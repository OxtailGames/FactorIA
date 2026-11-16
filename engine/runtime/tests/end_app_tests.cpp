// Engine::end_app: the end of an app whose process ends right after (Android). It runs once, does nothing before init(), the
// game's quit handler and its asynchronous write run, and shutdown() still works afterwards.
#include <filesystem>
#include <string>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct EndProject {
    stdfs::path dir = fs::make_temp_dir("fa_end_app").value();
    EndProject() {
        write("factoria.json", R"({"format":"factoria.project/1","name":"End","id":"com.example.end",
                                   "mainScene":"main.scene.json","display":{"width":64,"height":64},"physics":{"fixedHz":60}})");
        write("main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
    }
    ~EndProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const char* rel, const char* text) const {
        stdfs::create_directories((dir / rel).parent_path());
        REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok());
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;
        return c;
    }
};

}  // namespace

TEST_CASE("engine end_app: before init and after shutdown it does nothing") {
    EndProject p;
    Engine e;
    e.end_app();  // not initialized: nothing to end, and it must not mark the app ended for a later init
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.shutdown();
    e.end_app();  // after shutdown
    e.shutdown();
}

TEST_CASE("engine end_app: the quit handler runs once, a second call changes nothing, shutdown follows") {
    EndProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto r = e.scripts().eval(R"JS(
globalThis.quits = 0;
game.on("quit", (e) => { quits++; e.cancel(); storage.setAsync("last", { quits }); });
1)JS");
    REQUIRE(r.ok());
    e.step(1);
    e.end_app();
    e.end_app();  // a second destroy, or a Back during the end
    CHECK(e.scripts().eval("quits").value() == 1);
    CHECK_FALSE(e.quit_requested());  // the handler's cancel() changes nothing: the end asks the host for nothing
    e.shutdown();  // the process normally ends instead; running it after the end must be safe
    e.shutdown();
}
