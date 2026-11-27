// The D3D12 backend's ray tracing (M79 P1d, src/gpu/d3d12_accel.* and d3d12_raytracing_win32.cpp). The neutral half runs
// on every host: what the capabilities make of Features, Limits and the reason, the bytes of an instance desc, the build
// flags, the size rounding, the geometry checks and the DXIL test. On Windows a WARP device builds a BLAS and a TLAS of
// two instances, traces the engine's rt_probe kernel against them and checks every pixel against the same rays on the
// CPU, then refits, compacts and rebuilds on the frames after. A WARP without DXR tier 1.1 says so (MESSAGE) and passes,
// unless FA_D3D12_REQUIRE_RT=1 (CMake sets it on the ctest render_d3d12_raytracing alone with -DFA_D3D12_REQUIRE_RT=ON,
// which the Windows CI job passes) makes it a failure that names the tier, the shader model and the d3d10warp.dll
// loaded. FA_D3D12_REQUIRE alone does not (it asks for a D3D12 device, not for its ray tracing tier).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <iterator>
#include <memory>
#include <string>
#include <vector>

#include "gpu/d3d12_accel.h"
#include "rt_kernels.h"
#if defined(_WIN32)
#include "fa/core/fs.h"
#include "gpu/d3d12_device.h"
#endif

using namespace fa::gpu;
using namespace fa::gpu::d3d12;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

void put_u32(std::vector<std::uint8_t>& v, std::size_t at, std::uint32_t x) {
    for (int i = 0; i < 4; ++i) v[at + std::size_t(i)] = std::uint8_t(x >> (8 * i));
}

// A container with one part of `fourcc` (and its 8-byte part header) after the part table.
std::vector<std::uint8_t> container(const char* fourcc) {
    std::vector<std::uint8_t> v(32 + 4 + 8, 0);
    std::memcpy(v.data(), "DXBC", 4);
    put_u32(v, 24, std::uint32_t(v.size()));
    put_u32(v, 28, 1);
    put_u32(v, 32, 36);
    std::memcpy(v.data() + 36, fourcc, 4);
    return v;
}

AccelTriangles triangle_list(std::uint32_t vertices) {
    AccelTriangles g;
    g.vertexBuffer = Buffer{1};
    g.vertexStride = 12;
    g.vertexCount = vertices;
    return g;
}

}  // namespace

TEST_CASE("d3d12 ray tracing: the capabilities make the features, the limits and a reason that names what is missing") {
    RtCaps caps;
    caps.tier = kRtTier1_1;
    caps.shaderModel = 0x66;
    caps.interfaces = true;
    caps.adapter = "Test GPU";
    Features f;
    Limits l;
    std::string why = "stale";
    CHECK(apply_rt_caps(caps, f, l, why));
    CHECK(why.empty());
    CHECK(f.rayQuery);
    CHECK(f.accelerationStructure);
    CHECK(f.rayTracingPipeline);
    CHECK(f.bufferDeviceAddress);
    CHECK(l.maxAccelInstances == kMaxTlasInstances);
    CHECK(l.maxAccelGeometries == kMaxBlasGeometries);
    CHECK(l.maxAccelPrimitives == kMaxBlasPrimitives);

    SUBCASE("DXR 1.0: pipelines only, no ray query") {
        caps.tier = kRtTier1_0;
        CHECK_FALSE(apply_rt_caps(caps, f, l, why));
        CHECK_FALSE(f.rayQuery);
        CHECK_FALSE(f.accelerationStructure);
        CHECK(f.rayTracingPipeline);
        CHECK(f.bufferDeviceAddress);
        CHECK(l.maxAccelInstances == 0);
        CHECK(l.maxAccelPrimitives == 0);
        CHECK_MESSAGE(contains(why, "'Test GPU' has DXR tier 1.0 and shader model 6.6"), why);
        CHECK_MESSAGE(contains(why, "needs DXR tier 1.1 and shader model 6.5"), why);
        CHECK_MESSAGE(contains(why, "update the GPU driver"), why);
        CHECK_FALSE(contains(why, "P1d"));
    }
    SUBCASE("no DXR at all, and an old shader model") {
        caps.tier = kRtTierNone;
        caps.shaderModel = 0x51;
        CHECK_FALSE(apply_rt_caps(caps, f, l, why));
        CHECK_FALSE(f.rayTracingPipeline);
        CHECK_MESSAGE(contains(why, "DXR tier none and shader model 5.1"), why);
    }
    SUBCASE("tier 1.1 and shader model 6.5 without ID3D12Device5") {
        caps.shaderModel = kShaderModel6_5;
        caps.interfaces = false;
        caps.adapter.clear();
        CHECK_FALSE(apply_rt_caps(caps, f, l, why));
        CHECK_MESSAGE(contains(why, "'(no name)'"), why);
        CHECK_MESSAGE(contains(why, "ID3D12Device5"), why);
    }
    SUBCASE("tier 1.1 with shader model 6.4") {
        caps.shaderModel = 0x64;
        CHECK_FALSE(apply_rt_caps(caps, f, l, why));
        CHECK_MESSAGE(contains(why, "shader model 6.4"), why);
    }
    CHECK(rt_tier_name(12) == "1.2");
    CHECK(rt_tier_name(99) == "tier 99");
    CHECK(shader_model_name(0) == "unknown");
    CHECK(shader_model_name(0x65) == "6.5");
}

