// The Vulkan backend's shaders and pipelines: SPIR-V modules with sokol-shdc's descriptor layout (set 0 the uniform
// blocks as dynamic uniform buffers, set 1 the views and samplers, set 2 the bindless table), cached descriptor set
// layouts, pipeline layouts and render passes, and graphics and compute pipelines with an in-memory cache over a
// VkPipelineCache (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/hash.h"

namespace fa::gpu::vk {

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

// Whether a slot of `stage` fits a shader of this kind.
bool stage_fits(ShaderStage stage, bool compute) {
    if (compute) return stage == ShaderStage::Compute;
    return stage == ShaderStage::Vertex || stage == ShaderStage::Fragment;
}

VkShaderStageFlags stage_flags(ShaderStage s) {
    switch (s) {
        case ShaderStage::Vertex: return VK_SHADER_STAGE_VERTEX_BIT;
        case ShaderStage::Fragment: return VK_SHADER_STAGE_FRAGMENT_BIT;
        case ShaderStage::Compute: return VK_SHADER_STAGE_COMPUTE_BIT;
        default: return 0;
    }
}

VkPipelineStageFlags2 pipeline_stage(ShaderStage s) {
    switch (s) {
        case ShaderStage::Vertex: return VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT;
        case ShaderStage::Fragment: return VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT;
        default: return VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
    }
}

const char* descriptor_type_name(VkDescriptorType t) {
    switch (t) {
        case VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC: return "ubo";
        case VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE: return "tex";
        case VK_DESCRIPTOR_TYPE_STORAGE_IMAGE: return "simg";
        case VK_DESCRIPTOR_TYPE_STORAGE_BUFFER: return "sbuf";
        case VK_DESCRIPTOR_TYPE_SAMPLER: return "smp";
        default: return "?";
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
    VkFormat format = VK_FORMAT_UNDEFINED;
    std::uint32_t bytes = 0;
};

VertexFormatInfo vertex_format(VertexFormat f) {
    switch (f) {
        case VertexFormat::Float: return {VK_FORMAT_R32_SFLOAT, 4};
        case VertexFormat::Float2: return {VK_FORMAT_R32G32_SFLOAT, 8};
        case VertexFormat::Float3: return {VK_FORMAT_R32G32B32_SFLOAT, 12};
        case VertexFormat::Float4: return {VK_FORMAT_R32G32B32A32_SFLOAT, 16};
        case VertexFormat::Int: return {VK_FORMAT_R32_SINT, 4};
        case VertexFormat::Int2: return {VK_FORMAT_R32G32_SINT, 8};
        case VertexFormat::Int3: return {VK_FORMAT_R32G32B32_SINT, 12};
        case VertexFormat::Int4: return {VK_FORMAT_R32G32B32A32_SINT, 16};
        case VertexFormat::Uint: return {VK_FORMAT_R32_UINT, 4};
        case VertexFormat::Uint2: return {VK_FORMAT_R32G32_UINT, 8};
        case VertexFormat::Uint3: return {VK_FORMAT_R32G32B32_UINT, 12};
        case VertexFormat::Uint4: return {VK_FORMAT_R32G32B32A32_UINT, 16};
        case VertexFormat::Byte4: return {VK_FORMAT_R8G8B8A8_SINT, 4};
        case VertexFormat::Byte4N: return {VK_FORMAT_R8G8B8A8_SNORM, 4};
        case VertexFormat::Ubyte4: return {VK_FORMAT_R8G8B8A8_UINT, 4};
        case VertexFormat::Ubyte4N: return {VK_FORMAT_R8G8B8A8_UNORM, 4};
        case VertexFormat::Short2: return {VK_FORMAT_R16G16_SINT, 4};
        case VertexFormat::Short2N: return {VK_FORMAT_R16G16_SNORM, 4};
        case VertexFormat::Ushort2: return {VK_FORMAT_R16G16_UINT, 4};
        case VertexFormat::Ushort2N: return {VK_FORMAT_R16G16_UNORM, 4};
        case VertexFormat::Short4: return {VK_FORMAT_R16G16B16A16_SINT, 8};
        case VertexFormat::Short4N: return {VK_FORMAT_R16G16B16A16_SNORM, 8};
        case VertexFormat::Ushort4: return {VK_FORMAT_R16G16B16A16_UINT, 8};
        case VertexFormat::Ushort4N: return {VK_FORMAT_R16G16B16A16_UNORM, 8};
        case VertexFormat::Int10N2: return {VK_FORMAT_A2B10G10R10_SNORM_PACK32, 4};
        case VertexFormat::Uint10N2: return {VK_FORMAT_A2B10G10R10_UNORM_PACK32, 4};
        case VertexFormat::Half2: return {VK_FORMAT_R16G16_SFLOAT, 4};
        case VertexFormat::Half4: return {VK_FORMAT_R16G16B16A16_SFLOAT, 8};
        default: return {};
    }
}

VkBlendFactor blend_factor(BlendFactor f, BlendFactor fallback) {
    if (f == BlendFactor::Default) f = fallback;
    switch (f) {
        case BlendFactor::Zero: return VK_BLEND_FACTOR_ZERO;
        case BlendFactor::One: return VK_BLEND_FACTOR_ONE;
        case BlendFactor::SrcColor: return VK_BLEND_FACTOR_SRC_COLOR;
        case BlendFactor::OneMinusSrcColor: return VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
        case BlendFactor::SrcAlpha: return VK_BLEND_FACTOR_SRC_ALPHA;
        case BlendFactor::OneMinusSrcAlpha: return VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
        case BlendFactor::DstColor: return VK_BLEND_FACTOR_DST_COLOR;
        case BlendFactor::OneMinusDstColor: return VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
        case BlendFactor::DstAlpha: return VK_BLEND_FACTOR_DST_ALPHA;
        case BlendFactor::OneMinusDstAlpha: return VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
        case BlendFactor::SrcAlphaSaturated: return VK_BLEND_FACTOR_SRC_ALPHA_SATURATE;
        case BlendFactor::BlendColor: return VK_BLEND_FACTOR_CONSTANT_COLOR;
        case BlendFactor::OneMinusBlendColor: return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
        case BlendFactor::BlendAlpha: return VK_BLEND_FACTOR_CONSTANT_ALPHA;
        case BlendFactor::OneMinusBlendAlpha: return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA;
        case BlendFactor::Src1Color: return VK_BLEND_FACTOR_SRC1_COLOR;
        case BlendFactor::OneMinusSrc1Color: return VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR;
        case BlendFactor::Src1Alpha: return VK_BLEND_FACTOR_SRC1_ALPHA;
        case BlendFactor::OneMinusSrc1Alpha: return VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA;
        default: return VK_BLEND_FACTOR_ONE;
    }
}

bool uses_src1(BlendFactor f) {
    return f == BlendFactor::Src1Color || f == BlendFactor::OneMinusSrc1Color || f == BlendFactor::Src1Alpha ||
           f == BlendFactor::OneMinusSrc1Alpha;
}

// BlendOp's values are VkBlendOp's plus one (Add = 1 .. Max = 5), CompareFunc's VkCompareOp's plus one (Never = 1 ..
// Always = 8), StencilOp's VkStencilOp's plus one (Keep = 1 .. DecrWrap = 8).
VkBlendOp blend_op(BlendOp op) { return op == BlendOp::Default ? VK_BLEND_OP_ADD : VkBlendOp(std::uint32_t(op) - 1u); }
VkCompareOp compare_op(CompareFunc f) {
    return VkCompareOp(std::uint32_t(f == CompareFunc::Default ? CompareFunc::Always : f) - 1u);
}
VkStencilOp stencil_op(StencilOp op) {
    return VkStencilOp(std::uint32_t(op == StencilOp::Default ? StencilOp::Keep : op) - 1u);
}

VkColorComponentFlags color_mask(ColorMask m) {
    if (m == ColorMask::Default) return 0xFu;
    if (m == ColorMask::None) return 0;
    return VkColorComponentFlags(std::uint32_t(m) & 0xFu);  // R = 1, G = 2, B = 4, A = 8, as VkColorComponentFlagBits
}

// One stage's SPIR-V: the words of its bytecode, checked.
bool spirv_words(const ShaderFunction& fn, const char* stage, std::vector<std::uint32_t>& out, std::string& error) {
    if (!fn.bytecode.ptr) {
        if (fn.source)
            error = std::string("the ") + stage +
                    " stage is source text, and Vulkan takes SPIR-V (hint: give the stage as SPIR-V bytecode: "
                    "sokol-shdc's spirv_vk output, which the generated shader headers carry; a custom material's "
                    "SPIR-V goes through render::make_shader, which decodes it)";
        else
            error = std::string("the ") + stage +
                    " stage has neither source nor bytecode (hint: a render shader sets vertexFunc and fragmentFunc, a "
                    "compute shader computeFunc)";
        return false;
    }
    const std::size_t size = fn.bytecode.size;
    std::uint32_t magic = 0;
    if (size >= 4) std::memcpy(&magic, fn.bytecode.ptr, 4);
    if (size < 20 || size % 4 != 0 || magic != 0x07230203u) {
        error = std::string("the ") + stage + " stage's bytecode (" + std::to_string(size) +
                " bytes) is not SPIR-V (hint: SPIR-V is a whole number of 32-bit words that starts with the magic "
                "number 0x07230203 and a 20-byte header; Vulkan takes sokol-shdc's spirv_vk output)";
        return false;
    }
    out.resize(size / 4);
    std::memcpy(out.data(), fn.bytecode.ptr, size);
    return true;
}

// The state structs of a graphics pipeline. The create info points into this struct: it is filled in place and never
// copied.
struct GraphicsBuild {
    VkPipelineShaderStageCreateInfo stages[2]{};
    std::vector<VkVertexInputBindingDescription> bindings;
    std::vector<VkVertexInputAttributeDescription> attributes;
    VkPipelineVertexInputStateCreateInfo vertexInput{};
    VkPipelineInputAssemblyStateCreateInfo inputAssembly{};
    VkPipelineViewportStateCreateInfo viewport{};
    VkPipelineRasterizationStateCreateInfo raster{};
    VkPipelineMultisampleStateCreateInfo multisample{};
    VkPipelineDepthStencilStateCreateInfo depthStencil{};
    VkPipelineColorBlendAttachmentState blends[kMaxColorAttachments]{};
    VkPipelineColorBlendStateCreateInfo colorBlend{};
    VkDynamicState dynamicStates[4] = {VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR,
                                       VK_DYNAMIC_STATE_BLEND_CONSTANTS, VK_DYNAMIC_STATE_STENCIL_REFERENCE};
    VkPipelineDynamicStateCreateInfo dynamic{};
    VkGraphicsPipelineCreateInfo info{};
    RenderPassKey pass{};
    KeyText key;

    GraphicsBuild() = default;
    GraphicsBuild(const GraphicsBuild&) = delete;
    GraphicsBuild& operator=(const GraphicsBuild&) = delete;
};

bool same_blend(const VkPipelineColorBlendAttachmentState& a, const VkPipelineColorBlendAttachmentState& b) {
    return a.blendEnable == b.blendEnable && a.srcColorBlendFactor == b.srcColorBlendFactor &&
           a.dstColorBlendFactor == b.dstColorBlendFactor && a.colorBlendOp == b.colorBlendOp &&
           a.srcAlphaBlendFactor == b.srcAlphaBlendFactor && a.dstAlphaBlendFactor == b.dstAlphaBlendFactor &&
           a.alphaBlendOp == b.alphaBlendOp && a.colorWriteMask == b.colorWriteMask;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Shaders
// ---------------------------------------------------------------------------------------------------------------------

ShaderInfo::~ShaderInfo() {
    if (!device || !device->vk_device()) return;
    for (VkShaderModule m : {vs, fs, cs})
        if (m) device->fn().vkDestroyShaderModule(device->vk_device(), m, nullptr);
}

std::string RenderPassKey::text() const {
    KeyText k;
    for (std::uint64_t v :
         {std::uint64_t(color[0]), std::uint64_t(color[1]), std::uint64_t(colorCount), std::uint64_t(depth),
          std::uint64_t(resolve), std::uint64_t(samples), std::uint64_t(colorLoad), std::uint64_t(colorStore),
          std::uint64_t(depthLoad), std::uint64_t(depthStore), std::uint64_t(stencilLoad), std::uint64_t(stencilStore)})
        k.add(v);
    return k.s;
}

Shader VulkanDevice::make_shader(const ShaderDesc& desc) {
    const std::string label = label_of(desc.label);
    auto info = std::make_shared<ShaderInfo>();
    info->device = this;
    info->compute = desc.compute();
    info->label = label;
    std::string error;
    auto fail = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    const bool hasRender = desc.vertexFunc.source || desc.vertexFunc.bytecode.ptr || desc.fragmentFunc.source ||
                           desc.fragmentFunc.bytecode.ptr;
    if (info->compute && hasRender)
        fail("it has a compute stage and a vertex or fragment stage (hint: a compute shader sets computeFunc only, a "
             "render shader vertexFunc and fragmentFunc)");

    // The slots: each in a stage the shader has, uniform blocks in set 0 and the rest in set 1, each on a binding of its
    // own.
    const char* kind = info->compute ? "a compute shader" : "a render shader";
    std::map<std::uint32_t, std::string> taken;  // set << 8 | binding -> what is there
    auto claim = [&](const std::string& what, std::uint32_t wantSet, const BackendBinding& b) {
        if (b.spirvSet != wantSet) {
            fail(what + " is in descriptor set " + std::to_string(b.spirvSet) + " (hint: Vulkan lays shaders out as " +
                 "sokol-shdc does: the uniform blocks in set 0, the views and samplers in set 1; set 2 is the "
                 "bindless table)");
            return;
        }
        const std::uint32_t at = std::uint32_t(b.spirvSet) << 8 | b.spirvBinding;
        auto [it, added] = taken.try_emplace(at, what);
        if (!added)
            fail(what + " is on binding " + std::to_string(b.spirvBinding) + " of set " + std::to_string(b.spirvSet) +
                 ", which " + it->second +
                 " is on already (hint: every uniform block, view and sampler needs a binding of its own)");
    };
    auto wrong_stage = [&](const std::string& what, ShaderStage s) {
        fail(what + " belongs to the " + stage_name(s) + " stage, which " + kind +
             " does not have (hint: a compute shader's slots are ShaderStage::Compute, a render shader's Vertex or "
             "Fragment)");
    };
    const std::uint32_t uniformMost = std::min<std::uint32_t>(props_.limits.maxUniformBufferRange, 65536u);
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        const ShaderUniformBlock& b = desc.uniformBlocks[i];
        if (b.stage == ShaderStage::None) continue;
        const std::string what = "uniform block " + std::to_string(i);
        if (!stage_fits(b.stage, info->compute)) {
            wrong_stage(what, b.stage);
            continue;
        }
        if (b.size == 0 || b.size > uniformMost) {
            fail(what + " has " + std::to_string(b.size) + " bytes (hint: a uniform block has 1 to " +
                 std::to_string(uniformMost) + " bytes on this GPU, its maxUniformBufferRange)");
            continue;
        }
        info->uniformSize[i] = b.size;
        claim(what, 0, b.binding);
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const ShaderView& v = desc.views[i];
        const ViewType type = v.type();
        if (type == ViewType::Invalid) continue;
        const std::string what = "view " + std::to_string(i);
        if (!stage_fits(v.stage(), info->compute)) {
            wrong_stage(what, v.stage());
            continue;
        }
        info->viewType[i] = type;
        const BackendBinding* b = &v.texture.binding;
        ImageType imageType = ImageType::Default;
        if (type == ViewType::StorageBuffer) {
            info->viewWritable[i] = !v.storageBuffer.readonly;
            b = &v.storageBuffer.binding;
        } else if (type == ViewType::StorageImage) {
            info->viewWritable[i] = true;
            imageType = v.storageImage.imageType;
            b = &v.storageImage.binding;
        } else {
            imageType = v.texture.imageType;
        }
        info->viewImageType[i] = imageType == ImageType::Default ? ImageType::Tex2d : imageType;
        claim(what, 1, *b);
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& sm = desc.samplers[i];
        if (sm.stage == ShaderStage::None) continue;
        const std::string what = "sampler " + std::to_string(i);
        if (!stage_fits(sm.stage, info->compute)) {
            wrong_stage(what, sm.stage);
            continue;
        }
        claim(what, 1, sm.binding);
    }

    // The modules
    Sha256 h;
    auto module = [&](const ShaderFunction& fn, const char* stage, VkShaderModule& out, std::string& entry) {
        if (!error.empty()) return;
        std::vector<std::uint32_t> words;
        std::string e;
        if (!spirv_words(fn, stage, words, e)) {
            fail(e);
            return;
        }
        entry = fn.entry && *fn.entry ? fn.entry : "main";
        h.update(std::string(stage) + ":" + std::to_string(words.size()) + ":" + entry + ":");
        h.update(words.data(), words.size() * 4);
        VkShaderModuleCreateInfo ci{};
        ci.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
        ci.codeSize = words.size() * 4;
        ci.pCode = words.data();
        const VkResult r = fn_.vkCreateShaderModule(device_, &ci, nullptr, &out);
        if (r != VK_SUCCESS) {
            out = VK_NULL_HANDLE;
            fail(std::string("vkCreateShaderModule (") + stage + " stage) failed with " + result_text(r) +
                 " (hint: the validation layer (VulkanOptions::validation) says what is wrong with the SPIR-V)");
            return;
        }
        set_name(VK_OBJECT_TYPE_SHADER_MODULE, handle_bits(out), label.c_str());
    };
    if (info->compute) {
        module(desc.computeFunc, "compute", info->cs, info->csEntry);
    } else {
        module(desc.vertexFunc, "vertex", info->vs, info->vsEntry);
        module(desc.fragmentFunc, "fragment", info->fs, info->fsEntry);
    }

    std::shared_ptr<const PipelineLayoutInfo> layout;
    if (error.empty()) {
        info->codeKey = h.finish_hex();
        std::string e;
        layout = pipeline_layout(desc, *info, e);
        if (!layout) fail(e);
    }
    if (!error.empty()) report("gpu vulkan: make_shader '" + label + "': " + error);

    ShaderRecord rec;
    if (error.empty()) {
        rec.info = std::move(info);
        rec.layout = std::move(layout);
    }
    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.info != nullptr;
    const std::uint32_t id = shaders_.add(std::move(rec));
    if (id == 0) {
        report("gpu vulkan: make_shader '" + label + "': the shader pool is full (" +
               std::to_string(shaders_.capacity()) +
               " shaders) (hint: destroy shaders you no longer use, or raise DeviceInit::shaderPoolSize)");
        return {};
    }
    count_make(stats_.shaders, ok);
    return Shader{id};
}

VkDescriptorSetLayout VulkanDevice::set_layout(const std::string& key,
                                               const std::vector<VkDescriptorSetLayoutBinding>& bindings,
                                               std::string& error) {
    std::lock_guard<std::mutex> lock(cacheMutex_);
    if (auto it = setLayouts_.find(key); it != setLayouts_.end()) {
        ++layoutHits_;
        return it->second;
    }
    VkDescriptorSetLayoutCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    ci.bindingCount = std::uint32_t(bindings.size());
    ci.pBindings = bindings.empty() ? nullptr : bindings.data();
    VkDescriptorSetLayout made = VK_NULL_HANDLE;
    const VkResult r = fn_.vkCreateDescriptorSetLayout(device_, &ci, nullptr, &made);
    if (r != VK_SUCCESS) {
        error = "vkCreateDescriptorSetLayout (" + std::to_string(bindings.size()) + " bindings) failed with " +
                result_text(r) + " (hint: the device is out of memory)";
        return VK_NULL_HANDLE;
    }
    set_name(VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT, handle_bits(made), "fa-vulkan-set-layout");
    ++layoutMisses_;
    setLayouts_.emplace(key, made);
    return made;
}

std::shared_ptr<const PipelineLayoutInfo> VulkanDevice::pipeline_layout(const ShaderDesc& desc, const ShaderInfo& info,
                                                                        std::string& error) {
    const VkDescriptorSetLayout bindless = descriptors_.bindless_layout();
    auto layout = std::make_shared<PipelineLayoutInfo>();
    std::vector<VkDescriptorSetLayoutBinding> sets[2];
    // The key names every slot with its binding, type and stage (shaders with the same bindings but other slots need
    // layouts of their own: the slot -> binding maps differ), and whether the bindless table is there.
    KeyText key;
    key.add(info.compute ? "compute" : "render");
    auto add = [&](char kind, int slot, std::uint32_t set, std::uint32_t binding, VkDescriptorType type,
                   ShaderStage stage) {
        VkDescriptorSetLayoutBinding b{};
        b.binding = binding;
        b.descriptorType = type;
        b.descriptorCount = 1;
        b.stageFlags = stage_flags(stage);
        sets[set].push_back(b);
        for (std::uint64_t v : {std::uint64_t(kind), std::uint64_t(slot), std::uint64_t(set), std::uint64_t(binding),
                                std::uint64_t(type), std::uint64_t(b.stageFlags)})
            key.add(v);
    };
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        if (info.uniformSize[i] == 0) continue;
        const ShaderUniformBlock& b = desc.uniformBlocks[i];
        layout->uniformBinding[i] = b.binding.spirvBinding;
        layout->counts[0].n[kDescUniformBufferDynamic]++;
        add('u', i, 0, b.binding.spirvBinding, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, b.stage);
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const ViewType type = info.viewType[i];
        if (type == ViewType::Invalid) continue;
        const ShaderView& v = desc.views[i];
        std::uint32_t binding = v.texture.binding.spirvBinding;
        VkDescriptorType dt = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
        int kindIndex = kDescSampledImage;
        if (type == ViewType::StorageBuffer) {
            binding = v.storageBuffer.binding.spirvBinding;
            dt = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
            kindIndex = kDescStorageBuffer;
        } else if (type == ViewType::StorageImage) {
            binding = v.storageImage.binding.spirvBinding;
            dt = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
            kindIndex = kDescStorageImage;
        }
        layout->viewBinding[i] = binding;
        layout->viewStage[i] = pipeline_stage(v.stage());
        layout->counts[1].n[std::size_t(kindIndex)]++;
        add('v', i, 1, binding, dt, v.stage());
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& sm = desc.samplers[i];
        if (sm.stage == ShaderStage::None) continue;
        layout->samplerBinding[i] = sm.binding.spirvBinding;
        layout->samplerUsed |= 1u << i;
        layout->counts[1].n[kDescSampler]++;
        add('s', i, 1, sm.binding.spirvBinding, VK_DESCRIPTOR_TYPE_SAMPLER, sm.stage);
    }
    key.add(bindless ? "bindless" : "-");
    layout->key = key.s;
    layout->bindless = bindless != VK_NULL_HANDLE;
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        if (auto it = pipelineLayouts_.find(key.s); it != pipelineLayouts_.end()) {
            ++layoutHits_;
            return it->second;
        }
    }

