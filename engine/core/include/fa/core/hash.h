// SHA-1 and SHA-256 (hex digests) of a buffer or a file. Used to verify downloads (`factoria setup`): the Android SDK
// repository lists SHA-1 checksums, Adoptium, GitHub releases and Kitware list SHA-256 ones.
//
// These are checksums to detect a damaged or substituted download, not password hashes. SHA-1 is only here because
// Google publishes SHA-1 for the command-line tools (they are fetched over HTTPS from dl.google.com).
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <string>
#include <string_view>

#include "fa/core/types.h"

namespace fa {

// Incremental hashers: update() any number of times, then finish_hex() once (lowercase hex).
class Sha256 {
public:
    Sha256();
    void update(const void* data, std::size_t size);
    void update(std::string_view data) { update(data.data(), data.size()); }
    std::string finish_hex();

private:
    void block(const std::uint8_t* p);
    std::array<std::uint32_t, 8> h_;
    std::array<std::uint8_t, 64> buf_{};
    std::size_t bufLen_ = 0;
    std::uint64_t total_ = 0;
};

class Sha1 {
public:
    Sha1();
    void update(const void* data, std::size_t size);
    void update(std::string_view data) { update(data.data(), data.size()); }
    std::string finish_hex();

private:
    void block(const std::uint8_t* p);
    std::array<std::uint32_t, 5> h_;
    std::array<std::uint8_t, 64> buf_{};
    std::size_t bufLen_ = 0;
    std::uint64_t total_ = 0;
};

std::string sha256_hex(const void* data, std::size_t size);
inline std::string sha256_hex(std::string_view data) { return sha256_hex(data.data(), data.size()); }
std::string sha1_hex(const void* data, std::size_t size);
inline std::string sha1_hex(std::string_view data) { return sha1_hex(data.data(), data.size()); }

// Hash of a whole file, read in chunks (a 200 MB archive is not loaded into memory). The Error names the file.
Result<std::string> sha256_file_hex(const std::filesystem::path& path);
Result<std::string> sha1_file_hex(const std::filesystem::path& path);

}  // namespace fa
