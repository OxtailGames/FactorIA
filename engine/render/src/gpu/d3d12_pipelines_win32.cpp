// The D3D12 backend's shaders and pipelines: DXBC of shader model 5.1 (compiled here from HLSL when a stage is given as
// source), one root signature per binding layout (cached: every shader with the same registers shares it), graphics and
// compute PSOs with an in-memory cache over an on-disk pipeline library (docs/design/ARCHITECTURE_RENDERING_GPU.md,
// "D3D12 backend").
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <climits>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <iterator>
#include <memory>
#include <new>
#include <set>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/log.h"
#include "gpu/d3d12_device.h"

// After the D3D12 headers: the D3DCOMPILE_* flag values only (D3DCompile itself is loaded from d3dcompiler_47.dll).
#include <d3dcompiler.h>

namespace fa::gpu::d3d12 {

namespace {

std::string label_of(const char* label) { return label && *label ? std::string(label) : std::string("(no label)"); }

const char* stage_name(ShaderStage s) {
    switch (s) {
        case ShaderStage::Vertex: return "vertex";
        case ShaderStage::Fragment: return "fragment";
        case ShaderStage::Compute: return "compute";
        default: return "no";
    }
}

// The table a slot of `stage` goes in: 0 for the vertex (or compute) stage, 1 for the fragment stage; -1 when a shader
// of this kind has no such stage.
int stage_index(ShaderStage stage, bool compute) {
    if (compute) return stage == ShaderStage::Compute ? 0 : -1;
    if (stage == ShaderStage::Vertex) return 0;
    if (stage == ShaderStage::Fragment) return 1;
    return -1;
}

// D3DCompile, loaded at runtime like sokol does (no import library).
using PD3DCompile = HRESULT(WINAPI*)(LPCVOID, SIZE_T, LPCSTR, const D3D_SHADER_MACRO*, ID3DInclude*, LPCSTR, LPCSTR,
                                     UINT, UINT, ID3DBlob**, ID3DBlob**);
// The engine's flags (shader_cache.cpp uses the same ones, so a stage it cached and one compiled here are the same),
// plus D3DCOMPILE_ENABLE_UNBOUNDED_DESCRIPTOR_TABLES: shader model 5.1 refuses an unsized array such as the bindless
// table (`Texture2D table[] : register(t0, space1)`, error X3596) without it.
constexpr UINT kCompileFlags = D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR | D3DCOMPILE_OPTIMIZATION_LEVEL3 |
                               D3DCOMPILE_PREFER_FLOW_CONTROL | D3DCOMPILE_ENABLE_UNBOUNDED_DESCRIPTOR_TABLES;

bool compile_hlsl(const ShaderFunction& fn, const char* target, const char* stage, std::vector<std::uint8_t>& out,
                  std::string& error) {
    static HMODULE dll = LoadLibraryW(L"d3dcompiler_47.dll");
    static PD3DCompile compile =
        dll ? reinterpret_cast<PD3DCompile>(reinterpret_cast<void*>(GetProcAddress(dll, "D3DCompile"))) : nullptr;
    if (!compile) {
        error = std::string("the ") + stage +
                " stage is HLSL source and d3dcompiler_47.dll, which compiles it, could not be loaded (hint: give the "
                "stage as DXBC bytecode, or put the Windows SDK's d3dcompiler_47.dll next to the program)";
        return false;
    }
    const char* entry = fn.entry && *fn.entry ? fn.entry : "main";
    Com<ID3DBlob> code, messages;
    const HRESULT hr = compile(fn.source, std::strlen(fn.source), fn.d3d11Filepath, nullptr, nullptr, entry, target,
                               kCompileFlags, 0, code.put(), messages.put());
    if (FAILED(hr) || !code || code->GetBufferSize() == 0) {
        std::string text;
        if (messages && messages->GetBufferSize() > 0)
            text.assign(static_cast<const char*>(messages->GetBufferPointer()), messages->GetBufferSize());
        while (!text.empty() && (text.back() == '\0' || text.back() == '\n' || text.back() == '\r')) text.pop_back();
        error = std::string("the ") + stage + " stage does not compile as " + target + " (entry '" + entry +
                "'): " + (text.empty() ? hr_text(hr) : text) +
                " (hint: D3D12 compiles HLSL to shader model 5.1; the compiler's lines are the source's)";
        return false;
    }
    const auto* p = static_cast<const std::uint8_t*>(code->GetBufferPointer());
    out.assign(p, p + code->GetBufferSize());
    return true;
}

// One stage's DXBC: the bytecode given, or the source compiled for `target`.
// `shaderModel` is the highest shader model the device takes (RtCaps::shaderModel): DXIL (shader model 6, from DXC)
// is accepted for a compute stage on a device that takes shader model 6.0 or more, DXBC (shader model 5.x) everywhere.
bool stage_code(const ShaderFunction& fn, const char* target, const char* stage, int shaderModel,
                std::vector<std::uint8_t>& out, std::string& error) {
    if (fn.bytecode.ptr) {
        if (fn.bytecode.size < 4 || std::memcmp(fn.bytecode.ptr, "DXBC", 4) != 0) {
            error = std::string("the ") + stage +
                    " stage's bytecode is neither DXBC nor DXIL (hint: D3D12 takes shader model 5.x DXBC, sokol-shdc's "
                    "hlsl5 output, HLSL source it compiles itself, or a compute shader's DXIL from DXC)";
            return false;
        }
        if (is_dxil_container(fn.bytecode.ptr, fn.bytecode.size)) {
            const bool compute = std::strcmp(stage, "compute") == 0;
            if (!compute) {
                error = std::string("the ") + stage +
                        " stage's bytecode is DXIL (shader model 6), which the engine takes for compute shaders only "
                        "(hint: give a render shader shader model 5.x DXBC, sokol-shdc's hlsl5 output, or HLSL "
                        "source)";
                return false;
            }
            if (shaderModel < 0x60) {
                error = "the compute stage's bytecode is DXIL (shader model 6) and this device takes shader model " +
                        shader_model_name(shaderModel) +
                        " at most (hint: update the GPU driver, or give the shader as shader model 5.x DXBC)";
                return false;
            }
        }
        const auto* p = static_cast<const std::uint8_t*>(fn.bytecode.ptr);
        out.assign(p, p + fn.bytecode.size);
        return true;
    }
    if (fn.source) return compile_hlsl(fn, target, stage, out, error);
    error = std::string("the ") + stage +
            " stage has neither source nor bytecode (hint: a render shader sets vertexFunc and fragmentFunc, a "
            "compute shader computeFunc)";
    return false;
}

// Where a view slot sits: an SRV ('t') or a UAV ('u') register and its space.
struct Reg {
    char cls = 't';
    std::uint32_t reg = 0;
    std::uint32_t space = 0;
};

Reg view_register(const ShaderView& v) {
    switch (v.type()) {
        case ViewType::Texture: return {'t', v.texture.binding.hlslRegister, v.texture.binding.hlslSpace};
        case ViewType::StorageBuffer:
            if (v.storageBuffer.readonly)
                return {'t', v.storageBuffer.binding.hlslRegister, v.storageBuffer.binding.hlslSpace};
            return {'u', v.storageBuffer.hlslRegisterU, v.storageBuffer.binding.hlslSpace};
        default: return {'u', v.storageImage.binding.hlslRegister, v.storageImage.binding.hlslSpace};
    }
}

// The text a cache key is made of: values separated by commas.
struct KeyText {
    std::string s;
    void add(std::uint64_t v) {
        s += std::to_string(v);
        s += ',';
    }
    void add(const char* t) {
        s += t ? t : "";
        s += ',';
    }
    void add_float(float f) {
        std::uint32_t bits = 0;
        std::memcpy(&bits, &f, sizeof bits);
        add(bits);
    }
};

struct VertexFormatInfo {
    DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
    std::uint32_t bytes = 0;
};

VertexFormatInfo vertex_format(VertexFormat f) {
    switch (f) {
        case VertexFormat::Float: return {DXGI_FORMAT_R32_FLOAT, 4};
        case VertexFormat::Float2: return {DXGI_FORMAT_R32G32_FLOAT, 8};
        case VertexFormat::Float3: return {DXGI_FORMAT_R32G32B32_FLOAT, 12};
        case VertexFormat::Float4: return {DXGI_FORMAT_R32G32B32A32_FLOAT, 16};
        case VertexFormat::Int: return {DXGI_FORMAT_R32_SINT, 4};
        case VertexFormat::Int2: return {DXGI_FORMAT_R32G32_SINT, 8};
        case VertexFormat::Int3: return {DXGI_FORMAT_R32G32B32_SINT, 12};
        case VertexFormat::Int4: return {DXGI_FORMAT_R32G32B32A32_SINT, 16};
        case VertexFormat::Uint: return {DXGI_FORMAT_R32_UINT, 4};
        case VertexFormat::Uint2: return {DXGI_FORMAT_R32G32_UINT, 8};
        case VertexFormat::Uint3: return {DXGI_FORMAT_R32G32B32_UINT, 12};
        case VertexFormat::Uint4: return {DXGI_FORMAT_R32G32B32A32_UINT, 16};
        case VertexFormat::Byte4: return {DXGI_FORMAT_R8G8B8A8_SINT, 4};
        case VertexFormat::Byte4N: return {DXGI_FORMAT_R8G8B8A8_SNORM, 4};
        case VertexFormat::Ubyte4: return {DXGI_FORMAT_R8G8B8A8_UINT, 4};
        case VertexFormat::Ubyte4N: return {DXGI_FORMAT_R8G8B8A8_UNORM, 4};
        case VertexFormat::Short2: return {DXGI_FORMAT_R16G16_SINT, 4};
        case VertexFormat::Short2N: return {DXGI_FORMAT_R16G16_SNORM, 4};
        case VertexFormat::Ushort2: return {DXGI_FORMAT_R16G16_UINT, 4};
        case VertexFormat::Ushort2N: return {DXGI_FORMAT_R16G16_UNORM, 4};
        case VertexFormat::Short4: return {DXGI_FORMAT_R16G16B16A16_SINT, 8};
        case VertexFormat::Short4N: return {DXGI_FORMAT_R16G16B16A16_SNORM, 8};
        case VertexFormat::Ushort4: return {DXGI_FORMAT_R16G16B16A16_UINT, 8};
        case VertexFormat::Ushort4N: return {DXGI_FORMAT_R16G16B16A16_UNORM, 8};
        case VertexFormat::Uint10N2: return {DXGI_FORMAT_R10G10B10A2_UNORM, 4};
        case VertexFormat::Half2: return {DXGI_FORMAT_R16G16_FLOAT, 4};
        case VertexFormat::Half4: return {DXGI_FORMAT_R16G16B16A16_FLOAT, 8};
        default: return {};  // Invalid, Int10N2 (D3D has no signed 10:10:10:2 vertex format)
    }
}

// A blend factor; the alpha factors take the *_ALPHA form of a *_COLOR factor (D3D12 refuses colour factors there).
// BlendAlpha is the blend constant's alpha: D3D12 has one blend factor for the four channels (sokol's D3D11 does the
// same).
D3D12_BLEND blend_factor(BlendFactor f, BlendFactor fallback, bool alpha) {
    if (f == BlendFactor::Default) f = fallback;
    switch (f) {
        case BlendFactor::Zero: return D3D12_BLEND_ZERO;
        case BlendFactor::One: return D3D12_BLEND_ONE;
        case BlendFactor::SrcColor: return alpha ? D3D12_BLEND_SRC_ALPHA : D3D12_BLEND_SRC_COLOR;
        case BlendFactor::OneMinusSrcColor: return alpha ? D3D12_BLEND_INV_SRC_ALPHA : D3D12_BLEND_INV_SRC_COLOR;
        case BlendFactor::SrcAlpha: return D3D12_BLEND_SRC_ALPHA;
        case BlendFactor::OneMinusSrcAlpha: return D3D12_BLEND_INV_SRC_ALPHA;
        case BlendFactor::DstColor: return alpha ? D3D12_BLEND_DEST_ALPHA : D3D12_BLEND_DEST_COLOR;
        case BlendFactor::OneMinusDstColor: return alpha ? D3D12_BLEND_INV_DEST_ALPHA : D3D12_BLEND_INV_DEST_COLOR;
        case BlendFactor::DstAlpha: return D3D12_BLEND_DEST_ALPHA;
        case BlendFactor::OneMinusDstAlpha: return D3D12_BLEND_INV_DEST_ALPHA;
        case BlendFactor::SrcAlphaSaturated: return D3D12_BLEND_SRC_ALPHA_SAT;
        case BlendFactor::BlendColor:
        case BlendFactor::BlendAlpha: return D3D12_BLEND_BLEND_FACTOR;
        case BlendFactor::OneMinusBlendColor:
        case BlendFactor::OneMinusBlendAlpha: return D3D12_BLEND_INV_BLEND_FACTOR;
        case BlendFactor::Src1Color: return alpha ? D3D12_BLEND_SRC1_ALPHA : D3D12_BLEND_SRC1_COLOR;
        case BlendFactor::OneMinusSrc1Color: return alpha ? D3D12_BLEND_INV_SRC1_ALPHA : D3D12_BLEND_INV_SRC1_COLOR;
        case BlendFactor::Src1Alpha: return D3D12_BLEND_SRC1_ALPHA;
        case BlendFactor::OneMinusSrc1Alpha: return D3D12_BLEND_INV_SRC1_ALPHA;
        default: return D3D12_BLEND_ONE;
    }
}

// BlendOp's values are D3D12_BLEND_OP's (Add = 1 .. Max = 5).
D3D12_BLEND_OP blend_op(BlendOp op) {
    return op == BlendOp::Default ? D3D12_BLEND_OP_ADD : D3D12_BLEND_OP(std::uint32_t(op));
}

// CompareFunc's values are D3D12_COMPARISON_FUNC's (Never = 1 .. Always = 8), StencilOp's D3D12_STENCIL_OP's.
D3D12_COMPARISON_FUNC compare_func(CompareFunc f) {
    return D3D12_COMPARISON_FUNC(std::uint32_t(f == CompareFunc::Default ? CompareFunc::Always : f));
}
D3D12_STENCIL_OP stencil_op(StencilOp op) {
    return D3D12_STENCIL_OP(std::uint32_t(op == StencilOp::Default ? StencilOp::Keep : op));
}

UINT8 color_mask(ColorMask m) {
    if (m == ColorMask::Default) return D3D12_COLOR_WRITE_ENABLE_ALL;
    if (m == ColorMask::None) return 0;
    return UINT8(std::uint32_t(m) & 0xFu);  // R = 1, G = 2, B = 4, A = 8, as D3D12_COLOR_WRITE_ENABLE
}

using CapsTable = std::array<PixelFormatCaps, std::size_t(PixelFormat::Count)>;

struct GraphicsBuild {
    D3D12_GRAPHICS_PIPELINE_STATE_DESC d{};
    std::vector<D3D12_INPUT_ELEMENT_DESC> elements;
    KeyText key;
};

// Fills the graphics PSO desc (but its root signature and code) and the draw state of `st` from a render pipeline's
// desc; the error when the desc cannot be one.
std::string graphics_desc(const PipelineDesc& desc, const ShaderInfo& sh, const EnvironmentDefaults& env,
                          const CapsTable& caps, PipelineState& st, GraphicsBuild& out) {
    auto cap = [&](PixelFormat f) {
        const auto i = std::size_t(f);
        return i < caps.size() ? caps[i] : PixelFormatCaps{};
    };
    D3D12_GRAPHICS_PIPELINE_STATE_DESC& d = out.d;

    // The vertex input, by sokol's per-buffer rule (resolve_vertex_offsets): in each buffer whose attributes all have
    // offset 0 they are packed in order, a stride of 0 is the packed size, the attributes end at the first Invalid
    // format. A layout that mixes a packed mesh buffer with an instance buffer of given offsets means the same here as
    // on every other backend.
    VertexLayout layout = desc.layout;
    resolve_vertex_offsets(layout);
    std::uint32_t packed[kMaxVertexBuffers]{};
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        const VertexAttr& a = layout.attrs[i];
        if (a.format == VertexFormat::Invalid) break;
        const std::string what = "vertex attribute " + std::to_string(i);
        if (a.bufferIndex < 0 || a.bufferIndex >= kMaxVertexBuffers)
            return what + " reads vertex buffer slot " + std::to_string(a.bufferIndex) + " (hint: slots are 0 to " +
                   std::to_string(kMaxVertexBuffers - 1) + ")";
        const VertexFormatInfo vf = vertex_format(a.format);
        if (vf.format == DXGI_FORMAT_UNKNOWN)
            return what + " has format Int10N2, which D3D has no vertex format for (hint: Uint10N2; "
                          "Features::vertexFormatInt10N2 says where Int10N2 exists)";
        if (sh.semName[i].empty())
            return what + " has no HLSL semantic in shader '" + sh.label + "' (hint: set ShaderDesc::attrs[" +
                   std::to_string(i) + "].hlslSemName and hlslSemIndex, which sokol-shdc writes)";
        if (a.offset < 0) return what + " has the negative offset " + std::to_string(a.offset);
        const auto b = std::size_t(a.bufferIndex);
        const VertexBufferLayout& bl = layout.buffers[b];
        const bool instance = bl.stepFunc == VertexStep::PerInstance;
        D3D12_INPUT_ELEMENT_DESC e{};
        e.SemanticName = sh.semName[i].c_str();
        e.SemanticIndex = sh.semIndex[i];
        e.Format = vf.format;
        e.InputSlot = UINT(b);
        e.AlignedByteOffset = UINT(a.offset);
        e.InputSlotClass =
            instance ? D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA : D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA;
        e.InstanceDataStepRate = instance ? UINT(bl.stepRate > 0 ? bl.stepRate : 1) : 0u;
        packed[b] += vf.bytes;
        st.buffersUsed |= 1u << b;
        out.elements.push_back(e);
    }
    for (std::size_t b = 0; b < std::size_t(kMaxVertexBuffers); ++b) {
        if (!(st.buffersUsed & (1u << b))) continue;
        const int stride = layout.buffers[b].stride;
        if (stride < 0 || stride > int(D3D12_REQ_MULTI_ELEMENT_STRUCTURE_SIZE_IN_BYTES))
            return "vertex buffer slot " + std::to_string(b) + " has stride " + std::to_string(stride) +
                   " (hint: 0 = the packed size of its attributes, at most " +
                   std::to_string(D3D12_REQ_MULTI_ELEMENT_STRUCTURE_SIZE_IN_BYTES) + " bytes)";
        st.strides[b] = stride > 0 ? std::uint32_t(stride) : packed[b];
    }

