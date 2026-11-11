// music.info, music.check and music.preview: song documents (`*.song.json`, docs/MUSIC.md) as project files. The model, the checks and the
// offline renderer are fa_audio's (fa/audio/song*.h); this file reads songs from the project, shows one as a piano roll, runs the checks and
// bakes the preview into a WAV or OGG next to the song with a recipe in assets.json (so a changed song makes its preview stale and
// assets.regenerate renders it again). music.create, music.edit and the helper commands are in assets_music_edit.cpp.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "audio_mix.h"
#include "fa/audio/audio_doc.h"
#include "fa/audio/song.h"
#include "fa/audio/song_check.h"
#include "fa/audio/song_preview.h"
#include "fa/audio/song_theory.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "fa/tooling/style_guide.h"
#include "music_internal.h"
#include "picture_canvas.h"
#include "util.h"

namespace fa::assets_detail::music {

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

std::string meter_text(const SongMeter& m) { return std::to_string(m.beats) + "/" + std::to_string(m.unit); }

// ---------------------------------------------------------------- finding and reading songs ---

std::string song_path(const std::string& arg, const char* what) {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("`") + what + "` '" + arg + "' is not a song under assets/.", "Songs live in assets/, e.g. \"assets/music/theme.song.json\" (music.create writes a starting point).");
    if (!ends_with(to_lower(*norm), kSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .song.json.", "Name song documents <name>.song.json, e.g. \"assets/music/theme.song.json\".");
    return *norm;
}

std::string song_stem(const std::string& rel) { return rel.substr(0, rel.size() - std::string(kSuffix).size()); }
std::string default_preview(const std::string& rel) { return song_stem(rel) + ".preview.wav"; }

std::vector<std::string> list_songs(const std::string& projectDir) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path root = stdfs::path(projectDir) / "assets";
    if (!stdfs::is_directory(root, ec)) return out;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        if (it->is_directory(ec) && (it->path().filename() == "node_modules" || starts_with(it->path().filename().string(), "."))) {
            it.disable_recursion_pending();
            continue;
        }
        if (!it->is_regular_file(ec)) continue;
        const std::string rel = stdfs::relative(it->path(), projectDir, ec).generic_string();
        if (ends_with(to_lower(rel), kSuffix)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

Json issues_json(const std::vector<SongIssue>& issues) {
    Json list = Json::array();
    for (const SongIssue& i : issues) {
        Json j = Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}});
        if (i.line > 0) {
            j["line"] = i.line;
            j["column"] = i.column;
        }
        list.push_back(j);
    }
    return list;
}

namespace {

[[noreturn]] void invalid_song(const std::string& rel, const Result<SongDoc>& r, const std::vector<SongIssue>& issues, const char* what) {
    std::string message = r.error().message;
    if (what && *what) {
        if (message.back() != '.' && message.back() != '!' && message.back() != '?') message += '.';
        message += std::string(" ") + what;
    }
    throw CommandError("invalid_song", message, r.error().hint.empty() ? "schemas/song.schema.json describes the format; docs/MUSIC.md has the note text." : r.error().hint,
                       Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
}

}  // namespace

SongDoc check_song_json(const Json& json, const std::string& rel, const char* what) {
    std::vector<SongIssue> issues;
    auto doc = parse_song(json, rel, &issues);
    if (!doc.ok()) invalid_song(rel, doc, issues, what);
    return std::move(*doc);
}

Loaded load_song_file(const std::string& projectDir, const std::string& rel) {
    Loaded out;
    out.rel = rel;
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = list_songs(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with music.create {\"path\":\"" + rel + "\"} and edit it." : did_you_mean(rel, all) + " Songs: " + join(all, ", ") + ".");
    }
    auto json = parse_json(*text, rel);
    if (!json.ok()) fail("invalid_song", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/song.schema.json describes the format." : json.error().hint);
    out.json = std::move(*json);
    out.doc = check_song_json(out.json, rel);
    return out;
}

void write_song(const std::string& projectDir, const std::string& rel, const Json& json) {
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), dump_json(json), &err)) fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
}

Loaded resolve_song(const std::string& projectDir, const Json& a, const char* command) {
    if (int(a.contains("path")) + int(a.contains("song")) != 1)
        fail("invalid_argument", std::string(command) + ": give exactly one of `path` (a song file) and `song` (the song as JSON).", "Example: {\"path\":\"assets/music/theme.song.json\"}.");
    if (a.contains("path")) return load_song_file(projectDir, song_path(tooling_detail::arg_string(a, "path", true)));
    if (!a["song"].is_object()) fail("invalid_argument", std::string(command) + ": `song` must be the song document as a JSON object.", "Write {\"format\":\"factoria.song/1\", \"tempo\":120, \"tracks\":{...}, \"sections\":[...]}.");
    Loaded out;
    // `format` may be left out of an inline song; it comes first as in every song file.
    out.json = Json::object({{"format", kSongFormat}});
    for (auto it = a["song"].begin(); it != a["song"].end(); ++it) out.json[it.key()] = it.value();
    out.doc = check_song_json(out.json, "song");
    return out;
}

SongTimeline expand_or_fail(const SongDoc& doc, const std::string& rel) {
    auto t = expand_song(doc);
    if (!t.ok()) fail("failed", (rel.empty() ? std::string("song") : rel) + ": " + t.error().message, t.error().hint);
    return std::move(*t);
}

// ---------------------------------------------------------------- the summary ---

namespace {

std::string entries_text(const std::vector<SongPlayEntry>& entries) {
    std::string out;
    for (const SongPlayEntry& e : entries) {
        if (!out.empty()) out += ' ';
        out += (e.pattern.empty() ? std::string("rest") : e.pattern);
        if (e.repeat > 1) out += "*" + std::to_string(e.repeat);
    }
    return out;
}

const SongSpan* first_span(const SongTimeline& tl, int section) {
    for (const SongSpan& s : tl.spans)
        if (s.section == section) return &s;
    return nullptr;
}

}  // namespace

std::string structure_text(const SongDoc& doc) {
    std::string out;
    for (const SongSection& s : doc.sections) {
        if (!out.empty()) out += " > ";
        out += s.name + " (" + std::to_string(s.bars) + (s.bars == 1 ? " bar)" : " bars)");
        if (s.repeat > 1) out += " x" + std::to_string(s.repeat);
    }
    return out;
}

