#include "light_layers.h"

#include <algorithm>
#include <cmath>

namespace fa::render {

int LightLayerPlan::buffer_of(std::int32_t layers) const {
    for (const Mask& m : masks)
        if (m.layers == layers) return m.buffer;
    return kLoop;
}

LightLayerPlan plan_light_layers(const std::vector<Light2DData>& lights, const std::vector<std::int32_t>& receivers,
                                 bool bufferPath, int maxBuffers) {
    LightLayerPlan plan;
    for (std::int32_t mask : receivers) {
        bool known = false;
        for (const LightLayerPlan::Mask& k : plan.masks) known = known || k.layers == mask;
        if (known) continue;
        LightLayerPlan::Mask m;
        m.layers = mask;
        if (!bufferPath) {
            m.buffer = LightLayerPlan::kLoop;
        } else {
            std::vector<int> set;
            for (std::size_t i = 0; i < lights.size(); ++i)
                if (lights[i].pos[3] >= 0.0f && light_reaches(lights[i].layers, mask)) set.push_back(int(i));
            if (set.empty()) {
                m.buffer = LightLayerPlan::kNoPoint;
            } else {
                int found = -1;
                for (std::size_t b = 0; b < plan.buffers.size(); ++b)
                    if (plan.buffers[b] == set) found = int(b);
                if (found < 0 && int(plan.buffers.size()) < std::max(1, maxBuffers)) {
                    plan.buffers.push_back(std::move(set));
                    found = int(plan.buffers.size()) - 1;
                }
                if (found < 0) plan.overflowed = true;
                m.buffer = found >= 0 ? found : LightLayerPlan::kLoop;
            }
        }
        plan.masks.push_back(m);
    }
    return plan;
}

std::vector<TextureAsset*> assign_cookie_cells(std::vector<Light2DData>& lights, int* dropped) {
    std::vector<TextureAsset*> cells;
    int lost = 0;
    std::vector<TextureAsset*> lostTex;
    for (Light2DData& l : lights) {
        l.cookieCell = -1;
        if (!l.cookieTex || l.pos[3] < 0.0f) continue;  // only point lights have a cookie
        const auto it = std::find(cells.begin(), cells.end(), l.cookieTex);
        if (it != cells.end()) {
            l.cookieCell = int(it - cells.begin());
        } else if (int(cells.size()) < kMaxCookies2D) {
            cells.push_back(l.cookieTex);
            l.cookieCell = int(cells.size()) - 1;
        } else if (std::find(lostTex.begin(), lostTex.end(), l.cookieTex) == lostTex.end()) {
            lostTex.push_back(l.cookieTex);
            ++lost;
        }
    }
    if (dropped) *dropped = lost;
    return cells;
}

CookieShaderData cookie_shader_data(const Light2DData& light, bool flipV) {
    CookieShaderData d;
    if (light.cookieCell < 0 || !light.cookieTex || light.pos[3] <= 0.0f) return d;
    const float step = 1.0f / float(kCookieGrid);
    const int cx = light.cookieCell % kCookieGrid, cy = light.cookieCell / kCookieGrid;
    d.cell[0] = float(cx) * step;
    if (flipV) {
        d.cell[1] = 1.0f - float(cy) * step;
        d.cell[2] = -step;
    } else {
        d.cell[1] = float(cy) * step;
        d.cell[2] = step;
    }
    d.cell[3] = step;
    d.xf[0] = std::cos(light.cookieRot);
    d.xf[1] = std::sin(light.cookieRot);
    const float width = 2.0f * light.pos[3] * std::max(light.cookieScale, 0.001f);
    d.xf[2] = 1.0f / std::max(width, 1e-4f);
    return d;
}

}  // namespace fa::render
