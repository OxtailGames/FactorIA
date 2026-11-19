// Post-process materials (M72.2, docs/shaders/SHADERS_POST.md): the entries of PostProcess.customPasses are drawn as full-screen
// passes of the post stack by the compiled program of a kind "post" material (src/renderer_custom_post.cpp, shaders/post_common.glsl). The
// fixtures are tests/data/materials/*post_*: their twins are committed for the backends the render tests run on
// (tools/common/tests/shaders_fixtures_test.cpp keeps them current).
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/render/compute.h"
#include "fa/scene/postprocess.h"
#include "frame_graph.h"
#include "postprocess.h"
#include "renderer_custom_post.h"
#include "renderer_test_access.h"

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

struct MaterialScope {
    MaterialScope() {
        gfx().renderer.clear_asset_cache();
        gfx().renderer.reset_post_history();  // an earlier test's world may have had a camera with the same id
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

constexpr const char* kEmpty = "materials/post_empty.material.json";
constexpr const char* kTint = "materials/post_tint.material.json";
constexpr const char* kUv = "materials/post_uv.material.json";
constexpr const char* kDepth = "materials/post_depth.material.json";
constexpr const char* kTex = "materials/post_tex.material.json";

void near(const Color& got, float r, float g, float b, float tol = kTol) {
    CHECK(std::fabs(got.r - r) <= tol);
    CHECK(std::fabs(got.g - g) <= tol);
    CHECK(std::fabs(got.b - b) <= tol);
}

// An entry of PostProcess.customPasses.
Json entry(const char* material, const char* position = nullptr, Json params = Json::object(), bool enabled = true) {
    Json e = Json::object({{"material", material}});
    if (!params.empty()) e["materialParams"] = std::move(params);
    if (position) e["position"] = position;
    if (!enabled) e["enabled"] = false;
    return e;
}
Json tint(double r, double g, double b) { return Json::object({{"tint", Json::array({r, g, b, 1.0})}}); }

// A 2D world: a white 60x40 sprite at the middle of the 320x180 picture on a black clear colour.
struct Scene2d {
    World w;
    Entity cam = kNullEntity;
    Entity sprite = kNullEntity;
    Scene2d() {
        cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color::black();
        Entity e = sprite = make(w, "sprite", {0, 0, 0});
        auto& s = w.add<Sprite>(e);
        s.size = {60, 40};
        s.color = Color{1, 1, 1, 1};
    }
    PostProcess& post() {
        PostProcess* p = w.get<PostProcess>(cam);
        return p ? *p : w.add<PostProcess>(cam);
    }
    void passes(const std::vector<Json>& list) {
        Json a = Json::array();
        for (const Json& e : list) a.push_back(e);
        post().customPasses = std::move(a);
    }
};

// A 3D world: an unlit white cube (2 m) at the origin, the camera at (0, 0, 10) looking down -Z, a black sky.
struct Scene3d {
    World w;
    Entity cam = kNullEntity;
    Scene3d() {
        cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        Entity e = make(w, "cube", {0, 0, 0});
        w.get<Transform>(e)->scale = {2, 2, 2};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "cube";
        m.color = Color::white();
        m.unlit = true;
    }
    PostProcess& post() {
        PostProcess* p = w.get<PostProcess>(cam);
        return p ? *p : w.add<PostProcess>(cam);
    }
};

std::vector<std::string> graph_order(Gfx& g) {
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}
int index_of(const std::vector<std::string>& names, const std::string& part) {
    for (std::size_t i = 0; i < names.size(); ++i)
        if (names[i].find(part) != std::string::npos) return int(i);
    return -1;
}
int count_of(const std::vector<std::string>& names, const std::string& part) {
    return int(std::count_if(names.begin(), names.end(),
                             [&](const std::string& n) { return n.find(part) != std::string::npos; }));
}

}  // namespace

TEST_CASE("post materials: a material with an empty snippet draws the picture as it was") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    const Image without = g.render(s.w);
    s.passes({entry(kEmpty)});
    const Image with = g.render(s.w);
    CHECK(diff_images(without, with, 2.0f / 255.0f).maxError <= 2.0 / 255.0);
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(count_of(graph_order(g), "custom-bloom-pass0") == 1);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a tint material multiplies the picture and materialParams changes the tint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    s.passes({entry(kTint)});
    Image img = g.render(s.w);
    near(img.pixel(160, 90), 1.0f, 0.25f, 0.25f);  // the default tint
    near(img.pixel(20, 20), 0, 0, 0);              // black stays black
    s.passes({entry(kTint, nullptr, tint(0.0, 1.0, 0.0))});
    img = g.render(s.w);
    near(img.pixel(160, 90), 0.0f, 1.0f, 0.0f);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: uv runs left to right and top to bottom, and time follows the engine clock") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    Scene2d s;
    s.passes({entry(kUv)});
    Image img = g.render(s.w);
    for (const auto& p : {std::pair<int, int>{40, 20}, {280, 40}, {100, 150}, {300, 170}}) {
        CAPTURE(p.first);
        CAPTURE(p.second);
        near(img.pixel(p.first, p.second), (float(p.first) + 0.5f) / 320.0f, (float(p.second) + 0.5f) / 180.0f, 0.0f);
    }
    // The blue channel is a quarter of the seconds: it grows with the world's clock.
    for (int i = 0; i < 120; ++i) s.w.advance_clock(1.0 / 60.0);
    img = g.draw(s.w);
    near(img.pixel(40, 20), 40.5f / 320.0f, 20.5f / 180.0f, 0.5f);
}

TEST_CASE("post materials: the depth and normals are made only when a material reads them, and read by pixel") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene3d s;
    s.post().customPasses = Json::array({entry(kTint)});
    g.render(s.w);
    CHECK(index_of(graph_order(g), "/prepass") < 0);  // a tint reads neither
    s.post().customPasses = Json::array({entry(kDepth)});
    const Image img = g.render(s.w);
    CHECK(index_of(graph_order(g), "/prepass") >= 0);
    // The cube's front face is 9 m from the camera and faces it; the sky has no depth (60000: clamped to 1) and no normal.
    near(img.pixel(160, 90), 9.0f / 20.0f, 0.5f, 0.5f);
    near(img.pixel(10, 10), 1.0f, 0.5f, 0.5f);
    CHECK(log.messages().empty());
    // A camera with no opaque mesh gets an empty prepass: nothing drawn, depth 60000.
    World w;
    Entity cam = make(w, "cam", {0, 0, 10});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
    w.add<PostProcess>(cam).customPasses = Json::array({entry(kDepth)});
    const Image empty = g.render(w);
    near(empty.pixel(160, 90), 1.0f, 0.5f, 0.5f);
    CHECK(log.messages().empty());
}

