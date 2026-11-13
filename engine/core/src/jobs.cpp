// The job system (fa/core/jobs.h): the pool, the queues, waits and parallel_for.
//
// How it is built (M94.5b2: per-worker queues with stealing; before, one FIFO under one mutex):
// - Ready jobs sit in one queue per worker (ReadyQueue, each with its own small mutex), plus queue 0, used only while
//   the pool has no worker thread. A worker queues the jobs it submits or releases in its own queue; any other thread
//   (the main thread, a loader) deals them out round-robin over the workers' queues. A worker takes the oldest job of
//   its own queue, then steals the oldest of the others. Workers hardly ever share a lock: the main thread pushes into
//   one queue while its worker pops from it, an idle worker steals.
// - A job in a queue is taken by whoever flips its `queued` flag to false first (an atomic exchange), so it runs once.
//   A wait takes the jobs it needs straight from the dependency graph, wherever they are queued; their entries stay
//   behind and are dropped by the next thread that pops them (`wake.ready` counts only the jobs still to take).
// - Sleep and wake without lost wake-ups: a worker that finds nothing registers in `sleepers` and checks `wake.ready`
//   under `sleepMu` before it sleeps; a thread that queues a job adds to `wake.ready` first and wakes a sleeper only
//   when `sleepers` says one may sleep (both sequentially consistent, so one of the two sees the other). Idle workers
//   sleep on the condition variable: no spinning.
// - Pool::mu still guards the dependency graph (pendingDeps, dependents, deps), the wait bookkeeping (frames other
//   threads read, waiters, the graph walks), and start/stop. A job that nobody depends on or waits for, submitted with
//   its dependencies done, never takes it: submit queues it, the worker runs it and marks it done with atomics. The
//   end of a job takes Pool::mu only when the job is `watched` (a dependent, a wait or a parallel_for join looked at
//   it), had dependencies, or waited itself: `watched` is set under the lock before the watcher reads `doneFlag`, and
//   the job's end stores `doneFlag` before it reads `watched` (both sequentially consistent), so at least one of them
//   sees the other and no dependent or waiter is missed.
// - A wait for a job that is still queued takes it and runs it at once, without the lock. Otherwise it sleeps on
//   doneCv and wakes when its job ends, a job becomes queued, or its owner's last job ends.
// - A worker that ends a job which releases dependents runs the first of them itself next (it never goes to a queue),
//   so a chain of jobs stays on one thread without a queue or a wake-up per link.
// - Waits that can never end (never_ends_locked) follow the frames of other threads. A thread publishes its frames
//   (the jobs running on it, under Pool::mu) only when it starts a wait: until then nothing can wait behind its jobs.
//   Frames below `published` change only under Pool::mu; the ones above are this thread's alone.
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
    std::atomic<int> pending{0};  // its jobs not finished
    std::atomic<int> waiting{0};  // threads in Owner::wait for it (the end of its last job wakes them)
    mutable std::mutex mainMu;
    std::vector<MainTask> main;  // mainMu
    bool alive = true;           // mainMu: false once the Owner is destroyed (its late tasks are dropped)
};

struct ThreadInfo;

struct JobState {
    std::string name;
    std::function<void()> fn;  // moved out by the one thread that takes the job (or dropped when it is skipped)
    bool internal = false;     // a parallel_for helper: its chunks are counted, not the helper itself
    std::shared_ptr<OwnerState> owner;
    // Written before the job is queued, or under Pool::mu.
    int pendingDeps = 0;    // Pool::mu
    bool waited = false;    // Pool::mu: a wait or a parallel_for join sleeps until it ends (its end wakes them)
    bool failed = false;    // written before doneFlag by the thread that ends it; read after doneFlag
    Error error;            // what wait() returns when failed
    Error rootError;        // the throw a failure goes back to (for skipped dependents)
    std::string failedDep;  // the first dependency that failed: the job is skipped
    std::vector<std::shared_ptr<JobState>> dependents;  // Pool::mu
    std::vector<std::shared_ptr<JobState>> deps;  // Pool::mu: the dependencies not finished at submit (dropped at end)
    ThreadInfo* runningOn = nullptr;              // Pool::mu: the thread running it, once that thread published it
    std::size_t frame = 0;                        // Pool::mu: its place in runningOn->frames
    std::uint64_t mark = 0;                       // Pool::mu: graph walks (Pool::walk)
    std::atomic<bool> queued{false};   // in a ReadyQueue and not taken: the thread that flips it to false runs it
    std::atomic<bool> watched{false};  // a dependent or a wait looks at it: its end goes through Pool::mu
    std::atomic<bool> doneFlag{false};  // finished, readable without the lock
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
    bool full() const { return count == capacity; }
    std::size_t size() const { return count; }
    const Frame& operator[](std::size_t i) const { return data[i]; }
    void grow();
    void push_back(const Frame& f) {  // under Pool::mu when it grows while frames are published (push_job_frame)
        if (count == capacity) grow();
        data[count++] = f;
    }
    void pop_back() { --count; }
};

