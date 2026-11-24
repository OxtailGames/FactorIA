// Private to fa_render: the vocabulary of the engine's GPU interface (M77, docs/design/ARCHITECTURE_RENDERING_GPU.md).
//
// Everything a backend needs to know about a resource, a pipeline, a pass or a draw, without one sokol type: the
// sokol_gfx backends (GL, GLES3, WebGL2, D3D11, Metal; gpu/sokol_device.cpp), the engine's own D3D12 and Vulkan
// backends (M77.2, M77.3) and the RecordingDevice of the tests (gpu/recording_device.h) all take these.
//
//  * Handles are opaque 32-bit ids, 0 = invalid. A backend never reuses an id while the old one could still be named:
//    the upper bits hold a generation that changes when a slot is reused. On the sokol backends the id IS the sokol id
//    (gpu::Image{img.id} names the same image as sg_image{img.id}), so a call site can be converted one call at a time.
//  * Every enum has sokol_gfx's values (the sokol backend converts with a static_cast; sokol_device.cpp asserts each
//    value), and its zero is "the default" where sokol has a default (`Default`), so a value-initialised desc means
//    what a zero sokol desc means.
//  * Every desc is a plain struct with defaults; strings (labels, shader source, entry points) and data ranges are
//    borrowed for the duration of the call that takes them, never kept.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <initializer_list>

