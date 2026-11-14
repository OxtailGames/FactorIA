// Component views from scripts (M94.3b): one view per (entity, component type) is kept on the entity's JS object, the
// field's index is fixed once per type, and the view stays a handle, so removing the component, destroying the entity
// or loading another scene gives the teaching errors and never memory that is gone.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
std::string eval_err(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(!r.ok(), code);
    return r.error().to_string();
}
bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

const char* kScene = R"({"format":"factoria.scene/1","entities":[
  {"id":"a","components":{"Transform":{"position":[1,2,0]},"Sprite":{"layer":4}}},
  {"id":"b","components":{"Transform":{"position":[5,6,0]},"Sprite":{"layer":9}}}]})";

struct Rig {
    TestHost h;
    explicit Rig(const char* tag) : h(tag) {
        h.file("scenes/main.scene.json", kScene);
        REQUIRE(h.start());
        REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
        h.step_frames(1);
    }
};
}  // namespace

TEST_CASE("component views: the same entity and type give the same view, other entities and types do not") {
    Rig r("views_identity");
    CHECK(eval_ok(r.h, "var a = world.find('a'); a.get('Sprite') === a.get('Sprite')").get<bool>());
    CHECK(eval_ok(r.h, "var a = world.find('a'); a.transform === a.get('Transform')").get<bool>());
    CHECK(
        eval_ok(r.h, "var a = world.find('a'), b = world.find('b'); a.get('Sprite') !== b.get('Sprite')").get<bool>());
    CHECK(eval_ok(r.h, "var a = world.find('a'); a.get('Sprite') !== a.get('Transform')").get<bool>());
    CHECK(eval_ok(r.h, "var a = world.find('a'); a.get('Sprite') === a.add('Sprite')").get<bool>());
    CHECK(eval_ok(r.h, "var a = world.find('a'); a.position === a.position").get<bool>());
    CHECK(eval_ok(r.h, "var a = world.find('a'); a.get('Sprite').$type").get<std::string>() == "Sprite");
    CHECK(has(eval_err(r.h, "world.find('a').get('Sprite').$type = 'x'"), "read-only"));
}

TEST_CASE("component views: reads and writes go to the engine's memory, through a kept view too") {
    Rig r("views_live");
    eval_ok(r.h, "globalThis.s = world.find('a').get('Sprite'); globalThis.p = world.find('a').position; 1");
    CHECK(eval_ok(r.h, "s.layer").get<int>() == 4);
    CHECK(eval_ok(r.h, "p.x").get<double>() == 1.0);
    // the engine changes the fields behind the view's back
    Entity a = r.h.w.find_by_id("a");
    r.h.w.get<Sprite>(a)->layer = 11;
    r.h.w.get<Transform>(a)->position.x = 7;
    CHECK(eval_ok(r.h, "s.layer").get<int>() == 11);
    CHECK(eval_ok(r.h, "p.x").get<double>() == 7.0);
    // the script writes through the kept views
    eval_ok(r.h, "s.layer = 3; p.x = 9; 1");
    CHECK(r.h.w.get<Sprite>(a)->layer == 3);
    CHECK(r.h.w.get<Transform>(a)->position.x == 9.0f);
    // a new vector replaces the field, the cached field view shows it
    eval_ok(r.h, "world.find('a').position = vec3(2, 3, 4); 1");
    CHECK(eval_ok(r.h, "p.y").get<double>() == 3.0);
    CHECK(eval_ok(r.h, "JSON.stringify(world.find('a').get('Sprite').toJSON().layer)").get<std::string>() == "3");
}

TEST_CASE("component views: removing the component and adding it again") {
    Rig r("views_remove");
    eval_ok(r.h, "globalThis.a = world.find('a'); globalThis.s = a.get('Sprite'); 1");
    CHECK(eval_ok(r.h, "a.remove('Sprite')").get<bool>());
    CHECK(eval_ok(r.h, "a.get('Sprite') === null").get<bool>());
    const std::string text = eval_err(r.h, "s.layer");
    MESSAGE(text);
    CHECK(has(text, "has no Sprite component"));
    CHECK(has(eval_err(r.h, "s.layer = 2"), "has no Sprite component"));
    // adding it again: the kept view is valid again and is the one entity.get returns
    eval_ok(r.h, "a.add('Sprite', { layer: 21 }); 1");
    CHECK(eval_ok(r.h, "a.get('Sprite') === s").get<bool>());
    CHECK(eval_ok(r.h, "s.layer").get<int>() == 21);
    // entity.set returns the view too
    CHECK(eval_ok(r.h, "a.set('Sprite', { layer: 5 }) === s && s.layer === 5").get<bool>());
}

