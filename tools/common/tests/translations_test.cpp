// i18n.export and i18n.import: CSV and XLIFF files for translators and what they put back into locales/<language>.json.
#include <doctest.h>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/translations.h"
#include "test_helpers.h"

using namespace fa;

namespace {

// A nested English table, a nested Spanish table that is partly translated, and a flat Russian one (which needs four plural forms).
const char* kEn = R"({
  "$name": "English",
  "menu": { "play": "Play", "quit": "Quit, \"now\"", "multi": "Line one\nLine two" },
  "greeting": "Hello, {name}!",
  "coins": { "one": "{count} coin", "other": "{count} coins" },
  "tag": "A & B <tag>"
})";
const char* kEs = R"({
  "$name": "Español",
  "menu": { "play": "Jugar" },
  "coins": { "one": "{count} moneda", "other": "{count} monedas" }
})";
const char* kRu = R"({ "menu.play": "Играть" })";

struct Game {
    testing::TempDir tmp;
    std::string dir;
    CommandRegistry registry;

    explicit Game(const char* en = kEn, const char* es = kEs, const char* ru = kRu) {
        REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
        dir = tmp.sub("game");
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["localization"] = *parse_json(R"({"defaultLanguage": "en", "languages": ["en", "es", "ru"]})");
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
        if (en) testing::write_all(dir + "/locales/en.json", en);
        if (es) testing::write_all(dir + "/locales/es.json", es);
        if (ru) testing::write_all(dir + "/locales/ru.json", ru);
        register_translation_commands(registry, dir);
    }
    CommandResult call(const char* name, const Json& args) { return registry.call(name, args); }
    Json table(const char* language) {
        auto j = parse_json(testing::read_all(dir + "/locales/" + language + ".json"), language);
        REQUIRE(j.ok());
        return *j;
    }
    std::string raw(const std::string& rel) { return testing::read_all(dir + "/" + rel); }
};

std::vector<std::string> keys_of(const Json& object) {
    std::vector<std::string> keys;
    for (auto it = object.begin(); it != object.end(); ++it) keys.push_back(it.key());
    return keys;
}

// The texts of one language of a translator's file, by key.
std::map<std::string, std::string> column(const TranslationFile& file, const std::string& language) {
    std::map<std::string, std::string> out;
    for (const TranslationRow& row : file.rows.at(language)) out[row.key] = row.text;
    return out;
}

// What a translator does to an exported CSV: reads it, fills cells, writes it back (as a spreadsheet would).
std::string translate_csv(const std::string& exported, const std::map<std::string, std::map<std::string, std::string>>& fills) {
    auto file = read_csv(exported);
    REQUIRE(file.ok());
    TranslationSheet sheet;
    sheet.sourceLanguage = "en";
    sheet.languages = {"es", "ru"};
    for (const TranslationRow& source : file->rows.at("en")) {
        TranslationSheet::Row row;
        row.key = source.key;
        row.source = source.text;
        for (const std::string& language : sheet.languages) {
            std::string text;
            for (const TranslationRow& r : file->rows.at(language))
                if (r.key == source.key) text = r.text;
            const auto lang = fills.find(language);
            if (lang != fills.end())
                if (const auto fill = lang->second.find(source.key); fill != lang->second.end()) text = fill->second;
            row.texts.push_back(text);
        }
        sheet.rows.push_back(std::move(row));
    }
    return write_csv(sheet);
}

// Sets the <target> of one unit of an XLIFF file the way a translation tool does.
std::string set_target(std::string xliff, const std::string& key, const std::string& target) {
    const std::size_t unit = xliff.find("<trans-unit id=\"" + key + "\"");
    REQUIRE(unit != std::string::npos);
    const std::size_t open = xliff.find("<target", unit);
    const std::size_t close = xliff.find("</target>", open) + 9;
    REQUIRE(open != std::string::npos);
    xliff.replace(open, close - open, "<target state=\"translated\">" + target + "</target>");
    return xliff;
}

}  // namespace

