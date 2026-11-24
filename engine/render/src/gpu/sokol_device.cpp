// SokolDevice: the GPU interface on sokol_gfx. Every call forwards to the sg_* function of the same meaning; the enums
// and constants of gpu/types.h are sokol's (asserted below), the descs are converted field by field.
#include "gpu/sokol_device.h"

#include <algorithm>
#include <cstdint>
#include <string>
#include <thread>
#include <utility>

#include "fa/platform/sokol_logging.h"
#include "render_internal.h"

namespace fa::gpu {

// ---------------------------------------------------------------------------------------------------------------------
// The values of gpu/types.h are sokol's: a static_cast converts every enum, and the arrays of a desc have sokol's sizes.
// ---------------------------------------------------------------------------------------------------------------------
#define FA_SAME(ours, theirs) static_assert(int(ours) == int(theirs), #ours " must equal " #theirs)

FA_SAME(kMaxColorAttachments, SG_MAX_COLOR_ATTACHMENTS);
FA_SAME(kMaxUniformBlockMembers, SG_MAX_UNIFORMBLOCK_MEMBERS);
FA_SAME(kMaxVertexAttributes, SG_MAX_VERTEX_ATTRIBUTES);
FA_SAME(kMaxMipmaps, SG_MAX_MIPMAPS);
FA_SAME(kMaxVertexBuffers, SG_MAX_VERTEXBUFFER_BINDSLOTS);
FA_SAME(kMaxUniformBlocks, SG_MAX_UNIFORMBLOCK_BINDSLOTS);
FA_SAME(kMaxViews, SG_MAX_VIEW_BINDSLOTS);
FA_SAME(kMaxSamplers, SG_MAX_SAMPLER_BINDSLOTS);
FA_SAME(kMaxTextureSamplerPairs, SG_MAX_TEXTURE_SAMPLER_PAIRS);
FA_SAME(kInflightFrames, SG_NUM_INFLIGHT_FRAMES);
FA_SAME(Buffer{}.id, SG_INVALID_ID);

FA_SAME(PixelFormat::Default, _SG_PIXELFORMAT_DEFAULT);
FA_SAME(PixelFormat::None, SG_PIXELFORMAT_NONE);
FA_SAME(PixelFormat::R8, SG_PIXELFORMAT_R8);
FA_SAME(PixelFormat::R8Sn, SG_PIXELFORMAT_R8SN);
FA_SAME(PixelFormat::R8Ui, SG_PIXELFORMAT_R8UI);
FA_SAME(PixelFormat::R8Si, SG_PIXELFORMAT_R8SI);
FA_SAME(PixelFormat::R16, SG_PIXELFORMAT_R16);
FA_SAME(PixelFormat::R16Sn, SG_PIXELFORMAT_R16SN);
FA_SAME(PixelFormat::R16Ui, SG_PIXELFORMAT_R16UI);
FA_SAME(PixelFormat::R16Si, SG_PIXELFORMAT_R16SI);
FA_SAME(PixelFormat::R16F, SG_PIXELFORMAT_R16F);
FA_SAME(PixelFormat::Rg8, SG_PIXELFORMAT_RG8);
FA_SAME(PixelFormat::Rg8Sn, SG_PIXELFORMAT_RG8SN);
FA_SAME(PixelFormat::Rg8Ui, SG_PIXELFORMAT_RG8UI);
FA_SAME(PixelFormat::Rg8Si, SG_PIXELFORMAT_RG8SI);
FA_SAME(PixelFormat::R32Ui, SG_PIXELFORMAT_R32UI);
FA_SAME(PixelFormat::R32Si, SG_PIXELFORMAT_R32SI);
FA_SAME(PixelFormat::R32F, SG_PIXELFORMAT_R32F);
FA_SAME(PixelFormat::Rg16, SG_PIXELFORMAT_RG16);
FA_SAME(PixelFormat::Rg16Sn, SG_PIXELFORMAT_RG16SN);
FA_SAME(PixelFormat::Rg16Ui, SG_PIXELFORMAT_RG16UI);
FA_SAME(PixelFormat::Rg16Si, SG_PIXELFORMAT_RG16SI);
FA_SAME(PixelFormat::Rg16F, SG_PIXELFORMAT_RG16F);
FA_SAME(PixelFormat::Rgba8, SG_PIXELFORMAT_RGBA8);
FA_SAME(PixelFormat::Srgb8A8, SG_PIXELFORMAT_SRGB8A8);
FA_SAME(PixelFormat::Rgba8Sn, SG_PIXELFORMAT_RGBA8SN);
FA_SAME(PixelFormat::Rgba8Ui, SG_PIXELFORMAT_RGBA8UI);
FA_SAME(PixelFormat::Rgba8Si, SG_PIXELFORMAT_RGBA8SI);
FA_SAME(PixelFormat::Bgra8, SG_PIXELFORMAT_BGRA8);
FA_SAME(PixelFormat::Sbgr8A8, SG_PIXELFORMAT_SBGR8A8);
FA_SAME(PixelFormat::Rgb10A2, SG_PIXELFORMAT_RGB10A2);
FA_SAME(PixelFormat::Rg11B10F, SG_PIXELFORMAT_RG11B10F);
FA_SAME(PixelFormat::Rgb9E5, SG_PIXELFORMAT_RGB9E5);
FA_SAME(PixelFormat::Rg32Ui, SG_PIXELFORMAT_RG32UI);
FA_SAME(PixelFormat::Rg32Si, SG_PIXELFORMAT_RG32SI);
FA_SAME(PixelFormat::Rg32F, SG_PIXELFORMAT_RG32F);
FA_SAME(PixelFormat::Rgba16, SG_PIXELFORMAT_RGBA16);
FA_SAME(PixelFormat::Rgba16Sn, SG_PIXELFORMAT_RGBA16SN);
FA_SAME(PixelFormat::Rgba16Ui, SG_PIXELFORMAT_RGBA16UI);
FA_SAME(PixelFormat::Rgba16Si, SG_PIXELFORMAT_RGBA16SI);
FA_SAME(PixelFormat::Rgba16F, SG_PIXELFORMAT_RGBA16F);
FA_SAME(PixelFormat::Rgba32Ui, SG_PIXELFORMAT_RGBA32UI);
FA_SAME(PixelFormat::Rgba32Si, SG_PIXELFORMAT_RGBA32SI);
FA_SAME(PixelFormat::Rgba32F, SG_PIXELFORMAT_RGBA32F);
FA_SAME(PixelFormat::Depth, SG_PIXELFORMAT_DEPTH);
FA_SAME(PixelFormat::DepthStencil, SG_PIXELFORMAT_DEPTH_STENCIL);
FA_SAME(PixelFormat::Bc1Rgba, SG_PIXELFORMAT_BC1_RGBA);
FA_SAME(PixelFormat::Bc2Rgba, SG_PIXELFORMAT_BC2_RGBA);
FA_SAME(PixelFormat::Bc3Rgba, SG_PIXELFORMAT_BC3_RGBA);
FA_SAME(PixelFormat::Bc3Srgba, SG_PIXELFORMAT_BC3_SRGBA);
FA_SAME(PixelFormat::Bc4R, SG_PIXELFORMAT_BC4_R);
FA_SAME(PixelFormat::Bc4RSn, SG_PIXELFORMAT_BC4_RSN);
FA_SAME(PixelFormat::Bc5Rg, SG_PIXELFORMAT_BC5_RG);
FA_SAME(PixelFormat::Bc5RgSn, SG_PIXELFORMAT_BC5_RGSN);
FA_SAME(PixelFormat::Bc6hRgbF, SG_PIXELFORMAT_BC6H_RGBF);
FA_SAME(PixelFormat::Bc6hRgbUf, SG_PIXELFORMAT_BC6H_RGBUF);
FA_SAME(PixelFormat::Bc7Rgba, SG_PIXELFORMAT_BC7_RGBA);
FA_SAME(PixelFormat::Bc7Srgba, SG_PIXELFORMAT_BC7_SRGBA);
FA_SAME(PixelFormat::Etc2Rgb8, SG_PIXELFORMAT_ETC2_RGB8);
FA_SAME(PixelFormat::Etc2Srgb8, SG_PIXELFORMAT_ETC2_SRGB8);
FA_SAME(PixelFormat::Etc2Rgb8A1, SG_PIXELFORMAT_ETC2_RGB8A1);
FA_SAME(PixelFormat::Etc2Rgba8, SG_PIXELFORMAT_ETC2_RGBA8);
FA_SAME(PixelFormat::Etc2Srgb8A8, SG_PIXELFORMAT_ETC2_SRGB8A8);
FA_SAME(PixelFormat::EacR11, SG_PIXELFORMAT_EAC_R11);
FA_SAME(PixelFormat::EacR11Sn, SG_PIXELFORMAT_EAC_R11SN);
FA_SAME(PixelFormat::EacRg11, SG_PIXELFORMAT_EAC_RG11);
FA_SAME(PixelFormat::EacRg11Sn, SG_PIXELFORMAT_EAC_RG11SN);
FA_SAME(PixelFormat::Astc4x4Rgba, SG_PIXELFORMAT_ASTC_4x4_RGBA);
FA_SAME(PixelFormat::Astc4x4Srgba, SG_PIXELFORMAT_ASTC_4x4_SRGBA);
FA_SAME(PixelFormat::Count, _SG_PIXELFORMAT_NUM);

FA_SAME(ResourceState::Initial, SG_RESOURCESTATE_INITIAL);
FA_SAME(ResourceState::Alloc, SG_RESOURCESTATE_ALLOC);
FA_SAME(ResourceState::Unsealed, SG_RESOURCESTATE_UNSEALED);
FA_SAME(ResourceState::Valid, SG_RESOURCESTATE_VALID);
FA_SAME(ResourceState::Failed, SG_RESOURCESTATE_FAILED);
FA_SAME(ResourceState::Invalid, SG_RESOURCESTATE_INVALID);

FA_SAME(IndexType::Default, _SG_INDEXTYPE_DEFAULT);
FA_SAME(IndexType::None, SG_INDEXTYPE_NONE);
FA_SAME(IndexType::Uint16, SG_INDEXTYPE_UINT16);
FA_SAME(IndexType::Uint32, SG_INDEXTYPE_UINT32);

FA_SAME(ImageType::Default, _SG_IMAGETYPE_DEFAULT);
FA_SAME(ImageType::Tex2d, SG_IMAGETYPE_2D);
FA_SAME(ImageType::Cube, SG_IMAGETYPE_CUBE);
FA_SAME(ImageType::Tex3d, SG_IMAGETYPE_3D);
FA_SAME(ImageType::Array, SG_IMAGETYPE_ARRAY);

FA_SAME(ImageSampleType::Default, _SG_IMAGESAMPLETYPE_DEFAULT);
FA_SAME(ImageSampleType::Float, SG_IMAGESAMPLETYPE_FLOAT);
FA_SAME(ImageSampleType::Depth, SG_IMAGESAMPLETYPE_DEPTH);
FA_SAME(ImageSampleType::Sint, SG_IMAGESAMPLETYPE_SINT);
FA_SAME(ImageSampleType::Uint, SG_IMAGESAMPLETYPE_UINT);
FA_SAME(ImageSampleType::UnfilterableFloat, SG_IMAGESAMPLETYPE_UNFILTERABLE_FLOAT);

FA_SAME(SamplerType::Default, _SG_SAMPLERTYPE_DEFAULT);
FA_SAME(SamplerType::Filtering, SG_SAMPLERTYPE_FILTERING);
FA_SAME(SamplerType::Nonfiltering, SG_SAMPLERTYPE_NONFILTERING);
FA_SAME(SamplerType::Comparison, SG_SAMPLERTYPE_COMPARISON);

FA_SAME(PrimitiveType::Default, _SG_PRIMITIVETYPE_DEFAULT);
FA_SAME(PrimitiveType::Points, SG_PRIMITIVETYPE_POINTS);
FA_SAME(PrimitiveType::Lines, SG_PRIMITIVETYPE_LINES);
FA_SAME(PrimitiveType::LineStrip, SG_PRIMITIVETYPE_LINE_STRIP);
FA_SAME(PrimitiveType::Triangles, SG_PRIMITIVETYPE_TRIANGLES);
FA_SAME(PrimitiveType::TriangleStrip, SG_PRIMITIVETYPE_TRIANGLE_STRIP);

FA_SAME(Filter::Default, _SG_FILTER_DEFAULT);
FA_SAME(Filter::Nearest, SG_FILTER_NEAREST);
FA_SAME(Filter::Linear, SG_FILTER_LINEAR);

FA_SAME(Wrap::Default, _SG_WRAP_DEFAULT);
FA_SAME(Wrap::Repeat, SG_WRAP_REPEAT);
FA_SAME(Wrap::ClampToEdge, SG_WRAP_CLAMP_TO_EDGE);
FA_SAME(Wrap::ClampToBorder, SG_WRAP_CLAMP_TO_BORDER);
FA_SAME(Wrap::MirroredRepeat, SG_WRAP_MIRRORED_REPEAT);

FA_SAME(BorderColor::Default, _SG_BORDERCOLOR_DEFAULT);
FA_SAME(BorderColor::TransparentBlack, SG_BORDERCOLOR_TRANSPARENT_BLACK);
FA_SAME(BorderColor::OpaqueBlack, SG_BORDERCOLOR_OPAQUE_BLACK);
FA_SAME(BorderColor::OpaqueWhite, SG_BORDERCOLOR_OPAQUE_WHITE);

FA_SAME(VertexFormat::Invalid, SG_VERTEXFORMAT_INVALID);
FA_SAME(VertexFormat::Float, SG_VERTEXFORMAT_FLOAT);
FA_SAME(VertexFormat::Float2, SG_VERTEXFORMAT_FLOAT2);
FA_SAME(VertexFormat::Float3, SG_VERTEXFORMAT_FLOAT3);
FA_SAME(VertexFormat::Float4, SG_VERTEXFORMAT_FLOAT4);
FA_SAME(VertexFormat::Int, SG_VERTEXFORMAT_INT);
FA_SAME(VertexFormat::Int2, SG_VERTEXFORMAT_INT2);
FA_SAME(VertexFormat::Int3, SG_VERTEXFORMAT_INT3);
FA_SAME(VertexFormat::Int4, SG_VERTEXFORMAT_INT4);
FA_SAME(VertexFormat::Uint, SG_VERTEXFORMAT_UINT);
FA_SAME(VertexFormat::Uint2, SG_VERTEXFORMAT_UINT2);
FA_SAME(VertexFormat::Uint3, SG_VERTEXFORMAT_UINT3);
FA_SAME(VertexFormat::Uint4, SG_VERTEXFORMAT_UINT4);
FA_SAME(VertexFormat::Byte4, SG_VERTEXFORMAT_BYTE4);
FA_SAME(VertexFormat::Byte4N, SG_VERTEXFORMAT_BYTE4N);
FA_SAME(VertexFormat::Ubyte4, SG_VERTEXFORMAT_UBYTE4);
FA_SAME(VertexFormat::Ubyte4N, SG_VERTEXFORMAT_UBYTE4N);
FA_SAME(VertexFormat::Short2, SG_VERTEXFORMAT_SHORT2);
FA_SAME(VertexFormat::Short2N, SG_VERTEXFORMAT_SHORT2N);
FA_SAME(VertexFormat::Ushort2, SG_VERTEXFORMAT_USHORT2);
FA_SAME(VertexFormat::Ushort2N, SG_VERTEXFORMAT_USHORT2N);
FA_SAME(VertexFormat::Short4, SG_VERTEXFORMAT_SHORT4);
FA_SAME(VertexFormat::Short4N, SG_VERTEXFORMAT_SHORT4N);
FA_SAME(VertexFormat::Ushort4, SG_VERTEXFORMAT_USHORT4);
FA_SAME(VertexFormat::Ushort4N, SG_VERTEXFORMAT_USHORT4N);
FA_SAME(VertexFormat::Int10N2, SG_VERTEXFORMAT_INT10_N2);
FA_SAME(VertexFormat::Uint10N2, SG_VERTEXFORMAT_UINT10_N2);
FA_SAME(VertexFormat::Half2, SG_VERTEXFORMAT_HALF2);
FA_SAME(VertexFormat::Half4, SG_VERTEXFORMAT_HALF4);

FA_SAME(VertexStep::Default, _SG_VERTEXSTEP_DEFAULT);
FA_SAME(VertexStep::PerVertex, SG_VERTEXSTEP_PER_VERTEX);
FA_SAME(VertexStep::PerInstance, SG_VERTEXSTEP_PER_INSTANCE);

FA_SAME(UniformType::Invalid, SG_UNIFORMTYPE_INVALID);
FA_SAME(UniformType::Float, SG_UNIFORMTYPE_FLOAT);
FA_SAME(UniformType::Float2, SG_UNIFORMTYPE_FLOAT2);
FA_SAME(UniformType::Float3, SG_UNIFORMTYPE_FLOAT3);
FA_SAME(UniformType::Float4, SG_UNIFORMTYPE_FLOAT4);
FA_SAME(UniformType::Int, SG_UNIFORMTYPE_INT);
FA_SAME(UniformType::Int2, SG_UNIFORMTYPE_INT2);
FA_SAME(UniformType::Int3, SG_UNIFORMTYPE_INT3);
FA_SAME(UniformType::Int4, SG_UNIFORMTYPE_INT4);
FA_SAME(UniformType::Mat4, SG_UNIFORMTYPE_MAT4);

FA_SAME(UniformLayout::Default, _SG_UNIFORMLAYOUT_DEFAULT);
FA_SAME(UniformLayout::Native, SG_UNIFORMLAYOUT_NATIVE);
FA_SAME(UniformLayout::Std140, SG_UNIFORMLAYOUT_STD140);

FA_SAME(CullMode::Default, _SG_CULLMODE_DEFAULT);
FA_SAME(CullMode::None, SG_CULLMODE_NONE);
FA_SAME(CullMode::Front, SG_CULLMODE_FRONT);
FA_SAME(CullMode::Back, SG_CULLMODE_BACK);

FA_SAME(FaceWinding::Default, _SG_FACEWINDING_DEFAULT);
FA_SAME(FaceWinding::Ccw, SG_FACEWINDING_CCW);
FA_SAME(FaceWinding::Cw, SG_FACEWINDING_CW);

FA_SAME(CompareFunc::Default, _SG_COMPAREFUNC_DEFAULT);
FA_SAME(CompareFunc::Never, SG_COMPAREFUNC_NEVER);
FA_SAME(CompareFunc::Less, SG_COMPAREFUNC_LESS);
FA_SAME(CompareFunc::Equal, SG_COMPAREFUNC_EQUAL);
FA_SAME(CompareFunc::LessEqual, SG_COMPAREFUNC_LESS_EQUAL);
FA_SAME(CompareFunc::Greater, SG_COMPAREFUNC_GREATER);
FA_SAME(CompareFunc::NotEqual, SG_COMPAREFUNC_NOT_EQUAL);
FA_SAME(CompareFunc::GreaterEqual, SG_COMPAREFUNC_GREATER_EQUAL);
FA_SAME(CompareFunc::Always, SG_COMPAREFUNC_ALWAYS);

FA_SAME(StencilOp::Default, _SG_STENCILOP_DEFAULT);
FA_SAME(StencilOp::Keep, SG_STENCILOP_KEEP);
FA_SAME(StencilOp::Zero, SG_STENCILOP_ZERO);
FA_SAME(StencilOp::Replace, SG_STENCILOP_REPLACE);
FA_SAME(StencilOp::IncrClamp, SG_STENCILOP_INCR_CLAMP);
FA_SAME(StencilOp::DecrClamp, SG_STENCILOP_DECR_CLAMP);
FA_SAME(StencilOp::Invert, SG_STENCILOP_INVERT);
FA_SAME(StencilOp::IncrWrap, SG_STENCILOP_INCR_WRAP);
FA_SAME(StencilOp::DecrWrap, SG_STENCILOP_DECR_WRAP);

FA_SAME(BlendFactor::Default, _SG_BLENDFACTOR_DEFAULT);
FA_SAME(BlendFactor::Zero, SG_BLENDFACTOR_ZERO);
FA_SAME(BlendFactor::One, SG_BLENDFACTOR_ONE);
FA_SAME(BlendFactor::SrcColor, SG_BLENDFACTOR_SRC_COLOR);
FA_SAME(BlendFactor::OneMinusSrcColor, SG_BLENDFACTOR_ONE_MINUS_SRC_COLOR);
FA_SAME(BlendFactor::SrcAlpha, SG_BLENDFACTOR_SRC_ALPHA);
FA_SAME(BlendFactor::OneMinusSrcAlpha, SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA);
FA_SAME(BlendFactor::DstColor, SG_BLENDFACTOR_DST_COLOR);
FA_SAME(BlendFactor::OneMinusDstColor, SG_BLENDFACTOR_ONE_MINUS_DST_COLOR);
FA_SAME(BlendFactor::DstAlpha, SG_BLENDFACTOR_DST_ALPHA);
FA_SAME(BlendFactor::OneMinusDstAlpha, SG_BLENDFACTOR_ONE_MINUS_DST_ALPHA);
FA_SAME(BlendFactor::SrcAlphaSaturated, SG_BLENDFACTOR_SRC_ALPHA_SATURATED);
FA_SAME(BlendFactor::BlendColor, SG_BLENDFACTOR_BLEND_COLOR);
FA_SAME(BlendFactor::OneMinusBlendColor, SG_BLENDFACTOR_ONE_MINUS_BLEND_COLOR);
FA_SAME(BlendFactor::BlendAlpha, SG_BLENDFACTOR_BLEND_ALPHA);
FA_SAME(BlendFactor::OneMinusBlendAlpha, SG_BLENDFACTOR_ONE_MINUS_BLEND_ALPHA);
FA_SAME(BlendFactor::Src1Color, SG_BLENDFACTOR_SRC1_COLOR);
FA_SAME(BlendFactor::OneMinusSrc1Color, SG_BLENDFACTOR_ONE_MINUS_SRC1_COLOR);
FA_SAME(BlendFactor::Src1Alpha, SG_BLENDFACTOR_SRC1_ALPHA);
FA_SAME(BlendFactor::OneMinusSrc1Alpha, SG_BLENDFACTOR_ONE_MINUS_SRC1_ALPHA);

FA_SAME(BlendOp::Default, _SG_BLENDOP_DEFAULT);
FA_SAME(BlendOp::Add, SG_BLENDOP_ADD);
FA_SAME(BlendOp::Subtract, SG_BLENDOP_SUBTRACT);
FA_SAME(BlendOp::ReverseSubtract, SG_BLENDOP_REVERSE_SUBTRACT);
FA_SAME(BlendOp::Min, SG_BLENDOP_MIN);
FA_SAME(BlendOp::Max, SG_BLENDOP_MAX);

FA_SAME(ColorMask::Default, _SG_COLORMASK_DEFAULT);
FA_SAME(ColorMask::None, SG_COLORMASK_NONE);
FA_SAME(ColorMask::R, SG_COLORMASK_R);
FA_SAME(ColorMask::G, SG_COLORMASK_G);
FA_SAME(ColorMask::Rg, SG_COLORMASK_RG);
FA_SAME(ColorMask::B, SG_COLORMASK_B);
FA_SAME(ColorMask::Rb, SG_COLORMASK_RB);
FA_SAME(ColorMask::Gb, SG_COLORMASK_GB);
FA_SAME(ColorMask::Rgb, SG_COLORMASK_RGB);
FA_SAME(ColorMask::A, SG_COLORMASK_A);
FA_SAME(ColorMask::Ra, SG_COLORMASK_RA);
FA_SAME(ColorMask::Ga, SG_COLORMASK_GA);
FA_SAME(ColorMask::Rga, SG_COLORMASK_RGA);
FA_SAME(ColorMask::Ba, SG_COLORMASK_BA);
FA_SAME(ColorMask::Rba, SG_COLORMASK_RBA);
FA_SAME(ColorMask::Gba, SG_COLORMASK_GBA);
FA_SAME(ColorMask::Rgba, SG_COLORMASK_RGBA);

FA_SAME(LoadAction::Default, _SG_LOADACTION_DEFAULT);
FA_SAME(LoadAction::Clear, SG_LOADACTION_CLEAR);
FA_SAME(LoadAction::Load, SG_LOADACTION_LOAD);
FA_SAME(LoadAction::DontCare, SG_LOADACTION_DONTCARE);

FA_SAME(StoreAction::Default, _SG_STOREACTION_DEFAULT);
FA_SAME(StoreAction::Store, SG_STOREACTION_STORE);
FA_SAME(StoreAction::DontCare, SG_STOREACTION_DONTCARE);

FA_SAME(ShaderStage::None, SG_SHADERSTAGE_NONE);
FA_SAME(ShaderStage::Vertex, SG_SHADERSTAGE_VERTEX);
FA_SAME(ShaderStage::Fragment, SG_SHADERSTAGE_FRAGMENT);
FA_SAME(ShaderStage::Compute, SG_SHADERSTAGE_COMPUTE);

FA_SAME(ShaderAttrBaseType::Undefined, SG_SHADERATTRBASETYPE_UNDEFINED);
FA_SAME(ShaderAttrBaseType::Float, SG_SHADERATTRBASETYPE_FLOAT);
FA_SAME(ShaderAttrBaseType::Sint, SG_SHADERATTRBASETYPE_SINT);
FA_SAME(ShaderAttrBaseType::Uint, SG_SHADERATTRBASETYPE_UINT);

FA_SAME(ViewType::Invalid, SG_VIEWTYPE_INVALID);
FA_SAME(ViewType::StorageBuffer, SG_VIEWTYPE_STORAGEBUFFER);
FA_SAME(ViewType::StorageImage, SG_VIEWTYPE_STORAGEIMAGE);
FA_SAME(ViewType::Texture, SG_VIEWTYPE_TEXTURE);
FA_SAME(ViewType::ColorAttachment, SG_VIEWTYPE_COLORATTACHMENT);
FA_SAME(ViewType::ResolveAttachment, SG_VIEWTYPE_RESOLVEATTACHMENT);
FA_SAME(ViewType::DepthStencilAttachment, SG_VIEWTYPE_DEPTHSTENCILATTACHMENT);

FA_SAME(PassState::None, SG_PASSSTATE_NONE);
FA_SAME(PassState::Render, SG_PASSSTATE_RENDER);
FA_SAME(PassState::Compute, SG_PASSSTATE_COMPUTE);

#undef FA_SAME

// ---------------------------------------------------------------------------------------------------------------------
// Conversions
// ---------------------------------------------------------------------------------------------------------------------
namespace {

// The overloads below would hide those of sokol_device.h (sokol's types are in the global namespace, so no ADL).
using gpu::from_sg;
using gpu::to_sg;

template <class To, class From>
constexpr To cast(From v) {
    return static_cast<To>(v);
}

// "" -> nullptr: sokol treats a null label as "no label"; an empty string is the interface's default.
const char* label_or_null(const char* s) { return (s && *s) ? s : nullptr; }

sg_image_view_desc to_sg(const ViewDesc::ImageView& v) {
    sg_image_view_desc d{};
    d.image = to_sg(v.image);
    d.mip_level = v.mipLevel;
    d.slice = v.slice;
    return d;
}

sg_blend_state to_sg(const BlendState& b) {
    sg_blend_state s{};
    s.enabled = b.enabled;
    s.src_factor_rgb = cast<sg_blend_factor>(b.srcFactorRgb);
    s.dst_factor_rgb = cast<sg_blend_factor>(b.dstFactorRgb);
    s.op_rgb = cast<sg_blend_op>(b.opRgb);
    s.src_factor_alpha = cast<sg_blend_factor>(b.srcFactorAlpha);
    s.dst_factor_alpha = cast<sg_blend_factor>(b.dstFactorAlpha);
    s.op_alpha = cast<sg_blend_op>(b.opAlpha);
    return s;
}

BlendState from_sg(const sg_blend_state& s) {
    BlendState b;
    b.enabled = s.enabled;
    b.srcFactorRgb = cast<BlendFactor>(s.src_factor_rgb);
    b.dstFactorRgb = cast<BlendFactor>(s.dst_factor_rgb);
    b.opRgb = cast<BlendOp>(s.op_rgb);
    b.srcFactorAlpha = cast<BlendFactor>(s.src_factor_alpha);
    b.dstFactorAlpha = cast<BlendFactor>(s.dst_factor_alpha);
    b.opAlpha = cast<BlendOp>(s.op_alpha);
    return b;
}

sg_stencil_face_state to_sg(const StencilFaceState& f) {
    sg_stencil_face_state s{};
    s.compare = cast<sg_compare_func>(f.compare);
    s.fail_op = cast<sg_stencil_op>(f.failOp);
    s.depth_fail_op = cast<sg_stencil_op>(f.depthFailOp);
    s.pass_op = cast<sg_stencil_op>(f.passOp);
    return s;
}

StencilFaceState from_sg(const sg_stencil_face_state& s) {
    StencilFaceState f;
    f.compare = cast<CompareFunc>(s.compare);
    f.failOp = cast<StencilOp>(s.fail_op);
    f.depthFailOp = cast<StencilOp>(s.depth_fail_op);
    f.passOp = cast<StencilOp>(s.pass_op);
    return f;
}

sg_image_location to_sg(const ImageLocation& l) {
    sg_image_location s{};
    s.image = to_sg(l.image);
    s.mip_level = l.mipLevel;
    s.x = l.x;
    s.y = l.y;
    s.slice = l.slice;
    return s;
}

sg_image_extent to_sg(const ImageExtent& e) {
    sg_image_extent s{};
    s.width = e.width;
    s.height = e.height;
    s.num_slices = e.numSlices;
    return s;
}

}  // namespace

sg_shader_function to_sg(const ShaderFunction& f) {
    sg_shader_function s{};
    s.source = f.source;
    s.bytecode = to_sg(f.bytecode);
    s.entry = f.entry;
    s.d3d11_target = f.d3d11Target;
    s.d3d11_filepath = f.d3d11Filepath;
    return s;
}

ShaderFunction from_sg(const sg_shader_function& s) {
    ShaderFunction f;
    f.source = s.source;
    f.bytecode = from_sg(s.bytecode);
    f.entry = s.entry;
    f.d3d11Target = s.d3d11_target;
    f.d3d11Filepath = s.d3d11_filepath;
    return f;
}

Backend backend_from_sg(sg_backend b) {
    switch (b) {
        case SG_BACKEND_GLCORE: return Backend::Gl;
        case SG_BACKEND_GLES3:
#if defined(__EMSCRIPTEN__)
            return Backend::WebGl2;
#else
            return Backend::Gles3;
#endif
        case SG_BACKEND_D3D11: return Backend::D3d11;
        case SG_BACKEND_METAL_IOS:
        case SG_BACKEND_METAL_MACOS:
        case SG_BACKEND_METAL_SIMULATOR: return Backend::Metal;
        // sokol's WebGPU and Vulkan backends and its dummy are never built by the engine (its Vulkan is its own).
        default: return Backend::Recording;
    }
}

MetalTarget metal_target_from_sg(sg_backend b) {
    switch (b) {
        case SG_BACKEND_METAL_MACOS: return MetalTarget::MacOs;
        case SG_BACKEND_METAL_IOS: return MetalTarget::Ios;
        case SG_BACKEND_METAL_SIMULATOR: return MetalTarget::Simulator;
        default: return MetalTarget::None;
    }
}

Backend built_sokol_backend() {
#if defined(SOKOL_GLCORE)
    return Backend::Gl;
#elif defined(SOKOL_GLES3) && defined(__EMSCRIPTEN__)
    return Backend::WebGl2;
#elif defined(SOKOL_GLES3)
    return Backend::Gles3;
#elif defined(SOKOL_D3D11)
    return Backend::D3d11;
#elif defined(SOKOL_METAL)
    return Backend::Metal;
#else
    return Backend::Recording;
#endif
}

sg_buffer_desc to_sg(const BufferDesc& d) {
    sg_buffer_desc s{};
    s.size = d.size;
    s.usage.vertex_buffer = d.usage.vertexBuffer;
    s.usage.index_buffer = d.usage.indexBuffer;
    s.usage.storage_buffer = d.usage.storageBuffer;
    s.usage.staging_buffer = d.usage.stagingBuffer;
    s.usage.staging_index_buffer = d.usage.stagingIndexBuffer;
    s.usage.write_unsealed = d.usage.writeUnsealed;
    s.usage.write_transient = d.usage.writeTransient;
    s.usage.copy_src = d.usage.copySrc;
    s.usage.copy_dst = d.usage.copyDst;
    s.data = to_sg(d.data);
    s.label = label_or_null(d.label);
    return s;
}

sg_image_desc to_sg(const ImageDesc& d) {
    sg_image_desc s{};
    s.type = cast<sg_image_type>(d.type);
    s.usage.storage_image = d.usage.storageImage;
    s.usage.color_attachment = d.usage.colorAttachment;
    s.usage.resolve_attachment = d.usage.resolveAttachment;
    s.usage.depth_stencil_attachment = d.usage.depthStencilAttachment;
    s.usage.write_unsealed = d.usage.writeUnsealed;
    s.usage.write_transient = d.usage.writeTransient;
    s.usage.copy_src = d.usage.copySrc;
    s.usage.copy_dst = d.usage.copyDst;
    s.usage.immutable = d.usage.immutable;
    s.width = d.width;
    s.height = d.height;
    s.num_slices = d.numSlices;
    s.num_mipmaps = d.numMipmaps;
    s.pixel_format = to_sg(d.pixelFormat);
    s.sample_count = d.sampleCount;
    for (int i = 0; i < kMaxMipmaps; ++i) s.data.mip_levels[i] = to_sg(d.data.mipLevels[i]);
    s.label = label_or_null(d.label);
    return s;
}

sg_view_desc to_sg(const ViewDesc& d) {
    sg_view_desc s{};
    s.texture.image = to_sg(d.texture.image);
    s.texture.mip_levels.base = d.texture.mipLevels.base;
    s.texture.mip_levels.count = d.texture.mipLevels.count;
    s.texture.slices.base = d.texture.slices.base;
    s.texture.slices.count = d.texture.slices.count;
    s.storage_buffer.buffer = to_sg(d.storageBuffer.buffer);
    s.storage_buffer.offset = d.storageBuffer.offset;
    s.storage_image = to_sg(d.storageImage);
    s.color_attachment = to_sg(d.colorAttachment);
    s.resolve_attachment = to_sg(d.resolveAttachment);
    s.depth_stencil_attachment = to_sg(d.depthStencilAttachment);
    s.label = label_or_null(d.label);
    return s;
}

sg_sampler_desc to_sg(const SamplerDesc& d) {
    sg_sampler_desc s{};
    s.min_filter = cast<sg_filter>(d.minFilter);
    s.mag_filter = cast<sg_filter>(d.magFilter);
    s.mipmap_filter = cast<sg_filter>(d.mipmapFilter);
    s.wrap_u = cast<sg_wrap>(d.wrapU);
    s.wrap_v = cast<sg_wrap>(d.wrapV);
    s.wrap_w = cast<sg_wrap>(d.wrapW);
    s.min_lod = d.minLod;
    s.max_lod = d.maxLod;  // 0 = sokol's default, FLT_MAX
    s.border_color = cast<sg_border_color>(d.borderColor);
    s.compare = cast<sg_compare_func>(d.compare);
    s.max_anisotropy = d.maxAnisotropy;
    s.label = label_or_null(d.label);
    return s;
}

sg_shader_desc to_sg(const ShaderDesc& d) {
    sg_shader_desc s{};
    s.vertex_func = to_sg(d.vertexFunc);
    s.fragment_func = to_sg(d.fragmentFunc);
    s.compute_func = to_sg(d.computeFunc);
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        const ShaderVertexAttr& a = d.attrs[i];
        s.attrs[i].base_type = cast<sg_shader_attr_base_type>(a.baseType);
        s.attrs[i].glsl_name = a.glslName;
        s.attrs[i].hlsl_sem_name = a.hlslSemName;
        s.attrs[i].hlsl_sem_index = a.hlslSemIndex;
    }
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        const ShaderUniformBlock& u = d.uniformBlocks[i];
        sg_shader_uniform_block& o = s.uniform_blocks[i];
        o.stage = cast<sg_shader_stage>(u.stage);
        o.size = u.size;
        o.hlsl_register_b_n = u.binding.hlslRegister;
        o.msl_buffer_n = u.binding.mslIndex;
        o.wgsl_group0_binding_n = u.binding.wgslBinding;
        o.spirv_set0_binding_n = u.binding.spirvBinding;
        o.layout = cast<sg_uniform_layout>(u.layout);
        for (int m = 0; m < kMaxUniformBlockMembers; ++m) {
            o.glsl_uniforms[m].type = cast<sg_uniform_type>(u.glslUniforms[m].type);
            o.glsl_uniforms[m].array_count = u.glslUniforms[m].arrayCount;
            o.glsl_uniforms[m].glsl_name = u.glslUniforms[m].glslName;
        }
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const ShaderView& v = d.views[i];
        sg_shader_view& o = s.views[i];
        o.texture.stage = cast<sg_shader_stage>(v.texture.stage);
        o.texture.image_type = cast<sg_image_type>(v.texture.imageType);
        o.texture.sample_type = cast<sg_image_sample_type>(v.texture.sampleType);
        o.texture.multisampled = v.texture.multisampled;
        o.texture.hlsl_register_t_n = v.texture.binding.hlslRegister;
        o.texture.msl_texture_n = v.texture.binding.mslIndex;
        o.texture.wgsl_group1_binding_n = v.texture.binding.wgslBinding;
        o.texture.spirv_set1_binding_n = v.texture.binding.spirvBinding;
        o.storage_buffer.stage = cast<sg_shader_stage>(v.storageBuffer.stage);
        o.storage_buffer.readonly = v.storageBuffer.readonly;
        o.storage_buffer.hlsl_register_t_n = v.storageBuffer.binding.hlslRegister;
        o.storage_buffer.hlsl_register_u_n = v.storageBuffer.hlslRegisterU;
        o.storage_buffer.msl_buffer_n = v.storageBuffer.binding.mslIndex;
        o.storage_buffer.wgsl_group1_binding_n = v.storageBuffer.binding.wgslBinding;
        o.storage_buffer.spirv_set1_binding_n = v.storageBuffer.binding.spirvBinding;
        o.storage_buffer.glsl_binding_n = v.storageBuffer.binding.glslBinding;
        o.storage_image.stage = cast<sg_shader_stage>(v.storageImage.stage);
        o.storage_image.image_type = cast<sg_image_type>(v.storageImage.imageType);
        o.storage_image.access_format = to_sg(v.storageImage.accessFormat);
        o.storage_image.writeonly = v.storageImage.writeonly;
        o.storage_image.hlsl_register_u_n = v.storageImage.binding.hlslRegister;
        o.storage_image.msl_texture_n = v.storageImage.binding.mslIndex;
        o.storage_image.wgsl_group1_binding_n = v.storageImage.binding.wgslBinding;
        o.storage_image.spirv_set1_binding_n = v.storageImage.binding.spirvBinding;
        o.storage_image.glsl_binding_n = v.storageImage.binding.glslBinding;
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& m = d.samplers[i];
        sg_shader_sampler& o = s.samplers[i];
        o.stage = cast<sg_shader_stage>(m.stage);
        o.sampler_type = cast<sg_sampler_type>(m.samplerType);
        o.hlsl_register_s_n = m.binding.hlslRegister;
        o.msl_sampler_n = m.binding.mslIndex;
        o.wgsl_group1_binding_n = m.binding.wgslBinding;
        o.spirv_set1_binding_n = m.binding.spirvBinding;
    }
    for (int i = 0; i < kMaxTextureSamplerPairs; ++i) {
        const ShaderTextureSamplerPair& p = d.textureSamplerPairs[i];
        sg_shader_texture_sampler_pair& o = s.texture_sampler_pairs[i];
        o.stage = cast<sg_shader_stage>(p.stage);
        o.view_slot = p.viewSlot;
        o.sampler_slot = p.samplerSlot;
        o.glsl_name = p.glslName;
    }
    s.mtl_threads_per_threadgroup.x = d.mtlThreadsPerThreadgroup[0];
    s.mtl_threads_per_threadgroup.y = d.mtlThreadsPerThreadgroup[1];
    s.mtl_threads_per_threadgroup.z = d.mtlThreadsPerThreadgroup[2];
    s.label = label_or_null(d.label);
    return s;
}

