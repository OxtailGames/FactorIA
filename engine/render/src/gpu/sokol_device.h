// Private to fa_render: the GPU interface on sokol_gfx (GL, GLES3, WebGL2, D3D11, Metal), and the conversions between
// this interface's types and sokol's. Only the sokol backend's files include it (sokol_device.cpp, sokol_context.cpp,
// sokol_native.h's readbacks, gpu_timer.cpp, device.cpp's factory) and the tests that compare the two sides: the
// renderer reaches sokol through gpu::Device (docs/design/ARCHITECTURE_RENDERING_GPU.md, "P5d3").
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <thread>

#include "gpu/device.h"
#include "sokol_gfx.h"

namespace fa::render {
class GpuTimer;
}  // namespace fa::render

namespace fa::gpu {

// ---- conversions ---------------------------------------------------------------------------------------------------
// Every enum of gpu/types.h has sokol's values, so an enum converts with a static_cast (sokol_device.cpp asserts each
// value) and a handle by its id: gpu::Image{img.id} and sg_image{h.id} name the same image. The descs are converted
// field by field (sokol_device.cpp).
inline sg_buffer to_sg(Buffer h) { return sg_buffer{h.id}; }
inline sg_image to_sg(Image h) { return sg_image{h.id}; }
inline sg_view to_sg(View h) { return sg_view{h.id}; }
inline sg_sampler to_sg(Sampler h) { return sg_sampler{h.id}; }
inline sg_shader to_sg(Shader h) { return sg_shader{h.id}; }
inline sg_pipeline to_sg(Pipeline h) { return sg_pipeline{h.id}; }
inline Buffer from_sg(sg_buffer h) { return Buffer{h.id}; }
inline Image from_sg(sg_image h) { return Image{h.id}; }
inline View from_sg(sg_view h) { return View{h.id}; }
inline Sampler from_sg(sg_sampler h) { return Sampler{h.id}; }
inline Shader from_sg(sg_shader h) { return Shader{h.id}; }
inline Pipeline from_sg(sg_pipeline h) { return Pipeline{h.id}; }

inline sg_pixel_format to_sg(PixelFormat f) { return static_cast<sg_pixel_format>(f); }
inline PixelFormat from_sg(sg_pixel_format f) { return static_cast<PixelFormat>(f); }
inline sg_resource_state to_sg(ResourceState s) { return static_cast<sg_resource_state>(s); }
inline ResourceState from_sg(sg_resource_state s) { return static_cast<ResourceState>(s); }
inline sg_load_action to_sg(LoadAction a) { return static_cast<sg_load_action>(a); }
inline LoadAction from_sg(sg_load_action a) { return static_cast<LoadAction>(a); }
inline sg_store_action to_sg(StoreAction a) { return static_cast<sg_store_action>(a); }
inline StoreAction from_sg(sg_store_action a) { return static_cast<StoreAction>(a); }
inline sg_pass_state to_sg(PassState s) { return static_cast<sg_pass_state>(s); }
inline PassState from_sg(sg_pass_state s) { return static_cast<PassState>(s); }
inline sg_color to_sg(const Color& c) { return sg_color{c.r, c.g, c.b, c.a}; }
inline Color from_sg(const sg_color& c) { return Color{c.r, c.g, c.b, c.a}; }
inline sg_range to_sg(Range r) { return sg_range{r.ptr, r.size}; }
inline Range from_sg(sg_range r) { return Range{r.ptr, r.size}; }

// The engine Backend of a sokol backend (GLES3 is WebGl2 in an Emscripten build; DUMMY, which the engine never builds,
// is Recording: no GPU either way), and the Metal platform.
Backend backend_from_sg(sg_backend b);
MetalTarget metal_target_from_sg(sg_backend b);

sg_buffer_desc to_sg(const BufferDesc& d);
sg_image_desc to_sg(const ImageDesc& d);
sg_view_desc to_sg(const ViewDesc& d);
sg_sampler_desc to_sg(const SamplerDesc& d);
sg_shader_function to_sg(const ShaderFunction& f);
sg_shader_desc to_sg(const ShaderDesc& d);
sg_pipeline_desc to_sg(const PipelineDesc& d);
sg_bindings to_sg(const Bindings& b);
sg_swapchain to_sg(const Swapchain& s);
sg_environment to_sg(const Environment& e);
// The sokol pass of a PassDesc.
sg_pass to_sg(const PassDesc& p);
// The generated shader headers return sokol descs: this is how they reach Device::make_shader (gpu/sokol_shaders.h).
// The strings and bytecode stay the header's (static data).
ShaderFunction from_sg(const sg_shader_function& s);
ShaderDesc from_sg(const sg_shader_desc& d);
PipelineDesc from_sg(const sg_pipeline_desc& d);
VertexLayout from_sg(const sg_vertex_layout_state& l);
Swapchain from_sg(const sg_swapchain& s);
EnvironmentDefaults from_sg(const sg_environment_defaults& d);
PixelFormatCaps from_sg(const sg_pixelformat_info& i);
Features from_sg(const sg_features& f);
Limits from_sg(const sg_limits& l);
ResourceTotals from_sg(const sg_total_resource_stats& t);

// The sokol setup of a context opened from `init`: its environment, pool sizes, uniform buffer size and the engine's
// logger. SokolDevice::create and gpu::open_context (gpu/sokol_context.h) open the context with it.
sg_desc sokol_setup_desc(const DeviceInit& init);
// The native objects of the open sokol context (SokolDevice::native and gpu::context_native).
NativeDevice sokol_native_device();

class AsyncBufferRead;  // gpu/sokol_native.h
class SokolDevice;

// The one immediate command list of a SokolDevice: every call runs the sokol function at once.
class SokolCommandList final : public CommandList {
public:
    explicit SokolCommandList(SokolDevice& device) : device_(device) {}
    void begin_pass(const PassDesc& pass) override;
    void begin_compute_pass(const char* label) override;
    void end_pass() override;
    PassState pass_state() const override;
    void set_pipeline(Pipeline pipeline) override;
    void set_bindings(const Bindings& bindings) override;
    void set_uniforms(int slot, Range data) override;
    void set_viewport(int x, int y, int width, int height, bool originTopLeft) override;
    void set_viewport_f(float x, float y, float width, float height, bool originTopLeft) override;
    void set_scissor(int x, int y, int width, int height, bool originTopLeft) override;
    void draw(int base, int count, int instances) override;
    void draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) override;
    void dispatch(int x, int y, int z) override;
    void write_buffer(const BufferWrite& write) override;
    void write_image(const ImageWrite& write) override;
    void copy_buffer_to_buffer(const BufferCopy& copy) override;
    void copy_buffer_to_image(const BufferImageCopy& copy) override;
    void push_debug_group(const char* name) override;
    void pop_debug_group() override;
    void begin_timed_scope(const char* name) override;
    void end_timed_scope() override;

private:
    SokolDevice& device_;
    // The format of the render pass this list began: a debug build asserts in set_pipeline that the pipeline was made
    // for it (GL and D3D11 validation reject a mismatch; Metal accepts it and draws wrong). A pass begun outside the
    // list (gpu::begin_context_pass, the window pass the UI painter draws in) is not checked: ownPass_ is false.
    TargetFormat passFormat_{};
    bool ownPass_ = false;
};

