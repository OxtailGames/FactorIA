// Drawing a MeshRenderer from compute buffers (M72.4, docs/shaders/SHADERS_COMPUTE.md "Drawing from a compute buffer"):
// a mesh material that declares "buffers" reads them in its vertex() and surface() as read-only storage buffers, and
// the entity draws MeshRenderer.instances GPU instances. The CPU only sets the instance count (sokol_gfx has no
// indirect draw).
//
// The draw loops (renderer_draw.cpp) ask resolve_mesh_buffers once per batch and pass; the rest is here, so the loops
// carry a few lines. An entity whose material has buffers is a batch of its own (render_scene.cpp mixes its entity into
// the sort key), so `instances` is the count of that one entity.
#pragma once

#include "gpu/device.h"
#include "mesh_batch.h"

namespace fa {
class Compute;
}

namespace fa::render {

struct MeshBufferUse {
    bool active =
        false;          // the material declares buffers: its model matrix is the uniform block kMeshInstanceBaseUniform
    bool skip = false;  // draw nothing: a buffer is missing or does not fit, or the backend cannot (logged once)
    int instances = 1;  // the instance count of every draw call (1 = MeshRenderer.instances 0)
    int count = 0;      // the material's buffers
    gpu::View views[kMaxMeshBuffers]{};
};

// The buffers `mi` is drawn with: the compute buffer ids of `mi.mr->materialParams` checked against the layouts the
// material declares, and MeshRenderer.instances against their sizes. A failure sets `skip` and is reported once through
// Assets::note_failure (JSON pointer, the entity, what to change). A material without buffers answers `active` false.
MeshBufferUse resolve_mesh_buffers(Assets& assets, Compute* compute, const MeshItem& mi);

// Whether the depth and normal prepass draws a part (renderer_draw.cpp: prepass_pass, and fill_fs for the per-pixel GI, which reads the image the prepass
// made, so the two never differ). `fullWithoutPrepass`: a full shader that keeps out of the image (prepass false); `use`: the part's mesh buffers;
// `hasPrepassProgram`: the material has a prepass program for this part (else the engine's program draws, and it cannot place what buffers place).
inline bool prepass_draws(bool fullWithoutPrepass, const MeshBufferUse& use, bool hasPrepassProgram) {
    if (fullWithoutPrepass || use.skip) return false;
    return !(use.active && !hasPrepassProgram);
}

// Binds the views to the slots `prog` declares for them (the vertex stage's copy and the fragment stage's copy of each
// buffer).
void bind_mesh_buffers(gpu::Bindings& b, const MeshBufferUse& use, const MaterialProgram& prog);

// Applies the entity's model matrix as the vertex uniform block of a program that declares it.
void apply_mesh_base_model(gpu::CommandList& list, const MaterialProgram& prog, const Mat4& model);

}  // namespace fa::render
