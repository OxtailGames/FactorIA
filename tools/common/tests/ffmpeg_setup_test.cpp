// `factoria setup ffmpeg` (the static ffmpeg of eugeneware/ffmpeg-static, pinned by release and SHA-256) and where find_ffmpeg looks.
// Nothing here downloads: the SetupContext is a fake computer whose downloader serves what the test registers, and the "ffmpeg"
// is a few bytes in a hand-made gzip file.
#include <doctest.h>

#include <cstdint>
#include <filesystem>
#include <map>
#include <string>

#include "fa/core/hash.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/setup.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace fa::setup_detail {
// Defined in tools/common/src/setup_ffmpeg.cpp (private to fa_tooling): the install of one given binary entry.
SetupResult ffmpeg_install_binary(const SetupContext& ctx, const SetupInstallOptions& options, const FfmpegBinary* bin);
}  // namespace fa::setup_detail

namespace {

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

std::uint32_t crc32(const std::string& data) {
    std::uint32_t crc = 0xFFFFFFFFu;
    for (unsigned char c : data) {
        crc ^= c;
        for (int i = 0; i < 8; ++i) crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}

void put32(std::string& out, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) out.push_back(static_cast<char>((v >> (8 * i)) & 0xFF));
}

// A valid gzip file holding `data` in one stored deflate block (data < 64 KB).
std::string gzip_of(const std::string& data, bool badCrc = false) {
    std::string out("\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03", 10);
    const std::uint16_t n = static_cast<std::uint16_t>(data.size());
    out.push_back('\x01');
    out.push_back(static_cast<char>(n & 0xFF));
    out.push_back(static_cast<char>(n >> 8));
    out.push_back(static_cast<char>(~n & 0xFF));
    out.push_back(static_cast<char>((~n >> 8) & 0xFF));
    out += data;
    put32(out, crc32(data) ^ (badCrc ? 1u : 0u));
    put32(out, static_cast<std::uint32_t>(data.size()));
    return out;
}

struct Lab {
    testing::TempDir tmp;
    std::string home = tmp.sub("fhome");
    std::map<std::string, std::string> served;  // url -> body
    std::vector<std::string> requested;
    std::map<std::string, std::string> env;

    SetupContext ctx(const std::string& host = "linux", const std::string& arch = "x64") {
        SetupContext c;
        c.env = [this](const std::string& k) {
            auto it = env.find(k);
            return it == env.end() ? std::string() : it->second;
        };
        c.home = home;
        c.machineConfigPath = tmp.sub("export.json");
        c.executableDir = tmp.sub("bin");
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
        return c;
    }
};

std::string url_of(const FfmpegBinary& b) {
    return std::string("https://github.com/eugeneware/ffmpeg-static/releases/download/") + kSetupFfmpegRelease + "/ffmpeg-" + b.asset + ".gz";
}

SetupInstallOptions options(bool force = false) {
    SetupInstallOptions o;
    o.component = "ffmpeg";
    o.force = force;
    return o;
}

SetupComponent ffmpeg_status(const SetupContext& c) {
    const SetupStatus st = setup_status(c, "ffmpeg", false);
    REQUIRE(st.components.size() == 1);
    return st.components[0];
}

// The status and install tests expect "missing": an ffmpeg on this computer's PATH (the lookup uses the real PATH) would hide it.
bool machine_has_ffmpeg() { return fa::find_ffmpeg([](const std::string&) { return std::string(); }, "/nonexistent/export.json").ok(); }

}  // namespace