Json summary_json(const SongDoc& doc, const SongTimeline& tl) {
    std::vector<int> notes(doc.tracks.size(), 0), lo(doc.tracks.size(), 128), hi(doc.tracks.size(), -1);
    for (const SongNote& n : tl.notes) {
        const std::size_t t = std::size_t(n.track);
        notes[t]++;
        if (n.pitch >= 0) {
            lo[t] = std::min(lo[t], n.pitch);
            hi[t] = std::max(hi[t], n.pitch);
        }
    }
    Json tracks = Json::array();
    for (std::size_t ti = 0; ti < doc.tracks.size(); ++ti) {
        const SongTrack& t = doc.tracks[ti];
        Json patterns = Json::array();
        for (const SongPattern& p : t.patterns) patterns.push_back(Json::object({{"name", p.name}, {"bars", p.bars}, {"events", p.events.size()}}));
        Json playsIn = Json::array();
        for (const SongSection& s : doc.sections) {
            const bool muted = std::find(s.mute.begin(), s.mute.end(), t.name) != s.mute.end();
            for (const SongSectionTrack& st : s.play)
                if (st.track == t.name && !muted && !st.entries.empty()) {
                    playsIn.push_back(s.name);
                    break;
                }
        }
        Json j = Json::object({{"name", t.name}, {"instrument", t.instrument}, {"kind", t.drums ? "drums" : "pitched"}, {"volume", t.volume}, {"pan", t.pan}, {"patterns", patterns}, {"notes", notes[ti]}, {"playsIn", playsIn}});
        if (hi[ti] >= 0) j["range"] = song_pitch_name(lo[ti]) + " to " + song_pitch_name(hi[ti]);
        tracks.push_back(j);
    }
    Json sections = Json::array();
    for (std::size_t si = 0; si < doc.sections.size(); ++si) {
        const SongSection& s = doc.sections[si];
        Json play = Json::object();
        for (const SongSectionTrack& st : s.play) play[st.track] = entries_text(st.entries);
        Json j = Json::object({{"name", s.name}, {"kind", s.kind}, {"bars", s.bars}, {"repeat", s.repeat}, {"play", play}});
        if (!s.mute.empty()) j["mute"] = s.mute;
        if (const SongSpan* span = first_span(tl, int(si))) {
            Json counts = Json::object();
            int total = 0;
            for (const SongNote& n : tl.notes)
                if (n.tick >= span->startTick && n.tick < span->endTick) {
                    const std::string& tn = doc.tracks[std::size_t(n.track)].name;
                    counts[tn] = counts.value(tn, 0) + 1;
                    ++total;
                }
            j["startBar"] = span->startBar + 1;
            j["startSeconds"] = num(doc.ticks_to_seconds(span->startTick));
            j["secondsPerPass"] = num(doc.ticks_to_seconds(span->endTick - span->startTick));
            j["notesPerPass"] = total;
            j["notesByTrack"] = counts;
            if (s.bars > 0) j["notesPerBar"] = num(double(total) / double(s.bars), 1);
        }
        sections.push_back(j);
    }
    Json out = Json::object({{"tempo", doc.tempo},
                             {"meter", meter_text(doc.meter)},
                             {"key", doc.key},
                             {"mode", doc.mode},
                             {"swing", doc.swing},
                             {"bars", tl.bars},
                             {"seconds", num(tl.seconds)},
                             {"notes", tl.notes.size()},
                             {"structure", structure_text(doc)},
                             {"tracks", tracks},
                             {"sections", sections}});
    if (!doc.doc.empty()) out["doc"] = doc.doc;
    if (!doc.layers.empty()) {
        Json layers = Json::array();
        for (const SongLayer& l : song_layers(doc)) {
            Json lj = Json::object({{"name", l.name}, {"tracks", l.tracks}, {"intensity", round_to(l.intensity, 4)}});
            if (!l.doc.empty()) lj["doc"] = l.doc;
            layers.push_back(lj);
        }
        out["layers"] = layers;
    }
    return out;
}

// ---------------------------------------------------------------- the piano roll ---

namespace {

using picture::Canvas;
using picture::Rgb;

std::filesystem::path next_picture_file(const std::string& projectDir) {
    static std::atomic<int> counter{0};
    const std::filesystem::path dir = project_file(projectDir, kScreenshotDir);
    std::error_code ec;
    for (;;) {
        const std::filesystem::path file = dir / std::format("frame_{}_pianoroll.png", ++counter);
        if (!std::filesystem::exists(file, ec)) return file;
    }
}

constexpr Rgb kPalette[] = {{86, 180, 233}, {230, 159, 0}, {0, 190, 140}, {240, 228, 66}, {204, 121, 167}, {235, 110, 40}, {150, 150, 255}, {200, 200, 200}};

bool is_black_key(int midi) {
    const int pc = ((midi % 12) + 12) % 12;
    return pc == 1 || pc == 3 || pc == 6 || pc == 8 || pc == 10;
}

}  // namespace

