// make_device(): the factory of the GPU interface (gpu/device.h), and the defaults of Device's non-pure virtuals.
#include "gpu/device.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>

#include "gpu/d3d12_device.h"
#include "gpu/recording_device.h"
#include "gpu/sokol_device.h"
#include "gpu/vulkan_device.h"

namespace fa::gpu {

bool Device::storage_image_loadable(PixelFormat format, std::string* why) const {
    if (why)
        *why = std::string("Device::storage_image_loadable is not implemented on the ") + backend_name(backend()) +
               " device yet, so " + pixel_format_name(format) +
               " storage images are write-only there: use \"access\": \"write\"";
    return false;
}

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

Result<std::unique_ptr<Device>> make_device(Backend backend, const DeviceInit& init) {
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