ShaderDesc from_sg(const sg_shader_desc& s) {
    ShaderDesc d;
    d.vertexFunc = from_sg(s.vertex_func);
    d.fragmentFunc = from_sg(s.fragment_func);
    d.computeFunc = from_sg(s.compute_func);
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        d.attrs[i].baseType = cast<ShaderAttrBaseType>(s.attrs[i].base_type);
        d.attrs[i].glslName = s.attrs[i].glsl_name;
        d.attrs[i].hlslSemName = s.attrs[i].hlsl_sem_name;
        d.attrs[i].hlslSemIndex = s.attrs[i].hlsl_sem_index;
    }
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        const sg_shader_uniform_block& u = s.uniform_blocks[i];
        ShaderUniformBlock& o = d.uniformBlocks[i];
        o.stage = cast<ShaderStage>(u.stage);
        o.size = u.size;
        o.layout = cast<UniformLayout>(u.layout);
        o.binding.hlslRegister = u.hlsl_register_b_n;
        o.binding.mslIndex = u.msl_buffer_n;
        o.binding.wgslBinding = u.wgsl_group0_binding_n;
        o.binding.spirvSet = 0;
        o.binding.spirvBinding = u.spirv_set0_binding_n;
        for (int m = 0; m < kMaxUniformBlockMembers; ++m) {
            o.glslUniforms[m].type = cast<UniformType>(u.glsl_uniforms[m].type);
            o.glslUniforms[m].arrayCount = u.glsl_uniforms[m].array_count;
            o.glslUniforms[m].glslName = u.glsl_uniforms[m].glsl_name;
        }
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const sg_shader_view& v = s.views[i];
        ShaderView& o = d.views[i];
        o.texture.stage = cast<ShaderStage>(v.texture.stage);
        o.texture.imageType = cast<ImageType>(v.texture.image_type);
        o.texture.sampleType = cast<ImageSampleType>(v.texture.sample_type);
        o.texture.multisampled = v.texture.multisampled;
        o.texture.binding.hlslRegister = v.texture.hlsl_register_t_n;
        o.texture.binding.mslIndex = v.texture.msl_texture_n;
        o.texture.binding.wgslBinding = v.texture.wgsl_group1_binding_n;
        o.texture.binding.spirvSet = 1;
        o.texture.binding.spirvBinding = v.texture.spirv_set1_binding_n;
        o.storageBuffer.stage = cast<ShaderStage>(v.storage_buffer.stage);
        o.storageBuffer.readonly = v.storage_buffer.readonly;
        o.storageBuffer.binding.hlslRegister = v.storage_buffer.hlsl_register_t_n;
        o.storageBuffer.hlslRegisterU = v.storage_buffer.hlsl_register_u_n;
        o.storageBuffer.binding.mslIndex = v.storage_buffer.msl_buffer_n;
        o.storageBuffer.binding.wgslBinding = v.storage_buffer.wgsl_group1_binding_n;
        o.storageBuffer.binding.spirvSet = 1;
        o.storageBuffer.binding.spirvBinding = v.storage_buffer.spirv_set1_binding_n;
        o.storageBuffer.binding.glslBinding = v.storage_buffer.glsl_binding_n;
        o.storageImage.stage = cast<ShaderStage>(v.storage_image.stage);
        o.storageImage.imageType = cast<ImageType>(v.storage_image.image_type);
        o.storageImage.accessFormat = from_sg(v.storage_image.access_format);
        o.storageImage.writeonly = v.storage_image.writeonly;
        o.storageImage.binding.hlslRegister = v.storage_image.hlsl_register_u_n;
        o.storageImage.binding.mslIndex = v.storage_image.msl_texture_n;
        o.storageImage.binding.wgslBinding = v.storage_image.wgsl_group1_binding_n;
        o.storageImage.binding.spirvSet = 1;
        o.storageImage.binding.spirvBinding = v.storage_image.spirv_set1_binding_n;
        o.storageImage.binding.glslBinding = v.storage_image.glsl_binding_n;
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const sg_shader_sampler& m = s.samplers[i];
        ShaderSampler& o = d.samplers[i];
        o.stage = cast<ShaderStage>(m.stage);
        o.samplerType = cast<SamplerType>(m.sampler_type);
        o.binding.hlslRegister = m.hlsl_register_s_n;
        o.binding.mslIndex = m.msl_sampler_n;
        o.binding.wgslBinding = m.wgsl_group1_binding_n;
        o.binding.spirvSet = 1;
        o.binding.spirvBinding = m.spirv_set1_binding_n;
    }
    for (int i = 0; i < kMaxTextureSamplerPairs; ++i) {
        const sg_shader_texture_sampler_pair& p = s.texture_sampler_pairs[i];
        ShaderTextureSamplerPair& o = d.textureSamplerPairs[i];
        o.stage = cast<ShaderStage>(p.stage);
        o.viewSlot = p.view_slot;
        o.samplerSlot = p.sampler_slot;
        o.glslName = p.glsl_name;
    }
    d.mtlThreadsPerThreadgroup[0] = s.mtl_threads_per_threadgroup.x;
    d.mtlThreadsPerThreadgroup[1] = s.mtl_threads_per_threadgroup.y;
    d.mtlThreadsPerThreadgroup[2] = s.mtl_threads_per_threadgroup.z;
    d.label = s.label ? s.label : "";
    return d;
}