void add_piano_roll(const std::string& projectDir, const Json& a, const SongDoc& doc, const SongTimeline& tl, Json& result) {
    const int width = int(std::clamp<long>(tooling_detail::arg_int(a, "width", 1000), 400, 2400));
    const std::string outRel = tooling_detail::arg_string(a, "pictureOut", false);
    std::filesystem::path outFile;
    if (!outRel.empty()) {
        if (to_lower(fs::extension(outRel)) != ".png") fail("invalid_argument", "`pictureOut` must end in .png.", "Example: \"pictureOut\": \"assets/music/theme.png\".");
        outFile = project_file(projectDir, outRel);
    }
    const std::int64_t barTicks = doc.meter.barTicks();
    const long fromBar = std::clamp<long>(tooling_detail::arg_int(a, "fromBar", 1), 1, std::max(1, tl.bars));
    const long barsArg = tooling_detail::arg_int(a, "bars", 0);
    const std::int64_t t0 = std::int64_t(fromBar - 1) * barTicks;
    const std::int64_t t1 = barsArg > 0 ? std::min<std::int64_t>(tl.totalTicks, t0 + barsArg * barTicks) : tl.totalTicks;
    const std::int64_t span = std::max<std::int64_t>(barTicks, t1 - t0);

    // The pitch and drum rows that appear in the window.
    int lowPitch = 128, highPitch = -1;
    std::vector<std::pair<int, std::string>> drumRows;  // (track, lane)
    for (const SongNote& n : tl.notes) {
        if (n.tick >= t1 || n.end() <= t0) continue;
        if (n.pitch >= 0) {
            lowPitch = std::min(lowPitch, n.pitch);
            highPitch = std::max(highPitch, n.pitch);
        } else {
            const std::pair<int, std::string> row{n.track, n.drum};
            if (std::find(drumRows.begin(), drumRows.end(), row) == drumRows.end()) drumRows.push_back(row);
        }
    }
    std::sort(drumRows.begin(), drumRows.end());
    if (drumRows.size() > 24) drumRows.resize(24);
    const bool pitched = highPitch >= 0;
    if (pitched) {
        lowPitch = std::max(0, lowPitch - 1);
        highPitch = std::min(127, highPitch + 1);
    }
    const int rows = pitched ? highPitch - lowPitch + 1 : 0;
    const int rowH = pitched ? std::clamp(300 / rows, 3, 10) : 0;
    const int pitchedH = rows * rowH;
    const int drumRowH = 10;
    const int drumsH = int(drumRows.size()) * drumRowH;

    const int left = 70, right = 12, top = 24, bandH = 16, rulerH = 14, gap = 6, legendH = 20;
    const int plotW = width - left - right;
    const int bandY = top, rulerY = bandY + bandH + 2, pitchedY = rulerY + rulerH, drumsY = pitchedY + pitchedH + (pitched && drumsH ? gap : 0);
    const int height = drumsY + drumsH + gap + legendH;
    const Rgb bg{18, 18, 24}, axis{150, 150, 165}, white{255, 255, 255};
    Canvas cv(width, height, bg);
    auto x_of = [&](std::int64_t tick) { return left + int(std::llround(double(tick - t0) * double(plotW - 1) / double(span))); };

    cv.text(std::format("{}   {:g} bpm  {}  {} {}  {} bars  {:.1f} s", doc.doc.empty() ? std::string("song") : doc.doc.substr(0, 60), doc.tempo, meter_text(doc.meter), doc.key, doc.mode, tl.bars, tl.seconds), left, 5, 12, {235, 235, 240});

    // the sections
    for (const SongSpan& sp : tl.spans) {
        if (sp.endTick <= t0 || sp.startTick >= t1) continue;
        const SongSection& s = doc.sections[std::size_t(sp.section)];
        const Rgb c = s.kind == "intro" ? Rgb{70, 120, 200} : s.kind == "loop" ? Rgb{60, 160, 100} : s.kind == "outro" ? Rgb{200, 120, 60} : Rgb{120, 120, 140};
        const int x0 = std::max(left, x_of(std::max(sp.startTick, t0))), x1 = std::min(left + plotW - 1, x_of(std::min(sp.endTick, t1)));
        cv.rect(x0, bandY, std::max(x0, x1 - 1), bandY + bandH - 1, c, 0.75);
        const std::string label = s.repeat > 1 ? s.name + " " + std::to_string(sp.pass + 1) + "/" + std::to_string(s.repeat) : s.name;
        if ((x1 - x0) > int(label.size()) * 6 + 6) cv.text(label, x0 + 4, bandY + 2, 11, white);
        else if ((x1 - x0) > 14) cv.text(s.name.substr(0, std::max<std::size_t>(1, std::size_t(x1 - x0 - 8) / 6)), x0 + 3, bandY + 2, 11, white);
        cv.vline(x0, bandY, pitchedY + pitchedH + (drumsH ? gap + drumsH : 0) - 1, white, 0.22);
    }

    // pitch rows
    for (int m = highPitch; pitched && m >= lowPitch; --m) {
        const int y = pitchedY + (highPitch - m) * rowH;
        if (is_black_key(m)) cv.rect(left, y, left + plotW - 1, y + rowH - 1, white, 0.04);
        if (m % 12 == 0) {
            cv.hline(left, left + plotW - 1, y + rowH - 1, white, 0.14);
            cv.text(song_pitch_name(m), left - 6, y + rowH / 2, 10, axis, 2, true);
        }
    }

    // bars and beats
    const double pxPerBar = double(plotW) * double(barTicks) / double(span);
    long labelEvery = 1;
    while (pxPerBar * double(labelEvery) < 30.0) labelEvery *= 2;
    const std::int64_t beatTicks = doc.meter.beatTicks();
    const int plotBottom = drumsY + drumsH - 1;
    for (std::int64_t t = t0 - t0 % beatTicks; t <= t1; t += beatTicks) {
        if (t < t0) continue;
        const bool barLine = t % barTicks == 0;
        const int x = x_of(t);
        if (barLine) {
            const long bar = long(t / barTicks) + 1;
            cv.vline(x, pitchedY, plotBottom, white, 0.18);
            if ((bar - 1) % labelEvery == 0) cv.text(std::to_string(bar), x + 2, rulerY, 10, axis);
        } else if (pxPerBar / doc.meter.beats >= 7.0) {
            cv.vline(x, pitchedY, plotBottom, white, 0.06);
        }
    }

    // notes
    for (const SongNote& n : tl.notes) {
        if (n.tick >= t1 || n.end() <= t0) continue;
        const Rgb c = kPalette[std::size_t(n.track) % (sizeof(kPalette) / sizeof(kPalette[0]))];
        const double alpha = 0.45 + 0.55 * std::min(1.0, double(n.velocity) / 127.0);
        const int x0 = x_of(std::max(n.tick, t0)), x1 = x_of(std::min(n.tick + n.gateTicks(), t1));
        if (n.pitch >= 0) {
            const int y = pitchedY + (highPitch - n.pitch) * rowH;
            cv.rect(x0, y, std::max(x0, x1 - 1), y + std::max(1, rowH - 2), c, alpha);
        } else {
            const auto it = std::find(drumRows.begin(), drumRows.end(), std::pair<int, std::string>{n.track, n.drum});
            if (it == drumRows.end()) continue;
            const int y = drumsY + int(it - drumRows.begin()) * drumRowH;
            cv.rect(x0, y + 1, x0 + 2, y + drumRowH - 2, c, alpha);
        }
    }
    for (std::size_t i = 0; i < drumRows.size(); ++i) {
        const int y = drumsY + int(i) * drumRowH;
        cv.hline(left, left + plotW - 1, y + drumRowH - 1, white, 0.08);
        cv.text(drumRows[i].second, left - 6, y + drumRowH / 2, 10, axis, 2, true);
    }

    // legend: a square and the name of each track
    int lx = left;
    const int ly = height - legendH + 4;
    for (std::size_t ti = 0; ti < doc.tracks.size(); ++ti) {
        const Rgb c = kPalette[ti % (sizeof(kPalette) / sizeof(kPalette[0]))];
        cv.rect(lx, ly + 1, lx + 8, ly + 9, c);
        const std::string label = doc.tracks[ti].name + " (" + doc.tracks[ti].instrument + ")";
        cv.text(label, lx + 13, ly, 11, axis);
        lx += 13 + int(label.size()) * 6 + 14;
        if (lx > width - 100) break;
    }

    const std::vector<std::uint8_t> png = encode_png(cv.img);
    const bool keep = !outRel.empty();
    const std::filesystem::path file = keep ? outFile : next_picture_file(projectDir);
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);
    Json pic = Json::object({{"width", width}, {"height", height}, {"fromBar", fromBar}, {"toBar", int(std::min<std::int64_t>(tl.bars, (t1 + barTicks - 1) / barTicks))}});
    if (pitched) pic["pitchRange"] = song_pitch_name(lowPitch) + " to " + song_pitch_name(highPitch);
    if (keep) pic["out"] = outRel;
    result["pianoRoll"] = pic;
    Json image = Json::object({{"path", file.string()}, {"mimeType", "image/png"}});
    if (!keep) image["temporary"] = true;
    result["$image"] = image;
}

