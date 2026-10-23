#include "fa/core/i18n.h"

#include "fa/core/number_format.h"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <cmath>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

// ================================================================================================== language tags
namespace {

bool all_alpha(std::string_view s) {
    return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'); });
}
bool all_digit(std::string_view s) {
    return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) { return c >= '0' && c <= '9'; });
}

// language[-Script][-REGION] of a canonical tag.
struct TagParts {
    std::string language, script, region;
};
TagParts parts_of(std::string_view tag) {
    TagParts p;
    std::vector<std::string> sub = split(tag, '-');
    if (sub.empty()) return p;
    p.language = sub[0];
    for (std::size_t i = 1; i < sub.size(); ++i) {
        if (sub[i].size() == 4 && all_alpha(sub[i])) p.script = sub[i];
        else p.region = sub[i];
    }
    return p;
}

// The script a tag is written in, or implied: Chinese is Simplified in China and Singapore, Traditional in Taiwan, Hong Kong
// and Macau. "" when unknown.
std::string script_of(const TagParts& p) {
    if (!p.script.empty()) return p.script;
    if (p.language == "zh") {
        if (p.region == "CN" || p.region == "SG") return "Hans";
        if (p.region == "TW" || p.region == "HK" || p.region == "MO") return "Hant";
    }
    return {};
}

}  // namespace

std::string normalize_language_tag(std::string_view raw) {
    std::string s(raw);
    s.resize(s.find_first_of(".@") == std::string::npos ? s.size() : s.find_first_of(".@"));  // "es_ES.UTF-8@euro"
    std::replace(s.begin(), s.end(), '_', '-');
    std::vector<std::string> sub = split(s, '-', false);
    if (sub.empty() || sub[0].size() < 2 || sub[0].size() > 3 || !all_alpha(sub[0])) return {};
    std::string out = to_lower(sub[0]);
    bool hasScript = false, hasRegion = false;
    for (std::size_t i = 1; i < sub.size(); ++i) {
        const std::string& p = sub[i];
        if (!hasScript && !hasRegion && p.size() == 4 && all_alpha(p)) {
            out += '-';
            out += char(std::toupper(static_cast<unsigned char>(p[0])));
            out += to_lower(p.substr(1));
            hasScript = true;
        } else if (!hasRegion && ((p.size() == 2 && all_alpha(p)) || (p.size() == 3 && all_digit(p)))) {
            out += '-';
            for (char c : p) out += char(std::toupper(static_cast<unsigned char>(c)));
            hasRegion = true;
        } else {
            break;  // variants and extensions ("-valencia", "-u-nu-latn") do not matter to a game
        }
    }
    return out;
}

bool is_language_tag(std::string_view tag) { return !tag.empty() && normalize_language_tag(tag) == tag; }

bool is_rtl_language(std::string_view tag) {
    const std::string lower = to_lower(normalize_language_tag(tag));
    const std::string_view t = lower;
    if (t.find("-arab") != std::string_view::npos || t.find("-hebr") != std::string_view::npos) return true;
    if (t.find("-latn") != std::string_view::npos || t.find("-cyrl") != std::string_view::npos) return false;
    const std::string_view base = t.substr(0, t.find('-'));
    for (std::string_view r : {"ar", "he", "iw", "fa", "ur", "ps", "sd", "ug", "yi", "dv", "ckb"})
        if (base == r) return true;
    return false;
}

std::string base_language(std::string_view tag) {
    const std::size_t dash = tag.rfind('-');
    return dash == std::string_view::npos ? std::string() : std::string(tag.substr(0, dash));
}

