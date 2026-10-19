// `factoria setup shaders` (sokol-shdc, pinned by commit and SHA-256) and where sokol-shdc is looked for. No test runs the real
// sokol-shdc or needs a network: the SetupContext is a fake computer whose downloader serves what the test registers.
#include <doctest.h>

#include <filesystem>
#include <map>
#include <string>

#include "fa/core/hash.h"
#include "fa/tooling/setup.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace fa::setup_detail {
// Defined in tools/common/src/setup_shaders.cpp (private to fa_tooling): the install of one given binary entry.
SetupResult shaders_install_binary(const SetupContext& ctx, const SetupInstallOptions& options, const SokolShdcBinary* bin);
}  // namespace fa::setup_detail

namespace {

struct Lab {
    testing::TempDir tmp;
    std::string home = tmp.sub("fhome");
    std::string exeDir = tmp.sub("bin");
    std::map<std::string, std::string> served;  // url -> body
    std::vector<std::string> requested;
    std::map<std::string, std::string> env;
    int runs = 0;

    SetupContext ctx(const std::string& host = "linux", const std::string& arch = "x64") {
        SetupContext c;
        c.env = [this](const std::string& k) {
            auto it = env.find(k);
            return it == env.end() ? std::string() : it->second;
        };
        c.home = home;
        c.machineConfigPath = tmp.sub("export.json");
        c.executableDir = exeDir;
        c.host = host;
        c.hostArch = arch;
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
        c.run = [this](const ProcessOptions&) -> Result<ProcessResult> {
            ++runs;  // nothing may run sokol-shdc here
            return ProcessResult{};
        };
        return c;
    }
};

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

std::string url_of(const SokolShdcBinary& b, const std::string& file) {
    return std::string("https://raw.githubusercontent.com/floooh/sokol-tools-bin/") + kSetupSokolShdcCommit + "/bin/" + b.dir +
           "/" + file;
}

SetupInstallOptions options(bool force = false) {
    SetupInstallOptions o;
    o.component = "shaders";
    o.force = force;
    return o;
}

SetupComponent shaders_status(const SetupContext& c) {
    const SetupStatus st = setup_status(c, "shaders", false);
    REQUIRE(st.components.size() == 1);
    return st.components[0];
}

}  // namespace

TEST_CASE("setup shaders: every desktop host has a binary, others are unsupported") {
    Lab lab;
    const std::pair<const char*, const char*> hosts[] = {{"windows", "x64"}, {"windows", "aarch64"}, {"linux", "x64"},
                                                         {"linux", "aarch64"}, {"macos", "x64"},     {"macos", "aarch64"}};
    for (const auto& [host, arch] : hosts) {
        CAPTURE(host);
        CAPTURE(arch);
        SetupContext c = lab.ctx(host, arch);
        REQUIRE(sokol_shdc_binary(c) != nullptr);
        CHECK(shaders_status(c).state == "missing");
    }
    CHECK(std::string(sokol_shdc_binary(lab.ctx("linux", "aarch64"))->dir) == "linux_arm64");
    SetupContext odd = lab.ctx("linux", "riscv64");
    CHECK(sokol_shdc_binary(odd) == nullptr);
    const SetupComponent c = shaders_status(odd);
    CHECK(c.state == "unsupported");
    CHECK_FALSE(c.canInstall);
    CHECK(has_text(c.details, "SOKOL_SHDC"));
    const SetupResult r = setup_install(options(), odd);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "unsupported");
}

TEST_CASE("setup shaders: lookup order is $SOKOL_SHDC, next to factoria, the installed pinned commit") {
    Lab lab;
    SetupContext c = lab.ctx();
    CHECK(find_sokol_shdc(c).empty());
    CHECK(shaders_status(c).state == "missing");

    const stdfs::path installed = stdfs::path(sokol_shdc_install_dir(c)) / "sokol-shdc";
    CHECK(has_text(installed.string(), kSetupSokolShdcCommit));
    testing::write_all(installed, "installed");
    CHECK(find_sokol_shdc(c) == installed.string());
    CHECK(shaders_status(c).state == "installed");

    const stdfs::path next = stdfs::path(lab.exeDir) / "sokol-shdc";
    testing::write_all(next, "next to factoria");
    CHECK(find_sokol_shdc(c) == next.string());
    // What the release downloads have (release.yml greps the smoke test's status for these words).
    const SetupComponent bundled = shaders_status(c);
    CHECK(bundled.state == "installed");
    CHECK(has_text(bundled.details, "sokol-shdc found next to factoria"));
    CHECK(has_text(bundled.details, next.string()));

    const std::string mine = lab.tmp.sub("mine");
    lab.env["SOKOL_SHDC"] = mine;
    CHECK(find_sokol_shdc(c) == mine);
    // A variable that names nothing is not "installed", and the status says so.
    stdfs::remove(installed);
    stdfs::remove(next);
    const SetupComponent missing = shaders_status(c);
    CHECK(missing.state == "missing");
    REQUIRE_FALSE(missing.problems.empty());
    CHECK(has_text(missing.problems.front(), "SOKOL_SHDC"));
    testing::write_all(mine, "mine");
    CHECK(shaders_status(c).state == "installed");

    lab.env.clear();
    SetupContext win = lab.ctx("windows", "x64");
    CHECK(has_text(sokol_shdc_install_dir(win), kSetupSokolShdcCommit));
    testing::write_all(stdfs::path(lab.exeDir) / "sokol-shdc.exe", "x");
    CHECK(find_sokol_shdc(win) == (stdfs::path(lab.exeDir) / "sokol-shdc.exe").string());
}

