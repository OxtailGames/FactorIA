// Effect documents (fa/scene/vfx.h): the format and its errors, the timeline, play / stop, budgets, determinism, reloading.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa_test_paths.h"
#include "fa/scene/serialize.h"
#include "fa/scene/vfx.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

struct TempDir {
    std::filesystem::path dir;
    explicit TempDir(const char* prefix) : dir(fs::make_temp_dir(prefix)) {}
    ~TempDir() {
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
        clear_vfx_cache();
    }
    TempDir(const TempDir&) = delete;
    TempDir& operator=(const TempDir&) = delete;
    std::string file(const char* name) const { return (dir / name).generic_string(); }
};

void write(const std::string& path, const Json& j) {
    auto r = fs::write_text(path, j.dump(2));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
}

// A hit effect: a burst, a flash, a sound at 0.1 s and a shake at 0.2 s. Ends at 0.4 s (the flash lasts 0.4 s).
Json hit_effect() {
    return Json::parse(R"({
      "format": "factoria.vfx/1",
      "doc": "A hit",
      "parts": [
        {"type": "emitter", "name": "sparks", "emitter": {"burst": 12, "lifetime": 0.3, "speed": 90, "maxParticles": 40}},
        {"type": "light", "name": "flash", "duration": 0.4, "offset": [0, 4], "light": {"intensity": 2, "radius": 120}},
        {"type": "sound", "at": 0.1, "clip": "assets/sfx/hit.wav", "volume": 0.5, "pitch": 1.2},
        {"type": "command", "at": 0.2, "command": "feel.shake", "args": {"amount": 0.5}}
      ]})");
}

struct Log {
    std::vector<std::string> events;
    VfxHost host() {
        VfxHost h;
        h.play_sound = [this](const std::string& clip, float volume, float pitch, const std::string& bus) {
            events.push_back("sound " + clip + " " + std::to_string(int(volume * 100)) + " " + std::to_string(int(pitch * 10)) + " " + bus);
            return true;
        };
        h.call = [this](const std::string& command, const Json& args) {
            events.push_back("call " + command + " " + args.dump());
            return std::string();
        };
        return h;
    }
};

std::vector<VfxIssue> issues_of(const Json& doc) {
    std::vector<VfxIssue> issues;
    (void)parse_vfx(doc, "t.vfx.json", &issues);
    return issues;
}

const VfxIssue* find_issue(const std::vector<VfxIssue>& issues, const std::string& pointer) {
    for (const VfxIssue& i : issues)
        if (i.pointer == pointer) return &i;
    return nullptr;
}

int children_named(World& w, Entity parent, const char* name) {
    int n = 0;
    for (Entity c : w.children(parent))
        if (w.alive(c) && !w.pending_destroy(c) && w.info(c).name == name) ++n;
    return n;
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ format --

TEST_CASE("vfx: a valid document parses with the parts, their times and the length it works out") {
    std::vector<VfxIssue> issues;
    auto doc = parse_vfx(hit_effect(), "hit.vfx.json", &issues);
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? "" : doc.error().message));
    CHECK_MESSAGE(issues.empty(), (issues.empty() ? "" : issues[0].pointer + ": " + issues[0].message));
    const VfxDoc& d = **doc;
    REQUIRE(d.parts.size() == 4);
    CHECK(d.description == "A hit");
    CHECK(d.parts[0].kind == VfxPartKind::Emitter);
    CHECK(d.parts[0].name == "sparks");
    CHECK(d.parts[1].offset.y == doctest::Approx(4.0f));
    CHECK(d.parts[2].clip == "assets/sfx/hit.wav");
    CHECK(d.parts[2].bus == "sfx");
    CHECK(d.parts[3].command == "feel.shake");
    CHECK(d.duration == doctest::Approx(0.4));  // the flash ends last
}

