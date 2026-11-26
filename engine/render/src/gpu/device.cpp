// make_device(): the factory of the GPU interface (gpu/device.h), and the defaults of Device's non-pure virtuals.
#include "gpu/device.h"

#include <atomic>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>

#include "gpu/d3d12_device.h"
#include "gpu/recording_device.h"
#include "gpu/sokol_device.h"
#include "gpu/vulkan_device.h"

namespace fa::gpu {

std::uint64_t Device::next_generation() {
    static std::atomic<std::uint64_t> last{0};
    return last.fetch_add(1, std::memory_order_relaxed) + 1;
}

bool Device::storage_image_loadable(PixelFormat format, std::string* why) const {
    if (why)
        *why = std::string("Device::storage_image_loadable is not implemented on the ") + backend_name(backend()) +
               " device yet, so " + pixel_format_name(format) +
               " storage images are write-only there: use \"access\": \"write\"";
    return false;
}

// ---- ray tracing: the answer of a backend that has none (yet) -------------------------------------------------------

const char* accel_kind_name(AccelKind kind) { return kind == AccelKind::Tlas ? "TLAS" : "BLAS"; }

std::string accel_unavailable_reason(Backend backend) {
    switch (backend) {
        case Backend::Gl:
        case Backend::Gles3:
        case Backend::WebGl2:
        case Backend::D3d11:
            return std::string("the ") + backend_name(backend) +
                   " backend cannot trace rays: ray tracing needs the d3d12 or vulkan backend (Windows, Linux, "
                   "Android) or Metal on Apple";
        case Backend::D3d12:
            return "the d3d12 device has no DXR tier 1.1 with shader model 6.5, which inline ray query needs (update "
                   "the GPU driver, or run on a DirectX 12 Ultimate GPU; WARP has tier 1.1 on Windows 11)";
        case Backend::Vulkan:
            return "the vulkan backend does not build acceleration structures yet (VK_KHR_acceleration_structure and "
                   "VK_KHR_ray_query are package P1v of milestone 79)";
        case Backend::Metal:
            return "the metal backend does not build acceleration structures yet (Metal ray tracing inside the sokol "
                   "device is package P1m of milestone 79)";
        case Backend::Recording:
            return "this RecordingDevice was made without ray tracing: set DeviceInit::recordingRayTracing (or "
                   "recordingFeatures rayQuery, accelerationStructure and bufferDeviceAddress with recordingLimits "
                   "maxAccelInstances, maxAccelGeometries and maxAccelPrimitives, with recordingDefaultCaps false)";
    }
    return "this backend has no ray tracing";
}

Error accel_refusal(Backend backend, const char* call) {
    return Error{std::string("gpu: ") + call + ": " + accel_unavailable_reason(backend),
                 "check Device::features().accelerationStructure && rayQuery before building acceleration structures "
                 "(renderer.supports(\"raytracing\") says it with a reason), and draw without ray tracing when it is "
                 "false"};
}

namespace {

Error no_ray_tracing(Backend backend, const char* call) { return accel_refusal(backend, call); }

}  // namespace

Result<void> CommandList::build_blas(const BlasBuild&) { return no_ray_tracing(backend(), "CommandList::build_blas"); }
Result<void> CommandList::build_tlas(const TlasBuild&) { return no_ray_tracing(backend(), "CommandList::build_tlas"); }
Result<void> CommandList::query_compacted_size(AccelStructure, Buffer, std::size_t) {
    return no_ray_tracing(backend(), "CommandList::query_compacted_size");
}
Result<void> CommandList::copy_accel_structure(AccelStructure, AccelStructure, AccelCopyMode) {
    return no_ray_tracing(backend(), "CommandList::copy_accel_structure");
}
Result<AccelSizes> Device::blas_sizes(std::span<const AccelTriangles>, const AccelBuildFlags&) {
    return no_ray_tracing(backend(), "Device::blas_sizes");
}
Result<AccelSizes> Device::tlas_sizes(std::uint32_t, const AccelBuildFlags&) {
    return no_ray_tracing(backend(), "Device::tlas_sizes");
}
Result<AccelStructure> Device::make_accel_structure(const AccelStructureDesc&) {
    return no_ray_tracing(backend(), "Device::make_accel_structure");
}
bool Device::ray_tracing_status(std::string* why) const {
    const bool ok = features().rayQuery && features().accelerationStructure;
    if (!ok && why) *why = accel_unavailable_reason(backend());
    return ok;
}
void Device::destroy_accel_structure(AccelStructure) {}
ResourceState Device::accel_structure_state(AccelStructure) const { return ResourceState::Invalid; }

// ---- the window: the answer of a backend without a window path ------------------------------------------------------

namespace {

Error no_window_path(const Device& device, const char* call) {
    return Error{std::string("gpu: ") + call + " on the " + backend_name(device.backend()) +
                     " backend, which has no window path yet: it draws into images only",
                 std::string("render offscreen (RendererDesc::headless true, then Renderer::capture), or pick the "
                             "platform's sokol backend (") +
                     backend_name(built_sokol_backend()) + ") to draw into a window"};
}

}  // namespace

Result<void> Device::create_swapchain(const SwapchainDesc&) { return no_window_path(*this, "create_swapchain"); }
Result<void> Device::resize_swapchain(int, int) { return no_window_path(*this, "resize_swapchain"); }
Result<Swapchain> Device::acquire_swapchain(const Swapchain&) { return no_window_path(*this, "acquire_swapchain"); }
Result<void> Device::present() { return no_window_path(*this, "present"); }
void Device::destroy_swapchain() {}
bool Device::has_swapchain() const { return false; }
bool Device::swapchain_format_supported(PixelFormat format, std::string* why) const {
    if (why)
        *why = std::string("the ") + backend_name(backend()) +
               " backend has no window path yet, so no swapchain takes " + pixel_format_name(format);
    return false;
}

// ---- queues and hand-offs --------------------------------------------------------------------------------------------

CommandList& Device::begin_commands(const char* label, QueueKind) { return begin_commands(label); }

SyncToken Device::issue_token(QueueKind queue) {
    const int i = std::size_t(queue) < std::size_t(kQueueKinds) ? int(queue) : 0;
    return SyncToken{QueueKind(i), issued_[i].fetch_add(1, std::memory_order_relaxed) + 1};
}

SyncToken Device::submit_token(CommandList& list, std::span<const QueueHandoff>) {
    const QueueKind queue = list.queue();  // before submit(): the device may recycle the list
    submit(list);
    return issue_token(queue);
}

void Device::wait_list(CommandList&, SyncToken) {}

void Device::wait_queue(QueueKind, SyncToken) {}

std::uint32_t Device::bindless_index(View) const { return kNoBindlessIndex; }

NativeView Device::native_view(View) const { return {}; }

Result<void> Device::wait_idle() { return {}; }

// ---- native commands: the answer of a backend without them, and the shared checks -----------------------------------

Result<NativeCommands> CommandList::begin_native(std::span<const NativeUse>) {
    return make_error("gpu: CommandList::begin_native: this command list records no native commands",
                      "native command recording is for D3D12, Vulkan and D3D11 (the RecordingDevice, GL and Metal "
                      "have none): check Device::backend() before asking for it");
}

Result<void> CommandList::end_native(std::span<const NativeUse>) {
    return make_error("gpu: CommandList::end_native without begin_native",
                      "call end_native once after each begin_native that succeeded");
}

std::string check_native_use(const NativeUse& use, const NativeTarget& target, QueueKind queue, NativeRange& range) {
    const NativeState s = use.state;
    if (std::size_t(s) >= std::size_t(NativeState::Count))
        return "the state " + std::to_string(int(s)) + " is not a NativeState";
    const std::string what = target.label && *target.label
                                 ? std::string(target.buffer ? "buffer '" : "image '") + target.label + "'"
                                 : std::string(target.buffer ? "an unnamed buffer" : "an unnamed image");
    const std::string state = native_state_name(s);
    const bool graphicsOnly =
        s == NativeState::RenderTarget || s == NativeState::DepthWrite || s == NativeState::DepthRead;
    if (graphicsOnly && queue != QueueKind::Graphics)
        return state + " on a " + queue_name(queue) +
               " list (hint: attachment states need a list of the graphics queue, begin_commands(label, "
               "QueueKind::Graphics))";
    if (target.buffer) {
        if (use.mip != 0 || use.mipCount != 0 || use.layer != 0 || use.layerCount != 0)
            return what + " has a mip or layer range (hint: a buffer is always whole: leave mip, mipCount, layer and "
                          "layerCount 0)";
        if (graphicsOnly)
            return what + " cannot be in " + state +
                   " (hint: a buffer takes Common, ShaderRead, UnorderedAccess, CopySource or CopyDest)";
        if (s == NativeState::UnorderedAccess && !target.bufferUsage.storageBuffer)
            return what + " was not made with BufferUsage::storageBuffer, so it cannot be in UnorderedAccess";
        range = NativeRange{0, 1, 0, 1};
        return {};
    }
    const int mipCount = use.mipCount == 0 ? target.mips - use.mip : use.mipCount;
    const int layerCount = use.layerCount == 0 ? target.layers - use.layer : use.layerCount;
    if (use.mip < 0 || use.mip >= target.mips || use.mipCount < 0 || mipCount < 1 || mipCount > target.mips - use.mip)
        return "mips " + std::to_string(use.mip) + " + " + std::to_string(use.mipCount) + " are not inside the " +
               std::to_string(target.mips) + " mip(s) of " + what + " (hint: mipCount 0 = up to the last mip)";
    if (use.layer < 0 || use.layer >= target.layers || use.layerCount < 0 || layerCount < 1 ||
        layerCount > target.layers - use.layer)
        return "layers " + std::to_string(use.layer) + " + " + std::to_string(use.layerCount) + " are not inside the " +
               std::to_string(target.layers) + " layer(s) of " + what +
               " (hint: layerCount 0 = up to the last layer; a 3D image has one)";
    const bool depth = pixel_format_depth(target.format);
    const ImageUsage& u = target.imageUsage;
    if (s == NativeState::RenderTarget && (depth || !(u.colorAttachment || u.resolveAttachment)))
        return what + (depth ? " has a depth format, so it cannot be in RenderTarget (hint: DepthWrite or DepthRead)"
                             : " was not made with ImageUsage::colorAttachment, so it cannot be in RenderTarget");
    if ((s == NativeState::DepthWrite || s == NativeState::DepthRead) && (!depth || !u.depthStencilAttachment))
        return what + " is not a depth image made with ImageUsage::depthStencilAttachment, so it cannot be in " + state;
    if (s == NativeState::UnorderedAccess && !u.storageImage)
        return what + " was not made with ImageUsage::storageImage, so it cannot be in UnorderedAccess";
    range = NativeRange{use.mip, mipCount, use.layer, layerCount};
    return {};
}

std::string check_native_overlaps(std::span<const NativeUse> uses, std::span<const NativeRange> ranges) {
    auto overlap = [](int a, int an, int b, int bn) { return a < b + bn && b < a + an; };
    for (std::size_t i = 0; i < uses.size() && i < ranges.size(); ++i)
        for (std::size_t j = i + 1; j < uses.size() && j < ranges.size(); ++j) {
            const NativeUse& a = uses[i];
            const NativeUse& b = uses[j];
            const bool same = a.image.id ? a.image.id == b.image.id : (a.buffer.id && a.buffer.id == b.buffer.id);
            if (!same || a.state == b.state) continue;
            const NativeRange& ra = ranges[i];
            const NativeRange& rb = ranges[j];
            if (overlap(ra.mip, ra.mipCount, rb.mip, rb.mipCount) &&
                overlap(ra.layer, ra.layerCount, rb.layer, rb.layerCount))
                return "uses[" + std::to_string(i) + "] (" + native_state_name(a.state) + ") and uses[" +
                       std::to_string(j) + "] (" + native_state_name(b.state) +
                       ") put the same subresource in two states (hint: split the mip or layer ranges, or pick one "
                       "state)";
        }
    return {};
}

// ---- make_device -----------------------------------------------------------------------------------------------------

bool device_backend_compiled(Backend backend) {
    switch (backend) {
        case Backend::Recording: return true;
        case Backend::D3d12:
#if defined(_WIN32)
            return true;
#else
            return false;
#endif
        case Backend::Vulkan:
#if defined(FA_RENDER_VULKAN)
            return true;
#else
            return false;
#endif
        default: return backend == built_sokol_backend();
    }
}

Result<std::unique_ptr<Device>> make_device(Backend backend, const DeviceInit& initIn) {
    // The registered hooks take part in every device; a backend that calls none says so in each hook's reason.
    DeviceInit init = initIn;
    init.hooks = with_registered_hooks(initIn.hooks);
    if (backend != Backend::D3d12 && backend != Backend::Vulkan) mark_hooks_unsupported(init.hooks, backend);
    if (backend == Backend::Recording) return std::unique_ptr<Device>(std::make_unique<RecordingDevice>(init));
    const Backend built = built_sokol_backend();
    if (backend == Backend::D3d12) {
        D3d12Options options;
        options.init = init;
        options.pipelineCacheFile = d3d12_pipeline_cache_file();
        // Test and diagnosis hooks (docs/design/ARCHITECTURE_RENDERING_D3D12.md, "Tests"): FA_D3D12_WARP=1 draws on
        // WARP instead of the GPU, FA_D3D12_DEBUG=1 turns the debug layer on.
        auto on = [](const char* name) {
            const char* v = std::getenv(name);
            return v && std::strcmp(v, "1") == 0;
        };
        options.warp = on("FA_D3D12_WARP");
        options.debugLayer = on("FA_D3D12_DEBUG");
        return make_d3d12_device(options);  // a teaching error off Windows
    }
    if (backend == Backend::Vulkan) {
#if defined(FA_RENDER_VULKAN)
        VulkanOptions options;
        options.init = init;
        options.pipelineCacheFile = vulkan_pipeline_cache_file();
        return make_vulkan_device(options);
#else
        return make_error("gpu: the renderer of this build has no Vulkan backend (FA_RENDER_VULKAN is off: its "
                          "built-in shaders carry no SPIR-V)",
                          std::string("ask for built_sokol_backend() (") + backend_name(built) +
                              "), or configure with -DFA_RENDER_VULKAN=ON on a platform with Vulkan (Linux, Windows, "
                              "Android; macOS in a build with the tests)");
#endif
    }
    if (backend != built)
        return make_error(std::string("gpu: this binary was built with the ") + backend_name(built) + " backend, not " +
                              backend_name(backend),
                          std::string("ask for built_sokol_backend() (") + backend_name(built) +
                              "): sokol builds one backend per binary");
    auto device = SokolDevice::create(init);
    if (!device) return device.error();
    return std::unique_ptr<Device>(std::move(device.value()));
}

}  // namespace fa::gpu
