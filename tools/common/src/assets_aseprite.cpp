// Aseprite (.aseprite, .ase) -> one PNG sprite sheet and its `sheet` entry (frames, tags as clips).
// File format: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
#include <algorithm>
#include <cmath>
#include <format>
#include <memory>

#include <stb_image.h>  // the zlib decoder; its implementation is compiled into fa_core (image.cpp)

#include "assets_internal.h"
#include "fa/core/strings.h"
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
        if (pos > n_) overrun_ = true;
        else pos_ = pos;
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
    int from = 0, to = 0, direction = 0;
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
    static const char* names[] = {"normal", "multiply", "screen", "overlay", "darken", "lighten", "color dodge",
                                  "color burn", "hard light", "soft light", "difference", "exclusion", "hue",
                                  "saturation", "color", "luminosity", "addition", "subtract", "divide"};
    return mode >= 0 && mode < int(std::size(names)) ? names[mode] : "unknown";
}

Error bad(const std::string& file, const std::string& what) {
    return make_error(std::format("'{}' is not a valid Aseprite file: {}", file, what),
                      "Save it again from Aseprite (File > Save As, .aseprite) and import that file; if Aseprite opens it "
                      "fine, export a PNG sprite sheet from Aseprite (File > Export Sprite Sheet) and import the PNG.");
}

Pixels inflate(const std::uint8_t* data, std::size_t size, std::size_t expected) {
    int length = 0;
    char* out = stbi_zlib_decode_malloc_guesssize_headerflag(reinterpret_cast<const char*>(data), int(size), int(expected),
                                                             &length, 1);
    if (!out) return nullptr;
    auto pixels = std::make_shared<std::vector<std::uint8_t>>(out, out + length);
    stbi_image_free(out);
    return pixels;
}

void read_palette_chunk(Cursor& c, Ase& ase) {
    const std::uint32_t size = c.u32(), first = c.u32(), last = c.u32();
    c.skip(8);
    if (c.overrun() || first > last || last >= 65536) return;
    if (ase.palette.size() < std::max<std::size_t>(size, last + 1)) ase.palette.resize(std::max<std::size_t>(size, last + 1));
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
    layer.visible = (layer.flags & kLayerVisible) && !(layer.flags & kLayerReference) &&
                    (parent < 0 || ase.layers[parent].visible);
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
        return std::format("a cel is on layer {} but only {} layers were defined before it", cel.layer, ase.layers.size());
    const std::string where = std::format("frame {}, layer '{}'", frameIndex, ase.layers[cel.layer].name);
    if (type == 3) {  // a tilemap cel: not drawn
        ++ase.tilemapCels;
        return {};
    }
    Frame& frame = ase.frames[frameIndex];
    if (type == 1) {
        const int link = int(c.u16());
        if (link < 0 || link >= frameIndex) return std::format("{}: a linked cel points to frame {}, which does not come before it", where, link);
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
        c.skip(2 + 6 + 3 + 1);  // repeat count, reserved, the deprecated color, a zero byte
        tag.name = c.string();
        if (!c.overrun()) ase.tags.push_back(std::move(tag));
    }
}

Result<Ase> parse(const std::vector<std::uint8_t>& bytes, const std::string& file) {
    Cursor c(bytes.data(), bytes.size());
    Ase ase;
    c.skip(4);  // file size
    if (c.u16() != 0xA5E0) return bad(file, "it does not start with the Aseprite signature (is it really an .aseprite file?)");
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
        return make_error(std::format("'{}' has {} frames of {}x{} px: the sprite sheet would be too large.", file, frameCount,
                                      ase.width, ase.height),
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
            if (body.overrun() && type != 0x2005) return bad(file, std::format("a chunk (type 0x{:04x}) of frame {} is cut short", type, f));
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
                const Rgba src = decode_pixel(ase, cel->pixels->data() + (std::size_t(y) * cel->width + x) * bytesPerPixel,
                                              (layer.flags & kLayerBackground) != 0);
                const float sa = float(src.a) / 255.0f * opacity;
                if (sa <= 0) continue;
                std::uint8_t* dst = &canvas.rgba[(std::size_t(dy) * ase.width + dx) * 4];
                const float da = float(dst[3]) / 255.0f;
                const float oa = sa + da * (1 - sa);
                const float s[3] = {float(src.r), float(src.g), float(src.b)};
                for (int k = 0; k < 3; ++k) dst[k] = std::uint8_t(std::lround((s[k] * sa + float(dst[k]) * da * (1 - sa)) / oa));
                dst[3] = std::uint8_t(std::lround(oa * 255.0f));
            }
        }
    }
    return canvas;
}

double round2(double v) { return std::round(v * 100.0) / 100.0; }

}  // namespace

Result<ImportOutput> import_aseprite(const ImportRequest& request) {
    const std::string file = request.source.filename().string();
    auto bytes = read_bytes(request.source);
    if (!bytes.ok()) return bytes.error();
    auto parsed = parse(*bytes, file);
    if (!parsed.ok()) return parsed.error();
    const Ase& ase = *parsed;

    ImportOutput out;
    const int frames = int(ase.frames.size());
    const int columns = request.columns > 0 ? std::min(request.columns, frames) : int(std::ceil(std::sqrt(double(frames))));
    const int rows = (frames + columns - 1) / columns;
    if (std::size_t(columns) * ase.width > 16384 || std::size_t(rows) * ase.height > 16384)
        return make_error(std::format("The sheet would be {}x{} px (columns {}, rows {}), more than the 16384 px a texture can have.",
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
            out.warnings.push_back(std::format("Tag '{}' covers frames {}-{} but the sprite has {} frames: skipped.", tag.name,
                                               tag.from, tag.to, frames));
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
        out.warnings.push_back("SpriteAnimator only plays forward, so these tags are clips that play forward: " + join(slowedDirections, ", ") + ".");
    std::vector<std::string> blended;
    for (const Layer& layer : ase.layers)
        if (layer.visible && layer.type != kLayerGroup && layer.blend != 0) blended.push_back(std::format("'{}' ({})", layer.name, blend_name(layer.blend)));
    if (!blended.empty())
        out.warnings.push_back("These layers use a blend mode other than normal and were composited as normal: " + join(blended, ", ") + ".");
    if (ase.tilemapCels > 0)
        out.warnings.push_back("The sprite has tilemap layers; they are not drawn in the sheet.");

    const double fps = round2(1000.0 * frames / totalMs);
    out.sheet = sheet_entry(columns, rows, ase.width, ase.height, frames, clips);
    out.files.push_back({request.dest, encode_png(sheet)});
    out.details = Json::object({{"frames", frames}, {"frameWidth", ase.width}, {"frameHeight", ase.height},
                                {"columns", columns}, {"rows", rows}, {"layers", ase.layers.size()},
                                {"colorDepth", ase.depth == 32 ? "rgba" : ase.depth == 16 ? "grayscale" : "indexed"},
                                {"frameDurationsMs", durations}, {"fps", fps}});
    out.nextSteps = sheet_next_steps(request.dest, out.sheet, fps);
    return out;
}

}  // namespace fa::assets_detail
