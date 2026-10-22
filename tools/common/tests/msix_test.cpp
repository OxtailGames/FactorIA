// The MSIX package of `project.export --platform windows --format msix` (export_msix.cpp) and sign.windows. The package is read back
// with a small zip reader of this file (stored entries, the central directory) so the bytes are checked independently of the writer:
// entry order, every 64 KiB block hash of AppxBlockMap.xml, LfhSize, the manifest, [Content_Types].xml and determinism. The player
// is a fake; nothing here needs Windows. sign.windows runs with fake process runners.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <map>

#include "fa/core/hash.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/sign.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has_text(const std::string& h, const std::string& n) { return h.find(n) != std::string::npos; }

std::uint32_t rd16(const std::string& s, std::size_t at) {
    return static_cast<unsigned char>(s[at]) | (static_cast<unsigned char>(s[at + 1]) << 8);
}
std::uint32_t rd32(const std::string& s, std::size_t at) { return rd16(s, at) | (rd16(s, at + 2) << 16); }

struct PackedEntry {
    std::string name, data;
    std::uint32_t headerSize = 0;  // 30 + name length, as the local header says
    std::uint16_t method = 99;
};

std::uint64_t rd64(const std::string& s, std::size_t at) { return rd32(s, at) | (static_cast<std::uint64_t>(rd32(s, at + 4)) << 32); }

// Reads a zip of stored entries through its ZIP64 end of central directory (an MSIX package always has one) and its central
// directory; the local headers are checked against it.
std::vector<PackedEntry> read_zip(const std::string& bytes) {
    std::vector<PackedEntry> out;
    REQUIRE(bytes.size() > 22 + 20 + 56);
    const std::size_t eocd = bytes.size() - 22;
    REQUIRE(rd32(bytes, eocd) == 0x06054b50);
    CHECK(rd16(bytes, eocd + 10) == 0xFFFF);
    CHECK(rd32(bytes, eocd + 16) == 0xFFFFFFFF);
    const std::size_t locator = eocd - 20;
    REQUIRE(rd32(bytes, locator) == 0x07064b50);
    const std::size_t record = static_cast<std::size_t>(rd64(bytes, locator + 8));
    REQUIRE(record == locator - 56);
    REQUIRE(rd32(bytes, record) == 0x06064b50);
    const std::uint64_t count = rd64(bytes, record + 32);
    std::size_t at = static_cast<std::size_t>(rd64(bytes, record + 48));
    CHECK(at + rd64(bytes, record + 40) == record);
    for (std::uint64_t i = 0; i < count; ++i) {
        REQUIRE(rd32(bytes, at) == 0x02014b50);
        PackedEntry e;
        e.method = static_cast<std::uint16_t>(rd16(bytes, at + 10));
        const std::uint32_t size = rd32(bytes, at + 24), nameLen = rd16(bytes, at + 28), extra = rd16(bytes, at + 30), comment = rd16(bytes, at + 32);
        const std::uint32_t local = rd32(bytes, at + 42);
        e.name = bytes.substr(at + 46, nameLen);
        REQUIRE(rd32(bytes, local) == 0x04034b50);
        const std::uint32_t lname = rd16(bytes, local + 26), lextra = rd16(bytes, local + 28);
        CHECK(lname == nameLen);
        e.headerSize = 30 + lname + lextra;
        e.data = bytes.substr(local + e.headerSize, size);
        out.push_back(std::move(e));
        at += 46 + nameLen + extra + comment;
    }
    return out;
}

std::string raw_sha256_base64(std::string_view data) {
    const std::string hex = sha256_hex(data);
    std::string raw;
    for (std::size_t i = 0; i + 1 < hex.size(); i += 2) raw += static_cast<char>(std::stoi(hex.substr(i, 2), nullptr, 16));
    return base64_encode(raw.data(), raw.size());
}

// Decodes %XX of a zip part name.
std::string decode_part(const std::string& s) {
    std::string out;
    for (std::size_t i = 0; i < s.size(); ++i) {
        if (s[i] == '%' && i + 2 < s.size()) {
            out += static_cast<char>(std::stoi(s.substr(i + 1, 2), nullptr, 16));
            i += 2;
        } else {
            out += s[i];
        }
    }
    return out;
}

struct Game {
    testing::TempDir tmp;
    std::string proj, out;

