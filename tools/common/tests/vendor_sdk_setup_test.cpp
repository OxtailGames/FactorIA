// `factoria setup streamline | xess | fidelityfx` (tools/common/src/setup_vendor_sdks.cpp): the vendors' redistributable x64 DLLs,
// pinned by SHA-256 in fa/tooling/setup.h, installed after the user accepted the vendor's license. Nothing here downloads: the
// SetupContext's downloader serves hand-made archives (a stored zip) or single files, which the system's tar/unzip unpacks as
// it would the real release. The real table is checked for what it must never contain.
#include <doctest.h>

#include <cctype>
#include <filesystem>
#include <algorithm>
#include <map>
#include <memory>
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
// Defined in tools/common/src/setup_vendor_sdks.cpp (private to fa_tooling): status and install of one given SDK table.
SetupComponent vendor_sdk_status(const SetupContext& ctx, const VendorSdk& sdk, bool fetchLicenses);
SetupResult vendor_sdk_install(const SetupContext& ctx, const SetupInstallOptions& opt, const VendorSdk& sdk);
}  // namespace fa::setup_detail

namespace {

constexpr const char* kArchiveUrl = "https://example.invalid/sdk.zip";
constexpr const char* kBaseUrl = "https://example.invalid/raw";
constexpr const char* kLicenseUrl = "https://example.invalid/license.txt";

bool has_text(const std::string& haystack, const std::string& needle) {
    return haystack.find(needle) != std::string::npos;
}

bool lower_has(std::string haystack, const std::string& needle) {
    for (char& c : haystack) c = char(std::tolower(static_cast<unsigned char>(c)));
    return haystack.find(needle) != std::string::npos;
}

std::vector<std::string> sources_of(const VendorSdk& sdk) {
    std::vector<std::string> out;
    for (int i = 0; i < sdk.fileCount; ++i) out.push_back(sdk.files[i].src);
    return out;
}

struct Lab {
    testing::TempDir tmp;
    std::string home = tmp.sub("fhome");
    std::map<std::string, std::string> served;  // url -> body
    std::vector<std::string> requested;
    std::string host;  // "" = this machine

    SetupContext ctx() {
        SetupContext c;
        c.env = [](const std::string&) { return std::string(); };
        c.home = home;
        c.host = host;
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
};

// A fake SDK table whose strings live as long as the object. Archive mode: kArchiveUrl, one zip holding the files (the
// DLLs under bin/x64, the licenses at the top, and a profiler DLL the table does not list). Single-file mode: each file
// alone at kBaseUrl + "/" + src, each pinned.
struct FakeSdk {
    std::string version = "1.0.0";
    bool archive = true;
    std::string licenseBody = "The test license.\nShip it with the game.\n";
    std::vector<VendorSdkFile> files;
    std::vector<std::string> hashes;
    std::map<std::string, std::string> bodies;  // src -> content
    std::string zip, zipHash, licenseHash, id = "streamline", licenseEnd;
    VendorSdk sdk{};

    FakeSdk(Lab& lab, bool asArchive = true, const std::string& ver = "1.0.0") : version(ver), archive(asArchive) {
        bodies = {{"bin/x64/sl.interposer.dll", "interposer " + ver},
                  {"bin/x64/sl.dlss.dll", "dlss " + ver},
                  {"license.txt", "vendor license " + ver}};
        hashes.reserve(bodies.size());
        for (const auto& [src, body] : bodies) hashes.push_back(sha256_hex(body));
        files.reserve(bodies.size());
        std::size_t i = 0;
        for (const auto& [src, body] : bodies) {
            const char* dst = src == "license.txt" ? "sl.license.txt" : nullptr;
            files.push_back(VendorSdkFile{keep(src), dst, archive ? "" : keep(hashes[i])});
            ++i;
        }
        licenseHash = sha256_hex(licenseBody);
        if (archive) {
            std::vector<std::pair<std::string, std::string>> entries(bodies.begin(), bodies.end());
            entries.emplace_back("bin/x64/sl.nvperf.dll", "the profiler: never kept");
            entries.emplace_back("include/sl.h", "// header");
            const stdfs::path file = lab.tmp.path / ("sdk-" + ver + ".zip");
            testing::write_stored_zip(file, entries);
            zip = testing::read_all(file);
            zipHash = sha256_hex(zip);
            lab.served[kArchiveUrl] = zip;
        } else {
            for (const auto& [src, body] : bodies) lab.served[std::string(kBaseUrl) + "/" + src] = body;
        }
        lab.served[kLicenseUrl] = licenseBody;
        refresh();
    }

