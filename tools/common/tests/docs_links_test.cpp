// What links the docs to each other and to the code (M97.4), as files of the checkout (no git, no network):
//
// - Citations: `docs/X.md, "Section"` (also `X.md "Section"`) in docs, source comments, error strings and scripts names
//   a section that exists. A doc that was split into an entry page and pages keeps its sections on the pages. For a doc
//   the binary serves, the entry page is accepted when a page of it holds the heading, because docs.read {"name":"X",
//   "heading":"Section"} searches the pages (the engine promises that a citation written before the split keeps
//   working; 450 citations would otherwise change at once). For docs/design/, which docs.read does not serve, the
//   citation must name the page that holds the section: nothing finds it through the entry. A section that no page of
//   the doc has is always a failure.
// - Reachability: every doc is reachable from README.md (README.es.md for the translations) by links; an entry page
//   links all its pages.
// - Embedded docs name a doc the binary does not carry ("docs/design/...", ARCHITECTURE.md, BUILDING.md,
//   COMPONENTS.md) only in a paragraph that says "repository only, not in the binary" or names the command that
//   serves it.
// - No heading repeats inside one doc (two anchors with the same text: a link or docs.read picks the first).
// - Translations record the English text they follow (a hash of it) and say so when they are behind.
//
// Not scanned for citations: README.md, README.es.md, feedback/ and examples/ (their texts cite docs by link, and a wrong one
// is a link the structure test checks). A citation may name a heading or the bold lead of a paragraph ("**Planted feet.**");
// any bold lead of a page satisfies it, so a generic label ("**Note.**") would too: name a heading where there is one.
// No heading repeats inside a doc, whatever its level (docs/design/EXTENDING_CHECKLISTS.md, "Documentation").
//
// The link check (every `[..](x.md#anchor)` resolves) and the size budget are in docs_structure_test.cpp.
#include <doctest.h>

#include <chrono>
#include <cstring>
#include <deque>
#include <functional>
#include <regex>

#include "docs_test_util.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"

using namespace fa_docs_test;

namespace {

// ---- the files -------------------------------------------------------------------------------------------------------

struct Heading {
    std::string title;  // as written, without the '#' marks
    int line = 0;       // 1-based
    int level = 0;
};

std::vector<Heading> headings_of(const std::string& text) {
    std::vector<Heading> out;
    const std::vector<Line> lines = split_lines(text);
    for (size_t n = 0; n < lines.size(); ++n) {
        if (lines[n].inFence) continue;
        const std::string& s = lines[n].text;
        size_t i = 0;
        while (i < s.size() && s[i] == '#') ++i;
        if (i == 0 || i > 6 || i >= s.size() || s[i] != ' ') continue;
        std::string h = s.substr(i + 1);
        while (!h.empty() && (h.back() == ' ' || h.back() == '#')) h.pop_back();
        while (!h.empty() && h.front() == ' ') h.erase(h.begin());
        out.push_back({h, static_cast<int>(n) + 1, static_cast<int>(i)});
    }
    return out;
}

// The text of a heading or a citation to compare: no markup, lower case, one space between words, no trailing ':' or '.'.
std::string normalized(const std::string& s) {
    std::string out;
    bool space = false;
    for (const char ch : s) {
        if (ch == '`' || ch == '*') continue;
        if (ch == ' ' || ch == '\t') {
            space = !out.empty();
            continue;
        }
        if (space) out += ' ';
        space = false;
        out += static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
    }
    while (!out.empty() && (out.back() == ':' || out.back() == '.' || out.back() == ',')) out.pop_back();
    return out;
}

// "G. Native plugins" -> "native plugins"; "4.2 Foo" -> "foo".
std::string without_number(const std::string& n) {
    size_t i = 0;
    while (i < n.size() && (std::isalnum(static_cast<unsigned char>(n[i])) || n[i] == '.') && i < 8) ++i;
    if (i > 0 && i + 1 < n.size() && n[i] == ' ' && (n[i - 1] == '.' || std::isdigit(static_cast<unsigned char>(n[0]))))
        return n.substr(i + 1);
    return n;
}

bool is_word_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) != 0; }

// Does the heading answer to a citation? The same words (case and markup aside), or the heading starts with them and
// goes on after punctuation: "Sanitizers" names "Sanitizers (TSan, ASan)".
bool heading_matches(const std::string& heading, const std::string& cited) {
    const std::string c = normalized(cited);
    if (c.empty()) return false;
    for (const std::string& h : {normalized(heading), without_number(normalized(heading))}) {
        if (h == c) return true;
        if (h.size() > c.size() && h.compare(0, c.size(), c) == 0 && !is_word_char(h[c.size()]) && h[c.size()] != ' ')
            return true;
        if (h.size() > c.size() && h.compare(0, c.size(), c) == 0 && h[c.size()] == ' ' && h.size() > c.size() + 1 &&
            !is_word_char(h[c.size() + 1]))
            return true;
    }
    return false;
}

