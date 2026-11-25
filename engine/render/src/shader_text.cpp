#include "shader_text.h"

#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>

#include "fa/core/compress.h"
#include "fa/core/log.h"

namespace fa::shader_text {

namespace {

struct Cache {
    std::mutex mutex;
    // Keys are copies of the frame bytes (and the text size), so a caller's frame may go away: the same bytes are one pack.
    std::unordered_map<std::string, std::unique_ptr<char[]>> packs;
    std::size_t decoded = 0;
};

Cache& cache() {
    static Cache* c = new Cache;  // never destroyed: a shader made while the process exits still finds its text
    return *c;
}

}  // namespace

const char* decoded(const Pack& pack) {
    if (!pack.frame || pack.frameSize == 0 || pack.textSize == 0) return nullptr;
    Cache& c = cache();
    std::string key(reinterpret_cast<const char*>(pack.frame), pack.frameSize);
    key.append(reinterpret_cast<const char*>(&pack.textSize), sizeof(pack.textSize));
    std::lock_guard lock(c.mutex);
    if (auto it = c.packs.find(key); it != c.packs.end()) return it->second.get();
    // One byte more than the texts: a string for the driver even when the frame lacked its last NUL.
    auto buffer = std::make_unique<char[]>(pack.textSize + 1);
    auto done = decompress_into(Codec::Zstd, std::span<const std::uint8_t>(pack.frame, pack.frameSize),
                                std::span<std::uint8_t>(reinterpret_cast<std::uint8_t*>(buffer.get()), pack.textSize));
    if (!done) {
        FA_ERROR("render", "the embedded GLSL text of a built-in shader is damaged: {}", done.error().message);
        return nullptr;
    }
    buffer[pack.textSize] = '\0';
    ++c.decoded;
    return c.packs.emplace(key, std::move(buffer)).first->second.get();
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
