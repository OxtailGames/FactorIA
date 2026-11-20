// M73-P3a-2: an .hdr is an asset kind of its own (SceneSettings.environmentMap): assets.import checks it with the code the renderer
// loads it with, project.validate checks the file a scene names, and the listing calls it "hdri".
#include <doctest.h>

#include <cstring>

#include "asset_test_helpers.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/image_float.h"
#include "fa/runtime/project.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

std::string hdr_file(int w, int h) {
    ImageF img = ImageF::create(w, h, 3).value();
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            float* p = img.at(x, y);
            p[0] = 0.2f + 0.01f * float(x);
            p[1] = 0.3f;
            p[2] = 0.5f + (y < h / 2 ? 0.2f : 0.0f);
        }
    const auto bytes = encode_hdr(img);
    return std::string(bytes.begin(), bytes.end());
}

std::string art(AssetsProject& p, const std::string& name, const std::string& bytes) {
    const stdfs::path file = p.tmp.path / "art" / name;
    write_all(file, bytes);
    return file.string();
}

}  // namespace

TEST_CASE("assets.import: an equirectangular .hdr lands in assets/hdri/ as the kind hdri, with what the GPU gets") {
    AssetsProject p;
    const Json r = p.ok("assets.import", {{"source", art(p, "Sunset Sky.HDR", hdr_file(64, 32))}, {"license", "CC0"}});
    CHECK(r["path"] == "assets/hdri/Sunset_Sky.hdr");
    CHECK(r["importer"] == "hdri");
    CHECK(r["details"]["width"] == 64);
    CHECK(r["details"]["height"] == 32);
    CHECK(r["details"]["shrunkForTheGpu"] == false);
    CHECK(r["written"][0]["kind"] == "hdri");
    CHECK(has_text(r["nextSteps"], "environmentMap"));
    CHECK(read_all(p.file("assets/hdri/Sunset_Sky.hdr")) == hdr_file(64, 32));  // copied as it is
    CHECK(p.manifest()["assets"].contains("assets/hdri/Sunset_Sky.hdr"));
    CHECK(assets::kind_of("assets/hdri/Sunset_Sky.hdr") == assets::AssetKind::Hdri);

    // The listing (assets.list) and the reflected asset fields call it "hdri".
    CHECK(asset_type_of("assets/hdri/Sunset_Sky.hdr") == "hdri");
}

TEST_CASE("assets.import: an .hdr that is not equirectangular, cut short or not Radiance's is an error that says how to fix it") {
    AssetsProject p;
    // a mirror-ball light probe
    CommandResult probe = p.call("assets.import", {{"source", art(p, "ball.hdr", hdr_file(32, 32))}});
    REQUIRE_FALSE(probe.ok);
    const std::string message = probe.error["message"].get<std::string>();
    CHECK(message.find("light probe") != std::string::npos);
    CHECK(message.find("equirectangular") != std::string::npos);
    CHECK(message.find("ball.hdr") != std::string::npos);
    CHECK_FALSE(p.exists("assets/hdri/ball.hdr"));
    // a cube cross
    CommandResult cross = p.call("assets.import", {{"source", art(p, "cross.hdr", hdr_file(32, 24))}});
    REQUIRE_FALSE(cross.ok);
    CHECK(cross.error["message"].get<std::string>().find("cube cross") != std::string::npos);
    // cut short: the header is fine, the pixels are not there
    std::string whole = hdr_file(64, 32);
    CommandResult cut = p.call("assets.import", {{"source", art(p, "cut.hdr", whole.substr(0, whole.size() / 2))}});
    REQUIRE_FALSE(cut.ok);
    CHECK(cut.error["message"].get<std::string>().find("cut.hdr") != std::string::npos);
    CHECK_FALSE(cut.error["hint"].get<std::string>().empty());
    // a PNG renamed .hdr
    CommandResult renamed = p.call("assets.import", {{"source", art(p, "fake.hdr", png_string(make_image(4, 2, {1, 2, 3, 255})))}});
    REQUIRE_FALSE(renamed.ok);
    CHECK(renamed.error["message"].get<std::string>().find("fake.hdr") != std::string::npos);
    // the extension of the destination is kept
    CommandResult ext = p.call("assets.import", {{"source", art(p, "sky.hdr", hdr_file(64, 32))}, {"path", "assets/hdri/sky.png"}});
    REQUIRE_FALSE(ext.ok);
    CHECK(ext.error["message"].get<std::string>().find("'.hdr'") != std::string::npos);
}

TEST_CASE("validate: SceneSettings.environmentMap names an existing equirectangular .hdr") {
    TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "3d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    write_all(dir / "assets/hdri/good.hdr", hdr_file(64, 32));
    write_all(dir / "assets/hdri/ball.hdr", hdr_file(32, 32));
    write_all(dir / "assets/hdri/notes.txt", "x");

    auto problems = [&](const char* map) {
        auto scene = load_json_file((dir / "scenes/main.scene.json").string());
        REQUIRE(scene.ok());
        (*scene)["settings"]["environmentMap"] = map;
        REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
        std::vector<ValidationIssue> out;
        for (const ValidationIssue& i : validate_project(dir.string()).errors)
            if (i.pointer == "/settings/environmentMap") out.push_back(i);
        return out;
    };
    CHECK(problems("assets/hdri/good.hdr").empty());
    CHECK(problems("").empty());
    const auto missing = problems("assets/hdri/goood.hdr");
    REQUIRE(missing.size() == 1);
    CHECK(missing[0].message.find("does not exist") != std::string::npos);
    CHECK(missing[0].hint.find("assets/hdri/good.hdr") != std::string::npos);
    const auto ball = problems("assets/hdri/ball.hdr");
    REQUIRE(ball.size() == 1);
    CHECK(ball[0].message.find("light probe") != std::string::npos);
    const auto notes = problems("assets/hdri/notes.txt");
    REQUIRE(notes.size() == 1);
    CHECK(notes[0].message.find("not a .hdr") != std::string::npos);
}
