// Pixel tools for the screenshot commands: crop and enlarge a region, a contact sheet (filmstrip) of several pictures
// with frame labels, and the luminance profile of a picture along a line with the hard steps in it (seams, bands).
// Pure CPU code on fa::Image: nothing here draws or reads the screen.
#pragma once

#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/math.h"

namespace fa {

// The w x h pixels of `src` whose top-left corner is (x, y). The part outside `src` is transparent black, so the result
// is always exactly w x h. An empty image for an empty `src` or a size below 1.
Image crop_image(const Image& src, int x, int y, int w, int h);

// `src` enlarged (or shrunk) to width x height with nearest-neighbour sampling: no pixel is blended, so a one-pixel
// line stays a hard block when magnified. Empty for an empty `src` or a size below 1.
Image resize_nearest(const Image& src, int width, int height);

// Where a contact sheet puts its tiles.
struct SheetLayout {
    int columns = 0, rows = 0;
    int tileWidth = 0, tileHeight = 0;
    int gap = 0;                // pixels between tiles and around the border
    int width = 0, height = 0;  // the whole sheet
};
// `count` tiles of tileWidth x tileHeight in `columns` columns (0 = the number that makes the sheet closest to square,
// at most `count`), filled row by row. gap < 0 picks a gap that grows with the tile size.
SheetLayout sheet_layout(int count, int columns, int tileWidth, int tileHeight, int gap = -1);

// Tiles side by side on a dark background, row by row, each with its label (e.g. "f120 +8") in a box at its top-left
// corner, drawn with a built-in 5x7 font (digits, 'f', '+', '-', space; other characters are blank). The tiles should
// have the size of the first one; a different one is cut or padded to it. `labels` may be shorter than `tiles`.
// Empty when there are no tiles. The layout used is returned in `layoutOut` when given.
Image contact_sheet(const std::vector<Image>& tiles, const std::vector<std::string>& labels, int columns, int gap = -1,
                    SheetLayout* layoutOut = nullptr);

// ---- Luminance profile and step detection ----------------------------------------------------------------------

enum class ProfileChannel { Luminance, Red, Green, Blue };
// "luminance", "red", "green" or "blue"; an error with a hint otherwise.
Result<ProfileChannel> parse_profile_channel(std::string_view name);

// One value per pixel along the segment from -> to (pixel coordinates: the pixel (x, y) covers [x, x+1) x [y, y+1); a
// point outside the image takes the nearest edge pixel). The samples are spaced one pixel apart along the longer axis
// (the count is ceil(max(|dx|, |dy|)) + 1; a zero-length line gives one sample). Values are 0..255 on the sRGB bytes;
// Luminance uses the Rec. 709 weights (0.2126, 0.7152, 0.0722). `points` (when given) receives the sampled position of
// each value.
std::vector<float> profile_line(const Image& img, Vec2 from, Vec2 to, ProfileChannel channel,
                                std::vector<Vec2>* points = nullptr);

// A jump between samples `index` and `index + width`.
struct ProfileStep {
    int index = 0;  // the sample before the jump
    int width = 1;  // samples the jump takes (1..window)
    float from = 0, to = 0;
    float delta = 0;  // to - from; negative = darker
};
// Every place where the value changes by at least `threshold` (> 0) within `window` samples (>= 1). Scans from the
// start: at each sample it looks 1..window samples ahead and takes the largest change; when that reaches the threshold
// it is reported and the scan continues after it, so a jump is reported once and a staircase gives one step per riser.
// At most `maxSteps` are returned.
std::vector<ProfileStep> find_steps(const std::vector<float>& values, float threshold, int window = 2,
                                    std::size_t maxSteps = 200);

// ---- Normal maps made from a height field (M74) ----------------------------------------------------------------

// A tangent-space normal map (+X right, +Y up the picture, like Sprite.normalMap and glTF; a flat area is (0.5, 0.5, 1))
// from a height field of w x h values in 0..1 (row 0 = top). The slope of a pixel is the central difference of its
// neighbours (clamped at the border, or wrapped when `tile`), scaled so one `strength` looks the same at every
// resolution (512 px is the reference). `strength` 0 = a flat map. The same kernel `assets.generate_texture` writes its
// normal maps with. An empty image when w or h is below 1 or `height` holds fewer than w * h values.
Image normal_map_from_height(const std::vector<double>& height, int w, int h, bool tile, double strength);

// The height of a sprite for its generated normal map (Sprite.normalFrom sprite): a bevel from the distance to the
// transparent edge (a pixel `bevel` pixels inside the silhouette is at full height; bevel 0 picks a twelfth of the
// shorter side) plus the luminance of the picture times its alpha, so brighter and more opaque reads as higher.
// One value per pixel, 0..1. Deterministic: integer distances, no random numbers.
std::vector<double> sprite_height_field(const Image& sprite, int bevel = 0);

// The normal map of a sprite (sprite_height_field, then normal_map_from_height with clamped borders).
Image normal_map_from_sprite(const Image& sprite, double strength);

// The luminance of an RGBA pixel (`px` points at its R byte; alpha ignored), 0..1: Rec. 709 weights 0.2126, 0.7152 and
// 0.0722 on the 8-bit channels, divided by 255. The one formula of the height fields of the normal maps.
double luminance01(const std::uint8_t* px);

// The normal map of a grey image used as a height field (white = high; the luminance of the pixels, alpha ignored).
Image normal_map_from_height_image(const Image& grey, double strength);

}  // namespace fa
