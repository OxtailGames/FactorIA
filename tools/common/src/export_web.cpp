// Web exports (docs/EXPORTING.md, "Web"): the Emscripten player (factoria_player.js + .wasm), the page that loads it
// (platforms/web/shell.html, embedded in the factoria binary), the whole game in one game.pak, and a zip of the folder with
// index.html at its root, which itch.io accepts as an HTML5 game.
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <map>
#include <set>

#include "export_internal.h"
#include "export_zip.h"
#include "fa/core/build_info.h"
#include "fa/core/pack.h"
#include "fa/tooling/ai_disclosure.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/notices.h"
#include "fa/tooling/setup.h"

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
                       "a web player is two files, factoria_player.js and factoria_player.wasm, in one folder; pass "
                       "that folder with --player");
    return w;
}

bool has_player(const stdfs::path& dir) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(dir / "factoria_player.js"), ec) &&
           stdfs::is_regular_file(os_path(dir / "factoria_player.wasm"), ec);
}

// Replaces {{name}} in one pass, so a game called "{{pakBytes}}" stays what it is. Names without a value are left as they are
// and listed in `unknown`.
std::string fill_page(const std::string& shell, const std::map<std::string, std::string>& values,
                      std::vector<std::string>& unknown) {
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

// ---- single file ---------------------------------------------------------------------------------------------------

constexpr std::uint64_t kBase64Chunk =
    3ull * 256 * 1024;  // bytes read and encoded at a time (a multiple of 3: no padding in the middle)

std::string mb_text(std::uint64_t bytes) {
    const std::uint64_t tenths = bytes / (1024 * 1024 / 10);  // tenths of a MiB, rounded down
    return std::to_string(tenths / 10) + "." + std::to_string(tenths % 10) + " MB";
}

// A reader over the bytes of a wasm module that never reads past the end.
struct WasmReader {
    std::string_view d;
    std::size_t at = 0;
    bool bad = false;
    std::uint64_t leb() {
        std::uint64_t v = 0;
        for (int shift = 0; shift < 64; shift += 7) {
            if (at >= d.size()) {
                bad = true;
                return 0;
            }
            const unsigned char b = static_cast<unsigned char>(d[at++]);
            v |= static_cast<std::uint64_t>(b & 0x7F) << shift;
            if ((b & 0x80) == 0) return v;
        }
        bad = true;
        return 0;
    }
    unsigned char byte() {
        if (at >= d.size()) {
            bad = true;
            return 0;
        }
        return static_cast<unsigned char>(d[at++]);
    }
    void skip(std::uint64_t n) {
        if (n > d.size() - at) {
            bad = true;
            at = d.size();
            return;
        }
        at += static_cast<std::size_t>(n);
    }
    // limits: flags, min, and max when flag bit 0 is set. Returns the flags (bit 1 = shared).
    unsigned limits() {
        const unsigned flags = static_cast<unsigned>(leb());
        leb();
        if (flags & 1) leb();
        return flags;
    }
};

// Reads a UTF-8/ASCII 'bytes of the file' chunk by chunk and writes it as base64 to `out`.
bool write_base64_of(std::ofstream& out, const stdfs::path& file) {
    std::ifstream in(os_path(file), std::ios::binary);
    if (!in) return false;
    std::string buf(static_cast<std::size_t>(kBase64Chunk), '\0');
    while (in) {
        in.read(buf.data(), static_cast<std::streamsize>(buf.size()));
        const std::streamsize got = in.gcount();
        if (got <= 0) break;
        const std::string enc = base64_encode(buf.data(), static_cast<std::size_t>(got));
        out.write(enc.data(), static_cast<std::streamsize>(enc.size()));
    }
    return static_cast<bool>(out) && (in.eof() || !in.bad());
}

// Text that goes inside <script type="text/plain">: "</" would end the element.
std::string script_safe(const std::string& text) { return replace_all(text, "</", "<\\/"); }

}  // namespace

std::string web_single_file_name(const Project& p) {
    const std::string slug = slugify(p.name, '-');
    return (slug.empty() ? std::string("game") : slug) + ".html";
}

std::uint64_t base64_length(std::uint64_t bytes) {
    if (bytes > UINT64_MAX / 2) return UINT64_MAX;
    return (bytes / 3 + (bytes % 3 ? 1 : 0)) * 4;
}