TEST_CASE("d3d12 ray tracing: an instance is the 64 bytes of D3D12_RAYTRACING_INSTANCE_DESC") {
    AccelInstance in;
    for (int i = 0; i < 12; ++i) in.transform[i] = float(i) + 0.5f;
    in.customIndex = 0x123456;
    in.mask = 0xA5;
    in.opaque = true;
    in.cullDisable = true;
    const InstanceDesc d = to_instance_desc(in, 0x0123456789ABCDEFull);
    for (int i = 0; i < 12; ++i) CHECK(d.transform[i] == in.transform[i]);
    CHECK(d.idAndMask == (0x123456u | 0xA5u << 24));
    CHECK(d.contributionAndFlags == ((kInstanceFlagCullDisable | kInstanceFlagForceOpaque) << 24));
    CHECK(d.blas == 0x0123456789ABCDEFull);
    // The bytes the GPU reads: the BLAS address at byte 56.
    unsigned char bytes[sizeof(InstanceDesc)];
    std::memcpy(bytes, &d, sizeof d);
    std::uint64_t at56 = 0;
    std::memcpy(&at56, bytes + 56, 8);
    CHECK(at56 == 0x0123456789ABCDEFull);
    // A custom index past 24 bits keeps its low bits (the backend refuses it before it gets here).
    in.customIndex = 0x1FFFFFF;
    in.opaque = false;
    in.cullDisable = false;
    const InstanceDesc e = to_instance_desc(in, 0);
    CHECK((e.idAndMask & 0xFFFFFFu) == 0xFFFFFFu);
    CHECK((e.idAndMask >> 24) == 0xA5u);
    CHECK(e.contributionAndFlags == 0u);
}

TEST_CASE("d3d12 ray tracing: the build flags, and the sizes rounded to the structure alignment") {
    AccelBuildFlags f;  // preferFastTrace by default
    CHECK(build_flags(f, AccelKind::Blas, false) == kBuildFlagPreferFastTrace);
    f.allowUpdate = true;
    f.allowCompaction = true;
    CHECK(build_flags(f, AccelKind::Blas, false) ==
          (kBuildFlagAllowUpdate | kBuildFlagAllowCompaction | kBuildFlagPreferFastTrace));
    CHECK(build_flags(f, AccelKind::Tlas, false) == (kBuildFlagAllowUpdate | kBuildFlagPreferFastTrace));
    f.preferFastBuild = true;  // wins over preferFastTrace
    CHECK(build_flags(f, AccelKind::Tlas, true) ==
          (kBuildFlagAllowUpdate | kBuildFlagPreferFastBuild | kBuildFlagPerformUpdate));

    const AccelSizes s = round_sizes(1, 256, 257, true);
    CHECK(s.structure == 256);
    CHECK(s.buildScratch == 256);
    CHECK(s.updateScratch == 512);
    CHECK(round_sizes(0, 0, 1000, false).updateScratch == 0);
    CHECK(round_sizes(0, 0, 0, true).structure == 0);
    const AccelSizes big = round_sizes(~std::uint64_t(0), 0, 0, false);  // saturates instead of wrapping to 0
    CHECK(big.structure % kAccelAlignment == 0);
    CHECK(big.structure > (std::uint64_t(1) << 63));
}