// ---------------------------------------------------------------- music.info ---

namespace {

bool preview_is_ours(const std::string& projectDir, const std::string& outRel) {
    const std::string manifest = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
    if (manifest.empty()) return false;
    auto parsed = parse_json(manifest, assets::kManifestFile);
    if (!parsed.ok() || !parsed->is_object() || !parsed->contains("assets") || !(*parsed)["assets"].is_object()) return false;
    auto it = (*parsed)["assets"].find(outRel);
    if (it == (*parsed)["assets"].end()) return false;
    const Json recipe = recipe_of(*it);
    return recipe.is_object() && recipe.value("command", std::string()) == "music.preview";
}

Json music_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.info", a, "", {"path", "song", "picture", "pictureOut", "width", "fromBar", "bars"});
    Loaded loaded = resolve_song(projectDir, a, "music.info");
    const SongTimeline tl = expand_or_fail(loaded.doc, loaded.rel);
    Json result = summary_json(loaded.doc, tl);
    if (!loaded.rel.empty()) {
        Json head = Json::object({{"path", loaded.rel}, {"valid", true}});
        for (auto it = result.begin(); it != result.end(); ++it) head[it.key()] = it.value();
        result = std::move(head);
        const std::string out = default_preview(loaded.rel);
        std::error_code ec;
        const bool exists = stdfs::exists(project_file(projectDir, out), ec);
        Json preview = Json::object({{"path", out}, {"exists", exists}});
        if (exists) {
            preview["madeByPreview"] = preview_is_ours(projectDir, out);
            if (preview["madeByPreview"].get<bool>()) {
                const std::string manifest = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
                Json recipe;
                if (auto parsed = parse_json(manifest, assets::kManifestFile); parsed.ok() && parsed->is_object() && parsed->contains("assets") && (*parsed)["assets"].is_object())
                    if (auto it = (*parsed)["assets"].find(out); it != (*parsed)["assets"].end()) recipe = recipe_of(*it);
                preview["stale"] = check_recipe(projectDir, recipe).stale();
            }
        }
        result["preview"] = preview;
    } else {
        result["valid"] = true;
    }
    if (tooling_detail::arg_bool(a, "picture", true)) add_piano_roll(projectDir, a, loaded.doc, tl, result);
    Json steps = Json::array();
    if (tooling_detail::arg_bool(a, "picture", true))
        steps.push_back("Read the picture: coloured bars are notes (one colour per track, brighter = louder), the lower rows are the drum lanes, the strip on top is the sections.");
    steps.push_back("music.check finds notes outside the key, clashes and mud (add \"render\": true for the loudness); music.preview renders the song to a WAV you can measure.");
    result["nextSteps"] = steps;
    return result;
}

// ---------------------------------------------------------------- music.check ---

Json check_issue_json(const SongCheckIssue& i) {
    Json j = Json::object({{"rule", i.rule}, {"severity", i.severity}, {"message", i.message}, {"hint", i.hint}});
    if (!i.track.empty()) j["track"] = i.track;
    if (!i.pattern.empty()) j["pattern"] = i.pattern;
    if (!i.section.empty()) j["section"] = i.section;
    if (i.bar > 0) {
        j["bar"] = i.bar;
        j["position"] = i.position;
    }
    if (!i.source.pointer.empty()) {
        j["pointer"] = i.source.pointer;
        if (i.source.line > 0) {
            j["line"] = i.source.line;
            j["column"] = i.source.column;
        }
        if (!i.source.label.empty()) j["token"] = i.source.label;
    }
    if (i.count > 1) j["count"] = i.count;
    return j;
}

// The loudness the style guide asks of the music bus (style.audio.loudnessLufs.music in assets.json), if it says.
std::optional<double> style_music_lufs(const std::string& projectDir) { return style_music_loudness(projectDir); }

// What the mixer did in a render: per-track levels, the buses and the master (loudness normalization and limiter).
Json mix_json(const SongDoc& doc, const SongRender& render, const std::optional<double>& styleTarget) {
    Json tracks = Json::array();
    for (const SongTrackStats& t : render.tracks) {
        const SongTrack* track = doc.find_track(t.name);
        Json j = Json::object({{"track", t.name}, {"notes", t.notes}, {"peakDb", round_to(t.peakDb, 1)}, {"lufs", round_to(t.lufs, 1)}});
        if (track) {
            j["volume"] = track->volume;
            j["pan"] = track->pan;
            if (!track->effects.empty()) j["effects"] = Json::array();
            for (const AudioStep& e : track->effects) j["effects"].push_back(e.type);
            if (!track->sends.empty()) j["sends"] = track->sends;
        }
        tracks.push_back(j);
    }
    const SongMasterStats& m = render.master;
    Json master = Json::object({{"lufs", round_to(render.clip.lufs, 1)}, {"peakDb", round_to(render.clip.peakDb, 1)},
                                {"lufsBeforeLimiter", round_to(m.lufsBefore, 1)}, {"peakBeforeDb", round_to(m.peakBeforeDb, 1)},
                                {"limiter", m.limiter}, {"limiterReductionDb", round_to(m.limiterReductionDb, 1)}, {"normalizeGainDb", round_to(m.normalizeGainDb, 1)}});
    if (m.limiter) master["ceilingDb"] = m.ceilingDb;
    if (m.targetLufs) {
        master["targetLufs"] = *m.targetLufs;
        master["loudness"] = doc.mixer.master.loudness == SongMaster::Loudness::Style ? "style" : "target";
        if (doc.mixer.master.loudness == SongMaster::Loudness::Style) master["targetSource"] = "style.audio.loudnessLufs.music in assets.json";
    } else {
        master["loudness"] = doc.mixer.master.loudness == SongMaster::Loudness::Off ? "off" : "style";
        if (doc.mixer.master.loudness == SongMaster::Loudness::Style && !styleTarget) master["loudnessNote"] = "style: the project's style guide sets no music loudness, so the level is what the mix adds up to";
    }
    Json buses = Json::array();
    for (const SongBus& b : doc.mixer.buses) {
        Json bj = Json::object({{"bus", b.name}, {"volume", b.volume}, {"pan", b.pan}, {"mute", b.mute}, {"effects", Json::array()}});
        for (const AudioStep& e : b.effects) bj["effects"].push_back(e.type);
        buses.push_back(bj);
    }
    return Json::object({{"tracks", tracks}, {"buses", buses}, {"master", master}});
}

