#include "fa/render/lightmap_gpu_bake.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <span>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/platform/app.h"
#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/sokol_context.h"
#include "lightmap_gpu_bake.h"
#include "rt_kernels.h"

namespace fa::render {

namespace {

using namespace fa::gpu;

// The work of one dispatch, in "ray units" (one unit = a ray query and its shading): a dispatch is far below the 2 seconds after which Windows
// resets a GPU, whatever the scene. The cuts depend on the counts of the request only, never on the speed of the machine.
constexpr std::uint64_t kDispatchWork = std::uint64_t(1) << 23;
constexpr std::uint32_t kMaxBatchTexels = 16384;  // a multiple of 1024: whole rows of the output image
constexpr std::uint32_t kMinBatchTexels = 1024;
constexpr std::uint32_t kImageWidth = 2048;  // 1024 texels per row, two pixels each (direct, gather)
constexpr std::uint64_t kMaxBufferBytes = std::uint64_t(256)
                                          << 20;  // a storage buffer bigger than this is refused (limits of the APIs)

constexpr std::uint32_t kLightFloat4 = 8;   // float4 per light in the scene buffer (rt_bake.hlsl)
constexpr std::uint32_t kCasterFloat4 = 3;  // float4 per caster

// The constants block of the kernel (BakeParams of rt_bake.hlsl, 112 bytes).
struct BakeParams {
    std::uint32_t a[4];  // texels in the dispatch, sampleBegin, sampleEnd, samples
    std::uint32_t b[4];  // atlas key (low, high), bounces, shadow samples
    std::uint32_t c[4];  // lights, the first caster (float4), sky width, sky height
    float d[4];          // eps, sky rotation in turns, sky intensity, 0
    float zenith[4];
    float horizon[4];
    float ground[4];
};
static_assert(sizeof(BakeParams) == 112, "BakeParams is the constants block of rt_bake.hlsl");

std::uint32_t bits_of(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

// One process runs one GPU bake at a time: the sokol context is a singleton, and two bakes would only slow each other down.
std::mutex& bake_mutex() {
    static std::mutex m;
    return m;
}

void put4(std::vector<float>& v, float x, float y, float z, float w) {
    v.push_back(x);
    v.push_back(y);
    v.push_back(z);
    v.push_back(w);
}

}  // namespace

gpu::ShaderDesc lightmap_bake_shader_desc(gpu::Backend backend) {
    ShaderDesc d;
    const rt_kernels::RtKernel* kernel = rt_kernels::find_rt_kernel("rt_bake");
    if (!kernel) return d;
    d.label = kernel->name.data();  // the table's names are string literals
    switch (backend) {
        case Backend::D3d12:
            if (kernel->dxil.empty()) return d;
            d.computeFunc.bytecode = Range{kernel->dxil.data(), kernel->dxil.size()};
            break;
        case Backend::Vulkan:
            if (kernel->spirv.empty()) return d;
            d.computeFunc.bytecode = Range{kernel->spirv.data(), kernel->spirv.size()};
            break;
        case Backend::Metal:
        case Backend::Recording:
            if (kernel->msl.empty()) return d;
            d.computeFunc.source = kernel->msl.data();
            d.computeFunc.entry = kernel->name.data();
            d.mtlThreadsPerThreadgroup[0] = 64;
            d.mtlThreadsPerThreadgroup[1] = 1;
            d.mtlThreadsPerThreadgroup[2] = 1;
            break;
        default: return d;  // no ray queries on the other backends
    }
    d.usesRayQuery = true;
    // The TLAS: t0 / binding 0 / buffer(0).
    d.accelStructures[0].stage = ShaderStage::Compute;
    d.accelStructures[0].binding.hlslRegister = 0;
    d.accelStructures[0].binding.mslIndex = 0;
    d.accelStructures[0].binding.spirvSet = 0;
    d.accelStructures[0].binding.spirvBinding = 0;
    // The constants: b0 / binding 2 / buffer(1).
    ShaderUniformBlock& u = d.uniformBlocks[LightmapBakeBindings::kUniformParams];
    u.stage = ShaderStage::Compute;
    u.size = std::uint32_t(sizeof(BakeParams));
    u.binding.hlslRegister = 0;
    u.binding.mslIndex = 1;
    u.binding.spirvSet = 0;
    u.binding.spirvBinding = 2;
    // The output: u0 / binding 1 / texture(0).
    ShaderStorageImageView& out = d.views[LightmapBakeBindings::kViewOut].storageImage;
    out.stage = ShaderStage::Compute;
    out.imageType = ImageType::Tex2d;
    out.accessFormat = PixelFormat::Rgba32F;
    out.writeonly = true;
    out.binding.hlslRegister = 0;
    out.binding.mslIndex = 0;
    out.binding.spirvSet = 0;
    out.binding.spirvBinding = 1;
    // The read-only storage buffers: t2 / binding 4 / buffer(8), t3 / 5 / buffer(9), t4 / 6 / buffer(10) (Sokol's Metal numbers the storage
    // buffers from 8).
    auto storage = [&](int slot, int reg, int msl, int vk) {
        ShaderStorageBufferView& s = d.views[slot].storageBuffer;
        s.stage = ShaderStage::Compute;
        s.readonly = true;
        s.binding.hlslRegister = std::uint8_t(reg);
        s.binding.mslIndex = std::uint8_t(msl);
        s.binding.spirvSet = 0;
        s.binding.spirvBinding = std::uint8_t(vk);
    };
    storage(LightmapBakeBindings::kViewScene, 2, 8, 4);
    storage(LightmapBakeBindings::kViewTexels, 3, 9, 5);
    storage(LightmapBakeBindings::kViewSky, 4, 10, 6);
    return d;
}

struct LightmapGpuTracer::Impl {
    // Where the device comes from: a device the caller made (tests), or one the tracer opened (open()).
    std::unique_ptr<Device> owned;
    Device* dev = nullptr;
    std::unique_ptr<HeadlessGpu> headless;  // a private sokol context (Metal)
    bool contextOpened = false;
    std::unique_lock<std::mutex> processLock;
    std::string name;

