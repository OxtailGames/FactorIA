#include "fa/core/screenshot_files.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <system_error>
#include <vector>

namespace fa {

namespace stdfs = std::filesystem;

bool is_engine_named_screenshot(std::string_view name) {
    constexpr std::string_view prefix = "frame_", suffix = ".png";
    if (name.size() < prefix.size() + 1 + suffix.size() || name.substr(0, prefix.size()) != prefix ||
        name.substr(name.size() - suffix.size()) != suffix)
        return false;
    return std::isdigit(static_cast<unsigned char>(name[prefix.size()])) != 0;
}

std::size_t prune_screenshots(const stdfs::path& projectDir, int maxAgeDays, std::size_t maxFiles) {
    std::error_code ec;
    const stdfs::path dir = projectDir / kScreenshotDir;
    if (projectDir.empty() || !stdfs::is_directory(dir, ec)) return 0;
    struct Entry {
        stdfs::path path;
        stdfs::file_time_type time;
    };
    std::vector<Entry> files;
    for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        std::error_code e2;
        if (!it->is_regular_file(e2) || !is_engine_named_screenshot(it->path().filename().string())) continue;
        const auto t = it->last_write_time(e2);
        if (!e2) files.push_back({it->path(), t});
    }
    std::size_t removed = 0;
    auto remove = [&](const Entry& f) {
        std::error_code e;
        if (stdfs::remove(f.path, e) && !e) ++removed;
    };
    const auto cutoff = stdfs::file_time_type::clock::now() - std::chrono::hours(24LL * std::max(0, maxAgeDays));
    std::vector<Entry> kept;
    for (const Entry& f : files) {
        if (f.time < cutoff) remove(f);
        else kept.push_back(f);
    }
    if (kept.size() > maxFiles) {
        std::sort(kept.begin(), kept.end(), [](const Entry& a, const Entry& b) { return a.time > b.time; });  // newest first
        for (std::size_t i = maxFiles; i < kept.size(); ++i) remove(kept[i]);
    }
    return removed;
}

bool discard_temporary_image(const Json& spec, const stdfs::path& projectDir) {
    if (!spec.is_object() || spec.value("temporary", false) != true || !spec.contains("path") || !spec["path"].is_string())
        return false;
    std::error_code ec;
    stdfs::path p = spec["path"].get<std::string>();
    if (p.is_relative()) p = projectDir / p;
    if (!is_engine_named_screenshot(p.filename().string())) return false;
    const stdfs::path dir = stdfs::weakly_canonical(projectDir / kScreenshotDir, ec);
    const stdfs::path parent = stdfs::weakly_canonical(p.parent_path(), ec);
    if (ec || dir.empty() || parent != dir) return false;
    return stdfs::remove(p, ec) && !ec;
}

}  // namespace fa
