// The plan of a DirectStorage read of game.pak (pack_direct_storage.h): pure functions, built and tested on every platform.
#include <algorithm>

#include "pack_direct_storage.h"

namespace fa::detail {

std::vector<DirectRequest> plan_direct_requests(std::span<const DirectBlock> blocks, std::uint64_t blockSize,
                                                std::uint64_t fileSize, std::uint64_t from, std::uint64_t size) {
    std::vector<DirectRequest> out;
    if (size == 0 || blockSize == 0 || from >= fileSize) return out;
    const std::uint64_t end = std::min(fileSize, from + std::min(size, fileSize - from));
    const std::uint64_t firstBlock = from / blockSize, lastBlock = (end - 1) / blockSize;
    if (lastBlock >= blocks.size())
        return out;  // an index that does not cover the file: the caller's CPU path reports it
    out.reserve(std::size_t(lastBlock - firstBlock + 1));
    for (std::uint64_t k = firstBlock; k <= lastBlock; ++k) {
        const DirectBlock& b = blocks[std::size_t(k)];
        const std::uint64_t blockStart = k * blockSize;
        const std::uint64_t blockLen = std::min(blockSize, fileSize - blockStart);
        const std::uint64_t partStart = std::max(from, blockStart), partEnd = std::min(end, blockStart + blockLen);
        DirectRequest r;
        r.block = std::uint32_t(k);
        r.fileOffset = b.offset;
        r.storedSize = b.stored;
        r.decodedSize = std::uint32_t(blockLen);
        r.compressed = !b.raw;
        r.outOffset = partStart - from;
        r.copyLength = std::uint32_t(partEnd - partStart);
        if (partStart != blockStart || partEnd != blockStart + blockLen) {
            r.scratch = k == firstBlock ? 0 : 1;
            r.copyFrom = std::uint32_t(partStart - blockStart);
        }
        out.push_back(r);
    }
    return out;
}

std::vector<DirectBatch> batch_direct_requests(std::span<const DirectRequest> requests, std::size_t maxRequests,
                                               std::uint64_t maxBytes) {
    std::vector<DirectBatch> out;
    maxRequests = std::max<std::size_t>(maxRequests, 1);
    DirectBatch cur;
    for (std::size_t i = 0; i < requests.size(); ++i) {
        const std::uint64_t bytes = requests[i].decodedSize;
        if (cur.count > 0 && (cur.count == maxRequests || cur.decodedBytes + bytes > maxBytes)) {
            out.push_back(cur);
            cur = DirectBatch{};
        }
        if (cur.count == 0) cur.first = i;
        ++cur.count;
        cur.decodedBytes += bytes;
    }
    if (cur.count > 0) out.push_back(cur);
    return out;
}

}  // namespace fa::detail
