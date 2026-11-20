// M71: the CPU side of the post-processing stack (src/postprocess_resolve.h: which volumes apply at a camera and the one blended stack) and
// the per-backend feature table behind Renderer::supports (src/render_features.h). No GPU: a camera is a CameraGeometry filled by hand, a
// GPU is a FeatureEnv.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <iterator>
#include <set>
#include <string>
#include <vector>

#include "fa/render/post_custom.h"
#include "fa/render/renderer.h"
#include "postprocess_resolve.h"
#include "render_features.h"

using namespace fa;
using namespace fa::render;

namespace {

struct Scene {
    World world;
    Entity cam;
    CameraGeometry geo;
    explicit Scene(Vec3 camPos = {0, 0, 0}, bool perspective = true) {
        cam = world.create("cam", "cam");
        world.add<Camera>(cam);
        set_camera(camPos, perspective);
    }
    void set_camera(Vec3 pos, bool perspective = true) {
        geo.entity = cam;
        geo.position = pos;
        geo.perspective = perspective;
    }
    Entity volume(const char* id, Vec3 pos = {}) {
        Entity e = world.create(id, id);
        world.get<Transform>(e)->position = pos;
        world.add<PostProcess>(e);
        return e;
    }
    PostProcess& pp(Entity e) { return *world.get<PostProcess>(e); }
    PostStack resolve() { return resolve_post_stack(world, geo); }
};

}  // namespace

TEST_CASE("resolve_post_stack: a world without PostProcess gives the neutral stack") {
    Scene s;
    const PostStack st = s.resolve();
    CHECK_FALSE(st.any());
    CHECK(st.mask == 0);
    CHECK(st.sources == 0);
    CHECK(st.effect_count() == 0);
    CHECK(st.fx.tonemapMode == TonemapMode::None);
}

TEST_CASE("resolve_post_stack: a global volume applies everywhere, exactly at weight 1") {
    Scene s({1000, -50, 3});
    Entity v = s.volume("grade");
    s.pp(v).bloomEnabled = true;
    s.pp(v).bloomIntensity = 2.0f;
    s.pp(v).tonemapEnabled = true;
    s.pp(v).tonemapMode = TonemapMode::Aces;
    const PostStack st = s.resolve();
    CHECK(st.sources == 1);
    CHECK(st.has(PostEffect::Bloom));
    CHECK(st.has(PostEffect::Tonemap));
    CHECK_FALSE(st.has(PostEffect::Vignette));
    CHECK(st.effect_count() == 2);
    CHECK(st.fx.bloomEnabled);
    CHECK(st.fx.bloomIntensity == 2.0f);
    CHECK(st.fx.tonemapMode == TonemapMode::Aces);
    CHECK(st.mask == ((1u << int(PostEffect::Bloom)) | (1u << int(PostEffect::Tonemap))));
}

TEST_CASE("resolve_post_stack: the camera's own PostProcess is its stack, another camera's is nobody's volume") {
    Scene s;
    s.world.add<PostProcess>(s.cam).vignetteEnabled = true;
    s.world.get<PostProcess>(s.cam)->vignetteIntensity = 0.7f;
    Entity other = s.world.create("cam2", "cam2");
    s.world.add<Camera>(other);
    s.world.add<PostProcess>(other).bloomEnabled = true;
    PostStack st = s.resolve();
    CHECK(st.sources == 1);
    CHECK(st.has(PostEffect::Vignette));
    CHECK_FALSE(st.has(PostEffect::Bloom));
    CHECK(st.fx.vignetteIntensity == 0.7f);
    // From the other camera the picture is the other way round.
    s.geo.entity = other;
    st = s.resolve();
    CHECK(st.has(PostEffect::Bloom));
    CHECK_FALSE(st.has(PostEffect::Vignette));
}

TEST_CASE("post_volume_influence: box inside, on the edge, in the blend band and outside") {
    Scene s;
    Entity v = s.volume("box");
    PostProcess& p = s.pp(v);
    p.shape = PostShape::Box;
    p.size = {10, 6, 4};  // half extents 5, 3, 2
    p.blendDistance = 4;
    const Mat4 m = s.world.world_matrix(v);
    CHECK(post_volume_influence(p, m, {0, 0, 0}, true) == 1.0f);
    CHECK(post_volume_influence(p, m, {4.9f, 2.9f, 1.9f}, true) == 1.0f);
    CHECK(post_volume_influence(p, m, {5, 0, 0}, true) == 1.0f);   // the edge is inside
    CHECK(post_volume_influence(p, m, {-5, 3, 2}, true) == 1.0f);  // a corner
    CHECK(post_volume_influence(p, m, {7, 0, 0}, true) == doctest::Approx(0.5f));
    CHECK(post_volume_influence(p, m, {5, 5, 0}, true) == doctest::Approx(1.0f - 2.0f / 4.0f));
    CHECK(post_volume_influence(p, m, {9, 0, 0}, true) == 0.0f);  // distance 4 = blendDistance
    CHECK(post_volume_influence(p, m, {50, 0, 0}, true) == 0.0f);
    p.blendDistance = 0;  // a hard edge
    CHECK(post_volume_influence(p, m, {5, 0, 0}, true) == 1.0f);
    CHECK(post_volume_influence(p, m, {5.01f, 0, 0}, true) == 0.0f);
    // A 2D camera tests x and y only: the z of the box is nothing to it.
    CHECK(post_volume_influence(p, m, {0, 0, 500}, false) == 1.0f);
    CHECK(post_volume_influence(p, m, {0, 0, 500}, true) == 0.0f);
}

TEST_CASE("post_volume_influence: a box follows the rotation and the scale of its entity") {
    Scene s;
    Entity v = s.volume("box", {10, 0, 0});
    PostProcess& p = s.pp(v);
    p.shape = PostShape::Box;
    p.size = {10, 2, 10};  // 10 long along its own x, 2 along y
    p.blendDistance = 0;
    s.world.get<Transform>(v)->rotation = {0, 0, 90};  // its x now points up the world y
    Mat4 m = s.world.world_matrix(v);
    CHECK(post_volume_influence(p, m, {10, 4, 0}, true) == 1.0f);  // 4 up: inside the long side
    CHECK(post_volume_influence(p, m, {14, 0, 0}, true) == 0.0f);  // 4 along the world x: past the short side
    s.world.get<Transform>(v)->rotation = {0, 0, 0};
    s.world.get<Transform>(v)->scale = {2, 2, 2};
    m = s.world.world_matrix(v);
    CHECK(post_volume_influence(p, m, {18, 0, 0}, true) == 1.0f);  // half extent 5 * scale 2 = 10 around x = 10
    CHECK(post_volume_influence(p, m, {21, 0, 0}, true) == 0.0f);
}

