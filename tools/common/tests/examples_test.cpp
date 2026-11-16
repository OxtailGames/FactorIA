// The example games a user can get (fa/tooling/examples.h): the source manifest examples/examples.json against the folders,
// the release manifest reader, the release URLs, the check of a download and the packaging of the zips.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <set>

#include "export_zip.h"
#include "fa/core/command.h"
#include "fa/core/hash.h"
#include "fa/tooling/examples.h"
#include "fa/tooling/setup_parse.h"
#include "fa/tooling/tooling.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
using fa::testing::read_all;
using fa::testing::TempDir;
using fa::testing::write_all;
namespace stdfs = std::filesystem;

namespace {

const std::string kSha = std::string(64, 'a');

std::string manifest_text(const std::string& format = kExamplesManifestFormat, const std::string& extra = "") {
    return R"({"format":")" + format + R"(","engineVersion":"0.30.0","examples":[
      {"name":"block-push","title":"Block Push","shows":"A puzzle.","readFirst":["docs/SCRIPTING.md"],
       "file":"block-push.zip","size":1234,"sha256":")" +
           kSha + R"("})" + extra + R"(]})";
}

// A tiny examples folder: two projects, one hidden folder and a few files that must stay out of a zip.
void make_examples(const TempDir& d) {
    write_all(d.path / "examples.json", R"({"format":"factoria.examples-source/1","examples":[
      {"name":"alpha","title":"Alpha","shows":"The first.","readFirst":["docs/SCRIPTING.md"]},
      {"name":"beta","title":"Beta","shows":"The second.","readFirst":[]}]})");
    for (const char* n : {"alpha", "beta"}) {
        const stdfs::path p = d.path / n;
        write_all(p / "factoria.json", std::string(R"({"format":"factoria.project/1","name":")") + n + R"("})");
        write_all(p / "scripts/main.js", "let a = 1;\n");
        write_all(p / "assets/pic.bin", std::string("\x89PNG\0\1\2\3", 8));
        write_all(p / ".factoria/cache/x.bin", "cache");
        write_all(p / ".git/config", "git");
        write_all(p / "node_modules/m/index.js", "m");
        write_all(p / "build/out.bin", "build");
        write_all(p / "scripts/build/keep.js", "a build/ folder below the top is part of the project");
        write_all(p / ".DS_Store", "x");
        write_all(p / "shot.actual.png", "x");
        for (const char* secret : {".env", "ai.local.json", "release.keystore", "upload.jks", "sign.p12", "tls.pem",
                                   "api.key", "desktop.ini", "x.fa-tmp"})
            write_all(p / secret, "secret");
        write_all(p / "scripts/.env", "secret below the top");
        write_all(p / "keystore.txt", "a name that only contains a left-out word stays");
        write_all(p / ".gitignore", ".factoria/\n");
    }
}

}  // namespace

TEST_CASE("examples source: every folder of examples/ has an entry and every entry has a folder") {
    const stdfs::path root = stdfs::path(FA_REPO_ROOT) / "examples";
    auto text = read_all(root / kExamplesSourceFile);
    REQUIRE_MESSAGE(!text.empty(), "examples/examples.json is missing");
    auto src = parse_examples_source(text, "examples/examples.json");
    REQUIRE_MESSAGE(src.ok(), (src.ok() ? std::string() : src.error().to_string()));
    std::set<std::string> entries, folders;
    for (const ExampleInfo& e : *src) entries.insert(e.name);
    CHECK(entries.size() == src->size());
    std::error_code ec;
    for (const auto& d : stdfs::directory_iterator(root, ec))
        if (d.is_directory(ec)) folders.insert(d.path().filename().string());
    for (const std::string& f : folders)
        CHECK_MESSAGE(entries.count(f),
                      "examples/" << f << " has no entry in examples/examples.json (name, title, shows, readFirst)");
    for (const std::string& n : entries)
        CHECK_MESSAGE(folders.count(n),
                      "examples/examples.json lists \"" << n << "\", which is no folder of examples/");
    CHECK(entries.size() >= 11);
    for (const ExampleInfo& e : *src) {
        INFO("example " << e.name);
        CHECK(stdfs::exists(root / e.name / "factoria.json"));
        CHECK_FALSE(e.readFirst.empty());
        for (const std::string& doc : e.readFirst)
            CHECK_MESSAGE(stdfs::exists(stdfs::path(FA_REPO_ROOT) / doc), doc << " does not exist");
    }
    // The entries stay sorted by name, so a diff of the file shows what changed.
    std::vector<std::string> names;
    for (const ExampleInfo& e : *src) names.push_back(e.name);
    CHECK(std::is_sorted(names.begin(), names.end()));
}

