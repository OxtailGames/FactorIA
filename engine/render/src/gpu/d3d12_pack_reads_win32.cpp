// The D3D12 backend's pack reads into GPU resources (M77-P11b2, docs/design/ARCHITECTURE_FILES.md, "DirectStorage", and
// docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
//
// A read goes through three stages, none of which blocks the render thread:
//   1. Graphics: an internal list moves the destination to the COMMON state DirectStorage writes in (a texture; a
//      buffer is COMMON between lists already) and uploads the blocks the range holds only part of, decoded on the CPU.
//      For the CPU fallback it uploads the whole range instead, and that is the read's last stage.
//   2. Direct: once that list finished on the GPU (so nothing the queue ran before touches the resource any more), the
//      read's requests, a status entry and a fence signal go to DirectStorage's queue, made with this device.
//   3. Done: the status entry is complete and the fence reached its value; the direct queue waits for that fence, so
//      the lists submitted from now on see what DirectStorage wrote.
// poll_pack_read() and commit() move reads along; poll_pack_read(wait) and the destructor wait, bounded.
#include "gpu/d3d12_device.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/log.h"
#include "fa/core/pack.h"
#include "pack_direct_storage.h"
#if defined(_WIN64)
#include "dstorage_api_win32.h"
#endif

namespace fa::gpu::d3d12 {

namespace {

std::uint64_t now_ms() {
    return std::uint64_t(
        std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch())
            .count());
}

// How long poll_pack_read(wait) and the destructor wait for one read at most (DirectStorage's own give-up, plus the
// time its cancellation takes).
constexpr std::uint64_t kPackWaitMs = fa::detail::kDirectGiveUpMs + fa::detail::kDirectWarnMs;

}  // namespace

struct D3d12Device::PackRead {
    enum class Stage { Free, Graphics, Direct, Done };
    Stage stage = Stage::Free;
    std::uint32_t generation = 0;  // the ticket's; 0 = none (released or polled to the end)
    bool direct = false;           // DirectStorage writes it (else the CPU fallback)
    std::uint64_t graphicsFence = 0;  // Graphics: the internal list's fence value
    std::uint64_t directFence = 0;    // Direct: the value DirectStorage's signal sets
    std::uint64_t directSince = 0;    // Direct: when it was submitted (ms)
    bool warned = false, cancelled = false;
    std::uint64_t tag = 0;  // its requests' cancellation tag

    // What and where
    PackSource src;
    const char* what = "";
    bool image = false;
    std::shared_ptr<TrackedResource> tracked;
    std::string label;
    std::size_t dstOffset = 0;  // a buffer
    PixelFormat format = PixelFormat::Rgba8;  // an image
    bool is3d = false;
    std::uint32_t mip = 0, layer = 0, sub = 0, x = 0, y = 0, width = 0, height = 0, rowBytes = 0, rows = 0;

    // The DirectStorage requests (stage 2) and what they read
#if defined(_WIN64)
    std::vector<fa::detail::dstorage::Request> requests;
    std::vector<std::uint8_t> partial;  // the decoded bytes of the partial blocks, uploaded in stage 1
    std::vector<fa::detail::DirectBufferSplit::CpuPart> partialParts;
#endif
    std::uint64_t storedBytes = 0;
    std::uint64_t directBlocks = 0;
    PackReadResult result;
};

struct D3d12Device::PackReads {
    std::array<PackRead, kPackReads> reads;
    std::uint32_t generation = 0;
    std::uint64_t directReads = 0, cpuReads = 0, directBlocks = 0;
    std::vector<std::string> warned;  // the fallback reasons already logged
    bool tried = false;               // DirectStorage was set up (or failed to be)
    std::string why;                  // non-empty: reads do not use DirectStorage on this device
#if defined(_WIN64)
    fa::detail::dstorage::Ref<fa::detail::dstorage::Queue> queue;
    fa::detail::dstorage::Ref<fa::detail::dstorage::StatusArray> status;
    Com<ID3D12Fence> fence;
    std::uint64_t fenceValue = 0;
    HANDLE event = nullptr;
    fa::detail::DirectQueueRoom room{fa::detail::kDirectGpuQueueCapacity};
    std::uint64_t nextTag = 0;
    struct OpenFile {
        std::weak_ptr<const PackReader> pack;
        fa::detail::dstorage::Ref<fa::detail::dstorage::File> file;
    };
    std::vector<OpenFile> files;
#endif

