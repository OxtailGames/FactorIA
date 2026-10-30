// GPU-free mesh surface: the triangles of a built-in primitive or a .gltf/.glb model WITH their texture coordinates, and a
// ray test that answers where on the texture a ray lands. The pointer reaches a render target through it (a MeshRenderer
// whose texture is "target:<name>" shows that camera's picture; the point under the mouse is a UV, so a pixel of the
// picture). The vertices and UVs are the ones the renderer draws (fa_render assets.cpp), which a test keeps true.
#pragma once

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

struct MeshSurface {
    std::vector<Vec3> positions;
    std::vector<Vec2> uvs;               // one per position (texcoord 0; (0, 0) for a model without any)
    std::vector<std::uint32_t> indices;  // three per triangle, indexing `positions`
};

// The surface of `mesh`: a primitive name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad") or a
// project-relative .gltf/.glb path (every mesh node, node transforms applied, triangle primitives only). Cached by name.
// Errors name the mesh and say what to use instead.
Result<std::shared_ptr<const MeshSurface>> load_mesh_surface(const std::string& mesh);

class MeshStore;
// The same for a mesh of a World: a procedural id ("mesh:N") is read from `store` (MeshStore::surface: the current triangles and uvs,
// rebuilt only after a mesh.update), anything else goes through load_mesh_surface(mesh). The pointer through a render target calls this
// every frame, so a page that bends every frame is hit-tested against the shape it is drawn with.
Result<std::shared_ptr<const MeshSurface>> load_mesh_surface(MeshStore& store, const std::string& mesh);

// Where a ray meets a surface.
struct SurfaceHit {
    float distance = 0.0f;       // along the ray, in the units of `dir` (world units when `dir` is normalized)
    Vec2 uv;                     // the texture coordinate at the hit
    std::uint32_t triangle = 0;  // index of the first of its three indices, divided by 3
};

// The nearest hit of the ray (`origin`, `dir` in world space) with the surface drawn with `model` (mesh space -> world).
// Both sides of a triangle count: a screen seen from behind still answers (mirrored, like it is drawn).
std::optional<SurfaceHit> raycast_surface(const MeshSurface& surface, const Mat4& model, Vec3 origin, Vec3 dir);

// The texture coordinate where the ray meets the PLANE of one triangle, which may lie outside the triangle (the
// coordinates are extended linearly). Used to keep a drag going while the pointer leaves the mesh. nullopt when the ray
// is parallel to the plane or the triangle has no area.
std::optional<Vec2> surface_uv_on_plane(const MeshSurface& surface, const Mat4& model, std::uint32_t triangle, Vec3 origin, Vec3 dir);

}  // namespace fa