    // The strings the table points at must not move: keep them in a list that never reallocates.
    std::vector<std::unique_ptr<std::string>> pool;
    const char* keep(const std::string& s) {
        pool.push_back(std::make_unique<std::string>(s));
        return pool.back()->c_str();
    }

    void refresh() {
        sdk = VendorSdk{id.c_str(),
                        "NVIDIA Streamline (test)",
                        version.c_str(),
                        archive ? kArchiveUrl : "",
                        archive ? zipHash.c_str() : "",
                        archive ? "" : kBaseUrl,
                        1,
                        files.data(),
                        int(files.size()),
                        "test-license",
                        "Test SDK license",
                        kLicenseUrl,
                        licenseHash.c_str(),
                        licenseEnd.c_str(),
                        "Obligation: credit the vendor."};
    }
};

SetupInstallOptions options(bool accept, bool force = false) {
    SetupInstallOptions o;
    o.component = "streamline";
    o.acceptLicenses = accept;
    o.force = force;
    return o;
}

}  // namespace

TEST_CASE("vendor SDK tables: pinned, and never the profiler, the unsigned builds or the denoiser") {
    REQUIRE(vendor_sdk_ids() == std::vector<std::string>{"streamline", "xess", "fidelityfx"});
    for (const std::string& id : vendor_sdk_ids()) {
        CAPTURE(id);
        const VendorSdk* sdk = find_vendor_sdk(id);
        REQUIRE(sdk != nullptr);
        CHECK(std::string(sdk->licenseSha256).size() == 64);
        CHECK(std::string(sdk->licenseUrl).rfind("https://", 0) == 0);
        CHECK(sdk->fileCount > 0);
        CHECK(*sdk->obligations != 0);
        if (*sdk->archiveUrl) {
            CHECK(std::string(sdk->archiveSha256).size() == 64);
        } else {
            for (int i = 0; i < sdk->fileCount; ++i) CHECK(std::string(sdk->files[i].sha256).size() == 64);
        }
        for (const std::string& src : sources_of(*sdk)) {
            CAPTURE(src);
            CHECK_FALSE(lower_has(src, "nvperf"));  // a separate, non redistributable license
            CHECK_FALSE(lower_has(src, "denoiser"));
            CHECK_FALSE(lower_has(src, "radiancecache"));
            CHECK_FALSE(lower_has(src, "development"));
            CHECK_FALSE(lower_has(src, "/lib/"));
            CHECK_FALSE(lower_has(src, ".h"));
        }
    }
    CHECK(find_vendor_sdk("directstorage") == nullptr);
    // Streamline: the interposer and the plugins, the DLSS runtimes (NGX), Reflex, and the licenses.
    std::vector<std::string> streamline = sources_of(*find_vendor_sdk("streamline"));
    auto has_file = [](const std::vector<std::string>& v, const std::string& name) {
        for (const std::string& s : v)
            if (has_text(s, name)) return true;
        return false;
    };
    CHECK(has_file(streamline, "sl.interposer.dll"));
    CHECK(has_file(streamline, "sl.reflex.dll"));
    CHECK(has_file(streamline, "nvngx_dlss.dll"));
    CHECK(has_file(sources_of(*find_vendor_sdk("xess")), "libxess.dll"));
    CHECK(has_file(sources_of(*find_vendor_sdk("fidelityfx")), "amd_fidelityfx_loader_dx12.dll"));
}

TEST_CASE("setup streamline: refuses without the license accepted, then installs only the listed files") {
    Lab lab;
    FakeSdk fake(lab);
    const SetupContext c = lab.ctx();

    SetupResult r = setup_detail::vendor_sdk_install(c, options(false), fake.sdk);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "license_required");
    CHECK(has_text(r.error.message, "Test SDK license"));
    CHECK(has_text(r.error.hint, "--accept-licenses"));
    CHECK(has_text(r.error.hint, "An AI must ask the user first"));
    CHECK(lab.requested.empty());  // nothing was downloaded before the answer
    CHECK(installed_vendor_sdk_dir(c, fake.sdk).empty());

