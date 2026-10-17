// project.validate and localization: the "localization" section of factoria.json (wrong values with their JSON pointer, unknown keys),
// the string tables (locales/<language>.json), the `key`s of scenes and prefabs, and whether the fonts have a glyph for every
// character the game shows (the Noto subsets of the render tests stand for the fonts a game ships).
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"  // FA_RENDER_DATA_DIR
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* const kJp = "assets/fonts/NotoSansJP-Regular-subset.ttf";
const char* const kKr = "assets/fonts/NotoSansKR-Regular-subset.ttf";
const char* const kAr = "assets/fonts/NotoSansArabic-Regular-subset.ttf";

// A 2d-empty project with a "localization" section (when `localization` is not null).
struct Project {
    testing::TempDir tmp;
    std::string dir;

    explicit Project(const char* localization) {
        REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
        dir = tmp.sub("game");
        if (!localization) return;
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["localization"] = *parse_json(localization);
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    }
    void table(const char* language, const char* json) { testing::write_all(dir + "/locales/" + language + ".json", json); }
    void font(const char* path) {
        const stdfs::path to = stdfs::path(dir) / path;
        stdfs::create_directories(to.parent_path());
        stdfs::copy_file(stdfs::path(FA_RENDER_DATA_DIR) / "fonts" / to.filename(), to, stdfs::copy_options::overwrite_existing);
    }
    // A scene or prefab in the canonical layout, so that only its content is reported.
    void scene(const std::string& rel, const char* entities) {
        stdfs::create_directories(stdfs::path(dir + "/" + rel).parent_path());
        REQUIRE(save_scene_json_file(dir + "/" + rel, Json::parse(std::string(R"({"format": "factoria.scene/1", "entities": )") + entities + "}")).ok());
    }
    void prefab(const std::string& rel, const char* entity) {
        stdfs::create_directories(stdfs::path(dir + "/" + rel).parent_path());
        REQUIRE(save_scene_json_file(dir + "/" + rel, Json::parse(std::string(R"({"format": "factoria.prefab/1", "entity": )") + entity + "}")).ok());
    }
    ValidationReport validate() const { return validate_project(dir); }
};

std::vector<const ValidationIssue*> at(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer = "*") {
    std::vector<const ValidationIssue*> found;
    for (const auto& i : list)
        if (i.file == file && (pointer == "*" || i.pointer == pointer)) found.push_back(&i);
    return found;
}

bool mentions(const ValidationIssue& issue, const std::string& text) {
    return issue.message.find(text) != std::string::npos || issue.hint.find(text) != std::string::npos;
}

const char* kTwoLanguages = R"({"defaultLanguage": "en", "languages": ["en", "es"]})";
const char* kEn = R"({"menu": {"play": "Play", "quit": "Quit"}, "greeting": "Hello, {name}!", "coins": {"one": "{count} coin", "other": "{count} coins"}})";
const char* kEs = R"({"menu": {"play": "Jugar", "quit": "Salir"}, "greeting": "¡Hola, {name}!", "coins": {"one": "{count} moneda", "other": "{count} monedas"}})";

}  // namespace

TEST_CASE("validate: a good localization section with consistent tables adds nothing") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "es", "zh-Hans"],
        "fallbackFonts": ["assets/fonts/NotoSansArabic-Regular-subset.ttf"], "languageFonts": {"zh-Hans": ["assets/fonts/NotoSansJP-Regular-subset.ttf"]}})");
    p.font(kAr);
    p.font(kJp);
    p.table("en", kEn);
    p.table("es", kEs);
    p.table("zh-Hans", R"({"$name": "Chinese", "menu": {"play": "日本", "quit": "語"}, "greeting": "中文 {name}", "coins": {"other": "{count}"}})");
    const ValidationReport r = p.validate();
    for (const auto& e : r.errors) CHECK_MESSAGE(false, e.to_string());
    for (const auto& w : r.warnings) CHECK_MESSAGE((w.file == "AGENTS.md" || w.file == "tests"), w.to_string());  // what a bare project warns about
}