    // The colour targets
    int colorCount = desc.colorCount;
    if (colorCount == 0) colorCount = desc.colors[0].pixelFormat == PixelFormat::None ? 0 : 1;
    if (colorCount < 0 || colorCount > kMaxColorAttachments)
        return "colorCount " + std::to_string(desc.colorCount) + " is outside 0.." +
               std::to_string(kMaxColorAttachments);
    const int samples = desc.sampleCount > 0 ? desc.sampleCount : env.sampleCount;
    if (samples != 1 && samples != 2 && samples != 4 && samples != 8)
        return "sampleCount " + std::to_string(samples) + " is not 1, 2, 4 or 8";
    for (D3D12_RENDER_TARGET_BLEND_DESC& bt : d.BlendState.RenderTarget) {
        bt.SrcBlend = bt.SrcBlendAlpha = D3D12_BLEND_ONE;
        bt.DestBlend = bt.DestBlendAlpha = D3D12_BLEND_ZERO;
        bt.BlendOp = bt.BlendOpAlpha = D3D12_BLEND_OP_ADD;
        bt.LogicOp = D3D12_LOGIC_OP_NOOP;
        bt.RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
    }
    PixelFormat colorFormats[kMaxColorAttachments]{};
    for (int i = 0; i < colorCount; ++i) {
        const ColorTargetState& c = desc.colors[i];
        const PixelFormat f = c.pixelFormat == PixelFormat::Default ? env.colorFormat : c.pixelFormat;
        const std::string what = "colour target " + std::to_string(i) + " (" + pixel_format_name(f) + ")";
        const PixelFormatCaps fc = cap(f);
        if (f == PixelFormat::None || !fc.render || fc.depth)
            return what +
                   " is not a colour format this GPU renders to (hint: pixel_format_caps(format).render says which "
                   "formats are; colorCount counts the targets)";
        if (c.blend.enabled && !fc.blend)
            return what + " cannot blend on this GPU (hint: turn its blending off, or pick a format whose "
                          "pixel_format_caps(format).blend is true)";
        if (samples > 1 && !fc.msaa)
            return what + " cannot be multisampled on this GPU (hint: pixel_format_caps(format).msaa says which "
                          "formats can; sampleCount 1)";
        colorFormats[i] = f;
        d.RTVFormats[i] = format_info(f).rtv;
        D3D12_RENDER_TARGET_BLEND_DESC& bt = d.BlendState.RenderTarget[i];
        bt.BlendEnable = c.blend.enabled ? TRUE : FALSE;
        bt.SrcBlend = blend_factor(c.blend.srcFactorRgb, BlendFactor::One, false);
        bt.DestBlend = blend_factor(c.blend.dstFactorRgb, BlendFactor::Zero, false);
        bt.BlendOp = blend_op(c.blend.opRgb);
        bt.SrcBlendAlpha = blend_factor(c.blend.srcFactorAlpha, BlendFactor::One, true);
        bt.DestBlendAlpha = blend_factor(c.blend.dstFactorAlpha, BlendFactor::Zero, true);
        bt.BlendOpAlpha = blend_op(c.blend.opAlpha);
        bt.RenderTargetWriteMask = color_mask(c.writeMask);
    }
    d.BlendState.AlphaToCoverageEnable = desc.alphaToCoverageEnabled ? TRUE : FALSE;
    d.BlendState.IndependentBlendEnable = TRUE;