std::string best_language_match(const std::vector<std::string>& systemLanguages, const std::vector<std::string>& projectLanguages) {
    const auto find_exact = [&](const std::string& tag) -> std::string {
        for (const std::string& p : projectLanguages)
            if (iequals(p, tag)) return p;
        return {};
    };
    for (const std::string& raw : systemLanguages) {
        const std::string tag = normalize_language_tag(raw);
        if (tag.empty()) continue;
        const TagParts want = parts_of(tag);
        const std::string wantScript = script_of(want);
        if (std::string m = find_exact(tag); !m.empty()) return m;
        if (!wantScript.empty())
            if (std::string m = find_exact(want.language + "-" + wantScript); !m.empty()) return m;
        if (std::string m = find_exact(want.language); !m.empty()) return m;
        for (const std::string& p : projectLanguages) {  // another variant of the language, unless it is in another script
            const TagParts have = parts_of(p);
            const std::string haveScript = script_of(have);
            if (have.language == want.language && (haveScript.empty() || wantScript.empty() || haveScript == wantScript)) return p;
        }
    }
    return {};
}

// ================================================================================================== plural forms
const char* plural_category_name(PluralCategory category) {
    switch (category) {
        case PluralCategory::Zero: return "zero";
        case PluralCategory::One: return "one";
        case PluralCategory::Two: return "two";
        case PluralCategory::Few: return "few";
        case PluralCategory::Many: return "many";
        case PluralCategory::Other: return "other";
    }
    return "other";
}

bool parse_plural_category(std::string_view name, PluralCategory& out) {
    for (PluralCategory c : {PluralCategory::Zero, PluralCategory::One, PluralCategory::Two, PluralCategory::Few, PluralCategory::Many,
                             PluralCategory::Other})
        if (name == plural_category_name(c)) {
            out = c;
            return true;
        }
    return false;
}

PluralCategory plural_category(std::string_view language, double count) {
    using PC = PluralCategory;
    const double n = std::fabs(count);
    if (!std::isfinite(n)) return PC::Other;
    const bool whole = n == std::floor(n);  // CLDR's v = 0: no visible decimals
    const std::uint64_t i = n >= 1.8e19 ? UINT64_MAX : static_cast<std::uint64_t>(n);
    const std::uint64_t i10 = i % 10, i100 = i % 100;
    const auto between = [](std::uint64_t x, std::uint64_t lo, std::uint64_t hi) { return x >= lo && x <= hi; };

    const std::vector<std::string> sub = split(language, '-');
    const std::string lang = sub.empty() ? std::string() : to_lower(sub[0]);
    // One form: Chinese, Japanese, Korean, Vietnamese, Thai, Indonesian, Malay, Lao, Burmese, Khmer.
    for (const char* only : {"ja", "zh", "ko", "vi", "th", "id", "ms", "lo", "my", "km"})
        if (lang == only) return PC::Other;
    const bool million = whole && i != 0 && i % 1000000 == 0;  // "1 million of": es, fr, it, pt, ca

    if (lang == "ar") {  // whole numbers only; a fraction is "other"
        if (!whole) return PC::Other;
        if (i == 0) return PC::Zero;
        if (i == 1) return PC::One;
        if (i == 2) return PC::Two;
        if (between(i100, 3, 10)) return PC::Few;
        if (between(i100, 11, 99)) return PC::Many;
        return PC::Other;
    }
    if (lang == "he" || lang == "iw") {
        if ((whole && i == 1) || (!whole && i == 0)) return PC::One;
        if (whole && i == 2) return PC::Two;
        return PC::Other;
    }
    if (lang == "ru" || lang == "uk") {
        if (!whole) return PC::Other;
        if (i10 == 1 && i100 != 11) return PC::One;
        if (between(i10, 2, 4) && !between(i100, 12, 14)) return PC::Few;
        return PC::Many;
    }
    if (lang == "pl") {
        if (!whole) return PC::Other;
        if (i == 1) return PC::One;
        if (between(i10, 2, 4) && !between(i100, 12, 14)) return PC::Few;
        return PC::Many;
    }
    if (lang == "cs" || lang == "sk") {
        if (!whole) return PC::Many;
        if (i == 1) return PC::One;
        if (between(i, 2, 4)) return PC::Few;
        return PC::Other;
    }
    if (lang == "fr") {
        if (i == 0 || i == 1) return PC::One;
        return million ? PC::Many : PC::Other;
    }
    if (lang == "pt") {
        const bool portugal = sub.size() > 1 && iequals(sub.back(), "PT");  // pt-PT counts like English; pt and pt-BR: 0 and 1
        if (portugal ? (whole && i == 1) : (i == 0 || i == 1)) return PC::One;
        return million ? PC::Many : PC::Other;
    }
    if (lang == "es" || lang == "it" || lang == "ca") {
        if (whole && i == 1) return PC::One;
        return million ? PC::Many : PC::Other;
    }
    // English, German, Dutch, Turkish and every language without a rule above: 1 is "one", the rest "other".
    return whole && i == 1 ? PC::One : PC::Other;
}