TEST_CASE("validate: localization mistakes are reported once each, at their pointer, with a fix") {
    Project p(R"({"defaultLanguage": "fr", "languages": ["en", "pt_br", "en"],
        "languageFonts": {"ja": ["a.ttf"]}, "fallbackFont": []})");
    const ValidationReport r = p.validate();
    CHECK_FALSE(r.ok);

    const auto badTag = at(r.errors, "factoria.json", "/localization/languages/1");
    REQUIRE(badTag.size() == 1);  // the schema's own message is dropped in favour of this one
    CHECK(badTag[0]->message.find("pt-BR") != std::string::npos);
    CHECK_FALSE(badTag[0]->hint.empty());
    const auto twice = at(r.errors, "factoria.json", "/localization/languages/2");
    REQUIRE(twice.size() == 1);
    CHECK(twice[0]->message.find("listed twice") != std::string::npos);

    const auto typo = at(r.warnings, "factoria.json", "/localization/fallbackFont");
    REQUIRE(typo.size() == 1);
    CHECK(typo[0]->message.find("fallbackFonts") != std::string::npos);  // did you mean
    CHECK(at(r.errors, "locales/en.json").empty());                       // a broken section: its tables are not looked at
}

TEST_CASE("validate: a default language that is not in the list, a font for a language the game lacks") {
    Project p(R"({"defaultLanguage": "fr", "languages": ["en", "es"],
        "languageFonts": {"ja": ["assets/fonts/a.ttf"]}})");
    const ValidationReport r = p.validate();
    const auto def = at(r.errors, "factoria.json", "/localization/defaultLanguage");
    REQUIRE(def.size() == 1);
    CHECK(def[0]->message.find("not one of \"languages\"") != std::string::npos);
    const auto font = at(r.errors, "factoria.json", "/localization/languageFonts/ja");
    REQUIRE(font.size() == 1);
    CHECK(font[0]->message.find("not one of \"languages\"") != std::string::npos);
}

TEST_CASE("validate: a table that is missing or is not a string table is an error with the file and the JSON pointer") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "es", "pt-BR"]})");
    p.table("en", kEn);
    p.table("es", R"({"menu": {"play": 3}})");
    const ValidationReport r = p.validate();
    const auto missing = at(r.errors, "locales/pt-BR.json");
    REQUIRE(missing.size() == 1);
    CHECK(mentions(*missing[0], "does not exist"));
    CHECK_FALSE(missing[0]->hint.empty());
    const auto wrong = at(r.errors, "locales/es.json", "/menu/play");
    REQUIRE(wrong.size() == 1);
    CHECK(mentions(*wrong[0], "expected a string"));

    p.table("pt-BR", "{ not json");
    const ValidationReport again = p.validate();  // at() points into the report: keep it alive
    const auto broken = at(again.errors, "locales/pt-BR.json");
    REQUIRE(broken.size() == 1);
    CHECK_FALSE(broken[0]->message.empty());
}

