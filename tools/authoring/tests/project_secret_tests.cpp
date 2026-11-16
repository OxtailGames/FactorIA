// project.create_storage_secret: the random secret behind storage.set(..., {encrypt: true}) (docs/scripting/SCRIPTING_UI_SCENES.md,
// "Encrypted saves"). It writes factoria.json, never reveals the secret and never replaces one by accident.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Secret Test",
  "id": "com.example.secrettest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_secret_test").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary)
            << R"({"format": "factoria.scene/1", "entities": []})";
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;  // nothing is written to the real save folder
        return c;
    }
    Json project_file() const {
        std::ifstream in(dir / "factoria.json", std::ios::binary);
        std::stringstream ss;
        ss << in.rdbuf();
        return Json::parse(ss.str());
    }
};

}  // namespace

TEST_CASE("project.create_storage_secret: writes a random secret once, keeps it, replaces it only on request") {
    authoring::install();
    TempProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.has("project.create_storage_secret"));

    // Before: encrypting a save fails and names the command.
    auto before = c.call("script.eval", Json::object({{"code", "storage.set('a', 1, {encrypt: true})"}}));
    CHECK_FALSE(before.ok);
    CHECK(before.error.dump().find("project.create_storage_secret") != std::string::npos);

    auto made = c.call("project.create_storage_secret", Json::object());
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    CHECK(made.result["created"] == true);
    CHECK(made.result["replaced"] == false);
    const Json file = p.project_file();
    REQUIRE(file["storage"]["encryptionSecret"].is_string());
    const std::string secret = file["storage"]["encryptionSecret"].get<std::string>();
    CHECK(secret.size() == 64);
    CHECK(file["name"] == "Secret Test");  // the rest of the file is kept
    CHECK(file["display"]["width"] == 320);
    CHECK(made.result.dump().find(secret) == std::string::npos);  // never in a result

    // The running game uses it at once (no restart), and nothing shows it.
    auto after = c.call("script.eval", Json::object({{"code", "storage.set('a', 1, {encrypt: true}); storage.get('a')"}}));
    CHECK_MESSAGE(after.ok, after.error.dump());
    auto info = c.call("project.info", Json::object());
    REQUIRE(info.ok);
    CHECK(info.result.dump().find(secret) == std::string::npos);
    CHECK(info.result["project"]["storage"]["encryptionSecret"] == "(hidden)");
    auto seen = c.call("script.eval", Json::object({{"code", "game.project.storage.encryptionSecret"}}));
    REQUIRE(seen.ok);
    CHECK(seen.result.dump().find(secret) == std::string::npos);

    // A second call leaves it alone.
    auto again = c.call("project.create_storage_secret", Json::object());
    REQUIRE(again.ok);
    CHECK(again.result["created"] == false);
    CHECK(p.project_file()["storage"]["encryptionSecret"] == secret);

    // replace: true makes a new one.
    auto replaced = c.call("project.create_storage_secret", Json::object({{"replace", true}}));
    REQUIRE(replaced.ok);
    CHECK(replaced.result["created"] == true);
    CHECK(replaced.result["replaced"] == true);
    const std::string other = p.project_file()["storage"]["encryptionSecret"].get<std::string>();
    CHECK(other.size() == 64);
    CHECK(other != secret);
    e.shutdown();
}

TEST_CASE("project.create_storage_secret: a \"storage\" section that is not an object is refused when the project loads, with its pointer") {
    authoring::install();
    TempProject p;
    std::ofstream(p.dir / "factoria.json", std::ios::binary | std::ios::trunc)
        << R"({"format": "factoria.project/1", "id": "x.y.z", "storage": 5})";
    Engine e;
    std::string err;
    EngineConfig cfg = p.config();
    // "storage": 5 is refused at load with a pointer, so the project does not even open.
    CHECK_FALSE(e.init(cfg, nullptr, &err));
    CHECK(err.find("/storage") != std::string::npos);
}
