// M79 P1s: the acceleration structures of the scene (src/rt_scene.h, src/rt_records.h; docs/design/ARCHITECTURE_RT_SCENE.md), on the
// RecordingDevice with ray tracing. The counts are units of builds, instances and records, never times. Two kinds of cases: the scene on
// its own (RtScene with hand-made assets: every rule of what is traced, the cap, the compaction, the records) and the renderer's frame
// (the setting, the device, the main camera's items, LOD, foliage, the floating origin, an asset going away).
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <fstream>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/scene/foliage.h"
#include "gpu/recording_device.h"
#include "render_internal.h"
#include "renderer_impostor.h"
#include "renderer_terrain.h"
#include "renderer_test_access.h"
#include "rt_scene.h"

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
    std::vector<MeshRenderer> renderers;  // reserved up front: the items point into it

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
        renderers.reserve(256);
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
    // The record buffer holds what the frame says: one 96-byte record per instance, written before the TLAS build.
    int writes = 0;
    for (const gpu::RecordedCommand& cmd : rig.dev->commands())
        if (cmd.kind == gpu::CommandKind::WriteBuffer && cmd.args[0] == int(4 * sizeof(render::RtInstanceRecord)))
            ++writes;
    CHECK(writes == 1);
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
    render::MeshItem skinned = rig.item(m, {1, 0, 0}, 2);
    skinned.anim = &animator;
    items.push_back(skinned);
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

    int skinnedSeen = 0;
    rig.scene.onSkinned = [&](const render::MeshItem& mi) { skinnedSeen += mi.anim == &animator ? 1 : 0; };
    rig.frame(items);
    rig.frame(items);
    const render::RtSceneStats& st = rig.scene.stats();
    CHECK(st.candidates == 9);
    CHECK(rig.scene.instance_count() == 3);
    std::set<std::uint32_t> traced;
    for (const auto& f : rig.scene.frame_instances()) traced.insert(f.entityId);
    CHECK(traced == std::set<std::uint32_t>{1, 6, 7});
    CHECK(st.skippedSkinned == 1);
    CHECK(st.skippedImpostor == 1);
    CHECK(st.skippedTerrain == 1);
    CHECK(st.skippedFading == 1);
    CHECK(st.skippedGpuDriven == 1);
    CHECK(st.skippedUntraceable == 1);
    CHECK(skinnedSeen == 2);  // once per skinned item per frame
    // One line about the skinned meshes, once (not one a frame).
    CHECK(log.count("skinned meshes") == 1);
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
    CHECK(log.count("a BLAS could not be built") == 1);  // once, not a line per frame
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

TEST_CASE("rt scene: a mesh whose geometry changes every frame retires its BLAS each frame and destroys it later") {
    Rig rig;
    REQUIRE(rig.scene.configure(rig.dev, true, 100));
    render::MeshAsset* a = rig.mesh("animated");
    const std::vector<render::MeshItem> items{rig.item(a, {0, 0, 0}, 1)};
    std::vector<gpu::AccelStructure> seen;
    for (int f = 0; f < 8; ++f) {
        ++a->geometryVersion;
        rig.frame(items);
        seen.push_back(rig.scene.blas_structure(rig.scene.blas_ids_of(a)[0]));
        // Each earlier structure is alive while a frame in flight may still name it.
        for (std::size_t i = 0; i + 1 < seen.size(); ++i) {
            const bool old = i + 1 + std::size_t(gpu::kInflightFrames) + 1 <= std::size_t(f) + 1;
            if (!old) CHECK(rig.dev->accel_structure_state(seen[i]) == gpu::ResourceState::Valid);
        }
    }
    // Bounded, nothing piles up: at most the BLAS and its compaction target of each of the frames in flight and the one being recorded.
    CHECK(rig.scene.retired_count() <= 2 * (std::size_t(gpu::kInflightFrames) + 1));
    CHECK(rig.dev->accel_structure_state(seen[0]) != gpu::ResourceState::Valid);
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
    static_assert(sizeof(render::RtInstanceRecord) == 96);
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
    CHECK(value_of("kRtMaskOpaque") == long(render::kRtMaskOpaque));
    CHECK(value_of("kRtMaskCutout") == long(render::kRtMaskCutout));
    CHECK(value_of("kRtMaskBlended") == long(render::kRtMaskBlended));
    CHECK(value_of("kRtMaskCastsShadow") == long(render::kRtMaskCastsShadow));
    CHECK(value_of("kRtMaskFoliage") == long(render::kRtMaskFoliage));
    CHECK(value_of("kRtMaskEmissive") == long(render::kRtMaskEmissive));
    CHECK(value_of("kRtMaskSurfaces") == long(render::kRtMaskSurfaces));
    // The members, in order, with the sizes that make 96 bytes (a float4 is 16, a scalar 4).
    const std::size_t body = hlsl.find("struct RtInstanceRecord");
    REQUIRE(body != std::string::npos);
    const std::string s = hlsl.substr(body, hlsl.find("};", body) - body);
    const std::array<const char*, 9> members = {"float4 objectToWorldRow0",
                                                "float4 objectToWorldRow1",
                                                "float4 objectToWorldRow2",
                                                "float4 albedo",
                                                "float4 emissive",
                                                "float roughness",
                                                "float metalness",
                                                "uint flags",
                                                "uint blasId"};
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

}  // namespace