TEST_CASE("examples manifest: parse, round trip and find") {
    auto m = parse_examples_manifest(manifest_text());
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    CHECK(m->engineVersion == "0.30.0");
    REQUIRE(m->examples.size() == 1);
    const ExampleInfo& e = m->examples[0];
    CHECK(e.name == "block-push");
    CHECK(e.title == "Block Push");
    CHECK(e.readFirst == std::vector<std::string>{"docs/SCRIPTING.md"});
    CHECK(e.file == "block-push.zip");
    CHECK(e.size == 1234);
    CHECK(e.sha256 == kSha);
    auto again = parse_examples_manifest(m->to_json().dump(2));
    REQUIRE(again.ok());
    CHECK(again->to_json() == m->to_json());
    CHECK(m->find("block-push").ok());
    auto missing = m->find("block-pusk");
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("block-push") != std::string::npos);  // did you mean
}

TEST_CASE("examples manifest: bad manifests say where and how to fix") {
    SUBCASE("not JSON") {
        auto m = parse_examples_manifest("{nope", "examples-manifest.json");
        REQUIRE_FALSE(m.ok());
        CHECK(m.error().message.find("examples-manifest.json") != std::string::npos);
    }
    SUBCASE("an unknown format version") {
        auto m = parse_examples_manifest(manifest_text("factoria.examples/2"));
        REQUIRE_FALSE(m.ok());
        CHECK(m.error().message.find("factoria.examples/2") != std::string::npos);
        CHECK(m.error().message.find("/format") != std::string::npos);
        CHECK(m.error().hint.find("Update FactorIA") != std::string::npos);
    }
    SUBCASE("another kind of file") {
        auto m = parse_examples_manifest(manifest_text("something/1"));
        REQUIRE_FALSE(m.ok());
        CHECK(m.error().message.find("something/1") != std::string::npos);
    }
    SUBCASE("a missing field names its pointer") {
        for (const char* field : {"name", "title", "shows", "readFirst", "file", "size", "sha256"}) {
            Json j = Json::parse(manifest_text());
            j["examples"][0].erase(field);
            auto m = parse_examples_manifest(j.dump());
            REQUIRE_FALSE(m.ok());
            CHECK_MESSAGE(m.error().message.find(std::string("/examples/0/") + field) != std::string::npos,
                          m.error().message);
            CHECK_FALSE(m.error().hint.empty());
        }
        Json j = Json::parse(manifest_text());
        j.erase("engineVersion");
        auto m = parse_examples_manifest(j.dump());
        REQUIRE_FALSE(m.ok());
        CHECK(m.error().message.find("/engineVersion") != std::string::npos);
        j = Json::parse(manifest_text());
        j.erase("examples");
        CHECK_FALSE(parse_examples_manifest(j.dump()).ok());
    }
    SUBCASE("wrong values") {
        auto bad = [](const char* field, const Json& value) {
            Json j = Json::parse(manifest_text());
            j["examples"][0][field] = value;
            auto m = parse_examples_manifest(j.dump());
            CHECK_MESSAGE(!m.ok(), field);
            if (!m.ok())
                CHECK_MESSAGE(m.error().message.find(std::string("/examples/0/") + field) != std::string::npos,
                              m.error().message);
        };
        bad("sha256", "xyz");
        bad("sha256", std::string(64, 'A'));  // upper case: the manifest writes lower case
        bad("size", 0);
        bad("size", "12");
        bad("file", "../x.zip");
        bad("file", "dir/x.zip");
        bad("file", "x.tar");
        bad("name", "Block Push");
        bad("title", "");
        bad("shows", "two\nlines");
        bad("readFirst", Json::array({"README.md"}));
        bad("readFirst", Json::array({"docs/../x.md"}));
    }
    SUBCASE("the same example twice") {
        Json j = Json::parse(manifest_text());
        j["examples"].push_back(j["examples"][0]);
        auto m = parse_examples_manifest(j.dump());
        REQUIRE_FALSE(m.ok());
        CHECK(m.error().message.find("/examples/1/name") != std::string::npos);
    }
}