bool wasm_uses_shared_memory(std::string_view wasm) {
    if (wasm.size() < 8 || wasm.compare(0, 4, std::string_view("\0asm", 4)) != 0) return false;
    WasmReader r{wasm, 8};
    while (!r.bad && r.at < wasm.size()) {
        const unsigned id = r.byte();
        const std::uint64_t size = r.leb();
        if (r.bad) return false;
        if (id > 5)
            return false;  // the memory section is the last one that can declare a memory (imports and memories come first)
        if (size > wasm.size() - r.at) return false;
        const std::size_t end = r.at + static_cast<std::size_t>(size);
        if (id == 2) {  // imports: module, field, kind, descriptor
            const std::uint64_t count = r.leb();
            for (std::uint64_t i = 0; i < count && !r.bad && r.at < end; ++i) {
                r.skip(r.leb());  // module name
                r.skip(r.leb());  // field name
                switch (r.byte()) {
                    case 0: r.leb(); break;  // function: type index
                    case 1:
                        r.byte();
                        r.limits();
                        break;  // table: element type, limits
                    case 2:
                        if (r.limits() & 2) return !r.bad;
                        break;  // memory
                    case 3:
                        r.byte();
                        r.byte();
                        break;  // global: type, mutability
                    case 4:
                        r.byte();
                        r.leb();
                        break;  // tag: attribute, type index
                    default: return false;
                }
            }
        } else if (id == 5) {  // memories
            const std::uint64_t count = r.leb();
            for (std::uint64_t i = 0; i < count && !r.bad && r.at < end; ++i)
                if (r.limits() & 2) return !r.bad;
        }
        r.at = end;
    }
    return false;
}

Result<void> check_web_single_file(const ExportOptions& options, const WebPlayer& player, std::uint64_t packBytes) {
    if (auto wasm = read_file(player.wasm); wasm && wasm_uses_shared_memory(*wasm))
        return err("export: singleFile: this web player uses threads (its wasm has a shared memory), and a browser "
                   "starts those only on a page served with the "
                   "cross-origin isolation headers (Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy), "
                   "which a file opened by a double click cannot have",
                   "export the normal web folder instead (without singleFile) and serve it with those headers, or use "
                   "the default web player of this FactorIA "
                   "(it uses no threads): `factoria setup players --platforms web`");
    const std::uint64_t jsBytes = file_size_of(player.js), wasmBytes = file_size_of(player.wasm);
    const std::uint64_t playerPage = base64_length(jsBytes) + base64_length(wasmBytes);
    const std::uint64_t page =
        playerPage > UINT64_MAX - base64_length(packBytes) ? UINT64_MAX : playerPage + base64_length(packBytes);
    constexpr std::uint64_t kPageOverhead = 64 * 1024;  // the page's own text, the favicon and the notices
    if (page != UINT64_MAX && page + kPageOverhead <= options.singleFileMaxBytes) return {};
    std::string what = "the player is " + mb_text(jsBytes + wasmBytes) + " (" + mb_text(playerPage) + " as base64)";
    if (packBytes > 0)
        what += " and the game " + mb_text(packBytes) + " (" + mb_text(base64_length(packBytes)) + " as base64)";
    return err("export: singleFile: the page would be about " + mb_text(page) + " but the limit is " +
                   mb_text(options.singleFileMaxBytes) + "; " + what + "; base64 makes every file a third bigger",
               "make the game smaller (docs/ASSETS.md, \"Import settings\": compress textures and audio), raise the "
               "limit with singleFileMaxMb "
               "(--single-file-max-mb; browsers get slow with pages over about 100 MB), or export the normal web "
               "folder (no singleFile) and host it, "
               "or try it on a phone with project.serve_web");
}