TEST_CASE("vfx: every kind of mistake is an error naming the JSON pointer, with a fix") {
    SUBCASE("an unknown key suggests the closest one") {
        Json j = hit_effect();
        j["durration"] = 1.0;
        auto issues = issues_of(j);
        const VfxIssue* i = find_issue(issues, "/durration");
        REQUIRE(i);
        CHECK(i->hint.find("duration") != std::string::npos);
    }
    SUBCASE("a key of another kind of part says which kind it belongs to") {
        Json j = hit_effect();
        j["parts"][0]["clip"] = "assets/sfx/hit.wav";
        auto issues = issues_of(j);
        const VfxIssue* i = find_issue(issues, "/parts/0/clip");
        REQUIRE(i);
        CHECK(i->hint.find("sound") != std::string::npos);
    }
    SUBCASE("an unknown type suggests one") {
        Json j = hit_effect();
        j["parts"][1]["type"] = "ligth";
        auto issues = issues_of(j);
        const VfxIssue* i = find_issue(issues, "/parts/1/type");
        REQUIRE(i);
        CHECK(i->hint.find("light") != std::string::npos);
    }
    SUBCASE("a wrong format and a missing parts list") {
        CHECK(find_issue(issues_of(Json::parse(R"({"format":"factoria.vfx/2","parts":[]})")), "/format"));
        CHECK(find_issue(issues_of(Json::parse(R"({"format":"factoria.vfx/1"})")), "/parts"));
        CHECK(find_issue(issues_of(Json::parse(R"({"format":"factoria.vfx/1","parts":[]})")), "/parts"));
    }
    SUBCASE("a command outside the allowed list is refused, with the list and a suggestion") {
        Json j = hit_effect();
        j["parts"][3]["command"] = "fs.delete";
        auto issues = issues_of(j);
        const VfxIssue* i = find_issue(issues, "/parts/3/command");
        REQUIRE(i);
        CHECK(i->message.find("fs.delete") != std::string::npos);
        CHECK(i->hint.find("feel.shake") != std::string::npos);
        j["parts"][3]["command"] = "feel.shak";
        const auto typo = issues_of(j);
        i = find_issue(typo, "/parts/3/command");
        REQUIRE(i);
        CHECK(i->hint.find("Did you mean 'feel.shake'") != std::string::npos);
    }
    SUBCASE("commands that write files or change settings are refused at parse time, with the pointer") {
        for (const char* name : {"audio.bake", "audio.create", "audio.edit", "feel.settings", "feel.cancel", "audio.log", "feel.state", "feel.*"}) {
            Json j = hit_effect();
            j["parts"][3]["command"] = name;
            auto doc = parse_vfx(j, "assets/vfx/hit.vfx.json");
            INFO(name);
            REQUIRE_FALSE(doc.ok());
            CHECK(doc.error().message.find("/parts/3/command") != std::string::npos);
            CHECK(doc.error().message.find(name) != std::string::npos);
            CHECK_FALSE(vfx_command_allowed(name));
        }
        for (const std::string& name : vfx_allowed_commands()) {
            Json j = hit_effect();
            j["parts"][3]["command"] = name;
            INFO(name);
            CHECK(parse_vfx(j, "t.vfx.json").ok());
        }
    }
    SUBCASE("an emitter field that does not exist is the same error a scene gives") {
        Json j = hit_effect();
        j["parts"][0]["emitter"]["burts"] = 3;
        auto issues = issues_of(j);
        const VfxIssue* i = find_issue(issues, "/parts/0/emitter");
        REQUIRE(i);
        CHECK(i->message.find("burts") != std::string::npos);
    }
    SUBCASE("an emitter that never emits") {
        Json j = hit_effect();
        j["parts"][0]["emitter"]["burst"] = 0;
        auto issues = issues_of(j);
        CHECK(find_issue(issues, "/parts/0/emitter"));
    }
    SUBCASE("times and offsets are finite and in range") {
        Json j = hit_effect();
        j["parts"][2]["at"] = 31;
        j["parts"][1]["offset"] = Json::array({1});
        j["parts"][3]["at"] = -1;
        auto issues = issues_of(j);
        CHECK(find_issue(issues, "/parts/2/at"));
        CHECK(find_issue(issues, "/parts/1/offset"));
        CHECK(find_issue(issues, "/parts/3/at"));
    }
    SUBCASE("a part that would start after the end of the effect") {
        Json j = hit_effect();
        j["duration"] = 0.15;
        auto issues = issues_of(j);
        CHECK(find_issue(issues, "/parts/3/at"));
    }
    SUBCASE("two parts with one name") {
        Json j = hit_effect();
        j["parts"][1]["name"] = "sparks";
        CHECK(find_issue(issues_of(j), "/parts/1/name"));
    }
    SUBCASE("more parts than the limit") {
        Json j = hit_effect();
        for (int i = 0; i < kVfxMaxParts; ++i) j["parts"].push_back(Json::parse(R"({"type":"sound","clip":"a.wav"})"));
        CHECK(find_issue(issues_of(j), "/parts"));
    }
    SUBCASE("the Error names the file and the first problem, and counts the others") {
        Json j = hit_effect();
        j["parts"][2]["volume"] = 5;
        j["parts"][3]["command"] = "fs.delete";
        auto doc = parse_vfx(j, "assets/vfx/hit.vfx.json");
        REQUIRE_FALSE(doc.ok());
        CHECK(doc.error().message.find("assets/vfx/hit.vfx.json") != std::string::npos);
        CHECK(doc.error().message.find("/parts/2/volume") != std::string::npos);
        CHECK(doc.error().message.find("1 more problem") != std::string::npos);
    }
}

TEST_CASE("vfx: a rate with no duration is a warning, the effect still parses") {
    Json j = hit_effect();
    j["parts"][0]["emitter"]["rate"] = 50;
    std::vector<VfxIssue> issues;
    auto doc = parse_vfx(j, "t.vfx.json", &issues);
    REQUIRE(doc.ok());
    const VfxIssue* i = find_issue(issues, "/parts/0/emitter/rate");
    REQUIRE(i);
    CHECK_FALSE(i->error);
}

TEST_CASE("vfx: missing sound files are listed with their pointer") {
    auto doc = parse_vfx(hit_effect(), "t.vfx.json");
    REQUIRE(doc.ok());
    auto missing = vfx_missing_assets(**doc, [](const std::string&) { return false; });
    REQUIRE(missing.size() == 1);
    CHECK(missing[0].pointer == "/parts/2/clip");
    CHECK(vfx_missing_assets(**doc, [](const std::string&) { return true; }).empty());
}