TEST_CASE("validate: keys a language lacks, keys the default language lacks (did you mean), placeholders, plural forms") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "es", "ru", "ja"]})");
    p.table("en", R"({"menu": {"play": "Play", "quit": "Quit"}, "greeting": "Hello, {name}!", "coins": {"one": "{count} coin", "other": "{count} coins"},
                       "items": "Items", "level": {"one": "Level", "other": "Levels"}})");
    p.table("es", R"({"menu": {"play": "Jugar", "quti": "Salir"}, "greeting": "¡Hola, {nombre}!", "coins": {"one": "{count} moneda", "other": "{count} monedas"},
                       "items": "Objetos", "level": "Nivel"})");
    p.table("ru", R"({"menu.play": "Играть", "menu.quit": "Выход", "greeting": "Привет, {name}!", "items": "Предметы", "level": {"other": "Уровни"},
                       "coins": {"one": "{count} монета", "other": "{count} монеты"}})");
    p.table("ja", R"({"menu.play": "x", "menu.quit": "y", "greeting": "{name}", "items": "z", "level": {"other": "Lv", "one": "Lv1"},
                       "coins": {"other": "{count}", "zero": "0"}})");
    const ValidationReport r = p.validate();
    CHECK(r.errors.empty());

    // Spanish: "menu.quit" is missing and a stale "menu.quti" exists (did you mean), {nombre} is not {name}, "level" lost its plural form.
    const auto missing = at(r.warnings, "locales/es.json", "");
    REQUIRE(missing.size() == 1);
    CHECK(mentions(*missing[0], "lacks 1 of the 6 strings"));
    CHECK(mentions(*missing[0], "'menu.quit'"));
    const auto stale = at(r.warnings, "locales/es.json", "/menu/quti");
    REQUIRE(stale.size() == 1);
    CHECK(mentions(*stale[0], "Did you mean 'menu.quit'?"));
    const auto placeholder = at(r.warnings, "locales/es.json", "/greeting");
    REQUIRE(placeholder.size() == 1);
    CHECK(mentions(*placeholder[0], "{nombre}"));
    CHECK(mentions(*placeholder[0], "{name}"));
    const auto shape = at(r.warnings, "locales/es.json", "/level");
    REQUIRE(shape.size() == 1);
    CHECK(mentions(*shape[0], "plural forms in locales/en.json but is one plain string"));

    // Russian counts need "few" and "many"; its "level" entry has "other" only.
    std::string russian;
    for (const ValidationIssue* i : at(r.warnings, "locales/ru.json")) russian += i->message + "\n";
    CHECK(russian.find("'coins' has no \"few\" form") != std::string::npos);
    CHECK(russian.find("'coins' has no \"many\" form") != std::string::npos);
    CHECK(russian.find("counts like 2") != std::string::npos);
    CHECK(russian.find("'level' has no \"one\" form") != std::string::npos);

    // Japanese has one form: "one" and "zero" are never picked.
    const auto never = at(r.warnings, "locales/ja.json", "/coins/zero");
    REQUIRE(never.size() == 1);
    CHECK(mentions(*never[0], "no count picks"));
    CHECK(at(r.warnings, "locales/ja.json", "/level/one").size() == 1);
    CHECK(at(r.warnings, "locales/ja.json", "/coins/other").empty());
}

TEST_CASE("validate: the `key` of a Text or widget must be in the default table; plural and placeholder keys cannot be filled by a component") {
    Project p(kTwoLanguages);
    p.table("en", kEn);
    p.table("es", kEs);
    p.scene("scenes/main.scene.json", R"([
        {"id": "camera", "components": {"Camera": {}}},
        {"id": "ok", "components": {"Button": {"text": "Play", "key": "menu.play"}}},
        {"id": "typo", "components": {"Text": {"text": "Play", "key": "menu.plya"}}},
        {"id": "toggle", "components": {"Toggle": {"label": "Quit", "key": "menu.quti"}}},
        {"id": "count", "components": {"Text": {"text": "coins", "key": "coins"}}},
        {"id": "hello", "components": {"TextField": {"placeholder": "Hello", "key": "greeting"}}}])");
    p.prefab("prefabs/row.prefab.json", R"({"id": "row", "children": [{"id": "label", "components": {"Slider": {"label": "x", "key": "volume"}}}]})");
    const ValidationReport r = p.validate();
    CHECK(at(r.errors, "scenes/main.scene.json", "/entities/1/components/Button/key").empty());

    const auto typo = at(r.errors, "scenes/main.scene.json", "/entities/2/components/Text/key");
    REQUIRE(typo.size() == 1);
    CHECK(mentions(*typo[0], "'menu.plya'"));
    CHECK(mentions(*typo[0], "locales/en.json"));
    CHECK(mentions(*typo[0], "Did you mean 'menu.play'?"));
    const auto toggle = at(r.errors, "scenes/main.scene.json", "/entities/3/components/Toggle/key");
    REQUIRE(toggle.size() == 1);
    CHECK(mentions(*toggle[0], "Did you mean 'menu.quit'?"));
    const auto prefab = at(r.errors, "prefabs/row.prefab.json", "/entity/children/0/components/Slider/key");
    REQUIRE(prefab.size() == 1);
    CHECK(mentions(*prefab[0], "'volume'"));

    const auto plural = at(r.warnings, "scenes/main.scene.json", "/entities/4/components/Text/key");
    REQUIRE(plural.size() == 1);
    CHECK(mentions(*plural[0], "plural entry"));
    const auto placeholders = at(r.warnings, "scenes/main.scene.json", "/entities/5/components/TextField/key");
    REQUIRE(placeholders.size() == 1);
    CHECK(mentions(*placeholders[0], "{name}"));
}