TEST_CASE("i18n.export csv: one file with a byte order mark, the default language and every language, RFC 4180 quoting") {
    Game g;
    const CommandResult r = g.call("i18n.export", Json{{"format", "csv"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["files"] == Json::array({"build/translations/translations.csv"}));
    CHECK(r.result["sourceLanguage"] == "en");
    CHECK(r.result["languages"] == Json::array({"es", "ru"}));

    const std::string text = g.raw("build/translations/translations.csv");
    CHECK(text.substr(0, 3) == "\xEF\xBB\xBF");                          // Excel reads it as UTF-8
    CHECK(text.find("key,en,es,ru\r\n") == 3);                           // header: key, default, languages
    CHECK(text.find("menu.quit,\"Quit, \"\"now\"\"\",") != std::string::npos);  // comma and quotes: quoted, quotes doubled
    CHECK(text.find("\"Line one\nLine two\"") != std::string::npos);     // a line break inside quotes

    auto file = read_csv(text);
    REQUIRE(file.ok());
    CHECK(file->languages == std::vector<std::string>{"en", "es", "ru"});
    const auto en = column(*file, "en"), es = column(*file, "es"), ru = column(*file, "ru");
    CHECK(en.at("menu.quit") == "Quit, \"now\"");
    CHECK(en.at("menu.multi") == "Line one\nLine two");
    CHECK(en.at("tag") == "A & B <tag>");
    CHECK(en.at("$name") == "English");
    CHECK(es.at("$name") == "Español");
    CHECK(es.at("menu.play") == "Jugar");
    CHECK(es.at("menu.quit").empty());                                  // not translated yet
    CHECK(ru.at("menu.play") == "Играть");

    // Plural entries: one row per form, key#category. Russian needs one, few, many, other; Spanish one, other.
    CHECK(en.at("coins#one") == "{count} coin");
    CHECK(en.at("coins#few") == "{count} coins");  // the default language has no "few": its "other" is shown as the source
    CHECK(es.at("coins#one") == "{count} moneda");
    CHECK(es.count("coins#few") == 1);             // the rows are the same for every language
    CHECK(ru.at("coins#many").empty());
    CHECK(en.count("coins") == 0);
    CHECK(en.count("coins#zero") == 0);
}

TEST_CASE("i18n.export csv: delimiter, languages, out folder, and refusals that teach") {
    Game g;
    auto r = g.call("i18n.export", Json{{"format", "csv"}, {"languages", Json::array({"es"})}, {"out", "out/for-translators"}, {"delimiter", ";"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["files"] == Json::array({"out/for-translators/translations.csv"}));
    const std::string text = g.raw("out/for-translators/translations.csv");
    CHECK(text.find("key;en;es\r\n") == 3);
    CHECK(text.find("ru") == std::string::npos);
    auto file = read_csv(text);  // the delimiter is found in the header
    REQUIRE(file.ok());
    CHECK(file->languages == std::vector<std::string>{"en", "es"});

    r = g.call("i18n.export", Json{{"format", "csv"}, {"out", "locales/export"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("inside locales/") != std::string::npos);
    CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    CHECK_FALSE(std::filesystem::exists(g.dir + "/locales/export"));

    r = g.call("i18n.export", Json{{"format", "csv"}, {"languages", Json::array({"esp"})}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("Unknown language 'esp'") != std::string::npos);
    CHECK(r.error["message"].get<std::string>().find("Did you mean 'es'?") != std::string::npos);

    r = g.call("i18n.export", Json{{"format", "csv"}, {"languages", Json::array({"en"})}});
    REQUIRE_FALSE(r.ok);  // only the default language: nothing to translate
    CHECK(r.error["message"].get<std::string>().find("only the default language") != std::string::npos);
}

TEST_CASE("i18n.export without a localization section or with one language says what to do") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    CommandRegistry registry;
    register_translation_commands(registry, tmp.sub("game"));
    auto r = registry.call("i18n.export", Json{{"format", "csv"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("no \"localization\" section") != std::string::npos);

    auto j = load_json_file(tmp.sub("game") + "/factoria.json");
    (*j)["localization"] = *parse_json(R"({"defaultLanguage": "en", "languages": ["en"]})");
    REQUIRE(save_json_file(tmp.sub("game") + "/factoria.json", *j).ok());
    testing::write_all(tmp.sub("game") + "/locales/en.json", kEn);
    r = registry.call("i18n.export", Json{{"format", "csv"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("one language") != std::string::npos);
}

TEST_CASE("i18n.import csv: export, translate, import keeps nested and flat tables, order, and never deletes on an empty cell") {
    Game g;
    REQUIRE(g.call("i18n.export", Json{{"format", "csv"}}).ok);
    const std::string exported = g.raw("build/translations/translations.csv");

    const std::string translated = translate_csv(exported, {
        {"es", {{"menu.play", ""},                         // an emptied cell must not delete "Jugar"
                {"menu.quit", "Salir, \"ya\""},            // comma and quotes survive
                {"menu.multi", "Línea uno\nLínea dos"},    // a line break survives
                {"greeting", "¡Hola, {name}!"},
                {"coins#one", "{count} moneda ya"},
                {"tag", "A & B <etiqueta>"}}},
        {"ru", {{"menu.quit", "Выход"},
                {"coins#one", "{count} монета"}, {"coins#few", "{count} монеты"}, {"coins#many", "{count} монет"}, {"coins#other", "{count} монеты"},
                {"$name", "Русский"}}}});
    testing::write_all(g.dir + "/build/translations/translated.csv", translated);

    const Json before = g.table("es");
    auto dry = g.call("i18n.import", Json{{"file", "build/translations/translated.csv"}, {"dryRun", true}});
    REQUIRE_MESSAGE(dry.ok, dry.error.dump());
    CHECK(dry.result["dryRun"] == true);
    CHECK(dry.result["languages"]["es"]["written"] == false);
    CHECK(g.table("es") == before);  // dry run: nothing written
    CHECK(dry.result["ignored"].size() == 1);  // the default language's column is the source

    auto r = g.call("i18n.import", Json{{"file", "build/translations/translated.csv"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& es = r.result["languages"]["es"];
    CHECK(es["file"] == "locales/es.json");
    CHECK(es["written"] == true);
    CHECK(es["updated"].get<int>() == 1);     // coins#one
    CHECK(es["added"].get<int>() == 4);       // menu.quit, menu.multi, greeting, tag
    CHECK(es["skippedEmpty"].get<int>() >= 1);
    CHECK(es["warnings"].empty());

    const Json t = g.table("es");
    CHECK(t["menu"]["play"] == "Jugar");                         // kept
    CHECK(t["menu"]["quit"] == "Salir, \"ya\"");                  // added inside the existing group
    CHECK(t["menu"]["multi"] == "Línea uno\nLínea dos");
    CHECK(t["greeting"] == "¡Hola, {name}!");                     // added at the top, nested style kept
    CHECK(t["coins"]["one"] == "{count} moneda ya");
    CHECK(t["coins"]["other"] == "{count} monedas");
    CHECK(t["tag"] == "A & B <etiqueta>");
    CHECK(keys_of(t) == std::vector<std::string>{"$name", "menu", "coins", "greeting", "tag"});  // existing order kept, new at the end
    CHECK(keys_of(t["menu"]) == std::vector<std::string>{"play", "multi", "quit"});  // new keys come in the order of the rows (sorted)

    // The Russian table is flat and stays flat; its plural entry is complete.
    const Json ru = g.table("ru");
    CHECK(ru["menu.play"] == "Играть");
    CHECK(ru["menu.quit"] == "Выход");
    CHECK(ru["coins"]["few"] == "{count} монеты");
    CHECK(ru["coins"].size() == 4);
    CHECK(ru["$name"] == "Русский");
    CHECK_FALSE(ru.contains("menu"));

    // Importing the same file again changes nothing.
    r = g.call("i18n.import", Json{{"file", "build/translations/translated.csv"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    for (const char* language : {"es", "ru"}) {
        CHECK(r.result["languages"][language]["updated"] == 0);
        CHECK(r.result["languages"][language]["added"] == 0);
        CHECK(r.result["languages"][language]["written"] == false);
    }
    CHECK(g.table("ru") == ru);

    // The result is a table the game accepts, and the plural categories come back as rows.
    CHECK(parse_string_table(g.table("es"), "es", "locales/es.json").ok());
    CHECK(parse_string_table(g.table("ru"), "ru", "locales/ru.json").ok());
}

TEST_CASE("i18n.import csv from a spreadsheet: semicolons, CRLF, extra blank lines, warnings that teach, errors that name the column") {
    Game g;
    // What Excel with a decimal comma saves: ";" between cells, quotes only where needed, a BOM, blank lines at the end.
    const std::string sheet =
        "\xEF\xBB\xBF" "key;en;es\r\n"
        "menu.play;Play;Jugar!\r\n"
        "menu.plya;Play;Jugar mal\r\n"                     // a typo of a key
        "greeting;Hello, {name}!;\"Hola, {nombre}!\"\r\n"   // a placeholder renamed
        "coins;;monedas\r\n"                                // a plural entry written without its forms
        "menu.play#one;;x\r\n"                              // a plural form of a plain string
        "\r\n;;\r\n";
    testing::write_all(g.dir + "/sheet.csv", sheet);
    auto r = g.call("i18n.import", Json{{"file", "sheet.csv"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& es = r.result["languages"]["es"];
    CHECK(es["updated"] == 1);  // menu.play
    CHECK(es["added"] == 1);    // greeting, imported although its placeholder differs
    std::string warnings;
    for (const Json& w : es["warnings"]) warnings += w.get<std::string>() + "\n";
    CHECK(warnings.find("'menu.plya' is not a key of locales/en.json") != std::string::npos);
    CHECK(warnings.find("Did you mean 'menu.play'?") != std::string::npos);
    CHECK(warnings.find("{nombre}") != std::string::npos);
    CHECK(warnings.find("{name}") != std::string::npos);
    CHECK(warnings.find("'coins' is a plural entry") != std::string::npos);
    CHECK(warnings.find("one plain string") != std::string::npos);
    CHECK(g.table("es")["menu"]["play"] == "Jugar!");
    CHECK_FALSE(g.table("es")["menu"].contains("plya"));

    // A column that is not a language of the game stops everything, before anything is written.
    testing::write_all(g.dir + "/bad.csv", "key,en,esp\nmenu.play,Play,Jugar\n");
    const std::string snapshot = g.raw("locales/es.json");
    r = g.call("i18n.import", Json{{"file", "bad.csv"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("'esp'") != std::string::npos);
    CHECK(r.error["message"].get<std::string>().find("Did you mean 'es'?") != std::string::npos);
    CHECK(g.raw("locales/es.json") == snapshot);

    testing::write_all(g.dir + "/nokey.csv", "id,en,es\nmenu.play,Play,Jugar\n");
    r = g.call("i18n.import", Json{{"file", "nokey.csv"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("not 'key'") != std::string::npos);

    r = g.call("i18n.import", Json{{"file", "build/translations/translation.csv"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
}

TEST_CASE("i18n.import creates the table of a language that has none (flat: the file has no groups) and honours `languages`") {
    Game g(kEn, nullptr, kRu);
    testing::write_all(g.dir + "/new.csv",
                       "key,en,es,ru\n$name,English,Español,\nmenu.play,Play,Jugar,Играть ya\ncoins#one,x,{count} moneda,\n"
                       "coins#other,x,{count} monedas,\ngreeting,x,Hola,\n");
    auto r = g.call("i18n.import", Json{{"file", "new.csv"}, {"languages", Json::array({"es"})}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK_FALSE(r.result["languages"].contains("ru"));  // not asked for: its table is untouched
    CHECK(g.table("ru")["menu.play"] == "Играть");
    const Json& es = r.result["languages"]["es"];
    CHECK(es["added"] == 5);
    REQUIRE(es["warnings"].size() == 1);                 // greeting lost its {name}
    CHECK(es["warnings"][0].get<std::string>().find("no placeholders") != std::string::npos);
    const Json t = g.table("es");
    CHECK(t["$name"] == "Español");
    CHECK(t["menu.play"] == "Jugar");                    // flat: the dotted key stays one key
    CHECK(t["greeting"] == "Hola");
    CHECK(t["coins"] == *parse_json(R"({"one": "{count} moneda", "other": "{count} monedas"})"));
    CHECK(parse_string_table(t, "es", "locales/es.json").ok());

    // A plural entry without its "other" form is not added: the table would not load.
    testing::write_all(g.dir + "/partial.csv", "key,en,ru\ncoins#one,x,{count} монета\ncoins#few,x,{count} монеты\n");
    r = g.call("i18n.import", Json{{"file", "partial.csv"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["languages"]["ru"]["added"] == 0);
    CHECK(r.result["languages"]["ru"]["warnings"][0].get<std::string>().find("no text for \"other\"") != std::string::npos);
    CHECK_FALSE(g.table("ru").contains("coins"));
}

TEST_CASE("i18n.import xliff: export one file per language, translate in a tool, import; XML escaping survives") {
    Game g;
    auto r = g.call("i18n.export", Json{{"format", "xliff"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["files"] == Json::array({"build/translations/translations.es.xlf", "build/translations/translations.ru.xlf"}));

    std::string es = g.raw("build/translations/translations.es.xlf");
    CHECK(es.find("<xliff version=\"1.2\" xmlns=\"urn:oasis:names:tc:xliff:document:1.2\">") != std::string::npos);
    CHECK(es.find("source-language=\"en\" target-language=\"es\"") != std::string::npos);
    CHECK(es.find("<trans-unit id=\"menu.play\" resname=\"menu.play\"") != std::string::npos);
    CHECK(es.find("<source>A &amp; B &lt;tag&gt;</source>") != std::string::npos);                 // escaped
    CHECK(es.find("<target state=\"translated\">Jugar</target>") != std::string::npos);
    CHECK(es.find("<target state=\"needs-translation\"></target>") != std::string::npos);          // not translated yet
    CHECK(es.find("<trans-unit id=\"coins#one\"") != std::string::npos);                           // plural forms: key#category
    CHECK(es.find("Keep the placeholders as they are: {name}.") != std::string::npos);

    es = set_target(es, "menu.quit", "Salir &amp; &lt;ya&gt;, \"ya\"");
    es = set_target(es, "tag", "A &amp; B &lt;etiqueta&gt;");
    es = set_target(es, "menu.multi", "Línea uno\nLínea dos");
    testing::write_all(g.dir + "/build/translations/translations.es.xlf", es);

    r = g.call("i18n.import", Json{{"file", "build/translations/translations.es.xlf"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["format"] == "xliff");
    const Json& result = r.result["languages"]["es"];
    CHECK(result["updated"] == 0);
    CHECK(result["added"] == 3);
    CHECK(result["unchanged"].get<int>() >= 2);
    CHECK(result["warnings"].empty());
    CHECK_FALSE(r.result["languages"].contains("ru"));  // only the languages in the file
    const Json t = g.table("es");
    CHECK(t["menu"]["quit"] == "Salir & <ya>, \"ya\"");
    CHECK(t["tag"] == "A & B <etiqueta>");
    CHECK(t["menu"]["multi"] == "Línea uno\nLínea dos");
}

TEST_CASE("read_xliff: namespaces, CDATA, character references, inline tags and alternative translations") {
    const std::string xliff = R"(<?xml version="1.0" encoding="UTF-8"?>
<!-- written by a tool -->
<x:xliff xmlns:x="urn:oasis:names:tc:xliff:document:1.2" version="1.2">
  <x:file original="locales/en.json" source-language="en" target-language="ja" datatype="plaintext">
    <x:body>
      <x:group>
        <x:trans-unit id="1" resname="menu.play">
          <x:source>Play</x:source>
          <x:target>&#x65E5;&#26412;<x:g id="1">語</x:g></x:target>
          <x:alt-trans><x:target>wrong</x:target></x:alt-trans>
        </x:trans-unit>
      </x:group>
      <x:trans-unit id="menu.quit"><x:source>Quit</x:source><x:target><![CDATA[Quit <now> & go]]></x:target></x:trans-unit>
      <x:trans-unit id="menu.back"><x:source>Back</x:source></x:trans-unit>
    </x:body>
  </x:file>
</x:xliff>)";
    auto file = read_xliff(xliff);
    REQUIRE(file.ok());
    REQUIRE(file->languages == std::vector<std::string>{"ja"});
    const auto ja = column(*file, "ja");
    CHECK(ja.at("menu.play") == "日本語");        // resname wins over the numeric id; entities decoded; inline tag text kept
    CHECK(ja.at("menu.quit") == "Quit <now> & go");
    CHECK(ja.at("menu.back").empty());           // no <target>: nothing to import

    auto bad = read_xliff("<xliff><file source-language=\"en\" target-language=\"es\"><body><trans-unit id=\"a\"><source>x</source></body></file></xliff>");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("does not close <trans-unit>") != std::string::npos);
    CHECK(bad.error().message.find("line 1") != std::string::npos);

    auto notXliff = read_xliff("<html></html>");
    REQUIRE_FALSE(notXliff.ok());
    CHECK(notXliff.error().message.find("not an XLIFF file") != std::string::npos);
    auto noLanguage = read_xliff("<xliff><file><body><trans-unit id=\"a\"><target>x</target></trans-unit></body></file></xliff>");
    REQUIRE_FALSE(noLanguage.ok());
    CHECK(noLanguage.error().message.find("target-language") != std::string::npos);
}

TEST_CASE("read_csv: quotes, line breaks, a BOM, ragged rows and the errors for broken files") {
    auto file = read_csv("\xEF\xBB\xBFkey,en,es\r\na,\"x, \"\"y\"\"\",\"z\nw\"\r\nb,only\r\n\r\nc,1,2,\r\n");
    REQUIRE(file.ok());
    const auto en = column(*file, "en"), es = column(*file, "es");
    CHECK(en.at("a") == "x, \"y\"");
    CHECK(es.at("a") == "z\nw");
    CHECK(en.at("b") == "only");
    CHECK(es.at("b").empty());  // a short row: the missing cells are empty
    CHECK(en.at("c") == "1");   // a trailing delimiter is an empty extra cell

    auto open = read_csv("key,en\na,\"never closed\n");
    REQUIRE_FALSE(open.ok());
    CHECK(open.error().message.find("quoted field never ends") != std::string::npos);
    auto wide = read_csv("key,en\na,1,2\n");
    REQUIRE_FALSE(wide.ok());
    CHECK(wide.error().message.find("row 2") != std::string::npos);
    CHECK(wide.error().message.find("has 3 columns but the header has 2") != std::string::npos);
    CHECK_FALSE(read_csv("").ok());
    CHECK_FALSE(read_csv("key\na\n").ok());           // no language column
    CHECK_FALSE(read_csv("key,en,en\na,1,2\n").ok());  // a language twice
    CHECK(read_translation_file("key,en\na,1\n", "x.csv").ok());
    CHECK(read_translation_file("<xliff/>", "x.txt").error().message.find("no translation units") != std::string::npos);
}
