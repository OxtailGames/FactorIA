// ffmpeg, which `factoria run --record-video trailer.mp4` turns its recording into H.264 + AAC with, and `setup ffmpeg`, which
// installs the pinned static build. The pinned downloads and their hashes are in fa/tooling/setup.h.
//
//   <home>/tools/ffmpeg/<release>/ffmpeg[.exe]
//
// The download is one gzip file of github.com/eugeneware/ffmpeg-static per host: it is checked against the SHA-256 kept in
// setup.h, then unpacked (gzip = a header, raw deflate, CRC-32 and size) into the install folder. Folders of older releases
// are removed once the new one is in place. Where the ffmpeg is looked for (variable, export.json, PATH, then this folder)
// is find_ffmpeg() in export_settings.cpp.
#include <cstdlib>
#include <fstream>

#define MINIZ_HEADER_FILE_ONLY
#define MINIZ_NO_ZLIB_COMPATIBLE_NAMES
#include <encoder/basisu_miniz.h>

#include "setup_internal.h"

namespace fa {

const FfmpegBinary* ffmpeg_binary(const SetupContext& context) {
    const std::string os = context.host_os(), arch = context.host_architecture();
    for (const FfmpegBinary& b : kSetupFfmpegBinaries)
        if (os == b.host && (*b.arch == '\0' || arch == b.arch)) return &b;
    return nullptr;
}

std::string ffmpeg_install_path(const SetupContext& context) {
    return (std::filesystem::path(context.home_dir()) / "tools" / "ffmpeg" / kSetupFfmpegRelease /
            ("ffmpeg" + setup_detail::exe_suffix(context.host_os())))
        .string();
}

}  // namespace fa

namespace fa::setup_detail {

namespace {

std::string ffmpeg_file(const SetupContext& ctx) { return "ffmpeg" + exe_suffix(ctx.host_os()); }

std::string ffmpeg_url(const FfmpegBinary& b) {
    return std::string("https://github.com/eugeneware/ffmpeg-static/releases/download/") + kSetupFfmpegRelease + "/ffmpeg-" +
           b.asset + ".gz";
}

const char* const kUnsupportedHint =
    "Compile on Windows, Linux or macOS (x64 or arm64), or install ffmpeg yourself (https://ffmpeg.org/download.html) and "
    "set FACTORIA_FFMPEG to it.";

// The gunzipped bytes of `gz`, or the reason it does not unpack.
Result<std::string> gunzip(const std::string& gz) {
    const auto bad = [](const std::string& why) {
        return make_error("The downloaded ffmpeg is not a valid gzip file: " + why + ".",
                          "Run the install again; if it keeps failing, install ffmpeg yourself (https://ffmpeg.org/download.html) "
                          "and set FACTORIA_FFMPEG to it.");
    };
    const auto* d = reinterpret_cast<const unsigned char*>(gz.data());
    const std::size_t n = gz.size();
    if (n < 18 || d[0] != 0x1f || d[1] != 0x8b || d[2] != 8) return bad("it does not start with the gzip header");
    const unsigned flags = d[3];
    std::size_t pos = 10;
    if (flags & 4) {  // extra field
        if (pos + 2 > n) return bad("the header is cut short");
        pos += 2 + (d[pos] | (d[pos + 1] << 8));
    }
    for (unsigned bit : {8u, 16u})  // name, comment: zero-terminated
        if (flags & bit) {
            while (pos < n && d[pos] != 0) ++pos;
            ++pos;
        }
    if (flags & 2) pos += 2;
    if (pos + 8 > n) return bad("the header is cut short");
    const std::size_t packedSize = n - 8 - pos;
    const auto read32 = [&](std::size_t at) {
        return std::uint32_t(d[at]) | (std::uint32_t(d[at + 1]) << 8) | (std::uint32_t(d[at + 2]) << 16) | (std::uint32_t(d[at + 3]) << 24);
    };
    std::size_t outSize = 0;
    void* heap = buminiz::tinfl_decompress_mem_to_heap(d + pos, packedSize, &outSize, 0);
    if (!heap) return bad("the data does not inflate");
    std::string out(static_cast<const char*>(heap), outSize);
    std::free(heap);
    const std::uint32_t crc = static_cast<std::uint32_t>(
        buminiz::mz_crc32(buminiz::mz_crc32(0, nullptr, 0), reinterpret_cast<const unsigned char*>(out.data()), out.size()));
    if (crc != read32(n - 8) || std::uint32_t(out.size()) != read32(n - 4)) return bad("it does not match its CRC-32");
    return out;
}

}  // namespace

SetupComponent ffmpeg_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "ffmpeg";
    c.title = "ffmpeg (turns --record-video recordings into .mp4)";
    const FfmpegBinary* bin = ffmpeg_binary(ctx);
    if (!bin) {
        c.state = "unsupported";
        c.details = "There is no ffmpeg build for " + ctx.host_os() + "-" + ctx.host_architecture() + ". " + kUnsupportedHint;
        return c;
    }
    c.canInstall = true;
    auto found = find_ffmpeg(ctx.env, ctx.config_path(), ffmpeg_install_path(ctx));
    if (found.ok() && is_file(found->path)) {
        c.state = "installed";
        c.paths.emplace_back("ffmpeg", found->path);
        c.details = "ffmpeg found (" + found->from + "): " + found->path + ".";
        return c;
    }
    c.state = "missing";
    c.installSizeMb = bin->sizeMb;
    c.details = std::string("The install downloads the static ffmpeg ") + kSetupFfmpegRelease + " build of github.com/eugeneware/ffmpeg-static (SHA-256 checked) into " +
                std::filesystem::path(ffmpeg_install_path(ctx)).parent_path().string() + ".";
    if (!found.ok() && found.error().message.find("was not found on this computer") == std::string::npos)
        c.problems.push_back(found.error().message);  // a variable or an export.json entry that points at nothing
    c.problems.push_back("`factoria run --record-video trailer.mp4` needs ffmpeg (an .avi needs nothing): run `factoria setup ffmpeg`.");
    return c;
}