    r = setup_detail::vendor_sdk_install(c, options(true), fake.sdk);
    REQUIRE(r.ok);
    CHECK(r.report.changed);
    const std::string dir = installed_vendor_sdk_dir(c, fake.sdk);
    REQUIRE_FALSE(dir.empty());
    CHECK(has_text(dir, "tools"));
    CHECK(dir == vendor_sdk_install_dir(c, fake.sdk));
    const stdfs::path d = fs::path_from_utf8(dir);
    CHECK(testing::read_all(d / "sl.interposer.dll") == "interposer 1.0.0");
    CHECK(testing::read_all(d / "sl.dlss.dll") == "dlss 1.0.0");
    CHECK(testing::read_all(d / "sl.license.txt") == "vendor license 1.0.0");  // renamed by VendorSdkFile::dst
    CHECK_FALSE(stdfs::exists(d / "sl.nvperf.dll"));  // in the archive, not in the table: never kept
    CHECK_FALSE(stdfs::exists(d / "sl.h"));
    bool obligations = false;
    for (const std::string& s : r.report.nextSteps) obligations = obligations || has_text(s, "credit the vendor");
    CHECK(obligations);
    CHECK(vendor_sdk_file_is_library(fake.sdk.files[0]) == true);   // .dll goes next to the game
    CHECK(vendor_sdk_file_is_library(fake.sdk.files[2]) == false);  // the license goes to licenses/<id>/

    // Installed: skipped, without even asking for the license; --force downloads again.
    const std::size_t before = lab.requested.size();
    r = setup_detail::vendor_sdk_install(c, options(false), fake.sdk);
    REQUIRE(r.ok);
    CHECK_FALSE(r.report.changed);
    CHECK(lab.requested.size() == before);
    r = setup_detail::vendor_sdk_install(c, options(true, true), fake.sdk);
    REQUIRE(r.ok);
    CHECK(r.report.changed);
    CHECK(lab.requested.size() == before + 1);
}

TEST_CASE("setup streamline: a download that is not the pinned one is refused and nothing is installed") {
    Lab lab;
    FakeSdk fake(lab);
    lab.served[kArchiveUrl] = fake.zip + "tampered";
    const SetupContext c = lab.ctx();
    const SetupResult r = setup_detail::vendor_sdk_install(c, options(true), fake.sdk);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(installed_vendor_sdk_dir(c, fake.sdk).empty());
    CHECK_FALSE(stdfs::exists(fs::path_from_utf8(vendor_sdk_install_dir(c, fake.sdk))));

    // The same with the real table: the pins of the maintainers, not the test's.
    SetupInstallOptions o = options(true);
    lab.served["https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.14.16/streamline-sdk-v2.14.16.zip"] = "x";
    const SetupResult real = setup_install(o, c);
    REQUIRE_FALSE(real.ok);
    CHECK(real.code == "checksum_mismatch");
    CHECK(installed_vendor_sdk_dir(c, *find_vendor_sdk("streamline")).empty());
}

TEST_CASE("setup streamline: the install removes the older versions, and leaves nothing of a failed one") {
    Lab lab;
    const SetupContext c = lab.ctx();
    FakeSdk old(lab, true, "0.9.0");
    REQUIRE(setup_detail::vendor_sdk_install(c, options(true), old.sdk).ok);
    const stdfs::path tools = stdfs::path(fs::path_from_utf8(lab.home)) / "tools" / "streamline";
    REQUIRE(stdfs::is_directory(tools / "0.9.0"));
    stdfs::create_directories(tools / "0.1.0");
    testing::write_all(tools / "0.1.0" / "leftover.dll", "old");

    FakeSdk current(lab, true, "1.0.0");
    REQUIRE(setup_detail::vendor_sdk_install(c, options(true), current.sdk).ok);
    CHECK(stdfs::is_directory(tools / "1.0.0"));
    CHECK_FALSE(stdfs::exists(tools / "0.9.0"));
    CHECK_FALSE(stdfs::exists(tools / "0.1.0"));

    // A newer pin whose download fails keeps the working install.
    FakeSdk next(lab, true, "1.1.0");
    lab.served.erase(kArchiveUrl);
    CHECK_FALSE(setup_detail::vendor_sdk_install(c, options(true), next.sdk).ok);
    CHECK(stdfs::is_directory(tools / "1.0.0"));
    CHECK_FALSE(stdfs::exists(tools / "1.1.0"));
}