// The bold lead of a paragraph or list item ("**Planted feet.** If the clip..."): the docs name many sections that way,
// and docs.search finds them. A citation may name one; a heading is better where there is one.
std::vector<Heading> labels_of(const std::string& text) {
    std::vector<Heading> out;
    const std::vector<Line> lines = split_lines(text);
    for (size_t n = 0; n < lines.size(); ++n) {
        if (lines[n].inFence) continue;
        const std::string& s = lines[n].text;
        size_t i = 0;
        if (s.compare(0, 2, "- ") == 0 || s.compare(0, 2, "* ") == 0) i = 2;
        if (s.compare(i, 2, "**") != 0) continue;
        const size_t end = s.find("**", i + 2);
        if (end == std::string::npos) continue;
        out.push_back({s.substr(i + 2, end - (i + 2)), static_cast<int>(n) + 1, 7});
    }
    return out;
}

// Files that can hold a citation: the sources of the engine, the tools, the scripts and the workflows.
bool is_citing_file(const stdfs::path& p) {
    static const std::set<std::string> kinds = {".h",   ".hpp", ".cpp",  ".cc",   ".c",  ".mm",   ".m",      ".js",
                                                ".mjs", ".ts",  ".sh",   ".ps1",  ".py", ".yml",  ".yaml",   ".cmake",
                                                ".txt", ".md",  ".json", ".glsl", ".kt", ".java", ".gradle", ".html"};
    const std::string ext = p.extension().generic_string();
    const std::string name = p.filename().generic_string();
    return kinds.count(ext) != 0 || name == "CMakeLists.txt";
}

struct Source {
    std::string rel;
    std::string text;
};

// Every file that may cite a doc, read once for the tests below.
const std::vector<Source>& citing_sources() {
    static const std::vector<Source> all = [] {
        std::vector<Source> out;
        const stdfs::path repo = FA_REPO_ROOT;
        static const std::set<std::string> skipDirs = {"build",  "external", "node_modules", ".git",
                                                       "corpus", ".cache",   "i18n",         "reference"};
        for (const char* top : {"engine", "tools", "scripts", ".github", "schemas", "templates", "docs", "platforms"}) {
            if (!stdfs::exists(repo / top)) continue;
            stdfs::recursive_directory_iterator it(repo / top), end;
            for (; it != end; ++it) {
                if (it->is_directory()) {
                    if (skipDirs.count(it->path().filename().generic_string()) != 0) it.disable_recursion_pending();
                    continue;
                }
                std::error_code ec;
                if (!it->is_regular_file(ec) || !is_citing_file(it->path()) || it->file_size(ec) > (1u << 21)) continue;
                const std::string rel = rel_of(it->path());
                if (rel == "docs/COMPONENTS.md") continue;  // generated
                out.push_back({rel, read_all(it->path())});
            }
        }
        out.push_back({"CLAUDE.md", read_all(repo / "CLAUDE.md")});
        std::sort(out.begin(), out.end(), [](const Source& a, const Source& b) { return a.rel < b.rel; });
        return out;
    }();
    return all;
}

// Every doc of docs/ (not the translations) and its headings, by path below the checkout.
const std::map<std::string, std::vector<Heading>>& doc_headings() {
    static const std::map<std::string, std::vector<Heading>> all = [] {
        std::map<std::string, std::vector<Heading>> out;
        const stdfs::path repo = FA_REPO_ROOT;
        for (const stdfs::path& p : markdown_files_under(repo / "docs")) {
            const std::string rel = rel_of(p);
            if (starts_with(rel, "docs/i18n/")) continue;
            const std::string text = read_all(p);
            out[rel] = headings_of(text);
            for (Heading& l : labels_of(text)) out[rel].push_back(std::move(l));
        }
        for (const char* top : {"README.md", "CLAUDE.md"}) out[top] = headings_of(read_all(repo / top));
        return out;
    }();
    return all;
}

// The pages of an entry page: docs/<topic>/X_*.md for docs/X.md (docs/design/X_*.md for docs/design/X.md). The prefix X_
// is the whole rule: a future docs/AI.md would adopt AI_GUIDE_*.md, AI_COSTS_*.md and AI_PROVIDERS_*.md as its pages.
std::vector<std::string> pages_of(const std::string& entryRel) {
    std::vector<std::string> out;
    const std::string name = stdfs::path(entryRel).filename().generic_string();
    if (!starts_with(entryRel, "docs/") || name.size() < 4) return out;
    const std::string stem = name.substr(0, name.size() - 3);
    for (const auto& [rel, heads] : doc_headings()) {
        const std::string other = stdfs::path(rel).filename().generic_string();
        if (rel != entryRel && starts_with(rel, "docs/") && starts_with(other, stem + "_")) out.push_back(rel);
    }
    return out;
}