    // Depth and stencil
    const PixelFormat depth = desc.depth.pixelFormat == PixelFormat::Default ? env.depthFormat : desc.depth.pixelFormat;
    const bool hasDepth = depth != PixelFormat::None;
    if (hasDepth) {
        const PixelFormatCaps fc = cap(depth);
        if (!fc.depth || !fc.render)
            return std::string("depth format ") + pixel_format_name(depth) +
                   " is not a depth format this GPU renders to (hint: Depth or DepthStencil; None for a pipeline "
                   "without depth)";
        if (samples > 1 && !fc.msaa)
            return std::string("depth format ") + pixel_format_name(depth) + " cannot be multisampled on this GPU";
        d.DSVFormat = format_info(depth).rtv;
    }
    const bool hasStencil = hasDepth && format_info(depth).planes > 1;
    const CompareFunc depthCompare =
        desc.depth.compare == CompareFunc::Default ? CompareFunc::Always : desc.depth.compare;
    D3D12_DEPTH_STENCIL_DESC& ds = d.DepthStencilState;
    ds.DepthEnable = hasDepth && (depthCompare != CompareFunc::Always || desc.depth.writeEnabled) ? TRUE : FALSE;
    ds.DepthWriteMask = desc.depth.writeEnabled ? D3D12_DEPTH_WRITE_MASK_ALL : D3D12_DEPTH_WRITE_MASK_ZERO;
    ds.DepthFunc = compare_func(depthCompare);
    ds.StencilEnable = hasStencil && desc.stencil.enabled ? TRUE : FALSE;
    ds.StencilReadMask = desc.stencil.readMask;
    ds.StencilWriteMask = desc.stencil.writeMask;
    auto face = [](const StencilFaceState& f, D3D12_DEPTH_STENCILOP_DESC& o) {
        o.StencilFailOp = stencil_op(f.failOp);
        o.StencilDepthFailOp = stencil_op(f.depthFailOp);
        o.StencilPassOp = stencil_op(f.passOp);
        o.StencilFunc = compare_func(f.compare);
    };
    face(desc.stencil.front, ds.FrontFace);
    face(desc.stencil.back, ds.BackFace);

    // Rasterizer
    D3D12_RASTERIZER_DESC& r = d.RasterizerState;
    r.FillMode = D3D12_FILL_MODE_SOLID;
    r.CullMode = desc.cullMode == CullMode::Front  ? D3D12_CULL_MODE_FRONT
                 : desc.cullMode == CullMode::Back ? D3D12_CULL_MODE_BACK
                                                   : D3D12_CULL_MODE_NONE;
    r.FrontCounterClockwise = desc.faceWinding == FaceWinding::Ccw ? TRUE : FALSE;
    // Clamped before the cast: a float past INT's range (or NaN) does not convert.
    const float bias = std::isfinite(desc.depth.bias) ? std::clamp(desc.depth.bias, -2.0e9f, 2.0e9f) : 0.0f;
    r.DepthBias = INT(bias);
    r.DepthBiasClamp = std::isfinite(desc.depth.biasClamp) ? desc.depth.biasClamp : 0.0f;
    r.SlopeScaledDepthBias = std::isfinite(desc.depth.biasSlopeScale) ? desc.depth.biasSlopeScale : 0.0f;
    r.DepthClipEnable = TRUE;
    r.MultisampleEnable = samples > 1 ? TRUE : FALSE;
    r.AntialiasedLineEnable = FALSE;
    r.ForcedSampleCount = 0;
    r.ConservativeRaster = D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF;

    // Primitives
    bool strip = false;
    switch (desc.primitiveType) {
        case PrimitiveType::Points:
            d.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_POINT;
            st.topology = D3D_PRIMITIVE_TOPOLOGY_POINTLIST;
            break;
        case PrimitiveType::Lines:
            d.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE;
            st.topology = D3D_PRIMITIVE_TOPOLOGY_LINELIST;
            break;
        case PrimitiveType::LineStrip:
            d.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE;
            st.topology = D3D_PRIMITIVE_TOPOLOGY_LINESTRIP;
            strip = true;
            break;
        case PrimitiveType::TriangleStrip:
            d.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
            st.topology = D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
            strip = true;
            break;
        default:
            d.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
            st.topology = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
            break;
    }
    st.indexType = desc.indexType == IndexType::Default ? IndexType::None : desc.indexType;
    d.IBStripCutValue = !strip                              ? D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_DISABLED
                        : st.indexType == IndexType::Uint16 ? D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_0xFFFF
                        : st.indexType == IndexType::Uint32 ? D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_0xFFFFFFFF
                                                            : D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_DISABLED;
    d.InputLayout.pInputElementDescs = out.elements.empty() ? nullptr : out.elements.data();
    d.InputLayout.NumElements = UINT(out.elements.size());
    d.NumRenderTargets = UINT(colorCount);
    d.SampleDesc.Count = UINT(samples);
    d.SampleDesc.Quality = 0;
    d.SampleMask = UINT_MAX;

    st.blendColor[0] = desc.blendColor.r;
    st.blendColor[1] = desc.blendColor.g;
    st.blendColor[2] = desc.blendColor.b;
    st.blendColor[3] = desc.blendColor.a;
    st.stencilRef = desc.stencil.ref;
    st.colorCount = colorCount;
    st.format.color = colorCount > 0 ? colorFormats[0] : PixelFormat::None;
    st.format.color1 = colorCount > 1 ? colorFormats[1] : PixelFormat::None;
    st.format.depth = hasDepth ? depth : PixelFormat::None;
    st.format.samples = samples;

