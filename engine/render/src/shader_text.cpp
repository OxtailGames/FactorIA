#include "shader_text.h"

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#include "fa/core/compress.h"
#include "fa/core/log.h"

namespace fa::shader_text {

namespace {

// What identifies a pack in the cache. The frame bytes are not kept (the generated headers' arrays live as long as the process, but a
// caller may pass a frame that goes away, and a copy of each frame, a few KB per pack and about 155 KB for all of them, would be memory
// the players pay for): two packs are the same when their sizes and BOTH of two independent 64-bit hashes of the frame agree, 128 bits
// besides the sizes. The first hash is the lookup key; a slot whose second one differs is another pack that happens to share the key.
struct Slot {
    std::size_t frameSize;
    std::size_t textSize;
    std::uint64_t check;
    std::unique_ptr<char[]> text;
};

struct Cache {
    std::mutex mutex;
    std::unordered_map<std::uint64_t, std::vector<Slot>> packs;
    std::size_t decoded = 0;
};

Cache& cache() {
    static Cache* c = new Cache;  // never destroyed: a shader made while the process exits still finds its text
    return *c;
}

std::atomic<bool> g_same_key{false};  // tests: every pack gets the same key, so the check alone tells packs apart

}  // namespace

namespace detail {

// The two hashes of the frame bytes, in one pass: FNV-1a (the key) and a rotate-xor-multiply over the same bytes (the check).
void hash_frame(const std::uint8_t* bytes, std::size_t size, std::uint64_t& key, std::uint64_t& check) {
    std::uint64_t h = 1469598103934665603ull;
    std::uint64_t k = 0x9E3779B97F4A7C15ull ^ std::uint64_t(size);
    for (std::size_t i = 0; i < size; ++i) {
        h ^= bytes[i];
        h *= 1099511628211ull;
        k = ((k << 5) | (k >> 59)) ^ bytes[i];
        k *= 0xD6E8FEB86659FD93ull;
    }
    key = h;
    check = k;
}

void set_same_key_for_test(bool same) { g_same_key.store(same); }

}  // namespace detail

const char* decoded(const Pack& pack) {
    if (!pack.frame || pack.frameSize == 0 || pack.textSize == 0) return nullptr;
    std::uint64_t key = 0, check = 0;
    detail::hash_frame(pack.frame, pack.frameSize, key, check);  // outside the lock: a few KB of hashing per pack
    key ^= std::uint64_t(pack.textSize) * 0x9E3779B97F4A7C15ull;
    if (g_same_key.load()) key = 0;
    Cache& c = cache();
    std::lock_guard lock(c.mutex);
    std::vector<Slot>& bucket = c.packs[key];
    for (const Slot& slot : bucket)
        if (slot.frameSize == pack.frameSize && slot.textSize == pack.textSize && slot.check == check)
            return slot.text.get();
    // One byte more than the texts: a string for the driver even when the frame lacked its last NUL.
    auto buffer = std::make_unique<char[]>(pack.textSize + 1);
    auto done = decompress_into(Codec::Zstd, std::span<const std::uint8_t>(pack.frame, pack.frameSize),
                                std::span<std::uint8_t>(reinterpret_cast<std::uint8_t*>(buffer.get()), pack.textSize));
    if (!done) {
        FA_ERROR("render", "the embedded GLSL text of a built-in shader is damaged: {}", done.error().message);
        if (bucket.empty()) c.packs.erase(key);
        return nullptr;
    }
    buffer[pack.textSize] = '\0';
    ++c.decoded;
    bucket.push_back(Slot{pack.frameSize, pack.textSize, check, std::move(buffer)});
    return bucket.back().text.get();
}

const char* get(const Pack& pack, std::size_t offset) {
    const char* all = decoded(pack);
    return all && offset < pack.textSize ? all + offset : "";
}

std::size_t decoded_count() {
    Cache& c = cache();
    std::lock_guard lock(c.mutex);
    return c.decoded;
}

}  // namespace fa::shader_text