// The doc a citation names: "docs/sound/SOUND_MIXER.md" as written, or a bare "SOUND_MIXER.md" when exactly one doc has
// that file name. Empty when the name is not a doc of the checkout (a file of a game, a template...).
std::string cited_doc(const std::string& path, bool& missing) {
    missing = false;
    if (starts_with(path, "docs/")) {
        if (doc_headings().count(path) != 0) return path;
        missing = true;
        return path;
    }
    if (path.find('/') != std::string::npos) return {};
    std::string found;
    int n = 0;
    for (const auto& [rel, heads] : doc_headings())
        if (stdfs::path(rel).filename().generic_string() == path) {
            found = rel;
            ++n;
        }
    return n == 1 ? found : std::string();
}

struct Citation {
    std::string path;     // the .md as written
    std::string section;  // the text between the quotes
    int line = 0;
};

// The text with every comment or quote prefix of a line (`//`, `#`, `*`, `>`) removed and the lines joined by one space,
// so a citation broken across two lines reads as one. `lineOf[k]` is the original line of byte k.
struct Flat {
    std::string text;
    std::vector<int> lineOf;
};

Flat flatten(const std::string& src) {
    Flat f;
    f.text.reserve(src.size());
    f.lineOf.reserve(src.size());
    int line = 1;
    size_t pos = 0;
    while (pos <= src.size()) {
        size_t end = src.find('\n', pos);
        if (end == std::string::npos) end = src.size();
        size_t k = pos;
        while (k < end && (src[k] == ' ' || src[k] == '\t')) ++k;
        // A prefix only counts when it is followed by a space or ends the line ("#include" or "*ptr" are not prefixes).
        size_t afterPrefix = k;
        if (src.compare(k, 2, "//") == 0)
            afterPrefix = k + 2;
        else if (k < end && (src[k] == '#' || src[k] == '*' || src[k] == '>'))
            afterPrefix = k + 1;
        if (afterPrefix != k) {
            while (afterPrefix < end && (src[afterPrefix] == '/' || src[afterPrefix] == '#' || src[afterPrefix] == '*'))
                ++afterPrefix;
            if (afterPrefix < end && src[afterPrefix] != ' ') afterPrefix = k;
        }
        while (afterPrefix < end && (src[afterPrefix] == ' ' || src[afterPrefix] == '\t')) ++afterPrefix;
        // Two string literals side by side ("..." newline "...") are one: drop the quote that ends one and opens the next.
        if (afterPrefix < end && src[afterPrefix] == '"' && f.text.size() >= 3 && f.text.back() == ' ' &&
            f.text[f.text.size() - 2] == '"' && f.text[f.text.size() - 3] != '\\') {
            f.text.resize(f.text.size() - 2);
            f.lineOf.resize(f.text.size());
            ++afterPrefix;
        }
        for (size_t m = afterPrefix; m < end; ++m) {
            if (src[m] == '\r') continue;
            f.text.push_back(src[m]);
            f.lineOf.push_back(line);
        }
        f.text.push_back(' ');
        f.lineOf.push_back(line);
        ++line;
        pos = end + 1;
    }
    return f;
}

// True when text[pos..] (after spaces) starts a JSON value: { [ " a digit or - , or true / false / null as a whole word.
// It accepts some false negatives: a title followed by a value that starts with a digit, `-` or `"` (`X.md, "T": 5`,
// `X.md, "T": "text"`) is taken for a JSON key and not checked, and so is a title whose closing quote is escaped
// (the escaped-quote branch of citations_of).
bool starts_json_value(const std::string& text, size_t pos) {
    while (pos < text.size() && text[pos] == ' ') ++pos;
    if (pos >= text.size()) return false;
    const char c = text[pos];
    if (c == '{' || c == '[' || c == '"' || c == '-' || std::isdigit(static_cast<unsigned char>(c))) return true;
    for (const char* w : {"true", "false", "null"}) {
        const size_t n = std::strlen(w);
        if (text.compare(pos, n, w) == 0 &&
            (pos + n >= text.size() || !std::isalpha(static_cast<unsigned char>(text[pos + n]))))
            return true;
    }
    return false;
}