namespace fa::gpu {

// ---------------------------------------------------------------------------------------------------------------------
// Limits of the descs (sokol_gfx's SG_MAX_* values: a desc of this interface converts to a sokol one slot for slot).
// ---------------------------------------------------------------------------------------------------------------------
inline constexpr int kMaxColorAttachments = 8;  // colour attachments of a pass, colour targets of a pipeline
inline constexpr int kMaxUniformBlockMembers =
    16;                                          // GL uniforms of one uniform block (ShaderUniformBlock::glslUniforms)
inline constexpr int kMaxVertexAttributes = 16;  // vertex attributes of a pipeline / shader
inline constexpr int kMaxMipmaps = 16;           // mip levels of an image (ImageData::mipLevels)
inline constexpr int kMaxVertexBuffers = 8;      // vertex buffer slots of Bindings and of a vertex layout
inline constexpr int kMaxUniformBlocks = 8;      // uniform block slots of a shader (CommandList::set_uniforms)
inline constexpr int kMaxViews = 32;             // view slots of a shader / Bindings (textures, storage)
inline constexpr int kMaxSamplers = 12;          // sampler slots of a shader / Bindings
inline constexpr int kMaxTextureSamplerPairs = 32;  // texture-sampler pairs of a shader (GL combines them)
inline constexpr int kInflightFrames = 2;           // frames the CPU may record ahead of the GPU (sokol's value)

// ---------------------------------------------------------------------------------------------------------------------
// Handles
// ---------------------------------------------------------------------------------------------------------------------

// An opaque handle: `id` 0 is the invalid handle; any other id names one resource of the device that made it, until it
// is destroyed. The Tag makes a Buffer and an Image different types, so a view cannot be passed where an image is meant.
template <class Tag>
struct Handle {
    std::uint32_t id = 0;
    constexpr bool valid() const { return id != 0; }  // not 0; says nothing about whether it is still alive
    constexpr explicit operator bool() const { return id != 0; }
    friend constexpr bool operator==(Handle a, Handle b) { return a.id == b.id; }
    friend constexpr bool operator!=(Handle a, Handle b) { return a.id != b.id; }
};
using Buffer = Handle<struct BufferTag>;      // vertex, index, storage or staging memory
using Image = Handle<struct ImageTag>;        // a texture, render target or storage image (the memory)
using View = Handle<struct ViewTag>;          // how a pass or a shader sees an image or a buffer
using Sampler = Handle<struct SamplerTag>;    // filtering and addressing state
using Shader = Handle<struct ShaderTag>;      // a compiled program and its reflection
using Pipeline = Handle<struct PipelineTag>;  // a shader plus the fixed-function state it draws (or dispatches) with

// A pointer and a size: data the call reads (and never keeps).
struct Range {
    const void* ptr = nullptr;
    std::size_t size = 0;
};

// A linear RGBA colour (clear colours, the blend constant).
struct Color {
    float r = 0.0f, g = 0.0f, b = 0.0f, a = 0.0f;
};

// ---------------------------------------------------------------------------------------------------------------------
// Backends
// ---------------------------------------------------------------------------------------------------------------------

// The API a Device drives. Not sokol's enum (sokol has three Metal values and no D3D12): Metal's platform is in
// DeviceInfo::metalTarget, and the shader language a custom material compiles to follows from both.
enum class Backend : std::uint8_t {
    Gl,         // desktop OpenGL 4.1 / 4.3 core (sokol GLCORE)
    Gles3,      // OpenGL ES 3.0 (Android, sokol GLES3)
    WebGl2,     // WebGL 2 in a browser (sokol GLES3 under Emscripten)
    D3d11,      // Direct3D 11 (sokol)
    Metal,      // Metal on macOS, iOS or the iOS simulator (sokol)
    D3d12,      // Direct3D 12, the engine's own backend (M77.2)
    Vulkan,     // Vulkan, the engine's own backend (M77.3)
    Recording,  // no GPU: RecordingDevice, which validates and records the calls (tests)
};

// The platform of a Metal device (the MSL dialect a shader is compiled for); None on every other backend.
enum class MetalTarget : std::uint8_t { None, MacOs, Ios, Simulator };

// ---------------------------------------------------------------------------------------------------------------------
// Enums with sokol_gfx's values (sokol_device.cpp static_asserts every one)
// ---------------------------------------------------------------------------------------------------------------------

// sg_pixel_format. `Default` (0) = "the default of the context" where a desc accepts it (a pass into the window, a
// pipeline); `None` = no attachment.
enum class PixelFormat : std::uint32_t {
    Default = 0,
    None,
    R8,
    R8Sn,
    R8Ui,
    R8Si,
    R16,
    R16Sn,
    R16Ui,
    R16Si,
    R16F,
    Rg8,
    Rg8Sn,
    Rg8Ui,
    Rg8Si,
    R32Ui,
    R32Si,
    R32F,
    Rg16,
    Rg16Sn,
    Rg16Ui,
    Rg16Si,
    Rg16F,
    Rgba8,
    Srgb8A8,
    Rgba8Sn,
    Rgba8Ui,
    Rgba8Si,
    Bgra8,
    Sbgr8A8,
    Rgb10A2,
    Rg11B10F,
    Rgb9E5,
    Rg32Ui,
    Rg32Si,
    Rg32F,
    Rgba16,
    Rgba16Sn,
    Rgba16Ui,
    Rgba16Si,
    Rgba16F,
    Rgba32Ui,
    Rgba32Si,
    Rgba32F,
    Depth,         // 32-bit float depth (or the backend's nearest)
    DepthStencil,  // 24/8 or 32F/8 depth-stencil
    Bc1Rgba,
    Bc2Rgba,
    Bc3Rgba,
    Bc3Srgba,
    Bc4R,
    Bc4RSn,
    Bc5Rg,
    Bc5RgSn,
    Bc6hRgbF,
    Bc6hRgbUf,
    Bc7Rgba,
    Bc7Srgba,
    Etc2Rgb8,
    Etc2Srgb8,
    Etc2Rgb8A1,
    Etc2Rgba8,
    Etc2Srgb8A8,
    EacR11,
    EacR11Sn,
    EacRg11,
    EacRg11Sn,
    Astc4x4Rgba,
    Astc4x4Srgba,
    Count,  // the number of values (not a format)
};

// sg_resource_state: where a resource is in its life. Valid = usable; Failed = its creation failed (the handle is
// alive and must still be destroyed); Invalid = the handle names nothing (never made, destroyed, or another device's).
enum class ResourceState : std::uint32_t { Initial = 0, Alloc, Unsealed, Valid, Failed, Invalid };

// sg_index_type. None = a non-indexed pipeline.
enum class IndexType : std::uint32_t { Default = 0, None, Uint16, Uint32 };

// sg_image_type. Array = a 2D array (numSlices layers); Cube = six faces (numSlices must be 6).
enum class ImageType : std::uint32_t { Default = 0, Tex2d, Cube, Tex3d, Array };

// sg_image_sample_type: what a shader's texture slot samples.
enum class ImageSampleType : std::uint32_t { Default = 0, Float, Depth, Sint, Uint, UnfilterableFloat };

// sg_sampler_type: what a shader's sampler slot is.
enum class SamplerType : std::uint32_t { Default = 0, Filtering, Nonfiltering, Comparison };

// sg_primitive_type.
enum class PrimitiveType : std::uint32_t { Default = 0, Points, Lines, LineStrip, Triangles, TriangleStrip };

// sg_filter (min, mag and mip filters).
enum class Filter : std::uint32_t { Default = 0, Nearest, Linear };

// sg_wrap.
enum class Wrap : std::uint32_t { Default = 0, Repeat, ClampToEdge, ClampToBorder, MirroredRepeat };

// sg_border_color (Wrap::ClampToBorder).
enum class BorderColor : std::uint32_t { Default = 0, TransparentBlack, OpaqueBlack, OpaqueWhite };

// sg_vertex_format. Invalid (0) = the attribute slot is unused.
enum class VertexFormat : std::uint32_t {
    Invalid = 0,
    Float,
    Float2,
    Float3,
    Float4,
    Int,
    Int2,
    Int3,
    Int4,
    Uint,
    Uint2,
    Uint3,
    Uint4,
    Byte4,
    Byte4N,
    Ubyte4,
    Ubyte4N,
    Short2,
    Short2N,
    Ushort2,
    Ushort2N,
    Short4,
    Short4N,
    Ushort4,
    Ushort4N,
    Int10N2,
    Uint10N2,
    Half2,
    Half4,
};

// sg_vertex_step.
enum class VertexStep : std::uint32_t { Default = 0, PerVertex, PerInstance };

// sg_uniform_type: the type of one GL uniform of a uniform block (ShaderGlslUniform).
enum class UniformType : std::uint32_t { Invalid = 0, Float, Float2, Float3, Float4, Int, Int2, Int3, Int4, Mat4 };

// sg_uniform_layout: Native = the shader language's own packing, Std140 = std140 everywhere.
enum class UniformLayout : std::uint32_t { Default = 0, Native, Std140 };

// sg_cull_mode.
enum class CullMode : std::uint32_t { Default = 0, None, Front, Back };

// sg_face_winding: which winding is the front face.
enum class FaceWinding : std::uint32_t { Default = 0, Ccw, Cw };

// sg_compare_func (depth test, stencil test, comparison samplers).
enum class CompareFunc : std::uint32_t {
    Default = 0,
    Never,
    Less,
    Equal,
    LessEqual,
    Greater,
    NotEqual,
    GreaterEqual,
    Always,
};

// sg_stencil_op.
enum class StencilOp : std::uint32_t {
    Default = 0,
    Keep,
    Zero,
    Replace,
    IncrClamp,
    DecrClamp,
    Invert,
    IncrWrap,
    DecrWrap,
};

// sg_blend_factor.
enum class BlendFactor : std::uint32_t {
    Default = 0,
    Zero,
    One,
    SrcColor,
    OneMinusSrcColor,
    SrcAlpha,
    OneMinusSrcAlpha,
    DstColor,
    OneMinusDstColor,
    DstAlpha,
    OneMinusDstAlpha,
    SrcAlphaSaturated,
    BlendColor,
    OneMinusBlendColor,
    BlendAlpha,
    OneMinusBlendAlpha,
    Src1Color,
    OneMinusSrc1Color,
    Src1Alpha,
    OneMinusSrc1Alpha,
};

// sg_blend_op.
enum class BlendOp : std::uint32_t { Default = 0, Add, Subtract, ReverseSubtract, Min, Max };

// sg_color_mask: the channels a colour target writes, as bits (R = 1, G = 2, B = 4, A = 8). Default (0) = all of them;
// None (0x10) = none, since 0 already means the default.
enum class ColorMask : std::uint32_t {
    Default = 0,
    None = 0x10,
    R = 0x1,
    G = 0x2,
    Rg = 0x3,
    B = 0x4,
    Rb = 0x5,
    Gb = 0x6,
    Rgb = 0x7,
    A = 0x8,
    Ra = 0x9,
    Ga = 0xA,
    Rga = 0xB,
    Ba = 0xC,
    Rba = 0xD,
    Gba = 0xE,
    Rgba = 0xF,
};

// sg_load_action: what a pass does with an attachment's old contents. Default = Clear (sokol's default).
enum class LoadAction : std::uint32_t { Default = 0, Clear, Load, DontCare };

// sg_store_action: what a pass does with an attachment's contents at its end. Default = Store for colour, DontCare for
// depth and stencil (sokol's defaults).
enum class StoreAction : std::uint32_t { Default = 0, Store, DontCare };

// sg_shader_stage: which stage a uniform block, view or sampler of a shader belongs to. None = the slot is unused.
enum class ShaderStage : std::uint32_t { None = 0, Vertex, Fragment, Compute };

// sg_shader_attr_base_type: the base type of a vertex attribute as the shader declares it.
enum class ShaderAttrBaseType : std::uint32_t { Undefined = 0, Float, Sint, Uint };

// sg_view_type: what a View is. Fixed when the view is made (by which member of ViewDesc is set).
enum class ViewType : std::uint32_t {
    Invalid = 0,
    StorageBuffer,
    StorageImage,
    Texture,
    ColorAttachment,
    ResolveAttachment,
    DepthStencilAttachment,
};

// sg_pass_state: what a command list is inside.
enum class PassState : std::uint32_t { None = 0, Render, Compute };

// ---------------------------------------------------------------------------------------------------------------------
// What the device can do
// ---------------------------------------------------------------------------------------------------------------------

// What the device does with one pixel format (sg_pixelformat_info): the question behind every "can this GPU render
// to / filter / multisample RGBA16F" of the renderer.
struct PixelFormatCaps {
    bool sample = false;      // a shader can sample it
    bool filter = false;      // ... with linear filtering
    bool render = false;      // it can be a colour (or depth) attachment
    bool blend = false;       // blending works on it as a colour attachment
    bool msaa = false;        // it can be multisampled
    bool depth = false;       // it is a depth format
    bool compressed = false;  // it is a block-compressed format
    bool read = false;        // a compute shader can read it as a storage image
    bool write = false;       // a compute shader can write it as a storage image
    int bytesPerPixel = 0;    // 0 for compressed formats
};

// Optional features of the device (sg_features).
struct Features {
    bool originTopLeft = false;                        // framebuffer y goes down (D3D, Metal, Vulkan)
    bool imageClampToBorder = false;                   // Wrap::ClampToBorder works
    bool mrtIndependentBlendState = false;             // each colour target can blend differently
    bool mrtIndependentWriteMask = false;              // each colour target can have its own ColorMask
    bool compute = false;                              // compute passes and storage buffers / images
    bool msaaTextureBindings = false;                  // a multisampled image can be bound as a texture
    bool separateBufferTypes = false;                  // index and vertex buffers are separate kinds (WebGL2)
    bool drawBaseVertex = false;                       // CommandList::draw_ex's baseVertex works
    bool drawBaseInstance = false;                     // CommandList::draw_ex's baseInstance works
    bool dualSourceBlending = false;                   // the Src1 blend factors work
    bool vertexFormatInt10N2 = false;                  // VertexFormat::Int10N2 works
    bool copyBufferToImageRelaxedBufferType = false;   // any buffer can be the source of copy_buffer_to_image
    bool copyBufferToImageRelaxedBytesPerRow = false;  // copy_buffer_to_image accepts any row pitch
    bool glTextureViews = false;                       // GL: views can name a mip/slice range of an image
};

// Limits of the device (sg_limits).
struct Limits {
    int maxImageSize2d = 0;
    int maxImageSizeCube = 0;
    int maxImageSize3d = 0;
    int maxImageSizeArray = 0;
    int maxImageArrayLayers = 0;
    int maxVertexAttrs = 0;
    int maxColorAttachments = 0;
    int maxTextureBindingsPerStage = 0;
    int maxStorageBufferBindingsPerStage = 0;
    int maxStorageImageBindingsPerStage = 0;
    int glMaxVertexUniformComponents = 0;       // GL only
    int glMaxCombinedTextureImageUnits = 0;     // GL only
    int d3d11MaxUnorderedAccessViews = 0;       // D3D11 only
    int vkMinUniformBufferOffsetAlignment = 0;  // Vulkan only
};

// Who the device is.
struct DeviceInfo {
    Backend backend = Backend::Recording;
    MetalTarget metalTarget = MetalTarget::None;  // Metal: macOS, iOS or the simulator; None elsewhere
    const char* name = "";                        // backend_name(backend): a static string
};

// The name of a backend as the engine's reports use it: "glcore", "gles3", "webgl2", "d3d11", "metal", "d3d12",
// "vulkan", "recording".
const char* backend_name(Backend b);
// The name of a pixel format as the docs and error messages write it ("RGBA16F", "DEPTH_STENCIL"); "?" past Count.
const char* pixel_format_name(PixelFormat f);
// The bytes of one pixel of an uncompressed format (RGBA8 4, RGBA16F 8, DEPTH 4, DEPTH_STENCIL 4); 0 for None,
// Default and the compressed formats. The same on every backend (what a tightly packed upload or readback holds).
int pixel_format_bytes(PixelFormat f);
// True for the block-compressed formats (BC, ETC2, EAC, ASTC).
bool pixel_format_compressed(PixelFormat f);
// True for Depth and DepthStencil.
bool pixel_format_depth(PixelFormat f);

// ---------------------------------------------------------------------------------------------------------------------
// Resource descs
// ---------------------------------------------------------------------------------------------------------------------

// How a buffer is used (sg_buffer_usage). With none of the first four set it is a vertex buffer.
struct BufferUsage {
    bool vertexBuffer = false;
    bool indexBuffer = false;
    bool storageBuffer = false;       // a compute or vertex shader reads (or writes) it through a storage view
    bool stagingBuffer = false;       // only a copy source (written with write_buffer)
    bool stagingIndexBuffer = false;  // a staging buffer for index data (backends with separate buffer types)
    bool writeUnsealed = false;       // written after creation while unsealed (sokol; unused by the engine today)
    bool writeTransient = false;      // rewritten every frame with CommandList::write_buffer
    bool copySrc = false;             // a source of copy_buffer_to_buffer / copy_buffer_to_image
    bool copyDst = false;             // a destination of copy_buffer_to_buffer
};

// A buffer (sg_buffer_desc). `size` 0 = data.size. Without writeTransient/copyDst the buffer is immutable and needs
// `data`.
struct BufferDesc {
    std::size_t size = 0;
    BufferUsage usage{};
    Range data{};            // the initial contents (immutable buffers); read during make_buffer only
    const char* label = "";  // debug label (captures, validation): borrowed for the call
};

// How an image is used (sg_image_usage). With none set it is an immutable texture.
struct ImageUsage {
    bool storageImage = false;            // a compute shader writes (or reads) it through a storage view
    bool colorAttachment = false;         // a pass draws into it
    bool resolveAttachment = false;       // an MSAA pass resolves into it
    bool depthStencilAttachment = false;  // a pass uses it as depth(-stencil)
    bool writeUnsealed = false;           // sokol; unused by the engine today
    bool writeTransient = false;          // rewritten with CommandList::write_image
    bool copySrc = false;
    bool copyDst = false;    // a destination of copy_buffer_to_image
    bool immutable = false;  // explicit immutability (the default when nothing else is set)
};

// The initial contents of an image: one range per mip level, each holding every slice (cube faces, array layers,
// 3D slices) of that level, tightly packed.
struct ImageData {
    Range mipLevels[kMaxMipmaps]{};
};

// An image (sg_image_desc): 2D, cube (numSlices 6), 3D (numSlices = depth) or 2D array (numSlices layers).
struct ImageDesc {
    ImageType type = ImageType::Default;  // Default = Tex2d
    ImageUsage usage{};
    int width = 0;
    int height = 0;
    int numSlices = 0;   // 0 = 1 (6 for a cube); 3D the depth, array the layer count
    int numMipmaps = 0;  // 0 = 1
    // Default = the context's colour format for a colour/resolve attachment, its depth format for a depth attachment,
    // RGBA8 for everything else.
    PixelFormat pixelFormat = PixelFormat::Default;
    // 0 = the context's sample count for an attachment, 1 otherwise; > 1 = multisampled.
    int sampleCount = 0;
    ImageData data{};  // initial contents of an immutable image; read during make_image only
    const char* label = "";
};

// A sampler (sg_sampler_desc).
struct SamplerDesc {
    Filter minFilter = Filter::Default;  // Default = Nearest
    Filter magFilter = Filter::Default;
    Filter mipmapFilter = Filter::Default;
    Wrap wrapU = Wrap::Default;  // Default = Repeat
    Wrap wrapV = Wrap::Default;
    Wrap wrapW = Wrap::Default;
    float minLod = 0.0f;
    float maxLod = 0.0f;                             // 0 = no limit (sokol: FLT_MAX)
    BorderColor borderColor = BorderColor::Default;  // Default = OpaqueBlack
    CompareFunc compare = CompareFunc::Default;      // Default = Never; anything else = a comparison (shadow) sampler
    std::uint32_t maxAnisotropy = 0;                 // 0 = 1 = off
    const char* label = "";
};

// A mip or slice range of a texture view: `count` 0 = every level / slice from `base`.
struct TextureViewRange {
    int base = 0;
    int count = 0;
};

// A view (sg_view_desc). EXACTLY ONE of the members names its resource; which one decides ViewType:
//   texture                -> ViewType::Texture (a shader samples it; mip and slice ranges)
//   storageBuffer          -> ViewType::StorageBuffer (a shader reads/writes a buffer from `offset`)
//   storageImage           -> ViewType::StorageImage (a compute shader writes one mip of one slice)
//   colorAttachment        -> ViewType::ColorAttachment (a pass draws into one mip of one slice)
//   resolveAttachment      -> ViewType::ResolveAttachment (an MSAA pass resolves into it)
//   depthStencilAttachment -> ViewType::DepthStencilAttachment
struct ViewDesc {
    struct TextureView {
        Image image{};
        TextureViewRange mipLevels{};
        TextureViewRange slices{};
    };
    struct BufferView {
        Buffer buffer{};
        int offset = 0;  // bytes (a multiple of 256 for portability)
    };
    struct ImageView {
        Image image{};
        int mipLevel = 0;
        int slice = 0;  // cube face, array layer or 3D slice
    };
    TextureView texture{};
    BufferView storageBuffer{};
    ImageView storageImage{};
    ImageView colorAttachment{};
    ImageView resolveAttachment{};
    ImageView depthStencilAttachment{};
    const char* label = "";

