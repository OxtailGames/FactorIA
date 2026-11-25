// The GLSL text of the built-in shaders (M78): the generated headers keep the OpenGL dialects as zstd frames and
// engine/render/src/shader_text.h decodes them on first use (tools/shaders/shader_pack). This file sees every packed header at once
// (shader_text_index.h, written by tools/shaders/compile_shaders.sh: it defines FA_SHADER_TEXT_CHECK, so the frames and their tables
// are there on any backend, and SOKOL_GLES3 and SOKOL_GLCORE, so the shader_desc functions of the two OpenGL dialects exist). It needs no GPU.
#include <doctest.h>

#include <atomic>
#include <cstdint>
#include <cstring>
#include <set>
#include <span>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/compress.h"
#include "shader_text.h"
#include "shader_text_index.h"

namespace {

using fa::shader_text::Entry;
using fa::shader_text::Pack;
using fa::shader_text::Texts;

const Entry* find_entry(const std::string& name) {
    for (const Texts* texts : kShaderTexts)
        for (std::size_t i = 0; i < texts->count; ++i)
            if (name == texts->entries[i].name) return &texts->entries[i];
    return nullptr;
}

const Texts* find_texts(const std::string& label) {
    for (const Texts* texts : kShaderTexts)
        if (label == texts->label) return texts;
    return nullptr;
}

}  // namespace

// Declared in glsl_source.h: the tests that read a shader's GLSL ES text (highp checks) get it from the frames.
std::string glsl_source_from_header(const std::string& headerName, const std::string& key) {
    std::string name = key;
    if (!name.empty() && name.back() == '[') name.pop_back();
    const std::string base = headerName.substr(0, headerName.find('.'));
    const Texts* texts = find_texts(base + ".glsl300es");
    if (!texts) return {};
    for (std::size_t i = 0; i < texts->count; ++i) {
        const Entry& e = texts->entries[i];
        if (name != e.name) continue;
        const char* all = fa::shader_text::decoded(*texts->pack);
        return all ? std::string(all + e.offset, e.size - 1) : std::string();
    }
    return {};
}

TEST_CASE("shader text: every packed text decodes to the bytes sokol-shdc wrote (the hash taken when the header was generated)") {
    REQUIRE(std::size(kShaderTexts) > 40);  // 32 headers, two dialects (hiz: desktop GL only)
    std::size_t texts = 0;
    for (const Texts* t : kShaderTexts) {
        CAPTURE(t->label);
        const char* all = fa::shader_text::decoded(*t->pack);
        REQUIRE(all != nullptr);
        // The entries tile the decoded pack: each one starts where the one before ended, with a NUL last.
        std::size_t next = 0;
        for (std::size_t i = 0; i < t->count; ++i) {
            const Entry& e = t->entries[i];
            CAPTURE(e.name);
            CHECK(e.offset == next);
            REQUIRE(e.size > 1);
            REQUIRE(e.offset + e.size <= t->pack->textSize);
            CHECK(all[e.offset + e.size - 1] == '\0');
            CHECK(std::strlen(all + e.offset) == e.size - 1);
            CHECK(fa::shader_text::fnv1a64(all + e.offset, e.size) == e.hash);
            next = e.offset + e.size;
            ++texts;
        }
        CHECK(next == t->pack->textSize);
        // It is GLSL of the dialect its name says.
        const bool es = std::string(t->label).find("glsl300es") != std::string::npos;
        CHECK(std::strncmp(all, es ? "#version 300 es" : "#version 430", es ? 15 : 12) == 0);
    }
    CHECK(texts > 100);
}

TEST_CASE("shader text: a text is decoded once and the same pointer comes back") {
    const Texts* mesh = find_texts("mesh.glsl300es");
    REQUIRE(mesh != nullptr);
    const char* first = fa::shader_text::get(*mesh->pack, mesh->entries[0].offset);
    const char* second = fa::shader_text::get(*mesh->pack, mesh->entries[0].offset);
    CHECK(first == second);
    const std::size_t decoded = fa::shader_text::decoded_count();
    for (std::size_t i = 0; i < mesh->count; ++i) CHECK(fa::shader_text::get(*mesh->pack, mesh->entries[i].offset) != nullptr);
    CHECK(fa::shader_text::decoded_count() == decoded);  // the other texts of the pack were already there
    // A copy of the frame (another translation unit's copy of the header) is the same pack.
    std::vector<std::uint8_t> copy(mesh->pack->frame, mesh->pack->frame + mesh->pack->frameSize);
    const Pack other{copy.data(), copy.size(), mesh->pack->textSize};
    CHECK(fa::shader_text::get(other, mesh->entries[0].offset) == first);
    CHECK(fa::shader_text::decoded_count() == decoded);
    // An offset past the end is an empty string, never a read past the buffer.
    CHECK(std::string(fa::shader_text::get(*mesh->pack, mesh->pack->textSize)).empty());
}

