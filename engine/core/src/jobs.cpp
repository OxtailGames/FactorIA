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
#include <string>
#include <thread>
#include <type_traits>
#include <utility>
#include <vector>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/core/strings.h"
#include "jobs_internal.h"

namespace fa::jobs {

namespace detail {

struct MainTask {
    std::string name;
    std::function<void()> fn;
};

struct OwnerState : std::enable_shared_from_this<OwnerState> {
    std::string name;
    int pending = 0;  // Pool::mu: its jobs not finished
    mutable std::mutex mainMu;
    std::vector<MainTask> main;  // mainMu
    bool alive = true;           // mainMu: false once the Owner is destroyed (its late tasks are dropped)
};

struct ThreadInfo;

struct JobState {
    std::string name;
    std::function<void()> fn;
    bool internal = false;  // a parallel_for helper: its chunks are counted, not the helper itself
    std::shared_ptr<OwnerState> owner;
    // Guarded by Pool::mu until finished; read-only after doneFlag is true.
    int pendingDeps = 0;
    bool queued = false;  // in Pool::ready and not taken yet
    bool finished = false;
    bool failed = false;
    Error error;                                       // what wait() returns when failed
    Error rootError;                                   // the throw a failure goes back to (for skipped dependents)
    std::string failedDep;                             // the first dependency that failed: the job is skipped
    std::vector<std::shared_ptr<JobState>> dependents;
    std::vector<std::shared_ptr<JobState>> deps;       // the dependencies not finished at submit (dropped when it ends)
    ThreadInfo* runningOn = nullptr;                   // the thread running it now
    std::size_t frame = 0;                             // its place in runningOn->frames
    std::uint64_t mark = 0;                            // graph walks (Pool::walk)
    std::atomic<bool> doneFlag{false};                 // finished, readable without the lock
};

// One level of a thread's stack: a job it runs, or a wait. A job can only end once every wait above it has ended.
struct Frame {
    JobState* job = nullptr;
    JobState* waitFor = nullptr;
};

// A thread's frames, innermost last. Trivially destructible on purpose: a static object destroyed at exit (an Engine)
// may still use the job system after the main thread's thread_local objects with destructors are gone, so the storage
// is freed by a separate thread_local (FrameReaper) and a later use only allocates again (and leaks that, once).
struct FrameStack {
    Frame* data = nullptr;
    std::size_t count = 0;
    std::size_t capacity = 0;

    bool empty() const { return count == 0; }
    std::size_t size() const { return count; }
    const Frame& operator[](std::size_t i) const { return data[i]; }
    void push_back(const Frame& f);  // Pool::mu
    void pop_back() { --count; }     // Pool::mu
};

struct ThreadInfo {
    std::uint32_t gen = 0;
    int lane = -1;
    OwnerState* owner = nullptr;  // the current owner (OwnerScope, or the job running now)
    FrameStack frames;            // Pool::mu (other threads read it to find waits that can never end)
    bool reaperArmed = false;     // FrameReaper registered for this thread
    bool reaped = false;          // FrameReaper ran (thread exit): storage allocated from now on is never freed
};
static_assert(std::is_trivially_destructible_v<ThreadInfo>, "tls must stay usable during static destruction");

}  // namespace detail

using detail::Frame;
using detail::JobState;
using detail::MainTask;
using detail::OwnerState;
using detail::ThreadInfo;
using JobPtr = std::shared_ptr<JobState>;

struct Access {
    static const JobPtr& state(const Handle& h) { return h.state_; }
    static Handle make(JobPtr s) { return Handle(std::move(s)); }
    static const std::shared_ptr<OwnerState>& state(const Owner& o) { return o.state_; }
};

namespace {

using Clock = std::chrono::steady_clock;

#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)  // padded because of alignas: that is the point
#endif
// One cache line per lane: workers add to their own lane without sharing a line with another worker's.
struct alignas(64) LaneCounters {
    std::atomic<std::uint64_t> jobs{0};
    std::atomic<std::uint64_t> busyNs{0};
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
    std::mutex life;  // held for the whole of start() and stop(): one at a time, a start never sees a half-stopped pool
    std::mutex mu;    // everything below up to `threads`, and every JobState and ThreadInfo::frames
    std::condition_variable workCv;  // workers sleep here while nothing is queued
    std::condition_variable doneCv;  // waiters sleep here until a job finishes or becomes ready
    std::deque<JobPtr> ready;        // FIFO; a job a waiter took out of order stays here with queued == false
    std::size_t readyCount = 0;      // entries of `ready` still queued
    int refs = 0;
    bool active = false;  // started and not fully stopped
    bool stopping = false;
    bool inlineMode = false;
    int workers = 0;
    int pending = 0;  // submitted and not finished
    int waiters = 0;  // threads sleeping (or about to) on doneCv
    std::uint64_t walk = 0;
    Settings settings;
    std::thread::id mainId;
    std::vector<std::thread> threads;

