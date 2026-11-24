// Private to fa_render: the engine's own Direct3D 12 backend of the GPU interface (M77.2,
// docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
//
// The first part of this header compiles on every platform: the options and make_d3d12_device(), which returns a
// teaching error where D3D12 does not exist. The second part (Windows only) declares D3d12Device and its helpers; the
// code is in d3d12_*_win32.cpp.
//
// What M77-P7a built: the adapter (hardware or WARP), the device, the debug layer and its InfoQueue, the direct queue,
// the fence and the frames in flight, the deferred release of destroyed resources, the CPU descriptor heaps (free
// lists), the shader-visible heaps (a ring of per-frame segments after a reserved bindless range), the upload ring,
// buffers, images, views and samplers, resource-state tracking with automatic barriers, the transfers of a command
// list, debug groups, the blocking readbacks, statistics and commit listeners. Shaders, pipelines, passes, draws,
// dispatches, bindings, uniforms, GPU timers and asynchronous reads come in M77-P7c: until then they report a
// "not yet (M77-P7c)" error (errors()) and do nothing.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>

#include "fa/core/types.h"
#include "gpu/device.h"

namespace fa::gpu {

// How make_d3d12_device() makes its device.
struct D3d12Options {
    // The WARP software rasterizer instead of the first hardware adapter (tests, CI machines without a GPU).
    bool warp = false;
    // The D3D12 debug layer: every API misuse becomes a message, and the ERROR and CORRUPTION ones go to
    // D3d12Device::errors() (and the log). Needs the Windows "Graphics Tools" optional feature; without it the device
    // is made without the layer and debug_layer_active() is false.
    bool debugLayer = false;
    // GPU-based validation (with debugLayer): checks descriptors and resource states on the GPU. Slow.
    bool gpuValidation = false;
    // Frames the CPU may record ahead of the GPU: 1 to 3.
    int framesInFlight = kInflightFrames;
    // Pool sizes (buffers, images, views, samplers, shaders, pipelines) and the environment defaults (the default
    // colour and depth formats and the sample count of a swapchain pass).
    DeviceInit init{};
    // Bytes of the upload ring that write_buffer, write_image and the initial data of make_buffer / make_image copy
    // through (shared by the frames in flight). An upload that does not fit takes a buffer of its own.
    std::size_t uploadRingBytes = 32u * 1024u * 1024u;
    // CPU (non shader-visible) descriptors: texture and storage views (a storage buffer view takes two: SRV and UAV),
    // colour attachments (RTV), depth attachments (DSV), samplers. 0 = from the pool sizes of `init`.
    int cpuViewDescriptors = 0;
    int cpuRtvDescriptors = 0;
    int cpuDsvDescriptors = 0;
    int cpuSamplerDescriptors = 0;
    // The shader-visible CBV/SRV/UAV heap: a range reserved for the bindless tables (M77-P7c), then one segment per
    // frame in flight that the bindings of that frame are copied into.
    int bindlessDescriptors = 32768;
    int frameViewDescriptors = 32768;
    // The shader-visible sampler heap: one segment per frame in flight (D3D12 allows 2048 samplers in all).
    int frameSamplerDescriptors = 512;
};

// Makes a Direct3D 12 device. Fails with a teaching error where D3D12 does not exist (every platform but Windows), when
// no adapter makes a feature level 11.0 device with resource binding tier 2, or when an option is out of range.
Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options& options = {});

}  // namespace fa::gpu

#if defined(_WIN32)

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
// windows.h first: the D3D headers need its types
#include <d3d12.h>
#include <d3d12sdklayers.h>
#include <dxgi1_6.h>

#include <array>
#include <atomic>
#include <deque>
#include <mutex>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace fa::gpu::d3d12 {

// An owning COM pointer (the engine does not depend on WRL). Copy = AddRef, destruction = Release.
template <class T>
class Com {
public:
    Com() = default;
    Com(std::nullptr_t) {}
    ~Com() { reset(); }
    Com(const Com& o) : p_(o.p_) {
        if (p_) p_->AddRef();
    }
    Com(Com&& o) noexcept : p_(o.p_) { o.p_ = nullptr; }
    Com& operator=(Com o) noexcept {
        std::swap(p_, o.p_);
        return *this;
    }
    void reset() {
        if (p_) {
            T* p = p_;
            p_ = nullptr;
            p->Release();
        }
    }
    T* get() const { return p_; }
    T* operator->() const { return p_; }
    explicit operator bool() const { return p_ != nullptr; }
    // For an out-parameter: releases what it holds, then hands its slot over.
    T** put() {
        reset();
        return &p_;
    }
    void** put_void() {
        reset();
        return reinterpret_cast<void**>(&p_);
    }
    // QueryInterface; empty when the object does not have U.
    template <class U>
    Com<U> as() const {
        Com<U> u;
        if (p_) p_->QueryInterface(__uuidof(U), u.put_void());
        return u;
    }

private:
    T* p_ = nullptr;
};

