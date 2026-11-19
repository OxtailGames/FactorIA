// Sprite materials (M72.1, docs/SHADERS.md "Materials on sprites, shapes, tiles, text and particles"): a Sprite with `material` and
// `materialParams` is drawn by the compiled quad programs of its material. The fixtures are tests/data/materials/*sprite_*: their
// twins are committed for the backends the render tests run on (tools/common/tests/shaders_fixtures_test.cpp keeps them current).
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <iterator>
#include <memory>
#include <string>
#include <vector>
#include <fstream>
#include <mutex>

#include "fa/core/json.h"
#include "fa/scene/tilemap.h"

using namespace fa;
using namespace fa::test;

namespace {

constexpr float kTol = 0.04f;  // 4 % of a channel: 8-bit quantisation and the scene's filtering

// The fixture materials are copied into the test project; every twin gets this build's engine version (its "template" stays,
// so a template change without regenerating the twins fails loudly).
void install_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

// A test starts with an empty asset cache and the fixtures installed, and leaves no compiler behind.
struct MaterialScope {
    MaterialScope() {
        gfx().renderer.clear_asset_cache();
        install_materials();
    }
    ~MaterialScope() {
        gfx().renderer.set_shader_compiler({});
        gfx().renderer.clear_asset_cache();
    }
};

// The warnings and errors logged while alive (the sink may run on a job thread).
struct ProblemLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    ProblemLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Warn) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ProblemLog() { remove_log_sink(id); }
    ProblemLog(const ProblemLog&) = delete;
    ProblemLog& operator=(const ProblemLog&) = delete;
    std::vector<std::string> messages() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return shared->lines;
    }
    int count(const std::string& needle) const {
        const std::vector<std::string> m = messages();
        return int(std::count_if(m.begin(), m.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
};

void camera2d(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
}

Entity sprite(World& w, Vec3 p, const char* material = "", Vec2 size = {60, 40}) {
    Entity e = make(w, "sprite", p);
    auto& s = w.add<Sprite>(e);
    s.size = size;
    s.color = Color{0.8f, 0.7f, 0.9f, 1.0f};
    s.material = material;
    return e;
}

void near(const Color& got, float r, float g, float b, float tol = kTol) {
    CHECK(std::fabs(got.r - r) <= tol);
    CHECK(std::fabs(got.g - g) <= tol);
    CHECK(std::fabs(got.b - b) <= tol);
}

constexpr const char* kEmpty = "materials/sprite_empty.material.json";
constexpr const char* kTint = "materials/sprite_tint.material.json";
constexpr const char* kCut = "materials/sprite_cut.material.json";
constexpr const char* kTime = "materials/sprite_time.material.json";
constexpr const char* kMask = "materials/sprite_mask.material.json";

}  // namespace

TEST_CASE(
    "sprite materials: a material with an empty fragment() draws the pixels of the sprite without one, in the lean "
    "program and in the full one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // The same sprites with and without the material. The first batch is `plain` (the lean quad_plain program); a lit sprite and
    // a Multiply one are not (the full quad program).
    auto frame = [&](const char* material, bool full) {
        World w;
        camera2d(w);
        Entity a = sprite(w, {-80, 20, 0}, material);
        Entity b = sprite(w, {-10, -20, 0}, material, {50, 30});
        Entity c = sprite(w, {70, 10, 0}, material, {40, 40});
        if (full) {
            w.get<Sprite>(a)->lit = true;
            w.get<Sprite>(b)->blend = BlendMode::Multiply;
            w.get<Sprite>(c)->lit = true;
        }
        return g.render(w);
    };
    ProblemLog log;
    for (const bool full : {false, true}) {
        INFO((full ? "full program" : "plain program"));
        const Image without = frame("", full);
        CHECK(g.renderer.stats().materials == 0);
        const Image with = frame(kEmpty, full);
        CHECK(g.renderer.stats().materials >= 1);
        CHECK(g.renderer.stats().materialFallbacks.empty());
        CHECK(diff_images(without, with, 2.0f / 255.0f).maxError <= 2.0 / 255.0);
    }
    CHECK(log.messages().empty());
}

TEST_CASE("sprite materials: a tint material changes the sprite's pixels and materialParams changes the tint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const Json& params, bool lit) {
        World w;
        camera2d(w);
        Entity e = sprite(w, {0, 0, 0}, kTint);
        w.get<Sprite>(e)->color = Color{1, 1, 1, 1};
        w.get<Sprite>(e)->lit = lit;
        w.get<Sprite>(e)->materialParams = params;
        return g.render(w);
    };
    for (const bool lit : {false, true}) {
        INFO((lit ? "full program" : "plain program"));
        const Image def = frame(Json::object(), lit);
        const Image green = frame(Json::object({{"tint", Json::array({0.0, 1.0, 0.0, 1.0})}}), lit);
        Color d = def.pixel(160, 90), gr = green.pixel(160, 90);
        if (lit) {  // the 2D lights shade the picture before the snippet: only the ratios are checked
            CHECK(d.r > d.g * 2.0f);
            CHECK(gr.g > gr.r * 4.0f);
        } else {
            near(d, 1.0f, 0.25f, 0.25f);
            near(gr, 0.0f, 1.0f, 0.0f);
        }
        near(def.pixel(20, 20), 0, 0, 0);  // outside the sprite nothing changed
    }
}

