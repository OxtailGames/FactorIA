// The Audio panel's feed (audio.log) and the Profiler panel's numbers.
//
// Everything here is plain logic over a CommandRegistry: no ImGui, no Editor, no window. audio_panel.cpp only draws it, and tests
// call it directly against a headless Engine. The editor never reimplements what the command does; it runs it and keeps the
// plays it returns.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/profiler.h"

namespace fa::editor {

struct AudioPlay {
    std::uint64_t seq = 0, frame = 0;
    double time = 0;
    std::string path, bus, source;
    float volume = 1, pitch = 1, pan = 0;
    bool loop = false, music = false, ok = true;
};

struct AudioLogState {
    std::vector<AudioPlay> plays;  // oldest first, capped at kMax
    std::uint64_t after = 0;       // seq of the newest play seen or cleared: the next poll asks for newer ones
    std::uint64_t dropped = 0;     // plays the engine's own log (4096) forgot
    std::string filter;            // keep plays whose path contains this (case-insensitive)
    bool onlyFailed = false;       // keep only plays whose clip failed to load
    bool autoScroll = true;
    std::uint64_t scrolledTo = 0;  // seq of the newest play the panel already scrolled to
    std::string error;             // last poll error ("" = fine)
    static constexpr std::size_t kMax = 2000;
};
// audio.log {after}: appends the plays newer than state.after. Returns the number of new plays.
std::size_t poll_audio_log(const CommandRegistry& commands, AudioLogState& state);
// Forgets what is shown; later polls only add plays newer than the newest one seen.
void clear_audio_log(AudioLogState& state);
// Forgets everything including the position (a new project has a new log that starts at seq 1).
void reset_audio_log(AudioLogState& state);
bool audio_play_visible(const AudioPlay& play, const AudioLogState& state);

// What the Profiler panel shows (View > Profiler): the engine's per-frame profile (fa/core/profiler.h) smoothed over a few
// frames so the table does not flicker, a history of frame times for the graph, GPU and memory. Pure data: the panel draws it.
struct ProfilerView {
    static constexpr std::size_t kHistory = 240;  // frames in the graph
    static constexpr double kSmooth = 0.1;        // weight of the newest frame in the shown averages
    struct Row {
        std::string className, path;
        double ms = 0, calls = 0;  // smoothed per frame
    };
    std::vector<float> frameMs;  // oldest first, at most kHistory
    double smoothFrameMs = 0;
    std::array<double, kProfSystemCount> systemMs{};  // smoothed
    std::vector<Row> rows;                            // sorted by ms, slowest first
    // One row per thread of the job pool (fa/core/jobs.h): main first, then worker 1.., then "other" when a thread outside
    // the pool ran jobs. Smoothed like the rows; a lane the frame no longer has fades out.
    struct JobRow {
        std::string name;
        double ms = 0, count = 0;  // smoothed per frame
    };
    struct LaneRow {
        std::string name;
        double jobMs = 0, jobs = 0;  // smoothed per frame
        std::vector<JobRow> top;     // the lane's jobs by name, slowest first
    };
    std::vector<LaneRow> lanes;
    std::uint64_t frames = 0;  // frames added since reset
    bool gpuSupported = false;
    std::string gpuReason = "no GPU time yet";
    double gpuMs = 0;  // smoothed; valid when haveGpu
    bool haveGpu = false;
    // The input-to-present time of the engine's low-latency measurement (M78): smoothed; valid when haveLatency. The editor draws in
    // its own loop, which has none, so the row says why.
    double latencyMs = 0;
    bool haveLatency = false;
    std::string latencyDriver = "none", latencyReason = "no frame presented yet";
    ProfMemory memory;
    bool haveMemory = false;
    // The post-processing passes of the last sampled frame (fa::post_pass_times): CPU time to record each, GPU time where the
    // backend measures it (-1: none, `postGpuReason` says why, shown as "unavailable"). The effects folded into the `post` pass
    // are not timed one by one: that pass is their total.
    struct PostRow {
        std::string name;
        double cpuMs = 0, gpuMs = -1;
    };
    std::vector<PostRow> post;
    double postCpuMs = 0, postGpuMs = -1;
    std::string postGpuReason = "no frame sampled yet";
    // The frames the scripts took more than runtime.scriptFrameBudgetMs (ProfFrame::overBudget "scripts"): how many since
    // reset, the worst one and the limit it was measured against.
    std::uint64_t framesOverScriptBudget = 0;
    double worstOverScriptBudgetMs = 0, scriptBudgetMs = 0;

    void reset() { *this = ProfilerView{}; }
    void add_frame(const ProfFrame& f);
    void add_gpu_ms(double ms);
};

}  // namespace fa::editor
