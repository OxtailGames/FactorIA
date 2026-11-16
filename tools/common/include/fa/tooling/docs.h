// Documentation served to AIs (docs/*.md embedded in the binary).
//   docs.list / docs.read / docs.search commands, plus the same as functions.
// Doc names: file stem lowercased with '_' -> '-' ("AI_GUIDE.md" -> "ai-guide",
// "SCRIPTING.md" -> "scripting"). A big doc is an entry page `docs/<NAME>.md` plus pages
// `docs/<name>/<NAME>_<PART>.md` (its family; docs/ARCHITECTURE_RUNTIME.md, "Docs"). "components" and "commands" fall back to
// generated reference when no such file exists.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/types.h"

namespace fa {

struct DocInfo {
    std::string name;   // "ai-guide"
    std::string path;   // "docs/AI_GUIDE.md"
    std::string title;  // first heading
    std::size_t bytes = 0;
    std::string summary;  // one sentence: what the page is for (the manifest in docs.cpp)
    std::vector<std::string>
        audience;        // "gameAi" (the AI making a game), "user" (the person using the engine), "engineDev"
    std::string family;  // a page of a split doc: the entry page's name ("scripting"); empty for every other doc
};

// The manifest behind `summary` and `audience`: one entry per embedded doc.
struct DocManifestEntry {
    std::string name;
    std::string summary;
    std::vector<std::string> audience;
};
const std::vector<DocManifestEntry>& doc_manifest();

struct DocHit {
    std::string doc;     // name (of the page, for a page of a split doc)
    std::string family;  // the entry page's name when `doc` is a page, else empty
    std::string path;
    std::string heading;  // section containing the match
    int line = 0;         // 1-based line of the best match
    double score = 0;
    std::string snippet;
};

std::vector<DocInfo> list_docs();
// By name ("ai-guide"), file name ("AI_GUIDE.md") or path ("docs/AI_GUIDE.md"; "schemas/x.json" also works).
Result<std::string> read_doc(std::string_view nameOrPath);
// The pages of the family of `entryName` (docs/<NAME>.md plus every embedded doc under docs/<name>/), sorted by path.
std::vector<DocInfo> doc_family_pages(std::string_view entryName);
// What is wrong with the layout of the embedded docs, one message per problem (empty when fine): two docs with the same
// name (both paths), a page in a folder whose entry page does not exist, a page its entry page does not link to by
// relative path. A test runs it on the real docs.
std::vector<std::string> doc_layout_problems();

// Test seam: serve docs/ from these functions instead of the bundle (nullptr: the bundle again). `list` receives
// "docs/" and returns repository-relative paths.
struct DocFiles {
    std::function<std::vector<std::string>(std::string_view prefix)> list;
    std::function<std::optional<std::string>(std::string_view path)> read;
};
void set_doc_files_for_tests(const DocFiles* files);

std::vector<DocHit> search_docs(std::string_view query, std::size_t maxResults = 8);

void register_docs_commands(CommandRegistry& registry);

}  // namespace fa
