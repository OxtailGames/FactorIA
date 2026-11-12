#include <doctest.h>

#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/json.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
struct TempProject {
    stdfs::path dir;
    stdfs::path oldRoot;
    TempProject() {
        oldRoot = fs::project_root();
        dir = stdfs::temp_directory_path() / ("fa_test_fs_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        stdfs::remove_all(dir);
        stdfs::create_directories(dir);
        fs::set_project_root(dir);
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

// Turns the Windows file rules on or off for a scope and puts the process's own setting back.
struct RulesScope {
    bool before = fs::windows_rules();
    explicit RulesScope(bool on) { fs::set_windows_rules(on); }
    ~RulesScope() { fs::set_windows_rules(before); }
};
}  // namespace

TEST_CASE("fs: normalize") {
    CHECK(fs::normalize("./a\\b/../c") == "a/c");
    CHECK(fs::normalize("assets//player.png") == "assets/player.png");
    CHECK(fs::normalize("a/b/./c/") == "a/b/c");
    CHECK(fs::normalize("") == "");
    CHECK(fs::normalize("/abs/x/../y") == "/abs/y");
    CHECK(fs::is_absolute("/tmp/x"));
    CHECK(fs::is_absolute("C:\\x"));
    CHECK(!fs::is_absolute("assets/x"));
}

TEST_CASE("fs: escaping the project root is rejected with a hint") {
    CHECK(fs::normalize("../x").empty());
    CHECK(fs::normalize("a/../../x").empty());
    auto r = fs::normalize_checked("a/../../secret.txt");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("escapes the project root") != std::string::npos);
    CHECK(!r.error().hint.empty());

    TempProject p;
    auto read = fs::read_text("../outside.txt");
    REQUIRE(!read.ok());
    CHECK(read.error().message.find("escapes") != std::string::npos);
    CHECK(!fs::write_text("../outside.txt", "x").ok());
    CHECK(!fs::exists("../outside.txt"));
}

TEST_CASE("fs: read/write/list in a temp project") {
    TempProject p;
    REQUIRE(fs::write_text("assets/b.txt", "hello").ok());
    REQUIRE(fs::write_text("assets/sub/a.png", "x").ok());
    REQUIRE(fs::write_text("scenes/main.scene.json", "{}").ok());
    CHECK(fs::exists("assets/b.txt"));
    CHECK(fs::is_directory("assets"));
    CHECK(!fs::is_directory("assets/b.txt"));
    CHECK(fs::read_text("assets/b.txt").value() == "hello");
    CHECK(fs::read_bytes("assets/b.txt").value().size() == 5);
    CHECK(stdfs::exists(p.dir / "assets" / "sub" / "a.png"));

    auto all = fs::list("assets");
    REQUIRE(all.size() == 2);
    CHECK(all[0] == "assets/b.txt");
    CHECK(all[1] == "assets/sub/a.png");
    CHECK(fs::list("assets", false).size() == 1);
    auto pngs = fs::list("", true, ".png");
    REQUIRE(pngs.size() == 1);
    CHECK(pngs[0] == "assets/sub/a.png");
    CHECK(fs::list("nope").empty());

    // Absolute paths are accepted on desktop.
    std::string abs = (p.dir / "assets" / "b.txt").generic_string();
    CHECK(fs::read_text(abs).value() == "hello");
    CHECK(fs::modified_time("assets/b.txt") != -1);
    CHECK(fs::modified_time("missing") == -1);
}

namespace {
// Names of the files directly in `dir`.
std::vector<std::string> names_in(const stdfs::path& dir) {
    std::vector<std::string> out;
    for (const auto& e : stdfs::directory_iterator(dir)) out.push_back(e.path().filename().string());
    return out;
}
}  // namespace

TEST_CASE("fs: writes replace the file atomically through a temporary file that is never left behind") {
    TempProject p;
    REQUIRE(fs::write_text("scenes/a.scene.json", "{\"v\": 1}").ok());
    const std::string big(1 << 20, 'x');
    REQUIRE(fs::write_text("scenes/a.scene.json", big).ok());  // replaces an existing file (also on Windows)
    CHECK(fs::read_text("scenes/a.scene.json").value() == big);
    REQUIRE(fs::write_text("scenes/a.scene.json", "").ok());   // shrinking to nothing works too
    CHECK(fs::read_text("scenes/a.scene.json").value().empty());
    CHECK(names_in(p.dir / "scenes") == std::vector<std::string>{"a.scene.json"});

    // A write that cannot replace its target fails, leaves the target as it was and removes the temporary file.
    REQUIRE(fs::write_text("data/keep/inner.txt", "x").ok());
    auto r = fs::write_text("data/keep", "x");  // 'keep' is a folder
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("data/keep") != std::string::npos);
    CHECK(fs::is_directory("data/keep"));
    CHECK(fs::read_text("data/keep/inner.txt").value() == "x");
    CHECK(names_in(p.dir / "data") == std::vector<std::string>{"keep"});

