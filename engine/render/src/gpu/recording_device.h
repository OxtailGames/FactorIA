// Private to fa_render: RecordingDevice, the GPU interface without a GPU. It checks every call the way a strict backend
// would (sokol's validation layer plus what D3D12 and Vulkan need: formats of a pipeline against its pass, bindings
// against the shader's reflection, resources used after destruction) and records the command stream, so tests can
// assert on what a frame does and the later backends' CPU logic can run without a device.
//
// It never stops on a misuse: the call is recorded as far as it can be, and a teaching message (what was wrong, at
// which call of which list, how to fix it) goes to errors(). Several command lists can be open at once, each on its
// own thread (the D3D12/Vulkan model); each list's stream joins the device stream at submit(), in submit order.
#pragma once

#include <atomic>
#include <cstdint>
#include <initializer_list>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "gpu/device.h"

namespace fa::gpu {

// What a recorded command did.
enum class CommandKind : std::uint8_t {
    BeginPass,
    BeginComputePass,
    EndPass,
    SetPipeline,
    SetBindings,
    SetUniforms,
    SetViewport,
    SetScissor,
    Draw,
    Dispatch,
    WriteBuffer,
    WriteImage,
    CopyBufferToBuffer,
    CopyBufferToImage,
    PushDebugGroup,
    PopDebugGroup,
    BeginTimedScope,
    EndTimedScope,
    Commit,
    // Device-level reads (no list: recorded when the device is asked, between the frames' commands).
    ReadImage,   // read_image_rgba8 / read_image_rgba16f / read_storage_image: id the image, args x, y, width, height
    ReadBuffer,  // read_buffer: id the buffer, args offset, bytes (each clamped to INT_MAX)
    // Queues (Device::submit_token / wait_list / wait_queue); args: the token's queue, the token's value (clamped to
    // INT_MAX). `queue` of the command is the queue it runs on (a WaitQueue: the queue that waits).
    Signal,    // the end of a list submitted with submit_token(): the token it returned
    WaitList,  // a wait_list() of the list, emitted before the list's first command at submit()
    Handoff,  // a QueueHandoff of submit_token(): id the resource, args from queue, to queue, token value; before Signal
    WaitQueue,  // a wait_queue() (device level, between the commands of the frames, like the reads)
    // Ray tracing (M79); `id` is the acceleration structure written (the handle's id).
    BuildBlas,  // build_blas: args geometries, triangles, scratch bytes needed (each clamped to INT_MAX), update
    BuildTlas,  // build_tlas: args instances, scratch bytes needed, update
    QueryCompactedSize,  // query_compacted_size: id the BLAS, args destination offset
    CopyAccelStructure,  // copy_accel_structure: id the destination, args mode (0 clone, 1 compact)
};

// The snake_case name of a command kind ("begin_pass"), as stream_text() prints it.
const char* command_kind_name(CommandKind kind);

// One command of the device stream.
struct RecordedCommand {
    CommandKind kind = CommandKind::Commit;
    std::uint64_t frame = 0;  // Device::frame_index() when it was submitted (a Commit: the frame it ended)
    std::string list;         // the label of the command list ("" for a Commit, a WaitQueue and the device-level reads)
    QueueKind queue = QueueKind::Graphics;  // the queue of the list that recorded it (Features::asyncCompute)
    std::uint32_t id = 0;  // the handle it names: the pipeline, the written or copied-to resource; 0 otherwise
    // Its numbers: draw (base, count, instances, baseVertex, baseInstance), dispatch (x, y, z), viewport and scissor
    // (x, y, width, height; fractional viewports rounded), uniforms (slot, bytes), writes and copies (bytes),
    // bindings (vertex buffers, views, samplers bound). 0 where unused.
    int args[5]{};
    std::string text;  // the whole command as one line, without the frame and list ("draw 0 36 1")
};

class RecordingDevice;

// A command list of a RecordingDevice: checks and records each call; nothing runs.
class RecordingCommandList : public CommandList {
public:
    explicit RecordingCommandList(RecordingDevice& device) : device_(device) {}
    void begin_pass(const PassDesc& pass) override;
    void begin_compute_pass(const char* label) override;
    void end_pass() override;
    PassState pass_state() const override { return passState_; }
    QueueKind queue() const override { return queue_; }
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
    // Ray tracing (M79): checked like a strict D3D12 or Vulkan backend would (docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md,
    // "RecordingDevice, with ray tracing"). A refused call records nothing and returns the error, which is also added to errors();
    // without Features::accelerationStructure it returns the refusal alone (a probing caller is not a misuse).
    Result<void> build_blas(const BlasBuild& build) override;
    Result<void> build_tlas(const TlasBuild& build) override;
    Result<void> query_compacted_size(AccelStructure blas, Buffer dst, std::size_t dstOffset) override;
    Result<void> copy_accel_structure(AccelStructure src, AccelStructure dst, AccelCopyMode mode) override;
    Backend backend() const override { return Backend::Recording; }

private:
    friend class RecordingDevice;
    // Reports a ray tracing misuse at the current command and returns it as the call's error (mutex_ held).
    Error reject(const char* command, const std::string& what, const std::string& fix);
    // The pipeline facts a draw or dispatch checks against (copied at set_pipeline, so a later destroy does not
    // change what the list checks).
    struct BoundPipeline {
        std::uint32_t id = 0;
        std::string label;
        bool compute = false;
        std::uint32_t requiredUniforms = 0;  // bit per declared uniform block
        bool needsBindings = false;          // the pipeline reads a vertex/index buffer, a view or a sampler
    };

