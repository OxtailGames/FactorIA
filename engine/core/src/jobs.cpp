#include "fa/core/jobs.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <charconv>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <deque>
#include <exception>
#include <limits>
#include <mutex>
#include <system_error>
#include <thread>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/core/strings.h"
#include "jobs_internal.h"

namespace fa::jobs {

namespace detail {
struct JobState {
    std::string name;
    std::function<void()> fn;
    bool internal = false;  // a parallel_for helper: its chunks are counted, not the helper itself
    // Guarded by Pool::mu until finished; read-only after doneFlag is true.
    int pendingDeps = 0;
    bool queued = false;
    bool finished = false;
    bool failed = false;
    Error error;                                       // what wait() returns when failed
    Error rootError;                                   // the throw a failure goes back to (for skipped dependents)
    std::string failedDep;                             // the first dependency that failed: the job is skipped
    std::vector<std::shared_ptr<JobState>> dependents;
    std::atomic<bool> doneFlag{false};                 // finished, readable without the lock
};
}  // namespace detail

using detail::JobState;
using JobPtr = std::shared_ptr<JobState>;

struct Access {
    static const JobPtr& state(const Handle& h) { return h.state_; }
    static Handle make(JobPtr s) { return Handle(std::move(s)); }
};

namespace {

using Clock = std::chrono::steady_clock;

struct LaneCounters {
    std::atomic<std::uint64_t> jobs{0};
    std::atomic<std::uint64_t> busyNs{0};
};

struct MainTask {
    std::string name;
    std::function<void()> fn;
};

struct FrameStats {
    std::array<std::uint64_t, kMaxLanes> jobs{};
    std::array<std::uint64_t, kMaxLanes> busyNs{};
    std::uint64_t submitted = 0;
    std::uint64_t mainTasks = 0;
    std::uint64_t frameNs = 0;
    bool otherUsed = false;
};

struct Pool {
    std::mutex mu;  // everything below up to `threads`
    std::condition_variable workCv;  // workers sleep here while nothing is queued
    std::condition_variable doneCv;  // waiters sleep here until a job finishes or becomes ready
    std::deque<JobPtr> ready;
    int refs = 0;
    bool active = false;  // started and not fully stopped
    bool stopping = false;
    bool inlineMode = false;
    int workers = 0;
    int runningJobs = 0;  // jobs executing now, on any thread
    int pending = 0;      // submitted and not finished
    int waiters = 0;
    Settings settings;
    std::thread::id mainId;
    std::vector<std::thread> threads;

    std::atomic<std::uint32_t> gen{1};  // changes at every start and stop: cached thread lanes go stale
    std::atomic<bool> activeFlag{false};
    std::atomic<bool> inlineFlag{false};
    std::atomic<int> workerCount{0};

    std::mutex mainMu;
    std::vector<MainTask> mainQueue;

    std::array<LaneCounters, kMaxLanes> lanes;
    std::atomic<std::uint64_t> submitted{0};
    std::atomic<std::uint64_t> mainTasksRun{0};
    std::atomic<bool> otherUsed{false};

