#include "js_scan.h"

#include <cctype>
#include <system_error>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::tooling_detail {
namespace stdfs = std::filesystem;

bool js_ident_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$'; }

// Strings, templates and comments are told apart; the inside of a template's substitution is code again (so a call to
// fa.call there is found), with nesting. Regex literals are NOT recognised (telling the `/` of a division from a regex needs a
// parser): a quote inside one can start a string that ends at the line (a backtick: later), which can only hide calls.
Masked mask_source(const std::string& t) {
    Masked m{t, t};
    std::vector<int> subst;  // open substitutions of templates: the brace depth inside each
    enum class S { Code, Line, Block, Single, Double, Template } st = S::Code;
    auto blank = [](std::string& s, std::size_t i) {
        if (s[i] != '\n') s[i] = ' ';
    };
    for (std::size_t i = 0; i < t.size(); ++i) {
        const char c = t[i];
        const char n = i + 1 < t.size() ? t[i + 1] : '\0';
        switch (st) {
            case S::Code:
                if (!subst.empty() && c == '{')
                    ++subst.back();
                else if (!subst.empty() && c == '}') {
                    if (--subst.back() == 0) {
                        blank(m.bare,
                              i);  // the closing brace is not code either: an orphan `}` would unbalance declared_names
                        subst.pop_back();
                        st = S::Template;
                    }
                } else if (c == '/' && n == '/') {
                    st = S::Line;
                    blank(m.code, i);
                    blank(m.bare, i);
                } else if (c == '/' && n == '*') {
                    st = S::Block;
                    blank(m.code, i);
                    blank(m.bare, i);
                } else if (c == '\'')
                    st = S::Single;
                else if (c == '"')
                    st = S::Double;
                else if (c == '`')
                    st = S::Template;
                break;
            case S::Line:
                if (c == '\n')
                    st = S::Code;
                else {
                    blank(m.code, i);
                    blank(m.bare, i);
                }
                break;
            case S::Block:
                blank(m.code, i);
                blank(m.bare, i);
                if (c == '*' && n == '/') {
                    blank(m.code, i + 1);
                    blank(m.bare, i + 1);
                    ++i;
                    st = S::Code;
                }
                break;
            case S::Single:
            case S::Double:
            case S::Template: {
                const char q = st == S::Single ? '\'' : st == S::Double ? '"' : '`';
                if (c == '\\') {
                    blank(m.bare, i);
                    if (i + 1 < t.size()) blank(m.bare, i + 1);
                    ++i;
                } else if (st == S::Template && c == '$' && n == '{') {
                    blank(m.bare, i);  // the `${` itself is not code; what follows it is
                    blank(m.bare, i + 1);
                    ++i;
                    subst.push_back(1);
                    st = S::Code;
                } else if (c == q) {
                    st = S::Code;
                } else if (c == '\n' && st != S::Template) {
                    st = S::Code;  // an unterminated string ends at the line
                } else {
                    blank(m.bare, i);
                }
                break;
            }
        }
    }
    return m;
}

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
    // `fa.call` inside a comment or a string is not a call: find it in the masked text (strings blanked) and read the
    // argument from the text with only the comments blanked.
    const Masked m = mask_source(text);
    const std::string& bare = m.bare;
    for (std::size_t at = bare.find("fa"); at != std::string::npos; at = bare.find("fa", at + 2)) {
        if (at > 0 && js_ident_char(bare[at - 1])) continue;
        JsScan sc{m.code, at + 2};
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

std::string tool_only_call_message(const std::string& scriptFile, const ProjectCall& call,
                                   const std::string& toolFile) {
    return scriptFile + ":" + std::to_string(call.line) + " calls project." + call.name + ", the command of " +
           toolFile +
           ". tools/ is left out of the export, so in the shipped game that call fails (there is no such command). "
           "Tools are for "
           "working on the game: move what the game needs into a module under scripts/ and import it from both the "
           "tool and the "
           "script (docs/EXPORTING.md, \"What is shipped and what is not\")";
}

}  // namespace fa::tooling_detail
