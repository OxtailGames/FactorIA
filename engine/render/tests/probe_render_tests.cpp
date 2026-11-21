// M73-P3b: the reflection probes on the GPU (docs/design/ARCHITECTURE_PROBES.md). A colour room around the probe (one unlit wall of its own
// colour in each of the six directions, and two patches on the +X wall that are not symmetric) is captured:
//   - by the synchronous capture (Renderer::probe_capture, what probe.bake runs) and read back as a page of octahedral texels;
//   - by the renderer's frames (the realtime probe's tile of the atlas), read back through the test hooks;
//   - from a baked page (the manifest and the .hdr written here the way probe.bake writes them), with a hot reload.
// The colour of a texel is read by DIRECTION through oct_encode (probe.h), so a capture that is mirrored, turned or flipped fails here.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "fa/core/engine_version.h"
#include "fa/core/image_float.h"
#include "fa/render/probe.h"
#include "fa/scene/components.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

struct Rgb {
    float r = 0, g = 0, b = 0;
};

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
    }
};

// The next renderers made are RGBA8 ones until this goes out of scope.
struct ForceRgba8 {
    ForceRgba8() { renderer_probe_force_rgba8(true); }
    ~ForceRgba8() { renderer_probe_force_rgba8(false); }
};

void add_box(World& w, const char* name, Vec3 pos, Vec3 scale, Color emissive) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color{0, 0, 0, 1};
    m.unlit = true;
    m.emissive = emissive;
    m.castShadows = false;
}

// The room: walls 6 m apart, a patch of white and one of black on the +X wall, each off the axis, one toward +Y and one toward +Z.
constexpr Vec3 kPatchWhite{2.7f, 1.2f, 0.0f};
constexpr Vec3 kPatchBlack{2.7f, 0.0f, 1.2f};

Entity build_room(World& w, ProbeMode mode, ProbeUpdate update) {
    Entity cam = make(w, "cam", {0, 0, 0});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0, 0, 0, 1};
    w.settings().horizonColor = Color{0, 0, 0, 1};
    const Vec3 wide{6.4f, 6.4f, 0.2f};
    add_box(w, "px", {3, 0, 0}, {0.2f, 6.4f, 6.4f}, Color{1, 0, 0, 1});
    add_box(w, "nx", {-3, 0, 0}, {0.2f, 6.4f, 6.4f}, Color{0, 1, 1, 1});
    add_box(w, "py", {0, 3, 0}, {6.4f, 0.2f, 6.4f}, Color{0, 1, 0, 1});
    add_box(w, "ny", {0, -3, 0}, {6.4f, 0.2f, 6.4f}, Color{1, 0, 1, 1});
    add_box(w, "pz", {0, 0, 3}, wide, Color{0, 0, 1, 1});
    add_box(w, "nz", {0, 0, -3}, wide, Color{1, 1, 0, 1});
    add_box(w, "white", kPatchWhite, {0.2f, 0.4f, 0.4f}, Color{1, 1, 1, 1});
    add_box(w, "black", kPatchBlack, {0.2f, 0.4f, 0.4f}, Color{0, 0, 0, 1});
    Entity probe = make(w, "probe", {0, 0, 0});
    auto& rp = w.add<ReflectionProbe>(probe);
    rp.mode = mode;
    rp.update = update;
    rp.resolution = 128;
    rp.boxSize = {6, 6, 6};
    rp.clear = ProbeClear::Color;
    rp.clearColor = Color{0, 0, 0, 1};
    return probe;
}

// The colour at direction d of a level-0 image of `size` texels: `stride` floats per texel, `rowWidth` texels per row, interior origin
// (x0, y0).
Rgb sample(const std::vector<float>& px, int stride, int rowWidth, int x0, int y0, int size, Vec3 d) {
    const Vec2 e = oct_encode(d);
    const int x = std::clamp(int((e.x * 0.5f + 0.5f) * float(size)), 0, size - 1);
    const int y = std::clamp(int((e.y * 0.5f + 0.5f) * float(size)), 0, size - 1);
    const std::size_t i = (std::size_t(y0 + y) * std::size_t(rowWidth) + std::size_t(x0 + x)) * std::size_t(stride);
    return {px[i], px[i + 1], px[i + 2]};
}

