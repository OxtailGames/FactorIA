// make_device(): the factory of the GPU interface (gpu/device.h), and the defaults of Device's non-pure virtuals.
#include "gpu/device.h"

#include <memory>
#include <string>

#include "gpu/recording_device.h"
#include "gpu/sokol_device.h"

namespace fa::gpu {

bool Device::storage_image_loadable(PixelFormat format, std::string* why) const {
    if (why)
        *why = std::string("Device::storage_image_loadable is not implemented on the ") + backend_name(backend()) +
               " device yet (M77-P5d2 moved the question behind the device; each backend answers it for its GPU), so " +
               pixel_format_name(format) + " storage images are write-only there: use \"access\": \"write\"";
    return false;
}

Result<std::unique_ptr<Device>> make_device(Backend backend, const DeviceInit& init) {
    if (backend == Backend::Recording) return std::unique_ptr<Device>(std::make_unique<RecordingDevice>(init));
    if (backend == Backend::D3d12 || backend == Backend::Vulkan)
        return make_error(std::string("gpu: the ") + backend_name(backend) + " backend is not built yet",
                          "it arrives later in M77 (D3D12 in M77.2, Vulkan in M77.3); use built_sokol_backend() "
                          "or Backend::Recording");
    const Backend built = built_sokol_backend();
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