struct ThreadInfo {
    std::uint32_t gen = 0;
    int lane = -1;
    std::uint32_t deal = 0;       // round-robin over the workers' queues for the jobs this thread queues
    OwnerState* owner = nullptr;  // the current owner (OwnerScope, or the job running now)
    FrameStack frames;            // only this thread changes it; other threads read [0, published) under Pool::mu
    std::size_t published = 0;    // Pool::mu (written by this thread only): frames other threads may read
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
    std::atomic<std::int64_t> live{0};  // jobs submitted minus jobs finished on this thread (jobs.info sums them)
};

// The ready jobs of one worker (queue 0: of the pool without workers). Its own cache line: a worker and the thread that
// deals it jobs touch only this one.
struct alignas(64) ReadyQueue {
    std::mutex mu;
    std::deque<std::shared_ptr<JobState>> jobs;  // mu; oldest first; entries a wait took out of order stay until popped
    std::atomic<std::size_t> size{0};            // jobs.size(), read without the lock to skip empty queues
    bool closed = true;                          // mu: no pool, or a queue beyond the pool's workers: push fails
};

// What the sleep and wake protocol shares, on a line of its own.
struct alignas(64) WakeState {
    std::atomic<int> ready{0};     // jobs queued and not taken yet (a wait may have taken one whose entry is still there)
    std::atomic<int> sleepers{0};  // workers asleep on workCv, or about to check `ready` once more first
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
    std::mutex mu;    // everything below up to `threads`, the graph fields of every JobState, published frames
    std::condition_variable doneCv;  // waiters sleep here until a job they look at ends or becomes queued
    int refs = 0;
    bool active = false;  // started and not fully stopped
    bool inlineMode = false;
    int workers = 0;
    // Threads in a wait (jobs.info "waiting"). The ones that may sleep on doneCv count under `mu`, so a thread that
    // ends a job under `mu` and reads 0 knows nobody sleeps; a wait that just runs the queued job it waits for counts
    // without the lock (it never sleeps).
    std::atomic<int> waiters{0};
    std::uint64_t walk = 0;
    Settings settings;
    std::thread::id mainId;
    std::vector<std::thread> threads;

    std::array<ReadyQueue, kMaxWorkers + 1> queues;  // [0] with no worker, [i] worker i's (lane i)
    WakeState wake;
    std::mutex sleepMu;              // the check of wake.ready before a worker sleeps, and its wait
    std::condition_variable workCv;  // idle workers sleep here
    std::atomic<bool> stopFlag{false};

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
#pragma warning(pop)  // C4324 covers LaneCounters, ReadyQueue, WakeState and Pool, which holds them
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
        // stack is empty, nothing published), and other threads only read the published frames of a thread.
        delete[] tls.frames.data;
        tls.frames = detail::FrameStack{};
        tls.published = 0;
        tls.reaped = true;
    }
};
thread_local FrameReaper reaper;

}  // namespace

