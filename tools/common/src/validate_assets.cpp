// The asset checks of project.validate that look at the files: texture size, the weight of what ships, and textures that
// Sprites draw with a background that should be transparent. Read only; textures are measured from their file header.
// (The checks of assets.json itself are in validate.cpp.)
#include <algorithm>
#include <cstring>
#include <fstream>
#include <format>

#include <stb_image.h>  // stbi_info_from_memory; the implementation is compiled into fa_core (image.cpp)

#include "assets_internal.h"
#include "export_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/validate.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr std::uint64_t kMiB = std::uint64_t(1) << 20;
constexpr int kMaxTextureSide = 4096;        // a texture over this cannot be sampled by many mobile GPUs
constexpr int kMobileTextureSide = 2048;     // what low-end phones handle comfortably
constexpr std::uint64_t kBigFile = 20 * kMiB;

// The store limits in one place. The numbers were checked on 2026-10-16:
//   Google Play: 500 MB compressed download for the base module of an app bundle (older documents still say 200 MB):
//     https://support.google.com/googleplay/android-developer/answer/9859372
//   App Store: an iPhone asks the player before downloading an app of more than 200 MB over cellular data
//     (Settings > App Store > App Downloads), so bigger apps lose impatient players; the hard limit is 4 GB uncompressed:
//     https://developer.apple.com/help/app-store-connect/reference/maximum-build-file-sizes/
struct StoreLimit {
    const char* platform;
    std::uint64_t bytes;
    const char* what;
};
constexpr StoreLimit kStoreLimits[] = {
    {"android", 500 * kMiB, "the 500 MB Google Play allows for the base module of an app"},
    {"ios", 200 * kMiB, "the 200 MB above which an iPhone asks the player before downloading over cellular data"},
    {"ios", 4096 * kMiB, "the 4 GB the App Store allows for an uncompressed app"},
};

std::string megabytes(std::uint64_t bytes) { return std::format("{:.1f} MB", double(bytes) / double(kMiB)); }

// The pixel size of an image file from its first bytes (a PNG header is 33 bytes, a JPEG's start rarely passes a few KB).
bool image_size(const stdfs::path& file, int& width, int& height) {
    std::ifstream in(fs::os_path(file), std::ios::binary);
    std::vector<char> head(256 * 1024);
    in.read(head.data(), std::streamsize(head.size()));
    int components = 0;
    return in.gcount() > 0 && stbi_info_from_memory(reinterpret_cast<const stbi_uc*>(head.data()), int(in.gcount()), &width, &height, &components);
}

}  // namespace

void check_shipped_assets(const std::string& projectDir, std::vector<ValidationIssue>& warnings) {
    std::string feedbackFile = "ENGINE_FEEDBACK.json";
    std::vector<std::string> platforms;
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / "factoria.json")) {
        auto parsed = parse_json(*text, "factoria.json");
        if (parsed.ok() && parsed->is_object()) {
            if (parsed->contains("feedbackFile") && (*parsed)["feedbackFile"].is_string()) feedbackFile = (*parsed)["feedbackFile"].get<std::string>();
            if (parsed->contains("platforms") && (*parsed)["platforms"].is_array())
                for (const Json& p : (*parsed)["platforms"])
                    if (p.is_string()) platforms.push_back(to_lower(p.get<std::string>()));
        }
    }
    const auto targets = [&](const char* platform) { return std::find(platforms.begin(), platforms.end(), platform) != platforms.end(); };
    const bool mobile = targets("android") || targets("ios");

    std::uint64_t total = 0;
    for (const std::string& rel : export_detail::list_game_files(projectDir, feedbackFile)) {
        std::error_code ec;
        const std::uint64_t bytes = stdfs::file_size(stdfs::path(projectDir) / rel, ec);
        if (ec) continue;
        total += bytes;
        const auto kind = assets::kind_of(rel);
        if (bytes > kBigFile) {
            const bool audio = kind == assets::AssetKind::Audio, texture = kind == assets::AssetKind::Texture;
            warnings.push_back({rel, "", std::format("This file is {} and ships in the game.", megabytes(bytes)),
                                audio     ? "Convert it to OGG (or QOA, import setting \"convert\"), or stream it if it is music; docs/ASSETS.md, \"Import settings\"."
                                : texture ? "Scale it down, and compress it (import setting \"compression\"); docs/ASSETS.md, \"Import settings\"."
                                          : "Leave it out of the game, or make it smaller; every shipped file adds to the download (docs/ASSETS.md)."});
        }
        int width = 0, height = 0;
        if (kind != assets::AssetKind::Texture || !image_size(stdfs::path(projectDir) / rel, width, height)) continue;
        const int side = std::max(width, height);
        if (side > kMaxTextureSide)
            warnings.push_back({rel, "", std::format("This texture is {}x{} px: many mobile GPUs cannot sample a texture over {} px on a side.", width, height, kMaxTextureSide),
                                "Scale it down, or cut it into tiles of 2048 px or less (a 4096x4096 RGBA texture also takes 64 MB of GPU memory)."});
        else if (mobile && side > kMobileTextureSide)
            warnings.push_back({rel, "", std::format("This texture is {}x{} px, over {} px, and factoria.json lists a mobile platform: low-end phones struggle with it.", width, height, kMobileTextureSide),
                                "Scale it down to 2048 px or less, or cut it into tiles."});
    }
    for (const StoreLimit& limit : kStoreLimits)
        if (targets(limit.platform) && total > limit.bytes)
            warnings.push_back({"factoria.json", "/platforms",
                                std::format("The files that ship add up to {} for {}, over {}.", megabytes(total), limit.platform, limit.what),
                                "This is before the export's texture compression and audio conversion (`factoria export` reports the real size). Compress textures, "
                                "convert audio to OGG or QOA, stream music and remove files the game does not use; docs/ASSETS.md."});
}

void check_sprite_textures(const std::string& projectDir, const std::set<std::string>& textures, std::vector<ValidationIssue>& warnings) {
    for (const std::string& rel : textures) {
        const stdfs::path file = stdfs::path(projectDir) / rel;
        std::error_code ec;
        if (!stdfs::is_regular_file(file, ec)) continue;  // a missing file is reported as a missing asset
        auto image = load_image(file);
        if (!image.ok()) continue;
        const auto& px = image->rgba;
        bool visible = false, varied = false;
        for (std::size_t i = 0; i < px.size() && !(visible && varied); i += 4) {
            visible = visible || px[i + 3] != 0;
            varied = varied || std::memcmp(&px[i], &px[0], 4) != 0;
        }
        if (!visible) {
            warnings.push_back({rel, "", "A Sprite draws this texture, and every pixel of it is fully transparent: nothing will show.",
                                "Regenerate or re-export the image, or point the Sprite at another texture."});
            continue;
        }
        const auto color = opaque_corner_color(*image);
        if (color && varied)
            warnings.push_back({rel, "", std::format("A Sprite draws this texture, and its four corners are the same opaque color (#{:02x}{:02x}{:02x}): probably a background that should be transparent.",
                                                     (*color)[0], (*color)[1], (*color)[2]),
                                "Make the background transparent with assets.slice_sheet {\"path\":\"" + rel + "\",\"background\":\"auto\"} (it writes " +
                                    (stdfs::path(rel).parent_path() / (stdfs::path(rel).stem().string() + "_sheet.png")).generic_string() +
                                    "; point the Sprite at it), or regenerate the image with transparent: true. Ignore this if the opaque edge is intended "
                                    "(a backdrop, a panel)."});
    }
}

}  // namespace fa::assets_detail
