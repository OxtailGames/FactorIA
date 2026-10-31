// Several AI chats can run at the same time in the editor (up to limits.maxConcurrentRuns of ai.json, default 3). This file
// holds what is per run and has nothing to do with a window, so the tests in tools/editor/tests exercise it directly:
//
//   AiRun            one chat's run: its agent thread, cancel flag, MCP endpoint, the events waiting for the main thread, its
//                    delegated workers, the liveness the status line and the watchdog read.
//   RunTouchTracker  which project files each running chat changed, so two chats that change the same file are warned.
//   plan_revert      what Revert of one run does when other chats' runs changed files too (never silently clobbering them).
//   command_touched_files / tool_touched_files / project_relative: what a tool call changed, as project-relative paths.
//
// THREADING: an AiRun is shared between the main thread (draws it, drains it) and its agent thread and the MCP connection
// threads (they note events). Every member under `mu` is guarded by it; the atomics are free. The members marked "main thread"
// are touched by the UI thread only.
#pragma once

#include <atomic>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <string>
#include <thread>
#include <vector>

#include "fa/ai/activity.h"
#include "fa/ai/commands.h"
#include "fa/ai/session.h"
#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/mcp/http_server.h"

namespace fa::editor {

// A worker the orchestrator delegated with ai.run (its tool call runs on an MCP connection thread).
struct AiDelegate {
    ai::AiRunInfo info;
    bool ended = false;
    bool orphan = false;  // still running when the orchestrator's turn ended: nobody will hand it its result
    bool ok = false;
    std::string report, error;
};

struct AiTool {  // a tool call started and not ended
    std::string name, text;  // text: describe_agent_event() ("running Bash (cmake --build)")
    int depth = 0;
    long long startMs = 0;
};

struct AiProc {  // a CLI agent process of the run
    long long pid = 0;
    std::string runId;  // "" = the orchestrator's own process, else the ai.run it belongs to
    std::string label;  // role
};

class AiRun {
public:
    explicit AiRun(std::string chat) : chatId(std::move(chat)) {}
    AiRun(const AiRun&) = delete;
    AiRun& operator=(const AiRun&) = delete;

    const std::string chatId;  // the chat this run works for (a chat has at most one run)

    // ---- control (free to read from any thread)
    std::atomic<bool> cancel{false};     // Stop: the agent, its workers and its queued commands end
    std::atomic<bool> running{false};    // the agent thread is going
    std::atomic<bool> detached{false};   // the orchestrator's turn ended while a delegated worker still runs
    std::atomic<long long> startMs{0}, lastActivityMs{0};  // steady-clock milliseconds
    // True from the run's start to its end, whatever the agent thread does in between.
    bool active() const { return running.load() || detached.load(); }
    // Sets `cancel` and records why (a cause key of ai::cancel_cause_text(): user_stop, watchdog_process_gone...). The first
    // cause stays: a run that was stopped and then torn down with the project is still "stopped by the user".
    void request_cancel(const char* cause);
    std::string cancel_cause();  // "" until request_cancel() was called

    // ---- owned by the main thread
    std::thread thread;
    McpHttpServer mcp;           // this run's endpoint for a CLI agent (Claude Code): it serves `proxy`
    std::string provider;        // the orchestrator's provider (the plan limits belong to it)
    std::string role;            // the role this run plays ("" = orchestrator); a review runs artCritic or reviewer
    std::string extraSystem;     // extra system prompt of the run (a reviewer's persona)
    std::string checkpointId;    // the project checkpoint taken before the run ("" = none)
    i64 startedAt = 0;           // epoch seconds
    bool sceneEdited = false;    // a scene-editing command ran for this run
    bool detachedOk = false;     // the orchestrator's turn ended well (so a continuation makes sense)
    double snoozeUntil = 0;      // the stuck warning stays quiet until then (seconds, the editor's clock)
    double sampledAt = 0;        // seconds of the last watchdog sample
    ai::CpuSampler cpu;          // CPU use of the run's processes
    std::vector<ProcessEntry> lastTree;
    std::map<long long, double> deadSince;  // pid -> seconds when the watchdog first found it gone

