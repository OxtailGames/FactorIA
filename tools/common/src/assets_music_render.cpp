// music.render: a song rendered whole (intro, loop, outro) to a game asset, with sample-exact loop points and, optionally, one stem per layer
// (docs/MUSIC.md, "Rendering a song for a game"). It follows the other bakes: the file, provenance and recipe in assets.json, and
// assets.regenerate makes it again.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/audio/audio_doc.h"
#include "fa/audio/song.h"
#include "fa/audio/song_preview.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "music_internal.h"
#include "util.h"

namespace fa::assets_detail::music {

namespace {

constexpr const char* kRender = "music.render";

Json manifest_entry(const std::string& projectDir, const std::string& rel) {
    const std::string text =
        tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
    if (text.empty()) return Json();
    auto parsed = parse_json(text, assets::kManifestFile);
    if (!parsed.ok() || !parsed->is_object() || !parsed->contains("assets") || !(*parsed)["assets"].is_object())
        return Json();
    auto it = (*parsed)["assets"].find(rel);
    return it == (*parsed)["assets"].end() ? Json() : *it;
}

bool made_by_render(const std::string& projectDir, const std::string& rel) {
    const Json recipe = recipe_of(manifest_entry(projectDir, rel));
    return recipe.is_object() && recipe.value("command", std::string()) == kRender;
}

double seconds_of(std::size_t frame, int rate) { return std::round(double(frame) / double(rate) * 1e6) / 1e6; }

// theme.wav + "drums" -> theme.stem.drums.wav
std::string stem_path(const std::string& out, const std::string& name) {
    std::string safe = safe_file_name(name, "stem");
    const std::size_t dot = out.find_last_of('.');
    return out.substr(0, dot) + ".stem." + safe + out.substr(dot);
}

std::vector<std::uint8_t> encode_clip(const AudioClip& clip, const std::string& ext, const std::string& what) {
    if (ext == ".ogg") {
        AudioOutput o;
        o.format = "ogg";
        auto ogg = audio_encode(clip, o);
        if (!ogg.ok())
            fail("failed", "Cannot encode '" + what + "' as Ogg Vorbis: " + ogg.error().message, ogg.error().hint);
        return std::move(*ogg);
    }
    return audio_wav_bytes(clip);
}

Json music_render_command(const std::string& projectDir, const Json& a) {
    check_arg_keys(kRender, a, "", {"path", "out", "format", "sampleRate", "seed", "loop", "stems", "overwrite"});
    const std::string rel = song_path(tooling_detail::arg_string(a, "path", true));
    Loaded loaded = load_song_file(projectDir, rel);
    const SongTimeline tl = expand_or_fail(loaded.doc, rel);

    SongAssetOptions options;
    if (a.contains("sampleRate")) {
        const long sr = tooling_detail::arg_int(a, "sampleRate", 44100);
        if (sr != 22050 && sr != 32000 && sr != 44100 && sr != 48000)
            fail("invalid_argument", "music.render: `sampleRate` must be 22050, 32000, 44100 or 48000.",
                 "44100 is the default and the rate the engine mixes at: loop points are exact frames there.");
        options.render.sampleRate = int(sr);
    }
    if (a.contains("seed")) {
        if (!a["seed"].is_number_integer() || a["seed"].get<long long>() < 0)
            fail("invalid_argument", "music.render: `seed` must be a whole number, 0 or more.",
                 "Another seed is another take of the instruments' noise; the same seed always gives the same file.");
        options.render.seed = a["seed"].get<std::uint64_t>();
    }
    if (a.contains("loop") && !a["loop"].is_boolean())
        fail("invalid_argument", "music.render: `loop` must be true or false.",
             "true (default) finds the song's loop sections and wraps their tail; false renders the song once, with no "
             "loop points.");
    options.loop = tooling_detail::arg_bool(a, "loop", true);
    const std::optional<double> styleTarget = music_style_target(projectDir, loaded.doc);
    options.render.targetLufs = styleTarget;

    // Which file, and in what format.
    const std::string outArg = tooling_detail::arg_string(a, "out", false);
    const std::string formatArg = to_lower(tooling_detail::arg_string(a, "format", false));
    if (!formatArg.empty() && formatArg != "wav" && formatArg != "ogg")
        fail("invalid_argument", "music.render: `format` must be \"wav\" or \"ogg\".",
             "wav is lossless and carries the loop points in its smpl chunk; ogg is about 10x smaller and keeps the "
             "loop points in assets.json only.");
    const std::string defaultOut = song_stem(rel) + "." + (formatArg.empty() ? "wav" : formatArg);
    const std::string out = outArg.empty() ? defaultOut : outArg;
    const std::string ext = to_lower(fs::extension(out));
    if (ext != ".wav" && ext != ".ogg")
        fail("invalid_argument", "`out` '" + out + "' must end in .wav or .ogg.",
             "Example: \"out\": \"" + defaultOut + "\".");
    if (!formatArg.empty() && "." + formatArg != ext)
        fail("invalid_argument", "`format` \"" + formatArg + "\" and `out` '" + out + "' disagree.",
             "Leave `format` out (the extension of `out` decides) or change the extension.");
    auto norm = fs::normalize_checked(out);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The sound goes under assets/, and '" + out + "' is not there.",
             "Use a path such as \"" + defaultOut + "\".");
    if (ends_with(*norm, kSuffix))
        fail("invalid_argument", "`out` '" + *norm + "' would replace the song itself.",
             "Use a path such as \"" + defaultOut + "\".");