struct Expect {
    Vec3 dir;
    Rgb want;
    const char* what;
};

std::vector<Expect> expectations() {
    return {
        {{1, 0, 0}, {1, 0, 0}, "+X red"},
        {{-1, 0, 0}, {0, 1, 1}, "-X cyan"},
        {{0, 1, 0}, {0, 1, 0}, "+Y green"},
        {{0, -1, 0}, {1, 0, 1}, "-Y magenta"},
        {{0, 0, 1}, {0, 0, 1}, "+Z blue"},
        {{0, 0, -1}, {1, 1, 0}, "-Z yellow"},
        {kPatchWhite, {1, 1, 1}, "the white patch (+X wall, up)"},
        {kPatchBlack, {0, 0, 0}, "the black patch (+X wall, +Z)"},
        // Where a mirrored capture would see the patches: the red wall.
        {{kPatchWhite.x, -kPatchWhite.y, kPatchWhite.z}, {1, 0, 0}, "+X wall below the white patch"},
        {{kPatchBlack.x, kPatchBlack.y, -kPatchBlack.z}, {1, 0, 0}, "+X wall at -Z of the black patch"},
    };
}

void check_colors(const std::vector<float>& px, int stride, int rowWidth, int x0, int y0, int size, float tolerance) {
    for (const Expect& e : expectations()) {
        const Rgb got = sample(px, stride, rowWidth, x0, y0, size, normalize(e.dir));
        INFO(e.what << ": got " << got.r << " " << got.g << " " << got.b << ", want " << e.want.r << " " << e.want.g
                    << " " << e.want.b);
        CHECK(std::fabs(got.r - e.want.r) < tolerance);
        CHECK(std::fabs(got.g - e.want.g) < tolerance);
        CHECK(std::fabs(got.b - e.want.b) < tolerance);
    }
}

bool half_float_probes(Gfx& g) { return g.renderer.supports("floatTargets"); }

Json report_of(Own& o) { return o.r.probe_report(); }

const Json* probe_json(const Json& report, const std::string& name) {
    if (!report.contains("probes")) return nullptr;
    for (const Json& p : report["probes"])
        if (p.value("entity", std::string()) == name) return &p;
    return nullptr;
}

// The report's entry of the probe (the report names an entity by its id in the scene); fails the test when it is not listed.
Json probe_of(Own& o, World& w, Entity probe) {
    const Json report = o.r.probe_report();
    const Json* p = probe_json(report, w.id_of(probe));
    INFO("report: " << report.dump(2));
    REQUIRE(p != nullptr);
    return *p;
}

// The manifest and the page of `page` written into the project the way probe.bake writes them (the page first, then the manifest).
std::string write_baked(const Renderer::ProbePage& page, const std::string& stem, float scale) {
    ImageF img;
    img.width = page.width;
    img.height = page.height;
    img.channels = 3;
    img.data = page.rgb;
    for (float& v : img.data) v *= scale;
    const std::vector<std::uint8_t> bytes = encode_hdr(img);
    ProbeManifest m;
    m.resolution = page.resolution;
    m.levels = probe_levels(page.resolution);
    m.hash = probe_hash_hex(bytes);
    m.page = "assets/" + stem + ".probe." + m.hash + ".hdr";
    m.entity = "probe";
    for (int k = 0; k < kProbeShCoefficients; ++k)
        for (int c = 0; c < 3; ++c) m.sh[k][c] = page.sh[k][c] * scale;
    REQUIRE(fs::write_bytes(m.page, bytes.data(), bytes.size()).ok());
    const std::string path = "assets/" + stem + ".probe.json";
    REQUIRE(fs::write_text(path, probe_manifest_to_json(m).dump(2)).ok());
    return path;
}

}  // namespace

