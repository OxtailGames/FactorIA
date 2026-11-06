// project.validate for effect documents (`*.vfx.json`, docs/PARTICLES.md "Effect documents"): every problem of a file is an error with
// its JSON pointer and the fix, a sound clip that is not in the project is an error, and the warnings of the parser (a `rate` with no
// duration, too many live particles) are warnings.
#include <algorithm>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/scene/vfx.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

std::vector<std::string> list_vfx_documents(const std::string& projectDir) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path root = stdfs::path(projectDir);
    if (!stdfs::is_directory(root, ec)) return out;
    // The whole project, as the scene validator walks it: an effect may live in any folder (vfx.play takes any project path).
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        const bool topBuild = it.depth() == 0 && it->path().filename() == "build";
        if (it->is_directory(ec) && (topBuild || it->path().filename() == "node_modules" || starts_with(it->path().filename().string(), "."))) {
            it.disable_recursion_pending();
            continue;
        }
        if (!it->is_regular_file(ec)) continue;
        const std::string rel = stdfs::relative(it->path(), projectDir, ec).generic_string();
        if (ends_with(to_lower(rel), ".vfx.json")) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

}  // namespace

void check_vfx_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings,
                         const std::set<std::string>& referenced) {
    std::vector<std::string> files = list_vfx_documents(projectDir);
    std::set<std::string> have;
    for (const std::string& f : files) have.insert(to_lower(f));
    for (const std::string& ref : referenced) {
        std::error_code ec;
        if (ref.empty() || !have.insert(to_lower(ref)).second || !stdfs::is_regular_file(project_file(projectDir, ref), ec)) continue;
        files.push_back(ref);
    }
    for (const std::string& rel : files) {
        auto text = tooling_detail::read_file(project_file(projectDir, rel));
        if (!text) {
            errors.push_back({rel, "", "The effect cannot be read.", "Check the file's permissions."});
            continue;
        }
        auto json = parse_json(*text, rel);
        if (!json.ok()) {
            errors.push_back({rel, "", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/vfx.schema.json describes the format." : json.error().hint});
            continue;
        }
        std::vector<VfxIssue> issues;
        auto doc = parse_vfx(*json, rel, &issues);
        if (doc.ok()) {
            const auto missing = vfx_missing_assets(**doc, [&](const std::string& clip) {
                std::error_code ec;
                return stdfs::exists(project_file(projectDir, clip), ec);
            });
            issues.insert(issues.end(), missing.begin(), missing.end());
        } else if (issues.empty()) {
            issues.push_back({true, "", doc.error().message, doc.error().hint});
        }
        for (const VfxIssue& i : issues)
            (i.error ? errors : warnings).push_back({rel, i.pointer, i.message, i.hint.empty() ? "Fix the effect (docs/PARTICLES.md, schemas/vfx.schema.json)." : i.hint});
    }
}

}  // namespace fa::assets_detail
