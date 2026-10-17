// The files translators exchange: CSV (RFC 4180, opens in Excel, LibreOffice and Google Sheets) and XLIFF 1.2 (Poedit, OmegaT, memoQ...).
// What the files mean for the string tables is translations.cpp.
#include <algorithm>
#include <charconv>

#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/tooling/translations.h"
#include "localization_tables.h"

namespace fa {

namespace {

constexpr const char* kBom = "\xEF\xBB\xBF";

// ---- CSV -----------------------------------------------------------------------------------------------------------------------

std::string csv_field(const std::string& text, char delimiter) {
    if (text.find_first_of(std::string("\"\r\n") + delimiter) == std::string::npos) return text;
    std::string out = "\"";
    for (char c : text) {
        if (c == '"') out += '"';
        out += c;
    }
    return out + "\"";
}

// ---- XML -----------------------------------------------------------------------------------------------------------------------

std::string xml_escape(const std::string& text, bool attribute) {
    std::string out;
    for (const char32_t cp : utf8_decode(text)) {
        switch (cp) {
            case U'&': out += "&amp;"; break;
            case U'<': out += "&lt;"; break;
            case U'>': out += "&gt;"; break;
            case U'"': out += attribute ? "&quot;" : "\""; break;
            case U'\r': out += "&#13;"; break;
            case U'\n': out += attribute ? "&#10;" : "\n"; break;
            case U'\t': out += attribute ? "&#9;" : "\t"; break;
            default:
                if (cp < 0x20) utf8_append(out, 0xFFFD);  // XML 1.0 cannot hold the other control characters
                else utf8_append(out, cp);
        }
    }
    return out;
}

std::string xml_unescape(std::string_view text) {
    std::string out;
    for (std::size_t i = 0; i < text.size(); ++i) {
        if (text[i] != '&') {
            out += text[i];
            continue;
        }
        const std::size_t end = text.find(';', i);
        if (end == std::string_view::npos || end - i > 12) {
            out += '&';
            continue;
        }
        const std::string_view name = text.substr(i + 1, end - i - 1);
        if (name == "amp") out += '&';
        else if (name == "lt") out += '<';
        else if (name == "gt") out += '>';
        else if (name == "quot") out += '"';
        else if (name == "apos") out += '\'';
        else if (name.size() > 1 && name[0] == '#') {
            const bool hex = name[1] == 'x' || name[1] == 'X';
            const char* const digits = name.data() + (hex ? 2 : 1);
            const char* const last = name.data() + name.size();
            std::uint32_t cp = 0;
            const auto parsed = std::from_chars(digits, last, cp, hex ? 16 : 10);
            if (parsed.ec != std::errc() || parsed.ptr != last || cp > 0x10FFFF) {
                out += '&';
                continue;
            }
            utf8_append(out, cp);
        } else {
            out += '&';
            continue;
        }
        i = end;
    }
    return out;
}

std::string local_name(std::string_view name) {
    const std::size_t colon = name.rfind(':');
    return std::string(colon == std::string_view::npos ? name : name.substr(colon + 1));
}

struct Attribute {
    std::string name, value;
};

// Walks an XML document and calls back for its elements and text. Comments, processing instructions and the DOCTYPE are skipped;
// namespaces are ignored (names are compared without their prefix).
class XmlWalker {
public:
    explicit XmlWalker(std::string_view text) : s_(text) {}

