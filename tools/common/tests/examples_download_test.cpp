// Getting an example game (fa/tooling/examples.h, "Getting an example"): the list of a release, the download of a zip, its safe
// unpacking and the project made from it. Nothing touches the network: SetupContext::download is a fake that serves the files of a
// folder the test packed with package_examples.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <map>
#include <set>

#include "export_zip.h"
#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/tooling/examples.h"
#include "fa/tooling/tooling.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
using fa::testing::read_all;
using fa::testing::TempDir;
using fa::testing::write_all;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kVersion = "0.30.0";

// A release on disk (the assets of v0.30.0: <name>.zip and examples-manifest.json) and a SetupContext whose downloads read from it.
struct Release {
    TempDir assets, home;
    int manifestDownloads = 0, zipDownloads = 0;
    bool offline = false;
    std::set<std::string> hidden;  // assets the "server" answers 404 for

    SetupContext ctx() {
        SetupContext c;
        c.home = home.str();
        c.engineVersion = kVersion;
        c.download = [this](const DownloadRequest& rq) {
            DownloadResult r;
            const std::string prefix = examples_asset_url(kVersion, "x.zip").substr(0, examples_asset_url(kVersion, "x.zip").size() - 5);
            const std::string file = rq.url.rfind(prefix, 0) == 0 ? rq.url.substr(prefix.size()) : "";
            auto fail = [&](int status, const std::string& message) {
                r.ok = false;
                r.httpStatus = status;
                r.error = make_error(message, "Check the connection.");
                return r;
            };
            if (offline) return fail(0, "Cannot download " + rq.what + ": cannot resolve the address github.com.");
            if (file.empty() || hidden.count(file) || !stdfs::exists(assets.path / file)) return fail(404, "HTTP 404 for " + rq.url);
            (file == kExamplesManifestFile ? manifestDownloads : zipDownloads)++;
            const stdfs::path dest = fs::path_from_utf8(rq.destination);
            std::error_code ec;
            stdfs::create_directories(dest.parent_path(), ec);
            stdfs::copy_file(assets.path / file, dest, stdfs::copy_options::overwrite_existing, ec);
            if (ec) return fail(0, "copy failed: " + ec.message());
            return r;
        };
        return c;
    }
    // A release from the source manifest in `src` (examples folders).
    void pack(const stdfs::path& src, const std::string& version = kVersion) {
        auto m = package_examples(src, assets.path, version);
        REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    }
    // A release with ONE example called `name` whose zip is the file `zip` (as it is: the manifest says its size and hash).
    void publish_zip(const std::string& name, const stdfs::path& zip) {
        const std::string bytes = read_all(zip);
        REQUIRE_FALSE(bytes.empty());
        stdfs::create_directories(assets.path);
        write_all(assets.path / (name + ".zip"), bytes);
        Json m = Json::object({{"format", kExamplesManifestFormat}, {"engineVersion", kVersion},
                               {"examples", Json::array({Json::object({{"name", name}, {"title", "Evil"}, {"shows", "A test."},
                                                                       {"readFirst", Json::array()}, {"file", name + ".zip"},
                                                                       {"size", bytes.size()}, {"sha256", sha256_hex(bytes)}})})}});
        write_all(assets.path / kExamplesManifestFile, m.dump(2));
    }
};

void make_source(const TempDir& d) {
    write_all(d.path / "examples.json", R"({"format":"factoria.examples-source/1","examples":[
      {"name":"alpha","title":"Alpha","shows":"The first.","readFirst":["docs/SCRIPTING.md"]},
      {"name":"beta","title":"Beta","shows":"The second.","readFirst":[]}]})");
    for (const char* n : {"alpha", "beta"}) {
        const stdfs::path p = d.path / n;
        write_all(p / "factoria.json", std::string(R"({"format":"factoria.project/1","id":"com.test.)") + n + R"(","name":")" + n + R"("})");
        write_all(p / "scripts/main.js", std::string("// ") + n + "\n");
        write_all(p / "assets/pic.bin", std::string("\x89PNG\0\1\2\3", 8));
        write_all(p / ".factoria/cache/x.bin", "cache");
    }
}

