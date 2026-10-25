// assets.import of a video (.mp4 .mov .webm ... -> MPEG-1 .mpg through ffmpeg, an .mpg is checked and copied) and the video
// check of project.validate.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/process.h"
#include "fa/core/video.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "fa/scene/serialize.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

// Puts the ffmpeg lookup back to the real machine when the test ends.
struct FfmpegOverride {
    explicit FfmpegOverride(const std::string& path) { set_video_ffmpeg(&path); }
    ~FfmpegOverride() { set_video_ffmpeg(nullptr); }
};

std::string fixture() { return read_all(FA_VIDEO_FIXTURE); }

Json details_of(const Json& result) { return result["details"]; }

}  // namespace

TEST_CASE("assets.import: an .mpg is checked and copied to assets/video with its provenance") {
    AssetsProject p;
    write_all(p.tmp.path / "art/intro.mpg", fixture());
    Json r = p.ok("assets.import", {{"source", (p.tmp.path / "art/intro.mpg").string()}, {"license", "CC0"}, {"author", "Ana"}});
    CHECK(r["importer"] == "video");
    CHECK(r["path"] == "assets/video/intro.mpg");
    CHECK(p.exists("assets/video/intro.mpg"));
    CHECK(read_all(p.file("assets/video/intro.mpg")) == fixture());
    CHECK(details_of(r)["width"] == 64);
    CHECK(details_of(r)["height"] == 64);
    CHECK(details_of(r)["duration"].get<double>() == doctest::Approx(1.2).epsilon(0.05));
    CHECK(details_of(r)["hasAudio"] == true);
    CHECK(has_text(r["nextSteps"], "Video component"));
    CHECK(has_text(r["nextSteps"], "assets/video/intro.mpg"));
    const Json entry = p.manifest()["assets"]["assets/video/intro.mpg"];
    CHECK(entry["provenance"]["origin"] == "imported");
    CHECK(entry["provenance"]["license"] == "CC0");
    CHECK(entry["provenance"]["author"] == "Ana");
}