// "0x887A0005 (DXGI_ERROR_DEVICE_REMOVED)": an HRESULT in hex and its name, for the error messages.
std::string hr_text(HRESULT hr);
// UTF-8 <-> UTF-16 (labels into SetName and PIX markers, adapter names out).
std::wstring widen(const char* utf8);
std::string narrow(const wchar_t* utf16);

inline constexpr std::uint32_t kNoDescriptor = 0xFFFFFFFFu;
// Resource states are kept as their D3D12_RESOURCE_STATES bits in a uint32 (so "not seen yet" can be a value that is
// no state: kStateUnknown).
using StateBits = std::uint32_t;
inline constexpr StateBits kStateUnknown = 0xFFFFFFFFu;

// How the backend makes one PixelFormat: the resource's format (typeless for depth, so it can be sampled), the format
// of its shader views and of its attachment views. UNKNOWN resource = not supported here.
struct FormatInfo {
    DXGI_FORMAT resource = DXGI_FORMAT_UNKNOWN;
    DXGI_FORMAT srv = DXGI_FORMAT_UNKNOWN;
    DXGI_FORMAT rtv = DXGI_FORMAT_UNKNOWN;  // DSV format for the depth formats
    std::uint32_t planes = 1;               // 2 for depth-stencil (depth plane, stencil plane)
    std::uint32_t blockBytes = 0;           // compressed: bytes of one 4x4 block
};
FormatInfo format_info(PixelFormat f);
// Bytes of one row of `width` texels (a row of 4x4 blocks for a compressed format) and the number of such rows in
// `height` texels.
std::uint32_t texel_row_bytes(PixelFormat f, std::uint32_t width);
std::uint32_t texel_rows(PixelFormat f, std::uint32_t height);
inline std::uint64_t align_up(std::uint64_t v, std::uint64_t a) { return (v + a - 1) / a * a; }
inline std::uint32_t mip_extent(int v, int mip) {
    const int e = v >> mip;
    return std::uint32_t(e < 1 ? 1 : e);
}

// A GPU resource whose state the backend tracks: one D3D12_RESOURCE_STATES per subresource, the state the queue leaves
// it in after the lists submitted so far. Shared by the buffer or image record, the views of it, the command lists
// that use it and the deferred-release queue, so a resource destroyed while a list still holds it stays alive.
struct TrackedResource {
    Com<ID3D12Resource> resource;
    std::vector<StateBits> states;
    std::uint32_t mips = 1;
    std::uint32_t layers = 1;  // array layers or cube faces (1 for buffers and 3D images)
    std::uint32_t planes = 1;
    std::uint32_t subresource(std::uint32_t mip, std::uint32_t layer, std::uint32_t plane) const {
        return mip + layer * mips + plane * mips * layers;
    }
    std::uint32_t subresource_count() const { return mips * layers * planes; }
};

