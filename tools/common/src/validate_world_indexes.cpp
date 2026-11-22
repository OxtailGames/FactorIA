// project.validate: the world indexes (*.world.json, docs/BIG_WORLDS.md "Streaming") of the project: every one is read with
// load_world_index and EVERY cell's scene file is checked (the runtime streamer skips that check on a very big index).
#include <algorithm>
#include <filesystem>

#include "assets_internal.h"
#include "fa/core/fs.h"
#include "fa/scene/world_index.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kWorldIndexSuffix = ".world.json";

bool ends_with_suffix(const std::string& name) {
    const std::string suffix = kWorldIndexSuffix;
    return name.size() > suffix.size() && name.compare(name.size() - suffix.size(), suffix.size(), suffix) == 0;
}

std::vector<std::string> list_world_indexes(const std::string& projectDir) {
    std::vector<std::string> out;
    const stdfs::path root = fs::path_from_utf8(projectDir);
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end;
         !ec && it != end; it.increment(ec)) {
        const std::string name = fs::path_to_utf8(it->path().filename());
        const std::string rel = fs::path_to_utf8(it->path().lexically_relative(root));
        std::error_code e2;
        if (it->is_directory(e2)) {
            if ((!name.empty() && name[0] == '.') || name == "node_modules" || rel == "build")
                it.disable_recursion_pending();
            continue;
        }
        if (ends_with_suffix(name)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

}  // namespace

void check_world_indexes(const std::string& projectDir, std::vector<ValidationIssue>& errors,
                         std::vector<ValidationIssue>& warnings) {
    const std::vector<std::string> files = list_world_indexes(projectDir);
    if (files.empty()) return;
    ProjectRootGuard root(projectDir);
    for (const std::string& rel : files) {
        std::vector<WorldIndexIssue> issues;
        WorldIndexOptions options;  // checkFiles on, no cap
        auto index = load_world_index(rel, options, &issues);
        if (issues.empty() && !index.ok()) {  // not readable or not JSON: the one message
            errors.push_back({rel, "", index.error().message,
                              index.error().hint.empty() ? "Fix the file (docs/BIG_WORLDS.md \"Streaming\", "
                                                           "schemas/world.schema.json)."
                                                         : index.error().hint});
            continue;
        }
        for (const WorldIndexIssue& issue : issues) {
            ValidationIssue v{rel, issue.pointer, issue.message,
                              issue.hint.empty() ? "See docs/BIG_WORLDS.md \"Streaming\" and schemas/world.schema.json."
                                                 : issue.hint};
            (issue.error ? errors : warnings).push_back(std::move(v));
        }
    }
}

}  // namespace fa::assets_detail
