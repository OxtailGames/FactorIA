// M73: the texture slot table of the mesh fragment shader (src/render_internal.h, kMeshFragmentViews). No GPU: these run where
// `ctest -LE gpu` does (render_postprocess_core). The same rules are static_asserts in the header; the test says them in words and
// checks the table against what the shaders and the tooling declare today.
#include <doctest.h>

#include <set>
#include <string>

#include "gpu/sokol_device.h"  // the sokol calls this test makes to check the GPU directly
#include "render_internal.h"

using namespace fa::render;

TEST_CASE("mesh slots: no phase binds more fragment texture units than GLES3 and WebGL2 guarantee") {
    for (int phase = 0; phase <= 2; ++phase) {
        CAPTURE(phase);
        CHECK(mesh_fragment_units(phase) <= 16);
        CHECK(mesh_fragment_units(phase) >= 12);  // the engine's 6, the material's 4 and the two sky cubes of today
    }
    CHECK(mesh_fragment_units(0) == 12);  // today
    CHECK(kMeshMaxFragmentUnits == 16);
}

TEST_CASE(
    "mesh slots: the material keeps views 6..9 and samplers 2..5, the new views start after the storage buffers") {
    CHECK(mesh_fragment_views_valid());
    int material = 0;
    for (int i = 0; i < kMeshFragmentViewCount; ++i) {
        const MeshFragmentView& v = kMeshFragmentViews[i];
        CAPTURE(v.name);
        CHECK(v.view < SG_MAX_VIEW_BINDSLOTS);
        CHECK(v.sampler < SG_MAX_SAMPLER_BINDSLOTS);
        CHECK(std::string(v.what).size() > 5);
        if (std::string(v.name).rfind("material texture", 0) == 0) {
            CHECK(v.view >= kMaterialFirstView);
            CHECK(v.view < kMaterialFirstView + kMaxMaterialTextures);
            CHECK(v.sampler == kMaterialFirstSampler + (v.view - kMaterialFirstView));
            ++material;
        }
        if (v.firstPhase > 0 && v.view != 14)
            CHECK(v.view >= kMeshNewViewFirst);  // the views of M73 follow the buffers 16..23
        const bool inBuffers = v.view >= kMeshBufferFirstView && v.view < kMeshBufferFirstView + 2 * kMaxMeshBuffers;
        CHECK_FALSE(inBuffers);
    }
    CHECK(material == kMaxMaterialTextures);
    CHECK(kMeshNewViewFirst == 24);
}

TEST_CASE("mesh slots: every view of a phase is unique and every name is") {
    for (int phase = 0; phase <= 2; ++phase) {
        CAPTURE(phase);
        std::set<int> views;
        for (const MeshFragmentView& v : kMeshFragmentViews)
            if (v.firstPhase <= phase && phase <= v.lastPhase) CHECK(views.insert(v.view).second);
        CHECK(int(views.size()) == mesh_fragment_units(phase));
    }
    std::set<std::string> names;
    for (const MeshFragmentView& v : kMeshFragmentViews) CHECK(names.insert(v.name).second);
}

TEST_CASE("mesh slots: the screen slot (view 28) is read with texelFetch through the nearest sampler, never a "
          "filtering one") {
    // An unfilterable image (the RGBA32F prepass) cannot be paired with the filtering sampler 10: the slot uses the shadow map's nearest
    // sampler 1, as the light data texture does (M73.2c). M73.6b reads the opaque colour through the same sampler, bilinear by hand.
    bool found = false;
    for (const MeshFragmentView& v : kMeshFragmentViews)
        if (std::string(v.name) == "fa_screen_tex") {
            found = true;
            CHECK(v.view == 28);
            CHECK(v.sampler == 1);
            CHECK(v.firstPhase == 1);
        }
    CHECK(found);
    CHECK(mesh_fragment_units(1) <= kMeshMaxFragmentUnits);
}
