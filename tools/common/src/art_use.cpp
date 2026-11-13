// Where the scenes draw a texture, and how big on screen (fa/tooling/art_check.h): the Sprites of every scene and prefab with
// the scale of their parents, and the camera of each scene.
#include <algorithm>
#include <cmath>

#include "fa/core/asset_manifest.h"
#include "fa/core/image.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "fa/tooling/art_check.h"
#include "util.h"

namespace fa {

std::vector<const TextureUse*> ProjectArtUse::of(const std::string& texture) const {
    std::vector<const TextureUse*> out;
    for (const TextureUse& u : uses)
        if (u.texture == texture) out.push_back(&u);
    return out;
}

const SceneView* ProjectArtUse::view_of(const std::string& scene) const {
    for (const SceneView& v : views)
        if (v.scene == scene) return &v;
    return nullptr;
}

void collect_art_use(World& world, const std::string& sceneFile, ProjectArtUse& use) {
    SceneView view;
    view.scene = sceneFile;
    int bestDepth = 0;
    world.each<Camera>([&](Entity, Camera& cam) {
        if (cam.projection != Projection::Orthographic || !cam.primary) return;
        if (view.hasCamera && cam.depth >= bestDepth) return;
        view.hasCamera = true;
        bestDepth = cam.depth;
        view.halfHeight = cam.orthoSize;
        view.clear = cam.clearColor;
        view.clears = cam.clear;
    });
    const double halfH = view.hasCamera && view.halfHeight > 0 ? view.halfHeight : use.designHeight / 2.0;
    const double viewH = 2 * halfH, viewW = viewH * use.designWidth / double(use.designHeight);

    world.each<Sprite>([&](Entity e, Sprite& s) {
        if (s.texture.empty()) return;
        TextureUse u;
        u.scene = sceneFile;
        u.texture = fs::normalize(s.texture);
        u.layer = s.layer;
        u.screenSpace = s.space == RenderSpace::Screen;
        u.nearest = s.pixelArt;
        u.stretched = s.slice.x > 0 || s.slice.y > 0 || s.slice.z > 0 || s.slice.w > 0;
        // the pixels drawn: the region, else a sheet frame, else the whole texture
        if (s.region.w > 0 && s.region.h > 0) {
            u.framePx[0] = s.region.w;
            u.framePx[1] = s.region.h;
        } else if (auto size = texture_size(u.texture)) {
            u.framePx[0] = size->width;
            u.framePx[1] = size->height;
            if (const SpriteAnimator* anim = world.get<SpriteAnimator>(e)) {
                auto sheet = assets::sheet(u.texture);
                if (sheet && sheet->frameWidth > 0 && sheet->frameHeight > 0) {
                    u.framePx[0] = sheet->frameWidth;
                    u.framePx[1] = sheet->frameHeight;
                } else if (anim->columns > 1 || anim->rows > 1) {
                    u.framePx[0] = double(size->width) / std::max(1, anim->columns);
                    u.framePx[1] = double(size->height) / std::max(1, anim->rows);
                }
            }
        } else {
            return;  // a missing texture is reported elsewhere
        }
        const Mat4 m = world.world_matrix(e);
        const double sx = std::sqrt(double(m.m[0]) * m.m[0] + double(m.m[1]) * m.m[1] + double(m.m[2]) * m.m[2]);
        const double sy = std::sqrt(double(m.m[4]) * m.m[4] + double(m.m[5]) * m.m[5] + double(m.m[6]) * m.m[6]);
        u.world[0] = (s.size.x > 0 ? s.size.x : u.framePx[0]) * sx;
        u.world[1] = (s.size.y > 0 ? s.size.y : u.framePx[1]) * sy;
        use.uses.push_back(u);
        if (!u.screenSpace && !u.stretched && u.world[0] * u.world[1] >= 0.5 * viewW * viewH)
            view.backdrops.push_back({u.texture, u.layer});
    });
    use.views.push_back(std::move(view));
}

void read_art_display(const std::string& projectDir, ProjectArtUse& use) {
    namespace stdfs = std::filesystem;
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / "factoria.json")) {
        Json j = Json::parse(*text, nullptr, false);
        if (j.is_object() && j.contains("display") && j["display"].is_object()) {
            const Json& d = j["display"];
            if (d.value("width", 0) > 0) use.designWidth = d.value("width", 1280);
            if (d.value("height", 0) > 0) use.designHeight = d.value("height", 720);
            if (d.contains("orientation") && d["orientation"].is_string())
                use.orientation = d["orientation"].get<std::string>();
        }
    }
}

ProjectArtUse scan_art_use(const std::string& projectDir) {
    ProjectArtUse use;
    read_art_display(projectDir, use);
    tooling_detail::ProjectRootScope root(projectDir);
    for (const std::string& rel : project_scene_files()) {
        World world;
        if (ends_with(to_lower(rel), ".scene.json")) {
            load_scene_file(world, rel);
        } else {
            LoadReport ignored;
            instantiate_prefab(world, rel, kNullEntity, ignored);
        }
        collect_art_use(world, rel, use);
    }
    return use;
}

double texels_per_unit(const TextureUse& u) {
    if (u.screenSpace || u.stretched) return 0;
    const double wx = u.world[0], wy = u.world[1];
    if (wx <= 0 || wy <= 0) return 0;
    return (u.framePx[0] / wx + u.framePx[1] / wy) / 2.0;
}

double median_texels_per_unit(const std::vector<const TextureUse*>& uses) {
    std::vector<double> values;
    for (const TextureUse* u : uses) {
        const double v = texels_per_unit(*u);
        if (v <= 0) continue;
        const double rounded = std::round(v * 100.0) / 100.0;
        if (std::find(values.begin(), values.end(), rounded) == values.end()) values.push_back(rounded);
    }
    if (values.empty()) return 0;
    std::sort(values.begin(), values.end());
    return values[values.size() / 2];
}

ReferenceScreens reference_screens(const ProjectArtUse& project) {
    ReferenceScreens s;
    if (project.orientation == "portrait") {
        std::swap(s.phoneWidth, s.phoneHeight);
        std::swap(s.desktopWidth, s.desktopHeight);
    }
    return s;
}

double on_screen_px(const TextureUse& u, const SceneView* view, const ProjectArtUse& project, double screenWidth,
                    double screenHeight) {
    const double halfH =
        view && view->hasCamera && view->halfHeight > 0 ? view->halfHeight : project.designHeight / 2.0;
    const double designPerUnit = u.screenSpace ? 1.0 : project.designHeight / (2 * halfH);
    const double device = std::min(screenWidth / project.designWidth, screenHeight / project.designHeight);
    return std::max(u.world[0], u.world[1]) * designPerUnit * device;
}

}  // namespace fa