TEST_CASE(
    "post materials: a material's texture is bound after the engine's two views, and amount 0 leaves the picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    const Image without = g.render(s.w);
    s.passes({entry(kTex, nullptr, Json::object({{"amount", 0.0}}))});
    CHECK(diff_images(without, g.render(s.w), 2.0f / 255.0f).maxError <= 2.0 / 255.0);
    s.passes({entry(kTex)});
    const Image shown = g.render(s.w);
    // Amount 1: the whole picture is one texel of the texture, wherever the sprite was.
    const Color a = shown.pixel(20, 20), b = shown.pixel(160, 90), c = shown.pixel(300, 170);
    near(b, a.r, a.g, a.b, 2.0f / 255.0f);
    near(c, a.r, a.g, a.b, 2.0f / 255.0f);
    CHECK(diff_images(without, shown, 2.0f / 255.0f).maxError > 0.1);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a chain of passes reads what the one before wrote, with two or three images in turn") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    s.passes({entry(kTint, nullptr, tint(0.5, 1.0, 1.0)), entry(kTint, nullptr, tint(1.0, 0.5, 1.0))});
    Image img = g.render(s.w);
    near(img.pixel(160, 90), 0.5f, 0.5f, 1.0f);
    s.passes({entry(kTint, nullptr, tint(0.5, 1.0, 1.0)), entry(kTint, nullptr, tint(1.0, 0.5, 1.0)),
              entry(kTint, nullptr, tint(1.0, 1.0, 0.5))});
    img = g.render(s.w);
    near(img.pixel(160, 90), 0.5f, 0.5f, 0.5f);
    s.passes({entry(kTint, nullptr, tint(0.5, 1.0, 1.0)), entry(kTint, nullptr, tint(1.0, 0.5, 1.0)),
              entry(kTint, nullptr, tint(1.0, 1.0, 0.5)), entry(kTint, nullptr, tint(0.5, 1.0, 1.0))});
    img = g.render(s.w);
    near(img.pixel(160, 90), 0.25f, 0.5f, 0.5f);
    near(img.pixel(20, 20), 0, 0, 0);
    CHECK(count_of(graph_order(g), "custom-bloom-pass") == 4);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: an entry says where it goes, relative to the built-in passes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene3d s;
    PostProcess& p = s.post();
    p.bloomEnabled = true;
    p.bloomThreshold = 0.0f;
    p.depthOfFieldEnabled = true;
    p.depthOfFieldFocusDistance = 9.0f;
    p.customPasses =
        Json::array({entry(kTint, "before:bloom"), entry(kTint, "after:bloom"), entry(kTint, "before:depthOfField"),
                     entry(kTint, "after:ssao"), entry(kTint, "after:motionBlur")});
    g.render(s.w);
    const std::vector<std::string> order = graph_order(g);
    const int main = index_of(order, "custom-main-pass0");
    const int shafts = index_of(order, "custom-shafts-pass0");
    const int dof = index_of(order, "custom-dof-pass0");
    const int bloom = index_of(order, "custom-bloom-pass0");
    const int bloomPass = index_of(order, "bloom-bright");
    const int dofPass = index_of(order, "dof-down");
    CAPTURE(order.size());
    REQUIRE(main >= 0);
    REQUIRE(shafts >= 0);
    REQUIRE(dof >= 0);
    REQUIRE(bloom >= 0);
    REQUIRE(bloomPass >= 0);
    REQUIRE(dofPass >= 0);
    CHECK(main < dofPass);     // after:ssao
    CHECK(shafts < dofPass);   // before:depthOfField
    CHECK(dofPass < dof);      // after:motionBlur
    CHECK(dof < bloomPass);    // before:bloom
    CHECK(bloomPass < bloom);  // after:bloom
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a disabled entry draws nothing and is not a fallback") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    const Image without = g.render(s.w);
    s.passes({entry("materials/not_there.material.json", nullptr, Json::object(), false)});
    const Image img = g.render(s.w);
    CHECK(diff_images(without, img, 0.0f).maxError == 0.0);
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(index_of(graph_order(g), "custom-") < 0);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a material that does not build, or is not a post material, skips its pass once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    REQUIRE(fs::write_text("materials/post_broken.material.json",
                           R"({"format": "factoria.material/1", "kind": "post", "shader": "shaders/broken.post.glsl"})")
                .ok());
    const std::string dialect = g.renderer.shader_dialect();
    // Stands in for the tooling: the fixtures have their twins, the broken material does not compile.
    g.renderer.set_shader_compiler([dialect](const std::string& path, const std::string&) -> Result<Json> {
        if (path.find("broken") != std::string::npos)
            return make_error("shaders/broken.post.glsl:3:5: error: 'colour' : no such field in structure "
                              "'PostSurface'\n  hint: did you mean color?",
                              "did you mean color?");
        return load_json_file(path + "." + dialect + ".shader");
    });
    ProblemLog log;
    Scene2d s;
    const Image without = g.render(s.w);
    // The broken material, a mesh material, a file that is not there: each is skipped, the good one still draws.
    s.passes({entry("materials/post_broken.material.json"), entry("materials/glow.material.json"),
              entry("materials/missing.material.json"), entry(kTint)});
    Image img;
    for (int i = 0; i < 3; ++i) img = g.render(s.w);
    near(img.pixel(160, 90), 1.0f, 0.25f, 0.25f);
    const std::vector<std::string>& fallbacks = g.renderer.stats().materialFallbacks;
    CHECK(fallbacks.size() == 3);
    CHECK(std::find(fallbacks.begin(), fallbacks.end(), "materials/post_broken.material.json") != fallbacks.end());
    CHECK(std::find(fallbacks.begin(), fallbacks.end(), "materials/glow.material.json") != fallbacks.end());
    CHECK(std::find(fallbacks.begin(), fallbacks.end(), "materials/missing.material.json") != fallbacks.end());
    CHECK(log.count("Custom post pass 'materials/post_broken.material.json'") == 1);  // not once per frame
    CHECK(log.count("Custom post pass 'materials/glow.material.json'") == 1);
    CHECK(log.count("Custom post pass 'materials/missing.material.json'") == 1);
    CHECK(log.count("needs a \"post\" material") == 1);
    // Only the broken ones: the picture is the one without passes.
    s.passes({entry("materials/post_broken.material.json"), entry("materials/glow.material.json")});
    img = g.render(s.w);
    CHECK(diff_images(without, img, 2.0f / 255.0f).maxError <= 2.0 / 255.0);
}

