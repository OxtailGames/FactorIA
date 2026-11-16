// The structure of docs/ as files of the checkout: a size budget per doc and links that resolve.
//
// - Budget: every Markdown file of docs/ is at most 60 KB (61440 bytes), so an AI reads a page with one docs.read and a
//   doc grows by a new page, not by a longer one. Only the generated references are outside it (docs/COMPONENTS.md,
//   docs/reference/) and the translations (docs/i18n/).
// - Links: every relative Markdown link of docs/**/*.md, README*.md and CLAUDE.md names a file that exists and, with a
//   #anchor, a heading that exists (GitHub's slug rules). A split of a doc cannot break a link silently.
// - Embedded docs: docs/design/ (and the generated references) are not in the binary, so a page that is embedded and
//   links one says so in the same paragraph ("repository only, not in the binary").
#include <doctest.h>

#include "docs_test_util.h"

using namespace fa_docs_test;

TEST_CASE("docs: every doc stays within the size budget (60 KB), references and translations aside") {
    const stdfs::path repo = FA_REPO_ROOT;
    std::vector<std::string> problems;
    int checked = 0;
    for (const stdfs::path& p : markdown_files_under(repo / "docs")) {
        const std::string rel = rel_of(p);
        if (is_generated_or_translation(rel)) continue;
        ++checked;
        // Without the CR of a CRLF checkout (Windows), so the size is the same on every platform.
        const std::string content = read_all(p);
        const std::uintmax_t size = static_cast<std::uintmax_t>(
            std::count_if(content.begin(), content.end(), [](char c) { return c != '\r'; }));
        if (size > kDocBudgetBytes)
            problems.push_back(rel + ": " + std::to_string(size) + " bytes (budget " + std::to_string(kDocBudgetBytes) +
                               "): split it into pages (CLAUDE.md, docs rules)");
    }
    CHECK(checked > 100);  // the folders were found
    std::string all;
    for (const std::string& s : problems) all += "\n  - " + s;
    CHECK_MESSAGE(problems.empty(), "docs over the size budget:" << all);
}

TEST_CASE("docs: every relative Markdown link names a file and a heading that exist") {
    const stdfs::path repo = FA_REPO_ROOT;
    std::vector<stdfs::path> files = markdown_files_under(repo / "docs");
    for (const char* top : {"README.md", "README.es.md", "CLAUDE.md"}) files.push_back(repo / top);

    std::map<std::string, std::set<std::string>> anchorCache;  // by relative path
    auto anchors_for = [&](const stdfs::path& p) -> const std::set<std::string>& {
        const std::string key = rel_of(p);
        auto it = anchorCache.find(key);
        if (it == anchorCache.end()) it = anchorCache.emplace(key, anchors_of(read_all(p))).first;
        return it->second;
    };

    std::vector<std::string> problems;
    std::vector<std::string> embeddedProblems;
    int links = 0;
    for (const stdfs::path& file : files) {
        const std::string rel = rel_of(file);
        const std::string text = read_all(file);
        const std::vector<Line> lines = split_lines(text);
        for (const Link& link : links_of(text)) {
            if (is_external(link.target)) continue;
            ++links;
            const size_t hash = link.target.find('#');
            const std::string pathPart = link.target.substr(0, hash);
            const std::string anchor = hash == std::string::npos ? std::string() : link.target.substr(hash + 1);
            const std::string where = rel + ":" + std::to_string(link.line) + ": [" + link.target + "]";
            const stdfs::path target =
                pathPart.empty() ? file : (file.parent_path() / fa::fs::path_from_utf8(pathPart)).lexically_normal();
            std::error_code ec;
            if (!stdfs::exists(target, ec)) {
                problems.push_back(where + " points to " + rel_of(target) +
                                   ", which does not exist (a moved section: update the link to its new page)");
                continue;
            }
            if (!anchor.empty() && target.extension() == ".md" && stdfs::is_regular_file(target, ec)) {
                if (anchors_for(target).count(anchor) == 0)
                    problems.push_back(where + " points to a heading that " + rel_of(target) +
                                       " does not have (GitHub anchor rules; a moved section is on another page)");
            }
            // An embedded doc that links a page the binary does not carry says so.
            const std::string targetRel = rel_of(target);
            if (is_embedded_doc(rel) && starts_with(targetRel, "docs/") && !is_embedded_doc(targetRel) &&
                !says_not_embedded(paragraph_around(lines, link.line)))
                embeddedProblems.push_back(where + " is a link from an embedded doc to " + targetRel +
                                           ", which is not in the binary: say so in the same paragraph (\"repository "
                                           "only, not in the binary\"), because docs.read cannot serve it");
        }
    }
    CHECK(links > 500);  // the docs were scanned
    std::string all;
    for (const std::string& s : problems) all += "\n  - " + s;
    CHECK_MESSAGE(problems.empty(), "broken links in the docs:" << all);
    all.clear();
    for (const std::string& s : embeddedProblems) all += "\n  - " + s;
    CHECK_MESSAGE(embeddedProblems.empty(),
                  "embedded docs that link a doc outside the binary without saying so:" << all);
}

TEST_CASE("docs: the anchor rules match GitHub's (the link check depends on them)") {
    CHECK(slug_of("Linux and macOS, short output: `scripts/agent-build.sh`") ==
          "linux-and-macos-short-output-scriptsagent-buildsh");
    CHECK(slug_of("Coordinates & units") == "coordinates--units");
    CHECK(slug_of("G. Native plugins (C/C++ for one game)") == "g-native-plugins-cc-for-one-game");
    CHECK(slug_of("A [link](x.md) in a title") == "a-link-in-a-title");
    const std::set<std::string> a = anchors_of("# T\n\n## Same\n\n```\n## Not a heading\n```\n\n## Same\n");
    CHECK(a.count("same") == 1);
    CHECK(a.count("same-1") == 1);
    CHECK(a.count("not-a-heading") == 0);
    CHECK(links_of("a [b](c.md#d) and `[x](y.md)`\n```\n[z](w.md)\n```\n").size() == 1);
}

TEST_CASE("docs: anchors drop Unicode punctuation and lower-case other scripts (GitHub's slugger)") {
    CHECK(slug_of("Qué es «esto» \xE2\x80\x94 y por qué") == "qué-es-esto--y-por-qué");
    CHECK(slug_of("\xC3\x81rbol \xC3\x91o\xC3\xB1o") == "árbol-ñoño");
    CHECK(slug_of("Done \xE2\x9C\x93 \xE2\x86\x92 next") == "done---next");
    CHECK(anchors_of("# T\n\n<a id=\"explicit\"></a>\n\n```\n<a id=\"in-fence\">\n```\n").count("explicit") == 1);
    CHECK(anchors_of("<a id=\"in-fence\">").count("in-fence") == 1);
}
