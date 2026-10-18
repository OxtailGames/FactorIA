// Web exports (docs/EXPORTING.md, "Web"): the Emscripten player (factoria_player.js + .wasm), the page that loads it
// (platforms/web/shell.html, embedded in the factoria binary), the whole game in one game.pak, and a zip of the folder with
// index.html at its root, which itch.io accepts as an HTML5 game.
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <map>

#include "export_internal.h"
#include "fa/core/pack.h"
#include "fa/tooling/ai_disclosure.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/setup.h"

// miniz, as vendored by the Basis Universal encoder this library already links: raw deflate and CRC-32 for the zip.
#define MINIZ_HEADER_FILE_ONLY
#define MINIZ_NO_ZLIB_COMPATIBLE_NAMES
#include <encoder/basisu_miniz.h>

namespace fa::export_detail {

namespace {

constexpr const char* kShellPath = "platforms/web/shell.html";

// The two files of a web player in `dir`, or an Error naming what is missing.
Result<WebPlayer> player_in(const stdfs::path& dir, const std::string& from) {
    std::error_code ec;
    WebPlayer w;
    w.js = dir / "factoria_player.js";
    w.wasm = dir / "factoria_player.wasm";
    w.from = from;
    for (const stdfs::path* f : {&w.js, &w.wasm})
        if (!stdfs::is_regular_file(os_path(*f), ec))
            return err("export: the web player is incomplete: " + generic(*f) + " not found",
                       "a web player is two files, factoria_player.js and factoria_player.wasm, in one folder; pass that folder with --player");
    return w;
}

bool has_player(const stdfs::path& dir) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(dir / "factoria_player.js"), ec) && stdfs::is_regular_file(os_path(dir / "factoria_player.wasm"), ec);
}

// Replaces {{name}} in one pass, so a game called "{{pakBytes}}" stays what it is. Names without a value are left as they are
// and listed in `unknown`.
std::string fill_page(const std::string& shell, const std::map<std::string, std::string>& values, std::vector<std::string>& unknown) {
    std::string out;
    std::size_t i = 0;
    while (i < shell.size()) {
        const std::size_t open = shell.find("{{", i);
        const std::size_t close = open == std::string::npos ? open : shell.find("}}", open + 2);
        if (close == std::string::npos) {
            out.append(shell, i, std::string::npos);
            break;
        }
        out.append(shell, i, open - i);
        const std::string name = shell.substr(open + 2, close - open - 2);
        if (const auto it = values.find(name); it != values.end()) {
            out += it->second;
        } else {
            out.append(shell, open, close + 2 - open);
            if (std::find(unknown.begin(), unknown.end(), name) == unknown.end()) unknown.push_back(name);
        }
        i = close + 2;
    }
    return out;
}

std::uint64_t file_size_of(const stdfs::path& p) {
    std::error_code ec;
    const auto n = stdfs::file_size(os_path(p), ec);
    return ec ? 0 : static_cast<std::uint64_t>(n);
}

}  // namespace

Result<WebPlayer> find_web_player(const ExportOptions& o, const std::string& sourceRoot) {
    std::error_code ec;
    if (!o.playerBinary.empty()) {
        stdfs::path given(o.playerBinary);
        if (stdfs::is_regular_file(os_path(given), ec)) {
            const std::string ext = to_lower(given.extension().string());
            if (ext != ".js" && ext != ".wasm")
                return err("export: --player '" + o.playerBinary + "' is not a web player",
                           "for --platform web pass the folder that holds factoria_player.js and factoria_player.wasm, or factoria_player.js itself");
            given = given.parent_path();
        } else if (!stdfs::is_directory(os_path(given), ec)) {
            return err("export: web player '" + o.playerBinary + "' not found",
                       "pass --player <folder> with factoria_player.js and factoria_player.wasm (the build tree's player/ folder, or web/ of the FactorIA download)");
        }
        return player_in(given, "explicit");
    }
    std::vector<std::string> searched;
    const stdfs::path exeDir = executable_dir();
    // The download carries web/ next to factoria, like mobile/.
    if (has_player(exeDir / "web")) return player_in(exeDir / "web", "package");
    searched.push_back(generic(exeDir / "web"));
    if (const std::string installed = installed_player("web"); !installed.empty()) return player_in(stdfs::path(installed).parent_path(), "installed");
    searched.push_back("<FactorIA home>/players/<version>/web (`factoria setup players --platforms web`)");
    // A web build of the engine source (Emscripten, preset web-release) in the checkout factoria was built from.
    if (!sourceRoot.empty())
        for (const char* build : {"web-release", "web"})
            if (const stdfs::path dir = stdfs::path(sourceRoot) / "build" / build / "player"; has_player(dir))
                return player_in(dir, "build");
    searched.push_back(generic(stdfs::path(sourceRoot) / "build" / "web-release" / "player") + " (a web build of the engine source)");
    return err("export: no web player found: factoria_player.js and factoria_player.wasm are not in " + join(searched, ", "),
               "run `factoria setup players --platforms web` (the editor: Set up in the Export window) to install the web player of this FactorIA "
               "version, or build it with Emscripten (docs/BUILDING.md, preset web-release) and pass its player/ folder with --player <folder>");
}

