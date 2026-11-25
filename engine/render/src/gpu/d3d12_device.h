// Private to fa_render: the engine's own Direct3D 12 backend of the GPU interface (M77.2,
// docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
//
// The first part of this header compiles on every platform: the options and make_d3d12_device(), which returns a
// teaching error where D3D12 does not exist. The second part (Windows only) declares D3d12Device and its helpers; the
// code is in d3d12_*_win32.cpp.
//
// What it has: the adapter (hardware or WARP), the device, the debug layer and its InfoQueue, the direct queue, the
// fence and the frames in flight, the deferred release of destroyed resources, the CPU descriptor heaps (free lists),
// the shader-visible heaps (a ring of per-frame segments after a reserved bindless range), the upload ring, buffers,
// images, views and samplers, resource-state tracking with automatic barriers, the transfers of a command list, debug
// groups, the blocking readbacks, statistics and commit listeners (M77-P7a); shaders (DXBC SM 5.1, compiled from HLSL
// when given source) with one cached root signature per binding layout, graphics and compute pipelines with an
// in-memory PSO cache, render passes into views (clears, MSAA resolve), compute passes, bindings, uniforms, viewports,
// scissors, draws and dispatches (M77-P7c1); GPU timers (timestamp queries) and asynchronous reads of buffers and
// texture regions (M77-P7c2); the PSO cache on disk (an ID3D12PipelineLibrary in a file, M77-P7b). The renderer draws
// through it offscreen (RendererDesc::backend D3d12, make_device). The window (M77-P9c, d3d12_swapchain_win32.cpp): a
// DXGI flip-model swapchain on a native HWND (create_swapchain), its back buffers adopted as images with views, so a
// PassDesc::for_swapchain pass draws into the acquired one; scRGB and HDR10 colour spaces.
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
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
    // A COMPUTE queue (Features::asyncCompute: QueueKind::Compute lists run on it) and a COPY queue
    // (QueueKind::Transfer lists, the copy engine). False = only the direct queue, every list runs there
    // (CommandList::queue() is Graphics), as when D3D12 cannot make them.
    bool asyncQueues = true;
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
    // The shader-visible CBV/SRV/UAV heap: a range reserved for the bindless table (every root signature sees it as
    // an unbounded SRV range at t0, space1; 0 = no bindless table), then one segment per frame in flight that the
    // bindings of that frame are copied into. A GPU of resource binding tier 1 has no unbounded ranges: there the
    // device makes no bindless table, whatever this asks (D3d12Device::bindless_descriptors() says what it made).
    int bindlessDescriptors = 32768;
    int frameViewDescriptors = 32768;
    // The shader-visible sampler heap: one segment per frame in flight (D3D12 allows 2048 samplers in all).
    int frameSamplerDescriptors = 512;
    // The on-disk PSO cache (an ID3D12PipelineLibrary): loaded when the device is made, written by
    // D3d12Device::save_pipeline_cache() and when the device is destroyed. Empty = no file (the PSOs are still cached
    // in memory for the device's life). The engine's file is d3d12_pipeline_cache_file().
    std::filesystem::path pipelineCacheFile;
};

// Makes a Direct3D 12 device. Fails with a teaching error where D3D12 does not exist (every platform but Windows), when
// no adapter makes a feature level 11.0 device, or when an option is out of range.
Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options& options = {});

// The engine's D3D12 pipeline cache file: d3d12-pipelines.bin in the shader cache's folder (fs::cache_dir()/shaders,
// next to the d3d12-dxbc stages). Empty when there is no cache folder (the web build, a player before set_cache_dir).
std::filesystem::path d3d12_pipeline_cache_file();

// What the D3D12 devices of this process did with their pipeline caches (the shader cache's report shows it).
struct D3d12PipelineCacheTotals {
    std::uint64_t libraryHits = 0;     // PSOs loaded from a pipeline library instead of compiled
    std::uint64_t libraryMisses = 0;   // PSOs compiled and stored into a pipeline library
    std::uint64_t filesLoaded = 0;     // cache files a device loaded
    std::uint64_t filesStored = 0;     // cache files written
    std::uint64_t filesDiscarded = 0;  // cache files thrown away (damaged, another GPU or driver)
    std::uint64_t storeFailed = 0;     // writes that failed (the old file was kept)
};
D3d12PipelineCacheTotals d3d12_pipeline_cache_totals();
// Adds `add` to the totals (the D3D12 device's own counting).
void d3d12_pipeline_cache_count(const D3d12PipelineCacheTotals& add);

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
#include <functional>
#include <mutex>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace fa {
class PackReader;
}

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
    // A buffer: the queue decays it to COMMON at the end of every ExecuteCommandLists and its first use in a list
    // promotes it implicitly, so it never needs a fix-up barrier (states[0] is COMMON between lists).
    bool buffer = false;
    // The queue that owns it (a new resource: Graphics; a QueueHandoff at submit_token moves it) and the token the
    // owner's next list must wait for before it touches it (invalid once a list of the owner waited for it). `states`
    // is the owner queue's view. Under queueMutex_.
    QueueKind owner = QueueKind::Graphics;
    SyncToken handoff{};
    std::string label;  // "buffer 'x'" or "image 'x'", for the ownership errors of submit_token
    // What the errors call it: the label, or a default for a resource nothing named.
    std::string display_name() const {
        return !label.empty() ? label : buffer ? "an unnamed buffer" : "an unnamed image";
    }
    std::uint32_t subresource(std::uint32_t mip, std::uint32_t layer, std::uint32_t plane) const {
        return mip + layer * mips + plane * mips * layers;
    }
    std::uint32_t subresource_count() const { return mips * layers * planes; }
};

// The D3D12 queue and command list type of a (mapped) queue.
inline D3D12_COMMAND_LIST_TYPE list_type(QueueKind q) {
    switch (q) {
        case QueueKind::Compute: return D3D12_COMMAND_LIST_TYPE_COMPUTE;
        case QueueKind::Transfer: return D3D12_COMMAND_LIST_TYPE_COPY;
        default: return D3D12_COMMAND_LIST_TYPE_DIRECT;
    }
}

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
// and copied into the shader-visible heap when set_bindings binds them.
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

// A shader-visible descriptor heap: [0, reserved) is kept for the bindless table, then one segment of
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