    explicit Game(const std::string& factoriaPatch = "") {
        proj = tmp.sub("proj");
        ScaffoldOptions so;
        so.name = "Space Dodge";
        so.id = "com.example.spacedodge";
        auto created = create_project(proj, "2d-platformer", so);
        REQUIRE_MESSAGE(created.ok(), (created.ok() ? "" : created.error().to_string()));
        if (!factoriaPatch.empty()) {
            auto j = load_json_file(proj + "/factoria.json");
            REQUIRE(j.ok());
            json_merge(*j, *parse_json(factoriaPatch));
            REQUIRE(save_json_file(proj + "/factoria.json", *j).ok());
        }
        testing::write_all(tmp.sub("fake_player/factoria_player"), "#!/bin/sh\nexit 0\n");
        out = tmp.sub("out");
    }

    ExportOptions options(const std::string& outDir = "") const {
        ExportOptions o;
        o.projectDir = proj;
        o.platform = "windows";
        o.format = "msix";
        o.outDir = outDir.empty() ? out : outDir;
        o.playerBinary = tmp.sub("fake_player/factoria_player");
        return o;
    }

    std::string msix() const { return out + "/space-dodge-windows.msix"; }
};

const char* kIdentity = R"({"export": {"windows": {"msix": {"identityName": "12345Studio.SpaceDodge",
    "publisher": "CN=0123ABCD-4567-89EF-0123-456789ABCDEF", "publisherDisplayName": "Studio & Co"}}}})";

ExportEnvLookup env_of(std::map<std::string, std::string> vars) {
    return [vars = std::move(vars)](const std::string& name) {
        auto it = vars.find(name);
        return it == vars.end() ? std::string() : it->second;
    };
}

}  // namespace

TEST_CASE("msix: the package has the documented entries in the documented order") {
    Game g(kIdentity);
    auto r = export_project(g.options());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->format == "msix");
    CHECK(stdfs::equivalent(r->artifact, g.msix()));
    REQUIRE(stdfs::exists(g.msix()));
    CHECK(stdfs::exists(g.out + "/space-dodge-windows/space-dodge.exe"));  // the folder is still there

    const auto zip = read_zip(testing::read_all(g.msix()));
    REQUIRE(zip.size() > 10);
    for (const auto& e : zip) CHECK_MESSAGE(e.method == 0, e.name);  // stored: the block map needs no compressed sizes
    const std::size_t n = zip.size();
    CHECK(zip[n - 3].name == "AppxManifest.xml");
    CHECK(zip[n - 2].name == "AppxBlockMap.xml");
    CHECK(zip[n - 1].name == "[Content_Types].xml");
    std::vector<std::string> payload;
    for (std::size_t i = 0; i + 3 < n; ++i) payload.push_back(decode_part(zip[i].name));
    CHECK(std::is_sorted(payload.begin(), payload.end()));
    CHECK(std::find(payload.begin(), payload.end(), "space-dodge.exe") != payload.end());
    CHECK(std::find(payload.begin(), payload.end(), "game/factoria.json") != payload.end());
    CHECK(std::find(payload.begin(), payload.end(), "Assets/StoreLogo.png") != payload.end());
    CHECK(std::find(payload.begin(), payload.end(), "Assets/Square44x44Logo.png") != payload.end());
    CHECK(std::find(payload.begin(), payload.end(), "Assets/Square150x150Logo.png") != payload.end());
    for (const std::string& p : payload) {
        CHECK(p != ".factoria-export");
        CHECK(p != "AI_CONTENT_DISCLOSURE.md");
    }
    // The first bytes of every logo are a PNG.
    for (const auto& e : zip)
        if (starts_with(e.name, "Assets/")) CHECK(e.data.compare(0, 8, "\x89PNG\r\n\x1a\n") == 0);
    // No timestamps: the DOS date of every entry is 1980-01-01.
    const std::string bytes = testing::read_all(g.msix());
    CHECK(rd16(bytes, 10) == 0);
    CHECK(rd16(bytes, 12) == 0x21);
}

