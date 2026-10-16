// project.validate: the checks that look at the asset files (texture size, weight, Sprite textures with a background).
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/json.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

constexpr std::uint64_t kMiB = std::uint64_t(1) << 20;
const Rgba kRed{255, 0, 0, 255}, kBlue{0, 0, 255, 255}, kClear{0, 0, 0, 0};

struct Game {
    TempDir tmp;
    std::string dir;

    explicit Game(const Json& platforms = Json::array({"windows"})) {
        dir = tmp.sub("game");
        REQUIRE(create_project(dir, "2d-empty").ok());
        set_platforms(platforms);
    }
    void set_platforms(const Json& platforms) {
        auto project = load_json_file(dir + "/factoria.json");
        REQUIRE(project.ok());
        (*project)["platforms"] = platforms;
        REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
    }
    // A file of the given size that costs no disk: it is extended, not written.
    void big_file(const std::string& rel, std::uint64_t bytes) {
        const stdfs::path file = stdfs::path(dir) / rel;
        stdfs::create_directories(file.parent_path());
        std::ofstream(file, std::ios::binary).put(0);
        stdfs::resize_file(file, bytes);
    }
    // The main scene gets a Sprite per texture.
    void sprites(const std::vector<std::string>& textures) {
        Json entities = Json::array({Json::object({{"id", "camera"}, {"components", Json::object({{"Camera", Json::object({{"primary", true}})}})}})});
        int n = 0;
        for (const std::string& t : textures)
            entities.push_back(Json::object({{"id", "s" + std::to_string(n++)}, {"components", Json::object({{"Sprite", Json::object({{"texture", t}})}})}}));
        REQUIRE(save_json_file(dir + "/scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", entities}})).ok());
    }
    std::vector<ValidationIssue> warnings(const std::string& file) const {
        std::vector<ValidationIssue> found;
        for (const ValidationIssue& w : validate_project(dir).warnings)
            if (w.file == file) found.push_back(w);
        return found;
    }
    ValidationReport report() const { return validate_project(dir); }
};

