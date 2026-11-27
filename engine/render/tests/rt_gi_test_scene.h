// The small ray traced scene the probe kernel's real-device tests share (rt_gi_metal_tests.cpp, rt_gi_front_tests.cpp): a device that traces,
// two meshes (a floor and a closed box) in bottom level structures, their instances and records, the top level structure, a zero atlas the
// multi-bounce reads, the band image the kernel writes, the `rt_gi` pipeline, and the recording of one dispatch with its read-back. Header
// only: every test file that includes it is one translation unit of fa_test_render.
#pragma once

#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <memory>
#include <span>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/render/gi.h"
#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "rt_effect.h"
#include "rt_gi.h"
#include "rt_kernels.h"
#include "rt_records.h"
#include "test_util.h"

namespace fa::test::gi {

struct Mesh {
    std::vector<Vec3> vertices;
    std::vector<std::uint16_t> indices;
    gpu::Buffer vb{}, ib{};
    gpu::AccelStructure blas{};
    gpu::Buffer scratch{};
};

// A floor of 40 x 40 m at y = 0, two triangles, counter-clockwise seen from above.
inline Mesh make_quad() {
    Mesh m;
    m.vertices = {{-20, 0, -20}, {20, 0, -20}, {20, 0, 20}, {-20, 0, 20}};
    m.indices = {0, 2, 1, 0, 3, 2};
    return m;
}

// [-1, 1] x [0, 2] x [-1, 1], counter-clockwise seen from outside.
inline Mesh make_box() {
    Mesh m;
    m.vertices = {{-1, 0, -1}, {1, 0, -1}, {1, 2, -1}, {-1, 2, -1}, {-1, 0, 1}, {1, 0, 1}, {1, 2, 1}, {-1, 2, 1}};
    m.indices = {0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 4, 7, 0, 7, 3,
                 1, 2, 6, 1, 6, 5, 3, 7, 6, 3, 6, 2, 0, 1, 5, 0, 5, 4};
    return m;
}

// A mesh put in the scene: where, and the material of its record.
struct Place {
    Mesh* mesh = nullptr;
    Vec3 at{0, 0, 0};
    Vec3 albedo{0.4f, 0.4f, 0.4f};
    float roughness = 0.5f, metalness = 0.0f;
    Vec3 emissive{0, 0, 0};
};

inline constexpr std::uint8_t kMask = render::kRtMaskOpaque | render::kRtMaskCastsShadow;

struct Rig {
    std::unique_ptr<gpu::Device> owner;
    gpu::Device* dev = nullptr;
    gpu::Backend backend = gpu::Backend::Metal;
    gpu::AccelBuildFlags flags;
    gpu::Pipeline pipeline{};
    gpu::Sampler sampler{};
    gpu::AccelStructure tlas{};
    gpu::Buffer tlasScratch{};
    std::vector<gpu::AccelInstance> instances;
    std::vector<render::RtInstanceRecord> records;
    std::vector<Mesh*> meshes;  // each distinct mesh of the places, its BLAS is built once
    gpu::View recordsView{}, atlasView{}, outView{};
    gpu::Image outImage{}, atlasImage{};
    gpu::Shader shader{};
    std::vector<gpu::Buffer> recordBuffers;  // the buffers behind make_records' views
    std::vector<gpu::View> recordViews;
    bool blasBuilt = false;

    // Opens the device of this build. False with `skip` saying why: no GPU, a backend that is not `only` (when given), no ray tracing. A
    // device the build cannot make fails the test.
    bool open(std::string& skip, const gpu::Backend* only = nullptr) {
        auto& g = fa::test::gfx();
        if (!g.ok) {
            skip = "no GPU here (" + g.error + ")";
            return false;
        }
        backend = gpu::built_sokol_backend();
        if (only && backend != *only) {
            skip = std::string("the sokol backend of this build is ") + gpu::backend_name(backend);
            return false;
        }
        auto made = gpu::make_device(backend);
        REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
        owner = std::move(made.value());
        dev = owner.get();
        std::string why;
        if (!dev->ray_tracing_status(&why)) {
            skip = "this GPU or OS cannot trace rays: " + why;
            return false;
        }
        return true;
    }