// What a shader declares, as the backend binds it (made once by make_shader, shared by its pipelines). Stage index 0
// is the vertex (or compute) stage, 1 the fragment stage.
struct ShaderInfo {
    bool compute = false;
    std::string label;
    std::uint32_t uniformSize[kMaxUniformBlocks]{};  // 0 = the slot is unused
    ViewType viewType[kMaxViews]{};                  // Invalid = the slot is unused
    bool viewWritable[kMaxViews]{};                  // bound as a UAV (storage image, writable storage buffer)
    std::string semName[kMaxVertexAttributes];       // the vertex attribute's HLSL semantic; empty = none
    std::uint8_t semIndex[kMaxVertexAttributes]{};
    std::vector<std::uint8_t> vs, fs, cs;  // DXBC
    std::string codeKey;                   // the SHA-256 of the bytecode (the PSO cache key's part)
};

// A root signature and where each slot of a shader sits in it (cached per layout: every shader with the same
// registers shares one). Root parameters: one root CBV per uniform block, then per stage a table of its views
// (SRV and UAV ranges) and one of its samplers, then the bindless table.
struct RootLayout {
    Com<ID3D12RootSignature> signature;
    std::string key;
    int cbvParam[kMaxUniformBlocks]{};  // root parameter index; -1 = the slot is unused
    int viewTable[2] = {-1, -1};        // root parameter of each stage's view table; -1 = none
    int samplerTable[2] = {-1, -1};
    std::uint32_t viewCount[2]{};
    std::uint32_t samplerCount[2]{};
    std::uint8_t viewStage[kMaxViews]{};    // the table (stage index) of the view slot
    std::uint32_t viewOffset[kMaxViews]{};  // the slot's descriptor in that table
    std::uint8_t samplerStage[kMaxSamplers]{};
    std::uint32_t samplerOffset[kMaxSamplers]{};
    std::uint32_t samplerUsed = 0;  // bit per sampler slot
    int bindlessTable = -1;         // the unbounded SRV table at t0, space1; -1 = none
};

// A pipeline as a command list sets it: the PSO and what set_pipeline, set_bindings and the draws need.
struct PipelineState {
    Com<ID3D12PipelineState> pso;
    std::shared_ptr<const RootLayout> layout;
    std::shared_ptr<const ShaderInfo> shader;
    bool compute = false;
    D3D_PRIMITIVE_TOPOLOGY topology = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
    IndexType indexType = IndexType::None;
    std::uint32_t strides[kMaxVertexBuffers]{};
    std::uint32_t buffersUsed = 0;  // bit per vertex buffer slot the layout reads
    float blendColor[4]{};
    std::uint8_t stencilRef = 0;
    TargetFormat format{};  // what the pass must have
    int colorCount = 0;
    std::string label;
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
    PassState pass_state() const override { return passState_; }
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
    // The queue it runs on: the one begin_commands asked for, or the queue that stands in for it (map_queue).
    QueueKind queue() const override { return kind_; }

    // ---- the backend's side -----------------------------------------------------------------------------------------
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
    // A timed scope this list recorded: scope `scope` of the timed frame `serial`, in the query heap `heap` (the
    // device's timer slot `slot`).
    struct ScopeRef {
        std::uint64_t serial = 0;
        int slot = -1;
        std::uint32_t scope = 0;
        ID3D12QueryHeap* heap = nullptr;  // lives as long as the device
    };
    struct Use {
        std::shared_ptr<TrackedResource> res;
        std::vector<StateBits> first;    // the state the list needs at its start; kStateUnknown = not used
        std::vector<StateBits> current;  // the state the list leaves it in; kStateUnknown = not used
    };
    // Makes the allocator and the list of `kind`'s type (DIRECT, COMPUTE or COPY); a list made for another queue
    // before is replaced, its fix-up list too.
    Result<void> create(const char* what, QueueKind kind);
    // Opens the list for recording (its allocator's previous commands must be finished).
    Result<void> open(const char* label);
    void transition(Use& u, std::uint32_t sub, StateBits state);
    // A UAV barrier on `t` when this list already left it in the UAV state (a write before this use).
    void uav_barrier_if_written(const std::shared_ptr<TrackedResource>& t);
    // Records the end timestamp of the timed scope still open (end_timed_scope, and submit for a scope left open).
    void close_scope();
    // Reports an error of CommandList::`what` in this list.
    void fail(const char* what, const std::string& error);
    // The checks every draw and dispatch makes: false (reported) when it cannot run.
    bool ready_to_run(const char* what, bool compute);
    // Back to "no pipeline, nothing bound" (a pass ends, the list opens).
    void reset_bind_state();
    // set_viewport and set_viewport_f: the rectangle in the pass's pixels (y flipped when not originTopLeft).
    void apply_viewport(const char* what, float x, float y, float width, float height, bool originTopLeft);
    // draw and draw_ex: the checks, the barriers and the (indexed) instanced draw.
    void record_draw(const char* what, int base, int count, int instances, int baseVertex, int baseInstance);
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
    QueueKind kind_ = QueueKind::Graphics;  // the queue its allocator and list are made for
    Com<ID3D12CommandAllocator> allocator_;
    Com<ID3D12GraphicsCommandList> list_;
    Com<ID3D12CommandAllocator> fixupAllocator_;  // the fix-up list submit() records before this one
    Com<ID3D12GraphicsCommandList> fixup_;
    // The tokens of other queues its work waits for (Device::wait_list; reset by open()), mapped to real queues.
    std::vector<SyncToken> waits_;
    std::string label_;
    bool open_ = false;
    bool internal_ = false;        // the device's own list (initial uploads, readbacks), never handed out
    bool empty_ = true;            // no command recorded yet
    std::uint64_t fence_ = 0;      // the value its last submission signals on its queue's fence
    std::uint64_t openFrame_ = 0;  // the frame it was opened in (it is submitted in the same one)
    int debugDepth_ = 0;
    std::vector<Use> uses_;
    std::unordered_map<TrackedResource*, std::size_t> useIndex_;
    std::vector<D3D12_RESOURCE_BARRIER> pending_;
    std::vector<Com<ID3D12Resource>> keep_;

