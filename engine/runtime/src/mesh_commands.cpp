// The commands that make and edit procedural meshes (fa/scene/mesh_store.h, docs/SCRIPTING.md, "Procedural meshes"):
// mesh.create, mesh.update, mesh.destroy, mesh.save, mesh.list and mesh.info. The script API (`mesh` in "factoria") does the
// same through the same MeshStore of the World, so what a command made a script can use and the other way round.
//
// A procedural mesh is run-time data: it is not part of a scene file, and loading a scene releases every mesh. Use mesh.save
// to turn one into a .glb file that scenes can name.
#include <format>

#include "engine_impl.h"
#include "fa/core/strings.h"
#include "fa/scene/mesh_store.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

[[noreturn]] void fail(const Error& e) { throw CommandError("invalid_argument", e.message, e.hint); }

std::string need_id(const Json& a) {
    if (!a.contains("id") || !a["id"].is_string() || a["id"].get<std::string>().empty())
        throw CommandError("invalid_argument", "Missing 'id'.", "Pass the id mesh.create returned, e.g. {\"id\":\"mesh:1\"}. mesh.list shows the live ones.");
    return a["id"].get<std::string>();
}

// The array fields shared by mesh.create and mesh.update.
const char* kMeshProps = R"({
    "positions":{"description":"Vertex positions: a flat list [x, y, z, x, y, z, ...] or a list of [x, y, z]. Three numbers per vertex."},
    "indices":{"description":"Vertex numbers, three per triangle (flat, or a list of [a, b, c]). create: left out = every three vertices make a triangle. update: left out = kept."},
    "normals":{"description":"Three numbers per vertex, normalized for you. Left out = computed (smooth, weighted by triangle area). Never kept from an earlier call."},
    "uvs":{"description":"Two numbers per vertex ((0,0) is the top-left of the image). Left out = zeros (create) or kept (update)."},
    "tangents":{"description":"Four (xyz + handedness +1/-1) or three numbers per vertex, for normal maps. Left out = computed from the uvs."},
    "colors":{"description":"Three (rgb) or four (rgba) numbers per vertex. Drawn like glTF COLOR_0: they multiply the material's base color (rgb and alpha; alpha shows with a material with blend: true and cuts holes with a custom material that has alphaMode clip) in every 3D draw path, clamped to 0..1 with 8 bits per channel, and are saved as COLOR_0 in a .glb. Left out = white (create) or kept (update)."},
    "submeshes":{"type":"array","description":"Runs of the index list with their own material: [{material, start?, count?}]. material is a name or {name, color, texture, metallic, roughness, emissive, doubleSided, blend}; start and count count indices (multiples of 3); start defaults to where the previous submesh ends, count to the end of the index list. Left out = one submesh over all indices (update: the existing ones are kept)."}
})";

Json schema_with(const char* extraRequired, const char* extraProps, bool requirePositions) {
    Json props = parse_schema(kMeshProps);
    if (extraProps && *extraProps) {
        Json extra = parse_schema(extraProps);
        for (auto it = extra.begin(); it != extra.end(); ++it) props[it.key()] = it.value();
    }
    Json s = Json::object({{"type", "object"}, {"properties", props}});
    Json req = Json::array();
    if (extraRequired && *extraRequired) req.push_back(extraRequired);
    if (requirePositions) req.push_back("positions");
    if (!req.empty()) s["required"] = req;
    return s;
}

}  // namespace

