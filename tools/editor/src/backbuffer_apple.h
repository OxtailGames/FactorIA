// Metal half of ui::read_backbuffer (backbuffer_apple.mm); imgui_backend.cpp calls it on macOS.
#pragma once

#include <cstdint>

namespace fa::editor::ui {

// Makes the window's next drawables readable by a blit (sokol_app creates the layer framebuffer-only), and keeps the
// window above the others (a covered window gets no drawables). Unless `show`, the window is see-through and lets
// clicks through, and the app in front keeps the keyboard: the person at the computer can go on working.
void metal_make_window_readable(bool show);
// Copies a frame's CAMetalDrawable to top-down RGBA8 with a blit on the renderer's id<MTLCommandQueue> (both come from
// render::native_window_handles()). Call after Renderer::commit_context(), inside the frame callback. False if the
// drawable is not readable or not w x h. This is the one native Metal use left in the editor: a window screenshot has no
// portable equivalent.
bool metal_read_drawable(const void* drawable, const void* queue, int w, int h, std::uint8_t* rgbaTopDown);

}  // namespace fa::editor::ui
