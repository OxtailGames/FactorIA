// project.validate for song documents (`*.song.json`, docs/MUSIC.md): a song with mistakes is an error (every issue with its JSON
// pointer, line and column inside note text), an instrument or kit patch it names that is missing or invalid is an error, and the
// music checks that need no render (notes out of key or range, clashes, mud, an unused pattern) are warnings. A stale preview is
// reported with the other recipes (check_recipes).
#include <algorithm>
#include <fstream>

#include "assets_internal.h"
#include "fa/audio/sfx.h"
#include "fa/audio/song.h"
#include "fa/audio/song_check.h"
#include "fa/core/strings.h"
#include "music_internal.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

std::string escape_pointer(const std::string& s) {
    std::string out;
    for (char ch : s) {
        if (ch == '~') out += "~0";
        else if (ch == '/') out += "~1";
        else out += ch;
    }
    return out;
}

// A patch file a track or a kit lane names: it must exist and be a valid sound patch.
void check_instrument_file(const std::string& projectDir, const std::string& rel, const std::string& pointer, const std::string& instrument, std::vector<ValidationIssue>& errors) {
    if (!ends_with(to_lower(instrument), ".sfx.json")) return;
    auto text = tooling_detail::read_file(project_file(projectDir, instrument));
    if (!text) {
        errors.push_back({rel, pointer, "The instrument '" + instrument + "' does not exist.", "Write the patch with sfx.preset or music.instrument {\"name\":\"pluck\",\"path\":\"" + instrument + "\"}, or name a built-in instrument."});
        return;
    }
    auto json = parse_json(*text, instrument);
    if (!json.ok()) {
        errors.push_back({rel, pointer, "The instrument '" + instrument + "' is not valid JSON: " + json.error().message, "Fix the file; schemas/sfx.schema.json describes the format."});
        return;
    }
    std::vector<SfxIssue> issues;
    if (!parse_sfx(*json, instrument, &issues).ok()) {
        const std::string first = issues.empty() ? std::string("it is not a valid sound patch") : issues.front().pointer + ": " + issues.front().message;
        errors.push_back({rel, pointer, "The instrument '" + instrument + "' is not a valid sound patch (" + first + ").", "sfx.info {\"path\":\"" + instrument + "\"} lists every problem."});
    }
}

// The SoundFont a track plays: the file must be there and be a RIFF "sfbk" file. The presets are not read here (a large font is slow to
// load); music.preview and music.check name a missing preset and the close ones.
void check_soundfont_file(const std::string& projectDir, const std::string& rel, const std::string& pointer, const std::string& path, std::vector<ValidationIssue>& errors) {
    std::ifstream in(project_file(projectDir, path), std::ios::binary);
    if (!in) {
        errors.push_back({rel, pointer, "The SoundFont '" + path + "' does not exist.", "Put the .sf2 file at " + path + " (an asset the project brings; the engine includes none), or name a built-in instrument."});
        return;
    }
    char head[12] = {};
    in.read(head, sizeof head);
    if (in.gcount() < 12 || std::string(head, 4) != "RIFF" || std::string(head + 8, 4) != "sfbk")
        errors.push_back({rel, pointer, "The SoundFont '" + path + "' is not a SoundFont 2 file.", "A .sf2 file starts with RIFF....sfbk; export it again from the SoundFont editor, or use another file."});
}

}  // namespace

void check_song_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings) {
    for (const std::string& rel : music::list_songs(projectDir)) {
        auto text = tooling_detail::read_file(project_file(projectDir, rel));
        if (!text) {
            errors.push_back({rel, "", "The song cannot be read.", "Check the file's permissions."});
            continue;
        }
        auto json = parse_json(*text, rel);
        if (!json.ok()) {
            errors.push_back({rel, "", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/song.schema.json describes the format." : json.error().hint});
            continue;
        }
        std::vector<SongIssue> issues;
        auto doc = parse_song(*json, rel, &issues);
        if (!doc.ok()) {
            if (issues.empty()) issues.push_back({"", doc.error().message, doc.error().hint, 0, 0});
            for (const SongIssue& i : issues) {
                const std::string where = i.line > 0 ? "(line " + std::to_string(i.line) + ", column " + std::to_string(i.column) + ") " : std::string();
                errors.push_back({rel, i.pointer, where + i.message, i.hint.empty() ? "Fix the song (docs/MUSIC.md, schemas/song.schema.json)." : i.hint});
            }
            continue;
        }
        for (const SongTrack& t : doc->tracks) {
            const std::string base = "/tracks/" + escape_pointer(t.name);
            if (t.soundfont.present()) check_soundfont_file(projectDir, rel, base + "/instrument", t.soundfont.path, errors);
            else check_instrument_file(projectDir, rel, base + "/instrument", t.instrument, errors);
            for (const auto& [lane, instrument] : t.kit) check_instrument_file(projectDir, rel, base + "/kit/" + escape_pointer(lane), instrument, errors);
        }
        auto timeline = expand_song(*doc);
        if (!timeline.ok()) {
            errors.push_back({rel, "", timeline.error().message, timeline.error().hint});
            continue;
        }
        auto report = check_song(*doc, *timeline, {});
        if (!report.ok()) continue;
        int shown = 0;
        for (const SongCheckIssue& i : report->issues) {
            if (i.severity == "info") continue;
            if (++shown > 20) {
                warnings.push_back({rel, "", "More findings: music.check {\"path\":\"" + rel + "\"} lists all of them.", "Fix the ones above first."});
                break;
            }
            std::string message = "[" + i.rule + "] " + i.message;
            if (!i.position.empty()) message += " (" + (i.track.empty() ? std::string() : i.track + ", ") + i.position + ")";
            if (i.count > 1) message += " x" + std::to_string(i.count);
            ValidationIssue v{rel, i.source.pointer, message, i.hint};
            (i.severity == "error" ? errors : warnings).push_back(v);
        }
    }
}

}  // namespace fa::assets_detail
