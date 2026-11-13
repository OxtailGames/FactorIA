// Songs rendered to game assets (M56.3): sample-exact loop points, a seamless loop (the tail of the last bar wraps onto the loop start),
// layers and stems (all the same length and loop, adding up to the mix before the master limiter), and the layers of a song document.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "fa/audio/song.h"
#include "fa/audio/song_preview.h"

using namespace fa;

namespace {

SongDoc parsed(const Json& j) {
    std::vector<SongIssue> issues;
    auto r = parse_song(j, "test.song.json", &issues);
    INFO(std::string(r ? "" : r.error().message));
    REQUIRE(bool(r));
    return *r;
}

SongTimeline timeline_of(const SongDoc& song) {
    auto tl = expand_song(song);
    REQUIRE(bool(tl));
    return *tl;
}

// A small song: a pad and a pluck through a reverb bus and a drum track; intro (1 bar), loop (2 bars), outro (1 bar). The master does
// not normalize or limit unless a test asks, so what is measured is the mix.
Json demo(bool loopFirst = false) {
    Json j = Json::parse(R"({
      "format": "factoria.song/1", "tempo": 120, "volume": 1.0,
      "mixer": {"buses": {"hall": {"effects": [{"type": "reverb", "decay": 2.2, "mix": 1}]}},
                "master": {"loudness": "off", "limiter": false}},
      "tracks": {
        "pad": {"instrument": "pad", "sends": {"hall": 0.7}, "patterns": {"a": "(Am@3):1 | (F@3):1", "i": "(Am@3):1", "o": "(F@3):1"}},
        "pluck": {"instrument": "pluck", "sends": {"hall": 0.5}, "patterns": {"a": "A4:8 C5 E5 A5 E5 C5 A4 E4 | F4:8 A4 C5 F5 C5 A4 F4 C4"}},
        "drums": {"instrument": "kit", "patterns": {"g": {"step": "8", "grid": {"kick": "x...x...", "hat": "x.x.x.x."}}}}
      },
      "layers": {"rhythm": ["drums"], "harmony": {"tracks": ["pad"], "intensity": 0.3}},
      "sections": [
        {"name": "intro", "kind": "intro", "play": {"pad": "i"}},
        {"name": "main", "kind": "loop", "play": {"pad": "a", "pluck": "a", "drums": "g*2"}},
        {"name": "outro", "kind": "outro", "play": {"pad": "o"}}]})");
    if (loopFirst) {
        j["sections"] = Json::array({j["sections"][1]});
    }
    return j;
}

SongAssetRender render_asset(const SongDoc& song, SongAssetOptions o = {}) {
    o.render.tailSeconds = 1.0;
    auto r = render_song_asset(song, timeline_of(song), o);
    INFO(std::string(r ? "" : r.error().message));
    REQUIRE(bool(r));
    return std::move(*r);
}

double peak_of(const std::vector<float>& s) {
    double p = 0.0;
    for (float v : s) p = std::max(p, double(std::abs(v)));
    return p;
}

}  // namespace

TEST_CASE("layers: a song declares them, the tracks left out form 'other', intensities spread evenly") {
    SongDoc song = parsed(demo());
    REQUIRE(song.layers.size() == 2);
    const auto layers = song_layers(song);
    REQUIRE(layers.size() == 3);
    CHECK(layers[0].name == "rhythm");
    CHECK(layers[0].intensity == doctest::Approx(0.0));
    CHECK(layers[1].name == "harmony");
    CHECK(layers[1].intensity == doctest::Approx(0.3));  // written
    CHECK(layers[2].name == kSongRestLayer);
    CHECK(layers[2].tracks == std::vector<std::string>{"pluck"});
    CHECK(layers[2].intensity == doctest::Approx(1.0));
}

TEST_CASE("layers: unknown tracks get a did-you-mean, a track in two layers and the reserved name are errors") {
    Json j = demo();
    j["layers"] = Json::parse(R"({"a": ["padd"]})");
    std::vector<SongIssue> issues;
    CHECK_FALSE(bool(parse_song(j, "x", &issues)));
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].pointer == "/layers/a/0");
    CHECK(issues[0].message.find("padd") != std::string::npos);
    CHECK(issues[0].hint.find("pad") != std::string::npos);
    j["layers"] = Json::parse(R"({"a": ["pad"], "b": ["pad"]})");
    issues.clear();
    CHECK_FALSE(bool(parse_song(j, "x", &issues)));
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].message.find("`a` and `b`") != std::string::npos);
    j["layers"] = Json::parse(R"({"other": ["pad"]})");
    issues.clear();
    CHECK_FALSE(bool(parse_song(j, "x", &issues)));
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].message.find("other") != std::string::npos);
}

