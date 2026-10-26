// `factoria export --platform web`: the folder (index.html, the player's two files, game.pak), the page's placeholders, the
// zip for itch.io, and the errors of a missing player. The player is a fake: two small files with the right names.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <map>

#define MINIZ_HEADER_FILE_ONLY
#define MINIZ_NO_ZLIB_COMPATIBLE_NAMES
#include <encoder/basisu_miniz.h>

#include "fa/core/build_info.h"
#include "fa/core/fs.h"
#include "fa/core/pack.h"
#include "fa/core/json.h"
#include "fa/script/bytecode.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A wasm stand-in: the magic, the build fingerprint (`fingerprint`, none when empty) and padding up to 1008 bytes.
std::string fake_wasm(const std::string& fingerprint) {
    std::string bytes = std::string("\0asm\1\0\0\0", 8);
    if (!fingerprint.empty()) bytes += "FA-BUILD-FINGERPRINT:" + fingerprint + ";";
    return bytes + std::string(1008 - bytes.size(), 'w');
}

std::string fake_player(const testing::TempDir& tmp, const std::string& fingerprint = build_fingerprint(), const char* folder = "web-player") {
    const stdfs::path dir = tmp.sub(folder);
    testing::write_all(dir / "factoria_player.js", "// fake emscripten glue\n");
    testing::write_all(dir / "factoria_player.wasm", fake_wasm(fingerprint));
    return dir.string();
}

std::string make_project(const testing::TempDir& tmp, const std::string& name = "Web Test") {
    const std::string dir = tmp.sub("proj");
    ScaffoldOptions so;
    so.name = name;
    so.id = "com.example.webtest";
    auto r = create_project(dir, "2d-platformer", so);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return dir;
}

ExportOptions web_options(const testing::TempDir& tmp, const std::string& proj) {
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "web";
    o.outDir = tmp.sub("out");
    o.playerBinary = fake_player(tmp);
    return o;
}

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::uint32_t u16(const std::string& s, std::size_t at) {
    return static_cast<unsigned char>(s[at]) | (static_cast<unsigned char>(s[at + 1]) << 8);
}
std::uint32_t u32(const std::string& s, std::size_t at) { return u16(s, at) | (u16(s, at + 2) << 16); }

// The files of a zip (name -> content), read through its central directory like any unzip tool does. Empty on a malformed zip.
std::map<std::string, std::string> read_zip(const std::string& zip, std::vector<std::string>* order = nullptr) {
    std::map<std::string, std::string> out;
    if (zip.size() < 22) return out;
    const std::size_t eocd = zip.size() - 22;  // no archive comment
    REQUIRE(u32(zip, eocd) == 0x06054b50);
    const std::uint32_t count = u16(zip, eocd + 10);
    std::size_t at = u32(zip, eocd + 16);
    for (std::uint32_t i = 0; i < count; ++i) {
        REQUIRE(u32(zip, at) == 0x02014b50);
        const std::uint32_t method = u16(zip, at + 10), crc = u32(zip, at + 16), csize = u32(zip, at + 20), size = u32(zip, at + 24);
        const std::uint32_t nameLen = u16(zip, at + 28), extra = u16(zip, at + 30), comment = u16(zip, at + 32), local = u32(zip, at + 42);
        const std::string name = zip.substr(at + 46, nameLen);
        at += 46 + nameLen + extra + comment;
        REQUIRE(u32(zip, local) == 0x04034b50);
        const std::size_t data = local + 30 + u16(zip, local + 26) + u16(zip, local + 28);
        std::string content;
        if (method == 0) {
            content = zip.substr(data, csize);
        } else {
            REQUIRE(method == 8);
            std::size_t n = 0;
            void* heap = buminiz::tinfl_decompress_mem_to_heap(zip.data() + data, csize, &n, 0);  // raw deflate
            REQUIRE(heap != nullptr);
            content.assign(static_cast<const char*>(heap), n);
            std::free(heap);
        }
        CHECK(content.size() == size);
        CHECK(static_cast<std::uint32_t>(buminiz::mz_crc32(buminiz::mz_crc32(0, nullptr, 0), reinterpret_cast<const unsigned char*>(content.data()), content.size())) == crc);
        if (order) order->push_back(name);
        out[name] = std::move(content);
    }
    return out;
}

struct ScopedHome {  // FACTORIA_HOME somewhere empty: no players installed by an earlier `setup players`
    std::string old;
    bool had = false;
    explicit ScopedHome(const std::string& dir) {
        if (const char* cur = std::getenv("FACTORIA_HOME")) {
            had = true;
            old = cur;
        }
        set(dir.c_str());
    }
    ~ScopedHome() { set(had ? old.c_str() : ""); }
    static void set(const char* v) {
#if defined(_WIN32)
        _putenv_s("FACTORIA_HOME", v);
#else
        if (*v) setenv("FACTORIA_HOME", v, 1);
        else unsetenv("FACTORIA_HOME");
#endif
    }
};

}  // namespace