std::vector<PluralCategory> plural_categories(std::string_view language, bool everyCount) {
    std::set<PluralCategory> found;
    for (int n = 0; n < 200; ++n) found.insert(plural_category(language, n));
    if (everyCount) {
        for (double n : {0.5, 1.5, 2.5, 10.5, 100.5, 1e6, 2e6}) found.insert(plural_category(language, n));
    }
    found.insert(PluralCategory::Other);
    return {found.begin(), found.end()};  // the enum is ordered zero .. other
}

// ================================================================================================== string tables
namespace {

std::string escape_pointer(std::string_view key) {
    std::string out;
    for (char c : key) {
        if (c == '~') out += "~0";
        else if (c == '/') out += "~1";
        else out += c;
    }
    return out;
}

Error table_error(std::string_view file, const std::string& pointer, const std::string& message, const std::string& hint) {
    return make_error(std::string(file) + (pointer.empty() ? "" : "#" + pointer) + ": " + message, hint);
}

bool is_plural_object(const Json& obj) {
    bool any = false;
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        if (!it.key().empty() && it.key()[0] == '$') continue;
        PluralCategory c;
        if (!parse_plural_category(it.key(), c)) return false;
        any = true;
    }
    return any;
}

struct Flattener {
    StringTable& table;
    std::string_view file;

    std::optional<Error> add(const std::string& key, StringEntry entry, const std::string& pointer) {
        if (table.entries.count(key))
            return table_error(file, pointer, "the key '" + key + "' is written twice (as \"a.b\" and as nested objects)",
                               "Keep one spelling of each key.");
        entry.pointer = pointer;
        table.entries.emplace(key, std::move(entry));
        return std::nullopt;
    }

    std::optional<Error> walk(const Json& obj, const std::string& prefix, const std::string& pointer) {
        if (!prefix.empty() && is_plural_object(obj)) {
            StringEntry entry;
            for (auto it = obj.begin(); it != obj.end(); ++it) {
                if (!it.key().empty() && it.key()[0] == '$') continue;
                PluralCategory c{};
                parse_plural_category(it.key(), c);
                if (!it->is_string())
                    return table_error(file, pointer + "/" + escape_pointer(it.key()),
                                       "expected a string for the plural form '" + it.key() + "' of '" + prefix + "', got " +
                                           describe_json_value(*it),
                                       "Every form is a string, e.g. \"one\": \"{count} coin\".");
                entry.forms[c] = it->get<std::string>();
            }
            if (!entry.forms.count(PluralCategory::Other))
                return table_error(file, pointer, "the plural entry '" + prefix + "' has no \"other\" form",
                                   "Every plural entry needs \"other\", the form used when no other applies, e.g. {\"one\": "
                                   "\"{count} coin\", \"other\": \"{count} coins\"}. (An object whose keys are all of zero, one, two, few, many, "
                                   "other is a plural entry: give a group another key name.)");
            return add(prefix, std::move(entry), pointer);
        }
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            const std::string& k = it.key();
            if (!k.empty() && k[0] == '$') continue;  // metadata
            const std::string childPointer = pointer + "/" + escape_pointer(k);
            if (k.empty()) return table_error(file, childPointer, "empty key", "Name every string, e.g. \"menu.play\".");
            const std::string key = prefix.empty() ? k : prefix + "." + k;
            if (it->is_string()) {
                StringEntry entry;
                entry.text = it->get<std::string>();
                if (auto err = add(key, std::move(entry), childPointer)) return err;
            } else if (it->is_object()) {
                if (auto err = walk(*it, key, childPointer)) return err;
            } else {
                return table_error(file, childPointer, "expected a string, got " + describe_json_value(*it),
                                   "Every value of a string table is a string, or an object of nested keys or plural forms; "
                                   "numbers belong in {placeholders} (i18n.t(\"" + key + "\", {count: 3})).");
            }
        }
        return std::nullopt;
    }
};

}  // namespace