TEST_CASE("msix: every block of AppxBlockMap.xml is the SHA-256 of 64 KiB of its file") {
    Game g(kIdentity);
    // A payload file of more than two blocks and one with a name that needs percent-encoding.
    std::string big(150000, 'x');
    for (std::size_t i = 0; i < big.size(); ++i) big[i] = static_cast<char>('a' + (i * 7) % 23);
    testing::write_all(g.proj + "/assets/big data.bin", big);
    auto r = export_project(g.options());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));

    const auto zip = read_zip(testing::read_all(g.msix()));
    std::map<std::string, const PackedEntry*> byName;
    for (const auto& e : zip) byName[decode_part(e.name)] = &e;
    REQUIRE(byName.count("AppxBlockMap.xml"));
    const std::string map = byName["AppxBlockMap.xml"]->data;
    CHECK(has_text(map, "http://schemas.microsoft.com/appx/2010/blockmap"));
    CHECK(has_text(map, "HashMethod=\"http://www.w3.org/2001/04/xmlenc#sha256\""));

    std::size_t files = 0;
    for (const auto& [name, e] : byName) {
        if (name == "AppxBlockMap.xml" || name == "[Content_Types].xml") continue;  // not part of the block map
        ++files;
        std::string back = name;
        std::replace(back.begin(), back.end(), '/', '\\');
        const std::string open = "<File Name=\"" + back + "\" Size=\"" + std::to_string(e->data.size()) + "\" LfhSize=\"" +
                                 std::to_string(e->headerSize) + "\">";
        INFO(name);
        const std::size_t at = map.find(open);
        REQUIRE(at != std::string::npos);
        const std::size_t end = map.find("</File>", at);
        REQUIRE(end != std::string::npos);
        const std::string body = map.substr(at + open.size(), end - at - open.size());
        std::string expected;
        for (std::size_t off = 0; off < e->data.size(); off += 65536)
            expected += "<Block Hash=\"" + raw_sha256_base64(std::string_view(e->data).substr(off, 65536)) + "\"/>";
        CHECK(body == expected);
    }
    CHECK(files == zip.size() - 2);
    // The big file is three blocks, the name with a space is stored percent-encoded and listed plainly.
    CHECK(byName.count("game/assets/big data.bin"));
    bool encoded = false;
    for (const auto& e : zip) encoded = encoded || e.name == "game/assets/big%20data.bin";
    CHECK(encoded);
    CHECK(byName["game/assets/big data.bin"]->data == big);
}

TEST_CASE("msix: manifest and content types") {
    Game g(kIdentity);
    REQUIRE(export_project(g.options()).ok());
    const auto zip = read_zip(testing::read_all(g.msix()));
    std::string manifest, types;
    for (const auto& e : zip) {
        if (e.name == "AppxManifest.xml") manifest = e.data;
        if (e.name == "[Content_Types].xml") types = e.data;
    }
    REQUIRE_FALSE(manifest.empty());
    CHECK(has_text(manifest, "Name=\"12345Studio.SpaceDodge\""));
    CHECK(has_text(manifest, "Publisher=\"CN=0123ABCD-4567-89EF-0123-456789ABCDEF\""));
    CHECK(has_text(manifest, "<PublisherDisplayName>Studio &amp; Co</PublisherDisplayName>"));
    CHECK(has_text(manifest, "ProcessorArchitecture=\"x64\""));
    CHECK(has_text(manifest, ".0\" ProcessorArchitecture=\"x64\""));  // the project's version with revision 0
    CHECK(has_text(manifest, "<DisplayName>Space Dodge</DisplayName>"));
    CHECK(has_text(manifest, "Name=\"Windows.Desktop\" MinVersion=\"10.0.17763.0\""));
    CHECK(has_text(manifest, "Executable=\"space-dodge.exe\""));
    CHECK(has_text(manifest, "EntryPoint=\"Windows.FullTrustApplication\""));
    CHECK(has_text(manifest, "rescap:Capability Name=\"runFullTrust\""));
    CHECK(has_text(manifest, "Square150x150Logo=\"Assets\\Square150x150Logo.png\""));
    CHECK(has_text(manifest, "<Logo>Assets\\StoreLogo.png</Logo>"));
    CHECK_FALSE(has_text(manifest, "FactorIA Developer"));  // identity set: no placeholder

    CHECK(has_text(types, "ContentType=\"image/png\" Extension=\"png\""));
    CHECK(has_text(types, "ContentType=\"application/vnd.ms-appx.manifest+xml\" PartName=\"/AppxManifest.xml\""));
    CHECK(has_text(types, "ContentType=\"application/vnd.ms-appx.blockmap+xml\" PartName=\"/AppxBlockMap.xml\""));
    CHECK(has_text(types, "Extension=\"exe\""));
}

