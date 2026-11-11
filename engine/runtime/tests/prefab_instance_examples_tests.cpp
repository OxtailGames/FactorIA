// scene.save keeps prefab instances: every scene of the examples that instances a prefab loads and saves back to the same
// bytes (PrefabSave::Keep), so a file the engine wrote is not rewritten by the next save.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/scene/serialize.h"
#include "fa_test_paths.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Root {
    stdfs::path old;
    explicit Root(const stdfs::path& dir) : old(fs::project_root()) { fs::set_project_root(dir); }
    ~Root() { fs::set_project_root(old); }
};

// How many objects of the document are {"prefab": "<path>", ...}.
std::size_t count_instances(const Json& j) {
    std::size_t n = 0;
    if (j.is_object()) {
        if (j.contains("prefab") && j["prefab"].is_string()) ++n;
        for (auto it = j.begin(); it != j.end(); ++it) n += count_instances(*it);
    } else if (j.is_array()) {
        for (const Json& x : j) n += count_instances(x);
    }
    return n;
}

}  // namespace

TEST_CASE("prefab instances: every example scene with a prefab keeps its instances and saves back to the same bytes") {
    const stdfs::path examples = stdfs::path(FA_REPO_ROOT) / "examples";
    REQUIRE(stdfs::is_directory(examples));
    std::size_t checked = 0, withInstances = 0;
    for (const auto& dirEntry : stdfs::directory_iterator(examples)) {
        if (!dirEntry.is_directory() || !stdfs::exists(dirEntry.path() / "factoria.json")) continue;
        Root root(dirEntry.path());
        for (const std::string& file : project_scene_files()) {
            if (file.size() < 11 || file.compare(file.size() - 11, 11, ".scene.json") != 0) continue;
            auto bytes = fs::read_text(file);
            REQUIRE(bytes.ok());
            auto doc = parse_json(bytes.value(), file);
            REQUIRE(doc.ok());
            ++checked;
            const std::size_t instances = count_instances(doc.value());
            if (instances == 0) continue;
            ++withInstances;
            const std::string label = dirEntry.path().filename().generic_string() + "/" + file;
            World w;
            LoadReport report = load_scene(w, doc.value(), file);
            INFO(label << "\n" << report.summary());
            if (!report.ok()) continue;   // the example's own validate test reports it
            SaveSceneOptions keep;
            keep.prefabs = PrefabSave::Keep;
            std::vector<PrefabExpanded> expanded;
            keep.prefabsExpanded = &expanded;
            const Json first = save_scene(w, keep);
            for (const PrefabExpanded& x : expanded) MESSAGE(label << ": '" << x.id << "' written inline: " << x.reason);
            CHECK_MESSAGE(expanded.empty(), label);
            // Every instance of the file is still one (the hand-written layout, number style and key order of the file
            // are what the saver normalizes; the instances are what must not be lost).
            CHECK_MESSAGE(count_instances(first) == instances, label);
            // The saved scene is the same world: expanded, both give the same scene.
            World again;
            REQUIRE(load_scene(again, first, "saved").ok());
            CHECK_MESSAGE(dump_scene_json(save_scene(again)) == dump_scene_json(save_scene(w)), label);
            // And a scene the saver wrote is saved back to the same bytes.
            CHECK_MESSAGE(dump_scene_json(save_scene(again, keep)) == dump_scene_json(first), label);
        }
    }
    CHECK(checked > 10);
    CHECK(withInstances > 5);
}