// The music loudness the render brings the master to, when the song asks for the style's: the project's style guide.
std::optional<double> style_target_for(const std::string& projectDir, const SongDoc& doc) {
    if (doc.mixer.master.loudness != SongMaster::Loudness::Style) return std::nullopt;
    return style_music_lufs(projectDir);
}

Json music_check_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.check", a, "", {"path", "song", "rules", "render", "targetLufs"});
    Loaded loaded = resolve_song(projectDir, a, "music.check");
    const SongTimeline tl = expand_or_fail(loaded.doc, loaded.rel);
    SongCheckOptions options;
    if (a.contains("rules")) {
        if (!a["rules"].is_array()) fail("invalid_argument", "music.check: `rules` must be a list of rule names.", "Rules: " + [] { std::string s; for (const SongCheckRule& r : song_check_rules()) s += (s.empty() ? "" : ", ") + r.name; return s; }() + ".");
        for (const Json& r : a["rules"]) {
            if (!r.is_string()) fail("invalid_argument", "music.check: a rule name must be text, got " + r.dump() + ".", "Example: \"rules\": [\"off_key\", \"clash\"].");
            options.rules.push_back(r.get<std::string>());
        }
    }
    options.render = tooling_detail::arg_bool(a, "render", false);
    Json target = Json::object();
    if (a.contains("targetLufs")) {
        if (!a["targetLufs"].is_number() || a["targetLufs"].get<double>() > 0 || a["targetLufs"].get<double>() < -70)
            fail("invalid_argument", "music.check: `targetLufs` must be a number from -70 to 0.", "The integrated loudness the music should have, e.g. -18; +-3 LU is accepted.");
        options.targetLufs = a["targetLufs"].get<double>();
        target = Json::object({{"lufs", *options.targetLufs}, {"source", "the targetLufs argument"}});
    } else if (options.render || std::find(options.rules.begin(), options.rules.end(), "loudness") != options.rules.end()) {
        if (auto t = style_music_lufs(projectDir)) {
            options.targetLufs = *t;
            target = Json::object({{"lufs", *t}, {"source", "style.audio.loudnessLufs.music in assets.json"}});
        }
    }
    Result<SongCheckReport> report = [&] {
        ProjectRootGuard root(projectDir);
        return check_song(loaded.doc, tl, options);
    }();
    if (!report.ok()) fail("invalid_argument", "music.check: " + report.error().message, report.error().hint);
    Json issues = Json::array();
    int errors = 0, warnings = 0, infos = 0;
    for (const SongCheckIssue& i : report->issues) {
        issues.push_back(check_issue_json(i));
        (i.severity == "error" ? errors : i.severity == "warning" ? warnings : infos)++;
    }
    Json result = Json::object({{"ok", report->ok()}, {"valid", true}, {"rulesRun", report->rulesRun}, {"notes", report->notes}, {"errors", errors}, {"warnings", warnings}, {"info", infos}, {"issues", issues}});
    if (!loaded.rel.empty()) result["path"] = loaded.rel;
    if (report->rendered) {
        result["loudness"] = Json::object({{"lufs", num(report->lufs, 1)}, {"peakDb", num(report->peakDb, 1)}});
        if (!target.empty()) result["target"] = target;
    }
    Json steps = Json::array();
    if (!report->ok()) steps.push_back("Fix the findings from the top (each has a hint and, for a note, the token's pointer, line and column), then call music.check again; music.edit changes a pattern.");
    else steps.push_back("No errors or warnings" + std::string(report->rendered ? "" : "; add \"render\": true to check the loudness too") + ". Listen with music.preview.");
    result["nextSteps"] = steps;
    return result;
}

// ---------------------------------------------------------------- music.preview ---

// The render options the arguments of music.preview and music.mix share: the range, the solo and mute lists, the seed, the sample rate
// and the style's loudness target.
SongRenderOptions render_options(const std::string& command, const std::string& projectDir, const Json& a, const SongDoc& doc, const SongTimeline& tl,
                                 std::optional<double>& styleTarget) {
    SongRenderOptions options;
    if (a.contains("sampleRate")) {
        const long sr = tooling_detail::arg_int(a, "sampleRate", 44100);
        if (sr != 22050 && sr != 32000 && sr != 44100 && sr != 48000) fail("invalid_argument", command + ": `sampleRate` must be 22050, 32000, 44100 or 48000.", "44100 is the default; 22050 renders faster and is enough to judge a part.");
        options.sampleRate = int(sr);
    }
    if (a.contains("fromBar")) {
        const long b = tooling_detail::arg_int(a, "fromBar", 1);
        if (b < 1 || b > std::max(1, tl.bars)) fail("invalid_argument", command + ": `fromBar` " + std::to_string(b) + " is outside the song's " + std::to_string(tl.bars) + " bars.", "Bars are numbered from 1; music.info lists where each section starts.");
        options.fromBar = int(b);
    }
    if (a.contains("bars")) {
        const long b = tooling_detail::arg_int(a, "bars", 0);
        if (b < 1 || b > kSongMaxBars) fail("invalid_argument", command + ": `bars` must be a whole number of bars, 1 or more.", "Render a part of the song, e.g. {\"fromBar\": 9, \"bars\": 8}.");
        options.bars = int(b);
    }
    for (const char* key : {"solo", "mute"}) {
        if (!a.contains(key)) continue;
        std::vector<std::string> names;
        for (const SongTrack& t : doc.tracks) names.push_back(t.name);
        if (!a[key].is_array()) fail("invalid_argument", std::string(command + ": `") + key + "` must be a list of track names.", "Tracks: " + join(names, ", ") + ".");
        for (const Json& n : a[key]) {
            const std::string name = n.is_string() ? n.get<std::string>() : std::string();
            if (std::find(names.begin(), names.end(), name) == names.end())
                fail("invalid_argument", std::string(command + ": `") + key + "` names the unknown track " + n.dump() + ".", did_you_mean(name, names) + " Tracks: " + join(names, ", ") + ".");
            (std::string(key) == "solo" ? options.solo : options.mute).push_back(name);
        }
    }
    styleTarget = style_target_for(projectDir, doc);
    options.targetLufs = styleTarget;
    if (a.contains("seed")) {
        if (!a["seed"].is_number_integer() || a["seed"].get<long long>() < 0) fail("invalid_argument", command + ": `seed` must be a whole number, 0 or more.", "Another seed is another take of every noise in the instruments; the same seed always gives the same sound.");
        options.seed = a["seed"].get<std::uint64_t>();
    }

    return options;
}