// A zip made of `entries` (name, data), stored, in that order.
stdfs::path make_zip(const TempDir& d, const std::string& file, const std::vector<std::pair<std::string, std::string>>& entries,
                     bool deflate = false) {
    const stdfs::path zip = d.path / file;
    export_detail::ZipWriter w(zip);
    for (const auto& [name, data] : entries) REQUIRE(w.add(name, data, deflate).ok());
    REQUIRE(w.finish().ok());
    return zip;
}

std::vector<std::string> names_in(const stdfs::path& dir) {
    std::vector<std::string> out;
    std::error_code ec;
    if (!stdfs::exists(dir, ec)) return out;
    for (const auto& e : stdfs::directory_iterator(dir, ec)) out.push_back(e.path().filename().string());
    std::sort(out.begin(), out.end());
    return out;
}

std::string msg(const Error& e) { return e.message + " | " + e.hint; }

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

// Puts a context in place for the commands and takes it away.
struct ScopedExamplesContext {
    explicit ScopedExamplesContext(const SetupContext& c) { set_examples_context(c); }
    ~ScopedExamplesContext() { set_examples_context(std::nullopt); }
};

}  // namespace

TEST_CASE("examples download: listing the examples of a release") {
    TempDir src;
    make_source(src);
    Release rel;
    rel.pack(src.path);

    SUBCASE("online: the list is fetched, kept, and says what each example is") {
        auto l = list_examples(rel.ctx());
        REQUIRE_MESSAGE(l.ok(), (l.ok() ? std::string() : msg(l.error())));
        CHECK_FALSE(l->stale);
        REQUIRE(l->manifest.examples.size() == 2);
        CHECK(l->manifest.engineVersion == kVersion);
        CHECK(l->manifest.examples[0].name == "alpha");
        CHECK(l->downloaded.empty());
        CHECK(stdfs::exists(examples_cache_dir(rel.ctx()) / kExamplesManifestFile));
        CHECK(has(fs::path_to_utf8(examples_cache_dir(rel.ctx())), std::string("cache/examples/") + kVersion));
        // The next call: the same list; no leftovers of the download in the cache folder.
        REQUIRE(list_examples(rel.ctx()).ok());
        CHECK(names_in(examples_cache_dir(rel.ctx())) == std::vector<std::string>{kExamplesManifestFile});

        const Json j = l->to_json();
        CHECK(j["engineVersion"] == kVersion);
        CHECK(j["source"] == "network");
        CHECK(j["stale"] == false);
        CHECK_FALSE(j.contains("staleReason"));
        REQUIRE(j["examples"].size() == 2);
        const Json& a = j["examples"][0];
        CHECK(a["name"] == "alpha");
        CHECK(a["title"] == "Alpha");
        CHECK(a["shows"] == "The first.");
        CHECK(a["readFirst"] == Json::array({"docs/SCRIPTING.md"}));
        CHECK(a["size"].get<std::uint64_t>() == stdfs::file_size(rel.assets.path / "alpha.zip"));
        CHECK(a["downloaded"] == false);
        CHECK_FALSE(a.contains("sha256"));
    }
    SUBCASE("offline with a copy: the copy, marked as not up to date") {
        REQUIRE(list_examples(rel.ctx()).ok());
        rel.offline = true;
        auto l = list_examples(rel.ctx());
        REQUIRE_MESSAGE(l.ok(), (l.ok() ? std::string() : msg(l.error())));
        CHECK(l->stale);
        CHECK(has(l->staleReason, "cannot resolve"));
        CHECK(l->manifest.examples.size() == 2);
        const Json j = l->to_json();
        CHECK(j["stale"] == true);
        CHECK(j["source"] == "cache");
        CHECK(has(j["staleReason"].get<std::string>(), "cannot resolve"));
        // cached_examples never touches the network.
        const int before = rel.manifestDownloads;
        rel.offline = false;
        auto c = cached_examples(rel.ctx());
        REQUIRE(c.has_value());
        CHECK(c->manifest.examples.size() == 2);
        CHECK(rel.manifestDownloads == before);
    }
    SUBCASE("offline without a copy: an Error that says what is missing and how to fix it") {
        rel.offline = true;
        auto l = list_examples(rel.ctx());
        REQUIRE_FALSE(l.ok());
        CHECK(has(l.error().message, "no saved copy"));
        CHECK(has(l.error().message, "base download"));
        CHECK(has(l.error().message, "carries no example"));
        CHECK(has(l.error().hint, "Connect to the internet"));
        CHECK(has(l.error().hint, "cache"));
        CHECK_FALSE(cached_examples(rel.ctx()).has_value());
        CHECK_FALSE(stdfs::exists(examples_cache_dir(rel.ctx()) / kExamplesManifestFile));
    }
    SUBCASE("a release without the manifest (404)") {
        rel.hidden.insert(kExamplesManifestFile);
        auto l = list_examples(rel.ctx());
        REQUIRE_FALSE(l.ok());
        CHECK(has(l.error().message, "404"));
        CHECK(has(l.error().message, "no saved copy"));
        CHECK(has(l.error().message, "base download"));
    }
    SUBCASE("a manifest of another version is not used, and does not replace the copy") {
        REQUIRE(list_examples(rel.ctx()).ok());
        const std::string good = read_all(examples_cache_dir(rel.ctx()) / kExamplesManifestFile);
        Json m = Json::parse(read_all(rel.assets.path / kExamplesManifestFile));
        m["engineVersion"] = "0.29.0";
        write_all(rel.assets.path / kExamplesManifestFile, m.dump());
        auto l = list_examples(rel.ctx());
        REQUIRE(l.ok());
        CHECK(l->stale);
        CHECK(has(l->staleReason, "0.29.0"));
        CHECK(read_all(examples_cache_dir(rel.ctx()) / kExamplesManifestFile) == good);
    }
    SUBCASE("a manifest that does not parse falls back to the copy and names the pointer") {
        REQUIRE(list_examples(rel.ctx()).ok());
        write_all(rel.assets.path / kExamplesManifestFile, R"({"format":"factoria.examples/2","engineVersion":"0.30.0","examples":[]})");
        auto l = list_examples(rel.ctx());
        REQUIRE(l.ok());
        CHECK(l->stale);
        CHECK(has(l->staleReason, "#/format"));
        CHECK(has(l->staleReason, "Update FactorIA"));
    }
    SUBCASE("the cache of another version is not offered") {
        REQUIRE(list_examples(rel.ctx()).ok());
        SetupContext other = rel.ctx();
        other.engineVersion = "0.31.0";
        CHECK_FALSE(cached_examples(other).has_value());
    }
    SUBCASE("a cancelled call is an Error, never the copy") {
        REQUIRE(list_examples(rel.ctx()).ok());
        rel.offline = true;
        CancelFlag cancel{true};
        SetupContext c = rel.ctx();
        c.cancel = &cancel;
        c.download = [](const DownloadRequest&) {
            DownloadResult r;
            r.ok = false;
            r.cancelled = true;
            r.error = make_error("cancelled", "");
            return r;
        };
        auto l = list_examples(c);
        REQUIRE_FALSE(l.ok());
        CHECK(has(l.error().message, "cancelled"));
    }
    SUBCASE("a version that no release has") {
        SetupContext c = rel.ctx();
        c.engineVersion = "0.30/../x";
        REQUIRE_FALSE(list_examples(c).ok());
    }
}

