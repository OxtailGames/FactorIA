// M71: the depth and normal prepass (src/renderer_draw.cpp plan_prepass / prepass_pass, mesh_common.glsl prepass programs, the debug
// view of prepass_view.glsl). The image is a float one that only the post effects read, so the tests read it through the debug view
// (Renderer::set_debug_view: depth as 10 / (10 + depth) grey, normals as n * 0.5 + 0.5, black where no mesh was drawn): a scene with a
// cube and a floor at known distances, with one and four samples, then what the prepass leaves out or does not make at all.
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "fa/scene/animation.h"

#include "frame_graph.h"
#include "postprocess_resolve.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

void add_camera(World& w, Vec3 pos, float fov = 60.0f) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = fov;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor =
        Color{0, 0, 0, 1};  // black behind the meshes: the main pass shows only them
}
Entity add_mesh(World& w, const char* mesh, Vec3 pos, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = Color::white();
    m.unlit = true;  // the main pass of a coverage comparison is the mesh's own colour on black
    return e;
}

// A camera at (0, 0, 10) looking down -Z, a cube of 2 m at the origin (its front face 9 m away) and a floor at y = -2 (20 x 20 m).
void cube_and_floor(World& w) {
    add_camera(w, {0, 0, 10});
    add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
    add_mesh(w, "plane", {0, -2, 0}, {20, 1, 20});
}

// Sets a debug view for the life of the object and puts it back.
struct DebugViewScope {
    Renderer& r;
    DebugViewScope(Renderer& rr, DebugView v) : r(rr) { r.set_debug_view(v); }
    ~DebugViewScope() { r.set_debug_view(DebugView::None); }
    DebugViewScope(const DebugViewScope&) = delete;
    DebugViewScope& operator=(const DebugViewScope&) = delete;
};
// Forces post effects for the life of the object and puts it back.
struct ForceScope {
    Renderer& r;
    ForceScope(Renderer& rr, PostEffect e) : r(rr) { render::renderer_force_post_effects(r, 1u << int(e)); }
    ~ForceScope() { render::renderer_force_post_effects(r, 0); }
    ForceScope(const ForceScope&) = delete;
    ForceScope& operator=(const ForceScope&) = delete;
};

// A second renderer on the test GPU with a chosen sample count.
struct OwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    OwnRenderer(Gfx& gx, int samples) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~OwnRenderer() { r.shutdown(); }
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

std::vector<std::string> order_of(Renderer& r) {
    const render::FrameGraph* graph = render::renderer_frame_graph(r);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}
int index_of(const std::vector<std::string>& names, const std::string& name) {
    const auto it = std::find(names.begin(), names.end(), name);
    return it == names.end() ? -1 : int(it - names.begin());
}
int count_suffix(const std::vector<std::string>& names, const std::string& suffix) {
    int n = 0;
    for (const std::string& s : names)
        if (s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0) ++n;
    return n;
}
std::string joined(const std::vector<std::string>& names) {
    std::string o;
    for (const std::string& s : names) o += s + " ";
    return o;
}

// The channels of a pixel as 0..255.
int c8(float v) { return int(std::lround(v * 255.0f)); }
bool near_rgb(const Color& c, int r, int g, int b, int tol) {
    return std::abs(c8(c.r) - r) <= tol && std::abs(c8(c.g) - g) <= tol && std::abs(c8(c.b) - b) <= tol;
}
// The grey the depth view paints for a view depth.
int depth_grey(float depth) { return int(std::lround(255.0f * 10.0f / (10.0f + depth))); }
bool is_black(const Color& c) { return c8(c.r) <= 2 && c8(c.g) <= 2 && c8(c.b) <= 2; }

// The depth the camera of cube_and_floor() sees through pixel row y of a 320 x 180 picture on the floor (y = -2, camera at y = 0).
float floor_depth(int y) {
    const float ndc = (90.0f - (float(y) + 0.5f)) / 90.0f;
    return 2.0f / (-ndc * std::tan(radians(30.0f)));
}