TEST_CASE("msix: without an identity the package gets a placeholder and a warning") {
    Game g;
    auto r = export_project(g.options());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    bool warned = false;
    for (const auto& w : r->warnings) warned = warned || (has_text(w, "identityName") && has_text(w, "placeholder"));
    CHECK(warned);
    std::string manifest;
    for (const auto& e : read_zip(testing::read_all(g.msix())))
        if (e.name == "AppxManifest.xml") manifest = e.data;
    CHECK(has_text(manifest, "Name=\"FactorIA.spacedodge\""));
    CHECK(has_text(manifest, "Publisher=\"CN=FactorIA Developer\""));
}

TEST_CASE("msix: the same game gives the same bytes, in any output folder") {
    Game g(kIdentity);
    REQUIRE(export_project(g.options()).ok());
    const std::string first = testing::read_all(g.msix());
    const std::string other = g.tmp.sub("out2");
    REQUIRE(export_project(g.options(other)).ok());
    CHECK(testing::read_all(other + "/space-dodge-windows.msix") == first);
    REQUIRE(export_project(g.options()).ok());
    CHECK(testing::read_all(g.msix()) == first);
}

TEST_CASE("msix: format comes from export.windows.format, plan_export reports the artifact, folder writes no package") {
    Game g(R"({"export": {"windows": {"format": "msix"}}})");
    ExportOptions o = g.options();
    o.format = "";
    auto plan = plan_export(o);
    REQUIRE_MESSAGE(plan.ok(), (plan.ok() ? "" : plan.error().to_string()));
    CHECK(plan->format == "msix");
    CHECK(stdfs::weakly_canonical(plan->artifact) == stdfs::weakly_canonical(g.msix()));
    REQUIRE(export_project(o).ok());
    CHECK(stdfs::exists(g.msix()));

    Game folder;
    ExportOptions f = folder.options();
    f.format = "folder";
    auto fr = export_project(f);
    REQUIRE(fr.ok());
    CHECK(fr->artifact.empty());
    CHECK_FALSE(stdfs::exists(folder.msix()));
}

TEST_CASE("msix: other platforms do not take the msix format") {
    Game g;
    ExportOptions o = g.options();
    o.platform = "linux";
    o.format = "msix";
    auto r = export_project(o);
    // Either it is refused with a teaching message or ignored (one format per platform); it never writes an .msix.
    if (!r.ok()) CHECK(has_text(r.error().message, "msix"));
    CHECK_FALSE(stdfs::exists(g.msix()));
}

TEST_CASE("msix settings: parse, save and the teaching errors") {
    auto j = parse_json(R"({"export": {"windows": {"format": "msix", "msix": {"identityName": "12345Studio.SpaceDodge",
        "publisher": "CN=ABC", "publisherDisplayName": "Studio", "version": "2.3.4.0", "backgroundColor": "#112233",
        "languages": ["en-us", "es-es"]}}}})", "test");
    REQUIRE(j.ok());
    auto p = parse_export_settings(*j);
    CHECK(p.errors.empty());
    CHECK(p.settings.windows.format == "msix");
    CHECK(p.settings.windows.msix.identityName == "12345Studio.SpaceDodge");
    CHECK(p.settings.windows.msix.backgroundColor == "#112233");
    CHECK(p.settings.msix_version() == "2.3.4.0");
    CHECK(p.settings.msix_languages() == std::vector<std::string>{"en-us", "es-es"});

    // Derived values.
    ProjectExportSettings d;
    d.projectVersion = "1.2.3";
    CHECK(d.msix_version() == "1.2.3.0");
    CHECK(d.msix_languages() == std::vector<std::string>{"en-us"});
    CHECK(is_msix_version("1.0.0.0"));
    CHECK_FALSE(is_msix_version("1.0.0"));

    // Saving writes it back and reading again gives the same settings.
    testing::TempDir tmp;
    testing::write_all(tmp.sub("factoria.json"), R"({"format": "factoria.project/1", "name": "X", "id": "com.example.x", "version": "1.0.0"})");
    REQUIRE(save_export_settings(tmp.str(), p.settings).ok());
    auto back = load_export_settings(tmp.str());
    REQUIRE_MESSAGE(back.ok(), (back.ok() ? "" : back.error().to_string()));
    CHECK(back->windows.format == "msix");
    CHECK(back->windows.msix == p.settings.windows.msix);

    auto bad = parse_json(R"({"export": {"windows": {"format": "msx", "msix": {"identityName": "a b", "publisher": "Studio",
        "version": "1.2", "backgroundColor": "red", "minVersion": "10", "languages": "en-us"}}}})", "test");
    REQUIRE(bad.ok());
    auto pe = parse_export_settings(*bad);
    for (const char* ptr : {"/export/windows/format", "/export/windows/msix/identityName", "/export/windows/msix/publisher", "/export/windows/msix/version",
                            "/export/windows/msix/backgroundColor", "/export/windows/msix/minVersion", "/export/windows/msix/languages"}) {
        INFO(ptr);
        const ExportSettingsIssue* found = nullptr;
        for (const auto& i : pe.errors)
            if (i.pointer == ptr) found = &i;
        REQUIRE(found);
        CHECK_FALSE(found->hint.empty());
    }
    for (const auto& i : pe.errors)
        if (i.pointer == "/export/windows/format") CHECK(has_text(i.hint, "msix"));
}

