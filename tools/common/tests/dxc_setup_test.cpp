// `factoria setup dxc` (tools/common/src/setup_dxc.cpp): DXC, Microsoft's DirectX Shader Compiler, at the release and SHA-256 pinned
// in fa/tooling/setup.h. Nothing here downloads: the SetupContext's downloader serves a hand-made stored .zip laid out like the
// release assets (bin/ + lib/ + licence files), which the system's tar/unzip unpacks as it would the real one.
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
// Defined in tools/common/src/setup_dxc.cpp (private to fa_tooling): the install of one given build, from `url` ("" = GitHub's).
SetupResult dxc_install_build(const SetupContext& ctx, const SetupInstallOptions& opt, const DxcBuild* build,
                              const std::string& url);
}  // namespace fa::setup_detail

namespace {

constexpr const char* kUrl = "https://example.invalid/dxc.zip";

bool has_text(const std::string& haystack, const std::string& needle) {
    return haystack.find(needle) != std::string::npos;
}

// The tests that install run on any host: the context claims the host the machine really is when it has a DXC build
// (Windows x64) and Linux x86_64 otherwise, so the archive is unpacked by a tool this machine has.
#if defined(_WIN32)
constexpr const char* kHost = "windows";
constexpr const char* kExe = ".exe";
constexpr const char* kSignerRel = "bin/dxil.dll";  // where the install leaves it
constexpr const char* kSignerSrc = "bin/x64/dxil.dll";  // where the asset has it
constexpr const char* kLibDir = "";
constexpr const char* kBinDir = "bin/x64";
#else
constexpr const char* kHost = "linux";
constexpr const char* kExe = "";
constexpr const char* kSignerRel = "lib/libdxil.so";
constexpr const char* kSignerSrc = "lib/libdxil.so";
constexpr const char* kLibDir = "lib";
constexpr const char* kBinDir = "bin";
#endif

struct Lab {
    testing::TempDir tmp;
    std::string home = tmp.sub("fhome");
    std::map<std::string, std::string> served;  // url -> body
    std::vector<std::string> requested;
    std::string hash;
    std::map<std::string, std::string> environment;