    // ---- under mu
    std::mutex mu;
    std::vector<ai::AgentEvent> pending;       // events for the main thread (the chat's transcript)
    std::optional<ai::SessionResult> result;   // the orchestrator's turn ended with this
    std::vector<AiDelegate> delegates;
    std::vector<AiTool> tools;
    std::vector<AiProc> procs;
    std::string cancelCause_;                  // why cancel was set (request_cancel)
    std::string activity;                      // the latest thing the agent did ("worker > running Bash (cmake)")
    std::shared_ptr<CommandRegistry> proxy;    // what the agent's tool calls run on (the MCP endpoint reads it)

    // ---- called from the agent thread, the MCP connection threads and the main thread
    // One agent event: queued for the main thread, and the liveness the watchdog and the status line read.
    void note_event(const ai::AgentEvent& ev, long long nowMs);
    // ai.run callbacks (a delegated worker).
    void delegate_started(const ai::AiRunInfo& info, long long nowMs);
    void delegate_event(const ai::AiRunInfo& info, const ai::AgentEvent& ev, long long nowMs);  // shown one level in
    void delegate_process(const ai::AiRunInfo& info, long long pid);
    void delegate_ended(const ai::AiRunInfo& info, bool ok, const std::string& report, const std::string& error, long long nowMs);
    void process_started(long long pid, const std::string& role);  // the orchestrator's own CLI process
    // The agent thread's session returned `r`. A delegate that still runs is an orphan: its ai_run call will never return its
    // result to anyone, so the run stays active (`detached`) until that worker ends. `detached` is set before `running`
    // drops, so active() never flickers.
    void turn_ended(ai::SessionResult r);