sg_pipeline_desc to_sg(const PipelineDesc& d) {
    sg_pipeline_desc s{};
    s.compute = d.compute;
    s.shader = to_sg(d.shader);
    for (int i = 0; i < kMaxVertexBuffers; ++i) {
        s.layout.buffers[i].stride = d.layout.buffers[i].stride;
        s.layout.buffers[i].step_func = cast<sg_vertex_step>(d.layout.buffers[i].stepFunc);
        s.layout.buffers[i].step_rate = d.layout.buffers[i].stepRate;
    }
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        s.layout.attrs[i].buffer_index = d.layout.attrs[i].bufferIndex;
        s.layout.attrs[i].offset = d.layout.attrs[i].offset;
        s.layout.attrs[i].format = cast<sg_vertex_format>(d.layout.attrs[i].format);
    }
    s.depth.pixel_format = to_sg(d.depth.pixelFormat);
    s.depth.compare = cast<sg_compare_func>(d.depth.compare);
    s.depth.write_enabled = d.depth.writeEnabled;
    s.depth.bias = d.depth.bias;
    s.depth.bias_slope_scale = d.depth.biasSlopeScale;
    s.depth.bias_clamp = d.depth.biasClamp;
    s.stencil.enabled = d.stencil.enabled;
    s.stencil.front = to_sg(d.stencil.front);
    s.stencil.back = to_sg(d.stencil.back);
    s.stencil.read_mask = d.stencil.readMask;
    s.stencil.write_mask = d.stencil.writeMask;
    s.stencil.ref = d.stencil.ref;
    s.color_count = d.colorCount;
    for (int i = 0; i < kMaxColorAttachments; ++i) {
        s.colors[i].pixel_format = to_sg(d.colors[i].pixelFormat);
        s.colors[i].write_mask = cast<sg_color_mask>(d.colors[i].writeMask);
        s.colors[i].blend = to_sg(d.colors[i].blend);
    }
    s.primitive_type = cast<sg_primitive_type>(d.primitiveType);
    s.index_type = cast<sg_index_type>(d.indexType);
    s.cull_mode = cast<sg_cull_mode>(d.cullMode);
    s.face_winding = cast<sg_face_winding>(d.faceWinding);
    s.sample_count = d.sampleCount;
    s.blend_color = to_sg(d.blendColor);
    s.alpha_to_coverage_enabled = d.alphaToCoverageEnabled;
    s.label = label_or_null(d.label);
    return s;
}

