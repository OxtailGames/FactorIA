// M75-P6b: foliage.scatter, foliage.paint, foliage.clear and foliage.restore (tools/authoring/src/foliage_commands.cpp): a
// deterministic scatter over a terrain, every rejection rule, the mesh weights, the spacing, the 2M cap, paint, clear, undo, redo
// and the errors that teach.
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
    Project() {
        authoring::install();
        dir = fs::make_temp_dir("fa_foliage_cmd").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({"format":"factoria.project/1","name":"Foliage","id":"com.example.foliage","mainScene":"scenes/main.scene.json",
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
    CHECK(ra["file"] == "scenes/main.a.foliage");  // no scene is loaded from a file: assets/foliage/ or next to it
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
    for (const FoliageInstance& in : p.load("l")) CHECK(std::hypot(in.position.x - 20.0f, in.position.z - 20.0f) < 11.0f);
    // layer 0 is everywhere else
    p.field("m", R"({"meshes":[{"mesh":"assets/models/pine.glb"}],"density":1,"layerMask":1})");
    for (const FoliageInstance& in : p.load("l")) (void)in;
    r = p.ok("foliage.scatter", R"({"entity":"m"})");
    for (const FoliageInstance& in : p.load("m")) CHECK(std::hypot(in.position.x - 20.0f, in.position.z - 20.0f) > 3.0f);
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
    p.ok("scene.spawn", R"({"id":"loose","components":{"Foliage":{},"ScatterRule":{"meshes":[{"mesh":"assets/models/pine.glb"}]}}})");
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
    Json rm = p.ok("foliage.paint", R"({"entity":"f","mode":"remove","center":[-20,-20],"radius":4,"mesh":"assets/models/a.glb"})");
    CHECK(rm["removed"] == 0);
    rm = p.ok("foliage.paint", R"({"entity":"f","mode":"remove","center":[-20,-20],"radius":4})");
    CHECK(rm["removed"] == one["added"]);
    // errors
    const std::string e1 = p.refused("foliage.paint", R"({"entity":"f","center":[0,0],"radius":4,"mesh":"assets/models/c.glb"})");
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

TEST_CASE("foliage commands: undo and redo restore the file, the meshes and the field") {
    Project p;
    p.field("f", kOne);
    Json s = p.ok("foliage.scatter", R"({"entity":"f"})");
    const std::string file = s["file"].get<std::string>();
    const auto scattered = p.bytes(file);
    // undo of the first scatter: no file before, no instances field, the meshes of a new Foliage
    Json undo = s["undo"];
    CHECK(undo["command"] == "foliage.restore");
    Json c = p.ok("foliage.clear", R"({"entity":"f","region":[-32,-32,0,0]})");
    const auto cleared = p.bytes(file);
    CHECK(cleared != scattered);
    Json back = p.ok("foliage.restore", c["undo"]["args"].dump());
    CHECK(p.bytes(file) == scattered);
    // redo
    p.ok("foliage.restore", back["undo"]["args"].dump());
    CHECK(p.bytes(file) == cleared);
    // undo the paint, then the scatter itself: the file is gone and the field is empty again
    Json pt = p.ok("foliage.paint", R"({"entity":"f","center":[10,10],"radius":4,"density":3})");
    Json u1 = p.ok("foliage.restore", pt["undo"]["args"].dump());
    CHECK(p.bytes(file) == cleared);
    p.ok("foliage.restore", s["undo"]["args"].dump());
    CHECK_FALSE(fs::exists(file));
    const Foliage* f = p.e.world().get<Foliage>(p.e.world().find("f"));
    CHECK(f->instances.empty());
    CHECK(f->meshes == Json::array({"cube"}));
    // restore refuses what it cannot read, and changes nothing
    CHECK(contains(p.refused("foliage.restore", R"({"entity":"f","file":"x.foliage","meshes":["cube"],"data":"AAAA"})"),
                   "x.foliage"));
    CHECK_FALSE(fs::exists("x.foliage"));
}

TEST_CASE("foliage commands: registered as real commands in the world category") {
    Project p;
    for (const char* n : {"foliage.scatter", "foliage.paint", "foliage.clear", "foliage.restore"}) {
        const CommandInfo* info = p.e.commands().info(n);
        REQUIRE(info != nullptr);
        CHECK(info->category == "world");
        CHECK_FALSE(info->readOnly);
        CHECK(info->description.find("Not built") == std::string::npos);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->description.size() < 1500);
    }
}
