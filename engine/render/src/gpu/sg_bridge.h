// Private to fa_render, TRANSITIONAL (M77-P2..P5): the bridge between the GPU interface (gpu/types.h, gpu/device.h)
// and the sokol types the renderer's code still uses while it moves over. It goes away with the last sg_* call site
// (M77-P5); docs/design/ARCHITECTURE_RENDERING_GPU.md, "How the renderer reaches the device", says how to use it.
//
//  * to_sg / from_sg: every enum of gpu/types.h has sokol's values, so an enum converts with a static_cast
//    (sokol_device.cpp asserts each value) and a handle by its id: gpu::Image{img.id} and sg_image{h.id} name the same
//    image. The descs are converted field by field (sokol_device.cpp).
//  * gpu::bridged::*: a handle of the interface that also converts to and from its sokol twin. A converted function
//    returns one where unconverted code still takes the sokol type (Gpu's pipeline getters, samplers and buffers),
//    so neither side needs a to_sg at every call. Do not put one in a ternary next to an sg_* value (each converts to
//    the other: the compiler cannot choose); write to_sg() or from_sg() on one side.
//  * GeneratedShader / generated_shader_desc: the generated shader headers (shaders/*.glsl.h) return sokol descs.
//  * begin_context_pass / end_context_pass: a pass on the sokol context itself, for the one pass that may run before
//    any device exists (Renderer::present_clear, through Gpu::begin_pass).
#pragma once

#include <cstdint>

#include "gpu/types.h"
#include "sokol_gfx.h"

