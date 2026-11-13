// The start-up timeline of a run: when the window and graphics context existed, when the first frame was PRESENTED (a clear
// frame, before any game file is read), and when the first GAME frame was done. docs/PERFORMANCE.md, "Startup".
//
// A player opens its window, presents one frame, and only then reads the game (scenes, textures, audio, scripts); the time
// the player waits staring at an empty window is `firstPresentMs`, the time until the game is playable is `firstGameFrameMs`.
// This class only RECORDS: nothing a game does depends on it (no simulation reads a time from here), and the numbers are
// rounded in the report because they differ on every machine and every run. A run on a host with no window (headless,
// tests, `perf.measure`) has no present: its report says so (`firstPresentMs: null`) and gives CPU time instead.
//
// Times are milliseconds since the process started (the static initialization of fa_core, a few ms after the real start).
// A mark is recorded ONCE: the first call wins, later ones are ignored. Thread-safe.
#pragma once

#include <array>
#include <cstdint>
#include <mutex>
#include <vector>

#include "fa/core/json.h"

namespace fa {

class StartupTimeline {
public:
    enum class Mark : int {
        WindowReady,   // the window and its graphics context exist (the first frame callback)
        FirstPresent,  // the first frame was presented: a clear frame, the game's files not read yet
        InitBegin,     // Engine::init starts: the first game file is read after this
        InitEnd,       // Engine::init returned: scenes, scripts, textures of the first scene and the shaders are loaded
        WarmEnd,  // the pipelines the first scene draws with were made (after InitEnd, before the first game frame)
        FirstGameFrame,  // the first game frame (simulation + drawing) is done
        Count
    };
    static const char* name(Mark m);  // "windowReady", "firstPresent", ...

    // Records `m` now, with the process's CPU time and the number of files read from disk so far (fs::disk_reads). No-op when
    // `m` was recorded already.
    void mark(Mark m);
    bool has(Mark m) const;
    // Milliseconds since the process started / CPU milliseconds the process had used / disk reads, when `m` was recorded;
    // -1 / -1 / 0 when it was not.
    double wall_ms(Mark m) const;
    double cpu_ms(Mark m) const;
    std::uint64_t disk_reads(Mark m) const;
    // The marks in the order they were recorded (a test checks "firstPresent" came before "initBegin").
    std::vector<Mark> order() const;

    // CPU milliseconds from InitBegin to FirstGameFrame (what the game itself costs to start; the window and the first
    // present are not in it); -1 when either is missing. The number `perf.startup` budgets and the baselines compare.
    double startup_cpu_ms() const;

    // {firstPresentMs|null, firstGameFrameMs|null, windowReadyMs|null, initMs|null (InitBegin -> InitEnd, wall),
    //  warmupMs|null (InitEnd -> WarmEnd), startupCpuMs|null, diskReadsAtFirstPresent|null, diskReadsAtFirstGameFrame|null,
    //  order: ["windowReady", ...]}. Milliseconds are rounded to 0.1.
    Json to_json() const;

    // Milliseconds since the process started, now. (Not a mark.)
    static double process_ms_now();

private:
    struct Slot {
        bool set = false;
        double wallMs = -1, cpuMs = -1;
        std::uint64_t reads = 0;
    };
    mutable std::mutex mutex_;
    std::array<Slot, int(Mark::Count)> slots_{};
    std::vector<Mark> order_;
};

}  // namespace fa