    ~PackReads() {
#if defined(_WIN64)
        for (OpenFile& f : files)
            if (f.file) f.file->Close();
        files.clear();
        if (queue) queue->Close();
        if (event) CloseHandle(event);
#endif
    }
};

namespace {

// Logs `message` the first time `reason` is given (one warning per reason a read takes the CPU fallback).
void warn_once(std::vector<std::string>& warned, const std::string& reason, const std::string& message) {
    if (std::find(warned.begin(), warned.end(), reason) != warned.end()) return;
    warned.push_back(reason);
    FA_WARN("render", "{}", message);
}

}  // namespace

std::string D3d12Device::pack_reads_direct_why() const { return packReads_ ? packReads_->why : std::string(); }

// ---- setting DirectStorage up ---------------------------------------------------------------------------------------

#if defined(_WIN64)
namespace {

namespace ds = fa::detail::dstorage;

// The DirectStorage queue of a device (its buffers and textures as destinations), its status array, fence and event.
void setup_direct(D3d12Device::PackReads& p, ID3D12Device* device) {
    p.tried = true;
    std::string why;
    ds::Factory* factory = fa::detail::direct_storage_factory(why);
    if (!factory) {
        p.why = why;
        return;
    }
    ds::QueueDesc desc;
    desc.capacity = std::uint16_t(fa::detail::kDirectGpuQueueCapacity);
    desc.name = "FactorIA game.pak (GPU)";
    desc.device = device;
    HRESULT hr = factory->CreateQueue(&desc, ds::kIidQueue, p.queue.put());
    if (FAILED(hr) || !p.queue) {
        p.queue.reset();
        p.why = "IDStorageFactory::CreateQueue with the D3D12 device failed with " + ds::hresult_text(hr);
        return;
    }
    hr = factory->CreateStatusArray(UINT32(D3d12Device::kPackReads), "FactorIA game.pak (GPU)", ds::kIidStatusArray,
                                    p.status.put());
    if (FAILED(hr) || !p.status) {
        p.status.reset();
        p.why = "IDStorageFactory::CreateStatusArray failed with " + ds::hresult_text(hr);
        return;
    }
    hr = device->CreateFence(0, D3D12_FENCE_FLAG_NONE, __uuidof(ID3D12Fence), p.fence.put_void());
    if (FAILED(hr) || !p.fence) {
        p.why = "ID3D12Device::CreateFence (DirectStorage's) failed with " + hr_text(hr);
        return;
    }
    p.event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (!p.event) p.why = "CreateEventW failed (error " + std::to_string(GetLastError()) + ")";
}

// DirectStorage's handle of the pack's file, opened on its first read (and while the pack lives).
ds::File* direct_file(D3d12Device::PackReads& p, const std::shared_ptr<const PackReader>& pack,
                      const std::filesystem::path& file, std::string& why) {
    p.files.erase(std::remove_if(p.files.begin(), p.files.end(),
                                 [](const D3d12Device::PackReads::OpenFile& f) {
                                     if (!f.pack.expired()) return false;
                                     if (f.file) f.file->Close();
                                     return true;
                                 }),
                  p.files.end());
    for (const auto& f : p.files)
        if (f.pack.lock() == pack) return f.file.get();
    std::string factoryWhy;
    ds::Factory* factory = fa::detail::direct_storage_factory(factoryWhy);
    if (!factory) {
        why = factoryWhy;
        return nullptr;
    }
    D3d12Device::PackReads::OpenFile f;
    f.pack = pack;
    const HRESULT hr = factory->OpenFile(file.c_str(), ds::kIidFile, f.file.put());
    if (FAILED(hr) || !f.file) {
        why = "IDStorageFactory::OpenFile failed with " + ds::hresult_text(hr);
        return nullptr;
    }
    p.files.push_back(std::move(f));
    return p.files.back().file.get();
}

}  // namespace
#endif

// ---- starting a read ------------------------------------------------------------------------------------------------

