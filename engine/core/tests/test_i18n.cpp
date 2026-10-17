#include <doctest.h>

#include <chrono>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/i18n.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A project folder with locales/*.json, set as the project root for the test.
struct Locales {
    stdfs::path dir, oldRoot;
    Locales() {
        oldRoot = fs::project_root();
        dir = stdfs::temp_directory_path() / ("fa_test_i18n_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        stdfs::remove_all(dir);
        stdfs::create_directories(dir / "locales");
        fs::set_project_root(dir);
    }
    ~Locales() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& language, const std::string& json) { REQUIRE(fs::write_text("locales/" + language + ".json", json).ok()); }
};

StringTable table_of(const char* language, const char* json) {
    auto doc = parse_json(json, "test");
    REQUIRE(doc.ok());
    auto t = parse_string_table(doc.value(), language, std::string("locales/") + language + ".json");
    REQUIRE_MESSAGE(t.ok(), std::string(t.ok() ? "" : t.error().to_string()));
    return std::move(t.value());
}

I18n game(std::initializer_list<std::pair<const char*, const char*>> tables, const char* def = "en", std::vector<std::string> languages = {}) {
    if (languages.empty())
        for (const auto& t : tables) languages.emplace_back(t.first);
    I18n i;
    i.configure(def, languages);
    for (const auto& t : tables) REQUIRE(i.add_table(table_of(t.first, t.second)).ok());
    return i;
}

}  // namespace

TEST_CASE("i18n: language tags are normalized") {
    CHECK(normalize_language_tag("es_ES.UTF-8") == "es-ES");
    CHECK(normalize_language_tag("pt_br") == "pt-BR");
    CHECK(normalize_language_tag("ZH-hant-tw") == "zh-Hant-TW");
    CHECK(normalize_language_tag("es-419") == "es-419");
    CHECK(normalize_language_tag("en-US-u-nu-latn") == "en-US");
    CHECK(normalize_language_tag("sr_RS@latin") == "sr-RS");
    CHECK(normalize_language_tag("C") == "");
    CHECK(normalize_language_tag("POSIX") == "");
    CHECK(normalize_language_tag("") == "");
    CHECK(normalize_language_tag("english") == "");
    CHECK(is_language_tag("pt-BR"));
    CHECK(is_language_tag("zh-Hans"));
    CHECK_FALSE(is_language_tag("pt-br"));
    CHECK_FALSE(is_language_tag("pt_BR"));
    CHECK_FALSE(is_language_tag(""));
    CHECK(base_language("zh-Hans-CN") == "zh-Hans");
    CHECK(base_language("zh-Hans") == "zh");
    CHECK(base_language("zh").empty());
}

TEST_CASE("i18n: the system languages are matched to the project's") {
    const std::vector<std::string> project = {"en", "es", "pt-BR", "zh-Hans", "zh-Hant", "fr-CA"};
    CHECK(best_language_match({"es"}, project) == "es");
    CHECK(best_language_match({"es-MX"}, project) == "es");           // base language
    CHECK(best_language_match({"pt-PT"}, project) == "pt-BR");        // another variant of the language
    CHECK(best_language_match({"pt"}, project) == "pt-BR");
    CHECK(best_language_match({"fr-FR"}, project) == "fr-CA");
    CHECK(best_language_match({"zh-CN"}, project) == "zh-Hans");
    CHECK(best_language_match({"zh-SG"}, project) == "zh-Hans");
    CHECK(best_language_match({"zh-TW"}, project) == "zh-Hant");
    CHECK(best_language_match({"zh-HK"}, project) == "zh-Hant");
    CHECK(best_language_match({"zh-MO"}, project) == "zh-Hant");
    CHECK(best_language_match({"zh-Hant-TW"}, project) == "zh-Hant");  // language + script
    CHECK(best_language_match({"PT_br"}, project) == "pt-BR");        // spelling and case
    CHECK(best_language_match({"de-DE", "es-ES", "en"}, project) == "es");  // the first language that matches, in the user's order
    CHECK(best_language_match({"de", "ja"}, project).empty());
    CHECK(best_language_match({}, project).empty());
    CHECK(best_language_match({"es"}, {}).empty());
    // Simplified and Traditional Chinese are not the same language: no guessing between them.
    CHECK(best_language_match({"zh-TW"}, {"en", "zh-Hans"}).empty());
    CHECK(best_language_match({"zh-CN"}, {"en", "zh"}) == "zh");
    CHECK(best_language_match({"zh-CN"}, {"en", "zh-CN"}) == "zh-CN");
    CHECK(best_language_match({"zh-SG"}, {"en", "zh-CN"}) == "zh-CN");  // same script, other region
}