TEST_CASE("probe capture: the synchronous capture of a colour room is right in all six directions and not mirrored") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Baked, ProbeUpdate::TimeSliced);
    Renderer::ProbePage page;
    std::string error;
    const bool ok = o.r.probe_capture(w, probe, page, &error);
    INFO("error: " << error);
    REQUIRE(ok);
    CHECK(page.resolution == 128);
    CHECK(page.width == probe_page_width(128));
    CHECK(page.height == probe_page_height(128));
    REQUIRE(page.rgb.size() == std::size_t(page.width) * std::size_t(page.height) * 3);
    check_colors(page.rgb, 3, page.width, kProbeBorder, kProbeBorder, 128, 0.08f);

    // The nine coefficients: finite, every colour channel is lit by at least one wall, and the red channel is brighter toward +X than -X.
    ShL2 sh;
    for (int k = 0; k < 9; ++k) {
        sh.c[k] = Vec3{page.sh[k][0], page.sh[k][1], page.sh[k][2]};
        CHECK(std::isfinite(page.sh[k][0]));
        CHECK(std::isfinite(page.sh[k][1]));
        CHECK(std::isfinite(page.sh[k][2]));
    }
    CHECK(sh.c[0].x > 0.05f);
    CHECK(sh.c[0].y > 0.05f);
    CHECK(sh.c[0].z > 0.05f);
    CHECK(sh_irradiance(sh, {1, 0, 0}).x > sh_irradiance(sh, {-1, 0, 0}).x);
    CHECK(sh_irradiance(sh, {-1, 0, 0}).y > sh_irradiance(sh, {1, 0, 0}).y);  // cyan on the -X wall
    CHECK(sh_irradiance(sh, {0, 0, 1}).z > sh_irradiance(sh, {0, 0, -1}).z);

    // The GPU's projection of the 16 x 16 image is the CPU's projection of level 0 up to what the smaller image loses.
    ImageF img;
    img.width = page.width;
    img.height = page.height;
    img.channels = 3;
    img.data = page.rgb;
    const ShL2 cpu = probe_sh_from_page(img, 128);
    for (int k = 0; k < 9; ++k) {
        INFO("coefficient " << k);
        CHECK(std::fabs(cpu.c[k].x - sh.c[k].x) < 0.08f);
        CHECK(std::fabs(cpu.c[k].y - sh.c[k].y) < 0.08f);
        CHECK(std::fabs(cpu.c[k].z - sh.c[k].z) < 0.08f);
    }

    // Twice the same: a capture is deterministic.
    Renderer::ProbePage again;
    REQUIRE(o.r.probe_capture(w, probe, again, &error));
    CHECK(again.rgb == page.rgb);
    CHECK(std::memcmp(again.sh, page.sh, sizeof(page.sh)) == 0);
}

TEST_CASE("probe capture: the rough levels of the page are blurrier than level 0 and keep the light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Baked, ProbeUpdate::TimeSliced);
    Renderer::ProbePage page;
    std::string error;
    REQUIRE(o.r.probe_capture(w, probe, page, &error));
    const ProbeLayout lay = probe_layout(128);
    REQUIRE(lay.levels == 5);
    // The smoothest level sees the room's light mixed: toward +X it is still redder than toward -X, but no longer pure red.
    const int last = lay.levels - 1;
    const int size = lay.levelSize[last];
    const int x0 = lay.levelX[last] + kProbeBorder, y0 = lay.levelY[last] + kProbeBorder;
    const Rgb px = sample(page.rgb, 3, page.width, x0, y0, size, {1, 0, 0});
    const Rgb nx = sample(page.rgb, 3, page.width, x0, y0, size, {-1, 0, 0});
    CHECK(px.r > nx.r);
    CHECK(px.g > 0.05f);  // pure red would be 0
    CHECK(nx.r > 0.05f);  // pure cyan would be 0
    // A level never holds more light than the brightest thing in the room (white = 1) and never a NaN.
    for (float v : page.rgb) {
        CHECK(std::isfinite(v));
        CHECK(v >= 0.0f);
        CHECK(v < 1.5f);
    }
}

