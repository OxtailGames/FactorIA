// What the fuzz targets share (tools/fuzz/README.md).
#pragma once

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <chrono>
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

// The folders of earlier runs that crashed or were aborted (a failed property, a libFuzzer finding, a timeout) never ran
// their destructor and are left in the temporary folder. Their names are unique (fa_fuzz_<pid>_<n>), so a new run removes
// those older than a day: another fuzz process running now (a parallel ctest, a libFuzzer job) is never touched.
inline void remove_stale_projects(const std::filesystem::path& parent) {
    std::error_code ec;
    const std::filesystem::path prefix(u8"fa_fuzz_");  // compared as native text: no round trip through the ANSI code page
    const auto cutoff = std::filesystem::file_time_type::clock::now() - std::chrono::hours(24);
    for (std::filesystem::directory_iterator it(parent, ec), end; !ec && it != end; it.increment(ec)) {
        std::error_code entryEc;
        const auto& name = it->path().filename().native();
        if (name.rfind(prefix.native(), 0) != 0) continue;
        // Only fa_fuzz_<pid>_<n> (and make_temp_dir's _<n> suffix): never a user's fa_fuzz_findings or fa_fuzz_corpus.
        const auto rest = name.substr(prefix.native().size());
        bool ours = !rest.empty() && rest.find('_') != rest.npos;
        for (const auto ch : rest) ours = ours && ((ch >= '0' && ch <= '9') || ch == '_');
        if (!ours) continue;
        if (!it->is_directory(entryEc) || entryEc) continue;
        const auto written = std::filesystem::last_write_time(it->path(), entryEc);
        if (!entryEc && written < cutoff) std::filesystem::remove_all(it->path(), entryEc);
    }
}

// An empty folder as the project root, once: whatever a target loads that names a file ("prefab": "x.prefab.json",
// a texture) is answered "not found" and nothing outside the folder is read. Removed when the process ends normally;
// when it crashes or aborts the next run removes it (remove_stale_projects).
inline const std::filesystem::path& empty_project() {
    struct Holder {
        std::filesystem::path dir;
        Holder() {
            if (auto d = fs::make_temp_dir("fa_fuzz")) {
                dir = d.value();
                remove_stale_projects(dir.parent_path());
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