// A fixed-size table of records with generation-counted 32-bit ids (sokol's scheme): id = generation << 16 | (index +
// 1), so a destroyed id never names the next record of its slot.
template <class T>
class Pool {
public:
    void init(int capacity) {
        const int cap = capacity < 1 ? 1 : (capacity > 65534 ? 65534 : capacity);
        slots_.assign(std::size_t(cap), Slot{});
        free_.clear();
        for (int i = cap - 1; i >= 0; --i) free_.push_back(std::uint32_t(i));
    }
    // 0 when the pool is full.
    std::uint32_t add(T&& item) {
        if (free_.empty()) return 0;
        const std::uint32_t index = free_.back();
        free_.pop_back();
        Slot& s = slots_[index];
        s.generation = std::uint16_t(s.generation == 0xFFFF ? 1 : s.generation + 1);
        s.used = true;
        s.item = std::move(item);
        return (std::uint32_t(s.generation) << 16) | (index + 1);
    }
    T* get(std::uint32_t id) {
        Slot* s = slot(id);
        return s ? &s->item : nullptr;
    }
    const T* get(std::uint32_t id) const { return const_cast<Pool*>(this)->get(id); }
    // Moves the record out and frees its slot; false when `id` names nothing.
    bool remove(std::uint32_t id, T& out) {
        Slot* s = slot(id);
        if (!s) return false;
        out = std::move(s->item);
        s->item = T{};
        s->used = false;
        free_.push_back((id & 0xFFFFu) - 1);
        return true;
    }
    int capacity() const { return int(slots_.size()); }
    int alive() const { return int(slots_.size() - free_.size()); }

private:
    struct Slot {
        T item{};
        std::uint16_t generation = 0;
        bool used = false;
    };
    Slot* slot(std::uint32_t id) {
        const std::uint32_t index = id & 0xFFFFu;
        if (index == 0 || index > slots_.size()) return nullptr;
        Slot& s = slots_[index - 1];
        if (!s.used || s.generation != std::uint16_t(id >> 16)) return nullptr;
        return &s;
    }
    std::vector<Slot> slots_;
    std::vector<std::uint32_t> free_;
};

// A non shader-visible descriptor heap with a free list: the views and samplers are written here once, at make_*(),
// and copied into the shader-visible heap when a draw binds them (M77-P7c).
class CpuDescriptorHeap {
public:
    Result<void> init(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, std::uint32_t capacity, const char* name);
    // kNoDescriptor when every descriptor is taken. A freed descriptor is the next one handed out.
    std::uint32_t alloc();
    void free(std::uint32_t index);
    D3D12_CPU_DESCRIPTOR_HANDLE cpu(std::uint32_t index) const;
    std::uint32_t capacity() const { return capacity_; }
    std::uint32_t used() const;
    const char* name() const { return name_; }

private:
    // Its own lock, the innermost one: the device frees descriptors while it holds its queue lock (deferred releases)
    // and takes them while it holds its resource lock (make_view, make_sampler).
    mutable std::mutex mutex_;
    Com<ID3D12DescriptorHeap> heap_;
    D3D12_CPU_DESCRIPTOR_HANDLE start_{};
    std::uint32_t increment_ = 0;
    std::uint32_t capacity_ = 0;
    std::uint32_t next_ = 0;  // descriptors never handed out start here
    std::uint32_t used_ = 0;
    std::vector<std::uint32_t> free_;
    const char* name_ = "";
};

// A shader-visible descriptor heap: [0, reserved) is kept for the bindless tables (M77-P7c), then one segment of
// `perFrame` descriptors per frame in flight. alloc() takes a contiguous span from the current frame's segment; the
// segment is reused once the GPU finished the frame that last used it (begin_frame).
class ShaderVisibleHeap {
public:
    struct Span {
        D3D12_CPU_DESCRIPTOR_HANDLE cpu{};
        D3D12_GPU_DESCRIPTOR_HANDLE gpu{};
        std::uint32_t index = kNoDescriptor;  // in the heap
        std::uint32_t count = 0;
        bool ok() const { return index != kNoDescriptor; }
    };
    Result<void> init(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, std::uint32_t reserved,
                      std::uint32_t perFrame, int frames, const char* name);
    // `count` contiguous descriptors of this frame; !ok() when the segment has no room left (or count is 0).
    Span alloc(std::uint32_t count);
    // The frame in slot `slot` starts: its segment is empty again.
    void begin_frame(int slot);
    // The reserved (bindless) range.
    Span reserved() const;
    ID3D12DescriptorHeap* heap() const { return heap_.get(); }
    std::uint32_t frame_used() const;
    std::uint32_t per_frame() const { return perFrame_; }
    std::uint32_t increment() const { return increment_; }

private:
    Span span(std::uint32_t index, std::uint32_t count) const;
    mutable std::mutex mutex_;
    Com<ID3D12DescriptorHeap> heap_;
    D3D12_CPU_DESCRIPTOR_HANDLE cpuStart_{};
    D3D12_GPU_DESCRIPTOR_HANDLE gpuStart_{};
    std::uint32_t increment_ = 0;
    std::uint32_t reserved_ = 0;
    std::uint32_t perFrame_ = 0;
    int slot_ = 0;
    std::uint32_t used_ = 0;  // in the current segment
};

