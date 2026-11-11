// The pure part of the music player: the song's timeline as frames, quantization, layer gains, the live/stems choice, and the sources
// (live render, stem files). Nothing here touches the mixer.
#include <algorithm>
#include <cmath>

#include "audio_decoder.h"
#include "music_stream.h"
#include "fa/audio/analysis.h"
#include "fa/audio/music_player.h"
#include "fa/audio/song_preview.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

namespace fa {

namespace {
constexpr double kEps = 1e-6;
constexpr std::int64_t kMusicStreamAutoFrames = 20 * std::int64_t(kMusicRate);  // import.music.stream "auto": stems of 20 s or more stream
}

const char* music_quantize_name(MusicQuantize q) {
    switch (q) {
        case MusicQuantize::None: return "none";
        case MusicQuantize::Beat: return "beat";
        case MusicQuantize::Bar: return "bar";
        case MusicQuantize::Section: return "section";
    }
    return "none";
}

std::optional<MusicQuantize> music_quantize_from_name(std::string_view name) {
    const std::string n = to_lower(std::string(name));
    if (n == "none" || n == "now" || n == "immediate") return MusicQuantize::None;
    if (n == "beat") return MusicQuantize::Beat;
    if (n == "bar") return MusicQuantize::Bar;
    if (n == "section") return MusicQuantize::Section;
    return std::nullopt;
}

float music_layer_gain(float intensity, float threshold, float range) {
    if (threshold <= 0.0f) return 1.0f;
    if (intensity >= threshold) return 1.0f;
    const float lo = threshold - std::max(range, 0.0f);
    if (range <= 0.0f || intensity <= lo) return 0.0f;
    const float t = (intensity - lo) / range;
    return t * t * (3.0f - 2.0f * t);
}

MusicMode music_resolve_mode(MusicMode mode, const MusicDeviceProfile& d, bool stemsAvailable, std::string* why) {
    auto say = [&](const char* text) { if (why) *why = text; };
    if (mode == MusicMode::Live) { say("mode is live"); return MusicMode::Live; }
    if (mode == MusicMode::Stems) {
        if (stemsAvailable) { say("mode is stems"); return MusicMode::Stems; }
        say("mode is stems but the song has no stem files (run music.render)");
        return MusicMode::Live;
    }
    const bool handheld = d.formFactor == "phone" || d.formFactor == "tablet";
    const bool needsStems = d.web || d.tier == "low" || (handheld && d.tier != "high");
    if (!stemsAvailable) {
        say(needsStems ? "auto would use stems on this device but the song has none (run music.render)"
                       : "auto: the song has no stem files, so it renders live (run music.render to stream it from its stems)");
        return MusicMode::Live;
    }
    // A song with stem files plays from them on every device: a long stem streams from its ogg (a window of a few MB instead of 10 MB per
    // minute per stem), and there is no render to wait for.
    say(d.web ? "auto: stems on the web" : d.tier == "low" ? "auto: stems on a low-tier device"
        : needsStems ? "auto: stems on a phone or tablet that is not high-tier"
                     : "auto: the song has stem files, which stream from disk instead of rendering the song in memory");
    return MusicMode::Stems;
}

// ---- the map -------------------------------------------------------------------------------------------------------------------

int MusicMap::section_index(std::string_view name) const {
    for (std::size_t i = 0; i < sections.size(); ++i)
        if (sections[i].name == name) return int(i);
    return -1;
}

std::vector<std::string> MusicMap::section_names() const {
    std::vector<std::string> out;
    for (const MusicSection& s : sections) out.push_back(s.name);
    return out;
}

int MusicMap::span_at(double frame) const {
    if (spans.empty() || frame < spans.front().start - kEps || frame >= spans.back().end) return -1;
    std::size_t lo = 0, hi = spans.size();
    while (hi - lo > 1) {
        const std::size_t mid = (lo + hi) / 2;
        if (spans[mid].start <= frame + kEps) lo = mid;
        else hi = mid;
    }
    return int(lo);
}

void MusicMap::position(double frame, int& bar, int& beat) const {
    bar = 1;
    beat = 1;
    if (marks.empty()) return;
    auto it = std::upper_bound(marks.begin(), marks.end(), frame + kEps, [](double f, const MusicMark& m) { return f < m.frame; });
    if (it == marks.begin()) return;
    --it;
    bar = it->bar;
    beat = it->beat;
}

double music_tick_frame(const SongDoc& song, std::int64_t tick) {
    const double spt = 60.0 / (song.tempo * double(kSongPpq));
    return double(std::size_t(double(tick) * spt * double(kMusicRate) + 0.5));
}

Result<MusicMap> music_map_build(const SongDoc& song, const SongTimeline& timeline, std::int64_t clipFrames) {
    MusicMap m;
    m.tempo = song.tempo;
    m.meter = song.meter;
    const std::int64_t barTicks = song.meter.barTicks(), strong = std::max<std::int64_t>(1, song.meter.strongTicks());
    m.barFrames = music_tick_frame(song, barTicks);
    m.beatFrames = music_tick_frame(song, strong);
    m.musicEnd = music_tick_frame(song, timeline.totalTicks);
    m.frames = clipFrames > 0 ? clipFrames : std::int64_t(m.musicEnd);
    if (timeline.spans.empty() || m.musicEnd <= 0.0)
        return make_error("the song has no music to play (no notes or sections)", "Add a pattern to a section of the song (music.info shows its structure).");

    for (const SongSection& s : song.sections) {
        MusicSection ms;
        ms.name = s.name;
        ms.kind = s.kind;
        ms.firstSpan = -1;
        m.sections.push_back(std::move(ms));
    }
    for (const SongSpan& sp : timeline.spans) {
        MusicSpan out;
        out.section = sp.section;
        out.pass = sp.pass;
        out.start = music_tick_frame(song, sp.startTick);
        out.end = music_tick_frame(song, sp.endTick);
        out.startBar = sp.startBar + 1;
        out.bars = sp.bars;
        const int index = int(m.spans.size());
        if (sp.section >= 0 && sp.section < int(m.sections.size()) && m.sections[std::size_t(sp.section)].firstSpan < 0)
            m.sections[std::size_t(sp.section)].firstSpan = index;
        m.spans.push_back(out);
        for (std::int64_t t = sp.startTick; t < sp.endTick; t += strong) {
            MusicMark mk;
            mk.frame = music_tick_frame(song, t);
            mk.bar = int(t / barTicks) + 1;
            mk.beat = int((t % barTicks) / strong) + 1;
            mk.span = index;
            mk.sectionStart = t == sp.startTick;
            m.marks.push_back(mk);
        }
    }

    // The loop: the loop sections, whole (the renderer's find_loop, in the same frames).
    std::vector<int> loopSections;
    for (std::size_t i = 0; i < song.sections.size(); ++i)
        if (song.sections[i].kind == "loop") loopSections.push_back(int(i));
    for (std::size_t k = 1; k < loopSections.size(); ++k)
        if (loopSections[k] != loopSections[k - 1] + 1)
            return make_error("the sections `" + song.sections[std::size_t(loopSections[k - 1])].name + "` and `" + song.sections[std::size_t(loopSections[k])].name +
                                  "` are both of kind \"loop\", with other sections between them",
                              "The loop is one stretch of the song: make the sections between them kind \"section\", or put the loop sections next to each other.");
    if (!loopSections.empty()) {
        bool any = false;
        for (const MusicSpan& sp : m.spans) {
            if (sp.section < loopSections.front() || sp.section > loopSections.back()) continue;
            if (!any) m.loopStart = sp.start;
            m.loopEnd = sp.end;
            any = true;
        }
        m.hasLoop = any && m.loopEnd > m.loopStart;
    }

    // The end of a play-through: the end of the last outro. When music follows the outro (a stinger section after it) a short fade hides
    // the cut; when nothing follows, the clip's own tail (reverb, releases) plays out.
    m.playEnd = double(m.frames);
    m.endFade = 0.0;
    for (std::size_t i = m.spans.size(); i-- > 0;) {
        if (song.sections[std::size_t(m.spans[i].section)].kind != "outro") continue;
        if (m.spans[i].end < m.musicEnd - 0.5) {
            m.playEnd = m.spans[i].end;
            m.endFade = 0.02 * kMusicRate;
        }
        break;
    }
    return m;
}

double music_boundary(const MusicMap& map, double pos, MusicQuantize q, double limit) {
    double b = pos;
    const double top = limit > 0.0 ? limit : map.playEnd;
    auto first_mark = [&](double from) {
        return std::lower_bound(map.marks.begin(), map.marks.end(), from - kEps, [](const MusicMark& mk, double f) { return mk.frame < f; });
    };
    switch (q) {
        case MusicQuantize::None: break;
        case MusicQuantize::Beat: {
            auto it = first_mark(pos);
            b = it == map.marks.end() ? top : it->frame;
            break;
        }
        case MusicQuantize::Bar: {
            auto it = first_mark(pos);
            while (it != map.marks.end() && it->beat != 1) ++it;
            b = it == map.marks.end() ? top : it->frame;
            break;
        }
        case MusicQuantize::Section: {
            const int i = map.span_at(pos);
            if (i < 0) { b = top; break; }
            const MusicSpan& sp = map.spans[std::size_t(i)];
            b = std::fabs(pos - sp.start) <= kEps ? pos : sp.end;
            break;
        }
    }
    if (b > top) b = top;
    if (b < pos) b = pos;
    return b;
}

// ---- stems and sources ---------------------------------------------------------------------------------------------------------

std::size_t MusicStem::bytes() const { return stream ? stream->resident_bytes() : pcm.size() * sizeof(std::int16_t); }

std::size_t MusicSource::bytes() const {
    std::size_t n = 0;
    for (const MusicStem& s : stems) n += s.bytes();
    return n;
}

bool MusicSource::streamed() const {
    for (const MusicStem& s : stems)
        if (s.stream) return true;
    return false;
}

std::uint64_t MusicSource::underrun_events() const {
    std::uint64_t n = 0;
    for (const MusicStem& s : stems) n += s.stream ? s.stream->underrun_events() : 0;
    return n;
}

std::uint64_t MusicSource::underrun_frames() const {
    std::uint64_t n = 0;
    for (const MusicStem& s : stems) n += s.stream ? s.stream->underrun_frames() : 0;
    return n;
}

void music_prime(const MusicSource& src, double pos) {
    const std::int64_t chunk = std::int64_t(std::max(pos, 0.0)) >> audio_detail::kMusicChunkShift;
    for (const MusicStem& s : src.stems) {
        if (!s.stream || !s.stream->claim()) continue;  // a decode job has it: it keeps the wanted chunks coming
        s.stream->prime(chunk, 2);
        s.stream->unclaim();
    }
}

MusicStem music_make_stem(std::string name, float threshold, const std::vector<float>& interleaved) {
    MusicStem s;
    s.name = std::move(name);
    s.threshold = threshold;
    float peak = 0.0f;
    for (float v : interleaved) peak = std::max(peak, std::fabs(v));
    s.scale = peak > 1e-9f ? peak / 32767.0f : 1.0f / 32767.0f;
    s.pcm.resize(interleaved.size());
    const float inv = 1.0f / s.scale;
    for (std::size_t i = 0; i < interleaved.size(); ++i) {
        const float v = std::round(interleaved[i] * inv);
        s.pcm[i] = std::int16_t(std::clamp(v, -32767.0f, 32767.0f));
    }
    return s;
}

namespace {
// The loudness the style guide asks of the music bus (style.audio.loudnessLufs.music in assets.json), if it says.
std::optional<double> style_music_target() {
    const Json manifest = assets::manifest();
    auto style = manifest.find("style");
    if (style == manifest.end() || !style->is_object()) return std::nullopt;
    auto audio = style->find("audio");
    if (audio == style->end() || !audio->is_object()) return std::nullopt;
    auto bus = audio->find("loudnessLufs");
    if (bus == audio->end() || !bus->is_object()) return std::nullopt;
    auto music = bus->find("music");
    if (music == bus->end() || !music->is_number()) return std::nullopt;
    const double lufs = music->get<double>();
    return lufs <= 0.0 && lufs >= -70.0 ? std::optional<double>(lufs) : std::nullopt;
}
}  // namespace

Result<std::shared_ptr<MusicSource>> music_render_source(const SongDoc& song, const SongTimeline& timeline, std::string path) {
    auto src = std::make_shared<MusicSource>();
    src->path = std::move(path);
    src->mode = "live";
    SongAssetOptions options;
    options.loop = true;
    // Like music.render and music.preview: a song whose master says `loudness: "style"` is brought to the style guide's music level.
    if (song.mixer.master.loudness == SongMaster::Loudness::Style) options.render.targetLufs = style_music_target();
    if (!song.layers.empty()) {
        auto plan = song_stem_plan(song, "layers");
        if (!plan) return plan.error();
        options.stems = *plan;
        src->layered = plan->names.size() > 1;
    }
    auto r = render_song_asset(song, timeline, options);
    if (!r) return r.error();
    if (r->mix.clip.channels != 2) return make_error("the song render is not stereo", "This is an engine bug: report it.");
    auto map = music_map_build(song, timeline, std::int64_t(r->mix.clip.samples.size() / 2));
    if (!map) return map.error();
    src->map = std::move(*map);
    if (options.stems && !r->stems.empty()) {
        for (std::size_t i = 0; i < r->stems.size(); ++i) {
            r->stems[i].clip.samples.shrink_to_fit();
            src->stems.push_back(music_make_stem(r->stems[i].name, float(r->stems[i].intensity), r->stems[i].clip.samples));
            std::vector<float>().swap(r->stems[i].clip.samples);  // free the float copy as soon as the 16-bit one exists
        }
    } else {
        src->stems.push_back(music_make_stem("mix", 0.0f, r->mix.clip.samples));
    }
    return src;
}

MusicStemPlan music_stem_plan_of(std::string_view songPath) {
    MusicStemPlan plan;
    const std::string song = fs::normalize(songPath);
    const Json manifest = assets::manifest();
    auto assets = manifest.find("assets");
    if (assets == manifest.end() || !assets->is_object()) return plan;
    for (auto it = assets->begin(); it != assets->end(); ++it) {
        if (!it->is_object() || !it->contains("import")) continue;
        const Json& imp = (*it)["import"];
        if (!imp.is_object() || !imp.contains("music") || !imp["music"].is_object()) continue;
        const Json& m = imp["music"];
        if (m.value("role", std::string()) != "mix" || fs::normalize(m.value("song", std::string())) != song) continue;
        plan.mixPath = it.key();
        if (m.contains("stream") && m["stream"].is_string()) {
            const std::string mode = m["stream"].get<std::string>();
            if (mode == "auto" || mode == "always" || mode == "never") {
                plan.stream = mode;
            } else {
                FA_WARN("audio", "assets.json '{}': import.music.stream is \"{}\"; use \"auto\", \"always\" or \"never\" (taken as \"auto\")", it.key(), mode);
            }
        }
        if (!m.contains("stems") || !m["stems"].is_array()) return plan;
        for (const Json& s : m["stems"]) {
            if (!s.is_object() || !s.contains("path") || !s["path"].is_string()) continue;
            MusicStemFile f;
            f.path = fs::normalize(s["path"].get<std::string>());
            f.name = s.value("name", std::string());
            f.threshold = s.contains("intensity") && s["intensity"].is_number() ? s["intensity"].get<float>() : 0.0f;
            plan.files.push_back(std::move(f));
        }
        return plan;
    }
    return plan;
}

Result<std::shared_ptr<MusicSource>> music_load_stems(const SongDoc& song, const SongTimeline& timeline, std::string path, const MusicStemPlan& plan) {
    if (plan.files.empty())
        return make_error("'" + path + "' has no stem files in assets.json", "Run music.render on the song (it writes one file per layer), or play it live.");
    if (plan.files.size() > kMusicMaxStems)
        return make_error("'" + path + "' has " + std::to_string(plan.files.size()) + " stems, but a player mixes " + std::to_string(kMusicMaxStems) + " at most",
                          "Render fewer stems: music.render with stems \"layers\" and fewer song layers.");
    auto src = std::make_shared<MusicSource>();
    src->path = std::move(path);
    src->mode = "stems";
    src->layered = plan.files.size() > 1;
    std::int64_t frames = 0;
    for (const MusicStemFile& f : plan.files) {
        auto file = read_audio_file(f.path);
        if (!file) return make_error("stem '" + f.name + "' of '" + src->path + "' could not be read: " + file.error().message,
                                     "Run music.render again (it rewrites every stem), or play the song live.");
        const std::string ext = fs::extension(file->path);
        auto bytes = std::make_shared<audio_detail::Bytes>(std::move(file->bytes));
        std::string problem;
        auto decoder = audio_detail::open_decoder(bytes->data(), bytes->size(), ext, &problem);
        if (!decoder) return make_error("stem '" + f.path + "' " + problem, "Run music.render again.");
        const std::uint64_t expected = decoder->frames();
        const std::string stemName = f.name.empty() ? fs::stem(f.path) : f.name;
        // A long ogg stem streams: it keeps its encoded bytes and a window of decoded chunks (docs/MUSIC.md, "What the music costs in memory").
        const bool wantStream = ext == ".ogg" && plan.stream != "never" && expected > 0 &&
                                (plan.stream == "always" || expected >= std::uint64_t(kMusicStreamAutoFrames));
        if (wantStream) {
            std::string why;
            auto stream = audio_detail::MusicStemStream::open(bytes, ext, &why);
            if (stream) {
                const std::int64_t n = stream->frames();
                if (frames != 0 && n != frames)
                    return make_error("stem '" + f.path + "' is " + std::to_string(n) + " frames long but the others are " + std::to_string(frames),
                                      "The stems are from different renders: run music.render again.");
                frames = n;
                MusicStem stem;
                stem.name = stemName;
                stem.threshold = f.threshold;
                stem.streamFrames = n;
                stem.stream = std::move(stream);
                src->stems.push_back(std::move(stem));
                continue;
            }
            if (plan.stream == "always")
                FA_WARN("audio", "stem '{}' of '{}' cannot stream ({}), so it is decoded whole (import.music.stream is \"always\")", f.path, src->path, why);
        }
        audio_detail::Resampler resampler(bytes, std::move(decoder), false);
        std::vector<float> data;
        data.reserve(std::size_t(expected) * 2 + 32768);
        for (;;) {
            const std::size_t at = data.size();
            data.resize(at + 2 * 16384);
            const std::size_t got = resampler.pull(data.data() + at, 16384);
            data.resize(at + 2 * got);
            if (got < 16384) break;
        }
        if (data.empty()) return make_error("stem '" + f.path + "' contains no audio samples", "Run music.render again.");
        const std::int64_t n = std::int64_t(data.size() / 2);
        if (frames != 0 && n != frames)
            return make_error("stem '" + f.path + "' is " + std::to_string(n) + " frames long but the others are " + std::to_string(frames),
                              "The stems are from different renders: run music.render again.");
        frames = n;
        src->stems.push_back(music_make_stem(stemName, f.threshold, data));
    }
    auto map = music_map_build(song, timeline, frames);
    if (!map) return map.error();
    if (double(frames) + 2.0 < map->musicEnd)
        return make_error("the stems of '" + src->path + "' are " + std::to_string(frames) + " frames long but the song is now " + std::to_string(std::int64_t(map->musicEnd)) +
                              " frames: the song changed after they were rendered",
                          "Run music.render again (assets.regenerate {\"stale\": true} does it), or play the song live.");
    src->map = std::move(*map);
    // The first chunks of a streamed song are decoded before it plays, so the first block of the music is not an underrun.
    music_prime(*src, 0.0);
    if (src->map.hasLoop) music_prime(*src, src->map.loopStart);
    return src;
}

Result<std::shared_ptr<MusicSource>> music_load_source(std::string path, MusicMode mode, const MusicStemPlan& plan, std::string* note) {
    auto song = load_song(path);
    if (!song) return song.error();
    auto timeline = expand_song(*song);
    if (!timeline) return timeline.error();
    if (note) note->clear();
    if (mode == MusicMode::Stems) {
        auto stems = music_load_stems(*song, *timeline, path, plan);
        if (stems) return stems;
        if (note) *note = stems.error().to_string();
    }
    return music_render_source(*song, *timeline, std::move(path));
}

Json MusicStatus::to_json() const {
    Json j = Json::object();
    j["exists"] = exists;
    j["ready"] = ready;
    j["playing"] = playing;
    j["ended"] = ended;
    j["song"] = song;
    j["mode"] = mode;
    j["section"] = section;
    j["bar"] = bar;
    j["beat"] = beat;
    j["positionSeconds"] = positionSeconds;
    j["tempo"] = tempo;
    j["intensity"] = intensity;
    j["appliedIntensity"] = appliedIntensity;
    j["requestedIntensity"] = requestedIntensity;
    j["pendingSong"] = pendingSong.empty() ? Json(nullptr) : Json(pendingSong);
    j["pendingSection"] = pendingSection.empty() ? Json(nullptr) : Json(pendingSection);
    j["pendingAt"] = pendingAt ? Json(*pendingAt) : Json(nullptr);
    j["volume"] = volume;
    j["bus"] = bus;
    j["sections"] = sections;
    j["stems"] = stems;
    j["stemGains"] = stemGains;
    j["pending"] = pending;
    j["heads"] = heads;
    j["error"] = error;
    return j;
}

Json MusicChange::to_json() const {
    Json j = Json::object();
    j["frame"] = frame ? Json(*frame) : Json(nullptr);
    j["time"] = frame ? Json(time) : Json(nullptr);
    j["quantize"] = music_quantize_name(quantize);
    return j;
}

}  // namespace fa
