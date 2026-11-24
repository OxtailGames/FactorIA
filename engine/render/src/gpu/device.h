// Private to fa_render: the engine's GPU interface (M77, docs/design/ARCHITECTURE_RENDERING_GPU.md).
//
// Two objects:
//  * Device: owns the resources (buffers, images, views, samplers, shaders, pipelines), answers what the GPU can do
//    (features, limits, pixel formats), hands out the native objects, runs the frame (command lists, commit), the GPU
//    timers and the readbacks.
//  * CommandList: records passes, pipeline and binding changes, uniforms, draws, dispatches, uploads and copies.
//
// Implementations: SokolDevice (gpu/sokol_device.h: GL, GLES3, WebGL2, D3D11, Metal through sokol_gfx),
// RecordingDevice (gpu/recording_device.h: no GPU; validates and records, for tests and the CPU logic of the later
// backends) and the engine's own D3D12 and Vulkan backends (gpu/d3d12_device.h, gpu/vulkan_device.h). make_device()
// picks one; the renderer draws through the one RendererDesc::backend names.
//
// THREADING. A Device is created, used for resources and destroyed on one thread, the render thread. A CommandList
// belongs to the thread that called begin_commands() until it is submitted: a backend that records in parallel
// (D3D12, Vulkan, M77.5) lets several threads each hold one list of the same frame; the sokol backends have a single
// immediate list, so a second begin_commands() before submit() and a call from another thread are programming errors
// (FA_ASSERT). Resource creation and destruction stay on the render thread on every backend. What SokolDevice checks:
// every entry that touches the sokol context (make_*, destroy_*, state, pixel_format_caps, environment_defaults, the
// natives, begin_commands, submit, commit, the commit listeners, the statistics, the readbacks and timers, and every
// CommandList call) asserts the calling thread, in every build (one thread-id compare); the queries that answer from
// values cached at creation (backend, info, features, limits, async_read_supported) do not.
//
// LIFETIME. A resource lives from make_*() to destroy_*(). Destroying one that a submitted command list still uses
// is allowed: a backend with frames in flight defers the release until the GPU is done with it (sokol does). A handle
// that was destroyed never names another resource (its generation changes), so a stale handle is Invalid, never a
// different object. A CommandList is valid from begin_commands() to submit(): a `CommandList&` kept past submit() is
// dangling (D3D12/Vulkan recycle the object for a later begin_commands()), so code that holds the frame's list (the
// renderer's Gpu::commands()) takes it again after each commit.
//
// UPLOADS INSIDE A PASS. write_buffer / write_image may run inside a pass here because sokol copies at once (GL, D3D11)
// or into a per-frame transient slot (Metal). The explicit backends (D3D12, Vulkan) cannot copy into a resource a
// pass is using: they will stage such a write in a host-visible ring buffer of the frame and copy it before the pass
// (or read the ring directly), so a write inside a pass costs them a ring allocation; keep uploads before the pass
// where the code allows it.
//
// BARRIERS. None in this interface. A backend that needs them (D3D12, Vulkan) derives them from the pass boundaries
// (attachments become shader-readable after the pass that wrote them) and from the views a draw or dispatch binds
// (a Texture view reads, a StorageImage/StorageBuffer view of a written binding writes), and inserts them itself.
//
// ERRORS. Creation never throws: a failed make_*() returns a handle whose state() is Failed (destroy it like any
// other), or the invalid handle when the desc itself is unusable. Readbacks return fa::Result with a hint.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "gpu/types.h"

namespace fa::gpu {

// A recording of GPU commands for one frame (see the header comment for the threading and lifetime rules).
//
// Inside a render pass: set_pipeline, set_bindings, set_uniforms, set_viewport, set_scissor, draw. Inside a compute
// pass: set_pipeline (a compute pipeline), set_bindings (views and samplers only), set_uniforms, dispatch. Outside a
// pass: the copies. write_buffer / write_image, debug groups and timed scopes go anywhere.
class CommandList {
public:
    virtual ~CommandList() = default;