TEST_CASE("examples download: creating a project from an example") {
    TempDir src, work;
    make_source(src);
    Release rel;
    rel.pack(src.path);
    const stdfs::path dir = work.path / "my-game";

    SUBCASE("downloads, verifies and creates; the same example again downloads nothing") {
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : msg(r.error())));
        CHECK(r->dir == fs::path_to_utf8(dir));
        CHECK(r->files == std::vector<std::string>{"assets/pic.bin", "factoria.json", "scripts/main.js"});
        CHECK(read_all(dir / "scripts/main.js") == "// alpha\n");
        CHECK(read_all(dir / "assets/pic.bin") == std::string("\x89PNG\0\1\2\3", 8));
        CHECK_FALSE(stdfs::exists(dir / ".factoria"));
        CHECK(rel.zipDownloads == 1);
        // No leftovers beside the project, and the verified zip is in the cache.
        CHECK(names_in(work.path) == std::vector<std::string>{"my-game"});
        CHECK(names_in(examples_cache_dir(rel.ctx())) == std::vector<std::string>{"alpha.zip", kExamplesManifestFile});
        auto l = list_examples(rel.ctx());
        REQUIRE(l.ok());
        CHECK(l->downloaded == std::vector<std::string>{"alpha"});

        auto again = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(work.path / "second"));
        REQUIRE_MESSAGE(again.ok(), (again.ok() ? std::string() : msg(again.error())));
        CHECK(rel.zipDownloads == 1);
        // ... also with no network at all.
        rel.offline = true;
        auto offline = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(work.path / "third"));
        REQUIRE_MESSAGE(offline.ok(), (offline.ok() ? std::string() : msg(offline.error())));
        CHECK(read_all(work.path / "third/scripts/main.js") == "// alpha\n");
        // A damaged cached zip is downloaded again.
        rel.offline = false;
        write_all(examples_cache_dir(rel.ctx()) / "alpha.zip", "damaged");
        REQUIRE(create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(work.path / "fourth")).ok());
        CHECK(rel.zipDownloads == 2);
        CHECK(read_all(examples_cache_dir(rel.ctx()) / "alpha.zip") == read_all(rel.assets.path / "alpha.zip"));
    }
    SUBCASE("name and id replace the example's own") {
        ScaffoldOptions o;
        o.name = "My Alpha";
        o.id = "com.me.alpha";
        REQUIRE(create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir), o).ok());
        auto j = Json::parse(read_all(dir / "factoria.json"));
        CHECK(j["name"] == "My Alpha");
        CHECK(j["id"] == "com.me.alpha");
        CHECK(j["format"] == "factoria.project/1");
        ScaffoldOptions bad;
        bad.id = "not an id";
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(work.path / "other"), bad);
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "not an id"));
        CHECK_FALSE(stdfs::exists(work.path / "other"));
    }
    SUBCASE("a name that does not exist gets did you mean, and nothing is created") {
        auto r = create_example_project(rel.ctx(), "alpa", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "alpa"));
        CHECK(has(r.error().message, "alpha"));
        CHECK(has(r.error().hint, "project.examples"));
        CHECK(rel.zipDownloads == 0);
        CHECK_FALSE(stdfs::exists(dir));
    }
    SUBCASE("a target that is not empty fails before anything is downloaded") {
        write_all(dir / "mine.txt", "mine");
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "is not empty"));
        CHECK(rel.manifestDownloads == 0);
        CHECK(rel.zipDownloads == 0);
        CHECK(read_all(dir / "mine.txt") == "mine");
        write_all(work.path / "afile", "x");
        CHECK_FALSE(create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(work.path / "afile")).ok());
    }
    SUBCASE("an empty folder that exists is used") {
        stdfs::create_directories(dir);
        auto r = create_example_project(rel.ctx(), "beta", fs::path_to_utf8(dir));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : msg(r.error())));
        CHECK(read_all(dir / "scripts/main.js") == "// beta\n");
        CHECK(names_in(work.path) == std::vector<std::string>{"my-game"});
    }
    SUBCASE("no network and no copy: nothing is created and the Error teaches") {
        rel.offline = true;
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "base download"));
        CHECK_FALSE(stdfs::exists(dir));
    }
    SUBCASE("the list is cached but the zip is not and the network is gone") {
        REQUIRE(list_examples(rel.ctx()).ok());
        rel.offline = true;
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "cannot resolve"));
        CHECK_FALSE(stdfs::exists(dir));
        CHECK(names_in(work.path).empty());
        CHECK(names_in(examples_cache_dir(rel.ctx())) == std::vector<std::string>{kExamplesManifestFile});
    }
    SUBCASE("a zip whose hash is not the manifest's is never opened") {
        std::string bytes = read_all(rel.assets.path / "alpha.zip");
        bytes[bytes.size() / 2] ^= 0x55;  // same size, other bytes
        write_all(rel.assets.path / "alpha.zip", bytes);
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "does not match"));
        CHECK(has(r.error().message, "SHA-256"));
        CHECK(has(r.error().hint, "Nothing was unpacked"));
        CHECK_FALSE(stdfs::exists(dir));
        CHECK(names_in(work.path).empty());
        CHECK(names_in(examples_cache_dir(rel.ctx())) == std::vector<std::string>{kExamplesManifestFile});  // not kept
    }
    SUBCASE("a zip of another size") {
        write_all(rel.assets.path / "alpha.zip", read_all(rel.assets.path / "alpha.zip") + "x");
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "bytes"));
        CHECK_FALSE(stdfs::exists(dir));
    }
    SUBCASE("a zip that is missing from the release") {
        rel.hidden.insert("alpha.zip");
        auto r = create_example_project(rel.ctx(), "alpha", fs::path_to_utf8(dir));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "404"));
        CHECK_FALSE(stdfs::exists(dir));
    }
    SUBCASE("a relative target is made absolute") {
        const stdfs::path old = stdfs::current_path();
        stdfs::current_path(work.path);
        auto r = create_example_project(rel.ctx(), "alpha", "rel-game");
        stdfs::current_path(old);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : msg(r.error())));
        CHECK(stdfs::exists(work.path / "rel-game/factoria.json"));
    }
}

