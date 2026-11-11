// Private helpers that read JavaScript source without a parser (no regex: a huge script cannot exhaust the stack of a
// recursive regex engine). Shared by `factoria export` and `factoria validate`.
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <map>
#include <string>
#include <string_view>
#include <vector>

namespace fa::tooling_detail {

// A script over 1 MiB is generated code: not scanned.
inline constexpr std::uintmax_t kMaxScanScriptBytes = 1u << 20;

bool js_ident_char(char c);

// Skips blanks and matches fixed words; strings and comments are not parsed, which is enough for the literal calls looked for.
struct JsScan {
    const std::string& s;
    std::size_t i = 0;
    void blanks();
    bool word(std::string_view w);
    // A quoted string ('...' or "..."), without escapes: the names looked for have none.
    bool quoted(std::string& out);
};

// `code`: the source with comments blanked. `bare`: also with the inside of strings and templates blanked. Same length as the
// source (newlines are kept), so an offset means the same in all three.
struct Masked {
    std::string code;
    std::string bare;
};

Masked mask_source(const std::string& t);

// 1-based line and column of byte `offset` in `text`.
struct SourcePos {
    int line = 1;
    int column = 1;
};
SourcePos source_pos(const std::string& text, std::size_t offset);

// The name a tool module registers: the first `name: "<text>"` after `export default`, cleaned the way the script module
// cleans it. Empty when there is none: the engine does not register such a file either.
std::string tool_module_name(const std::string& text);

// A literal `fa.call("project.<name>"` in a script.
struct ProjectCall {
    std::string name;  // <name>
    int line = 0;
    int column = 0;
};
// Each name once, at its first call, in source order.
std::vector<ProjectCall> literal_project_calls(const std::string& text);

// The commands the project's tool modules define (tools/, subfolders included): command name -> "tools/<file>".
std::map<std::string, std::string> tool_commands(const std::filesystem::path& projectDir);

// The warning for a game script that calls a command only a tool defines (tools/ is left out of an export).
std::string tool_only_call_message(const std::string& scriptFile, const ProjectCall& call, const std::string& toolFile);

}  // namespace fa::tooling_detail
