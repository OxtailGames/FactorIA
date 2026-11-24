// Private to fa_render: the GPU interface on sokol_gfx (GL, GLES3, WebGL2, D3D11, Metal). The conversions between
// this interface's types and sokol's are in gpu/sg_bridge.h (transitional, M77-P2..P5).
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <thread>

#include "gpu/device.h"
#include "gpu/sg_bridge.h"
#include "gpu_types.h"
#include "sokol_gfx.h"

namespace fa::render {
class GpuTimer;
class AsyncBufferRead;
}  // namespace fa::render

namespace fa::gpu {

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
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket ticket) override;

private:
    friend class SokolCommandList;
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
    bool listOpen_ = false;
    std::uint64_t frames_ = 0;
    mutable std::unique_ptr<render::GpuTimer> timer_;  // made on first use
    // The asynchronous reads: up to kMaxReadRings rings of AsyncBufferRead::kSlots slots, each made on first use (a ring
    // costs its staging buffers only once it is needed). A ticket's slot is ring * kSlots + slot. The renderer's depth
    // pyramid keeps up to eight cameras' reads in flight, four each.
    static constexpr int kReadSlotsPerRing = 4;  // == AsyncBufferRead::kSlots (asserted in sokol_device.cpp)
    static constexpr int kMaxReadRings = 8;
    std::array<std::unique_ptr<render::AsyncBufferRead>, kMaxReadRings> asyncRead_;
    // The read in flight in each slot of asyncRead_: the offset to drop from its bytes, and its ticket's generation
    // (0: none).
    struct PendingRead {
        std::size_t offset = 0;
        std::uint32_t generation = 0;
    };
    std::array<PendingRead, kMaxReadRings * kReadSlotsPerRing> reads_{};
    std::uint32_t readGeneration_ = 0;
};

}  // namespace fa::gpu