TEST_CASE("sprite materials: screen_uv runs left to right and top to bottom, fa_target is the whole target") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const Json& params, bool lit) {
        World w;
        camera2d(w);
        Entity e = sprite(w, {0, 0, 0}, kCut, {300, 160});
        w.get<Sprite>(e)->color = Color{1, 1, 1, 1};
        w.get<Sprite>(e)->lit = lit;
        w.get<Sprite>(e)->materialParams = params;
        return g.render(w);
    };
    for (const bool lit : {false, true}) {
        INFO((lit ? "full program" : "plain program"));
        // cut = 0.5 (the default): the left half of the target is gone.
        const Image left = frame(Json::object(), lit);
        near(left.pixel(80, 90), 0, 0, 0);
        CHECK(left.pixel(240, 90).r > 0.2f);
        // cut = 0.8 moves the edge to x = 256.
        const Image far = frame(Json::object({{"cut", 0.8}}), lit);
        near(far.pixel(240, 90), 0, 0, 0);
        CHECK(far.pixel(300, 90).r > 0.2f);
        // cutY = 0.5 (and no cut): the top half is gone, on every backend.
        const Image top = frame(Json::object({{"cut", 0.0}, {"cutY", 0.5}}), lit);
        near(top.pixel(160, 40), 0, 0, 0);
        CHECK(top.pixel(160, 140).r > 0.2f);
    }
}

TEST_CASE("sprite materials: QuadInput.time follows the engine clock in both programs") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](int steps, bool lit) {
        World w;
        camera2d(w);
        Entity e = sprite(w, {0, 0, 0}, kTime);
        w.get<Sprite>(e)->lit = lit;
        for (int i = 0; i < steps; ++i) w.advance_clock(1.0 / 60.0);
        return g.render(w);
    };
    for (const bool lit : {false, true}) {
        INFO((lit ? "full program" : "plain program"));
        near(frame(0, lit).pixel(160, 90), 0.0f, 0.0f, 0.0f);
        near(frame(120, lit).pixel(160, 90), 0.5f, 0.0f, 0.0f);  // 2 s * 0.25
        near(frame(240, lit).pixel(160, 90), 1.0f, 0.0f, 0.0f);
    }
}

TEST_CASE("sprite materials: a material's texture is bound after the engine's four views") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    Entity shown = sprite(w, {-80, 0, 0}, kMask, {64, 64});
    w.get<Sprite>(shown)->color = Color{1, 1, 1, 1};
    Entity reference = sprite(w, {80, 0, 0}, "", {64, 64});  // the same texture drawn by the engine
    w.get<Sprite>(reference)->texture = "textures/checker.png";
    w.get<Sprite>(reference)->pixelArt = true;
    const Image img = g.render(w);
    const Color want = img.pixel(80 + 160 - 29, 90 - 29);  // inside the first texel of the 8x8 checker
    REQUIRE(want.a > 0.9f);
    near(img.pixel(-80 + 160, 90), want.r, want.g, want.b, 0.02f);
    CHECK(g.renderer.stats().materials == 1);
}