void detail::FrameStack::grow() {
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

namespace {

std::uint64_t ns_since(Clock::time_point t0) {
    const auto d = Clock::now() - t0;
    const auto n = std::chrono::duration_cast<std::chrono::nanoseconds>(d).count();
    return n > 0 ? std::uint64_t(n) : 0;
}

double round2(double v) { return std::round(v * 100.0) / 100.0; }
double round1(double v) { return std::round(v * 10.0) / 10.0; }

std::size_t lane_index(int lane) {
    return lane >= 0 && lane < kMaxLanes ? std::size_t(lane) : std::size_t(kMaxLanes - 1);
}

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
    return make_error("job '" + j.name + "' did not run: its dependency '" + j.failedDep +
                          "' failed: " + j.rootError.message,
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

// ------------------------------------------------------------------------------------------------- queues and wakes
// Takes `j` if it is queued and nobody took it first. The one thread that gets true runs it.
bool try_take(Pool& p, JobState* j) {
    if (!j->queued.load(std::memory_order_relaxed)) return false;
    if (!j->queued.exchange(false, std::memory_order_acq_rel)) return false;
    p.wake.ready.fetch_sub(1, std::memory_order_relaxed);
    return true;
}

// Queues `j` (a job of this thread's `lane`; the pool has `workers` workers): a worker's own queue, else the next
// worker's queue in turn, or queue 0 without workers. False when that queue is closed (the pool stopped, or started again
// with fewer workers, since the caller looked): the caller runs the job itself. Callers wake a worker afterwards
// (wake_workers): this only counts the job in `wake.ready`.
bool enqueue(Pool& p, const JobPtr& j, int lane, int workers) {
    std::size_t index = 0;
    if (workers > 0)
        index = lane >= 1 && lane <= workers ? std::size_t(lane) : 1 + std::size_t(tls.deal++ % unsigned(workers));
    ReadyQueue& q = p.queues[index];
    {
        std::lock_guard<std::mutex> lk(q.mu);
        if (q.closed) return false;
        j->queued.store(true, std::memory_order_release);
        q.jobs.push_back(j);
        q.size.store(q.jobs.size(), std::memory_order_relaxed);
    }
    p.wake.ready.fetch_add(1, std::memory_order_seq_cst);  // before the sleepers check of wake_workers
    return true;
}

// Wakes sleeping workers for `count` jobs just queued (none when every worker is awake: they look before they sleep).
void wake_workers(Pool& p, int count) {
    if (count <= 0 || p.wake.sleepers.load(std::memory_order_seq_cst) == 0) return;
    // A worker checks wake.ready under sleepMu and sleeps without letting go of it in between: once this lock is ours,
    // every worker that registered is either asleep (and gets the notify) or has not checked yet (and sees the job).
    { std::lock_guard<std::mutex> lk(p.sleepMu); }
    if (count == 1)
        p.workCv.notify_one();
    else
        p.workCv.notify_all();
}

// Wakes the threads asleep on doneCv. Taking Pool::mu first means none is between its check and its sleep.
void wake_waiters(Pool& p) {
    { std::lock_guard<std::mutex> lk(p.mu); }
    p.doneCv.notify_all();
}

// A job of an owner that an Owner::wait sleeps for became queued: with no free worker, that wait must take it.
void wake_owner_waiters(Pool& p, const JobState& j) {
    if (j.owner && j.owner->waiting.load(std::memory_order_seq_cst) > 0) wake_waiters(p);
}

// The oldest job of `q` that nobody took yet, taken; null when none. Entries a wait took out of order are dropped.
JobPtr pop_take(Pool& p, ReadyQueue& q) {
    while (q.size.load(std::memory_order_relaxed) > 0) {
        JobPtr j;
        {
            std::lock_guard<std::mutex> lk(q.mu);
            if (q.jobs.empty()) return nullptr;
            j = std::move(q.jobs.front());
            q.jobs.pop_front();
            q.size.store(q.jobs.size(), std::memory_order_relaxed);
        }
        if (try_take(p, j.get())) return j;
        // A wait took it out of order: only its entry was left here; it goes now, outside the lock.
    }
    return nullptr;
}

// A job for worker `self`: the oldest of its own queue, else the oldest of another queue (stealing). Null when none.
JobPtr take_ready(Pool& p, int self) {
    const int n = p.workerCount.load(std::memory_order_relaxed);
    for (int k = 0; k <= n; ++k) {
        const int i = (self + k) % (n + 1);
        if (JobPtr j = pop_take(p, p.queues[std::size_t(i)])) return j;
    }
    return nullptr;
}

// ------------------------------------------------------------------------------------------------ frames and ends
// Puts `j`, which this thread is about to run, on its stack. Not published: no other thread sees it until this thread
// starts a wait (publish_locked). Pool::mu must not be held.
void push_job_frame(JobState* j) {
    detail::FrameStack& fs = tls.frames;
    if (fs.full() && tls.published > 0) {
        std::lock_guard<std::mutex> lk(pool().mu);  // other threads read the published frames: they move
        fs.grow();
    }
    fs.push_back(Frame{j, nullptr});
}

// Lets other threads see the jobs running on this thread (before it starts a wait). Pool::mu must be held.
void publish_locked() {
    for (std::size_t k = tls.published; k < tls.frames.size(); ++k)
        if (JobState* j = tls.frames[k].job) {
            j->runningOn = &tls;
            j->frame = k;
        }
    tls.published = tls.frames.size();
}

// Pushes a wait for `j` on this thread's stack, published with every frame below it. Pool::mu must be held.
void push_wait_frame_locked(JobState* j) {
    publish_locked();
    tls.frames.push_back(Frame{nullptr, j});
    tls.published = tls.frames.size();
}

void pop_wait_frame_locked() {
    tls.frames.pop_back();
    tls.published = tls.frames.size();
}

void add_pending(Pool& p, const JobState& j, int lane) {
    p.lanes[lane_index(lane)].live.fetch_add(1, std::memory_order_relaxed);
    if (j.owner) j.owner->pending.fetch_add(1, std::memory_order_relaxed);
}

// One job fewer in the pool (jobs.info "pending"). Before doneFlag: a thread whose wait for the job ended reads 0.
void count_live(Pool& p, int lane) { p.lanes[lane_index(lane)].live.fetch_sub(1, std::memory_order_relaxed); }

// One job fewer for its owner. True when it was the owner's last one and an Owner::wait sleeps for it. After doneFlag:
// when Owner::wait returns, every handle of the owner's jobs is done.
bool count_owner(const JobState& j) {
    OwnerState* o = j.owner.get();
    // seq_cst both: Owner::wait adds to `waiting` before it reads `pending`.
    return o && o->pending.fetch_sub(1, std::memory_order_seq_cst) == 1 &&
           o->waiting.load(std::memory_order_seq_cst) > 0;
}

struct Finished {
    bool mayKeep = false;  // the caller is a worker between jobs: it runs the first released dependent itself
    JobPtr keep;           // that dependent: taken, never queued
    int queued = 0;        // dependents queued (workers to wake)
    bool wakeWaiters = false;
    std::vector<JobPtr> runHere;                 // dependents that became ready while the pool is not running
    std::vector<std::function<void()>> discard;  // functions of skipped jobs: destroyed after the lock is released
    std::vector<JobPtr> release;                 // dependency lists of finished jobs: dropped after the lock too
};

// Marks `j` finished (its failed/error already set and count_live done; doneFlag may be set already) and every
// dependent it releases or skips. `lane` is the calling thread's. Pool::mu must be held.
void finish_locked(Pool& p, const JobPtr& j, int lane, Finished& out) {
    std::vector<JobPtr> work;
    JobPtr cur = j;
    bool ownerWake = false, waited = false;
    for (;;) {
        if (cur != j) count_live(p, lane);  // a skipped dependent
        cur->doneFlag.store(true, std::memory_order_seq_cst);
        waited = waited || cur->waited;
        ownerWake = count_owner(*cur) || ownerWake;
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
                if (out.mayKeep && !out.keep) {
                    out.keep = d;
                } else {
                    // Cannot fail: the queues of a running pool close only under Pool::mu, with `active` false.
                    (void)enqueue(p, d, lane, p.workers);
                    ++out.queued;
                }
            } else {
                out.runHere.push_back(d);
            }
        }
        cur->dependents.clear();
        if (cur != j) out.release.push_back(cur);  // a skipped dependent: its last reference may go, after the lock
        if (work.empty()) break;
        cur = std::move(work.back());
        work.pop_back();
    }
    // Waiters wake for what they may act on: a waited job ended, a job became queued (one they need?), an owner's
    // last job ended. A dependent this thread keeps runs at once, so nobody needs to wake for it.
    out.wakeWaiters = p.waiters.load(std::memory_order_relaxed) > 0 && (waited || out.queued > 0 || ownerWake);
}

JobPtr run_job(const JobPtr& j, bool mayKeep = false);

// After finish_locked, once Pool::mu is released: wakes, drops, and runs what the stopped pool left to this thread.
// Returns the dependent this thread keeps (Finished::mayKeep).
JobPtr after_finish(Pool& p, Finished& f) {
    wake_workers(p, f.queued);
    if (f.wakeWaiters) p.doneCv.notify_all();
    f.discard.clear();
    f.release.clear();
    for (const JobPtr& d : f.runHere) run_job(d);
    return std::move(f.keep);
}

// Ends `j` on this thread. `framePublished`: its frame, still on top of the stack, was published (it waited); else it
// is gone already. Without dependents, dependencies, waiters or a published frame no lock is taken.
JobPtr finish_job(const JobPtr& j, int lane, bool mayKeep, bool framePublished) {
    Pool& p = pool();
    count_live(p, lane);
    if (!framePublished && j->deps.empty() && !j->watched.load(std::memory_order_seq_cst)) {
        j->doneFlag.store(true, std::memory_order_seq_cst);
        if (!j->watched.load(std::memory_order_seq_cst)) {  // still nobody: done (see the file header)
            if (count_owner(*j)) wake_waiters(p);
            return nullptr;
        }
        // A dependent or a wait came between the two loads: finish_locked releases or wakes it.
    }
    Finished f;
    f.mayKeep = mayKeep;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        if (framePublished) {
            pop_wait_frame_locked();  // the job's frame: every wait it made has ended
            j->runningOn = nullptr;
        }
        finish_locked(p, j, lane, f);
    }
    return after_finish(p, f);
}

