// make_d3d12_device() where Direct3D 12 does not exist: a teaching error. The Windows factory is in
// d3d12_device_win32.cpp (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include "gpu/d3d12_device.h"

#if !defined(_WIN32)

#include <string>

namespace fa::gpu {

Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options&) {
    return make_error(std::string("gpu: the d3d12 backend runs on Windows only (this binary was built for another "
                                  "platform, whose sokol backend is ") +
                          backend_name(built_sokol_backend()) + ")",
                      "use make_device(built_sokol_backend()) here; Direct3D 12 exists only on Windows 10 and later");
}

}  // namespace fa::gpu

#endif
