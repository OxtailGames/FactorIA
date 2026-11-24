// Sprites drawn from compute buffers (M72.4, docs/shaders/SHADERS_COMPUTE.md "Sprites from a compute buffer"): a
// compute material writes the instances, a sprite material with "buffers" reads them in vertex() and fragment(),
// Sprite.instances is the count. The fixtures are tests/data/materials/materials/spritebuf*.material.json (twins made
// by tools/common/tests/shaders_fixtures_test.cpp); the compute material that fills them is meshbuf_fill, shared with
// the mesh tests. What needs storage buffers in a vertex shader (Metal, D3D11, GL 4.3+) says "SKIPPED, no compute here"
// elsewhere (FA_REQUIRE_COMPUTE=1 turns that into a failure on a runner that must have it).
#include "fa/core/engine_version.h"
#include "fa/render/compute.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iterator>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "compute_internal.h"
#include "render_features.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

const char* const kFill = "materials/meshbuf_fill.material.json";
const char* const kSprite = "materials/spritebuf.material.json";
const char* const kSprite2 = "materials/spritebuf2.material.json";
const char* const kScale = "materials/scale.material.json";

struct Scope {
    Gfx& g = gfx();
    Scope() {
        REQUIRE(g.ok);
        g.renderer.clear_asset_cache();
        install_materials();
    }
    ~Scope() {
        for (const Json& b : g.renderer.compute().list()) (void)g.renderer.compute().destroy_buffer(b["id"].get<int>());
        ComputeTestAccess::set_backend(g.renderer.compute(), -1);
        ComputeTestAccess::set_binding_limit(g.renderer.compute(), -1);
        g.renderer.clear_asset_cache();
    }
    Compute& compute() { return g.renderer.compute(); }
};

struct ErrorLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    ErrorLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Error) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ErrorLog() { remove_log_sink(id); }
    ErrorLog(const ErrorLog&) = delete;
    ErrorLog& operator=(const ErrorLog&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        int n = 0;
        for (const std::string& l : shared->lines)
            if (l.find(needle) != std::string::npos) ++n;
        return n;
    }
    int total() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(shared->lines.size());
    }
};

void skip_without_compute(const char* what, const std::string& why) {
    const char* v = std::getenv("FA_REQUIRE_COMPUTE");
    if (v && *v && std::string(v) != "0")
        FAIL("FA_REQUIRE_COMPUTE=1 but this backend has no compute (" << why << "): " << what);
    MESSAGE("SKIPPED, no compute here (" << why << "): " << what << " (FA_REQUIRE_COMPUTE=1 fails instead)");
}

void camera2d(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
}

// One 20 x 20 sprite at `pos` drawn with `material`: the template quad every instance starts from.
Entity add_instanced(World& w, const char* material, Json params, int instances, Vec3 pos = {0, 0, 0}) {
    Entity e = make(w, "points", pos);
    auto& s = w.add<Sprite>(e);
    s.size = {20, 20};
    s.color = Color::white();
    s.material = material;
    s.materialParams = std::move(params);
    s.instances = instances;
    return e;
}

bool is_red(const Color& c) { return c.r > 0.5f && c.g < 0.3f && c.b < 0.3f; }

// The number of red runs along the row `y` of the picture (one per instance drawn there: 40 px apart, 20 px wide).
int count_runs(const Image& img, int y = 90) {
    int runs = 0;
    bool in = false;
    for (int x = 0; x < img.width; ++x) {
        const bool red = is_red(img.pixel(x, y));
        if (red && !in) ++runs;
        in = red;
    }
    return runs;
}

// Writes `count` instances into the buffer, in a row 40 units apart centred on element 2; element `hide` hidden.
void fill(Compute& c, int id, int count, int hide = -1) {
    ComputeDispatch d;
    d.material = kFill;
    d.buffers["points"] = id;
    d.params = Json::object({{"count", count}, {"spacing", 40.0}, {"hide", hide}});
    d.groups[0] = 1;
    auto ran = c.dispatch(d);
    REQUIRE_MESSAGE(ran.ok(), ran.error().to_string());
}

int make_buffer(Compute& c, int elements) {
    auto id = c.create_buffer(kFill, "points", std::uint64_t(elements));
    REQUIRE_MESSAGE(id.ok(), id.error().to_string());
    return *id;
}

}  // namespace