    std::mutex statsMu;
    FrameStats last;
    Clock::time_point frameStart = Clock::now();
};

// Never destroyed: a static destructor at exit must not join threads or free state a late job still reads.
Pool& pool() {
    static Pool* p = new Pool;
    return *p;
}

struct ThreadInfo {
    std::uint32_t gen = 0;
    int lane = -1;
    int depth = 0;  // jobs running on this thread now (a wait inside a job runs others on top)
};
thread_local ThreadInfo tls;

std::uint64_t ns_since(Clock::time_point t0) {
    const auto d = Clock::now() - t0;
    const auto n = std::chrono::duration_cast<std::chrono::nanoseconds>(d).count();
    return n > 0 ? std::uint64_t(n) : 0;
}

double round2(double v) { return std::round(v * 100.0) / 100.0; }
double round1(double v) { return std::round(v * 10.0) / 10.0; }

void record(int lane, const std::string& name, std::uint64_t ns) {
    Pool& p = pool();
    if (lane < 0 || lane >= kMaxLanes) lane = lane_other();
    p.lanes[std::size_t(lane)].jobs.fetch_add(1, std::memory_order_relaxed);
    p.lanes[std::size_t(lane)].busyNs.fetch_add(ns, std::memory_order_relaxed);
    if (lane == lane_other()) p.otherUsed.store(true, std::memory_order_relaxed);
    if (Profiler::on()) Profiler::get().add_job(lane, name, double(ns) / 1e6);
}

Error thrown_error(const std::string& what, const std::string& name) {
    return make_error("job '" + name + "' failed: " + what,
                      "The job system caught the exception and the job's work is incomplete; fix the code the job runs "
                      "(the log has the same line with the job's name).");
}

// What a caught exception says.
std::string current_exception_text() {
    try {
        throw;
    } catch (const std::exception& e) {
        return std::string("exception: ") + e.what();
    } catch (...) {
        return "an exception that is not a std::exception";
    }
}

struct Finished {
    bool newReady = false;
    std::vector<JobPtr> runHere;                 // dependents that became ready while the pool is not running
    std::vector<std::function<void()>> discard;  // functions of skipped jobs: destroyed after the lock is released
};

// Marks `j` finished (its failed/error already set) and every dependent it releases. Pool::mu must be held.
void finish_locked(Pool& p, const JobPtr& j, Finished& out) {
    std::vector<JobPtr> work{j};
    while (!work.empty()) {
        JobPtr cur = std::move(work.back());
        work.pop_back();
        cur->finished = true;
        cur->doneFlag.store(true, std::memory_order_release);
        --p.pending;
        for (JobPtr& d : cur->dependents) {
            if (cur->failed && d->failedDep.empty()) {
                d->failedDep = cur->name;
                d->rootError = cur->rootError;
            }
            if (--d->pendingDeps > 0) continue;
            if (!d->failedDep.empty()) {
                d->failed = true;
                d->error = make_error("job '" + d->name + "' did not run: its dependency '" + d->failedDep +
                                          "' failed: " + d->rootError.message,
                                      d->rootError.hint);
                out.discard.push_back(std::move(d->fn));
                work.push_back(d);
            } else if (p.active && !p.inlineMode) {
                d->queued = true;
                p.ready.push_back(d);
                out.newReady = true;
            } else {
                ++p.runningJobs;
                out.runHere.push_back(d);
            }
        }
        cur->dependents.clear();
    }
}

void run_job(const JobPtr& j);

void notify_finished(Pool& p, Finished& f) {
    if (f.newReady) p.workCv.notify_all();
    p.doneCv.notify_all();
    f.discard.clear();
    for (const JobPtr& d : f.runHere) run_job(d);
}

// Runs a job the caller took (Pool::runningJobs already counts it) and finishes it.
void run_job(const JobPtr& j) {
    const int lane = current_lane();
    ++tls.depth;
    const Clock::time_point t0 = Clock::now();
    bool failed = false;
    std::string what;
    {
        std::function<void()> fn = std::move(j->fn);
        try {
            if (fn) fn();
        } catch (...) {
            failed = true;
            what = current_exception_text();
        }
    }  // the captures die here, before any waiter wakes
    const std::uint64_t ns = ns_since(t0);
    --tls.depth;
    if (!j->internal) record(lane, j->name, ns);
    if (failed) FA_ERROR("jobs", "job '{}' failed: {}", j->name, what);
    Pool& p = pool();
    Finished f;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        if (failed) {
            j->failed = true;
            j->error = thrown_error(what, j->name);
            j->rootError = j->error;
        }
        --p.runningJobs;
        finish_locked(p, j, f);
    }
    notify_finished(p, f);
}

JobPtr make_job(std::string_view name, std::function<void()> fn, bool internal) {
    auto j = std::make_shared<JobState>();
    j->name.assign(name.data(), name.size());
    j->fn = std::move(fn);
    j->internal = internal;
    return j;
}

Handle submit_job(const JobPtr& j, const std::vector<Handle>& deps) {
    Pool& p = pool();
    if (!j->internal) p.submitted.fetch_add(1, std::memory_order_relaxed);
    bool runNow = false;
    bool wakeWaiters = false;
    Finished f;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        ++p.pending;
        wakeWaiters = p.waiters > 0;
        if (!p.active || p.inlineMode) {
            runNow = true;
        } else {
            for (const Handle& h : deps) {
                const JobPtr& d = Access::state(h);
                if (!d || d.get() == j.get()) continue;
                if (!d->finished) {
                    ++j->pendingDeps;
                    d->dependents.push_back(j);
                } else if (d->failed && j->failedDep.empty()) {
                    j->failedDep = d->name;
                    j->rootError = d->rootError;
                }
            }
            if (j->pendingDeps == 0) {
                if (!j->failedDep.empty()) {
                    j->failed = true;
                    j->error = make_error("job '" + j->name + "' did not run: its dependency '" + j->failedDep +
                                              "' failed: " + j->rootError.message,
                                          j->rootError.hint);
                    f.discard.push_back(std::move(j->fn));
                    finish_locked(p, j, f);
                } else {
                    j->queued = true;
                    p.ready.push_back(j);
                    f.newReady = true;
                }
            }
        }
    }
    if (!runNow) {
        if (f.newReady) {
            p.workCv.notify_one();
            if (wakeWaiters) p.doneCv.notify_all();  // a helping waiter may take it (0 workers)
        } else if (!f.discard.empty()) {
            notify_finished(p, f);
        }
        return Access::make(j);
    }
    // Not running or inline: the job runs here, once its dependencies are done (they may run on another thread).
    for (const Handle& h : deps) {
        const JobPtr& d = Access::state(h);
        if (!d || d.get() == j.get()) continue;
        (void)wait(h);  // its error is reported through this job below
        if (d->failed && j->failedDep.empty()) {
            j->failedDep = d->name;
            j->rootError = d->rootError;
        }
    }
    if (!j->failedDep.empty()) {
        std::function<void()> discard;
        {
            std::lock_guard<std::mutex> lk(p.mu);
            j->failed = true;
            j->error = make_error("job '" + j->name + "' did not run: its dependency '" + j->failedDep + "' failed: " +
                                      j->rootError.message,
                                  j->rootError.hint);
            discard = std::move(j->fn);
            finish_locked(p, j, f);
        }
        notify_finished(p, f);
        return Access::make(j);
    }
    {
        std::lock_guard<std::mutex> lk(p.mu);
        ++p.runningJobs;
    }
    run_job(j);
    return Access::make(j);
}

