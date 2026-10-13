#pragma once
#include <atomic>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/json.h"

namespace fa::testing {

// Unique temporary directory removed on destruction.
struct TempDir {
    std::filesystem::path path;
    TempDir() {
        static std::atomic<int> counter{0};
        path = std::filesystem::temp_directory_path() /
               ("fa_tooling_test_" + std::to_string(std::hash<std::string>{}(std::to_string(counter++) + __TIME__)) + "_" +
                std::to_string(reinterpret_cast<std::uintptr_t>(this)));
        std::filesystem::remove_all(path);
        std::filesystem::create_directories(path);
    }
    ~TempDir() {
        std::error_code ec;
        std::filesystem::remove_all(path, ec);
    }
    std::string str() const { return path.string(); }
    std::string sub(const std::string& rel) const { return (path / rel).string(); }
};

inline std::string read_all(const std::filesystem::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

inline void write_all(const std::filesystem::path& p, const std::string& s) {
    std::filesystem::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << s;
}

}  // namespace fa::testing