TEST_CASE("sprite buffers: a compute material writes N positions and the sprite draws N quads in one draw") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("quads from a compute buffer are not drawn", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    ErrorLog log;
    auto frame = [&](int instances) {
        World w;
        camera2d(w);
        add_instanced(w, kSprite, Json::object({{"points", id}}), instances);
        return s.g.render(w);
    };
    const Image five = frame(5);
    CHECK(count_runs(five) == 5);
    // fragment() read its own element too: the quads are the red of the buffer, not the sprite's white.
    CHECK(is_red(five.pixel(160 - 80, 90)));
    CHECK(is_red(five.pixel(160, 90)));
    CHECK(is_red(five.pixel(160 + 80, 90)));
    CHECK(!is_red(five.pixel(160 + 20, 90)));  // between two quads: the clear colour
    CHECK(s.g.renderer.stats().sprites == 1);  // one Sprite, however many instances it draws
    CHECK(s.g.renderer.stats().drawCalls == 1);
    CHECK(count_runs(frame(3)) == 3);  // fewer instances than elements: the first three
    // Elements the compute pass did not write (all zero, w 0) collapse, so 8 instances show the 5 written ones.
    CHECK(count_runs(frame(8)) == 5);
    // 0 = the sprite's one quad: vertex() still runs once, with fa_instance_index 0 (the element at x = -80).
    const Image one = frame(0);
    CHECK(count_runs(one) == 1);
    CHECK(is_red(one.pixel(160 - 80, 90)));
    CHECK(log.total() == 0);
    CHECK(s.g.renderer.stats().materialFallbacks.empty());
}

TEST_CASE(
    "sprite buffers: the quad is the sprite's own (its Transform and size) and a flag in the buffer hides an instance, "
    "with no CPU round trip") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the template quad is not drawn", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    ErrorLog log;
    World w;
    camera2d(w);
    add_instanced(w, kSprite, Json::object({{"points", id}}), 5);
    fill(s.compute(), id, 5);
    CHECK(count_runs(s.g.render(w)) == 5);
    fill(s.compute(), id, 5, 2);  // the compute pass clears the flag of instance 2: vertex() collapses it
    const Image hidden = s.g.render(w);
    CHECK(count_runs(hidden) == 4);
    CHECK(!is_red(hidden.pixel(160, 90)));
    fill(s.compute(), id, 5, 4);  // another flag, the same entity and the same draw call
    CHECK(count_runs(s.g.render(w)) == 4);
    // The Transform and size reach vertex() through the quad's corners: a smaller sprite is a smaller instance.
    World w2;
    camera2d(w2);
    Entity e = add_instanced(w2, kSprite, Json::object({{"points", id}}), 5);
    w2.get<Sprite>(e)->size = {6, 6};
    fill(s.compute(), id, 5);
    const Image small = s.g.render(w2);
    CHECK(count_runs(small) == 5);
    CHECK(is_red(small.pixel(160, 90)));
    CHECK(!is_red(small.pixel(160 + 6, 90)));  // 10 px wide would still be red here
    CHECK(log.total() == 0);
}

TEST_CASE(
    "sprite buffers: a missing, destroyed or wrong buffer is a teaching error once, and the sprite is not drawn") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the buffer errors are not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    auto scale = s.compute().create_buffer(kScale, "items", 8);
    REQUIRE_MESSAGE(scale.ok(), scale.error().to_string());
    auto frame = [&](Json params, int instances) {
        World w;
        camera2d(w);
        add_instanced(w, kSprite, std::move(params), instances);
        return s.g.render(w);
    };
    ErrorLog log;
    // No id at all.
    CHECK(count_runs(frame(Json::object(), 5)) == 0);
    CHECK(count_runs(frame(Json::object(), 5)) == 0);
    CHECK(log.count("/materialParams/points") == 1);  // reported once, not every frame
    CHECK(log.count("does not give its compute buffer id") == 1);
    CHECK(log.count("Sprite") >= 1);
    CHECK(s.g.renderer.stats().sprites == 0);  // not drawn, so not counted
    CHECK(s.g.renderer.stats().drawCalls == 0);
    // Not an integer.
    CHECK(count_runs(frame(Json::object({{"points", "oops"}}), 5)) == 0);
    CHECK(log.count("an integer") == 1);
    // A buffer of another shape.
    CHECK(count_runs(frame(Json::object({{"points", *scale}}), 5)) == 0);
    CHECK(log.count("another layout") == 1);
    // More instances than the buffer holds.
    CHECK(count_runs(frame(Json::object({{"points", id}}), 20)) == 0);
    CHECK(log.count("/instances") == 1);
    CHECK(log.count("holds 8 elements") == 1);
    // More than the cap, and a negative count.
    CHECK(count_runs(frame(Json::object({{"points", id}}), -3)) == 0);
    CHECK(log.count("outside 0..") == 1);
    // A destroyed buffer.
    REQUIRE(s.compute().destroy_buffer(id).ok());
    CHECK(count_runs(frame(Json::object({{"points", id}}), 5)) == 0);
    CHECK(log.count("no compute buffer") == 1);
    CHECK(s.g.renderer.stats().materialFallbacks.empty());  // the material itself is fine
}