Json music_preview_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.preview", a, "", {"path", "out", "fromBar", "bars", "solo", "mute", "seed", "sampleRate", "overwrite", "picture", "pictureOut", "width", "height"});
    const std::string rel = song_path(tooling_detail::arg_string(a, "path", true));
    Loaded loaded = load_song_file(projectDir, rel);
    const SongTimeline tl = expand_or_fail(loaded.doc, rel);

    std::optional<double> styleTarget;
    const SongRenderOptions options = render_options("music.preview", projectDir, a, loaded.doc, tl, styleTarget);

    const std::string outArg = tooling_detail::arg_string(a, "out", false);
    const std::string out = outArg.empty() ? default_preview(rel) : outArg;
    const std::string ext = to_lower(fs::extension(out));
    if (ext != ".wav" && ext != ".ogg") fail("invalid_argument", "`out` '" + out + "' must end in .wav or .ogg.", "Example: \"out\": \"" + default_preview(rel) + "\".");
    auto norm = fs::normalize_checked(out);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/")) fail("invalid_argument", "The preview goes under assets/, and '" + out + "' is not there.", "Use a path such as \"" + default_preview(rel) + "\".");
    const stdfs::path file = project_file(projectDir, *norm);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec) && !preview_is_ours(projectDir, *norm))
        fail("exists", "'" + *norm + "' already exists and was not made by music.preview.", "Pass overwrite: true to replace it, or choose another `out`.");
    require_usable_manifest(projectDir);

    Result<SongRender> render = [&] {
        ProjectRootGuard root(projectDir);
        return render_song(loaded.doc, tl, options);
    }();
    if (!render.ok()) fail("failed", rel + ": " + render.error().message, render.error().hint);
    std::vector<std::uint8_t> bytes;
    if (ext == ".ogg") {
        AudioOutput o;
        o.format = "ogg";
        auto ogg = audio_encode(render->clip, o);
        if (!ogg.ok()) fail("failed", "Cannot encode '" + *norm + "' as Ogg Vorbis: " + ogg.error().message, ogg.error().hint);
        bytes = std::move(*ogg);
    } else {
        bytes = audio_wav_bytes(render->clip);
    }
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(bytes.data()), bytes.size()), &err)) fail("failed", err);

    std::vector<std::string> inputs = {rel};
    for (const std::string& in : render->inputs)
        if (std::find(inputs.begin(), inputs.end(), in) == inputs.end()) inputs.push_back(in);
    Json recipe = make_recipe(projectDir, "music.preview",
                              recipe_args(a, {{"path", rel}, {"out", outArg.empty() ? Json() : Json(*norm)}, {"picture", Json()}, {"pictureOut", Json()}, {"width", Json()}, {"height", Json()}}), inputs);
    if (loaded.doc.mixer.master.loudness == SongMaster::Loudness::Style) add_style_loudness_context(recipe, styleTarget);
    const std::string notes = std::format("song {}, {:.1f} s, {} notes, seed {}", rel, render->seconds, render->notes, options.seed);
    Json provenance = Json::object({{"origin", "original"}, {"ai", false}, {"kind", "music"}, {"provider", "factoria music.preview"}, {"seed", options.seed},
                                    {"license", "CC0-1.0"}, {"author", "factoria"}, {"notes", notes}, {"date", assets::today()}, {"recipe", recipe}});
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(*norm, [&](Json& e) {
            e.erase("analysis");
            // What a person recorded (license, author) stays when the preview is rendered again; the recipe, date and notes are the new render's.
            if (e.contains("provenance") && e["provenance"].is_object() && e["provenance"].value("provider", std::string()) == "factoria music.preview") {
                for (const char* key : {"recipe", "date", "notes", "seed"}) e["provenance"][key] = provenance[key];
            } else {
                e["provenance"] = provenance;
            }
        });
        if (!r.ok()) fail("failed", "The preview was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }

    Json result = Json::object({{"song", rel},
                                {"path", *norm},
                                {"bytes", bytes.size()},
                                {"seconds", num(render->seconds, 2)},
                                {"notes", render->notes},
                                {"seed", options.seed},
                                {"measurements", Json::object({{"lufs", num(render->clip.lufs, 1)}, {"peakDb", num(render->clip.peakDb, 1)}, {"sampleRate", render->clip.sampleRate}, {"channels", render->clip.channels}})},
                                {"mix", mix_json(loaded.doc, *render, styleTarget)},
                                {"provenance", provenance}});
    if (options.fromBar > 1 || options.bars > 0) result["range"] = Json::object({{"fromBar", options.fromBar}, {"bars", options.bars}});
    if (!options.solo.empty()) result["solo"] = options.solo;
    if (!options.mute.empty()) result["mute"] = options.mute;
    Json steps = Json::array();
    if (tooling_detail::arg_bool(a, "picture", true)) {
        Json picArgs = Json::object({{"path", *norm}});
        for (const char* key : {"width", "height"})
            if (a.contains(key)) picArgs[key] = a[key];
        if (a.contains("pictureOut")) picArgs["out"] = a["pictureOut"];
        Json pic = audio_mix::spectrogram_picture(projectDir, picArgs);
        if (pic.contains("$image")) result["$image"] = pic["$image"];
        pic.erase("$image");
        pic.erase("nextSteps");
        pic.erase("path");
        result["analysis"] = pic;
        steps.push_back("Read the picture: waveform on top, spectrogram (log frequency) in the middle, loudness at the bottom. music.info draws the notes instead.");
    }
    if (render->master.limiter && render->master.limiterReductionDb > 3.0)
        steps.push_back(std::format("The master limiter pulled the level down by {:.1f} dB: the mix is too hot, lower the loudest tracks' `volume` with music.edit (music.mix shows each track's level).", render->master.limiterReductionDb));
    else if (!render->master.limiter && render->clip.peakDb > -0.5)
        steps.push_back("It peaks at " + std::format("{:.1f}", render->clip.peakDb) + " dBFS and the master limiter is off: turn it on (music.edit set_mixer) or lower a track `volume` or the song's `volume`.");
    steps.push_back("Same song, same options, same bytes. After editing the song, music.preview again (assets.regenerate does it too while the preview is recorded as made by this command).");
    result["nextSteps"] = steps;
    return result;
}

