// The job system (fa/core/jobs.h). doctest's CHECK is not thread-safe: jobs only record into atomics or locked
// vectors, and the checks run on the test thread.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/core/profiler.h"

using namespace fa;

namespace {

// Starts the pool for one test and stops it at the end (also when a REQUIRE fails).
struct PoolScope {
    explicit PoolScope(const jobs::Settings& s) { jobs::start(s); }
    ~PoolScope() { jobs::stop(); }
    PoolScope(const PoolScope&) = delete;
    PoolScope& operator=(const PoolScope&) = delete;
};

// Every configuration the determinism rule covers: no workers, one, several, and the inline debug mode.
std::vector<jobs::Settings> all_modes() {
    return {jobs::Settings::threads(0), jobs::Settings::threads(1), jobs::Settings::threads(4),
            jobs::Settings::inline_jobs()};
}

struct Order {
    std::mutex mu;
    std::vector<std::string> names;
    void add(const std::string& n) {
        std::lock_guard<std::mutex> lk(mu);
        names.push_back(n);
    }
    std::size_t pos(const std::string& n) {
        std::lock_guard<std::mutex> lk(mu);
        return std::size_t(std::find(names.begin(), names.end(), n) - names.begin());
    }
};

std::uint32_t float_bits(float f) {
    std::uint32_t u = 0;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

// Per-item values from the chunk's own random stream, then an order-sensitive float sum merged in chunk order.
struct DetResult {
    std::vector<float> values;
    std::uint32_t sumBits = 0;
};

DetResult deterministic_work() {
    DetResult r;
    r.values.assign(1000, 0.0f);
    auto ok = jobs::parallel_for("test.det", r.values.size(), 37, [&](const jobs::Chunk& c) {
        Rng rng = c.rng();
        for (std::size_t i = c.begin; i < c.end; ++i) r.values[i] = rng.range(-1.0f, 1.0f) * float(i);
    }, 1234);
    REQUIRE(ok.ok());
    auto sum = jobs::parallel_reduce<float>("test.sum", r.values.size(), 64, 0.0f, [&](const jobs::Chunk& c) {
        float s = 0;
        for (std::size_t i = c.begin; i < c.end; ++i) s += r.values[i] * 0.001f;
        return s;
    }, [](float a, float b) { return a + b; });
    REQUIRE(sum.ok());
    r.sumBits = float_bits(sum.value());
    return r;
}

}  // namespace

TEST_CASE("jobs: chunk bounds and seeds depend only on count, grain, seed and index") {
    CHECK(jobs::chunk_count(0, 10) == 0);
    CHECK(jobs::chunk_count(10, 3) == 4);
    CHECK(jobs::chunk_count(9, 3) == 3);
    CHECK(jobs::chunk_count(5, 0) == 5);  // grain 0 counts as 1
    const jobs::Chunk last = jobs::chunk_at(10, 3, 3, 7);
    CHECK(last.begin == 9);
    CHECK(last.end == 10);
    CHECK(last.size() == 1);
    CHECK(last.seed == jobs::chunk_seed(7, 3));
    CHECK(jobs::chunk_seed(7, 3) == jobs::chunk_seed(7, 3));
    CHECK(jobs::chunk_seed(7, 3) != jobs::chunk_seed(7, 4));
    CHECK(jobs::chunk_seed(7, 3) != jobs::chunk_seed(8, 3));
    CHECK(jobs::chunk_seed(0, 0) == 0xe220a8397b1dcdafULL);  // splitmix64: the same number on every platform
    Rng a = last.rng(), b = jobs::chunk_at(10, 3, 3, 7).rng();
    CHECK(a.next_u32() == b.next_u32());
}

TEST_CASE("jobs: settings parse auto, inline and counts, and errors teach") {
    auto a = jobs::parse_settings(Json("auto"), "factoria.json /runtime/jobThreads");
    REQUIRE(a.ok());
    CHECK(a->mode == jobs::Settings::Mode::Auto);
    auto i = jobs::parse_settings(Json("Inline"), "x");
    REQUIRE(i.ok());
    CHECK(i->mode == jobs::Settings::Mode::Inline);
    auto n = jobs::parse_settings(Json(3), "x");
    REQUIRE(n.ok());
    CHECK(n->mode == jobs::Settings::Mode::Count);
    CHECK(n->count == 3);
    CHECK(jobs::parse_settings(Json(0), "x")->count == 0);
    CHECK(jobs::parse_settings(Json(2.0), "x")->count == 2);
    CHECK(jobs::parse_settings_text(" 5 ", "FA_JOB_THREADS")->count == 5);
    CHECK(jobs::parse_settings(Json("4"), "x")->count == 4);

    auto neg = jobs::parse_settings(Json(-1), "factoria.json /runtime/jobThreads");
    REQUIRE(!neg.ok());
    CHECK(neg.error().message.find("factoria.json /runtime/jobThreads") != std::string::npos);
    CHECK(neg.error().message.find("out of range") != std::string::npos);
    CHECK(!jobs::parse_settings(Json(jobs::kMaxWorkers + 1), "x").ok());
    CHECK(!jobs::parse_settings(Json(std::uint64_t(1) << 40), "x").ok());
    CHECK(!jobs::parse_settings_text("99999999999999999999999", "x").ok());
    CHECK(!jobs::parse_settings(Json(2.5), "x").ok());
    CHECK(!jobs::parse_settings(Json(true), "x").ok());
    auto typo = jobs::parse_settings_text("autto", "FA_JOB_THREADS");
    REQUIRE(!typo.ok());
    CHECK(typo.error().message.find("Did you mean 'auto'") != std::string::npos);
    CHECK(!typo.error().hint.empty());

    CHECK(jobs::Settings::threads(3).describe() == "3");
    CHECK(jobs::Settings::threads(3).to_json() == Json(3));
    CHECK(jobs::Settings::automatic().to_json() == Json("auto"));
    CHECK(jobs::Settings::inline_jobs().describe() == "inline");
}

TEST_CASE("jobs: auto is hardware threads - 1, capped") {
    CHECK(jobs::hardware_threads() >= 1);
    if (!jobs::threads_supported()) {
        CHECK(jobs::auto_worker_count(16) == 0);
        return;
    }
    CHECK(jobs::auto_worker_count(1) == 0);
    CHECK(jobs::auto_worker_count(4) == 3);
    CHECK(jobs::auto_worker_count(64) <= jobs::kAutoCapDesktop);
    CHECK(jobs::resolve_workers(jobs::Settings::inline_jobs()) == 0);
    CHECK(jobs::resolve_workers(jobs::Settings::threads(5)) == 5);
}

TEST_CASE("jobs: before the pool starts every job runs at once on the caller") {
    REQUIRE(!jobs::running());
    CHECK(jobs::worker_count() == 0);
    int ran = 0;
    jobs::Handle h = jobs::submit("test.inline", [&] { ++ran; });
    CHECK(ran == 1);
    CHECK(h.done());
    CHECK(jobs::wait(h).ok());
    std::vector<std::size_t> order;
    CHECK(jobs::parallel_for("test.order", 10, 3, [&](const jobs::Chunk& c) { order.push_back(c.index); }).ok());
    CHECK(order == std::vector<std::size_t>{0, 1, 2, 3});
    CHECK(jobs::wait(jobs::Handle{}).ok());  // an empty handle is done
}

TEST_CASE("jobs: dependencies run in order with 0, 1 and 4 workers and inline") {
    for (const jobs::Settings& s : all_modes()) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        CHECK(jobs::running());
        CHECK(jobs::worker_count() == jobs::resolve_workers(s));
        Order order;
        jobs::Handle a = jobs::submit("a", [&] { order.add("a"); });
        jobs::Handle b = jobs::submit("b", [&] { order.add("b"); }, {a});
        jobs::Handle c = jobs::submit("c", [&] { order.add("c"); }, {a});
        jobs::Handle d = jobs::submit("d", [&] { order.add("d"); }, {b, c});
        jobs::Handle e = jobs::submit("e", [&] { order.add("e"); }, {d});
        REQUIRE(jobs::wait(e).ok());
        CHECK(a.done());
        CHECK(d.done());
        REQUIRE(order.names.size() == 5);
        CHECK(order.pos("a") < order.pos("b"));
        CHECK(order.pos("a") < order.pos("c"));
        CHECK(order.pos("b") < order.pos("d"));
        CHECK(order.pos("c") < order.pos("d"));
        CHECK(order.pos("d") < order.pos("e"));
        CHECK(e.name() == "e");
    }
}