    // The dynamic offsets go in binding order.
    int n = 0;
    for (int i = 0; i < kMaxUniformBlocks; ++i)
        if (info.uniformSize[i] != 0) layout->uniformOrder[n++] = std::uint8_t(i);
    layout->uniformCount = n;
    std::sort(layout->uniformOrder, layout->uniformOrder + n,
              [&](std::uint8_t a, std::uint8_t b) { return layout->uniformBinding[a] < layout->uniformBinding[b]; });

    for (std::size_t s = 0; s < 2; ++s) {
        std::sort(sets[s].begin(), sets[s].end(),
                  [](const VkDescriptorSetLayoutBinding& a, const VkDescriptorSetLayoutBinding& b) {
                      return a.binding < b.binding;
                  });
        // The set layout's key: its bindings in order (shared by every pipeline layout with the same set).
        std::string setKey;
        for (const VkDescriptorSetLayoutBinding& b : sets[s])
            setKey += std::to_string(b.binding) + ":" + descriptor_type_name(b.descriptorType) + ":" +
                      std::to_string(b.stageFlags) + ",";
        layout->sets[s] = set_layout(setKey, sets[s], error);
        if (!layout->sets[s]) return nullptr;
        layout->hasSet[s] = !sets[s].empty();
    }
    VkDescriptorSetLayout all[3] = {layout->sets[0], layout->sets[1], bindless};
    VkPipelineLayoutCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    ci.setLayoutCount = bindless ? 3u : 2u;
    ci.pSetLayouts = all;
    const VkResult r = fn_.vkCreatePipelineLayout(device_, &ci, nullptr, &layout->layout);
    if (r != VK_SUCCESS) {
        layout->layout = VK_NULL_HANDLE;
        error = "vkCreatePipelineLayout failed with " + result_text(r) +
                " (hint: the validation layer (VulkanOptions::validation) says which limit the shader's bindings pass)";
        return nullptr;
    }
    set_name(VK_OBJECT_TYPE_PIPELINE_LAYOUT, handle_bits(layout->layout), "fa-vulkan-pipeline-layout");
    std::lock_guard<std::mutex> lock(cacheMutex_);
    auto [it, added] = pipelineLayouts_.try_emplace(layout->key, layout);
    if (added) {
        ++layoutMisses_;
    } else {
        ++layoutHits_;  // another thread made the same one meanwhile: the first one is kept
        fn_.vkDestroyPipelineLayout(device_, layout->layout, nullptr);
    }
    return it->second;
}

