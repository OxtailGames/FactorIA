// Private helpers shared by fa_tooling sources.
#pragma once

#include <algorithm>
#include <filesystem>
#include <initializer_list>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/tooling/export_settings.h"

namespace fa::tooling_detail {

// export.exclude: true when `rel` (project-relative, forward slashes) or one of its folders matches one of the globs.
bool export_excluded(const std::vector<std::string>& globs, std::string_view rel);
std::string today_utc();  // YYYY-MM-DD
std::optional<std::string> read_file(const std::filesystem::path& p);
bool write_file(const std::filesystem::path& p, std::string_view data, std::string* err = nullptr);  // creates dirs
std::string slugify(std::string_view s, char sep);  // "My Game!" -> "my-game"
// Loads a bundled schema ("schemas/project.schema.json"); null Json if missing.
Json load_schema(std::string_view bundledPath);
// Argument helpers for command handlers (throw CommandError on missing/invalid).
std::string arg_string(const Json& args, const char* key, bool required, std::string def = {});
bool arg_bool(const Json& args, const char* key, bool def);
long arg_int(const Json& args, const char* key, long def);

// User-edited JSON (import settings...): a missing key or a value of the wrong type reads as the fallback.
inline bool bool_setting(const Json& s, const char* key) {
    auto it = s.find(key);
    return it != s.end() && it->is_boolean() && it->get<bool>();
}
inline double number_setting(const Json& s, const char* key, double fallback) {
    auto it = s.find(key);
    return it != s.end() && it->is_number() ? it->get<double>() : fallback;
}
inline std::string string_setting(const Json& s, const char* key, const char* fallback) {
    auto it = s.find(key);
    return it != s.end() && it->is_string() ? it->get<std::string>() : fallback;
}
// "~" and "~/..." with the home folder (HOME, else USERPROFILE); unchanged when neither is set.
std::string expand_home(const std::string& path, const ExportEnvLookup& env);

// A key as one token of a JSON pointer ("a/b" -> "a~1b").
inline std::string escape_token(const std::string& key) {
    std::string out;
    for (char c : key) {
        if (c == '~') out += "~0";
        else if (c == '/') out += "~1";
        else out += c;
    }
    return out;
}

// What the readers of a factoria.json section share (export_settings.cpp, publish_settings.cpp): `Parse` has `errors` and
// `warnings`, both lists of ExportSettingsIssue. A reader derives from it and adds the fields of its section.
template <class Parse>
struct SettingsReader {
    Parse result;

    void error(const std::string& pointer, std::string message, std::string hint) {
        result.errors.push_back({pointer, std::move(message), std::move(hint)});
    }
    void warn(const std::string& pointer, std::string message, std::string hint) {
        result.warnings.push_back({pointer, std::move(message), std::move(hint)});
    }

    // The member `key` of `obj` as an object, or nullptr (absent, null, or an error was recorded).
    const Json* object_member(const Json& obj, const std::string& base, const char* key, const std::string& example) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return nullptr;
        if (!it->is_object()) {
            error(base + "/" + key, "expected an object, got " + describe_json_value(*it), "Write it as " + example + ".");
            return nullptr;
        }
        return &*it;
    }

    void unknown_keys(const Json& obj, const std::string& base, const std::vector<std::string>& known) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
            warn(base + "/" + escape_token(it.key()), "Unknown key '" + it.key() + "'; it is ignored.",
                 did_you_mean(it.key(), known));
        }
    }
    void unknown_keys(const Json& obj, const std::string& base, std::initializer_list<const char*> names) {
        unknown_keys(obj, base, std::vector<std::string>(names.begin(), names.end()));
    }
};

// A sound file the engine plays: .wav, .ogg, .mp3 or .qoa.
inline bool is_audio_file(std::string_view path) {
    const std::string ext = fs::extension(path);
    return ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa";
}

// Points the VFS (fa::fs) at a project folder for the length of a scope, for the engine functions that read through it
// (assets::import_settings, read_audio_file...); the previous root comes back on exit.
struct ProjectRootScope {
    std::filesystem::path saved;
    explicit ProjectRootScope(const std::filesystem::path& dir) : saved(fs::project_root()) { fs::set_project_root(dir); }
    ~ProjectRootScope() { fs::set_project_root(saved); }
    ProjectRootScope(const ProjectRootScope&) = delete;
    ProjectRootScope& operator=(const ProjectRootScope&) = delete;
};

}  // namespace fa::tooling_detail