VertexLayout from_sg(const sg_vertex_layout_state& s) {
    VertexLayout l;
    for (int i = 0; i < kMaxVertexBuffers; ++i) {
        l.buffers[i].stride = s.buffers[i].stride;
        l.buffers[i].stepFunc = cast<VertexStep>(s.buffers[i].step_func);
        l.buffers[i].stepRate = s.buffers[i].step_rate;
    }
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        l.attrs[i].bufferIndex = s.attrs[i].buffer_index;
        l.attrs[i].offset = s.attrs[i].offset;
        l.attrs[i].format = cast<VertexFormat>(s.attrs[i].format);
    }
    return l;
}

PipelineDesc from_sg(const sg_pipeline_desc& s) {
    PipelineDesc d;
    d.compute = s.compute;
    d.shader = from_sg(s.shader);
    d.layout = from_sg(s.layout);
    d.depth.pixelFormat = from_sg(s.depth.pixel_format);
    d.depth.compare = cast<CompareFunc>(s.depth.compare);
    d.depth.writeEnabled = s.depth.write_enabled;
    d.depth.bias = s.depth.bias;
    d.depth.biasSlopeScale = s.depth.bias_slope_scale;
    d.depth.biasClamp = s.depth.bias_clamp;
    d.stencil.enabled = s.stencil.enabled;
    d.stencil.front = from_sg(s.stencil.front);
    d.stencil.back = from_sg(s.stencil.back);
    d.stencil.readMask = s.stencil.read_mask;
    d.stencil.writeMask = s.stencil.write_mask;
    d.stencil.ref = s.stencil.ref;
    d.colorCount = s.color_count;
    for (int i = 0; i < kMaxColorAttachments; ++i) {
        d.colors[i].pixelFormat = from_sg(s.colors[i].pixel_format);
        d.colors[i].writeMask = cast<ColorMask>(s.colors[i].write_mask);
        d.colors[i].blend = from_sg(s.colors[i].blend);
    }
    d.primitiveType = cast<PrimitiveType>(s.primitive_type);
    d.indexType = cast<IndexType>(s.index_type);
    d.cullMode = cast<CullMode>(s.cull_mode);
    d.faceWinding = cast<FaceWinding>(s.face_winding);
    d.sampleCount = s.sample_count;
    d.blendColor = from_sg(s.blend_color);
    d.alphaToCoverageEnabled = s.alpha_to_coverage_enabled;
    d.label = s.label ? s.label : "";
    return d;
}