// Room in an upload (CPU-written, GPU-read) buffer: write `cpu`, copy from `resource` at `offset`.
struct UploadAlloc {
    ID3D12Resource* resource = nullptr;
    std::uint64_t offset = 0;
    std::uint8_t* cpu = nullptr;
    D3D12_GPU_VIRTUAL_ADDRESS gpu = 0;
    bool ok() const { return resource != nullptr; }
};

// The upload ring: one persistently mapped upload buffer shared by the frames in flight. Allocations move a head
// forward (wrapping to the start when the end has no room); a frame's room comes back once the GPU finished it.
class UploadRing {
public:
    Result<void> init(ID3D12Device* device, std::size_t bytes);
    // False when `size` does not fit: bigger than the ring, or the frames in flight still hold the room.
    bool alloc(std::size_t size, std::size_t align, UploadAlloc& out);
    // The recording of `frame` ended: what it took up to now belongs to it.
    void end_frame(std::uint64_t frame);
    // The GPU finished `frame` (and every frame before it).
    void frame_done(std::uint64_t frame);
    std::size_t size() const { return size_; }
    std::uint64_t wraps() const;
    std::size_t in_use() const;

private:
    mutable std::mutex mutex_;
    Com<ID3D12Resource> buffer_;
    std::uint8_t* cpu_ = nullptr;
    D3D12_GPU_VIRTUAL_ADDRESS gpu_ = 0;
    std::size_t size_ = 0;
    std::uint64_t head_ = 0;  // bytes ever taken (position = head_ % size_)
    std::uint64_t tail_ = 0;  // bytes ever given back
    std::uint64_t wraps_ = 0;
    std::deque<std::pair<std::uint64_t, std::uint64_t>> frames_;  // (frame, head at its end)
};

class D3d12Device;

// One command list of a frame: an ID3D12GraphicsCommandList and its allocator, reused once the GPU finished it. It
// tracks the state each resource must be in at its start (`first`) and is in at its end (`current`), per subresource;
// submit() turns the difference between the queue's states and `first` into a fix-up list executed just before it,
// so lists recorded in any order (or on several threads) still meet the states the queue really has.
class D3d12CommandList final : public CommandList {
public:
    explicit D3d12CommandList(D3d12Device& device) : device_(device) {}

    void begin_pass(const PassDesc& pass) override;
    void begin_compute_pass(const char* label) override;
    void end_pass() override;
    PassState pass_state() const override { return PassState::None; }
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

    // ---- the backend's side ------------------------------------------------------------------------------------------
    // Resource `t`'s subresource `sub` (or every one, kAllSubresources) must be in `state` for the next command.
    static constexpr std::uint32_t kAllSubresources = 0xFFFFFFFFu;
    void require(const std::shared_ptr<TrackedResource>& t, std::uint32_t sub, D3D12_RESOURCE_STATES state);
    // The same for mips [mip, mip + mipCount) of layers [layer, layer + layerCount), every plane.
    void require_range(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip, std::uint32_t mipCount,
                       std::uint32_t layer, std::uint32_t layerCount, D3D12_RESOURCE_STATES state);
    // Records the barriers require() collected (before every command that needs them).
    void flush_barriers();
    ID3D12GraphicsCommandList* native() const { return list_.get(); }
    const std::string& label() const { return label_; }
    // An upload buffer this list copies from that is not the ring's: released with the frame.
    void keep_until_done(Com<ID3D12Resource> r);

private:
    friend class D3d12Device;
    struct Use {
        std::shared_ptr<TrackedResource> res;
        std::vector<StateBits> first;    // the state the list needs at its start; kStateUnknown = not used
        std::vector<StateBits> current;  // the state the list leaves it in; kStateUnknown = not used
    };
    Result<void> create(const char* what);
    // Opens the list for recording (its allocator's previous commands must be finished).
    Result<void> open(const char* label);
    void not_yet(const char* what);
    void transition(Use& u, std::uint32_t sub, StateBits state);
    // Copies texels from CPU memory into an image through the upload ring: a width x height region at (x, y) of mip
    // `mip`, `count` layers from `layer` (2D, cube, array) or `count` depth slices from `layer` (3D). Source rows are
    // `srcRowPitch` apart, slices `srcSlicePitch`. False (and errors()) when no upload room could be had.
    bool upload_region(const std::shared_ptr<TrackedResource>& t, PixelFormat format, bool is3d, std::uint32_t mip,
                       std::uint32_t layer, std::uint32_t count, std::uint32_t x, std::uint32_t y, std::uint32_t width,
                       std::uint32_t height, const std::uint8_t* src, std::size_t srcRowPitch,
                       std::size_t srcSlicePitch);
    // Records the barriers and copies of a texel region from a buffer at a 512-aligned offset with 256-aligned rows.
    void copy_placed(ID3D12Resource* src, std::uint64_t offset, std::uint32_t rowPitch, std::uint64_t slicePitch,
                     const std::shared_ptr<TrackedResource>& t, PixelFormat format, bool is3d, std::uint32_t mip,
                     std::uint32_t layer, std::uint32_t count, std::uint32_t x, std::uint32_t y, std::uint32_t width,
                     std::uint32_t height);

