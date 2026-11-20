// An HDRI (SceneSettings.environmentMap): the equirectangular Radiance .hdr that is the sky and the image-based lighting of a
// scene (M73-P3a-2). CPU only: this is what the importer (assets.import), `validate` and the renderer's asset cache all use, so
// a file the importer accepts is a file the renderer loads, with the same limits and the same words when it does not.
//
// What a file may be. The picture must be equirectangular (latitude-longitude): twice as wide as it is tall. A cube cross, a
// strip of six faces and a mirror-ball light probe are other layouts the renderer does not read; each gets an error that names
// it and says how to convert. At most kHdriMaxWidth x kHdriMaxWidth / 2 texels reach the GPU: a bigger picture is shrunk
// (box filter, deterministic) when it is loaded; the file itself may be up to the decode budget (hdri_decode_pixel_budget),
// and one above it is refused from its header, before any pixel memory is asked for.
//
// What the GPU receives (HdriImage). RGBA16F, 8 bytes a texel, with the whole mip chain (every level the box average of the
// one above, down to 1 x 1) so the sky is sampled without sparkle at any size on the screen. Why half floats and not RGBA32F: a
// 32-bit float texture is not filterable on GLES 3 and WebGL 2 without an extension, and a half float has the 11 bits of
// range the light needs. The values are made safe on the way:
//   - NaN and negative values become 0 (a file that has them is not an error: photographs of the sun do).
//   - A value above kHdriMaxValue (60000, just under the largest half float, 65504) is scaled down to it with its colour kept
//     (the three channels share the factor), so a sun of 1e6 stays the colour it was and the half float never overflows to
//     infinity. This happens AFTER the shrinking, so the energy of a small sun that is averaged away is not lost twice.
// The conversion never depends on the CPU: the same file gives the same bytes on every machine.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// The widest picture the GPU gets (4096 x 2048 = 64 MB as RGBA16F, 85 MB with its mips).
inline constexpr int kHdriMaxWidth = 4096;
// The narrowest: 8 x 4 is enough for the tiny fixtures of tests and for a flat colour.
inline constexpr int kHdriMinWidth = 8;
// The largest value a texel keeps (see above).
inline constexpr float kHdriMaxValue = 60000.0f;

// The most pixels a file may have to be decoded: 8192 x 4096 (an "8K" panorama, 400 MB of floats while it is shrunk) on a
// 64-bit target, 4096 x 2048 on a 32-bit one (WebAssembly, where 400 MB do not fit). Bigger is refused from the header.
std::uint64_t hdri_decode_pixel_budget();

// "" when a width x height picture is equirectangular and inside the limits; else what is wrong and how to fix it, with the
// layout it looks like (a cube cross, a strip, a light probe) named. `name` begins the sentence ("sky.hdr").
std::string hdri_layout_problem(int width, int height, std::string_view name);

// What a .hdr says about itself, checked (the header is read, the pixels are not).
struct HdriCheck {
    int width = 0, height = 0;                 // as in the file
    int gpuWidth = 0, gpuHeight = 0;           // what the GPU gets (the file shrunk to kHdriMaxWidth when wider)
    bool shrunk() const { return gpuWidth != width; }
    std::uint64_t gpuBytes = 0;                // RGBA16F with the mip chain
};
// Reads the header of a .hdr and applies every rule above: an error that names the file, what is wrong and the fix, for a
// header that is not Radiance's, a picture that is not equirectangular, one over the decode budget, or too small.
Result<HdriCheck> hdri_check(const std::uint8_t* data, std::size_t size, std::string_view name);

// The texels the GPU is given: mips[0] is gpuWidth x gpuHeight RGBA16F (half float bits, alpha 1), mips[k] half the size of
// mips[k - 1] (never below 1), down to 1 x 1.
struct HdriImage {
    int width = 0, height = 0;
    int sourceWidth = 0, sourceHeight = 0;  // the file's size
    std::vector<std::vector<std::uint16_t>> mips;
    std::uint64_t bytes() const {
        std::uint64_t total = 0;
        for (const auto& m : mips) total += std::uint64_t(m.size()) * 2u;
        return total;
    }
};
// Decodes, checks, shrinks, cleans and builds the mip chain. The error is hdri_check's, or the decoder's for a corrupt file.
Result<HdriImage> hdri_from_bytes(const std::uint8_t* data, std::size_t size, std::string_view name);
// The same through the file layer (project paths, packs).
Result<HdriImage> hdri_load(std::string_view path);

// Where a direction looks into an equirectangular picture: u across (0..1, left to right) and v down (0 = the top row), for
// the world direction (x, y, z) (y up, need not be normalised) when the environment is turned `rotationDegrees` around the up
// axis. Looking along -Z shows the middle of the picture (u = 0.5) and +X is to its right (u = 0.75); a positive rotation
// turns the environment counter-clockwise seen from above, so what was at +X ends up at -Z for 90. The shader
// (shaders/hdri.glsl) computes the same; the tests compare them.
void hdri_uv(float x, float y, float z, float rotationDegrees, float& u, float& v);

}  // namespace fa
