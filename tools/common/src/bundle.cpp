#include "fa/tooling/bundle.h"

#include <algorithm>
#include <filesystem>

#include "fa/render/builtin_fonts.h"
#include "util.h"

#if defined(FA_HAS_EMBEDDED_FILES)
#include "fa_embedded_files.h"
#endif

namespace fa {

bool bundled_embedded() {
#if defined(FA_HAS_EMBEDDED_FILES)
    return true;
#else
    return false;
#endif
}

std::vector<std::string> bundled_list(std::string_view prefix) {
    std::vector<std::string> out;
#if defined(FA_HAS_EMBEDDED_FILES)
    for (const auto& f : embedded::files()) {
        std::string_view p = f.path;
        if (p.substr(0, prefix.size()) == prefix) out.emplace_back(p);
    }
#else
    namespace stdfs = std::filesystem;
    std::error_code ec;
    stdfs::path root = FA_SOURCE_ROOT;
    // Walk only the top-level folder named by the prefix (docs, templates, schemas).
    std::string top = std::string(prefix.substr(0, prefix.find('/')));
    if (top.empty()) top = ".";
    stdfs::path base = root / top;
    if (stdfs::is_directory(base, ec)) {
        for (stdfs::recursive_directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec)) {
            if (!it->is_regular_file(ec)) continue;
            std::string rel = stdfs::relative(it->path(), root, ec).generic_string();
            if (rel.compare(0, prefix.size(), prefix) == 0) out.push_back(rel);
        }
    }
#endif
    std::sort(out.begin(), out.end());
    return out;
}

std::optional<std::string> bundled_read(std::string_view path) {
#if defined(FA_HAS_EMBEDDED_FILES)
    for (const auto& f : embedded::files())
        if (f.path == path) return std::string(f.data);
    return std::nullopt;
#else
    if (path.find("..") != std::string_view::npos) return std::nullopt;
    return tooling_detail::read_file(std::filesystem::path(FA_SOURCE_ROOT) / std::string(path));
#endif
}

namespace {
// Every program that links the tooling (factoria, the editor, the tests) finds the files of the built-in fonts that are not
// inside the player (builtin:serif, ...) among the bundled files; a player finds them in the game folder, where the export puts
// them. A static initializer, because there is no startup function all these programs share.
[[maybe_unused]] const bool kFontSourceInstalled = [] {
    set_builtin_font_source([](std::string_view file) { return bundled_read("engine/render/assets/fonts/extra/" + std::string(file)); });
    return true;
}();
}  // namespace

}  // namespace fa
