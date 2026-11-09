// M70.2a: the render work of a frame runs as jobs (render_jobs.h; docs/ARCHITECTURE.md, "Systems that run as jobs").
// Every pass must give the same frame whatever the thread count: these tests draw scenes far above each pass's
// threshold with the pool stopped and in inline mode (each pass one chunk on the calling thread, the reference) and
// with 1, 2 and 8 workers (many chunks, joined in order), and compare the pictures byte for byte, the frame
// statistics, and the vertex streams of the helpers.
#include "test_util.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iterator>
#include <limits>
#include <map>
#include <string>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/core/profiler.h"
#include "fa/scene/animation.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/particles.h"

#include "render_internal.h"
#include "render_jobs.h"

using namespace fa;
using namespace fa::test;

namespace {

// How a test run sets up the job system: stopped (jobs run inline on the caller), inline mode, or N workers.
struct Mode {
    const char* name;
    bool start;
    jobs::Settings settings;
};

std::vector<Mode> modes() {
    std::vector<Mode> m{{"stopped", false, {}}, {"inline", true, jobs::Settings::inline_jobs()}};
    if (jobs::threads_supported()) {
        m.push_back({"1 worker", true, jobs::Settings::threads(1)});
        m.push_back({"2 workers", true, jobs::Settings::threads(2)});
        m.push_back({"8 workers", true, jobs::Settings::threads(8)});
    }
    return m;
}

struct PoolScope {
    bool started = false;
    explicit PoolScope(const Mode& m) {
        if (!m.start) return;
        auto r = jobs::start(m.settings);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
        started = true;
    }
    ~PoolScope() {
        if (started) jobs::stop();
    }
};

// A deterministic spread of numbers without a generator: item i of n, in [0, 1).
float frac(int i, int salt) {
    const unsigned h = unsigned(i) * 2654435761u + unsigned(salt) * 40503u;
    return float((h >> 8) & 0xffff) / 65536.0f;
}

std::string write_checker(const std::string& name, int cell, Color a, Color b) {
    Image img;
    img.width = 32;
    img.height = 32;
    img.rgba.resize(std::size_t(32) * 32 * 4);
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x) img.set_pixel(x, y, (((x / cell) + (y / cell)) % 2 == 0) ? a : b);
    const std::string path = "assets/" + name;
    REQUIRE(save_png(img, path).ok());
    return path;
}

