// Packs the textures of the glTF layer extensions into the maps a mesh part already binds (render_internal.h,
// pack_layer_textures). Any thread: it reads files through fa::fs and decodes them, nothing of the GPU.
#include <cstring>
#include <format>
#include <map>
#include <memory>

#include "fa/core/fs.h"
#include "render_internal.h"

namespace fa::render {

bool LayerTextureRefs::any() const {
    for (const PreparedTextureRef* r : {&clearcoat, &clearcoatRoughness, &clearcoatNormal, &sheenColor, &sheenRoughness,
                                        &anisotropy, &specular, &specularColor})
        if (r->kind != PreparedTextureRef::Kind::None) return true;
    return false;
}

namespace {

// One channel of a source picture, or (image null) 255.
struct Channel {
    const Image* image = nullptr;
    int index = 0;  // 0 r .. 3 a
};

// Bilinear sample of channel `c` of `src` at the centre of destination pixel (x, y) of a w x h picture: integer arithmetic
// with 8 bits of weight, so the result does not depend on the compiler or the CPU.
std::uint8_t sample(const Channel& c, int x, int y, int w, int h) {
    if (!c.image) return 255;
    const Image& s = *c.image;
    auto axis = [](int d, int dn, int sn, int& i0, int& i1, int& f) {
        // source coordinate (d + 0.5) * sn / dn - 0.5, in units of 1 / (2 dn)
        std::int64_t num = std::int64_t(2 * d + 1) * sn - dn;
        if (num < 0) num = 0;
        const std::int64_t den = std::int64_t(2) * dn;
        i0 = int(num / den);
        f = int((num % den) * 256 / den);
        i1 = std::min(i0 + 1, sn - 1);
        i0 = std::min(i0, sn - 1);
    };
    int x0, x1, fx, y0, y1, fy;
    axis(x, w, s.width, x0, x1, fx);
    axis(y, h, s.height, y0, y1, fy);
    auto at = [&](int px, int py) {
        return int(s.rgba[(std::size_t(py) * std::size_t(s.width) + std::size_t(px)) * 4 + std::size_t(c.index)]);
    };
    const int top = at(x0, y0) * (256 - fx) + at(x1, y0) * fx;
    const int bottom = at(x0, y1) * (256 - fx) + at(x1, y1) * fx;
    return std::uint8_t((top * (256 - fy) + bottom * fy + 32768) >> 16);
}

Image compose(const Channel (&ch)[4], int w, int h) {
    Image out;
    out.width = w;
    out.height = h;
    out.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            std::uint8_t* p = &out.rgba[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4];
            for (int c = 0; c < 4; ++c) p[c] = sample(ch[c], x, y, w, h);
        }
    return out;
}

// The decoded pictures of this material's textures, by name (a texture used for two things is decoded once).
struct Sources {
    std::map<std::string, std::shared_ptr<Image>> decoded;
    std::map<std::string, std::string> failed;  // name -> why

    // The picture of `r`, or null with `why` (empty when r names no texture).
    const Image* get(const PreparedTextureRef& r, std::string& label, std::string& why) {
        why.clear();
        switch (r.kind) {
            case PreparedTextureRef::Kind::None: return nullptr;
            case PreparedTextureRef::Kind::Image:
                label = r.name;
                if (r.image.empty()) {
                    why = "the embedded image is empty";
                    return nullptr;
                }
                return &r.image;
            case PreparedTextureRef::Kind::Missing:
                label = r.name.empty() ? std::string("a texture") : r.name;
                why = r.error.empty() ? std::string("the texture file is missing") : r.error;
                return nullptr;
            case PreparedTextureRef::Kind::Path: break;
        }
        label = r.path;
        if (auto it = decoded.find(r.path); it != decoded.end()) return it->second.get();
        if (auto it = failed.find(r.path); it != failed.end()) {
            why = it->second;
            return nullptr;
        }
        auto image = std::make_shared<Image>();
        std::string error;
        auto bytes = fs::read_bytes(r.path);
        if (bytes) {
            // The size from the header first: a hostile or huge file is refused before its pixels are allocated.
            auto size = image_size(bytes->data(), bytes->size());
            if (!size) {
                error = size.error().message;
            } else if (std::uint64_t(size->width) * std::uint64_t(size->height) > kMaxLayerPackPixels) {
                error = std::format("it is {} x {} pixels, over the {} x {} limit of a packed map", size->width,
                                    size->height, 4096, 4096);
            } else if (auto img = decode_image(bytes->data(), bytes->size()); img) {
                *image = std::move(*img);
            } else {
                error = img.error().message;
            }
        } else if (auto twin = fs::read_bytes(r.path + kTextureTwinExtension); twin) {
            // An export replaces the picture by its GPU twin: read the twin as RGBA8.
            auto tex = transcode_ktx2_as(twin->data(), twin->size(), SG_PIXELFORMAT_RGBA8);
            if (tex && !tex->levels.empty() && tex->width > 0 && tex->height > 0 &&
                tex->levels[0].size() == std::size_t(tex->width) * std::size_t(tex->height) * 4 &&
                std::uint64_t(tex->width) * std::uint64_t(tex->height) <= kMaxLayerPackPixels) {
                image->width = tex->width;
                image->height = tex->height;
                image->rgba = std::move(tex->levels[0]);
            } else {
                error = tex ? "its GPU twin cannot be read as RGBA8 here" : tex.error().message;
            }
        } else {
            error = bytes.error().message;
        }
        if (image->empty()) {
            failed[r.path] = error.empty() ? std::string("it cannot be decoded") : error;
            why = failed[r.path];
            return nullptr;
        }
        decoded[r.path] = image;
        return image.get();
    }
};

}  // namespace