// ---------------------------------------------------------------- music.mix ---

Json music_mix_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.mix", a, "", {"path", "song", "fromBar", "bars", "solo", "mute", "seed", "sampleRate"});
    Loaded loaded = resolve_song(projectDir, a, "music.mix");
    const SongTimeline tl = expand_or_fail(loaded.doc, loaded.rel);
    std::optional<double> styleTarget;
    const SongRenderOptions options = render_options("music.mix", projectDir, a, loaded.doc, tl, styleTarget);
    Result<SongRender> render = [&] {
        ProjectRootGuard root(projectDir);
        return render_song(loaded.doc, tl, options);
    }();
    if (!render.ok()) fail("failed", (loaded.rel.empty() ? std::string("the song") : loaded.rel) + ": " + render.error().message, render.error().hint);
    Json result = Json::object({{"seconds", num(render->seconds, 2)},
                                {"notes", render->notes},
                                {"measurements", Json::object({{"lufs", num(render->clip.lufs, 1)}, {"peakDb", num(render->clip.peakDb, 1)}})},
                                {"mix", mix_json(loaded.doc, *render, styleTarget)}});
    if (!loaded.rel.empty()) result["path"] = loaded.rel;
    Json steps = Json::array();
    const SongMasterStats& m = render->master;
    std::string loudest, quietest;
    double hi = -1e9, lo = 1e9;
    for (const SongTrackStats& t : render->tracks) {
        if (t.notes == 0) continue;
        if (t.lufs > hi) { hi = t.lufs; loudest = t.name; }
        if (t.lufs < lo) { lo = t.lufs; quietest = t.name; }
    }
    if (!loudest.empty() && loudest != quietest && hi - lo > 12.0)
        steps.push_back(std::format("`{}` is {:.0f} LU louder than `{}`: change a track `volume` with music.edit set_track to balance them.", loudest, hi - lo, quietest));
    if (m.limiter && m.limiterReductionDb > 3.0)
        steps.push_back(std::format("The master limiter pulls the level down by {:.1f} dB: lower the loudest tracks' `volume` instead of letting the limiter squash the mix.", m.limiterReductionDb));
    if (!m.limiter && render->clip.peakDb > -1.0)
        steps.push_back("The master limiter is off and the mix peaks at " + std::format("{:.1f}", render->clip.peakDb) + " dBFS: set mixer.master.limiter to true with music.edit set_mixer.");
    if (m.targetLufs && std::abs(render->clip.lufs - *m.targetLufs) > 3.0)
        steps.push_back(std::format("The mix is {:.1f} LUFS and the target is {:.1f}: the loudness gain was capped or the limiter held it back; lower the peaks of the loudest tracks.", render->clip.lufs, *m.targetLufs));
    steps.push_back("music.edit set_track changes a track's volume, pan, mute, solo, effects and sends; set_mixer changes the buses and the master. music.preview writes the sound.");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

Json music_mix_json(const SongDoc& doc, const SongRender& render, const std::optional<double>& styleTarget) { return mix_json(doc, render, styleTarget); }
std::optional<double> music_style_target(const std::string& projectDir, const SongDoc& doc) { return style_target_for(projectDir, doc); }

