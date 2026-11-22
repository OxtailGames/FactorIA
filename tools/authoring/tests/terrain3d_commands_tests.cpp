// M75-P5b: terrain.create, terrain.sculpt, terrain.paint, terrain.holes, terrain.generate, terrain.save, terrain.undo and
// terrain.redo (tools/authoring/src/terrain3d_commands.cpp): live edits of the shared heights, one undo step per command, the
// physics collider that follows, the files written on save, and the errors that teach.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/authoring/authoring.h"
#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/runtime/engine.h"
#include "fa/scene/terrain.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Project {
    stdfs::path dir;
    Engine e;
    Project() {
        authoring::install();
        dir = fs::make_temp_dir("fa_terrain_cmd").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({"format":"factoria.project/1","name":"Terrain","id":"com.example.terrain","mainScene":"scenes/main.scene.json",
                   "display":{"width":320,"height":180}})";
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary)
            << R"({"format": "factoria.scene/1", "entities": []})";
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    }
    ~Project() {
        e.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    CommandResult call(const char* name, const std::string& args) { return e.commands().call(name, Json::parse(args)); }
    Json ok(const char* name, const std::string& args) {
        auto r = call(name, args);
        REQUIRE_MESSAGE(r.ok, name << " " << args << " -> " << r.error.dump());
        return r.result;
    }
    // The error text of a call that must fail: message, hint and code in one string.
    std::string refused(const char* name, const std::string& args) {
        auto r = call(name, args);
        REQUIRE_MESSAGE(!r.ok, name << " " << args << " was accepted");
        return r.error.dump();
    }
    std::shared_ptr<TerrainHeights> heights(const char* id) {
        Entity en = e.world().find(id);
        REQUIRE(en);
        auto h = e.world().terrain().heights(e.world(), en);
        REQUIRE(h);
        return h;
    }
    // A 65 x 65 terrain of 64 x 64 metres (one sample per metre, the middle sample at [0, 0]) with a height range of 100 m.
    void make(const char* id, const char* extra = "") {
        ok("terrain.create", std::string(R"({"name":")") + id + R"(","size":[64,64],"resolution":65)" + extra + "}");
    }
    double height(const char* id, double x, double z) {
        float h = 0;
        REQUIRE(terrain_height_at(e.world(), e.world().find(id), float(x), float(z), h));
        return double(h);
    }
    // Does a ray straight down at (x, z) meet something, and where.
    bool ray(double x, double z, double* y = nullptr) {
        auto r = call("physics.raycast", "{\"dimension\":\"3d\",\"origin\":[" + std::to_string(x) + ",300," +
                                             std::to_string(z) + "],\"direction\":[0,-1,0],\"maxDistance\":600}");
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        if (r.result["hit"] != true) return false;
        if (y) *y = r.result["point"][1].get<double>();
        return true;
    }
};

bool contains(const std::string& s, const char* part) { return s.find(part) != std::string::npos; }

// FNV-1a over the samples (little endian): a pinned value fails on any change of the arithmetic, on any CPU.
std::uint64_t checksum(const std::vector<std::uint16_t>& v) {
    std::uint64_t h = 1469598103934665603ull;
    for (std::uint16_t s : v)
        for (int b = 0; b < 2; ++b) {
            h ^= std::uint64_t((s >> (8 * b)) & 0xFF);
            h *= 1099511628211ull;
        }
    return h;
}

}  // namespace