// `X.md, "Section"`, `X.md "Section"`, `X.md, \"Section\"` (in a string literal), `X.md`, "Section" (backticks),
// [X.md](X.md), "Section" (a link), the same split across two lines, and the "and"/"or" lists of sections after the
// first one.
// `json`: the source is a .json file, where `"X.md", "key": value` is a key, not a citation with a colon after it.
std::vector<Citation> citations_of(const std::string& source, bool json = false) {
    const Flat flat = flatten(source);
    const std::string& text = flat.text;
    std::vector<Citation> out;
    for (size_t i = text.find(".md"); i != std::string::npos; i = text.find(".md", i + 3)) {
        if (i + 3 < text.size() && is_word_char(text[i + 3])) continue;
        size_t b = i;
        while (b > 0 && (is_word_char(text[b - 1]) || text[b - 1] == '_' || text[b - 1] == '-' || text[b - 1] == '/' ||
                         text[b - 1] == '.'))
            --b;
        const std::string path = text.substr(b, i + 3 - b);
        if (path.size() < 4 || path[0] == '.' || path[0] == '/') continue;  // a URL's path or a file name
        const int line = flat.lineOf[i];
        // `[text](y.md "Title")`: a link with a title, not a citation
        if (b >= 2 && text[b - 1] == '(' && text[b - 2] == ']' && i + 4 < text.size() && text[i + 3] == ' ' &&
            text[i + 4] == '"')
            continue;
        size_t j = i + 3;
        if (j < text.size() && text[j] == '`') ++j;
        if (j + 1 < text.size() && text[j] == ']' && text[j + 1] == '(') {  // [X.md](target)
            const size_t close = text.find(')', j);
            if (close == std::string::npos || close - j > 200) continue;
            j = close + 1;
        } else if (j < text.size() && text[j] == ')') {
            // `[text](X.md), "Section"`: the link target; any other `X.md)` is the end of a parenthesis
            if (b >= 2 && text[b - 1] == '(' && text[b - 2] == ']')
                ++j;
            else
                continue;
        }
        if (j < text.size() && text[j] == '`') ++j;
        if (j < text.size() && text[j] == ',') ++j;
        while (j < text.size() && text[j] == ' ') ++j;
        if (text.compare(j, 8, "section ") == 0) j += 8;
        auto quote_at = [&](size_t k) -> size_t {  // the position after an opening quote (or \"), or npos
            if (k < text.size() && text[k] == '"') return k + 1;
            if (k + 1 < text.size() && text[k] == '\\' && text[k + 1] == '"') return k + 2;
            return std::string::npos;
        };
        size_t q = quote_at(j);
        while (q != std::string::npos) {
            size_t e = q;
            while (e < text.size() && text[e] != '"' && e - q < 90) ++e;
            if (e >= text.size() || text[e] != '"') break;
            const size_t close = e;
            // A JSON key, not a title: in a .json file, in JSON written inside a string literal, or a colon followed by
            // a JSON value (`"text": {`). `X.md, "Title": what it says` in a doc or a comment is a citation.
            if (close + 1 < text.size() && text[close + 1] == ':' &&
                (json || (q >= 2 && text[q - 2] == '\\') || starts_json_value(text, close + 2)))
                break;
            std::string section = text.substr(q, close - q);
            if (!section.empty() && section.back() == '\\') section.pop_back();
            // A quote that closes a string literal before the name ("x", "docs/X.md", ...) or opens a literal that goes
            // on after it ("Render " "section"): not a section title.
            if (!section.empty() && std::isalnum(static_cast<unsigned char>(section.front())) &&
                section.back() != ' ') {
                Citation c{path, section, line};
                if (out.empty() || out.back().path != c.path || out.back().section != c.section ||
                    out.back().line != c.line)
                    out.push_back(c);
            }
            // ` and "B"`, `, "B"`, ` or "B"`
            size_t k = close + 1;
            if (k < text.size() && text[k] == ',') ++k;
            while (k < text.size() && text[k] == ' ') ++k;
            if (text.compare(k, 4, "and ") == 0)
                k += 4;
            else if (text.compare(k, 3, "or ") == 0)
                k += 3;
            else if (k == close + 1)
                break;
            q = quote_at(k);
        }
    }
    return out;
}

std::string join_lines(const std::vector<std::string>& v) {
    std::string all;
    for (const std::string& s : v) all += "\n  - " + s;
    return all;
}

}  // namespace

// ---- citations -------------------------------------------------------------------------------------------------------

