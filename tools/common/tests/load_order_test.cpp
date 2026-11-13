// The first-use order of a project's files (fa/tooling/load_order.h): merge, read, record under the lock, pack order.
#include <doctest.h>

#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/tooling/export.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/load_order.h"
#include "fa/tooling/play_auto.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

LoadOrder order_of(std::initializer_list<SceneFiles> scenes) { return LoadOrder(scenes); }

std::string file_text(const stdfs::path& projectDir) { return testing::read_all(load_order_file(projectDir)); }

}  // namespace

TEST_CASE("load order merge: a known scene gains new files at its end, a new scene comes after the others") {
    const LoadOrder recorded = order_of({{"scenes/a.scene.json", {"scenes/a.scene.json", "img/a.png"}}});
    const LoadOrder seen = order_of({{"scenes/b.scene.json", {"scenes/b.scene.json", "img/b.png"}},
                                     {"scenes/a.scene.json", {"img/a.png", "img/a2.png"}}});
    LoadOrderMerge st;
    const LoadOrder merged = merge_load_order(recorded, seen, &st);
    REQUIRE(merged.size() == 2);
    CHECK(merged[0].scene == "scenes/a.scene.json");
    CHECK(merged[0].files == std::vector<std::string>{"scenes/a.scene.json", "img/a.png", "img/a2.png"});
    CHECK(merged[1].scene == "scenes/b.scene.json");
    CHECK(st.scenes == 2);
    CHECK(st.files == 5);
    CHECK(st.added == 3);
    // The same merge again adds nothing, and gives the same order (deterministic).
    LoadOrderMerge again;
    CHECK(merge_load_order(merged, seen, &again).size() == 2);
    CHECK(again.added == 0);
    CHECK(merge_load_order(recorded, seen) == merged);
}

TEST_CASE(
    "load order merge: a cold session (factoria run, play.auto) sets a scene's order, an editor Play only adds to it") {
    const LoadOrder editor = order_of({{"scenes/a.scene.json", {"scenes/a.scene.json", "img/late.png", "img/a.png"}}});
    // The cold run read a.png before late.png and never read late.png's neighbour: its order comes first, the rest after.
    const LoadOrder run =
        order_of({{"scenes/a.scene.json", {"scenes/a.scene.json", "img/a.png", "img/new.png", "img/a.png"}},
                  {"scenes/b.scene.json", {"img/b.png"}}});
    LoadOrderMerge st;
    const LoadOrder cold = merge_load_order(editor, run, &st, LoadOrderSource::Run);
    REQUIRE(cold.size() == 2);
    CHECK(cold[0].files == std::vector<std::string>{"scenes/a.scene.json", "img/a.png", "img/new.png", "img/late.png"});
    CHECK(cold[0].cold);
    CHECK(cold[1].cold);  // a scene a cold session adds is cold too
    CHECK(st.added == 2);
    CHECK(st.changed);

    // An editor Play afterwards does not reorder the cold scene: it only appends what it was missing.
    const LoadOrder play =
        order_of({{"scenes/a.scene.json", {"img/late.png", "img/editor.png", "scenes/a.scene.json"}}});
    LoadOrderMerge est;
    const LoadOrder after = merge_load_order(cold, play, &est, LoadOrderSource::Editor);
    CHECK(after[0].files == std::vector<std::string>{"scenes/a.scene.json", "img/a.png", "img/new.png", "img/late.png",
                                                     "img/editor.png"});
    CHECK(after[0].cold);
    CHECK(est.added == 1);

    // The same cold run again changes nothing; one that only marks a scene cold is a change.
    LoadOrderMerge same;
    merge_load_order(cold, run, &same, LoadOrderSource::Run);
    CHECK_FALSE(same.changed);
    LoadOrderMerge mark;
    const LoadOrder marked =
        merge_load_order(editor, order_of({{"scenes/a.scene.json", {}}}), &mark, LoadOrderSource::Run);
    CHECK(marked[0].files == editor[0].files);
    CHECK(marked[0].cold);
    CHECK(mark.changed);
    CHECK(mark.added == 0);
}

