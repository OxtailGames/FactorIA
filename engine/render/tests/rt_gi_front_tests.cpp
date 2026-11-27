// M79-P4a: which side of a triangle the hardware calls its front, measured on the real device of this build (Metal, D3D12 or Vulkan), and the
// two rules of the probe kernel that depend on it (shaders/rt/rt_gi.{hlsl,metal}, rt_gi_front_sense in src/rt_gi.h).
//
// Two probes of a floor and a closed box (the scene of rt_gi_metal_tests.cpp): one in the open, one inside the box, where every ray hits the
// inside of a wall. With the kernel told "+1" (the flag is set for the counter-clockwise side that faces the ray) the probe inside reads a
// back-face fraction of 1 when the backend's flag is set for that side, and 0 when it is the other way round: that is the SIGN of the
// backend, printed by the test. It is checked against rt_gi_front_sense(backend) only when that is not 0 (0 = not measured: the kernel then
// counts no back faces, which this test checks too, as it checks that a two-sided instance never counts as a back face). A machine without
// ray tracing says so and skips; a backend whose sign has not been measured is measured here by the first Windows or Linux machine that
// runs this test (read the message of the test run, put the value in rt_gi_front_sense).
#include <doctest.h>

#include <array>
#include <cstring>
#include <string>
#include <vector>

#include "hdr_encode.h"
#include "rt_gi_test_scene.h"

using namespace fa;
using namespace fa::gpu;
using fa::test::gi::Place;
using fa::test::gi::Rig;

namespace {

// The back-face fraction (meta texel, red) of the two probes for one setting of the kernel's front sense and of the box's two-sided flag.
struct Fractions {
    float open = -1.0f, inside = -1.0f;
};

}  // namespace

TEST_CASE("rt gi front face: the sense of the hardware's front flag is measured, no back face is counted when it is "
          "unknown or the "
          "instance is two-sided") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    const Backend backend = rig.backend;
    MESSAGE("backend " << backend_name(backend) << ", vendor "
                       << std::string(gpu_vendor_name(rig.dev->info().gpu.vendor)));

    fa::test::gi::Mesh ground = fa::test::gi::make_quad(), box = fa::test::gi::make_box();
    rig.build_scene({Place{&ground, {0, 0, 0}}, Place{&box, {3.0f, 0.5f, 0}}});
    // A second records buffer for the two-sided run: the box is a two-sided instance.
    std::vector<fa::render::RtInstanceRecord> twoSidedRecords = rig.records;
    twoSidedRecords[1].flags |= fa::render::kRtFlagTwoSided;
    const View twoSidedView = rig.make_records(twoSidedRecords, "rt gi front two-sided records");
    rig.make_pipeline();

    const fa::render::RtHitParams hit = fa::test::gi::make_hit({0, 1, 0}, {2, 2, 2}, {0.1f, 0.1f, 0.1f}, {0, 0, 0.8f},
                                                               {0.6f, 0.6f, 0.6f}, 0.02f, 0.002f);

    auto make_params = [&](float sense) {
        fa::render::RtGiParams p{};
        p.grid0[0] = 0.0f;
        p.grid0[1] = 1.0f;
        p.grid0[2] = 0.0f;
        p.grid0[3] = 3.0f;
        p.grid1[0] = 2.0f;
        p.grid1[1] = 1.0f;
        p.grid1[2] = 1.0f;
        p.grid1[3] = 2.0f;
        p.grid2[1] = float(fa::render::kGiBlocksPerRow);
        p.grid2[2] = 20.0f;
        p.grid2[3] = 1.0f;
        p.grid3[1] = 0.5f;
        p.grid3[3] = 0.02f;
        p.frame[0] = 7;
        p.frame[1] = 0x1234u;
        p.frame[2] = 128;
        p.frame[3] = 2;
        p.flags[0] = sense;
        for (int j = 0; j < 2; ++j) {
            p.probe[j][0] = float(j);
            p.probe[j][1] = 1.0f;
            p.probe[j][2] = float(j * 10);
        }
        return p;
    };

    auto trace = [&](float sense, View recordsOf) {
        CommandList& cl = rig.dev->begin_commands("rt gi front frame");
        rig.record_builds(cl);
        rig.record_trace(cl, make_params(sense), hit, recordsOf, 2);
        const std::vector<std::uint16_t> halves = rig.submit_and_read(cl);
        auto meta = [&](int probe) {  // the meta texel is texel 9 of the SH row (row 10) of the probe's block
            const std::size_t texel = (std::size_t(10) * fa::render::kProbeAtlasSize + std::size_t(probe * 10 + 9)) * 4;
            return fa::render::half_to_float(halves[texel]);
        };
        Fractions f;
        f.open = meta(0);
        f.inside = meta(1);
        return f;
    };

    // The sign: told "+1", the probe inside the box reads 1 when the backend's flag is set for the side of the triangle that faces the ray (as
    // Metal's is), 0 when it is set for the other side.
    const Fractions told = trace(1.0f, rig.recordsView);
    MESSAGE("with the sense +1: back faces seen by the probe in the open " << told.open << ", inside the box "
                                                                           << told.inside);
    float measured = 0.0f;
    if (told.inside > 0.9f)
        measured = 1.0f;
    else if (told.inside < 0.1f)
        measured = -1.0f;
    MESSAGE("MEASURED front-face sense of " << backend_name(backend) << ": " << measured << " (rt_gi_front_sense says "
                                            << fa::render::rt_gi_front_sense(backend) << ")");
    // 0.1 .. 0.9 inside a closed box would be a kernel or a scene problem: say what was read, so a failure on a CI machine shows it.
    INFO("measured sense " << measured << " on " << backend_name(backend)
                           << ": with the sense +1 the probe inside the box read a back-face fraction of "
                           << told.inside << " (a value between 0.1 and 0.9 is neither side), the probe in the open "
                           << told.open);
    CHECK(measured != 0.0f);
    CHECK(told.open < 0.9f);
    const float known = fa::render::rt_gi_front_sense(backend);
    if (known != 0.0f) CHECK(known == measured);
    // The opposite sense gives the opposite answer in the closed box.
    const Fractions flipped = trace(-1.0f, rig.recordsView);
    if (measured > 0.0f)
        CHECK(flipped.inside < 0.1f);
    else if (measured < 0.0f)
        CHECK(flipped.inside > 0.9f);

    // Unknown (0): no ray counts as a back face, the probes are never discarded by a guess.
    const Fractions unknown = trace(0.0f, rig.recordsView);
    CHECK(unknown.open == 0.0f);
    CHECK(unknown.inside == 0.0f);

    // A two-sided instance never counts as a back face, whatever the sense.
    const Fractions twoSided = trace(measured != 0.0f ? measured : 1.0f, twoSidedView);
    CHECK(twoSided.inside == 0.0f);
    rig.release();
}
