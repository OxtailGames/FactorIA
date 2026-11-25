// The Vulkan backend's command lists: opening and reusing them, render passes (recorded into secondary command buffers
// so their barriers go before the pass) and compute passes, pipelines, bindings, uniforms, draws and dispatches, layout
// and access tracking with automatic barriers, the transfers (write_buffer, write_image, the copies) and debug labels
// (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace fa::gpu::vk {

namespace {

// The rest of a level from `at` when `size` is 0 (sokol's ImageExtent rule).
std::uint32_t extent_or_rest(int size, int at, std::uint32_t level) {
    if (size > 0) return std::uint32_t(size);
    return at < 0 || std::uint32_t(at) >= level ? 0u : level - std::uint32_t(at);
}

constexpr SubState kUnused{kUnknownLayout, 0, 0};

// The Vulkan 1.0 stage mask of a synchronization2 one: the low 32 bits are the same, and each stage above them is
// mapped to the 1.0 stage that contains it.
VkPipelineStageFlags stages_1_0(VkPipelineStageFlags2 s) {
    auto out = VkPipelineStageFlags(s & 0xFFFFFFFFull);
    if (s & (VK_PIPELINE_STAGE_2_COPY_BIT | VK_PIPELINE_STAGE_2_RESOLVE_BIT | VK_PIPELINE_STAGE_2_BLIT_BIT |
             VK_PIPELINE_STAGE_2_CLEAR_BIT))
        out |= VK_PIPELINE_STAGE_TRANSFER_BIT;
    if (s & (VK_PIPELINE_STAGE_2_INDEX_INPUT_BIT | VK_PIPELINE_STAGE_2_VERTEX_ATTRIBUTE_INPUT_BIT))
        out |= VK_PIPELINE_STAGE_VERTEX_INPUT_BIT;
    if (s & VK_PIPELINE_STAGE_2_PRE_RASTERIZATION_SHADERS_BIT)
        out |= VK_PIPELINE_STAGE_VERTEX_SHADER_BIT;  // the engine has no tessellation or geometry shaders
    return out;
}

// The Vulkan 1.0 access mask of a synchronization2 one (the shader sampled and storage bits are above bit 31).
VkAccessFlags access_1_0(VkAccessFlags2 a) {
    auto out = VkAccessFlags(a & 0xFFFFFFFFull);
    if (a & (VK_ACCESS_2_SHADER_SAMPLED_READ_BIT | VK_ACCESS_2_SHADER_STORAGE_READ_BIT))
        out |= VK_ACCESS_SHADER_READ_BIT;
    if (a & VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT) out |= VK_ACCESS_SHADER_WRITE_BIT;
    return out;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Life
// ---------------------------------------------------------------------------------------------------------------------

VulkanCommandList::~VulkanCommandList() {
    if (pool_) device_.fn_.vkDestroyCommandPool(device_.device_, pool_, nullptr);  // frees its command buffers
}

Result<void> VulkanCommandList::create(const char* what) {
    const VkFunctions& f = device_.fn_;
    VkCommandPoolCreateInfo pi{};
    pi.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pi.flags = VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
    pi.queueFamilyIndex = device_.queues_[int(queue_)].family;
    VkResult r = f.vkCreateCommandPool(device_.device_, &pi, nullptr, &pool_);
    if (r != VK_SUCCESS) {
        pool_ = VK_NULL_HANDLE;
        return make_error(std::string("gpu vulkan: begin_commands('") + what + "'): vkCreateCommandPool failed with " +
                              result_text(r),
                          "the GPU ran out of memory or the device was lost");
    }
    VkCommandBufferAllocateInfo ai{};
    ai.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    ai.commandPool = pool_;
    ai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    ai.commandBufferCount = 2;
    VkCommandBuffer cmds[2] = {};
    r = f.vkAllocateCommandBuffers(device_.device_, &ai, cmds);
    if (r != VK_SUCCESS)
        return make_error(std::string("gpu vulkan: begin_commands('") + what +
                              "'): vkAllocateCommandBuffers failed with " + result_text(r),
                          "the GPU ran out of memory or the device was lost");
    cmd_ = cmds[0];
    fixup_ = cmds[1];
    device_.set_name(VK_OBJECT_TYPE_COMMAND_BUFFER, handle_bits(fixup_), "fa-vulkan-fixup");
    return {};
}

Result<void> VulkanCommandList::open(const char* label) {
    const VkFunctions& f = device_.fn_;
    VkResult r = f.vkResetCommandPool(device_.device_, pool_, 0);
    if (r == VK_SUCCESS) {
        VkCommandBufferBeginInfo bi{};
        bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        r = f.vkBeginCommandBuffer(cmd_, &bi);
    }
    if (r != VK_SUCCESS)
        return make_error(std::string("gpu vulkan: begin_commands('") + label +
                              "'): resetting a command list failed with " + result_text(r),
                          "the device was lost; the validation layer (VulkanOptions::validation) says why");
    label_ = label;
    if (!label_.empty()) device_.set_name(VK_OBJECT_TYPE_COMMAND_BUFFER, handle_bits(cmd_), label);
    open_ = true;
    internal_ = false;
    empty_ = true;
    debugDepth_ = 0;
    uses_.clear();
    useIndex_.clear();
    pending_.clear();
    keep_.clear();
    boundPipelines_.clear();
    for (std::uint64_t& w : waits_) w = 0;
    scopes_.clear();
    scopeOpen_ = false;
    timerSlot_ = -1;
    // The GPU finished the list's last commands: its secondaries and uniform sets can go (the framebuffers are the
    // device's, cached until one of their views is destroyed).
    secondaryNext_ = 0;
    uniformSets_.clear();
    clear_pass_state();
    return {};
}

// A call on a list that is not recording: report it (the dead list of a failed begin_commands() was reported then).
#define FA_VK_REQUIRE_OPEN(what)                                                                                       \
    do {                                                                                                               \
        if (!open_ || !cmd_) {                                                                                         \
            if (cmd_)                                                                                                  \
                device_.report(std::string("gpu vulkan: CommandList::") + what + " on list '" + label_ +               \
                               "', which was submitted (hint: take a new list with begin_commands() each frame)");     \
            return;                                                                                                    \
        }                                                                                                              \
    } while (false)

void VulkanCommandList::fail(const char* what, const std::string& error) {
    device_.report(std::string("gpu vulkan: CommandList::") + what + " in list '" + label_ + "': " + error);
}

void VulkanCommandList::reset_bind_state() {
    pipeline_.reset();
    uniformsSet_ = 0;
    bindingsSet_ = false;
    drawsFailed_ = false;
    setsDirty_ = 0;
    viewSet_ = VK_NULL_HANDLE;
    boundNeeds_.clear();
    boundNeedIndex_.clear();
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        uniformBuffer_[i] = VK_NULL_HANDLE;
        uniformOffset_[i] = 0;
    }
}

void VulkanCommandList::clear_pass_state() {
    passState_ = PassState::None;
    passFailed_ = false;
    passFormat_ = {};
    passColors_ = 0;
    passWidth_ = passHeight_ = 0;
    viewportEmpty_ = false;
    rec_ = VK_NULL_HANDLE;
    passHandle_ = VK_NULL_HANDLE;
    passFramebuffer_ = VK_NULL_HANDLE;
    passClears_.clear();
    passNeeds_.clear();
    passNeedIndex_.clear();
    passGroups_.clear();
    passOuterPops_ = 0;
    reset_bind_state();
}

// A timed scope: a timestamp in the open timed frame's query pool at each end (vulkan_timers.cpp reads them), written
// where the list records now (inside a render pass, its secondary command buffer). Outside a timed frame, past its
// kMaxTimedScopes scopes or on a device that cannot time, nothing is recorded. Nor on a list of another queue than
// Graphics: the frame's query pool is reset and read on the graphics queue, timestamps compare only within one queue,
// and a family may have none (timestampValidBits 0); such a scope is accepted and measures nothing.
void VulkanCommandList::begin_timed_scope(const char* name) {
    FA_VK_REQUIRE_OPEN("begin_timed_scope");
    if (scopeOpen_) close_scope();  // scopes do not nest
    if (queue_ != QueueKind::Graphics || device_.queues_[int(queue_)].timestampBits == 0) return;
    ScopeRef ref;
    {
        std::lock_guard<std::mutex> lock(device_.timerMutex_);
        if (!device_.timerOk_ || device_.timerCurrent_ < 0) return;
        VulkanDevice::TimerSlot& slot = device_.timerSlots_[std::size_t(device_.timerCurrent_)];
        if (slot.names.size() >= std::size_t(VulkanDevice::kMaxTimedScopes)) return;  // drawn, not measured
        ref.serial = slot.serial;
        ref.slot = device_.timerCurrent_;
        ref.scope = std::uint32_t(slot.names.size());
        ref.pool = slot.pool;
        ref.inPass = rec_ != VK_NULL_HANDLE;
        slot.names.emplace_back(name ? name : "");
        slot.submitted.push_back(false);
    }
    device_.fn_.vkCmdWriteTimestamp(recording(), VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, ref.pool, 2 + 2 * ref.scope);
    empty_ = false;
    scopes_.push_back(ref);
    scopeOpen_ = true;
}

void VulkanCommandList::end_timed_scope() {
    FA_VK_REQUIRE_OPEN("end_timed_scope");
    if (scopeOpen_) close_scope();
}

void VulkanCommandList::close_scope() {
    scopeOpen_ = false;
    if (scopes_.empty() || !cmd_) return;
    ScopeRef& ref = scopes_.back();
    if (rec_) ref.inPass = true;
    device_.fn_.vkCmdWriteTimestamp(recording(), VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, ref.pool, 3 + 2 * ref.scope);
}

namespace {

const char* view_type_name(ViewType t) {
    switch (t) {
        case ViewType::StorageBuffer: return "storage buffer";
        case ViewType::StorageImage: return "storage image";
        case ViewType::Texture: return "texture";
        case ViewType::ColorAttachment: return "colour attachment";
        case ViewType::ResolveAttachment: return "resolve attachment";
        case ViewType::DepthStencilAttachment: return "depth-stencil attachment";
        default: return "invalid";
    }
}

std::string target_format_text(const TargetFormat& f) {
    std::string s = std::string("colour ") + pixel_format_name(f.color);
    if (f.color1 != PixelFormat::None) s += std::string(", colour1 ") + pixel_format_name(f.color1);
    return s + ", depth " + pixel_format_name(f.depth) + ", " + std::to_string(f.samples) + " sample(s)";
}

VkAttachmentLoadOp load_op(LoadAction a) {
    switch (a) {
        case LoadAction::Load: return VK_ATTACHMENT_LOAD_OP_LOAD;
        case LoadAction::DontCare: return VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        default: return VK_ATTACHMENT_LOAD_OP_CLEAR;  // Clear, and Default (sokol's default clears)
    }
}

// Colour is stored by default, depth and stencil are not (sokol's defaults).
VkAttachmentStoreOp store_op(StoreAction a, bool color) {
    if (a == StoreAction::Store) return VK_ATTACHMENT_STORE_OP_STORE;
    if (a == StoreAction::DontCare) return VK_ATTACHMENT_STORE_OP_DONT_CARE;
    return color ? VK_ATTACHMENT_STORE_OP_STORE : VK_ATTACHMENT_STORE_OP_DONT_CARE;
}

// What a shader's texture or storage image of `t` needs the view to be.
VkImageViewType view_type_for(ImageType t) {
    switch (t) {
        case ImageType::Cube: return VK_IMAGE_VIEW_TYPE_CUBE;
        case ImageType::Tex3d: return VK_IMAGE_VIEW_TYPE_3D;
        case ImageType::Array: return VK_IMAGE_VIEW_TYPE_2D_ARRAY;
        default: return VK_IMAGE_VIEW_TYPE_2D;
    }
}

const char* view_kind_name(VkImageViewType t) {
    switch (t) {
        case VK_IMAGE_VIEW_TYPE_2D: return "2D";
        case VK_IMAGE_VIEW_TYPE_CUBE: return "cube";
        case VK_IMAGE_VIEW_TYPE_3D: return "3D";
        case VK_IMAGE_VIEW_TYPE_2D_ARRAY: return "array";
        default: return "other";
    }
}

// How a pass uses a subresource in `layout` (the conflict error names both uses).
const char* layout_use(VkImageLayout layout) {
    switch (layout) {
        case VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL: return "a colour or resolve attachment";
        case VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL: return "a depth attachment";
        case VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL: return "a texture";
        case VK_IMAGE_LAYOUT_GENERAL: return "a storage image";
        default: return "a buffer";
    }
}

// "gpu vulkan: " is said once, by fail().
std::string without_prefix(const std::string& s) {
    const std::string prefix = "gpu vulkan: ";
    return s.compare(0, prefix.size(), prefix) == 0 ? s.substr(prefix.size()) : s;
}

constexpr SubState kColorAttachmentState{
    VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT};
constexpr SubState kDepthAttachmentState{
    VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT | VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
    VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT | VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT};
constexpr SubState kVertexBufferState{VK_IMAGE_LAYOUT_UNDEFINED, VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT,
                                      VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT};
constexpr SubState kIndexBufferState{VK_IMAGE_LAYOUT_UNDEFINED, VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT,
                                     VK_ACCESS_2_INDEX_READ_BIT};

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Passes
// ---------------------------------------------------------------------------------------------------------------------

bool VulkanCommandList::need(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip, std::uint32_t mipCount,
                             std::uint32_t layer, std::uint32_t layerCount, const SubState& state, std::string& error) {
    if (!t) return true;
    for (std::uint32_t l = layer; l < layer + layerCount && l < t->layers; ++l)
        for (std::uint32_t m = mip; m < mip + mipCount && m < t->mips; ++m) {
            const std::uint32_t sub = t->subresource(m, l);
            // A render pass merges what its attachments and every draw need; a compute pass what one set_bindings
            // binds (each dispatch applies it). One subresource in two layouts cannot be: a descriptor would see the
            // wrong one.
            const bool compute = passState_ == PassState::Compute;
            std::vector<Need>& needs = compute ? boundNeeds_ : passNeeds_;
            auto& index = compute ? boundNeedIndex_ : passNeedIndex_;
            auto [it, added] = index.try_emplace({t.get(), sub}, needs.size());
            if (added) {
                needs.push_back({t, sub, state});
                continue;
            }
            Need& n = needs[it->second];
            if (n.state.layout != state.layout) {
                error = std::string("mip ") + std::to_string(m) + " of layer " + std::to_string(l) + " is used as " +
                        layout_use(n.state.layout) + " and as " + layout_use(state.layout) +
                        (compute ? " in the same dispatch (hint: a texture view and a storage image view of one "
                                   "subresource cannot be bound together; bind another mip or layer, read the storage "
                                   "image in the shader instead of a texture, or copy the image)"
                                 : " in the same pass (hint: an image is drawn into in one pass and read in a later "
                                   "one; read another mip or layer, or a copy)");
                return false;
            }
            n.state.stages |= state.stages;
            n.state.access |= state.access;
        }
    return true;
}

VkCommandBuffer VulkanCommandList::next_secondary(std::string& error) {
    if (secondaryNext_ == secondaries_.size()) {
        VkCommandBufferAllocateInfo ai{};
        ai.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
        ai.commandPool = pool_;
        ai.level = VK_COMMAND_BUFFER_LEVEL_SECONDARY;
        ai.commandBufferCount = 1;
        VkCommandBuffer c = VK_NULL_HANDLE;
        const VkResult r = device_.fn_.vkAllocateCommandBuffers(device_.device_, &ai, &c);
        if (r != VK_SUCCESS) {
            error = "vkAllocateCommandBuffers (the pass's secondary command buffer) failed with " + result_text(r) +
                    " (hint: the GPU ran out of memory or the device was lost)";
            return VK_NULL_HANDLE;
        }
        secondaries_.push_back(c);
    }
    return secondaries_[secondaryNext_++];
}

void VulkanCommandList::begin_pass(const PassDesc& pass) {
    FA_VK_REQUIRE_OPEN("begin_pass");
    if (passState_ != PassState::None) {
        fail("begin_pass", "a pass is open already (hint: end_pass() first; passes do not nest)");
        return;
    }
    // From here on the pass is open, even when it fails (end_pass then closes it and its commands are skipped).
    clear_pass_state();
    passState_ = PassState::Render;
    passFailed_ = true;
    if (queue_ != QueueKind::Graphics) {
        fail("begin_pass", std::string("the list runs on the ") + queue_name(queue_) +
                               " queue, which has no render passes (hint: record render passes on a "
                               "QueueKind::Graphics list; the pass's commands are skipped)");
        return;
    }
    passFormat_ = pass.format;
    const std::string passName = std::string("pass '") + (pass.label && *pass.label ? pass.label : "(no label)") + "'";
    if (pass.swapchain) {
        // A pass into the window is a pass into the views of the swapchain's images (the acquired one, its depth and
        // MSAA images), checked below like any other.
        PassDesc views;
        const std::string error = device_.swapchain_pass(pass, views);
        if (!error.empty()) {
            fail("begin_pass", passName + ": " + error);
            return;
        }
        passState_ = PassState::None;
        begin_pass(views);
        return;
    }

    struct Attachment {
        std::shared_ptr<TrackedResource> t;
        VkImageView view = VK_NULL_HANDLE;
        PixelFormat format = PixelFormat::None;
        int samples = 1;
        std::uint32_t width = 0, height = 0;
        std::uint32_t mip = 0, layer = 0;  // layer 0 for a 3D image (its slice is a depth slice)
        std::uint64_t serial = 0;          // the view's (what the framebuffer cache knows it by)
        std::uint64_t id = 0;              // the View handle
        bool bound = false;
    };
    Attachment color, color1, resolve, depth;
    std::string error;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        auto look = [&](View v, ViewType type, const char* what, Attachment& a) {
            if (!error.empty() || v.id == 0) return;
            const VulkanDevice::ViewRecord* r = device_.views_.get(v.id);
            const VulkanDevice::ImageRecord* im = r ? device_.images_.get(r->image.id) : nullptr;
            if (!r || !r->tracked || !r->view || !im || !im->tracked) {
                error = std::string(what) + " (view " + std::to_string(v.id) +
                        ") is not a live view of a live image (hint: views die with destroy_view, and a view whose "
                        "image was destroyed cannot be drawn into)";
                return;
            }
            if (r->type != type) {
                error = std::string(what) + " is a " + view_type_name(r->type) +
                        " view (hint: make it with ViewDesc::" +
                        (type == ViewType::ColorAttachment     ? "colorAttachment"
                         : type == ViewType::ResolveAttachment ? "resolveAttachment"
                                                               : "depthStencilAttachment") +
                        ")";
                return;
            }
            a.t = r->tracked;
            a.view = r->view;
            a.format = im->format;
            a.samples = im->samples;
            a.width = mip_extent(im->width, r->mip);
            a.height = mip_extent(im->height, r->mip);
            a.mip = std::uint32_t(r->mip);
            a.layer = im->type == ImageType::Tex3d ? 0u : std::uint32_t(r->slice);
            a.serial = r->serial;
            a.id = v.id;
            a.bound = true;
        };
        look(pass.color, ViewType::ColorAttachment, "the colour attachment (PassDesc::color)", color);
        look(pass.color1, ViewType::ColorAttachment, "colour attachment 1 (PassDesc::color1)", color1);
        look(pass.resolve, ViewType::ResolveAttachment, "the resolve attachment (PassDesc::resolve)", resolve);
        look(pass.depth, ViewType::DepthStencilAttachment, "the depth attachment (PassDesc::depth)", depth);
    }
    if (error.empty() && !color.bound && !depth.bound)
        error = "it has no attachment (hint: set PassDesc::color or PassDesc::depth to a view)";
    if (error.empty() && color1.bound && !color.bound)
        error = "it has colour attachment 1 without colour attachment 0 (hint: PassDesc::color first)";
    if (error.empty() && resolve.bound && !color.bound)
        error = "it resolves (PassDesc::resolve) without a colour attachment to resolve";
    const Attachment& first = color.bound ? color : depth;
    if (error.empty()) {
        for (const Attachment* a : {&color1, &resolve, &depth})
            if (a->bound && (a->width != first.width || a->height != first.height))
                error = "its attachments differ in size (" + std::to_string(first.width) + "x" +
                        std::to_string(first.height) + " and " + std::to_string(a->width) + "x" +
                        std::to_string(a->height) + ") (hint: every attachment of a pass has the same size)";
    }
    if (error.empty() && resolve.bound && (color.samples < 2 || resolve.format != color.format))
        error = std::string("it resolves a colour attachment that ") +
                (color.samples < 2 ? "is not multisampled" : "has another format than the resolve attachment") +
                " (hint: a resolve takes a multisampled colour attachment into a single-sampled image of its format)";
    TargetFormat expected;
    expected.color = color.bound ? color.format : PixelFormat::None;
    expected.color1 = color1.bound ? color1.format : PixelFormat::None;
    expected.depth = depth.bound ? depth.format : PixelFormat::None;
    expected.samples = first.samples;
    if (error.empty() && pass.format != expected)
        error = "PassDesc::format (" + target_format_text(pass.format) + ") is not what its attachments are (" +
                target_format_text(expected) +
                ") (hint: set format to the attachments' formats and sample count; the pipelines drawn in it must "
                "match it)";
    if (error.empty() && color1.bound && color1.samples != color.samples)
        error = "its colour attachments differ in sample count";
    if (error.empty() && depth.bound && color.bound && depth.samples != color.samples)
        error = "its depth attachment has " + std::to_string(depth.samples) + " sample(s), its colour attachment " +
                std::to_string(color.samples);
    if (!error.empty()) {
        fail("begin_pass", passName + ": " + error);
        return;
    }

