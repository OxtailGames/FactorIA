// Aseprite (.aseprite, .ase) -> an image document with the file's layers, cels, frames, durations and tags (the sprite sheet and its clips
// are baked from it), or, with `flat: true`, one PNG sprite sheet and its `sheet` entry (frames in a grid, tags as clips).
// File format: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
#include <algorithm>
#include <cmath>
#include <format>
#include <memory>
#include <set>

#include <stb_image.h>  // the zlib decoder; its implementation is compiled into fa_core (image.cpp)

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/pixel_art.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr std::size_t kMaxSheetPixels = std::size_t(1) << 27;  // 512 MB of RGBA
constexpr int kLayerGroup = 1, kLayerTilemap = 2;
constexpr int kLayerVisible = 1, kLayerBackground = 8, kLayerReference = 64;

// Little-endian reader over a byte range; reading past the end sets `overrun` and returns zeros.
class Cursor {
public:
    Cursor(const std::uint8_t* data, std::size_t size) : d_(data), n_(size) {}
    bool overrun() const { return overrun_; }
    std::size_t pos() const { return pos_; }
    std::size_t remaining() const { return overrun_ ? 0 : n_ - pos_; }
    std::uint32_t u8() { return read(1); }
    std::uint32_t u16() { return read(2); }
    std::uint32_t u32() { return read(4); }
    int s16() { return std::int16_t(read(2)); }
    void skip(std::size_t n) { take(n); }
    const std::uint8_t* take(std::size_t n) {
        if (overrun_ || n > n_ - pos_) {
            overrun_ = true;
            return nullptr;
        }
        const std::uint8_t* p = d_ + pos_;
        pos_ += n;
        return p;
    }
    void seek(std::size_t pos) {
        if (pos > n_)
            overrun_ = true;
        else
            pos_ = pos;
    }
    std::string string() {
        const std::size_t len = u16();
        const std::uint8_t* p = take(len);
        return p ? std::string(reinterpret_cast<const char*>(p), len) : std::string();
    }

private:
    std::uint32_t read(int bytes) {
        const std::uint8_t* p = take(std::size_t(bytes));
        std::uint32_t v = 0;
        for (int i = 0; p && i < bytes; ++i) v |= std::uint32_t(p[i]) << (8 * i);
        return v;
    }
    const std::uint8_t* d_;
    std::size_t n_;
    std::size_t pos_ = 0;
    bool overrun_ = false;
};

struct Rgba {
    std::uint8_t r = 0, g = 0, b = 0, a = 0;
};

struct Layer {
    std::string name;
    int flags = 0;
    int type = 0;
    int level = 0;
    int blend = 0;
    bool visible = false;  // its own flag and the flags of the groups above it
    float opacity = 1;     // its own opacity times the groups'
};

using Pixels = std::shared_ptr<const std::vector<std::uint8_t>>;  // as stored in the file: depth/8 bytes per pixel

struct Cel {
    int layer = 0, x = 0, y = 0, z = 0;
    float opacity = 1;
    int width = 0, height = 0;
    Pixels pixels;
};

struct Frame {
    int duration = 100;  // ms
    std::vector<Cel> cels;
};

struct Tag {
    std::string name;
    int from = 0, to = 0, direction = 0, repeat = 0;
};

struct Ase {
    int width = 0, height = 0, depth = 32, headerFlags = 0, transparentIndex = 0;
    std::vector<Rgba> palette = std::vector<Rgba>(256, Rgba{0, 0, 0, 255});
    std::vector<Layer> layers;
    std::vector<Frame> frames;
    std::vector<Tag> tags;
    int tilemapCels = 0;
};

const char* blend_name(int mode) {
    static const char* names[] = {"normal",     "multiply",    "screen",     "overlay",    "darken",
                                  "lighten",    "color dodge", "color burn", "hard light", "soft light",
                                  "difference", "exclusion",   "hue",        "saturation", "color",
                                  "luminosity", "addition",    "subtract",   "divide"};
    return mode >= 0 && mode < int(std::size(names)) ? names[mode] : "unknown";
}

Error bad(const std::string& file, const std::string& what) {
    return make_error(
        std::format("'{}' is not a valid Aseprite file: {}", file, what),
        "Save it again from Aseprite (File > Save As, .aseprite) and import that file; if Aseprite opens it "
        "fine, export a PNG sprite sheet from Aseprite (File > Export Sprite Sheet) and import the PNG.");
}

Pixels inflate(const std::uint8_t* data, std::size_t size, std::size_t expected) {
    int length = 0;
    char* out = stbi_zlib_decode_malloc_guesssize_headerflag(reinterpret_cast<const char*>(data), int(size),
                                                             int(expected), &length, 1);
    if (!out) return nullptr;
    auto pixels = std::make_shared<std::vector<std::uint8_t>>(out, out + length);
    stbi_image_free(out);
    return pixels;
}

