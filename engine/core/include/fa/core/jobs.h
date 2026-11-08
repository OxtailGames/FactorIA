// Job system: one process-wide pool of worker threads that engine code hands small pieces of work to
// (docs/ARCHITECTURE.md, "Jobs and threads"; docs/PERFORMANCE.md, "Job threads").
//
// The Engine starts the pool in init() and joins it in shutdown() (jobs::start / jobs::stop, reference counted). Before
// the pool starts, after it stops, and in inline mode every job runs at once on the thread that submits it, so code
// that uses jobs also works in tools and tests that never start a pool.
//
// Rules (they keep the simulation deterministic: a game gives the same result with 0, 1 or 16 threads):
// - A job never touches world.rng(), the World's entity list or anything another job may write. It reads shared data
//   and writes only its own slot (an index range of parallel_for, its own result).
// - Work that needs random numbers takes a seed drawn on the main thread and uses Chunk::rng(): the stream of a chunk
//   depends only on that seed and the chunk index, never on which thread runs it.
// - parallel_for splits [0, count) into chunks whose bounds depend only on count and grain. Results are merged in chunk
//   order (parallel_map_chunks, parallel_reduce), never in the order chunks happen to finish.
// - Results that must reach the World come back to the main thread: wait() for them, or post_main() a task that the
//   engine runs at the start of the next frame.
// - A job that throws does not take the process down: the exception is caught, logged with the job's name and
//   returned by wait() as an error. Jobs that depend on it do not run and report the same failure.
//
// Threads: hardware threads - 1 workers by default (the main thread is the other one), capped by kAutoCapDesktop /
// kAutoCapMobile. Idle workers sleep on a condition variable: no CPU is used while nothing is queued (a game in the
// background on a phone costs nothing). A worker's stack is the platform default for a secondary thread (512 KB on
// macOS and iOS, 1 MB on Windows, 8 MB on Linux): keep big buffers on the heap.
//
// Web: the browser build has no threads today (it is compiled without -pthread, and SharedArrayBuffer needs a page
// served cross-origin isolated). threads_supported() is false there, every setting resolves to 0 workers and jobs
// run on the main thread. A build with -pthread (__EMSCRIPTEN_PTHREADS__) gets real workers from the same code.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa::jobs {

inline constexpr int kMaxWorkers = 32;      // the most worker threads a setting may ask for
inline constexpr int kAutoCapDesktop = 8;   // "auto" on desktop: engine jobs are pieces of a 16 ms frame; past 8
                                            // workers the split costs more than it gains, and stacks cost memory
inline constexpr int kAutoCapMobile = 4;    // "auto" on Android/iOS: big.LITTLE chips count their slow cores too;
                                            // 4 leaves room for the OS, the GPU driver and audio threads
inline constexpr int kAutoCapWebThreads = 4;  // "auto" in a -pthread web build: each worker is a Web Worker
inline constexpr int kMaxLanes = kMaxWorkers + 2;  // profiler lanes: main, every worker, "other" threads

// ------------------------------------------------------------------------------------------------------------- settings
// The `runtime.jobThreads` project setting and the FA_JOB_THREADS environment variable.
struct Settings {
    enum class Mode { Auto, Count, Inline };
    Mode mode = Mode::Auto;
    int count = 0;  // Mode::Count: worker threads besides the main thread, 0..kMaxWorkers

    static Settings automatic() { return {}; }
    static Settings threads(int n) { return {Mode::Count, n}; }
    static Settings inline_jobs() { return {Mode::Inline, 0}; }
    std::string describe() const;  // "auto", "inline" or the count ("3")
    Json to_json() const;          // "auto", "inline" or the count as a number
    friend bool operator==(const Settings&, const Settings&) = default;
};

