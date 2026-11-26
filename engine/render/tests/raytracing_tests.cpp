// M79-P0a: the ray tracing seam (docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md). No backend traces rays yet, so what
// is tested is the interface: the RecordingDevice's answers, recorded stream and every validation error of the acceleration structure calls,
// the refusals of a device without ray tracing, the "raytracing" rows of renderer.supports per backend, and the settings
// (render.rayTracing: defaults, clamps, errors, the JSON round trip).
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <span>
#include <utility>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/render/raytracing.h"
#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/recording_device.h"
#include "render_features.h"

using namespace fa;
using namespace fa::gpu;
using render::FeatureBackend;
using render::FeatureEnv;
using render::RayTracingSettings;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

bool has_error(const std::vector<std::string>& errors, std::initializer_list<const char*> parts) {
    for (const std::string& e : errors) {
        bool all = true;
        for (const char* p : parts) all = all && contains(e, p);
        if (all) return true;
    }
    return false;
}

std::string joined(const std::vector<std::string>& errors) {
    std::string s;
    for (const std::string& e : errors) s += e + "\n";
    return s;
}

DeviceInit ray_tracing_init() {
    DeviceInit init;
    init.recordingRayTracing = true;
    return init;
}

// Two triangles over four vertices, in buffers a build can read, and the scratch and storage buffers of the sizes asked.
struct Mesh {
    RecordingDevice& dev;
    Buffer vertices{}, indices{};
    std::array<AccelTriangles, 1> geometry{};

    explicit Mesh(RecordingDevice& d) : dev(d) {
        BufferDesc vb;
        vb.size = 4 * 12;
        vb.usage.accelBuildInput = true;
        vb.usage.copyDst = true;
        vb.label = "mesh vertices";
        vertices = dev.make_buffer(vb);
        BufferDesc ib;
        ib.size = 6 * 2;
        ib.usage.accelBuildInput = true;
        ib.usage.copyDst = true;
        ib.label = "mesh indices";
        indices = dev.make_buffer(ib);
        geometry[0].vertexBuffer = vertices;
        geometry[0].vertexStride = 12;
        geometry[0].vertexCount = 4;
        geometry[0].indexBuffer = indices;
        geometry[0].indexType = IndexType::Uint16;
        geometry[0].indexCount = 6;
    }
    std::span<const AccelTriangles> geometries() const { return geometry; }
};

Buffer make_scratch(RecordingDevice& dev, std::uint64_t size, const char* label = "scratch") {
    BufferDesc d;
    d.size = std::size_t(size);
    d.usage.accelScratch = true;
    d.label = label;
    return dev.make_buffer(d);
}

AccelStructure make_as(RecordingDevice& dev, AccelKind kind, std::uint64_t size, const char* label) {
    AccelStructureDesc d;
    d.kind = kind;
    d.size = size;
    d.label = label;
    auto r = dev.make_accel_structure(d);
    REQUIRE_MESSAGE(r.ok(), r.error().message);
    return r.value();
}

// A built BLAS of `mesh` (one build recorded and submitted), made with `flags`.
AccelStructure built_blas(RecordingDevice& dev, const Mesh& mesh, const AccelBuildFlags& flags,
                          const char* label = "rock") {
    auto sizes = dev.blas_sizes(mesh.geometries(), flags);
    REQUIRE_MESSAGE(sizes.ok(), sizes.error().message);
    const AccelStructure blas = make_as(dev, AccelKind::Blas, sizes->structure, label);
    const Buffer scratch = make_scratch(dev, sizes->buildScratch, "blas scratch");
    CommandList& cl = dev.begin_commands("build");
    BlasBuild b;
    b.dst = blas;
    b.geometries = mesh.geometries();
    b.flags = flags;
    b.scratch = scratch;
    auto r = cl.build_blas(b);
    REQUIRE_MESSAGE(r.ok(), r.error().message);
    dev.submit(cl);
    return blas;
}

}  // namespace