SetupResult ffmpeg_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    return ffmpeg_install_binary(ctx, opt, ffmpeg_binary(ctx));
}

SetupResult ffmpeg_install_binary(const SetupContext& ctx, const SetupInstallOptions& opt, const FfmpegBinary* bin) {
    Installer in(ctx, "ffmpeg");
    if (!bin)
        return in.fail("unsupported",
                       make_error("There is no ffmpeg build for " + ctx.host_os() + "-" + ctx.host_architecture() + ".", kUnsupportedHint));
    StepTimer timer;
    SetupStep s;
    s.id = "ffmpeg";
    s.title = "ffmpeg";
    const stdfs::path dest = ffmpeg_install_path(ctx);
    const stdfs::path dir = dest.parent_path();
    if (auto found = find_ffmpeg(ctx.env, ctx.config_path(), ffmpeg_install_path(ctx)); !opt.force && found.ok() && is_file(found->path)) {
        s.outcome = "skipped";
        s.detail = "already available (" + found->from + "): " + found->path;
        s.path = found->path;
        in.add_step(s);
        in.report.paths = {{"ffmpeg", found->path}};
        return in.finish();
    }
    const stdfs::path file = in.staging() / "ffmpeg.gz";
    std::uint64_t bytes = 0;
    const std::uint64_t expected = std::uint64_t(bin->sizeMb) << 20;
    if (auto f = download_file(ctx, ffmpeg_url(*bin), file, "ffmpeg", expected, &bytes)) return in.fail(*f);
    if (auto f = verify_checksum(file, "sha256", bin->sha256, "ffmpeg")) return in.fail(*f);
    ctx.say("Unpacking ffmpeg");
    std::string gz;
    {
        std::ifstream f(file, std::ios::binary);
        gz.assign(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
    }
    auto unpacked = gunzip(gz);
    if (!unpacked.ok()) return in.fail("failed", unpacked.error());
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    const char* const writable = "Check that the folder is writable and the disk is not full.";
    if (ec) return in.fail("failed", make_error("Cannot create " + dir.string() + ": " + ec.message(), writable));
    stdfs::remove(dest, ec);
    {
        std::ofstream out(dest, std::ios::binary | std::ios::trunc);
        out.write(unpacked->data(), static_cast<std::streamsize>(unpacked->size()));
        if (!out) return in.fail("failed", make_error("Cannot write " + dest.string() + ".", writable));
    }
    make_executable(dest);
    in.report.changed = true;
    s.outcome = "installed";
    s.detail = "from github.com/eugeneware/ffmpeg-static (SHA-256 checked)";
    s.path = dest.string();
    s.downloadedBytes = bytes;
    s.seconds = timer.seconds();
    in.add_step(s);
    // The folders of older releases are no longer used.
    const std::string keep = kSetupFfmpegRelease;
    for (stdfs::directory_iterator it(dir.parent_path(), ec), end; !ec && it != end; it.increment(ec))
        if (it->is_directory() && it->path().filename().string() != keep) {
            std::error_code rm;
            stdfs::remove_all(it->path(), rm);
        }
    in.report.paths = {{"ffmpeg", dest.string()}};
    in.report.nextSteps.push_back("`factoria run --record-video trailer.mp4` now converts its recording with it.");
    return in.finish();
}

}  // namespace fa::setup_detail