    // Absolute paths (tools) take the same route.
    const std::string abs = (p.dir / "scenes" / "a.scene.json").generic_string();
    REQUIRE(fs::write_text(abs, "{}").ok());
    CHECK(fs::read_text("scenes/a.scene.json").value() == "{}");
    CHECK(names_in(p.dir / "scenes") == std::vector<std::string>{"a.scene.json"});
}

TEST_CASE("fs: a write replaces a file another thread is reading (Windows refuses while it is open)") {
    TempProject p;
    REQUIRE(fs::write_text("data/shared.json", "{\"v\": 1}").ok());
    // A reader holds the file open (std::ifstream shares no delete access on Windows) and lets go a moment later, as the
    // editor's panels do when they poll a file another thread writes.
    // fs::ReadStream registers the file, so a Windows-rules run (FA_FS_WINDOWS_RULES, fs.h) refuses the replace like Windows.
    fs::ReadStream reader(fs::os_path(p.dir / "data" / "shared.json"), std::ios::binary);
    REQUIRE(reader.good());
    std::thread release([&reader] {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        reader.close();
    });
    const auto r = fs::write_text("data/shared.json", "{\"v\": 2}");
    release.join();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    CHECK(fs::read_text("data/shared.json").value() == "{\"v\": 2}");
    CHECK(names_in(p.dir / "data") == std::vector<std::string>{"shared.json"});
}

TEST_CASE("fs: paths longer than Windows' MAX_PATH are read and written (os_path)") {
    TempProject p;
    const std::string rel = std::string(100, 'a') + "/" + std::string(100, 'b') + "/" + std::string(60, 'c') + ".json";
    REQUIRE((p.dir / rel).string().size() > 260);
    auto w = fs::write_text(rel, "{\"deep\": true}");
    REQUIRE_MESSAGE(w.ok(), (w.ok() ? "" : w.error().to_string()));
    CHECK(fs::exists(rel));
    CHECK(fs::read_text(rel).value() == "{\"deep\": true}");
    CHECK(fs::is_directory(std::string(100, 'a')));
    CHECK(fs::modified_time(rel) != -1);

    const stdfs::path longPath = p.dir / rel, shortPath = p.dir / "x.json";
    CHECK(fs::os_path(shortPath) == shortPath);  // short paths are left alone everywhere
#ifdef _WIN32
    const std::wstring prefixed = fs::os_path(longPath).native();
    CHECK(prefixed.rfind(LR"(\\?\)", 0) == 0);
    CHECK(prefixed.find(L'/') == std::wstring::npos);  // the prefix turns off '/' -> '\' conversion: none left
    CHECK(fs::os_path(fs::os_path(longPath)) == fs::os_path(longPath));
    CHECK(fs::os_path(LR"(\\server\share\)" + std::wstring(260, L'd')).native().rfind(LR"(\\?\UNC\server\share\)", 0) == 0);
#else
    CHECK(fs::os_path(longPath) == longPath);
#endif
    // A short folder with files past the limit: on Windows remove_all alone stops at them and leaves the folder behind.
    std::error_code ec;
    CHECK(fs::remove_tree(p.dir, ec) > 0);
    CHECK_FALSE(ec);
    CHECK_FALSE(stdfs::exists(p.dir));
}

TEST_CASE("fs: missing files get did-you-mean hints") {
    TempProject p;
    REQUIRE(fs::write_text("assets/player.png", "x").ok());
    auto r = fs::read_bytes("assets/plyer.png");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("File not found") != std::string::npos);
    CHECK(r.error().hint.find("Did you mean 'assets/player.png'") != std::string::npos);
    auto dir = fs::read_text("assets");
    CHECK(!dir.ok());
}