TEST_CASE("ray tracing: a RecordingDevice has none until it is asked, and every call refuses with the reason and "
          "records nothing") {
    RecordingDevice dev;
    CHECK_FALSE(dev.features().rayQuery);
    CHECK_FALSE(dev.features().accelerationStructure);
    CHECK_FALSE(dev.features().rayTracingPipeline);
    CHECK(dev.limits().maxAccelInstances == 0);
    std::string why;
    CHECK_FALSE(dev.ray_tracing_status(&why));
    CHECK(contains(why, "recordingRayTracing"));

    const auto sizes = dev.tlas_sizes(10, {});
    REQUIRE_FALSE(sizes.ok());
    CHECK(contains(sizes.error().message, "gpu: Device::tlas_sizes: "));
    CHECK(contains(sizes.error().message, "recordingRayTracing"));
    CHECK(contains(sizes.error().hint, "renderer.supports(\"raytracing\")"));
    AccelStructureDesc d;
    d.size = 4096;
    CHECK_FALSE(dev.make_accel_structure(d).ok());
    CHECK_FALSE(dev.blas_sizes({}, {}).ok());

    CommandList& cl = dev.begin_commands("main");
    const auto built = cl.build_tlas({});
    REQUIRE_FALSE(built.ok());
    CHECK(contains(built.error().message, "gpu: CommandList::build_tlas: "));
    CHECK_FALSE(cl.build_blas({}).ok());
    CHECK_FALSE(cl.query_compacted_size({}, {}, 0).ok());
    CHECK_FALSE(cl.copy_accel_structure({}, {}, AccelCopyMode::Clone).ok());
    dev.submit(cl);
    dev.commit();
    CHECK(dev.errors().empty());        // a refusal is an answer, not a misuse
    CHECK(dev.commands().size() == 1);  // only the commit
    CHECK(dev.accel_structure_state({}) == ResourceState::Invalid);

    // The buffer usages of a build need the features.
    BufferDesc b;
    b.size = 256;
    b.usage.accelScratch = true;
    b.label = "scratch";
    const Buffer scratch = dev.make_buffer(b);
    CHECK(dev.state(scratch) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"accelScratch", "without acceleration structures"}));
}

TEST_CASE("ray tracing: the reason names where it can run and the package that brings it, per backend") {
    for (const Backend b : {Backend::Gl, Backend::Gles3, Backend::WebGl2, Backend::D3d11}) {
        CAPTURE(backend_name(b));
        const std::string r = accel_unavailable_reason(b);
        CHECK(contains(r, backend_name(b)));
        CHECK(contains(r, "cannot trace rays"));
        CHECK(contains(r, "d3d12 or vulkan"));
        CHECK(contains(r, "Metal"));
    }
    CHECK(contains(accel_unavailable_reason(Backend::D3d12), "P1d"));
    CHECK(contains(accel_unavailable_reason(Backend::Vulkan), "VK_KHR_ray_query"));
    CHECK(contains(accel_unavailable_reason(Backend::Metal), "P1m"));
    const Error e = accel_refusal(Backend::Vulkan, "CommandList::build_blas");
    CHECK(contains(e.message, "gpu: CommandList::build_blas: a vulkan device traces rays only when"));
    CHECK(contains(e.hint, "Device::features()"));
}

TEST_CASE(
    "ray tracing: a RecordingDevice made with it reports the features and limits, and rayTracingPipeline stays false") {
    RecordingDevice dev(ray_tracing_init());
    CHECK(dev.features().rayQuery);
    CHECK(dev.features().accelerationStructure);
    CHECK(dev.features().bufferDeviceAddress);
    CHECK_FALSE(dev.features().rayTracingPipeline);  // reported only, and the engine never uses it
    CHECK(dev.limits().maxAccelInstances == (1u << 20));
    CHECK(dev.limits().maxAccelGeometries == 4096);
    CHECK(dev.limits().maxAccelPrimitives == (1ull << 28));
    CHECK(dev.accel_alignment() == 256);
    CHECK(dev.accel_scratch_alignment() == 256);
    std::string why;
    CHECK(dev.ray_tracing_status(&why));
    CHECK(why.empty());
}