    // The ViewType this desc makes (the first member with a resource), Invalid when none has one.
    ViewType type() const;
    // How many members name a resource: a valid desc has exactly one.
    int resource_count() const;
};

// ---------------------------------------------------------------------------------------------------------------------
// Shaders
// ---------------------------------------------------------------------------------------------------------------------

// Where one binding of a shader sits in each backend's own numbering. The engine binds by the backend-neutral SLOT
// (the index of the uniform block, view or sampler in ShaderDesc, which is what Bindings and set_uniforms use); each
// backend maps the slot to its numbers here. The sokol backends use the numbers sokol-shdc writes (hlsl registers,
// msl indices, wgsl bindings, GL binding points); D3D12 adds a register space and Vulkan a descriptor set, so the
// engine's own backends can lay out root signatures and descriptor sets from the same reflection.
struct BackendBinding {
    std::uint8_t hlslRegister =
        0;                         // D3D11/D3D12: register number (b for uniform blocks, t/u for views, s for samplers)
    std::uint8_t hlslSpace = 0;    // D3D12: register space (space0 for every shader sokol-shdc writes)
    std::uint8_t mslIndex = 0;     // Metal: [[buffer(n)]], [[texture(n)]] or [[sampler(n)]]
    std::uint8_t wgslBinding = 0;  // WebGPU: binding in its group (0 for uniform blocks, 1 for the rest)
    std::uint8_t spirvSet = 0;     // Vulkan: descriptor set (sokol-shdc: 0 for uniform blocks, 1 for the rest)
    std::uint8_t spirvBinding = 0;  // Vulkan: binding in that set
    std::uint8_t glslBinding = 0;   // GL: binding point (storage buffers and storage images)
};

// One stage's code: GLSL/MSL/HLSL `source`, or precompiled `bytecode` (DXBC, metallib, SPIR-V, DXIL), plus its entry.
struct ShaderFunction {
    const char* source = nullptr;
    Range bytecode{};
    const char* entry = nullptr;          // nullptr = "main" (sokol: "main" / "_main")
    const char* d3d11Target = nullptr;    // D3D11 compile target ("vs_5_0"); nullptr = the default
    const char* d3d11Filepath = nullptr;  // D3D11: the file name the compiler reports errors against
};

// One vertex attribute the vertex stage declares (index = its location).
struct ShaderVertexAttr {
    ShaderAttrBaseType baseType = ShaderAttrBaseType::Undefined;
    const char* glslName = nullptr;     // GL: the attribute's name (GL 4.1 without explicit locations)
    const char* hlslSemName = nullptr;  // D3D: the semantic name ("TEXCOORD")
    std::uint8_t hlslSemIndex = 0;      // D3D: the semantic index
};

// One member of a uniform block as GL sees it (GL uploads a block as separate uniforms by name).
struct ShaderGlslUniform {
    UniformType type = UniformType::Invalid;
    std::uint16_t arrayCount = 0;
    const char* glslName = nullptr;
};

// One uniform block slot (index = the slot set_uniforms names). `stage` None = the slot is unused.
struct ShaderUniformBlock {
    ShaderStage stage = ShaderStage::None;
    std::uint32_t size = 0;  // bytes; set_uniforms must pass exactly this many
    UniformLayout layout = UniformLayout::Default;
    BackendBinding binding{};  // hlslRegister = b<n>, mslIndex = buffer(n), spirvSet 0
    ShaderGlslUniform glslUniforms[kMaxUniformBlockMembers]{};
};

// A texture view slot: a View made with ViewDesc::texture binds here.
struct ShaderTextureView {
    ShaderStage stage = ShaderStage::None;
    ImageType imageType = ImageType::Default;
    ImageSampleType sampleType = ImageSampleType::Default;
    bool multisampled = false;
    BackendBinding binding{};  // hlslRegister = t<n>, mslIndex = texture(n), spirvSet 1
};

// A storage buffer view slot: a View made with ViewDesc::storageBuffer binds here.
struct ShaderStorageBufferView {
    ShaderStage stage = ShaderStage::None;
    bool readonly = false;
    BackendBinding binding{};        // hlslRegister = t<n> (readonly), mslIndex = buffer(n), glslBinding, spirvSet 1
    std::uint8_t hlslRegisterU = 0;  // D3D: u<n> when it is written
};

// A storage image view slot: a View made with ViewDesc::storageImage binds here.
struct ShaderStorageImageView {
    ShaderStage stage = ShaderStage::None;
    ImageType imageType = ImageType::Default;
    PixelFormat accessFormat = PixelFormat::Default;  // the format the shader declares
    bool writeonly = false;
    BackendBinding binding{};  // hlslRegister = u<n>, mslIndex = texture(n), glslBinding, spirvSet 1
};

// One view slot of a shader (index = the slot Bindings::views names): at most one of the three has a stage.
struct ShaderView {
    ShaderTextureView texture{};
    ShaderStorageBufferView storageBuffer{};
    ShaderStorageImageView storageImage{};