TEST_CASE("realtime probe: the atlas tile holds the same capture as the synchronous one, and the report names it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::EveryFrame);
    o.r.probe_set_budget(12);
    for (int i = 0; i < 3; ++i) o.frame(w);
    const Json report = report_of(o);
    INFO("report: " << report.dump(2));
    REQUIRE(report.contains("probes"));
    const Json* p = probe_json(report, w.id_of(probe));
    REQUIRE(p != nullptr);
    CHECK((*p)["state"] == "ready");
    CHECK((*p)["mode"] == "realtime");
    CHECK((*p)["captures"].get<int>() >= 1);
    CHECK(report["atlas"]["format"] == "RGBA16F");
    CHECK(report["atlas"]["size"] == kProbeAtlasSize);
    CHECK(report["atlas"]["tiles"].get<int>() >= 1);
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    CHECK(tile.resolution == 128);
    CHECK(tile.x >= 0);
    CHECK(tile.y >= 0);

    std::vector<float> px;
    std::string error;
    const bool read =
        renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, px, &error);
    INFO("read error: " << error);
    REQUIRE(read);
    REQUIRE(px.size() == std::size_t(128) * 128 * 4);
    check_colors(px, 4, 128, 0, 0, 128, 0.08f);

    // The SH row of the tile: coefficient 0 of the capture.
    const ProbeLayout lay = probe_layout(128);
    std::vector<float> shRow;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x, tile.y + lay.shY, kProbeShCoefficients, 1, shRow, &error));
    Renderer::ProbePage page;
    REQUIRE(o.r.probe_capture(w, probe, page, &error));
    for (int c = 0; c < 3; ++c) CHECK(std::fabs(shRow[std::size_t(c)] - page.sh[0][c]) < 0.05f);
    // What the synchronous capture drew did not disturb the atlas.
    std::vector<float> after;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, after, &error));
    CHECK(after == px);
}

TEST_CASE("realtime probe: a probe whose tile was wiped by a new atlas is not sampled until it is captured again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::TimeSliced);
    o.r.probe_set_budget(1);  // one face a frame: six frames a capture
    int frames = 0;
    while (!renderer_probe_tile_valid(o.r, probe.bits()) && frames++ < 40) o.frame(w);
    REQUIRE(renderer_probe_tile_valid(o.r, probe.bits()));
    o.frame(w);
    CHECK(renderer_probe_volume_count(o.r) == 1);

    // A RealtimeGI makes the atlas taller: it is made again and empty.
    Entity gie = make(w, "gi", {20, 0, 0});
    auto& gi = w.add<RealtimeGI>(gie);
    gi.size = {2, 0, 2};
    gi.spacing = 2.0f;
    gi.resolution = 16;
    o.frame(w);
    CHECK_FALSE(renderer_probe_tile_valid(o.r, probe.bits()));
    o.frame(w);
    CHECK(renderer_probe_volume_count(o.r) == 0);  // absent from the volumes while its tile is empty
    frames = 0;
    while (!renderer_probe_tile_valid(o.r, probe.bits()) && frames++ < 60) o.frame(w);
    REQUIRE(renderer_probe_tile_valid(o.r, probe.bits()));
    o.frame(w);
    CHECK(renderer_probe_volume_count(o.r) == 1);
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    std::vector<float> px;
    std::string error;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, px, &error));
    check_colors(px, 4, 128, 0, 0, 128, 0.08f);  // the capture, not black
}

TEST_CASE("realtime probe: the time slice draws at most the budget of faces a frame and finishes in order") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::TimeSliced);
    (void)probe;
    o.r.probe_set_budget(2);
    o.frame(w);
    Json p = probe_of(o, w, probe);
    CHECK(p["facesDone"].get<int>() == 2);
    CHECK(p["captures"].get<int>() == 0);
    CHECK(p["state"] == "capturing");
    o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["facesDone"].get<int>() == 4);
    o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["captures"].get<int>() == 1);
    CHECK(p["state"] == "ready");
    CHECK(report_of(o)["faceBudget"] == 2);

    // A bigger budget finishes the next capture sooner: all six faces in one frame.
    o.r.probe_set_budget(12);
    CHECK(o.r.probe_refresh(make(w, "unrelated")) == false);  // not a probe
    CHECK(o.r.probe_refresh(probe));
    o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["captures"].get<int>() == 2);
}