TEST_CASE("ray tracing: a BLAS, a TLAS and a ray query dispatch record a readable stream and no error") {
    RecordingDevice dev(ray_tracing_init());
    Mesh mesh(dev);
    const AccelBuildFlags flags;
    const AccelStructure blas = built_blas(dev, mesh, flags);
    CHECK(dev.accel_structure_state(blas) == ResourceState::Valid);

    // The sizes are the device's: the same call answers the same numbers.
    const auto blasSizes = dev.blas_sizes(mesh.geometries(), flags);
    REQUIRE(blasSizes.ok());
    CHECK(blasSizes->structure % 256 == 0);
    CHECK(blasSizes->buildScratch % 256 == 0);
    CHECK(blasSizes->updateScratch == 0);  // no allowUpdate: nothing to refit
    const auto again = dev.blas_sizes(mesh.geometries(), flags);
    CHECK(again->structure == blasSizes->structure);
    AccelBuildFlags upd;
    upd.allowUpdate = true;
    const auto updSizes = dev.blas_sizes(mesh.geometries(), upd);
    CHECK(updSizes->updateScratch > 0);
    CHECK(updSizes->structure >= blasSizes->structure);

    // The TLAS over two instances of the BLAS.
    std::array<AccelInstance, 2> instances{};
    instances[0].blas = blas;
    instances[1].blas = blas;
    instances[1].transform[3] = 10.0f;
    instances[1].customIndex = 7;
    const auto tlasSizes = dev.tlas_sizes(2, flags);
    REQUIRE(tlasSizes.ok());
    const AccelStructure tlas = make_as(dev, AccelKind::Tlas, tlasSizes->structure, "world");
    const Buffer tlasScratch = make_scratch(dev, tlasSizes->buildScratch, "tlas scratch");

    // A compute kernel that traces against it.
    BufferDesc outDesc;
    outDesc.size = 1024;
    outDesc.usage.storageBuffer = true;
    outDesc.label = "hits";
    const Buffer hits = dev.make_buffer(outDesc);
    ViewDesc hv;
    hv.storageBuffer.buffer = hits;
    const View hitsView = dev.make_view(hv);
    ShaderDesc sd;
    sd.computeFunc.source = "cs";
    sd.views[0].storageBuffer.stage = ShaderStage::Compute;
    sd.usesRayQuery = true;
    sd.accelStructures[0].stage = ShaderStage::Compute;
    sd.label = "trace";
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = dev.make_shader(sd);
    pd.label = "trace";
    const Pipeline trace = dev.make_pipeline(pd);
    REQUIRE_MESSAGE(dev.errors().empty(), joined(dev.errors()));
    dev.clear_commands();

    CommandList& cl = dev.begin_commands("rt");
    TlasBuild tb;
    tb.dst = tlas;
    tb.instances = instances;
    tb.flags = flags;
    tb.scratch = tlasScratch;
    auto built = cl.build_tlas(tb);
    REQUIRE_MESSAGE(built.ok(), built.error().message);
    cl.begin_compute_pass("trace");
    cl.set_pipeline(trace);
    Bindings bind;
    bind.views[0] = hitsView;
    bind.accelStructures[0] = tlas;
    cl.set_bindings(bind);
    cl.dispatch(8, 8, 1);
    cl.end_pass();
    dev.submit(cl);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    CHECK(dev.stream_text() ==
          "frame 0 [rt] build_tlas TLAS 'world' instances=2 scratch=" + std::to_string(tlasSizes->buildScratch) +
              "B\n"
              "frame 0 [rt] begin_compute_pass 'trace'\n"
              "frame 0 [rt] set_pipeline 'trace'\n"
              "frame 0 [rt] set_bindings vb=0 views=1 samplers=0\n"
              "frame 0 [rt] dispatch 8 8 1\n"
              "frame 0 [rt] end_pass\n"
              "frame 0 commit\n");
    const auto cmds = dev.commands();
    REQUIRE_FALSE(cmds.empty());
    CHECK(cmds[0].kind == CommandKind::BuildTlas);
    CHECK(std::string(command_kind_name(CommandKind::BuildBlas)) == "build_blas");
    CHECK(std::string(command_kind_name(CommandKind::QueryCompactedSize)) == "query_compacted_size");
    CHECK(std::string(command_kind_name(CommandKind::CopyAccelStructure)) == "copy_accel_structure");

    // Destroyed structures are not valid any more.
    dev.destroy_accel_structure(tlas);
    CHECK(dev.accel_structure_state(tlas) != ResourceState::Valid);
}

