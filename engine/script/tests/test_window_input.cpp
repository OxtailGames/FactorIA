// window.* and the options-menu additions of input.* (rebinding, text, last input, button names, cursor, keyboard).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

// A window that records what scripts ask of it (the real one is AppWindowControl in fa_runtime, tested in a real window).
// Two fake monitors (a 1920x1080 primary and a 1280x720 one on its right) and the macOS rule that borderless cannot be reached from
// full screen directly, so the platform-independent parts of window.* are covered without a display.
struct FakeWindow final : WindowControl {
    std::string mode_ = "windowed";
    bool sync = true;
    int w = 1000, h = 562, cap = 0, mon = 0;
    bool borderless_ok = true, monitors_ok = true;
    bool full() const { return mode_ != "windowed"; }
    std::string mode() const override { return mode_; }
    bool supports_modes() const override { return borderless_ok; }
    bool supports_monitors() const override { return monitors_ok; }
    std::vector<WindowMonitor> monitors() const override {
        return {{"Main", 1920, 1080, true, mon == 0}, {"Side", 1280, 720, false, mon == 1}};
    }
    std::string set_mode(const std::string& m) override {
        if (m == "borderless" && !borderless_ok) return "this platform has no borderless mode";
        mode_ = m;
        return {};
    }
    std::string set_monitor(int i) override {
        if (!monitors_ok) return "this platform shows the game on one display";
        if (i < 0 || i >= 2) return "there is no monitor " + std::to_string(i) + "; this computer has 2";
        mon = i;
        return {};
    }
    void size(int& a, int& b) const override { a = w; b = h; }
    void display_size(int& a, int& b) const override { a = mon == 0 ? 1920 : 1280; b = mon == 0 ? 1080 : 720; }
    bool vsync() const override { return sync; }
    int frame_cap() const override { return cap; }
    std::string set_size(int a, int b) override {
        if (full()) return "the window is full screen. Call window.setFullscreen(false) first.";
        w = a;
        h = b;
        return {};
    }
    std::string set_vsync(bool on) override {
        if (on == sync) return {};
        return "vsync cannot be changed here.";
    }
    std::string set_frame_cap(int fps) override { cap = fps; return {}; }
};

struct WindowedHost : TestHost {
    FakeWindow win;
    explicit WindowedHost(const std::string& tag, const Json& settings) : TestHost(tag, settings) {}
    WindowControl* window() override { return &win; }
};

Json display_settings() {
    return Json::parse(R"({"display": {"width": 800, "height": 600, "fullscreen": true, "vsync": false}})");
}

}  // namespace

