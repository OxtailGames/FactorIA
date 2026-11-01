// Autotest, second half (FA_EDITOR_AUTOTEST=1): what is left of the editor's UI, driven through the REAL window.
//
// The editor has no manual editing tools (the AI edits), so this half covers the Audio panel (View > Audio), commands that rebuild
// the open scene file (the Console and the AI call them), picking and the selection outline against the real renderer, and bloom in
// the viewport. Widgets publish where they are (Editor::at_track); the script moves, presses and releases the injected mouse over
// them exactly as a person would. After each action it checks the effect on disk, in the world and in the editor state, and takes
// window screenshots. A script of small steps, one step per frame followed by a wait, so a step never races the UI: a click is
// move, press, release on different frames.
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

#include "autotest_sections.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

namespace stdfs = std::filesystem;

// Section U: where a panel is now. Floating panels have no dock node; a docked one names its node.
ImGuiWindow* panel_window(const char* name) { return ImGui::FindWindowByName(name); }
bool panel_floating(const char* name) {
    const ImGuiWindow* w = panel_window(name);
    return w && !w->DockIsActive && w->DockNode == nullptr;
}
ImGuiID panel_node(const char* name) {
    const ImGuiWindow* w = panel_window(name);
    return w && w->DockNode ? w->DockNode->ID : 0;
}
float panel_width(const char* name) {
    const ImGuiWindow* w = panel_window(name);
    return w ? w->Size.x : 0.0f;
}

void write_file(const std::string& path, const std::string& bytes) {
    std::error_code ec;
    stdfs::create_directories(stdfs::path(path).parent_path(), ec);
    std::ofstream(path, std::ios::binary) << bytes;
}

std::string read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

std::string silence_wav() {  // 0.1 s of silence, 16-bit mono PCM
    const std::uint32_t n = 4410;
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
    auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
    b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
    b += "data"; u32(n * 2);
    b.append(std::size_t(n) * 2, '\0');
    return b;
}

// The scene the second half of the autotest works on. The first half runs on whatever the 2d-platformer template ships; from here on
// the checks must not depend on the template's entities, positions or levels, so the project's main scene is replaced by this fixture:
// a camera at the origin looking at 1280 x 720 world units, a few shapes, a player, three coins. No scripts, no physics, no tags that
// scene.import_ascii would treat as its own (`tilemap:<id>`), so importing a level into it cannot remove any of these entities.
const char* kFixtureScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "name": "Main Camera",
      "components": { "Transform": { "position": [0, 0, 0] }, "Camera": { "clearColor": [0.35, 0.55, 0.85, 1], "primary": true } } },
    { "id": "ground", "name": "Ground",
      "components": { "Transform": { "position": [0, -320, 0] }, "Shape2D": { "size": [3000, 80], "color": [0.25, 0.6, 0.3, 1] } } },
    { "id": "platform_1", "name": "Platform 1",
      "components": { "Transform": { "position": [250, -200, 0] }, "Shape2D": { "size": [220, 24], "color": [0.55, 0.4, 0.25, 1] } } },
    { "id": "player", "name": "Player", "tags": ["player"],
      "components": { "Transform": { "position": [-300, -250, 0] }, "Shape2D": { "size": [32, 48], "color": [0.95, 0.35, 0.3, 1], "layer": 2 } } },
    { "id": "coin_1", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [-100, -266, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } },
    { "id": "coin_2", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [250, -160, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } },
    { "id": "coin_3", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [420, -266, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } }
  ]
})";

// Section K: a 3D scene with one cube drawn by a custom material (docs/design/CUSTOM_SHADERS.md). The snippet adds `glow` to the
// emission; the "v2" snippet also paints the albedo blue, and the broken one is a GLSL error on line 3.
const char* kMatScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 1.5, 4] }, "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": { "Transform": { "position": [0, 5, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } },
    { "id": "gem", "components": { "Transform": { "scale": [1.5, 1.5, 1.5] },
        "MeshRenderer": { "mesh": "cube", "color": [0.125, 0.125, 0.125, 1], "material": "materials/autotest_glow.material.json" } } }
  ]
})";
const char* kMatFile = R"({
  "format": "factoria.material/1",
  "doc": "Editor autotest: adds the glow color to the emission.",
  "shader": "shaders/autotest_glow.surface.glsl",
  "params": { "glow": { "type": "color", "default": [1.0, 0.35, 0.0, 1.0], "doc": "Emission color; its alpha scales the strength." } }
})";
const char* kMatSnippet = "void surface(in SurfaceInput i, inout Surface s) {\n    s.emission += glow.rgb * glow.a;\n}\n";
const char* kMatSnippetV2 = "void surface(in SurfaceInput i, inout Surface s) {\n    s.albedo = vec3(0.0, 0.0, 1.0);\n    s.emission += glow.rgb * glow.a;\n}\n";
const char* kMatSnippetBroken = "void surface(in SurfaceInput i, inout Surface s) {\n    s.albedo = vec3(0.0, 0.0, 1.0);\n    s.colour = glow.rgb;\n}\n";

// Section L: a cube with a material that has a ranged float, a vec3 and a color param (the Inspector types them by material.info).
const char* kInspectScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 1.5, 4] }, "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": { "Transform": { "position": [0, 5, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } },
    { "id": "gem", "components": { "Transform": { "scale": [1.5, 1.5, 1.5] },
        "MeshRenderer": { "mesh": "cube", "color": [0.125, 0.125, 0.125, 1], "material": "materials/autotest_inspect.material.json" } } }
  ]
})";
const char* kInspectMatFile = R"({
  "format": "factoria.material/1",
  "doc": "Editor autotest: params of three types for the Inspector.",
  "shader": "shaders/autotest_glow.surface.glsl",
  "params": {
    "glow": { "type": "color", "default": [1.0, 0.35, 0.0, 1.0], "doc": "Emission color; its alpha scales the strength." },
    "pulse": { "type": "float", "default": 1.0, "min": 0.0, "max": 4.0, "doc": "Pulses per second (0 to 4)." },
    "tint": { "type": "vec3", "default": [1.0, 1.0, 1.0], "doc": "Multiplies the base color." }
  }
})";

// Section M2: a tilted cube under a perspective camera (3D gizmos), and a screen-space (HUD) rectangle under a 2D camera.
const char* kGizmo3dScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 0, 6] }, "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": { "Transform": { "position": [0, 5, 0], "rotation": [-50, 30, 0] }, "Light": { "intensity": 0.8 } } },
    { "id": "gem", "components": { "Transform": { "rotation": [10, 20, 0] }, "MeshRenderer": { "mesh": "cube", "color": [0.9, 0.5, 0.2, 1] } } }
  ]
})";
const char* kGizmoHudScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [0, 0, 0] }, "Camera": { "clearColor": [0.35, 0.55, 0.85, 1], "primary": true } } },
    { "id": "hud", "name": "Score",
      "components": { "Transform": { "position": [300, 200, 0] }, "Shape2D": { "size": [160, 48], "color": [0.95, 0.35, 0.3, 1], "space": "screen" } } }
  ]
})";

// The entity `id` in a saved scene's entities (children searched too), or nullptr.
const Json* find_saved_entity(const Json& list, const std::string& id) {
    if (!list.is_array()) return nullptr;
    for (const Json& e : list) {
        if (e.value("id", std::string()) == id) return &e;
        if (e.contains("children"))
            if (const Json* c = find_saved_entity(e["children"], id)) return c;
    }
    return nullptr;
}

struct MatShots {
    Image base, green, undone, v2, broken, fixed, playing;
    bool skip = false;      // no shader compiler on this machine: the section only records that
    std::uint64_t seq = 0;  // last log seq before the edit under test
    int edits = 0;          // makes every rewritten file's modification time new
    Json state;             // the material's state in the renderer before the last rewrite
};

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
    s.run();
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

namespace {
// Section P's scripted "model": in one turn it overwrites a script, writes a new one (fs.write, like an API provider) and
// spawns an entity (a scene edit), then says it is done.
class RevertProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest&, const ai::ChatHooks& hooks, const ai::CancelFlag*) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 900;
        r.usage.outputTokens = 60;
        if (turn_ == 0) {
            r.message.text = "Writing two scripts and adding a coin. ";
            if (hooks.onText) hooks.onText(r.message.text);
            auto call = [&](const char* id, const char* name, const char* input) {
                ai::ToolCall c;
                c.id = id;
                c.name = name;
                c.input = Json::parse(input);
                r.message.toolCalls.push_back(c);
            };
            call("w1", "fs_write", R"({"path":"scripts/revert_old.js","content":"new\n"})");
            call("w2", "fs_write", R"({"path":"scripts/revert_new.js","content":"added by the run\n"})");
            call("w3", "scene_spawn", R"({"name":"RevertCoin","position":[0,120],"components":{"Shape2D":{"shape":"circle","size":[28,28],"color":[1,0.85,0.1,1]}}})");
            r.stopReason = ai::StopReason::ToolUse;
        } else {
            r.message.text = "Done.";
            if (hooks.onText) hooks.onText(r.message.text);
            r.stopReason = ai::StopReason::EndTurn;
        }
        ++turn_;
        return r;
    }

private:
    int turn_ = 0;
};

// Section Q's worker: says something, takes `delayMs` to think (cancellable), then reports. Nothing else; no tool calls.
class SlowWorkerProvider : public ai::ChatProvider {
public:
    explicit SlowWorkerProvider(int delayMs) : delayMs_(delayMs) {}
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest&, const ai::ChatHooks& hooks, const ai::CancelFlag* cancel) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 300;
        r.usage.outputTokens = 30;
        if (hooks.onText) hooks.onText("Making the coin. ");
        for (int waited = 0; waited < delayMs_ && !(cancel && cancel->load()); waited += 25)
            std::this_thread::sleep_for(std::chrono::milliseconds(25));
        r.message.text = "Making the coin. Worker report: coin done";
        if (hooks.onText) hooks.onText("Worker report: coin done");
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }

private:
    int delayMs_;
};
// Section W's scripted "model" for several chats at once. The first user message carries a marker. [A], [B] and [L] work: they
// wait (1.2 s, 1.2 s, 3.5 s; cancellable), then write scripts/u_shared.js and their own scripts/u_<letter>.js and spawn a coin
// (UCoin<LETTER>). [S] only waits, 20 s (a run to Stop). Every run ends by saying "Finished <marker>".
class ConcurrentProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest& req, const ai::ChatHooks& hooks, const ai::CancelFlag* cancel) override {
        char marker = '?';
        for (const ai::Message& m : req.messages) {
            if (m.role != ai::Role::User) continue;
            const std::size_t at = m.text.find('[');
            if (at != std::string::npos && at + 2 < m.text.size() && m.text[at + 2] == ']') {
                marker = m.text[at + 1];
                break;
            }
        }
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 500;
        r.usage.outputTokens = 40;
        const bool answered = !req.messages.empty() && !req.messages.back().toolResults.empty();
        if (!answered) {
            r.message.text = std::string("Working on ") + marker + ". ";
            if (hooks.onText) hooks.onText(r.message.text);
            const int delayMs = marker == 'S' ? 20000 : marker == 'L' ? 3500 : 1200;
            for (int waited = 0; waited < delayMs && !(cancel && cancel->load()); waited += 25)
                std::this_thread::sleep_for(std::chrono::milliseconds(25));
            if (marker != 'S' && !(cancel && cancel->load())) {
                const std::string lower(1, static_cast<char>(std::tolower(static_cast<unsigned char>(marker))));
                const std::string upper(1, marker);
                auto call = [&](const std::string& id, const char* name, const Json& input) {
                    ai::ToolCall c;
                    c.id = id;
                    c.name = name;
                    c.input = input;
                    r.message.toolCalls.push_back(c);
                };
                call("w1", "fs_write", Json::object({{"path", "scripts/u_shared.js"}, {"content", "from " + upper + "\n"}}));
                call("w2", "fs_write", Json::object({{"path", "scripts/u_" + lower + ".js"}, {"content", "only " + upper + "\n"}}));
                call("w3", "scene_spawn",
                     Json::parse("{\"name\":\"UCoin" + upper + "\",\"position\":[0,120],\"components\":{\"Shape2D\":{\"shape\":\"circle\","
                                 "\"size\":[28,28],\"color\":[1,0.85,0.1,1]}}}"));
                r.stopReason = ai::StopReason::ToolUse;
                return r;
            }
        }
        r.message.text = std::string("Finished ") + marker;
        if (hooks.onText) hooks.onText(r.message.text);
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};
// Section U's reviewer: no tool calls, one report that ends in the score block. It records the tools it was offered, so the
// test can see that a read-only role really is not given the ones that change the project.
std::vector<std::string> g_reviewToolsOffered;
class ReviewerProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest& req, const ai::ChatHooks& hooks, const ai::CancelFlag*) override {
        g_reviewToolsOffered.clear();
        for (const ai::ToolDef& t : req.tools) g_reviewToolsOffered.push_back(t.name);
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 900;
        r.usage.outputTokens = 60;
        r.message.text =
            "The first minute is clear and the controls answer at once.\n\n```json\n"
            "{\"score\": 7.5, \"subScores\": {\"fun\": 8, \"polish\": 6}, \"summary\": \"Clear and quick\"}\n```";
        if (hooks.onText) hooks.onText(r.message.text);
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};
// Section E2's reviewer of a share text: every check passes, the text is left as it is.
class ShareReviewProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest&, const ai::ChatHooks& hooks, const ai::CancelFlag*) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.message.text =
            "{\"real\":{\"ok\":true,\"why\":\"The docs list no way to pause particles.\"},"
            "\"aboutEngine\":{\"ok\":true,\"why\":\"It names an engine feature only.\"},"
            "\"notPossibleYet\":{\"ok\":true,\"why\":\"No command or component does it.\",\"use\":\"\"},"
            "\"share\":null,\"fix\":\"\"}";
        if (hooks.onText) hooks.onText(r.message.text);
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};
}  // namespace