TEST_CASE("examples source: file, size and sha256 belong to the release manifest") {
    auto ok = parse_examples_source(
        R"({"format":"factoria.examples-source/1","examples":[{"name":"a","title":"A","shows":"s","readFirst":[]}]})");
    REQUIRE(ok.ok());
    CHECK(ok->size() == 1);
    auto bad = parse_examples_source(
        R"({"format":"factoria.examples-source/1","examples":[{"name":"a","title":"A","shows":"s","readFirst":[],"sha256":"x"}]})");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/examples/0/sha256") != std::string::npos);
    // A release manifest is not a source manifest, and the other way round.
    CHECK_FALSE(parse_examples_source(manifest_text()).ok());
    CHECK_FALSE(parse_examples_manifest(R"({"format":"factoria.examples-source/1","examples":[]})").ok());
}

TEST_CASE("examples: the release URL pattern") {
    CHECK(examples_release_tag("0.30.0") == "v0.30.0");
    CHECK(examples_release_tag("v0.30.0") == "v0.30.0");
    CHECK(examples_asset_url("0.30.0", "block-push.zip") ==
          "https://github.com/OxtailGames/FactorIA/releases/download/v0.30.0/block-push.zip");
    CHECK(examples_manifest_url("0.30.0") ==
          "https://github.com/OxtailGames/FactorIA/releases/download/v0.30.0/examples-manifest.json");
    CHECK(examples_asset_url("v0.30.1", "a.zip") == examples_asset_url("0.30.1", "a.zip"));
    CHECK(is_trusted_download_url(examples_asset_url("0.30.0", "block-push.zip")));
    // Nothing that leaves the release.
    CHECK(examples_asset_url("0.30.0", "../x.zip").empty());
    CHECK(examples_asset_url("0.30.0", "a/b.zip").empty());
    CHECK(examples_asset_url("0.30.0", "a?b.zip").empty());
    CHECK(examples_asset_url("0.30.0", "").empty());
    CHECK(examples_asset_url("0.30.0/../x", "a.zip").empty());
    CHECK(examples_asset_url("", "a.zip").empty());
}

TEST_CASE("examples: a download is checked against the manifest") {
    const std::string bytes = "PK pretend zip bytes";
    ExampleInfo e;
    e.name = "block-push";
    e.file = "block-push.zip";
    e.size = bytes.size();
    e.sha256 = sha256_hex(bytes);
    CHECK(verify_example_bytes(e, bytes).ok());
    TempDir d;
    write_all(d.path / "block-push.zip", bytes);
    CHECK(verify_example_file(e, d.path / "block-push.zip").ok());

    SUBCASE("a changed byte") {
        std::string bad = bytes;
        bad[3] = 'X';
        auto r = verify_example_bytes(e, bad);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("SHA-256") != std::string::npos);
        CHECK(r.error().message.find(e.sha256) != std::string::npos);
        write_all(d.path / "bad.zip", bad);
        CHECK_FALSE(verify_example_file(e, d.path / "bad.zip").ok());
    }
    SUBCASE("a short download") {
        auto r = verify_example_bytes(e, bytes.substr(0, 5));
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("bytes") != std::string::npos);
        CHECK_FALSE(r.error().hint.empty());
    }
    SUBCASE("a missing file") { CHECK_FALSE(verify_example_file(e, d.path / "nope.zip").ok()); }
}

TEST_CASE("examples packaging: what a zip holds, and the same bytes every time") {
    TempDir d;
    make_examples(d);
    const stdfs::path a = d.path / "alpha";
    auto listed = example_zip_files(a);
    REQUIRE(listed.ok());
    const std::vector<std::string>& files = *listed;
    CHECK(files == std::vector<std::string>{".gitignore", "assets/pic.bin", "factoria.json", "keystore.txt",
                                            "scripts/build/keep.js", "scripts/main.js"});

    {  // a folder that cannot be listed is an Error that names it
        auto missing = example_zip_files(d.path / "missing");
        REQUIRE_FALSE(missing.ok());
        CHECK(missing.error().message.find("missing") != std::string::npos);
        CHECK_FALSE(missing.error().hint.empty());
    }

    TempDir out1, out2;
    REQUIRE(package_example_zip(a, out1.path / "alpha.zip").ok());
    auto names = export_detail::zip_entry_names(out1.path / "alpha.zip");
    REQUIRE(names.ok());
    CHECK(*names == files);
    auto main = export_detail::zip_read_entry(out1.path / "alpha.zip", "scripts/main.js");
    REQUIRE(main.ok());
    CHECK(*main == "let a = 1;\n");

    // Packed again, later, from a copy whose files have other times: the same bytes.
    stdfs::copy(a, d.path / "alpha2", stdfs::copy_options::recursive);
    std::error_code ec;
    stdfs::last_write_time(d.path / "alpha2/scripts/main.js",
                           stdfs::file_time_type::clock::now() + std::chrono::hours(5), ec);
    REQUIRE(package_example_zip(d.path / "alpha2", out2.path / "alpha.zip").ok());
    CHECK(read_all(out1.path / "alpha.zip") == read_all(out2.path / "alpha.zip"));

    CHECK_FALSE(package_example_zip(d.path / "missing", out1.path / "x.zip").ok());
}

