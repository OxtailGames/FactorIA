// i18n.export and i18n.import: the string tables as files for translators, and what comes back as updates of locales/<language>.json.
// The formats are translations_formats.cpp; docs/LOCALIZATION.md, "Translators", describes the rows.
#include <algorithm>
#include <filesystem>
#include <map>
#include <optional>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/translations.h"
#include "localization_tables.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;
namespace ld = localization_detail;

namespace {

constexpr const char* kDefaultOut = "build/translations";

// ---- shared -----------------------------------------------------------------------------------------------------------------

LocalizationSettings load_localization(const std::string& projectDir) {
    auto project = load_project(projectDir);
    if (!project.ok()) throw CommandError("failed", project.error().message, project.error().hint);
    if (!project->localization.enabled())
        throw CommandError("failed", "factoria.json has no \"localization\" section, so there are no string tables to exchange.",
                           "Add \"localization\": {\"defaultLanguage\": \"en\", \"languages\": [\"en\", \"es\"]} and a locales/<language>.json per "
                           "language (docs/LOCALIZATION.md).");
    return project->localization;
}

std::string located(const ld::TableFile& t) {
    return t.file + (t.pointer.empty() ? "" : "#" + t.pointer) + ": " + t.message;
}

// `requested` as languages of the game, written as in factoria.json or close to it; an unknown one is an error with "did you mean".
std::vector<std::string> resolve_languages(const LocalizationSettings& loc, const Json& requested, const char* argument) {
    I18n resolver;
    resolver.configure(loc.defaultLanguage, loc.languages);
    std::vector<std::string> out;
    if (!requested.is_array()) return out;
    for (const Json& item : requested) {
        if (!item.is_string()) throw CommandError("invalid_argument", std::string("'") + argument + "' holds " + describe_json_value(item) + ", not a language tag.",
                                                  "Use tags of localization.languages, e.g. [\"es\", \"pt-BR\"].");
        auto language = resolver.resolve_language(item.get<std::string>());
        if (!language.ok()) throw CommandError("invalid_argument", language.error().message, language.error().hint);
        if (std::find(out.begin(), out.end(), language.value()) == out.end()) out.push_back(language.value());
    }
    return out;
}

std::string shown(const stdfs::path& projectDir, const stdfs::path& path) {
    const stdfs::path rel = path.lexically_relative(projectDir);
    if (!rel.empty() && *rel.begin() != "..") return rel.generic_string();
    return path.generic_string();
}

std::string lower_path(const stdfs::path& p) {
    std::error_code ec;
    return to_lower(stdfs::weakly_canonical(p, ec).generic_string());
}

// ---- export ----------------------------------------------------------------------------------------------------------------

// The text of `key` (one plural form when `category` is set) in a table; "" when the table has none.
std::string text_in(const ld::TableFile& t, const std::string& key, const PluralCategory* category) {
    if (!t.table) return {};
    const auto it = t.table->entries.find(key);
    if (it == t.table->entries.end()) return {};
    const StringEntry& e = it->second;
    if (!category) return e.plural() ? e.forms.at(PluralCategory::Other) : e.text;
    if (!e.plural()) return {};
    const auto form = e.forms.find(*category);
    return form == e.forms.end() ? std::string() : form->second;
}

Json export_translations(const std::string& projectDir, const Json& args) {
    const std::string format = tooling_detail::arg_string(args, "format", false, "csv");
    if (format != "csv" && format != "xliff")
        throw CommandError("invalid_argument", "Unknown format '" + format + "'.", "Use \"csv\" (a spreadsheet) or \"xliff\" (XLIFF 1.2 for translation tools).");
    const std::string delimiterText = tooling_detail::arg_string(args, "delimiter", false, ",");
    if (delimiterText != "," && delimiterText != ";" && delimiterText != "\t")
        throw CommandError("invalid_argument", "The delimiter must be \",\", \";\" or a tab.",
                           "Excel set to a language that writes decimals with a comma wants \";\".");

    tooling_detail::ProjectRootScope scope(projectDir);
    const LocalizationSettings loc = load_localization(projectDir);
    std::vector<std::string> targets;
    if (args.contains("languages") && args["languages"].is_array() && !args["languages"].empty()) {
        for (const std::string& l : resolve_languages(loc, args["languages"], "languages"))
            if (l != loc.defaultLanguage) targets.push_back(l);
    } else {
        for (const std::string& l : loc.languages)
            if (l != loc.defaultLanguage) targets.push_back(l);
    }
    if (targets.empty())
        throw CommandError("failed",
                           loc.languages.size() < 2 ? "The game has one language (" + loc.defaultLanguage + "): there is nothing to translate."
                                                    : "No language to translate into: only the default language (" + loc.defaultLanguage + ") was asked for.",
                           "Add a language to localization.languages in factoria.json (and a locales/<language>.json), or name one in `languages`.");

    const ld::TableFile def = ld::read_table(loc.defaultLanguage);
    if (!def.table)
        throw CommandError("failed", located(def), def.hint.empty() ? "Fix the default language's table first: it is the text translators read." : def.hint);
    std::vector<ld::TableFile> tables;
    for (const std::string& language : targets) {
        tables.push_back(ld::read_table(language));
        if (tables.back().exists && !tables.back().table)
            throw CommandError("failed", located(tables.back()), "Fix " + tables.back().file + " first (`factoria validate` lists the problems).");
    }

    TranslationSheet sheet;
    sheet.sourceLanguage = loc.defaultLanguage;
    sheet.languages = targets;
    {
        TranslationSheet::Row name{"$name", def.table->name, {}, "The name of the language in that language, for language menus (e.g. Español)."};
        for (const ld::TableFile& t : tables) name.texts.push_back(t.table ? t.table->name : std::string());
        sheet.rows.push_back(std::move(name));
    }
    for (const auto& [key, entry] : def.table->entries) {
        const auto add = [&](const std::string& rowKey, const std::string& source, const PluralCategory* category) {
            TranslationSheet::Row row{rowKey, source, {}, {}};
            for (const ld::TableFile& t : tables) row.texts.push_back(text_in(t, key, category));
            const std::set<std::string> names = ld::placeholders_of(source);
            if (!names.empty()) row.note = "Keep the placeholders as they are: " + ld::describe_names(names) + ".";
            sheet.rows.push_back(std::move(row));
        };
        if (!entry.plural()) {
            add(key, entry.text, nullptr);
            continue;
        }
        // The forms of the default language, the ones each language to translate needs, and any a table already has.
        std::set<PluralCategory> forms;
        for (const auto& [category, text] : entry.forms) forms.insert(category);
        for (std::size_t i = 0; i < targets.size(); ++i) {
            for (PluralCategory c : plural_categories(targets[i])) forms.insert(c);
            if (tables[i].table)
                if (const auto it = tables[i].table->entries.find(key); it != tables[i].table->entries.end())
                    for (const auto& [category, text] : it->second.forms) forms.insert(category);
        }
        for (PluralCategory c : forms) {
            const auto own = entry.forms.find(c);
            add(key + "#" + plural_category_name(c), own != entry.forms.end() ? own->second : entry.forms.at(PluralCategory::Other), &c);
        }
    }

    const stdfs::path root = stdfs::absolute(stdfs::path(projectDir)).lexically_normal();
    stdfs::path out = stdfs::path(tooling_detail::arg_string(args, "out", false, kDefaultOut));
    if (out.is_relative()) out = root / out;
    out = out.lexically_normal();
    const std::string outLower = lower_path(out), localesLower = lower_path(root / "locales");
    if (outLower == localesLower || starts_with(outLower, localesLower + "/"))
        throw CommandError("invalid_argument", "The export would be written inside locales/, next to the tables the game reads.",
                           std::string("Write it to ") + kDefaultOut + "/ (the default) or any folder outside locales/.");

    Json files = Json::array();
    const auto write = [&](const stdfs::path& path, const std::string& content) {
        if (auto r = fs::write_bytes(path.generic_string(), content.data(), content.size()); !r.ok())
            throw CommandError("failed", r.error().message, r.error().hint);
        files.push_back(shown(root, path));
    };
    if (format == "csv") {
        write(out / "translations.csv", write_csv(sheet, delimiterText[0]));
    } else {
        for (std::size_t i = 0; i < targets.size(); ++i) write(out / ("translations." + targets[i] + ".xlf"), write_xliff(sheet, i, def.file));
    }
    return Json::object({{"format", format}, {"files", files}, {"rows", sheet.rows.size()}, {"sourceLanguage", loc.defaultLanguage}, {"languages", targets}});
}

// ---- import ----------------------------------------------------------------------------------------------------------------

struct Location {
    std::string pointer;
    bool plural = false;
};

struct LanguageResult {
    int updated = 0, added = 0, unchanged = 0, skipped = 0;
    std::vector<std::string> warnings;
    std::string error;
    bool changed = false;
    Json document;
    std::string file;
};

// "items#one" -> {"items", One}; a key without a plural form after the '#' is whole.
struct RowKey {
    std::string key;
    std::optional<PluralCategory> category;
};
RowKey split_row_key(const std::string& raw) {
    const std::size_t hash = raw.rfind('#');
    PluralCategory category{};
    if (hash != std::string::npos && hash > 0 && parse_plural_category(raw.substr(hash + 1), category)) return {raw.substr(0, hash), category};
    return {raw, std::nullopt};
}

std::string child_pointer(const std::string& parent, const std::string& token) { return (Json::json_pointer(parent) / token).to_string(); }

// Puts `value` at the dotted `key`: nested objects when the file is written that way, else a flat key. Returns the JSON pointer of
// the new entry, "" (with *why) when the file's layout has no place for it.
std::string insert_entry(Json& document, const std::string& key, const Json& value, bool nested, const std::map<std::string, Location>& known,
                         std::string* why) {
    if (!nested || key.find('.') == std::string::npos) {
        document[key] = value;
        return child_pointer("", key);
    }
    const std::vector<std::string> segments = split(key, '.', false);
    Json* node = &document;
    std::string pointer, prefix;
    for (std::size_t i = 0; i + 1 < segments.size(); ++i) {
        prefix += (prefix.empty() ? "" : ".") + segments[i];
        pointer = child_pointer(pointer, segments[i]);
        auto it = node->find(segments[i]);
        if (it == node->end()) {
            (*node)[segments[i]] = Json::object();
            it = node->find(segments[i]);
        } else if (!it->is_object() || (known.count(prefix) && known.at(prefix).plural)) {
            *why = "'" + prefix + "' is " + (it->is_object() ? "a plural entry" : "a string") + " in the file, so '" + key + "' cannot sit under it";
            return {};
        }
        node = &*it;
    }
    if (node->contains(segments.back())) {
        *why = "'" + key + "' is a group of other keys in the file";
        return {};
    }
    (*node)[segments.back()] = value;
    return child_pointer(pointer, segments.back());
}

LanguageResult import_language(const std::string& language, const std::vector<TranslationRow>& rows, const ld::TableFile& def) {
    LanguageResult r;
    ld::TableFile current = ld::read_table(language);
    r.file = current.file;
    if (current.exists && !current.table) {
        r.error = located(current);
        return r;
    }
    r.document = current.table ? current.document : Json::object();
    std::map<std::string, Location> known;
    if (current.table)
        for (const auto& [key, entry] : current.table->entries) known[key] = {entry.pointer, entry.plural()};
    bool nested = false;  // is the file written as nested groups ("menu": {"play": ...})?
    for (auto it = r.document.begin(); it != r.document.end(); ++it) {
        if (!it.key().empty() && it.key()[0] == '$') continue;
        const auto entry = known.find(it.key());
        if (it->is_object() && !(entry != known.end() && entry->second.plural)) nested = true;
    }

    const auto& defaults = def.table->entries;
    std::vector<std::string> defaultKeys;
    for (const auto& [key, entry] : defaults) defaultKeys.push_back(key);
    std::set<std::string> unknownReported;
    std::map<std::string, std::map<PluralCategory, std::string>> newPlurals;  // plural entries the file lacks, added once complete

    const auto set_text = [&](const std::string& pointer, const std::string& text) {
        const Json::json_pointer ptr(pointer);
        if (r.document.contains(ptr)) {
            if (r.document[ptr] == text) {
                ++r.unchanged;
            } else {
                r.document[ptr] = text;
                ++r.updated;
                r.changed = true;
            }
        } else {
            r.document[ptr] = text;
            ++r.added;
            r.changed = true;
        }
    };

    for (const TranslationRow& row : rows) {
        if (trim(row.text).empty()) {
            ++r.skipped;  // an empty cell never deletes a translation
            continue;
        }
        const RowKey id = split_row_key(row.key);
        const std::string where = " (row " + std::to_string(row.line) + ")";
        if (id.key == "$name") {
            if (!id.category) set_text("/$name", row.text);
            continue;
        }
        const auto original = defaults.find(id.key);
        if (original == defaults.end()) {
            if (unknownReported.insert(id.key).second) {
                const std::string close = closest_match(id.key, defaultKeys);
                r.warnings.push_back("'" + row.key + "' is not a key of " + def.file + ", so it was not imported" + where + "." +
                                     (close.empty() ? " (A key that was removed, or a typo.)" : " Did you mean '" + close + "'?"));
            }
            continue;
        }
        const StringEntry& source = original->second;
        if (id.category && !source.plural()) {
            r.warnings.push_back("'" + row.key + "' names a plural form, but '" + id.key + "' is one plain string in " + def.file + ": not imported" + where + ".");
            continue;
        }
        if (!id.category && source.plural()) {
            r.warnings.push_back("'" + id.key + "' is a plural entry in " + def.file + ": write one row per form ('" + id.key + "#one', '" + id.key +
                                 "#other'...); not imported" + where + ".");
            continue;
        }
        // The {names} must be the default language's: the code fills those and nothing else.
        const std::set<std::string> want = ld::placeholders_of(source), have = ld::placeholders_of(row.text);
        const bool bad = id.category ? !std::includes(want.begin(), want.end(), have.begin(), have.end()) : want != have;
        if (bad)
            r.warnings.push_back("'" + row.key + "' uses " + ld::describe_names(have) + " but " + def.file + " has " + ld::describe_names(want) +
                                 ": the game fills the names of the default language" + where + ".");

        const auto place = known.find(id.key);
        if (place != known.end()) {
            if (place->second.plural != id.category.has_value()) {
                r.warnings.push_back("'" + id.key + "' is " + (place->second.plural ? "a plural entry" : "one plain string") + " in " + r.file +
                                     " but the row is " + (place->second.plural ? "a single text" : "a plural form") + ": not imported" + where + ".");
                continue;
            }
            set_text(place->second.pointer + (id.category ? "/" + std::string(plural_category_name(*id.category)) : std::string()), row.text);
        } else if (id.category) {
            newPlurals[id.key][*id.category] = row.text;
            ++r.added;
        } else {
            std::string why;
            const std::string pointer = insert_entry(r.document, id.key, row.text, nested, known, &why);
            if (pointer.empty()) {
                r.warnings.push_back("'" + id.key + "' was not added: " + why + where + ".");
                continue;
            }
            known[id.key] = {pointer, false};
            ++r.added;
            r.changed = true;
        }
    }
    for (const auto& [key, forms] : newPlurals) {
        if (!forms.count(PluralCategory::Other)) {
            r.added -= int(forms.size());
            r.warnings.push_back("The plural entry '" + key + "' was not added: it has no text for \"other\", which every plural entry needs ('" + key + "#other').");
            continue;
        }
        Json object = Json::object();
        for (const auto& [category, text] : forms) object[plural_category_name(category)] = text;
        std::string why;
        const std::string pointer = insert_entry(r.document, key, object, nested, known, &why);
        if (pointer.empty()) {
            r.added -= int(forms.size());
            r.warnings.push_back("The plural entry '" + key + "' was not added: " + why + ".");
            continue;
        }
        known[key] = {pointer, true};
        r.changed = true;
    }
    if (r.changed) {  // never write a table the game could not read
        auto check = parse_string_table(r.document, language, r.file);
        if (!check.ok()) r.error = "the updated table would be invalid, so nothing was written: " + check.error().message;
    }
    return r;
}

Json import_translations(const std::string& projectDir, const Json& args) {
    const std::string fileArg = tooling_detail::arg_string(args, "file", true);
    const bool dryRun = tooling_detail::arg_bool(args, "dryRun", false);
    tooling_detail::ProjectRootScope scope(projectDir);
    const LocalizationSettings loc = load_localization(projectDir);
    const stdfs::path root = stdfs::absolute(stdfs::path(projectDir)).lexically_normal();

    stdfs::path path(fileArg);
    std::error_code ec;
    if (path.is_relative() && !stdfs::exists(root / path, ec) && stdfs::exists(stdfs::absolute(path), ec)) path = stdfs::absolute(path);  // as typed in the shell
    if (path.is_relative()) path = root / path;
    if (!stdfs::is_regular_file(path, ec)) {
        std::vector<std::string> candidates;
        for (stdfs::recursive_directory_iterator it(root / kDefaultOut, ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec)) candidates.push_back(shown(root, it->path()));
        throw CommandError("not_found", "The file '" + fileArg + "' does not exist.",
                           candidates.empty() ? "Pass the CSV or XLIFF file a translator sent back (project-relative or absolute)."
                                              : did_you_mean(fileArg, candidates));
    }
    auto bytes = fs::read_bytes(path.generic_string());
    if (!bytes.ok()) throw CommandError("failed", bytes.error().message, bytes.error().hint);
    auto parsed = read_translation_file(std::string_view(reinterpret_cast<const char*>(bytes->data()), bytes->size()), path.filename().string());
    if (!parsed.ok()) throw CommandError("invalid_argument", fileArg + ": " + parsed.error().message, parsed.error().hint);

    // The columns (or target languages) of the file are languages of the game.
    I18n resolver;
    resolver.configure(loc.defaultLanguage, loc.languages);
    std::map<std::string, std::vector<TranslationRow>> byLanguage;
    std::vector<std::string> unknown, order;
    for (const std::string& column : parsed->languages) {
        auto language = resolver.resolve_language(column);
        if (!language.ok()) {
            unknown.push_back("'" + column + "': " + language.error().message);
            continue;
        }
        if (byLanguage.count(language.value()))
            throw CommandError("invalid_argument", fileArg + " has two columns for the language '" + language.value() + "' ('" + column + "' is one).",
                               "Keep one column per language.");
        byLanguage[language.value()] = parsed->rows.at(column);
        order.push_back(language.value());
    }
    if (!unknown.empty())
        throw CommandError("invalid_argument",
                           fileArg + " has " + std::string(unknown.size() == 1 ? "a language that is" : "languages that are") + " not in localization.languages of factoria.json: " +
                               join(unknown, "; "),
                           "Rename the column header to a tag of localization.languages (en, es, pt-BR...), or add the language to factoria.json first.");

    std::vector<std::string> wanted;
    Json ignored = Json::array();
    if (args.contains("languages") && args["languages"].is_array() && !args["languages"].empty()) {
        wanted = resolve_languages(loc, args["languages"], "languages");
        for (const std::string& l : wanted)
            if (!byLanguage.count(l))
                throw CommandError("invalid_argument", fileArg + " has no column for the language '" + l + "'.",
                                   "It has: " + join(order, ", ") + ".");
    } else {
        for (const std::string& l : order) {
            if (l == loc.defaultLanguage) ignored.push_back(l + ": the default language is the source of the file, not a translation (name it in `languages` to import it)");
            else wanted.push_back(l);
        }
    }
    if (wanted.empty())
        throw CommandError("invalid_argument", fileArg + " has no language to import: its only column is the default language (" + loc.defaultLanguage + ").",
                           "Translators fill the other language columns.");

    const ld::TableFile def = ld::read_table(loc.defaultLanguage);
    if (!def.table) throw CommandError("failed", located(def), "Fix the default language's table first: keys are checked against it.");

    std::map<std::string, LanguageResult> results;
    std::vector<std::string> failed;
    for (const std::string& language : wanted) {
        results[language] = import_language(language, byLanguage.at(language), def);
        if (!results[language].error.empty()) failed.push_back(language + ": " + results[language].error);
    }
    if (!failed.empty())
        throw CommandError("failed", "Nothing was written. " + join(failed, "; "),
                           "Fix the table (`factoria validate` lists what is wrong), then import again.");

    Json out = Json::object({{"file", shown(root, path)}, {"format", parsed->format}, {"dryRun", dryRun}});
    Json languages = Json::object();
    for (const std::string& language : wanted) {
        LanguageResult& r = results[language];
        bool written = false;
        if (r.changed && !dryRun) {
            const std::string text = dump_json(r.document);
            if (auto w = fs::write_bytes((root / r.file).generic_string(), text.data(), text.size()); !w.ok())
                throw CommandError("failed", w.error().message, w.error().hint);
            written = true;
        }
        languages[language] = Json::object({{"file", r.file}, {"updated", r.updated}, {"added", r.added}, {"unchanged", r.unchanged},
                                            {"skippedEmpty", r.skipped}, {"written", written}, {"warnings", r.warnings}});
    }
    out["languages"] = languages;
    if (!ignored.empty()) out["ignored"] = ignored;
    return out;
}

}  // namespace