TEST_CASE("fs: write policy - .factoria is managed, .factoria/tmp is scratch") {
    TempProject p;
    // Normal folders are writable; the tools' folders are not, except the scratch folder.
    for (const char* ok : {"scenes/a.scene.json", "assets/x.png", "levels/.hidden", ".factoria_not/x", ".factoria/tmp/a.json",
                           ".factoria/tmp/deep/er/a.json", "./.factoria/tmp/a.json", "scenes/../.factoria/tmp/a.json"}) {
        CAPTURE(ok);
        CHECK(fs::check_writable(ok).ok());
    }
    for (const char* bad : {".factoria", ".factoria/save/slot1.json", ".factoria/screenshots/frame_1.png", ".factoria/tmpx/a.json",
                            ".factoria/tmp2", ".git/config", ".git"}) {
        CAPTURE(bad);
        auto r = fs::check_writable(bad);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find(bad) != std::string::npos);
        CHECK(r.error().hint.find(".factoria/tmp/") != std::string::npos);  // names the place that is allowed
    }
    // The scratch folder itself can be deleted, i.e. it is not "managed".
    CHECK(fs::is_scratch_path(".factoria/tmp"));
    CHECK(fs::is_scratch_path(".factoria/tmp/x"));
    CHECK_FALSE(fs::is_scratch_path(".factoria/tmpx"));
    CHECK_FALSE(fs::is_managed_path(".factoria/tmp"));
    CHECK(fs::is_managed_path(".factoria"));
    CHECK(fs::is_managed_path(".factoria/save/a"));
    CHECK_FALSE(fs::is_managed_path("scenes/main.scene.json"));

    // Escaping the project is an error of its own; an absolute path is judged inside the project root only.
    CHECK_FALSE(fs::check_writable("../x").ok());
    CHECK_FALSE(fs::check_writable((p.dir / ".factoria" / "save" / "a.json").generic_string()).ok());
    CHECK(fs::check_writable((p.dir / ".factoria" / "tmp" / "a.json").generic_string()).ok());
    CHECK(fs::check_writable((p.dir / "scenes" / "a.json").generic_string()).ok());
    CHECK(fs::check_writable((stdfs::temp_directory_path() / "elsewhere.json").generic_string()).ok());
}

TEST_CASE("fs: a missing absolute path does not claim to be project-relative") {
    TempProject p;
    auto rel = fs::read_text("nope.json");
    REQUIRE_FALSE(rel.ok());
    CHECK(rel.error().hint.find("relative to the project root") != std::string::npos);
    auto abs = fs::read_text((p.dir / "nope.json").generic_string());
    REQUIRE_FALSE(abs.ok());
    CHECK(abs.error().hint.find("relative to the project root") == std::string::npos);
    CHECK(abs.error().hint.find("absolute path") != std::string::npos);
}

TEST_CASE("fs: path helpers") {
    CHECK(fs::extension("a/b/Player.PNG") == ".png");
    CHECK(fs::extension("a.b/noext") == "");
    CHECK(fs::filename("a/b/c.txt") == "c.txt");
    CHECK(fs::stem("a/b/c.tar.gz") == "c.tar");
    CHECK(fs::parent("a/b/c.txt") == "a/b");
    CHECK(fs::parent("c.txt") == "");
    CHECK(fs::join("a", "b/c") == "a/b/c");
    CHECK(fs::join("a/", "b") == "a/b");
    CHECK(fs::join("", "b") == "b");
}

TEST_CASE("fs: json files and watcher") {
    TempProject p;
    Json j = Json::object({{"k", 1}});
    REQUIRE(save_json_file("data/x.json", j).ok());
    CHECK(load_json_file("data/x.json").value()["k"] == 1);
    REQUIRE(fs::write_text("data/bad.json", "{\n \"a\": }").ok());
    auto bad = load_json_file("data/bad.json");
    REQUIRE(!bad.ok());
    CHECK(bad.error().message.find("data/bad.json:2:") == 0);

    fs::Watcher w;
    int hits = 0;
    int id = w.watch("data/x.json", [&](const std::string& path) {
        ++hits;
        CHECK(path == "data/x.json");
    });
    w.poll();
    CHECK(hits == 0);
    stdfs::last_write_time(p.dir / "data" / "x.json", stdfs::file_time_type::clock::now() + std::chrono::seconds(5));
    w.poll();
    CHECK(hits == 1);
    w.poll();
    CHECK(hits == 1);
    w.unwatch(id);
    stdfs::last_write_time(p.dir / "data" / "x.json", stdfs::file_time_type::clock::now() + std::chrono::seconds(10));
    w.poll();
    CHECK(hits == 1);
}

