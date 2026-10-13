// Private helpers shared by fa_tooling sources.
#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <string_view>

#include "fa/core/command.h"
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

}  // namespace fa::tooling_detail