    // The render pass (attachments in the order color, color1, depth, resolve) and its clear values.
    RenderPassKey key;
    key.samples = VkSampleCountFlagBits(first.samples);
    std::vector<VkImageView> views;
    std::vector<std::uint64_t> serials;  // views' serials, in the same order
    std::vector<std::uint64_t> ids;      // and their View handles
    for (const Attachment* a : {&color, &color1}) {
        if (!a->bound) continue;
        const Color& c = a == &color ? pass.clearColor : pass.clearColor1;
        VkClearValue v{};
        v.color.float32[0] = c.r;
        v.color.float32[1] = c.g;
        v.color.float32[2] = c.b;
        v.color.float32[3] = c.a;
        passClears_.push_back(v);
        key.color[key.colorCount++] = device_.vk_format(a->format);
        views.push_back(a->view);
        serials.push_back(a->serial);
        ids.push_back(a->id);
    }
    key.colorLoad = load_op(pass.colorLoad);
    key.colorStore = store_op(pass.colorStore, true);
    if (depth.bound) {
        const bool stencil = (format_info(depth.format).aspects & VK_IMAGE_ASPECT_STENCIL_BIT) != 0;
        key.depth = device_.vk_format(depth.format);
        key.depthLoad = load_op(pass.depthLoad);
        key.depthStore = store_op(pass.depthStore, false);
        if (stencil) {
            key.stencilLoad = load_op(pass.stencilLoad);
            key.stencilStore = store_op(pass.stencilStore, false);
        }
        VkClearValue v{};
        v.depthStencil.depth = std::isfinite(pass.clearDepth) ? std::clamp(pass.clearDepth, 0.0f, 1.0f) : 1.0f;
        v.depthStencil.stencil = 0;
        passClears_.push_back(v);
        views.push_back(depth.view);
        serials.push_back(depth.serial);
        ids.push_back(depth.id);
    }
    if (resolve.bound) {
        key.resolve = device_.vk_format(resolve.format);
        passClears_.push_back(VkClearValue{});
        views.push_back(resolve.view);
        serials.push_back(resolve.serial);
        ids.push_back(resolve.id);
    }
    const VkRenderPass renderPass = device_.render_pass(key, error);
    if (!renderPass) {
        fail("begin_pass", passName + ": " + error);
        return;
    }
    const VkFunctions& f = device_.fn_;
    // The device's framebuffer of these views and this pass (made on first use, destroyed with one of the views).
    const VkFramebuffer framebuffer =
        device_.framebuffer(renderPass, views, serials, ids, first.width, first.height, error);
    if (!framebuffer) {
        // A failure that already carries its own hint (a view destroyed meanwhile) keeps it.
        const bool hinted = error.find("(hint:") != std::string::npos;
        fail("begin_pass",
             passName + ": " + error + (hinted ? "" : " (hint: the GPU ran out of memory or the device was lost)"));
        return;
    }
    VkResult r = VK_SUCCESS;

