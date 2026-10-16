// The asset steps of every export: what assets.json's import settings ask for, applied to the files that ship.
#include <algorithm>

#include "export_internal.h"
#include "fa/core/asset_manifest.h"

namespace fa::export_detail {

void ExportAssets::replace(const std::string& original, const std::string& shipped, const stdfs::path& source) {
    if (!original.empty()) {
        files.erase(std::remove(files.begin(), files.end(), original), files.end());
        project.staged.erase(original);
    }
    if (std::find(files.begin(), files.end(), shipped) == files.end()) files.push_back(shipped);
    project.staged[shipped] = source;
}

Result<void> prepare_game_assets(Project& p, const std::string& platform, std::vector<std::string>& files, ExportReport& report) {
    ExportAssets ea{p, platform, files, p.dir / ".factoria" / "export-cache" / platform, Json(), report};
    const bool hasManifest = std::find(files.begin(), files.end(), assets::kManifestFile) != files.end();
    ea.manifest = Json::object({{"format", assets::kManifestFormat}});
    if (hasManifest) {
        auto text = read_file(p.dir / assets::kManifestFile);
        auto parsed = text ? parse_json(*text, assets::kManifestFile) : Result<Json>(err("cannot read assets.json"));
        if (!parsed.ok() || !parsed->is_object())
            return err(std::string("export: ") + assets::kManifestFile + " is not valid: " +
                           (parsed.ok() ? "it must be a JSON object" : parsed.error().message),
                       "Run `factoria validate` and fix the file.");
        ea.manifest = std::move(*parsed);
        // Authoring data stays home: the game needs the import settings, not who made what or the house style.
        ea.manifest.erase("style");
        if (auto a = ea.manifest.find("assets"); a != ea.manifest.end() && a->is_object()) {
            for (auto it = a->begin(); it != a->end(); ++it)
                if (it->is_object()) it->erase("provenance");
            for (auto it = a->begin(); it != a->end();) it = it->is_object() && it->empty() ? a->erase(it) : std::next(it);
        }
    }

    if (auto r = convert_textures(ea); !r.ok()) return r;
    if (auto r = convert_audio(ea); !r.ok()) return r;

    if (hasManifest || ea.manifest.size() > 1) {
        const stdfs::path shipped = ea.cacheDir / assets::kManifestFile;
        std::string e;
        if (!write_file(shipped, dump_json(ea.manifest), &e)) return err("export: " + e);
        ea.replace(assets::kManifestFile, assets::kManifestFile, shipped);
    }
    std::sort(files.begin(), files.end());
    return {};
}

}  // namespace fa::export_detail