    D3d12Device& device_;
    Com<ID3D12CommandAllocator> allocator_;
    Com<ID3D12GraphicsCommandList> list_;
    Com<ID3D12CommandAllocator> fixupAllocator_;  // the fix-up list submit() records before this one
    Com<ID3D12GraphicsCommandList> fixup_;
    std::string label_;
    bool open_ = false;
    bool internal_ = false;    // the device's own list (initial uploads, readbacks), never handed out
    bool empty_ = true;        // no command recorded yet
    std::uint64_t fence_ = 0;  // the fence value its last submission signals
    int debugDepth_ = 0;
    std::vector<Use> uses_;
    std::unordered_map<TrackedResource*, std::size_t> useIndex_;
    std::vector<D3D12_RESOURCE_BARRIER> pending_;
    std::vector<Com<ID3D12Resource>> keep_;
};

// What the backend counted (tests, the profiler).
struct D3d12Counters {
    std::uint64_t uploadRingWraps = 0;          // times the ring's head went back to its start
    std::uint64_t dedicatedUploads = 0;         // uploads that took a buffer of their own (too big, or ring full)
    std::size_t uploadRingBytes = 0;            // the ring's size
    std::size_t uploadRingInUse = 0;            // bytes the frames in flight still hold
    std::size_t pendingReleases = 0;            // destroyed objects waiting for their frame's fence
    std::uint32_t cpuViewDescriptors = 0;       // CPU descriptors in use: texture/storage views
    std::uint32_t cpuRtvDescriptors = 0;        // colour attachments
    std::uint32_t cpuDsvDescriptors = 0;        // depth attachments
    std::uint32_t cpuSamplerDescriptors = 0;    // samplers
    std::uint32_t frameViewDescriptors = 0;     // shader-visible CBV/SRV/UAV descriptors this frame took
    std::uint32_t frameSamplerDescriptors = 0;  // shader-visible samplers this frame took
    std::uint64_t barriers = 0;                 // resource barriers recorded (lists and fix-ups)
    std::uint64_t fenceValue = 0;               // the last value signalled
    std::uint64_t completedFenceValue = 0;      // the last value the GPU reached
};

// The Direct3D 12 Device. Made, used for resources and destroyed on one thread (the render thread); command lists may
// be recorded on other threads (a mutex guards the queue, the pools and the rings).
class D3d12Device final : public Device {
public:
    static Result<std::unique_ptr<D3d12Device>> create(const D3d12Options& options);
    ~D3d12Device() override;
    D3d12Device(const D3d12Device&) = delete;
    D3d12Device& operator=(const D3d12Device&) = delete;

    Backend backend() const override { return Backend::D3d12; }
    const DeviceInfo& info() const override { return info_; }
    const Features& features() const override { return features_; }
    const Limits& limits() const override { return limits_; }
    PixelFormatCaps pixel_format_caps(PixelFormat format) const override;
    EnvironmentDefaults environment_defaults() const override { return defaults_; }

    NativeDevice native() const override;
    NativeImage native_image(Image image) const override;
    NativeBuffer native_buffer(Buffer buffer) const override;
    MetalNative* native_metal() override { return nullptr; }  // Metal only (MetalFX)

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
    std::uint64_t frame_index() const override { return frame_; }
    bool add_commit_listener(void (*func)(void* user), void* user) override;
    bool remove_commit_listener(void (*func)(void* user), void* user) override;
    void reset_state_cache() override {}

    void enable_stats(bool on) override { statsEnabled_ = on; }
    bool stats_enabled() const override { return statsEnabled_; }
    TotalStats total_stats() const override;

