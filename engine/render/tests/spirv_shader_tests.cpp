// The SPIR-V of the built-in shaders (M77.4): tools/shaders/compile_shaders.sh asks sokol-shdc for spirv_vk too, and the
// generated headers keep it behind `#if defined(SOKOL_VULKAN)`, so no other backend's build carries a byte of it. This file
// defines SOKOL_VULKAN for itself (declarations of sokol_gfx.h only, no backend code) the way the Vulkan backend's own
// translation unit will, and checks what that backend would read: the module's magic number and version, the set and
// binding numbers, and the entry points. It needs no GPU.
#include <doctest.h>

#include <cstddef>
#include <cstdint>
#include <string>

#define SOKOL_VULKAN
#include "sokol_gfx.h"

#include "shaders/blit.glsl.h"
#include "shaders/hiz.glsl.h"

namespace {

std::uint32_t word(const sg_range& r, std::size_t index) {
    const auto* b = static_cast<const unsigned char*>(r.ptr) + index * 4;
    return std::uint32_t(b[0]) | (std::uint32_t(b[1]) << 8) | (std::uint32_t(b[2]) << 16) | (std::uint32_t(b[3]) << 24);
}

// A SPIR-V module: the magic number, a version from 1.0 up (0x00MMmm00), a size that is whole words, and a bound.
void check_module(const sg_shader_function& f) {
    REQUIRE(f.bytecode.ptr != nullptr);
    REQUIRE(f.bytecode.size >= 20);
    CHECK(f.bytecode.size % 4 == 0);
    CHECK(word(f.bytecode, 0) == 0x07230203u);
    CHECK(word(f.bytecode, 1) >= 0x00010000u);
    CHECK(word(f.bytecode, 1) <= 0x00010600u);
    CHECK(word(f.bytecode, 3) > 0);  // the id bound
    CHECK(std::string(f.entry) == "main");
}

}  // namespace

TEST_CASE("spirv: the blit program has SPIR-V for both stages and the set and binding numbers of its resources") {
    const sg_shader_desc* desc = blit_blit_shader_desc(SG_BACKEND_VULKAN);
    REQUIRE(desc != nullptr);
    check_module(desc->vertex_func);
    check_module(desc->fragment_func);
    // Uniform blocks are in set 0 at their slot, textures and samplers in set 1 (samplers after the 32 texture bindings).
    CHECK(desc->uniform_blocks[0].spirv_set0_binding_n == 0);
    CHECK(desc->uniform_blocks[1].spirv_set0_binding_n == 1);
    CHECK(desc->views[0].texture.spirv_set1_binding_n == 0);
    CHECK(desc->samplers[0].spirv_set1_binding_n == 32);
    // A backend the generated code has no dialect for gets no description (not GLCORE: a Linux build compiles that one).
    CHECK(blit_blit_shader_desc(SG_BACKEND_DUMMY) == nullptr);
}

TEST_CASE("spirv: the Hi-Z compute program has a compute module") {
    const sg_shader_desc* desc = hiz_hiz_shader_desc(SG_BACKEND_VULKAN);
    REQUIRE(desc != nullptr);
    check_module(desc->compute_func);
    CHECK(desc->vertex_func.bytecode.ptr == nullptr);
}
