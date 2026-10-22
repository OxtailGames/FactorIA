// Project checkpoints (fa/tooling/checkpoint.h): create, diff, restore with its safety checkpoint, dedupe, the stat cache,
// retention and object GC, the skipped folders, and the commands.
#include <doctest.h>

#include <chrono>
#include <filesystem>

#include "fa/core/command.h"
#include "fa/tooling/checkpoint.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
using fa::testing::read_all;
using fa::testing::TempDir;
using fa::testing::write_all;
namespace stdfs = std::filesystem;

namespace {

// Puts every file's mtime well in the past so the stat cache trusts it (a file changed in the last 2 s is rehashed).
void age_files(const TempDir& dir) {
    std::error_code ec;
    static const auto when = stdfs::file_time_type::clock::now() - std::chrono::hours(1);  // the same instant every call
    for (stdfs::recursive_directory_iterator it(dir.path, ec), end; !ec && it != end; it.increment(ec))
        if (it->is_regular_file(ec)) stdfs::last_write_time(it->path(), when, ec);
}

std::size_t count_objects(const TempDir& dir) {
    std::size_t n = 0;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(dir.path / ".factoria/checkpoints/objects", ec), end; !ec && it != end; it.increment(ec))
        if (it->is_regular_file(ec)) ++n;
    return n;
}

struct Project {
    TempDir dir;
    Project() {
        write_all(dir.path / "scripts/player.js", "let a = 1;\n");
        write_all(dir.path / "scenes/main.scene.json", "{}\n");
        write_all(dir.path / "assets/hero.png", std::string("\x89PNG\0\1\2", 7));
    }
    Result<CheckpointCreated> make(const std::string& label = "test") { return checkpoint_create(dir.str(), label); }
};

}  // namespace

TEST_CASE("checkpoint: create stores every file and lists newest first") {
    Project p;
    auto a = p.make("first");
    REQUIRE(a.ok());
    CHECK(a.value().info.files == 3);
    CHECK(a.value().bytesStored > 0);
    write_all(p.dir.path / "scripts/enemy.js", "x\n");
    auto b = p.make("second");
    REQUIRE(b.ok());
    CHECK(b.value().info.id != a.value().info.id);
    const auto list = checkpoint_list(p.dir.str());
    REQUIRE(list.size() == 2);
    CHECK(list[0].id == b.value().info.id);
    CHECK(list[0].label == "second");
    CHECK(list[0].files == 4);
    CHECK(list[1].label == "first");
}

TEST_CASE("checkpoint: diff reports modified, added and deleted files") {
    Project p;
    auto cp = p.make();
    REQUIRE(cp.ok());
    CHECK(checkpoint_diff(p.dir.str(), cp.value().info.id).value().empty());
    write_all(p.dir.path / "scripts/player.js", "let a = 2;\n");
    write_all(p.dir.path / "scripts/new.js", "n\n");
    stdfs::remove(p.dir.path / "scenes/main.scene.json");
    auto d = checkpoint_diff(p.dir.str(), cp.value().info.id);
    REQUIRE(d.ok());
    CHECK(d.value().modified == std::vector<std::string>{"scripts/player.js"});
    CHECK(d.value().added == std::vector<std::string>{"scripts/new.js"});
    CHECK(d.value().deleted == std::vector<std::string>{"scenes/main.scene.json"});
}

TEST_CASE("checkpoint: restore puts files back, removes added ones and makes a safety checkpoint") {
    Project p;
    auto cp = p.make("before the AI");
    REQUIRE(cp.ok());
    write_all(p.dir.path / "scripts/player.js", "let a = 2;\n");
    write_all(p.dir.path / "scripts/deep/new.js", "n\n");
    stdfs::remove(p.dir.path / "scenes/main.scene.json");
    write_all(p.dir.path / "assets/hero.png", "other");

    auto r = checkpoint_restore(p.dir.str(), cp.value().info.id);
    REQUIRE(r.ok());
    CHECK(r.value().changes.modified.size() == 2);
    CHECK(r.value().changes.added == std::vector<std::string>{"scripts/deep/new.js"});
    CHECK(r.value().changes.deleted == std::vector<std::string>{"scenes/main.scene.json"});
    CHECK(read_all(p.dir.path / "scripts/player.js") == "let a = 1;\n");
    CHECK(read_all(p.dir.path / "scenes/main.scene.json") == "{}\n");
    CHECK(read_all(p.dir.path / "assets/hero.png") == std::string("\x89PNG\0\1\2", 7));
    CHECK_FALSE(stdfs::exists(p.dir.path / "scripts/deep/new.js"));
    CHECK_FALSE(stdfs::exists(p.dir.path / "scripts/deep"));  // the folder the AI made went too
    CHECK(checkpoint_diff(p.dir.str(), cp.value().info.id).value().empty());

    // The safety checkpoint holds the state before the restore: restoring it takes the restore back.
    const auto list = checkpoint_list(p.dir.str());
    REQUIRE(list.size() == 2);
    CHECK(list[0].id == r.value().safetyId);
    CHECK(list[0].label == "Before restoring before the AI");
    REQUIRE(checkpoint_restore(p.dir.str(), r.value().safetyId).ok());
    CHECK(read_all(p.dir.path / "scripts/player.js") == "let a = 2;\n");
    CHECK(stdfs::exists(p.dir.path / "scripts/deep/new.js"));
    CHECK_FALSE(stdfs::exists(p.dir.path / "scenes/main.scene.json"));
}

