// Private to fa_render (M77-P5c): what UiPainter is made of, so the implementation (ui_painter.cpp) and the tests can run it
// on any gpu::Device, a RecordingDevice included. Public API: fa/render/ui_painter.h.
#pragma once

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "fa/render/ui_painter.h"
#include "gpu/device.h"

namespace fa::render {

// The caps of one frame (deterministic work counts, not times).
inline constexpr std::size_t kUiMaxVertices = std::size_t(1) << 22;    // 4 Mi vertices = 80 MiB, in one frame
inline constexpr std::size_t kUiFirstVertices = std::size_t(1) << 16;  // what the buffers start with (as sokol_imgui)
inline constexpr std::size_t kUiVertexBytes = sizeof(UiVertex);        // 20
inline constexpr std::size_t kUiIndexBytes = sizeof(std::uint16_t);

struct UiPainterImpl {
    // `device` outlives the painter; `owned` is set when the painter made it.
    gpu::Device* device = nullptr;
    std::unique_ptr<gpu::Device> owned;

    gpu::Shader shader{};
    gpu::Sampler linear{};
    gpu::Sampler nearest{};
    gpu::Buffer vertexBuffer{};
    gpu::Buffer indexBuffer{};
    std::size_t vertexCapacity = 0;  // bytes
    std::size_t indexCapacity = 0;
    gpu::Buffer staging{};
    std::size_t stagingCapacity = 0;
    std::unordered_map<gpu::TargetFormat, gpu::Pipeline> pipelines;
    // The views whose image format the device cannot filter linearly (a 32-bit float picture on some GPUs): they are
    // always sampled with `nearest`, whatever UiDrawCommand::nearest says, because a linear sampler on them is an error.
    std::unordered_set<std::uint32_t> unfilterableViews;

    // What upload() wrote for the frame it saw, per list: where its vertices and indices are in the buffers.
    struct Placed {
        std::size_t vertexByteOffset = 0;
        std::size_t indexByteOffset = 0;
    };
    std::vector<Placed> placed;  // placed.size() lists were uploaded (the first ones, when the frame is over the cap)

    struct Pending {
        gpu::Image image{};
        int x = 0, y = 0, width = 0, height = 0;
        std::vector<std::uint8_t> pixels;  // width * height * 4, tight
    };
    std::vector<Pending> pending;

    // Resources. False + `error` when the device cannot make them.
    bool init(std::string* error);
    ~UiPainterImpl();

    UiTexture make_texture(int width, int height, const std::uint8_t* rgba, bool updatable, std::string* error);
    bool update_texture(const UiTexture& texture, int x, int y, int width, int height, const std::uint8_t* rgba,
                        int bytesPerRow, std::string* error);
    void destroy_texture(const UiTexture& texture);

    // The two halves of a frame, on a list the caller owns (the sokol device's immediate list, or a recording device's).
    bool upload(gpu::CommandList& list, const UiFrame& frame, std::string* error);
    void draw(gpu::CommandList& list, const gpu::TargetFormat& format, const UiFrame& frame);

    gpu::Pipeline pipeline_for(const gpu::TargetFormat& format);
    // Tells the painter the format of the image behind `view` (make_texture does for its own pictures, always RGBA8).
    void note_view_format(std::uint32_t view, gpu::PixelFormat format);
    // The sampler `command` is drawn with: nearest when it asks for it or its view cannot be filtered, else linear.
    gpu::Sampler sampler_for(const UiDrawCommand& command) const;
    enum class Kind { Vertex, Index, Staging };
    // Makes `buffer` at least `needed` bytes (doubling), a writeTransient buffer of `kind`. False when the device refuses.
    bool grow(gpu::Buffer& buffer, std::size_t& capacity, std::size_t needed, Kind kind, const char* label);
};

// The painter on `device` (it must outlive the painter). Null with `error` when the pipeline cannot be made.
std::unique_ptr<UiPainter> make_ui_painter_on(gpu::Device& device, std::string* error);

// The painter's parts, for the tests.
struct UiPainterAccess {
    static UiPainterImpl& impl(UiPainter& painter) { return *painter.impl_; }
};

}  // namespace fa::render
