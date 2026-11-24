// M76-P1a: the per-pixel motion vectors the depth prepass writes as a second attachment (src/renderer_draw.cpp plan_prepass / prepass_pass /
// fill_prev_models, mesh_common.glsl prepass programs, docs/design/ARCHITECTURE_RENDERING_POST.md "Motion vectors and jitter (M76)").
// The image is read back through RendererTestAccess::read_velocity (a copy of the camera's RG16F image as floats, forced on with
// force_velocity). Every value is uvPrev - uvCurr from the UNJITTERED matrices (uv y down), the sentinel 1024 where no object wrote:
//   - a still scene: ~0 on the meshes, the sentinel on the sky;
//   - a mesh moved by a known amount, an instance of a batch moved alone, an entity drawn again after a frame it was not drawn in;
//   - a camera that pans over static objects (a pure rotation moves every pixel the same way whatever the depth, so the expected value of
//     every pixel is computed from the two matrices alone): meshes, terrain, foliage, impostor cards;
//   - the floating origin: a rebase makes no motion; a new entity has the camera's motion only; the first frame has none;
//   - the jitter does not change the values; with nothing asking there is no pass and the picture is the same, bit for bit.
// The tolerances are far above half-float and rasterisation noise and far below the motions the cases make (0.01 .. 0.1 of the image), so
// they hold on llvmpipe and WARP as well as on a real GPU; the thresholds on pixel counts are a fraction of what the scene draws.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/engine_version.h"
#include "fa/core/log.h"
#include "fa/scene/animation.h"
#include "fa/scene/foliage.h"
#include "fa/scene/impostor.h"
#include "fa/scene/jitter.h"

#include "foliage_chunks.h"
#include "frame_graph.h"
#include "postprocess.h"
#include "postprocess_resolve.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

constexpr int kW = 320, kH = 180;