int pack_layer_textures(LayerTextureRefs& refs, const std::string& what, const std::string& compositeName,
                        PreparedTextureRef& occlusion, PreparedTextureRef& metalRough,
                        std::vector<std::string>& warnings) {
    using Kind = PreparedTextureRef::Kind;
    // What is never packed: said first, with what is used instead.
    auto unused = [&](const PreparedTextureRef& r, const char* name, const char* instead) {
        if (r.kind == Kind::None) return;
        warnings.push_back(
            std::format("{}: {} '{}' is not used ({}).", what, name, r.kind == Kind::Path ? r.path : r.name, instead));
    };
    unused(refs.clearcoatNormal, "clearcoatNormalTexture",
           "the clear coat has no normal map of its own and follows the geometric normal");
    unused(refs.sheenColor, "sheenColorTexture", "sheenColorFactor is used for the whole surface");
    unused(refs.specularColor, "specularColorTexture", "specularColorFactor is used for the whole surface");

    Sources src;
    std::string label, why;
    // The picture of an extension texture; a texture that cannot be read is named and its factor alone is used.
    auto get = [&](const PreparedTextureRef& r, const char* name) -> const Image* {
        const Image* img = src.get(r, label, why);
        if (!img && r.kind != Kind::None)
            warnings.push_back(
                std::format("{}: {} '{}' cannot be used ({}); its factor alone is used.", what, name, label, why));
        return img;
    };
    const Image* coat = get(refs.clearcoat, "clearcoatTexture");
    const Image* coatRough = get(refs.clearcoatRoughness, "clearcoatRoughnessTexture");
    const Image* sheenRough = get(refs.sheenRoughness, "sheenRoughnessTexture");
    const Image* aniso = get(refs.anisotropy, "anisotropyTexture");
    const Image* spec = get(refs.specular, "specularTexture");
    if (aniso)
        warnings.push_back(
            std::format("{}: the direction of anisotropyTexture is not used (its blue channel, the strength, "
                        "is); the direction is the tangent turned by anisotropyRotation.",
                        what));

    // The maps the part has: read again (not owned by `src` when they are paths), so a missing one still reports itself.
    auto base = [&](PreparedTextureRef& own, const char* name, bool& broken) -> const Image* {
        const Image* img = src.get(own, label, why);
        broken = !img && own.kind != Kind::None;
        if (broken)
            warnings.push_back(
                std::format("{}: the {} '{}' cannot be read ({}); the layer textures that would share its "
                            "map are not used, their factors alone are.",
                            what, name, label, why));
        return img;
    };
    int packed = 0;
    auto dims = [&](std::initializer_list<const Image*> list, int& w, int& h) {
        w = h = 0;
        for (const Image* i : list)
            if (i) {
                w = std::max(w, i->width);
                h = std::max(h, i->height);
            }
    };
    auto fits = [&](int w, int h, const char* map) {
        if (std::uint64_t(w) * std::uint64_t(h) <= kMaxLayerPackPixels) return true;
        warnings.push_back(
            std::format("{}: the textures packed into the {} map would be {} x {}, over the {} x {} limit; "
                        "their factors alone are used.",
                        what, map, w, h, 4096, 4096));
        return false;
    };

    if (coat || coatRough || sheenRough) {
        bool broken = false;
        const Image* occ = base(occlusion, "occlusionTexture", broken);
        int w, h;
        dims({occ, coat, coatRough, sheenRough}, w, h);
        if (!broken && fits(w, h, "occlusion")) {
            const Channel ch[4] = {{occ, 0}, {coat, 0}, {coatRough, 1}, {sheenRough, 3}};
            PreparedTextureRef out;
            out.kind = Kind::Image;
            out.name = compositeName + ":occlusion";
            out.image = compose(ch, w, h);
            occlusion = std::move(out);
            packed |= 1;
        }
    }
    if (aniso || spec) {
        bool broken = false;
        const Image* mr = base(metalRough, "metallicRoughnessTexture", broken);
        int w, h;
        dims({mr, aniso, spec}, w, h);
        if (!broken && fits(w, h, "metallic-roughness")) {
            const Channel ch[4] = {{aniso, 2}, {mr, 1}, {mr, 2}, {spec, 3}};
            PreparedTextureRef out;
            out.kind = Kind::Image;
            out.name = compositeName + ":metalRough";
            out.image = compose(ch, w, h);
            metalRough = std::move(out);
            packed |= 2;
        }
    }
    return packed;
}

}  // namespace fa::render