TEST_CASE("vfx: the schema file lists every key the parser accepts") {
    auto text = fs::read_text(std::string(FA_REPO_ROOT) + "/schemas/vfx.schema.json");
    REQUIRE(text.ok());
    auto schema = parse_json(*text, "vfx.schema.json");
    REQUIRE(schema.ok());
    const Json& top = (*schema)["properties"];
    for (const char* k : {"$schema", "format", "doc", "duration", "parts"}) CHECK_MESSAGE(top.contains(k), k);
    const Json& part = (*schema)["properties"]["parts"]["items"]["properties"];
    for (const char* k : {"type", "name", "at", "duration", "offset", "emitter", "light", "is3D", "fade", "clip", "volume", "pitch", "bus", "command", "args"}) {
        REQUIRE_MESSAGE(part.contains(k), k);
        CHECK_MESSAGE(part[k].contains("description"), k);
    }
}

// ----------------------------------------------------------------------------------------------------------- loading --

TEST_CASE("vfx: load_vfx reads a file, shares it, and reads it again when it changed") {
    TempDir tmp("fa_vfx_load");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    auto a = load_vfx(path);
    auto b = load_vfx(path);
    REQUIRE(a.ok());
    REQUIRE(b.ok());
    CHECK(a->get() == b->get());  // one VfxDoc for both
    Json longer = hit_effect();
    longer["doc"] = "A hit that is a bit longer than the first one";  // a different size: the cache sees it on any file system
    write(path, longer);
    auto c = load_vfx(path);
    REQUIRE(c.ok());
    CHECK(c->get() != a->get());
    CHECK((*c)->description == "A hit that is a bit longer than the first one");
    CHECK((*a)->description == "A hit");  // the one an effect already playing holds is unchanged
}

TEST_CASE("vfx: a same-size edit of a file just written is seen (the cache checks the content of a fresh file)") {
    TempDir tmp("fa_vfx_samesize");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    auto a = load_vfx(path);
    REQUIRE(a.ok());
    CHECK((*a)->description == "A hit");
    Json same = hit_effect();
    same["doc"] = "A hot";  // the same size as "A hit": mtime may not move within the file system's time step
    write(path, same);
    auto b = load_vfx(path);
    REQUIRE(b.ok());
    CHECK((*b)->description == "A hot");
    auto c = load_vfx(path);  // nothing changed: the same VfxDoc
    REQUIRE(c.ok());
    CHECK(b->get() == c->get());
}

TEST_CASE("vfx: a particle that lives longer than 30 s is an error (it would hold one of the 64 slots)") {
    auto doc = [](const char* emitter) {
        return Json::parse(std::string(R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":)") + emitter + "}]}");
    };
    CHECK_FALSE(find_issue(issues_of(doc(R"({"burst":4,"lifetime":20})")), "/parts/0/emitter/lifetime"));
    const std::vector<VfxIssue> longIssues = issues_of(doc(R"({"burst":4,"lifetime":3600})"));
    const VfxIssue* long1 = find_issue(longIssues, "/parts/0/emitter/lifetime");
    REQUIRE(long1);
    CHECK(long1->error);
    CHECK_FALSE(long1->hint.empty());
    // The variance and the trail count: 25 s * 1.5 = 37.5 s.
    CHECK(find_issue(issues_of(doc(R"({"burst":4,"lifetime":25,"lifetimeVariance":0.5})")), "/parts/0/emitter/lifetime"));
    CHECK(find_issue(issues_of(doc(R"({"burst":4,"lifetime":20,"trail":"particle","trailTime":15})")), "/parts/0/emitter/lifetime"));
    // A sub-emitter written inline is checked too.
    const std::vector<VfxIssue> innerIssues =
        issues_of(doc(R"({"burst":4,"lifetime":1,"subEmitters":{"death":{"emitter":{"burst":2,"lifetime":500}}}})"));
    const VfxIssue* inner = find_issue(innerIssues, "/parts/0/emitter/subEmitters/death/emitter/lifetime");
    REQUIRE(inner);
    CHECK(inner->error);
}