TEST_CASE("ray tracing: a refit, a compaction and a clone record and keep the structure's rules") {
    RecordingDevice dev(ray_tracing_init());
    Mesh mesh(dev);
    AccelBuildFlags flags;
    flags.allowUpdate = true;
    flags.allowCompaction = true;
    const AccelStructure blas = built_blas(dev, mesh, flags);
    const auto sizes = dev.blas_sizes(mesh.geometries(), flags);
    REQUIRE(sizes.ok());
    const Buffer updateScratch = make_scratch(dev, sizes->updateScratch, "update scratch");
    BufferDesc sd;
    sd.size = 64;
    sd.usage.storageBuffer = true;
    sd.label = "compacted size";
    const Buffer sizeOut = dev.make_buffer(sd);
    const AccelStructure compact = make_as(dev, AccelKind::Blas, sizes->structure / 2, "rock compact");
    const AccelStructure clone = make_as(dev, AccelKind::Blas, sizes->structure, "rock clone");
    dev.clear_commands();

    CommandList& cl = dev.begin_commands("maintain");
    BlasBuild refit;
    refit.dst = blas;
    refit.src = blas;
    refit.update = true;
    refit.geometries = mesh.geometries();
    refit.flags = flags;
    refit.scratch = updateScratch;
    CHECK(cl.build_blas(refit).ok());
    CHECK(cl.query_compacted_size(blas, sizeOut, 8).ok());
    CHECK(cl.copy_accel_structure(blas, compact, AccelCopyMode::Compact).ok());
    CHECK(cl.copy_accel_structure(blas, clone, AccelCopyMode::Clone).ok());
    dev.submit(cl);
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    const std::string text = dev.stream_text();
    CHECK(contains(text, "build_blas BLAS 'rock' geometries=1 triangles=2 update scratch=" +
                             std::to_string(sizes->updateScratch) + "B"));
    CHECK(contains(text, "query_compacted_size BLAS 'rock' -> "));
    CHECK(contains(text, "copy_accel_structure BLAS 'rock' -> BLAS 'rock compact' compact"));
    CHECK(contains(text, "copy_accel_structure BLAS 'rock' -> BLAS 'rock clone' clone"));

    // A compaction into a larger target, and a clone into a smaller one, teach.
    CommandList& bad = dev.begin_commands("bad");
    const AccelStructure large = make_as(dev, AccelKind::Blas, sizes->structure * 2, "too large");
    const auto grow = bad.copy_accel_structure(blas, large, AccelCopyMode::Compact);
    REQUIRE_FALSE(grow.ok());
    CHECK(contains(grow.error().message, "larger than the source's"));
    const auto shrink = bad.copy_accel_structure(blas, compact, AccelCopyMode::Clone);
    REQUIRE_FALSE(shrink.ok());
    CHECK(contains(shrink.error().message, "smaller than the source's"));
    dev.submit(bad);
    dev.take_errors();
}