TEST_CASE("sprite buffers: every buffer the material reads must hold one element per instance") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the short second buffer is not run", why);
        return;
    }
    const int points = make_buffer(s.compute(), 8);
    const int shortOne = make_buffer(s.compute(), 3);
    const int extra = make_buffer(s.compute(), 8);
    fill(s.compute(), points, 5);
    fill(s.compute(), shortOne, 3);
    fill(s.compute(), extra, 5);
    auto frame = [&](int second, int instances) {
        World w;
        camera2d(w);
        add_instanced(w, kSprite2, Json::object({{"points", points}, {"extra", second}}), instances);
        return s.g.render(w);
    };
    ErrorLog log;
    // `points` holds 8 elements, `extra` only 3: five instances would read `extra` past its end.
    CHECK(count_runs(frame(shortOne, 5)) == 0);
    CHECK(count_runs(frame(shortOne, 5)) == 0);
    CHECK(log.count("/instances") == 1);
    CHECK(log.count("the buffer 'extra'") == 1);
    CHECK(log.count("holds 3 elements") == 1);
    CHECK(s.g.renderer.stats().sprites == 0);
    // Three instances fit both, and so do five with a second buffer of 8.
    CHECK(count_runs(frame(shortOne, 3)) == 3);
    CHECK(count_runs(frame(extra, 5)) == 5);
    CHECK(log.count("/instances") == 1);
}

TEST_CASE("sprite buffers: two sprites with the same buffer and the same params are two draws, never one batch") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the batch isolation is not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 3);
    ErrorLog log;
    World w;
    camera2d(w);
    add_instanced(w, kSprite, Json::object({{"points", id}}), 3, {0, 30, 0});
    add_instanced(w, kSprite, Json::object({{"points", id}}), 3, {0, -30, 0});
    const Image img = s.g.render(w);
    const RenderStats& st = s.g.renderer.stats();
    CHECK(st.sprites == 2);
    CHECK(st.drawCalls == 2);  // one per sprite: a merged batch would draw only the first sprite's quad
    CHECK(count_runs(img, 90 - 30) == 3);
    CHECK(count_runs(img, 90 + 30) == 3);
    // A sprite of the same material with the other buffer is its own draw too, and a plain sprite does not change them.
    const int other = make_buffer(s.compute(), 8);
    fill(s.compute(), other, 5);
    World w2;
    camera2d(w2);
    add_instanced(w2, kSprite, Json::object({{"points", id}}), 3, {0, 30, 0});
    add_instanced(w2, kSprite, Json::object({{"points", other}}), 5, {0, -30, 0});
    const Image img2 = s.g.render(w2);
    CHECK(count_runs(img2, 90 - 30) == 3);
    CHECK(count_runs(img2, 90 + 30) == 5);  // not the first sprite's buffer in both
    CHECK(s.g.renderer.stats().drawCalls == 2);
    CHECK(log.total() == 0);
}

