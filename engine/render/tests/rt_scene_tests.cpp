// M79 P1s: the acceleration structures of the scene (src/rt_scene.h, src/rt_records.h; docs/design/ARCHITECTURE_RT_SCENE.md), on the
// RecordingDevice with ray tracing. The counts are units of builds, instances and records, never times. Two kinds of cases: the scene on
// its own (RtScene with hand-made assets: every rule of what is traced, the cap, the compaction, the records) and the renderer's frame
// (the setting, the device, the main camera's items, LOD, foliage, the floating origin, an asset going away).
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <deque>
#include <fstream>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/scene/components.h"
#include "fa/scene/foliage.h"
#include "fa/scene/animation.h"
#include "gpu/recording_device.h"
#include "gpu/sokol_shaders.h"
#include "render_internal.h"
#include "renderer_impostor.h"
#include "renderer_terrain.h"
#include "renderer_test_access.h"
#include "rt_scene.h"
#include "rt_skin.h"
#include "shaders/rt_skin.glsl.h"

using namespace fa;
using namespace fa::test;
using fa::render::RtScene;

namespace {

// ---- logs ------------------------------------------------------------------------------------------------------------------------

struct Warnings {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    Warnings()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Info) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~Warnings() { remove_log_sink(id); }
    Warnings(const Warnings&) = delete;
    Warnings& operator=(const Warnings&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(std::count_if(shared->lines.begin(), shared->lines.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
    std::string all() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        std::string s;
        for (const std::string& l : shared->lines) s += l + "\n";
        return s;
    }
};

std::string joined(const std::vector<std::string>& lines) {
    std::string out;
    for (const std::string& l : lines) out += l + "\n";
    return out;
}

int count_kind(const gpu::RecordingDevice& dev, gpu::CommandKind kind) {
    int n = 0;
    for (const gpu::RecordedCommand& c : dev.commands()) n += c.kind == kind ? 1 : 0;
    return n;
}

// The recorded commands as text lines without the frame index (two runs of the same scene compare equal).
std::vector<std::string> lines_of(const gpu::RecordingDevice& dev) {
    std::vector<std::string> out;
    for (const gpu::RecordedCommand& c : dev.commands()) out.push_back(c.list + ": " + c.text);
    return out;
}

// ---- the scene on its own ----------------------------------------------------------------------------------------------------------

// The path the real backends take: the compacted sizes are read in the background. A ticket answers on its `pollsNeeded`th poll (a wait
// answers at once, as the real ones do); the device can say "every slot is in flight" (an invalid ticket) or refuse.
class AsyncRecordingDevice : public gpu::RecordingDevice {
public:
    using gpu::RecordingDevice::RecordingDevice;
    int pollsNeeded = 2;
    int busyRequests = 0;  // the next requests answer with an invalid ticket
    bool failRequests = false;
    int requests = 0, polls = 0, releases = 0;
    bool async_read_supported() const override { return true; }
    Result<gpu::ReadTicket> request_buffer_read(gpu::Buffer buffer, std::size_t offset, std::size_t bytes) override {
        ++requests;
        if (failRequests)
            return make_error("gpu: request_buffer_read: the test device refuses reads", "this is a test");
        if (busyRequests > 0) {
            --busyRequests;
            return gpu::ReadTicket{};
        }
        pending_.push_back({buffer, offset, bytes, 0});
        gpu::ReadTicket t;
        t.slot = int(pending_.size() - 1);
        t.generation = 1;
        return t;
    }
    bool poll_buffer_read(gpu::ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override {
        ++polls;
        Pending& p = pending_.at(std::size_t(ticket.slot));
        if (++p.polls < pollsNeeded && !wait) return false;
        return read_buffer(p.buffer, p.offset, p.bytes, out).ok();
    }
    void release_buffer_read(gpu::ReadTicket) override { ++releases; }

private:
    struct Pending {
        gpu::Buffer buffer;
        std::size_t offset, bytes;
        int polls;
    };
    std::vector<Pending> pending_;
};

struct Rig {
    std::unique_ptr<gpu::Device> owned;
    gpu::RecordingDevice* dev = nullptr;
    AsyncRecordingDevice* async = nullptr;
    bool headless = true;
    RtScene scene;
    std::vector<std::unique_ptr<render::MeshAsset>> meshes;
    std::deque<MeshRenderer> renderers;  // a deque: the items point into it, and a new one moves none of the others

    explicit Rig(bool rayTracing = true, bool asyncReads = false) {
        gpu::DeviceInit init;
        init.recordingRayTracing = rayTracing;
        if (asyncReads) {
            owned = std::make_unique<AsyncRecordingDevice>(init);
            async = static_cast<AsyncRecordingDevice*>(owned.get());
            headless = false;  // a read-back is polled, not waited for
        } else {
            auto made = gpu::make_device(gpu::Backend::Recording, init);
            REQUIRE_MESSAGE(made.ok(), (made.ok() ? "" : made.error().message));
            owned = std::move(made.value());
        }
        dev = dynamic_cast<gpu::RecordingDevice*>(owned.get());
        REQUIRE(dev != nullptr);
    }
    ~Rig() {
        scene.release();
    }  // before `owned` goes (members are destroyed in reverse order, so this is for the reader)

    // A mesh asset of `parts` parts: each a quad of four vertices and six indices (24 bytes) in buffers a build can read.
    render::MeshAsset* mesh(const char* key, int parts = 1, bool buildable = true) {
        auto m = std::make_unique<render::MeshAsset>();
        m->key = key;
        for (int p = 0; p < parts; ++p) {
            render::SubMesh sm;
            gpu::BufferDesc vb;
            vb.size = 4 * sizeof(render::MeshVertex);
            vb.usage.vertexBuffer = true;
            vb.usage.accelBuildInput = buildable;
            vb.usage.copyDst = true;
            vb.label = "rig vertices";
            sm.vb = dev->make_buffer(vb);
            gpu::BufferDesc ib;
            ib.size = 6 * sizeof(std::uint32_t);
            ib.usage.indexBuffer = true;
            ib.usage.accelBuildInput = buildable;
            ib.usage.copyDst = true;
            ib.label = "rig indices";
            sm.ib = dev->make_buffer(ib);
            sm.vertexCount = 4;
            sm.indexCount = 6;
            m->parts.push_back(sm);
        }
        meshes.push_back(std::move(m));
        return meshes.back().get();
    }

    // A skinned mesh asset: the parts of mesh() whose vertices and influences a compute shader can read (what Assets makes when ray tracing is on).
    render::MeshAsset* skinned_mesh(const char* key, int parts = 1) {
        render::MeshAsset* m = mesh(key, parts);
        for (render::SubMesh& sm : m->parts) {
            gpu::BufferDesc vb;
            vb.size = 4 * sizeof(render::MeshVertex);
            vb.usage.vertexBuffer = true;
            vb.usage.storageBuffer = true;
            vb.usage.accelBuildInput = true;
            vb.usage.copyDst = true;
            vb.label = "rig skinned vertices";
            dev->destroy_buffer(sm.vb);
            sm.vb = dev->make_buffer(vb);
            gpu::BufferDesc sk;
            sk.size = 4 * sizeof(render::SkinVertex);
            sk.usage.vertexBuffer = true;
            sk.usage.storageBuffer = true;
            sk.usage.copyDst = true;
            sk.label = "rig influences";
            sm.skinVb = dev->make_buffer(sk);
            sm.skin = 0;
            sm.bmin = {-1, -1, -1};
            sm.bmax = {1, 1, 1};
        }
        return m;
    }

    // The skinning kernel as the renderer makes it: the generated program of this device, one compute pipeline.
    gpu::Pipeline kernel;
    void use_kernel() {
        gpu::PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(gpu::generated_shader_desc(*dev, &rt_skin_rt_skin_shader_desc));
        REQUIRE(dev->state(pd.shader) == gpu::ResourceState::Valid);
        pd.label = "rt skin";
        kernel = dev->make_pipeline(pd);
        REQUIRE(dev->state(kernel) == gpu::ResourceState::Valid);
        scene.skinKernel = [this] { return kernel; };
    }

    // A skinned item of `m` posed by `anim` (a palette of two joints is enough for the scene: the kernel's maths is the CPU twin's business).
    render::MeshItem skinned_item(render::MeshAsset* m, const Animator* anim, Vec3 at, std::uint32_t entityIndex) {
        render::MeshItem mi = item(m, at, entityIndex);
        mi.anim = anim;
        return mi;
    }

    render::MeshItem item(render::MeshAsset* m, Vec3 at, std::uint32_t entityIndex = 0) {
        renderers.emplace_back();
        render::MeshItem mi;
        mi.mesh = m;
        mi.mr = &renderers.back();
        mi.model = Mat4::translate(at);
        mi.entity = Entity{entityIndex, 1};
        return mi;
    }

    // One frame of the scene as the renderer drives it: begin, collect, record on a list, submit and commit.
    void frame(const std::vector<render::MeshItem>& opaque, const std::vector<render::MeshItem>& blended = {},
               Vec3 camera = {0, 0, 0}) {
        scene.begin_frame(headless, [this] { dev->commit(); });
        scene.collect(opaque, blended, camera, true);
        gpu::CommandList& cl = dev->begin_commands("rt");
        scene.record(cl);
        dev->submit(cl);
        dev->commit();
    }
};

TEST_CASE("rt scene: one BLAS per submesh, built once, compacted, and freed when the asset goes") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    render::MeshAsset* a = rig.mesh("a", 2);
    render::MeshAsset* b = rig.mesh("b", 1);
    std::vector<render::MeshItem> items;
    for (int i = 0; i < 3; ++i) items.push_back(rig.item(a, {float(i), 0, 0}));
    items.push_back(rig.item(b, {0, 5, 0}));

    rig.frame(items);
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 3);  // 2 parts of a + 1 of b, however many instances
    CHECK(count_kind(*rig.dev, gpu::CommandKind::QueryCompactedSize) == 3);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildTlas) == 1);
    CHECK(rig.scene.instance_count() == 7);  // 3 * 2 parts + 1
    CHECK(rig.scene.tlas().valid());
    CHECK(rig.scene.records_buffer().valid());
    const std::vector<std::uint32_t> idsA = rig.scene.blas_ids_of(a);
    const std::vector<std::uint32_t> idsB = rig.scene.blas_ids_of(b);
    REQUIRE(idsA.size() == 2);
    REQUIRE(idsB.size() == 1);
    CHECK(idsA[0] != idsA[1]);
    const std::uint64_t bytesBuilt = rig.scene.stats().blasBytes;
    CHECK(bytesBuilt > 0);
    CHECK(rig.scene.stats().blasBuilt == 3);

    // Frame 2: the sizes asked in frame 1 are read, the smaller structures are made and the originals copied into them. No build.
    rig.dev->clear_commands();
    rig.frame(items);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 0);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::CopyAccelStructure) == 3);
    for (const gpu::RecordedCommand& c : rig.dev->commands())
        if (c.kind == gpu::CommandKind::CopyAccelStructure) CHECK(c.args[0] == 1);  // Compact
    CHECK(rig.scene.stats().blasCompacted == 3);
    // Frame 3: the compacted structures replace the originals (the TLAS of this frame names them); nothing is built or copied.
    rig.dev->clear_commands();
    rig.frame(items);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 0);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::CopyAccelStructure) == 0);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::QueryCompactedSize) == 0);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildTlas) == 1);
    for (std::uint32_t id : idsA) CHECK(rig.scene.blas_state(id) == "compacted");
    CHECK(rig.scene.blas_state(idsB[0]) == "compacted");
    CHECK(rig.scene.stats().blasBytes < bytesBuilt);
    CHECK(rig.dev->errors().empty());

    // The asset goes: its BLASes are freed, the other asset's stay.
    rig.scene.forget(a);
    CHECK(rig.scene.blas_state(idsA[0]) == "gone");
    CHECK(rig.scene.blas_state(idsA[1]) == "gone");
    CHECK(rig.scene.blas_state(idsB[0]) == "compacted");
    CHECK_FALSE(rig.scene.blas_has_asset(a));
    // The next frame traces the one that is left.
    rig.frame({rig.item(b, {0, 5, 0})});
    CHECK(rig.scene.instance_count() == 1);
    rig.scene.release();
    CHECK(rig.scene.blas_state(idsB[0]) == "gone");
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());  // nothing destroyed twice, nothing built from a freed structure
}

