// M75-P6b / P6c-a: foliage.scatter, foliage.paint, foliage.clear, foliage.undo and foliage.redo
// (tools/authoring/src/foliage_commands.cpp): a deterministic scatter over a terrain (with a golden hash), every rejection rule, the
// mesh weights, the spacing, the 2M cap, a transformed Foliage, alignToNormal, paint, clear, the in-memory undo history (strokes,
// the budget, a stale history) and the errors that teach.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/authoring/authoring.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/foliage.h"
#include "fa/scene/terrain.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Project {
    stdfs::path dir;
    Engine e;
    explicit Project(bool withScene = true) {
        authoring::install();
        dir = fs::make_temp_dir("fa_foliage_cmd").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << (std::string(R"({"format":"factoria.project/1","name":"Foliage","id":"com.example.foliage",)") +
                (withScene ? R"("mainScene":"scenes/main.scene.json",)" : R"("mainScene":"",)") +
                R"("display":{"width":320,"height":180}})");
        if (withScene)  // without it the project has no start scene at all: the engine runs with an empty world
            std::ofstream(dir / "scenes/main.scene.json", std::ios::binary)
                << R"({"format": "factoria.scene/1", "entities": []})";
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        ok("terrain.create", R"({"name":"g","size":[64,64],"resolution":65})");
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
    std::string refused(const char* name, const std::string& args) {
        auto r = call(name, args);
        REQUIRE_MESSAGE(!r.ok, name << " " << args << " was accepted");
        return r.error.dump();
    }
    // A Foliage entity with its ScatterRule (`rule` is the JSON of the rule's fields besides terrain).
    void field(const char* id, const std::string& rule, const char* terrain = "g") {
        std::string r = rule;
        r.insert(1, std::string(R"("terrain":")") + terrain + R"(",)");
        ok("scene.spawn", std::string(R"({"id":")") + id + R"(","components":{"Foliage":{},"ScatterRule":)" + r + "}}");
    }
    std::vector<std::uint8_t> bytes(const std::string& file) {
        auto b = fs::read_bytes(file);
        REQUIRE(b.ok());
        return *b;
    }
    std::vector<FoliageInstance> load(const char* id) {
        const Foliage* f = e.world().get<Foliage>(e.world().find(id));
        REQUIRE(f);
        auto r = read_foliage(f->instances, f->meshes.size());
        REQUIRE(r.ok());
        return *r;
    }
    float ground() {
        float h = 0;
        REQUIRE(terrain_height_at(e.world(), e.world().find("g"), 0.0f, 0.0f, h));
        return h;
    }
};

bool contains(const std::string& s, const char* part) { return s.find(part) != std::string::npos; }

const char* kOne = R"({"meshes":[{"mesh":"assets/models/pine.glb","weight":1}],"density":0.5,"seed":7})";

}  // namespace

TEST_CASE("foliage.scatter: the same rule, seed and terrain give the same file byte for byte") {
    Project p;
    p.field("a", kOne);
    p.field("b", kOne);
    Json ra = p.ok("foliage.scatter", R"({"entity":"a"})");
    Json rb = p.ok("foliage.scatter", R"({"entity":"b"})");
    CHECK(ra["file"] == "scenes/main.a.foliage");  // next to the scene (with no scene: assets/foliage/, tested below)
    CHECK(ra["instances"].get<int>() > 500);
    CHECK(ra["placed"] == ra["instances"]);
    CHECK(p.bytes(ra["file"].get<std::string>()) == p.bytes(rb["file"].get<std::string>()));
    // a second run on the same entity writes the same bytes again
    const auto first = p.bytes(ra["file"].get<std::string>());
    p.ok("foliage.scatter", R"({"entity":"a"})");
    CHECK(p.bytes(ra["file"].get<std::string>()) == first);
    // another seed gives another file
    p.ok("scene.set_component", R"({"id":"b","component":"ScatterRule","fields":{"seed":8}})");
    Json rc = p.ok("foliage.scatter", R"({"entity":"b"})");
    CHECK(p.bytes(rc["file"].get<std::string>()) != first);
    // the Foliage names its mesh and the file stays inside the instances of the rule
    const Foliage* f = p.e.world().get<Foliage>(p.e.world().find("a"));
    REQUIRE(f->meshes.size() == 1);
    CHECK(f->meshes[0] == "assets/models/pine.glb");
    CHECK(f->instances == ra["file"].get<std::string>());
    // dryRun counts and changes nothing
    p.field("d", kOne);
    Json rd = p.ok("foliage.scatter", R"({"entity":"d","dryRun":true})");
    CHECK(rd["instances"] == ra["instances"]);
    CHECK(p.e.world().get<Foliage>(p.e.world().find("d"))->instances.empty());
}

TEST_CASE("foliage.scatter: every rejection rule") {
    Project p;
    const float y = p.ground();
    // slope: a flat terrain has slope 0, so [10, 90] rejects everything
    p.field("s", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":0.5,"slopeRange":[10,90]})");
    Json r = p.ok("foliage.scatter", R"({"entity":"s","dryRun":true})");
    CHECK(r["instances"] == 0);
    CHECK(r["rejected"]["slope"].get<int>() + r["rejected"]["outside"].get<int>() == r["candidates"].get<int>());
    CHECK(r["rejected"]["slope"].get<int>() > 1900);
    // height
    p.field("h", "{\"meshes\":[{\"mesh\":\"assets/models/pine.glb\"}],\"density\":0.5,\"heightRange\":[" +
                     std::to_string(y + 1.0f) + ",100000]}");
    r = p.ok("foliage.scatter", R"({"entity":"h","dryRun":true})");
    CHECK(r["instances"] == 0);
    CHECK(r["rejected"]["height"].get<int>() > 1900);
    // outside: the grid of candidates covers the terrain's bounding box only, so a turned terrain would count some; here none
    // holes
    p.ok("terrain.holes", R"({"entity":"g","center":[0,0],"radius":8})");
    p.field("o", kOne);
    r = p.ok("foliage.scatter", R"({"entity":"o"})");
    CHECK(r["rejected"]["hole"].get<int>() > 20);
    for (const FoliageInstance& in : p.load("o")) CHECK(std::hypot(in.position.x, in.position.z) > 7.0f);
    // layers: map 0 channel 1 is painted inside a circle of 10 m; layerMask 2 (layer 1) grows only there
    p.ok("scene.set_component",
         R"({"id":"g","component":"Terrain","fields":{"layers":[{"tileSize":4},{"tileSize":4}]}})");
    p.ok("terrain.paint", R"({"entity":"g","layer":1,"center":[20,20],"radius":10,"strength":1})");
    p.field("l", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"layerMask":2})");
    r = p.ok("foliage.scatter", R"({"entity":"l"})");
    CHECK(r["instances"].get<int>() > 50);
    CHECK(r["rejected"]["layer"].get<int>() > 1000);
    for (const FoliageInstance& in : p.load("l"))
        CHECK(std::hypot(in.position.x - 20.0f, in.position.z - 20.0f) < 11.0f);
    // layer 0 is everywhere else
    p.field("m", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"layerMask":1})");
    for (const FoliageInstance& in : p.load("l")) (void)in;
    r = p.ok("foliage.scatter", R"({"entity":"m"})");
    for (const FoliageInstance& in : p.load("m"))
        CHECK(std::hypot(in.position.x - 20.0f, in.position.z - 20.0f) > 3.0f);
}