// Runs `j`, which this thread took, and finishes it. `mayKeep`: a worker between jobs, which runs the first dependent
// `j` releases itself; that one is returned (null otherwise).
JobPtr run_job(const JobPtr& j, bool mayKeep) {
    const int lane = current_lane();
    push_job_frame(j.get());
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
    if (failed) {
        FA_ERROR("jobs", "job '{}' failed: {}", j->name, what);
        j->failed = true;
        j->error = thrown_error(what, j->name);
        j->rootError = j->error;
    }
    const bool published = tls.frames.size() <= tls.published;
    if (!published) tls.frames.pop_back();
    return finish_job(j, lane, mayKeep, published);
}

JobPtr make_job(std::string_view name, std::function<void()> fn, bool internal) {
    auto j = std::make_shared<JobState>();
    j->name.assign(name.data(), name.size());
    j->fn = std::move(fn);
    j->internal = internal;
    if (tls.owner) j->owner = tls.owner->shared_from_this();
    return j;
}

// `j` does not run: a dependency failed (failedDep and rootError set). Nobody can be waiting for it yet.
void skip_new_job(const JobPtr& j, int lane) {
    j->failed = true;
    j->error = skipped_error(*j);
    std::function<void()> discard = std::move(j->fn);
    (void)finish_job(j, lane, false, false);
}

