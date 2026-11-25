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
// QUEUES, THREADS AND BINDLESS (M77.5). See the block "Queues, threads and bindless" of Device for the contract: the queue
// a list runs on (QueueKind), the sync tokens that order work across queues and what a resource handover between
// queues needs, which calls may run on several threads at once, and the bindless index.
//
// ERRORS. Creation never throws: a failed make_*() returns a handle whose state() is Failed (destroy it like any
// other), or the invalid handle when the desc itself is unusable. Readbacks return fa::Result with a hint.
#pragma once

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
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

    // ---- queues (M77.5; see Device, "Queues, threads and bindless") ----------------------------------------------------
    // The queue this list really runs on: the one begin_commands(label, queue) asked for, or the nearest the device has
    // when it has no such queue of its own (Transfer, then Compute, then Graphics). Valid until submit(). A list on the
    // Compute queue takes compute passes, copies, writes and markers (no render pass, no draw); one on the Transfer
    // queue takes copies, writes and markers only (no pass at all, so no draw and no dispatch). Markers are debug
    // groups and timed scopes; a timed scope on a list whose queue has no timestamps (Transfer, or a backend that says
    // so) is accepted and ignored: it records nothing and measures nothing. The default is the graphics queue (a backend
    // with one queue).
    virtual QueueKind queue() const { return QueueKind::Graphics; }

    // ---- native commands (M78: vendor SDKs; docs/design/ARCHITECTURE_RENDERING_D3D12.md and _VULKAN.md, "Native
    // access for vendor SDKs") ---------------------------------------------------------------------------------------
    // Opens a native section: records the barriers that put each resource of `uses` in its state (NativeState) and
    // hands out the backend's own command list, where the caller records with the raw API until end_native(). Outside
    // a pass, on a Graphics or Compute list (RenderTarget and the depth states on a Graphics list only), one section
    // at a time. The resources the native commands touch must all be in `uses`; the engine records nothing else on the
    // list before end_native() (begin_pass refuses: D3D12 and Vulkan fail the pass, D3D11 closes the section; both
    // report it), and the native commands may not end or reset the list.
    // D3D12 and Vulkan; D3D11 gives its immediate context (it tracks no state: `uses` is only checked); GL, Metal and
    // the RecordingDevice answer an error. An error records nothing and opens nothing; a resource or a range that does
    // not exist, a state its usage does not allow, two states for one subresource, all name the entry (uses[i]).
    virtual Result<NativeCommands> begin_native(std::span<const NativeUse> uses);
    // Closes the native section. `leftIn` names the subresources the native commands left in another state than the
    // one begin_native declared (each in a range begin_native declared); the others are as declared. The engine's
    // tracking takes these states and waits for the native commands' writes before its next use of any declared
    // resource, then binds again (pipelines, descriptor heaps and sets the native commands may have changed). An error
    // changes nothing and leaves the section open (call it again with a correct list); submitting a list whose section
    // is still open reports it and closes it as declared.
    virtual Result<void> end_native(std::span<const NativeUse> leftIn);
    // The same with every resource left as declared.
    Result<void> end_native() { return end_native(std::span<const NativeUse>{}); }
};

