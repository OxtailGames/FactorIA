// The pointer through a render target: a MeshRenderer shows "target:<name>" (the picture of a camera with Camera.renderTarget), the
// pointer is over that mesh, and the point of the picture under it is found from the mesh's UV there. The UI then hit-tests the
// world-space Interactables as the target's camera sees them (UiSystem::set_surface_pointer). Works on any mesh whose UVs lay the
// picture out: a flat quad, a bent screen, a sphere, a procedural mesh (its current triangles: a page deformed every frame is hit
// against the shape it is drawn with).
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <set>

#include "engine_impl.h"
#include "fa/core/log.h"
#include "fa/render/renderer.h"
#include "fa/scene/camera_mask.h"
#include "fa/scene/components.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/mesh_surface.h"

namespace fa {

namespace {

// The render target a MeshRenderer shows: its texture, else the first material parameter that names one, else (a procedural mesh) the
// base color texture of its first submesh material that names one ("" for none).
std::string shown_target(const World& world, const MeshRenderer& mr) {
    if (const std::string n = render_target_name(mr.texture); !n.empty()) return n;
    if (mr.materialParams.is_object())
        for (const auto& [key, value] : mr.materialParams.items())
            if (value.is_string())
                if (const std::string n = render_target_name(value.get<std::string>()); !n.empty()) return n;
    if (MeshStore::is_id(mr.mesh))
        if (const MeshStore::Entry* e = world.meshes().find(mr.mesh))
            for (const MeshSubmesh& s : e->data.submeshes)
                if (const std::string n = render_target_name(s.material.texture); !n.empty()) return n;
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
        // The mesh is seen through the camera that draws at the pointer: a mesh that camera does not draw (Camera.showTags /
        // hideTags) is not there to be hit.
        const CameraMask mainMask = CameraMask::of(world, r->camera_at(pos));
        world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
            if (pin && pin->mesh != e) return;
            if (mr.mesh.empty() || !world.active_in_hierarchy(e) || !mainMask.draws(world, e)) return;
            std::string target = shown_target(world, mr);
            if (target.empty()) return;
            static std::set<std::string> warned;
            auto surface = load_mesh_surface(world.meshes(), mr.mesh);
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
        s.mask = CameraMask::of(world, view->camera);  // only what the page's camera draws is on the page
        s.point = {uv.x * float(view->width), uv.y * float(view->height)};
        s.project = [to = view->to_pixels](Vec3 p, const Vec2*) { return to(p); };
        s.pin = UiSurfacePin{best->e, bestHit.triangle};
        s.camera = view->camera;
        return s;
    };
}

// ------------------------------------------------------------------------------------------------------------ the way back --
// game.click on a widget that only a render target shows: the inverse of the pointer above. The widget's hit area in the target
// camera's view is a quad of page pixels; a point inside it is a UV of the picture; a mesh showing the picture has points with that UV;
// the main camera puts one of them on the screen. The point is only used when the pointer path itself (UiSystem::widget_at, the same
// code a real mouse goes through) answers this widget there, so a mesh in front, another widget on top or a bent surface that hides
// the place are all noticed and the next point is tried.
UiPageAimFn make_ui_page_aim(Engine::Impl& I) {
    return [&I](Entity widget) -> UiPageAim {
        UiPageAim out;
        Renderer* r = I.renderer.get();
        World& world = I.world;
        if (!r || !r->initialized() || r->cameras().empty() || !world.alive(widget)) return out;

        // The pages whose camera draws the widget.
        struct Page {
            std::string name;
            Renderer::RenderTargetView view;
        };
        std::vector<Page> pages;
        std::set<std::string> seen;
        world.each<Camera>([&](Entity, Camera& c) {
            if (c.renderTarget.empty() || !seen.insert(c.renderTarget).second) return;
            auto view = r->render_target_view(world, c.renderTarget);
            if (view && view->to_pixels && CameraMask::of(world, view->camera).draws(world, widget)) pages.push_back({c.renderTarget, std::move(*view)});
        });
        if (pages.empty()) return out;
        out.relevant = true;

        const Vec2 design = I.design_size();
        const VisualMeasure measure = I.measure();
        const UiSurfaceFn forward = make_ui_surface_pointer(I);
        const std::string who = "'" + world.id_of(widget) + "'";
        std::vector<std::string> notes;  // why no point worked, one line per page
        for (const Page& page : pages) {
            const std::string where = "render target '" + page.name + "' (camera '" + world.id_of(page.view.camera) + "', picture " +
                                      std::to_string(page.view.width) + "x" + std::to_string(page.view.height) + " px)";
            std::vector<Entity> meshes;
            world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
                if (!mr.mesh.empty() && shown_target(world, mr) == page.name) meshes.push_back(e);
            });
            if (meshes.empty()) {
                notes.push_back("no MeshRenderer shows " + where + ", so the widget is drawn nowhere a player can see (set MeshRenderer.texture to \"target:" +
                                page.name + "\")");
                continue;
            }
            const std::size_t shown = meshes.size();
            std::erase_if(meshes, [&](Entity m) { return !world.active_in_hierarchy(m); });
            if (meshes.empty()) {
                notes.push_back(std::string(shown == 1 ? "the MeshRenderer that shows " : "every MeshRenderer that shows ") + where +
                                " is inactive (active = false on it or a parent), so nothing draws the page (activate it)");
                continue;
            }
            // The pointer only reaches meshes the main camera draws: a page shown on a mesh that only another render target draws is out of reach.
            std::string unreachable;
            std::erase_if(meshes, [&](Entity m) {
                const Vec2 centre = r->world_to_screen(world.world_matrix(m).translation());
                if (CameraMask::of(world, r->camera_at(centre)).draws(world, m)) return false;
                unreachable += (unreachable.empty() ? "'" : ", '") + world.id_of(m) + "'";
                return true;
            });
            if (meshes.empty()) {
                notes.push_back("the mesh that shows " + where + " (" + unreachable + ") is not drawn by the main camera (Camera.showTags / hideTags) and the pointer only "
                                "reaches meshes the main camera draws, so a render target shown inside another render target cannot be clicked (let the main camera draw the mesh)");
                continue;
            }
            const std::optional<std::array<Vec2, 4>> quad = I.ui.interactable_quad(
                world, widget, design, measure, [to = page.view.to_pixels](Vec3 p, const Vec2*) { return to(p); },
                CameraMask::of(world, page.view.camera));
            if (!quad) {
                notes.push_back("it has no hit area in " + where);
                continue;
            }
            const float W = float(page.view.width), H = float(page.view.height);
            float x0 = (*quad)[0].x, x1 = x0, y0 = (*quad)[0].y, y1 = y0;
            for (const Vec2& q : *quad) {
                x0 = std::min(x0, q.x);
                x1 = std::max(x1, q.x);
                y0 = std::min(y0, q.y);
                y1 = std::max(y1, q.y);
            }
            if (x1 < 0 || y1 < 0 || x0 > W || y0 > H) {
                char box[96];
                std::snprintf(box, sizeof box, "[%.0f, %.0f] to [%.0f, %.0f]", x0, y0, x1, y1);
                notes.push_back("it is outside the view of " + where + ": its hit area is at page pixels " + box +
                                ", so the picture does not show it (move the widget into the camera's view, or the camera onto it)");
                continue;
            }
            // Points of the hit area, the centre first, then a grid, kept inside the picture.
            std::vector<Vec2> samples;
            const auto at = [&](float a, float b) {  // bilinear in the quad: a along corner 0 -> 1, b along 0 -> 3
                const auto& q = *quad;
                const Vec2 top = q[0] * (1 - a) + q[1] * a, bottom = q[3] * (1 - a) + q[2] * a;
                return top * (1 - b) + bottom * b;
            };
            samples.push_back(at(0.5f, 0.5f));
            for (float b : {0.5f, 0.25f, 0.75f, 0.1f, 0.9f})
                for (float a : {0.5f, 0.25f, 0.75f, 0.1f, 0.9f})
                    if (!(a == 0.5f && b == 0.5f)) samples.push_back(at(a, b));

            int notOnMesh = 0, offScreen = 0, covered = 0, tried = 0;
            std::string lastCover;
            for (const Vec2& q : samples) {
                if (q.x < 0 || q.y < 0 || q.x > W || q.y > H) continue;
                ++tried;
                bool onMesh = false;
                for (Entity m : meshes) {
                    MeshRenderer& mr = *world.get<MeshRenderer>(m);
                    if (!world.active_in_hierarchy(m)) continue;
                    auto surface = load_mesh_surface(world.meshes(), mr.mesh);
                    if (!surface) continue;
                    // forward is uv * uvScale (tiled); the first tile is the way back
                    const Vec2 uv{q.x / W / std::max(mr.uvScale.x, 1e-6f), q.y / H / std::max(mr.uvScale.y, 1e-6f)};
                    for (const SurfacePoint& sp : surface_points_at_uv(*surface.value(), world.world_matrix(m), uv)) {
                        onMesh = true;
                        const Vec2 screen = r->world_to_screen(sp.world);
                        if (!(screen.x >= 0 && screen.y >= 0 && screen.x <= design.x && screen.y <= design.y) || !std::isfinite(screen.x) ||
                            !std::isfinite(screen.y)) {
                            ++offScreen;
                            continue;
                        }
                        const std::optional<UiSurface> reached = forward(screen, nullptr);
                        if (reached && reached->pin.mesh == m && I.ui.widget_at(world, design, screen, measure) == widget) {
                            out.point = screen;
                            out.mesh = m;
                            out.camera = page.view.camera;
                            return out;
                        }
                        ++covered;
                        if (!reached) lastCover = "nothing the pointer reaches is there (the main camera does not draw the mesh, a ray misses it, or it is behind the camera)";
                        else if (reached->pin.mesh != m) lastCover = "mesh '" + world.id_of(reached->pin.mesh) + "' is in front of it";
                        else lastCover = "another widget is on top there";
                    }
                }
                if (!onMesh) ++notOnMesh;
            }
            if (tried == 0)
                notes.push_back("no point of its hit area is inside the picture of " + where);
            else if (covered > 0)
                notes.push_back("its place on the mesh is covered: " + lastCover + " (move the camera or the mesh, or hide what covers it)");
            else if (offScreen > 0)
                notes.push_back("the mesh that shows " + where + " is off the screen where the widget is (point the main camera at it)");
            else if (notOnMesh == tried)
                notes.push_back("no mesh that shows " + where + " covers the widget's place of the picture (the mesh's UVs do not map there, or the mesh is inactive)");
            else
                notes.push_back("no point of it can be reached through a mesh that shows " + where);
        }
        out.problem = "it is drawn only on a page, never by the main view, and no click can reach it through a mesh: " + [&] {
            std::string all;
            for (const std::string& n : notes) all += (all.empty() ? "" : "; ") + n;
            return all;
        }();
        return out;
    };
}

}  // namespace fa
