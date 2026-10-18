// Texture steps of an export (texture import settings of assets.json): atlas packing, then GPU compression (KTX2).
//
// Atlases first: every texture whose `atlas` setting names a group is drawn into one image per group
// (assets/atlases/<group>.png), the original files are dropped from the export, and the shipped assets.json records
// where each one went (`packed`); the engine reads that to draw the same sprite from the atlas. Then every texture that
// ships (atlas pages included) is compressed to assets/<name>.ktx2 by its `compression` setting, or kept as it is.
#include <algorithm>
#include <map>
#include <mutex>
#include <set>

#include <encoder/basisu_comp.h>
#define STBRP_STATIC
#define STB_RECT_PACK_IMPLEMENTATION
#include <stb_rect_pack.h>

#include "export_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"

namespace fa::export_detail {
namespace {

constexpr int kAtlasPadding = 2;           // pixels around each packed texture, filled by repeating its edge pixels
constexpr int kMaxAtlasSideDesktop = 4096;
constexpr int kMaxAtlasSideMobile = 2048;  // what every GLES3 device samples (GL_MAX_TEXTURE_SIZE >= 2048)
// The size of a 4x4 block. A compressed texture must be a whole number of blocks wide and high: D3D11 and WebGPU refuse to
// create any other (the engine then transcodes the file to RGBA8, which is what the PNG would have been), so a texture of
// another size stays a PNG, and atlas pages are rounded up to it.
constexpr int kBlock = 4;
constexpr int kEtc1sQuality = 128;         // 1..255
// Part of every cache key: bump it when the encoder, the codec settings or the mip chain change.
constexpr const char* kCacheTag = "fa-textures-1 basisu-2.50";

std::string setting(const Json& s, const char* key) {
    const auto it = s.find(key);
    return it != s.end() && it->is_string() ? it->get<std::string>() : std::string();
}

std::string content_key(std::string_view what, const Image& img) {
    Sha256 h;
    h.update(std::string_view(kCacheTag));
    h.update(what);
    const int dims[2] = {img.width, img.height};
    h.update(dims, sizeof dims);
    h.update(img.rgba.data(), img.rgba.size());
    return h.finish_hex();
}

Result<Image> load_source(const Project& p, const std::string& rel) {
    auto data = read_file(p.dir / rel);
    if (!data) return err("cannot read the file");
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(data->data()), data->size());
    if (!img.ok()) return err(img.error().message);
    return std::move(*img);
}

// KTX2 file (Basis Universal) of `img` with its whole mip chain. UASTC is near lossless at 1 byte per pixel on the GPU;
// ETC1S makes smaller files with visible loss. Zstandard supercompression is off (the engine does not link zstd).
Result<std::string> encode_ktx2(const Image& img, bool uastc) {
    if (std::max(img.width, img.height) > int(basist::BASISU_MAX_SUPPORTED_TEXTURE_DIMENSION))
        return err("it is larger than " + std::to_string(basist::BASISU_MAX_SUPPORTED_TEXTURE_DIMENSION) + " pixels on a side");
    static std::once_flag once;
    std::call_once(once, [] { basisu::basisu_encoder_init(); });
    basisu::vector<basisu::image> mips;
    for (const Image& m : mip_chain(img)) mips.push_back(basisu::image(m.rgba.data(), m.width, m.height, 4));
    const std::uint32_t flags = basisu::cFlagKTX2 | basisu::cFlagSRGB | basisu::cFlagThreaded |
                                (uastc ? std::uint32_t(basisu::cPackUASTCLevelDefault) : std::uint32_t(kEtc1sQuality));
    std::size_t size = 0;
    void* out = basisu::basis_compress(uastc ? basist::basis_tex_format::cUASTC_LDR_4x4 : basist::basis_tex_format::cETC1S,
                                       mips, flags, 0.0f, &size);
    if (!out) return err("the Basis Universal encoder failed");
    std::string bytes(static_cast<const char*>(out), size);
    basisu::basis_free_data(out);
    return bytes;
}

// ---- atlases --------------------------------------------------------------------------------------------------

struct Member {
    std::string path;
    Image image;
};
struct Sprite {
    std::string path;
    int x = 0, y = 0, w = 0, h = 0;  // pixel rectangle of the texture in the page (padding excluded)
};
struct Page {
    std::string path;
    Image image;
    std::vector<Sprite> sprites;
};

// Draws `m` at (x, y) of `page` with kAtlasPadding pixels of its own edge repeated around it, so that filtering at the border of
// a sprite never reads the neighbour.
void blit_extruded(Image& page, const Image& m, int x, int y) {
    constexpr int pad = kAtlasPadding;
    for (int dy = -pad; dy < m.height + pad; ++dy) {
        for (int dx = -pad; dx < m.width + pad; ++dx) {
            const int sx = std::clamp(dx, 0, m.width - 1), sy = std::clamp(dy, 0, m.height - 1);
            const std::uint8_t* from = &m.rgba[(std::size_t(sy) * m.width + sx) * 4];
            std::uint8_t* to = &page.rgba[(std::size_t(y + dy) * page.width + (x + dx)) * 4];
            std::copy(from, from + 4, to);
        }
    }
}

// Packs `members` into as few pages as fit maxSide x maxSide. A member too large for any page is left out and reported.
std::vector<Page> pack_pages(const std::string& basePath, std::vector<Member> members, int maxSide,
                             std::vector<std::string>& warnings) {
    constexpr int pad = kAtlasPadding;
    std::vector<Page> pages;
    std::erase_if(members, [&](const Member& m) {
        const bool tooBig = m.image.width + 2 * pad > maxSide || m.image.height + 2 * pad > maxSide;
        if (tooBig)
            warnings.push_back("Texture " + m.path + " is " + std::to_string(m.image.width) + "x" + std::to_string(m.image.height) +
                               ", too large to share an atlas of at most " + std::to_string(maxSide) + "x" +
                               std::to_string(maxSide) + ": it ships on its own");
        return tooBig;
    });
    while (!members.empty()) {
        std::vector<stbrp_rect> rects(members.size());
        for (std::size_t i = 0; i < members.size(); ++i) {
            rects[i].id = int(i);
            rects[i].w = members[i].image.width + 2 * pad;
            rects[i].h = members[i].image.height + 2 * pad;
        }
        std::vector<stbrp_node> nodes;
        for (int side = 64;; side *= 2) {  // the first side that holds everything, else maxSide with what fits
            nodes.resize(side);
            stbrp_context ctx;
            stbrp_init_target(&ctx, side, side, nodes.data(), side);
            if (stbrp_pack_rects(&ctx, rects.data(), int(rects.size())) || side >= maxSide) break;
        }
        Page page;
        int usedW = 0, usedH = 0;
        for (const stbrp_rect& r : rects) {
            if (!r.was_packed) continue;
            usedW = std::max(usedW, r.x + r.w);
            usedH = std::max(usedH, r.y + r.h);
        }
        page.image.width = (usedW + kBlock - 1) / kBlock * kBlock;
        page.image.height = (usedH + kBlock - 1) / kBlock * kBlock;
        page.image.rgba.assign(std::size_t(page.image.width) * page.image.height * 4, 0);
        std::vector<Member> rest;
        for (const stbrp_rect& r : rects) {
            Member& m = members[std::size_t(r.id)];
            if (!r.was_packed) {
                rest.push_back(std::move(m));
                continue;
            }
            blit_extruded(page.image, m.image, r.x + pad, r.y + pad);
            page.sprites.push_back({m.path, r.x + pad, r.y + pad, m.image.width, m.image.height});
        }
        const std::string stem = basePath.substr(0, basePath.size() - 4);  // basePath ends in ".png"
        page.path = pages.empty() ? basePath : stem + "-" + std::to_string(pages.size() + 1) + ".png";
        pages.push_back(std::move(page));
        members = std::move(rest);
    }
    return pages;
}

// ---- shipping ---------------------------------------------------------------------------------------------------

struct Shipper {
    ExportAssets& ea;
    std::set<std::string> usedCache;       // cache files this export needs (the rest are pruned)
    std::vector<std::string> notBlockSized;  // textures asked to be compressed that are not a multiple of 4 pixels

