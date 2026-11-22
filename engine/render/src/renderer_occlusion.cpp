// Renderer::Impl, occlusion culling on the CPU (M75.2; docs/BIG_WORLDS.md, "Occlusion"): the Occluder entities of the world are rasterised
// into a small depth buffer per camera (occlusion.h) and the meshes that survived the frustum test are tested against it. A mesh it proves
// hidden is left out of the main pass (MeshItem::visible = false); it still casts shadows, because the shadow passes are not culled by it
// (a shadow can fall into the picture from an object the camera does not see). Sprites, 2D shapes and UI are not occlusion culled.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/profiler.h"
#include "fa/scene/mesh_store.h"
#include "render_jobs.h"
#include "renderer_impl.h"

namespace fa {

namespace {

// The 12 edges of a box (corner bit 0 = x, 1 = y, 2 = z).
constexpr int kBoxEdges[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3},
                                  {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};

}  // namespace

void Renderer::Impl::occlude_meshes(World& world, Frame& fr, bool z01, std::vector<MeshItem>& meshes) {
    // The occluders of this camera's scope, nearest first so that the caps keep the ones that matter most (a deterministic order: the
    // distance of the origin, then the entity).
    struct Pending {
        OccluderSource src;
        float dist = 0;
    };
    std::vector<Pending> pending;
    std::vector<std::uint64_t> occluderEntities;
    world.each<Occluder>([&](Entity e, Occluder& o) {
        if (!o.enabled || !entity_active_in_scope(world, fr.scopeRoot, e)) return;
        Pending p;
        p.src.entity = e.bits();
        p.src.model = world.drawn_matrix(e);
        const std::string name = world.id_of(e);
        if (o.shape == OccluderShape::Box) {
            const Vec3 half = o.size * 0.5f;
            p.src.boxMin = o.center - half;
            p.src.boxMax = o.center + half;
            if (!std::isfinite(p.src.boxMin.x + p.src.boxMin.y + p.src.boxMin.z + p.src.boxMax.x + p.src.boxMax.y +
                               p.src.boxMax.z))
                return;
        } else {
            const MeshRenderer* mr = world.get<MeshRenderer>(e);
            const std::string& meshName = !o.mesh.empty() ? o.mesh : (mr ? mr->mesh : o.mesh);
            if (meshName.empty()) {
                if (warnedOccluders.insert(e.bits()).second)
                    FA_WARN("render",
                            "Occluder on '{}' has shape \"mesh\" but no mesh to rasterise: Occluder.mesh is empty and "
                            "the entity has "
                            "no MeshRenderer. Hint: set Occluder.mesh to a model path, add a MeshRenderer, or use "
                            "shape \"box\". "
                            "The entity hides nothing until then.",
                            name);
                return;
            }
            std::string error;
            p.src.mesh = mesh_geometry_for(world.meshes(), meshName, &error);
            if (!p.src.mesh) {
                if (warnedOccluders.insert(e.bits()).second)
                    FA_WARN("render",
                            "Occluder on '{}' could not read its mesh '{}': {} Hint: fix Occluder.mesh, or use shape "
                            "\"box\". The "
                            "entity hides nothing until then.",
                            name, meshName, error);
                return;
            }
        }
        p.dist = length(p.src.model.translation() - fr.cam.position);
        pending.push_back(std::move(p));
        occluderEntities.push_back(e.bits());
    });
    if (pending.empty()) return;  // every Occluder is off or unreadable: nothing is culled, nothing is counted
    std::stable_sort(pending.begin(), pending.end(), [](const Pending& a, const Pending& b) {
        const float da = rjobs::order_float(a.dist), db = rjobs::order_float(b.dist);
        return da != db ? da < db : a.src.entity < b.src.entity;
    });
    std::sort(occluderEntities.begin(), occluderEntities.end());
    std::vector<OccluderSource> sources;
    sources.reserve(pending.size());
    for (Pending& p : pending) sources.push_back(std::move(p.src));

    OcclusionCamera cam;
    cam.viewProj = fr.cam.viewProj;
    cam.position = fr.cam.position;
    cam.forward = fr.cam.forward;
    cam.perspective = fr.cam.perspective;
    cam.zeroToOne = z01;
    const float p00 = fr.cam.proj.at(0, 0), p11 = fr.cam.proj.at(1, 1);
    int w = 0, h = 0;
    occlusion_size_for(std::fabs(p00) > 1e-12f ? std::fabs(p11 / p00) : 1.0f, w, h);
    occlusion.reset(cam, w, h);
    const OcclusionLimits limits = occlusionLimits;
    const OcclusionRasterStats rs = occlusion.rasterize(sources, limits);
    stats.occluders += rs.occluders;
    auto names = [&](const std::vector<std::uint64_t>& bits) {
        std::string out;
        for (std::uint64_t b : bits) out += (out.empty() ? "'" : ", '") + world.id_of(Entity::from_bits(b)) + "'";
        return out;
    };
    if (rs.occludersCapped > 0 && !warnedOccluderCap) {
        warnedOccluderCap = true;
        FA_WARN("render",
                "{} Occluder mesh(es) have more than {} triangles (e.g. {}): only the first {} of each are rasterised "
                "(the occluder "
                "hides less, never more). Hint: point Occluder.mesh at a low-poly proxy (a few hundred triangles), or "
                "use shape "
                "\"box\".",
                rs.occludersCapped, limits.perOccluder, names(rs.cappedEntities), limits.perOccluder);
    }
    if (rs.occludersDropped > 0 && !warnedOcclusionFrameCap) {
        warnedOcclusionFrameCap = true;
        FA_WARN("render",
                "The occluders of one camera hold more than {} triangles in all: {} occluder(s) were left out or cut "
                "(e.g. {}), "
                "the farthest ones first. Hint: use fewer or simpler Occluder meshes (boxes cost 12 triangles).",
                limits.perFrame, rs.occludersDropped, names(rs.droppedEntities));
    }

    // The test of every mesh the frustum kept: one flag per mesh, so the chunks write their own slots, and the counts are made after.
    std::vector<char> tested(meshes.size(), 0), hiddenFlag(meshes.size(), 0);
    const rjobs::Split split = rjobs::split(meshes.size(), kMeshGrain, kParallelMeshes);
    rjobs::run("render.mesh_occlusion", split, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            const MeshItem& mi = meshes[i];
            // noCull: no known bounds. An Occluder's own mesh is never tested (it is what hides the others).
            if (!mi.visible || mi.noCull) continue;
            if (std::binary_search(occluderEntities.begin(), occluderEntities.end(), mi.entity.bits())) continue;
            tested[i] = 1;
            hiddenFlag[i] = occlusion.hidden(mi.bmin, mi.bmax, mi.model) ? 1 : 0;
        }
    });
    int nTested = 0, nHidden = 0;
    for (std::size_t i = 0; i < meshes.size(); ++i) {
        nTested += tested[i];
        if (hiddenFlag[i]) {
            ++nHidden;
            meshes[i].visible = false;
        }
    }
    stats.occlusionTests += nTested;
    stats.meshesOccluded += nHidden;

    // What `render.occlusion` and the debug view show: the last camera of the frame that had occluders (the buffer is its own).
    {
        occlusionShown.valid = true;
        occlusionShown.camera = fr.cam.entity.is_null() ? std::string() : world.id_of(fr.cam.entity);
        occlusionShown.occluders = rs.occluders;
        occlusionShown.tests = nTested;
        occlusionShown.occluded = nHidden;
        occlusionShown.coveredCells = int(std::min<std::size_t>(rs.coveredCells, 0x7fffffffu));
        occlusionShown.sourceTriangles = int(std::min<std::size_t>(rs.sourceTriangles, 0x7fffffffu));
        occlusionShown.boxes.clear();
        if (debugView == DebugView::Occlusion) {
            auto addBox = [&](const Mat4& model, Vec3 lo, Vec3 hi, bool culled) {
                OcclusionShown::Box b;
                b.culled = culled;
                for (int k = 0; k < 8; ++k)
                    b.corners[std::size_t(k)] =
                        (model * Vec4{(k & 1) ? hi.x : lo.x, (k & 2) ? hi.y : lo.y, (k & 4) ? hi.z : lo.z, 1.0f}).xyz();
                occlusionShown.boxes.push_back(b);
            };
            for (const OccluderSource& s : sources) {
                const Vec3 lo = s.mesh ? s.mesh->bmin : s.boxMin, hi = s.mesh ? s.mesh->bmax : s.boxMax;
                addBox(s.model, lo, hi, false);
            }
            for (std::size_t i = 0; i < meshes.size(); ++i)
                if (hiddenFlag[i]) addBox(meshes[i].model, meshes[i].bmin, meshes[i].bmax, true);
        }
    }
}

