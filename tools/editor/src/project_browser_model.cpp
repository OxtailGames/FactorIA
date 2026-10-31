#include "project_browser_model.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <map>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "inspector_model.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

ProjectListing scan_project(const std::string& projectDir, std::size_t limit) {
    ProjectListing out;
    if (projectDir.empty()) return out;
    std::error_code ec;
    const stdfs::path root(projectDir);
    stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end;
    for (; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        std::error_code e2;
        if (it->is_directory(e2)) {
            if (skip_project_dir(name)) { it.disable_recursion_pending(); continue; }
            const std::string rel = stdfs::relative(it->path(), root, e2).generic_string();
            if (!e2 && !rel.empty()) out.folders.push_back(rel);
            continue;
        }
        if (!it->is_regular_file(e2)) continue;
        const std::string rel = stdfs::relative(it->path(), root, e2).generic_string();
        if (e2 || rel.empty()) continue;
        if (out.files.size() >= limit) { out.truncated = true; break; }
        BrowserFile f;
        f.path = rel;
        f.type = asset_type_of(rel);
        const auto sz = it->file_size(e2);
        f.size = e2 ? 0 : std::uint64_t(sz);
        out.files.push_back(std::move(f));
    }
    std::sort(out.files.begin(), out.files.end(), [](const BrowserFile& a, const BrowserFile& b) { return a.path < b.path; });
    std::sort(out.folders.begin(), out.folders.end());
    out.recipes = asset_recipe_statuses(projectDir);
    return out;
}

const AssetRecipeStatus* recipe_of_file(const ProjectListing& listing, std::string_view path) {
    const auto it = std::lower_bound(listing.recipes.begin(), listing.recipes.end(), path,
                                     [](const AssetRecipeStatus& r, std::string_view p) { return r.path < p; });
    return it != listing.recipes.end() && it->path == path ? &*it : nullptr;
}

std::vector<std::string> stale_assets(const ProjectListing& listing) {
    std::vector<std::string> out;
    for (const AssetRecipeStatus& r : listing.recipes)
        if (r.stale()) out.push_back(r.path);
    return out;
}

std::string recipe_inputs_stamp(const std::string& projectDir, const ProjectListing& listing) {
    std::string out;
    for (const AssetRecipeStatus& r : listing.recipes)
        for (const std::string& in : r.inputs) {
            std::error_code ec;
            const stdfs::path file = stdfs::path(projectDir) / in;
            const auto size = stdfs::file_size(file, ec);
            const auto time = ec ? stdfs::file_time_type::min() : stdfs::last_write_time(file, ec);
            out += in + ':' + (ec ? std::string("-") : std::to_string(std::uint64_t(size)) + '@' + std::to_string(std::int64_t(time.time_since_epoch().count()))) + ';';
        }
    return out;
}

std::string folder_of(std::string_view path) {
    const auto slash = path.rfind('/');
    return slash == std::string_view::npos ? std::string() : std::string(path.substr(0, slash));
}

std::string file_name_of(std::string_view path) {
    const auto slash = path.rfind('/');
    return std::string(slash == std::string_view::npos ? path : path.substr(slash + 1));
}

FolderNode build_folder_tree(const ProjectListing& listing) {
    FolderNode root;
    root.name = "Project";
    auto child_of = [](FolderNode& parent, const std::string& name, const std::string& path) -> FolderNode& {
        for (FolderNode& c : parent.children)
            if (c.name == name) return c;
        parent.children.push_back(FolderNode{name, path, 0, {}});
        return parent.children.back();
    };
    // Walks (and creates) the chain of `folder`; the callback sees each node on the way.
    auto ensure = [&](const std::string& folder, bool countFile) {
        FolderNode* node = &root;
        if (countFile) ++node->fileCount;
        std::size_t pos = 0;
        while (pos < folder.size()) {
            std::size_t next = folder.find('/', pos);
            if (next == std::string::npos) next = folder.size();
            node = &child_of(*node, folder.substr(pos, next - pos), folder.substr(0, next));
            if (countFile) ++node->fileCount;
            pos = next + 1;
        }
    };
    for (const std::string& f : listing.folders) ensure(f, false);
    for (const BrowserFile& f : listing.files) ensure(folder_of(f.path), true);
    auto sort_rec = [](auto&& self, FolderNode& n) -> void {
        std::sort(n.children.begin(), n.children.end(),
                  [](const FolderNode& a, const FolderNode& b) { return to_lower(a.name) < to_lower(b.name); });
        for (FolderNode& c : n.children) self(self, c);
    };
    sort_rec(sort_rec, root);
    return root;
}

