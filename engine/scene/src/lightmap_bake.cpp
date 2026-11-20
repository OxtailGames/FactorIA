// The CPU lightmap baker (fa/scene/lightmap_bake.h): validation and budgets, the atlas rasterisation, the path tracer, the post passes
// (denoise, gutter) and the spherical-harmonics probes. Every random number is a hash of (seed, atlas, texel, sample, bounce): see
// docs/design/ARCHITECTURE_BAKING.md for the rules that keep the result the same with any number of threads.
#include "fa/scene/lightmap_bake.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <limits>
#include <string>
#include <string_view>
#include <utility>

#include "fa/core/command.h"
#include "fa/core/det_math.h"
#include "fa/core/jobs.h"
#include "fa/scene/bvh.h"

namespace fa {

namespace {

constexpr float kFar = 1e30f;
constexpr std::uint64_t kU64Max = std::numeric_limits<std::uint64_t>::max();

// ---- 64-bit saturating size maths (size_t is 32 bits on wasm32) ---------------------------------------------------------------------

std::uint64_t sat_add(std::uint64_t a, std::uint64_t b) { return a > kU64Max - b ? kU64Max : a + b; }
std::uint64_t sat_mul(std::uint64_t a, std::uint64_t b) { return (a != 0 && b > kU64Max / a) ? kU64Max : a * b; }

// ---- counter-based random numbers ---------------------------------------------------------------------------------------------------

std::uint64_t mix64(std::uint64_t x) {
    x += 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebull;
    return x ^ (x >> 31);
}
std::uint64_t combine(std::uint64_t key, std::uint64_t v) { return mix64(key ^ mix64(v + 0x632be59bd9b4e019ull)); }
// 0 <= result < 1, from the high 24 bits
float to_unit(std::uint64_t h) { return float(h >> 40) * (1.0f / 16777216.0f); }
float rnd(std::uint64_t key, std::uint64_t dim) { return to_unit(combine(key, dim)); }
float fract(float x) { return x - std::floor(x); }

float radical2(std::uint32_t i) {
    i = (i << 16) | (i >> 16);
    i = ((i & 0x55555555u) << 1) | ((i & 0xAAAAAAAAu) >> 1);
    i = ((i & 0x33333333u) << 2) | ((i & 0xCCCCCCCCu) >> 2);
    i = ((i & 0x0F0F0F0Fu) << 4) | ((i & 0xF0F0F0F0u) >> 4);
    i = ((i & 0x00FF00FFu) << 8) | ((i & 0xFF00FF00u) >> 8);
    return float(i) * 2.3283064365386963e-10f;
}

// Sample `s` of `count` of a 2D point set: Hammersley, shifted (mod 1) by two numbers of the key so that every texel and light has its own
// copy of the pattern. With one sample it is a plain hash.
void sample2d(std::uint64_t key, std::uint32_t s, std::uint32_t count, float& u1, float& u2) {
    const float r1 = rnd(key, 0x51), r2 = rnd(key, 0x52);
    if (count <= 1) {
        u1 = r1;
        u2 = r2;
        return;
    }
    u1 = fract((float(s) + 0.5f) / float(count) + r1);
    u2 = fract(radical2(s) + r2);
}

struct Basis {
    Vec3 t, b, n;
    Vec3 to_world(Vec3 l) const { return t * l.x + b * l.y + n * l.z; }
};
Basis basis_of(Vec3 n) {
    const Vec3 ref = std::fabs(n.x) < 0.9f ? Vec3{1, 0, 0} : Vec3{0, 1, 0};
    const Vec3 t = normalize(cross(ref, n));
    return {t, cross(n, t), n};
}

Vec3 cosine_hemisphere(const Basis& bs, float u1, float u2) {
    const float r = std::sqrt(u1);
    float s, c;
    det::sin_cos(2.0f * kPi * u2, s, c);
    return normalize(bs.to_world({r * c, r * s, std::sqrt(std::max(0.0f, 1.0f - u1))}));
}
Vec3 sphere_direction(float u1, float u2) {
    const float z = 1.0f - 2.0f * u1;
    const float r = std::sqrt(std::max(0.0f, 1.0f - z * z));
    float s, c;
    det::sin_cos(2.0f * kPi * u2, s, c);
    return {r * c, z, r * s};
}

float max3(Vec3 v) { return std::max(v.x, std::max(v.y, v.z)); }
float luminance(Vec3 v) { return 0.2126f * v.x + 0.7152f * v.y + 0.0722f * v.z; }
bool finite3(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }
bool finite3(Vec2 v) { return std::isfinite(v.x) && std::isfinite(v.y); }
float smoothstep(float e0, float e1, float x) {
    if (e1 == e0) return x >= e1 ? 1.0f : 0.0f;
    const float t = saturate((x - e0) / (e1 - e0));
    return t * t * (3.0f - 2.0f * t);
}

std::string at(std::string_view what, std::size_t i, std::string_view field) {
    return "/" + std::string(what) + "/" + std::to_string(i) + "/" + std::string(field);
}

// ---- validation and budgets ---------------------------------------------------------------------------------------------------------

struct Sizes {
    std::uint64_t texels = 0, triangles = 0, vertices = 0;
};

// Roughly what one texel, one triangle and one probe keep alive during a bake (a margin included): see ARCHITECTURE_BAKING.md.
constexpr std::uint64_t kBytesPerTexel = 80;
constexpr std::uint64_t kBytesPerTriangle = 240;
constexpr std::uint64_t kBytesPerProbe = 160;

Result<void> check_settings(const BakeSettings& s) {
    auto bad = [](std::string field, std::string what, std::string hint) -> Result<void> {
        return make_error("bake settings " + field + " " + what, std::move(hint));
    };
    if (s.samples < 1 || s.samples > 65536)
        return bad("/samples", "is " + std::to_string(s.samples) + ", the range is 1..65536",
                   "use 16 for a preview and 256 or more for a final bake");
    if (s.bounces < 0 || s.bounces > 16)
        return bad("/bounces", "is " + std::to_string(s.bounces) + ", the range is 0..16",
                   "2 or 3 bounces carry most of the indirect light");
    if (s.shadowSamples < 1 || s.shadowSamples > 1024)
        return bad("/shadowSamples", "is " + std::to_string(s.shadowSamples) + ", the range is 1..1024",
                   "1 gives hard shadows, 4 to 16 soft ones");
    if (s.dilatePasses < 0 || s.dilatePasses > 64)
        return bad("/dilatePasses", "is " + std::to_string(s.dilatePasses) + ", the range is 0..64",
                   "4 texels of gutter hide the seams of bilinear filtering");
    if (s.denoiseRadius < 0 || s.denoiseRadius > 8)
        return bad("/denoiseRadius", "is " + std::to_string(s.denoiseRadius) + ", the range is 0..8",
                   "0 turns the denoise off");
    if (!(s.denoiseSigma >= 0.01f && s.denoiseSigma <= 10.0f))
        return bad("/denoiseSigma", "must be between 0.01 and 10", "0.3 keeps the edges of shadows; larger blurs more");
    if (!(s.rayEpsilon >= 0) || !std::isfinite(s.rayEpsilon))
        return bad("/rayEpsilon", "must be 0 (automatic) or a positive distance in meters", "leave it 0");
    if (s.maxAtlasSize < 1 || s.maxAtlasSize > 16384)
        return bad("/maxAtlasSize", "must be 1..16384", "4096 is a 64 MB atlas of floats");
    return {};
}

Result<void> validate_impl(const BakeScene& scene, const BakeSettings& st, bool probes, Sizes& sizes,
                           std::uint64_t& memory) {
    if (auto r = check_settings(st); !r) return r;
    // The atlases first: their sizes are what the memory budget is made of, and checking them allocates nothing.
    if (!probes) {
        for (std::size_t a = 0; a < scene.atlases.size(); ++a) {
            const BakeAtlas& at_ = scene.atlases[a];
            if (at_.width < 1 || at_.height < 1)
                return make_error("atlas " + at("atlases", a, "width") + " x height is " + std::to_string(at_.width) +
                                      " x " + std::to_string(at_.height) + ": an atlas needs at least 1 x 1 texels",
                                  "give it a positive size, or remove the atlas and set the meshes' atlas to -1");
            if (at_.width > st.maxAtlasSize || at_.height > st.maxAtlasSize)
                return make_error("atlas " + at("atlases", a, "width") + " x height is " + std::to_string(at_.width) +
                                      " x " + std::to_string(at_.height) + ", larger than the maximum of " +
                                      std::to_string(st.maxAtlasSize) + " texels",
                                  "use a smaller atlas (suggest_atlas_size picks one from the surface area and the "
                                  "texels per meter), more atlases, or raise maxAtlasSize");
            sizes.texels = sat_add(sizes.texels, sat_mul(std::uint64_t(at_.width), std::uint64_t(at_.height)));
        }
    }
    for (const BakeMesh& m : scene.meshes) {
        sizes.triangles = sat_add(sizes.triangles, std::uint64_t(m.indices.size() / 3));
        sizes.vertices = sat_add(sizes.vertices, std::uint64_t(m.positions.size()));
    }
    memory = sat_add(sat_mul(sizes.texels, kBytesPerTexel), sat_mul(sizes.triangles, kBytesPerTriangle));
    if (memory > st.maxMemoryBytes)
        return make_error("the bake needs about " + std::to_string(memory >> 20) + " MB (" +
                              std::to_string(sizes.texels) + " texels, " + std::to_string(sizes.triangles) +
                              " triangles), over the budget of " + std::to_string(st.maxMemoryBytes >> 20) +
                              " MB (/maxMemoryBytes)",
                          "bake smaller atlases or fewer triangles, or raise maxMemoryBytes if the machine has the "
                          "memory; nothing was allocated");
    if (sizes.triangles >= (1ull << 31))
        return make_error("the scene has " + std::to_string(sizes.triangles) +
                              " triangles, more than the 2^31 the baker indexes",
                          "bake the scene in parts");

    for (std::size_t i = 0; i < scene.meshes.size(); ++i) {
        const BakeMesh& m = scene.meshes[i];
        const std::string name = m.name.empty() ? "mesh " + std::to_string(i) : "mesh '" + m.name + "'";
        if (m.indices.size() % 3 != 0)
            return make_error(name + " " + at("meshes", i, "indices") + " has " + std::to_string(m.indices.size()) +
                                  " entries, not a multiple of 3",
                              "give three indices per triangle");
        if (m.indices.empty() && m.positions.empty()) continue;
        for (std::size_t k = 0; k < m.indices.size(); ++k)
            if (m.indices[k] >= m.positions.size())
                return make_error(name + " " + at("meshes", i, "indices") + "/" + std::to_string(k) + " is " +
                                      std::to_string(m.indices[k]) + " but the mesh has " +
                                      std::to_string(m.positions.size()) + " positions",
                                  "every index must be below the number of positions");
        for (std::size_t k = 0; k < m.positions.size(); ++k)
            if (!finite3(m.positions[k]))
                return make_error(name + " " + at("meshes", i, "positions") + "/" + std::to_string(k) +
                                      " is not a finite number",
                                  "remove the NaN or infinite vertex");
        if (!m.normals.empty() && m.normals.size() != m.positions.size())
            return make_error(name + " " + at("meshes", i, "normals") + " has " + std::to_string(m.normals.size()) +
                                  " entries but there are " + std::to_string(m.positions.size()) + " positions",
                              "give one normal per position, or none for flat triangles");
        for (std::size_t k = 0; k < m.normals.size(); ++k)
            if (!finite3(m.normals[k]))
                return make_error(name + " " + at("meshes", i, "normals") + "/" + std::to_string(k) +
                                      " is not a finite number",
                                  "remove the NaN or infinite normal");
        const std::size_t matCount = std::max<std::size_t>(scene.materials.size(), 1);
        if (!m.materials.empty() && m.materials.size() != m.indices.size() / 3)
            return make_error(name + " " + at("meshes", i, "materials") + " has " + std::to_string(m.materials.size()) +
                                  " entries but the mesh has " + std::to_string(m.indices.size() / 3) + " triangles",
                              "give one material index per triangle, or none for material 0");
        for (std::size_t k = 0; k < m.materials.size(); ++k)
            if (m.materials[k] >= matCount)
                return make_error(name + " " + at("meshes", i, "materials") + "/" + std::to_string(k) + " is " +
                                      std::to_string(m.materials[k]) + " but the scene has " +
                                      std::to_string(matCount) + " materials",
                                  "add the material to /materials or use an index below " + std::to_string(matCount));
        if (!probes && m.atlas >= 0) {
            if (std::size_t(m.atlas) >= scene.atlases.size())
                return make_error(name + " " + at("meshes", i, "atlas") + " is " + std::to_string(m.atlas) +
                                      " but the scene has " + std::to_string(scene.atlases.size()) + " atlases",
                                  "add the atlas to /atlases, or set atlas to -1 for a mesh that only casts shadows");
            if (m.lightmapUv.size() != m.positions.size())
                return make_error(name + " " + at("meshes", i, "lightmapUv") + " has " +
                                      std::to_string(m.lightmapUv.size()) + " entries but there are " +
                                      std::to_string(m.positions.size()) + " positions",
                                  "a mesh baked into an atlas needs one lightmap UV per position (generate them with "
                                  "the UV2 step), or set atlas to -1");
            for (std::size_t k = 0; k < m.lightmapUv.size(); ++k) {
                const Vec2 uv = m.lightmapUv[k];
                if (!finite3(uv) || uv.x < -1e-4f || uv.x > 1.0001f || uv.y < -1e-4f || uv.y > 1.0001f)
                    return make_error(name + " " + at("meshes", i, "lightmapUv") + "/" + std::to_string(k) + " is (" +
                                          std::to_string(uv.x) + ", " + std::to_string(uv.y) +
                                          "), outside 0..1 of the atlas",
                                      "lightmap UVs are the position of the vertex in the atlas, 0..1; repack the UVs "
                                      "or scale them into their atlas rectangle");
            }
        }
    }
    for (std::size_t i = 0; i < scene.materials.size(); ++i) {
        const BakeMaterial& m = scene.materials[i];
        const float a[3] = {m.albedo.x, m.albedo.y, m.albedo.z};
        for (float v : a)
            if (!(v >= 0.0f && v <= 1.0f))
                return make_error(
                    "material " + at("materials", i, "albedo") + " has a channel of " + std::to_string(v) +
                        ", outside 0..1",
                    "albedo is a reflectance: 0 black, 1 white; use emissive for light the surface sends out");
        if (!finite3(m.emissive) || m.emissive.x < 0 || m.emissive.y < 0 || m.emissive.z < 0)
            return make_error("material " + at("materials", i, "emissive") + " must be finite and not negative",
                              "use 0 for none");
    }
    for (std::size_t i = 0; i < scene.lights.size(); ++i) {
        const BakeLight& l = scene.lights[i];
        const std::string where = "light " + at("lights", i, "");
        if (!finite3(l.color) || l.color.x < 0 || l.color.y < 0 || l.color.z < 0)
            return make_error(where + "color must be finite and not negative",
                              "use 0..1 channels, or more for a bright light");
        if (!std::isfinite(l.intensity) || l.intensity < 0)
            return make_error(where + "intensity must be finite and not negative", "use 0 to switch the light off");
        if (!finite3(l.position) || !finite3(l.direction))
            return make_error(where + "position and direction must be finite", "remove the NaN or infinite value");
        const bool needsDir = l.kind != BakeLightKind::Point;
        if (needsDir && length_sq(l.direction) < 1e-12f)
            return make_error(
                where + "direction is the zero vector",
                "a directional, spot or area light needs the direction it points to, e.g. (0, -1, 0) for down");
        if ((l.kind == BakeLightKind::Point || l.kind == BakeLightKind::Spot) && l.falloff == BakeFalloff::Engine &&
            !(l.range > 0))
            return make_error(
                where + "range is " + std::to_string(l.range) + " but the engine falloff needs a range above 0",
                "give the light a range in meters, or use the InverseSquare falloff (range 0 = no limit)");
        if (!std::isfinite(l.range) || l.range < 0)
            return make_error(where + "range must be finite and not negative",
                              "use 0 for no limit with the InverseSquare falloff");
        if (l.kind == BakeLightKind::Spot) {
            if (!(l.spotAngleDeg > 0 && l.spotAngleDeg < 90))
                return make_error(where + "spotAngleDeg is " + std::to_string(l.spotAngleDeg) +
                                      ", the range is above 0 and below 90",
                                  "it is the half angle of the cone");
            if (!(l.spotInnerDeg >= 0 && l.spotInnerDeg <= l.spotAngleDeg))
                return make_error(where + "spotInnerDeg must be 0 (automatic) or between 0 and spotAngleDeg",
                                  "the inner cone is inside the outer one");
        }
        if (!(l.softRadius >= 0) || !(l.softAngleDeg >= 0 && l.softAngleDeg <= 45))
            return make_error(where + "softRadius must be >= 0 and softAngleDeg 0..45", "0 gives hard shadows");
        if (l.kind == BakeLightKind::Area && !(l.width > 0 && l.height > 0))
            return make_error(where + "an area light needs width and height above 0", "its size in meters");
    }
    const BakeSky& sky = scene.sky;
    if (!finite3(sky.zenith) || !finite3(sky.horizon) || !finite3(sky.ground) || !std::isfinite(sky.intensity) ||
        sky.intensity < 0)
        return make_error("sky colors and intensity must be finite and not negative (/sky)", "use 0 for no sky light");
    const BakeEquirect& img = sky.image;
    if (img.width > 0 || img.height > 0 || !img.rgb.empty()) {
        if (img.width < 1 || img.height < 1 ||
            sat_mul(sat_mul(std::uint64_t(std::max(img.width, 0)), std::uint64_t(std::max(img.height, 0))), 3) !=
                img.rgb.size())
            return make_error("sky image (/sky/image) is " + std::to_string(img.width) + " x " +
                                  std::to_string(img.height) + " with " + std::to_string(img.rgb.size()) + " floats",
                              "an equirectangular image has width x height x 3 floats (linear RGB)");
        for (float v : img.rgb)
            if (!std::isfinite(v) || v < 0)
                return make_error("sky image (/sky/image/rgb) holds a negative or non-finite value",
                                  "a Radiance .hdr holds none; clamp the image before the bake");
    }
    return {};
}

// ---- the scene, flattened for the tracer --------------------------------------------------------------------------------------------

struct LightRt {
    BakeLightKind kind = BakeLightKind::Directional;
    bool direct = false;  // lights the texels
    bool bounce = false;  // lights the surfaces the paths hit
    BakeFalloff falloff = BakeFalloff::Engine;
    Vec3 col{};  // color * intensity
    Vec3 pos{};
    Vec3 dir{};          // unit
    Vec3 right{}, up{};  // area
    float range = 0;
    float cosOuter = 0, cosInner = 0;  // spot (cosInner 0 = the realtime rule)
    float softRadius = 0, tanSoft = 0;
    float width = 1, height = 1;
};

struct Prepared {
    std::vector<Vec3> corners;   // three per triangle, every mesh in order
    std::vector<Vec3> cornerN;   // shading normals, three per triangle (the face normal for flat meshes)
    std::vector<Vec2> cornerUv;  // three per triangle (zero for meshes without an atlas)
    std::vector<Vec3> faceN;     // unit, on the lit side; zero for a triangle with no area
    std::vector<std::uint32_t> material;
    std::vector<std::int32_t> atlas;
    std::vector<std::int32_t> casterOf;       // global triangle -> index in the BVH, -1 when it casts nothing
    std::vector<std::uint32_t> casterGlobal;  // BVH triangle -> global triangle
    std::vector<BakeMaterial> materials;
    std::vector<LightRt> lights;
    TriBvh bvh;
    float eps = 1e-3f;
};

Prepared prepare(const BakeScene& scene, const BakeSettings& st, bool probes) {
    Prepared p;
    p.materials = scene.materials;
    if (p.materials.empty()) p.materials.push_back(BakeMaterial{});
    std::size_t tris = 0;
    for (const BakeMesh& m : scene.meshes) tris += m.indices.size() / 3;
    p.corners.reserve(tris * 3);
    p.cornerN.reserve(tris * 3);
    p.cornerUv.reserve(tris * 3);
    p.faceN.reserve(tris);
    p.material.reserve(tris);
    p.atlas.reserve(tris);
    p.casterOf.assign(tris, -1);
    std::vector<Vec3> casterCorners;
    Vec3 lo{kFar, kFar, kFar}, hi{-kFar, -kFar, -kFar};
    for (const BakeMesh& m : scene.meshes) {
        const bool smooth = !m.normals.empty();
        const bool baked = !probes && m.atlas >= 0;
        for (const Vec3& v : m.positions) {
            lo = min(lo, v);
            hi = max(hi, v);
        }
        for (std::size_t t = 0; t + 3 <= m.indices.size(); t += 3) {
            const std::size_t g = p.faceN.size();
            Vec3 c[3];
            for (int k = 0; k < 3; ++k) c[k] = m.positions[m.indices[t + std::size_t(k)]];
            Vec3 raw = cross(c[1] - c[0], c[2] - c[0]);
            const float len = length(raw);
            Vec3 fn = len > 1e-20f ? raw / len : Vec3{};
            Vec3 n[3] = {fn, fn, fn};
            if (smooth) {
                Vec3 avg{};
                for (int k = 0; k < 3; ++k) {
                    n[k] = m.normals[m.indices[t + std::size_t(k)]];
                    avg += n[k];
                }
                if (dot(fn, avg) < 0) fn = -fn;  // the side the vertex normals point to is the lit side
                for (int k = 0; k < 3; ++k) {
                    const float nl = length(n[k]);
                    n[k] = nl > 1e-6f ? n[k] / nl : fn;
                }
            }
            for (int k = 0; k < 3; ++k) {
                p.corners.push_back(c[k]);
                p.cornerN.push_back(n[k]);
                p.cornerUv.push_back(baked ? m.lightmapUv[m.indices[t + std::size_t(k)]] : Vec2{});
            }
            p.faceN.push_back(fn);
            p.material.push_back(m.materials.empty() ? 0u : m.materials[t / 3]);
            p.atlas.push_back(baked ? std::int32_t(m.atlas) : -1);
            if (m.castsShadow && len > 0.0f) {
                p.casterOf[g] = std::int32_t(p.casterGlobal.size());
                p.casterGlobal.push_back(std::uint32_t(g));
                for (int k = 0; k < 3; ++k) casterCorners.push_back(c[k]);
            }
        }
    }
    p.bvh.build(casterCorners.data(), p.casterGlobal.size());
    float diag = lo.x > hi.x ? 1.0f : length(hi - lo);
    if (!(diag > 1e-6f)) diag = 1.0f;
    p.eps = st.rayEpsilon > 0 ? st.rayEpsilon : diag * 1e-4f;

    for (const BakeLight& l : scene.lights) {
        if (l.mode == BakeLightMode::Realtime) continue;
        LightRt r;
        r.kind = l.kind;
        r.direct = l.mode == BakeLightMode::Baked;
        r.bounce = true;
        r.falloff = l.falloff;
        r.col = l.color * l.intensity;
        r.pos = l.position;
        r.dir = length_sq(l.direction) > 0 ? normalize(l.direction) : Vec3{0, -1, 0};
        r.range = l.range;
        r.softRadius = l.softRadius;
        r.width = l.width;
        r.height = l.height;
        if (l.kind == BakeLightKind::Directional && l.softAngleDeg > 0) {
            float s, c;
            det::sin_cos(l.softAngleDeg * (kPi / 180.0f), s, c);
            r.tanSoft = s / c;
        }
        if (l.kind == BakeLightKind::Spot) {
            r.cosOuter = det::cos(l.spotAngleDeg * (kPi / 180.0f));
            r.cosInner = l.spotInnerDeg > 0 ? det::cos(l.spotInnerDeg * (kPi / 180.0f)) : 0.0f;
        }
        if (l.kind == BakeLightKind::Area) {
            const Basis bs = basis_of(r.dir);
            r.right = bs.t;
            r.up = bs.b;
        }
        p.lights.push_back(r);
    }
    return p;
}

// ---- the tracer ---------------------------------------------------------------------------------------------------------------------

class Tracer {
public:
    Tracer(const Prepared& p, const BakeSky& skyIn, const BakeSettings& st) : p_(p), sky_(skyIn), st_(st) {}