    // `h` has start(name, attributes, line), end(name) and text(text).
    template <class Handler>
    Result<void> walk(Handler& h) {
        std::vector<std::string> open;
        while (pos_ < s_.size()) {
            if (s_[pos_] != '<') {
                const std::size_t next = std::min(s_.find('<', pos_), s_.size());
                h.text(xml_unescape(s_.substr(pos_, next - pos_)));
                pos_ = next;
                continue;
            }
            if (s_.compare(pos_, 4, "<!--") == 0) {
                if (!skip_to("-->", 3)) return fail("a comment that never ends");
            } else if (s_.compare(pos_, 9, "<![CDATA[") == 0) {
                const std::size_t close = s_.find("]]>", pos_);
                if (close == std::string_view::npos) return fail("a CDATA section that never ends");
                h.text(std::string(s_.substr(pos_ + 9, close - pos_ - 9)));
                pos_ = close + 3;
            } else if (s_.compare(pos_, 2, "<?") == 0) {
                if (!skip_to("?>", 2)) return fail("a processing instruction that never ends");
            } else if (s_.compare(pos_, 2, "<!") == 0) {
                int depth = 0;  // <!DOCTYPE x [ ... ]>
                for (; pos_ < s_.size(); ++pos_) {
                    if (s_[pos_] == '[') ++depth;
                    else if (s_[pos_] == ']') --depth;
                    else if (s_[pos_] == '>' && depth <= 0) break;
                }
                if (pos_ >= s_.size()) return fail("a declaration that never ends");
                ++pos_;
            } else if (s_.compare(pos_, 2, "</") == 0) {
                const std::size_t close = s_.find('>', pos_);
                if (close == std::string_view::npos) return fail("a closing tag that never ends");
                const std::string name = local_name(trim(s_.substr(pos_ + 2, close - pos_ - 2)));
                const std::size_t line = line_at(pos_);
                if (open.empty() || open.back() != name)
                    return make_error("line " + std::to_string(line) + ": </" + name + "> " +
                                          (open.empty() ? "closes an element that was never opened" : "does not close <" + open.back() + ">"),
                                      "The file is not well-formed XML: check the tags around that line, or export it again.");
                open.pop_back();
                h.end(name);
                pos_ = close + 1;
            } else {
                auto tag = read_start_tag(h, open);
                if (!tag.ok()) return tag;
            }
        }
        if (!open.empty())
            return make_error("the file ends inside <" + open.back() + ">",
                              "The file is not well-formed XML (it may be cut short): export it again or repair the end of it.");
        return {};
    }

private:
    Result<void> fail(const std::string& what) const {
        return make_error("line " + std::to_string(line_at(pos_)) + ": " + what, "The file is not well-formed XML: export it again.");
    }
    bool skip_to(const char* end, std::size_t skip) {
        const std::size_t at = s_.find(end, pos_ + skip);
        if (at == std::string_view::npos) return false;
        pos_ = at + std::string_view(end).size();
        return true;
    }
    // Lines are counted incrementally: asking for a position before the last one counts again from the start.
    std::size_t line_at(std::size_t pos) const {
        if (pos < linePos_) {
            linePos_ = 0;
            line_ = 1;
        }
        line_ += std::size_t(std::count(s_.begin() + std::ptrdiff_t(linePos_), s_.begin() + std::ptrdiff_t(std::min(pos, s_.size())), '\n'));
        linePos_ = std::min(pos, s_.size());
        return line_;
    }