TEST_CASE("d3d12 ray tracing: the geometry checks name the geometry and the field") {
    Limits l;
    l.maxAccelGeometries = 2;
    l.maxAccelPrimitives = 10;
    std::uint64_t primitives = 99;
    std::vector<AccelTriangles> g{triangle_list(6)};
    CHECK(check_geometries(g, l, primitives).empty());
    CHECK(primitives == 2);

    CHECK(contains(check_geometries({}, l, primitives), "no geometries"));
    g = {triangle_list(3), triangle_list(3), triangle_list(3)};
    CHECK(contains(check_geometries(g, l, primitives), "3 geometries are more than this device's limit 2"));
    g = {triangle_list(33)};
    std::string what = check_geometries(g, l, primitives);
    CHECK_MESSAGE(contains(what, "11 triangles are more than this device's limit 10"), what);
    CHECK(primitives == 11);

    AccelTriangles bad = triangle_list(4);
    bad.vertexStride = 10;
    bad.vertexFormat = VertexFormat::Float2;
    g = {triangle_list(3), bad};
    what = check_geometries(g, l, primitives);
    CHECK_MESSAGE(contains(what, "geometries[1].vertexFormat is not Float3"), what);
    CHECK_MESSAGE(contains(what, "geometries[1].vertexStride 10"), what);
    CHECK_MESSAGE(contains(what, "geometries[1].vertexCount 4 is not a multiple of 3"), what);
    CHECK_FALSE(contains(what, "geometries[0]"));

    AccelTriangles indexed = triangle_list(4);
    indexed.indexBuffer = Buffer{2};
    indexed.indexType = IndexType::None;
    indexed.indexCount = 5;
    g = {indexed};
    what = check_geometries(g, l, primitives);
    CHECK_MESSAGE(contains(what, "has an index buffer but indexType is not Uint16 or Uint32"), what);
    CHECK_MESSAGE(contains(what, ".indexCount 5 is not a multiple of 3"), what);
    AccelTriangles typed = triangle_list(3);
    typed.indexType = IndexType::Uint32;
    g = {typed};
    CHECK(contains(check_geometries(g, l, primitives), "names an indexType but no index buffer"));
    g = {triangle_list(0)};
    CHECK(contains(check_geometries(g, l, primitives), "has no triangles"));
}

TEST_CASE("d3d12 ray tracing: a DXIL container is told from a DXBC one, and the engine's kernels are DXIL") {
    CHECK(is_dxil_container(container("DXIL").data(), 44));
    CHECK_FALSE(is_dxil_container(container("SHEX").data(), 44));
    CHECK_FALSE(is_dxil_container(container("DXIL").data(), 40));  // the part runs past the bytes given
    std::vector<std::uint8_t> lying = container("DXIL");
    put_u32(lying, 28, 1000000);  // a part count the bytes cannot hold
    CHECK_FALSE(is_dxil_container(lying.data(), lying.size()));
    std::vector<std::uint8_t> notDxbc = container("DXIL");
    notDxbc[0] = 'X';
    CHECK_FALSE(is_dxil_container(notDxbc.data(), notDxbc.size()));
    CHECK_FALSE(is_dxil_container(nullptr, 100));
    for (const fa::rt_kernels::RtKernel& k : fa::rt_kernels::all_rt_kernels()) {
        CAPTURE(std::string(k.name));
        CHECK(is_dxil_container(k.dxil.data(), k.dxil.size()));
    }
    const std::string e = accel_storage_copy_error("tlas memory");
    CHECK(contains(e, "buffer 'tlas memory' holds acceleration structures (usage.accelStorage)"));
    CHECK(contains(kAccelStorageCopyHint, "copy_accel_structure"));
}

#if defined(_WIN32)