    // The pass and what is bound (reset by open(), begin_pass and end_pass).
    PassState passState_ = PassState::None;
    TargetFormat passFormat_{};
    int passColors_ = 0;
    std::uint32_t passWidth_ = 0, passHeight_ = 0;
    std::shared_ptr<TrackedResource> resolveSrc_, resolveDst_;  // the MSAA resolve end_pass records
    std::uint32_t resolveSrcSub_ = 0, resolveDstSub_ = 0;
    DXGI_FORMAT resolveFormat_ = DXGI_FORMAT_UNKNOWN;
    std::shared_ptr<const PipelineState> pipeline_;
    ID3D12RootSignature* rootSignature_ = nullptr;  // the one set (kept alive by pipeline_)
    bool rootCompute_ = false;
    std::uint32_t uniformsSet_ = 0;  // bit per uniform block slot set since set_pipeline
    bool bindingsSet_ = false;
    // begin_pass failed (reported): the pass is open so end_pass matches it, but its commands are skipped.
    bool passFailed_ = false;
    // set_pipeline, set_bindings or set_uniforms failed (reported): the draws and dispatches are skipped until the next
    // set_pipeline (sokol's rule, so one mistake is one error and not one per draw).
    bool drawsFailed_ = false;
    // The resources the bindings bind as UAVs, and whether a draw or dispatch ran with them since: the next one adds a
    // UAV barrier on each (its writes must be visible to the next command).
    std::vector<std::shared_ptr<TrackedResource>> boundUavs_;
    bool uavsWritten_ = false;
    // The timed scopes recorded in this list (reset by open()); the last one is still open when scopeOpen_.
    std::vector<ScopeRef> scopes_;
    bool scopeOpen_ = false;
    // The open pass's attachments (colour, second colour, depth): set_bindings refuses to bind one of them for
    // reading or writing (reset by open(), begin_pass and end_pass).
    struct PassAttachment {
        std::shared_ptr<TrackedResource> tracked;
        std::uint32_t mip = 0, layer = 0;
        const char* role = "";
    };
    std::vector<PassAttachment> passAttachments_;
};

// What the backend counted (tests, the profiler).
struct D3d12Counters {
    std::uint64_t uploadRingWraps = 0;        // times an upload did not fit before the ring's end and went to its start
    std::uint64_t dedicatedUploads = 0;       // uploads that took a buffer of their own (too big, or ring full)
    std::size_t uploadRingBytes = 0;          // the ring's size
    std::size_t uploadRingInUse = 0;          // bytes the frames in flight still hold
    std::size_t pendingReleases = 0;          // destroyed objects waiting for their frame's fence
    std::uint32_t cpuViewDescriptors = 0;     // CPU descriptors in use: texture/storage views
    std::uint32_t cpuRtvDescriptors = 0;      // colour attachments
    std::uint32_t cpuDsvDescriptors = 0;      // depth attachments
    std::uint32_t cpuSamplerDescriptors = 0;  // samplers
    std::uint32_t frameViewDescriptors = 0;   // shader-visible CBV/SRV/UAV descriptors this frame took
    std::uint32_t frameSamplerDescriptors = 0;  // shader-visible samplers this frame took
    std::uint64_t barriers = 0;                 // resource barriers recorded (lists and fix-ups)
    std::uint64_t fenceValue = 0;               // the last value signalled
    std::uint64_t completedFenceValue = 0;      // the last value the GPU reached
    std::uint64_t psoCacheHits = 0;             // make_pipeline calls that found their PSO made already
    std::uint64_t psoCacheMisses = 0;           // make_pipeline calls that made a PSO
    std::size_t psos = 0;                       // PSOs the device keeps (they live as long as it)
    std::uint64_t rootSignatureCacheHits = 0;   // make_shader calls that found their root signature made already
    std::size_t rootSignatures = 0;             // root signatures the device keeps
    bool pipelineLibrary = false;               // an ID3D12PipelineLibrary backs the PSO cache (a cache file is set)
    std::uint64_t psoLibraryHits = 0;           // PSOs loaded from the library instead of compiled
    std::uint64_t psoLibraryMisses = 0;         // PSOs compiled and stored into the library
    std::uint64_t pipelineCacheStored = 0;      // times this device wrote its cache file
    std::uint64_t pipelineCacheDiscarded = 0;   // cache files it threw away (damaged, another GPU or driver)
    std::uint64_t packReadsDirect = 0;          // pack reads DirectStorage wrote into a buffer or image
    std::uint64_t packReadsCpu = 0;             // pack reads decoded on the CPU and uploaded (the fallback)
    std::uint64_t packBlocksDirect = 0;         // pack blocks DirectStorage read for them
    std::uint64_t packFilesOpened = 0;          // pack files DirectStorage opened for them (one handle per live pack)
    std::uint64_t packFilesClosed = 0;          // of those, the ones closed because their pack was gone
    std::size_t packReadsInFlight = 0;          // tickets not finished yet
};

// A range of a file of a game pack, read into a GPU resource by read_pack_to_buffer / read_pack_to_image.
struct PackSource {
    std::shared_ptr<const PackReader> pack;  // kept alive by the read until it finishes
    std::string path;                        // the file in the pack (project-relative, as PackReader::read takes it)
    std::uint64_t offset = 0;                // the range's first byte in the (decoded) file
    std::uint64_t size = 0;                  // its bytes; must lie inside the file
};

// The texel region of one subresource that read_pack_to_image fills: mip `mip` of layer `layer` (array layer, cube
// face, or depth slice of a 3D image), the rectangle (x, y, width, height). A compressed format's rectangle starts on a
// 4x4 block and its size is whole blocks, or reaches the mip's edge (a mip smaller than a block, 2x2 say, is read with
// its own width and height, and the read writes its whole block).
struct PackImageRegion {
    int mip = 0, layer = 0;
    int x = 0, y = 0, width = 0, height = 0;
};

// A pack read in flight: invalid (slot -1) when every slot is busy (ask again next frame).
struct PackReadTicket {
    int slot = -1;
    std::uint32_t generation = 0;
    bool valid() const { return slot >= 0 && generation != 0; }
};

// How a finished pack read went.
struct PackReadResult {
    bool direct = false;             // DirectStorage wrote it (else the CPU decoded it and an upload copied it)
    std::uint64_t bytes = 0;         // the range's bytes
    std::uint64_t directBlocks = 0;  // the pack blocks DirectStorage read for it
    std::string error;               // empty: the destination holds the bytes
};