namespace {

// Why a range cannot go to DirectStorage ("" when it can), from its layout alone.
std::string layout_why(const PackReader::RangeLayout& l) {
    if (l.packFile.empty()) return "the pack was opened from memory";
    if (l.blocks.empty()) return "the pack has no blocks (format 1)";
    if (l.codec != Codec::GDeflate && l.codec != Codec::Store)
        return "its files are stored with " + std::string(codec_name(l.codec)) + " (DirectStorage reads gdeflate)";
    return {};
}

std::vector<fa::detail::DirectRequest> plan_of(const PackReader::RangeLayout& l) {
    std::vector<fa::detail::DirectBlock> blocks;
    blocks.reserve(l.blocks.size());
    for (const auto& b : l.blocks) blocks.push_back(fa::detail::DirectBlock{b.offset, b.stored, b.raw});
    const std::uint64_t base = l.firstBlock * l.blockSize;
    return fa::detail::plan_direct_requests(blocks, l.blockSize, l.fileSize - base, l.offset - base, l.size);
}

}  // namespace

Result<PackReadTicket> D3d12Device::read_pack_to_buffer(const PackSource& src, Buffer buffer, std::size_t dstOffset) {
    const std::string where = "gpu d3d12: read_pack_to_buffer of '" + src.path + "'";
    if (!src.pack) return make_error(where + ": no pack", "PackSource::pack is the PackReader the file is in");
    std::size_t size = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = buffer_tracked(buffer, &size, &label);
    if (!t)
        return make_error(where + ": buffer " + std::to_string(buffer.id) +
                              " is not a live buffer (destroyed, failed, or another device's)",
                          "read into a buffer this device made, before destroy_buffer()");
    auto layout = src.pack->range_layout(src.path, src.offset, src.size);
    if (!layout) return layout.error();
    const PackReader::RangeLayout& l = layout.value();
    if (src.size == 0 || l.size != src.size)
        return make_error(where + ": " + std::to_string(src.size) + " bytes from offset " + std::to_string(src.offset) +
                              (src.size == 0 ? " is no read" : " go past the file's " + std::to_string(l.fileSize) +
                                                                   " bytes"),
                          "read at least one byte, inside the file (PackReader::size_of gives its size)");
    if (dstOffset > size || src.size > size - dstOffset)
        return make_error(where + ": " + std::to_string(src.size) + " bytes at offset " + std::to_string(dstOffset) +
                              " go past the end of buffer '" + label + "' (" + std::to_string(size) + " bytes)",
                          "make the buffer bigger, or read less");
    const auto requests = plan_of(l);
    if (requests.size() > fa::detail::kDirectGpuReadRequests)
        return make_error(where + ": " + std::to_string(src.size) + " bytes span " + std::to_string(requests.size()) +
                              " blocks, more than one read takes (" +
                              std::to_string(fa::detail::kDirectGpuReadRequests) + ")",
                          "read the file in parts of at most " +
                              std::to_string(fa::detail::kDirectGpuReadRequests * (l.blockSize >> 10) >> 10) +
                              " MiB");
    if (!packReads_) packReads_ = std::make_shared<PackReads>();
    PackReads& p = *packReads_;
    PackRead* r = nullptr;
    for (PackRead& candidate : p.reads)
        if (candidate.stage == PackRead::Stage::Free) {
            r = &candidate;
            break;
        }
    if (!r) return PackReadTicket{};  // every slot is busy: ask again next frame
    *r = PackRead{};
    r->src = src;
    r->what = "read_pack_to_buffer";
    r->tracked = std::move(t);
    r->label = label;
    r->dstOffset = dstOffset;
    for (const auto& b : l.blocks) r->storedBytes += b.stored;

    std::string why = layout_why(l);
#if defined(_WIN64)
    if (why.empty()) {
        if (!p.tried) setup_direct(p, device_.get());
        why = p.why;
    }
    const auto split = fa::detail::split_direct_buffer(requests);
    if (why.empty() && split.gpu.empty()) why = "-";  // the range holds no whole block: the CPU reads it, no warning
    ds::File* file = nullptr;
    if (why.empty()) {
        file = direct_file(p, src.pack, l.packFile, why);
        if (!file) p.why = why;  // the runtime is there but cannot open packs: no further tries
    }
    if (why.empty()) {
        ID3D12Resource* res = r->tracked->resource.get();
        for (std::size_t i : split.gpu) {
            const fa::detail::DirectRequest& q = requests[i];
            ds::Request req;
            req.compressionFormat = q.compressed ? ds::kFormatGDeflate : ds::kFormatNone;
            req.sourceFile = file;
            req.sourceOffset = q.fileOffset;
            req.sourceSize = q.storedSize;
            ds::set_destination(req, ds::kDestinationBuffer,
                                ds::BufferDestination{res, dstOffset + q.outOffset, q.decodedSize});
            req.uncompressedSize = q.decodedSize;
            r->requests.push_back(req);
        }
        r->directBlocks = r->requests.size();
        // The partial blocks: decoded on the CPU now, uploaded by stage 1.
        for (const auto& part : split.cpu) {
            auto bytes = src.pack->read_range(src.path, src.offset + part.outOffset, part.length);
            if (!bytes) {
                *r = PackRead{};
                return bytes.error();
            }
            r->partial.insert(r->partial.end(), bytes.value().begin(), bytes.value().end());
            r->partialParts.push_back(part);
        }
        r->direct = true;
    }
#else
    if (why.empty()) why = "DirectStorage needs a 64-bit build";
#endif
    if (!why.empty() && why != "-")
        warn_once(p.warned, why,
                  "gpu d3d12: pack reads into buffers and textures are decoded on the CPU and uploaded, DirectStorage "
                  "does not write them: " +
                      why);
    return start_pack_read(*r, r->what);
}

