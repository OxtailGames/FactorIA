// The material layers of a glTF material (M73.6): clear coat, sheen, anisotropy, the dielectric specular, transmission and volume.
// Read from the KHR_materials_clearcoat, _sheen, _anisotropy, _specular, _ior, _transmission and _volume extensions by read_material_layers (gltf_file.h), which the
// two glTF readers of the engine call (the model loader of the renderer and the editable-mesh importer, gltf_mesh.cpp).
#pragma once

#include <array>

namespace fa {

// The factors of the extensions. The defaults are "no layer": a material that has none of the extensions is drawn as before.
// What the renderer does with them: docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The material layers".
struct MaterialLayers {
    float clearcoat = 0.0f;                             // 0..1 strength of the clear coat (clearcoatFactor)
    float clearcoatRoughness = 0.0f;                    // 0..1 (clearcoatRoughnessFactor)
    std::array<float, 3> sheenColor{0.0f, 0.0f, 0.0f};  // linear colour of the sheen (sheenColorFactor); black = none
    float sheenRoughness = 0.0f;                        // 0..1 (sheenRoughnessFactor)
    float anisotropy = 0.0f;          // -1..1 stretch of the highlight (anisotropyStrength; glTF allows 0..1)
    float anisotropyRotation = 0.0f;  // radians (anisotropyRotation)
    float specular = 1.0f;            // 0..1 (specularFactor)
    std::array<float, 3> specularColor{1.0f, 1.0f, 1.0f};     // 0..16 (specularColorFactor)
    float ior = 1.5f;                                         // 1..3 (ior)
    float transmission = 0.0f;                                // 0..1 (transmissionFactor); 0 = opaque
    float thickness = 0.0f;                                   // metres, 0..1000 (thicknessFactor); 0 = a thin surface
    std::array<float, 3> attenuationColor{1.0f, 1.0f, 1.0f};  // 0..1 (attenuationColor)
    float attenuationDistance = 0.0f;  // metres, 0..100000 (attenuationDistance); 0 = no tint (glTF: infinity)

    bool operator==(const MaterialLayers&) const = default;
    // True when the material uses any layer or a specular / ior that is not the engine's own.
    bool any() const { return !(*this == MaterialLayers{}); }
};

}  // namespace fa