TEST_CASE("rt scene: traceable_items counts the last collect for a job planned before this frame's collect") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    render::MeshAsset* a = rig.mesh("a", 1);
    CHECK(rig.scene.traceable_items() == 0);  // nothing collected yet
    rig.frame({rig.item(a, {0, 0, 0}, 1), rig.item(a, {2, 0, 0}, 2)});
    CHECK(rig.scene.traceable_items() == 2);
    rig.scene.begin_graph();  // a new frame graph: a job planned now, before the main camera's collect
    CHECK_FALSE(rig.scene.collected());
    CHECK(rig.scene.traceable_items() == 2);  // the scene of the frame before, never 0
    rig.scene.begin_frame(true, [&] { rig.dev->commit(); });
    rig.scene.collect({rig.item(a, {0, 0, 0}, 1)}, {}, {0, 0, 0}, true);
    CHECK(rig.scene.traceable_items() == 1);
    rig.scene.release();
    CHECK(rig.scene.traceable_items() == 0);
}

TEST_CASE("rt scene: a BLAS is built again when the asset's geometry is replaced") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    render::MeshAsset* a = rig.mesh("a");
    const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0})};
    rig.frame(items);
    const std::uint32_t first = rig.scene.blas_ids_of(a)[0];
    rig.frame(items);
    CHECK(rig.scene.blas_ids_of(a)[0] == first);  // the same
    ++a->geometryVersion;                         // a procedural mesh updated, a mesh loaded again
    rig.dev->clear_commands();
    rig.frame(items);
    const std::uint32_t second = rig.scene.blas_ids_of(a)[0];
    CHECK(second != first);
    CHECK(rig.scene.blas_state(first) == "gone");
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 1);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: the records and the instances (transform, mask, customIndex, flags)") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    render::MeshAsset* m = rig.mesh("m");
    render::MaterialAsset cut;  // a custom material with alpha test
    cut.ok = true;
    cut.alphaMode = "clip";
    cut.doubleSided = true;
    render::MaterialAsset plain;
    plain.ok = true;

    render::MeshItem solid = rig.item(m, {1, 2, 3}, 10);
    rig.renderers.back().color = Color{1, 0, 0, 1};
    rig.renderers.back().metallic = 1.0f;
    rig.renderers.back().roughness = 0.25f;
    rig.renderers.back().emissive = Color{1, 0, 0, 1};
    rig.renderers.back().emissiveStrength = 2.0f;
    solid.model = Mat4::trs({1, 2, 3}, {0, 0, 0}, {2, 2, 2});
    render::MeshItem cutout = rig.item(m, {4, 0, 0}, 11);
    cutout.material = &cut;
    render::MeshItem custom = rig.item(m, {5, 0, 0}, 12);
    custom.material = &plain;
    rig.renderers.back().castShadows = false;
    rig.renderers.back().unlit = true;
    render::MeshItem glass = rig.item(m, {6, 0, 0}, 13);

    rig.frame({solid, cutout, custom}, {glass});
    const auto& fi = rig.scene.frame_instances();
    REQUIRE(fi.size() == 4);
    // customIndex = the position of the record; the instance's transform is the model's three rows.
    for (std::size_t i = 0; i < fi.size(); ++i) {
        CHECK(fi[i].instance.customIndex == i);
        CHECK(fi[i].record.blasId == fi[i].blasId);
        CHECK(std::memcmp(fi[i].record.objectToWorld, fi[i].instance.transform, sizeof(float) * 12) == 0);
        CHECK((fi[i].instance.mask & render::kRtMaskSurfaces) != 0);  // every instance is in at least one surface class
        CHECK((fi[i].instance.mask & render::kRtMaskReserved) == 0);
    }
    // solid: scale 2 at (1,2,3), opaque, casts shadows, emissive.
    const auto& s = fi[0];
    CHECK(s.entityId == 10);
    CHECK(s.instance.transform[0] == doctest::Approx(2.0f));
    CHECK(s.instance.transform[5] == doctest::Approx(2.0f));
    CHECK(s.instance.transform[3] == doctest::Approx(1.0f));
    CHECK(s.instance.transform[7] == doctest::Approx(2.0f));
    CHECK(s.instance.transform[11] == doctest::Approx(3.0f));
    CHECK(s.instance.opaque);
    CHECK_FALSE(s.instance.cullDisable);
    CHECK(s.instance.mask == (render::kRtMaskOpaque | render::kRtMaskCastsShadow | render::kRtMaskEmissive));
    CHECK((s.record.flags & render::kRtFlagOpaque) != 0);
    CHECK((s.record.flags & render::kRtFlagCutout) == 0);
    CHECK((s.record.flags & render::kRtFlagCastsShadow) != 0);
    CHECK(s.record.albedo[0] == doctest::Approx(1.0f));
    CHECK(s.record.albedo[1] == doctest::Approx(0.0f));
    CHECK(s.record.metalness == doctest::Approx(1.0f));
    CHECK(s.record.roughness == doctest::Approx(0.25f));
    CHECK(s.record.emissive[0] == doctest::Approx(2.0f));
    // cutout: the instance is NOT forced opaque and the record says cutout; double-sided material: back faces are hit.
    const auto& c = fi[1];
    CHECK_FALSE(c.instance.opaque);
    CHECK(c.instance.cullDisable);
    CHECK(c.instance.mask == (render::kRtMaskCutout | render::kRtMaskCastsShadow));
    CHECK((c.record.flags & render::kRtFlagCutout) != 0);
    CHECK((c.record.flags & render::kRtFlagOpaque) == 0);
    CHECK((c.record.flags & render::kRtFlagTwoSided) != 0);
    CHECK((c.record.flags & render::kRtFlagCustomMaterial) != 0);
    // The alpha-tested caster is in the TLAS but the sun's shadow kernel has no alpha texture to test: it is the one untraced caster here (the
    // lit pass takes the cascades' shadow too, which cut the leaf's holes).
    CHECK(rig.scene.stats().untracedCasters == 1);
    // a material that is not alpha-tested: opaque; no shadow caster, unlit.
    const auto& u = fi[2];
    CHECK(u.instance.opaque);
    CHECK(u.instance.mask == render::kRtMaskOpaque);
    CHECK((u.record.flags & render::kRtFlagUnlit) != 0);
    CHECK((u.record.flags & render::kRtFlagCastsShadow) == 0);
    // the blended list: after the opaque ones, in the blended class.
    const auto& gl = fi[3];
    CHECK(gl.entityId == 13);
    CHECK(gl.instance.mask == (render::kRtMaskBlended | render::kRtMaskCastsShadow));
    CHECK((gl.record.flags & render::kRtFlagBlended) != 0);
    // The record buffer holds what the frame says: one 128-byte record per instance, written before the TLAS build.
    int writes = 0;
    for (const gpu::RecordedCommand& cmd : rig.dev->commands())
        if (cmd.kind == gpu::CommandKind::WriteBuffer && cmd.args[0] == int(4 * sizeof(render::RtInstanceRecord)))
            ++writes;
    CHECK(writes == 1);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: a transmissive part is refractive (flag, mask, volume, both faces); a plain blended one is not") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    render::MeshAsset* m = rig.mesh("m");
    render::MeshItem glass = rig.item(m, {0, 0, 0}, 20);
    rig.renderers.back().transmission = 0.8f;
    rig.renderers.back().thickness = 0.5f;
    rig.renderers.back().ior = 1.33f;
    rig.renderers.back().attenuationDistance = 2.0f;
    rig.renderers.back().attenuationColor = Color{0.5f, 1.0f, 0.25f, 1.0f};
    render::MeshItem tinted = rig.item(m, {3, 0, 0}, 21);  // blended by its alpha, nothing transmitted
    rig.renderers.back().color = Color{1, 1, 1, 0.5f};
    render::MeshItem unlitGlass =
        rig.item(m, {6, 0, 0}, 22);  // an unlit surface transmits nothing (the draw's own rule)
    rig.renderers.back().transmission = 1.0f;
    rig.renderers.back().unlit = true;
    render::MeshItem metalGlass =
        rig.item(m, {9, 0, 0}, 23);  // a full metal lets nothing through: transmission * (1 - metallic)
    rig.renderers.back().transmission = 1.0f;
    rig.renderers.back().metallic = 1.0f;
    rig.renderers.back().color = Color{1, 1, 1, 0.5f};
    rig.frame({}, {glass, tinted, unlitGlass, metalGlass});
    const auto& fi = rig.scene.frame_instances();
    REQUIRE(fi.size() == 4);
    const auto& g = fi[0];
    CHECK((g.record.flags & render::kRtFlagRefractive) != 0);
    CHECK((g.record.flags & render::kRtFlagBlended) != 0);
    CHECK((g.instance.mask & render::kRtMaskRefractive) != 0);
    CHECK((g.instance.mask & render::kRtMaskBlended) != 0);
    CHECK((g.instance.mask & render::kRtMaskCastsShadow) != 0);  // glass casts a solid shadow (castShadows decides)
    CHECK(g.instance.cullDisable);                               // a ray leaves a closed glass through its far wall
    CHECK(g.record.volume[0] == doctest::Approx(1.33f));
    CHECK(g.record.volume[1] == doctest::Approx(0.5f));
    CHECK(g.record.volume[2] == doctest::Approx(2.0f));
    CHECK(g.record.volume[3] == doctest::Approx(0.8f));
    CHECK(g.record.attenuation[1] == doctest::Approx(1.0f));
    CHECK(g.record.attenuation[0] < 1.0f);  // the colour, in the scene's colour space
    for (std::size_t i = 1; i < fi.size(); ++i) {
        CHECK((fi[i].record.flags & render::kRtFlagRefractive) == 0);
        CHECK((fi[i].instance.mask & render::kRtMaskRefractive) == 0);
        CHECK(fi[i].record.volume[3] == 0.0f);
        CHECK(fi[i].record.volume[1] == 0.0f);
        CHECK(fi[i].record.attenuation[0] == 1.0f);
    }
    CHECK_FALSE(fi[1].instance.cullDisable);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: what is not traced, and why") {
    Warnings log;
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    render::MeshAsset* m = rig.mesh("m");
    render::MeshAsset* ph = rig.mesh("missing", 1);
    ph->placeholder = true;
    Animator animator;
    render::ImpostorDraw card;
    render::TerrainDraw node;
    render::MaterialAsset gpuDriven;
    gpuDriven.ok = true;
    gpuDriven.buffers.resize(1);

    std::vector<render::MeshItem> items;
    items.push_back(rig.item(m, {0, 0, 0}, 1));  // traced
    animator.palette = {Mat4::identity(), Mat4::translate({0, 1, 0})};
    rig.use_kernel();
    render::MeshAsset* sk = rig.skinned_mesh("sk");
    items.push_back(rig.skinned_item(sk, &animator, {1, 0, 0}, 2));  // traced: its own BLAS, skinned by the kernel
    render::MeshItem impostor = rig.item(m, {2, 0, 0}, 3);
    impostor.impostor = &card;
    items.push_back(impostor);
    render::MeshItem terrain = rig.item(m, {3, 0, 0}, 4);
    terrain.terrain = &node;
    items.push_back(terrain);
    render::MeshItem fadingOut = rig.item(m, {4, 0, 0}, 5);
    fadingOut.lodFade = -0.5f;
    items.push_back(fadingOut);
    render::MeshItem fadingIn = rig.item(m, {5, 0, 0}, 6);
    fadingIn.lodFade = 0.5f;
    items.push_back(fadingIn);
    render::MeshItem foliageFade = rig.item(m, {6, 0, 0}, 7);
    foliageFade.foliage = true;
    foliageFade.lodFade = -0.5f;  // a foliage's fade is a distance fade, not a cross-fade: it is traced
    items.push_back(foliageFade);
    render::MeshItem driven = rig.item(m, {7, 0, 0}, 8);
    driven.material = &gpuDriven;
    items.push_back(driven);
    items.push_back(rig.item(ph, {8, 0, 0}, 9));  // a placeholder (the mesh is still loading)
    // A terrain node that casts no shadow is not a lost shadow: only the casters the rays do not see are counted.
    render::MeshItem terrainNoCast = rig.item(m, {9, 0, 0}, 10);
    terrainNoCast.terrain = &node;
    rig.renderers.back().castShadows = false;
    items.push_back(terrainNoCast);

    rig.frame(items);
    rig.frame(items);
    const render::RtSceneStats& st = rig.scene.stats();
    CHECK(st.candidates == 10);
    CHECK(rig.scene.instance_count() == 4);
    std::set<std::uint32_t> traced;
    for (const auto& f : rig.scene.frame_instances()) traced.insert(f.entityId);
    CHECK(traced == std::set<std::uint32_t>{1, 2, 6, 7});
    CHECK(st.skippedSkinned == 0);
    CHECK(st.skinnedInstances == 1);
    CHECK(st.skippedImpostor == 1);
    CHECK(st.skippedTerrain == 2);  // both nodes, the one that casts and the one that does not
    CHECK(st.skippedFading == 1);
    CHECK(st.skippedGpuDriven == 1);
    CHECK(st.skippedUntraceable == 1);
    // M79-P2a-2: the casters the sun's rays cannot see (the lit pass then takes the cascades' shadow too): the impostor, the terrain, the
    // GPU-driven mesh and the placeholder; the node that casts nothing, the fading-out level (its replacement is traced) and the traced ones are not.
    CHECK(st.untracedCasters == 4);
    CHECK(log.count("skinned meshes") == 0);  // nothing to say: they are traced now
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: over the cap the nearest to the main camera stay, and the warning comes once") {
    Warnings log;
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 4));
    CHECK(rig.scene.cap() == 4);
    render::MeshAsset* m = rig.mesh("m");
    std::vector<render::MeshItem> items;
    // 10 items, distances 1..10 from the camera at the origin, in a scrambled order (index = distance).
    for (int d : {7, 2, 9, 1, 10, 4, 3, 8, 6, 5}) items.push_back(rig.item(m, {0, 0, -float(d)}, std::uint32_t(d)));
    rig.frame(items);
    rig.frame(items);
    CHECK(rig.scene.instance_count() == 4);
    CHECK(rig.scene.stats().droppedOverCap == 6);
    CHECK(rig.scene.stats().untracedCasters == 6);  // the ones over the cap cast too: the cascades keep their shadow
    CHECK(rig.scene.stats().cap == 4);
    std::set<std::uint32_t> kept;
    for (const auto& f : rig.scene.frame_instances()) kept.insert(f.entityId);
    CHECK(kept == std::set<std::uint32_t>{1, 2, 3, 4});
    CHECK(log.count("render.rayTracing.maxInstances") == 1);
    const std::string lines = log.all();
    CHECK(lines.find("10 instances") != std::string::npos);  // the count the scene holds
    CHECK(lines.find("holds 4") != std::string::npos);       // the cap
    // A change of the setting says it again if it is hit again; a cap that is not hit says nothing.
    CHECK(rig.scene.configure(rig.dev, true, 100));
    rig.frame(items);
    CHECK(rig.scene.instance_count() == 10);
    CHECK(rig.scene.stats().droppedOverCap == 0);
    CHECK(rig.scene.stats().untracedCasters == 0);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: the cap is the lower of the setting and the device's limit") {
    Rig rig;
    const std::uint32_t limit = rig.dev->limits().maxAccelInstances;
    REQUIRE(limit > 0);
    REQUIRE(rig.scene.configure(rig.dev, true, 0xFFFFFFFFu));
    CHECK(rig.scene.cap() == std::min<std::uint32_t>(limit, render::kRtMaxInstanceIndex + 1));
    REQUIRE(rig.scene.configure(rig.dev, true, 8));
    CHECK(rig.scene.cap() == 8);
    REQUIRE(rig.scene.configure(rig.dev, true, 0));  // never below one
    CHECK(rig.scene.cap() == 1);
}

