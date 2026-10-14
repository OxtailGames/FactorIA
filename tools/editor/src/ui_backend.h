// Thin wrapper over sokol_imgui (the ONE translation unit with its implementation
// is imgui_backend.cpp) plus fonts and the dark theme.
#pragma once

#include <cstdint>

struct sapp_event;

namespace fa::editor::ui {

// Call after sg_setup() (the renderer or editor_gfx_setup() did it). iniFile may be nullptr.
void setup(const char* iniFile);
void shutdown();
void new_frame(int fbWidth, int fbHeight, double dt, float dpiScale);
void flush();  // outside any pass, after building the UI
void draw();   // inside the swapchain pass
bool handle_event(const sapp_event* ev);
// ImTextureID for a sokol texture view id (renderer game target) or an sg_image id (creates a view).
std::uint64_t texture_from_view(std::uint32_t viewId, bool linear);
// Creates an RGBA8 texture; returns {image id, view id} packed in the out params.
bool make_texture(int w, int h, const std::uint8_t* rgba, std::uint32_t& imageId, std::uint32_t& viewId);
void destroy_texture(std::uint32_t imageId, std::uint32_t viewId);

// Raw sokol_gfx init for the no-project state (no Renderer yet): sg_setup / sg_shutdown.
void gfx_setup();
void gfx_shutdown();

// Reads the default framebuffer (BGRA/RGBA top-down) for autotest screenshots. Linux GL only.
bool read_backbuffer(int w, int h, std::uint8_t* rgbaTopDown);

}  // namespace fa::editor::ui