    // The sky radiance in a direction.
    Vec3 sky(Vec3 d) const {
        const BakeEquirect& img = sky_.image;
        if (img.width > 0 && img.height > 0) {
            float u = 0.5f + det::atan2(d.z, d.x) / (2.0f * kPi) + sky_.image.rotationDeg / 360.0f;
            u = fract(u);
            const float v = det::acos(clamp(d.y, -1.0f, 1.0f)) / kPi;
            const float fx = u * float(img.width) - 0.5f,
                        fy = clamp(v * float(img.height) - 0.5f, 0.0f, float(img.height - 1));
            const int x0 = int(std::floor(fx)), y0 = int(std::floor(fy));
            const float tx = fx - float(x0), ty = fy - float(y0);
            auto px = [&](int x, int y) {
                x = ((x % img.width) + img.width) % img.width;
                y = std::min(std::max(y, 0), img.height - 1);
                const std::size_t k = (std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 3;
                return Vec3{img.rgb[k], img.rgb[k + 1], img.rgb[k + 2]};
            };
            const Vec3 top = lerp(px(x0, y0), px(x0 + 1, y0), tx), bot = lerp(px(x0, y0 + 1), px(x0 + 1, y0 + 1), tx);
            return lerp(top, bot, ty) * sky_.intensity;
        }
        const Vec3 c =
            d.y >= 0 ? lerp(sky_.horizon, sky_.zenith, saturate(d.y)) : lerp(sky_.horizon, sky_.ground, saturate(-d.y));
        return c * sky_.intensity;
    }

    // One sample of light `l` seen from `P`: the direction and distance to it and what a surface facing it would receive. False: no light.
    bool sample_light(const LightRt& l, Vec3 P, float u1, float u2, Vec3& dir, float& dist, Vec3& weight) const {
        if (l.kind == BakeLightKind::Directional) {
            dir = -l.dir;
            if (l.tanSoft > 0) {
                const Basis bs = basis_of(dir);
                const float r = std::sqrt(u1) * l.tanSoft;
                float s, c;
                det::sin_cos(2.0f * kPi * u2, s, c);
                dir = normalize(dir + bs.t * (r * c) + bs.b * (r * s));
            }
            dist = kFar;
            weight = l.col;
            return true;
        }
        Vec3 target = l.pos;
        Vec3 centre = l.pos - P;
        const float centreLen = length(centre);
        if (centreLen < 1e-5f) return false;
        const Vec3 centreDir = centre / centreLen;
        if (l.kind == BakeLightKind::Area) {
            target = l.pos + l.right * ((u1 - 0.5f) * l.width) + l.up * ((u2 - 0.5f) * l.height);
        } else if (l.softRadius > 0) {
            const Basis bs = basis_of(centreDir);
            const float r = std::sqrt(u1) * l.softRadius;
            float s, c;
            det::sin_cos(2.0f * kPi * u2, s, c);
            target = l.pos + bs.t * (r * c) + bs.b * (r * s);
        }
        const Vec3 to = target - P;
        const float d2 = std::max(dot(to, to), 1e-4f);
        dist = std::sqrt(d2);
        dir = to / dist;
        if (l.kind == BakeLightKind::Area) {
            const float cosl = dot(l.dir, -dir);
            if (cosl <= 0) return false;
            weight = l.col * (cosl * l.width * l.height / (kPi * d2));
            return true;
        }
        float atten;
        if (l.falloff == BakeFalloff::Engine) {
            const float x = saturate(1.0f - (dist / l.range) * (dist / l.range));
            atten = x * x;
        } else {
            atten = 1.0f / d2;
            if (l.range > 0) {
                const float x =
                    saturate(1.0f - (dist / l.range) * (dist / l.range) * (dist / l.range) * (dist / l.range));
                atten *= x * x;
            }
        }
        if (l.kind == BakeLightKind::Spot) {
            const float cosA = dot(-centreDir, l.dir);
            atten *=
                smoothstep(l.cosOuter, l.cosInner > 0 ? l.cosInner : l.cosOuter + (1.0f - l.cosOuter) * 0.25f, cosA);
        }
        if (atten <= 0) return false;
        weight = l.col * atten;
        return true;
    }

    // The direct light that reaches a surface point: every light (the Baked ones, or also the IndirectOnly ones at a bounce), `count`
    // shadow rays each. `skip` is the triangle (of the BVH) the point is on.
    Vec3 direct(Vec3 P, Vec3 Ns, Vec3 Ng, std::int32_t skip, std::uint64_t key, std::uint32_t count, bool atBounce,
                std::uint64_t& rays) const {
        Vec3 sum{};
        const Vec3 o = P + Ng * p_.eps;
        for (std::size_t li = 0; li < p_.lights.size(); ++li) {
            const LightRt& l = p_.lights[li];
            if (!(atBounce ? l.bounce : l.direct)) continue;
            const std::uint64_t lkey = combine(key, 0x1000 + li);
            Vec3 acc{};
            for (std::uint32_t s = 0; s < count; ++s) {
                float u1, u2;
                sample2d(lkey, s, count, u1, u2);
                Vec3 dir, w;
                float dist;
                if (!sample_light(l, o, u1, u2, dir, dist, w)) continue;
                const float ndl = dot(Ns, dir);
                if (ndl <= 1e-4f || dot(Ng, dir) <= 1e-4f) continue;
                ++rays;
                if (p_.bvh.occluded(o, dir, dist - 2.0f * p_.eps, skip)) continue;
                acc += w * ndl;
            }
            sum += acc / float(count);
        }
        return sum;
    }

    // The radiance that comes back along the ray (o, d): what it sees, plus the bounces of light after the first hit.
    Vec3 path(Vec3 o, Vec3 d, std::int32_t skip, std::uint64_t key, std::uint64_t& rays) const {
        Vec3 result{}, T{1, 1, 1};
        for (int depth = 1;; ++depth) {
            ++rays;
            RayHit h;
            if (!p_.bvh.closest(o, d, kFar, skip, h)) {
                result += T * sky(d);
                break;
            }
            const std::uint32_t g = p_.casterGlobal[std::size_t(h.tri)];
            const Vec3 P = o + d * h.t;
            Vec3 Ng = p_.faceN[g];
            if (dot(Ng, d) > 0) Ng = -Ng;
            const BakeMaterial& m = p_.materials[p_.material[g]];
            result += T * m.emissive;
            if (depth > st_.bounces) break;
            const Vec3 alb = m.albedo;
            if (max3(alb) <= 0) break;
            const std::uint64_t dkey = combine(key, 0x2000 + std::uint64_t(depth));
            result += T * alb * direct(P, Ng, Ng, h.tri, dkey, 1, true, rays);
            T = T * alb;
            if (depth >= 2) {  // Russian roulette: continue with probability p and weigh the survivors 1/p (unbiased)
                const float pk = clamp(max3(T), 0.05f, 1.0f);
                if (rnd(dkey, 0x77) >= pk) break;
                T = T / pk;
            }
            d = cosine_hemisphere(basis_of(Ng), rnd(dkey, 0x78), rnd(dkey, 0x79));
            o = P + Ng * p_.eps;
            skip = h.tri;
        }
        return result;
    }

    const Prepared& prepared() const { return p_; }
    const BakeSettings& settings() const { return st_; }

private:
    const Prepared& p_;
    const BakeSky& sky_;
    const BakeSettings& st_;
};

// ---- batches: progress, cancel ------------------------------------------------------------------------------------------------------

Error cancelled_error() {
    return make_error("cancelled", "the bake was cancelled before it finished; nothing was returned");
}

// Runs fn(i, rays) for i in [0, count) on the job pool, in batches: after each batch the calling thread reports progress and looks at the
// cancel flag. The batch and chunk sizes depend only on `count` and `grain`, and fn writes only slot i, so the threads change nothing.
template <class Fn>
Result<std::uint64_t> run_batches(const std::string& label, std::size_t count, std::size_t grain, Fn&& fn) {
    const std::atomic<bool>* flag = command_cancel_flag();
    auto is_cancelled = [&] { return flag != nullptr && flag->load(std::memory_order_relaxed); };
    if (is_cancelled()) return cancelled_error();
    const std::size_t batch = std::max<std::size_t>(256, (count + 39) / 40);
    std::uint64_t rays = 0;
    for (std::size_t b0 = 0; b0 < count; b0 += batch) {
        const std::size_t n = std::min(batch, count - b0);
        auto parts = jobs::parallel_map_chunks<std::uint64_t>("lightmap bake", n, grain, [&](const jobs::Chunk& c) {
            std::uint64_t r = 0;
            for (std::size_t i = c.begin; i < c.end; ++i) {
                if (is_cancelled()) break;
                fn(b0 + i, r);
            }
            return r;
        });
        if (!parts) return parts.error();
        for (std::uint64_t r : parts.value()) rays += r;
        if (is_cancelled()) return cancelled_error();
        const std::size_t done = b0 + n;
        report_command_progress(label + ", texels " + std::to_string(done) + "/" + std::to_string(count) + " (" +
                                std::to_string(done * 100 / count) + "%)");
    }
    return rays;
}

// ---- the atlas: which triangle covers which texel -----------------------------------------------------------------------------------

struct TexelMap {
    int width = 0, height = 0;
    std::vector<std::int32_t> tri;  // global triangle, -1 for none
    std::vector<float> b1, b2;
    std::vector<std::uint32_t> work;  // covered texels, in order
    std::uint32_t overlapped = 0;
};

TexelMap rasterize_atlas(const Prepared& p, int atlas, const BakeAtlas& size) {
    TexelMap m;
    m.width = size.width;
    m.height = size.height;
    const std::size_t n = std::size_t(m.width) * std::size_t(m.height);
    m.tri.assign(n, -1);
    m.b1.assign(n, 0.0f);
    m.b2.assign(n, 0.0f);
    const float W = float(m.width), H = float(m.height);
    for (std::size_t g = 0; g < p.faceN.size(); ++g) {
        if (p.atlas[g] != atlas || length_sq(p.faceN[g]) < 0.5f) continue;
        const Vec2 a{p.cornerUv[3 * g].x * W, p.cornerUv[3 * g].y * H},
            b{p.cornerUv[3 * g + 1].x * W, p.cornerUv[3 * g + 1].y * H},
            c{p.cornerUv[3 * g + 2].x * W, p.cornerUv[3 * g + 2].y * H};
        const float area = cross(b - a, c - a);
        if (std::fabs(area) < 1e-9f) continue;
        const int x0 = std::max(0, int(std::floor(std::min(a.x, std::min(b.x, c.x)) - 0.5f)));
        const int x1 = std::min(m.width - 1, int(std::ceil(std::max(a.x, std::max(b.x, c.x)) - 0.5f)));
        const int y0 = std::max(0, int(std::floor(std::min(a.y, std::min(b.y, c.y)) - 0.5f)));
        const int y1 = std::min(m.height - 1, int(std::ceil(std::max(a.y, std::max(b.y, c.y)) - 0.5f)));
        for (int y = y0; y <= y1; ++y) {
            for (int x = x0; x <= x1; ++x) {
                const Vec2 q{float(x) + 0.5f, float(y) + 0.5f};
                const float w1 = cross(q - a, c - a) / area;  // weight of corner 1
                const float w2 = cross(b - a, q - a) / area;  // weight of corner 2
                const float w0 = 1.0f - w1 - w2;
                if (w0 < -1e-5f || w1 < -1e-5f || w2 < -1e-5f) continue;
                const std::size_t i = std::size_t(y) * std::size_t(m.width) + std::size_t(x);
                if (m.tri[i] >= 0) {
                    if (w0 > 1e-4f && w1 > 1e-4f && w2 > 1e-4f) ++m.overlapped;
                    continue;
                }
                m.tri[i] = std::int32_t(g);
                m.b1[i] = w1;
                m.b2[i] = w2;
            }
        }
    }
    for (std::size_t i = 0; i < n; ++i)
        if (m.tri[i] >= 0) m.work.push_back(std::uint32_t(i));
    return m;
}

// ---- denoise ------------------------------------------------------------------------------------------------------------------------

// A cross-bilateral filter on the baked texels: neighbours weigh by distance in the atlas, by how much their surface faces the same way and
// lies on the same plane (in texel spacings), and by how close their light is (relative to the light). Reads `in`, writes `out`.
Result<void> denoise_atlas(const std::string& label, int width, int height, int radius, float sigmaC,
                           const std::vector<std::uint8_t>& mask, const std::vector<Vec3>& pos,
                           const std::vector<Vec3>& nrm, const std::vector<float>& in, std::vector<float>& out) {
    out = in;
    const float sigmaS = std::max(0.5f, float(radius) * 0.5f);
    std::vector<float> spatial;
    for (int dy = -radius; dy <= radius; ++dy)
        for (int dx = -radius; dx <= radius; ++dx)
            spatial.push_back(det::exp(-float(dx * dx + dy * dy) / (2.0f * sigmaS * sigmaS)));
    const int side = 2 * radius + 1;
    auto r = run_batches(label, std::size_t(width) * std::size_t(height), 256, [&](std::size_t i, std::uint64_t&) {
        if (mask[i] != kBakeBaked) return;
        const int x = int(i % std::size_t(width)), y = int(i / std::size_t(width));
        auto valid = [&](int xx, int yy) {
            return xx >= 0 && yy >= 0 && xx < width && yy < height &&
                   mask[std::size_t(yy) * std::size_t(width) + std::size_t(xx)] == kBakeBaked;
        };
        // the spacing of the texels here, in meters: the nearest valid 4-neighbour
        float spacing = kFar;
        const int off[4][2] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
        for (const auto& o : off)
            if (valid(x + o[0], y + o[1]))
                spacing = std::min(
                    spacing, length(pos[std::size_t(y + o[1]) * std::size_t(width) + std::size_t(x + o[0])] - pos[i]));
        if (spacing >= kFar || spacing < 1e-9f) return;
        const Vec3 c{in[3 * i], in[3 * i + 1], in[3 * i + 2]};
        const float lc = luminance(c);
        const float sc = sigmaC * lc + 0.01f;
        Vec3 sum{};
        float wTotal = 0;
        for (int dy = -radius; dy <= radius; ++dy) {
            for (int dx = -radius; dx <= radius; ++dx) {
                if (!valid(x + dx, y + dy)) continue;
                const std::size_t j = std::size_t(y + dy) * std::size_t(width) + std::size_t(x + dx);
                const float nd = std::max(0.0f, dot(nrm[i], nrm[j]));
                float wn = nd * nd;
                wn *= wn;
                wn *= wn;
                const float plane = std::fabs(dot(nrm[i], pos[j] - pos[i])) / spacing;
                const float wp = det::exp(-2.0f * plane * plane);
                const Vec3 cj{in[3 * j], in[3 * j + 1], in[3 * j + 2]};
                const float dl = luminance(cj) - lc;
                const float wc = det::exp(-(dl * dl) / (2.0f * sc * sc));
                const float w =
                    spatial[std::size_t(dy + radius) * std::size_t(side) + std::size_t(dx + radius)] * wn * wp * wc;
                sum += cj * w;
                wTotal += w;
            }
        }
        if (wTotal > 1e-12f) {
            out[3 * i] = sum.x / wTotal;
            out[3 * i + 1] = sum.y / wTotal;
            out[3 * i + 2] = sum.z / wTotal;
        }
    });
    if (!r) return r.error();
    return {};
}

// ---- spherical harmonics ------------------------------------------------------------------------------------------------------------

}  // namespace

void sh_basis(Vec3 d, float y[9]) {
    y[0] = 0.282094792f;
    y[1] = 0.488602512f * d.y;
    y[2] = 0.488602512f * d.z;
    y[3] = 0.488602512f * d.x;
    y[4] = 1.092548431f * d.x * d.y;
    y[5] = 1.092548431f * d.y * d.z;
    y[6] = 0.315391565f * (3.0f * d.z * d.z - 1.0f);
    y[7] = 1.092548431f * d.x * d.z;
    y[8] = 0.546274215f * (d.x * d.x - d.y * d.y);
}

ShL2 sh_project_cube(int size, const float* rgb) {
    // The faces as the cube map specification lays them out (+X -X +Y -Y +Z -Z; row 0 is the top of the face): the direction of a
    // texel is fwd + u * right + v * up, u and v in -1..1 at its centre, and its solid angle is proportional to (1 + u^2 + v^2)^-1.5.
    static const float kFwd[6][3] = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}};
    static const float kRight[6][3] = {{0, 0, -1}, {0, 0, 1}, {1, 0, 0}, {1, 0, 0}, {1, 0, 0}, {-1, 0, 0}};
    static const float kUp[6][3] = {{0, 1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}, {0, 1, 0}, {0, 1, 0}};
    double sum[9][3] = {};
    double weight = 0.0;
    const std::size_t faceTexels = std::size_t(size) * std::size_t(size);
    for (int f = 0; f < 6; ++f)
        for (int y = 0; y < size; ++y)
            for (int x = 0; x < size; ++x) {
                const double u = (2.0 * x + 1.0) / size - 1.0, v = 1.0 - (2.0 * y + 1.0) / size;
                double d[3];
                for (int i = 0; i < 3; ++i) d[i] = kFwd[f][i] + u * kRight[f][i] + v * kUp[f][i];
                const double len = std::sqrt(d[0] * d[0] + d[1] * d[1] + d[2] * d[2]);
                const double w = 1.0 / (len * len * len);
                float basis[9];
                sh_basis({float(d[0] / len), float(d[1] / len), float(d[2] / len)}, basis);
                const float* px = rgb + 3 * (std::size_t(f) * faceTexels + std::size_t(y) * size + x);
                for (int k = 0; k < 9; ++k)
                    for (int c = 0; c < 3; ++c) sum[k][c] += double(px[c]) * double(basis[k]) * w;
                weight += w;
            }
    ShL2 out;
    const double norm =
        weight > 0.0 ? 4.0 * 3.14159265358979323846 / weight : 0.0;  // the weights add up to the sphere's 4 pi
    for (int k = 0; k < 9; ++k) out.c[k] = {float(sum[k][0] * norm), float(sum[k][1] * norm), float(sum[k][2] * norm)};
    return out;
}