TEST_CASE("window without a window: getters answer from factoria.json, every setter throws the teaching error") {
    TestHost h("window_headless", display_settings());
    h.file("tests/t.test.js", R"JS(
import { test, expect } from "factoria:test";
import { window } from "factoria";
const NO_WINDOW = "this run has no window (headless run / test)";
test("getters return the project's display settings", () => {
  expect(window.available).toBe(false);
  expect(window.fullscreen).toBe(true);
  expect(window.vsync).toBe(false);
  expect(window.frameCap).toBe(0);
  expect(window.size.x).toBe(800);
  expect(window.size.y).toBe(600);
  expect(window.displaySize.x).toBe(800);
  expect(window.resolutions()).toEqual([{ width: 640, height: 360 }, { width: 800, height: 600 }]);   // what fits, smallest first
});
test("setFullscreen, setSize, setVsync and frameCap throw and say what to do", () => {
  expect(() => window.setFullscreen(true)).toThrow("window.setFullscreen: " + NO_WINDOW);
  expect(() => window.setFullscreen(false)).toThrow("check window.available first");
  expect(() => window.setSize(1280, 720)).toThrow("window.setSize: " + NO_WINDOW);
  expect(() => window.setVsync(true)).toThrow("window.setVsync: " + NO_WINDOW);
  expect(() => { window.frameCap = 60; }).toThrow("window.frameCap: " + NO_WINDOW);
  expect(() => window.setFullscreen(true)).toThrow("Full screen, size, vsync and the frame cap only apply to a windowed run (factoria run, an exported game)");
  expect(window.fullscreen).toBe(true);   // nothing changed
});
test("bad arguments are explained before anything else", () => {
  expect(() => window.setFullscreen("yes")).toThrow("expects true or false");
  expect(() => window.setVsync(1)).toThrow("window.setVsync(on) expects true or false");
  expect(() => window.setSize(0, 720)).toThrow("whole numbers of pixels from 160 to 16384");
  expect(() => window.setSize(1280.5, 720)).toThrow("window.setSize(1280, 720)");
  expect(() => { window.frameCap = 10; }).toThrow("0 (unlimited) or a whole number of frames per second from 15 to 1000");
  expect(() => { window.frameCap = "fast"; }).toThrow("window.frameCap = 60");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("window with a window: setters reach it, its refusals are thrown with the function name") {
    WindowedHost h("window_fake", Json::parse(R"({"display": {"width": 1000, "height": 562}})"));
    h.file("tests/t.test.js", R"JS(
import { test, expect } from "factoria:test";
import { window } from "factoria";
test("full screen on and off", () => {
  expect(window.available).toBe(true);
  expect(window.fullscreen).toBe(false);
  window.setFullscreen(true);
  expect(window.fullscreen).toBe(true);
  expect(() => window.setSize(800, 600)).toThrow("window.setSize: the window is full screen. Call window.setFullscreen(false) first.");
  window.setFullscreen(false);
  expect(window.fullscreen).toBe(false);
});
test("size, display size and resolutions", () => {
  window.setSize(1280, 720);
  expect(window.size.x).toBe(1280);
  expect(window.size.y).toBe(720);
  expect(window.displaySize.x).toBe(1920);
  const list = window.resolutions();
  expect(list[0]).toEqual({ width: 640, height: 360 });
  expect(list).toContain({ width: 1000, height: 562 });           // the design size
  expect(list[list.length - 1]).toEqual({ width: 1920, height: 1080 });   // 1920x1200 does not fit a 1080 high monitor
  for (let i = 1; i < list.length; i++) expect(list[i].width * list[i].height).toBeGreaterThan(list[i - 1].width * list[i - 1].height);
  expect(list.length).toBe(9);
});
test("vsync and frame cap", () => {
  expect(window.vsync).toBe(true);
  window.setVsync(true);
  expect(() => window.setVsync(false)).toThrow("window.setVsync: vsync cannot be changed here.");
  window.frameCap = 144;
  expect(window.frameCap).toBe(144);
  window.frameCap = 0;
  expect(window.frameCap).toBe(0);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("window modes and monitors: a fake set of monitors, mode changes, refusals and supports()") {
    WindowedHost h("window_modes", Json::parse(R"({"display": {"width": 1000, "height": 562}})"));
    h.file("tests/t.test.js", R"JS(
import { test, expect } from "factoria:test";
import { window } from "factoria";
test("monitors are listed primary first with index, name and size", () => {
  const list = window.monitors();
  expect(list.length).toBe(2);
  expect(list[0].index).toBe(0);
  expect(list[0].name).toBe("Main");
  expect(list[0].size.x).toBe(1920);
  expect(list[0].primary).toBe(true);
  expect(list[1].index).toBe(1);
  expect(list[1].size.y).toBe(720);
  expect(list[1].primary).toBe(false);
  expect(window.monitor).toBe(0);
  expect(list[0].current).toBe(true);
});
test("setMonitor moves the window and the display size follows", () => {
  window.setMonitor(1);
  expect(window.monitor).toBe(1);
  expect(window.monitors()[1].current).toBe(true);
  expect(window.displaySize.x).toBe(1280);
  expect(window.resolutions()[window.resolutions().length - 1]).toEqual({ width: 1280, height: 720 });
  window.setMonitor(0);
  expect(window.displaySize.x).toBe(1920);
});
test("setMonitor explains a bad index", () => {
  expect(() => window.setMonitor(5)).toThrow("window.setMonitor: there is no monitor 5; this computer has 2");
  expect(() => window.setMonitor(-1)).toThrow("expects the number of a monitor from window.monitors()");
  expect(() => window.setMonitor(1.5)).toThrow("window.setMonitor(1)");
  expect(() => window.setMonitor("1")).toThrow("but got");
});
test("setMode switches between windowed, borderless and fullscreen; fullscreen is true for both covering modes", () => {
  expect(window.mode).toBe("windowed");
  expect(window.fullscreen).toBe(false);
  window.setMode("borderless");
  expect(window.mode).toBe("borderless");
  expect(window.fullscreen).toBe(true);
  window.setMode("fullscreen");
  expect(window.mode).toBe("fullscreen");
  window.setMode("windowed");
  expect(window.mode).toBe("windowed");
  window.setFullscreen(true);
  expect(window.mode).toBe("fullscreen");
  window.setFullscreen(false);
  expect(window.mode).toBe("windowed");
});
test("setMode rejects an unknown name with a suggestion", () => {
  expect(() => window.setMode("borderles")).toThrow('did you mean "borderless"?');
  expect(() => window.setMode(true)).toThrow('expects "windowed", "borderless" or "fullscreen"');
});
test("supports says what this platform can do and a refusal is thrown with the function name", () => {
  expect(window.supports("borderless")).toBe(true);
  expect(window.supports("monitors")).toBe(true);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("window modes on a platform without borderless or monitor choice") {
    WindowedHost h("window_modes_web", Json::parse(R"({"display": {"width": 1000, "height": 562}})"));
    h.win.borderless_ok = false;
    h.win.monitors_ok = false;
    h.file("tests/t.test.js", R"JS(
import { test, expect } from "factoria:test";
import { window } from "factoria";
test("supports is false and the setters explain", () => {
  expect(window.supports("borderless")).toBe(false);
  expect(window.supports("monitors")).toBe(false);
  expect(() => window.setMode("borderless")).toThrow("window.setMode: this platform has no borderless mode");
  expect(() => window.setMonitor(1)).toThrow("window.setMonitor: this platform shows the game on one display");
  window.setMode("fullscreen");
  expect(window.mode).toBe("fullscreen");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("window modes and monitors without a window: one monitor from factoria.json, setters throw") {
    TestHost h("window_modes_headless", Json::parse(R"({"display": {"width": 800, "height": 600, "fullscreen": true}})"));
    h.file("tests/t.test.js", R"JS(
import { test, expect } from "factoria:test";
import { window } from "factoria";
test("one display, the project's mode, and no support", () => {
  expect(window.mode).toBe("fullscreen");
  const list = window.monitors();
  expect(list.length).toBe(1);
  expect(list[0].primary).toBe(true);
  expect(list[0].size.x).toBe(800);
  expect(window.monitor).toBe(0);
  expect(window.supports("borderless")).toBe(false);
  expect(window.supports("monitors")).toBe(false);
  expect(() => window.setMode("borderless")).toThrow("window.setMode: this run has no window");
  expect(() => window.setMonitor(0)).toThrow("window.setMonitor: this run has no window");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("input rebinding: input.down follows the new binding, errors teach, nothing leaks into the next test") {
    TestHost h("input_rebind");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";
test("rebind, bindings, actions and resetBindings", () => {
  expect(input.actions()).toEqual(["jump", "move_left", "move_right"]);
  expect(input.bindings("jump")).toEqual(["Space"]);
  input.rebind("jump", ["enter", "GamepadX"]);
  expect(input.bindings("jump")).toEqual(["Enter", "GamepadX"]);
  game.keyDown("Space");
  expect(input.down("jump")).toBe(false);          // the old binding no longer counts
  game.keyUp("Space");
  game.keyDown("Enter");
  expect(input.down("jump")).toBe(true);
  expect(input.pressed("jump")).toBe(true);
  game.keyUp("Enter");
  game.gamepad().press("X");
  expect(input.down("jump")).toBe(true);
  game.gamepad().release("X");
  input.rebind("move_left", []);                    // unbound but still an action
  expect(input.bindings("move_left")).toEqual([]);
  expect(input.down("move_left")).toBe(false);
  input.resetBindings("jump");
  expect(input.bindings("jump")).toEqual(["Space"]);
  expect(input.bindings("move_left")).toEqual([]);   // only the one asked for
  input.resetBindings();
  expect(input.bindings("move_left")).toEqual(["A"]);
});
test("a rebind in the last test did not leak", () => {
  expect(input.bindings("jump")).toEqual(["Space"]);
  expect(input.bindings("move_left")).toEqual(["A"]);
});
test("errors name the problem and suggest the fix, and change nothing", () => {
  expect(() => input.rebind("jmp", ["Space"])).toThrow("Did you mean 'jump'");
  expect(() => input.rebind("jump", ["Enter", "Spce"])).toThrow("Did you mean 'Space'");
  expect(input.bindings("jump")).toEqual(["Space"]);
  expect(() => input.rebind("jump", "Enter")).toThrow("expects an array of binding names");
  expect(() => input.rebind("jump", [5])).toThrow("expects an array of binding names");
  expect(() => input.bindings("nope")).toThrow("unknown input action");
  expect(() => input.resetBindings("nope")).toThrow("unknown input action");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("input.text, lastPressed, lastDevice, cursor and keyboard state") {
    TestHost h("input_settings");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";
test("input.text holds what was typed until the next step", () => {
  expect(input.text).toBe("");
  game.typeText("hé€\n\u{1F600}");        // the newline is a control character: skipped
  expect(input.text).toBe("hé€\u{1F600}");
  game.step(1);
  expect(input.text).toBe("");
});
test("lastPressed names what went down this frame, null otherwise", () => {
  expect(input.lastPressed()).toBe(null);
  game.keyDown("Space");
  expect(input.lastPressed()).toBe("Space");
  game.step(1);
  expect(input.lastPressed()).toBe(null);           // held: not new
  game.keyUp("Space");
  game.gamepad().press("A");
  expect(input.lastPressed()).toBe("GamepadA");
  game.gamepad().release("A");
  game.step(1);
  game.gamepad().axis("LeftX", -1);
  expect(input.lastPressed()).toBe("GamepadLeftStickLeft");
});
test("lastDevice follows the last input", () => {
  expect(input.lastDevice).toBe("keyboard");
  game.gamepad().press("B");
  expect(input.lastDevice).toBe("gamepad");
  game.mouseMove({ x: 50, y: 60 });
  expect(input.lastDevice).toBe("mouse");
  game.touchStart({ x: 5, y: 5 });
  expect(input.lastDevice).toBe("touch");
  game.touchEnd();
  game.keyDown("A");
  expect(input.lastDevice).toBe("keyboard");
});
test("the next test starts from the keyboard again", () => {
  expect(input.lastDevice).toBe("keyboard");
});
test("cursor and on-screen keyboard are recorded without a window", () => {
  expect(input.mouse.visible).toBe(true);
  expect(input.mouse.locked).toBe(false);
  expect(input.keyboardShown).toBe(false);
  input.mouse.visible = false;
  input.mouse.locked = true;
  input.showKeyboard();
  expect(input.mouse.visible).toBe(false);
  expect(input.mouse.locked).toBe(true);
  expect(input.keyboardShown).toBe(true);
  input.showKeyboard(false);
  expect(input.keyboardShown).toBe(false);
});
test("and do not leak", () => {
  expect(input.mouse.visible).toBe(true);
  expect(input.mouse.locked).toBe(false);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("input.buttonName and gamepad(i).type per pad family") {
    TestHost h("input_button_names");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";
test("keys and the mouse are named by themselves", () => {
  expect(input.buttonName("Space")).toBe("Space");
  expect(input.buttonName("w")).toBe("W");
  expect(input.buttonName("MouseLeft")).toBe("Left Click");
});
test("a pad button is named by the family of the pad", () => {
  expect(input.gamepad(0).type).toBe("generic");
  expect(input.buttonName("GamepadA")).toBe("A");
  const pad = game.gamepad(0);
  for (const [type, a, b, lb, rt] of [["xbox", "A", "B", "LB", "RT"], ["playstation", "Cross", "Circle", "L1", "R2"],
                                      ["nintendo", "B", "A", "L", "ZR"], ["steamdeck", "A", "B", "L1", "R2"], ["generic", "A", "B", "LB", "RT"]]) {
    pad.setType(type);
    expect(input.gamepad(0).type).toBe(type);
    expect(input.buttonName("GamepadA")).toBe(a);
    expect(input.buttonName("GamepadB")).toBe(b);
    expect(input.buttonName("GamepadLeftShoulder")).toBe(lb);
    expect(input.buttonName("GamepadRightTrigger")).toBe(rt);
  }
  pad.setType("playstation");
  expect(input.buttonName("GamepadA", 1)).toBe("A");            // pad 1 is not connected: the generic names
  expect(input.gamepad(1).type).toBe("generic");
  expect(input.buttonName("GamepadLeftStickUp")).toBe("Left Stick Up");
});
test("an action is named by the first binding for the last device", () => {
  input.rebind("jump", ["Space", "GamepadA"]);
  game.gamepad().setType("playstation");
  game.keyDown("Space");
  expect(input.buttonName("jump")).toBe("Space");
  game.gamepad().press("Y");
  expect(input.buttonName("jump")).toBe("Cross");
  input.rebind("jump", []);
  expect(input.buttonName("jump")).toBe("");
});
test("the pad type does not leak, bad names teach", () => {
  expect(input.gamepad(0).type).toBe("generic");
  expect(() => input.buttonName("jumpp")).toThrow("Did you mean 'jump'");
  expect(() => input.buttonName("Spce")).toThrow("unknown action or binding");
  expect(() => input.buttonName("Space", 7)).toThrow("0 to 3");
  expect(() => game.gamepad().setType("ps5")).toThrow("unknown pad type");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("typescript declarations: window, rebinding and button names") {
    TestHost h("dts_window_input");
    REQUIRE(h.start());
    std::string dts = h.scripts.typescript_declarations();
    for (const char* needle : {"export interface WindowAPI {", "export const window: WindowAPI;", "setFullscreen(on: boolean): void;",
                               "readonly available: boolean;", "frameCap: number;", "resolutions(): Resolution[];",
                               "export type GamepadType =", "export type InputDevice =", "readonly lastDevice: InputDevice;",
                               "rebind(action: string, bindings: string[]): void;", "resetBindings(action?: string): void;",
                               "lastPressed(): string | null;", "buttonName(bindingOrAction: string, pad?: number): string;",
                               "readonly text: string;", "showKeyboard(on?: boolean): void;", "readonly type: GamepadType;",
                               "typeText(text: string): void;", "setType(type: "}) {
        CAPTURE(needle);
        CHECK(dts.find(needle) != std::string::npos);
    }
}

TEST_CASE("window.renderScale, window.supports and game.device without a renderer or a window") {
    TestHost h("window_quality_headless");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { window, game as g } from "factoria";
test("render scale is remembered, bad values teach", () => {
  expect(window.renderScale).toBe(1);
  window.renderScale = 0.75;
  expect(window.renderScale).toBe(0.75);
  expect(() => { window.renderScale = 0.4; }).toThrow("window.renderScale expects a number from 0.5 to 1");
  expect(() => { window.renderScale = NaN; }).toThrow("window.renderScale expects");
});
test("render scale is back at 1 in the next test", () => {
  expect(window.renderScale).toBe(1);
});
test("supports names the feature or throws with a suggestion", () => {
  expect(window.supports("renderScale")).toBe(true);
  expect(window.supports("frameCap")).toBe(false);
  expect(window.supports("fullscreen")).toBe(false);
  expect(window.supports("resize")).toBe(false);
  expect(() => window.supports("renderscale")).toThrow('did you mean "renderScale"');
  expect(() => window.supports("hdr")).toThrow('use one of "frameCap", "renderScale"');
});
test("game.device is fixed headless and game.setDevice pretends", () => {
  expect(g.device).toEqual({ formFactor: "desktop", gpuBackend: "headless", memoryGB: 8, tier: "high", steamDeck: false, handheld: false });
  game.setDevice({ formFactor: "tablet", gpuBackend: "gles3", memoryGB: 3, tier: "low" });
  expect(g.device).toEqual({ formFactor: "tablet", gpuBackend: "gles3", memoryGB: 3, tier: "low", steamDeck: false, handheld: true });
  expect(window.supports("frameCap")).toBe(false);  // still no window
  expect(() => game.setDevice({ formFactor: "tv" })).toThrow("formFactor must be one of");
  expect(() => game.setDevice({ memoryGb: 2 })).toThrow("did you mean 'memoryGB'");
});
test("a test device can be a Steam Deck", () => {
  game.setDevice({ steamDeck: true });
  expect(g.device.steamDeck).toBe(true);
  expect(g.device.handheld).toBe(true);        // a Deck is a handheld
  expect(g.device.formFactor).toBe("desktop");  // and reports a desktop form factor
  game.setDevice({ steamDeck: true, handheld: false });
  expect(g.device.handheld).toBe(false);
  game.setDevice({ handheld: true });
  expect(g.device.steamDeck).toBe(false);
  expect(g.device.handheld).toBe(true);
  expect(() => game.setDevice({ steamDeck: "yes" })).toThrow("steamDeck must be true or false");
  expect(() => game.setDevice({ steamdeck: true })).toThrow("did you mean 'steamDeck'");
});
test("game.renderStats needs graphics", () => {
  expect(() => game.renderStats()).toThrow("no renderer");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("window.supports(frameCap) follows the window and the form factor") {
    WindowedHost h("window_quality_windowed", Json::parse(R"({"display": {"width": 1000, "height": 562}})"));
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { window } from "factoria";
test("a desktop window can cap, a pretend phone cannot", () => {
  expect(window.supports("frameCap")).toBe(true);
  expect(window.supports("resize")).toBe(true);
  game.setDevice({ formFactor: "phone" });
  expect(window.supports("frameCap")).toBe(false);
  expect(window.supports("renderScale")).toBe(true);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
