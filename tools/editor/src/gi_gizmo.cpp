// The viewport gizmo of the selected RealtimeGI (M73-P5d-2b): the box its probes fill and one small marker per probe, at most 2048 of them
// (a stride over the grid beyond that, as the light probe gizmo does), none behind the camera, perspective views only. The layout is the
// renderer's own (gi_layout on the component, the same call the renderer makes), so the gizmo is where the probes are captured. A probe that
// already has a picture is a filled green dot and one still waiting for its first capture a grey ring (Renderer::gi_progress: the probes are
// captured in index order). Probes inside geometry (render.gi_grid lists them) are not marked: that needs a read-back of the atlas, which a
// frame never does.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/render/gi.h"

namespace fa::editor {

namespace {
constexpr int kMaxDrawnGiProbes = 2048;
}

void Editor::draw_gi_gizmo(ImDrawList* dl, Renderer& r, Entity grid, Vec3 eye, Vec3 forward,
                           const std::function<ImVec2(Vec3)>& project_world) {
    World& w = world();
    const RealtimeGI* c = w.get<RealtimeGI>(grid);
    if (!c) return;
    const Result<render::GiLayout> layout =
        render::gi_layout(*c, w.drawn_matrix(grid, true).translation(), w.id_of(grid));
    if (!layout.ok()) return;  // the Inspector and render.gi_grid say what is wrong
    const render::GiLayout& l = layout.value();
    const auto in_front = [&](Vec3 p) { return dot(p - eye, forward) > 0.01f; };
    // The box the probes fill (first probe .. last probe).
    const Vec3 lo = l.origin, hi = render::gi_probe_position(l, l.count - 1);
    Vec3 c8[8];
    for (int i = 0; i < 8; ++i) c8[i] = Vec3{(i & 1) ? hi.x : lo.x, (i & 2) ? hi.y : lo.y, (i & 4) ? hi.z : lo.z};
    static const int edges[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3},
                                     {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};
    for (const auto& ed : edges) {
        if (!in_front(c8[ed[0]]) || !in_front(c8[ed[1]])) continue;
        dl->AddLine(project_world(c8[ed[0]]), project_world(c8[ed[1]]), IM_COL32(120, 230, 140, 220), 1.5f);
    }
    const Renderer::GiProgress progress = r.gi_progress(grid);
    const int stride = std::max(1, (l.count + kMaxDrawnGiProbes - 1) / kMaxDrawnGiProbes);
    for (int i = 0; i < l.count; i += stride) {
        const Vec3 pos = render::gi_probe_position(l, i);
        if (!in_front(pos)) continue;
        const ImVec2 p = project_world(pos);
        if (!progress.known || i >= progress.captured) {
            dl->AddCircle(p, 3.5f, IM_COL32(170, 170, 170, 230), 10, 1.5f);
        } else {
            dl->AddCircleFilled(p, 3.5f, IM_COL32(120, 230, 140, 255));
            dl->AddCircle(p, 3.5f, IM_COL32(0, 0, 0, 200), 10, 1.0f);
        }
    }
}

}  // namespace fa::editor
