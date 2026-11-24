// DirectStorage reads of game.pak (M77, docs/design/ARCHITECTURE_FILES.md, "DirectStorage"): private to fa_core.
//
// fa::PackReader hands the blocks of a gdeflate file to Microsoft's DirectStorage runtime on Windows, which reads them
// from the file and decompresses them itself into the reader's memory. Two parts:
//   - the PLAN (pack_direct_plan.cpp, every platform, pure): which requests a read of bytes [from, from + size) of a
//     file makes, where each one's bytes land, and how they are cut into batches. A doctest case covers it everywhere.
//   - the RUNTIME (pack_direct_storage_win32.cpp, Windows x64 only): dstorage.dll loaded at run time with the engine's
//     own declarations of the few interfaces it uses, a queue shared by the process, and the reads themselves.
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

// The queue's size and how much one batch may ask for: the queue holds the batch's requests plus its status and event
// entries; 32 MiB is DirectStorage's default staging buffer.
inline constexpr std::size_t kDirectQueueCapacity = 256;
inline constexpr std::size_t kDirectBatchRequests = kDirectQueueCapacity - 2;
inline constexpr std::uint64_t kDirectBatchBytes = std::uint64_t(32) << 20;

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

#if defined(_WIN32) && defined(_WIN64)
// Opens `pack` for DirectStorage reads. The first call of the process loads the runtime: FA_DIRECTSTORAGE=0 turns it off,
// else dstoragecore.dll and dstorage.dll are loaded from $FA_DIRECTSTORAGE_DIR (tests, CI) or the executable's folder,
// then its factory, one queue (memory destinations, no D3D12 device) and a status array are made. Null with `why` (one
// sentence: what was missing or failed) when any of it fails; a failed runtime is not tried again.
std::shared_ptr<DirectStorageFile> direct_storage_open(const std::filesystem::path& pack, std::string& why);
// Submits `ios` (at most kDirectBatchRequests of them) and waits until DirectStorage has finished every one. Reads of the
// process take turns (one batch at a time). The error names the HRESULT; the destinations hold anything on failure.
Result<void> direct_storage_read(DirectStorageFile& file, std::span<const DirectIo> ios);
// The runtime loads (see direct_storage_open), or why not. Tests use it to skip.
Result<void> direct_storage_available();
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
#endif

}  // namespace fa::detail