TEST_CASE("vfx: an unreadable file and an invalid one are errors that name the file") {
    TempDir tmp("fa_vfx_bad");
    auto missing = load_vfx(tmp.file("nope.vfx.json"));
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("nope.vfx.json") != std::string::npos);
    const std::string path = tmp.file("bad.vfx.json");
    REQUIRE(fs::write_text(path, "{ not json").ok());
    auto bad = load_vfx(path);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("bad.vfx.json") != std::string::npos);
    Json j = hit_effect();
    j["parts"][3]["command"] = "fs.delete";
    write(path, j);
    auto invalid = load_vfx(path);
    REQUIRE_FALSE(invalid.ok());
    CHECK(invalid.error().message.find("/parts/3/command") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------- timeline --

TEST_CASE("vfx: parts start at their time, lights fade and end, and an autoDestroy effect goes") {
    TempDir tmp("fa_vfx_timeline");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    Log log;
    const VfxHost host = log.host();
    VfxPlayOptions o;
    o.position = {100, 50, 0};
    auto r = vfx_play(w, path, o);
    REQUIRE(r.ok());
    const Entity fx = *r;
    REQUIRE_FALSE(fx.is_null());
    CHECK(w.info(fx).scriptSpawned);
    CHECK(w.get<Transform>(fx)->position.x == doctest::Approx(100.0f));
    CHECK(vfx_playing_count(w) == 1);
    CHECK(w.children(fx).empty());  // nothing before the first step

    const float dt = 0.05f;
    update_vfx(w, dt, host);  // t = 0.05: the emitter and the light started at 0
    CHECK(children_named(w, fx, "sparks") == 1);
    CHECK(children_named(w, fx, "flash") == 1);
    REQUIRE(w.get<Vfx>(fx)->duration == doctest::Approx(0.4f));
    CHECK(log.events.empty());
    Entity flash = kNullEntity;
    for (Entity c : w.children(fx))
        if (w.info(c).name == "flash") flash = c;
    REQUIRE(w.get<Light2D>(flash));
    CHECK(w.get<Light2D>(flash)->intensity == doctest::Approx(2.0f * (1.0f - 0.05f / 0.4f)).epsilon(0.02));
    CHECK(w.get<Transform>(flash)->position.y == doctest::Approx(4.0f));

    update_vfx(w, dt, host);  // 0.10: the sound
    REQUIRE(log.events.size() == 1);
    CHECK(log.events[0] == "sound assets/sfx/hit.wav 50 12 sfx");
    update_vfx(w, dt, host);  // 0.15
    update_vfx(w, dt, host);  // 0.20: the shake
    REQUIRE(log.events.size() == 2);
    CHECK(log.events[1] == "call feel.shake {\"amount\":0.5}");
    for (int i = 0; i < 6; ++i) update_vfx(w, dt, host);  // 0.60 s: past the end of the effect (0.4 s) and of its sparks (0.46 s)
    CHECK(log.events.size() == 2);  // each part once
    CHECK(children_named(w, fx, "flash") == 0);  // the flash lasted 0.4 s
    CHECK_FALSE(w.get<Vfx>(fx)->playing);
    w.flush();
    CHECK_FALSE(w.alive(fx));  // no renderer here: the effect removed its emitter itself, and then went
    CHECK(vfx_playing_count(w) == 0);
}

// ---- cleanup does not depend on a renderer: nobody steps the particles in these tests ----

TEST_CASE("vfx: a one-shot autoDestroy effect is gone at the time its particles can live until, without a renderer") {
    TempDir tmp("fa_vfx_drain");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());  // sparks: lifetime 0.3 +- 20%, a burst; the flash ends the effect at 0.4 s
    World w;
    VfxHost none;
    auto r = vfx_play(w, path);
    REQUIRE(r.ok());
    const std::size_t before = w.entity_count();
    // The emitter starts at the first step: its entity waits 0.3 * 1.2 + kVfxDrainSlack = 0.46 s, counted from then.
    int steps = 0;
    auto step = [&] {
        update_vfx(w, 0.05f, none);
        w.flush();
        ++steps;
    };
    while (steps < 8) step();  // 0.40 s
    CHECK(w.alive(*r));
    CHECK(w.entity_count() == before + 1);  // the sparks, the flash went at 0.4 s
    while (steps < 11) step();  // 0.55 s
    CHECK_FALSE(w.alive(*r));
    CHECK(w.entity_count() == before - 1);
    CHECK(vfx_playing_count(w) == 0);
}

TEST_CASE("vfx: a looping effect over a minute of game time keeps a bounded, stable set of entities, without a renderer") {
    TempDir tmp("fa_vfx_loop60");
    const std::string path = tmp.file("loop.vfx.json");
    write(path, Json::parse(R"({"format":"factoria.vfx/1","duration":1.0,"parts":[
        {"type":"emitter","name":"sparks","duration":0.5,"emitter":{"rate":30,"lifetime":0.5,"maxParticles":50}},
        {"type":"emitter","name":"burst","at":0.5,"emitter":{"burst":8,"lifetime":0.4}},
        {"type":"light","name":"glow","duration":0.3}]})"));
    World w;
    VfxHost none;
    VfxPlayOptions o;
    o.loop = true;
    auto r = vfx_play(w, path, o);
    REQUIRE(r.ok());
    std::size_t peak = 0, peakEarly = 0, peakLate = 0;
    for (int i = 0; i < 60 * 60; ++i) {  // 60 s of 60 Hz steps
        update_vfx(w, 1.0f / 60.0f, none);
        w.flush();
        peak = std::max(peak, w.entity_count());
        if (i >= 2 * 60 && i < 10 * 60) peakEarly = std::max(peakEarly, w.entity_count());  // after the first loops have warmed up
        if (i >= 50 * 60) peakLate = std::max(peakLate, w.entity_count());
    }
    // The effect, plus at most the emitters of the loops whose particles are still draining (0.6 s + 0.1 s of slack, and 0.48 + 0.1).
    CHECK(peak <= 1 + 2 * 2 + 1);
    CHECK(peakEarly > 1);
    CHECK(peakLate == peakEarly);  // nothing piles up from loop to loop
    CHECK(w.alive(*r));
    CHECK(w.get<Vfx>(*r)->playing);
    CHECK(w.get<Vfx>(*r)->rt.children.size() <= 6);
    CHECK(vfx_playing_count(w) == 1);
}

