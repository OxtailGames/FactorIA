#include "js_scan.h"

#include <cctype>
#include <system_error>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::tooling_detail {
namespace stdfs = std::filesystem;

bool js_ident_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$'; }

void JsScan::blanks() {
    while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
}

bool JsScan::word(std::string_view w) {
    if (s.compare(i, w.size(), w) != 0) return false;
    i += w.size();
    return true;
}

bool JsScan::quoted(std::string& out) {
    if (i >= s.size() || (s[i] != '"' && s[i] != '\'')) return false;
    const char q = s[i];
    const std::size_t close = s.find(q, i + 1);
    if (close == std::string::npos || s.find('\n', i + 1) < close) return false;
    out = s.substr(i + 1, close - i - 1);
    i = close + 1;
    return true;
}

SourcePos source_pos(const std::string& text, std::size_t offset) {
    SourcePos p;
    if (offset > text.size()) offset = text.size();
    std::size_t lineStart = 0;
    for (std::size_t k = 0; k < offset; ++k)
        if (text[k] == '\n') {
            ++p.line;
            lineStart = k + 1;
        }
    p.column = static_cast<int>(offset - lineStart) + 1;
    return p;
}

std::string tool_module_name(const std::string& text) {
    const std::size_t def = text.find("export default");
    if (def == std::string::npos) return {};
    JsScan sc{text, def};
    for (std::size_t at = text.find("name", def); at != std::string::npos; at = text.find("name", at + 4)) {
        if (at > 0 && js_ident_char(text[at - 1])) continue;
        sc.i = at + 4;
        sc.blanks();
        if (!sc.word(":")) continue;
        sc.blanks();
        std::string name;
        if (!sc.quoted(name)) continue;
        for (char& c : name)
            if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_')) c = '_';
        return name;
    }
    return {};
}

std::vector<ProjectCall> literal_project_calls(const std::string& text) {
    std::vector<ProjectCall> out;
    for (std::size_t at = text.find("fa"); at != std::string::npos; at = text.find("fa", at + 2)) {
        if (at > 0 && js_ident_char(text[at - 1])) continue;
        JsScan sc{text, at + 2};
        sc.blanks();
        if (!sc.word(".")) continue;
        sc.blanks();
        if (!sc.word("call")) continue;
        sc.blanks();
        if (!sc.word("(")) continue;
        sc.blanks();
        const std::size_t quoteAt = sc.i;
        std::string target;
        if (!sc.quoted(target) || target.rfind("project.", 0) != 0) continue;
        std::string name = target.substr(8);
        bool seen = false;
        for (const ProjectCall& c : out) seen = seen || c.name == name;
        if (seen) continue;
        const SourcePos pos = source_pos(text, quoteAt);
        out.push_back({std::move(name), pos.line, pos.column});
    }
    return out;
}

std::map<std::string, std::string> tool_commands(const stdfs::path& projectDir) {
    std::map<std::string, std::string> toolFile;
    const stdfs::path toolsDir = fs::os_path(projectDir / "tools");
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(toolsDir, stdfs::directory_options::skip_permission_denied, ec), end;
         !ec && it != end; it.increment(ec)) {
        std::error_code fec;
        if (!it->is_regular_file(fec) || to_lower(fs::path_to_utf8(it->path().extension())) != ".js") continue;
        const auto size = it->file_size(fec);
        if (fec || size > kMaxScanScriptBytes) continue;
        const auto text = read_file(it->path());
        if (!text) continue;
        const std::string name = tool_module_name(*text);
        if (name.empty()) continue;
        toolFile.emplace(name, "tools/" + fs::path_to_utf8(it->path().lexically_relative(toolsDir)));
    }
    return toolFile;
}

std::string tool_only_call_message(const std::string& scriptFile, const ProjectCall& call, const std::string& toolFile) {
    return scriptFile + ":" + std::to_string(call.line) + " calls project." + call.name +
           ", the command of " + toolFile +
           ". tools/ is left out of the export, so in the shipped game that call fails (there is no such command). Tools are for "
           "working on the game: move what the game needs into a module under scripts/ and import it from both the tool and the "
           "script (docs/EXPORTING.md, \"What is shipped and what is not\")";
}

}  // namespace fa::tooling_detail