TEST_CASE("component views: a view of a destroyed entity says so, and the cache does not hold the entity") {
    Rig r("views_destroy");
    eval_ok(r.h,
            "globalThis.b = world.find('b'); globalThis.sb = b.get('Sprite'); globalThis.pb = b.position; b.hp = 3; 1");
    // the game's own field is listed; the private $h and $v are not (Object.keys, spread, the members of a 'did you mean')
    CHECK(eval_ok(r.h, "JSON.stringify(Object.keys(b))").get<std::string>() == "[\"hp\"]");
    CHECK(eval_ok(r.h, "Object.keys({ ...b }).join()").get<std::string>() == "hp");
    const std::string miss = eval_err(r.h, "b.nope");
    CHECK(has(miss, "Its members: hp,"));
    CHECK_FALSE(has(miss, "$"));
    const Entity bOld = r.h.w.find_by_id("b");
    eval_ok(r.h, "b.destroy(); 1");
    r.h.step_frames(1);
    for (const char* code : {"sb.layer", "pb.x", "sb.layer = 1", "pb.x = 1", "b.get('Sprite')"}) {
        const std::string text = eval_err(r.h, code);
        MESSAGE(text);
        CHECK(has(text, "destroyed"));
    }
    CHECK(eval_ok(r.h, "world.find('b') === null").get<bool>());
    // a new entity may reuse the slot: it gets its own views and the old ones stay dead
    eval_ok(r.h, "globalThis.n = world.spawn({ id: 'n', components: { Transform: {}, Sprite: { layer: 8 } } }); 1");
    r.h.step_frames(1);
    CHECK(eval_ok(r.h, "n.get('Sprite').layer").get<int>() == 8);
    // it did reuse the slot (a new generation), and the new entity is a new JS object: nothing of b's fields is on it
    const Entity nNew = r.h.w.find_by_id("n");
    CHECK(nNew.index == bOld.index);
    CHECK(nNew.generation != bOld.generation);
    CHECK(eval_ok(r.h, "n !== b && !('hp' in n) && Object.keys(n).length === 0").get<bool>());
    CHECK(has(eval_err(r.h, "sb.layer"), "destroyed"));
}

TEST_CASE("component views: many entities spawned, read and destroyed leave nothing behind") {
    Rig r("views_many");
    CHECK(eval_ok(r.h, R"(
var sum = 0;
for (let round = 0; round < 5; round++) {
  const list = [];
  for (let i = 0; i < 100; i++) list.push(world.spawn({ components: { Transform: {}, Sprite: { layer: i } } }));
  for (const e of list) { sum += e.get('Sprite').layer; e.position.x = 1; }
  for (const e of list) e.destroy();
}
sum)")
              .get<int>() == 5 * 4950);
    r.h.step_frames(1);
    // the same after loading the scene again: views of the old scene's entities are dead, new ones work
    eval_ok(r.h, "globalThis.old = world.find('a').get('Sprite'); 1");
    REQUIRE(r.h.load_scene_now("scenes/main.scene.json").empty());
    r.h.step_frames(1);
    CHECK(has(eval_err(r.h, "old.layer"), "destroyed"));
    CHECK(eval_ok(r.h, "world.find('a').get('Sprite').layer").get<int>() == 4);
}

