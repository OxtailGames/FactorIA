// The built-in fonts step of an export: DejaVu Sans and Press Start 2P are inside every player, but builtin:serif, builtin:hand,
// builtin:blackletter and builtin:display are files of the developer tools (fa/render/builtin_fonts.h). The game gets the files
// of the families its text mentions, as builtin-fonts/<file> (the player reads them from there), and nothing else, so a game that
// does not use them does not grow. Their license texts go into FACTORIA_NOTICES.txt (export.cpp: write_notices).
#include <algorithm>
#include <set>

#include "export_internal.h"
#include "fa/render/builtin_fonts.h"
#include "fa/tooling/bundle.h"

namespace fa::export_detail {

namespace {
bool scanned_extension(const std::string& f) {
    for (const char* e : {".json", ".js", ".mjs", ".ts", ".txt"})
        if (f.ends_with(e)) return true;
    return false;
}
}  // namespace

std::vector<std::string> builtin_fonts_used(const Project& p, const std::vector<std::string>& files) {
    std::set<std::string> used;
    constexpr std::uintmax_t kMaxScanned = 32u << 20;  // a data file bigger than this is not where a font is named
    for (const std::string& f : files) {
        if (!scanned_extension(f) || f.rfind(kBuiltinFontDir, 0) == 0) continue;
        std::error_code ec;
        const stdfs::path path = p.dir / f;
        if (stdfs::file_size(os_path(path), ec) > kMaxScanned) continue;
        const auto text = tooling_detail::read_file(path);
        if (!text) continue;
        for (const BuiltinFont* b : builtin_fonts_named_in(*text)) used.insert(b->name);
    }
    return {used.begin(), used.end()};
}

Result<void> stage_builtin_fonts(ExportAssets& ea) {
    const std::vector<std::string> used = builtin_fonts_used(ea.project, ea.files);
    for (const std::string& name : used) {
        const BuiltinFont* font = find_builtin_font(name);
        if (!font) continue;
        for (const std::string& file : font->files) {
            const auto bytes = bundled_read("engine/render/assets/fonts/extra/" + file);
            if (!bytes)
                return err("export: the built-in font file " + file + " (" + name + ") is missing from this factoria build",
                           "Use a factoria built from a complete FactorIA checkout (engine/render/assets/fonts/extra/).");
            const std::string shipped = std::string(kBuiltinFontDir) + "/" + file;
            const stdfs::path source = ea.cacheDir / shipped;
            std::string e;
            if (!write_file(source, *bytes, &e)) return err("export: " + e);
            ea.replace("", shipped, source);
        }
        ea.report.builtinFonts.push_back(name);
    }
    return {};
}

}  // namespace fa::export_detail
