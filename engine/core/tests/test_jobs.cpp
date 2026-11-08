// The job system (fa/core/jobs.h). doctest's CHECK is not thread-safe: jobs only record into atomics or locked
// vectors, and the checks run on the test thread.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <chrono>
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
    explicit PoolScope(const jobs::Settings& s) { REQUIRE(jobs::start(s).ok()); }
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
    auto i = jobs::parse_settings(Json("inline"), "x");
    REQUIRE(i.ok());
    CHECK(i->mode == jobs::Settings::Mode::Inline);
    // A JSON value is exactly what the schema allows: lowercase words, integers.
    auto upper = jobs::parse_settings(Json("Inline"), "factoria.json /runtime/jobThreads");
    REQUIRE(!upper.ok());
    CHECK(upper.error().message.find("write \"inline\"") != std::string::npos);
    CHECK(!jobs::parse_settings(Json("AUTO"), "x").ok());
    CHECK(!jobs::parse_settings(Json(" auto"), "x").ok());
    auto decimal = jobs::parse_settings(Json(4.0), "x");
    REQUIRE(!decimal.ok());
    CHECK(decimal.error().message.find("not an integer") != std::string::npos);
    CHECK(decimal.error().hint.find("\"jobThreads\": 4") != std::string::npos);
    auto jsonTypo = jobs::parse_settings(Json("autto"), "x");
    REQUIRE(!jsonTypo.ok());
    CHECK(jsonTypo.error().message.find("Did you mean 'auto'") != std::string::npos);
    // Text (FA_JOB_THREADS, EngineConfig) is lenient: any case, spaces around.
    CHECK(jobs::parse_settings_text(" Inline ", "FA_JOB_THREADS")->mode == jobs::Settings::Mode::Inline);
    auto n = jobs::parse_settings(Json(3), "x");
    REQUIRE(n.ok());
    CHECK(n->mode == jobs::Settings::Mode::Count);
    CHECK(n->count == 3);
    CHECK(jobs::parse_settings(Json(0), "x")->count == 0);
    CHECK(jobs::parse_settings_text(" 5 ", "FA_JOB_THREADS")->count == 5);
    auto quoted = jobs::parse_settings(Json("4"), "factoria.json /runtime/jobThreads");  // the schema wants a number
    REQUIRE(!quoted.ok());
    CHECK(quoted.error().message.find("write it as a number") != std::string::npos);
    CHECK(quoted.error().hint.find("\"jobThreads\": 4") != std::string::npos);
    CHECK(jobs::parse_settings_text("4", "FA_JOB_THREADS")->count == 4);  // text (an environment variable) may

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
    REQUIRE(jobs::start(jobs::Settings::threads(2)).ok());
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
    REQUIRE(jobs::start(jobs::Settings::threads(1)).ok());
    REQUIRE(jobs::start(jobs::Settings::threads(3)).ok());  // already running: keeps its first settings
    CHECK(jobs::worker_count() == 1);
    CHECK(jobs::settings() == jobs::Settings::threads(1));
    jobs::stop();
    CHECK(jobs::running());
    // Not wait(): this thread would help and run the job itself. A worker must take it.
    std::atomic<bool> startRefused{false};
    jobs::Handle h = jobs::submit("test.stop", [&] {
        jobs::stop();
        auto r = jobs::start(jobs::Settings::threads(1));
        startRefused = !r.ok() && r.error().message.find("inside a job") != std::string::npos;
    });
    for (int i = 0; i < 30000000 && !h.done(); ++i) std::this_thread::yield();
    REQUIRE(h.done());
    CHECK(jobs::running());  // the job's stop() was refused
    CHECK(startRefused.load());
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

namespace {
// Spins (no sleeping: the tests never depend on timing) until `cond` holds; false after far more tries than a loaded
// machine needs.
template <class F>
bool spin_until(F&& cond) {
    for (long i = 0; i < 200000000L; ++i) {
        if (cond()) return true;
        std::this_thread::yield();
    }
    return cond();
}
}  // namespace