Result<WebPlayer> find_web_player(const ExportOptions& o, const std::string& sourceRoot) {
    std::error_code ec;
    if (!o.playerBinary.empty()) {
        stdfs::path given(o.playerBinary);
        if (stdfs::is_regular_file(os_path(given), ec)) {
            const std::string ext = to_lower(given.extension().string());
            if (ext != ".js" && ext != ".wasm")
                return err("export: --player '" + o.playerBinary + "' is not a web player",
                           "for --platform web pass the folder that holds factoria_player.js and factoria_player.wasm, "
                           "or factoria_player.js itself");
            given = given.parent_path();
        } else if (!stdfs::is_directory(os_path(given), ec)) {
            return err("export: web player '" + o.playerBinary + "' not found",
                       "pass --player <folder> with factoria_player.js and factoria_player.wasm (the build tree's "
                       "player/ folder, or web/ of the FactorIA download)");
        }
        return player_in(given, "explicit");
    }
    // Every web player there is, in the order of preference when they all match: the download's web/ next to factoria, a web
    // build of the engine source (Emscripten, preset web-release) in the checkout factoria was built from, then the one
    // `factoria setup players` installed. The first whose build fingerprint is this factoria's wins, so a checkout's fresh
    // build is used before an installed player of an older release; when none matches the first found is returned and the
    // export then stops on the mismatch (check_player_build).
    std::vector<std::string> searched;
    std::vector<WebPlayer> found;
    const stdfs::path exeDir = executable_dir();
    if (has_player(exeDir / "web"))
        if (auto w = player_in(exeDir / "web", "package"); w.ok()) found.push_back(*w);
    searched.push_back(generic(exeDir / "web"));
    if (!sourceRoot.empty())
        for (const char* build : {"web-release", "web"})
            if (const stdfs::path dir = stdfs::path(sourceRoot) / "build" / build / "player"; has_player(dir))
                if (auto w = player_in(dir, "build"); w.ok()) found.push_back(*w);
    if (const std::string installed = installed_player("web"); !installed.empty())
        if (auto w = player_in(stdfs::path(installed).parent_path(), "installed"); w.ok()) found.push_back(*w);
    searched.push_back("<FactorIA home>/players/<version>/web (`factoria setup players --platforms web`)");
    searched.push_back(generic(stdfs::path(sourceRoot) / "build" / "web-release" / "player") +
                       " (a web build of the engine source)");
    const std::string mine = build_fingerprint();
    if (mine != "unknown")
        for (const WebPlayer& w : found)
            if (const auto data = read_file(w.wasm); data && find_build_fingerprint(*data) == mine) return w;
    if (!found.empty()) return found.front();
    return err("export: no web player found: factoria_player.js and factoria_player.wasm are not in " +
                   join(searched, ", "),
               "run `factoria setup players --platforms web` (the editor: Set up in the Export window) to install the "
               "web player of this FactorIA "
               "version, or build it with Emscripten (docs/BUILDING.md, preset web-release) and pass its player/ "
               "folder with --player <folder>");
}

namespace {

// Single file: the page with the player, wasm, favicon and pack inlined. `favicon` is the data: URL of the icon (or "data:,").
Result<void> write_single_file(const ExportOptions& options, const Project& p, const WebPlayer& player,
                               const stdfs::path& outRoot, const std::string& shell, const std::string& faviconDataUrl,
                               ExportReport& report) {
    const stdfs::path packFile = outRoot / kPackFileName;
    const std::uint64_t packBytes = file_size_of(packFile);
    // Before anything big is read or built: the sizes are on disk.
    if (auto r = check_web_single_file(options, player, packBytes); !r.ok()) return r;

    static const std::string kSlot = "{{inlineData}}";
    const std::size_t slot = shell.find(kSlot);
    if (slot == std::string::npos || shell.find(kSlot, slot + kSlot.size()) != std::string::npos)
        return err("export: the page template " + std::string(kShellPath) +
                       " has no single {{inlineData}} placeholder, which singleFile needs",
                   "update factoria, or restore the placeholder in platforms/web/shell.html");
    std::vector<std::string> unknown;
    const std::map<std::string, std::string> values = {{"title", xml_escape(p.name)},
                                                       {"favicon", faviconDataUrl},
                                                       {"wasmBytes", std::to_string(file_size_of(player.wasm))},
                                                       {"pakBytes", std::to_string(packBytes)}};
    const std::string head = fill_page(shell.substr(0, slot), values, unknown);
    const std::string tail = fill_page(shell.substr(slot + kSlot.size()), values, unknown);
    if (!unknown.empty())
        report.warnings.push_back(
            "The page template has placeholders this factoria does not fill in ({{" + join(unknown, "}}, {{") +
            "}}), so the page shows them as they are. Update factoria, or the template platforms/web/shell.html");

    const stdfs::path page = outRoot / web_single_file_name(p);
    std::ofstream out(os_path(page), std::ios::binary | std::ios::trunc);
    if (!out) return err("export: cannot write " + generic(page));
    out.write(head.data(), static_cast<std::streamsize>(head.size()));
    const std::pair<const char*, const stdfs::path*> parts[] = {
        {"fa-wasm", &player.wasm}, {"fa-pak", &packFile}, {"fa-js", &player.js}};
    for (const auto& [id, file] : parts) {
        out << "<script type=\"application/octet-stream\" id=\"" << id << "\">";  // never run: the page decodes it
        if (!write_base64_of(out, *file))
            return err("export: cannot read " + generic(*file) + " to inline it, or cannot write " + generic(page));
        out << "</script>\n";
    }
    // The licenses of the engine code in the player travel inside the file too (the folder's FACTORIA_NOTICES.txt may be left behind).
    out << "<script type=\"text/plain\" id=\"fa-notices\">"
        << script_safe(third_party_notices(
               NoticeScope::Game, std::set<std::string>(report.builtinFonts.begin(), report.builtinFonts.end())))
        << "</script>\n";
    out.write(tail.data(), static_cast<std::streamsize>(tail.size()));
    out.flush();
    if (!out) return err("export: cannot write " + generic(page) + " (is the disk full?)");
    out.close();
    std::error_code ec;
    stdfs::remove(os_path(packFile), ec);  // inlined: the page does not use it
    if (ec)
        report.warnings.push_back("Could not delete " + generic(packFile) + " after inlining it (" + ec.message() +
                                  "); the page does not need it");
    report.format = "html";
    report.artifact = generic(page);
    report.mode = player.from;
    report.nextSteps.push_back("Open " + generic(page) +
                               " with a double click: it runs offline in a browser, with no server (" +
                               mb_text(file_size_of(page)) +
                               "). Send that one file to try the game on another computer; a phone opens it from a "
                               "chat or a file manager only in some browsers, "
                               "so to test on a phone use project.serve_web instead");
    return {};
}

}  // namespace