TEST_CASE("setup shaders: the file for this computer is downloaded, checked, installed, older commits removed") {
    Lab lab;
    SetupContext c = lab.ctx();
    const std::string body = "pretend this is sokol-shdc";
    const std::string sum = sha256_hex(body);
    const SokolShdcBinary bin{"linux", "x64", "linux", sum.c_str()};  // a table entry whose hash is the fake file's
    lab.served[url_of(bin, "sokol-shdc")] = body;
    const stdfs::path old = stdfs::path(c.home_dir()) / "tools" / "sokol-shdc" / "0123456789abcdef";
    testing::write_all(old / "sokol-shdc", "old");

    const SetupResult r = setup_detail::shaders_install_binary(c, options(), &bin);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.changed);
    CHECK(lab.requested == std::vector<std::string>{url_of(bin, "sokol-shdc")});
    const stdfs::path dest = stdfs::path(sokol_shdc_install_dir(c)) / "sokol-shdc";
    CHECK(testing::read_all(dest) == body);
    CHECK_FALSE(stdfs::exists(old));
    CHECK(find_sokol_shdc(c) == dest.string());
    CHECK(shaders_status(c).state == "installed");
    CHECK(lab.runs == 0);

    // Found: a second install downloads nothing; force downloads again.
    lab.requested.clear();
    const SetupResult again = setup_install(options(), c);
    REQUIRE(again.ok);
    CHECK_FALSE(again.report.changed);
    CHECK(lab.requested.empty());
    CHECK(setup_detail::shaders_install_binary(c, options(true), &bin).report.changed);
    CHECK(lab.requested.size() == 1);
}

