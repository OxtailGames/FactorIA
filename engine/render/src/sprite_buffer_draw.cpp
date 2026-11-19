#include "sprite_buffer_draw.h"

#include <algorithm>
#include <string>

#include "compute_internal.h"
#include "fa/scene/components.h"

namespace fa::render {

namespace {

constexpr const char* kDocs = "docs/shaders/SHADERS_COMPUTE.md, \"Sprites from a compute buffer\"";

// Reports a failure once per entity and message (Assets::note_failure keys on the path) and marks the use as skipped.
MeshBufferUse& fail(MeshBufferUse& use, Assets& assets, const MaterialUse* material, Entity e,
                    const std::string& pointer, std::string message, const std::string& hint) {
    use.skip = true;
    const std::string entity = std::to_string(e.bits());
    const std::string path = (material && material->material ? material->material->path : std::string("Sprite")) +
                             " on entity " + entity + ": " + message;
    const bool pointed = message.compare(0, pointer.size(), pointer) == 0;  // ComputeDrawAccess::bind names it already
    assets.note_failure("material-sprite", path,
                        "entity " + entity + ", Sprite" + (pointed ? "" : pointer + ": ") + message, hint);
    return use;
}

}  // namespace

MeshBufferUse resolve_sprite_buffers(Assets& assets, Compute* compute, Entity e, const Sprite& s,
                                     const MaterialUse* material) {
    MeshBufferUse use;
    use.instances = 1;
    const MaterialAsset* mat = material && !material->error ? material->material : nullptr;
    if (!mat || mat->kind != MaterialKind::Sprite || mat->buffers.empty()) {
        // instances > 0 asks for a draw from buffers: without a material that reads some there is nothing to place the instances
        // (a material that failed to build already reports its own error and draws with the error material).
        if (s.instances > 0 && !(material && material->error))
            fail(use, assets, material, e, "/instances",
                 "instances is " + std::to_string(s.instances) + " but the material " +
                     (mat ? "'" + mat->path + "' declares no \"buffers\"" : std::string("is not set")),
                 std::string("Set Sprite.material to a sprite material that declares \"buffers\" (") + kDocs +
                     "), or set instances to 0.");
        return use;
    }
    use.active = true;
    use.count = int(std::min<std::size_t>(mat->buffers.size(), kMaxMeshBuffers));
    if (!compute) {
        fail(use, assets, material, e, "/material",
             "the renderer has no compute support to read the buffers of '" + mat->path + "'",
             std::string("Use a material without \"buffers\" (") + kDocs + ").");
        return use;
    }
    if (s.instances < 0 || s.instances > kMaxMeshInstances) {
        fail(use, assets, material, e, "/instances",
             "instances is " + std::to_string(s.instances) + ", outside 0.." + std::to_string(kMaxMeshInstances),
             "Set instances to 0 (one normal quad) or the number of elements to draw.");
        return use;
    }
    const std::uint64_t need = std::uint64_t(std::max<std::int32_t>(s.instances, 1));
    for (int i = 0; i < use.count; ++i) {
        const MaterialBufferDef& def = mat->buffers[std::size_t(i)];
        const std::string pointer = "/materialParams/" + def.name;
        const bool isObject = s.materialParams.is_object();
        const Json::const_iterator it = isObject ? s.materialParams.find(def.name) : Json::const_iterator();
        if (!isObject || it == s.materialParams.end()) {
            fail(use, assets, material, e, pointer,
                 "'" + mat->path + "' reads the buffer '" + def.name +
                     "' but materialParams does not give its compute buffer id",
                 "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
            return use;
        }
        if (!it->is_number_integer()) {
            fail(use, assets, material, e, pointer,
                 "'" + def.name + "' is the id of a compute buffer (an integer), not " + it->dump(),
                 "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
            return use;
        }
        const std::int64_t id = it->get<std::int64_t>();
        if (id < 0 || id > 0x7fffffff) {
            fail(use, assets, material, e, pointer, "buffer id " + std::to_string(id) + " is not a compute buffer id",
                 "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
            return use;
        }
        auto bound = ComputeDrawAccess::bind(*compute, int(id), def, mat->path, pointer);
        if (!bound) {
            fail(use, assets, material, e, pointer, bound.error().message, bound.error().hint);
            return use;
        }
        // Every buffer the material reads must hold one element per instance: the shader may index any of them with
        // fa_instance_index, and a read past the end of a storage buffer is undefined.
        if (bound->count < need) {
            fail(use, assets, material, e, "/instances",
                 "instances is " + std::to_string(need) + " but the buffer '" + def.name + "' (" + pointer + ", id " +
                     std::to_string(id) + ") holds " + std::to_string(bound->count) + " elements",
                 "Make every buffer of the material for at least " + std::to_string(need) +
                     " elements (compute.create_buffer count) or lower instances; a buffer smaller than instances is "
                     "read past its end.");
            return use;
        }
        use.views[i] = bound->view;
    }
    use.instances = int(need);
    return use;
}

bool bind_sprite_buffer_views(Assets& assets, Compute* compute, const MaterialUse& use, int instances,
                              MeshBufferUse& out) {
    const MaterialAsset* mat = use.material;
    out = MeshBufferUse{};
    out.instances = instances;
    out.count = int(std::min<std::size_t>(mat->buffers.size(), kMaxMeshBuffers));
    auto gone = [&](const std::string& message, const std::string& hint) {
        assets.note_failure("material-sprite", mat->path + " at draw: " + message,
                            "Sprite drawn with '" + mat->path + "': " + message, hint);
        return false;
    };
    if (!compute) return gone("the renderer has no compute support", std::string("See ") + kDocs + ".");
    for (int i = 0; i < out.count; ++i) {
        const MaterialBufferDef& def = mat->buffers[std::size_t(i)];
        const std::int64_t id = use.bufferIds[i];
        if (id < 0 || id > 0x7fffffff)
            return gone("the buffer '" + def.name + "' has no compute buffer id",
                        "Set materialParams." + def.name + " to the id compute.create_buffer returned.");
        auto bound = ComputeDrawAccess::bind(*compute, int(id), def, mat->path, "/materialParams/" + def.name);
        if (!bound) return gone(bound.error().message, bound.error().hint);
        if (bound->count < std::uint64_t(std::max(instances, 1)))
            return gone("the buffer '" + def.name + "' (id " + std::to_string(id) + ") holds " +
                            std::to_string(bound->count) + " elements, fewer than the " + std::to_string(instances) +
                            " instances drawn",
                        "Make the buffer for at least " + std::to_string(instances) + " elements.");
        out.views[i] = bound->view;
    }
    out.active = true;
    return true;
}

}  // namespace fa::render
