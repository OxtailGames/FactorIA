// The D3D12 backend's readbacks: blocking ones (a copy into a readback buffer, a fence wait, a map) and asynchronous
// ones (the copy's fence value checked later) (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include <cstring>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/d3d12_device.h"
#include "hdr_encode.h"

namespace fa::gpu::d3d12 {

namespace {

D3D12_RESOURCE_DESC readback_desc(std::uint64_t bytes) {
    D3D12_RESOURCE_DESC d{};
    d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    d.Width = bytes;
    d.Height = 1;
    d.DepthOrArraySize = 1;
    d.MipLevels = 1;
    d.Format = DXGI_FORMAT_UNKNOWN;
    d.SampleDesc.Count = 1;
    d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    return d;
}

}  // namespace

Com<ID3D12Resource> D3d12Device::make_readback(std::uint64_t bytes, const char* what) {
    return make_committed(readback_desc(bytes), D3D12_HEAP_TYPE_READBACK, D3D12_RESOURCE_STATE_COPY_DEST, what,
                          "fa-d3d12-readback");
}

Result<D3d12Device::TextureFootprint> D3d12Device::texture_read_footprint(const ImageRecord& rec, std::uint32_t mip,
                                                                          std::uint32_t layer, int x, int y, int width,
                                                                          int height, const char* what) const {
    const std::string where = std::string("gpu d3d12: ") + what + " of image '" + rec.label + "'";
    if (rec.samples > 1)
        return make_error(where + ": the image is multisampled",
                          "resolve it into a single-sampled image (PassDesc::resolve) and read that");
    if (pixel_format_depth(rec.format) || pixel_format_compressed(rec.format))
        return make_error(where + ": " + pixel_format_name(rec.format) + " images are not read back",
                          "copy the values into a colour or storage image with a shader and read that");
    const bool is3d = rec.type == ImageType::Tex3d;
    if (mip >= std::uint32_t(rec.mips))
        return make_error(where + ": mip " + std::to_string(mip) + " is outside its " + std::to_string(rec.mips) +
                              " levels",
                          "read a mip level from 0 to numMipmaps - 1");
    const std::uint32_t mw = mip_extent(rec.width, int(mip)), mh = mip_extent(rec.height, int(mip));
    const std::uint32_t layers = is3d ? mip_extent(rec.slices, int(mip)) : std::uint32_t(rec.slices);
    if (layer >= layers)
        return make_error(where + ": slice " + std::to_string(layer) + " is outside its " + std::to_string(layers) +
                              " slices at mip " + std::to_string(mip),
                          "read a slice from 0 to the image's slice count - 1");
    if (x < 0 || y < 0 || width < 1 || height < 1 || std::uint32_t(x) >= mw || std::uint32_t(y) >= mh ||
        std::uint32_t(width) > mw - std::uint32_t(x) || std::uint32_t(height) > mh - std::uint32_t(y))
        return make_error(where + ": the rectangle (" + std::to_string(x) + ", " + std::to_string(y) + ", " +
                              std::to_string(width) + "x" + std::to_string(height) + ") is empty or outside its " +
                              std::to_string(mw) + "x" + std::to_string(mh) + " mip " + std::to_string(mip),
                          "read inside the image's size");
    // The region as a one-mip 2D texture: GetCopyableFootprints gives its layout in a buffer (rows 256-byte aligned).
    D3D12_RESOURCE_DESC d{};
    d.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
    d.Width = std::uint64_t(width);
    d.Height = std::uint32_t(height);
    d.DepthOrArraySize = 1;
    d.MipLevels = 1;
    d.Format = format_info(rec.format).resource;
    d.SampleDesc.Count = 1;
    d.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
    TextureFootprint fp;
    UINT rows = 0;
    UINT64 rowSize = 0, total = 0;
    device_->GetCopyableFootprints(&d, 0, 1, 0, &fp.placed, &rows, &rowSize, &total);
    if (total == UINT64_MAX || rows != UINT(height) || rowSize == 0)
        return make_error(where + ": D3D12 gives no buffer layout for a " + std::to_string(width) + "x" +
                              std::to_string(height) + " region of " + pixel_format_name(rec.format),
                          "read the image with read_image_region in smaller pieces");
    fp.placed.Offset = 0;
    fp.rows = rows;
    fp.rowBytes = texel_row_bytes(rec.format, std::uint32_t(width));
    fp.total = total;
    return fp;
}

void D3d12Device::record_texture_read(D3d12CommandList& list, const ImageRecord& rec, std::uint32_t mip,
                                      std::uint32_t layer, int x, int y, const TextureFootprint& fp,
                                      ID3D12Resource* dst) {
    const bool is3d = rec.type == ImageType::Tex3d;
    D3D12_TEXTURE_COPY_LOCATION from{};
    from.pResource = rec.tracked->resource.get();
    from.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
    from.SubresourceIndex = rec.tracked->subresource(mip, is3d ? 0 : layer, 0);
    list.require(rec.tracked, from.SubresourceIndex, D3D12_RESOURCE_STATE_COPY_SOURCE);
    list.flush_barriers();
    D3D12_TEXTURE_COPY_LOCATION to{};
    to.pResource = dst;
    to.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
    to.PlacedFootprint = fp.placed;
    D3D12_BOX box{};
    box.left = UINT(x);
    box.top = UINT(y);
    box.right = UINT(x) + fp.placed.Footprint.Width;
    box.bottom = UINT(y) + fp.placed.Footprint.Height;
    box.front = is3d ? layer : 0;
    box.back = box.front + 1;
    list.list_->CopyTextureRegion(&to, 0, 0, 0, &from, &box);
    list.empty_ = false;
}

Result<void> D3d12Device::read_texture(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y,
                                       int width, int height, std::vector<std::uint8_t>& out, const char* what) {
    auto fpr = texture_read_footprint(rec, mip, layer, x, y, width, height, what);
    if (!fpr) return fpr.error();
    const TextureFootprint fp = *fpr;
    const std::string where = std::string("gpu d3d12: ") + what + " of image '" + rec.label + "'";
    Com<ID3D12Resource> rb = make_readback(fp.total, what);
    if (!rb) return make_error(where + ": the readback buffer could not be made", "see errors() for D3D12's reason");
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();  // the image's initial data goes first
        D3d12CommandList* list = acquire_list("fa-d3d12-readback", true);
        if (!list) return make_error(where + ": no command list", "see errors() for D3D12's reason");
        record_texture_read(*list, rec, mip, layer, x, y, fp, rb.get());
        execute(*list);
        auto r = wait_fence(list->fence_, what);
        collect();
        if (!r) return r;
    }
    void* p = nullptr;
    const D3D12_RANGE range{0, SIZE_T(fp.total)};
    const HRESULT hr = rb->Map(0, &range, &p);
    if (FAILED(hr) || !p)
        return make_error(where + ": ID3D12Resource::Map of the readback buffer failed with " + hr_text(hr) +
                              removed_reason(),
                          "the process ran out of address space or the device was lost");
    const std::size_t pitch = fp.placed.Footprint.RowPitch;
    out.resize(std::size_t(fp.rowBytes) * fp.rows);
    for (std::size_t row = 0; row < fp.rows; ++row)
        std::memcpy(out.data() + std::size_t(fp.rowBytes) * row, static_cast<const std::uint8_t*>(p) + pitch * row,
                    fp.rowBytes);
    const D3D12_RANGE none{0, 0};
    rb->Unmap(0, &none);
    return {};
}

