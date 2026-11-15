// The CPU core of the frame graph (src/frame_graph.h, src/target_pool.h): ordering, culling, aliasing, errors, the
// target pool and the JSON dump. No GPU: the pool creates plain counters.
#include <doctest.h>

#include <string>
#include <vector>

#include "frame_graph.h"

using namespace fa;
using namespace fa::render;

namespace {

TransientDesc desc(int w, int h, const char* label, sg_pixel_format color = SG_PIXELFORMAT_RGBA8) {
    TransientDesc d;
    d.width = w;
    d.height = h;
    d.format.color = color;
    d.label = label;
    return d;
}

// A pool whose targets are numbers 1, 2, 3...
struct FakePool {
    std::uint64_t next = 1;
    int alive = 0;
    TargetPool pool;
    explicit FakePool(int maxIdle = 4)
        : pool(
              [this](const TransientDesc&) {
                  ++alive;
                  return next++;
              },
              [this](std::uint64_t) { --alive; }, maxIdle) {}
};

GraphPass pass(const char* name, std::vector<ResourceId> reads, std::vector<ResourceId> writes,
               std::vector<std::string>* log = nullptr) {
    GraphPass p;
    p.name = name;
    p.reads = std::move(reads);
    p.writes = std::move(writes);
    if (log) p.execute = [log, n = std::string(name)](const PassContext&) { log->push_back(n); };
    return p;
}

GraphPass present_pass(const char* name, std::vector<ResourceId> reads, std::vector<std::string>* log = nullptr) {
    GraphPass p = pass(name, std::move(reads), {}, log);
    p.sideEffect = true;
    return p;
}

}  // namespace

TEST_CASE("frame graph: a linear chain runs in order and hands out the targets") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 77);
    ResourceId a = g.create_transient(desc(64, 64, "a"));
    ResourceId b = g.create_transient(desc(64, 64, "b"));
    std::vector<std::string> log;
    std::uint64_t seenA = 0, seenScreen = 0;
    GraphPass p1, p2, p3;
    p1 = pass("draw", {}, {a}, &log);
    p1.execute = [&](const PassContext& c) {
        log.push_back("draw");
        seenA = c.handle(a);
    };
    p2 = pass("blur", {a}, {b}, &log);
    p3 = pass("final", {b}, {screen}, &log);
    p3.execute = [&](const PassContext& c) {
        log.push_back("final");
        seenScreen = c.handle(screen);
    };
    g.add_pass(std::move(p1));
    g.add_pass(std::move(p2));
    g.add_pass(std::move(p3));
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"draw", "blur", "final"});
    CHECK(g.culled_names().empty());

    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(log == std::vector<std::string>{"draw", "blur", "final"});
    CHECK(seenA != 0);
    CHECK(seenScreen == 77);
    CHECK(fp.pool.stats().inUse == 0);  // every transient went back to the pool
    REQUIRE(g.stats().size() == 3);
    CHECK(g.stats()[0].name == "draw");
    CHECK(g.stats()[2].culled == false);
    CHECK(g.stats()[1].cpuMs >= 0.0);
}

TEST_CASE("frame graph: a diamond runs both branches before the join, in declaration order") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId src = g.create_transient(desc(8, 8, "src"));
    ResourceId l = g.create_transient(desc(8, 8, "left"));
    ResourceId r = g.create_transient(desc(8, 8, "right"));
    g.add_pass(pass("source", {}, {src}));
    g.add_pass(pass("right", {src}, {r}));
    g.add_pass(pass("left", {src}, {l}));
    g.add_pass(pass("join", {l, r}, {screen}));
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"source", "right", "left", "join"});
}