TEST_CASE("render asset: the loop points are the loop section's bar boundaries, sample exact") {
    SongDoc song = parsed(demo());
    const SongAssetRender r = render_asset(song);
    REQUIRE(r.loop.has_value());
    REQUIRE(r.mix.clip.loop.has_value());
    // 120 BPM, 4/4: a bar is 2 s. The intro is bar 1, the loop bars 2-3.
    CHECK(r.loop->startBar == 2);
    CHECK(r.loop->bars == 2);
    CHECK(r.mix.clip.loop->start == 2 * 44100);
    CHECK(r.mix.clip.loop->end == 6 * 44100);
    CHECK(r.mix.clip.sampleRate == 44100);
    // the whole song plus the tail: intro, loop and outro are all in the file
    CHECK(r.mix.clip.frames() > std::size_t(8 * 44100));
    CHECK(r.mix.seconds == doctest::Approx(8.0));
}

TEST_CASE("render asset: at another sample rate the points are still the exact frames of the bars") {
    SongDoc song = parsed(demo());
    SongAssetOptions o;
    o.render.sampleRate = 22050;
    const SongAssetRender r = render_asset(song, o);
    REQUIRE(r.mix.clip.loop.has_value());
    CHECK(r.mix.clip.loop->start == 2 * 22050);
    CHECK(r.mix.clip.loop->end == 6 * 22050);
}

TEST_CASE("render asset: a song without a loop section has no loop points") {
    Json j = demo();
    j["sections"][1]["kind"] = "section";
    SongDoc song = parsed(j);
    const SongAssetRender r = render_asset(song);
    CHECK_FALSE(r.loop.has_value());
    CHECK_FALSE(r.mix.clip.loop.has_value());
}

TEST_CASE("render asset: the loop is seamless, the tail of its last bar wraps onto its start") {
    // The reference plays the loop section four times in a row; the third pass has the tails of the passes before it, which is what a
    // game hears once the loop is running. The asset's loop body must be that same sound.
    Json one = demo(true);
    Json four = demo(true);
    four["sections"][0]["repeat"] = 4;
    const SongDoc songOne = parsed(one), songFour = parsed(four);
    const SongAssetRender asset = render_asset(songOne);
    REQUIRE(asset.mix.clip.loop.has_value());
    SongRenderOptions ro;
    ro.sampleRate = 44100;
    ro.tailSeconds = 1.0;
    auto ref = render_song(songFour, timeline_of(songFour), ro);
    REQUIRE(bool(ref));
    const std::size_t len = asset.mix.clip.loop->end - asset.mix.clip.loop->start;  // 4 s
    REQUIRE(len == std::size_t(4 * 44100));
    const std::size_t from = 2 * len;  // the third pass of the reference
    double worst = 0.0, peak = 0.0;
    for (std::size_t i = 0; i < len * 2; ++i) {
        const double a = double(asset.mix.clip.samples[i]);
        const double b = double(ref->clip.samples[from * 2 + i]);
        worst = std::max(worst, std::abs(a - b));
        peak = std::max(peak, std::abs(b));
    }
    CHECK(peak > 0.05);
    CHECK(worst < 1e-3 * peak);

    // And the seam itself: the step from the last frame of the loop to its first is no bigger than the steps inside it.
    const auto& s = asset.mix.clip.samples;
    const std::size_t last = asset.mix.clip.loop->end - 1, first = asset.mix.clip.loop->start;
    double maxStep = 0.0;
    for (std::size_t i = first + 1; i < last; ++i)
        for (std::size_t c = 0; c < 2; ++c)
            maxStep = std::max(maxStep, double(std::abs(s[2 * i + c] - s[2 * (i - 1) + c])));
    for (std::size_t c = 0; c < 2; ++c)
        CHECK(std::abs(double(s[2 * first + c] - s[2 * last + c])) <= maxStep * 1.5 + 1e-4);
}

TEST_CASE("render asset: without folding the tail the seam would be a different sound (the fold does something)") {
    Json one = demo(true);
    SongDoc song = parsed(one);
    SongAssetOptions folded, plain;
    plain.loop = false;
    const SongAssetRender a = render_asset(song, folded);
    const SongAssetRender b = render_asset(song, plain);
    REQUIRE(a.mix.clip.loop.has_value());
    CHECK_FALSE(b.mix.clip.loop.has_value());
    // the first bar of the loop differs by the reverb tail that comes round from the end
    double diff = 0.0;
    for (std::size_t i = 0; i < 44100 * 2; ++i)
        diff = std::max(diff, double(std::abs(a.mix.clip.samples[i] - b.mix.clip.samples[i])));
    CHECK(diff > 1e-3);
}

TEST_CASE("render asset: one stem and no loop is exactly render_song") {
    Json j = demo();
    j["sections"][1]["kind"] = "section";
    SongDoc song = parsed(j);
    SongRenderOptions ro;
    ro.tailSeconds = 1.0;
    auto plain = render_song(song, timeline_of(song), ro);
    REQUIRE(bool(plain));
    const SongAssetRender r = render_asset(song);
    REQUIRE(r.mix.clip.samples.size() == plain->clip.samples.size());
    CHECK(r.mix.clip.samples == plain->clip.samples);
}