Result<PackReadTicket> D3d12Device::read_pack_to_image(const PackSource& src, Image image,
                                                       const PackImageRegion& region) {
    const std::string where = "gpu d3d12: read_pack_to_image of '" + src.path + "'";
    if (!src.pack) return make_error(where + ": no pack", "PackSource::pack is the PackReader the file is in");
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error(where + ": image " + std::to_string(image.id) +
                              " is not a live image (destroyed, failed, or another device's)",
                          "read into an image this device made, before destroy_image()");
    const std::string into = where + " into image '" + rec.label + "'";
    if (rec.samples > 1 || pixel_format_depth(rec.format))
        return make_error(into + ": a " + (rec.samples > 1 ? std::string("multisampled") : "depth") +
                              " image takes no texels from a file",
                          "read into a single-sampled colour image");
    const bool is3d = rec.type == ImageType::Tex3d;
    if (region.mip < 0 || region.mip >= rec.mips)
        return make_error(into + ": mip " + std::to_string(region.mip) + " is outside its " + std::to_string(rec.mips) +
                              " levels",
                          "read into a mip level from 0 to numMipmaps - 1");
    const std::uint32_t mip = std::uint32_t(region.mip);
    const std::uint32_t mw = mip_extent(rec.width, region.mip), mh = mip_extent(rec.height, region.mip);
    const std::uint32_t layers = is3d ? mip_extent(rec.slices, region.mip) : std::uint32_t(rec.slices);
    if (region.layer < 0 || std::uint32_t(region.layer) >= layers)
        return make_error(into + ": slice " + std::to_string(region.layer) + " is outside its " +
                              std::to_string(layers) + " slices at mip " + std::to_string(region.mip),
                          "read into a slice from 0 to the image's slice count - 1");
    if (region.x < 0 || region.y < 0 || region.width < 1 || region.height < 1 || std::uint32_t(region.x) >= mw ||
        std::uint32_t(region.y) >= mh || std::uint32_t(region.width) > mw - std::uint32_t(region.x) ||
        std::uint32_t(region.height) > mh - std::uint32_t(region.y))
        return make_error(into + ": the rectangle (" + std::to_string(region.x) + ", " + std::to_string(region.y) +
                              ", " + std::to_string(region.width) + "x" + std::to_string(region.height) +
                              ") is empty or outside its " + std::to_string(mw) + "x" + std::to_string(mh) + " mip " +
                              std::to_string(region.mip),
                          "read inside the image's size");
    const std::uint32_t x = std::uint32_t(region.x), y = std::uint32_t(region.y);
    const std::uint32_t w = std::uint32_t(region.width), h = std::uint32_t(region.height);
    if (pixel_format_compressed(rec.format) &&
        (x % 4 || y % 4 || (w % 4 && x + w != mw) || (h % 4 && y + h != mh)))
        return make_error(into + ": the rectangle (" + std::to_string(x) + ", " + std::to_string(y) + ", " +
                              std::to_string(w) + "x" + std::to_string(h) + ") is not whole 4x4 blocks of " +
                              pixel_format_name(rec.format),
                          "start it on a multiple of 4 and make its size a multiple of 4 (or reach the mip's edge)");
    const std::uint32_t rowBytes = texel_row_bytes(rec.format, w), rows = texel_rows(rec.format, h);
    const std::uint64_t need = fa::detail::direct_texture_bytes(rowBytes, rows);
    auto layout = src.pack->range_layout(src.path, src.offset, src.size);
    if (!layout) return layout.error();
    const PackReader::RangeLayout& l = layout.value();
    if (src.size != need || l.size != src.size)
        return make_error(into + ": the range has " + std::to_string(src.size) + " bytes" +
                              (l.size != src.size ? " (past the file's " + std::to_string(l.fileSize) + " bytes)"
                                                  : std::string()) +
                              ", the region needs " + std::to_string(need) + " (" + std::to_string(rows) +
                              " rows of " + std::to_string(rowBytes) + " bytes, " +
                              std::to_string(fa::detail::direct_texture_pitch(rowBytes)) +
                              " bytes apart, the last one unpadded)",
                          "store the region in the pack as D3D12's copyable footprint (rows 256-byte aligned) and read "
                          "exactly its bytes");
    const auto requests = plan_of(l);
    if (requests.size() > fa::detail::kDirectGpuReadRequests)
        return make_error(into + ": the region spans " + std::to_string(requests.size()) +
                              " blocks, more than one read takes (" +
                              std::to_string(fa::detail::kDirectGpuReadRequests) + ")",
                          "read the region in parts (rows from y)");
    if (!packReads_) packReads_ = std::make_shared<PackReads>();
    PackReads& p = *packReads_;
    PackRead* r = nullptr;
    for (PackRead& candidate : p.reads)
        if (candidate.stage == PackRead::Stage::Free) {
            r = &candidate;
            break;
        }
    if (!r) return PackReadTicket{};  // every slot is busy: ask again next frame
    *r = PackRead{};
    r->src = src;
    r->what = "read_pack_to_image";
    r->image = true;
    r->tracked = rec.tracked;
    r->label = rec.label;
    r->format = rec.format;
    r->is3d = is3d;
    r->mip = mip;
    r->layer = std::uint32_t(region.layer);
    r->sub = rec.tracked->subresource(mip, is3d ? 0 : r->layer, 0);
    r->x = x;
    r->y = y;
    r->width = w;
    r->height = h;
    r->rowBytes = rowBytes;
    r->rows = rows;
    for (const auto& b : l.blocks) r->storedBytes += b.stored;

    std::string why = layout_why(l);
#if defined(_WIN64)
    if (why.empty()) {
        if (!p.tried) setup_direct(p, device_.get());
        why = p.why;
    }
    std::vector<fa::detail::DirectRowSpan> spans;
    if (why.empty()) {
        spans = fa::detail::plan_direct_texture_rows(requests, rowBytes, rows);
        if (spans.empty())
            why = "a texture region's rows do not fill whole pack blocks (rows of a multiple of 256 bytes do, and so "
                  "does a region in one block that starts it)";
    }
    ds::File* file = nullptr;
    if (why.empty()) {
        file = direct_file(p, src.pack, l.packFile, why);
        if (!file) p.why = why;
    }
    if (why.empty()) {
        // Rows of a compressed format are rows of 4x4 blocks: 4 texel rows each, the last one clamped to the region.
        const std::uint32_t texelRows = pixel_format_compressed(rec.format) ? 4u : 1u;
        for (std::size_t i = 0; i < requests.size(); ++i) {
            const fa::detail::DirectRequest& q = requests[i];
            ds::TextureRegionDestination d;
            d.resource = r->tracked->resource.get();
            d.subresource = r->sub;
            d.region.left = x;
            d.region.right = x + w;
            d.region.top = y + spans[i].firstRow * texelRows;
            d.region.bottom = std::min(y + h, y + (spans[i].firstRow + spans[i].rowCount) * texelRows);
            d.region.front = is3d ? r->layer : 0;
            d.region.back = d.region.front + 1;
            ds::Request req;
            req.compressionFormat = q.compressed ? ds::kFormatGDeflate : ds::kFormatNone;
            req.sourceFile = file;
            req.sourceOffset = q.fileOffset;
            req.sourceSize = q.storedSize;
            ds::set_destination(req, ds::kDestinationTextureRegion, d);
            req.uncompressedSize = q.decodedSize;
            r->requests.push_back(req);
        }
        r->directBlocks = r->requests.size();
        r->direct = true;
    }
#else
    if (why.empty()) why = "DirectStorage needs a 64-bit build";
#endif
    if (!why.empty())
        warn_once(p.warned, why,
                  "gpu d3d12: pack reads into buffers and textures are decoded on the CPU and uploaded, DirectStorage "
                  "does not write them: " +
                      why);
    return start_pack_read(*r, r->what);
}

