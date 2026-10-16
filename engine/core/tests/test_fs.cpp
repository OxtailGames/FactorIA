#include <doctest.h>

#include <chrono>
#include <filesystem>

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
    std::error_code ec;
    stdfs::remove_all(fs::os_path(p.dir / std::string(100, 'a')), ec);  // TempProject's remove_all stops at long paths on Windows
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
    const stdfs::path a = fs::make_temp_dir("fa_test_tmp");
    const stdfs::path b = fs::make_temp_dir("fa_test_tmp");
    CHECK(a != b);
    CHECK(stdfs::is_directory(a));
    CHECK(stdfs::is_empty(a));
    CHECK(a.filename().string().rfind("fa_test_tmp_", 0) == 0);
    CHECK(stdfs::is_directory(stdfs::temp_directory_path() / a.filename()));  // directly inside the system temp folder
    stdfs::remove_all(a);
    stdfs::remove_all(b);
}