    // The PSO's key: every value of the desc but the pointers (the code and the root signature are keyed by the
    // caller).
    KeyText& k = out.key;
    for (const D3D12_INPUT_ELEMENT_DESC& e : out.elements) {
        k.add(e.SemanticName);
        for (std::uint64_t v : {std::uint64_t(e.SemanticIndex), std::uint64_t(e.Format), std::uint64_t(e.InputSlot),
                                std::uint64_t(e.AlignedByteOffset), std::uint64_t(e.InputSlotClass),
                                std::uint64_t(e.InstanceDataStepRate)})
            k.add(v);
    }
    k.add("|");
    k.add(std::uint64_t(d.BlendState.AlphaToCoverageEnable));
    for (const D3D12_RENDER_TARGET_BLEND_DESC& bt : d.BlendState.RenderTarget)
        for (std::uint64_t v :
             {std::uint64_t(bt.BlendEnable), std::uint64_t(bt.SrcBlend), std::uint64_t(bt.DestBlend),
              std::uint64_t(bt.BlendOp), std::uint64_t(bt.SrcBlendAlpha), std::uint64_t(bt.DestBlendAlpha),
              std::uint64_t(bt.BlendOpAlpha), std::uint64_t(bt.RenderTargetWriteMask)})
            k.add(v);
    for (std::uint64_t v : {std::uint64_t(ds.DepthEnable),
                            std::uint64_t(ds.DepthWriteMask),
                            std::uint64_t(ds.DepthFunc),
                            std::uint64_t(ds.StencilEnable),
                            std::uint64_t(ds.StencilReadMask),
                            std::uint64_t(ds.StencilWriteMask),
                            std::uint64_t(ds.FrontFace.StencilFailOp),
                            std::uint64_t(ds.FrontFace.StencilDepthFailOp),
                            std::uint64_t(ds.FrontFace.StencilPassOp),
                            std::uint64_t(ds.FrontFace.StencilFunc),
                            std::uint64_t(ds.BackFace.StencilFailOp),
                            std::uint64_t(ds.BackFace.StencilDepthFailOp),
                            std::uint64_t(ds.BackFace.StencilPassOp),
                            std::uint64_t(ds.BackFace.StencilFunc),
                            std::uint64_t(r.CullMode),
                            std::uint64_t(r.FrontCounterClockwise),
                            std::uint64_t(std::int64_t(r.DepthBias) + INT_MAX),
                            std::uint64_t(r.MultisampleEnable),
                            std::uint64_t(d.PrimitiveTopologyType),
                            std::uint64_t(d.IBStripCutValue),
                            std::uint64_t(d.NumRenderTargets),
                            std::uint64_t(d.DSVFormat),
                            std::uint64_t(d.SampleDesc.Count)})
        k.add(v);
    k.add_float(r.DepthBiasClamp);
    k.add_float(r.SlopeScaledDepthBias);
    for (DXGI_FORMAT f : d.RTVFormats) k.add(std::uint64_t(f));
    return {};
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Shaders
// ---------------------------------------------------------------------------------------------------------------------

Shader D3d12Device::make_shader(const ShaderDesc& desc) {
    const std::string label = label_of(desc.label);
    auto info = std::make_shared<ShaderInfo>();
    info->compute = desc.compute();
    info->label = label;
    std::string error;
    auto fail = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    auto code = [&](const ShaderFunction& fn, const char* target, const char* stage, std::vector<std::uint8_t>& out) {
        std::string e;
        if (error.empty() && !stage_code(fn, target, stage, rtCaps_.shaderModel, out, e)) fail(e);
    };
    // What a ray-query kernel's compute stage is, when it is not DXIL: nothing at all, HLSL text, or bytecode of another
    // compiler (DXBC, SPIR-V): the refusal says which, and what to give instead.
    const bool rqNoStage = !desc.computeFunc.bytecode.ptr && !desc.computeFunc.source;
    const bool rqNotDxil =
        desc.usesRayQuery && !(desc.computeFunc.bytecode.ptr &&
                               is_dxil_container(desc.computeFunc.bytecode.ptr, desc.computeFunc.bytecode.size));
    const bool hasRender = desc.vertexFunc.source || desc.vertexFunc.bytecode.ptr || desc.fragmentFunc.source ||
                           desc.fragmentFunc.bytecode.ptr;
    if (info->compute && hasRender) {
        fail("it has a compute stage and a vertex or fragment stage (hint: a compute shader sets computeFunc only, a "
             "render shader vertexFunc and fragmentFunc)");
    } else if (info->compute) {
        // A ray-query kernel is DXIL (cs_6_5): HLSL text would go through D3DCompile's cs_5_1, which has no RayQuery,
        // so it is refused below with what to give instead rather than with that compiler's error.
        if (!rqNotDxil) code(desc.computeFunc, "cs_5_1", "compute", info->cs);
    } else {
        code(desc.vertexFunc, "vs_5_1", "vertex", info->vs);
        code(desc.fragmentFunc, "ps_5_1", "fragment", info->fs);
    }

    // The slots: each in a stage the shader has, each on a register of its own.
    const char* kind = info->compute ? "a compute shader" : "a render shader";
    std::set<std::string> taken;
    auto claim = [&](const std::string& what, int stage, char cls, std::uint32_t reg, std::uint32_t space) {
        const std::string name = std::string(1, cls) + std::to_string(reg) + ", space" + std::to_string(space);
        if (!taken.insert(std::to_string(stage) + name).second)
            fail(what + " is on register " + name +
                 ", which another slot of the same stage is on already (hint: every uniform block, view and sampler of "
                 "a stage needs a register of its own)");
        if (cls == 't' && space == 1 && bindlessDescriptors_ > 0)
            fail(what + " is on register " + name +
                 ": space1's t registers are the bindless table's (every root signature sees it as an unbounded SRV "
                 "range at t0, space1) (hint: use space0, or make the device with D3d12Options::bindlessDescriptors "
                 "0)");
    };
    auto wrong_stage = [&](const std::string& what, ShaderStage s) {
        fail(what + " belongs to the " + stage_name(s) + " stage, which " + kind +
             " does not have (hint: a compute shader's slots are ShaderStage::Compute, a render shader's Vertex or "
             "Fragment)");
    };
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        const ShaderUniformBlock& b = desc.uniformBlocks[i];
        if (b.stage == ShaderStage::None) continue;
        const std::string what = "uniform block " + std::to_string(i);
        const int s = stage_index(b.stage, info->compute);
        if (s < 0) {
            wrong_stage(what, b.stage);
            continue;
        }
        if (b.size == 0 || b.size > 65536) {
            fail(what + " has " + std::to_string(b.size) +
                 " bytes (hint: a uniform block has 1 to 65536 bytes, D3D12's constant buffer limit)");
            continue;
        }
        info->uniformSize[i] = b.size;
        claim(what, s, 'b', b.binding.hlslRegister, b.binding.hlslSpace);
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const ShaderView& v = desc.views[i];
        const ViewType type = v.type();
        if (type == ViewType::Invalid) continue;
        const std::string what = "view " + std::to_string(i);
        const int s = stage_index(v.stage(), info->compute);
        if (s < 0) {
            wrong_stage(what, v.stage());
            continue;
        }
        const Reg r = view_register(v);
        info->viewType[i] = type;
        info->viewWritable[i] = r.cls == 'u';
        claim(what, s, r.cls, r.reg, r.space);
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& sm = desc.samplers[i];
        if (sm.stage == ShaderStage::None) continue;
        const std::string what = "sampler " + std::to_string(i);
        const int s = stage_index(sm.stage, info->compute);
        if (s < 0) {
            wrong_stage(what, sm.stage);
            continue;
        }
        claim(what, s, 's', sm.binding.hlslRegister, sm.binding.hlslSpace);
    }
    // Ray queries (M79): a compute kernel with usesRayQuery, its TLAS slots on t registers (root SRVs).
    const std::string noRt = rtWhy_.empty() ? std::string("this device has no ray query") : rtWhy_;
    if (desc.usesRayQuery) {
        if (!info->compute)
            fail("usesRayQuery on a render shader: ray queries run in compute shaders (hint: a kernel keeps "
                 "ShaderStage::Compute; there are no ray tracing pipelines)");
        else if (!features_.rayQuery)
            fail("usesRayQuery on a device without ray query (Features::rayQuery is false: " + noRt +
                 ") (hint: check Device::features().rayQuery before making a ray-query kernel)");
        else if (rqNotDxil) {
            const char* dxilHint = "(hint: give the DXC container as computeFunc.bytecode: the engine's kernels are "
                                   "engine/render/shaders/rt/*.hlsl, compiled by tools/shaders/compile_rt_shaders.sh)";
            if (rqNoStage)
                fail(std::string("usesRayQuery on a shader with no compute stage: computeFunc has neither bytecode nor "
                                 "source ") +
                     dxilHint);
            else if (!desc.computeFunc.bytecode.ptr)
                fail(std::string("usesRayQuery on a compute stage given as HLSL text: RayQuery needs DXIL (cs_6_5), "
                                 "and HLSL text is compiled for cs_5_1, which has no RayQuery ") +
                     dxilHint);
            else
                fail(std::string("usesRayQuery on a compute stage whose bytecode is not a DXIL container (no \"DXBC\" "
                                 "header with a DXIL part: DXBC from FXC and SPIR-V have no RayQuery either) ") +
                     dxilHint);
        }
    }
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        const ShaderAccelStructure& a = desc.accelStructures[i];
        if (a.stage == ShaderStage::None) continue;
        const std::string what = "accelStructures[" + std::to_string(i) + "]";
        if (a.stage != ShaderStage::Compute || !info->compute) {
            fail(what + " has a stage other than Compute, or the shader is not a compute shader: only a compute "
                        "shader traces rays (hint: ShaderStage::Compute on a shader with computeFunc)");
            continue;
        }
        if (!desc.usesRayQuery)
            fail(what + " is declared but usesRayQuery is false (hint: set it on a ray-query kernel)");
        if (!features_.accelerationStructure)
            fail(what + " on a device without acceleration structures (Features::accelerationStructure is false: " +
                 noRt + ")");
        info->accelDeclared[i] = true;
        // Stage 0 is the compute stage (stage_index(Compute, true) == 0): the same stage the kernel's own views claim
        // their registers in, so a TLAS on a t register a view uses is reported as the clash it is.
        claim(what, 0, 't', a.binding.hlslRegister, a.binding.hlslSpace);
    }
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        if (!desc.attrs[i].hlslSemName || !*desc.attrs[i].hlslSemName) continue;
        info->semName[i] = desc.attrs[i].hlslSemName;
        info->semIndex[i] = desc.attrs[i].hlslSemIndex;
    }

    std::shared_ptr<const RootLayout> layout;
    if (error.empty()) {
        Sha256 h;
        for (const std::vector<std::uint8_t>* stage : {&info->vs, &info->fs, &info->cs}) {
            const std::string size = std::to_string(stage->size()) + ":";
            h.update(size);
            if (!stage->empty()) h.update(stage->data(), stage->size());
        }
        info->codeKey = h.finish_hex();
        std::string e;
        layout = root_layout(desc, *info, e);
        if (!layout) fail(e);
    }
    if (!error.empty()) report("gpu d3d12: make_shader '" + label + "': " + error);

    ShaderRecord rec;
    if (error.empty()) {
        rec.info = std::move(info);
        rec.layout = std::move(layout);
    }
    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.info != nullptr;
    const std::uint32_t id = shaders_.add(std::move(rec));
    if (id == 0) {
        report("gpu d3d12: make_shader '" + label + "': the shader pool is full (" +
               std::to_string(shaders_.capacity()) +
               " shaders) (hint: destroy shaders you no longer use, or raise DeviceInit::shaderPoolSize)");
        return {};
    }
    count_make(stats_.shaders, ok);
    return Shader{id};
}

