// M73.1a: clustered forward lighting, the CPU half (src/light_clusters.h; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Clustered
// lights"). No GPU: these run where `ctest -LE gpu` does (render_postprocess_core). The cluster assignment is compared with a brute-force
// reference (every light whose sphere holds a point must be in the list of the point's cluster, the cluster found with the same numbers
// the fragment shader gets), the lists must be the same bytes with any number of job threads, the data texture has the layout
// shaders/light_data.glsl reads, and a scene of at most 32 lights gives every fragment the lights in the order of today's loop.
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <string>
#include <vector>

#include "fa/core/jobs.h"

#include "light_clusters.h"
#include "mesh_batch.h"

using namespace fa;
using namespace fa::render;

namespace {

// A tiny deterministic generator (the tests must not depend on std::rand or on the engine's world rng).
struct Lcg {
    std::uint32_t s;
    explicit Lcg(std::uint32_t seed) : s(seed) {}
    float next() {  // 0..1
        s = s * 1664525u + 1013904223u;
        return float(s >> 8) / float(1u << 24);
    }
    float range(float a, float b) { return a + (b - a) * next(); }
};

struct View {
    ClusterCamera cam;
    ClusterGrid grid;
};

View make_view(int w, int h, bool zeroToOne, Vec3 eye = {0, 0, 0}, Vec3 target = {0, 0, -1}, float nearD = 0.1f,
               float farD = 200.0f) {
    View v;
    const Mat4 view = Mat4::look_at(eye, target);
    const Mat4 proj = Mat4::perspective(60.0f, float(w) / float(h), nearD, farD, zeroToOne);
    v.cam.viewProj = proj * view;
    v.cam.position = eye;
    v.cam.forward = normalize(target - eye);
    v.cam.nearDepth = nearD;
    v.cam.farDepth = farD;
    v.cam.widthPx = w;
    v.cam.heightPx = h;
    v.grid = make_cluster_grid(w, h, nearD, farD);
    return v;
}

std::vector<LightSphere> random_spheres(std::uint32_t seed, int count, float spread, float rMin, float rMax) {
    Lcg r(seed);
    std::vector<LightSphere> s;
    s.resize(std::size_t(count));
    for (LightSphere& l : s) {
        l.x = r.range(-spread, spread);
        l.y = r.range(-spread * 0.5f, spread * 0.5f);
        l.z = r.range(-spread * 2.0f, spread * 0.3f);  // some behind the camera
        l.radius = r.range(rMin, rMax);
    }
    return s;
}

// The cluster of a world position, the way the fragment shader finds it from fa_cl_* (shaders/light_data.glsl, fa_cluster_lookup).
// False when the position is outside the grid's view (the shader gives such a fragment no local lights; it is not in the picture).
bool cluster_of(const ClusterUniforms& u, const ClusterGrid& g, Vec3 p, int& out) {
    const float cx = u.vpx[0] * p.x + u.vpx[1] * p.y + u.vpx[2] * p.z + u.vpx[3];
    const float cy = u.vpy[0] * p.x + u.vpy[1] * p.y + u.vpy[2] * p.z + u.vpy[3];
    const float cw = u.vpw[0] * p.x + u.vpw[1] * p.y + u.vpw[2] * p.z + u.vpw[3];
    if (!(cw > 1e-4f)) return false;
    const float nx = cx / cw, ny = cy / cw;
    if (nx < -1.0f || nx > 1.0f || ny < -1.0f || ny > 1.0f) return false;
    const float depth = u.fwd[0] * p.x + u.fwd[1] * p.y + u.fwd[2] * p.z + u.fwd[3];
    if (depth < g.nearDepth) return false;
    out = cluster_index(g, cluster_tile(nx, g.tilesX), cluster_tile(ny, g.tilesY), cluster_slice(g, depth));
    return true;
}

LightData local_light(float x, float y, float z, float range) {
    LightData l;
    l.pos = {x, y, z, range};
    l.color = {1, 1, 1, 1};
    l.dir = {0, 0, 0, 0};
    l.rank = 2;
    return l;
}

}  // namespace