TEST_CASE(
    "materials: the error of a material that does not build says what happens to its kind, not 'magenta' for all") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    g.renderer.set_shader_compiler([](const std::string& path, const std::string&) -> Result<Json> {
        return make_error("shaders/broken.glsl:3:5: error: nothing compiles in " + path, "fix the shader");
    });
    for (const char* kind : {"post", "sky", "compute", "mesh"}) {
        const std::string path = std::string("materials/broken_") + kind + ".material.json";
        REQUIRE(fs::write_text(path, std::string(R"({"format": "factoria.material/1", "kind": ")") + kind +
                                         R"(", "shader": "shaders/broken.glsl"})")
                    .ok());
    }
    ProblemLog log;
    {
        Scene2d s;
        s.passes({entry("materials/broken_post.material.json")});
        g.render(s.w);
        World sky;
        sky.add<Camera>(make(sky, "cam"));
        sky.settings().skyMaterial = "materials/broken_sky.material.json";
        g.render(sky);
    }
    if (g.renderer.compute().available())
        (void)g.renderer.compute().create_buffer("materials/broken_compute.material.json", "buf", 1);
    CHECK(log.count("The custom post passes using it are skipped.") == 1);
    CHECK(log.count("The sky using it is drawn as the built-in gradient.") == 1);
    if (g.renderer.compute().available()) CHECK(log.count("The compute.* commands that name it fail") == 1);
    CHECK(log.count("drawn magenta") == 0);
}