namespace {

std::uint64_t ray_estimate(const BakeSettings& st, std::size_t lightCount, std::uint64_t items) {
    // per item: samples x (the gather ray + for each bounce a next ray and a shadow ray per light) + the shadow rays of the direct light
    const std::uint64_t perSample = sat_add(1, sat_mul(std::uint64_t(st.bounces), sat_add(1, lightCount)));
    const std::uint64_t perItemRays =
        sat_add(sat_mul(std::uint64_t(st.samples), perSample), sat_mul(std::uint64_t(st.shadowSamples), lightCount));
    return sat_mul(items, perItemRays);
}

Error ray_budget_error(std::uint64_t estimate, const BakeSettings& st, std::uint64_t items, const char* itemName) {
    return make_error("the bake would trace up to " + std::to_string(estimate) + " rays (" + std::to_string(items) +
                          " " + itemName + " x " + std::to_string(st.samples) + " samples x " +
                          std::to_string(st.bounces + 1) + " bounces and lights), over the budget of " +
                          std::to_string(st.maxRays) + " (/maxRays)",
                      "lower samples or bounces, bake a smaller atlas, or raise maxRays; nothing was traced");
}

}  // namespace

// ---- public API ---------------------------------------------------------------------------------------------------------------------

Result<void> validate_bake(const BakeScene& scene, const BakeSettings& settings) {
    Sizes sizes;
    std::uint64_t memory = 0;
    return validate_impl(scene, settings, false, sizes, memory);
}