void VulkanDevice::destroy_shader(Shader shader) {
    if (!shader.valid()) return;
    ShaderRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!shaders_.remove(shader.id, rec)) {
            report("gpu vulkan: destroy_shader: shader " + std::to_string(shader.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.shaders);
    }
    // The modules live on in the pipelines being made from it; the last holder destroys them (no pipeline needs them
    // once made).
}

ResourceState VulkanDevice::state(Shader shader) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ShaderRecord* r = shaders_.get(shader.id);
    if (!r) return ResourceState::Invalid;
    return r->info ? ResourceState::Valid : ResourceState::Failed;
}

// ---------------------------------------------------------------------------------------------------------------------
// Render passes
// ---------------------------------------------------------------------------------------------------------------------

VkRenderPass VulkanDevice::render_pass(const RenderPassKey& key, std::string& error) {
    const std::string text = key.text();
    std::lock_guard<std::mutex> lock(cacheMutex_);
    if (auto it = renderPasses_.find(text); it != renderPasses_.end()) {
        ++renderPassHits_;
        return it->second;
    }
    // Every attachment starts and ends in the layout the pass uses it in: the command list's barriers put it there
    // before the pass and track it after.
    std::vector<VkAttachmentDescription> att;
    VkAttachmentReference colorRefs[2]{}, resolveRefs[2]{}, depthRef{};
    for (int i = 0; i < key.colorCount && i < 2; ++i) {
        VkAttachmentDescription a{};
        a.format = key.color[i];
        a.samples = key.samples;
        a.loadOp = key.colorLoad;
        a.storeOp = key.colorStore;
        a.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        a.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        a.initialLayout = a.finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
        colorRefs[i] = {std::uint32_t(att.size()), VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL};
        att.push_back(a);
    }
    const int colors = std::min(key.colorCount, 2);
    if (key.depth != VK_FORMAT_UNDEFINED) {
        VkAttachmentDescription a{};
        a.format = key.depth;
        a.samples = key.samples;
        a.loadOp = key.depthLoad;
        a.storeOp = key.depthStore;
        a.stencilLoadOp = key.stencilLoad;
        a.stencilStoreOp = key.stencilStore;
        a.initialLayout = a.finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
        depthRef = {std::uint32_t(att.size()), VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL};
        att.push_back(a);
    }
    const bool resolve = key.resolve != VK_FORMAT_UNDEFINED && colors > 0;
    if (resolve) {
        VkAttachmentDescription a{};
        a.format = key.resolve;
        a.samples = VK_SAMPLE_COUNT_1_BIT;
        a.loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        a.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        a.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        a.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        a.initialLayout = a.finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
        resolveRefs[0] = {std::uint32_t(att.size()), VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL};
        resolveRefs[1] = {VK_ATTACHMENT_UNUSED, VK_IMAGE_LAYOUT_UNDEFINED};
        att.push_back(a);
    }
    VkSubpassDescription sub{};
    sub.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    sub.colorAttachmentCount = std::uint32_t(colors);
    sub.pColorAttachments = colors > 0 ? colorRefs : nullptr;
    sub.pResolveAttachments = resolve ? resolveRefs : nullptr;
    sub.pDepthStencilAttachment = key.depth != VK_FORMAT_UNDEFINED ? &depthRef : nullptr;
    VkRenderPassCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    ci.attachmentCount = std::uint32_t(att.size());
    ci.pAttachments = att.empty() ? nullptr : att.data();
    ci.subpassCount = 1;
    ci.pSubpasses = &sub;
    VkRenderPass made = VK_NULL_HANDLE;
    const VkResult r = fn_.vkCreateRenderPass(device_, &ci, nullptr, &made);
    if (r != VK_SUCCESS) {
        error = "vkCreateRenderPass (" + std::to_string(att.size()) + " attachments) failed with " + result_text(r) +
                " (hint: the validation layer (VulkanOptions::validation) says which attachment is wrong)";
        return VK_NULL_HANDLE;
    }
    set_name(VK_OBJECT_TYPE_RENDER_PASS, handle_bits(made), "fa-vulkan-render-pass");
    ++renderPassMisses_;
    renderPasses_.emplace(text, made);
    return made;
}

