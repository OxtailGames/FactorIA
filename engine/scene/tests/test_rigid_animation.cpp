// Rigid glTF animation (meshes that follow animated nodes without a skin of their own) and several skins over the same
// joints. The fixtures are tiny .glb files built here, so each layout is visible next to its expectation.
#include <doctest.h>

#include <cmath>
#include <cstring>
#include <filesystem>
#include <string>

#include "fa/core/fs.h"
#include "fa/scene/animation.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {

bool near(Vec3 a, Vec3 b, float eps = 1e-4f) { return length(a - b) < eps; }

// Builds a binary glTF: accessors are appended to one buffer; `doc` is the rest of the JSON (nodes, meshes, skins...).
struct Glb {
    std::vector<std::uint8_t> bin;
    Json accessors = Json::array(), views = Json::array();

    int add(const void* data, std::size_t bytes, int componentType, std::size_t count, const char* type) {
        while (bin.size() % 4) bin.push_back(0);
        views.push_back({{"buffer", 0}, {"byteOffset", bin.size()}, {"byteLength", bytes}});
        bin.insert(bin.end(), static_cast<const std::uint8_t*>(data), static_cast<const std::uint8_t*>(data) + bytes);
        accessors.push_back({{"bufferView", views.size() - 1}, {"componentType", componentType}, {"count", count}, {"type", type}});
        return int(accessors.size()) - 1;
    }
    int floats(const std::vector<float>& v, std::size_t comps, const char* type) {
        return add(v.data(), v.size() * 4, 5126, v.size() / comps, type);
    }
    int joints(const std::vector<std::uint16_t>& v) { return add(v.data(), v.size() * 2, 5123, v.size() / 4, "VEC4"); }

    std::vector<std::uint8_t> build(Json doc) const {
        doc["asset"] = {{"version", "2.0"}};
        doc["accessors"] = accessors;
        doc["bufferViews"] = views;
        doc["buffers"] = Json::array({Json{{"byteLength", (bin.size() + 3) & ~std::size_t(3)}}});
        std::string js = doc.dump();
        while (js.size() % 4) js += ' ';
        std::vector<std::uint8_t> bytes2 = bin;
        while (bytes2.size() % 4) bytes2.push_back(0);
        auto u32 = [](std::vector<std::uint8_t>& o, std::uint32_t v) { for (int i = 0; i < 4; ++i) o.push_back(std::uint8_t(v >> (8 * i))); };
        std::vector<std::uint8_t> out;
        u32(out, 0x46546C67);
        u32(out, 2);
        u32(out, std::uint32_t(12 + 8 + js.size() + 8 + bytes2.size()));
        u32(out, std::uint32_t(js.size()));
        u32(out, 0x4E4F534A);
        out.insert(out.end(), js.begin(), js.end());
        u32(out, std::uint32_t(bytes2.size()));
        u32(out, 0x004E4942);
        out.insert(out.end(), bytes2.begin(), bytes2.end());
        return out;
    }
};

// One triangle at (1,0,0) (0,1,0) (0,0,0) as primitive of mesh 0, with optional JOINTS_0 / WEIGHTS_0 accessors.
Json triangle_mesh(Glb& g, int joints = -1, int weights = -1) {
    const int pos = g.floats({1, 0, 0, 0, 1, 0, 0, 0, 0}, 3, "VEC3");
    Json attrs = {{"POSITION", pos}};
    if (joints >= 0) attrs["JOINTS_0"] = joints;
    if (weights >= 0) attrs["WEIGHTS_0"] = weights;
    return Json{{"primitives", Json::array({Json{{"attributes", attrs}}})}};
}

// A LINEAR animation channel: node, path, times and values.
void add_channel(Glb& g, Json& anim, int node, const char* path, const std::vector<float>& times, const std::vector<float>& values) {
    const int in = g.floats(times, 1, "SCALAR");
    const int out = g.floats(values, std::strcmp(path, "rotation") == 0 ? 4 : 3, std::strcmp(path, "rotation") == 0 ? "VEC4" : "VEC3");
    anim["samplers"].push_back({{"input", in}, {"output", out}, {"interpolation", "LINEAR"}});
    anim["channels"].push_back({{"sampler", anim["samplers"].size() - 1}, {"target", {{"node", node}, {"path", path}}}});
}

Json new_anim(const char* name) { return Json{{"name", name}, {"samplers", Json::array()}, {"channels", Json::array()}}; }

const float kQ90Z[4] = {0, 0, 0.70710678f, 0.70710678f};  // 90 degrees about Z

SkeletonAsset parse(const std::vector<std::uint8_t>& glb) {
    auto r = parse_skeleton(glb, "fixture.glb");
    const std::string err = r.ok() ? std::string() : r.error().to_string();
    INFO(err);
    REQUIRE(r.ok());
    return std::move(*r);
}