TEST_CASE("sprite materials: items with equal values share a batch, different values and a missing material split it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // Four sprites in a row (the same layer and height: they draw in the order they were made), each with a material and params.
    struct Item {
        const char* material;
        Json params;
    };
    auto calls = [&](const std::vector<Item>& items) {
        World w;
        camera2d(w);
        float x = -105.0f;
        for (const Item& it : items) {
            Entity e = sprite(w, {x, 0, 0}, it.material, {40, 40});
            w.get<Sprite>(e)->materialParams = it.params;
            x += 70.0f;
        }
        g.render(w);
        return g.renderer.stats().drawCalls;
    };
    const Json none = Json::object();
    const Json green = Json::object({{"tint", Json::array({0.0, 1.0, 0.0, 1.0})}});
    // The default written out is the same value as no override: one batch.
    const Json spelled = Json::object({{"tint", Json::array({1.0, 0.25, 0.25, 1.0})}});
    const int one = calls({{kTint, none}, {kTint, none}, {kTint, none}, {kTint, none}});
    CHECK(calls({{kTint, none}, {kTint, spelled}, {kTint, none}, {kTint, spelled}}) == one);
    CHECK(calls({{kTint, none}, {kTint, none}, {kTint, green}, {kTint, green}}) == one + 1);
    CHECK(calls({{kTint, none}, {kTint, green}, {kTint, none}, {kTint, green}}) == one + 3);
    // Another material, or none, is another batch.
    CHECK(calls({{kTint, none}, {kTint, none}, {kEmpty, none}, {kEmpty, none}}) == one + 1);
    CHECK(calls({{kTint, none}, {kTint, none}, {"", none}, {"", none}}) == one + 1);
    CHECK(calls({{"", none}, {"", none}, {"", none}, {"", none}}) == one);
}

TEST_CASE("sprite materials: a material that does not build draws magenta, logs once and counts as a fallback") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    REQUIRE(fs::write_text(
                "materials/broken.material.json",
                R"({"format": "factoria.material/1", "kind": "sprite", "shader": "shaders/broken.fragment.glsl"})")
                .ok());
    g.renderer.set_shader_compiler([](const std::string&, const std::string&) -> Result<Json> {
        return make_error(
            "shaders/broken.fragment.glsl:3:5: error: 'colour' : no such field in structure 'QuadSurface'\n  "
            "hint: did you mean color?",
            "did you mean color?");
    });
    ProblemLog log;
    World w;
    camera2d(w);
    Entity e = sprite(w, {0, 0, 0}, "materials/broken.material.json");
    w.get<Sprite>(e)->color = Color{1, 1, 1, 0.5f};
    sprite(w, {-100, 50, 0}, "materials/broken.material.json", {20, 20});
    Image img;
    for (int i = 0; i < 3; ++i) img = g.render(w);
    // Magenta, and the sprite's alpha (blended over the black clear colour) is kept.
    near(img.pixel(160, 90), 0.5f, 0.0f, 0.5f);
    CHECK(log.count("broken.fragment.glsl:3:5") == 1);
    REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
    CHECK(g.renderer.stats().materialFallbacks[0] == "materials/broken.material.json");
    CHECK(g.renderer.stats().materials == 0);
    CHECK(g.renderer.asset_report()["failures"].size() == 1);
}