// 2D: thousands of sprites of every kind the sprite pass draws (textured, solid, 9-slice, grid meshes with offsets
// and colours, skinned, lit, additive and multiply, screen space, on many layers), a tilemap with ~57600 cells in
// view, and emitters with thousands of particles, world and screen space, some with trails.
void build_2d(World& w) {
    const std::string checker = write_checker("jobs_checker.png", 4, Color::hex(0xffffff), Color::hex(0x404040));
    const std::string tiles = write_checker("jobs_tiles.png", 8, Color::hex(0x3b7d3b), Color::hex(0x8b5a2b));
    w.add<Camera>(make(w, "cam")).clearColor = Color::hex(0x101018);
    {
        Entity light = make(w, "light", {20, 10, 0});
        auto& l = w.add<Light2D>(light);
        l.radius = 260;
        l.color = Color::hex(0xffe0b0);
    }
    w.settings().ambientLight = Color{0.5f, 0.5f, 0.6f, 1};
    {
        Entity map = make(w, "map", {-200, 100, 0});
        auto& tm = w.add<Tilemap>(map);
        tm.tileset = tiles;
        tm.tileSize = {1, 1};
        tm.columns = 4;
        tm.width = 400;
        tm.height = 200;
        tm.layer = -20;
        Json flat = Json::array();
        for (int i = 0; i < 400 * 200; ++i) flat.push_back(i % 11 == 0 ? -1 : (i / 3 + i / 400) % 16);
        tm.tiles = flat;
    }
    for (int i = 0; i < 3000; ++i) {
        Entity e = make(w, "s", {frac(i, 1) * 340 - 170, frac(i, 2) * 200 - 100, 0});
        w.get<Transform>(e)->rotation.z = frac(i, 3) * 360;
        auto& s = w.add<Sprite>(e);
        s.size = {4 + frac(i, 4) * 14, 4 + frac(i, 5) * 14};
        s.color = Color{0.3f + frac(i, 6) * 0.7f, 0.3f + frac(i, 7) * 0.7f, 0.3f + frac(i, 8) * 0.7f, 0.5f + frac(i, 9) * 0.5f};
        s.layer = i % 7 - 3;
        const int kind = i % 10;
        if (kind != 0) s.texture = checker;
        if (kind == 2) s.slice = {4, 4, 4, 4};
        if (kind == 3) s.lit = true;
        if (kind == 4) s.blend = BlendMode::Additive;
        if (kind == 5) s.blend = BlendMode::Multiply;
        if (kind == 6) {
            s.meshColumns = 3;
            s.meshRows = 2;
            Json offsets = Json::array(), colors = Json::array();
            for (int v = 0; v < 12; ++v) {
                offsets.push_back(frac(i + v, 10) * 2 - 1);
                offsets.push_back(frac(i + v, 11) * 2 - 1);
                for (int k = 0; k < 4; ++k) colors.push_back(0.5 + frac(i + v + k, 12) * 0.5);
            }
            s.vertexOffsets = offsets;
            s.vertexColors = colors;
        }
        if (kind == 7) {
            s.space = RenderSpace::Screen;
            w.get<Transform>(e)->position = {frac(i, 13) * 320, frac(i, 14) * 180, 0};
        }
        if (kind == 8) s.flipX = true;
    }
    // Skinned sprites: an arm of two bones each, the second bent.
    for (int i = 0; i < 40; ++i) {
        Entity arm = make(w, "arm", {frac(i, 20) * 300 - 150, frac(i, 21) * 160 - 80, 0});
        auto& s = w.add<Sprite>(arm);
        s.size = {40, 10};
        s.meshColumns = 8;
        s.meshRows = 2;
        s.color = Color::hex(0xff8040);
        s.layer = 3;
        Entity b0 = w.create("b0");
        w.add<Bone2D>(b0).length = 20;
        w.set_parent(b0, arm);
        w.get<Transform>(b0)->position = {-20, 0, 0};
        Entity b1 = w.create("b1");
        w.add<Bone2D>(b1).length = 20;
        w.set_parent(b1, b0);
        w.get<Transform>(b1)->position = {20, 0, 0};
        w.get<Transform>(b1)->rotation.z = frac(i, 22) * 120 - 60;
        Json bones = Json::array();
        bones.push_back(w.id_of(b0));
        bones.push_back(w.id_of(b1));
        w.add<SpriteSkin>(arm).bones = bones;
    }
    for (int i = 0; i < 24; ++i) {
        Entity e = make(w, "fx", {frac(i, 30) * 300 - 150, frac(i, 31) * 160 - 80, 0});
        auto& p = w.add<ParticleEmitter>(e);
        p.rate = 120;
        p.burst = 150;
        p.maxParticles = 400;
        p.seed = 7 + i;
        p.lifetime = 1.5f;
        p.speed = 20 + frac(i, 32) * 40;
        p.startSize = 3;
        if (i % 3 == 0) p.texture = checker;
        if (i % 4 == 1) p.trail = ParticleTrail::Particle;
        if (i % 5 == 2) {
            p.space = RenderSpace::Screen;
            w.get<Transform>(e)->position = {frac(i, 33) * 320, frac(i, 34) * 180, 0};
        }
        if (i % 6 == 3) p.blend = BlendMode::Additive;
    }
}

