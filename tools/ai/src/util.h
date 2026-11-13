// Private helpers (not installed).
#pragma once

#include <cctype>
#include <cstddef>
#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/feedback_share.h"

namespace fa::ai::util {

// The lock of a read-modify-write of ai.json (or of a file next to it, ai-trust.json): the editor, a `factoria` of an agent and a
// second editor can save at the same time, and each reads the file, changes one part and writes it back, so the one that wrote
// first would be lost. It is a ShareLock in the file's folder with its own lock file, ai-config.lock (a lock FILE, so it holds
// between processes; one left by a program that crashed is taken over after about 10 s). The wait is capped at one second: the
// lock is held for milliseconds, and the editor's UI thread saves too. The write itself is write_private (a temporary file, then
// an atomic replace; on Windows the replace is retried for about a second when another program holds the target open). Take it
// BEFORE reading the file; `held()` false means nothing was changed.
inline constexpr const char* kAiConfigLockFile = "ai-config.lock";

class AiFileLock {
public:
    explicit AiFileLock(std::string_view file)
        : cap_(1.0), lock_(fa::share_env(), folder_of(file), -1, kAiConfigLockFile), file_(file) {}
    bool held() const { return lock_.held(); }
    Error error() const {
        if (lock_.unwritable())
            return make_error("Cannot save '" + file_ + "': the lock file " + lock_.path() +
                                  " cannot be made in its folder",
                              "Check that the folder of the file exists and that your account may create files in it, "
                              "then save again.");
        return make_error(
            "Cannot save '" + file_ +
                "': another FactorIA program (a second editor, an agent's `factoria`) holds the lock file " +
                lock_.path() + " and did not finish in one second, so nothing was changed.",
            "Try again in a few seconds. A lock left by a program that crashed expires after about 10 s; if it stays "
            "and no "
            "FactorIA program is running, delete that lock file.");
    }

private:
    static std::filesystem::path folder_of(std::string_view file) {
        std::filesystem::path p = fa::fs::path_from_utf8(file).parent_path();
        return p.empty() ? std::filesystem::path(".") : p;
    }
    fa::ShareWaitCap cap_;
    fa::ShareLock lock_;
    std::string file_;
};

// Safe JSON accessors: never throw on type mismatch.
inline std::string str(const Json& j, const char* key, std::string def = {}) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return (it != j.end() && it->is_string()) ? it->get<std::string>() : def;
}
inline double num(const Json& j, const char* key, double def = 0) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return (it != j.end() && it->is_number()) ? it->get<double>() : def;
}
inline bool flag(const Json& j, const char* key, bool def = false) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return (it != j.end() && it->is_boolean()) ? it->get<bool>() : def;
}
inline const Json* child(const Json& j, const char* key) {
    if (!j.is_object()) return nullptr;
    auto it = j.find(key);
    return it == j.end() ? nullptr : &*it;
}

// Compact dump that never throws on invalid UTF-8.
inline std::string dump(const Json& j) { return j.dump(-1, ' ', false, Json::error_handler_t::replace); }
inline std::string dump_pretty(const Json& j, int indent = 2) {
    return j.dump(indent, ' ', false, Json::error_handler_t::replace);
}
// Non-throwing parse; returns discarded value on error.
inline Json parse(std::string_view text) { return Json::parse(text.begin(), text.end(), nullptr, false); }

inline std::string lower(std::string s) {
    for (auto& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}
inline bool contains(std::string_view s, std::string_view needle) { return s.find(needle) != std::string_view::npos; }

// A placeholder of a command-line template ("{prompt}") and what it stands for.
struct Placeholder {
    std::string_view key;
    std::string_view value;
};
// Replaces the placeholders of `subs` in `text` in one pass, left to right: a value that was put in is never searched again,
// so a prompt or a path that contains "{model}" stays as written. Text that matches no key is kept. `found` (optional) is
// set to whether each key occurred, in the order of `subs`.
inline std::string expand_placeholders(std::string_view text, const Placeholder* subs, std::size_t count,
                                       std::vector<bool>* found = nullptr) {
    if (found) found->assign(count, false);
    std::string out;
    out.reserve(text.size());
    std::size_t i = 0;
    while (i < text.size()) {
        const std::size_t open = text.find('{', i);
        if (open == std::string_view::npos) break;
        out.append(text.substr(i, open - i));
        std::size_t matched = count;
        for (std::size_t k = 0; k < count; ++k)
            if (!subs[k].key.empty() && text.substr(open, subs[k].key.size()) == subs[k].key &&
                (matched == count || subs[k].key.size() > subs[matched].key.size()))
                matched = k;  // the longest key that matches here
        if (matched == count) {
            out += '{';
            i = open + 1;
            continue;
        }
        out.append(subs[matched].value);
        if (found) (*found)[matched] = true;
        i = open + subs[matched].key.size();
    }
    if (i < text.size()) out.append(text.substr(i));
    return out;
}

}  // namespace fa::ai::util
