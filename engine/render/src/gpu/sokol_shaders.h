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

// The interface's desc of a generated shader in the dialect `device` consumes (sokol_context.cpp): GLSL 4.10 / 4.30 on
// Gl, GLSL ES 3.00 on Gles3 and WebGl2, HLSL 5 on D3d11 and D3d12, the MSL of the device's MetalTarget on Metal, SPIR-V
// on Vulkan (in a file compiled with FA_SHADERS_SPIRV: fa_render where FA_RENDER_VULKAN is on), and on Recording the
// dialect of the open sokol context (the built one when none is open). The strings and bytecode stay the header's
// (static data): the result is valid for the whole run. A header without that dialect (SPIR-V in a build without it, a
// Metal-only shader elsewhere) logs an error and gives an empty desc, which make_shader refuses.
class Device;
ShaderDesc generated_shader_desc(const Device& device, GeneratedShader fn);

}  // namespace fa::gpu
