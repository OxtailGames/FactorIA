// Private to fa_render: the one door of the generated shader headers (shaders/*.glsl.h, made by sokol-shdc). Each of
// them needs sokol_gfx.h's declarations (it stops with #error without them) for its desc function (`const
// sg_shader_desc* x_shader_desc(sg_backend)`) and declares the uniform structs and the slot macros (ATTR_, UB_, VIEW_,
// SMP_) the renderer fills. Include this header before the first shaders/*.glsl.h of a file.
//
// TYPES ONLY: the renderer never calls sokol (docs/design/ARCHITECTURE_RENDERING_GPU.md, "P5d3"). A generated desc
// reaches the device through generated_shader_desc and Device::make_shader; every other GPU call goes through
// gpu::Device / gpu::CommandList.
#pragma once

#include "gpu/types.h"
#include "sokol_gfx.h"

namespace fa::gpu {

// The desc function of a generated shader header, e.g. mesh_mesh_shader_desc.
using GeneratedShader = const sg_shader_desc* (*)(sg_backend backend);

// The interface's desc of a generated shader for the backend of the open sokol context (sokol_context.cpp). The strings
// and bytecode stay the header's (static data): the result is valid for the whole run.
ShaderDesc generated_shader_desc(GeneratedShader fn);

}  // namespace fa::gpu