TEST_CASE("ray tracing: every misuse of a build is a teaching error that records nothing") {
    RecordingDevice dev(ray_tracing_init());
    Mesh mesh(dev);
    const AccelBuildFlags plain;
    const AccelStructure blas = built_blas(dev, mesh, plain);
    const auto sizes = dev.blas_sizes(mesh.geometries(), plain);
    REQUIRE(sizes.ok());
    const AccelStructure freshBlas = make_as(dev, AccelKind::Blas, sizes->structure, "fresh");
    const AccelStructure tlas = make_as(dev, AccelKind::Tlas, dev.tlas_sizes(1, plain)->structure, "world");
    const Buffer tlasScratch = make_scratch(dev, dev.tlas_sizes(1, plain)->buildScratch, "tlas scratch");
    dev.clear_commands();
    REQUIRE(dev.errors().empty());
    CommandList& cl = dev.begin_commands("misuse");

    SUBCASE("a TLAS built over a destroyed BLAS") {
        const AccelStructure gone = make_as(dev, AccelKind::Blas, sizes->structure, "gone");
        dev.destroy_accel_structure(gone);
        std::array<AccelInstance, 1> in{};
        in[0].blas = gone;
        TlasBuild tb;
        tb.dst = tlas;
        tb.instances = in;
        tb.scratch = tlasScratch;
        const auto r = cl.build_tlas(tb);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "instances[0].blas is "));
        CHECK(contains(r.error().message, "destroy a BLAS only after the TLAS that names it"));
        CHECK(has_error(dev.errors(), {"build_tlas", "instances[0].blas"}));
    }
    SUBCASE("a TLAS over a BLAS that was never built") {
        std::array<AccelInstance, 1> in{};
        in[0].blas = freshBlas;
        TlasBuild tb;
        tb.dst = tlas;
        tb.instances = in;
        tb.scratch = tlasScratch;
        const auto r = cl.build_tlas(tb);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "was never built: record build_blas before build_tlas"));
    }
    SUBCASE("a scratch buffer too small names both sizes") {
        const Buffer small = make_scratch(dev, 256, "small scratch");
        BlasBuild b;
        b.dst = freshBlas;
        b.geometries = mesh.geometries();
        b.scratch = small;
        const auto r = cl.build_blas(b);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "scratch buffer 'small scratch' has 256 bytes from scratchOffset 0"));
        CHECK(contains(r.error().message, "needs " + std::to_string(sizes->buildScratch)));
        CHECK(contains(r.error().message, "AccelSizes::buildScratch"));
    }
    SUBCASE("an update of a BLAS built without allowUpdate") {
        AccelBuildFlags upd;
        upd.allowUpdate = true;
        const Buffer scratch = make_scratch(dev, 1 << 16, "scratch");
        BlasBuild b;
        b.dst = blas;
        b.src = blas;
        b.update = true;
        b.geometries = mesh.geometries();
        b.flags = upd;
        b.scratch = scratch;
        const auto r = cl.build_blas(b);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "which was built without flags.allowUpdate"));
        CHECK(contains(r.error().hint, "allowUpdate"));
    }
    SUBCASE("more geometries than the device's limit") {
        std::vector<AccelTriangles> many(5000, mesh.geometry[0]);
        const auto s = dev.blas_sizes(many, plain);
        REQUIRE_FALSE(s.ok());
        CHECK(contains(s.error().message, "5000 geometries are more than this device's limit 4096"));
        CHECK(contains(s.error().message, "Limits::maxAccelGeometries"));
        BlasBuild b;
        b.dst = freshBlas;
        b.geometries = many;
        b.scratch = make_scratch(dev, 1 << 20, "scratch");
        const auto r = cl.build_blas(b);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "5000 geometries are more than this device's limit 4096"));
    }
    SUBCASE("a BLAS bound where a ray query needs a TLAS, and a slot the shader does not declare") {
        ShaderDesc sd;
        sd.computeFunc.source = "cs";
        sd.usesRayQuery = true;
        sd.accelStructures[0].stage = ShaderStage::Compute;
        sd.label = "trace";
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev.make_shader(sd);
        pd.label = "trace";
        const Pipeline trace = dev.make_pipeline(pd);
        REQUIRE(dev.errors().empty());
        cl.begin_compute_pass("trace");
        cl.set_pipeline(trace);
        Bindings bind;
        bind.accelStructures[0] = blas;
        cl.set_bindings(bind);
        CHECK(has_error(dev.take_errors(),
                        {"set_bindings", "accelStructures[0] is the BLAS 'rock'", "traces against a TLAS"}));
        Bindings other;
        other.accelStructures[0] = tlas;  // declared, but build_tlas has not run
        cl.set_bindings(other);
        CHECK(has_error(dev.take_errors(),
                        {"accelStructures[0] is the TLAS 'world'", "which build_tlas has not built yet"}));
        Bindings extra;
        extra.accelStructures[1] = tlas;  // not declared
        cl.set_bindings(extra);
        CHECK(
            has_error(dev.take_errors(), {"accelStructures[1] is bound", "declares no acceleration structure there"}));
        cl.end_pass();
    }
    SUBCASE("a build inside a pass, on a transfer list, and into the wrong kind") {
        const Buffer scratch = make_scratch(dev, 1 << 16, "scratch");
        BlasBuild b;
        b.dst = tlas;  // a TLAS where a BLAS is written
        b.geometries = mesh.geometries();
        b.scratch = scratch;
        auto r = cl.build_blas(b);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "is a TLAS: build_blas writes a BLAS"));
        cl.begin_compute_pass("pass");
        b.dst = freshBlas;
        r = cl.build_blas(b);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "it goes outside a pass"));
        cl.end_pass();
    }
    SUBCASE("a customIndex over 24 bits, a NaN transform and no instances") {
        std::array<AccelInstance, 1> in{};
        in[0].blas = blas;
        in[0].customIndex = 1u << 24;
        in[0].transform[5] = std::numeric_limits<float>::quiet_NaN();
        TlasBuild tb;
        tb.dst = tlas;
        tb.instances = in;
        tb.scratch = tlasScratch;
        auto r = cl.build_tlas(tb);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "instances[0].customIndex 16777216 does not fit in 24 bits"));
        CHECK(contains(r.error().message, "instances[0].transform has a NaN or infinite value"));
        tb.instances = {};
        r = cl.build_tlas(tb);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message, "no instances"));
        CHECK_FALSE(dev.tlas_sizes(0, plain).ok());
        CHECK_FALSE(dev.tlas_sizes((1u << 20) + 1, plain).ok());
    }
    SUBCASE("a buffer without the build usage, and a structure that does not fit its storage") {
        BufferDesc plainVb;
        plainVb.size = 48;
        plainVb.usage.vertexBuffer = true;
        plainVb.usage.copyDst = true;
        plainVb.label = "draw only";
        std::array<AccelTriangles, 1> g = mesh.geometry;
        g[0].vertexBuffer = dev.make_buffer(plainVb);
        BlasBuild b;
        b.dst = freshBlas;
        b.geometries = g;
        b.scratch = make_scratch(dev, 1 << 16, "scratch");
        const auto r = cl.build_blas(b);
        REQUIRE_FALSE(r.ok());
        CHECK(contains(r.error().message,
                       "geometries[0].vertexBuffer 'draw only' was not made with usage.accelBuildInput"));

        BufferDesc st;
        st.size = 1024;
        st.usage.accelStorage = true;
        st.label = "pool";
        AccelStructureDesc d;
        d.size = 4096;
        d.storage = dev.make_buffer(st);
        const auto made = dev.make_accel_structure(d);
        REQUIRE_FALSE(made.ok());
        CHECK(contains(made.error().message, "do not fit in buffer 'pool' (1024 bytes)"));
        d.size = 512;
        d.storageOffset = 100;
        const auto unaligned = dev.make_accel_structure(d);
        REQUIRE_FALSE(unaligned.ok());
        CHECK(contains(unaligned.error().message, "storageOffset 100 is not a multiple of 256"));
    }
    dev.submit(cl);
    dev.take_errors();
}