TEST_CASE("validate: keys or locales/ without a localization section is a warning that says to add the section") {
    Project p(nullptr);
    p.scene("scenes/main.scene.json", R"([{"id": "camera", "components": {"Camera": {}}},
        {"id": "t", "components": {"Text": {"text": "Play", "key": "menu.play"}}}])");
    ValidationReport r = p.validate();
    const auto keys = at(r.warnings, "factoria.json", "");
    REQUIRE(keys.size() == 1);
    CHECK(mentions(*keys[0], "no \"localization\" section"));
    CHECK(mentions(*keys[0], "`key`"));
    CHECK(r.errors.empty());

    Project q(nullptr);
    q.table("en", kEn);
    r = q.validate();
    const auto folder = at(r.warnings, "factoria.json", "");
    REQUIRE(folder.size() == 1);
    CHECK(mentions(*folder[0], "locales/ folder"));

    Project clean(nullptr);
    CHECK(at(clean.validate().warnings, "factoria.json").empty());
}

TEST_CASE("validate: a character no font has is an error that names the character, the text, the file and the fix") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "ko"]})");
    p.table("en", R"({"menu": {"play": "Play"}})");
    p.table("ko", R"({"menu": {"play": "한국어 한글"}})");
    const ValidationReport r = p.validate();
    CHECK_FALSE(r.ok);
    const auto missing = at(r.errors, "locales/ko.json", "/menu/play");
    REQUIRE(missing.size() == 1);
    const ValidationIssue& issue = *missing[0];
    CHECK(issue.message.find("U+D55C '\xED\x95\x9C'") != std::string::npos);   // the character
    CHECK(issue.message.find("한국어 한글") != std::string::npos);                // the text
    CHECK(issue.message.find("'menu.play'") != std::string::npos);              // the table key
    CHECK(issue.hint.find("localization.languageFonts.\"ko\"") != std::string::npos);  // the fix
    CHECK(issue.hint.find("localization.fallbackFonts") != std::string::npos);
    CHECK(issue.hint.find("Noto Sans KR") != std::string::npos);
    CHECK(issue.to_string().find("locales/ko.json#/menu/play") != std::string::npos);

    // The fix works: with the Korean font listed for Korean, the table validates.
    p.font(kKr);
    auto j = load_json_file(p.dir + "/factoria.json");
    (*j)["localization"]["languageFonts"] = *parse_json(R"({"ko": ["assets/fonts/NotoSansKR-Regular-subset.ttf"]})");
    REQUIRE(save_json_file(p.dir + "/factoria.json", *j).ok());
    for (const auto& e : p.validate().errors) CHECK_MESSAGE(false, e.to_string());
}