// A renderer of its own: its history of matrices and models starts empty, whatever the other tests of the process drew.
struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx, bool velocity = true) : g(gx) {
        RendererDesc d;
        d.designWidth = kW;
        d.designHeight = kH;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
        if (ok) RendererTestAccess::force_velocity(r, velocity);
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
    Image draw(World& w) {
        frame(w);
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

// The velocity image of the last frame, as floats.
struct Vel {
    std::vector<float> px;
    int w = 0, h = 0;
    bool none(int x, int y) const {
        return VelocityRef::is_none(px[idx(x, y)]) || VelocityRef::is_none(px[idx(x, y) + 1]);
    }
    Vec2 at(int x, int y) const { return {px[idx(x, y)], px[idx(x, y) + 1]}; }
    std::size_t idx(int x, int y) const { return (std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4; }
};

// Reads it (REQUIRE: the GPU of these tests makes an RG16F image).
Vel read_vel(Own& o) {
    Vel v;
    std::string err;
    const bool ok = RendererTestAccess::read_velocity(o.r, v.px, v.w, v.h, &err);
    INFO("read_velocity: " << err);
    REQUIRE(ok);
    REQUIRE(v.w == kW);
    REQUIRE(v.h == kH);
    REQUIRE(v.px.size() == std::size_t(kW) * std::size_t(kH) * 4);
    return v;
}

// The uv (0..1 over the image, y down) a world point has in the picture of `vp`.
Vec2 uv_of(const Mat4& vp, Vec3 q) {
    const Vec4 c = vp * Vec4{q.x, q.y, q.z, 1.0f};
    return {c.x / c.w * 0.5f + 0.5f, 0.5f - c.y / c.w * 0.5f};
}
// A point on the ray through the pixel (x, y) of the picture of `vp` (any depth: a pure rotation of the camera does not need it).
Vec3 on_ray(const Mat4& vp, int x, int y) {
    const float nx = (float(x) + 0.5f) / float(kW) * 2.0f - 1.0f, ny = 1.0f - (float(y) + 0.5f) / float(kH) * 2.0f;
    const Vec4 p = vp.inverse() * Vec4{nx, ny, 0.5f, 1.0f};
    return {p.x / p.w, p.y / p.w, p.z / p.w};
}
// What a static point sees at the pixel (x, y) of the picture of `cur` moves by when the camera went from `prev` to `cur`, for a camera
// that only turned (the same position), whatever the depth of the point.
Vec2 pan_motion(const Mat4& prev, const Mat4& cur, int x, int y) {
    const Vec3 q = on_ray(cur, x, y);
    const Vec2 a = uv_of(prev, q), b = uv_of(cur, q);
    return {a.x - b.x, a.y - b.y};
}

struct PanCheck {
    int drawn = 0, wrong = 0;
    float worst = 0;
};
// Every 3rd pixel of the image that holds a vector must hold the camera's pure-rotation motion.
PanCheck check_pan(const Vel& v, const Mat4& prev, const Mat4& cur, float tol = 3.0e-3f) {
    PanCheck c;
    for (int y = 1; y < v.h; y += 3)
        for (int x = 1; x < v.w; x += 3) {
            if (v.none(x, y)) continue;
            ++c.drawn;
            const Vec2 want = pan_motion(prev, cur, x, y), got = v.at(x, y);
            const float err = std::max(std::fabs(want.x - got.x), std::fabs(want.y - got.y));
            c.worst = std::max(c.worst, err);
            if (err > tol) ++c.wrong;
        }
    return c;
}

Entity add_camera(World& w, Vec3 pos, Vec3 rotation = {0, 0, 0}, float farPlane = 1000.0f) {
    Entity cam = make(w, "cam", pos);
    w.get<Transform>(cam)->rotation = rotation;
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.farPlane = farPlane;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
    return cam;
}
Entity add_cube(World& w, Vec3 pos, Vec3 scale = {2, 2, 2}) {
    Entity e = make(w, "cube", pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color::white();
    m.unlit = true;
    return e;
}
void move_to(World& w, Entity e, Vec3 pos) { w.get<Transform>(e)->position = pos; }
void yaw_to(World& w, Entity cam, float deg) { w.get<Transform>(cam)->rotation = {0, deg, 0}; }

Mat4 matrix_of(Own& o, Entity cam) {
    Mat4 m;
    REQUIRE(RendererTestAccess::prev_view_proj(o.r, cam, m));
    return m;
}

// The motion of the front face (z = 1, a plane facing the camera at 9 m) of a cube that moved by `d` between the frames, seen by `vp`.
Vec2 front_face_motion(const Mat4& vp, Vec3 d, Vec3 at = {0, 0, 1}) {
    const Vec2 a = uv_of(vp, at - d), b = uv_of(vp, at);
    return {a.x - b.x, a.y - b.y};
}
// The pixel the point `at` falls on.
void pixel_of(const Mat4& vp, Vec3 at, int& x, int& y) {
    const Vec2 uv = uv_of(vp, at);
    x = int(std::floor(uv.x * float(kW)));
    y = int(std::floor(uv.y * float(kH)));
}

// The rig of the tests (render/tests/data), a material of the fixtures, in the project's files.
void install_file_from_repo(const char* repoRelative, const char* projectPath) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + repoRelative, std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(!text.empty());
    REQUIRE(fs::write_text(projectPath, text).ok());
}
// The fixtures' materials with their committed shader twins, made current for this engine version.
struct MaterialScope {
    MaterialScope() {
        namespace sfs = std::filesystem;
        gfx().renderer.clear_asset_cache();
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
    ~MaterialScope() {
        gfx().renderer.set_shader_compiler({});
        gfx().renderer.clear_asset_cache();
    }
};

// The column of the tests (a skinned mesh 0.5 wide and 2 tall, assets/rig.gltf) with the clip `clip`; the caller poses it.
Entity add_rig(World& w, const char* clip, Vec3 pos = {0, 0, 0}) {
    Entity rig = make(w, "rig", pos);
    auto& m = w.add<MeshRenderer>(rig);
    m.mesh = "assets/rig.gltf";
    m.unlit = true;
    m.color = Color::white();
    w.add<Animator>(rig).clip = clip;
    return rig;
}

}  // namespace

TEST_CASE("velocity: the layout of the previous model's attributes follows the same rule as the shader") {
    MeshExtras none;
    CHECK(prepass_prev_attr(false, false, none) ==
          kExtraAttrBase);  // the engine's program: straight after the 9 mesh attributes
    CHECK(prepass_prev_attr(true, false, none) == kExtraAttrBaseSkinned);  // skinned: after its joints and weights
    MeshExtras e;
    e.instanceVec4 = 2;
    e.uv1 = true;
    CHECK(prepass_prev_attr(false, true, e) == kExtraAttrBase + 3);
    e.color1 = true;
    CHECK(prepass_prev_attr(false, true, e) == kExtraAttrBase + 4);
    e.instanceVec4 = 3;  // five extras: three more attributes would pass the 16 of SG_MAX_VERTEX_ATTRIBUTES
    CHECK(prepass_prev_attr(false, true, e) == -1);
    MeshExtras buf;
    buf.bufferInst = true;  // drawn from storage buffers: no previous model
    CHECK(prepass_prev_attr(false, true, buf) == -1);
    CHECK(kExtraAttrBase + 4 + 3 <= 16);
    CHECK(prepass_prev_attr(true, true, MeshExtras{}) == kExtraAttrBaseSkinned);
    e = MeshExtras{};
    e.instanceVec4 = 2;
    CHECK(prepass_prev_attr(true, true, e) == kExtraAttrBaseSkinned + 2);
    e.uv1 = true;
    e.color1 = true;  // four extras: 11 + 4 + 3 passes 16
    CHECK(prepass_prev_attr(true, true, e) == -1);
    buf.bufferInst = true;
    CHECK(prepass_prev_attr(true, true, buf) == -1);
    // The previous palette is an image of 192 texels a skinned draw (the 64 joints of the loader, 3 texels each), in rows of the same width as
    // the light data image whose pool writes it, and the shader reads texel t at (t & 1023, t >> 10).
    CHECK(kPrevPaletteTexels == 3 * kMaxSkinJoints);
    CHECK(kPrevPaletteWidth == 1024);
    // Only the temporal antialiasing asks for it, and only a frame that draws it.
    CHECK(post_effect_needs_velocity(PostEffect::TemporalAA));
    CHECK_FALSE(post_effect_needs_velocity(PostEffect::Ssao));
    CHECK_FALSE(post_mask_needs_velocity(1u << int(PostEffect::Ssao)));
    PostPlan plan;
    CHECK_FALSE(plan.needsVelocity);
    plan.request_velocity();
    CHECK(plan.needsVelocity);
    CHECK_FALSE(plan.velocity.valid());
}

TEST_CASE("velocity: a still scene has no motion on the meshes and the sentinel on the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    add_cube(w, {0, 0, 0});
    add_cube(w, {-4, 0, 0});
    o.frame(w);
    o.frame(w);
    const Vel v = read_vel(o);
    int meshPixels = 0, moving = 0;
    for (int y = 0; y < v.h; ++y)
        for (int x = 0; x < v.w; ++x) {
            if (v.none(x, y)) continue;
            ++meshPixels;
            const Vec2 m = v.at(x, y);
            if (std::fabs(m.x) > 5.0e-4f || std::fabs(m.y) > 5.0e-4f) ++moving;
        }
    CHECK(meshPixels > 1500);  // two cubes of ~30 x 30 pixels
    CHECK(moving == 0);
    CHECK(v.none(2, 2));  // the sky: both channels hold 1024
    CHECK(v.at(2, 2).x == VelocityRef::kNone);
    CHECK(v.at(kW - 3, kH - 3).y == VelocityRef::kNone);
    (void)cam;
}

TEST_CASE("velocity: the first frame of a camera has no motion at all") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera(w, {0, 0, 10}, {0, 5, 0});
    add_cube(w, {0, 0, 0});
    o.frame(w);  // nothing before it: a cut
    const Vel v = read_vel(o);
    int drawn = 0, moving = 0;
    for (int y = 0; y < v.h; y += 2)
        for (int x = 0; x < v.w; x += 2) {
            if (v.none(x, y)) continue;
            ++drawn;
            if (std::fabs(v.at(x, y).x) > 5.0e-4f || std::fabs(v.at(x, y).y) > 5.0e-4f) ++moving;
        }
    CHECK(drawn > 100);
    CHECK(moving == 0);
}

TEST_CASE("velocity: a mesh moved by a known amount holds uvPrev - uvCurr, a still one next to it holds none") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    const Entity mover = add_cube(w, {0, 0, 0});
    add_cube(w, {-4, 0, 0});
    o.frame(w);
    const Vec3 d{0.5f, 0.25f, 0.0f};
    move_to(w, mover, d);
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    const Vec2 want = front_face_motion(vp, d, d + Vec3{0, 0, 1});
    int x, y;
    pixel_of(vp, d + Vec3{0, 0, 1}, x, y);
    REQUIRE_FALSE(v.none(x, y));
    CHECK(std::fabs(want.x) > 0.02f);  // the case is not a still one
    CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.002));
    CHECK(v.at(x, y).y == doctest::Approx(want.y).epsilon(0.0).scale(1.0).epsilon(0.002));
    // Every pixel of the moved face holds the same vector (a plane facing the camera, moved parallel to the image).
    int onFace = 0, off = 0;
    for (int dy = -8; dy <= 8; dy += 4)
        for (int dx = -8; dx <= 8; dx += 4) {
            if (v.none(x + dx, y + dy)) continue;
            ++onFace;
            if (std::fabs(v.at(x + dx, y + dy).x - want.x) > 3.0e-3f ||
                std::fabs(v.at(x + dx, y + dy).y - want.y) > 3.0e-3f)
                ++off;
        }
    CHECK(onFace >= 20);
    CHECK(off == 0);
    // The cube that stayed.
    int sx, sy;
    pixel_of(vp, {-4, 0, 1}, sx, sy);
    REQUIRE_FALSE(v.none(sx, sy));
    CHECK(std::fabs(v.at(sx, sy).x) < 5.0e-4f);
    CHECK(std::fabs(v.at(sx, sy).y) < 5.0e-4f);
}