TEST_CASE("setup fidelityfx: every file alone against its own pin (no archive); one wrong refuses all") {
    Lab lab;
    FakeSdk fake(lab, false);
    const SetupContext c = lab.ctx();
    SetupResult r = setup_detail::vendor_sdk_install(c, options(true), fake.sdk);
    REQUIRE(r.ok);
    CHECK(lab.requested.size() == 3);
    const stdfs::path d = fs::path_from_utf8(installed_vendor_sdk_dir(c, fake.sdk));
    CHECK(testing::read_all(d / "sl.dlss.dll") == "dlss 1.0.0");

    Lab lab2;
    FakeSdk bad(lab2, false);
    lab2.served[std::string(kBaseUrl) + "/bin/x64/sl.interposer.dll"] = "tampered";
    const SetupContext c2 = lab2.ctx();
    r = setup_detail::vendor_sdk_install(c2, options(true), bad.sdk);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(installed_vendor_sdk_dir(c2, bad.sdk).empty());
    CHECK_FALSE(stdfs::exists(fs::path_from_utf8(vendor_sdk_install_dir(c2, bad.sdk))));
}

TEST_CASE("setup streamline: a table that names a profiler file is never installed") {
    Lab lab;
    FakeSdk fake(lab);
    fake.files.push_back(VendorSdkFile{"bin/x64/sl.nvperf.dll", nullptr, ""});
    fake.refresh();
    const SetupResult r = setup_detail::vendor_sdk_install(lab.ctx(), options(true), fake.sdk);
    REQUIRE_FALSE(r.ok);
    CHECK(has_text(r.error.message, "never installs"));
    CHECK(lab.requested.empty());
}

TEST_CASE(
    "setup streamline: the status shows the pinned license text with the obligations, and says why when it cannot") {
    Lab lab;
    FakeSdk fake(lab);
    lab.host = "windows";
    SetupContext c = lab.ctx();
    SetupComponent s = setup_detail::vendor_sdk_status(c, fake.sdk, true);
    CHECK(s.state == "missing");
    CHECK(s.canInstall);
    REQUIRE(s.licenses.size() == 1);
    CHECK(s.licenses[0].id == "test-license");
    CHECK(has_text(s.licenses[0].text, "Obligation: credit the vendor."));
    CHECK(has_text(s.licenses[0].text, "Ship it with the game."));

    // Not asked for: no request, no text.
    lab.requested.clear();
    s = setup_detail::vendor_sdk_status(c, fake.sdk, false);
    CHECK(s.licenses.empty());
    CHECK(lab.requested.empty());

    // A text that is not the pinned one is not shown.
    lab.served[kLicenseUrl] = "something else";
    s = setup_detail::vendor_sdk_status(c, fake.sdk, true);
    CHECK(s.licenses.empty());
    bool pinned = false;
    for (const std::string& p : s.problems) pinned = pinned || has_text(p, "not the license");
    CHECK(pinned);

    // Cannot be fetched: the problem names the address, so the user can read it there.
    lab.served.erase(kLicenseUrl);
    s = setup_detail::vendor_sdk_status(c, fake.sdk, true);
    CHECK(s.licenses.empty());
    bool address = false;
    for (const std::string& p : s.problems) address = address || has_text(p, kLicenseUrl);
    CHECK(address);

    // Elsewhere than Windows nothing runs the DLLs: "unsupported", though the install still works.
    lab.host = "linux";
    c = lab.ctx();
    s = setup_detail::vendor_sdk_status(c, fake.sdk, false);
    CHECK(s.state == "unsupported");
    CHECK(s.canInstall);

    REQUIRE(setup_detail::vendor_sdk_install(c, options(true), fake.sdk).ok);
    s = setup_detail::vendor_sdk_status(c, fake.sdk, false);
    CHECK(s.state == "installed");
    REQUIRE_FALSE(s.paths.empty());
}

