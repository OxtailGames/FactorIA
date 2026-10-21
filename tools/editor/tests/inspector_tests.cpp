// The Hierarchy and Inspector logic (inspector_model.h): field kind -> widget -> command arguments, the Json box, asset
// lists, a material's params and the entity tree's filter. GPU-free.
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "inspector_model.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("inspector: every field kind gets a widget, and its arity matches the JSON the command takes") {
    struct Row { FieldKind kind; FieldWidget widget; int arity; };
    const Row rows[] = {
        {FieldKind::Bool, FieldWidget::Checkbox, 0},    {FieldKind::Int, FieldWidget::DragInt, 1},
        {FieldKind::Float, FieldWidget::DragFloat, 1},  {FieldKind::String, FieldWidget::Text, 0},
        {FieldKind::Vec2, FieldWidget::Vec2, 2},        {FieldKind::Vec3, FieldWidget::Vec3, 3},
        {FieldKind::Vec4, FieldWidget::Vec4, 4},        {FieldKind::Color, FieldWidget::Color, 4},
        {FieldKind::Rect, FieldWidget::Rect, 4},        {FieldKind::Entity, FieldWidget::EntityCombo, 0},
        {FieldKind::Enum, FieldWidget::EnumCombo, 0},   {FieldKind::Asset, FieldWidget::AssetPicker, 0},
        {FieldKind::Json, FieldWidget::JsonText, 0},
    };
    for (const Row& r : rows) {
        FieldInfo f;
        f.kind = r.kind;
        INFO(field_kind_name(r.kind));
        CHECK(widget_for(f) == r.widget);
        CHECK(widget_arity(r.widget) == r.arity);
        CHECK(std::string(widget_name(r.widget)) != "?");
    }
}

TEST_CASE("inspector: the widget of every registered field is built from the field's own metadata") {
    // Nothing in the registry may fall through: runtime-only fields are hidden, the rest has a widget with a drag speed.
    World world;  // registers the built-in components
    int shown = 0, hidden = 0;
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        for (const FieldInfo& f : t->fields) {
            INFO(t->name << "." << f.name);
            CHECK_FALSE(f.doc.empty());  // the doc string is the tooltip
            if (!inspector_shows(f)) { ++hidden; continue; }
            ++shown;
            const FieldWidget w = widget_for(f);
            CHECK(std::string(widget_name(w)) != "?");
            if (w == FieldWidget::EnumCombo) CHECK_FALSE(f.enumNames.empty());
            if (w == FieldWidget::AssetPicker) CHECK_FALSE(f.assetType.empty());
            if (w == FieldWidget::DragFloat || w == FieldWidget::DragInt) CHECK(drag_speed_for(f, 5.0) > 0.0f);
        }
    }
    CHECK(shown > 100);
    CHECK(hidden > 0);
}

TEST_CASE("inspector: a ranged field drags across its range, an unbounded one by its magnitude") {
    FieldInfo ranged;
    ranged.kind = FieldKind::Float;
    ranged.minValue = 0;
    ranged.maxValue = 1;
    CHECK(field_has_range(ranged));
    CHECK(drag_speed_for(ranged, 0.5) == doctest::Approx(0.005f));
    FieldInfo free;
    free.kind = FieldKind::Float;
    CHECK_FALSE(field_has_range(free));
    CHECK(drag_speed_for(free, 0.0) == doctest::Approx(0.01f));
    CHECK(drag_speed_for(free, 1000.0) == doctest::Approx(10.0f));
    FieldInfo whole;
    whole.kind = FieldKind::Int;
    CHECK(drag_speed_for(whole, 3.0) == doctest::Approx(1.0f));
}

TEST_CASE("inspector: an edit is the same scene.set_component call the AI makes") {
    const Json a = field_edit_args("player", "Transform", "position", Json::array({1, 2, 0}));
    CHECK(a == Json::parse(R"({"id":"player","component":"Transform","fields":{"position":[1,2,0]}})"));
    CHECK_FALSE(a.contains("merge"));
    const Json m = field_edit_args("gem", "MeshRenderer", "materialParams", Json::object({{"glow", 0.5}}), true);
    CHECK(m["merge"] == true);
}