// 3D: 600 meshes of four shapes and many colours (opaque and blended), a shadow-casting sun, meshes behind the
// camera (culled from the main pass, still casting), and 220 skinned rigs whose poses the animators build as jobs.
void build_3d(World& w) {
    {
        std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/tests/data/skinned_two_bone.gltf", std::ios::binary);
        std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        REQUIRE(!text.empty());
        REQUIRE(fs::write_text("assets/jobs_rig.gltf", text).ok());
    }
    Entity cam = make(w, "cam", {0, 9, 16});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.get<Transform>(cam)->rotation = {-30, 0, 0};
    Entity sun = make(w, "sun", {0, 10, 0});
    w.get<Transform>(sun)->rotation = {-55, 30, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = true;
    {
        Entity floor = make(w, "floor", {0, -0.5f, 0});
        w.get<Transform>(floor)->scale = {40, 1, 40};
        auto& m = w.add<MeshRenderer>(floor);
        m.mesh = "plane";
        m.color = Color::hex(0x808890);
    }
    const char* shapes[] = {"cube", "sphere", "cylinder", "cone"};
    for (int i = 0; i < 600; ++i) {
        const bool behind = i % 9 == 0;
        Entity e = make(w, "m", {frac(i, 40) * 30 - 15, frac(i, 41) * 3, behind ? 20 + frac(i, 42) * 10 : frac(i, 42) * 24 - 16});
        w.get<Transform>(e)->rotation = {frac(i, 43) * 90, frac(i, 44) * 360, 0};
        w.get<Transform>(e)->scale = {0.3f + frac(i, 45) * 0.5f, 0.3f + frac(i, 46) * 0.5f, 0.3f + frac(i, 47) * 0.5f};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = shapes[i % 4];
        m.color = Color{float(i % 5) / 4.0f, float(i % 3) / 2.0f, float(i % 7) / 6.0f, i % 8 == 0 ? 0.5f : 1.0f};
        m.castShadows = i % 10 != 1;
    }
    for (int i = 0; i < 220; ++i) {
        Entity e = make(w, "rig", {frac(i, 50) * 24 - 12, 0, frac(i, 51) * 16 - 10});
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "assets/jobs_rig.gltf";
        m.color = Color{1, 0.4f + frac(i, 52) * 0.6f, 0.3f, 1};
        auto& a = w.add<Animator>(e);
        a.clip = i % 2 ? "Bend" : "Slide";
        a.speed = 0.5f + frac(i, 53);
    }
}

struct Frames {
    std::vector<std::vector<std::uint8_t>> pictures;
    std::vector<std::string> stats;
    // Chunks of each render / animation job over every lane, summed over the frames. The profiler records every chunk
    // once, on the lane that ran it, so the sums depend only on how the passes split their items, never on which
    // thread got there first.
    std::map<std::string, int> chunks;
    bool workerRan = false;  // a worker thread ran at least one of them (depends on timing: only reported)
};

// Draws `frames` frames of a fresh scene with the job system set up as `m`.
template <class Build>
Frames draw(const Mode& m, Build build, int frames, bool animate) {
    Gfx& g = gfx();
    REQUIRE(!jobs::running());
    PoolScope pool(m);
    g.renderer.clear_asset_cache();  // no emitter state, skin binding or texture of another run
    World w;
    build(w);
    Profiler& p = Profiler::get();
    p.set_enabled(true);
    Frames out;
    for (int f = 0; f < frames; ++f) {
        if (animate) update_animators(w, 1.0f / 30.0f);
        p.begin_frame();
        Image img = g.render(w, 1.0f / 30.0f);
        p.end_frame();
        jobs::end_frame();
        const ProfFrame pf = p.last();
        for (std::size_t lane = 0; lane < pf.lanes.size(); ++lane)
            for (const ProfJobSample& s : pf.lanes[lane].samples) {
                if (s.name.rfind("render.", 0) != 0 && s.name.rfind("scene.", 0) != 0) continue;
                out.chunks[s.name] += s.count;
                if (lane > 0 && s.count > 0) out.workerRan = true;
            }
        Json st = g.renderer.stats().to_json();
        st.erase("cpuMs");
        out.pictures.push_back(std::move(img.rgba));
        out.stats.push_back(st.dump());
    }
    p.set_enabled(false);
    g.renderer.clear_asset_cache();
    return out;
}

std::string describe(const std::map<std::string, int>& chunks) {
    std::string out;
    for (const auto& [name, n] : chunks) out += name + " " + std::to_string(n) + "; ";
    return out;
}

// Draws the scene in every mode and compares each with the pool stopped. With workers, each job of `split` must
// have been cut into more than one chunk per frame, and every worker count must give the same chunks.
template <class Build>
void check_same_frames(Build build, int frames, bool animate, const std::vector<std::string>& split,
                       bool still = false) {
    const std::vector<Mode> ms = modes();
    const Frames base = draw(ms[0], build, frames, animate);
    CHECK_MESSAGE(base.chunks.empty(), describe(base.chunks));  // no worker: every pass is one chunk, no job at all
    const std::map<std::string, int>* firstChunks = nullptr;
    std::vector<Frames> runs;
    runs.reserve(ms.size());
    REQUIRE(base.pictures.size() == std::size_t(frames));
    if (!still) CHECK(base.pictures.front() != base.pictures.back());  // the frames do change (particles, poses)
    for (std::size_t i = 1; i < ms.size(); ++i) {
        INFO("jobs: " << std::string(ms[i].name));
        runs.push_back(draw(ms[i], build, frames, animate));
        const Frames& run = runs.back();
        REQUIRE(run.pictures.size() == base.pictures.size());
        for (int f = 0; f < frames; ++f) {
            INFO("frame " << f);
            CHECK(run.stats[std::size_t(f)] == base.stats[std::size_t(f)]);
            CHECK(run.pictures[std::size_t(f)] == base.pictures[std::size_t(f)]);
        }
        if (ms[i].settings.mode != jobs::Settings::Mode::Count) {
            CHECK_MESSAGE(run.chunks.empty(), describe(run.chunks));  // inline: no worker, one chunk per pass
            continue;
        }
        INFO("chunks: " << describe(run.chunks));
        for (const std::string& name : split) {
            INFO("job " << name);
            const auto it = run.chunks.find(name);
            REQUIRE(it != run.chunks.end());
            CHECK(it->second >= 2 * frames);
        }
        if (firstChunks) CHECK(run.chunks == *firstChunks);
        else firstChunks = &run.chunks;
        // Whether a worker took a chunk before the waiting thread ran them all depends on timing: only reported.
        if (!run.workerRan)
            MESSAGE("jobs: " << std::string(ms[i].name) << ": every chunk ran on the main thread this time");
    }
}

}  // namespace