TEST_CASE("rt scene: the same scene records the same calls, run after run") {
    auto run = [] {
        Rig rig;
        REQUIRE(rig.scene.configure(rig.dev, true, 6));
        render::MeshAsset* a = rig.mesh("a", 2);
        render::MeshAsset* b = rig.mesh("b", 1);
        std::vector<render::MeshItem> items;
        for (int i = 0; i < 5; ++i)
            items.push_back(rig.item(i % 2 ? a : b, {float(i) * 1.5f, 0, -float(i)}, std::uint32_t(i)));
        for (int f = 0; f < 5; ++f) rig.frame(items, {}, {0, 0, 0});
        return lines_of(*rig.dev);
    };
    const std::vector<std::string> first = run();
    const std::vector<std::string> second = run();
    REQUIRE(first.size() > 20);
    CHECK(first == second);
}

TEST_CASE("rt scene: off allocates nothing and does nothing") {
    {
        Rig rig;  // never configured
        const render::MeshItem none;
        rig.scene.begin_frame(true, {});
        rig.scene.collect({}, {}, {0, 0, 0}, true);
        gpu::CommandList& cl = rig.dev->begin_commands("rt");
        rig.scene.record(cl);
        rig.dev->submit(cl);
        rig.dev->commit();
        (void)none;
        CHECK_FALSE(rig.scene.active());
        CHECK(rig.scene.instance_count() == 0);
        CHECK_FALSE(rig.scene.tlas().valid());
        CHECK_FALSE(rig.scene.records_buffer().valid());
        CHECK(rig.dev->commands().size() == 1);  // only the commit
        CHECK(rig.dev->errors().empty());
    }
    {
        Rig rig;
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        CHECK(rig.scene.active());
        CHECK_FALSE(rig.scene.configure(rig.dev, false, 100));  // turned off: everything freed
        CHECK_FALSE(rig.scene.active());
    }
    {
        Rig noRt(false);  // a device that cannot trace
        CHECK_FALSE(noRt.scene.configure(noRt.dev, true, 100));
        CHECK_FALSE(noRt.scene.active());
        render::MeshAsset* m = noRt.mesh("m", 1, false);
        noRt.frame({noRt.item(m, {0, 0, 0})});
        CHECK(noRt.scene.instance_count() == 0);
        CHECK(noRt.dev->commands().size() == 1);
        CHECK(noRt.dev->errors().empty());
    }
}

TEST_CASE("rt scene: shift() moves the world-space records of the frame before") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 100));
    render::MeshAsset* m = rig.mesh("m");
    rig.frame({rig.item(m, {100, 5, -7})});
    REQUIRE(rig.scene.previous_records().size() == 1);
    rig.scene.shift({64, 0, -8});
    const render::RtInstanceRecord& r = rig.scene.previous_records()[0];
    CHECK(r.objectToWorld[3] == doctest::Approx(36.0f));
    CHECK(r.objectToWorld[7] == doctest::Approx(5.0f));
    CHECK(r.objectToWorld[11] == doctest::Approx(1.0f));
}

TEST_CASE("rt scene: a BLAS that cannot be built is reported once and its instances are left out") {
    Warnings log;
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 100));
    render::MeshAsset* bad = rig.mesh("noInput", 1, false);  // buffers made without accelBuildInput
    render::MeshAsset* good = rig.mesh("good");
    const std::vector<render::MeshItem> items{rig.item(bad, {0, 0, 0}, 1), rig.item(good, {1, 0, 0}, 2)};
    rig.frame(items);
    // The frame whose build failed: the TLAS of that very frame has the good instance only (the failed BLAS was never built).
    CHECK(rig.scene.instance_count() == 1);
    REQUIRE(rig.scene.frame_instances().size() == 1);
    CHECK(rig.scene.frame_instances()[0].entityId == 2);
    CHECK(rig.scene.frame_instances()[0].instance.customIndex == 0);
    int tlasBuilds = 0;
    for (const gpu::RecordedCommand& c : rig.dev->commands())
        if (c.kind == gpu::CommandKind::BuildTlas) {
            ++tlasBuilds;
            CHECK(c.args[0] == 1);  // instances
        }
    CHECK(tlasBuilds == 1);
    // The device reported the refused build and nothing else: no TLAS over a structure that was never built.
    for (const std::string& e : rig.dev->errors()) CHECK(e.find("instances[") == std::string::npos);
    rig.frame(items);
    CHECK(rig.scene.instance_count() == 1);
    CHECK(rig.scene.stats().skippedNoBlas == 1);
    CHECK(rig.scene.stats().untracedCasters ==
          1);  // the instance that was left out casts a shadow: the cascades keep it
    CHECK(log.count("a BLAS could not be built") == 1);  // once, not a line per frame
}

TEST_CASE("rt scene: the instances whose BLAS waits for the frame's build budget count as untraced casters until it is "
          "built") {
    Rig rig;
    const std::uint32_t over = 4;
    const std::uint32_t total = render::RtScene::kMaxBuildsPerFrame + over;
    REQUIRE(rig.scene.configure(rig.dev, true, total + 10));
    std::vector<std::string> keys;
    keys.reserve(total);
    for (std::uint32_t i = 0; i < total; ++i) keys.push_back("budget" + std::to_string(i));
    std::vector<render::MeshItem> items;
    for (std::uint32_t i = 0; i < total; ++i)
        items.push_back(rig.item(rig.mesh(keys[i].c_str()), {float(i), 0, 0}, i + 1));
    rig.frame(items);
    CHECK(rig.scene.stats().skippedNoBlas == over);
    CHECK(rig.scene.stats().untracedCasters == over);
    rig.frame(items);  // the rest are built now
    CHECK(rig.scene.stats().skippedNoBlas == 0);
    CHECK(rig.scene.stats().untracedCasters == 0);
}

TEST_CASE("rt scene: the BLASes of the instances the cap leaves out are never made") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 2));
    std::vector<render::MeshAsset*> assets;
    std::vector<render::MeshItem> items;
    for (int d = 1; d <= 6; ++d) {
        assets.push_back(rig.mesh(("m" + std::to_string(d)).c_str()));
        items.push_back(rig.item(assets.back(), {0, 0, -float(d)}, std::uint32_t(d)));
    }
    rig.frame(items);
    CHECK(rig.scene.instance_count() == 2);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 2);
    CHECK(rig.scene.stats().blasLive == 2);
    CHECK(rig.scene.blas_has_asset(assets[0]));
    CHECK(rig.scene.blas_has_asset(assets[1]));
    for (std::size_t i = 2; i < assets.size(); ++i) CHECK_FALSE(rig.scene.blas_has_asset(assets[i]));
}

