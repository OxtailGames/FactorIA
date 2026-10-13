#include <doctest.h>

#include "fa/core/reflect.h"

using namespace fa;

namespace {
enum class Mode : std::int32_t { Idle, Walk, Run };
struct Probe {
    float speed = 5.0f;
    int lives = 3;
    bool alive = true;
    std::string label = "probe";
    std::string icon;
    Vec2 pivot{0.5f, 0.5f};
    Vec3 pos{0, 0, 0};
    Vec4 v4{0, 0, 0, 0};
    Color tint{1, 1, 1, 1};
    Rect region{0, 0, 0, 0};
    Mode mode = Mode::Idle;
    Entity target;
    Json extra = Json::object();
    float timer = 0.0f;
    float locked = 1.0f;
};

const TypeInfo& probe_type() {
    static const TypeInfo* t = [] {
        auto& reg = TypeRegistry::global();
        if (!reg.of<Probe>()) {
            reg.add<Probe>("ProbeTest", "A test component.", "Test")
                .field("speed", &Probe::speed, "Speed in units/s.").range(0, 10)
                .field("lives", &Probe::lives, "Lives left.").range(0, 9)
                .field("alive", &Probe::alive, "Is alive.")
                .field("label", &Probe::label, "Label text.")
                .asset_field("icon", &Probe::icon, "texture", "Icon texture.")
                .field("pivot", &Probe::pivot, "Pivot.")
                .field("pos", &Probe::pos, "Position.")
                .field("v4", &Probe::v4, "Vec4.")
                .field("tint", &Probe::tint, "Tint.")
                .field("region", &Probe::region, "Region.")
                .enum_field("mode", &Probe::mode, {"idle", "walk", "run"}, "Movement mode.")
                .field("target", &Probe::target, "Target entity.")
                .field("extra", &Probe::extra, "Free-form data.")
                .field("timer", &Probe::timer, "Runtime timer.").runtime_only()
                .field("locked", &Probe::locked, "Engine-managed.").read_only();
        }
        return reg.of<Probe>();
    }();
    return *t;
}
}  // namespace

TEST_CASE("reflect: registry lookup and suggestions") {
    const TypeInfo& t = probe_type();
    auto& reg = TypeRegistry::global();
    CHECK(reg.find("ProbeTest") == &t);
    CHECK(reg.find("probetest") == nullptr);
    CHECK(reg.find_ci("probetest") == &t);
    CHECK(reg.get(t.id) == &t);
    CHECK(reg.id_of<Probe>() == t.id);
    CHECK(reg.suggest("ProbeTst") == "ProbeTest");
    CHECK(reg.suggest("Zzzzzzzzzz").empty());
    CHECK(t.field("speed") != nullptr);
    CHECK(t.field("nope") == nullptr);
    bool listed = false;
    for (const TypeInfo* x : reg.all()) listed |= x == &t;
    CHECK(listed);
    CHECK(reg.describe_all().is_array());
}

TEST_CASE("reflect: full round trip through JSON") {
    const TypeInfo& t = probe_type();
    Probe a;
    a.speed = 7.5f;
    a.lives = 9;
    a.alive = false;
    a.label = "hi";
    a.icon = "assets/i.png";
    a.pivot = {1, 0};
    a.pos = {1, 2, 3};
    a.v4 = {1, 2, 3, 4};
    a.tint = {0.1f, 0.2f, 0.3f, 0.4f};
    a.region = {1, 2, 3, 4};
    a.mode = Mode::Run;
    a.extra = Json::parse(R"({"k":[1,2]})");
    Json j = object_to_json(t, &a, true);
    CHECK(j["mode"] == "run");
    CHECK(j["icon"] == "assets/i.png");
    CHECK(!j.contains("timer"));  // runtime-only
    CHECK(j["speed"] == 7.5);

    Probe b;
    REQUIRE(object_patch_from_json(t, &b, j).ok());
    CHECK(b.speed == 7.5f);
    CHECK(b.lives == 9);
    CHECK(!b.alive);
    CHECK(b.label == "hi");
    CHECK(b.pos == Vec3{1, 2, 3});
    CHECK(b.tint == Color{0.1f, 0.2f, 0.3f, 0.4f});
    CHECK(b.region == Rect{1, 2, 3, 4});
    CHECK(b.mode == Mode::Run);
    CHECK(b.extra == a.extra);
}