TEST_CASE("i18n: CLDR plural categories per language") {
    using PC = PluralCategory;
    const auto cat = [](const char* lang, double n) { return plural_category(lang, n); };
    // English-like: one / other.
    for (const char* lang : {"en", "de", "nl", "tr", "sv", "xx"}) {
        CHECK(cat(lang, 1) == PC::One);
        CHECK(cat(lang, 0) == PC::Other);
        CHECK(cat(lang, 2) == PC::Other);
        CHECK(cat(lang, 1.5) == PC::Other);
    }
    CHECK(cat("en-GB", 1) == PC::One);
    // Spanish and Italian: one for 1, many for whole millions.
    CHECK(cat("es", 1) == PC::One);
    CHECK(cat("es", 0) == PC::Other);
    CHECK(cat("es", 1000000) == PC::Many);
    CHECK(cat("it", 1) == PC::One);
    CHECK(cat("it", 2000000) == PC::Many);
    // French and Brazilian Portuguese: 0 and 1 (and 1.5) are one; Portugal's Portuguese is like English.
    CHECK(cat("fr", 0) == PC::One);
    CHECK(cat("fr", 1) == PC::One);
    CHECK(cat("fr", 1.5) == PC::One);
    CHECK(cat("fr", 2) == PC::Other);
    CHECK(cat("fr", 1000000) == PC::Many);
    CHECK(cat("pt", 0) == PC::One);
    CHECK(cat("pt-BR", 1) == PC::One);
    CHECK(cat("pt", 2) == PC::Other);
    CHECK(cat("pt-PT", 0) == PC::Other);
    CHECK(cat("pt-PT", 1) == PC::One);
    // Slavic: one / few / many / other.
    for (const char* lang : {"ru", "uk"}) {
        CHECK(cat(lang, 1) == PC::One);
        CHECK(cat(lang, 21) == PC::One);
        CHECK(cat(lang, 11) == PC::Many);
        CHECK(cat(lang, 2) == PC::Few);
        CHECK(cat(lang, 24) == PC::Few);
        CHECK(cat(lang, 12) == PC::Many);
        CHECK(cat(lang, 14) == PC::Many);
        CHECK(cat(lang, 0) == PC::Many);
        CHECK(cat(lang, 5) == PC::Many);
        CHECK(cat(lang, 100) == PC::Many);
        CHECK(cat(lang, 102) == PC::Few);
        CHECK(cat(lang, 1.5) == PC::Other);
    }
    CHECK(cat("pl", 1) == PC::One);
    CHECK(cat("pl", 21) == PC::Many);  // unlike Russian
    CHECK(cat("pl", 22) == PC::Few);
    CHECK(cat("pl", 12) == PC::Many);
    CHECK(cat("pl", 0) == PC::Many);
    CHECK(cat("pl", 5) == PC::Many);
    CHECK(cat("pl", 1.5) == PC::Other);
    CHECK(cat("cs", 1) == PC::One);
    CHECK(cat("cs", 3) == PC::Few);
    CHECK(cat("cs", 5) == PC::Other);
    CHECK(cat("cs", 0) == PC::Other);
    CHECK(cat("cs", 1.5) == PC::Many);
    // Arabic: all six.
    CHECK(cat("ar", 0) == PC::Zero);
    CHECK(cat("ar", 1) == PC::One);
    CHECK(cat("ar", 2) == PC::Two);
    CHECK(cat("ar", 3) == PC::Few);
    CHECK(cat("ar", 10) == PC::Few);
    CHECK(cat("ar", 11) == PC::Many);
    CHECK(cat("ar", 99) == PC::Many);
    CHECK(cat("ar", 100) == PC::Other);
    CHECK(cat("ar", 102) == PC::Other);
    CHECK(cat("ar", 103) == PC::Few);
    CHECK(cat("ar", 1.5) == PC::Other);
    // Hebrew: one, two, other.
    CHECK(cat("he", 1) == PC::One);
    CHECK(cat("he", 2) == PC::Two);
    CHECK(cat("he", 3) == PC::Other);
    CHECK(cat("he", 0) == PC::Other);
    // Languages with a single form.
    for (const char* lang : {"ja", "zh", "zh-Hans", "ko", "vi", "id"}) {
        CHECK(cat(lang, 1) == PC::Other);
        CHECK(cat(lang, 0) == PC::Other);
        CHECK(cat(lang, 5) == PC::Other);
    }
    CHECK(cat("en", -1) == PC::One);  // the sign does not matter
}