TEST_CASE(
    "rt scene: a BLAS that goes is destroyed after the frames in flight, and the TLAS of those frames still names it") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 100));
    render::MeshAsset* a = rig.mesh("a");
    render::MeshAsset* b = rig.mesh("b");
    const std::vector<render::MeshItem> both{rig.item(a, {0, 0, 0}, 1), rig.item(b, {2, 0, 0}, 2)};
    const std::vector<render::MeshItem> onlyB{rig.item(b, {2, 0, 0}, 2)};
    for (int f = 0; f < 6; ++f) rig.frame(both);  // built, compacted, the originals retired and destroyed
    CHECK(rig.scene.retired_count() == 0);
    const std::uint32_t idA = rig.scene.blas_ids_of(a)[0];
    const gpu::AccelStructure structureA = rig.scene.blas_structure(idA);
    REQUIRE(structureA.id != 0);
    // The last TLAS built before the asset goes names it.
    bool named = false;
    for (const auto& f : rig.scene.frame_instances()) named = named || f.instance.blas.id == structureA.id;
    CHECK(named);
    rig.scene.forget(a);  // the asset is destroyed between two frames
    CHECK(rig.scene.blas_state(idA) == "gone");
    CHECK(rig.scene.retired_count() == 1);
    for (int f = 0; f < gpu::kInflightFrames; ++f) {
        rig.frame(onlyB);  // the TLASes of the frames before may still be executing: the structure is alive
        CHECK(rig.dev->accel_structure_state(structureA) == gpu::ResourceState::Valid);
    }
    rig.frame(onlyB);  // one frame more than the frames in flight
    CHECK(rig.dev->accel_structure_state(structureA) != gpu::ResourceState::Valid);
    CHECK(rig.scene.retired_count() == 0);
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: a buffer of the scene the device cannot make leaves the frame untraced, warns once, and the next "
          "frame that "
          "can make it builds everything") {
    Warnings log;
    for (const char* label : {"rt scratch", "rt instance records"}) {
        CAPTURE(label);
        Rig rig;
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        render::MeshAsset* a = rig.mesh("a");
        const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1), rig.item(a, {2, 0, 0}, 2)};
        rig.dev->fail_next_make_buffer(label, 3);  // three frames in a row the device is out of memory
        const int warningsBefore = log.count("a buffer of the scene could not be made");
        for (int f = 0; f < 3; ++f) {
            rig.frame(items);
            CHECK(rig.scene.frame_instances().empty());  // nothing is traced, nothing half built
            CHECK(rig.scene.stats().blasBuilt == 0);
            CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildTlas) == 0);
        }
        CHECK(log.count("a buffer of the scene could not be made") == warningsBefore + 1);  // once, not every frame
        const auto errors = rig.dev->take_errors();
        CHECK(errors.size() == 3);
        for (const std::string& e : errors) CHECK(e.find("injected fault") != std::string::npos);
        const std::vector<std::uint32_t> ids = rig.scene.blas_ids_of(a);
        REQUIRE(ids.size() == 1);
        CHECK(rig.scene.blas_state(ids[0]) == "pending");  // waits for a frame that can build it
        // The device recovers: the same scene is built in the next frame.
        rig.frame(items);
        CHECK(rig.scene.frame_instances().size() == 2);
        CHECK(rig.scene.stats().blasBuilt == 1);
        CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildTlas) == 1);
        CHECK(rig.dev->errors().empty());
    }
}

TEST_CASE("rt scene: instances of one BLAS count once in the build budget") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.scene.set_builds_per_frame(2);
    render::MeshAsset* shared = rig.mesh("shared");
    render::MeshAsset* b = rig.mesh("b");
    render::MeshAsset* c = rig.mesh("c");
    std::vector<render::MeshItem> items;
    for (std::uint32_t i = 0; i < 100; ++i) items.push_back(rig.item(shared, {float(i), 0, 0}, i + 1));
    items.push_back(rig.item(b, {0, 5, 0}, 200));
    items.push_back(rig.item(c, {0, 6, 0}, 201));
    rig.frame(items);
    // 102 instances need 3 BLASes; the budget of 2 builds `shared` (its hundred instances cost one) and one of the others.
    CHECK(rig.scene.stats().blasBuilt == 2);
    CHECK(rig.scene.frame_instances().size() >= 101);
    CHECK(rig.scene.stats().skippedNoBlas <= 1);
    rig.frame(items);
    CHECK(rig.scene.frame_instances().size() == 102);
    CHECK(rig.scene.stats().skippedNoBlas == 0);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: a mesh whose geometry changes every frame retires its BLAS each frame and destroys it later") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 100));
    render::MeshAsset* a = rig.mesh("animated");
    const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1)};
    std::vector<gpu::AccelStructure> seen;
    // The last frame whose TLAS names each structure, and the first frame it was destroyed in: a structure must be gone only once no TLAS
    // that may still be in flight names it (the delay alone could be right while the scene kept naming a retired structure).
    std::vector<int> lastNamed, destroyedAt;
    for (int f = 0; f < 12; ++f) {
        ++a->geometryVersion;
        rig.frame(items);
        seen.push_back(rig.scene.blas_structure(rig.scene.blas_ids_of(a)[0]));
        lastNamed.push_back(-1);
        destroyedAt.push_back(-1);
        for (const auto& fi : rig.scene.frame_instances())
            for (std::size_t i = 0; i < seen.size(); ++i)
                if (fi.instance.blas.id == seen[i].id) lastNamed[i] = f;
        for (std::size_t i = 0; i < seen.size(); ++i)
            if (destroyedAt[i] < 0 && rig.dev->accel_structure_state(seen[i]) != gpu::ResourceState::Valid)
                destroyedAt[i] = f;
        // Each earlier structure is alive while a frame in flight may still name it.
        for (std::size_t i = 0; i + 1 < seen.size(); ++i) {
            const bool old = i + 1 + std::size_t(gpu::kInflightFrames) + 1 <= std::size_t(f) + 1;
            if (!old) CHECK(rig.dev->accel_structure_state(seen[i]) == gpu::ResourceState::Valid);
        }
    }
    // Bounded, nothing piles up: at most the BLAS and its compaction target of each of the frames in flight and the one being recorded.
    CHECK(rig.scene.retired_count() <= 2 * (std::size_t(gpu::kInflightFrames) + 1));
    CHECK(rig.dev->accel_structure_state(seen[0]) != gpu::ResourceState::Valid);
    for (std::size_t i = 0; i < seen.size(); ++i) {
        CHECK_MESSAGE(lastNamed[i] == int(i), "frame " << i << " names its own BLAS, and the next frames name another");
        if (destroyedAt[i] >= 0)  // the TLAS that named it left the frames in flight before it was destroyed
            CHECK_MESSAGE(destroyedAt[i] - lastNamed[i] > int(gpu::kInflightFrames),
                          "structure " << i << " destroyed in frame " << destroyedAt[i] << ", named in "
                                       << lastNamed[i]);
    }
    CHECK(rig.dev->errors().empty());
    // Turning the scene off frees everything at once, retired ones included.
    rig.scene.release();
    for (const gpu::AccelStructure& s : seen) CHECK(rig.dev->accel_structure_state(s) != gpu::ResourceState::Valid);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt scene: the compacted sizes read in the background (the path the real backends take)") {
    Warnings log;
    SUBCASE("a ticket that takes polls: reading until it answers, then compaction") {
        Rig rig(true, true);
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        render::MeshAsset* a = rig.mesh("a");
        const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1)};
        rig.frame(items);
        const std::uint32_t id = rig.scene.blas_ids_of(a)[0];
        CHECK(rig.scene.blas_state(id) == "queried");
        rig.frame(items);  // the size is asked for
        CHECK(rig.async->requests == 1);
        CHECK(rig.scene.blas_state(id) == "reading");
        rig.frame(items);  // poll 1 of 2
        CHECK(rig.scene.blas_state(id) == "reading");
        CHECK(count_kind(*rig.dev, gpu::CommandKind::CopyAccelStructure) == 0);
        rig.frame(items);  // poll 2: the answer, the smaller structure, the copy
        CHECK(rig.async->polls == 2);
        CHECK(rig.scene.blas_state(id) == "swap");
        CHECK(count_kind(*rig.dev, gpu::CommandKind::CopyAccelStructure) == 1);
        rig.frame(items);
        CHECK(rig.scene.blas_state(id) == "compacted");
        CHECK(rig.dev->errors().empty());
    }
    SUBCASE("every slot in flight (an invalid ticket): the BLAS asks again on a later frame") {
        Rig rig(true, true);
        rig.async->busyRequests = 2;
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        render::MeshAsset* a = rig.mesh("a");
        const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1)};
        rig.frame(items);
        const std::uint32_t id = rig.scene.blas_ids_of(a)[0];
        rig.frame(items);
        CHECK(rig.scene.blas_state(id) == "queried");
        rig.frame(items);
        CHECK(rig.scene.blas_state(id) == "queried");
        CHECK(rig.async->requests == 2);
        rig.frame(items);
        CHECK(rig.scene.blas_state(id) == "reading");
        for (int f = 0; f < 4; ++f) rig.frame(items);
        CHECK(rig.scene.blas_state(id) == "compacted");
        CHECK(rig.dev->errors().empty());
    }
    SUBCASE("a read the device refuses: the BLAS stays as built, one warning") {
        Rig rig(true, true);
        rig.async->failRequests = true;
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        render::MeshAsset* a = rig.mesh("a");
        const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1)};
        for (int f = 0; f < 5; ++f) rig.frame(items);
        const std::uint32_t id = rig.scene.blas_ids_of(a)[0];
        CHECK(rig.scene.blas_state(id) == "built");
        CHECK(rig.scene.instance_count() == 1);  // still traced
        CHECK(count_kind(*rig.dev, gpu::CommandKind::CopyAccelStructure) == 0);
        CHECK(log.count("could not be read back") == 1);
        CHECK(rig.dev->errors().empty());
    }
    SUBCASE("a BLAS freed while its size is being read: the answer is dropped, the others go on") {
        Rig rig(true, true);
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        render::MeshAsset* a = rig.mesh("a");
        render::MeshAsset* b = rig.mesh("b");
        const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1), rig.item(b, {2, 0, 0}, 2)};
        rig.frame(items);
        rig.frame(items);
        const std::uint32_t idA = rig.scene.blas_ids_of(a)[0];
        const std::uint32_t idB = rig.scene.blas_ids_of(b)[0];
        CHECK(rig.scene.blas_state(idA) == "reading");
        rig.scene.forget(a);
        CHECK(rig.scene.blas_state(idA) == "gone");
        const std::vector<render::MeshItem> onlyB{items[1]};
        for (int f = 0; f < 6; ++f) rig.frame(onlyB);
        CHECK(rig.scene.blas_state(idB) == "compacted");
        CHECK(rig.scene.instance_count() == 1);
        INFO(joined(rig.dev->errors()));
        CHECK(rig.dev->errors().empty());
    }
    SUBCASE("release() with a ticket in flight releases it") {
        Rig rig(true, true);
        REQUIRE(rig.scene.configure(rig.dev, true, 100));
        render::MeshAsset* a = rig.mesh("a");
        const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1)};
        rig.frame(items);
        rig.frame(items);
        CHECK(rig.async->requests == 1);
        CHECK(rig.async->releases == 0);
        rig.scene.release();
        CHECK(rig.async->releases == 1);
        CHECK(rig.dev->errors().empty());
    }
}