TEST_CASE("frame graph: independent passes keep their declaration order; a dependency moves a pass later") {
    FrameGraph g;
    ResourceId s1 = g.import_target("s1", 1);
    ResourceId s2 = g.import_target("s2", 2);
    ResourceId s3 = g.import_target("s3", 3);
    g.add_pass(pass("c", {}, {s3}));
    g.add_pass(pass("a", {}, {s1}));
    GraphPass b = pass("b", {}, {s2});
    b.after = {"d"};  // an explicit order, to a pass declared later
    g.add_pass(std::move(b));
    g.add_pass(pass("d", {}, {s1}));  // also runs after "a" (both write s1)
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"c", "a", "d", "b"});
    // The same declaration compiles to the same order every time.
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"c", "a", "d", "b"});
}

TEST_CASE("frame graph: a later writer of the same target runs after the earlier readers and writers") {
    FrameGraph g;
    ResourceId game = g.import_target("game", 5);
    ResourceId screen = g.import_target("screen", 6);
    g.add_pass(pass("world", {}, {game}));
    g.add_pass(pass("bloom", {game}, {game}));  // reads and writes the same image
    g.add_pass(pass("hud", {}, {game}));
    g.add_pass(pass("copy", {game}, {screen}));
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"world", "bloom", "hud", "copy"});
}

TEST_CASE("frame graph: a cycle is an error that names the passes") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    g.add_pass(pass("one", {}, {screen}));
    GraphPass two = pass("two", {}, {screen});
    two.after = {"three"};
    g.add_pass(std::move(two));
    GraphPass three = pass("three", {}, {screen});
    three.after = {"two"};
    g.add_pass(std::move(three));
    auto r = g.compile();
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(g.compiled());
    CHECK(r.error().message.find("cycle") != std::string::npos);
    CHECK(r.error().message.find("'two'") != std::string::npos);
    CHECK(r.error().message.find("'three'") != std::string::npos);
    CHECK(r.error().message.find("'one'") == std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
    FakePool fp;
    CHECK_FALSE(g.execute(fp.pool).ok());
}

TEST_CASE("frame graph: CyclePolicy::Break runs the pass declared first of a cycle first and records it") {
    FrameGraph g;
    g.set_cycle_policy(CyclePolicy::Break);
    ResourceId img = g.import_target("img", 1);
    std::vector<std::string> log;
    g.add_pass(pass("one", {}, {img}, &log));
    GraphPass two = pass("two", {}, {}, &log);
    two.sideEffect = true;
    two.after = {"three"};
    g.add_pass(std::move(two));
    GraphPass three = pass("three", {}, {}, &log);
    three.sideEffect = true;
    three.after = {"two"};
    g.add_pass(std::move(three));
    GraphPass four = pass("four", {}, {}, &log);
    four.sideEffect = true;
    four.after = {"three"};
    g.add_pass(std::move(four));
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"one", "two", "three", "four"});
    REQUIRE(g.cycle_breaks().size() == 1);
    CHECK(g.cycle_breaks()[0].pass == "two");
    CHECK(g.cycle_breaks()[0].waitedFor == std::vector<std::string>{"three"});
    CHECK(g.to_json()["cycleBreaks"].size() == 1);
    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(log == std::vector<std::string>{"one", "two", "three", "four"});
    // The same declaration breaks the same way, and a graph without a cycle records nothing.
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"one", "two", "three", "four"});
    CHECK(g.cycle_breaks().size() == 1);
    FrameGraph plain;
    plain.set_cycle_policy(CyclePolicy::Break);
    plain.add_pass(pass("a", {}, {plain.import_target("t", 1)}));
    REQUIRE(plain.compile().ok());
    CHECK(plain.cycle_breaks().empty());
}

TEST_CASE("frame graph: release_callbacks keeps the dump and refuses to execute") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    std::vector<std::string> log;
    g.add_pass(pass("a", {}, {screen}, &log));
    REQUIRE(g.compile().ok());
    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(log.size() == 1);
    g.release_callbacks();
    CHECK(g.order_names() == std::vector<std::string>{"a"});
    CHECK(g.to_json()["order"].size() == 1);
    CHECK_FALSE(g.execute(fp.pool).ok());
    CHECK(log.size() == 1);
    g.clear();
    g.add_pass(pass("b", {}, {g.import_target("screen", 1)}, &log));
    REQUIRE(g.compile().ok());
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(log.size() == 2);
}