    // The ViewType a view bound here must have; Invalid when the slot is unused.
    ViewType type() const;
    // The stage of the slot (None when unused).
    ShaderStage stage() const;
};

// One sampler slot (index = the slot Bindings::samplers names).
struct ShaderSampler {
    ShaderStage stage = ShaderStage::None;
    SamplerType samplerType = SamplerType::Default;
    BackendBinding binding{};  // hlslRegister = s<n>, mslIndex = sampler(n), spirvSet 1
};

// Which texture slot is sampled with which sampler slot (GL combines them into one sampler2D named glslName).
struct ShaderTextureSamplerPair {
    ShaderStage stage = ShaderStage::None;
    std::uint8_t viewSlot = 0;
    std::uint8_t samplerSlot = 0;
    const char* glslName = nullptr;
};

// A shader program and its reflection (sg_shader_desc). A render program sets vertexFunc and fragmentFunc, a compute
// program computeFunc. The reflection is what the backends bind by and what RecordingDevice checks Bindings against.
// A desc is per backend (a GLSL program is not an MSL one): the generated shader headers give one per backend.
struct ShaderDesc {
    ShaderFunction vertexFunc{};
    ShaderFunction fragmentFunc{};
    ShaderFunction computeFunc{};
    ShaderVertexAttr attrs[kMaxVertexAttributes]{};
    ShaderUniformBlock uniformBlocks[kMaxUniformBlocks]{};
    ShaderView views[kMaxViews]{};
    ShaderSampler samplers[kMaxSamplers]{};
    ShaderTextureSamplerPair textureSamplerPairs[kMaxTextureSamplerPairs]{};
    int mtlThreadsPerThreadgroup[3]{};  // Metal compute: the threadgroup size (x, y, z)
    const char* label = "";