    // Begins a render pass (PassDesc: its attachments or the swapchain, and what it does with their contents). Passes
    // do not nest.
    virtual void begin_pass(const PassDesc& pass) = 0;
    // Begins a compute pass (dispatches only, no attachments).
    virtual void begin_compute_pass(const char* label) = 0;
    // Ends the render or compute pass begun last.
    virtual void end_pass() = 0;
    // What the list is inside now.
    virtual PassState pass_state() const = 0;

    // The pipeline of the next draws or dispatches. A render pipeline's colour/depth formats and sample count must equal
    // the pass's (PassDesc::format); a compute pipeline goes in a compute pass.
    virtual void set_pipeline(Pipeline pipeline) = 0;
    // The buffers, views and samplers of the next draws, after set_pipeline: every slot the pipeline's shader declares.
    virtual void set_bindings(const Bindings& bindings) = 0;
    // The uniform block `slot` of the current pipeline's shader (whatever its stage), exactly its declared size.
    virtual void set_uniforms(int slot, Range data) = 0;
    // The viewport in pixels (originTopLeft: y counts from the top, the engine's convention).
    virtual void set_viewport(int x, int y, int width, int height, bool originTopLeft = true) = 0;
    // The same with fractional pixels (a dynamic-resolution viewport).
    virtual void set_viewport_f(float x, float y, float width, float height, bool originTopLeft = true) = 0;
    // The scissor rectangle in pixels; the whole attachment until set.
    virtual void set_scissor(int x, int y, int width, int height, bool originTopLeft = true) = 0;
    // Draws `count` vertices (or indices, with an index buffer) from `base`, `instances` times.
    virtual void draw(int base, int count, int instances = 1) = 0;
    // The same with a vertex offset added to every index and a first instance (Features::drawBaseVertex /
    // drawBaseInstance; 0 and 0 work everywhere).
    virtual void draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) = 0;
    // Runs the compute pipeline on x * y * z thread groups.
    virtual void dispatch(int x, int y, int z) = 0;

    // Uploads into a writeTransient buffer / image, seen by the commands recorded after it. Inside or outside a pass.
    virtual void write_buffer(const BufferWrite& write) = 0;
    virtual void write_image(const ImageWrite& write) = 0;
    // GPU-side copies, outside a pass (copySrc / copyDst usages).
    virtual void copy_buffer_to_buffer(const BufferCopy& copy) = 0;
    virtual void copy_buffer_to_image(const BufferImageCopy& copy) = 0;

    // A named group in GPU captures (RenderDoc, Xcode, PIX); groups nest and are closed in order.
    virtual void push_debug_group(const char* name) = 0;
    virtual void pop_debug_group() = 0;
    // A timed scope: timestamps before and after the GPU work recorded between the two, read back a few frames later
    // through Device::timer_poll / timer_last_scopes. Scopes do not nest (a begin closes the scope still open); they
    // do nothing outside a timed frame (Device::timer_begin_frame) or on a device that cannot time.
    virtual void begin_timed_scope(const char* name) = 0;
    virtual void end_timed_scope() = 0;
};

// The command buffer of a Metal device, for code that orders its own Metal work against the frame (MetalFX,
// metalfx_apple.mm). Only the Metal backend has one (Device::native_metal() is null elsewhere): the objects are
// void* so that no Objective-C type reaches a header (`id<MTLCommandBuffer>`).
class MetalNative {
public:
    virtual ~MetalNative() = default;
    // The MTLCommandBuffer the passes recorded from now on go into: the one the open frame has, made when it has
    // none yet. Encoding events or waits on it is allowed (outside a pass); committing it is not: split_commit() does.
    // Null when the device lost its queue.
    virtual const void* current_command_buffer() = 0;
    // Submits everything recorded so far to the GPU as one command buffer and goes on with the frame: the next pass
    // goes into a new buffer, queued behind it. It is a commit() that does not end the frame (the commit listeners
    // run, as in sokol's frame split; the command list stays open). Outside a pass.
    virtual void split_commit() = 0;
};