TEST_CASE("image: png roundtrip, flip and diff") {
    TempProject p;
    Image img;
    img.width = 4;
    img.height = 2;
    img.rgba.assign(4 * 2 * 4, 0);
    img.set_pixel(0, 0, Color::red());
    img.set_pixel(3, 1, Color{0, 0, 1, 0.5f});
    REQUIRE(save_png(img, "out/test.png").ok());
    auto loaded = load_image("out/test.png");
    REQUIRE(loaded.ok());
    CHECK(loaded->width == 4);
    CHECK(loaded->height == 2);
    CHECK(loaded->rgba == img.rgba);
    CHECK(loaded->pixel(0, 0) == Color::red());
    CHECK(loaded->pixel(99, 99).a == 0.0f);

    ImageDiff same = diff_images(img, *loaded);
    CHECK(same.sameSize);
    CHECK(same.differingPixels == 0);
    CHECK(same.maxError == 0.0);

    Image other = img;
    other.set_pixel(1, 1, Color::white());
    ImageDiff d = diff_images(img, other);
    CHECK(d.differingPixels == 1);
    CHECK(d.maxError == doctest::Approx(1.0));
    CHECK(d.meanError > 0.0);
    Image small;
    small.width = 1;
    small.height = 1;
    small.rgba.assign(4, 0);
    CHECK(!diff_images(img, small).sameSize);

    Image flipped = img;
    flipped.flip_vertical();
    CHECK(flipped.pixel(0, 1) == Color::red());
    CHECK(flipped.pixel(0, 0).a == 0.0f);

    auto bad = decode_image(reinterpret_cast<const std::uint8_t*>("garbage"), 7);
    CHECK(!bad.ok());
    CHECK(!load_image("out/missing.png").ok());
}

TEST_CASE("fs: make_temp_dir gives a fresh, unique, empty directory per call") {
    const stdfs::path a = fs::make_temp_dir("fa_test_tmp").value();
    const stdfs::path b = fs::make_temp_dir("fa_test_tmp").value();
    CHECK(a != b);
    CHECK(stdfs::is_directory(a));
    CHECK(stdfs::is_empty(a));
    CHECK(a.filename().string().rfind("fa_test_tmp_", 0) == 0);
    CHECK(stdfs::is_directory(stdfs::temp_directory_path() / a.filename()));  // directly inside the system temp folder
    stdfs::remove_all(a);
    stdfs::remove_all(b);
}

// The web build copies the save folder to the browser's storage here; everywhere else the folder is on disk and this does nothing.
TEST_CASE("fs: user_dir_changed is a no-op outside the web build") {
    CHECK_NOTHROW(fs::user_dir_changed());
}

TEST_CASE("fs: warm reads a file ahead, later reads take it from memory until unwarm") {
    TempProject p;
    REQUIRE(fs::write_text("assets/a.bin", "hello"));
    const std::uint64_t base = fs::disk_reads();
    std::string text;
    std::uint64_t size = 0;
    REQUIRE(fs::warm("assets/a.bin", &text, &size));
    CHECK(text == "hello");
    CHECK(size == 5);
    CHECK(fs::is_warm("assets/a.bin"));
    CHECK(fs::warm_bytes() == 5);
    CHECK(fs::disk_reads() == base + 1);
    REQUIRE(fs::warm("assets/./a.bin"));  // already warm: no second read
    CHECK(fs::disk_reads() == base + 1);

    for (int i = 0; i < 3; ++i) {  // as often as asked, no disk read
        auto r = fs::read_text("assets/a.bin");
        REQUIRE(r);
        CHECK(r.value() == "hello");
    }
    CHECK(fs::disk_reads() == base + 1);
    CHECK(fs::is_warm("assets/a.bin"));

    fs::unwarm("assets/a.bin");
    CHECK(fs::warm_bytes() == 0);
    REQUIRE(fs::read_text("assets/a.bin"));  // now it reads the disk
    CHECK(fs::disk_reads() == base + 2);
}

