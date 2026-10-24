// GPU-free mesh geometry: the positions and triangles of a built-in primitive or a .gltf/.glb model. Physics builds its
// convex hulls and triangle-mesh colliders from this (fa_physics may not include fa_render); the renderer has its own
// loader that also reads normals, UVs and materials. Primitive sizes match the renderer's (fa_render assets.cpp).
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

struct MeshGeometry {
    std::vector<Vec3> positions;
    std::vector<std::uint32_t> indices;  // three per triangle, indexing `positions`
    Vec3 bmin{}, bmax{};                 // bounding box of `positions`
};

// "cube" (1 m), "sphere" (radius 0.5), "plane" (1 x 1 in XZ, y = 0), "quad" (1 x 1 in XY), "cylinder" (radius 0.5,
// height 1), "capsule" (radius 0.5, height 2: hemispheres centred at y = +-0.5), "cone" (radius 0.5, height 1, apex up).
// Anything else is a project-relative .gltf/.glb path (every mesh node, node transforms applied, triangle primitives
// only), read through fa::fs. Results are cached by name. Errors name the mesh, list the primitives and suggest a
// close one.
Result<std::shared_ptr<const MeshGeometry>> load_mesh_geometry(const std::string& mesh);

// The names of the materials a .gltf/.glb model uses on its triangle meshes (the names MeshRenderer.materialColors is keyed
// by), in file order, without duplicates; materials without a name are left out. Read through fa::fs.
Result<std::vector<std::string>> gltf_material_names(const std::string& path);

// The name a mesh is cached under: primitive names lower-cased, paths as written. Use it as a key for per-mesh data.
std::string mesh_key(const std::string& mesh);

}  // namespace fa
