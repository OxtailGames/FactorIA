#include <doctest.h>

#include <filesystem>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
struct TempProject {
    stdfs::path dir;
    stdfs::path oldRoot;
    TempProject() {
        oldRoot = fs::project_root();
        dir = fs::make_temp_dir("fa_test_asset_manifest").value();
        fs::set_project_root(dir);
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};
}  // namespace

TEST_CASE("asset manifest: kinds by extension") {
    CHECK(assets::kind_of("assets/hero.PNG") == assets::AssetKind::Texture);
    CHECK(assets::kind_of("assets/theme.ogg") == assets::AssetKind::Audio);
    CHECK(assets::kind_of("assets/ship.glb") == assets::AssetKind::Model);
    CHECK(assets::kind_of("assets/ui.ttf") == assets::AssetKind::Font);
    CHECK(assets::kind_of("assets/intro.mp4") == assets::AssetKind::Video);
    CHECK(assets::kind_of("scripts/a.js") == assets::AssetKind::Other);
    CHECK(std::string(assets::kind_name(assets::AssetKind::Audio)) == "audio");
}

TEST_CASE("asset manifest: missing file gives built-in defaults") {
    TempProject p;
    CHECK(assets::manifest()["format"] == assets::kManifestFormat);
    CHECK(assets::entry("assets/x.png").empty());
    Json t = assets::import_settings("assets/x.png");
    CHECK(t["compression"] == "auto");
    Json a = assets::import_settings("assets/music/theme.ogg");
    CHECK(a["stream"] == "auto");
    CHECK(a["targetLufs"].get<double>() == doctest::Approx(-16.0));
    CHECK(assets::import_settings("scripts/a.js").empty());
}

TEST_CASE("asset manifest: defaults and per-asset settings override, edits round-trip sorted") {
    TempProject p;
    REQUIRE(assets::update_manifest([](Json& doc) { doc["defaults"] = {{"audio", {{"normalize", true}}}}; }).ok());
    REQUIRE(assets::update_entry("assets/z.ogg", [](Json& e) { e["import"] = {{"stream", "never"}}; }).ok());
    REQUIRE(assets::update_entry("./assets/a.png", [](Json& e) {
        e["provenance"] = {{"origin", "generated"}, {"date", "2026-10-16"}};
    }).ok());

    Json a = assets::import_settings("assets/z.ogg");
    CHECK(a["stream"] == "never");
    CHECK(a["normalize"] == true);   // from defaults.audio
    CHECK(a["convert"] == "none");   // built-in
    CHECK(assets::entry("assets/a.png")["provenance"]["origin"] == "generated");

    // Entries are written sorted by path, whatever order they were added in.
    auto text = fs::read_text(assets::kManifestFile);
    REQUIRE(text.ok());
    CHECK(text->find("assets/a.png") < text->find("assets/z.ogg"));

    // An entry left empty disappears, and so does an empty "assets".
    REQUIRE(assets::update_entry("assets/a.png", [](Json& e) { e.erase("provenance"); }).ok());
    REQUIRE(assets::update_entry("assets/z.ogg", [](Json& e) { e.erase("import"); }).ok());
    CHECK_FALSE(assets::manifest().contains("assets"));
}

TEST_CASE("asset manifest: an invalid file is ignored at run time and never overwritten by edits") {
    TempProject p;
    REQUIRE(fs::write_text(assets::kManifestFile, "{ not json").ok());
    CHECK(assets::import_settings("assets/x.ogg")["stream"] == "auto");
    auto r = assets::update_entry("assets/x.ogg", [](Json& e) { e["import"] = {{"stream", "always"}}; });
    CHECK_FALSE(r.ok());
    CHECK(fs::read_text(assets::kManifestFile).value() == "{ not json");
}

TEST_CASE("asset manifest: today() is a YYYY-MM-DD date") {
    std::string d = assets::today();
    REQUIRE(d.size() == 10);
    CHECK(d[4] == '-');
    CHECK(d[7] == '-');
}