// The per-backend settings of make_device().
struct DeviceInit {
    // The window's environment: the default formats and the native device. Read by a SokolDevice that opens its own
    // sokol context, and by RecordingDevice for what Default formats mean.
    Environment environment{};
    // The pool sizes of a context the device opens (the renderer's values; sokol_setup_desc in gpu/sokol_device.cpp).
    int bufferPoolSize = 2048;
    int imagePoolSize = 1024;
    int viewPoolSize = 4096;
    int samplerPoolSize = 64;
    int shaderPoolSize = 384;
    int pipelinePoolSize = 256;
    int uniformBufferSize = 16 * 1024 * 1024;  // bytes of uniform data per frame
    // RecordingDevice: what it reports. recordingDefaultCaps true = a desktop GPU with compute (recordingFeatures and
    // recordingLimits are ignored); false = exactly recordingFeatures and recordingLimits (a test describes a
    // GLES3-like device, say; a limit left 0 is not checked).
    Features recordingFeatures{};
    Limits recordingLimits{};
    bool recordingDefaultCaps = true;
};

// ---- the window: swapchain and present (Device::create_swapchain and the calls after it) --------------------------
// The window a device presents into, as the platform layer hands it over. On the sokol backends sokol_app made the
// swapchain already (the native fields stay null and are not read); an explicit backend (D3D12, Vulkan) makes its own
// swapchain on the native window.
struct SwapchainDesc {
    const void* nativeWindow = nullptr;   // HWND (Windows), ANativeWindow* (Android), the X11 Window (Linux)
    const void* nativeDisplay = nullptr;  // the X11 Display* (Linux); null elsewhere
    int width = 0;                        // framebuffer pixels; 0 = the window's size
    int height = 0;
    int sampleCount = 1;  // MSAA of the swapchain's image
    // The colour format of the swapchain: Default = the device's SDR format (EnvironmentDefaults::colorFormat);
    // Rgba16F = scRGB (Windows) or EDR (Apple); Rgb10A2 = HDR10. swapchain_format_supported() says which it takes.
    PixelFormat colorFormat = PixelFormat::Default;
    bool vsync = true;
    const char* label = nullptr;
};

// The GPU device (see the header comment for threading, lifetime, barriers and errors).
class Device {
public:
    virtual ~Device() = default;

    // ---- who it is, what it can do --------------------------------------------------------------------------------
    virtual Backend backend() const = 0;
    virtual const DeviceInfo& info() const = 0;
    virtual const Features& features() const = 0;
    virtual const Limits& limits() const = 0;
    // What the device does with one pixel format (the sg_query_pixelformat question).
    virtual PixelFormatCaps pixel_format_caps(PixelFormat format) const = 0;
    // The default formats of the context (what Default means in a swapchain pass and a pipeline).
    virtual EnvironmentDefaults environment_defaults() const = 0;

    // ---- native objects (readbacks, timers, MetalFX, Dear ImGui) ---------------------------------------------------
    virtual NativeDevice native() const = 0;
    virtual NativeImage native_image(Image image) const = 0;
    virtual NativeBuffer native_buffer(Buffer buffer) const = 0;
    // The Metal command-buffer access (MetalFX); null on every backend that is not Metal. The MTLTexture of an image is
    // native_image(image).texture.
    virtual MetalNative* native_metal() = 0;

    // ---- resources -------------------------------------------------------------------------------------------------
    virtual Buffer make_buffer(const BufferDesc& desc) = 0;
    virtual Image make_image(const ImageDesc& desc) = 0;
    virtual View make_view(const ViewDesc& desc) = 0;
    virtual Sampler make_sampler(const SamplerDesc& desc) = 0;
    virtual Shader make_shader(const ShaderDesc& desc) = 0;
    virtual Pipeline make_pipeline(const PipelineDesc& desc) = 0;
    // Destroying the invalid handle does nothing; destroying a destroyed one is an error (RecordingDevice reports it).
    virtual void destroy_buffer(Buffer buffer) = 0;
    virtual void destroy_image(Image image) = 0;
    virtual void destroy_view(View view) = 0;
    virtual void destroy_sampler(Sampler sampler) = 0;
    virtual void destroy_shader(Shader shader) = 0;
    virtual void destroy_pipeline(Pipeline pipeline) = 0;
    // Where a resource is in its life (Invalid for a destroyed or unknown handle).
    virtual ResourceState state(Buffer buffer) const = 0;
    virtual ResourceState state(Image image) const = 0;
    virtual ResourceState state(View view) const = 0;
    virtual ResourceState state(Sampler sampler) const = 0;
    virtual ResourceState state(Shader shader) const = 0;
    virtual ResourceState state(Pipeline pipeline) const = 0;