TEST_CASE("sprite buffers: instances on a material without buffers draws nothing and says why; other items refuse a "
          "buffers material") {
    Scope s;
    ErrorLog log;
    {
        World w;
        camera2d(w);
        Entity e = make(w, "plain", {0, 0, 0});
        auto& sp = w.add<Sprite>(e);
        sp.size = {20, 20};
        sp.instances = 4;
        s.g.render(w);
        s.g.render(w);
        CHECK(log.count("/instances") == 1);
        CHECK(s.g.renderer.stats().sprites == 0);
    }
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the Shape2D with a buffers material is not run", why);
        return;
    }
    // A Shape2D (or any 2D item that is not a Sprite) cannot give a material its buffers: it is not drawn, the log says
    // why once.
    World w;
    camera2d(w);
    Entity e = make(w, "shape", {0, 0, 0});
    auto& sh = w.add<Shape2D>(e);
    sh.shape = ShapeType::Rectangle;
    sh.size = {50, 50};
    sh.color = Color::white();
    sh.material = kSprite;
    const Image img = s.g.render(w);
    s.g.render(w);
    CHECK(log.count("only a Sprite can draw from buffers") == 1);
    CHECK(!is_red(img.pixel(160, 90)));
    CHECK(img.pixel(160, 90).r < 0.1f);  // nothing drawn, not even magenta
}

TEST_CASE(
    "sprite buffers: a backend that cannot read storage buffers in a vertex shader refuses the material at load") {
    Scope s;
    using FB = render::FeatureBackend;
    for (FB backend : {FB::Gles3, FB::WebGl2}) {
        s.g.renderer.clear_asset_cache();
        install_materials();
        ComputeTestAccess::set_backend(s.compute(), int(backend));
        ErrorLog log;
        World w;
        camera2d(w);
        add_instanced(w, kSprite, Json::object({{"points", 1}}), 4);
        s.g.render(w);
        s.g.render(w);
        CHECK(log.count(render::feature_backend_label(backend)) >= 1);
        CHECK(log.count("storage buffers") >= 1);
        CHECK(log.count("CPU path") >= 1);
        REQUIRE(s.g.renderer.stats().materialFallbacks.size() == 1);  // drawn with the error material, never a crash
        CHECK(s.g.renderer.stats().materialFallbacks[0] == kSprite);
    }
}

TEST_CASE("sprite buffers: a driver with too few storage buffer bindings refuses the material at load and says so") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the binding limit is not run", why);
        return;
    }
    const int points = make_buffer(s.compute(), 8);
    const int extra = make_buffer(s.compute(), 8);
    fill(s.compute(), points, 5);
    auto draw = [&](const char* material, Json params) {
        s.g.renderer.clear_asset_cache();
        install_materials();
        World w;
        camera2d(w);
        add_instanced(w, material, std::move(params), 5);
        return count_runs(s.g.render(w));
    };
    // A driver that offers 2 bindings: one buffer takes 2 (vertex and fragment copy), two take 4.
    ComputeTestAccess::set_binding_limit(s.compute(), 2);
    {
        ErrorLog log;
        CHECK(draw(kSprite, Json::object({{"points", points}})) == 5);
        CHECK(log.count("storage buffer bindings") == 0);
    }
    {
        ErrorLog log;
        CHECK(draw(kSprite2, Json::object({{"points", points}, {"extra", extra}})) == 0);
        CHECK(log.count("takes 4 storage buffer bindings") >= 1);
        CHECK(log.count("offers 2") >= 1);
        CHECK(s.g.renderer.stats().materialFallbacks.size() == 1);  // the error material, never a crash
    }
    ComputeTestAccess::set_binding_limit(s.compute(), -1);
    s.g.renderer.clear_asset_cache();
}

namespace {

// Whether any pixel of the picture is lit: the clear colour is black, and the magenta of a failed material counts as
// lit.
bool any_lit(const Image& img) {
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            if (std::max({c.r, c.g, c.b}) > 0.3f) return true;
        }
    return false;
}

// Puts one white item of kind `kind` in the world (the 2D items that are not a Sprite or a Shape2D) with `material`.
void add_other_item(World& w, const std::string& kind, const char* material) {
    if (kind == "Text") {
        Entity e = make(w, "text", {0, 0, 0});
        auto& t = w.add<Text>(e);
        t.text = "MMMM";
        t.fontSize = 48;
        t.color = Color::white();
        t.material = material;
    } else if (kind == "Tilemap") {
        Entity e = make(w, "tiles", {0, 0, 0});
        auto& tm = w.add<Tilemap>(e);
        tm.tileset = "assets/sprite_buffer_tiles.png";
        tm.tileSize = {16, 16};
        tm.columns = 2;
        tm.width = 2;
        tm.height = 1;
        set_tilemap_tiles(tm, Json::array({0, 1}));
        tm.material = material;
    } else if (kind == "ParticleEmitter") {
        Entity e = make(w, "fx", {0, 0, 0});
        auto& p = w.add<ParticleEmitter>(e);
        p.rate = 0;
        p.burst = 20;
        p.lifetime = 5.0f;
        p.speed = 0;
        p.gravity = {0, 0, 0};
        p.startSize = p.endSize = 20;
        p.startColor = p.endColor = Color::white();
        p.material = material;
    } else {  // Panel: a UiBox widget
        Entity e = make(w, "panel", {160, 90, 0});
        auto& pn = w.add<Panel>(e);
        pn.size = {60, 30};
        pn.color = Color::white();
        pn.material = material;
    }
}