Result<BakeResult> bake_lightmap(const BakeScene& scene, const BakeSettings& st) {
    if (const std::atomic<bool>* flag = command_cancel_flag(); flag != nullptr && flag->load(std::memory_order_relaxed))
        return cancelled_error();
    Sizes sizes;
    std::uint64_t memory = 0;
    if (auto r = validate_impl(scene, st, false, sizes, memory); !r) return r.error();

    const Prepared prep = prepare(scene, st, false);
    const Tracer tracer(prep, scene.sky, st);

    BakeResult result;
    result.stats.triangles = sizes.triangles;
    result.stats.memoryBudget = memory;
    std::vector<TexelMap> maps;
    std::uint64_t covered = 0;
    for (std::size_t a = 0; a < scene.atlases.size(); ++a) {
        maps.push_back(rasterize_atlas(prep, int(a), scene.atlases[a]));
        covered = sat_add(covered, maps.back().work.size());
    }
    const std::uint64_t estimate = ray_estimate(st, prep.lights.size(), covered);
    result.stats.rayBudget = estimate;
    if (estimate > st.maxRays) return ray_budget_error(estimate, st, covered, "texels");

    result.atlases.resize(scene.atlases.size());
    for (std::size_t a = 0; a < scene.atlases.size(); ++a) {
        const TexelMap& map = maps[a];
        BakedAtlas& out = result.atlases[a];
        const std::size_t n = std::size_t(map.width) * std::size_t(map.height);
        out.width = map.width;
        out.height = map.height;
        out.rgb.assign(n * 3, 0.0f);
        out.mask.assign(n, kBakeEmpty);
        out.overlappedTexels = map.overlapped;
        std::vector<Vec3> gpos, gnrm;
        if (st.denoiseRadius > 0) {
            gpos.assign(n, Vec3{});
            gnrm.assign(n, Vec3{});
        }
        const std::uint64_t atlasKey = combine(combine(0xfac70a1a5eedull, st.seed), std::uint64_t(a) + 1);
        const std::string label =
            "lightmap bake: atlas " + std::to_string(a + 1) + "/" + std::to_string(scene.atlases.size());
        auto rays = run_batches(label, map.work.size(), 16, [&](std::size_t k, std::uint64_t& r) {
            const std::size_t i = map.work[k];
            const std::size_t g = std::size_t(map.tri[i]);
            const float b1 = map.b1[i], b2 = map.b2[i], b0 = 1.0f - b1 - b2;
            const Vec3 P = prep.corners[3 * g] * b0 + prep.corners[3 * g + 1] * b1 + prep.corners[3 * g + 2] * b2;
            const Vec3 Ng = prep.faceN[g];
            Vec3 Ns = prep.cornerN[3 * g] * b0 + prep.cornerN[3 * g + 1] * b1 + prep.cornerN[3 * g + 2] * b2;
            const float nl = length(Ns);
            Ns = nl > 1e-6f ? Ns / nl : Ng;
            const std::uint64_t key = combine(atlasKey, i);
            const std::int32_t skip = prep.casterOf[g];
            const Vec3 o = P + Ng * prep.eps;
            Vec3 value = tracer.direct(P, Ns, Ng, skip, combine(key, 0xD1), std::uint32_t(st.shadowSamples), false, r);
            const Basis bs = basis_of(Ns);
            Vec3 gather{};
            for (int s = 0; s < st.samples; ++s) {
                const std::uint64_t skey = combine(key, 0x10000 + std::uint64_t(s));
                float u1, u2;
                sample2d(key, std::uint32_t(s), std::uint32_t(st.samples), u1, u2);
                const Vec3 d = cosine_hemisphere(bs, u1, u2);
                if (dot(d, Ng) <= 1e-4f)
                    continue;  // a shading normal that leans over the edge of the face: nothing lights it from below the surface
                gather += tracer.path(o, d, skip, skey, r);
            }
            value += gather / float(st.samples);
            out.rgb[3 * i] = value.x;
            out.rgb[3 * i + 1] = value.y;
            out.rgb[3 * i + 2] = value.z;
            out.mask[i] = kBakeBaked;
            if (!gpos.empty()) {
                gpos[i] = P;
                gnrm[i] = Ns;
            }
        });
        if (!rays) return rays.error();
        result.stats.rays = sat_add(result.stats.rays, rays.value());
        out.bakedTexels = std::uint32_t(map.work.size());
        result.stats.texels = sat_add(result.stats.texels, map.work.size());
        if (st.denoiseRadius > 0) {
            std::vector<float> smoothed;
            if (auto r = denoise_atlas(
                    "lightmap denoise: atlas " + std::to_string(a + 1) + "/" + std::to_string(scene.atlases.size()),
                    map.width, map.height, st.denoiseRadius, st.denoiseSigma, out.mask, gpos, gnrm, out.rgb, smoothed);
                !r)
                return r.error();
            out.rgb = std::move(smoothed);
        }
        out.dilatedTexels = std::uint32_t(dilate_texels(out.width, out.height, out.rgb, out.mask, st.dilatePasses));
    }
    return result;
}