// What a backend knows of the resource a NativeUse names (check_native_use).
struct NativeTarget {
    bool buffer = false;
    const char* label = "";  // the resource's label, for the errors
    ImageUsage imageUsage{};
    BufferUsage bufferUsage{};
    PixelFormat format = PixelFormat::None;
    int mips = 1;
    int layers = 1;  // array layers or cube faces (1 for a 3D image)
};
// The mips and layers a NativeUse covers once its 0 counts are resolved (a buffer: 0, 1, 0, 1).
struct NativeRange {
    int mip = 0, mipCount = 1, layer = 0, layerCount = 1;
};
// The backend-neutral checks of begin_native / end_native (gpu/device.cpp): whether `use` names one resource only, its
// range lies in it, its state suits its usage and format, and the list's queue takes that state. "" when it is fine
// (`range` then holds the resolved range); the error otherwise, without a prefix.
std::string check_native_use(const NativeUse& use, const NativeTarget& target, QueueKind queue, NativeRange& range);
// Two uses of one resource whose ranges overlap with different states: the error naming both ("" when none). `ranges`
// are check_native_use's answers, one per use.
std::string check_native_overlaps(std::span<const NativeUse> uses, std::span<const NativeRange> ranges);
// Every check of a list of uses, in order: one handle each, `lookup(use, target)` finds the live resource (false: none),
// check_native_use, then check_native_overlaps (when `overlaps`). "" and one range per use, or the first error with
// its entry ("uses[2]: ..."); `name` is "uses" or "leftIn".
template <class Lookup>
std::string check_native_uses(std::span<const NativeUse> uses, QueueKind queue, const char* name, bool overlaps,
                              std::vector<NativeRange>& ranges, Lookup&& lookup) {
    ranges.assign(uses.size(), NativeRange{});
    for (std::size_t i = 0; i < uses.size(); ++i) {
        const NativeUse& use = uses[i];
        const std::string at = std::string(name) + "[" + std::to_string(i) + "]: ";
        if (bool(use.image.id) == bool(use.buffer.id))
            return at + (use.image.id ? "names an image and a buffer (hint: one resource per entry)"
                                      : "names no resource (hint: set image or buffer)");
        NativeTarget target;
        if (!lookup(use, target))
            return at + (use.image.id ? "the image" : "the buffer") +
                   " is not alive (destroyed, failed, or never made)";
        std::string error = check_native_use(use, target, queue, ranges[i]);
        if (!error.empty()) return at + error;
    }
    return overlaps ? check_native_overlaps(uses, ranges) : std::string();
}

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
    // HWND (Windows), ANativeWindow* (Android), the X11 Window (Linux), a CAMetalLayer* (macOS: Vulkan on MoltenVK)
    const void* nativeWindow = nullptr;
    const void* nativeDisplay = nullptr;  // the X11 Display* (Linux); null elsewhere
    int width = 0;                        // framebuffer pixels; 0 = the window's size
    int height = 0;
    int sampleCount = 1;  // MSAA of the swapchain's image
    // The colour format of the swapchain: Default = the device's SDR format (EnvironmentDefaults::colorFormat);
    // Rgba16F = scRGB (Windows) or EDR (Apple); Rgb10A2 = HDR10. swapchain_format_supported() says which it takes.
    // Vulkan: where the surface lacks the default's 8-bit order (Android has only RGBA) Default takes the other one
    // and EnvironmentDefaults::colorFormat follows it (an error when pipelines made with the old one exist).
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
    // The native view handle and format (M78: D3D12 and Vulkan; empty elsewhere and for a dead view).
    virtual NativeView native_view(View view) const;
    // Waits until the GPU finished everything submitted (D3D12 and Vulkan: every queue). The default does nothing: a device whose
    // driver orders the work itself (D3D11, GL, Metal) needs no wait before a vendor SDK's context is made again or destroyed.
    virtual Result<void> wait_idle();
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
    // (The same list on a chosen hardware queue: begin_commands(label, queue) in "Queues, threads and bindless".)
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

    // ---- queues, threads and bindless (M77.5: async compute, parallel recording, the bindless table) ------------------
    // Every member here is virtual with a default that is right for a device with ONE queue and no bindless table
    // (sokol, and a backend that has not built the feature yet): Compute and Transfer lists run on the graphics queue,
    // tokens complete in submission order, waits do nothing, the features below are false. Renderer code written for
    // the async path therefore runs unchanged on every backend. A derived class that overrides only one of the two
    // begin_commands() overloads hides the other when it is used through its own type: write
    // `using Device::begin_commands;` in it, or call through a Device&.
    //
    // QUEUES. begin_commands(label, queue) is begin_commands(label) on a chosen queue. With Features::asyncCompute a
    // Compute or Transfer list is recorded for a queue of its own, which the GPU runs concurrently with the graphics
    // queue; without it the list is a graphics one (list.queue() says which). Lists of ONE queue run in the order of
    // their submit() calls; lists of different queues run in no defined order except through sync tokens.
    virtual CommandList& begin_commands(const char* label, QueueKind queue);
    // submit() that also returns a token for the work: it is complete once everything submitted to the list's queue up
    // to and including this list has finished on the GPU. Plain submit() returns none (it costs no fence). The token's
    // queue is list.queue(), as read before the call. Render thread only. `handoffs` hand resources to another queue at
    // this submit (see RESOURCES BETWEEN QUEUES); the single-queue default accepts and ignores them (the order already
    // holds). submit_token(list) is submit_token(list, {}); a derived class that overrides the two-argument form writes
    // `using Device::submit_token;` to keep the short one visible through its own type.
    virtual SyncToken submit_token(CommandList& list, std::span<const QueueHandoff> handoffs);
    SyncToken submit_token(CommandList& list) { return submit_token(list, std::span<const QueueHandoff>{}); }
    // Makes the work of `list` start only after `token` is complete. Called while the list is open (the owning
    // thread's call, like a recording call); every wait of a list holds before its first command, whatever the order of
    // the calls inside the list, and they accumulate (the list waits for all of them). The invalid token, and a token
    // of the list's own queue, wait for nothing (the queue's order already covers them). The default does nothing,
    // which is only right while every queue is the graphics queue: a backend with Features::asyncCompute MUST override it.
    virtual void wait_list(CommandList& list, SyncToken token);
    // Makes everything submitted to `queue` AFTER this call start only after `token` is complete (a wait on the queue
    // itself, for work whose lists were recorded without knowing it). `queue` is mapped as in begin_commands: on a
    // device without that queue it is the graphics queue. Render thread only. The default does nothing (single queue); a
    // backend with Features::asyncCompute MUST override it.
    virtual void wait_queue(QueueKind queue, SyncToken token);
    //
    // THE CONTRACT OF A TOKEN.
    //  * A token is valid for the life of the device: it names a point of one queue's timeline and the point never
    //    moves. A token of an earlier frame, or of work the GPU finished long ago, is satisfied at once: waiting for
    //    it is allowed and does nothing. commit() and a swapchain resize do not reset the counters.
    //  * Waiting for a token that no submit_token() of this device has returned (a made-up value, another device's,
    //    one of a list not submitted yet) is a programming error: it can never be satisfied. RecordingDevice reports
    //    it. A wait is always recorded AFTER the producer's submit_token() returned.
    //  * Token values only grow per queue but are NOT contiguous: a backend may submit fix-up work of its own that takes
    //    values too. Compare tokens; never compute with them. The backends implement them with timeline semaphores
    //    (Vulkan 1.2, already required) and 64-bit fences (D3D12), so a backend without them has no asyncCompute.
    //  * Only the GPU waits: nothing here blocks the calling thread (readbacks and commit()'s frame limiter do).
    //  * commit() ends the frame for the graphics queue (what is presented, the frames in flight). Compute and
    //    transfer work of the frame that no list ever waited for is allowed (an asynchronous readback's copy, say), and
    //    the frames-in-flight limit counts the work of every queue, but the frame's picture may only depend on async
    //    work that a graphics list of the same frame waited for (the swapchain waits for the graphics queue alone).
    //
    // RESOURCES BETWEEN QUEUES. A buffer or image belongs to ONE queue at a time. A new resource belongs to Graphics.
    // The interface has no barrier call (see BARRIERS), and the backend does not guess a handover from the views the
    // lists bind: the PRODUCER declares it when it submits, with QueueHandoff, and the CONSUMER waits for the token:
    //   1. produce:  token = submit_token(producerList, {QueueHandoff{image or buffer, to}});  `to` is the queue that
    //                uses the resource next; the producer's queue must own the resource at that moment (to start using
    //                a new resource on the compute queue, a graphics list, possibly an empty one, hands it over first);
    //   2. consume:  wait_list(consumerList, token) (or wait_queue(to, token) before the consumer is submitted), so the
    //                consumer's first command that touches the resource runs after the token; the consumer's queue must
    //                be `to`; submit it after the producer (the wait names a token that exists);
    //   3. go back:  the same way in the other direction: the consumer (or a later list of `to`) hands the resource to
    //                the next queue in its own submit_token, and the next user waits for that token. Before the
    //                compute queue writes a resource again (the next frame's HiZ), it has been handed back and waited.
    // Read-only sharing of one image by two queues is not a feature: hand it over in turn, or keep one copy per queue.
    // The backend resolves a handoff on the render thread at submit: Vulkan records the queue-family release at the end
    // of the producer's list and the acquire at the head of the consumer list that waits for the token (or makes such
    // resources VK_SHARING_MODE_CONCURRENT, its choice); D3D12 transitions the resource on the producer queue to a state
    // the destination queue type accepts (COMMON, or a read state) and the consumer transitions on from there. Using a
    // resource on a queue that does not own it, or before waiting for the handoff's token, is a programming error:
    // RecordingDevice tracks the owner of every resource (checked when a list is submitted, so lists may be recorded in
    // parallel in any order) and reports both, naming the resource, the list and the fix. Without Features::asyncCompute
    // handoffs are accepted and ignored. Destroying a resource that any queue's submitted list uses is allowed, as for
    // one queue: the release is deferred until the GPU is done with it on every queue. Swapchain images belong to the
    // graphics queue and cannot be handed off. RecordingDevice also records the queue of each list, every signal, wait
    // and handoff in its stream, and checks the queue's capabilities and the tokens' validity.
    //
    // THREADS. Which calls may run at the same time on different threads:
    //  * Render thread only (the one that made the device), never while another thread is inside any call below it:
    //    make_*, destroy_*, submit, submit_token, wait_queue, commit, the commit listeners, the statistics, the timers,
    //    the readbacks and asynchronous reads, the natives, reset_state_cache.
    //  * Any thread, when Features::multiThreadRecording: begin_commands (both overloads), every CommandList call on the
    //    list the thread holds (including wait_list), so different lists record in parallel; and the read-only queries
    //    backend, info, features, limits, pixel_format_caps, environment_defaults, state, frame_index, bindless_index
    //    and async_read_supported. The queries are safe because the renderer never creates or destroys a resource, submits
    //    or commits while a recording job runs (it joins the jobs first); the backend makes them lock-free or
    //    thread-safe on that condition.
    //  * One list is used by one thread at a time (a hand-over to another thread needs a happens-before edge, a job
    //    join). A list begun on one thread may be submitted by the render thread once its recorder is done with it.
    //    submit() order is execution order per queue, so a renderer that wants a deterministic frame submits the lists
    //    in a fixed order after the join, whatever order the jobs finished in.
    //  * Without multiThreadRecording (sokol: one immediate list) only the render thread calls begin_commands and the
    //    list; a second begin_commands() before submit() or a call from another thread is an FA_ASSERT.
    //
    // BINDLESS. The index of the view's texture (or buffer) in the global descriptor table every shader of the device
    // can index (D3D12: the unbounded SRV range at t0 space1; Vulkan: the update-after-bind set), assigned when the view
    // is made and valid until it is destroyed. kNoBindlessIndex when the backend has no table (Features::bindless is
    // false), the table is full, or `view` is not a live sampled view. Never changes for a live view.
    virtual std::uint32_t bindless_index(View view) const;

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
    // The scopes of the newest frame timer_poll() resolved. Within one queue in the order they started on the GPU; a
    // device whose compute lists run on a queue of their own (D3D12) lists the graphics queue's scopes first, then the
    // compute queue's, since each queue counts in its own clock and two queues' times are never compared (and leaves
    // out the scopes of copy lists, which D3D12 does not time).
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
    // the frame). D3D12 makes its own DXGI flip-model swapchain on SwapchainDesc::nativeWindow (an HWND): acquire waits
    // for the frame-latency object and hands back the next back buffer, present presents it on the graphics queue,
    // resize waits for the GPU and resizes the buffers (docs/design/ARCHITECTURE_RENDERING_D3D12.md, "Swapchain").
    // Vulkan makes its own VkSwapchainKHR on the surface of SwapchainDesc::nativeWindow (an HWND, an X11 Window, an
    // ANativeWindow* or a CAMetalLayer*; docs/design/ARCHITECTURE_RENDERING_VULKAN.md, "Swapchain"). The runtime claims
    // the native window from the platform first (Renderer::init gets it through RendererDesc::nativeWindow). The defaults
    // below are the answer of a backend without a window path (RecordingDevice, and a Vulkan device whose loader or
    // driver lacks the surface and swapchain extensions): every call fails with a teaching error and nothing changes.
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