struct Mask {
    int w = 0, h = 0;
    std::vector<unsigned char> on;
    int count() const { return int(std::count(on.begin(), on.end(), (unsigned char)1)); }
};
Mask mask_of(const Image& img, bool (*covered)(const Color&)) {
    Mask m;
    m.w = img.width;
    m.h = img.height;
    m.on.resize(std::size_t(m.w) * std::size_t(m.h));
    for (int y = 0; y < m.h; ++y)
        for (int x = 0; x < m.w; ++x) m.on[std::size_t(y * m.w + x)] = covered(img.pixel(x, y)) ? 1 : 0;
    return m;
}
bool lit_pixel(const Color& c) { return std::max({c.r, c.g, c.b}) > 0.05f; }
bool not_black(const Color& c) { return !is_black(c); }
// Pixels that are in one mask and not in the other (edge pixels of a rasterisation differ in the last bit of a float).
int mismatch(const Mask& a, const Mask& b) {
    REQUIRE(a.on.size() == b.on.size());
    int n = 0;
    for (std::size_t i = 0; i < a.on.size(); ++i) n += a.on[i] != b.on[i] ? 1 : 0;
    return n;
}

// The main pass of a scene next to what the depth view of the same scene covers: the same pixels, give or take the edges.
void expect_same_coverage(Gfx& g, World& w, int* coveredOut = nullptr) {
    const Image main = g.draw(w);
    Mask mainMask = mask_of(main, lit_pixel);
    Image depth;
    {
        DebugViewScope view(g.renderer, DebugView::Depth);
        depth = g.draw(w);
    }
    Mask prepassMask = mask_of(depth, not_black);
    const int covered = mainMask.count();
    CHECK(covered > 300);
    CHECK(prepassMask.count() > 300);
    // A multisampled main pass blends its edges (any lit sample counts) where the prepass has hard ones: a wrong pose, a missing hole or
    // an offset vertex() differs by far more than the edges of a mesh do.
    CHECK(mismatch(mainMask, prepassMask) <= 4 + covered / 8);
    if (coveredOut) *coveredOut = covered;
}

void install_file_from_repo(const char* repoRelative, const char* projectPath) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + repoRelative, std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(!text.empty());
    REQUIRE(fs::write_text(projectPath, text).ok());
}

void install_materials(bool dropPrepass = false) {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            if (dropPrepass && twin.contains("programs")) {  // a twin made before the prepass existed
                twin["programs"].erase("prepass");
                twin["programs"].erase("prepass_skin");
            }
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}
struct MaterialScope {
    explicit MaterialScope(bool dropPrepass = false) {
        gfx().renderer.clear_asset_cache();
        install_materials(dropPrepass);
    }
    ~MaterialScope() {
        gfx().renderer.set_shader_compiler({});
        gfx().renderer.clear_asset_cache();
    }
};

}  // namespace

TEST_CASE("prepass: the depth and the normals at known pixels of a cube and a floor, with one and four samples") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        OwnRenderer own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        World w;
        cube_and_floor(w);
        {
            DebugViewScope view(own.r, DebugView::Depth);
            const Image img = own.draw(w);
            const int cube = depth_grey(9.0f);
            INFO("cube grey " << cube << ", pixel " << c8(img.pixel(160, 90).r));
            CHECK(near_rgb(img.pixel(160, 90), cube, cube, cube, 4));  // the front face, 9 m away
            CHECK(near_rgb(img.pixel(150, 80), cube, cube, cube, 4));  // a flat face is the same depth anywhere on it
            for (const int y : {120, 150, 175}) {
                const int grey = depth_grey(floor_depth(y));
                CAPTURE(y);
                CHECK(near_rgb(img.pixel(40, y), grey, grey, grey, 5));
            }
            CHECK(is_black(img.pixel(160, 3)));  // above the cube, over the horizon: nothing was drawn
        }
        {
            DebugViewScope view(own.r, DebugView::Normals);
            const Image img = own.draw(w);
            CHECK(near_rgb(img.pixel(160, 90), 128, 128, 255, 4));  // the cube's front face looks at the camera
            CHECK(near_rgb(img.pixel(40, 170), 128, 255, 128, 4));  // the floor looks up
            CHECK(is_black(img.pixel(160, 3)));
        }
    }
}

TEST_CASE("prepass: a view-space normal follows the camera, not the world") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 10, 0});
    w.get<Transform>(w.find("cam"))->rotation = {-90, 0, 0};  // looking straight down
    add_mesh(w, "plane", {0, 0, 0}, {20, 1, 20});             // the floor faces +Y in the world: toward this camera
    {
        DebugViewScope view(g.renderer, DebugView::Normals);
        const Image img = g.draw(w);
        CHECK(near_rgb(img.pixel(160, 90), 128, 128, 255, 4));
    }
    DebugViewScope view(g.renderer, DebugView::Depth);
    const int grey = depth_grey(10.0f);
    CHECK(near_rgb(g.draw(w).pixel(160, 90), grey, grey, grey, 4));
}

