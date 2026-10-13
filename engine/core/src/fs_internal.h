// Platform hooks used by fs.cpp. Implemented in fs_android.cpp on Android only.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace fa::fs::detail {
#ifdef __ANDROID__
// Reads an APK asset. Returns false if the asset does not exist.
bool android_read(const std::string& path, std::vector<std::uint8_t>& out);
bool android_exists(const std::string& path);
bool android_is_directory(const std::string& path);
// Lists file paths (relative to the APK assets root) under `dir`.
std::vector<std::string> android_list(const std::string& dir, bool recursive);
#endif
}  // namespace fa::fs::detail