TEST_CASE("load order merge: absolute paths, '..' and backslashes are left out, and the caps hold") {
    const LoadOrder seen =
        order_of({{"s", {"/etc/passwd", "../up.png", "a\\b.png", "C:/x.png", "ok/..x.png", "ok/a.png", ""}}});
    const LoadOrder merged = merge_load_order({}, seen);
    REQUIRE(merged.size() == 1);
    CHECK(merged[0].files == std::vector<std::string>{"ok/..x.png", "ok/a.png"});

    LoadOrder many;
    for (std::size_t i = 0; i < kLoadOrderMaxScenes + 10; ++i)
        many.push_back(SceneFiles{"s" + std::to_string(i), {"f.png"}});
    LoadOrderMerge st;
    const LoadOrder capped = merge_load_order({}, many, &st);
    CHECK(capped.size() == kLoadOrderMaxScenes);
    CHECK(st.scenes == kLoadOrderMaxScenes);
    CHECK(capped.back().scene ==
          "s" + std::to_string(kLoadOrderMaxScenes - 1));  // the first ones stay, the rest is left out

    SceneFiles big{"big", {}};
    for (std::size_t i = 0; i < kLoadOrderMaxFiles + 5; ++i) big.files.push_back("f" + std::to_string(i));
    LoadOrderMerge bst;
    const LoadOrder bigMerged = merge_load_order({}, LoadOrder{big}, &bst);
    CHECK(bigMerged[0].files.size() == kLoadOrderMaxFiles);
    CHECK(bst.files == kLoadOrderMaxFiles);
    CHECK(bigMerged[0].files.back() == "f" + std::to_string(kLoadOrderMaxFiles - 1));
}

TEST_CASE("load order read: no file is an empty order, a damaged one names the file, the JSON pointer and the fix") {
    testing::TempDir dir;
    auto none = read_load_order(dir.path);
    REQUIRE(none.ok());
    CHECK(none.value().empty());

    testing::write_all(load_order_file(dir.path), R"({"format":"something/else","scenes":[]})");
    auto wrong = read_load_order(dir.path);
    REQUIRE_FALSE(wrong.ok());
    CHECK(wrong.error().message.find("load-order.json") != std::string::npos);
    CHECK(wrong.error().message.find("factoria.loadorder/1") != std::string::npos);
    CHECK(wrong.error().hint.find("delete it") != std::string::npos);

    testing::write_all(
        load_order_file(dir.path),
        R"({"format":"factoria.loadorder/1","scenes":[{"scene":"a","files":["x.png"]},{"scene":"b","files":["y.png",3]}]})");
    auto bad = read_load_order(dir.path);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/scenes/1/files/1") != std::string::npos);

    testing::write_all(load_order_file(dir.path), R"({"format":"factoria.loadorder/1","scenes":[{"files":[]}]})");
    auto noScene = read_load_order(dir.path);
    REQUIRE_FALSE(noScene.ok());
    CHECK(noScene.error().message.find("#/scenes/0/scene") != std::string::npos);

    testing::write_all(load_order_file(dir.path),
                       R"({"format":"factoria.loadorder/1","scenes":[{"scene":"a","files":[],"source":"cold"}]})");
    auto badSource = read_load_order(dir.path);
    REQUIRE_FALSE(badSource.ok());
    CHECK(badSource.error().message.find("#/scenes/0/source") != std::string::npos);

    testing::write_all(load_order_file(dir.path), "{ not json");
    CHECK_FALSE(read_load_order(dir.path).ok());
}

TEST_CASE("load order record: merges into the file under the project's lock and writes nothing when nothing is new") {
    testing::ScratchShareHome home;
    testing::TempDir dir;
    auto first =
        record_load_order(dir.path, order_of({{"scenes/main.scene.json", {"scenes/main.scene.json", "a.png"}}}));
    REQUIRE_MESSAGE(first.ok(), (first.ok() ? std::string() : first.error().message));
    CHECK(first.value().added == 2);
    const std::string written = file_text(dir.path);
    CHECK(written.find("factoria.loadorder/1") != std::string::npos);

    auto second = record_load_order(dir.path, order_of({{"scenes/main.scene.json", {"a.png", "b.png"}}}));
    REQUIRE(second.ok());
    CHECK(second.value().added == 1);
    auto read = read_load_order(dir.path);
    REQUIRE(read.ok());
    REQUIRE(read.value().size() == 1);
    CHECK(read.value()[0].files == std::vector<std::string>{"scenes/main.scene.json", "a.png", "b.png"});

    const std::string before = file_text(dir.path);
    auto same = record_load_order(dir.path, order_of({{"scenes/main.scene.json", {"b.png"}}}));
    REQUIRE(same.ok());
    CHECK(same.value().added == 0);
    CHECK(file_text(dir.path) == before);
    // The lock is released: no lock file is left in the cache folder.
    CHECK_FALSE(stdfs::exists(dir.path / ".factoria" / "cache" / kFeedbackShareLockFile));
}