bool D3d12Device::bindless_table_accepted(std::string& why) {
    // The table exactly as root_layout adds it to every root signature, alone, with a render signature's flags.
    D3D12_DESCRIPTOR_RANGE range{};
    range.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
    range.NumDescriptors = UINT_MAX;  // unbounded
    range.BaseShaderRegister = 0;
    range.RegisterSpace = 1;
    range.OffsetInDescriptorsFromTableStart = 0;
    D3D12_ROOT_PARAMETER p{};
    p.ParameterType = D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
    p.DescriptorTable.NumDescriptorRanges = 1;
    p.DescriptorTable.pDescriptorRanges = &range;
    p.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
    D3D12_ROOT_SIGNATURE_DESC rd{};
    rd.NumParameters = 1;
    rd.pParameters = &p;
    rd.Flags = D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;
    Com<ID3DBlob> blob, messages;
    HRESULT hr = D3D12SerializeRootSignature(&rd, D3D_ROOT_SIGNATURE_VERSION_1, blob.put(), messages.put());
    if (FAILED(hr) || !blob) {
        why = "D3D12SerializeRootSignature failed with " + hr_text(hr);
        return false;
    }
    // A refusal is the answer: the debug layer stores none of the messages this one call makes (the filter init
    // pushed is back on top afterwards).
    bool filtered = false;
    if (infoQueue_) {
        D3D12_MESSAGE_SEVERITY all[] = {D3D12_MESSAGE_SEVERITY_CORRUPTION, D3D12_MESSAGE_SEVERITY_ERROR,
                                        D3D12_MESSAGE_SEVERITY_WARNING, D3D12_MESSAGE_SEVERITY_INFO,
                                        D3D12_MESSAGE_SEVERITY_MESSAGE};
        D3D12_INFO_QUEUE_FILTER filter{};
        filter.DenyList.NumSeverities = UINT(sizeof all / sizeof all[0]);
        filter.DenyList.pSeverityList = all;
        filtered = SUCCEEDED(infoQueue_->PushStorageFilter(&filter));
    }
    Com<ID3D12RootSignature> signature;
    hr = device_->CreateRootSignature(0, blob->GetBufferPointer(), blob->GetBufferSize(), __uuidof(ID3D12RootSignature),
                                      signature.put_void());
    if (filtered) infoQueue_->PopStorageFilter();
    if (FAILED(hr) || !signature) {
        why = "CreateRootSignature failed with " + hr_text(hr) + removed_reason();
        return false;
    }
    return true;
}

std::shared_ptr<const RootLayout> D3d12Device::root_layout(const ShaderDesc& desc, const ShaderInfo& info,
                                                           std::string& error) {
    const bool compute = info.compute;
    // The key names every slot with its stage, register and space (and whether the bindless table is there).
    KeyText key;
    key.add(compute ? "compute" : "render");
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        if (info.uniformSize[i] == 0) continue;
        const ShaderUniformBlock& b = desc.uniformBlocks[i];
        for (std::uint64_t v : {std::uint64_t('b'), std::uint64_t(i), std::uint64_t(stage_index(b.stage, compute)),
                                std::uint64_t(b.binding.hlslRegister), std::uint64_t(b.binding.hlslSpace)})
            key.add(v);
    }
    for (int i = 0; i < kMaxViews; ++i) {
        if (info.viewType[i] == ViewType::Invalid) continue;
        const Reg r = view_register(desc.views[i]);
        for (std::uint64_t v :
             {std::uint64_t('v'), std::uint64_t(i), std::uint64_t(stage_index(desc.views[i].stage(), compute)),
              std::uint64_t(r.cls), std::uint64_t(r.reg), std::uint64_t(r.space)})
            key.add(v);
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& s = desc.samplers[i];
        if (s.stage == ShaderStage::None) continue;
        for (std::uint64_t v : {std::uint64_t('s'), std::uint64_t(i), std::uint64_t(stage_index(s.stage, compute)),
                                std::uint64_t(s.binding.hlslRegister), std::uint64_t(s.binding.hlslSpace)})
            key.add(v);
    }
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        if (!info.accelDeclared[i]) continue;
        const BackendBinding& b = desc.accelStructures[i].binding;
        for (std::uint64_t v :
             {std::uint64_t('a'), std::uint64_t(i), std::uint64_t(b.hlslRegister), std::uint64_t(b.hlslSpace)})
            key.add(v);
    }
    key.add(bindlessDescriptors_ > 0 ? "bindless" : "-");
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        if (auto it = rootLayouts_.find(key.s); it != rootLayouts_.end()) {
            ++rootHits_;
            return it->second;
        }
    }

    auto layout = std::make_shared<RootLayout>();
    layout->key = key.s;
    std::fill(std::begin(layout->cbvParam), std::end(layout->cbvParam), -1);
    const D3D12_SHADER_VISIBILITY visibility[2] = {
        compute ? D3D12_SHADER_VISIBILITY_ALL : D3D12_SHADER_VISIBILITY_VERTEX,
        compute ? D3D12_SHADER_VISIBILITY_ALL : D3D12_SHADER_VISIBILITY_PIXEL,
    };
    std::vector<D3D12_ROOT_PARAMETER> params;
    std::vector<D3D12_DESCRIPTOR_RANGE> viewRanges[2], samplerRanges[2];
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        if (info.uniformSize[i] == 0) continue;
        const ShaderUniformBlock& b = desc.uniformBlocks[i];
        D3D12_ROOT_PARAMETER p{};
        p.ParameterType = D3D12_ROOT_PARAMETER_TYPE_CBV;
        p.Descriptor.ShaderRegister = b.binding.hlslRegister;
        p.Descriptor.RegisterSpace = b.binding.hlslSpace;
        p.ShaderVisibility = visibility[stage_index(b.stage, compute)];
        layout->cbvParam[i] = int(params.size());
        params.push_back(p);
    }
    // A TLAS: a root SRV at the structure's GPU address (root signature 1.0 takes them; a descriptor table would need
    // an SRV descriptor per build).
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        if (!info.accelDeclared[i]) continue;
        const BackendBinding& b = desc.accelStructures[i].binding;
        D3D12_ROOT_PARAMETER p{};
        p.ParameterType = D3D12_ROOT_PARAMETER_TYPE_SRV;
        p.Descriptor.ShaderRegister = b.hlslRegister;
        p.Descriptor.RegisterSpace = b.hlslSpace;
        p.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
        layout->accelParam[i] = int(params.size());
        params.push_back(p);
    }
    for (int i = 0; i < kMaxViews; ++i) {
        if (info.viewType[i] == ViewType::Invalid) continue;
        const auto s = std::size_t(stage_index(desc.views[i].stage(), compute));
        const Reg r = view_register(desc.views[i]);
        D3D12_DESCRIPTOR_RANGE d{};
        d.RangeType = r.cls == 't' ? D3D12_DESCRIPTOR_RANGE_TYPE_SRV : D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
        d.NumDescriptors = 1;
        d.BaseShaderRegister = r.reg;
        d.RegisterSpace = r.space;
        d.OffsetInDescriptorsFromTableStart = layout->viewCount[s];
        layout->viewStage[i] = std::uint8_t(s);
        layout->viewOffset[i] = layout->viewCount[s]++;
        viewRanges[s].push_back(d);
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& sm = desc.samplers[i];
        if (sm.stage == ShaderStage::None) continue;
        const auto s = std::size_t(stage_index(sm.stage, compute));
        D3D12_DESCRIPTOR_RANGE d{};
        d.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
        d.NumDescriptors = 1;
        d.BaseShaderRegister = sm.binding.hlslRegister;
        d.RegisterSpace = sm.binding.hlslSpace;
        d.OffsetInDescriptorsFromTableStart = layout->samplerCount[s];
        layout->samplerStage[i] = std::uint8_t(s);
        layout->samplerOffset[i] = layout->samplerCount[s]++;
        layout->samplerUsed |= 1u << i;
        samplerRanges[s].push_back(d);
    }
    // Resource binding tier 1 (old GPUs) caps what a root signature may hold: 128 SRVs and 16 samplers per stage, which
    // ShaderDesc's kMaxViews and kMaxSamplers never exceed, and 8 UAVs in all at feature level 11.0 (64 above), which a
    // shader with many storage views can.
    static_assert(kMaxViews <= 128 && kMaxSamplers <= 16, "the tier 1 limits checked below assume these");
    if (bindingTier_ == 1) {
        // A UAV that several stages see is one register, not one per stage: count distinct (register, space) pairs.
        std::vector<std::uint64_t> uavRegs;
        for (const auto& ranges : viewRanges)
            for (const D3D12_DESCRIPTOR_RANGE& r : ranges)
                if (r.RangeType == D3D12_DESCRIPTOR_RANGE_TYPE_UAV)
                    for (UINT k = 0; k < r.NumDescriptors; ++k)
                        uavRegs.push_back(std::uint64_t(r.RegisterSpace) << 32 | (r.BaseShaderRegister + k));
        std::sort(uavRegs.begin(), uavRegs.end());
        const int uavs = int(std::unique(uavRegs.begin(), uavRegs.end()) - uavRegs.begin());
        const int uavLimit = featureLevel_ == D3D_FEATURE_LEVEL_11_0 ? 8 : 64;
        if (uavs > uavLimit) {
            error = "it declares " + std::to_string(uavs) + " writable views (storage buffers and images), and " +
                    adapterName_ + " has resource binding tier 1" +
                    (featureLevel_ == D3D_FEATURE_LEVEL_11_0 ? " at feature level 11.0" : "") +
                    ", which binds at most " + std::to_string(uavLimit) +
                    " (hint: split the work into passes that each write fewer views, make the views it only reads "
                    "read-only, or pack the data into fewer storage buffers)";
            return nullptr;
        }
    }
    auto table = [&](const std::vector<D3D12_DESCRIPTOR_RANGE>& ranges, D3D12_SHADER_VISIBILITY v) {
        D3D12_ROOT_PARAMETER p{};
        p.ParameterType = D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
        p.DescriptorTable.NumDescriptorRanges = UINT(ranges.size());
        p.DescriptorTable.pDescriptorRanges = ranges.data();
        p.ShaderVisibility = v;
        params.push_back(p);
        return int(params.size() - 1);
    };
    for (std::size_t s = 0; s < 2; ++s)
        if (!viewRanges[s].empty()) layout->viewTable[s] = table(viewRanges[s], visibility[s]);
    for (std::size_t s = 0; s < 2; ++s)
        if (!samplerRanges[s].empty()) layout->samplerTable[s] = table(samplerRanges[s], visibility[s]);
    std::vector<D3D12_DESCRIPTOR_RANGE> bindless;
    if (bindlessDescriptors_ > 0) {
        D3D12_DESCRIPTOR_RANGE d{};
        d.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
        d.NumDescriptors = UINT_MAX;  // unbounded
        d.BaseShaderRegister = 0;
        d.RegisterSpace = 1;
        d.OffsetInDescriptorsFromTableStart = 0;
        bindless.push_back(d);
        layout->bindlessTable = table(bindless, D3D12_SHADER_VISIBILITY_ALL);
    }

    D3D12_ROOT_SIGNATURE_DESC rd{};
    rd.NumParameters = UINT(params.size());
    rd.pParameters = params.empty() ? nullptr : params.data();
    rd.Flags = compute ? D3D12_ROOT_SIGNATURE_FLAG_NONE
                       : D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT |
                             D3D12_ROOT_SIGNATURE_FLAG_DENY_HULL_SHADER_ROOT_ACCESS |
                             D3D12_ROOT_SIGNATURE_FLAG_DENY_DOMAIN_SHADER_ROOT_ACCESS |
                             D3D12_ROOT_SIGNATURE_FLAG_DENY_GEOMETRY_SHADER_ROOT_ACCESS;
    Com<ID3DBlob> blob, messages;
    HRESULT hr = D3D12SerializeRootSignature(&rd, D3D_ROOT_SIGNATURE_VERSION_1, blob.put(), messages.put());
    if (FAILED(hr) || !blob) {
        std::string text;
        if (messages && messages->GetBufferSize() > 0)
            text.assign(static_cast<const char*>(messages->GetBufferPointer()), messages->GetBufferSize());
        while (!text.empty() && (text.back() == '\0' || text.back() == '\n')) text.pop_back();
        error = "D3D12SerializeRootSignature refused its slots (" + std::to_string(params.size()) +
                " root parameters): " + (text.empty() ? hr_text(hr) : text) +
                " (hint: the uniform blocks, views and samplers of ShaderDesc name the registers; check them against "
                "the HLSL)";
        return nullptr;
    }
    hr = device_->CreateRootSignature(0, blob->GetBufferPointer(), blob->GetBufferSize(), __uuidof(ID3D12RootSignature),
                                      layout->signature.put_void());
    if (FAILED(hr) || !layout->signature) {
        drain_messages();
        error = "CreateRootSignature failed with " + hr_text(hr) + removed_reason() +
                " (hint: the debug layer's message before this one (D3d12Options::debugLayer) says why)";
        return nullptr;
    }
    layout->signature->SetName(L"fa-d3d12-root-signature");
    std::lock_guard<std::mutex> lock(cacheMutex_);
    auto [it, added] = rootLayouts_.try_emplace(layout->key, layout);
    if (!added) ++rootHits_;  // another thread made the same one meanwhile
    return it->second;
}