    // ---- the frame -------------------------------------------------------------------------------------------------
    // A command list for this frame, owned by the device and valid until submit(). The sokol backends return their one
    // immediate list (its commands run as they are recorded); D3D12/Vulkan return a new one per call.
    virtual CommandList& begin_commands(const char* label) = 0;
    // Hands the list back: its commands run after those of the lists submitted before it.
    virtual void submit(CommandList& list) = 0;
    // Ends the frame: every list must have been submitted. The GPU may still be working on it (kInflightFrames).
    virtual void commit() = 0;
    // Frames committed since the device started.
    virtual std::uint64_t frame_index() const = 0;
    // A function called inside every commit() (sg_add_commit_listener): the renderer counts frames with it. False when
    // it cannot be added (the listener table is full, or it is there already).
    virtual bool add_commit_listener(void (*func)(void* user), void* user) = 0;
    virtual bool remove_commit_listener(void (*func)(void* user), void* user) = 0;
    // GL: forget the cached API state after code that called GL directly (Dear ImGui, interop). No-op elsewhere.
    virtual void reset_state_cache() = 0;

    // ---- statistics ------------------------------------------------------------------------------------------------
    virtual void enable_stats(bool on) = 0;
    virtual bool stats_enabled() const = 0;
    // The resource totals since the start (sg_query_stats().total), while stats are enabled.
    virtual TotalStats total_stats() const = 0;

    // ---- GPU timers ------------------------------------------------------------------------------------------------
    // Whether this device measures GPU time; `why` (when not) says why, for the profiler.
    virtual bool timer_supported(std::string* why) const = 0;
    // Brackets one timed frame (before its first pass, after its last); CommandList::begin_timed_scope inside.
    virtual void timer_begin_frame() = 0;
    virtual void timer_end_frame() = 0;
    // Appends the GPU milliseconds of every timed frame whose result has arrived (never waits).
    virtual void timer_poll(std::vector<double>& frameMs) = 0;
    // One timed scope of the newest resolved frame.
    struct ScopeTime {
        std::string name;
        double ms = 0.0;
    };
    // The scopes of the newest frame timer_poll() resolved, in the order they ran.
    virtual std::vector<ScopeTime> timer_last_scopes() const = 0;
    // Drops the results so far and those still in flight (the profiler was switched off).
    virtual void timer_forget() = 0;