namespace fa::gpu {

// ---- handles: the same id ----------------------------------------------------------------------------------------
inline sg_buffer to_sg(Buffer h) { return sg_buffer{h.id}; }
inline sg_image to_sg(Image h) { return sg_image{h.id}; }
inline sg_view to_sg(View h) { return sg_view{h.id}; }
inline sg_sampler to_sg(Sampler h) { return sg_sampler{h.id}; }
inline sg_shader to_sg(Shader h) { return sg_shader{h.id}; }
inline sg_pipeline to_sg(Pipeline h) { return sg_pipeline{h.id}; }
inline Buffer from_sg(sg_buffer h) { return Buffer{h.id}; }
inline Image from_sg(sg_image h) { return Image{h.id}; }
inline View from_sg(sg_view h) { return View{h.id}; }
inline Sampler from_sg(sg_sampler h) { return Sampler{h.id}; }
inline Shader from_sg(sg_shader h) { return Shader{h.id}; }
inline Pipeline from_sg(sg_pipeline h) { return Pipeline{h.id}; }

// A handle of the interface that converts to and from its sokol twin (see the header comment).
template <class Tag, class Sg>
struct SgBridge : Handle<Tag> {
    constexpr SgBridge() = default;
    constexpr SgBridge(Handle<Tag> h) : Handle<Tag>(h) {}   // NOLINT(google-explicit-constructor): the point of it
    constexpr SgBridge(Sg h) : Handle<Tag>{h.id} {}         // NOLINT(google-explicit-constructor)
    constexpr operator Sg() const { return Sg{this->id}; }  // NOLINT(google-explicit-constructor)
};

namespace bridged {
using Buffer = SgBridge<BufferTag, sg_buffer>;
using Image = SgBridge<ImageTag, sg_image>;
using View = SgBridge<ViewTag, sg_view>;
using Sampler = SgBridge<SamplerTag, sg_sampler>;
using Shader = SgBridge<ShaderTag, sg_shader>;
using Pipeline = SgBridge<PipelineTag, sg_pipeline>;
}  // namespace bridged

// ---- enums: the same value ---------------------------------------------------------------------------------------
inline sg_pixel_format to_sg(PixelFormat f) { return static_cast<sg_pixel_format>(f); }
inline PixelFormat from_sg(sg_pixel_format f) { return static_cast<PixelFormat>(f); }
inline sg_resource_state to_sg(ResourceState s) { return static_cast<sg_resource_state>(s); }
inline ResourceState from_sg(sg_resource_state s) { return static_cast<ResourceState>(s); }
inline sg_load_action to_sg(LoadAction a) { return static_cast<sg_load_action>(a); }
inline LoadAction from_sg(sg_load_action a) { return static_cast<LoadAction>(a); }
inline sg_store_action to_sg(StoreAction a) { return static_cast<sg_store_action>(a); }
inline StoreAction from_sg(sg_store_action a) { return static_cast<StoreAction>(a); }
inline sg_pass_state to_sg(PassState s) { return static_cast<sg_pass_state>(s); }
inline PassState from_sg(sg_pass_state s) { return static_cast<PassState>(s); }
inline sg_color to_sg(const Color& c) { return sg_color{c.r, c.g, c.b, c.a}; }
inline Color from_sg(const sg_color& c) { return Color{c.r, c.g, c.b, c.a}; }
inline sg_range to_sg(Range r) { return sg_range{r.ptr, r.size}; }
inline Range from_sg(sg_range r) { return Range{r.ptr, r.size}; }

// The engine Backend of a sokol backend (GLES3 is WebGl2 in an Emscripten build; DUMMY, which the engine never builds,
// is Recording: no GPU either way), and the Metal platform.
Backend backend_from_sg(sg_backend b);
MetalTarget metal_target_from_sg(sg_backend b);

// ---- descs ---------------------------------------------------------------------------------------------------------
sg_buffer_desc to_sg(const BufferDesc& d);
sg_image_desc to_sg(const ImageDesc& d);
sg_view_desc to_sg(const ViewDesc& d);
sg_sampler_desc to_sg(const SamplerDesc& d);
sg_shader_function to_sg(const ShaderFunction& f);
sg_shader_desc to_sg(const ShaderDesc& d);
sg_pipeline_desc to_sg(const PipelineDesc& d);
sg_bindings to_sg(const Bindings& b);
sg_swapchain to_sg(const Swapchain& s);
sg_environment to_sg(const Environment& e);
// The sokol pass of a PassDesc.
sg_pass to_sg(const PassDesc& p);
// The generated shader headers return sokol descs: this is how they reach Device::make_shader. The strings and
// bytecode stay the header's (static data).
ShaderFunction from_sg(const sg_shader_function& s);
ShaderDesc from_sg(const sg_shader_desc& d);
// A pipeline desc built for sokol, for a call site converted one step at a time.
PipelineDesc from_sg(const sg_pipeline_desc& d);
VertexLayout from_sg(const sg_vertex_layout_state& l);
Swapchain from_sg(const sg_swapchain& s);
EnvironmentDefaults from_sg(const sg_environment_defaults& d);
PixelFormatCaps from_sg(const sg_pixelformat_info& i);
Features from_sg(const sg_features& f);
Limits from_sg(const sg_limits& l);
ResourceTotals from_sg(const sg_total_resource_stats& t);

// A pass into the window `sc`: PassDesc::for_swapchain with the defaults of the open sokol context (EnvironmentDefaults{}
// when there is none). `sc` must outlive the pass.
PassDesc swapchain_pass(const Swapchain& sc);

// ---- generated shaders -----------------------------------------------------------------------------------------------
// The desc function of a generated shader header (shaders/*.glsl.h), e.g. mesh_mesh_shader_desc.
using GeneratedShader = const sg_shader_desc* (*)(sg_backend backend);
// The interface's desc of a generated shader for the backend of the open sokol context. The strings and bytecode stay
// the header's (static data): the result is valid for the whole run.
ShaderDesc generated_shader_desc(GeneratedShader fn);

// ---- a pass with no device ----------------------------------------------------------------------------------------
// Begins / ends a pass directly on the open sokol context. Only for a pass that can run while no Device exists
// (Renderer::present_clear runs before the renderer is made); everything else begins its passes on a CommandList.
void begin_context_pass(const PassDesc& pass);
void begin_context_compute_pass(const char* label);
void end_context_pass();

}  // namespace fa::gpu