Result<void> D3d12Device::read_image_region(Image image, int mip, int layer, int x, int y, int width, int height,
                                            std::vector<std::uint8_t>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu d3d12: read_image_region: image " + std::to_string(image.id) +
                              " is not a live image (destroyed, failed, or another device's)",
                          "read an image this device made, before destroy_image()");
    if (mip < 0 || layer < 0)
        return make_error("gpu d3d12: read_image_region of image '" + rec.label + "': a negative mip or slice",
                          "mip and slice count from 0");
    return read_texture(rec, std::uint32_t(mip), std::uint32_t(layer), x, y, width, height, out, "read_image_region");
}

Result<void> D3d12Device::read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu d3d12: read_image_rgba8: image " + std::to_string(image.id) + " is not a live image",
                          "read an image this device made, before destroy_image()");
    const PixelFormat f = rec.format;
    if (f != PixelFormat::Rgba8 && f != PixelFormat::Srgb8A8 && f != PixelFormat::Bgra8 && f != PixelFormat::Sbgr8A8)
        return make_error(std::string("gpu d3d12: read_image_rgba8 of image '") + rec.label + "': its format is " +
                              pixel_format_name(f) + ", not an 8-bit RGBA or BGRA one",
                          "read an RGBA16F image with read_image_rgba16f, other formats with read_storage_image");
    if (auto r = read_texture(rec, 0, 0, 0, 0, width, height, out, "read_image_rgba8"); !r) return r;
    if (f == PixelFormat::Bgra8 || f == PixelFormat::Sbgr8A8)
        for (std::size_t i = 0; i + 3 < out.size(); i += 4) std::swap(out[i], out[i + 2]);  // BGRA -> RGBA
    return {};
}

