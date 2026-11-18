// The .cube 3D colour lookup table (Adobe / Resolve): what PostProcess.colorGradingLut names. CPU only: the renderer lays the table out
// as a 2D strip of slices (a 3D texture is not on every backend) and the final pass looks it up with a manual trilinear filter; this
// parser and `sample` are the same table and the same maths on the CPU, for the importer (assets.import checks the file), the tests and
// anything that has to look at a LUT.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// The smallest and largest table side a .cube file may have (LUT_3D_SIZE): 2 to 65 covers the 16, 17, 32, 33, 64 and 65 that grading
// tools export; 65^3 = 274625 colours (3.3 MB as floats).
inline constexpr int kCubeLutMinSize = 2;
inline constexpr int kCubeLutMaxSize = 65;
// A file larger than this is refused before it is parsed (a 65 side table is about 8 MB of text).
inline constexpr std::size_t kCubeLutMaxFileBytes = std::size_t(32) << 20;

struct CubeLut {
    int size = 0;       // colours per side (LUT_3D_SIZE)
    std::string title;  // TITLE, "" when the file has none
    std::vector<float>
        rgb;  // size^3 colours, 3 floats each, red varying fastest, then green, then blue (the file's order)

    // One entry; r, g, b in 0..size-1.
    Vec3 at(int r, int g, int b) const {
        const std::size_t i =
            (std::size_t(b) * std::size_t(size) + std::size_t(g)) * std::size_t(size) + std::size_t(r);
        return {rgb[i * 3], rgb[i * 3 + 1], rgb[i * 3 + 2]};
    }
    // The colour the table gives `c` (each channel clamped to 0..1 first), by trilinear interpolation between the 8 nearest entries.
    Vec3 sample(Vec3 c) const;
};

// Parses the text of a .cube file. `name` is only used in messages ("grade.cube:12: ..."). Every problem is an error that names the line
// and says how to fix it: a 1D table (LUT_1D_SIZE), a size outside kCubeLutMinSize..kCubeLutMaxSize, a DOMAIN other than 0..1, a row
// that is not three numbers, a missing LUT_3D_SIZE, or a wrong number of rows. Values outside 0..1 are kept as they are (the renderer
// clamps them when it makes the strip; `sample` does not).
Result<CubeLut> parse_cube_lut(std::string_view text, std::string_view name);

// The 2D strip the renderer uploads: the slices (one per blue value, each size x size) tiled `cols` across and `rows` down, in the
// order of blue. RGBA8, colours clamped to 0..1 and rounded, alpha 255. width = cols * size, height = rows * size.
struct CubeLutStrip {
    int size = 0, cols = 0, rows = 0;
    int width() const { return cols * size; }
    int height() const { return rows * size; }
    std::vector<std::uint8_t> rgba;
};
CubeLutStrip cube_lut_strip(const CubeLut& lut);

}  // namespace fa
