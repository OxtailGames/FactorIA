// M77-P9a: a game chooses its GPU backend: factoria.json render.backend, the FA_GPU_BACKEND variable,
// EngineConfig::gpuBackend, the warning for a backend this binary lacks, the headless selection and the startup report
// that names the device's backend.
#include <doctest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/render/renderer.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/gpu_backend_choice.h"
#include "fa/runtime/internal/engine_impl.h"
#include "fa/runtime/project.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// Sets (or, with nullptr, removes) an environment variable for the length of a test and restores what was there.
// Declare it BEFORE any Engine of the test: the engine's threads must be gone when the destructor restores the
// variable.
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

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& renderBlock = "") {
        dir = fs::make_temp_dir("fa_gpu_backend_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary)
            << R"({ "format": "factoria.project/1", "name": "Backend Test", "id": "com.example.backendtest",
  "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180 })" +
                   renderBlock + "\n}";
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary)
            << R"({ "format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ] })";
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    std::string path() const { return dir.generic_string(); }
};

EngineConfig cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.path();
    c.headless = true;
    c.hotReload = false;
    c.audioDevice = false;
    return c;
}

// A backend this binary cannot make, or Default when it has them all (Windows with Vulkan, say).
GpuBackend an_unavailable_backend() {
    for (GpuBackend b : {GpuBackend::Metal, GpuBackend::D3d12, GpuBackend::D3d11, GpuBackend::Vulkan, GpuBackend::Gl})
        if (!gpu_backend_available(b)) return b;
    return GpuBackend::Default;
}

}  // namespace