    // What the attachments need before the pass begins.
    for (const Attachment* a : {&color, &color1, &resolve}) {
        if (a->bound && !need(a->t, a->mip, 1, a->layer, 1, kColorAttachmentState, error)) break;
    }
    if (error.empty() && depth.bound) need(depth.t, depth.mip, 1, depth.layer, 1, kDepthAttachmentState, error);
    if (!error.empty()) {
        fail("begin_pass", passName + ": " + error);
        return;
    }

    // The pass's commands go into a secondary command buffer, executed inside the render pass at end_pass, so the
    // barriers its draws need can still be recorded before the pass begins.
    VkCommandBuffer sec = next_secondary(error);
    if (!sec) {
        fail("begin_pass", passName + ": " + error);
        return;
    }
    VkCommandBufferInheritanceInfo inh{};
    inh.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
    inh.renderPass = renderPass;
    inh.subpass = 0;
    inh.framebuffer = framebuffer;
    VkCommandBufferBeginInfo bi{};
    bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    bi.flags = VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT | VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    bi.pInheritanceInfo = &inh;
    r = f.vkBeginCommandBuffer(sec, &bi);
    if (r != VK_SUCCESS) {
        fail("begin_pass", passName + ": vkBeginCommandBuffer (the pass's secondary command buffer) failed with " +
                               result_text(r) + " (hint: the GPU ran out of memory or the device was lost)");
        return;
    }
    if (pass.label && *pass.label) device_.set_name(VK_OBJECT_TYPE_COMMAND_BUFFER, handle_bits(sec), pass.label);
    rec_ = sec;
    passHandle_ = renderPass;
    passFramebuffer_ = framebuffer;
    passWidth_ = first.width;
    passHeight_ = first.height;
    passColors_ = key.colorCount;
    // The whole pass, y up as on the other backends (a negative viewport height flips Vulkan's y down).
    const VkViewport vp{0.0f, float(passHeight_), float(passWidth_), -float(passHeight_), 0.0f, 1.0f};
    f.vkCmdSetViewport(rec_, 0, 1, &vp);
    const VkRect2D all{{0, 0}, {passWidth_, passHeight_}};
    f.vkCmdSetScissor(rec_, 0, 1, &all);
    passFailed_ = false;
    empty_ = false;
}

void VulkanCommandList::begin_compute_pass(const char* label) {
    FA_VK_REQUIRE_OPEN("begin_compute_pass");
    if (passState_ != PassState::None) {
        fail("begin_compute_pass", std::string("compute pass '") + (label ? label : "") +
                                       "': a pass is open already (hint: end_pass() first; passes do not nest)");
        return;
    }
    clear_pass_state();
    passState_ = PassState::Compute;
    if (queue_ == QueueKind::Transfer) {
        passFailed_ = true;  // open, so end_pass() closes it; its commands are skipped
        fail("begin_compute_pass", std::string("compute pass '") + (label ? label : "") +
                                       "': the list runs on the transfer queue, which has no compute passes (hint: "
                                       "record compute passes on a QueueKind::Compute or Graphics list)");
    }
}

void VulkanCommandList::end_pass() {
    FA_VK_REQUIRE_OPEN("end_pass");
    if (passState_ == PassState::None) {
        fail("end_pass", "no pass is open (hint: one end_pass() per begin_pass() or begin_compute_pass())");
        return;
    }
    bool executed = false;  // the pass's secondary ended and runs inside the list
    if (passState_ == PassState::Render && !passFailed_ && rec_) {
        const VkFunctions& f = device_.fn_;
        // Labels must close in the command buffer that opened them: the groups opened in the pass and still open
        // end in the secondary and open again on the list after the pass.
        if (f.vkCmdEndDebugUtilsLabelEXT)
            for (std::size_t i = 0; i < passGroups_.size(); ++i) f.vkCmdEndDebugUtilsLabelEXT(rec_);
        const VkResult r = f.vkEndCommandBuffer(rec_);
        executed = r == VK_SUCCESS;
        if (r != VK_SUCCESS) {
            fail("end_pass", "recording the pass failed with " + result_text(r) +
                                 " (hint: the validation layer (VulkanOptions::validation) says which command was "
                                 "wrong)");
        } else {
            for (const Need& n : passNeeds_) require(n.res, n.sub, n.state);
            flush_barriers();
            VkRenderPassBeginInfo bi{};
            bi.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
            bi.renderPass = passHandle_;
            bi.framebuffer = passFramebuffer_;
            bi.renderArea = {{0, 0}, {passWidth_, passHeight_}};
            bi.clearValueCount = std::uint32_t(passClears_.size());
            bi.pClearValues = passClears_.data();
            f.vkCmdBeginRenderPass(cmd_, &bi, VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS);
            f.vkCmdExecuteCommands(cmd_, 1, &rec_);
            f.vkCmdEndRenderPass(cmd_);
            empty_ = false;
        }
        // The pops of groups opened before the pass, then the groups opened in it again.
        if (f.vkCmdEndDebugUtilsLabelEXT)
            for (int i = 0; i < passOuterPops_; ++i) f.vkCmdEndDebugUtilsLabelEXT(cmd_);
        if (f.vkCmdBeginDebugUtilsLabelEXT)
            for (const std::string& g : passGroups_) {
                VkDebugUtilsLabelEXT l{};
                l.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT;
                l.pLabelName = g.c_str();
                f.vkCmdBeginDebugUtilsLabelEXT(cmd_, &l);
            }
    }
    // A timestamp recorded in a secondary that did not end, or that a failed pass never executes, never runs: its scope
    // is not reported. Whatever path the pass took, no scope stays "in the pass" after it.
    for (ScopeRef& sc : scopes_) {
        if (sc.inPass && !executed) sc.lost = true;
        sc.inPass = false;
    }
    clear_pass_state();
}

// ---------------------------------------------------------------------------------------------------------------------
// Pipelines, bindings, uniforms
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::set_pipeline(Pipeline pipeline) {
    FA_VK_REQUIRE_OPEN("set_pipeline");
    if (passState_ == PassState::None) {
        fail("set_pipeline", "outside a pass (hint: begin_pass() or begin_compute_pass() first)");
        return;
    }
    reset_bind_state();
    if (passFailed_) return;
    std::shared_ptr<const PipelineState> st = device_.pipeline_state(pipeline);
    std::string error;
    if (!st)
        error = "pipeline " + std::to_string(pipeline.id) +
                " is not a live pipeline, or its creation failed (make_pipeline reported why in errors())";
    else if (st->compute != (passState_ == PassState::Compute))
        error = "pipeline '" + st->label + "' is a " + (st->compute ? "compute" : "render") + " pipeline inside a " +
                (passState_ == PassState::Compute ? "compute" : "render") +
                " pass (hint: compute pipelines go in begin_compute_pass(), render pipelines in begin_pass())";
    else if (!st->compute && (st->format != passFormat_ || st->colorCount != passColors_))
        error = "pipeline '" + st->label + "' draws into " + target_format_text(st->format) + " with " +
                std::to_string(st->colorCount) + " colour target(s), the pass has " + target_format_text(passFormat_) +
                " with " + std::to_string(passColors_) +
                " (hint: a pipeline's colour targets, depth format and sampleCount must equal its pass's)";
    if (!error.empty()) {
        drawsFailed_ = true;
        fail("set_pipeline", error);
        return;
    }
    const VkFunctions& f = device_.fn_;
    const VkCommandBuffer c = recording();
    const VkPipelineBindPoint point = st->compute ? VK_PIPELINE_BIND_POINT_COMPUTE : VK_PIPELINE_BIND_POINT_GRAPHICS;
    f.vkCmdBindPipeline(c, point, st->pipeline);
    // The list holds the state until it is submitted (or dropped): destroy_pipeline() and wait_idle() cannot free the
    // VkPipeline its command buffer names before it runs.
    boundPipelines_.insert(st);
    if (!st->compute) {
        f.vkCmdSetBlendConstants(c, st->blendColor);
        f.vkCmdSetStencilReference(c, VK_STENCIL_FACE_FRONT_AND_BACK, st->stencilRef);
    }
    pipeline_ = std::move(st);
    setsDirty_ = 0b111;  // ready_to_run binds sets 0, 1 and 2 (bindless) with this pipeline's layout
    empty_ = false;
}

void VulkanCommandList::set_bindings(const Bindings& b) {
    FA_VK_REQUIRE_OPEN("set_bindings");
    if (passFailed_ || drawsFailed_) return;
    if (!pipeline_) {
        fail("set_bindings", "no pipeline is set (hint: set_pipeline() first, inside a pass)");
        return;
    }
    const PipelineState& st = *pipeline_;
    const ShaderInfo& sh = *st.shader;
    const PipelineLayoutInfo& lay = *st.layout;
    struct BoundBuffer {
        std::shared_ptr<TrackedResource> t;
        VkDeviceSize offset = 0;
    };
    struct BoundView {
        std::shared_ptr<TrackedResource> t;
        VkImageView view = VK_NULL_HANDLE;
        VkDeviceSize offset = 0;             // storage buffers
        VkDeviceSize range = VK_WHOLE_SIZE;  // storage buffers: at most maxStorageBufferRange bytes
        ViewType type = ViewType::Invalid;
        std::uint32_t mip = 0, mipCount = 1, slice = 0, sliceCount = 1;
        bool writable = false;
    };
    BoundBuffer vbs[kMaxVertexBuffers];
    BoundBuffer ib;
    BoundView views[kMaxViews];
    VkSampler samplers[kMaxSamplers]{};
    std::string error;
    auto bad = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    const std::string shaderName = "shader '" + sh.label + "'";
    const VkPhysicalDeviceLimits& limits = device_.props_.limits;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        auto buffer = [&](Buffer buf, int offset, bool wanted, bool usageOk, const char* what, const char* usage,
                          BoundBuffer& out) {
            if (!wanted) {
                if (buf.id != 0)
                    bad(std::string(what) + " is bound and pipeline '" + st.label +
                        "' reads nothing there (hint: bind only the slots its vertex layout or index type uses)");
                return;
            }
            const VulkanDevice::BufferRecord* r = device_.buffers_.get(buf.id);
            if (buf.id == 0) {
                bad(std::string(what) + " is empty and pipeline '" + st.label + "' reads it");
            } else if (!r || !r->tracked) {
                bad(std::string(what) + " (buffer " + std::to_string(buf.id) + ") is not a live buffer");
            } else if (!usageOk) {
                bad(std::string(what) + " is buffer '" + r->label + "', which was not made with BufferUsage::" + usage);
            } else if (offset < 0 || std::size_t(offset) >= r->size) {
                bad(std::string(what) + "'s offset " + std::to_string(offset) + " is outside buffer '" + r->label +
                    "''s " + std::to_string(r->size) + " bytes");
            } else {
                out.t = r->tracked;
                out.offset = VkDeviceSize(offset);
            }
        };
        for (int i = 0; i < kMaxVertexBuffers; ++i) {
            const VulkanDevice::BufferRecord* r = device_.buffers_.get(b.vertexBuffers[i].id);
            const std::string what = "vertex buffer slot " + std::to_string(i);
            // BufferUsage: a buffer with none of vertexBuffer, indexBuffer, storageBuffer and the staging bits is a
            // vertex buffer (make_buffer gives it the vertex usage).
            const bool vertexUsage =
                r && (r->usage.vertexBuffer || !(r->usage.indexBuffer || r->usage.storageBuffer ||
                                                 r->usage.stagingBuffer || r->usage.stagingIndexBuffer));
            buffer(b.vertexBuffers[i], b.vertexBufferOffsets[i], (st.buffersUsed >> i) & 1u, vertexUsage, what.c_str(),
                   "vertexBuffer", vbs[i]);
        }
        {
            const VulkanDevice::BufferRecord* r = device_.buffers_.get(b.indexBuffer.id);
            buffer(b.indexBuffer, b.indexBufferOffset, st.indexType != IndexType::None, r && r->usage.indexBuffer,
                   "the index buffer", "indexBuffer", ib);
            const VkDeviceSize indexBytes = st.indexType == IndexType::Uint16 ? 2u : 4u;
            if (ib.t && ib.offset % indexBytes != 0)
                bad("the index buffer's offset " + std::to_string(ib.offset) +
                    " is not a multiple of the index size (" + std::to_string(indexBytes) + " bytes)");
        }
        for (int i = 0; i < kMaxViews && error.empty(); ++i) {
            const ViewType want = sh.viewType[i];
            const View v = b.views[i];
            const std::string what = "view slot " + std::to_string(i);
            if (want == ViewType::Invalid) {
                if (v.id != 0) bad(what + " is bound and " + shaderName + " declares nothing there");
                continue;
            }
            const VulkanDevice::ViewRecord* r = device_.views_.get(v.id);
            const bool image = want != ViewType::StorageBuffer;
            if (v.id == 0) {
                bad(what + " is empty and " + shaderName + " declares a " + view_type_name(want) + " there");
            } else if (!r || !r->tracked || (image && r->type != ViewType::StorageBuffer && !r->view)) {
                bad(what + " (view " + std::to_string(v.id) + ") is not a live view");
            } else if (r->type != want) {
                bad(what + " is a " + view_type_name(r->type) + " view and " + shaderName + " declares a " +
                    view_type_name(want) + " there");
            } else if (image && r->viewType != view_type_for(sh.viewImageType[i])) {
                bad(what + " is a " + view_kind_name(r->viewType) + " view and " + shaderName + " declares a " +
                    view_kind_name(view_type_for(sh.viewImageType[i])) + " " + view_type_name(want) +
                    " there (hint: view an image of the type the shader samples: a 2D image for texture2D, a cube "
                    "image for textureCube, an array image for texture2DArray, a 3D image for texture3D)");
            } else if (!image && limits.minStorageBufferOffsetAlignment > 0 &&
                       r->offset % limits.minStorageBufferOffsetAlignment != 0) {
                bad(what + "'s storage buffer view starts at byte " + std::to_string(r->offset) +
                    ", which is not a multiple of this GPU's minStorageBufferOffsetAlignment (" +
                    std::to_string(limits.minStorageBufferOffsetAlignment) +
                    ") (hint: start storage buffer views at multiples of 256 bytes, which every GPU accepts)");
            } else {
                BoundView& out = views[i];
                out.t = r->tracked;
                out.view = r->view;
                out.offset = VkDeviceSize(r->offset);
                if (r->type == ViewType::StorageBuffer)
                    if (const VulkanDevice::BufferRecord* buf = device_.buffers_.get(r->buffer.id))
                        // the rest of the buffer, or the most one descriptor may see (128 MiB on Mali)
                        out.range =
                            storage_buffer_range(align_up(buf->size, 16), r->offset, limits.maxStorageBufferRange);
                out.type = r->type;
                out.writable = sh.viewWritable[i];
                out.mip = std::uint32_t(r->mip);
                out.mipCount = std::uint32_t(r->mipCount);
                out.slice = std::uint32_t(r->slice);
                out.sliceCount = std::uint32_t(r->sliceCount);
            }
        }
        for (int i = 0; i < kMaxSamplers && error.empty(); ++i) {
            const bool wanted = (lay.samplerUsed >> i) & 1u;
            const Sampler s = b.samplers[i];
            const std::string what = "sampler slot " + std::to_string(i);
            if (!wanted) {
                if (s.id != 0) bad(what + " is bound and " + shaderName + " declares nothing there");
                continue;
            }
            const VulkanDevice::SamplerRecord* r = device_.samplers_.get(s.id);
            if (s.id == 0)
                bad(what + " is empty and " + shaderName + " declares a sampler there");
            else if (!r || !r->sampler)
                bad(what + " (sampler " + std::to_string(s.id) + ") is not a live sampler");
            else
                samplers[i] = r->sampler;
        }
    }
    if (!error.empty()) {
        drawsFailed_ = true;
        fail("set_bindings", error);
        return;
    }