    bool timer_supported(std::string* why) const override;
    void timer_begin_frame() override {}
    void timer_end_frame() override {}
    void timer_poll(std::vector<double>&) override {}
    std::vector<ScopeTime> timer_last_scopes() const override { return {}; }
    void timer_forget() override {}

    Result<void> read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) override;
    Result<void> read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) override;
    Result<void> read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                    std::vector<std::uint8_t>& out) override;
    Result<void> read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                             std::vector<std::uint8_t>& out) override;
    bool async_read_supported() const override { return false; }
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket ticket) override {}

    // ---- D3D12 only (tests, M77-P7c, M77-P9) --------------------------------------------------------------------------
    ID3D12Device* d3d_device() const { return device_.get(); }
    ID3D12CommandQueue* queue() const { return queue_.get(); }
    // The adapter's description ("Microsoft Basic Render Driver" for WARP).
    const std::string& adapter_name() const { return adapterName_; }
    bool warp() const { return warp_; }
    bool debug_layer_active() const { return debugLayer_; }
    bool gpu_validation_active() const { return gpuValidation_; }
    int frames_in_flight() const { return framesInFlight_; }
    // The errors so far: the debug layer's ERROR and CORRUPTION messages, failed D3D12 calls, calls not built yet.
    // Each also went to the log. Reading drains the debug layer's queue first.
    std::vector<std::string> errors();
    // The debug layer's WARNING messages so far.
    std::vector<std::string> warnings();
    void clear_messages();
    // Waits until the GPU finished everything submitted, then releases what was waiting for it.
    Result<void> wait_idle();
    D3d12Counters counters() const;
    // Mip `mip` of layer `layer` (array layer, cube face or 3D slice), the rectangle (x, y, w, h), tightly packed
    // rows top first, in the image's own format. Waits for the GPU.
    Result<void> read_image_region(Image image, int mip, int layer, int x, int y, int width, int height,
                                   std::vector<std::uint8_t>& out);
    // Upload room for this frame: from the ring, else a buffer of its own (released with the frame). !ok() only when
    // D3D12 could not make that buffer (reported in errors()).
    UploadAlloc upload(std::size_t size, std::size_t align, D3d12CommandList* keeper);
    ShaderVisibleHeap& view_heap() { return viewHeap_; }
    ShaderVisibleHeap& sampler_heap() { return samplerHeap_; }
    // Reports an error: errors() and the log.
    void report(const std::string& message);
    // Reports `message` the first time `what` is reported (a call not built yet, made every frame).
    void report_once(const std::string& what, const std::string& message);