    SetupContext ctx(const char* host = kHost, const char* arch = "x64") {
        SetupContext c;
        c.env = [this](const std::string& name) {
            auto it = environment.find(name);
            return it == environment.end() ? std::string() : it->second;
        };
        c.home = home;
        c.host = host;
        c.hostArch = arch;
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

    // A release asset laid out like the real one of this host: the compiler and dxv in binDir, the libraries in libDir (Linux), the
    // signer (libdxil.so / dxil.dll) where `signerSrc` says, licences at the top.
    std::string asset(const std::string& tag, const std::string& binDir, const std::string& libDir,
                      const std::string& signerSrc, bool withSigner = true) {
        std::vector<std::pair<std::string, std::string>> entries = {
            {binDir + "/dxc" + kExe, "dxc " + tag},
            {binDir + "/dxv" + kExe, "dxv " + tag},
            {"include/dxc/dxcapi.h", "// header"},
            {"LICENSE-LLVM.txt", "llvm licence " + tag},
            {"LICENSE-MS.txt", "ms licence " + tag},
            {"ReleaseNotes.md", "notes " + tag},
        };
        if (!libDir.empty()) entries.emplace_back(libDir + "/libdxcompiler.so", "compiler " + tag);
        if (withSigner) entries.emplace_back(signerSrc, "signer " + tag);
        const stdfs::path file = tmp.path / ("asset-" + tag + ".zip");
        testing::write_stored_zip(file, entries);
        return testing::read_all(file);
    }

    std::string native_asset(const std::string& tag, bool withSigner = true) {
        return asset(tag, kBinDir, kLibDir, kSignerSrc, withSigner);
    }

    // The build entry of the served body (the asset is picked by its extension: .zip).
    DxcBuild serve(const std::string& body, const char* binDir = kBinDir, const char* libDir = kLibDir,
                   const char* signer = kSignerRel) {
        served[kUrl] = body;
        hash = sha256_hex(body);
        return DxcBuild{kHost, "x64", "test.zip", hash.c_str(), binDir, libDir, signer, 1};
    }

    stdfs::path dir() { return fs::path_from_utf8(dxc_install_dir(ctx())); }
};

SetupInstallOptions options(bool force = false) {
    SetupInstallOptions o;
    o.component = "dxc";
    o.force = force;
    return o;
}

SetupComponent status_of(const SetupContext& c) {
    const SetupStatus st = setup_status(c, "dxc", false);
    REQUIRE(st.components.size() == 1);
    return st.components[0];
}

}  // namespace

TEST_CASE("setup dxc: the pinned release has a Windows and a Linux x86_64 build and none for macOS") {
    CHECK(std::string(kSetupDxcVersion) == "1.9.2609");
    for (const DxcBuild& b : kSetupDxcBuilds) {
        CAPTURE(b.asset);
        CHECK(std::string(b.sha256).size() == 64);
        CHECK(std::string(b.signer).size() > 5);
    }
    Lab lab;
    CHECK(dxc_build(lab.ctx("linux", "x64")) != nullptr);
    CHECK(dxc_build(lab.ctx("windows", "x64")) != nullptr);
    CHECK(dxc_build(lab.ctx("windows", "aarch64")) != nullptr);
    CHECK(dxc_build(lab.ctx("macos", "aarch64")) == nullptr);
    CHECK(dxc_build(lab.ctx("linux", "aarch64")) == nullptr);
    CHECK(has_text(dxc_install_dir(lab.ctx()), "dxc"));
    CHECK(has_text(dxc_install_dir(lab.ctx()), kSetupDxcVersion));
}

TEST_CASE("setup dxc: macOS and Linux Arm are unsupported and the install teaches where the DXIL comes from") {
    Lab lab;
    for (const auto& [host, arch] : {std::pair<const char*, const char*>{"macos", "aarch64"}, {"linux", "aarch64"}}) {
        CAPTURE(host);
        SetupContext c = lab.ctx(host, arch);
        const SetupComponent s = status_of(c);
        CHECK(s.state == "unsupported");
        CHECK_FALSE(s.canInstall);
        CHECK(s.problems.empty());  // nothing is broken: the committed DXIL is enough to build and run
        CHECK(has_text(s.details, "no build for"));
        CHECK(has_text(s.details, "CI"));
        SetupInstallOptions o = options();
        const SetupResult r = setup_install(o, c);
        CHECK_FALSE(r.ok);
        CHECK(r.code == "unsupported");
        CHECK(has_text(r.error.message, "DXC has no build for"));
        CHECK(has_text(r.error.hint, "rt-shader-headers"));
        CHECK(has_text(r.error.hint, "FA_DXC_DIR"));
    }
    CHECK(lab.requested.empty());
}

TEST_CASE("setup dxc: installs the compiler, its libraries and the licences, skips when there, --force reinstalls") {
    Lab lab;
    const DxcBuild build = lab.serve(lab.native_asset("one"));
    CHECK(status_of(lab.ctx()).state == "missing");
    CHECK(status_of(lab.ctx()).installSizeMb == dxc_build(lab.ctx())->sizeMb);
    CHECK(find_dxc(lab.ctx()).empty());
    const SetupResult r = setup_detail::dxc_install_build(lab.ctx(), options(), &build, kUrl);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.changed);
    const stdfs::path dir = lab.dir();
    const stdfs::path dxc = dir / "bin" / (std::string("dxc") + kExe);
    CHECK(testing::read_all(dxc) == "dxc one");
    CHECK(testing::read_all(dir / fs::path_from_utf8(kSignerRel)) == "signer one");  // where dxc looks for it
    CHECK(testing::read_all(dir / "LICENSE-LLVM.txt") == "llvm licence one");
    CHECK(testing::read_all(dir / "LICENSE-MS.txt") == "ms licence one");
    CHECK_FALSE(stdfs::exists(dir / "include"));  // only what the compiler runs with
    CHECK(find_dxc(lab.ctx()) == fs::path_to_utf8(dxc));
    const SetupComponent s = status_of(lab.ctx());
    CHECK(s.state == "installed");
    REQUIRE(!s.paths.empty());
    CHECK(s.paths[0].second == fs::path_to_utf8(dxc));
#if !defined(_WIN32)
    CHECK(testing::read_all(dir / "lib" / "libdxcompiler.so") == "compiler one");
    CHECK((stdfs::status(dxc).permissions() & stdfs::perms::owner_exec) != stdfs::perms::none);
#endif

    const std::size_t before = lab.requested.size();
    const SetupResult again = setup_detail::dxc_install_build(lab.ctx(), options(), &build, kUrl);
    REQUIRE(again.ok);
    CHECK_FALSE(again.report.changed);
    CHECK(lab.requested.size() == before);
    REQUIRE(!again.report.steps.empty());
    CHECK(again.report.steps[0].outcome == "skipped");