TEST_CASE("i18n: plural_categories lists the forms a language needs, and with everyCount the ones only fractions or millions pick") {
    using PC = PluralCategory;
    const auto forms = [](const char* lang, bool every = false) { return plural_categories(lang, every); };
    CHECK(forms("en") == std::vector<PC>{PC::One, PC::Other});
    CHECK(forms("ja") == std::vector<PC>{PC::Other});
    CHECK(forms("zh-Hans") == std::vector<PC>{PC::Other});
    CHECK(forms("ru") == std::vector<PC>{PC::One, PC::Few, PC::Many, PC::Other});
    CHECK(forms("ar") == std::vector<PC>{PC::Zero, PC::One, PC::Two, PC::Few, PC::Many, PC::Other});
    CHECK(forms("he") == std::vector<PC>{PC::One, PC::Two, PC::Other});
    // "many" of es / fr is for whole millions, of cs for fractions: not needed, but not a mistake.
    CHECK(forms("es") == std::vector<PC>{PC::One, PC::Other});
    CHECK(forms("es", true) == std::vector<PC>{PC::One, PC::Many, PC::Other});
    CHECK(forms("fr", true) == std::vector<PC>{PC::One, PC::Many, PC::Other});
    CHECK(forms("cs") == std::vector<PC>{PC::One, PC::Few, PC::Other});
    CHECK(forms("cs", true) == std::vector<PC>{PC::One, PC::Few, PC::Many, PC::Other});
    CHECK(forms("en", true) == std::vector<PC>{PC::One, PC::Other});
}

TEST_CASE("i18n: nested keys flatten to dotted keys, plural entries and metadata") {
    StringTable t = table_of("es", R"({
        "$name": "Español", "$comment": 12,
        "menu": { "play": "Jugar", "options": { "title": "Opciones" } },
        "flat.key": "plano",
        "coins": { "one": "{count} moneda", "other": "{count} monedas" },
        "group": { "$note": "x", "one": "uno", "other": "otro" }
    })");
    CHECK(t.name == "Español");
    CHECK(t.entries.at("menu.play").text == "Jugar");
    CHECK(t.entries.at("menu.options.title").text == "Opciones");
    CHECK(t.entries.at("flat.key").text == "plano");
    REQUIRE(t.entries.at("coins").plural());
    CHECK(t.entries.at("coins").forms.at(PluralCategory::One) == "{count} moneda");
    CHECK(t.entries.at("group").plural());
    CHECK(t.entries.count("$name") == 0);
    CHECK(t.entries.count("$comment") == 0);
    CHECK(t.entries.count("menu") == 0);
    CHECK(t.entries.size() == 5);
    // Where each entry is in the file, as a JSON pointer (escaped): `factoria validate` and the translation import use it.
    CHECK(t.entries.at("menu.play").pointer == "/menu/play");
    CHECK(t.entries.at("menu.options.title").pointer == "/menu/options/title");
    CHECK(t.entries.at("flat.key").pointer == "/flat.key");
    CHECK(t.entries.at("coins").pointer == "/coins");
}

TEST_CASE("i18n: a bad table is a teaching error with file and JSON pointer") {
    const auto error_of = [](const char* json) {
        auto doc = parse_json(json, "x");
        REQUIRE(doc.ok());
        auto t = parse_string_table(doc.value(), "es", "locales/es.json");
        REQUIRE_FALSE(t.ok());
        return t.error();
    };
    Error e = error_of(R"({"menu": {"play": 3}})");
    CHECK(e.message.find("locales/es.json#/menu/play") != std::string::npos);
    CHECK(e.message.find("expected a string") != std::string::npos);
    CHECK(e.hint.find("placeholders") != std::string::npos);
    e = error_of(R"({"a": [1, 2]})");
    CHECK(e.message.find("locales/es.json#/a") != std::string::npos);
    e = error_of(R"({"menu": {"back": "Volver", "a~b/c": true}})");
    CHECK(e.message.find("locales/es.json#/menu/a~0b~1c") != std::string::npos);  // pointer escapes
    e = error_of(R"({"coins": {"one": "{count} moneda"}})");
    CHECK(e.message.find("no \"other\" form") != std::string::npos);
    CHECK(e.message.find("locales/es.json#/coins") != std::string::npos);
    e = error_of(R"({"coins": {"one": "uno", "other": 5}})");
    CHECK(e.message.find("locales/es.json#/coins/other") != std::string::npos);
    e = error_of(R"({"a.b": "x", "a": {"b": "y"}})");
    CHECK(e.message.find("written twice") != std::string::npos);
    e = error_of(R"({"$name": 5})");
    CHECK(e.message.find("#/$name") != std::string::npos);
    e = error_of(R"([1])");
    CHECK(e.message.find("must be a JSON object") != std::string::npos);
    e = error_of(R"({"": "x"})");
    CHECK(e.message.find("empty key") != std::string::npos);
}