TEST_CASE("post materials: hot reload swaps the shader, keeps the last good one on a broken edit and recovers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    REQUIRE(fs::write_text("materials/post_hot.material.json",
                           R"({"format": "factoria.material/1", "kind": "post", "shader": "shaders/hot.txt",
                               "params": {"tint": {"type": "color", "default": [1.0, 0.25, 0.25, 1.0], "doc": "Tint."}}})")
                .ok());
    // Stands in for the tooling: the snippet on disk names the fixture twin to use ("post_tint" or "post_empty"), or is broken.
    g.renderer.set_shader_compiler([dialect](const std::string&, const std::string&) -> Result<Json> {
        auto snippet = fs::read_text("shaders/hot.txt");
        if (!snippet.ok()) return snippet.error();
        if (*snippet == "broken")
            return make_error("shaders/hot.txt:1:1: error: 'broken' : undeclared identifier",
                              "Write post_tint or post_empty.");
        return load_json_file("materials/" + *snippet + ".material.json." + dialect + ".shader");
    });
    Scene2d s;
    s.passes({entry("materials/post_hot.material.json")});
    ProblemLog log;
    REQUIRE(fs::write_text("shaders/hot.txt", "post_tint").ok());
    const Image tinted = g.render(s.w);
    near(tinted.pixel(160, 90), 1.0f, 0.25f, 0.25f);
    REQUIRE(fs::write_text("shaders/hot.txt", "post_empty").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image plain = g.render(s.w);
    near(plain.pixel(160, 90), 1.0f, 1.0f, 1.0f);
    CHECK(log.messages().empty());

    REQUIRE(fs::write_text("shaders/hot.txt", "broken").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image kept = g.render(s.w);
    g.render(s.w);
    CHECK(diff_images(plain, kept, 0.0f).maxError == 0.0);
    CHECK(log.count("shaders/hot.txt:1:1") == 1);
    CHECK(g.renderer.stats().materialFallbacks.empty());

    REQUIRE(fs::write_text("shaders/hot.txt", "post_tint").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image back = g.render(s.w);
    CHECK(diff_images(tinted, back, 0.0f).maxError == 0.0);
    CHECK(log.messages().size() == 1);
}

TEST_CASE("post materials: a camera of a split screen draws its pass over its own rectangle only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    World w;
    auto camera = [&](const char* name, Vec3 pos, Rect viewport, int depth) {
        Entity e = make(w, name, pos);
        auto& c = w.add<Camera>(e);
        c.viewport = viewport;
        c.clearColor = Color::black();
        c.depth = depth;
        return e;
    };
    Entity left = camera("left", {0, 0, 0}, {0, 0, 0.5f, 1}, 0);
    camera("right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, 1);
    for (const float x : {0.0f, 500.0f}) {
        Entity e = make(w, "square", {x, 0, 0});
        auto& sh = w.add<Shape2D>(e);
        sh.shape = ShapeType::Rectangle;
        sh.size = {40, 40};
        sh.color = Color{1, 1, 1, 1};
    }
    w.add<PostProcess>(left).customPasses = Json::array({entry(kTint)});
    const Image img = g.render(w);
    near(img.pixel(80, 90), 1.0f, 0.25f, 0.25f);  // the left camera's square, tinted
    near(img.pixel(240, 90), 1.0f, 1.0f, 1.0f);   // the right camera's, not
    near(img.pixel(10, 10), 0, 0, 0);
    near(img.pixel(310, 170), 0, 0, 0);
    CHECK(log.messages().empty());
}

// ---- the places between the screen effects (display-referred; the final pass is cut there) -------------------------------------

namespace {

// How many passes of the frame draw the final pass of post.glsl, whole or in pieces: "post" and "post-part<k>" (job/ prefix kept).
int final_pieces(const std::vector<std::string>& order) {
    int n = 0;
    for (const std::string& s : order) {
        const std::size_t slash = s.rfind('/');
        const std::string leaf = slash == std::string::npos ? s : s.substr(slash + 1);
        if (leaf == "post" || leaf.rfind("post-part", 0) == 0) ++n;
    }
    return n;
}

// The index of the last piece of the final pass (the one that draws to the picture's destination).
int last_final_piece(const std::vector<std::string>& order) {
    for (int i = int(order.size()) - 1; i >= 0; --i) {
        const std::string& s = order[std::size_t(i)];
        const std::size_t slash = s.rfind('/');
        if ((slash == std::string::npos ? s : s.substr(slash + 1)) == "post") return i;
    }
    return -1;
}

}  // namespace

TEST_CASE("post materials: a frame with no custom pass keeps its one final pass, a display-referred entry cuts it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    PostProcess& p = s.post();
    p.vignetteEnabled = true;
    p.vignetteIntensity = 0.5f;
    p.sharpenEnabled = true;
    p.posterizeEnabled = true;
    p.posterizeLevels = 16;
    g.render(s.w);
    std::vector<std::string> order = graph_order(g);
    CHECK(final_pieces(order) == 1);
    CHECK(count_of(order, "post-part") == 0);
    const std::size_t plain = order.size();

    // A pass before the tonemap (scene-linear) does not cut it either: more passes for the custom pass, the same final pass.
    s.passes({entry(kTint, "before:tonemap")});
    g.render(s.w);
    order = graph_order(g);
    CHECK(final_pieces(order) == 1);
    CHECK(count_of(order, "post-part") == 0);
    CHECK(order.size() > plain);

    // Between two effects: the final pass is drawn in two pieces, the custom pass between them.
    s.passes({entry(kTint, "after:vignette")});
    g.render(s.w);
    order = graph_order(g);
    CHECK(final_pieces(order) == 2);
    const int part = index_of(order, "post-part0");
    const int pass = index_of(order, "custom-vignette-pass0");
    REQUIRE(part >= 0);
    REQUIRE(pass >= 0);
    CHECK(part < pass);

    // Dropping the entry gives the old graph back, pass for pass.
    s.passes({});
    g.render(s.w);
    CHECK(graph_order(g).size() == plain);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: every display-referred position cuts the final pass once, with the effects before it in the "
          "first piece") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    const char* positions[] = {"after:tonemap", "after:colorGrading", "after:vignette", "after:sharpen",
                               "after:outline", "after:posterize",    "after:filmGrain"};
    const char* names[] = {"tonemap", "grading", "vignette", "sharpen", "outline", "posterize", "grain"};
    for (int i = 0; i < 7; ++i) {
        INFO(positions[i]);
        Scene2d s;
        PostProcess& p = s.post();
        p.tonemapEnabled = true;
        p.colorGradingEnabled = true;
        p.vignetteEnabled = true;
        p.vignetteIntensity = 0.1f;
        p.sharpenEnabled = true;
        p.outlineEnabled = true;
        p.outlineMode = OutlineMode::Sprite;
        p.posterizeEnabled = true;
        p.posterizeLevels = 64;
        p.filmGrainEnabled = true;
        p.filmGrainIntensity = 0.01f;
        s.passes({entry(kTint, positions[i])});
        const Image img = g.render(s.w);
        const std::vector<std::string> order = graph_order(g);
        const int custom = index_of(order, std::string("custom-") + names[i] + "-pass0");
        REQUIRE(custom >= 0);
        CHECK(final_pieces(order) == 2);  // one cut at the place: the effects before it, the effects after it
        CHECK(index_of(order, "post-part0") < custom);
        CHECK(custom < last_final_piece(order));
        // The sprite's white is tinted red-ish whatever the place; the black around it stays dark.
        const Color c = img.pixel(160, 90);
        CHECK(c.r > c.g + 0.3f);
        CHECK(std::fabs(c.g - c.b) < 0.1f);
        CHECK(img.pixel(40, 20).r < 0.2f);
    }
    CHECK(log.messages().empty());
}

TEST_CASE(
    "post materials: a display-referred pass reads what the effects before it made, the ones after it read its own") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    // The vignette paints the corners white: a tint before it is painted over, a tint after it tints the white too.
    auto corner = [&](const char* position) {
        Scene2d s;
        PostProcess& p = s.post();
        p.vignetteEnabled = true;
        p.vignetteIntensity = 1.0f;
        p.vignetteSmoothness = 0.2f;
        p.vignetteRoundness = 0.0f;
        p.vignetteColor = Color{1, 1, 1, 1};
        s.passes({entry(kTint, position, tint(1.0, 0.5, 0.5))});
        return g.render(s.w).pixel(1, 1);
    };
    near(corner("before:vignette"), 1.0f, 1.0f, 1.0f);
    near(corner("after:vignette"), 1.0f, 0.5f, 0.5f);

    // The posterize cuts a 0.6 grey to a hard 1 (two levels): a tint before it is rounded away, a tint after it stays.
    auto grey = [&](const char* position) {
        Scene2d s;
        s.w.get<Sprite>(s.sprite)->color = Color{0.6f, 0.6f, 0.6f, 1};
        PostProcess& p = s.post();
        p.posterizeEnabled = true;
        p.posterizeLevels = 2;
        s.passes({entry(kTint, position, tint(0.9, 0.9, 0.9))});
        return g.render(s.w).pixel(160, 90);
    };
    near(grey("before:posterize"), 1.0f, 1.0f, 1.0f);
    near(grey("after:posterize"), 0.9f, 0.9f, 0.9f);

    // The grading's saturation 0 makes every channel the same: a tint before it is greyed, a tint after it is not.
    auto graded = [&](const char* position) {
        Scene2d s;
        PostProcess& p = s.post();
        p.colorGradingEnabled = true;
        p.colorGradingSaturation = 0.0f;
        s.passes({entry(kTint, position, tint(1.0, 0.4, 0.4))});
        return g.render(s.w).pixel(160, 90);
    };
    const Color before = graded("after:tonemap");
    CHECK(std::fabs(before.r - before.g) < 0.05f);
    const Color after = graded("after:colorGrading");
    CHECK(after.r > after.g + 0.3f);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: entries at several display-referred places all run, in the order of the places") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    Scene2d s;
    PostProcess& p = s.post();
    p.vignetteEnabled = true;
    p.vignetteIntensity = 0.1f;
    p.posterizeEnabled = true;
    p.posterizeLevels = 64;
    // A disabled entry among them draws nothing; the stack order does not matter between different places.
    s.passes({entry(kTint, "after:posterize", tint(0.5, 1, 1)), entry(kTint, "after:tonemap", tint(1, 0.5, 1)),
              entry(kTint, "after:vignette", tint(1, 1, 0.5), false), entry(kTint, "after:vignette", tint(1, 1, 0.5))});
    const Image img = g.render(s.w);
    near(img.pixel(160, 90), 0.5f, 0.5f, 0.5f);
    const std::vector<std::string> order = graph_order(g);
    CHECK(index_of(order, "custom-tonemap-pass0") < index_of(order, "custom-vignette-pass0"));
    CHECK(index_of(order, "custom-vignette-pass0") < index_of(order, "custom-posterize-pass0"));
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a linear scene with a display-referred pass is still encoded when the LUT does not load") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    auto picture = [&](bool withPass) {
        Scene2d s;
        s.w.settings().colorSpace = ColorSpace::Linear;
        s.w.get<Sprite>(s.sprite)->color = Color{0.5f, 0.5f, 0.5f, 1};
        if (withPass) {
            PostProcess& p = s.post();
            p.colorGradingEnabled =
                true;  // the only effect, and its table is missing: nothing else asks for the conversion
            p.colorGradingLut = "luts/does-not-exist.cube";
            s.passes({entry(kEmpty, "after:vignette")});
        }
        return g.render(s.w).pixel(160, 90);
    };
    const Color plain = picture(false);
    const Color cut = picture(true);
    near(cut, plain.r, plain.g, plain.b, 0.02f);  // not left in linear light (about 0.21 where 0.5 is shown)
    CHECK(cut.r > 0.4f);
}

