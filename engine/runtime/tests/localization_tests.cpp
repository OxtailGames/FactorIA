// Localization of a running game: the "localization" section of factoria.json, the start language, the pass that writes
// translations into Text and widgets, i18n.state / i18n.set_language and hot reload of locales/*.json.
#include <chrono>
#include <cstdlib>
#include <filesystem>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/localization.h"
#include "fa/runtime/project.h"
#include "fa/scene/components.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// Sets an environment variable for the length of a test (and removes it again).
struct ScopedEnv {
    std::string name;
    ScopedEnv(const char* n, const char* value) : name(n) {
#ifdef _WIN32
        _putenv_s(n, value);
#else
        setenv(n, value, 1);
#endif
    }
    ~ScopedEnv() {
#ifdef _WIN32
        _putenv_s(name.c_str(), "");
#else
        unsetenv(name.c_str());
#endif
    }
};

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Loc", "id": "com.example.loc", "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180 },
  "localization": { "defaultLanguage": "en", "languages": ["en", "es", "pt-BR"] }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "title", "components": { "Text": { "text": "scene text", "key": "menu.title", "space": "screen" } } },
    { "id": "play", "components": { "Button": { "text": "Play", "key": "menu.play" } } },
    { "id": "music", "components": { "Slider": { "label": "Music", "key": "menu.music" } } },
    { "id": "plain", "components": { "Text": { "text": "no key here", "space": "screen" } } },
    { "id": "lost", "components": { "Text": { "text": "own text", "key": "menu.nobody_has_this", "space": "screen" } } }
  ]
})";

const char* kEn = R"({ "$name": "English", "menu": { "title": "My Game", "play": "Play", "music": "Music" }, "only_en": "Only English" })";
const char* kEs = R"({ "$name": "Español", "menu": { "title": "Mi juego", "play": "Jugar", "music": "Música" } })";
const char* kPt = R"json({ "$name": "Português (Brasil)", "menu": { "title": "Meu jogo", "play": "Jogar" } })json";

struct Game {
    stdfs::path dir;
    Engine engine;

    explicit Game(const std::string& name, const char* project = kProject, EngineConfig cfg = {}, bool tables = true, bool hot = false) {
        dir = fs::make_temp_dir("fa_loc_test_" + name);
        write("factoria.json", project);
        write("scenes/main.scene.json", kScene);
        if (tables) {
            write("locales/en.json", kEn);
            write("locales/es.json", kEs);
            write("locales/pt-BR.json", kPt);
        }
        cfg.projectDir = dir.generic_string();
        cfg.headless = true;
        cfg.hotReload = hot;
        std::string err;
        REQUIRE_MESSAGE(engine.init(cfg, nullptr, &err), err);
    }
    ~Game() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok());
    }
    Entity entity(const char* id) { return engine.world().find_by_id(id); }
    std::string text(const char* id) { return engine.world().get<Text>(entity(id))->text; }
    std::string button(const char* id) { return engine.world().get<Button>(entity(id))->text; }
    std::string slider(const char* id) { return engine.world().get<Slider>(entity(id))->label; }
    Json call(const char* command, const Json& args = Json::object()) {
        auto r = engine.commands().call(command, args);
        return r.ok ? r.result : Json::object({{"error", r.error}});
    }
};

}  // namespace