    std::atomic<std::uint32_t> gen{1};  // changes at every start and stop: cached thread lanes go stale
    std::atomic<bool> activeFlag{false};
    std::atomic<bool> inlineFlag{false};
    std::atomic<int> workerCount{0};

    std::mutex mainMu;
    std::vector<MainTask> mainQueue;  // tasks posted with no owner
    std::atomic<int> mainQueued{0};   // every queued task: mainQueue and every owner's

    std::array<LaneCounters, kMaxLanes> lanes;
    std::atomic<std::uint64_t> submitted{0};
    std::atomic<std::uint64_t> mainTasksRun{0};
    std::atomic<bool> otherUsed{false};

    std::mutex statsMu;
    FrameStats last;
    Clock::time_point frameStart = Clock::now();
    const OwnerState* frameOwner = nullptr;  // the owner whose end_frame closes the frames (compared, never read)
    Clock::time_point frameOwnerLast;  // when frameOwner last called end_frame (hand-over after kFrameOwnerHandOverMs)
};
#if defined(_MSC_VER)
#pragma warning(pop)  // C4324 covers LaneCounters and Pool, which holds them
#endif

// Never destroyed: a static destructor at exit must not join threads or free state a late job still reads.
Pool& pool() {
    static Pool* p = new Pool;
    return *p;
}

thread_local ThreadInfo tls;

// Frees this thread's frame storage when the thread ends (see FrameStack).
struct FrameReaper {
    bool armed = false;
    ~FrameReaper() {
        if (!armed) return;
        // No Pool::mu here, on purpose. On Windows this runs under DLL_THREAD_DETACH with the loader lock held: waiting
        // for a mutex another thread holds while it waits for that lock (it starts a thread, loads a library) would
        // deadlock. It is not needed either: the thread is ending, so no job runs on it and no frame is open (the
        // stack is empty), and other threads only read ThreadInfo::frames of a thread a running job sits on.
        delete[] tls.frames.data;
        tls.frames = detail::FrameStack{};
        tls.reaped = true;
    }
};
thread_local FrameReaper reaper;

}  // namespace

void detail::FrameStack::push_back(const Frame& f) {
    if (count == capacity) {
        const std::size_t grown = capacity ? capacity * 2 : 16;
        Frame* bigger = new Frame[grown];
        for (std::size_t i = 0; i < count; ++i) bigger[i] = data[i];
        delete[] data;
        if (!tls.reaperArmed && !tls.reaped) {
            tls.reaperArmed = true;
            reaper.armed = true;  // first use on this thread: registers the reaper's destructor
        }  // storage allocated after the reaper ran (static destruction at exit) is never freed: once, at exit
        data = bigger;
        capacity = grown;
    }
    data[count++] = f;
}

namespace {

std::uint64_t ns_since(Clock::time_point t0) {
    const auto d = Clock::now() - t0;
    const auto n = std::chrono::duration_cast<std::chrono::nanoseconds>(d).count();
    return n > 0 ? std::uint64_t(n) : 0;
}

double round2(double v) { return std::round(v * 100.0) / 100.0; }
double round1(double v) { return std::round(v * 10.0) / 10.0; }

void record(int lane, const std::string& name, std::uint64_t count, std::uint64_t ns) {
    Pool& p = pool();
    if (lane < 0 || lane >= kMaxLanes) lane = lane_other();
    p.lanes[std::size_t(lane)].jobs.fetch_add(count, std::memory_order_relaxed);
    p.lanes[std::size_t(lane)].busyNs.fetch_add(ns, std::memory_order_relaxed);
    if (lane == lane_other()) p.otherUsed.store(true, std::memory_order_relaxed);
    if (Profiler::on())
        Profiler::get().add_job(lane, name, double(ns) / 1e6, int(std::min<std::uint64_t>(count, 1u << 30)));
}

Error thrown_error(const std::string& what, const std::string& name) {
    return make_error("job '" + name + "' failed: " + what,
                      "The job system caught the exception and the job's work is incomplete; fix the code the job runs "
                      "(the log has the same line with the job's name).");
}

Error skipped_error(const JobState& j) {
    return make_error("job '" + j.name + "' did not run: its dependency '" + j.failedDep + "' failed: " +
                          j.rootError.message,
                      j.rootError.hint);
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

// Runs the tasks in order, catching what they throw. Returns how many ran.
int run_tasks(std::vector<MainTask>& tasks) {
    Pool& p = pool();
    p.mainQueued.fetch_sub(int(tasks.size()), std::memory_order_relaxed);
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

struct Finished {
    bool newReady = false;
    std::vector<JobPtr> runHere;                 // dependents that became ready while the pool is not running
    std::vector<std::function<void()>> discard;  // functions of skipped jobs: destroyed after the lock is released
    std::vector<JobPtr> release;                 // dependency lists of finished jobs: dropped after the lock too
};

// Puts j, which this thread is about to run, on this thread's stack. Pool::mu must be held.
void claim_locked(JobState* j) {
    j->runningOn = &tls;
    j->frame = tls.frames.size();
    tls.frames.push_back(Frame{j, nullptr});
}

// Takes `j`, which is queued, out of order: its entry in `ready` stays behind, no longer queued. Pool::mu held.
void take_locked(Pool& p, JobState* j) {
    j->queued = false;
    --p.readyCount;
    if (!p.ready.empty() && p.ready.front().get() == j) p.ready.pop_front();
    else if (!p.ready.empty() && p.ready.back().get() == j) p.ready.pop_back();
    claim_locked(j);
}

// The oldest queued job, taken; null when none. Pool::mu must be held.
JobPtr pop_front_locked(Pool& p) {
    while (!p.ready.empty()) {
        JobPtr j = std::move(p.ready.front());
        p.ready.pop_front();
        if (!j->queued) continue;  // a waiter took it already
        j->queued = false;
        --p.readyCount;
        claim_locked(j.get());
        return j;
    }
    return nullptr;
}

// Marks `j` finished (its failed/error already set) and every dependent it releases. Pool::mu must be held.
void finish_locked(Pool& p, const JobPtr& j, Finished& out) {
    std::vector<JobPtr> work{j};
    while (!work.empty()) {
        JobPtr cur = std::move(work.back());
        work.pop_back();
        cur->finished = true;
        cur->doneFlag.store(true, std::memory_order_release);
        --p.pending;
        if (cur->owner) --cur->owner->pending;
        for (JobPtr& d : cur->deps) out.release.push_back(std::move(d));
        cur->deps.clear();
        for (JobPtr& d : cur->dependents) {
            if (cur->failed && d->failedDep.empty()) {
                d->failedDep = cur->name;
                d->rootError = cur->rootError;
            }
            if (--d->pendingDeps > 0) continue;
            if (!d->failedDep.empty()) {
                d->failed = true;
                d->error = skipped_error(*d);
                out.discard.push_back(std::move(d->fn));
                work.push_back(d);
            } else if (p.active && !p.inlineMode) {
                d->queued = true;
                p.ready.push_back(d);
                ++p.readyCount;
                out.newReady = true;
            } else {
                out.runHere.push_back(d);
            }
        }
        cur->dependents.clear();
    }
}

void run_job(const JobPtr& j);

void notify_finished(Pool& p, Finished& f, bool wakeWaiters) {
    if (f.newReady) p.workCv.notify_all();
    if (wakeWaiters) p.doneCv.notify_all();
    f.discard.clear();
    f.release.clear();
    for (const JobPtr& d : f.runHere) {
        {
            std::lock_guard<std::mutex> lk(p.mu);
            claim_locked(d.get());
        }
        run_job(d);
    }
}

// Runs a job this thread claimed (claim_locked) and finishes it.
void run_job(const JobPtr& j) {
    const int lane = current_lane();
    OwnerState* const prevOwner = tls.owner;
    tls.owner = j->owner.get();
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
    tls.owner = prevOwner;
    if (!j->internal) record(lane, j->name, 1, ns);
    if (failed) FA_ERROR("jobs", "job '{}' failed: {}", j->name, what);
    Pool& p = pool();
    Finished f;
    bool wake = false;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        if (failed) {
            j->failed = true;
            j->error = thrown_error(what, j->name);
            j->rootError = j->error;
        }
        tls.frames.pop_back();  // this job's frame: every wait it made has ended
        j->runningOn = nullptr;
        finish_locked(p, j, f);
        wake = p.waiters > 0;
    }
    notify_finished(p, f, wake);
}

JobPtr make_job(std::string_view name, std::function<void()> fn, bool internal) {
    auto j = std::make_shared<JobState>();
    j->name.assign(name.data(), name.size());
    j->fn = std::move(fn);
    j->internal = internal;
    if (tls.owner) j->owner = tls.owner->shared_from_this();
    return j;
}

Handle submit_job(const JobPtr& j, const std::vector<Handle>& deps) {
    Pool& p = pool();
    if (!j->internal) p.submitted.fetch_add(1, std::memory_order_relaxed);
    bool runNow = false;
    bool wake = false;
    Finished f;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        ++p.pending;
        if (j->owner) ++j->owner->pending;
        if (!p.active || p.inlineMode) {
            runNow = true;
        } else {
            for (const Handle& h : deps) {
                const JobPtr& d = Access::state(h);
                if (!d || d.get() == j.get()) continue;
                if (!d->finished) {
                    ++j->pendingDeps;
                    d->dependents.push_back(j);
                    j->deps.push_back(d);
                } else if (d->failed && j->failedDep.empty()) {
                    j->failedDep = d->name;
                    j->rootError = d->rootError;
                }
            }
            if (j->pendingDeps == 0) {
                if (!j->failedDep.empty()) {
                    j->failed = true;
                    j->error = skipped_error(*j);
                    f.discard.push_back(std::move(j->fn));
                    finish_locked(p, j, f);
                    wake = p.waiters > 0;
                } else {
                    j->queued = true;
                    p.ready.push_back(j);
                    ++p.readyCount;
                    f.newReady = true;
                }
            }
        }
    }
    if (!runNow) {
        // A new job is in nobody's wait yet (waits only take what the waited job needs), so only workers wake.
        if (f.newReady) p.workCv.notify_one();
        else notify_finished(p, f, wake);  // skipped at once: its waiters (none yet, or a copy of the handle) wake
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
            j->error = skipped_error(*j);
            discard = std::move(j->fn);
            finish_locked(p, j, f);
            wake = p.waiters > 0;
        }
        notify_finished(p, f, wake);
        return Access::make(j);
    }
    {
        std::lock_guard<std::mutex> lk(p.mu);
        claim_locked(j.get());
    }
    run_job(j);
    return Access::make(j);
}

// A queued job that `root` needs: root itself or one of its unfinished dependencies (and theirs). Pool::mu held.
JobPtr find_needed_locked(Pool& p, const JobPtr& root) {
    const std::uint64_t mark = ++p.walk;
    std::vector<const JobPtr*> todo{&root};
    root->mark = mark;
    while (!todo.empty()) {
        const JobPtr& cur = *todo.back();
        todo.pop_back();
        if (cur->finished) continue;
        if (cur->queued) return cur;
        for (const JobPtr& d : cur->deps) {
            if (d->finished || d->mark == mark) continue;
            d->mark = mark;
            todo.push_back(&d);
        }
    }
    return nullptr;
}

// The first queued job that `o` needs: one of its own, or one that a job of `o` depends on (through any chain of
// dependents). Null when none. Pool::mu must be held.
JobPtr find_owner_needs_locked(Pool& p, const OwnerState* o) {
    std::vector<JobState*> todo;
    for (const JobPtr& j : p.ready) {
        if (!j->queued) continue;
        if (j->owner.get() == o) return j;
        const std::uint64_t mark = ++p.walk;
        todo.assign(1, j.get());
        j->mark = mark;
        while (!todo.empty()) {
            JobState* cur = todo.back();
            todo.pop_back();
            for (const JobPtr& d : cur->dependents) {
                if (d->owner.get() == o) return j;
                if (d->mark == mark) continue;
                d->mark = mark;
                todo.push_back(d.get());
            }
        }
    }
    return nullptr;
}

// True when `root` can only finish after the wait this thread is starting has ended: root, or a job it needs, runs on
// this thread, or runs on another thread under a wait that (through more waits and dependencies) leads back here.
// Pool::mu must be held; every frame of every thread changes only under it.
bool never_ends_locked(Pool& p, JobState* root) {
    const std::uint64_t mark = ++p.walk;
    std::vector<JobState*> todo{root};
    root->mark = mark;
    auto visit = [&](JobState* j) {
        if (j->finished || j->mark == mark) return;
        j->mark = mark;
        todo.push_back(j);
    };
    while (!todo.empty()) {
        JobState* cur = todo.back();
        todo.pop_back();
        if (cur->finished) continue;
        if (cur->runningOn == &tls) return true;  // it is under this wait on this thread's stack
        if (ThreadInfo* t = cur->runningOn) {
            // It ends only after every wait above it on that thread: follow them.
            for (std::size_t k = cur->frame + 1; k < t->frames.size(); ++k)
                if (JobState* w = t->frames[k].waitFor) visit(w);
        }
        for (const JobPtr& d : cur->deps) visit(d.get());
    }
    return false;
}

void worker_main(int index, std::uint32_t gen) {
    tls.gen = gen;
    tls.lane = index + 1;
    const std::string name = "fa-job-" + std::to_string(index + 1);
    detail::set_current_thread_name(name.c_str());
    Pool& p = pool();
    std::unique_lock<std::mutex> lk(p.mu);
    for (;;) {
        p.workCv.wait(lk, [&p] { return p.readyCount > 0 || p.stopping; });
        JobPtr j = pop_front_locked(p);
        if (!j) break;  // stopping and nothing left: the jobs queued during shutdown ran too
        lk.unlock();
        run_job(j);
        j.reset();  // the last reference may go here: not under the lock
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
    // Exactly what the project schema allows: the strings "auto" and "inline" (lowercase, no spaces) or an integer.
    if (v.is_string()) {
        const std::string text = v.get<std::string>();
        if (text == "auto") return Settings::automatic();
        if (text == "inline") return Settings::inline_jobs();
        const std::string t(trim(text));
        const std::string_view digits = std::string_view(t).substr(!t.empty() && t[0] == '-' ? 1 : 0);
        if (!digits.empty() && std::all_of(digits.begin(), digits.end(), [](char c) { return c >= '0' && c <= '9'; }))
            return make_error(std::string(where) + ": the thread count is the string \"" + text +
                                  "\"; write it as a number",
                              "Use " + t + " without quotes (\"jobThreads\": " + t + "), \"auto\" or \"inline\".");
        const std::string lower = to_lower(t);
        if (lower == "auto" || lower == "inline")
            return make_error(std::string(where) + ": \"" + text + "\" is not a job thread setting; write \"" + lower +
                                  "\" (lowercase, no spaces)",
                              range_hint());
        return make_error(std::string(where) + ": unknown job thread setting \"" + text + "\". " +
                              did_you_mean(lower, setting_words()),
                          range_hint());
    }
    if (v.is_number_unsigned()) {
        const std::uint64_t u = v.get<std::uint64_t>();
        return count_setting(u > std::uint64_t(kMaxWorkers) ? std::int64_t(kMaxWorkers) + 1 : std::int64_t(u), where,
                             std::to_string(u));
    }
    if (v.is_number_integer()) return count_setting(v.get<std::int64_t>(), where, std::to_string(v.get<std::int64_t>()));
    if (v.is_number_float()) {
        const double d = v.get<double>();
        const bool whole = std::isfinite(d) && d == std::floor(d) && d >= 0 && d <= double(kMaxWorkers);
        return make_error(std::string(where) + ": the thread count " + v.dump() + " is not an integer" +
                              (whole ? "; write it without a decimal point" : ""),
                          whole ? "Use " + std::to_string(int(d)) + " (\"jobThreads\": " + std::to_string(int(d)) + ")."
                                : range_hint());
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

namespace {

void start_impl(const Settings& s, std::vector<std::pair<LogLevel, std::string>>& logs, Result<void>& result) {
    Pool& p = pool();
    std::lock_guard<std::mutex> lk(p.mu);
    if (p.refs > 0) {
        if (std::this_thread::get_id() != p.mainId) {
            result = make_error("jobs::start() was called from a thread that is not the job pool's main thread: the "
                                "pool already runs, started by another thread",
                                "Create and run every Engine on the same thread (the main thread), or stop the pool "
                                "everywhere before starting it from another thread.");
            return;
        }
        ++p.refs;
        if (!(s == p.settings))
            logs.emplace_back(LogLevel::Debug, "the job pool already runs with jobThreads " + p.settings.describe() +
                                                   "; " + s.describe() + " is ignored until it stops");
        return;
    }
    p.refs = 1;
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
            logs.emplace_back(LogLevel::Warn, "could not start job thread " + std::to_string(i + 1) + " of " +
                                                  std::to_string(want) + " (" + e.what() + "); the pool runs with " +
                                                  std::to_string(i));
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
        p.frameOwner = nullptr;
        p.frameOwnerLast = Clock::time_point();
        for (LaneCounters& l : p.lanes) {  // the first frame counts from here, not what ran inline before
            l.jobs.store(0, std::memory_order_relaxed);
            l.busyNs.store(0, std::memory_order_relaxed);
        }
        p.submitted.store(0, std::memory_order_relaxed);
        p.mainTasksRun.store(0, std::memory_order_relaxed);
        p.otherUsed.store(false, std::memory_order_relaxed);
    }
    logs.emplace_back(LogLevel::Debug, "job pool started: jobThreads " + s.describe() + ", " +
                                           std::to_string(p.workers) + " worker thread(s), " +
                                           std::to_string(hardware_threads()) + " hardware thread(s)");
}

void flush_logs(const std::vector<std::pair<LogLevel, std::string>>& logs) {
    for (const auto& [level, text] : logs) fa::log(level, "jobs", text);
}

// In a job, or in a wait (only this thread changes its own frames, so it may read them without the lock).
bool inside_job() { return !tls.frames.empty(); }

}  // namespace

// --------------------------------------------------------------------------------------------------------- the pool
Result<void> start(const Settings& s) {
    if (inside_job())
        return make_error("jobs::start() was called from inside a job",
                          "Start the pool from the main thread before submitting jobs (Engine::init does).");
    Pool& p = pool();
    std::vector<std::pair<LogLevel, std::string>> logs;
    Result<void> result;
    {
        std::lock_guard<std::mutex> life(p.life);  // waits for a stop() that another thread is in the middle of
        start_impl(s, logs, result);
    }
    flush_logs(logs);
    return result;
}

void stop() {
    if (inside_job()) {
        FA_ERROR("jobs", "jobs::stop() was called from inside a job; the pool keeps running (stop it from the thread "
                         "that started it, outside jobs)");
        return;
    }
    Pool& p = pool();
    std::vector<std::pair<LogLevel, std::string>> logs;
    std::vector<MainTask> dropped;
    {
        std::lock_guard<std::mutex> life(p.life);
        std::vector<std::thread> joining;
        bool last = false;
        {
            std::lock_guard<std::mutex> lk(p.mu);
            if (p.refs == 0) {
                logs.emplace_back(LogLevel::Warn, "jobs::stop() without a matching jobs::start()");
            } else if (--p.refs == 0) {
                last = true;
                p.stopping = true;
                joining = std::move(p.threads);
                p.threads.clear();
            }
        }
        if (last) {
            p.workCv.notify_all();
            for (std::thread& t : joining)
                if (t.joinable()) t.join();
            // Jobs another thread queued after the last worker left run here; then the pool is off and submit runs
            // inline.
            for (;;) {
                JobPtr j;
                {
                    std::lock_guard<std::mutex> lk(p.mu);
                    j = pop_front_locked(p);
                    if (!j) {
                        p.ready.clear();
                        p.readyCount = 0;
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
            {
                std::lock_guard<std::mutex> lk(p.mainMu);
                dropped.swap(p.mainQueue);
            }
            p.mainQueued.fetch_sub(int(dropped.size()), std::memory_order_relaxed);
            {
                std::lock_guard<std::mutex> st(p.statsMu);
                p.frameOwner = nullptr;
                p.frameOwnerLast = Clock::time_point();
            }
        }
    }
    flush_logs(logs);
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
        bool stuck = false;
        {
            std::unique_lock<std::mutex> lk(p.mu);
            if (!j->finished) {
                tls.frames.push_back(Frame{nullptr, j.get()});
                ++p.waiters;
                while (!j->finished) {
                    if (JobPtr next = find_needed_locked(p, j)) {
                        take_locked(p, next.get());
                        lk.unlock();
                        run_job(next);
                        next.reset();  // the last reference may go here: not under the lock
                        lk.lock();
                        continue;
                    }
                    if (never_ends_locked(p, j.get())) {
                        stuck = true;
                        break;
                    }
                    p.doneCv.wait(lk);
                }
                --p.waiters;
                tls.frames.pop_back();  // this wait's frame: the jobs it ran have ended
            }
        }
        if (stuck) {
            FA_ERROR("jobs", "waiting for job '{}' can never end: it needs a job that is waiting for it", j->name);
            return make_error("waiting for job '" + j->name +
                                  "' can never end: it (or a job it needs) can only finish after this wait ends",
                              "Do not wait inside a job for a job that needs the waiting job (directly, through its "
                              "dependencies or through another wait); pass the dependency to submit() instead.");
        }
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

std::vector<std::pair<std::size_t, std::size_t>> weighted_ranges(const std::vector<std::size_t>& weights, std::size_t target,
                                                                 std::size_t minTotal) {
    std::vector<std::pair<std::size_t, std::size_t>> out;
    if (weights.empty()) return out;
    std::size_t total = 0;
    for (std::size_t w : weights) total += w;
    if (total < minTotal || jobs::worker_count() == 0) {
        out.emplace_back(0, weights.size());
        return out;
    }
    std::size_t first = 0, sum = 0;
    for (std::size_t i = 0; i < weights.size(); ++i) {
        sum += weights[i];
        if (sum >= target) {
            out.emplace_back(first, i + 1);
            first = i + 1;
            sum = 0;
        }
    }
    if (first < weights.size()) out.emplace_back(first, weights.size());
    return out;
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

// Runs chunks until none is left; the thread's chunks go to the profiler as one entry (count and total time).
void run_chunks(ForState& s) {
    const int lane = current_lane();
    std::uint64_t ran = 0, ns = 0;
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
        ns += ns_since(t0);
        ++ran;
    }
    if (ran > 0) record(lane, s.name, ran, ns);
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
    // The join: a job that is never queued and depends on the helpers. Its wait frame is on this thread while this
    // thread runs its own chunks too, so a helper's chunk that waits for a job under this call (the job that runs
    // this parallel_for) sees the loop and gets an error where it waits, instead of this call returning while that
    // chunk still runs. It also makes the chunks run here count as inside a job (start(), Owner::wait refused).
    auto join = std::make_shared<JobState>();
    join->name = s->name;
    join->internal = true;
    bool wake = false;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        for (const Handle& h : hs)
            if (const JobPtr& d = Access::state(h); d && !d->finished) join->deps.push_back(d);
        tls.frames.push_back(Frame{nullptr, join.get()});
        wake = p.waiters > 0;
    }
    if (wake) p.doneCv.notify_all();  // a helper's chunk already in a wait checks again: it may be a loop now
    run_chunks(*s);
    // Never returns while a helper runs: fn and what it captures belong to the caller. A helper still queued is taken
    // here and finds no chunk left; one running on a worker is waited for. This wait looks for no loop: a loop
    // through it is found by the helper's own wait (it sees the join frame), which then ends with an error.
    bool helperFailed = false;
    std::vector<JobPtr> release;
    {
        std::unique_lock<std::mutex> lk(p.mu);
        ++p.waiters;
        for (;;) {
            if (JobPtr next = find_needed_locked(p, join)) {
                take_locked(p, next.get());
                lk.unlock();
                run_job(next);
                next.reset();  // the last reference may go here: not under the lock
                lk.lock();
                continue;
            }
            if (std::all_of(join->deps.begin(), join->deps.end(), [](const JobPtr& d) { return d->finished; })) break;
            p.doneCv.wait(lk);
        }
        --p.waiters;
        tls.frames.pop_back();  // the join's frame
        for (const JobPtr& d : join->deps) helperFailed = helperFailed || d->failed;
        release.swap(join->deps);
    }
    release.clear();
    if (helperFailed && s->failures == 0)  // run_chunks catches every throw: a helper never fails today
        return make_error("parallel_for '" + s->name + "': a helper job failed",
                          "This is a job system bug: report it with the log.");
    if (s->failures == 0) return {};
    const Chunk c = chunk_at(count, grain, s->errIndex, seed);
    FA_ERROR("jobs", "parallel_for '{}': {} of {} chunk(s) failed; the first is chunk {} (items {}..{}): {}", s->name,
             s->failures, chunks, c.index, c.begin, c.end - 1, s->errWhat);
    return make_error("parallel_for '" + s->name + "' chunk " + std::to_string(c.index) + " (items " +
                          std::to_string(c.begin) + ".." + std::to_string(c.end - 1) + ") failed: " + s->errWhat +
                          (s->failures > 1 ? " (" + std::to_string(s->failures) + " chunks failed)" : std::string()),
                      "The job system caught the exception; every other chunk ran. Fix the code the chunk runs.");
}

// ------------------------------------------------------------------------------------------------------------ owners
Owner::Owner(std::string_view name) : state_(std::make_shared<OwnerState>()) {
    state_->name.assign(name.data(), name.size());
}

Owner::~Owner() {
    {
        std::lock_guard<std::mutex> lk(state_->mainMu);
        state_->alive = false;
    }
    close();
}

const std::string& Owner::name() const { return state_->name; }

int Owner::pending() const {
    Pool& p = pool();
    std::lock_guard<std::mutex> lk(p.mu);
    return state_->pending;
}

Result<void> Owner::wait() {
    if (inside_job())
        return make_error("Owner::wait() for '" + state_->name + "' was called from inside a job",
                          "Wait for an owner's jobs from the thread that owns it, outside jobs (Engine::shutdown "
                          "does); inside a job wait for the handles it needs.");
    Pool& p = pool();
    std::unique_lock<std::mutex> lk(p.mu);
    ++p.waiters;
    while (state_->pending > 0) {
        // Only what this owner needs: its own queued jobs and the queued jobs (of any owner) one of its jobs depends
        // on, so it also ends with 0 workers. Anything else stays queued for its own engine.
        if (JobPtr next = find_owner_needs_locked(p, state_.get())) {
            take_locked(p, next.get());
            lk.unlock();
            run_job(next);
            next.reset();
            lk.lock();
            continue;
        }
        p.doneCv.wait(lk);
    }
    --p.waiters;
    return {};
}

int Owner::run_main_thread_tasks() {
    std::vector<MainTask> tasks;
    {
        std::lock_guard<std::mutex> lk(state_->mainMu);
        if (state_->main.empty()) return 0;
        tasks.swap(state_->main);
    }
    return run_tasks(tasks);
}

int Owner::main_tasks_queued() const {
    std::lock_guard<std::mutex> lk(state_->mainMu);
    return int(state_->main.size());
}

void Owner::close() {
    Pool& p = pool();
    std::vector<MainTask> dropped;
    {
        std::lock_guard<std::mutex> lk(state_->mainMu);
        dropped.swap(state_->main);
    }
    p.mainQueued.fetch_sub(int(dropped.size()), std::memory_order_relaxed);
    {
        std::lock_guard<std::mutex> st(p.statsMu);
        if (p.frameOwner == state_.get()) {
            p.frameOwner = nullptr;
            p.frameOwnerLast = Clock::time_point();
        }
    }
    if (!dropped.empty())
        FA_DEBUG("jobs", "{}: {} main-thread task(s) still queued were dropped (first: '{}')", state_->name,
                 dropped.size(), dropped.front().name);
}

OwnerScope::OwnerScope(Owner* owner) : previous_(tls.owner) {
    tls.owner = owner ? Access::state(*owner).get() : nullptr;
}

OwnerScope::~OwnerScope() { tls.owner = previous_; }

std::string current_owner_name() { return tls.owner ? tls.owner->name : std::string(); }

// ------------------------------------------------------------------------------------------ the main thread's queue
void post_main(std::string_view name, std::function<void()> fn) {
    Pool& p = pool();
    if (!running()) {
        // No main thread to hand it to (like submit() before start): it runs now.
        std::vector<MainTask> now;
        now.push_back(MainTask{std::string(name), std::move(fn)});
        p.mainQueued.fetch_add(1, std::memory_order_relaxed);
        run_tasks(now);
        return;
    }
    if (OwnerState* o = tls.owner) {
        {
            std::lock_guard<std::mutex> lk(o->mainMu);
            if (o->alive) {
                p.mainQueued.fetch_add(1, std::memory_order_relaxed);
                o->main.push_back(MainTask{std::string(name), std::move(fn)});
                return;
            }
        }
        FA_DEBUG("jobs", "main-thread task '{}' of '{}' was dropped: its owner is gone", name, o->name);
        fn = nullptr;  // its captures go now, outside the lock
        return;
    }
    p.mainQueued.fetch_add(1, std::memory_order_relaxed);
    std::lock_guard<std::mutex> lk(p.mainMu);
    p.mainQueue.push_back(MainTask{std::string(name), std::move(fn)});
}

int main_tasks_queued() { return std::max(0, pool().mainQueued.load(std::memory_order_relaxed)); }

int run_main_thread_tasks() {
    Pool& p = pool();
    if (running() && !is_main_thread()) return 0;
    std::vector<MainTask> tasks;
    {
        std::lock_guard<std::mutex> lk(p.mainMu);
        if (p.mainQueue.empty()) return 0;
        tasks.swap(p.mainQueue);
    }
    return run_tasks(tasks);
}

void end_frame(const Owner* owner) {
    Pool& p = pool();
    if (running() && !is_main_thread()) return;
    if (running() && !inline_mode() && worker_count() == 0) {
        // Nobody else runs queued jobs: those nobody waited for run now (the ones they queue wait for next frame).
        std::size_t n = 0;
        {
            std::lock_guard<std::mutex> lk(p.mu);
            n = p.ready.size();
        }
        for (std::size_t i = 0; i < n; ++i) {  // n entries of `ready`: the ones a wait took count too
            JobPtr j;
            bool run = false;
            {
                std::lock_guard<std::mutex> lk(p.mu);
                if (p.ready.empty()) break;
                if (!p.ready.front()->queued) {
                    j = std::move(p.ready.front());  // taken by a wait: only the entry goes (after the lock)
                    p.ready.pop_front();
                } else {
                    j = pop_front_locked(p);
                    run = j != nullptr;
                }
            }
            if (run) run_job(j);
        }
    }
    std::lock_guard<std::mutex> st(p.statsMu);
    if (owner) {
        const OwnerState* o = Access::state(*owner).get();
        const Clock::time_point now = Clock::now();
        if (p.frameOwner == o) {
            p.frameOwnerLast = now;
        } else if (p.frameOwner && now - p.frameOwnerLast < std::chrono::milliseconds(kFrameOwnerHandOverMs)) {
            return;  // another engine closes the frames
        } else {
            // No owner yet, or the one that had it stopped ending frames without closing (a hidden view): this one.
            p.frameOwner = o;
            p.frameOwnerLast = now;
        }
    }
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
        out.waiting = p.waiters;
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
                         {"waiting", i.waiting},
                         {"mainTasksQueued", i.mainTasksQueued},
                         {"lanes", lanes}});
}

}  // namespace fa::jobs
