// Video (.mp4 .mov .webm .mkv .avi .m4v) -> .mpg. The engine plays MPEG-1 video with MP2 audio in an MPEG program stream (the
// same on every platform, decoded by pl_mpeg), so any other video is converted by ffmpeg, which does not ship with FactorIA:
// `factoria setup ffmpeg` installs one. An .mpg or .mpeg that already is MPEG-1 is only checked and copied.
#include <algorithm>
#include <format>
#include <mutex>
#include <optional>

#include "assets_internal.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/core/video.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/export_settings.h"

namespace fa {

namespace {

std::mutex g_ffmpegMutex;
std::optional<std::string> g_ffmpegOverride;  // set by tests

constexpr int kMaxWidth = 1280;                       // wider videos are scaled down: the decoder runs on the CPU
constexpr std::uintmax_t kBigVideoBytes = std::uintmax_t(20) << 20;

std::string tail(const ProcessResult& r) {
    std::vector<std::string> lines = split(r.stderrText, '\n');
    while (!lines.empty() && trim(lines.back()).empty()) lines.pop_back();
    if (lines.size() > 8) lines.erase(lines.begin(), lines.end() - 8);
    return join(lines, "\n");
}

}  // namespace

void set_video_ffmpeg(const std::string* path) {
    std::lock_guard lock(g_ffmpegMutex);
    if (path) g_ffmpegOverride = *path;
    else g_ffmpegOverride.reset();
}

namespace assets_detail {

namespace {

Json video_details(const VideoInfo& i) {
    return Json::object({{"width", i.width}, {"height", i.height}, {"fps", i.fps}, {"duration", i.duration}, {"hasAudio", i.hasAudio}});
}

std::vector<std::string> video_warnings(const VideoInfo& i, std::uintmax_t bytes) {
    std::vector<std::string> w;
    if (!i.hasAudio) w.push_back("The video has no audio track: it plays silently.");
    if (bytes > kBigVideoBytes)
        w.push_back(std::format("The video is {} MB, and it ships inside the game: shorten it, lower the size, or encode it at a higher "
                                "quality number (ffmpeg -q:v 6).",
                                bytes >> 20));
    return w;
}

}  // namespace

Result<ImportOutput> import_video(const ImportRequest& request) {
    const std::string file = request.source.filename().string();
    const std::string ext = to_lower(request.source.extension().string());
    const bool alreadyMpeg = ext == ".mpg" || ext == ".mpeg";

    stdfs::path result = request.source;  // the .mpg that is imported
    struct Cleanup {
        stdfs::path dir;
        ~Cleanup() {
            if (!dir.empty()) { std::error_code ec; stdfs::remove_all(dir, ec); }
        }
    } cleanup;

    if (!alreadyMpeg) {
        std::optional<std::string> over;
        {
            std::lock_guard lock(g_ffmpegMutex);
            over = g_ffmpegOverride;
        }
        auto locate = [&]() -> Result<MachineToolFound> {
            if (!over) return find_ffmpeg();
            if (over->empty()) return make_error("ffmpeg was not found on this computer.");
            return MachineToolFound{*over, "override"};
        };
        Result<MachineToolFound> ffmpeg = locate();
        if (!ffmpeg.ok()) {
            std::string hint = "Run `factoria setup ffmpeg` to download one (setup.install {\"component\":\"ffmpeg\"}), then import again.";
            if (ffmpeg.error().hint.find("factoria setup ffmpeg") == std::string::npos && !ffmpeg.error().hint.empty())
                hint += " " + ffmpeg.error().hint;
            hint += " Or convert the video yourself: ffmpeg -i " + file + " -c:v mpeg1video -c:a mp2 -f mpeg movie.mpg, and import that .mpg.";
            return make_error("'" + file + "' is not an MPEG-1 .mpg, and the engine plays only that, so converting it needs ffmpeg: " +
                                  ffmpeg.error().message,
                              hint);
        }

        cleanup.dir = fs::make_temp_dir("fa_video");
        const stdfs::path out = cleanup.dir / "movie.mpg";
        std::string failure;
        auto convert = [&](bool forceRate) {
            ProcessOptions options;
            options.argv = {ffmpeg->path, "-nostdin", "-y", "-loglevel", "error", "-i", request.source.string(), "-map", "0:v:0", "-map", "0:a:0?",
                            "-sn", "-dn", "-vf", std::format("scale=w=trunc(min({}\\,iw)/2)*2:h=-2", kMaxWidth), "-pix_fmt", "yuv420p"};
            if (forceRate) options.argv.insert(options.argv.end(), {"-r", "30"});
            options.argv.insert(options.argv.end(), {"-c:v", "mpeg1video", "-q:v", "4", "-g", "30", "-bf", "0", "-c:a", "mp2", "-b:a", "128k", "-ar",
                                                     "44100", "-ac", "2", "-f", "mpeg", out.string()});
            options.timeoutSeconds = 600;
            auto r = run_process(options);
            std::error_code ec;
            if (r.ok() && r->exitCode == 0 && stdfs::is_regular_file(out, ec) && stdfs::file_size(out, ec) > 0) return true;
            failure = r.ok() ? (r->timedOut ? "it did not finish in 10 minutes" : "it exited with code " + std::to_string(r->exitCode) + ":\n" + tail(*r))
                             : r.error().message;
            stdfs::remove(out, ec);
            return false;
        };
        // MPEG-1 has a short list of frame rates; a video with another (15 fps, a variable rate) is converted again at 30 fps.
        bool done = convert(false);
        const std::string firstFailure = failure;
        if (!done && failure.find("fps") != std::string::npos) done = convert(true);  // "MPEG-1/2 does not support 15/1 fps"
        if (!done)
            return make_error("Converting '" + file + "' with ffmpeg failed: " + firstFailure,
                              "Open the video in a player to see that it is not damaged. Convert it by hand with ffmpeg -i " + file +
                                  " -c:v mpeg1video -c:a mp2 -f mpeg movie.mpg and import that .mpg.");
        result = out;
    }

    auto bytes = read_bytes(result);
    if (!bytes.ok()) return bytes.error();
    auto shared = std::make_shared<const std::vector<std::uint8_t>>(*bytes);
    auto decoder = VideoDecoder::open(shared, file);
    if (!decoder.ok()) return make_error(decoder.error().message, decoder.error().hint);
    const VideoInfo info = (*decoder)->info();

    ImportOutput out;
    out.details = video_details(info);
    out.details["converter"] = alreadyMpeg ? "copy" : "ffmpeg";
    out.warnings = video_warnings(info, bytes->size());
    out.nextSteps = {"Show it: a Video component (a UI rectangle) with \"path\": \"" + request.dest +
                     "\", \"size\": [width, height] and \"fit\": \"contain\"; it plays on its own (autoplay). In a script: "
                     "entity.video.play() / pause() / seek(seconds), and entity.video.on(\"ended\", fn)."};
    out.files.push_back({request.dest, std::move(*bytes)});
    return out;
}

}  // namespace assets_detail

}  // namespace fa