void Renderer::Impl::occlusion_overlay() {
    if (debugView != DebugView::Occlusion || !occlusionPrev.valid) return;
    const Color green{0.2f, 1.0f, 0.3f, 1.0f}, red{1.0f, 0.2f, 0.2f, 1.0f};
    for (const OcclusionShown::Box& b : occlusionPrev.boxes)
        for (const auto& e : kBoxEdges)
            debug.line(b.corners[std::size_t(e[0])], b.corners[std::size_t(e[1])], b.culled ? red : green);
    debug.text({8.0f, 8.0f},
               std::format("occlusion: {} occluders (green), {} tests, {} hidden (red)", occlusionPrev.occluders,
                           occlusionPrev.tests, occlusionPrev.occluded),
               Color::white(), 16.0f);
}

Json Renderer::occlusion_report(std::string_view savePath) {
    Json out = Json::object();
    if (!impl_) return out;
    Impl& im = *impl_;
    const Impl::OcclusionShown& s = im.occlusionShown;
    out["supported"] = true;
    out["debugView"] = im.debugView == DebugView::Occlusion;
    out["active"] = s.valid;
    out["limits"] = Json::object({{"width", render::kOcclusionWidth},
                                  {"trianglesPerOccluder", int(im.occlusionLimits.perOccluder)},
                                  {"trianglesPerCamera", int(im.occlusionLimits.perFrame)}});
    if (!s.valid) {
        out["message"] = "No camera of the last frame had an enabled Occluder, so nothing was rasterised. Hint: add an "
                         "Occluder component "
                         "(shape box or mesh) to an entity, draw a frame (game.step), and call this again.";
        return out;
    }
    out["camera"] = s.camera;
    out["width"] = im.occlusion.ready() ? im.occlusion.width() : 0;
    out["height"] = im.occlusion.ready() ? im.occlusion.height() : 0;
    out["occluders"] = s.occluders;
    out["triangles"] = s.sourceTriangles;
    out["coveredCells"] = s.coveredCells;
    out["tests"] = s.tests;
    out["hidden"] = s.occluded;
    if (!savePath.empty() && im.occlusion.ready()) {
        Image img;
        img.width = im.occlusion.width();
        img.height = im.occlusion.height();
        img.rgba.resize(std::size_t(img.width) * std::size_t(img.height) * 4);
        const std::vector<std::uint8_t> grey = im.occlusion.grey();
        for (std::size_t i = 0; i < grey.size(); ++i) {
            img.rgba[4 * i] = img.rgba[4 * i + 1] = img.rgba[4 * i + 2] = grey[i];
            img.rgba[4 * i + 3] = 255;
        }
        const Result<void> saved = save_png(img, savePath);
        if (!saved)
            out["error"] =
                std::format("could not write {}: {} {}", savePath, saved.error().message, saved.error().hint);
        else
            out["file"] = std::string(savePath);
    }
    return out;
}

}  // namespace fa