void register_music_commands_core(CommandRegistry& registry, const std::string& projectDir) {
    auto songArgs = [] {
        return std::vector<std::pair<const char*, Json>>{{"path", str("The song, project-relative, under assets/ and ending in .song.json, e.g. \"assets/music/theme.song.json\".")}};
    };
    {
        CommandInfo info;
        info.name = "music.info";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Check a song document and say what it holds: structure, bars, seconds, a summary per section, and a piano-roll picture.";
        info.description =
            "Reads a song (`*.song.json`, format factoria.song/1, docs/MUSIC.md and schemas/song.schema.json) from `path`, or takes it inline as `song`, and checks it. A song with mistakes fails with `invalid_song` and EVERY problem in "
            "data.issues (JSON pointer, line and column inside note text, what is wrong and how to fix it), so one call is enough to repair it. A valid song returns tempo, meter, key, mode, swing, the length in bars and seconds, the "
            "structure (\"intro (4 bars) > loop (8 bars) x2 > outro (4 bars)\"), each track (instrument, patterns and their bars, notes played, the range they cover, the sections they play in) and each section (kind, bars, repeats, what every "
            "track plays, where it starts in bars and seconds, notes per bar and per track), and where its preview WAV is and whether it is stale. Unless `picture` is false it also returns a piano roll (`$image`): the sections on top, "
            "one colour per track, brighter = louder, drum lanes below; `fromBar` and `bars` zoom on a part. Example: {\"path\":\"assets/music/theme.song.json\"}";
        auto props = songArgs();
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({props[0],
                                                             {"song", object_arg("The song itself, as JSON, to check before writing it to a file (format is filled in).")},
                                                             {"picture", boolean("Return the piano-roll picture (`$image`).", true)},
                                                             {"pictureOut", str("Also keep the picture's PNG at this project path (ends in .png). Default: a temporary screenshot.")},
                                                             {"width", integer("Width of the picture in pixels (default 1000).", 400, 2400)},
                                                             {"fromBar", integer("First bar shown in the picture (default 1).", 1, kSongMaxBars)},
                                                             {"bars", integer("Number of bars shown (default: to the end).", 1, kSongMaxBars)}})}});
        registry.add(info, [projectDir](const Json& args) { return music_info_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "music.check";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Find what is wrong in a song before listening: notes outside the key or the instrument's range, clashes, mud, silent tracks, loudness.";
        info.description =
            "Runs the music checks on a song (`path` or inline `song`). Rules: off_key (a note outside the song's key and mode that is not a passing tone), range (a note outside the instrument's range or the track's `range`), clash (a minor "
            "second or a tritone sounding together on a strong beat), mud (close low notes under C3), structure (a track that never plays, an empty section, an unused pattern) and loudness (the song is rendered with its mixer: with the master limiter off a clipping mix is an error and a peak over -1 dBFS "
            "a warning; a limiter that pulls the level down by more than 6 dB is a warning, more than 3 dB a note; a mix below -35 LUFS is a warning; an integrated loudness more than 3 LU from the target is a warning, "
            "unless the master `loudness` brings it there). Without `rules` every rule that needs no render runs; `render: true` adds loudness. The target is `targetLufs`, else "
            "style.audio.loudnessLufs.music of assets.json when the style guide says it. Every finding has the rule, severity, a message, a fix (`hint`), the track, pattern, section, bar and position, and for a note the pointer, line, column "
            "and token in the note text; equal findings are reported once with a `count`. `ok` is true when there is no error and no warning. A song with mistakes fails like music.info. Example: {\"path\":\"assets/music/theme.song.json\",\"render\":true}";
        auto props = songArgs();
        std::vector<std::string> rules;
        for (const SongCheckRule& r : song_check_rules()) rules.push_back(r.name);
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({props[0],
                                                             {"song", object_arg("The song itself, as JSON, to check before writing it to a file.")},
                                                             {"rules", Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}, {"enum", rules}})}, {"description", "Which rules to run (default: every rule that needs no render). Naming loudness renders the song."}})},
                                                             {"render", boolean("Also run the loudness rule: render the song and measure it.", false)},
                                                             {"targetLufs", number("Integrated loudness the music should have (LUFS, -70 to 0). Default: style.audio.loudnessLufs.music of assets.json, if set.", -70, 0)}})}});
        registry.add(info, [projectDir](const Json& args) { return music_check_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "music.preview";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Render a song to a stereo WAV or OGG next to it (offline, deterministic) and see its spectrogram.";
        info.description =
            "Renders the song at `path` with the preview voices: every note of the arrangement is played by "
            "its track's instrument at the note's pitch (a built-in instrument, a preset, or your own "
            ".sfx.json patch), with the track's volume, pan, swing and automation lanes and the song's "
            "master lanes. The result is a stereo 16-bit WAV at `out` (default: the song's path with "
            ".preview.wav; a path ending in .ogg encodes Ogg Vorbis). No provider, no key, no other program: "
            "the same song, options and seed give the same bytes on every platform. The file gets provenance "
            "and a recipe in assets.json whose inputs are the song and every patch it read, so "
            "project.validate warns when they changed after the preview was made and assets.regenerate "
            "renders it again. `fromBar` and `bars` render a part, `solo` and `mute` choose tracks, `seed` "
            "is another take of the instruments' noise, `sampleRate` 22050, 32000, 44100 (default) or 48000. "
            "A song longer than 180 s needs a range. An existing file that music.preview did not make is an "
            "`exists` error unless overwrite is true. Example: "
            "{\"path\":\"assets/music/theme.song.json\",\"fromBar\":5,\"bars\":4,\"solo\":[\"lead\"]}"
            FA_COMMAND_DETAILS
            "The result has the measurements (lufs, peakDb), the numbers of the file as written (`analysis`) "
            "and the spectrogram picture (`$image`). The song's mixer applies: track effects and sends, the "
            "buses, the master limiter and the loudness normalization to the style's music loudness; `mix` "
            "in the result says what each did (music.mix gives the same without writing a file).";
        auto props = songArgs();
        info.inputSchema = Json::object({{"type", "object"},
                                         {"required", Json::array({"path"})},
                                         {"additionalProperties", false},
                                         {"properties", obj({props[0],
                                                             {"out", str("Where to write the sound: .wav or .ogg under assets/. Default: the song's path with .preview.wav.")},
                                                             {"fromBar", integer("First bar rendered, counted from 1 (default 1). Notes that start earlier are not played.", 1, kSongMaxBars)},
                                                             {"bars", integer("Number of bars rendered from `fromBar` (default: to the end).", 1, kSongMaxBars)},
                                                             {"solo", strings("Render only these tracks.")},
                                                             {"mute", strings("Leave these tracks out.")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"default", 0}, {"description", "Added to the song's seed: another take of the instruments' noise. The same seed always gives the same file."}})},
                                                             {"sampleRate", Json::object({{"type", "integer"}, {"enum", Json::array({22050, 32000, 44100, 48000})}, {"default", 44100}, {"description", "Sample rate of the file."}})},
                                                             {"overwrite", boolean("Replace the file when it exists and was not made by music.preview (one made by it is always replaced).", false)},
                                                             {"picture", boolean("Return the spectrogram picture (`$image`) of the preview.", true)},
                                                             {"pictureOut", str("Also keep the picture's PNG at this project path (ends in .png).")},
                                                             {"width", integer("Width of the picture in pixels (default 1000).", 400, 2400)},
                                                             {"height", integer("Height of the picture in pixels (default 640).", 280, 1600)}})}});
        registry.add(info, [projectDir](const Json& args) { return music_preview_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "music.mix";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Render a song in memory and report the mix: each track's level, the buses and what the master's loudness normalization and limiter did.";
        info.description =
            "Renders the song (`path`, or inline `song`) like music.preview but writes no file, and returns the mix: for every track its notes, peak (dBFS) and loudness (LUFS) as heard in the mix, volume, pan, effects and sends; the buses "
            "(volume, pan, effects); and the master: the loudness and peak before the loudness gain and the limiter, the gain the normalization added, the target loudness (`mixer.master.loudness`: \"style\" is the project's "
            "style.audio.loudnessLufs.music, a number is LUFS, \"off\" leaves the level), whether the limiter is on and how many dB it pulled down at most. Use it to balance the tracks (a track 10 LU above the others covers them), "
            "to see whether the limiter is squashing a hot mix, and before music.edit set_track / set_mixer. `fromBar`, `bars`, `solo`, `mute`, `seed` and `sampleRate` work as in music.preview. "
            "Example: {\"path\":\"assets/music/theme.song.json\",\"bars\":8}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"path", str("The song, project-relative, under assets/ and ending in .song.json.")},
                                                             {"song", Json::object({{"type", "object"}, {"description", "The song document inline (a song not saved yet); `path` or `song`."}})},
                                                             {"fromBar", integer("First bar rendered, counted from 1 (default 1).", 1, kSongMaxBars)},
                                                             {"bars", integer("Number of bars rendered from `fromBar` (default: to the end).", 1, kSongMaxBars)},
                                                             {"solo", strings("Render only these tracks.")},
                                                             {"mute", strings("Leave these tracks out.")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"default", 0}, {"description", "Added to the song's seed."}})},
                                                             {"sampleRate", Json::object({{"type", "integer"}, {"enum", Json::array({22050, 32000, 44100, 48000})}, {"default", 44100}, {"description", "Sample rate of the render (22050 is faster)."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return music_mix_command(projectDir, args.is_null() ? Json::object() : args); });
    }
}

}  // namespace fa::assets_detail::music

namespace fa::assets_detail {

void register_music_commands(CommandRegistry& registry, const std::string& projectDir) {
    music::register_music_commands_core(registry, projectDir);
    music::register_music_edit_commands(registry, projectDir);
    music::register_music_render_commands(registry, projectDir);
    music::register_music_midi_commands(registry, projectDir);
}

}  // namespace fa::assets_detail