Result<void> D3d12Device::read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu d3d12: read_image_rgba16f: image " + std::to_string(image.id) + " is not a live image",
                          "read an image this device made, before destroy_image()");
    if (rec.format != PixelFormat::Rgba16F)
        return make_error(std::string("gpu d3d12: read_image_rgba16f of image '") + rec.label + "': its format is " +
                              pixel_format_name(rec.format) + ", not RGBA16F",
                          "read 8-bit images with read_image_rgba8, other formats with read_storage_image");
    std::vector<std::uint8_t> bytes;
    if (auto r = read_texture(rec, 0, 0, 0, 0, width, height, bytes, "read_image_rgba16f"); !r) return r;
    out.resize(bytes.size() / 2);
    for (std::size_t i = 0; i < out.size(); ++i) {
        std::uint16_t h = 0;
        std::memcpy(&h, bytes.data() + i * 2, 2);
        out[i] = render::half_to_float(h);
    }
    return {};
}

Result<void> D3d12Device::read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                             std::vector<std::uint8_t>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu d3d12: read_storage_image: image " + std::to_string(image.id) + " is not a live image",
                          "read an image this device made, before destroy_image()");
    if (format != rec.format)
        return make_error(std::string("gpu d3d12: read_storage_image of image '") + rec.label + "': asked for " +
                              pixel_format_name(format) + ", the image is " + pixel_format_name(rec.format),
                          "pass the image's own format: the bytes come back in it, tightly packed");
    return read_texture(rec, 0, 0, x, y, width, height, out, "read_storage_image");
}

Result<void> D3d12Device::read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                                      std::vector<std::uint8_t>& out) {
    std::size_t size = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = buffer_tracked(buffer, &size, &label);
    if (!t)
        return make_error("gpu d3d12: read_buffer: buffer " + std::to_string(buffer.id) +
                              " is not a live buffer (destroyed, failed, or another device's)",
                          "read a buffer this device made, before destroy_buffer()");
    if (offset > size || bytes > size - offset)
        return make_error("gpu d3d12: read_buffer of buffer '" + label + "': " + std::to_string(bytes) +
                              " bytes from offset " + std::to_string(offset) + " go past its " + std::to_string(size) +
                              " bytes",
                          "read inside the buffer");
    out.clear();
    if (bytes == 0) return {};
    Com<ID3D12Resource> rb = make_readback(bytes, "read_buffer");
    if (!rb)
        return make_error("gpu d3d12: read_buffer of buffer '" + label + "': the readback buffer could not be made",
                          "see errors() for D3D12's reason");
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();
        D3d12CommandList* list = acquire_list("fa-d3d12-readback", true);
        if (!list) return make_error("gpu d3d12: read_buffer: no command list", "see errors() for D3D12's reason");
        list->require(t, 0, D3D12_RESOURCE_STATE_COPY_SOURCE);
        list->flush_barriers();
        list->list_->CopyBufferRegion(rb.get(), 0, t->resource.get(), offset, bytes);
        list->empty_ = false;
        execute(*list);
        auto r = wait_fence(list->fence_, "read_buffer");
        collect();
        if (!r) return r;
    }
    void* p = nullptr;
    const D3D12_RANGE range{0, SIZE_T(bytes)};
    const HRESULT hr = rb->Map(0, &range, &p);
    if (FAILED(hr) || !p)
        return make_error("gpu d3d12: read_buffer of buffer '" + label + "': Map failed with " + hr_text(hr) +
                              removed_reason(),
                          "the process ran out of address space or the device was lost");
    out.assign(static_cast<const std::uint8_t*>(p), static_cast<const std::uint8_t*>(p) + bytes);
    const D3D12_RANGE none{0, 0};
    rb->Unmap(0, &none);
    return {};
}