TEST_CASE("post_volume_influence: circle and sphere") {
    Scene s;
    Entity c = s.volume("circle");
    PostProcess& pc = s.pp(c);
    pc.shape = PostShape::Circle;
    pc.size = {5, 0, 0};  // radius 5 (size.x)
    pc.blendDistance = 4;
    const Mat4 mc = s.world.world_matrix(c);
    CHECK(post_volume_influence(pc, mc, {3, 0, 0}, false) == 1.0f);
    CHECK(post_volume_influence(pc, mc, {3, 4, 0}, false) == 1.0f);  // on the edge: 5
    CHECK(post_volume_influence(pc, mc, {7, 0, 0}, false) == doctest::Approx(0.5f));
    CHECK(post_volume_influence(pc, mc, {9, 0, 0}, false) == 0.0f);
    CHECK(post_volume_influence(pc, mc, {0, 0, 300}, true) == 1.0f);  // a circle is flat: z is nothing to it

    Entity sp = s.volume("sphere");
    PostProcess& ps = s.pp(sp);
    ps.shape = PostShape::Sphere;
    ps.size = {5, 0, 0};
    ps.blendDistance = 4;
    const Mat4 ms = s.world.world_matrix(sp);
    CHECK(post_volume_influence(ps, ms, {0, 0, 3}, true) == 1.0f);
    CHECK(post_volume_influence(ps, ms, {0, 0, 5}, true) == 1.0f);
    CHECK(post_volume_influence(ps, ms, {0, 0, 7}, true) == doctest::Approx(0.5f));
    CHECK(post_volume_influence(ps, ms, {0, 0, 9}, true) == 0.0f);
    CHECK(post_volume_influence(ps, ms, {0, 0, 7}, false) == 1.0f);  // a 2D camera sees the sphere as a circle
}

TEST_CASE("post_volume_influence: bad numbers give nothing, never NaN") {
    Scene s;
    Entity v = s.volume("box");
    PostProcess& p = s.pp(v);
    p.shape = PostShape::Box;
    p.size = {std::nanf(""), 1, 1};
    const Mat4 m = s.world.world_matrix(v);
    CHECK(post_volume_influence(p, m, {0, 0, 0}, true) == 0.0f);
    p.size = {4, 4, 4};
    p.blendDistance = std::nanf("");
    CHECK(post_volume_influence(p, m, {10, 0, 0}, true) == 0.0f);
    CHECK(post_volume_influence(p, m, {std::nanf(""), 0, 0}, true) == 0.0f);
    p.shape = PostShape::Global;
    CHECK(post_volume_influence(p, m, {1e9f, 0, 0}, true) == 1.0f);
}

TEST_CASE("resolve_post_stack: a box volume fades in over its blend distance") {
    Scene s;
    Entity v = s.volume("cave");
    PostProcess& p = s.pp(v);
    p.shape = PostShape::Box;
    p.size = {10, 10, 10};
    p.blendDistance = 4;
    p.vignetteEnabled = true;
    p.vignetteIntensity = 0.8f;
    s.set_camera({0, 0, 0});
    PostStack st = s.resolve();
    CHECK(st.has(PostEffect::Vignette));
    CHECK(st.fx.vignetteIntensity == 0.8f);  // inside: exactly the volume's own value
    s.set_camera({7, 0, 0});                 // halfway through the band
    st = s.resolve();
    CHECK(st.has(PostEffect::Vignette));  // an effect fades in from neutral (intensity 0), so it is on at once
    CHECK(st.fx.vignetteIntensity == doctest::Approx(0.4f));
    CHECK(st.sources == 1);
    s.set_camera({9, 0, 0});
    st = s.resolve();
    CHECK_FALSE(st.any());
    CHECK(st.sources == 0);
}

TEST_CASE("resolve_post_stack: weight scales the volume, modes switch at one half") {
    Scene s;
    Entity v = s.volume("look");
    PostProcess& p = s.pp(v);
    p.bloomEnabled = true;
    p.bloomIntensity = 2.0f;
    p.tonemapEnabled = true;
    p.tonemapMode = TonemapMode::Agx;
    p.posterizeEnabled = true;
    p.posterizeLevels = 4;
    p.weight = 0.25f;
    PostStack st = s.resolve();
    CHECK(st.fx.bloomIntensity == doctest::Approx(0.5f));  // 0 * 0.75 + 2 * 0.25
    CHECK(st.fx.tonemapMode == TonemapMode::None);         // below one half the neutral mode stays
    CHECK(st.fx.posterizeLevels == 193);                   // 256 * 0.75 + 4 * 0.25, whole numbers rounded
    p.weight = 0.5f;
    st = s.resolve();
    CHECK(st.fx.tonemapMode == TonemapMode::Agx);
    CHECK(st.fx.bloomIntensity == doctest::Approx(1.0f));
    p.weight = 0.0f;
    st = s.resolve();
    CHECK_FALSE(st.any());
    p.weight = 7.0f;  // clamped to 1
    st = s.resolve();
    CHECK(st.fx.bloomIntensity == 2.0f);
    p.weight = std::nanf("");  // a NaN weight is no weight
    CHECK_FALSE(s.resolve().any());
}

TEST_CASE("resolve_post_stack: a higher priority wins, whatever the order the components were made in") {
    for (int swap = 0; swap < 2; ++swap) {
        Scene s;
        Entity lo, hi;
        if (swap) {
            hi = s.volume("zzz");
            lo = s.volume("aaa");
        } else {
            lo = s.volume("aaa");
            hi = s.volume("zzz");
        }
        s.pp(lo).bloomEnabled = true;
        s.pp(lo).bloomIntensity = 1.0f;
        s.pp(lo).priority = -3;
        s.pp(hi).bloomEnabled = true;
        s.pp(hi).bloomIntensity = 3.0f;
        s.pp(hi).priority = 5;
        const PostStack st = s.resolve();
        CHECK(st.sources == 2);
        CHECK(st.fx.bloomIntensity == 3.0f);
    }
}