TEST_CASE("vfx: an explicit file duration shorter than a part ends its light and its emitter at the end of the effect") {
    TempDir tmp("fa_vfx_shortdur");
    const std::string path = tmp.file("short.vfx.json");
    write(path, Json::parse(R"({"format":"factoria.vfx/1","duration":0.2,"parts":[
        {"type":"emitter","name":"stream","duration":1.0,"emitter":{"rate":40,"lifetime":0.1,"lifetimeVariance":0}},
        {"type":"light","name":"glow","duration":0.4}]})"));
    World w;
    VfxHost none;
    auto r = vfx_play(w, path);
    REQUIRE(r.ok());
    Entity stream = kNullEntity;
    update_vfx(w, 0.05f, none);
    for (Entity c : w.children(*r))
        if (w.info(c).name == "stream") stream = c;
    REQUIRE_FALSE(stream.is_null());
    CHECK(w.get<ParticleEmitter>(stream)->emitting);
    CHECK(children_named(w, *r, "glow") == 1);
    for (int i = 0; i < 3; ++i) update_vfx(w, 0.05f, none);  // 0.20 s: the effect ends
    w.flush();
    CHECK_FALSE(w.get<Vfx>(*r)->playing);
    CHECK(children_named(w, *r, "glow") == 0);  // not left alive until its own end at 0.4 s
    REQUIRE(w.alive(stream));
    CHECK_FALSE(w.get<ParticleEmitter>(stream)->emitting);
    for (int i = 0; i < 6; ++i) update_vfx(w, 0.05f, none);  // 0.1 s lifetime + slack have passed
    w.flush();
    CHECK_FALSE(w.alive(stream));
    CHECK_FALSE(w.alive(*r));
}

TEST_CASE("vfx: the time an emitter waits counts the trail and the sub-emitter chain") {
    TempDir tmp("fa_vfx_chain");
    const std::string path = tmp.file("chain.vfx.json");
    write(path, Json::parse(R"({"format":"factoria.vfx/1","parts":[
        {"type":"emitter","name":"rocket","emitter":{"burst":3,"lifetime":1.0,"lifetimeVariance":0,"trail":"particle","trailTime":0.5,
          "subEmitters":{"death":{"count":4,"emitter":{"lifetime":2.0,"lifetimeVariance":0}}}}}]})"));
    World w;
    VfxHost none;
    auto r = vfx_play(w, path);
    REQUIRE(r.ok());
    update_vfx(w, 0.01f, none);
    REQUIRE(w.get<Vfx>(*r)->rt.children.size() == 1);
    // 1.0 + 0.5 (trail) + 2.0 (what its death makes) + slack
    CHECK(w.get<Vfx>(*r)->rt.children[0].drainFor == doctest::Approx(3.5f + float(kVfxDrainSlack)).epsilon(0.001));
    for (int i = 0; i < 100; ++i) update_vfx(w, 0.05f, none);  // 5 s
    w.flush();
    CHECK_FALSE(w.alive(*r));
}

TEST_CASE("vfx: speed, a paused clock and loop") {
    TempDir tmp("fa_vfx_speed");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    SUBCASE("speed 2 brings the sound from 0.1 s to 0.05 s") {
        World w;
        Log log;
        VfxPlayOptions o;
        o.speed = 2.0f;
        REQUIRE(vfx_play(w, path, o).ok());
        update_vfx(w, 0.025f, log.host());
        CHECK(log.events.empty());
        update_vfx(w, 0.025f, log.host());
        update_vfx(w, 0.025f, log.host());
        CHECK(log.events.size() == 1);
    }
    SUBCASE("a step of 0 (time.scale 0) does not advance the timeline") {
        World w;
        Log log;
        auto r = vfx_play(w, path);
        REQUIRE(r.ok());
        for (int i = 0; i < 50; ++i) update_vfx(w, 0.0f, log.host());
        CHECK(log.events.empty());
        CHECK(w.get<Vfx>(*r)->time == 0.0f);
    }
    SUBCASE("loop starts the parts again at the end") {
        World w;
        Log log;
        VfxPlayOptions o;
        o.loop = true;
        auto r = vfx_play(w, path, o);
        REQUIRE(r.ok());
        for (int i = 0; i < 32; ++i) update_vfx(w, 0.05f, log.host());  // 1.6 s = four passes of 0.4 s
        int sounds = 0;
        for (const std::string& e : log.events) sounds += e.rfind("sound", 0) == 0;
        CHECK(sounds >= 3);
        CHECK(sounds <= 4);
        CHECK(w.get<Vfx>(*r)->playing);
    }
    SUBCASE("a loop reads the file again at each round, and keeps the last good version when it cannot") {
        World w;
        Log log;
        VfxPlayOptions o;
        o.loop = true;
        REQUIRE(vfx_play(w, path, o).ok());
        for (int i = 0; i < 9; ++i) update_vfx(w, 0.05f, log.host());  // 0.45 s: the first round (0.4 s) is over
        REQUIRE(log.events.size() >= 2);
        CHECK(log.events[0].find("hit.wav") != std::string::npos);
        Json other = hit_effect();
        other["parts"][2]["clip"] = "assets/sfx/other.wav";
        write(path, other);
        log.events.clear();
        for (int i = 0; i < 9; ++i) update_vfx(w, 0.05f, log.host());  // the second round runs the new file
        bool sawNew = false;
        for (const std::string& e : log.events) sawNew = sawNew || e.find("other.wav") != std::string::npos;
        CHECK(sawNew);
        write(path, Json::parse(R"({"format": "factoria.vfx/1", "parts": "broken"})"));
        log.events.clear();
        for (int i = 0; i < 9; ++i) update_vfx(w, 0.05f, log.host());  // a round later: the file is invalid, the last version plays on
        bool sawLast = false;
        for (const std::string& e : log.events) sawLast = sawLast || e.find("other.wav") != std::string::npos;
        CHECK(sawLast);
    }
}