std::size_t dilate_texels(int width, int height, std::vector<float>& rgb, std::vector<std::uint8_t>& mask, int passes) {
    if (width < 1 || height < 1) return 0;
    const std::size_t n = std::size_t(width) * std::size_t(height);
    if (rgb.size() != n * 3 || mask.size() != n) return 0;
    std::size_t total = 0;
    std::vector<std::uint8_t> prev;
    for (int pass = 0; pass < passes; ++pass) {
        prev = mask;
        std::size_t filled = 0;
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                const std::size_t i = std::size_t(y) * std::size_t(width) + std::size_t(x);
                if (prev[i] != kBakeEmpty) continue;
                Vec3 sum{};
                int cnt = 0;
                for (int dy = -1; dy <= 1; ++dy) {
                    for (int dx = -1; dx <= 1; ++dx) {
                        const int xx = x + dx, yy = y + dy;
                        if ((dx == 0 && dy == 0) || xx < 0 || yy < 0 || xx >= width || yy >= height) continue;
                        const std::size_t j = std::size_t(yy) * std::size_t(width) + std::size_t(xx);
                        if (prev[j] == kBakeEmpty) continue;
                        sum += Vec3{rgb[3 * j], rgb[3 * j + 1], rgb[3 * j + 2]};
                        ++cnt;
                    }
                }
                if (cnt == 0) continue;
                rgb[3 * i] = sum.x / float(cnt);
                rgb[3 * i + 1] = sum.y / float(cnt);
                rgb[3 * i + 2] = sum.z / float(cnt);
                mask[i] = kBakeDilated;
                ++filled;
            }
        }
        total += filled;
        if (filled == 0) break;
    }
    return total;
}