TEST_CASE("frame graph: reading a transient before it is written is an error with a hint") {
    SUBCASE("written by a pass declared later") {
        FrameGraph g;
        ResourceId screen = g.import_target("screen", 1);
        ResourceId t = g.create_transient(desc(8, 8, "lightBuffer"));
        g.add_pass(pass("main", {t}, {screen}));
        g.add_pass(pass("lights", {}, {t}));
        auto r = g.compile();
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("'main'") != std::string::npos);
        CHECK(r.error().message.find("'lightBuffer'") != std::string::npos);
        CHECK(r.error().message.find("'lights'") != std::string::npos);
        CHECK(r.error().hint.find("Declare 'lights' before 'main'") != std::string::npos);
    }
    SUBCASE("written by nobody") {
        FrameGraph g;
        ResourceId screen = g.import_target("screen", 1);
        ResourceId t = g.create_transient(desc(8, 8, "ghost"));
        g.add_pass(pass("main", {t}, {screen}));
        auto r = g.compile();
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("nothing writes it") != std::string::npos);
    }
}

TEST_CASE("frame graph: names must be unique and after() must name a pass") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    g.add_pass(pass("shadow", {}, {screen}));
    GraphPass p = pass("main", {}, {screen});
    p.after = {"shadw"};
    g.add_pass(std::move(p));
    auto r = g.compile();
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("shadow") != std::string::npos);  // the did-you-mean suggestion

    FrameGraph g2;
    g2.add_pass(pass("x", {}, {}));
    g2.add_pass(pass("x", {}, {}));
    auto r2 = g2.compile();
    REQUIRE_FALSE(r2.ok());
    CHECK(r2.error().message.find("'x'") != std::string::npos);
}

TEST_CASE("frame graph: a pass nobody reads is culled, a side-effect pass and an imported write are kept") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId used = g.create_transient(desc(8, 8, "used"));
    ResourceId unused = g.create_transient(desc(8, 8, "unused"));
    ResourceId feedsUnused = g.create_transient(desc(8, 8, "feedsUnused"));
    ResourceId readback = g.create_transient(desc(8, 8, "readback"));
    std::vector<std::string> log;
    g.add_pass(pass("makeUsed", {}, {used}, &log));
    g.add_pass(pass("makeFeed", {}, {feedsUnused}, &log));
    g.add_pass(pass("makeUnused", {feedsUnused}, {unused}, &log));
    g.add_pass(pass("final", {used}, {screen}, &log));
    g.add_pass(pass("makeReadback", {}, {readback}, &log));
    g.add_pass(present_pass("read", {readback}, &log));
    REQUIRE(g.compile().ok());
    CHECK(g.order_names() == std::vector<std::string>{"makeUsed", "final", "makeReadback", "read"});
    CHECK(g.culled_names() == std::vector<std::string>{"makeFeed", "makeUnused"});
    CHECK(g.alias_slot(unused) == -1);

    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(log == std::vector<std::string>{"makeUsed", "final", "makeReadback", "read"});
    REQUIRE(g.stats().size() == 6);
    CHECK(g.stats()[4].name == "makeFeed");
    CHECK(g.stats()[4].culled);
    CHECK(g.stats()[5].culled);
    CHECK(fp.pool.stats().created == 1);  // `used` and `readback` do not overlap and share one target
}

