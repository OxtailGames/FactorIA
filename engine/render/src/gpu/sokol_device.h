// Private to fa_render: the GPU interface on sokol_gfx (GL, GLES3, WebGL2, D3D11, Metal), and the conversions between
// this interface's types and sokol's that the call sites use while they move over (M77-P2..P5; the table is in
// docs/design/ARCHITECTURE_RENDERING_GPU.md, "How to convert an sg_* call site").
//
// Every enum of gpu/types.h has sokol's values, so an enum converts with a static_cast (sokol_device.cpp asserts each
// value) and a handle by its id: gpu::Image{img.id} and sg_image{h.id} name the same image. The descs are converted
// field by field.
#pragma once

#include <memory>
#include <string>
#include <thread>

#include "gpu/device.h"
#include "gpu_types.h"
#include "sokol_gfx.h"

namespace fa::render {
class GpuTimer;
class AsyncBufferRead;
}  // namespace fa::render

namespace fa::gpu {

// ---- handles: the same id ----------------------------------------------------------------------------------------
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

// ---- enums: the same value ---------------------------------------------------------------------------------------
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

// ---- descs ---------------------------------------------------------------------------------------------------------
sg_buffer_desc to_sg(const BufferDesc& d);
sg_image_desc to_sg(const ImageDesc& d);
sg_view_desc to_sg(const ViewDesc& d);
sg_sampler_desc to_sg(const SamplerDesc& d);
sg_shader_desc to_sg(const ShaderDesc& d);
sg_pipeline_desc to_sg(const PipelineDesc& d);
sg_bindings to_sg(const Bindings& b);
sg_swapchain to_sg(const Swapchain& s);
sg_environment to_sg(const Environment& e);
// The sokol pass of a PassDesc: the same result as render::PassDesc::to_sg() for the same values.
sg_pass to_sg(const PassDesc& p);
// The generated shader headers return sokol descs: this is how they reach Device::make_shader. The strings and
// bytecode stay the header's (static data).
ShaderDesc from_sg(const sg_shader_desc& d);
// The pipeline descs the renderer builds today (Gpu::find_or_make), for a call site converted one step at a time.
PipelineDesc from_sg(const sg_pipeline_desc& d);
Swapchain from_sg(const sg_swapchain& s);
EnvironmentDefaults from_sg(const sg_environment_defaults& d);
PixelFormatCaps from_sg(const sg_pixelformat_info& i);
Features from_sg(const sg_features& f);
Limits from_sg(const sg_limits& l);
ResourceTotals from_sg(const sg_total_resource_stats& t);

// render::TargetFormat / render::PassDesc (gpu_types.h, today's sokol-typed pass) and the interface's: same fields.
TargetFormat from_render(const render::TargetFormat& f);
render::TargetFormat to_render(const TargetFormat& f);
// `swapchain` receives the converted window surface when the pass has one (the result points at it).
PassDesc from_render(const render::PassDesc& p, Swapchain& swapchain);

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
};

// The Device of the sokol backends. It adopts the sokol context that is open when it is made (the renderer's: it is
// left open at destruction) or opens one from DeviceInit (and closes it at destruction). One immediate command list;
// single-threaded (the thread that made the device). Readbacks and timers forward to readback_*.cpp/.mm and
// gpu_timer.cpp.
class SokolDevice final : public Device {
public:
    // The device of the open sokol context, or of a new one made with `init`. Fails (with a hint) when sg_setup fails.
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
    bool async_read_supported() const override;
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket ticket) override;

private:
    friend class SokolCommandList;
    explicit SokolDevice(bool ownsContext);
    // FA_ASSERTs that the caller is the thread that made the device (the sokol context is single-threaded).
    void check_thread(const char* what) const;
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
    bool listOpen_ = false;
    std::uint64_t frames_ = 0;
    mutable std::unique_ptr<render::GpuTimer> timer_;     // made on first use
    std::unique_ptr<render::AsyncBufferRead> asyncRead_;  // made on first use
};

}  // namespace fa::gpu
