#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/runtime/startup_sequence.h"

using namespace fa;
using Mark = StartupTimeline::Mark;

namespace {
struct Recorder {
    std::vector<std::string> events;
    int warmLeft = 3;
    bool initOk = true;
    StartupSequence::Hooks hooks() {
        StartupSequence::Hooks h;
        h.present_clear = [this] { events.push_back("present"); };
        h.init = [this] {
            events.push_back("init");
            return initOk;
        };
        h.warm = [this] {
            events.push_back("warm");
            return --warmLeft;
        };
        return h;
    }
};
}  // namespace

TEST_CASE("StartupSequence: the first frame is presented before the game is read, the game runs after the warm-up") {
    Recorder r;
    StartupTimeline t;
    StartupSequence seq(r.hooks(), &t);
    int gameFrames = 0;
    for (int i = 0; i < 12; ++i)
        if (seq.on_frame()) ++gameFrames;
    // frame 1: present; frame 2: init + present; frames 3-5: warm + present each; then game frames.
    const std::vector<std::string> expected = {"present", "init", "present", "warm", "present", "warm", "present", "warm", "present"};
    CHECK(r.events == expected);
    CHECK(gameFrames == 12 - 5);
    CHECK(seq.running());
    CHECK(t.has(Mark::WindowReady));
    CHECK(t.has(Mark::FirstPresent));
}

TEST_CASE("StartupSequence: no file is read before the first present") {
    // The hooks stand for the host: present_clear notes how many files were read from disk when the window first showed.
    // A folder of its own (fs::make_temp_dir: unique per process, so tests may run in parallel) and native paths throughout, so
    // a Windows user name with accents works.
    const std::filesystem::path dir = fs::make_temp_dir("fa_test_startup_sequence").value();
    const std::filesystem::path file = dir / "game_file.txt";
    {
        std::ofstream out(fs::os_path(file), std::ios::binary);
        REQUIRE(out.is_open());
        out << "a game file";
    }
    std::uint64_t readsAtPresent = ~std::uint64_t(0), readsAtInit = 0;
    int presents = 0;
    bool readBack = false;
    StartupSequence::Hooks h;
    h.present_clear = [&] {
        if (presents++ == 0) readsAtPresent = fs::disk_reads();
    };
    h.init = [&] {
        const auto bytes = fs::read_bytes(fs::path_to_utf8(file));  // Engine::init reads the game's files: each read counts in disk_reads
        readBack = bytes.ok() && bytes.value().size() == 11;
        readsAtInit = fs::disk_reads();
        return true;
    };
    StartupSequence seq(h, nullptr);
    seq.on_frame();
    seq.on_frame();
    CHECK(readsAtPresent != ~std::uint64_t(0));
    CHECK(readBack);  // the read really happened (a read that failed would not count)
    CHECK(readsAtInit > readsAtPresent);  // the file was read after the first present, not before
    CHECK(presents == 2);  // the first frame, and the frame init ran in
    std::error_code ec;
    fs::remove_tree(dir, ec);
}

TEST_CASE("StartupSequence: a start that fails stops the sequence and never runs a game frame") {
    Recorder r;
    r.initOk = false;
    StartupSequence seq(r.hooks(), nullptr);
    for (int i = 0; i < 6; ++i) CHECK_FALSE(seq.on_frame());
    CHECK(seq.failed());
    CHECK(r.events == std::vector<std::string>{"present", "init"});
}

TEST_CASE("StartupSequence: without a warm-up hook one clear frame separates init from the game") {
    StartupSequence::Hooks h;
    int presents = 0;
    h.present_clear = [&] { ++presents; };
    StartupSequence seq(h, nullptr);
    CHECK_FALSE(seq.on_frame());
    CHECK_FALSE(seq.on_frame());
    CHECK_FALSE(seq.on_frame());
    CHECK(seq.on_frame());
    CHECK(presents == 3);
}