TEST_CASE("velocity: the instances of one batch each keep their own previous model") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    add_cube(w, {-4, 0, 0});
    const Entity middle = add_cube(w, {0, 0, 0});
    add_cube(w, {4, 0, 0});
    o.frame(w);
    move_to(w, middle, {0.5f, 0, 0});
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    int x, y;
    pixel_of(vp, {0.5f, 0, 1}, x, y);
    const Vec2 want = front_face_motion(vp, {0.5f, 0, 0}, {0.5f, 0, 1});
    REQUIRE_FALSE(v.none(x, y));
    CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.002));
    for (float cx : {-4.0f, 4.0f}) {
        pixel_of(vp, {cx, 0, 1}, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CHECK(std::fabs(v.at(x, y).x) < 5.0e-4f);
        CHECK(std::fabs(v.at(x, y).y) < 5.0e-4f);
    }
}

TEST_CASE("velocity: an entity that was not drawn in the frame before has no motion of its own") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    const Entity e = add_cube(w, {0, 0, 0});
    o.frame(w);
    move_to(w, e, {400, 0, 0});  // out of the view: not drawn, so the renderer forgets its history
    o.frame(w);
    move_to(w, e,
            {0.5f, 0, 0});  // back: the frame before did not draw it, so it did not move as far as the picture knows
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    int x, y;
    pixel_of(vp, {0.5f, 0, 1}, x, y);
    REQUIRE_FALSE(v.none(x, y));
    CHECK(std::fabs(v.at(x, y).x) < 5.0e-4f);
    CHECK(std::fabs(v.at(x, y).y) < 5.0e-4f);
}

TEST_CASE("velocity: a camera that pans over still meshes gives every pixel the camera's motion") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    add_cube(w, {0, 0, 0});
    add_cube(w, {-3, 1, -4});
    add_cube(w, {3, -1, 3});
    o.frame(w);
    const Mat4 before = matrix_of(o, cam);
    yaw_to(w, cam, 3.0f);
    o.frame(w);
    const Mat4 after = matrix_of(o, cam);
    const Vel v = read_vel(o);
    const PanCheck c = check_pan(v, before, after);
    CAPTURE(c.worst);
    CHECK(c.drawn > 400);
    CHECK(c.wrong == 0);
    // The motion is not zero: 3 degrees of a 60 degree field is 5 % of the image height, more across the width.
    int cx, cy;
    pixel_of(after, {0, 0, 1}, cx, cy);
    if (!v.none(cx, cy)) CHECK(std::fabs(v.at(cx, cy).x) > 0.02f);
}

TEST_CASE("velocity: a new entity next to a panning camera has the camera's motion only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    add_cube(w, {-4, 0, 0});
    o.frame(w);
    const Mat4 before = matrix_of(o, cam);
    yaw_to(w, cam, 3.0f);
    add_cube(w, {3, 0, 0});  // born in this frame
    o.frame(w);
    const Mat4 after = matrix_of(o, cam);
    const Vel v = read_vel(o);
    const PanCheck c = check_pan(v, before, after);
    CAPTURE(c.worst);
    CHECK(c.drawn > 250);  // both cubes
    CHECK(c.wrong == 0);
}

TEST_CASE("velocity: a rebase of the floating origin makes no motion") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Vec3 at{4096.0f, 0.0f, 0.0f};
    const Entity cam = add_camera(w, at + Vec3{0, 0, 10});
    const Entity e = add_cube(w, at);
    add_cube(w, at + Vec3{-4, 0, 0});
    o.frame(w);
    o.frame(w);
    w.rebase(at);  // every local position moves by -at: the same scene, 4096 m closer to 0
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    int x, y, drawn = 0, moving = 0;
    pixel_of(vp, {0, 0, 1}, x, y);
    REQUIRE_FALSE(v.none(x, y));
    for (int yy = 0; yy < v.h; yy += 2)
        for (int xx = 0; xx < v.w; xx += 2) {
            if (v.none(xx, yy)) continue;
            ++drawn;
            if (std::fabs(v.at(xx, yy).x) > 1.0e-3f || std::fabs(v.at(xx, yy).y) > 1.0e-3f) ++moving;
        }
    CHECK(drawn > 300);
    CHECK(moving == 0);
    // A cube that moves after the rebase still has its motion (the history was shifted, not dropped).
    move_to(w, e, {0.5f, 0, 0});
    o.frame(w);
    const Vel v2 = read_vel(o);
    const Vec2 want = front_face_motion(vp, {0.5f, 0, 0}, {0.5f, 0, 1});
    pixel_of(vp, {0.5f, 0, 1}, x, y);
    REQUIRE_FALSE(v2.none(x, y));
    CHECK(v2.at(x, y).x == doctest::Approx(want.x).epsilon(0.002));
}