void Editor::at_build_tools_script() {
    using Fn = std::function<void()>;
    bool keep = true;  // false while the script passes over a section FA_EDITOR_AUTOTEST_SECTIONS did not ask for
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
    auto scroll_to = [&scroll_until_at, window_middle](const std::string& name, const char* window, float dy = -6) {
        scroll_until_at([name] { return name; }, dy, [window_middle, window] { return window_middle(window); }, 100000, -1e9f);
    };

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
            showAnimation_ = showBoneTools_ = false;
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
    // The toolbar's Screenshot button. It reads the game target back, which never completes inside the UI frame on Metal (the
    // game's command buffer is not committed yet): the button only asks, on_frame takes the picture between frames. A hang here
    // is caught by the autotest's watchdog (no frame for 60 s) instead of freezing the window for good.
    click("toolbar:screenshot");
    step(8, [this] {
        std::error_code ec;
        bool found = false;
        for (const auto& e : stdfs::directory_iterator(projectDir_ + "/.factoria/screenshots", ec))
            if (e.path().extension() == ".png") found = true;
        at_check(found, "the toolbar Screenshot button saves a PNG into the project's .factoria/screenshots");
        at_check(at_visible("toast:screenshot-reveal"), std::string("the screenshot toast offers Show in ") + file_manager_name());
        toasts_.clear();
    });

    // ----------------------------------------------------------------------------------- A. Audio panel (View menu)
    section("A");
    click("menu:view");
    step(3, [] {});
    click("menu:audio");
    step(4, [this] {
        at_check(showAudio_, "View > Audio shows the Audio panel");
        pendingFocus_ = "Audio";
        play();
    });
    step(12, [this] {
        // The panel may already list sounds the game made earlier in this run: the checks are relative to what it shows now.
        atAudioBase_ = audioLog_.plays.size();
        run_console_line("> audio.play('assets/blip.wav', {bus: 'ui', volume: 0.6})");
        run_console_line("> audio.play('assets/missing.wav')");
    });
    step(6, [this] {
        const size_t n = audioLog_.plays.size();
        at_check(n == atAudioBase_ + 2, "the Audio panel polled both new plays while the game runs");
        if (n >= 2) {
            const AudioPlay& good = audioLog_.plays[n - 2];
            const AudioPlay& bad = audioLog_.plays[n - 1];
            at_check(good.path == "assets/blip.wav" && good.ok && good.bus == "ui", "a successful play shows its clip and bus");
            at_check(bad.path == "assets/missing.wav" && !bad.ok, "a clip that failed to load is flagged ok: false");
        }
        pendingFocus_ = "Audio";
    });
    snap("editor_audio.png");
    step(2, [this] {
        atAudioAfter_ = audioLog_.after;
        run_console_line("> audio.play('assets/blip.wav')");
    });
    step(6, [this] {
        at_check(audioLog_.plays.size() == atAudioBase_ + 3 && audioLog_.after > atAudioAfter_, "only the new play is added (the poll asks for plays after the last seq)");
        audioLog_.filter = "missing";
        size_t visible = 0;
        for (const AudioPlay& p : audioLog_.plays) visible += audio_play_visible(p, audioLog_) ? 1 : 0;
        at_check(visible == 1, "the path filter keeps only matching plays");
        audioLog_.filter.clear();
        audioLog_.onlyFailed = true;
        visible = 0;
        size_t failed = 0;
        for (const AudioPlay& p : audioLog_.plays) {
            visible += audio_play_visible(p, audioLog_) ? 1 : 0;
            failed += p.ok ? 0 : 1;
        }
        at_check(visible == failed && failed >= 1, "Failed only keeps exactly the failed loads");
        audioLog_.onlyFailed = false;
        clear_audio_log(audioLog_);
        at_check(audioLog_.plays.empty(), "Clear empties the list");
    });
    step(4, [this] {
        at_check(audioLog_.plays.empty(), "plays seen before Clear do not come back");
        stop();
        showAudio_ = false;
        pendingFocus_ = "Console";
    });

    // ----------------------------------------------------------------------------------- A2. Profiler panel (View menu)
    section("A2");
    // A behaviour on the player, then View > Profiler while the game plays: its class must show up as a row with time and calls.
    step(2, [this, project_file] {
        write_file(project_file("scripts/autotest_spinner.js"),
                   "import { Behaviour } from \"factoria\";\n"
                   "export default class AutotestSpinner extends Behaviour {\n"
                   "  onUpdate(dt) { let x = 0; for (let i = 0; i < 4000; i++) x += Math.sqrt(i); this.sum = x; }\n"
                   "}\n");
        run_console_line("scene.set_component {\"id\":\"player\",\"component\":\"Script\",\"fields\":{\"path\":\"scripts/autotest_spinner.js\"}}");
    });
    click("menu:view");
    step(3, [] {});
    click("menu:profiler");
    step(4, [this] {
        at_check(showProfiler_, "View > Profiler shows the Profiler panel");
        pendingFocus_ = "Profiler";
        play();
    });
    step(40, [] {});
    step(4, [this] {
        at_check(profView_.frames > 10, "the Profiler panel measured the frames of the running game");
        const auto row = std::find_if(profView_.rows.begin(), profView_.rows.end(),
                                      [](const ProfilerView::Row& r) { return r.className == "AutotestSpinner"; });
        at_check(row != profView_.rows.end(), "a row for the behaviour class AutotestSpinner appears");
        if (row != profView_.rows.end()) {
            at_check(row->ms > 0.0 && row->calls > 0.5, "...with milliseconds and about one onUpdate call per frame");
            at_check(row->path == "scripts/autotest_spinner.js", "...and its script path");
        }
        at_check(profView_.systemMs[std::size_t(ProfSystem::ScriptsUpdate)] > 0.0, "the scriptsUpdate system has time");
        pendingFocus_ = "Profiler";
    });
    snap("editor_profiler.png");

    // ---------------------------------------------------------- B. Commands that rebuild the open scene file (Console / AI)
    section("B");
    // A file import into the OPEN scene reloads it in the viewport, and Ctrl+Z still brings back what was on screen.
    step(2, [this] {
        run_console_line("scene.set_component " +
                         Json::object({{"id", "player"},
                                       {"component", "Transform"},
                                       {"fields", Json::object({{"position", Json::array({-305, -250, 0})}})}})
                             .dump());
        at_check(dirty(), "an unsaved edit before a console import");
        run_console_line("scene.import_ascii {\"rows\":[\"...\",\"###\"],\"legend\":{\"#\":0},\"entity\":\"map3\",\"path\":\"" + scenePath_ + "\"}");
    });
    step(3, [this] {
        at_check(!world().find_by_id("map3").is_null(), "a console import into the open scene reloads it");
        at_check(!dirty() && undo_depth() == 1, "...and nothing is lost: the unsaved edit is one Ctrl+Z away");
        undo();
        at_check(world().find_by_id("map3").is_null() && dirty(), "Ctrl+Z restores the scene as it was before the import");
        redo();
        at_check(!world().find_by_id("map3").is_null(), "Ctrl+Y brings the imported level back");
        undo();
        run_console_line("scene.import_ascii {\"rows\":[\"#\"],\"legend\":{\"#\":0},\"path\":\"scenes/other_level.scene.json\"}");
        at_check(dirty() && world().find_by_id("map3").is_null(), "an import into another file does not touch the open scene or its unsaved changes");
        at_check(fs::exists("scenes/other_level.scene.json"), "...it just writes the file");
    });

    // ------------------------------------------- C. Pick bounds and the selection outline against the real renderer
    section("C");
    step(2, [this] {
        World& w = world();
        auto make = [&](const char* id, Vec3 pos, float rot) {
            Entity e = w.create(id, id);
            Transform* t = w.get<Transform>(e);
            t->position = pos;
            t->rotation = {0, 0, rot};
            return e;
        };
        Entity dia = make("test_diamond", {200, 150, 0}, 30.0f);
        Shape2D& d = w.add<Shape2D>(dia);
        d.shape = ShapeType::Diamond;
        d.size = {80, 40};
        d.color = {0.9f, 0.5f, 0.9f, 1};
        Entity tri = make("test_triangle", {-200, 150, 0}, 90.0f);
        Shape2D& t = w.add<Shape2D>(tri);
        t.shape = ShapeType::Triangle;
        t.size = {60, 90};
        t.pivot = {0.5f, 0.3333f};
        t.color = {0.4f, 0.9f, 0.5f, 1};
        // A Tilemap in rows form (3 x 2 tiles, top-left corner at (350, 250)) and a world-space Text.
        Entity rowsMap = make("test_rows_map", {350, 250, 0}, 0.0f);
        Tilemap& rm = w.add<Tilemap>(rowsMap);
        rm.tileSize = {32, 32};
        rm.tiles = Json::parse("[[0,0,0],[0,-1,0]]");
        Entity worldText = make("test_text", {-120, 300, 0}, 0.0f);
        Text& wt = w.add<Text>(worldText);
        wt.text = "World text";
        wt.fontSize = 28;
        // Screen-space text at the top-left (pivot top-left, y down): the shape the template's HUD text has, made here.
        Entity hudText = make("test_hud_text", {24, 24, 0}, 0.0f);
        Text& ht = w.add<Text>(hudText);
        ht.text = "Coins: 0";
        ht.fontSize = 32;
        ht.pivot = {0, 1};
        ht.space = RenderSpace::Screen;
        ht.layer = 100;
        Entity hudBox = make("test_hud", {-20, 60, 0}, 0.0f);
        Shape2D& h = w.add<Shape2D>(hudBox);
        h.size = {100, 40};
        h.pivot = {1, 0};
        h.space = RenderSpace::Screen;
        h.anchor = {1, 0};
        h.layer = 50;
        h.color = {0.2f, 0.2f, 0.2f, 0.8f};
    });
    step(3, [this] {
        Renderer* r = engine_->renderer();
        World& w = world();
        auto design = [&](float x, float y) { return r->world_to_screen(Vec3{x, y, 0}); };
        const Entity tri = w.find_by_id("test_triangle"), dia = w.find_by_id("test_diamond"), hud = w.find_by_id("test_hud");
        // Rotated triangle (pivot [0.5, 0.3333], turned 90 degrees): world x -260..-170, y 120..180 around its origin (-200, 150).
        at_check(pick_at(design(-255, 150)) == tri, "pick: inside the rotated triangle's oriented box");
        at_check(pick_at(design(-200, 205)) != tri, "pick: outside the oriented box, though inside the unrotated one");
        at_check(pick_at(design(-165, 150)) != tri, "pick: past the base of the rotated triangle");
        // Diamond turned by 30 degrees: its size box is 80 x 40 around (200, 150).
        at_check(pick_at(design(200, 150)) == dia, "pick: the diamond's centre");
        at_check(pick_at(design(200 + 30, 150 + 8)) == dia, "pick: inside the turned size box");
        at_check(pick_at(design(200, 150 + 60)) != dia, "pick: above the diamond");
        // Tilemap in rows form: x 350..446, y 186..250 (local y goes down from the top-left corner).
        const Entity rowsMap = w.find_by_id("test_rows_map");
        at_check(pick_at(design(400, 220)) == rowsMap, "pick: inside a Tilemap given as rows");
        at_check(pick_at(design(400, 180)) != rowsMap, "pick: below the map's last row");
        at_check(pick_at(design(400, 256)) != rowsMap, "pick: above the map's top-left corner");
        // Text: the box the renderer lays out (pivot top-left), not an estimate.
        const Entity worldText = w.find_by_id("test_text");
        const Vec2 ts = r->measure_text("World text", 28);
        at_check(ts.x > 100 && ts.y > 20, "the renderer measures the text");
        at_check(pick_at(design(-120 + ts.x * 0.5f, 300 - ts.y * 0.5f)) == worldText, "pick: inside the measured Text box");
        at_check(pick_at(design(-120 + ts.x + 12, 300 - ts.y * 0.5f)) != worldText, "pick: just past the measured end of the Text");
        at_check(pick_at(design(-120 + ts.x * 0.5f, 300 + 8)) != worldText, "pick: above the Text (pivot is the top-left corner)");
        // Screen space: a panel anchored top-right (x 1160..1260, y 20..60 on the 1280 x 720 screen).
        at_check(pick_at(Vec2{1200, 40}) == hud, "pick: a screen-space shape with an anchor");
        at_check(pick_at(Vec2{1100, 40}) != hud, "pick: left of the anchored panel");
        // Screen-space text (pivot top-left, y down): picked on its drawn box, not mirrored above it.
        const Entity text = w.find_by_id("test_hud_text");
        const PickBounds tb = bounds_of(text);
        at_check(tb.screenSpace, "the HUD text is a screen-space entity");
        at_check(pick_at(Vec2{40, 40}) == text, "pick: the screen-space HUD text under the cursor");
        // The engine's entity.bounds() (script) and the editor's footprint agree.
        auto r2 = engine_->commands().call("script.eval", Json::object({{"code", "world.find('test_diamond').bounds().toArray()"}}));
        const std::optional<Rect> eb = entity_world_rect(w, dia, visual_measure());
        const Json v = r2.ok ? r2.result.value("value", Json()) : Json();
        bool same = eb && v.is_array() && v.size() == 4;
        if (same) {
            const float mine[4] = {eb->x, eb->y, eb->w, eb->h};
            for (size_t i = 0; i < 4; ++i) same = same && std::fabs(v[i].get<float>() - mine[i]) < 0.01f;
        }
        at_check(same, "entity.bounds() in a script equals the editor's world rectangle for the turned diamond");
        select(dia);
    });
    snap("editor_select_diamond.png");
    step(1, [this] { select_id("test_triangle"); });
    snap("editor_select_triangle.png");
    step(1, [this] { select_id("test_hud_text"); });
    snap("editor_select_hud.png");

    // ------------------------------------------------------------------------------------ D. Bloom in the viewport
    section("D");
    step(1, [this] {
        // A glow source on an empty patch of sky; bloom is still off, and nothing is selected (no outline in the way).
        Entity glow = world().create("test_glow", "test_glow");
        world().get<Transform>(glow)->position = Vec3{-420, 230, 0};
        Shape2D& g = world().add<Shape2D>(glow);
        g.shape = ShapeType::Circle;
        g.size = {70, 70};
        g.color = {1, 1, 1, 1};
        g.blend = BlendMode::Additive;
        g.layer = 5;
        select_id("");
    });
    step(4, [this] {
        // Bloom OFF reference.
        atPostFrame_.push_back([this] { at_check(capture_window(atShotBefore_), "captured the window without bloom"); });
    });
    step(3, [this] {
        // The command the AI uses; the values are inside the documented ranges (threshold 0..1, intensity 0..10, radius 1..128).
        const CommandResult r = engine_->commands().call(
            "scene.set_component",
            Json::parse(R"({"id":"camera","component":"Camera","fields":{"bloom":true,"bloomThreshold":0.8,"bloomIntensity":1.6,"bloomRadius":40}})"));
        at_check(r.ok, "scene.set_component: Camera.bloom on");
        Entity cam = world().find_by_id("camera");
        at_check(!cam.is_null() && std::fabs(world().get<Camera>(cam)->bloomRadius - 40.0f) < 0.001f, "the Camera bloom fields were written");
    });
    step(5, [this] {
        atPostFrame_.push_back([this] {
            Image after;
            if (!capture_window(after) || atShotBefore_.empty()) {
                at_check(false, "captured the window with bloom");
                return;
            }
            Renderer* r = engine_->renderer();
            const Vec2 d = r->world_to_screen(Vec3{-420, 230, 0});
            const float sx = vpImageSize_.x / float(r->target_width());
            const float cx = (vpImageMin_.x + d.x * sx) * dpi_, cy = (vpImageMin_.y + d.y * sx) * dpi_;
            const float radius = 35.0f * sx * dpi_;
            auto ring_sum = [&](const Image& img) {
                double sum = 0;
                int n = 0;
                for (int y = int(cy - radius * 2.4f); y <= int(cy + radius * 2.4f); ++y)
                    for (int x = int(cx - radius * 2.4f); x <= int(cx + radius * 2.4f); ++x) {
                        const float dist = std::hypot(float(x) - cx, float(y) - cy);
                        if (dist < radius * 1.2f || dist > radius * 2.2f || x < 0 || y < 0 || x >= img.width || y >= img.height) continue;
                        const std::uint8_t* px = &img.rgba[(size_t(y) * size_t(img.width) + size_t(x)) * 4];
                        sum += px[0] + px[1] + px[2];
                        ++n;
                    }
                return n ? sum / n : 0.0;
            };
            const double before = ring_sum(atShotBefore_), now = ring_sum(after);
            FA_INFO("autotest", "bloom ring brightness: off {:.1f}, on {:.1f}", before, now);
            at_check(now > before + 6.0, "Camera.bloom is visible in the editor viewport (the glow brightens the area around the bright shape)");
        });
    });
    snap("editor_bloom.png");

    // ------------------------------------------------------------------------- E. Ctrl+V into the AI Assistant input
    section("E");
    // sokol_app turns Ctrl+V into a CLIPBOARD_PASTED event (only with the clipboard enabled); sokol_imgui then presses
    // Ctrl+V for ImGui, which pastes the clipboard's text into the focused box.
    static const char* kPasted = "A 3D tower game.\nThree levels.";
    click("ai:input");
    step(4, [this] {
        chat_.current().input.clear();
        sapp_set_clipboard_string(kPasted);
        sapp_event ev{};
        ev.type = SAPP_EVENTTYPE_CLIPBOARD_PASTED;
        on_event(&ev);
    });
    step(2, [this] {
        at_check(chat_.current().input == kPasted, "Ctrl+V pastes the clipboard's text into the AI Assistant input");
        chat_.current().input.clear();
        focus_window("###Viewport");
    });

    // ----------------------------------------------- F. AI Assistant text: wrapping, right-click menu, selectable messages
    section("F");
    auto rclick = [this, &step](const std::string& name) {
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
        step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
        step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
    };
    static const char* kLong = "Make a 3D tower game: the player throws balls at towers of crates, three levels, each tower "
                               "taller than the last, a score for every crate that falls off, and a restart button at the end.";
    step(2, [this] { chat_.current().input = kLong; });  // before the click: an active box keeps its own copy of the text
    click("ai:input");
    snap("editor_ai_input_wrap.png");  // the long message wraps inside the box
    rclick("ai:input");
    click("textmenu:Select all");
    rclick("ai:input");
    snap("editor_ai_text_menu.png");
    click("textmenu:Cut");
    step(2, [this] {
        at_check(chat_.current().input.empty(), "right-click > Select all, then Cut, empties the AI Assistant input");
        const char* clip = ImGui::GetClipboardText();
        at_check(clip && std::string(clip) == kLong, "Cut puts the text on the clipboard");
    });
    rclick("ai:input");
    click("textmenu:Paste");
    step(2, [this] {
        at_check(chat_.current().input == kLong, "right-click > Paste puts the clipboard's text back");
        chat_.current().input.clear();
        ChatItem reply;
        reply.kind = ChatItem::Kind::Assistant;
        reply.text = "Copy this reply.";
        chat_.current().items.push_back(reply);
        chat_.current().scrollDown = true;
    });
    rclick("ai:message");
    click("textmenu:Select all");
    rclick("ai:message");
    click("textmenu:Copy");
    step(2, [this] {
        const char* clip = ImGui::GetClipboardText();
        at_check(clip && std::string(clip) == "Copy this reply.", "an assistant message can be selected and copied (right-click > Select all, Copy)");
        chat_.current().items.pop_back();
    });

    // New output is followed only at the bottom: scrolled up to read, the transcript stays put and "Jump to latest" goes back.
    auto transcript = [] {
        for (ImGuiWindow* w : GImGui->Windows)
            if (std::strstr(w->Name, "AI Assistant/##chat_") && !std::strstr(w->Name, "##jump") && w->Active) return w;
        return static_cast<ImGuiWindow*>(nullptr);
    };
    auto items0 = std::make_shared<std::size_t>();
    step(2, [this, items0] {
        *items0 = chat_.current().items.size();
        for (int i = 0; i < 80; ++i) {
            ChatItem it;
            it.kind = ChatItem::Kind::Info;
            it.text = "line " + std::to_string(i);
            chat_.current().items.push_back(it);
        }
        chat_.current().forceScroll = true;
    });
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->ScrollMax.y > 0 && w->Scroll.y >= w->ScrollMax.y - 4, "the AI transcript scrolls to the bottom");
        if (w) ImGui::SetScrollY(w, 0);  // the user scrolls up to read
    });
    step(3, [this] {
        ChatItem it;
        it.kind = ChatItem::Kind::Info;
        it.text = "new output while reading";
        chat_.current().items.push_back(it);
        chat_.current().scrollDown = true;
    });
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y < 1, "new output does not move a transcript the user scrolled up");
    });
    snap("editor_ai_jump_latest.png");
    click("ai:jump");
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y >= w->ScrollMax.y - 4, "Jump to latest goes back to the bottom");
    });
    step(2, [this] {
        ChatItem it;
        it.kind = ChatItem::Kind::Info;
        it.text = "followed again";
        chat_.current().items.push_back(it);
        chat_.current().scrollDown = true;
    });
    step(3, [this, transcript] {
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y >= w->ScrollMax.y - 4, "at the bottom again, new output is followed");
    });
    // The grip above the message box makes it taller.
    auto grip = std::make_shared<Vec2>();
    step(2, [this, grip] {
        aiInputH_ = 0;
        *grip = at_widget("ai:input:grip");
        inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, *grip);
    });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, *grip); });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{grip->x, grip->y - 40}); });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{grip->x, grip->y - 80}); });
    step(2, [this, grip] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, Vec2{grip->x, grip->y - 80}); });
    snap("editor_ai_input_tall.png");
    step(2, [this, items0, transcript] {
        const float def = ImGui::GetTextLineHeight() * 3.4f + 8;
        at_check(aiInputH_ > def + 40, "dragging the grip up makes the AI message box taller (" + std::to_string(aiInputH_) + ")");
        ImGuiWindow* w = transcript();
        at_check(w && w->Scroll.y >= w->ScrollMax.y - 4, "a transcript at the bottom stays at the bottom while the box grows");
        aiInputH_ = 0;
        chat_.current().items.resize(*items0);
        focus_window("###Viewport");
    });

    // ------------------------------------------------------------- G. Delete a project from the Open project dialog
    section("G");
    step(2, [this] {
        atDeleteProject_ = atOutDir_ + "/delete-me";
        ScaffoldOptions so;
        so.name = "delete-me";
        auto r = create_project(atDeleteProject_, "2d-empty", so);
        at_check(bool(r), "a scratch project to delete was created");
        showProjectDialog_ = true;
    });
    step(2, [this] { dlgOpenPath_ = atDeleteProject_; });
    click("project:delete");
    snap("editor_delete_project.png");  // the confirmation popup
    step(2, [this] { at_check(stdfs::exists(atDeleteProject_), "Delete... only asks: the project is still there"); });
    click("project:delete-confirm");
    step(2, [this] {
        at_check(!stdfs::exists(atDeleteProject_), "confirming deletes the project folder");
        at_check(dlgError_.empty(), "no error deleting the project (" + dlgError_ + ")");
        showProjectDialog_ = false;
        dlgScanned_ = false;
    });

    // ------------------------------------------------- H. Export window: a button per platform, then the export's report
    section("H");
    // Export Game in the menu bar opens it. Every platform's row says what an export there writes, or why it cannot run here
    // (another OS's desktop player is not in this build tree). This machine's platform is exported for real, with the
    // factoria_player of the build tree, on the export's worker thread; the report shows the folder and the next steps.
    const std::string host = normalize_export_platform("");
    auto host_status = [this, host]() -> const ExportStatus* {
        for (size_t i = 0; i < export_targets().size() && i < exportStatus_.size(); ++i)
            if (host == export_targets()[i].platform) return &exportStatus_[i];
        return nullptr;
    };
    step(2, [this] {
        at_check(windowTitle_ == editor_window_title(FA_ENGINE_VERSION, "Autotest Platformer"),
                 "the window title names the engine version and the project (" + windowTitle_ + ")");
        at_check(at_visible("menu:version"), "the menu bar shows the engine version at its right end");
    });
    click("menu:export");
    step(4, [this, host_status] {
        at_check(showExport_, "the Export Game item of the menu bar opens the Export window");
        at_check(exportStatus_.size() == export_targets().size(), "the Export window checked every platform");
        for (size_t i = 0; i < exportStatus_.size() && i < export_targets().size(); ++i) {
            const ExportTarget& t = export_targets()[i];
            const ExportStatus& st = exportStatus_[i];
            if (st.ready) continue;
            at_check(!st.error.empty() && !st.hint.empty(), std::string(t.label) + " is not ready and says why and how to fix it");
            if (export_needs_player(t.platform))
                at_check(st.error.find("cannot export for") != std::string::npos,
                         std::string(t.label) + " needs a player built for it (" + st.error + ")");
        }
        const ExportStatus* st = host_status();
        if (st && !st->ready) {  // a build tree without factoria_player: export with a stand-in, the window is what is tested
            atLog_.push_back("NOTE no factoria_player for this machine (" + st->error + "): exporting with a stand-in player");
            const std::string fake = atOutDir_ + "/stand-in-player/factoria_player";
            write_file(fake, "#!/bin/sh\nexit 0\n");
            exportSettings_.players[normalize_export_platform("")] = fake;
            exportChecked_ = -100;
        }
    });
    snap("editor_export_window.png");
    click("export:" + host);
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !exportJob_.running() && exportLast_.has_value(); };
    });
    step(2, [this, host] {
        at_check(exportLast_.has_value(), "pressing this machine's Export button runs an export that finishes");
        if (!exportLast_) return;
        const ExportOutcome& o = *exportLast_;
        at_check(o.ok && o.platform == host, "the " + host + " export succeeded (" + o.error + " " + o.hint + ")");
        if (!o.ok) return;
        std::error_code ec;
        const stdfs::path out = stdfs::weakly_canonical(o.report.outputDir, ec);
        const stdfs::path parent = stdfs::weakly_canonical(stdfs::path(projectDir_) / "build" / "export", ec);
        at_check(out.parent_path() == parent && out.filename().string() == "autotest-platformer-" + host,
                 "the export went to <project>/build/export/<game>-<platform> (" + o.report.outputDir + ")");
        at_check(stdfs::exists(out / o.report.notices), "the license notices are where the report says (" + o.report.notices + ")");
        at_check(!o.report.nextSteps.empty(), "the report lists the next steps");
        at_check(at_visible("export:reveal"), std::string("the report offers Show in ") + file_manager_name());
        at_check(export_report_text(o).find(o.report.outputDir) != std::string::npos, "Copy report includes the output folder");
    });
    snap("editor_export_report.png");
    step(2, [this] { showExport_ = false; });

    // ------------------------------------------------- I. Platform settings window
    section("I");
    // Opened from the Settings... button of the Android row in the Export window, then through the tabs. Edits make it dirty,
    // the Export window's format menu keeps working next to pending edits, Save writes factoria.json (and only that: this
    // computer's file is untouched), closing with unsaved changes asks, and File > Platform Settings... opens it again.
    // This computer's settings live in a scratch file (FACTORIA_EXPORT_CONFIG, set by on_init): never the user's own.
    const std::string machineFile = machine_export_config_path();
    step(2, [this, project_file] {
        // A game icon with a transparent corner, as the AI would make one.
        Image icon;
        icon.width = icon.height = 1024;
        icon.rgba.resize(size_t(icon.width) * size_t(icon.height) * 4);
        for (int y = 0; y < icon.height; ++y)
            for (int x = 0; x < icon.width; ++x) {
                std::uint8_t* px = &icon.rgba[(size_t(y) * size_t(icon.width) + size_t(x)) * 4];
                px[0] = std::uint8_t(x / 4);
                px[1] = std::uint8_t(y / 4);
                px[2] = 200;
                px[3] = (x < 200 && y < 200) ? 0 : 255;
            }
        at_check(save_png(icon, project_file("assets/icon.png")).ok(), "a game icon was written to assets/icon.png");
    });
    click("menu:export");
    step(4, [this] { at_check(at_visible("export:settings:android"), "the Export window has a Settings... button on the Android row"); });
    // On a smaller screen (the macOS runner's 1024x642) the Android row can be out of view: above it after section H (the
    // window stays scrolled down to the report it showed), below it when this section runs alone. Scroll to it.
    scroll_until("export:settings:android", 6, Vec2{700, 400}, 560);
    click("export:settings:android");
    step(4, [this] {
        at_check(showPlatformSettings_, "the Android row's Settings... button opens the Platform settings window");
        at_check(platformTab_ == SettingsTab::Android, "...on the Android tab");
        at_check(platformSettings_.loaded() && !platformSettings_.dirty(), "...with nothing to save yet");
        at_check(platformSettings_.info.name == "Autotest Platformer", "it shows the game's own name (" + platformSettings_.info.name + ")");
        at_check(platformSettings_.parseErrors.empty() && platformSettings_.fileError.empty(), "the project's export settings read without errors");
        // What a person types in the fields.
        PlatformSettings& ps = platformSettings_;
        ps.project.icon = "assets/icon.png";
        ps.project.android.versionCode = 12;
        ps.project.android.permissions = {"android.permission.VIBRATE"};
        ps.project.android.signing.keystore = "keys/upload.keystore";
        ps.project.macos.copyright = "Copyright 2026 Autotest";
        ps.project.ios.teamId = "ABCDE12345";
        at_check(ps.dirty(), "typing in a field makes the settings dirty");
        at_check(ps.validate().errors.empty(), "the edits are valid");
        at_check(ps.validate().warning_for("/export/android/signing/alias") != nullptr, "a keystore without an alias is a warning next to the alias field");
    });
    snap("editor_platform_android.png");
    scroll_until("platform:keystore-create", -6, Vec2{800, 420}, 560);
    snap("editor_platform_android_signing.png");
    click("platform:keystore-create");
    step(4, [this] {
        at_check(keystoreOpen_, "Create keystore... opens its window");
        at_check(!keystoreForm_.path.empty() && keystoreForm_.alias == "upload", "...with a keystore path and the alias upload filled in");
    });
    snap("editor_platform_keystore.png");
    click("platform:keystore-cancel");
    step(4, [this] { at_check(!keystoreOpen_, "Cancel closes the keystore window"); });
    click("platform:tab:general");
    step(4, [this] { at_check(platformTab_ == SettingsTab::General, "clicking the General tab shows it"); });
    snap("editor_platform_general.png");
    click("platform:tab:macos");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Macos, "clicking the macOS tab shows it"); });
    snap("editor_platform_macos.png");
    click("platform:tab:ios");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Ios, "clicking the iOS tab shows it"); });
    snap("editor_platform_ios.png");
    click("platform:tab:linux");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Linux, "clicking the Linux tab shows it"); });
    snap("editor_platform_linux.png");
    click("platform:tab:windows");
    step(4, [this] { at_check(platformTab_ == SettingsTab::Windows, "clicking the Windows tab shows it"); });
    snap("editor_platform_windows.png");

    // The Export window's format menu, with edits pending here: the format is saved at once and the working copy follows.
    step(2, [this] {
        set_android_format("aab");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok() && saved->android.format == "aab", "the Export window's format menu saves export.android.format in factoria.json");
        at_check(saved.ok() && saved->android.versionCode == 0, "...and nothing else of the pending edits");
        at_check(platformSettings_.project.android.format == "aab" && platformSettings_.project.android.versionCode == 12,
                 "...while the Platform settings window keeps its other edits");
        at_check(platformSettings_.dirty(), "...which are still unsaved");
        at_check(!platformSettings_.project_file_changed(), "factoria.json written by the editor itself is not reported as changed behind its back");
    });
    // The same for the Windows format (folder | MSIX): saved at once, the pending edits stay.
    step(2, [this] {
        set_windows_format("msix");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok() && saved->windows.format == "msix", "the Export window's Windows format menu saves export.windows.format in factoria.json");
        at_check(saved.ok() && saved->android.versionCode == 0, "...and nothing else of the pending edits");
        at_check(platformSettings_.project.windows.format == "msix" && platformSettings_.project.android.versionCode == 12,
                 "...while the Platform settings window keeps its other edits");
        at_check(platformSettings_.dirty(), "...which are still unsaved");
        at_check(!platformSettings_.project_file_changed(), "factoria.json written by the editor itself is not reported as changed behind its back");
        platformSettings_.project.windows.msix.identityName = "12345Autotest.Platformer";
        platformSettings_.project.windows.msix.publisher = "CN=0123ABCD-4567-89EF-0123-456789ABCDEF";
        platformSettings_.project.windows.msix.publisherDisplayName = "Autotest Studio";
    });
    click("platform:tab:android");
    step(3, [this] { platformSettings_.project.android.signing.alias = "upload"; });
    click("platform:save");
    step(4, [this, machineFile] {
        at_check(!platformSettings_.dirty(), "Save leaves nothing unsaved");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok(), "factoria.json still reads after Save");
        if (saved.ok()) {
            at_check(saved->icon == "assets/icon.png", "Save wrote the game icon");
            at_check(saved->android.versionCode == 12 && saved->android.format == "aab", "Save wrote the Android settings");
            at_check(saved->windows.format == "msix" && saved->windows.msix.identityName == "12345Autotest.Platformer" &&
                         saved->windows.msix.publisherDisplayName == "Autotest Studio",
                     "Save wrote the Windows MSIX settings");
            at_check(saved->android.permissions == std::vector<std::string>{"android.permission.VIBRATE"}, "Save wrote the permissions");
            at_check(saved->android.signing.keystore == "keys/upload.keystore" && saved->android.signing.alias == "upload", "Save wrote the signing key");
            at_check(saved->macos.copyright == "Copyright 2026 Autotest" && saved->ios.teamId == "ABCDE12345", "Save wrote the macOS and iOS settings");
        }
        auto project = load_project(projectDir_);
        at_check(project.ok() && project->name == "Autotest Platformer", "Save kept the game's own keys");
        at_check(!std::filesystem::exists(machineFile), "Save did not write this computer's file (nothing of it was edited)");
    });

    // Closing with unsaved changes asks first.
    step(2, [this] { platformSettings_.project.windows.icon = "assets/icon.png"; });
    click("platform:close");
    step(4, [this] {
        at_check(platformCloseAsk_ && showPlatformSettings_, "Close with unsaved changes asks instead of closing");
    });
    snap("editor_platform_unsaved.png");
    click("platform:close-discard");
    step(4, [this] {
        at_check(!showPlatformSettings_ && !platformCloseAsk_, "Discard closes the window");
        auto saved = load_export_settings(projectDir_);
        at_check(saved.ok() && saved->windows.icon.empty(), "...without saving the edit");
    });
    click("menu:file");
    step(3, [] {});
    click("menu:platform-settings");
    step(4, [this] {
        at_check(showPlatformSettings_ && platformTab_ == SettingsTab::General, "File > Platform Settings... opens the window on General");
        at_check(platformSettings_.loaded() && !platformSettings_.dirty() && platformSettings_.project.icon == "assets/icon.png",
                 "...with what was saved");
    });
    snap("editor_platform_reopened.png");
    click("platform:close");
    step(4, [this] { at_check(!showPlatformSettings_, "Close with nothing unsaved just closes"); });
    step(2, [this] { showExport_ = false; });

    // ------------------------------------------------- J. Set Up This Computer
    section("J");
    // File > Set Up This Computer... lists the five components; the Export window and the Platform settings tabs offer the
    // "Set up" button that fixes a row; the Android SDK license dialog only lets "I accept" through after its checkbox.
    // The editor's setup context in the autotest (on_init) can neither download nor run a program, and its FACTORIA_HOME is a
    // folder of the autotest's own: no step here can install anything, and none presses "I accept".
    std::string otherOs, ownOs;  // a desktop platform that needs another OS's player, and one that does not
    for (const char* p : {"windows", "linux", "macos"}) {
        if (export_needs_player(p) && otherOs.empty()) otherOs = p;
        if (!export_needs_player(p) && ownOs.empty()) ownOs = p;
    }
    // A Mac with nothing set up, and Export rows to match: the other OS's player and the Android toolchain missing, the rest ready.
    auto inject_setup = [this, otherOs] {
        SetupStatus st;
        st.home = atOutDir_ + "/factoria_home";
        st.host = "injected-autotest";
        auto add = [&st](const char* id, const char* title, const char* details, int mb) {
            SetupComponent c;
            c.id = id;
            c.title = title;
            c.state = "missing";
            c.details = details;
            c.installSizeMb = mb;
            c.canInstall = true;
            st.components.push_back(c);
        };
        add("android", "Android export (JDK + Android SDK)", "`setup.install android` fetches what is missing.", 600);
        add("players", "Players of the other platforms", "Missing: other desktop players and mobile libraries.", 60);
        add("cmake", "CMake (iOS export)", "CMake 3.24 or newer is needed by build_ios.sh.", 75);
        st.components.back().problems = {"No CMake 3.24 or newer was found (PATH, Homebrew, /Applications/CMake.app)."};
        add("xcode", "Xcode (iOS export)", "Xcode is not installed.", 0);
        setupStatus_.set(st, time_ + 100000.0);  // far in the future: the window's own refresh leaves it alone
        setupRefreshAgain_ = false;
        exportStatus_.assign(export_targets().size(), ExportStatus{});
        for (size_t i = 0; i < exportStatus_.size(); ++i) {
            const std::string platform = export_targets()[i].platform;
            exportStatus_[i].ready = true;
            exportStatus_[i].hint = "injected-autotest";
            if (platform == otherOs) {
                exportStatus_[i].ready = false;
                exportStatus_[i].error = "export: cannot export for " + platform + " without a player binary built for " + platform;
            } else if (platform == "android") {
                exportStatus_[i].ready = false;
                exportStatus_[i].error = "export: cannot build the Android app on this computer: No JDK 17 or newer was found.";
            }
        }
        exportChecked_ = time_ + 100000.0;
        exportLast_.reset();  // the report of section H would push the rows out of view
    };
    auto action_labels = [this](const std::string& platform) {
        std::vector<std::string> out;
        for (size_t i = 0; i < export_targets().size() && i < exportStatus_.size(); ++i)
            if (platform == export_targets()[i].platform)
                for (const SetupAction& a : setup_actions_for_row(platform, exportStatus_[i], setupStatus_.status())) out.push_back(a.label);
        return out;
    };

    // The window: File > Set Up This Computer... lists the seven components, each with its Install button (the AppImage
    // tools and sokol-shdc have none yet: `factoria setup appimage|shaders`).
    click("menu:file");
    step(3, [] {});
    click("menu:setup");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return setupStatus_.has() && !setupStatus_.refreshing(); };
    });
    step(4, [this] {
        at_check(showSetup_, "File > Set Up This Computer... opens the window");
        const SetupStatus& st = setupStatus_.status();
        std::string ids;
        for (const SetupComponent& c : st.components) ids += c.id + " ";
        at_check(ids == "android players cmake xcode appimage shaders vscode ffmpeg webplayer launcher ", "the window lists the ten components, in order (" + ids + ")");
        at_check(st.home == (std::filesystem::path(atOutDir_) / "factoria_home").string(), "...installing into the autotest's own FACTORIA_HOME (" + st.home + ")");
        for (const SetupComponent& c : st.components)
            if (setup_action_for_component(c, st.home))
                at_check(at_visible("setup:install:" + c.id) && at_enabled("setup:install:" + c.id), "the " + c.id + " component has an Install button");
        at_check(at_visible("setup:install:android") && at_visible("setup:install:players"), "Android and players can always be installed");
        at_check(at_visible("setup:refresh"), "the window can check the computer again");
        at_check(!setupJob_.running() && !setupLast_, "nothing is installed until a button is pressed");
    });
    snap("editor_setup_window.png");
    step(2, [this] { showSetup_ = false; });

    // The Export window: the "Set up" button that fixes each row that is not ready.
    step(2, [this, inject_setup] {
        inject_setup();
        showExport_ = true;
        exportFocus_ = true;
    });
    step(4, [this, otherOs, ownOs, action_labels] {
        at_check(at_visible("setup:export:android:android"), "the Android row that cannot find a JDK and SDK has a Set up button");
        at_check(action_labels("android") == std::vector<std::string>{"Install Android build tools"}, "...Install Android build tools");
        const std::string os = otherOs == "macos" ? "macOS" : (otherOs == "windows" ? "Windows" : "Linux");
        at_check(at_visible("setup:export:" + otherOs + ":players-" + otherOs), "the row that needs another OS's player has a Set up button");
        at_check(action_labels(otherOs) == std::vector<std::string>{"Download " + os + " player"}, "...Download " + os + " player");
        at_check(at_visible("setup:export:ios:cmake") && at_visible("setup:export:ios:xcode"), "the iOS row, ready, still offers CMake and Xcode");
        at_check((action_labels("ios") == std::vector<std::string>{"Install CMake", "Open App Store (Xcode)"}), "...Install CMake and Open App Store (Xcode)");
        at_check(!at_visible("setup:export:" + ownOs + ":players-" + ownOs), "a row that is ready has no download button");
        at_check(at_enabled("setup:export:android:android") && at_enabled("setup:export:ios:cmake"), "the Set up buttons can be pressed");
    });
    snap("editor_setup_export.png");

    // Pressing one runs the setup in the editor (here it can only fail, the autotest has no network) and shows its report.
    scroll_until("setup:export:" + otherOs + ":players-" + otherOs, 6, Vec2{700, 400}, 500);
    click("setup:export:" + otherOs + ":players-" + otherOs);
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !setupJob_.running() && setupLast_.has_value(); };
    });
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return setupStatus_.has() && !setupStatus_.refreshing() && setupStatus_.status().host != "injected-autotest"; };
    });
    step(4, [this, otherOs] {
        at_check(showSetup_, "pressing a Set up button opens the Set Up window");
        at_check(setupLast_.has_value() && !setupLast_->ok && !setupLast_->cancelled,
                 "the setup ran (setup_install) and failed where the autotest cannot download: " + (setupLast_ ? setupLast_->error : std::string("no result")));
        at_check(setupLast_ && setupLast_->options.component == "players" && setupLast_->options.platforms == std::vector<std::string>{otherOs},
                 "...it was the player of that platform");
        at_check(setupStatus_.status().host != "injected-autotest", "when it finished the status was read again");
        bool rechecked = !exportStatus_.empty();
        for (const ExportStatus& st : exportStatus_) rechecked = rechecked && st.hint != "injected-autotest";
        at_check(rechecked, "...and so were the Export rows");
        at_check(at_visible("setup:copy-report"), "the window shows the report with Copy report");
    });
    snap("editor_setup_failed.png");
    step(2, [this] { showSetup_ = false; });

    // The license dialog, first with a license that cannot be loaded: the dialog says so and installs nothing.
    step(2, [this, inject_setup] {
        inject_setup();
        setupLicense_.reset();
        setupLast_.reset();
        showExport_ = true;
        exportFocus_ = true;
    });
    step(3, [] {});
    scroll_until("setup:export:android:android", -6, Vec2{700, 400}, 560);
    click("setup:export:android:android");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return setupLicense_.state() == SetupLicenseLoad::State::Failed; };
    });
    step(4, [this] {
        at_check(setupLicenseOpen_ && at_visible("setup:license-retry"), "Install Android build tools opens the license dialog first; a license that cannot be loaded offers Try again");
        at_check(!at_visible("setup:license-accept") || !at_enabled("setup:license-accept"), "...and cannot be accepted");
        at_check(!setupJob_.running(), "...and nothing is installed meanwhile");
    });
    snap("editor_setup_license_failed.png");
    click("setup:license-decline");
    step(4, [this] {
        at_check(!setupLicenseOpen_ && !setupJob_.running() && !setupLast_.has_value(), "Decline closes the dialog and installs nothing");
    });

    // With the text: shown in full, "I accept" waits for the checkbox.
    step(2, [this] {
        SetupLicense lic;
        lic.id = "android-sdk-license";
        lic.title = "Android Software Development Kit License Agreement";
        lic.text = "Terms and Conditions\n\n";
        for (int i = 1; i <= 24; ++i)
            lic.text += std::to_string(i) + ". This is paragraph " + std::to_string(i) + " of the test license. It is long enough to wrap onto a second "
                        "line in the box, so the box has to scroll to show all of the text before anyone agrees to it.\n\n";
        lic.text += "The end of the license.";
        setupLicense_.set(SetupLicenseLoad::State::Ready, {lic});
    });
    click("setup:export:android:android");
    step(4, [this] {
        at_check(setupLicenseOpen_ && at_visible("setup:license-text"), "the license dialog shows the license text in a box of its own");
        at_check(at_visible("setup:license-accept") && !at_enabled("setup:license-accept"), "I accept is disabled until the checkbox is ticked");
        at_check(at_enabled("setup:license-check") && !setupLicenseTick_, "...the checkbox is there, not ticked");
        at_check(at_visible("setup:license-decline"), "...next to Decline");
    });
    snap("editor_setup_license.png");
    click("setup:license-check");
    step(3, [this] {
        at_check(setupLicenseTick_, "ticking the checkbox...");
        at_check(at_enabled("setup:license-accept"), "...enables I accept");
        at_check(!setupJob_.running(), "...but nothing is installed until it is pressed");
    });
    snap("editor_setup_license_ticked.png");
    click("setup:license-check");
    step(3, [this] {
        at_check(!setupLicenseTick_ && !at_enabled("setup:license-accept"), "unticking the checkbox disables I accept again");
    });
    click("setup:license-decline");
    step(4, [this] {
        at_check(!setupLicenseOpen_ && !setupJob_.running() && !setupLast_.has_value(), "Decline closes the dialog and installs nothing");
        showExport_ = false;
    });

    // The Platform settings window: a button on General, and the tabs offer what their row needs.
    step(2, [this, inject_setup] {
        inject_setup();
        open_platform_settings(SettingsTab::General);
    });
    step(4, [this] { at_check(at_visible("setup:open-general"), "Platform settings > General has a Set Up This Computer... button"); });
    scroll_until("setup:open-general", -6, Vec2{512, 320}, 560);  // at the end of the tab: below the fold on a small display
    click("setup:open-general");
    step(4, [this, inject_setup] {
        at_check(showSetup_, "...that opens the Set Up window");
        showSetup_ = false;
        // Opening the window read this computer again (a Linux runner has CMake and no Xcode to offer): back to the injected
        // status, which drops that read if it is still running.
        inject_setup();
        open_platform_settings(SettingsTab::Android);
    });
    step(4, [this] { at_check(at_visible("setup:tab:android:android"), "the Android tab offers Install Android build tools next to the JDK and SDK status"); });
    step(2, [this, otherOs] { open_platform_settings(*settings_tab_for_platform(otherOs)); });
    step(4, [this, otherOs] {
        at_check(at_visible("setup:tab:" + otherOs + ":players-" + otherOs), "the " + otherOs + " tab offers to download its player");
        open_platform_settings(SettingsTab::Ios);
    });
    step(4, [this] {
        at_check(at_visible("setup:tab:ios:cmake") && at_visible("setup:tab:ios:xcode"), "the iOS tab offers CMake and Xcode");
    });
    snap("editor_setup_ios_tab.png");
    step(2, [this] {
        request_close_platform_settings();
        platformCloseAsk_ = false;
        showPlatformSettings_ = false;
        exportChecked_ = -100;
        setupRefreshAgain_ = true;  // what the windows show is read from this computer again
    });

    // --------------------------------------------------- K. A custom material: params, snippet reload, a broken snippet
    section("K");
    // The editor runs with hotReloadAssets: a material or snippet rewritten on disk (by the AI's file tools, or by hand) shows in
    // the viewport without a reload, in edit mode and while playing, and a broken edit keeps the last good picture and logs once.
    {
        auto ms = std::make_shared<MatShots>();
        const std::string snippet = project_file("shaders/autotest_glow.surface.glsl");
        // How much the viewport picture of two shots differs, in 0..255 per channel (the rest of the window, with the Console,
        // changes with every log line and says nothing about the viewport).
        auto vp_diff = [this](const Image& a, const Image& b) {
            if (a.rgba.size() != b.rgba.size() || a.rgba.empty()) return 1e9;
            const int x0 = int(vpImageMin_.x * dpi_), y0 = int(vpImageMin_.y * dpi_);
            const int x1 = std::min(a.width, x0 + int(vpImageSize_.x * dpi_)), y1 = std::min(a.height, y0 + int(vpImageSize_.y * dpi_));
            double sum = 0;
            long n = 0;
            for (int y = std::max(0, y0); y < y1; ++y)
                for (int x = std::max(0, x0); x < x1; ++x)
                    for (int c = 0; c < 3; ++c, ++n)
                        sum += std::abs(int(a.rgba[(size_t(y) * size_t(a.width) + size_t(x)) * 4 + size_t(c)]) -
                                        int(b.rgba[(size_t(y) * size_t(b.width) + size_t(x)) * 4 + size_t(c)]));
            return n ? sum / double(n) : 1e9;
        };
        // A viewport comparison: the same picture (`same`) or a changed one. The message carries the difference; on a failure
        // every shot of this section and the material's state are kept in the autotest's output (a CI artifact on macOS).
        auto diff_check = [this, ms, vp_diff](const Image& a, const Image& b, bool same, const std::string& what) {
            const double d = vp_diff(a, b);
            const bool ok = same ? d < 0.05 : d > 1.0;
            std::string detail = " (viewport difference " + std::to_string(d) + ")";
            if (!ok) {
                const std::pair<const char*, const Image*> shots[] = {{"base", &ms->base}, {"green", &ms->green}, {"undone", &ms->undone},
                    {"v2", &ms->v2}, {"broken", &ms->broken}, {"fixed", &ms->fixed}, {"playing", &ms->playing}};
                for (const auto& [name, img] : shots)
                    if (!img->rgba.empty()) (void)save_png(*img, atOutDir_ + "/material_" + name + ".png");
                detail += "; shots saved as material_*.png; materials: " + engine_->renderer()->asset_report()["materials"].dump();
            }
            at_check(ok, what + detail);
        };
        // The material's state in the renderer: its generation (+1 per build that worked) and its last error. A reload of the
        // snippet changes it, whether the new snippet compiles or not.
        auto material_state = [this] {
            const Json report = engine_->renderer()->asset_report();
            for (const Json& m : report["materials"])
                if (m.value("material", std::string()) == "materials/autotest_glow.material.json") return m;
            return Json();
        };
        // Rewrites a project file so its modification time is different from the last write, whatever the file system's resolution.
        auto rewrite = [ms, material_state](const std::string& path, const std::string& text) {
            ms->state = material_state();
            write_file(path, text);
            std::error_code ec;
            stdfs::last_write_time(path, stdfs::file_time_type::clock::now() + std::chrono::seconds(10 * ++ms->edits), ec);
        };
        // Waits until the renderer took the rewritten snippet, polling once a frame for at most 300 frames (a reload is the 0.25 s
        // poll plus a compile, slow on a software GPU), then 5 frames to draw it.
        struct Reloaded {
            Editor* ed;
            std::shared_ptr<MatShots> ms;
            std::function<Json()> state;
            int left;
            void operator()() const {
                if (ms->skip) return;
                if (state() != ms->state) ed->atSteps_.push_front(AtStep{5, [] {}});
                else if (left == 0) ed->at_check(false, "the renderer reloaded the rewritten snippet within 300 frames");
                else ed->atSteps_.push_front(AtStep{1, Reloaded{ed, ms, state, left - 1}});
            }
        };
        auto wait_reload = [this, ms, material_state, &step] { step(1, Reloaded{this, ms, material_state, 300}); };
        // A shot for vp_diff, like snap() without toasts: they fade on their own clock over the viewport (the "Reloaded" one of
        // the scene was in one shot and gone in the next on a slow runner).
        auto grab = [this, &step](Image MatShots::*which, std::shared_ptr<MatShots> shots) {
            step(3, [this] { toasts_.clear(); });
            step(3, [this, which, shots] {
                atPostFrame_.push_back([this, which, shots] { at_check(capture_window((*shots).*which), "captured the viewport"); });
            });
        };
        // Errors the AI would read: game.logs, from the seq noted before the edit.
        auto errors_naming = [this](std::uint64_t after) {
            const CommandResult r = engine_->commands().call("game.logs", Json::object({{"minLevel", "error"}, {"after", after}}));
            int n = 0;
            if (r.ok)
                for (const Json& l : r.result["logs"])
                    if (l["message"].get<std::string>().find("shaders/autotest_glow.surface.glsl:") != std::string::npos) ++n;
            return n;
        };

        step(2, [this, project_file] {
            stop();
            write_file(project_file("materials/autotest_glow.material.json"), kMatFile);
            write_file(project_file("shaders/autotest_glow.surface.glsl"), kMatSnippet);
            write_file(project_file(scenePath_), kMatScene);
            reload_scene_from_disk();
            select_id("");
            focus_window("###Viewport");
        });
        step(20, [] {});
        grab(&MatShots::base, ms);
        step(2, [this, ms] {
            const Renderer* r = engine_->renderer();
            ms->skip = !r || !r->stats().materialFallbacks.empty();
            // CI installs the compiler and sets FA_REQUIRE_SHDC=1 (docs/BUILDING.md): there a material that did not build fails.
            const char* required = std::getenv("FA_REQUIRE_SHDC");
            if (ms->skip && required && std::string(required) == "1") at_check(false, "the custom material builds (FA_REQUIRE_SHDC=1)");
            else if (ms->skip) atLog_.push_back("SKIP custom material section (the material did not build: no sokol-shdc? set SOKOL_SHDC)");
        });
        // (a) materialParams through a Console command, the way the AI edits; Undo brings the picture back.
        step(2, [this, ms] {
            if (ms->skip) return;
            run_console_line(R"(scene.set_component {"id":"gem","component":"MeshRenderer","fields":{"materialParams":{"glow":[0,1,0,1]}}})");
        });
        step(8, [] {});
        grab(&MatShots::green, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->base, ms->green, false, "a materialParams edit from the Console changes the viewport");
            undo();
        });
        step(8, [] {});
        grab(&MatShots::undone, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->base, ms->undone, true, "Undo brings the previous viewport picture back");
            ms->seq = log_last_seq();
        });
        // (b) the snippet rewritten on disk: the new picture shows after the poll, with no reload.
        step(2, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippetV2);
        });
        wait_reload();
        grab(&MatShots::v2, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->base, ms->v2, false, "a snippet rewritten on disk changes the viewport without a reload");
            at_check(engine_->renderer()->stats().materialFallbacks.empty(), "...and the material still builds");
            ms->seq = log_last_seq();
        });
        // (c) a broken snippet: the last good picture stays, one error names file:line, and the AI reads it from game.logs.
        step(2, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippetBroken);
        });
        wait_reload();
        grab(&MatShots::broken, ms);
        step(2, [this, ms, diff_check, errors_naming] {
            if (ms->skip) return;
            diff_check(ms->v2, ms->broken, true, "a broken snippet keeps the last good picture");
            at_check(errors_naming(ms->seq) == 1, "...and logs exactly one error with file:line (game.logs shows it to the AI)");
            at_check(engine_->renderer()->stats().materialFallbacks.empty(), "...without falling back to the error material");
            showOverlay_ = false;  // no selection outline in the pictures compared below
            select_id("gem");      // the Inspector shows the build error under MeshRenderer.material
        });
        step(1, [this, ms] {  // the Inspector reads the renderer's report twice a second: wait for it (bounded)
            atWaitCount_ = 0;
            atWaitUntil_ = [this, ms] { return ms->skip || at_visible("insp:material:error"); };
        });
        step(4, [this, ms] {
            if (ms->skip) return;
            at_check(at_visible("insp:material:error"), "the Inspector shows the material's build error under the material field");
            const std::string shown = material_build_error(assetReport_, "materials/autotest_glow.material.json");
            at_check(shown.find("autotest_glow.surface.glsl") != std::string::npos, "...naming the snippet file (" + shown.substr(0, 120) + ")");
        });
        snap("editor_inspector_material_error.png");
        step(2, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippetV2);
        });
        wait_reload();
        grab(&MatShots::fixed, ms);
        step(2, [ms, diff_check] {
            if (ms->skip) return;
            diff_check(ms->v2, ms->fixed, true, "fixing the snippet recovers the picture");
        });
        step(1, [this, ms] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, ms] { return ms->skip || !at_visible("insp:material:error"); };
        });
        step(4, [this, ms] {
            if (ms->skip) return;
            at_check(!at_visible("insp:material:error"), "the Inspector's build error is gone once the snippet builds again");
            select_id("");
            showOverlay_ = true;
        });
        // While playing: the same reload, without leaving Play.
        step(2, [this, ms] {
            if (ms->skip) return;
            play();
        });
        step(10, [ms, rewrite, snippet] {
            if (!ms->skip) rewrite(snippet, kMatSnippet);
        });
        wait_reload();
        grab(&MatShots::playing, ms);
        step(2, [this, ms, diff_check] {
            if (ms->skip) return;
            at_check(play_state() == PlayState::Playing, "the game is playing");
            diff_check(ms->v2, ms->playing, false, "a snippet rewritten on disk changes the viewport while the game plays");
            stop();
        });
    }

    // ------------------------------------------------------- L. Hand editing: the Hierarchy and the Inspector, with the mouse
    section("L");
    // The acceptance of M20's hand editing: select in the tree by clicking, click a number in the Inspector, type a value, Enter;
    // the world changed, one undo step was added, Save writes it into the scene file. Drag and drop in the tree reparents.
    {
        struct HandEdit {
            size_t undo = 0;
            Vec3 coinWorld{};
        };
        auto he = std::make_shared<HandEdit>();
        auto type_text = [this, &step](const std::string& text) {
            step(3, [this, text] {
                for (char c : text) inject_char(unsigned(static_cast<unsigned char>(c)));
            });
        };
        auto press_enter = [this, &step] {
            step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ENTER); });
            step(4, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ENTER); });
        };
        auto right_click = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
        };
        // Drag `from` over `to` and let go: ImGui's drag and drop needs the mouse to travel with the button held.
        auto drag = [this, &step](const std::string& from, const std::string& to) {
            auto start = std::make_shared<Vec2>();
            step(2, [this, from, start] {
                *start = at_widget(from);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, *start);
            });
            step(2, [this, start] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, *start); });
            step(2, [this, start] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{start->x + 6, start->y + 14}); });
            step(2, [this, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(to)); });
            step(3, [this, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(to)); });
            step(4, [this, to] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(to)); });
        };
        auto scene_file = [this, project_file] {
            auto loaded = load_json_file(project_file(scenePath_));
            return loaded ? *loaded : Json::object();
        };
        auto position_of = [this](const char* id) {
            Entity e = world().find_by_id(id);
            const Transform* t = e.is_null() ? nullptr : world().get<Transform>(e);
            return t ? t->position : Vec3{9999, 9999, 9999};
        };

        step(2, [this, project_file] {
            stop();
            select_id("");
            showHierarchy_ = showInspector_ = true;
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            focus_window("###Viewport");
        });
        step(10, [this] {
            at_check(at_visible("tree:coin_2") && at_visible("tree:player") && at_visible("tree:camera"), "the Hierarchy lists the scene's entities");
            at_check(!at_visible("insp:Transform.position.0"), "the Inspector shows nothing with no entity selected");
        });
        snap("editor_hierarchy_empty.png");

        // 1. Select in the tree: the Inspector shows the entity.
        click("tree:coin_2");
        step(4, [this] {
            at_check(selected_id() == "coin_2", "clicking an entity in the Hierarchy selects it");
            at_check(at_visible("insp:Transform.position.0") && at_visible("insp:Shape2D.thickness"), "the Inspector shows its components and fields");
            at_check(!at_enabled("insp:EntityInfo.id"), "a read-only field (the entity id) is disabled");
        });
        snap("editor_inspector.png");

        // 2. Click a number, type, Enter: the world changes with one undo step.
        step(2, [this, he] { he->undo = undo_depth(); });
        click("insp:Transform.position.0");
        step(4, [this] { at_check(ImGui::GetIO().WantTextInput, "clicking a number in the Inspector opens it for typing"); });
        type_text("300");
        press_enter();
        step(4, [this, he, position_of] {
            at_check(std::fabs(position_of("coin_2").x - 300.0f) < 0.01f && std::fabs(position_of("coin_2").y + 160.0f) < 0.01f,
                     "typing 300 and Enter sets Transform.position.x of the selected entity (y is kept)");
            at_check(undo_depth() == he->undo + 1 && dirty(), "...as ONE undo step, and the scene is dirty");
        });
        click("toolbar:save");
        step(4, [this, scene_file] {
            at_check(!dirty(), "Save clears the dirty flag");
            const Json scene = scene_file();
            const Json* coin = find_saved_entity(scene["entities"], "coin_2");
            at_check(coin && coin->contains("components") && (*coin)["components"]["Transform"]["position"][0] == 300,
                     "the scene file has the value typed in the Inspector");
        });
        click("toolbar:undo");
        step(4, [this, position_of] { at_check(std::fabs(position_of("coin_2").x - 250.0f) < 0.01f, "the Undo button takes the typed value back"); });

        // 3. A value the command refuses changes nothing, and its message shows under the field.
        step(2, [this, he] { he->undo = undo_depth(); });
        step(2, [this] { inspScrollTo_ = "Shape2D.thickness"; });  // a small window shows only the top of the Inspector
        step(3, [] {});
        click("insp:Shape2D.thickness");
        type_text("-5");
        press_enter();
        step(4, [this, he] {
            Entity c = world().find_by_id("coin_2");
            at_check(world().get<Shape2D>(c)->thickness >= 0.0f, "a value outside the field's range is refused: nothing changed");
            at_check(undo_depth() == he->undo, "...and the refused edit left no undo step");
            auto it = inspErrors_.find("Shape2D.thickness");
            at_check(it != inspErrors_.end() && it->second.find("thickness") != std::string::npos,
                     "...and the Inspector keeps the command's message for the field");
        });
        snap("editor_inspector_error.png");

        // 4. Add and remove a component.
        click("insp:add");
        step(3, [this] { at_check(at_visible("insp:add:Sprite"), "the Add Component list offers the components the entity lacks"); });
        click("insp:add:Sprite");
        step(2, [this] { inspScrollTo_ = "Sprite"; });
        step(3, [] {});
        step(4, [this] {
            at_check(world().has<Sprite>(world().find_by_id("coin_2")), "choosing a component in the list adds it with its defaults");
            at_check(at_visible("insp:hdr:Sprite"), "...and the Inspector shows its header");
        });
        click("insp:hdr:Sprite:x");
        step(4, [this] { at_check(!world().has<Sprite>(world().find_by_id("coin_2")), "the x on a component's header removes it"); });

        // 5. Reparent by drag and drop.
        step(2, [this] { toasts_.clear(); });
        step(2, [this, he, position_of] {
            he->undo = undo_depth();
            he->coinWorld = world().world_position(world().find_by_id("coin_3"));
        });
        drag("tree:coin_3", "tree:platform_1");
        step(4, [this, he] {
            World& w = world();
            at_check(w.parent(w.find_by_id("coin_3")) == w.find_by_id("platform_1"), "dragging an entity onto another in the Hierarchy makes it a child");
            at_check(undo_depth() == he->undo + 1, "...as one undo step");
            const Vec3 now = w.world_position(w.find_by_id("coin_3"));
            at_check(std::fabs(now.x - he->coinWorld.x) < 0.01f && std::fabs(now.y - he->coinWorld.y) < 0.01f,
                     "...and the entity stays where it was on screen");
        });
        click("toolbar:save");
        step(4, [this, scene_file] {
            const Json scene = scene_file();
            const Json* plat = find_saved_entity(scene["entities"], "platform_1");
            bool nested = false;
            if (plat && plat->contains("children"))
                for (const Json& c : (*plat)["children"]) nested = nested || c.value("id", std::string()) == "coin_3";
            bool topLevel = false;
            for (const Json& e : scene["entities"]) topLevel = topLevel || e.value("id", std::string()) == "coin_3";
            at_check(nested && !topLevel, "the scene file has the entity under its new parent");
        });
        snap("editor_hierarchy_children.png");
        drag("tree:coin_3", "tree:empty");
        step(4, [this] {
            World& w = world();
            at_check(w.parent(w.find_by_id("coin_3")).is_null(), "dropping an entity on the empty space of the Hierarchy moves it to the top level");
        });

        // 6. The context menu: create a child, rename, toggle active, delete.
        right_click("tree:coin_1");
        step(3, [this] { at_check(at_visible("tree:ctx:child") && at_visible("tree:ctx:delete"), "right-clicking an entity opens its context menu"); });
        click("tree:ctx:child");
        step(4, [this] {
            World& w = world();
            const Entity coin = w.find_by_id("coin_1");
            at_check(w.children(coin).size() == 1, "Create empty child adds an entity under it");
            at_check(!selected().is_null() && w.parent(selected()) == coin, "...and selects the new entity");
        });
        right_click("tree:coin_1");
        step(3, [] {});
        click("tree:ctx:rename");
        step(4, [this] { at_check(at_visible("tree:rename:text"), "Rename opens a box for the name"); });
        type_text("Gold");
        press_enter();
        step(4, [this] { at_check(world().info(world().find_by_id("coin_1")).name == "Gold", "typing a name and Enter renames the entity"); });
        right_click("tree:coin_1");
        step(3, [] {});
        click("tree:ctx:active");
        step(4, [this] { at_check(!world().info(world().find_by_id("coin_1")).active, "the Active item of the context menu deactivates the entity"); });
        snap("editor_hierarchy.png");
        right_click("tree:coin_3");
        step(3, [] {});
        click("tree:ctx:delete");
        step(4, [this] { at_check(world().find_by_id("coin_3").is_null(), "Delete removes the entity"); });
        click("toolbar:undo");
        step(4, [this] { at_check(!world().find_by_id("coin_3").is_null(), "Undo brings the deleted entity back"); });

        // 7. While the game plays an edit changes the running game, and Stop takes it back.
        step(2, [this, he] {
            he->undo = undo_depth();
            play();
        });
        step(6, [this] { select_id("player"); });
        step(6, [this] { at_check(at_visible("insp:Transform.position.0"), "the Inspector works while the game runs"); });
        click("insp:Transform.position.0");
        type_text("-111");
        press_enter();
        step(4, [this, he, position_of] {
            at_check(std::fabs(position_of("player").x + 111.0f) < 0.5f, "an edit while playing changes the running game");
            at_check(undo_depth() == he->undo, "...and adds no undo step (Stop discards it)");
        });
        snap("editor_inspector_play.png");
        step(2, [this] { stop(); });
        step(4, [this, position_of] { at_check(std::fabs(position_of("player").x + 300.0f) < 0.01f, "Stop takes the edit made while playing back"); });

        // 8. A material: its params typed by material.info, edited with the same commands.
        step(2, [this, project_file, he] {
            write_file(project_file("materials/autotest_inspect.material.json"), kInspectMatFile);
            write_file(project_file("shaders/autotest_glow.surface.glsl"), kMatSnippet);
            write_file(project_file(scenePath_), kInspectScene);
            reload_scene_from_disk();
            select_id("gem");
            he->undo = undo_depth();
        });
        step(30, [this] {
            at_check(at_visible("insp:matparam:pulse") && at_visible("insp:matparam:glow") && at_visible("insp:matparam:tint"),
                     "the Inspector lists the params of MeshRenderer.material, typed by material.info");
            at_check(!at_enabled("insp:matreset:pulse"), "...a param with no override cannot be reset");
        });
        // Scrolled once the material's build report is in: an error under the material field (no shader compiler on this
        // machine) pushes the params down, out of a small window's Inspector.
        step(2, [this] { inspScrollTo_ = "MeshRenderer.materialParams"; });
        step(3, [] {});
        click("insp:matparam:pulse");
        type_text("2.5");
        press_enter();
        step(4, [this, he] {
            const Json params = component_to_json(world(), world().find_by_id("gem"), *TypeRegistry::global().find("MeshRenderer"), true, false)["materialParams"];
            at_check(params.is_object() && params.value("pulse", 0.0) == 2.5, "typing a value for a material param writes it into materialParams");
            at_check(undo_depth() == he->undo + 1, "...as one undo step");
            at_check(at_enabled("insp:matreset:pulse"), "...and the param can now be reset");
        });
        click("insp:matparam:pulse");
        type_text("9");
        press_enter();
        step(4, [this] {
            const Json params = component_to_json(world(), world().find_by_id("gem"), *TypeRegistry::global().find("MeshRenderer"), true, false)["materialParams"];
            at_check(params.value("pulse", 0.0) == 4.0, "a value above the param's max is held to it (max 4)");
        });
        snap("editor_inspector_material.png");
        click("insp:matreset:pulse");
        step(4, [this] {
            const Json params = component_to_json(world(), world().find_by_id("gem"), *TypeRegistry::global().find("MeshRenderer"), true, false)["materialParams"];
            at_check(!params.contains("pulse"), "Reset removes the override: the material's default applies again");
            select_id("");
            reload_scene_from_disk();
        });
    }

    // ------------------------------------------------------------------- M. Transform gizmos: move, rotate, scale in the viewport
    section("M");
    // The acceptance of the gizmos: select the player, press W / E / R, drag handles with the injected mouse. Every drag is one
    // undo step and a scene.set_component on Transform; Ctrl snaps; a child of a rotated, scaled parent follows the mouse in
    // world space; Esc puts the start value back with no undo step; Q hides the handles; none while Playing, but Paused edits the
    // running game; Save writes the values into the scene file.
    {
        struct Gz {
            Vec2 grab{}, cur{};
            Vec3 pos{}, rot{}, scl{};
            size_t undo = 0;
            double restUntil = 0;
        };
        auto g = std::make_shared<Gz>();
        auto tf = [this](const char* id) {
            Entity e = world().find_by_id(id);
            const Transform* t = e.is_null() ? nullptr : world().get<Transform>(e);
            return t ? *t : Transform{};
        };
        // Panel pixels per design pixel (= world unit with the fixture's camera).
        auto sc = [this] { return vpImageSize_.x / float(engine_->renderer()->target_width()); };
        auto sc_y = [this] { return vpImageSize_.y / float(engine_->renderer()->target_height()); };  // the image size is floored: not quite the same
        auto panel_of_player = [this] {
            const Vec2 d = engine_->renderer()->world_to_screen(world().world_position(world().find_by_id("player")));
            return Vec2{vpImageMin_.x + d.x / float(engine_->renderer()->target_width()) * vpImageSize_.x,
                        vpImageMin_.y + d.y / float(engine_->renderer()->target_height()) * vpImageSize_.y};
        };
        auto press = [this, &step](int keyCode) {
            step(3, [this, keyCode] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, keyCode); });
            step(3, [this, keyCode] { inject_key(SAPP_EVENTTYPE_KEY_UP, keyCode); });
        };
        auto ctrl = [this, &step](bool down) {
            step(2, [this, down] {
#if defined(__APPLE__)
                // Dear ImGui swaps Cmd and Ctrl on macOS (io.KeyCtrl is Cmd): the key a Mac user holds to snap is Cmd.
                atMods_ = down ? SAPP_MODIFIER_SUPER : 0;
                inject_key(down ? SAPP_EVENTTYPE_KEY_DOWN : SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_SUPER);
#else
                atMods_ = down ? SAPP_MODIFIER_CTRL : 0;
                inject_key(down ? SAPP_EVENTTYPE_KEY_DOWN : SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_CONTROL);
#endif
            });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // Grab a handle (at the point the layout says it can be grabbed), move the mouse to `target()` in one go, let go.
        auto grab = [this, &step, &wait_until, g](const std::string& handle) {
            step(2, [this, g, handle] {
                g->grab = g->cur = at_widget("gizmo:" + handle);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, g->grab);
            });
            step(2, [this, g] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, g->grab); });
            wait_until([this] { return gizmoDrag_.active; });
        };
        auto move_to = [this, &step, &wait_until, g](std::function<Vec2()> target) {
            step(2, [this, g, target] {
                g->cur = target();
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, g->cur);
            });
            wait_until([this] { return gizmoDrag_.wrote; });
            step(3, [] {});
        };
        auto release = [this, &step, &wait_until, g] {
            step(2, [this, g] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, g->cur); });
            wait_until([this] { return !gizmoDrag_.active; });
            step(3, [] {});
        };
        auto drag_by = [&grab, &move_to, &release, g](const std::string& handle, float dx, float dy) {
            grab(handle);
            move_to([g, dx, dy] { return Vec2{g->grab.x + dx, g->grab.y + dy}; });
            release();
        };
        // A ring drag: from where the ring was grabbed (45 degrees up-right of the entity) to `degrees` of screen angle.
        auto ring_to = [&move_to, g, panel_of_player](float degrees) {
            move_to([g, panel_of_player, degrees] {
                const Vec2 c = panel_of_player();
                const float r = std::hypot(g->grab.x - c.x, g->grab.y - c.y);
                return Vec2{c.x + r * std::cos(degrees * kDegToRad), c.y + r * std::sin(degrees * kDegToRad)};
            });
        };
        auto remember = [this, g, tf] {
            const Transform t = tf("player");
            g->pos = t.position;
            g->rot = t.rotation;
            g->scl = t.scale;
            g->undo = undo_depth();
        };

        step(2, [this, project_file] {
            stop();
            select_id("player");
            gizmoMode_ = GizmoMode::Select;
            showHierarchy_ = showInspector_ = true;
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            select_id("player");
            focus_window("###Viewport");
        });
        // The mouse over the viewport (keys reach it while hovered or focused).
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f}); });
        step(4, [this] { at_check(!at_visible("gizmo:move:x"), "Select mode shows no gizmo"); });
        click("toolbar:gizmo:move");
        step(4, [this] {
            at_check(gizmoMode_ == GizmoMode::Move, "the toolbar's Move button switches to the move gizmo");
            at_check(at_visible("gizmo:move:x") && at_visible("gizmo:move:y") && at_visible("gizmo:move:plane"),
                     "Move shows an arrow per axis and the free-move square on the selected entity");
            at_check(!at_visible("gizmo:move:z"), "...with no Z arrow under a 2D camera");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f});
        });
        press(SAPP_KEYCODE_Q);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Select && !at_visible("gizmo:move:x"), "Q switches to Select: the gizmo disappears"); });
        press(SAPP_KEYCODE_W);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Move && at_visible("gizmo:move:x"), "W switches to Move: the gizmo is back"); });
        snap("editor_gizmo_move.png");

        // Move: the X arrow. The world moved by what the mouse covered (px / panel scale) and y did not.
        step(2, remember);
        drag_by("move:x", 60, 25);
        step(2, [this, g, tf, sc] {
            const Transform t = tf("player");
            at_check(std::fabs(t.position.x - (g->pos.x + 60.0f / sc())) < 0.05f, "dragging the X arrow moves position.x by the world distance the mouse covered");
            at_check(t.position.y == g->pos.y && t.position.z == g->pos.z, "...and position.y / z did not change (the drag followed the axis)");
            at_check(undo_depth() == g->undo + 1, "the whole drag is ONE undo step");
            at_check(dirty_, "...and marks the scene dirty");
            undo();
            at_check(tf("player").position.x == g->pos.x, "Undo puts the position back");
        });
        // Move: the free square (the XY plane in 2D; y is down on screen, up in the world).
        step(2, remember);
        drag_by("move:plane", 30, 20);
        step(2, [this, g, tf, sc, sc_y] {
            const Transform t = tf("player");
            at_check(std::fabs(t.position.x - (g->pos.x + 30.0f / sc())) < 0.05f && std::fabs(t.position.y - (g->pos.y - 20.0f / sc_y())) < 0.05f,
                     "dragging the centre square moves the entity in both axes under the mouse");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });

        // Rotate: a ring around Z. From 45 degrees on the ring to 0: a clockwise 45 on screen is -45 about Z (y is up).
        press(SAPP_KEYCODE_E);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Rotate && at_visible("gizmo:rotate:z") && !at_visible("gizmo:rotate:x"), "E shows one rotation ring in 2D"); });
        snap("editor_gizmo_rotate.png");
        step(2, remember);
        grab("rotate:z");
        ring_to(0.0f);
        release();
        step(2, [this, g, tf] {
            const Transform t = tf("player");
            at_check(std::fabs(t.rotation.z + 45.0f) < 2.0f, "dragging the ring turns rotation.z with the mouse's angle around the entity (" + std::to_string(t.rotation.z) + ")");
            at_check(t.rotation.x == 0 && t.rotation.y == 0 && t.position.x == g->pos.x && t.scale.x == g->scl.x, "...and nothing else changes");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });
        // Past 180 degrees the ring keeps turning: -45 to 135 on screen is +180 about the mouse, and the next half turn goes on.
        step(2, remember);
        grab("rotate:z");
        ring_to(-45.0f - 120.0f);
        ring_to(-45.0f - 240.0f);
        release();
        step(2, [this, tf] {
            const float z = tf("player").rotation.z;
            at_check(std::fabs(z - 240.0f) < 3.0f, "a drag that goes more than half a turn keeps turning (rotation.z " + std::to_string(z) + ", wanted 240)");
            undo();
        });

        // Scale: the X handle's box grows the entity along its own X only.
        press(SAPP_KEYCODE_R);
        step(3, [this] { at_check(gizmoMode_ == GizmoMode::Scale && at_visible("gizmo:scale:x") && at_visible("gizmo:scale:all"), "R shows scale handles and the uniform box"); });
        snap("editor_gizmo_scale.png");
        step(2, remember);
        drag_by("scale:x", 40, 0);
        step(2, [this, g, tf] {
            const Transform t = tf("player");
            at_check(std::fabs(t.scale.x - 1.5f) < 0.02f && t.scale.y == g->scl.y && t.scale.z == g->scl.z, "dragging the X handle scales x only (1 -> " + std::to_string(t.scale.x) + ")");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });
        // A drag back through the pivot never reaches 0 or flips the sign.
        step(2, remember);
        drag_by("scale:x", -400, 0);
        step(2, [this, tf] {
            const Transform t = tf("player");
            at_check(t.scale.x > 0.0f && t.scale.x < 0.05f, "dragging a scale handle past the pivot holds a small positive value (" + std::to_string(t.scale.x) + ")");
            undo();
        });

        // Ctrl snaps the value: whole units (2D) for move, 15 degrees for rotate, 0.1 for scale. (Keys are ignored while Ctrl is held.)
        press(SAPP_KEYCODE_W);
        ctrl(true);
        drag_by("move:x", 33.3f, 0);
        step(2, [this, tf] {
            const float x = tf("player").position.x;
            at_check(std::fabs(x - std::round(x)) < 1e-3f, "Ctrl while dragging an arrow snaps the position to whole units (" + std::to_string(x) + ")");
            undo();
        });
        ctrl(false);
        press(SAPP_KEYCODE_E);
        ctrl(true);
        grab("rotate:z");
        ring_to(-45.0f + 100.0f);
        release();
        step(2, [this, tf] {
            const float z = tf("player").rotation.z;
            at_check(std::fabs(z) > 1.0f && std::fabs(z / 15.0f - std::round(z / 15.0f)) < 1e-3f, "Ctrl while dragging a ring snaps the rotation to 15 degrees (" + std::to_string(z) + ")");
            undo();
        });
        ctrl(false);
        press(SAPP_KEYCODE_R);
        ctrl(true);
        drag_by("scale:x", 37, 0);
        step(2, [this, tf] {
            const float s = tf("player").scale.x;
            at_check(s > 1.0f && std::fabs(s * 10.0f - std::round(s * 10.0f)) < 1e-2f, "Ctrl while dragging a scale handle snaps it to 0.1 (" + std::to_string(s) + ")");
            undo();
        });
        ctrl(false);
        press(SAPP_KEYCODE_W);

        // A child of a rotated and scaled parent ends where the mouse put it in world space (the value written is local).
        step(2, [this, g] {
            run_console_line(R"(scene.set_component {"id":"platform_1","component":"Transform","fields":{"rotation":[0,0,30],"scale":[1.5,1,1]}})");
            run_console_line(R"(scene.set_parent {"id":"coin_1","parent":"platform_1"})");
            select_id("coin_1");
            g->undo = undo_depth();
            g->pos = world().world_position(world().find_by_id("coin_1"));
        });
        step(4, [this] { at_check(!world().parent(world().find_by_id("coin_1")).is_null() && at_visible("gizmo:move:x"), "the child has the gizmo too"); });
        drag_by("move:x", 50, 0);
        step(2, [this, g, sc] {
            const Vec3 now = world().world_position(world().find_by_id("coin_1"));
            at_check(std::fabs(now.x - (g->pos.x + 50.0f / sc())) < 0.1f && std::fabs(now.y - g->pos.y) < 0.1f,
                     "a child of a rotated, scaled parent moves by the mouse's world distance (the local value written differs from it)");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            select_id("player");
        });

        // Esc in the middle of a drag: the start value is back and no undo step is left behind. The mouse rests longer than the
        // 0.8 s that merges edits into one undo step before it moves on: still one step, which Esc takes back.
        step(4, remember);
        grab("move:x");
        move_to([g] { return Vec2{g->grab.x + 45, g->grab.y}; });
        step(1, [this, g] { g->restUntil = time_ + 1.0; });
        wait_until([this, g] { return time_ > g->restUntil; });
        step(2, [this, g] { gizmoDrag_.wrote = false; });
        move_to([g] { return Vec2{g->grab.x + 70, g->grab.y}; });
        step(2, [this, g, tf] {
            at_check(tf("player").position.x != g->pos.x, "mid-drag the entity has moved");
            at_check(undo_depth() == g->undo + 1, "a drag that rests mid-way is still one undo step");
            inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ESCAPE);
        });
        step(4, [this, g, tf] {
            inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ESCAPE);
            at_check(tf("player").position.x == g->pos.x, "Esc while dragging puts the start value back");
            at_check(undo_depth() == g->undo && !gizmoDrag_.active, "...and leaves no undo step, ending the drag");
        });
        release();
        step(2, [this, g, tf] { at_check(tf("player").position.x == g->pos.x, "letting go after Esc changes nothing"); });

        // Playing: the input goes to the game, so no handles. Paused: they edit the running game, with no undo step, lost on Stop.
        step(2, [this, remember] {
            remember();
            play();
        });
        wait_until([this] { return play_ == PlayState::Playing && !at_visible("gizmo:move:x"); });
        step(3, [this] {
            at_check(!at_visible("gizmo:move:x"), "no gizmo while the game plays");
            pause();
        });
        step(6, [this] { at_check(play_ == PlayState::Paused && at_visible("gizmo:move:x"), "paused: the gizmo is back"); });
        drag_by("move:x", 40, 0);
        step(2, [this, g, tf, sc] {
            at_check(std::fabs(tf("player").position.x - (g->pos.x + 40.0f / sc())) < 0.05f, "a drag while paused edits the running game");
            at_check(undo_depth() == g->undo, "...with no undo step (Stop discards it)");
            stop();
        });
        step(6, [this, g, tf] { at_check(tf("player").position.x == g->pos.x, "Stop takes the edit made while paused back"); });

        // Save: the scene file holds what the gizmo wrote.
        step(2, remember);
        drag_by("move:x", 80, 0);
        step(2, [this, tf, project_file] {
            at_check(save_scene_now(), "Save works after gizmo edits");
            auto loaded = load_json_file(project_file(scenePath_));
            const Json* saved = loaded ? find_saved_entity((*loaded)["entities"], "player") : nullptr;
            const Json pos = saved ? (*saved)["components"]["Transform"]["position"] : Json();
            at_check(pos.is_array() && pos.size() >= 1 && std::fabs(pos[0].get<float>() - tf("player").position.x) < 1e-3f,
                     "the scene file holds the position the gizmo set");
            at_check(!dirty_, "...and the scene is clean after saving");
        });
        step(2, [this, project_file] {  // back to the fixture the next sections expect
            gizmoMode_ = GizmoMode::Move;
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            select_id("");
        });

        // ---- M2. The same gizmos with a perspective camera (3D) and on a screen-space (HUD) entity.
        auto piv = std::make_shared<Vec2>();
        auto shape_of = [this](GizmoHandle h) -> const GizmoShape* {
            for (const GizmoShape& s : gizmoShapes_)
                if (s.handle == h) return &s;
            return nullptr;
        };
        // A point on a ring where the hit test gives THIS ring (rings of a 3D gizmo cross each other).
        auto ring_point = [this, shape_of](GizmoHandle h) {
            const GizmoShape* s = shape_of(h);
            if (s)
                for (size_t i = 0; i < s->ring.size(); ++i) {
                    const Vec2 v = s->ring[(i + 8) % s->ring.size()];
                    if (gizmo_hit(gizmoShapes_, v, 7.0f) == h) return v;
                }
            at_check(false, "a point of the " + gizmo_handle_name(h) + " ring that only it can be grabbed by");
            return Vec2{-100, -100};
        };
        auto grab_pt = [this, &step, &wait_until, g, piv, shape_of](GizmoHandle h, std::function<Vec2()> where) {
            step(2, [this, g, piv, shape_of, h, where] {
                g->grab = g->cur = where();
                if (const GizmoShape* s = shape_of(h)) *piv = s->centre;
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, g->grab);
            });
            step(2, [this, g] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, g->grab); });
            wait_until([this] { return gizmoDrag_.active; });
        };
        auto over_viewport = [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f}); };
        auto start_scene = [this, project_file](const char* json, const char* id, int mode) {
            write_file(project_file(scenePath_), json);
            reload_scene_from_disk();
            select_id(id);
            gizmoMode_ = GizmoMode(mode);
            focus_window("###Viewport");
        };
        // Rotation matrices before and after: `after` is `before` turned about its own local axis `axis` (by some angle).
        auto turned_about_local = [](Vec3 before, Vec3 after, int axis) {
            const Mat4 rel = Mat4::rotate_euler_deg(before).transposed() * Mat4::rotate_euler_deg(after);
            const bool fixed = std::fabs(rel.at(axis, axis) - 1.0f) < 1e-3f;
            const int other = (axis + 1) % 3;
            return fixed && rel.at(other, other) < 0.9998f;
        };
        auto vec3_str = [](Vec3 v) { return "(" + std::to_string(v.x) + ", " + std::to_string(v.y) + ", " + std::to_string(v.z) + ")"; };

        step(2, [start_scene] { start_scene(kGizmo3dScene, "gem", int(GizmoMode::Move)); });
        step(6, over_viewport);
        step(4, [this] { at_check(at_visible("gizmo:move:x") && at_visible("gizmo:move:y"), "3D: the move gizmo shows on the cube"); });
        snap("editor_gizmo_move_3d.png");
        step(2, [this, g, tf] {
            const Transform t = tf("gem");
            g->pos = t.position;
            g->rot = t.rotation;
            g->scl = t.scale;
            g->undo = undo_depth();
        });
        drag_by("move:x", 40, 15);
        step(2, [this, g, tf, vec3_str] {
            const Transform t = tf("gem");
            at_check(t.position.x > g->pos.x + 0.05f && t.position.y == g->pos.y && t.position.z == g->pos.z,
                     "3D: dragging the X arrow grows position.x and leaves y and z alone " + vec3_str(t.position));
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            undo();
        });

        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_E); });
        step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_E); });
        step(3, [this] { at_check(at_visible("gizmo:rotate:x") && at_visible("gizmo:rotate:y") && at_visible("gizmo:rotate:z"), "3D: the rotate gizmo has three rings"); });
        snap("editor_gizmo_rotate_3d.png");
        for (int axis = 0; axis < 2; ++axis) {  // the local x ring, then the local y ring
            const GizmoHandle h{GizmoKind::RotateAxis, axis};
            step(2, [this, g, tf] {
                const Transform t = tf("gem");
                g->rot = t.rotation;
                g->scl = t.scale;
                g->undo = undo_depth();
            });
            grab_pt(h, [ring_point, h] { return ring_point(h); });
            move_to([g, piv] {  // 40 degrees around the projected pivot
                const float a = 40.0f * kDegToRad, dx = g->grab.x - piv->x, dy = g->grab.y - piv->y;
                return Vec2{piv->x + dx * std::cos(a) - dy * std::sin(a), piv->y + dx * std::sin(a) + dy * std::cos(a)};
            });
            release();
            step(2, [this, g, tf, axis, turned_about_local, vec3_str] {
                const Transform t = tf("gem");
                at_check(turned_about_local(g->rot, t.rotation, axis),
                         std::string("3D: dragging the local ") + (axis == 0 ? "x" : "y") + " ring turns the cube about that local axis, as the euler round trip says " + vec3_str(g->rot) + " -> " + vec3_str(t.rotation));
                at_check(t.scale.x == g->scl.x && undo_depth() == g->undo + 1, "...one undo step, scale untouched");
                undo();
            });
        }

        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_R); });
        step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_R); });
        step(3, [this] { at_check(at_visible("gizmo:scale:x") && at_visible("gizmo:scale:y"), "3D: the scale gizmo shows"); });
        step(2, [this, g, tf] {
            g->scl = tf("gem").scale;
            g->undo = undo_depth();
        });
        grab_pt(GizmoHandle{GizmoKind::ScaleAxis, 1}, [this] { return at_widget("gizmo:scale:y"); });
        move_to([g, piv] {  // 30 px further out along the handle
            const float dx = g->grab.x - piv->x, dy = g->grab.y - piv->y, l = std::max(1.0f, std::hypot(dx, dy));
            return Vec2{g->grab.x + dx / l * 30.0f, g->grab.y + dy / l * 30.0f};
        });
        release();
        step(2, [this, g, tf, vec3_str] {
            const Transform t = tf("gem");
            at_check(t.scale.y > g->scl.y * 1.1f && t.scale.x == g->scl.x && t.scale.z == g->scl.z,
                     "3D: dragging the local Y scale handle changes scale.y only " + vec3_str(t.scale));
            undo();
        });

        // HUD: a screen-space shape. Its Transform is in design pixels, y down: the gizmo's Y arrow points down the screen.
        step(2, [start_scene] { start_scene(kGizmoHudScene, "hud", int(GizmoMode::Move)); });
        step(6, over_viewport);
        step(4, [this, shape_of] {
            at_check(at_visible("gizmo:move:x") && at_visible("gizmo:move:plane"), "HUD: a screen-space entity gets the move gizmo");
            const GizmoShape* y = shape_of(GizmoHandle{GizmoKind::MoveAxis, 1});
            at_check(y && y->dir.y > 0.9f, "HUD: the Y arrow points down the screen (design y grows downwards)");
        });
        snap("editor_gizmo_hud.png");
        step(2, [this, g, tf] {
            g->pos = tf("hud").position;
            g->undo = undo_depth();
        });
        drag_by("move:plane", 30, 20);
        step(2, [this, g, tf, sc, sc_y] {
            const Transform t = tf("hud");
            at_check(std::fabs(t.position.x - (g->pos.x + 30.0f / sc())) < 0.1f && std::fabs(t.position.y - (g->pos.y + 20.0f / sc_y())) < 0.1f,
                     "HUD: the centre square moves it by the design pixels the mouse covered (right and DOWN are positive)");
            at_check(undo_depth() == g->undo + 1, "...as one undo step");
            g->pos = t.position;
            g->undo = undo_depth();
        });
        drag_by("move:y", 12, 30);
        step(2, [this, g, tf, sc_y] {
            const Transform t = tf("hud");
            at_check(std::fabs(t.position.y - (g->pos.y + 30.0f / sc_y())) < 0.1f && t.position.x == g->pos.x,
                     "HUD: the Y arrow moves it down by the design pixels covered, x unchanged");
            undo();
            undo();
        });
    }

    // ------------------------------------------------------------------------------------------ N. Project panel (View > Project)
    section("N");
    // The acceptance of the file browser: the panel lists the project's files, the type filter and the search narrow the list, a
    // prefab dragged onto the Viewport spawns an entity at the point under the mouse (one undo step, Ctrl+Z removes it), a picture
    // dragged onto a Sprite's texture field sets the field (and a sound dragged there does nothing), Delete goes through fs.delete,
    // and the listing is read from the disk only on a refresh, not per frame.
    {
        struct Browse {
            Vec2 from{}, to{};
            size_t undo = 0, entities = 0;
            int scans = 0;
            Vec3 expected{};
        };
        auto bz = std::make_shared<Browse>();
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto right_click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // Drag a tile (or any tracked widget) to a point: the mouse travels with the button held, as ImGui's drag and drop needs.
        auto drag_to = [this, &step, bz](const std::string& from, std::function<Vec2()> target) {
            step(2, [this, from, bz] {
                bz->from = at_widget(from);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, bz->from);
            });
            step(2, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, bz->from); });
            step(2, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{bz->from.x + 6, bz->from.y + 14}); });
            step(2, [this, bz, target] {
                bz->to = target();
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, bz->to);
            });
            step(3, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, bz->to); });
            step(4, [this, bz] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, bz->to); });
        };
        auto type_text = [this, &step](const std::string& text) {
            step(3, [this, text] {
                for (char c : text) inject_char(unsigned(static_cast<unsigned char>(c)));
            });
        };
        auto ctrl_z = [this, &step] {
            step(2, [this] {
#if defined(__APPLE__)
                atMods_ = SAPP_MODIFIER_SUPER;  // Dear ImGui swaps Cmd and Ctrl on macOS
                inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_LEFT_SUPER);
#else
                atMods_ = SAPP_MODIFIER_CTRL;
                inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_LEFT_CONTROL);
#endif
            });
            step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_Z); });
            step(3, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_Z); });
            step(2, [this] {
#if defined(__APPLE__)
                inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_SUPER);
#else
                inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_LEFT_CONTROL);