TEST_CASE("project: the \"localization\" section is read, and every mistake has a pointer and a fix") {
    const Json good = Json::parse(R"({
        "defaultLanguage": "en", "languages": ["en", "zh-Hans", "ja"],
        "fallbackFonts": ["assets/fonts/NotoSans.ttf"],
        "languageFonts": { "zh-Hans": ["assets/fonts/NotoSansSC.ttf"], "ja": ["assets/fonts/NotoSansJP.ttf"] } })");
    const LocalizationParse ok = parse_localization(good);
    REQUIRE(ok.ok());
    CHECK(ok.warnings.empty());
    CHECK(ok.settings.enabled());
    CHECK(ok.settings.languages == std::vector<std::string>{"en", "zh-Hans", "ja"});
    // The language's own fonts first, then the common ones.
    CHECK(ok.settings.fallback_fonts_for("ja") == std::vector<std::string>{"assets/fonts/NotoSansJP.ttf", "assets/fonts/NotoSans.ttf"});
    CHECK(ok.settings.fallback_fonts_for("zh-Hans") == std::vector<std::string>{"assets/fonts/NotoSansSC.ttf", "assets/fonts/NotoSans.ttf"});
    CHECK(ok.settings.fallback_fonts_for("en") == std::vector<std::string>{"assets/fonts/NotoSans.ttf"});

    CHECK_FALSE(parse_localization(Json()).settings.enabled());  // no section: localization is off
    const LocalizationParse single = parse_localization(Json::parse(R"({"defaultLanguage":"fr"})"));  // one language is enough
    REQUIRE(single.ok());
    CHECK(single.settings.languages == std::vector<std::string>{"fr"});
    CHECK(parse_localization(Json::parse(R"({"languages":["de","en"]})")).settings.defaultLanguage == "de");  // first by default

    struct Case {
        const char* section;
        const char* pointer;
        const char* message;  // a part of it
    };
    const Case bad[] = {
        {R"("text")", "/localization", "expected an object"},
        {R"({})", "/localization/languages", "missing"},
        {R"({"languages":[]})", "/localization/languages", "non-empty array"},
        {R"({"languages":["en","es","en"]})", "/localization/languages/2", "listed twice"},
        {R"({"languages":["en","pt_br"]})", "/localization/languages/1", "Did you mean \"pt-BR\""},
        {R"({"languages":["en",7]})", "/localization/languages/1", "expected a language tag"},
        {R"({"defaultLanguage":"fr","languages":["en","es"]})", "/localization/defaultLanguage", "not one of \"languages\""},
        {R"({"languages":["en"],"fallbackFonts":"a.ttf"})", "/localization/fallbackFonts", "expected an array of font paths"},
        {R"({"languages":["en"],"fallbackFonts":["a.ttf",""]})", "/localization/fallbackFonts/1", "path of a font file"},
        {R"({"languages":["en"],"fallbackFonts":["C:/Windows/Fonts/a.ttf"]})", "/localization/fallbackFonts/0", "not a path inside the project"},
        {R"({"languages":["en","es"],"languageFonts":{"fr":["a.ttf"]}})", "/localization/languageFonts/fr", "not one of \"languages\""},
        {R"({"languages":["en"],"languageFonts":[]})", "/localization/languageFonts", "expected an object"},
    };
    for (const Case& c : bad) {
        INFO(c.section);
        const LocalizationParse r = parse_localization(Json::parse(c.section));
        REQUIRE_FALSE(r.ok());
        CHECK(r.issues.front().pointer == c.pointer);
        CHECK(r.issues.front().message.find(c.message) != std::string::npos);
        CHECK_FALSE(r.issues.front().hint.empty());
    }

    const LocalizationParse typo = parse_localization(Json::parse(R"({"languages":["en"],"defaultLanguag":"en"})"));
    CHECK(typo.ok());  // an unknown key is a warning with "did you mean"
    REQUIRE(typo.warnings.size() == 1);
    CHECK(typo.warnings[0].pointer == "/localization/defaultLanguag");
    CHECK(typo.warnings[0].message.find("defaultLanguage") != std::string::npos);
}

TEST_CASE("project: load_project reads the localization section, reports the first mistake and keeps it when saving") {
    auto dir = fs::make_temp_dir("fa_loc_project");
    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(), kProject).ok());
    auto loaded = load_project(dir.generic_string());
    REQUIRE(loaded.ok());
    CHECK(loaded->localization.defaultLanguage == "en");
    CHECK(loaded->localization.languages.size() == 3);
    REQUIRE(save_project(dir.generic_string(), *loaded).ok());
    auto again = load_project(dir.generic_string());
    REQUIRE(again.ok());
    CHECK(again->localization.languages == loaded->localization.languages);

    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(),
                           R"({"name":"x","localization":{"languages":["en","es","en"],"fallbackFonts":"a.ttf"}})").ok());
    auto bad = load_project(dir.generic_string());
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/localization/languages/2") != std::string::npos);
    CHECK(bad.error().message.find("1 more") != std::string::npos);
    CHECK_FALSE(bad.error().hint.empty());

    REQUIRE(fs::write_text((dir / "factoria.json").generic_string(), R"({"name":"plain"})").ok());
    CHECK_FALSE(load_project(dir.generic_string())->localization.enabled());
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE("choose_start_language: the override beats the environment, which beats the system, which beats the default") {
    I18n i18n;
    i18n.configure("en", {"en", "es", "pt-BR"});
    const std::vector<std::string> system = {"pt-PT", "es-MX"};
    std::vector<std::string> problems;

    CHECK(choose_start_language(i18n, "", "", false, system, &problems) == "en");  // headless: always the default language
    CHECK(choose_start_language(i18n, "", "", true, system, &problems) == "pt-BR");  // best match of the system languages
    CHECK(choose_start_language(i18n, "", "es", true, system, &problems) == "es");   // FA_LANGUAGE
    CHECK(choose_start_language(i18n, "pt_br", "es", true, system, &problems) == "pt-BR");  // EngineConfig::language, loosely written
    CHECK(choose_start_language(i18n, "", "es", false, system, &problems) == "es");  // the environment also reaches a headless run
    CHECK(choose_start_language(i18n, "", "", true, {"fr-FR", "de"}, &problems) == "en");  // nothing matches: the default
    CHECK(problems.empty());

    CHECK(choose_start_language(i18n, "", "klingon", true, system, &problems) == "pt-BR");  // a wrong override is ignored, with a reason
    REQUIRE(problems.size() == 1);
    CHECK(problems[0].find("FA_LANGUAGE") != std::string::npos);
    CHECK(problems[0].find("klingon") != std::string::npos);

    I18n off;
    CHECK(choose_start_language(off, "es", "es", true, system, nullptr).empty());  // no localization
}