void read_palette_chunk(Cursor& c, Ase& ase) {
    const std::uint32_t size = c.u32(), first = c.u32(), last = c.u32();
    c.skip(8);
    if (c.overrun() || first > last || last >= 65536) return;
    if (ase.palette.size() < std::max<std::size_t>(size, last + 1))
        ase.palette.resize(std::max<std::size_t>(size, last + 1));
    for (std::uint32_t i = first; i <= last && !c.overrun(); ++i) {
        const int flags = int(c.u16());
        Rgba& e = ase.palette[i];
        e.r = std::uint8_t(c.u8());
        e.g = std::uint8_t(c.u8());
        e.b = std::uint8_t(c.u8());
        e.a = std::uint8_t(c.u8());
        if (flags & 1) c.string();
    }
}

void read_old_palette_chunk(Cursor& c, Ase& ase) {
    std::size_t index = 0;
    for (std::uint32_t packets = c.u16(); packets > 0 && !c.overrun(); --packets) {
        index += c.u8();
        std::size_t count = c.u8();
        if (count == 0) count = 256;
        for (; count > 0 && !c.overrun() && index < ase.palette.size(); --count)
            ase.palette[index++] = Rgba{std::uint8_t(c.u8()), std::uint8_t(c.u8()), std::uint8_t(c.u8()), 255};
    }
}

void read_layer_chunk(Cursor& c, Ase& ase, std::vector<int>& lastAtLevel) {
    Layer layer;
    layer.flags = int(c.u16());
    layer.type = int(c.u16());
    layer.level = int(c.u16());
    c.skip(4);  // default size, ignored
    layer.blend = int(c.u16());
    const int opacity = int(c.u8());
    c.skip(3);
    layer.name = c.string();
    const bool opacityValid = layer.type == kLayerGroup ? (ase.headerFlags & 2) != 0 : (ase.headerFlags & 1) != 0;
    const int parent = layer.level > 0 && layer.level <= int(lastAtLevel.size()) ? lastAtLevel[layer.level - 1] : -1;
    layer.visible =
        (layer.flags & kLayerVisible) && !(layer.flags & kLayerReference) && (parent < 0 || ase.layers[parent].visible);
    layer.opacity = (opacityValid ? float(opacity) / 255.0f : 1.0f) * (parent < 0 ? 1.0f : ase.layers[parent].opacity);
    if (lastAtLevel.size() <= std::size_t(layer.level)) lastAtLevel.resize(std::size_t(layer.level) + 1, -1);
    lastAtLevel[layer.level] = int(ase.layers.size());
    ase.layers.push_back(std::move(layer));
}

// A cel chunk. Returns an empty string, or what is wrong with it.
std::string read_cel_chunk(Cursor& c, Ase& ase, int frameIndex) {
    Cel cel;
    cel.layer = int(c.u16());
    cel.x = c.s16();
    cel.y = c.s16();
    cel.opacity = float(c.u8()) / 255.0f;
    const int type = int(c.u16());
    cel.z = c.s16();
    c.skip(5);
    if (c.overrun()) return "a cel chunk is cut short";
    if (cel.layer >= int(ase.layers.size()))
        return std::format("a cel is on layer {} but only {} layers were defined before it", cel.layer,
                           ase.layers.size());
    const std::string where = std::format("frame {}, layer '{}'", frameIndex, ase.layers[cel.layer].name);
    if (type == 3) {  // a tilemap cel: not drawn
        ++ase.tilemapCels;
        return {};
    }
    Frame& frame = ase.frames[frameIndex];
    if (type == 1) {
        const int link = int(c.u16());
        if (link < 0 || link >= frameIndex)
            return std::format("{}: a linked cel points to frame {}, which does not come before it", where, link);
        for (const Cel& other : ase.frames[link].cels) {
            if (other.layer != cel.layer) continue;
            Cel linked = other;  // a linked cel shares the position and opacity of the cel it links to
            linked.z = cel.z;
            frame.cels.push_back(std::move(linked));
            return {};
        }
        return std::format("{}: a linked cel points to frame {}, which has no cel on that layer", where, link);
    }
    if (type != 0 && type != 2) return std::format("{}: unknown cel type {}", where, type);
    cel.width = int(c.u16());
    cel.height = int(c.u16());
    const std::size_t bytesPerPixel = std::size_t(ase.depth / 8);
    const std::size_t expected = std::size_t(cel.width) * std::size_t(cel.height) * bytesPerPixel;
    if (c.overrun()) return "a cel chunk is cut short";
    if (type == 0) {
        const std::uint8_t* raw = c.take(expected);
        if (!raw) return std::format("{}: the pixel data is cut short", where);
        cel.pixels = std::make_shared<std::vector<std::uint8_t>>(raw, raw + expected);
    } else {
        const std::size_t size = c.remaining();
        const std::uint8_t* z = c.take(size);
        cel.pixels = z ? inflate(z, size, expected) : nullptr;
        if (!cel.pixels || cel.pixels->size() < expected)
            return std::format("{}: the compressed pixel data is damaged (expected {} bytes)", where, expected);
    }
    frame.cels.push_back(std::move(cel));
    return {};
}

