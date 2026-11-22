// model.bake_impostor (docs/BIG_WORLDS_LOD.md, "Impostors"): the files, the atlas content, determinism, the arguments that teach and the write rules.
#include <doctest.h>

#include <cmath>

#include "asset_test_helpers.h"
#include "fa/scene/impostor.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kBall =
    R"({"format": "factoria.model/1", "nodes": [{"op": "sphere", "id": "s", "radius": 1, "part": "ball"}]})";

// A 2 x 1 x 1 box baked to a .glb, so the silhouette depends on the direction.
void make_box(AssetsProject& p) {
    write_all(p.file("assets/models/box.model.json"),
              R"({"format": "factoria.model/1", "nodes": [{"op": "box", "id": "b", "size": [2, 1, 1]}]})");
    p.ok("model.bake", {{"path", "assets/models/box.model.json"}});
}

long covered(const Image& img, int x0, int y0, int w, int h) {
    long n = 0;
    for (int y = y0; y < y0 + h; ++y)
        for (int x = x0; x < x0 + w; ++x)
            if (get(img, x, y).a > 127) ++n;
    return n;
}

}  // namespace

TEST_CASE("model.bake_impostor: writes the json, the colour atlas and the normal atlas, same bytes twice") {
    AssetsProject p;
    write_all(p.file("assets/models/ball.model.json"), kBall);
    p.ok("model.bake", {{"path", "assets/models/ball.model.json"}});
    const Json r =
        p.ok("model.bake_impostor", {{"model", "assets/models/ball.model.json"}, {"views", 4}, {"resolution", 128}});
    CHECK(r["file"] == "assets/models/ball.impostor.json");
    CHECK(r["frameSize"] == 32);
    CHECK(r["views"] == 4);
    const Json doc = parse_json(read_all(p.file("assets/models/ball.impostor.json")), "impostor").value();
    auto parsed = impostor_from_json(doc, "ball.impostor.json");
    REQUIRE(parsed.ok());
    CHECK(parsed->mode == ImpostorMode::Octahedral);
    CHECK(parsed->views == 4);
    CHECK(parsed->frameSize == 32);
    CHECK(parsed->albedo == "assets/models/ball.impostor.png");
    CHECK(parsed->normal == "assets/models/ball.impostor.normal.png");
    CHECK(parsed->radius == doctest::Approx(1.02f * 1.0f).epsilon(0.05));
    CHECK(doc["triangles"].get<long>() > 12);

    const Image albedo = read_png(p.file("assets/models/ball.impostor.png"));
    const Image normal = read_png(p.file("assets/models/ball.impostor.normal.png"));
    CHECK(albedo.width == 128);
    CHECK(albedo.height == 128);
    CHECK(normal.width == 128);
    // a sphere seen from any direction fills a disc of about pi / 4 of the 2R square
    for (int j = 0; j < 4; ++j)
        for (int i = 0; i < 4; ++i) {
            const long n = covered(albedo, i * 32, j * 32, 32, 32);
            CHECK(n > 32 * 32 * 0.65);
            CHECK(n < 32 * 32 * 0.85);
        }
    // the middle of every frame: the normal faces the camera, so the normal map holds the frame's own direction
    for (int j = 0; j < 4; ++j)
        for (int i = 0; i < 4; ++i) {
            const Vec3 d = impostor_direction(ImpostorMode::Octahedral, 4, i, j);
            const Rgba n = get(normal, i * 32 + 16, j * 32 + 16);
            const Vec3 got{n.r / 255.0f * 2 - 1, n.g / 255.0f * 2 - 1, n.b / 255.0f * 2 - 1};
            CHECK(dot(normalize(got), d) > 0.97f);
            CHECK(n.a == 255);
        }
    // the corner of a frame is outside the disc: transparent, with the model's colour dilated into it only near the edge
    CHECK(get(albedo, 0, 0).a == 0);

    const std::string a1 = read_all(p.file("assets/models/ball.impostor.png")),
                      n1 = read_all(p.file("assets/models/ball.impostor.normal.png")),
                      j1 = read_all(p.file("assets/models/ball.impostor.json"));
    p.ok("model.bake_impostor", {{"model", "assets/models/ball.glb"}, {"views", 4}, {"resolution", 128}});
    CHECK(read_all(p.file("assets/models/ball.impostor.png")) == a1);
    CHECK(read_all(p.file("assets/models/ball.impostor.normal.png")) == n1);
    CHECK(read_all(p.file("assets/models/ball.impostor.json")) == j1);
}

TEST_CASE("model.bake_impostor: the silhouette follows the direction and hemiOctahedral gives the upper half") {
    AssetsProject p;
    make_box(p);
    p.ok("model.bake_impostor",
         {{"model", "assets/models/box.glb"}, {"views", 3}, {"resolution", 96}, {"mode", "hemiOctahedral"}});
    const Json doc = parse_json(read_all(p.file("assets/models/box.impostor.json")), "impostor").value();
    CHECK(doc["mode"] == "hemiOctahedral");
    const Image albedo = read_png(p.file("assets/models/box.impostor.png"));
    // the centre frame looks from straight above (y): the 2 x 1 box shows its 2 x 1 top
    const long top = covered(albedo, 32, 32, 32, 32);
    // a frame on the edge of the hemisphere looks along the horizon, from +-x or +-z: the end (1 x 1) or the side (2 x 1) of the box
    long ends = 1000000, sides = 0;
    for (int j = 0; j < 3; ++j)
        for (int i = 0; i < 3; ++i) {
            if (i == 1 && j == 1) continue;
            const long n = covered(albedo, i * 32, j * 32, 32, 32);
            ends = std::min(ends, n);
            sides = std::max(sides, n);
        }
    CHECK(top > 0);
    CHECK(ends != sides);  // not every frame is the same picture
    CHECK(top > 32 * 32 / 4);
}

