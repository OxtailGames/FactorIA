// Game icons: one square image (factoria.json "icon", docs/EXPORTING.md "Platform settings") becomes what each platform
// asks for. Pure functions over fa::Image that write files or return bytes; the export calls them and decides where
// the results go.
//
//   .icns (macOS)            make_icns                                  PNG payloads, 16 .. 1024 and the @2x sizes
//   .ico / RT_ICON (Windows) make_ico_bmp, icon_bmp_entry               uncompressed 32-bit BMP entries with an AND mask
//   Android                  write_android_icons                        mipmap PNGs, adaptive icon XML, background colour
//   iOS                      write_ios_app_icon                         Assets.xcassets/AppIcon.appiconset, opaque 1024
//   Linux                    write_png_icon                             one PNG
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/types.h"
#include "fa/tooling/export_settings.h"

namespace fa {

// Icons smaller than this (in either direction) get a warning: they look blurry on large icons.
inline constexpr int kRecommendedIconSize = 512;

// Reads <projectDir>/<relPath> and returns it as a SQUARE image (a non-square picture is centered on a transparent
// square canvas of its longer side). `pointer` is the JSON pointer of the setting ("/icon", "/export/android/icon"),
// used in messages. Errors: the file is missing (with a "did you mean" for a similar file name in the same folder),
// is not a file, or cannot be decoded. Warnings (appended to `warnings` when given): not square, or smaller than
// `recommendedSize` (default kRecommendedIconSize) in either direction. ExportSettingsIssue::to_string() prints one.
Result<Image> load_icon_image(const std::string& projectDir, const std::string& relPath, const std::string& pointer,
                              std::vector<ExportSettingsIssue>* warnings = nullptr, int recommendedSize = kRecommendedIconSize);

// "#RRGGBB" -> an opaque Color; `fallback` for anything else.
Color icon_color_from_hex(const std::string& hex, Color fallback = Color::white());

// ---- macOS ----------------------------------------------------------------------------------------------------------

// An .icns file with PNG payloads: icp4 16, icp5 32, icp6 64, ic07 128, ic08 256, ic09 512, ic10 1024, and the @2x
// variants ic11 (32 = 16@2x), ic12 (64 = 32@2x), ic13 (256 = 128@2x), ic14 (512 = 256@2x). The icon is resampled to
// every size. Layout: "icns", total length (big endian), then per entry its type, its length (with the 8 header bytes)
// and the PNG.
std::vector<std::uint8_t> make_icns(const Image& icon);

// ---- Windows --------------------------------------------------------------------------------------------------------

// The sizes of the placeholder icon of factoria_player.exe (and of the entries the export overwrites): 16, 24, 32, 48,
// 64, 128, 256.
const std::vector<int>& windows_icon_sizes();

// One RT_ICON payload (the image of an .ico entry): a BITMAPINFOHEADER (40 bytes, height = size * 2 because the AND
// mask follows the pixels), size * size bottom-up BGRA pixels, then the 1-bit AND mask (rows padded to 32 bits; a bit
// is set where the pixel is fully transparent). Its length is 40 + size * size * 4 + ((size + 31) / 32) * 4 * size, and
// depends on `size` alone, so an entry can be replaced in place by another icon of the same size.
std::vector<std::uint8_t> icon_bmp_entry(const Image& icon, int size);

// A complete .ico file: ICONDIR, one ICONDIRENTRY per size (256 is stored as 0), then the icon_bmp_entry of each.
std::vector<std::uint8_t> make_ico_bmp(const Image& icon, const std::vector<int>& sizes);

// ---- Android --------------------------------------------------------------------------------------------------------

// The adaptive icon layers (Android 8+): the foreground is a 108dp layer of which only the inner 72dp are always
// visible, so by default the icon is scaled into the 66dp safe zone (66/108 of the layer) over transparency.
struct AdaptiveIcon {
    std::optional<Image> foreground;       // the whole 108dp layer; none = derived from the icon
    std::string backgroundColor = "#FFFFFF";  // "#RRGGBB", used when backgroundImage is empty
    std::optional<Image> backgroundImage;  // replaces the colour
    std::optional<Image> monochrome;       // themed icons (Android 13); none = not written
};

// Loads the layers named by `settings.adaptiveIcon` (relative to projectDir; `background` is a colour when it starts
// with '#', else an image). Errors and warnings as load_icon_image (layers are recommended to be at least 432 px, the
// xxxhdpi size), with pointers under /export/android/adaptiveIcon.
Result<AdaptiveIcon> load_adaptive_icon(const std::string& projectDir, const AndroidExportSettings& settings,
                                        std::vector<ExportSettingsIssue>* warnings = nullptr);

// Writes the icons of an Android app into `resDir` (the project's app/src/main/res):
//   mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png and ic_launcher_round.png   48/72/96/144/192 px (round: circle mask)
//   mipmap-{...}/ic_launcher_foreground.png                                              108/162/216/324/432 px
//   mipmap-{...}/ic_launcher_background.png        only with a background image
//   mipmap-{...}/ic_launcher_monochrome.png        only with a monochrome layer
//   mipmap-anydpi-v26/ic_launcher.xml, ic_launcher_round.xml                             the <adaptive-icon>
//   values/ic_launcher_background.xml              only with a background colour (@color/ic_launcher_background)
// The manifest points at @mipmap/ic_launcher and @mipmap/ic_launcher_round.
Result<void> write_android_icons(const std::string& resDir, const Image& icon, const AdaptiveIcon& adaptive);

// ---- iOS ------------------------------------------------------------------------------------------------------------

// Writes <xcassetsDir>/Contents.json and <xcassetsDir>/AppIcon.appiconset/{Contents.json, AppIcon-1024.png}: one
// "universal" 1024x1024 icon (Xcode 14+ derives the other sizes). The App Store rejects icons with transparency, so
// the icon is composed over `background` and the PNG is written WITHOUT an alpha channel.
Result<void> write_ios_app_icon(const std::string& xcassetsDir, const Image& icon, Color background);

// ---- Linux ----------------------------------------------------------------------------------------------------------

// Writes `icon` as a size x size PNG at `path` (folders are created).
Result<void> write_png_icon(const std::string& path, const Image& icon, int size);

}  // namespace fa
