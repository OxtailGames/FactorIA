// The OS part of fa::fs::write_private / make_private (private_file.cpp): private_file_posix.cpp, private_file_win32.cpp.
#pragma once

#include <filesystem>
#include <string>
#include <string_view>

namespace fa::detail {

// Creates `file` (it must not exist) readable by its owner only from its first moment, and writes `bytes` to it. "" on success,
// else what went wrong (with the OS message).
std::string create_private_file(const std::filesystem::path& file, std::string_view bytes);

// Restricts the existing file to its owner. "" on success, else what went wrong.
std::string restrict_to_owner(const std::filesystem::path& file);

}  // namespace fa::detail