TEST_CASE("jobs: a waiting job's thread never takes an unrelated job (no false 'can never end')") {
    // A waits for H, which runs on the other worker. C is queued meanwhile and waits for A. A's thread must not pick C up
    // while it waits: C would then sit on top of A on that thread, and C's wait for A could never end.
    PoolScope pool(jobs::Settings::threads(2));
    REQUIRE(jobs::worker_count() == 2);
    std::atomic<bool> hStarted{false}, cStarted{false}, aWaitOk{false}, cWaitOk{false};
    std::atomic<int> cLane{-1};
    jobs::Handle h = jobs::submit("test.h", [&] {
        hStarted = true;
        spin_until([&] { return cStarted.load(); });  // H ends only once C runs: C cannot have waited for a worker
    });
    REQUIRE(spin_until([&] { return hStarted.load(); }));
    jobs::Handle a = jobs::submit("test.a", [&, h] { aWaitOk = jobs::wait(h).ok(); });
    REQUIRE(spin_until([] { return jobs::info().waiting >= 1; }));  // A sits in its wait for H on the other worker
    jobs::Handle c = jobs::submit("test.c", [&, a] {
        cLane = jobs::current_lane();
        cStarted = true;
        cWaitOk = jobs::wait(a).ok();
    });
    // Both workers are busy (H spins, A waits for H), so only this thread's wait can run C.
    REQUIRE(jobs::wait(c).ok());
    CHECK(cLane.load() == 0);
    CHECK(cWaitOk.load());
    REQUIRE(jobs::wait(a).ok());
    CHECK(aWaitOk.load());
}

TEST_CASE("jobs: parallel_for waits for its own chunks and never runs another job on the calling thread") {
    // One worker runs the call's helper; its chunk queues a foreign job F and holds until the main thread is in the
    // wait at the end of parallel_for. The main thread must sleep there (its own helper is running), not take F.
    PoolScope pool(jobs::Settings::threads(1));
    REQUIRE(jobs::worker_count() == 1);
    std::atomic<bool> workerInChunk{false};
    std::atomic<int> fLane{-1};
    jobs::Handle f;
    std::mutex fMu;
    auto r = jobs::parallel_for("test.own", 2, 1, [&](const jobs::Chunk&) {
        if (jobs::is_worker_thread()) {
            {
                std::lock_guard<std::mutex> lk(fMu);
                f = jobs::submit("test.foreign", [&] { fLane = jobs::current_lane(); });
            }
            workerInChunk = true;
            spin_until([] { return jobs::info().waiting >= 1; });  // the main thread waits for this helper
        } else {
            spin_until([&] { return workerInChunk.load(); });  // the worker holds the other chunk
        }
    });
    REQUIRE(r.ok());
    REQUIRE(workerInChunk.load());
    jobs::Handle foreign;
    {
        std::lock_guard<std::mutex> lk(fMu);
        foreign = f;
    }
    // Not wait(): that would run F here, legitimately. The worker takes it once the helper is done.
    REQUIRE(spin_until([&] { return foreign.done(); }));
    CHECK(fLane.load() == 1);
}