TEST_CASE("setup streamline: an installed SDK lists its license when asked, so a reinstall can ask for it again") {
    Lab lab;
    FakeSdk fake(lab);
    lab.host = "windows";
    SetupContext c = lab.ctx();
    REQUIRE(setup_detail::vendor_sdk_install(c, options(true), fake.sdk).ok);

    lab.requested.clear();
    SetupComponent s = setup_detail::vendor_sdk_status(c, fake.sdk, false);
    CHECK(s.state == "installed");
    CHECK(s.licenses.empty());
    CHECK(lab.requested.empty());  // a polling UI stays offline

    s = setup_detail::vendor_sdk_status(c, fake.sdk, true);
    CHECK(s.state == "installed");
    REQUIRE(s.licenses.size() == 1);
    CHECK(s.licenses[0].id == "test-license");
    CHECK(has_text(s.licenses[0].text, "Ship it with the game."));
    CHECK(lab.requested.size() == 1);

    // Cannot be fetched: the problem says so, and there is no license to agree to.
    lab.served.erase(kLicenseUrl);
    s = setup_detail::vendor_sdk_status(c, fake.sdk, true);
    CHECK(s.state == "installed");
    CHECK(s.licenses.empty());
    CHECK_FALSE(s.problems.empty());
}

TEST_CASE("setup.status: without a component no vendor SDK's license is fetched; with one it is") {
    Lab lab;
    lab.host = "windows";
    const SetupContext c = lab.ctx();
    const SetupStatus all = setup_status(c, {}, true);
    for (const char* id : {"streamline", "xess", "fidelityfx"}) {
        CAPTURE(id);
        const SetupComponent* sc = all.find(id);
        REQUIRE(sc != nullptr);
        CHECK(sc->licenses.empty());
        const VendorSdk* sdk = find_vendor_sdk(id);
        REQUIRE(sdk != nullptr);
        for (const std::string& url : lab.requested) CHECK(url != sdk->licenseUrl);
    }
    lab.requested.clear();
    (void)setup_status(c, "streamline", true);
    const VendorSdk* sl = find_vendor_sdk("streamline");
    REQUIRE(sl != nullptr);
    CHECK(std::count(lab.requested.begin(), lab.requested.end(), std::string(sl->licenseUrl)) == 1);
}

TEST_CASE("setup: the three vendor SDKs are components of setup.status and setup.install, license first") {
    Lab lab;
    lab.host = "windows";
    const SetupContext c = lab.ctx();
    for (const char* id : {"streamline", "xess", "fidelityfx"}) {
        CAPTURE(id);
        const SetupStatus st = setup_status(c, id, false);
        REQUIRE(st.components.size() == 1);
        CHECK(st.components[0].id == id);
        CHECK(st.components[0].state == "missing");
        CHECK(st.components[0].installSizeMb > 0);
        SetupInstallOptions o;
        o.component = id;
        const SetupResult r = setup_install(o, c);
        REQUIRE_FALSE(r.ok);
        CHECK(r.code == "license_required");
        CHECK(has_text(r.error.hint, std::string("factoria setup ") + id + " --accept-licenses"));
    }
    CHECK(lab.requested.empty());
}

TEST_CASE("vendor_sdks_used_by_project: what factoria.json says the game can use, tolerant of what is missing") {
    using Ids = std::vector<std::string>;
    CHECK(vendor_sdks_used_by_project(Json::object()).empty());
    CHECK(vendor_sdks_used_by_project(Json::array()).empty());
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": 5})")).empty());
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": "dlss"}})")).empty());
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": 3}}})")).empty());
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": "off"}}})")).empty());
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": "auto"}}})")) ==
          Ids{"streamline", "xess", "fidelityfx"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": "dlss"}}})")) ==
          Ids{"streamline"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": "XeSS"}}})")) == Ids{"xess"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": "fsr"}}})")) ==
          Ids{"fidelityfx"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"frameGeneration": {"mode": "fsr"}}})")) ==
          Ids{"fidelityfx"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"latency": {"mode": "reflex"}}})")) ==
          Ids{"streamline"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"latency": {"mode": "xell"}}})")) == Ids{"xess"});
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"latency": {"mode": "auto"}}})")) ==
          Ids{"streamline", "xess"});
    // Several sections: each id once, in the table's order; the reasons say which pointer asked for it.
    std::vector<std::pair<std::string, std::string>> why;
    CHECK(vendor_sdks_used_by_project(Json::parse(R"({"render": {"upscaler": {"mode": "fsr"},
                                         "frameGeneration": {"mode": "dlss"}, "latency": {"mode": "reflex"}}})"),
                                      &why) == Ids{"streamline", "fidelityfx"});
    REQUIRE(why.size() == 2);
    CHECK(why[0].first == "streamline");
    CHECK(has_text(why[0].second, "/render/frameGeneration/mode"));
    CHECK(why[1].second == "/render/upscaler/mode = \"fsr\"");
}
