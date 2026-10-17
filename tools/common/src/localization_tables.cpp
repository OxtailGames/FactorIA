#include "localization_tables.h"

#include <format>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa::localization_detail {

namespace {

// parse_string_table puts "file#/pointer: " in front of its messages; the validation report keeps them in fields of their own.
void split_located(const std::string& file, std::string& message, std::string& pointer) {
    if (starts_with(message, file + "#")) {
        const std::string rest = message.substr(file.size() + 1);
        if (const std::size_t at = rest.find(": "); at != std::string::npos) {
            pointer = rest.substr(0, at);
            message = rest.substr(at + 2);
        }
    } else if (starts_with(message, file + ": ")) {
        message = message.substr(file.size() + 2);
    }
}

}  // namespace

TableFile read_table(const std::string& language) {
    TableFile t;
    t.language = language;
    t.file = "locales/" + language + ".json";
    t.exists = fs::exists(t.file);
    if (!t.exists) {
        t.message = t.file + " does not exist, although '" + language + "' is one of localization.languages";
        t.hint = "Create it (start from {\"menu\": {\"play\": \"...\"}}: `factoria call i18n.import` fills a new table from a translator's file), or remove '" +
                 language + "' from localization.languages in factoria.json.";
        return t;
    }
    auto document = load_json_file(t.file);
    if (!document.ok()) {
        t.message = document.error().message;
        t.hint = document.error().hint.empty() ? "Fix the JSON syntax." : document.error().hint;
        split_located(t.file, t.message, t.pointer);
        return t;
    }
    t.document = std::move(document.value());
    auto parsed = parse_string_table(t.document, language, t.file);
    if (!parsed.ok()) {
        t.message = parsed.error().message;
        t.hint = parsed.error().hint;
        split_located(t.file, t.message, t.pointer);
        return t;
    }
    t.table = std::move(parsed.value());
    return t;
}

std::set<std::string> placeholders_of(std::string_view text) {
    std::vector<std::string> names;
    format_message(text, Json::object(), &names);  // every placeholder is "missing" from an empty argument list
    return {names.begin(), names.end()};
}

std::set<std::string> placeholders_of(const StringEntry& entry) {
    if (!entry.plural()) return placeholders_of(entry.text);
    std::set<std::string> names;
    for (const auto& [category, text] : entry.forms) names.merge(placeholders_of(text));
    return names;
}

std::string describe_names(const std::set<std::string>& names) {
    if (names.empty()) return "no placeholders";
    std::string out;
    for (const std::string& n : names) out += (out.empty() ? "{" : ", {") + n + "}";
    return out;
}

std::vector<EntryText> texts_of(const StringEntry& entry) {
    std::vector<EntryText> out;
    if (!entry.plural()) {
        out.push_back({entry.pointer, "", &entry.text});
        return out;
    }
    for (const auto& [category, text] : entry.forms)
        out.push_back({entry.pointer + "/" + plural_category_name(category), plural_category_name(category), &text});
    return out;
}

std::u32string decode_utf8(std::string_view text) {
    std::u32string out;
    for (std::size_t i = 0; i < text.size();) {
        const unsigned char c = static_cast<unsigned char>(text[i]);
        const int extra = c < 0x80 ? 0 : (c >> 5) == 0x6 ? 1 : (c >> 4) == 0xE ? 2 : (c >> 3) == 0x1E ? 3 : -1;
        if (extra < 0 || i + std::size_t(extra) >= text.size()) {  // not a lead byte, or the text ends inside the character
            out.push_back(0xFFFD);
            ++i;
            continue;
        }
        char32_t cp = extra == 0 ? c : (c & (0x3F >> extra));
        bool good = true;
        for (int k = 1; k <= extra; ++k) {
            const unsigned char cc = static_cast<unsigned char>(text[i + std::size_t(k)]);
            if ((cc & 0xC0) != 0x80) {
                good = false;
                break;
            }
            cp = (cp << 6) | (cc & 0x3F);
        }
        if (!good) {
            out.push_back(0xFFFD);
            ++i;
            continue;
        }
        out.push_back(cp);
        i += std::size_t(extra) + 1;
    }
    return out;
}

void append_utf8(std::string& out, char32_t cp) {
    if (cp < 0x80) {
        out += char(cp);
    } else if (cp < 0x800) {
        out += char(0xC0 | (cp >> 6));
        out += char(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
        out += char(0xE0 | (cp >> 12));
        out += char(0x80 | ((cp >> 6) & 0x3F));
        out += char(0x80 | (cp & 0x3F));
    } else {
        out += char(0xF0 | (cp >> 18));
        out += char(0x80 | ((cp >> 12) & 0x3F));
        out += char(0x80 | ((cp >> 6) & 0x3F));
        out += char(0x80 | (cp & 0x3F));
    }
}

std::string describe_code_point(std::uint32_t cp) {
    std::string out = std::format("U+{:04X}", cp);
    if (cp >= 0x20 && cp != 0x7F) {
        out += " '";
        append_utf8(out, cp);
        out += "'";
    }
    return out;
}

std::string excerpt(std::string_view text, std::size_t limit) {
    const std::u32string cps = decode_utf8(text);
    std::string out;
    for (std::size_t i = 0; i < cps.size() && i < limit; ++i) {
        if (cps[i] == U'\n') out += "\\n";
        else append_utf8(out, cps[i]);
    }
    if (cps.size() > limit) out += "...";
    return out;
}

}  // namespace fa::localization_detail
