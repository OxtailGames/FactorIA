// Play sessions: stats, session.json, and the commands play.sessions / play.report on a fixture folder.
#include <filesystem>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/play_session.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("play session: frame stats (avg, p95, over 16.7 / 33 ms)") {
    CHECK(compute_frame_stats({}).count == 0);
    std::vector<double> ms(100, 10.0);
    ms[0] = 40.0;
    ms[1] = 20.0;
    ms[2] = 100.0;
    const FrameStats s = compute_frame_stats(ms);
    CHECK(s.count == 100);
    CHECK(s.maxMs == doctest::Approx(100.0));
    CHECK(s.p95Ms == doctest::Approx(10.0));  // nearest rank: the 95th of 100 sorted values
    CHECK(s.avgMs == doctest::Approx(11.3));
    CHECK(s.over16 == 3);
    CHECK(s.over33 == 2);
    ms.assign(20, 5.0);
    ms.back() = 50.0;
    CHECK(compute_frame_stats(ms).p95Ms == doctest::Approx(5.0));  // ceil(0.95 * 20) = the 19th value
}

TEST_CASE("play session: the worst spikes are kept, slowest first") {
    std::vector<PlaySpike> sp;
    for (int i = 0; i < 6; ++i) keep_worst_spike(sp, PlaySpike{std::uint64_t(i), 10.0 + (i * 7 % 6), i, Json()}, 3);
    REQUIRE(sp.size() == 3);
    CHECK(sp[0].ms >= sp[1].ms);
    CHECK(sp[1].ms >= sp[2].ms);
    CHECK(sp[0].ms == doctest::Approx(15.0));
}

namespace {
struct Fixture {
    stdfs::path dir = fs::make_temp_dir("fa_play_sessions");
    Engine engine;
    Fixture() {
        stdfs::create_directories(dir / "scenes");
        auto w = [&](const char* rel, const char* text) { REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok()); };
        w("factoria.json", R"({"format":"factoria.project/1","name":"Sessions","id":"com.example.sessions","mainScene":"scenes/main.scene.json",
            "display":{"width":64,"height":64},"physics":{"fixedHz":60}})");
        w("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}}]})");
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Fixture() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    // A session folder as the editor writes it; returns the folder name.
    std::string add(const std::string& name, bool withMark) {
        PlaySession s;
        s.name = name;
        s.scene = "scenes/main.scene.json";
        s.frames = 120;
        s.durationSec = 2.0;
        s.perf = compute_frame_stats({10, 12, 50});
        if (withMark) {  // the profiler's summary of the session, as the editor records it
            ProfileSummary prof;
            ProfFrame pf;
            pf.totalMs = 12;
            pf.classes = {{"Player", "scripts/player.js", 3.5, 2}};
            prof.add_frame(pf);
            s.profile = prof.to_json();
        }
        keep_worst_spike(s.spikes, PlaySpike{77, 50.0, 12, Json::object({{"drawCalls", 5}})});
        s.logs.push_back(Json::object({{"seq", 1}, {"frame", 80}, {"level", "error"}, {"category", "script"}, {"message", "boom"}}));
        s.input = Json::parse(R"({"frames":{"3":{"keys":{"Space":true}},"9":{"keys":{"Space":false}}}})");
        if (withMark) {
            s.marks.push_back(PlayMark{77, 1.3, "the HUD overlaps the score", "mark-1.png"});
            Image img;
            img.width = 4;
            img.height = 4;
            img.rgba.assign(64, 255);
            stdfs::create_directories(dir / ".factoria/sessions" / name);
            REQUIRE(save_png(img, (dir / ".factoria/sessions" / name / "mark-1.png").generic_string()).ok());
        }
        REQUIRE(write_play_session(".factoria/sessions/" + name, s).ok());
        return name;
    }
};
}  // namespace

TEST_CASE("play.sessions and play.report read the session folders") {
    Fixture f;
    CommandRegistry& c = f.engine.commands();
    for (const char* n : {"play.sessions", "play.report"}) {
        const CommandInfo* info = c.info(n);
        REQUIRE(info != nullptr);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->readOnly);
    }
    CHECK_FALSE(c.call("play.report", Json::object()).ok);  // no session yet: explains what to do
    CHECK(c.call("play.sessions", Json::object()).result["count"] == 0);

    f.add("20260101-100000", false);
    f.add("20260102-100000", true);
    auto list = c.call("play.sessions", Json::object());
    REQUIRE(list.ok);
    REQUIRE(list.result["count"] == 2);
    CHECK(list.result["sessions"][0]["session"] == "20260102-100000");  // newest first
    CHECK(list.result["sessions"][0]["marks"] == 1);
    CHECK(list.result["sessions"][0]["logs"] == 1);
    CHECK(list.result["sessions"][1]["marks"] == 0);
    CHECK(c.call("play.sessions", Json{{"max", 1}}).result["count"] == 1);

    auto rep = c.call("play.report", Json::object());  // latest
    REQUIRE(rep.ok);
    CHECK(rep.result["session"] == "20260102-100000");
    CHECK(rep.result["perf"]["maxMs"] == 50.0);
    CHECK(rep.result["spikes"][0]["frame"] == 77);
    CHECK(rep.result["logs"][0]["message"] == "boom");
    CHECK(rep.result["marks"][0]["note"] == "the HUD overlaps the score");
    CHECK(rep.result["inputFrames"] == 2);
    REQUIRE(rep.result.contains("profile"));  // new key; the others are unchanged
    CHECK(rep.result["profile"]["behaviours"][0]["class"] == "Player");
    CHECK(rep.result["profile"]["behaviours"][0]["avgMs"].get<double>() == doctest::Approx(3.5));
    CHECK(rep.result["replay"].get<std::string>().find("input.json") != std::string::npos);
    CHECK(rep.result["replayHow"].get<std::string>().find("--input") != std::string::npos);
    REQUIRE(rep.result.contains("$image"));
    CHECK(stdfs::exists(rep.result["$image"]["path"].get<std::string>()));
    CHECK(rep.result["marks"][0]["screenshot"] == rep.result["$image"]["path"]);

    auto old = c.call("play.report", Json{{"session", "20260101-100000"}});
    REQUIRE(old.ok);
    CHECK_FALSE(old.result.contains("profile"));  // a session without one (older editor) stays as it was
    CHECK_FALSE(old.result.contains("$image"));
    auto bad = c.call("play.report", Json{{"session", "20260102-1000"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("20260102-100000") != std::string::npos);  // did you mean

    const std::string text = play_session_summary(rep.result);
    CHECK(text.find("the HUD overlaps the score") != std::string::npos);
    CHECK(text.find("boom") != std::string::npos);
    CHECK(text.find("Player") != std::string::npos);  // the costliest behaviour class
}
