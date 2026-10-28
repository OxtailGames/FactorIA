#include "ai_runs.h"

#include <algorithm>
#include <filesystem>
#include <limits>
#include <utility>

namespace fa::editor {

// ---------------------------------------------------------------------------------------------------------------------
// AiRun

void AiRun::note_event(const ai::AgentEvent& ev, long long nowMs) {
    using T = ai::AgentEvent::Type;
    const std::string what = ai::describe_agent_event(ev);
    std::lock_guard<std::mutex> lock(mu);
    pending.push_back(ev);
    lastActivityMs = nowMs;
    if (!what.empty())
        activity = (ev.depth > 0 ? (ev.role.empty() ? std::string("worker") : ev.role) + " > " : std::string()) + what;
    if (ev.type == T::ToolStart) {
        tools.push_back(AiTool{ev.toolName, what, ev.depth, nowMs});
    } else if (ev.type == T::ToolEnd) {
        for (auto it = tools.rbegin(); it != tools.rend(); ++it) {
            if (it->name == ev.toolName && it->depth == ev.depth) {
                tools.erase(std::next(it).base());
                break;
            }
        }
    }
}

void AiRun::delegate_started(const ai::AiRunInfo& info, long long nowMs) {
    std::lock_guard<std::mutex> lock(mu);
    AiDelegate d;
    d.info = info;
    delegates.push_back(std::move(d));
    lastActivityMs = nowMs;
    activity = info.role + ": starting";
}

void AiRun::delegate_event(const ai::AiRunInfo& info, const ai::AgentEvent& ev, long long nowMs) {
    ai::AgentEvent shown = ev;
    shown.depth += 1;
    shown.runId = info.id;
    note_event(shown, nowMs);
}

void AiRun::delegate_process(const ai::AiRunInfo& info, long long pid) {
    std::lock_guard<std::mutex> lock(mu);
    procs.push_back(AiProc{pid, info.id, info.role});
}

void AiRun::delegate_ended(const ai::AiRunInfo& info, bool ok, const std::string& report, const std::string& error,
                           long long nowMs) {
    std::lock_guard<std::mutex> lock(mu);
    for (AiDelegate& d : delegates) {
        if (d.info.id != info.id) continue;
        d.ended = true;
        d.ok = ok;
        d.report = report;
        d.error = error;
    }
    std::erase_if(procs, [&](const AiProc& p) { return p.runId == info.id; });
    std::erase_if(tools, [](const AiTool& t) { return t.depth >= 1; });
    lastActivityMs = nowMs;
}

void AiRun::process_started(long long pid, const std::string& role) {
    std::lock_guard<std::mutex> lock(mu);
    procs.push_back(AiProc{pid, std::string(), role});
}

void AiRun::turn_ended(ai::SessionResult r) {
    {
        std::lock_guard<std::mutex> lock(mu);
        result = std::move(r);
        // The orchestrator's own process and tool calls are over. A delegated worker that still runs is an orphan: its
        // ai_run call will never return its result to anyone (Claude Code gave up on it, or its turn ended without
        // waiting). The run stays active until that worker ends.
        std::erase_if(procs, [](const AiProc& p) { return p.runId.empty(); });
        std::erase_if(tools, [](const AiTool& t) { return t.depth == 0; });
        bool orphans = false;
        for (AiDelegate& d : delegates) {
            if (d.ended) continue;
            d.orphan = true;
            orphans = true;
        }
        if (orphans) detached = true;  // before `running` goes false: active() never flickers
    }
    running = false;
}

AiRun::Drained AiRun::drain() {
    Drained out;
    std::lock_guard<std::mutex> lock(mu);
    out.events.swap(pending);
    out.result.swap(result);
    out.detached = detached.load();
    if (out.detached) {
        out.orphansDone = std::ranges::all_of(delegates, [](const AiDelegate& d) { return !d.orphan || d.ended; });
        if (out.orphansDone) {
            for (AiDelegate& d : delegates)
                if (d.orphan) out.finished.push_back(d);
        }
    }
    return out;
}

void AiRun::reset_live(long long nowMs) {
    {
        std::lock_guard<std::mutex> lock(mu);
        delegates.clear();
        procs.clear();
        tools.clear();
        activity.clear();
    }
    detachedOk = false;
    startMs = lastActivityMs = nowMs;
    snoozeUntil = 0;
    sampledAt = 0;
    cpu.clear();
    lastTree.clear();
    deadSince.clear();
}

void AiRun::clear_live() {
    std::lock_guard<std::mutex> lock(mu);
    delegates.clear();
    procs.clear();
    tools.clear();
}

std::string AiRun::activity_line() {
    std::lock_guard<std::mutex> lock(mu);
    return activity;
}

std::vector<AiProc> AiRun::processes() {
    std::lock_guard<std::mutex> lock(mu);
    return procs;
}

// ---------------------------------------------------------------------------------------------------------------------
// Which files a tool call changed

namespace {

std::string slashes(std::string s) {
    std::ranges::replace(s, '\\', '/');
    return s;
}

bool absolute_path(const std::string& s) { return !s.empty() && (s[0] == '/' || (s.size() > 2 && s[1] == ':' && s[2] == '/')); }

void add_path(std::set<std::string>& out, const Json& v, const std::string& projectDir) {
    if (v.is_string()) {
        const std::string rel = project_relative(v.get<std::string>(), projectDir);
        if (!rel.empty()) out.insert(rel);
    } else if (v.is_array()) {
        for (const Json& e : v) add_path(out, e, projectDir);
    }
}

}  // namespace

std::string project_relative(const std::string& path, const std::string& projectDir) {
    std::string p = slashes(path);
    if (p.empty()) return {};
    std::string root = slashes(projectDir);
    while (root.size() > 1 && root.back() == '/') root.pop_back();
    std::filesystem::path fp = std::filesystem::path(p).lexically_normal();
    if (absolute_path(p)) {
        if (root.empty()) return {};
        fp = fp.lexically_relative(std::filesystem::path(root).lexically_normal());
        if (fp.empty()) return {};
    }
    std::string out = slashes(fp.generic_string());
    while (out.rfind("./", 0) == 0) out.erase(0, 2);
    while (!out.empty() && out.back() == '/') out.pop_back();
    if (out.empty() || out == "." || out == ".." || out.rfind("../", 0) == 0) return {};
    return out;
}

std::vector<std::string> command_touched_files(const std::string& name, const Json& args, const Json& result, bool readOnly,
                                               bool editsScene, const std::string& openScene, const std::string& projectDir) {
    if (readOnly) return {};
    std::set<std::string> out;
    if (editsScene) add_path(out, Json(openScene), projectDir);
    static const char* const kPathKeys[] = {"path", "file", "from", "to", "dest", "destination", "output", "outPath", "savePath"};
    if (args.is_object()) {
        for (const char* k : kPathKeys)
            if (args.contains(k)) add_path(out, args[k], projectDir);
        for (const char* k : {"paths", "files"})
            if (args.contains(k)) add_path(out, args[k], projectDir);
        // scene.save with no path writes the open scene's file.
        if (name == "scene.save" && !args.contains("path")) add_path(out, Json(openScene), projectDir);
    } else if (name == "scene.save") {
        add_path(out, Json(openScene), projectDir);
    }
    if (result.is_object()) {
        for (const char* k : {"saved", "path", "file", "written", "output", "files"})
            if (result.contains(k)) add_path(out, result[k], projectDir);
    }
    return std::vector<std::string>(out.begin(), out.end());
}

std::vector<std::string> tool_touched_files(const std::string& toolName, const Json& input, const std::string& projectDir) {
    if (!input.is_object()) return {};
    const char* key = nullptr;
    if (toolName == "Write" || toolName == "Edit" || toolName == "MultiEdit") key = "file_path";
    else if (toolName == "NotebookEdit") key = "notebook_path";
    if (!key || !input.contains(key)) return {};
    std::set<std::string> out;
    add_path(out, input[key], projectDir);
    return std::vector<std::string>(out.begin(), out.end());
}

// ---------------------------------------------------------------------------------------------------------------------
// RunTouchTracker

bool RunTouchTracker::overlap(const Rec& a, const Rec& b) {
    constexpr long long kOpen = std::numeric_limits<long long>::max();
    const long long aEnd = a.endSeq ? a.endSeq : kOpen, bEnd = b.endSeq ? b.endSeq : kOpen;
    return a.beginSeq < bEnd && b.beginSeq < aEnd;
}

const RunTouchTracker::Rec* RunTouchTracker::latest(const std::string& run) const {
    for (auto it = recs_.rbegin(); it != recs_.rend(); ++it)
        if (it->name == run) return &*it;
    return nullptr;
}

RunTouchTracker::Rec* RunTouchTracker::latest(const std::string& run) {
    return const_cast<Rec*>(std::as_const(*this).latest(run));
}

void RunTouchTracker::begin(const std::string& run) {
    Rec r;
    r.name = run;
    r.beginSeq = ++seq_;
    recs_.push_back(std::move(r));
}

bool RunTouchTracker::active(const std::string& run) const {
    const Rec* r = latest(run);
    return r && r->endSeq == 0;
}

std::vector<FileConflict> RunTouchTracker::compare(const Rec& rec, const std::set<std::string>& files) {
    std::vector<FileConflict> out;
    for (const Rec& o : recs_) {
        if (&o == &rec || o.name == rec.name || !overlap(rec, o)) continue;
        for (const std::string& f : files) {
            if (!o.files.contains(f)) continue;
            const std::string& lo = std::min(rec.name, o.name);
            const std::string& hi = std::max(rec.name, o.name);
            if (!reported_.insert(lo + "\n" + hi + "\n" + f).second) continue;
            out.push_back(FileConflict{f, rec.name, o.name});
        }
    }
    return out;
}

std::vector<FileConflict> RunTouchTracker::touch(const std::string& run, const std::string& file) {
    Rec* r = latest(run);
    if (!r || file.empty() || !r->files.insert(file).second) return {};
    return compare(*r, {file});
}

std::vector<FileConflict> RunTouchTracker::end(const std::string& run, const std::vector<std::string>& changed) {
    std::vector<FileConflict> out;
    if (Rec* r = latest(run); r && r->endSeq == 0) {
        std::set<std::string> fresh;
        for (const std::string& f : changed)
            if (r->files.insert(f).second) fresh.insert(f);
        r->endSeq = ++seq_;
        // Files already in r->files were compared when touched; the checkpoint's own find is compared now.
        out = compare(*r, fresh);
    }
    // Drop what no running run can overlap any more.
    long long earliestActive = 0;
    for (const Rec& r : recs_)
        if (r.endSeq == 0 && (earliestActive == 0 || r.beginSeq < earliestActive)) earliestActive = r.beginSeq;
    if (earliestActive == 0) {
        recs_.clear();
        reported_.clear();
    } else {
        std::erase_if(recs_, [&](const Rec& r) { return r.endSeq != 0 && r.endSeq <= earliestActive; });
    }
    return out;
}

std::set<std::string> RunTouchTracker::touched(const std::string& run) const {
    const Rec* r = latest(run);
    return r ? r->files : std::set<std::string>();
}

bool RunTouchTracker::overlapped(const std::string& run) const { return !overlapping(run).empty(); }

std::vector<std::string> RunTouchTracker::overlapping(const std::string& run) const {
    std::vector<std::string> out;
    const Rec* r = latest(run);
    if (!r) return out;
    for (const Rec& o : recs_) {
        if (&o == r || o.name == run || !overlap(*r, o)) continue;
        if (std::ranges::find(out, o.name) == out.end()) out.push_back(o.name);
    }
    return out;
}

std::set<std::string> RunTouchTracker::touched_by_others(const std::string& run) const {
    std::set<std::string> out;
    const Rec* r = latest(run);
    if (!r) return out;
    for (const Rec& o : recs_)
        if (&o != r && o.name != run && overlap(*r, o)) out.insert(o.files.begin(), o.files.end());
    return out;
}

int RunTouchTracker::active_count() const {
    int n = 0;
    for (const Rec& r : recs_) n += r.endSeq == 0 ? 1 : 0;
    return n;
}

void RunTouchTracker::clear() {
    recs_.clear();
    reported_.clear();
    seq_ = 0;
}

std::vector<ConflictNote> group_conflicts(const std::vector<FileConflict>& conflicts) {
    std::vector<ConflictNote> out;
    for (const FileConflict& c : conflicts) {
        auto it = std::ranges::find_if(out, [&](const ConflictNote& n) { return n.run == c.run && n.other == c.other; });
        if (it == out.end()) {
            out.push_back(ConflictNote{c.run, c.other, {}});
            it = std::prev(out.end());
        }
        it->files.push_back(c.file);
    }
    return out;
}

std::string conflict_text(const std::string& otherTitle, bool otherRunning, const std::vector<std::string>& files) {
    std::string list;
    constexpr std::size_t kShown = 4;
    for (std::size_t i = 0; i < files.size() && i < kShown; ++i) list += (i ? ", " : "") + files[i];
    if (files.size() > kShown) list += " and " + std::to_string(files.size() - kShown) + " more";
    return "Chat \"" + (otherTitle.empty() ? std::string("New chat") : otherTitle) + "\" " +
           (otherRunning ? "is running at the same time and also changed " : "ran at the same time and also changed ") + list +
           ". Both runs' edits are in the file now; check the result, and Revert keeps the other chat's changes unless you ask otherwise.";
}

std::vector<std::string> attribute_files(const std::vector<std::string>& changed, const std::set<std::string>& own,
                                         const std::set<std::string>& others) {
    std::vector<std::string> out;
    for (const std::string& f : changed)
        if (own.contains(f) || !others.contains(f)) out.push_back(f);
    return out;
}

// ---------------------------------------------------------------------------------------------------------------------
// Reverting one run

RevertPlan plan_revert(const std::set<std::string>& own, const std::string& scene, bool truncated,
                       const std::vector<RunRecord>& others) {
    RevertPlan p;
    if (others.empty()) return p;  // nobody else involved: the whole checkpoint, as ever
    for (const RunRecord& o : others)
        if (o.running && std::ranges::find(p.running, o.chat) == p.running.end()) p.running.push_back(o.chat);
    auto add_shared = [&](const std::string& file, const std::string& chat) {
        auto it = std::ranges::find_if(p.shared, [&](const SharedFile& s) { return s.file == file; });
        if (it == p.shared.end()) {
            p.shared.push_back(SharedFile{file, {}});
            it = std::prev(p.shared.end());
        }
        if (std::ranges::find(it->chats, chat) == it->chats.end()) it->chats.push_back(chat);
    };
    if (truncated) {
        // The run's file list was cut, so it cannot say what to restore: the whole checkpoint goes back, and every file
        // another chat's run changed may be among them.
        for (const RunRecord& o : others)
            for (const std::string& f : o.files) add_shared(f, o.chat);
    } else {
        p.whole = false;
        p.files.assign(own.begin(), own.end());
        for (const std::string& f : p.files)
            for (const RunRecord& o : others)
                if (o.files.contains(f)) add_shared(f, o.chat);
    }
    std::ranges::sort(p.shared, {}, &SharedFile::file);
    if (!scene.empty())
        for (const RunRecord& o : others)
            if (o.files.contains(scene)) p.sceneShared = true;
    return p;
}

}  // namespace fa::editor
