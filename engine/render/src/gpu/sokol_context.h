// Private to fa_render: the sokol context's own lifecycle, for the renderer code that runs while no gpu::Device exists
// (Renderer::open_context, init and shutdown, present_clear and the window passes before any renderer is made, the UI
// painter's native handles). Sokol-free: the implementation is sokol_context.cpp, one of the sokol backend's files.
// Everything that has a device goes through gpu::Device / gpu::CommandList instead.
#pragma once

#include "gpu/types.h"

namespace fa {
struct GfxEnvironment;  // fa/platform/app.h
struct GfxSwapchain;
}  // namespace fa

namespace fa::gpu {

// Whether a sokol context is open (sg_isvalid).
bool context_open();
// Opens the sokol context of the window's environment `env`, with DeviceInit's pool sizes and uniform buffer size (the
// renderer's) and the engine's logger. False when a context is already open or the setup failed (the 'sg' log lines
// say why).
bool open_context(const GfxEnvironment& env);
// Closes the open context (nothing when none is open). Every Device on it must be gone first.
void close_context();
// Ends the frame of the open context (sg_commit). False when none is open.
bool commit_context();
// The backend of the open context (built_sokol_backend() names the one this binary was built with); Recording when
// none is open.
Backend context_backend();
// The native objects of the open context (Device::native() of a SokolDevice on it); empty when none is open.
NativeDevice context_native();
// The default formats of the open context; EnvironmentDefaults{} when none is open.
EnvironmentDefaults context_defaults();
// The engine's description of the window's swapchain `sc` (its images, formats and native objects).
Swapchain swapchain_of(const GfxSwapchain& sc);
// The default formats and sample count of the window's environment `env` (what Default means in its swapchain pass),
// for a device that does not run on the sokol context (RendererDesc::backend D3d12, Vulkan, Recording).
EnvironmentDefaults environment_defaults_of(const GfxEnvironment& env);

// Begins / ends a pass directly on the open context. Only for a pass that can run while no Device exists
// (Renderer::present_clear runs before the renderer is made, and the window passes share it); everything else begins
// its passes on a CommandList.
void begin_context_pass(const PassDesc& pass);
void end_context_pass();

}  // namespace fa::gpu