namespace {

bool env_is_1(const wchar_t* name) {
    wchar_t v[8];
    const DWORD n = GetEnvironmentVariableW(name, v, DWORD(std::size(v)));
    return n == 1 && v[0] == L'1';
}

// The file of the DLL `name` this process has loaded, in UTF-8 ("none" when there is none).
std::string loaded_module(const wchar_t* name) {
    const HMODULE m = GetModuleHandleW(name);
    if (!m) return "none";
    wchar_t file[4096];
    const DWORD n = GetModuleFileNameW(m, file, DWORD(std::size(file)));
    if (n == 0 || n >= std::size(file)) return "a DLL whose path does not fit";
    return fa::fs::path_to_utf8(std::filesystem::path(std::wstring(file, n)));
}

// The d3d10warp.dll this process has loaded (WARP's own library).
std::string loaded_warp() { return loaded_module(L"d3d10warp.dll"); }

// The D3D12Core.dll this process has loaded: the system's, or the Agility SDK's of D3D12\ beside the program
// (fa_test_render_d3d12_rt, which is what ci.yml runs this file with).
std::string loaded_d3d12_core() { return loaded_module(L"D3D12Core.dll"); }

// What load_nuget_warp did: a sentence, and whether an earlier WARP of the process kept FA_WARP_DIR's from loading.
struct WarpLoad {
    std::string what;
    bool defeated = false;
};

// FA_WARP_DIR (the Windows CI job exports it when the runner's own WARP has no DXR tier 1.1): a folder with the
// d3d10warp.dll of the Microsoft.Direct3D.WARP NuGet package. Loaded before the first WARP device, it is the WARP D3D12
// takes (a DLL of that name is already in the process). The ctest render_d3d12_raytracing runs this file alone, so
// nothing has loaded a WARP before; in a run of the whole fa_test_render (the ctest `render`) the other D3D12 cases
// may have loaded the system's first, and `defeated` says so.
WarpLoad load_nuget_warp() {
    WarpLoad out;
    wchar_t dir[4096];
    const DWORD n = GetEnvironmentVariableW(L"FA_WARP_DIR", dir, DWORD(std::size(dir)));
    if (n == 0 || n >= std::size(dir)) {
        out.what = "FA_WARP_DIR is not set: the system's WARP";
        return out;
    }
    const std::filesystem::path folder(std::wstring(dir, n));
    const std::filesystem::path dll = folder / L"d3d10warp.dll";
    if (const HMODULE m = GetModuleHandleW(L"d3d10warp.dll")) {
        wchar_t file[4096];
        const DWORD fn = GetModuleFileNameW(m, file, DWORD(std::size(file)));
        std::error_code ec;
        const bool same = fn > 0 && fn < std::size(file) &&
                          std::filesystem::equivalent(std::filesystem::path(std::wstring(file, fn)), dll, ec);
        out.what = same ? "the WARP of FA_WARP_DIR (loaded already)"
                        : "an earlier case loaded another WARP, so FA_WARP_DIR's is not used";
        out.defeated = !same;
        return out;
    }
    if (!LoadLibraryExW(dll.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH)) {
        out.what = "FA_WARP_DIR has no loadable d3d10warp.dll (error " + std::to_string(GetLastError()) +
                   "): the system's WARP";
        return out;
    }
    out.what = "the WARP of FA_WARP_DIR";
    return out;
}

// A WARP device with the debug layer, or null (with a MESSAGE) where this Windows has no WARP. FA_D3D12_RT_HARDWARE=1
// (by hand, never in CI) asks for the machine's hardware adapter instead, to run the same tracing case on a GPU.
std::unique_ptr<D3d12Device> make_warp(WarpLoad& load) {
    load = load_nuget_warp();
    MESSAGE("d3d12 ray tracing: " << load.what);
    D3d12Options o;
    o.warp = !env_is_1(L"FA_D3D12_RT_HARDWARE");
    o.debugLayer = true;
    auto d = D3d12Device::create(o);
    if (!d) {
        MESSAGE("d3d12 ray tracing: skipped, no WARP device: " << d.error().to_string());
        return nullptr;
    }
    return std::move(d.value());
}

std::string all_errors(D3d12Device& dev) {
    std::string s;
    for (const std::string& e : dev.errors()) s += e + "\n";
    return s;
}

void submit_and_finish(D3d12Device& dev, CommandList& list) {
    dev.submit(list);
    dev.commit();
    auto r = dev.wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
}

constexpr int kSize = 8;          // the probe image is kSize x kSize, one 8x8 group
constexpr float kMiss = 1000.0f;  // what rt_probe writes where the ray hits nothing

// A quad of `width` x 1 at z = 0 in its BLAS, scaled by (sx, sy) and moved to (tx, ty, tz) by its instance. The rays
// go from the origin through each pixel (rt_probe's camera), and every quad edge sits at least 0.2 from a ray's hit
// point, so the CPU and the GPU agree on which quad each ray hits.
struct Placement {
    float sx, sy, tx, ty, tz;
};

AccelInstance instance_of(const Placement& p, AccelStructure blas, std::uint32_t index) {
    AccelInstance in;
    const float m[12] = {p.sx, 0, 0, p.tx, 0, p.sy, 0, p.ty, 0, 0, 1, p.tz};
    std::memcpy(in.transform, m, sizeof m);
    in.customIndex = index;
    in.cullDisable = true;
    in.blas = blas;
    return in;
}

// The distance rt_probe should write per pixel: the nearest quad along the pixel's ray, or kMiss.
std::vector<float> expected_hits(const std::vector<Placement>& quads, float width) {
    std::vector<float> out(std::size_t(kSize) * kSize, kMiss);
    for (int y = 0; y < kSize; ++y)
        for (int x = 0; x < kSize; ++x) {
            const double u = (x + 0.5) / kSize * 2.0 - 1.0, v = (y + 0.5) / kSize * 2.0 - 1.0;
            const double len = std::sqrt(u * u + v * v + 1.0);
            double best = kMiss;
            for (const Placement& q : quads) {
                const double t = -double(q.tz) * len;  // the plane z = tz along the normalized (u, v, -1)
                const double lx = (u / len * t - q.tx) / q.sx, ly = (v / len * t - q.ty) / q.sy;
                if (lx >= 0 && lx <= width && ly >= 0 && ly <= 1 && t < best) best = t;
            }
            out[std::size_t(y) * kSize + std::size_t(x)] = float(best);
        }
    return out;
}

// "" when every pixel of `got` is within 1e-3 of `want`, else the first one that is not.
std::string first_mismatch(const std::vector<float>& got, const std::vector<float>& want) {
    if (got.size() != want.size()) return "read " + std::to_string(got.size()) + " pixels";
    int hits = 0;
    for (std::size_t i = 0; i < got.size(); ++i) {
        if (std::fabs(got[i] - want[i]) > 1e-3f)
            return "pixel (" + std::to_string(i % kSize) + ", " + std::to_string(i / kSize) +
                   "): " + std::to_string(got[i]) + ", expected " + std::to_string(want[i]);
        if (want[i] < kMiss) ++hits;
    }
    if (hits == 0 || hits == int(want.size())) return "the expectation has no hits or no misses";
    return {};
}

Buffer input_buffer(D3d12Device& dev, const void* data, std::size_t bytes, const char* label) {
    BufferDesc d;
    d.size = bytes;
    d.usage.accelBuildInput = true;
    d.data = Range{data, bytes};
    d.label = label;
    const Buffer b = dev.make_buffer(d);
    REQUIRE_MESSAGE(dev.state(b) == ResourceState::Valid, all_errors(dev));
    return b;
}

}  // namespace