TEST_CASE("assets.import: a file named .mpg that is not MPEG-1 is refused with the way to convert it") {
    AssetsProject p;
    write_all(p.tmp.path / "art/fake.mpg", std::string(4096, 'A'));
    CommandResult r = p.call("assets.import", {{"source", (p.tmp.path / "art/fake.mpg").string()}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("fake.mpg") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("factoria setup ffmpeg") != std::string::npos);
    CHECK_FALSE(p.exists("assets/video/fake.mpg"));
    CHECK_FALSE(p.exists("assets.json"));
}

TEST_CASE("assets.import: an .mp4 without ffmpeg names the command that installs it") {
    AssetsProject p;
    write_all(p.tmp.path / "art/intro.mp4", "not really a video");
    FfmpegOverride none("");
    CommandResult r = p.call("assets.import", {{"source", (p.tmp.path / "art/intro.mp4").string()}});
    REQUIRE_FALSE(r.ok);
    const std::string message = r.error["message"].get<std::string>(), hint = r.error["hint"].get<std::string>();
    CHECK(message.find("ffmpeg") != std::string::npos);
    CHECK(message.find("intro.mp4") != std::string::npos);
    CHECK(hint.find("factoria setup ffmpeg") != std::string::npos);
    CHECK(hint.find("-c:v mpeg1video") != std::string::npos);  // or convert it by hand
    CHECK_FALSE(p.exists("assets/video/intro.mpg"));
    CHECK_FALSE(p.exists("assets.json"));
}

TEST_CASE("assets.import: an ffmpeg that does not work is an error, not a half-written file") {
    AssetsProject p;
    write_all(p.tmp.path / "art/intro.mp4", "not really a video");
    FfmpegOverride broken((p.tmp.path / "no_such_ffmpeg").string());
    CommandResult r = p.call("assets.import", {{"source", (p.tmp.path / "art/intro.mp4").string()}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("failed") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("mpeg1video") != std::string::npos);
    CHECK_FALSE(p.exists("assets/video/intro.mpg"));
}

TEST_CASE("assets.import: a destination for a video must end in .mpg") {
    AssetsProject p;
    write_all(p.tmp.path / "art/intro.mp4", "x");
    CommandResult r = p.call("assets.import", {{"source", (p.tmp.path / "art/intro.mp4").string()}, {"path", "assets/video/intro.mp4"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find(".mpg") != std::string::npos);
}

// Needs ffmpeg (FACTORIA_FFMPEG, PATH or `factoria setup ffmpeg`): skipped when there is none.
TEST_CASE("assets.import: an .mp4 is converted to an .mpg the engine decodes (odd size, 15 fps, with sound)") {
    auto ffmpeg = find_ffmpeg();
    if (!ffmpeg.ok()) {
        MESSAGE("ffmpeg was not found: the real video conversion is not tested on this machine");
        return;
    }
    AssetsProject p;
    const stdfs::path source = p.tmp.path / "art/clip.mp4";
    stdfs::create_directories(source.parent_path());
    ProcessOptions make;
    make.argv = {ffmpeg->path, "-nostdin", "-y", "-loglevel", "error", "-f", "lavfi", "-i", "testsrc=size=101x75:rate=15:duration=1",
                 "-f", "lavfi", "-i", "sine=frequency=330:sample_rate=48000:duration=1", "-c:v", "mpeg4", "-c:a", "aac", "-shortest", source.string()};
    make.timeoutSeconds = 120;
    auto made = run_process(make);
    if (!made.ok() || made->exitCode != 0 || !stdfs::exists(source)) {
        MESSAGE("this ffmpeg cannot make the test video (mpeg4 + aac in mp4): " << (made.ok() ? made->stderrText : made.error().message));
        return;
    }
    Json r = p.ok("assets.import", {{"source", source.string()}});
    CHECK(r["path"] == "assets/video/clip.mpg");
    CHECK(details_of(r)["converter"] == "ffmpeg");
    CHECK(details_of(r)["hasAudio"] == true);
    CHECK(details_of(r)["width"].get<int>() % 2 == 0);
    CHECK(details_of(r)["height"].get<int>() % 2 == 0);
    CHECK(details_of(r)["duration"].get<double>() == doctest::Approx(1.0).epsilon(0.2));
    CHECK(r["written"][0]["kind"] == "video");
    CHECK(r["written"][0]["bytes"].get<int>() < 1000000);

    // What landed plays.
    const std::string bytes = read_all(p.file("assets/video/clip.mpg"));
    auto data = std::make_shared<const std::vector<std::uint8_t>>(bytes.begin(), bytes.end());
    auto decoder = VideoDecoder::open(data, "clip.mpg");
    REQUIRE_MESSAGE(decoder.ok(), decoder.error().to_string());
    (*decoder)->advance(0.5);
    CHECK((*decoder)->time() == doctest::Approx(0.5));
    CHECK((*decoder)->info().hasAudio);
}

// ---- project.validate ----------------------------------------------------------------------------------

namespace {

ValidationReport validate_with_video(TempDir& tmp, const std::string& videoPath, const std::string& fileContent) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    if (!fileContent.empty()) write_all(tmp.path / "game" / videoPath, fileContent);
    auto scene = load_json_file(tmp.sub("game/scenes/main.scene.json"));
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(Json::object(
        {{"id", "intro"}, {"components", Json::object({{"Video", Json::object({{"path", videoPath}, {"size", Json::array({320, 180})}})}})}}));
    REQUIRE(save_scene_json_file(tmp.sub("game/scenes/main.scene.json"), *scene).ok());
    return validate_project(tmp.sub("game"));
}

const ValidationIssue* find_video_issue(const std::vector<ValidationIssue>& list) {
    for (const ValidationIssue& i : list)
        if (i.file == "scenes/main.scene.json" && i.pointer.find("/path") != std::string::npos && i.pointer.find("Video") != std::string::npos) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: a Video that names a playable .mpg passes") {
    TempDir tmp;
    auto r = validate_with_video(tmp, "assets/video/intro.mpg", fixture());
    for (auto& e : r.errors) MESSAGE(e.to_string());
    CHECK(r.ok);
}

TEST_CASE("validate: a Video whose file is missing or is not MPEG-1 is an error at the path field") {
    {
        TempDir tmp;
        auto r = validate_with_video(tmp, "assets/video/intro.mpg", "");
        REQUIRE_FALSE(r.ok);
        const ValidationIssue* issue = find_video_issue(r.errors);
        REQUIRE(issue);
        CHECK(issue->message.find("does not exist") != std::string::npos);
    }
    {
        TempDir tmp;  // a renamed .mp4 is the usual mistake
        auto r = validate_with_video(tmp, "assets/video/intro.mpg", std::string(4096, 'A'));
        REQUIRE_FALSE(r.ok);
        const ValidationIssue* issue = find_video_issue(r.errors);
        REQUIRE(issue);
        CHECK(issue->message.find("cannot be played") != std::string::npos);
        CHECK(issue->message.find("intro.mpg") != std::string::npos);
        CHECK(issue->hint.find("factoria setup ffmpeg") != std::string::npos);
    }
}
