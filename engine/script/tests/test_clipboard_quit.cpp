// clipboard.read / clipboard.write, window.supports("clipboard"), and the game.on("quit") event (event.cancel, game.quit).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("clipboard: write then read gives the text back, and every test starts with an empty clipboard") {
    TestHost h("clipboard_basic", Json::object());
    h.file("tests/clip.test.js", R"JS(
import { test, expect } from "factoria:test";
import { clipboard, window } from "factoria";

test("write then read", async () => {
  expect(window.supports("clipboard")).toBe(true);
  expect(await clipboard.read()).toBe("");
  clipboard.write("ABC 123 é中");
  expect(await clipboard.read()).toBe("ABC 123 é中");
  clipboard.write("second");
  expect(await clipboard.read()).toBe("second");
});

test("starts empty again, and write teaches", async () => {
  expect(await clipboard.read()).toBe("");
  expect(() => clipboard.write(42)).toThrow("clipboard.write(text) expects a string");
  expect(() => window.supports("clipbord")).toThrow('did you mean "clipboard"');
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/clip.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 2);
}

namespace {
// A phone: no clipboard for games.
struct NoClipboardHost : TestHost {
    struct Unsupported final : Clipboard {
        bool supported() const override { return false; }
        std::string get() override { return "never"; }
        void set(const std::string&) override {}
    } none;
    explicit NoClipboardHost(const std::string& tag) : TestHost(tag, Json::object()) {}
    Clipboard* clipboard() override { return &none; }
};
}  // namespace

TEST_CASE("clipboard: a platform without one is unsupported, and read() rejects with code unsupported") {
    NoClipboardHost h("clipboard_none");
    h.file("tests/none.test.js", R"JS(
import { test, expect } from "factoria:test";
import { clipboard, window } from "factoria";

test("unsupported", async () => {
  expect(window.supports("clipboard")).toBe(false);
  let code = "";
  try { await clipboard.read(); } catch (e) { code = e.code; }
  expect(code).toBe("unsupported");
  clipboard.write("x");   // does nothing, does not throw
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/none.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
}

TEST_CASE("quit event: a requested quit raises it once, a cancelled one keeps running, game.quit closes") {
    TestHost h("quit_event", Json::object());
    h.file("tests/quit.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { game as g } from "factoria";

test("a requested quit raises quit once and closes", () => {
  let n = 0;
  const off = g.on("quit", () => { n++; });
  expect(game.quitRequested).toBe(false);
  expect(game.closeWindow()).toBe(true);
  expect(n).toBe(1);
  expect(game.quitRequested).toBe(true);
  off();
});

test("a cancelled quit keeps running; game.quit() afterwards closes without asking again", () => {
  let n = 0, cancelledSeen = null;
  const off = g.on("quit", (e) => { n++; e.cancel(); cancelledSeen = e.cancelled; });
  expect(game.closeWindow()).toBe(false);
  expect(n).toBe(1);
  expect(cancelledSeen).toBe(true);
  expect(game.quitRequested).toBe(false);
  game.step(3);
  expect(game.quitRequested).toBe(false);
  expect(game.closeWindow()).toBe(false);   // asked again: the handler cancels again
  expect(n).toBe(2);
  g.quit();                                 // the game's own quit does not come back to the handler
  expect(n).toBe(2);
  expect(game.quitRequested).toBe(true);
  off();
});

test("without a handler the window closes; the next test starts clean", () => {
  expect(game.quitRequested).toBe(false);
  expect(game.closeWindow()).toBe(true);
});

test("game.on rejects an unknown event with the list", () => {
  expect(() => g.on("quitt", () => {})).toThrow('did you mean "quit"');
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/quit.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}