TEST_CASE("velocity: the jitter is not part of the motion") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    RendererTestAccess::force_jitter(o.r, kJitterPhasesDefault);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    const Entity e = add_cube(w, {0, 0, 0});
    add_cube(w, {-4, 0, 0});
    bool jittered = false;
    for (int f = 0; f < 4; ++f) {
        move_to(w, e, {0.1f * float(f), 0, 0});
        o.frame(w);
        for (const Vec2& j : RendererTestAccess::last_jitter(o.r)) jittered = jittered || j.x != 0.0f || j.y != 0.0f;
        if (f == 0) continue;
        const Mat4 vp = matrix_of(o, cam);
        const Vel v = read_vel(o);
        const Vec3 d{0.1f, 0, 0};
        const Vec3 face = Vec3{0.1f * float(f), 0, 1};
        const Vec2 want = front_face_motion(vp, d, face);
        int x, y;
        pixel_of(vp, face, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CAPTURE(f);
        CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.003));
        CHECK(std::fabs(v.at(x, y).y) < 5.0e-4f);
        pixel_of(vp, {-4, 0, 1}, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CHECK(std::fabs(v.at(x, y).x) < 5.0e-4f);
    }
    CHECK(jittered);
}

TEST_CASE("velocity: terrain, foliage and impostor cards hold the camera's motion") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The terrain: a 64 m square of a flat 16-bit height map with a bump, seen by a camera that only turns.
    SUBCASE("terrain") {
        constexpr int kN = 65;
        GrayImage16 gi;
        gi.width = gi.height = kN;
        gi.sixteenBit = true;
        gi.samples.resize(std::size_t(kN) * kN);
        for (int r = 0; r < kN; ++r)
            for (int c = 0; c < kN; ++c) {
                const double dx = (c - 32) / 32.0, dz = (r - 32) / 32.0;
                gi.samples[std::size_t(r) * kN + std::size_t(c)] = std::uint16_t(
                    std::clamp(0.3 + 0.2 * std::max(0.0, 1.0 - std::sqrt(dx * dx + dz * dz)), 0.0, 1.0) * 65535.0);
            }
        const auto png = encode_png_gray16(gi);
        const std::string file = fs::path_to_utf8(g.projectDir / "velocity_terrain.png");
        REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        const Entity cam = add_camera(w, {0, 30, 50}, {-25, 0, 0}, 2000.0f);
        Entity t = make(w, "ground", {0, 0, 0});
        auto& terrain = w.add<Terrain3D>(t);
        terrain.heightmap = file;
        terrain.size = {64, 64};
        terrain.heightScale = 20.0f;
        o.frame(w);
        const Mat4 before = matrix_of(o, cam);
        w.get<Transform>(cam)->rotation = {-25, 4, 0};
        o.frame(w);
        const Mat4 after = matrix_of(o, cam);
        const Vel v = read_vel(o);
        const PanCheck c = check_pan(v, before, after);
        CAPTURE(c.worst);
        CHECK(c.drawn > 800);
        CHECK(c.wrong == 0);
        g.renderer.clear_asset_cache();
    }
    SUBCASE("foliage") {
        std::vector<FoliageInstance> in;
        for (int j = 0; j < 4; ++j)
            for (int i = 0; i < 5; ++i) {
                FoliageInstance f;
                f.position = {(float(i) - 2.0f) * 2.0f, 0.0f, -6.0f - float(j) * 2.0f};
                f.scale = 1.5f;
                f.yaw = float(i + j) * 0.7f;
                in.push_back(f);
            }
        const std::string file = fs::path_to_utf8(g.projectDir / "velocity_foliage.foliage");
        const auto written = write_foliage(file, in, 1);
        REQUIRE_MESSAGE(written.ok(), (written.ok() ? "" : written.error().message));
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        const Entity cam = add_camera(w, {0, 2, 0}, {0, 0, 0}, 500.0f);
        Entity f = make(w, "forest", {0, 0, 0});
        w.add<Foliage>(f).instances = file;
        o.frame(w);
        o.r.wait_foliage_loaded();
        o.frame(w);
        const Mat4 before = matrix_of(o, cam);
        yaw_to(w, cam, 4.0f);
        o.frame(w);
        const Mat4 after = matrix_of(o, cam);
        const Vel v = read_vel(o);
        const PanCheck c = check_pan(v, before, after);
        CAPTURE(c.worst);
        CHECK(c.drawn > 150);
        CHECK(c.wrong == 0);
        CHECK(o.r.stats().foliageInstances > 0);
    }
    SUBCASE("impostor") {
        std::filesystem::create_directories(g.projectDir / "assets" / "imp");
        ImpostorAtlas a;
        a.mode = ImpostorMode::Octahedral;
        a.views = 3;
        a.frameSize = 16;
        a.albedo = "assets/imp/velocity.impostor.png";
        a.normal = "assets/imp/velocity.impostor.normal.png";
        a.center = {0, 0, 0};
        a.radius = 1.0f;
        const int side = a.views * a.frameSize;
        Image albedo, normal;
        albedo.width = albedo.height = normal.width = normal.height = side;
        albedo.rgba.assign(std::size_t(side) * std::size_t(side) * 4, 0);
        normal.rgba.assign(std::size_t(side) * std::size_t(side) * 4, 0);
        for (int y = 0; y < side; ++y)
            for (int x = 0; x < side; ++x) {
                const std::size_t at = (std::size_t(y) * std::size_t(side) + std::size_t(x)) * 4;
                const float fx = float(x % a.frameSize) + 0.5f - float(a.frameSize) * 0.5f,
                            fy = float(y % a.frameSize) + 0.5f - float(a.frameSize) * 0.5f;
                const bool inside = std::sqrt(fx * fx + fy * fy) < float(a.frameSize) * 0.4f;
                albedo.rgba[at] = albedo.rgba[at + 1] = albedo.rgba[at + 2] = 200;
                albedo.rgba[at + 3] = inside ? 255 : 0;
                normal.rgba[at] = 128;
                normal.rgba[at + 1] = 255;
                normal.rgba[at + 2] = 128;
                normal.rgba[at + 3] = 255;
            }
        for (auto [img, path] : {std::pair<const Image*, std::string>{&albedo, a.albedo}, {&normal, a.normal}}) {
            const auto png = encode_png(*img);
            REQUIRE(fs::write_bytes(fs::path_to_utf8(g.projectDir / fs::path_from_utf8(path)), png.data(), png.size())
                        .ok());
        }
        const std::string json = impostor_to_json(a).dump(2);
        REQUIRE(fs::write_bytes(fs::path_to_utf8(g.projectDir / "assets/imp/velocity.impostor.json"), json.data(),
                                json.size())
                    .ok());
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        const Entity cam = add_camera(w, {0, 0, 10});
        Entity tree = make(w, "tree", {0, 0, -30});  // 40 m: the card
        w.get<Transform>(tree)->scale = {6, 6, 6};
        auto& m = w.add<MeshRenderer>(tree);
        m.mesh = "cube";
        m.unlit = true;
        m.impostor = "assets/imp/velocity.impostor.json";
        m.impostorDistance = 40.0f;
        o.frame(w);
        const Mat4 before = matrix_of(o, cam);
        yaw_to(w, cam, 2.0f);
        o.frame(w);
        const Mat4 after = matrix_of(o, cam);
        CHECK(o.r.stats().impostors == 1);
        const Vel v = read_vel(o);
        const PanCheck c = check_pan(v, before, after);
        CAPTURE(c.worst);
        CHECK(c.drawn > 100);
        CHECK(c.wrong == 0);
        g.renderer.clear_asset_cache();
    }
}

