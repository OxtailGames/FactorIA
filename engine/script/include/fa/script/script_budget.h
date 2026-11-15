// The script budgets of factoria.json: "runtime": {"scriptMemoryMB", "scriptFrameBudgetMs"}.
//
// Each is a number, or an object with one number per platform: {"default": 768, "android": 384, "web": 256}. The project
// loader (fa/runtime/project.h) checks the file and says what is wrong; the script system (script.h) resolves the value for
// the platform it runs on when it starts. Nothing here reads a clock or a file.
#pragma once

#include <string_view>

#include "fa/core/json.h"

namespace fa {

// Heap cap of the JavaScript runtime in megabytes. A script that needs more fails with "out of memory", and the error names
// this setting and its value. 768 on every platform unless the project says otherwise.
inline constexpr double kDefaultScriptMemoryMB = 768.0;
inline constexpr double kMinScriptMemoryMB = 16.0;
inline constexpr double kMaxScriptMemoryMB =
    2048.0;  // below 4 GB: the number of bytes fits a 32-bit size_t (the web build)

// What the scripts of one frame (every callback, timer, event handler and promise job) may spend before the engine warns:
// milliseconds. 0 turns the warning off.
inline constexpr double kDefaultScriptFrameBudgetMs = 8.0;
inline constexpr double kMaxScriptFrameBudgetMs = 1000.0;

// The platform this build runs on, spelled like the keys of "export" and "backend": "windows", "macos", "linux", "ios",
// "android" or "web".
const char* script_platform_name();

// The number a per-platform setting gives on `platform`: `setting` itself when it is a number, else the entry of that platform,
// else its "default" entry. `fallback` when the setting is absent, malformed or has no entry for the platform (the project
// loader reports those cases before the game starts; this one never throws).
double resolve_per_platform_number(const Json& setting, std::string_view platform, double fallback);

}  // namespace fa