// The pipeline cache file (d3d12_pipelines_win32.cpp): a header, then the ID3D12PipelineLibrary's serialized blob.
// Little-endian; the offsets are in bytes. A file whose magic, version, adapter (vendor, device, subsystem, revision),
// driver version, size or SHA-256 does not match is thrown away before the driver sees it.
struct PipelineCacheFile {
    static constexpr char kMagic[9] = "FAPSOLIB";  // 8 bytes at 0
    static constexpr std::uint32_t kVersion = 1;
    static constexpr std::size_t kVersionAt = 8;       // u32
    static constexpr std::size_t kHeaderSizeAt = 12;   // u32: kHeaderBytes
    static constexpr std::size_t kVendorAt = 16;       // u32, then device, subsystem and revision ids (u32 each)
    static constexpr std::size_t kDriverAt = 32;       // u64: IDXGIAdapter::CheckInterfaceSupport's UMD version
    static constexpr std::size_t kLuidAt = 40;         // u32 low, i32 high: recorded only (it changes with each boot)
    static constexpr std::size_t kPayloadSizeAt = 48;  // u64
    static constexpr std::size_t kChecksumAt = 56;     // 64 bytes: the payload's SHA-256 in lowercase hex
    static constexpr std::size_t kHeaderBytes = 120;
};