// Takes the next queued job (`prefer` first when it is queued). Pool::mu must be held.
JobPtr take_locked(Pool& p, const JobState* prefer) {
    if (p.ready.empty()) return nullptr;
    auto it = p.ready.begin();
    if (prefer && prefer->queued) {
        auto found = std::find_if(p.ready.begin(), p.ready.end(), [&](const JobPtr& x) { return x.get() == prefer; });
        if (found != p.ready.end()) it = found;
    }
    JobPtr j = std::move(*it);
    p.ready.erase(it);
    j->queued = false;
    ++p.runningJobs;
    return j;
}

void worker_main(int index, std::uint32_t gen) {
    tls.gen = gen;
    tls.lane = index + 1;
    const std::string name = "fa-job-" + std::to_string(index + 1);
    detail::set_current_thread_name(name.c_str());
    Pool& p = pool();
    std::unique_lock<std::mutex> lk(p.mu);
    for (;;) {
        p.workCv.wait(lk, [&p] { return !p.ready.empty() || p.stopping; });
        JobPtr j = take_locked(p, nullptr);
        if (!j) break;  // stopping and nothing left: the jobs queued during shutdown ran too
        lk.unlock();
        run_job(j);
        lk.lock();
    }
}

bool is_mobile() {
#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
    return true;
#else
    return false;
#endif
}

const std::vector<std::string>& setting_words() {
    static const std::vector<std::string> words = {"auto", "inline"};
    return words;
}

std::string range_hint() {
    return "Use \"auto\" (hardware threads - 1, at most " + std::to_string(kAutoCapDesktop) + " on desktop and " +
           std::to_string(kAutoCapMobile) + " on phones), \"inline\" (every job runs on the main thread when it is "
           "submitted: for debugging) or a number of worker threads from 0 to " + std::to_string(kMaxWorkers) + ".";
}