    Shader shader{};
    Pipeline pipeline{};
    // The scene of the bake.
    Buffer vertices{};
    AccelStructure blas{}, tlas{};
    Buffer sceneBuffer{}, skyBuffer{};
    View sceneView{}, skyView{};
    BakeParams base{};  // the constants every dispatch shares
    std::uint32_t lightCount = 0;
    int samples = 0;
    bool began = false;
    std::uint64_t dispatchCount = 0;

    ~Impl() {
        release_scene();
        if (dev) {
            if (pipeline.id) dev->destroy_pipeline(pipeline);
            if (shader.id) dev->destroy_shader(shader);
        }
        owned.reset();  // the device before the context it runs on
        if (contextOpened) gpu::close_context();
        if (headless) headless->shutdown();
        headless.reset();
    }

    void release_scene() {
        if (!dev) return;
        if (sceneView.id) dev->destroy_view(sceneView);
        if (skyView.id) dev->destroy_view(skyView);
        if (sceneBuffer.id) dev->destroy_buffer(sceneBuffer);
        if (skyBuffer.id) dev->destroy_buffer(skyBuffer);
        if (tlas.id) dev->destroy_accel_structure(tlas);
        if (blas.id) dev->destroy_accel_structure(blas);
        if (vertices.id) dev->destroy_buffer(vertices);
        sceneView = skyView = {};
        sceneBuffer = skyBuffer = {};
        tlas = blas = {};
        vertices = {};
        began = false;
    }