void register_mesh_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add({"mesh.create", "Create a procedural mesh from arrays and get its id for MeshRenderer.mesh.",
           "Builds geometry at run time, without writing a file: `positions` (three numbers per vertex), `indices` (three per "
           "triangle; left out = a triangle soup), and optionally `normals`, `uvs`, `tangents`, `colors` and `submeshes` "
           "(runs of the index list with their own material). Missing normals and tangents are computed. Conventions are glTF's: "
           "+Y up, right-handed, counter-clockwise triangles face front, uv (0,0) is the top-left of the image. Everything is "
           "checked and an error names the field, the counts and the fix (array length, index outside the vertices, submesh outside "
           "the index list). Result: the info of mesh.info with `id` (\"mesh:N\"). Set MeshRenderer.mesh (and Collider3D.mesh for a "
           "convex or mesh collider) to that id; culling, shadows, picking and the editor's selection use the mesh's real bounds. "
           "The mesh belongs to the running scene: loading a scene releases every mesh, and it is not written to scene files "
           "(scene validation rejects an id in a file): use mesh.save for a file. At most 256 meshes, 1048576 vertices and "
           "6291456 indices each. Vertex colors multiply the base color. Example: mesh.create {\"positions\":[0,0,0, 1,0,0, 0,1,0],"
           "\"indices\":[0,1,2],\"submeshes\":[{\"material\":{\"name\":\"skin\",\"color\":[0.9,0.7,0.5,1]}}]}",
           schema_with(nullptr, nullptr, true), false, "render"},
          [&I](const Json& a) {
              auto in = mesh_input_from_json(a);
              if (!in.ok()) fail(in.error());
              auto id = I.world.meshes().create(*in);
              if (!id.ok()) fail(id.error());
              return mesh_info_json(*I.world.meshes().find(*id));
          });

    I.commands.add({"mesh.update", "Replace the data of a procedural mesh; arrays left out are kept.",
           "Takes the same arrays as mesh.create. `positions`, `uvs`, `colors`, `indices` and `submeshes` that are left out are "
           "kept; normals and tangents are computed again unless given. Changing the vertex count needs the other per-vertex "
           "arrays to fit it (errors say which); changing `indices` of a mesh with several submeshes needs `submeshes` too. Cheap "
           "enough to call every frame: the GPU buffers are reused while the new data fits. A Collider3D (convex or mesh) that "
           "uses the mesh rebuilds its shape on every update, which is costly for big meshes. Result: the info of mesh.info. "
           "Example: mesh.update {\"id\":\"mesh:1\",\"positions\":[0,0,0, 2,0,0, 0,2,0]}",
           schema_with("id", R"({"id":{"type":"string","description":"The mesh to change (\"mesh:N\")."}})", false), false, "render"},
          [&I](const Json& a) {
              const std::string id = need_id(a);
              auto in = mesh_input_from_json(a);
              if (!in.ok()) fail(in.error());
              if (auto r = I.world.meshes().update(id, *in); !r.ok()) fail(r.error());
              return mesh_info_json(*I.world.meshes().find(id));
          });

    I.commands.add({"mesh.destroy", "Free a procedural mesh.",
           "Entities that still name the id draw the missing-mesh placeholder and the engine logs why once: set their `mesh` "
           "first. Errors for an unknown id with the live ids. Result: {destroyed: id}. Example: mesh.destroy {\"id\":\"mesh:1\"}",
           parse_schema(R"({"type":"object","required":["id"],"properties":{"id":{"type":"string","description":"The mesh (\"mesh:N\")."}}})"),
           false, "render"},
          [&I](const Json& a) {
              const std::string id = need_id(a);
              if (auto r = I.world.meshes().destroy(id); !r.ok()) fail(r.error());
              return Json::object({{"destroyed", id}});
          });

    I.commands.add({"mesh.save", "Write a procedural mesh as a .glb file that loads back as a normal model.",
           "One node, one primitive per submesh with its material (name, base color, metallic/roughness, emissive, double-sided, "
           "blend, base color texture by a relative uri), vertex colors as COLOR_0. `path` is project-relative and ends in .glb; "
           "it may not be inside .factoria/ (except .factoria/tmp/). A material whose texture is a run-time texture cannot be "
           "saved (the file would point to nothing): use a project image. A mesh with no metallic/roughness set is written with "
           "the defaults (0 and 0.6). Afterwards MeshRenderer.mesh = the path loads it like any model. Result: {saved: path, "
           "submeshes}. Example: mesh.save {\"id\":\"mesh:1\",\"path\":\"assets/models/tree.glb\"}",
           parse_schema(R"({"type":"object","required":["id","path"],"properties":{
               "id":{"type":"string","description":"The mesh (\"mesh:N\")."},
               "path":{"type":"string","description":"Project-relative file ending in .glb."}}})"),
           false, "render"},
          [&I](const Json& a) {
              const std::string id = need_id(a);
              if (!a.contains("path") || !a["path"].is_string())
                  throw CommandError("invalid_argument", "Missing 'path'.", "Pass the file to write, e.g. \"assets/models/tree.glb\".");
              auto got = I.world.meshes().get(id);
              if (!got.ok()) fail(got.error());
              auto saved = save_mesh_glb((*got)->data, a["path"].get<std::string>());
              if (!saved.ok()) fail(saved.error());
              return Json::object({{"saved", *saved}, {"submeshes", (*got)->data.submeshes.size()}});
          });

    I.commands.add({"mesh.list", "List the live procedural meshes of the running scene.",
           "Result: {meshes: [info...], count}. Each info: {id, version, vertices, triangles, hasColors, bounds, submeshes}. "
           "Example: mesh.list {}",
           parse_schema(R"({"type":"object","properties":{}})"), true, "render"},
          [&I](const Json&) {
              Json list = Json::array();
              for (const std::string& id : I.world.meshes().ids()) list.push_back(mesh_info_json(*I.world.meshes().find(id)));
              return Json::object({{"count", list.size()}, {"meshes", list}});
          });

    I.commands.add({"mesh.info", "Describe one procedural mesh: counts, bounds, submeshes and materials.",
           "Result: {id, version, vertices, triangles, hasColors, bounds: {min, max}, submeshes: [{material, start, count}]}. "
           "`version` grows with every mesh.update. Errors for an unknown or destroyed id with the live ids. "
           "Example: mesh.info {\"id\":\"mesh:1\"}",
           parse_schema(R"({"type":"object","required":["id"],"properties":{"id":{"type":"string","description":"The mesh (\"mesh:N\")."}}})"),
           true, "render"},
          [&I](const Json& a) {
              auto got = I.world.meshes().get(need_id(a));
              if (!got.ok()) fail(got.error());
              return mesh_info_json(**got);
          });
}

}  // namespace fa