TEST_CASE("foliage.scatter: mesh weights, scale, lean and spacing") {
    Project p;
    p.field("w", R"({"meshes":[{"mesh":"assets/models/a.glb","weight":3},{"mesh":"assets/models/b.glb","weight":1}],
                     "density":2,"scaleRange":[0.5,2],"seed":3})");
    Json r = p.ok("foliage.scatter", R"({"entity":"w"})");
    const double ca = r["meshes"][0]["count"].get<double>(), cb = r["meshes"][1]["count"].get<double>();
    CHECK(ca / (ca + cb) == doctest::Approx(0.75).epsilon(0.05));
    for (const FoliageInstance& in : p.load("w")) {
        CHECK(in.scale >= 0.5f);
        CHECK(in.scale <= 2.0f);
        CHECK(in.up.y == doctest::Approx(1.0f));  // alignToNormal 0: upright
    }
    // minSpacing: no pair closer than it
    p.field("sp", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"minSpacing":1.2,"seed":5})");
    r = p.ok("foliage.scatter", R"({"entity":"sp"})");
    CHECK(r["rejected"]["spacing"].get<int>() > 0);
    const auto v = p.load("sp");
    REQUIRE(v.size() > 100);
    for (std::size_t i = 0; i < v.size(); ++i)
        for (std::size_t j = i + 1; j < v.size(); ++j)
            REQUIRE(std::hypot(v[i].position.x - v[j].position.x, v[i].position.z - v[j].position.z) >= 1.2f - 0.001f);
}