    gpu::AccelTriangles geometry_of(const Mesh& m) const {
        gpu::AccelTriangles g{};
        g.vertexBuffer = m.vb;
        g.vertexStride = sizeof(Vec3);
        g.vertexCount = std::uint32_t(m.vertices.size());
        g.indexBuffer = m.ib;
        g.indexType = gpu::IndexType::Uint16;
        g.indexCount = std::uint32_t(m.indices.size());
        return g;
    }

    gpu::AccelStructure make_as(gpu::AccelKind kind, std::uint64_t size, const char* label) {
        gpu::AccelStructureDesc d;
        d.kind = kind;
        d.size = size;
        d.label = label;
        auto r = dev->make_accel_structure(d);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        return r.value();
    }

    gpu::Buffer make_scratch(std::uint64_t size, const char* label) {
        gpu::BufferDesc d;
        d.size = std::size_t(std::max<std::uint64_t>(size, 256));
        d.usage.accelScratch = true;
        d.label = label;
        return dev->make_buffer(d);
    }

    void upload(Mesh& m) {
        gpu::BufferDesc vb;
        vb.size = m.vertices.size() * sizeof(Vec3);
        vb.usage.accelBuildInput = true;
        vb.data = gpu::Range{m.vertices.data(), vb.size};
        vb.label = "rt gi mesh vertices";
        m.vb = dev->make_buffer(vb);
        gpu::BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = gpu::Range{m.indices.data(), ib.size};
        ib.label = "rt gi mesh indices";
        m.ib = dev->make_buffer(ib);
    }

    // A storage view of `data` (the records a compute pass reads).
    gpu::View make_records(const std::vector<render::RtInstanceRecord>& data, const char* label) {
        gpu::BufferDesc rbd;
        rbd.size = data.size() * sizeof(render::RtInstanceRecord);
        rbd.usage.storageBuffer = true;
        rbd.label = label;
        rbd.data = gpu::Range{data.data(), rbd.size};
        const gpu::Buffer buffer = dev->make_buffer(rbd);
        recordBuffers.push_back(buffer);
        gpu::ViewDesc rvd;
        rvd.storageBuffer.buffer = buffer;
        rvd.label = label;
        const gpu::View view = dev->make_view(rvd);
        recordViews.push_back(view);
        return view;
    }