TEST_CASE("jobs: inline mode runs each job when it is submitted, on the main thread") {
    PoolScope pool(jobs::Settings::inline_jobs());
    CHECK(jobs::inline_mode());
    CHECK(jobs::worker_count() == 0);
    std::vector<int> order;
    bool onMain = true;
    for (int i = 0; i < 5; ++i) {
        jobs::Handle h = jobs::submit("test.inline", [&order, &onMain, i] {
            order.push_back(i);
            onMain = onMain && jobs::is_main_thread();
        });
        CHECK(h.done());
    }
    CHECK(order == std::vector<int>{0, 1, 2, 3, 4});
    CHECK(onMain);
}

TEST_CASE("jobs: a job that waits for another runs it instead of deadlocking") {
    for (const jobs::Settings& s : {jobs::Settings::threads(0), jobs::Settings::threads(1)}) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        std::atomic<int> innerRan{0};
        std::atomic<bool> innerOk{false};
        // With one worker the outer job holds it: the inner job can only run because the outer one's wait helps.
        jobs::Handle outer = jobs::submit("outer", [&] {
            jobs::Handle inner = jobs::submit("inner", [&] { innerRan.fetch_add(1); });
            innerOk = jobs::wait(inner).ok();
        });
        REQUIRE(jobs::wait(outer).ok());
        CHECK(innerRan.load() == 1);
        CHECK(innerOk.load());
    }
}