TEST_CASE("docs: every citation 'X.md, \"Section\"' names a section of that doc, on the page that holds it") {
    std::vector<std::string> problems;
    int checked = 0;
    for (const Source& src : citing_sources()) {
        if (src.rel == "tools/common/tests/docs_links_test.cpp") continue;  // its examples of a citation
        for (const Citation& c :
             citations_of(src.text, src.rel.size() > 5 && src.rel.compare(src.rel.size() - 5, 5, ".json") == 0)) {
            bool missing = false;
            const std::string doc = cited_doc(c.path, missing);
            if (doc.empty()) continue;
            const std::string where =
                src.rel + ":" + std::to_string(c.line) + ": cites " + c.path + ", \"" + c.section + "\"";
            if (missing) {
                std::vector<std::string> names;
                for (const auto& [rel, heads] : doc_headings()) names.push_back(rel);
                problems.push_back(where + ": " + c.path + " does not exist (a doc that moved into docs/design/ or a " +
                                   "topic folder?). " + fa::did_you_mean(c.path, names));
                continue;
            }
            ++checked;
            auto holds = [&](const std::string& rel) {
                for (const Heading& h : doc_headings().at(rel))
                    if (heading_matches(h.title, c.section)) return true;
                return false;
            };
            if (holds(doc)) continue;
            std::string onPage;
            for (const std::string& page : pages_of(doc))
                if (holds(page)) onPage += (onPage.empty() ? "" : ", ") + page;
            if (!onPage.empty()) {
                // docs.read {"name":"X","heading":"Section"} finds a section on a page of X (so a citation written
                // before the split keeps working), but only for a doc the binary serves.
                if (is_embedded_doc(doc)) continue;
                problems.push_back(where + ": the section is not on the entry page " + doc + " but on " + onPage +
                                   ": cite the page (docs.read does not serve docs/design/, so nothing finds it "
                                   "through the entry)");
                continue;
            }
            std::vector<std::string> titles;
            for (const Heading& h : doc_headings().at(doc)) titles.push_back(h.title);
            for (const std::string& page : pages_of(doc))
                for (const Heading& h : doc_headings().at(page)) titles.push_back(h.title);
            problems.push_back(where + ": " + doc + " and its pages have no such heading (renamed or removed?). " +
                               fa::did_you_mean(c.section, titles));
        }
    }
    CHECK(checked > 300);  // the sources were scanned
    CHECK_MESSAGE(problems.empty(), "citations of a doc section that does not resolve:" << join_lines(problems));
}

TEST_CASE("docs: the citation scanner reads what the docs and the source write") {
    const std::vector<Citation> a =
        citations_of("// (docs/MUSIC.md, \"Writing notes\") and docs/SOUND.md \"Foo\" or \"Bar\"\n"
                     "throw Error(\"see docs/EDITOR.md, \\\"Run only\\\".\"); see https://x.org/y.md, \"no\"; a.md.\n");
    REQUIRE(a.size() == 4);
    CHECK(a[0].path == "docs/MUSIC.md");
    CHECK(a[0].section == "Writing notes");
    CHECK(a[1].section == "Foo");
    CHECK(a[2].section == "Bar");
    CHECK(a[2].line == 1);
    CHECK(a[3].section == "Run only");
    CHECK(a[3].line == 2);
    const std::vector<Citation> w =
        citations_of("see `docs/X.md`, \"Tick\" and [Y.md](Y.md), \"Link\" and [Z](docs/Z.md), \"Target\".\n"
                     "// docs/W.md,\n"
                     "// \"Split path\" and V.md, \"A title that\n"
                     "// breaks\".\n");
    REQUIRE(w.size() == 5);
    CHECK(w[0].section == "Tick");
    CHECK(w[1].section == "Link");
    CHECK(w[2].section == "Target");
    CHECK(w[3].section == "Split path");
    CHECK(w[3].line == 2);
    CHECK(w[4].section == "A title that breaks");
    // `X.md, "Title": explanation` is a citation (the colon does not hide it); a JSON key after one is not
    const std::vector<Citation> colon = citations_of("see ANIMATION.md, \"Tweens\": the steps.\n");
    REQUIRE(colon.size() == 1);
    CHECK(colon[0].section == "Tweens");
    CHECK(citations_of("{\"file\": \"X.md\", \"key\": 1}\n", true).empty());
    // the `json` flag decides: `: foo` is not a JSON value, so only a .json source treats the title as a key
    CHECK(citations_of("docs/X.md, \"Title\": foo\n", true).empty());
    CHECK(citations_of("docs/X.md, \"Title\": foo\n", false).size() == 1);
    CHECK(citations_of("// docs/X.md, \"text\": { \"a\": 1 }\n").empty());  // a JSON key in a comment
    // a link with a title is not a citation; a link without one still is
    CHECK(citations_of("[x](docs/Y.md \"Title\") and [z](docs/Z.md), \"Real\"\n").size() == 1);
    // CRLF: the citation of a line that ends in \r\n reads like the one of a \n file
    const std::vector<Citation> crlf = citations_of("// docs/W.md,\r\n// \"Split path\" and\r\n// V.md, \"Next\".\r\n");
    REQUIRE(crlf.size() == 2);
    CHECK(crlf[1].section == "Next");
    CHECK(heading_matches("Sanitizers (TSan, ASan)", "Sanitizers"));
    CHECK(heading_matches("`docs.read`: reading", "docs.read"));
    CHECK(heading_matches("G. Native plugins", "Native plugins"));
    CHECK_FALSE(heading_matches("Sanitizers and more", "Sanitizers"));
    CHECK_FALSE(heading_matches("Fuzzing", "Fuzz"));
}

