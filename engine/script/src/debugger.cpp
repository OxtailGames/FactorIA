// ScriptDebugger: the public API (breakpoints, filters, requests from any thread) and the bookkeeping shared with the
// ScriptSystem (module table, error columns, console output). The hooks, stopping and inspecting are in
// debugger_runtime.cpp.
#include <algorithm>
#include <format>

#include "debugger_internal.h"
#include "fa/core/fs.h"

namespace fa {

ScriptDebugger::Impl::Impl(DebugClient& c, ScriptInstrumenter i, std::string dir)
    : client(c), instrumenter(std::move(i)), projectDir(std::move(dir)) {
    modules.resize(1);
}

ScriptDebugger::Impl::~Impl() = default;

ScriptDebugger::ScriptDebugger(DebugClient& client, ScriptInstrumenter instrumenter, std::string projectDir)
    : impl_(std::make_unique<Impl>(client, std::move(instrumenter), std::move(projectDir))) {}
ScriptDebugger::~ScriptDebugger() = default;

DebugClient& ScriptDebugger::client() { return impl_->client; }
const ScriptInstrumenter& ScriptDebugger::instrumenter() const { return impl_->instrumenter; }

void ScriptDebugger::set_exception_filters(bool all, bool uncaught) {
    impl_->excAll = all;
    impl_->excUncaught = uncaught;
}
void ScriptDebugger::request_pause() { impl_->pauseReq = true; }
void ScriptDebugger::request_terminate() { impl_->terminating = true; }
void ScriptDebugger::set_stop_on_entry(bool stop) { impl_->entryPending = stop; }

std::vector<DebugBreakpointState> ScriptDebugger::set_breakpoints(const std::string& file,
                                                                  const std::vector<DebugBreakpoint>& breakpoints) {
    return impl_->set_breakpoints(file, breakpoints);
}

// ---------------------------------------------------------------------------------------------------------------------
// Breakpoints
// ---------------------------------------------------------------------------------------------------------------------
Result<InstrumentedScript> ScriptDebugger::Impl::instrument(const std::string& file, std::string_view source, int moduleId) {
    if (!instrumenter) return Error{"no script instrumenter", "Pass a ScriptInstrumenter to the ScriptDebugger."};
    std::lock_guard<std::mutex> lock(instrumenterMutex);
    return instrumenter(file, source, moduleId);
}

namespace {

int resolve_line(const std::vector<int>& lines, int requested) {
    auto it = std::lower_bound(lines.begin(), lines.end(), requested);
    return it == lines.end() ? 0 : *it;
}

}  // namespace

std::vector<DebugBreakpointState> ScriptDebugger::Impl::set_breakpoints(const std::string& file,
                                                                        const std::vector<DebugBreakpoint>& wanted) {
    std::shared_ptr<const ScriptDebugInfo> info;
    {
        std::lock_guard<std::mutex> lock(mutex);
        auto it = fileInfo.find(file);
        if (it != fileInfo.end()) info = it->second;
    }
    std::string problem;
    if (!info) {  // not loaded (yet): instrument the file on disk just to learn its breakable lines
        std::string path = projectDir.empty() ? file : projectDir + "/" + file;
        auto text = fs::read_text(path);
        if (!text) {
            problem = "cannot read '" + file + "' to find its breakable lines: " + text.error().message;
        } else {
            auto r = instrument(file, *text, -1);
            if (r.ok()) info = std::make_shared<const ScriptDebugInfo>(std::move(r.value().info));
            else problem = file + " does not parse: " + r.error().message;
        }
    }
    std::vector<int> lines = info ? info->breakable_lines() : std::vector<int>();

    std::vector<DebugBreakpointState> states;
    std::lock_guard<std::mutex> lock(mutex);
    std::vector<DebugBpRec> old = std::move(breakpoints[file]);
    std::vector<DebugBpRec> fresh;
    for (const DebugBreakpoint& bp : wanted) {
        DebugBpRec rec;
        rec.requestedLine = bp.line;
        rec.condition = bp.condition;
        rec.hitCondition = bp.hitCondition;
        rec.logMessage = bp.logMessage;
        for (const DebugBpRec& o : old)  // the same breakpoint again keeps its id (and its hit count)
            if (o.requestedLine == rec.requestedLine && o.condition == rec.condition && o.hitCondition == rec.hitCondition &&
                o.logMessage == rec.logMessage && std::none_of(fresh.begin(), fresh.end(), [&](const DebugBpRec& f) { return f.id == o.id; })) {
                rec.id = o.id;
                break;
            }
        if (rec.id == 0) rec.id = nextBpId++;
        DebugBreakpointState st;
        st.id = rec.id;
        if (info) {
            rec.line = resolve_line(lines, bp.line);
            st.verified = rec.line > 0;
            st.line = rec.line > 0 ? rec.line : bp.line;
            if (!st.verified)
                st.message = std::format("no code at or after line {} of {}: the last statement is on line {}", bp.line, file,
                                         lines.empty() ? 0 : lines.back());
        } else {
            st.line = bp.line;
            st.message = problem;
        }
        fresh.push_back(rec);
        states.push_back(std::move(st));
    }
    breakpoints[file] = std::move(fresh);
    bpGen.fetch_add(1);
    return states;
}

void ScriptDebugger::Impl::refresh(DebugModule& m) {
    std::lock_guard<std::mutex> lock(mutex);
    m.gen = bpGen.load();
    m.bps.clear();
    m.stmtBp.assign(m.stmtLine.size(), 0);
    auto it = breakpoints.find(m.file);
    if (it == breakpoints.end()) return;
    for (const DebugBpRec& bp : it->second) {
        if (bp.line <= 0) continue;
        m.bps.push_back(bp);
        for (size_t k = 0; k < m.stmtLine.size(); ++k)
            if (m.stmtLine[k] == bp.line) m.stmtBp[k] = 1;
    }
}

// ---------------------------------------------------------------------------------------------------------------------
// Module table
// ---------------------------------------------------------------------------------------------------------------------
int ScriptDebugger::Impl::register_module(const std::string& file, const std::string& name) {
    int mid = nextMid++;
    if (static_cast<size_t>(mid) >= modules.size()) modules.resize(static_cast<size_t>(mid) + 1);
    modules[static_cast<size_t>(mid)].file = file;
    modules[static_cast<size_t>(mid)].name = name;
    nameToMid[name] = mid;
    return mid;
}

void ScriptDebugger::Impl::module_loaded(int mid, std::shared_ptr<const ScriptDebugInfo> info) {
    DebugModule& m = modules[static_cast<size_t>(mid)];
    m.info = info;
    m.stmtLine.clear();
    for (const auto& s : info->statements) m.stmtLine.push_back(s.line);
    m.gen = 0;
    std::vector<int> lines = info->breakable_lines();
    std::lock_guard<std::mutex> lock(mutex);
    fileInfo[m.file] = info;
    auto it = breakpoints.find(m.file);  // the new version may have moved the lines
    if (it != breakpoints.end())
        for (DebugBpRec& bp : it->second) bp.line = resolve_line(lines, bp.requestedLine);
    bpGen.fetch_add(1);
}

// ---------------------------------------------------------------------------------------------------------------------
// Error columns, console output
// ---------------------------------------------------------------------------------------------------------------------
void ScriptDebugger::Impl::map_location(const std::string& file, int line, int& column) const {
    auto it = nameToMid.find(file);
    if (it == nameToMid.end() || column <= 0) return;
    const DebugModule& m = modules[static_cast<size_t>(it->second)];
    if (m.info) column = m.info->original_column(line, column);
}

std::string ScriptDebugger::Impl::map_stack(const std::string& text) const {
    if (nameToMid.empty() || text.empty()) return text;
    std::string out;
    size_t pos = 0;
    while (pos < text.size()) {
        size_t eol = text.find('\n', pos);
        std::string ln = text.substr(pos, eol == std::string::npos ? std::string::npos : eol - pos);
        pos = eol == std::string::npos ? text.size() : eol + 1;
        // "    at fn (file:line:col)" or "    at file:line:col"
        size_t end = ln.size();
        if (end && ln[end - 1] == ')') --end;
        size_t c2 = end ? ln.rfind(':', end - 1) : std::string::npos;
        size_t c1 = (c2 != std::string::npos && c2 > 0) ? ln.rfind(':', c2 - 1) : std::string::npos;
        if (c1 != std::string::npos) {
            size_t lp = ln.rfind('(', c1);
            size_t start = lp != std::string::npos ? lp + 1 : (ln.find("at ") != std::string::npos ? ln.find("at ") + 3 : 0);
            if (start <= c1) {
                std::string name = ln.substr(start, c1 - start);
                int l = std::atoi(ln.c_str() + c1 + 1), col = std::atoi(ln.c_str() + c2 + 1);
                int mapped = col;
                map_location(name, l, mapped);
                if (mapped != col) ln = ln.substr(0, c2 + 1) + std::to_string(mapped) + ln.substr(end);
            }
        }
        out += ln;
        if (eol != std::string::npos) out += '\n';
    }
    return out;
}

void ScriptDebugger::Impl::frame_position(const DebugFrameRec& r, std::string& file, std::string& name, int& line,
                                          int& column) const {
    file.clear();
    name = r.isModule ? "(module)" : "(anonymous)";
    line = 0;
    column = 0;
    if (r.mid <= 0 || static_cast<size_t>(r.mid) >= modules.size()) return;
    const DebugModule& m = modules[static_cast<size_t>(r.mid)];
    file = m.file;
    if (!m.info) return;
    if (!r.isModule && r.fid >= 0 && static_cast<size_t>(r.fid) < m.info->functions.size()) {
        const auto& f = m.info->functions[static_cast<size_t>(r.fid)];
        name = f.name;
        line = f.line;
        column = f.column;
    } else if (r.isModule) {
        line = 1;
        column = 1;
    }
    if (r.stmt >= 0 && static_cast<size_t>(r.stmt) < m.info->statements.size()) {
        line = m.info->statements[static_cast<size_t>(r.stmt)].line;
        column = m.info->statements[static_cast<size_t>(r.stmt)].column;
    }
}

bool ScriptDebugger::Impl::top_position(std::string& file, int& line) const {
    if (stack.empty()) return false;
    const DebugFrameRec* r = debug_frame_of(stack.back());
    if (!r) return false;
    std::string name;
    int col = 0;
    frame_position(*r, file, name, line, col);
    return !file.empty();
}

void ScriptDebugger::Impl::on_console(int level, const std::string& text) {
    std::string file;
    int line = 0;
    if (!top_position(file, line)) {
        file.clear();
        line = 0;
    }
    client.output(level >= 3 ? "stderr" : "stdout", text, file, line);
}

void ScriptDebugger::Impl::on_error(const ScriptError& e) {
    std::string file = e.file;
    int line = e.line;
    if (file.empty() || file[0] == '<' || line <= 0) {
        file.clear();
        line = 0;
        top_position(file, line);
    }
    client.output("stderr", e.to_string(), file, line);
}

void ScriptDebugger::Impl::frame_start() {
    if (terminating.load() && !quitSent) {
        quitSent = true;
        if (sys && sys->host) sys->host->request_quit();
    }
    if (sys && sys->owner) client.poll(*sys->owner);
}

}  // namespace fa