    // The pipeline of the kernel, once.
    Result<void> make_pipeline() {
        const ShaderDesc desc = lightmap_bake_shader_desc(dev->backend());
        if (!desc.compute())
            return make_error(std::string("the lightmap bake kernel has no code for the ") +
                                  backend_name(dev->backend()) + " backend",
                              "bake on the CPU (device \"cpu\")");
        shader = dev->make_shader(desc);
        if (!shader.id || dev->state(shader) != ResourceState::Valid)
            return make_error(std::string("the ") + backend_name(dev->backend()) +
                                  " device refused the lightmap bake kernel",
                              "bake on the CPU (device \"cpu\"); the engine log has the compiler's message");
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = shader;
        pd.label = "rt_bake";
        pipeline = dev->make_pipeline(pd);
        if (!pipeline.id || dev->state(pipeline) != ResourceState::Valid)
            return make_error(std::string("the ") + backend_name(dev->backend()) +
                                  " device could not make the lightmap bake pipeline",
                              "bake on the CPU (device \"cpu\")");
        return {};
    }

    Buffer make_storage(const void* data, std::size_t bytes, const char* label) {
        BufferDesc bd;
        bd.size = bytes;
        bd.usage.storageBuffer = true;
        bd.data = Range{data, bytes};
        bd.label = label;
        const Buffer b = dev->make_buffer(bd);
        if (b.id && dev->state(b) != ResourceState::Valid) {
            dev->destroy_buffer(b);
            return {};
        }
        return b;
    }