TEST_CASE("checkpoint: unchanged content is stored once") {
    Project p;
    auto a = p.make();
    REQUIRE(a.ok());
    const std::size_t objects = count_objects(p.dir);
    CHECK(objects == 3);
    auto b = p.make();
    REQUIRE(b.ok());
    CHECK(b.value().bytesStored == 0);
    CHECK(count_objects(p.dir) == objects);
    write_all(p.dir.path / "scripts/player.js", "let a = 22222;\n");
    auto c = p.make();
    CHECK(c.value().bytesStored == std::string("let a = 22222;\n").size());
    CHECK(count_objects(p.dir) == objects + 1);
    // Two files with the same content share one object.
    write_all(p.dir.path / "scripts/copy.js", "let a = 22222;\n");
    CHECK(p.make().value().bytesStored == 0);
}

TEST_CASE("checkpoint: the stat cache skips reading unchanged files") {
    Project p;
    age_files(p.dir);
    auto a = p.make();
    REQUIRE(a.ok());
    CHECK(a.value().filesHashed == 3);
    auto c = p.make();
    CHECK(c.value().filesHashed == 0);
    // A change of size is seen even with the same mtime; a change of content with the same size and mtime is the
    // documented blind spot of any stat cache, so only the size case is asserted.
    write_all(p.dir.path / "scripts/player.js", "let a = 222;\n");
    age_files(p.dir);
    CHECK(p.make().value().filesHashed == 1);
    auto cp = p.make("again");
    CHECK(cp.value().filesHashed == 0);
    CHECK(checkpoint_diff(p.dir.str(), cp.value().info.id).value().empty());
}

TEST_CASE("checkpoint: only the newest checkpoints are kept and unused objects are deleted") {
    Project p;
    auto first = p.make("first");
    REQUIRE(first.ok());
    write_all(p.dir.path / "scripts/only-in-first.js", "unique content of the first checkpoint\n");
    auto second = p.make("second");
    REQUIRE(second.ok());
    stdfs::remove(p.dir.path / "scripts/only-in-first.js");
    const std::size_t withUnique = count_objects(p.dir);
    for (int i = 0; i < kCheckpointLimit; ++i) REQUIRE(p.make("n" + std::to_string(i)).ok());
    CHECK(checkpoint_list(p.dir.str()).size() == static_cast<std::size_t>(kCheckpointLimit));
    CHECK(checkpoint_diff(p.dir.str(), first.value().info.id).error().message.find("No checkpoint") == 0);
    CHECK(count_objects(p.dir) == withUnique - 1);  // the file only the dropped checkpoints held is gone
}

TEST_CASE("checkpoint: hidden folders, node_modules and a top-level build are skipped") {
    Project p;
    write_all(p.dir.path / ".git/config", "x");
    write_all(p.dir.path / ".factoria/ai/chat.json", "x");
    write_all(p.dir.path / "node_modules/pkg/index.js", "x");
    write_all(p.dir.path / "build/out.bin", "x");
    write_all(p.dir.path / "scripts/build/keep.js", "x");  // only the top-level build/ is skipped
    write_all(p.dir.path / ".gitignore", ".factoria/\n");   // a hidden FILE is part of the project
    auto cp = p.make();
    REQUIRE(cp.ok());
    CHECK(cp.value().info.files == 5);
    write_all(p.dir.path / "build/out.bin", "changed");
    write_all(p.dir.path / ".factoria/ai/chat.json", "changed");
    CHECK(checkpoint_diff(p.dir.str(), cp.value().info.id).value().empty());
}

TEST_CASE("checkpoint: errors teach") {
    Project p;
    auto none = checkpoint_diff(p.dir.str(), "nope");
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message.find("none yet") != std::string::npos);
    auto cp = p.make();
    auto typo = checkpoint_restore(p.dir.str(), cp.value().info.id + "9");
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().message.find("Did you mean") != std::string::npos);
    CHECK_FALSE(typo.error().hint.empty());
    CHECK_FALSE(checkpoint_create((p.dir.path / "missing").string(), "x").ok());
}

TEST_CASE("checkpoint: a missing object is reported before any file is touched") {
    Project p;
    auto cp = p.make();
    REQUIRE(cp.ok());
    write_all(p.dir.path / "scripts/player.js", "changed\n");
    std::error_code ec;
    stdfs::remove_all(p.dir.path / ".factoria/checkpoints/objects", ec);
    auto r = checkpoint_restore(p.dir.str(), cp.value().info.id);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("damaged") != std::string::npos);
    CHECK(read_all(p.dir.path / "scripts/player.js") == "changed\n");
}

TEST_CASE("checkpoint: the commands") {
    Project p;
    CommandRegistry reg;
    register_tooling_commands(reg, p.dir.str());
    for (const char* name : {"checkpoint.create", "checkpoint.list", "checkpoint.diff", "checkpoint.restore"}) {
        REQUIRE(reg.has(name));
        CHECK(reg.info(name)->description.size() > 40);
    }
    auto created = reg.call("checkpoint.create", Json::object({{"label", "mine"}}));
    REQUIRE(created.ok);
    const std::string id = created.result["id"];
    write_all(p.dir.path / "scripts/player.js", "changed\n");
    auto diff = reg.call("checkpoint.diff", Json::object({{"id", id}}));
    REQUIRE(diff.ok);
    CHECK(diff.result["changed"] == 1);
    auto restored = reg.call("checkpoint.restore", Json::object({{"id", id}}));
    REQUIRE(restored.ok);
    CHECK(restored.result["modified"].size() == 1);
    CHECK(restored.result.contains("safetyCheckpointId"));
    CHECK(reg.call("checkpoint.list").result["checkpoints"].size() == 2);
    auto bad = reg.call("checkpoint.restore", Json::object({{"id", "zzz"}}));
    CHECK_FALSE(bad.ok);
    CHECK_FALSE(bad.error["hint"].get<std::string>().empty());
}