TEST_CASE("ray tracing: a kernel declares its acceleration structure slots and the shader desc is checked") {
    RecordingDevice dev(ray_tracing_init());
    ShaderDesc render;
    render.vertexFunc.source = "vs";
    render.fragmentFunc.source = "fs";
    render.usesRayQuery = true;
    render.label = "render shader";
    CHECK(dev.state(dev.make_shader(render)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"usesRayQuery on a render shader", "compute shaders"}));

    ShaderDesc undeclared;
    undeclared.computeFunc.source = "cs";
    undeclared.accelStructures[0].stage = ShaderStage::Compute;  // usesRayQuery false
    undeclared.label = "slot without ray query";
    CHECK(dev.state(dev.make_shader(undeclared)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"accelStructures[0] is declared but usesRayQuery is false"}));

    ShaderDesc fragmentSlot;
    fragmentSlot.computeFunc.source = "cs";
    fragmentSlot.usesRayQuery = true;
    fragmentSlot.accelStructures[0].stage = ShaderStage::Fragment;
    fragmentSlot.label = "wrong stage";
    CHECK(dev.state(dev.make_shader(fragmentSlot)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"accelStructures[0] has a stage other than Compute"}));

    // A device without the feature refuses a ray query kernel.
    RecordingDevice plain;
    ShaderDesc kernel;
    kernel.computeFunc.source = "cs";
    kernel.usesRayQuery = true;
    kernel.label = "kernel";
    CHECK(plain.state(plain.make_shader(kernel)) == ResourceState::Failed);
    CHECK(has_error(plain.take_errors(), {"usesRayQuery on a device without ray query"}));
}

// ---- renderer.supports --------------------------------------------------------------------------------------------------------------------

namespace {

FeatureEnv env_of(FeatureBackend table, Backend gpuBackend, bool rayQuery = false, bool pipeline = false,
                  const std::string& why = "") {
    FeatureEnv e;
    e.backend = table;
    e.gpuBackend = gpuBackend;
    e.compute = true;
    Features f;
    f.rayQuery = rayQuery;
    f.accelerationStructure = rayQuery;
    f.rayTracingPipeline = pipeline;
    render::set_ray_tracing_env(e, f, why);
    return e;
}

bool supported(const FeatureEnv& env, const char* name, std::string* why = nullptr) {
    const int i = render::find_feature(name);
    REQUIRE_MESSAGE(i >= 0, name);
    return render::feature_supported(env, i, why);
}

}  // namespace

TEST_CASE("renderer.supports: the ray tracing rows exist, are documented, and are false with a reason on every backend "
          "that cannot trace") {
    CHECK(render::find_feature("raytracing") >= 0);
    CHECK(render::find_feature("raytracingPipeline") >= 0);
    for (const auto& pair :
         {std::pair{FeatureBackend::Gl, Backend::Gl}, std::pair{FeatureBackend::Gles3, Backend::Gles3},
          std::pair{FeatureBackend::WebGl2, Backend::WebGl2}, std::pair{FeatureBackend::D3d11, Backend::D3d11}}) {
        CAPTURE(backend_name(pair.second));
        const FeatureEnv e = env_of(pair.first, pair.second);
        std::string why;
        CHECK_FALSE(supported(e, "raytracing", &why));
        CHECK(contains(why, "cannot trace rays"));
        CHECK(contains(why, backend_name(pair.second)));
        why.clear();
        CHECK_FALSE(supported(e, "raytracingPipeline", &why));
        CHECK(contains(why, "cannot trace rays"));
    }
}