TEST_CASE(
    "load order record: the file keeps each scene's source, and a factoria run reorders what an editor Play wrote") {
    testing::ScratchShareHome home;
    testing::TempDir dir;
    REQUIRE(record_load_order(dir.path, order_of({{"s", {"b.png", "a.png"}}, {"t", {"c.png"}}})).ok());
    auto run = record_load_order(dir.path, order_of({{"s", {"a.png", "b.png"}}}), LoadOrderSource::Run);
    REQUIRE_MESSAGE(run.ok(), (run.ok() ? std::string() : run.error().message));
    CHECK(run.value().changed);
    CHECK(run.value().added == 0);
    CHECK(file_text(dir.path).find("\"source\": \"run\"") != std::string::npos);
    auto read = read_load_order(dir.path);
    REQUIRE(read.ok());
    REQUIRE(read.value().size() == 2);
    CHECK(read.value()[0].files == std::vector<std::string>{"a.png", "b.png"});
    CHECK(read.value()[0].cold);
    CHECK_FALSE(read.value()[1].cold);
    // An editor Play with the old order leaves the file as it is.
    const std::string before = file_text(dir.path);
    auto play = record_load_order(dir.path, order_of({{"s", {"b.png", "a.png"}}}));
    REQUIRE(play.ok());
    CHECK_FALSE(play.value().changed);
    CHECK(file_text(dir.path) == before);
}

TEST_CASE("load order record: nothing is recorded for a folder inside an exported game") {
    testing::ScratchShareHome home;
    testing::TempDir dir;
    const stdfs::path game = dir.path / u8"jeu-exporté-macos" / "Game.app" / "Contents" / "Resources" / "game";
    stdfs::create_directories(game);
    testing::write_all(dir.path / u8"jeu-exporté-macos" / kExportMarkerFile, "factoria export\n");
    std::string why;
    CHECK_FALSE(load_order_recordable(game, &why));
    CHECK(why.find("exported game") != std::string::npos);
    auto r = record_load_order(game, order_of({{"s", {"a.png"}}}), LoadOrderSource::Run);
    REQUIRE(r.ok());
    CHECK(r.value().skipped);
    CHECK_FALSE(r.value().changed);
    CHECK_FALSE(stdfs::exists(load_order_file(game)));
    CHECK_FALSE(stdfs::exists(game / ".factoria"));
    // The project itself, next to its export, records as usual.
    CHECK(load_order_recordable(dir.path));
}

TEST_CASE("load order record: a damaged file is replaced by this session's order") {
    testing::ScratchShareHome home;
    testing::TempDir dir;
    testing::write_all(load_order_file(dir.path), "{ damaged");
    auto r = record_load_order(dir.path, order_of({{"s", {"a.png"}}}));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message));
    auto read = read_load_order(dir.path);
    REQUIRE(read.ok());
    REQUIRE(read.value().size() == 1);
    CHECK(read.value()[0].files == std::vector<std::string>{"a.png"});
}