    // Stems.
    std::string grouping;
    if (a.contains("stems")) {
        if (a["stems"].is_boolean()) {
            if (a["stems"].get<bool>()) grouping = "layers";
        } else if (a["stems"].is_string()) {
            grouping = a["stems"].get<std::string>();
            if (grouping != "layers" && grouping != "tracks" && grouping != "buses")
                fail("invalid_argument", "music.render: `stems` \"" + grouping + "\" is not a grouping.",
                     "Use \"layers\" (the song's `layers`), \"tracks\" (one per track), \"buses\" (the dry tracks and "
                     "each bus's return), or false.");
        } else {
            fail("invalid_argument", "music.render: `stems` must be \"layers\", \"tracks\", \"buses\" or false.",
                 "Example: {\"stems\": \"layers\"}.");
        }
    }
    if (!grouping.empty()) {
        auto plan = song_stem_plan(loaded.doc, grouping);
        if (!plan.ok()) fail("invalid_argument", "music.render: " + plan.error().message, plan.error().hint);
        options.stems = std::move(*plan);
    }
    std::vector<std::string> stemFiles;
    if (options.stems) {
        std::set<std::string> seen;
        for (const std::string& name : options.stems->names) {
            const std::string p = stem_path(*norm, name);
            if (!seen.insert(p).second)
                fail("invalid_argument", "Two stems would be written to '" + p + "'.",
                     "Rename the layers or tracks so their names differ in letters and digits.");
            stemFiles.push_back(p);
        }
    }

    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::vector<std::string> targets = {*norm};
    targets.insert(targets.end(), stemFiles.begin(), stemFiles.end());
    for (const std::string& t : targets) {
        std::error_code ec;
        if (!overwrite && stdfs::exists(project_write_file(projectDir, t), ec) && !made_by_render(projectDir, t))
            fail("exists", "'" + t + "' already exists and was not made by music.render.",
                 "Pass overwrite: true to replace it, or choose another `out`.");
    }
    require_usable_manifest(projectDir);

    Result<SongAssetRender> render = [&] {
        ProjectRootGuard root(projectDir);
        return render_song_asset(loaded.doc, tl, options);
    }();
    if (!render.ok()) fail("failed", rel + ": " + render.error().message, render.error().hint);
    const SongRender& mix = render->mix;
    const int rate = mix.clip.sampleRate;

    // Write the files.
    std::vector<std::vector<std::uint8_t>> blobs;
    blobs.push_back(encode_clip(mix.clip, ext, *norm));
    for (std::size_t i = 0; i < render->stems.size(); ++i)
        blobs.push_back(encode_clip(render->stems[i].clip, ext, stemFiles[i]));
    for (std::size_t i = 0; i < targets.size(); ++i) {
        std::string err;
        if (!tooling_detail::write_file(
                project_write_file(projectDir, targets[i]),
                std::string_view(reinterpret_cast<const char*>(blobs[i].data()), blobs[i].size()), &err))
            fail("failed", err);
    }

    // The recipe: the same one for the mix and every stem (assets.regenerate makes the group once).
    std::vector<std::string> inputs = {rel};
    for (const std::string& in : mix.inputs)
        if (std::find(inputs.begin(), inputs.end(), in) == inputs.end()) inputs.push_back(in);
    Json recipe = make_recipe(
        projectDir, kRender,
        recipe_args(
            a,
            {{"path", rel}, {"out", *norm}, {"format", Json()}, {"stems", grouping.empty() ? Json() : Json(grouping)}}),
        inputs);
    if (loaded.doc.mixer.master.loudness == SongMaster::Loudness::Style)
        add_style_loudness_context(recipe, styleTarget);