TEST_CASE(
    "d3d12 ray tracing: WARP traces rt_probe against a TLAS of two instances, then refits, compacts and rebuilds") {
    // FA_D3D12_REQUIRE_RT=1 (only the ctest render_d3d12_raytracing has it in CI, which runs this file alone): a WARP
    // that cannot trace rays fails the case instead of skipping it.
    const bool requireRt = env_is_1(L"FA_D3D12_REQUIRE_RT");
    WarpLoad load;
    auto dev = make_warp(load);
    if (!dev) {
        if (requireRt) FAIL("FA_D3D12_REQUIRE_RT=1 and this Windows made no WARP device");
        return;
    }
    std::string why;
    if (!dev->ray_tracing_status(&why)) {
        // The refusals of a device without ray tracing, then the skip.
        CHECK_MESSAGE(contains(why, "needs DXR tier 1.1 and shader model 6.5"), why);
        auto s = dev->tlas_sizes(1, {});
        REQUIRE_FALSE(s);
        CHECK_MESSAGE(contains(s.error().message, "gpu d3d12: Device::tlas_sizes: the d3d12 device on"),
                      s.error().message);
        BufferDesc bd;
        bd.size = 256;
        bd.usage.accelStorage = true;
        bd.label = "no-rt";
        CHECK(dev->state(dev->make_buffer(bd)) == ResourceState::Failed);
        const std::string which = "the d3d10warp.dll loaded: " + loaded_warp() + " (" + load.what +
                                  "), the D3D12Core.dll loaded: " + loaded_d3d12_core();
        if (requireRt)
            // The dedicated ctest (render_d3d12_raytracing) runs this file alone, so `defeated` (an earlier device of
            // the process loaded another WARP first) is a failure there too: nothing ran before this case.
            FAIL_CHECK("FA_D3D12_REQUIRE_RT=1 and this WARP cannot trace rays: "
                       << why << "; " << which
                       << (load.defeated ? " (an earlier case of this process had loaded another WARP: run this file "
                                           "alone, as the render_d3d12_raytracing test does)"
                                         : " (hint: point FA_WARP_DIR at the d3d10warp.dll of the NuGet package "
                                           "Microsoft.Direct3D.WARP)"));
        else
            MESSAGE("d3d12 ray tracing: skipped, this WARP cannot trace rays: " << why << "; " << which);
        return;
    }
    MESSAGE("d3d12 ray tracing: the d3d10warp.dll loaded: " << loaded_warp()
                                                            << ", the D3D12Core.dll loaded: " << loaded_d3d12_core());
    const fa::rt_kernels::RtKernel* kernel = fa::rt_kernels::find_rt_kernel("rt_probe");
    REQUIRE(kernel != nullptr);
    std::string step = "the rt_probe kernel and its pipeline";
    INFO("step: " << step);
    ShaderDesc sd;
    sd.computeFunc.bytecode = Range{kernel->dxil.data(), kernel->dxil.size()};
    sd.usesRayQuery = true;
    sd.accelStructures[0].stage = ShaderStage::Compute;     // t0
    sd.views[0].storageImage.stage = ShaderStage::Compute;  // u0
    sd.views[0].storageImage.imageType = ImageType::Tex2d;
    sd.views[0].storageImage.accessFormat = PixelFormat::R32F;
    sd.uniformBlocks[0].stage = ShaderStage::Compute;  // b0
    sd.uniformBlocks[0].size = 32;
    sd.label = "rt_probe";
    const Shader shader = dev->make_shader(sd);
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = shader;
    pd.label = "rt_probe";
    const Pipeline pipeline = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pipeline) == ResourceState::Valid, all_errors(*dev));
    {
        // The same kernel as HLSL text is refused with what to give instead (D3DCompile's cs_5_1 has no RayQuery).
        ShaderDesc text = sd;
        text.computeFunc.bytecode = Range{};
        text.computeFunc.source = "[numthreads(8, 8, 1)] void main() {}";
        text.label = "rt_probe as text";
        CHECK(dev->state(dev->make_shader(text)) == ResourceState::Failed);
        CHECK_MESSAGE(contains(all_errors(*dev), "RayQuery needs DXIL (cs_6_5)"), all_errors(*dev));
    }
    ImageDesc id;
    id.width = kSize;
    id.height = kSize;
    id.pixelFormat = PixelFormat::R32F;
    id.usage.storageImage = true;
    id.label = "rt_probe out";
    const Image image = dev->make_image(id);
    ViewDesc iv;
    iv.storageImage.image = image;
    const View imageView = dev->make_view(iv);
    REQUIRE_MESSAGE(dev->state(imageView) == ResourceState::Valid, all_errors(*dev));

    step = "the geometry, the sizes, the structures and the scratch";
    const float quad[12] = {0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0};
    const float narrow[12] = {0, 0, 0, 0.5f, 0, 0, 0.5f, 1, 0, 0, 1, 0};  // the same topology, half as wide
    const std::uint16_t indices[6] = {0, 1, 2, 0, 2, 3};
    const Buffer quadVb = input_buffer(*dev, quad, sizeof quad, "quad vertices");
    const Buffer narrowVb = input_buffer(*dev, narrow, sizeof narrow, "narrow vertices");
    const Buffer ib = input_buffer(*dev, indices, sizeof indices, "quad indices");
    AccelTriangles geo;
    geo.vertexBuffer = quadVb;
    geo.vertexStride = 12;
    geo.vertexCount = 4;
    geo.indexBuffer = ib;
    geo.indexType = IndexType::Uint16;
    geo.indexCount = 6;
    geo.opaque = true;
    AccelBuildFlags blasFlags;
    blasFlags.allowUpdate = true;
    blasFlags.allowCompaction = true;
    AccelBuildFlags tlasFlags;
    tlasFlags.allowUpdate = true;
    auto blasSizes = dev->blas_sizes({&geo, 1}, blasFlags);
    REQUIRE_MESSAGE(blasSizes, blasSizes.error().to_string());
    auto tlasSizes = dev->tlas_sizes(2, tlasFlags);
    REQUIRE_MESSAGE(tlasSizes, tlasSizes.error().to_string());
    CHECK(blasSizes.value().structure % kAccelAlignment == 0);
    // WARP answers 0 bytes of update scratch for a two-triangle structure: a refit then needs no scratch at all.
    CHECK(blasSizes.value().updateScratch % kAccelAlignment == 0);
    AccelStructureDesc ad;
    ad.kind = AccelKind::Blas;
    ad.size = blasSizes.value().structure;
    ad.label = "quad";
    auto blas = dev->make_accel_structure(ad);  // memory of its own
    REQUIRE_MESSAGE(blas, blas.error().to_string());
    BufferDesc storage;
    storage.size = std::size_t(kAccelAlignment + tlasSizes.value().structure);
    storage.usage.accelStorage = true;
    storage.label = "tlas memory";
    const Buffer tlasMemory = dev->make_buffer(storage);
    REQUIRE_MESSAGE(dev->state(tlasMemory) == ResourceState::Valid, all_errors(*dev));
    ad.kind = AccelKind::Tlas;
    ad.size = tlasSizes.value().structure;
    ad.storage = tlasMemory;
    ad.storageOffset = std::size_t(kAccelAlignment);  // in the caller's buffer, at an offset
    ad.label = "scene";
    auto tlas = dev->make_accel_structure(ad);
    REQUIRE_MESSAGE(tlas, tlas.error().to_string());
    CHECK(dev->accel_structure_state(tlas.value()) == ResourceState::Valid);
    BufferDesc scratchDesc;
    scratchDesc.size = std::size_t(std::max({blasSizes.value().buildScratch, blasSizes.value().updateScratch,
                                             tlasSizes.value().buildScratch, tlasSizes.value().updateScratch}));
    scratchDesc.usage.accelScratch = true;
    scratchDesc.label = "scratch";
    const Buffer scratch = dev->make_buffer(scratchDesc);  // one scratch for every build: barriers between them
    REQUIRE_MESSAGE(dev->state(scratch) == ResourceState::Valid, all_errors(*dev));
    BufferDesc sizeDesc;
    sizeDesc.size = 16;
    sizeDesc.usage.storageBuffer = true;
    sizeDesc.usage.copySrc = true;
    sizeDesc.label = "compacted size";
    const Buffer sizeBuffer = dev->make_buffer(sizeDesc);
    REQUIRE_MESSAGE(dev->state(sizeBuffer) == ResourceState::Valid, all_errors(*dev));

    const float params[8] = {0, 0, 0, 0, float(kSize), float(kSize), 0, 0};
    auto trace = [&](CommandList& list, AccelStructure scene) {
        list.begin_compute_pass("rt_probe");
        list.set_pipeline(pipeline);
        Bindings b;
        b.views[0] = imageView;
        b.accelStructures[0] = scene;
        list.set_bindings(b);
        list.set_uniforms(0, Range{params, sizeof params});
        list.dispatch(1, 1, 1);
        list.end_pass();
    };
    auto read_hits = [&]() {
        std::vector<std::uint8_t> raw;
        auto r = dev->read_storage_image(image, PixelFormat::R32F, 0, 0, kSize, kSize, raw);
        REQUIRE_MESSAGE(r, r.error().to_string());
        std::vector<float> out(raw.size() / 4);
        std::memcpy(out.data(), raw.data(), out.size() * 4);
        return out;
    };
    auto build_blas = [&](CommandList& list, AccelStructure dst, Buffer vertices, bool update) {
        AccelTriangles g = geo;
        g.vertexBuffer = vertices;
        BlasBuild b;
        b.dst = dst;
        b.geometries = {&g, 1};
        b.flags = blasFlags;
        b.update = update;
        b.scratch = scratch;
        auto r = list.build_blas(b);
        REQUIRE_MESSAGE(r, r.error().to_string());
    };
    auto build_tlas = [&](CommandList& list, AccelStructure blasOfBoth, const std::vector<Placement>& at, bool update) {
        std::vector<AccelInstance> instances;
        for (std::size_t i = 0; i < at.size(); ++i)
            instances.push_back(instance_of(at[i], blasOfBoth, std::uint32_t(i)));
        TlasBuild b;
        b.dst = tlas.value();
        b.instances = instances;
        b.flags = tlasFlags;
        b.update = update;
        b.scratch = scratch;
        auto r = list.build_tlas(b);
        REQUIRE_MESSAGE(r, r.error().to_string());
    };

    // Frame 1: a full build of both, traced in the same list. The near quad covers the left of the image, the far
    // one the right and the middle (behind the near one where they overlap).
    step = "frame 1: build the BLAS and the TLAS, trace";
    const std::vector<Placement> first = {{1, 2, -1.05f, -1.05f, -2}, {3, 3, -0.9f, -0.9f, -4}};
    {
        CommandList& list = dev->begin_commands("rt frame 1");
        build_blas(list, blas.value(), quadVb, false);
        build_tlas(list, blas.value(), first, false);
        trace(list, tlas.value());
        submit_and_finish(*dev, list);
        const std::string bad = first_mismatch(read_hits(), expected_hits(first, 1.0f));
        CHECK_MESSAGE(bad.empty(), bad);
    }

    // Frame 2: the BLAS refits to the narrow vertices in place, the TLAS refits with the far quad moved closer.
    step = "frame 2: refit both, trace";
    const std::vector<Placement> moved = {{1, 2, -1.05f, -1.05f, -2}, {3, 3, -0.9f, -0.9f, -3}};
    {
        CommandList& list = dev->begin_commands("rt frame 2");
        build_blas(list, blas.value(), narrowVb, true);
        build_tlas(list, blas.value(), moved, true);
        trace(list, tlas.value());
        submit_and_finish(*dev, list);
        const std::string bad = first_mismatch(read_hits(), expected_hits(moved, 0.5f));
        CHECK_MESSAGE(bad.empty(), bad);
    }

    // Frame 3: the refitted BLAS is compacted into a structure of the size the GPU answered, and the TLAS is rebuilt
    // over the compacted copy.
    step = "frame 3: compact the BLAS, rebuild the TLAS over it, trace";
    {
        CommandList& query = dev->begin_commands("rt compacted size");
        auto r = query.query_compacted_size(blas.value(), sizeBuffer, 8);
        REQUIRE_MESSAGE(r, r.error().to_string());
        submit_and_finish(*dev, query);
    }
    std::vector<std::uint8_t> raw;
    auto rr = dev->read_buffer(sizeBuffer, 8, 8, raw);
    REQUIRE_MESSAGE(rr, rr.error().to_string());
    std::uint64_t compactedSize = 0;
    std::memcpy(&compactedSize, raw.data(), 8);
    CHECK(compactedSize > 0);
    CHECK(compactedSize <= blasSizes.value().structure);
    ad = {};
    ad.kind = AccelKind::Blas;
    ad.size = compactedSize;
    ad.label = "quad compacted";
    auto compacted = dev->make_accel_structure(ad);
    REQUIRE_MESSAGE(compacted, compacted.error().to_string());
    {
        CommandList& list = dev->begin_commands("rt frame 3");
        auto c = list.copy_accel_structure(blas.value(), compacted.value(), AccelCopyMode::Compact);
        REQUIRE_MESSAGE(c, c.error().to_string());
        build_tlas(list, compacted.value(), moved, false);
        trace(list, tlas.value());
        submit_and_finish(*dev, list);
        const std::string bad = first_mismatch(read_hits(), expected_hits(moved, 0.5f));
        CHECK_MESSAGE(bad.empty(), bad);
    }
    // A compacted structure is not compacted again.
    {
        CommandList& list = dev->begin_commands("rt compact twice");
        auto r = list.query_compacted_size(compacted.value(), sizeBuffer, 0);
        CHECK_FALSE(r);
        if (!r) CHECK_MESSAGE(contains(r.error().message, "built without flags.allowCompaction"), r.error().message);
        submit_and_finish(*dev, list);
    }

    // Frame 4: a full rebuild of the original BLAS from the wide vertices, and of the TLAS over it at first places;
    // the compacted copy is destroyed while the frame that last used it may still run.
    step = "frame 4: rebuild both from scratch, trace";
    dev->destroy_accel_structure(compacted.value());
    CHECK(dev->accel_structure_state(compacted.value()) == ResourceState::Invalid);
    {
        CommandList& list = dev->begin_commands("rt frame 4");
        build_blas(list, blas.value(), quadVb, false);
        build_tlas(list, blas.value(), first, false);
        trace(list, tlas.value());
        submit_and_finish(*dev, list);
        const std::string bad = first_mismatch(read_hits(), expected_hits(first, 1.0f));
        CHECK_MESSAGE(bad.empty(), bad);
    }

    // Frame 5: the refit is in one list and the trace in the next, submitted one after the other with no wait between
    // them. The engine records no UAV barrier between the two lists: ID3D12CommandQueue::ExecuteCommandLists
    // guarantees that the work of the first call finishes before the work of the second starts, and every list is its
    // own call (D3d12Device::submit).
    step = "frame 5: refit in one list, trace in the next one";
    {
        CommandList& refit = dev->begin_commands("rt frame 5 refit");
        build_blas(refit, blas.value(), narrowVb, true);
        build_tlas(refit, blas.value(), moved, true);
        dev->submit(refit);
        CommandList& tracing = dev->begin_commands("rt frame 5 trace");
        trace(tracing, tlas.value());
        dev->submit(tracing);
        dev->commit();
        auto idle = dev->wait_idle();
        REQUIRE_MESSAGE(idle, idle.error().to_string());
        const std::string bad = first_mismatch(read_hits(), expected_hits(moved, 0.5f));
        CHECK_MESSAGE(bad.empty(), bad);
    }

    step = "the refusals: an acceleration structure buffer is never copied, a build checks its sizes";
    {
        CommandList& list = dev->begin_commands("rt refusals");
        const std::uint8_t zeros[16] = {};
        BufferWrite w;
        w.buffer = tlasMemory;
        w.data = Range{zeros, sizeof zeros};
        list.write_buffer(w);  // reported, nothing recorded
        BlasBuild b;
        b.dst = blas.value();
        b.geometries = {&geo, 1};
        b.flags = blasFlags;
        b.scratch = sizeBuffer;  // 16 bytes, no accelScratch
        auto r = list.build_blas(b);
        REQUIRE_FALSE(r);
        CHECK_MESSAGE(
            contains(r.error().message, "scratch buffer 'compacted size' was not made with usage.accelScratch"),
            r.error().message);
        b.scratch = scratch;
        b.update = true;
        b.flags.allowUpdate = false;
        r = list.build_blas(b);
        REQUIRE_FALSE(r);
        CHECK_MESSAGE(contains(r.error().message, "with other flags than its build"), r.error().message);
        TlasBuild t;
        t.dst = blas.value();  // a BLAS
        AccelInstance one = instance_of(first[0], blas.value(), 0);
        t.instances = {&one, 1};
        t.scratch = scratch;
        auto rt = list.build_tlas(t);
        REQUIRE_FALSE(rt);
        CHECK_MESSAGE(contains(rt.error().message, "is a BLAS: build_tlas writes a TLAS"), rt.error().message);
        list.begin_compute_pass("inside");
        r = list.build_blas(b);
        REQUIRE_FALSE(r);
        CHECK_MESSAGE(contains(r.error().message, "inside a pass"), r.error().message);
        list.end_pass();
        submit_and_finish(*dev, list);
        CHECK_MESSAGE(contains(all_errors(*dev), "buffer 'tlas memory' holds acceleration structures"),
                      all_errors(*dev));
        std::vector<std::uint8_t> out;
        auto rb = dev->read_buffer(tlasMemory, 0, 16, out);
        REQUIRE_FALSE(rb);
        CHECK(contains(rb.error().hint, "copy_accel_structure"));
    }

    step = "the debug layer said nothing";
    std::string layer;
    for (const std::string& e : dev->errors())
        if (contains(e, "debug layer")) layer += e + "\n";
    CHECK_MESSAGE(layer.empty(), layer);
    dev->destroy_accel_structure(tlas.value());
    dev->destroy_accel_structure(blas.value());
    CHECK(dev->wait_idle());
}

#endif  // _WIN32