Result<Settings> count_setting(std::int64_t n, std::string_view where, const std::string& shown) {
    if (n < 0 || n > kMaxWorkers)
        return make_error(std::string(where) + ": " + shown + " worker threads is out of range (0.." +
                              std::to_string(kMaxWorkers) + ")",
                          range_hint());
    return Settings::threads(int(n));
}

}  // namespace

// --------------------------------------------------------------------------------------------------------- settings
std::string Settings::describe() const {
    switch (mode) {
        case Mode::Auto: return "auto";
        case Mode::Inline: return "inline";
        case Mode::Count: return std::to_string(count);
    }
    return "auto";
}

Json Settings::to_json() const {
    if (mode == Mode::Count) return Json(count);
    return Json(describe());
}

Result<Settings> parse_settings_text(std::string_view text, std::string_view where) {
    const std::string t = to_lower(trim(text));
    if (t == "auto") return Settings::automatic();
    if (t == "inline") return Settings::inline_jobs();
    const bool negative = !t.empty() && t[0] == '-';
    const std::string_view digits = std::string_view(t).substr(negative ? 1 : 0);
    if (!digits.empty() && std::all_of(digits.begin(), digits.end(), [](char c) { return c >= '0' && c <= '9'; })) {
        std::int64_t n = 0;
        const auto [ptr, ec] = std::from_chars(digits.data(), digits.data() + digits.size(), n);
        if (ec != std::errc() || ptr != digits.data() + digits.size()) n = std::numeric_limits<std::int64_t>::max();
        return count_setting(negative ? -1 : n, where, t);
    }
    return make_error(std::string(where) + ": unknown job thread setting '" + std::string(trim(text)) + "'. " +
                          did_you_mean(t, setting_words()),
                      range_hint());
}

Result<Settings> parse_settings(const Json& v, std::string_view where) {
    if (v.is_string()) return parse_settings_text(v.get<std::string>(), where);
    if (v.is_number_unsigned()) {
        const std::uint64_t u = v.get<std::uint64_t>();
        return count_setting(u > std::uint64_t(kMaxWorkers) ? std::int64_t(kMaxWorkers) + 1 : std::int64_t(u), where,
                             std::to_string(u));
    }
    if (v.is_number_integer()) return count_setting(v.get<std::int64_t>(), where, std::to_string(v.get<std::int64_t>()));
    if (v.is_number_float()) {
        const double d = v.get<double>();
        if (std::isfinite(d) && d == std::floor(d) && d >= 0 && d <= double(kMaxWorkers))
            return Settings::threads(int(d));
        return make_error(std::string(where) + ": expected a whole number of worker threads, got " + v.dump(),
                          range_hint());
    }
    return make_error(std::string(where) + ": expected \"auto\", \"inline\" or a number of worker threads, got " +
                          std::string(v.type_name()) + " " + v.dump(),
                      range_hint());
}

bool threads_supported() {
#if defined(__EMSCRIPTEN__) && !defined(__EMSCRIPTEN_PTHREADS__)
    return false;
#else
    return true;
#endif
}

int hardware_threads() {
    const unsigned n = std::thread::hardware_concurrency();
    return n == 0 ? 1 : int(std::min(n, 1024u));
}

int auto_worker_count(int hardwareThreads) {
    if (!threads_supported()) return 0;
#if defined(__EMSCRIPTEN__)
    const int cap = kAutoCapWebThreads;
#else
    const int cap = is_mobile() ? kAutoCapMobile : kAutoCapDesktop;
#endif
    return std::clamp(hardwareThreads - 1, 0, cap);
}

int resolve_workers(const Settings& s) {
    if (!threads_supported()) return 0;
    switch (s.mode) {
        case Settings::Mode::Inline: return 0;
        case Settings::Mode::Count: return std::clamp(s.count, 0, kMaxWorkers);
        case Settings::Mode::Auto: return auto_worker_count(hardware_threads());
    }
    return 0;
}