TEST_CASE("inspector: a world value round-trips through the widget's JSON, and a refused value changes nothing") {
    World w;
    Entity e = w.create("box", "Box");
    w.add<Shape2D>(e);
    const TypeInfo& shape = *TypeRegistry::global().find("Shape2D");
    const Json before = component_to_json(w, e, shape, true, false);
    // A vector field is edited as an array of numbers, a color as [r, g, b, a], an enum by its name.
    CHECK(before["size"].is_array());
    CHECK(before["color"].is_array());
    CHECK(before["shape"].is_string());
    auto ok = patch_component(w, e, shape, Json::object({{"size", Json::array({10, 20})}}));
    REQUIRE(ok.ok());
    CHECK(component_to_json(w, e, shape, true, false)["size"] == Json::array({10, 20}));
    // Out of range: the error is what the inspector shows under the field, and the value stays.
    const FieldInfo* ranged = nullptr;
    for (const FieldInfo& f : shape.fields)
        if (field_has_range(f) && f.kind == FieldKind::Float) ranged = &f;
    REQUIRE(ranged != nullptr);
    const Json current = component_to_json(w, e, shape, true, false);
    auto bad = patch_component(w, e, shape, Json::object({{ranged->name, double(ranged->maxValue) + 1000.0}}));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find(ranged->name) != std::string::npos);
    CHECK(component_to_json(w, e, shape, true, false) == current);
}

TEST_CASE("inspector: the Json box refuses invalid JSON with the parse error") {
    auto good = parse_json_box("{\n  \"a\": [1, 2]\n}\n");
    REQUIRE(good.ok());
    CHECK((*good)["a"].size() == 2);
    auto bad = parse_json_box("{\n  \"a\": [1, 2\n}");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("line") != std::string::npos);
    CHECK_FALSE(bad.error().hint.empty());
    CHECK_FALSE(parse_json_box("   ").ok());
    CHECK(parse_json_box("null").ok());
}

TEST_CASE("inspector: command errors are shown with their hint") {
    CHECK(command_error_text(Json::parse(R"({"code":"x","message":"Field 'a' is out of range.","hint":"Use 0..1."})")) ==
          "Field 'a' is out of range. Use 0..1.");
    CHECK(command_error_text(Json::parse(R"({"message":"Nope."})")) == "Nope.");
}

TEST_CASE("inspector: asset fields list the project's files of the right type") {
    CHECK(asset_file_matches("texture", "assets/Hero.PNG"));
    CHECK_FALSE(asset_file_matches("texture", "assets/hero.wav"));
    CHECK(asset_file_matches("material", "materials/water.material.json"));
    CHECK_FALSE(asset_file_matches("material", "scenes/main.scene.json"));
    CHECK(asset_file_matches("scene", "scenes/main.scene.json"));
    CHECK(asset_file_matches("any", "whatever.bin"));

    namespace stdfs = std::filesystem;
    const stdfs::path dir = fs::make_temp_dir("fa_inspector_assets");
    auto touch = [&](const char* rel) {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel) << "x";
    };
    touch("materials/b.material.json");
    touch("materials/a.material.json");
    touch("assets/hero.png");
    touch(".factoria/screenshots/s.material.json");
    touch("build/export/z.material.json");
    CHECK(list_asset_files(dir.string(), "material") == std::vector<std::string>{"materials/a.material.json", "materials/b.material.json"});
    CHECK(list_asset_files(dir.string(), "texture") == std::vector<std::string>{"assets/hero.png"});
    CHECK(list_asset_files(dir.string(), "material", 1).size() == 1);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

namespace {
const char* kInfo = R"({"material":"materials/m.material.json","params":[
  {"name":"glow","type":"color","default":[1,0.35,0,1],"doc":"Emission color."},
  {"name":"speed","type":"float","default":2.0,"min":0,"max":10,"doc":"Seconds per cycle."},
  {"name":"tint","type":"vec3","default":[1,1,1],"doc":"A vector."}]})";
}