int suggest_atlas_size(double surfaceArea, double texelsPerMeter, int maxSize) {
    const int top = std::max(16, maxSize);
    if (!(surfaceArea > 0) || !(texelsPerMeter > 0)) return 16;
    const double texels = surfaceArea * texelsPerMeter * texelsPerMeter / (2.0 / 3.0);
    const double side = std::sqrt(texels);
    int s = 16;
    while (double(s) < side && s < top) s *= 2;
    return std::min(s, top);
}

std::uint64_t hash_bake_result(const BakeResult& result) {
    std::uint64_t h = 1469598103934665603ull;
    auto feed = [&](std::uint64_t v) {
        h ^= v;
        h *= 1099511628211ull;
    };
    feed(result.atlases.size());
    for (const BakedAtlas& a : result.atlases) {
        feed(std::uint64_t(a.width));
        feed(std::uint64_t(a.height));
        for (std::uint8_t m : a.mask) feed(m);
        for (float f : a.rgb) {
            std::uint32_t bits;
            static_assert(sizeof(bits) == sizeof(f));
            std::memcpy(&bits, &f, sizeof(bits));
            feed(bits);
        }
    }
    return h;
}

Vec3 sh_irradiance(const ShL2& sh, Vec3 normal, int bands) {
    float y[9];
    sh_basis(normal, y);
    static const float kScale[9] = {1.0f, 2.0f / 3.0f, 2.0f / 3.0f, 2.0f / 3.0f, 0.25f, 0.25f, 0.25f, 0.25f, 0.25f};
    const int count = bands <= 0 ? 1 : (bands == 1 ? 4 : 9);
    Vec3 r{};
    for (int k = 0; k < count; ++k) r += sh.c[k] * (kScale[k] * y[k]);
    return r;
}