TEST_CASE("setup ffmpeg: setup.status lists the component, every desktop host has a build, others are unsupported") {
    Lab lab;
    const Json status = setup_status(lab.ctx(), {}, false).to_json();
    bool listed = false;
    for (const Json& comp : status["components"]) listed = listed || comp.value("id", "") == "ffmpeg";
    CHECK(listed);

    const std::pair<const char*, const char*> hosts[] = {{"windows", "x64"}, {"windows", "aarch64"}, {"linux", "x64"},
                                                         {"linux", "aarch64"}, {"macos", "x64"},     {"macos", "aarch64"}};
    for (const auto& [host, arch] : hosts) {
        CAPTURE(host);
        CAPTURE(arch);
        SetupContext c = lab.ctx(host, arch);
        REQUIRE(ffmpeg_binary(c) != nullptr);
        const SetupComponent comp = ffmpeg_status(c);
        CHECK(comp.canInstall);
        CHECK(comp.installSizeMb > 0);
    }
    CHECK(std::string(ffmpeg_binary(lab.ctx("macos", "aarch64"))->asset) == "darwin-arm64");
    SetupContext odd = lab.ctx("linux", "riscv64");
    CHECK(ffmpeg_binary(odd) == nullptr);
    const SetupComponent c = ffmpeg_status(odd);
    CHECK(c.state == "unsupported");
    CHECK_FALSE(c.canInstall);
    CHECK(has_text(c.details, "FACTORIA_FFMPEG"));
    const SetupResult r = setup_install(options(), odd);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "unsupported");
}

TEST_CASE("setup ffmpeg: the pinned table has a 64 hex digit hash per build and the release's download names") {
    for (const FfmpegBinary& b : kSetupFfmpegBinaries) {
        CAPTURE(b.asset);
        CHECK(std::string(b.sha256).size() == 64);
        CHECK(has_text(url_of(b), "eugeneware/ffmpeg-static/releases/download/b6.0/ffmpeg-"));
        CHECK(b.sizeMb > 0);
    }
}

TEST_CASE("setup ffmpeg: found by FACTORIA_FFMPEG, export.json or the installed copy") {
    Lab lab;
    SetupContext c = lab.ctx();
    if (machine_has_ffmpeg()) {
        MESSAGE("ffmpeg is on this computer's PATH: the missing/installed distinction is not testable here");
        return;
    }
    CHECK(ffmpeg_status(c).state == "missing");
    CHECK_FALSE(ffmpeg_status(c).problems.empty());
    CHECK(has_text(ffmpeg_status(c).problems.back(), "factoria setup ffmpeg"));

    const std::string installed = ffmpeg_install_path(c);
    CHECK(has_text(installed, std::string("ffmpeg") + "/" + kSetupFfmpegRelease + "/ffmpeg"));
    testing::write_all(installed, "installed");
    auto found = find_ffmpeg(c.env, c.config_path(), ffmpeg_install_path(c));
    REQUIRE(found.ok());
    CHECK(found->path == stdfs::path(installed).generic_string());
    CHECK(ffmpeg_status(c).state == "installed");

    // A variable wins over the installed copy; one that names nothing is an error, not a fall-through.
    const std::string mine = lab.tmp.sub("mine/ffmpeg");
    testing::write_all(mine, "mine");
    lab.env["FACTORIA_FFMPEG"] = mine;
    auto viaEnv = find_ffmpeg(c.env, c.config_path(), ffmpeg_install_path(c));
    REQUIRE(viaEnv.ok());
    CHECK(viaEnv->from == "FACTORIA_FFMPEG");
    lab.env["FACTORIA_FFMPEG"] = lab.tmp.sub("nowhere");
    CHECK_FALSE(find_ffmpeg(c.env, c.config_path(), ffmpeg_install_path(c)).ok());
    CHECK(ffmpeg_status(c).state == "missing");
}