TEST_CASE("foliage.scatter: the instance cap and the error cases") {
    Project p;
    // 160 x 160 m at 100 per m2 is 2.56 M instances: over the cap of 2M
    p.ok("terrain.create", R"({"name":"t160","size":[160,160],"resolution":33})");
    p.field("big", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":100})", "t160");
    const std::string e1 = p.refused("foliage.scatter", R"({"entity":"big"})");
    CHECK(contains(e1, "too_many_instances"));
    CHECK(contains(e1, "2000000"));
    CHECK(p.e.world().get<Foliage>(p.e.world().find("big"))->instances.empty());
    p.ok("terrain.create", R"({"name":"t512","size":[512,512],"resolution":33})");
    p.field("huge", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":100})", "t512");
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"huge"})"), "too_many_candidates"));
    // unknown entity: did you mean
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"bigg"})"), "big"));
    // no Foliage, no ScatterRule, no terrain
    p.ok("scene.spawn", R"({"id":"plain"})");
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"plain"})"), "no Foliage component"));
    p.ok("scene.spawn", R"({"id":"norule","components":{"Foliage":{}}})");
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"norule"})"), "ScatterRule"));
    p.ok("scene.spawn", R"({"id":"empty","components":{"Foliage":{},"ScatterRule":{"terrain":"g"}}})");
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"empty"})"), "meshes"));
    p.ok("scene.spawn",
         R"({"id":"loose","components":{"Foliage":{},"ScatterRule":{"meshes":[{"mesh":"assets/models/pine.glb"}]}}})");
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"loose"})"), "No Terrain"));
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"loose","rule":"nope"})"), "nope"));
}

TEST_CASE("foliage.paint: add with spacing against what is there, remove, determinism") {
    Project p;
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb","weight":1},{"mesh":"assets/models/b.glb","weight":1}],
                     "density":1,"seed":2})");
    p.ok("foliage.scatter", R"({"entity":"f"})");  // sets the meshes
    p.ok("foliage.clear", R"({"entity":"f"})");
    Json r = p.ok("foliage.paint", R"({"entity":"f","center":[10,10],"radius":5,"density":2})");
    CHECK(r["added"].get<int>() > 80);
    CHECK(r["removed"] == 0);
    const std::string file = r["file"].get<std::string>();
    CHECK(file == "scenes/main.f.foliage");
    const auto v = p.load("f");
    for (const FoliageInstance& in : v) CHECK(std::hypot(in.position.x - 10.0f, in.position.z - 10.0f) <= 5.001f);
    // the same stroke again adds nothing at the same places: no two instances closer than half the average gap
    const auto before = p.bytes(file);
    Json again = p.ok("foliage.paint", R"({"entity":"f","center":[10,10],"radius":5,"density":2})");
    CHECK(again["added"] == 0);
    CHECK(p.bytes(file) == before);
    // another seed finds free spots
    Json other = p.ok("foliage.paint", R"({"entity":"f","center":[10,10],"radius":5,"density":2,"seed":9})");
    const auto all = p.load("f");
    CHECK(all.size() == v.size() + other["added"].get<std::size_t>());
    for (std::size_t i = 0; i < all.size(); ++i)
        for (std::size_t j = i + 1; j < all.size(); ++j)
            REQUIRE(std::hypot(all[i].position.x - all[j].position.x, all[i].position.z - all[j].position.z) >=
                    0.5 / std::sqrt(2.0) - 0.002);
    // the mesh filter
    Json one = p.ok("foliage.paint", R"({"entity":"f","center":[-20,-20],"radius":4,"mesh":"assets/models/b.glb"})");
    CHECK(one["added"].get<int>() > 0);
    // remove: only mesh b inside the small circle
    Json rm = p.ok("foliage.paint",
                   R"({"entity":"f","mode":"remove","center":[-20,-20],"radius":4,"mesh":"assets/models/a.glb"})");
    CHECK(rm["removed"] == 0);
    rm = p.ok("foliage.paint", R"({"entity":"f","mode":"remove","center":[-20,-20],"radius":4})");
    CHECK(rm["removed"] == one["added"]);
    // errors
    const std::string e1 =
        p.refused("foliage.paint", R"({"entity":"f","center":[0,0],"radius":4,"mesh":"assets/models/c.glb"})");
    CHECK(contains(e1, "/mesh"));
    CHECK(contains(e1, "a.glb"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"f","center":[0,0],"radius":-1})"), "radius"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"f","center":[0],"radius":1})"), "/center"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"ff","center":[0,0],"radius":1})"), "f"));
}

TEST_CASE("foliage.clear: all, or by rectangle") {
    Project p;
    p.field("f", kOne);
    Json s = p.ok("foliage.scatter", R"({"entity":"f"})");
    const int total = s["instances"].get<int>();
    Json r = p.ok("foliage.clear", R"({"entity":"f","region":[-32,-32,0,0]})");
    const int removed = r["removed"].get<int>();
    CHECK(removed > 50);
    CHECK(removed < total / 2);
    const auto v = p.load("f");
    CHECK(int(v.size()) == total - removed);
    for (const FoliageInstance& in : v) CHECK(!(in.position.x <= 0.0f && in.position.z <= 0.0f));
    CHECK(contains(p.refused("foliage.clear", R"({"entity":"f","region":[5,0,0,5]})"), "/region"));
    r = p.ok("foliage.clear", R"({"entity":"f"})");
    CHECK(r["removed"] == total - removed);
    CHECK(p.load("f").empty());
    // nothing left: nothing changes
    r = p.ok("foliage.clear", R"({"entity":"f"})");
    CHECK(r["removed"] == 0);
    CHECK(r.contains("note"));
}