Result<PackReadTicket> D3d12Device::start_pack_read(PackRead& r, const char* what) {
    PackReads& p = *packReads_;
    if (!r.direct) {
        cpu_pack_read(r);
        if (r.stage == PackRead::Stage::Free) {  // the CPU read failed before anything ran
            const std::string error = r.result.error;
            r = PackRead{};
            return make_error(error, "see errors() and the log");
        }
    } else {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();  // initial data and uploads go first
        D3d12CommandList* list = acquire_list("fa-d3d12-pack-read", true);
        if (!list) {
            r = PackRead{};
            return make_error(std::string("gpu d3d12: ") + what + ": no command list",
                              "see errors() for D3D12's reason");
        }
        if (r.image) {
            list->require(r.tracked, r.sub, D3D12_RESOURCE_STATE_COMMON);  // DirectStorage writes a COMMON texture
        }
#if defined(_WIN64)
        std::size_t at = 0;
        for (const auto& part : r.partialParts) {
            const UploadAlloc a = upload(part.length, 16, list);
            if (!a.ok()) break;  // reported; the read still ends (its partial bytes are missing: errors() says why)
            std::memcpy(a.cpu, r.partial.data() + at, part.length);
            list->require(r.tracked, 0, D3D12_RESOURCE_STATE_COPY_DEST);
            list->flush_barriers();
            list->native()->CopyBufferRegion(r.tracked->resource.get(), r.dstOffset + part.outOffset, a.resource,
                                          a.offset, part.length);
            at += part.length;
        }
        r.partial.clear();
        r.partial.shrink_to_fit();
#endif
        list->empty_ = false;
        const std::uint64_t before = fenceValue_;
        execute(*list);
        if (list->fence_ <= before) {
            r = PackRead{};
            return make_error(std::string("gpu d3d12: ") + what + ": the list before DirectStorage could not be "
                                  "submitted" + removed_reason(),
                              "see errors() for D3D12's reason");
        }
        r.graphicsFence = list->fence_;
        r.stage = PackRead::Stage::Graphics;
        collect();
    }
    if (++p.generation == 0) ++p.generation;  // 0 names no ticket
    r.generation = p.generation;
    const int slot = int(&r - p.reads.data());
    pump_pack_reads();
    return PackReadTicket{slot, r.generation};
}

