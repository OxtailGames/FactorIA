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

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/render/gi.h"
#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "hdr_encode.h"
#include "rt_effect.h"
#include "rt_gi.h"
#include "rt_kernels.h"
#include "rt_records.h"
#include "test_util.h"

using namespace fa;
using namespace fa::gpu;

namespace {

struct FrontMesh {
    std::vector<Vec3> vertices;
    std::vector<std::uint16_t> indices;
    Buffer vb{}, ib{};
    AccelStructure blas{};
    Buffer scratch{};
};

FrontMesh front_quad() {
    FrontMesh m;
    m.vertices = {{-20, 0, -20}, {20, 0, -20}, {20, 0, 20}, {-20, 0, 20}};
    m.indices = {0, 2, 1, 0, 3, 2};
    return m;
}

FrontMesh front_box() {  // [-1, 1] x [0, 2] x [-1, 1], counter-clockwise seen from outside
    FrontMesh m;
    m.vertices = {{-1, 0, -1}, {1, 0, -1}, {1, 2, -1}, {-1, 2, -1}, {-1, 0, 1}, {1, 0, 1}, {1, 2, 1}, {-1, 2, 1}};
    m.indices = {0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 4, 7, 0, 7, 3,
                 1, 2, 6, 1, 6, 5, 3, 7, 6, 3, 6, 2, 0, 1, 5, 0, 5, 4};
    return m;
}

// The back-face fraction (meta texel, red) of the two probes for one setting of the kernel's front sense and of the box's two-sided flag.
struct Fractions {
    float open = -1.0f, inside = -1.0f;
};

}  // namespace