TEST_CASE("frame graph: transients whose lifetimes do not overlap share a slot, overlapping ones do not") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId a = g.create_transient(desc(32, 32, "a"));
    ResourceId b = g.create_transient(desc(32, 32, "b"));
    ResourceId c = g.create_transient(desc(32, 32, "c"));
    ResourceId other = g.create_transient(desc(16, 16, "otherSize"));
    g.add_pass(pass("p0", {}, {a}));
    g.add_pass(pass("p1", {a}, {b}));      // a and b overlap here (a's last use, b's first)
    g.add_pass(pass("p2", {b}, {c}));      // a is free from here: c can reuse its slot
    g.add_pass(pass("p3", {c}, {other}));  // another size never shares
    g.add_pass(pass("p4", {other}, {screen}));
    REQUIRE(g.compile().ok());
    CHECK(g.alias_slot(a) == 0);
    CHECK(g.alias_slot(b) == 1);
    CHECK(g.alias_slot(c) == 0);
    CHECK(g.alias_slot(other) == 2);
    CHECK(g.alias_slot_count() == 3);

    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(fp.pool.stats().created == 3);
    CHECK(fp.pool.stats().reused == 1);
    // The next frame reuses all three.
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(fp.pool.stats().created == 3);
    CHECK(fp.pool.stats().reused == 5);
}

TEST_CASE("frame graph: transients that are alive together never get the same physical target") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId a = g.create_transient(desc(8, 8, "a"));
    ResourceId b = g.create_transient(desc(8, 8, "b"));
    std::uint64_t ha = 0, hb = 0;
    g.add_pass(pass("makeA", {}, {a}));
    GraphPass mb = pass("makeB", {}, {b});
    g.add_pass(std::move(mb));
    GraphPass j = pass("join", {a, b}, {screen});
    j.execute = [&](const PassContext& c) {
        ha = c.handle(a);
        hb = c.handle(b);
    };
    g.add_pass(std::move(j));
    REQUIRE(g.compile().ok());
    CHECK(g.alias_slot(a) != g.alias_slot(b));
    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(ha != 0);
    CHECK(hb != 0);
    CHECK(ha != hb);
}

TEST_CASE("target pool: reuse across frames, eviction after N idle frames, counters") {
    FakePool fp(2);
    TargetPool& pool = fp.pool;
    TransientDesc d = desc(100, 50, "x");
    std::uint64_t h1 = pool.acquire(d);
    CHECK(h1 != 0);
    CHECK(pool.stats().created == 1);
    CHECK(pool.stats().inUse == 1);
    pool.release(h1);
    pool.release(h1);   // twice: ignored
    pool.release(999);  // unknown: ignored
    CHECK(pool.stats().inUse == 0);

    pool.begin_frame();
    CHECK(pool.acquire(d) == h1);                       // reused, the label does not matter
    CHECK(pool.acquire(desc(100, 50, "other")) != h1);  // the first is in use: a second target
    CHECK(pool.stats().created == 2);
    CHECK(pool.stats().reused == 1);
    CHECK(pool.stats().live == 2);
    // a size or a format that differs is another target
    CHECK(pool.acquire(desc(100, 51, "x")) != 0);
    CHECK(pool.acquire(desc(100, 50, "x", SG_PIXELFORMAT_RGBA16F)) != 0);
    CHECK(pool.stats().created == 4);
    pool.release(h1);

    // h1 is free since frame 1; frames 2 and 3 pass without it: it goes at the start of frame 4 (idle for 2 whole
    // frames).
    pool.begin_frame();  // frame 2
    pool.begin_frame();  // frame 3
    CHECK(fp.alive == 4);
    pool.begin_frame();  // frame 4
    CHECK(fp.alive == 3);
    CHECK(pool.stats().destroyed == 1);
    CHECK(pool.stats().live == 3);  // the three still in use stay however long they are held
    for (int i = 0; i < 10; ++i) pool.begin_frame();
    CHECK(pool.stats().live == 3);

    pool.clear_free();
    CHECK(pool.stats().live == 3);
}

TEST_CASE("target pool: the destructor destroys every target") {
    int alive = 0;
    {
        TargetPool pool([&](const TransientDesc&) { return std::uint64_t(++alive); }, [&](std::uint64_t) { --alive; });
        pool.acquire(desc(4, 4, "a"));
        std::uint64_t b = pool.acquire(desc(5, 5, "b"));
        pool.release(b);
        CHECK(alive == 2);
        pool.clear_free();
        CHECK(alive == 1);
    }
    CHECK(alive == 0);
}