    void reset(const char* label, QueueKind onQueue);
    // Notes that the list uses a resource (checked against its owner queue at submit()); mutex_ held.
    void use_buffer(Buffer buffer);
    void use_image(Image image);
    void use_view(View view);
    // Appends a command to this list's stream.
    void record(CommandKind kind, std::uint32_t id, std::initializer_list<int> args, std::string text);
    // Reports a misuse at the current command, naming the list, the command's index and the open pass.
    void fail(const char* command, const std::string& what, const std::string& fix);
    // Fails (and returns false) when the list is not inside `want` (None = outside any pass).
    bool require_pass(const char* command, PassState want);
    bool require_pipeline(const char* command);
    void check_ready_to_run(const char* command);

    RecordingDevice& device_;
    std::string label_;
    bool open_ = false;
    QueueKind queue_ = QueueKind::Graphics;
    std::vector<RecordedCommand> commands_;
    std::vector<SyncToken> waitTokens_;  // the tokens wait_list() named (the handoff check reads them)
    struct Use {
        bool image = false;
        std::uint32_t id = 0;
    };
    std::vector<Use> uses_;               // the resources the list's commands touch, once each
    std::vector<RecordedCommand> waits_;  // the wait_list() calls, joined ahead of commands_ at submit()
    PassState passState_ = PassState::None;
    std::string passLabel_;
    TargetFormat passFormat_{};
    BoundPipeline pipeline_{};
    bool bindingsApplied_ = false;
    std::uint32_t uniformsApplied_ = 0;
    int debugDepth_ = 0;
    bool timedScopeOpen_ = false;
};

// The Device without a GPU (see the header comment).
class RecordingDevice : public Device {
public:
    // `init`: the environment's default formats, the pool sizes, and the features and limits to report.
    explicit RecordingDevice(const DeviceInit& init = {});
    ~RecordingDevice() override;
    RecordingDevice(const RecordingDevice&) = delete;
    RecordingDevice& operator=(const RecordingDevice&) = delete;

    // ---- what tests read --------------------------------------------------------------------------------------------
    // The misuses reported so far, oldest first (each one message that says what, where and how to fix it).
    std::vector<std::string> errors() const;
    // The same, emptying the list.
    std::vector<std::string> take_errors();
    // The device stream: the commands of every submitted list, in submit order, and a Commit per commit().
    std::vector<RecordedCommand> commands() const;
    // The device stream as text, one line per command: "frame 0 [main] draw 0 36 1".
    std::string stream_text() const;
    // Forgets the recorded stream (not the resources, not the errors).
    void clear_commands();