TEST_CASE("prepass: off by default - no node in the graph and the same draw calls; a depth effect or a view adds the "
          "prepass only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    cube_and_floor(w);
    g.draw(w);
    const RenderStats base = g.renderer.stats();
    const std::vector<std::string> baseOrder = order_of(g.renderer);
    CHECK(count_suffix(baseOrder, "/prepass") == 0);
    CHECK(count_suffix(baseOrder, "/prepass-view") == 0);
    REQUIRE(base.meshBatches == 2);

    {  // an effect that does not read the depth makes no prepass
        ForceScope force(g.renderer, PostEffect::Bloom);
        g.draw(w);
        CHECK(count_suffix(order_of(g.renderer), "/prepass") == 0);
    }
    {  // one that does makes it, drawn before the main pass: one draw per batch, nothing else
        ForceScope force(g.renderer, PostEffect::Ssao);
        g.draw(w);
        const std::vector<std::string> order = order_of(g.renderer);
        INFO(joined(order));
        REQUIRE(count_suffix(order, "/prepass") == 1);
        CHECK(count_suffix(order, "/prepass-view") == 0);
        CHECK(index_of(order, "camera:0/prepass") < index_of(order, "camera:0/game"));
        CHECK(g.renderer.stats().drawCalls == base.drawCalls + base.meshBatches);
    }
    {  // the debug view adds the prepass and one full-screen draw
        DebugViewScope view(g.renderer, DebugView::Depth);
        g.draw(w);
        const std::vector<std::string> order = order_of(g.renderer);
        INFO(joined(order));
        REQUIRE(count_suffix(order, "/prepass") == 1);
        REQUIRE(count_suffix(order, "/prepass-view") == 1);
        CHECK(index_of(order, "camera:0/prepass") < index_of(order, "camera:0/game"));
        CHECK(index_of(order, "camera:0/game") < index_of(order, "camera:0/prepass-view"));
        CHECK(g.renderer.stats().drawCalls == base.drawCalls + base.meshBatches + 1);
    }
    g.draw(w);  // back to nothing
    CHECK(count_suffix(order_of(g.renderer), "/prepass") == 0);
    CHECK(g.renderer.stats().drawCalls == base.drawCalls);
}

TEST_CASE("prepass: a scene without an opaque mesh has no prepass, and blended meshes are not in it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DebugViewScope view(g.renderer, DebugView::Depth);
    {
        World w;
        add_camera(w, {0, 0, 10});  // nothing to draw
        g.draw(w);
        CHECK(count_suffix(order_of(g.renderer), "/prepass") == 0);
    }
    {
        World w;
        add_camera(w, {0, 0, 10});
        Entity glass = add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
        w.get<MeshRenderer>(glass)->color = Color{1, 1, 1, 0.5f};  // blended: drawn far to near after the opaque meshes
        const Image img = g.draw(w);
        CHECK(count_suffix(order_of(g.renderer), "/prepass") == 0);
        CHECK(img.pixel(160, 90).r > 0.2f);  // still drawn by the main pass
        add_mesh(
            w, "cube",
            {4, 0,
             0});  // one opaque cube, 62 pixels right of the centre: the prepass is back, and the glass is not in it
        const Image both = g.draw(w);
        CHECK(count_suffix(order_of(g.renderer), "/prepass") == 1);
        CHECK(is_black(both.pixel(160, 90)));
        CHECK_FALSE(is_black(both.pixel(222, 90)));
    }
}

TEST_CASE("prepass: an orthographic 3D camera writes the distance along the view axis") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 0, 10});
    w.get<Camera>(w.find("cam"))->projection = Projection::Orthographic;
    w.get<Camera>(w.find("cam"))->orthoSize = 4.0f;
    add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});  // front face at z = 1: 9 m
    add_mesh(w, "cube", {2.5f, 0, -5.0f});      // front face at z = -4.5: 14.5 m
    DebugViewScope view(g.renderer, DebugView::Depth);
    const Image img = g.draw(w);
    const int near9 = depth_grey(9.0f), far = depth_grey(14.5f);
    CHECK(near_rgb(img.pixel(160, 90), near9, near9, near9, 4));
    CHECK(near_rgb(img.pixel(150, 82), near9, near9, near9, 4));  // the same depth over the whole face
    const int x = 160 + int(std::lround(2.5f / (4.0f * 16.0f / 9.0f) * 160.0f));
    CHECK(near_rgb(img.pixel(x, 90), far, far, far, 4));
    CHECK(is_black(img.pixel(160, 3)));
}