    template <class Handler>
    Result<void> read_start_tag(Handler& h, std::vector<std::string>& open) {
        const std::size_t start = pos_;
        std::size_t i = pos_ + 1;
        const auto is_space = [](char c) { return c == ' ' || c == '\t' || c == '\r' || c == '\n'; };
        const std::size_t nameStart = i;
        while (i < s_.size() && !is_space(s_[i]) && s_[i] != '/' && s_[i] != '>') ++i;
        const std::string name = local_name(s_.substr(nameStart, i - nameStart));
        std::vector<Attribute> attributes;
        bool selfClosing = false;
        for (;;) {
            while (i < s_.size() && is_space(s_[i])) ++i;
            if (i >= s_.size()) return fail("a tag that never ends");
            if (s_[i] == '>') {
                ++i;
                break;
            }
            if (s_[i] == '/' && i + 1 < s_.size() && s_[i + 1] == '>') {
                selfClosing = true;
                i += 2;
                break;
            }
            const std::size_t attributeStart = i;
            while (i < s_.size() && !is_space(s_[i]) && s_[i] != '=' && s_[i] != '>' && s_[i] != '/') ++i;
            const std::string attribute(s_.substr(attributeStart, i - attributeStart));
            while (i < s_.size() && is_space(s_[i])) ++i;
            if (attribute.empty() || i >= s_.size() || s_[i] != '=') {
                pos_ = start;
                return make_error("line " + std::to_string(line_at(start)) + ": the tag <" + name + "> has an attribute without a value",
                                  "The file is not well-formed XML: attributes are written name=\"value\".");
            }
            ++i;
            while (i < s_.size() && is_space(s_[i])) ++i;
            if (i >= s_.size() || (s_[i] != '"' && s_[i] != '\'')) {
                pos_ = start;
                return make_error("line " + std::to_string(line_at(start)) + ": the attribute '" + attribute + "' of <" + name + "> is not quoted",
                                  "The file is not well-formed XML: attribute values are in quotes.");
            }
            const char quote = s_[i++];
            const std::size_t close = s_.find(quote, i);
            if (close == std::string_view::npos) return fail("an attribute value that never ends");
            attributes.push_back({local_name(attribute), xml_unescape(s_.substr(i, close - i))});
            i = close + 1;
        }
        const std::size_t line = line_at(start);
        pos_ = i;
        h.start(name, attributes, line);
        if (selfClosing) h.end(name);
        else open.push_back(name);
        return {};
    }

    std::string_view s_;
    std::size_t pos_ = 0;
    mutable std::size_t linePos_ = 0, line_ = 1;
};

const std::string& attribute_of(const std::vector<Attribute>& attributes, const char* name) {
    static const std::string none;
    for (const Attribute& a : attributes)
        if (a.name == name) return a.value;
    return none;
}

// Collects <trans-unit>s: the key is `resname` (else `id`), the text is what <target> holds (inline tags dropped, their text kept).
struct XliffReader {
    TranslationFile file;
    std::string error;
    std::string targetLanguage;
    int altTrans = 0, unitDepth = 0;
    bool inTarget = false;
    std::string key, targetText;
    std::size_t unitLine = 0;
    bool sawXliff = false;