TEST_CASE("load order record: a lock another program holds is reported and changes nothing") {
    testing::ScratchShareHome home;
    testing::TempDir dir;
    REQUIRE(record_load_order(dir.path, order_of({{"s", {"a.png"}}})).ok());
    const std::string before = file_text(dir.path);

    ShareEnv busy = share_env();
    busy.lockWaitSec = 0.2;
    busy.lockStaleSec = 600.0;  // the lock file below is never taken over as a dead holder's
    ScopedShareEnv scoped(busy);
    const stdfs::path lockFile = dir.path / ".factoria" / "cache" / kFeedbackShareLockFile;
    testing::write_all(lockFile, "alive");

    auto blocked = record_load_order(dir.path, order_of({{"s", {"b.png"}}}));
    REQUIRE_FALSE(blocked.ok());
    CHECK(blocked.error().message.find("was not recorded") != std::string::npos);
    CHECK_FALSE(blocked.error().hint.empty());
    CHECK(file_text(dir.path) == before);                              // nothing half-written
    record_load_order_logged(dir.path, order_of({{"s", {"c.png"}}}));  // logs, never throws, writes nothing
    CHECK(file_text(dir.path) == before);

    std::error_code ec;
    stdfs::remove(lockFile, ec);
    auto free = record_load_order(dir.path, order_of({{"s", {"b.png"}}}));
    REQUIRE_MESSAGE(free.ok(), (free.ok() ? std::string() : free.error().message));
    CHECK(free.value().added == 1);
}

TEST_CASE("load order record_async: writes land in the order they were queued, and wait returns once they are done") {
    testing::ScratchShareHome home;
    testing::TempDir dir;
    for (int i = 0; i < 8; ++i)
        record_load_order_async(dir.path, order_of({{"s", {"f" + std::to_string(i) + ".png"}}}));
    record_load_order_async(dir.path, {});  // an empty order queues nothing
    wait_load_order_writes();
    auto read = read_load_order(dir.path);
    REQUIRE(read.ok());
    REQUIRE(read.value().size() == 1);
    std::vector<std::string> want;
    for (int i = 0; i < 8; ++i) want.push_back("f" + std::to_string(i) + ".png");
    CHECK(read.value()[0].files == want);
}

TEST_CASE("pack order: the start-up files, the main scene's, then the other scenes', each shipped file once, the scene "
          "file first") {
    const LoadOrder recorded = order_of({
        {"scenes/menu.scene.json", {"ui/menu.png", "fonts/a.ttf"}},
        {LoadTrace::kStartupScene, {"factoria.json", "scripts/boot.js"}},
        {"scenes/main.scene.json", {"img/hero.png", "scenes/main.scene.json", "dev/only.txt", "fonts/a.ttf"}},
        {"scenes/gone.scene.json", {"old.png"}},
    });
    const std::vector<std::string> shipped = {
        "factoria.json",          "fonts/a.ttf",     "img/hero.png", "scenes/main.scene.json",
        "scenes/menu.scene.json", "scripts/boot.js", "ui/menu.png"};
    const PackOrder po = pack_order(recorded, "scenes/main.scene.json", shipped);
    CHECK(po.files == std::vector<std::string>{"factoria.json", "scripts/boot.js", "scenes/main.scene.json",
                                               "img/hero.png", "fonts/a.ttf", "scenes/menu.scene.json", "ui/menu.png"});
    CHECK(po.scenes == 3);  // the start-up group counts; the scene whose files no longer ship gives nothing

    const PackOrder none = pack_order({}, "scenes/main.scene.json", shipped);
    CHECK(none.files.empty());
    CHECK(none.scenes == 0);
}

TEST_CASE("load order record: play.auto in a folder with an accent records into that folder (the path stays native)") {
    testing::TempDir tmp;
    const stdfs::path project = tmp.path / stdfs::path(u8"juego-Adrià");
    testing::write_all(
        project / "factoria.json",
        R"({"format":"factoria.project/1","name":"Acc","id":"com.example.acc","mainScene":"scenes/main.scene.json",
                           "display":{"width":64,"height":64}})");
    testing::write_all(project / "scenes" / "main.scene.json",
                       R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
    // The tooling carries a project folder as a native string (what a command line or current_path().string() gives),
    // the way the engine builds its root from it: on Windows that is the code page, never UTF-8.
    const std::string nativeDir = project.string();
    CommandRegistry registry;
    register_play_auto_commands(registry, nativeDir);
    const CommandResult r = registry.call("play.auto", Json::object({{"seconds", 0.5}, {"screenshots", false}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(stdfs::exists(load_order_file(project)));
    auto order = read_load_order(project);
    REQUIRE(order.ok());
    REQUIRE(!order.value().empty());
    CHECK(order.value().front().scene ==
          "scenes/main.scene.json");  // factoria.json is read by an absolute path: not the game's read
    CHECK(order.value().front().cold);
}