    // What the views and buffers need: before the render pass begins, or before each dispatch.
    if (passState_ == PassState::Compute) {
        boundNeeds_.clear();
        boundNeedIndex_.clear();
    }
    for (int i = 0; i < kMaxViews && error.empty(); ++i) {
        const BoundView& v = views[i];
        if (!v.t) continue;
        const VkPipelineStageFlags2 stage = lay.viewStage[i];
        const bool flat = v.t->layers == 1;  // a 3D image or a buffer: one layer
        const std::uint32_t layer = flat ? 0u : v.slice, layers = flat ? 1u : v.sliceCount;
        const VkAccessFlags2 access = VK_ACCESS_2_SHADER_READ_BIT | (v.writable ? VK_ACCESS_2_SHADER_WRITE_BIT : 0);
        if (v.type == ViewType::StorageBuffer)
            need(v.t, 0, 1, 0, 1, {VK_IMAGE_LAYOUT_UNDEFINED, stage, access}, error);
        else if (v.type == ViewType::StorageImage)
            need(v.t, v.mip, 1, layer, layers, {VK_IMAGE_LAYOUT_GENERAL, stage, access}, error);
        else
            need(v.t, v.mip, v.mipCount, layer, layers,
                 {VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, stage, VK_ACCESS_2_SHADER_READ_BIT}, error);
        if (!error.empty()) error = "view slot " + std::to_string(i) + ": " + error;
    }
    for (int i = 0; i < kMaxVertexBuffers && error.empty(); ++i)
        if (vbs[i].t) need(vbs[i].t, 0, 1, 0, 1, kVertexBufferState, error);
    if (error.empty() && ib.t) need(ib.t, 0, 1, 0, 1, kIndexBufferState, error);
    if (!error.empty()) {
        drawsFailed_ = true;
        fail("set_bindings", error);
        return;
    }