TEST_CASE("terrain.create: writes a flat 16-bit heightmap and an entity that uses it") {
    Project p;
    Json r =
        p.ok("terrain.create", R"({"name":"ground","size":[64,64],"resolution":65,"heightScale":50,"baseHeight":2})");
    CHECK(r["entity"] == "ground");
    CHECK(r["heightmap"] == "assets/terrain/ground.height.png");
    CHECK(r["samples"] == 65);
    auto bytes = fs::read_bytes("assets/terrain/ground.height.png");
    REQUIRE(bytes);
    auto img = decode_gray16(bytes->data(), bytes->size());
    REQUIRE(img);
    CHECK(img->width == 65);
    CHECK(img->height == 65);
    CHECK(img->sixteenBit);
    for (std::uint16_t v : img->samples) REQUIRE(v == 32768);
    const Terrain3D* t = p.e.world().get<Terrain3D>(p.e.world().find("ground"));
    REQUIRE(t != nullptr);
    CHECK(t->heightmap == "assets/terrain/ground.height.png");
    CHECK(t->size.x == 64.0f);
    CHECK(p.height("ground", 3.0, -4.0) == doctest::Approx(2.0).epsilon(1e-4).scale(1.0));
    // a second terrain of the same name or file is refused, nothing is overwritten
    CHECK(contains(p.refused("terrain.create", R"({"name":"ground"})"), "already exists"));
    CHECK(contains(p.refused("terrain.create", R"({"name":"other","path":"assets/terrain/ground.height.png"})"),
                   "/path"));
    // resolutions that are not 2^k + 1 say which ones work
    const std::string e1 = p.refused("terrain.create", R"({"name":"x","resolution":100})");
    CHECK(contains(e1, "/resolution"));
    CHECK(contains(e1, "129"));
    // an unknown argument gets a did you mean
    CHECK(contains(p.refused("terrain.create", R"({"name":"y","sizes":[1,1]})"), "size"));
    // importing the file just written
    Json imp =
        p.ok("terrain.create", R"({"name":"copy","heightmap":"assets/terrain/ground.height.png","size":[10,10]})");
    CHECK(imp["imported"] == true);
    CHECK(imp["samples"] == 65);
    CHECK(contains(p.refused("terrain.create", R"({"name":"bad","heightmap":"assets/terrain/missing.png"})"),
                   "/heightmap"));
}

TEST_CASE("terrain.sculpt: brushes change the surface inside the circle only, deterministically") {
    Project p;
    p.make("a");
    p.make("b");
    const double base = p.height("a", 0, 0);
    Json r =
        p.ok("terrain.sculpt", R"({"entity":"a","tool":"raise","center":[0,0],"radius":10,"amount":5,"strength":1})");
    CHECK(r["changedSamples"].get<int>() > 100);
    CHECK(r["undoDepth"] == 1);
    CHECK(r["unsaved"] == true);
    CHECK(p.height("a", 0, 0) == doctest::Approx(base + 5.0).epsilon(1e-3).scale(1.0));
    CHECK(p.height("a", 5, 0) > base + 0.5);
    CHECK(p.height("a", 5, 0) < base + 5.0);
    CHECK(p.height("a", 20, 0) == doctest::Approx(base).epsilon(1e-6).scale(1.0));
    CHECK(p.height("a", 0, -11) == doctest::Approx(base).epsilon(1e-6).scale(1.0));
    // the same command on the other terrain gives the same bits
    p.ok("terrain.sculpt", R"({"entity":"b","tool":"raise","center":[0,0],"radius":10,"amount":5,"strength":1})");
    CHECK(p.heights("a")->data == p.heights("b")->data);
    // lower, flatten, smooth
    p.ok("terrain.sculpt", R"({"entity":"a","tool":"lower","center":[0,0],"radius":10,"amount":5,"strength":1})");
    CHECK(p.height("a", 0, 0) == doctest::Approx(base).epsilon(1e-3).scale(1.0));
    p.ok("terrain.sculpt", R"({"entity":"a","tool":"flatten","center":[0,0],"radius":6,"strength":1,"height":7})");
    CHECK(p.height("a", 0, 0) == doctest::Approx(7.0).epsilon(1e-3).scale(1.0));
    p.ok("terrain.sculpt", R"({"entity":"a","tool":"raise","center":[0,0],"radius":2,"amount":20,"strength":1})");
    const double spike = p.height("a", 0, 0);
    p.ok("terrain.sculpt", R"({"entity":"a","tool":"smooth","center":[0,0],"radius":4,"strength":1})");
    CHECK(p.height("a", 0, 0) < spike - 1.0);
    // a stroke of points is one undo step
    const std::size_t depth = p.heights("a")->undo_depth();
    Json s = p.ok("terrain.sculpt",
                  R"({"entity":"a","points":[[-20,-20],[-18,-20],[-16,-20],[-14,-20]],"radius":3,"amount":2})");
    CHECK(s["stamps"] == 4);
    CHECK(p.heights("a")->undo_depth() == depth + 1);
    // outside the terrain: nothing changes, no step
    Json out = p.ok("terrain.sculpt", R"({"entity":"a","center":[500,500],"radius":5})");
    CHECK(out["changedSamples"] == 0);
    CHECK(p.heights("a")->undo_depth() == depth + 1);
}

