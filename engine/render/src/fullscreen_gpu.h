// Private to fa_render (M77-P4c): what the full-screen post-process classes (SceneFx, Ssr, Ssao, TaaFx, the custom post chain
// and the upscalers) share when they record on the GPU interface (gpu/device.h): the list a pass records on and the pipeline of
// one full-screen triangle. docs/design/ARCHITECTURE_RENDERING_GPU.md says how a converted pass looks.
#pragma once

#include "gpu/device.h"
#include "frame_graph.h"
#include "render_internal.h"

namespace fa::render {

// The list a pass of the frame graph records on: the frame's (PassContext::commands()), or the Gpu's own when the graph runs
// without one (the CPU-only graph tests never draw, so this only keeps a caller outside a graph working).
inline gpu::CommandList& pass_list(const PassContext& c, Gpu& gpu) {
    return c.commands() ? *c.commands() : gpu.commands();
}

// The pipeline of a full-screen-triangle program: one `pos` (float2) attribute at location `posAttr`, no depth test or write, CCW
// winding, one colour target of `format` (no depth: `format.depth` is what the pass has), `colorMask` on it.
inline gpu::Pipeline make_triangle_pipeline(gpu::Device& device, gpu::Shader shader, const TargetFormat& format,
                                            const char* label, int posAttr = 0,
                                            gpu::ColorMask colorMask = gpu::ColorMask::Default) {
    gpu::PipelineDesc d{};
    d.shader = shader;
    d.layout.attrs[posAttr].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    const gpu::TargetFormat t = format;
    d.depth.pixelFormat = t.depth;
    d.colors[0].pixelFormat = t.color;
    d.colors[0].writeMask = colorMask;
    if (t.color1 != gpu::PixelFormat::None) {
        d.colorCount = 2;
        d.colors[1].pixelFormat = t.color1;
        d.colors[1].writeMask = colorMask;
    }
    d.sampleCount = t.samples;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = label;
    return device.make_pipeline(d);
}

}  // namespace fa::render