TEST_CASE("msix settings: validate warns when msix is chosen and the identity is missing") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    auto j = load_json_file(dir + "/factoria.json");
    REQUIRE(j.ok());
    json_merge(*j, *parse_json(R"({"export": {"windows": {"format": "msix"}}})"));
    REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    bool warned = false;
    for (const auto& w : r.warnings) warned = warned || (w.pointer == "/export/windows/msix" && has_text(w.message, "identityName"));
    CHECK(warned);

    json_merge(*j, *parse_json(kIdentity));
    REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    r = validate_project(dir);
    for (const auto& w : r.warnings) CHECK(w.pointer != "/export/windows/msix");
}

// ---- sign.windows -------------------------------------------------------------------------------------------------------

namespace {

constexpr const char* kPfxPassword = "s3cr3t-pfx-pass";

struct SignGame : Game {
    std::string pfx;
    SignGame() : Game(kIdentity) {
        REQUIRE(export_project(options()).ok());
        pfx = tmp.sub("keys") + "/code.pfx";
        testing::write_all(pfx, "not a real pfx");
    }

    SignWindowsOptions sign_options(const std::string& host) {
        SignWindowsOptions o;
        o.projectDir = proj;
        o.outDir = out;
        o.pfx = pfx;
        o.host = host;
        o.toolConfigPath = tmp.sub("no-export.json");
        std::map<std::string, std::string> vars = {{"FACTORIA_WINDOWS_PFX_PASSWORD", kPfxPassword}};
        const std::string fake = tmp.sub("tools") + (host == "windows" ? "/signtool.exe" : "/osslsigncode");
        testing::write_all(fake, "tool");
        vars[host == "windows" ? "FACTORIA_SIGNTOOL" : "FACTORIA_OSSLSIGNCODE"] = fake;
        o.env = env_of(vars);
        return o;
    }
};

std::string joined(const std::vector<std::string>& v) {
    std::string s;
    for (const auto& a : v) s += (s.empty() ? "" : " ") + a;
    return s;
}

}  // namespace

TEST_CASE("sign.windows dry run: signtool on Windows, osslsigncode elsewhere, the password never shown") {
    SignGame g;
    {
        SignWindowsOptions o = g.sign_options("windows");
        o.dryRun = true;
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->tool == "signtool");
        CHECK(r->publisher == "CN=0123ABCD-4567-89EF-0123-456789ABCDEF");
        REQUIRE(r->steps.size() == 1);
        const std::string line = joined(r->steps[0].command);
        CHECK(has_text(line, "sign /fd SHA256 /f "));
        CHECK(has_text(line, "/p <redacted>"));
        CHECK(has_text(line, "/tr http://timestamp.digicert.com /td SHA256"));
        CHECK(has_text(line, "space-dodge-windows.msix"));
        CHECK_FALSE(has_text(line, kPfxPassword));
        CHECK_FALSE(has_text(r->to_json().dump(), kPfxPassword));
        CHECK(r->steps[0].ran == false);
    }
    {
        SignWindowsOptions o = g.sign_options("linux");
        o.dryRun = true;
        o.timestampUrl = "http://ts.example.com";
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->tool == "osslsigncode");
        REQUIRE_FALSE(r->steps.empty());
        const std::string line = joined(r->steps.back().command);
        CHECK(has_text(line, "sign -pkcs12 "));
        CHECK(has_text(line, "-pass <redacted>"));
        CHECK(has_text(line, "-h sha256 -ts http://ts.example.com"));
        CHECK_FALSE(has_text(r->to_json().dump(), kPfxPassword));
    }
}