// The Device of the sokol backends. It adopts the sokol context that is open when it is made (the renderer's: it is
// left open at destruction) or opens one from DeviceInit (and closes it at destruction). One immediate command list;
// single-threaded (the thread that made the device). Readbacks, storage_image_loadable and the OpenGL ES fix of
// make_image forward to the native_* functions of gpu/sokol_native.h (readback_*.cpp/.mm, image_gl.cpp: they reach the
// backend through this device's natives); timers to gpu_timer.cpp.
class SokolDevice final : public Device {
public:
    // The device of the open sokol context, or of a new one made with `init`. Fails (with a hint) when sg_setup fails.
    // When a context is already open, `init` is IGNORED entirely (its environment, pool sizes and uniform buffer size
    // are the open context's, set by whoever opened it: Renderer::init).
    static Result<std::unique_ptr<SokolDevice>> create(const DeviceInit& init);
    ~SokolDevice() override;
    SokolDevice(const SokolDevice&) = delete;
    SokolDevice& operator=(const SokolDevice&) = delete;

    // Whether this device opened the sokol context (and closes it at destruction).
    bool owns_context() const { return ownsContext_; }

    Backend backend() const override { return info_.backend; }
    const DeviceInfo& info() const override { return info_; }
    const Features& features() const override { return features_; }
    const Limits& limits() const override { return limits_; }
    PixelFormatCaps pixel_format_caps(PixelFormat format) const override;
    EnvironmentDefaults environment_defaults() const override;

    NativeDevice native() const override;
    NativeImage native_image(Image image) const override;
    NativeBuffer native_buffer(Buffer buffer) const override;
    MetalNative* native_metal() override;

    Buffer make_buffer(const BufferDesc& desc) override;
    Image make_image(const ImageDesc& desc) override;
    View make_view(const ViewDesc& desc) override;
    Sampler make_sampler(const SamplerDesc& desc) override;
    Shader make_shader(const ShaderDesc& desc) override;
    Pipeline make_pipeline(const PipelineDesc& desc) override;
    void destroy_buffer(Buffer buffer) override;
    void destroy_image(Image image) override;
    void destroy_view(View view) override;
    void destroy_sampler(Sampler sampler) override;
    void destroy_shader(Shader shader) override;
    void destroy_pipeline(Pipeline pipeline) override;
    ResourceState state(Buffer buffer) const override;
    ResourceState state(Image image) const override;
    ResourceState state(View view) const override;
    ResourceState state(Sampler sampler) const override;
    ResourceState state(Shader shader) const override;
    ResourceState state(Pipeline pipeline) const override;