TEST_CASE("terrain.sculpt: honours the entity's transform") {
    Project p;
    p.make("t");
    p.ok(
        "scene.set_component",
        R"({"id":"t","component":"Transform","fields":{"position":[100,10,-50],"rotation":[0,90,0],"scale":[2,3,2]}})");
    const double base = p.height("t", 100, -50);
    CHECK(base == doctest::Approx(10.0).epsilon(1e-3).scale(1.0));
    Json r = p.ok("terrain.sculpt", R"({"entity":"t","center":[110,-50],"radius":8,"amount":2,"strength":1})");
    CHECK(r["changedSamples"].get<int>() > 20);
    // `amount` is in world metres whatever the entity's scale, and the world bounds follow the brush
    CHECK(p.height("t", 110, -50) == doctest::Approx(10.0 + 2.0).epsilon(1e-3).scale(1.0));
    CHECK(p.height("t", 100, -50) == doctest::Approx(base).epsilon(1e-6).scale(1.0));
    CHECK(p.height("t", 130, -50) == doctest::Approx(base).epsilon(1e-6).scale(1.0));
    const Json& b = r["bounds"];
    CHECK(b[0].get<double>() > 100.0);
    CHECK(b[2].get<double>() < 120.0);
    // a brush on the centre of the world (far from the terrain) changes nothing
    CHECK(p.ok("terrain.sculpt", R"({"entity":"t","center":[0,0],"radius":8})")["changedSamples"] == 0);
}

TEST_CASE("terrain.undo and terrain.redo: bit-exact, one step per command") {
    Project p;
    p.make("g");
    const std::vector<std::uint16_t> start = p.heights("g")->data;
    p.ok("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":12,"amount":9})");
    const std::vector<std::uint16_t> one = p.heights("g")->data;
    p.ok("terrain.sculpt", R"({"entity":"g","tool":"smooth","points":[[0,0],[3,3]],"radius":9,"strength":1})");
    p.ok("terrain.holes", R"({"entity":"g","center":[10,10],"radius":4})");
    p.ok("terrain.paint", R"({"entity":"g","layer":2,"center":[-10,-10],"radius":6,"strength":1})");
    const std::vector<std::uint16_t> four = p.heights("g")->data;
    const std::vector<std::uint8_t> holes4 = p.heights("g")->holes;
    const std::vector<std::uint8_t> splat4 = p.heights("g")->splat[0].rgba;
    CHECK(p.heights("g")->undo_depth() == 4);
    Json u = p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(u["undone"] == "terrain.paint");
    CHECK(u["redoDepth"] == 1);
    p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(p.heights("g")->holes != holes4);
    p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(p.heights("g")->data == one);
    p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(p.heights("g")->data == start);
    CHECK(contains(p.refused("terrain.undo", R"({"entity":"g"})"), "nothing_to_undo"));
    for (int i = 0; i < 4; ++i) p.ok("terrain.redo", R"({"entity":"g"})");
    CHECK(p.heights("g")->data == four);
    CHECK(p.heights("g")->holes == holes4);
    CHECK(p.heights("g")->splat[0].rgba == splat4);
    CHECK(contains(p.refused("terrain.redo", R"({"entity":"g"})"), "nothing_to_redo"));
    // a new edit clears the redo list
    p.ok("terrain.undo", R"({"entity":"g"})");
    p.ok("terrain.sculpt", R"({"entity":"g","center":[20,20],"radius":3})");
    CHECK(p.heights("g")->redo_depth() == 0);
}

TEST_CASE("terrain.holes: the collider follows a cut and a fill, and undo closes the hole") {
    Project p;
    p.make("g");
    p.ok("game.step", R"({"frames":2})");
    double y = 0;
    REQUIRE(p.ray(0, 0, &y));
    CHECK(y == doctest::Approx(0.0).epsilon(1e-3).scale(1.0));
    Json r = p.ok("terrain.holes", R"({"entity":"g","center":[0,0],"radius":5})");
    CHECK(r["changedTexels"].get<int>() > 40);
    CHECK(r["holes"] == "assets/terrain/g.holes.png");
    p.ok("game.step", R"({"frames":2})");
    CHECK_FALSE(p.ray(0, 0));
    CHECK_FALSE(p.ray(2, 2));
    CHECK(p.ray(12, 0));  // outside the hole
    CHECK(p.heights("g")->holes.size() == 64u * 64u);
    // fill part of it
    p.ok("terrain.holes", R"({"entity":"g","mode":"fill","center":[0,0],"radius":2})");
    p.ok("game.step", R"({"frames":2})");
    CHECK(p.ray(0, 0));
    CHECK_FALSE(p.ray(4, 0));
    // undo twice: no hole at all
    p.ok("terrain.undo", R"({"entity":"g"})");
    p.ok("terrain.undo", R"({"entity":"g"})");
    p.ok("game.step", R"({"frames":2})");
    CHECK(p.ray(0, 0));
    CHECK(p.ray(4, 0));
    p.ok("terrain.redo", R"({"entity":"g"})");
    p.ok("game.step", R"({"frames":2})");
    CHECK_FALSE(p.ray(0, 0));
}