// --------------------------------------------------------------------------------------------------------- the pool
void start(const Settings& s) {
    Pool& p = pool();
    std::lock_guard<std::mutex> lk(p.mu);
    if (p.refs++ > 0) {
        if (!(s == p.settings))
            FA_DEBUG("jobs", "the job pool already runs with jobThreads {}; {} is ignored until it stops",
                     p.settings.describe(), s.describe());
        return;
    }
    p.settings = s;
    p.mainId = std::this_thread::get_id();
    const std::uint32_t gen = p.gen.fetch_add(1, std::memory_order_acq_rel) + 1;
    tls.gen = gen;
    tls.lane = 0;
    p.inlineMode = s.mode == Settings::Mode::Inline;
    p.stopping = false;
    p.active = true;
    const int want = resolve_workers(s);
    p.threads.reserve(std::size_t(want));
    for (int i = 0; i < want; ++i) {
        try {
            p.threads.emplace_back(worker_main, i, gen);
        } catch (const std::system_error& e) {
            FA_WARN("jobs", "could not start job thread {} of {} ({}); the pool runs with {}", i + 1, want, e.what(), i);
            break;
        }
    }
    p.workers = int(p.threads.size());
    p.activeFlag.store(true, std::memory_order_release);
    p.inlineFlag.store(p.inlineMode, std::memory_order_release);
    p.workerCount.store(p.workers, std::memory_order_release);
    {
        std::lock_guard<std::mutex> st(p.statsMu);
        p.last = FrameStats{};
        p.frameStart = Clock::now();
    }
    FA_DEBUG("jobs", "job pool started: jobThreads {}, {} worker thread(s), {} hardware thread(s)", s.describe(),
             p.workers, hardware_threads());
}

void stop() {
    Pool& p = pool();
    std::vector<std::thread> joining;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        if (p.refs == 0) {
            FA_WARN("jobs", "jobs::stop() without a matching jobs::start()");
            return;
        }
        if (tls.gen == p.gen.load(std::memory_order_acquire) && tls.lane >= 1 && tls.lane <= kMaxWorkers) {
            FA_ERROR("jobs", "jobs::stop() was called from a job thread; the pool keeps running (stop it from the "
                             "thread that started it)");
            return;
        }
        if (--p.refs > 0) return;
        p.stopping = true;
        joining = std::move(p.threads);
        p.threads.clear();
    }
    p.workCv.notify_all();
    for (std::thread& t : joining)
        if (t.joinable()) t.join();
    // Jobs another thread queued after the last worker left run here; then the pool is off and submit runs inline.
    for (;;) {
        JobPtr j;
        {
            std::lock_guard<std::mutex> lk(p.mu);
            j = take_locked(p, nullptr);
            if (!j) {
                p.active = false;
                p.inlineMode = false;
                p.stopping = false;
                p.workers = 0;
                p.settings = Settings{};
                p.mainId = std::thread::id();
                p.gen.fetch_add(1, std::memory_order_acq_rel);
                p.activeFlag.store(false, std::memory_order_release);
                p.inlineFlag.store(false, std::memory_order_release);
                p.workerCount.store(0, std::memory_order_release);
                break;
            }
        }
        run_job(j);
    }
    std::vector<MainTask> dropped;
    {
        std::lock_guard<std::mutex> lk(p.mainMu);
        dropped.swap(p.mainQueue);
    }
    if (!dropped.empty())
        FA_DEBUG("jobs", "job pool stopped; {} main-thread task(s) still queued were dropped (first: '{}')",
                 dropped.size(), dropped.front().name);
}

bool running() { return pool().activeFlag.load(std::memory_order_acquire); }
bool inline_mode() { return pool().inlineFlag.load(std::memory_order_acquire); }
int worker_count() { return pool().workerCount.load(std::memory_order_acquire); }

Settings settings() {
    Pool& p = pool();
    std::lock_guard<std::mutex> lk(p.mu);
    return p.settings;
}

bool is_main_thread() { return current_lane() == 0; }
bool is_worker_thread() {
    const int lane = current_lane();
    return lane >= 1 && lane <= kMaxWorkers;
}