TEST_CASE("examples download: the real block-push example goes through the same pipeline") {
    TempDir out, work, home;
    const stdfs::path root = stdfs::path(FA_REPO_ROOT) / "examples";
    auto m = package_examples(root, out.path, kVersion, {"block-push"});
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    Release rel;
    stdfs::copy(out.path, rel.assets.path, stdfs::copy_options::recursive | stdfs::copy_options::overwrite_existing);
    auto r = create_example_project(rel.ctx(), "block-push", fs::path_to_utf8(work.path / "bp"));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : msg(r.error())));
    CHECK(read_all(work.path / "bp/factoria.json") == read_all(root / "block-push/factoria.json"));
    CHECK(read_all(work.path / "bp/README.md") == read_all(root / "block-push/README.md"));
    CHECK_FALSE(stdfs::exists(work.path / "bp/.factoria"));
    auto expected = example_zip_files(root / "block-push");
    REQUIRE(expected.ok());
    CHECK(r->files == *expected);
}

TEST_CASE("examples download: a zip with an unsafe entry is refused before anything is written") {
    TempDir work;
    const std::string project = R"({"format":"factoria.project/1"})";
    struct Bad {
        std::vector<std::pair<std::string, std::string>> entries;
        const char* reason;
    };
    const std::vector<Bad> bad = {
        {{{"factoria.json", project}, {"../evil.txt", "x"}}, "goes up"},
        {{{"factoria.json", project}, {"a/../../evil.txt", "x"}}, "goes up"},
        {{{"factoria.json", project}, {"/etc/evil.txt", "x"}}, "absolute"},
        {{{"factoria.json", project}, {"C:/evil.txt", "x"}}, "':'"},
        {{{"factoria.json", project}, {"C:\\evil.txt", "x"}}, "backslash"},
        {{{"factoria.json", project}, {"a\\b.txt", "x"}}, "backslash"},
        {{{"factoria.json", project}, {"\\\\server\\share\\x", "x"}}, "backslash"},
        {{{"factoria.json", project}, {"data.txt:stream", "x"}}, "':'"},
        {{{"factoria.json", project}, {"a//b.txt", "x"}}, "empty part"},
        {{{"factoria.json", project}, {"./b.txt", "x"}}, "\".\" part"},
        {{{"factoria.json", project}, {"dir./b.txt", "x"}}, "dot or a space"},
        {{{"factoria.json", project}, {"nul.txt", "x"}}, "Windows device"},
        {{{"factoria.json", project}, {"a/COM1", "x"}}, "Windows device"},
        {{{"factoria.json", project}, {"what?.txt", "x"}}, "Windows does not allow"},
        {{{"factoria.json", project}, {"tab\there.txt", "x"}}, "control character"},
        {{{"factoria.json", project}, {"bad\xff.txt", "x"}}, "UTF-8"},
        {{{"factoria.json", project}, {"Readme.md", "x"}, {"README.md", "y"}}, "differs only in capitals"},
        {{{"factoria.json", project}, {"scripts/a.js", "x"}, {"Scripts/B.js", "y"}, {"SCRIPTS/a.JS", "z"}}, "differs only in capitals"},
        {{{"factoria.json", project}, {"x.txt", "x"}, {"x.txt", "y"}}, "twice"},
        {{{"factoria.json", project}, {"a", "x"}, {"A/b.txt", "y"}}, "also a file"},
        {{{"factoria.json", project}, {"a/b.txt", "x"}, {"A", "y"}}, "also a folder"},
        {{{"scripts/main.js", "x"}}, "no factoria.json"},
        {{{"project/factoria.json", project}}, "no factoria.json"},
    };
    int n = 0;
    for (const Bad& b : bad) {
        CAPTURE(b.entries.back().first);
        const stdfs::path zip = make_zip(work, "bad" + std::to_string(n) + ".zip", b.entries);
        const stdfs::path dest = work.path / ("out" + std::to_string(n++));
        auto r = extract_example_zip(zip, dest);
        REQUIRE_FALSE(r.ok());
        INFO(msg(r.error()));
        CHECK(has(r.error().message + r.error().hint, b.reason));
        CHECK_FALSE(r.error().hint.empty());
        CHECK_FALSE(stdfs::exists(dest));  // nothing was written: the names are all checked first
    }
    // Outside the folder: nothing appeared next to it either.
    for (const std::string& f : names_in(work.path)) CHECK(f.rfind("bad", 0) == 0);

    SUBCASE("the good one, with folders and deflated entries") {
        const stdfs::path zip = make_zip(work, "ok.zip",
                                         {{"factoria.json", project}, {"scripts/", ""}, {"scripts/a.js", std::string(2000, 'a')},
                                          {"Scripts2/b.js", "b"}, {"empty.txt", ""}},
                                         true);
        auto r = extract_example_zip(zip, work.path / "ok");
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : msg(r.error())));
        CHECK(*r == std::vector<std::string>{"Scripts2/b.js", "empty.txt", "factoria.json", "scripts/a.js"});
        CHECK(read_all(work.path / "ok/scripts/a.js") == std::string(2000, 'a'));
        CHECK(stdfs::exists(work.path / "ok/empty.txt"));
    }
    SUBCASE("limits") {
        const stdfs::path zip = make_zip(work, "lim.zip", {{"factoria.json", project}, {"a.txt", std::string(50, 'a')}, {"b.txt", "0123456789"}});
        ExampleExtractLimits few;
        few.maxEntries = 2;
        CHECK(has(extract_example_zip(zip, work.path / "l1", few).error().message, "3 entries"));
        ExampleExtractLimits small;
        small.maxEntryBytes = 40;
        CHECK(has(extract_example_zip(zip, work.path / "l2", small).error().message, "\"a.txt\""));
        ExampleExtractLimits total;
        total.maxTotalBytes = 60;
        CHECK(has(extract_example_zip(zip, work.path / "l3", total).error().message, "more than 60 bytes"));
        CHECK_FALSE(stdfs::exists(work.path / "l1"));
        CHECK_FALSE(stdfs::exists(work.path / "l2"));
        CHECK_FALSE(stdfs::exists(work.path / "l3"));
        // A zip whose entry inflates to more than its directory says does not grow the buffer.
        CHECK(extract_example_zip(zip, work.path / "l4").ok());
    }
    SUBCASE("a file that is not a zip") {
        write_all(work.path / "no.zip", "not a zip at all, but long enough to have a tail to look in......");
        auto r = extract_example_zip(work.path / "no.zip", work.path / "x");
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "not a zip"));
    }
}