// ---------------------------------------------------------------------------------------------------------------------
// Asynchronous reads: the copy runs at once on an internal list (behind every list submitted so far); its fence value
// says when the bytes are there. Nothing waits but poll_buffer_read(wait = true).
// ---------------------------------------------------------------------------------------------------------------------

int D3d12Device::free_async_slot() const {
    const std::uint64_t completed = fence_->GetCompletedValue();
    if (completed == UINT64_MAX) return -1;  // device lost: a copy may never finish
    for (std::size_t i = 0; i < asyncReads_.size(); ++i)
        if (asyncReads_[i].generation == 0 && asyncReads_[i].fence <= completed) return int(i);
    return -1;
}

bool D3d12Device::async_ticket_current(ReadTicket ticket) const {
    return ticket.valid() && ticket.slot < kAsyncReads &&
           asyncReads_[std::size_t(ticket.slot)].generation == ticket.generation;
}

Result<ReadTicket> D3d12Device::start_async_read(int slot, const char* what,
                                                 const std::function<void(D3d12CommandList&)>& copy) {
    AsyncRead& r = asyncReads_[std::size_t(slot)];
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();  // initial data and uploads go first
        D3d12CommandList* list = acquire_list("fa-d3d12-async-read", true);
        if (!list)
            return make_error(std::string("gpu d3d12: ") + what + ": no command list",
                              "see errors() for D3D12's reason");
        copy(*list);
        list->empty_ = false;
        const std::uint64_t before = fenceValue_;
        execute(*list);
        if (list->fence_ <= before)
            return make_error(std::string("gpu d3d12: ") + what + ": the copy could not be submitted" +
                                  removed_reason(),
                              "see errors() for D3D12's reason");
        r.fence = list->fence_;
        collect();
    }
    if (++readGeneration_ == 0) ++readGeneration_;  // 0 names no ticket
    r.generation = readGeneration_;
    return ReadTicket{slot, r.generation};
}

Result<ReadTicket> D3d12Device::request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) {
    std::size_t size = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = buffer_tracked(buffer, &size, &label);
    if (!t)
        return make_error("gpu d3d12: request_buffer_read: buffer " + std::to_string(buffer.id) +
                              " is not a live buffer (destroyed, failed, or another device's)",
                          "read a buffer this device made, before destroy_buffer()");
    if (bytes == 0 || offset > size || bytes > size - offset)
        return make_error("gpu d3d12: request_buffer_read of buffer '" + label + "': " + std::to_string(bytes) +
                              " bytes from offset " + std::to_string(offset) +
                              (bytes == 0 ? " is no read" : " go past its " + std::to_string(size) + " bytes"),
                          "read at least one byte, inside the buffer");
    const int slot = free_async_slot();
    if (slot < 0) return ReadTicket{};  // every slot is busy: ask again next frame
    AsyncRead& r = asyncReads_[std::size_t(slot)];
    if (r.capacity < bytes) {
        const std::uint64_t capacity = align_up(bytes, 64u * 1024u);
        Com<ID3D12Resource> rb = make_readback(capacity, "request_buffer_read");
        if (!rb)
            return make_error("gpu d3d12: request_buffer_read of buffer '" + label +
                                  "': the readback buffer could not be made",
                              "see errors() for D3D12's reason");
        r.buffer = std::move(rb);
        r.capacity = capacity;
    }
    r.bytes = bytes;
    r.rows = r.rowBytes = r.rowPitch = 0;
    ID3D12Resource* dst = r.buffer.get();
    return start_async_read(slot, "request_buffer_read", [&](D3d12CommandList& list) {
        list.require(t, 0, D3D12_RESOURCE_STATE_COPY_SOURCE);
        list.flush_barriers();
        list.list_->CopyBufferRegion(dst, 0, t->resource.get(), offset, bytes);
    });
}