Result<StringTable> parse_string_table(const Json& document, std::string_view language, std::string_view file) {
    if (!document.is_object())
        return table_error(file, "", "a string table must be a JSON object, got " + describe_json_value(document),
                           "Start from {\"menu\": {\"play\": \"Play\"}}: nested objects become the keys menu.play...");
    StringTable table;
    table.language = std::string(language);
    table.file = std::string(file);
    if (auto it = document.find("$name"); it != document.end()) {
        if (!it->is_string())
            return table_error(file, "/$name", "expected a string (the language's own name), got " + describe_json_value(*it),
                               "Write the name as the speakers write it: \"$name\": \"Español\".");
        table.name = it->get<std::string>();
    }
    Flattener f{table, file};
    if (auto err = f.walk(document, "", "")) return *err;
    return table;
}

std::string format_message(std::string_view text, const Json& args, std::vector<std::string>* missing, std::string_view language,
                           std::vector<std::string>* problems) {
    if (text.find_first_of("{}") == std::string_view::npos) return std::string(text);
    const auto valid_name = [](std::string_view s) {
        return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) {
                   return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
               });
    };
    const auto value_text = [](const Json& v) -> std::string {
        if (v.is_string()) return v.get<std::string>();
        if (v.is_null()) return {};
        if (v.is_boolean()) return v.get<bool>() ? "true" : "false";
        if (v.is_number_float()) {
            const double d = v.get<double>();
            if (d == std::floor(d) && std::fabs(d) < 1e15) return std::to_string(static_cast<long long>(d));
            char buf[40];
            const auto r = std::to_chars(buf, buf + sizeof(buf), d);
            return std::string(buf, r.ptr);
        }
        return v.dump();  // integers and anything unusual (an array, an object)
    };
    std::string out;
    for (std::size_t i = 0; i < text.size(); ++i) {
        const char c = text[i];
        const bool next = i + 1 < text.size();
        if (c == '{' && next && text[i + 1] == '{') {
            out += '{';
            ++i;
        } else if (c == '}' && next && text[i + 1] == '}') {
            out += '}';
            ++i;
        } else if (c == '{') {
            const std::size_t close = text.find('}', i + 1);
            std::string_view inner = close == std::string_view::npos ? std::string_view() : text.substr(i + 1, close - i - 1);
            // {name}, {name:number}, {name:number:2}, {name:duration}, {name:duration:0}
            std::string_view name = inner, type, param;
            if (const std::size_t c1 = inner.find(':'); c1 != std::string_view::npos) {
                name = inner.substr(0, c1);
                type = inner.substr(c1 + 1);
                if (const std::size_t c2 = type.find(':'); c2 != std::string_view::npos) {
                    param = type.substr(c2 + 1);
                    type = type.substr(0, c2);
                }
            }
            if (!valid_name(name)) {
                out += c;
                continue;
            }
            const auto found = args.is_object() ? args.find(std::string(name)) : Json::const_iterator();
            if (args.is_object() && found != args.end()) {
                bool formatted = false;
                if (inner.size() > name.size()) {
                    const bool isNumber = type == "number", isDuration = type == "duration";
                    const bool digits = param.size() == 1 && param[0] >= '0' && param[0] <= '9';
                    if (!isNumber && !isDuration) {
                        if (problems)
                            problems->push_back("{" + std::string(inner) + "}: unknown format '" + std::string(type) +
                                                "' (use {" + std::string(name) + ":number}, {" + std::string(name) + ":number:1} or {" +
                                                std::string(name) + ":duration})");
                    } else if (!param.empty() && !digits) {
                        if (problems)
                            problems->push_back("{" + std::string(inner) + "}: '" + std::string(param) +
                                                "' is not a number of decimals (one digit 0-9, e.g. {" + std::string(name) + ":" +
                                                std::string(type) + ":1})");
                    } else if (!found->is_number()) {
                        if (problems)
                            problems->push_back("{" + std::string(inner) + "}: the argument '" + std::string(name) + "' is " +
                                                (found->is_string() ? "a string" : "not a number") + ", so it is shown as it is (pass a number)");
                    } else {
                        const double v = found->get<double>();
                        const int d = param.empty() ? -1 : param[0] - '0';
                        out += isNumber ? format_number(v, d, language) : format_duration(v, d < 0 ? 1 : d, language);
                        formatted = true;
                    }
                }
                if (!formatted) out += value_text(*found);
            } else {
                out += '{';
                out += inner;
                out += '}';
                if (missing) missing->emplace_back(name);
            }
            i = close;
        } else {
            out += c;
        }
    }
    return out;
}

