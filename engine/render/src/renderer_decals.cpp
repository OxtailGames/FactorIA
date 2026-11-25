// Renderer::Impl, the projected decals (M73.5b; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Decals"): the atlas of their textures on the GPU
// and the records the mesh fragment shader reads. The layout of the atlas is decal_atlas.h, the clusters and the data texture
// light_clusters.h; renderer_draw.cpp (collect_decals, upload_lights) calls these.
#include <algorithm>
#include <cmath>
#include <iterator>
#include <set>

#include "color_space.h"
#include "renderer_impl.h"

namespace fa {

namespace {

// The key a texture path has in the atlas (the same normalisation the asset cache uses).
std::string decal_key(const std::string& path) {
    std::string k = fs::normalize(path);
    return k.empty() ? path : k;
}

// The largest atlas side the GPU and kDecalAtlasMaxSide allow (a power of two).
int decal_max_side(const gpu::Device& device) {
    const int limit = std::max(64, device.limits().maxImageSize2d);
    int side = 64;
    while (side * 2 <= limit && side * 2 <= render::kDecalAtlasMaxSide) side *= 2;
    return side;
}

}  // namespace

std::string Renderer::Impl::decal_path_key(const std::string& path) { return decal_key(path); }

bool Renderer::Impl::ensure_decal_atlas(const std::vector<std::string>& pathsIn, bool linear) {
    // 0 = gamma scene (raw bytes), 1 = linear scene, no sRGB format (the shader decodes the albedo), 2 = linear scene, SRGB8A8 atlas.
    const gpu::PixelFormat format = gpu.texture_format(gpu::PixelFormat::Rgba8);
    const int mode = !linear ? 0 : (format != gpu::PixelFormat::Rgba8 ? 2 : 1);
    const std::uint64_t generation = assets->reload_generation();
    DecalAtlasState& a = decalAtlas;
    // Only the reload of a texture the atlas holds (or refused) rebuilds it, not that of any other asset of the project.
    const bool sameBuild = a.built && a.colorMode == mode && !assets->reloaded_any_of(a.generation, a.known);
    if (sameBuild) a.generation = generation;
    if (sameBuild) {
        bool all = true;
        for (const std::string& p : pathsIn)
            if (!a.known.count(p)) {
                all = false;
                break;
            }
        if (all) return a.view.id != 0;
    }
    // The textures to hold: the ones asked for before (so two views with different decals do not rebuild the atlas by turns) and the new
    // ones, as long as they are no more than the cap; past it only the ones asked for now.
    std::set<std::string> wanted(pathsIn.begin(), pathsIn.end());
    if (sameBuild) {
        std::set<std::string> merged = a.known;
        merged.insert(pathsIn.begin(), pathsIn.end());
        if (merged.size() <= render::kMaxDecalTextures) wanted = std::move(merged);
    }
    while (wanted.size() > render::kMaxDecalTextures) wanted.erase(std::prev(wanted.end()));
    const std::vector<std::string> list(wanted.begin(), wanted.end());
    render::DecalAtlasImage built =
        render::build_decal_atlas(list, render::project_decal_source(), decal_max_side(gpu.device()));
    // What went wrong, once for each text.
    for (const std::string& why : built.failed)
        if (warnedDecalTextures.insert(why).second)
            FA_WARN("render",
                    "Decal texture not used: {}. The decal is drawn without it (the albedo missing: not at all). Hint: "
                    "check the path in "
                    "Decal.albedo / Decal.normal.",
                    why);
    if (!built.layout.dropped.empty() && !warnedDecalAtlas) {
        warnedDecalAtlas = true;
        std::string names;
        for (std::size_t i = 0; i < built.layout.dropped.size() && i < 5; ++i)
            names += (i ? ", " : "") + built.layout.dropped[i];
        FA_WARN("render",
                "The decal atlas is full: {} texture(s) were left out ({}{}) and their decals are not drawn. The atlas "
                "holds at most {}x{} "
                "pixels. Hint: use smaller decal textures (each is scaled to at most {} px) or fewer of them.",
                built.layout.dropped.size(), names, built.layout.dropped.size() > 5 ? ", ..." : "",
                decal_max_side(gpu.device()), decal_max_side(gpu.device()), render::kDecalTileMaxSide);
    }
    // The new image, then the old one retired (an earlier job of this frame may still draw with it).
    gpu::Device& device = gpu.device();
    gpu::Image image{};
    gpu::View view{};
    std::uint64_t bytes = 0;
    if (built.layout.width > 0 && !built.image.rgba.empty()) {
        const bool srgb = mode == 2;
        std::vector<Image> chain = mip_chain(std::move(built.image), srgb);
        gpu::ImageDesc d;
        d.width = built.layout.width;
        d.height = built.layout.height;
        d.pixelFormat = mode == 2 ? format : gpu::PixelFormat::Rgba8;
        d.numMipmaps = int(std::min<std::size_t>(chain.size(), gpu::kMaxMipmaps));
        for (int i = 0; i < d.numMipmaps; ++i) {
            d.data.mipLevels[i] = gpu::Range{chain[std::size_t(i)].rgba.data(), chain[std::size_t(i)].rgba.size()};
            bytes += chain[std::size_t(i)].rgba.size();
        }
        d.label = "decal-atlas";
        image = device.make_image(d);
        if (device.state(image) == gpu::ResourceState::Valid) {
            gpu::ViewDesc vd;
            vd.texture.image = image;
            vd.label = "decal-atlas";
            view = device.make_view(vd);
        }
        if (!view.id || device.state(view) != gpu::ResourceState::Valid) {
            if (view.id) device.destroy_view(view);
            if (image.id) device.destroy_image(image);
            image = gpu::Image{};
            view = gpu::View{};
            bytes = 0;
            built.layout = render::DecalAtlasLayout{};
            if (!warnedDecalAtlas) {
                warnedDecalAtlas = true;
                FA_WARN("render", "The GPU could not make the decal atlas: the decals are not drawn.");
            }
        }
    }
    if (a.image.id || a.view.id) decalRetired.emplace_back(a.image, a.view);
    a.image = image;
    a.view = view;
    a.layout = std::move(built.layout);
    a.known = std::move(wanted);
    a.generation = generation;
    a.colorMode = mode;
    a.built = true;
    a.bytes = bytes;
    return a.view.id != 0;
}

void Renderer::Impl::free_retired_decal_atlases() {
    for (auto& [image, view] : decalRetired) {
        if (view.id) gpu.device().destroy_view(view);
        if (image.id) gpu.device().destroy_image(image);
    }
    decalRetired.clear();
}

void Renderer::Impl::destroy_decal_atlas() {
    free_retired_decal_atlases();
    if (decalAtlas.view.id) gpu.device().destroy_view(decalAtlas.view);
    if (decalAtlas.image.id) gpu.device().destroy_image(decalAtlas.image);
    decalAtlas = DecalAtlasState{};
}

void Renderer::Impl::make_decal_records(const std::vector<DecalItem>& items, bool linear, render::DecalPack& pack,
                                        std::vector<render::DecalBox>& boxes, int& skipped) {
    pack.records.clear();
    boxes.clear();
    pack.atlasWidth = std::max(1, decalAtlas.layout.width);
    pack.atlasHeight = std::max(1, decalAtlas.layout.height);
    pack.colorMode = decalAtlas.colorMode;
    auto rect_of = [&](const std::string& path, float (&out)[4]) {
        const render::DecalTile* t = path.empty() ? nullptr : decalAtlas.layout.find(decal_key(path));
        if (!t) return false;
        out[0] = float(t->x) / float(pack.atlasWidth);
        out[1] = float(t->y) / float(pack.atlasHeight);
        out[2] = float(t->x + t->w) / float(pack.atlasWidth);
        out[3] = float(t->y + t->h) / float(pack.atlasHeight);
        return true;
    };
    for (const DecalItem& it : items) {
        const Decal& d = *it.decal;
        render::DecalRecord r;
        // An albedo texture that is not in the atlas (unreadable, or left out because the atlas is full) leaves the decal out: a tinted
        // box in its place would be worse than none. A missing normal map only drops the relief.
        if (!d.albedo.empty() && !rect_of(d.albedo, r.albedoRect)) {
            ++skipped;
            continue;
        }
        if (!d.normal.empty()) rect_of(d.normal, r.normalRect);
        const Mat4 inv = it.world.inverse();
        for (int row = 0; row < 3; ++row)
            for (int c = 0; c < 4; ++c) r.rows[row * 4 + c] = inv.at(c, row);
        const Color tint = render::to_scene(d.color, linear);
        r.tint[0] = tint.r;
        r.tint[1] = tint.g;
        r.tint[2] = tint.b;
        r.tint[3] = std::clamp(d.color.a, 0.0f, 1.0f);
        r.opacity = std::clamp(d.opacity, 0.0f, 1.0f);
        r.normalStrength = std::clamp(d.normalStrength, 0.0f, 4.0f);
        const float fade = std::clamp(d.angleFade, 0.0f, 90.0f) * 0.017453292519943295f;
        r.angleScale = 1.0f / std::max(std::cos(fade), 1e-3f);
        r.layers = d.layers == 0 ? 65535.0f : float(std::clamp(d.layers, 0, 65535));
        render::DecalBox box;
        for (int i = 0; i < 8; ++i)
            box.corners[i] =
                it.world.transform_point(Vec3{(i & 1) ? 0.5f : -0.5f, (i & 2) ? 0.5f : -0.5f, (i & 4) ? 0.5f : -0.5f});
        pack.records.push_back(r);
        boxes.push_back(box);
    }
}

}  // namespace fa