// ---- reachability ----------------------------------------------------------------------------------------------------

TEST_CASE("docs: every doc is reachable from README.md (README.es.md for the translations) by links") {
    const stdfs::path repo = FA_REPO_ROOT;
    std::set<std::string> all;  // every Markdown file that must be reachable
    for (const stdfs::path& p : markdown_files_under(repo / "docs")) all.insert(rel_of(p));

    std::set<std::string> seen;
    std::deque<std::string> todo;
    std::map<std::string, std::set<std::string>> linksOf;  // rel -> rel of every linked Markdown file
    auto visit = [&](const std::string& rel) {
        if (seen.insert(rel).second) todo.push_back(rel);
    };
    visit("README.md");
    visit("README.es.md");
    while (!todo.empty()) {
        const std::string rel = todo.front();
        todo.pop_front();
        const stdfs::path file = repo / rel;
        std::error_code ec;
        if (!stdfs::is_regular_file(file, ec)) continue;
        for (const Link& l : links_of(read_all(file))) {
            if (is_external(l.target)) continue;
            const std::string pathPart = l.target.substr(0, l.target.find('#'));
            if (pathPart.size() < 3 || pathPart.substr(pathPart.size() - 3) != ".md") continue;
            const stdfs::path target = (file.parent_path() / fa::fs::path_from_utf8(pathPart)).lexically_normal();
            const std::string targetRel = rel_of(target);
            linksOf[rel].insert(targetRel);
            if (all.count(targetRel) != 0) visit(targetRel);
        }
    }
    std::vector<std::string> problems;
    for (const std::string& rel : all) {
        if (seen.count(rel) != 0) continue;
        std::string hint = "link it from the README or from the entry page of its topic";
        const std::string name = stdfs::path(rel).filename().generic_string();
        const size_t us = name.find('_');
        if (us != std::string::npos) {
            const std::string entry = name.substr(0, us) + ".md";
            for (const std::string& cand : {"docs/" + entry, "docs/design/" + entry})
                if (all.count(cand) != 0) hint = "it is a page of " + cand + ": add it to that page's list of pages";
        }
        problems.push_back(rel + " is not linked from any doc reachable from README.md: " + hint);
    }
    CHECK(seen.size() > 100);
    CHECK_MESSAGE(problems.empty(), "docs nobody can reach:" << join_lines(problems));
}

TEST_CASE("docs: an entry page links every one of its pages") {
    const stdfs::path repo = FA_REPO_ROOT;
    std::vector<std::string> problems;
    int entries = 0;
    for (const auto& [rel, heads] : doc_headings()) {
        if (!starts_with(rel, "docs/")) continue;
        const std::vector<std::string> pages = pages_of(rel);
        if (pages.empty()) continue;
        ++entries;
        std::set<std::string> linked;
        const stdfs::path file = repo / rel;
        for (const Link& l : links_of(read_all(file))) {
            if (is_external(l.target)) continue;
            const std::string pathPart = l.target.substr(0, l.target.find('#'));
            if (pathPart.empty()) continue;
            linked.insert(rel_of((file.parent_path() / fa::fs::path_from_utf8(pathPart)).lexically_normal()));
        }
        for (const std::string& page : pages)
            if (linked.count(page) == 0)
                problems.push_back(rel + " does not link its page " + page +
                                   " (add it to the list under \"## Pages\")");
    }
    CHECK(entries > 10);
    CHECK_MESSAGE(problems.empty(), "pages an entry page does not list:" << join_lines(problems));
}

// ---- embedded docs and docs outside the binary -----------------------------------------------------------------------

