// The editor's Dear ImGui backend (imgui_backend.cpp), plus fonts and the dark theme. It draws through the renderer's
// public 2D painter (fa/render/ui_painter.h) and takes its input from sokol_app events: this file and its .cpp hold no
// sokol_gfx or sokol_imgui call.
#pragma once

#include <cstdint>

#include "fa/platform/app.h"

struct sapp_event;

namespace fa::editor::ui {

// Call once a graphics context is open (the renderer or gfx_setup() opened it). iniFile may be nullptr.
void setup(const char* iniFile);
// Frees the painter and with it every picture made by make_texture(): destroy the panels' pictures first.
void shutdown();
void new_frame(int fbWidth, int fbHeight, double dt, float dpiScale);
void flush();  // outside any pass, after building the UI: the texture updates, vertices and indices
// Inside the window pass on `swapchain`: draws the frame flush() prepared.
void draw(const fa::GfxSwapchain& swapchain);
bool handle_event(const sapp_event* ev);
// ImTextureID for a picture view (UiTexture::view of make_texture() or of the renderer's game target): `linear` smooths the
// picture when it is scaled, false shows its pixels as they are.
std::uint64_t texture_from_view(std::uint32_t viewId, bool linear);
// Creates an RGBA8 texture; returns {image id, view id} packed in the out params. False when there is no UI or the
// device refuses the picture.
bool make_texture(int w, int h, const std::uint8_t* rgba, std::uint32_t& imageId, std::uint32_t& viewId);
// Frees a picture made by make_texture(); does nothing after shutdown() (the pictures went with the painter's device).
void destroy_texture(std::uint32_t imageId, std::uint32_t viewId);

// The no-project state (no Renderer yet): opens / closes the graphics context (Renderer::open_context / close_context).
void gfx_setup();
void gfx_shutdown();

// Autotest screenshots of the whole window, top-down RGBA8. GL (Linux) and Metal (macOS); false elsewhere.
// - prepare_backbuffer_readback(): once the window exists (Metal: drawables are framebuffer-only by default, and macOS
//   gives a covered window none, so it also keeps the window above the others; see-through and out of the way of the
//   mouse and keyboard unless `showWindow`).
// - note_window_swapchain(): every frame, with the swapchain of the window pass (Metal reads that frame's drawable).
// - read_backbuffer(): after Renderer::commit_context(), before the frame callback returns (GL swaps after it; the
//   Metal drawable lives until then).
void prepare_backbuffer_readback(bool showWindow);
void note_window_swapchain(const fa::GfxSwapchain& swapchain);
bool read_backbuffer(int w, int h, std::uint8_t* rgbaTopDown);

}  // namespace fa::editor::ui