TEST_CASE("foliage.scatter: the file of one fixed seed has the same FNV-1a hash on every compiler and CPU") {
    // The golden: a literal computed on ARM (macOS); CI (MSVC, x86 GCC) is the first check anywhere else. The candidates, the draws
    // and the quantised numbers are IEEE double operations, so a change of this value means a platform differs (or the generator
    // changed on purpose: then say why).
    Project p;
    p.field("g1", R"({"meshes":[{"mesh":"assets/models/a.glb","weight":2},{"mesh":"assets/models/b.glb","weight":1}],
                      "density":0.7,"seed":12345,"scaleRange":[0.8,1.4],"minSpacing":0.9,"alignToNormal":0.5})");
    p.ok("terrain.sculpt", R"({"entity":"g","tool":"raise","center":[8,-6],"radius":18,"amount":6,"strength":1})");
    Json r = p.ok("foliage.scatter", R"({"entity":"g1"})");
    const auto b = p.bytes(r["file"].get<std::string>());
    std::uint64_t h = 1469598103934665603ull;  // FNV-1a, 64 bits
    for (std::uint8_t byte : b) {
        h ^= byte;
        h *= 1099511628211ull;
    }
    INFO("instances " << r["instances"].dump() << ", bytes " << b.size() << ", hash " << h);
    CHECK(h == 4368253582388478046ull);
}

TEST_CASE("foliage.scatter: a Foliage under a transformed parent stores local positions that land on the ground") {
    Project p;
    p.ok("scene.spawn", R"({"id":"par","components":{"Transform":{"position":[10,2,5]}}})");
    p.ok("scene.spawn", R"({"id":"kid","parent":"par","components":{"Foliage":{},"ScatterRule":{"terrain":"g",
         "meshes":[{"mesh":"assets/models/pine.glb"}],"density":0.5,"seed":4}}})");
    Json r = p.ok("foliage.scatter", R"({"entity":"kid"})");
    REQUIRE(r["instances"].get<int>() > 300);
    const float y = p.ground();
    for (const FoliageInstance& in : p.load("kid")) {
        CHECK(in.position.x + 10.0f >= -32.001f);  // the world position is inside the terrain
        CHECK(in.position.x + 10.0f <= 32.001f);
        CHECK(in.position.z + 5.0f >= -32.001f);
        CHECK(in.position.z + 5.0f <= 32.001f);
        CHECK(in.position.y + 2.0f == doctest::Approx(y).epsilon(1e-3));  // local y = ground - the parent's height
    }
    // a brush at a WORLD position finds the instances through the parent transform
    Json pt = p.ok("foliage.paint", R"({"entity":"kid","center":[0,0],"radius":3,"density":2,"seed":3})");
    CHECK(pt["added"].get<int>() > 10);
    const auto all = p.load("kid");
    int nearCount = 0;
    for (const FoliageInstance& in : all)
        if (std::hypot(in.position.x + 10.0f, in.position.z + 5.0f) <= 3.001f) ++nearCount;
    CHECK(nearCount >= pt["added"].get<int>());
    Json rm = p.ok("foliage.paint", R"({"entity":"kid","mode":"remove","center":[0,0],"radius":3})");
    CHECK(rm["removed"].get<int>() == nearCount);
}

TEST_CASE("foliage.scatter: alignToNormal leans the instances away from the slope, slopeRange keeps the flat ground") {
    Project p;
    p.ok("terrain.sculpt", R"({"entity":"g","tool":"raise","center":[0,0],"radius":20,"amount":12,"strength":1})");
    p.field("lean", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"alignToNormal":1,"seed":2})");
    p.ok("foliage.scatter", R"({"entity":"lean"})");
    int leaning = 0;
    for (const FoliageInstance& in : p.load("lean")) {
        CHECK(in.up.y > 0.0f);
        CHECK(in.up.x * in.up.x + in.up.y * in.up.y + in.up.z * in.up.z == doctest::Approx(1.0f).epsilon(0.02));
        const float r = std::hypot(in.position.x, in.position.z);
        if (r > 6.0f && r < 18.0f) {  // on the hill's flank: the up axis points outwards, away from the centre
            CHECK(in.up.x * in.position.x + in.up.z * in.position.z > 0.0f);
            if (in.up.y < 0.97f) ++leaning;
        }
    }
    CHECK(leaning > 20);
    // half-lean tilts less than a full lean
    p.field("half", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"alignToNormal":0.5,"seed":2})");
    p.ok("foliage.scatter", R"({"entity":"half"})");
    float minFull = 1.0f, minHalf = 1.0f;
    for (const FoliageInstance& in : p.load("lean")) minFull = std::min(minFull, in.up.y);
    for (const FoliageInstance& in : p.load("half")) minHalf = std::min(minHalf, in.up.y);
    CHECK(minHalf > minFull);
    // slopeRange: only the steep flank, then only the flat ground
    p.field("steep", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"slopeRange":[10,90],"seed":2})");
    Json steep = p.ok("foliage.scatter", R"({"entity":"steep"})");
    p.field("flat", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"slopeRange":[0,10],"seed":2})");
    Json flat = p.ok("foliage.scatter", R"({"entity":"flat"})");
    CHECK(steep["instances"].get<int>() > 100);
    CHECK(flat["instances"].get<int>() > 100);
    for (const FoliageInstance& in : p.load("steep")) CHECK(std::hypot(in.position.x, in.position.z) < 21.0f);
    for (const FoliageInstance& in : p.load("flat")) CHECK(std::hypot(in.position.x, in.position.z) > 0.0f);
}