TEST_CASE("i18n: {placeholders} take their value from the arguments") {
    std::vector<std::string> missing;
    CHECK(format_message("Hello {name}, {n} coins", Json{{"name", "Ana"}, {"n", 3}}) == "Hello Ana, 3 coins");
    CHECK(format_message("{a}{b}", Json{{"a", "x"}, {"b", "y"}}) == "xy");
    CHECK(format_message("{n}", Json{{"n", 2.0}}) == "2");  // a script number that happens to be whole
    CHECK(format_message("{n}", Json{{"n", 2.5}}) == "2.5");
    CHECK(format_message("{on} {off} {nothing}", Json{{"on", true}, {"off", false}, {"nothing", nullptr}}) == "true false ");
    CHECK(format_message("{{literal}} and {{{n}}}", Json{{"n", 7}}) == "{literal} and {7}");
    CHECK(format_message("a { b } {} {x-y} {", Json::object()) == "a { b } {} {x-y} {");  // not placeholders
    CHECK(format_message("no braces", nullptr) == "no braces");
    CHECK(format_message("{n} left", nullptr, &missing) == "{n} left");  // stays visible
    REQUIRE(missing.size() == 1);
    CHECK(missing[0] == "n");
    CHECK(format_message("{0} then {1}", Json{{"0", "a"}, {"1", "b"}}) == "a then b");
}

TEST_CASE("i18n: lookup falls back from the language to its base language to the default") {
    I18n i = game({{"en", R"({"a": "A", "b": "B", "c": "C", "d": "D"})"},
                   {"pt", R"({"a": "A-pt", "b": "B-pt", "c": "C-pt"})"},
                   {"pt-BR", R"({"a": "A-br", "b": "B-br"})"}},
                  "en");
    REQUIRE(i.set_language("pt-BR").ok());
    CHECK(i.t("a") == "A-br");
    CHECK(i.t("b") == "B-br");
    CHECK(i.t("c") == "C-pt");  // base language
    CHECK(i.t("d") == "D");     // default language
    CHECK(i.has("d"));
    CHECK_FALSE(i.has("zzz"));
    CHECK(i.t("zzz") == "zzz");  // missing everywhere: the key itself
    CHECK_FALSE(i.translate("zzz").has_value());
    REQUIRE(i.set_language("en").ok());
    CHECK(i.t("a") == "A");
    CHECK(i.language() == "en");
}

TEST_CASE("i18n: set_language resolves tags and teaches on a mistake") {
    I18n i = game({{"en", R"({})"}, {"es", R"({})"}, {"zh-Hans", R"({})"}}, "en");
    CHECK(i.resolve_language("es").value() == "es");
    CHECK(i.resolve_language("ES").value() == "es");
    CHECK(i.resolve_language("es_MX").value() == "es");
    CHECK(i.resolve_language("zh-CN").value() == "zh-Hans");
    auto bad = i.set_language("esp");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("Unknown language 'esp'") != std::string::npos);
    CHECK(bad.error().message.find("Did you mean 'es'?") != std::string::npos);
    CHECK(bad.error().message.find("Valid: en, es, zh-Hans") != std::string::npos);
    CHECK(i.language() == "en");  // unchanged
    REQUIRE(i.set_language("en").ok());
    REQUIRE(i.set_language("es").ok());
    CHECK(i.language() == "es");

    I18n off;  // no localization section
    CHECK_FALSE(off.enabled());
    auto none = off.set_language("en");
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message.find("Localization is off") != std::string::npos);
    CHECK(off.t("menu.play") == "menu.play");
}