int lane_count() { return 1 + worker_count(); }
int lane_other() { return kMaxLanes - 1; }

std::string lane_name(int lane) {
    if (lane == 0) return "main";
    if (lane >= 1 && lane <= kMaxWorkers) return "worker " + std::to_string(lane);
    return "other";
}

int current_lane() {
    Pool& p = pool();
    const std::uint32_t g = p.gen.load(std::memory_order_acquire);
    if (tls.gen == g && tls.lane >= 0) return tls.lane;
    int lane = lane_other();
    std::uint32_t seen = g;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        if (p.active && std::this_thread::get_id() == p.mainId) lane = 0;
        seen = p.gen.load(std::memory_order_acquire);
    }
    tls.gen = seen;
    tls.lane = lane;
    return lane;
}

// --------------------------------------------------------------------------------------------------------- jobs
bool Handle::done() const { return !state_ || state_->doneFlag.load(std::memory_order_acquire); }

const std::string& Handle::name() const {
    static const std::string none;
    return state_ ? state_->name : none;
}

bool Group::done() const {
    return std::all_of(handles_.begin(), handles_.end(), [](const Handle& h) { return h.done(); });
}

Handle submit(std::string_view name, std::function<void()> fn, const std::vector<Handle>& deps) {
    return submit_job(make_job(name, std::move(fn), false), deps);
}

Result<void> wait(const Handle& h) {
    const JobPtr& j = Access::state(h);
    if (!j) return {};
    if (!j->doneFlag.load(std::memory_order_acquire)) {
        Pool& p = pool();
        std::unique_lock<std::mutex> lk(p.mu);
        ++p.waiters;
        while (!j->finished) {
            if (JobPtr next = take_locked(p, j.get())) {
                lk.unlock();
                run_job(next);
                lk.lock();
                continue;
            }
            if (p.runningJobs - tls.depth <= 0) {
                // Nothing is queued and no other thread runs a job: what we wait for depends on a job this thread is
                // in the middle of. Waiting would hang forever.
                --p.waiters;
                lk.unlock();
                FA_ERROR("jobs", "waiting for job '{}' can never end: it depends on a job that is waiting for it",
                         j->name);
                return make_error("waiting for job '" + j->name +
                                      "' can never end: it (or one of its dependencies) depends on the job that waits",
                                  "Do not wait inside a job for a job that has the waiting job among its dependencies; "
                                  "pass the dependency to submit() instead.");
            }
            p.doneCv.wait(lk);
        }
        --p.waiters;
    }
    if (j->failed) return j->error;
    return {};
}

Result<void> wait_all(const std::vector<Handle>& hs) {
    Result<void> first;
    for (const Handle& h : hs) {
        Result<void> r = wait(h);
        if (!r && first.ok()) first = r;
    }
    return first;
}

// ------------------------------------------------------------------------------------------------------- parallel_for
std::size_t chunk_count(std::size_t count, std::size_t grain) {
    if (grain == 0) grain = 1;
    return count / grain + (count % grain ? 1 : 0);
}

std::uint64_t chunk_seed(std::uint64_t seed, std::size_t index) {
    std::uint64_t z = seed + 0x9e3779b97f4a7c15ULL * (std::uint64_t(index) + 1);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}

Chunk chunk_at(std::size_t count, std::size_t grain, std::size_t index, std::uint64_t seed) {
    if (grain == 0) grain = 1;
    Chunk c;
    c.index = index;
    c.begin = std::min(count, index * grain);
    c.end = std::min(count, c.begin + grain);
    c.seed = chunk_seed(seed, index);
    return c;
}