void read_tags_chunk(Cursor& c, Ase& ase) {
    const int count = int(c.u16());
    c.skip(8);
    for (int i = 0; i < count && !c.overrun(); ++i) {
        Tag tag;
        tag.from = int(c.u16());
        tag.to = int(c.u16());
        tag.direction = int(c.u8());
        tag.repeat = int(c.u16());  // 0 = not set (plays for ever), n = n times
        c.skip(6 + 3 + 1);          // reserved, the deprecated color, a zero byte
        tag.name = c.string();
        if (!c.overrun()) ase.tags.push_back(std::move(tag));
    }
}

Result<Ase> parse(const std::vector<std::uint8_t>& bytes, const std::string& file) {
    Cursor c(bytes.data(), bytes.size());
    Ase ase;
    c.skip(4);  // file size
    if (c.u16() != 0xA5E0)
        return bad(file, "it does not start with the Aseprite signature (is it really an .aseprite file?)");
    const int frameCount = int(c.u16());
    ase.width = int(c.u16());
    ase.height = int(c.u16());
    ase.depth = int(c.u16());
    ase.headerFlags = int(c.u32());
    const int speed = int(c.u16());
    c.skip(8);
    ase.transparentIndex = int(c.u8());
    c.seek(128);
    if (c.overrun()) return bad(file, "the header is cut short");
    if (ase.depth != 32 && ase.depth != 16 && ase.depth != 8)
        return bad(file, std::format("color depth {} is not 32 (RGBA), 16 (grayscale) or 8 (indexed)", ase.depth));
    if (ase.width == 0 || ase.height == 0 || frameCount == 0) return bad(file, "the sprite has no pixels or no frames");
    if (std::size_t(ase.width) * std::size_t(ase.height) * std::size_t(frameCount) > kMaxSheetPixels)
        return make_error(std::format("'{}' has {} frames of {}x{} px: the sprite sheet would be too large.", file,
                                      frameCount, ase.width, ase.height),
                          "Import a smaller sprite, or export the frames you need from Aseprite as a PNG sheet.");

    std::vector<int> lastAtLevel;
    ase.frames.resize(std::size_t(frameCount));
    for (int f = 0; f < frameCount; ++f) {
        const std::size_t frameStart = c.pos();
        const std::size_t frameBytes = c.u32();
        if (c.u16() != 0xF1FA) return bad(file, std::format("frame {} has no frame signature", f));
        const std::uint32_t oldChunks = c.u16();
        const int duration = int(c.u16());
        c.skip(2);
        const std::uint32_t newChunks = c.u32();
        if (c.overrun() || frameBytes < 16 || frameBytes > bytes.size() - frameStart)
            return bad(file, std::format("frame {} is cut short", f));
        ase.frames[f].duration = duration ? duration : speed ? speed : 100;
        const std::size_t frameEnd = frameStart + frameBytes;
        for (std::uint32_t i = 0, n = newChunks ? newChunks : oldChunks; i < n; ++i) {
            const std::size_t chunkStart = c.pos();
            const std::size_t chunkBytes = c.u32();
            const int type = int(c.u16());
            if (c.overrun() || chunkBytes < 6 || chunkBytes > frameEnd - chunkStart)
                return bad(file, std::format("a chunk of frame {} is cut short", f));
            Cursor body(bytes.data() + chunkStart + 6, chunkBytes - 6);
            std::string problem;
            switch (type) {
                case 0x0004: read_old_palette_chunk(body, ase); break;
                case 0x2004: read_layer_chunk(body, ase, lastAtLevel); break;
                case 0x2005: problem = read_cel_chunk(body, ase, f); break;
                case 0x2018: read_tags_chunk(body, ase); break;
                case 0x2019: read_palette_chunk(body, ase); break;
                default: break;  // color profile, user data, slices, tilesets...: not needed for the sheet
            }
            if (!problem.empty()) return bad(file, problem);
            if (body.overrun() && type != 0x2005)
                return bad(file, std::format("a chunk (type 0x{:04x}) of frame {} is cut short", type, f));
            c.seek(chunkStart + chunkBytes);
        }
        c.seek(frameEnd);
    }
    return ase;
}