    View make_storage_view(Buffer b, const char* label) {
        ViewDesc vd{};
        vd.storageBuffer.buffer = b;
        vd.label = label;
        const View v = dev->make_view(vd);
        if (v.id && dev->state(v) != ResourceState::Valid) {
            dev->destroy_view(v);
            return {};
        }
        return v;
    }
};

LightmapGpuTracer::LightmapGpuTracer(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
LightmapGpuTracer::~LightmapGpuTracer() = default;

const std::string& LightmapGpuTracer::device_name() const { return impl_->name; }
std::uint64_t LightmapGpuTracer::dispatches() const { return impl_->dispatchCount; }

namespace {

std::string device_label(Device& dev) {
    std::string s = backend_name(dev.backend());
    const GpuVendor vendor = dev.info().gpu.vendor;
    const std::string v = gpu_vendor_name(vendor);
    if (!v.empty() && v != "unknown" && v != "Unknown") s += " (" + v + ")";
    return s;
}

}  // namespace

Result<std::unique_ptr<LightmapGpuTracer>> make_lightmap_gpu_tracer_on(gpu::Device& device) {
    std::string why;
    if (!device.ray_tracing_status(&why))
        return make_error(std::string("the ") + backend_name(device.backend()) + " device cannot trace rays: " + why,
                          "bake on the CPU (device \"cpu\"), or use a GPU with ray tracing (docs/RAY_TRACING.md)");
    auto impl = std::make_unique<LightmapGpuTracer::Impl>();
    impl->dev = &device;
    impl->name = device_label(device);
    auto made = impl->make_pipeline();
    if (!made.ok()) return made.error();
    return std::make_unique<LightmapGpuTracer>(std::move(impl));
}

Result<std::unique_ptr<LightmapGpuTracer>> LightmapGpuTracer::open(bool allowSoftware) {
    std::unique_lock<std::mutex> lock(bake_mutex(), std::try_to_lock);
    if (!lock.owns_lock())
        return make_error("another GPU lightmap bake is running in this process",
                          "wait for it, or bake this one on the CPU (device \"cpu\")");
    std::vector<Backend> candidates;
#if defined(_WIN32)
    candidates = {Backend::D3d12, Backend::Vulkan};
#elif defined(__APPLE__)
    if (built_sokol_backend() == Backend::Metal) candidates = {Backend::Metal};
#else
    candidates = {Backend::Vulkan};
#endif
    std::string reasons;
    auto note = [&](Backend b, const std::string& why) {
        if (!reasons.empty()) reasons += "; ";
        reasons += std::string(backend_name(b)) + ": " + why;
    };
    for (const Backend backend : candidates) {
        if (!device_backend_compiled(backend)) {
            note(backend, "this build has no such backend");
            continue;
        }
        auto impl = std::make_unique<Impl>();
        if (backend == Backend::Metal) {
            if (gpu::context_open()) {
                note(backend, "this process already has a graphics context (the editor, a game or an engine with "
                              "graphics), which a bake thread cannot share; "
                              "start without graphics (factoria call --no-graphics) to bake on the GPU");
                continue;
            }
            impl->headless = std::make_unique<HeadlessGpu>();
            std::string err;
            if (!impl->headless->init(&err)) {
                note(backend, "no headless graphics context (" + err + ")");
                continue;
            }
            if (!gpu::open_context(impl->headless->environment())) {
                note(backend, "the graphics context did not open");
                continue;
            }
            impl->contextOpened = true;
        }
        auto device = make_device(backend);
        if (!device) {
            note(backend, device.error().message);
            continue;
        }
        impl->owned = std::move(device.value());
        impl->dev = impl->owned.get();
        std::string why;
        if (!impl->dev->ray_tracing_status(&why)) {
            note(backend, "this GPU cannot trace rays: " + why);
            continue;  // the Impl closes everything it opened
        }
        impl->name = device_label(*impl->dev);
        if (impl->dev->info().gpu.software && !allowSoftware) {
            note(backend, "only a software rasteriser here (" + impl->name +
                              "), which \"auto\" leaves out because it is slower than the CPU baker; ask for device "
                              "\"gpu\" to use it");
            continue;
        }
        auto made = impl->make_pipeline();
        if (!made.ok()) {
            note(backend, made.error().message);
            continue;
        }
        impl->processLock = std::move(lock);
        return std::make_unique<LightmapGpuTracer>(std::move(impl));
    }
    if (reasons.empty()) reasons = "no graphics backend of this build can trace rays";
    return make_error("no GPU here can trace rays for the lightmap bake (" + reasons + ")",
                      "bake on the CPU (device \"cpu\"); the GPU bake needs ray tracing: Metal on Apple silicon, D3D12 "
                      "or Vulkan with ray "
                      "queries elsewhere (docs/RAY_TRACING.md)");
}

Result<void> LightmapGpuTracer::begin(const BakeTraceScene& scene) {
    Impl& s = *impl_;
    Device& dev = *s.dev;
    s.release_scene();
    const std::size_t casters = scene.casterNormal.size();
    if (scene.casterCorners.size() != casters * 3 || scene.casterAlbedo.size() != casters ||
        scene.casterEmissive.size() != casters)
        return make_error(
            "the GPU lightmap bake was given a scene whose caster arrays differ in length (an engine bug)");
    // The sizes, in 64 bits with saturation before anything is allocated.
    const std::uint64_t sceneBytes = (std::uint64_t(scene.lights.size()) * kLightFloat4 +
                                      std::uint64_t(std::max<std::size_t>(casters, 1)) * kCasterFloat4) *
                                     16;
    std::uint64_t skyPixels = 1;
    const BakeSky* sky = scene.sky;
    const bool hasImage =
        sky && sky->image.width > 0 && sky->image.height > 0 &&
        sky->image.rgb.size() >= std::uint64_t(sky->image.width) * std::uint64_t(sky->image.height) * 3;
    if (hasImage) skyPixels = std::uint64_t(sky->image.width) * std::uint64_t(sky->image.height);
    if (sceneBytes > kMaxBufferBytes || skyPixels * 16 > kMaxBufferBytes)
        return make_error("the scene (" + std::to_string(casters) +
                              " shadow-casting triangles) or the sky image is too big for the GPU bake",
                          "bake on the CPU (device \"cpu\"), or bake a smaller part of the scene");
    const Limits& lim = dev.limits();
    const std::uint64_t triangles = std::max<std::size_t>(casters, 1);
    if (lim.maxAccelPrimitives != 0 && triangles > lim.maxAccelPrimitives)
        return make_error("the scene has " + std::to_string(casters) + " shadow-casting triangles, more than the " +
                              std::to_string(lim.maxAccelPrimitives) + " this GPU's acceleration structure holds",
                          "bake on the CPU (device \"cpu\")");

    // The triangles: every caster in order, so a hit's primitive index is the caster's index (a scene without a caster gets one degenerate
    // triangle, which no ray hits).
    std::vector<Vec3> corners = scene.casterCorners;
    if (corners.empty()) corners.assign(3, Vec3{0, 0, 0});
    BufferDesc vb;
    vb.size = corners.size() * sizeof(Vec3);
    vb.usage.accelBuildInput = true;
    vb.data = Range{corners.data(), vb.size};
    vb.label = "lightmap bake triangles";
    s.vertices = dev.make_buffer(vb);
    if (!s.vertices.id || dev.state(s.vertices) != ResourceState::Valid) {
        s.release_scene();
        return make_error("the GPU refused the triangle buffer of the lightmap bake",
                          "bake on the CPU (device \"cpu\")");
    }
    AccelTriangles geometry{};
    geometry.vertexBuffer = s.vertices;
    geometry.vertexStride = sizeof(Vec3);
    geometry.vertexCount = std::uint32_t(corners.size());
    geometry.opaque = true;
    AccelBuildFlags flags;
    auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&geometry, 1), flags);
    if (!bs.ok()) {
        s.release_scene();
        return bs.error();
    }
    AccelStructureDesc ad;
    ad.kind = AccelKind::Blas;
    ad.size = bs->structure;
    ad.label = "lightmap bake blas";
    auto blas = dev.make_accel_structure(ad);
    if (!blas.ok()) {
        s.release_scene();
        return blas.error();
    }
    s.blas = blas.value();
    auto ts = dev.tlas_sizes(1, flags);
    if (!ts.ok()) {
        s.release_scene();
        return ts.error();
    }
    ad.kind = AccelKind::Tlas;
    ad.size = ts->structure;
    ad.label = "lightmap bake tlas";
    auto tlas = dev.make_accel_structure(ad);
    if (!tlas.ok()) {
        s.release_scene();
        return tlas.error();
    }
    s.tlas = tlas.value();
    auto scratch_of = [&](std::uint64_t bytes, const char* label) {
        BufferDesc sd;
        sd.size = std::size_t(std::max<std::uint64_t>(bytes, 256));
        sd.usage.accelScratch = true;
        sd.label = label;
        return dev.make_buffer(sd);
    };
    const Buffer blasScratch = scratch_of(std::max(bs->buildScratch, bs->updateScratch), "lightmap bake blas scratch");
    const Buffer tlasScratch = scratch_of(std::max(ts->buildScratch, ts->updateScratch), "lightmap bake tlas scratch");
    auto drop_scratch = [&] {
        if (blasScratch.id) dev.destroy_buffer(blasScratch);
        if (tlasScratch.id) dev.destroy_buffer(tlasScratch);
    };
    if (!blasScratch.id || !tlasScratch.id) {
        drop_scratch();
        s.release_scene();
        return make_error("the GPU refused the scratch memory of the lightmap bake's acceleration structure",
                          "bake on the CPU (device \"cpu\")");
    }
    {
        CommandList& cl = dev.begin_commands("lightmap bake accel");
        BlasBuild bb;
        bb.dst = s.blas;
        bb.geometries = std::span<const AccelTriangles>(&geometry, 1);
        bb.flags = flags;
        bb.scratch = blasScratch;
        auto r = cl.build_blas(bb);
        if (r.ok()) {
            AccelInstance instance;
            instance.blas = s.blas;
            instance.mask = 0xFF;
            instance.opaque = true;
            TlasBuild tb;
            tb.dst = s.tlas;
            tb.instances = std::span<const AccelInstance>(&instance, 1);
            tb.flags = flags;
            tb.scratch = tlasScratch;
            r = cl.build_tlas(tb);
        }
        if (!r.ok()) {
            dev.submit(cl);
            dev.commit();
            (void)dev.wait_idle();
            drop_scratch();
            s.release_scene();
            return r.error();
        }
        dev.submit(cl);
        dev.commit();
        auto idle = dev.wait_idle();
        drop_scratch();
        if (!idle.ok()) {
            s.release_scene();
            return idle.error();
        }
    }

