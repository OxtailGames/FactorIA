#include "args.h"

#include <algorithm>
#include <charconv>
#include <cstdlib>
#include <sstream>

#include "fa/core/strings.h"

namespace fa::cli {

std::string Args::str(const std::string& flag, const std::string& def) const {
    auto it = flags_.find(flag);
    if (it == flags_.end() || it->second.empty()) return def;
    return it->second.back();
}

std::vector<std::string> Args::all(const std::string& flag) const {
    auto it = flags_.find(flag);
    return it == flags_.end() ? std::vector<std::string>{} : it->second;
}

int Args::integer(const std::string& flag, int def) const {
    auto it = flags_.find(flag);
    if (it == flags_.end() || it->second.empty()) return def;
    const std::string& s = it->second.back();
    int v = 0;
    auto r = std::from_chars(s.data(), s.data() + s.size(), v);
    if (r.ec != std::errc() || r.ptr != s.data() + s.size())
        throw UsageError("--" + flag + " expects an integer, got '" + s + "'.", "Example: --" + flag + " 60");
    return v;
}

u64 Args::uinteger(const std::string& flag, u64 def) const {
    auto it = flags_.find(flag);
    if (it == flags_.end() || it->second.empty()) return def;
    const std::string& s = it->second.back();
    u64 v = 0;
    auto r = std::from_chars(s.data(), s.data() + s.size(), v);
    if (r.ec != std::errc() || r.ptr != s.data() + s.size())
        throw UsageError("--" + flag + " expects a non-negative integer, got '" + s + "'.");
    return v;
}

double Args::number(const std::string& flag, double def) const {
    auto it = flags_.find(flag);
    if (it == flags_.end() || it->second.empty()) return def;
    const std::string& s = it->second.back();
    char* end = nullptr;
    double v = std::strtod(s.c_str(), &end);
    if (end == s.c_str() || *end != '\0') throw UsageError("--" + flag + " expects a number, got '" + s + "'.");
    return v;
}

namespace {

std::vector<FlagSpec> all_flags(const Command& cmd) {
    std::vector<FlagSpec> f = cmd.flags;
    f.push_back({"log-level", "LEVEL", "Log verbosity on stderr: trace, debug, info, warn (default), error."});
    f.push_back({"help", "", "Show this help."});
    return f;
}

}  // namespace

Args parse_args(const Command& cmd, const std::vector<std::string>& tokens, const std::string& cmdPath, bool& help) {
    Args out;
    help = false;
    const std::vector<FlagSpec> specs = all_flags(cmd);
    std::vector<std::string> names;
    for (const auto& s : specs) names.push_back("--" + s.name);
    bool flagsDone = false;
    for (std::size_t i = 0; i < tokens.size(); ++i) {
        const std::string& t = tokens[i];
        if (flagsDone || t.size() < 2 || t[0] != '-' || (t[1] != '-' && !(t == "-h"))) {
            out.positional_.push_back(t);
            continue;
        }
        if (t == "--") {
            flagsDone = true;
            continue;
        }
        if (t == "-h") {
            help = true;
            continue;
        }
        std::string name = t.substr(2), value;
        bool hasValue = false;
        if (auto eq = name.find('='); eq != std::string::npos) {
            value = name.substr(eq + 1);
            name = name.substr(0, eq);
            hasValue = true;
        }
        const FlagSpec* spec = nullptr;
        for (const auto& s : specs)
            if (s.name == name) spec = &s;
        if (!spec) {
            throw UsageError("Unknown option '--" + name + "' for 'factoria " + cmdPath + "'.",
                             fa::did_you_mean("--" + name, names) + "  Run 'factoria " + cmdPath + " --help'.");
        }
        if (spec->name == "help") {
            help = true;
            continue;
        }
        if (spec->value.empty()) {
            if (hasValue) {
                if (value == "true" || value == "1") {
                    out.flags_[name].push_back("true");
                    continue;
                }
                if (value == "false" || value == "0") continue;
                throw UsageError("Option '--" + name + "' takes no value.");
            }
            out.flags_[name].push_back("true");
            continue;
        }
        if (!hasValue) {
            if (i + 1 >= tokens.size() || (tokens[i + 1].rfind("--", 0) == 0 && tokens[i + 1].size() > 2))
                throw UsageError("Option '--" + name + "' needs a value (" + spec->value + ").",
                                 "Example: --" + name + " " + spec->value);
            value = tokens[++i];
        }
        auto& slot = out.flags_[name];
        if (!spec->repeatable) slot.clear();
        slot.push_back(value);
    }
    if (!help && cmd.maxPositional >= 0 && static_cast<int>(out.positional_.size()) > cmd.maxPositional) {
        throw UsageError("Unexpected argument '" + out.positional_[static_cast<std::size_t>(cmd.maxPositional)] +
                             "' for 'factoria " + cmdPath + "'.",
                         "Usage: factoria " + cmdPath + " " + cmd.usage);
    }
    return out;
}

std::string format_command_list(const std::vector<Command>& commands) {
    std::size_t w = 0;
    for (const auto& c : commands)
        if (!c.hidden) w = std::max(w, c.name.size());
    std::ostringstream o;
    for (const auto& c : commands) {
        if (c.hidden) continue;
        o << "  " << c.name << std::string(w - c.name.size() + 2, ' ') << c.summary << "\n";
    }
    return o.str();
}

std::string format_help(const Command& cmd, const std::string& cmdPath) {
    std::ostringstream o;
    o << "factoria " << cmdPath << " - " << cmd.summary << "\n\n";
    o << "Usage:\n  factoria " << cmdPath;
    if (!cmd.subs.empty()) o << " <subcommand>";
    if (!cmd.usage.empty()) o << " " << cmd.usage;
    o << "\n";
    if (!cmd.details.empty()) o << "\n" << cmd.details << "\n";
    if (!cmd.subs.empty()) {
        o << "\nSubcommands:\n" << format_command_list(cmd.subs);
        o << "\nRun 'factoria " << cmdPath << " <subcommand> --help' for details.\n";
    }
    if (cmd.run) {
        o << "\nOptions:\n";
        std::vector<FlagSpec> specs = all_flags(cmd);
        std::size_t w = 0;
        auto label = [](const FlagSpec& f) { return "--" + f.name + (f.value.empty() ? "" : " " + f.value); };
        for (const auto& f : specs)
            if (!f.hidden) w = std::max(w, label(f).size());
        for (const auto& f : specs) {
            if (f.hidden) continue;
            std::string l = label(f);
            o << "  " << l << std::string(w - l.size() + 2, ' ') << f.help << (f.repeatable ? " (repeatable)" : "") << "\n";
        }
    }
    if (!cmd.examples.empty()) {
        o << "\nExamples:\n";
        for (const auto& e : cmd.examples) o << "  " << e << "\n";
    }
    o << "\nExit codes: 0 ok, 1 failure, 2 usage error.\n";
    return o.str();
}

}  // namespace fa::cli