    // Everything the main thread takes in one go (one lock: a worker's last events and its end are seen together).
    struct Drained {
        std::vector<ai::AgentEvent> events;
        std::optional<ai::SessionResult> result;
        bool detached = false;
        bool orphansDone = false;              // detached and every orphaned worker ended
        std::vector<AiDelegate> finished;      // those workers, when orphansDone
    };
    Drained drain();
    // A fresh run starts with no liveness left over (the status line's clock starts at `nowMs`).
    void reset_live(long long nowMs);
    // The run ended: no delegate, process or tool call is left.
    void clear_live();
    std::string activity_line();
    std::vector<AiProc> processes();
};

// The watchdog's and "Check activity"'s verdict on one CLI agent process: gone only when process_tree() found nothing, the OS
// itself says the pid does not run (process_alive: the process list can miss a process that lives) and the run produced no event
// for `graceSeconds` (a run that still reports is not dead, whatever the list says). `alive` is process_alive; tests pass fakes.
inline constexpr double kProcessGoneGraceSeconds = 10;
bool agent_process_gone(long long pid, bool treeEmpty, double idleSeconds, bool (*alive)(long long) = &process_alive);

// ---------------------------------------------------------------------------------------------------------------------
// Which files each running chat changed.

// A path as the tracker compares it: project-relative, forward slashes, no "./". "" for a path outside the project
// (absolute elsewhere, or with "..") or an empty one. `projectDir` makes an absolute path inside the project relative.
std::string project_relative(const std::string& path, const std::string& projectDir);

// What a command (`name`, e.g. "fs.write"; `args` as the model passed them; `result` its reply) changed, as project-relative
// files. `readOnly` commands change nothing. A command that edits the open scene changes `openScene` (the scene file it is
// saved to). Looks at the path-like arguments (path, file, from, to, ...), the `saved` file a scene import reports, and the
// `paths` / `files` lists.
std::vector<std::string> command_touched_files(const std::string& name, const Json& args, const Json& result, bool readOnly,
                                               bool editsScene, const std::string& openScene, const std::string& projectDir);
// What a tool call of a CLI agent's own tools changed (Claude Code's Write / Edit / MultiEdit / NotebookEdit). Calls of the
// editor's commands (mcp__factoria__fs_write...) are not seen here: they arrive as commands. Bash is not seen at all; the
// checkpoint diff at the end of the run covers it.
std::vector<std::string> tool_touched_files(const std::string& toolName, const Json& input, const std::string& projectDir);

// One file two runs changed.
struct FileConflict {
    std::string file;
    std::string run;    // the run that just changed it (its chat id)
    std::string other;  // the other run that also changed it
};

class RunTouchTracker {
public:
    // A run starts (a chat has one run at a time; a chat's later run is a new record, the earlier one stays while it can
    // still overlap a running one).
    void begin(const std::string& run);
    bool active(const std::string& run) const;
    // `run` changed `file`. The conflicts that creates with runs that overlapped it (running now, or ended after this run
    // began) and changed the same file; each (pair, file) is reported once.
    std::vector<FileConflict> touch(const std::string& run, const std::string& file);
    // The run ended; `changed` are the files it changed according to its checkpoint (after attribute_files). The conflicts
    // with the files other overlapping runs changed, not reported before. Read touched() / touched_by_others() BEFORE this:
    // the records of ended runs are dropped as soon as no running run can overlap them.
    std::vector<FileConflict> end(const std::string& run, const std::vector<std::string>& changed);
    std::set<std::string> touched(const std::string& run) const;
    // True when another run was active at some moment while `run` was.
    bool overlapped(const std::string& run) const;
    // The files the runs that overlapped `run` changed (without `run`'s own).
    std::set<std::string> touched_by_others(const std::string& run) const;
    // The runs that overlapped `run`.
    std::vector<std::string> overlapping(const std::string& run) const;
    int active_count() const;
    void clear();

private:
    struct Rec {
        std::string name;
        std::set<std::string> files;
        long long beginSeq = 0, endSeq = 0;  // endSeq 0 = still running
    };
    static bool overlap(const Rec& a, const Rec& b);
    const Rec* latest(const std::string& run) const;
    Rec* latest(const std::string& run);
    std::vector<FileConflict> compare(const Rec& rec, const std::set<std::string>& files);
    std::vector<Rec> recs_;
    std::set<std::string> reported_;  // "a\nb\nfile" with a < b
    long long seq_ = 0;
};

// Conflicts of one run with one other, to tell each chat once ("chat 'B' also changed a, b and c").
struct ConflictNote {
    std::string run, other;
    std::vector<std::string> files;
};
std::vector<ConflictNote> group_conflicts(const std::vector<FileConflict>& conflicts);
// "Chat \"B\" is running at the same time and also changed scenes/menu.scene.json" (up to 4 files, then "and N more").
std::string conflict_text(const std::string& otherTitle, bool otherRunning, const std::vector<std::string>& files);

// The files a finished run gets credited with when other runs overlapped it: those it touched itself, plus those nobody else
// touched (a Bash command wrote them; no tool call names them). Files only another run changed are left out.
std::vector<std::string> attribute_files(const std::vector<std::string>& changed, const std::set<std::string>& own,
                                         const std::set<std::string>& others);

// ---------------------------------------------------------------------------------------------------------------------
// Reverting one run.

// What another chat's run changed (a Run item of an open chat, or what a still running chat touched so far).
struct RunRecord {
    std::string chat;             // the chat's title
    std::set<std::string> files;  // project-relative; includes the open scene's file when the run edited the scene
    bool running = false;
};

struct SharedFile {
    std::string file;
    std::vector<std::string> chats;  // the other chats that also changed it
};

struct RevertPlan {
    // No other chat's run is involved: the whole checkpoint is restored (every file that differs, as always).
    bool whole = true;
    // Otherwise only these files go back: the files of the run (and of the later runs of the same chat, which are taken back too).
    std::vector<std::string> files;
    std::vector<SharedFile> shared;   // among `files`, those another chat's run also changed
    bool sceneShared = false;         // the run edited the open scene and another chat's run did too
    std::vector<std::string> running; // other chats whose run is still going
};

// `own`: what the run being reverted changed (and its chat's later runs). `scene`: the open scene's file when the run changed
// the scene ("" when it did not). `truncated`: the run's file list was cut at kMaxListedFiles, so it cannot be used as a scope.
RevertPlan plan_revert(const std::set<std::string>& own, const std::string& scene, bool truncated,
                       const std::vector<RunRecord>& others);

}  // namespace fa::editor