    CommandList& begin_commands(const char* label) override;
    void submit(CommandList& list) override;
    // One queue, one immediate list (no async compute, no parallel recording, no bindless: the features stay false):
    // every queue is the graphics queue, a signal is the order the lists were submitted in, a wait changes nothing.
    CommandList& begin_commands(const char* label, QueueKind queue) override;
    using Device::submit_token;
    SyncToken submit_token(CommandList& list, std::span<const QueueHandoff> handoffs) override;
    void wait_list(CommandList& list, SyncToken token) override;
    void wait_queue(QueueKind queue, SyncToken token) override;
    void commit() override;
    std::uint64_t frame_index() const override { return frames_; }
    bool add_commit_listener(void (*func)(void* user), void* user) override;
    bool remove_commit_listener(void (*func)(void* user), void* user) override;
    void reset_state_cache() override;

    void enable_stats(bool on) override;
    bool stats_enabled() const override;
    TotalStats total_stats() const override;

    bool timer_supported(std::string* why) const override;
    void timer_begin_frame() override;
    void timer_end_frame() override;
    void timer_poll(std::vector<double>& frameMs) override;
    std::vector<ScopeTime> timer_last_scopes() const override;
    void timer_forget() override;

    Result<void> read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) override;
    Result<void> read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) override;
    Result<void> read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                    std::vector<std::uint8_t>& out) override;
    Result<void> read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                             std::vector<std::uint8_t>& out) override;
    bool storage_image_loadable(PixelFormat format, std::string* why) const override;
    bool async_read_supported() const override;
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket ticket) override;

    // The window: sokol_app's swapchain (gpu/device.h, "the window: swapchain and present"). The window system made it
    // and presents it after the frame callback: create and resize record the request, acquire hands back the frame's
    // surface as the window system gave it, present does nothing.
    Result<void> create_swapchain(const SwapchainDesc& desc) override;
    Result<void> resize_swapchain(int width, int height) override;
    Result<Swapchain> acquire_swapchain(const Swapchain& windowFrame) override;
    Result<void> present() override;
    void destroy_swapchain() override;
    bool has_swapchain() const override;
    bool swapchain_format_supported(PixelFormat format, std::string* why) const override;

private:
    friend class SokolCommandList;
    friend class SokolMetalNative;
    explicit SokolDevice(bool ownsContext);
    // FA_ASSERTs (in every build) that the caller is the thread that made the device: the sokol context is
    // single-threaded. Every entry that reaches the context calls it; the cached queries (backend, info, features,
    // limits) do not.
    void check_thread(const char* what) const;
    // Whether `ticket` names the read in flight in its slot (not a released or already read one).
    bool read_ticket_current(ReadTicket ticket) const;
    // The GPU timer, made on first use (timer_supported asks it, hence const).
    render::GpuTimer& timer() const;
    // The commit listener that counts frame_index().
    static void count_commit(void* self);

    bool ownsContext_ = false;
    bool listening_ = false;
    DeviceInfo info_{};
    Features features_{};
    Limits limits_{};
    std::thread::id thread_{};
    SokolCommandList list_{*this};
    std::unique_ptr<MetalNative> metal_;  // Metal only (made by create)
    bool listOpen_ = false;
    std::uint64_t frames_ = 0;
    mutable std::unique_ptr<render::GpuTimer> timer_;  // made on first use
    // The asynchronous reads: up to kMaxReadRings rings of AsyncBufferRead::kSlots slots, each made on first use (a ring
    // costs its staging buffers only once it is needed). A ticket's slot is ring * kSlots + slot. The renderer's depth
    // pyramid keeps up to eight cameras' reads in flight, four each.
    static constexpr int kReadSlotsPerRing = 4;  // == AsyncBufferRead::kSlots (asserted in sokol_device.cpp)
    static constexpr int kMaxReadRings = 8;
    std::array<std::unique_ptr<AsyncBufferRead>, kMaxReadRings> asyncRead_;
    // The read in flight in each slot of asyncRead_: the offset to drop from its bytes, and its ticket's generation
    // (0: none).
    struct PendingRead {
        std::size_t offset = 0;
        std::uint32_t generation = 0;
    };
    std::array<PendingRead, kMaxReadRings * kReadSlotsPerRing> reads_{};
    std::uint32_t readGeneration_ = 0;
    // The window's swapchain as create_swapchain / resize_swapchain asked for it (sokol_app owns the real one).
    bool swapchain_ = false;
    SwapchainDesc swapchainDesc_{};
};

}  // namespace fa::gpu