TEST_CASE("terrain.sculpt: the collider follows the sculpt, and its undo") {
    Project p;
    p.make("g");
    p.ok("game.step", R"({"frames":2})");
    double y0 = 0, y1 = 0, y2 = 0;
    REQUIRE(p.ray(0, 0, &y0));
    p.ok("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":10,"amount":8,"strength":1})");
    p.ok("game.step", R"({"frames":2})");
    REQUIRE(p.ray(0, 0, &y1));
    CHECK(y1 == doctest::Approx(y0 + 8.0).epsilon(1e-3).scale(1.0));
    CHECK(std::fabs(y1 - p.height("g", 0, 0)) < 2e-3);
    double ys = 0;
    REQUIRE(p.ray(4.3, 2.7, &ys));
    CHECK(std::fabs(ys - p.height("g", 4.3, 2.7)) < 2e-3);
    p.ok("terrain.undo", R"({"entity":"g"})");
    p.ok("game.step", R"({"frames":2})");
    REQUIRE(p.ray(0, 0, &y2));
    CHECK(y2 == doctest::Approx(y0).epsilon(1e-3).scale(1.0));
}

TEST_CASE("terrain.paint: weights stay normalised across the two splat maps") {
    Project p;
    p.make("g");
    Json r = p.ok("terrain.paint", R"({"entity":"g","layer":1,"center":[0,0],"radius":10,"strength":1})");
    CHECK(r["created"].size() == 1);
    CHECK(r["map"] == 0);
    CHECK(r["channel"] == 1);
    auto h = p.heights("g");
    REQUIRE(h->splat[0].valid());
    CHECK(h->splat[0].size == 64);
    const Terrain3D* t = p.e.world().get<Terrain3D>(p.e.world().find("g"));
    REQUIRE(t->splatMaps.size() == 1);
    CHECK(t->splatMaps[0] == "assets/terrain/g.splat0.png");
    auto texel = [&](int map, double x, double z) {
        const int i = int(std::floor((x + 32.0) / 64.0 * 64.0)), j = int(std::floor((z + 32.0) / 64.0 * 64.0));
        return &h->splat[std::size_t(map)].rgba[(std::size_t(j) * 64 + std::size_t(i)) * 4];
    };
    const std::uint8_t* mid = texel(0, 0.5, 0.5);
    CHECK(int(mid[0]) < 16);
    CHECK(int(mid[1]) > 240);
    const std::uint8_t* far = texel(0, 20.5, 20.5);
    CHECK(int(far[0]) == 255);
    // layer 6 is in the second map; the sum over all 8 channels is 255 everywhere
    p.ok("terrain.paint", R"({"entity":"g","layer":6,"center":[2,0],"radius":9,"strength":0.6})");
    REQUIRE(h->splat[1].valid());
    for (std::size_t i = 0; i < h->splat[0].rgba.size(); i += 4) {
        int sum = 0;
        for (int c = 0; c < 4; ++c) sum += h->splat[0].rgba[i + std::size_t(c)] + h->splat[1].rgba[i + std::size_t(c)];
        REQUIRE(sum == 255);
    }
    const std::uint8_t* part = texel(1, 2.5, 0.5);
    CHECK(int(part[2]) > 100);
    // undo the second paint: the first map is as it was, the second is all zeros
    const std::vector<std::uint8_t> before = h->splat[0].rgba;
    p.ok("terrain.paint", R"({"entity":"g","layer":3,"center":[0,0],"radius":10,"strength":1})");
    CHECK(h->splat[0].rgba != before);
    p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(h->splat[0].rgba == before);
    // layers that are declared bound the layer index
    p.ok("scene.set_component",
         R"({"id":"g","component":"Terrain","fields":{"layers":[{"albedo":"a.png"},{"albedo":"b.png"}]}})");
    const std::string e = p.refused("terrain.paint", R"({"entity":"g","layer":3,"center":[0,0],"radius":3})");
    CHECK(contains(e, "/layer"));
    CHECK(contains(e, "2 layer"));
}