    // ---- readbacks -------------------------------------------------------------------------------------------------
    // The work recorded so far must have been committed: these wait for the GPU.
    // An RGBA8 image, top row first.
    virtual Result<void> read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) = 0;
    // An RGBA16F image as floats (4 per pixel, top row first).
    virtual Result<void> read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) = 0;
    // A rectangle of a storage image, tightly packed in its own format (`format`: RGBA8, RGBA16F, R32F, RGBA32F).
    virtual Result<void> read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                            std::vector<std::uint8_t>& out) = 0;
    // `bytes` bytes of a storage buffer from `offset`.
    virtual Result<void> read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                                     std::vector<std::uint8_t>& out) = 0;
    // Whether a compute shader can imageLoad (not only imageStore) a storage image of `format` (RGBA8, RGBA16F, R32F,
    // RGBA32F) on this GPU: the question behind a material's `"access": "readWrite"`. pixel_format_caps().read does not
    // answer it (on D3D11.0 hardware a typed UAV exists for formats it cannot load; on Metal the read-write texture tier
    // decides). False + `why` (a sentence about this GPU, for the material's error) when it cannot. Every backend answers
    // it (the sokol ones, D3D12 from the typed UAV load support of the format, Vulkan from the storage-image feature of
    // the format). The default answers false with a teaching `why`, for a backend that has not built the question:
    // it refuses rather than promising a load the GPU may not do.
    virtual bool storage_image_loadable(PixelFormat format, std::string* why) const;
    // Asynchronous readback of `bytes` bytes of a storage buffer from `offset`, frames in flight: request() queues a
    // copy behind the committed work and returns a ticket (an invalid ticket with ok = every slot is busy, ask again
    // next frame); poll() hands the bytes over once the GPU is done (wait = block until then, bounded); release()
    // frees a ticket without reading it. A ticket names one request: once it was polled to the end or released, it is
    // stale (its generation no longer matches the slot's) and poll() / release() ignore it, even after the slot was
    // reused. The sokol backends copy the first offset + bytes bytes and drop the first `offset`. Only buffers are read
    // in the background: an image is read with the blocking read_image_* / read_storage_image. Render thread only.
    virtual bool async_read_supported() const = 0;
    virtual Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) = 0;
    virtual bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) = 0;
    virtual void release_buffer_read(ReadTicket ticket) = 0;

    // ---- the window: swapchain and present -------------------------------------------------------------------------
    // The frame of a renderer that draws into a window (RendererDesc::headless false), on the render thread:
    //   create_swapchain(desc)               once, before the first frame (Renderer::init)
    //   acquire_swapchain(windowFrame)       each frame: the image to draw into, for a PassDesc::for_swapchain pass
    //   ... the passes; submit(); commit()
    //   present()                            shows the image acquired this frame
    //   resize_swapchain(w, h)               when the window's framebuffer changed size (before the next acquire)
    //   destroy_swapchain()                  before the device goes (nothing when there is none)
    // The sokol devices present into sokol_app's swapchain: the window system made it, resizes it and presents it after
    // the frame callback, so create and resize only record the request, acquire hands back `windowFrame` (the frame's
    // surface as the window system gave it, gpu::swapchain_of(GfxSwapchain)) and present does nothing (commit() ended
    // the frame). The defaults below are the answer of a backend without a window path (D3D12 and Vulkan for now, and
    // RecordingDevice): every call fails with a teaching error and nothing changes.
    virtual Result<void> create_swapchain(const SwapchainDesc& desc);
    virtual Result<void> resize_swapchain(int width, int height);
    // `windowFrame` is read by the sokol devices only (an explicit backend acquires the next image of its own
    // swapchain). The result is valid until present().
    virtual Result<Swapchain> acquire_swapchain(const Swapchain& windowFrame);
    virtual Result<void> present();
    virtual void destroy_swapchain();
    virtual bool has_swapchain() const;
    // Whether the window's swapchain can take `format` as its colour format (the HDR question: Rgba16F for scRGB or
    // EDR, Rgb10A2 for HDR10; Default and the environment's colour format are the SDR one). False + `why` (one sentence
    // naming the backend) when it cannot. It answers for the backend, before any swapchain exists; whether the display
    // shows HDR is the platform's question (fa/platform/hdr_output.h).
    virtual bool swapchain_format_supported(PixelFormat format, std::string* why) const;
};

// Makes the device of `backend`:
//  * Gl, Gles3, WebGl2, D3d11, Metal: a SokolDevice, when it is the sokol backend this binary was built with (it adopts
//    the sokol context the renderer opened, or opens one with `init` when none is open).
//  * Recording: a RecordingDevice (no GPU).
//  * D3d12: make_d3d12_device (gpu/d3d12_device.h) with `init` and the engine's pipeline cache file
//    (d3d12_pipeline_cache_file()); an error off Windows.
//  * Vulkan: make_vulkan_device (gpu/vulkan_device.h) with `init` and the other options at their defaults, in a build
//    whose renderer has Vulkan (FA_RENDER_VULKAN: the SPIR-V of the built-in shaders); an error elsewhere.
// D3D12 and Vulkan draw offscreen only for now (no window path: create_swapchain fails).
Result<std::unique_ptr<Device>> make_device(Backend backend, const DeviceInit& init = {});

// Whether make_device(backend) can succeed in this binary: the built sokol backend, Recording, D3d12 on Windows, Vulkan
// where FA_RENDER_VULKAN is on. True does not promise a GPU (a machine without a Vulkan driver still fails).
bool device_backend_compiled(Backend backend);

// The sokol backend this binary was built with (Gl, Gles3, WebGl2, D3d11 or Metal).
Backend built_sokol_backend();

}  // namespace fa::gpu