TEST_CASE("render jobs: a big 2D frame (sprites, meshes, skins, tilemap, particles) is the same with 0, 1, 2, 8 threads and inline") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    check_same_frames(build_2d, 4, false, {"render.gather_sprites", "render.gather_tilemap", "render.particles",
                                          "render.gather_particles", "render.flatten_quads"});
    // The scene is far above every 2D threshold, so these frames were split into many chunks.
    World w;
    build_2d(w);
    g.render(w, 1.0f / 30.0f);
    const RenderStats s = g.renderer.stats();
    CHECK(s.sprites >= 3000);
    CHECK(s.particles >= 2048);
    g.renderer.clear_asset_cache();
}

TEST_CASE("render jobs: a big 3D frame (meshes, blending, culling, shadows, skinned rigs) is the same with 0, 1, 2, 8 threads and inline") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    check_same_frames(build_3d, 3, true, {"render.mesh_matrices", "render.mesh_cull", "render.shadow_bounds",
                                         "render.shadow_cull"});
    World w;
    build_3d(w);
    update_animators(w, 1.0f / 30.0f);
    g.render(w);
    const RenderStats s = g.renderer.stats();
    CHECK(s.meshes + s.meshesCulled >= 800);
    CHECK(s.meshesCulled > 0);
    CHECK(s.shadowCasters > s.meshes / 2);
    g.renderer.clear_asset_cache();
}

