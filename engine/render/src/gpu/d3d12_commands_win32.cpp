// The D3D12 backend's command lists: opening and reusing them, resource-state tracking and barriers, the transfers
// (write_buffer, write_image, the copies), debug groups, render and compute passes, pipelines, bindings, uniforms,
// viewports, scissors, draws and dispatches (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <utility>

#include "gpu/d3d12_device.h"

namespace fa::gpu::d3d12 {

namespace {

// The rest of a level from `at` when `size` is 0 (sokol's ImageExtent rule).
std::uint32_t extent_or_rest(int size, int at, std::uint32_t level) {
    if (size > 0) return std::uint32_t(size);
    return at < 0 || std::uint32_t(at) >= level ? 0u : level - std::uint32_t(at);
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Life
// ---------------------------------------------------------------------------------------------------------------------

Result<void> D3d12CommandList::create(const char* what, QueueKind kind) {
    ID3D12Device* dev = device_.device_.get();
    // A list made for another queue before: its fix-up list goes too (its type must be the queue's).
    list_.reset();
    allocator_.reset();
    fixup_.reset();
    fixupAllocator_.reset();
    kind_ = kind;
    // A value of the old queue's fence means nothing on the new one (submit_token compares it with this queue's).
    fence_ = 0;
    const D3D12_COMMAND_LIST_TYPE type = list_type(kind);
    HRESULT hr = dev->CreateCommandAllocator(type, __uuidof(ID3D12CommandAllocator), allocator_.put_void());
    if (FAILED(hr))
        return make_error(std::string("gpu d3d12: begin_commands('") + what + "', " + queue_name(kind) +
                              "): CreateCommandAllocator failed with " + hr_text(hr) + device_.removed_reason(),
                          "the GPU ran out of memory or the device was lost");
    hr = dev->CreateCommandList(0, type, allocator_.get(), nullptr, __uuidof(ID3D12GraphicsCommandList),
                                list_.put_void());
    if (FAILED(hr))
        return make_error(std::string("gpu d3d12: begin_commands('") + what + "', " + queue_name(kind) +
                              "): CreateCommandList failed with " + hr_text(hr) + device_.removed_reason(),
                          "the GPU ran out of memory or the device was lost");
    list_->Close();  // made open: closed here, so open() can always Reset it
    return {};
}

Result<void> D3d12CommandList::open(const char* label) {
    HRESULT hr = allocator_->Reset();
    if (SUCCEEDED(hr)) hr = list_->Reset(allocator_.get(), nullptr);
    if (FAILED(hr))
        return make_error(std::string("gpu d3d12: begin_commands('") + label +
                              "'): resetting a command list failed with " + hr_text(hr) + device_.removed_reason(),
                          "the device was lost; the debug layer (D3d12Options::debugLayer) says why");
    label_ = label;
    if (!label_.empty()) list_->SetName(widen(label).c_str());
    open_ = true;
    internal_ = false;
    empty_ = true;
    debugDepth_ = 0;
    uses_.clear();
    useIndex_.clear();
    pending_.clear();
    keep_.clear();
    scopes_.clear();
    scopeOpen_ = false;
    waits_.clear();
    // Every list that can bind sees the two shader-visible heaps (the bindings' tables and the bindless table point
    // into them); a copy list binds nothing and may not set them.
    if (kind_ != QueueKind::Transfer) {
        ID3D12DescriptorHeap* heaps[2] = {device_.viewHeap_.heap(), device_.samplerHeap_.heap()};
        list_->SetDescriptorHeaps(2, heaps);
    }
    passState_ = PassState::None;
    passFailed_ = false;
    passFormat_ = {};
    passColors_ = 0;
    passWidth_ = passHeight_ = 0;
    resolveSrc_.reset();
    resolveDst_.reset();
    reset_bind_state();
    passAttachments_.clear();
    return {};
}

// A call on a list that is not recording: report it (the dead list of a failed begin_commands() was reported then).
#define FA_D3D12_REQUIRE_OPEN(what)                                                                                    \
    do {                                                                                                               \
        if (!open_) {                                                                                                  \
            if (list_)                                                                                                 \
                device_.report(std::string("gpu d3d12: CommandList::") + what + " on list '" + label_ +                \
                               "', which was submitted (hint: take a new list with begin_commands() each frame)");     \
            return;                                                                                                    \
        }                                                                                                              \
    } while (false)

void D3d12CommandList::fail(const char* what, const std::string& error) {
    device_.report(std::string("gpu d3d12: CommandList::") + what + " in list '" + label_ + "': " + error);
}

void D3d12CommandList::reset_bind_state() {
    pipeline_.reset();
    rootSignature_ = nullptr;
    rootCompute_ = false;
    uniformsSet_ = 0;
    bindingsSet_ = false;
    drawsFailed_ = false;
    boundUavs_.clear();
    uavsWritten_ = false;
}

// A timed scope: a timestamp in the open timed frame's query heap at each end (d3d12_timers_win32.cpp resolves them).
// Outside a timed frame, past its kMaxTimedScopes scopes or on a device that cannot time, nothing is recorded; nor on
// a Transfer list (a copy queue's timestamps need a heap of another type) or a Compute list whose queue cannot time.
void D3d12CommandList::begin_timed_scope(const char* name) {
    FA_D3D12_REQUIRE_OPEN("begin_timed_scope");
    if (scopeOpen_) close_scope();  // scopes do not nest
    if (kind_ == QueueKind::Transfer) return;
    if (kind_ == QueueKind::Compute && device_.side_[0].timestampFrequency == 0) return;
    ScopeRef ref;
    {
        std::lock_guard<std::mutex> lock(device_.timerMutex_);
        if (!device_.timerOk_ || device_.timerCurrent_ < 0) return;
        D3d12Device::TimerSlot& slot = device_.timerSlots_[std::size_t(device_.timerCurrent_)];
        if (slot.names.size() >= std::size_t(D3d12Device::kMaxTimedScopes)) return;  // drawn, not measured
        ref.serial = slot.serial;
        ref.slot = device_.timerCurrent_;
        ref.scope = std::uint32_t(slot.names.size());
        ref.heap = slot.heap.get();
        slot.names.emplace_back(name ? name : "");
        slot.submitted.push_back(false);
        slot.scopeQueue.push_back(kind_);
        // This list now writes the slot's queries: the slot is not taken again until it was submitted or dropped.
        const bool holds =
            std::any_of(scopes_.begin(), scopes_.end(), [&](const ScopeRef& s) { return s.slot == ref.slot; });
        if (!holds) ++slot.openLists;
    }
    list_->EndQuery(ref.heap, D3D12_QUERY_TYPE_TIMESTAMP, 2 + 2 * ref.scope);
    empty_ = false;
    scopes_.push_back(ref);
    scopeOpen_ = true;
}

void D3d12CommandList::end_timed_scope() {
    FA_D3D12_REQUIRE_OPEN("end_timed_scope");
    if (scopeOpen_) close_scope();
}

void D3d12CommandList::close_scope() {
    scopeOpen_ = false;
    if (scopes_.empty() || !list_) return;
    const ScopeRef& ref = scopes_.back();
    {
        // A list kept open over kTimerSlots timed frames: the slot holds another frame now, whose queries this end
        // would overwrite. Stale: not recorded (execute does not report it either).
        std::lock_guard<std::mutex> lock(device_.timerMutex_);
        if (ref.slot < 0 || device_.timerSlots_[std::size_t(ref.slot)].serial != ref.serial) return;
    }
    list_->EndQuery(ref.heap, D3D12_QUERY_TYPE_TIMESTAMP, 3 + 2 * ref.scope);
}

namespace {

const char* view_type_name(ViewType t) {
    switch (t) {
        case ViewType::StorageBuffer: return "storage buffer";
        case ViewType::StorageImage: return "storage image";
        case ViewType::Texture: return "texture";
        case ViewType::ColorAttachment: return "colour attachment";
        case ViewType::ResolveAttachment: return "resolve attachment";
        case ViewType::DepthStencilAttachment: return "depth-stencil attachment";
        default: return "invalid";
    }
}

std::string target_format_text(const TargetFormat& f) {
    std::string s = std::string("colour ") + pixel_format_name(f.color);
    if (f.color1 != PixelFormat::None) s += std::string(", colour1 ") + pixel_format_name(f.color1);
    return s + ", depth " + pixel_format_name(f.depth) + ", " + std::to_string(f.samples) + " sample(s)";
}

bool clears(LoadAction a) { return a == LoadAction::Clear || a == LoadAction::Default; }

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Passes
// ---------------------------------------------------------------------------------------------------------------------

void D3d12CommandList::begin_pass(const PassDesc& pass) {
    FA_D3D12_REQUIRE_OPEN("begin_pass");
    if (passState_ != PassState::None) {
        fail("begin_pass", "a pass is open already (hint: end_pass() first; passes do not nest)");
        return;
    }
    // From here on the pass is open, even when it fails (end_pass then closes it and its commands are skipped).
    passState_ = PassState::Render;
    passFailed_ = true;
    passFormat_ = pass.format;
    passColors_ = 0;
    passWidth_ = passHeight_ = 0;
    resolveSrc_.reset();
    resolveDst_.reset();
    passAttachments_.clear();
    reset_bind_state();
    const std::string passName = std::string("pass '") + (pass.label && *pass.label ? pass.label : "(no label)") + "'";
    if (kind_ != QueueKind::Graphics) {
        fail("begin_pass",
             passName + ": a " + queue_name(kind_) +
                 " list records no render pass (hint: draw in a list of begin_commands(label) or "
                 "begin_commands(label, QueueKind::Graphics); hand the resources over with QueueHandoff)");
        return;
    }
    if (pass.swapchain) {
        fail("begin_pass", passName + ": a pass into the window (PassDesc::swapchain) on the D3D12 backend, which has "
                                      "no window path yet (hint: draw into images here, RendererDesc::headless; pick "
                                      "the sokol backend, GpuBackend::Default, to draw into a window)");
        return;
    }

    struct Attachment {
        std::shared_ptr<TrackedResource> t;
        D3D12_CPU_DESCRIPTOR_HANDLE handle{};
        PixelFormat format = PixelFormat::None;
        int samples = 1;
        std::uint32_t width = 0, height = 0;
        std::uint32_t mip = 0, layer = 0;  // layer 0 for a 3D image (its slice is a depth slice)
        bool bound = false;
    };
    Attachment color, color1, resolve, depth;
    std::string error;
    // Held until the clears read the attachments' CPU descriptors: a view destroyed on the render thread meanwhile may
    // have its descriptor freed at once (wait_idle), and the make_* call that takes it again writes it under this lock,
    // never while this list reads it.
    std::unique_lock<std::mutex> lock(device_.resMutex_);
    {
        auto look = [&](View v, ViewType type, const char* what, Attachment& a) {
            if (!error.empty() || v.id == 0) return;
            const D3d12Device::ViewRecord* r = device_.views_.get(v.id);
            const D3d12Device::ImageRecord* im = r ? device_.images_.get(r->image.id) : nullptr;
            if (!r || !r->tracked || !im || !im->tracked) {
                error = std::string(what) + " (view " + std::to_string(v.id) +
                        ") is not a live view of a live image (hint: views die with destroy_view, and a view whose "
                        "image was destroyed cannot be drawn into)";
                return;
            }
            if (r->type != type) {
                error = std::string(what) + " is a " + view_type_name(r->type) +
                        " view (hint: make it with ViewDesc::" +
                        (type == ViewType::ColorAttachment     ? "colorAttachment"
                         : type == ViewType::ResolveAttachment ? "resolveAttachment"
                                                               : "depthStencilAttachment") +
                        ")";
                return;
            }
            a.t = r->tracked;
            if (r->heap >= 0 && r->descriptor != kNoDescriptor)
                a.handle = device_.cpuHeaps_[std::size_t(r->heap)].cpu(r->descriptor);
            a.format = im->format;
            a.samples = im->samples;
            a.width = mip_extent(im->width, r->mip);
            a.height = mip_extent(im->height, r->mip);
            a.mip = std::uint32_t(r->mip);
            a.layer = im->type == ImageType::Tex3d ? 0u : std::uint32_t(r->slice);
            a.bound = true;
        };
        look(pass.color, ViewType::ColorAttachment, "the colour attachment (PassDesc::color)", color);
        look(pass.color1, ViewType::ColorAttachment, "colour attachment 1 (PassDesc::color1)", color1);
        look(pass.resolve, ViewType::ResolveAttachment, "the resolve attachment (PassDesc::resolve)", resolve);
        look(pass.depth, ViewType::DepthStencilAttachment, "the depth attachment (PassDesc::depth)", depth);
    }
    if (error.empty() && !color.bound && !depth.bound)
        error = "it has no attachment (hint: set PassDesc::color or PassDesc::depth to a view)";
    if (error.empty() && color1.bound && !color.bound)
        error = "it has colour attachment 1 without colour attachment 0 (hint: PassDesc::color first)";
    if (error.empty() && resolve.bound && !color.bound)
        error = "it resolves (PassDesc::resolve) without a colour attachment to resolve";
    const Attachment& first = color.bound ? color : depth;
    if (error.empty()) {
        for (const Attachment* a : {&color1, &resolve, &depth})
            if (a->bound && (a->width != first.width || a->height != first.height))
                error = "its attachments differ in size (" + std::to_string(first.width) + "x" +
                        std::to_string(first.height) + " and " + std::to_string(a->width) + "x" +
                        std::to_string(a->height) + ") (hint: every attachment of a pass has the same size)";
    }
    if (error.empty() && resolve.bound && (color.samples < 2 || resolve.format != color.format))
        error = std::string("it resolves a colour attachment that ") +
                (color.samples < 2 ? "is not multisampled" : "has another format than the resolve attachment") +
                " (hint: a resolve takes a multisampled colour attachment into a single-sampled image of its format)";
    TargetFormat expected;
    expected.color = color.bound ? color.format : PixelFormat::None;
    expected.color1 = color1.bound ? color1.format : PixelFormat::None;
    expected.depth = depth.bound ? depth.format : PixelFormat::None;
    expected.samples = first.samples;
    if (error.empty() && pass.format != expected)
        error = "PassDesc::format (" + target_format_text(pass.format) + ") is not what its attachments are (" +
                target_format_text(expected) +
                ") (hint: set format to the attachments' formats and sample count; the pipelines drawn in it must "
                "match it)";
    if (error.empty() && color1.bound && color1.samples != color.samples)
        error = "its colour attachments differ in sample count";
    if (error.empty() && depth.bound && color.bound && depth.samples != color.samples)
        error = "its depth attachment has " + std::to_string(depth.samples) + " sample(s), its colour attachment " +
                std::to_string(color.samples);
    if (!error.empty()) {
        lock.unlock();
        fail("begin_pass", passName + ": " + error);
        return;
    }

    // The attachments' states, then the targets and the clears.
    D3D12_CPU_DESCRIPTOR_HANDLE rtvs[2]{};
    UINT rtvCount = 0;
    for (const Attachment* a : {&color, &color1}) {
        if (!a->bound) continue;
        require(a->t, a->t->subresource(a->mip, a->layer, 0), D3D12_RESOURCE_STATE_RENDER_TARGET);
        rtvs[rtvCount++] = a->handle;
    }
    const bool stencil = depth.bound && format_info(depth.format).planes > 1;
    if (depth.bound)
        for (std::uint32_t p = 0; p < depth.t->planes; ++p)
            require(depth.t, depth.t->subresource(depth.mip, depth.layer, p), D3D12_RESOURCE_STATE_DEPTH_WRITE);
    flush_barriers();
    list_->OMSetRenderTargets(rtvCount, rtvCount ? rtvs : nullptr, FALSE, depth.bound ? &depth.handle : nullptr);
    if (color.bound && clears(pass.colorLoad)) {
        const float c[4] = {pass.clearColor.r, pass.clearColor.g, pass.clearColor.b, pass.clearColor.a};
        list_->ClearRenderTargetView(color.handle, c, 0, nullptr);
    }
    if (color1.bound && clears(pass.colorLoad)) {
        const float c[4] = {pass.clearColor1.r, pass.clearColor1.g, pass.clearColor1.b, pass.clearColor1.a};
        list_->ClearRenderTargetView(color1.handle, c, 0, nullptr);
    }
    if (depth.bound) {
        D3D12_CLEAR_FLAGS flags = D3D12_CLEAR_FLAGS(0);
        if (clears(pass.depthLoad)) flags |= D3D12_CLEAR_FLAG_DEPTH;
        if (stencil && clears(pass.stencilLoad)) flags |= D3D12_CLEAR_FLAG_STENCIL;
        const float clearDepth = std::isfinite(pass.clearDepth) ? std::clamp(pass.clearDepth, 0.0f, 1.0f) : 1.0f;
        if (flags) list_->ClearDepthStencilView(depth.handle, flags, clearDepth, 0, 0, nullptr);
    }
    lock.unlock();
    passWidth_ = first.width;
    passHeight_ = first.height;
    passColors_ = int(rtvCount);
    const D3D12_VIEWPORT vp{0.0f, 0.0f, float(passWidth_), float(passHeight_), 0.0f, 1.0f};
    list_->RSSetViewports(1, &vp);
    const D3D12_RECT all{0, 0, LONG(passWidth_), LONG(passHeight_)};
    list_->RSSetScissorRects(1, &all);
    if (resolve.bound) {
        resolveSrc_ = color.t;
        resolveDst_ = resolve.t;
        resolveSrcSub_ = color.t->subresource(color.mip, color.layer, 0);
        resolveDstSub_ = resolve.t->subresource(resolve.mip, resolve.layer, 0);
        resolveFormat_ = format_info(color.format).rtv;
    }
    if (color.bound)
        passAttachments_.push_back({color.t, color.mip, color.layer, "colour attachment (PassDesc::color)"});
    if (color1.bound)
        passAttachments_.push_back({color1.t, color1.mip, color1.layer, "colour attachment 1 (PassDesc::color1)"});
    if (depth.bound)
        passAttachments_.push_back({depth.t, depth.mip, depth.layer, "depth attachment (PassDesc::depth)"});
    passFailed_ = false;
    empty_ = false;
}

void D3d12CommandList::begin_compute_pass(const char* label) {
    FA_D3D12_REQUIRE_OPEN("begin_compute_pass");
    if (passState_ != PassState::None) {
        fail("begin_compute_pass", std::string("compute pass '") + (label ? label : "") +
                                       "': a pass is open already (hint: end_pass() first; passes do not nest)");
        return;
    }
    passState_ = PassState::Compute;
    passFailed_ = false;
    reset_bind_state();
    if (kind_ == QueueKind::Transfer) {
        // Open (end_pass matches it) but failed: its commands are skipped.
        passFailed_ = true;
        fail("begin_compute_pass", std::string("compute pass '") + (label ? label : "") +
                                       "': a Transfer list records copies and writes only (hint: dispatch in a list of "
                                       "begin_commands(label, QueueKind::Compute) or a Graphics one)");
    }
}

void D3d12CommandList::end_pass() {
    FA_D3D12_REQUIRE_OPEN("end_pass");
    if (passState_ == PassState::None) {
        fail("end_pass", "no pass is open (hint: one end_pass() per begin_pass() or begin_compute_pass())");
        return;
    }
    if (passState_ == PassState::Render && !passFailed_ && resolveSrc_ && resolveDst_) {
        require(resolveSrc_, resolveSrcSub_, D3D12_RESOURCE_STATE_RESOLVE_SOURCE);
        require(resolveDst_, resolveDstSub_, D3D12_RESOURCE_STATE_RESOLVE_DEST);
        flush_barriers();
        list_->ResolveSubresource(resolveDst_->resource.get(), resolveDstSub_, resolveSrc_->resource.get(),
                                  resolveSrcSub_, resolveFormat_);
        empty_ = false;
    }
    passState_ = PassState::None;
    passFailed_ = false;
    passFormat_ = {};
    passColors_ = 0;
    passWidth_ = passHeight_ = 0;
    resolveSrc_.reset();
    resolveDst_.reset();
    reset_bind_state();
    passAttachments_.clear();
}

// ---------------------------------------------------------------------------------------------------------------------
// Pipelines, bindings, uniforms
// ---------------------------------------------------------------------------------------------------------------------

void D3d12CommandList::set_pipeline(Pipeline pipeline) {
    FA_D3D12_REQUIRE_OPEN("set_pipeline");
    if (passState_ == PassState::None) {
        fail("set_pipeline", "outside a pass (hint: begin_pass() or begin_compute_pass() first)");
        return;
    }
    ID3D12RootSignature* const previousRoot = rootSignature_;
    const bool previousCompute = rootCompute_;
    reset_bind_state();
    if (passFailed_) return;
    std::shared_ptr<const PipelineState> st = device_.pipeline_state(pipeline);
    std::string error;
    if (!st)
        error = "pipeline " + std::to_string(pipeline.id) +
                " is not a live pipeline, or its creation failed (make_pipeline reported why in errors())";
    else if (st->compute != (passState_ == PassState::Compute))
        error = "pipeline '" + st->label + "' is a " + (st->compute ? "compute" : "render") + " pipeline inside a " +
                (passState_ == PassState::Compute ? "compute" : "render") +
                " pass (hint: compute pipelines go in begin_compute_pass(), render pipelines in begin_pass())";
    else if (!st->compute && (st->format != passFormat_ || st->colorCount != passColors_))
        error = "pipeline '" + st->label + "' draws into " + target_format_text(st->format) + " with " +
                std::to_string(st->colorCount) + " colour target(s), the pass has " + target_format_text(passFormat_) +
                " with " + std::to_string(passColors_) +
                " (hint: a pipeline's colour targets, depth format and sampleCount must equal its pass's)";
    if (!error.empty()) {
        drawsFailed_ = true;
        fail("set_pipeline", error);
        return;
    }
    ID3D12RootSignature* root = st->layout->signature.get();
    // Restore what reset_bind_state forgot: the list keeps its root signature across set_pipeline calls.
    rootSignature_ = previousRoot;
    rootCompute_ = previousCompute;
    if (root != rootSignature_ || rootCompute_ != st->compute) {
        if (st->compute)
            list_->SetComputeRootSignature(root);
        else
            list_->SetGraphicsRootSignature(root);
        rootSignature_ = root;
        rootCompute_ = st->compute;
    }
    list_->SetPipelineState(st->pso.get());
    if (st->layout->bindlessTable >= 0) {
        const D3D12_GPU_DESCRIPTOR_HANDLE bindless = device_.viewHeap_.reserved().gpu;
        if (st->compute)
            list_->SetComputeRootDescriptorTable(UINT(st->layout->bindlessTable), bindless);
        else
            list_->SetGraphicsRootDescriptorTable(UINT(st->layout->bindlessTable), bindless);
    }
    if (!st->compute) {
        list_->IASetPrimitiveTopology(st->topology);
        list_->OMSetBlendFactor(st->blendColor);
        list_->OMSetStencilRef(st->stencilRef);
    }
    pipeline_ = std::move(st);
    empty_ = false;
}

void D3d12CommandList::uav_barrier_if_written(const std::shared_ptr<TrackedResource>& t) {
    auto it = useIndex_.find(t.get());
    if (it == useIndex_.end()) return;
    const Use& u = uses_[it->second];
    for (StateBits s : u.current)
        if (s == StateBits(D3D12_RESOURCE_STATE_UNORDERED_ACCESS)) {
            D3D12_RESOURCE_BARRIER b{};
            b.Type = D3D12_RESOURCE_BARRIER_TYPE_UAV;
            b.UAV.pResource = t->resource.get();
            pending_.push_back(b);
            return;
        }
}

void D3d12CommandList::set_bindings(const Bindings& b) {
    FA_D3D12_REQUIRE_OPEN("set_bindings");
    if (passFailed_ || drawsFailed_) return;
    if (!pipeline_) {
        fail("set_bindings", "no pipeline is set (hint: set_pipeline() first, inside a pass)");
        return;
    }
    const PipelineState& st = *pipeline_;
    const ShaderInfo& sh = *st.shader;
    const RootLayout& lay = *st.layout;
    struct BoundBuffer {
        std::shared_ptr<TrackedResource> t;
        std::uint64_t offset = 0, size = 0;
    };
    struct BoundView {
        std::shared_ptr<TrackedResource> t;
        D3D12_CPU_DESCRIPTOR_HANDLE src{};
        ViewType type = ViewType::Invalid;
        std::uint32_t mip = 0, mipCount = 1, slice = 0, sliceCount = 1;
        bool writable = false;
    };
    BoundBuffer vbs[kMaxVertexBuffers];
    BoundBuffer ib;
    BoundView views[kMaxViews];
    D3D12_CPU_DESCRIPTOR_HANDLE samplers[kMaxSamplers]{};
    std::string error;
    auto bad = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    const std::string shaderName = "shader '" + sh.label + "'";
    // Held until the CPU descriptors are copied into the shader-visible heap: a view or sampler destroyed on the
    // render thread meanwhile may have its descriptor freed at once (wait_idle), and the make_* call that takes it
    // again writes it under this lock, never while this list copies it.
    std::unique_lock<std::mutex> lock(device_.resMutex_);
    {
        auto buffer = [&](Buffer buf, int offset, bool wanted, bool usageOk, const char* what, const char* usage,
                          BoundBuffer& out) {
            if (!wanted) {
                if (buf.id != 0)
                    bad(std::string(what) + " is bound and pipeline '" + st.label +
                        "' reads nothing there (hint: bind only the slots its vertex layout or index type uses)");
                return;
            }
            const D3d12Device::BufferRecord* r = device_.buffers_.get(buf.id);
            if (buf.id == 0) {
                bad(std::string(what) + " is empty and pipeline '" + st.label + "' reads it");
            } else if (!r || !r->tracked) {
                bad(std::string(what) + " (buffer " + std::to_string(buf.id) + ") is not a live buffer");
            } else if (!usageOk) {
                bad(std::string(what) + " is buffer '" + r->label + "', which was not made with BufferUsage::" + usage);
            } else if (offset < 0 || std::size_t(offset) >= r->size) {
                bad(std::string(what) + "'s offset " + std::to_string(offset) + " is outside buffer '" + r->label +
                    "''s " + std::to_string(r->size) + " bytes");
            } else {
                out.t = r->tracked;
                out.offset = std::uint64_t(offset);
                out.size = r->size;
            }
        };
        for (int i = 0; i < kMaxVertexBuffers; ++i) {
            const D3d12Device::BufferRecord* r = device_.buffers_.get(b.vertexBuffers[i].id);
            const std::string what = "vertex buffer slot " + std::to_string(i);
            buffer(b.vertexBuffers[i], b.vertexBufferOffsets[i], (st.buffersUsed >> i) & 1u, r && r->usage.vertexBuffer,
                   what.c_str(), "vertexBuffer", vbs[i]);
        }
        {
            const D3d12Device::BufferRecord* r = device_.buffers_.get(b.indexBuffer.id);
            buffer(b.indexBuffer, b.indexBufferOffset, st.indexType != IndexType::None, r && r->usage.indexBuffer,
                   "the index buffer", "indexBuffer", ib);
        }
        for (int i = 0; i < kMaxViews && error.empty(); ++i) {
            const ViewType want = sh.viewType[i];
            const View v = b.views[i];
            const std::string what = "view slot " + std::to_string(i);
            if (want == ViewType::Invalid) {
                if (v.id != 0) bad(what + " is bound and " + shaderName + " declares nothing there");
                continue;
            }
            const D3d12Device::ViewRecord* r = device_.views_.get(v.id);
            if (v.id == 0) {
                bad(what + " is empty and " + shaderName + " declares a " + view_type_name(want) + " there");
            } else if (!r || !r->tracked || r->heap < 0) {
                bad(what + " (view " + std::to_string(v.id) + ") is not a live view");
            } else if (r->type != want) {
                bad(what + " is a " + view_type_name(r->type) + " view and " + shaderName + " declares a " +
                    view_type_name(want) + " there");
            } else {
                BoundView& out = views[i];
                out.t = r->tracked;
                out.type = r->type;
                out.writable = sh.viewWritable[i];
                const std::uint32_t d =
                    out.writable && r->type == ViewType::StorageBuffer ? r->uavDescriptor : r->descriptor;
                out.src = device_.cpuHeaps_[std::size_t(r->heap)].cpu(d);
                out.mip = std::uint32_t(r->mip);
                out.mipCount = std::uint32_t(r->mipCount);
                out.slice = std::uint32_t(r->slice);
                out.sliceCount = std::uint32_t(r->sliceCount);
                // An attachment of the open pass is written by its draws: it cannot be read (or written) through a view
                // too (D3D12 would need it in two states at once; the debug layer calls the draw invalid).
                for (const PassAttachment& a : passAttachments_) {
                    if (a.tracked != out.t || a.mip < out.mip || a.mip - out.mip >= out.mipCount) continue;
                    if (out.t->layers > 1 && (a.layer < out.slice || a.layer - out.slice >= out.sliceCount)) continue;
                    bad(what + " (" + view_type_name(r->type) + " view " + std::to_string(v.id) + ") reads mip " +
                        std::to_string(a.mip) + (out.t->layers > 1 ? ", layer " + std::to_string(a.layer) : "") +
                        " of an image the pass draws into as its " + a.role +
                        " (hint: end_pass() before reading what a pass drew, or draw into another image; a view of "
                        "other "
                        "mips or layers of the same image may be bound)");
                    break;
                }
            }
        }
        for (int i = 0; i < kMaxSamplers && error.empty(); ++i) {
            const bool wanted = (lay.samplerUsed >> i) & 1u;
            const Sampler s = b.samplers[i];
            const std::string what = "sampler slot " + std::to_string(i);
            if (!wanted) {
                if (s.id != 0) bad(what + " is bound and " + shaderName + " declares nothing there");
                continue;
            }
            const D3d12Device::SamplerRecord* r = device_.samplers_.get(s.id);
            if (s.id == 0)
                bad(what + " is empty and " + shaderName + " declares a sampler there");
            else if (!r || r->descriptor == kNoDescriptor)
                bad(what + " (sampler " + std::to_string(s.id) + ") is not a live sampler");
            else
                samplers[i] = device_.cpuHeaps_[D3d12Device::kHeapSampler].cpu(r->descriptor);
        }
    }
    if (!error.empty()) {
        lock.unlock();
        drawsFailed_ = true;
        fail("set_bindings", error);
        return;
    }

    // The descriptors: copied into this frame's part of the shader-visible heaps, one table per stage.
    ID3D12Device* dev = device_.device_.get();
    ShaderVisibleHeap::Span viewSpan[2], samplerSpan[2];
    for (std::size_t s = 0; s < 2; ++s) {
        if (lay.viewCount[s] > 0) {
            viewSpan[s] = device_.viewHeap_.alloc(lay.viewCount[s]);
            if (!viewSpan[s].ok()) {
                lock.unlock();
                drawsFailed_ = true;
                fail("set_bindings",
                     "this frame used up its " + std::to_string(device_.viewHeap_.per_frame()) +
                         " shader-visible view descriptors (hint: raise D3d12Options::frameViewDescriptors)");
                return;
            }
        }
        if (lay.samplerCount[s] > 0) {
            samplerSpan[s] = device_.samplerHeap_.alloc(lay.samplerCount[s]);
            if (!samplerSpan[s].ok()) {
                lock.unlock();
                drawsFailed_ = true;
                fail("set_bindings",
                     "this frame used up its " + std::to_string(device_.samplerHeap_.per_frame()) +
                         " shader-visible sampler descriptors (hint: raise D3d12Options::frameSamplerDescriptors; "
                         "D3D12 allows 2048 in all)");
                return;
            }
        }
    }
    const std::uint32_t viewInc = device_.viewHeap_.increment(), samplerInc = device_.samplerHeap_.increment();
    boundUavs_.clear();
    uavsWritten_ = false;
    for (int i = 0; i < kMaxViews; ++i) {
        const BoundView& v = views[i];
        if (!v.t) continue;
        D3D12_CPU_DESCRIPTOR_HANDLE dst = viewSpan[lay.viewStage[i]].cpu;
        dst.ptr += std::size_t(lay.viewOffset[i]) * viewInc;
        dev->CopyDescriptorsSimple(1, dst, v.src, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
        const bool flat = v.t->layers == 1;  // a 3D image or a buffer: one layer
        const std::uint32_t layer = flat ? 0u : v.slice, layers = flat ? 1u : v.sliceCount;
        if (v.writable) {
            uav_barrier_if_written(v.t);
            if (v.type == ViewType::StorageBuffer)
                require(v.t, 0, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
            else
                require_range(v.t, v.mip, 1, layer, layers, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
            if (std::find(boundUavs_.begin(), boundUavs_.end(), v.t) == boundUavs_.end()) boundUavs_.push_back(v.t);
        } else {
            // A compute list's queue has no pixel shader state (a COMPUTE list may not use it).
            const auto read = kind_ == QueueKind::Graphics
                                  ? D3D12_RESOURCE_STATES(D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE |
                                                          D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE)
                                  : D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
            if (v.type == ViewType::StorageBuffer)
                require(v.t, 0, read);
            else
                require_range(v.t, v.mip, v.mipCount, layer, layers, read);
        }
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        if (!samplers[i].ptr) continue;
        D3D12_CPU_DESCRIPTOR_HANDLE dst = samplerSpan[lay.samplerStage[i]].cpu;
        dst.ptr += std::size_t(lay.samplerOffset[i]) * samplerInc;
        dev->CopyDescriptorsSimple(1, dst, samplers[i], D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
    }
    lock.unlock();
    for (std::size_t s = 0; s < 2; ++s) {
        if (lay.viewTable[s] >= 0) {
            if (st.compute)
                list_->SetComputeRootDescriptorTable(UINT(lay.viewTable[s]), viewSpan[s].gpu);
            else
                list_->SetGraphicsRootDescriptorTable(UINT(lay.viewTable[s]), viewSpan[s].gpu);
        }
        if (lay.samplerTable[s] >= 0) {
            if (st.compute)
                list_->SetComputeRootDescriptorTable(UINT(lay.samplerTable[s]), samplerSpan[s].gpu);
            else
                list_->SetGraphicsRootDescriptorTable(UINT(lay.samplerTable[s]), samplerSpan[s].gpu);
        }
    }

    // The vertex and index buffers.
    for (int i = 0; i < kMaxVertexBuffers; ++i) {
        const BoundBuffer& v = vbs[i];
        if (!v.t) continue;
        require(v.t, 0, D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER);
        D3D12_VERTEX_BUFFER_VIEW vbv{};
        vbv.BufferLocation = v.t->resource->GetGPUVirtualAddress() + v.offset;
        vbv.SizeInBytes = UINT(std::min<std::uint64_t>(v.size - v.offset, 0xFFFFFFFFu));
        vbv.StrideInBytes = st.strides[i];
        list_->IASetVertexBuffers(UINT(i), 1, &vbv);
    }
    if (ib.t) {
        require(ib.t, 0, D3D12_RESOURCE_STATE_INDEX_BUFFER);
        D3D12_INDEX_BUFFER_VIEW ibv{};
        ibv.BufferLocation = ib.t->resource->GetGPUVirtualAddress() + ib.offset;
        ibv.SizeInBytes = UINT(std::min<std::uint64_t>(ib.size - ib.offset, 0xFFFFFFFFu));
        ibv.Format = st.indexType == IndexType::Uint16 ? DXGI_FORMAT_R16_UINT : DXGI_FORMAT_R32_UINT;
        list_->IASetIndexBuffer(&ibv);
    }
    bindingsSet_ = true;
    empty_ = false;
}

void D3d12CommandList::set_uniforms(int slot, Range data) {
    FA_D3D12_REQUIRE_OPEN("set_uniforms");
    if (passFailed_ || drawsFailed_) return;
    if (!pipeline_) {
        fail("set_uniforms", "no pipeline is set (hint: set_pipeline() first, inside a pass)");
        return;
    }
    const ShaderInfo& sh = *pipeline_->shader;
    const std::uint32_t size = slot >= 0 && slot < kMaxUniformBlocks ? sh.uniformSize[slot] : 0;
    std::string error;
    if (size == 0)
        error = "uniform block slot " + std::to_string(slot) + " is not one shader '" + sh.label + "' declares";
    else if (!data.ptr || data.size != size)
        error = "uniform block slot " + std::to_string(slot) + " of shader '" + sh.label + "' has " +
                std::to_string(size) + " bytes and the data has " + std::to_string(data.ptr ? data.size : 0) +
                " (hint: pass exactly the block's size)";
    if (!error.empty()) {
        drawsFailed_ = true;
        fail("set_uniforms", error);
        return;
    }
    const UploadAlloc a = device_.upload(std::size_t(align_up(size, D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT)),
                                         D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT, this);
    if (!a.ok()) {
        drawsFailed_ = true;  // reported
        return;
    }
    std::memcpy(a.cpu, data.ptr, size);
    const UINT param = UINT(pipeline_->layout->cbvParam[slot]);
    if (pipeline_->compute)
        list_->SetComputeRootConstantBufferView(param, a.gpu);
    else
        list_->SetGraphicsRootConstantBufferView(param, a.gpu);
    uniformsSet_ |= 1u << slot;
    empty_ = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// Viewports, scissors, draws, dispatches
// ---------------------------------------------------------------------------------------------------------------------

void D3d12CommandList::apply_viewport(const char* what, float x, float y, float width, float height,
                                      bool originTopLeft) {
    FA_D3D12_REQUIRE_OPEN(what);
    if (passState_ != PassState::Render) {
        fail(what, "outside a render pass (hint: begin_pass() first)");
        return;
    }
    if (passFailed_) return;
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width) || !std::isfinite(height)) {
        fail(what, "the rectangle is not finite");
        return;
    }
    width = std::max(width, 0.0f);
    height = std::max(height, 0.0f);
    D3D12_VIEWPORT vp{};
    vp.TopLeftX = x;
    vp.TopLeftY = originTopLeft ? y : float(passHeight_) - (y + height);
    vp.Width = width;
    vp.Height = height;
    vp.MinDepth = 0.0f;
    vp.MaxDepth = 1.0f;
    list_->RSSetViewports(1, &vp);
    empty_ = false;
}

void D3d12CommandList::set_viewport(int x, int y, int width, int height, bool originTopLeft) {
    apply_viewport("set_viewport", float(x), float(y), float(width), float(height), originTopLeft);
}

void D3d12CommandList::set_viewport_f(float x, float y, float width, float height, bool originTopLeft) {
    apply_viewport("set_viewport_f", x, y, width, height, originTopLeft);
}

void D3d12CommandList::set_scissor(int x, int y, int width, int height, bool originTopLeft) {
    FA_D3D12_REQUIRE_OPEN("set_scissor");
    if (passState_ != PassState::Render) {
        fail("set_scissor", "outside a render pass (hint: begin_pass() first)");
        return;
    }
    if (passFailed_) return;
    // In 64 bits: x + width of two large ints does not overflow.
    const std::int64_t w = std::max(width, 0), h = std::max(height, 0);
    const std::int64_t top = originTopLeft ? std::int64_t(y) : std::int64_t(passHeight_) - (std::int64_t(y) + h);
    const std::int64_t limit = 0x7FFFFFFF;
    D3D12_RECT r{};
    r.left = LONG(std::clamp<std::int64_t>(x, 0, limit));
    r.top = LONG(std::clamp<std::int64_t>(top, 0, limit));
    r.right = LONG(std::clamp<std::int64_t>(std::int64_t(x) + w, r.left, limit));
    r.bottom = LONG(std::clamp<std::int64_t>(top + h, r.top, limit));
    list_->RSSetScissorRects(1, &r);
    empty_ = false;
}

bool D3d12CommandList::ready_to_run(const char* what, bool compute) {
    if (passState_ != (compute ? PassState::Compute : PassState::Render)) {
        fail(what, compute ? "outside a compute pass (hint: begin_compute_pass() first)"
                           : "outside a render pass (hint: begin_pass() first)");
        return false;
    }
    if (passFailed_ || drawsFailed_) return false;  // reported when it failed
    if (!pipeline_) {
        fail(what, "no pipeline is set (hint: set_pipeline() after beginning the pass)");
        return false;
    }
    const PipelineState& st = *pipeline_;
    const ShaderInfo& sh = *st.shader;
    for (int i = 0; i < kMaxUniformBlocks; ++i)
        if (sh.uniformSize[i] > 0 && !((uniformsSet_ >> i) & 1u)) {
            fail(what, "uniform block slot " + std::to_string(i) + " of shader '" + sh.label +
                           "' was not set since set_pipeline (hint: set_uniforms(" + std::to_string(i) +
                           ", ...) after set_pipeline)");
            return false;
        }
    const RootLayout& lay = *st.layout;
    const bool needsBindings = lay.viewCount[0] + lay.viewCount[1] + lay.samplerCount[0] + lay.samplerCount[1] > 0 ||
                               st.buffersUsed != 0 || st.indexType != IndexType::None;
    if (needsBindings && !bindingsSet_) {
        fail(what, "shader '" + sh.label +
                       "' reads buffers, views or samplers and set_bindings was not called since set_pipeline");
        return false;
    }
    // A command after one that wrote the bound UAVs sees its writes.
    if (uavsWritten_)
        for (const std::shared_ptr<TrackedResource>& t : boundUavs_) {
            D3D12_RESOURCE_BARRIER b{};
            b.Type = D3D12_RESOURCE_BARRIER_TYPE_UAV;
            b.UAV.pResource = t->resource.get();
            pending_.push_back(b);
        }
    flush_barriers();
    return true;
}

void D3d12CommandList::record_draw(const char* what, int base, int count, int instances, int baseVertex,
                                   int baseInstance) {
    FA_D3D12_REQUIRE_OPEN(what);
    if (base < 0 || count < 0 || instances < 0 || baseInstance < 0) {
        fail(what, "base " + std::to_string(base) + ", count " + std::to_string(count) + ", instances " +
                       std::to_string(instances) + " or baseInstance " + std::to_string(baseInstance) + " is negative");
        return;
    }
    if (count == 0 || instances == 0) return;  // nothing to draw (sokol skips it too)
    if (!ready_to_run(what, false)) return;
    if (pipeline_->indexType != IndexType::None) {
        list_->DrawIndexedInstanced(UINT(count), UINT(instances), UINT(base), INT(baseVertex), UINT(baseInstance));
    } else {
        const std::int64_t first = std::int64_t(base) + baseVertex;
        if (first < 0) {
            fail(what, "base " + std::to_string(base) + " + baseVertex " + std::to_string(baseVertex) +
                           " is negative (a draw without indices starts at that vertex)");
            return;
        }
        list_->DrawInstanced(UINT(count), UINT(instances), UINT(first), UINT(baseInstance));
    }
    uavsWritten_ = !boundUavs_.empty();
    empty_ = false;
}

void D3d12CommandList::draw(int base, int count, int instances) { record_draw("draw", base, count, instances, 0, 0); }

void D3d12CommandList::draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) {
    record_draw("draw_ex", base, count, instances, baseVertex, baseInstance);
}

void D3d12CommandList::dispatch(int x, int y, int z) {
    FA_D3D12_REQUIRE_OPEN("dispatch");
    const int most = D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION;
    if (x < 0 || y < 0 || z < 0 || x > most || y > most || z > most) {
        fail("dispatch", "(" + std::to_string(x) + ", " + std::to_string(y) + ", " + std::to_string(z) +
                             ") thread groups: each count is 0 to " + std::to_string(most) +
                             " (hint: split the work into several dispatches)");
        return;
    }
    if (x == 0 || y == 0 || z == 0) return;  // nothing to run
    if (!ready_to_run("dispatch", true)) return;
    list_->Dispatch(UINT(x), UINT(y), UINT(z));
    uavsWritten_ = !boundUavs_.empty();
    empty_ = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// States and barriers
// ---------------------------------------------------------------------------------------------------------------------

void D3d12CommandList::transition(Use& u, std::uint32_t sub, StateBits state) {
    StateBits& current = u.current[sub];
    if (current == kStateUnknown) {
        // First use in this list: submit() moves the resource from the queue's state to this one (fix-up list).
        u.first[sub] = state;
        current = state;
        return;
    }
    if (current == state) return;
    D3D12_RESOURCE_BARRIER b{};
    b.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
    b.Transition.pResource = u.res->resource.get();
    b.Transition.Subresource = sub;
    b.Transition.StateBefore = D3D12_RESOURCE_STATES(current);
    b.Transition.StateAfter = D3D12_RESOURCE_STATES(state);
    pending_.push_back(b);
    current = state;
}

void D3d12CommandList::require(const std::shared_ptr<TrackedResource>& t, std::uint32_t sub,
                               D3D12_RESOURCE_STATES state) {
    if (!t) return;
    auto [it, added] = useIndex_.try_emplace(t.get(), uses_.size());
    if (added) {
        Use u;
        u.res = t;
        u.first.assign(t->subresource_count(), kStateUnknown);
        u.current.assign(t->subresource_count(), kStateUnknown);
        uses_.push_back(std::move(u));
    }
    Use& u = uses_[it->second];
    if (sub == kAllSubresources) {
        for (std::uint32_t s = 0; s < t->subresource_count(); ++s) transition(u, s, StateBits(state));
    } else if (sub < t->subresource_count()) {
        transition(u, sub, StateBits(state));
    }
}

void D3d12CommandList::require_range(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip,
                                     std::uint32_t mipCount, std::uint32_t layer, std::uint32_t layerCount,
                                     D3D12_RESOURCE_STATES state) {
    if (!t) return;
    for (std::uint32_t p = 0; p < t->planes; ++p)
        for (std::uint32_t l = layer; l < layer + layerCount && l < t->layers; ++l)
            for (std::uint32_t m = mip; m < mip + mipCount && m < t->mips; ++m)
                require(t, t->subresource(m, l, p), state);
}

void D3d12CommandList::flush_barriers() {
    if (pending_.empty() || !list_) return;
    list_->ResourceBarrier(UINT(pending_.size()), pending_.data());
    device_.barriers_ += pending_.size();
    pending_.clear();
}

void D3d12CommandList::keep_until_done(Com<ID3D12Resource> r) { keep_.push_back(std::move(r)); }

// ---------------------------------------------------------------------------------------------------------------------
// Transfers
// ---------------------------------------------------------------------------------------------------------------------

void D3d12CommandList::write_buffer(const BufferWrite& w) {
    FA_D3D12_REQUIRE_OPEN("write_buffer");
    std::size_t bufferSize = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = device_.buffer_tracked(w.buffer, &bufferSize, &label);
    const std::size_t size = w.size > 0 ? w.size : (w.data.size > w.srcOffset ? w.data.size - w.srcOffset : 0);
    std::string error;
    if (!t)
        error = "buffer " + std::to_string(w.buffer.id) + " is not a live buffer";
    else if (!w.data.ptr || size == 0 || w.srcOffset + size > w.data.size)
        error = "the source range (offset " + std::to_string(w.srcOffset) + ", " + std::to_string(size) +
                " bytes) is empty or past the data's " + std::to_string(w.data.size) + " bytes";
    else if (w.dstOffset + size > bufferSize)
        error = std::to_string(size) + " bytes at offset " + std::to_string(w.dstOffset) + " go past buffer '" + label +
                "''s " + std::to_string(bufferSize) + " bytes";
    if (!error.empty()) {
        device_.report("gpu d3d12: CommandList::write_buffer in list '" + label_ + "': " + error);
        return;
    }
    const UploadAlloc a = device_.upload(size, 16, this);
    if (!a.ok()) return;  // reported
    std::memcpy(a.cpu, static_cast<const std::uint8_t*>(w.data.ptr) + w.srcOffset, size);
    require(t, 0, D3D12_RESOURCE_STATE_COPY_DEST);
    flush_barriers();
    list_->CopyBufferRegion(t->resource.get(), w.dstOffset, a.resource, a.offset, size);
    empty_ = false;
}

void D3d12CommandList::copy_buffer_to_buffer(const BufferCopy& c) {
    FA_D3D12_REQUIRE_OPEN("copy_buffer_to_buffer");
    std::size_t srcSize = 0, dstSize = 0;
    std::string srcLabel, dstLabel;
    std::shared_ptr<TrackedResource> src = device_.buffer_tracked(c.src, &srcSize, &srcLabel);
    std::shared_ptr<TrackedResource> dst = device_.buffer_tracked(c.dst, &dstSize, &dstLabel);
    std::string error;
    if (!src || !dst)
        error = std::string("the ") + (!src ? "source" : "destination") + " is not a live buffer";
    else if (src == dst)
        error = "the source and the destination are the same buffer '" + srcLabel +
                "' (hint: copy through a second buffer)";
    else if (c.size == 0 || c.srcOffset % 4 || c.dstOffset % 4)
        error = "the size is 0 or an offset is not a multiple of 4";
    else if (c.srcOffset + c.size > srcSize || c.dstOffset + c.size > dstSize)
        error = std::to_string(c.size) + " bytes from offset " + std::to_string(c.srcOffset) + " of '" + srcLabel +
                "' (" + std::to_string(srcSize) + " bytes) to offset " + std::to_string(c.dstOffset) + " of '" +
                dstLabel + "' (" + std::to_string(dstSize) + " bytes) go past a buffer's end";
    if (!error.empty()) {
        device_.report("gpu d3d12: CommandList::copy_buffer_to_buffer in list '" + label_ + "': " + error);
        return;
    }
    require(src, 0, D3D12_RESOURCE_STATE_COPY_SOURCE);
    require(dst, 0, D3D12_RESOURCE_STATE_COPY_DEST);
    flush_barriers();
    list_->CopyBufferRegion(dst->resource.get(), c.dstOffset, src->resource.get(), c.srcOffset, c.size);
    empty_ = false;
}

void D3d12CommandList::copy_placed(ID3D12Resource* src, std::uint64_t offset, std::uint32_t rowPitch,
                                   std::uint64_t slicePitch, const std::shared_ptr<TrackedResource>& t,
                                   PixelFormat format, bool is3d, std::uint32_t mip, std::uint32_t layer,
                                   std::uint32_t count, std::uint32_t x, std::uint32_t y, std::uint32_t width,
                                   std::uint32_t height) {
    const FormatInfo fi = format_info(format);
    // Compressed formats copy whole 4x4 blocks (a mip smaller than a block still takes one).
    const std::uint32_t fw = fi.blockBytes ? std::uint32_t(align_up(width, 4)) : width;
    const std::uint32_t fh = fi.blockBytes ? std::uint32_t(align_up(height, 4)) : height;
    D3D12_TEXTURE_COPY_LOCATION from{};
    from.pResource = src;
    from.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
    from.PlacedFootprint.Footprint.Format = fi.resource;
    from.PlacedFootprint.Footprint.Width = fw;
    from.PlacedFootprint.Footprint.Height = fh;
    from.PlacedFootprint.Footprint.RowPitch = rowPitch;
    D3D12_TEXTURE_COPY_LOCATION to{};
    to.pResource = t->resource.get();
    to.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
    if (is3d) {
        to.SubresourceIndex = t->subresource(mip, 0, 0);
        require(t, to.SubresourceIndex, D3D12_RESOURCE_STATE_COPY_DEST);
        flush_barriers();
        from.PlacedFootprint.Offset = offset;
        from.PlacedFootprint.Footprint.Depth = count;
        list_->CopyTextureRegion(&to, x, y, layer, &from, nullptr);
    } else {
        from.PlacedFootprint.Footprint.Depth = 1;
        for (std::uint32_t i = 0; i < count; ++i)
            require(t, t->subresource(mip, layer + i, 0), D3D12_RESOURCE_STATE_COPY_DEST);
        flush_barriers();
        for (std::uint32_t i = 0; i < count; ++i) {
            to.SubresourceIndex = t->subresource(mip, layer + i, 0);
            from.PlacedFootprint.Offset = offset + slicePitch * i;
            list_->CopyTextureRegion(&to, x, y, 0, &from, nullptr);
        }
    }
    empty_ = false;
}

bool D3d12CommandList::upload_region(const std::shared_ptr<TrackedResource>& t, PixelFormat format, bool is3d,
                                     std::uint32_t mip, std::uint32_t layer, std::uint32_t count, std::uint32_t x,
                                     std::uint32_t y, std::uint32_t width, std::uint32_t height,
                                     const std::uint8_t* src, std::size_t srcRowPitch, std::size_t srcSlicePitch) {
    const std::uint32_t rowBytes = texel_row_bytes(format, width);
    const std::uint32_t rows = texel_rows(format, height);
    const auto pitch = std::uint32_t(align_up(rowBytes, D3D12_TEXTURE_DATA_PITCH_ALIGNMENT));
    // 2D slices are copied one by one, each from a 512-byte aligned offset; a 3D region is one footprint.
    const std::uint64_t slice = is3d ? std::uint64_t(pitch) * rows
                                     : align_up(std::uint64_t(pitch) * rows, D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT);
    const UploadAlloc a = device_.upload(std::size_t(slice * count), D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT, this);
    if (!a.ok()) return false;
    for (std::uint32_t i = 0; i < count; ++i)
        for (std::uint32_t r = 0; r < rows; ++r)
            std::memcpy(a.cpu + slice * i + std::uint64_t(pitch) * r, src + srcSlicePitch * i + srcRowPitch * r,
                        rowBytes);
    copy_placed(a.resource, a.offset, pitch, slice, t, format, is3d, mip, layer, count, x, y, width, height);
    return true;
}

namespace {

// The region of a write_image / copy_buffer_to_image, checked against the image, with sokol's defaults.
struct Region {
    std::uint32_t mip = 0, x = 0, y = 0, layer = 0, width = 0, height = 0, count = 0;
    std::size_t rowPitch = 0, slicePitch = 0;  // of the source
    std::uint32_t rowBytes = 0, rows = 0;      // of the region
    std::string error;
};

template <class Record>
Region image_region(const Record& im, const ImageLocation& at, const ImageExtent& size, int bytesPerRow,
                    int bytesPerSlice) {
    Region r;
    const bool is3d = im.type == ImageType::Tex3d;
    if (at.mipLevel < 0 || at.mipLevel >= im.mips) {
        r.error = "mip level " + std::to_string(at.mipLevel) + " is outside image '" + im.label + "''s " +
                  std::to_string(im.mips) + " levels";
        return r;
    }
    if (pixel_format_depth(im.format) || im.samples > 1) {
        r.error = "image '" + im.label + "' is a depth or multisampled image (hint: draw into it instead)";
        return r;
    }
    r.mip = std::uint32_t(at.mipLevel);
    const std::uint32_t mw = mip_extent(im.width, at.mipLevel), mh = mip_extent(im.height, at.mipLevel);
    const std::uint32_t md = is3d ? mip_extent(im.slices, at.mipLevel) : std::uint32_t(im.slices);
    r.width = extent_or_rest(size.width, at.x, mw);
    r.height = extent_or_rest(size.height, at.y, mh);
    r.count = extent_or_rest(size.numSlices, at.slice, md);
    if (at.x < 0 || at.y < 0 || at.slice < 0 || r.width == 0 || r.height == 0 || r.count == 0 ||
        std::uint32_t(at.x) + r.width > mw || std::uint32_t(at.y) + r.height > mh ||
        std::uint32_t(at.slice) + r.count > md) {
        r.error = "the region at (" + std::to_string(at.x) + ", " + std::to_string(at.y) + ", slice " +
                  std::to_string(at.slice) + ") of " + std::to_string(r.width) + "x" + std::to_string(r.height) + "x" +
                  std::to_string(r.count) + " is empty or outside mip " + std::to_string(at.mipLevel) + " (" +
                  std::to_string(mw) + "x" + std::to_string(mh) + "x" + std::to_string(md) + ") of image '" + im.label +
                  "'";
        return r;
    }
    r.x = std::uint32_t(at.x);
    r.y = std::uint32_t(at.y);
    r.layer = std::uint32_t(at.slice);
    if (format_info(im.format).blockBytes &&
        (r.x % 4 || r.y % 4 || (r.width % 4 && r.x + r.width != mw) || (r.height % 4 && r.y + r.height != mh))) {
        r.error = "a compressed image is written in whole 4x4 blocks (hint: align the region to 4 texels)";
        return r;
    }
    r.rowBytes = texel_row_bytes(im.format, r.width);
    r.rows = texel_rows(im.format, r.height);
    // sokol's defaults: the pitches of the whole mip level, not of the region.
    r.rowPitch = bytesPerRow > 0 ? std::size_t(bytesPerRow) : texel_row_bytes(im.format, mw);
    r.slicePitch = bytesPerSlice > 0 ? std::size_t(bytesPerSlice) : r.rowPitch * texel_rows(im.format, mh);
    if (r.rowPitch < r.rowBytes || r.slicePitch < r.rowPitch * r.rows) {
        r.error = "bytesPerRow " + std::to_string(r.rowPitch) + " / bytesPerSlice " + std::to_string(r.slicePitch) +
                  " are smaller than a row (" + std::to_string(r.rowBytes) + ") / a slice of the region";
        return r;
    }
    return r;
}

std::size_t region_bytes(const Region& r) {
    return r.slicePitch * (r.count - 1) + r.rowPitch * (r.rows - 1) + r.rowBytes;
}

}  // namespace

void D3d12CommandList::write_image(const ImageWrite& w) {
    FA_D3D12_REQUIRE_OPEN("write_image");
    D3d12Device::ImageRecord im;
    if (!device_.image_info(w.dst.image, im)) {
        device_.report("gpu d3d12: CommandList::write_image in list '" + label_ + "': image " +
                       std::to_string(w.dst.image.id) + " is not a live image");
        return;
    }
    Region r = image_region(im, w.dst, w.size, w.bytesPerRow, w.bytesPerSlice);
    if (r.error.empty() && (!w.data.ptr || w.srcOffset + region_bytes(r) > w.data.size))
        r.error = "the region needs " + std::to_string(region_bytes(r)) + " bytes from offset " +
                  std::to_string(w.srcOffset) + ", the data has " + std::to_string(w.data.size);
    if (!r.error.empty()) {
        device_.report("gpu d3d12: CommandList::write_image in list '" + label_ + "': " + r.error);
        return;
    }
    upload_region(im.tracked, im.format, im.type == ImageType::Tex3d, r.mip, r.layer, r.count, r.x, r.y, r.width,
                  r.height, static_cast<const std::uint8_t*>(w.data.ptr) + w.srcOffset, r.rowPitch, r.slicePitch);
}

void D3d12CommandList::copy_buffer_to_image(const BufferImageCopy& c) {
    FA_D3D12_REQUIRE_OPEN("copy_buffer_to_image");
    std::size_t srcSize = 0;
    std::string srcLabel;
    std::shared_ptr<TrackedResource> src = device_.buffer_tracked(c.src, &srcSize, &srcLabel);
    D3d12Device::ImageRecord im;
    Region r;
    if (!src)
        r.error = "the source " + std::to_string(c.src.id) + " is not a live buffer";
    else if (!device_.image_info(c.dst.image, im))
        r.error = "the destination " + std::to_string(c.dst.image.id) + " is not a live image";
    else
        r = image_region(im, c.dst, c.size, c.bytesPerRow, c.bytesPerSlice);
    if (r.error.empty() && c.srcOffset + region_bytes(r) > srcSize)
        r.error = "the region needs " + std::to_string(region_bytes(r)) + " bytes from offset " +
                  std::to_string(c.srcOffset) + " of buffer '" + srcLabel + "', which has " + std::to_string(srcSize);
    if (!r.error.empty()) {
        device_.report("gpu d3d12: CommandList::copy_buffer_to_image in list '" + label_ + "': " + r.error);
        return;
    }
    const bool is3d = im.type == ImageType::Tex3d;
    require(src, 0, D3D12_RESOURCE_STATE_COPY_SOURCE);
    const bool placed =
        c.srcOffset % D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT == 0 &&
        r.rowPitch % D3D12_TEXTURE_DATA_PITCH_ALIGNMENT == 0 &&
        (is3d ? r.slicePitch == r.rowPitch * r.rows : r.slicePitch % D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT == 0);
    if (placed) {
        copy_placed(src->resource.get(), c.srcOffset, std::uint32_t(r.rowPitch), r.slicePitch, im.tracked, im.format,
                    is3d, r.mip, r.layer, r.count, r.x, r.y, r.width, r.height);
        return;
    }
    // D3D12 copies texels from 512-byte aligned offsets with 256-byte aligned rows: other layouts are repacked on the
    // GPU into a scratch buffer, one row at a time, then copied from there.
    const auto pitch = std::uint32_t(align_up(r.rowBytes, D3D12_TEXTURE_DATA_PITCH_ALIGNMENT));
    const std::uint64_t slice = is3d ? std::uint64_t(pitch) * r.rows
                                     : align_up(std::uint64_t(pitch) * r.rows, D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT);
    D3D12_RESOURCE_DESC d{};
    d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    d.Width = slice * r.count;
    d.Height = 1;
    d.DepthOrArraySize = 1;
    d.MipLevels = 1;
    d.SampleDesc.Count = 1;
    d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    Com<ID3D12Resource> raw = device_.make_committed(d, D3D12_HEAP_TYPE_DEFAULT, D3D12_RESOURCE_STATE_COMMON,
                                                     "copy_buffer_to_image (repacking rows)", "fa-d3d12-repack");
    if (!raw) return;  // reported
    auto scratch = std::make_shared<TrackedResource>();
    scratch->resource = raw;
    scratch->states.assign(1, StateBits(D3D12_RESOURCE_STATE_COMMON));
    scratch->buffer = true;
    scratch->owner = kind_;  // this list's own, on whichever queue it runs
    require(scratch, 0, D3D12_RESOURCE_STATE_COPY_DEST);
    flush_barriers();
    for (std::uint32_t i = 0; i < r.count; ++i)
        for (std::uint32_t row = 0; row < r.rows; ++row)
            list_->CopyBufferRegion(raw.get(), slice * i + std::uint64_t(pitch) * row, src->resource.get(),
                                    c.srcOffset + r.slicePitch * i + r.rowPitch * row, r.rowBytes);
    require(scratch, 0, D3D12_RESOURCE_STATE_COPY_SOURCE);
    copy_placed(raw.get(), 0, pitch, slice, im.tracked, im.format, is3d, r.mip, r.layer, r.count, r.x, r.y, r.width,
                r.height);
    keep_until_done(std::move(raw));
}

// ---------------------------------------------------------------------------------------------------------------------
// Debug groups (PIX markers)
// ---------------------------------------------------------------------------------------------------------------------

void D3d12CommandList::push_debug_group(const char* name) {
    FA_D3D12_REQUIRE_OPEN("push_debug_group");
    // PIX's convention: metadata 0 = the data is a null-terminated UTF-16 string.
    const std::wstring w = widen(name ? name : "");
    list_->BeginEvent(0, w.c_str(), UINT((w.size() + 1) * sizeof(wchar_t)));
    ++debugDepth_;
}

void D3d12CommandList::pop_debug_group() {
    FA_D3D12_REQUIRE_OPEN("pop_debug_group");
    if (debugDepth_ == 0) {
        device_.report("gpu d3d12: CommandList::pop_debug_group in list '" + label_ +
                       "' without an open group (hint: one pop_debug_group() per push_debug_group())");
        return;
    }
    list_->EndEvent();
    --debugDepth_;
}

#undef FA_D3D12_REQUIRE_OPEN

}  // namespace fa::gpu::d3d12