void D3d12Device::cpu_pack_read(PackRead& r) {
    PackReads& p = *packReads_;
    r.direct = false;
    r.directBlocks = 0;
#if defined(_WIN64)
    r.requests.clear();
    r.partial.clear();
    r.partialParts.clear();
#endif
    const std::string where = std::string("gpu d3d12: ") + r.what + " of '" + r.src.path + "'";
    auto bytes = r.src.pack->read_range(r.src.path, r.src.offset, r.src.size);
    const bool started = r.stage != PackRead::Stage::Free;
    auto fail = [&](const std::string& error) {
        r.result.error = error;
        // A read that started (a DirectStorage read redone) ends with its error; one that did not is refused.
        r.stage = started ? PackRead::Stage::Done : PackRead::Stage::Free;
    };
    if (!bytes) return fail(where + ": " + bytes.error().to_string());
    std::lock_guard<std::mutex> lock(queueMutex_);
    flush_prelude();
    D3d12CommandList* list = acquire_list("fa-d3d12-pack-read", true);
    if (!list) return fail(where + ": no command list (see errors() for D3D12's reason)");
    bool ok = true;
    if (r.image) {
        ok = list->upload_region(r.tracked, r.format, r.is3d, r.mip, r.layer, 1, r.x, r.y, r.width, r.height,
                                 bytes.value().data(), fa::detail::direct_texture_pitch(r.rowBytes), 0);
    } else {
        const UploadAlloc a = upload(bytes.value().size(), 16, list);
        ok = a.ok();
        if (ok) {
            std::memcpy(a.cpu, bytes.value().data(), bytes.value().size());
            list->require(r.tracked, 0, D3D12_RESOURCE_STATE_COPY_DEST);
            list->flush_barriers();
            list->native()->CopyBufferRegion(r.tracked->resource.get(), r.dstOffset, a.resource, a.offset,
                                          bytes.value().size());
        }
    }
    list->empty_ = false;
    const std::uint64_t before = fenceValue_;
    execute(*list);
    if (!ok || list->fence_ <= before)
        return fail(where + ": the upload could not be " + (ok ? "submitted" : "made") + removed_reason() +
                    " (see errors() for D3D12's reason)");
    r.graphicsFence = list->fence_;
    r.stage = PackRead::Stage::Graphics;
    ++p.cpuReads;
    collect();
}

