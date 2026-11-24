// `factoria setup directstorage` (tools/common/src/setup_directstorage.cpp): the NuGet package Microsoft.Direct3D.DirectStorage
// at the version and SHA-256 pinned in fa/tooling/setup.h, of which only the x64 dstorage.dll and dstoragecore.dll are kept.
// Nothing here downloads: the SetupContext's downloader serves a hand-made .nupkg (a stored zip) holding fake DLLs, which the
// system's tar/unzip unpacks as it would the real one.
#include <doctest.h>

#include <filesystem>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/tooling/setup.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace fa::setup_detail {
// Defined in tools/common/src/setup_directstorage.cpp (private to fa_tooling): the install of one given package, from
// `url` ("" = NuGet's URL of its version).
SetupResult directstorage_install_package(const SetupContext& ctx, const SetupInstallOptions& opt,
                                          const DirectStoragePackage& pkg, const std::string& url);
}  // namespace fa::setup_detail

namespace {

constexpr const char* kUrl = "https://example.invalid/directstorage.nupkg";

bool has_text(const std::string& haystack, const std::string& needle) {
    return haystack.find(needle) != std::string::npos;
}

struct Lab {
    testing::TempDir tmp;
    std::string home = tmp.sub("fhome");
    std::map<std::string, std::string> served;  // url -> body
    std::vector<std::string> requested;

    // The host is this machine's (""): the install unpacks with the system's archive tool.
    SetupContext ctx() {
        SetupContext c;
        c.env = [](const std::string&) { return std::string(); };
        c.home = home;
        c.machineConfigPath = tmp.sub("export.json");
        c.executableDir = tmp.sub("bin");
        c.download = [this](const DownloadRequest& rq) {
            requested.push_back(rq.url);
            DownloadResult r;
            auto it = served.find(rq.url);
            if (it == served.end()) {
                r.ok = false;
                r.httpStatus = 404;
                r.error = make_error("not served in the test: " + rq.url, "test hint");
                return r;
            }
            testing::write_all(rq.destination, it->second);
            return r;
        };
        return c;
    }

    // A .nupkg laid out as the real one: the DLLs under native/bin/x64 (and the x86/arm64 ones the setup ignores).
    std::string package(const std::string& tag, bool withCore = true) {
        std::vector<std::pair<std::string, std::string>> entries = {
            {"LICENSE.txt", "license " + tag},
            {"native/bin/x64/dstorage.dll", "x64 dstorage " + tag},
            {"native/bin/x86/dstorage.dll", "x86 dstorage " + tag},
            {"native/include/dstorage.h", "// header"},
        };
        if (withCore) entries.emplace_back("native/bin/x64/dstoragecore.dll", "x64 dstoragecore " + tag);
        const stdfs::path file = tmp.path / ("pkg-" + tag + ".zip");
        testing::write_stored_zip(file, entries);
        return testing::read_all(file);
    }

    DirectStoragePackage serve(const std::string& body, const char* version = "1.3.0") {
        served[kUrl] = body;
        hash = sha256_hex(body);
        return DirectStoragePackage{version, hash.c_str(), 1};
    }

    std::string hash;
};

SetupInstallOptions options(bool force = false) {
    SetupInstallOptions o;
    o.component = "directstorage";
    o.force = force;
    return o;
}

SetupComponent directstorage_status(const SetupContext& c) {
    const SetupStatus st = setup_status(c, "directstorage", false);
    REQUIRE(st.components.size() == 1);
    return st.components[0];
}

}  // namespace

TEST_CASE("setup directstorage: the pinned NuGet package, missing until installed, installable on every host") {
    Lab lab;
    CHECK(std::string(kSetupDirectStorage.sha256).size() == 64);
    CHECK(std::string(kSetupDirectStorage.version) == "1.3.0");
    for (const char* host : {"linux", "macos", "windows"}) {
        CAPTURE(host);
        SetupContext c = lab.ctx();
        c.host = host;
        const SetupComponent s = directstorage_status(c);
        CHECK(s.state == "missing");
        CHECK(s.canInstall);
        CHECK(s.installSizeMb == kSetupDirectStorage.sizeMb);
        REQUIRE(!s.problems.empty());
        CHECK(has_text(s.problems[0], "factoria setup directstorage"));
    }
    CHECK(installed_directstorage_dir(lab.ctx()).empty());
    CHECK(has_text(directstorage_install_dir(lab.ctx()), "directstorage"));

    // Without a test URL the install asks NuGet for the pinned version (served nothing here: it fails, nothing installed).
    const SetupResult r = setup_detail::directstorage_install_package(lab.ctx(), options(), kSetupDirectStorage, {});
    CHECK_FALSE(r.ok);
    REQUIRE(lab.requested.size() == 1);
    CHECK(lab.requested[0] == "https://api.nuget.org/v3-flatcontainer/microsoft.direct3d.directstorage/1.3.0/"
                              "microsoft.direct3d.directstorage.1.3.0.nupkg");
    CHECK(installed_directstorage_dir(lab.ctx()).empty());
}