    // ---- Device ----------------------------------------------------------------------------------------------------
    Backend backend() const override { return Backend::Recording; }
    const DeviceInfo& info() const override { return info_; }
    const Features& features() const override { return features_; }
    const Limits& limits() const override { return limits_; }
    PixelFormatCaps pixel_format_caps(PixelFormat format) const override;
    EnvironmentDefaults environment_defaults() const override { return defaults_; }

    NativeDevice native() const override { return {}; }
    NativeImage native_image(Image) const override { return {}; }
    NativeBuffer native_buffer(Buffer) const override { return {}; }
    MetalNative* native_metal() override { return nullptr; }

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

    // Ray tracing (M79; Features::accelerationStructure through DeviceInit::recordingRayTracing). The sizes are this
    // device's own deterministic numbers (a function of the triangle or instance counts, rounded up to 256), not a
    // real GPU's: tests compare them to what make_buffer and the builds are given. Every check names the call, the
    // field and what to change, and goes to errors() as well as the returned Error.
    Result<AccelSizes> blas_sizes(std::span<const AccelTriangles> geometries, const AccelBuildFlags& flags) override;
    Result<AccelSizes> tlas_sizes(std::uint32_t instanceCount, const AccelBuildFlags& flags) override;
    Result<AccelStructure> make_accel_structure(const AccelStructureDesc& desc) override;
    void destroy_accel_structure(AccelStructure structure) override;
    ResourceState accel_structure_state(AccelStructure structure) const override;

    CommandList& begin_commands(const char* label) override;
    void submit(CommandList& list) override;
    // Queues: with Features::asyncCompute (default caps) a Compute or Transfer list keeps its queue, which it checks
    // (no render pass on either, no compute pass on a Transfer list); without it every list is a graphics one. Tokens
    // count per queue from 1; submit_token() / wait_list() / wait_queue() are recorded in the stream (Signal, WaitList,
    // WaitQueue), and a wait for a token no submit_token() returned is reported. Ownership between queues (with asyncCompute only):
    // every resource has an owner queue (Graphics when made); a QueueHandoff of submit_token() moves it (a Handoff
    // command); at submit() each list's resources must be owned by its queue and, after a handoff, the list (or
    // wait_queue()) must have waited for the handoff's token; both are reported with the resource's name. A timed
    // scope on a Transfer list is recorded as ignored.
    CommandList& begin_commands(const char* label, QueueKind queue) override;
    using Device::submit_token;
    SyncToken submit_token(CommandList& list, std::span<const QueueHandoff> handoffs) override;
    void wait_list(CommandList& list, SyncToken token) override;
    void wait_queue(QueueKind queue, SyncToken token) override;
    // Features::bindless (recordingFeatures): a live Texture or storage view has index = its pool slot - 1, stable for
    // its life; kNoBindlessIndex otherwise.
    std::uint32_t bindless_index(View view) const override;
    void commit() override;
    std::uint64_t frame_index() const override;
    bool add_commit_listener(void (*func)(void* user), void* user) override;
    bool remove_commit_listener(void (*func)(void* user), void* user) override;
    void reset_state_cache() override {}

    void enable_stats(bool on) override;
    bool stats_enabled() const override;
    TotalStats total_stats() const override;

    // No GPU, so no GPU time: timer_supported() is false with a reason; the timed scopes are still recorded.
    bool timer_supported(std::string* why) const override;
    void timer_begin_frame() override {}
    void timer_end_frame() override {}
    void timer_poll(std::vector<double>&) override {}
    std::vector<ScopeTime> timer_last_scopes() const override { return {}; }
    void timer_forget() override {}