TEST_CASE("renderer.supports: D3D12, Vulkan and Metal say which package brings ray tracing, and answer true once the "
          "device has it") {
    struct Case {
        FeatureBackend table;
        Backend backend;
        const char* package;
    };
    for (const Case& c : {Case{FeatureBackend::Headless, Backend::D3d12, "P1d"},
                          Case{FeatureBackend::Headless, Backend::Vulkan, "VK_KHR_ray_query"},
                          Case{FeatureBackend::Metal, Backend::Metal, "P1m"}}) {
        CAPTURE(backend_name(c.backend));
        std::string why;
        // The device says it cannot: the reason names the package that brings it, or (Vulkan) what the device needs.
        FeatureEnv no = env_of(c.table, c.backend, false, false, accel_unavailable_reason(c.backend));
        CHECK_FALSE(supported(no, "raytracing", &why));
        CHECK(contains(why, c.package));
        // A device that has ray queries and acceleration structures.
        FeatureEnv yes = env_of(c.table, c.backend, true);
        why.clear();
        CHECK(supported(yes, "raytracing", &why));
        CHECK(why.empty());
        CHECK_FALSE(supported(yes, "raytracingPipeline", &why));  // no pipelines: reported only
        CHECK(contains(why, "no ray tracing pipelines"));
        CHECK(supported(env_of(c.table, c.backend, true, true), "raytracingPipeline"));
        // Without the device's reason the backend's own is used.
        FeatureEnv bare = env_of(c.table, c.backend);
        why.clear();
        CHECK_FALSE(supported(bare, "raytracing", &why));
        CHECK(contains(why, c.package));
    }
}

TEST_CASE("renderer.supports: a RecordingDevice answers by what it was made with, and the report lists D3D12 and "
          "Vulkan for both rows") {
    {
        RecordingDevice plain;
        const FeatureEnv e = render::feature_env_from_device(plain);
        std::string why;
        CHECK_FALSE(supported(e, "raytracing", &why));
        CHECK(contains(why, "recordingRayTracing"));
    }
    RecordingDevice dev(ray_tracing_init());
    const FeatureEnv e = render::feature_env_from_device(dev);
    CHECK(supported(e, "raytracing"));
    CHECK_FALSE(supported(e, "raytracingPipeline"));
    const Json report = render::feature_report(e, "headless");
    int seen = 0;
    for (const Json& row : report["features"]) {
        const std::string name = row["name"].get<std::string>();
        if (name != "raytracing" && name != "raytracingPipeline") continue;
        ++seen;
        CHECK(row["backends"]["D3D12"] == true);
        CHECK(row["backends"]["Vulkan"] == true);
        CHECK(row["backends"]["Metal"] == true);
        CHECK(row["backends"]["GL"] == false);
        CHECK(row["backends"]["D3D11"] == false);
        CHECK(row["doc"].get<std::string>().size() > 40);
        if (name == "raytracing") CHECK(row["supported"] == true);
    }
    CHECK(seen == 2);
}

// ---- the settings -------------------------------------------------------------------------------------------------------------------------

TEST_CASE("render.rayTracing: the defaults are off and free, and nothing asks for rays") {
    const RayTracingSettings s;
    CHECK_FALSE(s.enabled);
    CHECK(s.shadows == render::RtShadows::Off);
    CHECK_FALSE(s.ao);
    CHECK_FALSE(s.reflections);
    CHECK_FALSE(s.translucency);
    CHECK(s.gi == render::RtGi::Off);
    CHECK(s.raysPerPixel == 1);
    CHECK(s.maxInstances == 65536);
    CHECK_FALSE(render::rt_any_effect(s));
    // The master switch alone asks for nothing; an effect without it neither.
    RayTracingSettings on;
    on.enabled = true;
    CHECK_FALSE(render::rt_any_effect(on));
    RayTracingSettings effectOnly;
    effectOnly.ao = true;
    CHECK_FALSE(render::rt_any_effect(effectOnly));
    on.gi = render::RtGi::Probes;
    CHECK(render::rt_any_effect(on));
    const Json j = render::ray_tracing_to_json(s);
    CHECK(j.size() == 8);
    CHECK(j["enabled"] == false);
    CHECK(j["shadows"] == "off");
    CHECK(j["gi"] == "off");
    CHECK(j["raysPerPixel"] == 1);
    CHECK(j["maxInstances"] == 65536);
}