TEST_CASE("foliage.scatter: `rule` takes the ScatterRule from another entity, and a layerMask picks any layer") {
    Project p;
    p.ok("scene.spawn", R"({"id":"recipe","components":{"ScatterRule":{"terrain":"g","density":0.5,"seed":9,
         "meshes":[{"mesh":"assets/models/a.glb","weight":1}]}}})");
    p.ok("scene.spawn", R"({"id":"plain","components":{"Foliage":{}}})");
    Json r = p.ok("foliage.scatter", R"({"entity":"plain","rule":"recipe"})");
    CHECK(r["rule"] == "recipe");
    CHECK(r["instances"].get<int>() > 500);
    CHECK(p.e.world().get<Foliage>(p.e.world().find("plain"))->meshes == Json::array({"assets/models/a.glb"}));
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"plain","rule":"plain"})"), "ScatterRule"));
    // three layers: layer 1 painted around (20, 20), layer 2 around (-20, -20)
    p.ok("scene.set_component",
         R"({"id":"g","component":"Terrain","fields":{"layers":[{"tileSize":4},{"tileSize":4},{"tileSize":4}]}})");
    p.ok("terrain.paint", R"({"entity":"g","layer":1,"center":[20,20],"radius":8,"strength":1})");
    p.ok("terrain.paint", R"({"entity":"g","layer":2,"center":[-20,-20],"radius":8,"strength":1})");
    auto around = [&](const char* id, const char* mask, int expectAt) {
        p.field(id,
                std::string(R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"layerMask":)") + mask + "}");
        Json s = p.ok("foliage.scatter", std::string(R"({"entity":")") + id + R"("})");
        CHECK(s["instances"].get<int>() > 30);
        int a = 0, b = 0, other = 0;
        for (const FoliageInstance& in : p.load(id)) {
            if (std::hypot(in.position.x - 20.0f, in.position.z - 20.0f) < 9.0f)
                ++a;
            else if (std::hypot(in.position.x + 20.0f, in.position.z + 20.0f) < 9.0f)
                ++b;
            else
                ++other;
        }
        CHECK(other == 0);
        if (expectAt == 2) {
            CHECK(a == 0);
            CHECK(b > 30);
        } else if (expectAt == 3) {
            CHECK(a > 30);
            CHECK(b > 30);
        }
    };
    around("only2", "4", 2);  // layer 2 only
    around("both", "6", 3);   // layers 1 and 2
}

TEST_CASE("foliage.scatter: with no scene the file goes to assets/foliage/") {
    Project p(false);
    p.field("meadow", kOne);
    Json r = p.ok("foliage.scatter", R"({"entity":"meadow"})");
    CHECK(r["file"] == "assets/foliage/meadow.foliage");
    CHECK(fs::exists("assets/foliage/meadow.foliage"));
}

TEST_CASE("foliage.paint: the errors point at the argument, a rule's density 0 teaches, remove needs no ground") {
    Project p;
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":0.5,"seed":1})");
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"f","center":["x",0],"radius":1})"), "/center/0"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"f","center":[0,1e9],"radius":1})"), "/center/1"));
    p.ok("foliage.scatter", R"({"entity":"f"})");
    // a rule with density 0 and no `density` argument: a teaching error, not a silent "outside"
    p.ok("scene.set_component", R"({"id":"f","component":"ScatterRule","fields":{"density":0}})");
    const std::string e = p.refused("foliage.paint", R"({"entity":"f","center":[0,0],"radius":3})");
    CHECK(contains(e, "/density"));
    CHECK(contains(e, "above 0"));
    // ...which a `density` of the call sidesteps
    CHECK(p.call("foliage.paint", R"({"entity":"f","center":[0,0],"radius":3,"density":1})").ok);
    // remove: no Terrain and no ground needed
    p.ok("scene.destroy", R"({"id":"g"})");
    CHECK_FALSE(p.call("foliage.paint", R"({"entity":"f","center":[0,0],"radius":3,"density":1,"seed":5})").ok);
    Json rm = p.ok("foliage.paint", R"({"entity":"f","mode":"remove","center":[0,0],"radius":3})");
    CHECK(rm["removed"].get<int>() > 5);
}