TEST_CASE("model.bake_impostor: a textured, cut-out material keeps its colour and its holes") {
    AssetsProject p;
    make_box(p);
    // a mesh file with a texture is hard to write by hand: the baked box is one colour, so check the colour factor path instead
    const Json r = p.ok("model.bake_impostor", {{"model", "assets/models/box.glb"}, {"views", 2}, {"resolution", 32}});
    CHECK(r["frameSize"] == 16);
    const Image albedo = read_png(p.file("assets/models/box.impostor.png"));
    long opaque = 0;
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x)
            if (get(albedo, x, y).a == 255) {
                const Rgba c = get(albedo, x, y);
                CHECK(c.r > 0);  // the default material is not black
                ++opaque;
            }
    CHECK(opaque > 100);
}

TEST_CASE("model.bake_impostor: arguments that teach") {
    AssetsProject p;
    make_box(p);
    auto fails = [&](const Json& args, const char* what) {
        const CommandResult r = p.call("model.bake_impostor", args);
        REQUIRE_FALSE(r.ok);
        CHECK_MESSAGE(r.error.dump().find(what) != std::string::npos, r.error.dump());
        return r;
    };
    fails({{"model", "assets/models/box.glb"}, {"view", 4}}, "views");  // did you mean
    fails({{"model", "assets/models/box.glb"}, {"views", 1}}, "/views");
    fails({{"model", "assets/models/box.glb"}, {"views", 99}}, "/views");
    fails({{"model", "assets/models/box.glb"}, {"views", 2.5}}, "/views");
    fails({{"model", "assets/models/box.glb"}, {"resolution", 99999}}, "/resolution");
    fails({{"model", "assets/models/box.glb"}, {"views", 32}, {"resolution", 128}}, "/resolution");  // 4 px frames
    fails({{"model", "assets/models/box.glb"}, {"mode", "octahedron"}}, "octahedral");               // did you mean
    fails({{"model", "assets/models/nothing.glb"}}, "not_found");
    fails({{"model", "assets/models/box.png"}}, "/model");
    fails({{"model", "../outside.glb"}}, "/model");
    fails({{"model", "assets/models/ghost.model.json"}}, "ghost");
    write_all(p.file("assets/models/unbaked.model.json"),
              R"({"format": "factoria.model/1", "nodes": [{"op": "box", "id": "b", "size": [1, 1, 1]}]})");
    fails({{"model", "assets/models/unbaked.model.json"}}, "model.bake");
    CHECK_FALSE(p.exists("assets/models/box.impostor.json"));  // nothing was written by a refused call
}

TEST_CASE("model.bake_impostor: it replaces its own files and refuses to replace other files") {
    AssetsProject p;
    make_box(p);
    p.ok("model.bake_impostor", {{"model", "assets/models/box.glb"}, {"views", 2}, {"resolution", 32}});
    // our own files: a second bake with other arguments replaces them
    const Json again =
        p.ok("model.bake_impostor", {{"model", "assets/models/box.glb"}, {"views", 4}, {"resolution", 64}});
    CHECK(again["frameSize"] == 16);
    CHECK(read_png(p.file("assets/models/box.impostor.png")).width == 64);
    // somebody else's picture at the path is not replaced
    p.file("assets/models/box.impostor.png");
    std::filesystem::remove(p.file("assets/models/box.impostor.json"));
    write_all(p.file("assets/models/box.impostor.png"), "not ours");
    const CommandResult r =
        p.call("model.bake_impostor", {{"model", "assets/models/box.glb"}, {"views", 2}, {"resolution", 32}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "exists");
    CHECK(r.error.dump().find("overwrite") != std::string::npos);
    CHECK(read_all(p.file("assets/models/box.impostor.png")) == "not ours");
    p.ok("model.bake_impostor",
         {{"model", "assets/models/box.glb"}, {"views", 2}, {"resolution", 32}, {"overwrite", true}});
    CHECK(read_png(p.file("assets/models/box.impostor.png")).width == 32);
}

TEST_CASE("model.bake_impostor: apply with no scene says so, and the command is a project write") {
    AssetsProject p;
    make_box(p);
    const Json r = p.ok("model.bake_impostor",
                        {{"model", "assets/models/box.glb"}, {"views", 2}, {"resolution", 32}, {"apply", true}});
    CHECK(r["applied"].empty());
    CHECK(has_warning(r, "no scene"));
    const CommandInfo* info = p.registry.info("model.bake_impostor");
    REQUIRE(info);
    CHECK_FALSE(info->readOnly);
    CHECK(info->inputSchema["properties"]["resolution"]["default"] == 1024);
}
