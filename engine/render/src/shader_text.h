// Private to fa_render: the GLSL source text of the built-in shaders that the generated headers keep compressed.
//
// tools/shaders/compile_shaders.sh runs sokol-shdc and then tools/shaders/shader_pack over every generated header
// (docs/design/ARCHITECTURE_RENDERING.md, "Embedded shader text"). The GLSL ES 3.00 sources (and the desktop GL ones) are
// spirv-cross output, 1.4 MB of repeating text in the web and Android players, so the header holds each one as a zstd frame
// (fa/core/compress.h, the engine's own codec) and the generated `<name>_shader_desc()` asks for the text here. The text is
// decoded the first time a shader is made and kept for the life of the process: the sg_shader_desc the header caches keeps a
// pointer to it, and a later sg_make_shader (a lost context, another device) reads the same bytes. What the GPU driver
// receives is byte for byte what sokol-shdc wrote (the generated header carries a hash of it, checked by the tests).
#pragma once

#include <cstddef>
#include <cstdint>

namespace fa::shader_text {

// The texts of one dialect of a generated header, one zstd frame (the texts one after the other, a NUL after each).
struct Pack {
    const std::uint8_t* frame;
    std::size_t frameSize;
    std::size_t textSize;  // what the frame decodes to
};

// One text of a pack as the tests list it (FA_SHADER_TEXT_CHECK in the generated headers).
struct Entry {
    const char* name;    // the array of the original header, e.g. "mesh_fs_source_glsl300es"
    std::size_t offset;  // where the text starts in the decoded pack
    std::size_t size;    // its size, with its terminating NUL
    std::uint64_t hash;  // fnv1a64 of the text, taken by shader_pack when it wrote the header
};

// A pack with its entries, e.g. mesh.glsl300es (what the render tests walk).
struct Texts {
    const char* label;
    const Pack* pack;
    const Entry* entries;
    std::size_t count;
};

// FNV-1a, 64 bits: what the generated tables record and the tests compare.
constexpr std::uint64_t fnv1a64(const char* bytes, std::size_t size) {
    std::uint64_t h = 1469598103934665603ull;
    for (std::size_t i = 0; i < size; ++i) {
        h ^= static_cast<std::uint8_t>(bytes[i]);
        h *= 1099511628211ull;
    }
    return h;
}

// The text at `offset` of the decoded `pack`, a NUL-terminated string that stays valid until the process ends. The pack is
// decoded the first time one of its texts is asked for, and the same frame bytes are decoded once however many translation
// units hold a copy of the header. Thread-safe. A damaged frame logs an error and gives an empty string, so the driver's
// compile error names the shader.
const char* get(const Pack& pack, std::size_t offset);

// The whole decoded text of a pack (the tests compare it with the hashes of the table), or null when the frame is damaged.
const char* decoded(const Pack& pack);

// How many packs have been decoded so far (tests: the cache is reused).
std::size_t decoded_count();

}  // namespace fa::shader_text