TEST_CASE("docs: an embedded doc names a doc outside the binary only with a note or the command that serves it") {
    // docs/design/<page>.md, the generated references and the translations are not in the binary.
    std::set<std::string> designNames;
    for (const auto& [rel, heads] : doc_headings())
        if (starts_with(rel, "docs/design/")) designNames.insert(stdfs::path(rel).filename().generic_string());
    const std::vector<std::string> markers = {"docs/design/", "docs/reference/", "docs/i18n/", "COMPONENTS.md"};
    const stdfs::path repo = FA_REPO_ROOT;
    std::vector<std::string> problems;
    int embedded = 0;
    for (const auto& [rel, heads] : doc_headings()) {
        if (!is_embedded_doc(rel)) continue;
        ++embedded;
        const std::vector<Line> lines = split_lines(read_all(repo / rel));
        for (size_t n = 0; n < lines.size(); ++n) {
            if (lines[n].inFence) continue;
            // Link targets are checked by docs_structure_test.cpp; here the words a reader sees.
            std::string s;
            for (size_t i = 0; i < lines[n].text.size(); ++i) {
                if (lines[n].text[i] == ']' && i + 1 < lines[n].text.size() && lines[n].text[i + 1] == '(') {
                    const size_t close = lines[n].text.find(')', i);
                    if (close != std::string::npos) {
                        i = close;
                        continue;
                    }
                }
                s += lines[n].text[i];
            }
            std::string hit;
            for (const std::string& m : markers)
                if (s.find(m) != std::string::npos) hit = m;
            if (hit.empty()) {
                // A bare name of a design page (ARCHITECTURE.md, BUILDING_TESTS.md, EXTENDING_COMMANDS.md).
                for (const std::string& name : designNames) {
                    const size_t at = s.find(name);
                    if (at == std::string::npos) continue;
                    if (at > 0 && (is_word_char(s[at - 1]) || s[at - 1] == '_' || s[at - 1] == '/')) continue;
                    hit = name;
                    break;
                }
            }
            if (hit.empty()) continue;
            const std::string p = paragraph_around(lines, static_cast<int>(n) + 1);
            if (says_not_embedded(p) || p.find("docs.components") != std::string::npos ||
                p.find("docs.reference") != std::string::npos || p.find("factoria docs") != std::string::npos)
                continue;
            problems.push_back(rel + ":" + std::to_string(n + 1) + ": names " + hit +
                               ", which docs.read cannot serve: say \"(repository only, not in the binary)\" in the "
                               "same paragraph, or name the command that serves it (docs.components for the "
                               "components)");
        }
    }
    CHECK(embedded > 50);
    CHECK_MESSAGE(problems.empty(),
                  "embedded docs that name a doc outside the binary without saying so:" << join_lines(problems));
}

// ---- headings --------------------------------------------------------------------------------------------------------

TEST_CASE("docs: no heading repeats inside one doc (its anchor would be ambiguous)") {
    const stdfs::path repo = FA_REPO_ROOT;
    std::vector<std::string> problems;
    int docs = 0;
    for (const stdfs::path& p : markdown_files_under(repo / "docs")) {
        const std::string rel = rel_of(p);
        if (starts_with(rel, "docs/reference/") || rel == "docs/COMPONENTS.md") continue;  // generated
        ++docs;
        std::map<std::string, int> firstLine;
        for (const Heading& h : headings_of(read_all(p))) {
            const std::string slug = slug_of(h.title);
            auto [it, fresh] = firstLine.emplace(slug, h.line);
            if (!fresh)
                problems.push_back(rel + ":" + std::to_string(h.line) + ": the heading \"" + h.title +
                                   "\" repeats line " + std::to_string(it->second) + ": rename one (a link to #" +
                                   slug + " and docs.read would take the first)");
        }
    }
    CHECK(docs > 100);
    CHECK_MESSAGE(problems.empty(), "repeated headings:" << join_lines(problems));
}

// ---- translations ----------------------------------------------------------------------------------------------------

namespace {

// The first 16 hex digits of the SHA-256 of a file without its CRs: the same on a CRLF checkout.
// For README.md (`readme` true) the version number of the line that starts with "Version x.y" (the pattern of
// readme_version_test.cpp) is left out, and only the number: every version bump edits it, and it would make the hash
// stale in each release, while the rest of that line is real Status text.
std::string content_hash_of(std::string t, bool readme) {
    t.erase(std::remove(t.begin(), t.end(), '\r'), t.end());
    if (readme) {
        static const std::regex versionNumber(R"((^|\n)Version \d+\.\d+\b)");
        t = std::regex_replace(t, versionNumber, "$1Version");
    }
    fa::Sha256 h;
    h.update(t);
    return h.finish_hex().substr(0, 16);
}
std::string content_hash(const stdfs::path& p) { return content_hash_of(read_all(p), p.filename() == "README.md"); }

}  // namespace