Result<void> export_web(const Project& p, const WebPlayer& player, const stdfs::path& outRoot, const std::vector<std::string>& files,
                        ExportReport& report) {
    std::error_code ec;
    stdfs::create_directories(os_path(outRoot), ec);
    // The game first: its size goes into the page.
    if (auto r = pack_project(p, files, outRoot / kPackFileName, report); !r.ok()) return r;
    for (const stdfs::path* f : {&player.js, &player.wasm}) {
        stdfs::copy_file(os_path(*f), os_path(outRoot / f->filename()), stdfs::copy_options::overwrite_existing, ec);
        if (ec) return err("export: cannot copy the web player " + generic(*f) + " to " + generic(outRoot) + ": " + ec.message());
    }
    const auto shell = bundled_read(kShellPath);
    if (!shell)
        return err(std::string("export: the page template ") + kShellPath + " is not in this factoria",
                   "this build of factoria lacks the platforms/ folder: build it from a complete checkout, or use the FactorIA download");
    std::vector<std::string> unknown;
    const std::string page = fill_page(*shell,
                                       {{"title", xml_escape(p.name)},
                                        {"wasmBytes", std::to_string(file_size_of(player.wasm))},
                                        {"pakBytes", std::to_string(file_size_of(outRoot / kPackFileName))}},
                                       unknown);
    if (!unknown.empty())
        report.warnings.push_back("The page template has placeholders this factoria does not fill in ({{" + join(unknown, "}}, {{") +
                                  "}}), so index.html shows them as they are. Update factoria, or the template platforms/web/shell.html");
    if (auto r = write_text(outRoot / "index.html", page); !r.ok()) return r;
    report.mode = player.from;
    report.nextSteps.push_back("Try it: a browser does not run it from a file (it fetches the .wasm and game.pak), so serve the folder: "
                               "python -m http.server 8080 --directory \"" + generic(outRoot) + "\" and open http://localhost:8080/");
    return {};
}

// ---- the zip -------------------------------------------------------------------------------------------

namespace {

void put16(std::string& o, std::uint32_t v) {
    o += static_cast<char>(v & 0xFF);
    o += static_cast<char>((v >> 8) & 0xFF);
}

void put32(std::string& o, std::uint32_t v) {
    put16(o, v & 0xFFFF);
    put16(o, v >> 16);
}

struct ZipEntry {
    std::string name;
    std::uint32_t crc = 0, compressedSize = 0, size = 0, offset = 0;
    std::uint16_t method = 0;  // 0 stored, 8 deflate
};

constexpr std::uint32_t kDosDate = (0 << 9) | (1 << 5) | 1;  // 1980-01-01: the same bytes for the same game, whenever it is zipped
constexpr std::uint32_t kUtf8Names = 0x0800;

}  // namespace

