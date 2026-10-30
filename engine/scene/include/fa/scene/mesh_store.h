// Procedural meshes: geometry a script (or a command) builds at run time and uses as MeshRenderer.mesh through an id.
//
// The data lives in the World's MeshStore, GPU-free: the renderer uploads it (fa_render, Assets::procedural_mesh), physics
// builds a collider from it (fa_physics), the editor picks against it, and `mesh.save` writes it as a .glb. A scene load
// (World::clear) releases every mesh, so a script that kept an id across a scene change finds a teaching error, not a
// mesh of another scene.
//
// Conventions are glTF's: right-handed, +Y up, counter-clockwise triangles face front, uv (0,0) is the top-left of the
// image (v grows downwards), tangents are xyz + a handedness w of +1 or -1.
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_geometry.h"
#include "fa/scene/mesh_surface.h"

namespace fa {

// The look of one submesh: the fields of a glTF material the renderer reads. `name` is what MeshRenderer.materialColors
// is keyed by.
struct MeshMaterial {
    std::string name;
    Color color{1, 1, 1, 1};            // base color factor
    std::string texture;                // base color texture: a project-relative image path ("" = none)
    std::optional<float> metallic;      // 0..1; with `roughness`, replaces MeshRenderer.metallic/roughness for this submesh
    std::optional<float> roughness;     // 0..1
    Color emissive{0, 0, 0, 1};         // emissive factor (rgb)
    bool doubleSided = false;           // draw back faces too
    bool blend = false;                 // alpha-blended (drawn far to near with the other transparent meshes)
};

// A run of the index list drawn with one material.
struct MeshSubmesh {
    MeshMaterial material;
    std::uint32_t start = 0;  // first index, a multiple of 3
    std::uint32_t count = 0;  // number of indices, a multiple of 3
};

constexpr std::uint32_t kSubmeshToEnd = 0xFFFFFFFFu;  // MeshSubmesh::count in an input: up to the end of the index list

// What a caller gives: flat float arrays (x,y,z,x,y,z...). Empty = not given.
struct MeshInput {
    std::vector<float> positions;   // 3 per vertex
    std::vector<float> normals;     // 3 per vertex; computed (smooth, area-weighted) when absent
    std::vector<float> uvs;         // 2 per vertex; zeros when absent
    std::vector<float> tangents;    // 4 (xyzw) or 3 (xyz, w = 1) per vertex; computed from the uvs when absent
    std::vector<float> colors;      // 4 (rgba) or 3 (rgb) per vertex; multiply the base color when drawn (glTF COLOR_0) and are saved as COLOR_0
    std::vector<std::uint32_t> indices;  // three per triangle; when absent on create: 0,1,2,3,4,5... (a triangle soup)
    std::vector<MeshSubmesh> submeshes;  // absent = one submesh with a default material over all the indices
    bool hasIndices = false;        // `indices` was given (an empty list is then an error, not "absent")
};

// A validated mesh: every array complete and consistent.
struct MeshData {
    std::vector<float> positions;
    std::vector<float> normals;     // unit length
    std::vector<float> uvs;         // 2 per vertex (zeros when never given)
    std::vector<float> tangents;    // 4 per vertex
    std::vector<float> colors;      // 4 per vertex, or empty
    std::vector<std::uint32_t> indices;
    std::vector<MeshSubmesh> submeshes;  // at least one; each inside the index list (indices outside every submesh are not drawn)
    bool hasUvs = false;            // the uvs were given (an update keeps them; otherwise they are zeros again for any vertex count)
    Vec3 bmin{}, bmax{};
    std::size_t vertex_count() const { return positions.size() / 3; }
    std::size_t triangle_count() const { return indices.size() / 3; }
};

constexpr std::size_t kMaxProceduralMeshes = 256;           // live meshes per scene
constexpr std::size_t kMaxProceduralVertices = 1u << 20;    // vertices per mesh
constexpr std::size_t kMaxProceduralIndices = 6u << 20;     // indices per mesh

// Checks `in` (array lengths, index and submesh ranges, finite numbers) and completes it. Errors name the field and the
// value and say how to fix it. `base`, when given, supplies the arrays `in` leaves out (positions, uvs, colors, indices
// and submeshes; normals and tangents are always computed again) - the rule of mesh.update.
Result<MeshData> build_mesh_data(const MeshInput& in, const MeshData* base = nullptr);

// The meshes of one World. Ids are "mesh:N", N counting up for the whole life of the store (clear() does not reset it).
class MeshStore {
public:
    struct Entry {
        std::string id;
        std::uint64_t version = 1;  // grows with every update: the renderer re-uploads when it differs from its copy
        MeshData data;
        std::shared_ptr<const MeshGeometry> geometry;  // positions + triangles for physics and picking; built on demand
        std::uint64_t geometryVersion = 0;
        std::shared_ptr<const MeshSurface> surface;  // positions + uvs + triangles for the pointer through a render target; on demand
        std::uint64_t surfaceVersion = 0;
    };