std::vector<Mat4> palette_at(const SkeletonAsset& sk, const char* clip, float time, int skin) {
    Pose pose = rest_pose(sk);
    sample_clip(sk, sk.clips[std::size_t(sk.find_clip(clip))], time, pose);
    return skin_palette(sk, pose, skin);
}

}  // namespace

TEST_CASE("rigid: a mesh under an animated bone follows it") {
    // 0 Root, 1 Arm (child of Root at y = 1, turns 90 degrees about Z in 1 s), 2 a mesh child of Arm, 3 a mesh child of Root.
    Glb g;
    Json doc;
    doc["meshes"] = Json::array({triangle_mesh(g), triangle_mesh(g)});
    doc["nodes"] = Json::array({Json{{"name", "Root"}, {"children", Json::array({1, 3})}},
                                Json{{"name", "Arm"}, {"translation", {0, 1, 0}}, {"children", Json::array({2})}},
                                Json{{"name", "Hand"}, {"mesh", 0}}, Json{{"name", "Still"}, {"mesh", 1}}});
    doc["scenes"] = Json::array({Json{{"nodes", Json::array({0})}}});
    Json anim = new_anim("Wave");
    add_channel(g, anim, 1, "rotation", {0, 1}, {0, 0, 0, 1, kQ90Z[0], kQ90Z[1], kQ90Z[2], kQ90Z[3]});
    doc["animations"] = Json::array({anim});
    const SkeletonAsset sk = parse(g.build(doc));

    // Both meshes sit under an animated node chain? Only Hand has an animated node (Arm) above it.
    REQUIRE(sk.skinVertices.size() == 1);
    const SkinVertices& sv = sk.skinVertices[0];
    CHECK(sv.rigid);
    CHECK(sv.node == 2);
    REQUIRE(sv.joints.size() == 3);
    CHECK(sv.joints[0][0] == 0);
    CHECK(sv.weights[0][0] == doctest::Approx(1.0f));
    REQUIRE(sk.skins.size() == 1);
    CHECK(sk.skins[0].joints == std::vector<int>{1});

    // Bind pose: identity. At t = 1 the hand vertex (1,1,0) (bind, model space) turns around the Arm at (0,1,0).
    const Vec3 bind{1, 1, 0};
    CHECK(near(palette_at(sk, "Wave", 0.0f, 0)[0].transform_point(bind), bind));
    const Vec3 end = palette_at(sk, "Wave", 1.0f, 0)[0].transform_point(bind);
    CHECK(end.x != doctest::Approx(bind.x));
    CHECK(near(end, {0, 2, 0}));
}

TEST_CASE("rigid: an animated mesh node with no skin is its own bone") {
    // The layout of Kenney's cube pets: the mesh nodes are the animated bones and the file has no skin at all.
    Glb g;
    Json doc;
    doc["meshes"] = Json::array({triangle_mesh(g), triangle_mesh(g)});
    doc["nodes"] = Json::array({Json{{"name", "Body"}, {"translation", {2, 0, 0}}, {"mesh", 0}, {"children", Json::array({1})}},
                                Json{{"name", "Head"}, {"translation", {0, 1, 0}}, {"mesh", 1}}});
    doc["scenes"] = Json::array({Json{{"nodes", Json::array({0})}}});
    Json anim = new_anim("Walk");
    add_channel(g, anim, 0, "translation", {0, 1}, {2, 0, 0, 4, 0, 0});
    doc["animations"] = Json::array({anim});
    const SkeletonAsset sk = parse(g.build(doc));

    REQUIRE(sk.skinVertices.size() == 2);  // the Head follows Body, which animates
    CHECK(sk.skinVertices[0].rigid);
    CHECK(sk.skinVertices[1].rigid);
    REQUIRE(sk.skins.size() == 1);
    REQUIRE(sk.skins[0].joints == std::vector<int>{0});  // one joint shared by both meshes
    const Vec3 headBind{2, 1, 0};
    CHECK(near(palette_at(sk, "Walk", 0.0f, 0)[0].transform_point(headBind), headBind));
    CHECK(near(palette_at(sk, "Walk", 1.0f, 0)[0].transform_point(headBind), {4, 1, 0}));
}