TEST_CASE("examples download: an evil zip the release vouches for creates nothing") {
    TempDir work;
    const std::string project = R"({"format":"factoria.project/1"})";

    SUBCASE("entries that leave the folder, through the whole pipeline") {
        Release rel;
        rel.publish_zip("evil", make_zip(work, "evil-src.zip", {{"factoria.json", project}, {"../evil.txt", "x"}}));
        auto r = create_example_project(rel.ctx(), "evil", fs::path_to_utf8(work.path / "game"));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "../evil.txt"));
        CHECK(has(r.error().hint, "Nothing was unpacked"));
        CHECK_FALSE(stdfs::exists(work.path / "game"));
        CHECK_FALSE(stdfs::exists(work.path / "evil.txt"));
        CHECK(names_in(examples_cache_dir(rel.ctx())) == std::vector<std::string>{kExamplesManifestFile});
    }
    SUBCASE("a failure half way (a damaged entry) leaves no folder and no staging folder") {
        const std::string payload(64, 'Z');
        const stdfs::path src = make_zip(work, "half-src.zip", {{"factoria.json", project}, {"a.txt", "first"}, {"z.bin", payload}});
        std::string bytes = read_all(src);
        const auto at = bytes.find(payload);
        REQUIRE(at != std::string::npos);
        bytes[at + 5] = 'Y';  // the CRC-32 of the last entry no longer matches
        write_all(src, bytes);
        Release rel;
        rel.publish_zip("half", src);
        const stdfs::path game = work.path / "sub" / "game";
        auto r = create_example_project(rel.ctx(), "half", fs::path_to_utf8(game));
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "CRC-32"));
        CHECK_FALSE(stdfs::exists(game));
        CHECK(names_in(work.path / "sub").empty());  // the hidden staging folder is gone
        CHECK(names_in(examples_cache_dir(rel.ctx())) == std::vector<std::string>{kExamplesManifestFile});
        // An empty folder the caller gave stays an empty folder.
        stdfs::create_directories(game);
        REQUIRE_FALSE(create_example_project(rel.ctx(), "half", fs::path_to_utf8(game)).ok());
        CHECK(stdfs::is_directory(game));
        CHECK(stdfs::is_empty(game));
        CHECK(names_in(work.path / "sub") == std::vector<std::string>{"game"});
    }
}