TEST_CASE("validate: the font chain of a table string is the font of the component that shows its key, then the language's fonts") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "ja"], "languageFonts": {"ja": ["assets/fonts/NotoSansArabic-Regular-subset.ttf"]}})");
    p.font(kJp);
    p.font(kAr);
    p.table("en", R"({"title": "Title", "other": "Other"})");
    p.table("ja", R"({"title": "日本語", "other": "日本語"})");
    p.scene("scenes/main.scene.json", R"([{"id": "camera", "components": {"Camera": {}}},
        {"id": "t", "components": {"Text": {"text": "Title", "key": "title", "font": "assets/fonts/NotoSansJP-Regular-subset.ttf"}}}])");
    const ValidationReport r = p.validate();
    // "title" is shown with the Japanese font; "other" has no component, so only the built-in and Arabic fonts are tried.
    CHECK(at(r.errors, "locales/ja.json", "/title").empty());
    const auto other = at(r.errors, "locales/ja.json", "/other");
    REQUIRE(other.size() == 1);
    CHECK(other[0]->message.find("U+65E5 '\xE6\x97\xA5'") != std::string::npos);
    CHECK(other[0]->message.find("DejaVu Sans") != std::string::npos);
    CHECK(other[0]->message.find(kAr) != std::string::npos);  // the chain that was searched
    CHECK(other[0]->message.rfind("DejaVu Sans (built-in)") == other[0]->message.find("DejaVu Sans (built-in)"));  // named once
    CHECK(other[0]->hint.find("Noto Sans JP") != std::string::npos);
}

TEST_CASE("validate: literal texts of scenes and prefabs are checked against their font and the default language's fonts") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en"], "fallbackFonts": ["assets/fonts/NotoSansKR-Regular-subset.ttf"]})");
    p.font(kJp);
    p.font(kKr);
    p.table("en", R"({"x": "x"})");
    p.scene("scenes/main.scene.json", R"([{"id": "camera", "components": {"Camera": {}}},
        {"id": "greek", "components": {"Text": {"text": "Ωμέγα Привет"}}},
        {"id": "jp", "components": {"Text": {"text": "日本語", "font": "assets/fonts/NotoSansJP-Regular-subset.ttf"}}},
        {"id": "kr", "components": {"Button": {"text": "한국어"}}},
        {"id": "lost", "components": {"Text": {"text": "العربية"}, "Toggle": {"label": "ゲーム"}}},
        {"id": "keyed", "components": {"Text": {"text": "日本語", "key": "x"}}}])");
    p.prefab("prefabs/hud.prefab.json", R"({"id": "hud", "components": {"TextField": {"placeholder": "العربية"}}})");
    const ValidationReport r = p.validate();
    CHECK(at(r.errors, "scenes/main.scene.json", "/entities/1/components/Text/text").empty());   // DejaVu has Greek and Cyrillic
    CHECK(at(r.errors, "scenes/main.scene.json", "/entities/2/components/Text/text").empty());   // its own font
    CHECK(at(r.errors, "scenes/main.scene.json", "/entities/3/components/Button/text").empty()); // the project's fallback font
    CHECK(at(r.errors, "scenes/main.scene.json", "/entities/5/components/Text/text").empty());   // a keyed text is checked as a table string
    const auto arabic = at(r.errors, "scenes/main.scene.json", "/entities/4/components/Text/text");
    REQUIRE(arabic.size() == 0);  // DejaVu Sans has Arabic
    const auto kana = at(r.errors, "scenes/main.scene.json", "/entities/4/components/Toggle/label");
    REQUIRE(kana.size() == 1);
    CHECK(kana[0]->message.find("U+30B2") != std::string::npos);
    CHECK(kana[0]->message.find("ゲーム") != std::string::npos);
    CHECK(kana[0]->message.find("Toggle.label") != std::string::npos);
    CHECK(kana[0]->hint.find("localization.fallbackFonts") != std::string::npos);
    CHECK(kana[0]->hint.find("Noto Sans JP") != std::string::npos);
    CHECK(at(r.errors, "prefabs/hud.prefab.json").empty());
}

