// The pointer through a render target: a MeshRenderer shows "target:<name>" (the picture of a camera with Camera.renderTarget), the
// pointer is over that mesh, and the point of the picture under it is found from the mesh's UV there. The UI then hit-tests the
// world-space Interactables as the target's camera sees them (UiSystem::set_surface_pointer). Works on any mesh whose UVs lay the
// picture out: a flat quad, a bent screen, a sphere.
#include <cmath>
#include <set>

#include "engine_impl.h"
#include "fa/core/log.h"
#include "fa/render/renderer.h"
#include "fa/scene/components.h"
#include "fa/scene/mesh_surface.h"

namespace fa {

namespace {

// The render target a MeshRenderer shows: its texture, else the first material parameter that names one ("" for none).
std::string shown_target(const MeshRenderer& mr) {
    if (const std::string n = render_target_name(mr.texture); !n.empty()) return n;
    if (mr.materialParams.is_object())
        for (const auto& [key, value] : mr.materialParams.items())
            if (value.is_string())
                if (const std::string n = render_target_name(value.get<std::string>()); !n.empty()) return n;
    return {};
}

}  // namespace

UiSurfaceFn make_ui_surface_pointer(Engine::Impl& I) {
    return [&I](Vec2 pos, const UiSurfacePin* pin) -> std::optional<UiSurface> {
        Renderer* r = I.renderer.get();
        if (!r || !r->initialized() || r->cameras().empty()) return std::nullopt;
        World& world = I.world;
        struct Candidate {
            Entity e;
            std::string target;
            std::shared_ptr<const MeshSurface> surface;
            Mat4 model;
            Vec2 uvScale;
        };
        std::vector<Candidate> candidates;
        world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
            if (pin && pin->mesh != e) return;
            if (mr.mesh.empty() || !world.active_in_hierarchy(e)) return;
            std::string target = shown_target(mr);
            if (target.empty()) return;
            static std::set<std::string> warned;
            auto surface = load_mesh_surface(mr.mesh);
            if (!surface) {
                if (warned.insert(mr.mesh).second)
                    FA_WARN("ui", "MeshRenderer '{}' shows render target '{}' but the pointer cannot reach it: {}. Hint: {}", world.id_of(e),
                            target, surface.error().message, surface.error().hint);
                return;
            }
            candidates.push_back({e, std::move(target), surface.value(), world.world_matrix(e), mr.uvScale});
        });
        if (candidates.empty()) return std::nullopt;

        Vec3 origin, dir;
        r->screen_ray(pos, origin, dir, r->camera_at(pos));
        const Candidate* best = nullptr;
        SurfaceHit bestHit;
        Vec2 uv;
        bool extrapolated = false;
        for (const Candidate& c : candidates) {
            if (const auto hit = raycast_surface(*c.surface, c.model, origin, dir)) {
                if (best && hit->distance >= bestHit.distance) continue;
                best = &c;
                bestHit = *hit;
                uv = hit->uv;
            }
        }
        if (!best && pin && !candidates.empty()) {  // a drag that left the mesh: the plane of its last triangle goes on
            if (const auto on = surface_uv_on_plane(*candidates[0].surface, candidates[0].model, pin->triangle, origin, dir)) {
                best = &candidates[0];
                bestHit.triangle = pin->triangle;
                uv = *on;
                extrapolated = true;
            }
        }
        if (!best) return std::nullopt;
        const auto view = r->render_target_view(world, best->target);
        if (!view || !view->to_pixels) return std::nullopt;
        uv = uv * best->uvScale;
        if (!extrapolated) {  // tiling repeats the picture; a point that left the mesh keeps counting outside it
            if (best->uvScale.x > 1.0f) uv.x -= std::floor(uv.x);
            if (best->uvScale.y > 1.0f) uv.y -= std::floor(uv.y);
        }
        UiSurface s;
        s.point = {uv.x * float(view->width), uv.y * float(view->height)};
        s.project = [to = view->to_pixels](Vec3 p, const Vec2*) { return to(p); };
        s.pin = UiSurfacePin{best->e, bestHit.triangle};
        return s;
    };
}

}  // namespace fa