TEST_CASE("resolve_post_stack: equal priorities are applied by entity id, the last id wins") {
    for (int swap = 0; swap < 2; ++swap) {
        Scene s;
        Entity a, b;
        if (swap) {
            b = s.volume("b_vol");
            a = s.volume("a_vol");
        } else {
            a = s.volume("a_vol");
            b = s.volume("b_vol");
        }
        s.pp(a).vignetteEnabled = true;
        s.pp(a).vignetteIntensity = 0.2f;
        s.pp(b).vignetteEnabled = true;
        s.pp(b).vignetteIntensity = 0.9f;
        CHECK(s.resolve().fx.vignetteIntensity == 0.9f);
    }
}

TEST_CASE("resolve_post_stack: a volume that leaves an effect off never switches it off") {
    Scene s;
    Entity a = s.volume("a_base");
    s.pp(a).bloomEnabled = true;
    s.pp(a).bloomIntensity = 1.5f;
    s.pp(a).priority = 0;
    Entity b = s.volume("b_top");
    s.pp(b).priority = 10;  // bloom off here
    s.pp(b).filmGrainEnabled = true;
    const PostStack st = s.resolve();
    CHECK(st.has(PostEffect::Bloom));
    CHECK(st.has(PostEffect::FilmGrain));
    CHECK(st.fx.bloomIntensity == 1.5f);
}

TEST_CASE("resolve_post_stack: two overlapping volumes blend by priority, the top one over the lower") {
    Scene s;
    Entity a = s.volume("a_base");
    s.pp(a).bloomEnabled = true;
    s.pp(a).bloomIntensity = 4.0f;
    Entity b = s.volume("b_top");
    s.pp(b).priority = 1;
    s.pp(b).bloomEnabled = true;
    s.pp(b).bloomIntensity = 0.0f;
    s.pp(b).weight = 0.25f;
    // a sets 4 (weight 1), then b mixes 25% of 0 over it.
    CHECK(s.resolve().fx.bloomIntensity == doctest::Approx(3.0f));
}

TEST_CASE("resolve_post_stack: disabled, inactive and zero-weight components contribute nothing") {
    Scene s;
    Entity v = s.volume("v");
    s.pp(v).bloomEnabled = true;
    s.pp(v).enabled = false;
    CHECK_FALSE(s.resolve().any());
    s.pp(v).enabled = true;
    CHECK(s.resolve().has(PostEffect::Bloom));
    s.world.set_active(v, false);
    CHECK_FALSE(s.resolve().any());
    s.world.set_active(v, true);
    s.world.get<PostProcess>(v)->enabled = false;
    s.world.add<PostProcess>(s.cam).sharpenEnabled = true;
    const PostStack st = s.resolve();
    CHECK(st.has(PostEffect::Sharpen));
    CHECK_FALSE(st.has(PostEffect::Bloom));
    CHECK(st.sources == 1);
}

TEST_CASE("custom post passes: an entry is parsed with its defaults, and every mistake says where and how to fix it") {
    auto ok = parse_custom_post_pass(Json::parse(R"({"material":"materials/a.material.json"})"), "/customPasses/0");
    REQUIRE_MESSAGE(ok.ok(), ok.error().message);
    CHECK(ok->enabled);
    CHECK(ok->position == "before:tonemap");
    CHECK(ok->slot == PostSlot::AfterBloom);
    CHECK(ok->params.is_object());

    ok = parse_custom_post_pass(
        Json::parse(R"({"material":"m","position":"after:ssr","enabled":false,"name":"x","materialParams":{"a":1}})"),
        "/customPasses/1");
    REQUIRE(ok.ok());
    CHECK(ok->slot == PostSlot::AfterSsr);
    CHECK_FALSE(ok->enabled);
    CHECK(ok->name == "x");
    CHECK(ok->params["a"] == 1);

    // Every error starts with the pointer; the hint names what works.
    auto bad = parse_custom_post_pass(Json::parse(R"({"material":"m","position":"after:bloon"})"), "/customPasses/2");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/customPasses/2/position") != std::string::npos);
    CHECK((bad.error().message + bad.error().hint).find("after:bloom") != std::string::npos);
    bad = parse_custom_post_pass(Json::parse(R"({"material":"m","position":"before:ssao"})"), "/customPasses/0");
    REQUIRE_FALSE(bad.ok());
    CHECK((bad.error().message + bad.error().hint).find("after:ssao") != std::string::npos);
    bad = parse_custom_post_pass(Json::parse(R"({"materal":"m"})"), "/customPasses/0");
    REQUIRE_FALSE(bad.ok());
    CHECK((bad.error().message + bad.error().hint).find("material") != std::string::npos);
    bad = parse_custom_post_pass(Json::parse(R"({"position":"after:bloom"})"), "/customPasses/0");
    CHECK_FALSE(bad.ok());  // the material is required
    bad = parse_custom_post_pass(Json::parse(R"({"material":"m","enabled":"yes"})"), "/customPasses/0");
    CHECK_FALSE(bad.ok());
    bad = parse_custom_post_pass(Json::parse(R"("a string")"), "/customPasses/0");
    CHECK_FALSE(bad.ok());

    // The whole array: nine entries are too many.
    Json many = Json::array();
    for (int i = 0; i < kMaxCustomPostPasses + 1; ++i) many.push_back(Json::parse(R"({"material":"m"})"));
    auto all = parse_custom_post_passes(many, "/customPasses");
    REQUIRE_FALSE(all.ok());
    CHECK(all.error().message.find("/customPasses") != std::string::npos);
    CHECK(all.error().message.find("8") != std::string::npos);
    CHECK_FALSE(parse_custom_post_passes(Json::parse(R"({"a":1})"), "/customPasses").ok());
}