    // The lights, then the casters (rt_bake.hlsl lays them out).
    std::vector<float> data;
    data.reserve(std::size_t(sceneBytes / sizeof(float)));
    for (const BakeTraceLight& l : scene.lights) {
        put4(data, float(int(l.kind)), l.direct ? 1.0f : 0.0f, l.bounce ? 1.0f : 0.0f, float(int(l.falloff)));
        put4(data, l.color.x, l.color.y, l.color.z, l.range);
        put4(data, l.position.x, l.position.y, l.position.z, l.cosOuter);
        put4(data, l.direction.x, l.direction.y, l.direction.z, l.cosInner);
        put4(data, l.right.x, l.right.y, l.right.z, l.softRadius);
        put4(data, l.up.x, l.up.y, l.up.z, l.tanSoft);
        put4(data, l.width, l.height, 0, 0);
        put4(data, 0, 0, 0, 0);
    }
    const std::uint32_t casterBase = std::uint32_t(scene.lights.size() * kLightFloat4);
    for (std::size_t i = 0; i < casters; ++i) {
        put4(data, scene.casterNormal[i].x, scene.casterNormal[i].y, scene.casterNormal[i].z, 0);
        put4(data, scene.casterAlbedo[i].x, scene.casterAlbedo[i].y, scene.casterAlbedo[i].z, 0);
        put4(data, scene.casterEmissive[i].x, scene.casterEmissive[i].y, scene.casterEmissive[i].z, 0);
    }
    if (casters == 0)
        for (std::uint32_t i = 0; i < kCasterFloat4; ++i) put4(data, 0, 0, 0, 0);
    s.sceneBuffer = s.make_storage(data.data(), data.size() * sizeof(float), "lightmap bake scene");
    s.sceneView = s.sceneBuffer.id ? s.make_storage_view(s.sceneBuffer, "lightmap bake scene view") : View{};
    std::vector<float> skyData;
    if (hasImage) {
        skyData.reserve(std::size_t(skyPixels) * 4);
        for (std::uint64_t i = 0; i < skyPixels; ++i)
            put4(skyData, sky->image.rgb[i * 3], sky->image.rgb[i * 3 + 1], sky->image.rgb[i * 3 + 2], 0);
    } else {
        put4(skyData, 0, 0, 0, 0);  // a binding needs a buffer, the kernel reads none of it
    }
    s.skyBuffer = s.make_storage(skyData.data(), skyData.size() * sizeof(float), "lightmap bake sky");
    s.skyView = s.skyBuffer.id ? s.make_storage_view(s.skyBuffer, "lightmap bake sky view") : View{};
    if (!s.sceneView.id || !s.skyView.id) {
        s.release_scene();
        return make_error("the GPU refused the scene buffers of the lightmap bake", "bake on the CPU (device \"cpu\")");
    }