    // The compression `path` gets: "none", "uastc" or "etc1s" (the setting, with "auto" resolved for the platform).
    std::string mode_of(const std::string& path) {
        std::string mode = setting(assets::import_settings(ea.manifest, path), "compression");
        if (mode == "none" || mode == "uastc" || mode == "etc1s") return mode;
        if (!mode.empty() && mode != "auto")
            ea.report.warnings.push_back("Texture " + path + ": compression \"" + mode +
                                         "\" is not one of auto, none, uastc, etc1s; \"auto\" is used");
        return ea.mobile() ? "uastc" : "none";
    }

    // Ships `path` (decoded as `img`) with compression `mode`. `added` is a file the export made (an atlas page): it ships
    // even when it is not compressed.
    void ship(const std::string& path, const std::string& mode, const Image& img, bool added) {
        // Smaller than one block (a 1x1 white pixel) saves nothing: it stays a PNG without a word.
        if (mode == "none" || std::min(img.width, img.height) < kBlock) return keep_png(path, img, added);
        if (img.width % kBlock != 0 || img.height % kBlock != 0) {
            notBlockSized.push_back(path);
            return keep_png(path, img, added);
        }
        const std::string name = "tex-" + content_key(mode, img) + kTextureTwinExtension;
        const stdfs::path cached = ea.cacheDir / name;
        usedCache.insert(name);
        std::error_code ec;
        if (!stdfs::exists(os_path(cached), ec)) {  // the name carries the hash of what it holds
            auto bytes = encode_ktx2(img, mode == "uastc");
            std::string why = bytes.ok() ? std::string() : bytes.error().message;
            if (bytes.ok() && !write_file(cached, *bytes, &why)) why = "cannot write " + generic(cached) + ": " + why;
            if (!why.empty()) {
                ea.report.warnings.push_back("Texture " + path + " could not be compressed (" + why +
                                             "), so it ships as a PNG. Set its import setting compression to "
                                             "\"none\" to silence this");
                return keep_png(path, img, added);
            }
        }
        ea.replace(added ? std::string() : path, path + kTextureTwinExtension, cached);
    }