void D3d12Device::destroy_shader(Shader shader) {
    if (!shader.valid()) return;
    ShaderRecord rec;
    std::lock_guard<std::mutex> lock(resMutex_);
    if (!shaders_.remove(shader.id, rec)) {
        report("gpu d3d12: destroy_shader: shader " + std::to_string(shader.id) +
               " names nothing (hint: it was destroyed already, or another device made it)");
        return;
    }
    // Its code and root signature live on in the pipelines made from it (and the root signature in the cache).
    count_destroy(stats_.shaders);
}

ResourceState D3d12Device::state(Shader shader) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ShaderRecord* r = shaders_.get(shader.id);
    if (!r) return ResourceState::Invalid;
    return r->info ? ResourceState::Valid : ResourceState::Failed;
}

std::shared_ptr<const RootLayout> D3d12Device::shader_root_layout(Shader shader) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ShaderRecord* r = shaders_.get(shader.id);
    return r ? r->layout : nullptr;
}

// ---------------------------------------------------------------------------------------------------------------------
// Pipelines
// ---------------------------------------------------------------------------------------------------------------------

Com<ID3D12PipelineState> D3d12Device::pso(const std::string& key, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* graphics,
                                          const D3D12_COMPUTE_PIPELINE_STATE_DESC* compute, std::string& error) {
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        if (auto it = psos_.find(key); it != psos_.end()) {
            ++psoHits_;
            return it->second;
        }
    }
    // The pipeline library (the on-disk cache) holds the PSOs earlier runs made, under a name hashed from `key`: a
    // load there skips the driver's compile. A name it does not hold yet answers E_INVALIDARG (not an error).
    const std::wstring name = widen(("fa-" + sha256_hex(key)).c_str());
    // Into psos_. Called under libraryMutex_ when the library loaded or stored the PSO (the only nesting of the two
    // locks, always in this order): a trimming save_pipeline_cache() that reads libraryHits_ + libraryMisses_ then
    // finds every PSO they count in psos_.
    const auto keep = [&](const Com<ID3D12PipelineState>& state) {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        ++psoMisses_;
        auto [it, added] = psos_.try_emplace(key, state);
        (void)added;  // another thread made the same one meanwhile: both are the same state, the first one is kept
        return it->second;
    };
    Com<ID3D12PipelineState> made;
    {
        std::lock_guard<std::mutex> lock(libraryMutex_);
        if (library_) {
            const HRESULT lhr = graphics
                                    ? library_->LoadGraphicsPipeline(name.c_str(), graphics,
                                                                     __uuidof(ID3D12PipelineState), made.put_void())
                                    : library_->LoadComputePipeline(name.c_str(), compute,
                                                                    __uuidof(ID3D12PipelineState), made.put_void());
            bool loaded = SUCCEEDED(lhr) && made;
            if (!loaded) {
                made.reset();
                // After a trim the new library holds only the PSOs this run used: the libraries it replaced still
                // hold the ones loaded from the file and not asked for yet.
                for (const Com<ID3D12PipelineLibrary>& retired : retiredLibraries_) {
                    const HRESULT rhr =
                        graphics ? retired->LoadGraphicsPipeline(name.c_str(), graphics, __uuidof(ID3D12PipelineState),
                                                                 made.put_void())
                                 : retired->LoadComputePipeline(name.c_str(), compute, __uuidof(ID3D12PipelineState),
                                                                made.put_void());
                    if (SUCCEEDED(rhr) && made) {
                        // The next file keeps it: the current library gets it too.
                        if (SUCCEEDED(library_->StorePipeline(name.c_str(), made.get()))) libraryDirty_ = true;
                        loaded = true;
                        break;
                    }
                    made.reset();
                }
            }
            if (loaded) {
                ++libraryHits_;
                D3d12PipelineCacheTotals add;
                add.libraryHits = 1;
                d3d12_pipeline_cache_count(add);
                made->SetName(L"fa-d3d12-pso");
                return keep(made);
            }
        }
    }
    // Made without the lock: making a PSO compiles the shaders for the GPU and may take milliseconds.
    const HRESULT hr =
        graphics ? device_->CreateGraphicsPipelineState(graphics, __uuidof(ID3D12PipelineState), made.put_void())
                 : device_->CreateComputePipelineState(compute, __uuidof(ID3D12PipelineState), made.put_void());
    if (FAILED(hr) || !made) {
        drain_messages();
        error = std::string(graphics ? "CreateGraphicsPipelineState" : "CreateComputePipelineState") + " failed with " +
                hr_text(hr) + removed_reason() +
                " (hint: the debug layer's message before this one (D3d12Options::debugLayer) names the field; a "
                "shader whose HLSL registers or vertex inputs differ from its ShaderDesc is refused here)";
        return {};
    }
    made->SetName(L"fa-d3d12-pso");
    std::lock_guard<std::mutex> lock(libraryMutex_);
    // Another thread may have stored the same name meanwhile (E_INVALIDARG): the library has it either way.
    if (library_ && SUCCEEDED(library_->StorePipeline(name.c_str(), made.get()))) {
        libraryDirty_ = true;
        ++libraryMisses_;
        D3d12PipelineCacheTotals add;
        add.libraryMisses = 1;
        d3d12_pipeline_cache_count(add);
    }
    return keep(made);
}

// ---------------------------------------------------------------------------------------------------------------------
// The pipeline cache on disk: an ID3D12PipelineLibrary loaded from D3d12Options::pipelineCacheFile when the device is
// made and written back by save_pipeline_cache() (PipelineCacheFile in d3d12_device.h says what the file holds; its
// header is written and checked in d3d12_device.cpp, on every platform)
// ---------------------------------------------------------------------------------------------------------------------

