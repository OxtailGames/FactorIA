// Several AI chats running at the same time: the per-run state, the same-file tracker, the scope of a Revert and the shared
// main-thread queue. None of it needs a window.
#include <atomic>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <thread>

#include "ai_chat.h"
#include "ai_runs.h"
#include "doctest.h"
#include "editor_internal.h"
#include "fa/core/fs.h"
#include "fa/tooling/checkpoint.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

ai::AgentEvent event(ai::AgentEvent::Type type, const std::string& tool = {}, int depth = 0) {
    ai::AgentEvent ev;
    ev.type = type;
    ev.toolName = tool;
    ev.depth = depth;
    return ev;
}

ai::AiRunInfo worker(const std::string& id) {
    ai::AiRunInfo info;
    info.id = id;
    info.role = "worker";
    info.task = "do it";
    return info;
}

struct Dir {
    stdfs::path path = fa::fs::make_temp_dir("fa_ai_runs_test");
    ~Dir() {
        std::error_code ec;
        fa::fs::remove_tree(path, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((path / rel).parent_path());
        std::ofstream(path / rel, std::ios::binary) << text;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(path / rel, std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
};

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// AiRun

TEST_CASE("AiRun: two runs keep their own events, activity and tool calls") {
    AiRun a("chat-a"), b("chat-b");
    a.note_event(event(ai::AgentEvent::Type::ToolStart, "Bash"), 100);
    b.note_event(event(ai::AgentEvent::Type::TextDelta), 200);
    CHECK(a.lastActivityMs == 100);
    CHECK(b.lastActivityMs == 200);
    CHECK(a.tools.size() == 1);
    CHECK(b.tools.empty());
    CHECK_FALSE(a.activity_line().empty());
    a.note_event(event(ai::AgentEvent::Type::ToolEnd, "Bash"), 300);
    CHECK(a.tools.empty());
    auto da = a.drain();
    auto db = b.drain();
    CHECK(da.events.size() == 2);
    CHECK(db.events.size() == 1);
    CHECK(a.drain().events.empty());  // drained once
}

TEST_CASE("AiRun: a delegated worker still running when the turn ends keeps the run active until it ends") {
    AiRun run("chat");
    run.running = true;
    run.reset_live(10);
    CHECK(run.active());
    run.delegate_started(worker("run-1"), 20);
    run.delegate_process(worker("run-1"), 4242);
    run.process_started(1, "orchestrator");
    CHECK(run.processes().size() == 2);
    ai::SessionResult r;
    r.ok = true;
    run.turn_ended(r);
    CHECK_FALSE(run.running.load());
    CHECK(run.detached.load());
    CHECK(run.active());  // no flicker between running and detached
    CHECK(run.processes().size() == 1);  // the orchestrator's own process is gone, the worker's stays
    {
        auto d = run.drain();
        CHECK(d.result.has_value());
        CHECK(d.detached);
        CHECK_FALSE(d.orphansDone);
    }
    run.delegate_ended(worker("run-1"), true, "report", "", 30);
    auto d = run.drain();
    CHECK_FALSE(d.result.has_value());
    CHECK(d.orphansDone);
    REQUIRE(d.finished.size() == 1);
    CHECK(d.finished[0].report == "report");
    CHECK(run.processes().empty());
    run.detached = false;
    CHECK_FALSE(run.active());
}

TEST_CASE("AiRun: a turn that ends with every worker done is not detached") {
    AiRun run("chat");
    run.running = true;
    run.delegate_started(worker("run-1"), 1);
    run.delegate_ended(worker("run-1"), true, "ok", "", 2);
    run.turn_ended(ai::SessionResult{});
    CHECK_FALSE(run.detached.load());
    CHECK_FALSE(run.active());
}

TEST_CASE("AiRun: a worker's events are shown one level in and tagged with its run") {
    AiRun run("chat");
    run.delegate_event(worker("run-7"), event(ai::AgentEvent::Type::ToolStart, "Bash", 0), 5);
    auto d = run.drain();
    REQUIRE(d.events.size() == 1);
    CHECK(d.events[0].depth == 1);
    CHECK(d.events[0].runId == "run-7");
}

TEST_CASE("AiRun: reset_live clears what a previous run left") {
    AiRun run("chat");
    run.delegate_started(worker("run-1"), 1);
    run.note_event(event(ai::AgentEvent::Type::ToolStart, "Bash"), 2);
    run.snoozeUntil = 99;
    run.reset_live(500);
    CHECK(run.delegates.empty());
    CHECK(run.tools.empty());
    CHECK(run.activity_line().empty());
    CHECK(run.startMs == 500);
    CHECK(run.lastActivityMs == 500);
    CHECK(run.snoozeUntil == 0);
}

TEST_CASE("AiRun: request_cancel keeps the first cause, reset_live forgets it") {
    AiRun run("chat");
    CHECK(run.cancel_cause().empty());
    run.request_cancel("user_stop");
    run.request_cancel("run_ended");
    CHECK(run.cancel.load());
    CHECK(run.cancel_cause() == "user_stop");
    run.cancel = false;
    run.reset_live(1);
    CHECK(run.cancel_cause().empty());
}

TEST_CASE("agent_process_gone: needs an empty list, silence and the OS agreeing") {
    auto no = [](long long) { return false; };
    auto yes = [](long long) { return true; };
    CHECK(agent_process_gone(42, true, 30, +no));
    CHECK_FALSE(agent_process_gone(42, true, 30, +yes));  // the list missed a process that lives
    CHECK_FALSE(agent_process_gone(42, true, 3, +no));    // the run still reports: not dead
    CHECK_FALSE(agent_process_gone(42, false, 30, +no));  // the list shows it
}

// ---------------------------------------------------------------------------------------------------------------------
// What a call changed

TEST_CASE("project_relative: inside the project only") {
    CHECK(project_relative("scripts/a.js", "/p") == "scripts/a.js");
    CHECK(project_relative("./scripts//a.js", "/p") == "scripts/a.js");
    CHECK(project_relative("scripts\\a.js", "/p") == "scripts/a.js");
    CHECK(project_relative("/p/scripts/a.js", "/p") == "scripts/a.js");
    CHECK(project_relative("/p/scripts/a.js", "/p/") == "scripts/a.js");
    CHECK(project_relative("/other/a.js", "/p").empty());
    CHECK(project_relative("../a.js", "/p").empty());
    CHECK(project_relative("a/../../b.js", "/p").empty());
    CHECK(project_relative("", "/p").empty());
    CHECK(project_relative(".", "/p").empty());
}

TEST_CASE("command_touched_files: path arguments, the saved scene and the open scene") {
    using V = std::vector<std::string>;
    CHECK(command_touched_files("fs.write", Json::object({{"path", "scripts/a.js"}, {"content", "x"}}), Json::object(), false, false,
                                "", "/p") == V{"scripts/a.js"});
    CHECK(command_touched_files("fs.read", Json::object({{"path", "scripts/a.js"}}), Json::object(), true, false, "", "/p").empty());
    CHECK(command_touched_files("fs.move", Json::object({{"from", "a.js"}, {"to", "b.js"}}), Json::object(), false, false, "", "/p") ==
          V{"a.js", "b.js"});
    CHECK(command_touched_files("x.y", Json::object({{"paths", Json::array({"a.js", "../out.js"})}}), Json::object(), false, false, "",
                                "/p") == V{"a.js"});
    CHECK(command_touched_files("scene.import", Json::object(), Json::object({{"saved", "scenes/x.scene.json"}}), false, false, "",
                                "/p") == V{"scenes/x.scene.json"});
    // A command that edits the open scene changes the scene's file; saving with no path writes it too.
    CHECK(command_touched_files("entity.set", Json::object({{"id", 3}}), Json::object(), false, true, "scenes/main.scene.json", "/p") ==
          V{"scenes/main.scene.json"});
    CHECK(command_touched_files("scene.save", Json::object(), Json::object(), false, false, "scenes/main.scene.json", "/p") ==
          V{"scenes/main.scene.json"});
    CHECK(command_touched_files("scene.save", Json::object({{"path", "scenes/other.scene.json"}}), Json::object(), false, false,
                                "scenes/main.scene.json", "/p") == V{"scenes/other.scene.json"});
}

TEST_CASE("tool_touched_files: the CLI agent's own file tools") {
    using V = std::vector<std::string>;
    CHECK(tool_touched_files("Write", Json::object({{"file_path", "/p/scripts/a.js"}}), "/p") == V{"scripts/a.js"});
    CHECK(tool_touched_files("Edit", Json::object({{"file_path", "scripts/a.js"}}), "/p") == V{"scripts/a.js"});
    CHECK(tool_touched_files("MultiEdit", Json::object({{"file_path", "scripts/a.js"}}), "/p") == V{"scripts/a.js"});
    CHECK(tool_touched_files("NotebookEdit", Json::object({{"notebook_path", "n.ipynb"}}), "/p") == V{"n.ipynb"});
    CHECK(tool_touched_files("Write", Json::object({{"file_path", "/elsewhere/a.js"}}), "/p").empty());
    CHECK(tool_touched_files("Read", Json::object({{"file_path", "scripts/a.js"}}), "/p").empty());
    CHECK(tool_touched_files("Bash", Json::object({{"command", "rm a"}}), "/p").empty());
    CHECK(tool_touched_files("Write", Json(), "/p").empty());
}

// ---------------------------------------------------------------------------------------------------------------------
// RunTouchTracker

TEST_CASE("RunTouchTracker: two runs that change the same file at the same time are reported once") {
    RunTouchTracker t;
    t.begin("a");
    t.begin("b");
    CHECK(t.active_count() == 2);
    CHECK(t.touch("a", "scenes/main.scene.json").empty());
    auto c = t.touch("b", "scenes/main.scene.json");
    REQUIRE(c.size() == 1);
    CHECK(c[0].file == "scenes/main.scene.json");
    CHECK(c[0].run == "b");
    CHECK(c[0].other == "a");
    CHECK(t.touch("b", "scenes/main.scene.json").empty());  // already known for b
    CHECK(t.touch("a", "scenes/main.scene.json").empty());  // already known for a
    CHECK(t.touch("a", "scripts/only_a.js").empty());
    CHECK(t.touch("b", "scripts/only_b.js").empty());
    CHECK(t.touched("a").size() == 2);
    CHECK(t.touched_by_others("a") == std::set<std::string>{"scenes/main.scene.json", "scripts/only_b.js"});
    CHECK(t.overlapped("a"));
    CHECK(t.overlapping("a") == std::vector<std::string>{"b"});
}

TEST_CASE("RunTouchTracker: runs one after the other do not conflict") {
    RunTouchTracker t;
    t.begin("a");
    t.touch("a", "x.js");
    CHECK(t.end("a", {"x.js"}).empty());
    t.begin("b");
    CHECK(t.touch("b", "x.js").empty());
    CHECK_FALSE(t.overlapped("b"));
    CHECK(t.end("b", {"x.js"}).empty());
    CHECK(t.active_count() == 0);
}

TEST_CASE("RunTouchTracker: a run that ended while another one was going still conflicts with it") {
    RunTouchTracker t;
    t.begin("a");
    t.begin("b");
    t.touch("a", "x.js");
    CHECK(t.end("a", {"x.js"}).empty());
    auto c = t.touch("b", "x.js");  // a is over but ran while b did, and the record is kept for b
    REQUIRE(c.size() == 1);
    CHECK(c[0].run == "b");
    CHECK(c[0].other == "a");
    CHECK(t.touched_by_others("b") == std::set<std::string>{"x.js"});
}

TEST_CASE("RunTouchTracker: the checkpoint's files are compared when a run ends") {
    RunTouchTracker t;
    t.begin("a");
    t.begin("b");
    t.touch("a", "x.js");
    // b wrote x.js from a Bash command: no tool call named it, the checkpoint diff finds it.
    auto c = t.end("b", {"x.js", "y.js"});
    REQUIRE(c.size() == 1);
    CHECK(c[0].file == "x.js");
    CHECK(c[0].run == "b");
    CHECK(c[0].other == "a");
}

TEST_CASE("RunTouchTracker: a chat's next run is a new record and old records are forgotten") {
    RunTouchTracker t;
    t.begin("a");
    t.touch("a", "x.js");
    t.end("a", {"x.js"});
    CHECK(t.touched("a").empty());  // nothing is kept once no running run can overlap it
    t.begin("a");
    CHECK(t.active("a"));
    CHECK(t.touched("a").empty());
    t.end("a", {});
    CHECK_FALSE(t.active("a"));
}

TEST_CASE("attribute_files: a file only another run changed is not credited") {
    const std::vector<std::string> changed = {"mine.js", "bash_wrote.js", "theirs.js", "both.js"};
    auto out = attribute_files(changed, {"mine.js", "both.js"}, {"theirs.js", "both.js"});
    CHECK(out == std::vector<std::string>{"mine.js", "bash_wrote.js", "both.js"});
}

TEST_CASE("group_conflicts and conflict_text") {
    std::vector<FileConflict> in = {{"a.js", "b", "a"}, {"b.js", "b", "a"}, {"c.js", "c", "a"}};
    auto notes = group_conflicts(in);
    REQUIRE(notes.size() == 2);
    CHECK(notes[0].files == std::vector<std::string>{"a.js", "b.js"});
    CHECK(notes[1].other == "a");
    const std::string t = conflict_text("Fix the menu", true, {"a.js", "b.js", "c.js", "d.js", "e.js", "f.js"});
    CHECK(t.find("\"Fix the menu\"") != std::string::npos);
    CHECK(t.find("is running at the same time") != std::string::npos);
    CHECK(t.find("and 2 more") != std::string::npos);
    CHECK(conflict_text("", false, {"a.js"}).find("ran at the same time") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------------
// Revert of one run

TEST_CASE("plan_revert: alone, the whole checkpoint goes back") {
    auto p = plan_revert({"a.js"}, "", false, {});
    CHECK(p.whole);
    CHECK(p.shared.empty());
    CHECK(p.running.empty());
}

TEST_CASE("plan_revert: with other chats only the run's files go back and the shared ones are listed") {
    RunRecord other;
    other.chat = "Menu";
    other.files = {"b.js", "scenes/main.scene.json"};
    other.running = true;
    RunRecord unrelated;
    unrelated.chat = "Audio";
    unrelated.files = {"sfx.js"};
    auto p = plan_revert({"a.js", "b.js", "scenes/main.scene.json"}, "scenes/main.scene.json", false, {other, unrelated});
    CHECK_FALSE(p.whole);
    CHECK(p.files == std::vector<std::string>{"a.js", "b.js", "scenes/main.scene.json"});
    REQUIRE(p.shared.size() == 2);
    CHECK(p.shared[0].file == "b.js");
    CHECK(p.shared[0].chats == std::vector<std::string>{"Menu"});
    CHECK(p.sceneShared);
    CHECK(p.running == std::vector<std::string>{"Menu"});
}

TEST_CASE("plan_revert: a file list that was cut cannot be a scope") {
    RunRecord other;
    other.chat = "Menu";
    other.files = {"b.js"};
    auto p = plan_revert({"a.js"}, "", true, {other});
    CHECK(p.whole);
    REQUIRE(p.shared.size() == 1);
    CHECK(p.shared[0].file == "b.js");
}

TEST_CASE("reverting one run with a scoped restore leaves the other run's files alone") {
    Dir d;
    d.write("scripts/a.js", "a0\n");
    d.write("scripts/shared.js", "s0\n");
    auto cp = checkpoint_create(d.path.string(), "before run A");
    REQUIRE(cp.ok());
    // Run A (this chat) and run B (another chat) change files at the same time; both touch shared.js.
    d.write("scripts/a.js", "a1\n");
    d.write("scripts/new_a.js", "new a\n");
    d.write("scripts/shared.js", "s1\n");
    d.write("scripts/b.js", "b1\n");
    RunRecord b;
    b.chat = "B";
    b.files = {"scripts/b.js", "scripts/shared.js"};
    auto plan = plan_revert({"scripts/a.js", "scripts/new_a.js", "scripts/shared.js"}, "", false, {b});
    REQUIRE_FALSE(plan.whole);
    REQUIRE(plan.shared.size() == 1);
    // "Revert, keep their changes": the shared file stays.
    std::vector<std::string> keep;
    for (const std::string& f : plan.files)
        if (f != plan.shared[0].file) keep.push_back(f);
    auto r = checkpoint_restore(d.path.string(), cp.value().info.id, keep);
    REQUIRE(r.ok());
    CHECK(d.read("scripts/a.js") == "a0\n");
    CHECK_FALSE(stdfs::exists(d.path / "scripts/new_a.js"));
    CHECK(d.read("scripts/shared.js") == "s1\n");
    CHECK(d.read("scripts/b.js") == "b1\n");
}

TEST_CASE("ChatItem keeps when a run ran, its scene and a scoped revert through the chat file") {
    ChatItem run;
    run.kind = ChatItem::Kind::Run;
    run.checkpointId = "cp";
    run.startedAt = 100;
    run.endedAt = 160;
    run.scenePath = "scenes/main.scene.json";
    run.modified = {"scenes/main.scene.json"};
    ChatItem back = ChatItem::from_json(run.to_json());
    CHECK(back.startedAt == 100);
    CHECK(back.endedAt == 160);
    CHECK(back.scenePath == "scenes/main.scene.json");
    ChatItem rev;
    rev.kind = ChatItem::Kind::Revert;
    rev.scoped = true;
    CHECK(ChatItem::from_json(rev.to_json()).scoped);
    // A chat saved before runs could overlap has no times: it is read as a run with no start.
    Json old = run.to_json();
    old.erase("startedAt");
    old.erase("endedAt");
    CHECK(ChatItem::from_json(old).startedAt == 0);
}

// ---------------------------------------------------------------------------------------------------------------------
// The shared main-thread queue with two producers

TEST_CASE("MainThreadQueue: two runs' calls are told apart by their tag") {
    MainThreadQueue q;
    std::atomic<int> done{0};
    CommandResult ra, rb;
    std::thread ta([&] {
        ra = q.call("x.a", Json::object(), nullptr, "chat-a");
        ++done;
    });
    std::thread tb([&] {
        rb = q.call("x.b", Json::object(), nullptr, "chat-b");
        ++done;
    });
    std::map<std::string, std::string> tagOf;
    for (int i = 0; i < 400 && done < 2; ++i) {
        q.pump([&](const std::string& name, const Json&) {
            tagOf[name] = q.current_tag();
            CommandResult r;
            r.ok = true;
            r.result = Json::object({{"tag", q.current_tag()}});
            return r;
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    ta.join();
    tb.join();
    CHECK(tagOf["x.a"] == "chat-a");
    CHECK(tagOf["x.b"] == "chat-b");
    CHECK(ra.result["tag"] == "chat-a");
    CHECK(rb.result["tag"] == "chat-b");
    CHECK(q.current_tag().empty());  // outside a job there is none
}

TEST_CASE("MainThreadQueue: stopping one run drops its queued job and leaves the other run's alone") {
    MainThreadQueue q;
    std::atomic<bool> stopA{false};
    CommandResult ra, rb;
    std::atomic<int> done{0};
    std::thread ta([&] {
        ra = q.call("x.a", Json::object(), &stopA, "chat-a");
        ++done;
    });
    std::thread tb([&] {
        rb = q.call("x.b", Json::object(), nullptr, "chat-b");
        ++done;
    });
    while (q.size() < 2) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    stopA = true;  // Stop on chat A's run
    ta.join();
    CHECK_FALSE(ra.ok);
    std::vector<std::string> ran;
    for (int i = 0; i < 400 && done < 2; ++i) {
        q.pump([&](const std::string& name, const Json&) {
            ran.push_back(name);
            CommandResult r;
            r.ok = true;
            return r;
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    tb.join();
    CHECK(rb.ok);
    CHECK(ran == std::vector<std::string>{"x.b"});  // A's job was not run after A was stopped
}

TEST_CASE("MainThreadQueue: a sliced command from one run is not overwritten by another run's") {
    MainThreadQueue q;
    std::atomic<int> done{0};
    CommandResult ra, rb;
    std::thread ta([&] {
        ra = q.call("long.a", Json::object(), nullptr, "chat-a");
        ++done;
    });
    while (q.size() < 1) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    std::thread tb([&] {
        rb = q.call("long.b", Json::object(), nullptr, "chat-b");
        ++done;
    });
    while (q.size() < 2) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    std::shared_ptr<std::promise<CommandResult>> sliced;
    std::vector<std::string> ran;
    auto run = [&](const std::string& name, const Json&) -> std::optional<CommandResult> {
        ran.push_back(name);
        if (name == "long.a" && !sliced) {
            sliced = q.take_current();  // the command continues over the next frames
            return std::nullopt;
        }
        CommandResult r;
        r.ok = true;
        return r;
    };
    CHECK(q.pump(run) == 1);  // stops after the sliced job; long.b waits
    CHECK(ran == std::vector<std::string>{"long.a"});
    CHECK(q.size() == 1);
    REQUIRE(sliced);
    CommandResult fin;
    fin.ok = true;
    fin.result = Json::object({{"done", true}});
    sliced->set_value(fin);
    for (int i = 0; i < 400 && done < 2; ++i) {
        q.pump(run);
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    ta.join();
    tb.join();
    CHECK(ra.ok);
    CHECK(ra.result["done"] == true);
    CHECK(rb.ok);
    CHECK(ran == std::vector<std::string>{"long.a", "long.b"});
}