namespace {

// NaN sort keys: sprites and meshes with a NaN position (a NaN y sort key, a NaN distance) and meshes with a NaN
// colour, among enough items for the sorts to run as jobs. A NaN that broke the sorts' strict weak order would make
// the chunked sort and std::stable_sort disagree, and the frame would depend on the thread count.
void build_nan(World& w) {
    const float nan = std::numeric_limits<float>::quiet_NaN();
    w.add<Camera>(make(w, "cam")).clearColor = Color::hex(0x101018);
    for (int i = 0; i < 5000; ++i) {
        Entity e = make(w, "s", {frac(i, 70) * 300 - 150, frac(i, 71) * 160 - 80, 0});
        if (i % 37 == 5) w.get<Transform>(e)->position.y = nan;
        if (i % 53 == 7) w.get<Transform>(e)->position.x = nan;
        auto& s = w.add<Sprite>(e);
        s.size = {6 + frac(i, 72) * 20, 6 + frac(i, 73) * 20};
        s.color = Color{frac(i, 74), frac(i, 75), frac(i, 76), 0.6f + frac(i, 77) * 0.4f};
    }
    Entity cam3 = make(w, "cam3d", {0, 6, 14});
    auto& c = w.add<Camera>(cam3);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.depth = 1;
    c.clear = false;  // drawn over the first camera's picture
    w.get<Transform>(cam3)->rotation = {-20, 0, 0};
    const char* shapes[] = {"cube", "sphere"};
    for (int i = 0; i < 2400; ++i) {
        const bool blended = i % 2 == 1;
        Entity e = make(w, "m", {frac(i, 80) * 20 - 10, frac(i, 81) * 6 - 2, frac(i, 82) * 12 - 8});
        if (blended && i % 41 == 3) w.get<Transform>(e)->position.z = nan;
        w.get<Transform>(e)->scale = {0.6f, 0.6f, 0.6f};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = shapes[(i / 2) % 2];
        m.color = Color{float(i % 5) / 4.0f, float(i % 3) / 2.0f, float(i % 7) / 6.0f, blended ? 0.5f : 1.0f};
        if (!blended && i % 43 == 4) m.color.g = nan;
        m.castShadows = false;
    }
}

}  // namespace

TEST_CASE("render jobs: NaN sort keys (positions, colours) give the same frame with 0, 1, 2, 8 threads and inline") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    check_same_frames(build_nan, 2, false, {"render.sort_quads", "render.sort_blended", "render.sort_meshes"}, true);
}

TEST_CASE("render jobs: the chunked stable sort gives std::stable_sort's order, ties included") {
    struct Item {
        int key;
        int original;
    };
    auto less = [](const Item& a, const Item& b) { return a.key < b.key; };
    for (const Mode& m : modes()) {
        INFO("jobs: " << std::string(m.name));
        PoolScope pool(m);
        for (std::size_t n : {std::size_t(0), std::size_t(1), std::size_t(7), std::size_t(64), std::size_t(1000), std::size_t(1023),
                              std::size_t(1024), std::size_t(1025), std::size_t(5000), std::size_t(33333)}) {
            INFO("n = " << n);
            std::vector<Item> v(n);
            for (std::size_t i = 0; i < n; ++i) v[i] = {int(frac(int(i), 60) * 50), int(i)};  // many equal keys
            std::vector<Item> ref = v;
            std::stable_sort(ref.begin(), ref.end(), less);
            render::rjobs::stable_sort("test.sort", v, less, 100, 64);
            bool same = v.size() == ref.size();
            for (std::size_t i = 0; same && i < n; ++i) same = v[i].key == ref[i].key && v[i].original == ref[i].original;
            CHECK(same);
        }
    }
}

TEST_CASE("render jobs: splits and weighted ranges depend only on the counts, and are one chunk with no worker") {
    using render::rjobs::split;
    using render::rjobs::weighted_ranges;
    const std::vector<std::size_t> weights{3, 3000, 16, 16, 16, 500, 500, 2, 1};
    REQUIRE(!jobs::running());
    // With nobody to share them with, every pass is one chunk on the calling thread.
    CHECK(split(1000, 64, 100).chunks == 1);
    CHECK(split(1000, 64, 100).grain == 1000);
    CHECK(weighted_ranges(weights, 1000, 2048).size() == 1);
    if (!jobs::threads_supported()) return;
    for (int workers : {1, 2, 8}) {
        INFO(workers << " workers");
        PoolScope pool(Mode{"workers", true, jobs::Settings::threads(workers)});
        CHECK(split(0, 64, 0).chunks == 0);
        CHECK(split(100, 64, 1000).chunks == 1);  // under the threshold: one chunk with everything
        CHECK(split(100, 64, 1000).grain == 100);
        CHECK(split(1000, 64, 1000).chunks == 16);
        CHECK(split(1000, 64, 1000).grain == 64);
        CHECK(split(1000, 0, 0).chunks == 1);
        CHECK(split(50, 64, 0).chunks == 1);
        const auto r = weighted_ranges(weights, 1000, 2048);
        const std::vector<std::pair<std::size_t, std::size_t>> want{{0, 2}, {2, 7}, {7, 9}};
        CHECK(r == want);
        // Under the total, one range; no items, none.
        const auto one = weighted_ranges(weights, 1000, 100000);
        REQUIRE(one.size() == 1);
        CHECK(one[0] == std::pair<std::size_t, std::size_t>{0, weights.size()});
        CHECK(weighted_ranges({}, 1000, 0).empty());
    }
}