TEST_CASE("setup directstorage: installs the two x64 DLLs and the license, skips when there, --force reinstalls") {
    Lab lab;
    const DirectStoragePackage pkg = lab.serve(lab.package("one"));
    const SetupResult r = setup_detail::directstorage_install_package(lab.ctx(), options(), pkg, kUrl);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.changed);
    const stdfs::path dir = fs::path_from_utf8(directstorage_install_dir(lab.ctx()));
    CHECK(testing::read_all(dir / "dstorage.dll") == "x64 dstorage one");
    CHECK(testing::read_all(dir / "dstoragecore.dll") == "x64 dstoragecore one");
    CHECK(testing::read_all(dir / "LICENSE.txt") == "license one");
    CHECK_FALSE(stdfs::exists(dir / "native"));  // only the two DLLs are kept
    CHECK(installed_directstorage_dir(lab.ctx()) == fs::path_to_utf8(dir));
    const SetupComponent s = directstorage_status(lab.ctx());
    CHECK(s.state == "installed");
    REQUIRE(!s.paths.empty());
    CHECK(s.paths[0].second == fs::path_to_utf8(dir));

    // Again: nothing downloaded.
    const std::size_t before = lab.requested.size();
    const SetupResult again = setup_detail::directstorage_install_package(lab.ctx(), options(), pkg, kUrl);
    REQUIRE(again.ok);
    CHECK_FALSE(again.report.changed);
    CHECK(lab.requested.size() == before);
    REQUIRE(!again.report.steps.empty());
    CHECK(again.report.steps[0].outcome == "skipped");

    // --force downloads and replaces them.
    const DirectStoragePackage two = lab.serve(lab.package("two"));
    const SetupResult forced = setup_detail::directstorage_install_package(lab.ctx(), options(true), two, kUrl);
    REQUIRE_MESSAGE(forced.ok, forced.error.message);
    CHECK(testing::read_all(dir / "dstorage.dll") == "x64 dstorage two");
}

TEST_CASE("setup directstorage: a checksum mismatch or a package without dstoragecore.dll installs nothing") {
    Lab lab;
    SUBCASE("checksum") {
        lab.serve(lab.package("one"));
        const std::string wrong(64, '0');
        const DirectStoragePackage pkg{"1.3.0", wrong.c_str(), 1};
        const SetupResult r = setup_detail::directstorage_install_package(lab.ctx(), options(), pkg, kUrl);
        CHECK_FALSE(r.ok);
        CHECK(has_text(r.error.message, wrong));
    }
    SUBCASE("layout") {
        const DirectStoragePackage pkg = lab.serve(lab.package("one", false));
        const SetupResult r = setup_detail::directstorage_install_package(lab.ctx(), options(), pkg, kUrl);
        CHECK_FALSE(r.ok);
        CHECK(has_text(r.error.message, "native/bin/x64/dstoragecore.dll"));
    }
    CHECK(installed_directstorage_dir(lab.ctx()).empty());
    CHECK_FALSE(stdfs::exists(fs::path_from_utf8(directstorage_install_dir(lab.ctx())) / "dstorage.dll"));
}

TEST_CASE("setup directstorage: a new pinned version removes the folders of the older ones") {
    Lab lab;
    const stdfs::path old = fs::path_from_utf8(lab.home) / "tools" / "directstorage" / "1.2.0";
    testing::write_all(old / "dstorage.dll", "old");
    const DirectStoragePackage pkg = lab.serve(lab.package("one"));
    const SetupResult r = setup_detail::directstorage_install_package(lab.ctx(), options(), pkg, kUrl);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK_FALSE(stdfs::exists(old));
    CHECK(stdfs::exists(fs::path_from_utf8(directstorage_install_dir(lab.ctx())) / "dstorage.dll"));
}