Result<ReadTicket> D3d12Device::request_image_read(Image image, int mip, int layer, int x, int y, int width,
                                                   int height) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu d3d12: request_image_read: image " + std::to_string(image.id) +
                              " is not a live image (destroyed, failed, or another device's)",
                          "read an image this device made, before destroy_image()");
    if (mip < 0 || layer < 0)
        return make_error("gpu d3d12: request_image_read of image '" + rec.label + "': a negative mip or slice",
                          "mip and slice count from 0");
    auto fpr = texture_read_footprint(rec, std::uint32_t(mip), std::uint32_t(layer), x, y, width, height,
                                      "request_image_read");
    if (!fpr) return fpr.error();
    const TextureFootprint fp = *fpr;
    const int slot = free_async_slot();
    if (slot < 0) return ReadTicket{};  // every slot is busy: ask again next frame
    AsyncRead& r = asyncReads_[std::size_t(slot)];
    if (r.capacity < fp.total) {
        const std::uint64_t capacity = align_up(fp.total, 64u * 1024u);
        Com<ID3D12Resource> rb = make_readback(capacity, "request_image_read");
        if (!rb)
            return make_error("gpu d3d12: request_image_read of image '" + rec.label +
                                  "': the readback buffer could not be made",
                              "see errors() for D3D12's reason");
        r.buffer = std::move(rb);
        r.capacity = capacity;
    }
    r.bytes = std::size_t(fp.rowBytes) * fp.rows;
    r.rows = fp.rows;
    r.rowBytes = fp.rowBytes;
    r.rowPitch = fp.placed.Footprint.RowPitch;
    ID3D12Resource* dst = r.buffer.get();
    return start_async_read(slot, "request_image_read", [&](D3d12CommandList& list) {
        record_texture_read(list, rec, std::uint32_t(mip), std::uint32_t(layer), x, y, fp, dst);
    });
}

bool D3d12Device::poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) {
    if (!async_ticket_current(ticket)) return false;  // never issued, already read or released: stale
    AsyncRead& r = asyncReads_[std::size_t(ticket.slot)];
    const std::uint64_t completed = fence_->GetCompletedValue();
    if (completed == UINT64_MAX || completed < r.fence) {
        if (!wait) return false;
        std::lock_guard<std::mutex> lock(queueMutex_);
        if (auto w = wait_fence(r.fence, "poll_buffer_read"); !w) {
            report(w.error().to_string());
            return false;
        }
    }
    const std::size_t span = r.rows > 0 ? std::size_t(r.rowPitch) * (r.rows - 1) + r.rowBytes : r.bytes;
    void* p = nullptr;
    const D3D12_RANGE range{0, SIZE_T(span)};
    const HRESULT hr = r.buffer->Map(0, &range, &p);
    if (FAILED(hr) || !p) {
        report("gpu d3d12: poll_buffer_read: ID3D12Resource::Map of the readback buffer failed with " + hr_text(hr) +
               removed_reason() + " (hint: the process ran out of address space or the device was lost)");
        return false;
    }
    const auto* src = static_cast<const std::uint8_t*>(p);
    if (r.rows == 0) {
        out.assign(src, src + r.bytes);
    } else {
        out.resize(std::size_t(r.rowBytes) * r.rows);
        for (std::size_t row = 0; row < r.rows; ++row)
            std::memcpy(out.data() + std::size_t(r.rowBytes) * row, src + std::size_t(r.rowPitch) * row, r.rowBytes);
    }
    const D3D12_RANGE none{0, 0};
    r.buffer->Unmap(0, &none);
    r.generation = 0;  // read to the end: the ticket is stale, the slot free (its copy finished)
    return true;
}

void D3d12Device::release_buffer_read(ReadTicket ticket) {
    // The slot is reused once its copy finished (free_async_slot checks the fence), so nothing waits here.
    if (async_ticket_current(ticket)) asyncReads_[std::size_t(ticket.slot)].generation = 0;
}

}  // namespace fa::gpu::d3d12