TEST_CASE("material inspector: params are typed by material.info") {
    auto specs = material_params_from_info(Json::parse(kInfo));
    REQUIRE(specs.ok());
    REQUIRE(specs->size() == 3);
    const MaterialParamSpec& glow = (*specs)[0];
    const MaterialParamSpec& speed = (*specs)[1];
    CHECK(glow.type == "color");
    CHECK(material_param_arity(glow.type) == 4);
    CHECK_FALSE(glow.min.has_value());
    CHECK(speed.min.value() == 0);
    CHECK(speed.max.value() == 10);
    CHECK(material_param_arity("vec3") == 3);
    CHECK(material_param_arity("mat4") == 0);
    CHECK_FALSE(material_params_from_info(Json::parse(R"({"errors":[]})")).ok());

    // The shown value is the override when there is one, else the default; a reset is a null in a merge patch.
    const Json overrides = Json::parse(R"({"speed":4.5})");
    CHECK(material_param_value(speed, overrides) == 4.5);
    CHECK(material_param_overridden(speed, overrides));
    CHECK(material_param_value(glow, overrides) == Json::parse("[1,0.35,0,1]"));
    CHECK_FALSE(material_param_overridden(glow, overrides));
    CHECK_FALSE(material_param_overridden(speed, Json::object()));
    CHECK(material_param_value(speed, Json(nullptr)) == 2.0);

    const Json set = material_param_edit_args("gem", speed, 6.0);
    CHECK(set == Json::parse(R"({"id":"gem","component":"MeshRenderer","fields":{"materialParams":{"speed":6.0}},"merge":true})"));
    const Json reset = material_param_reset_args("gem", speed);
    CHECK(reset["fields"]["materialParams"]["speed"].is_null());
    CHECK(reset["merge"] == true);
}

TEST_CASE("material inspector: the build error comes from the renderer's asset report, and clears when it builds") {
    const Json broken = Json::parse(R"({"materials":[
      {"material":"materials/a.material.json","ok":true,"generation":1},
      {"material":"materials/m.material.json","ok":false,"generation":0,"error":"shaders/m.surface.glsl:3:5: unknown identifier 'colour'"}]})");
    CHECK(material_build_error(broken, "materials/m.material.json").find("m.surface.glsl:3") != std::string::npos);
    CHECK(material_build_error(broken, "./materials/m.material.json").find("glsl:3") != std::string::npos);
    CHECK(material_build_error(broken, "materials/a.material.json").empty());
    CHECK(material_build_error(broken, "").empty());
    CHECK(material_build_error(Json::object(), "materials/m.material.json").empty());
    const Json fixed = Json::parse(R"({"materials":[{"material":"materials/m.material.json","ok":true,"generation":2}]})");
    CHECK(material_build_error(fixed, "materials/m.material.json").empty());
}

TEST_CASE("hierarchy: the search box matches every word in the name or the id") {
    CHECK(tree_matches("", "Player", "player"));
    CHECK(tree_matches("pla", "Player", "e1"));
    CHECK(tree_matches("COIN", "Gold", "coin_3"));
    CHECK(tree_matches("gold 3", "Gold", "coin_3"));
    CHECK_FALSE(tree_matches("gold 4", "Gold", "coin_3"));
    CHECK(tree_label("Player", "player_1") == "Player  (player_1)");
    CHECK(tree_label("", "e7") == "e7");
    CHECK(tree_label("e7", "e7") == "e7");
}

TEST_CASE("hierarchy: Duplicate spawns the entity and its children under new ids") {
    const Json src = Json::parse(R"({"id":"squad","name":"Squad","components":{"Transform":{"position":[1,2,0]}},
      "children":[{"id":"gunner","name":"Gunner"}]})");
    const Json copy = duplicate_spec(src);
    CHECK_FALSE(copy.contains("id"));
    CHECK(copy["name"] == "Squad copy");
    CHECK_FALSE(copy["children"][0].contains("id"));
    CHECK(copy["children"][0]["name"] == "Gunner");
    CHECK(copy["components"]["Transform"]["position"][0] == 1);
    CHECK(duplicate_spec(Json::parse(R"({"id":"x"})"))["name"] == "Entity copy");
}