TEST_CASE("vfx: the same effects at the same steps do the same things") {
    TempDir tmp("fa_vfx_det");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    auto run = [&]() {
        World w;
        Log log;
        VfxPlayOptions o;
        o.speed = 1.5f;
        REQUIRE(vfx_play(w, path, o).ok());
        std::vector<std::string> trace;
        for (int i = 0; i < 20; ++i) {
            const std::size_t before = log.events.size();
            update_vfx(w, 1.0f / 60.0f, log.host());
            for (std::size_t k = before; k < log.events.size(); ++k) trace.push_back(std::to_string(i) + ":" + log.events[k]);
            trace.push_back(std::to_string(i) + " children " + std::to_string(w.entity_count()));
        }
        return trace;
    };
    CHECK(run() == run());
}

// --------------------------------------------------------------------------------------------------- play and stop --

TEST_CASE("vfx: vfx_play checks the file and the options, and follows a parent") {
    TempDir tmp("fa_vfx_play");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    CHECK_FALSE(vfx_play(w, tmp.file("missing.vfx.json")).ok());
    VfxPlayOptions bad;
    bad.speed = 0.0f;
    CHECK_FALSE(vfx_play(w, path, bad).ok());
    bad = {};
    bad.scale = -1.0f;
    CHECK_FALSE(vfx_play(w, path, bad).ok());
    CHECK(w.entity_count() == 0);  // a refused play makes nothing

    Entity boss = w.create("boss");
    VfxPlayOptions o;
    o.parent = boss;
    o.position = {0, 10, 0};
    o.scale = 2.0f;
    auto r = vfx_play(w, path, o);
    REQUIRE(r.ok());
    CHECK(w.parent(*r) == boss);
    CHECK(w.get<Transform>(*r)->scale.x == doctest::Approx(2.0f));
    CHECK(w.get<Vfx>(*r)->autoDestroy);

    // A parent that is gone (or about to be) is an error that says so, not an effect that silently stays in the world.
    const std::size_t before = w.entity_count();
    Entity gone = w.create("gone");
    w.destroy(gone);
    o.parent = gone;
    auto bad2 = vfx_play(w, path, o);
    REQUIRE_FALSE(bad2.ok());
    CHECK(bad2.error().message.find("parent") != std::string::npos);
    CHECK_FALSE(bad2.error().hint.empty());
    CHECK(w.entity_count() == before + 1);  // only `gone` itself (still waiting to be destroyed): the refused play made nothing
}

TEST_CASE("vfx: at most kVfxMaxPlaying effects play at once; a play past that is dropped") {
    TempDir tmp("fa_vfx_budget");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    for (int i = 0; i < kVfxMaxPlaying; ++i) {
        auto r = vfx_play(w, path);
        REQUIRE(r.ok());
        REQUIRE_FALSE(r->is_null());
    }
    auto over = vfx_play(w, path);
    REQUIRE(over.ok());
    CHECK(over->is_null());
    CHECK(vfx_playing_count(w) == kVfxMaxPlaying);
    // They count until they have ended and their emitters have drained, not before; then the budget is free again.
    VfxHost none;
    for (int i = 0; i < 20; ++i) update_vfx(w, 0.05f, none);  // 1 s
    w.flush();
    CHECK(vfx_playing_count(w) == 0);
    auto again = vfx_play(w, path);
    REQUIRE(again.ok());
    CHECK_FALSE(again->is_null());
}

TEST_CASE("vfx: vfx_stop ends an effect, at once or letting its particles finish") {
    TempDir tmp("fa_vfx_stop");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    Log log;
    SUBCASE("immediate removes the entity and its children") {
        auto r = vfx_play(w, path);
        REQUIRE(r.ok());
        update_vfx(w, 0.05f, log.host());
        REQUIRE(w.children(*r).size() == 2);
        vfx_stop(w, *r, true);
        w.flush();
        CHECK_FALSE(w.alive(*r));
    }
    SUBCASE("a soft stop: the emitter stops emitting, the light goes, later parts never start") {
        auto r = vfx_play(w, path);
        REQUIRE(r.ok());
        update_vfx(w, 0.05f, log.host());
        vfx_stop(w, *r, false);
        for (Entity c : w.children(*r))
            if (auto* pe = w.get<ParticleEmitter>(c)) CHECK_FALSE(pe->emitting);
        for (int i = 0; i < 10; ++i) update_vfx(w, 0.05f, log.host());
        CHECK(log.events.empty());  // the sound and the shake never started
        CHECK_FALSE(w.get<Vfx>(*r)->playing);
    }
}

// -------------------------------------------------------------------------------------------------- Vfx component --