TEST_CASE("custom post passes: every position maps to a place, in frame order, and the names are the table's") {
    const std::vector<std::string> names = custom_post_position_names();
    CHECK(int(names.size()) == kCustomPostPositionCount);
    PostSlot previous = PostSlot::Main;
    for (int i = 0; i < kCustomPostPositionCount; ++i) {
        INFO(names[std::size_t(i)]);
        auto r = parse_custom_post_pass(Json::object({{"material", "m"}, {"position", names[std::size_t(i)]}}), "/p");
        REQUIRE(r.ok());
        CHECK(r->slot == kCustomPostPositions[i].slot);
        CHECK(int(r->slot) >= int(previous));  // the table is in frame order
        previous = r->slot;
    }
    CHECK(int(PostSlot::Count) == kPostSlotCount);
    CHECK(std::find(names.begin(), names.end(), std::string(kCustomPostDefaultPosition)) != names.end());
}

TEST_CASE("custom post passes: the display-referred places parse, the ones that are no place say why") {
    const std::pair<const char*, PostSlot> places[] = {
        {"after:tonemap", PostSlot::AfterTonemap},      {"before:colorGrading", PostSlot::AfterTonemap},
        {"after:colorGrading", PostSlot::AfterGrading}, {"before:vignette", PostSlot::AfterGrading},
        {"after:vignette", PostSlot::AfterVignette},    {"before:sharpen", PostSlot::AfterVignette},
        {"after:sharpen", PostSlot::AfterSharpen},      {"before:outline", PostSlot::AfterSharpen},
        {"after:outline", PostSlot::AfterOutline},      {"before:posterize", PostSlot::AfterOutline},
        {"after:posterize", PostSlot::AfterPosterize},  {"before:filmGrain", PostSlot::AfterPosterize},
        {"after:filmGrain", PostSlot::AfterGrain},      {"before:colorFilter", PostSlot::AfterGrain},
    };
    for (const auto& [name, slot] : places) {
        INFO(name);
        auto r = parse_custom_post_pass(Json::object({{"material", "m"}, {"position", name}}), "/p");
        REQUIRE(r.ok());
        CHECK(r->slot == slot);
        CHECK(post_slot_is_ldr(r->slot));
    }
    CHECK_FALSE(post_slot_is_ldr(PostSlot::AfterBloom));
    // The pixelate and the colour filter are no places; the message says what to write instead and no text says the
    // display-referred places do not exist.
    for (const char* name : {"before:pixelate", "after:pixelate", "after:colorFilter"}) {
        INFO(name);
        auto bad = parse_custom_post_pass(Json::object({{"material", "m"}, {"position", name}}), "/p");
        REQUIRE_FALSE(bad.ok());
        CHECK(bad.error().message.find("/p/position") != std::string::npos);
        CHECK(bad.error().hint.find("is not a place") != std::string::npos);
        CHECK(bad.error().hint.find(std::string(name).find("pixelate") != std::string::npos
                                        ? "after:outline"
                                        : "before:colorFilter") != std::string::npos);
        CHECK(bad.error().hint.find("not supported") == std::string::npos);
    }
}

TEST_CASE("resolve_post_stack: custom passes of the camera and of volumes, in order; an unreadable entry is reported") {
    Scene s;
    s.world.add<PostProcess>(s.cam);
    PostProcess& own = *s.world.get<PostProcess>(s.cam);
    own.customPasses =
        Json::parse(R"([{"material":"own1"},{"material":"own2","position":"after:ssr"},{"mat":"typo"}])");
    Entity v = s.volume("v");
    s.pp(v).customPasses = Json::parse(R"([{"material":"vol1"}])");
    PostStack st = s.resolve();
    REQUIRE(st.custom.size() == 3);  // own first (in list order), then the volume
    CHECK(st.custom[0].material == "own1");
    CHECK(st.custom[1].material == "own2");
    CHECK(st.custom[2].material == "vol1");
    REQUIRE(st.customErrors.size() == 1);
    CHECK(st.customErrors[0].message.find("/customPasses/2") != std::string::npos);
    CHECK(st.has_custom());

    // A volume that is weaker than one half adds nothing (a list cannot be blended); a custom pass is no effect of the
    // order.
    s.pp(v).weight = 0.4f;
    st = s.resolve();
    CHECK(st.custom.size() == 2);
    CHECK(st.effect_count() == 0);
    CHECK(st.mask == 0);

    // The same world resolves to the same list every time.
    const PostStack again = s.resolve();
    CHECK(again.custom.size() == st.custom.size());

    // Too many entries on one component: none of them is taken, the error says why.
    Json many = Json::array();
    for (int i = 0; i < kMaxCustomPostPasses + 1; ++i) many.push_back(Json::parse(R"({"material":"m"})"));
    own.customPasses = many;
    s.pp(v).customPasses = Json::array();
    st = s.resolve();
    CHECK(st.custom.empty());
    CHECK_FALSE(st.customErrors.empty());
}

TEST_CASE(
    "resolve_post_stack: the custom passes of camera and volumes together stop at 32, and the stack says so once") {
    Scene s;
    s.world.add<PostProcess>(s.cam);
    Json eight = Json::array();
    for (int i = 0; i < kMaxCustomPostPasses; ++i)
        eight.push_back(Json::object({{"material", "m" + std::to_string(i)}}));
    s.world.get<PostProcess>(s.cam)->customPasses = eight;
    for (const char* id : {"v0", "v1", "v2", "v3", "v4"}) s.pp(s.volume(id)).customPasses = eight;
    const PostStack st = s.resolve();
    CHECK(st.custom.size() == std::size_t(4 * kMaxCustomPostPasses));
    REQUIRE(st.customErrors.size() == 1);
    CHECK(st.customErrors[0].message.find("32") != std::string::npos);
    CHECK_FALSE(st.customErrors[0].hint.empty());
    // v3 hit the cap (8 entries dropped); v4's 8 are added to the same message, with its entity, not left out.
    CHECK(st.customErrors[0].message.find("the 8 entries of one PostProcess") != std::string::npos);
    CHECK(st.customErrors[0].message.find("Also not drawn: the 8 entries of the PostProcess of entity 'v4' (v4)") !=
          std::string::npos);
}

