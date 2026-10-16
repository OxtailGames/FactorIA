#include "fa/tooling/icons.h"

#include <algorithm>
#include <cmath>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

std::string where(const std::string& pointer) { return std::string(kProjectFileName) + "#" + pointer; }

// `icon` as a size x size image, whatever its shape: centered on a transparent square.
Image square(const Image& icon, int size) { return fit_image(icon, size, 1.0f, Color::clear()); }

void put_u16le(std::vector<std::uint8_t>& v, std::uint32_t x) {
    v.push_back(std::uint8_t(x & 0xff));
    v.push_back(std::uint8_t((x >> 8) & 0xff));
}
void put_u32le(std::vector<std::uint8_t>& v, std::uint32_t x) {
    for (int i = 0; i < 4; ++i) v.push_back(std::uint8_t((x >> (8 * i)) & 0xff));
}
void put_u32be(std::vector<std::uint8_t>& v, std::uint32_t x) {
    for (int i = 3; i >= 0; --i) v.push_back(std::uint8_t((x >> (8 * i)) & 0xff));
}

Result<void> write_bytes_file(const std::string& path, const std::vector<std::uint8_t>& bytes) {
    std::string err;
    const std::string_view data(reinterpret_cast<const char*>(bytes.data()), bytes.size());
    if (!tooling_detail::write_file(stdfs::path(path), data, &err)) return make_error("Cannot write '" + path + "': " + err, "Check that the folder is writable.");
    return {};
}

Result<void> write_text_file(const std::string& path, const std::string& text) {
    std::string err;
    if (!tooling_detail::write_file(stdfs::path(path), text, &err)) return make_error("Cannot write '" + path + "': " + err, "Check that the folder is writable.");
    return {};
}

Result<void> write_png_file(const std::string& path, const Image& img) {
    auto png = encode_png(img);
    if (png.empty()) return make_error("PNG encoding failed for '" + path + "'");
    return write_bytes_file(path, png);
}

// Multiplies the alpha of every pixel by a circle inscribed in the image (one pixel of antialiasing at the rim).
void mask_circle(Image& img) {
    const double r = double(std::min(img.width, img.height)) / 2.0;
    const double cx = double(img.width) / 2.0, cy = double(img.height) / 2.0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const double d = std::hypot(double(x) + 0.5 - cx, double(y) + 0.5 - cy);
            const double cover = std::clamp(r - d + 0.5, 0.0, 1.0);
            std::uint8_t& a = img.rgba[(std::size_t(y) * img.width + x) * 4 + 3];
            a = std::uint8_t(double(a) * cover + 0.5);
        }
}

}  // namespace

// ===========================================================================
// Loading
// ===========================================================================

Result<Image> load_icon_image(const std::string& projectDir, const std::string& relPath, const std::string& pointer,
                              std::vector<ExportSettingsIssue>* warnings, int recommendedSize) {
    if (relPath.empty())
        return make_error(where(pointer) + ": no icon file is set",
                          "Set it to a square PNG or JPG inside the project, 1024x1024 recommended, e.g. \"assets/icon.png\".");
    const stdfs::path full = stdfs::path(projectDir.empty() ? "." : projectDir) / relPath;
    std::error_code ec;
    if (!stdfs::exists(full, ec)) {
        std::string hint = "Create the file or fix the path (project-relative, forward slashes); a square PNG or JPG, 1024x1024 recommended.";
        const stdfs::path parent = full.parent_path();
        if (stdfs::is_directory(parent, ec)) {
            std::vector<std::string> names;
            for (const auto& e : stdfs::directory_iterator(parent, ec))
                if (e.is_regular_file(ec)) names.push_back(e.path().filename().string());
            const std::string m = closest_match(full.filename().string(), names);
            if (!m.empty()) hint = "Did you mean '" + (stdfs::path(relPath).parent_path() / m).generic_string() + "'?";
        }
        return make_error(where(pointer) + ": the icon file '" + relPath + "' does not exist", hint);
    }
    if (!stdfs::is_regular_file(full, ec))
        return make_error(where(pointer) + ": '" + relPath + "' is not a file", "Point it at an image file (PNG or JPG), not a folder.");
    auto bytes = tooling_detail::read_file(full);
    if (!bytes) return make_error(where(pointer) + ": cannot read '" + relPath + "'", "Check that the file is readable.");
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size());
    if (!img.ok())
        return make_error(where(pointer) + ": cannot use '" + relPath + "' as an icon: " + img.error().message,
                          "Use a PNG or JPG image (square, 1024x1024 recommended); re-export it from your image editor.");
    Image result = std::move(*img);
    const std::string size = std::to_string(result.width) + "x" + std::to_string(result.height);
    if (warnings) {
        if (result.width != result.height)
            warnings->push_back({pointer, "The icon '" + relPath + "' is " + size + ", not square: it is centered on a transparent square.",
                                 "Use a square image (1024x1024 recommended) so that nothing is left empty."});
        if (std::min(result.width, result.height) < recommendedSize)
            warnings->push_back({pointer, "The icon '" + relPath + "' is " + size + ", smaller than " + std::to_string(recommendedSize) + " px: it will look blurry on large icons.",
                                 "Use at least " + std::to_string(recommendedSize) + "x" + std::to_string(recommendedSize) + " (1024x1024 recommended)."});
    }
    if (result.width != result.height) result = square(result, std::max(result.width, result.height));
    return result;
}