TEST_CASE("rt gi front face: the sense of the hardware's front flag is measured, no back face is counted when it is unknown or the "
          "instance is two-sided") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("skipped: no GPU here (" << g.error << ")");
        return;
    }
    const Backend backend = built_sokol_backend();
    auto made = make_device(backend);
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    std::unique_ptr<Device> owner = std::move(made.value());
    Device& dev = *owner;
    std::string why;
    if (!dev.ray_tracing_status(&why)) {
        MESSAGE("skipped: this GPU or OS cannot trace rays: " << why);
        return;
    }
    MESSAGE("backend " << backend_name(backend) << ", vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    FrontMesh ground = front_quad(), box = front_box();
    for (FrontMesh* m : {&ground, &box}) {
        BufferDesc vb;
        vb.size = m->vertices.size() * sizeof(Vec3);
        vb.usage.accelBuildInput = true;
        vb.data = Range{m->vertices.data(), vb.size};
        vb.label = "rt gi front vertices";
        m->vb = dev.make_buffer(vb);
        BufferDesc ib;
        ib.size = m->indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m->indices.data(), ib.size};
        ib.label = "rt gi front indices";
        m->ib = dev.make_buffer(ib);
    }
    auto geometry_of = [](const FrontMesh& m) {
        AccelTriangles t{};
        t.vertexBuffer = m.vb;
        t.vertexStride = sizeof(Vec3);
        t.vertexCount = std::uint32_t(m.vertices.size());
        t.indexBuffer = m.ib;
        t.indexType = IndexType::Uint16;
        t.indexCount = std::uint32_t(m.indices.size());
        return t;
    };
    auto make_as = [&](AccelKind kind, std::uint64_t size, const char* label) {
        AccelStructureDesc d;
        d.kind = kind;
        d.size = size;
        d.label = label;
        auto r = dev.make_accel_structure(d);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        return r.value();
    };
    auto make_scratch = [&](std::uint64_t size, const char* label) {
        BufferDesc d;
        d.size = std::size_t(std::max<std::uint64_t>(size, 256));
        d.usage.accelScratch = true;
        d.label = label;
        return dev.make_buffer(d);
    };
    AccelBuildFlags flags;
    for (FrontMesh* m : {&ground, &box}) {
        const AccelTriangles t = geometry_of(*m);
        auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&t, 1), flags);
        REQUIRE_MESSAGE(bs.ok(), bs.error().message);
        m->blas = make_as(AccelKind::Blas, bs->structure, "rt gi front blas");
        m->scratch = make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt gi front blas scratch");
    }
    constexpr std::uint8_t kMask = fa::render::kRtMaskOpaque | fa::render::kRtMaskCastsShadow;
    const std::array<FrontMesh*, 2> meshes = {&ground, &box};
    const std::array<Vec3, 2> at = {Vec3{0, 0, 0}, Vec3{3.0f, 0.5f, 0}};
    std::vector<AccelInstance> instances(2);
    std::vector<fa::render::RtInstanceRecord> records(2);
    for (std::size_t i = 0; i < 2; ++i) {
        instances[i].transform[3] = at[i].x;
        instances[i].transform[7] = at[i].y;
        instances[i].transform[11] = at[i].z;
        instances[i].blas = meshes[i]->blas;
        instances[i].mask = kMask;
        instances[i].customIndex = std::uint32_t(i);
        fa::render::RtInstanceRecord& r = records[i];
        std::memset(&r, 0, sizeof r);
        r.objectToWorld[0] = r.objectToWorld[5] = r.objectToWorld[10] = 1.0f;
        r.objectToWorld[3] = at[i].x;
        r.objectToWorld[7] = at[i].y;
        r.objectToWorld[11] = at[i].z;
        r.albedo[0] = r.albedo[1] = r.albedo[2] = 0.4f;
        r.albedo[3] = 1.0f;
        r.roughness = 0.5f;
        r.flags = fa::render::kRtFlagOpaque | fa::render::kRtFlagCastsShadow;
    }
    auto ts = dev.tlas_sizes(2, flags);
    REQUIRE_MESSAGE(ts.ok(), ts.error().message);
    const AccelStructure tlas = make_as(AccelKind::Tlas, ts->structure, "rt gi front tlas");
    const Buffer tlasScratch = make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt gi front tlas scratch");

    // The records buffer (a storage buffer a compute pass reads), and a second one for the two-sided run: the box is a two-sided instance.
    auto make_records = [&](const std::vector<fa::render::RtInstanceRecord>& data, const char* label) {
        BufferDesc rbd;
        rbd.size = data.size() * sizeof(fa::render::RtInstanceRecord);
        rbd.usage.storageBuffer = true;
        rbd.label = label;
        rbd.data = Range{data.data(), rbd.size};
        const Buffer buffer = dev.make_buffer(rbd);
        ViewDesc rvd;
        rvd.storageBuffer.buffer = buffer;
        rvd.label = label;
        return dev.make_view(rvd);
    };
    const View recordsView = make_records(records, "rt gi front records");
    std::vector<fa::render::RtInstanceRecord> twoSidedRecords = records;
    twoSidedRecords[1].flags |= fa::render::kRtFlagTwoSided;
    const View twoSidedView = make_records(twoSidedRecords, "rt gi front two-sided records");

    const int atlasW = fa::render::kProbeAtlasSize, atlasH = fa::render::kProbeAtlasSize + 11 * 2;
    std::vector<std::uint16_t> atlasData(std::size_t(atlasW) * atlasH * 4, 0);
    ImageDesc ad;
    ad.width = atlasW;
    ad.height = atlasH;
    ad.pixelFormat = PixelFormat::Rgba16F;
    ad.data.mipLevels[0] = Range{atlasData.data(), atlasData.size() * sizeof(std::uint16_t)};
    ad.label = "rt gi front atlas";
    const gpu::Image atlasImg = dev.make_image(ad);
    ViewDesc atv;
    atv.texture.image = atlasImg;
    atv.label = "rt gi front atlas view";
    const View atlasView = dev.make_view(atv);
    ImageDesc od;
    od.width = fa::render::kProbeAtlasSize;
    od.height = fa::render::kGiBandHeight;
    od.pixelFormat = PixelFormat::Rgba16F;
    od.usage.storageImage = true;
    od.label = "rt gi front band";
    const gpu::Image outImg = dev.make_image(od);
    ViewDesc ov;
    ov.storageImage.image = outImg;
    ov.label = "rt gi front band view";
    const View outView = dev.make_view(ov);

    const fa::rt_kernels::RtKernel* kernel = fa::rt_kernels::find_rt_kernel("rt_gi");
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_gi");
    REQUIRE(kernel != nullptr);
    REQUIRE(spec != nullptr);
    SamplerDesc sd;
    sd.label = "rt gi front nearest";
    const Sampler sampler = dev.make_sampler(sd);
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = dev.make_shader(fa::render::rt_effect_shader_desc(*kernel, *spec, backend));
    pd.label = "rt_gi";
    const Pipeline pipeline = dev.make_pipeline(pd);
    REQUIRE(dev.state(pd.shader) == ResourceState::Valid);
    REQUIRE(dev.state(pipeline) == ResourceState::Valid);

    fa::render::RtHitParams hit{};
    hit.sunDir[1] = 1.0f;
    hit.sunColor[0] = hit.sunColor[1] = hit.sunColor[2] = 2.0f;
    hit.ambient[0] = hit.ambient[1] = hit.ambient[2] = 0.1f;
    hit.sky[2] = 0.8f;
    hit.horizon[0] = hit.horizon[1] = hit.horizon[2] = 0.6f;
    hit.limits[0] = 0.02f;
    hit.limits[1] = 0.002f;
    hit.limits[2] = 10000.0f;
    hit.limits[3] = 0.002f;

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

    bool built = false;
    auto trace = [&](float sense, View records) {
        CommandList& cl = dev.begin_commands("rt gi front frame");
        if (!built) {
            for (FrontMesh* m : {&ground, &box}) {
                BlasBuild bb;
                const AccelTriangles t = geometry_of(*m);
                bb.dst = m->blas;
                bb.geometries = std::span<const AccelTriangles>(&t, 1);
                bb.flags = flags;
                bb.scratch = m->scratch;
                auto r = cl.build_blas(bb);
                REQUIRE_MESSAGE(r.ok(), r.error().message);
            }
            built = true;
        }
        TlasBuild tb;
        tb.dst = tlas;
        tb.instances = instances;
        tb.flags = flags;
        tb.scratch = tlasScratch;
        auto bt = cl.build_tlas(tb);
        REQUIRE_MESSAGE(bt.ok(), bt.error().message);
        const fa::render::RtGiParams params = make_params(sense);
        cl.begin_compute_pass("rt gi front");
        cl.set_pipeline(pipeline);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = outView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = atlasView;
        b.views[fa::render::RtEffectBindings::kViewRecords] = records;
        if (fa::render::rt_effect_needs_sampler(backend)) b.samplers[fa::render::RtEffectBindings::kSampler] = sampler;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformParams, Range{&params, sizeof params});
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformHit, Range{&hit, sizeof hit});
        cl.dispatch(2, 1, 1);
        cl.end_pass();
        dev.submit(cl);
        dev.commit();
        std::vector<std::uint8_t> bytes;
        auto r = dev.read_storage_image(outImg, PixelFormat::Rgba16F, 0, 0, fa::render::kProbeAtlasSize,
                                        fa::render::kGiBandHeight, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        REQUIRE(bytes.size() == std::size_t(fa::render::kProbeAtlasSize) * fa::render::kGiBandHeight * 4 * sizeof(std::uint16_t));
        auto meta = [&](int probe) {  // the meta texel is texel 9 of the SH row (row 10) of the probe's block
            std::uint16_t half = 0;
            const std::size_t texel = (std::size_t(10) * fa::render::kProbeAtlasSize + std::size_t(probe * 10 + 9)) * 4;
            std::memcpy(&half, bytes.data() + texel * sizeof(std::uint16_t), sizeof half);
            return fa::render::half_to_float(half);
        };
        Fractions f;
        f.open = meta(0);
        f.inside = meta(1);
        return f;
    };

    // The sign: told "+1", the probe inside the box reads 1 when the backend's flag is set for the side of the triangle that faces the ray (as
    // Metal's is), 0 when it is set for the other side.
    const Fractions told = trace(1.0f, recordsView);
    MESSAGE("with the sense +1: back faces seen by the probe in the open " << told.open << ", inside the box " << told.inside);
    float measured = 0.0f;
    if (told.inside > 0.9f)
        measured = 1.0f;
    else if (told.inside < 0.1f)
        measured = -1.0f;
    MESSAGE("MEASURED front-face sense of " << backend_name(backend) << ": " << measured
                                           << " (rt_gi_front_sense says " << fa::render::rt_gi_front_sense(backend) << ")");
    CHECK(measured != 0.0f);  // 0.1 .. 0.9 inside a closed box would be a kernel or a scene problem
    CHECK(told.open < 0.9f);
    const float known = fa::render::rt_gi_front_sense(backend);
    if (known != 0.0f) CHECK(known == measured);
    // The opposite sense gives the opposite answer in the closed box.
    const Fractions flipped = trace(-1.0f, recordsView);
    if (measured > 0.0f)
        CHECK(flipped.inside < 0.1f);
    else if (measured < 0.0f)
        CHECK(flipped.inside > 0.9f);

    // Unknown (0): no ray counts as a back face, the probes are never discarded by a guess.
    const Fractions unknown = trace(0.0f, recordsView);
    CHECK(unknown.open == 0.0f);
    CHECK(unknown.inside == 0.0f);

    // A two-sided instance never counts as a back face, whatever the sense.
    const Fractions twoSided = trace(measured != 0.0f ? measured : 1.0f, twoSidedView);
    CHECK(twoSided.inside == 0.0f);
}
