// M77-P9e2: the Vulkan player of Linux and Android and the OpenGL one. The relaunch decision (a pure function), the GL
// sibling's name, the stored choice of graphics.backend (user settings) in the backend choice, the fallback marker, and
// the graphics.backend command.
#include <doctest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/render/renderer.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/gpu_backend_choice.h"
#include "fa/runtime/gpu_launch.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct ScopedEnv {
    std::string name;
    std::string old;
    bool had = false;
    ScopedEnv(const char* n, const char* value) : name(n) {
        if (const char* v = std::getenv(n)) {
            had = true;
            old = v;
        }
        set(value);
    }
    ~ScopedEnv() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#ifdef _WIN32
        _putenv_s(name.c_str(), value ? value : "");
#else
        if (value)
            setenv(name.c_str(), value, 1);
        else
            unsetenv(name.c_str());
#endif
    }
};

// A temporary save folder for the length of a test (fs::user_dir is process-wide): restored afterwards.
struct ScopedUserDir {
    stdfs::path dir;
    stdfs::path old;
    explicit ScopedUserDir(const std::string& name) {
        old = fs::user_dir();
        dir = fs::make_temp_dir("fa_gpu_launch_" + name).value();
        fs::set_user_dir(dir);
    }
    ~ScopedUserDir() {
        fs::set_user_dir(old);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_gpu_launch_project_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Launch Test", "id": "com.example.launchtest",
  "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180 } })";
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary)
            << R"({ "format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ] })";
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig cfg(const TempProject& p, bool memoryStorage) {
    EngineConfig c;
    c.projectDir = fs::path_to_utf8(p.dir);
    c.headless = true;
    c.graphics = false;
    c.hotReload = false;
    c.audioDevice = false;
    c.memoryStorage = memoryStorage;
    return c;
}

// A sokol backend this binary has (what auto draws with), as a name graphics.backend accepts.
std::string built_name() {
    for (GpuBackend b : {GpuBackend::Gl, GpuBackend::Gles3, GpuBackend::D3d11, GpuBackend::Metal, GpuBackend::WebGl2})
        if (gpu_backend_available(b)) return gpu_backend_name(b);
    return "auto";
}

