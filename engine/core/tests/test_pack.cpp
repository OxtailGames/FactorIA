#include <doctest.h>

#include <atomic>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/pack.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::vector<std::uint8_t> bytes_of(const std::string& s) { return {s.begin(), s.end()}; }
std::string text_of(const std::vector<std::uint8_t>& b) { return {b.begin(), b.end()}; }

void write_raw(const stdfs::path& p, const std::string& data) {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << data;
}

// A scratch folder for one test; unmounts any pack and restores the project root on the way out.
struct Scratch {
    stdfs::path dir, oldRoot;
    Scratch() {
        oldRoot = fs::project_root();
        dir = fs::make_temp_dir("fa_test_pack");
    }
    ~Scratch() {
        fs::unmount_pack();
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    stdfs::path pak() const { return dir / "game.pak"; }
};

// The game used by most tests: some text, a binary file with every byte value, an empty file, a nested folder.
Result<void> write_sample_pack(const stdfs::path& out, std::string& binary) {
    for (int i = 0; i < 256; ++i) binary.push_back(char(i));
    binary += binary;
    PackWriter w;
    if (auto r = w.add_bytes("factoria.json", bytes_of("{\"name\":\"Pack\"}")); !r.ok()) return r;
    if (auto r = w.add_bytes("scenes/main.scene.json", bytes_of("{\"entities\":[]}")); !r.ok()) return r;
    if (auto r = w.add_bytes("assets/hero.bin", std::vector<std::uint8_t>(binary.begin(), binary.end())); !r.ok()) return r;
    if (auto r = w.add_bytes("assets/ui/empty.txt", {}); !r.ok()) return r;
    if (auto r = w.add_bytes("scripts/player.js", bytes_of("export default 1;")); !r.ok()) return r;
    return w.write(out);
}

}  // namespace

TEST_CASE("pack: write and read round trip, bytes are returned as they went in") {
    Scratch s;
    std::string binary;
    REQUIRE(write_sample_pack(s.pak(), binary).ok());
    CHECK(!stdfs::exists(s.dir / "game.pak.tmp"));  // the temporary file is gone once the pack is complete

    auto opened = PackReader::open(s.pak());
    REQUIRE(opened.ok());
    const PackReader& pack = *opened.value();
    CHECK(pack.file_count() == 5);

    auto hero = pack.read("assets/hero.bin");
    REQUIRE(hero.ok());
    CHECK(text_of(hero.value()) == binary);
    CHECK(text_of(pack.read("factoria.json").value()) == "{\"name\":\"Pack\"}");
    CHECK(pack.size_of("assets/hero.bin") == std::int64_t(binary.size()));
    CHECK(pack.size_of("assets/ui/empty.txt") == 0);
    CHECK(pack.read("assets/ui/empty.txt").value().empty());
    CHECK(pack.size_of("nope.txt") == -1);
}

TEST_CASE("pack: a file added from disk is streamed into the pack") {
    Scratch s;
    std::string big(3 * 1024 * 1024 + 17, 'x');  // more than one 1 MiB copy chunk
    for (std::size_t i = 0; i < big.size(); i += 4099) big[i] = char('a' + i % 26);
    write_raw(s.dir / "src" / "big.dat", big);
    PackWriter w;
    REQUIRE(w.add_file("assets/big.dat", s.dir / "src" / "big.dat").ok());
    REQUIRE(w.write(s.pak()).ok());
    auto pack = PackReader::open(s.pak());
    REQUIRE(pack.ok());
    CHECK(text_of(pack.value()->read("assets/big.dat").value()) == big);

    PackWriter missing;
    auto r = missing.add_file("assets/x.dat", s.dir / "src" / "does_not_exist.dat");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("assets/x.dat") != std::string::npos);
    CHECK(!r.error().hint.empty());
}

TEST_CASE("pack: the writer refuses paths that are not normalized and duplicates, and says how to fix them") {
    PackWriter w;
    for (const char* bad : {"", "../x", "a/../b", "/abs/x", "a\\b", "./a"}) {
        auto r = w.add_bytes(bad, bytes_of("x"));
        CHECK_MESSAGE(!r.ok(), "path '" << bad << "' should be refused");
        if (!r.ok()) CHECK(!r.error().message.empty());
    }
    CHECK(w.count() == 0);
    REQUIRE(w.add_bytes("a.txt", bytes_of("1")).ok());
    REQUIRE(w.add_bytes("a.txt", bytes_of("2")).ok());
    Scratch s;
    auto r = w.write(s.pak());
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("'a.txt' was added twice") != std::string::npos);
    CHECK(!r.error().hint.empty());
    CHECK(!stdfs::exists(s.pak()));
    CHECK(!stdfs::exists(s.dir / "game.pak.tmp"));
}

