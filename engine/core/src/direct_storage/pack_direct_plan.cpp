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

DirectBufferSplit split_direct_buffer(std::span<const DirectRequest> requests) {
    DirectBufferSplit out;
    for (std::size_t i = 0; i < requests.size(); ++i) {
        const DirectRequest& r = requests[i];
        if (r.scratch < 0)
            out.gpu.push_back(i);
        else if (r.copyLength > 0)
            out.cpu.push_back({r.outOffset, r.copyLength});
    }
    return out;
}

std::uint32_t direct_texture_pitch(std::uint32_t rowBytes) {
    const std::uint64_t a = kDirectTexturePitchAlign;
    const std::uint64_t p = (std::uint64_t(rowBytes) + a - 1) / a * a;
    return p > 0xffffffffull ? 0xffffffffu : std::uint32_t(p);
}

std::uint64_t direct_texture_bytes(std::uint32_t rowBytes, std::uint32_t rows) {
    if (rows == 0 || rowBytes == 0) return 0;
    return std::uint64_t(rows - 1) * direct_texture_pitch(rowBytes) + rowBytes;
}

std::vector<DirectRowSpan> plan_direct_texture_rows(std::span<const DirectRequest> requests, std::uint32_t rowBytes,
                                                    std::uint32_t rows) {
    std::vector<DirectRowSpan> out;
    if (requests.empty() || rowBytes == 0 || rows == 0) return out;
    const std::uint64_t pitch = direct_texture_pitch(rowBytes);
    std::uint64_t nextOut = 0;
    std::uint32_t nextRow = 0;
    out.reserve(requests.size());
    for (const DirectRequest& r : requests) {
        // A request writes its whole decoded block: it must start a row and end one (the last row unpadded).
        if (r.scratch >= 0 || r.outOffset != nextOut || r.outOffset % pitch != 0 || r.decodedSize == 0) return {};
        const std::uint64_t first = r.outOffset / pitch;
        if (std::uint64_t(r.decodedSize) < rowBytes || (r.decodedSize - std::uint64_t(rowBytes)) % pitch != 0)
            return {};
        const std::uint64_t count = (r.decodedSize - std::uint64_t(rowBytes)) / pitch + 1;
        if (first != nextRow || first + count > rows) return {};
        out.push_back({std::uint32_t(first), std::uint32_t(count)});
        nextRow = std::uint32_t(first + count);
        // The next request starts the row after this block's last one: when the pitch is wider than the row, the padding
        // after this block's last row is not in any block, so only a pitch equal to the row joins two blocks.
        nextOut = r.outOffset + r.decodedSize;
        if (nextRow < rows && pitch != rowBytes) return {};
    }
    if (nextRow != rows) return {};
    return out;
}

DirectTextureBox direct_texture_box(std::uint32_t x, std::uint32_t y, std::uint32_t width, std::uint32_t height,
                                    DirectRowSpan span, bool compressed) {
    const std::uint64_t texelRows = compressed ? 4 : 1;
    auto whole = [&](std::uint64_t v) { return compressed ? (v + 3) / 4 * 4 : v; };
    auto u32 = [](std::uint64_t v) { return v > 0xffffffffull ? 0xffffffffu : std::uint32_t(v); };
    const std::uint64_t right = whole(std::uint64_t(x) + width), bottom = whole(std::uint64_t(y) + height);
    DirectTextureBox b;
    b.left = x;
    b.right = u32(right);
    b.top = u32(y + span.firstRow * texelRows);
    b.bottom = u32(std::min(bottom, y + (std::uint64_t(span.firstRow) + span.rowCount) * texelRows));
    return b;
}

}  // namespace fa::detail