TEST_CASE("examples packaging: package_examples writes the zips and the manifest") {
    TempDir d, out;
    make_examples(d);
    auto m = package_examples(d.path, out.path / "dist", "0.30.0");
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    REQUIRE(m->examples.size() == 2);
    CHECK(m->engineVersion == "0.30.0");
    CHECK(m->examples[0].name == "alpha");
    CHECK(m->examples[0].file == "alpha.zip");
    // The manifest on disk is what the reader parses, and its hashes are the zips'.
    auto parsed = parse_examples_manifest(read_all(out.path / "dist" / kExamplesManifestFile));
    REQUIRE_MESSAGE(parsed.ok(), (parsed.ok() ? std::string() : parsed.error().to_string()));
    CHECK(parsed->to_json() == m->to_json());
    for (const ExampleInfo& e : parsed->examples) {
        CHECK(verify_example_file(e, out.path / "dist" / e.file).ok());
        CHECK(e.size == stdfs::file_size(out.path / "dist" / e.file));
    }
    CHECK(parsed->examples[0].shows == "The first.");
    // A second run gives the same manifest, byte for byte.
    const std::string first = read_all(out.path / "dist" / kExamplesManifestFile);
    REQUIRE(package_examples(d.path, out.path / "dist", "0.30.0").ok());
    CHECK(read_all(out.path / "dist" / kExamplesManifestFile) == first);

    SUBCASE("only") {
        auto one = package_examples(d.path, out.path / "one", "0.30.0", {"beta"});
        REQUIRE(one.ok());
        REQUIRE(one->examples.size() == 1);
        CHECK(one->examples[0].name == "beta");
        CHECK_FALSE(stdfs::exists(out.path / "one/alpha.zip"));
        auto bad = package_examples(d.path, out.path / "two", "0.30.0", {"gamma"});
        REQUIRE_FALSE(bad.ok());
        CHECK(bad.error().message.find("gamma") != std::string::npos);
    }
    SUBCASE("a project folder without an entry") {
        write_all(d.path / "gamma/factoria.json", "{}");
        auto r = package_examples(d.path, out.path / "three", "0.30.0");
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("examples/gamma") != std::string::npos);
        CHECK(r.error().hint.find("\"gamma\"") != std::string::npos);
    }
    SUBCASE("an entry without a folder") {
        std::error_code ec;
        stdfs::remove_all(d.path / "beta", ec);
        auto r = package_examples(d.path, out.path / "four", "0.30.0");
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("beta") != std::string::npos);
    }
    SUBCASE("no version") { CHECK_FALSE(package_examples(d.path, out.path / "five", "").ok()); }
}

TEST_CASE("examples packaging: the real examples/ folder") {
    // block-push is the smallest example: its zip holds the project and nothing of .factoria/.
    const stdfs::path root = stdfs::path(FA_REPO_ROOT) / "examples";
    TempDir out;
    auto m = package_examples(root, out.path, "0.30.0", {"block-push"});
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    auto names = export_detail::zip_entry_names(out.path / "block-push.zip");
    REQUIRE(names.ok());
    CHECK(std::find(names->begin(), names->end(), "factoria.json") != names->end());
    CHECK(std::find(names->begin(), names->end(), "README.md") != names->end());
    for (const std::string& n : *names) CHECK_MESSAGE(n.rfind(".factoria/", 0) != 0, n);
    CHECK(std::is_sorted(names->begin(), names->end()));
}