TEST_CASE("sprite materials: a mesh material on a sprite is the error material with one warning") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    World w;
    camera2d(w);
    Entity e = sprite(w, {0, 0, 0}, "materials/glow.material.json");
    w.get<Sprite>(e)->color = Color{1, 1, 1, 1};
    Image img;
    for (int i = 0; i < 3; ++i) img = g.render(w);
    near(img.pixel(160, 90), 1.0f, 0.0f, 1.0f);
    CHECK(log.count("needs a \"sprite\" material") == 1);
    CHECK(g.renderer.stats().materialFallbacks.size() == 1);
}

TEST_CASE("sprite materials: hot reload swaps the shader, keeps the last good one on a broken edit and recovers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    REQUIRE(fs::write_text("materials/hot.material.json",
                           R"({"format": "factoria.material/1", "kind": "sprite", "shader": "shaders/hot.txt",
                               "params": {"tint": {"type": "color", "default": [1.0, 0.25, 0.25, 1.0], "doc": "Tint."}}})")
                .ok());
    // Stands in for the tooling: the snippet on disk names the fixture twin to use ("sprite_tint" or "sprite_empty"), or is broken.
    g.renderer.set_shader_compiler([dialect](const std::string&, const std::string&) -> Result<Json> {
        auto snippet = fs::read_text("shaders/hot.txt");
        if (!snippet.ok()) return snippet.error();
        if (*snippet == "broken")
            return make_error("shaders/hot.txt:1:1: error: 'broken' : undeclared identifier",
                              "Write sprite_tint or sprite_empty.");
        return load_json_file("materials/" + *snippet + ".material.json." + dialect + ".shader");
    });
    auto frame = [&]() {
        World w;
        camera2d(w);
        Entity e = sprite(w, {0, 0, 0}, "materials/hot.material.json");
        w.get<Sprite>(e)->color = Color{1, 1, 1, 1};
        return g.render(w);
    };
    ProblemLog log;
    REQUIRE(fs::write_text("shaders/hot.txt", "sprite_tint").ok());
    const Image tinted = frame();
    near(tinted.pixel(160, 90), 1.0f, 0.25f, 0.25f);
    REQUIRE(fs::write_text("shaders/hot.txt", "sprite_empty").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image plain = frame();
    near(plain.pixel(160, 90), 1.0f, 1.0f, 1.0f);
    CHECK(log.messages().empty());

    REQUIRE(fs::write_text("shaders/hot.txt", "broken").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image kept = frame();
    frame();
    CHECK(diff_images(plain, kept, 0.0f).maxError == 0.0);
    CHECK(log.count("shaders/hot.txt:1:1") == 1);
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(g.renderer.asset_report()["failures"].size() == 1);

    REQUIRE(fs::write_text("shaders/hot.txt", "sprite_tint").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image back = frame();
    CHECK(diff_images(tinted, back, 0.0f).maxError == 0.0);
    CHECK(log.messages().size() == 1);
    CHECK(g.renderer.asset_report()["failures"].empty());
}

// ---------------------------------------------------------------------------------------------------------------------------------
// The other 2D emitters (M72.5): Shape2D, Tilemap, Text, ParticleEmitter and a UI widget's background take `material` too.
// ---------------------------------------------------------------------------------------------------------------------------------
namespace {

enum class Kind { Shape, Tiles, Glyphs, Particles, Widget };
constexpr Kind kKinds[] = {Kind::Shape, Kind::Tiles, Kind::Glyphs, Kind::Particles, Kind::Widget};

const char* kind_name(Kind k) {
    switch (k) {
        case Kind::Shape: return "Shape2D";
        case Kind::Tiles: return "Tilemap";
        case Kind::Glyphs: return "Text";
        case Kind::Particles: return "ParticleEmitter";
        case Kind::Widget: return "UI widget background";
    }
    return "";
}

// One visual of `kind` centred on design pixel (px, 90) of the 320 x 180 picture, with `material` (and `params`). Every one of
// them is white and draws a block of at least 40 x 40 pixels (a glyph: the stem of a big letter).
Entity emitter(World& w, Kind kind, float px, const char* material, const Json& params = Json::object()) {
    const Vec3 pos{px - 160.0f, 0, 0};  // world units = design pixels at the default camera
    switch (kind) {
        case Kind::Shape: {
            Entity e = make(w, "shape", pos);
            auto& s = w.add<Shape2D>(e);
            s.shape = ShapeType::Rectangle;
            s.size = {50, 50};
            s.color = Color::white();
            s.material = material;
            s.materialParams = params;
            return e;
        }
        case Kind::Tiles: {
            Entity e = make(w, "tiles", pos - Vec3{24, 24, 0});  // a map's origin is its corner
            auto& tm = w.add<Tilemap>(e);
            tm.tileSize = {16, 16};
            set_tilemap_grid(tm, 3, 3, std::vector<int>(9, 0));
            tm.color = Color::white();
            tm.material = material;
            tm.materialParams = params;
            return e;
        }
        case Kind::Glyphs: {
            Entity e = make(w, "text", pos);
            auto& t = w.add<Text>(e);
            t.text = "I";
            t.fontSize = 120;
            t.color = Color::white();
            t.material = material;
            t.materialParams = params;
            return e;
        }
        case Kind::Particles: {
            Entity e = make(w, "sparks", pos);
            auto& p = w.add<ParticleEmitter>(e);
            p.emitting = false;
            p.rate = 0;
            p.burst = 1;
            p.lifetime = 1000.0f;
            p.lifetimeVariance = 0;
            p.speed = 0;
            p.speedVariance = 0;
            p.spread = 0;
            p.gravity = {0, 0, 0};
            p.startSize = p.endSize = 80;
            p.startColor = p.endColor = Color::white();
            p.material = material;
            p.materialParams = params;
            return e;
        }
        case Kind::Widget: {
            Entity e = make(w, "panel", {px, 90, 0});  // design pixels from the top-left corner
            auto& p = w.add<Panel>(e);
            p.size = {50, 50};
            p.color = Color::white();
            p.material = material;
            p.materialParams = params;
            return e;
        }
    }
    return {};
}

// The brightest pixel (by its largest channel) in the columns [x0, x1) of the picture.
Color brightest(const Image& img, int x0, int x1) {
    Color best{0, 0, 0, 1};
    float bestV = -1.0f;
    for (int y = 0; y < img.height; ++y)
        for (int x = x0; x < x1; ++x) {
            const Color c = img.pixel(x, y);
            const float v = std::max({c.r, c.g, c.b});
            if (v > bestV) {
                bestV = v;
                best = c;
            }
        }
    return best;
}

// A world of a camera and two visuals of `kind` in a row: one with the material (left, or right with `materialSecond`), the other
// without.
Image two_visuals(Gfx& g, Kind kind, const char* material, bool materialSecond = false,
                  const Json& params = Json::object()) {
    World w;
    camera2d(w);
    emitter(w, kind, 100, materialSecond ? "" : material, materialSecond ? Json::object() : params);
    emitter(w, kind, 220, materialSecond ? material : "", materialSecond ? params : Json::object());
    Image img;
    for (int i = 0; i < 2; ++i) img = g.render(w, 1.0f / 60.0f);
    return img;
}

}  // namespace

TEST_CASE("emitter materials: a material changes the pixels of a Shape2D, a Tilemap, Text, particles and a widget, and "
          "the next "
          "component stays on the built-in shader") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    for (const Kind kind : kKinds) {
        INFO(kind_name(kind));
        for (const bool second : {false, true}) {  // the material on the first or on the second component of the pair
            INFO((second ? "material on the right" : "material on the left"));
            const Image img = two_visuals(g, kind, kTint, second);
            const Color with = brightest(img, second ? 160 : 0, second ? 320 : 160);
            const Color without = brightest(img, second ? 0 : 160, second ? 160 : 320);
            // The tint is (1, 0.25, 0.25): the colour keeps its red and loses three quarters of the others, whatever the coverage.
            CHECK(with.r > 0.3f);
            CHECK(with.g < with.r * 0.35f);
            CHECK(with.b < with.r * 0.35f);
            // No material: white, so the material did not leak into the next (or the previous) component.
            CHECK(without.r > 0.3f);
            CHECK(without.g > without.r * 0.9f);
            CHECK(without.b > without.r * 0.9f);
        }
        CHECK(g.renderer.stats().materials == 1);
        CHECK(g.renderer.stats().materialFallbacks.empty());
        // materialParams reach the shader of this kind too.
        const Image green =
            two_visuals(g, kind, kTint, false, Json::object({{"tint", Json::array({0.0, 1.0, 0.0, 1.0})}}));
        const Color gc = brightest(green, 0, 160);
        CHECK(gc.g > 0.3f);
        CHECK(gc.r < gc.g * 0.15f);
        CHECK(gc.b < gc.g * 0.15f);
    }
    CHECK(log.messages().empty());
}

TEST_CASE("emitter materials: a material that does not build draws every emitter magenta and counts as one fallback") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    REQUIRE(fs::write_text(
                "materials/broken.material.json",
                R"({"format": "factoria.material/1", "kind": "sprite", "shader": "shaders/broken.fragment.glsl"})")
                .ok());
    g.renderer.set_shader_compiler([](const std::string&, const std::string&) -> Result<Json> {
        return make_error("shaders/broken.fragment.glsl:3:5: error: 'colour' : no such field", "did you mean color?");
    });
    ProblemLog log;
    for (const Kind kind : kKinds) {
        INFO(kind_name(kind));
        const Image img = two_visuals(g, kind, "materials/broken.material.json");
        const Color bad = brightest(img, 0, 160), fine = brightest(img, 160, 320);
        CHECK(bad.r > 0.3f);
        CHECK(bad.g < bad.r * 0.15f);  // magenta: red and blue, no green
        CHECK(bad.b > bad.r * 0.85f);
        CHECK(fine.g > fine.r * 0.9f);  // the one without a material is white
        REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
        CHECK(g.renderer.stats().materialFallbacks[0] == "materials/broken.material.json");
        CHECK(g.renderer.stats().materials == 0);
    }
    CHECK(log.count("broken.fragment.glsl:3:5") == 1);
}