    // The meshes, their structures, the instances and records (one per place, customIndex = its index), the TLAS, the zero atlas (meta.g = 0:
    // no probe lends light to a bounce) and the band image the kernel writes.
    void build_scene(const std::vector<Place>& places) {
        for (const Place& p : places)
            if (std::find(meshes.begin(), meshes.end(), p.mesh) == meshes.end()) {
                meshes.push_back(p.mesh);
                upload(*p.mesh);
            }
        for (Mesh* m : meshes) {
            const gpu::AccelTriangles g = geometry_of(*m);
            auto bs = dev->blas_sizes(std::span<const gpu::AccelTriangles>(&g, 1), flags);
            REQUIRE_MESSAGE(bs.ok(), bs.error().message);
            m->blas = make_as(gpu::AccelKind::Blas, bs->structure, "rt gi blas");
            m->scratch = make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt gi blas scratch");
        }
        instances.assign(places.size(), gpu::AccelInstance{});
        records.assign(places.size(), render::RtInstanceRecord{});
        for (std::size_t i = 0; i < places.size(); ++i) {
            const Place& p = places[i];
            gpu::AccelInstance& in = instances[i];
            in.transform[3] = p.at.x;
            in.transform[7] = p.at.y;
            in.transform[11] = p.at.z;
            in.blas = p.mesh->blas;
            in.mask = kMask;
            in.customIndex = std::uint32_t(i);
            render::RtInstanceRecord& r = records[i];
            std::memset(&r, 0, sizeof r);
            r.objectToWorld[0] = r.objectToWorld[5] = r.objectToWorld[10] = 1.0f;
            r.objectToWorld[3] = p.at.x;
            r.objectToWorld[7] = p.at.y;
            r.objectToWorld[11] = p.at.z;
            const float albedo[3] = {p.albedo.x, p.albedo.y, p.albedo.z};
            const float emissive[3] = {p.emissive.x, p.emissive.y, p.emissive.z};
            for (int c = 0; c < 3; ++c) {
                r.albedo[c] = albedo[c];
                r.emissive[c] = emissive[c];
            }
            r.albedo[3] = 1.0f;
            r.roughness = p.roughness;
            r.metalness = p.metalness;
            r.flags = render::kRtFlagOpaque | render::kRtFlagCastsShadow;
        }
        auto ts = dev->tlas_sizes(std::uint32_t(instances.size()), flags);
        REQUIRE_MESSAGE(ts.ok(), ts.error().message);
        tlas = make_as(gpu::AccelKind::Tlas, ts->structure, "rt gi tlas");
        tlasScratch = make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt gi tlas scratch");
        recordsView = make_records(records, "rt gi records view");

        const int atlasW = render::kProbeAtlasSize, atlasH = render::kProbeAtlasSize + 11 * 2;
        std::vector<std::uint16_t> atlasData(std::size_t(atlasW) * atlasH * 4, 0);
        gpu::ImageDesc ad;
        ad.width = atlasW;
        ad.height = atlasH;
        ad.pixelFormat = gpu::PixelFormat::Rgba16F;
        ad.data.mipLevels[0] = gpu::Range{atlasData.data(), atlasData.size() * sizeof(std::uint16_t)};
        ad.label = "rt gi atlas";
        const gpu::Image atlasImg = atlasImage = dev->make_image(ad);
        gpu::ViewDesc atv;
        atv.texture.image = atlasImg;
        atv.label = "rt gi atlas view";
        atlasView = dev->make_view(atv);
        REQUIRE(dev->state(atlasView) == gpu::ResourceState::Valid);

        gpu::ImageDesc od;
        od.width = render::kProbeAtlasSize;
        od.height = render::kGiBandHeight;
        od.pixelFormat = gpu::PixelFormat::Rgba16F;
        od.usage.storageImage = true;
        od.label = "rt gi band";
        outImage = dev->make_image(od);
        gpu::ViewDesc ov;
        ov.storageImage.image = outImage;
        ov.label = "rt gi band view";
        outView = dev->make_view(ov);
    }

    void make_pipeline() {
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_gi");
        REQUIRE(k != nullptr);
        const render::RtEffectKernelSpec* spec = render::find_rt_effect_spec("rt_gi");
        REQUIRE(spec != nullptr);
        gpu::SamplerDesc sd;
        sd.label = "rt gi nearest";
        sampler = dev->make_sampler(sd);
        gpu::PipelineDesc pd;
        pd.compute = true;
        shader = dev->make_shader(render::rt_effect_shader_desc(*k, *spec, backend));
        pd.shader = shader;
        pd.label = "rt_gi";
        pipeline = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == gpu::ResourceState::Valid);
        REQUIRE(dev->state(pipeline) == gpu::ResourceState::Valid);
    }

    // Frees everything the rig made, the meshes' buffers and structures included (the way rt_reflect_metal_tests.cpp's Rig::release does). Call it
    // while the meshes of the places still live; the rig has no destructor for it because the test's meshes are declared after the rig.
    void release() {
        if (!dev) return;
        for (const gpu::View v : recordViews) dev->destroy_view(v);
        for (const gpu::Buffer b : recordBuffers) dev->destroy_buffer(b);
        recordViews.clear();
        recordBuffers.clear();
        if (atlasView.id) dev->destroy_view(atlasView);
        if (outView.id) dev->destroy_view(outView);
        if (atlasImage.id) dev->destroy_image(atlasImage);
        if (outImage.id) dev->destroy_image(outImage);
        if (tlas.id) dev->destroy_accel_structure(tlas);
        if (tlasScratch.id) dev->destroy_buffer(tlasScratch);
        for (Mesh* m : meshes) {
            if (m->blas.id) dev->destroy_accel_structure(m->blas);
            dev->destroy_buffer(m->vb);
            dev->destroy_buffer(m->ib);
            if (m->scratch.id) dev->destroy_buffer(m->scratch);
        }
        meshes.clear();
        if (pipeline.id) dev->destroy_pipeline(pipeline);
        if (shader.id) dev->destroy_shader(shader);
        if (sampler.id) dev->destroy_sampler(sampler);
        atlasView = outView = {};
        atlasImage = outImage = {};
        tlas = {};
        tlasScratch = {};
        pipeline = {};
        shader = {};
        sampler = {};
    }

