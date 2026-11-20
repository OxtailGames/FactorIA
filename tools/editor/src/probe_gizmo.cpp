// The viewport gizmo of LightProbeGroup (View > Show light probes, the Lightmap panel's "Show probes", and LightProbeGroup.showGizmo on each
// group): one small sphere per probe, coloured by the light it baked (the SH's irradiance for an upward normal), a grey one before the first
// bake or when the group was edited after it, and a red cross for a probe that lies inside geometry (the renderer ignores it). At most 2048
// probes are drawn in all (a stride over every group), none behind the camera. Nothing here reads a file on the UI thread except
// Renderer::light_probes, which loads the probe file the renderer itself needs, once. refresh_probe_cache also tells the Lightmap panel
// which groups changed since the bake.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/scene/lightmap_bake.h"
#include "fa/scene/light_probes.h"

namespace fa::editor {

namespace {

constexpr std::size_t kMaxDrawnProbes =
    2048;  // all groups together: a big scene is drawn with a stride (a hint, not a plot)

std::uint64_t group_key(const LightProbeGroup& g, Vec3 pos) {
    std::uint64_t h = 1469598103934665603ull;
    auto mix = [&](const void* p, std::size_t n) {
        const auto* b = static_cast<const unsigned char*>(p);
        for (std::size_t i = 0; i < n; ++i) h = (h ^ b[i]) * 1099511628211ull;
    };
    const float f[] = {g.size.x,   g.size.y,   g.size.z, g.spacing, g.offset.x,
                       g.offset.y, g.offset.z, pos.x,    pos.y,     pos.z};
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

void Editor::refresh_probe_cache(Renderer& r) {
    const int frame = ImGui::GetFrameCount();
    if (frame == probeCacheFrame_) return;
    probeCacheFrame_ = frame;
    World& w = world();
    baked_probes_ = r.light_probes(w);
    const ProbeSet* baked = baked_probes_ && baked_probes_->baked() ? baked_probes_ : nullptr;
    probeStaleGroups_ = 0;
    probeGroupsBaked_ = 0;
    std::vector<std::string> seen;
    w.each<LightProbeGroup>([&](Entity e, LightProbeGroup& g) {
        if (!w.active_in_hierarchy(e)) return;
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
        c.showGizmo = g.showGizmo;
        c.stale = false;
        c.baked.clear();
        if (!c.error.empty() || c.set.size() == 0) return;
        // A group of this entity (its grid, its points) is as baked when the file holds one of the same id, kind and layout.
        bool anyStale = false;
        for (const ProbeGroup& sg : c.set.groups) {
            const ProbeGroup* bg = baked ? find_same_probe_group(*baked, c.set, sg) : nullptr;
            c.baked.push_back(bg);
            if (baked && !bg) anyStale = true;
        }
        c.stale = anyStale;
        if (anyStale)
            ++probeStaleGroups_;
        else if (baked)
            ++probeGroupsBaked_;
    });
    // Forget the groups that are gone, so the cache never grows with the scenes a session opens.
    for (auto it = probeGizmo_.begin(); it != probeGizmo_.end();) {
        if (std::find(seen.begin(), seen.end(), it->first) == seen.end())
            it = probeGizmo_.erase(it);
        else
            ++it;
    }
}

void Editor::draw_probe_gizmos(ImDrawList* dl, Renderer& r, Vec3 eye, Vec3 forward,
                               const std::function<ImVec2(Vec3)>& project_world) {
    if (!showProbes_) return;
    refresh_probe_cache(r);
    const ProbeSet* baked = baked_probes_ && baked_probes_->baked() ? baked_probes_ : nullptr;
    // One budget for the whole scene: a stride over every drawn probe, so many groups do not each add their own 2048.
    std::size_t total = 0;
    for (const auto& [id, c] : probeGizmo_)
        if (c.showGizmo && c.error.empty()) total += c.set.size();
    const std::size_t stride = std::max<std::size_t>(1, (total + kMaxDrawnProbes - 1) / kMaxDrawnProbes);
    for (const auto& [id, c] : probeGizmo_) {
        if (!c.showGizmo || !c.error.empty() || c.set.size() == 0) continue;
        for (std::size_t gi = 0; gi < c.set.groups.size(); ++gi) {
            const ProbeGroup& sg = c.set.groups[gi];
            const ProbeGroup* bg = gi < c.baked.size() ? c.baked[gi] : nullptr;
            for (std::int32_t k = 0; k < sg.count; k += std::int32_t(stride)) {
                const std::size_t i = std::size_t(sg.first) + std::size_t(k);
                const Vec3 pos = c.set.positions[i];
                if (dot(pos - eye, forward) <= 0.01f) continue;  // behind the camera
                const ImVec2 p = project_world(pos);
                const std::size_t bi = bg ? std::size_t(bg->first) + std::size_t(k) : 0;
                if (bg && baked && !baked->valid[bi]) {
                    dl->AddLine(ImVec2(p.x - 4, p.y - 4), ImVec2(p.x + 4, p.y + 4), IM_COL32(255, 70, 60, 255), 2.0f);
                    dl->AddLine(ImVec2(p.x - 4, p.y + 4), ImVec2(p.x + 4, p.y - 4), IM_COL32(255, 70, 60, 255), 2.0f);
                    continue;
                }
                const ImU32 col = bg && baked ? probe_color(baked->sh[bi]) : IM_COL32(150, 150, 150, 255);
                dl->AddCircleFilled(p, 4.5f, col);
                dl->AddCircle(p, 4.5f, IM_COL32(0, 0, 0, 200), 12, 1.0f);
            }
        }
    }
}

}  // namespace fa::editor
