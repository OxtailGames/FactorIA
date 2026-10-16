// Private helpers shared by fa_tooling sources.
#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <string_view>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"

namespace fa::tooling_detail {

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
