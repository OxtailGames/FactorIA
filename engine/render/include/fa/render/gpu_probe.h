// Can this machine start a GPU backend, before any window is open (M77-P9e2: the Vulkan player of Linux and Android asks
// it before it opens its window, fa/runtime/gpu_launch.h).
#pragma once

#include "fa/core/types.h"
#include "fa/render/renderer.h"

namespace fa {

// Vulkan: opens the system's loader, makes an instance and a device with small pools and drops them again (tens of
// milliseconds; nothing is drawn, no file is written). The error says what failed: no loader (no libvulkan.so.1, no
// driver installed), no instance, or no device with what the renderer needs (Vulkan 1.2, timeline semaphores, a graphics
// and compute queue). It does not try the window's surface: a failure there is reported when the window opens
// (EngineConfig::gpuBackendFailed). Every other backend: succeeds when gpu_backend_available() says this binary has it,
// fails with a teaching error otherwise.
Result<void> probe_gpu_backend(GpuBackend backend);

}  // namespace fa