TEST_CASE("resolve_post_stack: the entries past the cap of 32 are named, and one that does not parse says why") {
    Scene s;
    s.world.add<PostProcess>(s.cam);
    Json eight = Json::array();
    for (int i = 0; i < kMaxCustomPostPasses; ++i)
        eight.push_back(Json::object({{"material", "m" + std::to_string(i)}}));
    s.world.get<PostProcess>(s.cam)->customPasses = eight;
    for (const char* id : {"v0", "v1", "v2"}) s.pp(s.volume(id)).customPasses = eight;
    Json last =
        Json::array();  // the 33rd entry is fine, the 34th names no material and the 35th has a position nobody knows
    last.push_back(Json::object({{"material", "late"}}));
    last.push_back(Json::object({{"position", "after:bloom"}}));
    last.push_back(Json::object({{"material", "later"}, {"position", "after:nowhere"}}));
    s.pp(s.volume("v3")).customPasses = last;
    const PostStack st = s.resolve();
    CHECK(st.custom.size() == std::size_t(4 * kMaxCustomPostPasses));
    REQUIRE(st.customErrors.size() == 3);
    const std::string& cap = st.customErrors[0].message;
    CHECK(cap.find("32") != std::string::npos);
    CHECK(cap.find("3 entries") != std::string::npos);
    CHECK(cap.find("/customPasses/0") != std::string::npos);
    CHECK(cap.find("'late'") != std::string::npos);
    // The two that do not parse say which they are and why, as an entry of the camera would.
    CHECK(st.customErrors[1].message.find("/customPasses/1") != std::string::npos);
    CHECK(st.customErrors[1].message.find("material") != std::string::npos);
    CHECK(st.customErrors[2].message.find("/customPasses/2") != std::string::npos);
    CHECK(st.customErrors[2].message.find("after:nowhere") != std::string::npos);

    // A later volume that is cut too is named in the same message, and its entries that do not parse get their own
    // errors.
    Json more = Json::array();
    more.push_back(Json::object({{"material", "v4first"}}));
    more.push_back(Json::object({{"position", "before:bloom"}}));
    s.pp(s.volume("v4")).customPasses = more;
    const PostStack st2 = s.resolve();
    REQUIRE(st2.customErrors.size() == 4);
    CHECK(st2.customErrors[0].message.find("Also not drawn: the 2 entries of the PostProcess of entity 'v4' (v4)") !=
          std::string::npos);
    CHECK(st2.customErrors[0].message.find("'v4first'") != std::string::npos);
    CHECK(st2.customErrors[3].message.find("In the PostProcess of entity 'v4' (v4): ") != std::string::npos);
    CHECK(st2.customErrors[3].message.find("/customPasses/1") != std::string::npos);
}

TEST_CASE("resolve_post_stack: the camera's own stack goes first, volumes are applied over it") {
    Scene s;
    s.world.add<PostProcess>(s.cam);
    s.world.get<PostProcess>(s.cam)->exposureEnabled = true;
    s.world.get<PostProcess>(s.cam)->exposureEv = 1.0f;
    Entity v = s.volume("v");
    s.pp(v).exposureEnabled = true;
    s.pp(v).exposureEv = 3.0f;
    s.pp(v).weight = 0.5f;
    const PostStack st = s.resolve();
    CHECK(st.sources == 2);
    CHECK(st.fx.exposureEv == doctest::Approx(2.0f));
}

TEST_CASE("resolve_post_stack: the same world resolves to the same stack every time") {
    Scene s({3, 1, 0});
    for (const char* id : {"d", "b", "c", "a"}) {
        Entity v = s.volume(id);
        s.pp(v).bloomEnabled = true;
        s.pp(v).bloomIntensity = float(id[0] - 'a');
        s.pp(v).shape = PostShape::Sphere;
        s.pp(v).size = {6, 0, 0};
        s.pp(v).blendDistance = 2;
        s.pp(v).weight = 0.7f;
    }
    const PostStack first = s.resolve();
    for (int i = 0; i < 5; ++i) {
        const PostStack again = s.resolve();
        CHECK(again.mask == first.mask);
        CHECK(again.sources == first.sources);
        CHECK(again.fx.bloomIntensity == first.fx.bloomIntensity);
    }
}

// ------------------------------------------------------------------------------------------- the feature table

namespace {
FeatureEnv gpu(FeatureBackend b, bool half = true, bool packed = true, bool depth = true, bool compute = false,
               bool float32 = true) {
    FeatureEnv e;
    e.backend = b;
    e.float32 = float32;
    e.halfTargets = half;
    e.r11g11b10 = packed;
    e.sampledDepth = depth;
    e.compute = compute;
    return e;
}
bool supported(const FeatureEnv& env, const char* name, std::string* why = nullptr) {
    const int i = find_feature(name);
    REQUIRE_MESSAGE(i >= 0, name);
    return feature_supported(env, i, why);
}
}  // namespace

TEST_CASE("features: the table has the capabilities, the engine features and every post effect once") {
    const std::vector<std::string> names = feature_names();
    // 4 capabilities + 3 engine features + the 21 lighting rows of M73 + the effects
    CHECK(names.size() == 4 + 1 + 3 + 21 + std::size_t(kPostEffectCount));
    CHECK(std::set<std::string>(names.begin(), names.end()).size() == names.size());
    for (const char* n : {"floatTargets", "r11g11b10", "linearColor", "hdrOutput", "sampledDepth", "computeShaders",
                          "postMaterials", "float32Targets"})
        CHECK(find_feature(n) >= 0);
    for (const std::string_view e : kPostEffectOrder) CHECK(find_feature(e) >= 0);
    CHECK(find_feature("bloomm") == -1);
    CHECK(find_feature("") == -1);
    CHECK(Renderer::feature_names() == names);
    for (const FeatureDef& f : feature_table()) {
        CAPTURE(f.name);
        CHECK(std::string(f.doc).size() > 20);
    }
    // The effects come last, in the canonical order.
    for (int i = 0; i < kPostEffectCount; ++i)
        CHECK(names[names.size() - std::size_t(kPostEffectCount) + std::size_t(i)] == kPostEffectOrder[std::size_t(i)]);
}

