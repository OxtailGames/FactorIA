// Localization of a running game: the start language, the pass that writes translations into Text and widgets, language changes
// and the i18n.* commands. The string tables and their lookup are fa/core/i18n.h; docs/LOCALIZATION.md describes it all.
#include <algorithm>
#include <cstdlib>

#include "engine_impl.h"
#include "fa/core/log.h"
#include "fa/platform/system_language.h"
#include "fa/runtime/localization.h"
#include "fa/scene/localize.h"

namespace fa {

std::string choose_start_language(const I18n& i18n, std::string_view configured, std::string_view environment, bool followSystem,
                                  const std::vector<std::string>& systemLanguages, std::vector<std::string>* problems) {
    if (!i18n.enabled()) return {};
    const std::pair<const char*, std::string_view> overrides[] = {{"EngineConfig::language", configured}, {"FA_LANGUAGE", environment}};
    for (const auto& [what, value] : overrides) {
        if (value.empty()) continue;
        auto language = i18n.resolve_language(value);
        if (language.ok()) return language.value();
        if (problems) problems->push_back(std::string(what) + " is ignored: " + language.error().to_string());
    }
    if (followSystem)
        if (std::string match = best_language_match(systemLanguages, i18n.languages()); !match.empty()) return match;
    return i18n.default_language();
}

void Engine::Impl::setup_localization() {
    const LocalizationSettings& loc = project.localization;
    i18n.configure(loc.defaultLanguage, loc.languages);
    if (!i18n.enabled()) return;
    for (const I18n::Problem& p : i18n.load_tables()) {
        fa::log(p.level, "i18n", p.text);
        startupProblems.push_back("i18n: " + p.text);
    }
    // The editor ignores FA_LANGUAGE: what it saves into scenes must be the default language's text.
    const bool followSystem = windowed && !cfg.editorMode;
    const char* env = cfg.editorMode ? nullptr : std::getenv("FA_LANGUAGE");
    std::vector<std::string> problems;
    const std::string start = choose_start_language(i18n, cfg.language, env ? env : "", followSystem,
                                                    followSystem ? system_languages() : std::vector<std::string>{}, &problems);
    for (const std::string& problem : problems) {
        FA_WARN("i18n", "{}", problem);
        startupProblems.push_back("i18n: " + problem);
    }
    if (auto set = i18n.set_language(start); !set.ok()) FA_WARN("i18n", "{}", set.error().to_string());  // not reachable: start is one of the languages
    FA_INFO("i18n", "Language {} (default {}; the game has {} language(s))", i18n.language(), i18n.default_language(), i18n.languages().size());
}

void Engine::Impl::reload_localization() {
    for (const I18n::Problem& p : i18n.load_tables()) fa::log(p.level, "i18n", p.text);
    apply_localization();
    if (renderer) renderStale = true;
}

void Engine::Impl::apply_localization() {
    world.set_rtl(i18n.rtl());
    localize_world(world, i18n);
}

Result<std::string> Engine::Impl::switch_language(std::string_view requested) {
    const std::string previous = i18n.language();
    auto language = i18n.set_language(requested);
    if (!language.ok() || language.value() == previous) return language;
    apply_fallback_fonts();
    apply_localization();
    world.events().game.push_back(
        GameEvent{"i18n.change", Json::object({{"language", language.value()}, {"previous", previous}}), kNullEntity});
    if (renderer) renderStale = true;  // OnDemand: what was drawn is outdated
    FA_INFO("i18n", "Language {} -> {}", previous, language.value());
    return language;
}

// The renderer falls back to the fonts of the language in use, so a Japanese table draws with the Japanese font while every Text
// keeps `font: ""`. Called when the renderer is created (the start language is chosen before it exists) and on every switch.
void Engine::Impl::apply_fallback_fonts() {
    if (renderer && i18n.enabled()) renderer->set_fallback_fonts(project.localization.fallback_fonts_for(i18n.language()));
}

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

}  // namespace

