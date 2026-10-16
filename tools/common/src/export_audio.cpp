// Audio steps of an export (audio import settings of assets.json): conversion and loudness.
//
//   convert "qoa"   a WAV ships as <path>.qoa (the engine loads that twin when the original is missing); the encoded file is
//                   kept in <cacheDir>/audio/ under the SHA-256 of the WAV, so a second export encodes nothing.
//   normalize       the shipped assets.json gets the loudness of the file as it ships (the twin's bytes when converted) under
//                   the entry's `analysis`: mobile builds never measure, and desktop builds skip the decode at load.
#include <algorithm>

#include "export_internal.h"
#include "fa/audio/analysis.h"
#include "fa/audio/convert.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"

namespace fa::export_detail {

namespace {

// The QOA file for the WAV `wav` (bytes of `path`): from the cache, or encoded and cached. Empty with a warning when the
// WAV cannot be converted (the WAV then ships as it is).
std::vector<std::uint8_t> qoa_twin(ExportAssets& ea, const std::string& path, const std::vector<std::uint8_t>& wav, stdfs::path& cached) {
    cached = ea.cacheDir / "audio" / (sha256_hex(wav.data(), wav.size()) + ".qoa");
    if (auto hit = fs::read_bytes(cached.generic_string()); hit && !hit->empty()) return *hit;
    auto skip = [&](const std::string& why) {
        ea.report.warnings.push_back(path + " was not converted to QOA, so it ships as a WAV: " + why);
        return std::vector<std::uint8_t>{};
    };
    auto encoded = encode_qoa(wav);
    if (!encoded) return skip(encoded.error().message + (encoded.error().hint.empty() ? "" : " (" + encoded.error().hint + ")"));
    std::string e;
    if (!write_file(cached, std::string_view(reinterpret_cast<const char*>(encoded->data()), encoded->size()), &e)) return skip(e);
    return *encoded;
}

}  // namespace

Result<void> convert_audio(ExportAssets& ea) {
    tooling_detail::ProjectRootScope root(ea.project.dir);  // import settings and sound files are read through the VFS
    std::vector<std::string> sounds;  // a copy: the steps below add and remove entries of ea.files
    for (const std::string& f : ea.files)
        if (tooling_detail::is_audio_file(f)) sounds.push_back(f);
    for (const std::string& path : sounds) {
        const Json settings = assets::import_settings(path);
        const bool normalize = tooling_detail::bool_setting(settings, "normalize");
        const bool convert = tooling_detail::string_setting(settings, "convert", "") == "qoa";
        if (!convert && !normalize) continue;
        auto file = read_audio_file(path);
        if (!file) {
            ea.report.warnings.push_back(path + " could not be read, so its audio import settings were not applied: " + file.error().message);
            continue;
        }
        const Json entry = assets::entry(path);
        std::vector<std::uint8_t> shipped = file->bytes;
        std::string shippedExt = fs::extension(path);
        if (convert && shippedExt == ".wav") {
            stdfs::path cached;
            std::vector<std::uint8_t> qoa = qoa_twin(ea, path, file->bytes, cached);
            if (!qoa.empty()) {
                ea.replace(path, path + ".qoa", cached);
                shipped = std::move(qoa);
                shippedExt = ".qoa";
            }
        } else if (convert && entry.value("import", Json::object()).contains("convert")) {
            ea.report.warnings.push_back(path + ": convert \"qoa\" only applies to WAV files, so it ships as it is (lossy files are never converted).");
        }
        if (!normalize) continue;

        Json record;  // what describes the bytes that ship
        if (shippedExt == fs::extension(path) && entry.contains("analysis"))
            if (auto fresh = cached_loudness(entry["analysis"], shipped)) record = loudness_analysis(*fresh, shipped);
        if (record.is_null()) {
            auto measured = measure_loudness(shipped, shippedExt);
            if (!measured) {
                ea.report.warnings.push_back(path + " has normalize on but its loudness could not be measured, so it plays unchanged: " +
                                             measured.error().message);
                continue;
            }
            record = loudness_analysis(*measured, shipped);
        }
        Json& all = ea.manifest["assets"];
        if (!all.is_object()) all = Json::object();
        Json& analysis = all[path]["analysis"];
        if (!analysis.is_object()) analysis = Json::object();
        analysis.update(record);
    }
    return {};
}

}  // namespace fa::export_detail