Color icon_color_from_hex(const std::string& hex, Color fallback) {
    Color c;
    if (hex.size() == 7 && hex[0] == '#' && parse_color(hex, c)) return Color(c.r, c.g, c.b, 1.0f);
    return fallback;
}

// ===========================================================================
// macOS
// ===========================================================================

std::vector<std::uint8_t> make_icns(const Image& icon) {
    struct Entry {
        const char* type;
        int size;
    };
    static const Entry kEntries[] = {{"icp4", 16},  {"icp5", 32},  {"icp6", 64},  {"ic07", 128}, {"ic08", 256}, {"ic09", 512},
                                     {"ic10", 1024}, {"ic11", 32}, {"ic12", 64}, {"ic13", 256}, {"ic14", 512}};
    std::vector<std::uint8_t> body;
    // The same size appears twice (32 as icp5 and ic11, ...): encode each size once.
    std::vector<std::pair<int, std::vector<std::uint8_t>>> cache;
    for (const Entry& e : kEntries) {
        auto it = std::find_if(cache.begin(), cache.end(), [&](const auto& c) { return c.first == e.size; });
        if (it == cache.end()) {
            cache.emplace_back(e.size, encode_png(square(icon, e.size)));
            it = cache.end() - 1;
        }
        const std::vector<std::uint8_t>& png = it->second;
        body.insert(body.end(), e.type, e.type + 4);
        put_u32be(body, std::uint32_t(8 + png.size()));
        body.insert(body.end(), png.begin(), png.end());
    }
    std::vector<std::uint8_t> out = {'i', 'c', 'n', 's'};
    put_u32be(out, std::uint32_t(8 + body.size()));
    out.insert(out.end(), body.begin(), body.end());
    return out;
}

// ===========================================================================
// Windows
// ===========================================================================

const std::vector<int>& windows_icon_sizes() {
    static const std::vector<int> sizes = {16, 24, 32, 48, 64, 128, 256};
    return sizes;
}