sg_bindings to_sg(const Bindings& b) {
    sg_bindings s{};
    for (int i = 0; i < kMaxVertexBuffers; ++i) {
        s.vertex_buffers[i] = to_sg(b.vertexBuffers[i]);
        s.vertex_buffer_offsets[i] = b.vertexBufferOffsets[i];
    }
    s.index_buffer = to_sg(b.indexBuffer);
    s.index_buffer_offset = b.indexBufferOffset;
    for (int i = 0; i < kMaxViews; ++i) s.views[i] = to_sg(b.views[i]);
    for (int i = 0; i < kMaxSamplers; ++i) s.samplers[i] = to_sg(b.samplers[i]);
    return s;
}

sg_swapchain to_sg(const Swapchain& c) {
    sg_swapchain s{};
    s.width = c.width;
    s.height = c.height;
    s.sample_count = c.sampleCount;
    s.color_format = to_sg(c.colorFormat);
    s.depth_format = to_sg(c.depthFormat);
    s.metal.current_drawable = c.metal.currentDrawable;
    s.metal.depth_stencil_texture = c.metal.depthStencilTexture;
    s.metal.msaa_color_texture = c.metal.msaaColorTexture;
    s.d3d11.render_view = c.d3d11.renderView;
    s.d3d11.resolve_view = c.d3d11.resolveView;
    s.d3d11.depth_stencil_view = c.d3d11.depthStencilView;
    s.wgpu.render_view = c.wgpu.renderView;
    s.wgpu.resolve_view = c.wgpu.resolveView;
    s.wgpu.depth_stencil_view = c.wgpu.depthStencilView;
    s.vulkan.render_image = c.vulkan.renderImage;
    s.vulkan.render_view = c.vulkan.renderView;
    s.vulkan.resolve_image = c.vulkan.resolveImage;
    s.vulkan.resolve_view = c.vulkan.resolveView;
    s.vulkan.depth_stencil_image = c.vulkan.depthStencilImage;
    s.vulkan.depth_stencil_view = c.vulkan.depthStencilView;
    s.vulkan.render_finished_semaphore = c.vulkan.renderFinishedSemaphore;
    s.vulkan.present_complete_semaphore = c.vulkan.presentCompleteSemaphore;
    s.gl.framebuffer = c.gl.framebuffer;
    return s;
}