TEST_CASE("component views: a field that does not exist still says 'did you mean', values are still checked") {
    Rig r("views_errors");
    eval_ok(r.h, "globalThis.s = world.find('a').get('Sprite'); 1");
    const std::string read = eval_err(r.h, "s.layr");
    MESSAGE(read);
    CHECK(has(read, "Sprite has no field 'layr'"));
    CHECK(has(read, "Did you mean 'layer'?"));
    CHECK(has(read, "Fields:"));
    const std::string write = eval_err(r.h, "s.layr = 3");
    CHECK(has(write, "Sprite has no field 'layr'"));
    CHECK(has(write, "Did you mean 'layer'?"));
    CHECK(has(eval_err(r.h, "s.$x = 3"), "Sprite has no field"));
    CHECK(eval_ok(r.h, "s.nothing_like_a_field_zzzzzz === undefined").get<bool>());
    CHECK(eval_ok(r.h, "s.then === undefined").get<bool>());
    // the checks of the field's kind
    CHECK(has(eval_err(r.h, "s.layer = 'x'"), "Sprite.layer expects an integer"));
    CHECK(has(eval_err(r.h, "s.flipX = 1; s.color = 'nope'"), "color"));
    CHECK(has(eval_err(r.h, "s.blend = 'Additiv'"), "Did you mean"));
    CHECK(eval_ok(r.h, "s.blend = 'Additive'; s.blend").get<std::string>() == "additive");
    // the view lists its fields like a plain object, the private members are hidden
    CHECK(eval_ok(r.h, "Object.keys(s).includes('layer') && Object.keys(s).includes('color')").get<bool>());
    CHECK(eval_ok(r.h, "!Object.keys(s).some((k) => k.startsWith('$'))").get<bool>());
    CHECK(eval_ok(r.h, "'layer' in s && !('layr' in s)").get<bool>());
    CHECK(eval_ok(r.h, "var c = { ...s }; c.layer === s.layer && Array.isArray(Object.entries(s))").get<bool>());
    CHECK(eval_ok(r.h, "JSON.parse(JSON.stringify(s)).layer").get<int>() == 4);
    CHECK(eval_ok(r.h, "String(s)").get<std::string>() == "Sprite(a)");
}

TEST_CASE("component views: Entity, Asset and Json fields and the scene settings are read and written as before") {
    TestHost h("views_kinds");
    h.file("scenes/main.scene.json",
           R"({"format":"factoria.scene/1","entities":[
  {"id":"a","components":{"Transform":{},"Sprite":{}}},
  {"id":"b","components":{"Transform":{},"Script":{"path":"x.js","props":{"k":2}}}}]})");
    REQUIRE(h.start());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    CHECK(eval_ok(h, "var t = world.find('b').get('Script'); t.props.k").get<int>() == 2);
    eval_ok(h, "world.find('b').get('Script').props = { k: 3, z: [1, 2] }; 1");
    CHECK(eval_ok(h, "world.find('b').get('Script').props.z.length").get<int>() == 2);
    eval_ok(h, "world.find('a').get('Sprite').texture = 'tex/a.png'; 1");
    CHECK(eval_ok(h, "world.find('a').get('Sprite').texture").get<std::string>() == "tex/a.png");
    CHECK(eval_ok(h, "world.find('a').get('Sprite').color instanceof Color").get<bool>());
    CHECK(eval_ok(h, "var c = world.find('a').get('Sprite').color; c.a = 0.5; world.find('a').get('Sprite').color.a")
              .get<double>() == 0.5);
}

TEST_CASE("script bridge: writing a name or a tag keeps the hierarchy cache, writing a position drops it") {
    Rig r("views_labels");
    const Entity a = r.h.w.find_by_id("a");
    const World& cw = r.h.w;
    (void)cw.world_matrix(a);  // fills the cache
    const std::uint64_t before = cw.hierarchy_version();
    eval_ok(r.h, R"(const a = world.find('a');
a.name = 'renamed'; a.addTag('t1'); a.addTag('t2'); a.removeTag('t1'); a.tags = ['x', 'y'];
a.set('EntityInfo', { tags: ['z'] }); 1)");
    CHECK(cw.hierarchy_version() == before);
    CHECK(cw.info(a).name == "renamed");
    CHECK(cw.info(a).tags == std::vector<std::string>{"z"});
    eval_ok(r.h, "world.find('a').position.x = 3; 1");
    CHECK(cw.hierarchy_version() > before);
    CHECK(cw.world_matrix(a).translation().x == 3.0f);
    // a vector field set from a script is written, and the cache sees it
    eval_ok(r.h, "world.find('a').position = vec3(4, 5, 6); 1");
    CHECK(cw.world_position(a).y == 5.0f);
}