protected:
    // The next token of `queue` (its fence value, from 1): the default submit_token() hands one out after submit(), so
    // tokens complete in submission order. Thread-safe.
    SyncToken issue_token(QueueKind queue);

private:
    std::atomic<std::uint64_t> issued_[kQueueKinds]{};
};

// Makes the device of `backend`:
//  * Gl, Gles3, WebGl2, D3d11, Metal: a SokolDevice, when it is the sokol backend this binary was built with (it adopts
//    the sokol context the renderer opened, or opens one with `init` when none is open).
//  * Recording: a RecordingDevice (no GPU).
//  * D3d12: make_d3d12_device (gpu/d3d12_device.h) with `init` and the engine's pipeline cache file
//    (d3d12_pipeline_cache_file()); an error off Windows.
//  * Vulkan: make_vulkan_device (gpu/vulkan_device.h) with `init` and the engine's pipeline cache file
//    (vulkan_pipeline_cache_file()), in a build whose renderer has Vulkan (FA_RENDER_VULKAN: the SPIR-V of the built-in
//    shaders); an error elsewhere.
// D3D12 and Vulkan present into a native window (create_swapchain with SwapchainDesc::nativeWindow: an HWND, an X11
// Window, an ANativeWindow or a CAMetalLayer).
Result<std::unique_ptr<Device>> make_device(Backend backend, const DeviceInit& init = {});

// Whether make_device(backend) can succeed in this binary: the built sokol backend, Recording, D3d12 on Windows, Vulkan
// where FA_RENDER_VULKAN is on. True does not promise a GPU (a machine without a Vulkan driver still fails).
bool device_backend_compiled(Backend backend);

// The sokol backend this binary was built with (Gl, Gles3, WebGl2, D3d11 or Metal).
Backend built_sokol_backend();

}  // namespace fa::gpu