TEST_CASE("render.rayTracing: a settings object parses over the base, keeps keys it does not name and round-trips") {
    RayTracingSettings base;
    base.maxInstances = 1000;
    auto r = render::parse_ray_tracing_settings(
        Json::parse(
            R"({"enabled":true,"shadows":"soft","ao":true,"reflections":true,"translucency":true,"gi":"perPixel","raysPerPixel":4})"),
        "factoria.json#/render/rayTracing", base);
    REQUIRE_MESSAGE(r.ok(), r.error().message);
    CHECK(r->enabled);
    CHECK(r->shadows == render::RtShadows::Soft);
    CHECK(r->ao);
    CHECK(r->reflections);
    CHECK(r->translucency);
    CHECK(r->gi == render::RtGi::PerPixel);
    CHECK(r->raysPerPixel == 4);
    CHECK(r->maxInstances == 1000);  // not named: the base's
    auto back = render::parse_ray_tracing_settings(render::ray_tracing_to_json(r.value()), "x", RayTracingSettings{});
    REQUIRE(back.ok());
    CHECK(back.value() == r.value());
    auto empty = render::parse_ray_tracing_settings(Json::object(), "x", base);
    REQUIRE(empty.ok());
    CHECK(empty.value() == base);
}

TEST_CASE("render.rayTracing: whole numbers are clamped before they are narrowed, never wrapped") {
    const auto parse = [](const char* text) {
        auto r = render::parse_ray_tracing_settings(Json::parse(text), "x", RayTracingSettings{});
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        return r.value();
    };
    CHECK(parse(R"({"raysPerPixel":0})").raysPerPixel == 1);
    CHECK(parse(R"({"raysPerPixel":-5})").raysPerPixel == 1);
    CHECK(parse(R"({"raysPerPixel":99})").raysPerPixel == 16);
    CHECK(parse(R"({"raysPerPixel":16})").raysPerPixel == 16);
    CHECK(parse(R"({"raysPerPixel":4294967297})").raysPerPixel == 16);  // 2^32 + 1 would wrap to 1 in an int
    CHECK(parse(R"({"raysPerPixel":-4294967297})").raysPerPixel == 1);
    CHECK(parse(R"({"maxInstances":0})").maxInstances == 1);
    CHECK(parse(R"({"maxInstances":5000000})").maxInstances == 1048576);
    CHECK(parse(R"({"maxInstances":9223372036854775807})").maxInstances == 1048576);
    CHECK(parse(R"({"maxInstances":1048576})").maxInstances == 1048576);
}

TEST_CASE("render.rayTracing: every mistake names the JSON pointer, what is wrong and the fix") {
    const auto fail = [](const char* text) {
        auto r = render::parse_ray_tracing_settings(Json::parse(text), "factoria.json#/render/rayTracing",
                                                    RayTracingSettings{});
        REQUIRE_FALSE(r.ok());
        return r.error();
    };
    Error e = fail(R"({"shadow":"soft"})");
    CHECK(contains(e.message, "factoria.json#/render/rayTracing/shadow"));
    CHECK(contains(e.hint, "shadows"));  // did you mean
    e = fail(R"({"shadows":"sofft"})");
    CHECK(contains(e.message, "factoria.json#/render/rayTracing/shadows"));
    CHECK(contains(e.hint, "soft"));
    e = fail(R"({"gi":"perpixel"})");
    CHECK(contains(e.message, "/render/rayTracing/gi"));
    CHECK(contains(e.hint, "perPixel"));
    e = fail(R"({"gi":3})");
    CHECK(contains(e.message, "/render/rayTracing/gi: expected a name"));
    CHECK(contains(e.hint, "\"probes\""));
    e = fail(R"({"enabled":"yes"})");
    CHECK(contains(e.message, "/render/rayTracing/enabled: expected true or false"));
    CHECK(contains(e.hint, "master switch"));
    e = fail(R"({"ao":1})");
    CHECK(contains(e.message, "/render/rayTracing/ao"));
    e = fail(R"({"raysPerPixel":1.5})");
    CHECK(contains(e.message, "/render/rayTracing/raysPerPixel: expected a whole number"));
    CHECK(contains(e.hint, "1 to 16"));
    e = fail(R"({"maxInstances":"many"})");
    CHECK(contains(e.message, "/render/rayTracing/maxInstances"));
    e = fail(R"([true])");
    CHECK(contains(e.message, "factoria.json#/render/rayTracing: expected an object"));
    CHECK(contains(e.hint, "maxInstances"));
}