TEST_CASE("jobs: waiting for a job that depends on the waiting one returns an error, not a hang") {
    PoolScope pool(jobs::Settings::threads(0));
    jobs::Handle outer;
    std::string innerError;
    outer = jobs::submit("outer", [&] {
        jobs::Handle cycle = jobs::submit("cycle", [] {}, {outer});  // can only run after outer, which waits for it
        auto r = jobs::wait(cycle);
        innerError = r.ok() ? "" : r.error().message;
    });
    REQUIRE(jobs::wait(outer).ok());  // with 0 workers nothing ran outer before this wait
    CHECK(innerError.find("can never end") != std::string::npos);
}

TEST_CASE("jobs: nested parallel_for covers every item once") {
    PoolScope pool(jobs::Settings::threads(4));
    std::vector<int> hits(8 * 100, 0);
    auto r = jobs::parallel_for("test.outer", 8, 1, [&](const jobs::Chunk& outer) {
        auto inner = jobs::parallel_for("test.inner", 100, 7, [&](const jobs::Chunk& c) {
            for (std::size_t i = c.begin; i < c.end; ++i) hits[outer.index * 100 + i] += 1;
        });
        if (!inner) throw std::runtime_error(inner.error().message);
    });
    REQUIRE(r.ok());
    CHECK(std::all_of(hits.begin(), hits.end(), [](int h) { return h == 1; }));
}

TEST_CASE("jobs: a throw is caught, named and returned; dependents are skipped") {
    for (const jobs::Settings& s : all_modes()) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        std::atomic<bool> dependentRan{false};
        jobs::Handle bad = jobs::submit("test.bad", [] { throw std::runtime_error("broken input"); });
        jobs::Handle after = jobs::submit("test.after", [&] { dependentRan = true; }, {bad});
        jobs::Handle later = jobs::submit("test.later", [&] { dependentRan = true; }, {after});
        auto r = jobs::wait(bad);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("test.bad") != std::string::npos);
        CHECK(r.error().message.find("broken input") != std::string::npos);
        auto r2 = jobs::wait(later);
        REQUIRE(!r2.ok());
        CHECK(r2.error().message.find("did not run") != std::string::npos);
        CHECK(r2.error().message.find("broken input") != std::string::npos);
        CHECK(!dependentRan.load());
        auto odd = jobs::wait(jobs::submit("test.odd", [] { throw 42; }));
        REQUIRE(!odd.ok());
        CHECK(odd.error().message.find("not a std::exception") != std::string::npos);

        jobs::Group g;
        g.run("test.fine", [] {});
        g.run("test.first", [] { throw std::runtime_error("first"); });
        g.run("test.second", [] { throw std::runtime_error("second"); });
        auto gr = g.wait();
        REQUIRE(!gr.ok());
        CHECK(gr.error().message.find("test.first") != std::string::npos);  // the first in submit order
        CHECK(g.done());

        std::atomic<int> chunksRun{0};
        auto pf = jobs::parallel_for("test.chunks", 100, 10, [&](const jobs::Chunk& c) {
            chunksRun.fetch_add(1);
            if (c.index == 7 || c.index == 3) throw std::runtime_error("chunk " + std::to_string(c.index));
        });
        REQUIRE(!pf.ok());
        CHECK(chunksRun.load() == 10);  // every chunk ran
        CHECK(pf.error().message.find("chunk 3 (items 30..39)") != std::string::npos);  // the lowest index failing
        CHECK(pf.error().message.find("2 chunks failed") != std::string::npos);
    }
}

