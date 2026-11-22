// M75-P1c on a GPU: the impostor a MeshRenderer is drawn as beyond impostorDistance (docs/BIG_WORLDS_LOD.md, "Impostors"): the pick by
// distance and by screen size, the dithered cross-fade with the last level, the atlas files that are missing or wrong (one warning, the
// last level keeps drawing) and the pixels the card draws against the CPU side of the atlas (fa/scene/impostor.h). The atlas maths and the
// bake are tested in engine/scene/tests/impostor_tests.cpp and tools/common/tests/model_impostor_test.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/scene/impostor.h"

using namespace fa;
using namespace fa::test;

namespace {

// The warnings and errors logged while the object lives.
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
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(std::count_if(shared->lines.begin(), shared->lines.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
};

Entity add_camera(World& w, Vec3 pos, Vec3 rotation = {0, 0, 0}) {
    Entity cam = make(w, "cam", pos);
    w.get<Transform>(cam)->rotation = rotation;
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color::hex(0x202830);
    return cam;
}

// The colour the test atlas gives the frame (i, j): all different, none dark, so the pixel says which frame the card drew.
Color frame_colour(int i, int j) {
    return Color{(30.0f + 90.0f * float(i)) / 255.0f, (30.0f + 90.0f * float(j)) / 255.0f, 200.0f / 255.0f, 1.0f};
}

// Writes assets/imp/<name>.impostor.json and its two pictures: 3 x 3 frames of 16 pixels, each one colour inside a disc of half the frame
// (transparent around it), radius 1 around the origin. Returns the project path of the json.
std::string write_atlas(const std::string& name, ImpostorMode mode = ImpostorMode::Octahedral, int views = 3,
                        int frame = 16) {
    Gfx& g = gfx();
    std::filesystem::create_directories(g.projectDir / "assets" / "imp");
    ImpostorAtlas a;
    a.mode = mode;
    a.views = views;
    a.frameSize = frame;
    a.albedo = "assets/imp/" + name + ".impostor.png";
    a.normal = "assets/imp/" + name + ".impostor.normal.png";
    a.center = {0, 0, 0};
    a.radius = 1.0f;
    const int side = views * frame;
    Image albedo, normal;
    albedo.width = albedo.height = normal.width = normal.height = side;
    albedo.rgba.assign(std::size_t(side) * std::size_t(side) * 4, 0);
    normal.rgba.assign(std::size_t(side) * std::size_t(side) * 4, 0);
    for (int y = 0; y < side; ++y)
        for (int x = 0; x < side; ++x) {
            const std::size_t at = (std::size_t(y) * std::size_t(side) + std::size_t(x)) * 4;
            const float fx = float(x % frame) + 0.5f - float(frame) * 0.5f,
                        fy = float(y % frame) + 0.5f - float(frame) * 0.5f;
            const Color c = frame_colour(x / frame, y / frame);
            const bool inside = std::sqrt(fx * fx + fy * fy) < float(frame) * 0.25f;
            albedo.rgba[at] = std::uint8_t(std::lround(c.r * 255.0f));
            albedo.rgba[at + 1] = std::uint8_t(std::lround(c.g * 255.0f));
            albedo.rgba[at + 2] = std::uint8_t(std::lround(c.b * 255.0f));
            albedo.rgba[at + 3] = inside ? 255 : 0;
            normal.rgba[at] = 128;
            normal.rgba[at + 1] = 255;
            normal.rgba[at + 2] = 128;
            normal.rgba[at + 3] = 255;
        }
    for (auto [img, path] : {std::pair<const Image*, std::string>{&albedo, a.albedo}, {&normal, a.normal}}) {
        const auto png = encode_png(*img);
        REQUIRE(
            fs::write_bytes(fs::path_to_utf8(g.projectDir / fs::path_from_utf8(path)), png.data(), png.size()).ok());
    }
    const std::string file = "assets/imp/" + name + ".impostor.json";
    const std::string text = impostor_to_json(a).dump(2);
    REQUIRE(fs::write_bytes(fs::path_to_utf8(g.projectDir / fs::path_from_utf8(file)), text.data(), text.size()).ok());
    return file;
}

void write_text(const std::string& file, const std::string& text) {
    std::filesystem::create_directories((gfx().projectDir / fs::path_from_utf8(file)).parent_path());
    REQUIRE(
        fs::write_bytes(fs::path_to_utf8(gfx().projectDir / fs::path_from_utf8(file)), text.data(), text.size()).ok());
}

// A unit cube that becomes the atlas's card from `distance` metres on (the unit of lodMode).
Entity add_tree(World& w, Vec3 pos, const std::string& atlas, float distance = 40.0f) {
    Entity e = make(w, "tree", pos);
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.unlit = true;
    m.impostor = atlas;
    m.impostorDistance = distance;
    return e;
}

}  // namespace

TEST_CASE("impostor render: the feature row says true where the card is drawn, and a scene with none counts 0") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CHECK(g.renderer.supports("impostors"));
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = make(w, "m", {0, 0, 0});
    w.add<MeshRenderer>(e).mesh = "cube";
    g.render(w);
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: a MeshRenderer draws its card from impostorDistance on, and the cards are not meshes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("pick");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_tree(w, {0, 0, 0}, atlas);  // 10 m: the cube
    g.render(w);
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    w.get<Transform>(e)->position = {0, 0, -29.9f};  // 39.9 m: still the cube
    g.render(w);
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    w.get<Transform>(e)->position = {0, 0, -30};  // 40 m: the threshold itself belongs to the card
    g.render(w);
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().meshes == 0);
    CHECK(g.renderer.stats().lodCrossFades == 0);  // crossFade 0: a hard switch
    // Three trees, two atlases: three cards.
    const std::string other = write_atlas("pick2", ImpostorMode::HemiOctahedral);
    add_tree(w, {3, 0, -30}, atlas);
    add_tree(w, {-3, 0, -30}, other);
    g.render(w);
    CHECK(g.renderer.stats().impostors == 3);
    CHECK(g.renderer.stats().meshes == 0);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: lodMode screenSize picks the card by the size on the screen") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("screen");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_tree(w, {0, 0, 0}, atlas, 0.1f);
    w.get<MeshRenderer>(e)->lodMode = LodMode::ScreenSize;
    g.render(w);  // the cube's box is 1.73 m across, in a view 11.5 m tall at 10 m: 0.15 of the screen
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    w.get<Transform>(e)->position = {0, 0, -30};  // 40 m: 0.04
    g.render(w);
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().meshes == 0);
    w.get<Transform>(e)->scale = {4, 4, 4};  // as big as 4 times closer: 0.15 again, the cube
    g.render(w);
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: the cross-fade with the last level draws both for crossFade seconds, then only the card") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("fade");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_tree(w, {0, 0, 0}, atlas);
    w.get<MeshRenderer>(e)->lodCrossFade = 0.5f;
    const float dt = 0.125f;  // a power of two: the fade's steps add up exactly
    g.render(w, dt);
    g.render(w, dt);
    w.get<Transform>(e)->position = {0, 0, -30};
    int fading = 0;
    for (int i = 0; i < 10; ++i) {
        g.render(w, dt);
        const RenderStats& st = g.renderer.stats();
        if (st.lodCrossFades == 0) break;
        ++fading;
        CHECK(st.lodCrossFades == 2);  // each level of the entity counts
        CHECK(st.meshes == 1);         // the cube
        CHECK(st.impostors == 1);      // and the card
    }
    CHECK(fading == 3);  // t = 0.25, 0.5, 0.75; the fourth frame reaches 1
    CHECK(g.renderer.stats().meshes == 0);
    CHECK(g.renderer.stats().impostors == 1);
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 0);
    // Back inside the distance the card fades out into the cube.
    w.get<Transform>(e)->position = {0, 0, 0};
    g.render(w, dt);
    CHECK(g.renderer.stats().lodCrossFades == 2);
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().meshes == 1);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: the card replaces the last of several levels, the earlier ones draw as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("levels");
    World w;
    add_camera(w, {0, 0, 10});
    Entity e = add_tree(w, {0, 0, 0}, atlas, 60.0f);
    w.get<MeshRenderer>(e)->lods = Json::array({Json{{"mesh", "sphere"}, {"distance", 30}}});
    g.render(w);
    CHECK(g.renderer.stats().impostors == 0);
    w.get<Transform>(e)->position = {0, 0, -30};  // 40 m: the sphere, no card yet
    g.render(w);
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    w.get<Transform>(e)->position = {0, 0, -60};  // 70 m
    g.render(w);
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().meshes == 0);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: a missing or wrong atlas warns once and the last level keeps drawing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    write_text("assets/imp/broken.impostor.json", "{ this is not json");
    const std::string good = write_atlas("small", ImpostorMode::Octahedral, 3, 16);
    // The picture of 'wrongsize' is not the size the json says (3 x 16 = 48): the json of 'small' with the pictures of another atlas.
    write_atlas("big", ImpostorMode::Octahedral, 4, 16);
    {
        ImpostorAtlas a;
        a.views = 3;
        a.frameSize = 16;
        a.albedo = "assets/imp/big.impostor.png";
        a.normal = "assets/imp/big.impostor.normal.png";
        a.radius = 1.0f;
        write_text("assets/imp/wrongsize.impostor.json", impostor_to_json(a).dump(2));
    }
    ProblemLog log;
    World w;
    add_camera(w, {0, 0, 10});
    int n = 0;
    for (const char* name : {"gone", "broken", "wrongsize"}) {
        Entity e = add_tree(w, {float(n) * 4.0f - 4.0f, 0, -30}, std::string("assets/imp/") + name + ".impostor.json");
        (void)e;
        ++n;
    }
    for (int i = 0; i < 4; ++i) {
        g.render(w);
        CHECK(g.renderer.stats().impostors == 0);
        CHECK(g.renderer.stats().meshes == 3);  // the cubes the three of them keep drawing
    }
    CHECK(log.count("assets/imp/gone.impostor.json") == 1);
    CHECK(log.count("assets/imp/broken.impostor.json") == 1);
    CHECK(log.count("assets/imp/wrongsize.impostor.json") == 1);
    CHECK(log.count("model.bake_impostor") == 3);  // every warning says how to fix it
    // A valid atlas next to them still draws.
    add_tree(w, {8, 0, -30}, good);
    g.render(w);
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().meshes == 3);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: the card shows the frame the CPU pick says, in front of a transparent surround") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("pixels");
    // Four cameras on the axes: each looks at the tree from a direction that is exactly one frame of the 3 x 3 grid.
    struct View {
        Vec3 from, rotation;
    };
    const View views[] = {
        {{0, 0, 40}, {0, 0, 0}}, {{40, 0, 0}, {0, 90, 0}}, {{-40, 0, 0}, {0, -90, 0}}, {{0, 40, 0}, {-90, 0, 0}}};
    for (const View& v : views) {
        World w;
        add_camera(w, v.from, v.rotation);
        World empty;
        add_camera(empty, v.from, v.rotation);
        const Image background = g.render(empty);
        Entity e = add_tree(w, {0, 0, 0}, atlas, 10.0f);
        const Image img = g.render(w);
        REQUIRE(g.renderer.stats().impostors == 1);
        const ImpostorPick pick = impostor_pick(ImpostorMode::Octahedral, 3, normalize(v.from));
        int best = 0;
        for (int k = 1; k < 3; ++k)
            if (pick.weight[k] > pick.weight[best]) best = k;
        CHECK(pick.weight[best] == doctest::Approx(1.0f).epsilon(1e-3));
        const Color want = frame_colour(pick.frame[best] % 3, pick.frame[best] / 3);
        const Color got = img.pixel(160, 90);
        INFO("camera at (" << v.from.x << ", " << v.from.y << ", " << v.from.z << "), frame " << pick.frame[best]);
        CHECK(std::fabs(got.r - want.r) < 0.06f);
        CHECK(std::fabs(got.g - want.g) < 0.06f);
        CHECK(std::fabs(got.b - want.b) < 0.06f);
        // The corner of the frame is transparent: the pixel is the background's. The disc is half the frame: 0.5 of the card's radius.
        // At 40 m the radius of 1 m is about 24 pixels.
        const Color corner = img.pixel(160 + 20, 90 + 20), clear = background.pixel(160 + 20, 90 + 20);
        CHECK(std::fabs(corner.r - clear.r) < 0.02f);
        CHECK(std::fabs(corner.g - clear.g) < 0.02f);
        CHECK(std::fabs(corner.b - clear.b) < 0.02f);
        (void)e;
        g.renderer.clear_asset_cache();
    }
}

