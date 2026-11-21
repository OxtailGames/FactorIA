// Deprecations (core/deprecation.h): the table, the text of a warning, and a deprecated command that warns once and still runs.
#include <doctest.h>

#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/deprecation.h"
#include "fa/core/log.h"

using namespace fa;

namespace {
// Puts a table in place for one test and empties it afterwards, so no other test sees it.
struct TableGuard {
    explicit TableGuard(const char* text) { Deprecations::global().set(Json::parse(text)); }
    ~TableGuard() { Deprecations::global().clear(); }
};

// The warnings of category "deprecated" that were logged while it lives.
struct DeprecatedLogCapture {
    std::mutex mutex;
    std::vector<std::string> lines;
    int id;
    DeprecatedLogCapture() {
        id = add_log_sink([this](const LogEntry& e) {
            if (e.category != "deprecated") return;
            std::lock_guard<std::mutex> lock(mutex);
            lines.push_back(e.message);
        });
    }
    ~DeprecatedLogCapture() { remove_log_sink(id); }
    std::vector<std::string> get() {
        std::lock_guard<std::mutex> lock(mutex);
        return lines;
    }
};

constexpr const char* kTable = R"({
    "commands": {"old.thing": {"since": "0.30.0", "use": "new.thing", "note": "It takes the same arguments."}},
    "components": {"Sprite.oldField": {"since": "0.30.1", "use": "Sprite.newField", "note": ""},
                   "Gone": {"since": "0.31.0", "use": "", "note": "Nothing replaces it: build it from two entities."}},
    "script": {"NavAPI.oldCall": {"since": "unreleased", "use": "NavAPI.newCall", "note": ""}}
})";
}  // namespace

TEST_CASE("deprecation: the version that removes something is two minors after the one that deprecated it") {
    CHECK(deprecation_removal_version("0.30.0") == "0.32.0");
    CHECK(deprecation_removal_version("0.30.7") == "0.32.0");
    CHECK(deprecation_removal_version("1.9.2") == "1.11.0");
    CHECK(deprecation_removal_version("unreleased").empty());
    CHECK(deprecation_removal_version("0.30").empty());
    CHECK(deprecation_removal_version("0.30.0.1").empty());
    CHECK(deprecation_removal_version("x.y.z").empty());
    CHECK(deprecation_removal_version("").empty());
}

TEST_CASE("deprecation: the message says what, since when, what replaces it and when it goes") {
    TableGuard g(kTable);
    const std::string cmd =
        deprecation_message(kDeprecatedCommands, "old.thing", *Deprecations::global().find("commands", "old.thing"));
    CHECK(cmd == "Deprecated: command 'old.thing' (since 0.30.0) will be removed in 0.32.0. Use 'new.thing' instead. "
                 "It takes the "
                 "same arguments.");
    const std::string field = deprecation_message(kDeprecatedComponents, "Sprite.oldField",
                                                  *Deprecations::global().find("components", "Sprite.oldField"));
    CHECK(field.find(
              "component field 'Sprite.oldField' (since 0.30.1) will be removed in 0.32.0. Use 'Sprite.newField'") !=
          std::string::npos);
    const std::string none =
        deprecation_message(kDeprecatedComponents, "Gone", *Deprecations::global().find("components", "Gone"));
    CHECK(none.find("component 'Gone'") != std::string::npos);
    CHECK(none.find("It has no replacement. Nothing replaces it") != std::string::npos);
    const std::string unreleased = deprecation_message(kDeprecatedScript, "NavAPI.oldCall",
                                                       *Deprecations::global().find("script", "NavAPI.oldCall"));
    CHECK(unreleased.find("script API 'NavAPI.oldCall' (deprecated before its first release)") != std::string::npos);
    CHECK(unreleased.find("two minor versions after the release that ships it") != std::string::npos);
    CHECK(deprecation_summary(*Deprecations::global().find("commands", "old.thing")) ==
          "Deprecated since 0.30.0 - use `new.thing`. Removed in 0.32.0.");
    CHECK(deprecation_summary(*Deprecations::global().find("components", "Gone")) ==
          "Deprecated since 0.31.0 - no replacement. Removed in 0.33.0.");
}

TEST_CASE("deprecation: take_warning gives the text once per key until the warnings are reset") {
    Deprecations& d = Deprecations::global();
    d.clear();  // no matter which test (or a tool's start-up) filled the global table before
    CHECK(d.empty());
    CHECK(d.take_warning("commands", "old.thing").empty());  // an empty table never warns
    TableGuard g(kTable);
    CHECK_FALSE(d.empty());
    CHECK(d.take_warning("commands", "other.thing").empty());  // not deprecated
    CHECK(d.take_warning("components", "old.thing").empty());  // another kind
    CHECK_FALSE(d.take_warning("commands", "old.thing").empty());
    CHECK(d.take_warning("commands", "old.thing").empty());                // once
    CHECK_FALSE(d.take_warning("components", "Sprite.oldField").empty());  // each key has its own
    d.reset_warned();
    CHECK_FALSE(d.take_warning("commands", "old.thing").empty());  // a new project load warns again
    CHECK(d.keys("commands") == std::vector<std::string>{"old.thing"});
}