TEST_CASE("pack: list, exists and directories") {
    Scratch s;
    std::string binary;
    REQUIRE(write_sample_pack(s.pak(), binary).ok());
    auto pack = PackReader::open(s.pak());
    REQUIRE(pack.ok());
    const PackReader& p = *pack.value();

    CHECK(p.contains("scenes/main.scene.json"));
    CHECK(!p.contains("scenes"));
    CHECK(p.is_directory(""));
    CHECK(p.is_directory("assets"));
    CHECK(p.is_directory("assets/ui"));
    CHECK(!p.is_directory("assets/u"));  // a prefix of a folder name is not a folder
    CHECK(!p.is_directory("scenes/main.scene.json"));

    CHECK(p.list("assets", true) == std::vector<std::string>{"assets/hero.bin", "assets/ui/empty.txt"});
    CHECK(p.list("assets", false) == std::vector<std::string>{"assets/hero.bin"});
    CHECK(p.list("", false) == std::vector<std::string>{"factoria.json"});
    CHECK(p.list("", true).size() == 5);
    CHECK(p.list("nothing", true).empty());
    // sorted
    auto all = p.list("", true);
    CHECK(std::is_sorted(all.begin(), all.end()));
}

TEST_CASE("pack: a missing file is an error that teaches, with a did-you-mean") {
    Scratch s;
    std::string binary;
    REQUIRE(write_sample_pack(s.pak(), binary).ok());
    auto pack = PackReader::open(s.pak());
    REQUIRE(pack.ok());

    auto r = pack.value()->read("scenes/main.scene.jsn");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("File not found: 'scenes/main.scene.jsn'") != std::string::npos);
    CHECK(r.error().hint.find("Did you mean 'scenes/main.scene.json'?") != std::string::npos);

    auto dir = pack.value()->read("assets");
    REQUIRE(!dir.ok());
    CHECK(dir.error().message.find("is a directory") != std::string::npos);

    auto elsewhere = pack.value()->read("totally/other.txt");
    REQUIRE(!elsewhere.ok());
    CHECK(elsewhere.error().hint.find("not in the pack") != std::string::npos);
}

TEST_CASE("pack: several threads read the same pack at once") {
    Scratch s;
    PackWriter w;
    std::vector<std::string> contents;
    for (int i = 0; i < 24; ++i) {
        std::string c;
        for (int j = 0; j < 20000 + i * 137; ++j) c.push_back(char('A' + (i * 7 + j * 13) % 61));
        contents.push_back(c);
        REQUIRE(w.add_bytes("data/file" + std::to_string(i) + ".bin", bytes_of(c)).ok());
    }
    REQUIRE(w.write(s.pak()).ok());
    auto pack = PackReader::open(s.pak());
    REQUIRE(pack.ok());

    std::atomic<int> wrong{0};
    std::vector<std::thread> threads;
    for (int t = 0; t < 8; ++t)
        threads.emplace_back([&, t] {
            for (int round = 0; round < 40; ++round)
                for (int i = 0; i < 24; ++i) {
                    const int n = (i + t * 3 + round) % 24;
                    auto r = pack.value()->read("data/file" + std::to_string(n) + ".bin");
                    if (!r.ok() || text_of(r.value()) != contents[std::size_t(n)]) ++wrong;
                }
        });
    for (auto& th : threads) th.join();
    CHECK(wrong == 0);
}