TEST_CASE("impostor render: the card turns with the entity, so a turned tree shows the frame of its own side") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("turned");
    World w;
    add_camera(w, {0, 0, 40});
    Entity e = add_tree(w, {0, 0, 0}, atlas, 10.0f);
    g.render(w);
    const Color front = g.render(w).pixel(160, 90);
    // Turned 90 degrees about y, the camera on +z sees what a camera on +x or -x saw of the unturned tree.
    w.get<Transform>(e)->rotation = {0, 90, 0};
    const Color side = g.render(w).pixel(160, 90);
    CHECK((std::fabs(front.r - side.r) > 0.2f || std::fabs(front.g - side.g) > 0.2f));
    // The frame the CPU pick names for the model-space direction that rotation gives.
    const Vec3 local = normalize(Quat::from_euler_deg({0, 90, 0}).conjugate().rotate(Vec3{0, 0, 1}));
    const ImpostorPick pick = impostor_pick(ImpostorMode::Octahedral, 3, local);
    int best = 0;
    for (int k = 1; k < 3; ++k)
        if (pick.weight[k] > pick.weight[best]) best = k;
    const Color want = frame_colour(pick.frame[best] % 3, pick.frame[best] / 3);
    CHECK(std::fabs(side.r - want.r) < 0.06f);
    CHECK(std::fabs(side.g - want.g) < 0.06f);
    CHECK(std::fabs(side.b - want.b) < 0.06f);
    g.renderer.clear_asset_cache();
}