    // Records the builds of the structures (the BLASes only the first time) onto `cl`.
    void record_builds(gpu::CommandList& cl) {
        if (!blasBuilt) {
            for (Mesh* m : meshes) {
                gpu::BlasBuild bb;
                const gpu::AccelTriangles g = geometry_of(*m);
                bb.dst = m->blas;
                bb.geometries = std::span<const gpu::AccelTriangles>(&g, 1);
                bb.flags = flags;
                bb.scratch = m->scratch;
                auto r = cl.build_blas(bb);
                REQUIRE_MESSAGE(r.ok(), r.error().message);
            }
            blasBuilt = true;
        }
        gpu::TlasBuild tb;
        tb.dst = tlas;
        tb.instances = instances;
        tb.flags = flags;
        tb.scratch = tlasScratch;
        auto built = cl.build_tlas(tb);
        REQUIRE_MESSAGE(built.ok(), built.error().message);
    }

    // Records the probe kernel's compute pass: `probes` thread groups with `params`, the hit constants and `records` (the scene's, or another).
    void record_trace(gpu::CommandList& cl, const render::RtGiParams& params, const render::RtHitParams& hit,
                      gpu::View recordsOf, int probes) {
        cl.begin_compute_pass("rt gi");
        cl.set_pipeline(pipeline);
        gpu::Bindings b;
        b.views[render::RtEffectBindings::kViewOut] = outView;
        b.views[render::RtEffectBindings::kViewPrepass] = atlasView;
        b.views[render::RtEffectBindings::kViewRecords] = recordsOf;
        if (render::rt_effect_needs_sampler(backend)) b.samplers[render::RtEffectBindings::kSampler] = sampler;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(render::RtEffectBindings::kUniformParams, gpu::Range{&params, sizeof params});
        cl.set_uniforms(render::RtEffectBindings::kUniformHit, gpu::Range{&hit, sizeof hit});
        cl.dispatch(std::uint32_t(probes), 1, 1);
        cl.end_pass();
    }

    // Submits `cl`, waits and reads the band image as halves (kProbeAtlasSize x kGiBandHeight x 4).
    std::vector<std::uint16_t> submit_and_read(gpu::CommandList& cl) {
        dev->submit(cl);
        dev->commit();
        std::vector<std::uint8_t> bytes;
        auto r = dev->read_storage_image(outImage, gpu::PixelFormat::Rgba16F, 0, 0, render::kProbeAtlasSize,
                                         render::kGiBandHeight, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        const std::size_t count = std::size_t(render::kProbeAtlasSize) * render::kGiBandHeight * 4;
        REQUIRE(bytes.size() == count * sizeof(std::uint16_t));
        std::vector<std::uint16_t> halves(count);
        std::memcpy(halves.data(), bytes.data(), bytes.size());
        return halves;
    }
};

// The hit constants the two tests use for the sun, the sky and the shadow offsets.
inline render::RtHitParams make_hit(Vec3 sunDir, Vec3 sunColor, Vec3 ambient, Vec3 sky, Vec3 horizon,
                                    float shadowOffset, float shadowOffsetPerMetre) {
    render::RtHitParams hit{};
    const Vec3 v[5] = {sunDir, sunColor, ambient, sky, horizon};
    float* dst[5] = {hit.sunDir, hit.sunColor, hit.ambient, hit.sky, hit.horizon};
    for (int i = 0; i < 5; ++i) {
        dst[i][0] = v[i].x;
        dst[i][1] = v[i].y;
        dst[i][2] = v[i].z;
    }
    hit.limits[0] = shadowOffset;
    hit.limits[1] = shadowOffsetPerMetre;
    hit.limits[2] = 10000.0f;
    hit.limits[3] = 0.002f;
    return hit;
}

}  // namespace fa::test::gi