// "auto" | "inline" | an integer 0..kMaxWorkers. `where` names the value in the error ("factoria.json /runtime/jobThreads").
Result<Settings> parse_settings(const Json& value, std::string_view where);
// The same values as text (an environment variable): "auto", "inline" or digits.
Result<Settings> parse_settings_text(std::string_view text, std::string_view where);

bool threads_supported();               // false in a web build without pthreads
int hardware_threads();                 // std::thread::hardware_concurrency(), at least 1
int auto_worker_count(int hardwareThreads);  // what "auto" gives on this platform for that many hardware threads
int resolve_workers(const Settings& s);      // the worker count `s` gives here (0 in inline mode)

// ------------------------------------------------------------------------------------------------------------ the pool
// Reference counted: the first start() creates the workers and makes the calling thread the main thread; later calls
// only count (the pool keeps its first settings). The last stop() runs every queued job to the end, joins the workers
// and drops the main-thread tasks still queued. stop() from a job is refused (it would join its own thread).
void start(const Settings& s);
void stop();
bool running();
bool inline_mode();       // running in inline mode: every job runs at once on the thread that submits it
int worker_count();       // worker threads now (0 when stopped, inline, or with 0 workers)
Settings settings();      // what the running pool was started with (automatic() when stopped)
bool is_main_thread();    // the thread that started the pool (false while stopped)
bool is_worker_thread();  // one of the pool's workers

namespace detail {
struct JobState;
}

// A submitted job. Copyable; done() and wait() can be asked from any thread.
class Handle {
public:
    Handle() = default;
    bool valid() const { return state_ != nullptr; }
    bool done() const;  // finished: ran, failed or was skipped (true for an invalid handle)
    const std::string& name() const;

private:
    friend struct Access;
    explicit Handle(std::shared_ptr<detail::JobState> s) : state_(std::move(s)) {}
    std::shared_ptr<detail::JobState> state_;
};

// Queues `fn` to run once every handle in `deps` is done. `name` names the job in the profiler, logs and errors
// ("physics.islands"). When the pool is not running, or in inline mode, the job runs before submit returns.
Handle submit(std::string_view name, std::function<void()> fn, const std::vector<Handle>& deps = {});

// Blocks until the job is done and returns its error (a throw, a failed dependency). The waiting thread runs queued
// jobs meanwhile, so a wait inside a job, or with 0 workers, makes progress instead of deadlocking. A wait that can
// never end (what it waits for depends on the job that is waiting) returns an error instead of hanging.
Result<void> wait(const Handle& h);
Result<void> wait_all(const std::vector<Handle>& hs);  // waits for all; the first error in list order

// Jobs that are waited for together.
class Group {
public:
    Handle run(std::string_view name, std::function<void()> fn, const std::vector<Handle>& deps = {}) {
        handles_.push_back(submit(name, std::move(fn), deps));
        return handles_.back();
    }
    Result<void> wait() { return wait_all(handles_); }  // the first error in submit order
    bool done() const;
    const std::vector<Handle>& handles() const { return handles_; }

private:
    std::vector<Handle> handles_;
};

// ------------------------------------------------------------------------------------------------------- parallel_for
// One piece of [0, count): items [begin, end). Bounds and seed depend only on (count, grain, seed, index).
struct Chunk {
    std::size_t index = 0;
    std::size_t begin = 0, end = 0;
    std::uint64_t seed = 0;  // chunk_seed(seed of the call, index)
    std::size_t size() const { return end - begin; }
    Rng rng() const { return Rng(seed); }  // this chunk's own random stream (never world.rng() inside a job)
};

std::size_t chunk_count(std::size_t count, std::size_t grain);  // ceil(count / grain); grain 0 counts as 1
std::uint64_t chunk_seed(std::uint64_t seed, std::size_t index);  // splitmix64 of seed and index
Chunk chunk_at(std::size_t count, std::size_t grain, std::size_t index, std::uint64_t seed = 0);