    // No GPU memory, so a deterministic answer: a read that a real device would accept returns zeros of the size it
    // asked for and is recorded in the stream (ReadImage, ReadBuffer); one it would refuse (a dead handle, a format the
    // read does not take, a rectangle or range outside the resource) fails with the teaching error. Work submitted but
    // not committed yet (the read would see stale contents on a GPU) goes to errors(); the read still answers.
    Result<void> read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) override;
    Result<void> read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) override;
    Result<void> read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                    std::vector<std::uint8_t>& out) override;
    Result<void> read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                             std::vector<std::uint8_t>& out) override;
    // What a desktop GPU with compute loads: the four storage formats when features().compute; false + why otherwise.
    bool storage_image_loadable(PixelFormat format, std::string* why) const override;
    // The background reads stay unsupported (no frames in flight to wait for): request_buffer_read fails with a hint.
    bool async_read_supported() const override { return false; }
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket, std::vector<std::uint8_t>&, bool) override { return false; }
    void release_buffer_read(ReadTicket) override {}

    // Fault injection for tests of a caller's failure path: the next `count` make_buffer calls whose label is `label` ("" = any
    // label) fail as a driver that is out of memory would (the handle is Failed, a "gpu: make_buffer" line goes to errors()).
    // count 0 clears it. The faults are used up in call order.
    void fail_next_make_buffer(const std::string& label, int count = 1);
    // Fault injection (M79 POLISH-RB): while set, make_shader of a shader whose ShaderDesc::label is `label` fails as a driver that cannot compile it
    // would (the shader is Failed, errors() says so). The label of a generated shader is its module and program ("upscale_rr_rr_hit_shader"). "" clears it.
    void fail_shaders_labelled(const std::string& label);

    // Test hooks (fault injection): while set, make_pipeline of a compute pipeline fails (the pipeline is Failed and errors() says so) and
    // build_tlas is refused. A real driver does both on a device that lies about its features or runs out of memory.
    void inject_faults(bool rejectComputePipelines, bool rejectTlasBuilds) {
        rejectCompute_ = rejectComputePipelines;
        rejectTlas_ = rejectTlasBuilds;
    }

    struct State;  // the resource pools and the facts the checks need (recording_device.cpp)

private:
    friend class RecordingCommandList;
    // Adds a message to errors(); mutex_ is held.
    void report_locked(std::string message);
    // The queue a list asked for runs on: the asked one with Features::asyncCompute, the graphics queue otherwise.
    QueueKind resolve_queue(QueueKind asked) const;
    // submit() of an open list of this device (mutex_ held); with `signal`, also emits and returns the list's token.
    SyncToken submit_locked(CommandList& list, bool signal, std::span<const QueueHandoff> handoffs);
    // The ownership checks of one list's resources (mutex_ held; asyncCompute only).
    void check_uses_locked(RecordingCommandList& list);
    // The handoffs of a submit_token(): checks them, moves the owners, records them (mutex_ held; asyncCompute only).
    void apply_handoffs_locked(RecordingCommandList& list, SyncToken token, std::span<const QueueHandoff> handoffs);
    // Reports a token no submit_token() returned (mutex_ held); true when it is fine.
    bool check_token_locked(const char* call, const char* label, SyncToken token);
    // A message for a misuse outside any command list ("gpu: make_view 'shadow map': ... Fix: ..."); mutex_ is held.
    void fail_locked(const char* call, const char* label, const std::string& what, const std::string& fix);
    // The checks and the record of a device-level read of an image (`format` None = any 4-byte colour format; `storage`
    // = the image must be a storage image of exactly `format`); the bytes it answers are the caller's. mutex_ is held.
    Result<void> read_image_locked(const char* call, Image image, PixelFormat format, bool storage, int x, int y,
                                   int width, int height);
    // Reports (errors()) a read while work recorded or submitted since the last commit() would not be on the GPU yet.
    void check_committed_locked(const char* call);

    DeviceInfo info_{};
    Features features_{};
    bool filterFloat32_ = false;  // DeviceInit::recordingFilterFloat32
    Limits limits_{};
    EnvironmentDefaults defaults_{};
    std::unique_ptr<State> state_;
    std::atomic<bool> rejectCompute_{false}, rejectTlas_{false};  // inject_faults
    mutable std::mutex mutex_;  // guards state_, the lists, the stream and the errors (lists record on any thread)
    std::vector<std::unique_ptr<RecordingCommandList>> lists_;
    std::string failBufferLabel_;  // fail_next_make_buffer
    int failBufferCount_ = 0;
    std::string failShaderLabel_;  // fail_shaders_labelled
};

}  // namespace fa::gpu