// The pool is stopped or inline (or stopped since the caller looked): `j` runs here, after its dependencies (they may
// run on another thread).
void run_now(const JobPtr& j, const std::vector<Handle>& deps, int lane) {
    for (const Handle& h : deps) {
        const JobPtr& d = Access::state(h);
        if (!d || d.get() == j.get()) continue;
        (void)wait(h);  // its error is reported through this job below
        if (d->failed && j->failedDep.empty()) {
            j->failedDep = d->name;
            j->rootError = d->rootError;
        }
    }
    if (!j->failedDep.empty())
        skip_new_job(j, lane);
    else
        run_job(j);
}

Handle submit_job(const JobPtr& j, const std::vector<Handle>& deps) {
    Pool& p = pool();
    if (!j->internal) p.submitted.fetch_add(1, std::memory_order_relaxed);
    const int lane = current_lane();
    add_pending(p, *j, lane);
    if (!p.activeFlag.load(std::memory_order_acquire) || p.inlineFlag.load(std::memory_order_acquire)) {
        run_now(j, deps, lane);
        return Access::make(j);
    }
    const bool depsDone = std::all_of(deps.begin(), deps.end(), [&j](const Handle& h) {
        const JobPtr& d = Access::state(h);
        return !d || d.get() == j.get() || d->doneFlag.load(std::memory_order_acquire);
    });
    if (depsDone) {
        // Nothing to wait for: no lock. A new job is in nobody's wait yet (waits only take what the waited job needs),
        // so only workers wake.
        for (const Handle& h : deps) {
            const JobPtr& d = Access::state(h);
            if (d && d.get() != j.get() && d->failed && j->failedDep.empty()) {
                j->failedDep = d->name;
                j->rootError = d->rootError;
            }
        }
        if (!j->failedDep.empty()) {
            skip_new_job(j, lane);
        } else if (enqueue(p, j, lane, p.workerCount.load(std::memory_order_relaxed))) {
            wake_workers(p, 1);
            wake_owner_waiters(p, *j);
        } else {
            run_now(j, {}, lane);
        }
        return Access::make(j);
    }
    bool runNow = false, skipped = false, queued = false;
    {
        std::lock_guard<std::mutex> lk(p.mu);
        if (!p.active || p.inlineMode) {
            runNow = true;  // stopped since the check above
        } else {
            for (const Handle& h : deps) {
                const JobPtr& d = Access::state(h);
                if (!d || d.get() == j.get()) continue;
                d->watched.store(true, std::memory_order_seq_cst);  // before doneFlag is read: see the file header
                if (!d->doneFlag.load(std::memory_order_seq_cst)) {
                    ++j->pendingDeps;
                    d->dependents.push_back(j);
                    j->deps.push_back(d);
                } else if (d->failed && j->failedDep.empty()) {
                    j->failedDep = d->name;
                    j->rootError = d->rootError;
                }
            }
            if (j->pendingDeps == 0) {
                if (!j->failedDep.empty())
                    skipped = true;
                else
                    queued = enqueue(p, j, lane, p.workers);  // open: `active` is true under the lock
            }
        }
    }
    if (runNow)
        run_now(j, deps, lane);
    else if (skipped)
        skip_new_job(j, lane);
    else if (queued) {
        wake_workers(p, 1);
        wake_owner_waiters(p, *j);
    }
    return Access::make(j);
}