// ================================================================================================== I18n
void I18n::configure(std::string defaultLanguage, std::vector<std::string> languages) {
    languages_ = std::move(languages);
    default_ = defaultLanguage.empty() && !languages_.empty() ? languages_.front() : std::move(defaultLanguage);
    current_ = default_;
    tables_.clear();
    chain_.clear();
    warned_.clear();
}

void I18n::rebuild_chain() {
    chain_.clear();
    std::vector<std::string> wanted;
    for (std::string l = current_; !l.empty(); l = base_language(l)) wanted.push_back(l);
    wanted.push_back(default_);
    for (const std::string& l : wanted) {
        const auto it = tables_.find(l);
        if (it != tables_.end() && std::find(chain_.begin(), chain_.end(), &it->second) == chain_.end()) chain_.push_back(&it->second);
    }
}

std::vector<I18n::Problem> I18n::load_tables() {
    std::vector<Problem> problems;
    tables_.clear();
    for (const std::string& lang : languages_) {
        const std::string file = "locales/" + lang + ".json";
        if (!fs::exists(file)) {
            problems.push_back({LogLevel::Warn, file + " does not exist, although '" + lang +
                                                    "' is one of localization.languages in factoria.json: its strings come from the "
                                                    "fallback languages (hint: create the file, e.g. {\"menu\": {\"play\": \"...\"}}, or "
                                                    "remove the language)"});
            continue;
        }
        auto doc = load_json_file(file);
        if (!doc.ok()) {
            problems.push_back({LogLevel::Error, doc.error().to_string()});
            continue;
        }
        auto table = parse_string_table(doc.value(), lang, file);
        if (!table.ok()) {
            problems.push_back({LogLevel::Error, table.error().to_string()});
            continue;
        }
        tables_[lang] = std::move(table.value());
    }
    rebuild_chain();
    return problems;
}

Result<void> I18n::add_table(StringTable table) {
    if (std::find(languages_.begin(), languages_.end(), table.language) == languages_.end())
        return make_error("Cannot add a table for '" + table.language + "': it is not one of the game's languages. " +
                              did_you_mean(table.language, languages_),
                          "Declare the language in factoria.json localization.languages.");
    const std::string lang = table.language;
    tables_[lang] = std::move(table);
    rebuild_chain();
    return {};
}

Result<std::string> I18n::resolve_language(std::string_view requested) const {
    if (!enabled())
        return make_error("Localization is off: factoria.json has no \"localization\" section, so there is no language '" +
                              std::string(requested) + "' to switch to.",
                          "Add \"localization\": {\"defaultLanguage\": \"en\", \"languages\": [\"en\", \"es\"]} and a locales/<language>.json "
                          "per language (docs/LOCALIZATION.md).");
    const std::string tag = normalize_language_tag(requested);
    if (!tag.empty()) {
        for (const std::string& l : languages_)
            if (iequals(l, tag)) return l;
        if (std::string m = best_language_match({tag}, languages_); !m.empty()) return m;
    }
    return make_error("Unknown language '" + std::string(requested) + "'. " + did_you_mean(tag.empty() ? requested : std::string_view(tag), languages_),
                      "Use one of localization.languages of factoria.json (BCP 47 tags such as \"en\", \"pt-BR\", \"zh-Hans\").");
}

