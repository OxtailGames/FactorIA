// Small command/flag parser and help generator for the factoria CLI.
#pragma once

#include <functional>
#include <iosfwd>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa::cli {

// Wrong invocation (exit code 2). The message says what is wrong; `hint` how to fix it.
struct UsageError : std::runtime_error {
    std::string hint;
    explicit UsageError(const std::string& msg, std::string hint_ = {})
        : std::runtime_error(msg), hint(std::move(hint_)) {}
};

// The command ran but failed (exit code 1).
struct CliError : std::runtime_error {
    std::string hint;
    explicit CliError(const std::string& msg, std::string hint_ = {})
        : std::runtime_error(msg), hint(std::move(hint_)) {}
};

struct FlagSpec {
    std::string name;   // "scene" for --scene
    std::string value;  // placeholder for the value ("PATH"); empty = boolean flag
    std::string help;
    bool repeatable = false;
    bool hidden = false;  // accepted, but not listed in --help (a hand-over between factoria processes, not for people)
};

class Args {
public:
    bool has(const std::string& flag) const { return flags_.count(flag) != 0; }
    std::string str(const std::string& flag, const std::string& def = {}) const;
    std::vector<std::string> all(const std::string& flag) const;
    int integer(const std::string& flag, int def) const;      // UsageError when not a number
    u64 uinteger(const std::string& flag, u64 def) const;
    double number(const std::string& flag, double def) const;
    const std::vector<std::string>& positional() const { return positional_; }
    std::string pos(std::size_t i, const std::string& def = {}) const {
        return i < positional_.size() ? positional_[i] : def;
    }

    std::map<std::string, std::vector<std::string>> flags_;
    std::vector<std::string> positional_;
};

struct Context;

struct Command {
    std::string name;
    std::string summary;                  // one line
    std::string usage;                    // e.g. "[project] [options]" (after "factoria <name> ")
    std::string details;                  // optional paragraphs
    std::vector<FlagSpec> flags;
    std::vector<std::string> examples;    // full command lines
    std::function<int(Context&)> run;     // null for groups (commands with `subs`)
    std::vector<Command> subs;
    int maxPositional = 0;                // -1 = unlimited
    bool hidden = false;
};

struct Context {
    std::ostream& out;
    std::ostream& err;
    std::istream& in;
    Args args;
    const Command* cmd = nullptr;
    std::string cmdPath;  // "ai run"
};

// Parses `tokens` against `cmd` (adds --help/-h and --log-level). Throws UsageError.
// `help` is set when --help/-h was seen.
Args parse_args(const Command& cmd, const std::vector<std::string>& tokens, const std::string& cmdPath, bool& help);

std::string format_help(const Command& cmd, const std::string& cmdPath);
std::string format_command_list(const std::vector<Command>& commands);

}  // namespace fa::cli
