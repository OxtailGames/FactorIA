#include "recent_projects.h"

#include <algorithm>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/json.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

std::string normalize_project_path(const std::string& path) {
    if (path.empty()) return {};
    std::error_code ec;
    stdfs::path p = stdfs::absolute(stdfs::path(path), ec);
    if (ec) p = stdfs::path(path);
    p = p.lexically_normal();
    std::string s = p.generic_string();
    while (s.size() > 1 && s.back() == '/' && !(s.size() == 3 && s[1] == ':')) s.pop_back();
    return s;
}

namespace {

void push_unique(std::vector<std::string>& out, const std::string& raw) {
    const std::string n = normalize_project_path(raw);
    if (n.empty() || std::find(out.begin(), out.end(), n) != out.end()) return;
    out.push_back(n);
}

void write_list(const std::string& file, const std::vector<std::string>& list) {
    Json j = Json::array();
    for (const auto& r : list) j.push_back(r);
    std::error_code ec;
    stdfs::create_directories(stdfs::path(file).parent_path(), ec);
    (void)save_json_file(file, j);
}

}  // namespace

std::vector<std::string> read_recent_projects(const std::string& file) {
    std::vector<std::string> out;
    std::error_code ec;
    if (file.empty() || !stdfs::exists(file, ec)) return out;
    auto j = load_json_file(file);
    if (!j || !j->is_array()) return out;
    for (const auto& v : *j)
        if (v.is_string()) push_unique(out, v.get<std::string>());
    if (out.size() > kRecentProjectsMax) out.resize(kRecentProjectsMax);
    return out;
}

std::vector<std::string> existing_recent_projects(const std::vector<std::string>& list) {
    std::vector<std::string> out;
    std::error_code ec;
    for (const auto& r : list)
        if (stdfs::exists(stdfs::path(r) / "factoria.json", ec)) out.push_back(r);
    return out;
}

std::vector<std::string> remember_recent_project(const std::string& file, const std::string& project) {
    std::vector<std::string> out;
    push_unique(out, project);
    for (const auto& r : read_recent_projects(file)) push_unique(out, r);
    // Over the cap, missing folders go first (oldest first), so deleted worktrees never push out real projects.
    std::error_code ec;
    for (std::size_t i = out.size(); out.size() > kRecentProjectsMax && i-- > 1;)
        if (!stdfs::exists(stdfs::path(out[i]) / "factoria.json", ec)) out.erase(out.begin() + std::ptrdiff_t(i));
    if (out.size() > kRecentProjectsMax) out.resize(kRecentProjectsMax);
    write_list(file, out);
    return out;
}

std::vector<std::string> forget_recent_project(const std::string& file, const std::string& project) {
    std::vector<std::string> list = read_recent_projects(file);
    const std::string n = normalize_project_path(project);
    std::erase(list, n);
    write_list(file, list);
    return list;
}

}  // namespace fa::editor