TEST_CASE("features: the capabilities follow what each backend's GPU reports") {
    for (const FeatureBackend b : {FeatureBackend::Gl, FeatureBackend::Gles3, FeatureBackend::WebGl2,
                                   FeatureBackend::D3d11, FeatureBackend::Metal}) {
        CAPTURE(feature_backend_label(b));
        CHECK(supported(gpu(b), "floatTargets"));
        CHECK(supported(gpu(b), "r11g11b10"));
        CHECK(supported(gpu(b), "sampledDepth"));
        std::string why;
        CHECK_FALSE(supported(gpu(b, false), "floatTargets", &why));
        CHECK(why.find("RGBA16F") != std::string::npos);
        CHECK_FALSE(supported(gpu(b, true, false), "r11g11b10"));
        CHECK_FALSE(supported(gpu(b, true, true, false), "sampledDepth", &why));
        CHECK(why.find("depth") != std::string::npos);
    }
}

TEST_CASE("features: compute shaders exist on GL, D3D11 and Metal and never on GLES3 or WebGL2") {
    CHECK(supported(gpu(FeatureBackend::Gl, true, true, true, true), "computeShaders"));
    CHECK(supported(gpu(FeatureBackend::D3d11, true, true, true, true), "computeShaders"));
    CHECK(supported(gpu(FeatureBackend::Metal, true, true, true, true), "computeShaders"));
    CHECK_FALSE(
        supported(gpu(FeatureBackend::Gl, true, true, true, false), "computeShaders"));  // an old GL: the GPU says no
    std::string why;
    CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, true, true), "computeShaders", &why));
    CHECK(why.find("GLES3") != std::string::npos);
    CHECK_FALSE(supported(gpu(FeatureBackend::WebGl2, true, true, true, true), "computeShaders", &why));
    CHECK(why.find("WebGL2") != std::string::npos);
}

TEST_CASE("features: what the engine does not draw yet is false and says planned") {
    const FeatureEnv full = gpu(FeatureBackend::D3d11, true, true, true, true);
    std::string why;
    CHECK(supported(full, "linearColor", &why));  // M71-B1: drawn on every GPU
    // The effects the renderer draws (M71-B4, C1, C2, C3b, D1, D2, D3a, D3b) answer true on a GPU that can; the others are planned.
    const std::string_view drawn[] = {
        "ssao",         "exposure",   "bloom",      "tonemap", "colorFilter", "lensDistortion", "chromaticAberration",
        "colorGrading", "vignette",   "sharpen",    "outline", "pixelate",    "posterize",      "filmGrain",
        "depthOfField", "motionBlur", "radialBlur", "ssr",     "fog",         "sunShafts"};
    for (const std::string_view e : kPostEffectOrder) {
        CAPTURE(e);
        if (std::find(std::begin(drawn), std::end(drawn), e) != std::end(drawn)) {
            CHECK(supported(full, std::string(e).c_str(), &why));
            // A GPU without float targets draws them too: they need nothing of it (the exposure stays manual there). The outline, the depth of field
            // and the motion blur read the depth prepass, so it needs a GPU that can sample the scene's depth: the answer names that, not the plan.
            if (e == "outline" || e == "motionBlur" || e == "fog") {
                CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false, false, false), std::string(e).c_str(), &why));
                CHECK(why.find("depth") != std::string::npos);
                CHECK(why.find("planned") == std::string::npos);
            } else if (e == "depthOfField" ||
                       e == "sunShafts") {  // their half-size images are RGBA16F: they need float targets too
                CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false, false, true), std::string(e).c_str(), &why));
                CHECK(why.find("RGBA16F") != std::string::npos);
                CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, false), std::string(e).c_str(), &why));
                CHECK(why.find("depth") != std::string::npos);
                CHECK(why.find("planned") == std::string::npos);
            } else if (e == "ssao") {  // M71-D1: float targets for its images, the prepass for the depth
                CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false, false, true), "ssao", &why));
                CHECK(why.find("RGBA16F") != std::string::npos);
                CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, false), "ssao", &why));
                CHECK(why.find("depth") != std::string::npos);
                CHECK(why.find("planned") == std::string::npos);
            } else if (
                e ==
                "ssr") {  // M71-D3a: reads the scene colour and the prepass: it needs float targets and the sampled depth
                CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false, false, false), "ssr", &why));
                CHECK(why.find("planned") == std::string::npos);
            } else {
                CHECK(supported(gpu(FeatureBackend::Gles3, false, false, false), std::string(e).c_str()));
            }
            continue;
        }
        CHECK_FALSE(supported(full, std::string(e).c_str(), &why));
        CHECK(why == "planned (M71)");
    }
    // hdrOutput can never exist where there is no HDR swapchain; the answer names the backend, not the plan.
    CHECK_FALSE(supported(gpu(FeatureBackend::Gl), "hdrOutput", &why));
    CHECK(why.find("GL") != std::string::npos);
    CHECK(why.find("planned") == std::string::npos);
    // An effect that reads the depth buffer on a GPU that cannot sample it: the missing capability, not the plan.
    CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, false), "ssao", &why));
    CHECK(why.find("depth") != std::string::npos);
}