    // Set 1: the views and samplers, written into a set of this frame's descriptor pool.
    const VkFunctions& f = device_.fn_;
    const VkCommandBuffer c = recording();
    if (lay.hasSet[1]) {
        Result<VkDescriptorSet> set = device_.descriptors_.alloc(lay.sets[1], lay.counts[1]);
        if (!set) {
            drawsFailed_ = true;
            fail("set_bindings", without_prefix(set.error().to_string()));
            return;
        }
        VkDescriptorImageInfo images[kMaxViews + kMaxSamplers]{};
        VkDescriptorBufferInfo buffers[kMaxViews]{};
        VkWriteDescriptorSet writes[kMaxViews + kMaxSamplers]{};
        std::uint32_t n = 0, ni = 0, nb = 0;
        for (int i = 0; i < kMaxViews; ++i) {
            const BoundView& v = views[i];
            if (!v.t) continue;
            VkWriteDescriptorSet& w = writes[n++];
            w.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
            w.dstSet = *set;
            w.dstBinding = lay.viewBinding[i];
            w.descriptorCount = 1;
            if (v.type == ViewType::StorageBuffer) {
                w.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
                buffers[nb] = {v.t->buffer, v.offset, v.range};
                w.pBufferInfo = &buffers[nb++];
            } else {
                const bool storage = v.type == ViewType::StorageImage;
                w.descriptorType = storage ? VK_DESCRIPTOR_TYPE_STORAGE_IMAGE : VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
                images[ni] = {VK_NULL_HANDLE, v.view,
                              storage ? VK_IMAGE_LAYOUT_GENERAL : VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL};
                w.pImageInfo = &images[ni++];
            }
        }
        for (int i = 0; i < kMaxSamplers; ++i) {
            if (!samplers[i]) continue;
            VkWriteDescriptorSet& w = writes[n++];
            w.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
            w.dstSet = *set;
            w.dstBinding = lay.samplerBinding[i];
            w.descriptorCount = 1;
            w.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLER;
            images[ni] = {samplers[i], VK_NULL_HANDLE, VK_IMAGE_LAYOUT_UNDEFINED};
            w.pImageInfo = &images[ni++];
        }
        if (n > 0) f.vkUpdateDescriptorSets(device_.device_, n, writes, 0, nullptr);
        viewSet_ = *set;  // bound by ready_to_run, after set 0
        setsDirty_ |= 0b010;
    }

    // The vertex and index buffers.
    for (int i = 0; i < kMaxVertexBuffers; ++i) {
        if (!vbs[i].t) continue;
        const VkBuffer vb = vbs[i].t->buffer;
        const VkDeviceSize offset = vbs[i].offset;
        f.vkCmdBindVertexBuffers(c, std::uint32_t(i), 1, &vb, &offset);
    }
    if (ib.t)
        f.vkCmdBindIndexBuffer(c, ib.t->buffer, ib.offset,
                               st.indexType == IndexType::Uint16 ? VK_INDEX_TYPE_UINT16 : VK_INDEX_TYPE_UINT32);
    bindingsSet_ = true;
    empty_ = false;
}

void VulkanCommandList::set_uniforms(int slot, Range data) {
    FA_VK_REQUIRE_OPEN("set_uniforms");
    if (passFailed_ || drawsFailed_) return;
    if (!pipeline_) {
        fail("set_uniforms", "no pipeline is set (hint: set_pipeline() first, inside a pass)");
        return;
    }
    const ShaderInfo& sh = *pipeline_->shader;
    const std::uint32_t size = slot >= 0 && slot < kMaxUniformBlocks ? sh.uniformSize[slot] : 0;
    std::string error;
    if (size == 0)
        error = "uniform block slot " + std::to_string(slot) + " is not one shader '" + sh.label + "' declares";
    else if (!data.ptr || data.size != size)
        error = "uniform block slot " + std::to_string(slot) + " of shader '" + sh.label + "' has " +
                std::to_string(size) + " bytes and the data has " + std::to_string(data.ptr ? data.size : 0) +
                " (hint: pass exactly the block's size)";
    if (!error.empty()) {
        drawsFailed_ = true;
        fail("set_uniforms", error);
        return;
    }
    // The block's room in the upload ring, at the dynamic offset alignment (16 to 256 bytes).
    const VkDeviceSize align =
        std::min<VkDeviceSize>(std::max<VkDeviceSize>(device_.props_.limits.minUniformBufferOffsetAlignment, 16), 256);
    const UploadAlloc a = device_.upload(std::size_t(align_up(size, align)), std::size_t(align), this);
    if (!a.ok()) {
        drawsFailed_ = true;  // reported
        return;
    }
    std::memcpy(a.cpu, data.ptr, size);
    uniformBuffer_[slot] = a.buffer;
    uniformOffset_[slot] = std::uint32_t(a.offset);  // the ring is smaller than 4 GB; a buffer of its own starts at 0
    uniformsSet_ |= 1u << slot;
    setsDirty_ |= 0b001;  // set 0 again with the same layout: sets 1 and 2 stay bound
    empty_ = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// Viewports, scissors, draws, dispatches
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::apply_viewport(const char* what, float x, float y, float width, float height,
                                       bool originTopLeft) {
    FA_VK_REQUIRE_OPEN(what);
    if (passState_ != PassState::Render) {
        fail(what, "outside a render pass (hint: begin_pass() first)");
        return;
    }
    if (passFailed_) return;
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width) || !std::isfinite(height)) {
        fail(what, "the rectangle is not finite");
        return;
    }
    // Vulkan takes no empty viewport: the draws are skipped until the next viewport with an area.
    viewportEmpty_ = !(width > 0.0f) || !(height > 0.0f);
    if (viewportEmpty_) return;
    const VkPhysicalDeviceLimits& lim = device_.props_.limits;
    width = std::min(width, float(lim.maxViewportDimensions[0]));
    height = std::min(height, float(lim.maxViewportDimensions[1]));
    const float lo = lim.viewportBoundsRange[0], hi = lim.viewportBoundsRange[1];
    const float top = originTopLeft ? y : float(passHeight_) - (y + height);
    VkViewport vp{};
    vp.x = std::clamp(x, lo, std::max(lo, hi - width));
    vp.y = std::clamp(top, lo, std::max(lo, hi - height)) + height;  // the bottom edge: the height is negative (y up)
    vp.width = width;
    vp.height = -height;
    vp.minDepth = 0.0f;
    vp.maxDepth = 1.0f;
    device_.fn_.vkCmdSetViewport(recording(), 0, 1, &vp);
    empty_ = false;
}

void VulkanCommandList::set_viewport(int x, int y, int width, int height, bool originTopLeft) {
    apply_viewport("set_viewport", float(x), float(y), float(width), float(height), originTopLeft);
}

void VulkanCommandList::set_viewport_f(float x, float y, float width, float height, bool originTopLeft) {
    apply_viewport("set_viewport_f", x, y, width, height, originTopLeft);
}

void VulkanCommandList::set_scissor(int x, int y, int width, int height, bool originTopLeft) {
    FA_VK_REQUIRE_OPEN("set_scissor");
    if (passState_ != PassState::Render) {
        fail("set_scissor", "outside a render pass (hint: begin_pass() first)");
        return;
    }
    if (passFailed_) return;
    // In 64 bits (x + width of two large ints does not overflow), clipped to the pass (Vulkan takes no negative
    // offset).
    const std::int64_t w = std::max(width, 0), h = std::max(height, 0);
    const std::int64_t top = originTopLeft ? std::int64_t(y) : std::int64_t(passHeight_) - (std::int64_t(y) + h);
    const std::int64_t left = std::clamp<std::int64_t>(x, 0, passWidth_);
    const std::int64_t right = std::clamp<std::int64_t>(std::int64_t(x) + w, left, passWidth_);
    const std::int64_t y0 = std::clamp<std::int64_t>(top, 0, passHeight_);
    const std::int64_t y1 = std::clamp<std::int64_t>(top + h, y0, passHeight_);
    VkRect2D r{};
    r.offset = {std::int32_t(left), std::int32_t(y0)};
    r.extent = {std::uint32_t(right - left), std::uint32_t(y1 - y0)};
    device_.fn_.vkCmdSetScissor(recording(), 0, 1, &r);
    empty_ = false;
}

