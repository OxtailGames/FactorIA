// The generated ray tracing kernel headers (engine/render/src/shaders/rt/*.rt.h, tools/shaders/compile_rt_shaders.sh): every
// kernel has a signed DXIL container, a SPIR-V module that uses ray queries and a Metal text of its own kernel function. No GPU is
// needed; the repository-level checks (the headers match their sources, DXC's version equals the pin) are in the tooling tests
// (tools/common/tests/rt_shaders_test.cpp).
#include <doctest.h>

#include <cstdint>
#include <cstring>
#include <string>

#include "rt_effect.h"
#include "rt_kernels.h"

using namespace fa::rt_kernels;

TEST_CASE("rt kernels: every kernel has DXIL, SPIR-V with ray query and MSL") {
    REQUIRE(!all_rt_kernels().empty());
    for (const RtKernel& k : all_rt_kernels()) {
        CAPTURE(std::string(k.name));
        REQUIRE(k.dxil.size() > 64);
        CHECK(std::memcmp(k.dxil.data(), "DXBC", 4) ==
              0);  // the container DXC wraps DXIL in (with the signature the driver checks)
        const std::string dxilText(reinterpret_cast<const char*>(k.dxil.data()), k.dxil.size());
        CHECK(dxilText.find("DXIL") != std::string::npos);

        REQUIRE(k.spirv.size() > 20);
        CHECK(k.spirv.size() % 4 == 0);
        std::uint32_t magic = 0;
        std::memcpy(&magic, k.spirv.data(),
                    4);  // SPIR-V words are little endian in the blob; every host the engine runs on is too
        CHECK(magic == 0x07230203u);
        // OpCapability (opcode 17, two words) RayQueryKHR (4472): the kernel is a ray query one.
        bool rayQuery = false;
        for (std::size_t i = 5 * 4; i + 8 <= k.spirv.size(); i += 4) {
            std::uint32_t w0 = 0, w1 = 0;
            std::memcpy(&w0, k.spirv.data() + i, 4);
            std::memcpy(&w1, k.spirv.data() + i + 4, 4);
            if (w0 == ((2u << 16) | 17u) && w1 == 4472u) rayQuery = true;
        }
        // A kernel that only reads images (the soft shadow's pack pass, spec usesTlas = false) has no ray query.
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec(k.name);
        const bool traces = !spec || spec->usesTlas;
        CHECK(rayQuery == traces);

        CHECK(k.msl.find("kernel void " + std::string(k.name)) != std::string::npos);
        CHECK((k.msl.find("intersection_query") != std::string::npos) == traces);
        CHECK(k.msl.back() == '\n');
        CHECK(!k.dxcVersion.empty());
        CHECK(k.hlslSha256.size() == 64);
        CHECK(k.mslSha256.size() == 64);
    }
    CHECK(find_rt_kernel("rt_probe") != nullptr);
    CHECK(find_rt_kernel("no_such_kernel") == nullptr);
}