TEST_CASE("validate: without a localization section a literal text is checked against its own font only") {
    Project p(nullptr);
    p.font(kJp);
    p.scene("scenes/main.scene.json", R"([{"id": "camera", "components": {"Camera": {}}},
        {"id": "jp", "components": {"Text": {"text": "日本語", "font": "assets/fonts/NotoSansJP-Regular-subset.ttf"}}},
        {"id": "lost", "components": {"Text": {"text": "日本語"}}}])");
    const ValidationReport r = p.validate();
    CHECK(at(r.errors, "scenes/main.scene.json", "/entities/1/components/Text/text").empty());
    const auto lost = at(r.errors, "scenes/main.scene.json", "/entities/2/components/Text/text");
    REQUIRE(lost.size() == 1);
    CHECK(lost[0]->hint.find("set the component's \"font\"") != std::string::npos);
    CHECK(lost[0]->hint.find("\"localization\" section") != std::string::npos);
}

TEST_CASE("validate: a font that is missing or is not a font is its own error, not a flood of missing glyphs") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "ja"],
        "fallbackFonts": ["assets/fonts/not-there.ttf", "assets/fonts/bogus.ttf"]})");
    testing::write_all(p.dir + "/assets/fonts/bogus.ttf", "this is not a font");
    p.table("en", R"({"a": "Play"})");
    p.table("ja", R"({"a": "日本語", "b": "ゲーム", "c": "한국어"})");
    const ValidationReport r = p.validate();
    const auto absent = at(r.errors, "factoria.json", "/localization/fallbackFonts/0");
    REQUIRE(absent.size() == 1);
    CHECK(mentions(*absent[0], "not-there.ttf"));
    const auto bogus = at(r.errors, "factoria.json", "/localization/fallbackFonts/1");
    REQUIRE(bogus.size() == 1);
    CHECK(mentions(*bogus[0], "bogus.ttf"));
    CHECK(at(r.errors, "locales/ja.json").empty());  // no glyph complaints while the chain cannot be loaded
}

TEST_CASE("validate: many texts with missing glyphs are listed up to a limit, then summed up with every missing character") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "ja"]})");
    std::string table = "{";
    for (int i = 0; i < 40; ++i) table += (i ? "," : "") + std::string("\"k") + std::to_string(i) + "\": \"日本語" + std::to_string(i) + "\"";
    p.table("en", "{\"x\": \"x\"}");
    p.table("ja", (table + "}").c_str());
    const ValidationReport r = p.validate();
    const auto all = at(r.errors, "locales/ja.json");
    CHECK(all.size() == 26);  // 25 texts and the summary
    const ValidationIssue& summary = *all.back();
    CHECK(summary.pointer.empty());
    CHECK(mentions(summary, "15 more text(s)"));
    CHECK(mentions(summary, "U+65E5"));
    CHECK(mentions(summary, "U+672C"));
}

TEST_CASE("validate: the name of a language must be drawable in the other languages' menus") {
    Project p(R"({"defaultLanguage": "en", "languages": ["en", "ja"], "languageFonts": {"ja": ["assets/fonts/NotoSansJP-Regular-subset.ttf"]}})");
    p.font(kJp);
    p.table("en", R"({"$name": "English", "x": "x"})");
    p.table("ja", R"({"$name": "日本語", "x": "x"})");
    const ValidationReport r = p.validate();
    CHECK(r.errors.empty());  // drawn with the Japanese font while the game runs in Japanese...
    const auto name = at(r.warnings, "locales/ja.json", "/$name");
    REQUIRE(name.size() == 1);  // ...but not in English, where a language menu would show it
    CHECK(mentions(*name[0], "while the game runs in 'en'"));
    CHECK(mentions(*name[0], "localization.fallbackFonts"));
}
