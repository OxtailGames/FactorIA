// The viewport gizmo of LightProbeGroup (View > Lightmap, "Show probes", and LightProbeGroup.showGizmo on each group): one small sphere per
// probe, coloured by the light it baked (the SH's irradiance for an upward normal), a grey one before the first bake or when the group was
// edited after it, and a red cross for a probe that lies inside geometry (the renderer ignores it). Nothing here reads a file on the UI
// thread except Renderer::light_probes, which loads the probe file the renderer itself needs, once.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/scene/lightmap_bake.h"
#include "fa/scene/light_probes.h"

namespace fa::editor {

namespace {

constexpr std::size_t kMaxDrawnPerGroup = 2048;  // a big grid is drawn with a stride: the gizmo is a hint, not a plot

std::uint64_t group_key(const LightProbeGroup& g, Vec3 pos) {
    std::uint64_t h = 1469598103934665603ull;
    auto mix = [&](const void* p, std::size_t n) {
        const auto* b = static_cast<const unsigned char*>(p);
        for (std::size_t i = 0; i < n; ++i) h = (h ^ b[i]) * 1099511628211ull;
    };
    const float f[] = {g.size.x, g.size.y,   g.size.z,   g.spacing, g.offset.x,
                       g.offset.y, g.offset.z, pos.x,      pos.y,     pos.z};
    mix(f, sizeof f);
    const char grid = g.grid ? 1 : 0;
    mix(&grid, 1);
    const std::string pts = g.points.dump();
    mix(pts.data(), pts.size());
    return h;
}

ImU32 probe_color(const ShL2& sh) {
    const Vec3 l = sh_irradiance(sh, Vec3{0, 1, 0});
    auto ch = [](float v) {  // a soft shoulder, then a gamma 2.2 for the screen
        v = std::max(v, 0.0f);
        v = v / (1.0f + v);
        return int(std::clamp(std::pow(v * 2.0f, 1.0f / 2.2f), 0.0f, 1.0f) * 255.0f + 0.5f);
    };
    return IM_COL32(ch(l.x), ch(l.y), ch(l.z), 255);
}

}  // namespace

void Editor::draw_probe_gizmos(ImDrawList* dl, Renderer& r, const std::function<ImVec2(Vec3)>& project_world) {
    World& w = world();
    if (!showProbes_) return;
    const ProbeSet* baked = r.light_probes(w);
    std::vector<std::string> seen;
    w.each<LightProbeGroup>([&](Entity e, LightProbeGroup& g) {
        if (!g.showGizmo || !w.active_in_hierarchy(e)) return;
        const std::string id = w.id_of(e);
        const Vec3 pos = w.world_position(e);
        seen.push_back(id);
        ProbeGizmoCache& c = probeGizmo_[id];
        const std::uint64_t key = group_key(g, pos);
        if (c.key != key || !c.built) {
            c.key = key;
            c.built = true;
            c.set = ProbeSet{};
            c.error = add_probe_group(c.set, id, g, pos) ? std::string() : std::string("x");
        }
        if (!c.error.empty() || c.set.size() == 0) return;
        // The baked probes of this group, when they are the group as it is now (the same count and the same first and last point).
        const ProbeGroup* bg = nullptr;
        if (baked && baked->baked()) {
            for (const ProbeGroup& cand : baked->groups)
                if (cand.id == id && std::size_t(cand.count) == c.set.size()) bg = &cand;
            if (bg) {
                auto same = [](Vec3 a, Vec3 b) {
                    return std::fabs(a.x - b.x) < 1e-3f && std::fabs(a.y - b.y) < 1e-3f && std::fabs(a.z - b.z) < 1e-3f;
                };
                const std::size_t last = c.set.size() - 1;
                if (!same(baked->positions[size_t(bg->first)], c.set.positions[0]) ||
                    !same(baked->positions[size_t(bg->first) + last], c.set.positions[last]))
                    bg = nullptr;
            }
        }
        const std::size_t n = c.set.size();
        const std::size_t stride = std::max<std::size_t>(1, (n + kMaxDrawnPerGroup - 1) / kMaxDrawnPerGroup);
        for (std::size_t i = 0; i < n; i += stride) {
            const ImVec2 p = project_world(c.set.positions[i]);
            const std::size_t bi = bg ? size_t(bg->first) + i : 0;
            if (bg && !baked->valid[bi]) {
                dl->AddLine(ImVec2(p.x - 4, p.y - 4), ImVec2(p.x + 4, p.y + 4), IM_COL32(255, 70, 60, 255), 2.0f);
                dl->AddLine(ImVec2(p.x - 4, p.y + 4), ImVec2(p.x + 4, p.y - 4), IM_COL32(255, 70, 60, 255), 2.0f);
                continue;
            }
            const ImU32 col = bg ? probe_color(baked->sh[bi]) : IM_COL32(150, 150, 150, 255);
            dl->AddCircleFilled(p, 4.5f, col);
            dl->AddCircle(p, 4.5f, IM_COL32(0, 0, 0, 200), 12, 1.0f);
        }
    });
    // Forget the groups that are gone, so the cache never grows with the scenes a session opens.
    for (auto it = probeGizmo_.begin(); it != probeGizmo_.end();) {
        if (std::find(seen.begin(), seen.end(), it->first) == seen.end())
            it = probeGizmo_.erase(it);
        else
            ++it;
    }
}

}  // namespace fa::editor