    BakeParams& p = s.base;
    p = BakeParams{};
    p.a[3] = std::uint32_t(std::clamp(scene.samples, 1, 65536));
    p.b[2] = std::uint32_t(std::clamp(scene.bounces, 0, 16));
    p.b[3] = std::uint32_t(std::clamp(scene.shadowSamples, 1, 1024));
    p.c[0] = std::uint32_t(scene.lights.size());
    p.c[1] = casterBase;
    p.c[2] = hasImage ? std::uint32_t(sky->image.width) : 0u;
    p.c[3] = hasImage ? std::uint32_t(sky->image.height) : 0u;
    p.d[0] = scene.eps;
    if (sky) {
        p.d[1] = sky->image.rotationDeg / 360.0f;
        p.d[2] = sky->intensity;
        const float k = sky->intensity;
        auto grad = [&](float* dst, Vec3 c) {
            dst[0] = c.x * k;
            dst[1] = c.y * k;
            dst[2] = c.z * k;
            dst[3] = 0;
        };
        grad(p.zenith, sky->zenith);
        grad(p.horizon, sky->horizon);
        grad(p.ground, sky->ground);
    }
    s.lightCount = p.c[0];
    s.samples = int(p.a[3]);
    s.began = true;
    return {};
}

Result<void> LightmapGpuTracer::trace_atlas(std::uint64_t atlasKey, const std::vector<BakeTraceTexel>& texels,
                                            const BakeTraceProgressFn& progress, std::vector<float>& rgb) {
    Impl& s = *impl_;
    if (!s.began) return make_error("the GPU lightmap tracer was asked to trace before begin() (an engine bug)");
    Device& dev = *s.dev;
    const std::uint64_t total = texels.size();
    rgb.assign(std::size_t(total) * 3, 0.0f);
    if (total == 0) return {};

    // The cuts: texels per dispatch from the work one texel needs, samples per dispatch from what is left of the budget. Counts only.
    const std::uint64_t lights = s.lightCount;
    const std::uint64_t directRays = lights * s.base.b[3];
    const std::uint64_t perSample = std::uint64_t(s.base.b[2] + 1) * (lights + 1);
    const std::uint64_t perTexel = std::max<std::uint64_t>(directRays + perSample, 1);
    std::uint64_t batch = std::clamp<std::uint64_t>(kDispatchWork / perTexel, kMinBatchTexels, kMaxBatchTexels);
    batch -= batch % 1024;  // whole rows of the output image
    batch = std::min<std::uint64_t>(batch, ((total + 1023) / 1024) * 1024);
    const std::uint64_t sampleChunk = std::clamp<std::uint64_t>(
        kDispatchWork / std::max<std::uint64_t>(batch * perSample, 1), 1, std::uint64_t(s.samples));
    const std::uint32_t rowsMax = std::uint32_t(batch / 1024);

    ImageDesc od;
    od.width = int(kImageWidth);
    od.height = int(rowsMax);
    od.pixelFormat = PixelFormat::Rgba32F;
    od.usage.storageImage = true;
    od.label = "lightmap bake out";
    const Image out = dev.make_image(od);
    ViewDesc ov{};
    ov.storageImage.image = out;
    ov.label = "lightmap bake out view";
    const View outView = out.id ? dev.make_view(ov) : View{};
    auto free_out = [&] {
        if (outView.id) dev.destroy_view(outView);
        if (out.id) dev.destroy_image(out);
    };
    if (!out.id || !outView.id || dev.state(out) != ResourceState::Valid ||
        dev.state(outView) != ResourceState::Valid) {
        free_out();
        return make_error("the GPU refused the output image of the lightmap bake", "bake on the CPU (device \"cpu\")");
    }

    std::vector<std::uint32_t> packed;
    std::vector<std::uint8_t> bytes;
    std::vector<float> accum;  // the gather sums of the batch, 3 per texel
    for (std::uint64_t first = 0; first < total; first += batch) {
        const std::uint32_t m = std::uint32_t(std::min<std::uint64_t>(batch, total - first));
        packed.assign(std::size_t(m) * 12, 0u);
        for (std::uint32_t k = 0; k < m; ++k) {
            const BakeTraceTexel& t = texels[std::size_t(first + k)];
            std::uint32_t* q = &packed[std::size_t(k) * 12];
            q[0] = bits_of(t.position.x);
            q[1] = bits_of(t.position.y);
            q[2] = bits_of(t.position.z);
            q[3] = t.index;
            q[4] = bits_of(t.shadingNormal.x);
            q[5] = bits_of(t.shadingNormal.y);
            q[6] = bits_of(t.shadingNormal.z);
            q[8] = bits_of(t.faceNormal.x);
            q[9] = bits_of(t.faceNormal.y);
            q[10] = bits_of(t.faceNormal.z);
        }
        const Buffer texelBuffer =
            s.make_storage(packed.data(), packed.size() * sizeof(std::uint32_t), "lightmap bake texels");
        const View texelView = texelBuffer.id ? s.make_storage_view(texelBuffer, "lightmap bake texels view") : View{};
        auto free_texels = [&] {
            if (texelView.id) dev.destroy_view(texelView);
            if (texelBuffer.id) dev.destroy_buffer(texelBuffer);
        };
        if (!texelView.id) {
            free_texels();
            free_out();
            return make_error("the GPU refused the texel buffer of the lightmap bake",
                              "bake on the CPU (device \"cpu\")");
        }
        const std::uint32_t rows = (m + 1023) / 1024;
        accum.assign(std::size_t(m) * 3, 0.0f);
        std::vector<float> direct(std::size_t(m) * 3, 0.0f);
        for (std::uint64_t sb = 0; sb < std::uint64_t(s.samples); sb += sampleChunk) {
            const std::uint64_t se = std::min<std::uint64_t>(sb + sampleChunk, std::uint64_t(s.samples));
            BakeParams p = s.base;
            p.a[0] = m;
            p.a[1] = std::uint32_t(sb);
            p.a[2] = std::uint32_t(se);
            p.b[0] = std::uint32_t(atlasKey & 0xFFFFFFFFull);
            p.b[1] = std::uint32_t(atlasKey >> 32);
            CommandList& cl = dev.begin_commands("lightmap bake");
            cl.begin_compute_pass("lightmap bake");
            cl.set_pipeline(s.pipeline);
            Bindings b;
            b.views[LightmapBakeBindings::kViewOut] = outView;
            b.views[LightmapBakeBindings::kViewScene] = s.sceneView;
            b.views[LightmapBakeBindings::kViewTexels] = texelView;
            b.views[LightmapBakeBindings::kViewSky] = s.skyView;
            b.accelStructures[0] = s.tlas;
            cl.set_bindings(b);
            cl.set_uniforms(LightmapBakeBindings::kUniformParams, Range{&p, sizeof p});
            cl.dispatch((m + 63) / 64, 1, 1);
            cl.end_pass();
            dev.submit(cl);
            dev.commit();
            ++s.dispatchCount;
            auto read = dev.read_storage_image(out, PixelFormat::Rgba32F, 0, 0, int(kImageWidth), int(rows), bytes);
            if (!read.ok()) {
                free_texels();
                free_out();
                return read.error();
            }
            if (bytes.size() != std::size_t(kImageWidth) * rows * 4 * sizeof(float)) {
                free_texels();
                free_out();
                return make_error("the GPU returned an output image of an unexpected size in the lightmap bake");
            }
            const float* px = reinterpret_cast<const float*>(bytes.data());
            for (std::uint32_t k = 0; k < m; ++k) {
                const std::size_t at = (std::size_t(k / 1024) * kImageWidth + 2u * (k % 1024u)) * 4;
                for (int c = 0; c < 3; ++c) {
                    if (sb == 0) direct[std::size_t(k) * 3 + c] = px[at + c];
                    accum[std::size_t(k) * 3 + c] += px[at + 4 + c];
                }
            }
            // The share of this atlas that is done: whole batches plus this batch's share of its samples.
            const std::uint64_t done = first + std::uint64_t(m) * se / std::uint64_t(s.samples);
            if (progress && !progress(done)) {
                free_texels();
                free_out();
                return make_error("cancelled");
            }
        }
        free_texels();
        const float inv = 1.0f / float(s.samples);
        for (std::uint32_t k = 0; k < m; ++k) {
            for (int c = 0; c < 3; ++c) {
                const float v = direct[std::size_t(k) * 3 + c] + accum[std::size_t(k) * 3 + c] * inv;
                rgb[std::size_t(first + k) * 3 + c] = std::isfinite(v) ? std::max(v, 0.0f) : 0.0f;
            }
        }
    }
    free_out();
    return {};
}

}  // namespace fa::render