TEST_CASE("jobs: a wait that loops back through another thread's wait returns an error") {
    // A (worker 1) waits for B; B (worker 2) waits for X, and X depends on A: X can only run after A, A after B, B
    // after X. B's wait sees the loop and fails; A's wait then ends and X runs.
    PoolScope pool(jobs::Settings::threads(2));
    REQUIRE(jobs::worker_count() == 2);
    std::atomic<bool> handlesSet{false}, aOk{false}, xRan{false};
    std::string bError;
    jobs::Handle a, b;
    a = jobs::submit("test.loop.a", [&] {
        spin_until([&] { return handlesSet.load(); });
        aOk = jobs::wait(b).ok();
    });
    b = jobs::submit("test.loop.b", [&] {
        spin_until([&] { return handlesSet.load(); });
        spin_until([] { return jobs::info().waiting >= 1; });  // A waits for this job
        jobs::Handle x = jobs::submit("test.loop.x", [&] { xRan = true; }, {a});
        auto r = jobs::wait(x);
        bError = r.ok() ? "" : r.error().message;
    });
    handlesSet = true;
    // Not wait(): this thread would count as a waiter, and B must start its wait only after A is in its own.
    REQUIRE(spin_until([&] { return a.done() && b.done(); }));
    REQUIRE(jobs::wait(a).ok());
    REQUIRE(jobs::wait(b).ok());
    CHECK(aOk.load());
    CHECK(bError.find("can never end") != std::string::npos);
    jobs::end_frame();
    REQUIRE(spin_until([&] { return xRan.load(); }));  // X ran once A was done
}

TEST_CASE("jobs: an owner counts its jobs, the jobs they submit too, and waits for them") {
    for (const jobs::Settings& s : {jobs::Settings::threads(0), jobs::Settings::threads(2)}) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        jobs::Owner engineA("engine A"), engineB("engine B");
        std::atomic<bool> release{false};
        std::atomic<int> ran{0}, asOwner{0};
        {
            jobs::OwnerScope scope(&engineA);
            CHECK(jobs::current_owner_name() == "engine A");
            for (int i = 0; i < 3; ++i)
                (void)jobs::submit("test.owned", [&] {
                    spin_until([&] { return release.load(); });
                    if (jobs::current_owner_name() == "engine A") asOwner.fetch_add(1);  // a job runs as its owner
                    (void)jobs::submit("test.child", [&] { ran.fetch_add(1); });  // engine A's too
                    ran.fetch_add(1);
                });
        }
        CHECK(jobs::current_owner_name().empty());
        {
            jobs::OwnerScope scope(&engineB);
            (void)jobs::submit("test.other", [&] { ran.fetch_add(100); });
        }
        CHECK(engineA.pending() >= 3);
        release = true;
        REQUIRE(engineA.wait().ok());
        CHECK(engineA.pending() == 0);
        CHECK(ran.load() % 100 == 6);  // engine A's three jobs and their three children
        CHECK(asOwner.load() == 3);
        REQUIRE(engineB.wait().ok());
        CHECK(ran.load() == 106);

        // From inside a job the wait is refused (the job may be one of the owner's).
        std::string inner;
        {
            jobs::OwnerScope scope(&engineA);
            REQUIRE(jobs::wait(jobs::submit("test.inner", [&] {
                auto r = engineA.wait();
                inner = r.ok() ? "" : r.error().message;
            })).ok());
        }
        CHECK(inner.find("inside a job") != std::string::npos);
    }
}

TEST_CASE("jobs: main-thread tasks go to their owner's queue; with the pool stopped they run at once") {
    {
        PoolScope pool(jobs::Settings::threads(1));
        jobs::Owner engineA("engine A"), engineB("engine B");
        std::vector<std::string> order;
        {
            jobs::OwnerScope scope(&engineA);
            REQUIRE(jobs::wait(jobs::submit("test.posts", [&] {
                jobs::post_main("test.a", [&] { order.push_back("a"); });  // the job's owner: engine A
            })).ok());
        }
        {
            jobs::OwnerScope scope(&engineB);
            jobs::post_main("test.b", [&] { order.push_back("b"); });
        }
        jobs::post_main("test.shared", [&] { order.push_back("shared"); });
        CHECK(jobs::main_tasks_queued() == 3);
        CHECK(engineA.main_tasks_queued() == 1);
        CHECK(engineB.main_tasks_queued() == 1);
        CHECK(engineB.run_main_thread_tasks() == 1);
        CHECK(order == std::vector<std::string>{"b"});
        CHECK(jobs::run_main_thread_tasks() == 1);  // the shared queue only
        CHECK(order == std::vector<std::string>{"b", "shared"});
        engineA.close();  // dropped, never run
        CHECK(engineA.main_tasks_queued() == 0);
        CHECK(engineA.run_main_thread_tasks() == 0);
        CHECK(jobs::main_tasks_queued() == 0);
        CHECK(order.size() == 2);
    }
    REQUIRE(!jobs::running());
    int ranNow = 0;
    jobs::post_main("test.now", [&] { ++ranNow; });
    CHECK(ranNow == 1);
    CHECK(jobs::main_tasks_queued() == 0);
}