private:
    friend class D3d12CommandList;
    D3d12Device() = default;

    struct BufferRecord {
        std::shared_ptr<TrackedResource> tracked;  // null when the creation failed
        std::size_t size = 0;
        BufferUsage usage{};
        std::string label;
    };
    struct ImageRecord {
        std::shared_ptr<TrackedResource> tracked;  // null when the creation failed
        ImageType type = ImageType::Tex2d;
        ImageUsage usage{};
        PixelFormat format = PixelFormat::Rgba8;
        int width = 0, height = 0, slices = 1, mips = 1, samples = 1;
        std::string label;
    };
    struct ViewRecord {
        ViewType type = ViewType::Invalid;
        std::shared_ptr<TrackedResource> tracked;  // null when the creation failed
        Buffer buffer{};
        Image image{};
        int mip = 0, mipCount = 1, slice = 0, sliceCount = 1;
        int heap = -1;  // index into cpuHeaps_ (-1: no descriptor, a resolve attachment)
        std::uint32_t descriptor = kNoDescriptor;
        std::uint32_t uavDescriptor = kNoDescriptor;  // a storage buffer's UAV (its SRV is `descriptor`)
    };
    struct SamplerRecord {
        std::uint32_t descriptor = kNoDescriptor;  // kNoDescriptor when the creation failed
        D3D12_SAMPLER_DESC desc{};
    };
    // Something destroyed while the GPU may still use it: released once `frame` was committed and the GPU finished it.
    struct Deferred {
        std::uint64_t frame = 0;
        std::shared_ptr<TrackedResource> tracked;
        Com<ID3D12Resource> raw;
        int heap = -1;
        std::uint32_t descriptor = kNoDescriptor;
        std::uint32_t descriptor2 = kNoDescriptor;
    };
    enum HeapIndex { kHeapView = 0, kHeapRtv = 1, kHeapDsv = 2, kHeapSampler = 3, kHeapCount = 4 };
    struct Listener {
        void (*func)(void*) = nullptr;
        void* user = nullptr;
    };

    Result<void> init(const D3d12Options& options);
    Result<void> init_adapter(const D3d12Options& options);
    void init_caps();
    // A free command list (open for recording), from the pool or new; null with errors() when D3D12 failed.
    D3d12CommandList* acquire_list(const char* label, bool internal);
    // Closes `list`, executes its fix-up list and it, signals the fence. Under queueMutex_.
    void execute(D3d12CommandList& list);
    // The device's own list for initial uploads and readbacks, opened on first use. Under queueMutex_.
    D3d12CommandList& prelude();
    // Executes the prelude if it recorded anything. Under queueMutex_.
    void flush_prelude();
    // Waits (bounded) until the fence reaches `value`. Under queueMutex_ or not.
    Result<void> wait_fence(std::uint64_t value, const char* what);
    // Releases what the GPU is done with and gives the finished frames' ring room back. Under queueMutex_.
    void collect();
    void defer(Deferred d);
    // Moves the debug layer's messages into errors_ / warnings_.
    void drain_messages();
    std::string removed_reason() const;
    void count_make(ResourceTotals& t, bool ok);
    void count_destroy(ResourceTotals& t);
    std::shared_ptr<TrackedResource> buffer_tracked(Buffer b, std::size_t* size, std::string* label) const;
    // The image's record copied out (under resMutex_): false when `image` names nothing or failed.
    bool image_info(Image image, ImageRecord& out) const;
    Com<ID3D12Resource> make_committed(const D3D12_RESOURCE_DESC& desc, D3D12_HEAP_TYPE heap,
                                       D3D12_RESOURCE_STATES state, const char* what, const char* label);
    void upload_initial_image(const ImageRecord& rec, const ImageDesc& desc);
    // Copies `region` of the image into a readback buffer and waits; `rowBytes` per row come back tightly packed.
    Result<void> read_texture(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y, int width,
                              int height, std::vector<std::uint8_t>& out, const char* what);

    // The D3D12 objects
    Com<IDXGIFactory4> factory_;
    Com<IDXGIAdapter1> adapter_;
    Com<ID3D12Device> device_;
    Com<ID3D12InfoQueue> infoQueue_;
    Com<ID3D12CommandQueue> queue_;
    Com<ID3D12Fence> fence_;
    HANDLE fenceEvent_ = nullptr;
    std::string adapterName_;
    bool warp_ = false;
    bool debugLayer_ = false;
    bool gpuValidation_ = false;
    int framesInFlight_ = kInflightFrames;

    // What the device can do
    DeviceInfo info_{};
    Features features_{};
    Limits limits_{};
    EnvironmentDefaults defaults_{};
    std::array<PixelFormatCaps, std::size_t(PixelFormat::Count)> caps_{};

    // Resources (resMutex_)
    mutable std::mutex resMutex_;
    Pool<BufferRecord> buffers_;
    Pool<ImageRecord> images_;
    Pool<ViewRecord> views_;
    Pool<SamplerRecord> samplers_;
    std::array<CpuDescriptorHeap, kHeapCount> cpuHeaps_;

    // The queue, the frames, the lists (queueMutex_)
    mutable std::mutex queueMutex_;
    std::vector<std::unique_ptr<D3d12CommandList>> lists_;
    D3d12CommandList* prelude_ = nullptr;
    std::uint64_t fenceValue_ = 0;
    std::uint64_t frame_ = 0;
    std::uint64_t completedFrames_ = 0;  // frames [0, completedFrames_) are finished on the GPU
    std::deque<std::pair<std::uint64_t, std::uint64_t>> frameFences_;  // (frame, fence value of its commit)
    std::deque<Deferred> deferred_;
    UploadRing ring_;
    std::atomic<std::uint64_t> dedicatedUploads_{0};
    std::atomic<std::uint64_t> barriers_{0};
    ShaderVisibleHeap viewHeap_;
    ShaderVisibleHeap samplerHeap_;
    std::vector<Listener> listeners_;

    // Messages (msgMutex_)
    mutable std::mutex msgMutex_;
    std::vector<std::string> errors_;
    std::vector<std::string> warnings_;
    std::vector<std::string> notYetReported_;  // each "not yet" call is reported once

    // Statistics (resMutex_)
    bool statsEnabled_ = false;
    TotalStats stats_{};
};

}  // namespace fa::gpu::d3d12

#endif  // _WIN32