// A queued job that `root` needs, taken: root itself or one of its unfinished dependencies (and theirs). Pool::mu held.
JobPtr find_needed_locked(Pool& p, const JobPtr& root) {
    const std::uint64_t mark = ++p.walk;
    std::vector<const JobPtr*> todo{&root};
    root->mark = mark;
    while (!todo.empty()) {
        const JobPtr& cur = *todo.back();
        todo.pop_back();
        if (cur->doneFlag.load(std::memory_order_acquire)) continue;
        if (try_take(p, cur.get())) return cur;
        for (const JobPtr& d : cur->deps) {
            if (d->doneFlag.load(std::memory_order_acquire) || d->mark == mark) continue;
            d->mark = mark;
            todo.push_back(&d);
        }
    }
    return nullptr;
}

// The first queued job that `o` needs, taken: one of its own, or one that a job of `o` depends on (through any chain of
// dependents). Null when none. Pool::mu must be held (the queues' locks are taken inside it).
JobPtr find_owner_needs_locked(Pool& p, const OwnerState* o) {
    std::vector<JobPtr> queued;
    for (ReadyQueue& q : p.queues) {
        if (q.size.load(std::memory_order_relaxed) == 0) continue;
        std::lock_guard<std::mutex> lk(q.mu);
        for (const JobPtr& j : q.jobs)
            if (j->queued.load(std::memory_order_acquire)) queued.push_back(j);
    }
    std::vector<JobState*> todo;
    for (const JobPtr& j : queued) {
        bool needed = j->owner.get() == o;
        if (!needed) {
            const std::uint64_t mark = ++p.walk;
            todo.assign(1, j.get());
            j->mark = mark;
            while (!todo.empty() && !needed) {
                JobState* cur = todo.back();
                todo.pop_back();
                for (const JobPtr& d : cur->dependents) {
                    if (d->owner.get() == o) {
                        needed = true;
                        break;
                    }
                    if (d->mark == mark) continue;
                    d->mark = mark;
                    todo.push_back(d.get());
                }
            }
        }
        if (needed && try_take(p, j.get())) return j;
    }
    return nullptr;
}

