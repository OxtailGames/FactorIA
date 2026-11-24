// UiPainter: the 2D painter of a client that draws its own interface (the editor's Dear ImGui), on the renderer's private GPU
// interface. Public API: fa/render/ui_painter.h. docs/design/ARCHITECTURE_RENDERING_GPU.md ("The 2D painter").
#include "fa/render/ui_painter.h"

#include <algorithm>
#include <cstring>

#include "gpu/sokol_context.h"
#include "gpu/sokol_shaders.h"
#include "shaders/ui2d.glsl.h"
#include "ui_painter_internal.h"

namespace fa::render {

namespace {

constexpr std::size_t kStagingAlign = 16;  // where one update starts inside the staging buffer
constexpr std::size_t kMaxTextureBytes = std::size_t(1) << 30;

std::size_t round_up(std::size_t v, std::size_t a) { return (v + a - 1) / a * a; }

void set_error(std::string* error, std::string message) {
    if (error) *error = std::move(message);
}

}  // namespace

UiNativeHandles native_window_handles(const GfxSwapchain& swapchain) {
    UiNativeHandles h;
    if (!gpu::context_open()) return h;
    // The open context's native objects (what Device::native() of a device on it returns): empty on GL.
    const gpu::NativeDevice n = gpu::context_native();
    switch (gpu::context_backend()) {
        case gpu::Backend::Metal:
            h.metalDrawable = gpu::swapchain_of(swapchain).metal.currentDrawable;
            h.metalQueue = n.commandQueue;
            break;
        case gpu::Backend::D3d11:
            h.d3d11Device = n.device;
            h.d3d11Context = n.context;
            break;
        default: break;
    }
    return h;
}

// ---------------------------------------------------------------------------------------------------------------------
// UiPainterImpl
// ---------------------------------------------------------------------------------------------------------------------
bool UiPainterImpl::init(std::string* error) {
    gpu::ShaderDesc sd = gpu::generated_shader_desc(ui2d_ui2d_shader_desc);
    sd.label = "ui2d";
    shader = device->make_shader(sd);
    if (device->state(shader) != gpu::ResourceState::Valid) {
        set_error(error, "the 2D painter's shader did not compile on this device (see the graphics log lines above)");
        return false;
    }
    gpu::SamplerDesc smp;
    smp.wrapU = smp.wrapV = gpu::Wrap::ClampToEdge;
    smp.minFilter = smp.magFilter = gpu::Filter::Linear;
    smp.label = "ui2d_linear";
    linear = device->make_sampler(smp);
    smp.minFilter = smp.magFilter = gpu::Filter::Nearest;
    smp.label = "ui2d_nearest";
    nearest = device->make_sampler(smp);
    if (!grow(vertexBuffer, vertexCapacity, kUiFirstVertices * kUiVertexBytes, Kind::Vertex, "ui2d_vertices") ||
        !grow(indexBuffer, indexCapacity, kUiFirstVertices * 3 * kUiIndexBytes, Kind::Index, "ui2d_indices")) {
        set_error(error, "the 2D painter's vertex buffers could not be made");
        return false;
    }
    return true;
}

UiPainterImpl::~UiPainterImpl() {
    if (!device) return;
    for (auto& [format, pipeline] : pipelines) device->destroy_pipeline(pipeline);
    device->destroy_buffer(staging);
    device->destroy_buffer(indexBuffer);
    device->destroy_buffer(vertexBuffer);
    device->destroy_sampler(nearest);
    device->destroy_sampler(linear);
    device->destroy_shader(shader);
}

bool UiPainterImpl::grow(gpu::Buffer& buffer, std::size_t& capacity, std::size_t needed, Kind kind, const char* label) {
    if (buffer.valid() && capacity >= needed) return true;
    const std::size_t size =
        std::max(needed, capacity * 2);  // doubling: a growing UI makes a few buffers, not one a frame
    gpu::BufferDesc d;
    d.size = size;
    d.usage.writeTransient = true;
    d.usage.indexBuffer = kind == Kind::Index;
    d.usage.stagingBuffer = kind == Kind::Staging;  // a staging buffer is only a copy source
    d.usage.copySrc = kind == Kind::Staging;
    d.label = label;
    const gpu::Buffer fresh = device->make_buffer(d);
    if (device->state(fresh) != gpu::ResourceState::Valid) {
        device->destroy_buffer(fresh);
        return false;
    }
    device->destroy_buffer(buffer);
    buffer = fresh;
    capacity = size;
    return true;
}

gpu::Pipeline UiPainterImpl::pipeline_for(const gpu::TargetFormat& format) {
    const auto it = pipelines.find(format);
    if (it != pipelines.end()) return it->second;
    gpu::PipelineDesc d;
    d.shader = shader;
    d.layout.buffers[0].stride = int(kUiVertexBytes);
    d.layout.attrs[ATTR_ui2d_ui2d_position] = {0, int(offsetof(UiVertex, x)), gpu::VertexFormat::Float2};
    d.layout.attrs[ATTR_ui2d_ui2d_texcoord0] = {0, int(offsetof(UiVertex, u)), gpu::VertexFormat::Float2};
    d.layout.attrs[ATTR_ui2d_ui2d_color0] = {0, int(offsetof(UiVertex, color)), gpu::VertexFormat::Ubyte4N};
    d.indexType = gpu::IndexType::Uint16;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.depth.pixelFormat = format.depth;
    d.sampleCount = format.samples;
    d.colors[0].pixelFormat = format.color;
    d.colors[0].writeMask = gpu::ColorMask::Rgb;  // the window's alpha is never read (what sokol_imgui does)
    d.colors[0].blend.enabled = true;
    d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
    d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::OneMinusSrcAlpha;
    d.label = "ui2d";
    const gpu::Pipeline p = device->make_pipeline(d);
    if (device->state(p) != gpu::ResourceState::Valid) {
        device->destroy_pipeline(p);
        return {};
    }
    pipelines.emplace(format, p);
    return p;
}

UiTexture UiPainterImpl::make_texture(int width, int height, const std::uint8_t* rgba, bool updatable,
                                      std::string* error) {
    const int maxSize = device->limits().maxImageSize2d;
    if (width <= 0 || height <= 0 || (maxSize > 0 && (width > maxSize || height > maxSize))) {
        set_error(error, "a UI picture needs a size from 1 to " + std::to_string(maxSize > 0 ? maxSize : 16384) +
                             " pixels, got " + std::to_string(width) + " x " + std::to_string(height));
        return {};
    }
    const std::size_t bytes = std::size_t(width) * std::size_t(height) * 4;
    if (bytes > kMaxTextureBytes || (!updatable && !rgba)) {
        set_error(error, !updatable && !rgba ? "a UI picture needs its pixels (rgba is null)"
                                             : "a UI picture of " + std::to_string(bytes) + " bytes is too big");
        return {};
    }
    gpu::ImageDesc d;
    d.width = width;
    d.height = height;
    d.pixelFormat = gpu::PixelFormat::Rgba8;
    if (updatable)
        d.usage.copyDst = true;
    else
        d.data.mipLevels[0] = gpu::Range{rgba, bytes};
    d.label = updatable ? "ui_texture_updatable" : "ui_texture";
    const gpu::Image image = device->make_image(d);
    if (device->state(image) != gpu::ResourceState::Valid) {
        device->destroy_image(image);
        set_error(error, "the device could not make a " + std::to_string(width) + " x " + std::to_string(height) +
                             " picture (see the graphics log lines above)");
        return {};
    }
    gpu::ViewDesc vd;
    vd.texture.image = image;
    vd.label = "ui_texture_view";
    const gpu::View view = device->make_view(vd);
    if (device->state(view) != gpu::ResourceState::Valid) {
        device->destroy_view(view);
        device->destroy_image(image);
        set_error(error, "the device could not make a view of the picture");
        return {};
    }
    return UiTexture{image.id, view.id};
}

bool UiPainterImpl::update_texture(const UiTexture& texture, int x, int y, int width, int height,
                                   const std::uint8_t* rgba, int bytesPerRow, std::string* error) {
    if (!texture.valid() || !rgba || width <= 0 || height <= 0 || x < 0 || y < 0) {
        set_error(error, "update_texture needs a made texture, pixels and a rectangle inside the picture");
        return false;
    }
    const std::size_t stride = bytesPerRow > 0 ? std::size_t(bytesPerRow) : std::size_t(width) * 4;
    if (stride < std::size_t(width) * 4) {
        set_error(error, "update_texture: bytesPerRow " + std::to_string(bytesPerRow) + " is less than width * 4");
        return false;
    }
    Pending p;
    p.image = gpu::Image{texture.image};
    p.x = x;
    p.y = y;
    p.width = width;
    p.height = height;
    p.pixels.resize(std::size_t(width) * std::size_t(height) * 4);
    for (int row = 0; row < height; ++row)
        std::memcpy(p.pixels.data() + std::size_t(row) * std::size_t(width) * 4, rgba + std::size_t(row) * stride,
                    std::size_t(width) * 4);
    pending.push_back(std::move(p));
    return true;
}

void UiPainterImpl::destroy_texture(const UiTexture& texture) {
    if (texture.image) {
        pending.erase(std::remove_if(pending.begin(), pending.end(),
                                     [&](const Pending& p) { return p.image.id == texture.image; }),
                      pending.end());
    }
    if (texture.view) device->destroy_view(gpu::View{texture.view});
    if (texture.image) device->destroy_image(gpu::Image{texture.image});
}

bool UiPainterImpl::upload(gpu::CommandList& list, const UiFrame& frame, std::string* error) {
    placed.clear();
    bool ok = true;

    // The pictures first: every write into the staging buffer, then every copy out of it (the two cannot interleave).
    if (!pending.empty()) {
        std::size_t total = 0;
        for (const Pending& p : pending) total = round_up(total, kStagingAlign) + p.pixels.size();
        if (!grow(staging, stagingCapacity, total, Kind::Staging, "ui2d_staging")) {
            set_error(error, "the 2D painter could not make a staging buffer of " + std::to_string(total) + " bytes");
            pending.clear();
            ok = false;
        }
    }
    if (!pending.empty()) {
        std::size_t offset = 0;
        for (const Pending& p : pending) {
            offset = round_up(offset, kStagingAlign);
            gpu::BufferWrite w;
            w.data = gpu::Range{p.pixels.data(), p.pixels.size()};
            w.buffer = staging;
            w.dstOffset = offset;
            list.write_buffer(w);
            offset += p.pixels.size();
        }
        offset = 0;
        for (const Pending& p : pending) {
            offset = round_up(offset, kStagingAlign);
            gpu::BufferImageCopy c;
            c.src = staging;
            c.srcOffset = offset;
            c.bytesPerRow = p.width * 4;
            c.bytesPerSlice = p.height * c.bytesPerRow;
            c.dst.image = p.image;
            c.dst.x = p.x;
            c.dst.y = p.y;
            c.size.width = p.width;
            c.size.height = p.height;
            list.copy_buffer_to_image(c);
            offset += p.pixels.size();
        }
        pending.clear();
    }

    // The lists that fit under the cap, laid out one after the other.
    std::size_t vertices = 0;
    std::size_t indexBytes = 0;
    std::size_t fit = 0;
    for (int i = 0; i < frame.listCount; ++i) {
        const UiDrawList& l = frame.lists[i];
        const std::size_t v = l.vertexCount > 0 ? std::size_t(l.vertexCount) : 0;
        if (vertices + v > kUiMaxVertices) {
            set_error(error, "the UI frame has more than " + std::to_string(kUiMaxVertices) +
                                 " vertices: " + std::to_string(frame.listCount - int(fit)) + " of " +
                                 std::to_string(frame.listCount) + " draw lists are not drawn");
            ok = false;
            break;
        }
        vertices += v;
        indexBytes = round_up(indexBytes + (l.indexCount > 0 ? std::size_t(l.indexCount) : 0) * kUiIndexBytes, 4);
        ++fit;
    }
    if (fit == 0) return ok;
    if (!grow(vertexBuffer, vertexCapacity, vertices * kUiVertexBytes, Kind::Vertex, "ui2d_vertices") ||
        !grow(indexBuffer, indexCapacity, indexBytes, Kind::Index, "ui2d_indices")) {
        set_error(error,
                  "the 2D painter could not grow its vertex buffers to " + std::to_string(vertices) + " vertices");
        return false;
    }
    std::size_t vOff = 0;
    std::size_t iOff = 0;
    for (std::size_t i = 0; i < fit; ++i) {
        const UiDrawList& l = frame.lists[i];
        placed.push_back(Placed{vOff, iOff});
        const std::size_t vBytes = l.vertexCount > 0 ? std::size_t(l.vertexCount) * kUiVertexBytes : 0;
        const std::size_t iBytes = l.indexCount > 0 ? std::size_t(l.indexCount) * kUiIndexBytes : 0;
        if (vBytes > 0 && l.vertices) {
            gpu::BufferWrite w;
            w.data = gpu::Range{l.vertices, vBytes};
            w.buffer = vertexBuffer;
            w.dstOffset = vOff;
            list.write_buffer(w);
        }
        if (iBytes > 0 && l.indices) {
            gpu::BufferWrite w;
            w.data = gpu::Range{l.indices, iBytes};
            w.buffer = indexBuffer;
            w.dstOffset = iOff;
            list.write_buffer(w);
        }
        vOff += vBytes;
        iOff = round_up(iOff + iBytes, 4);  // 16-bit indices: the next list starts on a 4-byte boundary
    }
    return ok;
}

void UiPainterImpl::draw(gpu::CommandList& list, const gpu::TargetFormat& format, const UiFrame& frame) {
    if (placed.empty() || frame.displayWidth <= 0.0f || frame.displayHeight <= 0.0f) return;
    const gpu::Pipeline pipeline = pipeline_for(format);
    if (!pipeline.valid()) return;
    const int fbW = int(frame.displayWidth * frame.scaleX);
    const int fbH = int(frame.displayHeight * frame.scaleY);
    if (fbW <= 0 || fbH <= 0) return;

    list.push_debug_group("ui2d");
    list.set_pipeline(pipeline);
    list.set_viewport(0, 0, fbW, fbH, true);
    // Positions are in display units; an sRGB target encodes the vertex colour once more, which gamma 2.2 undoes.
    const bool srgb = format.color == gpu::PixelFormat::Srgb8A8 || format.color == gpu::PixelFormat::Sbgr8A8;
    ui2d_ui2d_vs_params_t params{};
    params.params[0] = frame.displayWidth;
    params.params[1] = frame.displayHeight;
    params.params[2] = srgb ? 2.2f : 1.0f;
    list.set_uniforms(UB_ui2d_ui2d_vs_params, gpu::Range{&params, sizeof(params)});

    for (std::size_t i = 0; i < placed.size() && int(i) < frame.listCount; ++i) {
        const UiDrawList& l = frame.lists[i];
        gpu::Bindings b;
        b.vertexBuffers[0] = vertexBuffer;
        b.indexBuffer = indexBuffer;
        b.indexBufferOffset = int(placed[i].indexByteOffset);
        std::uint32_t boundView = 0;
        bool boundNearest = false;
        std::uint32_t boundVertexOffset = 0;
        bool anyBound = false;
        for (int c = 0; c < l.commandCount; ++c) {
            const UiDrawCommand& cmd = l.commands[c];
            if (cmd.view == 0 || cmd.indexCount == 0) continue;
            // The scissor in window pixels, cut to the window (sokol_imgui truncates the same way).
            int x0 = int(cmd.clipMinX * frame.scaleX);
            int y0 = int(cmd.clipMinY * frame.scaleY);
            int x1 = x0 + int((cmd.clipMaxX - cmd.clipMinX) * frame.scaleX);
            int y1 = y0 + int((cmd.clipMaxY - cmd.clipMinY) * frame.scaleY);
            x0 = std::max(x0, 0);
            y0 = std::max(y0, 0);
            x1 = std::min(x1, fbW);
            y1 = std::min(y1, fbH);
            if (x1 <= x0 || y1 <= y0) continue;
            if (!anyBound || boundView != cmd.view || boundNearest != cmd.nearest ||
                boundVertexOffset != cmd.vertexOffset) {
                anyBound = true;
                boundView = cmd.view;
                boundNearest = cmd.nearest;
                boundVertexOffset = cmd.vertexOffset;
                b.views[0] = gpu::View{cmd.view};
                b.samplers[0] = cmd.nearest ? nearest : linear;
                b.vertexBufferOffsets[0] =
                    int(placed[i].vertexByteOffset + std::size_t(cmd.vertexOffset) * kUiVertexBytes);
                list.set_bindings(b);
            }
            list.set_scissor(x0, y0, x1 - x0, y1 - y0, true);
            list.draw(int(cmd.indexOffset), int(cmd.indexCount), 1);
        }
    }
    list.set_scissor(0, 0, fbW, fbH, true);
    list.pop_debug_group();
}

std::unique_ptr<UiPainter> make_ui_painter_on(gpu::Device& device, std::string* error) {
    auto impl = std::make_unique<UiPainterImpl>();
    impl->device = &device;
    if (!impl->init(error)) return nullptr;
    return std::make_unique<UiPainter>(std::move(impl));
}

// ---------------------------------------------------------------------------------------------------------------------
// UiPainter
// ---------------------------------------------------------------------------------------------------------------------
UiPainter::UiPainter(std::unique_ptr<UiPainterImpl> impl) : impl_(std::move(impl)) {}
UiPainter::~UiPainter() = default;

std::unique_ptr<UiPainter> UiPainter::create(std::string* error) {
    if (!gpu::context_open()) {
        set_error(error, "UiPainter::create needs an open graphics context (Renderer::open_context, or a Renderer)");
        return nullptr;
    }
    // The sokol context is one per process and its ids are shared by every device on it, so this device and the renderer's
    // see each other's pictures (the editor shows the game's picture through it).
    auto made = gpu::make_device(gpu::built_sokol_backend());
    if (!made.ok()) {
        set_error(error, made.error().to_string());
        return nullptr;
    }
    auto impl = std::make_unique<UiPainterImpl>();
    impl->owned = std::move(made.value());
    impl->device = impl->owned.get();
    if (!impl->init(error)) return nullptr;
    return std::make_unique<UiPainter>(std::move(impl));
}

UiTexture UiPainter::make_texture(int width, int height, const std::uint8_t* rgba, std::string* error) {
    return impl_->make_texture(width, height, rgba, false, error);
}
UiTexture UiPainter::make_updatable_texture(int width, int height, std::string* error) {
    return impl_->make_texture(width, height, nullptr, true, error);
}
bool UiPainter::update_texture(const UiTexture& texture, int x, int y, int width, int height, const std::uint8_t* rgba,
                               int bytesPerRow, std::string* error) {
    return impl_->update_texture(texture, x, y, width, height, rgba, bytesPerRow, error);
}
void UiPainter::destroy_texture(const UiTexture& texture) { impl_->destroy_texture(texture); }

bool UiPainter::upload(const UiFrame& frame, std::string* error) {
    gpu::Device& device = *impl_->device;
    gpu::CommandList& list = device.begin_commands("ui upload");
    const bool ok = impl_->upload(list, frame, error);
    device.submit(list);
    return ok;
}

void UiPainter::draw(const GfxSwapchain& swapchain, const UiFrame& frame) {
    gpu::Device& device = *impl_->device;
    const gpu::Swapchain sc = gpu::swapchain_of(swapchain);
    const gpu::PassDesc pass = gpu::PassDesc::for_swapchain(sc, device.environment_defaults());
    gpu::CommandList& list = device.begin_commands("ui draw");
    impl_->draw(list, pass.format, frame);
    device.submit(list);
}

}  // namespace fa::render