TEST_CASE("emitter materials: a tilemap's material covers every tile and a particle's every particle, in one batch") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // A bigger map and a burst of particles are one material each: the calls are the same as for one tile or one particle.
    auto calls = [&](int tiles, int particles) {
        World w;
        camera2d(w);
        Entity e = emitter(w, Kind::Tiles, 160, kTint);
        set_tilemap_grid(*w.get<Tilemap>(e), tiles, tiles, std::vector<int>(std::size_t(tiles * tiles), 0));
        Entity p = emitter(w, Kind::Particles, 160, kTint);
        w.get<ParticleEmitter>(p)->burst = particles;
        g.render(w, 1.0f / 60.0f);
        return g.renderer.stats().drawCalls;
    };
    CHECK(calls(8, 40) == calls(1, 1));
    CHECK(g.renderer.stats().materials == 1);
}

TEST_CASE(
    "emitter materials: a lookup is made once per distinct material and values in a frame, not once per component") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const Json green = Json::object({{"tint", Json::array({0.0, 1.0, 0.0, 1.0})}});
    auto resolves = [&](int sprites, bool twoValues, bool shapesToo) {
        World w;
        camera2d(w);
        for (int i = 0; i < sprites; ++i) {
            Entity e = sprite(w, {float(i % 10) * 20.0f - 90.0f, float(i / 10) * 20.0f - 40.0f, 0}, kTint, {10, 10});
            if (twoValues && i % 2 == 1) w.get<Sprite>(e)->materialParams = green;
        }
        if (shapesToo)
            for (int i = 0; i < sprites; ++i) emitter(w, Kind::Shape, 160, kTint);
        g.render(w);
        return g.renderer.stats().materialResolves;
    };
    CHECK(resolves(1, false, false) == 1);
    CHECK(resolves(40, false, false) == 1);  // forty sprites with the same material and no params
    CHECK(resolves(40, false, true) == 1);   // and forty Shape2D with it: the same values, the same answer
    CHECK(resolves(40, true, false) == 2);   // two sets of values: two lookups
    CHECK(g.renderer.stats().to_json()["materialResolves"] == 2);
    CHECK(resolves(40, false, false) == 1);  // a new frame asks again, once
}