TEST_CASE(
    "features: the lighting rows of M73 are planned until their package lands and never claim what is not drawn") {
    const char* const rows[] = {"realtimeGI"};
    const FeatureEnv full = gpu(FeatureBackend::D3d11, true, true, true, true);
    for (const char* n : rows) {
        CAPTURE(n);
        REQUIRE(find_feature(n) >= 0);
        std::string why;
        CHECK_FALSE(supported(full, n, &why));
        CHECK(why == "planned (M73)");
        CHECK(feature_table()[std::size_t(find_feature(n))].kind == FeatureKind::Engine);
    }
    // reflection probes (M73-P3c) are sampled by the mesh shader and ask nothing of the GPU (an RGBA8 atlas where half floats cannot be
    // rendered): supported on every backend that draws, never "planned".
    for (FeatureBackend b : {FeatureBackend::Gl, FeatureBackend::Gles3, FeatureBackend::WebGl2, FeatureBackend::D3d11,
                             FeatureBackend::Metal}) {
        std::string why;
        REQUIRE(find_feature("reflectionProbes") >= 0);
        CHECK(supported(gpu(b, false, false, false, false), "reflectionProbes", &why));
        CHECK(why.find("planned") == std::string::npos);
    }
    CHECK(feature_table()[std::size_t(find_feature("reflectionProbes"))].kind == FeatureKind::Engine);
    // contact shadows (M73.2c) are drawn in the mesh shader from the depth prepass: supported where the prepass can be made.
    {
        std::string why;
        REQUIRE(find_feature("contactShadows") >= 0);
        CHECK(supported(full, "contactShadows", &why));
        CHECK(why.find("planned") == std::string::npos);
        CHECK(feature_table()[std::size_t(find_feature("contactShadows"))].kind == FeatureKind::Engine);
    }
    // transmission (M73-P6b) is drawn: the mesh shader refracts an atlas of the opaque colour; where that atlas cannot be made the glass
    // is a plain blend, which the frame's statistics say, so the row itself needs nothing of the GPU.
    {
        std::string why;
        REQUIRE(find_feature("transmission") >= 0);
        CHECK(supported(full, "transmission", &why));
        CHECK(why.find("planned") == std::string::npos);
        CHECK(feature_table()[std::size_t(find_feature("transmission"))].kind == FeatureKind::Engine);
    }
    // decals (M73.5b) are drawn in the mesh shader and ask nothing of the GPU: supported everywhere, never "planned".
    CHECK(find_feature("decals") >= 0);
    CHECK(supported(full, "decals"));
    CHECK(supported(gpu(FeatureBackend::Gles3, false, false, false, false, false), "decals"));
    CHECK(feature_table()[std::size_t(find_feature("decals"))].kind == FeatureKind::Engine);
    // M73.4a: the lightmaps are drawn; the row needs nothing of the GPU.
    REQUIRE(find_feature("lightmaps") >= 0);
    CHECK(supported(full, "lightmaps"));
    CHECK(feature_table()[std::size_t(find_feature("lightmaps"))].kind == FeatureKind::Engine);
    // M73.4d: the light probes are drawn too (the SH is a uniform); the row needs nothing of the GPU.
    REQUIRE(find_feature("lightProbes") >= 0);
    CHECK(supported(full, "lightProbes"));
    CHECK(supported(gpu(FeatureBackend::Gles3, false, false, false, false, false), "lightProbes"));
    CHECK(feature_table()[std::size_t(find_feature("lightProbes"))].kind == FeatureKind::Engine);
    // The physical sky is drawn (M73-P3d): it needs RGBA16F targets for its tables and says so when they are missing.
    {
        std::string why;
        REQUIRE(find_feature("physicalSky") >= 0);
        CHECK(supported(full, "physicalSky", &why));
        CHECK(feature_table()[std::size_t(find_feature("physicalSky"))].kind == FeatureKind::Engine);
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false), "physicalSky", &why));
        CHECK(why.find("RGBA16F") != std::string::npos);
        CHECK(why.find("planned") == std::string::npos);
    }
    // The light atlas rows are drawn (M73.1b) and the environment map (M73-P3a-2): they need RGBA16F images (that filter) and say so when
    // they are missing.
    for (const char* n : {"areaLights", "lightCookies", "iesProfiles", "environmentMap"}) {
        CAPTURE(n);
        std::string why;
        REQUIRE(find_feature(n) >= 0);
        CHECK(supported(full, n, &why));
        CHECK(feature_table()[std::size_t(find_feature(n))].kind == FeatureKind::Engine);
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false), n, &why));
        CHECK(why.find("RGBA16F") != std::string::npos);
        CHECK(why.find("planned") == std::string::npos);
    }
    // The volumetric fog is drawn (M73.5): it needs RGBA16F targets and a sampled depth, and says so, never "planned".
    {
        std::string why;
        REQUIRE(find_feature("volumetricFog") >= 0);
        CHECK(supported(full, "volumetricFog", &why));
        CHECK(feature_table()[std::size_t(find_feature("volumetricFog"))].kind == FeatureKind::Engine);
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false), "volumetricFog", &why));
        CHECK(why.find("RGBA16F") != std::string::npos);
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, false), "volumetricFog", &why));
        CHECK(why.find("depth") != std::string::npos);
        CHECK(why.find("planned") == std::string::npos);
    }
    // The subsurface scattering is drawn (M73.5): it needs RGBA16F targets and a sampled depth (its meshes keep only the surface the prepass sees),
    // and says so, never "planned".
    {
        std::string why;
        REQUIRE(find_feature("subsurface") >= 0);
        CHECK(supported(full, "subsurface", &why));
        CHECK(feature_table()[std::size_t(find_feature("subsurface"))].kind == FeatureKind::Engine);
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, false), "subsurface", &why));
        CHECK(why.find("RGBA16F") != std::string::npos);
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, false), "subsurface", &why));
        CHECK(why.find("depth") != std::string::npos);
        CHECK(why.find("planned") == std::string::npos);
    }
    // clusteredLights is drawn: it is a feature of the renderer on every GPU, with the row still in the same place.
    CHECK(find_feature("clusteredLights") >= 0);
    CHECK(supported(full, "clusteredLights"));
    CHECK(feature_table()[std::size_t(find_feature("clusteredLights"))].kind == FeatureKind::Engine);
    // float32Targets follows the GPU: a GPU whose R32F cannot be sampled answers with what is missing, not with the plan.
    std::string why;
    CHECK(supported(full, "float32Targets", &why));
    CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, true, false, false), "float32Targets", &why));
    CHECK(why.find("R32F") != std::string::npos);
    // cascadedShadows (M73.2a), pointShadows and spotShadows (M73.2b) are drawn: they need float32Targets and nothing else, so they
    // say what is missing, never "planned".
    for (const char* n : {"cascadedShadows", "pointShadows", "spotShadows"}) {
        CAPTURE(n);
        CHECK(supported(full, n, &why));
        CHECK_FALSE(supported(gpu(FeatureBackend::Gles3, true, true, true, false, false), n, &why));
        CHECK(why.find("R32F") != std::string::npos);
        CHECK(why.find("planned") == std::string::npos);
    }
}

