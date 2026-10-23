// Metal half of ui::read_backbuffer (backbuffer_apple.mm); imgui_backend.cpp calls it on macOS.
#pragma once

#include <cstdint>

namespace fa::editor::ui {

// Makes the window's next drawables readable by a blit (sokol_app creates the layer framebuffer-only), and keeps the
// window above the others (a covered window gets no drawables). Unless `show`, the window is see-through and lets
// clicks through, and the app in front keeps the keyboard: the person at the computer can go on working.
void metal_make_window_readable(bool show);
// Copies a frame's CAMetalDrawable (the swapchain's metal.current_drawable) to top-down RGBA8. Call after sg_commit(),
// inside the frame callback. False if the drawable is not readable or not w x h.
bool metal_read_drawable(const void* drawable, int w, int h, std::uint8_t* rgbaTopDown);

}  // namespace fa::editor::ui