// True when `root` can only finish after the wait this thread is starting has ended: root, or a job it needs, runs on
// this thread, or runs on another thread under a wait that (through more waits and dependencies) leads back here.
// Pool::mu must be held, and this thread's frames published. A job runs "on" a thread for this walk once that thread
// published it, which it does before every wait: a job whose thread never waited has no wait above it, so it ends.
bool never_ends_locked(Pool& p, JobState* root) {
    const std::uint64_t mark = ++p.walk;
    std::vector<JobState*> todo{root};
    root->mark = mark;
    auto visit = [&](JobState* j) {
        if (j->doneFlag.load(std::memory_order_acquire) || j->mark == mark) return;
        j->mark = mark;
        todo.push_back(j);
    };
    while (!todo.empty()) {
        JobState* cur = todo.back();
        todo.pop_back();
        if (cur->doneFlag.load(std::memory_order_acquire)) continue;
        if (cur->runningOn == &tls) return true;  // it is under this wait on this thread's stack
        if (ThreadInfo* t = cur->runningOn) {
            // It ends only after every wait above it on that thread: follow them.
            for (std::size_t k = cur->frame + 1; k < t->published; ++k)
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
    JobPtr next;  // a dependent the last job released, run here without queueing it
    for (;;) {
        JobPtr j = next ? std::move(next) : take_ready(p, index + 1);
        if (j) {
            next = run_job(j, true);
            j.reset();  // the last reference may go here: not under a lock
            continue;
        }
        // Counted but not found: a thread is between taking a job and counting it. Let it go on.
        if (p.wake.ready.load(std::memory_order_seq_cst) > 0) {
            std::this_thread::yield();
            continue;
        }
        std::unique_lock<std::mutex> lk(p.sleepMu);
        p.wake.sleepers.fetch_add(1, std::memory_order_seq_cst);  // before `ready` is read: see wake_workers
        while (p.wake.ready.load(std::memory_order_seq_cst) <= 0 && !p.stopFlag.load(std::memory_order_acquire))
            p.workCv.wait(lk);
        p.wake.sleepers.fetch_sub(1, std::memory_order_relaxed);
        // Stopping and nothing left: the jobs queued while it stops ran too (stop() runs the ones queued later). Not
        // stopping: woken for a job (another worker may have taken it first), so it looks again.
        if (p.stopFlag.load(std::memory_order_acquire) && p.wake.ready.load(std::memory_order_seq_cst) <= 0) break;
    }
}


#if !defined(__EMSCRIPTEN__)  // the web build has its own cap (kAutoCapWebThreads)
bool is_mobile() {
#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
    return true;
#else
    return false;
#endif
}
#endif

const std::vector<std::string>& setting_words() {
    static const std::vector<std::string> words = {"auto", "inline"};
    return words;
}

std::string range_hint() {
    return "Use \"auto\" (hardware threads - 1, at most " + std::to_string(kAutoCapDesktop) + " on desktop and " +
           std::to_string(kAutoCapMobile) +
           " on phones), \"inline\" (every job runs on the main thread when it is "
           "submitted: for debugging) or a number of worker threads from 0 to " +
           std::to_string(kMaxWorkers) + ".";
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
    if (v.is_number_integer())
        return count_setting(v.get<std::int64_t>(), where, std::to_string(v.get<std::int64_t>()));
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
    p.stopFlag.store(false, std::memory_order_release);
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
    if (!p.inlineMode) {
        // Queue 0 without workers (waits and end_frame run it), else one per worker. Inline: none (submit runs jobs).
        for (int i = 0; i <= p.workers; ++i) {
            ReadyQueue& q = p.queues[std::size_t(i)];
            std::lock_guard<std::mutex> ql(q.mu);
            q.closed = p.workers > 0 && i == 0;
        }
    }
    // Before activeFlag: submit reads activeFlag first, then these.
    p.workerCount.store(p.workers, std::memory_order_release);
    p.inlineFlag.store(p.inlineMode, std::memory_order_release);
    p.activeFlag.store(true, std::memory_order_release);
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
                p.stopFlag.store(true, std::memory_order_release);
                joining = std::move(p.threads);
                p.threads.clear();
            }
        }
        if (last) {
            { std::lock_guard<std::mutex> sl(p.sleepMu); }  // a worker checks stopFlag under it before it sleeps
            p.workCv.notify_all();
            for (std::thread& t : joining)
                if (t.joinable()) t.join();
            // Jobs another thread queued after the last worker left run here; then the pool is off (every queue
            // closed) and submit runs jobs inline.
            for (;;) {
                JobPtr j;
                for (ReadyQueue& q : p.queues)
                    if ((j = pop_take(p, q))) break;
                if (j) {
                    run_job(j);
                    continue;
                }
                std::lock_guard<std::mutex> lk(p.mu);
                std::array<std::unique_lock<std::mutex>, kMaxWorkers + 1> held;
                bool empty = true;
                for (std::size_t i = 0; i < p.queues.size(); ++i) {
                    held[i] = std::unique_lock<std::mutex>(p.queues[i].mu);
                    empty = empty && p.queues[i].jobs.empty();
                }
                if (!empty) continue;  // queued since the look above: run it first
                for (ReadyQueue& q : p.queues) q.closed = true;
                p.active = false;
                p.inlineMode = false;
                p.workers = 0;
                p.settings = Settings{};
                p.mainId = std::thread::id();
                p.gen.fetch_add(1, std::memory_order_acq_rel);
                p.activeFlag.store(false, std::memory_order_release);
                p.inlineFlag.store(false, std::memory_order_release);
                p.workerCount.store(0, std::memory_order_release);
                break;
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
        if (try_take(p, j.get())) {
            // Queued, so its dependencies are done and nothing runs it: it runs here, at once and without the lock. No
            // wait frame is needed: its own frame sits on top of this thread's stack while it runs.
            p.waiters.fetch_add(1, std::memory_order_relaxed);
            run_job(j);
            p.waiters.fetch_sub(1, std::memory_order_relaxed);
        } else {
            std::unique_lock<std::mutex> lk(p.mu);
            j->watched.store(true, std::memory_order_seq_cst);  // before doneFlag is read: see the file header
            if (!j->doneFlag.load(std::memory_order_seq_cst)) {
                j->waited = true;
                push_wait_frame_locked(j.get());
                p.waiters.fetch_add(1, std::memory_order_relaxed);
                while (!j->doneFlag.load(std::memory_order_acquire)) {
                    if (JobPtr next = find_needed_locked(p, j)) {
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
                p.waiters.fetch_sub(1, std::memory_order_relaxed);
                pop_wait_frame_locked();  // this wait's frame: the jobs it ran have ended
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

std::vector<std::pair<std::size_t, std::size_t>> weighted_ranges(const std::vector<std::size_t>& weights,
                                                                 std::size_t target, std::size_t minTotal) {
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
        for (const Handle& h : hs) {
            const JobPtr& d = Access::state(h);
            if (!d) continue;
            d->watched.store(true, std::memory_order_seq_cst);  // before doneFlag is read: see the file header
            if (d->doneFlag.load(std::memory_order_seq_cst)) continue;
            d->waited = true;  // its end wakes the wait below
            join->deps.push_back(d);
        }
        push_wait_frame_locked(join.get());
        wake = p.waiters.load(std::memory_order_relaxed) > 0;
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
        p.waiters.fetch_add(1, std::memory_order_relaxed);
        for (;;) {
            if (JobPtr next = find_needed_locked(p, join)) {
                lk.unlock();
                run_job(next);
                next.reset();  // the last reference may go here: not under the lock
                lk.lock();
                continue;
            }
            if (std::all_of(join->deps.begin(), join->deps.end(),
                            [](const JobPtr& d) { return d->doneFlag.load(std::memory_order_acquire); }))
                break;
            p.doneCv.wait(lk);
        }
        p.waiters.fetch_sub(1, std::memory_order_relaxed);
        pop_wait_frame_locked();  // the join's frame
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

int Owner::pending() const { return std::max(0, state_->pending.load(std::memory_order_acquire)); }

Result<void> Owner::wait() {
    if (inside_job())
        return make_error("Owner::wait() for '" + state_->name + "' was called from inside a job",
                          "Wait for an owner's jobs from the thread that owns it, outside jobs (Engine::shutdown "
                          "does); inside a job wait for the handles it needs.");
    Pool& p = pool();
    OwnerState* const o = state_.get();
    if (o->pending.load(std::memory_order_acquire) <= 0) return {};
    // Before `pending` is read again: the end of the owner's last job reads `waiting` after it counts (see
    // count_finished), so one of the two sees the other.
    o->waiting.fetch_add(1, std::memory_order_seq_cst);
    {
        std::unique_lock<std::mutex> lk(p.mu);
        p.waiters.fetch_add(1, std::memory_order_relaxed);
        while (o->pending.load(std::memory_order_seq_cst) > 0) {
            // Only what this owner needs: its own queued jobs and the queued jobs (of any owner) one of its jobs
            // depends on, so it also ends with 0 workers. Anything else stays queued for its own engine.
            if (JobPtr next = find_owner_needs_locked(p, o)) {
                lk.unlock();
                run_job(next);
                next.reset();
                lk.lock();
                continue;
            }
            p.doneCv.wait(lk);
        }
        p.waiters.fetch_sub(1, std::memory_order_relaxed);
    }
    o->waiting.fetch_sub(1, std::memory_order_relaxed);
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
        ReadyQueue& q = p.queues[0];
        const std::size_t n = q.size.load(std::memory_order_relaxed);
        for (std::size_t i = 0; i < n; ++i) {  // n entries of queue 0: the ones a wait took count too
            JobPtr j;
            {
                std::lock_guard<std::mutex> lk(q.mu);
                if (q.jobs.empty()) break;
                j = std::move(q.jobs.front());
                q.jobs.pop_front();
                q.size.store(q.jobs.size(), std::memory_order_relaxed);
            }
            if (try_take(p, j.get())) run_job(j);  // else a wait took it: only the entry goes (after the lock)
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
    }
    std::int64_t live = 0;  // per lane: a job may end on another lane than the one that submitted it
    for (const LaneCounters& l : p.lanes) live += l.live.load(std::memory_order_relaxed);
    out.pending = int(std::clamp<std::int64_t>(live, 0, std::numeric_limits<int>::max()));
    out.waiting = std::max(0, p.waiters.load(std::memory_order_relaxed));
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
        lanes.push_back(
            Json::object({{"name", l.name}, {"jobs", l.jobs}, {"busyMs", l.busyMs}, {"busyPct", l.busyPct}}));
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
