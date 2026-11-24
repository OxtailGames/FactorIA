// DirectStorage reads of game.pak (M77, docs/design/ARCHITECTURE_FILES.md, "DirectStorage"): private to fa_core, and
// to fa_render's D3D12 backend, which reads pack ranges into GPU buffers and textures with the same plan and runtime
// (engine/render/src/gpu/d3d12_pack_reads_win32.cpp; render adds this folder, and only this one, to its include path).
//
// fa::PackReader hands the blocks of a gdeflate file to Microsoft's DirectStorage runtime on Windows, which reads them
// from the file and decompresses them itself into the reader's memory. Three parts:
//   - the PLAN (pack_direct_plan.cpp, every platform, pure): which requests a read of bytes [from, from + size) of a
//     file makes, where each one's bytes land (memory, a buffer, the rows of a texture region), and how they are cut
//     into batches. Doctest cases cover it everywhere.
//   - the API (dstorage_api_win32.h): the engine's own declarations of the few DirectStorage interfaces it uses.
//   - the RUNTIME (pack_direct_storage_win32.cpp, Windows x64 only): dstorage.dll loaded at run time, a queue shared by
//     the process for memory destinations, and the reads themselves.
// Elsewhere kDirectStorageBuilt is false and the inline stubs below say so: the pack reader then never asks.
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <span>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa::detail {

// ---- the plan (pure, every platform) --------------------------------------------------------------------------------

// One block of a pack file, as the index describes it.
struct DirectBlock {
    std::uint64_t offset = 0;  // its stored bytes, from the start of the pack
    std::uint32_t stored = 0;  // how many
    bool raw = false;          // stored as it is (the codec saved too little): a plain read
};

// One DirectStorage request: a block read from the pack (and decompressed, unless it is raw) into memory.
struct DirectRequest {
    std::uint32_t block = 0;        // the block's index within the file
    std::uint64_t fileOffset = 0;   // its stored bytes in the pack
    std::uint32_t storedSize = 0;   // how many
    std::uint32_t decodedSize = 0;  // what it decodes to (= storedSize for a raw block)
    bool compressed = false;        // false: a raw block, read as it is (no decompression)
    // Where the decoded block goes: -1 = straight into the caller's buffer at outOffset (the range holds the whole
    // block); 0 or 1 = into that scratch buffer (decodedSize bytes), of which [copyFrom, copyFrom + copyLength) is
    // then copied to outOffset. Only the first and the last block of a range can be partial, so two buffers suffice.
    int scratch = -1;
    std::uint64_t outOffset = 0;   // where the block's part starts in the caller's buffer
    std::uint32_t copyFrom = 0;    // scratch only: the first byte of the decoded block the range needs
    std::uint32_t copyLength = 0;  // the bytes of this block in the range (decodedSize when not scratch)
};

// The requests that read bytes [from, from + size) of a file whose blocks are `blocks` (all of them, in order; block k
// decodes to bytes [k * blockSize, min((k + 1) * blockSize, fileSize))). One request per block that holds part of the
// range, in file order. The caller has clamped the range to the file; size 0 gives none.
std::vector<DirectRequest> plan_direct_requests(std::span<const DirectBlock> blocks, std::uint64_t blockSize,
                                                std::uint64_t fileSize, std::uint64_t from, std::uint64_t size);

// Consecutive requests submitted and waited for together.
struct DirectBatch {
    std::size_t first = 0, count = 0;  // requests[first, first + count)
    std::uint64_t decodedBytes = 0;    // the sum of their decodedSize
};

// Cuts `requests` into batches of at most `maxRequests` requests (the room the queue has) and `maxBytes` decoded bytes
// (DirectStorage's staging buffer); a request larger than maxBytes alone makes a batch of one. maxRequests 0 counts as 1.
std::vector<DirectBatch> batch_direct_requests(std::span<const DirectRequest> requests, std::size_t maxRequests,
                                               std::uint64_t maxBytes);

// Room in a DirectStorage queue. Every request, status and signal or event takes one entry, and a queue made with capacity
// C holds at most C - 1 entries at once (dstorage.h: one entry always stays free to tell a full ring from an empty one).
// A submission of n requests takes n + 2 entries (its status and its event or fence signal), so a batch holds at most
// C - 3 requests. The entries come back when the submission completes.
inline constexpr std::size_t direct_queue_entries(std::size_t requests) { return requests + 2; }
class DirectQueueRoom {
public:
    explicit DirectQueueRoom(std::size_t capacity) : free_(capacity > 0 ? capacity - 1 : 0) {}
    // Takes the entries of a submission of `requests` requests: false (nothing taken) when they do not fit now.
    bool take(std::size_t requests) {
        const std::size_t n = direct_queue_entries(requests);
        if (n > free_) return false;
        free_ -= n;
        return true;
    }
    void give(std::size_t requests) { free_ += direct_queue_entries(requests); }
    std::size_t free_entries() const { return free_; }

private:
    std::size_t free_;
};

// The memory queue of the pack reader: its size and how much one batch may ask for (32 MiB is DirectStorage's default
// staging buffer).
inline constexpr std::size_t kDirectQueueCapacity = 256;
inline constexpr std::size_t kDirectBatchRequests = kDirectQueueCapacity - 3;
inline constexpr std::uint64_t kDirectBatchBytes = std::uint64_t(32) << 20;

// ---- the plan of GPU destinations (pure, every platform) ------------------------------------------------------------
// The D3D12 backend reads pack ranges into buffers and texture regions (d3d12_pack_reads_win32.cpp). Its queue is made
// with the device, so DirectStorage decompresses GDeflate on the GPU where the GPU and its driver can.

// The D3D12 queue's size, and the most requests one read into a GPU resource may make (a read of more blocks is an
// error that says to split it: 2045 blocks of 256 KiB are about 511 MiB).
inline constexpr std::size_t kDirectGpuQueueCapacity = 2048;
inline constexpr std::size_t kDirectGpuReadRequests = kDirectGpuQueueCapacity - 3;

// A read into a buffer: whole blocks decompress straight into it (DSTORAGE_REQUEST_DESTINATION_BUFFER); a block the range
// holds only part of (the first and the last) is decoded on the CPU and its part uploaded, since a request writes its
// whole decoded block.
struct DirectBufferSplit {
    std::vector<std::size_t> gpu;  // indices of the requests DirectStorage writes into the buffer
    struct CpuPart {
        std::uint64_t outOffset = 0;  // from the start of the range (= of the destination region)
        std::uint32_t length = 0;
    };
    std::vector<CpuPart> cpu;  // in range order
};
DirectBufferSplit split_direct_buffer(std::span<const DirectRequest> requests);

// A read into a texture region: DirectStorage writes a region (DSTORAGE_REQUEST_DESTINATION_TEXTURE_REGION) from bytes
// laid out as D3D12's copyable footprint: its rows (of texels, or of 4x4 blocks for a compressed format) `pitch` bytes
// apart, the pitch being the row's bytes rounded up to 256, the last row unpadded. The pack range must hold the region in
// that layout, whichever path reads it.
inline constexpr std::uint32_t kDirectTexturePitchAlign = 256;  // D3D12_TEXTURE_DATA_PITCH_ALIGNMENT
std::uint32_t direct_texture_pitch(std::uint32_t rowBytes);
// The bytes of a region of `rows` rows of `rowBytes`: (rows - 1) * pitch + rowBytes (0 for an empty region).
std::uint64_t direct_texture_bytes(std::uint32_t rowBytes, std::uint32_t rows);

// The rows of the region request i fills.
struct DirectRowSpan {
    std::uint32_t firstRow = 0, rowCount = 0;
};
// One span per request when each request is a whole block that decodes to whole rows of the footprint (the region in
// one block, or rows whose bytes are a multiple of 256 in blocks that hold whole rows) and together they cover the
// `rows` rows; empty when the region cannot be cut that way (the read then takes the CPU path).
std::vector<DirectRowSpan> plan_direct_texture_rows(std::span<const DirectRequest> requests, std::uint32_t rowBytes,
                                                    std::uint32_t rows);

// ---- the runtime (Windows x64) --------------------------------------------------------------------------------------

#if defined(_WIN32) && defined(_WIN64)
inline constexpr bool kDirectStorageBuilt = true;
#else
inline constexpr bool kDirectStorageBuilt = false;
#endif

// One read: `storedSize` bytes at `fileOffset` of the pack, decompressed (GDeflate) when `compressed`, into `dest`
// (`decodedSize` bytes, which must stay alive until direct_storage_read returns).
struct DirectIo {
    std::uint64_t fileOffset = 0;
    std::uint32_t storedSize = 0, decodedSize = 0;
    bool compressed = false;
    std::uint8_t* dest = nullptr;
};

class DirectStorageFile;  // a pack opened through DirectStorage (IDStorageFile)

// How long a read waits for DirectStorage before it warns (a drive that stalls), and before it cancels its requests and
// fails (a safety net far above any real read: the pack reader then reads on the CPU).
inline constexpr std::uint32_t kDirectWarnMs = 30'000;
inline constexpr std::uint32_t kDirectGiveUpMs = 600'000;

#if defined(_WIN32) && defined(_WIN64)
namespace dstorage {
struct Factory;
}  // namespace dstorage

// Opens `pack` for DirectStorage reads. The first call of the process loads the runtime: FA_DIRECTSTORAGE=0 turns it off,
// else dstoragecore.dll and dstorage.dll are loaded from $FA_DIRECTSTORAGE_DIR (made absolute; tests, CI) or the
// executable's folder, then its factory, one queue (memory destinations, no D3D12 device) and a status array are made.
// Null with `why` (one sentence: what was missing or failed) when any of it fails; a failed runtime is not tried again.
// DirectStorage opens the file with its own share mode, not the pack reader's (fs.h, "Windows file rules").
std::shared_ptr<DirectStorageFile> direct_storage_open(const std::filesystem::path& pack, std::string& why);
// Submits `ios` (at most kDirectBatchRequests of them) and waits until DirectStorage has finished every one. Reads of
// several threads run side by side: each has its own status entry and event, and the queue's lock is held only while
// it enqueues and submits. The error names the HRESULT; the destinations hold anything on failure. A read that has not
// finished after kDirectGiveUpMs is cancelled and fails once DirectStorage confirms it (it never returns while
// DirectStorage may still write into `ios`).
Result<void> direct_storage_read(DirectStorageFile& file, std::span<const DirectIo> ios);
// The runtime loads (see direct_storage_open), or why not. Tests use it to skip.
Result<void> direct_storage_available();
// The process's factory (the runtime loaded as direct_storage_open does): the D3D12 backend makes its own queue with it.
// Null with `why` when the runtime did not load.
dstorage::Factory* direct_storage_factory(std::string& why);
// FA_DIRECTSTORAGE_VERIFY=1: after DirectStorage decompressed a block, its stored bytes are also read and checked
// against the block's checksum, as the CPU path checks them (debugging a pack; doubles the reads).
bool direct_storage_verify();
// DirectStorage's own CPU GDeflate codec (IDStorageCompressionCodec): the test vectors are checked with it.
Result<std::vector<std::uint8_t>> direct_storage_decompress(std::span<const std::uint8_t> stream, std::size_t size);
Result<std::vector<std::uint8_t>> direct_storage_compress(std::span<const std::uint8_t> data);
#else
inline std::shared_ptr<DirectStorageFile> direct_storage_open(const std::filesystem::path&, std::string& why) {
    why = "DirectStorage exists on 64-bit Windows only";
    return nullptr;
}
inline Result<void> direct_storage_read(DirectStorageFile&, std::span<const DirectIo>) {
    return Error{"DirectStorage exists on 64-bit Windows only", ""};
}
inline bool direct_storage_verify() { return false; }
#endif

}  // namespace fa::detail