TEST_CASE("terrain.paint and terrain.holes: files round trip, a scene save flushes them") {
    Project p;
    p.make("g");
    p.ok("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":10,"amount":6,"strength":1})");
    p.ok("terrain.paint", R"({"entity":"g","layer":1,"center":[0,0],"radius":8,"strength":1})");
    p.ok("terrain.holes", R"({"entity":"g","center":[10,10],"radius":3})");
    auto h = p.heights("g");
    CHECK(h->any_unsaved());
    // nothing was written yet
    auto flatBytes = fs::read_bytes("assets/terrain/g.height.png");
    REQUIRE(flatBytes);
    auto flat = decode_gray16(flatBytes->data(), flatBytes->size());
    REQUIRE(flat);
    CHECK(flat->samples[32 * 65 + 32] == 32768);
    CHECK_FALSE(fs::exists("assets/terrain/g.splat0.png"));
    CHECK_FALSE(fs::exists("assets/terrain/g.holes.png"));
    // a scene save writes the three planes
    p.ok("scene.save", "{}");
    CHECK_FALSE(h->any_unsaved());
    auto bytes = fs::read_bytes("assets/terrain/g.height.png");
    REQUIRE(bytes);
    auto img = decode_gray16(bytes->data(), bytes->size());
    REQUIRE(img);
    CHECK(img->samples == h->data);
    auto sp = fs::read_bytes("assets/terrain/g.splat0.png");
    REQUIRE(sp);
    auto spImg = decode_image(sp->data(), sp->size());
    REQUIRE(spImg);
    CHECK(spImg->width == 64);
    CHECK(spImg->rgba == h->splat[0].rgba);  // including the texels whose alpha (layer 3) is 0
    auto hb = fs::read_bytes("assets/terrain/g.holes.png");
    REQUIRE(hb);
    auto holeImg = decode_gray16(hb->data(), hb->size());
    REQUIRE(holeImg);
    CHECK(holeImg->width == 64);
    CHECK_FALSE(holeImg->sixteenBit);
    std::size_t holeCount = 0;
    for (std::size_t i = 0; i < h->holes.size(); ++i) {
        const bool png = holeImg->samples[i] >= 128 * 257;
        CHECK(png == (h->holes[i] != 0));
        holeCount += h->holes[i];
    }
    CHECK(holeCount > 10);
    // terrain.save with nothing to write is fine; save:true writes after an edit; a reload of the files gives the same planes
    CHECK(p.ok("terrain.save", R"({"entity":"g"})")["saved"].empty());
    Json r = p.ok("terrain.sculpt", R"({"entity":"g","center":[-20,-20],"radius":4,"save":true})");
    CHECK(r["saved"].size() == 1);
    CHECK(r["unsaved"] == false);
    auto loaded = load_terrain_heightmap("assets/terrain/g.height.png");
    REQUIRE(loaded);
    CHECK(loaded->heights->data == h->data);
}

TEST_CASE("terrain.generate: seeded noise and erosion are deterministic, one undo step") {
    Project p;
    p.make("a");
    p.make("b");
    p.make("c");
    Json ra =
        p.ok("terrain.generate", R"({"entity":"a","seed":7,"octaves":4,"frequency":0.03,"erosion":3000,"thermal":4})");
    p.ok("terrain.generate", R"({"entity":"b","seed":7,"octaves":4,"frequency":0.03,"erosion":3000,"thermal":4})");
    p.ok("terrain.generate", R"({"entity":"c","seed":8,"octaves":4,"frequency":0.03,"erosion":3000,"thermal":4})");
    CHECK(p.heights("a")->data == p.heights("b")->data);
    CHECK(p.heights("a")->data != p.heights("c")->data);
    CHECK(ra["maxHeight"].get<double>() > ra["minHeight"].get<double>() + 10.0);
    CHECK(ra["maxHeight"].get<double>() <= 50.0);  // heightOffset -50 (baseHeight 0, half way up) + heightScale 100
    CHECK(ra["erosion"]["droplets"] == 3000);
    CHECK(p.heights("a")->undo_depth() == 1);
    p.ok("terrain.undo", R"({"entity":"a"})");
    for (std::uint16_t v : p.heights("a")->data) REQUIRE(v == 32768);
    // ridged noise and a lower amplitude
    p.ok("terrain.generate", R"({"entity":"a","seed":2,"fractal":"ridged","amplitude":0.25})");
    std::uint16_t hi = 0;
    for (std::uint16_t v : p.heights("a")->data) hi = std::max(hi, v);
    CHECK(hi <= 16384 + 2);
    // a resolution that disagrees with the terrain, and work beyond the cap, are refused before anything changes
    const std::vector<std::uint16_t> keep = p.heights("a")->data;
    CHECK(contains(p.refused("terrain.generate", R"({"entity":"a","resolution":129})"), "/resolution"));
    CHECK(contains(p.refused("terrain.generate", R"({"entity":"a","erosion":100000000})"), "/erosion"));
    CHECK(p.heights("a")->data == keep);
    // a terrain with no heightmap gets a grid and a path, written on save
    p.ok("scene.spawn", R"({"name":"empty","components":{"Terrain":{"size":[32,32]}}})");
    Json r = p.ok("terrain.generate", R"({"entity":"empty","resolution":33,"seed":3,"save":true})");
    const std::string made = r["heightmap"].get<std::string>();
    CHECK(contains(made, ".height.png"));
    CHECK(r["samples"] == 33);
    CHECK(r["sceneChanged"] == true);
    CHECK(fs::exists(made));
    CHECK(p.heights("empty")->samples == 33);
}