namespace {
struct ForState {
    std::string name;
    const std::function<void(const Chunk&)>* fn = nullptr;
    std::size_t count = 0, grain = 1, chunks = 0;
    std::uint64_t seed = 0;
    std::atomic<std::size_t> next{0};
    std::mutex errMu;
    std::size_t failures = 0;
    std::size_t errIndex = std::numeric_limits<std::size_t>::max();
    std::string errWhat;
};

void run_chunks(ForState& s) {
    const int lane = current_lane();
    for (;;) {
        const std::size_t i = s.next.fetch_add(1, std::memory_order_relaxed);
        if (i >= s.chunks) break;
        const Chunk c = chunk_at(s.count, s.grain, i, s.seed);
        const Clock::time_point t0 = Clock::now();
        try {
            (*s.fn)(c);
        } catch (...) {
            const std::string what = current_exception_text();
            std::lock_guard<std::mutex> lk(s.errMu);
            ++s.failures;
            if (i < s.errIndex) {
                s.errIndex = i;
                s.errWhat = what;
            }
        }
        record(lane, s.name, ns_since(t0));
    }
}
}  // namespace

Result<void> parallel_for(std::string_view name, std::size_t count, std::size_t grain,
                          const std::function<void(const Chunk&)>& fn, std::uint64_t seed) {
    if (grain == 0) grain = 1;
    const std::size_t chunks = chunk_count(count, grain);
    if (chunks == 0 || !fn) return {};
    Pool& p = pool();
    p.submitted.fetch_add(chunks, std::memory_order_relaxed);
    auto s = std::make_shared<ForState>();
    s->name.assign(name.data(), name.size());
    s->fn = &fn;
    s->count = count;
    s->grain = grain;
    s->chunks = chunks;
    s->seed = seed;
    std::size_t helpers = 0;
    if (running() && !inline_mode()) helpers = std::min<std::size_t>(chunks - 1, std::size_t(worker_count()));
    std::vector<Handle> hs;
    hs.reserve(helpers);
    for (std::size_t k = 0; k < helpers; ++k)
        hs.push_back(submit_job(make_job(name, [s] { run_chunks(*s); }, true), {}));
    run_chunks(*s);
    // The helpers never fail (run_chunks catches); one still queued is taken by this wait and finds no chunk left.
    for (const Handle& h : hs) (void)wait(h);
    if (s->failures == 0) return {};
    const Chunk c = chunk_at(count, grain, s->errIndex, seed);
    FA_ERROR("jobs", "parallel_for '{}': {} of {} chunk(s) failed; the first is chunk {} (items {}..{}): {}", s->name,
             s->failures, chunks, c.index, c.begin, c.end - 1, s->errWhat);
    return make_error("parallel_for '" + s->name + "' chunk " + std::to_string(c.index) + " (items " +
                          std::to_string(c.begin) + ".." + std::to_string(c.end - 1) + ") failed: " + s->errWhat +
                          (s->failures > 1 ? " (" + std::to_string(s->failures) + " chunks failed)" : std::string()),
                      "The job system caught the exception; every other chunk ran. Fix the code the chunk runs.");
}

// ------------------------------------------------------------------------------------------ the main thread's queue
void post_main(std::string_view name, std::function<void()> fn) {
    Pool& p = pool();
    std::lock_guard<std::mutex> lk(p.mainMu);
    p.mainQueue.push_back(MainTask{std::string(name), std::move(fn)});
}

int main_tasks_queued() {
    Pool& p = pool();
    std::lock_guard<std::mutex> lk(p.mainMu);
    return int(p.mainQueue.size());
}

int run_main_thread_tasks() {
    Pool& p = pool();
    if (running() && !is_main_thread()) return 0;
    std::vector<MainTask> tasks;
    {
        std::lock_guard<std::mutex> lk(p.mainMu);
        if (p.mainQueue.empty()) return 0;
        tasks.swap(p.mainQueue);
    }
    for (MainTask& t : tasks) {
        try {
            if (t.fn) t.fn();
        } catch (...) {
            FA_ERROR("jobs", "main-thread task '{}' failed: {}", t.name, current_exception_text());
        }
        t.fn = nullptr;
    }
    p.mainTasksRun.fetch_add(tasks.size(), std::memory_order_relaxed);
    return int(tasks.size());
}