TEST_CASE("deprecation: threads asking for the same warning get it exactly once") {
    TableGuard g(kTable);
    std::atomic<int> got{0};
    std::vector<std::thread> threads;
    for (int i = 0; i < 4; ++i)
        threads.emplace_back([&] {
            for (int n = 0; n < 200; ++n)
                if (!Deprecations::global().take_warning("commands", "old.thing").empty()) ++got;
        });
    for (auto& t : threads) t.join();
    CHECK(got == 1);
}

TEST_CASE("deprecation: a deprecated command warns once, names the replacement and still runs") {
    CommandRegistry reg;
    int runs = 0;
    for (const char* name : {"old.thing", "new.thing"}) {
        CommandInfo info;
        info.name = name;
        info.summary = "Does the thing.";
        info.category = "test";
        reg.add(info, [&runs](const Json&) {
            ++runs;
            return Json::object({{"done", true}});
        });
    }
    {  // nothing deprecated: no warning
        Deprecations::global().clear();
        DeprecatedLogCapture cap;
        REQUIRE(reg.call("old.thing", Json::object()).ok);
        CHECK(cap.get().empty());
    }
    TableGuard g(kTable);
    DeprecatedLogCapture cap;
    auto first = reg.call("old.thing", Json::object());
    REQUIRE(first.ok);  // the command still works
    CHECK(first.result["done"] == true);
    auto second = reg.call("old.thing", Json::object());
    REQUIRE(second.ok);
    REQUIRE(reg.call("new.thing", Json::object()).ok);  // the replacement is not deprecated
    CHECK(runs == 4);
    const auto lines = cap.get();
    REQUIRE(lines.size() == 1);  // once for the two calls
    CHECK(lines[0].find("command 'old.thing'") != std::string::npos);
    CHECK(lines[0].find("Use 'new.thing' instead") != std::string::npos);
    CHECK(lines[0].find("removed in 0.32.0") != std::string::npos);
}

TEST_CASE("deprecation: the lock-free pre-check never misses an entry and almost never lets another key through") {
    Deprecations& d = Deprecations::global();
    d.clear();
    CHECK_FALSE(d.may_contain("commands", "old.thing"));  // an empty table: nothing may be in it
    CHECK_FALSE(d.may_contain_component("Sprite"));
    TableGuard g(kTable);
    CHECK(d.may_contain("commands", "old.thing"));
    CHECK(d.may_contain("script", "NavAPI.oldCall"));
    CHECK(d.may_contain("components", "Gone"));
    CHECK(
        d.may_contain_component("Sprite"));  // "Sprite.oldField" is in the table: the component asks for the slow path
    CHECK(d.may_contain("components", "Sprite.oldField"));
    CHECK(d.may_contain_component("Gone"));
    CHECK_FALSE(d.may_contain("commands", "Gone"));  // a key of another kind
    int falsePositives = 0;
    for (int i = 0; i < 1000; ++i) {
        const std::string name = "Other" + std::to_string(i);
        if (d.may_contain_component(name)) ++falsePositives;
        if (d.may_contain("commands", "scene." + name)) ++falsePositives;
    }
    CHECK(falsePositives < 20);  // 2000 questions: the filter is only a shortcut, but it has to shortcut
    // What the filter says no to, take_warning says no to without a lock; what it says yes to still gets its warning.
    CHECK(d.take_warning("commands", "scene.Other1").empty());
    CHECK_FALSE(d.take_warning("components", "Sprite.oldField").empty());

    // Many entries: no false negative.
    Json big = Json::object({{"commands", Json::object()}, {"components", Json::object()}});
    for (int i = 0; i < 60; ++i) {
        big["commands"]["area" + std::to_string(i) + ".verb"] = Json::object({{"since", "0.30.0"}, {"use", "x.y"}});
        big["components"]["Comp" + std::to_string(i) + ".f"] = Json::object({{"since", "0.30.0"}, {"use", "Comp.g"}});
    }
    d.set(big);
    for (int i = 0; i < 60; ++i) {
        CHECK(d.may_contain("commands", "area" + std::to_string(i) + ".verb"));
        CHECK(d.may_contain_component("Comp" + std::to_string(i)));
    }
}

TEST_CASE("removed_field_hint names the PostProcess for the removed Camera post fields, whatever the case") {
    const std::string bloom = removed_field_hint("Camera", "bloom");
    CHECK(bloom.find("Camera.bloom was removed in 0.33.0") == 0);
    CHECK(bloom.find("PostProcess") != std::string::npos);
    const std::string filter = removed_field_hint("Camera", "colorFilter");
    CHECK(filter.find("Camera.colorFilter was removed in 0.33.0") == 0);
    CHECK(filter.find("colorFilterMode") != std::string::npos);
    // The field name ignores case, and the hint spells it as the table does.
    CHECK(removed_field_hint("Camera", "Bloom") == bloom);
    CHECK(removed_field_hint("Camera", "COLORFILTER") == filter);
    // A field never removed, a field of another component, an unknown component.
    CHECK(removed_field_hint("Camera", "fov").empty());
    CHECK(removed_field_hint("Light", "bloom").empty());
    CHECK(removed_field_hint("camera", "bloom").empty());
    CHECK(removed_field_hint("Camera", "").empty());
}
