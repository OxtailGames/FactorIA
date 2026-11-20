#include "fa/scene/gltf_file.h"

#include <cmath>
#include <format>

namespace fa {
namespace {

// `value` clamped to lo..hi; NaN gives `fallback`. A clamp is reported once.
float clamp_reported(float value, float lo, float hi, float fallback, const char* name, const std::string& what,
                     std::vector<std::string>& warnings) {
    if (std::isnan(value)) {
        warnings.push_back(std::format("{}: {} is not a number, {} is used", what, name, fallback));
        return fallback;
    }
    if (value < lo || value > hi) {
        const float to = value < lo ? lo : hi;
        warnings.push_back(std::format("{}: {} {} is outside {}..{}, clamped to {}", what, name, value, lo, hi, to));
        return to;
    }
    return value;
}

}  // namespace

void read_material_layers(const cgltf_material& m, const std::string& what, MaterialLayers& out,
                          std::vector<std::string>& warnings) {
    out = MaterialLayers{};
    if (m.has_clearcoat) {
        out.clearcoat =
            clamp_reported(m.clearcoat.clearcoat_factor, 0.0f, 1.0f, 0.0f, "clearcoatFactor", what, warnings);
        out.clearcoatRoughness = clamp_reported(m.clearcoat.clearcoat_roughness_factor, 0.0f, 1.0f, 0.0f,
                                                "clearcoatRoughnessFactor", what, warnings);
    }
    if (m.has_sheen) {
        for (int i = 0; i < 3; ++i)
            out.sheenColor[std::size_t(i)] =
                clamp_reported(m.sheen.sheen_color_factor[i], 0.0f, 1.0f, 0.0f, "sheenColorFactor", what, warnings);
        out.sheenRoughness =
            clamp_reported(m.sheen.sheen_roughness_factor, 0.0f, 1.0f, 0.0f, "sheenRoughnessFactor", what, warnings);
    }
    if (m.has_anisotropy) {
        out.anisotropy =
            clamp_reported(m.anisotropy.anisotropy_strength, -1.0f, 1.0f, 0.0f, "anisotropyStrength", what, warnings);
        out.anisotropyRotation = std::isfinite(m.anisotropy.anisotropy_rotation)
                                     ? std::fmod(m.anisotropy.anisotropy_rotation, 6.2831853f)
                                     : 0.0f;
    }
    if (m.has_specular) {
        out.specular = clamp_reported(m.specular.specular_factor, 0.0f, 1.0f, 1.0f, "specularFactor", what, warnings);
        for (int i = 0; i < 3; ++i)
            out.specularColor[std::size_t(i)] = clamp_reported(m.specular.specular_color_factor[i], 0.0f, 16.0f, 1.0f,
                                                               "specularColorFactor", what, warnings);
    }
    if (m.has_ior) out.ior = clamp_reported(m.ior.ior, 1.0f, 3.0f, 1.5f, "ior", what, warnings);
}

}  // namespace fa