    MeshStore();
    static bool is_id(std::string_view s);  // "mesh:" followed by digits
    // Different for every MeshStore ever made in the process (a clear() keeps it): lets the renderer tell the store it has meshes of
    // from another one, also when a new World lands at the address of a freed one.
    std::uint64_t serial() const { return serial_; }

    Result<std::string> create(const MeshInput& in);
    Result<void> update(const std::string& id, const MeshInput& in);
    Result<void> destroy(const std::string& id);
    // nullptr when the id is not alive. `why` (optional) gets the teaching error.
    const Entry* find(const std::string& id) const;
    Result<const Entry*> get(const std::string& id) const;  // the same with the teaching error
    std::vector<std::string> ids() const;
    std::size_t size() const { return entries_.size(); }
    void clear() { entries_.clear(); }  // keeps the id counter

    // The collider/picking geometry of the mesh (cached per version); nullptr when the id is not alive.
    std::shared_ptr<const MeshGeometry> geometry(const std::string& id);
    // The drawn triangles of the mesh with their uvs (indices outside every submesh are left out, as they are not drawn), for
    // raycast_surface: built on first use and again only after an update (cached per version, so a mesh that is deformed every frame
    // is rebuilt once per update and one that did not change costs nothing); nullptr when the id is not alive.
    std::shared_ptr<const MeshSurface> surface(const std::string& id);

private:
    std::map<std::string, std::unique_ptr<Entry>> entries_;
    std::uint64_t next_ = 1;
    std::uint64_t serial_ = 0;
};

// The geometry of any MeshRenderer.mesh value for picking and colliders: a procedural id through `store`, else
// load_mesh_geometry (primitive or glTF). nullptr when it cannot be had; `error` (optional) gets why.
std::shared_ptr<const MeshGeometry> mesh_geometry_for(MeshStore& store, const std::string& mesh, std::string* error = nullptr);

// The nearest hit of the ray origin + t * dir (t >= 0, `dir` need not be unit length) with the triangles of `g`, both faces
// (Moeller-Trumbore): the editor's picking of a procedural mesh. False when it misses; `t` is then left alone.
bool ray_hits_mesh(const MeshGeometry& g, Vec3 origin, Vec3 dir, float& t);

// Reads the JSON form of a mesh (the arguments of the mesh.create / mesh.update commands): `positions`, `normals`, `uvs`,
// `tangents`, `colors` each a flat list of numbers or a list of [x, y, z] (or {x, y, z}) entries; `indices` a flat list or
// a list of [a, b, c] triangles; `submeshes` a list of { material, start?, count? } (material: a name or an object
// { name, color, texture, metallic, roughness, emissive, doubleSided, blend }; start defaults to where the previous submesh
// ends, count to the rest of the index list). Errors name the field and the entry.
Result<MeshInput> mesh_input_from_json(const Json& args);
// A material from its JSON form (a name, or the object above); `where` names it in errors.
Result<MeshMaterial> mesh_material_from_json(const Json& j, const std::string& where);
// { id, version, vertices, triangles, hasColors, bounds: {min, max}, submeshes: [{ material: {...}, start, count }] }
Json mesh_info_json(const MeshStore::Entry& e);

// The .glb bytes of a mesh: one node and one mesh, one primitive per submesh (POSITION, NORMAL, TEXCOORD_0, TANGENT, and
// COLOR_0 when the mesh has colors) with its material. `glbPath` (project-relative) is where the file will be written:
// base color textures are referenced by a uri relative to its folder. A material texture that is not a project file (a
// "runtime:N" id) is an error.
Result<std::vector<std::uint8_t>> mesh_to_glb(const MeshData& data, const std::string& glbPath);

// Writes the mesh as a .glb at `path` (project-relative, must end in .glb and be a place commands may write) and returns
// the normalized path. The file loads back as a normal model with the mesh's submeshes and materials.
Result<std::string> save_mesh_glb(const MeshData& data, const std::string& path);

}  // namespace fa
