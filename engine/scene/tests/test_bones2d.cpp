// fa/scene/bones2d.h: 2D bones, skinned sprites (SpriteSkin) and IK2D.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>

#include "fa/core/image.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/bounds.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

std::uint32_t bits_of(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

// A 100 x 20 sprite (pivot at the left edge, mid height) with a 10 x 2 mesh, and a two-bone arm of 50 + 50 along +X.
// The bones are children of the sprite unless `bonesOutside`.
struct Rig {
    World w;
    Entity body, b0, b1, target;
    explicit Rig(bool bonesOutside = false) {
        body = w.create("body", "body");
        Sprite& s = w.add<Sprite>(body);
        s.size = {100, 20};
        s.pivot = {0.0f, 0.5f};
        s.meshColumns = 10;
        s.meshRows = 2;
        const Entity root = bonesOutside ? w.create("rig", "rig") : body;
        b0 = w.create("b0", "b0");
        w.add<Bone2D>(b0).length = 50;
        w.set_parent(b0, root);
        b1 = w.create("b1", "b1");
        w.add<Bone2D>(b1).length = 50;
        w.set_parent(b1, b0);
        w.get<Transform>(b1)->position = {50, 0, 0};
        SpriteSkin& skin = w.add<SpriteSkin>(body);
        skin.bones = Json::array({"b0", "b1"});
        target = w.create("target", "target");
    }
    SkinBox box() const { return SkinBox{0, -10, 100, 10}; }
    SkinMesh mesh() {
        SkinMesh m;
        std::string problem;
        REQUIRE(build_skin_mesh(w, body, *w.get<Sprite>(body), box(), m, &problem));
        return m;
    }
    void set_rot(Entity e, float z) { w.get<Transform>(e)->rotation.z = z; }
    float rot(Entity e) { return w.get<Transform>(e)->rotation.z; }
    void set_pos(Entity e, float x, float y) { w.get<Transform>(e)->position = {x, y, 0}; }
    // IK2D on the lower bone.
    IK2D& ik(Vec2 at, IKSolver solver = IKSolver::TwoBone, IKBend bend = IKBend::Positive) {
        set_pos(target, at.x, at.y);
        IK2D& i = w.add<IK2D>(b1);
        i.target = target;
        i.solver = solver;
        i.bend = bend;
        return i;
    }
    Vec2 tip() { return bone_world_segment(w, b1).tip; }
    Vec2 elbow() { return bone_world_segment(w, b1).origin; }
};

Vec2 position_at(const SkinMesh& m, int column, int row) {
    // Find the used vertex whose uv is (column / columns, row / rows).
    const float u = float(column) / float(m.columns), v = float(row) / float(m.rows);
    for (std::size_t i = 0; i < m.position.size(); ++i)
        if (std::fabs(m.uv[i].x - u) < 1e-5f && std::fabs(m.uv[i].y - v) < 1e-5f) return m.position[i];
    FAIL("vertex not in the mesh");
    return {};
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ bones ----
TEST_CASE("bones2d: a bone runs length along its local X in the world") {
    Rig r;
    r.set_pos(r.b0, 10, 20);
    r.set_rot(r.b0, 90);
    const BoneSegment s = bone_world_segment(r.w, r.b0);
    CHECK(s.origin.x == doctest::Approx(10).epsilon(1e-4));
    CHECK(s.origin.y == doctest::Approx(20).epsilon(1e-4));
    CHECK(s.tip.x == doctest::Approx(10).epsilon(1e-3));
    CHECK(s.tip.y == doctest::Approx(70).epsilon(1e-4));
    const auto kite = bone_kite(s);
    CHECK(kite[0].x == doctest::Approx(s.origin.x));
    CHECK(kite[2].y == doctest::Approx(s.tip.y));
}

TEST_CASE("bones2d: the angle limit clamps to the nearest edge and wraps") {
    Bone2D b;
    b.minAngle = -30;
    b.maxAngle = 60;
    CHECK(bone_clamp_angle(b, 10) == doctest::Approx(10));
    CHECK(bone_clamp_angle(b, 100) == doctest::Approx(60));
    CHECK(bone_clamp_angle(b, -80) == doctest::Approx(-30));
    // 350 degrees is -10: inside. 200 is nearer to 60 (140 away) than to -30 (130 away through the back): -30.
    CHECK(bone_clamp_angle(b, 350) == doctest::Approx(-10));
    CHECK(bone_clamp_angle(b, 200) == doctest::Approx(-30));
    Bone2D free;  // -180..180 is a full turn: no limit
    CHECK(bone_clamp_angle(free, 1234) == doctest::Approx(1234));
}

// ------------------------------------------------------------------------------------------------------- resolution ----
TEST_CASE("bones2d: bones are found by name, by path and by id; a miss teaches") {
    Rig r;
    SpriteSkin skin = *r.w.get<SpriteSkin>(r.body);
    SkinBones ok = skin_resolve_bones(r.w, r.body, skin);
    REQUIRE(ok.entities.size() == 2);
    CHECK(ok.entities[0] == r.b0);
    CHECK(ok.entities[1] == r.b1);
    CHECK(ok.problems.empty());

    skin.bones = Json::array({"b0/b1", "b1"});  // a path of direct children, then a name at any depth
    ok = skin_resolve_bones(r.w, r.body, skin);
    CHECK(ok.entities[0] == r.b1);
    CHECK(ok.entities[1] == r.b1);

    skin.bones = Json::array({"b0", "b11"});
    const SkinBones bad = skin_resolve_bones(r.w, r.body, skin);
    REQUIRE(bad.entities.size() == 2);
    CHECK(bad.entities[1].is_null());
    REQUIRE(bad.problems.size() == 1);
    CHECK(bad.problems[0].find("b11") != std::string::npos);
    CHECK(bad.problems[0].find("Did you mean") != std::string::npos);
}

TEST_CASE("bones2d: a skeleton found under a parent of the sprite, not only under the sprite") {
    World w;
    Entity root = w.create("hero", "hero");
    Entity sprite = w.create("torso", "torso");
    w.set_parent(sprite, root);
    Entity hip = w.create("hip", "hip");
    w.add<Bone2D>(hip);
    w.set_parent(hip, root);
    SpriteSkin& skin = w.add<SpriteSkin>(sprite);
    skin.bones = Json::array({"hip"});
    const SkinBones found = skin_resolve_bones(w, sprite, skin);
    REQUIRE(found.entities.size() == 1);
    CHECK(found.entities[0] == hip);
}

// ------------------------------------------------------------------------------------------------------- bind pose ----
TEST_CASE("bones2d: the bind pose is recorded once, and an empty bindPose binds again") {
    Rig r;
    CHECK_FALSE(skin_is_bound(r.w, r.body));
    bind_pending_skins(r.w);
    REQUIRE(skin_is_bound(r.w, r.body));
    const Json pose = r.w.get<SpriteSkin>(r.body)->bindPose;
    CHECK(pose.size() == 12);

    r.set_rot(r.b1, 40);  // a pose change after the bind does not touch the recorded pose
    bind_pending_skins(r.w);
    CHECK(r.w.get<SpriteSkin>(r.body)->bindPose == pose);

    r.w.get<SpriteSkin>(r.body)->bindPose = Json::array();  // rebinds at the current pose
    bind_pending_skins(r.w);
    CHECK_FALSE(r.w.get<SpriteSkin>(r.body)->bindPose == pose);
    // ... and the bones at their bind pose leave the mesh as it was.
    const SkinMesh m = r.mesh();
    CHECK(position_at(m, 10, 1).x == doctest::Approx(100).epsilon(1e-3));
    CHECK(position_at(m, 10, 1).y == doctest::Approx(0).epsilon(1e-3));
}

TEST_CASE("bones2d: a skin without a bind pose, or with bones at the bind pose, draws undeformed") {
    Rig r;
    const SkinMesh before = r.mesh();  // not bound yet
    r.set_rot(r.b1, 70);
    const SkinMesh unbound = r.mesh();
    REQUIRE(before.position.size() == unbound.position.size());
    for (std::size_t i = 0; i < before.position.size(); ++i) {
        CHECK(before.position[i].x == unbound.position[i].x);
        CHECK(before.position[i].y == unbound.position[i].y);
    }
    CHECK(before.position.size() == 11 * 3);
    CHECK(before.quads.size() == 20);
}

TEST_CASE("bones2d: moving the sprite and its bones together deforms nothing") {
    Rig r;
    bind_pending_skins(r.w);
    const SkinMesh rest = r.mesh();
    r.set_pos(r.body, 300, -40);
    r.set_rot(r.body, 33);
    r.w.get<Transform>(r.body)->scale = {2, 2, 1};
    const SkinMesh moved = r.mesh();
    for (std::size_t i = 0; i < rest.position.size(); ++i) {
        CHECK(moved.position[i].x == doctest::Approx(rest.position[i].x).epsilon(1e-3));
        CHECK(moved.position[i].y == doctest::Approx(rest.position[i].y).epsilon(1e-3));
    }
}

// ------------------------------------------------------------------------------------------------------------ weights ----
TEST_CASE("bones2d: automatic weights follow the nearest bone, sum to one and break ties by index") {
    const std::vector<std::pair<Vec2, Vec2>> segs = {{{0, 0}, {50, 0}}, {{50, 0}, {100, 0}}};
    const auto w = auto_skin_weights({{0, 0}, {100, 0}, {50, 0}, {25, 30}}, segs);
    REQUIRE(w.size() == 4);
    CHECK(w[0].count >= 1);
    CHECK(w[0].bone[0] == 0);
    CHECK(w[0].weight[0] > 0.97f);
    CHECK(w[1].bone[0] == 1);
    CHECK(w[1].weight[0] > 0.97f);
    // At the joint both bones are at distance 0: equal weights, the lower index first.
    REQUIRE(w[2].count == 2);
    CHECK(w[2].bone[0] == 0);
    CHECK(w[2].bone[1] == 1);
    CHECK(w[2].weight[0] == doctest::Approx(0.5f));
    for (const VertexWeights& v : w) {
        float sum = 0;
        for (int i = 0; i < v.count; ++i) sum += v.weight[std::size_t(i)];
        CHECK(sum == doctest::Approx(1.0f).epsilon(1e-5));
    }
}

TEST_CASE("bones2d: a vertex follows at most four bones and drops those under 2 percent") {
    std::vector<std::pair<Vec2, Vec2>> segs;
    for (int i = 0; i < 6; ++i) segs.push_back({{float(i) * 2, 0}, {float(i) * 2 + 1, 0}});
    segs.push_back({{5000, 5000}, {5001, 5000}});  // far away: it cannot make the top four
    const auto w = auto_skin_weights({{5, 0}}, segs);
    CHECK(w[0].count <= 4);
    for (int i = 0; i < w[0].count; ++i) CHECK(w[0].bone[std::size_t(i)] != 6);

    const auto far = auto_skin_weights({{0, 0}}, {{{0, 0}, {10, 0}}, {{0, 4000}, {10, 4000}}});
    CHECK(far[0].count == 1);  // the second bone is under 2%
    CHECK(far[0].weight[0] == doctest::Approx(1.0f));
}

TEST_CASE("bones2d: auto weights are written out as explicit weights and give the same mesh") {
    Rig r;
    bind_pending_skins(r.w);
    r.set_rot(r.b1, 50);
    const SkinMesh autoMesh = r.mesh();
    Result<Json> weights = skin_auto_weights(r.w, r.body, r.box());
    REQUIRE(weights.ok());
    CHECK(weights->size() == 33);  // (10 + 1) x (2 + 1) vertices
    r.w.get<SpriteSkin>(r.body)->weights = *weights;
    const SkinMesh explicitMesh = r.mesh();
    REQUIRE(autoMesh.position.size() == explicitMesh.position.size());
    for (std::size_t i = 0; i < autoMesh.position.size(); ++i) {
        CHECK(autoMesh.position[i].x == doctest::Approx(explicitMesh.position[i].x).epsilon(1e-4));
        CHECK(autoMesh.position[i].y == doctest::Approx(explicitMesh.position[i].y).epsilon(1e-4));
    }
}

TEST_CASE("bones2d: explicit weights move a vertex by the bones they name") {
    Rig r;
    bind_pending_skins(r.w);
    // Every vertex follows b1 at weight 1: rotating b1 by 90 degrees about (50, 0) moves (100, 0) to (50, 50).
    Json all = Json::array();
    for (int i = 0; i < 33; ++i) all.push_back(Json::array({1, 1.0}));
    r.w.get<SpriteSkin>(r.body)->weights = all;
    r.set_rot(r.b1, 90);
    const SkinMesh m = r.mesh();
    const Vec2 p = position_at(m, 10, 1);
    CHECK(p.x == doctest::Approx(50).epsilon(1e-3));
    CHECK(p.y == doctest::Approx(50).epsilon(1e-3));
    const Vec2 q = position_at(m, 5, 1);  // (50, 0) is the pivot of the rotation
    CHECK(q.x == doctest::Approx(50).epsilon(1e-3));
    CHECK(q.y == doctest::Approx(0).epsilon(1e-3));
}

TEST_CASE("bones2d: a rotated bone bends the mesh with auto weights; the far end follows it, the root stays") {
    Rig r;
    bind_pending_skins(r.w);
    r.set_rot(r.b1, 90);
    const SkinMesh m = r.mesh();
    const Vec2 tip = position_at(m, 10, 1);
    CHECK(tip.x == doctest::Approx(50).epsilon(0.02));
    CHECK(tip.y == doctest::Approx(50).epsilon(0.02));
    const Vec2 root = position_at(m, 0, 1);
    CHECK(root.x == doctest::Approx(0).epsilon(0.02));
    CHECK(root.y == doctest::Approx(0).epsilon(0.02));
    // The joint region blends the two bones: it moves, but less than the tip.
    const Vec2 mid = position_at(m, 7, 1);
    CHECK(mid.y > 5.0f);
    CHECK(mid.y < tip.y);
}

TEST_CASE("bones2d: bones outside the sprite's subtree work too: a bone that travels drags the vertices with it") {
    Rig r(true);
    bind_pending_skins(r.w);
    // Same arm, same bind pose as under the sprite: a rotation of the lower bone bends the mesh the same way.
    r.set_rot(r.b1, 90);
    const Vec2 tip = position_at(r.mesh(), 10, 1);
    CHECK(tip.x == doctest::Approx(50).epsilon(0.02));
    CHECK(tip.y == doctest::Approx(50).epsilon(0.02));
    // The whole skeleton moves (the sprite does not): every vertex follows by the same offset.
    r.set_rot(r.b1, 0);
    r.w.get<Transform>(r.w.find_by_id("rig"))->position = {5, 7, 0};
    const SkinMesh moved = r.mesh();
    CHECK(position_at(moved, 0, 1).x == doctest::Approx(5).epsilon(1e-3));
    CHECK(position_at(moved, 10, 1).y == doctest::Approx(7).epsilon(1e-3));
    CHECK(position_at(moved, 4, 2).x == doctest::Approx(40 + 5).epsilon(1e-3));
}

TEST_CASE("bones2d: a skin is deterministic") {
    auto run = [] {
        Rig r;
        bind_pending_skins(r.w);
        r.set_rot(r.b0, 17.5f);
        r.set_rot(r.b1, -63.25f);
        return r.mesh();
    };
    const SkinMesh a = run(), b = run();
    REQUIRE(a.position.size() == b.position.size());
    for (std::size_t i = 0; i < a.position.size(); ++i) {
        CHECK(bits_of(a.position[i].x) == bits_of(b.position[i].x));
        CHECK(bits_of(a.position[i].y) == bits_of(b.position[i].y));
    }
}

TEST_CASE("bones2d: a sprite with neither a mesh nor an outline says how to fix it") {
    Rig r;
    r.w.get<Sprite>(r.body)->meshColumns = 0;
    SkinMesh m;
    std::string problem;
    CHECK_FALSE(build_skin_mesh(r.w, r.body, *r.w.get<Sprite>(r.body), r.box(), m, &problem));
    CHECK(problem.find("meshColumns") != std::string::npos);
    CHECK(problem.find("outline") != std::string::npos);
}

TEST_CASE("bones2d: the footprint of a skinned sprite follows the bones") {
    Rig r;
    bind_pending_skins(r.w);
    const auto rest = visual_footprints(r.w, r.body);
    REQUIRE(rest.size() == 1);
    r.set_rot(r.b1, 90);
    const auto bent = visual_footprints(r.w, r.body);
    REQUIRE(bent.size() == 1);
    float restMaxY = -1e9f, bentMaxY = -1e9f;
    for (const Vec2& p : rest[0].box) restMaxY = std::max(restMaxY, p.y);
    for (const Vec2& p : bent[0].box) bentMaxY = std::max(bentMaxY, p.y);
    CHECK(restMaxY == doctest::Approx(10).epsilon(1e-3));
    CHECK(bentMaxY > 40.0f);
}

// ------------------------------------------------------------------------------------------------------------ outline ----
TEST_CASE("bones2d: an outline mesh keeps the cells that hold opaque pixels") {
    // A 64 x 64 picture with an opaque 24 x 24 square at the top left.
    Image img;
    img.width = img.height = 64;
    img.rgba.assign(64 * 64 * 4, 0);
    for (int y = 0; y < 24; ++y)
        for (int x = 0; x < 24; ++x) img.rgba[(std::size_t(y) * 64 + std::size_t(x)) * 4 + 3] = 255;
    const std::filesystem::path path = std::filesystem::temp_directory_path() / "fa_bones2d_outline_test.png";
    REQUIRE(save_png(img, path.string()).ok());

    invalidate_sprite_outlines();
    const auto grid = sprite_outline_grid(path.string(), Rect{0, 0, 0, 0}, 8, 8);
    REQUIRE(grid->traced);
    REQUIRE(grid->keep.size() == 64);
    int kept = 0;
    for (std::uint8_t k : grid->keep) kept += k;
    CHECK(kept < 64);
    CHECK(kept >= 9);  // the 3 x 3 cells of the square, plus the one-pixel margin
    CHECK(grid->keep[0] == 1);             // top left: opaque
    CHECK(grid->keep[7 * 8 + 7] == 0);     // bottom right: empty
    CHECK(sprite_outline_grid(path.string(), Rect{0, 0, 0, 0}, 8, 8).get() == grid.get());  // cached

    // A skinned sprite with outline: true builds only the kept cells.
    World w;
    Entity e = w.create("shape", "shape");
    Sprite& s = w.add<Sprite>(e);
    s.texture = path.string();
    s.size = {64, 64};
    s.pivot = {0, 0};
    SpriteSkin& skin = w.add<SpriteSkin>(e);
    skin.outline = true;
    skin.outlineDetail = 8;
    Entity bone = w.create("bone", "bone");
    w.add<Bone2D>(bone).length = 30;
    w.set_parent(bone, e);
    skin.bones = Json::array({"bone"});
    SkinMesh m;
    std::string problem;
    REQUIRE(build_skin_mesh(w, e, s, SkinBox{0, 0, 64, 64}, m, &problem));
    CHECK(problem.empty());
    CHECK(int(m.quads.size()) == kept);

    // Replacing the picture and invalidating traces it again.
    for (auto& b : img.rgba) b = 255;
    REQUIRE(save_png(img, path.string()).ok());
    invalidate_sprite_outlines(path.string());
    const auto full = sprite_outline_grid(path.string(), Rect{0, 0, 0, 0}, 8, 8);
    int keptFull = 0;
    for (std::uint8_t k : full->keep) keptFull += k;
    CHECK(keptFull == 64);
    std::filesystem::remove(path);
}

TEST_CASE("bones2d: an outline whose picture cannot be read draws the full grid and says why") {
    invalidate_sprite_outlines();
    const auto grid = sprite_outline_grid("assets/definitely-not-here.png", Rect{0, 0, 0, 0}, 4, 4);
    CHECK_FALSE(grid->traced);
    CHECK(grid->problem.find("definitely-not-here.png") != std::string::npos);
    for (std::uint8_t k : grid->keep) CHECK(k == 1);
}

// ---------------------------------------------------------------------------------------------------------------- IK ----
TEST_CASE("ik2d: twoBone puts the tip on a reachable target") {
    Rig r;
    r.ik({60, 40});
    Result<float> left = solve_ik2d(r.w, r.b1);
    REQUIRE(left.ok());
    CHECK(*left == doctest::Approx(0).epsilon(1e-2));
    CHECK(r.tip().x == doctest::Approx(60).epsilon(1e-3));
    CHECK(r.tip().y == doctest::Approx(40).epsilon(1e-3));
    // The bone lengths did not change.
    CHECK(length(r.elbow()) == doctest::Approx(50).epsilon(1e-3));
    CHECK(length(r.tip() - r.elbow()) == doctest::Approx(50).epsilon(1e-3));
}

TEST_CASE("ik2d: out of reach, the chain stretches straight toward the target") {
    Rig r;
    r.ik({0, 300});
    Result<float> left = solve_ik2d(r.w, r.b1);
    REQUIRE(left.ok());
    CHECK(*left == doctest::Approx(200).epsilon(1e-3));
    CHECK(r.tip().x == doctest::Approx(0).epsilon(1e-2));
    CHECK(r.tip().y == doctest::Approx(100).epsilon(1e-2));
}

TEST_CASE("ik2d: a target closer than the difference of the bone lengths is still reached as near as possible") {
    Rig r;
    r.w.get<Bone2D>(r.b0)->length = 50;
    r.set_pos(r.b1, 50, 0);
    r.w.get<Bone2D>(r.b1)->length = 20;
    r.ik({1, 1});
    Result<float> left = solve_ik2d(r.w, r.b1);
    REQUIRE(left.ok());
    CHECK(*left == doctest::Approx(30.0f - length(Vec2{1, 1})).epsilon(1e-2));
}

TEST_CASE("ik2d: bend decides which side the elbow goes to") {
    Rig a, b;
    a.ik({60, 40}, IKSolver::TwoBone, IKBend::Positive);
    b.ik({60, 40}, IKSolver::TwoBone, IKBend::Negative);
    REQUIRE(solve_ik2d(a.w, a.b1).ok());
    REQUIRE(solve_ik2d(b.w, b.b1).ok());
    CHECK(a.tip().x == doctest::Approx(60).epsilon(1e-3));
    CHECK(b.tip().x == doctest::Approx(60).epsilon(1e-3));
    CHECK(a.tip().y == doctest::Approx(40).epsilon(1e-3));
    CHECK(b.tip().y == doctest::Approx(40).epsilon(1e-3));
    // Positive: the lower bone turns counter-clockwise, so the elbow is on the clockwise side of origin -> target.
    CHECK(a.rot(a.b1) > 0.0f);
    CHECK(b.rot(b.b1) < 0.0f);
    const Vec2 line{60, 40};
    const float sideA = line.x * a.elbow().y - line.y * a.elbow().x;
    const float sideB = line.x * b.elbow().y - line.y * b.elbow().x;
    CHECK(sideA < 0.0f);
    CHECK(sideB > 0.0f);
    // The two elbows are mirror images about the line.
    CHECK(length(a.elbow() + b.elbow() - line * (dot(a.elbow() + b.elbow(), line) / dot(line, line))) < 1e-2f);
}

TEST_CASE("ik2d: bend keeps its meaning under a mirrored parent") {
    Rig a, b;
    b.w.get<Transform>(b.body)->scale = {-1, 1, 1};  // mirrored along X: the elbow of "positive" ends on the mirrored side
    a.ik({60, 40});
    b.ik({-60, 40});
    REQUIRE(solve_ik2d(a.w, a.b1).ok());
    REQUIRE(solve_ik2d(b.w, b.b1).ok());
    CHECK(b.tip().x == doctest::Approx(-60).epsilon(1e-3));
    CHECK(b.tip().y == doctest::Approx(40).epsilon(1e-3));
    // The mirror image of a's chain is b's chain, elbow included.
    CHECK(b.elbow().x == doctest::Approx(-a.elbow().x).epsilon(1e-3));
    CHECK(b.elbow().y == doctest::Approx(a.elbow().y).epsilon(1e-3));
}

TEST_CASE("ik2d: angle limits are kept, and the tip falls short when they forbid the way") {
    Rig r;
    r.w.get<Bone2D>(r.b1)->minAngle = 0;  // the knee bends one way only
    r.w.get<Bone2D>(r.b1)->maxAngle = 150;
    r.ik({60, 40}, IKSolver::TwoBone, IKBend::Negative);  // needs a negative angle on the lower bone
    Result<float> left = solve_ik2d(r.w, r.b1);
    REQUIRE(left.ok());
    CHECK(r.rot(r.b1) >= -1e-3f);
    CHECK(*left > 1.0f);

    Rig ok;
    ok.w.get<Bone2D>(ok.b1)->minAngle = 0;
    ok.w.get<Bone2D>(ok.b1)->maxAngle = 150;
    ok.ik({60, 40}, IKSolver::TwoBone, IKBend::Positive);  // the allowed way
    Result<float> reached = solve_ik2d(ok.w, ok.b1);
    REQUIRE(reached.ok());
    CHECK(*reached == doctest::Approx(0).epsilon(1e-2));
    CHECK(ok.rot(ok.b1) >= 0.0f);
    CHECK(ok.rot(ok.b1) <= 150.0f);
}

TEST_CASE("ik2d: ccd reaches a target with a chain of three and respects the limits") {
    World w;
    Entity root = w.create("root", "root");
    Entity b0 = w.create("c0", "c0");
    w.add<Bone2D>(b0).length = 40;
    w.set_parent(b0, root);
    Entity b1 = w.create("c1", "c1");
    w.add<Bone2D>(b1).length = 40;
    w.set_parent(b1, b0);
    w.get<Transform>(b1)->position = {40, 0, 0};
    Entity b2 = w.create("c2", "c2");
    w.add<Bone2D>(b2).length = 40;
    w.set_parent(b2, b1);
    w.get<Transform>(b2)->position = {40, 0, 0};
    Entity target = w.create("t", "t");
    w.get<Transform>(target)->position = {30, 70, 0};
    IK2D& ik = w.add<IK2D>(b2);
    ik.target = target;
    ik.solver = IKSolver::Ccd;
    ik.chainLength = 3;
    w.get<Bone2D>(b1)->minAngle = -90;
    w.get<Bone2D>(b1)->maxAngle = 90;
    Result<float> left = solve_ik2d(w, b2);
    REQUIRE(left.ok());
    CHECK(*left < 0.5f);
    CHECK(w.get<Transform>(b1)->rotation.z <= 90.001f);
    CHECK(w.get<Transform>(b1)->rotation.z >= -90.001f);

    // Out of reach: it ends as near as it can, pointing straight at the target.
    w.get<Transform>(target)->position = {0, 500, 0};
    Result<float> far = solve_ik2d(w, b2);
    REQUIRE(far.ok());
    CHECK(*far == doctest::Approx(500 - 120).epsilon(0.02));

    // chainLength 1 turns only the tip bone.
    ik.chainLength = 1;
    w.get<Transform>(target)->position = {40 + 40 + 20, 20, 0};
    const float before0 = w.get<Transform>(b0)->rotation.z, before1 = w.get<Transform>(b1)->rotation.z;
    REQUIRE(solve_ik2d(w, b2).ok());
    CHECK(w.get<Transform>(b0)->rotation.z == before0);
    CHECK(w.get<Transform>(b1)->rotation.z == before1);
}

TEST_CASE("ik2d: weight blends the pose from the clip to the solved pose") {
    Rig full, half;
    full.set_rot(full.b0, 10);
    half.set_rot(half.b0, 10);
    full.ik({60, 40});
    half.ik({60, 40}).weight = 0.5f;
    REQUIRE(solve_ik2d(full.w, full.b1).ok());
    REQUIRE(solve_ik2d(half.w, half.b1).ok());
    CHECK(half.rot(half.b0) == doctest::Approx(10 + (full.rot(full.b0) - 10) * 0.5f).epsilon(1e-3));
    CHECK(half.rot(half.b1) == doctest::Approx(full.rot(full.b1) * 0.5f).epsilon(1e-3));
}

TEST_CASE("ik2d: it runs from the pose the clip left, every step, and update_ik2d solves all of them") {
    Rig r;
    r.ik({60, 40});
    update_ik2d(r.w);
    CHECK(r.tip().x == doctest::Approx(60).epsilon(1e-3));
    r.set_pos(r.target, -30, 50);  // the target moved; the next step follows
    r.set_rot(r.b0, 0);            // a clip wrote the bones again
    r.set_rot(r.b1, 0);
    update_ik2d(r.w);
    CHECK(r.tip().x == doctest::Approx(-30).epsilon(1e-3));
    CHECK(r.tip().y == doctest::Approx(50).epsilon(1e-3));
}

TEST_CASE("ik2d: problems teach") {
    Rig r;
    r.set_pos(r.target, 10, 10);
    IK2D& i = r.w.add<IK2D>(r.b0);  // twoBone on the root bone: the parent is the sprite, which has no Bone2D
    i.target = r.target;
    Result<float> noParent = solve_ik2d(r.w, r.b0);
    REQUIRE_FALSE(noParent.ok());
    CHECK(noParent.error().message.find("parent") != std::string::npos);
    CHECK_FALSE(noParent.error().hint.empty());

    r.w.add<IK2D>(r.b1);  // no target
    Result<float> noTarget = solve_ik2d(r.w, r.b1);
    REQUIRE_FALSE(noTarget.ok());
    CHECK(noTarget.error().message.find("target") != std::string::npos);

    Entity plain = r.w.create("plain", "plain");
    r.w.add<IK2D>(plain);
    Result<float> noBone = solve_ik2d(r.w, plain);
    REQUIRE_FALSE(noBone.ok());
    CHECK(noBone.error().message.find("Bone2D") != std::string::npos);

    // A chain longer than the bones above it.
    IK2D& c = r.w.get<IK2D>(r.b1) ? *r.w.get<IK2D>(r.b1) : r.w.add<IK2D>(r.b1);
    c.target = r.target;
    c.solver = IKSolver::Ccd;
    c.chainLength = 5;
    Result<float> tooLong = solve_ik2d(r.w, r.b1);
    REQUIRE_FALSE(tooLong.ok());
    CHECK(tooLong.error().hint.find("chainLength") != std::string::npos);
}

TEST_CASE("ik2d: it is deterministic") {
    auto run = [](IKSolver solver) {
        Rig r;
        r.ik({41.37f, 62.9f}, solver);
        r.w.get<IK2D>(r.b1)->chainLength = 2;
        REQUIRE(solve_ik2d(r.w, r.b1).ok());
        return std::array<std::uint32_t, 2>{bits_of(r.rot(r.b0)), bits_of(r.rot(r.b1))};
    };
    CHECK(run(IKSolver::TwoBone) == run(IKSolver::TwoBone));
    CHECK(run(IKSolver::Ccd) == run(IKSolver::Ccd));
}

// ------------------------------------------------------------------------------------------------------- components ----
TEST_CASE("bones2d: the components survive a save and a load") {
    Rig r;
    bind_pending_skins(r.w);
    r.ik({60, 40}, IKSolver::Ccd, IKBend::Negative);
    r.w.get<Bone2D>(r.b0)->minAngle = -45;
    r.w.get<Bone2D>(r.b0)->maxAngle = 90;
    r.w.get<SpriteSkin>(r.body)->weights = Json::array({Json::array({0, 1.0})});
    const Json scene = save_scene(r.w);
    World w2;
    const LoadReport report = load_scene(w2, scene, "test");
    CHECK(report.ok());
    Entity body = w2.find_by_id("body");
    REQUIRE(w2.alive(body));
    const SpriteSkin* skin = w2.get<SpriteSkin>(body);
    REQUIRE(skin != nullptr);
    CHECK(skin->bones == Json::array({"b0", "b1"}));
    CHECK(skin->bindPose.size() == 12);
    CHECK(skin->weights.is_array());
    const Bone2D* bone = w2.get<Bone2D>(w2.find_by_id("b0"));
    REQUIRE(bone != nullptr);
    CHECK(bone->length == 50);
    CHECK(bone->minAngle == -45);
    CHECK(bone->maxAngle == 90);
    const IK2D* ik = w2.get<IK2D>(w2.find_by_id("b1"));
    REQUIRE(ik != nullptr);
    CHECK(ik->solver == IKSolver::Ccd);
    CHECK(ik->bend == IKBend::Negative);
    CHECK(ik->target == w2.find_by_id("target"));
}
