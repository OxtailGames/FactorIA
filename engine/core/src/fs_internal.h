// Platform hooks used by fs.cpp (the Android ones are in fs_android.cpp, Android only; the Windows one in
// fs_in_use_win32.cpp), and the hooks pack.cpp uses to tell the "Windows file rules" emulation about an open pack.
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

// Under the Windows rules emulation (fs.h): `file` counts as open for reading until unregister_open_file(token) with
// the same `sharesDelete`. Any open file cannot be replaced; one whose handle does not share delete (a ReadStream, a
// mapped pack) cannot be deleted either. A delete that goes through (every handle shared delete) frees the path, as
// on Windows: the handles stay on the nameless file and a new file there is not held by them. Returns a token, "" when
// the emulation is off (then there is nothing to unregister).
std::string register_open_file(const std::filesystem::path& file, bool sharesDelete);
void unregister_open_file(const std::string& token, bool sharesDelete);

#ifdef _WIN32
// fs_in_use_win32.cpp: Yes when something holds `file` so that a delete of it would fail: a handle that did not allow
// deleting, a running exe or loaded library, a mapped file. MarkLost: the probe marked the file for deletion and Windows
// would not take the mark back, so it goes when the probe's handle closes. One look, no retry (fs::file_in_use retries).
enum class Held { No, Yes, MarkLost };
Held held_open(const std::filesystem::path& file);
// fs_in_use_win32.cpp: whether another handle is open on `file`, whatever it shares (an exclusive open fails with a
// sharing or lock violation). MoveFileExW answers ERROR_ACCESS_DENIED both for a target that is open somewhere (mapped
// or not, delete shared or not) and for one this process may not write: this tells the two apart. One look, no retry.
bool open_elsewhere(const std::filesystem::path& file);
// fs_win32.cpp: the system's temporary folder as GetTempPath2W / GetTempPathW answer it (UTF-16, with a trailing separator),
// or an empty string when Windows names none.
std::wstring windows_temp_path();
#endif
}  // namespace fa::fs::detail