// (The line of README.md that starts with "Version x.y" is not part of the hash, so a version bump keeps it valid.)
// A translation starts with `<!-- follows <English file> sha256:<16 hex> -->`: the English text it was brought up to
// date with. When that file changes, the hash no longer matches and the translation must be updated (and the hash with
// it) or say it is behind: `<!-- follows <file> sha256:<hash or unknown> behind -->` (and its visible notice). A hash,
// not a git commit: it needs no history (a CI checkout can be shallow, a source tarball has none).
TEST_CASE("docs: a translation records the English text it follows, and says so when that text has changed") {
    const stdfs::path repo = FA_REPO_ROOT;
    std::vector<stdfs::path> files = {repo / "README.es.md"};
    for (const stdfs::path& p : markdown_files_under(repo / "docs/i18n")) files.push_back(p);
    std::vector<std::string> problems;
    for (const stdfs::path& p : files) {
        const std::string rel = rel_of(p);
        const std::string text = read_all(p);
        const std::string first = text.substr(0, text.find('\n'));
        // README.<lang>.md follows README.md; docs/i18n/<lang>/X.md follows docs/X.md (docs/<topic>/X.md for a page).
        std::string english =
            starts_with(rel, "docs/i18n/") ? "docs/" + stdfs::path(rel).filename().generic_string() : "README.md";
        const std::string example = "<!-- follows " + english + " sha256:" +
                                    (stdfs::exists(repo / english) ? content_hash(repo / english) : "<hash>") + " -->";
        if (!starts_with(first, "<!-- follows ")) {
            problems.push_back(rel + ":1: the first line does not record the English text it follows; write " +
                               example +
                               " (or add \" behind\" before the \"-->\" when it is not up to date, with a notice)");
            continue;
        }
        std::string body = first.substr(13);
        while (!body.empty() && (body.back() == '\r' || body.back() == ' ')) body.pop_back();
        if (body.size() < 4 || body.compare(body.size() - 3, 3, "-->") != 0) {
            problems.push_back(rel + ":1: the line does not end with \"-->\"; write " + example);
            continue;
        }
        body = body.substr(0, body.size() - 3);
        while (!body.empty() && body.back() == ' ') body.pop_back();
        const bool behind = body.size() > 7 && body.compare(body.size() - 7, 7, " behind") == 0;
        if (behind) body.resize(body.size() - 7);
        const size_t sp = body.find(" sha256:");
        if (sp == std::string::npos) {
            problems.push_back(rel + ":1: the line has no \" sha256:<hash>\"; write " + example);
            continue;
        }
        const std::string path = body.substr(0, sp);
        const std::string hash = body.substr(sp + 8);
        std::error_code ec;
        if (!stdfs::is_regular_file(repo / path, ec)) {
            problems.push_back(rel + ":1: follows " + path +
                               ", which does not exist (the English file moved?): write " + example);
            continue;
        }
        const std::string now = content_hash(repo / path);
        if (hash == "unknown") {
            if (!behind)
                problems.push_back(rel +
                                   ":1: \"sha256:unknown\" is only for a translation that says it is behind: "
                                   "update the translation and write sha256:" +
                                   now + ", or add \" behind\"");
        } else if (hash != now && !behind) {
            problems.push_back(rel + ":1: " + path + " changed after this translation was brought up to date (hash " +
                               hash + ", now " + now + "): translate what changed and write sha256:" + now +
                               ", or add \" behind\" to the line and a notice that says what is missing");
        } else if (hash == now && behind) {
            problems.push_back(rel + ":1: marked behind, but its hash matches " + path +
                               ": remove \" behind\" and the notice");
        }
        const std::string rest = text.substr(first.size());
        if (behind && rest.find("va por detr") == std::string::npos && rest.find("behind") == std::string::npos)
            problems.push_back(rel + ":1: marked behind without a visible notice at the top");
    }
    CHECK(files.size() >= 2);
    CHECK_MESSAGE(problems.empty(), "translations that do not follow their English text:" << join_lines(problems));
}

TEST_CASE("docs: the content hash of a translation's original ignores CRs") {
    // a name of its own: two checkouts running ctest at once must not share (or remove) each other's files
    const stdfs::path tmp =
        stdfs::temp_directory_path() /
        ("fa_docs_links_hash_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    stdfs::create_directories(tmp);
    {
        std::ofstream(tmp / "a.md", std::ios::binary) << "x\ny\n";
        std::ofstream(tmp / "b.md", std::ios::binary) << "x\r\ny\r\n";
    }
    CHECK(content_hash(tmp / "a.md") == content_hash(tmp / "b.md"));
    CHECK(content_hash(tmp / "a.md").size() == 16);
    std::error_code ec;
    stdfs::remove_all(tmp, ec);
}

TEST_CASE("docs: the hash of README.md ignores the version number, and only that") {
    CHECK(content_hash_of("# T\n\nVersion 0.29, alpha.\nbody\n", true) ==
          content_hash_of("# T\n\nVersion 0.30, alpha.\nbody\n", true));
    CHECK(content_hash_of("# T\n\nVersion 0.29, alpha.\nbody\n", true) !=
          content_hash_of("# T\n\nVersion 0.29, beta.\nbody\n", true));
    CHECK(content_hash_of("# T\n\nVersion 0.29\nbody\n", true) !=
          content_hash_of("# T\n\nVersion 0.29\nbody2\n", true));
    CHECK(content_hash_of("a\nVersion 1.2\n", true) == content_hash_of("a\r\nVersion 3.4\r\n", true));
    // any other document keeps the number
    CHECK(content_hash_of("a\nVersion 1.2\n", false) != content_hash_of("a\nVersion 3.4\n", false));
}