TEST_CASE("clusters: the grid has at most 65536 clusters and its slices grow with the distance") {
    const int sizes[][2] = {{1, 1}, {640, 360}, {1280, 720}, {1920, 1080}, {3840, 2160}, {7680, 4320}, {16384, 16384}};
    for (const auto& s : sizes) {
        const ClusterGrid g = make_cluster_grid(s[0], s[1], 0.1f, 500.0f);
        CAPTURE(s[0]);
        CHECK(g.clusters() <= kMaxClusters);
        CHECK(g.tilesX >= 1);
        CHECK(g.tilesY >= 1);
        CHECK(g.slices == kClusterSlices);
    }
    const ClusterGrid g = make_cluster_grid(1920, 1080, 0.1f, 500.0f);
    CHECK(g.tilesX == 30);
    CHECK(g.tilesY == 17);
    int last = 0;
    for (float d = 0.01f; d < 2000.0f; d *= 1.07f) {
        const int s = cluster_slice(g, d);
        CHECK(s >= last);
        CHECK(s < kClusterSlices);
        last = s;
    }
    CHECK(cluster_slice(g, 0.05f) == 0);
    CHECK(cluster_slice(g, 0.1f) == 0);
    CHECK(cluster_slice(g, 500.0f) == kClusterSlices - 1);
    CHECK(cluster_slice(g, 1e9f) == kClusterSlices - 1);
    CHECK(cluster_slice(g, std::numeric_limits<float>::quiet_NaN()) == 0);
    CHECK(cluster_tile(-1.0f, 30) == 0);
    CHECK(cluster_tile(1.0f, 30) == 29);
    CHECK(cluster_tile(std::numeric_limits<float>::quiet_NaN(), 30) == 0);
    // A degenerate camera (far not beyond near, NaN) still gives a usable grid.
    const ClusterGrid d = make_cluster_grid(100, 100, 5.0f, 5.0f);
    CHECK(std::isfinite(d.slicesPerOctave));
    CHECK(d.slicesPerOctave > 0.0f);
    const ClusterGrid n =
        make_cluster_grid(100, 100, std::numeric_limits<float>::quiet_NaN(), std::numeric_limits<float>::infinity());
    CHECK(std::isfinite(n.slicesPerOctave));
    CHECK(n.nearDepth > 0.0f);
}

TEST_CASE("clusters: a light that cannot shine in the view reaches no cluster") {
    const View v = make_view(1280, 720, true);
    ClusterRange r;
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {0, 0, -10, 0.0f}, r));  // no size
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {0, 0, -10, -1.0f}, r));
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {0, 0, -10, std::numeric_limits<float>::quiet_NaN()}, r));
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {std::numeric_limits<float>::quiet_NaN(), 0, -10, 1.0f}, r));
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {0, 0, 50, 2.0f}, r));     // behind the camera
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {0, 0, -900, 2.0f}, r));   // beyond the far plane
    CHECK_FALSE(light_cluster_range(v.cam, v.grid, {500, 0, -10, 2.0f}, r));  // far to the side
    CHECK(light_cluster_range(v.cam, v.grid, {0, 0, -10, 2.0f}, r));
    CHECK(r.x0 <= r.x1);
    CHECK(r.y0 <= r.y1);
    CHECK(r.s0 <= r.s1);
    // A light around the camera reaches every tile.
    CHECK(light_cluster_range(v.cam, v.grid, {0, 0, 0, 5.0f}, r));
    CHECK(r.x0 == 0);
    CHECK(r.x1 == v.grid.tilesX - 1);
    CHECK(r.y0 == 0);
    CHECK(r.y1 == v.grid.tilesY - 1);
}

TEST_CASE("clusters: every light that reaches a point is in the list of the point's cluster (brute-force reference)") {
    for (const bool zeroToOne : {false, true}) {
        // 1280x720, and a view that looks sideways from a point away from the origin: the numbers must not depend on the pose.
        for (int pose = 0; pose < 2; ++pose) {
            CAPTURE(zeroToOne);
            CAPTURE(pose);
            const View v = pose == 0 ? make_view(1280, 720, zeroToOne)
                                     : make_view(1000, 800, zeroToOne, {12, 3, 7}, {-20, 1, -30}, 0.3f, 300.0f);
            const auto spheres = random_spheres(7u + std::uint32_t(pose), 300, 60.0f, 0.5f, 6.0f);
            ClusterLists lists;
            build_light_clusters(v.cam, v.grid, spheres, lists);
            REQUIRE(lists.first.size() == std::size_t(v.grid.clusters()));
            CHECK(lists.clippedEntries == 0);
            CHECK(lists.clippedClusters == 0);
            CHECK(int(lists.maxPerCluster) < kMaxLightsPerCluster / 4);  // far from the cap
            CHECK(lists.lightsAssigned > 0);

            std::vector<LightData> table;
            for (const LightSphere& s : spheres) table.push_back(local_light(s.x, s.y, s.z, s.radius));
            LightTexture tex;
            pack_light_texture(table, 0, v.cam, &lists, tex);

            Lcg r(99);
            int checked = 0, covered = 0;
            for (int n = 0; n < 6000; ++n) {
                const Vec3 p{r.range(-40.0f, 40.0f) + v.cam.position.x, r.range(-25.0f, 25.0f) + v.cam.position.y,
                             r.range(-80.0f, 10.0f) + v.cam.position.z};
                int c = 0;
                if (!cluster_of(tex.uniforms, v.grid, p, c)) continue;
                ++checked;
                const std::uint32_t first = lists.first[std::size_t(c)], count = lists.count[std::size_t(c)];
                for (std::size_t i = 0; i < spheres.size(); ++i) {
                    const LightSphere& s = spheres[i];
                    const float dx = p.x - s.x, dy = p.y - s.y, dz = p.z - s.z;
                    if (dx * dx + dy * dy + dz * dz > s.radius * s.radius) continue;
                    ++covered;
                    const auto* b = lists.indices.data() + first;
                    CHECK_MESSAGE(std::binary_search(b, b + count, std::uint32_t(i)),
                                  "light " << i << " holds point " << n << " but is not in cluster " << c);
                }
            }
            CHECK(checked > 1000);
            CHECK(covered > 100);  // the reference found lights to check
            // Every list is in ascending light order and has no repeats.
            for (std::size_t c = 0; c < lists.first.size(); ++c) {
                const auto* b = lists.indices.data() + lists.first[c];
                for (std::uint32_t k = 1; k < lists.count[c]; ++k) CHECK(b[k - 1] < b[k]);
            }
        }
    }
}