// ---- the layout the kernels read ------------------------------------------------------------------------------------------------------

TEST_CASE("rt records: the HLSL twin has the same fields, flags and masks as the C++ header") {
    static_assert(sizeof(render::RtInstanceRecord) == 128);
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/shaders/rt/rt_records.hlsli", std::ios::binary);
    REQUIRE(in.good());
    std::stringstream ss;
    ss << in.rdbuf();
    const std::string hlsl = ss.str();
    // A "static const uint NAME = <value>;" line gives NAME's value (shifts and hex).
    auto value_of = [&](const std::string& name) -> long {
        const std::size_t at = hlsl.find("static const uint " + name + " =");
        REQUIRE_MESSAGE(at != std::string::npos, name);
        const std::size_t eq = hlsl.find('=', at);
        const std::size_t end = hlsl.find(';', eq);
        std::string expr = hlsl.substr(eq + 1, end - eq - 1);
        const std::size_t shift = expr.find("<<");
        if (shift != std::string::npos) return 1L << std::stol(expr.substr(shift + 2));
        return std::stol(expr, nullptr, 0);
    };
    CHECK(value_of("kRtFlagOpaque") == long(render::kRtFlagOpaque));
    CHECK(value_of("kRtFlagCutout") == long(render::kRtFlagCutout));
    CHECK(value_of("kRtFlagTwoSided") == long(render::kRtFlagTwoSided));
    CHECK(value_of("kRtFlagBlended") == long(render::kRtFlagBlended));
    CHECK(value_of("kRtFlagUnlit") == long(render::kRtFlagUnlit));
    CHECK(value_of("kRtFlagFoliage") == long(render::kRtFlagFoliage));
    CHECK(value_of("kRtFlagCastsShadow") == long(render::kRtFlagCastsShadow));
    CHECK(value_of("kRtFlagCustomMaterial") == long(render::kRtFlagCustomMaterial));
    CHECK(value_of("kRtFlagSkinned") == long(render::kRtFlagSkinned));
    CHECK(value_of("kRtFlagRefractive") == long(render::kRtFlagRefractive));
    CHECK(value_of("kRtMaskOpaque") == long(render::kRtMaskOpaque));
    CHECK(value_of("kRtMaskCutout") == long(render::kRtMaskCutout));
    CHECK(value_of("kRtMaskBlended") == long(render::kRtMaskBlended));
    CHECK(value_of("kRtMaskCastsShadow") == long(render::kRtMaskCastsShadow));
    CHECK(value_of("kRtMaskFoliage") == long(render::kRtMaskFoliage));
    CHECK(value_of("kRtMaskEmissive") == long(render::kRtMaskEmissive));
    CHECK(value_of("kRtMaskRefractive") == long(render::kRtMaskRefractive));
    CHECK(value_of("kRtMaskSurfaces") == long(render::kRtMaskSurfaces));
    // The members, in order, with the sizes that make 128 bytes (a float4 is 16, a scalar 4).
    const std::size_t body = hlsl.find("struct RtInstanceRecord");
    REQUIRE(body != std::string::npos);
    const std::string s = hlsl.substr(body, hlsl.find("};", body) - body);
    const std::array<const char*, 11> members = {"float4 objectToWorldRow0",
                                                 "float4 objectToWorldRow1",
                                                 "float4 objectToWorldRow2",
                                                 "float4 albedo",
                                                 "float4 emissive",
                                                 "float roughness",
                                                 "float metalness",
                                                 "uint flags",
                                                 "uint blasId",
                                                 "float4 volume",
                                                 "float4 attenuation"};
    std::size_t at = 0;
    for (const char* m : members) {
        const std::size_t found = s.find(m, at);
        CHECK_MESSAGE(found != std::string::npos, m);
        if (found != std::string::npos) at = found;
    }
    CHECK(offsetof(render::RtInstanceRecord, albedo) == 48);
    CHECK(offsetof(render::RtInstanceRecord, emissive) == 64);
    CHECK(offsetof(render::RtInstanceRecord, roughness) == 80);
    CHECK(offsetof(render::RtInstanceRecord, blasId) == 92);
    CHECK(offsetof(render::RtInstanceRecord, volume) == 96);
    CHECK(offsetof(render::RtInstanceRecord, attenuation) == 112);
}

TEST_CASE("recording device: a geometry's vertex and index offsets must be aligned, and the error names the field") {
    Rig rig;
    gpu::BufferDesc vb;
    vb.size = 1024;
    vb.usage.accelBuildInput = true;
    vb.usage.copyDst = true;
    const gpu::Buffer vertices = rig.dev->make_buffer(vb);
    const gpu::Buffer indices = rig.dev->make_buffer(vb);
    gpu::AccelTriangles t;
    t.vertexBuffer = vertices;
    t.vertexStride = 12;
    t.vertexCount = 4;
    t.indexBuffer = indices;
    t.indexType = gpu::IndexType::Uint32;
    t.indexCount = 6;
    std::array<gpu::AccelTriangles, 1> g{t};
    CHECK(rig.dev->blas_sizes(g, {}).ok());
    g[0].vertexOffset = 2;
    auto bad = rig.dev->blas_sizes(g, {});
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("vertexOffset") != std::string::npos);
    g[0].vertexOffset = 4;
    g[0].indexOffset = 2;
    bad = rig.dev->blas_sizes(g, {});
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("indexOffset") != std::string::npos);
    g[0].indexType = gpu::IndexType::Uint16;
    g[0].indexOffset = 2;
    CHECK(rig.dev->blas_sizes(g, {}).ok());  // 2 is a whole number of 16-bit indices
    g[0].indexOffset = 1;
    bad = rig.dev->blas_sizes(g, {});
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("indexOffset") != std::string::npos);
}

// ---- the renderer ------------------------------------------------------------------------------------------------------------------

struct RtRenderer {
    Renderer renderer;
    gpu::RecordingDevice* dev = nullptr;
    bool ok = false;
    std::string error;
    explicit RtRenderer(bool deviceTraces = true) {
        gfx();  // the project root of the process (foliage files, meshes)
        gpu::DeviceInit init;
        init.recordingRayTracing = deviceTraces;
        auto made = gpu::make_device(gpu::Backend::Recording, init);
        REQUIRE_MESSAGE(made.ok(), (made.ok() ? "" : made.error().message));
        dev = dynamic_cast<gpu::RecordingDevice*>(made.value().get());
        RendererDeviceAccess::set_next_device(std::move(made.value()));
        RendererDesc d;
        d.designWidth = 160;
        d.designHeight = 96;
        d.headless = true;
        d.backend = GpuBackend::Recording;
        ok = renderer.init(d, gfx().gpu.environment(), &error);
        RendererDeviceAccess::set_next_device(nullptr);
        REQUIRE_MESSAGE(ok, error);
    }
    ~RtRenderer() { renderer.shutdown(); }
    RtRenderer(const RtRenderer&) = delete;
    RtRenderer& operator=(const RtRenderer&) = delete;

    void rays(int maxInstances = render::kRtDefaultMaxInstances) {
        render::RayTracingSettings s;
        s.enabled = true;
        s.shadows = render::RtShadows::Hard;
        s.maxInstances = maxInstances;
        renderer.set_ray_tracing(s);
    }
    void frame(World& w) {
        renderer.update(w);
        renderer.begin_frame();
        renderer.render_world(w, 0.0f);
        renderer.end_frame();
    }
    RtScene& scene() { return *RendererTestAccess::rt_scene(renderer); }
};

Entity add_camera(World& w, Vec3 at = {0, 2, 12}) {
    Entity cam = make(w, "cam", at);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.farPlane = 500.0f;
    return cam;
}

Entity add_mesh(World& w, const char* name, const char* mesh, Vec3 at) {
    Entity e = make(w, name, at);
    w.add<MeshRenderer>(e).mesh = mesh;
    return e;
}

TEST_CASE("rt renderer: with ray tracing off the frame is the frame without it, on a device that traces and on one "
          "that cannot") {
    Warnings log;
    auto stream = [&](bool deviceTraces, bool setting) {
        RtRenderer r(deviceTraces);
        if (setting) r.rays();
        World w;
        add_camera(w);
        add_mesh(w, "a", "cube", {0, 0, 0});
        add_mesh(w, "b", "sphere", {3, 0, 0});
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        INFO(joined(r.dev->errors()));
        CHECK(r.dev->errors().empty());
        CHECK(count_kind(*r.dev, gpu::CommandKind::BuildBlas) == 0);
        CHECK(count_kind(*r.dev, gpu::CommandKind::BuildTlas) == 0);
        CHECK_FALSE(r.scene().active());
        CHECK(r.scene().instance_count() == 0);
        return lines_of(*r.dev);
    };
    const std::vector<std::string> off = stream(true, false);  // a device that traces, the setting off
    CHECK(log.count("cannot trace rays") == 0);
    const std::vector<std::string> unsupported = stream(false, true);  // a device that cannot, the setting on
    REQUIRE(off.size() > 5);
    CHECK(off == unsupported);
    // One teaching message, however many frames: the reason, the nothing-is-traced, and where to look.
    CHECK(log.count("cannot trace rays") == 1);
    CHECK(log.count("factoria call render.ray_tracing") == 1);
}

TEST_CASE("rt renderer: the main camera's meshes become BLASes and a TLAS, built once and rebuilt every frame") {
    RtRenderer r;
    r.rays();
    World w;
    add_camera(w);
    Entity cubeA = add_mesh(w, "a", "cube", {-3, 0, 0});
    add_mesh(w, "b", "cube", {0, 0, 0});
    add_mesh(w, "c", "cube", {3, 0, 0});
    Entity ball = add_mesh(w, "d", "sphere", {0, 3, 0});
    w.get<MeshRenderer>(cubeA)->color = Color{1, 0, 0, 1};
    r.frame(w);
    INFO(joined(r.dev->errors()));
    CHECK(r.dev->errors().empty());
    REQUIRE(r.scene().active());
    CHECK(r.scene().instance_count() == 4);
    CHECK(r.scene().tlas().valid());
    CHECK(count_kind(*r.dev, gpu::CommandKind::BuildBlas) == 2);  // the cube and the sphere, however many instances
    CHECK(count_kind(*r.dev, gpu::CommandKind::BuildTlas) == 1);
    std::map<std::uint32_t, std::uint32_t> blasOf;
    std::map<std::uint32_t, float> xOf;
    for (const auto& f : r.scene().frame_instances()) {
        blasOf[f.entityId] = f.blasId;
        xOf[f.entityId] = f.instance.transform[3];
    }
    REQUIRE(blasOf.size() == 4);
    CHECK(blasOf[std::uint32_t(cubeA.index)] == blasOf[std::uint32_t(w.find("c").index)]);
    CHECK(blasOf[std::uint32_t(cubeA.index)] != blasOf[std::uint32_t(ball.index)]);
    CHECK(xOf[std::uint32_t(cubeA.index)] == doctest::Approx(-3.0f));
    CHECK(xOf[std::uint32_t(w.find("c").index)] == doctest::Approx(3.0f));

    for (int i = 0; i < 2; ++i) {
        r.dev->clear_commands();
        r.frame(w);
        CHECK(count_kind(*r.dev, gpu::CommandKind::BuildBlas) == 0);  // once per asset
        CHECK(count_kind(*r.dev, gpu::CommandKind::BuildTlas) == 1);  // every frame
    }
    for (std::uint32_t id : r.scene().blas_ids_of(nullptr)) (void)id;
    CHECK(r.dev->errors().empty());
    // Every BLAS is compacted two frames after its build.
    for (const auto& f : r.scene().frame_instances()) CHECK(r.scene().blas_state(f.blasId) == "compacted");
    // The setting off again frees everything on the next frame; the frame draws as before.
    r.renderer.set_ray_tracing({});
    r.dev->clear_commands();
    r.frame(w);
    CHECK_FALSE(r.scene().active());
    CHECK(count_kind(*r.dev, gpu::CommandKind::BuildTlas) == 0);
    CHECK(r.dev->errors().empty());
}