TEST_CASE("asset manifest: sheet() parses the sheet entry and follows edits of the file") {
    TempProject p;
    CHECK(assets::sheet("assets/coin.png") == nullptr);
    REQUIRE(assets::update_entry("assets/coin.png", [](Json& e) {
        e["sheet"] = Json::parse(R"({"columns":4,"rows":2,"frameWidth":16,"frameHeight":16,"frames":7,"padding":2,"pivot":[0.5,1],
            "clips":[{"name":"spin","firstFrame":0,"lastFrame":3,"fps":8,"loop":true},
                     {"name":"pop","firstFrame":4,"lastFrame":6,"fps":12,"loop":false,"pivot":[0.25,0.75]}]})");
    }).ok());
    auto s = assets::sheet("./assets/coin.png");
    REQUIRE(s);
    CHECK(s->columns == 4);
    CHECK(s->rows == 2);
    CHECK(s->padding == 2);
    REQUIRE(s->pivot);
    CHECK((*s->pivot)[1] == doctest::Approx(1.0f));
    REQUIRE(s->clips.size() == 2);
    CHECK(s->find("pop")->loop == false);
    CHECK(s->find("pop")->fps == doctest::Approx(12.0f));
    REQUIRE(s->find("pop")->pivot);
    CHECK(s->find("spin")->pivot == std::nullopt);
    CHECK(s->find("nope") == nullptr);
    CHECK(s->clip_names() == std::vector<std::string>{"spin", "pop"});
    REQUIRE(assets::update_entry("assets/coin.png", [](Json& e) { e["sheet"]["columns"] = 8; }).ok());
    CHECK(assets::sheet("assets/coin.png")->columns == 8);  // the cache follows the file
    CHECK(assets::parse_sheet(Json::object({{"columns", 2}})) == nullptr);
}

TEST_CASE("asset manifest: a second write of the same size right after a read is seen, though time and size match") {
    TempProject p;
    const stdfs::path file = p.dir / assets::kManifestFile;
    auto write_with_time = [&](const std::string& text, stdfs::file_time_type time) {
        REQUIRE(fs::write_text(assets::kManifestFile, text).ok());
        std::error_code ec;
        stdfs::last_write_time(file, time, ec);  // the same step of the file clock, as two quick writes on Windows
        REQUIRE_FALSE(ec);
    };
    REQUIRE(fs::write_text(assets::kManifestFile, R"({"format":1,"style":{"name":"aaaa"}})").ok());
    std::error_code ec;
    const stdfs::file_time_type stamp = stdfs::last_write_time(file, ec);
    REQUIRE_FALSE(ec);
    CHECK(assets::manifest()["style"]["name"] == "aaaa");
    write_with_time(R"({"format":1,"style":{"name":"bbbb"}})", stamp);
    CHECK(assets::manifest()["style"]["name"] == "bbbb");
    CHECK(assets::manifest()["style"]["name"] == "bbbb");  // the same text again keeps the parsed document
    // A read long after the file's time trusts time and size again: an old file is not re-read on every call.
    write_with_time(R"({"format":1,"style":{"name":"cccc"}})", stamp - std::chrono::seconds(60));
    CHECK(assets::manifest()["style"]["name"] == "cccc");
    const std::uint64_t reads = fs::disk_reads();
    (void)assets::manifest();
    (void)assets::manifest();
    CHECK(fs::disk_reads() == reads);
}

TEST_CASE("asset manifest: manifest_version changes when the file is read again, style_palette copies only the palette") {
    TempProject p;
    const std::uint64_t none = assets::manifest_version();
    CHECK(assets::manifest_version() == none);  // nothing changed: the same number
    CHECK(assets::style_palette().is_null());
    REQUIRE(assets::update_manifest([](Json& doc) { doc["style"] = {{"palette", Json::array({"#112233", "#ffffff"})}}; }).ok());
    const std::uint64_t first = assets::manifest_version();
    CHECK(first != none);
    CHECK(assets::manifest_version() == first);
    const Json palette = assets::style_palette();
    REQUIRE(palette.is_array());
    CHECK(palette.size() == 2);
    REQUIRE(assets::update_manifest([](Json& doc) { doc["style"]["palette"] = "palettes/night.png"; }).ok());
    CHECK(assets::manifest_version() != first);
    CHECK(assets::style_palette() == Json("palettes/night.png"));
}
