// UiPainter (M77-P5c): the 2D painter of a client that draws its own interface into the window, such as the editor's Dear
// ImGui. It draws triangle lists (pos, uv, colour per vertex, 16-bit indices) with one texture and one scissor rectangle per
// command, and makes the pictures such a client shows. It knows nothing of ImGui: the editor turns an ImDrawData into
// UiDrawLists (tools/editor/src/imgui_backend.cpp) and any other 2D client can do the same.
//
// It is implemented on the renderer's private GPU interface (src/gpu/, docs/design/ARCHITECTURE_RENDERING_GPU.md), so the
// client never sees a sokol or a Metal/D3D handle: pictures are UiTexture ids, the window is a GfxSwapchain, and the few
// native objects a screenshot needs come from native_window_handles().
//
// One frame, on the render thread, with an open graphics context (Renderer::open_context or a Renderer that opened it):
//   upload(frame)                       outside any pass: vertices, indices and the pending texture updates
//   Renderer::begin_window_pass(...)    a pass into the window, as the editor does
//   draw(swapchain, frame)              inside that pass, with the same `frame`
//   Renderer::end_window_pass()
//   Renderer::commit_context()
// Textures can be made and destroyed at any time outside a pass, in the same thread.
#pragma once

#include <cstdint>
#include <memory>
#include <string>

#include "fa/platform/app.h"

namespace fa::render {

// One vertex of a UiDrawList: 20 bytes, the layout of an ImDrawVert. `color` is four normalised bytes, red in the lowest
// (0xAABBGGRR on a little-endian machine).
struct UiVertex {
    float x = 0.0f, y = 0.0f;  // display units, origin top left
    float u = 0.0f, v = 0.0f;  // texture coordinates, origin top left
    std::uint32_t color = 0xFFFFFFFFu;
};

// A picture the painter shows: `image` is the memory, `view` is what a UiDrawCommand names. Both are 0 when it was not made.
// The ids are opaque numbers of the renderer; a picture belongs to the graphics context that made it.
struct UiTexture {
    std::uint32_t image = 0;
    std::uint32_t view = 0;
    bool valid() const { return view != 0; }
};

// One draw: `indexCount` indices from `indexOffset` of its list, each plus `vertexOffset`, with the texture `view` and the
// scissor rectangle clip* (display units; the painter multiplies by UiFrame::scaleX/scaleY, clamps to the window and skips a
// command with nothing inside).
struct UiDrawCommand {
    std::uint32_t view = 0;  // UiTexture::view; the texture must be a filterable colour format (RGBA8, RGBA16F...)
    bool nearest = false;    // sample without smoothing (pixel art); false = linear
    float clipMinX = 0.0f, clipMinY = 0.0f, clipMaxX = 0.0f, clipMaxY = 0.0f;
    std::uint32_t indexOffset = 0;
    std::uint32_t indexCount = 0;
    std::uint32_t vertexOffset = 0;
};

// A vertex array, an index array into it (16 bits, plus each command's vertexOffset) and the commands that draw from them.
// The pointers stay valid until the frame is drawn.
struct UiDrawList {
    const UiVertex* vertices = nullptr;
    int vertexCount = 0;
    const std::uint16_t* indices = nullptr;
    int indexCount = 0;
    const UiDrawCommand* commands = nullptr;
    int commandCount = 0;
};

// What one frame draws.
struct UiFrame {
    float displayWidth = 0.0f;  // the size of the display in the units of the vertex positions
    float displayHeight = 0.0f;
    float scaleX = 1.0f;  // window pixels per display unit (the dpi scale)
    float scaleY = 1.0f;
    const UiDrawList* lists = nullptr;
    int listCount = 0;
};

// The native objects behind the window, for the one client that must read the picture back (the editor's autotest
// screenshots): null where the backend has none. `metalDrawable` is this frame's CAMetalDrawable (it lives until the frame
// callback returns), `metalQueue` an id<MTLCommandQueue>, the d3d11 ones an ID3D11Device and its immediate context.
struct UiNativeHandles {
    const void* metalDrawable = nullptr;
    const void* metalQueue = nullptr;
    const void* d3d11Device = nullptr;
    const void* d3d11Context = nullptr;
};
// The handles of the open graphics context and of `swapchain` (this frame's window surface). Needs an open context.
UiNativeHandles native_window_handles(const GfxSwapchain& swapchain);

struct UiPainterImpl;

class UiPainter {
public:
    // Makes a painter on the open graphics context (Renderer::open_context, or a Renderer that opened one). Null with
    // `error` when there is none or the device cannot make its pipeline.
    static std::unique_ptr<UiPainter> create(std::string* error);
    explicit UiPainter(std::unique_ptr<UiPainterImpl> impl);  // see ui_painter_internal.h
    ~UiPainter();
    UiPainter(const UiPainter&) = delete;
    UiPainter& operator=(const UiPainter&) = delete;

    // A picture of `width` x `height` RGBA8 pixels (rows top to bottom, `rgba` is width * height * 4 bytes). Invalid with
    // `error` when the size is not positive, `rgba` is null or the device refuses it.
    UiTexture make_texture(int width, int height, const std::uint8_t* rgba, std::string* error = nullptr);
    // An RGBA8 picture whose pixels are filled in later with update_texture (a glyph atlas). Its pixels are undefined
    // until the first update covers them.
    UiTexture make_updatable_texture(int width, int height, std::string* error = nullptr);
    // Queues `width` x `height` pixels at (x, y) of an updatable texture: `rgba` has rows of `bytesPerRow` bytes (0 = tight)
    // and is copied now; the next upload() writes it. False with `error` when the rectangle is outside the picture.
    bool update_texture(const UiTexture& texture, int x, int y, int width, int height, const std::uint8_t* rgba,
                        int bytesPerRow = 0, std::string* error = nullptr);
    // Frees a picture (an invalid one does nothing). A picture still named by a frame that was not drawn must not be freed.
    void destroy_texture(const UiTexture& texture);

    // Outside a pass: writes the frame's vertices and indices and the queued texture updates. False with `error` when the
    // frame holds more than the painter's cap (about 4 million vertices); the lists that fit are still drawn.
    bool upload(const UiFrame& frame, std::string* error = nullptr);
    // Inside a window pass on `swapchain` (begun by Renderer::begin_window_pass): draws what upload() wrote for `frame`.
    void draw(const GfxSwapchain& swapchain, const UiFrame& frame);

private:
    friend struct UiPainterAccess;  // ui_painter_internal.h: the tests and the implementation reach the impl
    std::unique_ptr<UiPainterImpl> impl_;
};

}  // namespace fa::render