namespace {

// What replace_cache_file did: empty `why` = written, else what went wrong and why (the hint follows from `kind`).
struct CacheWrite {
    std::string why;
    CacheWriteFailure kind = CacheWriteFailure::Other;
};

// Another process holds `osFile` open without sharing deletes (a reader, a scanner, an indexer): opening it for DELETE
// fails with a sharing or lock violation. A file that is missing or whose permissions refuse the open is not held.
bool held_by_other(const std::filesystem::path& osFile) {
    HANDLE h = CreateFileW(osFile.c_str(), DELETE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h != INVALID_HANDLE_VALUE) {
        CloseHandle(h);
        return false;
    }
    const DWORD e = GetLastError();
    return e == ERROR_SHARING_VIOLATION || e == ERROR_LOCK_VIOLATION;
}

// Writes `bytes` to `target` atomically: a temporary file next to it, then MoveFileExW(MOVEFILE_REPLACE_EXISTING) over
// it, so a reader never sees half a file and a failure leaves the old one. When the move fails,
// d3d12_classify_cache_write_error says why and d3d12_cache_replace_policy how long to try again: a cache is only a
// speed-up, so a reader that holds the OLD file is waited for 3 x 1 ms (Windows sleeps up to one timer step, ~15.6 ms)
// and the old file is kept, since a long wait would stretch the shutdown of every run that meets one; a scanner that
// holds the TEMPORARY file lets go within a moment, so that one is waited for up to 8 x 20 ms.
CacheWrite replace_cache_file(const std::filesystem::path& target, const std::vector<std::uint8_t>& bytes) {
    static std::atomic<unsigned> counter{0};
    std::filesystem::path tmp = target;
    tmp += L".fa-tmp" + std::to_wstring(GetCurrentProcessId()) + L"_" + std::to_wstring(counter.fetch_add(1));
    const std::filesystem::path osTmp = fs::os_path(tmp), osTarget = fs::os_path(target);
    HANDLE h = CreateFileW(osTmp.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        const DWORD e = GetLastError();
        return {"the temporary file " + fs::path_to_utf8(tmp) + " could not be made (" +
                    hr_text(HRESULT_FROM_WIN32(e)) + ")",
                e == ERROR_ACCESS_DENIED ? CacheWriteFailure::FolderDenied : CacheWriteFailure::Other};
    }
    DWORD err = 0;
    for (std::size_t at = 0; at < bytes.size() && err == 0;) {
        const DWORD chunk = DWORD(std::min<std::size_t>(bytes.size() - at, std::size_t(1) << 30));
        DWORD wrote = 0;
        if (!WriteFile(h, bytes.data() + at, chunk, &wrote, nullptr) || wrote != chunk) {
            err = GetLastError();
            if (err == 0) err = ERROR_DISK_FULL;  // a short write without an error code
        }
        at += chunk;
    }
    if (!CloseHandle(h) && err == 0) err = GetLastError();
    if (err != 0) {
        DeleteFileW(osTmp.c_str());
        return {"writing the temporary file " + fs::path_to_utf8(tmp) + " failed (" + hr_text(HRESULT_FROM_WIN32(err)) +
                    ")",
                CacheWriteFailure::Other};
    }
    CacheWriteFailure kind = CacheWriteFailure::Other;
    for (int attempt = 0;; ++attempt) {
        if (MoveFileExW(osTmp.c_str(), osTarget.c_str(), MOVEFILE_REPLACE_EXISTING)) return {};
        err = GetLastError();
        const DWORD attributes = GetFileAttributesW(osTarget.c_str());
        const bool readOnly = attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_READONLY) != 0;
        kind = d3d12_classify_cache_write_error(err, held_by_other(osTmp), held_by_other(osTarget), readOnly);
        const CacheReplacePolicy policy = d3d12_cache_replace_policy(kind);
        if (attempt >= policy.retries) break;
        Sleep(DWORD(policy.sleepMs));
    }
    DeleteFileW(osTmp.c_str());
    return {"the old file could not be replaced (" + hr_text(HRESULT_FROM_WIN32(err)) + ")", kind};
}

// Deletes the temporary files of this cache file that a crashed save left in its folder (d3d12_orphan_cache_temps picks
// them: older than a minute). One a process still holds open (a save running now that is slow) fails to delete and
// stays. At most kMaxScanned entries of the folder are looked at, however large it is.
void remove_orphan_cache_temps(const std::filesystem::path& cacheFile) {
    constexpr int kMaxScanned = 20000;
    const std::filesystem::path folder =
        cacheFile.parent_path().empty() ? std::filesystem::path(".") : cacheFile.parent_path();
    std::error_code ec;
    std::filesystem::directory_iterator it(fs::os_path(folder), ec), end;
    if (ec) return;
    const std::int64_t nowNs =
        std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::system_clock::now().time_since_epoch())
            .count();
    std::vector<CacheFolderEntry> entries;
    int scanned = 0;
    for (; it != end && scanned < kMaxScanned; it.increment(ec), ++scanned) {
        if (ec) break;
        const std::string name = fs::path_to_utf8(it->path().filename());
        if (name.find(".fa-tmp") == std::string::npos) continue;  // only these are looked at (no stat of the others)
        const std::int64_t modified = fs::host_modified_time(it->path());
        CacheFolderEntry entry;
        entry.name = name;
        entry.ageSeconds = modified < 0 ? 0 : (nowNs - modified) / 1000000000;
        entries.push_back(std::move(entry));
    }
    const std::string cacheName = fs::path_to_utf8(cacheFile.filename());
    for (const std::string& name : d3d12_orphan_cache_temps(entries, cacheName)) {
        const std::filesystem::path orphan = folder / fs::path_from_utf8(name);
        // A scanner that holds the leftover for a moment (a sharing violation) is tried again 2 more times, 1 ms apart.
        bool removed = false;
        for (int attempt = 0; attempt < 3 && !removed; ++attempt) {
            removed = DeleteFileW(fs::os_path(orphan).c_str()) != 0;
            if (removed || GetLastError() != ERROR_SHARING_VIOLATION) break;
            Sleep(1);
        }
        if (removed) FA_INFO("render", "gpu d3d12: removed the leftover {}", name);
    }
}

std::string mib_text(std::uint64_t bytes) {
    char text[32];
    std::snprintf(text, sizeof text, "%.1f MiB", double(bytes) / double(1u << 20));
    return text;
}

}  // namespace

void D3d12Device::init_pipeline_library() {
    if (pipelineCacheFile_.empty()) return;
    remove_orphan_cache_temps(pipelineCacheFile_);
    Com<ID3D12Device1> device1 = device_.as<ID3D12Device1>();
    if (!device1) {
        FA_INFO("render", "gpu d3d12: {} has no ID3D12Device1 (pipeline libraries): PSOs are cached in memory only",
                adapterName_);
        return;
    }
    const std::string file = fs::path_to_utf8(pipelineCacheFile_);
    using F = PipelineCacheFile;
    std::string discard;  // why the file is thrown away; empty = kept (or there is none)
    std::vector<std::uint8_t> bytes;
    // One read of the whole file (it counts once in fs::disk_reads, so in the startup report's diskReadsAtFirstPresent:
    // the device is made before the first present).
    const std::int64_t size = fs::file_size(file);
    if (size > std::int64_t(F::kMaxBytes)) {
        discard = "it has " + std::to_string(size) + " bytes, more than the " + std::to_string(F::kMaxBytes) +
                  " a pipeline cache may have";
    } else if (size >= 0) {
        auto read = fs::read_bytes(file);
        if (!read)
            discard = "it could not be read: " + read.error().message;
        else
            bytes = std::move(*read);
    }
    if (discard.empty() && size >= 0) discard = pipeline_cache_mismatch(bytes, identity_, adapterName_);
    auto create = [&](const std::vector<std::uint8_t>& blob) {
        library_.reset();
        return device1->CreatePipelineLibrary(blob.empty() ? nullptr : blob.data(), blob.size(),
                                              __uuidof(ID3D12PipelineLibrary), library_.put_void());
    };
    HRESULT hr = S_OK;
    bool loaded = false;
    if (discard.empty() && size >= 0) {
        // The library reads its blob for its whole life: it lives in libraryBlob_.
        libraryBlob_.assign(bytes.begin() + std::ptrdiff_t(F::kHeaderBytes), bytes.end());
        hr = create(libraryBlob_);
        if (hr == E_INVALIDARG || hr == D3D12_ERROR_ADAPTER_NOT_FOUND || hr == D3D12_ERROR_DRIVER_VERSION_MISMATCH)
            discard = "the driver refused it (CreatePipelineLibrary: " + hr_text(hr) + ")";
        else
            loaded = SUCCEEDED(hr) && library_;
    }
    if (!loaded && (hr != DXGI_ERROR_UNSUPPORTED)) {
        libraryBlob_.clear();
        hr = create(libraryBlob_);  // an empty library: this run's PSOs go into it
    }
    if (FAILED(hr) || !library_) {
        library_.reset();
        libraryBlob_.clear();
        // DXGI_ERROR_UNSUPPORTED: the driver has no pipeline libraries (or a graphics debugger is attached).
        FA_INFO("render", "gpu d3d12: {} makes no pipeline library ({}): PSOs are cached in memory only", adapterName_,
                hr_text(hr));
        return;
    }
    library_->SetName(L"fa-d3d12-pipeline-library");
    D3d12PipelineCacheTotals add;
    if (loaded) add.filesLoaded = 1;
    if (!discard.empty()) {
        add.filesDiscarded = 1;
        const std::string message =
            "gpu d3d12: the pipeline cache " + file + " was thrown away: " + discard +
            "; its pipelines are compiled again and the file is written anew (hint: nothing to fix; it happens after "
            "a GPU or driver change, and deleting the file clears the cache)";
        FA_WARN("render", "{}", message);
        std::lock_guard<std::mutex> lock(msgMutex_);
        warnings_.push_back(message);
    }
    d3d12_pipeline_cache_count(add);
    std::lock_guard<std::mutex> lock(libraryMutex_);
    if (!discard.empty()) {
        ++cacheDiscarded_;
        libraryDirty_ = true;  // the next save replaces the thrown-away file
    }
}