Swapchain from_sg(const sg_swapchain& s) {
    Swapchain c;
    c.width = s.width;
    c.height = s.height;
    c.sampleCount = s.sample_count;
    c.colorFormat = from_sg(s.color_format);
    c.depthFormat = from_sg(s.depth_format);
    c.metal.currentDrawable = s.metal.current_drawable;
    c.metal.depthStencilTexture = s.metal.depth_stencil_texture;
    c.metal.msaaColorTexture = s.metal.msaa_color_texture;
    c.d3d11.renderView = s.d3d11.render_view;
    c.d3d11.resolveView = s.d3d11.resolve_view;
    c.d3d11.depthStencilView = s.d3d11.depth_stencil_view;
    c.wgpu.renderView = s.wgpu.render_view;
    c.wgpu.resolveView = s.wgpu.resolve_view;
    c.wgpu.depthStencilView = s.wgpu.depth_stencil_view;
    c.vulkan.renderImage = s.vulkan.render_image;
    c.vulkan.renderView = s.vulkan.render_view;
    c.vulkan.resolveImage = s.vulkan.resolve_image;
    c.vulkan.resolveView = s.vulkan.resolve_view;
    c.vulkan.depthStencilImage = s.vulkan.depth_stencil_image;
    c.vulkan.depthStencilView = s.vulkan.depth_stencil_view;
    c.vulkan.renderFinishedSemaphore = s.vulkan.render_finished_semaphore;
    c.vulkan.presentCompleteSemaphore = s.vulkan.present_complete_semaphore;
    c.gl.framebuffer = s.gl.framebuffer;
    return c;
}

sg_environment to_sg(const Environment& e) {
    sg_environment s{};
    s.defaults.color_format = to_sg(e.defaults.colorFormat);
    s.defaults.depth_format = to_sg(e.defaults.depthFormat);
    s.defaults.sample_count = e.defaults.sampleCount;
    s.metal.device = e.metalDevice;
    s.d3d11.device = e.d3d11Device;
    s.d3d11.device_context = e.d3d11DeviceContext;
    s.wgpu.device = e.wgpuDevice;
    s.vulkan.instance = e.vulkanInstance;
    s.vulkan.physical_device = e.vulkanPhysicalDevice;
    s.vulkan.device = e.vulkanDevice;
    s.vulkan.queue = e.vulkanQueue;
    s.vulkan.queue_family_index = e.vulkanQueueFamilyIndex;
    return s;
}

// The sokol pass of a PassDesc: how a pass reaches sg_begin_pass.
sg_pass to_sg(const PassDesc& p) {
    sg_pass s{};
    s.action.colors[0].load_action = to_sg(p.colorLoad);
    s.action.colors[0].store_action = to_sg(p.colorStore);
    s.action.colors[0].clear_value = to_sg(p.clearColor);
    if (p.color1.id) {
        s.action.colors[1].load_action = to_sg(p.colorLoad);
        s.action.colors[1].store_action = to_sg(p.colorStore);
        s.action.colors[1].clear_value = to_sg(p.clearColor1);
    }
    s.action.depth.load_action = to_sg(p.depthLoad);
    s.action.depth.clear_value = p.clearDepth;
    s.action.depth.store_action = to_sg(p.depthStore);
    s.action.stencil.store_action = to_sg(p.stencilStore);
    s.action.stencil.load_action = to_sg(p.stencilLoad);
    if (p.swapchain) {
        s.swapchain = to_sg(*p.swapchain);
    } else {
        s.attachments.colors[0] = to_sg(p.color);
        s.attachments.colors[1] = to_sg(p.color1);
        s.attachments.resolves[0] = to_sg(p.resolve);
        s.attachments.depth_stencil = to_sg(p.depth);
    }
    s.label = p.label;
    return s;
}

EnvironmentDefaults from_sg(const sg_environment_defaults& d) {
    EnvironmentDefaults e;
    e.colorFormat = from_sg(d.color_format);
    e.depthFormat = from_sg(d.depth_format);
    e.sampleCount = d.sample_count;
    return e;
}

PixelFormatCaps from_sg(const sg_pixelformat_info& i) {
    PixelFormatCaps c;
    c.sample = i.sample;
    c.filter = i.filter;
    c.render = i.render;
    c.blend = i.blend;
    c.msaa = i.msaa;
    c.depth = i.depth;
    c.compressed = i.compressed;
    c.read = i.read;
    c.write = i.write;
    c.bytesPerPixel = i.bytes_per_pixel;
    return c;
}

Features from_sg(const sg_features& f) {
    Features o;
    o.originTopLeft = f.origin_top_left;
    o.imageClampToBorder = f.image_clamp_to_border;
    o.mrtIndependentBlendState = f.mrt_independent_blend_state;
    o.mrtIndependentWriteMask = f.mrt_independent_write_mask;
    o.compute = f.compute;
    o.msaaTextureBindings = f.msaa_texture_bindings;
    o.separateBufferTypes = f.separate_buffer_types;
    o.drawBaseVertex = f.draw_base_vertex;
    o.drawBaseInstance = f.draw_base_instance;
    o.dualSourceBlending = f.dual_source_blending;
    o.vertexFormatInt10N2 = f.vertexformat_int10_n2;
    o.copyBufferToImageRelaxedBufferType = f.copy_buffer_to_image_relaxed_buffer_type;
    o.copyBufferToImageRelaxedBytesPerRow = f.copy_buffer_to_image_relaxed_bytes_per_row;
    o.glTextureViews = f.gl_texture_views;
    return o;
}

Limits from_sg(const sg_limits& l) {
    Limits o;
    o.maxImageSize2d = l.max_image_size_2d;
    o.maxImageSizeCube = l.max_image_size_cube;
    o.maxImageSize3d = l.max_image_size_3d;
    o.maxImageSizeArray = l.max_image_size_array;
    o.maxImageArrayLayers = l.max_image_array_layers;
    o.maxVertexAttrs = l.max_vertex_attrs;
    o.maxColorAttachments = l.max_color_attachments;
    o.maxTextureBindingsPerStage = l.max_texture_bindings_per_stage;
    o.maxStorageBufferBindingsPerStage = l.max_storage_buffer_bindings_per_stage;
    o.maxStorageImageBindingsPerStage = l.max_storage_image_bindings_per_stage;
    o.glMaxVertexUniformComponents = l.gl_max_vertex_uniform_components;
    o.glMaxCombinedTextureImageUnits = l.gl_max_combined_texture_image_units;
    o.d3d11MaxUnorderedAccessViews = l.d3d11_max_unordered_access_views;
    o.vkMinUniformBufferOffsetAlignment = l.vk_min_uniform_buffer_offset_alignment;
    return o;
}

ResourceTotals from_sg(const sg_total_resource_stats& t) {
    ResourceTotals o;
    o.alive = t.alive;
    o.free = t.free;
    o.allocated = t.allocated;
    o.deallocated = t.deallocated;
    o.inited = t.inited;
    o.uninited = t.uninited;
    return o;
}

PassDesc swapchain_pass(const Swapchain& sc) {
    EnvironmentDefaults d{};
    if (sg_isvalid()) d = from_sg(sg_query_desc().environment.defaults);
    return PassDesc::for_swapchain(sc, d);
}

ShaderDesc generated_shader_desc(GeneratedShader fn) {
    FA_ASSERT(fn, "gpu::generated_shader_desc: no desc function");
    const sg_shader_desc* d = fn(sg_query_backend());
    FA_ASSERT(d, "gpu::generated_shader_desc: the generated header has no desc for this backend");
    return from_sg(*d);
}

void begin_context_pass(const PassDesc& pass) {
    const sg_pass p = to_sg(pass);
    sg_begin_pass(&p);
}

void begin_context_compute_pass(const char* label) {
    sg_pass p{};
    p.compute = true;
    p.label = label_or_null(label);
    sg_begin_pass(&p);
}

void end_context_pass() { sg_end_pass(); }

// ---------------------------------------------------------------------------------------------------------------------
// SokolCommandList: every call runs at once.
// ---------------------------------------------------------------------------------------------------------------------
void SokolCommandList::begin_pass(const PassDesc& pass) {
    device_.check_thread("CommandList::begin_pass");
    const sg_pass p = to_sg(pass);
    sg_begin_pass(&p);
}

void SokolCommandList::begin_compute_pass(const char* label) {
    device_.check_thread("CommandList::begin_compute_pass");
    sg_pass p{};
    p.compute = true;
    p.label = label_or_null(label);
    sg_begin_pass(&p);
}

void SokolCommandList::end_pass() {
    device_.check_thread("CommandList::end_pass");
    sg_end_pass();
}

PassState SokolCommandList::pass_state() const {
    device_.check_thread("CommandList::pass_state");
    return from_sg(sg_query_pass_state());
}

void SokolCommandList::set_pipeline(Pipeline pipeline) {
    device_.check_thread("CommandList::set_pipeline");
    sg_apply_pipeline(to_sg(pipeline));
}

void SokolCommandList::set_bindings(const Bindings& bindings) {
    device_.check_thread("CommandList::set_bindings");
    const sg_bindings b = to_sg(bindings);
    sg_apply_bindings(&b);
}

void SokolCommandList::set_uniforms(int slot, Range data) {
    device_.check_thread("CommandList::set_uniforms");
    const sg_range r = to_sg(data);
    sg_apply_uniforms(slot, &r);
}

void SokolCommandList::set_viewport(int x, int y, int width, int height, bool originTopLeft) {
    device_.check_thread("CommandList::set_viewport");
    sg_apply_viewport(x, y, width, height, originTopLeft);
}

void SokolCommandList::set_viewport_f(float x, float y, float width, float height, bool originTopLeft) {
    device_.check_thread("CommandList::set_viewport_f");
    sg_apply_viewportf(x, y, width, height, originTopLeft);
}