TEST_CASE("fs: a warm file that changed on disk is read again; unwarm drops it; a missing file teaches") {
    TempProject p;
    REQUIRE(fs::write_text("assets/b.txt", "one"));
    REQUIRE(fs::warm("assets/b.txt"));
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    REQUIRE(fs::write_text("assets/b.txt", "two!"));
    stdfs::last_write_time(fs::resolve("assets/b.txt"), stdfs::file_time_type::clock::now() + std::chrono::seconds(5));
    auto r = fs::read_text("assets/b.txt");
    REQUIRE(r);
    CHECK(r.value() == "two!");

    REQUIRE(fs::warm("assets/b.txt"));
    fs::unwarm("assets/b.txt");
    CHECK_FALSE(fs::is_warm("assets/b.txt"));
    REQUIRE(fs::warm("assets/b.txt"));
    fs::unwarm_all();
    CHECK(fs::warm_bytes() == 0);

    auto missing = fs::warm("assets/nope.png");
    REQUIRE_FALSE(missing);
    CHECK(missing.error().message.find("nope.png") != std::string::npos);
}

// ---- Windows file rules (fs.h): what ctest turns on for every test on macOS and Linux -----------------------------------
#ifndef _WIN32
TEST_CASE("windows rules: a file open through ReadStream cannot be replaced; the write waits for the reader") {
    RulesScope rules(true);
    TempProject p;
    REQUIRE(fs::write_text("data/a.json", "1").ok());
    // Held for good: after the retries the write fails as on Windows, names the cause and leaves the original alone.
    {
        fs::ReadStream reader(fs::os_path(p.dir / "data" / "a.json"), std::ios::binary);
        REQUIRE(reader.good());
        const auto t0 = std::chrono::steady_clock::now();
        const auto r = fs::write_text("data/a.json", "2");
        const auto waited = std::chrono::steady_clock::now() - t0;
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("being used by another process") != std::string::npos);
        CHECK(waited > std::chrono::milliseconds(500));  // it tried for about a second
        CHECK(fs::read_text("data/a.json").value() == "1");
        CHECK(names_in(p.dir / "data") == std::vector<std::string>{"a.json"});  // no temporary file left
        // The same holds for a delete, and read_text (which opens it again) does not break it.
        std::error_code ec;
        CHECK(!fs::remove_file(p.dir / "data" / "a.json", ec));
        CHECK(fs::is_sharing_violation(ec));
        CHECK(stdfs::exists(p.dir / "data" / "a.json"));
    }
    // Let go: the same write goes through at once (nothing left in the registry).
    const auto t1 = std::chrono::steady_clock::now();
    REQUIRE(fs::write_text("data/a.json", "2").ok());
    CHECK(std::chrono::steady_clock::now() - t1 < std::chrono::milliseconds(800));  // no retries (~0.9 s); room for a loaded VM
    CHECK(fs::read_text("data/a.json").value() == "2");
    std::error_code ec;
    CHECK(fs::remove_file(p.dir / "data" / "a.json", ec));
    CHECK(!ec);
}

TEST_CASE("windows rules: a reader that lets go within a moment does not lose the write (the retry path)") {
    RulesScope rules(true);
    TempProject p;
    REQUIRE(fs::write_text("a.json", "1").ok());
    fs::ReadStream reader(fs::os_path(p.dir / "a.json"), std::ios::binary);
    REQUIRE(reader.good());
    std::thread release([&reader] {
        std::this_thread::sleep_for(std::chrono::milliseconds(80));
        reader.close();
    });
    const auto r = fs::write_text("a.json", "2");
    release.join();
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    CHECK(fs::read_text("a.json").value() == "2");
    // A reader that lets go while a delete waits.
    fs::ReadStream again(fs::os_path(p.dir / "a.json"), std::ios::binary);
    std::thread release2([&again] {
        std::this_thread::sleep_for(std::chrono::milliseconds(80));
        again.close();
    });
    std::error_code ec;
    CHECK(fs::remove_file(p.dir / "a.json", ec));
    release2.join();
    CHECK(!ec);
}