void register_translation_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo exporter;
    exporter.name = "i18n.export";
    exporter.category = "i18n";
    exporter.readOnly = false;
    exporter.summary = "Write the game's string tables as a spreadsheet (CSV) or XLIFF files for translators.";
    exporter.description =
        "Reads locales/<language>.json of every language and writes what a translator needs into `out` (default build/translations/, "
        "never inside locales/): format \"csv\" is ONE file, translations.csv (UTF-8 with a byte order mark so Excel opens it right; "
        "columns `key`, the default language, then one column per language to translate; fields with a comma, quote or line break "
        "are quoted), format \"xliff\" is one XLIFF 1.2 file per language to translate, translations.<language>.xlf (source = the "
        "default language's text, target = the translation, state \"needs-translation\" when missing; trans-unit id and resname = the "
        "key). A plural entry is one row per form, the key written `items#one`, `items#other`: the forms the language needs "
        "(CLDR) plus any the tables have. The row `$name` is the language's own name. A placeholder note lists the {names} to keep. "
        "Returns {format, files, rows, sourceLanguage, languages}. `languages` limits the columns (default: every language except "
        "the default). With `delimiter` \";\" the CSV opens in Excel set to a language that writes decimals with a comma. Read the "
        "result back with i18n.import. Example: {\"format\": \"csv\", \"languages\": [\"es\", \"ja\"]}";
    exporter.inputSchema = Json::parse(R"({
        "type": "object",
        "properties": {
            "format": {"type": "string", "enum": ["csv", "xliff"], "default": "csv",
                       "description": "csv = one spreadsheet file; xliff = one XLIFF 1.2 file per language (Poedit, OmegaT, memoQ...)."},
            "languages": {"type": "array", "items": {"type": "string"},
                          "description": "Languages to translate into, as in localization.languages (e.g. [\"es\", \"pt-BR\"]). Default: all but the default language."},
            "out": {"type": "string",
                    "description": "Folder to write into, project-relative or absolute (default build/translations). Not inside locales/."},
            "delimiter": {"type": "string", "enum": [",", ";", "\t"], "default": ",",
                          "description": "CSV only. Use \";\" for Excel set to Spanish, German, French... (decimal comma)."}
        }})");
    registry.add(exporter, [projectDir](const Json& args) { return export_translations(projectDir, args); });

    CommandInfo importer;
    importer.name = "i18n.import";
    importer.category = "i18n";
    importer.readOnly = false;
    importer.summary = "Read a translator's CSV or XLIFF file back into locales/<language>.json.";
    importer.description =
        "Reads a file written by i18n.export (or edited in a spreadsheet or a translation tool) and updates the tables of the "
        "languages in it: existing keys are changed in place (nested objects stay nested, flat keys stay flat, key order is kept), "
        "keys the language lacks are added (nested by their dots when the file is nested), and an empty cell never deletes a "
        "translation. Rows `items#one` fill the forms of a plural entry. A column or target language that is not in "
        "localization.languages is an error with \"did you mean\"; a key the default language does not have, a {placeholder} that "
        "differs from the default language's, or a plural/plain mismatch is a warning and that row is not imported (placeholders: "
        "imported with the warning). The default language's own column is the source and is skipped unless named in `languages`. "
        "Tables are rewritten with 2-space indentation. Returns {file, format, dryRun, languages: {<tag>: {file, updated, added, "
        "unchanged, skippedEmpty, written, warnings}}}. With `dryRun` nothing is written. Example: "
        "{\"file\": \"build/translations/translations.csv\", \"dryRun\": true}";
    importer.inputSchema = Json::parse(R"({
        "type": "object", "required": ["file"],
        "properties": {
            "file": {"type": "string", "description": "The CSV or XLIFF file to read, project-relative or absolute."},
            "languages": {"type": "array", "items": {"type": "string"},
                          "description": "Import only these languages of the file (default: all but the default language)."},
            "dryRun": {"type": "boolean", "default": false, "description": "Report what would change without writing anything."}
        }})");
    registry.add(importer, [projectDir](const Json& args) { return import_translations(projectDir, args); });
}

}  // namespace fa