#endif
                atMods_ = 0;
            });
        };
        // A search that leaves one tile: it is the first, so it is on screen even in a small window.
        auto search_for = [this, &step, &click_widget, &type_text](const std::string& text) {
            step(2, [this] { projBrowser_.query.search.clear(); });
            click_widget("proj:search");
            type_text(text);
            step(4, [] {});
        };
        const std::string tile_prefab = "proj:file:prefabs/autotest_drop.prefab.json";
        const std::string tile_png = "proj:file:assets/autotest_drop.png";

        step(2, [this, project_file, bz] {
            stop();
            select_id("");
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            Image img;
            img.width = img.height = 16;
            img.rgba.assign(16 * 16 * 4, 255);
            for (size_t i = 0; i < img.rgba.size(); i += 4) { img.rgba[i + 1] = 90; img.rgba[i + 2] = 40; }
            at_check(save_png(img, project_file("assets/autotest_drop.png")).ok(), "a picture was written for the Project panel test");
            write_file(project_file("assets/autotest_trash.txt"), "delete me");
            // The prefab comes from the open scene's coin, through the command the AI uses.
            std::string err;
            CommandResult r = edit_command("at:prefab", "prefab.save",
                                           Json::object({{"id", "coin_1"}, {"path", "prefabs/autotest_drop.prefab.json"}, {"overwrite", true}}), &err);
            at_check(r.ok, "prefab.save made a prefab for the Project panel test: " + err);
            r = edit_command("at:sprite", "scene.spawn",
                             Json::object({{"id", "dropsprite"}, {"name", "Drop Sprite"},
                                           {"components", Json::object({{"Transform", Json::object({{"position", Json::array({300, 250, 0})}})},
                                                                        {"Sprite", Json::object()}})}}),
                             &err);
            at_check(r.ok, "an entity with a Sprite was spawned: " + err);
            bz->undo = undo_depth();
            showProject_ = true;
            focus_window("Project");
        });
        wait_until([this] { return at_visible("proj:refresh") && at_visible("proj:file:assets/blip.wav"); });
        step(4, [this, bz] {
            at_check(at_visible("proj:file:assets/blip.wav"), "the Project panel lists a file of the project (assets/blip.wav)");
            at_check(at_visible("proj:folder:") && at_visible("proj:folder:assets"), "...and a folder tree");
            bz->scans = projBrowser_.scans;
        });
        step(30, [this, bz] { at_check(projBrowser_.scans == bz->scans, "the panel does not read the disk again while nothing changed"); });
        snap("editor_project_panel.png");

        // The type filter.
        click_widget("proj:type");
        step(3, [] {});
        click_widget("proj:type:audio");
        step(5, [this] {
            at_check(at_visible("proj:file:assets/blip.wav"), "the type filter 'audio' keeps the sounds");
            at_check(!at_visible("proj:file:assets/autotest_drop.png") && !at_visible("proj:file:prefabs/autotest_drop.prefab.json"),
                     "...and hides the pictures and prefabs");
        });
        snap("editor_project_filter.png");
        step(2, [this] { projBrowser_.query.type = "all"; });
        // The search.
        search_for("DROP.p");
        step(4, [this] {
            at_check(at_visible("proj:file:assets/autotest_drop.png") && at_visible("proj:file:prefabs/autotest_drop.prefab.json"),
                     "searching 'DROP.p' (case-insensitive) keeps the files whose path contains it (the prefab.save and the picture written "
                     "after the panel was created are listed without Refresh)");
            at_check(!at_visible("proj:file:assets/blip.wav"), "...and hides the others");
        });
        snap("editor_project_search.png");
        click_widget("proj:refresh");
        step(4, [this] { at_check(projBrowser_.scans > 0, "Refresh reads the folder again"); });

        // A prefab dropped on the viewport: scene.spawn at the world point under the mouse.
        search_for("autotest_drop.prefab");
        step(2, [this, bz] {
            bz->entities = world().entity_count();
            bz->undo = undo_depth();
        });
        drag_to(tile_prefab, [this, bz] {
            const Vec2 t{vpImageMin_.x + vpImageSize_.x * 0.78f, vpImageMin_.y + vpImageSize_.y * 0.30f};
            const float tw = float(engine_->renderer()->target_width()), th = float(engine_->renderer()->target_height());
            bz->expected = engine_->renderer()->screen_to_world(Vec2{(t.x - vpImageMin_.x) / vpImageSize_.x * tw, (t.y - vpImageMin_.y) / vpImageSize_.y * th}, 0.0f);
            return t;
        });
        step(5, [this, bz] {
            at_check(world().entity_count() == bz->entities + 1, "dropping a prefab on the Viewport adds one entity");
            at_check(undo_depth() == bz->undo + 1, "...as one undo step");
            Entity e = selected();
            at_check(!e.is_null() && world().id_of(e) != "coin_1", "...and the new entity is the selection");
            const Vec3 p = e.is_null() ? Vec3{9999, 9999, 9999} : world().world_position(e);
            // A world unit can be less than a pixel in a small window: allow two panel pixels of difference.
            const float tol = 2.0f * float(engine_->renderer()->target_width()) / std::max(1.0f, vpImageSize_.x);
            at_check(std::fabs(p.x - bz->expected.x) < tol && std::fabs(p.y - bz->expected.y) < tol && std::fabs(p.z) < 0.01f,
                     "...at the world point under the mouse on the z = 0 plane (" + std::to_string(p.x) + ", " + std::to_string(p.y) +
                         " expected " + std::to_string(bz->expected.x) + ", " + std::to_string(bz->expected.y) + ")");
        });
        snap("editor_project_drop_prefab.png");
        step(2, [this] { focus_window("###Viewport"); });
        step(4, [] {});
        ctrl_z();
        step(5, [this, bz] {
            at_check(world().entity_count() == bz->entities, "Ctrl+Z removes the spawned entity");
            at_check(undo_depth() == bz->undo, "...and takes the undo step back");
        });

        // A file that is not a prefab dropped on the viewport does nothing.
        search_for("autotest_drop.png");
        drag_to(tile_png, [this] { return Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.5f}; });
        step(5, [this, bz] {
            at_check(world().entity_count() == bz->entities && undo_depth() == bz->undo, "a picture dropped on the Viewport does nothing");
        });

        // A picture dropped on a Sprite's texture field.
        step(2, [this, bz] {
            focus_window("Project");
            select_id("dropsprite");
            inspScrollTo_ = "Sprite.texture";
            bz->undo = undo_depth();
        });
        wait_until([this] { return at_shown("insp:Sprite.texture") && at_visible(std::string("proj:file:assets/autotest_drop.png")); });
        drag_to(tile_png, [this] { return at_widget("insp:Sprite.texture"); });
        step(5, [this, bz] {
            const Sprite* sp = world().get<Sprite>(world().find_by_id("dropsprite"));
            at_check(sp && sp->texture == "assets/autotest_drop.png", "a picture dropped on the Sprite's texture field sets it");
            at_check(undo_depth() == bz->undo + 1, "...as one undo step");
        });
        snap("editor_project_drop_texture.png");
        search_for("blip.wav");
        step(2, [this, bz] { bz->undo = undo_depth(); });
        wait_until([this] { return at_shown("insp:Sprite.texture") && at_visible(std::string("proj:file:assets/blip.wav")); });
        drag_to("proj:file:assets/blip.wav", [this] { return at_widget("insp:Sprite.texture"); });
        step(5, [this, bz] {
            const Sprite* sp = world().get<Sprite>(world().find_by_id("dropsprite"));
            at_check(sp && sp->texture == "assets/autotest_drop.png" && undo_depth() == bz->undo,
                     "a sound dropped on a texture field is refused (the field keeps its value)");
        });

        // Delete: the right-click menu, a confirmation, fs.delete; the listing follows without Refresh.
        search_for("autotest_trash");
        wait_until([this] { return at_visible("proj:file:assets/autotest_trash.txt"); });
        right_click_widget("proj:file:assets/autotest_trash.txt");
        step(3, [this] {
            at_check(at_visible("proj:ctx:reveal") && at_visible("proj:ctx:copy") && at_visible("proj:ctx:delete"),
                     "right-clicking a file offers Show in the file manager, Copy path and Delete");
        });
        snap("editor_project_menu.png");
        click_widget("proj:ctx:copy");
        step(4, [this] { at_check(std::string(ImGui::GetClipboardText() ? ImGui::GetClipboardText() : "") == "assets/autotest_trash.txt", "Copy path puts the project-relative path on the clipboard"); });
        right_click_widget("proj:file:assets/autotest_trash.txt");
        step(3, [] {});
        click_widget("proj:ctx:delete");
        step(4, [this] { at_check(at_visible("proj:delete-confirm") && stdfs::exists(projectDir_ + "/assets/autotest_trash.txt"), "Delete asks first; the file is still there"); });
        snap("editor_project_delete.png");
        click_widget("proj:delete-confirm");
        wait_until([this] { return !at_visible("proj:file:assets/autotest_trash.txt") && !at_visible("proj:delete-confirm"); });
        step(4, [this] {
            at_check(!stdfs::exists(projectDir_ + "/assets/autotest_trash.txt"), "confirming removes the file from disk (fs.delete)");
            at_check(!at_visible("proj:file:assets/autotest_trash.txt"), "...and the panel stops listing it without a Refresh");
        });

    }

    // ----------------------------------------------------------------------------------- O. CLI agent (Claude Code)
    section("O");
    // A CLI agent runs its own loop in a child process; its tool calls come back through the editor's MCP endpoint. The
    // fake Claude Code of the AI tests calls scene_spawn there: the coin must land in THIS world, with an undo step, and
    // Play must wait meanwhile. Needs the fixture (the autotest runs from the repository root) and curl.
    step(1, [this] {  // the background detection writes aiConfig_ once: it must be done before the swap below (O alone runs early)
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this] {
#ifdef _WIN32
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.cmd");
#else
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.sh");
#endif
        if (!stdfs::exists(fake) || ai::which("curl").empty()) {
            atLog_.push_back("SKIP CLI agent through the editor's MCP endpoint (no " + fake.string() + " or no curl)");
            return;
        }
        ai::ProviderConfig cc;
        cc.name = "claude-code";
        cc.kind = ai::ProviderKind::ClaudeCode;
        cc.command = fake.make_preferred().string();
        cc.env["FAKE_MODE"] = "mcp_spawn";
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            aiConfig_.providers[cc.name] = cc;
            aiConfig_.roles[ai::kRoleOrchestrator] = ai::RoleConfig{cc.name};
        }
        atUndoBeforeAi_ = undo_depth();
        ai_start("Add a coin.");
        at_check(ai_running(), "a message to a Claude Code orchestrator starts the agent");
        play();
        at_check(play_state() == PlayState::Edit, "Play waits while the CLI agent is changing the scene");
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(2, [this] {
        if (!atSavedConfig_) return;
        at_check(!ai_running(), "the CLI agent finished");
        at_check(!world().find("CliCoin").is_null(), "the CLI agent's tool call (scene_spawn over MCP) created the entity in the editor's world");
        at_check(undo_depth() > atUndoBeforeAi_, "the CLI agent's edit recorded an undo step");
        undo();
        at_check(world().find("CliCoin").is_null(), "Ctrl+Z (undo) removes the entity the CLI agent created");
        std::lock_guard<std::mutex> lock(aiMu_);
        aiConfig_ = std::move(*atSavedConfig_);
        atSavedConfig_.reset();
    });

    // --------------------------------------------------------------------------------- P. Revert an AI run
    section("P");
    // A scripted AI run overwrites one script, adds another and spawns an entity. The transcript offers Revert; confirming it
    // puts the files back and the scene back as ONE Ctrl+Z step; Undo revert brings the run's state back.
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this, project_file] {
        write_file(project_file("scripts/revert_old.js"), "old\n");
        std::error_code ec;
        stdfs::remove(project_file("scripts/revert_new.js"), ec);
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<RevertProvider>());
        };
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            ai::RoleConfig& orchestrator = aiConfig_.roles[ai::kRoleOrchestrator];
            orchestrator.provider = "anthropic";
            if (orchestrator.model.empty()) orchestrator.model = "mock";
        }
        chat_.clear();
        focus_window("AI Assistant");
        ai_start("Add a revert probe script and a coin.");
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(4, [this, project_file] {
        at_check(!ai_running(), "the scripted run finished");
        at_check(read_file(project_file("scripts/revert_old.js")) == "new\n" && stdfs::exists(project_file("scripts/revert_new.js")) &&
                     !world().find("RevertCoin").is_null(),
                 "the run overwrote a script, added one and spawned an entity");
        const ChatItem* run = nullptr;
        for (const ChatItem& c : chat())
            if (c.kind == ChatItem::Kind::Run) run = &c;
        at_check(run && run->modified == std::vector<std::string>{"scripts/revert_old.js"} &&
                     run->added == std::vector<std::string>{"scripts/revert_new.js"} && run->sceneChanged,
                 "the transcript lists what the run changed: a modified file, an added file, the scene");
        at_check(at_visible("ai:revert") && at_enabled("ai:revert"), "the run offers a Revert button");
    });
    snap("editor_ai_run_changed.png");
    click("ai:revert");
    step(4, [this] { at_check(at_visible("ai:revert:confirm"), "Revert asks before it changes anything"); });
    snap("editor_ai_revert_confirm.png");
    click("ai:revert:confirm");
    step(6, [this, project_file] {
        at_check(read_file(project_file("scripts/revert_old.js")) == "old\n", "Revert writes the overwritten script back");
        at_check(!stdfs::exists(project_file("scripts/revert_new.js")), "Revert deletes the file the run added");
        at_check(world().find("RevertCoin").is_null() && !dirty(), "Revert puts the scene back as it was before the run");
        bool sawRevert = false;
        for (const ChatItem& c : chat()) sawRevert = sawRevert || (c.kind == ChatItem::Kind::Revert && !c.isUndo);
        at_check(sawRevert && at_visible("ai:undo-revert") && !at_visible("ai:revert"), "the transcript says so and offers Undo revert");
        undo();
        at_check(!world().find("RevertCoin").is_null(), "the scene went back as ONE Ctrl+Z step: Undo brings the coin back");
        redo();
        at_check(world().find("RevertCoin").is_null(), "...and Redo takes it away again");
    });
    snap("editor_ai_reverted.png");
    scroll_to("ai:undo-revert", "AI Assistant");
    click("ai:undo-revert");
    step(4, [this] { at_check(at_visible("ai:revert:confirm"), "Undo revert asks first too"); });
    click("ai:revert:confirm");
    step(6, [this, project_file] {
        at_check(read_file(project_file("scripts/revert_old.js")) == "new\n" && stdfs::exists(project_file("scripts/revert_new.js")),
                 "Undo revert brings the run's files back");
        at_check(!world().find("RevertCoin").is_null(), "...and the run's scene");
        at_check(at_visible("ai:revert"), "...and the run can be reverted again");
        std::error_code ec;
        stdfs::remove(project_file("scripts/revert_old.js"), ec);
        stdfs::remove(project_file("scripts/revert_new.js"), ec);
        aiFactory_ = nullptr;
        if (atSavedConfig_) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
        }
        chat_.clear();
        focus_window("###Viewport");
    });


    // ------------------------------------------------------------------------- Q. The agent is never silent
    section("Q");
    // The fake Claude Code of the AI tests stands in for a real orchestrator. (1) It stays silent for longer than
    // limits.stuckAfterSeconds: the panel warns, "Check activity" writes a verdict in the chat and quiets the warning, Stop
    // ends the run. (2) It calls ai_run (a worker, over the editor's MCP endpoint) and ends its turn without waiting for the
    // answer: the panel keeps showing the worker's progress, and when the worker finishes its report is in the chat and the
    // orchestrator is continued with it (once). (3) Stop while the worker runs ends both and sends no continuation.
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this, project_file] {
#ifdef _WIN32
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.cmd");
#else
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.sh");
#endif
        atQFake_.clear();
        if (!stdfs::exists(fake) || ai::which("curl").empty()) {
            atLog_.push_back("SKIP the agent is never silent (no " + fake.string() + " or no curl)");
            return;
        }
        atQFake_ = fake.make_preferred().string();
        atQArgv_ = (stdfs::temp_directory_path() / "fa_autotest_q_argv.txt").string();
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            ai::ProviderConfig cc;
            cc.name = "claude-code";
            cc.kind = ai::ProviderKind::ClaudeCode;
            cc.command = atQFake_;
            cc.env["FAKE_ARGV_FILE"] = atQArgv_;
            cc.env["FAKE_SLEEP"] = "7";
            aiConfig_.providers[cc.name] = cc;
            aiConfig_.roles[ai::kRoleOrchestrator] = ai::RoleConfig{cc.name};
            ai::RoleConfig& worker = aiConfig_.roles[ai::kRoleWorker];
            worker.provider = "anthropic";
            worker.model = "mock";
            aiConfig_.limits.stuckAfterSeconds = 2;
        }
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<SlowWorkerProvider>(2500));
        };
        chat_.clear();
        focus_window("AI Assistant");
        ai_start("Think for a while.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return at_visible("ai:stuck"); };
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        at_check(ai_running(), "the agent is still running while it is silent");
        at_check(at_visible("ai:status"), "the panel shows the run's elapsed time and last activity");
        at_check(at_visible("ai:stuck") && at_visible("ai:stuck:stop") && at_visible("ai:stuck:check"),
                 "a silent agent gets a warning with Stop and Check activity");
    });
    snap("editor_ai_stuck.png");
    click("ai:stuck:check");
    step(3, [this] {
        if (atQFake_.empty()) return;
        const ChatItem* check = nullptr;
        for (const ChatItem& c : chat())
            if ((c.kind == ChatItem::Kind::Info || c.kind == ChatItem::Kind::Error) && c.text.rfind("Activity check:", 0) == 0) check = &c;
        at_check(check && check->text.find("Process:") != std::string::npos && check->text.find("Last event:") != std::string::npos,
                 "Check activity writes a verdict with what it saw in the chat");
        at_check(!at_visible("ai:stuck"), "...and quiets the warning");
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running(), "the silent agent finished in the end");
        // A second silent run, ended with the warning's Stop.
        ai_start("Think for a while again.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return at_visible("ai:stuck"); };
    });
    click("ai:stuck:stop");
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running() && !ai_busy(), "Stop in the warning ends the run");
        // (2) the orchestrator delegates and ends its turn.
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            ai::ProviderConfig& cc = aiConfig_.providers["claude-code"];
            cc.env["FAKE_MODE"] = "mcp_run_detach";
            cc.env.erase("FAKE_SLEEP");
            aiConfig_.limits.stuckAfterSeconds = 120;
        }
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        chat_.clear();
        ai_start("Delegate the coin.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] {
            const AiRun* r = ai_run_of(chat_.current().id);
            return r && r->detached.load();
        };
    });
    step(3, [this] {
        if (atQFake_.empty()) return;
        {
            const AiRun* r = ai_run_of(chat_.current().id);
            at_check(ai_running() && r && !r->running.load(), "the orchestrator's turn ended and the run goes on for the worker");
        }
        at_check(at_visible("ai:detached"), "the panel says a worker is still running");
        bool live = false;
        for (const ChatItem& c : chat()) live = live || (c.kind == ChatItem::Kind::Assistant && c.depth == 1 && c.text.find("Making the coin") != std::string::npos);
        at_check(live, "the worker's progress is in the chat while it runs, one level in");
        play();
        at_check(play_state() == PlayState::Edit, "Play waits for the worker");
    });
    snap("editor_ai_worker_running.png");
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(3, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running() && !ai_busy(), "the run ended after the continuation");
        int reports = 0, continued = 0;
        for (const ChatItem& c : chat()) {
            if (c.kind == ChatItem::Kind::Assistant && c.depth == 1 && c.text.find("Worker report: coin done") != std::string::npos) ++reports;
            if (c.kind == ChatItem::Kind::Info && c.text.find("continuing the orchestrator") != std::string::npos) ++continued;
        }
        at_check(reports == 1, "the worker's report is in the chat once");
        at_check(continued == 1, "the transcript says the orchestrator was continued");
        const std::string argv = read_file(atQArgv_);
        std::size_t stdins = 0, resumes = 0;
        for (std::size_t at = argv.find("stdin:"); at != std::string::npos; at = argv.find("stdin:", at + 1)) ++stdins;
        for (std::size_t at = argv.find("--resume"); at != std::string::npos; at = argv.find("--resume", at + 1)) ++resumes;
        at_check(stdins == 2, "the orchestrator ran twice: its first turn and one continuation (" + std::to_string(stdins) + ")");
        at_check(resumes == 1, "the continuation resumed the same Claude Code session");
        at_check(argv.find("Worker report: coin done") != std::string::npos, "the continuation carried the worker's report");
        // (3) Stop while the worker runs.
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        chat_.clear();
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<SlowWorkerProvider>(20000));
        };
        ai_start("Delegate the coin, slowly.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] {
            const AiRun* r = ai_run_of(chat_.current().id);
            return r && r->detached.load();
        };
    });
    click("ai:stop");
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(3, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running() && !ai_busy(), "Stop ends the run while the worker works");
        const std::string argv = read_file(atQArgv_);
        std::size_t stdins = 0;
        for (std::size_t at = argv.find("stdin:"); at != std::string::npos; at = argv.find("stdin:", at + 1)) ++stdins;
        at_check(stdins == 1, "...and no continuation is sent");
        bool continued = false;
        for (const ChatItem& c : chat()) continued = continued || c.text.find("continuing the orchestrator") != std::string::npos;
        at_check(!continued, "...and the transcript does not claim one");
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        aiFactory_ = nullptr;
        if (atSavedConfig_) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
        }
        chat_.clear();
        focus_window("###Viewport");
    });

    // ------------------------------------------------------------------------------------ R. Updated on disk
    section("R");
    // The program is replaced on disk without the updater: a non-blocking notice offers Restart / Not now. The watch looks at a
    // fake program (two fingerprints written into files), so nothing real is replaced and Restart only records the click.
    {
        auto fake_program = [](const std::string& path, const std::string& version, const std::string& fingerprint, std::size_t pad) {
            std::string bytes = "MZ fake program " + std::string(pad, '.');
            bytes += std::string("FA-BUILD-") + "FINGERPRINT:" + fingerprint + ";";
            bytes += std::string("FA-ENGINE-") + "VERSION:" + version + ";";
            write_file(path, bytes);
        };
        step(2, [this, fake_program] {
            const std::string fake = atOutDir_ + "/fake_factoria";
            fake_program(fake, "0.1.0", "aaaaaaaaaaaa", 100);
            diskWatchOwn_ = std::make_unique<UpdateWatch>(fake, BuildId{"0.1.0", "aaaaaaaaaaaa"});
            diskDismissedSet_ = false;
            diskRestartRequested_ = false;
            diskSettling_ = false;
            diskPolled_ = -100;
        });
        step(3, [this] {
            at_check(!at_visible("update:disk"), "no notice while the program on disk is the one that runs");
            Json status = update_status_json(disk_watch());
            at_check(status.value("state", "") == "current" && status.value("restartDue", true) == false,
                     "engine.update_status says current: " + status.dump());
        });
        step(2, [this, fake_program] {  // the new files arrive (a different size, so a different stamp even within one second)
            fake_program(atOutDir_ + "/fake_factoria", "0.2.0", "bbbbbbbbbbbb", 400);
            diskPollNow_ = true;
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("update:disk"); };  // seen twice alike (a second), then identified
        });
        step(3, [this] {
            at_check(at_visible("update:disk"), "the notice appears when the program changed on disk");
            at_check(at_enabled("update:restart") && at_visible("update:disknotnow"), "...with Restart and Not now");
            Json status = update_status_json(disk_watch());
            at_check(status.value("state", "") == "updated_on_disk" && status.value("restartDue", false) &&
                         status["onDisk"].value("version", "") == "0.2.0" && status["editor"].value("noticeShown", false),
                     "engine.update_status says an update is on disk and the notice is showing: " + status.dump());
            // A play session is not stopped silently: Restart is off, with the reason.
            play();
        });
        step(3, [this] {
            at_check(play_state() != PlayState::Edit, "a play session runs");
            at_check(!at_enabled("update:restart") && !disk_restart_blocker().empty(), "Restart is off while a play session runs (" + disk_restart_blocker() + ")");
        });
        snap("editor_update_disk.png");
        step(2, [this] {
            stop();
            at_check(disk_restart_blocker().empty(), "...and back on when it stops");
        });
        click("update:disknotnow");
        step(3, [this] {
            at_check(!at_visible("update:disk"), "Not now hides the notice");
            diskPollNow_ = true;
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !diskPollNow_; };
        });
        step(3, [this, fake_program] {
            at_check(!at_visible("update:disk"), "...and it stays quiet while the file does not change");
            fake_program(atOutDir_ + "/fake_factoria", "0.3.0", "cccccccccccc", 900);  // another build lands
            diskPollNow_ = true;
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("update:disk"); };
        });
        step(3, [this] {
            at_check(at_visible("update:disk") && disk_watch().on_disk().version == "0.3.0", "...and comes back when the file changes again");
        });
        click("update:restart");
        step(3, [this] {
            at_check(diskRestartRequested_, "Restart asks to quit and reopen the editor");
            diskWatchOwn_.reset();
            diskRestartRequested_ = false;
            diskDismissedSet_ = false;
            diskSettling_ = false;
            std::error_code ec;
            stdfs::remove(atOutDir_ + "/fake_factoria", ec);
        });
    }

    // ------------------------------------------------------------------------------------ U. Layout kept
    section("U");
    // A layout the user changed (a panel floated, a tab moved to another dock, a column made wider) is in the layout file when the
    // editor goes down, and comes back when a project opens again: straight away, and after a visit to the welcome screen (which
    // has its own ImGui context, without the dock space). The test uses its own layout file; the real one is put back at the end.
    {
        auto reopen_wait = [this](bool viaWelcome) {
            const std::string dir = projectDir_;
            const std::uint64_t u0 = uiFrame_;
            if (viaWelcome) {
                close_project();
                atReopenDir_ = dir;
                atReopenIn_ = 10;
            } else {
                open_project(dir);
            }
            atWaitCount_ = 0;
            atWaitUntil_ = [this, u0, viaWelcome] { return engine_ && pendingOpen_.empty() && !pendingWelcome_ && atReopenIn_ == 0 && uiFrame_ >= u0 + 8 + (viaWelcome ? 10 : 0); };
        };
        step(2, [this, reopen_wait] {
            atIniSaved_ = iniPath_;
            iniPath_ = atOutDir_ + "/layout_test.ini";
            std::error_code ec;
            stdfs::remove(iniPath_, ec);
            reopen_wait(false);  // no layout file yet: the default layout, and the file is written when the UI goes down
        });
        step(2, [this] {
            at_check(!panel_floating("Console") && panel_node("Console") != 0, "no layout file: Console starts docked (the default layout)");
            at_check(panel_node("Project") == panel_node("Console"), "...in the same dock as Project");
            at_check(panel_node("Project") != panel_node("Hierarchy"), "...and Project is not with the Hierarchy");
            // The user's changes: Console floats, Project joins the Hierarchy and the left column gets wider.
            ImGuiContext& g = *GImGui;
            ImGuiWindow* console = panel_window("Console");
            ImGui::DockContextQueueUndockWindow(&g, console);
            ImGuiWindow* hier = panel_window("Hierarchy");
            if (hier && hier->DockNode && panel_window("Project"))
                ImGui::DockContextQueueDock(&g, hier->DockNode->HostWindow, hier->DockNode, panel_window("Project"), ImGuiDir_None, 0.0f, false);
            if (hier && hier->DockNode) {
                ImGuiDockNode* col = hier->DockNode->ParentNode;
                while (col && col->ParentNode && col->ParentNode->SplitAxis != ImGuiAxis_X) col = col->ParentNode;
                if (col && col->ParentNode) {  // the node of the left column inside the X split: take 200 px from its sibling
                    ImGuiDockNode* sib = col->ParentNode->ChildNodes[0] == col ? col->ParentNode->ChildNodes[1] : col->ParentNode->ChildNodes[0];
                    col->SizeRef.x += 200;
                    if (sib) sib->SizeRef.x = std::max(100.0f, sib->SizeRef.x - 200);
                }
            }
            showFeedback_ = false;  // a panel closed with its X, and one opened from the View menu
            showAudio_ = true;
            atLayoutWidth_ = panel_width("Hierarchy");
        });
        step(4, [] {
            ImGui::SetWindowPos("Console", ImVec2(300, 300));
            ImGui::SetWindowSize("Console", ImVec2(420, 210));
        });
        step(6, [this] {
            at_check(panel_floating("Console"), "the test floated Console");
            at_check(panel_node("Project") == panel_node("Hierarchy") && panel_node("Project") != 0, "the test moved Project next to the Hierarchy");
            at_check(panel_width("Hierarchy") > atLayoutWidth_ + 100, "the test made the left column wider (" + std::to_string(atLayoutWidth_) + " -> " +
                                                                        std::to_string(panel_width("Hierarchy")) + ")");
            atLayoutWidth_ = panel_width("Hierarchy");
        });
        step(2, [reopen_wait] { reopen_wait(false); });
        auto check_changed_layout = [this](const std::string& when) {
            at_check(!showFeedback_ && showAudio_ && showConsole_, "the closed panel (Engine Feedback) is still closed and the opened one (Audio) still open " + when);
            at_check(panel_floating("Console"), "Console is still floating " + when);
            const ImGuiWindow* c = panel_window("Console");
            at_check(c && std::fabs(c->Size.x - 420) < 3 && std::fabs(c->Size.y - 210) < 3, "...with the size the user gave it " + when);
            at_check(panel_node("Project") == panel_node("Hierarchy") && panel_node("Project") != 0, "Project is still next to the Hierarchy " + when);
            at_check(std::fabs(panel_width("Hierarchy") - atLayoutWidth_) < 6,
                     "the left column keeps its width " + when + " (" + std::to_string(panel_width("Hierarchy")) + " vs " + std::to_string(atLayoutWidth_) + ")");
        };
        step(2, [check_changed_layout] { check_changed_layout("after the project is opened again"); });
        step(2, [reopen_wait] { reopen_wait(true); });  // through the welcome screen: its context must not wipe the dock data
        step(2, [check_changed_layout] { check_changed_layout("after a visit to the welcome screen"); });
        step(2, [this] { resetLayout_ = true; });
        step(4, [this] {
            at_check(!panel_floating("Console") && panel_node("Console") == panel_node("Project"), "Reset layout puts Console back in the bottom dock");
            at_check(panel_node("Project") != panel_node("Hierarchy"), "...and Project away from the Hierarchy");
            at_check(showFeedback_ && !showAudio_, "...and the panels that are open by default again");
        });
        step(2, [this, reopen_wait] {  // the real layout file again (none in the autotest), through a last reopen
            iniPath_ = atIniSaved_;
            reopen_wait(false);
        });
    }
    // ------------------------------------------------------------------------------------------------------ U. Reviews
    section("V");
    // A review runs only when its button is pressed: it opens a tab of its own, the reviewer is offered only tools that look
    // and play, the report is saved with its score, and nothing reaches the orchestrator until "Send to orchestrator".
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this, project_file] {
        std::error_code ec;
        stdfs::remove_all(project_file(".factoria/ai/reviews"), ec);
        aiReviewDirty_ = true;
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<ReviewerProvider>());
        };
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            for (const char* role : {ai::kRoleOrchestrator, ai::kRoleReviewer, ai::kRoleArtCritic}) {
                ai::RoleConfig& rc = aiConfig_.roles[role];
                rc.provider = "anthropic";
                rc.model = "mock";
            }
        }
        while (chat_.tabs.size() > 1) chat_.close(0);
        chat_.clear();
        g_reviewToolsOffered.clear();
        focus_window("AI Assistant");
    });
    step(3, [this] {
        at_check(at_visible("ai:review:game") && at_visible("ai:review:art"), "the AI Assistant has an Art critique and a Game review button");
        at_check(chat().empty() && !ai_busy(), "nothing runs and nothing is asked until a button is pressed");
    });
    click("menu:ai");
    click("menu:ai-roles");
    step(3, [this] {
        at_check(showAiSettings_, "AI > Roles... opens the AI settings window");
        at_check(at_visible("ai:roles:enabled:orchestrator") && !at_enabled("ai:roles:enabled:orchestrator"),
                 "the Roles window shows the orchestrator's Enabled checkbox ticked and disabled");
        at_check(at_visible("ai:roles:enabled:artist") && at_enabled("ai:roles:enabled:artist") &&
                     at_visible("ai:roles:enabled:reviewer"),
                 "...and an Enabled checkbox for the other roles");
    });
    click("ai:roles:enabled:artist");
    step(3, [this] {
        at_check(!aiRolesEdit_[ai::kRoleArtist].enabled && aiRolesEdit_[ai::kRoleWorker].enabled,
                 "unticking Artist turns off that role only");
    });
    click("ai:roles:revert");
    step(3, [this] {
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            at_check(aiConfig_.role_enabled(ai::kRoleArtist), "Revert leaves the configuration alone");
        }
        at_check(aiRolesEdit_[ai::kRoleArtist].enabled, "...and puts the Enabled checkbox back");
        showAiSettings_ = false;
        aiSettings_ = AiSettingsDraft{};
    });
    click("ai:review:game");
    step(3, [this] {
        at_check(at_visible("ai:review:start") && !aiReview_.active && !ai_busy() && chat().empty(),
                 "a review button asks first: nothing runs until Start is pressed");
    });
    click("ai:review:start");
    step(2, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !aiReview_.active && !ai_busy(); };
    });
    step(4, [this] {
        at_check(!aiReview_.active && !ai_running(), "the review finished");
        const auto saved = ai::list_reviews(projectDir_);
        at_check(saved.size() == 1 && saved[0].role == ai::kRoleReviewer && saved[0].score == 7.5 && saved[0].persona == "all-rounder",
                 "the report was saved with its score and persona (" + std::to_string(saved.size()) + " review(s))");
        at_check(saved.size() == 1 && stdfs::exists(saved[0].path) && saved[0].subScores.size() == 2 &&
                     saved[0].text.find("```") == std::string::npos,
                 "...with its sub-scores and the text without the score block");
        const bool hasLook = std::ranges::find(g_reviewToolsOffered, "scene_list_entities") != g_reviewToolsOffered.end();
        bool hasEdit = false;
        for (const char* t : {"scene_spawn", "fs_write", "scene_set_component", "ai_run", "agent_delegate"})
            hasEdit = hasEdit || std::ranges::find(g_reviewToolsOffered, t) != g_reviewToolsOffered.end();
        at_check(hasLook && !hasEdit, "the reviewer was offered tools that look, and none that change the project");
        bool onlyReview = chat().size() >= 2;
        for (const ChatItem& c : chat())
            if (c.kind == ChatItem::Kind::User) onlyReview = onlyReview && c.role == "review";
        at_check(onlyReview, "the review ran in its own tab: nothing was posted as a message to the orchestrator");
        at_check(aiReviewsShown_, "the AI reviews window opens with the report");
        at_check(play_state() == PlayState::Edit, "the project stays in edit mode");
    });
    snap("editor_ai_review.png");
    click("ai:review:send");
    step(2, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !ai_busy(); };
    });
    step(4, [this] {
        const AiChat& cur = chat_.current();
        bool sent = false;
        for (const ChatItem& c : cur.items)
            sent = sent || (c.kind == ChatItem::Kind::User && c.role != "review" && c.text.find("7.5") != std::string::npos);
        at_check(sent, "Send to orchestrator posts the report as a user message into an orchestrator chat");
        at_check(chat_.tabs.size() >= 2, "...in a new tab, because the active one was the review's own");
        std::error_code ec;
        stdfs::remove_all(projectDir_ + "/.factoria/ai/reviews", ec);
        aiReviewDirty_ = true;
        aiReviewsShown_ = false;
        aiFactory_ = nullptr;
        if (atSavedConfig_) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
        }
        while (chat_.tabs.size() > 1) chat_.close(0);
        chat_.clear();
        focus_window("###Viewport");
    });

    // ----------------------------------------------------------------------- W. Several AI chats at the same time
    section("W");
    // Two chats run at once against a scripted model that writes the same file and spawns a coin in both: both finish with their
    // own results, each chat is warned that the other changed the same file, Play names the chats that work, a third chat is
    // held back by limits.maxConcurrentRuns, Revert of one run keeps the other's changes. Then Stop on one run leaves the other going.
    {
        struct VState {
            std::string a, b, c;
        };
        auto v = std::make_shared<VState>();
        auto reset_chats = [this] {  // one blank tab, nothing of the previous scenario saved
            for (int i = static_cast<int>(chat_.tabs.size()) - 1; i >= 0; --i) {
                chat_.select(i);
                chat_.clear();
            }
            while (chat_.tabs.size() > 1) chat_.close(static_cast<int>(chat_.tabs.size()) - 1);
            aiTabForce_ = 2;
        };
        auto info_warnings = [](const AiChat* c) {
            int n = 0;
            for (const ChatItem& it : c->items)
                n += it.kind == ChatItem::Kind::Info && it.isError && it.text.find("also changed") != std::string::npos ? 1 : 0;
            return n;
        };
        auto said = [](const AiChat* c, const std::string& text) {
            for (const ChatItem& it : c->items)
                if (it.kind == ChatItem::Kind::Assistant && it.text.find(text) != std::string::npos) return true;
            return false;
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load(); };
        });
        step(2, [this, v, project_file, reset_chats] {
            write_file(project_file("scripts/u_shared.js"), "old\n");
            std::error_code ec;
            for (const char* f : {"scripts/u_a.js", "scripts/u_b.js", "scripts/u_l.js", "scripts/u_s.js"}) stdfs::remove(project_file(f), ec);
            aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
                return std::shared_ptr<ai::ChatProvider>(std::make_shared<ConcurrentProvider>());
            };
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
                ai::RoleConfig& orchestrator = aiConfig_.roles[ai::kRoleOrchestrator];
                orchestrator.provider = "anthropic";
                if (orchestrator.model.empty()) orchestrator.model = "mock";
                aiConfig_.limits.maxConcurrentRuns = 2;
            }
            reset_chats();
            focus_window("AI Assistant");
            ai_start("Probe A [A]");
            v->a = chat_.current().id;
            chat_.add(static_cast<i64>(std::time(nullptr)));
            ai_start("Probe B [B]");
            v->b = chat_.current().id;
            chat_.add(static_cast<i64>(std::time(nullptr)));
            ai_start("Probe C [A]");  // the third: no slot
            v->c = chat_.current().id;
            aiTabForce_ = 2;
        });
        step(3, [this, v] {
            at_check(ai_run_count() == 2 && ai_chat_running(v->a) && ai_chat_running(v->b), "two chats run at the same time");
            at_check(!ai_chat_running(v->c) && chat_.find(v->c) && chat_.find(v->c)->items.empty(),
                     "a third chat is held back by limits.maxConcurrentRuns (it did not start, its message was not sent)");
            play();
            at_check(play_state() == PlayState::Edit, "Play waits while the assistant edits");
            const std::string note = ai_editing_note();
            at_check(note.find("Probe A") != std::string::npos && note.find("Probe B") != std::string::npos,
                     "...and the note names the chats that work: " + note);
        });
        step(2, [this] {
            atWaitAi_ = true;
            atWaitCount_ = 0;
        });
        step(3, [this, v, project_file, info_warnings, said] {
            at_check(!ai_running(), "both scripted runs finished");
            const AiChat* a = chat_.find(v->a);
            const AiChat* b = chat_.find(v->b);
            if (!a || !b) {
                at_check(false, "both chats are still open");
                return;
            }
            at_check(said(a, "Finished A") && !said(a, "Finished B") && said(b, "Finished B") && !said(b, "Finished A"),
                     "each chat has its own run's answer");
            at_check(a->usage.inputTokens > 0 && b->usage.inputTokens > 0, "each chat counted its own tokens");
            at_check(info_warnings(a) >= 1 && info_warnings(b) >= 1,
                     "each chat is warned that the other changed the same file (" + std::to_string(info_warnings(a)) + ", " +
                         std::to_string(info_warnings(b)) + ")");
            auto names = [&](const AiChat* c, const char* other, const char* file) {
                bool named = false, file_listed = false;
                for (const ChatItem& it : c->items) {
                    if (it.kind != ChatItem::Kind::Info || !it.isError) continue;
                    named = it.text.find(other) != std::string::npos;
                    file_listed = file_listed || it.text.find(file) != std::string::npos;
                }
                return named && file_listed;
            };
            at_check(names(a, "Probe B", "scripts/u_shared.js") && names(b, "Probe A", "scripts/u_shared.js"),
                     "...each warning names the other chat and the shared file");
            const ChatItem* ra = nullptr;
            const ChatItem* rb = nullptr;
            for (const ChatItem& it : a->items)
                if (it.kind == ChatItem::Kind::Run) ra = &it;
            for (const ChatItem& it : b->items)
                if (it.kind == ChatItem::Kind::Run) rb = &it;
            auto has = [](const std::vector<std::string>& list, const char* f) { return std::ranges::find(list, f) != list.end(); };
            at_check(ra && rb && has(ra->added, "scripts/u_a.js") && has(ra->modified, "scripts/u_shared.js") &&
                         !has(ra->added, "scripts/u_b.js") && has(rb->added, "scripts/u_b.js") && !has(rb->added, "scripts/u_a.js"),
                     "each Run item lists its own files, not the other chat's");
            at_check(!world().find("UCoinA").is_null() && !world().find("UCoinB").is_null(), "both runs' coins are in the scene");
            at_check(!read_file(project_file("scripts/u_a.js")).empty() && !read_file(project_file("scripts/u_b.js")).empty(),
                     "both runs' files are on disk");
            chat_.select(chat_.index_of(v->a));
            aiTabForce_ = 2;
        });
        step(3, [] {});
        scroll_to("ai:revert", "AI Assistant");  // A's warnings push it below the fold of a small display
        click("ai:revert");
        step(4, [this] {
            at_check(at_visible("ai:revert:confirm") && at_visible("ai:revert:confirm-all"),
                     "Revert of A asks, and offers to keep the other chat's changes or take those files back too");
        });
        click("ai:revert:confirm");
        step(6, [this, v, project_file] {
            at_check(!stdfs::exists(project_file("scripts/u_a.js")), "Revert of A removes the file only A added");
            at_check(stdfs::exists(project_file("scripts/u_b.js")), "...and leaves the file B added");
            at_check(read_file(project_file("scripts/u_shared.js")) != "old\n", "...and the file both changed stays as it is now");
            at_check(!world().find("UCoinA").is_null() && !world().find("UCoinB").is_null(),
                     "...and the scene stays too, since B edited it as well");
            const AiChat* a = chat_.find(v->a);
            bool scoped = false;
            if (a)
                for (const ChatItem& it : a->items) scoped = scoped || (it.kind == ChatItem::Kind::Revert && it.scoped);
            at_check(scoped, "A's transcript says only some files went back");
        });
        // Stop on one run leaves the other going.
        step(2, [this, v, project_file, reset_chats] {
            std::error_code ec;
            stdfs::remove(project_file("scripts/u_l.js"), ec);
            reset_chats();
            ai_start("Probe S [S]");
            v->a = chat_.current().id;
            chat_.add(static_cast<i64>(std::time(nullptr)));
            ai_start("Probe L [L]");
            v->b = chat_.current().id;
            chat_.select(chat_.index_of(v->a));
            aiTabForce_ = 2;
            atWaitCount_ = 0;
            atWaitUntil_ = [this, v] { return ai_chat_running(v->a) && ai_chat_running(v->b); };
        });
        step(3, [] {});
        click("ai:stop");
        step(2, [this, v] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, v] { return !ai_chat_running(v->a); };
        });
        step(3, [this, v] {
            at_check(!ai_chat_running(v->a), "Stop ends the run of the chat it is pressed in");
            at_check(ai_chat_running(v->b), "...and the other chat's run goes on");
            atWaitAi_ = true;
            atWaitCount_ = 0;
        });
        step(3, [this, v, project_file, info_warnings, said] {
            const AiChat* b = chat_.find(v->b);
            at_check(b && said(b, "Finished L") && info_warnings(b) == 0, "the other run finished with its own result and no false warning");
            at_check(read_file(project_file("scripts/u_l.js")) == "only L\n", "...and its file is on disk");
            at_check(!stdfs::exists(project_file("scripts/u_s.js")), "the stopped run wrote nothing");
            at_check(!ai_running() && !ai_busy(), "no run is left");
            std::error_code ec;
            for (const char* f : {"scripts/u_shared.js", "scripts/u_a.js", "scripts/u_b.js", "scripts/u_l.js"}) stdfs::remove(project_file(f), ec);
            aiFactory_ = nullptr;
            if (atSavedConfig_) {
                std::lock_guard<std::mutex> lock(aiMu_);
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
        });
        step(2, [this, reset_chats] {
            reset_chats();
            focus_window("###Viewport");
        });
    }

    // ------------------------------------------------------------------------------------------------ X. AI settings window
    section("X");
    // AI > AI Settings... opens the window on the user's ai.json (here a scratch file: FACTORIA_AI_CONFIG
    // is set for the section and put back after). What a person types in the fields is set on the draft; Save and Close are
    // real clicks. A site that is not a web address stops Save with a message and leaves the file as it was; a good Save
    // rewrites only assets / assetSources / the provider fields the routes need (roles and limits stay), stores a typed key in
    // a file only the user can read and forgets it, and a stored key can be removed again.
    {
        struct XState {
            std::string path, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
            std::string before;
        };
        auto x = std::make_shared<XState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_settings_scratch.json";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({
  "limits": { "maxConcurrentRuns": 3 },
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } },
  "assets": { "image": { "provider": "fake" } }
})");
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();  // the panel and the window now read the scratch file
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_, "AI > AI Settings... opens the window");
            aiSettingsTab_ = 2;  // the Assets tab: the rest of this section works there
            at_check(aiSettings_.loaded && aiSettings_.path == x->path, "it works on the AI config file (" + aiSettings_.path + ")");
            at_check(aiSettings_.routes["image"].provider == "fake" && aiSettings_.routes["sound"].provider.empty(),
                     "the image row shows the provider of the file and the sound row none");
            at_check(!aiSettings_.sources.onlyListed && aiSettings_.sources.empty(), "no site yet: 'Use only these sites' is off");
            at_check(std::ranges::any_of(aiSettings_.status, [](const ai::ProviderStatus& s) { return s.name == "elevenlabs"; }),
                     "it knows the status of the providers (keys and programs found on this computer)");
            x->before = read_file(x->path);
        });
        // A site that is not a web address, a key and a program typed.
        step(2, [this] {
            AiSettingsDraft& d = aiSettings_;
            d.routes["sound"] = {"elevenlabs", "", ""};
            d.routes["music"] = {"elevenlabs", "", ""};
            d.routes["voice"] = {"elevenlabs", "", "21m00Tcm4TlvDq8ikWAM"};
            d.routes["model3d"] = {"asset-command", "", ""};
            d.command["asset-command"] = "python";
            d.args["asset-command"] = "/tools/gen3d.py --prompt {prompt} --out \"{output}\"";
            d.keys["elevenlabs"] = "xi-autotest-secret-key-123";
            d.sources.onlyListed = true;
            d.sources.images.push_back({"https://opengameart.org/art-search", "CC0 packs"});
            d.sources.models.push_back({"kenney.nl", ""});
            d.sources.fonts.push_back({"not a site", ""});
        });
        snap("editor_ai_settings.png");
        click("aiset:save");
        step(4, [this, x] {
            at_check(aiSettings_.saveError.find("not a web address") != std::string::npos,
                     "a site that is not a web address stops Save and says so (" + aiSettings_.saveError + ")");
            at_check(read_file(x->path) == x->before, "...and the file is left as it was");
            at_check(showAiSettings_ && !aiSettings_.keys.empty(), "...with the window and the typed values still there");
            aiSettings_.sources.fonts.clear();
        });
        click("aiset:save");
        step(6, [this, x] {
            const std::string text = read_file(x->path);
            Json j = Json::parse(text, nullptr, false);
            at_check(!j.is_discarded() && j.is_object(), "Save wrote a JSON object");
            if (!j.is_object()) return;
            at_check(aiSettings_.saveError.empty(), "Save reported no error (" + aiSettings_.saveError + ")");
            at_check(j["limits"]["maxConcurrentRuns"] == 3 && j["roles"]["worker"]["model"] == "sonnet",
                     "the roles and limits of the file stayed");
            at_check(j["assets"]["image"]["provider"] == "fake" && j["assets"]["sound"]["provider"] == "elevenlabs" &&
                         j["assets"]["voice"]["voice"] == "21m00Tcm4TlvDq8ikWAM" && j["assets"]["model3d"]["provider"] == "asset-command",
                     "the asset routes are in the file");
            at_check(j["assetSources"]["onlyListed"] == true && j["assetSources"]["images"][0]["url"] == "https://opengameart.org/art-search" &&
                         j["assetSources"]["images"][0]["note"] == "CC0 packs" && j["assetSources"]["models"][0]["url"] == "kenney.nl",
                     "the sites and 'Use only these sites' are in the file");
            at_check(j["providers"]["elevenlabs"]["apiKey"] == "xi-autotest-secret-key-123", "the typed key is stored under its provider");
            at_check(j["providers"]["asset-command"]["type"] == "asset-command" && j["providers"]["asset-command"]["command"] == "python" &&
                         j["providers"]["asset-command"]["argv"].size() == 5 && j["providers"]["asset-command"]["argv"][4] == "{output}",
                     "the program of the asset-command provider is stored with its arguments split");
#ifndef _WIN32
            std::error_code ec;
            const auto perms = stdfs::status(x->path, ec).permissions();
            at_check((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none,
                     "the file with a key in it is readable only by its owner");
#endif
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.assetSources.onlyListed && aiConfig_.assets.count("voice") && aiConfig_.assets.at("music").provider == "elevenlabs",
                         "the editor's config was reloaded with the new settings");
            }
            at_check(std::ranges::all_of(aiSettings_.keys, [](const auto& kv) { return kv.second.empty(); }), "the typed key is forgotten after Save");
            at_check(std::ranges::none_of(atLog_, [](const std::string& line) { return line.find("xi-autotest-secret-key-123") != std::string::npos; }),
                     "the key is in no line of the autotest log");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        snap("editor_ai_settings_saved.png");
        // Remove the stored key, and a kind back to None.
        step(2, [this] {
            aiSettings_.removeKey.insert("elevenlabs");
            aiSettings_.routes["music"] = {};
        });
        click("aiset:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && (!j.contains("providers") || !j["providers"].contains("elevenlabs")),
                     "Remove stored key takes the key out of the file");
            at_check(j.is_object() && j.contains("assets") && !j["assets"].contains("music") && j["assets"].contains("sound") &&
                         j.contains("assetSources") && j["assetSources"].contains("images"), "a kind set to None leaves the file");
            at_check(j.is_object() && j["roles"]["worker"]["model"] == "sonnet", "the roles stayed again");
        });
        click("aiset:close");
        step(4, [this] {
            at_check(!showAiSettings_, "Close closes the window");
            at_check(aiSettings_.keys.empty() && !aiSettings_.loaded, "...and drops what was typed in it");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

    // ------------------------------------------------------------------------------------------------ Y. Recipes
    section("Y");
    // A made asset (assets.rasterize_svg records a recipe): the Project panel shows a stale badge when its source changed on
    // disk, a banner offers Regenerate / Not now (quiet after Not now), the toolbar Regenerate makes the selected asset again
    // (different pixels, up to date), the banner's Regenerate makes every stale one again, and a deleted source turns the badge
    // into "no src" with Regenerate off.
    {
        struct Recipes {
            std::string manifest, firstPng;
            bool hadManifest = false;
        };
        auto ry = std::make_shared<Recipes>();
        const std::string png = "assets/ay_coin.png", svg = "assets/ay_src.svg", tile = "proj:file:assets/ay_coin.png";
        auto svg_text = [](const char* fill, int size) {
            return std::string("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\"><circle cx=\"32\" cy=\"32\" r=\"") +
                   std::to_string(size) + "\" fill=\"" + fill + "\"/></svg>";
        };
        step(2, [this, ry, project_file, svg_text, png, svg] {
            stop();
            select_id("");
            ry->hadManifest = stdfs::exists(project_file("assets.json"));
            ry->manifest = ry->hadManifest ? read_file(project_file("assets.json")) : std::string();
            write_file(project_file(svg), svg_text("#e03030", 20));
            std::string err;
            CommandResult r = edit_command("at:y:make", "assets.rasterize_svg",
                                           Json::object({{"path", png}, {"source", svg}, {"width", 32}, {"height", 32}}), &err);
            at_check(r.ok, "assets.rasterize_svg made a picture with a recipe: " + err);
            ry->firstPng = read_file(project_file(png));
            showProject_ = true;
            projBrowser_.selected.clear();
            projBrowser_.offeredStale.clear();
            focus_window("Project");
        });
        step(1, [this, tile] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, tile] { return at_visible(tile); };
        });
        step(3, [this, png] {
            const AssetRecipeStatus* st = recipe_of_file(projBrowser_.listing, png);
            at_check(st && !st->stale() && st->missing.empty() && st->command == "assets.rasterize_svg",
                     "the made picture has a recipe and is up to date");
            at_check(!at_visible("recipe:notice"), "no banner while everything is up to date");
        });
        step(2, [project_file, svg, svg_text] { write_file(project_file(svg), svg_text("#3060e0", 26)); });  // the source is saved
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("recipe:notice"); };  // the watcher looks once a second
        });
        step(3, [this, png] {
            const std::vector<std::string> stale = stale_assets(projBrowser_.listing);
            at_check(stale == std::vector<std::string>{png}, "the saved source makes the picture stale");
            at_check(at_visible("recipe:regenerate") && at_visible("recipe:notnow"), "the banner offers Regenerate and Not now");
        });
        snap("editor_recipe_stale.png");
        click("recipe:notnow");
        step(2, [this] { projBrowser_.inputsPolled = -100; });
        step(40, [this] { at_check(!at_visible("recipe:notice"), "Not now hides the banner and it stays quiet"); });
        step(2, [this, png] {
            projBrowser_.selected = png;
            at_check(at_enabled("proj:regenerate"), "the toolbar Regenerate is on for the selected made picture");
        });
        click("proj:regenerate");
        step(6, [this, ry, project_file, png] {
            at_check(read_file(project_file(png)) != ry->firstPng, "Regenerate drew the picture again from the new source");
            const AssetRecipeStatus* st = recipe_of_file(projBrowser_.listing, png);
            at_check(st && !st->stale(), "...and it is up to date again");
            at_check(stale_assets(projBrowser_.listing).empty(), "...so nothing is stale");
        });
        step(2, [this, project_file, svg, svg_text] {
            write_file(project_file(svg), svg_text("#30c060", 14));
            projBrowser_.offeredStale.clear();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("recipe:notice"); };
        });
        click("recipe:regenerate");
        step(6, [this, png] {
            at_check(stale_assets(projBrowser_.listing).empty(), "the banner's Regenerate made the stale picture again");
            at_check(!at_visible("recipe:notice"), "...and the banner is gone");
        });
        step(2, [this, project_file, svg] {
            std::error_code ec;
            stdfs::remove(project_file(svg), ec);
            projBrowser_.recipesDirty = true;
            projBrowser_.stale = true;
            projBrowser_.inputsPolled = -100;
        });
        step(30, [this, png] {
            const AssetRecipeStatus* st = recipe_of_file(projBrowser_.listing, png);
            at_check(st && !st->missing.empty(), "a deleted source is a missing input");
            at_check(!at_enabled("proj:regenerate"), "...and Regenerate is off (it cannot be made again)");
        });
        step(2, [this, ry, project_file, png, svg] {  // put the project back
            std::error_code ec;
            stdfs::remove(project_file(png), ec);
            stdfs::remove(project_file(svg), ec);
            if (ry->hadManifest) write_file(project_file("assets.json"), ry->manifest);
            else stdfs::remove(project_file("assets.json"), ec);
            projBrowser_.selected.clear();
            projBrowser_.offeredStale.clear();
            project_files_changed();
        });
    }

    // ----------------------------------------------------------------------------------------------- Z. Sprite sheets
    section("Z");
    // Sprite sheets: the Project panel previews the sheet that is selected (its clips, played the way a SpriteAnimator plays
    // them, with a menu to change clip), and the Inspector of a SpriteAnimator lists the clips of its Sprite's texture, one click
    // sets `clip` (one undo step).
    {
        struct YState {
            size_t undo = 0;
        };
        auto y = std::make_shared<YState>();
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        step(2, [this, project_file, y] {
            stop();
            select_id("");
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            Image img;
            img.width = 24;
            img.height = 8;
            img.rgba.assign(size_t(24) * 8 * 4, 255);
            for (int x = 0; x < 24; ++x)
                for (int yy = 0; yy < 8; ++yy) {
                    std::uint8_t* px = &img.rgba[(size_t(yy) * 24 + x) * 4];
                    px[0] = std::uint8_t(x / 8 == 0 ? 255 : 40);
                    px[1] = std::uint8_t(x / 8 == 1 ? 255 : 40);
                    px[2] = std::uint8_t(x / 8 == 2 ? 255 : 40);
                }
            at_check(save_png(img, project_file("assets/autotest_sheet.png")).ok(), "a sprite sheet was written for the sheet test");
            write_file(project_file("assets.json"),
                       R"({"format": "factoria.assets/1", "assets": {"assets/autotest_sheet.png": {"sheet": {"columns": 3, "rows": 1,
                          "frameWidth": 8, "frameHeight": 8, "frames": 3, "clips": [
                          {"name": "run", "firstFrame": 0, "lastFrame": 1, "fps": 4, "loop": true},
                          {"name": "idle", "firstFrame": 2, "lastFrame": 2, "fps": 1, "loop": true}]}}}})");
            std::string err;
            CommandResult r = edit_command("at:sheethero", "scene.spawn",
                                           Json::object({{"id", "sheethero"}, {"name", "Sheet Hero"},
                                                         {"components", Json::object({{"Transform", Json::object({{"position", Json::array({300, 250, 0})}})},
                                                                                      {"Sprite", Json::object({{"texture", "assets/autotest_sheet.png"}})},
                                                                                      {"SpriteAnimator", Json::object()}})}}),
                                           &err);
            at_check(r.ok, "an entity with a Sprite and a SpriteAnimator was spawned: " + err);
            projBrowser_.stale = true;
            projBrowser_.query.search = "autotest_sheet";
            projBrowser_.selected = "assets/autotest_sheet.png";
            sheetPreviewPath_.clear();
            showProject_ = true;
            focus_window("Project");
            y->undo = undo_depth();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("sheet:clip") && sheetPreviewFrame_ >= 0; };
        });
        step(30, [this] {
            at_check(sheetPreviewChoice_ == "run", "the preview starts with the first clip of the sheet");
            at_check(sheetPreviewFrame_ == 0 || sheetPreviewFrame_ == 1, "...and shows one of its frames (0 or 1)");
        });
        snap("editor_sheet_preview.png");
        click_widget("sheet:clip");
        step(3, [] {});
        click_widget("sheet:choice:idle");
        step(6, [this] {
            at_check(sheetPreviewChoice_ == "idle", "choosing a clip in the menu plays that clip");
            at_check(sheetPreviewFrame_ == 2, "...the idle clip is the third frame of the sheet");
        });
        step(2, [this] {
            focus_window("Project");
            select_id("sheethero");
            inspScrollTo_ = "SpriteAnimator.clip";
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("insp:SpriteAnimator.clip:run") && at_visible("insp:SpriteAnimator.clip:idle"); };
        });
        step(2, [this, y] {
            at_check(true, "the Inspector lists the clips of the Sprite's texture under SpriteAnimator.clip");
            y->undo = undo_depth();
        });
        click_widget("insp:SpriteAnimator.clip:idle");
        step(5, [this, y] {
            const SpriteAnimator* a = world().get<SpriteAnimator>(world().find_by_id("sheethero"));
            at_check(a && a->clip == "idle", "clicking a clip sets SpriteAnimator.clip");
            at_check(undo_depth() == y->undo + 1, "...as one undo step");
        });
        snap("editor_sheet_inspector.png");
        step(2, [this, project_file] {
            select_id("");
            projBrowser_.selected.clear();
            projBrowser_.query.search.clear();
            std::error_code ec;
            stdfs::remove(project_file("assets.json"), ec);
            stdfs::remove(project_file("assets/autotest_sheet.png"), ec);
            projBrowser_.stale = true;
        });
    }


    section("B2");
    // The Animation panel (docs/EDITOR.md, "Animation panel"): a puppet with an Animator and a Sprite part. New clip makes the
    // clip; in record mode a gizmo drag on the part writes keys at the playhead instead of the rest position; a key is dragged
    // (one undo step) and its easing changed from the context menu; an event is added; a click on the ruler poses the entity
    // without touching the scene; the onion skin draws faded poses.
    {
        struct Bs {
            size_t undo = 0;
            Vec2 grab{}, cur{};
            float firstX = 0, secondX = 0;
        };
        auto b = std::make_shared<Bs>();
        auto click_widget = [this, &step](const std::string& name, int button = 0) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name, button] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), button); });
            step(4, [this, name, button] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), button); });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto clip_now = [this]() -> std::shared_ptr<const ClipAsset> {
            const std::string path = anim_clip_path();
            if (path.empty()) return nullptr;
            auto loaded = load_anim_clip(path);
            return loaded.ok() ? *loaded : nullptr;
        };
        auto position_track = [clip_now]() -> int {
            const auto clip = clip_now();
            if (!clip) return -1;
            for (std::size_t i = 0; i < clip->tracks.size(); ++i)
                if (clip->tracks[i].component == "Transform" && clip->tracks[i].field == "position") return int(i);
            return -1;
        };
        auto key_at = [clip_now, position_track](double t) -> const ClipKey* {
            const auto clip = clip_now();
            const int ti = position_track();
            if (!clip || ti < 0) return nullptr;
            for (const ClipKey& k : clip->tracks[std::size_t(ti)].keys)
                if (std::fabs(double(k.t) - t) < 0.0006) return &k;
            return nullptr;
        };
        auto body_x = [this] { return world().get<Transform>(world().find_by_id("puppet_body"))->position.x; };
        // One gizmo drag by (dx, dy) panel pixels on the X arrow, with the mouse over the viewport.
        auto drag_arrow = [this, &step, &wait_until, b](float dx) {
            step(2, [this, b] {
                b->grab = b->cur = at_widget("gizmo:move:x");
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->grab);
            });
            step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, b->grab); });
            wait_until([this] { return gizmoDrag_.active; });
            step(2, [this, b, dx] {
                b->cur = Vec2{b->grab.x + dx, b->grab.y};
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->cur);
            });
            wait_until([this] { return gizmoDrag_.wrote; });
            step(3, [] {});
            step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, b->cur); });
            wait_until([this] { return !gizmoDrag_.active; });
            step(4, [] {});
        };

        step(2, [this, project_file, b] {
            stop();
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            std::error_code ec;
            stdfs::remove(project_file("anim/clip.anim.json"), ec);
            std::string err;
            CommandResult r = edit_command("at:puppet", "scene.spawn",
                                           Json::object({{"id", "puppet"}, {"name", "Puppet"},
                                                         {"components", Json::object({{"Transform", Json::object({{"position", Json::array({300, 120, 0})}})},
                                                                                      {"Animator", Json::object()}})}}),
                                           &err);
            at_check(r.ok, "a Puppet with an Animator was spawned: " + err);
            r = edit_command("at:puppetbody", "scene.spawn",
                             Json::object({{"id", "puppet_body"}, {"name", "Body"}, {"parent", "puppet"},
                                           {"components", Json::object({{"Transform", Json::object()},
                                                                        {"Sprite", Json::object({{"size", Json::array({60, 60})},
                                                                                                 {"color", Json::array({0.9, 0.5, 0.2, 1})}})}})}}),
                             &err);
            at_check(r.ok, "...with a Sprite part called Body: " + err);
            select_id("puppet_body");
            showAnimation_ = true;
            gizmoMode_ = GizmoMode::Move;
            focus_window("Animation");
            b->undo = undo_depth();
        });
        wait_until([this] { return at_visible("anim:newclip"); });
        step(2, [this] {
            at_check(anim_owner() == world().find_by_id("puppet"), "selecting the Body part makes its parent's Animator the one the panel edits");
            at_check(!at_visible("anim:play"), "...and with no clip yet there is no transport");
        });
        click_widget("anim:newclip");
        wait_until([this] { return at_visible("anim:newclip:create"); });
        click_widget("anim:newclip:create");
        step(6, [this, b] {
            const Animator* a = world().get<Animator>(world().find_by_id("puppet"));
            at_check(a && a->clips.is_object() && a->clips.contains("clip"), "New clip lists the clip in Animator.clips");
            at_check(stdfs::exists(projectDir_ + "/anim/clip.anim.json"), "...and writes anim/clip.anim.json");
            at_check(anim_.clipName == "clip", "...and the panel opens it");
            at_check(at_visible("anim:record") && at_visible("anim:play"), "...so the transport and Record are there");
            at_check(undo_depth() == b->undo + 2, "...as two undo steps: the clip file, then the Animator.clips entry");
            dirty_ = false;  // from here on the checks ask whether record mode, scrubbing and clip edits touch the scene
        });
        click_widget("anim:clips");
        step(3, [this] { at_check(at_visible("anim:clip:clip"), "the clip list names the new clip"); });
        click_widget("anim:clip:clip");
        snap("editor_animation_panel.png");

        // ---- record mode: a gizmo drag writes a key
        click_widget("anim:record");
        step(3, [this] {
            at_check(anim_.recording, "Record turns record mode on");
            select_id("puppet_body");
            anim_set_playhead(0.2);
            focus_window("Animation");
        });
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f}); });
        wait_until([this] { return at_visible("gizmo:move:x"); });
        step(2, [this, b, body_x] {
            b->undo = undo_depth();
            b->firstX = body_x();
        });
        drag_arrow(40);
        step(4, [this, b, key_at, position_track, body_x, clip_now] {
            const int ti = position_track();
            at_check(ti >= 0, "a Transform.position track was made for the Body part in record mode");
            const ClipKey* k = key_at(0.2);
            at_check(k != nullptr, "...with a key at the playhead (0.2 s)");
            if (k) at_check(k->value[0] > b->firstX + 10.0f, "...holding the position the drag reached, not the rest position");
            if (k) b->secondX = k->value[0];
            at_check(anim_.recordedKeys >= 1, "the panel counts the keys record mode wrote");
            at_check(!dirty_, "record mode leaves the scene file unchanged (no unsaved changes)");
            at_check(undo_depth() == b->undo + 1, "the drag is ONE undo step");
            const auto clip = clip_now();
            at_check(clip && clip->tracks.size() >= 1, "the clip file has the track");
            at_check(std::fabs(body_x() - b->secondX) < 0.01f, "the entity shows the recorded pose");
        });
        snap("editor_animation_record.png");
        // a second key at 0.6 s
        step(2, [this] { anim_set_playhead(0.6); });
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f}); });
        wait_until([this] { return at_visible("gizmo:move:x"); });
        drag_arrow(40);
        step(4, [this, key_at, clip_now, position_track, b] {
            const ClipKey* k = key_at(0.6);
            at_check(k != nullptr, "a second drag at 0.6 s writes a second key");
            if (k) at_check(k->value[0] > b->secondX + 10.0f, "...further along");
            const auto clip = clip_now();
            const int ti = position_track();
            at_check(clip && ti >= 0 && clip->tracks[std::size_t(ti)].keys.size() == 3,
                     "the track has the rest key at 0 s (the part stays as it was until the first key) and the two recorded ones (" + [&] {
                         std::string out;
                         if (clip && ti >= 0)
                             for (const ClipKey& k : clip->tracks[std::size_t(ti)].keys) out += std::to_string(k.t) + ":" + std::to_string(k.value[0]) + " ";
                         return out;
                     }() + ")");
            if (k) b->firstX = k->value[0];
            anim_.recording = false;
        });

        // ---- scrubbing poses the entity, the scene is not changed
        click_widget("anim:ruler");
        step(5, [this, b, body_x] {
            at_check(std::fabs(anim_.playhead - 0.5) < 0.05, "a click on the ruler puts the playhead there");
            const float expected = b->secondX + (b->firstX - b->secondX) * float((anim_.playhead - 0.2) / 0.4);
            at_check(std::fabs(body_x() - expected) < 0.5f, "...and poses the Body between the two keys");
            at_check(!dirty_, "scrubbing leaves the scene file unchanged");
            anim_unpose();
            at_check(std::fabs(body_x()) < 0.001f, "...the rest value is what the scene holds (unposed: Body at 0)");
            anim_.dirtyPose = true;
        });

        // ---- move a key, undo it
        // On a small window the dopesheet rows scroll: bring the Position track's keys into the visible part first.
        auto rows_point = [] {  // the visible bottom of the Animation window
            const ImGuiWindow* w = ImGui::FindWindowByName("Animation");
            if (!w) return Vec2{500, 500};
            const float bottom = std::min(w->Pos.y + w->Size.y, ImGui::GetIO().DisplaySize.y - 24.0f);
            return Vec2{w->Pos.x + w->Size.x * 0.5f, bottom - 12.0f};
        };
        scroll_until_at([position_track] { return "anim:key:" + std::to_string(position_track()) + ":600"; }, -6, rows_point, 100000, -1e9f);
        step(3, [this, b, position_track] {
            b->undo = undo_depth();
            at_check(at_visible("anim:key:" + std::to_string(position_track()) + ":600"), "the dopesheet shows the key at 600 ms");
        });
        step(2, [this, b, position_track] {
            b->grab = b->cur = at_widget("anim:key:" + std::to_string(position_track()) + ":600");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->grab);
        });
        step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, b->grab); });
        step(3, [this, b] {
            b->cur = Vec2{b->grab.x + float(anim_time_to_x(0.8) - anim_time_to_x(0.6)), b->grab.y};
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->cur);
        });
        step(3, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{b->cur.x + 0.5f, b->cur.y}); });
        step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, b->cur); });
        step(5, [this, b, key_at] {
            at_check(key_at(0.6) == nullptr && key_at(0.8) != nullptr, "dragging the key moves it from 0.6 s to 0.8 s");
            at_check(undo_depth() == b->undo + 1, "...as ONE undo step");
            undo();
            at_check(key_at(0.6) != nullptr && key_at(0.8) == nullptr, "Undo puts the key back at 0.6 s");
            redo();
            at_check(key_at(0.8) != nullptr, "Redo moves it again");
            undo();
            at_check(!dirty_, "clip edits never mark the scene dirty");
        });

        // ---- easing from the context menu
        step(3, [this, position_track] {
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("anim:key:" + std::to_string(position_track()) + ":200"));
        });
        step(2, [this, b, position_track] {
            b->grab = at_widget("anim:key:" + std::to_string(position_track()) + ":200");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, b->grab, 1);
        });
        step(3, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, b->grab, 1); });
        wait_until([this] { return at_visible("anim:menu:easing"); });
        click_widget("anim:menu:easing");
        wait_until([this] { return at_visible("anim:menu:ease:quadOut"); });
        step(2, [this, b] { b->undo = undo_depth(); });
        click_widget("anim:menu:ease:quadOut");
        step(5, [this, b, key_at] {
            const ClipKey* k = key_at(0.2);
            at_check(k && k->interp == ClipInterp::Ease && k->ease >= 0 && clip_ease_names()[std::size_t(k->ease)] == "quadOut",
                     "the context menu sets the easing of the key to quadOut");
            at_check(undo_depth() == b->undo + 1, "...as one undo step");
        });

        // ---- an event
        scroll_until_at([] { return std::string("anim:addevent"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:addevent");
        wait_until([this] { return at_visible("anim:event:ok"); });
        click_widget("anim:event:ok");
        step(5, [this, clip_now] {
            const auto clip = clip_now();
            at_check(clip && clip->events.size() == 1 && clip->events[0].name == "event", "Add event writes a marker named 'event' into the clip");
            at_check(at_visible("anim:event:0"), "...and the ruler shows it");
        });

        // ---- onion skin
        scroll_until_at([] { return std::string("anim:onion"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:onion");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return anim_.onionDrawn > 0; };
        });
        step(3, [this] { at_check(anim_.onion && anim_.onionDrawn >= 2, "the onion skin draws the poses before and after the playhead (" + std::to_string(anim_.onionDrawn) + " ghosts)"); });
        snap("editor_animation_onion.png");
        scroll_until_at([] { return std::string("anim:onion"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:onion");
        step(4, [this, project_file] {
            at_check(!anim_.onion && anim_.onionDrawn == 0, "turning Onion off draws no ghosts");
            anim_unpose();
            at_check(!dirty_ && undo_depth() > 0, "the whole session left the scene unchanged and the steps are on the undo stack");
            showAnimation_ = false;
            select_id("");
            std::error_code ec;
            stdfs::remove(project_file("anim/clip.anim.json"), ec);
        });
    }

    section("C2");
    // The bone tools (docs/EDITOR.md, "Bone tools"): draw a chain with clicks, bind a sprite to it, paint weights with the brush
    // (one stroke = one undo step), drag an IK target, and the weight overlay follows the selected bone.
    {
        struct Cs {
            size_t undo = 0;
            Vec2 grab{}, cur{};
            Json weights;
            float targetX = 0, targetY = 0, rotBefore = 0;
        };
        auto c = std::make_shared<Cs>();
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // The panel position of a world point (the fixture camera sits at the origin).
        auto panel_of = [this](float x, float y) {
            const Vec2 d = engine_->renderer()->world_to_screen(Vec3{x, y, 0});
            return Vec2{vpImageMin_.x + d.x / float(engine_->renderer()->target_width()) * vpImageSize_.x,
                        vpImageMin_.y + d.y / float(engine_->renderer()->target_height()) * vpImageSize_.y};
        };
        auto vp_click = [this, &step](std::function<Vec2()> where) {
            step(2, [this, where] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, where()); });
            step(2, [this, where] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, where()); });
            step(4, [this, where] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, where()); });
        };
        auto bone_named = [this](const char* name) {
            for (Entity e : world().entities_with(TypeRegistry::global().of<Bone2D>()))
                if (world().info(e).name == name) return e;
            return kNullEntity;
        };

        step(2, [this, project_file, c] {
            stop();
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            std::string err;
            CommandResult r = edit_command("at:rig", "scene.spawn",
                                           Json::object({{"id", "rig"}, {"name", "Rig"},
                                                         {"components", Json::object({{"Transform", Json::object({{"position", Json::array({-300, 50, 0})}})}})}}),
                                           &err);
            at_check(r.ok, "a Rig entity was spawned: " + err);
            r = edit_command("at:limb", "scene.spawn",
                             Json::object({{"id", "limb"}, {"name", "Limb"},
                                           {"components", Json::object({{"Transform", Json::object({{"position", Json::array({200, 100, 0})}})},
                                                                        {"Sprite", Json::object({{"size", Json::array({40, 120})},
                                                                                                 {"color", Json::array({0.3, 0.7, 0.9, 1})}})}})}}),
                             &err);
            at_check(r.ok, "...and a Limb sprite: " + err);
            r = edit_command("at:iktarget", "scene.spawn",
                             Json::object({{"id", "ik_target"}, {"name", "Target"},
                                           {"components", Json::object({{"Transform", Json::object({{"position", Json::array({-200, -20, 0})}})},
                                                                        {"Shape2D", Json::object({{"size", Json::array({10, 10})}})}})}}),
                             &err);
            at_check(r.ok, "...and an IK target: " + err);
            select_id("rig");
            showBoneTools_ = true;
            focus_window("Bone tools");
            c->undo = undo_depth();
        });
        wait_until([this] { return at_visible("bone:tool:chain"); });
        click_widget("bone:tool:chain");
        step(3, [this] { at_check(bone_.tool == BoneTool::Chain, "Draw chain turns the tool on"); });

        // ---- draw a chain: three clicks, two bones
        vp_click([panel_of] { return panel_of(-300, 150); });
        vp_click([panel_of] { return panel_of(-300, 50); });
        vp_click([panel_of] { return panel_of(-300, -50); });
        step(3, [this, c] {
            at_check(bone_.chain.size() == 3, "three clicks in the viewport put three points on the chain");
            at_check(undo_depth() == c->undo, "...and nothing is made until the chain is finished");
            at_check(at_visible("bone:chain:finish") && at_enabled("bone:chain:finish"), "Finish chain is on");
        });
        snap("editor_bone_chain.png");
        click_widget("bone:chain:finish");
        step(5, [this, c, bone_named] {
            const Entity b1 = bone_named("bone_1"), b2 = bone_named("bone_2");
            at_check(!b1.is_null() && !b2.is_null(), "Finish chain makes bone_1 and bone_2");
            at_check(!b1.is_null() && world().parent(b1) == world().find_by_id("rig"), "...the first hangs from the Rig");
            at_check(!b2.is_null() && world().parent(b2) == b1, "...the second from the first");
            at_check(undo_depth() == c->undo + 1, "the chain is ONE undo step");
            undo();
            at_check(bone_named("bone_1").is_null(), "Undo removes the bones");
            redo();
            at_check(!bone_named("bone_1").is_null(), "Redo brings them back");
            at_check(bone_.chain.empty(), "the chain on screen is cleared");
        });

        // ---- bind the sprite
        step(2, [this, bone_named, c] {
            select_id("limb");
            bone_.bindRoot = world().id_of(bone_named("bone_1"));
            bone_.meshColumns = 2;
            bone_.meshRows = 4;
            c->undo = undo_depth();
        });
        scroll_to("bone:bind", "Bone tools");
        click_widget("bone:bind");
        step(5, [this, c] {
            const SpriteSkin* skin = world().get<SpriteSkin>(world().find_by_id("limb"));
            at_check(skin != nullptr, "Bind sprite to bones adds a SpriteSkin to the Limb");
            at_check(skin && skin->bones.is_array() && skin->bones.size() == 2, "...with the two bones");
            const Sprite* sp = world().get<Sprite>(world().find_by_id("limb"));
            at_check(sp && sp->meshColumns == 2 && sp->meshRows == 4, "...and the 2 x 4 mesh");
            at_check(undo_depth() == c->undo + 1, "...as one undo step");
        });

        // ---- weights: the overlay, then a brush stroke
        scroll_to("bone:tool:weights", "Bone tools", 6);
        click_widget("bone:tool:weights");
        step(2, [this] { select_id("limb"); });
        step(5, [this] {
            at_check(bone_.tool == BoneTool::Weights && bone_.weightDots == 15, "the weights tool draws a dot on each of the 15 mesh vertices (" + std::to_string(bone_.weightDots) + ")");
        });
        scroll_to("bone:mode:set", "Bone tools");
        click_widget("bone:mode:set");
        step(3, [this, c] {
            at_check(bone_.mode == 1, "the Set brush mode is on");
            bone_.strength = 1.0f;
            bone_.radius = 40.0f;
            bone_.boneIndex = 0;
            c->undo = undo_depth();
            c->weights = world().get<SpriteSkin>(world().find_by_id("limb"))->weights;
            focus_window("###Viewport");
        });
        step(2, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_of(180, 160)); });
        step(2, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, panel_of(180, 160)); });
        step(3, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_of(180, 130)); });
        step(3, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_of(180, 100)); });
        step(2, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, panel_of(180, 100)); });
        step(5, [this, c] {
            const SpriteSkin* skin = world().get<SpriteSkin>(world().find_by_id("limb"));
            at_check(skin && skin->weights.is_array() && skin->weights.size() == 15, "painting writes explicit weights for the 15 vertices");
            bool full = false;
            if (skin && skin->weights.is_array() && !skin->weights.empty() && skin->weights[0].is_array() && skin->weights[0].size() >= 2)
                full = skin->weights[0][0].get<int>() == 0 && skin->weights[0][1].get<float>() > 0.99f;
            at_check(full, "...the top-left vertex is fully bone_1's");
            at_check(bone_.strokes >= 2, "...with more than one dab along the drag (" + std::to_string(bone_.strokes) + ")");
            at_check(undo_depth() == c->undo + 1, "the whole stroke is ONE undo step");
            undo();
            const SpriteSkin* after = world().get<SpriteSkin>(world().find_by_id("limb"));
            at_check(after && after->weights == c->weights, "Undo puts the weights back");
            redo();
        });
        snap("editor_bone_weights.png");

        // ---- the overlay follows the selected bone
        step(2, [this, bone_named] { select(bone_named("bone_2")); });
        step(4, [this] {
            at_check(bone_.boneIndex == 1, "selecting bone_2 in the Hierarchy picks it as the bone shown");
            at_check(bone_.weightDots == 15, "...the overlay is still on the Limb");
            at_check(bone_.bonesDrawn == 1, "...and the viewport outlines the selected bone (" + std::to_string(bone_.bonesDrawn) + ")");
        });

        // ---- IK: a handle at the target
        step(2, [this, bone_named, c] {
            std::string err;
            const Entity b2 = bone_named("bone_2");
            const CommandResult r = edit_command("at:ik", "scene.set_component",
                                                 Json::object({{"id", world().id_of(b2)}, {"component", "IK2D"},
                                                               {"fields", Json::object({{"target", "ik_target"}, {"chainLength", 2}})}}), &err);
            at_check(r.ok, "an IK2D on bone_2 targets the Target: " + err);
            select_id("rig");
        });
        scroll_to("bone:tool:ik", "Bone tools", 6);
        click_widget("bone:tool:ik");
        step(4, [this, c, bone_named] {
            at_check(bone_.tool == BoneTool::Ik && bone_.ikHandles == 1, "the IK tool draws one handle for the one IK chain");
            c->undo = undo_depth();
            const Transform* t = world().get<Transform>(world().find_by_id("ik_target"));
            c->targetX = t->position.x;
            c->targetY = t->position.y;
            c->rotBefore = world().get<Transform>(bone_named("bone_1"))->rotation.z;
            focus_window("###Viewport");
        });
        step(2, [this, c] {
            c->grab = c->cur = at_widget("bone:ik:Target");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, c->grab);
        });
        step(2, [this, c] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, c->grab); });
        step(3, [this, c] {
            c->cur = Vec2{c->grab.x + 40.0f, c->grab.y - 30.0f};
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, c->cur);
        });
        step(3, [this, c] {
            c->cur = Vec2{c->grab.x + 60.0f, c->grab.y - 50.0f};
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, c->cur);
        });
        step(2, [this, c] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, c->cur); });
        step(5, [this, c, bone_named] {
            const Transform* t = world().get<Transform>(world().find_by_id("ik_target"));
            at_check(t && t->position.x > c->targetX + 20.0f && t->position.y > c->targetY + 20.0f, "dragging the handle moves the IK target");
            at_check(undo_depth() == c->undo + 1, "...as ONE undo step");
            at_check(std::fabs(world().get<Transform>(bone_named("bone_1"))->rotation.z - c->rotBefore) > 0.01f, "...and the bones turned to follow it");
            undo();
            const Transform* back = world().get<Transform>(world().find_by_id("ik_target"));
            at_check(back && std::fabs(back->position.x - c->targetX) < 0.01f, "Undo puts the target back");
            at_check(std::fabs(world().get<Transform>(bone_named("bone_1"))->rotation.z - c->rotBefore) < 0.01f, "...and the bones with it");
        });
        snap("editor_bone_ik.png");
        step(2, [this] {
            bone_.tool = BoneTool::Off;
            showBoneTools_ = false;
            select_id("");
        });
    }

    section("D2");
    // The External tools tab of the AI settings window (docs/EDITOR.md, "AI settings"): a server added with the form (a name that
    // cannot be used stops Apply), Test against a fake MCP server (the key goes out in the header), a Claude Code style JSON pasted,
    // Save writes only "mcpServers" (the other keys of the file stay, owner-only, the key never in the log), Remove, Save again.
    {
        struct DState {
            std::string path, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
            std::shared_ptr<std::string> auth = std::make_shared<std::string>();
        };
        auto x = std::make_shared<DState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_tools_scratch.json";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({
  "limits": { "maxConcurrentRuns": 3 },
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } }
})");
            set_env("FACTORIA_AI_CONFIG", x->path);
            // A fake MCP server: initialize, tools/list, and it remembers the Authorization header it was given.
            auto auth = x->auth;
            aiToolTransport_ = [auth](const ai::HttpRequest& rq) -> ai::HttpResponse {
                ai::HttpResponse rs;
                rs.status = 200;
                if (rq.method == "DELETE") return rs;
                for (const auto& [k, v] : rq.headers) {
                    if (k == "Authorization") *auth = v;
                }
                const Json body = Json::parse(rq.body, nullptr, false);
                const std::string method = body.is_object() ? body.value("method", std::string()) : std::string();
                if (!body.is_object() || !body.contains("id")) {
                    rs.status = 202;
                    return rs;
                }
                Json result = Json::object();
                if (method == "initialize") {
                    result = Json::object({{"protocolVersion", "2025-06-18"},
                                           {"capabilities", Json::object({{"tools", Json::object()}})},
                                           {"serverInfo", Json::object({{"name", "FakeArt"}, {"version", "1.0"}})}});
                } else if (method == "tools/list") {
                    result = Json::object(
                        {{"tools", Json::array({Json::object({{"name", "generate_image"}, {"description", "Makes an image"},
                                                              {"inputSchema", Json::object({{"type", "object"}})}}),
                                                Json::object({{"name", "list_models"}, {"description", "Lists models"},
                                                              {"inputSchema", Json::object({{"type", "object"}})}})})}});
                }
                rs.headers["content-type"] = "application/json";
                rs.body = Json::object({{"jsonrpc", "2.0"}, {"id", body["id"]}, {"result", result}}).dump();
                return rs;
            };
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 3;  // External tools
        });
        step(3, [this] {
            at_check(aiSettings_.tools.servers.empty(), "no tool server yet");
            at_check(at_visible("aiset:tools:add") && at_visible("aiset:tools:paste"), "the External tools tab shows Add server and Paste JSON");
        });
        click("aiset:tools:add");
        step(3, [this] {
            at_check(aiSettings_.tools.editing >= 0 && aiSettings_.tools.adding && at_visible("aiset:tools:apply"), "Add server opens the form");
            auto& e = aiSettings_.tools.edit;
            e.name = "factoria";  // reserved
            e.type = "http";
            e.url = "https://mcp.example.test/mcp";
            e.apiKey = "autotest-tool-key-987";
            e.note = "Makes pixel-art sprites; costs credits per image.";
            e.roles = {"worker", "artist"};
            aiSettings_.tools.editHeaders = "Authorization: Basic {key}";
        });
        scroll_to("aiset:tools:apply", "AI settings###AiSettings");
        click("aiset:tools:apply");
        step(3, [this] {
            at_check(aiSettings_.tools.servers.empty() && aiSettings_.tools.editing >= 0 &&
                         aiSettings_.tools.editError.find("factoria") != std::string::npos,
                     "a reserved name stops Apply and says why (" + aiSettings_.tools.editError + ")");
            aiSettings_.tools.edit.name = "scenario";
        });
        scroll_to("aiset:tools:apply", "AI settings###AiSettings");
        click("aiset:tools:apply");
        step(3, [this] {
            const auto& s = aiSettings_.tools.servers;
            at_check(s.size() == 1 && s[0].name == "scenario" && aiSettings_.tools.editing < 0, "Apply adds the server and closes the form");
            at_check(s.size() == 1 && s[0].headers.size() == 1 && s[0].headers[0].first == "Authorization" &&
                         s[0].headers[0].second == "Basic {key}" && s[0].roles.size() == 2,
                     "...with its header and roles");
        });
        scroll_to("aiset:tools:test:scenario", "AI settings###AiSettings");
        click("aiset:tools:test:scenario");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiToolTestRunning_.load(); };
        });
        step(3, [this, x] {
            std::string text;
            {
                std::lock_guard<std::mutex> lock(aiSettings_.tools.tests->mu);
                text = aiSettings_.tools.tests->text["scenario"];
            }
            at_check(text.find("Connected to FakeArt") != std::string::npos && text.find("2 tools") != std::string::npos &&
                         text.find("generate_image") != std::string::npos,
                     "Test connects and lists the tools (" + text + ")");
            at_check(*x->auth == "Basic autotest-tool-key-987", "...and the key went out in the Authorization header");
        });
        // A Claude Code style JSON.
        click("aiset:tools:paste");
        step(3, [this] {
            at_check(aiSettings_.tools.showPaste && at_visible("aiset:tools:import"), "Paste JSON opens the paste box");
            aiSettings_.tools.pasteText = R"({"mcpServers":{"fs":{"command":"npx","args":["-y","some-mcp","--root","/tmp/my dir"],"env":{"MODE":"fast"},"disabled":true}}})";
        });
        click("aiset:tools:import");
        step(3, [this] {
            const auto& s = aiSettings_.tools.servers;
            at_check(s.size() == 2 && s[1].name == "fs" && s[1].is_stdio() && s[1].command == "npx" && s[1].args.size() == 4 &&
                         s[1].args[3] == "/tmp/my dir" && s[1].env.count("MODE"),
                     "Import adds the pasted stdio server (" + aiSettings_.tools.pasteMessage + ")");
            at_check(aiSettings_.tools.pasteMessage.find("disabled") != std::string::npos, "...and says which keys FactorIA does not use");
        });
        snap("editor_ai_tools.png");
        click("aiset:tools:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && aiSettings_.tools.saveError.empty(), "Save wrote a JSON object (" + aiSettings_.tools.saveError + ")");
            if (!j.is_object()) return;
            at_check(j["limits"]["maxConcurrentRuns"] == 3 && j["roles"]["worker"]["model"] == "sonnet", "the other keys of the file stayed");
            at_check(j["mcpServers"]["scenario"]["url"] == "https://mcp.example.test/mcp" && j["mcpServers"]["scenario"]["apiKey"] == "autotest-tool-key-987" &&
                         j["mcpServers"]["scenario"]["headers"]["Authorization"] == "Basic {key}" && j["mcpServers"]["scenario"]["roles"].size() == 2,
                     "the server is in the file with its header, key and roles");
            at_check(j["mcpServers"]["fs"]["command"] == "npx" && j["mcpServers"]["fs"]["args"].size() == 4, "the program server is in the file");
#ifndef _WIN32
            std::error_code ec;
            const auto perms = stdfs::status(x->path, ec).permissions();
            at_check((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none,
                     "the file with a key in it is readable only by its owner");
#endif
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.toolServers.size() == 2, "the editor's config was reloaded with the servers");
            }
            at_check(std::ranges::none_of(atLog_, [](const std::string& line) { return line.find("autotest-tool-key-987") != std::string::npos; }),
                     "the key is in no line of the autotest log");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        click("aiset:tools:remove:fs");
        click("aiset:tools:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j["mcpServers"].contains("scenario") && !j["mcpServers"].contains("fs"), "Remove and Save take the server out of the file");
            at_check(j.is_object() && j["roles"]["worker"]["model"] == "sonnet", "the other keys stayed again");
        });
        click("aiset:tools:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded && aiSettings_.tools.servers.empty(), "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            aiToolTransport_ = nullptr;
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

    section("E2");
    // Feedback sharing (docs/EDITOR.md, "Feedback sharing"): the consent dialog writes the mode, the review list of the "ask" mode
    // sends one entry and drops another, the Engine Feedback panel's share column and share boxes (suggest, limits, sanitizer),
    // Review with AI against a mock model, Feedback Settings (GitHub sign-in with a code on screen, sign-out, reset id, Send now
    // against a server that is down and then up) and the mode radio buttons. The client talks to the fake server of on_init: no
    // network, and the settings and the outbox live in the autotest's own folder.
    {
        struct EState {
            std::string path, installBefore;
            std::optional<ai::AiConfig> savedConfig;
            ImGuiID row = 0, sibling = 0;  // the dock row of the panel made taller for this section, and the one it took from
            float grown = 0;
        };
        auto x = std::make_shared<EState>();
        // The bottom row of the dock gives the panel under 200 px on a small display (the macOS runner's 1024x642), where the
        // table leaves the share boxes a few pixels: the row grows to 440 px for this section and gets its height back after.
        auto grow_panel_row = [x](bool grow) {
            if (!grow) {
                ImGuiDockNode* row = ImGui::DockBuilderGetNode(x->row);
                ImGuiDockNode* sib = ImGui::DockBuilderGetNode(x->sibling);
                if (row && sib) row->SizeRef.y -= x->grown, sib->SizeRef.y += x->grown;
                x->grown = 0;
                return;
            }
            const ImGuiWindow* w = panel_window("Engine Feedback");
            ImGuiDockNode* row = w ? w->DockNode : nullptr;
            while (row && row->ParentNode && row->ParentNode->SplitAxis != ImGuiAxis_Y) row = row->ParentNode;
            if (!row || !row->ParentNode) return;  // floating: it has its own size
            ImGuiDockNode* sib = row->ParentNode->ChildNodes[0] == row ? row->ParentNode->ChildNodes[1] : row->ParentNode->ChildNodes[0];
            if (!sib) return;
            x->grown = std::clamp(440.0f - row->Size.y, 0.0f, std::max(0.0f, sib->Size.y - 120.0f));
            x->row = row->ID;
            x->sibling = sib->ID;
            row->SizeRef.y += x->grown;
            sib->SizeRef.y -= x->grown;
        };
        auto entry_of = [x](const std::string& id) -> Json {
            auto doc = load_feedback(x->path);
            if (doc && doc->contains("entries"))
                for (const Json& e : (*doc)["entries"])
                    if (e.value("id", std::string()) == id) return e;
            return Json::object();
        };
        auto shared_of = [entry_of](const std::string& id) {
            const Json e = entry_of(id);
            return e.contains("shared") ? e["shared"].value("status", std::string()) : std::string();
        };
        auto reports = [this] {
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            return atShareNet_->reportBodies.size();
        };
        auto add_entry = [x](const std::string& title, const std::string& missing, const Json& share) {
            FeedbackInput in;
            in.category = feedback_categories().front();
            in.severity = "minor";
            in.title = title;
            in.missing = missing;
            in.workaround = "Edited the scene file by hand.";
            in.reporter = Json::object({{"kind", "human"}, {"agent", "factoria-editor"}});
            in.share = share;
            (void)add_feedback_entry_to_file(x->path, in, "Autotest Platformer");
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        step(2, [this, x, add_entry] {
            x->path = projectDir_ + "/" + engine_->project().feedbackFile;
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(projectDir_ + "/ENGINE_FEEDBACK.archive.json", ec);
            const ShareEnv& env = share_env();
            ShareSettings st = load_share_settings(env);
            st.mode = ShareMode::Unset;  // the harness starts the dialog's story: nothing chosen yet (only a click sets a mode in the product)
            (void)save_share_settings(env, st);
            (void)save_outbox(env, Outbox{});
            {
                std::lock_guard<std::mutex> lock(atShareNet_->mu);
                atShareNet_->urls.clear();
                atShareNet_->reportBodies.clear();
            }
            atShareNet_->authorize = false;
            atShareNet_->failReports = false;
            ShareUi& s = share_;
            s.consentOpen = s.consentLater = s.settingsOpen = s.reviewOpen = false;
            s.waiting.clear();
            s.notified.clear();
            s.editId.clear();
            s.newShare = ShareFields{};
            s.reviewShown = Json();
            s.mode = ShareMode::Unset;
            s.docFile.clear();
            s.docStamp = INT64_MIN;
            s.tickAt = -10;
            const Json one = Json::object(
                {{"title", "No one-way platforms"},
                 {"missing", "Collider2D has no one-way option, so a body cannot pass up through a platform and land on it."},
                 {"suggestion", "Add Collider2D.oneWay (bool)."}});
            const Json two = Json::object({{"title", "Pause cannot stop particles"},
                                           {"missing", "ParticleEmitter keeps emitting while the game is paused and there is no way to freeze it."}});
            add_entry("Jump-through platforms are impossible", "The player of SecretLevelName cannot jump up through its platforms.", one);
            add_entry("Pause menu cannot freeze particles", "Particles keep running in SecretLevelName while paused.", two);
            add_entry("Autotest Platformer needs a screen shake helper", "The Autotest Platformer game has no helper to shake the screen after a hit, so every script rolls its own.", Json());
            fbSelected_.clear();
            fbAddOpen_ = false;
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
            showFeedback_ = true;
            focus_window("Engine Feedback");
        });
        step(2, [grow_panel_row] { grow_panel_row(true); });
        // ---- the consent dialog
        wait_until([this] { return share_.consentOpen; });
        step(3, [this, x] {
            at_check(at_visible("share:consent:always") && at_visible("share:consent:ask") && at_visible("share:consent:never") &&
                         at_visible("share:consent:later"),
                     "a project with feedback entries and no answer asks: Always, Ask me each time, Never and Decide later");
            at_check(share_.consentEntries == 2 && share_.consentPreview.find("No one-way platforms") != std::string::npos &&
                         share_.consentPreview.find("Pause cannot stop particles") != std::string::npos,
                     "the dialog previews the next report: the two share texts");
            at_check(share_.consentPreview.find("SecretLevelName") == std::string::npos &&
                         share_.consentPreview.find("Edited the scene") == std::string::npos &&
                         share_.consentPreview.find("Autotest Platformer") == std::string::npos,
                     "...without the entries' own text, the project's name or its workaround");
            at_check(load_share_settings(share_env()).mode == ShareMode::Unset, "nothing is chosen until a click");
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            at_check(atShareNet_->urls.empty(), "the dialog sends nothing");
            (void)x;
        });
        snap("editor_share_consent.png");
        click("share:consent:ask");
        step(3, [this] {
            at_check(load_share_settings(share_env()).mode == ShareMode::Ask && !share_.consentOpen, "Ask me each time writes the mode and closes the dialog");
        });
        // ---- ask mode: the review list
        wait_until([this] { return share_.waiting.size() == 2 && at_visible("share:notify"); });
        step(2, [this, entry_of, reports] {
            at_check(share_column(entry_of("FB-0001")).label == "waiting" && share_column(entry_of("FB-0002")).label == "waiting",
                     "the entries with a share text wait in ask mode");
            at_check(share_column(entry_of("FB-0003")).label == "-", "an entry without a share text is not shared");
            at_check(reports() == 0, "ask mode sends nothing before the answer");
        });
        click("share:notify");
        step(3, [this] {
            at_check(share_.reviewOpen && at_visible("share:review:send:FB-0001") && at_visible("share:review:drop:FB-0001") &&
                         at_visible("share:review:send:FB-0002") && at_visible("share:review:sendall") && at_visible("share:review:dropall"),
                     "the notification opens the review list: Send and Don't send for each entry, and for all");
        });
        snap("editor_share_review.png");
        click("share:review:drop:FB-0001");
        step(3, [this, shared_of, reports] {
            at_check(shared_of("FB-0001") == "skipped" && reports() == 0, "Don't send marks the entry skipped and sends nothing");
        });
        click("share:review:send:FB-0002");
        wait_until([shared_of] { return shared_of("FB-0002") == "sent"; });
        step(3, [this, entry_of, reports] {
            at_check(reports() == 1, "Send sends the confirmed entry in one request");
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            const std::string body = atShareNet_->reportBodies.empty() ? std::string() : atShareNet_->reportBodies[0];
            at_check(body.find("Pause cannot stop particles") != std::string::npos && body.find("FB-0002") != std::string::npos,
                     "the report carries the share text of FB-0002");
            at_check(body.find("FB-0001") == std::string::npos && body.find("SecretLevelName") == std::string::npos &&
                         body.find("Edited the scene") == std::string::npos && body.find("Autotest Platformer") == std::string::npos,
                     "...and nothing of the dropped entry, the entries' own text or the project's name");
            at_check(load_share_settings(share_env()).mode == ShareMode::Ask, "sending changed no setting");
            at_check(share_column(entry_of("FB-0001")).label == "skipped" && share_column(entry_of("FB-0002")).label == "sent",
                     "the share column reads skipped and sent");
            share_.reviewOpen = false;  // out of the way of the panel
            fbSelected_ = "FB-0003";
            focus_window("Engine Feedback");
        });
        // ---- the panel: the share column and the share boxes
        wait_until([this] { return at_visible("feedback:share:FB-0001") && at_visible("feedback:share:FB-0002") && at_visible("feedback:share:suggest"); });
        step(2, [this] { at_check(at_visible("feedback:share:FB-0003"), "the table has a share column for every entry"); });
        // the boxes are in the scrolling detail of the panel: the wheel goes over it
        auto detail_at = [this] {
            auto it = atWidgets_.find("feedback:detail");
            return it == atWidgets_.end() ? Vec2{500, 300} : it->second;
        };
        auto scroll_detail_to = [&scroll_until_at, detail_at](const std::string& name) {
            scroll_until_at([name] { return name; }, -6, detail_at, 100000, -1e9f);
        };
        scroll_detail_to("feedback:share:suggest");
        click("feedback:share:suggest");
        step(3, [this] {
            at_check(!share_.edit.title.empty() && share_.edit.title.find("Autotest Platformer") == std::string::npos &&
                         share_.edit.missing.find("Autotest Platformer") == std::string::npos && !share_.editMessage.empty(),
                     "Suggest fills the boxes from the entry with the project's name taken out (" + share_.editMessage + ")");
            share_.edit.title = "short";  // under the 8 characters of the limit
        });
        scroll_detail_to("feedback:share:save");
        click("feedback:share:save");
        step(3, [this, entry_of] {
            at_check(share_.editMessage.find("share.title is too short") == 0 && !entry_of("FB-0003").contains("share"),
                     "Save checks the limits: a title under 8 characters is not stored (" + share_.editMessage + ")");
            share_.edit.title = "Autotest Platformer lacks a screen shake helper";  // the sanitizer takes the name out again
        });
        scroll_detail_to("feedback:share:save");
        click("feedback:share:save");
        wait_until([shared_of] { return shared_of("FB-0003") == "pending"; });
        step(3, [this, entry_of] {
            const Json e = entry_of("FB-0003");
            at_check(e.contains("share") && e["share"].value("title", std::string()).find("Autotest Platformer") == std::string::npos &&
                         !e["share"].value("title", std::string()).empty(),
                     "Save sanitizes again: the stored title has no project name (" + e.value("share", Json::object()).dump() + ")");
            at_check(share_.editMessage.find("The sanitizer took out") != std::string::npos, "...and says what it took out (" + share_.editMessage + ")");
            at_check(share_column(e).label == "waiting" && !e.value("reviewed", false), "the saved text waits for the answer, not yet reviewed");
        });
        // ---- Review with AI
        step(2, [this, x] {
            aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
                return std::shared_ptr<ai::ChatProvider>(std::make_shared<ShareReviewProvider>());
            };
            std::lock_guard<std::mutex> lock(aiMu_);
            x->savedConfig = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            for (const char* role : {ai::kRoleOrchestrator, ai::kRoleFast}) {
                ai::RoleConfig& rc = aiConfig_.roles[role];
                rc.provider = "anthropic";
                rc.model = "mock";
            }
        });
        scroll_detail_to("feedback:share:review");
        click("feedback:share:review");
        wait_until([this] { return !share_.aiRunning && share_.reviewShown.is_object() && at_visible("feedback:share:review-result"); });
        step(3, [this, entry_of, reports] {
            at_check(share_.reviewShown.is_object() && share_.reviewShown.value("pass", false) && entry_of("FB-0003").value("reviewed", false),
                     "Review with AI passes the text and marks the entry reviewed (" + share_.reviewShown.dump() + ")");
            at_check(at_visible("feedback:share:review-result"), "the panel shows the result of the review");
            at_check(load_share_settings(share_env()).mode == ShareMode::Ask && reports() == 1, "the review changed no setting and sent nothing");
            aiFactory_ = nullptr;
        });
        step(2, [this, x] {
            std::lock_guard<std::mutex> lock(aiMu_);
            if (x->savedConfig) aiConfig_ = std::move(*x->savedConfig);
            x->savedConfig.reset();
        });
        // "Don't send any" from the list that FB-0003 puts up again
        wait_until([this] { return at_visible("share:notify"); });
        click("share:notify");
        step(3, [this] { at_check(share_.reviewOpen && at_visible("share:review:dropall"), "a new waiting entry notifies again"); });
        click("share:review:dropall");
        step(3, [this, shared_of] {
            at_check(shared_of("FB-0003") == "skipped" && share_.waiting.empty(), "Don't send any drops everything that waits");
            share_.reviewOpen = false;
            focus_window("Engine Feedback");
        });
        // ---- Feedback Settings: GitHub sign-in
        wait_until([this] { return at_visible("feedback:settings"); });
        click("feedback:settings");
        step(3, [this] {
            at_check(share_.settingsOpen && at_visible("share:settings:mode:always") && at_visible("share:settings:mode:ask") &&
                         at_visible("share:settings:mode:never") && at_visible("share:settings:installid"),
                     "Sharing... opens Feedback Settings with the three modes and the installation id");
        });
        wait_until([this] { return at_visible("share:settings:signin"); });
        click("share:settings:signin");
        wait_until([this] {
            std::lock_guard<std::mutex> lock(share_.mu);
            return share_.haveCode && at_visible("share:settings:code");
        });
        step(3, [this] {
            at_check(share_.code.userCode == "ABCD-1234" && at_visible("share:settings:url") && at_visible("share:settings:open") &&
                         at_visible("share:settings:cancel"),
                     "Sign in shows the device code, the address, a button that opens it and Cancel");
        });
        snap("editor_share_signin.png");
        click("share:settings:open");
        step(3, [this] {
            at_check(share_.settingsMessage.find("(autotest) would open https://github.com/login/device") != std::string::npos,
                     "Open in browser opens the address (not in the autotest: " + share_.settingsMessage + ")");
            atShareNet_->authorize = true;  // the person approved the code on github.com
        });
        wait_until([this] { return load_share_settings(share_env()).login == "octocat" && at_visible("share:settings:signout"); });
        step(3, [this] {
            at_check(at_visible("share:settings:login") && !load_share_settings(share_env()).credential.empty(),
                     "the sign-in finishes by itself and shows the login");
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            int exchanges = 0;
            for (const std::string& u : atShareNet_->urls)
                if (u == "POST https://feedback.autotest.invalid/v1/auth/github") ++exchanges;
            at_check(exchanges == 1, "the GitHub token was exchanged once with the feedback server");
        });
        click("share:settings:signout");
        step(3, [this] {
            at_check(load_share_settings(share_env()).credential.empty() && load_share_settings(share_env()).login.empty(), "Sign out forgets the credential and the login");
        });
        // ---- installation id
        step(2, [this, x] {
            x->installBefore = load_share_settings(share_env()).installId;
            at_check(is_uuid_v4(x->installBefore), "the first report made an installation id (" + x->installBefore + ")");
        });
        wait_until([this] { return at_visible("share:settings:resetid") && at_enabled("share:settings:resetid"); });
        click("share:settings:resetid");
        step(3, [this, x] {
            const std::string now = load_share_settings(share_env()).installId;
            at_check(is_uuid_v4(now) && now != x->installBefore, "Reset id makes a new installation id");
        });
        // ---- Always, a server that is down, Send now
        step(2, [this, add_entry] {
            atShareNet_->failReports = true;
            add_entry("Sprites cannot be tinted by a gradient", "SpriteRenderer only has a flat tint, so a gradient needs a custom material.",
                      Json::object({{"title", "Sprites cannot be tinted by a gradient"},
                                    {"missing", "SpriteRenderer only has a flat tint color, so a gradient across one sprite needs a custom material."}}));
        });
        click("share:settings:mode:always");
        step(3, [this] { at_check(load_share_settings(share_env()).mode == ShareMode::Always, "the Always radio button writes the mode"); });
        wait_until([this] {
            const Json st = share_status(share_env());
            return st["outbox"]["failed"].size() == 1 && at_enabled("share:settings:sendnow");
        });
        step(3, [this, shared_of] {
            at_check(shared_of("FB-0004") == "pending" && at_visible("share:settings:outbox"), "a server that is down leaves the entry in the outbox, which the window shows");
            atShareNet_->failReports = false;
        });
        click("share:settings:sendnow");
        wait_until([shared_of] { return shared_of("FB-0004") == "sent"; });
        step(3, [this, reports] { at_check(reports() == 2 || reports() == 3, "Send now sent what was waiting once the server answered"); });
        click("share:settings:mode:never");
        step(3, [this, grow_panel_row] {
            at_check(load_share_settings(share_env()).mode == ShareMode::Never && load_outbox(share_env()).items.empty(),
                     "the Never radio button writes the mode and the outbox is empty");
            share_.settingsOpen = false;
            grow_panel_row(false);
        });
    }

    section("E3");
    // The Extensions tab of the AI settings window (docs/EDITOR.md, "AI settings"): a plugin folder added with the form, hooks pasted,
    // a role switched off, Save writing only "extensions" (the other keys of ai.json stay, owner-only); then the project's own
    // file: a skill and hooks kept "only for this project", the hooks not running until Trust this project, and the trust dropped
    // when the file changes.
    {
        // The Skills table above the Add row pushes the form below the fold of the window: scroll to a widget of the body, then click it.
        const auto scroll_click = [&](const std::string& name, float dy = -6) {
            scroll_to(name, "AI settings###AiSettings", dy);
            click(name);
        };
        struct EState {
            std::string path, previousEnv, plugin, skill, projectFileText, claudeFile, claudeBackup;
            bool hadEnv = false, hadClaudeFile = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<EState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_ext_scratch.json";
            x->plugin = atOutDir_ + "/ext_plugin";
            x->skill = projectDir_ + "/skills/autotest_gdd";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({
  "limits": { "maxConcurrentRuns": 3 },
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } }
})");
            write_file(x->plugin + "/.claude-plugin/plugin.json", R"({"name":"ext_plugin","version":"1.0.0"})");
            write_file(x->skill + "/SKILL.md", "---\nname: autotest-gdd\ndescription: A skill for the autotest.\n---\nBody.\n");
            std::error_code ec;
            stdfs::remove(projectDir_ + "/.factoria/extensions.json", ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            // The project's own Claude Code settings run a program: the trust below covers them too.
            x->claudeFile = projectDir_ + "/.claude/settings.local.json";
            x->hadClaudeFile = stdfs::exists(x->claudeFile, ec);
            if (x->hadClaudeFile) x->claudeBackup = read_file(x->claudeFile);
            write_file(x->claudeFile, R"j({"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo autotest"}]}]}})j");
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
        });
        scroll_to("aiset:ext:hooks", "AI settings###AiSettings");
        step(3, [this] {
            at_check(aiSettings_.ext.user.empty() && aiSettings_.ext.project.empty(), "no extension yet");
            at_check(at_visible("aiset:ext:add") && at_visible("aiset:ext:hooks"), "the Extensions tab shows Add and Paste hooks JSON");
        });
        // A plugin folder.
        step(3, [this, x] { aiSettings_.ext.addPath = x->plugin; });
        scroll_click("aiset:ext:add");
        step(3, [this, x] {
            const auto& u = aiSettings_.ext.user;
            at_check(u.size() == 1 && u[0].kind == ai::ExtensionKind::Plugin && u[0].name == "ext_plugin" && u[0].source == "user",
                     "Add puts the plugin folder in the list under the folder's name (" + aiSettings_.ext.addError + ")");
            at_check(u.size() == 1 && ai::resolve_extension_path(u[0], "", ai::system_env()) == stdfs::path(x->plugin).lexically_normal().string(),
                     "...with a path that leads back to the folder");
            at_check(aiSettings_.ext.addError.empty() && aiSettings_.ext.addPath.empty(), "...and the add row is empty again");
        });
        // A relative path cannot be kept in ai.json: it teaches.
        step(3, [this] {
            aiSettings_.ext.addPath = "plugins/relative";
            aiSettings_.ext.addName = "rel";
        });
        scroll_click("aiset:ext:add");
        step(3, [this] {
            at_check(aiSettings_.ext.user.size() == 1 && aiSettings_.ext.addError.find("~/") != std::string::npos,
                     "a relative path is refused with the way to write it (" + aiSettings_.ext.addError + ")");
            aiSettings_.ext.addPath.clear();
            aiSettings_.ext.addName.clear();
            aiSettings_.ext.addError.clear();
        });
        // Pasted hooks.
        scroll_click("aiset:ext:hooks");
        scroll_to("aiset:ext:hooks-import", "AI settings###AiSettings");
        step(3, [this] {
            at_check(aiSettings_.ext.showHooks && at_visible("aiset:ext:hooks-import"), "Paste hooks JSON opens the paste box");
            aiSettings_.ext.hooksText = R"({"hooks":{"PostToolUsee":[]}})";
        });
        scroll_click("aiset:ext:hooks-import");
        step(3, [this] {
            at_check(aiSettings_.ext.user.size() == 1 && aiSettings_.ext.hooksMessage.find("PostToolUse") != std::string::npos,
                     "hooks with a misspelled event are refused with the right name (" + aiSettings_.ext.hooksMessage + ")");
            aiSettings_.ext.hooksText = R"({"hooks":{"PostToolUse":[{"matcher":"Edit|Write","hooks":[{"type":"command","command":"echo edited"}]}]}})";
            aiSettings_.ext.hooksName = "log";
        });
        scroll_click("aiset:ext:hooks-import");
        step(3, [this] {
            const auto& u = aiSettings_.ext.user;
            at_check(u.size() == 2 && u[1].kind == ai::ExtensionKind::Hooks && u[1].name == "log" && u[1].hooks.contains("PostToolUse"),
                     "Import hooks adds them (" + aiSettings_.ext.hooksMessage + ")");
        });
        // A role off.
        scroll_click("aiset:ext:role:plugin:ext_plugin:fast");
        step(3, [this] {
            const auto& r = aiSettings_.ext.user[0].roles;
            at_check(r.size() == 4 && std::ranges::find(r, std::string("fast")) == r.end() && std::ranges::find(r, std::string("worker")) != r.end(),
                     "switching fast off lists the other four default roles");
        });
        scroll_click("aiset:ext:inherit", -2);  // small steps: the page is long and one big step jumps over it
        step(3, [this] { at_check(!aiSettings_.ext.inherit, "the inherit box switches off"); });
        snap("editor_ai_extensions.png");
        click("aiset:ext:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && aiSettings_.ext.saveError.empty(), "Save wrote a JSON object (" + aiSettings_.ext.saveError + ")");
            if (!j.is_object()) return;
            at_check(j["limits"]["maxConcurrentRuns"] == 3 && j["roles"]["worker"]["model"] == "sonnet", "the other keys of the file stayed");
            const Json& e = j["extensions"];
            at_check(e.is_object() && e.value("inheritUserPlugins", true) == false, "inheritUserPlugins: false is in the file");
            at_check(e.contains("plugins") && e["plugins"].contains("ext_plugin") && e["plugins"]["ext_plugin"]["roles"].size() == 4,
                     "the plugin is in the file with its roles");
            at_check(e.contains("hooks") && e["hooks"]["log"]["hooks"]["PostToolUse"][0]["hooks"][0]["command"] == "echo edited", "the hooks are in the file");
#ifndef _WIN32
            std::error_code ec;
            const auto perms = stdfs::status(x->path, ec).permissions();
            at_check((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none, "the file is readable only by its owner");
#endif
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.extensions.entries.size() == 2 && !aiConfig_.extensions.inheritUserPlugins, "the editor's config was reloaded with the extensions");
            }
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        // The project's own file: a skill (text, needs no trust) and hooks (run a program, need it).
        step(3, [this, x] {
            at_check(aiSettings_.ext.saveError.empty() && aiSettings_.ext.user.size() == 2, "the draft was rebuilt from the saved file");
            aiSettings_.ext.addKind = 1;
            aiSettings_.ext.addToProject = true;
            aiSettings_.ext.addPath = x->skill;
        });
        scroll_click("aiset:ext:add");
        step(3, [this] {
            const auto& p = aiSettings_.ext.project;
            at_check(p.size() == 1 && p[0].kind == ai::ExtensionKind::Skill && p[0].path == "skills/autotest_gdd" && p[0].source == "project",
                     "a skill added \"only for this project\" is kept relative to the project (" + aiSettings_.ext.addError + ")");
            aiSettings_.ext.showHooks = true;
            aiSettings_.ext.hooksText = R"({"Stop":[{"hooks":[{"type":"command","command":"echo project-hook"}]}]})";
            aiSettings_.ext.hooksName = "stop-log";
        });
        scroll_click("aiset:ext:hooks-import");
        step(3, [this] {
            const auto& p = aiSettings_.ext.project;
            at_check(p.size() == 2 && p[1].kind == ai::ExtensionKind::Hooks && p[1].source == "project", "pasted hooks can be kept for the project too");
        });
        click("aiset:ext:save");
        step(6, [this] {
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            at_check(pe.exists && pe.error.empty() && pe.entries.size() == 2, "Save wrote the project's .factoria/extensions.json (" + pe.error + ")");
            at_check(!aiSettings_.ext.projectTrusted, "a project's hooks are not trusted just because they were saved");
            aiSettings_.ext.statusAt = -10;
        });
        step(3, [this] {
            const auto it = aiSettings_.ext.status.find("hooks:project:stop-log");
            at_check(it != aiSettings_.ext.status.end() && it->second.find("not trusted") != std::string::npos,
                     "the hooks of the project show as not trusted");
            const auto skill = aiSettings_.ext.status.find("skill:project:autotest_gdd");
            at_check(skill != aiSettings_.ext.status.end() && skill->second.empty(), "...while the skill (text) is ready");
        });
        scroll_click("aiset:ext:review");
        step(3, [this] {
            at_check(aiSettings_.ext.showTrust && at_visible("aiset:ext:trust"), "Review what would run opens the list and the Trust button");
            at_check(aiSettings_.ext.claudeGrants.size() == 1 && aiSettings_.ext.claudeGrants[0].find("settings.local.json: hooks (SessionStart)") != std::string::npos,
                     "...which also lists what the project's .claude/settings.local.json would run");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            const ai::ExtensionPlan plan = ai::plan_extensions(cfg, ai::default_config().providers.at("claude-code"), "worker",
                                                               ai::make_extension_context(cfg, projectDir_, ai::system_env()));
            at_check(plan.projectSettingsOff, "until then a Claude Code run starts without the project's .claude settings");
        });
        scroll_to("aiset:ext:trust", "AI settings###AiSettings");  // the list of what would run grew: the button is below the fold
        snap("editor_ai_extensions_trust.png");
        click("aiset:ext:trust");
        step(4, [this, x] {
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            const ai::ClaudeProjectSettings claude = ai::load_claude_project_settings(projectDir_);
            at_check(aiSettings_.ext.projectTrusted && claude.needs_trust() &&
                         ai::project_extensions_trusted(ai::extensions_trust_path(x->path), projectDir_, pe.hash, nullptr, false, claude.hash),
                     "Trust this project records the trust for both the extensions file and .claude/settings*.json (" + aiSettings_.ext.trustMessage + ")");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            ai::ExtensionContext ctx = ai::make_extension_context(cfg, projectDir_, ai::system_env());
            const ai::ExtensionPlan plan = ai::plan_extensions(cfg, ai::default_config().providers.at("claude-code"), "worker", ctx);
            at_check(plan.hooks.is_object() && plan.hooks.contains("Stop"), "a Claude Code run for the worker now gets the project's hooks");
            at_check(!plan.projectSettingsOff, "...and loads the project's own .claude settings");
            x->projectFileText = read_file(projectDir_ + "/.factoria/extensions.json");
        });
        // The file changes behind the editor's back (an AI edit): the trust ends.
        step(2, [this, x] {
            Json j = Json::parse(x->projectFileText);
            j["hooks"]["stop-log"]["hooks"]["Stop"][0]["hooks"][0]["command"] = "echo something-else";
            write_file(projectDir_ + "/.factoria/extensions.json", j.dump(2));
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            at_check(!ai::project_extensions_trusted(ai::extensions_trust_path(x->path), projectDir_, pe.hash, nullptr, false,
                                                     ai::load_claude_project_settings(projectDir_).hash),
                     "an edited project file is no longer trusted");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            const ai::ExtensionPlan plan = ai::plan_extensions(cfg, ai::default_config().providers.at("claude-code"), "worker",
                                                               ai::make_extension_context(cfg, projectDir_, ai::system_env()));
            at_check(!plan.hooks.is_object() || !plan.hooks.contains("Stop"), "...and a run does not get its hooks");
            at_check(plan.projectSettingsOff, "...nor the project's .claude settings, which the same trust covered");
        });
        // Remove everything, Save.
        step(3, [this] {
            aiSettings_.ext.user.clear();
            aiSettings_.ext.project.clear();
            aiSettings_.ext.inherit = true;
            aiSettings_.ext.projectError.clear();
        });
        click("aiset:ext:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && !j.contains("extensions") && j["roles"]["worker"]["model"] == "sonnet",
                     "Saving an empty list takes \"extensions\" out of the file and the other keys stay");
            at_check(!ai::load_project_extensions(projectDir_).exists, "...and removes the project's file");
        });
        click("aiset:ext:close");
        step(4, [this] { at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft"); });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            stdfs::remove_all(x->plugin, ec);
            stdfs::remove_all(projectDir_ + "/skills/autotest_gdd", ec);
            if (x->hadClaudeFile) write_file(x->claudeFile, x->claudeBackup);
            else {
                stdfs::remove(x->claudeFile, ec);
                stdfs::remove(projectDir_ + "/.claude", ec);  // only when it is empty
            }
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

    section("H2");
    // The Hooks section of the Extensions tab (docs/HOOKS.md, docs/EDITOR.md): the saved hooks with where each handler runs, then the
    // recent runs of this editor with the failures marked. The handlers really run (ai::test_hooks, what `ai.hooks_test` calls): a
    // program that answers, one that exits with an error, a JavaScript module that blocks; Clear forgets the list.
    {
        struct HState {
            std::string path, previousEnv, module;
            bool hadEnv = false, hadHooksDir = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<HState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        auto current_config = [this] {
            std::lock_guard<std::mutex> lock(aiMu_);
            return aiConfig_;
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_hooks_scratch.json";
            x->module = projectDir_ + "/hooks/autotest_gate.js";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            std::error_code ec;
            x->hadHooksDir = stdfs::exists(projectDir_ + "/hooks", ec);
            write_file(x->module, "export default {\n  PreToolUse(input) {\n    if (input.tool_name === \"scene_delete\") return { decision: \"block\", reason: \"autotest: no deletes\" };\n  },\n};\n");
            write_file(x->path, R"j({
  "extensions": {
    "hooks": {
      "audit": {
        "hooks": {
          "PostToolUse": [{ "matcher": "scene_*", "hooks": [{ "type": "command", "command": "echo audited" }] }],
          "beforeCommand": [{ "matcher": "scene.spawn", "hooks": [{ "type": "command", "command": "exit 3" }] }],
          "Stop": [{ "hooks": [{ "type": "http", "url": "https://example.invalid/stop" }] }]
        }
      },
      "gate": {
        "hooks": { "PreToolUse": [{ "matcher": "scene_delete", "hooks": [{ "type": "js", "module": "hooks/autotest_gate.js" }] }] }
      }
    }
  }
})j");
            ai::clear_recent_hook_runs();
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
            aiSettings_.ext.hooksAt = -10;
        });
        // Nothing has run: the saved hooks are listed, the list of runs is empty.
        step(4, [this] {
            const Json& r = aiSettings_.ext.hooksReport;
            at_check(r.is_object() && r.value("entries", Json::array()).size() == 2, "the saved report lists the two hooks entries");
            at_check(r.value("recentRuns", Json::array()).empty(), "no hook has run yet");
            at_check(at_visible("aiset:ext:hooks-clear") && !at_enabled("aiset:ext:hooks-clear"), "Clear is there and disabled while the list is empty");
        });
        // Three real runs: a program that answers, a program that fails, a JavaScript module that blocks.
        step(3, [this, current_config] {
            const ai::AiConfig cfg = current_config();
            at_check(cfg.extensions.entries.size() == 2, "the editor loaded the two hooks entries from the scratch file");
            const ai::ExtensionContext ctx = ai::make_extension_context(cfg, projectDir_, ai::system_env());
            auto post = ai::test_hooks(cfg, ctx, ai::HookEvent::PostToolUse, "scene_spawn",
                                       Json::object({{"tool_name", "scene_spawn"}, {"tool_input", Json::object()}}), "orchestrator", nullptr);
            at_check(post && (*post)["outcome"]["runs"].size() == 1 && !(*post)["outcome"]["failed"].get<bool>(),
                     "a PostToolUse program ran and answered");
            auto before = ai::test_hooks(cfg, ctx, ai::HookEvent::BeforeCommand, "scene.spawn",
                                         Json::object({{"command", "scene.spawn"}, {"args", Json::object()}}), "orchestrator", nullptr);
            at_check(before && (*before)["outcome"]["failed"].get<bool>(), "a beforeCommand program that exits with 3 is a failed run");
            auto gate = ai::test_hooks(cfg, ctx, ai::HookEvent::PreToolUse, "scene_delete",
                                       Json::object({{"tool_name", "scene_delete"}, {"tool_input", Json::object()}}), "orchestrator", nullptr);
            at_check(gate && (*gate)["outcome"]["blocked"].get<bool>(),
                     "the JavaScript module blocked scene_delete (" + (gate ? (*gate)["outcome"].dump() : gate.error().to_string()) + ")");
            aiSettings_.ext.hooksAt = -10;
        });
        step(4, [this] {
            const Json& r = aiSettings_.ext.hooksReport;
            const Json runs = r.value("recentRuns", Json::array());
            at_check(runs.size() == 3, "the tab reads the three runs (" + std::to_string(runs.size()) + ")");
            int failed = 0, blocked = 0;
            for (const Json& run : runs) {
                failed += run.value("failed", false) ? 1 : 0;
                blocked += run.value("decision", std::string()) == "block" ? 1 : 0;
            }
            at_check(failed == 1 && blocked == 1, "...one failed and one blocked");
            bool httpOnlyClaude = false;
            for (const Json& e : r.value("entries", Json::array()))
                if (e.value("name", std::string()) == "audit")
                    for (const Json& g : e["events"]["Stop"])
                        for (const Json& h : g["handlers"]) httpOnlyClaude = h.value("type", std::string()) == "http" && !h.value("runsHere", true);
            at_check(httpOnlyClaude, "an http handler is listed as one FactorIA does not run");
        });
        scroll_to("aiset:ext:hooks-clear", "AI settings###AiSettings");  // the Hooks section is the last of a long page
        step(3, [this] {
            at_check(at_shown("aiset:ext:hooks-clear") && at_enabled("aiset:ext:hooks-clear"), "Clear is shown and enabled once there are runs");
            at_check(at_shown("aiset:ext:hookrun:first"), "the newest run is on screen");
        });
        snap("editor_ai_hooks.png");
        click("aiset:ext:hooks-clear");
        step(4, [this] {
            at_check(ai::recent_hook_runs().empty(), "Clear forgot the runs");
            at_check(aiSettings_.ext.hooksReport.value("recentRuns", Json::array()).empty(), "...and the tab shows none");
        });
        click("aiset:ext:close");
        step(4, [this] { at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft"); });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(x->module, ec);
            if (!x->hadHooksDir) stdfs::remove(projectDir_ + "/hooks", ec);  // only when it is empty
            ai::clear_recent_hook_runs();
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

    section("S2");
    // The "Token savers" section of the Extensions tab (docs/AI_PROVIDERS.md, "Token savers"): the switches and the judge saved in
    // ai.json ("savers") without touching its other keys; the proposals a project's runs left in .factoria/ai/savers.json; AGENTS.md
    // and the project's tool groups unchanged until Load up front / Add to AGENTS.md, and a No thanks that changes nothing.
    {
        struct SState {
            std::string path, previousEnv, store, agents, agentsBefore;
            bool hadEnv = false, hadStore = false, hadAgents = false;
            std::string storeBefore;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<SState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        const std::string factId = "scene.spawn:not_found";
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env, factId] {
            x->path = atOutDir_ + "/ai_savers_scratch.json";
            x->store = projectDir_ + "/" + ai::kSaversFile;
            x->agents = projectDir_ + "/AGENTS.md";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            std::error_code ec;
            x->hadStore = stdfs::exists(x->store, ec);
            if (x->hadStore) x->storeBefore = read_file(x->store);
            x->hadAgents = stdfs::exists(x->agents, ec);
            if (x->hadAgents) x->agentsBefore = read_file(x->agents);
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({
  "limits": { "maxConcurrentRuns": 3 },
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } }
})");
            write_file(x->agents, "# Autotest project\n\nSome notes.\n");
            Json store = Json::object();
            store["version"] = 1;
            store["runs"] = Json::object({{"worker", 3}});
            store["groups"] = Json::object({{"worker", Json::object({{"scene", Json::object({{"runs", 3}, {"commands", Json::object({{"scene.spawn", 3}})}})},
                                                                  {"assets", Json::object({{"runs", 4}, {"commands", Json::object({{"assets.list", 4}})}})}})}});
            store["facts"] = Json::object(
                {{factId, Json::object({{"command", "scene.spawn"}, {"code", "not_found"}, {"runs", 3}, {"line", "- `scene.spawn` fails with `not_found`; list the prefabs first."}})}});
            write_file(x->store, store.dump(2));
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
            aiSettings_.ext.saversAt = -10;
        });
        step(3, [this, factId] {
            const ai::Savers& s = aiSettings_.ext.savers;
            at_check(s.loopGuard && s.learnedToolGroups && s.projectFacts && s.loopGuardJudge.empty(), "the savers start on, without a judge");
            const Json& props = aiSettings_.ext.saversReport.value("proposals", Json::object());
            at_check(props.value("toolGroups", Json::array()).size() == 2, "the report lists the two tool group proposals");
            const Json facts = props.value("facts", Json::array());
            at_check(facts.size() == 1 && facts[0].value("id", std::string()) == factId, "...and the one fact");
        });
        scroll_to("aiset:saver:loopguard", "AI settings###AiSettings");
        step(3, [this] {
            at_check(at_shown("aiset:saver:loopguard") && at_shown("aiset:saver:groups") && at_shown("aiset:saver:facts"),
                     "the Token savers section shows the three switches");
        });
        // Switches off, a judge picked.
        click("aiset:saver:loopguard");
        step(3, [this] { at_check(!aiSettings_.ext.savers.loopGuard, "the Loop guard switch turned off"); });
        click("aiset:saver:loopguard");
        click("aiset:saver:judge");
        click("aiset:saver:judge:worker");
        click("aiset:saver:groups");
        click("aiset:saver:facts");
        step(3, [this] {
            const ai::Savers& s = aiSettings_.ext.savers;
            at_check(s.loopGuard && s.loopGuardJudge == "worker" && !s.learnedToolGroups && !s.projectFacts,
                     "the judge is worker, learned groups and facts are off, the loop guard is on again");
        });
        scroll_to("aiset:ext:save", "AI settings###AiSettings");
        click("aiset:ext:save");
        step(4, [this, x] {
            const std::string text = read_file(x->path);
            const Json j = Json::parse(text, nullptr, false);
            at_check(j.is_object() && j.contains("savers") && j["savers"].value("loopGuardJudge", std::string()) == "worker" &&
                         !j["savers"].value("learnedToolGroups", true) && !j["savers"].value("projectFacts", true) && !j["savers"].contains("loopGuard"),
                     "Save wrote only the non-default savers keys: " + text);
            at_check(j.is_object() && j.contains("limits") && j.contains("roles"), "...and kept the other keys of ai.json");
            aiSettings_.ext.saversAt = -10;
        });
        // Back on, then the answers.
        scroll_to("aiset:saver:groups", "AI settings###AiSettings");
        click("aiset:saver:groups");
        click("aiset:saver:facts");
        step(3, [this] { at_check(aiSettings_.ext.savers.learnedToolGroups && aiSettings_.ext.savers.projectFacts, "learned groups and facts turned back on"); });
        scroll_to("aiset:saver:group-accept:worker:scene", "AI settings###AiSettings");
        step(3, [this, x] {
            at_check(at_shown("aiset:saver:group-accept:worker:scene") && at_visible("aiset:saver:fact-accept:scene.spawn:not_found"),
                     "the proposals have their buttons");
            at_check(read_file(x->agents) == "# Autotest project\n\nSome notes.\n", "AGENTS.md is untouched while the fact is only proposed");
        });
        snap("editor_ai_savers.png");
        click("aiset:saver:group-accept:worker:scene");
        step(4, [this, x] {
            const Json store = Json::parse(read_file(x->store), nullptr, false);
            at_check(store.is_object() && store["groups"]["worker"]["scene"].value("status", std::string()) == "accepted", "Load up front stored the accepted group");
            at_check(store["groups"]["worker"]["assets"].value("status", std::string()).empty(), "...and left the other group undecided");
            aiSettings_.ext.saversAt = -10;
        });
        scroll_to("aiset:saver:group-decline:worker:assets", "AI settings###AiSettings");
        click("aiset:saver:group-decline:worker:assets");
        step(4, [this, x] {
            const Json store = Json::parse(read_file(x->store), nullptr, false);
            at_check(store.is_object() && store["groups"]["worker"]["assets"].value("status", std::string()) == "declined", "No thanks stored the declined group");
            at_check(read_file(x->agents) == "# Autotest project\n\nSome notes.\n", "AGENTS.md is still untouched");
            aiSettings_.ext.saversAt = -10;
        });
        scroll_to("aiset:saver:fact-accept:scene.spawn:not_found", "AI settings###AiSettings");
        click("aiset:saver:fact-accept:scene.spawn:not_found");
        step(4, [this, x] {
            const std::string agents = read_file(x->agents);
            at_check(agents.find("## Project facts") != std::string::npos && agents.find("`scene.spawn` fails with `not_found`") != std::string::npos,
                     "Add to AGENTS.md wrote the line under the heading");
            at_check(agents.find("Some notes.") != std::string::npos, "...and kept what was there");
            const Json report = aiSettings_.ext.saversReport;
            at_check(report.value("proposals", Json::object()).value("toolGroups", Json::array()).empty() &&
                         report.value("proposals", Json::object()).value("facts", Json::array()).empty(),
                     "nothing is proposed any more");
        });
        click("aiset:ext:close");
        step(4, [this] { at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft"); });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            if (x->hadStore) write_file(x->store, x->storeBefore); else stdfs::remove(x->store, ec);
            if (x->hadAgents) write_file(x->agents, x->agentsBefore); else stdfs::remove(x->agents, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

    section("K2");
    // The Skills list of the AI settings' Extensions tab (docs/SKILLS.md): FactorIA's own skills, one of the project's, on/off per
    // role kept as skill entries (the engine skill by its "engine:<name>" path), Save writing them to ai.json and to the project's
    // .factoria/extensions.json, and a role then being offered exactly the skills left on for it.
    {
        struct KState {
            std::string path, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<KState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        const std::string win = "AI settings###AiSettings";
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_skills_scratch.json";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({ "limits": { "maxConcurrentRuns": 3 } })");
            write_file(projectDir_ + "/skills/autotest-notes/SKILL.md",
                       "---\nname: autotest-notes\ndescription: Notes for the autotest.\n---\nBody.\n");
            std::error_code ec;
            stdfs::remove(projectDir_ + "/.factoria/extensions.json", ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
        });
        step(4, [this] {
            const auto find = [&](const char* name) -> const ai::SkillInfo* {
                for (const ai::SkillInfo& s : aiSettings_.ext.skills)
                    if (s.name == name && s.shadowedBy.empty()) return &s;
                return nullptr;
            };
            const ai::SkillInfo* art = find("make-art");
            const ai::SkillInfo* notes = find("autotest-notes");
            at_check(art && art->source == "engine" && art->offered_to("artist") && !art->offered_to("audio"),
                     "the list has FactorIA's own make-art skill, on for the artist and not for the audio role");
            at_check(notes && notes->source == "project" && notes->offered_to("worker"), "...and the project's skills/autotest-notes, on for the worker");
            at_check(find("tile-levels") && find("review-ready") && find("make-audio"), "...with the other engine skills");
            at_check(at_visible("aiset:ext:skill:enabled:tile-levels") || at_visible("aiset:ext:skill:enabled:make-art"), "the Skills table shows an On box per skill");
        });
        // make-art also for the audio role: an entry "engine:make-art" with the roles listed.
        scroll_to("aiset:ext:skill:role:make-art:audio", win.c_str());
        click("aiset:ext:skill:role:make-art:audio");
        step(3, [this] {
            const auto& u = aiSettings_.ext.user;
            const auto it = std::ranges::find_if(u, [](const ai::Extension& e) { return e.kind == ai::ExtensionKind::Skill && e.path == "engine:make-art"; });
            at_check(it != u.end() && it->roles.size() == 3 && std::ranges::find(it->roles, std::string("audio")) != it->roles.end() &&
                         std::ranges::find(it->roles, std::string("artist")) != it->roles.end(),
                     "the Audio box of make-art adds the role to an engine:make-art entry that lists the artist, the orchestrator and audio");
        });
        // tile-levels off.
        scroll_to("aiset:ext:skill:enabled:tile-levels", win.c_str());
        click("aiset:ext:skill:enabled:tile-levels");
        step(3, [this] {
            const auto& u = aiSettings_.ext.user;
            const auto it = std::ranges::find_if(u, [](const ai::Extension& e) { return e.path == "engine:tile-levels"; });
            at_check(it != u.end() && !it->enabled, "the On box of tile-levels switches it off in an engine:tile-levels entry");
        });
        // The project's skill: not for the worker. It is kept in the project's file, relative to the project.
        scroll_to("aiset:ext:skill:role:autotest-notes:worker", win.c_str());
        click("aiset:ext:skill:role:autotest-notes:worker");
        step(3, [this] {
            const auto& p = aiSettings_.ext.project;
            at_check(p.size() == 1 && p[0].kind == ai::ExtensionKind::Skill && p[0].path == "skills/autotest-notes" && p[0].source == "project" &&
                         std::ranges::find(p[0].roles, std::string("worker")) == p[0].roles.end(),
                     "a project skill switched off for the worker becomes an entry of the project's file, with its path relative to the project");
        });
        step(2, [this] { aiSettings_.ext.statusAt = -10; });  // rescan now
        step(3, [this] {
            bool seenOff = false, seenNoWorker = false;
            for (const ai::SkillInfo& s : aiSettings_.ext.skills) {
                if (s.name == "tile-levels" && s.shadowedBy.empty()) seenOff = !s.enabled && !s.offered_to("worker");
                if (s.name == "autotest-notes" && s.shadowedBy.empty()) seenNoWorker = !s.offered_to("worker") && s.offered_to("orchestrator");
            }
            at_check(seenOff, "the list shows tile-levels as off");
            at_check(seenNoWorker, "...and autotest-notes as offered to the orchestrator but not the worker");
        });
        snap("editor_ai_skills.png");
        click("aiset:ext:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && aiSettings_.ext.saveError.empty(), "Save wrote a JSON object (" + aiSettings_.ext.saveError + ")");
            if (!j.is_object()) return;
            at_check(j["limits"]["maxConcurrentRuns"] == 3, "the other keys of the file stayed");
            const Json& skills = j["extensions"]["skills"];
            bool art = false, tiles = false;
            for (const auto& [name, e] : skills.items()) {
                if (e.value("path", "") == "engine:make-art") art = e["roles"].size() == 3;
                if (e.value("path", "") == "engine:tile-levels") tiles = e.value("enabled", true) == false;
            }
            at_check(art && tiles, "ai.json keeps the make-art roles and tile-levels off as skill entries");
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            at_check(pe.exists && pe.error.empty() && pe.entries.size() == 1 && pe.entries[0].path == "skills/autotest-notes",
                     "the project's .factoria/extensions.json keeps the project skill's roles (" + pe.error + ")");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            ai::SkillsContext sctx;
            sctx.projectDir = projectDir_;
            const std::vector<ai::SkillInfo> all = ai::scan_skills(cfg, sctx);
            const auto offered = [&](const char* role, const char* name) {
                for (const ai::SkillInfo* s : ai::skills_for_role(all, role))
                    if (s->name == name) return true;
                return false;
            };
            at_check(offered("audio", "make-art") && offered("artist", "make-art"), "a role is now offered make-art: audio and the artist");
            at_check(!offered("worker", "tile-levels") && !offered("orchestrator", "tile-levels"), "...and tile-levels by none");
            at_check(!offered("worker", "autotest-notes") && offered("orchestrator", "autotest-notes"), "...and autotest-notes by the orchestrator, not the worker");
        });
        click("aiset:ext:close");
        step(4, [this] { at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft"); });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            stdfs::remove(projectDir_ + "/.factoria/extensions.json", ec);
            stdfs::remove_all(projectDir_ + "/skills/autotest-notes", ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

    section("F2");
    // Add TokenEconomizer in the Extensions tab (docs/AI_PROVIDERS.md, "Installing a plugin"): the tab asks a fake Claude Code CLI what is
    // installed, the button shows what will be installed and runs nothing until Install, the install runs the CLI's plugin commands
    // and adds the entry to ai.json (the other keys stay), Save keeps it, and with the entry removed but the plugin still installed
    // the button offers only the entry. The CLI is a script of the autotest's output folder; the real claude is never run.
    {
        struct FState {
            std::string path, dir, cli, python, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<FState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        const auto scroll_click = [&](const std::string& name) {
            scroll_to(name, "AI settings###AiSettings");
            click(name);
        };
        const auto probed = [this] {
            std::lock_guard<std::mutex> lock(aiPluginJob_->mu);
            return aiPluginJob_->probeDone && !aiPluginJob_->running;
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->dir = atOutDir_ + "/fake_plugin_cli";
            x->path = atOutDir_ + "/ai_eco_scratch.json";
            std::error_code ec;
            stdfs::remove_all(x->dir, ec);
            stdfs::create_directories(x->dir, ec);
            write_file(x->dir + "/marketplaces.json", "[]");
            write_file(x->dir + "/plugins.json", "[]");
#ifdef _WIN32
            std::string d = x->dir;
            std::replace(d.begin(), d.end(), '/', '\\');
            x->cli = x->dir + "/claude.cmd";
            x->python = x->dir + "/python.cmd";
            write_file(x->cli,
                       "@echo off\r\nset \"D=" + d + "\"\r\necho %* >> \"%D%\\argv.log\"\r\n"
                       "if \"%1 %2 %3 %4\"==\"plugin marketplace list --json\" type \"%D%\\marketplaces.json\" & exit /b 0\r\n"
                       "if \"%1 %2 %3\"==\"plugin list --json\" type \"%D%\\plugins.json\" & exit /b 0\r\n"
                       "if \"%1 %2 %3\"==\"plugin marketplace add\" echo [{\"name\":\"tokeneconomizer\",\"repo\":\"microsoft/TokenEconomizer\"}]> \"%D%\\marketplaces.json\" & exit /b 0\r\n"
                       "if \"%1 %2\"==\"plugin install\" echo [{\"id\":\"tokeneconomizer@tokeneconomizer\"}]> \"%D%\\plugins.json\" & exit /b 0\r\n"
                       "if \"%1\"==\"--version\" echo 2.1.0 & exit /b 0\r\n"
                       "exit /b 9\r\n");
            write_file(x->python, "@echo off\r\necho Python 3.12.1\r\n");
#else
            x->cli = x->dir + "/claude";
            x->python = x->dir + "/python3";
            write_file(x->cli,
                       "#!/bin/sh\nD='" + x->dir + "'\necho \"$*\" >> \"$D/argv.log\"\ncase \"$*\" in\n"
                       "  \"plugin marketplace list --json\") cat \"$D/marketplaces.json\" ;;\n"
                       "  \"plugin list --json\") cat \"$D/plugins.json\" ;;\n"
                       "  \"plugin marketplace add \"*) echo '[{\"name\":\"tokeneconomizer\",\"repo\":\"microsoft/TokenEconomizer\"}]' > \"$D/marketplaces.json\"; echo added ;;\n"
                       "  \"plugin install \"*) echo '[{\"id\":\"tokeneconomizer@tokeneconomizer\"}]' > \"$D/plugins.json\"; echo installed ;;\n"
                       "  \"--version\") echo '2.1.0 (Claude Code)' ;;\n"
                       "  *) echo \"unexpected: $*\" >&2; exit 9 ;;\nesac\n");
            write_file(x->python, "#!/bin/sh\necho 'Python 3.12.1'\n");
            stdfs::permissions(x->cli, stdfs::perms::owner_all, stdfs::perm_options::add, ec);
            stdfs::permissions(x->python, stdfs::perms::owner_all, stdfs::perm_options::add, ec);
#endif
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            Json cfg = Json::object({{"limits", Json::object({{"maxConcurrentRuns", 3}})},
                                     {"roles", Json::object({{"worker", Json::object({{"provider", "anthropic"}, {"model", "sonnet"}})}})},
                                     {"providers", Json::object({{"claude-code", Json::object({{"command", x->cli}})}})}});
            write_file(x->path, cfg.dump(2));
            aiPluginProbeInTest_ = true;
            aiPluginPython_ = {x->python};
            aiEconomizerMessage_.clear();
            aiEconomizerConfirm_ = false;
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
        });
        step(1, [this, probed] {
            atWaitCount_ = 0;
            atWaitUntil_ = probed;
        });
        scroll_to("aiset:eco:add", "AI settings###AiSettings");
        step(3, [this, x] {
            at_check(at_shown("aiset:eco:add") && !at_visible("aiset:eco:installed"), "the TokenEconomizer section offers Add TokenEconomizer...");
            at_check(read_file(x->dir + "/argv.log").find("marketplace add") == std::string::npos, "the dry run asked the CLI to list only: nothing was added");
        });
        // The confirmation: what will be installed, and nothing has run.
        click("aiset:eco:add");
        scroll_to("aiset:eco:confirm", "AI settings###AiSettings");
        step(3, [this, x] {
            at_check(aiEconomizerConfirm_ && at_shown("aiset:eco:confirm") && at_enabled("aiset:eco:confirm"), "the confirmation shows an Install button (Python 3.12.1 is enough)");
            at_check(at_shown("aiset:eco:cancel"), "...and a Cancel button");
            const std::string log = read_file(x->dir + "/argv.log");
            at_check(log.find("marketplace add") == std::string::npos && log.find("plugin install") == std::string::npos, "the confirmation ran no install command");
            at_check(read_file(x->path).find("tokeneconomizer") == std::string::npos, "...and wrote nothing to ai.json");
        });
        snap("editor_ai_economizer.png");
        click("aiset:eco:cancel");
        step(3, [this] { at_check(!aiEconomizerConfirm_, "Cancel closes the confirmation"); });
        scroll_click("aiset:eco:add");
        scroll_click("aiset:eco:confirm");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                std::lock_guard<std::mutex> lock(aiPluginJob_->mu);
                return !aiPluginJob_->running && !aiPluginJob_->finished && !aiEconomizerMessage_.empty();
            };
        });
        step(3, [this, x] {
            const std::string log = read_file(x->dir + "/argv.log");
            const auto add = log.find("plugin marketplace add microsoft/TokenEconomizer");
            const auto install = log.find("plugin install tokeneconomizer@tokeneconomizer");
            at_check(add != std::string::npos && install != std::string::npos && add < install, "Install ran the marketplace add, then the plugin install");
            at_check(aiEconomizerOk_, "the result is a success: " + aiEconomizerMessage_);
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("extensions") && j["extensions"]["plugins"]["tokeneconomizer"].value("plugin", std::string()) == "tokeneconomizer@tokeneconomizer",
                     "ai.json has the plugin entry");
            at_check(j.is_object() && j.contains("limits") && j.contains("roles") && j.contains("providers"), "...and kept its other keys");
            const auto& u = aiSettings_.ext.user;
            at_check(std::ranges::count_if(u, [](const ai::Extension& e) { return e.plugin == "tokeneconomizer@tokeneconomizer"; }) == 1,
                     "the tab's list has the entry once");
        });
        step(1, [this, probed] {
            atWaitCount_ = 0;
            atWaitUntil_ = probed;
        });
        scroll_to("aiset:eco:installed", "AI settings###AiSettings");
        step(3, [this] { at_check(at_shown("aiset:eco:installed") && !at_visible("aiset:eco:add"), "the section now reads installed"); });
        // Save keeps the entry and every other key.
        scroll_click("aiset:ext:save");
        step(4, [this, x] {
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("limits") && j.contains("roles") && j.contains("providers") &&
                         j["extensions"]["plugins"].size() == 1 && j["extensions"]["plugins"].contains("tokeneconomizer"),
                     "Save kept the entry (once) and the other keys of ai.json");
        });
        // The entry removed, the plugin still installed: only the entry is offered.
        scroll_click("aiset:ext:remove:plugin:tokeneconomizer");
        scroll_click("aiset:ext:save");
        step(1, [this, probed] {
            atWaitCount_ = 0;
            atWaitUntil_ = probed;
        });
        step(3, [this, x] {
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && !j.contains("extensions"), "Remove and Save took the entry out of ai.json");
        });
        scroll_to("aiset:eco:entry", "AI settings###AiSettings");
        step(3, [this] { at_check(at_shown("aiset:eco:entry") && !at_visible("aiset:eco:add"), "the section offers only the entry, since the plugin is installed"); });
        click("aiset:eco:entry");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                std::lock_guard<std::mutex> lock(aiPluginJob_->mu);
                return !aiPluginJob_->running && !aiPluginJob_->finished && aiPluginJob_->probeDone;
            };
        });
        step(3, [this, x] {
            const std::string log = read_file(x->dir + "/argv.log");
            const auto first = log.find("plugin install ");
            at_check(first != std::string::npos && log.find("plugin install ", first + 1) == std::string::npos, "adding only the entry did not install the plugin again");
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("extensions") && j["extensions"]["plugins"].contains("tokeneconomizer"), "ai.json has the entry again");
        });
        click("aiset:ext:close");
        step(4, [this] { at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft"); });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            aiPluginProbeInTest_ = false;
            aiPluginPython_.clear();
            aiEconomizerMessage_.clear();
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove_all(x->dir, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }

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