TEST_CASE("realtime probe: an on-demand probe captures only when asked") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::OnDemand);
    o.r.probe_set_budget(12);
    for (int i = 0; i < 2; ++i) o.frame(w);
    Json p = probe_of(o, w, probe);
    const int first = p["captures"].get<int>();
    for (int i = 0; i < 3; ++i) o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["captures"].get<int>() == first);  // nothing asked since
    CHECK(o.r.probe_refresh(probe));
    o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["captures"].get<int>() == first + 1);
}

namespace {

// Draws frames until `probe` has made `captures` captures (at most `limit` frames); false when it did not.
bool frames_until_captured(Own& o, World& w, Entity probe, int captures, int limit = 60) {
    for (int i = 0; i < limit; ++i) {
        o.frame(w);
        const Json report = o.r.probe_report();
        const Json* p = probe_json(report, w.id_of(probe));
        if (p && (*p)["captures"].get<int>() >= captures) return true;
    }
    return false;
}

// Whether the colour room's directions read from the atlas tile of `probe` are right; `why` names the first one that is not.
bool tile_colors_right(Own& o, Entity probe, int resolution, std::string& why) {
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    CHECK(tile.resolution == resolution);
    std::vector<float> px;
    std::string error;
    const bool read = renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, resolution,
                                                resolution, px, &error);
    INFO("read error: " << error);
    REQUIRE(read);
    why.clear();
    for (const Expect& e : expectations()) {
        const Rgb got = sample(px, 4, resolution, 0, 0, resolution, normalize(e.dir));
        if (std::fabs(got.r - e.want.r) > 0.08f || std::fabs(got.g - e.want.g) > 0.08f ||
            std::fabs(got.b - e.want.b) > 0.08f) {
            why = std::string(e.what) + ": got " + std::to_string(got.r) + " " + std::to_string(got.g) + " " +
                  std::to_string(got.b);
            return false;
        }
    }
    return true;
}

}  // namespace

namespace {

// Another realtime probe of the colour room, at its centre, with a tile of `resolution`.
Entity add_probe(World& w, const char* name, int resolution) {
    Entity e = make(w, name, {0, 0, 0});
    auto& rp = w.add<ReflectionProbe>(e);
    rp.mode = ProbeMode::Realtime;
    rp.update = ProbeUpdate::OnDemand;
    rp.resolution = resolution;
    rp.boxSize = {6, 6, 6};
    rp.clear = ProbeClear::Color;
    rp.clearColor = Color{0, 0, 0, 1};
    return e;
}

}  // namespace

TEST_CASE("realtime probe: two probes of different resolutions share the scratch slots and both tiles are right, at "
          "every face budget") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    // A budget of 2 draws a capture over three frames; 4 and 8 make the second probe start in the frame the first one ends, the case in
    // which the scratch images of a slot used to be remade for the other resolution before the first probe's filtering ran.
    // Every capture is compared, the first ones too: a capture that spreads over several frames once drew one face of its tile with
    // the data of another frame when the GPU was behind (Gpu::begin_transient_writes), which only a loaded machine showed.
    for (int budget : {2, 4, 8}) {
        INFO("budget " << budget);
        Own o(g);
        REQUIRE(o.ok);
        World w;
        const Entity a = build_room(w, ProbeMode::Realtime, ProbeUpdate::OnDemand);  // 128
        const Entity b = add_probe(w, "second", 256);
        o.r.probe_set_budget(budget);
        std::string whyA, whyB;
        REQUIRE(frames_until_captured(o, w, a, 1));
        CHECK_MESSAGE(tile_colors_right(o, a, 128, whyA), "first capture of the probe of 128: " << whyA);
        REQUIRE(frames_until_captured(o, w, b, 1));
        CHECK_MESSAGE(tile_colors_right(o, b, 256, whyB), "first capture of the probe of 256: " << whyB);
        // The second ones, asked together and so sharing the slots.
        CHECK(o.r.probe_refresh(a));
        CHECK(o.r.probe_refresh(b));
        REQUIRE(frames_until_captured(o, w, a, 2));
        REQUIRE(frames_until_captured(o, w, b, 2));
        CHECK_MESSAGE(tile_colors_right(o, a, 128, whyA), "second capture of the probe of 128: " << whyA);
        CHECK_MESSAGE(tile_colors_right(o, b, 256, whyB), "second capture of the probe of 256: " << whyB);
    }
}