    const DxcBuild two = lab.serve(lab.native_asset("two"));
    const SetupResult forced = setup_detail::dxc_install_build(lab.ctx(), options(true), &two, kUrl);
    REQUIRE_MESSAGE(forced.ok, forced.error.message);
    CHECK(testing::read_all(dxc) == "dxc two");
}

TEST_CASE("setup dxc: an architecture folder of the asset (bin/arm64) is flattened under bin/") {
    Lab lab;
    const std::string body = lab.asset("one", "bin/arm64", "", "bin/arm64/dxil.dll");
    const DxcBuild build = lab.serve(body, "bin/arm64", "", "bin/dxil.dll");
    const SetupResult r = setup_detail::dxc_install_build(lab.ctx(), options(), &build, kUrl);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(testing::read_all(lab.dir() / "bin" / (std::string("dxc") + kExe)) == "dxc one");
    CHECK_FALSE(stdfs::exists(lab.dir() / "bin" / "arm64"));
}

TEST_CASE("setup dxc: a checksum mismatch or a release without the DXIL signer installs nothing") {
    Lab lab;
    SUBCASE("checksum") {
        lab.serve(lab.native_asset("one"));
        const std::string wrong(64, '0');
        const DxcBuild build{kHost, "x64", "test.zip", wrong.c_str(), kBinDir, kLibDir, kSignerRel, 1};
        const SetupResult r = setup_detail::dxc_install_build(lab.ctx(), options(), &build, kUrl);
        CHECK_FALSE(r.ok);
        CHECK(r.code == "checksum_mismatch");
        CHECK(has_text(r.error.message, wrong));
    }
    SUBCASE("no signer library") {
        const DxcBuild build = lab.serve(lab.native_asset("one", false));
        const SetupResult r = setup_detail::dxc_install_build(lab.ctx(), options(), &build, kUrl);
        CHECK_FALSE(r.ok);
        CHECK(has_text(r.error.message, kSignerRel));
        CHECK(has_text(r.error.message, "signs DXIL"));
    }
    CHECK(find_dxc(lab.ctx()).empty());
    CHECK_FALSE(stdfs::exists(lab.dir() / "bin" / (std::string("dxc") + kExe)));
}

TEST_CASE("setup dxc: FA_DXC_DIR names a DXC folder of your own, with or without a bin/ folder, on any host") {
    Lab lab;
    const stdfs::path mine = lab.tmp.path / "mydxc";
    const std::string exe = std::string("dxc") + kExe;
    SUBCASE("bin/dxc") {
        testing::write_all(mine / "bin" / exe, "x");
        lab.environment["FA_DXC_DIR"] = fs::path_to_utf8(mine);
        CHECK(find_dxc(lab.ctx()) == fs::path_to_utf8(mine / "bin" / exe));
        CHECK(status_of(lab.ctx()).state == "installed");
        // macOS has no build, but a DXC of your own is used there.
        testing::write_all(mine / "bin" / "dxc", "x");
        const SetupContext mac = lab.ctx("macos", "aarch64");
        CHECK(find_dxc(mac) == fs::path_to_utf8(mine / "bin" / "dxc"));
        CHECK(status_of(mac).state == "installed");
    }
    SUBCASE("dxc") {
        testing::write_all(mine / exe, "x");
        lab.environment["FA_DXC_DIR"] = fs::path_to_utf8(mine);
        CHECK(find_dxc(lab.ctx()) == fs::path_to_utf8(mine / exe));
    }
    SUBCASE("a folder without dxc is reported, the installed copy is not used instead") {
        lab.environment["FA_DXC_DIR"] = fs::path_to_utf8(mine);
        CHECK(find_dxc(lab.ctx()).empty());
        const SetupComponent s = status_of(lab.ctx());
        CHECK(s.state == "missing");
        REQUIRE(!s.problems.empty());
        CHECK(has_text(s.problems[0], "FA_DXC_DIR"));
    }
}

TEST_CASE("setup dxc: a new pinned version removes the folders of the older ones") {
    Lab lab;
    const stdfs::path old = fs::path_from_utf8(lab.home) / "tools" / "dxc" / "1.8.0";
    testing::write_all(old / "bin" / "dxc", "old");
    const DxcBuild build = lab.serve(lab.native_asset("one"));
    const SetupResult r = setup_detail::dxc_install_build(lab.ctx(), options(), &build, kUrl);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK_FALSE(stdfs::exists(old));
    CHECK(stdfs::exists(lab.dir() / "bin" / (std::string("dxc") + kExe)));
}
