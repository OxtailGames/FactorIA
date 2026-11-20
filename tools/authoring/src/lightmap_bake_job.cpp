#include "lightmap_bake_job.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <map>
#include <set>
#include <utility>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image_float.h"
#include "fa/core/strings.h"
#include "fa/render/hdri.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/scene/components.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"
#include "fa/scene/world.h"

namespace fa::lightmap_job {

namespace {

// How much of a square of a page the unwrapped charts fill, about: the side of the square is picked so that the charts reach the asked density.
constexpr double kChartFill = 0.66;
constexpr int kMinSquare = 8;
// The longest side of the sky picture the bake keeps (the sky only lights diffuse surfaces: a sun spread over a few pixels gives the same light).
constexpr int kSkyMaxWidth = 1024;

bool cancelled() {
    const std::atomic<bool>* flag = command_cancel_flag();
    return flag != nullptr && flag->load(std::memory_order_relaxed);
}
Error cancelled_error() { return make_error("cancelled", "the bake was cancelled before it wrote anything"); }

Vec3 scene_rgb(const Color& c, bool linear) {
    auto one = [&](float v) { return std::isfinite(v) ? std::max(0.0f, linear ? srgb_to_linear(v) : v) : 0.0f; };
    return {one(c.r), one(c.g), one(c.b)};
}

bool finite_color(const Color& c) { return std::isfinite(c.r) && std::isfinite(c.g) && std::isfinite(c.b); }

// ---- the hash of what a bake used ------------------------------------------------------------------------------------------------------

struct Hasher {
    std::uint64_t h = kLightmapHashSeed;
    void i(std::int64_t v) { h = lightmap_hash_bytes(h, &v, sizeof v); }
    void f(double v) {
        i(std::int64_t(std::llround(v * 1e4)));
    }  // to a tenth of a millimetre: a rounding in the last digit changes nothing
    void v3(Vec3 v) {
        f(v.x);
        f(v.y);
        f(v.z);
    }
    void s(const std::string& t) {
        i(std::int64_t(t.size()));
        h = lightmap_hash_bytes(h, t.data(), t.size());
    }
};

std::string settings_hash(const Plan& p) {
    Hasher h;
    const BakeSettings& st = p.options.settings;
    h.i(st.samples);
    h.i(st.bounces);
    h.i(st.shadowSamples);
    h.i(st.seed);
    h.i(st.dilatePasses);
    h.i(st.denoiseRadius);
    h.f(st.denoiseSigma);
    h.f(st.rayEpsilon);
    h.f(p.options.texelsPerMeter);
    h.i(p.options.maxPageSize);
    h.i(int(p.options.sky));
    for (const BakeLight& l : p.lights) {
        h.i(int(l.kind));
        h.i(int(l.mode));
        h.v3(l.color);
        h.f(l.intensity);
        h.v3(l.position);
        h.v3(l.direction);
        h.v3(l.up);
        h.f(l.range);
        h.i(int(l.falloff));
        h.f(l.spotAngleDeg);
        h.f(l.spotInnerDeg);
        h.f(l.softRadius);
        h.f(l.softAngleDeg);
        h.f(l.width);
        h.f(l.height);
    }
    h.i(std::int64_t(p.probes.groups.size()));
    for (const ProbeGroup& g : p.probes.groups) {
        h.s(g.id);
        h.i(int(g.kind));
        h.i(g.count);
    }
    for (const Vec3& v : p.probes.positions) h.v3(v);
    h.v3(p.sky.zenith);
    h.v3(p.sky.horizon);
    h.v3(p.sky.ground);
    h.f(p.sky.intensity);
    h.s(p.environmentMap);
    h.f(p.environmentScale);
    h.f(p.environmentRotation);
    for (const PlanMesh& m : p.meshes) {
        h.s(m.id);
        h.s(m.mesh);
        for (float v : m.world.m) h.f(v);
        h.v3(m.albedo);
        h.v3(m.emissive);
        h.i(m.castsShadow);
        h.i(m.receiver);
        h.f(m.texelsPerMeter);
    }
    return lightmap_hash_hex(h.h);
}

// ---- the plan ------------------------------------------------------------------------------------------------------------------------------

// A BakeLight from a Light component, or false (with the reason) when it cannot be baked.
bool map_light(const World& world, Entity e, const Light& l, bool linear, BakeLight& out, std::string& why) {
    if (l.mode == LightMode::Realtime) {
        why = "mode realtime";
        return false;
    }
    if (!finite_color(l.color) || !std::isfinite(l.intensity) || l.intensity < 0) {
        why = "its color or intensity is not a finite, non-negative number";
        return false;
    }
    const Mat4 m = world.world_matrix(e);
    BakeLight b;
    b.mode = l.mode == LightMode::Baked ? BakeLightMode::Baked : BakeLightMode::IndirectOnly;
    b.color = scene_rgb(l.color, linear);
    b.intensity = l.intensity;
    b.position = m.translation();
    const Vec3 forward = m.transform_dir(kForward);
    b.direction = length_sq(forward) > 1e-12f ? normalize(forward) : Vec3{0, -1, 0};
    const bool soft = l.shadowFilter == ShadowFilter::Pcss && std::isfinite(l.shadowSoftness) && l.shadowSoftness > 0;
    switch (l.type) {
        case LightType::Directional:
            b.kind = BakeLightKind::Directional;
            if (soft) b.softAngleDeg = std::min(45.0f, 0.27f * l.shadowSoftness);
            break;
        case LightType::Point:
        case LightType::Spot: {
            b.kind = l.type == LightType::Point ? BakeLightKind::Point : BakeLightKind::Spot;
            if (!std::isfinite(l.range) || l.range < 0) {
                why = "its range is not a finite, non-negative number";
                return false;
            }
            if (l.range > 0) {
                b.range = l.range;
                b.falloff = BakeFalloff::Engine;  // the realtime falloff
            } else {
                b.range = 0;
                b.falloff = BakeFalloff::InverseSquare;
            }
            if (l.type == LightType::Spot) {
                const float outer = std::isfinite(l.spotAngle) ? std::clamp(l.spotAngle, 0.5f, 89.0f) : 30.0f;
                b.spotAngleDeg = outer;
                b.spotInnerDeg = std::isfinite(l.innerAngle) && l.innerAngle > 0 ? std::min(l.innerAngle, outer) : 0.0f;
            }
            if (soft) b.softRadius = 0.05f * l.shadowSoftness;
            break;
        }
        case LightType::Area: {
            const bool disc = l.shape == LightShape::Disc;
            if (!std::isfinite(l.size.x) || !(l.size.x > 0) ||
                (!disc && (!std::isfinite(l.size.y) || !(l.size.y > 0)))) {
                why = "its area size must be finite and above 0";
                return false;
            }
            b.kind = BakeLightKind::Area;
            // A disc (size.x is the diameter) becomes the square of the same area; a rectangle is width x height, a tube length x thickness.
            b.width = disc ? l.size.x * 0.8862269f : l.size.x;
            b.height = disc ? l.size.x * 0.8862269f : l.size.y;
            const Vec3 up = m.transform_dir({0, 1, 0});
            b.up = length_sq(up) > 1e-12f ? normalize(up) : Vec3{0, 0, 0};
            break;
        }
    }
    out = b;
    return true;
}

}  // namespace

float baker_rotation_for_environment(float environmentRotationDegrees) {
    // The renderer looks the picture up with u = 0.5 + (atan2(z, x) + theta + pi/2) / 2pi (hdri_uv); the baker with u = 0.5 + atan2(z, x) / 2pi +
    // rotationDeg / 360: the same picture needs the quarter turn added. tests/lightmap_commands_tests.cpp compares both on a grid of directions.
    return environmentRotationDegrees + 90.0f;
}

Result<Plan> make_plan(World& world, const std::string& scene, const Options& options, const std::string& manifestAbs,
                       const std::string& manifestProject) {
    Plan plan;
    plan.options = options;
    plan.options.settings.maxAtlasSize = options.maxPageSize;
    plan.scene = scene;
    plan.manifestAbs = manifestAbs;
    plan.manifestProject = manifestProject;
    const SceneSettings& ss = world.settings();
    const bool linear = ss.colorSpace == ColorSpace::Linear;

    // The meshes.
    std::vector<std::pair<std::string, Entity>> meshEntities;
    world.each<MeshRenderer>([&](Entity e, MeshRenderer&) {
        if (world.active_in_hierarchy(e)) meshEntities.emplace_back(world.id_of(e), e);
    });
    std::sort(meshEntities.begin(), meshEntities.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    std::size_t receivers = 0;
    for (const auto& [id, e] : meshEntities) {
        const MeshRenderer& mr = *world.get<MeshRenderer>(e);
        PlanMesh pm;
        pm.id = id;
        pm.mesh = mr.mesh.empty() ? std::string("cube") : mr.mesh;
        pm.world = world.world_matrix(e);
        pm.albedo = scene_rgb(mr.color, linear);
        pm.albedo = {std::min(pm.albedo.x, 1.0f), std::min(pm.albedo.y, 1.0f), std::min(pm.albedo.z, 1.0f)};
        const float strength = std::isfinite(mr.emissiveStrength) ? std::max(0.0f, mr.emissiveStrength) : 0.0f;
        pm.emissive = scene_rgb(mr.emissive, linear) * strength;
        pm.castsShadow = mr.castShadows && mr.contributeGI;
        pm.texelsPerMeter = lightmap_texels_per_meter(options.texelsPerMeter, mr.lightmapScale);
        pm.receiver = mr.receiveGI && !mr.unlit && pm.texelsPerMeter > 0;
        if (pm.receiver) ++receivers;
        plan.meshes.push_back(std::move(pm));
    }
    // The light probes (M73.4d): the groups of the active entities, in id order, as positions.
    {
        std::vector<std::pair<std::string, Entity>> groupEntities;
        world.each<LightProbeGroup>([&](Entity e, LightProbeGroup&) {
            if (world.active_in_hierarchy(e)) groupEntities.emplace_back(world.id_of(e), e);
        });
        std::sort(groupEntities.begin(), groupEntities.end(),
                  [](const auto& a, const auto& b) { return a.first < b.first; });
        for (const auto& [id, e] : groupEntities) {
            const Vec3 at = world.world_matrix(e).translation();
            if (auto r = add_probe_group(plan.probes, id, *world.get<LightProbeGroup>(e), at); !r)
                return Error{r.error().message, r.error().hint};
        }
    }
    if (receivers == 0 && plan.probes.size() == 0)
        return make_error(
            "nothing to bake: the scene has no active MeshRenderer that receives light into a lightmap and no "
            "LightProbeGroup",
            "A mesh is lit by the lightmap when its MeshRenderer has receiveGI true, lightmapScale above "
            "0 and unlit false, and the entity is "
            "active. Add a mesh (scene.spawn {\"components\":{\"MeshRenderer\":{\"mesh\":\"cube\"}}}) or "
            "set those fields on one; or add a LightProbeGroup to bake light probes for moving objects.");

    // The lights.
    std::vector<std::pair<std::string, Entity>> lightEntities;
    world.each<Light>([&](Entity e, Light&) {
        if (world.active_in_hierarchy(e)) lightEntities.emplace_back(world.id_of(e), e);
    });
    std::sort(lightEntities.begin(), lightEntities.end(),
              [](const auto& a, const auto& b) { return a.first < b.first; });
    for (const auto& [id, e] : lightEntities) {
        BakeLight b;
        std::string why;
        const Light& l = *world.get<Light>(e);
        if (map_light(world, e, l, linear, b, why)) {
            plan.lights.push_back(b);
        } else if (l.mode != LightMode::Realtime) {
            plan.warnings.push_back("light '" + id + "' is left out of the bake: " + why + ".");
        }
        if (l.mode != LightMode::Realtime && l.type == LightType::Area && l.shape == LightShape::Tube)
            plan.warnings.push_back("light '" + id +
                                    "' is a tube: it is baked as a rectangle of the same length and thickness.");
    }

    // The sky.
    SkyChoice choice = options.sky;
    const bool physical = ss.skyModel == SkyModel::Physical || !ss.skyMaterial.empty();
    if (choice == SkyChoice::Auto) {
        if (!ss.environmentMap.empty())
            choice = SkyChoice::Environment;
        else
            choice = SkyChoice::Ambient;
    }
    plan.options.sky = choice;
    auto gradient = [&] {
        plan.sky.zenith = scene_rgb(ss.skyColor, linear);
        plan.sky.horizon = scene_rgb(ss.horizonColor, linear);
        plan.sky.ground = plan.sky.horizon * 0.55f;
        plan.sky.intensity = 1.0f;
    };
    switch (choice) {
        case SkyChoice::Environment:
            if (ss.environmentMap.empty())
                return make_error("sky \"environment\" needs SceneSettings.environmentMap, which is empty",
                                  "Set an HDRI (scene.set_settings {\"environmentMap\": \"assets/sky.hdr\"}) or use "
                                  "sky \"auto\", \"gradient\", "
                                  "\"ambient\" or \"none\".");
            plan.environmentMap = ss.environmentMap;
            plan.environmentScale =
                std::isfinite(ss.environmentIntensity) ? std::max(0.0f, ss.environmentIntensity) : 1.0f;
            plan.environmentRotation =
                baker_rotation_for_environment(std::isfinite(ss.environmentRotation) ? ss.environmentRotation : 0.0f);
            break;
        case SkyChoice::Gradient: gradient(); break;
        case SkyChoice::Ambient: {
            const Vec3 a = scene_rgb(ss.ambientLight, linear);
            plan.sky.zenith = plan.sky.horizon = plan.sky.ground = a;
            plan.sky.intensity = 1.0f;
            if (physical)
                plan.warnings.push_back("the scene uses a physical sky or a sky material, which the bake cannot "
                                        "evaluate: the surfaces get the constant "
                                        "ambientLight of the scene settings. Use sky \"gradient\" for skyColor and "
                                        "horizonColor, or set an environmentMap (an HDRI) "
                                        "to light the bake with a real sky.");
            break;
        }
        case SkyChoice::None:
        case SkyChoice::Auto: break;
    }
    if (choice == SkyChoice::Gradient && physical)
        plan.warnings.push_back("the scene uses a physical sky or a sky material, which the bake cannot evaluate: it "
                                "bakes skyColor and horizonColor.");
    if (plan.lights.empty() && choice == SkyChoice::None)
        plan.warnings.push_back("the bake has no Baked or Mixed light and no sky: every lightmap will be black (only "
                                "emissive meshes light it).");
    plan.settingsHash = settings_hash(plan);
    return plan;
}

// ---- execute ---------------------------------------------------------------------------------------------------------------------------------

namespace {

struct Geometry {
    bool ok = false;
    std::string error, hint;
    render::LightmapMeshGeometry geo;
};

struct Square {
    std::size_t mesh = 0;  // index in the included meshes
    int size = 0;
    int page = -1, x = 0, y = 0;
};

struct PageSize {
    int width = 0, height = 0;
};

int pow2_ceil(int v) {
    int p = 1;
    while (p < v && p < (1 << 20)) p *= 2;
    return p;
}

// Shelf packing: squares by size (largest first, then by id), left to right in rows, a new page when the next row does not fit. Each square keeps
// `gap` texels from its neighbours and the page edge. Deterministic, the same layout for the same sizes. The pages shrink to what is used.
Result<std::vector<PageSize>> pack_squares(std::vector<Square>& squares, int gap, int maxSize) {
    std::vector<std::size_t> order(squares.size());
    for (std::size_t i = 0; i < order.size(); ++i) order[i] = i;
    std::stable_sort(order.begin(), order.end(),
                     [&](std::size_t a, std::size_t b) { return squares[a].size > squares[b].size; });
    double area = 0;
    int biggest = 0;
    for (const Square& s : squares) {
        area += double(s.size + gap) * double(s.size + gap);
        biggest = std::max(biggest, s.size + gap);
    }
    const int side = int(std::ceil(std::sqrt(area * 1.15)));
    const int width = std::min(maxSize, std::max(pow2_ceil(side), biggest));
    std::vector<PageSize> pages(1);
    int x = 0, y = 0, rowH = 0, page = 0;
    for (std::size_t idx : order) {
        Square& s = squares[idx];
        const int cell = s.size + gap;
        if (x + cell > width) {
            y += rowH;
            x = 0;
            rowH = 0;
        }
        if (y + cell > maxSize) {
            ++page;
            pages.emplace_back();
            x = 0;
            y = 0;
            rowH = 0;
        }
        s.page = page;
        s.x = x + gap / 2;
        s.y = y + gap / 2;
        x += cell;
        rowH = std::max(rowH, cell);
        pages[std::size_t(page)].width = std::max(pages[std::size_t(page)].width, x);
        pages[std::size_t(page)].height = std::max(pages[std::size_t(page)].height, y + rowH);
    }
    if (int(pages.size()) > kLightmapMaxPages)
        return make_error(
            "the bake needs " + std::to_string(pages.size()) + " pages, more than the " +
                std::to_string(kLightmapMaxPages) + " a manifest may list",
            "Lower texelsPerMeter (or MeshRenderer.lightmapScale of the big meshes) or raise maxPageSize (up to " +
                std::to_string(kLightmapMaxPageSize) + ").");
    return pages;
}

float round6(double v) { return float(std::llround(v * 1e6) / 1e6); }

double world_area(const render::LightmapMeshGeometry& g, const Mat4& m) {
    double area = 0;
    for (std::size_t t = 0; t + 2 < g.indices.size(); t += 3) {
        const Vec3 a = m.transform_point(g.positions[g.indices[t]]),
                   b = m.transform_point(g.positions[g.indices[t + 1]]),
                   c = m.transform_point(g.positions[g.indices[t + 2]]);
        area += 0.5 * double(length(cross(b - a, c - a)));
    }
    return area;
}

std::string dir_of(const std::string& path) {
    const std::size_t slash = path.find_last_of('/');
    return slash == std::string::npos ? std::string() : path.substr(0, slash + 1);
}
std::string file_of(const std::string& path) {
    const std::size_t slash = path.find_last_of('/');
    return slash == std::string::npos ? path : path.substr(slash + 1);
}

// The name of the manifest without ".lightmap.json": the pages are "<stem>.lightmap.<hash>.<n>.hdr".
std::string stem_of(const std::string& manifestFile) {
    const std::string tail = ".lightmap.json";
    return manifestFile.size() > tail.size() ? manifestFile.substr(0, manifestFile.size() - tail.size()) : manifestFile;
}

Error write_error(const std::string& what, const std::string& file, const Error& cause) {
    return make_error(what + " '" + file + "': " + cause.message,
                      "On Windows a file another program holds open (the editor's image viewer, an antivirus scan) "
                      "cannot be replaced: close it and run "
                      "the bake again, or bake to another manifest with `path`. Nothing of the old bake was changed "
                      "unless the manifest was "
                      "written. " +
                          cause.hint);
}

}  // namespace

Result<Json> execute(const Plan& plan, const ReportFn& report) {
    auto say = [&](const char* phase, double progress, std::uint64_t rays) {
        if (report) report(phase, progress, rays);
    };
    const Options& opt = plan.options;
    const BakeSettings& st = opt.settings;
    const int gap = std::max(2, std::min(st.dilatePasses, 8)) + (std::max(2, std::min(st.dilatePasses, 8)) & 1);
    std::vector<std::string> warnings = plan.warnings;
    Json skipped = Json::array();
    say("geometry", 0.0, 0);

    // 1. The geometry of every mesh file, once each.
    std::map<std::string, Geometry> geos;
    {
        std::set<std::string> names;
        for (const PlanMesh& m : plan.meshes) names.insert(m.mesh);
        std::size_t done = 0;
        for (const std::string& name : names) {
            if (cancelled()) return cancelled_error();
            Geometry g;
            auto r = render::lightmap_mesh_geometry(name);
            if (r) {
                g.ok = true;
                g.geo = std::move(r.value());
            } else {
                g.error = r.error().message;
                g.hint = r.error().hint;
            }
            geos.emplace(name, std::move(g));
            say("geometry", 0.1 * double(++done) / double(names.size()), 0);
        }
    }

    // 2. Which meshes take part, and the square each lit one gets.
    std::vector<const PlanMesh*> used;
    std::vector<Square> squares;
    std::vector<std::size_t> squareOf;  // per used mesh: index in `squares`, or npos
    for (const PlanMesh& m : plan.meshes) {
        const Geometry& g = geos.at(m.mesh);
        if (!g.ok) {
            skipped.push_back(Json::object({{"id", m.id}, {"reason", g.error}}));
            warnings.push_back("entity '" + m.id + "' is left out of the bake" +
                               (m.receiver ? " (it will not be lit by the lightmap)" : "") + ": " + g.error);
            continue;
        }
        used.push_back(&m);
        squareOf.push_back(std::size_t(-1));
        if (!m.receiver) continue;
        const double area = world_area(g.geo, m.world);
        if (!(area > 1e-9)) {
            skipped.push_back(Json::object(
                {{"id", m.id}, {"reason", "the mesh has no surface area in the scene (scaled to zero?)"}}));
            used.pop_back();
            squareOf.pop_back();
            continue;
        }
        const double wanted = std::ceil(std::sqrt(area / kChartFill) * m.texelsPerMeter);
        const double limit = double(opt.maxPageSize - gap);
        int size = int(std::clamp(wanted, double(kMinSquare), limit));
        if (wanted > limit)
            warnings.push_back("entity '" + m.id + "' needs " + std::to_string(std::int64_t(wanted)) +
                               " texels per side for " + std::to_string(m.texelsPerMeter) +
                               " texels per meter, over the page size " + std::to_string(opt.maxPageSize) +
                               ": it is baked at a lower density (raise maxPageSize or lower its lightmapScale).");
        Square sq;
        sq.mesh = used.size() - 1;
        sq.size = size;
        squareOf.back() = squares.size();
        squares.push_back(sq);
    }
    const bool lightmapped = !squares.empty();  // a scene with probes and no lit mesh bakes the probes alone
    if (!lightmapped && plan.probes.size() == 0)
        return make_error(
            "no mesh of the scene can be lit into a lightmap: " +
                (skipped.empty() ? std::string("none has surface area") : skipped[0]["reason"].get<std::string>()),
            "Fix the first reason above (the `skipped` list of the result names every entity) and bake again.");

    // 3. The pages.
    say("layout", 0.1, 0);
    std::vector<PageSize> pages;
    if (lightmapped) {
        auto packed = pack_squares(squares, gap, opt.maxPageSize);
        if (!packed) return packed.error();
        pages = std::move(packed.value());
    }

    // 4. The scene of the baker.
    BakeScene scene;
    std::vector<std::array<float, 6>> matKeys;
    auto material_of = [&](const PlanMesh& m) {
        const std::array<float, 6> key = {m.albedo.x, m.albedo.y, m.albedo.z, m.emissive.x, m.emissive.y, m.emissive.z};
        for (std::size_t i = 0; i < matKeys.size(); ++i)
            if (matKeys[i] == key) return std::uint32_t(i);
        matKeys.push_back(key);
        BakeMaterial bm;
        bm.albedo = m.albedo;
        bm.emissive = m.emissive;
        scene.materials.push_back(bm);
        return std::uint32_t(matKeys.size() - 1);
    };
    for (const PageSize& p : pages) scene.atlases.push_back(BakeAtlas{p.width, p.height});
    LightmapManifest manifest;
    std::map<std::string, std::string> unused;
    for (std::size_t u = 0; u < used.size(); ++u) {
        if (cancelled()) return cancelled_error();
        const PlanMesh& m = *used[u];
        const render::LightmapMeshGeometry& g = geos.at(m.mesh).geo;
        BakeMesh bm;
        bm.name = m.id;
        bm.positions.reserve(g.positions.size());
        bm.normals.reserve(g.positions.size());
        const Mat4 normalMatrix = m.world.inverse().transposed();
        for (std::size_t i = 0; i < g.positions.size(); ++i) {
            bm.positions.push_back(m.world.transform_point(g.positions[i]));
            const Vec3 n = i < g.normals.size() ? normalMatrix.transform_dir(g.normals[i]) : Vec3{};
            bm.normals.push_back(length_sq(n) > 1e-20f ? normalize(n) : Vec3{0, 1, 0});
        }
        bm.indices = g.indices;
        bm.materials.assign(g.indices.size() / 3, material_of(m));
        bm.castsShadow = m.castsShadow;
        if (squareOf[u] == std::size_t(-1)) {
            bm.atlas = -1;
        } else {
            const Square& sq = squares[squareOf[u]];
            const PageSize& pg = pages[std::size_t(sq.page)];
            LightmapEntry entry;
            entry.id = m.id;
            entry.mesh = m.mesh;
            entry.uv = g.uvKind;
            entry.meshHash = lightmap_hash_hex(g.hash);
            entry.settingsHash = plan.settingsHash;
            entry.page = sq.page;
            entry.scaleOffset[0] = round6(double(sq.size) / pg.width);
            entry.scaleOffset[1] = round6(double(sq.size) / pg.height);
            entry.scaleOffset[2] = round6(double(sq.x) / pg.width);
            entry.scaleOffset[3] = round6(double(sq.y) / pg.height);
            manifest.entities.push_back(entry);
            bm.atlas = sq.page;
            bm.lightmapUv.reserve(g.uv.size());
            for (const Vec2& t : g.uv)
                bm.lightmapUv.push_back({t.x * entry.scaleOffset[0] + entry.scaleOffset[2],
                                         t.y * entry.scaleOffset[1] + entry.scaleOffset[3]});
        }
        scene.meshes.push_back(std::move(bm));
    }
    scene.lights = plan.lights;
    scene.sky = plan.sky;
    if (!plan.environmentMap.empty()) {
        auto img = load_hdr(plan.environmentMap);
        if (!img) return make_error("the environment map for the bake: " + img.error().message, img.error().hint);
        if (const std::string problem = hdri_layout_problem(img->width, img->height, plan.environmentMap);
            !problem.empty())
            return make_error(
                problem,
                "Use an equirectangular .hdr (twice as wide as tall), or bake with sky \"gradient\" or \"ambient\".");
        ImageF pic = std::move(img.value());
        if (pic.width > kSkyMaxWidth) {
            auto small = pic.resized(kSkyMaxWidth, std::max(1, kSkyMaxWidth * pic.height / pic.width));
            if (!small) return small.error();
            pic = std::move(small.value());
        }
        BakeEquirect eq;
        eq.width = pic.width;
        eq.height = pic.height;
        eq.rotationDeg = plan.environmentRotation;
        eq.rgb.resize(std::size_t(pic.width) * std::size_t(pic.height) * 3);
        for (std::size_t i = 0; i < std::size_t(pic.width) * std::size_t(pic.height); ++i)
            for (std::size_t c = 0; c < 3; ++c) {
                float v = pic.data[i * std::size_t(pic.channels) + c];
                v = std::isfinite(v) ? std::clamp(v, 0.0f, kHdriMaxValue)
                                     : 0.0f;  // what the renderer's copy of the picture holds
                eq.rgb[i * 3 + c] = v;
            }
        scene.sky.image = std::move(eq);
        scene.sky.intensity = plan.environmentScale;
        scene.sky.zenith = scene.sky.horizon = scene.sky.ground = {};
    }
    if (cancelled()) return cancelled_error();

    // 5. The bake. The share of each atlas in the progress is its size.
    double total = 0;
    for (const PageSize& p : pages) total += double(p.width) * double(p.height);
    const bool denoise = st.denoiseRadius > 0;
    // The progress: the lightmap takes 0.12..lightmapEnd, the probes the rest up to 0.95 (all of it when there is no lightmap).
    const bool hasProbes = plan.probes.size() > 0;
    const double lightmapEnd = !hasProbes ? 0.95 : (lightmapped ? 0.70 : 0.12);
    BakeProgressFn progress = [&](const BakeProgress& p) {
        double before = 0;
        for (int a = 0; a + 1 < p.atlas; ++a)
            before += double(pages[std::size_t(a)].width) * double(pages[std::size_t(a)].height);
        const double mine =
            p.atlas > 0 ? double(pages[std::size_t(p.atlas - 1)].width) * double(pages[std::size_t(p.atlas - 1)].height)
                        : 0.0;
        const double part = p.total > 0 ? double(p.done) / double(p.total) : 0.0;
        double within = 0;
        const char* phase = "prepare";
        switch (p.phase) {
            case BakePhase::Prepare: phase = "prepare"; break;
            case BakePhase::Rasterize: phase = "rasterize"; break;
            case BakePhase::Trace:
                phase = "trace";
                within = (denoise ? 0.85 : 0.97) * part;
                break;
            case BakePhase::Denoise:
                phase = "denoise";
                within = 0.85 + 0.12 * part;
                break;
            case BakePhase::Dilate:
                phase = "dilate";
                within = 0.97;
                break;
            case BakePhase::Probes: phase = "probes"; break;
        }
        const double frac = total > 0 ? (before + mine * within) / total : 0.0;
        say(phase, 0.12 + (lightmapEnd - 0.12) * frac, p.rays);
    };
    say("prepare", 0.12, 0);
    BakeResult result;
    if (lightmapped) {
        auto baked = bake_lightmap(scene, st, progress);
        if (!baked) return baked.error();
        if (cancelled()) return cancelled_error();
        result = std::move(baked.value());
    }
    // The probes: the same scene, seeds and rules; positions from the plan. Valid probes keep their SH, the ones inside geometry are flagged.
    ProbeSet probeSet = plan.probes;
    std::uint64_t probeRays = 0;
    if (hasProbes) {
        say("probes", lightmapEnd, result.stats.rays);
        BakeProgressFn probeProgress = [&](const BakeProgress& p) {
            probeRays = p.rays;
            const double part = p.total > 0 ? double(p.done) / double(p.total) : 0.0;
            say("probes", lightmapEnd + (0.95 - lightmapEnd) * part, result.stats.rays + p.rays);
        };
        auto sampled = sample_probes(scene, probeSet.positions, st, probeProgress);
        if (!sampled) return sampled.error();
        if (cancelled()) return cancelled_error();
        probeSet.sh.resize(probeSet.size());
        probeSet.valid.resize(probeSet.size());
        for (std::size_t i = 0; i < probeSet.size(); ++i) {
            probeSet.sh[i] = (*sampled)[i].sh;
            probeSet.valid[i] = (*sampled)[i].valid ? 1 : 0;
        }
        result.stats.rays += probeRays;
        if (probeSet.invalid_count() > 0)
            warnings.push_back(
                std::to_string(probeSet.invalid_count()) + " of " + std::to_string(probeSet.size()) +
                " light probes are inside geometry (most of their rays hit the back of a surface): they "
                "are skipped when the objects are lit. Move the LightProbeGroup or its points out of the "
                "walls to use them.");
        if (probeSet.invalid_count() == probeSet.size())
            warnings.push_back("every light probe is inside geometry: moving objects will be lit by the sky's ambient "
                               "light as without probes.");
    }
    for (std::size_t a = 0; a < result.atlases.size(); ++a)
        if (result.atlases[a].overlappedTexels > 0)
            warnings.push_back(
                "page " + std::to_string(a) + ": " + std::to_string(result.atlases[a].overlappedTexels) +
                " texels are covered by two triangles of the lightmap UVs (overlapping charts: the first one wins). A "
                "model with its own "
                "TEXCOORD_1 needs charts that do not overlap; remove TEXCOORD_1 to use the engine's unwrap.");

    // 6. The files. From here on a cancel is not looked at: the pages are written first, the manifest last and atomically, so a reader sees either
    // the old bake or the new one.
    say("writing", 0.95, result.stats.rays);
    const std::string dirAbs = dir_of(plan.manifestAbs), dirProject = dir_of(plan.manifestProject);
    const std::string stem = stem_of(file_of(plan.manifestProject));
    const std::string tag = lightmap_hash_hex(hash_bake_result(result)).substr(0, 8);
    std::vector<std::string> newPages;
    std::vector<std::string>
        madeNow;  // the pages this call wrote (not the ones that were already there with the same bytes)
    // The pages the manifest on disk lists: a failed bake never deletes one of them, the game may be reading it.
    std::set<std::string> oldPages;
    std::string oldProbes;
    if (fs::exists(plan.manifestProject))
        if (auto old = load_lightmap_manifest(plan.manifestProject); old) {
            for (const LightmapPage& p : old->pages) oldPages.insert(p.file);
            oldProbes = old->probes.file;
        }
    auto remove_made_pages = [&] {
        for (const std::string& page : madeNow)
            if (!oldPages.count(page) && page != oldProbes) {
                std::error_code ec;
                fs::remove_file(fs::path_from_utf8(dirAbs + file_of(page)), ec);
            }
    };
    Json pageJson = Json::array();
    for (std::size_t a = 0; a < result.atlases.size(); ++a) {
        const BakedAtlas& at = result.atlases[a];
        auto pic = ImageF::create(at.width, at.height, 3);
        if (!pic) return pic.error();
        pic->data = at.rgb;
        const std::vector<std::uint8_t> bytes = encode_hdr(*pic);
        const std::string name = stem + ".lightmap." + tag + "." + std::to_string(a) + ".hdr";
        const std::string abs = dirAbs + name;
        bool same = false;
        if (fs::exists(abs))
            if (auto old = fs::read_bytes(abs); old && *old == bytes)
                same = true;  // the same bake again: nothing to replace
        if (!same) {
            if (auto w = fs::write_bytes(abs, bytes.data(), bytes.size()); !w) {
                remove_made_pages();
                return write_error("cannot write the lightmap page", abs, w.error());
            }
            madeNow.push_back(dirProject + name);
        }
        newPages.push_back(dirProject + name);
        manifest.pages.push_back(LightmapPage{dirProject + name, at.width, at.height});
        pageJson.push_back(Json::object({{"file", dirProject + name},
                                         {"width", at.width},
                                         {"height", at.height},
                                         {"bakedTexels", at.bakedTexels}}));
    }
    // The light probes: one file named after its own bytes, written after the pages and before the manifest, like them.
    std::string newProbes;
    if (hasProbes) {
        const std::vector<std::uint8_t> bytes = encode_probe_set(probeSet);
        const std::string tagP =
            lightmap_hash_hex(lightmap_hash_bytes(kLightmapHashSeed, bytes.data(), bytes.size())).substr(0, 8);
        const std::string name = stem + ".lightmap." + tagP + ".probes";
        const std::string abs = dirAbs + name;
        bool same = false;
        if (fs::exists(abs))
            if (auto old = fs::read_bytes(abs); old && *old == bytes) same = true;
        if (!same) {
            if (auto w = fs::write_bytes(abs, bytes.data(), bytes.size()); !w) {
                remove_made_pages();
                return write_error("cannot write the light probe file", abs, w.error());
            }
            madeNow.push_back(dirProject + name);
        }
        newProbes = dirProject + name;
        manifest.probes.file = newProbes;
        manifest.probes.count = int(probeSet.size());
        manifest.probes.invalid = int(probeSet.invalid_count());
    }
    manifest.version = kLightmapManifestVersion;
    manifest.uvVersion = kLightmapUvVersion;
    manifest.settingsHash = plan.settingsHash;
    manifest.index();
    const std::string text = dump_json(lightmap_manifest_to_json(manifest)) + "\n";
    if (auto w = fs::write_bytes(plan.manifestAbs, text.data(), text.size()); !w) {
        remove_made_pages();  // nothing references the pages this call made
        return write_error("cannot write the lightmap manifest", plan.manifestAbs, w.error());
    }
    // The pages of the old bake that the new manifest does not list: only files that look like this manifest's own pages are removed.
    const std::string prefix = stem + ".lightmap.";
    for (const std::string& old : oldPages) {
        if (std::find(newPages.begin(), newPages.end(), old) != newPages.end()) continue;
        const std::string name = file_of(old);
        if (dir_of(old) != dirProject || name.rfind(prefix, 0) != 0 || name.size() < 4 ||
            name.substr(name.size() - 4) != ".hdr")
            continue;
        std::error_code ec;
        fs::remove_file(fs::path_from_utf8(dirAbs + name), ec);
    }
    if (!oldProbes.empty() && oldProbes != newProbes) {  // the probe file of the old bake, by the same rule
        const std::string name = file_of(oldProbes);
        if (dir_of(oldProbes) == dirProject && name.rfind(prefix, 0) == 0 && name.size() > 7 &&
            name.substr(name.size() - 7) == ".probes") {
            std::error_code ec;
            fs::remove_file(fs::path_from_utf8(dirAbs + name), ec);
        }
    }
    say("writing", 1.0, result.stats.rays);

    Json out = Json::object();
    out["manifest"] = plan.manifestProject;
    out["pages"] = pageJson;
    out["entities"] = manifest.entities.size();
    out["texels"] = result.stats.texels;
    out["rays"] = result.stats.rays;
    out["triangles"] = result.stats.triangles;
    out["settingsHash"] = plan.settingsHash;
    out["lights"] = plan.lights.size();
    out["skipped"] = skipped;
    if (hasProbes) {
        Json groups = Json::array();
        for (const ProbeGroup& g : probeSet.groups) {
            std::int64_t bad = 0;
            for (std::int32_t i = 0; i < g.count; ++i) bad += probeSet.valid[std::size_t(g.first + i)] == 0 ? 1 : 0;
            groups.push_back(Json::object({{"id", g.id},
                                           {"kind", g.kind == ProbeGroupKind::Grid ? "grid" : "points"},
                                           {"count", g.count},
                                           {"invalid", bad}}));
        }
        out["probes"] = Json::object({{"file", newProbes},
                                      {"count", probeSet.size()},
                                      {"invalid", probeSet.invalid_count()},
                                      {"groups", groups}});
    }
    Json w = Json::array();
    for (const std::string& s : warnings) w.push_back(s);
    out["warnings"] = w;
    return out;
}

}  // namespace fa::lightmap_job