    bool compute() const { return computeFunc.source != nullptr || computeFunc.bytecode.ptr != nullptr; }
};

// ---------------------------------------------------------------------------------------------------------------------
// Pipelines
// ---------------------------------------------------------------------------------------------------------------------

// One vertex buffer slot of a layout: its stride (0 = computed from the attributes) and step.
struct VertexBufferLayout {
    int stride = 0;
    VertexStep stepFunc = VertexStep::Default;  // Default = PerVertex
    int stepRate = 0;                           // 0 = 1
};

// One vertex attribute of a layout (index = the shader's attribute location).
struct VertexAttr {
    int bufferIndex = 0;  // the vertex buffer slot it reads
    int offset = 0;       // bytes from the start of the vertex (0 with every offset 0 = packed in order)
    VertexFormat format = VertexFormat::Invalid;  // Invalid = unused
};

// The vertex input of a pipeline.
struct VertexLayout {
    VertexBufferLayout buffers[kMaxVertexBuffers]{};
    VertexAttr attrs[kMaxVertexAttributes]{};
};

// Stencil state of one face.
struct StencilFaceState {
    CompareFunc compare = CompareFunc::Default;  // Default = Always
    StencilOp failOp = StencilOp::Default;       // Default = Keep
    StencilOp depthFailOp = StencilOp::Default;
    StencilOp passOp = StencilOp::Default;
};

// Stencil state of a pipeline.
struct StencilState {
    bool enabled = false;
    StencilFaceState front{};
    StencilFaceState back{};
    std::uint8_t readMask = 0;
    std::uint8_t writeMask = 0;
    std::uint8_t ref = 0;
};

// Depth state of a pipeline. `pixelFormat` must equal the depth attachment of every pass it draws in (None = a pass
// without depth; Default = the context's default depth format).
struct DepthState {
    PixelFormat pixelFormat = PixelFormat::Default;
    CompareFunc compare = CompareFunc::Default;  // Default = Always
    bool writeEnabled = false;
    float bias = 0.0f;
    float biasSlopeScale = 0.0f;
    float biasClamp = 0.0f;
};

// Blending of one colour target.
struct BlendState {
    bool enabled = false;
    BlendFactor srcFactorRgb = BlendFactor::Default;  // Default = One
    BlendFactor dstFactorRgb = BlendFactor::Default;  // Default = Zero
    BlendOp opRgb = BlendOp::Default;                 // Default = Add
    BlendFactor srcFactorAlpha = BlendFactor::Default;
    BlendFactor dstFactorAlpha = BlendFactor::Default;
    BlendOp opAlpha = BlendOp::Default;
};

// One colour target of a pipeline: its format must equal the pass's attachment at the same index.
struct ColorTargetState {
    PixelFormat pixelFormat = PixelFormat::Default;  // Default = the context's default colour format
    ColorMask writeMask = ColorMask::Default;        // Default = RGBA
    BlendState blend{};
};

// A pipeline (sg_pipeline_desc): a render pipeline draws in passes whose formats and sample count equal its colour
// targets, depth format and sampleCount; a compute pipeline (`compute`) dispatches in compute passes and ignores the
// render state.
struct PipelineDesc {
    bool compute = false;
    Shader shader{};
    VertexLayout layout{};
    DepthState depth{};
    StencilState stencil{};
    // Colour targets: 0 = 1, or 0 (depth only) when colors[0].pixelFormat is None.
    int colorCount = 0;
    ColorTargetState colors[kMaxColorAttachments]{};
    PrimitiveType primitiveType = PrimitiveType::Default;  // Default = Triangles
    IndexType indexType = IndexType::Default;              // Default = None
    CullMode cullMode = CullMode::Default;                 // Default = None
    FaceWinding faceWinding = FaceWinding::Default;        // Default = Cw
    int sampleCount = 0;                                   // 0 = the context's default
    Color blendColor{};
    bool alphaToCoverageEnabled = false;
    const char* label = "";
};

// ---------------------------------------------------------------------------------------------------------------------
// Draws
// ---------------------------------------------------------------------------------------------------------------------

// The resources of the next draws (sg_bindings): set with CommandList::set_bindings after set_pipeline. Every slot the
// pipeline's shader declares must be bound; nothing may be bound where it declares nothing.
struct Bindings {
    Buffer vertexBuffers[kMaxVertexBuffers]{};
    int vertexBufferOffsets[kMaxVertexBuffers]{};
    Buffer indexBuffer{};
    int indexBufferOffset = 0;
    View views[kMaxViews]{};
    Sampler samplers[kMaxSamplers]{};
};

// ---------------------------------------------------------------------------------------------------------------------
// Uploads and copies
// ---------------------------------------------------------------------------------------------------------------------

// CommandList::write_buffer: `size` bytes from data.ptr + srcOffset into `buffer` at dstOffset (a writeTransient
// buffer). size 0 = data.size - srcOffset.
struct BufferWrite {
    Range data{};
    std::size_t srcOffset = 0;
    Buffer buffer{};
    std::size_t dstOffset = 0;
    std::size_t size = 0;
};

// Where in an image a write or a copy lands.
struct ImageLocation {
    Image image{};
    int mipLevel = 0;
    int x = 0, y = 0, slice = 0;
};

// The size of a region of an image; 0 = the rest of the level from the location.
struct ImageExtent {
    int width = 0;
    int height = 0;
    int numSlices = 0;
};

// CommandList::write_image: pixels from `data` (rows of bytesPerRow, slices of bytesPerSlice; 0 = tightly packed)
// into a region of a writeTransient image.
struct ImageWrite {
    Range data{};
    std::size_t srcOffset = 0;
    int bytesPerRow = 0;
    int bytesPerSlice = 0;
    ImageLocation dst{};
    ImageExtent size{};
};

// CommandList::copy_buffer_to_buffer: `size` bytes, outside a pass.
struct BufferCopy {
    Buffer src{};
    std::size_t srcOffset = 0;
    Buffer dst{};
    std::size_t dstOffset = 0;
    std::size_t size = 0;
};

// CommandList::copy_buffer_to_image: texels from a buffer (rows of bytesPerRow) into an image region, outside a pass.
struct BufferImageCopy {
    Buffer src{};
    std::size_t srcOffset = 0;
    int bytesPerRow = 0;
    int bytesPerSlice = 0;
    ImageLocation dst{};
    ImageExtent size{};
};

// ---------------------------------------------------------------------------------------------------------------------
// Passes
// ---------------------------------------------------------------------------------------------------------------------

// The formats and sample count of the attachments a pass writes, which a pipeline drawn in that pass must match. The
// same fields, order and hash as render::TargetFormat (gpu_types.h), whose sokol enum values these share, so a cache
// keyed by one hashes the same as a cache keyed by the other.
struct TargetFormat {
    PixelFormat color = PixelFormat::None;  // colour attachment 0; None for a depth-only pass
    PixelFormat depth = PixelFormat::None;  // the depth(-stencil) attachment; None without one
    int samples = 1;
    PixelFormat color1 = PixelFormat::None;  // colour attachment 1 (multiple render targets); None for most passes