TEST_CASE("setup ffmpeg: the file for this computer is downloaded, checked, unpacked and older releases removed") {
    Lab lab;
    if (machine_has_ffmpeg()) return;
    SetupContext c = lab.ctx();
    const std::string program = "\x7f" "ELF pretend this is ffmpeg";
    const std::string gz = gzip_of(program);
    const std::string sum = sha256_hex(gz);
    const FfmpegBinary bin{"linux", "x64", "linux-x64", sum.c_str(), 1};  // a table entry whose hash is the fake file's
    lab.served[url_of(bin)] = gz;
    const stdfs::path old = stdfs::path(c.home_dir()) / "tools" / "ffmpeg" / "b0.1";
    testing::write_all(old / "ffmpeg", "old");

    const SetupResult r = setup_detail::ffmpeg_install_binary(c, options(), &bin);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(r.report.changed);
    CHECK(lab.requested == std::vector<std::string>{url_of(bin)});
    const stdfs::path dest = ffmpeg_install_path(c);
    CHECK(testing::read_all(dest) == program);
    CHECK_FALSE(stdfs::exists(old));
    CHECK(ffmpeg_status(c).state == "installed");
    CHECK(find_ffmpeg(c.env, c.config_path(), ffmpeg_install_path(c)).ok());

    // Found: a second install downloads nothing; force downloads again.
    lab.requested.clear();
    const SetupResult again = setup_detail::ffmpeg_install_binary(c, options(), &bin);
    REQUIRE(again.ok);
    CHECK_FALSE(again.report.changed);
    CHECK(lab.requested.empty());
    CHECK(setup_detail::ffmpeg_install_binary(c, options(true), &bin).report.changed);
    CHECK(lab.requested.size() == 1);
}

TEST_CASE("setup ffmpeg: a download that is not the pinned file, or not a gzip file, installs nothing") {
    Lab lab;
    if (machine_has_ffmpeg()) return;
    SetupContext c = lab.ctx();
    const FfmpegBinary* bin = ffmpeg_binary(c);
    REQUIRE(bin != nullptr);
    lab.served[url_of(*bin)] = "somebody replaced this file";
    const SetupResult r = setup_install(options(), c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(has_text(r.error.message, bin->sha256));
    CHECK(has_text(r.error.hint, "Nothing was installed"));
    CHECK_FALSE(stdfs::exists(ffmpeg_install_path(c)));

    // Right hash, wrong content: a text file is not gzip; a gzip with a wrong CRC does not unpack either.
    for (const std::string& body : {std::string("this is plain text, long enough to pass the header size check"), gzip_of("some bytes", true)}) {
        const std::string sum = sha256_hex(body);
        const FfmpegBinary pinned{"linux", "x64", "linux-x64", sum.c_str(), 1};
        lab.served[url_of(pinned)] = body;
        const SetupResult bad = setup_detail::ffmpeg_install_binary(c, options(), &pinned);
        REQUIRE_FALSE(bad.ok);
        CHECK(has_text(bad.error.message, "not a valid gzip file"));
        CHECK_FALSE(bad.error.hint.empty());
        CHECK_FALSE(stdfs::exists(ffmpeg_install_path(c)));
    }

    lab.served.clear();  // a 404
    const SetupResult nf = setup_install(options(), c);
    REQUIRE_FALSE(nf.ok);
    CHECK_FALSE(nf.error.hint.empty());
}

TEST_CASE("setup ffmpeg: Windows installs ffmpeg.exe") {
    Lab lab;
    SetupContext win = lab.ctx("windows", "x64");
    CHECK(has_text(ffmpeg_install_path(win), "ffmpeg.exe"));
    const FfmpegBinary* bin = ffmpeg_binary(win);
    REQUIRE(bin != nullptr);
    CHECK(std::string(bin->asset) == "win32-x64");
    CHECK(std::string(ffmpeg_binary(lab.ctx("windows", "aarch64"))->asset) == "win32-x64");
}

TEST_CASE("setup ffmpeg: an unknown component name suggests ffmpeg") {
    Lab lab;
    SetupInstallOptions typo = options();
    typo.component = "ffmpe";
    const SetupResult r = setup_install(typo, lab.ctx());
    REQUIRE_FALSE(r.ok);
    CHECK(has_text(r.error.hint, "ffmpeg"));
}
