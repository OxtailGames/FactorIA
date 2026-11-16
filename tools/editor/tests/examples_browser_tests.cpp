// The Examples tab's logic (examples_browser.h): the words and choices, and the jobs against a fake release (no network, no window).
#include <atomic>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <thread>

#include "doctest.h"
#include "examples_browser.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kVersion = "0.30.0";

struct TempDir {
    stdfs::path path = fs::make_temp_dir("fa_examples_browser").value();
    TempDir() = default;
    TempDir(const TempDir&) = delete;
    TempDir& operator=(const TempDir&) = delete;
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
    std::string str() const { return fs::path_to_utf8(path); }
};

void put(const stdfs::path& p, const std::string& content) {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << content;
}

// A release of two examples on disk and a SetupContext that downloads from it; `hold` makes the downloads wait until cancelled.
struct Release {
    TempDir src, assets, home;
    std::atomic<bool> offline{false};
    std::atomic<bool> hold{false};
    Release() {
        put(src.path / "examples.json",
            R"({"format":"factoria.examples-source/1","examples":[
  {"name":"alpha","title":"Alpha","shows":"The first.","readFirst":["docs/SCRIPTING.md"]},
  {"name":"beta","title":"Beta","shows":"The second.","readFirst":[]}]})");
        for (const char* n : {"alpha", "beta"}) {
            put(src.path / n / "factoria.json",
                std::string(R"({"format":"factoria.project/1","id":"com.test.)") + n + R"(","name":")" + n + R"("})");
            put(src.path / n / "scripts/main.js", std::string("// ") + n + "\n");
        }
        auto m = package_examples(src.path, assets.path, kVersion);
        REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    }
    SetupContext ctx() {
        SetupContext c;
        c.home = home.str();
        c.engineVersion = kVersion;
        c.download = [this](const DownloadRequest& rq) {
            DownloadResult r;
            while (hold.load() && !is_cancelled(rq.cancel)) std::this_thread::sleep_for(std::chrono::milliseconds(2));
            auto fail = [&](bool cancelled, const std::string& message) {
                r.ok = false;
                r.cancelled = cancelled;
                r.error = make_error(message, "Try again.");
                return r;
            };
            if (is_cancelled(rq.cancel)) return fail(true, "cancelled");
            if (offline.load()) return fail(false, "Cannot download " + rq.what + ": offline.");
            const std::string probe = examples_asset_url(kVersion, "x.zip");
            const std::string prefix = probe.substr(0, probe.size() - 5);
            const std::string file = rq.url.rfind(prefix, 0) == 0 ? rq.url.substr(prefix.size()) : std::string();
            std::error_code ec;
            if (file.empty() || !stdfs::exists(assets.path / file, ec)) return fail(false, "HTTP 404 for " + rq.url);
            stdfs::create_directories(fs::path_from_utf8(rq.destination).parent_path(), ec);
            stdfs::copy_file(assets.path / file, fs::path_from_utf8(rq.destination), stdfs::copy_options::overwrite_existing, ec);
            return r;
        };
        return c;
    }
};

// Polls like the UI does, until `done` or about 20 s (a deterministic count of 5 ms looks, not a clock).
template <class F>
bool poll_until(ExamplesBrowser& b, F done) {
    for (int i = 0; i < 4000; ++i) {
        b.poll();
        if (done()) return true;
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    return false;
}

}  // namespace

TEST_CASE("examples browser: size and read-first words") {
    CHECK(example_size_text(0).empty());
    CHECK(example_size_text(812) == "812 B");
    CHECK(example_size_text(34 * 1024) == "34 KB");
    CHECK(example_size_text(26ull * 1024 * 1024 + 400 * 1024) == "26.4 MB");
    CHECK(example_size_text(1288490189ull) == "1.2 GB");
    CHECK(example_read_first_text({}).empty());
    CHECK(example_read_first_text({"docs/SCRIPTING.md", "docs/ANIMATION.md"}) == "SCRIPTING, ANIMATION");
    CHECK(example_read_first_text({"README.md"}) == "README");
}

TEST_CASE("examples browser: the folder proposed for an example and the target's problems") {
    TempDir dir;
    CHECK(example_folder_name("block-push", dir.path) == "block-push");
    put(dir.path / "block-push" / "factoria.json", "{}");
    CHECK(example_folder_name("block-push", dir.path) == "block-push-2");
    put(dir.path / "block-push-2" / "x", "x");
    CHECK(example_folder_name("block-push", dir.path) == "block-push-3");
    stdfs::create_directories(dir.path / "empty-one");  // an empty folder can be used
    CHECK(example_folder_name("empty-one", dir.path) == "empty-one");
    put(dir.path / "a-file", "x");  // a file is in the way
    CHECK(example_folder_name("a-file", dir.path) == "a-file-2");

    CHECK(example_target_problem("/tmp/x", "my-game").empty());
    CHECK_FALSE(example_target_problem("/tmp/x", "").empty());
    CHECK_FALSE(example_target_problem("", "my-game").empty());
    CHECK_FALSE(example_target_problem("/tmp/x", "a/b").empty());
    CHECK_FALSE(example_target_problem("/tmp/x", "..").empty());
    CHECK_FALSE(example_target_problem("/tmp/x", "a:b").empty());
}