TEST_CASE("rigid: models that nothing animates add no skins") {
    Glb g;
    Json doc;
    doc["meshes"] = Json::array({triangle_mesh(g)});
    doc["nodes"] = Json::array({Json{{"name", "Prop"}, {"mesh", 0}}, Json{{"name", "Empty"}}});
    doc["scenes"] = Json::array({Json{{"nodes", Json::array({0, 1})}}});
    Json anim = new_anim("Idle");  // animates a node with no mesh below it: nothing can play it
    add_channel(g, anim, 1, "translation", {0, 1}, {0, 0, 0, 1, 0, 0});
    doc["animations"] = Json::array({anim});
    const SkeletonAsset sk = parse(g.build(doc));
    CHECK(sk.skinVertices.empty());
    CHECK(sk.skins.empty());
}

TEST_CASE("skins: every mesh keeps its own skin and the Animator writes one palette per skin") {
    // Joints A (node 0) and B (node 1, child of A at y = 1, turns 90 degrees about Z in 1 s). Skin 0 lists [A, B], skin 1
    // lists [B, A] with its own inverse binds. Mesh node 2 uses skin 0 and mesh node 3 skin 1, all weight on joint index 1
    // and 0 respectively, so both are carried by B.
    Glb g;
    Json doc;
    const int j0 = g.joints({1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0});
    const int j1 = g.joints({0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
    const int w = g.floats({1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0}, 4, "VEC4");
    const Mat4 ibB = Mat4::translate({0, -1, 0});
    std::vector<float> ibm0, ibm1;
    for (const Mat4& m : {Mat4::identity(), ibB}) ibm0.insert(ibm0.end(), m.m, m.m + 16);
    for (const Mat4& m : {ibB, Mat4::identity()}) ibm1.insert(ibm1.end(), m.m, m.m + 16);
    const int ib0 = g.floats(ibm0, 16, "MAT4"), ib1 = g.floats(ibm1, 16, "MAT4");
    doc["meshes"] = Json::array({triangle_mesh(g, j0, w), triangle_mesh(g, j1, w)});
    doc["nodes"] = Json::array({Json{{"name", "A"}, {"children", Json::array({1})}},
                                Json{{"name", "B"}, {"translation", {0, 1, 0}}},
                                Json{{"name", "Skin0"}, {"mesh", 0}, {"skin", 0}},
                                Json{{"name", "Skin1"}, {"mesh", 1}, {"skin", 1}}});
    doc["skins"] = Json::array({Json{{"joints", Json::array({0, 1})}, {"inverseBindMatrices", ib0}},
                                Json{{"joints", Json::array({1, 0})}, {"inverseBindMatrices", ib1}}});
    doc["scenes"] = Json::array({Json{{"nodes", Json::array({0, 2, 3})}}});
    Json anim = new_anim("Bend");
    add_channel(g, anim, 1, "rotation", {0, 1}, {0, 0, 0, 1, kQ90Z[0], kQ90Z[1], kQ90Z[2], kQ90Z[3]});
    doc["animations"] = Json::array({anim});
    const std::vector<std::uint8_t> glb = g.build(doc);
    const SkeletonAsset sk = parse(glb);

    REQUIRE(sk.skinVertices.size() == 2);
    CHECK(sk.skinVertices[0].skin == 0);
    CHECK(sk.skinVertices[1].skin == 1);
    CHECK_FALSE(sk.skinVertices[0].rigid);

    // Through the Animator, from a file in a scratch project.
    const std::filesystem::path dir = std::filesystem::temp_directory_path() / "fa_rigid_animation_test";
    std::filesystem::create_directories(dir);
    const std::filesystem::path old = fs::project_root();
    fs::set_project_root(dir);
    ensure_builtin_components();
    REQUIRE(fs::write_bytes("two_skins.glb", glb.data(), glb.size()).ok());
    {
        World world;
        Entity e = world.create("hero", "hero");
        world.add<MeshRenderer>(e).mesh = "two_skins.glb";
        Animator& a = world.add<Animator>(e);
        a.clip = "Bend";
        update_animators(world, 0.0f);
        REQUIRE(a.skinPalettes.size() == 2);
        update_animators(world, 1.0f);  // a looping clip: t = 1 wraps to the end of the first loop
        a.time = 1.0f;
        update_animators(world, 0.0f);
        // Both skins send the bind point of B's mesh (0,2,0) around B, but through their own joint order.
        const Vec3 tip{0, 2, 0};
        const Vec3 viaSkin0 = a.skinPalettes[0][1].transform_point(tip);
        const Vec3 viaSkin1 = a.skinPalettes[1][0].transform_point(tip);
        CHECK(near(viaSkin0, viaSkin1));
        CHECK(near(viaSkin0, {-1, 1, 0}));
        CHECK(near(a.skinPalettes[0][0].transform_point(tip), tip));  // joint A does not move
        CHECK(near(a.skinPalettes[1][1].transform_point(tip), tip));
        CHECK(a.palette.size() == 2);
    }
    fs::set_project_root(old);
    std::filesystem::remove_all(dir);
}