void end_frame() {
    Pool& p = pool();
    if (running() && !is_main_thread()) return;
    if (running() && !inline_mode() && worker_count() == 0) {
        // Nobody else runs queued jobs: those nobody waited for run now (the ones they queue wait for next frame).
        std::size_t n = 0;
        {
            std::lock_guard<std::mutex> lk(p.mu);
            n = p.ready.size();
        }
        for (std::size_t i = 0; i < n; ++i) {
            JobPtr j;
            {
                std::lock_guard<std::mutex> lk(p.mu);
                j = take_locked(p, nullptr);
            }
            if (!j) break;
            run_job(j);
        }
    }
    std::lock_guard<std::mutex> st(p.statsMu);
    FrameStats f;
    for (std::size_t i = 0; i < std::size_t(kMaxLanes); ++i) {
        f.jobs[i] = p.lanes[i].jobs.exchange(0, std::memory_order_relaxed);
        f.busyNs[i] = p.lanes[i].busyNs.exchange(0, std::memory_order_relaxed);
    }
    f.submitted = p.submitted.exchange(0, std::memory_order_relaxed);
    f.mainTasks = p.mainTasksRun.exchange(0, std::memory_order_relaxed);
    f.otherUsed = p.otherUsed.exchange(false, std::memory_order_relaxed);
    f.frameNs = ns_since(p.frameStart);
    p.frameStart = Clock::now();
    p.last = f;
}

// ------------------------------------------------------------------------------------------------------- jobs.info
Info info() {
    Pool& p = pool();
    Info out;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        out.running = p.active;
        out.mode = !p.active ? "stopped" : p.inlineMode ? "inline" : "threads";
        out.workers = p.workers;
        out.settings = p.settings;
        out.pending = p.pending;
    }
    out.hardwareThreads = hardware_threads();
    out.autoWorkers = auto_worker_count(out.hardwareThreads);
    out.threadsSupported = threads_supported();
    out.mainTasksQueued = main_tasks_queued();
    FrameStats f;
    {
        std::lock_guard<std::mutex> st(p.statsMu);
        f = p.last;
    }
    out.submittedLastFrame = int(std::min<std::uint64_t>(f.submitted, std::uint64_t(std::numeric_limits<int>::max())));
    out.mainTasksLastFrame = int(std::min<std::uint64_t>(f.mainTasks, std::uint64_t(std::numeric_limits<int>::max())));
    const double frameMs = double(f.frameNs) / 1e6;
    out.frameMs = round2(frameMs);
    auto add_lane = [&](int lane) {
        LaneInfo l;
        l.name = lane_name(lane);
        const std::uint64_t jobsRun = f.jobs[std::size_t(lane)];
        l.jobs = int(std::min<std::uint64_t>(jobsRun, std::uint64_t(std::numeric_limits<int>::max())));
        const double ms = double(f.busyNs[std::size_t(lane)]) / 1e6;
        l.busyMs = round2(ms);
        l.busyPct = frameMs > 0 ? round1(std::min(100.0, ms / frameMs * 100.0)) : 0.0;
        out.jobsLastFrame += l.jobs;
        out.lanes.push_back(std::move(l));
    };
    for (int lane = 0; lane < 1 + out.workers; ++lane) add_lane(lane);
    if (f.otherUsed || f.jobs[std::size_t(lane_other())] > 0) add_lane(lane_other());
    return out;
}

Json info_json(const Info& i) {
    Json lanes = Json::array();
    for (const LaneInfo& l : i.lanes)
        lanes.push_back(Json::object({{"name", l.name}, {"jobs", l.jobs}, {"busyMs", l.busyMs}, {"busyPct", l.busyPct}}));
    return Json::object({{"running", i.running},
                         {"mode", i.mode},
                         {"workers", i.workers},
                         {"setting", i.settings.to_json()},
                         {"hardwareThreads", i.hardwareThreads},
                         {"autoWorkers", i.autoWorkers},
                         {"threadsSupported", i.threadsSupported},
                         {"lastFrame", Json::object({{"jobs", i.jobsLastFrame},
                                                     {"submitted", i.submittedLastFrame},
                                                     {"mainTasks", i.mainTasksLastFrame},
                                                     {"frameMs", i.frameMs}})},
                         {"pending", i.pending},
                         {"mainTasksQueued", i.mainTasksQueued},
                         {"lanes", lanes}});
}

}  // namespace fa::jobs