TEST_CASE("post plan: the cuts of the final pass, and an outline that cannot be drawn keeps the conversion of a "
          "display-referred pass") {
    using namespace fa::render;
    PostPlan pp;
    pp.sceneLinear = true;
    pp.fx.outline = true;
    CustomPostEntry e;
    e.slot = PostSlot::AfterOutline;
    pp.custom.entries.push_back(e);
    pp.settle_custom();
    CHECK(pp.customLdr);
    CHECK(pp.linear);
    CHECK(pp.ldr_cuts() ==
          (1u << kStageOutline));  // the scene stage converts: something is drawn before the outline's place
    pp.skip_outline();
    CHECK_FALSE(pp.fx.outline);
    CHECK(pp.linear);  // the pass still reads an encoded picture
    CHECK(pp.final_pass());
    // Places with nothing drawn between them share a cut; an active stage in between makes a second one.
    PostPlan two;
    two.sceneLinear = true;
    two.fx.vignette = true;
    two.fx.posterize = true;
    for (PostSlot s :
         {PostSlot::AfterTonemap, PostSlot::AfterVignette, PostSlot::AfterSharpen, PostSlot::AfterPosterize}) {
        CustomPostEntry c;
        c.slot = s;
        two.custom.entries.push_back(c);
    }
    two.settle_custom();
    // AfterTonemap: the scene stage (converting) is active -> a cut; AfterVignette: the vignette -> a cut; AfterSharpen: nothing
    // since the last cut -> none; AfterPosterize: the posterize -> a cut.
    CHECK(two.ldr_cuts() == ((1u << kStageScene) | (1u << kStageVignette) | (1u << kStagePosterize)));
}

// ---- history: a pass that reads its own output of the frame before (fa_history) --------------------------------------------------

namespace {

constexpr const char* kHistory = "materials/post_history.material.json";
// `mark`: the pass paints red where fa_history_valid is true.
Json keep(double k, bool mark = false) { return Json::object({{"keep", k}, {"mark", mark ? 1.0 : 0.0}}); }

// MaterialScope that also starts with no history image: the slots of the tests before are freed by drawing frames that ask for none
// (kHistoryIdleFrames of them), so the counts of a test are its own.
struct HistoryScope {
    MaterialScope scope;
    HistoryScope() {
        Scene2d empty;
        for (std::uint64_t i = 0; i < render::CustomPost::kHistoryIdleFrames + 2; ++i) gfx().render(empty.w);
        REQUIRE(render::renderer_post_history_images(gfx().renderer) == 0);
    }
};

}  // namespace

TEST_CASE("post history: a trail stays where the sprite was, fades by keep each frame and is not mirrored") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    Scene2d s;
    s.w.get<Transform>(s.sprite)->position = {0, 40, 0};
    s.passes({entry(kHistory, nullptr, keep(0.5))});
    CHECK(render::renderer_post_history_images(g.renderer) == 0);
    Image img = g.render(s.w);  // the first frame: no history, the picture as it is
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    const int oy = img.pixel(160, 50).r > 0.9f ? 50 : 130;  // where the sprite is on the picture (y up in the world)
    REQUIRE(img.pixel(160, oy).r > 0.9f);
    near(img.pixel(160, 180 - oy), 0, 0, 0);
    s.w.get<Transform>(s.sprite)->position = {100, -40, 0};
    img = g.render(s.w);
    near(img.pixel(260, 180 - oy), 1, 1, 1);     // the sprite now
    near(img.pixel(160, oy), 0.5f, 0.5f, 0.5f);  // its trail, where it was (not mirrored), half as bright
    near(img.pixel(160, 180 - oy), 0, 0, 0);
    near(img.pixel(260, oy), 0, 0, 0);
    img = g.render(s.w);
    near(img.pixel(160, oy), 0.25f, 0.25f, 0.25f);
    img = g.render(s.w);
    near(img.pixel(160, oy), 0.125f, 0.125f, 0.125f);
    near(img.pixel(260, 180 - oy), 1, 1, 1);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);  // the same two images all along
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(log.messages().empty());
}

TEST_CASE("post history: the first frame is the picture, and a reset, a resize and a new scene start it again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    Scene2d s;
    const Image plain = g.render(s.w);
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    Image img = g.render(s.w);
    CHECK(diff_images(plain, img, 2.0f / 255.0f).maxError <= 2.0 / 255.0);  // frame 0: the picture, no garbage
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);  // frame 1: the history is valid
    near(img.pixel(160, 90), 1, 0, 0);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    g.renderer.reset_post_history();  // every camera
    img = g.render(s.w);
    near(img.pixel(20, 20), 0, 0, 0);
    near(img.pixel(160, 90), 1, 1, 1);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    g.renderer.reset_post_history(s.cam.bits());  // this camera
    img = g.render(s.w);
    near(img.pixel(20, 20), 0, 0, 0);
    img = g.render(s.w);
    g.renderer.reset_post_history(s.cam.bits() + 1);  // another camera: nothing happens
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    // A resize (here the camera's rectangle): the images are made again and the first frame has no history.
    s.w.get<Camera>(s.cam)->viewport = Rect{0, 0, 0.75f, 1};
    img = g.render(s.w);
    near(img.pixel(20, 20), 0, 0, 0);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    // A scene load: the world's load count moves, the camera is the same entity.
    s.w.bump_scene_generation();
    img = g.render(s.w);
    near(img.pixel(20, 20), 0, 0, 0);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    // A clock that jumps (a seek) is a cut too.
    for (int i = 0; i < 20; ++i) s.w.advance_clock(0.016);
    img = g.render(s.w);
    near(img.pixel(20, 20), 0, 0, 0);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(log.messages().empty());
}