TEST_CASE("engine: a headless game starts in the default language and translates every component with a key") {
    Game g("start");
    Engine& e = g.engine;
    REQUIRE(e.i18n() != nullptr);
    CHECK(e.i18n()->language() == "en");
    CHECK(g.text("title") == "My Game");  // the scene says "scene text": the table wins as soon as the scene is loaded
    CHECK(g.button("play") == "Play");
    CHECK(g.slider("music") == "Music");
    CHECK(g.text("plain") == "no key here");
    CHECK(g.text("lost") == "own text");  // a key no table has keeps the component's own text

    SUBCASE("i18n.set_language rewrites everything at once, also what has no frame yet") {
        Json r = g.call("i18n.set_language", Json{{"language", "es"}});
        CHECK(r["language"] == "es");
        CHECK(r["previous"] == "en");
        CHECK(r["changed"] == true);
        CHECK(g.text("title") == "Mi juego");
        CHECK(g.button("play") == "Jugar");
        CHECK(g.slider("music") == "Música");
        CHECK(g.text("plain") == "no key here");
        CHECK(g.text("lost") == "own text");

        r = g.call("i18n.set_language", Json{{"language", "es-MX"}});  // close enough to "es"
        CHECK(r["language"] == "es");
        CHECK(r["changed"] == false);

        r = g.call("i18n.set_language", Json{{"language", "pt_br"}});
        CHECK(r["language"] == "pt-BR");
        CHECK(g.button("play") == "Jogar");
        CHECK(g.slider("music") == "Music");  // pt-BR has no "menu.music": the default language answers
    }

    SUBCASE("an unknown language is a teaching error and changes nothing") {
        Json r = g.call("i18n.set_language", Json{{"language", "ess"}});
        REQUIRE(r.contains("error"));
        const std::string message = r["error"]["message"];
        CHECK(message.find("Unknown language 'ess'") != std::string::npos);
        CHECK(message.find("es") != std::string::npos);
        CHECK_FALSE(r["error"]["hint"].get<std::string>().empty());
        CHECK(e.i18n()->language() == "en");
        CHECK(g.call("i18n.set_language").contains("error"));  // `language` is required
    }

    SUBCASE("a text a script or a command changed is translated again, a key that is removed leaves the text alone") {
        g.call("scene.set_component", Json{{"id", "title"}, {"component", "Text"}, {"fields", Json{{"text", "changed"}}}});
        e.step(1);
        CHECK(g.text("title") == "My Game");
        g.call("scene.set_component", Json{{"id", "title"}, {"component", "Text"}, {"fields", Json{{"key", ""}, {"text", "free text"}}}});
        e.step(1);
        CHECK(g.text("title") == "free text");
    }

    SUBCASE("a spawned entity with a key is translated before it is drawn") {
        g.call("i18n.set_language", Json{{"language", "es"}});
        Json r = g.call("scene.spawn", Json{{"name", "late"}, {"components", Json{{"Button", Json{{"text", "x"}, {"key", "menu.play"}}}}}});
        REQUIRE(r.contains("id"));
        e.step(1);
        CHECK(e.world().get<Button>(e.world().find_by_id(r["id"].get<std::string>()))->text == "Jugar");
    }

    SUBCASE("loading a scene applies the current language to it") {
        g.call("i18n.set_language", Json{{"language", "es"}});
        REQUIRE(e.commands().call("scene.reload", Json::object()).ok);
        CHECK(g.text("title") == "Mi juego");
    }
}