bool contains(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("gpu launch: the Vulkan player stays, runs the OpenGL one, or falls back to it") {
    GpuLaunchInput in;
    // The OpenGL player never starts another one.
    in.vulkanPlayer = false;
    in.glPlayerPresent = true;
    in.backend = GpuBackend::Gl;
    in.vulkanFailure = "no loader";
    CHECK(decide_gpu_launch(in).action == GpuLaunchAction::Stay);

    // The Vulkan player draws with Vulkan when it starts.
    in = {};
    in.vulkanPlayer = true;
    in.glPlayerPresent = true;
    in.backend = GpuBackend::Vulkan;
    auto d = decide_gpu_launch(in);
    CHECK(d.action == GpuLaunchAction::Stay);
    CHECK(contains(d.reason, "Vulkan"));

    // It falls back when Vulkan fails, with the reason.
    in.vulkanFailure = "no libvulkan.so.1";
    d = decide_gpu_launch(in);
    CHECK(d.action == GpuLaunchAction::FallBackToGl);
    CHECK(contains(d.reason, "no libvulkan.so.1"));
    CHECK(std::string(gpu_launch_action_name(d.action)) == "fallBackToGl");

    // Without the OpenGL player next to it, it draws itself (sokol backend).
    in.glPlayerPresent = false;
    CHECK(decide_gpu_launch(in).action == GpuLaunchAction::Stay);

    // An explicit OpenGL choice runs the OpenGL player directly, with no marker.
    in = {};
    in.vulkanPlayer = true;
    in.glPlayerPresent = true;
    in.backend = GpuBackend::Gl;
    d = decide_gpu_launch(in);
    CHECK(d.action == GpuLaunchAction::RunGl);
    CHECK(std::string(gpu_launch_action_name(d.action)) == "runGl");
    in.backend = GpuBackend::Gles3;
    CHECK(decide_gpu_launch(in).action == GpuLaunchAction::RunGl);
    in.glPlayerPresent = false;
    CHECK(decide_gpu_launch(in).action == GpuLaunchAction::Stay);

    // A player started by a fallback never starts another one: no loop.
    in = {};
    in.vulkanPlayer = true;
    in.glPlayerPresent = true;
    in.backend = GpuBackend::Vulkan;
    in.vulkanFailure = "no device";
    in.fallbackFrom = "vulkan";
    d = decide_gpu_launch(in);
    CHECK(d.action == GpuLaunchAction::Stay);
    CHECK(contains(d.reason, "vulkan"));
}

TEST_CASE("gpu launch: the OpenGL player's file name next to the Vulkan one") {
    CHECK(gl_player_name("factoria_player_vulkan") == "factoria_player");
    CHECK(gl_player_name("mygame") == "mygame-gl");
    CHECK(gl_player_name("_vulkan") == "_vulkan-gl");  // nothing before the suffix: not a build-tree name
    CHECK(gl_player_name("my_vulkan_game") == "my_vulkan_game-gl");
#if !(defined(__linux__) && !defined(__ANDROID__))
    CHECK(gl_player_path().empty());
    auto r = exec_gl_player("/nowhere/factoria_player", {"x"}, "vulkan", "test");
    CHECK_FALSE(r.ok());
    CHECK(contains(r.error().message, "Linux"));
#endif
}

TEST_CASE("gpu backend: the stored choice sits between FA_GPU_BACKEND and factoria.json") {
    const std::string built = built_name();
    GpuBackendInputs in;
    in.user = built;
    in.project = "auto";
    auto c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    CHECK(c.value().source == "user settings");
    CHECK(c.value().asked == built);
    CHECK(c.value().warnings.empty());

    // The variable beats the stored choice.
    in.env = "auto";
    c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    CHECK(c.value().source == "FA_GPU_BACKEND");

    // A stored name the engine does not know is a warning, never an error: the game still starts.
    in = {};
    in.user = "vulcan";
    in.project = built;
    c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    CHECK(c.value().source == "factoria.json");
    REQUIRE(c.value().warnings.size() == 1);
    CHECK(contains(c.value().warnings[0], "vulcan"));
    CHECK(contains(c.value().warnings[0], "vulkan"));  // did you mean
}

TEST_CASE("gpu backend: auto in the Vulkan player and the fallback marker") {
    GpuBackendInputs in;
    in.autoBackend = GpuBackend::Vulkan;
    auto c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    CHECK(c.value().backend == (gpu_backend_available(GpuBackend::Vulkan) ? GpuBackend::Vulkan : GpuBackend::Default));
    CHECK(c.value().fallbackFrom.empty());

    // The OpenGL player started by the Vulkan one: auto never picks Vulkan again, one warning names what happened.
    in.fallbackFrom = "vulkan";
    in.fallbackReason = "no Vulkan driver";
    c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    CHECK(c.value().backend == GpuBackend::Default);
    CHECK(c.value().fallbackFrom == "vulkan");
    CHECK(c.value().fallbackReason == "no Vulkan driver");
    REQUIRE(c.value().warnings.size() == 1);
    CHECK(contains(c.value().warnings[0], "no Vulkan driver"));

    // A stored "vulkan" that the OpenGL player cannot draw with: the marker's warning says it, not a second one.
    if (!gpu_backend_available(GpuBackend::Vulkan)) {
        in.user = "vulkan";
        c = choose_gpu_backend(in);
        REQUIRE(c.ok());
        CHECK(c.value().warnings.size() == 1);
    }
}

TEST_CASE("gpu backend: the marker of a window that cannot take the swapchain does not promise a driver update") {
    const std::string reason =
        gpu_window_path_reason("vulkan", "the window cannot be handed to the vulkan device: OpenGL");
    CHECK(is_gpu_window_path_reason(reason));
    CHECK_FALSE(is_gpu_window_path_reason("no Vulkan driver"));
    GpuBackendInputs in;
    in.fallbackFrom = "vulkan";
    in.fallbackReason = reason.c_str();
    auto c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    REQUIRE(c.value().warnings.size() == 1);
    const std::string& w = c.value().warnings[0];
    CHECK(contains(w, "the window path is not available on this platform yet"));
    CHECK_FALSE(contains(w, "driver update"));
    CHECK_FALSE(contains(w, "brings it back"));
    // A Vulkan that could not start keeps the advice.
    in.fallbackReason = "no Vulkan driver";
    c = choose_gpu_backend(in);
    REQUIRE(c.ok());
    REQUIRE(c.value().warnings.size() == 1);
    CHECK(contains(c.value().warnings[0], "driver update"));
}

TEST_CASE("gpu backend: the stored choice file round-trips, 'auto' removes it, a broken one is ignored") {
    ScopedUserDir user("file");
    CHECK(read_gpu_backend_setting(user.dir, nullptr).empty());
    REQUIRE(write_gpu_backend_setting(user.dir, "gl").ok());
    CHECK(stdfs::exists(user.dir / kGpuBackendSettingFile));
    CHECK(read_gpu_backend_setting(user.dir, nullptr) == "gl");
    REQUIRE(write_gpu_backend_setting(user.dir, "auto").ok());
    CHECK_FALSE(stdfs::exists(user.dir / kGpuBackendSettingFile));

    std::ofstream(user.dir / kGpuBackendSettingFile, std::ios::binary) << "{ not json";
    std::string warning;
    CHECK(read_gpu_backend_setting(user.dir, &warning).empty());
    CHECK(contains(warning, kGpuBackendSettingFile));
    CHECK(contains(warning, "graphics.backend"));

    auto none = write_gpu_backend_setting({}, "gl");
    CHECK_FALSE(none.ok());
}

TEST_CASE("graphics.backend: reads, stores for the next start, and teaches when wrong") {
    TempProject proj("command");
    ScopedEnv env("FA_GPU_BACKEND", nullptr);
    ScopedEnv from(kGpuFallbackFromEnv, nullptr);
    const std::string built = built_name();

    SUBCASE("in-memory storage keeps the choice in memory") {
        ScopedUserDir user("memory");
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(proj, true), nullptr, &err), err);
        auto& c = e.commands();
        const CommandInfo* info = c.info("graphics.backend");
        REQUIRE(info != nullptr);
        CHECK_FALSE(info->readOnly);
        CHECK_FALSE(info->description.empty());
        CHECK(info->description.size() < 1500);

        auto r = c.call("graphics.backend", Json::object());
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["active"] == "none");  // graphics off
        CHECK(r.result["requested"] == "auto");
        CHECK(r.result["source"] == "default");
        CHECK(r.result["stored"] == "auto");
        CHECK(r.result["storedIn"] == "memory");
        CHECK(r.result["fallback"].is_null());
        REQUIRE(r.result["available"].is_array());
        CHECK_FALSE(r.result.contains("takesEffect"));

        r = c.call("graphics.backend", Json::object({{"name", built}}));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["changed"] == (built != "auto"));
        CHECK(r.result["takesEffect"] == "next start");
        CHECK(r.result["stored"] == built);
        CHECK(r.result["requested"] == "auto");  // the backend in use does not change
        CHECK_FALSE(stdfs::exists(user.dir / kGpuBackendSettingFile));

        r = c.call("graphics.backend", Json::object({{"name", "vulcan"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(r.error.dump(), "vulkan"));
        r = c.call("graphics.backend", Json::object({{"nmae", "gl"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(contains(r.error.dump(), "name"));
        r = c.call("graphics.backend", Json::object({{"name", 3}}));
        REQUIRE_FALSE(r.ok);
        e.shutdown();
    }

    SUBCASE("a save folder stores the file, and the next start reads it") {
        ScopedUserDir user("disk");
        {
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(cfg(proj, false), nullptr, &err), err);
            auto r = e.commands().call("graphics.backend", Json::object({{"name", built}}));
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            if (built != "auto") CHECK(read_gpu_backend_setting(user.dir, nullptr) == built);
            e.shutdown();
        }
        if (built != "auto") {
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(cfg(proj, false), nullptr, &err), err);
            auto r = e.commands().call("graphics.backend", Json::object());
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            CHECK(r.result["source"] == "user settings");
            CHECK(r.result["requested"] == built);
            CHECK(r.result["stored"] == built);
            r = e.commands().call("graphics.backend", Json::object({{"name", "auto"}}));
            REQUIRE(r.ok);
            CHECK(r.result["changed"] == true);
            CHECK_FALSE(stdfs::exists(user.dir / kGpuBackendSettingFile));
            e.shutdown();
        }
    }

    SUBCASE("a player started in place of another one says so") {
        ScopedUserDir user("marker");
        ScopedEnv marker(kGpuFallbackFromEnv, "vulkan");
        ScopedEnv reason(kGpuFallbackReasonEnv, "no Vulkan driver");
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(proj, true), nullptr, &err), err);
        auto r = e.commands().call("graphics.backend", Json::object());
        REQUIRE(r.ok);
        REQUIRE(r.result["fallback"].is_object());
        CHECK(r.result["fallback"]["from"] == "vulkan");
        CHECK(r.result["fallback"]["reason"] == "no Vulkan driver");
        e.shutdown();
    }
}