TEST_CASE("examples browser: show lists, then the saved copy is shown at once") {
    Release rel;
    {
        ExamplesBrowser b;
        CHECK_FALSE(b.list().has_value());
        b.show(rel.ctx());
        CHECK(b.visited());
        CHECK(b.loading());
        CHECK_FALSE(b.list().has_value());  // nothing saved yet
        REQUIRE(poll_until(b, [&] { return !b.loading(); }));
        REQUIRE(b.list().has_value());
        CHECK(b.list()->manifest.examples.size() == 2);
        CHECK_FALSE(b.list()->stale);
        CHECK_FALSE(b.shown_from_cache());
        CHECK(b.error().empty());
    }
    SUBCASE("a second visit shows the saved copy before the refresh answers") {
        rel.hold = true;
        ExamplesBrowser b;
        b.show(rel.ctx());
        CHECK(b.loading());
        REQUIRE(b.list().has_value());
        CHECK(b.shown_from_cache());
        CHECK(b.list()->manifest.examples.size() == 2);
        rel.offline = true;
        rel.hold = false;
        REQUIRE(poll_until(b, [&] { return !b.loading(); }));
        REQUIRE(b.list().has_value());
        CHECK(b.list()->stale);  // the download failed: the saved copy with the reason
        CHECK_FALSE(b.list()->staleReason.empty());
        CHECK_FALSE(b.shown_from_cache());
        rel.offline = false;
        b.refresh(rel.ctx());
        REQUIRE(poll_until(b, [&] { return !b.loading(); }));
        CHECK_FALSE(b.list()->stale);
    }
}

TEST_CASE("examples browser: offline with no copy is an error with a hint; close ignores a refresh in flight") {
    Release rel;
    rel.offline = true;
    ExamplesBrowser b;
    b.show(rel.ctx());
    REQUIRE(poll_until(b, [&] { return !b.loading(); }));
    CHECK_FALSE(b.list().has_value());
    CHECK_FALSE(b.error().empty());
    CHECK_FALSE(b.hint().empty());

    SUBCASE("close during a refresh: the answer never shows") {
        rel.offline = false;
        rel.hold = true;
        b.refresh(rel.ctx());
        CHECK(b.loading());
        CHECK(b.error().empty());
        b.close();
        CHECK_FALSE(b.loading());
        CHECK_FALSE(b.visited());
        rel.hold = false;
        for (int i = 0; i < 40; ++i) {  // the cancelled job is joined and dropped, whatever it brought
            b.poll();
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        CHECK_FALSE(b.list().has_value());
        CHECK(b.error().empty());
    }
    SUBCASE("a refresh replaced by another: only the last one counts") {
        rel.offline = false;
        rel.hold = true;
        b.refresh(rel.ctx());
        b.refresh(rel.ctx());
        rel.hold = false;
        REQUIRE(poll_until(b, [&] { return !b.loading(); }));
        REQUIRE(b.list().has_value());
        CHECK(b.list()->manifest.examples.size() == 2);
        CHECK(b.error().empty());
    }
}

TEST_CASE("examples browser: create makes the project, reports an error, cancels, and ignores a closed window") {
    Release rel;
    TempDir out;
    const std::string target = fs::path_to_utf8(out.path / "alpha");
    ExamplesBrowser b;
    ScaffoldOptions so;
    so.name = "alpha";

    SUBCASE("success") {
        REQUIRE(b.create(rel.ctx(), "alpha", target, so));
        CHECK(b.creating());
        CHECK_FALSE(b.create(rel.ctx(), "beta", fs::path_to_utf8(out.path / "beta"), so));  // one at a time
        REQUIRE(poll_until(b, [&] { return !b.creating(); }));
        auto done = b.take_created();
        REQUIRE(done.has_value());
        CHECK(done->ok);
        CHECK(stdfs::exists(out.path / "alpha" / "factoria.json"));
        CHECK_FALSE(b.take_created().has_value());  // once
    }
    SUBCASE("a name that is not an example is an error that says so") {
        REQUIRE(b.create(rel.ctx(), "alpa", target, so));
        REQUIRE(poll_until(b, [&] { return !b.creating(); }));
        auto done = b.take_created();
        REQUIRE(done.has_value());
        CHECK_FALSE(done->ok);
        CHECK_FALSE(done->cancelled);
        CHECK(done->error.find("alpha") != std::string::npos);  // did you mean
        CHECK_FALSE(stdfs::exists(out.path / "alpha"));
    }
    SUBCASE("Cancel stops the download and leaves nothing") {
        rel.hold = true;
        REQUIRE(b.create(rel.ctx(), "alpha", target, so));
        std::this_thread::sleep_for(std::chrono::milliseconds(30));
        b.cancel_create();
        CHECK(b.cancelling());
        REQUIRE(poll_until(b, [&] { return !b.creating(); }));
        auto done = b.take_created();
        REQUIRE(done.has_value());
        CHECK(done->cancelled);
        CHECK_FALSE(done->ok);
        CHECK_FALSE(stdfs::exists(out.path / "alpha"));
    }
    SUBCASE("closing the window cancels the create and its result is ignored") {
        rel.hold = true;
        REQUIRE(b.create(rel.ctx(), "alpha", target, so));
        b.close();
        CHECK_FALSE(b.creating());
        rel.hold = false;
        for (int i = 0; i < 40; ++i) {
            b.poll();
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        CHECK_FALSE(b.take_created().has_value());
        CHECK_FALSE(stdfs::exists(out.path / "alpha"));
    }
}