    bool operator==(const TargetFormat& o) const {
        return color == o.color && color1 == o.color1 && depth == o.depth && samples == o.samples;
    }
    bool operator!=(const TargetFormat& o) const { return !(*this == o); }
    // FNV-1a over the four values, the same on every run.
    std::size_t hash() const {
        std::uint64_t h = 1469598103934665603ull;
        for (std::uint64_t v :
             {std::uint64_t(color), std::uint64_t(color1), std::uint64_t(depth), std::uint64_t(samples)}) {
            h ^= v;
            h *= 1099511628211ull;
        }
        return std::size_t(h);
    }
};

// The default formats of the context (sg_environment_defaults): what Default means for a swapchain pass and a pipeline.
struct EnvironmentDefaults {
    PixelFormat colorFormat = PixelFormat::Default;
    PixelFormat depthFormat = PixelFormat::Default;
    int sampleCount = 0;
};

// The window a device presents into, as the platform layer hands it over (sg_environment): the default formats and the
// native device objects. Only what the backend uses is read.
struct Environment {
    EnvironmentDefaults defaults{};
    const void* metalDevice = nullptr;         // id<MTLDevice>
    const void* d3d11Device = nullptr;         // ID3D11Device*
    const void* d3d11DeviceContext = nullptr;  // ID3D11DeviceContext*
    const void* wgpuDevice = nullptr;          // WGPUDevice (unused: the engine builds no WebGPU backend)
    const void* vulkanInstance = nullptr;      // VkInstance
    const void* vulkanPhysicalDevice = nullptr;
    const void* vulkanDevice = nullptr;
    const void* vulkanQueue = nullptr;
    std::uint32_t vulkanQueueFamilyIndex = 0;
};

// This frame's window surface (sg_swapchain): its size and formats plus the native objects of the backend.
struct Swapchain {
    int width = 0;
    int height = 0;
    int sampleCount = 0;                             // 0 = EnvironmentDefaults::sampleCount
    PixelFormat colorFormat = PixelFormat::Default;  // Default = EnvironmentDefaults::colorFormat
    PixelFormat depthFormat = PixelFormat::Default;  // Default = EnvironmentDefaults::depthFormat
    struct {
        const void* currentDrawable = nullptr;
        const void* depthStencilTexture = nullptr;
        const void* msaaColorTexture = nullptr;
    } metal;
    struct {
        const void* renderView = nullptr;
        const void* resolveView = nullptr;
        const void* depthStencilView = nullptr;
    } d3d11;
    struct {
        const void* renderView = nullptr;
        const void* resolveView = nullptr;
        const void* depthStencilView = nullptr;
    } wgpu;
    struct {
        const void* renderImage = nullptr;
        const void* renderView = nullptr;
        const void* resolveImage = nullptr;
        const void* resolveView = nullptr;
        const void* depthStencilImage = nullptr;
        const void* depthStencilView = nullptr;
        const void* renderFinishedSemaphore = nullptr;
        const void* presentCompleteSemaphore = nullptr;
    } vulkan;
    struct {
        std::uint32_t framebuffer = 0;
    } gl;
};

// One render pass as data: the same fields, meaning and defaults as render::PassDesc (gpu_types.h), with this
// interface's types. A pass draws either into the views below or into a swapchain, never both.
//
// The defaults of the load/store actions are NOT sokol's: a PassDesc says DontCare for what it does not set (a zero
// sg_pass clears), so a pass that forgets a field is cheap rather than clearing. A site that begins a pass sets
// colorLoad, colorStore and, when it has depth or stencil, depthLoad and stencilLoad explicitly.
struct PassDesc {
    const char* label = "";  // debug label: a string literal (captures, validation messages)