    // An atlas page that is not compressed ships as a PNG; a texture that is not compressed ships as it is.
    void keep_png(const std::string& path, const Image& img, bool added) {
        if (!added) return;
        const std::string name = "atlas-" + content_key("png", img) + ".png";
        const stdfs::path cached = ea.cacheDir / name;
        usedCache.insert(name);
        std::error_code ec;
        if (!stdfs::exists(os_path(cached), ec)) {
            const std::vector<std::uint8_t> png = encode_png(img);
            std::string why;
            if (!write_file(cached, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &why)) {
                ea.report.warnings.push_back("Atlas " + path + " could not be written: " + why);
                return;
            }
        }
        ea.replace(std::string(), path, cached);
    }
};

}  // namespace

Result<void> convert_textures(ExportAssets& ea) {
    const std::string icon = ea.project.settings.icon_for(ea.platform);
    const std::string iconPath = icon.empty() ? icon : generic(stdfs::path(icon).lexically_normal());
    std::vector<std::string> textures;
    for (const std::string& f : ea.files)
        if (assets::kind_of(f) == assets::AssetKind::Texture && fs::extension(f) != kTextureTwinExtension && f != iconPath)
            textures.push_back(f);  // the icon is read from the project, never by the game
    if (textures.empty()) return {};

    Shipper shipper{ea};

    // 1. Atlas groups.
    std::map<std::string, std::vector<Member>> groups;
    for (const std::string& path : textures) {
        const std::string group = setting(assets::import_settings(ea.manifest, path), "atlas");
        if (group.empty()) continue;
        auto img = load_source(ea.project, path);
        if (!img.ok()) {
            ea.report.warnings.push_back("Texture " + path + " (atlas \"" + group + "\") could not be read (" +
                                         img.error().message + "), so it is not packed");
            continue;
        }
        groups[group].push_back({path, std::move(*img)});
    }
    const int maxSide = ea.small_textures() ? kMaxAtlasSideMobile : kMaxAtlasSideDesktop;
    std::set<std::string> packed;  // paths that live in an atlas now
    std::vector<Page> atlases;
    for (auto& [group, members] : groups) {
        const std::string slug = tooling_detail::slugify(group, '-');
        if (slug.empty()) {
            ea.report.warnings.push_back("Atlas group \"" + group + "\" has no letters or digits to name its file with, so "
                                         "its textures are not packed");
            continue;
        }
        std::vector<Page> pages = pack_pages("assets/atlases/" + slug + ".png", std::move(members), maxSide, ea.report.warnings);
        const bool taken = std::any_of(pages.begin(), pages.end(), [&](const Page& p) {
            return std::find(ea.files.begin(), ea.files.end(), p.path) != ea.files.end();
        });
        if (taken) {
            ea.report.warnings.push_back("Atlas group \"" + group + "\" would write assets/atlases/" + slug +
                                         ".png, which is a file of the project, so its textures are not packed. Rename the group");
            continue;
        }
        for (Page& page : pages) {
            Json& assets = ea.manifest["assets"];
            if (!assets.is_object()) assets = Json::object();
            for (const Sprite& s : page.sprites) {
                assets[s.path]["packed"] = Json::object({{"atlas", page.path}, {"rect", Json::array({s.x, s.y, s.w, s.h})}});
                packed.insert(s.path);
            }
            atlases.push_back(std::move(page));
        }
    }
    std::erase_if(ea.files, [&](const std::string& f) { return packed.contains(f); });
    for (const std::string& p : packed) ea.project.staged.erase(p);

    // 2. Compression of what ships: the atlas pages and the textures that are not in one.
    for (const Page& page : atlases) shipper.ship(page.path, shipper.mode_of(page.path), page.image, true);
    for (const std::string& path : textures) {
        if (packed.contains(path)) continue;  // in an atlas: not shipped on its own
        const std::string mode = shipper.mode_of(path);
        if (mode == "none") continue;  // ships as it is: not even decoded
        auto img = load_source(ea.project, path);
        if (!img.ok()) {
            ea.report.warnings.push_back("Texture " + path + " could not be read (" + img.error().message + "), so it ships as it is");
            continue;
        }
        shipper.ship(path, mode, *img, false);
    }

    if (!shipper.notBlockSized.empty()) {
        std::string list;
        for (std::size_t i = 0; i < shipper.notBlockSized.size() && i < 5; ++i) list += (i ? ", " : "") + shipper.notBlockSized[i];
        if (shipper.notBlockSized.size() > 5) list += ", ...";
        ea.report.warnings.push_back(std::to_string(shipper.notBlockSized.size()) + " texture(s) ship as PNG, uncompressed: " + list +
                                     ". GPU compression needs a width and height that are multiples of 4 pixels. Resize them, or "
                                     "set their import setting atlas to a group (atlas images are always sized for it)");
    }

    // 3. The cache keeps what this export used, but not what no longer matches any texture.
    std::error_code ec;
    for (stdfs::directory_iterator it(os_path(ea.cacheDir), ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if ((name.starts_with("tex-") || name.starts_with("atlas-")) && !shipper.usedCache.contains(name))
            stdfs::remove(it->path(), ec);
    }
    return {};
}

}  // namespace fa::export_detail