// ---- moving reads along ---------------------------------------------------------------------------------------------

void D3d12Device::pump_pack_reads() {
    if (!packReads_) return;
    PackReads& p = *packReads_;
    const std::uint64_t completed = fence_->GetCompletedValue();
    for (std::size_t i = 0; i < p.reads.size(); ++i) {
        PackRead& r = p.reads[i];
        if (r.stage == PackRead::Stage::Graphics && completed != UINT64_MAX && completed >= r.graphicsFence) {
            if (!r.direct) {
                r.result.direct = false;
                r.result.bytes = r.src.size;
                r.stage = PackRead::Stage::Done;
            }
#if defined(_WIN64)
            else if (p.room.take(r.requests.size())) {
                r.tag = ++p.nextTag;
                for (ds::Request& req : r.requests) {
                    req.cancellationTag = r.tag;
                    p.queue->EnqueueRequest(&req);
                }
                p.queue->EnqueueStatus(p.status.get(), UINT32(i));
                p.queue->EnqueueSignal(p.fence.get(), ++p.fenceValue);
                p.queue->Submit();
                r.directFence = p.fenceValue;
                r.directSince = now_ms();
                r.stage = PackRead::Stage::Direct;
            }
#endif
        }
#if defined(_WIN64)
        if (r.stage != PackRead::Stage::Direct) continue;
        if (!p.status->IsComplete(UINT32(i))) {
            const std::uint64_t waited = now_ms() - r.directSince;
            if (!r.warned && waited >= fa::detail::kDirectWarnMs) {
                FA_WARN("render", "gpu d3d12: DirectStorage has not finished a read of '{}' for {} s; still waiting",
                        r.src.path, fa::detail::kDirectWarnMs / 1000);
                r.warned = true;
            }
            if (!r.cancelled && waited >= fa::detail::kDirectGiveUpMs) {
                FA_ERROR("render", "gpu d3d12: DirectStorage has not finished a read of '{}' for {} s; cancelling it",
                         r.src.path, fa::detail::kDirectGiveUpMs / 1000);
                p.queue->CancelRequestsWithTag(~std::uint64_t(0), r.tag);
                r.cancelled = true;
            }
            continue;
        }
        // The status is written; the fence signal follows it in the queue.
        const std::uint64_t dsCompleted = p.fence->GetCompletedValue();
        if (dsCompleted == UINT64_MAX || dsCompleted < r.directFence) continue;
        p.room.give(r.requests.size());
        const HRESULT hr = p.status->GetHResult(UINT32(i));
        if (FAILED(hr)) {
            // Not this read only: the device reads packs on the CPU from now on. This one is read again that way.
            const std::string why = "DirectStorage failed with " + ds::hresult_text(hr);
            if (p.why.empty()) p.why = why;
            warn_once(p.warned, "failed",
                      "gpu d3d12: a DirectStorage read of '" + r.src.path + "' failed (" + why +
                          "); pack reads into buffers and textures are decoded on the CPU from now on");
            cpu_pack_read(r);
            continue;
        }
        {
            // The direct queue waits for DirectStorage's fence: lists submitted from now on see its writes.
            std::lock_guard<std::mutex> lock(queueMutex_);
            const HRESULT w = queue_->Wait(p.fence.get(), r.directFence);
            if (FAILED(w))
                report("gpu d3d12: ID3D12CommandQueue::Wait (DirectStorage's fence) failed with " + hr_text(w) +
                       removed_reason() + " (hint: the device was lost)");
        }
        if (fa::detail::direct_storage_verify())
            if (auto v = r.src.pack->check_stored(r.src.path, r.src.offset, r.src.size); !v)
                r.result.error = "gpu d3d12: " + std::string(r.what) + " (FA_DIRECTSTORAGE_VERIFY): " +
                                 v.error().to_string();
        r.result.direct = true;
        r.result.bytes = r.src.size;
        r.result.directBlocks = r.directBlocks;
        r.src.pack->count_external(r.src.size, r.storedBytes, r.directBlocks);
        ++p.directReads;
        p.directBlocks += r.directBlocks;
        r.requests.clear();
        r.stage = PackRead::Stage::Done;
#endif
    }
    // Released reads that finished give their slot back.
    for (PackRead& r : p.reads)
        if (r.stage == PackRead::Stage::Done && r.generation == 0) r = PackRead{};
}