bool VulkanCommandList::ready_to_run(const char* what, bool compute) {
    if (passState_ != (compute ? PassState::Compute : PassState::Render)) {
        fail(what, compute ? "outside a compute pass (hint: begin_compute_pass() first)"
                           : "outside a render pass (hint: begin_pass() first)");
        return false;
    }
    if (passFailed_ || drawsFailed_) return false;  // reported when it failed
    if (!pipeline_) {
        fail(what, "no pipeline is set (hint: set_pipeline() after beginning the pass)");
        return false;
    }
    const PipelineState& st = *pipeline_;
    const ShaderInfo& sh = *st.shader;
    for (int i = 0; i < kMaxUniformBlocks; ++i)
        if (sh.uniformSize[i] > 0 && !((uniformsSet_ >> i) & 1u)) {
            fail(what, "uniform block slot " + std::to_string(i) + " of shader '" + sh.label +
                           "' was not set since set_pipeline (hint: set_uniforms(" + std::to_string(i) +
                           ", ...) after set_pipeline)");
            return false;
        }
    const PipelineLayoutInfo& lay = *st.layout;
    const bool needsBindings = lay.hasSet[1] || st.buffersUsed != 0 || st.indexType != IndexType::None;
    if (needsBindings && !bindingsSet_) {
        fail(what, "shader '" + sh.label +
                       "' reads buffers, views or samplers and set_bindings was not called since set_pipeline");
        return false;
    }
    if (!compute && viewportEmpty_) return false;  // nothing to draw into
    const VkPipelineBindPoint point = compute ? VK_PIPELINE_BIND_POINT_COMPUTE : VK_PIPELINE_BIND_POINT_GRAPHICS;
    // The sets are bound in order 0, 1, 2 with the pipeline's layout. Binding set N with a layout whose set N differs
    // from the one bound before disturbs every set above N, so a set 0 bound after sets 1 and 2 (or a new pipeline
    // whose set 0 layout differs) would leave them unbound: set_pipeline marks all three, and set_uniforms only set 0
    // (bound again with the same layout, which leaves sets 1 and 2 as they are).
    if ((setsDirty_ & 0b001) && lay.hasSet[0]) {
        // Set 0: one dynamic uniform buffer per block; a set is made once per (layout, buffers) in the list and the
        // blocks' places in the buffers are its dynamic offsets.
        std::string key = std::to_string(handle_bits(lay.sets[0]));
        for (int k = 0; k < lay.uniformCount; ++k) {
            const int i = lay.uniformOrder[k];
            key += "|" + std::to_string(handle_bits(uniformBuffer_[i])) + ":" + std::to_string(sh.uniformSize[i]);
        }
        VkDescriptorSet set = VK_NULL_HANDLE;
        if (auto it = uniformSets_.find(key); it != uniformSets_.end()) {
            set = it->second;
        } else {
            Result<VkDescriptorSet> made = device_.descriptors_.alloc(lay.sets[0], lay.counts[0]);
            if (!made) {
                drawsFailed_ = true;
                fail(what, without_prefix(made.error().to_string()));
                return false;
            }
            set = *made;
            VkDescriptorBufferInfo buffers[kMaxUniformBlocks]{};
            VkWriteDescriptorSet writes[kMaxUniformBlocks]{};
            for (int k = 0; k < lay.uniformCount; ++k) {
                const int i = lay.uniformOrder[k];
                buffers[k] = {uniformBuffer_[i], 0, sh.uniformSize[i]};
                VkWriteDescriptorSet& w = writes[k];
                w.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
                w.dstSet = set;
                w.dstBinding = lay.uniformBinding[i];
                w.descriptorCount = 1;
                w.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC;
                w.pBufferInfo = &buffers[k];
            }
            device_.fn_.vkUpdateDescriptorSets(device_.device_, std::uint32_t(lay.uniformCount), writes, 0, nullptr);
            uniformSets_.emplace(std::move(key), set);
        }
        std::uint32_t offsets[kMaxUniformBlocks]{};
        for (int k = 0; k < lay.uniformCount; ++k) offsets[k] = uniformOffset_[lay.uniformOrder[k]];
        device_.fn_.vkCmdBindDescriptorSets(recording(), point, lay.layout, 0, 1, &set, std::uint32_t(lay.uniformCount),
                                            offsets);
        device_.count_descriptor_set_bind();
    }
    if ((setsDirty_ & 0b010) && lay.hasSet[1] && viewSet_) {
        device_.fn_.vkCmdBindDescriptorSets(recording(), point, lay.layout, 1, 1, &viewSet_, 0, nullptr);
        device_.count_descriptor_set_bind();
    }
    if ((setsDirty_ & 0b100) && lay.bindless)
        if (const VkDescriptorSet bindless = device_.descriptors_.bindless_set()) {
            device_.fn_.vkCmdBindDescriptorSets(recording(), point, lay.layout, 2, 1, &bindless, 0, nullptr);
            device_.count_descriptor_set_bind();
        }
    setsDirty_ = 0;
    if (compute) {
        // A dispatch after one that wrote the bound views sees its writes (require() puts a barrier after a write).
        for (const Need& n : boundNeeds_) require(n.res, n.sub, n.state);
        flush_barriers();
    }
    return true;
}

void VulkanCommandList::record_draw(const char* what, int base, int count, int instances, int baseVertex,
                                    int baseInstance) {
    FA_VK_REQUIRE_OPEN(what);
    if (base < 0 || count < 0 || instances < 0 || baseInstance < 0) {
        fail(what, "base " + std::to_string(base) + ", count " + std::to_string(count) + ", instances " +
                       std::to_string(instances) + " or baseInstance " + std::to_string(baseInstance) + " is negative");
        return;
    }
    if (count == 0 || instances == 0) return;  // nothing to draw (sokol skips it too)
    if (!ready_to_run(what, false)) return;
    const VkFunctions& f = device_.fn_;
    if (pipeline_->indexType != IndexType::None) {
        f.vkCmdDrawIndexed(rec_, std::uint32_t(count), std::uint32_t(instances), std::uint32_t(base), baseVertex,
                           std::uint32_t(baseInstance));
    } else {
        const std::int64_t firstVertex = std::int64_t(base) + baseVertex;
        if (firstVertex < 0) {
            fail(what, "base " + std::to_string(base) + " + baseVertex " + std::to_string(baseVertex) +
                           " is negative (a draw without indices starts at that vertex)");
            return;
        }
        f.vkCmdDraw(rec_, std::uint32_t(count), std::uint32_t(instances), std::uint32_t(firstVertex),
                    std::uint32_t(baseInstance));
    }
    empty_ = false;
}

void VulkanCommandList::draw(int base, int count, int instances) { record_draw("draw", base, count, instances, 0, 0); }

void VulkanCommandList::draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) {
    record_draw("draw_ex", base, count, instances, baseVertex, baseInstance);
}