TEST_CASE("examples packaging: every example of examples/ packs (what the release job packs)") {
    // The `package` job of release.yml runs on a pull request only when the workflow or the packer changes, so a new file in an example
    // that the packer refuses (a Windows device name, a name over 240 bytes, an unreadable file) would show up in the release run of the
    // tag. This test, which every change under examples/ runs, packs them all.
    const stdfs::path root = stdfs::path(FA_REPO_ROOT) / "examples";
    TempDir out;
    auto m = package_examples(root, out.path, "0.30.0");
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? std::string() : m.error().to_string()));
    auto text = read_all(root / kExamplesSourceFile);
    auto src = parse_examples_source(text, "examples/examples.json");
    REQUIRE(src.ok());
    CHECK(m->examples.size() == src->size());
    for (const ExampleInfo& e : m->examples) {
        INFO("example " << e.name);
        CHECK(verify_example_file(e, out.path / e.file).ok());
        auto names = export_detail::zip_entry_names(out.path / e.file);
        REQUIRE(names.ok());
        CHECK(std::find(names->begin(), names->end(), "factoria.json") != names->end());
        for (const std::string& n : *names) CHECK_MESSAGE(n.rfind(".factoria/", 0) != 0, n);
    }
}

TEST_CASE("examples: the command project.package_examples") {
    TempDir d, out;
    make_examples(d);
    CommandRegistry reg;
    register_tooling_commands(reg, d.str());
    REQUIRE(reg.has("project.package_examples"));
    CHECK(reg.info("project.package_examples")->capabilities.has(Capability::WriteAnywhere));
    auto r = reg.call("project.package_examples",
                      Json::object({{"examples", d.str()}, {"out", out.str()}, {"version", "0.31.0"}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["engineVersion"] == "0.31.0");
    CHECK(r.result["examples"].size() == 2);
    CHECK(stdfs::exists(out.path / "alpha.zip"));
    CHECK(stdfs::exists(out.path / kExamplesManifestFile));
    auto bad = reg.call("project.package_examples",
                        Json::object({{"examples", d.str()}, {"out", out.str()}, {"only", "alpha"}}));
    REQUIRE_FALSE(bad.ok);
    CHECK_FALSE(bad.error["hint"].get<std::string>().empty());
    CHECK_FALSE(reg.call("project.package_examples",
                         Json::object({{"examples", (d.path / "nope").string()}, {"out", out.str()}}))
                    .ok);
}

#ifndef _WIN32
#include <unistd.h>

TEST_CASE("examples: a folder that cannot be read fails the listing, never a partial list") {
    if (::geteuid() == 0) return;  // root reads everything
    TempDir d;
    write_all(d.path / "p/factoria.json", R"({"format":"factoria.project/1"})");
    write_all(d.path / "p/a.txt", "a");
    write_all(d.path / "p/locked/b.txt", "b");
    write_all(d.path / "p/zzz/c.txt", "c");
    stdfs::permissions(d.path / "p/locked", stdfs::perms::none);
    struct Restore {
        stdfs::path p;
        ~Restore() {
            std::error_code ec;
            stdfs::permissions(p, stdfs::perms::owner_all, ec);
        }
    } restore{d.path / "p/locked"};
    auto files = example_zip_files(d.path / "p");
    REQUIRE_FALSE(files.ok());
    CHECK(files.error().message.find("Cannot list") != std::string::npos);
    CHECK_FALSE(files.error().hint.empty());
    CHECK_FALSE(package_example_zip(d.path / "p", d.path / "p.zip").ok());
    // The same for the folder of examples.
    write_all(d.path / "ex/examples.json", R"({"format":"factoria.examples-source/1","examples":[
      {"name":"p","title":"P","shows":"x","readFirst":[]}]})");
    write_all(d.path / "ex/p/factoria.json", R"({"format":"factoria.project/1"})");
    write_all(d.path / "ex/q/factoria.json", R"({"format":"factoria.project/1"})");
    stdfs::permissions(d.path / "ex/q", stdfs::perms::none);
    struct Restore2 {
        stdfs::path p;
        ~Restore2() {
            std::error_code ec;
            stdfs::permissions(p, stdfs::perms::owner_all, ec);
        }
    } restore2{d.path / "ex/q"};
    auto m = package_examples(d.path / "ex", d.path / "out", "0.30.0");
    REQUIRE_FALSE(m.ok());
}
#endif
