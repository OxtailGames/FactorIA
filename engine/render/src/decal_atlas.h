// The texture atlas of the projected decals (M73.5b; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Decals"), the CPU half. Free of any GPU
// call so tests can look at it: the albedo and normal textures of every Decal are packed into ONE RGBA8 image (view 27, fa_decal_atlas) that
// the mesh fragment shader samples with textureLod (shaders/light_data.glsl, block fa_decals).
//
// The layout is deterministic: the textures are sorted by height (tallest first), width and path, shelf-packed into the smallest square power of
// two that holds them, so the same set of paths and sizes always gives the same rectangles, whatever order the decals were made in. Every tile has
// a gutter of kDecalGutter pixels around it that repeats its edge pixels and every cell starts on a multiple of 16 pixels, so a bilinear read at
// any mip level up to kDecalMaxLod near the edge of a tile never mixes in a neighbour. When the tiles do not fit the largest allowed atlas the
// biggest ones are halved (down to kDecalMinSide), and as the last resort the smallest are left out; both are reported to the caller by name.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/types.h"

namespace fa::render {

inline constexpr int kDecalTileMaxSide = 1024;   // a texture is scaled down to at most this many pixels on its longer side
inline constexpr int kDecalMinSide = 16;         // the smallest a tile is shrunk to when the atlas is full
inline constexpr int kDecalGutter = 16;          // pixels around a tile that repeat its edge
inline constexpr int kDecalMaxLod = 4;           // the highest mip level the shader reads (2^4 = the gutter)
inline constexpr int kDecalAtlasMaxSide = 4096;  // the largest atlas side (the GPU's own limit may be lower)
inline constexpr std::size_t kDecalAtlasMaxBytes = std::size_t(96) << 20;  // RGBA8 level 0 plus the mips of the largest atlas is 85 MB
inline constexpr std::size_t kMaxDecalTextures = 512;                      // two per decal (albedo and normal) of the 256 decals

// A texture to pack: its path and its size in pixels (before any scaling).
struct DecalTexture {
    std::string path;
    int width = 0, height = 0;
};

// Where a texture went: the rectangle of its pixels (inner, without the gutter) in the atlas, in pixels.
struct DecalTile {
    std::string path;
    int x = 0, y = 0, w = 0, h = 0;
    bool shrunk = false;  // smaller than the texture scaled to kDecalTileMaxSide
};

struct DecalAtlasLayout {
    int width = 0, height = 0;           // 0 when no texture fits (or none was asked for)
    std::vector<DecalTile> tiles;        // the textures that were placed, in path order
    std::vector<std::string> dropped;    // the paths left out because the atlas was full, in path order
    const DecalTile* find(const std::string& path) const;
};

// The tile size of a texture: scaled (keeping the ratio) so its longer side is at most kDecalTileMaxSide, never below 1 pixel.
void decal_tile_size(int width, int height, int& outW, int& outH);

// Packs the textures (duplicated paths count once; the first size wins). `maxSide` is the largest atlas side allowed (a power of two, at
// most kDecalAtlasMaxSide); the atlas never needs more than kDecalAtlasMaxBytes (checked in 64 bits before anything is allocated).
DecalAtlasLayout layout_decal_atlas(std::vector<DecalTexture> textures, int maxSide);

// How the pixels of a project texture are found: its size without decoding it, and the decoded image. The renderer's own supplies the file
// readers (twins, atlases of an export), tests supply their own.
struct DecalSource {
    std::function<Result<ImageSize>(const std::string&)> size;
    std::function<Result<Image>(const std::string&)> load;
};
// The source that reads the project's files (the texture file, its .ktx2 twin, or the atlas an export packed it into).
DecalSource project_decal_source();

struct DecalAtlasImage {
    DecalAtlasLayout layout;
    Image image;                         // RGBA8, layout.width x layout.height (empty when nothing was placed)
    std::vector<std::string> failed;     // "<path>: <why>" of the textures that could not be read (left out of the layout)
};
// Reads the textures named by `paths` (sorted, distinct), lays them out and fills the atlas: every tile scaled with resize_image, its gutter
// repeating the edge. A texture that cannot be read is listed in `failed` and has no tile.
DecalAtlasImage build_decal_atlas(const std::vector<std::string>& paths, const DecalSource& source, int maxSide);

}  // namespace fa::render
