#include "mesh_buffer_draw.h"

#include <algorithm>
#include <cstring>
#include <string>

#include "compute_internal.h"
#include "fa/scene/components.h"

namespace fa::render {

namespace {

// Reports a failure once per entity and material (Assets::note_failure keys on the path), and marks the use as skipped.
// `key` (when not empty) replaces the message in that key: a message with a count that changes every frame (instances,
// the buffer's size) would otherwise log one line per value.
MeshBufferUse& fail(MeshBufferUse& use, Assets& assets, const MeshItem& mi, const std::string& pointer,
                    std::string message, const std::string& hint, const std::string& key = std::string()) {
    use.skip = true;
    const std::string entity = std::to_string(mi.entity.bits());
    // What Assets::build_material forgets when the material builds again: its path, " on ", then what is wrong. The
    // message is part of the key, so another problem of the same entity is reported too, and the same one only once.
    const std::string path = (mi.material ? mi.material->path : std::string("MeshRenderer")) + " on entity " + entity +
                             ": " + (key.empty() ? message : key);
    const bool pointed = message.compare(0, pointer.size(), pointer) == 0;  // ComputeDrawAccess::bind names it already
    assets.note_failure("material-mesh", path,
                        "entity " + entity + ", MeshRenderer" + (pointed ? "" : pointer + ": ") + message, hint);
    return use;
}

}  // namespace

MeshBufferUse resolve_mesh_buffers(Assets& assets, Compute* compute, const MeshItem& mi) {
    MeshBufferUse use;
    const MaterialAsset* mat = mi.material && mi.material->ok ? mi.material : nullptr;
    if (!mat || mat->kind != MaterialKind::Mesh || mat->buffers.empty()) {
        // instances > 0 asks for a draw from buffers: without a material that reads some there is nothing to place the
        // instances (a material that failed to build already reports its own error and draws with the error material).
        if (mi.mr->instances > 0 && !(mi.material && !mi.material->ok))
            fail(use, assets, mi, "/instances",
                 "instances is " + std::to_string(mi.mr->instances) + " but the material " +
                     (mi.material ? "'" + mi.material->path + "' declares no \"buffers\"" : std::string("is not set")),
                 "Set MeshRenderer.material to a mesh material that declares \"buffers\" "
                 "(docs/shaders/SHADERS_COMPUTE.md, "
                 "\"Drawing from a compute buffer\"), or set instances to 0.",
                 mi.material ? "instances with a material without buffers" : "instances without a material");
        return use;
    }
    use.active = true;
    use.count = int(std::min<std::size_t>(mat->buffers.size(), kMaxMeshBuffers));
    const MeshRenderer& mr = *mi.mr;
    if (!compute) {
        fail(
            use, assets, mi, "/material",
            "the renderer has no compute support to read the buffers of '" + mat->path + "'",
            "Use a material without \"buffers\" (docs/shaders/SHADERS_COMPUTE.md, \"Drawing from a compute buffer\").");
        return use;
    }
    // The instance count: 0 draws once (the entity as a normal mesh); N draws N instances, each reading its own
    // element.
    if (mr.instances < 0 || mr.instances > kMaxMeshInstances) {
        fail(use, assets, mi, "/instances",
             "instances is " + std::to_string(mr.instances) + ", outside 0.." + std::to_string(kMaxMeshInstances),
             "Set instances to 0 (one normal draw) or the number of elements to draw.", "instances out of range");
        return use;
    }
    const std::uint64_t need = std::uint64_t(std::max<std::int32_t>(mr.instances, 1));
    for (int i = 0; i < use.count; ++i) {
        const MaterialBufferDef& def = mat->buffers[std::size_t(i)];
        const std::string pointer = "/materialParams/" + def.name;
        const bool isObject = mr.materialParams.is_object();
        const Json::const_iterator it = isObject ? mr.materialParams.find(def.name) : Json::const_iterator();
        if (!isObject || it == mr.materialParams.end()) {
            fail(use, assets, mi, pointer,
                 "'" + mat->path + "' reads the buffer '" + def.name +
                     "' but materialParams does not give its compute buffer id",
                 "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
            return use;
        }
        if (!it->is_number_integer()) {
            fail(use, assets, mi, pointer,
                 "'" + def.name + "' is the id of a compute buffer (an integer), not " + it->dump(),
                 "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
            return use;
        }
        const std::int64_t id = it->get<std::int64_t>();
        if (id < 0 || id > 0x7fffffff) {
            fail(use, assets, mi, pointer, "buffer id " + std::to_string(id) + " is not a compute buffer id",
                 "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
            return use;
        }
        auto bound = ComputeDrawAccess::bind(*compute, int(id), def, mat->path, pointer);
        if (!bound) {
            fail(use, assets, mi, pointer, bound.error().message, bound.error().hint);
            return use;
        }
        // Every buffer the material reads must hold one element per instance: the shader may index any of them with
        // fa_instance_index, and a read past the end of a storage buffer is undefined.
        if (bound->count < need) {
            fail(use, assets, mi, "/instances",
                 "instances is " + std::to_string(need) + " but the buffer '" + def.name + "' (" + pointer + ", id " +
                     std::to_string(id) + ") holds " + std::to_string(bound->count) + " elements",
                 "Make every buffer of the material for at least " + std::to_string(need) +
                     " elements (compute.create_buffer count) or lower instances; a buffer smaller than instances is "
                     "read past its end.",
                 "the buffer '" + def.name + "' holds fewer elements than instances");
            return use;
        }
        use.views[i] = bound->view;
    }
    use.instances = int(need);
    return use;
}

void bind_mesh_buffers(sg_bindings& b, const MeshBufferUse& use, const MaterialProgram& prog) {
    for (int i = 0; i < use.count; ++i) {
        const int vertexSlot = kMeshBufferFirstView + i;
        const int fragmentSlot = kMeshBufferFirstView + use.count + i;
        if (vertexSlot < SG_MAX_VIEW_BINDSLOTS && ((prog.viewMask >> vertexSlot) & 1u))
            b.views[vertexSlot] = use.views[i];
        if (fragmentSlot < SG_MAX_VIEW_BINDSLOTS && ((prog.viewMask >> fragmentSlot) & 1u))
            b.views[fragmentSlot] = use.views[i];
    }
}

void apply_mesh_base_model(const MaterialProgram& prog, const Mat4& model) {
    if (!prog.has_ub(kMeshInstanceBaseUniform)) return;
    float m[16];
    std::memcpy(m, model.m, sizeof m);
    sg_range range{m, sizeof m};
    sg_apply_uniforms(kMeshInstanceBaseUniform, &range);
}

}  // namespace fa::render
