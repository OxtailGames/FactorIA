// Engine updates (fa/editor/update.h): release parsing, and the file swap with a real package and a fake download.
#include <cstdlib>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/ai/process.h"
#include "fa/editor/update.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::string slurp(const stdfs::path& p) {
    std::ifstream f(p, std::ios::binary);
    return {std::istreambuf_iterator<char>(f), {}};
}

void put(const stdfs::path& p, const std::string& text) {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << text;
}

Json release(const std::string& tag, const std::string& body, bool prerelease = false) {
    Json asset = Json::object({{"name", update_package_name()}, {"browser_download_url", "https://example.test/" + tag}, {"size", 1234}});
    return Json::object({{"tag_name", tag}, {"name", "FactorIA " + tag}, {"body", body}, {"draft", false},
                         {"prerelease", prerelease}, {"assets", Json::array({asset})}});
}

}  // namespace

TEST_CASE("version_newer compares version numbers") {
    CHECK(version_newer("0.2.0", "0.1.9"));
    CHECK(version_newer("v1.10.0", "1.9.2"));
    CHECK(version_newer("1.0.1", "1.0"));
    CHECK_FALSE(version_newer("1.0.0", "1.0"));
    CHECK_FALSE(version_newer("v0.1.0", "0.1.0"));
    CHECK_FALSE(version_newer("0.9.0", "1.0.0"));
}

TEST_CASE("parse_releases offers the newest release with the notes of every newer one") {
    Json list = Json::array({release("v0.1.0", "old"), release("v0.3.0", "three"), release("v0.4.0", "beta", true),
                             release("v0.2.0", "two")});
    list.push_back(Json::object({{"tag_name", "v0.9.0"}, {"draft", true}}));
    auto r = parse_releases(list, "0.1.0");
    REQUIRE(r);
    CHECK(r->available());
    CHECK(r->latest == "0.3.0");
    CHECK(r->packageUrl == "https://example.test/v0.3.0");
    CHECK(r->packageSize == 1234);
    CHECK(r->notes.find("three") < r->notes.find("two"));  // newest first
    CHECK(r->notes.find("old") == std::string::npos);
    CHECK(r->notes.find("beta") == std::string::npos);      // pre-releases and drafts are not offered

    auto upToDate = parse_releases(list, "0.3.0");
    REQUIRE(upToDate);
    CHECK_FALSE(upToDate->available());

    Json noPackage = Json::array({Json::object({{"tag_name", "v2.0.0"}, {"name", nullptr}, {"body", nullptr},
                                                {"draft", false}, {"prerelease", false}, {"assets", Json::array()}})});
    auto missing = parse_releases(noPackage, "0.1.0");
    REQUIRE_FALSE(missing);
    CHECK(missing.error().message.find(update_package_name()) != std::string::npos);
}

TEST_CASE("install_update replaces the files and keeps the old ones until the next start") {
    stdfs::path root = stdfs::temp_directory_path() / "fa_update_test";
    stdfs::remove_all(root);
#ifdef _WIN32
    const std::string exe = "factoria.exe";
#else
    const std::string exe = "factoria";
#endif
    stdfs::path install = root / "install", pkg = root / "pkg";
    put(install / exe, "old factoria");
    put(install / "README.md", "old readme");
    put(install / "notes.txt", "mine");  // not in the package: left alone
    // mobile/ (the prebuilt Android and iOS players) is swapped whole: the old x86_64 library must not survive next to
    // the new arm64 one, since players of two versions must never mix.
    put(install / "mobile" / "android" / "jniLibs" / "arm64-v8a" / "libfactoria_player.so", "old arm64");
    put(install / "mobile" / "android" / "jniLibs" / "x86_64" / "libfactoria_player.so", "old x86_64");
    put(pkg / "FactorIA" / exe, "new factoria");
    put(pkg / "FactorIA" / "README.md", "new readme");
    put(pkg / "FactorIA" / "factoria_player", "new player");
    put(pkg / "FactorIA" / "mobile" / "android" / "jniLibs" / "arm64-v8a" / "libfactoria_player.so", "new arm64");

    // The same archive tools the release workflow and install_update use.
    stdfs::path archive = root / update_package_name();
    ai::ProcessOptions po;
#ifdef _WIN32
    po.argv = {std::string(std::getenv("SystemRoot")) + "\\System32\\tar.exe", "-a", "-cf", archive.string(), "-C",
               pkg.string(), "FactorIA"};
#else
    po.argv = {"tar", "-czf", archive.string(), "-C", pkg.string(), "FactorIA"};
#endif
    auto made = ai::run_process(po);
    REQUIRE(made);
    REQUIRE(made->exitCode == 0);
    const std::string bytes = slurp(archive);

    UpdateInfo info;
    info.current = "0.1.0";
    info.latest = "0.2.0";
    info.packageUrl = "https://example.test/pkg";
    info.packageSize = bytes.size();
    std::string asked;
    auto download = [&](const ai::HttpRequest& rq) {
        asked = rq.url;
        for (std::size_t i = 0; i < bytes.size(); i += 1000) rq.onData(std::string_view(bytes).substr(i, 1000));
        ai::HttpResponse resp;
        resp.status = 200;
        return resp;
    };
    double progress = 0;
    auto r = install_update(info, install, [&](double p) { progress = p; }, download);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(asked == info.packageUrl);
    CHECK(progress == doctest::Approx(1.0));
    CHECK(slurp(install / exe) == "new factoria");
    CHECK(slurp(install / "README.md") == "new readme");
    CHECK(slurp(install / "factoria_player") == "new player");
    CHECK(slurp(install / "notes.txt") == "mine");
    CHECK(slurp(install / (exe + ".old")) == "old factoria");
    CHECK(slurp(install / "mobile" / "android" / "jniLibs" / "arm64-v8a" / "libfactoria_player.so") == "new arm64");
    CHECK_FALSE(stdfs::exists(install / "mobile" / "android" / "jniLibs" / "x86_64"));
    CHECK(slurp(install / "mobile.old" / "android" / "jniLibs" / "x86_64" / "libfactoria_player.so") == "old x86_64");
    CHECK_FALSE(stdfs::exists(install / ".update"));

    remove_update_leftovers(install);
    CHECK_FALSE(stdfs::exists(install / (exe + ".old")));
    CHECK_FALSE(stdfs::exists(install / "mobile.old"));
    CHECK(stdfs::exists(install / "mobile"));
    CHECK_FALSE(stdfs::exists(install / "README.md.old"));
    CHECK(stdfs::exists(install / "notes.txt"));

    // A failed download changes nothing.
    auto notFound = [](const ai::HttpRequest&) {
        ai::HttpResponse resp;
        resp.status = 404;
        return resp;
    };
    auto failed = install_update(info, install, {}, notFound);
    CHECK_FALSE(failed);
    CHECK(slurp(install / exe) == "new factoria");
    CHECK_FALSE(stdfs::exists(install / (exe + ".old")));
    CHECK_FALSE(stdfs::exists(install / ".update"));
    stdfs::remove_all(root);
}