    void start(const std::string& name, const std::vector<Attribute>& attributes, std::size_t line) {
        if (name == "xliff") {
            sawXliff = true;
        } else if (name == "file") {
            targetLanguage = attribute_of(attributes, "target-language");
        } else if (name == "alt-trans") {
            ++altTrans;
        } else if (name == "trans-unit" && unitDepth++ == 0) {
            const std::string& resname = attribute_of(attributes, "resname");
            key = resname.empty() ? attribute_of(attributes, "id") : resname;
            targetText.clear();
            unitLine = line;
        } else if (name == "target" && unitDepth > 0 && altTrans == 0) {
            inTarget = true;
            targetText.clear();
        }
    }
    void end(const std::string& name) {
        if (name == "alt-trans") {
            --altTrans;
        } else if (name == "target" && inTarget) {
            inTarget = false;
        } else if (name == "trans-unit" && --unitDepth == 0) {
            if (key.empty()) {
                if (error.empty()) error = "line " + std::to_string(unitLine) + ": a <trans-unit> has no id or resname";
                return;
            }
            if (targetLanguage.empty()) {
                if (error.empty()) error = "line " + std::to_string(unitLine) + ": the <file> of the unit '" + key + "' has no target-language";
                return;
            }
            if (std::find(file.languages.begin(), file.languages.end(), targetLanguage) == file.languages.end()) file.languages.push_back(targetLanguage);
            file.rows[targetLanguage].push_back({key, targetText, unitLine});
        }
    }
    void text(const std::string& t) {
        if (inTarget) targetText += t;
    }
};

}  // namespace

std::string write_csv(const TranslationSheet& sheet, char delimiter) {
    const auto row = [&](const std::vector<std::string>& cells) {
        std::string line;
        for (std::size_t i = 0; i < cells.size(); ++i) line += (i ? std::string(1, delimiter) : std::string()) + csv_field(cells[i], delimiter);
        return line + "\r\n";
    };
    std::string out = kBom;
    std::vector<std::string> header{"key", sheet.sourceLanguage};
    header.insert(header.end(), sheet.languages.begin(), sheet.languages.end());
    out += row(header);
    for (const TranslationSheet::Row& r : sheet.rows) {
        std::vector<std::string> cells{r.key, r.source};
        cells.insert(cells.end(), r.texts.begin(), r.texts.end());
        out += row(cells);
    }
    return out;
}

std::string write_xliff(const TranslationSheet& sheet, std::size_t languageIndex, const std::string& original) {
    std::string out = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                      "<xliff version=\"1.2\" xmlns=\"urn:oasis:names:tc:xliff:document:1.2\">\n";
    out += "  <file original=\"" + xml_escape(original, true) + "\" source-language=\"" + xml_escape(sheet.sourceLanguage, true) +
           "\" target-language=\"" + xml_escape(sheet.languages.at(languageIndex), true) + "\" datatype=\"plaintext\">\n    <body>\n";
    for (const TranslationSheet::Row& r : sheet.rows) {
        const std::string& translation = r.texts.at(languageIndex);
        const std::string key = xml_escape(r.key, true);
        out += "      <trans-unit id=\"" + key + "\" resname=\"" + key + "\" xml:space=\"preserve\">\n";
        out += "        <source>" + xml_escape(r.source, false) + "</source>\n";
        out += translation.empty() ? "        <target state=\"needs-translation\"></target>\n"
                                   : "        <target state=\"translated\">" + xml_escape(translation, false) + "</target>\n";
        if (!r.note.empty()) out += "        <note>" + xml_escape(r.note, false) + "</note>\n";
        out += "      </trans-unit>\n";
    }
    return out + "    </body>\n  </file>\n</xliff>\n";
}

Result<TranslationFile> read_csv(std::string_view text) {
    if (starts_with(text, kBom)) text.remove_prefix(3);
    // The delimiter is whatever the header line uses most outside quotes: Excel writes ";" where the decimal separator is ",".
    std::size_t counts[3] = {0, 0, 0};
    constexpr char kDelimiters[3] = {',', ';', '\t'};
    for (std::size_t i = 0, quotes = 0; i < text.size() && text[i] != '\n' && text[i] != '\r'; ++i) {
        if (text[i] == '"') ++quotes;
        else if (quotes % 2 == 0)
            for (int d = 0; d < 3; ++d) counts[d] += text[i] == kDelimiters[d];
    }
    const int best = int(std::max_element(counts, counts + 3) - counts);
    const char delimiter = counts[best] > 0 ? kDelimiters[best] : ',';

    struct Record {
        std::vector<std::string> cells;
        std::size_t line = 0;
    };
    std::vector<Record> records;
    Record current;
    std::string field;
    bool quoted = false, inQuotes = false;
    std::size_t line = 1;
    current.line = 1;
    const auto end_field = [&] {
        current.cells.push_back(std::move(field));
        field.clear();
        quoted = false;
    };
    const auto end_record = [&] {
        end_field();
        const bool blank = current.cells.size() == 1 && current.cells[0].empty();
        if (!blank) records.push_back(std::move(current));
        current = Record{};
        current.line = line + 1;
    };
    for (std::size_t i = 0; i < text.size(); ++i) {
        const char c = text[i];
        if (inQuotes) {
            if (c == '"') {
                if (i + 1 < text.size() && text[i + 1] == '"') {
                    field += '"';
                    ++i;
                } else {
                    inQuotes = false;
                }
            } else {
                if (c == '\n') ++line;
                field += c;
            }
        } else if (c == '"' && field.empty() && !quoted) {
            inQuotes = quoted = true;
        } else if (c == delimiter) {
            end_field();
        } else if (c == '\r' || c == '\n') {
            if (c == '\r' && i + 1 < text.size() && text[i + 1] == '\n') ++i;
            end_record();
            ++line;
            current.line = line;
        } else {
            field += c;
        }
    }
    if (inQuotes)
        return make_error("row " + std::to_string(current.line) + ": a quoted field never ends",
                          "A text with a line break or a comma goes in double quotes, and a quote inside it is written twice (\"\"). "
                          "Check the last quote of that row.");
    if (!field.empty() || !current.cells.empty()) end_record();
    if (records.empty()) return make_error("the CSV file is empty", "It needs a header row `key,<languages>` (i18n.export writes one).");

    TranslationFile file;
    file.format = "csv";
    const Record& header = records.front();
    if (to_lower(trim(header.cells[0])) != "key")
        return make_error("row 1: the first column is called '" + std::string(trim(header.cells[0])) + "', not 'key'",
                          "Keep the header row `key,<languages>` that i18n.export wrote: one column per language, named by its tag (en, es, pt-BR).");
    std::vector<std::size_t> columns;
    for (std::size_t c = 1; c < header.cells.size(); ++c) {
        const std::string language(trim(header.cells[c]));
        if (language.empty()) continue;
        if (std::find(file.languages.begin(), file.languages.end(), language) != file.languages.end())
            return make_error("row 1: the language column '" + language + "' appears twice", "Keep one column per language.");
        file.languages.push_back(language);
        file.rows[language];
        columns.push_back(c);
    }
    if (file.languages.empty())
        return make_error("row 1: the header has no language columns", "The header is `key,<languages>`, e.g. key,en,es.");
    for (std::size_t r = 1; r < records.size(); ++r) {
        const Record& record = records[r];
        const std::string key(trim(record.cells[0]));
        if (key.empty()) continue;
        for (std::size_t c = header.cells.size(); c < record.cells.size(); ++c)
            if (!trim(record.cells[c]).empty())
                return make_error("row " + std::to_string(record.line) + ": '" + key + "' has " + std::to_string(record.cells.size()) +
                                      " columns but the header has " + std::to_string(header.cells.size()),
                                  "A text with a comma must be in double quotes; spreadsheets do that when they save as CSV.");
        for (std::size_t k = 0; k < columns.size(); ++k)
            file.rows[file.languages[k]].push_back({key, columns[k] < record.cells.size() ? record.cells[columns[k]] : std::string(), record.line});
    }
    return file;
}

Result<TranslationFile> read_xliff(std::string_view text) {
    if (starts_with(text, kBom)) text.remove_prefix(3);
    XliffReader reader;
    reader.file.format = "xliff";
    XmlWalker walker(text);
    if (auto walked = walker.walk(reader); !walked.ok()) return walked.error();
    if (!reader.error.empty()) return make_error(reader.error, "Every <trans-unit> needs an id (or resname) and sits in a <file> with a target-language.");
    if (!reader.sawXliff) return make_error("not an XLIFF file: there is no <xliff> element", "i18n.export writes XLIFF 1.2 files (.xlf); translate those.");
    if (reader.file.languages.empty())
        return make_error("the XLIFF file has no translation units", "A unit is <trans-unit id=\"menu.play\"><source>..</source><target>..</target></trans-unit>.");
    return std::move(reader.file);
}

Result<TranslationFile> read_translation_file(std::string_view text, std::string_view name) {
    const std::string extension = to_lower(name.substr(name.rfind('.') == std::string_view::npos ? name.size() : name.rfind('.')));
    std::string_view head = text;
    if (starts_with(head, kBom)) head.remove_prefix(3);
    head = trim(head);
    const bool xliff = extension == ".xlf" || extension == ".xliff" || (extension != ".csv" && starts_with(head, "<"));
    return xliff ? read_xliff(text) : read_csv(text);
}

}  // namespace fa