TEST_CASE("examples download: the commands project.examples and project.create {example}") {
    TempDir src, work, projectDir;
    make_source(src);
    Release rel;
    rel.pack(src.path);
    ScopedExamplesContext scoped(rel.ctx());

    CommandRegistry reg;
    register_tooling_commands(reg, projectDir.str());
    REQUIRE(reg.has("project.examples"));
    const CommandInfo* info = reg.info("project.examples");
    CHECK_FALSE(info->capabilities.has(Capability::WriteProject));
    CHECK(info->capabilities == CapabilitySet{Capability::Read, Capability::Network});
    CHECK_FALSE(info->description.empty());

    auto r = reg.call("project.examples", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["examples"].size() == 2);
    CHECK(r.result["stale"] == false);
    CHECK(r.result["examples"][1]["name"] == "beta");

    SUBCASE("a caller without the network capability (an agent granted less) cannot list") {
        CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
        auto denied = reg.call("project.examples", Json::object());
        REQUIRE_FALSE(denied.ok);
        CHECK(denied.error["code"] == "capability_denied");
    }
    SUBCASE("offline with the copy of the last call") {
        rel.offline = true;
        auto off = reg.call("project.examples", Json::object());
        REQUIRE_MESSAGE(off.ok, off.error.dump());
        CHECK(off.result["stale"] == true);
        CHECK(off.result["source"] == "cache");
        CHECK_FALSE(off.result["staleReason"].get<std::string>().empty());
    }
    SUBCASE("offline without a copy") {
        stdfs::remove_all(examples_cache_dir(rel.ctx()));
        rel.offline = true;
        auto off = reg.call("project.examples", Json::object());
        REQUIRE_FALSE(off.ok);
        CHECK(has(off.error["message"].get<std::string>(), "base download"));
        CHECK_FALSE(off.error["hint"].get<std::string>().empty());
    }
    SUBCASE("create_example_for_command") {
        const std::string dir = fs::path_to_utf8(work.path / "g");
        auto made = [&](const Json& args) { return create_example_for_command(args, dir); };
        Json ok = made(Json::object({{"example", "beta"}, {"dir", dir}}));
        CHECK(ok["example"] == "beta");
        CHECK(ok["dir"] == dir);
        CHECK_FALSE(ok.contains("template"));
        CHECK(ok["files"].size() == 3);
        CHECK(stdfs::exists(work.path / "g/factoria.json"));
        // Not together with a template, and not with a name that is not a string.
        try {
            made(Json::object({{"example", "beta"}, {"template", "2d-empty"}, {"dir", dir}}));
            FAIL("expected a CommandError");
        } catch (const CommandError& e) {
            CHECK(std::string(e.what()).find("/template") != std::string::npos);
            CHECK_FALSE(e.hint.empty());
        }
        CHECK_THROWS_AS(made(Json::object({{"example", 3}, {"dir", dir}})), CommandError);
        // A caller without the network capability.
        CommandCapabilityScope noNet(CapabilitySet{Capability::Read, Capability::WriteProject});
        try {
            create_example_for_command(Json::object({{"example", "alpha"}, {"dir", dir + "2"}}), dir + "2");
            FAIL("expected a CommandError");
        } catch (const CommandError& e) {
            CHECK(e.code == "capability_denied");
        }
        CHECK_FALSE(stdfs::exists(work.path / "g2"));
    }
}