TEST_CASE("post history: every camera keeps its own history, and a camera not drawn for a frame starts again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    World w;
    auto camera = [&](const char* name, Vec3 pos, Rect viewport, int depth) {
        Entity e = make(w, name, pos);
        auto& c = w.add<Camera>(e);
        c.viewport = viewport;
        c.clearColor = Color::black();
        c.depth = depth;
        return e;
    };
    Entity left = camera("left", {0, 0, 0}, {0, 0, 0.5f, 1}, 0);
    Entity right = camera("right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, 1);
    for (const float x : {0.0f, 500.0f}) {
        Entity e = make(w, "square", {x, 0, 0});
        auto& sh = w.add<Shape2D>(e);
        sh.shape = ShapeType::Rectangle;
        sh.size = {40, 40};
        sh.color = Color{1, 1, 1, 1};
    }
    w.add<PostProcess>(left).customPasses = Json::array({entry(kHistory, nullptr, keep(1.0, true))});
    Image img = g.render(w);
    img = g.render(w);
    near(img.pixel(80, 90), 1, 0, 0);   // the left camera: red, its history is valid
    near(img.pixel(240, 90), 1, 1, 1);  // the right one has no pass
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    // The right camera gets the pass now: its own first frame has no history while the left one's goes on.
    w.add<PostProcess>(right).customPasses = Json::array({entry(kHistory, nullptr, keep(1.0, true))});
    img = g.render(w);
    near(img.pixel(80, 90), 1, 0, 0);
    near(img.pixel(240, 90), 1, 1, 1);
    CHECK(render::renderer_post_history_images(g.renderer) == 4);
    img = g.render(w);
    near(img.pixel(80, 90), 1, 0, 0);
    near(img.pixel(240, 90), 1, 0, 0);
    // The left camera is not drawn for a frame: when it comes back its history starts again, the right one's goes on.
    w.get<Camera>(left)->primary = false;
    img = g.render(w);
    w.get<Camera>(left)->primary = true;
    img = g.render(w);
    near(img.pixel(80, 90), 1, 1, 1);  // not red: the frame before did not draw it
    near(img.pixel(240, 90), 1, 0, 0);
    img = g.render(w);
    near(img.pixel(80, 90), 1, 0, 0);
    CHECK(log.messages().empty());
}

TEST_CASE("post history: a history pass in a chain, first or last, and two of one material, each with its own images") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    Scene2d s;
    s.w.get<Transform>(s.sprite)->position = {0, 40, 0};
    // History first, tint after: the tint multiplies what the history pass wrote.
    s.passes({entry(kHistory, nullptr, keep(0.5)), entry(kTint)});
    Image img = g.render(s.w);
    const int oy = img.pixel(160, 50).r > 0.9f ? 50 : 130;
    near(img.pixel(160, oy), 1.0f, 0.25f, 0.25f);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    s.w.get<Transform>(s.sprite)->position = {100, -40, 0};
    img = g.render(s.w);
    near(img.pixel(160, oy), 0.5f, 0.125f, 0.125f);  // the trail, tinted after it was kept
    // Tint first, history last: the last pass draws into its history image and is copied into the picture.
    s.passes({entry(kTint), entry(kHistory, nullptr, keep(0.5))});
    s.w.get<Transform>(s.sprite)->position = {0, 40, 0};
    g.renderer.reset_post_history();
    img = g.render(s.w);
    near(img.pixel(160, oy), 1.0f, 0.25f, 0.25f);
    s.w.get<Transform>(s.sprite)->position = {100, -40, 0};
    img = g.render(s.w);
    near(img.pixel(260, 180 - oy), 1.0f, 0.25f, 0.25f);
    near(img.pixel(160, oy), 0.5f, 0.125f, 0.125f);  // the tinted sprite's trail
    near(img.pixel(20, 20), 0, 0, 0);
    // The same material twice: two slots.
    s.passes({entry(kHistory, nullptr, keep(0.5, true)), entry(kHistory, nullptr, keep(0.5, true))});
    g.renderer.reset_post_history();
    img = g.render(s.w);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(render::renderer_post_history_images(g.renderer) == 4);
    // A material that does not call fa_history keeps nothing of its own.
    s.passes({entry(kTint)});
    img = g.render(s.w);
    near(img.pixel(260, 180 - oy), 1.0f, 0.25f, 0.25f);
    CHECK(log.messages().empty());
}

TEST_CASE("post history: the images are freed after kHistoryIdleFrames frames nobody asked for them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    Scene2d s;
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    g.render(s.w);
    g.render(s.w);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    s.passes({entry(kTint)});
    for (int i = 0; i < 60; ++i) g.render(s.w);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);  // half of the time: still kept
    for (int i = 0; i < 80; ++i) g.render(s.w);
    CHECK(render::renderer_post_history_images(g.renderer) == 0);
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    Image img = g.render(s.w);  // made again: the first frame has no history
    near(img.pixel(20, 20), 0, 0, 0);
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    CHECK(log.messages().empty());
}

// ---- the cut final pass: its images, a split screen, the multisampled HUD chain, a gamma scene ----------------------------------

namespace {

// A renderer of its own with a sample count (the shared one has the one of FA_TEST_SAMPLES), shut down when the object ends, even when
// a REQUIRE fails in between.
struct OwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit OwnRenderer(Gfx& gx, int samples) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~OwnRenderer() { r.shutdown(); }
    OwnRenderer(const OwnRenderer&) = delete;
    OwnRenderer& operator=(const OwnRenderer&) = delete;
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 1.0f / 60.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    std::vector<std::string> order() {
        const render::FrameGraph* graph = render::renderer_frame_graph(r);
        REQUIRE(graph != nullptr);
        return graph->order_names();
    }
};

// The output of a renderer forced for the life of the object.
struct ForcedOutput {
    Renderer& r;
    ForcedOutput(Renderer& rr, HdrEncoding e, float headroom) : r(rr) {
        HdrOutputInfo i;
        i.requested = true;
        i.active = e != HdrEncoding::Sdr;
        i.encoding = e;
        i.headroom = headroom;
        render::renderer_force_output(r, &i);
    }
    ~ForcedOutput() { render::renderer_force_output(r, nullptr); }
    ForcedOutput(const ForcedOutput&) = delete;
    ForcedOutput& operator=(const ForcedOutput&) = delete;
};

bool usable_format(sg_pixel_format f) {
    const sg_pixelformat_info i = sg_query_pixelformat(f);
    return i.render && i.sample && i.filter;
}

}  // namespace