TEST_CASE("windows rules: fs::read_bytes holds the file open only while it reads, the registry forgets it after") {
    RulesScope rules(true);
    TempProject p;
    REQUIRE(fs::write_text("a.json", "1").ok());
    for (int i = 0; i < 20; ++i) {
        REQUIRE(fs::read_text("a.json").ok());
        REQUIRE(fs::write_text("a.json", std::to_string(i)).ok());  // would take a second each if a read stayed registered
    }
    // A failed open and a moved-from-nothing stream register nothing either.
    { fs::ReadStream missing(fs::os_path(p.dir / "nope.json")); CHECK(!missing.good()); }
    const auto t0 = std::chrono::steady_clock::now();
    REQUIRE(fs::write_text("nope.json", "x").ok());
    // The retries of the mode take ~0.9 s; one write on a loaded CI VM takes far less than 800 ms.
    CHECK(std::chrono::steady_clock::now() - t0 < std::chrono::milliseconds(800));
}

TEST_CASE("windows rules: a folder with an open file inside is deleted except for that file, and reports the violation") {
    RulesScope rules(true);
    TempProject p;
    REQUIRE(fs::write_text("tree/keep/open.txt", "o").ok());
    REQUIRE(fs::write_text("tree/keep/other.txt", "o").ok());
    REQUIRE(fs::write_text("tree/gone/x.txt", "x").ok());
    REQUIRE(fs::write_text("tree/y.txt", "y").ok());
    {
        fs::ReadStream reader(fs::os_path(p.dir / "tree" / "keep" / "open.txt"), std::ios::binary);
        REQUIRE(reader.good());
        std::error_code ec;
        fs::remove_tree(p.dir / "tree", ec);
        CHECK(fs::is_sharing_violation(ec));
        CHECK(stdfs::exists(p.dir / "tree" / "keep" / "open.txt"));
        CHECK(!stdfs::exists(p.dir / "tree" / "keep" / "other.txt"));
        CHECK(!stdfs::exists(p.dir / "tree" / "gone"));
        CHECK(!stdfs::exists(p.dir / "tree" / "y.txt"));
    }
    std::error_code ec;
    fs::remove_tree(p.dir / "tree", ec);
    CHECK(!ec);
    CHECK(!stdfs::exists(p.dir / "tree"));
}

TEST_CASE("windows rules: paths are case-insensitive and a relative or symlinked spelling meets the same file") {
    RulesScope rules(true);
    TempProject p;
    REQUIRE(fs::write_text("Data/A.json", "1").ok());
    fs::ReadStream reader(fs::os_path(p.dir / "Data" / "A.json"), std::ios::binary);
    REQUIRE(reader.good());
    // Other spellings of the same file: the folder in other letter case (Windows cannot tell the two apart), and a "." segment.
    std::error_code ec;
    fs::remove_tree(p.dir / "data", ec);
    CHECK(fs::is_sharing_violation(ec));
    CHECK(stdfs::exists(p.dir / "Data" / "A.json"));
    ec.clear();
    fs::replace_file(p.dir / "x.tmp", p.dir / "." / "Data" / "A.json", ec);
    CHECK(fs::is_sharing_violation(ec));
}