TEST_CASE("shader text: threads asking for the same new text get one decode and one pointer") {
    std::string text = "#version 300 es\nvoid main() {}\n";
    for (int i = 0; i < 200; ++i) text += "// a line of a made-up shader, number " + std::to_string(i) + "\n";
    fa::CompressOptions options;
    options.codec = fa::Codec::Zstd;
    auto frame = fa::compress(std::span<const std::uint8_t>(reinterpret_cast<const std::uint8_t*>(text.c_str()), text.size() + 1), options);
    REQUIRE(bool(frame));
    const Pack pack{frame->data(), frame->size(), text.size() + 1};
    const std::size_t before = fa::shader_text::decoded_count();
    std::vector<const char*> seen(4, nullptr);
    std::vector<std::thread> threads;
    for (std::size_t i = 0; i < seen.size(); ++i) threads.emplace_back([&, i] { seen[i] = fa::shader_text::get(pack, 0); });
    for (std::thread& t : threads) t.join();
    for (const char* s : seen) CHECK(s == seen[0]);
    CHECK(text == seen[0]);
    CHECK(fa::shader_text::decoded_count() == before + 1);
}

TEST_CASE("shader text: a damaged frame gives an empty string, not a crash") {
    const Texts* blit = find_texts("blit.glsl300es");
    REQUIRE(blit != nullptr);
    std::vector<std::uint8_t> bad(blit->pack->frame, blit->pack->frame + blit->pack->frameSize);
    bad[bad.size() / 2] ^= 0x55;
    bad.back() ^= 0xFF;
    const Pack damaged{bad.data(), bad.size(), blit->pack->textSize};
    const std::string text = fa::shader_text::get(damaged, 0);
    // The decoder either notices (an empty string) or hands back other bytes: it must never hand back the original text.
    CHECK((text.empty() || fa::shader_text::fnv1a64(text.c_str(), blit->entries[0].size) != blit->entries[0].hash));
}

TEST_CASE("shader text: what every OpenGL shader_desc hands to the driver is one of the recorded texts") {
    REQUIRE(std::size(kShaderDescs) > 30);
    std::set<std::string> seen;
    for (auto desc_fn : kShaderDescs) {
        for (sg_backend backend : {SG_BACKEND_GLES3, SG_BACKEND_GLCORE}) {
            const sg_shader_desc* desc = desc_fn(backend);
            if (!desc) continue;  // a program of the desktop dialects only (hiz)
            REQUIRE(desc->label != nullptr);
            CAPTURE(desc->label);
            const bool es = backend == SG_BACKEND_GLES3;
            for (const char* source : {desc->vertex_func.source, desc->fragment_func.source}) {
                if (!source) continue;
                REQUIRE(source[0] == '#');
                CHECK(std::strncmp(source, es ? "#version 300 es" : "#version 430", es ? 15 : 12) == 0);
                // Its hash is the one of a recorded text of the dialect, and no other text hashes the same.
                const std::size_t size = std::strlen(source) + 1;
                bool known = false;
                for (const Texts* t : kShaderTexts) {
                    if (std::string(t->label).find(es ? "glsl300es" : "glsl430") == std::string::npos) continue;
                    for (std::size_t i = 0; i < t->count; ++i)
                        known = known || (t->entries[i].size == size && t->entries[i].hash == fa::shader_text::fnv1a64(source, size));
                }
                CHECK(known);
                seen.insert(std::string(es ? "es:" : "gl:") + source);
            }
        }
    }
    CHECK(seen.size() > 60);
}

TEST_CASE("shader text: the readers of the highp tests find their text") {
    const std::string mesh = glsl_source_from_header("mesh.glsl.h", "mesh_fs_source_glsl300es[");
    CHECK(mesh.find("fa_ltc_quad") != std::string::npos);
    CHECK(glsl_source_from_header("mesh.glsl.h", "no_such_source_glsl300es").empty());
    CHECK(find_entry("mesh_fs_source_glsl300es") != nullptr);
}