Result<void> export_web(const ExportOptions& options, const Project& p, const WebPlayer& player,
                        const stdfs::path& outRoot, const std::vector<std::string>& files, ExportReport& report) {
    std::error_code ec;
    stdfs::create_directories(os_path(outRoot), ec);
    // The game first: its size goes into the page.
    if (auto r = pack_project(p, files, outRoot / kPackFileName, report); !r.ok()) return r;
    const bool single = options.singleFile;
    if (!single)
        for (const stdfs::path* f : {&player.js, &player.wasm}) {
            stdfs::copy_file(os_path(*f), os_path(outRoot / f->filename()), stdfs::copy_options::overwrite_existing,
                             ec);
            if (ec)
                return err("export: cannot copy the web player " + generic(*f) + " to " + generic(outRoot) + ": " +
                           ec.message());
        }
    const auto shell = bundled_read(kShellPath);
    if (!shell)
        return err(std::string("export: the page template ") + kShellPath + " is not in this factoria",
                   "this build of factoria lacks the platforms/ folder: build it from a complete checkout, or use the "
                   "FactorIA download");
    // The tab's icon: the game's icon (factoria.json "icon") as a 64x64 favicon.png. Without one, or with an icon that cannot be read
    // (the warning says why), the page keeps an empty icon, so that a host without a favicon logs no 404.
    std::string favicon = "data:,";
    {
        std::vector<std::string> ignored;  // load_icon_image's remarks (not square, under 512 px) are about app icons
        auto icon = load_platform_icon(p, "web", ignored);
        if (!icon.ok()) {
            report.warnings.push_back(icon.error().message +
                                      (icon.error().hint.empty() ? "" : ". " + icon.error().hint) +
                                      ". The page has no icon in the browser tab");
        } else if (!icon->empty()) {
            const Image small = fit_image(*icon, 64, 1.0f, Color{0, 0, 0, 0});
            const std::vector<std::uint8_t> png = encode_png(small);
            if (png.empty()) {
                report.warnings.push_back(
                    "The game's icon could not be written as favicon.png, so the page has no icon in the browser tab");
            } else if (single) {
                favicon = "data:image/png;base64," + base64_encode(png.data(), png.size());
            } else {
                std::string why;
                if (!write_file(outRoot / "favicon.png",
                                std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &why))
                    return err("export: cannot write " + generic(outRoot / "favicon.png") +
                               (why.empty() ? "" : ": " + why));
                favicon = "favicon.png";
            }
        }
    }
    if (single) return write_single_file(options, p, player, outRoot, *shell, favicon, report);
    std::vector<std::string> unknown;
    // {{inlineData}} is the single-file page's data blocks: empty here, the page loads the files next to it.
    const std::string page = fill_page(*shell,
                                       {{"title", xml_escape(p.name)},
                                        {"favicon", favicon},
                                        {"wasmBytes", std::to_string(file_size_of(player.wasm))},
                                        {"pakBytes", std::to_string(file_size_of(outRoot / kPackFileName))},
                                        {"inlineData", ""}},
                                       unknown);
    if (!unknown.empty())
        report.warnings.push_back(
            "The page template has placeholders this factoria does not fill in ({{" + join(unknown, "}}, {{") +
            "}}), so index.html shows them as they are. Update factoria, or the template platforms/web/shell.html");
    if (auto r = write_text(outRoot / "index.html", page); !r.ok()) return r;
    report.mode = player.from;
    report.nextSteps.push_back(
        "Try it: a browser does not run it from a file (it fetches the .wasm and game.pak), so serve the folder: "
        "python -m http.server 8080 --directory \"" +
        generic(outRoot) +
        "\" and open http://localhost:8080/ "
        "(or project.serve_web, which also serves it to a phone; or export with singleFile for one page that opens "
        "from a double click)");
    return {};
}