TEST_CASE("fs: file times count nanoseconds from 1970 with every standard library") {
    // libstdc++'s file clock starts in 2174 and MSVC's in 1601: the raw count of a file written today is negative on
    // Linux, which read as "missing" before file_time_ns.
    TempProject p;
    REQUIRE(fs::write_text("a.json", "1").ok());
    const std::int64_t t = fs::host_modified_time(p.dir / "a.json");
    CHECK(t > 0);
    CHECK(fs::modified_time("a.json") == t);
    const std::int64_t sys = std::chrono::duration_cast<std::chrono::nanoseconds>(
                                 std::chrono::system_clock::now().time_since_epoch()).count();
    const std::int64_t clock = fs::file_time_ns(stdfs::file_time_type::clock::now());
    CHECK(std::abs(clock - sys) < std::int64_t(5'000'000'000));
    CHECK(std::abs(t - sys) < std::int64_t(3600) * 1'000'000'000);
    CHECK(fs::host_modified_time(p.dir / "missing.json") == -1);
}

TEST_CASE("windows rules: modified_time moves in steps of 15.625 ms") {
    TempProject p;
    REQUIRE(fs::write_text("a.json", "1").ok());
    using Ns = std::chrono::nanoseconds;
    const stdfs::path file = p.dir / "a.json";
    // A time that is not on a step: 3 steps and 7.5 ms past the start of the clock's own epoch of a whole second.
    const auto base = stdfs::last_write_time(file);
    const std::int64_t baseNs = std::chrono::duration_cast<Ns>(base.time_since_epoch()).count();
    const std::int64_t aligned = baseNs - ((baseNs % 1'000'000'000) + 1'000'000'000) % 1'000'000'000;  // a whole second
    const std::int64_t odd = aligned + 3 * fs::kWindowsTimeStepNs + 7'500'000;
    stdfs::last_write_time(file, stdfs::file_time_type(std::chrono::duration_cast<stdfs::file_time_type::duration>(Ns(odd))));
    const std::int64_t set = fs::file_time_ns(stdfs::last_write_time(file));
    {
        RulesScope off(false);
        CHECK(fs::modified_time("a.json") == set);
    }
    {
        RulesScope on(true);
        const std::int64_t t = fs::modified_time("a.json");
        CHECK(t % fs::kWindowsTimeStepNs == 0);
        CHECK(t <= set);
        CHECK(set - t < fs::kWindowsTimeStepNs);
        // Two writes less than a step apart keep one time: a detector comparing times alone misses the second.
        stdfs::last_write_time(file, stdfs::file_time_type(std::chrono::duration_cast<stdfs::file_time_type::duration>(Ns(odd + 5'000'000))));
        CHECK(fs::modified_time("a.json") == t);
        // A step later it differs.
        stdfs::last_write_time(file, stdfs::file_time_type(std::chrono::duration_cast<stdfs::file_time_type::duration>(Ns(odd + fs::kWindowsTimeStepNs))));
        CHECK(fs::modified_time("a.json") == t + fs::kWindowsTimeStepNs);
    }
}

TEST_CASE("windows rules: with the mode off ReadStream blocks nothing and costs the write nothing") {
    RulesScope off(false);
    TempProject p;
    REQUIRE(fs::write_text("a.json", "1").ok());
    fs::ReadStream reader(fs::os_path(p.dir / "a.json"), std::ios::binary);
    REQUIRE(reader.good());
    const auto t0 = std::chrono::steady_clock::now();
    REQUIRE(fs::write_text("a.json", "2").ok());  // POSIX replaces a file that is open
    // The retries of the mode take ~0.9 s; one write on a loaded CI VM takes far less than 800 ms.
    CHECK(std::chrono::steady_clock::now() - t0 < std::chrono::milliseconds(800));
    std::error_code ec;
    CHECK(fs::remove_file(p.dir / "a.json", ec));
    CHECK(!fs::is_sharing_violation(std::make_error_code(std::errc::io_error)));
}
#endif

TEST_CASE("fs: a path under a folder with accents is found from its UTF-8 text and from path::generic_string()") {
    // generic_string() gives the ANSI code page on Windows: path_from_utf8 (and so resolve and every fs:: function) reads text
    // that is not UTF-8 in that code page instead of throwing, so the many callers that still build paths that way keep working.
    const stdfs::path root = fs::make_temp_dir("fa_fs_accents").value();
    const stdfs::path dir = root / stdfs::path(u8"Cañón niño");
    stdfs::create_directories(dir);
    const stdfs::path file = dir / "a.txt";
    REQUIRE(fs::write_text(fs::path_to_utf8(file), "utf8").ok());
    CHECK(stdfs::exists(file));
    std::string legacy;
    try {
        legacy = file.generic_string();
    } catch (const std::exception&) {
        // a name the code page cannot hold: nothing to check for that form
    }
    if (!legacy.empty()) {
        CHECK(fs::path_from_utf8(legacy) == fs::path_from_utf8(fs::path_to_utf8(file)));
        REQUIRE(fs::write_text(legacy, "legacy").ok());
        auto back = fs::read_text(fs::path_to_utf8(file));
        REQUIRE(back.ok());
        CHECK(back.value() == "legacy");
    }
    std::error_code ec;
    stdfs::remove_all(root, ec);
}