TEST_CASE(
    "velocity: asking for the velocity changes nothing of the picture, and with no consumer there is no prepass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // `on` asks for the velocity; `off` does not, but draws the prepass for an effect that reads the depth (so the only difference is the
    // second attachment); `plain` draws no prepass at all.
    auto scene = [](World& w, Entity& mover) {
        add_camera(w, {0, 0, 10});
        mover = add_cube(w, {0, 0, 0});
        add_cube(w, {-4, 0, 0});
    };
    auto run = [&](Own& o, World& w, Entity mover) {
        o.frame(w);
        move_to(w, mover, {0.5f, 0, 0});
        return o.draw(w);
    };
    Own on(g, true), off(g, false);
    REQUIRE_MESSAGE(on.ok, on.error);
    REQUIRE_MESSAGE(off.ok, off.error);
    render::renderer_force_post_effects(on.r, 1u << int(PostEffect::Ssao));
    render::renderer_force_post_effects(off.r, 1u << int(PostEffect::Ssao));
    World w1, w2;
    Entity m1, m2;
    scene(w1, m1);
    scene(w2, m2);
    const Image a = run(on, w1, m1);
    const Image b = run(off, w2, m2);
    REQUIRE(a.width == b.width);
    REQUIRE(a.rgba.size() == b.rgba.size());
    CHECK(a.rgba == b.rgba);
    // The velocity exists with the request and not without it.
    std::vector<float> px;
    int w = 0, h = 0;
    std::string err;
    CHECK(RendererTestAccess::read_velocity(on.r, px, w, h, &err));
    CHECK_FALSE(RendererTestAccess::read_velocity(off.r, px, w, h, &err));
    CHECK_FALSE(err.empty());
    const FrameGraph* graphOn = renderer_frame_graph(on.r);
    const FrameGraph* graphOff = renderer_frame_graph(off.r);
    REQUIRE(graphOn != nullptr);
    REQUIRE(graphOff != nullptr);
    auto has = [](const FrameGraph* gr, const char* needle) {
        for (const std::string& s : gr->order_names())
            if (s.find(needle) != std::string::npos) return true;
        return false;
    };
    CHECK(has(graphOn, "velocity-probe"));
    CHECK_FALSE(has(graphOff, "velocity-probe"));
    CHECK(has(graphOff, "prepass"));  // the effect still draws it
    render::renderer_force_post_effects(on.r, 0);
    render::renderer_force_post_effects(off.r, 0);
    // A camera with no consumer draws no prepass: the frame costs nothing for the feature.
    Own plain(g, false);
    REQUIRE_MESSAGE(plain.ok, plain.error);
    World w3;
    Entity m3;
    scene(w3, m3);
    plain.frame(w3);
    CHECK_FALSE(has(renderer_frame_graph(plain.r), "prepass"));
    CHECK_FALSE(RendererTestAccess::read_velocity(plain.r, px, w, h, &err));
}

TEST_CASE(
    "velocity: the debug view motionVectors paints the vectors over the picture and grey where nothing wrote one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g, false);  // no force: the debug view asks for the velocity itself
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    const Entity e = add_cube(w, {0, 0, 0});
    add_cube(w, {-4, 0, 0});
    o.frame(w);
    o.r.set_debug_view(DebugView::MotionVectors);
    CHECK(o.r.debug_view() == DebugView::MotionVectors);
    o.frame(w);
    move_to(w, e, {0.6f, 0, 0});
    const Image img = o.draw(w);
    o.r.set_debug_view(DebugView::None);
    const Mat4 vp = matrix_of(o, cam);
    int x, y;
    pixel_of(vp, {0.6f, 0, 1}, x, y);
    const Color moving = img.pixel(x, y);
    pixel_of(vp, {-4, 0, 1}, x, y);
    const Color still = img.pixel(x, y);
    const Color sky = img.pixel(3, 3);
    CHECK(std::max({moving.r, moving.g, moving.b}) > 0.5f);  // the moved cube: a bright colour
    CHECK(std::max({still.r, still.g, still.b}) < 0.1f);     // the still one: black
    // The sky wrote no vector: a mid grey (all channels alike).
    CHECK(std::fabs(sky.r - sky.g) < 0.02f);
    CHECK(std::fabs(sky.g - sky.b) < 0.02f);
    CHECK(sky.r > 0.05f);
    CHECK(sky.r < 0.7f);
    // The same view without anything drawn: the motion of a paused scene is black on the cubes.
    CHECK(o.r.supports("motionVectors"));
}