TEST_CASE("jobs: stop runs every queued job, also those queued while it stops") {
    std::atomic<int> ran{0};
    jobs::start(jobs::Settings::threads(2));
    for (int i = 0; i < 200; ++i) {
        (void)jobs::submit("test.queued", [&ran, i] {
            ran.fetch_add(1);
            if (i % 10 == 0) (void)jobs::submit("test.late", [&ran] { ran.fetch_add(1); });
        });
    }
    jobs::stop();
    CHECK(ran.load() == 220);
    CHECK(!jobs::running());
    CHECK(jobs::worker_count() == 0);
    // Afterwards jobs run inline again.
    int now = 0;
    (void)jobs::submit("test.after", [&] { now = 1; });
    CHECK(now == 1);
}

TEST_CASE("jobs: start and stop are reference counted; stop from a job is refused") {
    jobs::start(jobs::Settings::threads(1));
    jobs::start(jobs::Settings::threads(3));  // already running: keeps its first settings
    CHECK(jobs::worker_count() == 1);
    CHECK(jobs::settings() == jobs::Settings::threads(1));
    jobs::stop();
    CHECK(jobs::running());
    // Not wait(): this thread would help and run the job itself. A worker must take it.
    jobs::Handle h = jobs::submit("test.stop", [] { jobs::stop(); });
    for (int i = 0; i < 30000000 && !h.done(); ++i) std::this_thread::yield();
    REQUIRE(h.done());
    CHECK(jobs::running());  // the job's stop() was refused
    jobs::stop();
    CHECK(!jobs::running());
    jobs::stop();  // unmatched: a warning, nothing else
    CHECK(!jobs::running());
}

TEST_CASE("jobs: results are the same bits with 0, 1 and 4 workers and inline") {
    const DetResult reference = deterministic_work();  // pool stopped: every chunk on this thread, in order
    for (const jobs::Settings& s : all_modes()) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        for (int round = 0; round < 3; ++round) {
            const DetResult r = deterministic_work();
            CHECK(r.sumBits == reference.sumBits);
            CHECK(std::memcmp(r.values.data(), reference.values.data(), r.values.size() * sizeof(float)) == 0);
        }
    }
}

TEST_CASE("jobs: the main-thread queue runs in post order at the call, from any thread") {
    PoolScope pool(jobs::Settings::threads(2));
    REQUIRE(jobs::is_main_thread());
    CHECK(!jobs::is_worker_thread());
    std::vector<int> order;
    REQUIRE(jobs::wait(jobs::submit("test.post", [&] {
        for (int i = 0; i < 5; ++i) jobs::post_main("test.task", [&order, i] { order.push_back(i); });
        jobs::post_main("test.throws", [] { throw std::runtime_error("task failed"); });
        jobs::post_main("test.reposts", [&order] {
            jobs::post_main("test.next", [&order] { order.push_back(100); });  // runs at the next call
        });
    })).ok());
    CHECK(order.empty());  // nothing runs before the frame point
    CHECK(jobs::main_tasks_queued() == 7);
    CHECK(jobs::run_main_thread_tasks() == 7);
    CHECK(order == std::vector<int>{0, 1, 2, 3, 4});
    CHECK(jobs::run_main_thread_tasks() == 1);
    CHECK(order.back() == 100);
    // Another thread runs nothing while the pool runs.
    jobs::post_main("test.mine", [] {});
    int fromOther = -1;
    std::thread t([&] { fromOther = jobs::run_main_thread_tasks(); });
    t.join();
    CHECK(fromOther == 0);
    CHECK(jobs::run_main_thread_tasks() == 1);
}

TEST_CASE("jobs: a worker knows it is a worker") {
    PoolScope pool(jobs::Settings::threads(2));
    REQUIRE(jobs::worker_count() == 2);
    std::atomic<bool> started{false}, go{false}, sawWorker{false};
    jobs::Handle h = jobs::submit("test.who", [&] {
        sawWorker = jobs::is_worker_thread() && !jobs::is_main_thread() && jobs::current_lane() >= 1;
        started = true;
        while (!go.load()) std::this_thread::yield();
    });
    // This thread does not help here (it does not wait), so a worker must take the job.
    for (int i = 0; i < 30000000 && !started.load(); ++i) std::this_thread::yield();
    go = true;
    REQUIRE(jobs::wait(h).ok());
    CHECK(started.load());
    CHECK(sawWorker.load());
}