TEST_CASE("export web: the folder holds the page, the player's two files and the game in one pack") {
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp));
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const stdfs::path root = r->outputDir;
    CHECK(root.filename().string() == "web-test-web");
    CHECK(r->mode == "explicit");
    CHECK(r->pack == "game.pak");
    CHECK(r->format == "zip");
    CHECK(has(r->files, "index.html"));
    CHECK(has(r->files, "factoria_player.js"));
    CHECK(has(r->files, "factoria_player.wasm"));
    CHECK(has(r->files, "game.pak"));
    CHECK(has(r->files, "FACTORIA_NOTICES.txt"));
    CHECK(r->notices == "FACTORIA_NOTICES.txt");
    CHECK_FALSE(has(r->files, "game/factoria.json"));  // never a game/ folder: one pack, release or not

    const std::string html = testing::read_all(root / "index.html");
    CHECK(html.find("<title>Web Test</title>") != std::string::npos);
    CHECK(html.find("{{") == std::string::npos);
    CHECK(testing::read_all(root / "factoria_player.js") == "// fake emscripten glue\n");
    const std::uintmax_t wasmBytes = stdfs::file_size(root / "factoria_player.wasm");
    CHECK(wasmBytes == 1008);
    CHECK(html.find(std::to_string(wasmBytes)) != std::string::npos);
    CHECK(html.find(std::to_string(stdfs::file_size(root / "game.pak"))) != std::string::npos);

    auto pack = PackReader::open((root / "game.pak").string());
    REQUIRE_MESSAGE(pack.ok(), (pack.ok() ? "" : pack.error().message));
    CHECK((*pack)->contains("factoria.json"));
}

TEST_CASE("export web: the zip has index.html at its root and the same files as the folder") {
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp));
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const stdfs::path zipPath = stdfs::path(r->outputDir).parent_path() / "web-test-web.zip";
    CHECK(r->artifact == zipPath.generic_string());
    REQUIRE(stdfs::is_regular_file(zipPath));

    std::vector<std::string> order;
    const auto files = read_zip(testing::read_all(zipPath), &order);
    REQUIRE_FALSE(order.empty());
    CHECK(order.front() == "index.html");
    for (const std::string& name : order) CHECK(name.find('/') == std::string::npos);  // flat: itch.io wants index.html at the root
    for (const char* name : {"index.html", "factoria_player.js", "factoria_player.wasm", "game.pak", "FACTORIA_NOTICES.txt"}) {
        REQUIRE_MESSAGE(files.count(name) == 1, name);
        CHECK(files.at(name) == testing::read_all(stdfs::path(r->outputDir) / name));
    }
    CHECK(files.count(kExportMarkerFile) == 0);  // for the next export, not for players
}

TEST_CASE("export web: the game's name is HTML-escaped and a placeholder in it is not expanded") {
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp, "Tom & <Jerry> {{pakBytes}}"));
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const std::string html = testing::read_all(stdfs::path(r->outputDir) / "index.html");
    CHECK(html.find("Tom &amp; &lt;Jerry&gt; {{pakBytes}}") != std::string::npos);
    CHECK(html.find("<Jerry>") == std::string::npos);
}

TEST_CASE("export web: --player can be the folder or factoria_player.js; an incomplete or wrong one is a teaching error") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    ExportOptions o = web_options(tmp, proj);
    o.playerBinary += "/factoria_player.js";
    CHECK(export_project(o).ok());

    o.playerBinary = tmp.sub("web-player") + "/factoria_player.wasm";
    CHECK(export_project(o).ok());

    stdfs::remove(tmp.sub("web-player") + "/factoria_player.wasm");
    auto missing = export_project(o);
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("factoria_player.wasm") != std::string::npos);
    CHECK(missing.error().hint.find("--player") != std::string::npos);

    testing::write_all(tmp.sub("other/tool.exe"), "x");
    o.playerBinary = tmp.sub("other/tool.exe");
    auto wrong = export_project(o);
    REQUIRE_FALSE(wrong.ok());
    CHECK(wrong.error().message.find("not a web player") != std::string::npos);

    o.playerBinary = tmp.sub("nowhere");
    auto none = export_project(o);
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message.find("not found") != std::string::npos);
}

TEST_CASE("export web: no player anywhere names the places searched and the command that fixes it") {
    testing::TempDir tmp;
    ScopedHome home(tmp.sub("empty-home"));
    ExportOptions o = web_options(tmp, make_project(tmp));
    o.playerBinary.clear();
    o.buildSourceRoot = tmp.sub("no-checkout");
    auto r = export_project(o);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("no web player found") != std::string::npos);
    CHECK(r.error().hint.find("factoria setup players --platforms web") != std::string::npos);
    CHECK_FALSE(stdfs::exists(stdfs::path(tmp.sub("out")) / "web-test-web"));  // nothing was written
}

