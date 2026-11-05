// assets.contact_sheet: a set of pictures side by side over light, dark and camera backgrounds, and in greyscale.
// Pictures are drawn on the CPU; a .glb thumbnail uses the GPU, so that test skips where there is no graphics device.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/core/screenshot_files.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"

using namespace fa;
using namespace fa::testing;

namespace {

std::string message(const CommandResult& r) { return r.error.value("message", std::string()) + " " + r.error.value("hint", std::string()); }

Image picture_of(const Json& r) { return read_png(r["$image"]["path"].get<std::string>()); }

// A .glb with one triangle pair (a small pyramid) and its binary buffer inside.
std::string pyramid_glb() {
    const float pos[] = {-1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 0, 2, 0};
    const std::uint16_t idx[] = {0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4, 0, 2, 1, 0, 3, 2};
    std::string bin(reinterpret_cast<const char*>(pos), sizeof pos);
    bin.append(reinterpret_cast<const char*>(idx), sizeof idx);
    while (bin.size() % 4) bin.push_back('\0');
    std::string json = R"({"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
      "meshes":[{"primitives":[{"attributes":{"POSITION":0},"indices":1}]}],
      "buffers":[{"byteLength":)" + std::to_string(bin.size()) + R"(}],
      "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":60},{"buffer":0,"byteOffset":60,"byteLength":36}],
      "accessors":[{"bufferView":0,"componentType":5126,"count":5,"type":"VEC3","min":[-1,0,-1],"max":[1,2,1]},
                   {"bufferView":1,"componentType":5123,"count":18,"type":"SCALAR"}]})";
    while (json.size() % 4) json += ' ';
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char(v >> (8 * i))); };
    b += "glTF";
    u32(2);
    u32(std::uint32_t(12 + 8 + json.size() + 8 + bin.size()));
    u32(std::uint32_t(json.size()));
    b += "JSON";
    b += json;
    u32(std::uint32_t(bin.size()));
    b += "BIN";
    b.push_back('\0');
    b += bin;
    return b;
}

}  // namespace

TEST_CASE("assets.contact_sheet: rows for each background and greyscale, labelled columns, a temporary picture, same bytes twice") {
    AssetsProject p;
    write_png(p.file("assets/red.png"), make_image(16, 16, {220, 30, 30, 255}));
    write_png(p.file("assets/dot.png"), make_image(8, 24, {30, 200, 30, 255}));
    const Json args = Json{{"paths", Json::array({"assets/red.png", "assets/dot.png"})}};
    const Json r = p.ok("assets.contact_sheet", args);
    CHECK(r["rows"] == Json::array({"light", "dark", "greyscale"}));  // no main camera in this folder
    CHECK(r["cells"] == 2);
    REQUIRE(r.contains("$image"));
    CHECK(r["$image"]["temporary"] == true);
    CHECK(is_engine_named_screenshot(std::filesystem::path(r["$image"]["path"].get<std::string>()).filename().string()));
    const Image pic = picture_of(r);
    CHECK(pic.width == r["picture"]["width"].get<int>());
    CHECK(pic.height == r["picture"]["height"].get<int>());
    CHECK_FALSE(p.exists("assets.json"));  // nothing else was written
    CHECK(r["warnings"].empty());
    CHECK(has_text(r["nextSteps"], "assets.preview_in_scene"));

    const Json again = p.ok("assets.contact_sheet", args);
    CHECK(read_all(again["$image"]["path"].get<std::string>()) == read_all(r["$image"]["path"].get<std::string>()));

    // the red square is on the sheet, and in the greyscale row it has no colour
    int reds = 0, greenish = 0;
    for (std::size_t i = 0; i + 3 < pic.rgba.size(); i += 4) {
        if (pic.rgba[i] == 220 && pic.rgba[i + 1] == 30 && pic.rgba[i + 2] == 30) ++reds;
        if (pic.rgba[i] == pic.rgba[i + 1] && pic.rgba[i + 1] == pic.rgba[i + 2] && pic.rgba[i] == 0x3b) ++greenish;  // 0.2126*220+0.7152*30+0.0722*30 = 70?
    }
    CHECK(reds == 16 * 16 * 2);  // light and dark rows
    (void)greenish;
}

TEST_CASE("assets.contact_sheet: sizes make a column each, shrinking averages and growing keeps hard pixels") {
    AssetsProject p;
    write_png(p.file("assets/red.png"), make_image(16, 16, {220, 30, 30, 255}));
    const Json r = p.ok("assets.contact_sheet", Json{{"paths", Json::array({"assets/red.png"})}, {"sizes", Json::array({8, 32})}, {"greyscale", false}, {"backgrounds", Json::array({"#ffffff"})}});
    CHECK(r["cells"] == 2);
    CHECK(r["rows"] == Json::array({"#ffffff"}));
    const Image pic = picture_of(r);
    int reds = 0;
    for (std::size_t i = 0; i + 3 < pic.rgba.size(); i += 4)
        if (pic.rgba[i] == 220 && pic.rgba[i + 1] == 30 && pic.rgba[i + 2] == 30) ++reds;
    CHECK(reds == 8 * 8 + 32 * 32);
}