// ---- the zip (export_zip.cpp) ------------------------------------------------------------------------

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

    ZipWriter zip(zipFile);
    std::uint64_t total = 0;
    for (const std::string& name : names) {
        const stdfs::path file = outRoot / name;
        auto data = read_file(file);
        if (!data) return err("export: cannot read " + generic(file) + " to zip it");
        if (data->size() >= 0xFFFFFFFFull)
            return err("export: the web export is over 2 GB, more than a zip made here can hold",
                       "itch.io does not take such a game either: make the game smaller");
        total += data->size();
        if (auto r = zip.add(name, *data, true); !r.ok()) return r;
    }
    if (auto r = zip.finish(); !r.ok()) return r;
    const std::vector<ZipEntry>& entries = zip.entries();
    // The size of each file as a browser downloads it: a host that gzips sends the deflate stream in an 18-byte gzip frame (never more
    // than the raw file plus the frame). Biggest first.
    report.webBytes = report.webGzipBytes = 0;
    report.webFiles.clear();
    for (const ZipEntry& e : entries) {
        ExportSize row;
        row.name = e.name;
        row.files = 1;
        row.bytes = e.size;
        row.gzipBytes = std::min<std::uint64_t>(e.compressedSize, e.size) + 18;
        report.webBytes += row.bytes;
        report.webGzipBytes += row.gzipBytes;
        report.webFiles.push_back(std::move(row));
    }
    std::sort(report.webFiles.begin(), report.webFiles.end(), [](const ExportSize& a, const ExportSize& b) {
        return std::make_pair(b.bytes, a.name) < std::make_pair(a.bytes, b.name);
    });

    // What itch.io documents for an HTML5 game (https://itch.io/docs/creators/html5).
    constexpr std::uint64_t kMiB = 1024 * 1024;
    if (names.size() > 1000)
        report.warnings.push_back("The web export has " + std::to_string(names.size()) +
                                  " files; itch.io takes at most 1000 in an HTML5 game");
    if (total > 500 * kMiB)
        report.warnings.push_back("The web export is " + std::to_string(total / kMiB) +
                                  " MB unpacked; itch.io takes at most 500 MB for an HTML5 game. Compress "
                                  "textures and audio (docs/ASSETS.md, \"Import settings\")");
    for (const ZipEntry& e : entries) {
        if (e.size > 200 * kMiB)
            report.warnings.push_back(e.name + " is " + std::to_string(e.size / kMiB) +
                                      " MB; itch.io takes at most 200 MB per file in an HTML5 game. "
                                      "Make the game smaller (docs/ASSETS.md, \"Import settings\")");
        if (e.name.size() > 240)
            report.warnings.push_back("The path " + e.name +
                                      " is over 240 characters, which itch.io refuses in an HTML5 game");
    }
    report.format = "zip";
    report.artifact = generic(zipFile);
    report.nextSteps.push_back("Publish on itch.io: upload " + generic(zipFile.filename()) +
                               " to a project of kind HTML, tick \"This file will be played in the "
                               "browser\" and set the viewport size; any other host takes the folder's files as they "
                               "are (serve .wasm as application/wasm)");
    return {};
}

}  // namespace fa::export_detail
