// The Project panel's model (project_browser_model.h): scanning, the folder tree, filter and sort, the 3D drop point.
#include <cmath>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/math.h"
#include "project_browser_model.h"

using namespace fa;
using namespace fa::editor;

namespace {

ProjectListing sample() {
    ProjectListing l;
    auto add = [&](const char* p, const char* t, std::uint64_t s) { l.files.push_back(BrowserFile{p, t, s}); };
    add("assets/Hero.png", "texture", 4000);
    add("assets/audio/jump.wav", "audio", 90000);
    add("assets/audio/Music.ogg", "audio", 2000000);
    add("prefabs/enemy.prefab.json", "prefab", 300);
    add("scenes/main.scene.json", "scene", 1200);
    add("factoria.json", "other", 200);
    l.folders = {"assets", "assets/audio", "assets/empty", "prefabs", "scenes"};
    return l;
}

std::vector<std::string> paths(const ProjectListing& l, const std::vector<std::size_t>& idx) {
    std::vector<std::string> out;
    for (std::size_t i : idx) out.push_back(l.files[i].path);
    return out;
}

}  // namespace

TEST_CASE("project browser: the folder tree has every folder, empty ones too, with recursive file counts") {
    const FolderNode root = build_folder_tree(sample());
    CHECK(root.path.empty());
    CHECK(root.fileCount == 6);
    REQUIRE(root.children.size() == 3);
    CHECK(root.children[0].name == "assets");
    CHECK(root.children[0].fileCount == 3);
    REQUIRE(root.children[0].children.size() == 2);
    CHECK(root.children[0].children[0].path == "assets/audio");
    CHECK(root.children[0].children[0].fileCount == 2);
    CHECK(root.children[0].children[1].name == "empty");
    CHECK(root.children[0].children[1].fileCount == 0);
}

TEST_CASE("project browser: a folder shows its own files, the root shows all") {
    const ProjectListing l = sample();
    BrowserQuery q;
    CHECK(query_files(l, q).size() == 6);
    q.folder = "assets";
    CHECK(paths(l, query_files(l, q)) == std::vector<std::string>{"assets/Hero.png"});
    q.folder = "assets/audio";
    CHECK(query_files(l, q).size() == 2);
}

TEST_CASE("project browser: the type filter and the case-insensitive search narrow the list") {
    const ProjectListing l = sample();
    BrowserQuery q;
    q.type = "audio";
    CHECK(query_files(l, q).size() == 2);
    q.type = "prefab";
    CHECK(paths(l, query_files(l, q)) == std::vector<std::string>{"prefabs/enemy.prefab.json"});
    q.type = "all";
    q.search = "HERO";
    CHECK(paths(l, query_files(l, q)) == std::vector<std::string>{"assets/Hero.png"});
    q.folder = "scenes";  // a search looks through the whole project
    CHECK(query_files(l, q).size() == 1);
    q.type = "audio";
    CHECK(query_files(l, q).empty());
    q.search = "audio/";
    q.type = "all";
    CHECK(query_files(l, q).size() == 2);
}

TEST_CASE("project browser: sorting by name (case-insensitive), type and size, ascending and descending") {
    const ProjectListing l = sample();
    BrowserQuery q;
    q.folder = "assets/audio";
    CHECK(paths(l, query_files(l, q)).front() == "assets/audio/jump.wav");  // jump before Music
    q.descending = true;
    CHECK(paths(l, query_files(l, q)).front() == "assets/audio/Music.ogg");
    q = BrowserQuery{};
    q.sort = BrowserSort::Size;
    CHECK(paths(l, query_files(l, q)).front() == "factoria.json");
    q.descending = true;
    CHECK(paths(l, query_files(l, q)).front() == "assets/audio/Music.ogg");
    q = BrowserQuery{};
    q.sort = BrowserSort::Type;
    CHECK(l.files[query_files(l, q).front()].type == "audio");
}

TEST_CASE("project browser: scan_project skips hidden, build, node_modules, dist and export, and classifies files") {
    namespace stdfs = std::filesystem;
    const stdfs::path dir = stdfs::temp_directory_path() / "fa_browser_scan_test";
    stdfs::remove_all(dir);
    auto touch = [&](const char* rel, const char* bytes = "x") {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << bytes;
    };
    touch("assets/a.PNG", "12345");
    touch("prefabs/p.prefab.json");
    touch(".factoria/x.png");
    touch("build/y.png");
    touch("node_modules/z.js");
    touch("export/w.png");
    stdfs::create_directories(dir / "assets/empty");
    const ProjectListing l = scan_project(dir.string());
    REQUIRE(l.files.size() == 2);
    CHECK(l.files[0].path == "assets/a.PNG");
    CHECK(l.files[0].type == "texture");
    CHECK(l.files[0].size == 5);
    CHECK(l.files[1].type == "prefab");
    CHECK(l.folders == std::vector<std::string>{"assets", "assets/empty", "prefabs"});
    stdfs::remove_all(dir);
}

TEST_CASE("project browser: small helpers") {
    CHECK(folder_of("assets/a/b.png") == "assets/a");
    CHECK(folder_of("b.png").empty());
    CHECK(file_name_of("assets/a/b.png") == "b.png");
    CHECK(size_text(812) == "812 B");
    CHECK(size_text(4300) == "4.2 KB");
    CHECK(size_text(1572864) == "1.5 MB");
    CHECK(type_badge("a/b.wav", "audio") == "WAV");
    CHECK(type_badge("a/b.prefab.json", "prefab") == "PFB");
    CHECK(browser_type_filters().front() == "all");
    CHECK(browser_type_filters().size() == 9);
}

TEST_CASE("project browser: a prefab dropped in 3D lands on the ground plane, else in front of the camera") {
    // Looking down and forward from (0, 5, 0): hits y = 0 at z = -5.
    const Vec3 hit = drop_point_3d({0, 5, 0}, normalize(Vec3{0, -1, -1}));
    CHECK(std::fabs(hit.y) < 1e-4f);
    CHECK(std::fabs(hit.z + 5.0f) < 1e-3f);
    // Looking up: no ground, 10 units along the ray.
    const Vec3 up = drop_point_3d({0, 5, 0}, {0, 1, 0});
    CHECK(std::fabs(up.y - 15.0f) < 1e-4f);
    // Parallel to the ground.
    const Vec3 flat = drop_point_3d({0, 5, 0}, {0, 0, -1});
    CHECK(std::fabs(flat.z + 10.0f) < 1e-4f);
    // Too far away (grazing the horizon): the fallback again.
    const Vec3 far = drop_point_3d({0, 1, 0}, normalize(Vec3{0, -0.0001f, -1}));
    CHECK(far.z > -11.0f);
}