TEST_CASE("rt renderer: one level of detail per instance, the main camera's pick") {
    RtRenderer r;
    r.rays();
    World w;
    Entity cam = add_camera(w, {0, 0, 5});
    Entity lodded = make(w, "lodded", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(lodded);
    m.mesh = "cube";
    m.lods = Json::array({Json{{"mesh", "sphere"}, {"distance", 30.0}}});
    Entity plainCube = add_mesh(w, "cube", "cube", {5, 0, 0});
    Entity plainBall = add_mesh(w, "ball", "sphere", {-5, 0, 0});
    auto blas_of = [&](Entity e) {
        for (const auto& f : r.scene().frame_instances())
            if (f.entityId == std::uint32_t(e.index)) return f.blasId;
        return std::uint32_t(0);
    };
    r.frame(w);
    r.frame(w);
    REQUIRE(r.scene().instance_count() == 3);      // one instance per entity, never both levels
    CHECK(blas_of(lodded) == blas_of(plainCube));  // near: the cube
    CHECK(blas_of(lodded) != blas_of(plainBall));
    w.get<Transform>(cam)->position = {0, 0, 60};  // far: the sphere
    r.frame(w);
    r.frame(w);
    r.frame(w);
    REQUIRE(r.scene().instance_count() == 3);
    CHECK(blas_of(lodded) == blas_of(plainBall));
    CHECK(r.dev->errors().empty());
}

TEST_CASE("rt renderer: the instances of a foliage are traced, each with the foliage flag and mask") {
    RtRenderer r;
    r.rays();
    const std::string file = fs::path_to_utf8(gfx().projectDir / fs::path_from_utf8("rt_scene.foliage"));
    std::vector<FoliageInstance> in;
    for (int i = 0; i < 6; ++i) {
        FoliageInstance f;
        f.position = {float(i) * 2.0f - 5.0f, 0, -10};
        f.scale = 0.5f;
        in.push_back(f);
    }
    const auto written = write_foliage(file, in, 1);
    REQUIRE_MESSAGE(written.ok(), (written.ok() ? "" : written.error().message));
    World w;
    add_camera(w, {0, 2, 0});
    Entity forest = make(w, "forest", {0, 0, 0});
    w.add<Foliage>(forest).instances = file;
    add_mesh(w, "rock", "sphere", {0, 0, -4});
    r.frame(w);
    r.renderer.wait_foliage_loaded();
    r.frame(w);
    r.frame(w);
    int foliage = 0, plain = 0;
    std::set<std::uint32_t> foliageBlas;
    for (const auto& f : r.scene().frame_instances()) {
        if ((f.record.flags & render::kRtFlagFoliage) != 0) {
            ++foliage;
            foliageBlas.insert(f.blasId);
            CHECK((f.instance.mask & render::kRtMaskFoliage) != 0);
        } else {
            ++plain;
            CHECK((f.instance.mask & render::kRtMaskFoliage) == 0);
        }
    }
    CHECK(foliage == 6);
    CHECK(foliageBlas.size() == 1);  // the same mesh: one BLAS
    CHECK(plain == 1);
    CHECK(r.dev->errors().empty());
}

TEST_CASE("rt renderer: over the cap the nearest instances stay and the warning comes once") {
    Warnings log;
    RtRenderer r;
    r.rays(4);
    World w;
    add_camera(w, {0, 0, 0});
    std::set<std::uint32_t> nearest;
    for (int d : {7, 2, 9, 1, 10, 4, 3, 8, 6, 5}) {
        Entity e = add_mesh(w, ("c" + std::to_string(d)).c_str(), "cube", {0, 0, -float(d) * 3.0f});
        if (d <= 4) nearest.insert(std::uint32_t(e.index));
    }
    r.frame(w);
    r.frame(w);
    r.frame(w);
    CHECK(r.scene().instance_count() == 4);
    CHECK(r.scene().stats().droppedOverCap == 6);
    std::set<std::uint32_t> kept;
    for (const auto& f : r.scene().frame_instances()) kept.insert(f.entityId);
    CHECK(kept == nearest);
    CHECK(log.count("render.rayTracing.maxInstances") == 1);
    CHECK(r.dev->errors().empty());
}

TEST_CASE("rt renderer: the TLAS lives in rebased space: a floating origin shift moves the instances and the cached "
          "records") {
    RtRenderer r;
    r.rays();
    World w;
    add_camera(w, {200, 2, 12});
    Entity far = add_mesh(w, "far", "cube", {200, 0, 0});
    r.frame(w);
    r.frame(w);
    REQUIRE(r.scene().frame_instances().size() == 1);
    CHECK(r.scene().frame_instances()[0].instance.transform[3] == doctest::Approx(200.0f));
    REQUIRE(r.scene().previous_records().size() == 1);
    const std::uint64_t shifts = RendererTestAccess::origin_shifts(r.renderer);
    w.rebase({192, 0, 0});  // the observers run now: the renderer's cache moves with the world
    CHECK(RendererTestAccess::origin_shifts(r.renderer) == shifts + 1);
    CHECK(w.get<Transform>(far)->position.x == doctest::Approx(8.0f));
    CHECK(r.scene().previous_records()[0].objectToWorld[3] == doctest::Approx(8.0f));
    r.frame(w);
    REQUIRE(r.scene().frame_instances().size() == 1);
    CHECK(r.scene().frame_instances()[0].instance.transform[3] == doctest::Approx(8.0f));
    CHECK(r.scene().previous_records()[0].objectToWorld[3] == doctest::Approx(8.0f));
    CHECK(r.dev->errors().empty());
}

TEST_CASE("rt renderer: an asset that goes frees its BLASes") {
    RtRenderer r;
    r.rays();
    World w;
    add_camera(w);
    add_mesh(w, "a", "cube", {0, 0, 0});
    add_mesh(w, "b", "sphere", {3, 0, 0});
    r.frame(w);
    r.frame(w);
    r.frame(w);
    std::vector<std::uint32_t> ids;
    for (const auto& f : r.scene().frame_instances()) ids.push_back(f.blasId);
    REQUIRE(ids.size() == 2);
    for (std::uint32_t id : ids) CHECK(r.scene().blas_state(id) == "compacted");
    r.renderer.clear_asset_cache();  // every mesh asset is destroyed
    for (std::uint32_t id : ids) CHECK(r.scene().blas_state(id) == "gone");
    r.dev->clear_commands();
    r.frame(w);  // the meshes load again: new BLASes, built again
    CHECK(count_kind(*r.dev, gpu::CommandKind::BuildBlas) == 2);
    CHECK(r.scene().instance_count() == 2);
    INFO(joined(r.dev->errors()));
    CHECK(r.dev->errors().empty());
}

TEST_CASE("rt renderer: the same scene records the same calls on two renderers") {
    auto run = [] {
        RtRenderer r;
        r.rays(6);
        World w;
        add_camera(w);
        for (int i = 0; i < 9; ++i)
            add_mesh(w, ("m" + std::to_string(i)).c_str(), i % 3 == 0 ? "sphere" : "cube",
                     {float(i) * 2.0f - 8.0f, 0, -float(i)});
        for (int f = 0; f < 5; ++f) r.frame(w);
        CHECK(r.dev->errors().empty());
        return lines_of(*r.dev);
    };
    const std::vector<std::string> first = run();
    const std::vector<std::string> second = run();
    REQUIRE(first.size() > 50);
    CHECK(first == second);
}

// ---- skinned meshes (M79 P1k) ------------------------------------------------------------------------------------------------------

std::vector<gpu::RecordedCommand> commands_of(const gpu::RecordingDevice& dev, gpu::CommandKind kind) {
    std::vector<gpu::RecordedCommand> out;
    for (const gpu::RecordedCommand& c : dev.commands())
        if (c.kind == kind) out.push_back(c);
    return out;
}

Animator posed(float lift) {
    Animator a;
    a.palette = {Mat4::identity(), Mat4::translate({0, lift, 0})};
    return a;
}

TEST_CASE("rt skin: a skinned item is skinned once a frame, built with update in the first, refitted until the Nth and "
          "rebuilt there") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.use_kernel();
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator anim = posed(1.0f);
    const std::vector<render::MeshItem> items{rig.skinned_item(m, &anim, {0, 0, -3}, 1)};
    constexpr int N = int(RtScene::kSkinRebuildFrames);

    rig.dev->clear_commands();
    rig.frame(items);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::Dispatch) == 1);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BeginComputePass) == 1);
    const auto first = commands_of(*rig.dev, gpu::CommandKind::BuildBlas);
    REQUIRE(first.size() == 1);
    CHECK(first[0].args[3] ==
          0);  // built from scratch: with allowUpdate (the refits below are refused by the device otherwise)
    CHECK(count_kind(*rig.dev, gpu::CommandKind::QueryCompactedSize) == 0);  // never compacted
    CHECK(rig.scene.stats().skinnedBuilds == 1);
    CHECK(rig.scene.stats().skinnedDispatches == 1);
    CHECK(rig.scene.stats().skinnedVertices == 4);
    CHECK(rig.scene.instance_count() == 1);
    CHECK((rig.scene.frame_instances()[0].record.flags & render::kRtFlagSkinned) != 0);
    const std::uint32_t id = rig.scene.frame_instances()[0].blasId;
    CHECK(rig.scene.blas_state(id) == "built");
    // The dispatch is before the build in the stream: the build reads what the kernel wrote.
    {
        const std::vector<std::string> lines = lines_of(*rig.dev);
        int dispatchAt = -1, buildAt = -1;
        for (int i = 0; i < int(lines.size()); ++i) {
            if (dispatchAt < 0 && lines[std::size_t(i)].find("dispatch") != std::string::npos) dispatchAt = i;
            if (buildAt < 0 && lines[std::size_t(i)].find("build_blas") != std::string::npos) buildAt = i;
        }
        CHECK(dispatchAt >= 0);
        CHECK(dispatchAt < buildAt);
    }

    for (int f = 2; f <= N; ++f) {
        rig.dev->clear_commands();
        rig.frame(items);
        CAPTURE(f);
        CHECK(count_kind(*rig.dev, gpu::CommandKind::Dispatch) == 1);
        const auto b = commands_of(*rig.dev, gpu::CommandKind::BuildBlas);
        REQUIRE(b.size() == 1);
        CHECK(b[0].args[3] == 1);  // a refit
        CHECK(rig.scene.stats().skinnedRefits == 1);
        CHECK(rig.scene.stats().skinnedBuilds == 0);
        CHECK(rig.scene.frame_instances()[0].blasId == id);  // the same BLAS all along
    }
    // From frame N + 1 on, the rebuild waits for its phase (the BLAS id mod kSkinRebuildSpread): exactly one full build in the next
    // kSkinRebuildSpread frames, at the frame whose number plus the id is a multiple of the spread, refits in the others.
    int rebuilds = 0;
    for (int f = N + 1; f <= N + int(RtScene::kSkinRebuildSpread); ++f) {
        rig.dev->clear_commands();
        rig.frame(items);
        CAPTURE(f);
        const auto b = commands_of(*rig.dev, gpu::CommandKind::BuildBlas);
        REQUIRE(b.size() == 1);
        const bool phase = (std::uint32_t(f) + id) % RtScene::kSkinRebuildSpread == 0;
        CHECK((b[0].args[3] == 0) == phase);
        CHECK(rig.scene.stats().skinnedBuilds == (phase ? 1u : 0u));
        rebuilds += phase ? 1 : 0;
    }
    CHECK(rebuilds == 1);
    rig.dev->clear_commands();
    rig.frame(items);  // and refits again
    CHECK(commands_of(*rig.dev, gpu::CommandKind::BuildBlas)[0].args[3] == 1);
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt skin: the kernel is asked for in every frame that skins, so a pipeline the cache destroyed in between is "
          "not used") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.use_kernel();
    int asked = 0;
    rig.scene.skinKernel = [&] {
        ++asked;
        return rig.kernel;
    };
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator a = posed(1.0f);
    const std::vector<render::MeshItem> items{rig.skinned_item(m, &a, {0, 0, -3}, 1)};
    rig.frame(items);
    CHECK(asked > 0);
    // No animated character for longer than the cache keeps an idle pipeline: the kernel is destroyed, a new one is made when asked for.
    for (int f = 0; f < 3; ++f) rig.frame({});
    rig.dev->destroy_pipeline(rig.kernel);
    const gpu::Pipeline stale = rig.kernel;
    gpu::PipelineDesc pd;
    pd.compute = true;
    pd.shader = rig.dev->make_shader(gpu::generated_shader_desc(*rig.dev, &rt_skin_rt_skin_shader_desc));
    pd.label = "rt skin again";
    rig.kernel = rig.dev->make_pipeline(pd);
    REQUIRE(rig.dev->state(rig.kernel) == gpu::ResourceState::Valid);
    CHECK(rig.kernel.id != stale.id);
    const int before = asked;
    rig.dev->clear_commands();
    rig.frame(items);
    CHECK(asked > before);  // asked again, not remembered
    CHECK(count_kind(*rig.dev, gpu::CommandKind::Dispatch) == 1);
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
    rig.frame(items);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt skin: the kernel comes from Gpu's pipeline cache, and a sweep that destroyed it while no character was "
          "in view is "
          "answered by a new one") {
    // The path of the renderer (Renderer::Impl::rt_skin_pipeline): Gpu::compute_pipeline, swept by Gpu::sweep_pipelines.
    render::Gpu gpu;  // before the rig: the rig releases the scene while the device still lives
    Rig rig;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error, std::move(rig.owned)), error);
    gpu.set_pipeline_cache_limits(0, 4);  // every pipeline idle for 4 frames goes at the next sweep (every 16 frames)
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    gpu::Shader shader = rig.dev->make_shader(gpu::generated_shader_desc(*rig.dev, &rt_skin_rt_skin_shader_desc));
    REQUIRE(rig.dev->state(shader) == gpu::ResourceState::Valid);
    rig.scene.skinKernel = [&] { return gpu.compute_pipeline(shader); };
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator a = posed(1.0f);
    const std::vector<render::MeshItem> items{rig.skinned_item(m, &a, {0, 0, -3}, 1)};
    const auto frame = [&](const std::vector<render::MeshItem>& list) {
        gpu.begin_frame();
        rig.scene.begin_frame(true, [&] { gpu.commit_frame(); });
        rig.scene.collect(list, {}, {0, 0, 0}, true);
        gpu::CommandList& cl = rig.dev->begin_commands("rt");
        rig.scene.record(cl);
        rig.dev->submit(cl);
        gpu.commit_frame();  // submits Gpu's own list and commits
        gpu.note_commit();
    };
    frame(items);
    REQUIRE(gpu.pipelines_made() == 1);
    CHECK(gpu.pipelines_evicted() == 0);
    const gpu::Pipeline first = gpu.compute_pipeline(shader);
    // No character in view for longer than the cache keeps an idle pipeline: the sweep destroys the kernel.
    for (int f = 0; f < 40; ++f) frame({});
    CHECK(gpu.pipelines_evicted() == 1);
    CHECK(rig.dev->state(first) != gpu::ResourceState::Valid);
    // The character is back: the scene asks the cache again and gets a pipeline that lives, and the dispatch uses it.
    rig.dev->clear_commands();
    frame(items);
    CHECK(gpu.pipelines_made() == 2);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::Dispatch) == 1);
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
    frame(items);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt skin: when the rebuilds that are due outnumber the build budget, the oldest build goes first and no "
          "instance waits "
          "for ever") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.use_kernel();
    rig.scene.set_builds_per_frame(
        1);  // 100 instances rebuilt every 60 frames want 1.7 builds a frame: more than the budget
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator anim = posed(1.0f);
    std::vector<render::MeshItem> items;
    for (std::uint32_t i = 0; i < 100; ++i) items.push_back(rig.skinned_item(m, &anim, {float(i), 0, -3}, i + 1));
    for (int f = 0; f < 700; ++f) {
        rig.dev->clear_commands();
        rig.frame(items);
    }
    CHECK(rig.scene.stats().skinnedInstances == 100);
    // Rebuilt in turn, the oldest first: the age of the oldest build stays near a turn of the crowd (100 builds at one a frame), where an
    // order by id would leave the last ids at the age of the scene.
    std::uint64_t oldest = 0;
    for (const auto& f : rig.scene.frame_instances())
        oldest = std::max(oldest, rig.scene.frame_counter() - rig.scene.blas_built_frame(f.blasId));
    CHECK_MESSAGE(oldest <= 260, "the oldest BLAS was built " << oldest << " frames ago");
    CHECK(rig.dev->errors().empty());
}

