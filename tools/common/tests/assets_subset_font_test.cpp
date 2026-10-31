// assets.subset_font: a font cut down to the characters of the locale tables. The test font is the Noto Sans JP subset of the render tests.
#include <doctest.h>
#include <hb.h>

#include <filesystem>
#include <set>

#include "asset_test_helpers.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

std::set<std::uint32_t> unicodes_of(const std::string& bytes) {
    hb_blob_t* blob = hb_blob_create(bytes.data(), unsigned(bytes.size()), HB_MEMORY_MODE_READONLY, nullptr, nullptr);
    hb_face_t* face = hb_face_create(blob, 0);
    hb_set_t* set = hb_set_create();
    hb_face_collect_unicodes(face, set);
    std::set<std::uint32_t> out;
    for (hb_codepoint_t cp = HB_SET_VALUE_INVALID; hb_set_next(set, &cp);) out.insert(cp);
    hb_set_destroy(set);
    hb_face_destroy(face);
    hb_blob_destroy(blob);
    return out;
}

const std::string kSource = std::string(FA_RENDER_DATA_DIR) + "/fonts/NotoSansJP-Regular-subset.ttf";

}  // namespace

TEST_CASE("assets.subset_font: keeps the characters of the tables plus Latin and passes validate") {
    TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    auto j = load_json_file(dir + "/factoria.json");
    REQUIRE(j.ok());
    (*j)["localization"] = Json::parse(R"({"defaultLanguage":"ja","languages":["ja"],"languageFonts":{"ja":["assets/fonts/ja.ttf"]}})");
    REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    write_all(dir + "/locales/ja.json", R"({"$name":"日本語","menu":{"play":"日本"},"coins":{"one":"{n}語","other":"{n}本語"}})");

    CommandRegistry registry;
    register_asset_commands(registry, dir);
    const auto r = registry.call("assets.subset_font", {{"source", kSource}, {"out", "assets/fonts/ja.ttf"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["written"] == true);
    CHECK(r.result["bytes"].get<long>() < r.result["sourceBytes"].get<long>());
    CHECK(has_text(r.result["missing"], "n"));  // the test font is itself a subset with no Latin letters: the {n} of the strings is missing

    const std::set<std::uint32_t> source = unicodes_of(read_all(kSource));
    const std::set<std::uint32_t> kept = unicodes_of(read_all(dir + "/assets/fonts/ja.ttf"));
    for (std::uint32_t cp : {0x65E5u, 0x672Cu, 0x8A9Eu, 0x3002u}) CHECK_MESSAGE(kept.contains(cp), cp);
    for (std::uint32_t cp : source)  // Latin-1 and the ASCII the source has stay
        if (cp >= 0x20 && cp < 0x100) CHECK_MESSAGE(kept.contains(cp), cp);
    // exactly Latin, punctuation and the table's characters: a kanji the source has but no string uses is gone
    std::size_t dropped = 0;
    for (std::uint32_t cp : source)
        if (cp >= 0x4E00 && cp <= 0x9FFF && !kept.contains(cp)) ++dropped;
    CHECK(dropped > 10);
    for (std::uint32_t cp : kept) CHECK_MESSAGE(source.contains(cp), cp);
    CHECK(kept.size() < source.size());

    // the font replaces nothing in the project's files, and the glyph check finds every string covered
    const ValidationReport report = validate_project(dir);
    for (const auto& e : report.errors) CHECK_MESSAGE(false, e.file << ": " << e.message);

    // again: the same bytes are not written twice
    CHECK(registry.call("assets.subset_font", {{"source", kSource}, {"out", "assets/fonts/ja.ttf"}}).result["written"] == false);
}

TEST_CASE("assets.subset_font: `keep`, characters the source lacks, and the mistakes it teaches about") {
    AssetsProject p;
    write_all(p.file("factoria.json"), R"({"localization":{"defaultLanguage":"en","languages":["en"]}})");
    write_all(p.file("locales/en.json"), R"({"a":"Hello 😀 ☃"})");

    const Json r = p.ok("assets.subset_font", {{"source", kSource}, {"out", "assets/fonts/x.ttf"}, {"keep", "日"}});
    CHECK(has_warning(r, "not in the source font"));
    CHECK(r["missing"].size() >= 1);
    CHECK(unicodes_of(read_all(p.file("assets/fonts/x.ttf"))).contains(0x65E5));

    auto fails = [&](Json args, const char* needle) {
        const auto res = p.call("assets.subset_font", args);
        CHECK_FALSE(res.ok);
        CHECK_MESSAGE(res.error.dump().find(needle) != std::string::npos, res.error.dump());
    };
    fails({{"source", kSource}, {"out", "fonts/x.ttf"}}, "under assets/");
    fails({{"source", "nothing.ttf"}, {"out", "assets/fonts/x.ttf"}}, "does not exist");
    fails({{"source", kSource}, {"out", "assets/fonts/x.ttf"}, {"locales", {"fr"}}}, "locales/fr.json");
    fails({{"source", kSource}, {"out", "assets/fonts/x.ttf"}, {"axes", {{"wght", 400}}}}, "not a variable font");
    write_all(p.file("assets/notfont.ttf"), "not a font");
    fails({{"source", "assets/notfont.ttf"}, {"out", "assets/fonts/x.ttf"}}, "not a font HarfBuzz can read");
}

TEST_CASE("assets.subset_font: with no languages and no `keep` there is nothing to keep") {
    AssetsProject p;
    const auto res = p.call("assets.subset_font", {{"source", kSource}, {"out", "assets/fonts/x.ttf"}});
    CHECK_FALSE(res.ok);
    CHECK(res.error.dump().find("no characters to keep") != std::string::npos);
}
