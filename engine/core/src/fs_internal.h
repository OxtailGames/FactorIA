// Platform hooks used by fs.cpp (the Android ones are in fs_android.cpp, Android only), and the hooks pack.cpp uses to
// tell the "Windows file rules" emulation about a mapped pack.
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <string>
#include <vector>

namespace fa::fs::detail {
#ifdef __ANDROID__
// Reads an APK asset. Returns false if the asset does not exist.
bool android_read(const std::string& path, std::vector<std::uint8_t>& out);
// An APK asset's bytes without a copy (AAsset_getBuffer): `owner` keeps the asset open while the bytes are used. False
// when the asset does not exist or its buffer cannot be had (then android_read copies it).
bool android_view(const std::string& path, std::shared_ptr<const void>& owner, const std::uint8_t*& data, std::size_t& size);
bool android_exists(const std::string& path);
bool android_is_directory(const std::string& path);
// Lists file paths (relative to the APK assets root) under `dir`.
std::vector<std::string> android_list(const std::string& dir, bool recursive);
#endif

// Under the Windows rules emulation (fs.h): `file` counts as open for reading, as a ReadStream does, until
// unregister_open_file(key). Returns the key, "" when the emulation is off (then there is nothing to unregister).
std::string register_open_file(const std::filesystem::path& file);
void unregister_open_file(const std::string& key);
}  // namespace fa::fs::detail
