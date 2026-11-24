// make_device(): the factory of the GPU interface (gpu/device.h).
#include "gpu/device.h"

#include <memory>
#include <string>

#include "gpu/recording_device.h"
#include "gpu/sokol_device.h"

namespace fa::gpu {

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