TEST_CASE("rt skin: with no skinning program the skinned meshes leave the TLAS and count as untraced casters") {
    Warnings log;
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.scene.skinKernel = [] { return gpu::Pipeline{}; };  // the driver refused rt_skin: no pipeline
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator anim = posed(1.0f);
    std::vector<render::MeshItem> items{rig.skinned_item(m, &anim, {0, 0, -3}, 1)};
    rig.frame(items);
    CHECK(rig.scene.stats().skinnedInstances == 0);
    CHECK(rig.scene.stats().skippedSkinned == 1);
    CHECK(rig.scene.stats().untracedCasters ==
          1);  // the lit pass then takes min(rt, cascade): the character keeps its sun shadow
    CHECK(log.count("the skinning program is not available") == 1);
    // A skinned mesh that does not cast a shadow is not a lost shadow.
    rig.renderers.back().castShadows = false;
    rig.frame(items);
    CHECK(rig.scene.stats().untracedCasters == 0);
}

TEST_CASE("rt skin: the bones' box jumping rebuilds the BLAS at once, a small move is a refit") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.use_kernel();
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator anim = posed(0.0f);
    const std::vector<render::MeshItem> items{rig.skinned_item(m, &anim, {0, 0, -3}, 1)};
    rig.frame(items);
    const auto last_is_update = [&](bool expectUpdate) {
        const auto b = commands_of(*rig.dev, gpu::CommandKind::BuildBlas);
        REQUIRE(b.size() == 1);
        CHECK((b[0].args[3] == 1) == expectUpdate);
    };
    anim.palette[1] = Mat4::translate({0, 0.2f, 0});  // 0.2 of a 2-wide box: under kSkinExtentJump
    rig.dev->clear_commands();
    rig.frame(items);
    last_is_update(true);
    anim.palette[1] = Mat4::translate({0, 5.0f, 0});  // a bone teleported
    rig.dev->clear_commands();
    rig.frame(items);
    last_is_update(false);
    CHECK(rig.scene.stats().skinnedBuilds == 1);
    rig.dev->clear_commands();
    rig.frame(items);  // the new box is the one built for: back to refits
    last_is_update(true);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE(
    "rt skin: two skinned instances of one asset get two BLASes, a static one a third, and the records say which") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.use_kernel();
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator a = posed(1.0f), b = posed(2.0f);
    std::vector<render::MeshItem> items{
        rig.skinned_item(m, &a, {0, 0, -3}, 1), rig.skinned_item(m, &b, {2, 0, -3}, 2),
        rig.item(m, {4, 0, -3}, 3)};  // the third is drawn in its bind pose (no palette)
    rig.frame(items);
    CHECK(rig.dev->errors().empty());
    CHECK(rig.scene.instance_count() == 3);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::Dispatch) == 2);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 3);  // 2 skinned + 1 static
    std::map<std::uint32_t, std::uint32_t> blasOf;
    std::map<std::uint32_t, std::uint32_t> flagsOf;
    for (const auto& f : rig.scene.frame_instances()) {
        blasOf[f.entityId] = f.blasId;
        flagsOf[f.entityId] = f.record.flags;
    }
    REQUIRE(blasOf.size() == 3);
    CHECK(blasOf[1] != blasOf[2]);
    CHECK(blasOf[1] != blasOf[3]);
    CHECK(blasOf[2] != blasOf[3]);
    CHECK((flagsOf[1] & render::kRtFlagSkinned) != 0);
    CHECK((flagsOf[2] & render::kRtFlagSkinned) != 0);
    CHECK((flagsOf[3] & render::kRtFlagSkinned) == 0);
    CHECK(rig.scene.skinned_positions_of(blasOf[1]).id != rig.scene.skinned_positions_of(blasOf[2]).id);
    CHECK(rig.scene.skinned_positions_of(blasOf[3]).id == 0);
    // The palettes of two Animators are two palettes; two items of one Animator share one.
    rig.dev->clear_commands();
    items[1].anim = &a;
    rig.frame(items);
    const auto writes = commands_of(*rig.dev, gpu::CommandKind::WriteBuffer);
    std::size_t paletteBytes = 0;
    for (const auto& w : writes)
        if (w.args[0] > 0 && w.args[0] % int(render::kRtSkinPaletteFloats * sizeof(float)) == 0)
            paletteBytes = std::size_t(w.args[0]);
    CHECK(paletteBytes == render::kRtSkinPaletteFloats * sizeof(float));  // one palette
}

TEST_CASE("rt skin: an instance that leaves frees its BLAS after the frames in flight and its buffer at once") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.use_kernel();
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator a = posed(1.0f), b = posed(2.0f);
    const std::vector<render::MeshItem> both{rig.skinned_item(m, &a, {0, 0, -3}, 1),
                                             rig.skinned_item(m, &b, {2, 0, -3}, 2)};
    rig.frame(both);
    rig.frame(both);
    REQUIRE(rig.scene.instance_count() == 2);
    std::map<std::uint32_t, std::uint32_t> blasOf;
    std::map<std::uint32_t, gpu::AccelStructure> structOf;
    for (const auto& f : rig.scene.frame_instances()) {
        blasOf[f.entityId] = f.blasId;
        structOf[f.entityId] = f.instance.blas;
    }
    const gpu::Buffer leaving = rig.scene.skinned_positions_of(blasOf[2]);
    REQUIRE(leaving.valid());
    CHECK(rig.dev->state(leaving) == gpu::ResourceState::Valid);
    const std::vector<render::MeshItem> one{both[0]};
    rig.frame(one);  // entity 2 is gone from the frame
    CHECK(rig.scene.blas_state(blasOf[2]) == "gone");
    CHECK(rig.scene.blas_state(blasOf[1]) == "built");
    CHECK(rig.dev->state(leaving) == gpu::ResourceState::Invalid);  // a stale handle is Invalid
    // The structure is kept while a TLAS of a frame in flight can still name it, then destroyed.
    CHECK(rig.dev->accel_structure_state(structOf[2]) == gpu::ResourceState::Valid);
    for (std::uint64_t f = 0; f < std::uint64_t(gpu::kInflightFrames) + 1; ++f) rig.frame(one);
    CHECK(rig.dev->accel_structure_state(structOf[2]) == gpu::ResourceState::Invalid);
    CHECK(rig.dev->accel_structure_state(structOf[1]) == gpu::ResourceState::Valid);
    // The same entity coming back gets a new BLAS, built from scratch.
    rig.dev->clear_commands();
    rig.frame(both);
    CHECK(count_kind(*rig.dev, gpu::CommandKind::BuildBlas) == 2);  // the new one (full) and entity 1's refit
    INFO(joined(rig.dev->errors()));
    CHECK(rig.dev->errors().empty());
    // The asset going away frees its skinned BLASes with the rest.
    rig.scene.forget(m);
    CHECK(rig.scene.blas_state(blasOf[1]) == "gone");
}