bool D3d12Device::poll_pack_read(PackReadTicket ticket, PackReadResult& out, bool wait) {
    if (!packReads_ || !ticket.valid() || ticket.slot >= kPackReads) return false;
    PackReads& p = *packReads_;
    PackRead& r = p.reads[std::size_t(ticket.slot)];
    if (r.generation != ticket.generation || r.stage == PackRead::Stage::Free) return false;  // stale
    pump_pack_reads();
    const std::uint64_t start = now_ms();
    while (wait && r.stage != PackRead::Stage::Done) {
        if (now_ms() - start >= kPackWaitMs) {
            report("gpu d3d12: poll_pack_read of '" + r.src.path + "': not finished after " +
                   std::to_string(kPackWaitMs / 1000) + " s (hint: the drive or the GPU stopped answering)");
            return false;
        }
        if (r.stage == PackRead::Stage::Graphics) {
            const std::uint64_t completed = fence_->GetCompletedValue();
            if (completed != UINT64_MAX && completed >= r.graphicsFence) {
                Sleep(1);  // its list finished; it waits for room in DirectStorage's queue (other reads finishing)
            } else {
                std::lock_guard<std::mutex> lock(queueMutex_);
                if (auto w = wait_fence(r.graphicsFence, "poll_pack_read"); !w) {
                    report(w.error().to_string());
                    return false;
                }
            }
        }
#if defined(_WIN64)
        else if (r.stage == PackRead::Stage::Direct) {
            // DirectStorage signals its fence after the read's status: a short bounded wait, then the status decides.
            if (SUCCEEDED(p.fence->SetEventOnCompletion(r.directFence, p.event))) WaitForSingleObject(p.event, 100);
            else Sleep(1);
        }
#endif
        pump_pack_reads();
    }
    if (r.stage != PackRead::Stage::Done) return false;
    out = std::move(r.result);
    r = PackRead{};
    return true;
}

void D3d12Device::release_pack_read(PackReadTicket ticket) {
    if (!packReads_ || !ticket.valid() || ticket.slot >= kPackReads) return;
    PackRead& r = packReads_->reads[std::size_t(ticket.slot)];
    if (r.generation != ticket.generation) return;
    r.generation = 0;  // stale; the slot comes back once the read finished (pump_pack_reads)
    pump_pack_reads();
}

void D3d12Device::shutdown_pack_reads() {
    if (!packReads_) return;
    PackReads& p = *packReads_;
    // DirectStorage writes into this device's resources: every read it holds ends before they go.
    const std::uint64_t start = now_ms();
    for (;;) {
        pump_pack_reads();
        bool direct = false;
        for (const PackRead& r : p.reads) direct = direct || r.stage == PackRead::Stage::Direct;
        if (!direct) break;
        if (now_ms() - start >= kPackWaitMs) {
            FA_ERROR("render", "gpu d3d12: DirectStorage did not finish its reads within {} s of the device's end",
                     kPackWaitMs / 1000);
            break;
        }
#if defined(_WIN64)
        if (now_ms() - start >= fa::detail::kDirectWarnMs && p.queue)
            p.queue->CancelRequestsWithTag(0, 0);  // every request: the mask 0 matches every tag
#endif
        Sleep(1);
    }
    for (PackRead& r : p.reads) r = PackRead{};
}

void D3d12Device::pack_read_counters(D3d12Counters& c) const {
    if (!packReads_) return;
    c.packReadsDirect = packReads_->directReads;
    c.packReadsCpu = packReads_->cpuReads;
    c.packBlocksDirect = packReads_->directBlocks;
    for (const PackRead& r : packReads_->reads) c.packReadsInFlight += r.stage != PackRead::Stage::Free ? 1 : 0;
}

}  // namespace fa::gpu::d3d12