Rgba decode_pixel(const Ase& ase, const std::uint8_t* p, bool backgroundLayer) {
    if (ase.depth == 32) return Rgba{p[0], p[1], p[2], p[3]};
    if (ase.depth == 16) return Rgba{p[0], p[0], p[0], p[1]};
    // Indexed: the transparent index is transparent on every layer but a Background one.
    if (p[0] == ase.transparentIndex && !backgroundLayer) return Rgba{};
    return p[0] < ase.palette.size() ? ase.palette[p[0]] : Rgba{};
}

// All the cels of a frame drawn over a transparent canvas, bottom layer first (normal blending: Aseprite's other blend
// modes are drawn as normal).
Image render_frame(const Ase& ase, const Frame& frame) {
    Image canvas;
    canvas.width = ase.width;
    canvas.height = ase.height;
    canvas.rgba.assign(std::size_t(ase.width) * ase.height * 4, 0);
    std::vector<const Cel*> order;
    for (const Cel& cel : frame.cels) order.push_back(&cel);
    std::stable_sort(order.begin(), order.end(), [](const Cel* a, const Cel* b) {
        return a->layer + a->z != b->layer + b->z ? a->layer + a->z < b->layer + b->z : a->z < b->z;
    });
    const std::size_t bytesPerPixel = std::size_t(ase.depth / 8);
    for (const Cel* cel : order) {
        const Layer& layer = ase.layers[cel->layer];
        const float opacity = cel->opacity * layer.opacity;
        if (!layer.visible || opacity <= 0 || !cel->pixels) continue;
        for (int y = 0; y < cel->height; ++y) {
            const int dy = cel->y + y;
            if (dy < 0 || dy >= ase.height) continue;
            for (int x = 0; x < cel->width; ++x) {
                const int dx = cel->x + x;
                if (dx < 0 || dx >= ase.width) continue;
                const Rgba src =
                    decode_pixel(ase, cel->pixels->data() + (std::size_t(y) * cel->width + x) * bytesPerPixel,
                                 (layer.flags & kLayerBackground) != 0);
                const float sa = float(src.a) / 255.0f * opacity;
                if (sa <= 0) continue;
                std::uint8_t* dst = &canvas.rgba[(std::size_t(dy) * ase.width + dx) * 4];
                const float da = float(dst[3]) / 255.0f;
                const float oa = sa + da * (1 - sa);
                const float s[3] = {float(src.r), float(src.g), float(src.b)};
                for (int k = 0; k < 3; ++k)
                    dst[k] = std::uint8_t(std::lround((s[k] * sa + float(dst[k]) * da * (1 - sa)) / oa));
                dst[3] = std::uint8_t(std::lround(oa * 255.0f));
            }
        }
    }
    return canvas;
}

double round2(double v) { return std::round(v * 100.0) / 100.0; }

}  // namespace