TEST_CASE(
    "post materials: the images of a cut final pass hold the display format, and a float one with an HDR window") {
    using render::pick_ldr_cut_format;
    // The choice, whatever this GPU can do: an SDR window and a float display keep the display format; an HDR window over an 8-bit one
    // takes the half float, else the full float, else stays.
    CHECK(pick_ldr_cut_format(SG_PIXELFORMAT_RGBA8, false, true, true) == SG_PIXELFORMAT_RGBA8);
    CHECK(pick_ldr_cut_format(SG_PIXELFORMAT_RGBA8, true, true, true) == SG_PIXELFORMAT_RGBA16F);
    CHECK(pick_ldr_cut_format(SG_PIXELFORMAT_RGBA8, true, false, true) == SG_PIXELFORMAT_RGBA32F);
    CHECK(pick_ldr_cut_format(SG_PIXELFORMAT_RGBA8, true, false, false) == SG_PIXELFORMAT_RGBA8);
    CHECK(pick_ldr_cut_format(SG_PIXELFORMAT_RGBA16F, true, true, true) == SG_PIXELFORMAT_RGBA16F);
    CHECK(pick_ldr_cut_format(SG_PIXELFORMAT_RGBA16F, false, false, false) == SG_PIXELFORMAT_RGBA16F);

    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    render::Gpu* gpu = render::renderer_gpu(g.renderer);
    REQUIRE(gpu != nullptr);
    auto cut_picture = [&] {
        Scene2d s;
        PostProcess& p = s.post();
        p.posterizeEnabled = true;
        p.posterizeLevels = 64;
        s.passes({entry(kTint, "after:posterize")});
        g.render(s.w);
        CHECK(final_pieces(graph_order(g)) == 2);
    };
    cut_picture();
    CHECK(render::renderer_ldr_cut_format(g.renderer) == int(gpu->display_format()));
    {
        ForcedOutput hdr(g.renderer, HdrEncoding::ScRgb, 4.0f);
        cut_picture();
        const int format = render::renderer_ldr_cut_format(g.renderer);
        if (usable_format(SG_PIXELFORMAT_RGBA16F) || usable_format(SG_PIXELFORMAT_RGBA32F))
            CHECK((format == int(SG_PIXELFORMAT_RGBA16F) || format == int(SG_PIXELFORMAT_RGBA32F)));
        else
            CHECK(format == int(gpu->display_format()));
        CHECK(format == int(gpu->ldr_cut_format(true)));
    }
    cut_picture();  // the window went back to SDR: the images are made again in the display format
    CHECK(render::renderer_ldr_cut_format(g.renderer) == int(gpu->display_format()));
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a cut final pass in a split screen tints its own camera's rectangle only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    World w;
    auto camera = [&](const char* name, Vec3 pos, Rect viewport, int depth) {
        Entity e = make(w, name, pos);
        auto& c = w.add<Camera>(e);
        c.viewport = viewport;
        c.clearColor = Color::black();
        c.depth = depth;
        return e;
    };
    Entity left = camera("left", {0, 0, 0}, {0, 0, 0.5f, 1}, 0);
    camera("right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, 1);
    for (const float x : {0.0f, 500.0f}) {
        Entity e = make(w, "square", {x, 0, 0});
        auto& sh = w.add<Shape2D>(e);
        sh.shape = ShapeType::Rectangle;
        sh.size = {40, 40};
        sh.color = Color{1, 1, 1, 1};
    }
    PostProcess& p = w.add<PostProcess>(left);
    p.posterizeEnabled = true;
    p.posterizeLevels = 64;
    p.customPasses = Json::array({entry(kTint, "after:posterize")});
    const Image img = g.render(w);
    CHECK(index_of(graph_order(g), "post-part") >= 0);  // the final pass was cut for the left camera
    near(img.pixel(80, 90), 1.0f, 0.25f, 0.25f);        // the left square, tinted after the posterize
    near(img.pixel(240, 90), 1.0f, 1.0f, 1.0f);         // the right one is not
    near(img.pixel(10, 10), 0, 0, 0);
    near(img.pixel(310, 170), 0, 0, 0);
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a multisampled frame with a HUD over the final pass keeps the chain of custom passes and "
          "the HUD") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    // The HUD is drawn after the final pass (hudAfterPost), and the game is multisampled: the custom passes read the resolved picture
    // and write it back in place, the HUD is not tinted.
    for (const char* position : {static_cast<const char*>(nullptr), "after:tonemap"}) {
        INFO((position ? position : "default place"));
        OwnRenderer own(g, 4);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene2d s;
        PostProcess& p = s.post();
        p.exposureEnabled = true;
        p.tonemapEnabled = true;
        s.passes({entry(kTint, position), entry(kTint, position)});
        Entity box = make(s.w, "hud-box", {20, 10, 0});
        auto& b = s.w.add<Shape2D>(box);
        b.shape = ShapeType::Rectangle;
        b.size = {40, 20};
        b.color = Color::white();
        b.space = RenderSpace::Screen;
        b.pivot = {0, 1};
        const Image img = own.draw(s.w);
        const Color sprite = img.pixel(160, 90);
        CHECK(sprite.r > sprite.g + 0.3f);  // tinted twice
        CHECK(sprite.g < 0.2f);
        const Color hud = img.pixel(40, 20);
        CHECK(hud.r > 0.9f);  // the HUD is over the passes, white
        CHECK(hud.g > 0.9f);
        CHECK(hud.b > 0.9f);
        near(img.pixel(300, 170), 0, 0, 0);
        if (position) CHECK(index_of(own.order(), "post-part") >= 0);
    }
    CHECK(log.messages().empty());
}

TEST_CASE("post materials: a cut final pass in a gamma scene changes no colour, and a tint after it multiplies the "
          "shown one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    auto picture = [&](const char* material, double k) {
        Scene2d s;
        REQUIRE(s.w.settings().colorSpace == ColorSpace::Gamma);
        s.w.get<Sprite>(s.sprite)->color = Color{0.5f, 0.5f, 0.5f, 1};
        PostProcess& p = s.post();
        p.posterizeEnabled = true;
        p.posterizeLevels = 64;
        if (material)
            s.passes(
                {entry(material, "after:posterize", std::string(material) == kTint ? tint(k, k, k) : Json::object())});
        return g.render(s.w);
    };
    const Image plain = picture(nullptr, 1.0);
    const Image cut = picture(kEmpty, 1.0);
    CHECK(diff_images(plain, cut, 2.0f / 255.0f).maxError <=
          2.0 / 255.0);  // the cut is invisible: no second encode, no lost range
    const Color shown = plain.pixel(160, 90);
    near(picture(kTint, 0.5).pixel(160, 90), shown.r * 0.5f, shown.g * 0.5f,
         shown.b * 0.5f);  // display values, not linear light
    CHECK(log.messages().empty());
}

// ---- history: what a frame that is not the game's, a budget, a refusal, a second job and a reload do ----------------------------

namespace {

int live_images() {
    const sg_total_resource_stats t = sg_query_stats().total.images;
    return int(std::int64_t(t.inited) - std::int64_t(t.uninited));
}

// The game with a HUD box (screen space) over the final pass: hudAfterPost.
void add_hud_box(World& w) {
    Entity box = make(w, "hud-box", {20, 10, 0});
    auto& b = w.add<Shape2D>(box);
    b.shape = ShapeType::Rectangle;
    b.size = {40, 20};
    b.color = Color::white();
    b.space = RenderSpace::Screen;
    b.pivot = {0, 1};
}

}  // namespace

TEST_CASE("post history: a capture_world between two frames of the game keeps the trail") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    Scene2d s;
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    g.render(s.w);
    Image img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    Renderer::WorldCapture spec;
    spec.rect = Rect{-50, -30, 100, 60};
    Image shot;
    std::string err;
    REQUIRE_MESSAGE(g.renderer.capture_world(s.w, spec, shot, &err), err);
    CHECK(render::renderer_post_history_images(g.renderer) == 2);  // the capture neither made nor freed an image
    img = g.render(s.w);
    near(img.pixel(20, 20), 1, 0, 0);  // the history of the frame before the capture is still valid
    CHECK(render::renderer_post_history_images(g.renderer) == 2);
    CHECK(log.messages().empty());
}