TEST_CASE("velocity: a skinned mesh holds the motion of its pose, of its entity, and none for a still one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo("engine/render/tests/data/skinned_two_bone.gltf", "assets/rig.gltf");
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 1, 5});
    const Entity rig = add_rig(w, "Slide");  // the whole column slides along x: 0 m at t = 0, 1 m from t = 0.5
    update_animators(w, 0.0f);
    REQUIRE(w.get<Animator>(rig)->palette.size() == 2);
    // A still pose over two frames: a vector (not the sentinel) and no motion.
    o.frame(w);
    o.frame(w);
    {
        const Mat4 vp = matrix_of(o, cam);
        const Vel v = read_vel(o);
        int x, y;
        pixel_of(vp, {0, 1, -0.25f}, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CHECK(std::fabs(v.at(x, y).x) < 5.0e-4f);
        CHECK(std::fabs(v.at(x, y).y) < 5.0e-4f);
    }
    // The pose moves the column by 1 m between two frames, the entity does not.
    update_animators(w, 0.6f);
    o.frame(w);
    {
        const Mat4 vp = matrix_of(o, cam);
        const Vel v = read_vel(o);
        const Vec3 at{1.0f, 1.0f, -0.25f};  // the column's faces wind inwards: the one seen is the far one (z = -0.25)
        const Vec2 want = front_face_motion(vp, {1, 0, 0}, at);
        int x, y;
        pixel_of(vp, at, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CHECK(std::fabs(want.x) > 0.05f);
        CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.003));
        CHECK(v.at(x, y).y == doctest::Approx(want.y).epsilon(0.0).scale(1.0).epsilon(0.003));
    }
    // A still pose and an entity that moves: the model's motion.
    o.frame(w);
    move_to(w, rig, {0, 0.5f, 0});
    o.frame(w);
    {
        const Mat4 vp = matrix_of(o, cam);
        const Vel v = read_vel(o);
        const Vec3 at{1.0f, 1.5f, -0.25f};
        const Vec2 want = front_face_motion(vp, {0, 0.5f, 0}, at);
        int x, y;
        pixel_of(vp, at, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CHECK(std::fabs(want.y) > 0.03f);
        CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.003));
        CHECK(v.at(x, y).y == doctest::Approx(want.y).epsilon(0.0).scale(1.0).epsilon(0.003));
    }
}

namespace {
// A skin of `joints` joints whose "Tip" is the last one (render/tests/data/make_skinned_two_bone.py): the vertices of the upper rings read a
// joint far past the 32nd. The "Slide" clip moves the whole column by 1 m between two poses, the entity stays: the vector of a point of the
// column is that motion, whichever ring (Root alone, the blend, Tip alone) the point is nearest to.
void check_big_skin(const char* file, std::size_t joints) {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo(file, "assets/rig.gltf");
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 1, 5});
    const Entity rig = add_rig(w, "Slide");
    update_animators(w, 0.0f);
    REQUIRE(w.get<Animator>(rig)->palette.size() == joints);
    o.frame(w);
    update_animators(w, 0.6f);
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    for (const float y : {0.3f, 1.0f, 1.7f}) {
        const Vec3 at{1.0f, y, -0.25f};
        const Vec2 want = front_face_motion(vp, {1, 0, 0}, at);
        int x, py;
        pixel_of(vp, at, x, py);
        CAPTURE(y);
        REQUIRE_FALSE(v.none(x, py));  // a vector, not the sentinel
        CHECK(std::fabs(want.x) > 0.05f);
        CHECK(v.at(x, py).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.003));
        CHECK(v.at(x, py).y == doctest::Approx(want.y).epsilon(0.0).scale(1.0).epsilon(0.003));
    }
    // The picture itself is the skinned one: the column is where the pose puts it.
    int x, py;
    pixel_of(vp, {1.0f, 1.0f, -0.25f}, x, py);
    CHECK(o.draw(w).pixel(x, py).r > 0.5f);
}
}  // namespace

TEST_CASE("velocity: a skin of 40 joints has real vectors (the palette of the frame before is read from an image, not "
          "a uniform block)") {
    check_big_skin("engine/render/tests/data/skinned_forty_joints.gltf", 40);
}

TEST_CASE("velocity: a skin of 64 joints has real vectors, with the joint of the upper rings at index 63") {
    check_big_skin("engine/render/tests/data/skinned_sixty_four_joints.gltf", 64);
}

namespace {
// The warnings the engine logged (category "render") while alive.
struct RenderWarnings {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    RenderWarnings()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level != LogLevel::Warn || e.category != "render") return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~RenderWarnings() { remove_log_sink(id); }
    RenderWarnings(const RenderWarnings&) = delete;
    RenderWarnings& operator=(const RenderWarnings&) = delete;
    int count(const char* needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        int n = 0;
        for (const std::string& m : shared->lines) n += m.find(needle) != std::string::npos ? 1 : 0;
        return n;
    }
};
// A column the "Slide" clip moves by 1 m between two poses, `count` of them 2 m apart along x (the first at x = `first`), each with its own
// animator and so its own previous palette; the camera sees them all. Returns the entities.
std::vector<Entity> add_rig_row(World& w, int count, float first) {
    std::vector<Entity> rigs;
    for (int i = 0; i < count; ++i) rigs.push_back(add_rig(w, "Slide", {first + 2.0f * float(i), 0, 0}));
    return rigs;
}
}  // namespace