    Json stemList = Json::array();
    for (std::size_t i = 0; i < render->stems.size(); ++i) {
        const SongStem& s = render->stems[i];
        stemList.push_back(Json::object({{"name", s.name},
                                         {"path", stemFiles[i]},
                                         {"kind", s.kind},
                                         {"intensity", round_to(s.intensity, 4)},
                                         {"tracks", s.tracks},
                                         {"buses", s.buses}}));
    }
    const Json previous = manifest_entry(projectDir, *norm);
    std::vector<std::string> oldStems;
    if (previous.is_object() && previous.contains("import") && previous["import"].is_object() &&
        previous["import"].contains("music") && previous["import"]["music"].is_object() &&
        previous["import"]["music"].contains("stems") && previous["import"]["music"]["stems"].is_array())
        for (const Json& s : previous["import"]["music"]["stems"])
            if (s.is_object() && s.contains("path") && s["path"].is_string())
                oldStems.push_back(s["path"].get<std::string>());

    auto write_entry = [&](const std::string& path, const std::string& notes, const Json& music,
                           const AudioClip& clip) {
        Json provenance = Json::object({{"origin", "original"},
                                        {"ai", false},
                                        {"kind", "music"},
                                        {"provider", "factoria music.render"},
                                        {"seed", options.render.seed},
                                        {"license", "CC0-1.0"},
                                        {"author", "factoria"},
                                        {"notes", notes},
                                        {"source", rel},
                                        {"date", assets::today()},
                                        {"recipe", recipe}});
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(path, [&](Json& e) {
            e.erase("analysis");
            // What a person recorded (license, author) stays when the render is made again; the recipe, date and notes are the new render's.
            if (e.contains("provenance") && e["provenance"].is_object() &&
                e["provenance"].value("provider", std::string()) == "factoria music.render") {
                for (const char* key : {"recipe", "date", "notes", "seed", "source"})
                    e["provenance"][key] = provenance[key];
            } else {
                e["provenance"] = provenance;
            }
            if (!e.contains("import") || !e["import"].is_object()) e["import"] = Json::object();
            if (clip.loop) {
                // Seconds, rounded to a microsecond: the engine turns them back into the same frame at 44100 Hz.
                e["import"]["loopStart"] = seconds_of(clip.loop->start, clip.sampleRate);
                e["import"]["loopEnd"] = seconds_of(clip.loop->end, clip.sampleRate);
            } else {
                e["import"].erase("loopStart");
                e["import"].erase("loopEnd");
            }
            e["import"]["music"] = music;
        });
        if (!r.ok())
            fail("failed", "'" + path + "' was written, but assets.json was not updated: " + r.error().message,
                 r.error().hint);
        return provenance;
    };

    const std::string base =
        std::format("song {}, {:.1f} s, {} notes, seed {}", rel, mix.seconds, mix.notes, options.render.seed);
    Json mixMusic = Json::object({{"role", "mix"}, {"song", rel}});
    if (!stemList.empty()) {
        mixMusic["stemGrouping"] = grouping;
        mixMusic["stems"] = stemList;
        // The author's streaming choice (docs/MUSIC.md, "Live and stems") survives a new render.
        if (previous.is_object() && previous.contains("import") && previous["import"].is_object() &&
            previous["import"].contains("music") && previous["import"]["music"].is_object() &&
            previous["import"]["music"].contains("stream") && previous["import"]["music"]["stream"].is_string())
            mixMusic["stream"] = previous["import"]["music"]["stream"];
    }
    Json provenance = write_entry(*norm,
                                  base + (render->loop ? std::format(", loop bars {}-{}", render->loop->startBar,
                                                                     render->loop->startBar + render->loop->bars - 1)
                                                       : std::string(", no loop")),
                                  mixMusic, mix.clip);
    for (std::size_t i = 0; i < render->stems.size(); ++i) {
        const SongStem& s = render->stems[i];
        Json music = Json::object({{"role", "stem"},
                                   {"song", rel},
                                   {"mix", *norm},
                                   {"name", s.name},
                                   {"kind", s.kind},
                                   {"intensity", round_to(s.intensity, 4)},
                                   {"tracks", s.tracks},
                                   {"buses", s.buses}});
        write_entry(stemFiles[i], "stem '" + s.name + "' of " + base, music, s.clip);
    }
    // Stems an earlier render wrote that this one does not (the layers changed): they would be stale files nobody updates.
    Json removed = Json::array();
    for (const std::string& old : oldStems) {
        if (std::find(stemFiles.begin(), stemFiles.end(), old) != stemFiles.end() || !made_by_render(projectDir, old))
            continue;
        std::error_code ec;
        stdfs::remove(project_write_file(projectDir, old), ec);
        ProjectRootGuard root(projectDir);
        (void)assets::update_entry(old, [](Json& e) { e = Json::object(); });
        removed.push_back(old);
    }