TEST_CASE("sign.windows: errors that say what to do") {
    SignGame g;
    {  // no certificate
        SignWindowsOptions o = g.sign_options("linux");
        o.pfx.clear();
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().hint, "FACTORIA_WINDOWS_PFX"));
    }
    {  // a pfx that is not there
        SignWindowsOptions o = g.sign_options("linux");
        o.pfx = g.tmp.sub("keys") + "/missing.pfx";
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "missing.pfx"));
    }
    {  // a test certificate needs Windows
        SignWindowsOptions o = g.sign_options("linux");
        o.testCertificate = true;
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "Windows"));
    }
    {  // no package
        SignWindowsOptions o = g.sign_options("linux");
        o.msix = g.tmp.sub("nowhere") + "/x.msix";
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "no package"));
    }
    {  // not a package
        SignWindowsOptions o = g.sign_options("linux");
        o.msix = g.pfx;
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, ".msix"));
    }
}

TEST_CASE("sign.windows with a fake runner: osslsigncode output replaces the package, a failure keeps it") {
    SignGame g;
    const std::string before = testing::read_all(g.msix());
    std::vector<ProcessOptions> calls;
    int signExit = 0;
    SignWindowsOptions o = g.sign_options("linux");
    std::string signedBytes = "SIGNED-PACKAGE";
    o.run = [&](const ProcessOptions& po) -> Result<ProcessResult> {
        calls.push_back(po);
        ProcessResult pr;
        pr.exitCode = 0;
        const std::string exe = stdfs::path(po.argv.at(0)).filename().string();
        if (exe == "osslsigncode" && po.argv.size() > 1 && po.argv[1] == "--version") {
            pr.stdoutText = "osslsigncode 2.9.0, using:\n";
        } else if (exe == "osslsigncode" && po.argv.size() > 1 && po.argv[1] == "sign") {
            // It prints the password back, as a careless tool would.
            if (po.onStderrLine) po.onStderrLine(std::string("using password ") + kPfxPassword);
            pr.stderrText = std::string("bad password ") + kPfxPassword;
            pr.exitCode = signExit;
            if (signExit == 0) {
                const auto it = std::find(po.argv.begin(), po.argv.end(), "-out");
                testing::write_all(*(it + 1), signedBytes);
            }
        } else {
            pr.exitCode = 1;  // openssl is not installed on this fake computer
        }
        return pr;
    };
    std::vector<std::string> shown;
    o.progress = [&](const std::string& line) { shown.push_back(line); };
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->signedMsix);
    CHECK(testing::read_all(g.msix()) == signedBytes);
    for (const auto& line : shown) CHECK_FALSE(has_text(line, kPfxPassword));
    CHECK_FALSE(has_text(r->to_json().dump(), kPfxPassword));

    testing::write_all(g.msix(), before);
    signExit = 1;
    SignWindowsOptions f = o;
    auto bad = sign_windows(f);
    REQUIRE_FALSE(bad.ok());
    CHECK_FALSE(has_text(bad.error().message + bad.error().hint, kPfxPassword));
    CHECK(has_text(bad.error().message, "failed"));
    CHECK(testing::read_all(g.msix()) == before);
    CHECK_FALSE(stdfs::exists(g.msix() + ".signed"));
}

TEST_CASE("sign.windows: an old osslsigncode is refused") {
    SignGame g;
    SignWindowsOptions o = g.sign_options("linux");
    o.run = [&](const ProcessOptions& po) -> Result<ProcessResult> {
        ProcessResult pr;
        pr.exitCode = 0;
        if (po.argv.size() > 1 && po.argv[1] == "--version") pr.stdoutText = "osslsigncode 2.8.0\n";
        return pr;
    };
    auto r = sign_windows(o);
    REQUIRE_FALSE(r.ok());
    CHECK(has_text(r.error().message, "2.8"));
    CHECK(has_text(r.error().hint, "osslsigncode"));
}

TEST_CASE("sign.windows is registered as a command") {
    CommandRegistry registry;
    register_sign_windows_command(registry, "/nowhere");
    CHECK(registry.has("sign.windows"));
}