TEST_CASE("jobs: with two owners only the first one to end a frame closes the frame statistics") {
    PoolScope pool(jobs::Settings::threads(1));
    jobs::Owner editor("editor"), preview("preview");
    jobs::end_frame(&editor);  // the editor closes the frames from now on
    for (int i = 0; i < 3; ++i) REQUIRE(jobs::wait(jobs::submit("test.frame", [] {})).ok());
    jobs::end_frame(&preview);  // not its frames: nothing changes
    CHECK(jobs::info().submittedLastFrame == 0);
    jobs::end_frame(&editor);
    CHECK(jobs::info().submittedLastFrame == 3);
    editor.close();  // the editor stops: the next owner takes over
    REQUIRE(jobs::wait(jobs::submit("test.frame", [] {})).ok());
    jobs::end_frame(&preview);
    CHECK(jobs::info().submittedLastFrame == 1);
}

TEST_CASE("jobs: start from another thread while the pool runs is refused") {
    PoolScope pool(jobs::Settings::threads(1));
    std::string error;
    std::thread t([&] {
        auto r = jobs::start(jobs::Settings::threads(1));
        error = r.ok() ? "" : r.error().message;
        if (r.ok()) jobs::stop();
    });
    t.join();
    CHECK(error.find("not the job pool's main thread") != std::string::npos);
    CHECK(jobs::running());
    CHECK(jobs::is_main_thread());
}

TEST_CASE("jobs: a start from another thread during a stop finds either the old pool or a whole new one") {
    for (int round = 0; round < 3; ++round) {
        REQUIRE(jobs::start(jobs::Settings::threads(2)).ok());
        std::atomic<bool> go{false};
        std::atomic<bool> other{false};
        std::atomic<int> otherWorkers{-1};
        std::atomic<bool> otherStarted{false};
        (void)jobs::submit("test.slow", [&] {  // keeps a worker busy, so stop() is still joining when the start comes
            go = true;
            for (int i = 0; i < 2000; ++i) std::this_thread::yield();
        });
        std::thread t([&] {
            spin_until([&] { return go.load(); });
            auto r = jobs::start(jobs::Settings::threads(3));
            otherStarted = r.ok();
            if (r.ok()) {
                otherWorkers = jobs::worker_count();
                std::atomic<int> ran{0};
                const bool waited = jobs::wait(jobs::submit("test.new", [&] { ran = 1; })).ok();  // no CHECK here:
                other = waited && ran.load() == 1;                                                  // not thread-safe
                jobs::stop();
            }
        });
        jobs::stop();
        t.join();
        CHECK(!jobs::running());
        if (otherStarted) {  // it came after the stop: a whole pool with its own settings, and jobs ran
            CHECK(otherWorkers.load() == jobs::resolve_workers(jobs::Settings::threads(3)));
            CHECK(other.load());
        }
    }
}