TEST_CASE("clusters: the lists are the same bytes with the pool stopped, inline and with 1, 2 and 8 workers") {
    const View v = make_view(1920, 1080, false);
    const auto spheres = random_spheres(31, 1000, 80.0f, 0.5f, 8.0f);

    struct Mode {
        const char* name;
        bool start;
        jobs::Settings settings;
    };
    std::vector<Mode> modes{{"stopped", false, {}}, {"inline", true, jobs::Settings::inline_jobs()}};
    if (jobs::threads_supported()) {
        modes.push_back({"1 worker", true, jobs::Settings::threads(1)});
        modes.push_back({"2 workers", true, jobs::Settings::threads(2)});
        modes.push_back({"8 workers", true, jobs::Settings::threads(8)});
    }
    ClusterLists reference;
    bool haveReference = false;
    for (const Mode& m : modes) {
        CAPTURE(m.name);
        if (m.start) {
            auto r = jobs::start(m.settings);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
        }
        ClusterLists lists;
        const auto t0 = std::chrono::steady_clock::now();
        build_light_clusters(v.cam, v.grid, spheres, lists);
        const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        if (m.start) jobs::stop();
        // Informational: the cost of the build with 1000 lights (never asserted: it depends on the machine).
        std::printf("[light clusters] 1000 lights, %dx%d clusters x %d slices, %s: %.2f ms, %zu entries\n",
                    v.grid.tilesX, v.grid.tilesY, v.grid.slices, m.name, ms, lists.indices.size());
        CHECK(lists.indices.size() > 1000);
        if (!haveReference) {
            reference = lists;
            haveReference = true;
            continue;
        }
        CHECK(lists.first == reference.first);
        CHECK(lists.count == reference.count);
        CHECK(lists.indices == reference.indices);
        CHECK(lists.lightsAssigned == reference.lightsAssigned);
        CHECK(lists.clippedEntries == reference.clippedEntries);
        CHECK(lists.clippedClusters == reference.clippedClusters);
        CHECK(lists.maxPerCluster == reference.maxPerCluster);
    }
}

TEST_CASE("clusters: a list keeps its first 128 lights, and a view at most 524288 entries; what is lost is counted") {
    const View v = make_view(1280, 720, false);
    // 200 lights that cover the whole view (a huge range at the camera): every cluster wants 200.
    std::vector<LightSphere> spheres(200, LightSphere{0, 0, -20, 500.0f});
    ClusterLists lists;
    build_light_clusters(v.cam, v.grid, spheres, lists);
    const std::size_t clusters = std::size_t(v.grid.clusters());
    // The view cap: 128 entries x clusters is above 524288 for this grid, so the later clusters get less or nothing.
    CHECK(lists.indices.size() <= kMaxClusterIndices);
    CHECK(lists.indices.size() == std::min<std::size_t>(clusters * kMaxLightsPerCluster, kMaxClusterIndices));
    CHECK(lists.maxPerCluster == std::size_t(kMaxLightsPerCluster));
    CHECK(lists.clippedClusters > 0);
    std::size_t kept = 0;
    for (std::size_t c = 0; c < clusters; ++c) {
        CHECK(lists.count[c] <= std::uint32_t(kMaxLightsPerCluster));
        kept += lists.count[c];
        if (lists.count[c] == 0) continue;
        const std::uint32_t* b = lists.indices.data() + lists.first[c];
        for (std::uint32_t k = 0; k < lists.count[c]; ++k) CHECK(b[k] == k);  // the lowest indices survive
    }
    CHECK(kept == lists.indices.size());
    // Every cluster wanted all 200 lights (the sphere holds the camera): what was kept and what was clipped add up to that.
    CHECK(kept + lists.clippedEntries == clusters * 200);
}