TEST_CASE(
    "realtime probe: three probes of mixed resolutions captured one face per frame, round after round, every tile "
    "is right") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    // Every face of every capture is a frame of its own, so the data of the next face is written while the GPU may still be drawing
    // the one before it (what Gpu::begin_transient_writes keeps apart); the three probes share the scratch slots.
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probes[3] = {build_room(w, ProbeMode::Realtime, ProbeUpdate::OnDemand), add_probe(w, "second", 256),
                              add_probe(w, "third", 128)};
    const int sizes[3] = {128, 256, 128};
    o.r.probe_set_budget(1);
    for (int round = 1; round <= 4; ++round) {
        INFO("round " << round);
        if (round > 1)
            for (const Entity& p : probes) CHECK(o.r.probe_refresh(p));
        for (const Entity& p : probes) REQUIRE(frames_until_captured(o, w, p, round, 120));
        for (int i = 0; i < 3; ++i) {
            std::string why;
            CHECK_MESSAGE(tile_colors_right(o, probes[i], sizes[i], why), "probe " << i << ": " << why);
        }
    }
}

TEST_CASE("realtime probe: a scene change or a new world makes an on-demand probe capture the new scene") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    o.r.probe_set_budget(12);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::OnDemand);
    REQUIRE(frames_until_captured(o, w, probe, 1));
    for (int i = 0; i < 3; ++i) o.frame(w);
    CHECK(probe_of(o, w, probe)["captures"].get<int>() == 1);  // on demand: nothing asked, nothing captured

    // The scene is reloaded in place (the same World, the same entity ids): the +X wall is green now.
    w.get<MeshRenderer>(w.find("px"))->emissive = Color{0, 1, 0, 1};
    w.bump_scene_generation();
    o.frame(w);
    CHECK(probe_of(o, w, probe)["captures"].get<int>() == 1);  // the new scene was captured, from zero
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    std::vector<float> px;
    std::string error;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, px, &error));
    Rgb east = sample(px, 4, 128, 0, 0, 128, {1, 0, 0});
    CHECK(east.r < 0.1f);
    CHECK(east.g > 0.9f);

    // Another World (a scene switched to) with the same entity bits: the +X wall is blue.
    World w2;
    const Entity probe2 = build_room(w2, ProbeMode::Realtime, ProbeUpdate::OnDemand);
    w2.get<MeshRenderer>(w2.find("px"))->emissive = Color{0, 0, 1, 1};
    o.frame(w2);
    CHECK(probe_of(o, w2, probe2)["captures"].get<int>() == 1);
    REQUIRE(renderer_probe_tile(o.r, probe2.bits(), tile));
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, px, &error));
    east = sample(px, 4, 128, 0, 0, 128, {1, 0, 0});
    CHECK(east.r < 0.1f);
    CHECK(east.b > 0.9f);
}

TEST_CASE("realtime probe: removing the component or the entity gives the tile back") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::EveryFrame);
    o.r.probe_set_budget(12);
    for (int i = 0; i < 2; ++i) o.frame(w);
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    const int before = report_of(o)["atlas"]["tiles"].get<int>();
    w.remove<ReflectionProbe>(probe);
    o.frame(w);
    CHECK_FALSE(renderer_probe_tile(o.r, probe.bits(), tile));
    CHECK(probe_json(report_of(o), w.id_of(probe)) == nullptr);
    // The last probe gone: the renderer keeps no atlas (no report) or an atlas with fewer tiles.
    const Json after = report_of(o);
    CHECK((!after.contains("atlas") || after["atlas"]["tiles"].get<int>() < before));
    CHECK(before >= 1);
}