TEST_CASE("frame graph: a pool that cannot create a target fails the frame and gives back what it took") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId a = g.create_transient(desc(8, 8, "a"));
    ResourceId b = g.create_transient(desc(9, 9, "b"));
    g.add_pass(pass("p0", {}, {a}));
    g.add_pass(pass("p1", {a}, {b}));
    g.add_pass(pass("p2", {b}, {screen}));
    REQUIRE(g.compile().ok());
    int made = 0;
    TargetPool pool([&](const TransientDesc&) { return made++ == 0 ? std::uint64_t(1) : std::uint64_t(0); },
                    [](std::uint64_t) {});
    auto r = g.execute(pool);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("'b'") != std::string::npos);
    CHECK(pool.stats().inUse == 0);
}

TEST_CASE("frame graph: to_json describes resources, passes, order, culling and aliasing") {
    FrameGraph g;
    TransientDesc gd = desc(1280, 720, "game", SG_PIXELFORMAT_RGBA16F);
    gd.format.depth = SG_PIXELFORMAT_DEPTH_STENCIL;
    ResourceId game = g.import_target("game", 3, gd);
    ResourceId a = g.create_transient(desc(64, 32, "a"));
    ResourceId b = g.create_transient(desc(64, 32, "b"));
    ResourceId dead = g.create_transient(desc(2, 2, "dead"));
    g.add_pass(pass("first", {}, {a}));
    g.add_pass(pass("second", {a}, {b}));
    g.add_pass(pass("third", {b}, {game}));
    g.add_pass(pass("orphan", {}, {dead}));
    Json before = g.to_json();
    CHECK(before["compiled"] == false);
    REQUIRE(g.compile().ok());
    Json j = g.to_json();
    CHECK(j["compiled"] == true);
    REQUIRE(j["resources"].size() == 4);
    CHECK(j["resources"][0]["name"] == "game");
    CHECK(j["resources"][0]["kind"] == "imported");
    CHECK(j["resources"][0]["format"]["color"] == "rgba16f");
    CHECK(j["resources"][0]["format"]["depth"] == "depth_stencil");
    CHECK(j["resources"][0]["format"]["samples"] == 1);
    CHECK(j["resources"][1]["kind"] == "transient");
    CHECK(j["resources"][1]["firstUse"] == 0);
    CHECK(j["resources"][1]["lastUse"] == 1);
    CHECK(j["resources"][1]["aliasSlot"] == 0);
    CHECK(j["resources"][2]["aliasSlot"] == 1);  // b is born while a is read by "second"
    CHECK(j["resources"][3]["aliasSlot"].is_null());
    REQUIRE(j["passes"].size() == 4);
    CHECK(j["passes"][1]["name"] == "second");
    CHECK(j["passes"][1]["reads"] == Json::array({"a"}));
    CHECK(j["passes"][1]["writes"] == Json::array({"b"}));
    CHECK(j["passes"][1]["culled"] == false);
    CHECK(j["passes"][1]["position"] == 1);
    CHECK(j["passes"][3]["culled"] == true);
    CHECK(j["passes"][3]["position"].is_null());
    CHECK(j["order"] == Json::array({"first", "second", "third"}));
    CHECK(j["culled"] == Json::array({"orphan"}));
    REQUIRE(j["aliasSlots"].size() == 2);
    CHECK(j["aliasSlots"][0]["resources"] == Json::array({"a"}));
}