Result<void> D3d12Device::save_pipeline_cache() {
    if (pipelineCacheFile_.empty()) return {};
    using F = PipelineCacheFile;
    const std::string file = fs::path_to_utf8(pipelineCacheFile_);
    D3d12PipelineCacheTotals add;
    // Every way a save fails: the counter, the log, warnings(), and the library stays dirty (the next save tries again).
    auto fail = [&](const std::string& message, const std::string& hint) -> Result<void> {
        add.storeFailed = 1;
        d3d12_pipeline_cache_count(add);
        {
            std::lock_guard<std::mutex> lock(libraryMutex_);
            libraryDirty_ = true;
        }
        FA_WARN("render", "{} (hint: {})", message, hint);
        {
            std::lock_guard<std::mutex> lock(msgMutex_);
            warnings_.push_back(message + " (hint: " + hint + ")");
        }
        return make_error(message, hint);
    };

    // 1. Whether there is anything to do: PSOs the file does not hold, or a library over the trim size.
    std::uint64_t before = 0, storesBefore = 0;
    bool trim = false;
    {
        std::lock_guard<std::mutex> lock(libraryMutex_);
        if (!library_) return {};
        before = std::uint64_t(library_->GetSerializedSize());
        trim = trimBytes_ > 0 && before > trimBytes_ && !trimTried_;
        if (!libraryDirty_ && !trim) return {};
        storesBefore = libraryMisses_ + libraryHits_;
    }

    // 2. The trim: a new library with only the PSOs this device made or loaded (psos_ holds every one of them), built
    // without the library's lock. A run that made none says nothing about what is used: it keeps the file.
    Com<ID3D12PipelineLibrary> trimmed;
    std::size_t kept = 0;
    std::uint64_t after = 0;
    if (trim) {
        std::vector<std::pair<std::string, Com<ID3D12PipelineState>>> used;
        {
            std::lock_guard<std::mutex> lock(cacheMutex_);
            used.assign(psos_.begin(), psos_.end());
        }
        Com<ID3D12Device1> device1 = device_.as<ID3D12Device1>();
        if (!used.empty() && device1 &&
            SUCCEEDED(
                device1->CreatePipelineLibrary(nullptr, 0, __uuidof(ID3D12PipelineLibrary), trimmed.put_void())) &&
            trimmed) {
            for (const auto& [key, made] : used) {
                const std::wstring name = widen(("fa-" + sha256_hex(key)).c_str());
                if (SUCCEEDED(trimmed->StorePipeline(name.c_str(), made.get()))) ++kept;
            }
            after = std::uint64_t(trimmed->GetSerializedSize());
        } else {
            trimmed.reset();
        }
    }

    std::size_t psoCount = 0;  // for the hint of a library over kMaxBytes
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        psoCount = psos_.size();
    }

    // 3. The bytes to write, under the library's lock.
    std::vector<std::uint8_t> bytes;
    std::string failure, hint;
    bool didTrim = false;
    {
        std::lock_guard<std::mutex> lock(libraryMutex_);
        if (!library_) return {};
        // A PSO another thread stored or loaded meanwhile may not be in the trimmed library: the trim waits for the
        // next save then.
        if (trimmed && libraryMisses_ + libraryHits_ == storesBefore) {
            trimTried_ = true;  // from now on the library holds only used PSOs: a second rebuild drops nothing
            if (after < before) {
                retiredLibraries_.push_back(std::move(library_));
                library_ = std::move(trimmed);
                library_->SetName(L"fa-d3d12-pipeline-library");
                libraryDirty_ = true;
                trimUnwritten_ = true;  // counted when a file holds it (a failed write keeps it for the next save)
                didTrim = true;
            }
        }
        if (!libraryDirty_) return {};
        const SIZE_T payload = library_->GetSerializedSize();
        if (std::uint64_t(payload) > F::kMaxBytes - F::kHeaderBytes) {
            failure = "gpu d3d12: the pipeline cache " + file + " was not written: its library has " +
                      std::to_string(payload) + " bytes, more than the " + std::to_string(F::kMaxBytes) +
                      " a cache file may have; the old file was kept";
            hint = "this run made " + std::to_string(psoCount) +
                   " distinct pipelines: a desc field that changes every frame (a size, a format) makes a new PSO "
                   "each time; counters().psos says how many the device keeps";
        } else {
            bool allocated = true;
            try {
                bytes.resize(F::kHeaderBytes + payload);
            } catch (const std::bad_alloc&) {
                allocated = false;
            }
            const HRESULT hr = allocated ? library_->Serialize(bytes.data() + F::kHeaderBytes, payload) : E_OUTOFMEMORY;
            if (FAILED(hr)) {
                failure = "gpu d3d12: the pipeline cache " + file + " was not written: serializing its " +
                          std::to_string(payload) + "-byte pipeline library failed with " + hr_text(hr) +
                          removed_reason() + "; the old file was kept";
                hint = "the device was lost or memory ran out; nothing to fix unless it happens every run (then free "
                       "memory, or delete the file to start the cache anew)";
            } else {
                libraryDirty_ = false;  // a PSO stored from here on makes it dirty again
            }
        }
    }
    if (!failure.empty()) return fail(failure, hint);
    write_pipeline_cache_header(bytes, identity_);

    std::error_code ec;
    std::filesystem::create_directories(fs::os_path(pipelineCacheFile_.parent_path()), ec);  // a failure shows below
    const CacheWrite written = replace_cache_file(pipelineCacheFile_, bytes);
    if (!written.why.empty())
        return fail("gpu d3d12: the pipeline cache could not be written to " + file + ": " + written.why +
                        "; the old file was kept",
                    d3d12_cache_write_hint(written.kind, file));
    bool wroteTrim = false;  // a trimmed library counts once, when a file holds it
    {
        std::lock_guard<std::mutex> lock(libraryMutex_);
        wroteTrim = trimUnwritten_;
        trimUnwritten_ = false;
        if (wroteTrim) ++cacheTrimmed_;
        ++cacheStored_;
    }
    add.filesStored = 1;
    if (wroteTrim) add.filesTrimmed = 1;
    d3d12_pipeline_cache_count(add);
    if (didTrim)
        FA_INFO("render",
                "gpu d3d12: wrote the pipeline cache {} ({}): its library had {}, more than pipelineCacheTrimBytes "
                "({}), and was rebuilt with only the {} pipelines this run used",
                file, mib_text(bytes.size()), mib_text(before), mib_text(trimBytes_), kept);
    else if (wroteTrim)
        FA_INFO("render",
                "gpu d3d12: wrote the pipeline cache {} ({}): the library rebuilt with only the pipelines this run "
                "used by an earlier save, which could not write it",
                file, mib_text(bytes.size()));
    else
        FA_INFO("render", "gpu d3d12: wrote the pipeline cache {} ({})", file, mib_text(bytes.size()));
    return {};
}

Pipeline D3d12Device::make_pipeline(const PipelineDesc& desc) {
    const std::string label = label_of(desc.label);
    std::string error;
    auto fail = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    std::shared_ptr<const ShaderInfo> shader;
    std::shared_ptr<const RootLayout> layout;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        const ShaderRecord* s = shaders_.get(desc.shader.id);
        if (!s) {
            fail("its shader " + std::to_string(desc.shader.id) +
                 " is not a live shader (hint: make_shader() it first and keep it until make_pipeline() returns)");
        } else if (!s->info) {
            fail("its shader failed (make_shader reported why in errors())");
        } else {
            shader = s->info;
            layout = s->layout;
        }
    }
    auto st = std::make_shared<PipelineState>();
    st->label = label;
    st->compute = desc.compute;
    if (error.empty() && desc.compute != shader->compute)
        fail(desc.compute ? "it is a compute pipeline and shader '" + shader->label +
                                "' is a render shader (hint: a compute pipeline's shader sets computeFunc)"
                          : "it is a render pipeline and shader '" + shader->label +
                                "' is a compute shader (hint: set PipelineDesc::compute)");
    if (error.empty()) {
        st->shader = shader;
        st->layout = layout;
        std::string e;
        if (desc.compute) {
            D3D12_COMPUTE_PIPELINE_STATE_DESC c{};
            c.pRootSignature = layout->signature.get();
            c.CS.pShaderBytecode = shader->cs.data();
            c.CS.BytecodeLength = shader->cs.size();
            st->pso = pso("compute|" + shader->codeKey + "|" + layout->key, nullptr, &c, e);
        } else {
            GraphicsBuild g;
            e = graphics_desc(desc, *shader, defaults_, caps_, *st, g);
            if (e.empty()) {
                g.d.pRootSignature = layout->signature.get();
                g.d.VS.pShaderBytecode = shader->vs.data();
                g.d.VS.BytecodeLength = shader->vs.size();
                g.d.PS.pShaderBytecode = shader->fs.data();
                g.d.PS.BytecodeLength = shader->fs.size();
                st->pso = pso("render|" + shader->codeKey + "|" + layout->key + "|" + g.key.s, &g.d, nullptr, e);
            }
        }
        if (!st->pso) fail(e);
    }
    if (!error.empty()) report("gpu d3d12: make_pipeline '" + label + "': " + error);

    PipelineRecord rec;
    if (error.empty()) rec.state = std::move(st);
    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.state != nullptr;
    const std::uint32_t id = pipelines_.add(std::move(rec));
    if (id == 0) {
        report("gpu d3d12: make_pipeline '" + label + "': the pipeline pool is full (" +
               std::to_string(pipelines_.capacity()) +
               " pipelines) (hint: destroy pipelines you no longer use, or raise DeviceInit::pipelinePoolSize)");
        return {};
    }
    count_make(stats_.pipelines, ok);
    return Pipeline{id};
}

void D3d12Device::destroy_pipeline(Pipeline pipeline) {
    if (!pipeline.valid()) return;
    PipelineRecord rec;
    std::lock_guard<std::mutex> lock(resMutex_);
    if (!pipelines_.remove(pipeline.id, rec)) {
        report("gpu d3d12: destroy_pipeline: pipeline " + std::to_string(pipeline.id) +
               " names nothing (hint: it was destroyed already, or another device made it)");
        return;
    }
    // A list that set it holds its state until the list is reused; the PSO stays in the cache for the device's life.
    count_destroy(stats_.pipelines);
}

ResourceState D3d12Device::state(Pipeline pipeline) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const PipelineRecord* r = pipelines_.get(pipeline.id);
    if (!r) return ResourceState::Invalid;
    return r->state ? ResourceState::Valid : ResourceState::Failed;
}

std::shared_ptr<const PipelineState> D3d12Device::pipeline_state(Pipeline pipeline) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const PipelineRecord* r = pipelines_.get(pipeline.id);
    return r ? r->state : nullptr;
}

}  // namespace fa::gpu::d3d12