TEST_CASE("gpu backend: render.backend loads, round-trips and teaches when wrong") {
    TempProject plain("plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->renderBackend == "auto");
    CHECK_FALSE(s->to_json().contains("render"));

    TempProject set("set", R"(, "render": { "backend": "vulkan" })");
    auto t = load_project(set.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK(t->renderBackend == "vulkan");
    CHECK(t->to_json()["render"]["backend"] == "vulkan");
    t->renderBackend = "auto";
    CHECK_FALSE(t->to_json().contains("render"));

    for (const char* name : {"auto", "d3d11", "d3d12", "vulkan", "metal", "gl", "gles3", "webgl2"}) {
        TempProject each(std::string("each-") + name, std::string(R"(, "render": { "backend": ")") + name + "\" }");
        auto r = load_project(each.path());
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        CHECK(r->renderBackend == name);
    }

    TempProject bad("bad", R"(, "render": { "backend": "vulcan" })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    const std::string text = b.error().message + " " + b.error().hint;
    CHECK(text.find("/render/backend") != std::string::npos);
    CHECK(text.find("vulkan") != std::string::npos);  // the did-you-mean and the list of names
    CHECK(text.find("webgl2") != std::string::npos);

    TempProject number("number", R"(, "render": { "backend": 3 })");
    CHECK_FALSE(load_project(number.path()).ok());
}

TEST_CASE("gpu backend: render.asyncCompute and render.multiThreadRecording load, round-trip and teach when wrong") {
    TempProject plain("queues-plain");
    auto s = load_project(plain.path());
    REQUIRE(s.ok());
    CHECK(s->renderAsyncCompute);
    CHECK(s->renderMultiThreadRecording);

    TempProject off("queues-off", R"(, "render": { "asyncCompute": false, "multiThreadRecording": false })");
    auto t = load_project(off.path());
    REQUIRE_MESSAGE(t.ok(), t.error().message);
    CHECK_FALSE(t->renderAsyncCompute);
    CHECK_FALSE(t->renderMultiThreadRecording);
    const Json written = t->to_json();
    CHECK(written["render"]["asyncCompute"] == false);
    CHECK(written["render"]["multiThreadRecording"] == false);
    t->renderAsyncCompute = true;
    CHECK_FALSE(t->to_json()["render"].contains("asyncCompute"));
    t->renderMultiThreadRecording = true;
    CHECK_FALSE(t->to_json().contains("render"));  // both back on: the defaults are not written

    TempProject bad("queues-bad", R"(, "render": { "asyncCompute": "no" })");
    auto b = load_project(bad.path());
    REQUIRE_FALSE(b.ok());
    CHECK((b.error().message + " " + b.error().hint).find("/render/asyncCompute") != std::string::npos);
}

TEST_CASE(
    "gpu backend: choose_gpu_backend orders EngineConfig, the variable and the project, and warns for a missing one") {
    // Nothing asked: auto, no warning.
    auto none = choose_gpu_backend("", nullptr, "auto");
    REQUIRE(none.ok());
    CHECK(none->backend == GpuBackend::Default);
    CHECK(none->source == "default");
    CHECK(none->warnings.empty());

    // The project, then the variable over it, then EngineConfig over both.
    auto fromProject = choose_gpu_backend("", nullptr, "recordingxx");
    CHECK_FALSE(fromProject.ok());
    auto sokol = choose_gpu_backend("", nullptr, gpu_backend_name(GpuBackend::Default));
    CHECK(sokol->source == "default");
    auto envWins = choose_gpu_backend("", "auto", "vulkan");
    REQUIRE(envWins.ok());
    CHECK(envWins->source == "FA_GPU_BACKEND");
    CHECK(envWins->backend == GpuBackend::Default);
    auto cfgWins = choose_gpu_backend("auto", "vulkan", "vulkan");
    REQUIRE(cfgWins.ok());
    CHECK(cfgWins->source == "EngineConfig");

    // Unknown names teach, whoever wrote them.
    auto bad = choose_gpu_backend("", "vulcan", "auto");
    REQUIRE_FALSE(bad.ok());
    const std::string text = bad.error().message + " " + bad.error().hint;
    CHECK(text.find("FA_GPU_BACKEND") != std::string::npos);
    CHECK(text.find("vulkan") != std::string::npos);
    CHECK_FALSE(choose_gpu_backend("recording", nullptr, "auto").ok());  // the test-only backend is not a game's choice

    // A valid name the binary lacks: a warning that lists what it has, and auto.
    const GpuBackend missing = an_unavailable_backend();
    if (missing == GpuBackend::Default) {
        MESSAGE("this binary has every GPU backend: the unsupported-backend warning was not checked here");
    } else {
        auto c = choose_gpu_backend("", nullptr, gpu_backend_name(missing));
        REQUIRE(c.ok());
        CHECK(c->backend == GpuBackend::Default);
        CHECK(c->requested == missing);
        REQUIRE(c->warnings.size() == 1);
        CHECK(c->warnings[0].find(gpu_backend_name(missing)) != std::string::npos);
        CHECK(c->warnings[0].find("it has:") != std::string::npos);
        CHECK(c->warnings[0].find("using auto") != std::string::npos);
    }
    // What this binary has is accepted as asked.
    for (const std::string& n : gpu_backend_names()) {
        auto b = parse_gpu_backend_name(n);
        REQUIRE(b);
        auto c = choose_gpu_backend(n, nullptr, "auto");
        REQUIRE(c.ok());
        if (gpu_backend_available(*b)) {
            CHECK(c->backend == *b);
            CHECK(c->warnings.empty());
        } else {
            CHECK(c->backend == GpuBackend::Default);
        }
    }
}

TEST_CASE("gpu backend: the fallback warning says what was asked, why, what draws and how to choose") {
    const std::string w = gpu_backend_fallback_warning(GpuBackend::Vulkan, "no swapchain", "glcore");
    CHECK(w.find("vulkan") != std::string::npos);
    CHECK(w.find("no swapchain") != std::string::npos);
    CHECK(w.find("glcore") != std::string::npos);
    CHECK(w.find("the window") != std::string::npos);
    CHECK(w.find("render.backend") != std::string::npos);
    CHECK(w.find("cannot draw into a window yet") == std::string::npos);  // they do now (M77-P9e1)
    const std::string headless = gpu_backend_fallback_warning(GpuBackend::D3d12, "no adapter", "d3d11", false);
    CHECK(headless.find("headless") != std::string::npos);
    CHECK(headless.find("no adapter") != std::string::npos);
}

TEST_CASE("gpu backend: start_gpu_backend falls back to the build's backend once and keeps the first error") {
    std::vector<GpuBackend> tried;
    auto failing = [&](const std::string& vulkanError, const std::string& defaultError) {
        tried.clear();
        return [&tried, vulkanError, defaultError](GpuBackend b) {
            tried.push_back(b);
            return b == GpuBackend::Default ? defaultError : vulkanError;
        };
    };
    // The asked backend starts: no fallback.
    GpuBackendStartResult r = start_gpu_backend(GpuBackend::Vulkan, failing("", ""), "glcore", true);
    CHECK(r.ok);
    CHECK(r.used == GpuBackend::Vulkan);
    CHECK(r.fallbackReason.empty());
    CHECK(r.warning.empty());
    CHECK(tried.size() == 1);
    // It fails: Default starts, the first error is the reason and the warning keeps it.
    r = start_gpu_backend(GpuBackend::Vulkan, failing("no Vulkan driver", ""), "glcore", true);
    CHECK(r.ok);
    CHECK(r.used == GpuBackend::Default);
    CHECK(r.fallbackReason == "no Vulkan driver");
    CHECK(r.warning.find("no Vulkan driver") != std::string::npos);
    CHECK(r.warning.find("glcore") != std::string::npos);
    REQUIRE(tried.size() == 2);
    CHECK(tried[1] == GpuBackend::Default);
    // D3D12 the same, headless.
    r = start_gpu_backend(GpuBackend::D3d12, failing("no adapter", ""), "d3d11", false);
    CHECK(r.ok);
    CHECK(r.used == GpuBackend::Default);
    CHECK(r.warning.find("headless") != std::string::npos);
    // Both fail: not ok, both errors, the first one first.
    r = start_gpu_backend(GpuBackend::Vulkan, failing("first error", "second error"), "glcore", true);
    CHECK_FALSE(r.ok);
    CHECK(r.fallbackReason == "first error");
    CHECK(r.error.find("first error") < r.error.find("second error"));
    // Default, or the build's own sokol backend, is never retried: nothing else draws.
    r = start_gpu_backend(GpuBackend::Default, failing("x", "sg_setup failed"), "glcore", true);
    CHECK_FALSE(r.ok);
    CHECK(r.error == "sg_setup failed");
    CHECK(r.fallbackReason.empty());
    CHECK(tried.size() == 1);
    CHECK(gpu_backend_on_context(GpuBackend::Default));
    CHECK_FALSE(gpu_backend_on_context(GpuBackend::Vulkan));
    CHECK_FALSE(gpu_backend_on_context(GpuBackend::D3d12));
    CHECK_FALSE(gpu_backend_on_context(GpuBackend::Recording));
    CHECK(gpu_backend_on_context(GpuBackend::Metal));  // a sokol backend (this binary may not have it)
}

namespace {
// A backend this binary can make besides Default (D3D12 or Vulkan), or Default when it has none.
GpuBackend an_own_backend() {
    for (GpuBackend b : {GpuBackend::Vulkan, GpuBackend::D3d12})
        if (gpu_backend_available(b)) return b;
    return GpuBackend::Default;
}
}  // namespace

TEST_CASE("gpu backend: start_gpu_backend tells the host about the failure before the in-process fallback") {
    // The Vulkan player starts the OpenGL player there (EngineConfig::gpuBackendFailed): the fallback must not run
    // first.
    std::vector<std::string> events;
    const GpuBackendStart start = [&events](GpuBackend b) {
        events.push_back(std::string("start ") + gpu_backend_name(b));
        return b == GpuBackend::Default ? std::string() : std::string("no Vulkan driver");
    };
    GpuBackendStartResult r =
        start_gpu_backend(GpuBackend::Vulkan, start, "glcore", true,
                          [&events](const std::string& why) { events.push_back("failed: " + why); });
    CHECK(r.ok);  // the host returned: the fallback went on
    REQUIRE(events.size() == 3);
    CHECK(events[0] == "start vulkan");
    CHECK(events[1] == "failed: no Vulkan driver");
    CHECK(events[2] == "start auto");
    // Not called when the backend starts, nor for the build's own backend.
    events.clear();
    r = start_gpu_backend(
        GpuBackend::Vulkan, [](GpuBackend) { return std::string(); }, "glcore", true,
        [&events](const std::string& why) { events.push_back(why); });
    CHECK(events.empty());
    r = start_gpu_backend(
        GpuBackend::Default, [](GpuBackend) { return std::string("sg_setup failed"); }, "glcore", true,
        [&events](const std::string& why) { events.push_back(why); });
    CHECK_FALSE(r.ok);
    CHECK(events.empty());
}

TEST_CASE("gpu backend: a backend that cannot start falls back in process and the report says why") {
    TempProject proj("fallback");
    ScopedEnv env("FA_GPU_BACKEND", nullptr);
    const GpuBackend own = an_own_backend();
    if (own == GpuBackend::Default) {
        MESSAGE("this build has neither D3D12 nor Vulkan: the in-process fallback was not checked");
        return;
    }
    // Headless: the asked backend fails at its start (forced, so every machine checks it), the build's backend draws.
    {
        EngineConfig c = cfg(proj);
        c.gpuBackend = gpu_backend_name(own);
        std::vector<GpuBackend> tried;
        c.gpuStartFault = [&tried, own](GpuBackend b) {
            tried.push_back(b);
            return b == own ? std::string("forced failure of the test") : std::string();
        };
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        // No GPU at all (the headless context did not start): no backend was tried, the fallback is not checked.
        if (!tried.empty()) {
            REQUIRE(tried.size() == 2);
            CHECK(tried[0] == own);
            CHECK(tried[1] == GpuBackend::Default);
        }
        if (e.renderer()) {
            const Json g = e.startup_report()["gpu"];
            CHECK(g["backend"].get<std::string>() == std::string(Renderer::backend_name()));
            CHECK(g["requestedBackend"] == gpu_backend_name(own));
            CHECK(g["backendFallback"] == "forced failure of the test");
            bool warned = false;
            for (const std::string& p : e.runtime_impl().startupProblems)
                warned = warned || p.find("forced failure of the test") != std::string::npos;
            CHECK(warned);
        } else {
            MESSAGE("no GPU here: the fallback's renderer did not start either");
        }
        e.shutdown();
    }
    // Both fail: the engine runs without graphics and says both errors.
    {
        EngineConfig c = cfg(proj);
        c.gpuBackend = gpu_backend_name(own);
        bool anyTried = false;
        c.gpuStartFault = [&anyTried](GpuBackend b) {
            anyTried = true;
            return std::string("forced ") + gpu_backend_name(b);
        };
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        CHECK(e.renderer() == nullptr);
        bool both = !anyTried;  // no GPU here: nothing was tried, so there is nothing to say
        for (const std::string& p : e.runtime_impl().startupProblems)
            both = both || (p.find(std::string("forced ") + gpu_backend_name(own)) != std::string::npos &&
                            p.find("forced auto") != std::string::npos);
        CHECK(both);
        e.shutdown();
    }
}

TEST_CASE("gpu backend: Engine::init tells the host about a failed backend once, in a window only") {
    TempProject proj("failedhook");
    ScopedEnv env("FA_GPU_BACKEND", nullptr);
    const GpuBackend own = an_own_backend();
    if (own == GpuBackend::Default) {
        MESSAGE("this build has neither D3D12 nor Vulkan: the host's hook was not checked");
        return;
    }
    // A window: the first start fails (forced), so does the fallback (the fault fails every backend, Default too: no
    // OpenGL context is opened here); the host hears about the first one, once.
    {
        EngineConfig c = cfg(proj);
        c.headless = false;
        c.gpuBackend = gpu_backend_name(own);
        c.gpuStartFault = [](GpuBackend b) { return std::string("forced ") + gpu_backend_name(b); };
        std::vector<std::string> heard;
        c.gpuBackendFailed = [&heard](const std::string& backend, const std::string& why) {
            heard.push_back(backend + ": " + why);
        };
        GfxEnvironment gfx{};  // no device: no start makes a renderer (the claim is refused, or the fault is)
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, &gfx, &err), err);
        REQUIRE(heard.size() == 1);
        CHECK(heard[0].find(gpu_backend_name(own)) == 0);
        // Either the window could not be claimed (no native window in a test) or the forced fault said it.
        CHECK(heard[0].size() > std::string(gpu_backend_name(own)).size() + 2);
        CHECK(e.renderer() == nullptr);
        e.shutdown();
    }
    // Headless: the host's hook is never called, and a player that was started in place of another one (the marker)
    // still reports both what it fell back from in process and which player started it.
    {
        ScopedEnv from(kGpuFallbackFromEnv, "vulkan");
        ScopedEnv reason(kGpuFallbackReasonEnv, "the marker's reason");
        EngineConfig c = cfg(proj);
        c.gpuBackend = gpu_backend_name(own);
        int calls = 0;
        c.gpuBackendFailed = [&calls](const std::string&, const std::string&) { calls++; };
        c.gpuStartFault = [own](GpuBackend b) {
            return b == own ? std::string("forced failure of the test") : std::string();
        };
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        CHECK(calls == 0);
        if (e.renderer()) {
            const Json g = e.startup_report()["gpu"];
            CHECK(g["backendFallback"] == "forced failure of the test");
            CHECK(g["requestedBackend"] == gpu_backend_name(own));
            CHECK(g["fallbackFrom"] == "vulkan");
            CHECK(g["fallbackReason"] == "the marker's reason");
        } else {
            MESSAGE("no GPU here: the report of the fallback was not checked");
        }
        e.shutdown();
    }
}

TEST_CASE("gpu backend: a headless engine uses the asked backend and the report names the device's") {
    TempProject proj("headless");
    ScopedEnv env("FA_GPU_BACKEND", nullptr);

    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(proj), nullptr, &err), err);
        if (e.renderer()) {
            const Json g = e.startup_report()["gpu"];
            CHECK(g["backend"].get<std::string>() == std::string(Renderer::backend_name()));
            CHECK_FALSE(g.contains("requestedBackend"));
        } else {
            MESSAGE("no GPU here: the default backend's report was not checked");
        }
        e.shutdown();
    }

    if (gpu_backend_available(GpuBackend::Vulkan)) {
        EngineConfig c = cfg(proj);
        c.gpuBackend = "vulkan";
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        const Json g = e.startup_report()["gpu"];
        const char* require = std::getenv("FA_VULKAN_REQUIRE");
        if (e.renderer() && g.contains("backendFallback")) {
            // No Vulkan driver here (Windows CI runners, a Linux machine without Mesa): the in-process fallback drew.
            if (require && std::string(require) == "1")
                FAIL("FA_VULKAN_REQUIRE=1 but Vulkan did not start: " << g["backendFallback"].dump());
            MESSAGE("this machine has no Vulkan GPU or driver: the engine fell back to " << g["backend"].dump());
            CHECK(g["requestedBackend"] == "vulkan");
        } else if (e.renderer()) {
            CHECK(e.renderer()->device_backend() == GpuBackend::Vulkan);
            CHECK(g["backend"] == "vulkan");
            CHECK_FALSE(g.contains("requestedBackend"));
        } else {
            MESSAGE("this machine has no Vulkan GPU or driver: the engine ran without graphics (a warning in "
                    "startupProblems)");
        }
        e.shutdown();
    } else {
        MESSAGE("this build has no Vulkan backend: the headless Vulkan selection was not checked");
    }

    // The variable overrides the project; a name the binary lacks warns and the default draws.
    const GpuBackend missing = an_unavailable_backend();
    if (missing != GpuBackend::Default) {
        TempProject asks("asks", std::string(R"(, "render": { "backend": ")") + gpu_backend_name(missing) + "\" }");
        ScopedEnv viaEnv("FA_GPU_BACKEND", "auto");  // auto from the variable beats the project's missing backend
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(asks), nullptr, &err), err);
        if (e.renderer()) CHECK_FALSE(e.startup_report()["gpu"].contains("requestedBackend"));
        e.shutdown();

        viaEnv.set(nullptr);
        Engine e2;
        REQUIRE_MESSAGE(e2.init(cfg(asks), nullptr, &err), err);
        if (e2.renderer()) {
            CHECK(e2.startup_report()["gpu"]["requestedBackend"] == gpu_backend_name(missing));
            CHECK(e2.renderer()->device_backend() != missing);
        }
        e2.shutdown();
    } else {
        MESSAGE("this binary has every GPU backend: the project's missing backend was not checked");
    }

    // A wrong name in the variable makes init fail and teaches.
    ScopedEnv bad("FA_GPU_BACKEND", "vulcan");
    Engine e;
    std::string err;
    CHECK_FALSE(e.init(cfg(proj), nullptr, &err));
    CHECK(err.find("FA_GPU_BACKEND") != std::string::npos);
    CHECK(err.find("vulkan") != std::string::npos);
}
