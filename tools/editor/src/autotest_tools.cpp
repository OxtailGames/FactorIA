// Autotest, second half (FA_EDITOR_AUTOTEST=1): what is left of the editor's UI, driven through the REAL window.
//
// The editor has no manual editing tools (the AI edits), so this half covers the Audio panel (View > Audio), commands that rebuild
// the open scene file (the Console and the AI call them), picking and the selection outline against the real renderer, and bloom in
// the viewport. Widgets publish where they are (Editor::at_track); the script moves, presses and releases the injected mouse over
// them exactly as a person would. After each action it checks the effect on disk, in the world and in the editor state, and takes
// window screenshots. A script of small steps, one step per frame followed by a wait, so a step never races the UI: a click is
// move, press, release on different frames.
//
// This file builds the script: the tools every section writes its steps with (AtScript), the setup that starts every section from the
// same state, and the call of each section in the order of a full run. The sections are Editor::at_section_<id> in autotest_<group>.cpp
// (autotest_common.h has what they share); the window capture, the step runner and the section report are here too.
#include "fa/core/engine_version.h"
#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>
#include <atomic>
#include <thread>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
#include "autotest_sections.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "fa/core/date.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/net.h"
#include "fa/tooling/play_auto.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

}  // namespace

bool Editor::capture_window(Image& img) {
    const int w = sapp_width(), h = sapp_height();
    img.width = w;
    img.height = h;
    img.rgba.resize(size_t(w) * size_t(h) * 4);
    if (!ui::read_backbuffer(w, h, img.rgba.data())) return false;
    for (size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    return true;
}

void Editor::at_run_steps(int frame) {
    if (atSteps_.empty() || frame < atStepAt_) return;
    AtStep s = std::move(atSteps_.front());
    atSteps_.pop_front();
    atInStep_ = true;
    atStepRetry_ = false;
    s.run();
    atInStep_ = false;
    if (atStepRetry_) {  // its widget is scrolled out of view: at_track scrolls to it, and the step runs again once it is shown
        atStepRetry_ = false;
        const std::string name = atScrollTo_;
        atSteps_.push_front(std::move(s));
        atWaitCount_ = 0;
        atWaitUntil_ = [this, name] { return at_shown(name); };
        atStepAt_ = frame + 1;
        return;
    }
    atScrollTo_.clear();
    atStepAt_ = frame + s.wait;
}

void Editor::at_section_begin(const std::string& id) {
    const auto now = std::chrono::steady_clock::now();
    if (!atCosts_.empty() && atCosts_.back().frames == 0) {
        AtSectionCost& last = atCosts_.back();
        last.frames = std::max<std::uint64_t>(1, atFramesDrawn_ - atSectionFrame0_);
        last.seconds = std::chrono::duration<double>(now - atSectionStart_).count();
        last.failures = atFailures_.size() - atSectionFailures0_;
    }
    if (id.empty()) return;
    atCosts_.push_back(AtSectionCost{id});
    atSectionFrame0_ = atFramesDrawn_;
    atSectionStart_ = now;
    atSectionFailures0_ = atFailures_.size();
    std::string title;
    for (const AutotestSection& s : kAutotestSections)
        if (id == s.id) title = s.title;
    atLog_.push_back("SECTION " + id + ": " + title);
    FA_INFO("autotest", "section {}: {}", id, title);
}

Json Editor::at_section_report() {
    at_section_begin("");
    Json list = Json::array();
    std::uint64_t frames = 0;
    double seconds = 0;
    std::printf("\nautotest sections (FA_EDITOR_AUTOTEST_SECTIONS=<ids> runs only some):\n  %-4s %7s %8s %8s  %s\n", "id", "frames",
                "seconds", "failures", "title");
    for (const AtSectionCost& c : atCosts_) {
        std::string title;
        for (const AutotestSection& s : kAutotestSections)
            if (c.id == s.id) title = s.title;
        list.push_back(Json::object(
            {{"id", c.id}, {"title", title}, {"frames", c.frames}, {"seconds", c.seconds}, {"failures", c.failures}}));
        std::printf("  %-4s %7llu %8.1f %8zu  %s\n", c.id.c_str(), static_cast<unsigned long long>(c.frames), c.seconds, c.failures,
                    title.c_str());
        frames += c.frames;
        seconds += c.seconds;
    }
    std::printf("  %-4s %7llu %8.1f %8zu\n\n", "all", static_cast<unsigned long long>(frames), seconds, atFailures_.size());
    std::fflush(stdout);
    return list;
}

void Editor::at_build_tools_script() {
    using Fn = std::function<void()>;
    AtScript at;       // what the sections write their steps with (autotest_common.h); the lambdas below fill it in
    bool& keep = at.keep;  // false while the script passes over a section FA_EDITOR_AUTOTEST_SECTIONS did not ask for
    auto step = [this, &keep](int wait, Fn fn) {
        if (keep) atSteps_.push_back(AtStep{wait, std::move(fn)});
    };
    // A click is three steps on different frames: move onto the widget, press, release.
    auto click = [this, &step](const std::string& name) {
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
        step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
    };
    // A screenshot: first the mouse is parked on the status bar (no hover tooltip) and the toasts are cleared, three frames
    // later the window is captured (after the UI of that frame was drawn).
    auto snap = [this, &step](const std::string& file) {
        step(3, [this] {
            toasts_.clear();
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{900, 884});
        });
        step(2, [this, file] { atPendingShots_.push_back(atOutDir_ + "/" + file); });
    };
    auto project_file = [this](const std::string& rel) { return projectDir_ + "/" + rel; };
    // The wheel over (x, y) until a widget is shown in its window with room below it (maxY): what a long page needs, however
    // long it is on this computer (a warning that wraps onto more lines moves everything down). A click never lands on a widget
    // that is scrolled out of its window: at_widget refuses it. dy is the way to try first (> 0 up); when the widget does not
    // move (the window is already at that end, as a section run alone finds it), the wheel turns the other way.
    // `at` may be a function: the point is looked up each frame (over a panel whose position depends on the window size).
    auto scroll_until_at = [this, &step](std::function<std::string()> nameOf, float dy, std::function<Vec2()> at, float maxY, float minY = 120) {
        step(2, [this, at] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at()); });
        struct Wheel {
            float dy, lastY = -1e9f;
            bool lastOfWidget = false;
            int stuck = 0;
        };
        auto wheel = std::make_shared<Wheel>(Wheel{dy});
        for (int i = 0; i < 60; ++i)
            step(1, [this, nameOf, wheel, at, maxY, minY] {
                const std::string name = nameOf();
                auto it = atWidgets_.find(name);
                if (at_shown(name) && it != atWidgets_.end() && it->second.y < maxY && it->second.y > minY) return;
                // Whether the wheel still moves anything: the widget's y while it is drawn, else the scroll of the window
                // being wheeled (a widget scrolled out of a child window is not drawn at all, so its y never changes).
                const bool ofWidget = it != atWidgets_.end() && at_visible(name);
                const ImGuiContext& g = *ImGui::GetCurrentContext();
                const ImGuiWindow* wheeled = g.WheelingWindow ? g.WheelingWindow : g.HoveredWindow;
                if (ofWidget || wheeled) {
                    const float y = ofWidget ? it->second.y : wheeled->Scroll.y;
                    wheel->stuck = ofWidget == wheel->lastOfWidget && y == wheel->lastY ? wheel->stuck + 1 : 0;
                    wheel->lastY = y;
                    wheel->lastOfWidget = ofWidget;
                    if (wheel->stuck == 2) wheel->dy = -wheel->dy;
                }
                const Vec2 where = at();
                sapp_event ev{};
                ev.type = SAPP_EVENTTYPE_MOUSE_SCROLL;
                ev.mouse_x = where.x * dpi_;
                ev.mouse_y = where.y * dpi_;
                ev.scroll_y = wheel->dy;
                on_event(&ev);
            });
    };
    auto scroll_until = [&scroll_until_at](const std::string& name, float dy, Vec2 at, float maxY) {
        scroll_until_at([name] { return name; }, dy, [at] { return at; }, maxY);
    };
    // The visible middle of a window, wherever this display put it: where the wheel goes to scroll that window. A widget
    // below the fold of a small display (the macOS runner's 1024x642) needs it before a click.
    auto window_middle = [](const char* window) {
        const ImGuiWindow* w = ImGui::FindWindowByName(window);
        if (!w) return Vec2{500, 300};
        const ImVec2 d = ImGui::GetIO().DisplaySize;
        const float top = std::max(w->Pos.y, 0.0f), bottom = std::min(w->Pos.y + w->Size.y, d.y - 24.0f);
        return Vec2{std::clamp(w->Pos.x + w->Size.x * 0.5f, 0.0f, d.x), (top + bottom) * 0.5f};
    };
    // Scroll the window `window` until `name` is shown: the way to try first is down (a form's buttons are at its end).
    // `window` is copied: the steps run later, after the code that built the script returned (a `const char*` into a local
    // std::string of the caller dangled; found by the ASan run as a heap-use-after-free).
    auto scroll_to = [&scroll_until_at, window_middle](const std::string& name, const std::string& window, float dy = -6) {
        scroll_until_at([name] { return name; }, dy, [window_middle, window] { return window_middle(window.c_str()); }, 100000, -1e9f);
    };
    // The lambdas above live as long as this function, which calls every section: the sections get them through `at`.
    at.step = step;
    at.click = click;
    at.snap = snap;
    at.project_file = project_file;
    at.scroll_until_at = scroll_until_at;
    at.scroll_until = scroll_until;
    at.window_middle = window_middle;
    at.scroll_to = scroll_to;

    // FA_EDITOR_AUTOTEST_REAL_CMAKE=1 (a manual end-to-end check, never set by ctest): the editor's setup context is the real
    // one, so this script does only one thing, press the CMake button of the Set Up window and let it install CMake for real
    // into the autotest's own FACTORIA_HOME (<out>/factoria_home, about 50 MB from Kitware). Nothing else is clicked: the other
    // sections press buttons that would download players and the Android SDK.
    if (const char* real = std::getenv("FA_EDITOR_AUTOTEST_REAL_CMAKE"); real && *real && std::string(real) != "0") {
        atFrameBudget_ = 20000;
        step(2, [this] {
            stop();
            select_id("");
        });
        click("menu:file");
        step(3, [] {});
        click("menu:setup");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return setupStatus_.has() && !setupStatus_.refreshing(); };
        });
        step(4, [this] {
            const SetupComponent* c = setupStatus_.status().find("cmake");
            at_check(c != nullptr, "the Set Up window lists CMake");
            at_check(at_visible("setup:install:cmake") && at_enabled("setup:install:cmake"), "...with a button to install it");
            at_check(setupStatus_.status().home == (std::filesystem::path(atOutDir_) / "factoria_home").string(),
                     "...into the autotest's own FACTORIA_HOME (" + setupStatus_.status().home + ")");
        });
        snap("editor_setup_cmake_before.png");
        click("setup:install:cmake");
        // The bar fills while the download runs: one picture in the middle of it.
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !setupJob_.running() || setupJob_.fraction() >= 0.3; };
        });
        step(3, [this] { at_check(true, "the install runs on its worker thread while the window keeps drawing (" + setupJob_.progress_line() + ")"); });
        snap("editor_setup_cmake_progress.png");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !setupJob_.running() && setupLast_.has_value(); };
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !setupRefreshAgain_ && !setupStatus_.refreshing(); };  // the window looks again
        });
        step(6, [this] {
            at_check(setupLast_.has_value() && setupLast_->ok, "CMake was installed: " + (setupLast_ ? setupLast_->error : std::string("no result")));
            if (setupLast_) at_check(!setupLast_->report.steps.empty(), "...the report lists its steps");
            std::string installed;
            if (setupLast_)
                for (const auto& [key, value] : setupLast_->report.paths)
                    if (key == "cmake") installed = value;
            const std::string home = (std::filesystem::path(atOutDir_) / "factoria_home").string();
            at_check(!installed.empty() && stdfs::exists(installed) && installed.rfind(home, 0) == 0,
                     "CMake is where the report says, inside the autotest's FACTORIA_HOME (" + installed + ")");
            const std::string cmakeExe = find_cmake(make_setup_context());
            at_check(!cmakeExe.empty(), "find_cmake finds a CMake afterwards (" + cmakeExe + ")");
            const SetupComponent* c = setupStatus_.status().find("cmake");
            at_check(c && c->state == "installed", "the window reads the computer again: CMake is installed");
        });
        snap("editor_setup_cmake_done.png");
        step(2, [this] {
            Json report = Json::object({{"failures", atFailures_}, {"log", atLog_}, {"frames", atFrame_}});
            (void)save_json_file(atOutDir_ + "/autotest_result.json", report);
            FA_INFO("autotest", "finished: {} failure(s)", atFailures_.size());
            sapp_request_quit();
        });
        return;
    }

    // ------------------------------------------------------------------------------------------------------ setup
    // Every section starts with section(id): the script keeps it only when FA_EDITOR_AUTOTEST_SECTIONS asked for it (or named
    // none), and its first steps put the editor back in the same state, whatever the section before it did: the clean 2D fixture
    // as the open scene, no window of the autotest open, factoria.json as it was when the script was built, the mouse parked.
    // A section run alone passes or fails as it does in the full run (autotest_sections.h lists them).
    const std::string projectJson = read_file(project_file("factoria.json"));
    auto section = [this, &step, &keep, project_file, projectJson](const char* id) {
        keep = at_section_selected(id);
        step(1, [this, id] {
            at_section_begin(id);
            stop();
            select_id("");
            showExport_ = showPlatformSettings_ = platformCloseAsk_ = keystoreOpen_ = false;
            showSetup_ = setupLicenseOpen_ = showProjectDialog_ = showAudio_ = showProfiler_ = false;
            showProject_ = showHierarchy_ = showInspector_ = true;
            if (showAnimation_ || anim_.posed) anim_unpose();  // sections B2 and C2: the panels, the pose and the tools are not carried over
            anim_ = AnimUi{};
            bone_ = BoneUi{};
            showAnimation_ = showBoneTools_ = showImage_ = showVector_ = showSound_ = showMusic_ = showModeler_ = false;
            particle_close_document();   // section P3: the Particles panel, its effect and its preview are not carried over
            particle_ = ParticleUi{};
            showParticle_ = false;
            reset_auto_play_state();   // section S3: the Play sessions window, its list and a run still going are not carried over
            reset_review_state();   // section R4: the Review window, its sheet, its pictures and a sheet of seeds still being made are not carried over
            showLevelGen_ = false;   // section R3: the Level generator window, its sample, its preview and its history are not carried over
            levelGen_.clear(level_gen_caller());
            levelGenOpt_ = LevelGenOptions{};
            levelGenMessage_.clear();
            levelGenSelId_.clear();
            sound_close_document();   // section K3: the Sound panel, its sound and its playback are not carried over
            sound_release_textures();
            if (sound_.player) sound_.player->stop();
            sound_ = SoundUi{};
            music_close_document();   // section M3: the Music panel, its song and its playback are not carried over
            music_.preview.reset();
            music_.model.reset();
            music_ = MusicUi{};
            modeler_close_document();   // section N3: the Model panel and its document are not carried over
            modeler_release_textures();
            modeler_.model.reset();
            modeler_ = ModelerUi{};
            vector_release_textures();
            vector_ = VectorUi{};   // section J2: the Vector panel, its drawing and its tools are not carried over
            image_release_textures();   // section I2: the Image panel, its document and its tools are not carried over
            image_ = ImageUi{};
            anim3d_release_textures();   // section O3: the Animation panel's 3D mode, its clip and its sheets are not carried over
            anim3d_ = Anim3DUi{};
            projBrowser_.query = BrowserQuery{};
            exportLast_.reset();
            exportChecked_ = -100;
            atMods_ = 0;
            toasts_.clear();
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{900, 884});
            focus_window("Console");  // the tab in front where the Console is docked: the same in every section
        });
        step(2, [this, id, project_file, projectJson] {
            gizmoMode_ = GizmoMode::Select;  // the sections before M click and compare pictures: no handles over the selection
            if (read_file(project_file("factoria.json")) != projectJson) write_file(project_file("factoria.json"), projectJson);
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();  // the fixture is the open scene, clean (no unsaved changes, no undo history)
            write_file(project_file("assets/blip.wav"), silence_wav());
            focus_window("###Viewport");
            at_check(!dirty() && undo_depth() == 0 && !world().find_by_id("player").is_null() && !world().find_by_id("coin_3").is_null(),
                     std::string("section ") + id + " starts on the clean 2D fixture");
        });
    };

    section("T");
    at_section_T(at);
    section("A");
    at_section_A(at);
    section("A2");
    at_section_A2(at);
    section("B");
    at_section_B(at);
    section("C");
    at_section_C(at);
    section("D");
    at_section_D(at);
    section("E");
    at_section_E(at);
    section("F");
    at_section_F(at);
    section("G");
    at_section_G(at);
    section("H");
    at_section_H(at);
    section("I");
    at_section_I(at);
    section("J");
    at_section_J(at);
    section("K");
    at_section_K(at);
    section("L");
    at_section_L(at);
    section("M");
    at_section_M(at);
    section("N");
    at_section_N(at);
    section("O");
    at_section_O(at);
    section("P");
    at_section_P(at);
    section("Q");
    at_section_Q(at);
    section("R");
    at_section_R(at);
    section("U");
    at_section_U(at);
    section("V");
    at_section_V(at);
    section("W");
    at_section_W(at);
    section("X");
    at_section_X(at);
    section("Q2");
    at_section_Q2(at);
    section("Y");
    at_section_Y(at);
    section("Z");
    at_section_Z(at);
    section("B2");
    at_section_B2(at);
    section("C2");
    at_section_C2(at);
    section("D2");
    at_section_D2(at);
    section("E2");
    at_section_E2(at);
    section("E3");
    at_section_E3(at);
    section("H2");
    at_section_H2(at);
    section("S2");
    at_section_S2(at);
    section("K2");
    at_section_K2(at);
    section("F2");
    at_section_F2(at);
    section("I2");
    at_section_I2(at);
    section("L3");
    at_section_L3(at);
    section("J2");
    at_section_J2(at);
    section("K3");
    at_section_K3(at);
    section("M3");
    at_section_M3(at);
    section("N3");
    at_section_N3(at);
    section("P3");
    at_section_P3(at);
    section("O3");
    at_section_O3(at);
    section("E4");
    at_section_E4(at);
    section("R2");
    at_section_R2(at);
    section("R3");
    at_section_R3(at);
    section("A3");
    at_section_A3(at);
    section("T2");
    at_section_T2(at);
    section("S3");
    at_section_S3(at);
    section("R4");
    at_section_R4(at);

    // ------------------------------------------------------------------------------------------------------ done
    keep = true;
    step(2, [this] {
        select_id("");
        Json report = Json::object({{"failures", atFailures_}, {"log", atLog_}, {"frames", atFrame_}, {"sections", at_section_report()}});
        (void)save_json_file(atOutDir_ + "/autotest_result.json", report);
        FA_INFO("autotest", "finished: {} failure(s)", atFailures_.size());
        sapp_request_quit();
    });
}

}  // namespace fa::editor