TEST_CASE(
    "velocity: a GPU that cannot sample RGBA32F in the vertex stage gives skinned draws the sentinel, warns once, and "
    "the picture is the same") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo("engine/render/tests/data/skinned_forty_joints.gltf", "assets/rig.gltf");
    RenderWarnings warnings;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 1, 5});
    const Entity rig = add_rig(w, "Slide");
    (void)rig;
    RendererTestAccess::force_no_palette_sampling(o.r, true);
    update_animators(w, 0.0f);
    o.frame(w);
    update_animators(w, 0.6f);
    const Image limited = o.draw(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vec3 at{1.0f, 1.0f, -0.25f};
    int x, y;
    pixel_of(vp, at, x, y);
    {
        const Vel v = read_vel(o);
        CHECK(v.none(x, y));  // not a wrong vector: the sentinel, which the resolve reprojects from the depth
    }
    CHECK(limited.pixel(x, y).r > 0.5f);  // the column is drawn where the pose puts it
    CHECK(warnings.count("32-bit float") == 1);
    update_animators(w, 0.6f);
    o.frame(w);
    CHECK(warnings.count("32-bit float") == 1);  // once for the renderer
    // The same scene on a GPU that can: real vectors, and the very same picture.
    RendererTestAccess::force_no_palette_sampling(o.r, false);
    update_animators(w, 0.0f);
    o.frame(w);
    update_animators(w, 0.6f);
    const Image full = o.draw(w);
    const Vel v = read_vel(o);
    REQUIRE_FALSE(v.none(x, y));
    const Vec2 want = front_face_motion(matrix_of(o, cam), {1, 0, 0}, at);
    CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.003));
    REQUIRE(limited.rgba.size() == full.rgba.size());
    CHECK(limited.rgba == full.rgba);
}

TEST_CASE("velocity: past the rows of the palette image the skinned draws get the sentinel, the ones before them real "
          "vectors, and one warning names the count") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo("engine/render/tests/data/skinned_forty_joints.gltf", "assets/rig.gltf");
    RenderWarnings warnings;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const int count = 8;
    const Entity cam = add_camera(w, {0, 1, 16});
    const std::vector<Entity> rigs = add_rig_row(w, count, -7.0f);
    // One row of 1024 texels holds five of the 192-texel palettes (the engine's limit is 1024 rows: 5461 draws; the test hook cuts it to one).
    RendererTestAccess::set_palette_row_cap(o.r, 1);
    update_animators(w, 0.0f);
    o.frame(w);
    update_animators(w, 0.6f);
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    int real = 0, sentinel = 0;
    for (int i = 0; i < count; ++i) {
        const Vec3 at{-7.0f + 2.0f * float(i) + 1.0f, 1.0f, -0.25f};  // the column slid 1 m to the right
        int x, y;
        pixel_of(vp, at, x, y);
        CAPTURE(i);
        if (v.none(x, y)) {
            ++sentinel;
        } else {
            ++real;
            const Vec2 want = front_face_motion(vp, {1, 0, 0}, at);
            CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.003));
        }
    }
    CHECK(real == 5);
    CHECK(sentinel == 3);
    CHECK(warnings.count("skinned draws in one camera's frame") == 1);
    CHECK(warnings.count("5 skinned draws") == 1);
    // The engine's own limit (1024 rows: 5461 draws) holds all eight: every one has its vector, and nothing is warned.
    Own full(g);
    REQUIRE_MESSAGE(full.ok, full.error);
    World w2;
    const Entity cam2 = add_camera(w2, {0, 1, 16});
    add_rig_row(w2, count, -7.0f);
    update_animators(w2, 0.0f);
    full.frame(w2);
    update_animators(w2, 0.6f);
    full.frame(w2);
    const Vel all = read_vel(full);
    int real2 = 0;
    for (int i = 0; i < count; ++i) {
        int x, y;
        pixel_of(matrix_of(full, cam2), {-7.0f + 2.0f * float(i) + 1.0f, 1.0f, -0.25f}, x, y);
        real2 += all.none(x, y) ? 0 : 1;
    }
    CHECK(real2 == count);
    CHECK(warnings.count("skinned draws in one camera's frame") == 1);
}

TEST_CASE("velocity: two cameras with skinned meshes each read their own previous palettes") {
    // The frame graph runs after every camera has uploaded its palettes: a second camera must not overwrite the image of the first. Each camera
    // sees one column (the other is out of its frustum); one slides by 1 m between the frames, the other is frozen in the slid pose. The camera that drew first
    // (the lowest depth) is the one whose velocity the probe copies, and it is the one the old shared image broke.
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo("engine/render/tests/data/skinned_two_bone.gltf", "assets/rig.gltf");
    for (const int first : {0, 1}) {
        CAPTURE(first);
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        const float xs[2] = {-6.0f, 6.0f};
        Entity cams[2], rigs[2];
        for (int i = 0; i < 2; ++i) {
            cams[i] = add_camera(w, {xs[i], 1, 10});
            w.get<Camera>(cams[i])->depth = i == first ? 0 : 1;
            rigs[i] = add_rig(w, "Slide", {xs[i], 0, 0});
        }
        // The other one stays in its pose, which is the slid one: its previous palette (1 m) is not the previous palette of the sliding one (0 m).
        RendererTestAccess::probe_camera(o.r, cams[first]);
        update_animators(w, 0.0f);  // both start at their first pose
        Animator& other = *w.get<Animator>(rigs[1 - first]);
        other.time = 0.6f;  // a seek: the pose is evaluated again
        other.speed = 0.0f;
        update_animators(w, 0.0f);
        REQUIRE(other.palette.size() == 2);
        REQUIRE(other.palette[0].at(3, 0) == doctest::Approx(1.0f));
        REQUIRE(w.get<Animator>(rigs[first])->palette[0].at(3, 0) == doctest::Approx(0.0f));
        o.frame(w);
        o.frame(w);
        update_animators(w, 0.6f);
        o.frame(w);
        const Mat4 vp = matrix_of(o, cams[first]);
        const Vel v = read_vel(o);
        const Vec3 at{xs[first] + 1.0f, 1.0f, -0.25f};  // the column slid 1 m to the right
        const Vec2 want = front_face_motion(vp, {1, 0, 0}, at);
        int x, y;
        pixel_of(vp, at, x, y);
        REQUIRE_FALSE(v.none(x, y));
        CHECK(std::fabs(want.x) > 0.04f);
        CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.003));
        CHECK(v.at(x, y).y == doctest::Approx(want.y).epsilon(0.003));
    }
}

