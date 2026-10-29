// The recent projects list (recent_projects.h): load, merge, save and forget on a temp dir.
#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "recent_projects.h"

using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

struct TempDir {
    stdfs::path dir;
    TempDir() {
        static int n = 0;
        dir = stdfs::temp_directory_path() / ("fa_recent_test_" + std::to_string(n++) + "_" + std::to_string(reinterpret_cast<std::uintptr_t>(this)));
        stdfs::remove_all(dir);
        stdfs::create_directories(dir);
    }
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    std::string file() const { return (dir / "home" / "editor_recent.json").string(); }
    std::string project(const std::string& name, bool real = true) const {
        stdfs::path p = dir / name;
        if (real) {
            stdfs::create_directories(p);
            std::ofstream(p / "factoria.json") << "{}";
        }
        return p.string();
    }
};

void write_raw(const std::string& file, const std::string& text) {
    stdfs::create_directories(stdfs::path(file).parent_path());
    std::ofstream(file) << text;
}

}  // namespace

TEST_CASE("recent: opening a project keeps the existing history") {
    TempDir t;
    const std::string a = t.project("a"), b = t.project("b"), c = t.project("c");
    remember_recent_project(t.file(), a);
    remember_recent_project(t.file(), b);
    // A second editor that never loaded the file opens c: a and b survive.
    auto list = remember_recent_project(t.file(), c);
    CHECK(list == std::vector<std::string>{normalize_project_path(c), normalize_project_path(b), normalize_project_path(a)});
    CHECK(read_recent_projects(t.file()) == list);
    // Opening a again moves it to the front without a duplicate.
    list = remember_recent_project(t.file(), a);
    CHECK(list.size() == 3);
    CHECK(list.front() == normalize_project_path(a));
}

TEST_CASE("recent: a missing folder is hidden but kept in the file") {
    TempDir t;
    const std::string a = t.project("a"), gone = t.project("gone", false);
    remember_recent_project(t.file(), gone);
    auto list = remember_recent_project(t.file(), a);
    CHECK(list.size() == 2);
    CHECK(existing_recent_projects(read_recent_projects(t.file())) == std::vector<std::string>{normalize_project_path(a)});
    CHECK(read_recent_projects(t.file()).size() == 2);
    // The folder comes back (a drive mounted again): shown again.
    t.project("gone");
    CHECK(existing_recent_projects(read_recent_projects(t.file())).size() == 2);
}

TEST_CASE("recent: the same project with and without a trailing slash is listed once") {
    TempDir t;
    const std::string a = t.project("a");
    CHECK(normalize_project_path("/a/b") == normalize_project_path("/a/b/"));
    CHECK(normalize_project_path("/a/./b") == normalize_project_path("/a/b"));
    remember_recent_project(t.file(), a);
    auto list = remember_recent_project(t.file(), a + "/");
    CHECK(list.size() == 1);
    write_raw(t.file(), "[\"/a/b\", \"/a/b/\", \"/a/b/../b\"]");
    CHECK(read_recent_projects(t.file()).size() == 1);
}

TEST_CASE("recent: the list is capped at 8, most recent first") {
    TempDir t;
    std::vector<std::string> opened;
    for (int i = 0; i < 12; ++i) {
        opened.push_back(t.project("p" + std::to_string(i)));
        remember_recent_project(t.file(), opened.back());
    }
    auto list = read_recent_projects(t.file());
    REQUIRE(list.size() == kRecentProjectsMax);
    CHECK(list.front() == normalize_project_path(opened.back()));
    CHECK(list.back() == normalize_project_path(opened[4]));
}

TEST_CASE("recent: over the cap, missing folders are dropped before real projects") {
    TempDir t;
    const std::string real = t.project("real");
    remember_recent_project(t.file(), real);
    for (int i = 0; i < 7; ++i) remember_recent_project(t.file(), t.project("gone" + std::to_string(i), false));
    REQUIRE(read_recent_projects(t.file()).size() == kRecentProjectsMax);
    const std::string next = t.project("next");
    auto list = remember_recent_project(t.file(), next);
    REQUIRE(list.size() == kRecentProjectsMax);
    CHECK(list.front() == normalize_project_path(next));
    CHECK(std::find(list.begin(), list.end(), normalize_project_path(real)) != list.end());
    CHECK(std::find(list.begin(), list.end(), normalize_project_path(t.project("gone0", false))) == list.end());
}

TEST_CASE("recent: forgetting a project removes it from the file") {
    TempDir t;
    const std::string a = t.project("a"), b = t.project("b");
    remember_recent_project(t.file(), a);
    remember_recent_project(t.file(), b);
    auto list = forget_recent_project(t.file(), a + "/");
    CHECK(list == std::vector<std::string>{normalize_project_path(b)});
    CHECK(read_recent_projects(t.file()) == list);
}

TEST_CASE("recent: a corrupt, non-array or missing file is an empty list") {
    TempDir t;
    CHECK(read_recent_projects(t.file()).empty());
    write_raw(t.file(), "{ not json");
    CHECK(read_recent_projects(t.file()).empty());
    write_raw(t.file(), "{\"a\": 1}");
    CHECK(read_recent_projects(t.file()).empty());
    write_raw(t.file(), "[1, null, \"/x/y\"]");
    CHECK(read_recent_projects(t.file()) == std::vector<std::string>{normalize_project_path("/x/y")});
    write_raw(t.file(), "garbage");
    const std::string a = t.project("a");
    CHECK(remember_recent_project(t.file(), a).size() == 1);
    CHECK(forget_recent_project(t.file(), a).empty());
}