TEST_CASE("rt skin: with the scene off nothing is allocated and nothing is dispatched") {
    Rig rig;
    REQUIRE_FALSE(rig.scene.configure(rig.dev, false, 1000));
    rig.use_kernel();
    render::MeshAsset* m = rig.skinned_mesh("rig");
    Animator a = posed(1.0f);
    const std::vector<render::MeshItem> items{rig.skinned_item(m, &a, {0, 0, -3}, 1)};
    rig.dev->clear_commands();
    rig.frame(items);
    rig.frame(items);
    for (const auto& c : rig.dev->commands()) {
        CAPTURE(c.text);
        CHECK(c.kind != gpu::CommandKind::Dispatch);
        CHECK(c.kind != gpu::CommandKind::BuildBlas);
        CHECK(c.kind != gpu::CommandKind::BuildTlas);
        CHECK(c.kind != gpu::CommandKind::WriteBuffer);
    }
    CHECK(rig.scene.instance_count() == 0);
    CHECK(rig.scene.stats().skinnedDispatches == 0);
    CHECK(rig.scene.stats().blasLive == 0);
    // Turned on, then off again: everything goes.
    REQUIRE(rig.scene.configure(rig.dev, true, 1000));
    rig.frame(items);
    CHECK(rig.scene.instance_count() == 1);
    const gpu::Buffer positions = rig.scene.skinned_positions_of(rig.scene.frame_instances()[0].blasId);
    REQUIRE(positions.valid());
    rig.scene.configure(rig.dev, false, 1000);
    CHECK(rig.dev->state(positions) == gpu::ResourceState::Invalid);
    CHECK(rig.dev->errors().empty());
}

TEST_CASE(
    "rt skin: without the program, or past the budget, the skinned instances are left out with one teaching warning") {
    Warnings log;
    SUBCASE("no program") {
        Rig rig;
        REQUIRE(rig.scene.configure(rig.dev, true, 1000));  // no use_kernel(): no pipeline
        render::MeshAsset* m = rig.skinned_mesh("rig");
        Animator a = posed(1.0f);
        const std::vector<render::MeshItem> items{rig.skinned_item(m, &a, {0, 0, -3}, 1), rig.item(m, {1, 0, -3}, 2)};
        rig.frame(items);
        rig.frame(items);
        CHECK(rig.scene.instance_count() == 1);  // the static one
        CHECK(rig.scene.stats().skippedSkinned == 1);
        CHECK(count_kind(*rig.dev, gpu::CommandKind::Dispatch) == 0);
        CHECK(log.count("skinning program is not available") == 1);
        CHECK(rig.dev->errors().empty());
    }
    SUBCASE("a mesh over the budget of a part") {
        Rig rig;
        REQUIRE(rig.scene.configure(rig.dev, true, 1000));
        rig.use_kernel();
        render::MeshAsset* m = rig.skinned_mesh("big");
        m->parts[0].vertexCount = int(render::kRtSkinMaxPartVertices) + 1;
        Animator a = posed(1.0f);
        const std::vector<render::MeshItem> items{rig.skinned_item(m, &a, {0, 0, -3}, 1)};
        rig.frame(items);
        rig.frame(items);
        CHECK(rig.scene.instance_count() == 0);
        CHECK(rig.scene.stats().skippedSkinned == 1);
        CHECK(log.count("over the budget") == 1);
        CHECK(log.count("Hint:") == 1);
    }
}

TEST_CASE("rt skin: the same skinned scene records the same calls twice") {
    auto run = [] {
        Rig rig;
        REQUIRE(rig.scene.configure(rig.dev, true, 1000));
        rig.use_kernel();
        render::MeshAsset* m = rig.skinned_mesh("rig", 2);
        Animator a = posed(1.0f), b = posed(3.0f);
        std::vector<render::MeshItem> items{rig.skinned_item(m, &a, {0, 0, -3}, 1),
                                            rig.skinned_item(m, &b, {2, 0, -5}, 2),
                                            rig.item(rig.mesh("s"), {1, 0, -2}, 3)};
        for (int f = 0; f < 8; ++f) {
            b.palette[1] = Mat4::translate({0, f == 5 ? 9.0f : 1.0f + 0.01f * float(f), 0});
            rig.frame(items);
        }
        CHECK(rig.dev->errors().empty());
        return lines_of(*rig.dev);
    };
    const std::vector<std::string> first = run();
    const std::vector<std::string> second = run();
    REQUIRE(first.size() > 40);
    CHECK(first == second);
}

TEST_CASE("rt skin: the CPU twin of the kernel is the vertex shader's blend of four joints") {
    std::vector<Mat4> palette(3, Mat4::identity());
    palette[1] = Mat4::translate({0, 2, 0});
    palette[2] = Mat4::translate({1, 0, 0}) * Mat4::rotate_z_deg(90.0f);
    std::vector<float> rows(render::kRtSkinPaletteFloats);
    render::rt_skin_pack_palette(palette, rows.data());
    CHECK(rows[0] == 1.0f);                     // joint 0, row 0 = (1, 0, 0, 0)
    CHECK(rows[(1 * 3 + 1) * 4 + 3] == 2.0f);   // joint 1, row 1: the lift
    CHECK(rows[(63 * 3 + 2) * 4 + 2] == 1.0f);  // a joint past the palette is the identity
    render::MeshVertex v{};
    v.px = 1.0f;
    v.py = 0.5f;
    v.pz = -1.0f;
    render::SkinVertex s{};
    s.joints[0] = 1;
    s.weights[0] = 1.0f;
    Vec3 p = render::rt_skin_position(v, s, rows.data());
    CHECK(p.x == doctest::Approx(1.0f));
    CHECK(p.y == doctest::Approx(2.5f));
    CHECK(p.z == doctest::Approx(-1.0f));
    s.joints[1] = 0;
    s.weights[0] = 0.25f;
    s.weights[1] = 0.75f;  // 0.25 of the lift
    p = render::rt_skin_position(v, s, rows.data());
    CHECK(p.y == doctest::Approx(0.5f + 0.5f));
    s.joints[2] = 2;
    s.weights[0] = s.weights[1] = 0.0f;
    s.weights[2] = 1.0f;  // the rotated and moved joint: the engine's own matrix is the reference
    p = render::rt_skin_position(v, s, rows.data());
    const Vec3 want = palette[2].transform_point({1.0f, 0.5f, -1.0f});
    CHECK(p.x == doctest::Approx(want.x).epsilon(1e-5));
    CHECK(p.y == doctest::Approx(want.y).epsilon(1e-5));
    CHECK(p.z == doctest::Approx(want.z).epsilon(1e-5));
    s.joints[2] =
        255;  // a byte past the palette is clamped to the last joint, like the kernel (never a read out of range)
    p = render::rt_skin_position(v, s, rows.data());
    CHECK(p.x == doctest::Approx(1.0f));
}

void install_rig_file(const char* repoRelative, const char* projectPath) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + repoRelative, std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(!text.empty());
    REQUIRE(fs::write_text(projectPath, text).ok());
}

TEST_CASE("rt renderer: a skinned glTF is skinned and traced from its own BLAS, and with ray tracing off nothing of it "
          "is recorded") {
    install_rig_file("engine/render/tests/data/skinned_two_bone.gltf", "assets/rig.gltf");
    auto scene = [](RtRenderer& r, World& w) {
        add_camera(w, {0, 1, 8});
        Entity rig = make(w, "rig", {0, 0, 0});
        w.add<MeshRenderer>(rig).mesh = "assets/rig.gltf";
        w.add<Animator>(rig).clip = "Slide";
        update_animators(w, 0.0f);
        r.frame(w);
        update_animators(w, 0.3f);
        r.frame(w);
        return rig;
    };
    {
        RtRenderer r;
        r.rays();
        World w;
        const Entity rig = scene(r, w);
        INFO(joined(r.dev->errors()));
        CHECK(r.dev->errors().empty());
        REQUIRE(r.scene().active());
        CHECK(r.scene().stats().skinnedInstances == 1);
        CHECK(r.scene().stats().skinnedDispatches == 1);
        CHECK(r.scene().stats().skinnedRefits == 1);
        bool found = false;
        for (const auto& f : r.scene().frame_instances())
            if (f.entityId == std::uint32_t(rig.index)) {
                found = true;
                CHECK((f.record.flags & render::kRtFlagSkinned) != 0);
            }
        CHECK(found);
        CHECK(r.dev->stream_text().find("rt-skin") != std::string::npos);
    }
    {
        RtRenderer r(
            true);  // the device traces, the setting is off: not one call of the skinning, not one buffer for it
        World w;
        scene(r, w);
        CHECK(r.dev->errors().empty());
        CHECK_FALSE(r.scene().active());
        CHECK(count_kind(*r.dev, gpu::CommandKind::Dispatch) == 0);
        CHECK(r.dev->stream_text().find("rt-skin") == std::string::npos);
        CHECK(r.dev->stream_text().find("build_blas") == std::string::npos);
    }
}

TEST_CASE("rt renderer: ray tracing turned on after a mesh was loaded from disk reloads it in place and traces it") {
    // Assets::set_accel_input: the meshes uploaded before the switch had no accelBuildInput, so they are loaded again from their files.
    Warnings log;
    install_rig_file("engine/render/tests/data/skinned_two_bone.gltf", "assets/rig.gltf");
    RtRenderer r;
    World w;
    add_camera(w, {0, 1, 8});
    Entity e = make(w, "rig", {0, 0, 0});
    w.add<MeshRenderer>(e).mesh = "assets/rig.gltf";
    r.frame(w);  // ray tracing is off: the file is read once, its buffers have no build usage
    CHECK_FALSE(r.scene().active());
    CHECK(r.dev->errors().empty());
    r.rays();
    r.frame(w);  // on: the mesh is read again (the same asset, new buffers) and the scene builds it
    REQUIRE(r.scene().active());
    INFO(joined(r.dev->errors()));
    CHECK(r.dev->errors().empty());
    CHECK(r.scene().stats().instances == 1);
    CHECK(r.scene().stats().blasLive >= 1);
    CHECK(r.scene().stats().skippedUntraceable == 0);
    CHECK(count_kind(*r.dev, gpu::CommandKind::BuildBlas) >= 1);
    CHECK(log.count("unknown mesh") == 0);
    CHECK(log.count("not found") == 0);
    // Off and on again: the frame is still the traced one.
    render::RayTracingSettings off;
    r.renderer.set_ray_tracing(off);
    r.frame(w);
    CHECK_FALSE(r.scene().active());
    r.rays();
    r.frame(w);
    CHECK(r.scene().stats().instances == 1);
    CHECK(r.dev->errors().empty());
}

}  // namespace