TEST_CASE("vfx: an entity with a Vfx component plays by itself, a missing file is reported once and stops it") {
    TempDir tmp("fa_vfx_comp");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    Log log;
    SUBCASE("autoplay") {
        Entity e = w.create("torch");
        w.add<Vfx>(e).effect = path;
        update_vfx(w, 0.05f, log.host());
        CHECK(w.get<Vfx>(e)->playing);
        CHECK(children_named(w, e, "sparks") == 1);
    }
    SUBCASE("autoplay off waits for playing") {
        Entity e = w.create("torch");
        auto& v = w.add<Vfx>(e);
        v.effect = path;
        v.autoplay = false;
        for (int i = 0; i < 5; ++i) update_vfx(w, 0.05f, log.host());
        CHECK(w.children(e).empty());
        v.playing = true;
        update_vfx(w, 0.05f, log.host());
        CHECK(children_named(w, e, "sparks") == 1);
    }
    SUBCASE("a playing effect that ended plays again when playing is set true") {
        Entity e = w.create("torch");
        w.add<Vfx>(e).effect = path;
        for (int i = 0; i < 12; ++i) update_vfx(w, 0.05f, log.host());
        REQUIRE_FALSE(w.get<Vfx>(e)->playing);
        for (Entity c : w.children(e)) w.destroy(c);
        w.flush();
        w.get<Vfx>(e)->playing = true;
        update_vfx(w, 0.05f, log.host());
        CHECK(w.get<Vfx>(e)->playing);
        CHECK(children_named(w, e, "sparks") == 1);
    }
    SUBCASE("changing `effect` starts the other one from the beginning") {
        Entity e = w.create("torch");
        w.add<Vfx>(e).effect = path;
        update_vfx(w, 0.05f, log.host());
        update_vfx(w, 0.05f, log.host());
        const std::string other = tmp.file("other.vfx.json");
        write(other, Json::parse(R"({"format":"factoria.vfx/1","parts":[{"type":"sound","at":0.2,"clip":"x.wav"}]})"));
        w.get<Vfx>(e)->effect = other;
        update_vfx(w, 0.05f, log.host());
        CHECK(w.get<Vfx>(e)->time == doctest::Approx(0.05f));
        CHECK(w.get<Vfx>(e)->duration == doctest::Approx(0.2f));
        CHECK(children_named(w, e, "flash") == 0);
    }
    SUBCASE("a file with errors stops it: nothing plays, and the world is not stuck") {
        Entity e = w.create("torch");
        w.add<Vfx>(e).effect = tmp.file("absent.vfx.json");
        for (int i = 0; i < 3; ++i) update_vfx(w, 0.05f, log.host());
        CHECK_FALSE(w.get<Vfx>(e)->playing);
        CHECK(w.children(e).empty());
    }
}

TEST_CASE("vfx: the runtime state is not saved, and a copy starts the effect again") {
    TempDir tmp("fa_vfx_copy");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    Log log;
    Entity e = w.create("torch");
    w.add<Vfx>(e).effect = path;
    update_vfx(w, 0.05f, log.host());
    REQUIRE(w.get<Vfx>(e)->rt.children.size() == 2);
    Vfx copy = *w.get<Vfx>(e);
    CHECK(copy.rt.children.empty());
    CHECK(copy.rt.doc == nullptr);
    const TypeInfo& type = World::type_of<Vfx>();
    const Json saved = object_to_json(type, w.get<Vfx>(e), false);
    CHECK_FALSE(saved.contains("playing"));
    CHECK_FALSE(saved.contains("time"));
    CHECK_FALSE(saved.contains("duration"));
    CHECK(saved["effect"] == path);
}

TEST_CASE("vfx: VfxHost::load supplies the document instead of the file (the editor's preview plays an unsaved one)") {
    World w;
    Log log;
    auto doc = parse_vfx(hit_effect(), "memory.vfx.json", nullptr);
    REQUIRE(doc.ok());
    int asked = 0;
    VfxHost host = log.host();
    host.load = [&](const std::string& effect) {
        ++asked;
        return effect == "memory.vfx.json" ? *doc : std::shared_ptr<const VfxDoc>();
    };
    SUBCASE("a name only the hook knows plays") {
        Entity e = w.create("torch");
        w.add<Vfx>(e).effect = "memory.vfx.json";
        update_vfx(w, 0.05f, host);
        CHECK(asked >= 1);
        CHECK(w.get<Vfx>(e)->playing);
        CHECK(children_named(w, e, "sparks") == 1);
    }
    SUBCASE("an empty answer is an unreadable document: it stops, as a missing file does") {
        Entity e = w.create("torch");
        w.add<Vfx>(e).effect = "other.vfx.json";
        for (int i = 0; i < 3; ++i) update_vfx(w, 0.05f, host);
        CHECK_FALSE(w.get<Vfx>(e)->playing);
        CHECK(w.children(e).empty());
    }
}