TEST_CASE(
    "clusters: at most 32 lights that cover the view give every cluster the lights in table order, like today's loop") {
    const View v = make_view(1280, 720, false);
    std::vector<LightSphere> spheres;
    for (int i = 0; i < 20; ++i) spheres.push_back({float(i) * 0.1f, 0, -30, 2000.0f});
    ClusterLists lists;
    build_light_clusters(v.cam, v.grid, spheres, lists);
    CHECK(lists.clippedEntries == 0);
    for (std::size_t c = 0; c < lists.first.size(); ++c) {
        REQUIRE(lists.count[c] == 20);
        for (std::uint32_t k = 0; k < 20; ++k) CHECK(lists.indices[lists.first[c] + k] == k);
    }
    // select_lights keeps up to 32 lights in the order they had after the sort, drops nothing.
    std::vector<LightData> lights;
    for (int i = 0; i < 20; ++i) {
        LightData l = local_light(float(i), 0, -5, 10.0f);
        l.score = float(20 - i);
        lights.push_back(l);
    }
    CHECK(select_lights(lights, 1024) == 0);
    REQUIRE(lights.size() == 20);
    for (int i = 0; i < 20; ++i) CHECK(lights[std::size_t(i)].pos.x == float(i));
}

TEST_CASE("clusters: select_lights keeps 32 directional lights first and 1024 lights at most") {
    std::vector<LightData> lights;
    for (int i = 0; i < 40; ++i) {
        LightData l = local_light(float(i), 0, 0, 1.0f);
        l.rank = 1;
        l.score = float(i);
        lights.push_back(l);
    }
    for (int i = 0; i < 1100; ++i) {
        LightData l = local_light(float(i), 0, 0, 1.0f);
        l.score = float(i % 50);
        lights.push_back(l);
    }
    const int dropped = select_lights(lights, 1024);
    CHECK(dropped == 8 + (1100 + 32 - 1024));
    CHECK(lights.size() == 1024);
    int directional = 0;
    for (const LightData& l : lights) directional += l.rank < 2 ? 1 : 0;
    CHECK(directional == 32);
    CHECK(lights.front().rank == 1);
    CHECK(lights[32].rank == 2);
}