// Runs fn once per chunk of `grain` items, on the workers and the calling thread, and returns when every chunk is done.
// Every chunk runs even when one throws; the error returned is the one of the lowest chunk index that failed (the same
// whatever the threads). fn must only write data of its own chunk. Nested calls (a parallel_for inside a job) work.
Result<void> parallel_for(std::string_view name, std::size_t count, std::size_t grain,
                          const std::function<void(const Chunk&)>& fn, std::uint64_t seed = 0);

// fn's result for every chunk, in chunk order. T must be default-constructible (and not bool: std::vector<bool> packs
// bits, so two chunks would write the same byte).
template <class T, class Fn>
Result<std::vector<T>> parallel_map_chunks(std::string_view name, std::size_t count, std::size_t grain, Fn&& fn,
                                           std::uint64_t seed = 0) {
    static_assert(!std::is_same_v<T, bool>, "use char or int: std::vector<bool> is not safe to write from many threads");
    std::vector<T> out(chunk_count(count, grain));
    auto r = parallel_for(name, count, grain, [&](const Chunk& c) { out[c.index] = fn(c); }, seed);
    if (!r) return r.error();
    return out;
}

// map(chunk) -> T for every chunk, then combine(acc, part) on the calling thread in chunk order, starting from init.
template <class T, class Map, class Combine>
Result<T> parallel_reduce(std::string_view name, std::size_t count, std::size_t grain, T init, Map&& map,
                          Combine&& combine, std::uint64_t seed = 0) {
    auto parts = parallel_map_chunks<T>(name, count, grain, std::forward<Map>(map), seed);
    if (!parts) return parts.error();
    T acc = std::move(init);
    for (T& p : parts.value()) acc = combine(std::move(acc), std::move(p));
    return acc;
}

// --------------------------------------------------------------------------------------------- the main thread's queue
// Queues fn for the main thread (from any thread). The engine runs the queue at the start of each frame, before the
// platform events, in the order tasks were posted; a task posted while the queue runs waits for the next frame.
void post_main(std::string_view name, std::function<void()> fn);
// Runs the tasks queued so far, in order; returns how many ran. Main thread only (another thread gets 0 and nothing
// runs). A task that throws is logged with its name; the rest still run.
int run_main_thread_tasks();
int main_tasks_queued();

// The engine calls this once at the end of each frame on the main thread. With 0 workers it runs the jobs nobody waited
// for (queued before this call), then it closes the frame's statistics (jobs.info, the profiler's thread lanes).
void end_frame();

// --------------------------------------------------------------------------------------------------- what jobs.info says
struct LaneInfo {
    std::string name;   // "main", "worker 1".., "other" (threads that are neither)
    int jobs = 0;       // jobs (parallel_for chunks count one each) this thread ran last frame
    double busyMs = 0;  // their time, rounded to 0.01 ms
    double busyPct = 0; // busyMs / the frame's wall time, rounded to 0.1
};

struct Info {
    bool running = false;
    std::string mode;  // "stopped", "inline" or "threads"
    int workers = 0;
    Settings settings;
    int hardwareThreads = 1;
    int autoWorkers = 0;            // what "auto" gives on this machine
    bool threadsSupported = true;
    int jobsLastFrame = 0;          // jobs that ran last frame (sum of the lanes)
    int submittedLastFrame = 0;
    int pending = 0;                // submitted and not finished now
    int mainTasksLastFrame = 0;
    int mainTasksQueued = 0;
    double frameMs = 0;             // wall time of the last frame (end_frame to end_frame), rounded to 0.01
    std::vector<LaneInfo> lanes;    // main first, then every worker; "other" only when such a thread ran jobs
};
Info info();
Json info_json(const Info& i);

// Profiler lanes: 0 = main, 1..worker_count() = the workers, lane_other() = any other thread.
int lane_count();  // 1 + worker_count()
int lane_other();  // kMaxLanes - 1
std::string lane_name(int lane);
int current_lane();  // the lane of the calling thread

}  // namespace fa::jobs