TEST_CASE("foliage.undo and foliage.redo: every edit is a step, byte for byte") {
    Project p;
    p.field("f", kOne);
    Json s = p.ok("foliage.scatter", R"({"entity":"f"})");
    const std::string file = s["file"].get<std::string>();
    CHECK(s["undo"] == Json::parse(R"({"command":"foliage.undo","args":{"entity":"f"}})"));
    CHECK(s["undoDepth"] == 1);
    CHECK(s["redoDepth"] == 0);
    CHECK(s.dump().size() < 1500);  // the result is small however big the file is
    const auto scattered = p.bytes(file);
    CHECK(contains(p.refused("foliage.redo", R"({"entity":"f"})"), "nothing_to_redo"));
    Json c = p.ok("foliage.clear", R"({"entity":"f","region":[-32,-32,0,0]})");
    const auto cleared = p.bytes(file);
    CHECK(cleared != scattered);
    Json u = p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(u["undone"] == "foliage.clear");
    CHECK(u["redoDepth"] == 1);
    CHECK(p.bytes(file) == scattered);
    Json rd = p.ok("foliage.redo", R"({"entity":"f"})");
    CHECK(rd["redone"] == "foliage.clear");
    CHECK(p.bytes(file) == cleared);
    // paint, then undo it, then a new edit clears the redo list
    Json pt = p.ok("foliage.paint", R"({"entity":"f","center":[10,10],"radius":4,"density":3})");
    CHECK(pt["added"].get<int>() > 20);
    CHECK(pt["undoDepth"] == 3);
    const auto painted = p.bytes(file);
    p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(p.bytes(file) == cleared);
    p.ok("foliage.redo", R"({"entity":"f"})");
    CHECK(p.bytes(file) == painted);
    p.ok("foliage.undo", R"({"entity":"f"})");
    p.ok("foliage.clear", R"({"entity":"f","region":[0,0,5,5]})");
    CHECK(contains(p.refused("foliage.redo", R"({"entity":"f"})"), "nothing_to_redo"));
    // back to the beginning: the file is gone and the field is empty again
    p.ok("foliage.undo", R"({"entity":"f"})");
    p.ok("foliage.undo", R"({"entity":"f"})");
    Json last = p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(last["deleted"] == true);
    CHECK_FALSE(fs::exists(file));
    const Foliage* f = p.e.world().get<Foliage>(p.e.world().find("f"));
    CHECK(f->instances.empty());
    CHECK(f->meshes == Json::array({"cube"}));
    CHECK(contains(p.refused("foliage.undo", R"({"entity":"f"})"), "nothing_to_undo"));
    // and all the way forward again, to the scatter
    p.ok("foliage.redo", R"({"entity":"f"})");
    CHECK(p.bytes(file) == scattered);
    CHECK(f->meshes == Json::array({"assets/models/pine.glb"}));
    // scattering over a filled file is one step too: the undo brings the old file back
    p.ok("scene.set_component", R"({"id":"f","component":"ScatterRule","fields":{"seed":99}})");
    p.ok("foliage.scatter", R"({"entity":"f"})");
    CHECK(p.bytes(file) != scattered);
    p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(p.bytes(file) == scattered);
}