// ---------------------------------------------------------------------------------------------------------------------
// Pipelines
// ---------------------------------------------------------------------------------------------------------------------

namespace {

// Fills the graphics pipeline's state (but its stages, layout and render pass) and the draw state of `st` from a render
// pipeline's desc; the error when the desc cannot be one.
std::string graphics_desc(const PipelineDesc& desc, const VulkanDevice& dev, const VkPhysicalDeviceLimits& lim,
                          bool portability, bool depthBiasClamp, PipelineState& st, GraphicsBuild& out) {
    const Features& features = dev.features();
    const EnvironmentDefaults env = dev.environment_defaults();

    // The vertex input (sokol's rules: offsets are packed in order when every one is 0, a stride of 0 is the packed
    // size, the attributes end at the first Invalid format). The attribute's index is its location.
    bool autoOffset = true;
    for (const VertexAttr& a : desc.layout.attrs)
        if (a.offset != 0) autoOffset = false;
    std::uint32_t packed[kMaxVertexBuffers]{};
    for (int i = 0; i < kMaxVertexAttributes; ++i) {
        const VertexAttr& a = desc.layout.attrs[i];
        if (a.format == VertexFormat::Invalid) break;
        const std::string what = "vertex attribute " + std::to_string(i);
        if (a.bufferIndex < 0 || a.bufferIndex >= kMaxVertexBuffers)
            return what + " reads vertex buffer slot " + std::to_string(a.bufferIndex) + " (hint: slots are 0 to " +
                   std::to_string(kMaxVertexBuffers - 1) + ")";
        const VertexFormatInfo vf = vertex_format(a.format);
        if (vf.format == VK_FORMAT_UNDEFINED) return what + " has an unknown format";
        if (a.format == VertexFormat::Int10N2 && !features.vertexFormatInt10N2)
            return what + " has format Int10N2, which this GPU cannot read as a vertex format (hint: Uint10N2; "
                          "Features::vertexFormatInt10N2 says where Int10N2 exists)";
        if (a.offset < 0) return what + " has the negative offset " + std::to_string(a.offset);
        const auto b = std::size_t(a.bufferIndex);
        const std::uint32_t offset = autoOffset ? packed[b] : std::uint32_t(a.offset);
        if (offset > lim.maxVertexInputAttributeOffset)
            return what + " is at offset " + std::to_string(offset) + ", past this GPU's " +
                   std::to_string(lim.maxVertexInputAttributeOffset) + " (maxVertexInputAttributeOffset)";
        VkVertexInputAttributeDescription e{};
        e.location = std::uint32_t(i);
        e.binding = std::uint32_t(b);
        e.format = vf.format;
        e.offset = offset;
        packed[b] += vf.bytes;
        st.buffersUsed |= 1u << b;
        out.attributes.push_back(e);
    }
    for (std::size_t b = 0; b < std::size_t(kMaxVertexBuffers); ++b) {
        if (!(st.buffersUsed & (1u << b))) continue;
        const VertexBufferLayout& bl = desc.layout.buffers[b];
        const int stride = bl.stride;
        const std::string slot = "vertex buffer slot " + std::to_string(b);
        if (stride < 0 || std::uint64_t(stride) > lim.maxVertexInputBindingStride)
            return slot + " has stride " + std::to_string(stride) +
                   " (hint: 0 = the packed size of its attributes, at most " +
                   std::to_string(lim.maxVertexInputBindingStride) + " bytes on this GPU)";
        const std::uint32_t s = stride > 0 ? std::uint32_t(stride) : packed[b];
        if (portability && s % 4 != 0)
            return slot + " has stride " + std::to_string(s) +
                   ", and this GPU (VK_KHR_portability_subset: MoltenVK) reads vertices at strides that are multiples "
                   "of 4 bytes only (hint: pad the vertex to a multiple of 4 bytes)";
        if (bl.stepRate > 1)
            return slot + " has stepRate " + std::to_string(bl.stepRate) +
                   ", and the Vulkan backend steps instance data one instance at a time (hint: stepRate 0 or 1; "
                   "repeat the instance data instead)";
        VkVertexInputBindingDescription d{};
        d.binding = std::uint32_t(b);
        d.stride = s;
        d.inputRate =
            bl.stepFunc == VertexStep::PerInstance ? VK_VERTEX_INPUT_RATE_INSTANCE : VK_VERTEX_INPUT_RATE_VERTEX;
        out.bindings.push_back(d);
    }

    // The colour targets
    int colorCount = desc.colorCount;
    if (colorCount == 0) colorCount = desc.colors[0].pixelFormat == PixelFormat::None ? 0 : 1;
    if (colorCount < 0 || colorCount > kMaxColorAttachments)
        return "colorCount " + std::to_string(desc.colorCount) + " is outside 0.." +
               std::to_string(kMaxColorAttachments);
    if (colorCount > 2)
        return "colorCount " + std::to_string(colorCount) +
               " is more than the 2 colour targets a pass has (hint: PassDesc has color and color1)";
    const int samples = desc.sampleCount > 0 ? desc.sampleCount : env.sampleCount;
    if (samples != 1 && samples != 2 && samples != 4 && samples != 8)
        return "sampleCount " + std::to_string(samples) + " is not 1, 2, 4 or 8";
    PixelFormat colorFormats[kMaxColorAttachments]{};
    for (int i = 0; i < colorCount; ++i) {
        const ColorTargetState& c = desc.colors[i];
        const PixelFormat f = c.pixelFormat == PixelFormat::Default ? env.colorFormat : c.pixelFormat;
        const std::string what = "colour target " + std::to_string(i) + " (" + pixel_format_name(f) + ")";
        const PixelFormatCaps fc = dev.pixel_format_caps(f);
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
        if (c.blend.enabled && !features.dualSourceBlending &&
            (uses_src1(c.blend.srcFactorRgb) || uses_src1(c.blend.dstFactorRgb) || uses_src1(c.blend.srcFactorAlpha) ||
             uses_src1(c.blend.dstFactorAlpha)))
            return what + " blends with a Src1 factor, and this GPU has no dual-source blending (hint: "
                          "Features::dualSourceBlending says where it has)";
        colorFormats[i] = f;
        out.pass.color[i] = dev.vk_format(f);
        VkPipelineColorBlendAttachmentState& bt = out.blends[i];
        bt.blendEnable = c.blend.enabled ? VK_TRUE : VK_FALSE;
        // The factors of a target that does not blend are left at their defaults, so they do not make two targets
        // differ.
        bt.srcColorBlendFactor =
            c.blend.enabled ? blend_factor(c.blend.srcFactorRgb, BlendFactor::One) : VK_BLEND_FACTOR_ONE;
        bt.dstColorBlendFactor =
            c.blend.enabled ? blend_factor(c.blend.dstFactorRgb, BlendFactor::Zero) : VK_BLEND_FACTOR_ZERO;
        bt.colorBlendOp = c.blend.enabled ? blend_op(c.blend.opRgb) : VK_BLEND_OP_ADD;
        bt.srcAlphaBlendFactor =
            c.blend.enabled ? blend_factor(c.blend.srcFactorAlpha, BlendFactor::One) : VK_BLEND_FACTOR_ONE;
        bt.dstAlphaBlendFactor =
            c.blend.enabled ? blend_factor(c.blend.dstFactorAlpha, BlendFactor::Zero) : VK_BLEND_FACTOR_ZERO;
        bt.alphaBlendOp = c.blend.enabled ? blend_op(c.blend.opAlpha) : VK_BLEND_OP_ADD;
        bt.colorWriteMask = color_mask(c.writeMask);
        if (i > 0 && !features.mrtIndependentBlendState && !same_blend(bt, out.blends[0]))
            return "colour targets 0 and " + std::to_string(i) +
                   " blend or mask differently, which this GPU cannot (hint: Features::mrtIndependentBlendState says "
                   "where it can; give every target the same blend state and write mask)";
    }

    // Depth and stencil
    const PixelFormat depth = desc.depth.pixelFormat == PixelFormat::Default ? env.depthFormat : desc.depth.pixelFormat;
    const bool hasDepth = depth != PixelFormat::None;
    if (hasDepth) {
        const PixelFormatCaps fc = dev.pixel_format_caps(depth);
        if (!fc.depth || !fc.render)
            return std::string("depth format ") + pixel_format_name(depth) +
                   " is not a depth format this GPU renders to (hint: Depth or DepthStencil; None for a pipeline "
                   "without depth)";
        if (samples > 1 && !fc.msaa)
            return std::string("depth format ") + pixel_format_name(depth) + " cannot be multisampled on this GPU";
        out.pass.depth = dev.vk_format(depth);
    }
    const bool hasStencil = hasDepth && (format_info(depth).aspects & VK_IMAGE_ASPECT_STENCIL_BIT) != 0;
    const CompareFunc depthCompare =
        desc.depth.compare == CompareFunc::Default ? CompareFunc::Always : desc.depth.compare;
    VkPipelineDepthStencilStateCreateInfo& ds = out.depthStencil;
    ds.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
    ds.depthTestEnable =
        hasDepth && (depthCompare != CompareFunc::Always || desc.depth.writeEnabled) ? VK_TRUE : VK_FALSE;
    ds.depthWriteEnable = hasDepth && desc.depth.writeEnabled ? VK_TRUE : VK_FALSE;
    ds.depthCompareOp = compare_op(depthCompare);
    ds.stencilTestEnable = hasStencil && desc.stencil.enabled ? VK_TRUE : VK_FALSE;
    auto face = [&](const StencilFaceState& f, VkStencilOpState& o) {
        o.failOp = stencil_op(f.failOp);
        o.passOp = stencil_op(f.passOp);
        o.depthFailOp = stencil_op(f.depthFailOp);
        o.compareOp = compare_op(f.compare);
        o.compareMask = desc.stencil.readMask;
        o.writeMask = desc.stencil.writeMask;
        o.reference = 0;  // dynamic: set_pipeline sets it
    };
    face(desc.stencil.front, ds.front);
    face(desc.stencil.back, ds.back);
    ds.minDepthBounds = 0.0f;
    ds.maxDepthBounds = 1.0f;

    // Rasterizer
    VkPipelineRasterizationStateCreateInfo& r = out.raster;
    r.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    r.polygonMode = VK_POLYGON_MODE_FILL;
    r.cullMode = desc.cullMode == CullMode::Front  ? VK_CULL_MODE_FRONT_BIT
                 : desc.cullMode == CullMode::Back ? VK_CULL_MODE_BACK_BIT
                                                   : VK_CULL_MODE_NONE;
    r.frontFace = desc.faceWinding == FaceWinding::Ccw ? VK_FRONT_FACE_COUNTER_CLOCKWISE : VK_FRONT_FACE_CLOCKWISE;
    // Clamped (and truncated to whole units, as D3D12's integer bias) before use: a float past INT's range (or NaN)
    // does not convert.
    const float bias = std::isfinite(desc.depth.bias) ? std::clamp(desc.depth.bias, -2.0e9f, 2.0e9f) : 0.0f;
    const float slope = std::isfinite(desc.depth.biasSlopeScale) ? desc.depth.biasSlopeScale : 0.0f;
    r.depthBiasEnable = std::trunc(bias) != 0.0f || slope != 0.0f ? VK_TRUE : VK_FALSE;
    r.depthBiasConstantFactor = std::trunc(bias);
    r.depthBiasSlopeFactor = slope;
    r.depthBiasClamp = depthBiasClamp && std::isfinite(desc.depth.biasClamp) ? desc.depth.biasClamp : 0.0f;
    r.lineWidth = 1.0f;

    // Primitives
    VkPipelineInputAssemblyStateCreateInfo& ia = out.inputAssembly;
    ia.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    bool strip = false;
    switch (desc.primitiveType) {
        case PrimitiveType::Points: ia.topology = VK_PRIMITIVE_TOPOLOGY_POINT_LIST; break;
        case PrimitiveType::Lines: ia.topology = VK_PRIMITIVE_TOPOLOGY_LINE_LIST; break;
        case PrimitiveType::LineStrip:
            ia.topology = VK_PRIMITIVE_TOPOLOGY_LINE_STRIP;
            strip = true;
            break;
        case PrimitiveType::TriangleStrip:
            ia.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
            strip = true;
            break;
        default: ia.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST; break;
    }
    st.indexType = desc.indexType == IndexType::Default ? IndexType::None : desc.indexType;
    ia.primitiveRestartEnable = strip && st.indexType != IndexType::None ? VK_TRUE : VK_FALSE;

    VkPipelineMultisampleStateCreateInfo& ms = out.multisample;
    ms.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    ms.rasterizationSamples = VkSampleCountFlagBits(samples);
    ms.alphaToCoverageEnable = desc.alphaToCoverageEnabled ? VK_TRUE : VK_FALSE;

    VkPipelineColorBlendStateCreateInfo& cb = out.colorBlend;
    cb.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    cb.attachmentCount = std::uint32_t(colorCount);
    cb.pAttachments = colorCount > 0 ? out.blends : nullptr;

    out.vertexInput.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    out.vertexInput.vertexBindingDescriptionCount = std::uint32_t(out.bindings.size());
    out.vertexInput.pVertexBindingDescriptions = out.bindings.empty() ? nullptr : out.bindings.data();
    out.vertexInput.vertexAttributeDescriptionCount = std::uint32_t(out.attributes.size());
    out.vertexInput.pVertexAttributeDescriptions = out.attributes.empty() ? nullptr : out.attributes.data();
    out.viewport.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    out.viewport.viewportCount = 1;
    out.viewport.scissorCount = 1;
    out.dynamic.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    out.dynamic.dynamicStateCount = 4;
    out.dynamic.pDynamicStates = out.dynamicStates;

    out.pass.colorCount = colorCount;
    out.pass.samples = VkSampleCountFlagBits(samples);

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

    // The pipeline's key: every value of the state but the pointers (the code and the layout are keyed by the caller).
    KeyText& k = out.key;
    for (const VkVertexInputBindingDescription& d : out.bindings)
        for (std::uint64_t v : {std::uint64_t(d.binding), std::uint64_t(d.stride), std::uint64_t(d.inputRate)})
            k.add(v);
    k.add("|");
    for (const VkVertexInputAttributeDescription& e : out.attributes)
        for (std::uint64_t v :
             {std::uint64_t(e.location), std::uint64_t(e.binding), std::uint64_t(e.format), std::uint64_t(e.offset)})
            k.add(v);
    k.add("|");
    for (int i = 0; i < colorCount; ++i) {
        const VkPipelineColorBlendAttachmentState& bt = out.blends[i];
        for (std::uint64_t v : {std::uint64_t(bt.blendEnable), std::uint64_t(bt.srcColorBlendFactor),
                                std::uint64_t(bt.dstColorBlendFactor), std::uint64_t(bt.colorBlendOp),
                                std::uint64_t(bt.srcAlphaBlendFactor), std::uint64_t(bt.dstAlphaBlendFactor),
                                std::uint64_t(bt.alphaBlendOp), std::uint64_t(bt.colorWriteMask)})
            k.add(v);
    }
    k.add("|");
    auto stencil_key = [&](const VkStencilOpState& o) {
        for (std::uint64_t v : {std::uint64_t(o.failOp), std::uint64_t(o.passOp), std::uint64_t(o.depthFailOp),
                                std::uint64_t(o.compareOp), std::uint64_t(o.compareMask), std::uint64_t(o.writeMask)})
            k.add(v);
    };
    for (std::uint64_t v : {std::uint64_t(ds.depthTestEnable), std::uint64_t(ds.depthWriteEnable),
                            std::uint64_t(ds.depthCompareOp), std::uint64_t(ds.stencilTestEnable)})
        k.add(v);
    stencil_key(ds.front);
    stencil_key(ds.back);
    for (std::uint64_t v : {std::uint64_t(r.cullMode), std::uint64_t(r.frontFace), std::uint64_t(r.depthBiasEnable),
                            std::uint64_t(ia.topology), std::uint64_t(ia.primitiveRestartEnable),
                            std::uint64_t(ms.rasterizationSamples), std::uint64_t(ms.alphaToCoverageEnable)})
        k.add(v);
    k.add_float(r.depthBiasConstantFactor);
    k.add_float(r.depthBiasSlopeFactor);
    k.add_float(r.depthBiasClamp);
    k.add("|");
    k.add(out.pass.text().c_str());
    return {};
}

}  // namespace

