// The Windows half of hdr_output.cpp (hdr_output_win32.cpp, D3D11 only). Private to fa_platform.
#pragma once

#include "fa/platform/hdr_output.h"

namespace fa::hdr_impl {

// The DXGI output the window is on (IDXGIOutput6::GetDesc1). Asked again only when the window's monitor changes or the
// DXGI factory is stale (a display was added or removed, or HDR was switched on or off), so it is cheap every frame.
HdrDisplay dxgi_display();
// Switches the swapchain to `encoding` (Sdr, ScRgb or Hdr10): its buffers (fa_sapp_set_swapchain_kind) and its colour
// space (IDXGISwapChain3::SetColorSpace1). Returns what is in effect afterwards (Sdr when the driver refused).
HdrEncoding dxgi_apply(HdrEncoding encoding);
// Once per frame while `applied` is in effect: sets the colour space again after the window's swapchain buffers were
// resized (ResizeBuffers gives them DXGI's default colour space back). Cheap: it only compares the framebuffer size.
void dxgi_keep_color_space(HdrEncoding applied);

}  // namespace fa::hdr_impl
