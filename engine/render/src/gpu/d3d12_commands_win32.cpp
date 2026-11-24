// The D3D12 backend's command lists: opening and reusing them, resource-state tracking and barriers, the transfers
// (write_buffer, write_image, the copies) and debug groups (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
// Passes, pipelines, bindings, uniforms, draws and dispatches come in M77-P7c.
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

Result<void> D3d12CommandList::create(const char* what) {
    ID3D12Device* dev = device_.device_.get();
    HRESULT hr = dev->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, __uuidof(ID3D12CommandAllocator),
                                             allocator_.put_void());
    if (FAILED(hr))
        return make_error(std::string("gpu d3d12: begin_commands('") + what +
                              "'): CreateCommandAllocator failed with " + hr_text(hr) + device_.removed_reason(),
                          "the GPU ran out of memory or the device was lost");
    hr = dev->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, allocator_.get(), nullptr,
                                __uuidof(ID3D12GraphicsCommandList), list_.put_void());
    if (FAILED(hr))
        return make_error(std::string("gpu d3d12: begin_commands('") + what + "'): CreateCommandList failed with " +
                              hr_text(hr) + device_.removed_reason(),
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

void D3d12CommandList::not_yet(const char* what) {
    device_.report_once(what, std::string("gpu d3d12: CommandList::") + what +
                                  " is not built yet (M77-P7c) (hint: the D3D12 backend records transfers and debug "
                                  "groups for now; draw with the sokol backend until M77-P7c)");
}

void D3d12CommandList::begin_pass(const PassDesc&) { not_yet("begin_pass"); }
void D3d12CommandList::begin_compute_pass(const char*) { not_yet("begin_compute_pass"); }
void D3d12CommandList::end_pass() { not_yet("end_pass"); }
void D3d12CommandList::set_pipeline(Pipeline) { not_yet("set_pipeline"); }
void D3d12CommandList::set_bindings(const Bindings&) { not_yet("set_bindings"); }
void D3d12CommandList::set_uniforms(int, Range) { not_yet("set_uniforms"); }
void D3d12CommandList::set_viewport(int, int, int, int, bool) { not_yet("set_viewport"); }
void D3d12CommandList::set_viewport_f(float, float, float, float, bool) { not_yet("set_viewport_f"); }
void D3d12CommandList::set_scissor(int, int, int, int, bool) { not_yet("set_scissor"); }
void D3d12CommandList::draw(int, int, int) { not_yet("draw"); }
void D3d12CommandList::draw_ex(int, int, int, int, int) { not_yet("draw_ex"); }
void D3d12CommandList::dispatch(int, int, int) { not_yet("dispatch"); }
// The device cannot time yet (timer_supported() is false): a timed scope does nothing, as the interface says.
void D3d12CommandList::begin_timed_scope(const char*) {}
void D3d12CommandList::end_timed_scope() {}

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