TEST_CASE("prepass: a camera that draws into a texture and a CameraView never make one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DebugViewScope view(g.renderer, DebugView::Depth);
    {
        World w;
        add_camera(w, {0, 0, 10});
        add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
        Entity off = make(w, "off-cam", {200, 0, 10});
        auto& c = w.add<Camera>(off);
        c.projection = Projection::Perspective;
        c.renderTarget = "off";
        c.renderTargetSize = Vec2{64, 64};
        add_mesh(w, "cube", {200, 0, 0}, {2, 2, 2});
        g.draw(w);
        const std::vector<std::string> order = order_of(g.renderer);
        INFO(joined(order));
        CHECK(g.renderer.stats().renderTargets == 1);
        CHECK(count_suffix(order, "/prepass") == 1);  // the screen camera's own, not the texture camera's
    }
    {
        World w;
        add_camera(w, {0, 0, 10});
        add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
        Entity stage = make(w, "stage", {500, 0, 4});
        auto& c = w.add<Camera>(stage);
        c.projection = Projection::Perspective;
        c.primary = false;
        add_mesh(w, "cube", {500, 0, 0});
        Entity widget = make(w, "view", {40, 30, 0});
        auto& v = w.add<CameraView>(widget);
        v.camera = "stage";
        v.size = {120, 100};
        v.pivot = {0, 1};
        g.draw(w);
        const std::vector<std::string> order = order_of(g.renderer);
        INFO(joined(order));
        CHECK(g.renderer.stats().views == 1);
        CHECK(count_suffix(order, "/prepass") == 1);
    }
}

TEST_CASE("prepass: a skinned mesh is drawn at its pose") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo("engine/render/tests/data/skinned_two_bone.gltf", "assets/rig.gltf");
    World w;
    add_camera(w, {0.5f, 1.2f, 4});
    w.get<Transform>(w.find("cam"))->rotation = {-3.0f, 0, 0};
    Entity rig = make(w, "rig", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(rig);
    m.mesh = "assets/rig.gltf";
    m.unlit = true;
    m.color = Color::white();
    w.add<Animator>(rig).clip = "Bend";
    update_animators(w, 0.0f);
    update_animators(w, 0.5f);  // the tip is bent 45 degrees: the pose is not the bind pose
    REQUIRE(w.get<Animator>(rig)->palette.size() == 2);
    int bent = 0;
    expect_same_coverage(g, w, &bent);
    // and the bind pose covers other pixels, so the test above tells the poses apart
    World bindWorld;
    add_camera(bindWorld, {0.5f, 1.2f, 4});
    bindWorld.get<Transform>(bindWorld.find("cam"))->rotation = {-3.0f, 0, 0};
    Entity rig2 = make(bindWorld, "rig", {0, 0, 0});
    auto& m2 = bindWorld.add<MeshRenderer>(rig2);
    m2.mesh = "assets/rig.gltf";
    m2.unlit = true;
    m2.color = Color::white();
    bindWorld.add<Animator>(rig2).clip = "Bend";
    const Mask bentMask = mask_of(g.draw(w), lit_pixel);
    const Mask bindMask = mask_of(g.draw(bindWorld), lit_pixel);
    CHECK(mismatch(bentMask, bindMask) > 20);
}

TEST_CASE("prepass: a material with alphaMode clip cuts the same holes as the main pass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World plain;
    add_camera(plain, {0, 0, 4});
    add_mesh(plain, "plane", {0, 0, 0}, {3, 1, 3});
    plain.get<Transform>(plain.find("plane"))->rotation = {90, 0, 0};  // the quad faces the camera
    World cut;
    add_camera(cut, {0, 0, 4});
    Entity e = add_mesh(cut, "plane", {0, 0, 0}, {3, 1, 3});
    cut.get<Transform>(e)->rotation = {90, 0, 0};
    cut.get<MeshRenderer>(e)->material = "materials/cutout.material.json";
    const int full = mask_of(g.draw(plain), lit_pixel).count();
    int covered = 0;
    expect_same_coverage(g, cut, &covered);
    CHECK(full > 2000);
    CHECK(covered < full * 9 / 10);  // the checkerboard really cut holes
    CHECK(covered > full / 10);
}