TEST_CASE("realtime probe: a probe's resolution decides the size of its tile, and a bigger probe may evict a smaller "
          "one that matters less") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity a = build_room(w, ProbeMode::Realtime, ProbeUpdate::OnDemand);
    w.get<ReflectionProbe>(a)->resolution = 64;
    Entity b = make(w, "second", {0, 0, 0});
    auto& rb = w.add<ReflectionProbe>(b);
    rb.mode = ProbeMode::Realtime;
    rb.update = ProbeUpdate::OnDemand;
    rb.resolution = 256;
    rb.importance = 5;
    o.frame(w);
    ProbeTile ta, tb;
    REQUIRE(renderer_probe_tile(o.r, a.bits(), ta));
    REQUIRE(renderer_probe_tile(o.r, b.bits(), tb));
    CHECK(ta.resolution == 64);
    CHECK(tb.resolution == 256);
    const bool disjoint = ta.x + probe_layout(64).tileW <= tb.x || tb.x + probe_layout(256).tileW <= ta.x ||
                          ta.y + probe_layout(64).tileH <= tb.y || tb.y + probe_layout(256).tileH <= ta.y;
    CHECK(disjoint);
}

TEST_CASE("realtime probe: the sky is entry 0 of the atlas, written from the sky's own cube") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    Entity cam = make(w, "cam", {0, 0, 0});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0.15f, 0.35f, 0.9f, 1};  // the gradient sky: zenith blue, horizon and ground warm
    w.settings().horizonColor = Color{0.7f, 0.45f, 0.2f, 1};
    Entity probe = make(w, "probe", {0, 0, 0});
    auto& rp = w.add<ReflectionProbe>(probe);
    rp.mode = ProbeMode::Realtime;
    rp.update = ProbeUpdate::OnDemand;
    for (int i = 0; i < 4; ++i) o.frame(w);
    const Json report = report_of(o);
    INFO("report: " << report.dump(2));
    ProbeTile sky;
    REQUIRE(renderer_probe_tile(o.r, kProbeSkyId, sky));
    CHECK(sky.resolution == kProbeSkyResolution);
    const std::string state = report["sky"]["state"].get<std::string>();
    // The default gradient sky is drawn by the engine's own sky: the entry is written ("ready"), or the scene draws no sky material
    // and the meshes keep the gradient ("noSky"): either way the entry exists and the report says which.
    CHECK((state == "ready" || state == "noSky"));
    if (state == "ready") {
        std::vector<float> px;
        std::string error;
        REQUIRE(renderer_read_probe_atlas(o.r, sky.x + kProbeBorder, sky.y + kProbeBorder, kProbeSkyResolution,
                                          kProbeSkyResolution, px, &error));
        const Rgb up = sample(px, 4, kProbeSkyResolution, 0, 0, kProbeSkyResolution, {0, 1, 0});
        const Rgb down = sample(px, 4, kProbeSkyResolution, 0, 0, kProbeSkyResolution, {0, -1, 0});
        CHECK(up.b > up.r);  // blue overhead
        CHECK(down.b < up.b);
    }
}

TEST_CASE("realtime probe: on a GPU that cannot render half floats the atlas is RGBA8, the capture still reads right "
          "and probe_capture says no") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    ForceRgba8 force;
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Realtime, ProbeUpdate::EveryFrame);
    o.r.probe_set_budget(12);
    for (int i = 0; i < 3; ++i) o.frame(w);
    const Json report = report_of(o);
    INFO("report: " << report.dump(2));
    CHECK(report["atlas"]["format"] == "RGBA8");
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    std::vector<float> px;
    std::string error;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, px, &error));
    // The bytes of an RGBA8 atlas are the clamped light: pure colours stay pure. (With an RGBA8 scene the light is in gamma space, which
    // keeps 0 and 1.)
    check_colors(px, 4, 128, 0, 0, 128, 0.1f);
    Renderer::ProbePage page;
    CHECK_FALSE(o.r.probe_capture(w, probe, page, &error));
    CHECK(error.find("RGBA16F") != std::string::npos);
}