TEST_CASE("engine: i18n.state lists the languages, their tables and what each lacks") {
    Game g("state");
    Json s = g.call("i18n.state");
    CHECK(s["enabled"] == true);
    CHECK(s["default"] == "en");
    CHECK(s["current"] == "en");
    CHECK(s["systemLanguages"].empty());  // headless: the machine's language is not reported
    REQUIRE(s["languages"].size() == 3);
    CHECK(s["languages"][0]["code"] == "en");
    CHECK(s["languages"][0]["name"] == "English");
    CHECK(s["languages"][0]["file"] == "locales/en.json");
    CHECK(s["languages"][0]["loaded"] == true);
    CHECK(s["languages"][0]["missing"] == 0);
    CHECK(s["languages"][1]["name"] == "Español");
    CHECK(s["languages"][1]["missing"] == 1);  // "only_en"
    CHECK(s["languages"][1]["missingKeys"][0] == "only_en");
    CHECK(s["languages"][2]["keys"] == 2);
    CHECK(s["languages"][2]["missing"] == 2);  // menu.music and only_en

    const CommandInfo* info = g.engine.commands().info("i18n.state");
    REQUIRE(info != nullptr);
    CHECK(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    const CommandInfo* set = g.engine.commands().info("i18n.set_language");
    REQUIRE(set != nullptr);
    CHECK_FALSE(set->readOnly);
    CHECK(set->description.find("Example") != std::string::npos);
}

TEST_CASE("engine: a game without a \"localization\" section is not localized and says how to turn it on") {
    Game g("off", R"({"name":"Plain","mainScene":"scenes/main.scene.json","display":{"width":320,"height":180}})", {}, false);
    CHECK_FALSE(g.engine.i18n()->enabled());
    CHECK(g.text("title") == "scene text");  // untouched; the missing table is warned about once, not a failure
    Json s = g.call("i18n.state");
    CHECK(s["enabled"] == false);
    CHECK(s["hint"].get<std::string>().find("localization") != std::string::npos);
    Json r = g.call("i18n.set_language", Json{{"language", "es"}});
    REQUIRE(r.contains("error"));
    CHECK(r["error"]["message"].get<std::string>().find("Localization is off") != std::string::npos);
}

TEST_CASE("engine: EngineConfig::language and FA_LANGUAGE choose the start language, a wrong one is reported and ignored") {
    {
        EngineConfig cfg;
        cfg.language = "es";
        Game g("cfg_language", kProject, cfg);
        CHECK(g.engine.i18n()->language() == "es");
        CHECK(g.text("title") == "Mi juego");
    }
    {
        ScopedEnv env("FA_LANGUAGE", "pt-BR");
        Game g("env_language");
        CHECK(g.engine.i18n()->language() == "pt-BR");
    }
    {
        ScopedEnv env("FA_LANGUAGE", "pt-BR");
        EngineConfig cfg;
        cfg.language = "es";
        Game g("cfg_beats_env", kProject, cfg);
        CHECK(g.engine.i18n()->language() == "es");
    }
    {
        ScopedEnv env("FA_LANGUAGE", "klingon");
        Game g("env_wrong");
        CHECK(g.engine.i18n()->language() == "en");
        const Json info = g.call("engine.info");
        REQUIRE(info.contains("startupProblems"));
        CHECK(info["startupProblems"][0].get<std::string>().find("FA_LANGUAGE") != std::string::npos);
    }
    {
        ScopedEnv env("FA_LANGUAGE", "es");
        EngineConfig cfg;
        cfg.editorMode = true;  // the editor saves the default language's text into scenes
        Game g("editor", kProject, cfg);
        CHECK(g.engine.i18n()->language() == "en");
    }
}

TEST_CASE("engine: a missing or broken string table is reported and the game falls back to the default language") {
    Game g("broken", kProject, {}, false);
    CHECK(g.engine.i18n()->language() == "en");
    const Json info = g.call("engine.info");
    REQUIRE(info.contains("startupProblems"));
    CHECK(info["startupProblems"].size() == 3);  // one per missing locales/<language>.json
    CHECK(info["startupProblems"][0].get<std::string>().find("locales/en.json") != std::string::npos);
    CHECK(g.text("title") == "scene text");  // no table has the key: the component keeps its own text
    Json s = g.call("i18n.state");
    CHECK(s["languages"][0]["loaded"] == false);
}

TEST_CASE("engine: editing locales/<language>.json while the game runs reloads the tables") {
    Game g("hot", kProject, {}, true, true);
    g.call("i18n.set_language", Json{{"language", "es"}});
    CHECK(g.text("title") == "Mi juego");
    g.write("locales/es.json", R"({ "$name": "Español", "menu": { "title": "Mi videojuego", "play": "Jugar", "music": "Música" } })");
    const auto future = stdfs::file_time_type::clock::now() + std::chrono::seconds(10);  // whatever the file system's resolution
    stdfs::last_write_time(g.dir / "locales" / "es.json", future);
    g.engine.step(30);  // the watcher polls four times a second
    CHECK(g.text("title") == "Mi videojuego");
    CHECK(g.engine.i18n()->language() == "es");
}
