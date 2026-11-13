// The shader cache layer (src/shader_cache.h): the part that does not need a graphics device. A fake compiler stands in for
// D3DCompile, so what is tested is the cache logic every backend that caches shares: hit, miss, stale, damaged, store.
#include <doctest.h>

#include <atomic>
#include <cctype>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/blob_cache.h"
#include "fa/core/fs.h"
#include "shader_cache.h"

using namespace fa;
using namespace fa::render;
namespace stdfs = std::filesystem;

namespace {

struct TempDir {
    stdfs::path dir;
    TempDir() {
        static std::atomic<int> counter{0};
        dir = stdfs::temp_directory_path() /
              (std::string("fa_test_shadercache_") + std::to_string(counter++) + "_" +
               std::to_string(std::uintmax_t(reinterpret_cast<std::uintptr_t>(this) & 0xffffff)));
        std::error_code ec;
        stdfs::remove_all(dir, ec);
        stdfs::create_directories(dir);
    }
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

// Counts its calls and returns "bytecode of <source>".
struct FakeCompiler {
    int calls = 0;
    bool fail = false;
    StageCompiler fn() {
        return [this](const sg_shader_function& f, std::vector<std::uint8_t>& out, std::string& error) {
            ++calls;
            if (fail) {
                error = "boom";
                return false;
            }
            const std::string text = std::string("DXBC:") + (f.source ? f.source : "");
            out.assign(text.begin(), text.end());
            return true;
        };
    }
};

sg_shader_function func(const char* source) {
    sg_shader_function f{};
    f.source = source;
    f.entry = "main";
    f.d3d11_target = "vs_5_0";
    return f;
}

}  // namespace

TEST_CASE("shader cache: the first run compiles and stores, the second reads the file and compiles nothing") {
    TempDir t;
    FakeCompiler c;
    ShaderBuildStats stats;
    std::vector<std::uint8_t> out;
    const sg_shader_function f = func("float4 main() { return 0; }");
    REQUIRE(cached_stage_bytecode(t.dir, "d3d11|1|flags", "quad", "vs", f, c.fn(), out, stats));
    CHECK(c.calls == 1);
    CHECK(stats.cacheMisses == 1);
    CHECK(stats.cacheStored == 1);
    const std::vector<std::uint8_t> first = out;

    ShaderBuildStats second;
    std::vector<std::uint8_t> again;
    REQUIRE(cached_stage_bytecode(t.dir, "d3d11|1|flags", "quad", "vs", f, c.fn(), again, second));
    CHECK(c.calls == 1);  // not compiled again
    CHECK(second.cacheHits == 1);
    CHECK(second.cacheMisses == 0);
    CHECK(again == first);
}

namespace {
// The .facache files of a folder.
std::vector<stdfs::path> cache_files(const stdfs::path& dir) {
    std::vector<stdfs::path> v;
    for (const auto& e : stdfs::directory_iterator(dir))
        if (e.path().extension() == ".facache") v.push_back(e.path());
    return v;
}
}  // namespace

TEST_CASE("shader cache: another source, engine version or flags makes its own file; the first is still a hit") {
    TempDir t;
    FakeCompiler c;
    ShaderBuildStats stats;
    std::vector<std::uint8_t> out;
    REQUIRE(cached_stage_bytecode(t.dir, "d3d11|1|flags", "quad", "vs", func("A"), c.fn(), out, stats));
    ShaderBuildStats s1;
    REQUIRE(
        cached_stage_bytecode(t.dir, "d3d11|1|flags", "quad", "vs", func("B"), c.fn(), out, s1));  // the shader changed
    CHECK(s1.cacheMisses == 1);
    CHECK(s1.cacheHits == 0);
    CHECK(c.calls == 2);
    CHECK(std::string(out.begin(), out.end()) == "DXBC:B");
    ShaderBuildStats s2;
    REQUIRE(cached_stage_bytecode(t.dir, "d3d11|2|flags", "quad", "vs", func("B"), c.fn(), out,
                                  s2));  // another engine version
    CHECK(s2.cacheMisses == 1);
    CHECK(c.calls == 3);
    CHECK(cache_files(t.dir).size() ==
          3);  // three entries side by side: two versions or two games never replace each other's
    // Each is a hit now, whichever ran last: nothing is compiled again.
    for (const char* key : {"d3d11|1|flags", "d3d11|2|flags"}) {
        ShaderBuildStats s;
        REQUIRE(cached_stage_bytecode(t.dir, key, "quad", "vs", func("B"), c.fn(), out, s));
        CHECK(s.cacheHits == 1);
    }
    ShaderBuildStats sa;
    REQUIRE(cached_stage_bytecode(t.dir, "d3d11|1|flags", "quad", "vs", func("A"), c.fn(), out, sa));
    CHECK(sa.cacheHits == 1);
    CHECK(c.calls == 3);
}

TEST_CASE("shader cache: a file under the right name with another key is stale, ignored and replaced") {
    TempDir t;
    FakeCompiler c;
    std::vector<std::uint8_t> out;
    ShaderBuildStats first;
    REQUIRE(cached_stage_bytecode(t.dir, "k", "quad", "vs", func("A"), c.fn(), out, first));
    const auto files = cache_files(t.dir);
    REQUIRE(files.size() == 1);
    // Another program's entry stored under this name (a hash collision, or a file copied by hand): same name, other key.
    const std::string name = files[0].stem().string();
    REQUIRE(BlobCache(t.dir, "someone else's key").store(name, std::vector<std::uint8_t>{1, 2, 3}).ok());
    ShaderBuildStats s;
    REQUIRE(cached_stage_bytecode(t.dir, "k", "quad", "vs", func("A"), c.fn(), out, s));
    CHECK(s.cacheStale == 1);
    CHECK(s.cacheHits == 0);
    CHECK(std::string(out.begin(), out.end()) == "DXBC:A");
    ShaderBuildStats again;
    REQUIRE(cached_stage_bytecode(t.dir, "k", "quad", "vs", func("A"), c.fn(), out, again));
    CHECK(again.cacheHits == 1);
}

TEST_CASE("shader cache: a damaged or cut-short file is recompiled and stored again") {
    TempDir t;
    FakeCompiler c;
    std::vector<std::uint8_t> out;
    ShaderBuildStats stats;
    const sg_shader_function f = func("src");
    REQUIRE(cached_stage_bytecode(t.dir, "k", "mesh", "fs", f, c.fn(), out, stats));
    const auto files = cache_files(t.dir);
    REQUIRE(files.size() == 1);
    const stdfs::path file = fs::os_path(files[0]);
    // flip one byte near the end (the payload)
    {
        std::fstream io(file, std::ios::in | std::ios::out | std::ios::binary);
        io.seekp(-1, std::ios::end);
        io.put('\x7f');
    }
    ShaderBuildStats s1;
    REQUIRE(cached_stage_bytecode(t.dir, "k", "mesh", "fs", f, c.fn(), out, s1));
    CHECK(s1.cacheDamaged == 1);
    CHECK(s1.cacheHits == 0);
    CHECK(c.calls == 2);
    ShaderBuildStats s2;
    REQUIRE(cached_stage_bytecode(t.dir, "k", "mesh", "fs", f, c.fn(), out, s2));
    CHECK(s2.cacheHits == 1);
}

TEST_CASE(
    "shader cache: without a cache folder it only compiles; a failing compiler returns false and stores nothing") {
    FakeCompiler c;
    std::vector<std::uint8_t> out;
    ShaderBuildStats s;
    REQUIRE(cached_stage_bytecode(stdfs::path(), "k", "x", "vs", func("a"), c.fn(), out, s));
    CHECK(c.calls == 1);
    CHECK(s.cacheStored == 0);

    TempDir t;
    c.fail = true;
    ShaderBuildStats f;
    CHECK_FALSE(cached_stage_bytecode(t.dir, "k", "x", "vs", func("a"), c.fn(), out, f));
    CHECK(out.empty());
    CHECK(f.cacheStored == 0);
    int files = 0;
    for (const auto& e : stdfs::directory_iterator(t.dir)) {
        (void)e;
        ++files;
    }
    CHECK(files == 0);
}

TEST_CASE("shader cache: file names are safe, bounded and differ per label and stage") {
    const std::string a = shader_cache_file_name("quad/plain", "vs");
    const std::string b = shader_cache_file_name("quad_plain", "vs");
    const std::string c = shader_cache_file_name("quad/plain", "fs");
    CHECK(a != b);  // the label hash tells apart labels that sanitise to the same text
    CHECK(a != c);
    CHECK(shader_cache_file_name("quad", "vs", "0123456789abcdef") !=
          shader_cache_file_name("quad", "vs", "fedcba9876543210"));
    CHECK(shader_cache_file_name("quad", "vs", "0123456789abcdef")
              .ends_with("-01234567"));  // a few characters of the key hash
    for (const std::string& n :
         {a, b, c, shader_cache_file_name("quad", "vs", "0123456789abcdef"),
          shader_cache_file_name(std::string(500, 'x') + "\xc3\xa9 ?*", "vs", "0123456789abcdef")}) {
        CHECK(n.size() <= 120);
        for (char ch : n) CHECK((std::isalnum(static_cast<unsigned char>(ch)) || ch == '-' || ch == '_' || ch == '.'));
    }
}

TEST_CASE("shader cache: the stats report is plain numbers") {
    ShaderBuildStats s;
    s.programs = 3;
    s.stages = 2;
    s.cacheHits = 2;
    const Json j = s.to_json("d3d11");
    CHECK(j.at("backend").get<std::string>() == "d3d11");
    CHECK(j.at("programs").get<int>() == 3);
    CHECK(j.at("cacheHits").get<int>() == 2);
}