TEST_CASE("export web: a dry run reports the plan and writes nothing") {
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp));
    auto plan = plan_export(o);
    REQUIRE_MESSAGE(plan.ok(), (plan.ok() ? "" : plan.error().to_string()));
    CHECK(plan->platform == "web");
    CHECK(plan->mode == "explicit");
    CHECK(plan->format == "zip");
    CHECK(plan->player == (stdfs::path(o.playerBinary) / "factoria_player.js").generic_string());
    // The export resolves its folder (RUNNER~1 on Windows runners, /var -> /private/var on macOS): compare resolved paths.
    CHECK(stdfs::weakly_canonical(plan->artifact) == stdfs::weakly_canonical(stdfs::path(tmp.sub("out")) / "web-test-web.zip"));
    CHECK(plan->to_json()["mode"] == "explicit");
    CHECK_FALSE(stdfs::exists(tmp.sub("out")));
}

TEST_CASE("export web: platform aliases, no icon warning, and a platforms list without web is fine") {
    CHECK(normalize_export_platform("web") == "web");
    CHECK(normalize_export_platform("HTML5") == "web");
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp));
    o.platform = "html5";
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    for (const std::string& w : r->warnings) {
        CHECK(w.find("No icon") == std::string::npos);
        CHECK(w.find("\"platforms\"") == std::string::npos);
    }
}

TEST_CASE("export web: scripts are compiled to bytecode in the pack, like a desktop release") {
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp));
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    auto pack = PackReader::open(stdfs::path(r->outputDir) / "game.pak");
    REQUIRE(pack.ok());
    std::string script;
    for (const std::string& f : r->packed)
        if (f.size() > 3 && f.compare(f.size() - 3, 3, ".js") == 0) script = f;
    REQUIRE_FALSE(script.empty());
    auto bytes = (*pack)->read(script);
    REQUIRE(bytes.ok());
    CHECK(has(r->packed, "factoria.json"));
    CHECK(is_script_bytecode(std::string_view(reinterpret_cast<const char*>(bytes->data()), bytes->size())));
}

TEST_CASE("export web: a player of another build stops the export unless allowPlayerMismatch") {
    if (std::string(build_fingerprint()) == "unknown") return;  // built outside a git checkout: nothing to compare
    testing::TempDir tmp;
    ExportOptions o = web_options(tmp, make_project(tmp));

    SUBCASE("the same build exports quietly") {
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        for (const std::string& w : r->warnings) CHECK(w.find("build fingerprint") == std::string::npos);
    }
    SUBCASE("another fingerprint stops with an error that says what to do") {
        o.playerBinary = fake_player(tmp, "0123456789ab", "old-player");
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("web player") != std::string::npos);
        CHECK(r.error().message.find("was built from 0123456789ab") != std::string::npos);
        CHECK(r.error().hint.find("factoria setup players --platforms web") != std::string::npos);
        CHECK(r.error().hint.find("build/web-release") != std::string::npos);
        CHECK(r.error().hint.find("allowPlayerMismatch") != std::string::npos);
        CHECK_FALSE(stdfs::exists(stdfs::path(tmp.sub("out")) / "web-test-web"));  // nothing was written
    }
    SUBCASE("a player with no fingerprint is told apart") {
        o.playerBinary = fake_player(tmp, "", "old-player");
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("has no build fingerprint") != std::string::npos);
    }
    SUBCASE("allowPlayerMismatch exports anyway and says so") {
        o.playerBinary = fake_player(tmp, "0123456789ab", "old-player");
        o.allowPlayerMismatch = true;
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        bool said = false;
        for (const std::string& w : r->warnings) said = said || (w.find("0123456789ab") != std::string::npos && w.find("anyway") != std::string::npos);
        CHECK(said);
    }
}

TEST_CASE("export web: without --player the player whose fingerprint matches is chosen") {
    if (std::string(build_fingerprint()) == "unknown") return;
    testing::TempDir tmp;
    ScopedHome home(tmp.sub("fa-home"));
    ExportOptions o = web_options(tmp, make_project(tmp));
    o.playerBinary.clear();
    // The installed player (of an older release) and the checkout's own build.
    const stdfs::path installed = stdfs::path(tmp.sub("fa-home")) / "players" / FA_ENGINE_VERSION / "web";
    testing::write_all(installed / "factoria_player.js", "// installed glue\n");
    testing::write_all(installed / "factoria_player.wasm", fake_wasm("0123456789ab"));
    const stdfs::path checkout = tmp.sub("checkout");
    o.buildSourceRoot = checkout.string();

    SUBCASE("the checkout's build/web-release wins over an installed player of another build") {
        const stdfs::path build = checkout / "build" / "web-release" / "player";
        testing::write_all(build / "factoria_player.js", "// built glue\n");
        testing::write_all(build / "factoria_player.wasm", fake_wasm(build_fingerprint()));
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->mode == "build");
    }
    SUBCASE("a stale build of the checkout loses to an installed player that matches") {
        const stdfs::path build = checkout / "build" / "web-release" / "player";
        testing::write_all(build / "factoria_player.js", "// built glue\n");
        testing::write_all(build / "factoria_player.wasm", fake_wasm("ffffffffffff"));
        testing::write_all(installed / "factoria_player.wasm", fake_wasm(build_fingerprint()));
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->mode == "installed");
    }
    SUBCASE("none matches: the export stops on the first one found") {
        auto r = export_project(o);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("was built from 0123456789ab") != std::string::npos);
    }
}