TEST_CASE("i18n: plural entries pick the form of args.count in the language of the table") {
    I18n i = game({{"en", R"({"coins": {"one": "{count} coin", "other": "{count} coins"}, "only": {"other": "x{count}"}})"},
                   {"ru", R"({"coins": {"one": "{count} монета", "few": "{count} монеты", "many": "{count} монет", "other": "{count} монеты"}})"},
                   {"ar", R"({"coins": {"zero": "z", "one": "o", "two": "tw", "few": "f", "many": "m", "other": "ot"}})"}},
                  "en");
    CHECK(i.t("coins", Json{{"count", 1}}) == "1 coin");
    CHECK(i.t("coins", Json{{"count", 5}}) == "5 coins");
    CHECK(i.t("coins", Json{{"count", 0}}) == "0 coins");
    CHECK(i.t("only", Json{{"count", 1}}) == "x1");  // a missing form falls to "other"
    REQUIRE(i.set_language("ru").ok());
    CHECK(i.t("coins", Json{{"count", 1}}) == "1 монета");
    CHECK(i.t("coins", Json{{"count", 3}}) == "3 монеты");
    CHECK(i.t("coins", Json{{"count", 11}}) == "11 монет");
    CHECK(i.t("coins", Json{{"count", 21}}) == "21 монета");
    CHECK(i.t("coins", Json{{"count", 2.5}}) == "2.5 монеты");
    CHECK(i.t("only", Json{{"count", 3}}) == "x3");  // found in the default language: English rules
    REQUIRE(i.set_language("ar").ok());
    CHECK(i.t("coins", Json{{"count", 0}}) == "z");
    CHECK(i.t("coins", Json{{"count", 2}}) == "tw");
    CHECK(i.t("coins", Json{{"count", 7}}) == "f");
    CHECK(i.t("coins", Json{{"count", 50}}) == "m");
    CHECK(i.t("coins", Json{{"count", 100}}) == "ot");
    CHECK(i.t("coins") == "ot");  // no count: "other"
    CHECK(i.t("coins", Json{{"count", "many"}}) == "ot");
}

TEST_CASE("i18n: names, missing keys and the load of locales/*.json through fs") {
    Locales files;
    files.write("en", R"({"$name": "English", "a": "A", "b": "B", "nested": {"c": "C"}})");
    files.write("es", R"({"$name": "Español", "a": "A-es"})");
    // "fr" has no file; "de" does not parse; "it" has a number.
    files.write("de", R"({"a": )");
    files.write("it", R"({"a": 3})");
    I18n i;
    i.configure("en", {"en", "es", "fr", "de", "it"});
    std::vector<I18n::Problem> problems = i.load_tables();
    REQUIRE(problems.size() == 3);
    bool sawMissing = false, sawSyntax = false, sawValue = false;
    for (const auto& p : problems) {
        if (p.text.find("locales/fr.json does not exist") != std::string::npos) {
            sawMissing = true;
            CHECK(p.level == LogLevel::Warn);
        }
        if (p.text.find("locales/de.json:1") != std::string::npos) {
            sawSyntax = true;
            CHECK(p.level == LogLevel::Error);
        }
        if (p.text.find("locales/it.json#/a") != std::string::npos) {
            sawValue = true;
            CHECK(p.level == LogLevel::Error);
        }
    }
    CHECK(sawMissing);
    CHECK(sawSyntax);
    CHECK(sawValue);
    CHECK(i.name("es") == "Español");
    CHECK(i.name("en") == "English");
    CHECK(i.name("fr") == "fr");  // no table: the tag
    CHECK(i.table("de") == nullptr);
    REQUIRE(i.set_language("fr").ok());  // declared, without a table: the default's strings
    CHECK(i.t("a") == "A");
    CHECK(i.missing_keys("es") == std::vector<std::string>{"b", "nested.c"});
    CHECK(i.missing_keys("en").empty());
    CHECK(i.missing_keys("fr") == std::vector<std::string>{"a", "b", "nested.c"});
    // Editing a file and loading again (hot reload).
    files.write("es", R"({"$name": "Español", "a": "A-es", "b": "B-es", "nested": {"c": "C-es"}})");
    i.load_tables();
    CHECK(i.missing_keys("es").empty());
}

TEST_CASE("i18n: a language with a table of the wrong name is refused") {
    I18n i;
    i.configure("en", {"en"});
    StringTable t;
    t.language = "es";
    auto r = i.add_table(t);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("not one of the game's languages") != std::string::npos);
}