std::vector<std::uint8_t> icon_bmp_entry(const Image& icon, int size) {
    const Image img = square(icon, size);
    const std::size_t maskRow = std::size_t((size + 31) / 32) * 4;
    const std::size_t xorBytes = std::size_t(size) * size * 4, andBytes = maskRow * std::size_t(size);
    std::vector<std::uint8_t> out;
    out.reserve(40 + xorBytes + andBytes);
    put_u32le(out, 40);                          // biSize
    put_u32le(out, std::uint32_t(size));         // biWidth
    put_u32le(out, std::uint32_t(size) * 2);     // biHeight: pixels + AND mask
    put_u16le(out, 1);                           // biPlanes
    put_u16le(out, 32);                          // biBitCount
    put_u32le(out, 0);                           // biCompression = BI_RGB
    put_u32le(out, std::uint32_t(xorBytes + andBytes));  // biSizeImage
    put_u32le(out, 0);                           // biXPelsPerMeter
    put_u32le(out, 0);                           // biYPelsPerMeter
    put_u32le(out, 0);                           // biClrUsed
    put_u32le(out, 0);                           // biClrImportant
    for (int y = size - 1; y >= 0; --y)          // bottom-up BGRA
        for (int x = 0; x < size; ++x) {
            const std::uint8_t* p = &img.rgba[(std::size_t(y) * size + x) * 4];
            out.push_back(p[2]);
            out.push_back(p[1]);
            out.push_back(p[0]);
            out.push_back(p[3]);
        }
    for (int y = size - 1; y >= 0; --y) {        // bottom-up AND mask, 1 = transparent
        std::vector<std::uint8_t> row(maskRow, 0);
        for (int x = 0; x < size; ++x)
            if (img.rgba[(std::size_t(y) * size + x) * 4 + 3] == 0) row[std::size_t(x) / 8] |= std::uint8_t(0x80 >> (x % 8));
        out.insert(out.end(), row.begin(), row.end());
    }
    return out;
}

std::vector<std::uint8_t> make_ico_bmp(const Image& icon, const std::vector<int>& sizes) {
    std::vector<std::vector<std::uint8_t>> entries;
    for (int s : sizes) entries.push_back(icon_bmp_entry(icon, s));
    std::vector<std::uint8_t> out;
    put_u16le(out, 0);                           // reserved
    put_u16le(out, 1);                           // type: icon
    put_u16le(out, std::uint32_t(sizes.size()));
    std::uint32_t offset = 6 + 16 * std::uint32_t(sizes.size());
    for (std::size_t i = 0; i < sizes.size(); ++i) {
        out.push_back(sizes[i] >= 256 ? 0 : std::uint8_t(sizes[i]));  // width (0 = 256)
        out.push_back(sizes[i] >= 256 ? 0 : std::uint8_t(sizes[i]));  // height
        out.push_back(0);                        // colour count
        out.push_back(0);                        // reserved
        put_u16le(out, 1);                       // planes
        put_u16le(out, 32);                      // bits per pixel
        put_u32le(out, std::uint32_t(entries[i].size()));
        put_u32le(out, offset);
        offset += std::uint32_t(entries[i].size());
    }
    for (const auto& e : entries) out.insert(out.end(), e.begin(), e.end());
    return out;
}

// ===========================================================================
// Android
// ===========================================================================

namespace {

struct Density {
    const char* name;
    int legacy;  // launcher icon, 48dp
    int layer;   // adaptive layer, 108dp
};
constexpr Density kDensities[] = {{"mdpi", 48, 108}, {"hdpi", 72, 162}, {"xhdpi", 96, 216}, {"xxhdpi", 144, 324}, {"xxxhdpi", 192, 432}};

}  // namespace

Result<AdaptiveIcon> load_adaptive_icon(const std::string& projectDir, const AndroidExportSettings& settings,
                                        std::vector<ExportSettingsIssue>* warnings) {
    AdaptiveIcon a;
    const std::string base = "/export/android/adaptiveIcon";
    const AndroidAdaptiveIconSettings& s = settings.adaptiveIcon;
    constexpr int kLayerSize = 432;
    if (!s.foreground.empty()) {
        auto img = load_icon_image(projectDir, s.foreground, base + "/foreground", warnings, kLayerSize);
        if (!img.ok()) return img.error();
        a.foreground = std::move(*img);
    }
    if (!s.background.empty() && s.background[0] != '#') {
        auto img = load_icon_image(projectDir, s.background, base + "/background", warnings, kLayerSize);
        if (!img.ok()) return img.error();
        a.backgroundImage = std::move(*img);
    } else if (!s.background.empty()) {
        a.backgroundColor = s.background;
    }
    if (!s.monochrome.empty()) {
        auto img = load_icon_image(projectDir, s.monochrome, base + "/monochrome", warnings, kLayerSize);
        if (!img.ok()) return img.error();
        a.monochrome = std::move(*img);
    }
    return a;
}

