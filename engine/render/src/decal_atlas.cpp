#include "decal_atlas.h"

#include <algorithm>
#include <cstring>
#include <format>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/render/ktx2.h"

namespace fa::render {

namespace {

int round_up16(int v) { return (v + 15) & ~15; }

struct Cell {
    std::size_t tex = 0;  // index into the layout's tiles
    int w = 0, h = 0;     // the tile's pixels
    int cw = 0, ch = 0;   // the cell: the tile plus its gutter, a multiple of 16
    int x = 0, y = 0;     // the cell's place
};

// The order of the shelves: tallest first, then widest, then by path (so the result never depends on the order of the input).
bool cell_before(const Cell& a, const Cell& b, const std::vector<DecalTile>& t) {
    if (a.ch != b.ch) return a.ch > b.ch;
    if (a.cw != b.cw) return a.cw > b.cw;
    return t[a.tex].path < t[b.tex].path;
}

// Shelf packing of the cells (already sorted) into a side x side square; the cells get their places. `usedH` is the height reached.
bool shelf_pack(std::vector<Cell>& cells, int side, int& usedH) {
    int x = 0, y = 0, shelf = 0;
    for (Cell& c : cells) {
        if (c.cw > side || c.ch > side) return false;
        if (x + c.cw > side) {
            y += shelf;
            x = 0;
            shelf = 0;
        }
        if (y + c.ch > side) return false;
        c.x = x;
        c.y = y;
        x += c.cw;
        shelf = std::max(shelf, c.ch);
    }
    usedH = y + shelf;
    return true;
}

int pow2_at_least(int v, int lo) {
    int p = lo;
    while (p < v) p *= 2;
    return p;
}

}  // namespace

const DecalTile* DecalAtlasLayout::find(const std::string& path) const {
    const auto it = std::lower_bound(tiles.begin(), tiles.end(), path,
                                     [](const DecalTile& t, const std::string& p) { return t.path < p; });
    return it != tiles.end() && it->path == path ? &*it : nullptr;
}

void decal_tile_size(int width, int height, int& outW, int& outH) {
    const int longest = std::max(width, height);
    if (longest <= kDecalTileMaxSide) {
        outW = std::max(width, 1);
        outH = std::max(height, 1);
        return;
    }
    outW = std::max(1, int(std::int64_t(width) * kDecalTileMaxSide / longest));
    outH = std::max(1, int(std::int64_t(height) * kDecalTileMaxSide / longest));
}

DecalAtlasLayout layout_decal_atlas(std::vector<DecalTexture> textures, int maxSide) {
    DecalAtlasLayout out;
    maxSide = std::clamp(maxSide, 64, kDecalAtlasMaxSide);
    {
        int p = 64;  // a power of two: the largest one that is not above the limit
        while (p * 2 <= maxSide) p *= 2;
        maxSide = p;
    }
    // Duplicated paths count once (the first size wins); a texture without size has nothing to pack.
    std::stable_sort(textures.begin(), textures.end(),
                     [](const DecalTexture& a, const DecalTexture& b) { return a.path < b.path; });
    textures.erase(std::unique(textures.begin(), textures.end(),
                               [](const DecalTexture& a, const DecalTexture& b) { return a.path == b.path; }),
                   textures.end());
    std::vector<DecalTile> tiles;
    for (const DecalTexture& t : textures) {
        if (t.width < 1 || t.height < 1 || tiles.size() >= kMaxDecalTextures) {
            out.dropped.push_back(t.path);
            continue;
        }
        DecalTile tile;
        tile.path = t.path;
        decal_tile_size(t.width, t.height, tile.w, tile.h);
        tiles.push_back(tile);
    }
    auto make_cells = [&]() {
        std::vector<Cell> cells;
        cells.reserve(tiles.size());
        for (std::size_t i = 0; i < tiles.size(); ++i) {
            Cell c;
            c.tex = i;
            c.w = tiles[i].w;
            c.h = tiles[i].h;
            c.cw = round_up16(c.w + 2 * kDecalGutter);
            c.ch = round_up16(c.h + 2 * kDecalGutter);
            cells.push_back(c);
        }
        std::sort(cells.begin(), cells.end(), [&](const Cell& a, const Cell& b) { return cell_before(a, b, tiles); });
        return cells;
    };
    std::vector<Cell> cells;
    int usedH = 0;
    for (;;) {
        cells = make_cells();
        if (cells.empty()) break;
        if (shelf_pack(cells, maxSide, usedH)) break;
        // It does not fit the largest atlas: halve the biggest tile (the first of the sorted order among equals), down to kDecalMinSide...
        std::size_t big = tiles.size();
        int bigSide = kDecalMinSide;
        for (const Cell& c : cells) {
            const int s = std::max(tiles[c.tex].w, tiles[c.tex].h);
            if (s > bigSide) {
                bigSide = s;
                big = c.tex;
            }
        }
        if (big < tiles.size()) {
            tiles[big].w = std::max(1, tiles[big].w / 2);
            tiles[big].h = std::max(1, tiles[big].h / 2);
            tiles[big].shrunk = true;
            continue;
        }
        // ...and when every tile is that small, leave out the last of the order (the smallest).
        const std::size_t last = cells.back().tex;
        out.dropped.push_back(tiles[last].path);
        tiles.erase(tiles.begin() + std::ptrdiff_t(last));
    }
    if (cells.empty()) {
        std::sort(out.dropped.begin(), out.dropped.end());
        return out;
    }
    // The smallest square side that holds them (the shrinking above is the only thing that depends on maxSide).
    int side = 64;
    for (; side < maxSide; side *= 2) {
        std::vector<Cell> trial = cells;
        int h = 0;
        if (shelf_pack(trial, side, h)) {
            cells = trial;
            usedH = h;
            break;
        }
    }
    if (side >= maxSide) {
        side = maxSide;
        shelf_pack(cells, side, usedH);
    }
    out.width = side;
    out.height = std::min(side, pow2_at_least(usedH, 16));
    for (const Cell& c : cells) {
        tiles[c.tex].x = c.x + kDecalGutter;
        tiles[c.tex].y = c.y + kDecalGutter;
    }
    out.tiles = std::move(tiles);
    std::sort(out.tiles.begin(), out.tiles.end(),
              [](const DecalTile& a, const DecalTile& b) { return a.path < b.path; });
    std::sort(out.dropped.begin(), out.dropped.end());
    return out;
}

namespace {

Result<Image> load_one(const std::string& file) {
    if (fs::extension(file) == kTextureTwinExtension) {
        auto bytes = fs::read_bytes(file);
        if (!bytes) return bytes.error();
        return decode_ktx2(bytes->data(), bytes->size());
    }
    return load_image(file);
}

Result<Image> load_project_image(const std::string& pathIn) {
    std::string path = fs::normalize(pathIn);
    if (path.empty()) path = pathIn;
    // The order of Assets::load_texture: the atlas an export packed it into, then the compressed twin, then the file.
    if (const assets::PackedTexture packed = assets::packed_texture(path); !packed.atlas.empty()) {
        auto atlas = load_one(fs::exists(packed.atlas + kTextureTwinExtension) ? packed.atlas + kTextureTwinExtension
                                                                               : packed.atlas);
        if (!atlas) return atlas.error();
        if (packed.x < 0 || packed.y < 0 || packed.w < 1 || packed.h < 1 || packed.x + packed.w > atlas->width ||
            packed.y + packed.h > atlas->height)
            return make_error(std::format("'{}' is packed outside its atlas '{}'", path, packed.atlas),
                              "Export the project again.");
        Image out;
        out.width = packed.w;
        out.height = packed.h;
        out.rgba.resize(std::size_t(packed.w) * std::size_t(packed.h) * 4);
        for (int y = 0; y < packed.h; ++y)
            std::memcpy(out.rgba.data() + std::size_t(y) * std::size_t(packed.w) * 4,
                        atlas->rgba.data() +
                            (std::size_t(packed.y + y) * std::size_t(atlas->width) + std::size_t(packed.x)) * 4,
                        std::size_t(packed.w) * 4);
        return out;
    }
    const std::string twin = fs::extension(path) == kTextureTwinExtension ? path : path + kTextureTwinExtension;
    if (fs::exists(twin)) return load_one(twin);
    if (!fs::exists(path)) return make_error("file not found: " + path);
    return load_image(path);
}

}  // namespace

DecalSource project_decal_source() {
    DecalSource s;
    s.size = [](const std::string& path) { return texture_size(path); };
    s.load = [](const std::string& path) { return load_project_image(path); };
    return s;
}

DecalAtlasImage build_decal_atlas(const std::vector<std::string>& paths, const DecalSource& source, int maxSide) {
    DecalAtlasImage out;
    std::vector<DecalTexture> textures;
    for (const std::string& p : paths) {
        auto size = source.size(p);
        if (!size) {
            out.failed.push_back(p + ": " + size.error().message);
            continue;
        }
        textures.push_back(DecalTexture{p, size->width, size->height});
    }
    out.layout = layout_decal_atlas(std::move(textures), maxSide);
    const DecalAtlasLayout& lay = out.layout;
    if (lay.tiles.empty()) return out;
    // The byte budget, in 64 bits, before anything is allocated.
    const std::uint64_t bytes = std::uint64_t(lay.width) * std::uint64_t(lay.height) * 4u;
    if (bytes > kDecalAtlasMaxBytes) {
        out.failed.push_back("the atlas would need " + std::to_string(bytes >> 20) + " MB");
        out.layout = DecalAtlasLayout{};
        return out;
    }
    Image& img = out.image;
    img.width = lay.width;
    img.height = lay.height;
    img.rgba.assign(std::size_t(bytes), 0);
    for (const DecalTile& t : lay.tiles) {
        Image tile;
        auto loaded = source.load(t.path);
        if (loaded && !loaded->empty()) {
            tile =
                (loaded->width == t.w && loaded->height == t.h) ? std::move(*loaded) : resize_image(*loaded, t.w, t.h);
        } else {
            out.failed.push_back(t.path + ": " + (loaded ? std::string("the image is empty") : loaded.error().message));
        }
        if (tile.width != t.w || tile.height != t.h) {  // unreadable: transparent, with the flat normal
            tile.width = t.w;
            tile.height = t.h;
            tile.rgba.assign(std::size_t(t.w) * std::size_t(t.h) * 4, 0);
            for (std::size_t i = 0; i < std::size_t(t.w) * std::size_t(t.h); ++i) {
                tile.rgba[i * 4 + 0] = 128;
                tile.rgba[i * 4 + 1] = 128;
                tile.rgba[i * 4 + 2] = 255;
            }
        }
        // The tile and its gutter: every pixel of the cell reads the tile at the nearest edge-clamped position.
        for (int y = -kDecalGutter; y < t.h + kDecalGutter; ++y) {
            const int sy = std::clamp(y, 0, t.h - 1);
            for (int x = -kDecalGutter; x < t.w + kDecalGutter; ++x) {
                const int sx = std::clamp(x, 0, t.w - 1);
                std::memcpy(img.rgba.data() +
                                (std::size_t(t.y + y) * std::size_t(img.width) + std::size_t(t.x + x)) * 4,
                            tile.rgba.data() + (std::size_t(sy) * std::size_t(t.w) + std::size_t(sx)) * 4, 4);
            }
        }
    }
    return out;
}

}  // namespace fa::render