VkPipeline VulkanDevice::pipeline_object(const std::string& key, const VkGraphicsPipelineCreateInfo* graphics,
                                         const VkComputePipelineCreateInfo* compute, std::string& error) {
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        if (auto it = pipelineObjects_.find(key); it != pipelineObjects_.end()) {
            ++pipelineHits_;
            return it->second;
        }
    }
    // Made without the lock: making a pipeline compiles the shaders for the GPU and may take milliseconds (the
    // VkPipelineCache is internally synchronized).
    VkPipeline made = VK_NULL_HANDLE;
    const VkResult r = graphics ? fn_.vkCreateGraphicsPipelines(device_, pipelineCache_, 1, graphics, nullptr, &made)
                                : fn_.vkCreateComputePipelines(device_, pipelineCache_, 1, compute, nullptr, &made);
    if (r != VK_SUCCESS || !made) {
        if (made) fn_.vkDestroyPipeline(device_, made, nullptr);
        error = std::string(graphics ? "vkCreateGraphicsPipelines" : "vkCreateComputePipelines") + " failed with " +
                result_text(r) +
                " (hint: the validation layer (VulkanOptions::validation) names the field; a shader whose SPIR-V "
                "bindings or vertex inputs differ from its ShaderDesc is refused here)";
        return VK_NULL_HANDLE;
    }
    set_name(VK_OBJECT_TYPE_PIPELINE, handle_bits(made), "fa-vulkan-pipeline");
    std::lock_guard<std::mutex> lock(cacheMutex_);
    auto [it, added] = pipelineObjects_.try_emplace(key, made);
    if (added) {
        ++pipelineMisses_;
    } else {
        ++pipelineHits_;  // another thread made the same one meanwhile: both are the same state, the first is kept
        fn_.vkDestroyPipeline(device_, made, nullptr);
    }
    return it->second;
}