TEST_CASE("render jobs: parts of a QuadList appended in order give the stream of one list") {
    using namespace fa::render;
    TextureAsset texA, texB;
    auto vert = [](float x, float y, int i) {
        const std::uint32_t c = 0xff000000u | (std::uint32_t(frac(i, 1) * 255) << 16) | (std::uint32_t(frac(i, 2) * 255) << 8);
        return Vertex2D{x, y, 0, frac(i, 3), frac(i, 4), c, float(kModeTextured), 0};
    };
    auto quad = [&](QuadList& l, int i) {
        const float x = float(i % 300), y = frac(i, 9) * 100;
        l.quad(vert(x, y, i), vert(x, y + 1, i), vert(x + 1, y + 1, i), vert(x + 1, y, i));
    };
    auto item = [&](QuadList& l, int i) {
        l.begin_item(i % 5, frac(i, 9) * 100, i % 3 ? &texA : &texB, SamplerKind::Nearest, i % 4 ? BlendMode::Alpha : BlendMode::Additive);
        quad(l, i);
        if (i % 7 == 0) quad(l, i + 1);
        l.end_item();
    };
    const int n = 20000;  // above the sort and copy thresholds of flatten()
    QuadList whole;
    for (int i = 0; i < n; ++i) item(whole, i);
    // One big item, like a tilemap's, whose quads come in bands.
    whole.begin_item(2, 50, &texA, SamplerKind::Nearest);
    for (int i = 0; i < 9000; ++i) quad(whole, i);
    whole.end_item();
    std::vector<Vertex2D> refVerts;
    std::vector<QuadBatch> refBatches;
    whole.flatten(refVerts, refBatches);
    REQUIRE(refBatches.size() > 100);

    for (const Mode& m : modes()) {
        INFO("jobs: " << std::string(m.name));
        PoolScope pool(m);
        QuadList joined;
        for (int part = 0; part < 7; ++part) {
            QuadList p;
            for (int i = part * n / 7; i < (part + 1) * n / 7; ++i) item(p, i);
            joined.append(p);
            CHECK(p.empty());
        }
        joined.begin_item(2, 50, &texA, SamplerKind::Nearest);
        for (int band = 0; band < 3; ++band) {
            QuadList b;
            b.begin_item(2, 50, &texA, SamplerKind::Nearest);
            for (int i = band * 3000; i < (band + 1) * 3000; ++i) quad(b, i);
            joined.add_quads_of(b);
        }
        joined.end_item();
        std::vector<Vertex2D> verts;
        std::vector<QuadBatch> batches;
        joined.flatten(verts, batches);
        REQUIRE(verts.size() == refVerts.size());
        CHECK(std::memcmp(verts.data(), refVerts.data(), verts.size() * sizeof(Vertex2D)) == 0);
        REQUIRE(batches.size() == refBatches.size());
        bool same = true;
        for (std::size_t i = 0; i < batches.size(); ++i)
            same = same && batches[i].firstQuad == refBatches[i].firstQuad && batches[i].quadCount == refBatches[i].quadCount &&
                   batches[i].tex == refBatches[i].tex && batches[i].blend == refBatches[i].blend;
        CHECK(same);
    }
}