TEST_CASE("setup shaders: a download that is not the pinned file installs nothing") {
    Lab lab;
    SetupContext c = lab.ctx();
    const SokolShdcBinary* bin = sokol_shdc_binary(c);
    REQUIRE(bin != nullptr);
    lab.served[url_of(*bin, "sokol-shdc")] = "somebody replaced this file";
    const SetupResult r = setup_install(options(), c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(has_text(r.error.message, bin->sha256));
    CHECK(has_text(r.error.hint, "Nothing was installed"));
    CHECK(find_sokol_shdc(c).empty());
    CHECK_FALSE(stdfs::exists(sokol_shdc_install_dir(c)));  // no half-installed file

    lab.served.clear();  // a 404
    const SetupResult nf = setup_install(options(), c);
    REQUIRE_FALSE(nf.ok);
    CHECK_FALSE(nf.error.hint.empty());
}

TEST_CASE("setup shaders: Windows downloads sokol-shdc.exe from bin/win32") {
    Lab lab;
    SetupContext c = lab.ctx("windows", "x64");
    const SokolShdcBinary* bin = sokol_shdc_binary(c);
    REQUIRE(bin != nullptr);
    CHECK(std::string(bin->dir) == "win32");
    (void)setup_install(options(), c);
    REQUIRE(lab.requested.size() == 1);
    CHECK(lab.requested[0] == url_of(*bin, "sokol-shdc.exe"));
}

TEST_CASE("setup shaders: compile_shaders.sh pins the same commit and hashes as setup.h") {
    const std::string script = testing::read_all(stdfs::path(FA_REPO_ROOT) / "tools" / "shaders" / "compile_shaders.sh");
    REQUIRE_FALSE(script.empty());
    CHECK(has_text(script, std::string("SHDC_COMMIT=") + kSetupSokolShdcCommit));
    for (const SokolShdcBinary& b : kSetupSokolShdcBinaries) {
        CAPTURE(b.dir);
        CHECK(has_text(script, std::string("SHDC_SHA256_") + b.dir + "=" + b.sha256));
    }
    CHECK(has_text(script, "sokol-tools-bin/$SHDC_COMMIT/bin/$DIR/$EXE"));
}

TEST_CASE("setup shaders: the release downloads bundle the sokol-shdc that setup.h pins") {
    // scripts/bundle-sokol-shdc.sh (release.yml) reads the pin from setup.h with sed, one line per value, and fails the
    // release when it cannot: these are the lines it reads, so a reformat of setup.h fails here first.
    std::string header = testing::read_all(stdfs::path(FA_REPO_ROOT) / "tools" / "common" / "include" / "fa" / "tooling" / "setup.h");
    std::erase(header, '\r');  // a Windows checkout may have CRLF; the script drops it too
    CHECK(has_text(header, std::string("\ninline constexpr const char* kSetupSokolShdcCommit = \"") + kSetupSokolShdcCommit + "\";\n"));
    CHECK(has_text(header, "\ninline constexpr SokolShdcBinary kSetupSokolShdcBinaries[] = {\n"));
    for (const SokolShdcBinary& b : kSetupSokolShdcBinaries) {
        CAPTURE(b.dir);
        CHECK(has_text(header, std::string("\n    {\"") + b.host + "\", \"" + b.arch + "\", \"" + b.dir + "\", \"" + b.sha256 + "\"},\n"));
    }
    const std::string script = testing::read_all(stdfs::path(FA_REPO_ROOT) / "scripts" / "bundle-sokol-shdc.sh");
    REQUIRE_FALSE(script.empty());
    CHECK(has_text(script, "tools/common/include/fa/tooling/setup.h"));
    for (const char* dir : {"win32", "linux", "osx", "osx_arm64"}) {  // the packages: Windows, Linux x64, macOS universal
        CAPTURE(dir);
        CHECK(has_text(script, std::string("fetch ") + dir + " sokol-shdc"));
    }
    const std::string release = testing::read_all(stdfs::path(FA_REPO_ROOT) / ".github" / "workflows" / "release.yml");
    CHECK(has_text(release, "./scripts/bundle-sokol-shdc.sh build/sokol-shdc"));
    CHECK(has_text(release, "cp \"build/sokol-shdc/sokol-shdc${{ matrix.exe }}\" dist/FactorIA/"));
}

TEST_CASE("setup shaders: setup.status and setup.install know the component") {
    Lab lab;
    SetupContext c = lab.ctx();
    bool listed = false;
    const Json status = setup_status(c, {}, false).to_json();
    for (const Json& comp : status["components"])
        listed = listed || comp.value("id", "") == "shaders";
    CHECK(listed);
    SetupInstallOptions typo = options();
    typo.component = "shader";
    const SetupResult r = setup_install(typo, c);
    REQUIRE_FALSE(r.ok);
    CHECK(has_text(r.error.hint, "shaders"));  // "did you mean"
}

TEST_CASE("setup shaders: on Windows the status and a vanished file explain the Defender false positive") {
    Lab lab;
    SetupContext win = lab.ctx("windows", "x64");
    const SokolShdcBinary* bin = sokol_shdc_binary(win);
    REQUIRE(bin != nullptr);
    const SetupComponent c = shaders_status(win);
    const std::string& text = c.problems.front();
    CHECK(has_text(text, "false positive"));
    CHECK(has_text(text, bin->sha256));
    CHECK(has_text(text, "Protection history"));
    CHECK(has_text(text, "SOKOL_SHDC"));
    CHECK(has_text(text, "Games never contain"));
    // Other hosts do not get the Windows text.
    for (const std::string& p : shaders_status(lab.ctx()).problems) CHECK_FALSE(has_text(p, "Defender"));

    // The file is gone right after the move (the antivirus removed it): the install says why.
    const std::string body = "pretend this is sokol-shdc.exe";
    const std::string sum = sha256_hex(body);
    const SokolShdcBinary fake{"windows", "", "win32", sum.c_str()};
    lab.served[url_of(fake, "sokol-shdc.exe")] = body;
    SetupContext gone = lab.ctx("windows", "x64");
    gone.progress = [&](const std::string& line) {  // the "still there?" line: the antivirus removes the file just before
        if (has_text(line, "still there")) {
            std::error_code ec;
            stdfs::remove(stdfs::path(sokol_shdc_install_dir(gone)) / "sokol-shdc.exe", ec);
        }
    };
    const SetupResult r = setup_detail::shaders_install_binary(gone, options(), &fake);
    REQUIRE_FALSE(r.ok);
    CHECK(has_text(r.error.message, "cannot be read"));
    CHECK(has_text(r.error.hint, "Protection history"));
}