TEST_CASE("foliage.paint: continueStroke makes the stamps of one stroke ONE undo step") {
    Project p;
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    p.ok("foliage.scatter", R"({"entity":"f"})");
    p.ok("foliage.clear", R"({"entity":"f"})");
    const std::string file = p.e.world().get<Foliage>(p.e.world().find("f"))->instances;
    const auto empty = p.bytes(file);
    Json a = p.ok("foliage.paint", R"({"entity":"f","center":[0,0],"radius":4,"density":2})");
    CHECK(a["undoDepth"] == 3);
    Json b = p.ok("foliage.paint", R"({"entity":"f","center":[3,0],"radius":4,"density":2,"continueStroke":true})");
    Json c = p.ok("foliage.paint", R"({"entity":"f","center":[6,0],"radius":4,"density":2,"continueStroke":true})");
    CHECK(b["continued"] == true);
    CHECK(c["undoDepth"] == 3);  // no new step
    const std::size_t n = p.load("f").size();
    CHECK(n == a["added"].get<std::size_t>() + b["added"].get<std::size_t>() + c["added"].get<std::size_t>());
    const auto stroked = p.bytes(file);
    // a remove stamp continues a paint stroke too (the eraser of a brush that paints and erases)
    Json d = p.ok("foliage.paint", R"({"entity":"f","mode":"remove","center":[2,0],"radius":2,"continueStroke":true})");
    CHECK(d["removed"].get<int>() > 3);
    CHECK(d["undoDepth"] == 3);
    const auto erased = p.bytes(file);
    Json e =
        p.ok("foliage.paint", R"({"entity":"f","center":[2,0],"radius":3,"density":3,"seed":8,"continueStroke":true})");
    CHECK(e["undoDepth"] == 3);
    // one undo takes the whole stroke back
    p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(p.bytes(file) == empty);
    p.ok("foliage.redo", R"({"entity":"f"})");
    CHECK(p.load("f").size() == n - d["removed"].get<std::size_t>() + e["added"].get<std::size_t>());
    // continueStroke after an undo, after another command, or with nothing before it is refused (the history stays)
    p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"f","center":[0,0],"radius":4,"continueStroke":true})"),
                   "/continueStroke"));
    p.ok("foliage.redo", R"({"entity":"f"})");
    p.ok("foliage.clear", R"({"entity":"f","region":[100,100,101,101]})");  // nothing in the region: no step
    p.ok("foliage.clear", R"({"entity":"f","region":[-1,-1,1,1]})");
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"f","center":[0,0],"radius":4,"continueStroke":true})"),
                   "another command"));
    (void)stroked;
    (void)erased;
}

TEST_CASE("foliage history: the budget drops the oldest steps and the result says so") {
    Project p;
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    p.ok("foliage.scatter", R"({"entity":"f"})");
    p.ok("foliage.clear", R"({"entity":"f"})");  // 2 steps
    int dropped = 0;
    Json last;
    for (int i = 0; i < 70; ++i) {
        last = p.ok("foliage.paint", "{\"entity\":\"f\",\"center\":[" + std::to_string(-28 + (i % 14) * 4) + "," +
                                         std::to_string(-28 + (i / 14) * 4) + "],\"radius\":1.5,\"density\":2}");
        if (last.contains("historyDropped")) dropped += last["historyDropped"].get<int>();
        if (i < 61) CHECK_FALSE(last.contains("historyDropped"));
    }
    CHECK(dropped == 72 - 64);
    CHECK(contains(last["historyNote"].get<std::string>(), "64"));
    CHECK(last["undoDepth"] == 64);
    // 64 undos work, the 65th has nothing left
    for (int i = 0; i < 64; ++i) REQUIRE(p.call("foliage.undo", R"({"entity":"f"})").ok);
    CHECK(contains(p.refused("foliage.undo", R"({"entity":"f"})"), "nothing_to_undo"));
}

TEST_CASE("foliage history: a change outside the foliage commands clears it instead of applying it to other bytes") {
    Project p;
    p.field("f", kOne);
    Json s = p.ok("foliage.scatter", R"({"entity":"f"})");
    p.ok("foliage.clear", R"({"entity":"f","region":[-32,-32,0,0]})");
    const std::string file = s["file"].get<std::string>();
    // the file is rewritten behind the history's back
    const auto bytes = p.bytes(file);
    std::vector<std::uint8_t> other(bytes.begin(), bytes.begin() + 16 + 26 * 3);
    other[8] = 3;
    other[9] = other[10] = other[11] = 0;
    REQUIRE(fs::write_bytes(file, other.data(), other.size()).ok());
    const std::string e = p.refused("foliage.undo", R"({"entity":"f"})");
    CHECK(contains(e, "stale_history"));
    CHECK(p.bytes(file) == other);  // nothing was changed
    CHECK(contains(p.refused("foliage.undo", R"({"entity":"f"})"), "nothing_to_undo"));
    // the next edit starts a fresh history and says that the old one went
    Json c = p.ok("foliage.clear", R"({"entity":"f"})");
    CHECK(c["undoDepth"] == 1);
    p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(p.bytes(file) == other);
    // a damaged file cannot be undone to, but a scatter replaces it (with no undo step)
    const std::uint8_t junk[5] = {1, 2, 3, 4, 5};
    REQUIRE(fs::write_bytes(file, junk, 5).ok());
    Json again = p.ok("foliage.scatter", R"({"entity":"f"})");
    CHECK_FALSE(again.contains("undo"));
    CHECK(again.contains("historyReset"));
    CHECK(again["undoDepth"] == 0);
}

TEST_CASE("foliage commands: registered as real commands in the world category") {
    Project p;
    for (const char* n : {"foliage.scatter", "foliage.paint", "foliage.clear", "foliage.undo", "foliage.redo"}) {
        const CommandInfo* info = p.e.commands().info(n);
        REQUIRE(info != nullptr);
        CHECK(info->category == "world");
        CHECK_FALSE(info->readOnly);
        CHECK(info->description.find("Not built") == std::string::npos);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->description.size() < 1500);
    }
    CHECK(p.e.commands().info("foliage.restore") == nullptr);
}