    View color{};    // colour attachment 0 (a ColorAttachment view); id 0 for a depth-only pass
    View color1{};   // colour attachment 1 (multiple render targets); id 0 for most passes
    View resolve{};  // MSAA: the ResolveAttachment view `color` resolves into at the end; id 0 when not resolving
    View depth{};    // the DepthStencilAttachment view; id 0 without depth
    const Swapchain* swapchain = nullptr;  // a pass into the window (not owned, valid for begin_pass)

    TargetFormat format{};  // the formats and sample count of the attachments (what its pipelines must match)

    LoadAction colorLoad = LoadAction::DontCare;
    StoreAction colorStore = StoreAction::Store;
    Color clearColor{};
    Color clearColor1{};  // what a Clear of colour attachment 1 fills it with
    LoadAction depthLoad = LoadAction::DontCare;
    float clearDepth = 1.0f;
    LoadAction stencilLoad = LoadAction::DontCare;
    StoreAction depthStore = StoreAction::Default;
    StoreAction stencilStore = StoreAction::Default;

    // A pass into the window: `sc` and the formats it really has (a Default format or sample count 0 of the
    // swapchain takes the context's default). The caller sets the load/store actions.
    static PassDesc for_swapchain(const Swapchain& sc, const EnvironmentDefaults& defaults) {
        PassDesc p;
        p.swapchain = &sc;
        p.format.color = sc.colorFormat != PixelFormat::Default ? sc.colorFormat : defaults.colorFormat;
        p.format.depth = sc.depthFormat != PixelFormat::Default ? sc.depthFormat : defaults.depthFormat;
        p.format.samples = sc.sampleCount > 0 ? sc.sampleCount : (defaults.sampleCount > 0 ? defaults.sampleCount : 1);
        return p;
    }
};

// ---------------------------------------------------------------------------------------------------------------------
// Native objects, statistics
// ---------------------------------------------------------------------------------------------------------------------

// The backend's own device objects, for code that talks to the API directly (readbacks, timer queries, MetalFX,
// Dear ImGui's backends). Null where the backend has none.
struct NativeDevice {
    const void* device = nullptr;        // id<MTLDevice>, ID3D11Device*, ID3D12Device*, VkDevice
    const void* context = nullptr;       // ID3D11DeviceContext* (D3D11); the VkQueue / ID3D12CommandQueue later
    const void* commandQueue = nullptr;  // id<MTLCommandQueue> (Metal)
};

// The backend's own objects of an image (the slot of the frame in flight where the backend keeps several).
struct NativeImage {
    const void* texture = nullptr;   // id<MTLTexture>, ID3D11Texture2D* (or ID3D11Texture3D* for a 3D image)
    const void* resource = nullptr;  // ID3D11Resource* (D3D11)
    std::uint32_t glTexture = 0;     // GL texture name
    std::uint32_t glTarget = 0;      // GL texture target (GL_TEXTURE_2D...)
};

// The backend's own objects of a buffer (the slot of the frame in flight where the backend keeps several).
struct NativeBuffer {
    const void* buffer = nullptr;  // id<MTLBuffer>, ID3D11Buffer*
    std::uint32_t glBuffer = 0;    // GL buffer name
};

// Totals of one resource kind since the device started (sg_total_resource_stats).
struct ResourceTotals {
    std::uint32_t alive = 0;
    std::uint32_t free = 0;
    std::uint32_t allocated = 0;
    std::uint32_t deallocated = 0;
    std::uint32_t inited = 0;
    std::uint32_t uninited = 0;
};

// Totals of every resource kind (Device::total_stats, while stats are enabled).
struct TotalStats {
    ResourceTotals buffers{};
    ResourceTotals images{};
    ResourceTotals samplers{};
    ResourceTotals views{};
    ResourceTotals shaders{};
    ResourceTotals pipelines{};
};

// A pending asynchronous buffer readback (Device::request_buffer_read): `slot` -1 = none.
struct ReadTicket {
    int slot = -1;
    bool valid() const { return slot >= 0; }
};

}  // namespace fa::gpu

template <>
struct std::hash<fa::gpu::TargetFormat> {
    std::size_t operator()(const fa::gpu::TargetFormat& f) const noexcept { return f.hash(); }
};
