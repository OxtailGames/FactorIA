// Metal half of ui::read_backbuffer (backbuffer_apple.mm); imgui_backend.cpp calls it on macOS.
#pragma once

#include <cstdint>

namespace fa::editor::ui {

// Makes the window's next drawables readable by a blit (sokol_app creates the layer framebuffer-only).
void metal_make_window_readable();
// Copies a frame's CAMetalDrawable (the swapchain's metal.current_drawable) to top-down RGBA8. Call after sg_commit(),
// inside the frame callback. False if the drawable is not readable or not w x h.
bool metal_read_drawable(const void* drawable, int w, int h, std::uint8_t* rgbaTopDown);

}  // namespace fa::editor::ui