TEST_CASE("terrain commands: errors name the argument, the cause and the fix") {
    Project p;
    p.make("g");
    p.ok("scene.spawn", R"({"name":"rock"})");
    const std::string noEntity = p.refused("terrain.sculpt", R"({"entity":"gg","center":[0,0],"radius":3})");
    CHECK(contains(noEntity, "not_found"));
    CHECK(contains(noEntity, "g"));
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"rock","center":[0,0],"radius":3})"), "no Terrain"));
    const std::string both =
        p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"points":[[1,1]],"radius":3})");
    CHECK(contains(both, "/points"));
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"g","radius":3})"), "/center"));
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"g","center":[0],"radius":3})"), "center"));
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":0})"), "radius"));
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"g","tool":"raze","center":[0,0],"radius":3})"), "raise"));
    CHECK(
        contains(p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":3,"strenght":1})"), "strength"));
    CHECK(contains(p.refused("terrain.paint", R"({"entity":"g","layer":9,"center":[0,0],"radius":3})"), "layer"));
    CHECK(contains(p.refused("terrain.holes", R"({"entity":"g","mode":"dig","center":[0,0],"radius":3})"), "cut"));
    // an entity without a heightmap cannot be sculpted, and the error says how to get one
    p.ok("scene.spawn", R"({"name":"bare","components":{"Terrain":{}}})");
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"bare","center":[0,0],"radius":3})"), "terrain.generate"));
    // nothing above changed the terrain
    CHECK(p.heights("g")->undo_depth() == 0);
}

TEST_CASE("terrain commands: results are pinned bit for bit (the same on every CPU)") {
    Project p;
    p.make("a");
    p.ok("terrain.generate", R"({"entity":"a","seed":7,"octaves":4,"frequency":0.03,"erosion":500,"thermal":2})");
    CHECK(checksum(p.heights("a")->data) == 4190583852949114925ull);
    p.make("b");
    p.ok("terrain.sculpt",
         R"({"entity":"b","tool":"raise","points":[[-20,-10],[-10,0],[0,10]],"radius":7,"amount":9})");
    p.ok("terrain.sculpt", R"({"entity":"b","tool":"smooth","center":[-10,0],"radius":9,"strength":0.8})");
    p.ok("terrain.sculpt", R"({"entity":"b","tool":"flatten","center":[0,10],"radius":6,"strength":0.7,"height":12})");
    CHECK(checksum(p.heights("b")->data) == 11291136079281194523ull);
}

TEST_CASE("terrain commands: every file is written inside the project") {
    Project p;
    CommandCapabilityScope scope(capability_sets::mcp());  // an agent: it may write the project, not anywhere
    const std::string outside = fs::path_to_utf8(p.dir.parent_path() / "fa_terrain_outside.height.png");
    // an absolute path and a path that leaves the project are refused by terrain.create, with the argument and the fix
    const std::string abs = p.refused("terrain.create", R"({"name":"x","path":")" + outside + R"("})");
    CHECK(contains(abs, "/path"));
    CHECK(contains(abs, "inside the project"));
    CHECK(contains(p.refused("terrain.create", R"({"name":"y","path":"../fa_terrain_outside.height.png"})"), "/path"));
    CHECK_FALSE(fs::exists(outside));
    CHECK_FALSE(fs::exists("../fa_terrain_outside.height.png"));
    CHECK_FALSE(p.e.world().find("x"));
    CHECK_FALSE(p.e.world().find("y"));
    // 'path' with 'heightmap' contradict each other
    p.make("g");
    CHECK(contains(
        p.refused("terrain.create", R"({"name":"z","heightmap":"assets/terrain/g.height.png","path":"a.png"})"),
        "/path"));
    // a terrain whose files are named by an absolute or an escaping path is not written by a save either
    p.ok("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":5,"amount":3,"strength":1})");
    p.ok("scene.set_component", R"({"id":"g","component":"Terrain","fields":{"holes":")" + outside + R"("}})");
    p.ok("terrain.holes", R"({"entity":"g","center":[10,10],"radius":3})");
    const std::string save = p.refused("terrain.save", R"({"entity":"g"})");
    CHECK(contains(save, "Terrain.holes"));
    CHECK(contains(save, "inside the project"));
    CHECK_FALSE(fs::exists(outside));
    CHECK(p.heights("g")->any_unsaved());
    p.ok("scene.set_component",
         R"({"id":"g","component":"Terrain","fields":{"holes":"../fa_terrain_outside.holes.png"}})");
    p.ok("terrain.holes", R"({"entity":"g","center":[10,10],"radius":3})");
    CHECK(contains(p.refused("terrain.save", R"({})"), "Terrain.holes"));
    CHECK_FALSE(fs::exists("../fa_terrain_outside.holes.png"));
    // the scene save reports it too, and the scene file itself was written
    CHECK(contains(p.refused("scene.save", "{}"), "Terrain.holes"));
    CHECK_FALSE(fs::exists("../fa_terrain_outside.holes.png"));
}