TEST_CASE("clusters: the data texture holds the light table, the cluster table and the lists in the layout the shader "
          "reads") {
    const View v = make_view(640, 360, false);
    std::vector<LightData> table;
    LightData sun;
    sun.pos = {0.0f, 1.0f, 0.0f, 0.0f};
    sun.color = {2.0f, 1.5f, 1.0f, 0.0f};
    sun.dir = {0, 0, 0, 0};
    sun.rank = 0;
    table.push_back(sun);
    LightData spot = local_light(1.0f, 2.0f, -10.0f, 15.0f);
    spot.color = {0.5f, 0.25f, 0.125f, 2.0f};
    spot.dir = {0.0f, -1.0f, 0.0f, 0.9f};
    spot.cosInner = 0.95f;
    table.push_back(spot);
    table.push_back(local_light(-1.0f, 0.0f, -12.0f, 4.0f));

    std::vector<LightSphere> spheres{{0, 0, 0, 0}, {1.0f, 2.0f, -10.0f, 15.0f}, {-1.0f, 0.0f, -12.0f, 4.0f}};
    ClusterLists lists;
    build_light_clusters(v.cam, v.grid, spheres, lists);
    LightTexture tex;
    pack_light_texture(table, 1, v.cam, &lists, tex);

    CHECK(tex.width == kLightTextureWidth);
    CHECK(tex.height >= 1);
    CHECK((tex.height & (tex.height - 1)) == 0);  // a power of two
    CHECK(tex.texels.size() == std::size_t(tex.width) * std::size_t(tex.height) * 4);
    const std::size_t lightTexels = 3 * kLightTexels;
    const std::size_t clusters = std::size_t(v.grid.clusters());
    CHECK(tex.usedTexels == lightTexels + clusters + (lists.indices.size() + 3) / 4);
    auto texel = [&](std::size_t t, int c) { return tex.texels[t * 4 + std::size_t(c)]; };
    // Light 1: position and range, colour and kind, axis and cosOuter, cosInner.
    CHECK(texel(4, 0) == 1.0f);
    CHECK(texel(4, 1) == 2.0f);
    CHECK(texel(4, 2) == -10.0f);
    CHECK(texel(4, 3) == 15.0f);
    CHECK(texel(5, 0) == 0.5f);
    CHECK(texel(5, 3) == 2.0f);
    CHECK(texel(6, 1) == -1.0f);
    CHECK(texel(6, 3) == 0.9f);
    CHECK(texel(7, 0) == 0.95f);
    // Light 2 keeps the 2.0 sentinel of the default fade at texel 11.
    CHECK(texel(11, 0) == 2.0f);
    // The uniforms say where the tables are.
    CHECK(tex.uniforms.info[0] == float(lightTexels));
    CHECK(tex.uniforms.info[1] == float(kClusterSlices));
    CHECK(tex.uniforms.info[2] == 1.0f);
    CHECK(tex.uniforms.info[3] == float(clusters));
    CHECK(tex.uniforms.grid[0] == float(v.grid.tilesX));
    CHECK(tex.uniforms.grid[1] == float(v.grid.tilesY));
    CHECK(tex.uniforms.grid[3] == v.grid.nearDepth);
    // The cluster table: first slot and count, and the index lists after it, four to a texel.
    const std::size_t clusterBase = lightTexels, indexBase = lightTexels + clusters;
    std::size_t nonEmpty = 0;
    for (std::size_t c = 0; c < clusters; ++c) {
        CHECK(texel(clusterBase + c, 0) == float(lists.first[c]));
        CHECK(texel(clusterBase + c, 1) == float(lists.count[c]));
        for (std::uint32_t k = 0; k < lists.count[c]; ++k) {
            const std::size_t slot = lists.first[c] + k;
            CHECK(texel(indexBase + slot / 4, int(slot % 4)) == float(lists.indices[slot]));
        }
        nonEmpty += lists.count[c] > 0 ? 1 : 0;
    }
    CHECK(nonEmpty > 0);
    // A view of directional lights only: no cluster table, the shader's "no clusters" marker.
    LightTexture none;
    pack_light_texture({sun}, 1, v.cam, nullptr, none);
    CHECK(none.uniforms.info[0] == -1.0f);
    CHECK(none.uniforms.info[2] == 1.0f);
    CHECK(none.usedTexels == std::size_t(kLightTexels));
    CHECK(none.height == 1);
    // Rows are a power of two and cover the texels.
    CHECK(light_texture_rows(1) == 1);
    CHECK(light_texture_rows(1024) == 1);
    CHECK(light_texture_rows(1025) == 2);
    CHECK(light_texture_rows(3 * 1024 + 1) == 4);
}

TEST_CASE("clusters: a contact shadow length is in the y of the light's texel of the shadow region, which exists "
          "without shadow maps") {
    const View v = make_view(640, 360, false);
    LightData sun;
    sun.pos = {0.0f, 1.0f, 0.0f, 0.0f};
    sun.color = {1.0f, 1.0f, 1.0f, 0.0f};
    sun.rank = 0;
    sun.contactLength = 1.25f;
    LightData lamp = local_light(1.0f, 2.0f, -10.0f, 15.0f);  // no length: 0 in its texel
    LightData lamp2 = local_light(-1.0f, 0.0f, -12.0f, 4.0f);
    lamp2.contactLength = 0.5f;
    LightTexture tex;
    pack_light_texture({sun, lamp, lamp2}, 1, v.cam, nullptr, tex);
    REQUIRE(tex.shadowBase >= 0);
    auto texel = [&](long long t, int c) { return tex.texels[std::size_t(t) * 4 + std::size_t(c)]; };
    // One texel per light, in the order of the table: x = -1 (no shadow map), y = the length.
    for (int i = 0; i < 3; ++i) CHECK(texel(tex.shadowBase + i, 0) == -1.0f);
    CHECK(texel(tex.shadowBase + 0, 1) == 1.25f);
    CHECK(texel(tex.shadowBase + 1, 1) == 0.0f);
    CHECK(texel(tex.shadowBase + 2, 1) == 0.5f);
    CHECK(tex.usedTexels >= std::size_t(tex.shadowBase) + 3);
    // No light asks for one and no map exists: no region at all, as before M73.2c.
    sun.contactLength = 0.0f;
    lamp2.contactLength = 0.0f;
    LightTexture plain;
    pack_light_texture({sun, lamp, lamp2}, 1, v.cam, nullptr, plain);
    CHECK(plain.shadowBase < 0);
}