TEST_CASE("jobs: with 0 workers the frame end runs the jobs nobody waited for") {
    PoolScope pool(jobs::Settings::threads(0));
    std::atomic<int> ran{0};
    for (int i = 0; i < 3; ++i) (void)jobs::submit("test.fire", [&] { ran.fetch_add(1); });
    CHECK(ran.load() == 0);
    jobs::end_frame();
    CHECK(ran.load() == 3);
}

TEST_CASE("jobs: info counts last frame's jobs per thread") {
    PoolScope pool(jobs::Settings::threads(2));
    jobs::end_frame();
    REQUIRE(jobs::parallel_for("test.info", 16, 1, [](const jobs::Chunk&) {}).ok());
    REQUIRE(jobs::wait(jobs::submit("test.one", [] {})).ok());
    jobs::end_frame();
    const jobs::Info i = jobs::info();
    CHECK(i.running);
    CHECK(i.mode == "threads");
    CHECK(i.workers == jobs::worker_count());
    REQUIRE(i.lanes.size() == std::size_t(1 + i.workers));
    CHECK(i.lanes[0].name == "main");
    if (i.workers > 0) CHECK(i.lanes[1].name == "worker 1");
    CHECK(i.jobsLastFrame == 17);
    CHECK(i.submittedLastFrame == 17);
    CHECK(i.pending == 0);
    const Json j = jobs::info_json(i);
    CHECK(j.value("mode", "") == "threads");
    CHECK(j.contains("lanes"));
    CHECK(j.at("lastFrame").value("jobs", 0) == 17);
    CHECK(j.at("setting") == Json(2));
}

TEST_CASE("jobs: the profiler gets one lane per thread with the jobs' names") {
    PoolScope pool(jobs::Settings::threads(2));
    Profiler& p = Profiler::get();
    p.set_enabled(true);
    p.begin_frame();
    REQUIRE(jobs::parallel_for("test.lanes", 32, 1, [](const jobs::Chunk&) {
        volatile int x = 0;
        for (int k = 0; k < 1000; ++k) x = x + k;
    }).ok());
    p.end_frame();
    const ProfFrame f = p.last();
    ProfileSummary sum;
    sum.add_frame(f);
    p.set_enabled(false);
    REQUIRE(f.lanes.size() == std::size_t(1 + jobs::worker_count()));
    CHECK(f.lanes[0].name == "main");
    int total = 0;
    bool named = true;
    for (const ProfLane& l : f.lanes) {
        total += l.jobs;
        for (const ProfJobSample& s : l.samples) named = named && s.name == "test.lanes";
    }
    CHECK(total == 32);
    CHECK(named);
    const Json j = sum.to_json();
    REQUIRE(j.contains("threads"));
    REQUIRE(j.at("threads").size() == f.lanes.size());
    CHECK(j.at("threads").at(0).value("name", "") == "main");
}

TEST_CASE("jobs: stress: many small jobs with dependencies, far below the test time limit") {
    PoolScope pool(jobs::Settings::threads(4));
    std::atomic<std::uint64_t> sum{0};
    std::uint64_t expected = 0;
    for (int round = 0; round < 20; ++round) {
        std::vector<jobs::Handle> hs;
        hs.reserve(400);
        for (int i = 0; i < 400; ++i) {
            std::vector<jobs::Handle> deps;
            if (i >= 3) deps = {hs[std::size_t(i - 3)], hs[std::size_t(i / 2)]};
            hs.push_back(jobs::submit("test.stress", [&sum, i] { sum.fetch_add(std::uint64_t(i)); }, deps));
            expected += std::uint64_t(i);
        }
        REQUIRE(jobs::wait_all(hs).ok());
        std::vector<std::uint64_t> squares(5000);
        REQUIRE(jobs::parallel_for("test.stress.for", squares.size(), 64, [&](const jobs::Chunk& c) {
            for (std::size_t k = c.begin; k < c.end; ++k) squares[k] = std::uint64_t(k) * k;
        }).ok());
        CHECK(squares[4999] == 4999ull * 4999ull);
        jobs::end_frame();
    }
    CHECK(sum.load() == expected);
}