Result<void> zip_web(const stdfs::path& outRoot, const stdfs::path& zipFile, ExportReport& report) {
    // index.html first; the files that are for the developer (not for players) stay out.
    std::vector<std::string> names;
    {
        std::error_code ec;
        const stdfs::path base = os_path(outRoot);
        for (stdfs::recursive_directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec)) names.push_back(generic(it->path().lexically_relative(base)));
    }
    names.erase(std::remove_if(names.begin(), names.end(),
                               [](const std::string& n) { return n == kExportMarkerFile || n == kAiDisclosureFile; }),
                names.end());
    std::sort(names.begin(), names.end(), [](const std::string& a, const std::string& b) {
        return std::make_pair(a != "index.html", a) < std::make_pair(b != "index.html", b);
    });
    if (names.empty() || names.front() != "index.html")
        return err("export: the web export has no index.html to zip", "this is a bug in factoria; report it");

    std::string zip, central;
    std::vector<ZipEntry> entries;
    std::uint64_t total = 0;
    for (const std::string& name : names) {
        const stdfs::path file = outRoot / name;
        auto data = read_file(file);
        if (!data) return err("export: cannot read " + generic(file) + " to zip it");
        if (data->size() >= 0xFFFFFFFFull || zip.size() >= 0x7FFFFFFFull)
            return err("export: the web export is over 2 GB, more than a zip made here can hold", "itch.io does not take such a game either: make the game smaller");
        ZipEntry e;
        e.name = name;
        e.size = static_cast<std::uint32_t>(data->size());
        total += data->size();
        e.crc = static_cast<std::uint32_t>(buminiz::mz_crc32(buminiz::mz_crc32(0, nullptr, 0), reinterpret_cast<const unsigned char*>(data->data()), data->size()));
        std::string_view body = *data;
        std::string deflated;
        if (!data->empty()) {
            std::size_t n = 0;
            void* heap = buminiz::tdefl_compress_mem_to_heap(data->data(), data->size(), &n, 1024);  // raw deflate, 1024 probes
            if (heap) {
                if (n < data->size()) deflated.assign(static_cast<const char*>(heap), n);
                std::free(heap);
            }
        }
        if (!deflated.empty()) {
            e.method = 8;
            body = deflated;
        }
        e.compressedSize = static_cast<std::uint32_t>(body.size());
        e.offset = static_cast<std::uint32_t>(zip.size());
        put32(zip, 0x04034b50);
        put16(zip, 20);
        put16(zip, kUtf8Names);
        put16(zip, e.method);
        put16(zip, 0);
        put16(zip, kDosDate);
        put32(zip, e.crc);
        put32(zip, e.compressedSize);
        put32(zip, e.size);
        put16(zip, static_cast<std::uint32_t>(e.name.size()));
        put16(zip, 0);
        zip += e.name;
        zip.append(body.data(), body.size());
        entries.push_back(std::move(e));
    }
    for (const ZipEntry& e : entries) {
        put32(central, 0x02014b50);
        put16(central, 20);
        put16(central, 20);
        put16(central, kUtf8Names);
        put16(central, e.method);
        put16(central, 0);
        put16(central, kDosDate);
        put32(central, e.crc);
        put32(central, e.compressedSize);
        put32(central, e.size);
        put16(central, static_cast<std::uint32_t>(e.name.size()));
        put16(central, 0);  // extra
        put16(central, 0);  // comment
        put16(central, 0);  // disk
        put16(central, 0);  // internal attributes
        put32(central, 0);  // external attributes
        put32(central, e.offset);
        central += e.name;
    }
    const std::uint32_t centralOffset = static_cast<std::uint32_t>(zip.size());
    zip += central;
    put32(zip, 0x06054b50);
    put16(zip, 0);
    put16(zip, 0);
    put16(zip, static_cast<std::uint32_t>(entries.size()));
    put16(zip, static_cast<std::uint32_t>(entries.size()));
    put32(zip, static_cast<std::uint32_t>(central.size()));
    put32(zip, centralOffset);
    put16(zip, 0);

    std::string why;
    std::error_code ec;
    stdfs::remove(os_path(zipFile), ec);
    if (!write_file(zipFile, zip, &why)) return err("export: " + why);

    // What itch.io documents for an HTML5 game (https://itch.io/docs/creators/html5).
    constexpr std::uint64_t kMiB = 1024 * 1024;
    if (names.size() > 1000)
        report.warnings.push_back("The web export has " + std::to_string(names.size()) + " files; itch.io takes at most 1000 in an HTML5 game");
    if (total > 500 * kMiB)
        report.warnings.push_back("The web export is " + std::to_string(total / kMiB) + " MB unpacked; itch.io takes at most 500 MB for an HTML5 game. Compress "
                                  "textures and audio (docs/ASSETS.md, \"Import settings\")");
    for (const ZipEntry& e : entries) {
        if (e.size > 200 * kMiB)
            report.warnings.push_back(e.name + " is " + std::to_string(e.size / kMiB) + " MB; itch.io takes at most 200 MB per file in an HTML5 game. "
                                      "Make the game smaller (docs/ASSETS.md, \"Import settings\")");
        if (e.name.size() > 240)
            report.warnings.push_back("The path " + e.name + " is over 240 characters, which itch.io refuses in an HTML5 game");
    }
    report.format = "zip";
    report.artifact = generic(zipFile);
    report.nextSteps.push_back("Publish on itch.io: upload " + generic(zipFile.filename()) + " to a project of kind HTML, tick \"This file will be played in the "
                               "browser\" and set the viewport size; any other host takes the folder's files as they are (serve .wasm as application/wasm)");
    return {};
}

}  // namespace fa::export_detail