void SokolCommandList::set_scissor(int x, int y, int width, int height, bool originTopLeft) {
    device_.check_thread("CommandList::set_scissor");
    sg_apply_scissor_rect(x, y, width, height, originTopLeft);
}

void SokolCommandList::draw(int base, int count, int instances) {
    device_.check_thread("CommandList::draw");
    sg_draw(base, count, instances);
}

void SokolCommandList::draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) {
    device_.check_thread("CommandList::draw_ex");
    sg_draw_ex(base, count, instances, baseVertex, baseInstance);
}

void SokolCommandList::dispatch(int x, int y, int z) {
    device_.check_thread("CommandList::dispatch");
    sg_dispatch(x, y, z);
}

void SokolCommandList::write_buffer(const BufferWrite& write) {
    device_.check_thread("CommandList::write_buffer");
    sg_write_buffer_desc d{};
    d.src.data = to_sg(write.data);
    d.src.offset = write.srcOffset;
    d.dst.buffer = to_sg(write.buffer);
    d.dst.offset = write.dstOffset;
    d.size = write.size;
    sg_write_buffer_transient(&d);
}

void SokolCommandList::write_image(const ImageWrite& write) {
    device_.check_thread("CommandList::write_image");
    sg_write_image_desc d{};
    d.src.data = to_sg(write.data);
    d.src.offset = write.srcOffset;
    d.src.bytes_per_row = write.bytesPerRow;
    d.src.bytes_per_slice = write.bytesPerSlice;
    d.dst = to_sg(write.dst);
    d.size = to_sg(write.size);
    sg_write_image_transient(&d);
}

void SokolCommandList::copy_buffer_to_buffer(const BufferCopy& copy) {
    device_.check_thread("CommandList::copy_buffer_to_buffer");
    sg_copy_buffer_to_buffer_desc d{};
    d.src.buffer = to_sg(copy.src);
    d.src.offset = copy.srcOffset;
    d.dst.buffer = to_sg(copy.dst);
    d.dst.offset = copy.dstOffset;
    d.size = copy.size;
    sg_copy_buffer_to_buffer(&d);
}

void SokolCommandList::copy_buffer_to_image(const BufferImageCopy& copy) {
    device_.check_thread("CommandList::copy_buffer_to_image");
    sg_copy_buffer_to_image_desc d{};
    d.src.buffer = to_sg(copy.src);
    d.src.offset = copy.srcOffset;
    d.src.bytes_per_row = copy.bytesPerRow;
    d.src.bytes_per_slice = copy.bytesPerSlice;
    d.dst = to_sg(copy.dst);
    d.size = to_sg(copy.size);
    sg_copy_buffer_to_image(&d);
}

void SokolCommandList::push_debug_group(const char* name) {
    device_.check_thread("CommandList::push_debug_group");
    sg_push_debug_group(name ? name : "");
}

void SokolCommandList::pop_debug_group() {
    device_.check_thread("CommandList::pop_debug_group");
    sg_pop_debug_group();
}

void SokolCommandList::begin_timed_scope(const char* name) {
    device_.check_thread("CommandList::begin_timed_scope");
    device_.timer().begin_pass(name ? name : "");
}

void SokolCommandList::end_timed_scope() {
    device_.check_thread("CommandList::end_timed_scope");
    device_.timer().end_pass();
}

// ---------------------------------------------------------------------------------------------------------------------
// SokolDevice
// ---------------------------------------------------------------------------------------------------------------------
Result<std::unique_ptr<SokolDevice>> SokolDevice::create(const DeviceInit& init) {
    bool owns = false;
    if (!sg_isvalid()) {
        sg_desc sd{};
        sd.environment = to_sg(init.environment);
        sd.logger.func = fa_sokol_log_func;
        sd.buffer_pool_size = init.bufferPoolSize;
        sd.image_pool_size = init.imagePoolSize;
        sd.view_pool_size = init.viewPoolSize;
        sd.sampler_pool_size = init.samplerPoolSize;
        sd.shader_pool_size = init.shaderPoolSize;
        sd.pipeline_pool_size = init.pipelinePoolSize;
        sd.uniform_buffer_size = init.uniformBufferSize;
        sg_setup(&sd);
        if (!sg_isvalid())
            return make_error(std::string("gpu: sg_setup failed for the ") + backend_name(built_sokol_backend()) +
                                  " backend",
                              "open the window or the headless context first (a current GL context, or the Metal / "
                              "D3D11 device in DeviceInit::environment); the sokol log above says what failed");
        owns = true;
    }
    return std::unique_ptr<SokolDevice>(new SokolDevice(owns));
}

SokolDevice::SokolDevice(bool ownsContext) : ownsContext_(ownsContext), thread_(std::this_thread::get_id()) {
    const sg_backend b = sg_query_backend();
    info_.backend = backend_from_sg(b);
    info_.metalTarget = metal_target_from_sg(b);
    info_.name = backend_name(info_.backend);
    features_ = from_sg(sg_query_features());
    limits_ = from_sg(sg_query_limits());
    listening_ = sg_add_commit_listener(sg_commit_listener{&SokolDevice::count_commit, this});
}

SokolDevice::~SokolDevice() {
    if (!sg_isvalid()) {
        // The renderer closed the context first: the timer's queries and the reads' staging buffers died with it, and
        // their destructors would call the native API on a context that is gone. Leak the two small objects instead.
        (void)timer_.release();
        for (auto& ring : asyncRead_) (void)ring.release();
        return;
    }
    // The timer and the asynchronous reads hold native queries and staging buffers of this context: release them
    // while it is open.
    timer_.reset();
    for (auto& ring : asyncRead_) ring.reset();
    if (listening_) sg_remove_commit_listener(sg_commit_listener{&SokolDevice::count_commit, this});
    if (ownsContext_) sg_shutdown();
}

void SokolDevice::count_commit(void* self) { ++static_cast<SokolDevice*>(self)->frames_; }

void SokolDevice::check_thread(const char* what) const {
    // One thread-id compare per call (no lock, no allocation unless it fails).
    if (std::this_thread::get_id() == thread_) return;
    const std::string msg = std::string("gpu::SokolDevice is single-threaded: ") + (what ? what : "a call") +
                            " ran on another thread than the one that made the device (the render thread)";
    ::fa::detail::assert_fail("std::this_thread::get_id() == thread_", msg.c_str(), __FILE__, __LINE__);
}

render::GpuTimer& SokolDevice::timer() const {
    if (!timer_) timer_ = std::make_unique<render::GpuTimer>();
    return *timer_;
}

PixelFormatCaps SokolDevice::pixel_format_caps(PixelFormat format) const {
    check_thread("Device::pixel_format_caps");
    if (format == PixelFormat::Default || format == PixelFormat::Count) return {};
    return from_sg(sg_query_pixelformat(to_sg(format)));
}

EnvironmentDefaults SokolDevice::environment_defaults() const {
    check_thread("Device::environment_defaults");
    return from_sg(sg_query_desc().environment.defaults);
}

NativeDevice SokolDevice::native() const {
    check_thread("Device::native");
    NativeDevice n;
    switch (info_.backend) {
        case Backend::Metal:
            n.device = sg_mtl_device();
            n.commandQueue = sg_mtl_command_queue();
            break;
        case Backend::D3d11:
            n.device = sg_d3d11_device();
            n.context = sg_d3d11_device_context();
            break;
        default: break;  // GL has no device object (its context is current on this thread)
    }
    return n;
}

NativeImage SokolDevice::native_image(Image image) const {
    check_thread("Device::native_image");
    NativeImage n;
    if (state(image) != ResourceState::Valid) return n;
    switch (info_.backend) {
        case Backend::Metal: {
            const sg_mtl_image_info i = sg_mtl_query_image_info(to_sg(image));
            if (i.active_slot >= 0 && i.active_slot < SG_NUM_INFLIGHT_FRAMES) n.texture = i.tex[i.active_slot];
            break;
        }
        case Backend::D3d11: {
            const sg_d3d11_image_info i = sg_d3d11_query_image_info(to_sg(image));
            n.texture = i.tex2d ? i.tex2d : i.tex3d;
            n.resource = i.res;
            break;
        }
        case Backend::Gl:
        case Backend::Gles3:
        case Backend::WebGl2: {
            const sg_gl_image_info i = sg_gl_query_image_info(to_sg(image));
            if (i.active_slot >= 0 && i.active_slot < SG_NUM_INFLIGHT_FRAMES) n.glTexture = i.tex[i.active_slot];
            n.glTarget = i.tex_target;
            break;
        }
        default: break;
    }
    return n;
}

NativeBuffer SokolDevice::native_buffer(Buffer buffer) const {
    check_thread("Device::native_buffer");
    NativeBuffer n;
    if (state(buffer) != ResourceState::Valid) return n;
    switch (info_.backend) {
        case Backend::Metal: {
            const sg_mtl_buffer_info i = sg_mtl_query_buffer_info(to_sg(buffer));
            if (i.active_slot >= 0 && i.active_slot < SG_NUM_INFLIGHT_FRAMES) n.buffer = i.buf[i.active_slot];
            break;
        }
        case Backend::D3d11: n.buffer = sg_d3d11_query_buffer_info(to_sg(buffer)).buf; break;
        case Backend::Gl:
        case Backend::Gles3:
        case Backend::WebGl2: {
            const sg_gl_buffer_info i = sg_gl_query_buffer_info(to_sg(buffer));
            if (i.active_slot >= 0 && i.active_slot < SG_NUM_INFLIGHT_FRAMES) n.glBuffer = i.buf[i.active_slot];
            break;
        }
        default: break;
    }
    return n;
}

Buffer SokolDevice::make_buffer(const BufferDesc& desc) {
    check_thread("Device::make_buffer");
    const sg_buffer_desc d = to_sg(desc);
    return from_sg(sg_make_buffer(&d));
}

Image SokolDevice::make_image(const ImageDesc& desc) {
    check_thread("Device::make_image");
    const sg_image_desc d = to_sg(desc);
    // Through the renderer's image functions: they add the per-backend fixes (image_gl.cpp: the last mip level on
    // OpenGL ES) on the image's own GL target.
    switch (desc.type) {
        case ImageType::Cube: return from_sg(render::make_cube_image(d));
        case ImageType::Array: return from_sg(render::make_array_image(d));
        case ImageType::Tex3d: return from_sg(sg_make_image(&d));
        case ImageType::Default:
        case ImageType::Tex2d: break;
    }
    return from_sg(render::make_image(d));
}

View SokolDevice::make_view(const ViewDesc& desc) {
    check_thread("Device::make_view");
    const sg_view_desc d = to_sg(desc);
    return from_sg(sg_make_view(&d));
}