TEST_CASE(
    "emitter materials: stats.materials counts a material once per frame, however many passes and groups draw it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    sprite(w, {-60, 0, 0}, kTint);
    Entity hud = sprite(w, {0, 0, 0}, kTint);  // the screen group is drawn apart from the world group
    w.get<Sprite>(hud)->space = RenderSpace::Screen;
    g.render(w);
    CHECK(g.renderer.stats().materials == 1);
    sprite(w, {60, 0, 0}, kEmpty);
    g.render(w);
    CHECK(g.renderer.stats().materials == 2);
}

TEST_CASE("emitter materials: the fading trail of an emitter with no live particle keeps the emitter's material") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    Entity e = emitter(w, Kind::Particles, 0, kTint);  // moved below
    {
        auto& p = *w.get<ParticleEmitter>(e);
        p.emitting = true;
        p.burst = 0;
        p.rate = 0;  // no particle is ever born: only the emitter's own path is drawn
        p.worldSpace = true;
        p.trail = ParticleTrail::Emitter;
        p.trailTime = 2.0f;
        p.trailWidth = 24.0f;
    }
    Image img;
    for (int i = 0; i < 40; ++i) {
        w.get<Transform>(e)->position = Vec3{-60.0f + float(i) * 3.0f, 0, 0};
        img = g.render(w, 1.0f / 60.0f);
    }
    w.get<ParticleEmitter>(e)->emitting = false;  // the trail alone is left and fades
    for (int i = 0; i < 3; ++i) img = g.render(w, 1.0f / 60.0f);
    const Color c = brightest(img, 0, 320);
    // The tint is (1, 0.25, 0.25): without the material the ribbon would be white.
    CHECK(c.r > 0.3f);
    CHECK(c.g < c.r * 0.35f);
    CHECK(c.b < c.r * 0.35f);
    CHECK(g.renderer.stats().materials == 1);
}

