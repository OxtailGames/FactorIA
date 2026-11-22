#include "fa/scene/lod.h"

#include <algorithm>
#include <cmath>
#include <limits>

#include "fa/core/det_math.h"
#include "fa/core/math.h"

namespace fa {

namespace {
// The `mesh` of an entry, or null when the entry is not an object with a non-empty mesh string.
const std::string* entry_mesh(const Json& e) {
    if (!e.is_object()) return nullptr;
    auto m = e.find("mesh");
    if (m == e.end() || !m->is_string() || m->get_ref<const std::string&>().empty()) return nullptr;
    return &m->get_ref<const std::string&>();
}
bool entry_number(const Json& e, const char* key, float& out) {
    auto d = e.find(key);
    if (d == e.end() || !d->is_number()) return false;
    out = d->get<float>();
    return true;
}
}  // namespace

const std::string& lod_mesh(const MeshRenderer& mr, float distance) {
    if (!mr.lods.is_array() || mr.lods.empty()) return mr.mesh;
    const std::string* pick = &mr.mesh;
    float best = -1.0f;
    for (const Json& e : mr.lods) {
        const std::string* m = entry_mesh(e);
        float at = 0.0f;
        if (!m || !entry_number(e, "distance", at)) continue;
        if (at <= distance && at >= best) {  // the farthest entry already reached
            best = at;
            pick = m;
        }
    }
    return *pick;
}

float lod_view_height(const LodView& view, float distance) {
    if (!view.perspective) return 2.0f * view.halfHeight;
    return 2.0f * std::max(distance, 0.0001f) * det::tan(radians(view.fovY) * 0.5f);
}

float lod_screen_size(float diameter, float distance, const LodView& view) {
    if (!std::isfinite(diameter) || diameter < 0.0f) return 0.0f;
    const float h = lod_view_height(view, distance);
    if (!(h > 0.0f)) return std::numeric_limits<float>::max();  // a degenerate camera: as close as it gets
    return diameter / h;
}

int lod_level_by_distance(const MeshRenderer& mr, float distance) {
    if (!mr.lods.is_array()) return 0;
    int level = 0;
    float best = -1.0f;
    int index = 0;
    for (const Json& e : mr.lods) {
        ++index;
        float at = 0.0f;
        if (!entry_mesh(e) || !entry_number(e, "distance", at)) continue;
        if (at <= distance && at >= best) {
            best = at;
            level = index;
        }
    }
    return level;
}

int lod_level_by_screen_size(const MeshRenderer& mr, float screenSize) {
    if (!mr.lods.is_array()) return 0;
    int level = 0;
    float best = std::numeric_limits<float>::infinity();
    int index = 0;
    for (const Json& e : mr.lods) {
        ++index;
        float at = 0.0f;
        if (!entry_mesh(e) || !entry_number(e, "screenSize", at)) continue;
        if (screenSize < at && at <= best) {  // the smallest threshold the size is already below
            best = at;
            level = index;
        }
    }
    return level;
}

int lod_level_of(const MeshRenderer& mr, float distance, float screenSize) {
    return mr.lodMode == LodMode::ScreenSize ? lod_level_by_screen_size(mr, screenSize)
                                             : lod_level_by_distance(mr, distance);
}

bool impostor_active(const MeshRenderer& mr, float distance, float screenSize) {
    if (mr.impostor.empty() || !(mr.impostorDistance > 0.0f)) return false;
    return mr.lodMode == LodMode::ScreenSize ? screenSize < mr.impostorDistance : distance >= mr.impostorDistance;
}

const std::string& lod_level_mesh(const MeshRenderer& mr, int level) {
    if (level <= 0 || !mr.lods.is_array() || std::size_t(level) > mr.lods.size()) return mr.mesh;
    const std::string* m = entry_mesh(mr.lods[std::size_t(level) - 1]);
    return m ? *m : mr.mesh;
}

int lod_group_level(const LodGroup& g, int childCount, float value) {
    if (childCount <= 0) return -1;
    if (std::isnan(value)) return 0;
    const bool screen = g.mode == LodMode::ScreenSize;
    int level = 0;
    const std::size_t n = std::min<std::size_t>(g.thresholds.size(), std::size_t(kMaxLodThresholds));
    for (std::size_t k = 0; k < n; ++k) {
        const float t = g.thresholds[k];
        if (screen ? value < t : value >= t) ++level;
    }
    return std::min(level, childCount - 1);
}

bool lod_hlod_reached(const LodGroup& g, float value) {
    if (g.hlodProxy.empty() || !(g.hlodThreshold > 0.0f) || std::isnan(value)) return false;
    return g.mode == LodMode::ScreenSize ? value < g.hlodThreshold : value >= g.hlodThreshold;
}

void lod_fade_step(LodFadeState& s, int target, float crossFade, float dt) {
    const bool fades = crossFade > 0.0f && std::isfinite(crossFade);
    if (!fades) {
        s = LodFadeState{target, -1, 1.0f};
        return;
    }
    if (target != s.level) {
        if (s.fading() && target == s.from) {  // back to the level that is leaving: the same picture, the other way
            s.from = s.level;
            s.level = target;
            s.t = 1.0f - s.t;
        } else {  // a new level: the one drawn now is where the fade starts (a fade still running is cut)
            s.from = s.level;
            s.level = target;
            s.t = 0.0f;
        }
    }
    if (s.fading()) {
        s.t += (dt > 0.0f && std::isfinite(dt)) ? dt / crossFade : 0.0f;
        if (!(s.t < 1.0f)) {
            s.t = 1.0f;
            s.from = -1;
        }
    }
}

float lod_fade_amount(const LodFadeState& s) {
    if (!s.fading()) return 0.0f;
    return std::clamp(s.t, 1.0f / 256.0f, 255.0f / 256.0f);
}

}  // namespace fa