TEST_CASE("jobs: a helper chunk that waits for the job running parallel_for gets an error; the call waits for it") {
    // J runs on the main thread (the worker is busy with B when the main thread's wait takes it); its parallel_for
    // queues one helper, which the worker takes once B ends. The worker's chunk waits for J: J can only end after
    // parallel_for returns, and that waits for this chunk. The chunk's wait must fail, and parallel_for must not return
    // before the chunk has ended (fn and what it captures belong to J).
    PoolScope pool(jobs::Settings::threads(1));
    REQUIRE(jobs::worker_count() == 1);
    std::atomic<bool> jStarted{false}, workerInChunk{false}, workerWaitReturned{false}, workerChunkDone{false};
    std::atomic<bool> chunkDoneAtReturn{false}, pfOk{false}, mainRanJ{false}, workerRanB{false}, bStarted{false};
    std::string workerError;  // written by the worker's chunk, read here only after J is done
    jobs::Handle b = jobs::submit("test.busy", [&] {
        workerRanB = jobs::is_worker_thread();
        bStarted = true;
        spin_until([&] { return jStarted.load(); });
    });
    REQUIRE(spin_until([&] { return bStarted.load(); }));  // the worker holds B: J stays queued below
    jobs::Handle j;
    std::atomic<bool> handleSet{false};
    j = jobs::submit("test.j", [&] {
        mainRanJ = jobs::is_main_thread();
        spin_until([&] { return handleSet.load(); });
        jStarted = true;
        auto r = jobs::parallel_for("test.pf.loop", 2, 1, [&](const jobs::Chunk&) {
            if (jobs::is_worker_thread()) {
                workerInChunk = true;
                auto w = jobs::wait(j);
                workerError = w.ok() ? "" : w.error().message;
                workerWaitReturned = true;
                workerChunkDone = true;
            } else {
                // Holds this chunk until the worker is in its wait (or already out of it), so the call reaches its
                // end while the worker's chunk may still be in that wait.
                spin_until([&] { return workerInChunk.load(); });
                spin_until([&] { return workerWaitReturned.load() || jobs::info().waiting >= 2; });
            }
        });
        chunkDoneAtReturn = workerChunkDone.load();
        pfOk = r.ok();
    });
    handleSet = true;
    REQUIRE(jobs::wait(j).ok());  // runs J here: the worker is in B
    REQUIRE(jobs::wait(b).ok());
    CHECK(workerRanB.load());
    REQUIRE(mainRanJ.load());
    REQUIRE(workerInChunk.load());  // the worker ran a chunk: the loop was really there
    CHECK(chunkDoneAtReturn.load());
    CHECK(pfOk.load());
    CHECK(workerError.find("can never end") != std::string::npos);
}

TEST_CASE("jobs: chunks of parallel_for run by the calling thread count as inside a job") {
    for (const jobs::Settings& s : {jobs::Settings::threads(0), jobs::Settings::threads(2)}) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        jobs::Owner owner("test owner");
        std::atomic<int> callerChunks{0}, startRefused{0}, waitRefused{0};
        auto r = jobs::parallel_for("test.inside", 4, 1, [&](const jobs::Chunk&) {
            if (jobs::is_worker_thread()) {  // holds its chunk until the caller has one of its own
                spin_until([&] { return callerChunks.load() >= 1; });
                return;
            }
            callerChunks.fetch_add(1);
            auto st = jobs::start(jobs::Settings::threads(1));
            if (!st.ok() && st.error().message.find("inside a job") != std::string::npos) startRefused.fetch_add(1);
            if (st.ok()) jobs::stop();
            auto w = owner.wait();
            if (!w.ok() && w.error().message.find("inside a job") != std::string::npos) waitRefused.fetch_add(1);
        });
        REQUIRE(r.ok());
        REQUIRE(callerChunks.load() >= 1);
        CHECK(startRefused.load() == callerChunks.load());
        CHECK(waitRefused.load() == callerChunks.load());
        CHECK(jobs::worker_count() == jobs::resolve_workers(s));  // the refused start changed nothing
    }
}

namespace {
// Sleeps (steady clock, so a stalled VM only makes it longer) until `ms` have passed since `since`.
void sleep_until_elapsed(std::chrono::steady_clock::time_point since, int ms) {
    while (std::chrono::steady_clock::now() - since < std::chrono::milliseconds(ms))
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
}
}  // namespace

