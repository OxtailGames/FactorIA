// Documentation served to AIs (docs/*.md embedded in the binary).
//   docs.list / docs.read / docs.search commands, plus the same as functions.
// Doc names: file stem lowercased with '_' -> '-' ("AI_GUIDE.md" -> "ai-guide",
// "SCRIPTING.md" -> "scripting"). "components" and "commands" fall back to
// generated reference when no such file exists.
#pragma once

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
};

struct DocHit {
    std::string doc;      // name
    std::string path;
    std::string heading;  // section containing the match
    int line = 0;         // 1-based line of the best match
    double score = 0;
    std::string snippet;
};

std::vector<DocInfo> list_docs();
// By name ("ai-guide"), file name ("AI_GUIDE.md") or path ("docs/AI_GUIDE.md"; "schemas/x.json" also works).
Result<std::string> read_doc(std::string_view nameOrPath);
std::vector<DocHit> search_docs(std::string_view query, std::size_t maxResults = 8);

void register_docs_commands(CommandRegistry& registry);

}  // namespace fa