// The Direct3D 12 Device. Made, used for resources and destroyed on one thread (the render thread); command lists may
// be recorded on other threads (Features::multiThreadRecording: a mutex guards the queues, the pools and the rings, and
// a list reads a view's CPU descriptor under the pools' lock). Three queues: direct (Graphics), compute (Compute) and
// copy (Transfer), each with its own 64-bit fence (D3d12Options::asyncQueues; the contract is device.h's "Queues,
// threads and bindless", this backend's side docs/design/ARCHITECTURE_RENDERING_D3D12.md, "Queues").
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
    // The root signature layout of a valid shader (tests check where each slot sits); null for a failed or unknown one.
    std::shared_ptr<const RootLayout> shader_root_layout(Shader shader) const;

    using Device::begin_commands;
    using Device::submit_token;
    CommandList& begin_commands(const char* label) override;
    CommandList& begin_commands(const char* label, QueueKind queue) override;
    void submit(CommandList& list) override;
    SyncToken submit_token(CommandList& list, std::span<const QueueHandoff> handoffs) override;
    void wait_list(CommandList& list, SyncToken token) override;
    void wait_queue(QueueKind queue, SyncToken token) override;
    // The view's slot in the bindless table (t0 space1): every live Texture view of a device with a table has one.
    std::uint32_t bindless_index(View view) const override;
    void commit() override;
    std::uint64_t frame_index() const override { return frame_; }
    bool add_commit_listener(void (*func)(void* user), void* user) override;
    bool remove_commit_listener(void (*func)(void* user), void* user) override;
    void reset_state_cache() override {}

    void enable_stats(bool on) override { statsEnabled_ = on; }
    bool stats_enabled() const override { return statsEnabled_; }
    TotalStats total_stats() const override;

    // GPU timers (d3d12_timers_win32.cpp): timestamp queries on the direct queue, a ring of kTimerSlots timed frames,
    // each with its own query heap and readback buffer, resolved once the frame's fence passed.
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
    // Typed UAV loads of `format` (a storage image a shader reads): r32f on every D3D12 GPU, the others when
    // D3D12_OPTIONS.TypedUAVLoadAdditionalFormats and the format's UAV_TYPED_LOAD support say so.
    bool storage_image_loadable(PixelFormat format, std::string* why) const override;
    // Asynchronous reads (d3d12_readback_win32.cpp): kAsyncReads slots, each with a readback buffer it keeps while it
    // is big enough. A request records the copy on an internal list and executes it at once (no wait); the slot's
    // fence value says when the bytes are there. A released slot is reused only once its copy finished.
    bool async_read_supported() const override { return true; }
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket ticket) override;

    // The window (d3d12_swapchain_win32.cpp; render thread only): a DXGI flip-model swapchain (FLIP_DISCARD) on
    // SwapchainDesc::nativeWindow, an HWND, made on the direct queue with as many buffers as frames in flight (at
    // least 2). Each back buffer is an image of the pools with a colour view (a resolve view when the swapchain is
    // multisampled: the pass then draws into an MSAA image of its own and resolves into it), next to a depth image in
    // EnvironmentDefaults::depthFormat. acquire_swapchain waits (bounded) for the frame-latency object, then hands back
    // the swapchain whose PassDesc::for_swapchain pass draws into the current back buffer; present moves it to the
    // PRESENT state on the direct queue and presents it (tearing allowed when vsync is off and DXGI can).
    // resize_swapchain waits for the GPU, drops the buffers' images and views, ResizeBuffers and makes them again.
    // Rgba16F is scRGB (DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709), Rgb10A2 HDR10 (G2084_NONE_P2020); create_swapchain
    // fails when the swapchain cannot present in that colour space (CheckColorSpaceSupport).
    Result<void> create_swapchain(const SwapchainDesc& desc) override;
    Result<void> resize_swapchain(int width, int height) override;
    Result<Swapchain> acquire_swapchain(const Swapchain& windowFrame) override;
    Result<void> present() override;
    void destroy_swapchain() override;
    bool has_swapchain() const override;
    // Default and the SDR formats (Bgra8, Sbgr8A8, Rgba8, Srgb8A8), Rgba16F and Rgb10A2 when the GPU can display and
    // render to their back-buffer format (D3D12_FORMAT_SUPPORT1_DISPLAY and RENDER_TARGET). Whether the window's
    // display takes the HDR colour space is asked by create_swapchain (and the platform's fa/platform/hdr_output.h).
    bool swapchain_format_supported(PixelFormat format, std::string* why) const override;

    // ---- D3D12 only (tests) -----------------------------------------------------------------------------------------
    // The back buffer acquire_swapchain handed out this frame (invalid before the acquire and after present): a test
    // reads it back (read_image_rgba8) before present.
    Image swapchain_image() const;
    // The swapchain's buffer count, and whether its presents may tear (DXGI_FEATURE_PRESENT_ALLOW_TEARING); 0 / false
    // without a swapchain.
    int swapchain_buffer_count() const;
    bool swapchain_tearing() const;
    // Frames whose acquire_swapchain gave up waiting for the frame-latency object (it then draws anyway).
    std::uint64_t swapchain_wait_timeouts() const;
    // The asynchronous read of a texel region: mip `mip` of layer `layer` (array layer, cube face or 3D slice), the
    // rectangle (x, y, width, height). poll_buffer_read() hands it over tightly packed, top row first, in the image's
    // own format; release_buffer_read() drops it. An invalid ticket with ok = every slot is busy. Render thread only.
    Result<ReadTicket> request_image_read(Image image, int mip, int layer, int x, int y, int width, int height);

    // Pack reads into GPU resources (d3d12_pack_reads_win32.cpp, docs/design/ARCHITECTURE_FILES.md, "DirectStorage").
    // Bytes [src.offset, src.offset + src.size) of a file of a game pack go into `buffer` from `dstOffset`, or into a
    // texel region of an image. On Windows x64 with the DirectStorage DLLs (`factoria setup directstorage`), a pack on
    // disk and a gdeflate (or stored) file, DirectStorage reads the blocks into the resource itself, on a queue made
    // with this device, and decompresses GDeflate on the GPU where the GPU and its driver can (else on its own CPU
    // path); a block the range holds only part of is decoded on the CPU and uploaded first. Anything else (no
    // DirectStorage, a pack in memory, another codec, a texture region whose rows do not fill whole blocks, a failed
    // DirectStorage read) takes the CPU fallback: PackReader::read_range and an upload, with one warning per reason.
    // The image read's range holds the region as D3D12's copyable footprint: its rows (of texels, or of 4x4 blocks)
    // 256-byte aligned apart, the last row unpadded (fa::detail::direct_texture_bytes). Each read takes a slot
    // (kPackReads in all): the ticket is invalid with ok() when every slot is busy. Until poll_pack_read says the read
    // finished, what DirectStorage writes from its own queue must not be used, and the resource must not be destroyed:
    // a buffer read owns the whole buffer (DirectStorage's queue writes it in COMMON while it reads, so no other queue
    // may touch any of it); an image read owns its subresource (mip `mip` of layer `layer`; of a 3D image the whole
    // mip, every depth slice), not only the rectangle, since that subresource is in COMMON for the read. The image's
    // other mips and layers may be sampled or written meanwhile, through views that leave the read's subresource out
    // (the state tracking is per subresource; a view of every mip would move it out of COMMON). The resource is left in
    // the COMMON state, which the state tracking knows. A lost device ends the read with an error. Render thread only.
    static constexpr int kPackReads = 64;
    Result<PackReadTicket> read_pack_to_buffer(const PackSource& src, Buffer buffer, std::size_t dstOffset);
    Result<PackReadTicket> read_pack_to_image(const PackSource& src, Image image, const PackImageRegion& region);
    // True once the read finished (`out` says how, and whether it failed); false while it runs, and for a stale ticket.
    // `wait` waits (bounded) until it finished. A finished read's ticket is stale after this call.
    bool poll_pack_read(PackReadTicket ticket, PackReadResult& out, bool wait);
    // Drops the ticket; the read itself runs to its end before its slot is reused.
    void release_pack_read(PackReadTicket ticket);
    // Why reads do not use DirectStorage on this device ("" when they do, or none was asked for yet).
    std::string pack_reads_direct_why() const;
    // The pack reads' state (defined in d3d12_pack_reads_win32.cpp; public only so its helpers can name them).
    struct PackReads;
    struct PackRead;
    // The size of the bindless table every root signature sees (0 = none: D3d12Options::bindlessDescriptors was 0, or
    // the GPU has resource binding tier 1).
    std::uint32_t bindless_descriptors() const { return bindlessDescriptors_; }
    // The GPU's resource binding tier (1, 2 or 3).
    int resource_binding_tier() const { return bindingTier_; }
    // Ticks per second of the direct queue's timestamps (0 when it cannot time).
    std::uint64_t timestamp_frequency() const { return timestampFrequency_; }
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
    // Writes the pipeline library to D3d12Options::pipelineCacheFile when it holds PSOs the file does not (atomically:
    // a temporary file, then a rename). Ok with nothing to do (no file set, no library, nothing new). A failure
    // (a reader holds the file on Windows, a full disk) keeps the old file and also goes to warnings().
    Result<void> save_pipeline_cache();
    // The cache file this device loads and writes (empty = none).
    const std::filesystem::path& pipeline_cache_file() const { return pipelineCacheFile_; }
    // Tests: the timer slots a timed frame holds (open, or ended and waiting for its fence).
    int timer_slots_busy() const;
    // Tests: the next timed frame to end is dropped, as when its resolve cannot be submitted (a failed Close).
    void drop_next_timed_frame();
    // Tests: the timer slot the open timed frame holds (-1 = none open).
    int timer_current_slot() const;
    // Ticks per second of the compute queue's timestamps (0: no compute queue, or it cannot time; its lists' timed
    // scopes are then not measured).
    std::uint64_t compute_timestamp_frequency() const { return side_[0].timestampFrequency; }

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
        std::uint32_t bindless = kNoBindlessIndex;    // a Texture view's slot in the bindless table
    };
    struct SamplerRecord {
        std::uint32_t descriptor = kNoDescriptor;  // kNoDescriptor when the creation failed
        D3D12_SAMPLER_DESC desc{};
    };
    struct ShaderRecord {
        std::shared_ptr<const ShaderInfo> info;  // null when the creation failed
        std::shared_ptr<const RootLayout> layout;
    };
    struct PipelineRecord {
        std::shared_ptr<const PipelineState> state;  // null when the creation failed
    };
    // Something destroyed while the GPU may still use it: released once `frame` was committed and the GPU finished it.
    struct Deferred {
        std::uint64_t frame = 0;
        std::shared_ptr<TrackedResource> tracked;
        Com<ID3D12Resource> raw;
        int heap = -1;
        std::uint32_t descriptor = kNoDescriptor;
        std::uint32_t descriptor2 = kNoDescriptor;
        std::uint32_t bindless = kNoBindlessIndex;  // a bindless slot: a null descriptor again, then free
        // The resources a submitted list used: alive until the frame it was submitted in is finished, whatever is
        // destroyed meanwhile.
        std::vector<std::shared_ptr<TrackedResource>> held;
    };
    enum HeapIndex { kHeapView = 0, kHeapRtv = 1, kHeapDsv = 2, kHeapSampler = 3, kHeapCount = 4 };
    struct Listener {
        void (*func)(void*) = nullptr;
        void* user = nullptr;
    };

    Result<void> init(const D3d12Options& options);
    Result<void> init_adapter(const D3d12Options& options);
    void init_caps();
    // The compute and copy queues (init, D3d12Options::asyncQueues); none when D3D12 cannot make them (logged).
    void init_side_queues(bool wanted);
    // A free command list for `kind` (a mapped queue), open for recording, from the pool or new; null with errors()
    // when D3D12 failed. Under queueMutex_.
    D3d12CommandList* acquire_list(const char* label, bool internal, QueueKind kind = QueueKind::Graphics);
    // Closes `list`, executes its waits, its fix-up list and it on its queue, signals the queue's fence. Under
    // queueMutex_.
    void execute(D3d12CommandList& list);
    // Closes `list` without running it: its resources and upload buffers are released with the frame, its timed
    // scopes give their slot back. Under queueMutex_.
    void drop_list(D3d12CommandList& list);
    // A list's timed scopes once it is closed: their slots count it no longer as open; when it `ran`, its queue writes
    // them at its next signal and the scopes of the open timed frame are reported. Under queueMutex_ (takes
    // timerMutex_).
    void timer_list_done(D3d12CommandList& list, bool ran);
    // submit()'s checks of a list the caller recorded (open, debug groups, pass, frame, the owner queue of every
    // resource it uses, the handoffs it waits for); false (reported, the list dropped) when it must not run. Under
    // queueMutex_.
    bool check_submit(D3d12CommandList& list, const char* what);
    // The queue that runs `q`'s lists here: Compute without a compute queue is Graphics, Transfer without a copy queue
    // is Compute (or Graphics).
    QueueKind map_queue(QueueKind q) const;
    // A mapped queue's D3D12 queue, fence, last signalled value (queueMutex_) and completed value.
    ID3D12CommandQueue* queue_of(QueueKind q) const;
    ID3D12Fence* fence_of(QueueKind q) const;
    std::uint64_t& fence_value(QueueKind q);
    std::uint64_t completed_value(QueueKind q) const;
    // Signals `q`'s fence with its next value, which it returns (reported on failure). Under queueMutex_.
    std::uint64_t signal(QueueKind q, const char* what);
    // Whether `token` (mapped) names a value its queue has signalled: a token a submit_token of this device returned.
    // Under queueMutex_.
    bool token_issued(SyncToken token) const;
    // Makes queue `waiter` wait (on the GPU) for `token` (mapped, issued, of another queue) and remembers it. Under
    // queueMutex_.
    void queue_wait(QueueKind waiter, SyncToken token);
    // Bindless slots (bindlessMutex_): a slot that holds a copy of the CPU descriptor `src`, or kNoBindlessIndex when
    // the table is full or there is none; and a slot given back (a null descriptor first).
    std::uint32_t take_bindless(D3D12_CPU_DESCRIPTOR_HANDLE src);
    void free_bindless(std::uint32_t index);
    // The device's own list for initial uploads and readbacks, opened on first use. Under queueMutex_.
    D3d12CommandList& prelude();
    // Executes the prelude if it recorded anything. Under queueMutex_.
    void flush_prelude();
    // Waits (bounded) until the fence of queue `queue` (mapped) reaches `value`. Under queueMutex_: every wait shares
    // the one fence event, and two waiters at once would each take the other's signal.
    Result<void> wait_fence(std::uint64_t value, const char* what, QueueKind queue = QueueKind::Graphics);
    // Releases what the GPU is done with and gives the finished frames' ring room back. Under queueMutex_.
    void collect();
    void defer(Deferred d);
    // Gives a deferred entry's descriptors back (its resources go when it is destroyed). Under queueMutex_.
    void release(Deferred& d);
    // The root signature of a shader's slots, from the cache or new; null with `error` when the layout cannot be one.
    std::shared_ptr<const RootLayout> root_layout(const ShaderDesc& desc, const ShaderInfo& info, std::string& error);
    // The PSO of a desc (`key`, the canonical text of every field): from the in-memory cache, else loaded from the
    // pipeline library (the on-disk cache, named by a hash of `key`), else made and stored there. Null with `error`
    // when D3D12 refused it.
    Com<ID3D12PipelineState> pso(const std::string& key, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* graphics,
                                 const D3D12_COMPUTE_PIPELINE_STATE_DESC* compute, std::string& error);
    // The swapchain (d3d12_swapchain_win32.cpp). Adds an image record whose resource exists already (a back buffer);
    // takes resMutex_.
    Image adopt_image(ImageRecord rec);
    // Gets the swapchain's buffers and makes their images and views (and the MSAA and depth images); the error leaves
    // none made.
    Result<void> make_swap_buffers();
    // Destroys the buffers' images and views, waits for the GPU and drops every reference to the back buffers (what
    // ResizeBuffers and the swapchain's release need).
    void release_swap_buffers();
    // Fills `pass` (a PassDesc::for_swapchain pass) with the views of the acquired back buffer; the error otherwise.
    // Takes swapMutex_.
    std::string swapchain_pass(const PassDesc& pass, PassDesc& into) const;
    // The pipeline's state (under resMutex_); null when `pipeline` names nothing or failed.
    std::shared_ptr<const PipelineState> pipeline_state(Pipeline pipeline) const;
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
    // Where a texel region lands in a readback buffer: its footprint (GetCopyableFootprints: rows 256-byte aligned),
    // the tight bytes of one row and the buffer bytes it needs.
    struct TextureFootprint {
        D3D12_PLACED_SUBRESOURCE_FOOTPRINT placed{};
        std::uint32_t rows = 0;
        std::uint32_t rowBytes = 0;
        std::uint64_t total = 0;
    };
    // Checks that the region (x, y, width, height) of mip `mip`, layer `layer` can be read back, and its footprint.
    Result<TextureFootprint> texture_read_footprint(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer,
                                                    int x, int y, int width, int height, const char* what) const;
    // Records the copy of that region into `dst` at offset 0 (barriers included). Under queueMutex_.
    void record_texture_read(D3d12CommandList& list, const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer,
                             int x, int y, const TextureFootprint& fp, ID3D12Resource* dst);
    // Copies `region` of the image into a readback buffer and waits; `rowBytes` per row come back tightly packed.
    Result<void> read_texture(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y, int width,
                              int height, std::vector<std::uint8_t>& out, const char* what);
    // A READBACK-heap buffer of `bytes` bytes (COPY_DEST, the only state it has); null with errors() on failure.
    Com<ID3D12Resource> make_readback(std::uint64_t bytes, const char* what);
    // The timers' query heaps and readback buffers, and the queue's timestamp frequency (init; timerWhy_ when not).
    void init_timer();
    // timer_end_frame's work, under queueMutex_ and timerMutex_.
    void end_timer_frame_locked();
    // A free asynchronous read slot (its copy finished and no ticket names it), or -1.
    int free_async_slot() const;
    // An error naming D3D12's reason when the device was removed (no slot ever frees then); ok otherwise.
    Result<void> async_device_alive(const char* what) const;
    // Loads (or makes empty) the pipeline library from D3d12Options::pipelineCacheFile (init; no library when the file
    // is not set or the driver has none).
    void init_pipeline_library();
    // Whether `ticket` names the request its slot holds now.
    bool async_ticket_current(ReadTicket ticket) const;
    // Records the copy of an async read on an internal list, executes it, and hands the slot its ticket.
    Result<ReadTicket> start_async_read(int slot, const char* what, const std::function<void(D3d12CommandList&)>& copy);
    // Pack reads (d3d12_pack_reads_win32.cpp): the DirectStorage submissions whose graphics work finished go out and
    // finished reads are collected (poll_pack_read and commit() call it); the destructor's bounded wait for them.
    void pump_pack_reads();
    void shutdown_pack_reads();
    void pack_read_counters(D3d12Counters& c) const;
    Result<PackReadTicket> start_pack_read(PackRead& r, const char* what);
    void cpu_pack_read(PackRead& r);

    // The D3D12 objects
    Com<IDXGIFactory4> factory_;
    Com<IDXGIAdapter1> adapter_;
    Com<ID3D12Device> device_;
    Com<ID3D12InfoQueue> infoQueue_;
    Com<ID3D12CommandQueue> queue_;  // the direct queue (Graphics), with its fence
    Com<ID3D12Fence> fence_;
    // The compute queue ([0], Compute) and the copy queue ([1], Transfer), each with a fence of its own; null when not
    // made (map_queue then names the queue that runs their lists).
    struct SideQueue {
        Com<ID3D12CommandQueue> queue;
        Com<ID3D12Fence> fence;
        std::uint64_t value = 0;               // the last value signalled (queueMutex_)
        std::uint64_t timestampFrequency = 0;  // the compute queue's (0: its lists' timed scopes are not measured)
    };
    std::array<SideQueue, 2> side_;
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

    // The bytes ID3D12PipelineLibrary was created from (libraryMutex_). The library does not copy them and reads them
    // for its whole life, and so do the PSOs loaded from it: members die in reverse order, so this one, declared before
    // pipelines_, psos_ and library_, is freed after all of them.
    std::vector<std::uint8_t> libraryBlob_;

    // Resources (resMutex_)
    mutable std::mutex resMutex_;
    Pool<BufferRecord> buffers_;
    Pool<ImageRecord> images_;
    Pool<ViewRecord> views_;
    Pool<SamplerRecord> samplers_;
    Pool<ShaderRecord> shaders_;
    Pool<PipelineRecord> pipelines_;
    std::array<CpuDescriptorHeap, kHeapCount> cpuHeaps_;

    // The root signature and PSO caches (cacheMutex_; never held with another lock but the message one)
    mutable std::mutex cacheMutex_;
    std::unordered_map<std::string, std::shared_ptr<const RootLayout>> rootLayouts_;
    std::unordered_map<std::string, Com<ID3D12PipelineState>> psos_;
    std::uint64_t psoHits_ = 0, psoMisses_ = 0, rootHits_ = 0;
    std::uint32_t bindlessDescriptors_ = 0;  // the reserved range of viewHeap_ (0 = no bindless table; set by init)
    int bindingTier_ = 0;                    // D3D12_OPTIONS.ResourceBindingTier (1, 2 or 3)
    D3D_FEATURE_LEVEL featureLevel_ = D3D_FEATURE_LEVEL_11_0;  // the device's
    bool typedUavLoadAdditional_ = false;                      // D3D12_OPTIONS.TypedUAVLoadAdditionalFormats

    // The on-disk PSO cache (libraryMutex_; never held with another lock but the message one). libraryBlob_, the
    // bytes the library was made from, is declared above the pools so it outlives library_ and every PSO loaded
    // from it.
    mutable std::mutex libraryMutex_;
    Com<ID3D12PipelineLibrary> library_;
    bool libraryDirty_ = false;  // holds PSOs the file does not
    std::filesystem::path pipelineCacheFile_;
    std::uint64_t libraryHits_ = 0, libraryMisses_ = 0, cacheStored_ = 0, cacheDiscarded_ = 0;
    // What the file's header must match (the LUID changes with every boot: recorded, not compared).
    struct AdapterIdentity {
        std::uint32_t vendor = 0, device = 0, subsys = 0, revision = 0;
        std::uint64_t driverVersion = 0;
        std::uint32_t luidLow = 0;
        std::int32_t luidHigh = 0;
    };
    AdapterIdentity identity_{};

    // GPU timers (timerMutex_; taken after queueMutex_ when both are held). A timed frame takes the next slot of the
    // ring: query 0 is its start, 1 its end, 2 + 2i and 3 + 2i scope i's.
    static constexpr int kTimerSlots = 6;       // timed frames in flight; a full ring skips the frame
    static constexpr int kMaxTimedScopes = 64;  // scopes measured per frame (as GpuTimer::kMaxTimedPasses)
    // Queries of a slot's heap: the frame's start and end, then two per scope.
    static constexpr std::uint32_t kQueriesPerSlot = 2u + 2u * std::uint32_t(kMaxTimedScopes);
    struct TimerSlot {
        Com<ID3D12QueryHeap> heap;
        Com<ID3D12Resource> readback;  // the resolved ticks
        std::uint64_t serial = 0;      // the timed frame it holds
        std::uint64_t fence = 0;       // the fence value after its resolve
        std::vector<std::string> names;
        std::vector<bool> submitted;        // scope i's list ran before timer_end_frame (else it is not reported)
        std::vector<QueueKind> scopeQueue;  // the queue scope i's list ran on (its ticks are that queue's)
        // Held by a timed frame (open, or ended and waiting for its fence): timer_begin_frame takes a slot that is not.
        bool busy = false;
        // Lists still open that wrote a query of this slot: submitted later, they would write it again, so the slot
        // is not taken again before they are submitted or dropped, and each queue reached its last write (lastWrite).
        int openLists = 0;
        std::array<std::uint64_t, std::size_t(kQueueKinds)> lastWrite{};
        std::uint64_t computeWait = 0;  // the compute fence value its frame's compute scopes end at (the resolve waits)
    };
    mutable std::mutex timerMutex_;
    bool timerOk_ = false;
    std::string timerWhy_;
    std::uint64_t timestampFrequency_ = 0;
    std::array<TimerSlot, kTimerSlots> timerSlots_;
    std::deque<int> timerPending_;  // ended frames waiting for their fence, oldest first
    int timerCurrent_ = -1;         // the slot of the open timed frame; -1 = none
    std::uint64_t timerSerial_ = 0;
    std::uint64_t timerNext_ = 0;
    std::size_t timerStale_ = 0;  // results still to arrive that timer_forget() dropped
    bool timerDropNext_ = false;  // drop_next_timed_frame()
    std::vector<ScopeTime> timerLastScopes_;

    // Asynchronous reads (render thread only; the copy itself under queueMutex_)
    static constexpr int kAsyncReads = 32;  // as SokolDevice: 8 rings of 4
    struct AsyncRead {
        Com<ID3D12Resource> buffer;  // READBACK heap, kept while big enough
        std::uint64_t capacity = 0;
        std::uint64_t fence = 0;       // the copy is done once the fence reaches it
        std::uint32_t generation = 0;  // the ticket's; 0 = no ticket (free once the fence passed)
        std::size_t bytes = 0;         // a buffer read's bytes
        std::uint32_t rows = 0;        // a texture read: rows of rowBytes, rowPitch apart (0 = a buffer read)
        std::uint32_t rowBytes = 0;
        std::uint32_t rowPitch = 0;
    };
    std::array<AsyncRead, kAsyncReads> asyncReads_;
    std::uint32_t readGeneration_ = 0;

    // Pack reads (render thread only; their lists under queueMutex_). Declared after device_ and the queue: it goes
    // before them (shutdown_pack_reads has waited for its reads already).
    std::shared_ptr<PackReads> packReads_;

    // The queue, the frames, the lists (queueMutex_)
    mutable std::mutex queueMutex_;
    std::vector<std::unique_ptr<D3d12CommandList>> lists_;
    D3d12CommandList* prelude_ = nullptr;
    std::uint64_t fenceValue_ = 0;
    std::uint64_t frame_ = 0;
    std::uint64_t completedFrames_ = 0;  // frames [0, completedFrames_) are finished on the GPU, on every queue
    // A committed frame: the value of each queue's fence its work ends at (Graphics: its commit's signal).
    struct FrameFence {
        std::uint64_t frame = 0;
        std::array<std::uint64_t, std::size_t(kQueueKinds)> values{};
    };
    std::deque<FrameFence> frameFences_;
    // waited_[a][b]: the highest value of queue b's fence that queue a waited for (wait_list, wait_queue, handoffs).
    std::array<std::array<std::uint64_t, std::size_t(kQueueKinds)>, std::size_t(kQueueKinds)> waited_{};
    std::deque<Deferred> deferred_;
    UploadRing ring_;
    std::atomic<std::uint64_t> dedicatedUploads_{0};
    std::atomic<std::uint64_t> barriers_{0};
    ShaderVisibleHeap viewHeap_;
    ShaderVisibleHeap samplerHeap_;
    std::vector<Listener> listeners_;
    // What begin_commands hands out when D3D12 gives no list: never opened, so it ignores every call (and holds no
    // state, so every thread can share it). Its queue() is always Graphics, whatever queue
    // begin_commands was asked for: a list that never runs has no queue.
    std::unique_ptr<D3d12CommandList> dead_;

    // The bindless table's free slots (bindlessMutex_, taken last): slots [0, bindlessNext_) were handed out once,
    // bindlessFree_ holds those given back.
    mutable std::mutex bindlessMutex_;
    std::uint32_t bindlessNext_ = 0;
    std::vector<std::uint32_t> bindlessFree_;

    // The window's swapchain (render thread only; what a pass reads, below, also under swapMutex_, a leaf lock taken
    // before no other).
    struct SwapBuffer {
        std::shared_ptr<TrackedResource> tracked;  // the back buffer (its resource is dropped before ResizeBuffers)
        Image image{};
        View view{};  // a ColorAttachment view, or a ResolveAttachment view when the swapchain is multisampled
    };
    Com<IDXGISwapChain3> swapchain_;
    HANDLE swapWaitable_ = nullptr;  // the frame-latency waitable object
    std::string swapLabel_;
    PixelFormat swapFormat_ = PixelFormat::None;  // the colour format (the back buffers' image records)
    DXGI_FORMAT swapBufferFormat_ = DXGI_FORMAT_UNKNOWN;
    DXGI_COLOR_SPACE_TYPE swapColorSpace_ = DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709;
    UINT swapCount_ = 0;
    UINT swapFlags_ = 0;  // the DXGI_SWAP_CHAIN_FLAGs it was made with (ResizeBuffers takes the same)
    bool swapTearing_ = false;
    bool swapVsync_ = true;
    std::uint64_t swapWaitTimeouts_ = 0;
    mutable std::mutex swapMutex_;
    std::vector<SwapBuffer> swapBuffers_;
    Image swapMsaa_{}, swapDepth_{};
    View swapMsaaView_{}, swapDepthView_{};
    int swapWidth_ = 0, swapHeight_ = 0, swapSamples_ = 1;
    PixelFormat swapDepthFormat_ = PixelFormat::None;
    bool swapAcquired_ = false;  // acquire_swapchain ran and present() has not yet
    UINT swapIndex_ = 0;         // the acquired back buffer

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