TEST_CASE("foliage.paint: points is one call with the same placements as the stamps one by one") {
    Project p;
    p.field("a", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    p.field("b", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    p.ok("foliage.scatter", R"({"entity":"a"})");
    p.ok("foliage.scatter", R"({"entity":"b"})");
    p.ok("foliage.clear", R"({"entity":"a"})");
    p.ok("foliage.clear", R"({"entity":"b"})");
    const Json one =
        p.ok("foliage.paint", R"({"entity":"a","points":[[0,0],[2,0],[4,0],[6,1]],"radius":3,"density":2,"seed":5})");
    CHECK(one["undoDepth"] == 3);  // scatter, clear and ONE stroke
    for (const char* c : {"[0,0]", "[2,0]", "[4,0]", "[6,1]"})
        p.ok("foliage.paint", std::string(R"({"entity":"b","center":)") + c +
                                  R"(,"radius":3,"density":2,"seed":5,"continueStroke":)" +
                                  (std::string(c) == "[0,0]" ? "false" : "true") + "}");
    const auto a = p.load("a"), b = p.load("b");
    REQUIRE(a.size() == b.size());
    CHECK(a.size() == one["added"].get<std::size_t>());
    for (std::size_t i = 0; i < a.size(); ++i) {
        CHECK(a[i].position.x == b[i].position.x);
        CHECK(a[i].position.z == b[i].position.z);
    }
    // remove with points takes the instances of every circle
    const Json rm = p.ok("foliage.paint", R"({"entity":"a","mode":"remove","points":[[0,0],[6,1]],"radius":3})");
    CHECK(rm["removed"].get<int>() > 5);
    CHECK(p.load("a").size() == a.size() - rm["removed"].get<std::size_t>());
    p.ok("foliage.undo", R"({"entity":"a"})");
    CHECK(p.load("a").size() == a.size());
    // the arguments say what is wrong, with a pointer
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"a","center":[0,0],"points":[[0,0]],"radius":3})"),
                   "/points"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"a","points":[],"radius":3})"), "/points"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"a","points":[[0,0],[1]],"radius":3})"), "/points/1"));
    CHECK(contains(p.refused("foliage.paint", R"({"entity":"a","radius":3})"), "/center"));
}

TEST_CASE("foliage.scatter and foliage.clear refuse continueStroke, the history of a destroyed entity is dropped") {
    Project p;
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    CHECK(contains(p.refused("foliage.scatter", R"({"entity":"f","continueStroke":true})"), "/continueStroke"));
    p.ok("foliage.scatter", R"({"entity":"f"})");
    CHECK(contains(p.refused("foliage.clear", R"({"entity":"f","continueStroke":true})"), "/continueStroke"));
    CHECK(p.ok("foliage.clear", R"({"entity":"f"})")["undoDepth"] == 2);
    // the entity goes and another one makes the next call: the history of the first one is gone, not kept for ever
    p.ok("scene.destroy", R"({"id":"f"})");
    p.field("other", kOne);
    p.ok("foliage.scatter", R"({"entity":"other"})");
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    CHECK(contains(p.refused("foliage.undo", R"({"entity":"f"})"), "nothing_to_undo"));
}

TEST_CASE("foliage commands report historyId and historyLost so the editor can number its undo rows") {
    Project p;
    p.field("f", R"({"meshes":[{"mesh":"assets/models/a.glb"}],"density":1,"seed":2})");
    p.field("h", kOne);
    const Json first = p.ok("foliage.paint", R"({"entity":"f","center":[0,0],"radius":2,"density":1})");
    const Json other = p.ok("foliage.paint", R"({"entity":"h","center":[0,0],"radius":2,"density":1})");
    CHECK(first["historyId"].get<int>() > 0);
    CHECK(first["historyId"] != other["historyId"]);
    CHECK(first["historyLost"] == 0);
    Json last = first;
    for (int i = 1; i < static_cast<int>(kFoliageHistorySteps) + 2; ++i)
        last = p.ok("foliage.paint", "{\"entity\":\"f\",\"center\":[" + std::to_string(-30 + 2 * (i % 30)) + "," +
                                         std::to_string(-20 + 6 * (i / 30)) + "],\"radius\":1.5,\"density\":3}");
    CHECK(last["historyId"] == first["historyId"]);
    CHECK(last["undoDepth"].get<std::size_t>() == kFoliageHistorySteps);
    CHECK(last["historyLost"] == 2);  // 66 steps made, the 64 newest kept: the newest is number lost + depth = 66
    CHECK(last["historyDropped"] == 1);
    const Json undone = p.ok("foliage.undo", R"({"entity":"f"})");
    CHECK(undone["historyLost"] == 2);
    CHECK(undone["historyId"] == first["historyId"]);
}