TEST_CASE("reflect: includeDefaults=false omits default fields") {
    const TypeInfo& t = probe_type();
    Probe p;
    CHECK(object_to_json(t, &p, false).empty());
    p.lives = 4;
    p.timer = 2;
    Json j = object_to_json(t, &p, false);
    CHECK(j.size() == 1);
    CHECK(j["lives"] == 4);
    CHECK(object_to_json(t, &p, false, true).size() == 2);  // includeRuntime
}

TEST_CASE("reflect: enum parsing") {
    const TypeInfo& t = probe_type();
    Probe p;
    const FieldInfo& f = *t.field("mode");
    CHECK(field_from_json(f, &p, "Walk").ok());
    CHECK(p.mode == Mode::Walk);
    CHECK(field_from_json(f, &p, 2).ok());
    CHECK(p.mode == Mode::Run);
    auto bad = field_from_json(f, &p, "runn");
    REQUIRE(!bad.ok());
    CHECK(bad.error().hint.find("Did you mean 'run'") != std::string::npos);
    CHECK(bad.error().hint.find("idle, walk, run") != std::string::npos);
    CHECK(!field_from_json(f, &p, 7).ok());
    CHECK(!field_from_json(f, &p, true).ok());
    CHECK(p.mode == Mode::Run);
}

TEST_CASE("reflect: field errors explain themselves") {
    const TypeInfo& t = probe_type();
    Probe p;
    auto r = field_from_json(*t.field("pos"), &p, "abc");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("Field 'pos'") != std::string::npos);
    CHECK(r.error().hint.find("[x, y, z]") != std::string::npos);
    auto range = field_from_json(*t.field("speed"), &p, 50);
    REQUIRE(!range.ok());
    CHECK(range.error().message.find("range") != std::string::npos);
    CHECK(p.speed == 5.0f);
    auto ent = field_from_json(*t.field("target"), &p, "player");
    REQUIRE(!ent.ok());
    CHECK(ent.error().hint.find("fa_scene") != std::string::npos);
}

TEST_CASE("reflect: patching") {
    const TypeInfo& t = probe_type();
    Probe p;
    auto typo = object_patch_from_json(t, &p, Json::parse(R"({"spede": 3})"));
    REQUIRE(!typo.ok());
    CHECK(typo.error().message.find("Unknown field 'spede'") != std::string::npos);
    CHECK(typo.error().hint.find("Did you mean 'speed'") != std::string::npos);
    CHECK(typo.error().hint.find("Valid:") != std::string::npos);

    auto ro = object_patch_from_json(t, &p, Json::parse(R"({"locked": 3})"));
    REQUIRE(!ro.ok());
    CHECK(ro.error().message.find("read-only") != std::string::npos);

    // All-or-nothing: a bad field leaves the object unchanged.
    auto mixed = object_patch_from_json(t, &p, Json::parse(R"({"lives": 2, "speed": "fast"})"));
    CHECK(!mixed.ok());
    CHECK(p.lives == 3);

    CHECK(!object_patch_from_json(t, &p, Json::array()).ok());
    CHECK(object_patch_from_json(t, &p, Json::parse(R"({"lives": 2, "tint": "red"})")).ok());
    CHECK(p.lives == 2);
    CHECK(p.tint == Color::red());
}

TEST_CASE("reflect: schema and description") {
    const TypeInfo& t = probe_type();
    Json s = type_json_schema(t);
    CHECK(s["type"] == "object");
    CHECK(s["additionalProperties"] == false);
    CHECK(s["properties"]["mode"]["enum"].size() == 3);
    CHECK(s["properties"]["speed"]["maximum"] == 10);
    CHECK(s["properties"]["icon"]["x-assetType"] == "texture");
    CHECK(s["properties"]["lives"]["default"] == 3);
    CHECK(!s["properties"].contains("timer"));
    CHECK(s["properties"]["speed"]["description"] == "Speed in units/s.");

    Json d = type_describe(t);
    CHECK(d["name"] == "ProbeTest");
    CHECK(d["category"] == "Test");
    bool sawMode = false, sawTimer = false;
    for (const Json& f : d["fields"]) {
        if (f["name"] == "mode") {
            sawMode = true;
            CHECK(f["kind"] == "enum");
            CHECK(f["default"] == "idle");
            CHECK(f["enum"].size() == 3);
        }
        if (f["name"] == "timer") {
            sawTimer = true;
            CHECK(f["runtimeOnly"] == true);
        }
        if (f["name"] == "icon") CHECK(f["assetType"] == "texture");
    }
    CHECK(sawMode);
    CHECK(sawTimer);
}