Result<std::vector<ShL2>> sample_irradiance_sh(const BakeScene& scene, const std::vector<Vec3>& points,
                                               const BakeSettings& st) {
    if (const std::atomic<bool>* flag = command_cancel_flag(); flag != nullptr && flag->load(std::memory_order_relaxed))
        return cancelled_error();
    Sizes sizes;
    std::uint64_t memory = 0;
    if (auto r = validate_impl(scene, st, true, sizes, memory); !r) return r.error();
    memory = sat_add(memory, sat_mul(points.size(), kBytesPerProbe));
    if (memory > st.maxMemoryBytes)
        return make_error("the probes need about " + std::to_string(memory >> 20) + " MB (" +
                              std::to_string(points.size()) + " points), over the budget of " +
                              std::to_string(st.maxMemoryBytes >> 20) + " MB (/maxMemoryBytes)",
                          "sample fewer points per call or raise maxMemoryBytes; nothing was allocated");
    for (std::size_t i = 0; i < points.size(); ++i)
        if (!finite3(points[i]))
            return make_error("probe point /points/" + std::to_string(i) + " is not a finite position",
                              "remove the NaN or infinite point");

    const Prepared prep = prepare(scene, st, true);
    const Tracer tracer(prep, scene.sky, st);
    const std::uint64_t estimate = ray_estimate(st, prep.lights.size(), points.size());
    if (estimate > st.maxRays) return ray_budget_error(estimate, st, points.size(), "probes");

    std::vector<ShL2> out(points.size());
    const std::uint64_t baseKey = combine(0x5bde1b7ull, st.seed);
    auto rays = run_batches("light probes", points.size(), 2, [&](std::size_t i, std::uint64_t& r) {
        const Vec3 P = points[i];
        const std::uint64_t key = combine(baseKey, i);
        ShL2 sh;
        const float weight = 4.0f * kPi / float(st.samples);
        for (int s = 0; s < st.samples; ++s) {
            float u1, u2;
            sample2d(key, std::uint32_t(s), std::uint32_t(st.samples), u1, u2);
            const Vec3 d = sphere_direction(u1, u2);
            const Vec3 L = tracer.path(P, d, -1, combine(key, 0x10000 + std::uint64_t(s)), r);
            float y[9];
            sh_basis(d, y);
            for (int k = 0; k < 9; ++k) sh.c[k] += L * (y[k] * weight);
        }
        if (st.shIncludeDirect) {
            for (std::size_t li = 0; li < prep.lights.size(); ++li) {
                const LightRt& l = prep.lights[li];
                if (!l.direct) continue;
                const std::uint64_t lkey = combine(key, 0x1000 + li);
                for (int s = 0; s < st.shadowSamples; ++s) {
                    float u1, u2;
                    sample2d(lkey, std::uint32_t(s), std::uint32_t(st.shadowSamples), u1, u2);
                    Vec3 dir, w;
                    float dist;
                    if (!tracer.sample_light(l, P, u1, u2, dir, dist, w)) continue;
                    ++r;
                    if (prep.bvh.occluded(P, dir, dist - 2.0f * prep.eps, -1)) continue;
                    float y[9];
                    sh_basis(dir, y);
                    // a delta light of "facing value" w is the radiance pi * w in its direction: irradiance / pi = w max(0, n.l)
                    const float f = kPi / float(st.shadowSamples);
                    for (int k = 0; k < 9; ++k) sh.c[k] += w * (y[k] * f);
                }
            }
        }
        out[i] = sh;
    });
    if (!rays) return rays.error();
    return out;
}

}  // namespace fa