bool mentions(const std::vector<ValidationIssue>& issues, const std::string& needle) {
    for (const ValidationIssue& i : issues)
        if (i.message.find(needle) != std::string::npos || i.hint.find(needle) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("validate: a texture over 4096 px is a warning; over 2048 only for a game that lists a mobile platform") {
    Game g;
    write_png(stdfs::path(g.dir) / "assets/huge.png", make_image(5000, 8, kRed));
    write_png(stdfs::path(g.dir) / "assets/big.png", make_image(3000, 8, kRed));
    write_png(stdfs::path(g.dir) / "assets/ok.png", make_image(2048, 8, kRed));

    const auto huge = g.warnings("assets/huge.png");
    REQUIRE(huge.size() == 1);
    CHECK(huge[0].message.find("5000x8 px") != std::string::npos);
    CHECK(huge[0].message.find("4096") != std::string::npos);
    CHECK_FALSE(huge[0].hint.empty());
    CHECK(g.warnings("assets/big.png").empty());  // windows only: 3000 px is fine
    CHECK(g.warnings("assets/ok.png").empty());

    g.set_platforms(Json::array({"windows", "android"}));
    const auto big = g.warnings("assets/big.png");
    REQUIRE(big.size() == 1);
    CHECK(big[0].message.find("3000x8 px") != std::string::npos);
    CHECK(big[0].message.find("2048") != std::string::npos);
    CHECK(g.warnings("assets/ok.png").empty());
    CHECK(g.warnings("assets/huge.png").size() == 1);  // one warning, the 4096 one
    CHECK(g.report().ok);                              // warnings, not errors
}

TEST_CASE("validate: a file over 20 MB is a warning with a hint for its kind") {
    Game g;
    g.big_file("assets/theme.wav", 21 * kMiB);
    g.big_file("assets/scan.png", 25 * kMiB);  // not a real image: only its size is looked at
    g.big_file("assets/data.bin", 22 * kMiB);
    g.big_file("assets/small.wav", 19 * kMiB);

    const auto wav = g.warnings("assets/theme.wav");
    REQUIRE(wav.size() == 1);
    CHECK(wav[0].message.find("21.0 MB") != std::string::npos);
    CHECK(wav[0].hint.find("OGG") != std::string::npos);
    CHECK(mentions(g.warnings("assets/scan.png"), "compress"));
    CHECK(mentions(g.warnings("assets/data.bin"), "Leave it out"));
    CHECK(g.warnings("assets/small.wav").empty());
}

TEST_CASE("validate: the files that ship are compared with the limits of the stores the game targets") {
    Game g;
    g.big_file("assets/world.bin", 201 * kMiB);

    CHECK(g.warnings("factoria.json").empty());  // windows has no store limit here

    g.set_platforms(Json::array({"ios"}));
    auto ios = g.warnings("factoria.json");
    REQUIRE(ios.size() == 1);
    CHECK(ios[0].pointer == "/platforms");
    CHECK(ios[0].message.find("201.0 MB for ios") != std::string::npos);
    CHECK(ios[0].message.find("200 MB") != std::string::npos);
    CHECK(ios[0].hint.find("before the export") != std::string::npos);

    g.set_platforms(Json::array({"android"}));
    CHECK(g.warnings("factoria.json").empty());  // 201 MB is under the 500 MB of Google Play

    g.big_file("assets/world.bin", 501 * kMiB);
    auto android = g.warnings("factoria.json");
    REQUIRE(android.size() == 1);
    CHECK(android[0].message.find("for android") != std::string::npos);
    CHECK(android[0].message.find("500 MB") != std::string::npos);

    // What the export leaves out does not count: build output, tests, tools and hidden folders.
    g.set_platforms(Json::array({"ios"}));
    g.big_file("assets/world.bin", 1 * kMiB);
    for (const char* skipped : {"build/out.bin", "tests/replay.bin", "tools/dump.bin", ".cache/blob.bin"}) {
        g.big_file(skipped, 201 * kMiB);
        CHECK_MESSAGE(g.warnings("factoria.json").empty(), skipped);
        stdfs::remove(stdfs::path(g.dir) / skipped);
    }
}

TEST_CASE("validate: a Sprite texture whose corners are one opaque colour is probably a background") {
    Game g;
    Image withBackground = make_image(16, 16, kRed);  // a red background...
    fill_rect(withBackground, 5, 5, 6, 6, kBlue);      // ...with a blue character in the middle
    write_png(stdfs::path(g.dir) / "assets/hero.png", withBackground);
    write_png(stdfs::path(g.dir) / "assets/cutout.png", [] {
        Image img = make_image(16, 16, kClear);
        fill_rect(img, 5, 5, 6, 6, kBlue);
        return img;
    }());
    write_png(stdfs::path(g.dir) / "assets/block.png", make_image(16, 16, kRed));  // one flat colour: a placeholder rectangle
    write_png(stdfs::path(g.dir) / "assets/unused.png", withBackground);           // no Sprite draws it
    write_png(stdfs::path(g.dir) / "assets/gone.png", make_image(16, 16, kClear));
    g.sprites({"assets/hero.png", "assets/cutout.png", "assets/block.png", "assets/gone.png", "assets/missing.png"});

    const auto hero = g.warnings("assets/hero.png");
    REQUIRE(hero.size() == 1);
    CHECK(hero[0].message.find("background that should be transparent") != std::string::npos);
    CHECK(hero[0].message.find("#ff0000") != std::string::npos);
    CHECK(hero[0].hint.find("assets.slice_sheet") != std::string::npos);
    CHECK(hero[0].hint.find("\"background\":\"auto\"") != std::string::npos);
    CHECK(g.warnings("assets/cutout.png").empty());
    CHECK(g.warnings("assets/block.png").empty());
    CHECK(g.warnings("assets/unused.png").empty());

    const auto gone = g.warnings("assets/gone.png");
    REQUIRE(gone.size() == 1);
    CHECK(gone[0].message.find("fully transparent") != std::string::npos);

    // A missing texture is the job of the missing-asset check (an error), not of this one.
    CHECK(g.warnings("assets/missing.png").empty());
    CHECK_FALSE(g.report().ok);
}

TEST_CASE("validate: a project without assets has no asset warnings") {
    Game g(Json::array({"windows", "ios", "android"}));
    for (const ValidationIssue& w : g.report().warnings) {
        CHECK(w.file.rfind("assets", 0) != 0);
        CHECK(w.pointer != "/platforms");
    }
}