TEST_CASE("vfx: play scale makes the effect that many times larger: positions, particle size and speed, trails, light radius; not times or command arguments") {
    TempDir tmp("fa_vfx_scale");
    const std::string path = tmp.file("hit.vfx.json");
    Json fx = hit_effect();
    fx["parts"][0]["emitter"]["gravity"] = Json::array({0, -100, 0});
    fx["parts"][0]["emitter"]["trailWidth"] = 3;
    fx["parts"][0]["emitter"]["noiseStrength"] = 10;
    fx["parts"][0]["emitter"]["subEmitters"] = Json::parse(R"({"death": {"count": 2, "emitter": {"speed": 50, "startSize": 6, "shape": "circle", "shapeSize": [4, 4, 4],
        "subEmitters": {"death": {"emitter": {"gravity": [0, -20, 0]}}}}}})");
    // The same emitter kept in its own space (the emitter's matrix scales how far its particles fly), and one that is a prefab link.
    fx["parts"].push_back(Json::parse(R"({"type": "emitter", "name": "local", "emitter": {"burst": 3, "worldSpace": false, "speed": 70, "startSize": 5,
        "gravity": [0, -40, 0], "subEmitters": {"death": {"prefab": "prefabs/dust.prefab.json"}}}})"));
    write(path, fx);
    auto play = [&](float scale) {
        auto w = std::make_unique<World>();
        VfxPlayOptions o;
        o.position = {100, 50, 0};
        o.scale = scale;
        auto r = vfx_play(*w, path, o);
        REQUIRE(r.ok());
        Log log;
        VfxHost host = log.host();
        update_vfx(*w, 1.0f / 60.0f, host);
        w->flush();
        return std::make_pair(std::move(w), *r);
    };
    auto [w1, e1] = play(1.0f);
    auto [w2, e2] = play(2.0f);
    auto child = [](World& w, Entity fx, const char* name) {
        for (Entity c : w.children(fx))
            if (w.info(c).name == name) return c;
        return kNullEntity;
    };
    const Entity flash1 = child(*w1, e1, "flash"), flash2 = child(*w2, e2, "flash");
    const Entity sparks1 = child(*w1, e1, "sparks"), sparks2 = child(*w2, e2, "sparks");
    const Entity local1 = child(*w1, e1, "local"), local2 = child(*w2, e2, "local");
    REQUIRE(flash2 != kNullEntity);
    REQUIRE(sparks2 != kNullEntity);
    REQUIRE(local2 != kNullEntity);
    // The flash is written 4 units above the effect: with scale 2 it is drawn 8 above it.
    CHECK(w2->get<Transform>(flash2)->position.y == doctest::Approx(4.0f));
    CHECK(w2->world_position(flash2).y == doctest::Approx(50.0f + 8.0f));
    CHECK(w1->world_position(flash1).y == doctest::Approx(50.0f + 4.0f));
    // The light grows with it.
    CHECK(w1->get<Light2D>(flash1)->radius == doctest::Approx(120.0f));
    CHECK(w2->get<Light2D>(flash2)->radius == doctest::Approx(240.0f));
    CHECK(w2->get<Light2D>(flash2)->height == doctest::Approx(2.0f * w1->get<Light2D>(flash1)->height));
    // A world-space emitter: sizes, speed, gravity, turbulence and trail width double. Times do not.
    const ParticleEmitter& a = *w1->get<ParticleEmitter>(sparks1);
    const ParticleEmitter& b = *w2->get<ParticleEmitter>(sparks2);
    CHECK(a.startSize == doctest::Approx(ParticleEmitter{}.startSize));
    CHECK(b.startSize == doctest::Approx(2.0f * a.startSize));
    CHECK(b.endSize == doctest::Approx(2.0f * a.endSize));
    CHECK(b.speed == doctest::Approx(180.0f));
    CHECK(b.gravity.y == doctest::Approx(-200.0f));
    CHECK(b.noiseStrength == doctest::Approx(20.0f));
    CHECK(b.noiseScale == doctest::Approx(2.0f * a.noiseScale));
    CHECK(b.trailWidth == doctest::Approx(6.0f));
    CHECK(b.lifetime == doctest::Approx(a.lifetime));
    CHECK(b.rate == doctest::Approx(a.rate));
    CHECK(b.burst == a.burst);
    CHECK(w2->get<Vfx>(e2)->duration == doctest::Approx(w1->get<Vfx>(e1)->duration));
    // The inline sub-emitter (and its own) is scaled, with its shape.
    const Json& death = b.subEmitters["death"]["emitter"];
    CHECK(death["speed"].get<double>() == doctest::Approx(100.0));
    CHECK(death["startSize"].get<double>() == doctest::Approx(12.0));
    CHECK(death["shapeSize"][0].get<double>() == doctest::Approx(8.0));
    CHECK(death["subEmitters"]["death"]["emitter"]["gravity"][1].get<double>() == doctest::Approx(-40.0));
    CHECK(a.subEmitters["death"]["emitter"]["speed"].get<double>() == doctest::Approx(50.0));  // scale 1 leaves the document's values
    // An emitter in its own space: the matrix of the effect already stretches how far its particles fly, so only the sizes change.
    const ParticleEmitter& la = *w1->get<ParticleEmitter>(local1);
    const ParticleEmitter& lb = *w2->get<ParticleEmitter>(local2);
    CHECK(lb.startSize == doctest::Approx(2.0f * la.startSize));
    CHECK(lb.speed == doctest::Approx(la.speed));
    CHECK(lb.gravity.y == doctest::Approx(la.gravity.y));
    // The command part is called with the arguments of the file, whatever the scale.
    VfxHost host;
    std::vector<std::string> calls;
    host.call = [&](const std::string& command, const Json& args) {
        calls.push_back(command + " " + args.dump());
        return std::string();
    };
    for (int i = 0; i < 20; ++i) update_vfx(*w2, 1.0f / 60.0f, host);
    REQUIRE(calls.size() == 1);
    CHECK(calls[0] == "feel.shake {\"amount\":0.5}");
}

TEST_CASE("vfx: a Vfx in a scene scales with the scale of its entity, and a scale of 1 changes nothing") {
    TempDir tmp("fa_vfx_scale_scene");
    const std::string path = tmp.file("hit.vfx.json");
    write(path, hit_effect());
    World w;
    Entity e = w.create("torch");
    w.get<Transform>(e)->scale = {3, 3, 1};
    w.add<Vfx>(e).effect = path;
    VfxHost none;
    update_vfx(w, 1.0f / 60.0f, none);
    w.flush();
    Entity sparks = kNullEntity;
    for (Entity c : w.children(e))
        if (w.info(c).name == "sparks") sparks = c;
    REQUIRE(sparks != kNullEntity);
    CHECK(w.get<ParticleEmitter>(sparks)->startSize == doctest::Approx(3.0f * ParticleEmitter{}.startSize));
}