TEST_CASE(
    "impostor render: a LodGroup with an hlodProxy and an impostor in the same entity draw each their own level") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("hlod_group");
    World w;
    add_camera(w, {0, 0, 10});
    // The group has an impostor of its own (a MeshRenderer on the group entity, which a group does not hide) and ONE child
    // (LOD 0) that is an impostor too. The proxy replaces the children from 60 m, the cards start at 40 m.
    Entity group = add_tree(w, {0, 0, 0}, atlas);
    auto& lg = w.add<LodGroup>(group);
    lg.hlodProxy = "sphere";
    lg.hlodThreshold = 60.0f;
    Entity kid = add_tree(w, {0, 0, 0}, atlas);
    w.set_parent(kid, group);
    g.render(w);  // 10 m: both cubes, no card, no proxy
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().meshes == 2);
    w.get<Transform>(group)->position = {0, 0, -30};  // 40 m: the two cards (the child is at the group's place)
    g.render(w);
    CHECK(g.renderer.stats().impostors == 2);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().meshes == 0);
    w.get<Transform>(group)->position = {0, 0, -60};  // 70 m: the proxy replaces the child, the group's own card stays
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 1);
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().meshes == 1);            // the proxy; the cards are not meshes
    w.get<Transform>(group)->position = {0, 0, -30};  // back at 40 m: the child's card comes back and the proxy goes
    g.render(w);
    CHECK(g.renderer.stats().hlodProxies == 0);
    CHECK(g.renderer.stats().impostors == 2);
    CHECK(g.renderer.stats().meshes == 0);
    g.renderer.clear_asset_cache();
}