TEST_CASE("baked probe: the page of a manifest is uploaded to the atlas, a changed pair is read again, a missing one "
          "is reported") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_probes(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity probe = build_room(w, ProbeMode::Baked, ProbeUpdate::TimeSliced);
    Renderer::ProbePage page;
    std::string error;
    REQUIRE(o.r.probe_capture(w, probe, page, &error));

    // No bakedMap yet: reported, nothing drawn.
    o.frame(w);
    Json p = probe_of(o, w, probe);
    CHECK(p["state"] == "noBake");
    CHECK(p["message"].get<std::string>().find("bakedMap") != std::string::npos);

    // A map that is not there: noBake with the file named.
    w.get<ReflectionProbe>(probe)->bakedMap = "assets/not_baked.probe.json";
    o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["state"] == "noBake");
    CHECK(p["message"].get<std::string>().find("not_baked") != std::string::npos);

    const std::string path = write_baked(page, "room", 1.0f);
    w.get<ReflectionProbe>(probe)->bakedMap = path;
    for (int i = 0; i < 2; ++i) o.frame(w);
    p = probe_of(o, w, probe);
    INFO("probe: " << p.dump(2));
    CHECK(p["state"] == "ready");
    CHECK(p["mode"] == "baked");
    CHECK(p["hash"].get<std::string>().size() == 16);
    ProbeTile tile;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), tile));
    std::vector<float> px;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, px, &error));
    check_colors(px, 4, 128, 0, 0, 128, 0.1f);  // RGBE keeps 0.4% of the largest channel
    const ProbeLayout lay = probe_layout(128);
    std::vector<float> shRow;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x, tile.y + lay.shY, kProbeShCoefficients, 1, shRow, &error));
    for (int c = 0; c < 3; ++c) CHECK(std::fabs(shRow[std::size_t(c)] - page.sh[0][c]) < 0.05f);

    // The probe's intensity is a gain of the upload.
    w.get<ReflectionProbe>(probe)->intensity = 0.5f;
    for (int i = 0; i < 2; ++i) o.frame(w);
    std::vector<float> half;
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, half, &error));
    const Rgb red = sample(half, 4, 128, 0, 0, 128, {1, 0, 0});
    CHECK(std::fabs(red.r - 0.5f) < 0.06f);
    w.get<ReflectionProbe>(probe)->intensity = 1.0f;

    // Hot reload: the pair rewritten with half the light (a new page name: the hash is in it), the manifest last, then the editor's notice.
    const std::string path2 = write_baked(page, "room", 0.5f);
    CHECK(path2 == path);
    o.r.reload_asset(path);
    for (int i = 0; i < 2; ++i) o.frame(w);
    p = probe_of(o, w, probe);
    CHECK(p["state"] == "ready");
    REQUIRE(renderer_read_probe_atlas(o.r, tile.x + kProbeBorder, tile.y + kProbeBorder, 128, 128, half, &error));
    const Rgb red2 = sample(half, 4, 128, 0, 0, 128, {1, 0, 0});
    CHECK(std::fabs(red2.r - 0.5f) < 0.06f);

    // The tile is given back (no bakedMap) and the same map returns to the same tile: it is uploaded again, not left empty.
    w.get<ReflectionProbe>(probe)->bakedMap.clear();
    o.frame(w);
    CHECK_FALSE(renderer_probe_tile_valid(o.r, probe.bits()));
    w.get<ReflectionProbe>(probe)->bakedMap = path;
    for (int i = 0; i < 2; ++i) o.frame(w);
    CHECK(renderer_probe_tile_valid(o.r, probe.bits()));
    ProbeTile again;
    REQUIRE(renderer_probe_tile(o.r, probe.bits(), again));
    REQUIRE(renderer_read_probe_atlas(o.r, again.x + kProbeBorder, again.y + kProbeBorder, 128, 128, half, &error));
    const Rgb red3 = sample(half, 4, 128, 0, 0, 128, {1, 0, 0});
    CHECK(std::fabs(red3.r - 0.5f) < 0.06f);
}