Sampler SokolDevice::make_sampler(const SamplerDesc& desc) {
    check_thread("Device::make_sampler");
    const sg_sampler_desc d = to_sg(desc);
    return from_sg(sg_make_sampler(&d));
}

Shader SokolDevice::make_shader(const ShaderDesc& desc) {
    check_thread("Device::make_shader");
    const sg_shader_desc d = to_sg(desc);
    return from_sg(sg_make_shader(&d));
}

Pipeline SokolDevice::make_pipeline(const PipelineDesc& desc) {
    check_thread("Device::make_pipeline");
    const sg_pipeline_desc d = to_sg(desc);
    return from_sg(sg_make_pipeline(&d));
}

void SokolDevice::destroy_buffer(Buffer buffer) {
    check_thread("Device::destroy_buffer");
    sg_destroy_buffer(to_sg(buffer));
}

void SokolDevice::destroy_image(Image image) {
    check_thread("Device::destroy_image");
    sg_destroy_image(to_sg(image));
}

void SokolDevice::destroy_view(View view) {
    check_thread("Device::destroy_view");
    sg_destroy_view(to_sg(view));
}

void SokolDevice::destroy_sampler(Sampler sampler) {
    check_thread("Device::destroy_sampler");
    sg_destroy_sampler(to_sg(sampler));
}

void SokolDevice::destroy_shader(Shader shader) {
    check_thread("Device::destroy_shader");
    sg_destroy_shader(to_sg(shader));
}

void SokolDevice::destroy_pipeline(Pipeline pipeline) {
    check_thread("Device::destroy_pipeline");
    sg_destroy_pipeline(to_sg(pipeline));
}

ResourceState SokolDevice::state(Buffer buffer) const {
    check_thread("Device::state");
    return from_sg(sg_query_buffer_state(to_sg(buffer)));
}

ResourceState SokolDevice::state(Image image) const {
    check_thread("Device::state");
    return from_sg(sg_query_image_state(to_sg(image)));
}

ResourceState SokolDevice::state(View view) const {
    check_thread("Device::state");
    return from_sg(sg_query_view_state(to_sg(view)));
}

ResourceState SokolDevice::state(Sampler sampler) const {
    check_thread("Device::state");
    return from_sg(sg_query_sampler_state(to_sg(sampler)));
}

ResourceState SokolDevice::state(Shader shader) const {
    check_thread("Device::state");
    return from_sg(sg_query_shader_state(to_sg(shader)));
}

ResourceState SokolDevice::state(Pipeline pipeline) const {
    check_thread("Device::state");
    return from_sg(sg_query_pipeline_state(to_sg(pipeline)));
}

CommandList& SokolDevice::begin_commands(const char* label) {
    (void)label;
    check_thread("Device::begin_commands");
    FA_ASSERT(!listOpen_,
              "gpu::SokolDevice has one immediate command list: submit() it before the next begin_commands()");
    listOpen_ = true;
    return list_;
}

void SokolDevice::submit(CommandList& list) {
    check_thread("Device::submit");
    FA_ASSERT(&list == &list_, "gpu::SokolDevice::submit: the list is not this device's");
    FA_ASSERT(listOpen_, "gpu::SokolDevice::submit: the list was already submitted (begin_commands() first)");
    listOpen_ = false;
}

void SokolDevice::commit() {
    check_thread("Device::commit");
    FA_ASSERT(!listOpen_, "gpu::SokolDevice::commit: submit() the command list before commit()");
    sg_commit();
}

bool SokolDevice::add_commit_listener(void (*func)(void* user), void* user) {
    check_thread("Device::add_commit_listener");
    return sg_add_commit_listener(sg_commit_listener{func, user});
}

bool SokolDevice::remove_commit_listener(void (*func)(void* user), void* user) {
    check_thread("Device::remove_commit_listener");
    return sg_remove_commit_listener(sg_commit_listener{func, user});
}

void SokolDevice::reset_state_cache() {
    check_thread("Device::reset_state_cache");
    sg_reset_state_cache();
}

void SokolDevice::enable_stats(bool on) {
    check_thread("Device::enable_stats");
    if (on)
        sg_enable_stats();
    else
        sg_disable_stats();
}

bool SokolDevice::stats_enabled() const {
    check_thread("Device::stats_enabled");
    return sg_stats_enabled();
}

TotalStats SokolDevice::total_stats() const {
    check_thread("Device::total_stats");
    const sg_total_stats t = sg_query_stats().total;
    TotalStats o;
    o.buffers = from_sg(t.buffers);
    o.images = from_sg(t.images);
    o.samplers = from_sg(t.samplers);
    o.views = from_sg(t.views);
    o.shaders = from_sg(t.shaders);
    o.pipelines = from_sg(t.pipelines);
    return o;
}

bool SokolDevice::timer_supported(std::string* why) const {
    check_thread("Device::timer_supported");
    const bool ok = timer().supported();
    if (!ok && why) *why = timer().reason();
    return ok;
}

void SokolDevice::timer_begin_frame() {
    check_thread("Device::timer_begin_frame");
    timer().begin();
}

void SokolDevice::timer_end_frame() {
    check_thread("Device::timer_end_frame");
    timer().end();
}

void SokolDevice::timer_poll(std::vector<double>& frameMs) {
    check_thread("Device::timer_poll");
    timer().poll(frameMs);
}

std::vector<Device::ScopeTime> SokolDevice::timer_last_scopes() const {
    check_thread("Device::timer_last_scopes");
    std::vector<ScopeTime> out;
    if (!timer_) return out;
    for (const render::GpuTimer::PassTime& p : timer_->last_passes()) out.push_back(ScopeTime{p.name, p.ms});
    return out;
}

void SokolDevice::timer_forget() {
    check_thread("Device::timer_forget");
    if (timer_) timer_->forget();
}

Result<void> SokolDevice::read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) {
    check_thread("Device::read_image_rgba8");
    std::string err;
    if (render::readback_rgba8(to_sg(image), width, height, out, &err)) return {};
    return make_error("gpu: read_image_rgba8: " + err,
                      "the image must be a valid RGBA8 attachment of this device, and the frame that drew it "
                      "committed (Device::commit) before the read");
}

Result<void> SokolDevice::read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) {
    check_thread("Device::read_image_rgba16f");
    std::string err;
    if (render::readback_rgba16f(to_sg(image), width, height, out, &err)) return {};
    return make_error("gpu: read_image_rgba16f: " + err,
                      "the image must be a valid RGBA16F attachment of this device, and the frame that drew it "
                      "committed (Device::commit) before the read");
}

Result<void> SokolDevice::read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                             std::vector<std::uint8_t>& out) {
    check_thread("Device::read_storage_image");
    std::string err;
    if (render::readback_storage_image(to_sg(image), to_sg(format), x, y, width, height, out, &err)) return {};
    return make_error("gpu: read_storage_image: " + err,
                      "pass the image's own format (RGBA8, RGBA16F, R32F, RGBA32F) and a rectangle inside it, on a "
                      "backend with storage images (Features::compute)");
}

Result<void> SokolDevice::read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                                      std::vector<std::uint8_t>& out) {
    check_thread("Device::read_buffer");
    std::string err;
    if (render::readback_buffer(to_sg(buffer), offset, bytes, out, &err)) return {};
    return make_error("gpu: read_buffer: " + err,
                      "read a storage buffer of this device within its size, on a backend with storage buffers "
                      "(Features::compute), after Device::commit");
}

bool SokolDevice::async_read_supported() const { return render::AsyncBufferRead::supported(); }

Result<ReadTicket> SokolDevice::request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) {
    check_thread("Device::request_buffer_read");
    if (bytes == 0 || offset > SIZE_MAX - bytes)
        return make_error("gpu: request_buffer_read: offset " + std::to_string(offset) + " + bytes " +
                              std::to_string(bytes) + " is empty or overflows",
                          "ask for at least one byte inside the buffer");
    static_assert(render::AsyncBufferRead::kSlots == kReadSlotsPerRing, "SokolDevice::reads_ has one entry per slot");
    std::string err;
    // AsyncBufferRead copies from the buffer's start: copy offset + bytes and drop the first offset bytes at poll. The
    // first ring with a free slot takes the request; a new ring is made only when every earlier one is in flight.
    for (std::size_t ring = 0; ring < asyncRead_.size(); ++ring) {
        if (!asyncRead_[ring]) asyncRead_[ring] = std::make_unique<render::AsyncBufferRead>();
        const int slot = asyncRead_[ring]->request(to_sg(buffer), offset + bytes, &err);
        if (slot >= 0 && slot < kReadSlotsPerRing) {
            const std::size_t index = ring * std::size_t(kReadSlotsPerRing) + std::size_t(slot);
            if (++readGeneration_ == 0) ++readGeneration_;  // 0 is "no ticket"
            reads_[index] = PendingRead{offset, readGeneration_};
            return ReadTicket{int(index), readGeneration_};
        }
        if (!err.empty()) break;  // a real error: the next ring would say the same
    }
    if (err.empty()) return ReadTicket{};  // every slot is in flight: ask again next frame
    return make_error("gpu: request_buffer_read: " + err,
                      "the buffer must be a storage buffer of this device and the work that wrote it committed "
                      "(Device::commit); async_read_supported() says whether the backend can");
}

bool SokolDevice::read_ticket_current(ReadTicket ticket) const {
    return ticket.valid() && ticket.slot < int(reads_.size()) &&
           asyncRead_[std::size_t(ticket.slot / kReadSlotsPerRing)] &&
           reads_[std::size_t(ticket.slot)].generation == ticket.generation;
}

bool SokolDevice::poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) {
    check_thread("Device::poll_buffer_read");
    if (!read_ticket_current(ticket)) return false;  // never issued, already read or released: stale
    PendingRead& r = reads_[std::size_t(ticket.slot)];
    if (!asyncRead_[std::size_t(ticket.slot / kReadSlotsPerRing)]->poll(ticket.slot % kReadSlotsPerRing, out, wait))
        return false;
    const std::size_t skip = std::min(r.offset, out.size());
    out.erase(out.begin(), out.begin() + std::ptrdiff_t(skip));
    r = PendingRead{};
    return true;
}

void SokolDevice::release_buffer_read(ReadTicket ticket) {
    check_thread("Device::release_buffer_read");
    if (!read_ticket_current(ticket)) return;
    asyncRead_[std::size_t(ticket.slot / kReadSlotsPerRing)]->release(ticket.slot % kReadSlotsPerRing);
    reads_[std::size_t(ticket.slot)] = PendingRead{};
}

}  // namespace fa::gpu