TEST_CASE("emitter materials: a material whose params name the target a camera draws into samples the checker for that "
          "camera "
          "only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    {
        Entity cam = make(w, "cam-X", {1000, 0, 0});
        auto& c = w.add<Camera>(cam);
        c.renderTarget = "X";
        c.renderTargetSize = Vec2{64, 32};
        c.orthoSize = 16;
        c.clearColor = Color{0, 0, 1, 1};
    }
    const Json params = Json::object({{"mask", "target:X"}});
    // The same material and params in the main camera's view and in X's own view: the main camera shows X's picture, X's camera
    // gets the checker (it cannot sample the image it writes).
    Entity inMain = sprite(w, {-80, 0, 0}, kMask, {32, 32});
    w.get<Sprite>(inMain)->color = Color::white();
    w.get<Sprite>(inMain)->materialParams = params;
    Entity inX = sprite(w, {1000, 0, 0}, kMask, {16, 16});
    w.get<Sprite>(inX)->color = Color::white();
    w.get<Sprite>(inX)->materialParams = params;
    Entity shows = sprite(w, {80, 0, 0}, "", {64, 32});  // X's picture, whole
    w.get<Sprite>(shows)->texture = "target:X";
    w.get<Sprite>(shows)->color = Color::white();
    Image img;
    for (int i = 0; i < 2; ++i) img = g.render(w, 1.0f / 60.0f);
    // The main camera: the corner of X's picture, its clear colour (blue).
    INFO("main camera");
    near(img.pixel(-80 + 160, 90), 0, 0, 1, 0.05f);
    // X's camera: the missing-texture checker (its first texel is not blue), in the middle of X's picture, which the main camera
    // shows at the centre of the sprite that shows X.
    INFO("X's camera");
    const Color mid = img.pixel(80 + 160, 90);
    near(mid, 1, 0, 1);  // the magenta of the checker's first texel
}
