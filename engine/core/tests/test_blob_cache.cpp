#include <doctest.h>

#include <atomic>
#include <cctype>
#include <cstdlib>
#include <chrono>
#include <memory>
#include <mutex>
#include <fstream>
#include <thread>

#include "fa/core/blob_cache.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct CacheDir {
    stdfs::path dir;
    CacheDir() { dir = fs::make_temp_dir("fa_test_blobcache"); }
    ~CacheDir() {
        std::error_code ec;
        fs::remove_tree(dir, ec);
    }
};

struct RulesScope {
    bool before = fs::windows_rules();
    explicit RulesScope(bool on) { fs::set_windows_rules(on); }
    ~RulesScope() { fs::set_windows_rules(before); }
};

void set_env(const char* name, const char* value) {
#ifdef _WIN32
    _putenv_s(name, value ? value : "");  // an empty value removes the variable
#else
    if (value) ::setenv(name, value, 1);
    else ::unsetenv(name);
#endif
}

// True when `dir` holds only finished cache files. A temporary file left by a failed store is deleted with retries, but on
// Windows an antivirus scanner or the indexer may hold it for a moment: wait up to 5 s (a safety net, not a speed limit).
bool only_cache_files(const stdfs::path& dir) {
    for (int attempt = 0; attempt < 100; ++attempt) {
        bool clean = true;
        for (const auto& e : stdfs::directory_iterator(dir)) clean = clean && e.path().extension() == ".facache";
        if (clean) return true;
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    return false;
}

std::vector<std::uint8_t> bytes_of(const std::string& s) { return {s.begin(), s.end()}; }

// Collects the log lines of the "cache" category while alive. The sink owns what it writes (a log sink may run once more
// after remove_log_sink).
struct CacheLog {
    struct Shared {
        std::mutex mutex;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Shared> shared = std::make_shared<Shared>();
    int id = 0;
    CacheLog() {
        id = add_log_sink([s = shared](const LogEntry& e) {
            if (e.category != "cache") return;
            std::lock_guard<std::mutex> lock(s->mutex);
            s->lines.push_back(e.message);
        });
    }
    ~CacheLog() { remove_log_sink(id); }
    std::size_t count() const {
        std::lock_guard<std::mutex> lock(shared->mutex);
        return shared->lines.size();
    }
};

std::vector<std::uint8_t> read_all(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return {std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
}
void write_all(const stdfs::path& p, const std::vector<std::uint8_t>& b) {
    std::ofstream out(p, std::ios::binary | std::ios::trunc);
    out.write(reinterpret_cast<const char*>(b.data()), std::streamsize(b.size()));
}

}  // namespace

TEST_CASE("BlobCache: a stored blob comes back byte for byte") {
    CacheDir t;
    BlobCache cache(t.dir / "shaders", "d3d11|test|0.1|abc");
    REQUIRE(cache.enabled());
    const auto payload = bytes_of(std::string("DXBC\0\1\2\3", 8) + std::string(1000, 'x'));
    REQUIRE(cache.store("quad-vs", payload).ok());
    std::vector<std::uint8_t> out;
    CHECK(cache.load("quad-vs", out) == BlobCache::Status::Hit);
    CHECK(out == payload);
    CHECK(cache.load("quad-fs", out) == BlobCache::Status::Miss);
    CHECK(out.empty());
}

TEST_CASE("BlobCache: an empty payload is a valid blob") {
    CacheDir t;
    BlobCache cache(t.dir, "k");
    REQUIRE(cache.store("empty", {}).ok());
    std::vector<std::uint8_t> out{1, 2, 3};
    CHECK(cache.load("empty", out) == BlobCache::Status::Hit);
    CHECK(out.empty());
}

TEST_CASE("BlobCache: a different key is Stale, ignored with one log line, and a store replaces it") {
    CacheDir t;
    BlobCache oldDriver(t.dir, "d3d11|driver-1|0.1");
    BlobCache newDriver(t.dir, "d3d11|driver-2|0.1");
    REQUIRE(oldDriver.store("mesh-vs", bytes_of("old")).ok());
    CacheLog log;
    std::vector<std::uint8_t> out;
    std::string why;
    CHECK(newDriver.load("mesh-vs", out, &why) == BlobCache::Status::Stale);
    CHECK(out.empty());
    CHECK(log.count() == 1);
    CHECK(why.find("driver-1") != std::string::npos);
    CHECK(why.find("driver-2") != std::string::npos);
    REQUIRE(newDriver.store("mesh-vs", bytes_of("new")).ok());
    CHECK(newDriver.load("mesh-vs", out) == BlobCache::Status::Hit);
    CHECK(out == bytes_of("new"));
    CHECK(oldDriver.load("mesh-vs", out) == BlobCache::Status::Stale);  // and now the old key is the stale one
}

TEST_CASE("BlobCache: damaged bytes are detected whatever part was hit") {
    CacheDir t;
    BlobCache cache(t.dir, "key");
    const auto payload = bytes_of(std::string(300, 'p'));
    REQUIRE(cache.store("a", payload).ok());
    const stdfs::path file = cache.file_for("a");
    const auto good = read_all(file);
    std::vector<std::uint8_t> out;
    CacheLog log;

    SUBCASE("a flipped payload byte fails the checksum") {
        auto bad = good;
        bad.back() ^= 0x55;
        write_all(file, bad);
        CHECK(cache.load("a", out) == BlobCache::Status::Damaged);
        CHECK(out.empty());
        CHECK(log.count() == 1);
    }
    SUBCASE("a flipped checksum byte fails the checksum") {
        auto bad = good;
        bad[good.size() - 300 - 5] ^= 0x01;
        write_all(file, bad);
        CHECK(cache.load("a", out) == BlobCache::Status::Damaged);
    }
    SUBCASE("a wrong magic is not a cache file") {
        auto bad = good;
        bad[0] = 'X';
        write_all(file, bad);
        CHECK(cache.load("a", out) == BlobCache::Status::Damaged);
    }
    SUBCASE("another format version is ignored") {
        auto bad = good;
        bad[4] = 99;
        write_all(file, bad);
        std::string why;
        CHECK(cache.load("a", out, &why) == BlobCache::Status::Damaged);
        CHECK(why.find("format version 99") != std::string::npos);
    }
    SUBCASE("a file cut short at any length is Damaged, never Hit") {
        for (std::size_t keep : {std::size_t(0), std::size_t(3), std::size_t(11), std::size_t(20), good.size() - 300 - 1, good.size() - 150, good.size() - 1}) {
            auto bad = good;
            bad.resize(keep);
            write_all(file, bad);
            const auto status = cache.load("a", out);
            INFO("kept " << keep << " of " << good.size());
            CHECK(status == BlobCache::Status::Damaged);
            CHECK(out.empty());
        }
    }
    SUBCASE("extra bytes at the end are Damaged") {
        auto bad = good;
        bad.push_back(0);
        write_all(file, bad);
        CHECK(cache.load("a", out) == BlobCache::Status::Damaged);
    }
    SUBCASE("a key length that runs past the file is Damaged") {
        auto bad = good;
        bad[8] = 0xff;
        bad[9] = 0x0f;  // 4095 bytes of key: more than the file holds
        write_all(file, bad);
        CHECK(cache.load("a", out) == BlobCache::Status::Damaged);
    }
    SUBCASE("a damaged file is rebuilt by the next store") {
        write_all(file, bytes_of("garbage"));
        CHECK(cache.load("a", out) == BlobCache::Status::Damaged);
        REQUIRE(cache.store("a", payload).ok());
        CHECK(cache.load("a", out) == BlobCache::Status::Hit);
        CHECK(out == payload);
    }
}

TEST_CASE("BlobCache: names are checked and a disabled cache does nothing") {
    CacheDir t;
    BlobCache cache(t.dir, "k");
    std::vector<std::uint8_t> out;
    std::string why;
    CHECK(cache.load("../escape", out, &why) == BlobCache::Status::Miss);
    CHECK(why.find("letters, digits") != std::string::npos);
    auto r = cache.store("a/b", bytes_of("x"));
    CHECK_FALSE(r.ok());
    CHECK(r.error().message.find("a/b") != std::string::npos);
    CHECK_FALSE(stdfs::exists(t.dir / "a"));

    BlobCache off(stdfs::path{}, "k");
    CHECK_FALSE(off.enabled());
    CHECK(off.load("x", out) == BlobCache::Status::Disabled);
    CHECK_FALSE(off.store("x", bytes_of("x")).ok());
}

TEST_CASE("BlobCache: a store leaves no temporary file behind") {
    CacheDir t;
    BlobCache cache(t.dir, "k");
    for (int i = 0; i < 3; ++i) REQUIRE(cache.store("x", bytes_of(std::string(10 + i, 'a'))).ok());
    int files = 0;
    for (const auto& e : stdfs::directory_iterator(t.dir)) {
        ++files;
        CHECK(e.path().extension() == ".facache");
    }
    CHECK(files == 1);
}

TEST_CASE("BlobCache: the atomic write waits for a reader (Windows rules) and fails without touching the old file") {
    CacheDir t;
    RulesScope rules(true);  // a file open through fs::ReadStream cannot be replaced, like on Windows
    BlobCache cache(t.dir, "k");
    REQUIRE(cache.store("lib", bytes_of("first")).ok());
    const stdfs::path file = cache.file_for("lib");

    SUBCASE("a reader that lets go soon: the store succeeds") {
        auto reader = std::make_unique<fs::ReadStream>(file, std::ios::binary);
        REQUIRE(reader->is_open());
        std::thread closer([&] {
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
            reader->close();
        });
        const auto stored = cache.store("lib", bytes_of("second"));
        closer.join();
        CHECK(stored.ok());
        std::vector<std::uint8_t> out;
        CHECK(cache.load("lib", out) == BlobCache::Status::Hit);
        CHECK(out == bytes_of("second"));
    }
    SUBCASE("a reader that never lets go: the store reports it and the old blob stays") {
        fs::ReadStream reader(file, std::ios::binary);
        REQUIRE(reader.is_open());
        const auto stored = cache.store("lib", bytes_of("second"));
        CHECK_FALSE(stored.ok());
        if (!stored.ok()) CHECK(stored.error().message.find("Cannot replace") != std::string::npos);
        reader.close();
        std::vector<std::uint8_t> out;
        CHECK(cache.load("lib", out) == BlobCache::Status::Hit);
        CHECK(out == bytes_of("first"));
        CHECK(only_cache_files(t.dir));  // the temporary file is gone
    }
}

TEST_CASE("BlobCache: a load while a store replaces the file never sees a half file") {
    CacheDir t;
    BlobCache cache(t.dir, "k");
    const auto a = bytes_of(std::string(20000, 'a')), b = bytes_of(std::string(30000, 'b'));
    REQUIRE(cache.store("x", a).ok());
    std::atomic<bool> stop{false};
    std::thread writer([&] {
        for (int i = 0; i < 40 && !stop; ++i) (void)cache.store("x", i % 2 ? a : b);
    });
    int hits = 0;
    for (int i = 0; i < 200; ++i) {
        std::vector<std::uint8_t> out;
        const auto status = cache.load("x", out);
        if (status == BlobCache::Status::Hit) {
            ++hits;
            CHECK((out == a || out == b));
        } else {
            CHECK(status == BlobCache::Status::Miss);  // a reader the writer's rename blocked on Windows: absent, never damaged
        }
    }
    stop = true;
    writer.join();
    CHECK(hits > 0);
}

TEST_CASE("fs::cache_dir: FA_CACHE_DIR overrides the default, set_cache_dir wins over both, reset_cache_dir forgets it") {
    const stdfs::path before = fs::cache_dir();
    const char* oldEnv = std::getenv("FA_CACHE_DIR");
    const std::string saved = oldEnv ? oldEnv : "";
    const bool hadEnv = oldEnv != nullptr;

    const stdfs::path fromEnv = fs::make_temp_dir("fa_test_cachedir_env");
    set_env("FA_CACHE_DIR", fs::path_to_utf8(fromEnv).c_str());
    fs::reset_cache_dir();
    CHECK(fs::cache_dir() == fromEnv);

    fs::set_cache_dir(stdfs::path("somewhere") / "cache");  // an explicit folder (a phone's player) wins
    CHECK(fs::cache_dir() == stdfs::path("somewhere") / "cache");

    fs::reset_cache_dir();  // back to the variable
    CHECK(fs::cache_dir() == fromEnv);

    set_env("FA_CACHE_DIR", nullptr);  // no variable: the platform's per-user folder, which is neither the project nor the save folder
    fs::reset_cache_dir();
    const stdfs::path dflt = fs::cache_dir();
    CHECK(dflt != fromEnv);
    if (!dflt.empty()) {  // empty where HOME / LOCALAPPDATA is not set
        std::string lower = dflt.generic_string();
        for (char& c : lower) c = char(std::tolower(static_cast<unsigned char>(c)));
        CHECK(lower.find("factoria") != std::string::npos);  // FactorIA (Windows, macOS) or factoria (Linux)
    }

    set_env("FA_CACHE_DIR", hadEnv ? saved.c_str() : nullptr);
    fs::reset_cache_dir();
    CHECK(fs::cache_dir() == before);
    std::error_code ec;
    fs::remove_tree(fromEnv, ec);
}
