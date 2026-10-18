// Minimal ScriptHost for tests: owns world/input/audio/physics/commands, no renderer, no fa_runtime.
#pragma once
#include <filesystem>
#include <fstream>

#include "fa/audio/audio.h"
#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/physics/physics.h"
#include "fa/platform/input.h"
#include "fa/scene/animation.h"
#include "fa/scene/localize.h"
#include "fa/scene/serialize.h"
#include "fa/script/script.h"
#include "fa/services/fake_platform.h"
#include "fa/services/platform_commands.h"

namespace fa::test {

inline void write_file(const std::filesystem::path& root, const std::string& rel, const std::string& text) {
    auto p = root / rel;
    std::filesystem::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << text;
}

struct TestHost : ScriptHost {
    std::filesystem::path root;
    World w;
    Input in;
    Audio au;
    Physics ph;
    CommandRegistry cmds;
    PlatformServices platformServices;  // the fake store, with the platform.* commands; the catalog is proj["platform"]
    I18n loc;                           // proj["localization"] {defaultLanguage, languages}; the tables are read by start()
    Json proj = Json::object();
    ScriptSystem scripts;
    double fdt = 1.0 / 60.0;
    std::string pendingScene;
    bool quitRequested = false;
    std::string initError;

    explicit TestHost(const std::string& tag, const Json& settings = Json::object()) {
        ensure_builtin_components();
        root = fs::make_temp_dir("fa_script_test_" + tag);
        fs::set_project_root(root);
        fs::set_user_dir(root / "save");
        proj = settings;
        if (!proj.contains("input"))
            proj["input"] = Json::object({{"actions", Json::object({{"jump", Json::array({"Space"})},
                                                                     {"move_left", Json::array({"A"})},
                                                                     {"move_right", Json::array({"D"})}})}});
        in.set_actions(proj["input"]["actions"]);
        au.init(false, nullptr);
        au.set_clock(&w);
        ph.init(PhysicsSettings{});
        if (auto catalog = load_platform_catalog(proj.contains("platform") ? proj["platform"] : Json()); catalog.ok())
            platformServices.set_catalog(std::move(catalog.value()));
        platformServices.set_backend(std::make_unique<FakeBackend>(), "the test host always uses the fake");
        register_platform_commands(cmds, platformServices);
        if (proj.contains("localization")) {
            const Json& l = proj["localization"];
            loc.configure(l.value("defaultLanguage", std::string()), l.value("languages", std::vector<std::string>()));
        }
    }
    ~TestHost() override {
        scripts.shutdown();
        std::error_code ec;
        std::filesystem::remove_all(root, ec);
    }
    bool start() {
        fs::set_project_root(root);
        if (loc.enabled()) loc.load_tables();
        return scripts.init(*this, &initError);
    }
    void file(const std::string& rel, const std::string& text) { write_file(root, rel, text); }

    World& world() override { return w; }
    Input& input() override { return in; }
    Audio& audio() override { return au; }
    Physics& physics() override { return ph; }
    Renderer* renderer() override { return nullptr; }
    PlatformServices* platform_services() override { return &platformServices; }
    const I18n* i18n() override { return &loc; }
    std::string set_language(std::string_view language) override {  // what Engine::switch_language does
        const std::string previous = loc.language();
        auto r = loc.set_language(language);
        if (!r.ok()) return r.error().to_string();
        if (r.value() != previous) {
            localize_world(w, loc);
            w.events().game.push_back(GameEvent{"i18n.change", Json::object({{"language", r.value()}, {"previous", previous}}), kNullEntity});
        }
        return {};
    }
    CommandRegistry& commands() override { return cmds; }
    Json project_settings() const override { return proj; }
    double fixed_dt() const override { return fdt; }
    void request_scene_change(std::string_view p) override { pendingScene = std::string(p); }
    void request_quit() override { quitRequested = true; }
    bool screenshot(std::string_view, std::string* e) override { if (e) *e = "no renderer"; return false; }
    std::string load_scene_now(std::string_view p) override {
        LoadReport r = load_scene_file(w, p);
        ph.reset();
        w.reset_clock();
        localize_world(w, loc);
        scripts.on_scene_loaded();
        return r.ok() ? "" : r.summary();
    }
    std::string load_scene_json_now(const Json& scene, std::string_view name) override {
        LoadReport r = load_scene(w, scene, name);
        ph.reset();
        w.reset_clock();
        localize_world(w, loc);
        scripts.on_scene_loaded();
        return r.ok() ? "" : r.summary();
    }
    void step_frames(int n) override {
        for (int i = 0; i < n; ++i) {
            float dt = static_cast<float>(fdt);
            platformServices.frame();
            scripts.dispatch_platform();
            scripts.dispatch_back();
            scripts.fixed_update(dt);
            ph.step(w, dt);
            update_animators(w, dt);
            scripts.dispatch_events();
            scripts.update(dt);
            au.update(w, dt);
            scripts.late_update(dt);
            localize_world(w, loc);  // like the engine: keys of what scripts changed this frame
            w.advance_clock(fdt);
            w.flush();
            in.begin_frame();
            if (!pendingScene.empty()) { std::string s = pendingScene; pendingScene.clear(); load_scene_now(s); }
        }
    }
};

}  // namespace fa::test
