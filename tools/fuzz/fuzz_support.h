// What the fuzz targets share (tools/fuzz/README.md).
#pragma once

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <string_view>
#include <system_error>

#include "fa/core/fs.h"
#include "fa/core/log.h"

namespace fa::fuzz {

// The input as text (the targets never copy it before they need to).
inline std::string_view as_text(const std::uint8_t* data, std::size_t size) {
    return {reinterpret_cast<const char*>(data), size};
}

// A property the engine promises did not hold: stop like a crash does (libFuzzer saves the input; the replay names the file).
[[noreturn]] inline void fail(const char* what) {
    std::fprintf(stderr, "fuzz: property violated: %s\n", what);
    std::abort();
}

// Call first in a target's initialisation: no log line goes to stderr (a target runs millions of inputs, and most of them
// are rejected with a message).
inline void quiet() { set_log_format(LogFormat::None); }

// An empty folder as the project root, once: whatever a target loads that names a file ("prefab": "x.prefab.json",
// a texture) is answered "not found" and nothing outside the folder is read. Removed when the process ends normally.
inline const std::filesystem::path& empty_project() {
    struct Holder {
        std::filesystem::path dir;
        Holder() {
            if (auto d = fs::make_temp_dir("fa_fuzz")) {
                dir = d.value();
                fs::set_project_root(dir);
            }
        }
        ~Holder() {
            std::error_code ec;
            if (!dir.empty()) std::filesystem::remove_all(dir, ec);
        }
    };
    static const Holder holder;
    return holder.dir;
}

}  // namespace fa::fuzz