TEST_CASE(
    "post history: going over the budget warns once, draws without history and starts when the budget allows it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    OwnRenderer own(g, 1);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene2d s;
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    render::renderer_set_post_history_budget(own.r, 1);  // one byte: no pair of images fits
    for (int i = 0; i < 5; ++i) {
        const Image img = own.draw(s.w);
        near(img.pixel(20, 20), 0, 0, 0);  // never red: the pass is drawn without its history
        near(img.pixel(160, 90), 1, 1, 1);
    }
    CHECK(log.count("keeps a history") == 1);
    CHECK(render::renderer_post_history_images(own.r) == 0);
    CHECK(render::renderer_post_history_attempts(own.r) == 0);  // the GPU was never asked
    CHECK(own.r.stats().materialFallbacks.empty());
    render::renderer_set_post_history_budget(own.r, 0);  // the default again
    own.draw(s.w);
    const Image img = own.draw(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(render::renderer_post_history_images(own.r) == 2);
    CHECK(log.count("keeps a history") == 1);
}

TEST_CASE("post history: a GPU that refuses the images is asked once for a shape, again when the shape changes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    OwnRenderer own(g, 1);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene2d s;
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    render::renderer_refuse_post_history(own.r, true);
    for (int i = 0; i < 6; ++i) {
        const Image img = own.draw(s.w);
        near(img.pixel(20, 20), 0, 0, 0);
        near(img.pixel(160, 90), 1, 1, 1);  // the picture, drawn without its history
    }
    CHECK(render::renderer_post_history_attempts(own.r) == 1);  // one ask, not one per frame
    CHECK(render::renderer_post_history_images(own.r) == 0);
    CHECK(log.count("keeps a history") == 1);
    // The GPU would take them now, but the shape that failed is remembered.
    render::renderer_refuse_post_history(own.r, false);
    for (int i = 0; i < 3; ++i) own.draw(s.w);
    CHECK(render::renderer_post_history_attempts(own.r) == 1);
    CHECK(render::renderer_post_history_images(own.r) == 0);
    // Another size of the camera's rectangle is another shape: it is asked again.
    s.w.get<Camera>(s.cam)->viewport = Rect{0, 0, 0.75f, 1};
    own.draw(s.w);
    CHECK(render::renderer_post_history_attempts(own.r) == 2);
    CHECK(render::renderer_post_history_images(own.r) == 2);
    const Image img = own.draw(s.w);
    near(img.pixel(20, 20), 1, 0, 0);
    CHECK(render::renderer_post_history_attempts(own.r) == 2);
}

TEST_CASE("post history: the refused shapes are remembered up to a cap, and the oldest one is forgotten first") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    OwnRenderer own(g, 1);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene2d s;
    // 32 history passes of one material (the camera's 8 and three volumes' 8 each: the most a stack takes), each its own slot.
    Json eight = Json::array();
    for (int i = 0; i < 8; ++i) eight.push_back(entry(kHistory, nullptr, keep(1.0, true)));
    s.post().customPasses = eight;
    for (int v = 0; v < 3; ++v) {
        Entity e = make(s.w, "volume");
        s.w.add<PostProcess>(e).customPasses = eight;
    }
    render::renderer_refuse_post_history(own.r, true);
    own.draw(s.w);
    CHECK(render::renderer_post_history_attempts(own.r) == 32);  // every slot asked once, every one refused
    // The memory holds 16 shapes, the 16 refused last (16..31); the oldest goes first. Frame 2 plans 0..15 first: each one is asked and
    // takes the place of the oldest, which is one of 16..31, so by the time 16..31 are planned none is left: all 32 are asked again
    // (a first-in first-out memory over a loop longer than itself). A memory that dropped whichever key sorts first would keep
    // most of 17..31 and ask 17, so the count tells which one is forgotten.
    own.draw(s.w);
    CHECK(render::renderer_post_history_attempts(own.r) == 64);
    own.draw(s.w);
    CHECK(render::renderer_post_history_attempts(own.r) == 96);
    CHECK(render::renderer_post_history_images(own.r) == 0);
    CHECK(log.count("keeps a history") == 1);
}

TEST_CASE(
    "post history: a multisampled frame with a HUD over the final pass keeps the history of the resolved picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    OwnRenderer own(g, 4);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene2d s;
    s.post().exposureEnabled = true;  // a final pass: the HUD is drawn after it
    s.passes({entry(kHistory, nullptr, keep(1.0, true))});
    add_hud_box(s.w);
    Image img = own.draw(s.w);
    near(img.pixel(160, 90), 1, 1, 1);
    img = own.draw(s.w);
    near(img.pixel(100, 150), 1, 0, 0);  // the history is valid
    near(img.pixel(40, 20), 1, 1, 1);    // the HUD is over it
    CHECK(render::renderer_post_history_images(own.r) == 2);
    img = own.draw(s.w);
    near(img.pixel(100, 150), 1, 0, 0);
    CHECK(render::renderer_post_history_images(own.r) == 2);
    CHECK(log.messages().empty());
}

TEST_CASE("post history: a reload of the material and the end of the renderer leave no image behind") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    HistoryScope scope;
    ProblemLog log;
    const bool wasEnabled = sg_stats_enabled();
    sg_enable_stats();
    {
        Scene2d s;
        s.passes({entry(kHistory, nullptr, keep(1.0, true))});
        g.render(s.w);
        g.render(s.w);
        const int images = live_images();
        for (int i = 0; i < 4; ++i) {
            g.renderer.reload_asset(kHistory);
            g.render(s.w);
            const Image img = g.render(s.w);
            near(img.pixel(20, 20), 1, 0, 0);
            CHECK(live_images() == images);  // the slot's two images stay, nothing is made twice
            CHECK(render::renderer_post_history_images(g.renderer) == 2);
        }
    }
    // A renderer that shuts down with history slots frees them: the same cycle without a history pass leaves the same count.
    auto cycle = [&](bool history) {
        OwnRenderer own(g, 1);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene2d s;
        if (history)
            s.passes({entry(kHistory, nullptr, keep(1.0, true))});
        else
            s.passes({entry(kTint)});
        for (int i = 0; i < 3; ++i) own.draw(s.w);
        CHECK(render::renderer_post_history_images(own.r) == (history ? 2 : 0));
    };
    cycle(false);
    const int without = live_images();
    cycle(true);
    CHECK(live_images() == without);
    cycle(true);
    CHECK(live_images() == without);
    if (!wasEnabled) sg_disable_stats();
    CHECK(log.messages().empty());
}