TEST_CASE("terrain commands: default names are unique, a paint that changes nothing makes no map") {
    Project p;
    // no name: terrain, terrain_2; the files never collide
    CHECK(p.ok("terrain.create", R"({"resolution":33})")["entity"] == "terrain");
    Json second = p.ok("terrain.create", R"({"resolution":33})");
    CHECK(second["entity"] == "terrain_2");
    CHECK(second["heightmap"] == "assets/terrain/terrain_2.height.png");
    // "a/b" and "a_b" map to one file stem, and ids that differ in case to one file name on some systems
    p.ok("terrain.create", R"({"name":"a/b","resolution":33})");
    Json clash = p.ok("terrain.create", R"({"name":"a_b","resolution":33})");
    CHECK(clash["heightmap"] == "assets/terrain/a_b_2.height.png");
    CHECK(p.ok("terrain.create", R"({"name":"Rock","resolution":33})")["heightmap"] ==
          "assets/terrain/Rock.height.png");
    CHECK(p.ok("terrain.create", R"({"name":"rock","resolution":33})")["heightmap"] ==
          "assets/terrain/rock_2.height.png");
    // holes get a unique file too
    p.ok("scene.set_component",
         R"({"id":"a_b","component":"Terrain","fields":{"holes":"assets/terrain/terrain.holes.png"}})");
    Json h = p.ok("terrain.holes", R"({"entity":"terrain","center":[0,0],"radius":30})");
    CHECK(h["holes"] == "assets/terrain/terrain_2.holes.png");
    // a paint with strength 0 changes nothing: no splat map, no scene change
    Json none = p.ok("terrain.paint", R"({"entity":"terrain_2","layer":5,"center":[0,0],"radius":20,"strength":0})");
    CHECK(none["changedTexels"] == 0);
    CHECK_FALSE(none.contains("created"));
    CHECK_FALSE(none.contains("sceneChanged"));
    CHECK_FALSE(p.heights("terrain_2")->splat[0].valid());
    CHECK_FALSE(p.heights("terrain_2")->splat[1].valid());
    CHECK(p.heights("terrain_2")->undo_depth() == 0);
    Json some = p.ok("terrain.paint", R"({"entity":"terrain_2","layer":5,"center":[0,0],"radius":20,"strength":1})");
    CHECK(some["created"].size() == 2);
    CHECK(p.heights("terrain_2")->splat[1].valid());
}

TEST_CASE("terrain commands: a terrain scaled to nothing is refused, not edited as if unscaled") {
    Project p;
    p.make("g");
    p.ok("scene.set_component", R"({"id":"g","component":"Transform","fields":{"scale":[1,0,1]}})");
    const std::string err = p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":5})");
    CHECK(contains(err, "scale"));
    CHECK(p.heights("g")->undo_depth() == 0);
}