const std::vector<std::string>& browser_type_filters() {
    static const std::vector<std::string> v = {"all", "texture", "audio", "font", "mesh", "script", "scene", "prefab", "material"};
    return v;
}

std::vector<std::size_t> query_files(const ProjectListing& listing, const BrowserQuery& q) {
    std::vector<std::size_t> out;
    const std::string needle = to_lower(q.search);
    for (std::size_t i = 0; i < listing.files.size(); ++i) {
        const BrowserFile& f = listing.files[i];
        if (q.type != "all" && !q.type.empty() && f.type != q.type) continue;
        if (!needle.empty()) {
            if (to_lower(f.path).find(needle) == std::string::npos) continue;
        } else if (!q.folder.empty() && folder_of(f.path) != q.folder) {
            continue;
        }
        out.push_back(i);
    }
    auto less = [&](std::size_t a, std::size_t b) {
        const BrowserFile& x = listing.files[a];
        const BrowserFile& y = listing.files[b];
        int c = 0;
        if (q.sort == BrowserSort::Type) c = x.type.compare(y.type);
        else if (q.sort == BrowserSort::Size) c = x.size < y.size ? -1 : x.size > y.size ? 1 : 0;
        if (c == 0) {
            const std::string lx = to_lower(x.path), ly = to_lower(y.path);
            c = lx.compare(ly);
            if (c == 0) c = x.path.compare(y.path);
            if (q.descending && q.sort == BrowserSort::Name) return c > 0;
            return c < 0;  // ties keep path order whichever way the main key goes
        }
        return q.descending ? c > 0 : c < 0;
    };
    std::stable_sort(out.begin(), out.end(), less);
    return out;
}

std::string size_text(std::uint64_t bytes) {
    char buf[32];
    if (bytes < 1024) std::snprintf(buf, sizeof buf, "%llu B", (unsigned long long)bytes);
    else if (bytes < 1024 * 1024) std::snprintf(buf, sizeof buf, "%.1f KB", double(bytes) / 1024.0);
    else std::snprintf(buf, sizeof buf, "%.1f MB", double(bytes) / (1024.0 * 1024.0));
    return buf;
}

std::string type_badge(std::string_view path, std::string_view type) {
    if (type == "scene") return "SCN";
    if (type == "prefab") return "PFB";
    if (type == "material") return "MAT";
    if (type == "script") return "JS";
    if (type == "mesh") return "3D";
    const auto dot = path.rfind('.');
    if (dot == std::string_view::npos || dot + 1 >= path.size()) return "FILE";
    std::string ext = to_lower(path.substr(dot + 1));
    if (ext.size() > 4) ext.resize(4);
    for (char& c : ext) c = char(std::toupper(static_cast<unsigned char>(c)));
    return ext;
}

Vec3 drop_point_3d(Vec3 o, Vec3 d, float fallbackDistance, float maxDistance) {
    const float len = length(d);
    if (len < 1e-8f) return o;
    d = d * (1.0f / len);
    if (std::fabs(d.y) > 1e-6f) {
        const float t = -o.y / d.y;
        if (t >= 0 && t <= maxDistance) return o + d * t;
    }
    return o + d * fallbackDistance;
}

}  // namespace fa::editor