void VulkanCommandList::dispatch(int x, int y, int z) {
    FA_VK_REQUIRE_OPEN("dispatch");
    const std::uint32_t* most = device_.props_.limits.maxComputeWorkGroupCount;
    const int counts[3] = {x, y, z};
    int limit[3] = {};
    bool inRange = true;
    for (int i = 0; i < 3; ++i) {
        limit[i] = int(std::min<std::uint32_t>(most[i], 65535u));
        if (counts[i] < 0 || counts[i] > limit[i]) inRange = false;
    }
    if (!inRange) {
        fail("dispatch", "(" + std::to_string(x) + ", " + std::to_string(y) + ", " + std::to_string(z) +
                             ") thread groups: the counts are 0 to (" + std::to_string(limit[0]) + ", " +
                             std::to_string(limit[1]) + ", " + std::to_string(limit[2]) +
                             ") (hint: split the work into several dispatches)");
        return;
    }
    if (x == 0 || y == 0 || z == 0) return;  // nothing to run
    if (!ready_to_run("dispatch", true)) return;
    device_.fn_.vkCmdDispatch(cmd_, std::uint32_t(x), std::uint32_t(y), std::uint32_t(z));
    empty_ = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// States and barriers
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::transition(Use& u, std::uint32_t sub, const SubState& want) {
    SubState& cur = u.current[sub];
    if (cur.layout == kUnknownLayout) {
        // First use in this list: submit() moves the resource from the queue's state to this one (fix-up barriers).
        u.first[sub] = want;
        cur = want;
        return;
    }
    const TrackedResource& t = *u.res;
    auto push = [&](const SubState& from, const SubState& to) {
        Barrier b;
        b.buffer = t.buffer;
        b.image = t.image;
        b.aspects = t.aspects;
        b.mip = sub % t.mips;
        b.layer = sub / t.mips;
        b.from = from;
        b.to = to;
        pending_.push_back(b);
        u.since[sub] = from;
    };
    if (cur.layout == want.layout && !access_writes(cur.access) && !access_writes(want.access)) {
        // Read after read in the same layout; the next write waits for every stage that read.
        SubState& since = u.since[sub];
        if (since.layout == kUnknownLayout) {
            // No barrier in this list yet: the list's first reads grow, and submit()'s fix-up barrier makes what came
            // before visible to all of them.
            cur.stages |= want.stages;
            cur.access |= want.access;
            u.first[sub] = cur;
            return;
        }
        // A barrier made the last write (or layout change) visible to cur's stages and access only. A read in another
        // stage, or with another access, waits for it again: the barrier chains from the stages the first one reached
        // (an execution dependency chain), and its source scope keeps the write's.
        if ((want.stages & ~cur.stages) != 0 || (want.access & ~cur.access) != 0) {
            const SubState from{cur.layout, since.stages | cur.stages, since.access};
            const SubState to{cur.layout, want.stages, want.access};
            push(from, to);
        }
        cur.stages |= want.stages;
        cur.access |= want.access;
        return;
    }
    push(cur, want);
    cur = want;
}

void VulkanCommandList::require(const std::shared_ptr<TrackedResource>& t, std::uint32_t sub, const SubState& state) {
    if (!t) return;
    auto [it, added] = useIndex_.try_emplace(t.get(), uses_.size());
    if (added) {
        Use u;
        u.res = t;
        u.first.assign(t->subresource_count(), kUnused);
        u.current.assign(t->subresource_count(), kUnused);
        u.since.assign(t->subresource_count(), kUnused);
        uses_.push_back(std::move(u));
    }
    Use& u = uses_[it->second];
    if (sub == kAllSubresources) {
        for (std::uint32_t s = 0; s < t->subresource_count(); ++s) transition(u, s, state);
    } else if (sub < t->subresource_count()) {
        transition(u, sub, state);
    }
}

void VulkanCommandList::require_range(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip,
                                      std::uint32_t mipCount, std::uint32_t layer, std::uint32_t layerCount,
                                      const SubState& state) {
    if (!t) return;
    for (std::uint32_t l = layer; l < layer + layerCount && l < t->layers; ++l)
        for (std::uint32_t m = mip; m < mip + mipCount && m < t->mips; ++m) require(t, t->subresource(m, l), state);
}

void VulkanCommandList::flush_barriers() {
    if (pending_.empty() || !cmd_) return;
    device_.record_barriers(cmd_, pending_);
    pending_.clear();
}

void VulkanCommandList::keep_until_done(std::shared_ptr<TrackedResource> r) { keep_.push_back(std::move(r)); }

void VulkanDevice::record_barriers(VkCommandBuffer cmd, std::vector<Barrier>& barriers) {
    if (barriers.empty()) return;
    // Merge the barriers of one image that go the same way: adjacent mips first, then adjacent layers of equal mip
    // ranges (require() walks mips inside layers, so a whole image becomes one barrier).
    // The two halves of a queue family ownership transfer must name the same subresource ranges, but the release's
    // source stages and accesses differ per subresource (what the producer did with each) while the acquire's are
    // none: so a transfer merges on its layouts, families and destination state alone, the merged source the union
    // of the parts (waiting for more is still right). Both halves skip the same subresources and walk them in the
    // same order, so their ranges come out equal.
    auto transfer = [](const Barrier& b) {
        return b.srcFamily != b.dstFamily && b.srcFamily != VK_QUEUE_FAMILY_IGNORED &&
               b.dstFamily != VK_QUEUE_FAMILY_IGNORED;
    };
    auto same = [&transfer](const Barrier& a, const Barrier& b) {
        if (!a.image || a.image != b.image || a.aspects != b.aspects || !(a.to == b.to) || a.srcFamily != b.srcFamily ||
            a.dstFamily != b.dstFamily)
            return false;
        return transfer(a) ? a.from.layout == b.from.layout : a.from == b.from;
    };
    auto join = [](Barrier& into, const Barrier& b) {
        into.from.stages |= b.from.stages;
        into.from.access |= b.from.access;
    };
    std::vector<Barrier> mips;
    for (const Barrier& b : barriers) {
        if (!mips.empty()) {
            Barrier& last = mips.back();
            if (same(last, b) && last.layer == b.layer && last.layerCount == b.layerCount &&
                last.mip + last.mipCount == b.mip) {
                last.mipCount += b.mipCount;
                join(last, b);
                continue;
            }
        }
        mips.push_back(b);
    }
    std::vector<Barrier> merged;
    for (const Barrier& b : mips) {
        if (!merged.empty()) {
            Barrier& last = merged.back();
            if (same(last, b) && last.mip == b.mip && last.mipCount == b.mipCount &&
                last.layer + last.layerCount == b.layer) {
                last.layerCount += b.layerCount;
                join(last, b);
                continue;
            }
        }
        merged.push_back(b);
    }

    if (fn_.vkCmdPipelineBarrier2) {
        std::vector<VkImageMemoryBarrier2> images;
        std::vector<VkBufferMemoryBarrier2> buffers;
        for (const Barrier& b : merged) {
            if (b.image) {
                VkImageMemoryBarrier2 x{};
                x.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2;
                x.srcStageMask = b.from.stages;
                x.srcAccessMask = b.from.access;
                x.dstStageMask = b.to.stages;
                x.dstAccessMask = b.to.access;
                x.oldLayout = b.from.layout;
                x.newLayout = b.to.layout;
                x.srcQueueFamilyIndex = b.srcFamily;
                x.dstQueueFamilyIndex = b.dstFamily;
                x.image = b.image;
                x.subresourceRange = {b.aspects, b.mip, b.mipCount, b.layer, b.layerCount};
                images.push_back(x);
            } else {
                VkBufferMemoryBarrier2 x{};
                x.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER_2;
                x.srcStageMask = b.from.stages;
                x.srcAccessMask = b.from.access;
                x.dstStageMask = b.to.stages;
                x.dstAccessMask = b.to.access;
                x.srcQueueFamilyIndex = b.srcFamily;
                x.dstQueueFamilyIndex = b.dstFamily;
                x.buffer = b.buffer;
                x.offset = 0;
                x.size = VK_WHOLE_SIZE;
                buffers.push_back(x);
            }
        }
        VkDependencyInfo di{};
        di.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO;
        di.bufferMemoryBarrierCount = std::uint32_t(buffers.size());
        di.pBufferMemoryBarriers = buffers.data();
        di.imageMemoryBarrierCount = std::uint32_t(images.size());
        di.pImageMemoryBarriers = images.data();
        fn_.vkCmdPipelineBarrier2(cmd, &di);
    } else {
        // Vulkan 1.0: one stage mask for every barrier, and the synchronization2 bits above bit 31 (which have no
        // 1.0 value) mapped to the 1.0 bits that cover them (stages_1_0, access_1_0).
        VkPipelineStageFlags src = 0, dst = 0;
        std::vector<VkImageMemoryBarrier> images;
        std::vector<VkBufferMemoryBarrier> buffers;
        for (const Barrier& b : merged) {
            src |= stages_1_0(b.from.stages);
            dst |= stages_1_0(b.to.stages);
            const VkAccessFlags srcAccess = access_1_0(b.from.access);
            const VkAccessFlags dstAccess = access_1_0(b.to.access);
            if (b.image) {
                VkImageMemoryBarrier x{};
                x.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
                x.srcAccessMask = srcAccess;
                x.dstAccessMask = dstAccess;
                x.oldLayout = b.from.layout;
                x.newLayout = b.to.layout;
                x.srcQueueFamilyIndex = b.srcFamily;
                x.dstQueueFamilyIndex = b.dstFamily;
                x.image = b.image;
                x.subresourceRange = {b.aspects, b.mip, b.mipCount, b.layer, b.layerCount};
                images.push_back(x);
            } else {
                VkBufferMemoryBarrier x{};
                x.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER;
                x.srcAccessMask = srcAccess;
                x.dstAccessMask = dstAccess;
                x.srcQueueFamilyIndex = b.srcFamily;
                x.dstQueueFamilyIndex = b.dstFamily;
                x.buffer = b.buffer;
                x.offset = 0;
                x.size = VK_WHOLE_SIZE;
                buffers.push_back(x);
            }
        }
        if (src == 0) src = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        if (dst == 0) dst = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
        fn_.vkCmdPipelineBarrier(cmd, src, dst, 0, 0, nullptr, std::uint32_t(buffers.size()), buffers.data(),
                                 std::uint32_t(images.size()), images.data());
    }
    barriers_ += merged.size();
}

// ---------------------------------------------------------------------------------------------------------------------
// Transfers
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::write_buffer(const BufferWrite& w) {
    FA_VK_REQUIRE_OPEN("write_buffer");
    std::size_t bufferSize = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = device_.buffer_tracked(w.buffer, &bufferSize, &label);
    const std::size_t size = w.size > 0 ? w.size : (w.data.size > w.srcOffset ? w.data.size - w.srcOffset : 0);
    std::string error;
    if (!t)
        error = "buffer " + std::to_string(w.buffer.id) + " is not a live buffer";
    else if (!w.data.ptr || size == 0 || w.srcOffset > w.data.size || size > w.data.size - w.srcOffset)
        error = "the source range (offset " + std::to_string(w.srcOffset) + ", " + std::to_string(size) +
                " bytes) is empty or past the data's " + std::to_string(w.data.size) + " bytes";
    else if (w.dstOffset > bufferSize || size > bufferSize - w.dstOffset)
        error = std::to_string(size) + " bytes at offset " + std::to_string(w.dstOffset) + " go past buffer '" + label +
                "''s " + std::to_string(bufferSize) + " bytes";
    if (!error.empty()) {
        device_.report("gpu vulkan: CommandList::write_buffer in list '" + label_ + "': " + error);
        return;
    }
    const UploadAlloc a = device_.upload(size, 16, this);
    if (!a.ok()) return;  // reported
    std::memcpy(a.cpu, static_cast<const std::uint8_t*>(w.data.ptr) + w.srcOffset, size);
    require(t, 0, transfer_write_state(false));
    flush_barriers();
    VkBufferCopy c{};
    c.srcOffset = a.offset;
    c.dstOffset = w.dstOffset;
    c.size = size;
    device_.fn_.vkCmdCopyBuffer(cmd_, a.buffer, t->buffer, 1, &c);
    empty_ = false;
}

void VulkanCommandList::copy_buffer_to_buffer(const BufferCopy& c) {
    FA_VK_REQUIRE_OPEN("copy_buffer_to_buffer");
    std::size_t srcSize = 0, dstSize = 0;
    std::string srcLabel, dstLabel;
    std::shared_ptr<TrackedResource> src = device_.buffer_tracked(c.src, &srcSize, &srcLabel);
    std::shared_ptr<TrackedResource> dst = device_.buffer_tracked(c.dst, &dstSize, &dstLabel);
    std::string error;
    if (!src || !dst)
        error = std::string("the ") + (!src ? "source" : "destination") + " is not a live buffer";
    else if (src == dst)
        error = "the source and the destination are the same buffer '" + srcLabel +
                "' (hint: copy through a second buffer)";
    else if (c.size == 0 || c.srcOffset % 4 || c.dstOffset % 4)
        error = "the size is 0 or an offset is not a multiple of 4";
    else if (c.srcOffset > srcSize || c.size > srcSize - c.srcOffset || c.dstOffset > dstSize ||
             c.size > dstSize - c.dstOffset)
        error = std::to_string(c.size) + " bytes from offset " + std::to_string(c.srcOffset) + " of '" + srcLabel +
                "' (" + std::to_string(srcSize) + " bytes) to offset " + std::to_string(c.dstOffset) + " of '" +
                dstLabel + "' (" + std::to_string(dstSize) + " bytes) go past a buffer's end";
    if (!error.empty()) {
        device_.report("gpu vulkan: CommandList::copy_buffer_to_buffer in list '" + label_ + "': " + error);
        return;
    }
    require(src, 0, transfer_read_state(false));
    require(dst, 0, transfer_write_state(false));
    flush_barriers();
    VkBufferCopy region{};
    region.srcOffset = c.srcOffset;
    region.dstOffset = c.dstOffset;
    region.size = c.size;
    device_.fn_.vkCmdCopyBuffer(cmd_, src->buffer, dst->buffer, 1, &region);
    empty_ = false;
}

void VulkanCommandList::copy_to_image(VkBuffer src, VkDeviceSize offset, std::uint32_t rowTexels,
                                      std::uint32_t sliceRows, const std::shared_ptr<TrackedResource>& t, bool is3d,
                                      std::uint32_t mip, std::uint32_t layer, std::uint32_t count, std::uint32_t x,
                                      std::uint32_t y, std::uint32_t width, std::uint32_t height) {
    if (is3d)
        require(t, t->subresource(mip, 0), transfer_write_state(true));
    else
        require_range(t, mip, 1, layer, count, transfer_write_state(true));
    flush_barriers();
    VkBufferImageCopy c{};
    c.bufferOffset = offset;
    c.bufferRowLength = rowTexels;
    c.bufferImageHeight = sliceRows;
    c.imageSubresource.aspectMask = t->aspects;
    c.imageSubresource.mipLevel = mip;
    c.imageSubresource.baseArrayLayer = is3d ? 0 : layer;
    c.imageSubresource.layerCount = is3d ? 1 : count;
    // a compressed region that ends at the mip's edge may end inside a 4x4 block: the copy takes the texels it covers
    c.imageOffset = {std::int32_t(x), std::int32_t(y), is3d ? std::int32_t(layer) : 0};
    c.imageExtent = {width, height, is3d ? count : 1u};
    device_.fn_.vkCmdCopyBufferToImage(cmd_, src, t->image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &c);
    empty_ = false;
}

bool VulkanCommandList::upload_region(const std::shared_ptr<TrackedResource>& t, PixelFormat format, bool is3d,
                                      std::uint32_t mip, std::uint32_t layer, std::uint32_t count, std::uint32_t x,
                                      std::uint32_t y, std::uint32_t width, std::uint32_t height,
                                      const std::uint8_t* src, std::size_t srcRowPitch, std::size_t srcSlicePitch) {
    const std::uint32_t rowBytes = texel_row_bytes(format, width);
    const std::uint32_t rows = texel_rows(format, height);
    const std::uint64_t slice = std::uint64_t(rowBytes) * rows;  // tightly packed in the upload buffer
    // the copy's offset is a multiple of the texel (block) size and of the device's preferred alignment, both powers
    // of two
    const std::size_t align = std::max<std::size_t>(device_.imageUploadAlign_, texel_block_bytes(format));
    const UploadAlloc a = device_.upload(std::size_t(slice * count), align, this);
    if (!a.ok()) return false;
    if (srcRowPitch == rowBytes && srcSlicePitch == slice) {
        std::memcpy(a.cpu, src, std::size_t(slice * count));
    } else {
        for (std::uint32_t i = 0; i < count; ++i)
            for (std::uint32_t r = 0; r < rows; ++r)
                std::memcpy(a.cpu + slice * i + std::uint64_t(rowBytes) * r, src + srcSlicePitch * i + srcRowPitch * r,
                            rowBytes);
    }
    copy_to_image(a.buffer, a.offset, 0, 0, t, is3d, mip, layer, count, x, y, width, height);
    return true;
}

namespace {

// The region of a write_image / copy_buffer_to_image, checked against the image, with sokol's defaults.
struct Region {
    std::uint32_t mip = 0, x = 0, y = 0, layer = 0, width = 0, height = 0, count = 0;
    std::size_t rowPitch = 0, slicePitch = 0;  // of the source
    std::uint32_t rowBytes = 0, rows = 0;      // of the region
    std::string error;
};

template <class Record>
Region image_region(const Record& im, const ImageLocation& at, const ImageExtent& size, int bytesPerRow,
                    int bytesPerSlice) {
    Region r;
    const bool is3d = im.type == ImageType::Tex3d;
    if (at.mipLevel < 0 || at.mipLevel >= im.mips) {
        r.error = "mip level " + std::to_string(at.mipLevel) + " is outside image '" + im.label + "''s " +
                  std::to_string(im.mips) + " levels";
        return r;
    }
    if (pixel_format_depth(im.format) || im.samples > 1) {
        r.error = "image '" + im.label + "' is a depth or multisampled image (hint: draw into it instead)";
        return r;
    }
    r.mip = std::uint32_t(at.mipLevel);
    const std::uint32_t mw = mip_extent(im.width, at.mipLevel), mh = mip_extent(im.height, at.mipLevel);
    const std::uint32_t md = is3d ? mip_extent(im.slices, at.mipLevel) : std::uint32_t(im.slices);
    r.width = extent_or_rest(size.width, at.x, mw);
    r.height = extent_or_rest(size.height, at.y, mh);
    r.count = extent_or_rest(size.numSlices, at.slice, md);
    if (at.x < 0 || at.y < 0 || at.slice < 0 || r.width == 0 || r.height == 0 || r.count == 0 ||
        std::uint64_t(at.x) + r.width > mw || std::uint64_t(at.y) + r.height > mh ||
        std::uint64_t(at.slice) + r.count > md) {
        r.error = "the region at (" + std::to_string(at.x) + ", " + std::to_string(at.y) + ", slice " +
                  std::to_string(at.slice) + ") of " + std::to_string(r.width) + "x" + std::to_string(r.height) + "x" +
                  std::to_string(r.count) + " is empty or outside mip " + std::to_string(at.mipLevel) + " (" +
                  std::to_string(mw) + "x" + std::to_string(mh) + "x" + std::to_string(md) + ") of image '" + im.label +
                  "'";
        return r;
    }
    r.x = std::uint32_t(at.x);
    r.y = std::uint32_t(at.y);
    r.layer = std::uint32_t(at.slice);
    if (format_info(im.format).blockBytes &&
        (r.x % 4 || r.y % 4 || (r.width % 4 && r.x + r.width != mw) || (r.height % 4 && r.y + r.height != mh))) {
        r.error = "a compressed image is written in whole 4x4 blocks (hint: align the region to 4 texels)";
        return r;
    }
    r.rowBytes = texel_row_bytes(im.format, r.width);
    r.rows = texel_rows(im.format, r.height);
    // sokol's defaults: the pitches of the whole mip level, not of the region.
    r.rowPitch = bytesPerRow > 0 ? std::size_t(bytesPerRow) : texel_row_bytes(im.format, mw);
    r.slicePitch = bytesPerSlice > 0 ? std::size_t(bytesPerSlice) : r.rowPitch * texel_rows(im.format, mh);
    if (r.rowPitch < r.rowBytes || r.slicePitch < r.rowPitch * r.rows) {
        r.error = "bytesPerRow " + std::to_string(r.rowPitch) + " / bytesPerSlice " + std::to_string(r.slicePitch) +
                  " are smaller than a row (" + std::to_string(r.rowBytes) + ") / a slice of the region";
        return r;
    }
    return r;
}

std::size_t region_bytes(const Region& r) {
    return r.slicePitch * (r.count - 1) + r.rowPitch * (r.rows - 1) + r.rowBytes;
}

}  // namespace

void VulkanCommandList::write_image(const ImageWrite& w) {
    FA_VK_REQUIRE_OPEN("write_image");
    VulkanDevice::ImageRecord im;
    if (!device_.image_info(w.dst.image, im)) {
        device_.report("gpu vulkan: CommandList::write_image in list '" + label_ + "': image " +
                       std::to_string(w.dst.image.id) + " is not a live image");
        return;
    }
    Region r = image_region(im, w.dst, w.size, w.bytesPerRow, w.bytesPerSlice);
    if (r.error.empty() && (!w.data.ptr || w.srcOffset > w.data.size || region_bytes(r) > w.data.size - w.srcOffset))
        r.error = "the region needs " + std::to_string(region_bytes(r)) + " bytes from offset " +
                  std::to_string(w.srcOffset) + ", the data has " + std::to_string(w.data.size);
    if (!r.error.empty()) {
        device_.report("gpu vulkan: CommandList::write_image in list '" + label_ + "': " + r.error);
        return;
    }
    upload_region(im.tracked, im.format, im.type == ImageType::Tex3d, r.mip, r.layer, r.count, r.x, r.y, r.width,
                  r.height, static_cast<const std::uint8_t*>(w.data.ptr) + w.srcOffset, r.rowPitch, r.slicePitch);
}

void VulkanCommandList::copy_buffer_to_image(const BufferImageCopy& c) {
    FA_VK_REQUIRE_OPEN("copy_buffer_to_image");
    std::size_t srcSize = 0;
    std::string srcLabel;
    std::shared_ptr<TrackedResource> src = device_.buffer_tracked(c.src, &srcSize, &srcLabel);
    VulkanDevice::ImageRecord im;
    Region r;
    if (!src)
        r.error = "the source " + std::to_string(c.src.id) + " is not a live buffer";
    else if (!device_.image_info(c.dst.image, im))
        r.error = "the destination " + std::to_string(c.dst.image.id) + " is not a live image";
    else
        r = image_region(im, c.dst, c.size, c.bytesPerRow, c.bytesPerSlice);
    if (r.error.empty() && (c.srcOffset > srcSize || region_bytes(r) > srcSize - c.srcOffset))
        r.error = "the region needs " + std::to_string(region_bytes(r)) + " bytes from offset " +
                  std::to_string(c.srcOffset) + " of buffer '" + srcLabel + "', which has " + std::to_string(srcSize);
    if (!r.error.empty()) {
        device_.report("gpu vulkan: CommandList::copy_buffer_to_image in list '" + label_ + "': " + r.error);
        return;
    }
    const bool is3d = im.type == ImageType::Tex3d;
    const bool compressed = format_info(im.format).blockBytes != 0;
    const std::uint32_t texel = texel_block_bytes(im.format);
    require(src, 0, transfer_read_state(false));
    // Vulkan reads texels from any offset that is a multiple of the texel (block) size, with rows a whole number of
    // texels long and slices a whole number of rows: other layouts are repacked on the GPU first.
    if (c.srcOffset % texel == 0 && r.rowPitch % texel == 0 && r.slicePitch % r.rowPitch == 0) {
        const auto rowTexels = std::uint32_t(r.rowPitch / texel * (compressed ? 4u : 1u));
        const auto sliceRows = std::uint32_t(r.slicePitch / r.rowPitch * (compressed ? 4u : 1u));
        copy_to_image(src->buffer, c.srcOffset, rowTexels, sliceRows, im.tracked, is3d, r.mip, r.layer, r.count, r.x,
                      r.y, r.width, r.height);
        return;
    }
    const std::uint64_t slice = std::uint64_t(r.rowBytes) * r.rows;
    std::string error;
    std::shared_ptr<TrackedResource> scratch =
        device_.make_raw_buffer(slice * r.count, VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
                                MemoryUse::GpuOnly, false, "fa-vulkan-repack", error);
    if (!scratch) {
        device_.report("gpu vulkan: CommandList::copy_buffer_to_image in list '" + label_ +
                       "': the buffer that repacks the rows could not be made: " + error);
        return;
    }
    scratch->owner = queue_;  // the list's own: born on its queue, never handed to another
    require(scratch, 0, transfer_write_state(false));
    flush_barriers();
    std::vector<VkBufferCopy> rows;
    rows.reserve(std::size_t(r.count) * r.rows);
    for (std::uint32_t i = 0; i < r.count; ++i)
        for (std::uint32_t row = 0; row < r.rows; ++row) {
            VkBufferCopy b{};
            b.srcOffset = c.srcOffset + r.slicePitch * i + r.rowPitch * row;
            b.dstOffset = slice * i + std::uint64_t(r.rowBytes) * row;
            b.size = r.rowBytes;
            rows.push_back(b);
        }
    device_.fn_.vkCmdCopyBuffer(cmd_, src->buffer, scratch->buffer, std::uint32_t(rows.size()), rows.data());
    require(scratch, 0, transfer_read_state(false));
    copy_to_image(scratch->buffer, 0, 0, 0, im.tracked, is3d, r.mip, r.layer, r.count, r.x, r.y, r.width, r.height);
    keep_until_done(std::move(scratch));
}

// ---------------------------------------------------------------------------------------------------------------------
// Debug groups (debug utils labels)
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::push_debug_group(const char* name) {
    FA_VK_REQUIRE_OPEN("push_debug_group");
    if (device_.fn_.vkCmdBeginDebugUtilsLabelEXT) {
        VkDebugUtilsLabelEXT l{};
        l.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT;
        l.pLabelName = name ? name : "";
        device_.fn_.vkCmdBeginDebugUtilsLabelEXT(recording(), &l);
    }
    if (rec_) passGroups_.emplace_back(name ? name : "");
    ++debugDepth_;
}

void VulkanCommandList::pop_debug_group() {
    FA_VK_REQUIRE_OPEN("pop_debug_group");
    if (debugDepth_ == 0) {
        device_.report("gpu vulkan: CommandList::pop_debug_group in list '" + label_ +
                       "' without an open group (hint: one pop_debug_group() per push_debug_group())");
        return;
    }
    if (rec_ && passGroups_.empty()) {
        ++passOuterPops_;  // a group opened before the render pass ends after it (labels end where they began)
    } else {
        if (device_.fn_.vkCmdEndDebugUtilsLabelEXT) device_.fn_.vkCmdEndDebugUtilsLabelEXT(recording());
        if (rec_) passGroups_.pop_back();
    }
    --debugDepth_;
}

#undef FA_VK_REQUIRE_OPEN

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