Result<void> write_android_icons(const std::string& resDir, const Image& icon, const AdaptiveIcon& adaptive) {
    if (icon.empty()) return make_error("Cannot write the Android icons: the icon image is empty", "Load it with load_icon_image first.");
    const stdfs::path res(resDir);
    auto mipmap = [&](const char* density, const char* file) { return (res / (std::string("mipmap-") + density) / file).string(); };

    for (const Density& d : kDensities) {
        Image legacy = square(icon, d.legacy);
        if (auto r = write_png_file(mipmap(d.name, "ic_launcher.png"), legacy); !r.ok()) return r;
        mask_circle(legacy);
        if (auto r = write_png_file(mipmap(d.name, "ic_launcher_round.png"), legacy); !r.ok()) return r;

        const Image fg = adaptive.foreground ? square(*adaptive.foreground, d.layer)
                                             : fit_image(icon, d.layer, 66.0f / 108.0f, Color::clear());
        if (auto r = write_png_file(mipmap(d.name, "ic_launcher_foreground.png"), fg); !r.ok()) return r;
        if (adaptive.backgroundImage)
            if (auto r = write_png_file(mipmap(d.name, "ic_launcher_background.png"), square(*adaptive.backgroundImage, d.layer)); !r.ok()) return r;
        if (adaptive.monochrome)
            if (auto r = write_png_file(mipmap(d.name, "ic_launcher_monochrome.png"), square(*adaptive.monochrome, d.layer)); !r.ok()) return r;
    }

    std::string xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                      "<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n";
    xml += adaptive.backgroundImage ? "    <background android:drawable=\"@mipmap/ic_launcher_background\"/>\n"
                                    : "    <background android:drawable=\"@color/ic_launcher_background\"/>\n";
    xml += "    <foreground android:drawable=\"@mipmap/ic_launcher_foreground\"/>\n";
    if (adaptive.monochrome) xml += "    <monochrome android:drawable=\"@mipmap/ic_launcher_monochrome\"/>\n";
    xml += "</adaptive-icon>\n";
    for (const char* name : {"ic_launcher.xml", "ic_launcher_round.xml"})
        if (auto r = write_text_file((res / "mipmap-anydpi-v26" / name).string(), xml); !r.ok()) return r;

    if (!adaptive.backgroundImage) {
        std::string color = adaptive.backgroundColor;
        if (color.size() != 7 || color[0] != '#') color = "#FFFFFF";
        const std::string values = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n    <color name=\"ic_launcher_background\">" + color +
                                   "</color>\n</resources>\n";
        if (auto r = write_text_file((res / "values" / "ic_launcher_background.xml").string(), values); !r.ok()) return r;
    }
    return {};
}

// ===========================================================================
// iOS
// ===========================================================================

Result<void> write_ios_app_icon(const std::string& xcassetsDir, const Image& icon, Color background) {
    if (icon.empty()) return make_error("Cannot write the iOS icon: the icon image is empty", "Load it with load_icon_image first.");
    const stdfs::path root(xcassetsDir);
    const Json info = Json::object({{"author", "xcode"}, {"version", 1}});
    if (auto r = write_text_file((root / "Contents.json").string(), dump_json(Json::object({{"info", info}}))); !r.ok()) return r;

    Json image = Json::object({{"filename", "AppIcon-1024.png"}, {"idiom", "universal"}, {"platform", "ios"}, {"size", "1024x1024"}});
    Json contents = Json::object({{"images", Json::array({image})}, {"info", info}});
    const stdfs::path set = root / "AppIcon.appiconset";
    if (auto r = write_text_file((set / "Contents.json").string(), dump_json(contents)); !r.ok()) return r;

    background.a = 1.0f;
    const Image flat = fit_image(icon, 1024, 1.0f, background);
    return write_bytes_file((set / "AppIcon-1024.png").string(), encode_png_rgb(flat));
}

// ===========================================================================
// Linux
// ===========================================================================

Result<void> write_png_icon(const std::string& path, const Image& icon, int size) {
    if (icon.empty() || size < 1) return make_error("Cannot write the PNG icon '" + path + "': the icon image is empty or the size is below 1", "Load the icon with load_icon_image first.");
    return write_png_file(path, square(icon, size));
}

}  // namespace fa