TEST_CASE("prepass: a material's vertex() moves the mesh in the prepass as in the main pass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World plain;
    add_camera(plain, {0, 0, 8});
    add_mesh(plain, "cube", {0, 0, 0}, {2, 2, 2});
    World lifted;
    add_camera(lifted, {0, 0, 8});
    Entity e = add_mesh(lifted, "cube", {0, 0, 0}, {2, 2, 2});
    lifted.get<MeshRenderer>(e)->material = "materials/lift.material.json";
    expect_same_coverage(g, lifted);
    // the cube is no longer where the plain one is: the left edge of the lifted one is further right and higher
    const Mask a = mask_of(g.draw(plain), lit_pixel);
    const Mask b = mask_of(g.draw(lifted), lit_pixel);
    CHECK(mismatch(a, b) > 200);
}

TEST_CASE("prepass: the effects that need the depth or the normals are the ones the table says") {
    using render::post_effect_needs_depth;
    using render::post_effect_needs_normals;
    CHECK(post_effect_needs_depth(PostEffect::Ssao));
    CHECK(post_effect_needs_depth(PostEffect::DepthOfField));
    CHECK(post_effect_needs_depth(PostEffect::MotionBlur));
    CHECK_FALSE(post_effect_needs_depth(PostEffect::Bloom));
    CHECK_FALSE(post_effect_needs_depth(PostEffect::Tonemap));
    CHECK(post_effect_needs_normals(PostEffect::Ssao));
    CHECK_FALSE(post_effect_needs_normals(PostEffect::DepthOfField));
    CHECK(render::post_mask_needs_depth(1u << int(PostEffect::Fog)));
    CHECK_FALSE(render::post_mask_needs_depth(1u << int(PostEffect::Vignette)));
}

TEST_CASE("prepass: a frame split between cameras, or a camera with a partial viewport, has none even without a HUD") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    ForceScope force(g.renderer, PostEffect::Ssao);
    DebugViewScope view(g.renderer, DebugView::Depth);
    {  // two cameras side by side, nothing on the screen: the screen-space job of the split frame is dropped
        World w;
        add_camera(w, {0, 0, 10});
        w.get<Camera>(w.find("cam"))->viewport = Rect{0, 0, 0.5f, 1};
        add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
        Entity second = make(w, "cam2", {0, 0, 10});
        auto& c = w.add<Camera>(second);
        c.projection = Projection::Perspective;
        c.viewport = Rect{0.5f, 0, 0.5f, 1};
        c.depth = 1;
        const Image img = g.draw(w);
        const std::vector<std::string> order = order_of(g.renderer);
        INFO(joined(order));
        CHECK(count_suffix(order, "/prepass") == 0);
        CHECK(count_suffix(order, "/prepass-view") == 0);
        CHECK(img.width == 320);
    }
    {  // one camera over the left half
        World w;
        add_camera(w, {0, 0, 10});
        w.get<Camera>(w.find("cam"))->viewport = Rect{0, 0, 0.5f, 1};
        add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
        g.draw(w);
        const std::vector<std::string> order = order_of(g.renderer);
        INFO(joined(order));
        CHECK(count_suffix(order, "/prepass") == 0);
        CHECK(count_suffix(order, "/prepass-view") == 0);
    }
    {  // and the same camera over the whole screen has one
        World w;
        add_camera(w, {0, 0, 10});
        add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
        g.draw(w);
        CHECK(count_suffix(order_of(g.renderer), "/prepass") == 1);
    }
}

TEST_CASE("prepass: the written depth is clamped to the far value, and the alpha stays the coverage") {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/shaders/mesh_common.glsl", std::ios::binary);
    const std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(!text.empty());
    CHECK(text.find("vec4(min(fa_pre_depth, 60000.0), e, 1.0)") != std::string::npos);
}

TEST_CASE("prepass: a custom material twin made before the prepass warns once that the depth effects do not see it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    clear_recent_logs();
    MaterialScope scope(true);
    World w;
    add_camera(w, {0, 0, 8});
    Entity e = add_mesh(w, "cube", {0, 0, 0}, {2, 2, 2});
    w.get<MeshRenderer>(e)->material = "materials/glow.material.json";
    (void)g.draw(w);
    int warnings = 0;
    for (const LogEntry& l : recent_logs(4096, LogLevel::Warn))
        if (l.message.find("has no program 'prepass'") != std::string::npos) ++warnings;
    CHECK(warnings >= 1);
    CHECK(warnings <= 2);  // the prepass and the prepass_skin program, once for this load
}