    Json result = Json::object({{"song", rel},
                                {"path", *norm},
                                {"format", ext.substr(1)},
                                {"bytes", blobs[0].size()},
                                {"seconds", num(mix.seconds, 3)},
                                {"frames", mix.clip.frames()},
                                {"sampleRate", rate},
                                {"notes", mix.notes},
                                {"seed", options.render.seed},
                                {"measurements", Json::object({{"lufs", num(mix.clip.lufs, 1)},
                                                               {"peakDb", num(mix.clip.peakDb, 1)},
                                                               {"channels", mix.clip.channels}})},
                                {"mix", music_mix_json(loaded.doc, mix, styleTarget)},
                                {"provenance", provenance}});
    if (render->loop) {
        const SongLoopRegion& l = *render->loop;
        result["loop"] = Json::object(
            {{"startBar", l.startBar},
             {"bars", l.bars},
             {"sections", l.sections},
             {"startFrame", l.startFrame},
             {"endFrame", l.endFrame},
             {"loopStart", seconds_of(l.startFrame, rate)},
             {"loopEnd", seconds_of(l.endFrame, rate)},
             {"where", ext == ".wav" ? "assets.json import.loopStart / loopEnd (seconds) and the WAV smpl chunk"
                                     : "assets.json import.loopStart / loopEnd (seconds); Ogg has no loop chunk"},
             {"seamless", "the tail of the last loop bar (reverb, releases) is folded onto the loop start, so playing "
                          "loopStart..loopEnd over and over has no click"}});
    } else if (options.loop) {
        result["loop"] = nullptr;
        result["loopNote"] = "The song has no `loop` section, so there are no loop points; the file plays once.";
    }
    if (!stemList.empty()) {
        result["stems"] = stemList;
        result["stemSum"] = Json::object(
            {{"errorDb", num(render->stemSumErrorDb, 1)},
             {"exact", render->stemsExact},
             {"toleranceDb", -80},
             {"note", render->stemsExact
                          ? "The stems add up to the mix to within float rounding (error below -80 dBFS): they carry "
                            "the mix's loudness gain and limiter gain, and the buses and master are linear."
                          : "A compressor, distortion or bitcrush on a bus or the master acts on the sum of the "
                            "sounds, not on each stem, so the stems add up to the mix only approximately (errorDb)."}});
    }
    if (!removed.empty()) result["removedStems"] = removed;
    Json steps = Json::array();
    if (render->loop)
        steps.push_back(
            "Loop it: audio.play(\"" + *norm +
            "\", {loop: true}) or an AudioSource with loop true; the loop points are applied by the engine.");
    else
        steps.push_back("Play it: audio.play(\"" + *norm + "\") or SceneSettings \"music\".");
    if (!stemList.empty())
        steps.push_back(
            "Each stem is a file of the same length and loop points, named <out>.stem.<name>.<ext>; their gains sum to "
            "the mix. The `import.music` block of every entry in assets.json lists them (docs/MUSIC.md, \"Stems\").");
    if (!render->mix.master.limiter && mix.clip.peakDb > -0.5)
        steps.push_back("It peaks at " + std::format("{:.1f}", mix.clip.peakDb) +
                        " dBFS and the master limiter is off: turn it on (music.edit set_mixer).");
    steps.push_back(
        "After editing the song, its instruments or the style guide's music loudness, run assets.regenerate "
        "{\"stale\":true} (project.validate warns while it is stale), or music.render again.");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_music_render_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kRender;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Render a whole song (intro, loop, outro) to a game-ready WAV or OGG with sample-exact loop points, "
                   "and optionally one stem per layer.";
    info.description =
        "Renders the song at `path` as music.preview does (same voices, mixer, loudness normalization and "
        "limiter) but as an ASSET: the whole song, with the loop points of its `loop` sections. The loop is "
        "seamless: the tail of the loop's last bar (reverb, release) is folded onto its first bar, so a "
        "looping AudioSource plays `loopStart`..`loopEnd` with no click. The points are the bar boundaries "
        "of the loop sections, exact frames, written as `import.loopStart` / `loopEnd` (seconds) in "
        "assets.json, which the engine honours, and, for a WAV, in the standard `smpl` chunk; an OGG keeps "
        "them in assets.json only. `out` (default: the song's path with .wav) or `format` \"wav\" / \"ogg\" "
        "choose the file. `stems`: \"layers\" renders one file per layer of the song's `layers` (the tracks "
        "left out form the layer `other`), \"tracks\" one per track, \"buses\" the dry tracks and each bus's "
        "return; true means \"layers\". Example: "
        "{\"path\":\"assets/music/theme.song.json\",\"stems\":\"layers\"}" FA_COMMAND_DETAILS
        "A stem is named <out without extension>.stem.<name>.<ext>, has the same length, sample rate and "
        "loop points as the mix, and passes through the same buses and master: the stems carry the mix's "
        "loudness gain and limiter gain, so their SUM is the mix to within float rounding (below -80 dBFS) "
        "when the buses and the master hold only linear effects; a compressor, distortion or bitcrush there "
        "acts on the sum and the result's stemSum says by how much the sum differs. Add them with gain 1 and "
        "clip nothing: a stem can pass 0 dBFS when the others cancel it. Every written file gets provenance "
        "and the same recipe in assets.json (inputs: the song, every .sfx.json patch and SoundFont it reads; "
        "context: the style guide's music loudness when the song's master loudness is \"style\"), so "
        "project.validate warns when any of them changed and assets.regenerate makes the files again; "
        "running music.render again updates them in place (a stem of a layer you removed is deleted). "
        "`import.music` of each entry says what it is: {role: \"mix\", song, stemGrouping, stems: [{name, "
        "path, kind, intensity, tracks, buses}]} or {role: \"stem\", song, mix, name, kind, intensity, "
        "tracks, buses}; intensity (0..1) is when a layered player brings the stem in. `sampleRate` 22050, "
        "32000, 44100 (default, exact loop frames in the engine) or 48000; `seed` another take of the "
        "instruments' noise; `loop` false renders the song once with no loop points. An existing file that "
        "music.render did not make is an `exists` error unless overwrite is true.";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path"})},
         {"additionalProperties", false},
         {"properties",
          obj({{"path", str("The song, project-relative, under assets/ and ending in .song.json.")},
               {"out", str("Where to write the mix: .wav or .ogg under assets/. Default: the song's path with .wav (or "
                           ".ogg when `format` says so).")},
               {"format", Json::object({{"type", "string"},
                                        {"enum", Json::array({"wav", "ogg"})},
                                        {"description", "File format when `out` is not given. wav is lossless and "
                                                        "holds the loop points in a smpl chunk; ogg is smaller."}})},
               {"sampleRate", Json::object({{"type", "integer"},
                                            {"enum", Json::array({22050, 32000, 44100, 48000})},
                                            {"default", 44100},
                                            {"description", "Sample rate of the files."}})},
               {"seed",
                Json::object({{"type", "integer"},
                              {"minimum", 0},
                              {"default", 0},
                              {"description", "Added to the song's seed: another take of the instruments' noise."}})},
               {"loop", boolean("Find the song's loop sections, fold their tail onto the start and write the loop "
                                "points. False: render once, no points.",
                                true)},
               {"stems",
                Json::object(
                    {{"description", "One file per stem: \"layers\" (the song's `layers`), \"tracks\" or \"buses\"; "
                                     "true = \"layers\"; false or absent: only the mix."},
                     {"oneOf", Json::array({Json::object({{"type", "boolean"}}),
                                            Json::object({{"type", "string"},
                                                          {"enum", Json::array({"layers", "tracks", "buses"})}})})}})},
               {"overwrite", boolean("Replace files that exist and were not made by music.render (the ones it made are "
                                     "always replaced).",
                                     false)}})}});
    mark_paths(info.inputSchema, "read", {"path"});
    mark_paths(info.inputSchema, "write", {"out"});
    registry.add(info, [projectDir](const Json& args) {
        return music_render_command(projectDir, args.is_null() ? Json::object() : args);
    });
    using namespace capability_sets;  // capability.h: writes the sound(s) and their records in the project
    declare_command_capabilities(registry, {{"music.render", writes_project()}});
}

}  // namespace fa::assets_detail::music
