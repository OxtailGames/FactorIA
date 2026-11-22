// M75-P0: the project setting world.floatingOrigin (validated, no behaviour yet) and the runtime commands of the big worlds, which exist
// but fail with `not_built` until their package lands (docs/BIG_WORLDS.md).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::string project_with(const std::string& extra) {
    return R"({"format":"factoria.project/1","name":"World Test","id":"com.example.worldtest",
      "mainScene":"scenes/main.scene.json","display":{"width":320,"height":180})" +
           extra + "}";
}

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& project) {
        dir = fs::make_temp_dir("fa_world_m75").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << project;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary)
            << R"({"format": "factoria.scene/1", "entities": []})";
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

}  // namespace

TEST_CASE("world.floatingOrigin: off by default, read, kept when saving, and not written when it is the default") {
    TempProject plain(project_with(""));
    auto def = load_project(plain.dir.generic_string());
    REQUIRE(def.ok());
    CHECK_FALSE(def->floatingOrigin.enabled);
    CHECK(def->floatingOrigin.threshold == 2048.0);
    CHECK(def->floatingOrigin.step == 256.0);
    CHECK(def->floatingOrigin.anchor == "camera");
    REQUIRE(save_project(plain.dir.generic_string(), *def).ok());
    std::ifstream in(plain.dir / "factoria.json", std::ios::binary);
    const std::string saved((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    CHECK(saved.find("floatingOrigin") == std::string::npos);  // an old project is saved as it was
    CHECK(saved.find("\"world\"") == std::string::npos);

    TempProject set(project_with(
        R"(,"world":{"floatingOrigin":{"enabled":true,"threshold":4096,"step":512,"anchor":"entity:player"}})"));
    auto loaded = load_project(set.dir.generic_string());
    REQUIRE_MESSAGE(loaded.ok(), loaded.error().message);
    CHECK(loaded->floatingOrigin.enabled);
    CHECK(loaded->floatingOrigin.threshold == 4096.0);
    CHECK(loaded->floatingOrigin.step == 512.0);
    CHECK(loaded->floatingOrigin.anchor == "entity:player");
    REQUIRE(save_project(set.dir.generic_string(), *loaded).ok());
    auto again = load_project(set.dir.generic_string());
    REQUIRE(again.ok());
    CHECK(again->floatingOrigin == loaded->floatingOrigin);

    // Only some keys: the others keep their defaults.
    TempProject some(project_with(R"(,"world":{"floatingOrigin":{"enabled":true}})"));
    auto partial = load_project(some.dir.generic_string());
    REQUIRE(partial.ok());
    CHECK(partial->floatingOrigin.enabled);
    CHECK(partial->floatingOrigin.threshold == 2048.0);
}

TEST_CASE("world.floatingOrigin: a mistake names the JSON pointer, the problem and the fix") {
    struct Case {
        const char* section;
        const char* pointer;
        const char* message;
    };
    const Case bad[] = {
        {R"({"floatingOrigin":{"enabld":true}})", "/world/floatingOrigin/enabld", "enabled"},
        {R"({"floatingOrigin":{"enabled":"yes"}})", "/world/floatingOrigin/enabled", ""},
        {R"({"floatingOrigin":{"threshold":"far"}})", "/world/floatingOrigin/threshold", ""},
        {R"({"floatingOrigin":{"threshold":4}})", "/world/floatingOrigin/threshold", "out of range"},
        {R"({"floatingOrigin":{"step":0}})", "/world/floatingOrigin/step", "out of range"},
        {R"({"floatingOrigin":{"threshold":100,"step":200}})", "/world/floatingOrigin/step", "above threshold"},
        {R"({"floatingOrigin":{"anchor":"player"}})", "/world/floatingOrigin/anchor", "neither"},
        {R"({"floatingOrigin":{"anchor":"entity:"}})", "/world/floatingOrigin/anchor", "names no entity"},
        {R"({"floatingOrigin":{"anchor":3}})", "/world/floatingOrigin/anchor", ""},
        {R"({"floatingOrigin":5})", "/world/floatingOrigin", ""},
    };
    for (const Case& c : bad) {
        INFO(std::string(c.section));
        TempProject p(project_with(std::string(",\"world\":") + c.section));
        auto r = load_project(p.dir.generic_string());
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find(c.pointer) != std::string::npos);
        CHECK((r.error().message + r.error().hint).find(c.message) != std::string::npos);  // "did you mean" is in the hint
        CHECK_FALSE(r.error().hint.empty());
    }
    TempProject notObject(project_with(R"(,"world":[])"));
    auto r = load_project(notObject.dir.generic_string());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/world") != std::string::npos);
}

TEST_CASE("world.* runtime commands: registered, documented, and the ones not built yet fail with not_built naming their package") {
    TempProject p(project_with(""));
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    c.memoryStorage = true;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    struct Row {
        const char* name;
        const char* package;
        bool readOnly;
    };
    const Row rows[] = {{"world.origin", "M75.4", true},
                        {"world.rebase", "M75.4", false},
                        {"world.cells", "M75.3", true},
                        {"world.stream_status", "M75.3", true}};
    for (const Row& row : rows) {
        INFO(row.name);
        const CommandInfo* info = e.commands().info(row.name);
        REQUIRE(info != nullptr);
        CHECK(info->category == "world");
        CHECK(info->readOnly == row.readOnly);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->description.size() < 1500);
        if (std::string(row.package) == "M75.3") {  // built: it answers (this scene has no StreamedWorld)
            CHECK(info->description.find("Not built yet") == std::string::npos);
            continue;
        }
        CHECK(info->description.find(row.package) != std::string::npos);
        auto r = e.commands().call(row.name, Json::object());
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "not_built");
        CHECK(r.error.dump().find(row.package) != std::string::npos);
        CHECK(r.error.dump().find("BIG_WORLDS") != std::string::npos);
    }
    e.shutdown();
}