TEST_CASE(
    "terrain.sculpt, paint and holes: continueStroke joins the newest undo step, so a stroke in pieces is one step") {
    Project p;
    p.make("g");
    const std::vector<std::uint16_t> start = p.heights("g")->data;
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":5,"continueStroke":true})"),
                   "/continueStroke"));
    p.ok("terrain.sculpt", R"({"entity":"g","points":[[-20,0],[-18,0]],"radius":4,"amount":3})");
    Json r = p.ok("terrain.sculpt",
                  R"({"entity":"g","points":[[-16,0],[-14,0]],"radius":4,"amount":3,"continueStroke":true})");
    CHECK(r["continued"] == true);
    p.ok("terrain.sculpt", R"({"entity":"g","points":[[-12,6]],"radius":4,"amount":3,"continueStroke":true})");
    CHECK(p.heights("g")->undo_depth() == 1);
    const std::vector<std::uint16_t> done = p.heights("g")->data;
    CHECK(done != start);
    p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(p.heights("g")->data == start);  // the first piece's before, bit for bit: the whole stroke is gone
    p.ok("terrain.redo", R"({"entity":"g"})");
    CHECK(p.heights("g")->data == done);
    // A piece that changes nothing (outside the terrain) adds nothing; another command's step is not continued.
    p.ok("terrain.sculpt", R"({"entity":"g","center":[500,500],"radius":4,"continueStroke":true})");
    CHECK(p.heights("g")->undo_depth() == 1);
    CHECK(contains(p.refused("terrain.holes", R"({"entity":"g","center":[0,0],"radius":3,"continueStroke":true})"),
                   "newest edit"));
    p.ok("terrain.undo", R"({"entity":"g"})");
    CHECK(contains(p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":3,"continueStroke":true})"),
                   "/continueStroke"));  // nothing to continue after an undo
    // The same stroke in one command and in pieces ends with the same surface, give or take the rounding to a sample between pieces.
    p.make("a");
    p.make("b");
    p.ok("terrain.sculpt",
         R"({"entity":"a","points":[[-10,0],[-6,0],[-2,0],[2,0]],"radius":5,"amount":4,"strength":1})");
    p.ok("terrain.sculpt", R"({"entity":"b","points":[[-10,0],[-6,0]],"radius":5,"amount":4,"strength":1})");
    p.ok("terrain.sculpt",
         R"({"entity":"b","points":[[-2,0],[2,0]],"radius":5,"amount":4,"strength":1,"continueStroke":true})");
    CHECK(p.heights("b")->undo_depth() == 1);
    int worst = 0;
    for (std::size_t i = 0; i < p.heights("a")->data.size(); ++i)
        worst = std::max(worst, std::abs(int(p.heights("a")->data[i]) - int(p.heights("b")->data[i])));
    CHECK(worst <= 2);
    // paint and holes: the pieces land in one step, undo gives the planes back
    p.ok("terrain.paint", R"({"entity":"a","layer":1,"points":[[10,10],[12,10]],"radius":4,"strength":1})");
    const std::vector<std::uint8_t> noSplat = p.heights("b")->splat[0].rgba;  // no map yet
    CHECK(noSplat.empty());
    p.ok("terrain.paint", R"({"entity":"b","layer":1,"points":[[10,10]],"radius":4,"strength":1})");
    p.ok("terrain.paint",
         R"({"entity":"b","layer":1,"points":[[12,10]],"radius":4,"strength":1,"continueStroke":true})");
    CHECK(p.heights("a")->splat[0].rgba == p.heights("b")->splat[0].rgba);
    CHECK(p.heights("b")->undo_depth() == 2);
    p.ok("terrain.holes", R"({"entity":"b","points":[[-20,-20]],"radius":3})");
    p.ok("terrain.holes", R"({"entity":"b","points":[[-17,-20]],"radius":3,"continueStroke":true})");
    CHECK(p.heights("b")->undo_depth() == 3);  // the sculpt in two pieces, the paint in two, the holes in two
    p.ok("terrain.undo", R"({"entity":"b"})");
    CHECK(std::count(p.heights("b")->holes.begin(), p.heights("b")->holes.end(), std::uint8_t(1)) == 0);
    p.ok("terrain.undo", R"({"entity":"b"})");
    CHECK(p.heights("b")->splat[0].rgba != p.heights("a")->splat[0].rgba);
}

TEST_CASE("terrain.sculpt and terrain.paint: falloff sets how much of the radius the brush fades over") {
    Project p;
    p.make("g");
    p.ok("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":16,"amount":10,"strength":1})");
    const double soft = p.height("g", 12, 0) - p.height("g", 30, 0);
    p.ok("terrain.undo", R"({"entity":"g"})");
    p.ok("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":16,"amount":10,"strength":1,"falloff":0})");
    const double hard = p.height("g", 12, 0) - p.height("g", 30, 0);
    CHECK(hard == doctest::Approx(10.0).epsilon(1e-3).scale(1.0));  // a hard edge: the full amount all the way to it
    CHECK(soft < hard - 1.0);
    CHECK(
        contains(p.refused("terrain.sculpt", R"({"entity":"g","center":[0,0],"radius":16,"falloff":2})"), "/falloff"));
}