TEST_CASE("velocity: a skinned mesh of 64 joints draws the same picture with and without the velocity image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_file_from_repo("engine/render/tests/data/skinned_sixty_four_joints.gltf", "assets/rig.gltf");
    Own on(g, true), off(g, false);
    REQUIRE_MESSAGE(on.ok, on.error);
    REQUIRE_MESSAGE(off.ok, off.error);
    render::renderer_force_post_effects(
        on.r, 1u << int(PostEffect::Ssao));  // `off` draws the prepass too, so only the second attachment differs
    render::renderer_force_post_effects(off.r, 1u << int(PostEffect::Ssao));
    auto run = [&](Own& o) {
        World w;
        add_camera(w, {0, 1, 5});
        add_rig(w, "Slide");
        update_animators(w, 0.0f);
        o.frame(w);
        update_animators(w, 0.6f);
        return o.draw(w);
    };
    const Image a = run(on);
    const Image b = run(off);
    REQUIRE(a.rgba.size() == b.rgba.size());
    CHECK(a.rgba == b.rgba);
    render::renderer_force_post_effects(on.r, 0);
    render::renderer_force_post_effects(off.r, 0);
}

TEST_CASE("velocity: a GPU with no RG16F target makes no velocity image and no prepass for it, warns once, and the TAA "
          "reprojects from the camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RenderWarnings warnings;
    auto has = [](Own& o, const char* needle) {
        const FrameGraph* gr = renderer_frame_graph(o.r);
        REQUIRE(gr != nullptr);
        for (const std::string& n : gr->order_names())
            if (n.find(needle) != std::string::npos) return true;
        return false;
    };
    std::vector<float> px;
    int vw = 0, vh = 0;
    std::string err;
    {
        // The temporal antialiasing asks for the velocity (and, for its depth reprojection, for the prepass): the prepass is drawn with one
        // attachment, the effect runs with its history, and nothing reads a velocity image.
        Own o(g, true);
        REQUIRE_MESSAGE(o.ok, o.error);
        RendererTestAccess::force_no_velocity_target(o.r, true);
        World w;
        const Entity cam = add_camera(w, {0, 0, 10});
        const Entity cube = add_cube(w, {0, 0, 0});
        camera_post(w, cam).temporalAAEnabled = true;
        for (int f = 1; f <= 4; ++f) {
            w.advance_clock(1.0 / 60.0);
            move_to(w, cube, {0.05f * float(f), 0, 0});
            o.frame(w);
        }
        CHECK(has(o, "taa-resolve"));
        CHECK(RendererTestAccess::taa_used_history(o.r, cam));
        CHECK(has(o, "prepass"));
        CHECK_FALSE(has(o, "velocity-probe"));
        CHECK_FALSE(RendererTestAccess::read_velocity(o.r, px, vw, vh, &err));
        CHECK(warnings.count("RG16F") == 1);  // one warning for the four frames
        // The same renderer with the target back: the image exists, and no second warning.
        RendererTestAccess::force_no_velocity_target(o.r, false);
        w.advance_clock(1.0 / 60.0);
        o.frame(w);
        CHECK(has(o, "velocity-probe"));
        CHECK(RendererTestAccess::read_velocity(o.r, px, vw, vh, &err));
        CHECK(warnings.count("RG16F") == 1);
    }
    {
        // Nothing but the velocity asks (the test hook): there is no reason for a prepass, so none is drawn.
        Own o(g, true);
        REQUIRE_MESSAGE(o.ok, o.error);
        RendererTestAccess::force_no_velocity_target(o.r, true);
        World w;
        add_camera(w, {0, 0, 10});
        add_cube(w, {0, 0, 0});
        o.frame(w);
        o.frame(w);
        CHECK_FALSE(has(o, "prepass"));
        CHECK_FALSE(RendererTestAccess::read_velocity(o.r, px, vw, vh, &err));
        CHECK(warnings.count("RG16F") == 2);  // one a renderer
    }
}

TEST_CASE("velocity: a material's vertex() runs for the previous position with the game time of the frame before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera(w, {0, 0, 10});
    const Entity cube = add_cube(w, {0, 0, 0});
    w.get<MeshRenderer>(cube)->material = "materials/wave.material.json";  // vertex(): x += fa_time.x * 0.5
    w.advance_clock(1.0);
    o.frame(w);
    w.advance_clock(2.0);  // 1 s -> 3 s: the vertices slid from x = 0.5 to x = 1.5
    o.frame(w);
    const Mat4 vp = matrix_of(o, cam);
    const Vel v = read_vel(o);
    const Vec3 d{1.0f, 0, 0};
    const Vec3 at{1.5f, 0, 1};
    const Vec2 want = front_face_motion(vp, d, at);
    int x, y;
    pixel_of(vp, at, x, y);
    REQUIRE_FALSE(v.none(x, y));
    CHECK(std::fabs(want.x) > 0.05f);
    CHECK(v.at(x, y).x == doctest::Approx(want.x).epsilon(0.0).scale(1.0).epsilon(0.003));
    CHECK(v.at(x, y).y == doctest::Approx(want.y).epsilon(0.0).scale(1.0).epsilon(0.003));
    // The game time stands still: the vertex() puts every vertex where it was, no motion (the time is not the frame's counter).
    o.frame(w);
    const Vel still = read_vel(o);
    REQUIRE_FALSE(still.none(x, y));
    CHECK(std::fabs(still.at(x, y).x) < 5.0e-4f);
}