TEST_CASE("impostor render: the proxy fades in over the child's card with one cross-fade, both drawn for its seconds") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string atlas = write_atlas("hlod_fade");
    World w;
    add_camera(w, {0, 0, 10});
    Entity group = make(w, "group", {0, 0, -30});  // 40 m: the child is a card
    auto& lg = w.add<LodGroup>(group);
    lg.hlodProxy = "sphere";
    lg.hlodThreshold = 60.0f;
    lg.crossFade = 1.0f;
    Entity kid = add_tree(w, {0, 0, -30}, atlas);
    w.set_parent(kid, group);
    const float dt = 0.25f;
    g.render(w, dt);
    g.render(w, dt);  // settled
    CHECK(g.renderer.stats().impostors == 1);
    CHECK(g.renderer.stats().hlodProxies == 0);
    w.get<Transform>(group)->position = {0, 0, -60};  // 70 m: the group's level changes to the proxy and fades
    w.get<Transform>(kid)->position = {0, 0, -60};
    g.render(w, dt);
    CHECK(g.renderer.stats().hlodProxies == 1);   // the proxy is fading in
    CHECK(g.renderer.stats().impostors == 1);     // the child's card is still fading out
    for (int i = 0; i < 6; ++i) g.render(w, dt);  // past the second
    CHECK(g.renderer.stats().hlodProxies == 1);
    CHECK(g.renderer.stats().impostors == 0);
    CHECK(g.renderer.stats().meshes == 1);
    g.renderer.clear_asset_cache();
}