// Clears the renderer's hook when the test leaves, whichever way.
struct HookScope {
    HookScope(Gfx& g, std::function<void()> hook) : g_(g) {
        render::renderer_set_before_frame_graph(g_.renderer, std::move(hook));
    }
    ~HookScope() { render::renderer_set_before_frame_graph(g_.renderer, {}); }
    HookScope(const HookScope&) = delete;
    HookScope& operator=(const HookScope&) = delete;
    Gfx& g_;
};

}  // namespace

TEST_CASE(
    "sprite buffers: Text, Tilemap, ParticleEmitter and UiBox with a buffers material are not drawn and say why") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the items that are not a Sprite are not run", why);
        return;
    }
    Image sheet;
    sheet.width = 32;
    sheet.height = 16;
    sheet.rgba.resize(32 * 16 * 4);
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 32; ++x) sheet.set_pixel(x, y, Color::white());
    REQUIRE(save_png(sheet, "assets/sprite_buffer_tiles.png").ok());
    const int id = make_buffer(s.compute(), 4);
    fill(s.compute(), id, 4);
    for (const std::string kind : {"Text", "Tilemap", "ParticleEmitter", "Panel"}) {
        CAPTURE(kind);
        s.g.renderer.clear_asset_cache();
        install_materials();
        // The same item with no material is visible, so a dark picture below is the material's doing.
        {
            World w;
            camera2d(w);
            add_other_item(w, kind, "");
            Image img;
            for (int i = 0; i < 3; ++i) img = s.g.render(w, 1.0f / 60.0f);
            REQUIRE(any_lit(img));
        }
        ErrorLog log;
        World w;
        camera2d(w);
        add_other_item(w, kind, kSprite);
        Image img;
        for (int i = 0; i < 3; ++i) img = s.g.render(w, 1.0f / 60.0f);
        CHECK(!any_lit(img));  // nothing drawn, not even the magenta of the error material
        CHECK(log.count("only a Sprite can draw from buffers") == 1);  // once, not every frame
        CHECK(s.g.renderer.stats().materialFallbacks.empty());
    }
}

TEST_CASE("sprite buffers: a buffer destroyed between the gather and the draw skips the batch with a warning") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the buffer destroyed at draw time is not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    World w;
    camera2d(w);
    add_instanced(w, kSprite, Json::object({{"points", id}}), 5);
    CHECK(count_runs(s.g.render(w)) == 5);  // drawn normally first
    ErrorLog log;
    {
        // The gather finds the buffer (it is alive when the frame is gathered); the hook destroys it before the passes
        // run.
        Compute& compute = s.compute();
        HookScope hook(s.g, [&compute, id] { (void)compute.destroy_buffer(id); });
        const Image img = s.g.render(w);
        CHECK(count_runs(img) == 0);  // the batch is skipped: nothing is read from a buffer that is gone
        CHECK(s.g.renderer.stats().drawCalls == 0);
    }
    CHECK(log.count("Sprite drawn with") == 1);
    // The next frames fail at the gather, with the message of a missing buffer, and do not crash either.
    CHECK(count_runs(s.g.render(w)) == 0);
    CHECK(count_runs(s.g.render(w)) == 0);
    CHECK(log.count("Sprite drawn with") == 1);
}

TEST_CASE("sprite buffers: instances that change every frame log the buffer-too-small error once, not once per value") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the changing instances are not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    ErrorLog log;
    for (int instances : {20, 21, 22, 23}) {
        World w;
        camera2d(w);
        add_instanced(w, kSprite, Json::object({{"points", id}}), instances);
        CHECK(count_runs(s.g.render(w)) == 0);
    }
    CHECK(log.count("holds 8 elements") == 1);  // the first value is logged, the next ones share its key
    CHECK(log.count("the buffer 'points'") == 1);
}