void register_i18n_commands(Engine&, Engine::Impl& I) {
    I.commands.add(
        {"i18n.state", "Show the languages of the game: which is current, which strings each lacks compared with the default language.",
         "Returns {enabled, default, current, languages: [{code, name, file, loaded, keys, missing, missingKeys}], systemLanguages}. "
         "`enabled` is false when factoria.json has no \"localization\" section (then there is nothing else). Each language has one "
         "string table, file locales/<code>.json; `loaded` is false when the file is missing or broken (its strings come from the "
         "fallback languages: see the log). `keys` counts the strings of the table, `missing` the keys of the default language's "
         "table that this one lacks (missingKeys lists up to 20 of them), `name` is the table's \"$name\" or the code. "
         "systemLanguages is the player's system languages in a game with its own window and empty in headless runs. "
         "Example: i18n.state {}",
         parse_schema(R"({"type":"object","properties":{}})"), true, "i18n"},
        [&I](const Json&) {
            Json out = Json::object({{"enabled", I.i18n.enabled()}});
            if (!I.i18n.enabled()) {
                out["hint"] = "factoria.json has no \"localization\" section: add {\"defaultLanguage\": \"en\", \"languages\": [\"en\", \"es\"]} "
                              "and a locales/<language>.json per language (docs/LOCALIZATION.md).";
                return out;
            }
            out["default"] = I.i18n.default_language();
            out["current"] = I.i18n.language();
            Json languages = Json::array();
            for (const std::string& code : I.i18n.languages()) {
                const StringTable* table = I.i18n.table(code);
                Json entry = Json::object({{"code", code}, {"name", I.i18n.name(code)}, {"file", "locales/" + code + ".json"},
                                           {"loaded", table != nullptr}, {"keys", table ? table->entries.size() : 0}});
                const std::vector<std::string> missing = I.i18n.missing_keys(code);
                entry["missing"] = missing.size();
                Json sample = Json::array();
                for (std::size_t i = 0; i < missing.size() && i < 20; ++i) sample.push_back(missing[i]);
                entry["missingKeys"] = sample;
                languages.push_back(std::move(entry));
            }
            out["languages"] = languages;
            Json system = Json::array();
            if (I.windowed && !I.cfg.editorMode)
                for (const std::string& tag : system_languages()) system.push_back(tag);
            out["systemLanguages"] = system;
            return out;
        });

    I.commands.add(
        {"i18n.set_language", "Switch the game to another language now: every Text and widget with a key is rewritten at once.",
         "`language` is one of the game's languages (see i18n.state), written as in factoria.json or close to it (\"pt_br\", "
         "\"es-MX\" -> \"es\", \"zh-CN\" -> \"zh-Hans\"). Sends the game event \"i18n.change\" {language, previous} to the scripts "
         "(`i18n.on(\"change\", fn)`). The choice is not saved: a game keeps the player's choice with `storage` and calls "
         "i18n.setLanguage at start (docs/LOCALIZATION.md). Returns {language, previous, changed}. Example: i18n.set_language "
         "{\"language\": \"es\"}",
         parse_schema(R"({"type":"object","required":["language"],"properties":{
             "language":{"type":"string","description":"A language of factoria.json localization.languages, e.g. \"es\" or \"pt-BR\"."}}})"),
         false, "i18n"},
        [&I](const Json& a) {
            if (!a.contains("language") || !a["language"].is_string())
                throw CommandError("invalid_argument", "Missing string argument 'language'.", "Use i18n.state to see the game's languages.");
            const std::string previous = I.i18n.language();
            auto language = I.switch_language(a["language"].get<std::string>());
            if (!language.ok()) throw CommandError("invalid_argument", language.error().message, language.error().hint);
            return Json::object({{"language", language.value()}, {"previous", previous}, {"changed", language.value() != previous}});
        });
}

}  // namespace fa