Result<std::string> I18n::set_language(std::string_view requested) {
    auto lang = resolve_language(requested);
    if (!lang.ok()) return lang;
    if (current_ != lang.value()) {
        current_ = lang.value();
        rebuild_chain();
    }
    return current_;
}

std::optional<std::string> I18n::translate(std::string_view key, const Json& args) const {
    const std::string k(key);
    for (const StringTable* table : chain_) {
        const auto it = table->entries.find(k);
        if (it == table->entries.end()) continue;
        const StringEntry& e = it->second;
        const std::string* text = &e.text;
        if (e.plural()) {
            PluralCategory category = PluralCategory::Other;
            const auto count = args.is_object() ? args.find("count") : Json::const_iterator();
            if (args.is_object() && count != args.end() && count->is_number()) category = plural_category(table->language, count->get<double>());
            else
                warn_once("plural|" + k, "'" + k + "' is a plural entry but was asked for without a numeric args.count: using the \"other\" "
                                         "form (hint: i18n.t(\"" + k + "\", {count: n}))");
            const auto form = e.forms.find(category);
            text = &(form != e.forms.end() ? form : e.forms.find(PluralCategory::Other))->second;
        }
        std::vector<std::string> missing;
        std::vector<std::string> problems;
        std::string out = format_message(*text, args, &missing, table->language, &problems);
        for (const std::string& problem : problems)
            warn_once("fmt|" + k + "|" + problem, "'" + k + "' (" + table->file + ") " + problem);
        for (const std::string& name : missing)
            warn_once("arg|" + k + "|" + name, "'" + k + "' (" + table->file + ") uses {" + name + "} but no argument '" + name +
                                                    "' was given: the placeholder stays in the text (hint: i18n.t(\"" + k + "\", {" + name + ": ...}))");
        return out;
    }
    return std::nullopt;
}

std::string I18n::number(double value, int decimals) const { return format_number(value, decimals, current_); }

std::string I18n::duration(double seconds, int decimals) const { return format_duration(seconds, decimals, current_); }

std::string I18n::t(std::string_view key, const Json& args) const {
    if (auto text = translate(key, args)) return *text;
    const std::string id = "key|" + std::string(key);
    if (!warned_.count(id)) {  // the did-you-mean list is built once per missing key, not every frame
        std::vector<std::string> known;
        for (const StringTable* table : chain_)
            for (const auto& entry : table->entries) known.push_back(entry.first);
        const std::string close = closest_match(key, known);
        warn_once(id, "no string table has the key '" + std::string(key) + "' (language " + current_ + "): showing the key" +
                          (close.empty() ? "" : " (did you mean '" + close + "'?)") +
                          (enabled() ? "" : " (localization is off: factoria.json has no \"localization\" section)"));
    }
    return std::string(key);
}

bool I18n::has(std::string_view key) const {
    const std::string k(key);
    return std::any_of(chain_.begin(), chain_.end(), [&](const StringTable* t) { return t->entries.count(k) != 0; });
}

std::string I18n::name(std::string_view language) const {
    const StringTable* t = table(language);
    return t && !t->name.empty() ? t->name : std::string(language);
}

const StringTable* I18n::table(std::string_view language) const {
    const auto it = tables_.find(std::string(language));
    return it == tables_.end() ? nullptr : &it->second;
}

std::vector<std::string> I18n::missing_keys(std::string_view language) const {
    std::vector<std::string> out;
    const StringTable* base = table(default_);
    if (!base || language == default_) return out;
    const StringTable* own = table(language);
    for (const auto& [key, entry] : base->entries)
        if (!own || !own->entries.count(key)) out.push_back(key);
    return out;
}

void I18n::warn_once(const std::string& id, const std::string& message) const {
    if (warned_.insert(id).second) FA_WARN("i18n", "{}", message);
}

}  // namespace fa