TEST_CASE("features: the material layers of M73.6 are drawn on every backend") {
    for (const char* n : {"clearCoat", "sheen", "anisotropy"}) {
        CAPTURE(n);
        REQUIRE(find_feature(n) >= 0);
        CHECK(feature_table()[std::size_t(find_feature(n))].kind == FeatureKind::Engine);
        for (FeatureBackend b :
             {FeatureBackend::Gl, FeatureBackend::Gles3, FeatureBackend::D3d11, FeatureBackend::Metal}) {
            std::string why;
            CHECK(supported(gpu(b), n, &why));
        }
    }
}

TEST_CASE("features: hdrOutput follows the display the window is on and what the renderer writes there") {
    std::string why;
    // A FeatureEnv nobody filled: the display was never asked.
    CHECK_FALSE(supported(gpu(FeatureBackend::Metal), "hdrOutput", &why));
    CHECK(why.find("not been asked") != std::string::npos);

    // Metal on a screen with EDR headroom: yes; on one without: the display's reason.
    FeatureEnv metal = gpu(FeatureBackend::Metal);
    set_hdr_env(metal, hdr_display_from_edr(16.0f, 1.0f, "XDR"));
    CHECK(supported(metal, "hdrOutput"));
    set_hdr_env(metal, hdr_display_from_edr(1.0f, 1.0f, "Studio"));
    CHECK_FALSE(supported(metal, "hdrOutput", &why));
    CHECK(why.find("EDR headroom") != std::string::npos);
    HdrDisplay none;
    none.why = "there is no window";
    set_hdr_env(metal, none);
    CHECK_FALSE(supported(metal, "hdrOutput", &why));
    CHECK(why == "there is no window");

    // D3D11 on a display Windows composes in HDR: yes (scRGB, HDR10 as the fallback); with HDR off in Settings: the reason.
    FeatureEnv d3d = gpu(FeatureBackend::D3d11);
    set_hdr_env(d3d, hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV"));
    CHECK(supported(d3d, "hdrOutput"));
    set_hdr_env(d3d, hdr_display_from_dxgi(false, 1000.0f, 0.0f, 600.0f, "TV"));
    CHECK_FALSE(supported(d3d, "hdrOutput", &why));
    CHECK(why.find("Use HDR") != std::string::npos);
    CHECK(hdr_encodable(FeatureBackend::D3d11) ==
          (hdr_encoding_bit(HdrEncoding::ScRgb) | hdr_encoding_bit(HdrEncoding::Hdr10)));
    CHECK(hdr_encodable(FeatureBackend::Metal) == hdr_encoding_bit(HdrEncoding::Edr));
    CHECK(hdr_encodable(FeatureBackend::Gl) == 0u);
    CHECK(hdr_encodable(FeatureBackend::Gles3) == 0u);
    CHECK(hdr_encodable(FeatureBackend::WebGl2) == 0u);
    // GL, GLES3 and WebGL2 on an HDR display still say why not (the renderer writes no HDR encoding there).
    FeatureEnv gl = gpu(FeatureBackend::Gl);
    set_hdr_env(gl, hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV"));
    CHECK_FALSE(supported(gl, "hdrOutput", &why));
    CHECK_FALSE(why.empty());

    // The request the renderer makes: Metal asks for an extended LINEAR sRGB swapchain (the present pass writes linear light),
    // and nothing is pending on D3D11 any more.
    const HdrRequest r = hdr_request(FeatureBackend::Metal, true, 300.0f);
    CHECK(r.want);
    CHECK(r.paperWhiteNits == doctest::Approx(300.0f));
    CHECK(r.edrLinear);
    CHECK(r.pending.empty());
    const HdrRequest d = hdr_request(FeatureBackend::D3d11, true, 200.0f);
    CHECK(d.pending.empty());
    CHECK(decide_hdr_output(d, hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV")).encoding ==
          HdrEncoding::ScRgb);
    CHECK(decide_hdr_output(d, hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV")).fallback ==
          HdrEncoding::Hdr10);
}

TEST_CASE("Renderer::output_info: without a window the output is the standard range") {
    Renderer r;                        // never init()ed
    r.update_output(SceneSettings{});  // does nothing before init()
    const HdrOutputInfo info = r.output_info();
    CHECK_FALSE(info.active);
    CHECK(info.encoding == HdrEncoding::Sdr);
    CHECK_FALSE(info.display.known);
    CHECK(info.swapchainFormat.empty());
}

TEST_CASE("features: the headless backend has no GPU and says no to everything") {
    const FeatureEnv none = gpu(FeatureBackend::Headless, true, true, true, true);
    for (const std::string& n : feature_names()) {
        CAPTURE(n);
        std::string why;
        CHECK_FALSE(supported(none, n.c_str(), &why));
        CHECK(why.find("no GPU") != std::string::npos);
    }
}

TEST_CASE("features: the report lists every feature with a status and the backends it can run on") {
    const Json r = feature_report(gpu(FeatureBackend::Metal, true, true, true, true), "metal");
    CHECK(r["backend"] == "metal");
    CHECK(r["backendLabel"] == "Metal");
    REQUIRE(r["features"].size() == feature_names().size());
    const Json& first = r["features"][0];
    CHECK(first["name"] == "floatTargets");
    CHECK(first["kind"] == "capability");
    CHECK(first["supported"] == true);
    CHECK(first["status"] == "supported");
    CHECK(first["backends"].size() == std::size_t(kFeatureBackendCount));
    CHECK(first["backends"]["Headless"] == false);  // no feature ever runs on the backend without a GPU
    CHECK(first["backends"]["Metal"] == true);
    for (const Json& f : r["features"])
        if (f["name"] == "computeShaders") {
            CHECK(f["backends"]["GLES3"] == false);
            CHECK(f["backends"]["D3D11"] == true);
        }
}

TEST_CASE("Renderer::supports: an unknown name, or a renderer that is not initialized, says false") {
    Renderer r;  // never init()ed: there is no GPU to ask
    CHECK_FALSE(r.supports("floatTargets"));
    CHECK_FALSE(r.supports("bloom"));
    CHECK_FALSE(r.supports("no such feature"));
    CHECK_FALSE(r.supports(""));
    CHECK(r.supports_report().empty());
}