TEST_CASE("pack: a file that is not a pack, was cut short or has another version is refused with the fix") {
    Scratch s;
    std::string binary;
    REQUIRE(write_sample_pack(s.pak(), binary).ok());
    std::string good;
    {
        std::ifstream in(s.pak(), std::ios::binary);
        good.assign(std::istreambuf_iterator<char>(in), {});
    }

    auto open_with = [&](const std::string& data) {
        write_raw(s.dir / "bad.pak", data);
        return PackReader::open(s.dir / "bad.pak");
    };

    auto missing = PackReader::open(s.dir / "none.pak");
    REQUIRE(!missing.ok());
    CHECK(missing.error().message.find("Cannot open the game pack") != std::string::npos);
    CHECK(missing.error().hint.find("next to the game's executable") != std::string::npos);

    auto text = open_with(std::string(200, 'z'));
    REQUIRE(!text.ok());
    CHECK(text.error().message.find("not a FactorIA game pack") != std::string::npos);

    auto tiny = open_with("FAPACK");
    REQUIRE(!tiny.ok());
    CHECK(tiny.error().message.find("too small") != std::string::npos);

    auto cut = open_with(good.substr(0, good.size() - 10));
    REQUIRE(!cut.ok());
    CHECK(cut.error().message.find("incomplete") != std::string::npos);
    CHECK(cut.error().hint.find("Export the game again") != std::string::npos);

    std::string newer = good;
    newer[8] = 9;  // format version 9
    auto version = open_with(newer);
    REQUIRE(!version.ok());
    CHECK(version.error().message.find("format version 9") != std::string::npos);
    CHECK(version.error().message.find("reads version 1") != std::string::npos);
    CHECK(version.error().hint.find("Export the game again with this FactorIA version") != std::string::npos);

    std::string lies = good;  // the index offset in the footer points past the file
    lies[lies.size() - 24] = char(-1);
    lies[lies.size() - 23] = char(-1);
    auto damaged = open_with(lies);
    REQUIRE(!damaged.ok());
    CHECK(damaged.error().message.find("damaged") != std::string::npos);
}

TEST_CASE("fs: a mounted pack answers every project-relative path, and only the pack") {
    Scratch s;
    std::string binary;
    REQUIRE(write_sample_pack(s.pak(), binary).ok());
    // A loose file of the same project folder that is NOT in the pack: invisible while the pack is mounted.
    write_raw(s.dir / "game" / "loose.txt", "loose");
    write_raw(s.dir / "game" / "factoria.json", "{\"name\":\"Loose\"}");
    fs::set_project_root(s.dir / "game");
    CHECK(fs::exists("loose.txt"));
    CHECK(!fs::pack_mounted());

    REQUIRE(fs::mount_pack(s.pak()).ok());
    CHECK(fs::pack_mounted());
    CHECK(!fs::exists("loose.txt"));
    CHECK(fs::read_text("factoria.json").value() == "{\"name\":\"Pack\"}");  // the pack's, not the folder's
    CHECK(fs::read_bytes("assets/hero.bin").value().size() == binary.size());
    CHECK(fs::exists("scenes/main.scene.json"));
    CHECK(fs::exists("./scenes//main.scene.json"));  // normalized like any path
    CHECK(fs::is_directory("scenes"));
    CHECK(fs::is_directory(""));
    CHECK(!fs::is_directory("scenes/main.scene.json"));
    CHECK(fs::file_size("assets/hero.bin") == std::int64_t(binary.size()));
    CHECK(fs::file_size("assets") == -1);
    CHECK(fs::file_size("nope") == -1);
    CHECK(fs::modified_time("factoria.json") >= 0);
    CHECK(fs::modified_time("factoria.json") == fs::modified_time("scenes/main.scene.json"));
    CHECK(fs::modified_time("nope") == -1);
    CHECK(fs::list("assets") == std::vector<std::string>{"assets/hero.bin", "assets/ui/empty.txt"});
    CHECK(fs::list("assets", false) == std::vector<std::string>{"assets/hero.bin"});
    CHECK(fs::list("", true, ".js") == std::vector<std::string>{"scripts/player.js"});

    auto missing = fs::read_text("scenes/main.scene.jsn");
    REQUIRE(!missing.ok());
    CHECK(missing.error().message.find("scenes/main.scene.jsn") != std::string::npos);
    CHECK(missing.error().hint.find("Did you mean 'scenes/main.scene.json'?") != std::string::npos);
    CHECK(!fs::read_text("loose.txt").ok());

    // Absolute paths and writes still go to the host.
    const stdfs::path abs = s.dir / "game" / "loose.txt";
    CHECK(fs::exists(abs.generic_string()));
    CHECK(fs::read_text(abs.generic_string()).value() == "loose");
    REQUIRE(fs::write_text("save/slot1.json", "{}").ok());
    CHECK(stdfs::exists(s.dir / "game" / "save" / "slot1.json"));

    fs::unmount_pack();
    CHECK(!fs::pack_mounted());
    CHECK(fs::exists("loose.txt"));
    CHECK(fs::read_text("factoria.json").value() == "{\"name\":\"Loose\"}");
    CHECK(!fs::exists("scenes/main.scene.json"));
}

TEST_CASE("fs: mounting a bad pack fails with the pack's message and mounts nothing") {
    Scratch s;
    write_raw(s.pak(), "not a pack at all, just some text that is long enough to have a header and a footer");
    auto r = fs::mount_pack(s.pak());
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("not a FactorIA game pack") != std::string::npos);
    CHECK(!fs::pack_mounted());
}