TEST_CASE("jobs: the frame statistics go to another owner after kFrameOwnerHandOverMs without their owner") {
    PoolScope pool(jobs::Settings::threads(1));
    jobs::Owner editor("editor"), preview("preview");
    jobs::end_frame(&editor);  // the editor closes the frames, then stops ending them (it never closes either)
    const auto editorLast = std::chrono::steady_clock::now();
    REQUIRE(jobs::wait(jobs::submit("test.frame", [] {})).ok());
    jobs::end_frame(&preview);
    // Only when the machine did not stall for most of the interval: then the editor surely still holds the frames.
    if (std::chrono::steady_clock::now() - editorLast < std::chrono::milliseconds(jobs::kFrameOwnerHandOverMs / 2))
        CHECK(jobs::info().submittedLastFrame == 0);  // still the editor's frame
    sleep_until_elapsed(editorLast, jobs::kFrameOwnerHandOverMs + 50);
    jobs::end_frame(&preview);  // the editor was silent for the whole interval: the preview takes over, closes this frame
    CHECK(jobs::info().submittedLastFrame == 1);
    REQUIRE(jobs::wait(jobs::submit("test.frame", [] {})).ok());
    REQUIRE(jobs::wait(jobs::submit("test.frame", [] {})).ok());
    jobs::end_frame(&editor);  // the editor now is the other one (the preview called a moment ago)
    jobs::end_frame(&preview);
    CHECK(jobs::info().submittedLastFrame == 2);
}

TEST_CASE("jobs: a secondary engine running many frames per main frame does not take the frames") {
    PoolScope pool(jobs::Settings::threads(1));
    jobs::Owner mainEngine("main"), secondary("secondary");
    // Frame k queues k + 1 jobs, so the frame a close reports says whose call closed it.
    for (int frame = 0; frame < 3; ++frame) {
        const auto start = std::chrono::steady_clock::now();
        jobs::end_frame(&mainEngine);  // the main engine closes the previous frame (frame jobs)...
        for (int i = 0; i <= frame; ++i) REQUIRE(jobs::wait(jobs::submit("test.frame", [] {})).ok());
        // ...then the secondary runs far more than the old limit of 8 calls before the main engine's next frame.
        for (int i = 0; i < 50; ++i) jobs::end_frame(&secondary);
        // Only when the machine did not stall for most of the interval (else the main engine may have lost the frames).
        if (std::chrono::steady_clock::now() - start < std::chrono::milliseconds(jobs::kFrameOwnerHandOverMs / 2))
            CHECK(jobs::info().submittedLastFrame == frame);  // still what the main engine closed: nothing took over
    }
    jobs::end_frame(&mainEngine);
}

TEST_CASE("jobs: an owner's wait runs only what that owner needs, not another owner's queued jobs") {
    PoolScope pool(jobs::Settings::threads(0));  // nobody else runs queued jobs
    jobs::Owner a("engine A"), b("engine B");
    std::atomic<int> ranA{0}, ranB{0}, ranDep{0};
    jobs::Handle dep;
    {
        jobs::OwnerScope scope(&b);
        dep = jobs::submit("test.b.dep", [&] { ranDep.fetch_add(1); });  // engine B's, but engine A's job needs it
        (void)jobs::submit("test.b.other", [&] { ranB.fetch_add(1); });
    }
    {
        jobs::OwnerScope scope(&a);
        (void)jobs::submit("test.a", [&] { ranA.fetch_add(1); }, {dep});
    }
    REQUIRE(a.wait().ok());
    CHECK(ranA.load() == 1);
    CHECK(ranDep.load() == 1);
    CHECK(ranB.load() == 0);  // still queued for engine B
    CHECK(b.pending() == 1);
    REQUIRE(b.wait().ok());
    CHECK(ranB.load() == 1);
}