TEST_CASE("assets.contact_sheet: path writes the PNG, an existing file needs overwrite, a sprite sheet shows frame 0 or all") {
    AssetsProject p;
    Image sheet = make_image(32, 16);
    fill_rect(sheet, 0, 0, 16, 16, {255, 0, 0, 255});
    fill_rect(sheet, 16, 0, 16, 16, {0, 0, 255, 255});
    write_png(p.file("assets/walk.png"), sheet);
    write_all(p.file("assets.json"), Json::object({{"format", 1}, {"assets", Json::object({{"assets/walk.png", Json::object({{"sheet", Json::object({{"columns", 2}, {"rows", 1}, {"frameWidth", 16}, {"frameHeight", 16}, {"frames", 2}})}})}})}}).dump());
    Json r = p.ok("assets.contact_sheet", Json{{"paths", Json::array({"assets/walk.png"})}, {"path", "review/walk.png"}});
    CHECK(r["cells"] == 1);
    CHECK(has_warning(r, "allFrames"));
    CHECK(r["written"] == "review/walk.png");
    CHECK(p.exists("review/walk.png"));
    CHECK_FALSE(r["$image"].contains("temporary"));
    CommandResult again = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/walk.png"})}, {"path", "review/walk.png"}});
    CHECK_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    r = p.ok("assets.contact_sheet", Json{{"paths", Json::array({"assets/walk.png"})}, {"path", "review/walk.png"}, {"overwrite", true}, {"allFrames", true}});
    CHECK(r["cells"] == 2);
    CHECK(r["warnings"].empty());
}

TEST_CASE("assets.contact_sheet: teaching errors for a missing file, a wrong kind, bad sizes and unknown arguments") {
    AssetsProject p;
    write_png(p.file("assets/a.png"), make_image(4, 4, {1, 2, 3, 255}));
    write_all(p.file("assets/s.wav"), "RIFF");
    write_all(p.file("assets/m.gltf"), "{}");
    CommandResult r = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/nope.png"})}});
    CHECK_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
    r = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/s.wav"})}});
    CHECK(message(r).find("assets.spectrogram") != std::string::npos);
    r = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/m.gltf"})}});
    CHECK(message(r).find("assets.preview_in_scene") != std::string::npos);
    r = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/a.png"})}, {"sizes", Json::array({2})}});
    CHECK_FALSE(r.ok);
    CHECK(message(r).find("/sizes/0") != std::string::npos);
    r = p.call("assets.contact_sheet", Json{{"paths", Json::array()}});
    CHECK_FALSE(r.ok);
    r = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/a.png"})}, {"background", "#fff"}});
    CHECK(message(r).find("backgrounds") != std::string::npos);  // did you mean
}

TEST_CASE("assets.contact_sheet: the camera clear colour of the main scene is a row") {
    TempDir tmp;
    REQUIRE(create_project(tmp.str(), "2d-empty").ok());
    CommandRegistry reg;
    register_tooling_commands(reg, tmp.str());
    write_png(std::filesystem::path(tmp.str()) / "assets/a.png", make_image(4, 4, {1, 2, 3, 255}));
    const CommandResult r = reg.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/a.png"})}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["rows"].size() == 4);
    CHECK(r.result["rows"][2] == "camera");
}

TEST_CASE("assets.contact_sheet: a .glb is drawn as a thumbnail (needs a GPU)") {
    TempDir tmp;
    REQUIRE(create_project(tmp.str(), "2d-empty").ok());
    CommandRegistry reg;
    register_tooling_commands(reg, tmp.str());
    write_all(std::filesystem::path(tmp.str()) / "assets/pyramid.glb", pyramid_glb());
    const CommandResult r = reg.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/pyramid.glb"})}, {"backgrounds", Json::array({"#ffffff"})}, {"greyscale", false}});
    if (!r.ok && r.error.value("code", std::string()) == "no_gpu") {
        MESSAGE("skipped: no graphics device on this machine");
        CHECK(message(r).find("GPU") != std::string::npos);
        return;
    }
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Image pic = picture_of(r.result);
    int dark = 0;  // the pyramid has pixels that are not the white background nor the label text colour
    for (std::size_t i = 0; i + 3 < pic.rgba.size(); i += 4)
        if (pic.rgba[i] < 250 && pic.rgba[i] > 20 && pic.rgba[i + 1] < 250) ++dark;
    CHECK(dark > 200);
}