TEST_CASE("frame graph: set_import_handle rebinds an imported resource and refuses the others") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 5, desc(32, 32, "screen"));
    ResourceId a = g.create_transient(desc(8, 8, "a"));
    CHECK_FALSE(g.set_import_handle(a, 9));  // a transient has no handle to set
    CHECK_FALSE(g.set_import_handle(ResourceId{}, 9));
    CHECK_FALSE(g.set_import_handle(ResourceId{99}, 9));
    std::uint64_t seen = 0;
    GraphPass p = pass("draw", {}, {screen});
    p.execute = [&](const PassContext& c) { seen = c.handle(screen); };
    g.add_pass(std::move(p));
    REQUIRE(g.compile().ok());
    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(seen == 5);
    // The same compiled graph, another image: no new compile is needed.
    CHECK(g.set_import_handle(screen, 6));
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(seen == 6);
    CHECK(g.to_json()["resources"][0]["width"] == 32);  // no desc given: the shape stays
    // A new desc replaces the shape and keeps the label when it has none.
    const TransientDesc bigger = desc(64, 48, "");
    CHECK(g.set_import_handle(screen, 7, &bigger));
    CHECK(g.to_json()["resources"][0]["width"] == 64);
    CHECK(g.to_json()["resources"][0]["height"] == 48);
    CHECK(g.to_json()["resources"][0]["name"] == "screen");
}

TEST_CASE("frame graph: a pass that throws gives every transient back to the pool") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId a = g.create_transient(desc(8, 8, "a"));
    ResourceId b = g.create_transient(desc(9, 9, "b"));
    g.add_pass(pass("p0", {}, {a}));
    GraphPass thrower = pass("p1", {a}, {b});
    thrower.execute = [](const PassContext&) { throw 42; };
    g.add_pass(std::move(thrower));
    g.add_pass(pass("p2", {b}, {screen}));
    REQUIRE(g.compile().ok());
    FakePool fp;
    CHECK_THROWS(static_cast<void>(g.execute(fp.pool)));
    CHECK(fp.pool.stats().inUse == 0);  // back in the pool, not leaked
    CHECK(fp.pool.stats().live == 2);
}

TEST_CASE("frame graph: pass hooks wrap every pass that runs, in order, with its CPU time, and skip culled passes") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    ResourceId a = g.create_transient(desc(8, 8, "a"));
    ResourceId dead = g.create_transient(desc(8, 8, "dead"));
    std::vector<std::string> log;
    g.add_pass(pass("p0", {}, {a}, &log));
    g.add_pass(pass("orphan", {}, {dead}, &log));  // nobody reads it: culled
    g.add_pass(pass("p1", {a}, {screen}, &log));
    REQUIRE(g.compile().ok());
    std::vector<std::string> events;
    PassHooks hooks;
    hooks.begin = [&](const std::string& n) { events.push_back("begin " + n); };
    hooks.end = [&](const std::string& n, double ms) {
        CHECK(ms >= 0.0);
        events.push_back("end " + n);
    };
    g.set_pass_hooks(hooks);
    FakePool fp;
    REQUIRE(g.execute(fp.pool).ok());
    CHECK(events == std::vector<std::string>{"begin p0", "end p0", "begin p1", "end p1"});
    REQUIRE(g.stats().size() == 3);
    CHECK(g.stats()[0].cpuMs >= 0.0);
    CHECK(g.stats()[2].culled);
}

TEST_CASE("frame graph: the end hook also runs when a pass throws") {
    FrameGraph g;
    ResourceId screen = g.import_target("screen", 1);
    GraphPass thrower = pass("boom", {}, {screen});
    thrower.execute = [](const PassContext&) { throw 42; };
    g.add_pass(std::move(thrower));
    REQUIRE(g.compile().ok());
    int begins = 0, ends = 0;
    PassHooks hooks;
    hooks.begin = [&](const std::string&) { ++begins; };
    hooks.end = [&](const std::string&, double) { ++ends; };
    g.set_pass_hooks(std::move(hooks));
    FakePool fp;
    CHECK_THROWS(static_cast<void>(g.execute(fp.pool)));
    CHECK(begins == 1);
    CHECK(ends == 1);
}