namespace {

// ---- the image document ------------------------------------------------------------------------------------------------

// What one layer shows in one frame.
struct CelState {
    bool empty = true;
    int x = 0, y = 0;
    float opacity = 1;
    int w = 0, h = 0;
    std::vector<std::uint8_t> rgba;  // a pixels layer
    std::vector<std::string> rows;   // an indexed layer
    bool operator==(const CelState& o) const {
        if (empty || o.empty) return empty == o.empty;
        return x == o.x && y == o.y && opacity == o.opacity && w == o.w && h == o.h && rgba == o.rgba && rows == o.rows;
    }
};

// The palette of an indexed file as the document keeps it: the colours the pictures use, each once, opaque; `remap[i]` is the
// document index of file index i.
struct IndexedPlan {
    bool ok = false;
    std::string why;
    std::vector<int> remap = std::vector<int>(256, -1);
    std::vector<Rgba> colours;
};

bool imported_layer(const Layer& layer) {
    return layer.type != kLayerGroup && layer.type != kLayerTilemap && !(layer.flags & kLayerReference);
}

IndexedPlan plan_indexed(const Ase& ase) {
    IndexedPlan plan;
    if (ase.depth != 8) return plan;
    std::vector<char> used(256, 0);
    for (const Frame& frame : ase.frames)
        for (const Cel& cel : frame.cels) {
            const Layer& layer = ase.layers[cel.layer];
            if (!imported_layer(layer) || !cel.pixels) continue;
            const bool background = (layer.flags & kLayerBackground) != 0;
            for (std::uint8_t index : *cel.pixels)
                if (background || index != ase.transparentIndex) used[index] = 1;
        }
    for (int i = 0; i < 256; ++i) {
        if (!used[i]) continue;
        const Rgba c = ase.palette[std::size_t(i)];
        if (c.a != 255) {
            plan.why = std::format("palette entry {} has an alpha of {}, and a palette colour of a document is opaque",
                                   i, c.a);
            return plan;
        }
        int found = -1;
        for (std::size_t k = 0; k < plan.colours.size() && found < 0; ++k)
            if (plan.colours[k].r == c.r && plan.colours[k].g == c.g && plan.colours[k].b == c.b) found = int(k);
        if (found < 0) {
            found = int(plan.colours.size());
            plan.colours.push_back(c);
        }
        plan.remap[std::size_t(i)] = found;
    }
    if (plan.colours.empty()) {
        plan.why = "no layer draws any color";
        return plan;
    }
    if (int(plan.colours.size()) > fa::kMaxIndexedColours) {
        plan.why = std::format("the pictures use {} colors and a document palette holds at most {}",
                               plan.colours.size(), fa::kMaxIndexedColours);
        return plan;
    }
    plan.ok = true;
    return plan;
}

CelState make_cel_state(const Ase& ase, const Layer& layer, const Cel* cel, const IndexedPlan& plan) {
    CelState s;
    if (!cel || !cel->pixels || cel->width <= 0 || cel->height <= 0 || cel->opacity <= 0) return s;
    const bool background = (layer.flags & kLayerBackground) != 0;
    const std::size_t bytesPerPixel = std::size_t(ase.depth / 8);
    bool any = false;
    if (plan.ok) {
        for (int y = 0; y < cel->height; ++y) {
            std::string row(std::size_t(cel->width), '.');
            for (int x = 0; x < cel->width; ++x) {
                const std::uint8_t index =
                    (*cel->pixels)[(std::size_t(y) * std::size_t(cel->width) + std::size_t(x)) * bytesPerPixel];
                if (!background && index == ase.transparentIndex) continue;
                row[std::size_t(x)] = fa::kPixelIndexChars[std::size_t(plan.remap[index])];
                any = true;
            }
            s.rows.push_back(std::move(row));
        }
    } else {
        s.rgba.resize(std::size_t(cel->width) * std::size_t(cel->height) * 4, 0);
        for (std::size_t i = 0; i < std::size_t(cel->width) * std::size_t(cel->height); ++i) {
            const Rgba c = decode_pixel(ase, cel->pixels->data() + i * bytesPerPixel, background);
            // A pixels cel carries its own opacity in its alpha, so a cel never needs an opacity relative to the layer's.
            const auto alpha = std::uint8_t(std::lround(float(c.a) * cel->opacity));
            if (alpha == 0) continue;
            s.rgba[i * 4] = c.r, s.rgba[i * 4 + 1] = c.g, s.rgba[i * 4 + 2] = c.b, s.rgba[i * 4 + 3] = alpha;
            any = true;
        }
    }
    if (!any) {
        s.rgba.clear();
        s.rows.clear();
        return s;
    }
    s.empty = false;
    s.x = cel->x;
    s.y = cel->y;
    s.opacity = plan.ok ? cel->opacity : 1.0f;
    s.w = cel->width;
    s.h = cel->height;
    return s;
}

const char* document_blend(int mode) {
    static const char* names[] = {"normal",     "multiply",   "screen",    "overlay",    "darken",     "lighten",
                                  "colorDodge", "colorBurn",  "hardLight", "softLight",  "difference", "exclusion",
                                  "hue",        "saturation", "color",     "luminosity", "add",        "subtract"};
    return mode >= 0 && mode < int(std::size(names)) ? names[mode] : "normal";
}

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

Result<ImportOutput> import_document(const Ase& ase, const ImportRequest& request, const std::string& file) {
    ImportOutput out;
    const int frameCount = int(ase.frames.size());
    const std::string stem = request.dest.substr(0, request.dest.size() - fs::extension(request.dest).size());
    const std::string layersDir = stem + ".layers/";
    const IndexedPlan plan = plan_indexed(ase);
    if (ase.depth == 8 && !plan.ok)
        out.warnings.push_back("The file is indexed but its palette cannot be kept as a document palette (" + plan.why +
                               "), so the layers are pixels layers with the colors drawn.");

    std::set<std::string> usedNames, usedFiles;
    std::vector<OutFile> layerFiles;
    Json layers = Json::array();
    std::vector<std::string> blendLost, groupBlend, noCels, referenceLayers, opacityClamped;
    bool zOffsets = false;
    for (std::size_t li = 0; li < ase.layers.size(); ++li) {
        const Layer& layer = ase.layers[li];
        if (layer.type == kLayerGroup) {
            if (layer.blend != 0) groupBlend.push_back("'" + layer.name + "'");
            continue;
        }
        if (layer.type == kLayerTilemap) continue;
        if (layer.flags & kLayerReference) {
            referenceLayers.push_back("'" + layer.name + "'");
            continue;
        }
        std::vector<CelState> states;
        for (const Frame& frame : ase.frames) {
            const Cel* found = nullptr;
            for (const Cel& cel : frame.cels)
                if (cel.layer == int(li)) {
                    found = &cel;
                    if (cel.z != 0) zOffsets = true;
                    break;
                }
            states.push_back(make_cel_state(ase, layer, found, plan));
        }
        if (std::all_of(states.begin(), states.end(), [](const CelState& s) { return s.empty; })) {
            noCels.push_back("'" + layer.name + "'");
            continue;
        }
        std::string name = layer.name.empty() ? "Layer " + std::to_string(li + 1) : layer.name;
        const std::string baseName = name;
        for (int n = 2; usedNames.count(to_lower(name)); ++n) name = baseName + " " + std::to_string(n);
        usedNames.insert(to_lower(name));
        const std::string fileBase = safe_file_name(name, "layer");
        std::string fileStem = fileBase;
        for (int n = 2; usedFiles.count(to_lower(fileStem)); ++n) fileStem = fileBase + "-" + std::to_string(n);
        usedFiles.insert(to_lower(fileStem));

        // An indexed cel keeps its opacity, but frame 0 always shows at the layer's own opacity: the first cel that shows is the
        // reference, the layer takes its opacity and the others are relative to it.
        float reference = 1;
        if (plan.ok) {
            for (const CelState& s : states)
                if (!s.empty) {
                    reference = s.opacity;
                    break;
                }
            bool raised = false;
            for (CelState& s : states) {
                if (s.empty) continue;
                const float relative = s.opacity / reference;
                raised = raised || relative > 1.0005f;
                s.opacity = float(round4(double(std::min(1.0f, relative))));
            }
            if (raised) opacityClamped.push_back("'" + name + "'");
        }
        Json j = Json::object({{"kind", plan.ok ? "indexed" : "pixels"}, {"name", name}});
        // The picture of one state: rows, or a PNG written next to the others (named after the frame it first shows).
        auto picture = [&](Json& target, const CelState& s, int frame) {
            if (plan.ok) {
                target["rows"] = s.rows;
            } else {
                Image img;
                img.width = s.w;
                img.height = s.h;
                img.rgba = s.rgba;
                const std::string path = layersDir + fileStem + "-" + std::to_string(frame) + ".png";
                layerFiles.push_back({path, encode_png(img)});
                target["source"] = path;
            }
        };
        auto place = [](Json& target, const CelState& s) {
            if (s.x) target["x"] = s.x;
            if (s.y) target["y"] = s.y;
            if (s.opacity < 0.9999f) target["opacity"] = double(s.opacity);
        };
        if (!states[0].empty) {
            picture(j, states[0], 0);
            if (states[0].x) j["x"] = states[0].x;
            if (states[0].y) j["y"] = states[0].y;
        }
        Json cels = Json::array();
        for (int f = 1; f < frameCount; ++f) {
            const CelState& s = states[std::size_t(f)];
            if (s == states[std::size_t(f - 1)]) continue;
            Json cel = Json::object({{"frame", f}});
            if (s.empty) {
                cel["empty"] = true;
            } else {
                int earlier = -1;
                for (int g = 0; g < f && earlier < 0; ++g)
                    if (states[std::size_t(g)] == s) earlier = g;
                if (earlier >= 0) {
                    cel["link"] = earlier;
                } else {
                    picture(cel, s, f);
                    place(cel, s);
                }
            }
            cels.push_back(std::move(cel));
        }
        if (!cels.empty()) j["cels"] = cels;
        const double layerOpacity =
            double(layer.opacity) * double(reference);  // the groups' opacity is already in layer.opacity
        if (layerOpacity < 0.9999) j["opacity"] = round4(layerOpacity);
        if (!layer.visible) j["visible"] = false;
        if (layer.blend != 0) {
            if (layer.blend > 17)
                blendLost.push_back(std::format("'{}' ({})", name, blend_name(layer.blend)));
            else
                j["blend"] = document_blend(layer.blend);
        }
        layers.push_back(std::move(j));
    }
    if (layers.empty())
        return make_error("'" + file + "' has no layer with pixels.",
                          "Draw something in Aseprite and save again, or export a PNG from it and import that.");

    // Frames and tags. A tag keeps its range, direction and repeat count; a name used twice gets a number.
    Json tags = Json::array();
    std::set<std::string> tagNames;
    std::vector<std::string> pingPongReverse;
    for (const Tag& tag : ase.tags) {
        if (tag.from > tag.to || tag.to >= frameCount) {
            out.warnings.push_back(std::format("Tag '{}' covers frames {}-{} but the sprite has {} frames: skipped.",
                                               tag.name, tag.from, tag.to, frameCount));
            continue;
        }
        const std::string baseName = tag.name.empty() ? "tag" : tag.name;
        std::string name = baseName;
        for (int n = 2; tagNames.count(name); ++n) name = baseName + " " + std::to_string(n);
        if (name != tag.name)
            out.warnings.push_back("A tag is called '" + tag.name + "' more than once (or has no name); this one is '" +
                                   name + "', because a clip name is unique.");
        tagNames.insert(name);
        Json t = Json::object({{"name", name}, {"from", tag.from}, {"to", tag.to}});
        if (tag.direction == 1)
            t["direction"] = "reverse";
        else if (tag.direction >= 2)
            t["direction"] = "pingpong";
        if (tag.direction == 3) pingPongReverse.push_back("'" + name + "'");
        if (tag.repeat > 0) t["repeat"] = std::min(tag.repeat, 1000);
        tags.push_back(std::move(t));
    }
    if (!pingPongReverse.empty())
        out.warnings.push_back("These tags play ping-pong in reverse in Aseprite; a document tag has no reverse "
                               "ping-pong, so they play ping-pong forward: " +
                               join(pingPongReverse, ", ") + ".");
    Json frames = Json::array();
    for (const Frame& frame : ase.frames)
        frames.push_back(Json::object({{"duration", std::clamp(frame.duration, 1, 60000)}}));
    const bool animated = frameCount > 1 || !tags.empty();

    if (!blendLost.empty())
        out.warnings.push_back(
            "These layers use a blend mode a document does not have and were composited as normal: " +
            join(blendLost, ", ") + ".");
    if (!groupBlend.empty())
        out.warnings.push_back("Groups are flattened into their layers (their visibility and opacity are kept); the "
                               "blend mode of these groups was dropped: " +
                               join(groupBlend, ", ") + ".");
    if (!noCels.empty())
        out.warnings.push_back("These layers have no pixels in any frame and were left out: " + join(noCels, ", ") +
                               ".");
    if (!referenceLayers.empty())
        out.warnings.push_back(
            "Reference layers are not part of the picture and were left out: " + join(referenceLayers, ", ") + ".");
    if (!opacityClamped.empty())
        out.warnings.push_back("The cels of these indexed layers get brighter than the first one shows; an indexed cel "
                               "cannot be more opaque than the layer, so they were capped: " +
                               join(opacityClamped, ", ") + ".");
    if (zOffsets)
        out.warnings.push_back(
            "Some cels have a z-index; a document stacks whole layers, so cels follow their layer's order.");
    if (ase.tilemapCels > 0) out.warnings.push_back("The sprite has tilemap layers; they are not imported.");

    Json document =
        Json::object({{"width", ase.width}, {"height", ase.height}, {"description", "Imported from " + file + "."}});
    if (plan.ok) {
        Json palette = Json::array();
        for (const Rgba& c : plan.colours) palette.push_back(std::format("#{:02x}{:02x}{:02x}", c.r, c.g, c.b));
        document["palette"] = palette;
    }
    if (animated) document["frames"] = frames;
    if (!tags.empty()) document["tags"] = tags;
    if (animated && request.columns > 0)
        document["sheet"] = Json::object({{"columns", std::min(request.columns, frameCount)}});
    document["layers"] = layers;

    // files[0] is the PNG the file always imported to; the document's bake replaces it with the sheet (or the picture) drawn from the layers.
    out.files.push_back({request.dest, encode_png(render_frame(ase, ase.frames[0]))});
    for (OutFile& f : layerFiles) out.files.push_back(std::move(f));
    out.documentPath = stem + ".image.json";
    out.document = std::move(document);
    double totalMs = 0;
    for (const Frame& frame : ase.frames) totalMs += frame.duration;
    out.details = Json::object({{"width", ase.width},
                                {"height", ase.height},
                                {"layers", layers.size()},
                                {"frames", frameCount},
                                {"tags", tags.size()},
                                {"colorDepth", ase.depth == 32   ? "rgba"
                                               : ase.depth == 16 ? "grayscale"
                                                                 : "indexed"},
                                {"indexedDocument", plan.ok},
                                {"totalMs", totalMs},
                                {"document", out.documentPath}});
    out.nextSteps.push_back(
        "The layers are an image document: image.info {\"path\":\"" + out.documentPath +
        "\"} lists the layers, frames and tags; image.pixel, image.draw, image.edit "
        "and image.paint take a `frame`, image.frame.* and image.tag.* change the animation, and the PNG at \"" +
        request.dest + "\" is baked from it.");
    return out;
}

// `flat: true`: one PNG sprite sheet and its `sheet` entry, no document.
Result<ImportOutput> import_flat_sheet(const Ase& ase, const ImportRequest& request) {
    ImportOutput out;
    const int frames = int(ase.frames.size());
    const int columns =
        request.columns > 0 ? std::min(request.columns, frames) : int(std::ceil(std::sqrt(double(frames))));
    const int rows = (frames + columns - 1) / columns;
    if (std::size_t(columns) * ase.width > 16384 || std::size_t(rows) * ase.height > 16384)
        return make_error(
            std::format("The sheet would be {}x{} px (columns {}, rows {}), more than the 16384 px a texture can have.",
                        columns * ase.width, rows * ase.height, columns, rows),
            "Pass a different `columns` so the sheet is closer to square, or import a sprite with fewer frames.");
    Image sheet;
    sheet.width = columns * ase.width;
    sheet.height = rows * ase.height;
    sheet.rgba.assign(std::size_t(sheet.width) * sheet.height * 4, 0);
    double totalMs = 0;
    Json durations = Json::array();
    for (int f = 0; f < frames; ++f) {
        const Image frame = render_frame(ase, ase.frames[f]);
        const int ox = (f % columns) * ase.width, oy = (f / columns) * ase.height;
        for (int y = 0; y < ase.height; ++y)
            std::copy_n(&frame.rgba[std::size_t(y) * ase.width * 4], std::size_t(ase.width) * 4,
                        &sheet.rgba[(std::size_t(oy + y) * sheet.width + ox) * 4]);
        totalMs += ase.frames[f].duration;
        durations.push_back(ase.frames[f].duration);
    }

    std::vector<SheetClip> clips;
    std::vector<std::string> slowedDirections;
    for (const Tag& tag : ase.tags) {
        if (tag.from > tag.to || tag.to >= frames) {
            out.warnings.push_back(std::format("Tag '{}' covers frames {}-{} but the sprite has {} frames: skipped.",
                                               tag.name, tag.from, tag.to, frames));
            continue;
        }
        double ms = 0;
        for (int f = tag.from; f <= tag.to; ++f) ms += ase.frames[f].duration;
        clips.push_back({tag.name, tag.from, tag.to, round2(1000.0 * (tag.to - tag.from + 1) / ms)});
        if (tag.direction != 0) {
            static const char* names[] = {"forward", "reverse", "ping-pong", "reverse ping-pong"};
            slowedDirections.push_back(std::format("'{}' ({})", tag.name, names[std::clamp(tag.direction, 0, 3)]));
        }
    }
    if (!slowedDirections.empty())
        out.warnings.push_back("The sheet has no direction per clip, so these tags are clips that play forward: " +
                               join(slowedDirections, ", ") +
                               ". Set SpriteAnimator.mode to \"reverse\" or \"pingpong\" to play them that way.");
    std::vector<std::string> blended;
    for (const Layer& layer : ase.layers)
        if (layer.visible && layer.type != kLayerGroup && layer.blend != 0)
            blended.push_back(std::format("'{}' ({})", layer.name, blend_name(layer.blend)));
    if (!blended.empty())
        out.warnings.push_back("These layers use a blend mode other than normal and were composited as normal: " +
                               join(blended, ", ") + ".");
    if (ase.tilemapCels > 0) out.warnings.push_back("The sprite has tilemap layers; they are not drawn in the sheet.");

    const double fps = round2(1000.0 * frames / totalMs);
    out.sheet = sheet_entry(columns, rows, ase.width, ase.height, frames, clips);
    out.files.push_back({request.dest, encode_png(sheet)});
    out.details = Json::object({{"layers", ase.layers.size()},
                                {"colorDepth", ase.depth == 32   ? "rgba"
                                               : ase.depth == 16 ? "grayscale"
                                                                 : "indexed"},
                                {"frameDurationsMs", durations},
                                {"fps", fps}});
    out.nextSteps = sheet_next_steps(request.dest, out.sheet, fps);
    return out;
}

}  // namespace

Result<ImportOutput> import_aseprite(const ImportRequest& request) {
    const std::string file = request.source.filename().string();
    auto bytes = read_bytes(request.source);
    if (!bytes.ok()) return bytes.error();
    auto parsed = parse(*bytes, file);
    if (!parsed.ok()) return parsed.error();
    return request.flat ? import_flat_sheet(*parsed, request) : import_document(*parsed, request, file);
}

}  // namespace fa::assets_detail
