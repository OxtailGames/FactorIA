// Profiler: CPU time per engine system and per script behaviour class, GPU time and memory, summarised for play.report,
// perf.profile and the editor's Profiler panel (docs/PERFORMANCE.md, "Finding what is slow").
//
// It only measures. Off by default: when off every probe is one branch on a flag and nothing is stored. Nothing it records
// reaches the simulation, game.state, replays or saved data (same rule as RenderStats::cpuMs): the numbers are wall-clock
// milliseconds and differ from run to run.
//
// One process-wide instance (Profiler::get()), single threaded like the engine loop. The engine brackets each frame with
// begin_frame/end_frame and each system with ProfSystemScope; the script system brackets each behaviour callback with
// ProfBehaviourScope. Time inside a nested scope is not counted twice: a behaviour callback that runs another behaviour's
// hook is charged only its own time.
#pragma once

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/json.h"

namespace fa {

// The engine systems, in the order of a frame. camelCase names are the keys of the reports.
enum class ProfSystem : int {
    Platform,            // store answers and events, the Back button
    Physics,             // physics.sync + physics.step
    ScriptsFixedUpdate,  // onFixedUpdate of every behaviour
    Animation,           // skeletal animators and their events
    ScriptsEvents,       // collision, trigger and world event handlers (onCollisionEnter, onEvent, world.on)
    Ui,                  // layout, focus, widget events
    ScriptsUpdate,       // timers, onUpdate of every behaviour, promise jobs
    Audio,
    ScriptsLateUpdate,   // onLateUpdate, then onStart/onEnable/onDisable of what changed
    Localization,        // string keys of new or edited entities
    Render,              // particles, sprite animators, recording the draw calls (the CPU side of drawing)
    EndOfFrame,          // deferred destroys, scene change, hot-reload poll
    Count
};
inline constexpr int kProfSystemCount = int(ProfSystem::Count);
const char* prof_system_name(ProfSystem s);  // "scriptsUpdate"...

// The bucket for script time that belongs to no behaviour: timers, world.on handlers, promise jobs, input.onBack.
inline constexpr const char* kProfOtherClass = "(timers, events and promises)";

struct ProfClassSample {
    std::string className;  // "Player"
    std::string path;       // "scripts/player.js" ("" for the bucket above)
    double ms = 0;          // this frame (own time, nested probes excluded)
    int calls = 0;          // callbacks run this frame (onUpdate, onFixedUpdate, collision handlers...)
};

struct ProfFrame {
    double totalMs = 0;  // begin_frame .. end_frame
    std::array<double, kProfSystemCount> systemMs{};
    std::vector<ProfClassSample> classes;  // sorted by ms, slowest first
};

// Memory the engine can name. Bytes; what the build cannot measure stays 0.
struct ProfMemory {
    std::uint64_t processBytes = 0;       // resident memory of the process now
    std::uint64_t peakProcessBytes = 0;   // peak resident memory so far
    std::uint64_t jsHeapBytes = 0;        // QuickJS heap
    std::uint64_t textureBytes = 0;       // textures the renderer holds
    std::uint64_t audioDecodedBytes = 0;  // decoded audio clips
    int entities = 0;
};

class Profiler {
public:
    static Profiler& get();
    static bool on() { return flag_; }
    void set_enabled(bool on);  // changing the state forgets what was recorded

    // Frame bracket (Engine::Impl::run_frame). end_frame() publishes last().
    void begin_frame();
    void end_frame();
    const ProfFrame& last() const { return last_; }
    std::uint64_t frames() const { return frames_; }  // frames published since the profiler was switched on

    // Probes (call only when on(); the scopes below check).
    void add_system(ProfSystem s, double ms) { cur_.systemMs[std::size_t(s)] += ms; }
    void add_behaviour(const std::string& className, const std::string& path, double ms);

    static double now_ms() {
        return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
    }
    double& child_ms() { return childMs_; }  // nesting: the time of an inner probe is subtracted from the outer one

private:
    static inline bool flag_ = false;
    ProfFrame cur_, last_;
    std::unordered_map<std::string, std::size_t> index_;  // path + '\n' + className -> slots_ index
    std::vector<ProfClassSample> slots_;
    double t0_ = 0;
    double childMs_ = 0;
    std::uint64_t frames_ = 0;
};

// Adds the time of its lifetime to a system. One branch when the profiler is off.
struct ProfSystemScope {
    explicit ProfSystemScope(ProfSystem s) : sys(s), t0(Profiler::on() ? Profiler::now_ms() : -1.0) {}
    ~ProfSystemScope() {
        if (t0 >= 0.0) Profiler::get().add_system(sys, Profiler::now_ms() - t0);
    }
    ProfSystemScope(const ProfSystemScope&) = delete;
    ProfSystemScope& operator=(const ProfSystemScope&) = delete;
    ProfSystem sys;
    double t0;
};

// Charges the time of its lifetime (one callback) to a behaviour class. One branch when the profiler is off.
struct ProfBehaviourScope {
    ProfBehaviourScope(const std::string& className, const std::string& path)
        : cls(className), file(path), active(Profiler::on()) {
        if (!active) return;
        Profiler& p = Profiler::get();
        savedChild = p.child_ms();
        p.child_ms() = 0;
        t0 = Profiler::now_ms();
    }
    ~ProfBehaviourScope() {
        if (!active) return;
        Profiler& p = Profiler::get();
        const double total = Profiler::now_ms() - t0;
        p.add_behaviour(cls, file, total - p.child_ms());
        p.child_ms() = savedChild + total;
    }
    ProfBehaviourScope(const ProfBehaviourScope&) = delete;
    ProfBehaviourScope& operator=(const ProfBehaviourScope&) = delete;
    const std::string& cls;
    const std::string& file;
    double t0 = 0, savedChild = 0;
    bool active;
};

// ----------------------------------------------------------------------------------------------------------------------
// Summary of many frames: the `profile` section of play.report and perf.profile. No engine, no GPU: tests feed it frames.
// ----------------------------------------------------------------------------------------------------------------------
class ProfileSummary {
public:
    static constexpr std::size_t kMaxWindow = 20000;  // p95 is over the last this many frames; avg and max are exact
    static constexpr std::size_t kMaxClasses = 30;    // behaviour classes listed (the slowest by average)

    void add_frame(const ProfFrame& f);
    void add_gpu_ms(double ms);  // one resolved GPU frame time (they arrive a few frames late)
    void set_gpu_status(bool supported, const std::string& reason);  // reason: why gpu times are null
    void add_memory(const ProfMemory& m);  // first call = start, last = end, max over calls = peak
    int frames() const { return frames_; }
    Json to_json() const;  // see docs/PERFORMANCE.md

private:
    struct Acc {
        std::uint64_t n = 0;
        double sum = 0, max = 0;
        std::vector<float> window;  // ring of the last kMaxWindow values
        std::size_t head = 0;
        void add(double v);
        double p95() const;
    };
    struct ClassAcc {
        std::string className, path;
        double sumMs = 0, maxMs = 0;
        std::uint64_t calls = 0;
    };
    int frames_ = 0;
    Acc frame_;
    std::array<Acc, kProfSystemCount> systems_;
    std::unordered_map<std::string, ClassAcc> classes_;
    Acc gpu_;
    bool gpuSupported_ = false;
    std::string gpuReason_ = "the GPU time was not measured";
    bool haveMemory_ = false;
    ProfMemory memStart_, memEnd_, memPeak_;
};

}  // namespace fa