TEST_CASE("stems: the plan has the layers, the tracks or the buses, and says what is wrong when it cannot") {
    SongDoc song = parsed(demo());
    auto layers = song_stem_plan(song, "layers");
    REQUIRE(bool(layers));
    CHECK(layers->names == std::vector<std::string>{"rhythm", "harmony", "other"});
    CHECK(layers->kinds[0] == "layer");
    auto tracks = song_stem_plan(song, "tracks");
    REQUIRE(bool(tracks));
    CHECK(tracks->names == std::vector<std::string>{"pad", "pluck", "drums"});
    auto buses = song_stem_plan(song, "buses");
    REQUIRE(bool(buses));
    CHECK(buses->names == std::vector<std::string>{"dry", "bus_hall"});
    auto bad = song_stem_plan(song, "bus");
    REQUIRE_FALSE(bool(bad));
    CHECK(bad.error().hint.find("\"buses\"") != std::string::npos);
    Json plain = demo();
    plain.erase("layers");
    plain["mixer"].erase("buses");
    plain["tracks"]["pad"].erase("sends");
    plain["tracks"]["pluck"].erase("sends");
    SongDoc noLayers = parsed(plain);
    auto none = song_stem_plan(noLayers, "layers");
    REQUIRE_FALSE(bool(none));
    CHECK(none.error().message.find("layers") != std::string::npos);
    auto nobus = song_stem_plan(noLayers, "buses");
    REQUIRE_FALSE(bool(nobus));
    CHECK(nobus.error().message.find("no buses") != std::string::npos);
}

TEST_CASE("stems: same length and loop points, and they add up to the mix") {
    for (const char* grouping : {"layers", "tracks", "buses"}) {
        SUBCASE(grouping) {
            SongDoc song = parsed(demo());
            SongAssetOptions o;
            o.stems = *song_stem_plan(song, grouping);
            const SongAssetRender r = render_asset(song, o);
            REQUIRE(r.stems.size() == o.stems->names.size());
            std::vector<double> sum(r.mix.clip.samples.size(), 0.0);
            for (const SongStem& s : r.stems) {
                CHECK(s.clip.samples.size() == r.mix.clip.samples.size());
                REQUIRE(s.clip.loop.has_value());
                CHECK(s.clip.loop->start == r.mix.clip.loop->start);
                CHECK(s.clip.loop->end == r.mix.clip.loop->end);
                CHECK(peak_of(s.clip.samples) > 0.0);
                for (std::size_t i = 0; i < sum.size(); ++i) sum[i] += double(s.clip.samples[i]);
            }
            double worst = 0.0;
            for (std::size_t i = 0; i < sum.size(); ++i)
                worst = std::max(worst, std::abs(sum[i] - double(r.mix.clip.samples[i])));
            CHECK(r.stemsExact);
            CHECK(worst < 1e-4 * peak_of(r.mix.clip.samples));
            CHECK(r.stemSumErrorDb < -80.0);
        }
    }
}

TEST_CASE(
    "stems: they carry the loudness gain and the limiter of the mix, so they add up to it before and after limiting") {
    Json j = demo();
    j["mixer"]["master"] = Json::parse(R"({"loudness": -9, "limiter": {"ceilingDb": -3, "release": 0.05}})");
    j["volume"] = 1.4;
    SongDoc song = parsed(j);
    SongAssetOptions o;
    o.stems = *song_stem_plan(song, "tracks");
    const SongAssetRender r = render_asset(song, o);
    CHECK(r.mix.master.limiterReductionDb > 0.0);  // the limiter acted, so the stems had to follow its gain
    CHECK(r.mix.master.normalizeGainDb != 0.0);
    std::vector<double> sum(r.mix.clip.samples.size(), 0.0);
    for (const SongStem& s : r.stems)
        for (std::size_t i = 0; i < sum.size(); ++i) sum[i] += double(s.clip.samples[i]);
    double worst = 0.0;
    for (std::size_t i = 0; i < sum.size(); ++i)
        worst = std::max(worst, std::abs(sum[i] - double(r.mix.clip.samples[i])));
    CHECK(worst < 1e-4);
    CHECK(r.stemSumErrorDb < -80.0);
    // the mix stays under the ceiling (-3 dBFS = 0.708)
    CHECK(peak_of(r.mix.clip.samples) <= 0.7080);
}

TEST_CASE("stems: a compressor on the master acts on the sum, so the stems add up only approximately, and the result "
          "says so") {
    Json j = demo();
    j["mixer"]["master"]["effects"] = Json::parse(R"([{"type": "compressor", "thresholdDb": -30, "ratio": 6}])");
    SongDoc song = parsed(j);
    SongAssetOptions o;
    o.stems = *song_stem_plan(song, "layers");
    const SongAssetRender r = render_asset(song, o);
    CHECK_FALSE(r.stemsExact);
    CHECK(r.stemSumErrorDb > -80.0);
}
