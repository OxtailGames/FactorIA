#include <doctest.h>

#include <cmath>

#include "fa/scene/impostor.h"
#include "fa/scene/lod.h"

using namespace fa;

TEST_CASE("impostor: directions are unit, round trip through encode, and the hemi mode stays above the horizon") {
    for (ImpostorMode mode : {ImpostorMode::Octahedral, ImpostorMode::HemiOctahedral}) {
        for (int i = 0; i < 8; ++i)
            for (int j = 0; j < 8; ++j) {
                const Vec3 d = impostor_direction(mode, 8, i, j);
                CHECK(length(d) == doctest::Approx(1.0f).epsilon(1e-4));
                if (mode == ImpostorMode::HemiOctahedral) CHECK(d.y >= -1e-5f);
                float u, v;
                impostor_encode(mode, d, u, v);
                // The edge and the corners of the octahedral grid hold the same direction twice, so compare directions, not cells.
                const float last = 7.0f;
                const Vec3 again = impostor_direction(mode, 8, int(std::lround((u * 0.5f + 0.5f) * last)),
                                                      int(std::lround((v * 0.5f + 0.5f) * last)));
                CHECK(dot(again, d) == doctest::Approx(1.0f).epsilon(1e-4));
            }
    }
    // The centre of the grid looks from straight above, the corners from straight below (octahedral).
    CHECK(impostor_direction(ImpostorMode::Octahedral, 9, 4, 4).y == doctest::Approx(1.0f));
    CHECK(impostor_direction(ImpostorMode::Octahedral, 9, 0, 0).y < -0.5f);
}

TEST_CASE(
    "impostor: the pick holds three frames whose weights add up to 1 and a direction on a frame picks that frame") {
    for (ImpostorMode mode : {ImpostorMode::Octahedral, ImpostorMode::HemiOctahedral}) {
        const int n = 8;
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j) {
                const Vec3 d = impostor_direction(mode, n, i, j);
                const ImpostorPick p = impostor_pick(mode, n, d);
                CHECK(p.weight[0] + p.weight[1] + p.weight[2] == doctest::Approx(1.0f).epsilon(1e-4));
                float best = 0.0f;
                int bestFrame = -1;
                for (int k = 0; k < 3; ++k) {
                    CHECK(p.weight[k] >= -1e-4f);
                    CHECK(p.frame[k] >= 0);
                    CHECK(p.frame[k] < n * n);
                    if (p.weight[k] > best) best = p.weight[k], bestFrame = p.frame[k];
                }
                // On an edge of the grid the same direction sits in two cells: the frame picked shows the same direction.
                CHECK(dot(impostor_direction(mode, n, bestFrame % n, bestFrame / n), d) ==
                      doctest::Approx(1.0f).epsilon(1e-4));
                CHECK(best == doctest::Approx(1.0f).epsilon(1e-3));
            }
        // A direction that is between frames weighs its neighbours.
        const Vec3 mid = normalize(impostor_direction(mode, n, 3, 3) + impostor_direction(mode, n, 4, 3));
        const ImpostorPick p = impostor_pick(mode, n, mid);
        CHECK(p.weight[0] + p.weight[1] + p.weight[2] == doctest::Approx(1.0f).epsilon(1e-4));
        int nonZero = 0;
        for (float w : p.weight) nonZero += w > 0.05f;
        CHECK(nonZero >= 2);
    }
}

TEST_CASE("impostor: the basis is orthonormal, up is +y except at the poles") {
    Vec3 r, u;
    impostor_basis(normalize(Vec3{1, 0.3f, 2}), r, u);
    CHECK(length(r) == doctest::Approx(1.0f));
    CHECK(length(u) == doctest::Approx(1.0f));
    CHECK(dot(r, u) == doctest::Approx(0.0f).epsilon(1e-4));
    CHECK(u.y > 0.0f);
    CHECK(r.y == doctest::Approx(0.0f).epsilon(1e-5));
    impostor_basis({0, 1, 0}, r, u);
    CHECK(length(r) == doctest::Approx(1.0f));
    CHECK(dot(r, u) == doctest::Approx(0.0f).epsilon(1e-4));
}

TEST_CASE("impostor: the json round trips and a bad file says where") {
    ImpostorAtlas a;
    a.mode = ImpostorMode::HemiOctahedral;
    a.views = 6;
    a.frameSize = 64;
    a.albedo = "models/tree.impostor.png";
    a.normal = "models/tree.impostor.normal.png";
    a.center = {0.5f, 2.0f, -1.0f};
    a.radius = 3.5f;
    a.source = "models/tree.glb";
    auto r = impostor_from_json(impostor_to_json(a), "tree.impostor.json");
    REQUIRE(r.ok());
    CHECK(r.value().mode == ImpostorMode::HemiOctahedral);
    CHECK(r.value().views == 6);
    CHECK(r.value().frameSize == 64);
    CHECK(r.value().atlasSize() == 384);
    CHECK(r.value().center.y == doctest::Approx(2.0f));
    CHECK(r.value().radius == doctest::Approx(3.5f));
    CHECK(r.value().albedo == a.albedo);

    auto expectBad = [&](const char* key, const Json& value, const char* pointer) {
        Json j = impostor_to_json(a);
        j[key] = value;
        auto bad = impostor_from_json(j, "tree.impostor.json");
        REQUIRE_FALSE(bad.ok());
        CHECK(bad.error().message.find(std::string("tree.impostor.json") + pointer) != std::string::npos);
        CHECK_FALSE(bad.error().hint.empty());
    };
    expectBad("format", "other/2", "/format");
    expectBad("mode", "sphere", "/mode");
    expectBad("views", 1, "/views");
    expectBad("views", 99, "/views");
    expectBad("frameSize", 4, "/frameSize");
    expectBad("frameSize", 4000, "/frameSize");  // 6 * 4000 > 4096
    expectBad("albedo", "../outside.png", "/albedo");
    expectBad("normal", "/abs/path.png", "/normal");
    expectBad("radius", 0, "/radius");
    expectBad("center", Json::array({1, 2}), "/center");
    CHECK_FALSE(impostor_from_json(Json::array(), "x").ok());
}

TEST_CASE("impostor: it draws from impostorDistance in the unit of lodMode") {
    MeshRenderer mr;
    CHECK_FALSE(impostor_active(mr, 1000.0f, 0.0f));  // no impostor
    mr.impostor = "a.impostor.json";
    CHECK_FALSE(impostor_active(mr, 1000.0f, 0.0f));  // distance 0 = never
    mr.impostorDistance = 50.0f;
    CHECK_FALSE(impostor_active(mr, 49.9f, 1.0f));
    CHECK(impostor_active(mr, 50.0f, 1.0f));
    CHECK_FALSE(impostor_active(mr, NAN, 1.0f));
    mr.lodMode = LodMode::ScreenSize;
    mr.impostorDistance = 0.1f;
    CHECK_FALSE(impostor_active(mr, 1.0f, 0.1f));
    CHECK(impostor_active(mr, 1.0f, 0.09f));
    CHECK_FALSE(impostor_active(mr, 1.0f, NAN));
}