Pipeline VulkanDevice::make_pipeline(const PipelineDesc& desc) {
    const std::string label = label_of(desc.label);
    std::string error;
    auto fail = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    std::shared_ptr<const ShaderInfo> shader;
    std::shared_ptr<const PipelineLayoutInfo> layout;
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
            VkComputePipelineCreateInfo c{};
            c.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
            c.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
            c.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
            c.stage.module = shader->cs;
            c.stage.pName = shader->csEntry.c_str();
            c.layout = layout->layout;
            st->pipeline = pipeline_object("compute|" + shader->codeKey + "|" + layout->key, nullptr, &c, e);
        } else {
            auto g = std::make_unique<GraphicsBuild>();
            e = graphics_desc(desc, *this, props_.limits, portability_, depthBiasClamp_, *st, *g);
            VkRenderPass pass = VK_NULL_HANDLE;
            if (e.empty()) pass = render_pass(g->pass, e);
            if (e.empty()) {
                for (int i = 0; i < 2; ++i) {
                    VkPipelineShaderStageCreateInfo& s = g->stages[i];
                    s.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
                    s.stage = i == 0 ? VK_SHADER_STAGE_VERTEX_BIT : VK_SHADER_STAGE_FRAGMENT_BIT;
                    s.module = i == 0 ? shader->vs : shader->fs;
                    s.pName = i == 0 ? shader->vsEntry.c_str() : shader->fsEntry.c_str();
                }
                VkGraphicsPipelineCreateInfo& gi = g->info;
                gi.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
                gi.stageCount = 2;
                gi.pStages = g->stages;
                gi.pVertexInputState = &g->vertexInput;
                gi.pInputAssemblyState = &g->inputAssembly;
                gi.pViewportState = &g->viewport;
                gi.pRasterizationState = &g->raster;
                gi.pMultisampleState = &g->multisample;
                gi.pDepthStencilState = &g->depthStencil;
                gi.pColorBlendState = &g->colorBlend;
                gi.pDynamicState = &g->dynamic;
                gi.layout = layout->layout;
                gi.renderPass = pass;
                gi.subpass = 0;
                st->pipeline =
                    pipeline_object("render|" + shader->codeKey + "|" + layout->key + "|" + g->key.s, &gi, nullptr, e);
            }
        }
        if (!st->pipeline) fail(e);
    }
    if (!error.empty()) report("gpu vulkan: make_pipeline '" + label + "': " + error);

    PipelineRecord rec;
    if (error.empty()) rec.state = std::move(st);
    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.state != nullptr;
    const std::uint32_t id = pipelines_.add(std::move(rec));
    if (id == 0) {
        report("gpu vulkan: make_pipeline '" + label + "': the pipeline pool is full (" +
               std::to_string(pipelines_.capacity()) +
               " pipelines) (hint: destroy pipelines you no longer use, or raise DeviceInit::pipelinePoolSize)");
        return {};
    }
    count_make(stats_.pipelines, ok);
    return Pipeline{id};
}

void VulkanDevice::destroy_pipeline(Pipeline pipeline) {
    if (!pipeline.valid()) return;
    PipelineRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!pipelines_.remove(pipeline.id, rec)) {
            report("gpu vulkan: destroy_pipeline: pipeline " + std::to_string(pipeline.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.pipelines);
    }
    // A list that set it holds its state until the list is reused; the VkPipeline stays in the cache for the device's
    // life (the state's last holder may let go of the shader modules: the record is released outside the lock).
}

ResourceState VulkanDevice::state(Pipeline pipeline) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const PipelineRecord* r = pipelines_.get(pipeline.id);
    if (!r) return ResourceState::Invalid;
    return r->state ? ResourceState::Valid : ResourceState::Failed;
}

std::shared_ptr<const PipelineState> VulkanDevice::pipeline_state(Pipeline pipeline) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const PipelineRecord* r = pipelines_.get(pipeline.id);
    return r ? r->state : nullptr;
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
