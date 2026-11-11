// sfx.render, sfx.bake, sfx.tweak, sfx.edit, sfx.family, sfx.preset and sfx.info: sound patches (`*.sfx.json`, docs/SOUND.md) as project files. The synthesizer is
// fa_audio's (fa/audio/sfx.h); this file reads patches from the project, bakes them into WAV or OGG files next to them with a
// recipe in assets.json (so a changed patch makes its sound stale and assets.regenerate renders it again), and shows the result
// as the picture of assets.spectrogram. assets.synth_sound (assets_synth.cpp) renders the presets through the same functions.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "audio_mix.h"
#include "fa/audio/convert.h"
#include "fa/audio/sfx.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kRender = "sfx.render";
constexpr const char* kSuffix = ".sfx.json";

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

std::string default_out(const std::string& patchRel) { return patchRel.substr(0, patchRel.size() - std::string(kSuffix).size()) + ".wav"; }

// The normalized project path of a patch argument, or an error that says what a patch path is.
std::string patch_path(const std::string& arg, const char* what = "path") {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("`") + what + "` '" + arg + "' is not a sound patch under assets/.", "Sound patches live in assets/, e.g. \"assets/audio/jump.sfx.json\" (sfx.preset writes a starting point).");
    if (!ends_with(to_lower(*norm), kSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .sfx.json.", "Name sound patches <name>.sfx.json, e.g. \"assets/audio/jump.sfx.json\".");
    return *norm;
}

// Every patch of the project, sorted.
std::vector<std::string> list_patches(const std::string& projectDir) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path root = stdfs::path(projectDir) / "assets";
    if (!stdfs::is_directory(root, ec)) return out;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec)) continue;
        const std::string rel = stdfs::relative(it->path(), projectDir, ec).generic_string();
        if (ends_with(to_lower(rel), kSuffix)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

Json issues_json(const std::vector<SfxIssue>& issues) {
    Json list = Json::array();
    for (const SfxIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

struct LoadedPatch {
    std::string rel;
    std::string text;  // the file as written
    Json json;
    SfxPatch patch;
};

// Reads and checks a patch. A patch with mistakes throws one error that carries all of them in `data.issues`.
LoadedPatch load_patch(const std::string& projectDir, const std::string& rel) {
    LoadedPatch out;
    out.rel = rel;
    const stdfs::path file = project_file(projectDir, rel);
    auto text = tooling_detail::read_file(file);
    if (!text) {
        const std::vector<std::string> all = list_patches(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with sfx.preset {\"name\":\"coin\",\"path\":\"" + rel + "\"} and edit it." : did_you_mean(rel, all) + " Patches: " + join(all, ", ") + ".");
    }
    out.text = std::move(*text);
    auto json = parse_json(out.text, rel);
    if (!json.ok()) fail("invalid_patch", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/sfx.schema.json describes the format." : json.error().hint);
    out.json = std::move(*json);
    std::vector<SfxIssue> issues;
    auto patch = parse_sfx(out.json, rel, &issues);
    if (!patch.ok()) throw CommandError("invalid_patch", patch.error().message, patch.error().hint, Json::object({{"issues", issues_json(issues)}}));
    out.patch = std::move(*patch);
    return out;
}

// ---- the arguments that change a render ----

struct RenderArgs {
    SfxRenderOptions options;
    std::uint64_t seed = 0;
    int variant = 0;  // 1-based, 0 = the patch itself
};

RenderArgs render_args(const char* command, const Json& a) {
    RenderArgs r;
    if (a.contains("seed")) {
        if (!a["seed"].is_number_integer() || a["seed"].get<long long>() < 0)
            fail("invalid_argument", std::string(command) + ": `seed` must be a whole number, 0 or more.", "Another seed is another take of every noise in the patch; the same seed always gives the same sound.");
        r.seed = a["seed"].get<std::uint64_t>();
    }
    r.options.seed = r.seed;
    if (a.contains("freq") && a.contains("note")) fail("invalid_argument", std::string(command) + ": give `freq` or `note`, not both.", "\"freq\": 440 and \"note\": \"A4\" are the same pitch.");
    if (a.contains("freq")) {
        if (!a["freq"].is_number() || a["freq"].get<double>() < 20.0 || a["freq"].get<double>() > 20000.0)
            fail("invalid_argument", std::string(command) + ": `freq` must be a number from 20 to 20000 (Hz).", "It transposes the patch so its base pitch becomes this frequency. Or use `note`: \"C4\".");
        r.options.freqHz = a["freq"].get<double>();
    }
    if (a.contains("note")) {
        std::optional<double> hz = a["note"].is_string() ? sfx_note_hz(a["note"].get<std::string>()) : std::nullopt;
        if (!hz) fail("invalid_argument", std::string(command) + ": `note` must be a name like \"A4\", \"C#3\" or \"Bb2\".", "Letter A to G, optional # or b, octave number; C4 is middle C and A4 is 440 Hz.");
        r.options.freqHz = *hz;
    }
    for (const char* key : {"length", "tail"}) {
        if (!a.contains(key)) continue;
        const double v = a[key].is_number() ? a[key].get<double>() : -1.0;
        if (v < (std::string(key) == "length" ? 0.001 : 0.0) || v > kSfxMaxSeconds)
            fail("invalid_argument", std::string(command) + ": `" + key + "` must be a number of seconds from " + (std::string(key) == "length" ? "0.001" : "0") + " to 30.", std::string("It replaces the patch's own ") + key + " for this render.");
        (std::string(key) == "length" ? r.options.length : r.options.tail) = v;
    }
    if (a.contains("macros")) {
        if (!a["macros"].is_object()) fail("invalid_argument", std::string(command) + ": `macros` must be an object such as {\"brightness\": 0.3}.", "Macro name to a value from -1 to 1; these replace the values the patch declares for this render.");
        for (auto it = a["macros"].begin(); it != a["macros"].end(); ++it) {
            if (!it.value().is_number() || it.value().get<double>() < -1.0 || it.value().get<double>() > 1.0)
                fail("invalid_argument", std::string(command) + ": macro `" + it.key() + "` must be a number from -1 to 1.", "0 leaves the patch as written; -1 and +1 are the ends of the knob.");
            r.options.macros[it.key()] = it.value().get<double>();
        }
    }
    if (a.contains("variant")) {
        if (!a["variant"].is_number_integer() || a["variant"].get<long long>() < 1 || a["variant"].get<long long>() > 64)
            fail("invalid_argument", std::string(command) + ": `variant` must be a whole number from 1 to 64.", "Variants are numbered from 1: variant 3 of a patch with variations is name_03.wav.");
        r.variant = a["variant"].get<int>();
        r.options.variant = r.variant - 1;
    }
    return r;
}

// The patch as this render sees it: the macro binds applied for the declared values replaced by the arguments'. Checks that the
// macro names and the variant exist.
SfxPatch effective_patch(const LoadedPatch& loaded, const RenderArgs& args, const char* command) {
    std::vector<std::string> known;
    for (const SfxMacroInfo& m : sfx_macros()) known.push_back(m.name);
    for (const SfxMacroDef& d : loaded.patch.macroDefs)
        if (std::find(known.begin(), known.end(), d.name) == known.end()) known.push_back(d.name);
    for (const auto& [name, value] : args.options.macros)
        if (std::find(known.begin(), known.end(), name) == known.end())
            fail("invalid_argument", std::string(command) + ": unknown macro '" + name + "'.", did_you_mean(name, known) + " Macros: " + join(known, ", ") + ".");
    if (args.variant > 0) {
        if (loaded.patch.variations.count <= 0)
            fail("invalid_argument", std::string(command) + ": " + loaded.rel + " declares no variations.", "Add \"variations\": {\"count\": 6} to the patch (docs/SOUND.md, \"Variations\").");
        if (args.variant > loaded.patch.variations.count)
            fail("invalid_argument", std::string(command) + ": variant " + std::to_string(args.variant) + " does not exist: " + loaded.rel + " has " + std::to_string(loaded.patch.variations.count) + ".", "Variants are numbered 1 to " + std::to_string(loaded.patch.variations.count) + ".");
    }
    bool binds = false;
    for (const SfxMacroDef& d : loaded.patch.macroDefs) binds = binds || !d.binds.empty();
    if (!binds) return loaded.patch;
    auto bound = sfx_apply_macro_binds(loaded.json, loaded.patch, args.options.macros);
    if (!bound.ok()) fail("invalid_patch", loaded.rel + ": " + bound.error().message, bound.error().hint);
    std::vector<SfxIssue> issues;
    auto patch = parse_sfx(*bound, loaded.rel, &issues);
    if (!patch.ok()) throw CommandError("invalid_patch", patch.error().message, "A macro bind moves a number outside its range: " + patch.error().hint, Json::object({{"issues", issues_json(issues)}}));
    return std::move(*patch);
}

// Where a render goes by default: the patch's path with .wav, or name_NN.wav for variant NN.
std::string out_for(const LoadedPatch& loaded, const RenderArgs& args) {
    const std::string base = default_out(loaded.rel);
    return args.variant > 0 ? sfx_variant_path(base, args.variant, loaded.patch.variations.count) : base;
}

// ---- baking ----

bool is_ours(const std::string& projectDir, const std::string& outRel) {
    const std::string manifest = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
    if (manifest.empty()) return false;
    auto parsed = parse_json(manifest, assets::kManifestFile);
    if (!parsed.ok() || !parsed->is_object() || !parsed->contains("assets") || !(*parsed)["assets"].is_object()) return false;
    auto it = (*parsed)["assets"].find(outRel);
    if (it == (*parsed)["assets"].end()) return false;
    const Json recipe = recipe_of(*it);
    return recipe.is_object() && recipe.value("command", std::string()) == kRender;
}

struct Baked {
    std::string out;
    std::size_t bytes = 0;
    SfxAudio audio;
    Json provenance;
};

// Renders `loaded` and writes `outRel` (.wav, or .ogg through the engine's Vorbis encoder) with provenance and the recipe in
// assets.json. `recipeArgs` are the arguments that make the same file again.
// The shared normalization gain of a patch's variants, found once per call: the key is the patch and the recipe arguments without
// the variant and the output name (everything else changes the gain).
using SharedGains = std::map<std::string, double>;

Baked bake_patch(const std::string& projectDir, const LoadedPatch& loaded, const std::string& outRel, const RenderArgs& argsIn, const Json& recipeArgs, bool overwrite,
                 SharedGains* gains = nullptr) {
    RenderArgs args = argsIn;
    const std::string ext = to_lower(fs::extension(outRel));
    if (ext != ".wav" && ext != ".ogg")
        fail("invalid_argument", "`out` '" + outRel + "' must end in .wav or .ogg.", "Example: \"out\": \"" + default_out(loaded.rel) + "\".");
    auto norm = fs::normalize_checked(outRel);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The sound goes under assets/, and '" + outRel + "' is not there.", "Use a path such as \"" + default_out(loaded.rel) + "\".");
    const stdfs::path file = project_file(projectDir, *norm);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec) && !is_ours(projectDir, *norm))
        fail("exists", "'" + *norm + "' already exists and was not made by sfx.render.", "Pass overwrite: true to replace it, or choose another `out`.");
    require_usable_manifest(projectDir);

    const SfxPatch patch = effective_patch(loaded, args, kRender);
    if (gains && args.options.variant >= 0 && (args.options.normalize ? args.options.normalize->shared : patch.normalize.shared)) {
        Json keyArgs = recipeArgs;
        keyArgs.erase("variant");
        keyArgs.erase("out");
        const std::string key = loaded.rel + "|" + keyArgs.dump();
        auto it = gains->find(key);
        if (it == gains->end()) {
            auto g = sfx_shared_gain_db(patch, args.options);
            if (!g.ok()) fail("failed", loaded.rel + ": " + g.error().message, g.error().hint);
            it = gains->emplace(key, *g).first;
        }
        args.options.sharedGainDb = it->second;
    }
    auto audio = render_sfx(patch, args.options);
    if (!audio.ok()) fail("failed", loaded.rel + ": " + audio.error().message, audio.error().hint);
    std::vector<std::uint8_t> bytes = sfx_wav_bytes(*audio);
    if (ext == ".ogg") {
        auto ogg = encode_vorbis(bytes, 0.5);
        if (!ogg.ok()) fail("failed", "Cannot encode '" + *norm + "' as Ogg Vorbis: " + ogg.error().message, ogg.error().hint);
        bytes = std::move(*ogg);
    }
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(bytes.data()), bytes.size()), &err)) fail("failed", err);

    Json recipe = make_recipe(projectDir, kRender, recipeArgs, {loaded.rel});
    const std::string notes = std::format("sound patch {}{}, {:.2f} s, seed {}", loaded.rel, args.variant > 0 ? std::format(" variant {}", args.variant) : std::string(), audio->seconds(), args.seed);
    Json provenance = Json::object({{"origin", "original"}, {"ai", false}, {"kind", "sound"}, {"provider", "factoria sfx.render"}, {"seed", args.seed},
                                    {"license", "CC0-1.0"}, {"author", "factoria"}, {"notes", notes}, {"date", assets::today()}, {"recipe", recipe}});
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(*norm, [&](Json& e) {
            e.erase("analysis");
            // What a person recorded (license, author) stays when the sound is rendered again; the recipe, date and notes are the new render's.
            if (e.contains("provenance") && e["provenance"].is_object() && e["provenance"].value("provider", std::string()) == "factoria sfx.render") {
                for (const char* key : {"recipe", "date", "notes", "seed"}) e["provenance"][key] = provenance[key];
            } else {
                e["provenance"] = provenance;
            }
        });
        if (!r.ok()) fail("failed", "The sound was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }
    return {*norm, bytes.size(), std::move(*audio), std::move(provenance)};
}

Json measurements_json(const SfxAudio& audio) {
    return Json::object({{"lufs", round_to(audio.lufs, 1)}, {"peakDb", round_to(audio.peakDb, 1)}, {"seconds", round_to(audio.seconds(), 3)}, {"sampleRate", audio.sampleRate},
                         {"centroidHz", round_to(sfx_centroid_hz(audio), 0)}, {"riseSeconds", round_to(sfx_rise_seconds(audio), 3)}});
}

std::string file_stem(const std::string& path) {
    std::string name = path.substr(path.find_last_of('/') == std::string::npos ? 0 : path.find_last_of('/') + 1);
    const std::size_t dot = name.find_last_of('.');
    return dot == std::string::npos ? name : name.substr(0, dot);
}

audio_mix::SheetRow sheet_row(const std::string& label, const SfxAudio& audio) {
    audio_mix::SheetRow row;
    row.label = label;
    row.note = std::format("{:.1f} LUFS  {:.2f} s  {:.0f} Hz", audio.lufs, audio.seconds(), sfx_centroid_hz(audio));
    row.samples = audio.samples;
    row.rate = audio.sampleRate;
    return row;
}

// ---- sfx.render ----

// Renders `loaded` in memory with `args` (checks the variant and macro names too): the numbers of a take without writing it.
SfxAudio render_in_memory(const LoadedPatch& loaded, const RenderArgs& args, const char* command) {
    const SfxPatch patch = effective_patch(loaded, args, command);
    auto audio = render_sfx(patch, args.options);
    if (!audio.ok()) fail("failed", loaded.rel + ": " + audio.error().message, audio.error().hint);
    return std::move(*audio);
}

// The picture of a result: the spectrogram of one file, or the contact sheet of `rows`.
void add_picture(const std::string& projectDir, const Json& a, Json& result, const std::string& soundPath, const std::string& title, const std::vector<audio_mix::SheetRow>& rows) {
    Json pic;
    if (rows.empty()) {
        Json picArgs = Json::object({{"path", soundPath}});
        for (const char* key : {"width", "height"})
            if (a.contains(key)) picArgs[key] = a[key];
        if (a.contains("pictureOut")) picArgs["out"] = a["pictureOut"];
        pic = audio_mix::spectrogram_picture(projectDir, picArgs);
        if (pic.contains("$image")) result["$image"] = pic["$image"];
        pic.erase("$image");
        pic.erase("nextSteps");
        pic.erase("path");
        result["analysis"] = pic;  // the numbers of the file as written: integratedLufs, truePeakDb, clippedSamples, dominantBand...
        return;
    }
    pic = audio_mix::spectrogram_sheet(projectDir, title, rows, a.value("width", 1000), a.value("pictureOut", std::string()));
    if (pic.contains("$image")) result["$image"] = pic["$image"];
    if (pic.contains("picture")) result["picture"] = pic["picture"];
}

Json loudness_json(const std::vector<double>& lufs) {
    if (lufs.empty()) return Json::object();
    const auto [lo, hi] = std::minmax_element(lufs.begin(), lufs.end());
    return Json::object({{"minLufs", round_to(*lo, 1)}, {"maxLufs", round_to(*hi, 1)}, {"spreadLu", round_to(*hi - *lo, 1)}});
}

Json sfx_render_command(const std::string& projectDir, const Json& a) {
    check_arg_keys(kRender, a, "", {"path", "out", "seed", "freq", "note", "length", "tail", "macros", "variant", "variants", "picture", "pictureOut", "width", "height", "overwrite"});
    const std::string rel = patch_path(tooling_detail::arg_string(a, "path", true));
    const std::string outArg = tooling_detail::arg_string(a, "out", false);
    RenderArgs args = render_args(kRender, a);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const bool all = tooling_detail::arg_bool(a, "variants", false);
    const LoadedPatch loaded = load_patch(projectDir, rel);
    const bool wantPicture = tooling_detail::arg_bool(a, "picture", true);
    const Json picKeys = Json::object({{"picture", nullptr}, {"pictureOut", nullptr}, {"width", nullptr}, {"height", nullptr}});

    if (all) {
        if (!outArg.empty() || a.contains("variant"))
            fail("invalid_argument", "sfx.render: `variants: true` renders every variant to its own name_NN file, so it takes neither `out` nor `variant`.", "Render one variant with {\"variant\": 3}, or all of them with {\"variants\": true}.");
        const int count = loaded.patch.variations.count;
        if (count <= 0) fail("invalid_argument", "sfx.render: " + rel + " declares no variations.", "Add \"variations\": {\"count\": 6} to the patch (docs/SOUND.md, \"Variations\").");
        Json items = Json::array();
        std::vector<audio_mix::SheetRow> rows;
        std::vector<double> lufs;
        SharedGains gains;
        for (int n = 1; n <= count; ++n) {
            RenderArgs va = args;
            va.variant = n;
            va.options.variant = n - 1;
            const std::string out = out_for(loaded, va);
            Json ra = recipe_args(a, {{"path", rel}, {"out", out}, {"variants", Json()}, {"variant", n}, {"picture", Json()}, {"pictureOut", Json()}, {"width", Json()}, {"height", Json()}});
            const Baked b = bake_patch(projectDir, loaded, out, va, ra, overwrite, &gains);
            items.push_back(Json::object({{"variant", n}, {"path", b.out}, {"bytes", b.bytes}, {"measurements", measurements_json(b.audio)}}));
            rows.push_back(sheet_row(file_stem(b.out), b.audio));
            lufs.push_back(b.audio.lufs);
        }
        Json result = Json::object({{"patch", rel}, {"count", count}, {"seed", args.seed}, {"variants", items}, {"loudness", loudness_json(lufs)}});
        if (wantPicture) add_picture(projectDir, a, result, "", rel + ": " + std::to_string(count) + " variants", rows);
        result["nextSteps"] = Json::array({"Each row of the picture is one variant: they should sound alike but not the same. Widen or narrow `variations.spread` in " + rel + " and render again.",
                                           "Play one per call: AudioSource {\"clip\": \"" + default_out(rel) + "\", \"variants\": " + std::to_string(count) + "} or audio.play(\"" + default_out(rel) + "\", {variants: " + std::to_string(count) + "})."});
        return result;
    }

    const std::string out = outArg.empty() ? out_for(loaded, args) : outArg;
    Baked baked = bake_patch(projectDir, loaded, out, args, recipe_args(a, {{"path", rel}, {"out", outArg.empty() && args.variant == 0 ? Json() : Json(out)}, {"variants", Json()}, {"picture", Json()}, {"pictureOut", Json()}, {"width", Json()}, {"height", Json()}}), overwrite);

    Json result = Json::object({{"patch", rel}, {"path", baked.out}, {"bytes", baked.bytes}, {"seed", args.seed}, {"measurements", measurements_json(baked.audio)}, {"provenance", baked.provenance}});
    if (args.variant > 0) result["variant"] = args.variant;
    Json steps = Json::array();
    if (wantPicture) {
        add_picture(projectDir, a, result, baked.out, "", {});
        steps.push_back("Read the picture: waveform on top, spectrogram (log frequency) in the middle, loudness at the bottom. Change a number in " + rel + " and call sfx.render again.");
    }
    if (baked.audio.peakDb > -0.5) steps.push_back("It peaks at " + std::format("{:.1f}", baked.audio.peakDb) + " dBFS: lower a layer `gain` or the master `normalize` target.");
    steps.push_back("Play it: audio.play(\"" + baked.out + "\") in a script, or an AudioSource \"clip\". Same patch, same seed, same bytes.");
    if (loaded.patch.variations.count > 0 && args.variant == 0)
        steps.push_back(rel + " declares " + std::to_string(loaded.patch.variations.count) + " variations: {\"variants\": true} renders them all and shows one row per variant; sfx.bake writes them with the sound.");
    steps.push_back("After editing the patch, sfx.bake {\"path\":\"" + rel + "\"} renders just it (without `path` it renders every patch whose sound is missing or out of date).");
    result["nextSteps"] = steps;
    return result;
}

// ---- sfx.bake ----

Json sfx_bake_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.bake", a, "", {"force", "dryRun", "macros", "path"});
    const bool force = tooling_detail::arg_bool(a, "force", false), dryRun = tooling_detail::arg_bool(a, "dryRun", false);
    // `macros` here are for the render of every patch that is baked in this call; they are kept in the recipe.
    if (a.contains("macros")) render_args("sfx.bake", Json::object({{"macros", a["macros"]}}));
    Json baked = Json::array(), unchanged = Json::array(), skipped = Json::array(), failed = Json::array();
    std::vector<std::string> patches = list_patches(projectDir);
    if (a.contains("path") && !a["path"].is_null()) {
        // Only these patches (one path or a list); a path that is not a patch of the project is an error, nothing is rendered.
        std::vector<std::string> wanted;
        if (a["path"].is_string()) wanted.push_back(a["path"].get<std::string>());
        else if (a["path"].is_array())
            for (std::size_t i = 0; i < a["path"].size(); ++i) {
                if (!a["path"][i].is_string()) fail("invalid_argument", "sfx.bake: `path`[" + std::to_string(i) + "] must be a string.", "Pass \"path\": \"assets/audio/jump.sfx.json\" or a list of such paths.");
                wanted.push_back(a["path"][i].get<std::string>());
            }
        else fail("invalid_argument", "sfx.bake: `path` must be a string or a list of strings.", "Pass \"path\": \"assets/audio/jump.sfx.json\" or a list of such paths.");
        if (wanted.empty()) fail("invalid_argument", "sfx.bake: `path` is an empty list.", "List the patches to bake, or leave `path` out to bake every stale patch.");
        std::vector<std::string> chosen;
        for (const std::string& w : wanted) {
            const std::string rel = patch_path(w);
            auto it = std::find_if(patches.begin(), patches.end(), [&](const std::string& p) { return to_lower(p) == to_lower(rel); });
            if (it == patches.end())
                fail("not_found", "sfx.bake: '" + rel + "' is not a sound patch of the project.", did_you_mean(rel, patches) + " sfx.preset writes a new patch.");
            if (std::find(chosen.begin(), chosen.end(), *it) == chosen.end()) chosen.push_back(*it);
        }
        std::sort(chosen.begin(), chosen.end());
        patches = std::move(chosen);
    }
    SharedGains gains;
    std::string manifestText = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
    Json entries = Json::object();
    if (!manifestText.empty())
        if (auto parsed = parse_json(manifestText, assets::kManifestFile); parsed.ok() && parsed->is_object() && parsed->contains("assets") && (*parsed)["assets"].is_object()) entries = (*parsed)["assets"];
    for (const std::string& rel : patches) {
        // The sound of the patch, then one file per declared variation (name_01.wav ...).
        const std::string baseOut = default_out(rel);
        int count = 0;
        try {
            count = load_patch(projectDir, rel).patch.variations.count;
        } catch (const CommandError&) {  // a patch with mistakes is reported below, when its sound needs rendering
        }
        std::vector<std::pair<std::string, int>> targets = {{baseOut, 0}};
        for (int n = 1; n <= count; ++n) targets.push_back({sfx_variant_path(baseOut, n, count), n});
        const Json baseRecipe = entries.contains(baseOut) ? recipe_of(entries[baseOut]) : Json();
        const bool baseOurs = baseRecipe.is_object() && baseRecipe.value("command", std::string()) == kRender;
        for (const auto& [out, variant] : targets) {
            std::error_code ec;
            const bool exists = stdfs::exists(project_file(projectDir, out), ec);
            const Json entry = entries.contains(out) ? entries[out] : Json();
            const Json recipe = recipe_of(entry);
            const bool ours = recipe.is_object() && recipe.value("command", std::string()) == kRender;
            std::string reason;
            if (!exists) reason = "missing";
            else if (!ours) {
                skipped.push_back(Json::object({{"patch", rel}, {"out", out}, {"reason", "'" + out + "' exists and was not made by sfx.render; render it yourself with overwrite: true to replace it"}}));
                continue;
            } else if (force || a.contains("macros")) reason = "forced";
            else if (check_recipe(projectDir, recipe).stale()) reason = "stale";
            if (reason.empty()) {
                unchanged.push_back(out);
                continue;
            }
            if (dryRun) {
                baked.push_back(Json::object({{"patch", rel}, {"out", out}, {"reason", reason}}));
                continue;
            }
            try {
                const LoadedPatch loaded = load_patch(projectDir, rel);
                // An existing recipe keeps its own arguments (seed, note, an .ogg `out`): the bake renders what it recorded. A variant that has
                // none starts from the sound's own arguments.
                Json recipeArgs = ours ? recipe["args"] : (variant > 0 && baseOurs ? baseRecipe["args"] : Json::object({{"path", rel}}));
                if (!ours && variant > 0) {
                    recipeArgs.erase("macros");
                    if (baseOurs && baseRecipe["args"].contains("macros")) recipeArgs["macros"] = baseRecipe["args"]["macros"];
                    recipeArgs["out"] = out;
                    recipeArgs["variant"] = variant;
                }
                if (a.contains("macros")) recipeArgs["macros"] = a["macros"];
                const RenderArgs args = render_args(kRender, recipeArgs);
                const std::string target = ours ? recipeArgs.value("out", out) : out;
                const Baked b = bake_patch(projectDir, loaded, target, args, recipeArgs, true, &gains);
                Json item = Json::object({{"patch", rel}, {"out", b.out}, {"reason", reason}, {"measurements", measurements_json(b.audio)}});
                if (variant > 0) item["variant"] = variant;
                baked.push_back(item);
            } catch (const CommandError& e) {
                Json f = Json::object({{"patch", rel}, {"out", out}, {"error", Json::object({{"code", e.code}, {"message", e.what()}, {"hint", e.hint}})}});
                if (e.data.is_object() && e.data.contains("issues")) f["error"]["issues"] = e.data["issues"];
                failed.push_back(f);
            }
        }
    }
    Json result = Json::object({{dryRun ? "wouldBake" : "baked", baked}, {"count", baked.size()}, {"unchanged", unchanged}});
    if (dryRun) result["dryRun"] = true;
    if (!skipped.empty()) result["skipped"] = skipped;
    if (!failed.empty()) result["failed"] = failed;
    Json steps = Json::array();
    if (patches.empty()) steps.push_back("There are no sound patches yet: sfx.preset {\"name\":\"coin\",\"path\":\"assets/audio/coin.sfx.json\"} writes one.");
    if (!failed.empty()) steps.push_back("Fix the patches in `failed` (each issue has its JSON pointer and a hint) and call sfx.bake again.");
    steps.push_back("sfx.render {\"path\":...} renders one patch and shows its spectrogram.");
    result["nextSteps"] = steps;
    return result;
}

// ---- sfx.tweak ----

// The macro names a patch answers to: the built-in knobs and the custom ones it declares.
std::vector<std::string> macro_names(const SfxPatch& patch) {
    std::vector<std::string> names;
    for (const SfxMacroInfo& m : sfx_macros()) names.push_back(m.name);
    for (const SfxMacroDef& d : patch.macroDefs)
        if (std::find(names.begin(), names.end(), d.name) == names.end()) names.push_back(d.name);
    return names;
}

void set_macro_value(Json& patchJson, const std::string& name, double value) {
    if (!patchJson.contains("macros") || !patchJson["macros"].is_object()) patchJson["macros"] = Json::object();
    Json& slot = patchJson["macros"][name];
    if (slot.is_object()) slot["value"] = value;
    else slot = value;
}

Json sfx_tweak_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.tweak", a, "", {"path", "macros", "absolute", "render", "seed", "picture", "pictureOut", "width", "height"});
    const std::string rel = patch_path(tooling_detail::arg_string(a, "path", true));
    if (!a.contains("macros") || !a["macros"].is_object() || a["macros"].empty())
        fail("invalid_argument", "sfx.tweak: `macros` must say what to turn, e.g. {\"brightness\": 0.2, \"tail\": -0.3}.",
             "Each value is added to the macro the patch declares (so +0.2 is a little brighter than now); with absolute: true it is the new value itself. Macros: " + join([] { std::vector<std::string> n; for (const SfxMacroInfo& m : sfx_macros()) n.push_back(m.name); return n; }(), ", ") + ".");
    const bool absolute = tooling_detail::arg_bool(a, "absolute", false);
    const LoadedPatch loaded = load_patch(projectDir, rel);
    const std::vector<std::string> known = macro_names(loaded.patch);
    Json json = loaded.json;
    Json changes = Json::object();
    for (auto it = a["macros"].begin(); it != a["macros"].end(); ++it) {
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            fail("invalid_argument", "sfx.tweak: unknown macro '" + it.key() + "'.", did_you_mean(it.key(), known) + " Macros: " + join(known, ", ") + ".");
        if (!it.value().is_number() || !std::isfinite(it.value().get<double>()))
            fail("invalid_argument", "sfx.tweak: macro `" + it.key() + "` must be a number.", absolute ? "The new value, from -1 to 1." : "How much to add, e.g. +0.2.");
        const double before = loaded.patch.macro_value(it.key());
        const double after = round_to(std::clamp(absolute ? it.value().get<double>() : before + it.value().get<double>(), -1.0, 1.0), 3);
        set_macro_value(json, it.key(), after);
        changes[it.key()] = Json::object({{"before", round_to(before, 3)}, {"after", after}});
    }
    std::vector<SfxIssue> issues;
    auto patch = parse_sfx(json, rel, &issues);
    if (!patch.ok()) throw CommandError("invalid_patch", patch.error().message, patch.error().hint, Json::object({{"issues", issues_json(issues)}}));
    RenderArgs plain = render_args("sfx.tweak", a.contains("seed") ? Json::object({{"seed", a["seed"]}}) : Json::object());
    std::optional<Json> beforeMeasure;
    if (tooling_detail::arg_bool(a, "render", true)) beforeMeasure = measurements_json(render_in_memory(loaded, plain, "sfx.tweak"));
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), json.dump(2) + "\n", &err)) fail("failed", err);

    Json result = Json::object({{"patch", rel}, {"macros", changes}});
    if (!tooling_detail::arg_bool(a, "render", true)) {
        result["nextSteps"] = Json::array({"The patch is changed; sfx.render {\"path\":\"" + rel + "\"} renders it, sfx.bake renders every sound that is now out of date."});
        return result;
    }
    // Render again: the sound, then its variants, with the picture of whichever shows the change.
    Json renderArgs = Json::object({{"path", rel}, {"overwrite", false}});
    for (const char* key : {"seed", "picture", "pictureOut", "width", "height"})
        if (a.contains(key)) renderArgs[key] = a[key];
    const bool variants = patch->variations.count > 0;
    if (variants) renderArgs["picture"] = false;
    Json rendered = sfx_render_command(projectDir, renderArgs);
    result["path"] = rendered["path"];
    result["measurementsBefore"] = *beforeMeasure;
    result["measurements"] = rendered["measurements"];
    if (rendered.contains("analysis")) result["analysis"] = rendered["analysis"];
    if (rendered.contains("$image")) result["$image"] = rendered["$image"];
    if (variants) {
        Json va = renderArgs;
        va["variants"] = true;
        va["picture"] = a.value("picture", true);
        va.erase("overwrite");
        Json all = sfx_render_command(projectDir, va);
        result["variants"] = all["variants"];
        result["loudness"] = all["loudness"];
        if (all.contains("$image")) result["$image"] = all["$image"];
    }
    result["nextSteps"] = Json::array({"Compare measurementsBefore and measurements (centroidHz is the brightness, riseSeconds the attack, seconds the length), then turn the macro again if it is not enough.",
                                       "The numbers are saved in the patch's `macros`; edit " + rel + " by hand to change what a macro does (docs/SOUND.md, \"Macros\")."});
    return result;
}

// ---- sfx.edit ----

// Changes one field of a patch by its JSON pointer and writes the patch back when the result still parses (the sound panel's inspector).
Json sfx_edit_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.edit", a, "", {"path", "op", "pointer", "value", "index", "to"});
    const std::string rel = patch_path(tooling_detail::arg_string(a, "path", true));
    const std::string op = tooling_detail::arg_string(a, "op", true);
    if (op != "set" && op != "remove" && op != "add" && op != "move")
        fail("invalid_argument", "sfx.edit: unknown op '" + op + "'.", "op is set, remove, add (insert into an array) or move (reorder an array).");
    const std::string pointer = tooling_detail::arg_string(a, "pointer", true);
    if (!pointer.empty() && pointer[0] != '/') fail("invalid_argument", "sfx.edit: `pointer` must be a JSON pointer such as /oscillators/0/wave.", "It starts with a slash; /macros/brightness is the brightness macro.");
    const LoadedPatch loaded = load_patch(projectDir, rel);
    Json json = loaded.json;
    Json::json_pointer ptr;
    try {
        ptr = Json::json_pointer(pointer);
    } catch (const std::exception& e) {
        fail("invalid_argument", std::string("sfx.edit: bad pointer: ") + e.what(), "Use a JSON pointer such as /oscillators/0/wave.");
    }
    auto need_array = [&]() -> Json& {
        if (!json.contains(ptr) || !json.at(ptr).is_array()) fail("invalid_argument", "sfx.edit: " + pointer + " is not an array in " + rel + ".", "Point at the array itself, e.g. /oscillators or /effects.");
        return json.at(ptr);
    };
    try {
        if (op == "set") {
            if (!a.contains("value")) fail("invalid_argument", "sfx.edit: `set` needs a `value`.", "Use op remove to delete a field.");
            if (pointer.empty()) fail("invalid_argument", "sfx.edit: set needs a pointer to a field.", "Example: /oscillators/0/wave.");
            const Json::json_pointer parent = ptr.parent_pointer();
            if (!json.contains(parent)) fail("invalid_argument", "sfx.edit: " + parent.to_string() + " does not exist in " + rel + ".", "Set the parent first, or point at an existing object.");
            json[ptr] = a["value"];
        } else if (op == "remove") {
            if (pointer.empty() || !json.contains(ptr)) fail("not_found", "sfx.edit: " + pointer + " is not in " + rel + ".", "Nothing to remove there.");
            const Json::json_pointer parent = ptr.parent_pointer();
            Json& holder = json.at(parent);
            if (holder.is_array()) holder.erase(holder.begin() + std::stoul(ptr.back()));
            else holder.erase(ptr.back());
        } else if (op == "add") {
            Json& arr = need_array();
            if (!a.contains("value")) fail("invalid_argument", "sfx.edit: `add` needs a `value` to insert.", "Example: {\"type\":\"sine\"} into /oscillators.");
            const std::size_t at = a.contains("index") ? static_cast<std::size_t>(std::clamp<long long>(a["index"].get<long long>(), 0, static_cast<long long>(arr.size()))) : arr.size();
            arr.insert(arr.begin() + static_cast<std::ptrdiff_t>(at), a["value"]);
        } else {
            Json& arr = need_array();
            if (!a.contains("index") || !a.contains("to") || !a["index"].is_number_integer() || !a["to"].is_number_integer())
                fail("invalid_argument", "sfx.edit: `move` needs integer `index` and `to`.", "index is the element to move, to its new place.");
            const long long from = a["index"].get<long long>(), to = a["to"].get<long long>(), n = static_cast<long long>(arr.size());
            if (from < 0 || from >= n || to < 0 || to >= n) fail("invalid_argument", "sfx.edit: index/to must be 0.." + std::to_string(n - 1) + ".", "The array has " + std::to_string(n) + " elements.");
            Json item = arr[static_cast<std::size_t>(from)];
            arr.erase(arr.begin() + from);
            arr.insert(arr.begin() + to, item);
        }
    } catch (const CommandError&) {
        throw;
    } catch (const std::exception& e) {
        fail("invalid_argument", std::string("sfx.edit: ") + e.what(), "Check the pointer and the value against schemas/sfx.schema.json.");
    }
    std::vector<SfxIssue> issues;
    auto patch = parse_sfx(json, rel, &issues);
    if (!patch.ok()) throw CommandError("invalid_patch", "sfx.edit: the patch would no longer be valid, so nothing was written. " + patch.error().message, patch.error().hint, Json::object({{"issues", issues_json(issues)}}));
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), json.dump(2) + "\n", &err)) fail("failed", err);
    return Json::object({{"patch", rel},
                         {"nextSteps", Json::array({"The patch is changed, not rendered: sfx.render {\"path\":\"" + rel + "\"} renders it, sfx.bake renders every sound that is out of date."})}});
}

// ---- sfx.family ----

// One interface sound of a family: how its patch differs from the base. The loudness is not here: every member takes the base's
// normalization, so they sit at the same level.
struct FamilyRole {
    const char* name;
    const char* what;
    double length, tail;
    std::vector<std::pair<const char*, double>> macros;  // added to the base's declared macros
    std::vector<double> arpeggio;                         // semitone steps, empty = keep the base's pitch movement
    double arpeggioRate;
    double sweepSemitones, sweepTime;                     // 0 = no slide
};

const std::vector<FamilyRole>& family_roles() {
    static const std::vector<FamilyRole> roles = {
        {"click", "a press: short and dry", 0.035, 0.03, {{"brightness", 0.3}, {"tail", -0.5}}, {}, 0, 0, 0},
        {"hover", "the pointer arrives on a control: soft, high and brief", 0.05, 0.05, {{"pitch", 0.25}, {"brightness", 0.1}, {"weight", -0.3}}, {}, 0, 0, 0},
        {"confirm", "an action went through: two notes up", 0.13, 0.12, {{"brightness", 0.2}}, {0, 7}, 12, 0, 0},
        {"cancel", "an action was backed out of: two notes down", 0.13, 0.1, {{"pitch", -0.15}, {"brightness", -0.2}}, {0, -5}, 12, 0, 0},
        {"error", "something is not allowed: low, buzzy and sliding down", 0.2, 0.1, {{"pitch", -0.3}, {"weight", 0.3}, {"grit", 0.5}}, {}, 0, -3, 0.15},
        {"open", "a panel opens: a rising slide", 0.14, 0.16, {{"brightness", 0.3}, {"attack", 0.2}}, {}, 0, 7, 0.14},
        {"close", "a panel closes: a falling slide", 0.12, 0.12, {{"brightness", -0.2}}, {}, 0, -7, 0.12},
        {"notify", "something happened elsewhere: three rising notes with a tail", 0.2, 0.25, {{"brightness", 0.1}, {"tail", 0.3}}, {0, 5, 9}, 10, 0, 0},
    };
    return roles;
}

bool layer_is_pitched(const Json& layer) {
    if (!layer.contains("pitch") || !layer["pitch"].is_object() || !layer.contains("oscillators") || !layer["oscillators"].is_array()) return false;
    for (const Json& o : layer["oscillators"])
        if (o.is_object() && o.value("wave", std::string("sine")) != "noise") return true;
    return false;
}

// `base` with the role's differences, as a patch of its own.
Json family_member(const Json& base, const FamilyRole& role, const std::string& baseRel) {
    Json j = base;
    j["doc"] = std::string(role.name) + ": " + role.what + ". Member of the family of " + baseRel + (base.contains("doc") && base["doc"].is_string() && !base["doc"].get<std::string>().empty() ? " (" + base["doc"].get<std::string>() + ")" : std::string());
    j["length"] = role.length;
    j["tail"] = role.tail;
    if (j.contains("layers") && j["layers"].is_array()) {
        for (Json& layer : j["layers"]) {
            if (!layer.is_object()) continue;
            if (layer.contains("length") && layer["length"].is_number() && layer["length"].get<double>() > role.length) layer["length"] = role.length;
            if (layer.contains("start") && layer["start"].is_number() && layer["start"].get<double>() >= role.length) layer["start"] = round_to(role.length * 0.5, 4);
            if (!layer_is_pitched(layer)) continue;
            Json& pitch = layer["pitch"];
            if (!role.arpeggio.empty()) {
                pitch.erase("sweep");
                pitch["arpeggio"] = Json::object({{"steps", role.arpeggio}, {"rate", role.arpeggioRate}, {"mode", "once"}});
            } else if (role.sweepSemitones != 0.0) {
                pitch.erase("arpeggio");
                pitch["sweep"] = Json::object({{"semitones", role.sweepSemitones}, {"time", role.sweepTime}, {"curve", 1.0}});
            }
        }
    }
    // The role's knobs are turned from where the base has them.
    SfxPatch parsed;
    {
        std::vector<SfxIssue> ignore;
        if (auto p = parse_sfx(base, baseRel, &ignore); p.ok()) parsed = std::move(*p);
    }
    for (const auto& [name, delta] : role.macros) set_macro_value(j, name, round_to(std::clamp(parsed.macro_value(name) + delta, -1.0, 1.0), 3));
    // Same loudness target and ceiling for every member.
    Json normalize = base.contains("master") && base["master"].is_object() && base["master"].contains("normalize") ? base["master"]["normalize"] : Json::object({{"mode", "lufs"}, {"target", -18}, {"ceilingDb", -1}});
    if (!j.contains("master") || !j["master"].is_object()) j["master"] = Json::object();
    j["master"]["normalize"] = normalize;
    return j;
}

Json sfx_family_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.family", a, "", {"from", "names", "preset", "out", "overwrite", "render", "picture", "pictureOut", "width", "height"});
    const std::string baseRel = patch_path(tooling_detail::arg_string(a, "from", true), "from");
    std::vector<std::string> roleNames;
    for (const FamilyRole& r : family_roles()) roleNames.push_back(r.name);
    if (int(a.contains("names")) + int(a.contains("preset")) != 1)
        fail("invalid_argument", "sfx.family: give exactly one of `names` and `preset`.", "{\"preset\":\"ui\"} makes " + join(roleNames, ", ") + "; {\"names\":[\"click\",\"confirm\"]} makes only those.");
    std::vector<std::string> names;
    if (a.contains("preset")) {
        if (!a["preset"].is_string() || a["preset"].get<std::string>() != "ui") fail("invalid_argument", "sfx.family: unknown preset " + a["preset"].dump() + ".", "The only preset is \"ui\": " + join(roleNames, ", ") + ".");
        names = roleNames;
    } else {
        if (!a["names"].is_array() || a["names"].empty()) fail("invalid_argument", "sfx.family: `names` must be a list of sound names.", "Names: " + join(roleNames, ", ") + ".");
        for (const Json& n : a["names"]) {
            const std::string name = n.is_string() ? to_lower(n.get<std::string>()) : std::string();
            if (std::find(roleNames.begin(), roleNames.end(), name) == roleNames.end())
                fail("invalid_argument", "sfx.family: unknown sound " + n.dump() + ".", did_you_mean(name, roleNames) + " Names: " + join(roleNames, ", ") + ".");
            if (std::find(names.begin(), names.end(), name) == names.end()) names.push_back(name);
        }
    }
    const LoadedPatch loaded = load_patch(projectDir, baseRel);
    std::string dir = tooling_detail::arg_string(a, "out", false);
    if (dir.empty()) dir = baseRel.substr(0, baseRel.size() - std::string(kSuffix).size()) + "_family";
    while (!dir.empty() && dir.back() == '/') dir.pop_back();
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const bool render = tooling_detail::arg_bool(a, "render", true);

    struct Member { std::string name, rel, text; Json json; SfxPatch patch; };
    std::vector<Member> members;
    for (const std::string& name : names) {
        const FamilyRole* role = nullptr;
        for (const FamilyRole& r : family_roles())
            if (name == r.name) role = &r;
        Member m;
        m.name = name;
        m.rel = patch_path(dir + "/" + name + kSuffix, "out");
        m.json = family_member(loaded.json, *role, baseRel);
        std::vector<SfxIssue> issues;
        auto p = parse_sfx(m.json, m.rel, &issues);
        if (!p.ok()) throw CommandError("invalid_patch", "The " + name + " of the family is not a valid patch: " + p.error().message, "The base patch " + baseRel + " does not fit this sound (" + p.error().hint + "). Fix the base or leave this name out.", Json::object({{"issues", issues_json(issues)}}));
        m.patch = std::move(*p);
        m.text = m.json.dump(2) + "\n";
        members.push_back(std::move(m));
    }
    std::vector<std::string> clash;
    for (const Member& m : members) {
        std::error_code ec;
        if (stdfs::exists(project_file(projectDir, m.rel), ec)) clash.push_back(m.rel);
    }
    if (!overwrite && !clash.empty()) fail("exists", "sfx.family: " + join(clash, ", ") + " already exist.", "Pass overwrite: true to replace them, or choose another `out` directory.");
    for (const Member& m : members) {
        std::string err;
        if (!tooling_detail::write_file(project_file(projectDir, m.rel), m.text, &err)) fail("failed", err);
    }

    Json items = Json::array();
    std::vector<audio_mix::SheetRow> rows;
    std::vector<double> lufs;
    for (const Member& m : members) {
        LoadedPatch lp{m.rel, m.text, m.json, m.patch};
        Json item = Json::object({{"patch", m.rel}});
        RenderArgs plain;
        if (render) {
            const Baked b = bake_patch(projectDir, lp, default_out(m.rel), plain, Json::object({{"path", m.rel}}), overwrite);
            item["path"] = b.out;
            item["measurements"] = measurements_json(b.audio);
            rows.push_back(sheet_row(m.name, b.audio));
            lufs.push_back(b.audio.lufs);
        } else {
            const SfxAudio audio = render_in_memory(lp, plain, "sfx.family");
            item["measurements"] = measurements_json(audio);
            rows.push_back(sheet_row(m.name, audio));
            lufs.push_back(audio.lufs);
        }
        items.push_back(item);
    }
    Json result = Json::object({{"from", baseRel}, {"out", dir}, {"count", items.size()}, {"sounds", items}, {"loudness", loudness_json(lufs)}});
    Json steps = Json::array();
    if (tooling_detail::arg_bool(a, "picture", true)) add_picture(projectDir, a, result, "", baseRel + ": family", rows);
    const double spread = result["loudness"].value("spreadLu", 0.0);
    if (spread > 3.0) steps.push_back("The sounds span " + std::format("{:.1f}", spread) + " LU: the very short ones hit the peak ceiling before the loudness target. Raise `ceilingDb` in the base's master.normalize (or use a longer base) and make the family again with overwrite: true.");
    steps.push_back("Each member is a patch of its own (copied from " + baseRel + "): edit it, or turn its knobs with sfx.tweak {\"path\":\"" + dir + "/click.sfx.json\",\"macros\":{\"brightness\":0.2}}.");
    steps.push_back("Play them: audio.play(\"" + dir + "/click.wav\"). " + (render ? "" : "Nothing was rendered: sfx.bake renders them. ") + "Editing the base does not change the members; make the family again with overwrite: true.");
    result["nextSteps"] = steps;
    return result;
}

// ---- sfx.preset ----

Json sfx_preset_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.preset", a, "", {"name", "path", "overwrite"});
    const std::string name = to_lower(tooling_detail::arg_string(a, "name", false));
    const std::string pathArg = tooling_detail::arg_string(a, "path", false);
    std::vector<std::string> names;
    for (const SfxPresetInfo& p : sfx_presets()) names.push_back(p.name);
    if (name.empty()) {
        if (!pathArg.empty()) fail("invalid_argument", "`path` needs a preset `name` to write.", "Presets: " + join(names, ", ") + ".");
        Json list = Json::array();
        for (const SfxPresetInfo& p : sfx_presets()) list.push_back(Json::object({{"name", p.name}, {"what", p.what}}));
        return Json::object({{"presets", list},
                             {"nextSteps", Json::array({"sfx.preset {\"name\":\"coin\"} returns the patch of a preset; add \"path\":\"assets/audio/coin.sfx.json\" to write it, edit it, then sfx.render it."})}});
    }
    std::optional<Json> patch = sfx_preset_patch(name);
    if (!patch) fail("not_found", "Unknown preset '" + name + "'.", did_you_mean(name, names) + " Presets: " + join(names, ", ") + ".");
    std::string what;
    for (const SfxPresetInfo& p : sfx_presets())
        if (p.name == name) what = p.what;
    Json result = Json::object({{"name", name}, {"what", what}, {"patch", *patch}});
    if (pathArg.empty()) {
        result["nextSteps"] = Json::array({"Write it with {\"name\":\"" + name + "\",\"path\":\"assets/audio/" + name + ".sfx.json\"}, or paste the patch into a file named <name>.sfx.json and edit it."});
        return result;
    }
    const std::string rel = patch_path(pathArg);
    const stdfs::path file = project_file(projectDir, rel);
    std::error_code ec;
    if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(file, ec)) fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    std::string err;
    if (!tooling_detail::write_file(file, patch->dump(2) + "\n", &err)) fail("failed", err);
    result.erase("patch");
    result["path"] = rel;
    result["nextSteps"] = Json::array({"Render it: sfx.render {\"path\":\"" + rel + "\"} (writes " + default_out(rel) + " and shows the spectrogram).",
                                       "Change a number (pitch.freq, amp.decay, filter.cutoff...) and render again; sfx.info {\"path\":\"" + rel + "\"} lists what the patch holds."});
    return result;
}

// ---- sfx.info ----

const char* wave_name(SfxWave w) {
    static const char* names[] = {"sine", "square", "saw", "triangle", "noise", "table"};
    return names[int(w)];
}
const char* effect_name(SfxEffectType t) {
    static const char* names[] = {"filter", "distortion", "bitcrush", "delay", "reverb"};
    return names[int(t)];
}

Json effects_json(const std::vector<SfxEffect>& list) {
    Json out = Json::array();
    for (const SfxEffect& e : list) out.push_back(Json::object({{"type", effect_name(e.type)}, {"enabled", e.enabled}}));
    return out;
}

Json sfx_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.info", a, "", {"path", "patch", "preset", "seed"});
    if (int(a.contains("path")) + int(a.contains("patch")) + int(a.contains("preset")) != 1)
        fail("invalid_argument", "Give exactly one of `path` (a patch file), `patch` (the patch as JSON) and `preset` (a preset name).", "Example: {\"path\":\"assets/audio/jump.sfx.json\"}.");
    std::string rel, text;
    Json json;
    if (a.contains("path")) {
        rel = patch_path(tooling_detail::arg_string(a, "path", true));
        const stdfs::path file = project_file(projectDir, rel);
        auto t = tooling_detail::read_file(file);
        if (!t) {
            const std::vector<std::string> all = list_patches(projectDir);
            fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with sfx.preset." : did_you_mean(rel, all) + " Patches: " + join(all, ", ") + ".");
        }
        text = *t;
        auto parsed = parse_json(text, rel);
        if (!parsed.ok()) return Json::object({{"valid", false}, {"patch", rel}, {"issues", Json::array({Json::object({{"pointer", ""}, {"message", parsed.error().message}, {"hint", parsed.error().hint}})})}});
        json = std::move(*parsed);
    } else if (a.contains("patch")) {
        json = a["patch"];
    } else {
        const std::string name = to_lower(tooling_detail::arg_string(a, "preset", true));
        std::optional<Json> p = sfx_preset_patch(name);
        if (!p) {
            std::vector<std::string> names;
            for (const SfxPresetInfo& i : sfx_presets()) names.push_back(i.name);
            fail("not_found", "Unknown preset '" + name + "'.", did_you_mean(name, names) + " Presets: " + join(names, ", ") + ".");
        }
        json = *p;
    }
    std::vector<SfxIssue> issues;
    auto patch = parse_sfx(json, rel, &issues);
    if (!patch.ok()) {
        Json r = Json::object({{"valid", false}, {"issues", issues_json(issues)}});
        if (!rel.empty()) r["patch"] = rel;
        r["nextSteps"] = Json::array({"Fix each issue at its JSON pointer (the hint says how) and call sfx.info again."});
        return r;
    }
    Json layers = Json::array();
    for (const SfxLayer& l : patch->layers) {
        Json oscs = Json::array();
        for (const SfxOscillator& o : l.oscillators) oscs.push_back(wave_name(o.wave));
        Json layer = Json::object({{"oscillators", oscs}, {"startSeconds", l.start}, {"gain", l.gain}, {"freq", l.pitch.freq}});
        if (!l.name.empty()) layer["name"] = l.name;
        if (l.filter.enabled) layer["filter"] = true;
        if (!l.effects.empty()) layer["effects"] = effects_json(l.effects);
        layers.push_back(layer);
    }
    Json result = Json::object({{"valid", true},
                                {"doc", patch->doc},
                                {"sampleRate", patch->sampleRate},
                                {"length", patch->length},
                                {"tail", patch->tail},
                                {"seed", patch->seed},
                                {"rootHz", round_to(patch->root_hz(), 2)},
                                {"layers", layers},
                                {"masterEffects", effects_json(patch->effects)}});
    if (!rel.empty()) {
        result["patch"] = rel;
        result["sha256"] = sha256_hex(text);
        const std::string out = default_out(rel);
        std::error_code ec;
        Json baked = Json::object({{"path", out}, {"exists", stdfs::exists(project_file(projectDir, out), ec)}});
        if (baked["exists"].get<bool>()) {
            const std::string manifest = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
            Json recipe;
            if (auto parsed = parse_json(manifest, assets::kManifestFile); parsed.ok() && parsed->is_object() && parsed->contains("assets") && (*parsed)["assets"].is_object())
                if (auto it = (*parsed)["assets"].find(out); it != (*parsed)["assets"].end()) recipe = recipe_of(*it);
            baked["madeByPatch"] = recipe.is_object() && recipe.value("command", std::string()) == kRender;
            if (baked["madeByPatch"].get<bool>()) baked["stale"] = check_recipe(projectDir, recipe).stale();
        }
        result["baked"] = baked;
    }
    RenderArgs args = render_args("sfx.info", a.contains("seed") ? Json::object({{"seed", a["seed"]}}) : Json::object());
    auto audio = render_sfx(*patch, args.options);
    if (audio.ok()) result["measurements"] = measurements_json(*audio);
    else result["renderError"] = audio.error().message;
    {
        // The knobs: every built-in macro with the value the patch declares (0 = as written), and the custom ones with what they bind.
        Json macros = Json::object();
        for (const SfxMacroInfo& m : sfx_macros()) macros[m.name] = Json::object({{"value", round_to(patch->macro_value(m.name), 3)}, {"what", m.what}});
        for (const SfxMacroDef& d : patch->macroDefs)
            if (!d.builtin) macros[d.name] = Json::object({{"value", round_to(d.value, 3)}, {"what", d.doc.empty() ? "custom macro" : d.doc}, {"binds", d.binds.size()}});
        result["macros"] = macros;
    }
    if (patch->variations.count > 0) {
        Json v = Json::object({{"count", patch->variations.count}, {"seed", patch->variations.seed}});
        if (!rel.empty()) {
            Json files = Json::array();
            for (int n = 1; n <= patch->variations.count; ++n) {
                const std::string path = sfx_variant_path(default_out(rel), n, patch->variations.count);
                std::error_code ec;
                files.push_back(Json::object({{"variant", n}, {"path", path}, {"exists", stdfs::exists(project_file(projectDir, path), ec)}}));
            }
            v["files"] = files;
        }
        result["variations"] = v;
    }
    result["nextSteps"] = Json::array({"sfx.render renders it to a WAV and shows its spectrogram; sfx.bake renders every patch that is missing its sound or out of date."});
    return result;
}

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json number(const char* what, double lo, double hi) { return Json::object({{"type", "number"}, {"minimum", lo}, {"maximum", hi}, {"description", what}}); }
Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }

}  // namespace

void register_sfx_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = kRender;
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Render a sound patch (*.sfx.json) to a WAV or OGG next to it and see its spectrogram: the engine's own synthesizer, offline and deterministic.";
        info.description =
            "Reads the sound patch at `path` (assets/.../name.sfx.json, format factoria.sfx/1: layers of "
            "oscillators with envelopes, pitch sweeps and arpeggios, filters, FM and ring modulation, "
            "distortion, bitcrush, delay and reverb; docs/SOUND.md and schemas/sfx.schema.json) and renders "
            "it to mono 16-bit WAV at `out` (default: the patch's path with .wav; a path ending in .ogg "
            "encodes Ogg Vorbis). No provider, no key, no other program: the same patch, `seed` and options "
            "give the same bytes on every platform. The sound is levelled to the patch's normalization "
            "(default -18 LUFS, peak under -1 dBFS). The file gets provenance and a recipe in assets.json "
            "whose input is the patch, so project.validate warns when the patch changed after the sound was "
            "made and assets.regenerate renders it again. A patch with mistakes fails with `invalid_patch` "
            "and every problem in data.issues (JSON pointer, what is wrong, how to fix it). The result has "
            "measurements (lufs, peakDb, seconds), the numbers of the file as written (`analysis`, from "
            "assets.spectrogram) and the picture (`$image`): waveform, spectrogram and loudness curve. "
            "Example: {\"path\":\"assets/audio/coin.sfx.json\"}"
            FA_COMMAND_DETAILS
            "Options that change one render without editing the patch: `seed` (another take of the noise), "
            "`freq` or `note` (transpose so the patch's base pitch becomes this), `length`, `tail`, and "
            "`macros` (meaning knobs from -1 to 1: attack, brightness, weight, tail, pitch, grit, plus the "
            "patch's own; they replace the values the patch declares). A patch that declares `variations` "
            "renders one take with `variant` (1-based; the file is name_NN.wav) or all of them with "
            "`variants: true`, which returns the measurements of each and one picture with a row per "
            "variant. The measurements also have centroidHz (the brightness) and riseSeconds (the attack). "
            "An existing file that sfx.render did not make is an `exists` error unless overwrite is true.";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"required", Json::array({"path"})},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"path", str("The sound patch, project-relative, under assets/ and ending in .sfx.json, e.g. \"assets/audio/coin.sfx.json\".")},
                                                             {"out", str("Where to write the sound: .wav or .ogg under assets/. Default: the patch's path with .wav.")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"default", 0}, {"description", "Added to the patch's seed: another take of every noise. The same seed always gives the same file."}})},
                                                             {"freq", number("Transpose the patch so its base pitch (the first pitched layer's pitch.freq) becomes this frequency in Hz. Fixed-frequency oscillators stay.", 20, 20000)},
                                                             {"note", str("The same as freq as a note name: \"C4\" (middle C), \"A4\" (440 Hz), \"C#3\", \"Bb2\".")},
                                                             {"length", number("Seconds the sound is held, replacing the patch's `length` for this render.", 0.001, 30)},
                                                             {"tail", number("Seconds after the length for releases, echoes and reverb, replacing the patch's `tail`.", 0, 30)},
                                                             {"macros", Json::object({{"type", "object"}, {"additionalProperties", number("Knob position.", -1, 1)}, {"description", "Macro values for this render, e.g. {\"brightness\": 0.3, \"tail\": -0.5}: attack, brightness, weight, tail, pitch, grit or a macro the patch declares. Replaces the patch's declared value; kept in the recipe."}})},
                                                             {"variant", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 64}, {"description", "Render this variation (1-based) of a patch that declares `variations`; the default out is name_NN.wav."}})},
                                                             {"variants", boolean("Render every variation of the patch to name_01.wav, name_02.wav... and return one picture with a row per variant. Takes neither `out` nor `variant`.", false)},
                                                             {"picture", boolean("Return the spectrogram picture (`$image`) of the sound. Turn it off when rendering many.", true)},
                                                             {"pictureOut", str("Also keep the picture's PNG at this project path (ends in .png). Default: a temporary screenshot.")},
                                                             {"width", Json::object({{"type", "integer"}, {"minimum", 400}, {"maximum", 2400}, {"description", "Width of the picture in pixels (default 1000)."}})},
                                                             {"height", Json::object({{"type", "integer"}, {"minimum", 280}, {"maximum", 1600}, {"description", "Height of the picture in pixels (default 640)."}})},
                                                             {"overwrite", boolean("Replace the sound when it exists and was not made by sfx.render (a sound made by it is always replaced).", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_render_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "sfx.bake";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Render every sound patch of the project whose WAV is missing or out of date.";
        info.description =
            "Finds every assets/**/*.sfx.json and renders the ones whose sound (the patch's path with .wav) does not exist, or was made by sfx.render from a patch that has changed since (the "
            "recipe's input hash differs: the same check project.validate does). Sounds that are up to date are left alone, a file at that path that sfx.render did not make is skipped and reported, "
            "and a patch with mistakes is listed in `failed` with its issues while the others are still baked. An existing recipe keeps its own arguments (seed, note, macros, an .ogg `out`). "
            "A patch with `variations` is baked with all its takes (name_01.wav ... each with a recipe of its own). `macros` replaces the macro values of every render in this call (it forces them and is kept in the recipes). "
            "`path` (one patch or a list) bakes only those patches, with the same rules (stale or missing only, `force` renders them anyway). "
            "No pictures are returned; use sfx.render for one patch. Example: {\"dryRun\":true} lists what would be rendered.";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"force", boolean("Render every patch again, even when its sound is up to date.", false)},
                                                             {"path", Json::object({{"oneOf", Json::array({Json::object({{"type", "string"}}), Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}})})}, {"description", "Bake only this patch (assets/audio/jump.sfx.json) or this list of patches, not every patch of the project."}})},
                                                             {"macros", Json::object({{"type", "object"}, {"additionalProperties", number("Knob position.", -1, 1)}, {"description", "Macro values for every sound rendered by this call, e.g. {\"weight\": 0.4}. Forces the render and is kept in the recipes."}})},
                                                             {"dryRun", boolean("List what would be rendered and why, and write nothing.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_bake_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "sfx.tweak";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Turn a patch's macros by meaning (brighter, longer tail, heavier) and write the change back to the patch.";
        info.description =
            "`macros` is {name: amount}: attack, brightness, weight, tail, pitch, grit (each from -1 to 1; 0 is the patch as written) or a macro the patch declares. Each amount is ADDED to the value "
            "the patch declares now (+0.2 brighter than it is), or is the new value when `absolute` is true; the result is clamped to -1..1 and written to the patch's `macros` (the file is rewritten with the "
            "same keys in the same order). Then the sound (and its variations) is rendered again and the result compares the measurements before and after: centroidHz rises with brightness, seconds with tail, "
            "riseSeconds with a slower attack. An unknown macro is an error with a 'did you mean'. Example: {\"path\":\"assets/audio/coin.sfx.json\",\"macros\":{\"brightness\":0.2}}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"required", Json::array({"path", "macros"})},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"path", str("The sound patch, project-relative, ending in .sfx.json.")},
                                                             {"macros", Json::object({{"type", "object"}, {"additionalProperties", number("Amount to add (or the new value with absolute).", -2, 2)}, {"description", "Macro name to amount, e.g. {\"brightness\": 0.2, \"tail\": -0.3}."}})},
                                                             {"absolute", boolean("Set the macros to these values instead of adding to the declared ones.", false)},
                                                             {"render", boolean("Render the sound again and compare the measurements. Turn it off to only edit the patch.", true)},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Seed of the renders (default 0)."}})},
                                                             {"picture", boolean("Return the spectrogram picture (`$image`).", true)},
                                                             {"pictureOut", str("Also keep the picture's PNG at this project path (ends in .png).")},
                                                             {"width", Json::object({{"type", "integer"}, {"minimum", 400}, {"maximum", 2400}, {"description", "Width of the picture in pixels."}})},
                                                             {"height", Json::object({{"type", "integer"}, {"minimum", 280}, {"maximum", 1600}, {"description", "Height of the picture in pixels."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_tweak_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "sfx.edit";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Change one field of a sound patch by JSON pointer (set, remove, add to an array, move inside an array); the result must still be a valid patch.";
        info.description =
            "Edits `*.sfx.json` the way a hand edit would, but checked: the patch is parsed again after the change and, when it would be invalid, nothing is written and the error lists the issues with their pointers. "
            "op `set` writes `value` at `pointer` (an existing object's field, new or old); `remove` deletes the field or array element at `pointer`; `add` inserts `value` into the array at `pointer` "
            "(at `index`, default the end); `move` takes element `index` of the array at `pointer` to place `to`. Nothing is rendered: call sfx.render or sfx.bake afterwards. "
            "Example: {\"path\":\"assets/audio/coin.sfx.json\",\"op\":\"set\",\"pointer\":\"/oscillators/0/wave\",\"value\":\"square\"}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"required", Json::array({"path", "op", "pointer"})},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"path", str("The sound patch, project-relative, ending in .sfx.json.")},
                                                             {"op", Json::object({{"type", "string"}, {"enum", Json::array({"set", "remove", "add", "move"})}, {"description", "What to do."}})},
                                                             {"pointer", str("JSON pointer into the patch, e.g. /oscillators/0/wave or /effects.")},
                                                             {"value", Json::object({{"description", "The new value (set) or the element to insert (add). Any JSON."}})},
                                                             {"index", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "add: where to insert; move: the element to move."}})},
                                                             {"to", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "move: the element's new place."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_edit_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "sfx.family";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Make a consistent set of interface sounds (click, hover, confirm, cancel, error, open, close, notify) from one base patch.";
        info.description =
            "Writes one patch per sound into the `out` directory (default: the base's path without .sfx.json plus _family), each a COPY of the base patch `from` with what that role changes: its length and tail, "
            "macros (brighter for a hover, heavier and gritty for an error), an arpeggio (confirm goes up, cancel down) or a pitch slide (open up, close down). They share the base's oscillators, filters, effects and "
            "master.normalize, so they share timbre and loudness; being copies they stand alone (editing the base later does not change them; make the family again with overwrite: true). Names: click, hover, "
            "confirm, cancel, error, open, close, notify; `preset: \"ui\"` makes all eight. Unless `render` is false each is baked to name.wav with a recipe (so sfx.bake keeps them current). The result lists the "
            "measurements of each (lufs, peakDb, seconds, centroidHz), the spread of loudness in LU, and one picture with a row per sound. "
            "Example: {\"from\":\"assets/audio/ui.sfx.json\",\"preset\":\"ui\"}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"required", Json::array({"from"})},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"from", str("The base patch, project-relative, ending in .sfx.json: the timbre every sound shares.")},
                                                             {"names", Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}, {"description", "Which sounds to make: click, hover, confirm, cancel, error, open, close, notify."}})},
                                                             {"preset", str("\"ui\": make all eight sounds. Give this or `names`.")},
                                                             {"out", str("Directory under assets/ for the patches (and their sounds). Default: the base's path without .sfx.json plus _family.")},
                                                             {"overwrite", boolean("Replace patches and sounds that exist.", false)},
                                                             {"render", boolean("Bake each sound to a WAV too (default); false writes only the patches and measures them in memory.", true)},
                                                             {"picture", boolean("Return the contact sheet (`$image`): one row per sound.", true)},
                                                             {"pictureOut", str("Also keep the sheet's PNG at this project path (ends in .png).")},
                                                             {"width", Json::object({{"type", "integer"}, {"minimum", 400}, {"maximum", 2400}, {"description", "Width of the picture in pixels (default 1000)."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_family_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "sfx.preset";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "List the sound presets, return one as an editable patch, or write it to a *.sfx.json file.";
        info.description =
            "The presets of assets.synth_sound (bark, growl, meow, screech, whoosh, explosion, hit, coin, pickup, jump, powerup, laser, blip, click, error, splash, footstep) are sound patches shipped "
            "in the engine. Without `name` this lists them. With `name` it returns the patch (the exact JSON that renders): read it to learn the format, or change it. With `name` and `path` it writes "
            "the patch to that *.sfx.json file under assets/ (an existing file is an error unless overwrite is true), ready for sfx.render. "
            "Example: {\"name\":\"laser\",\"path\":\"assets/audio/laser.sfx.json\"}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"name", str("The preset to return. Leave out to list them all.")},
                                                             {"path", str("Write the patch here: project-relative, under assets/, ending in .sfx.json.")},
                                                             {"overwrite", boolean("Replace the file when it exists.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_preset_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "sfx.info";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Check a sound patch and say what it holds and how loud it renders, without writing anything.";
        info.description =
            "Reads a sound patch from `path`, or takes it inline as `patch` (JSON) or by `preset` name, and checks it against the format (docs/SOUND.md). A patch with mistakes returns valid false and "
            "ALL its issues, each with the JSON pointer, what is wrong and how to fix it, so one call is enough to repair it. A valid patch returns its layers (oscillators, start, pitch), its "
            "effects, the base pitch (rootHz), its macros (the declared values) and variations (count and the files they bake to), whether its baked sound exists and is stale, and the loudness, peak, length, "
            "brightness (centroidHz) and attack (riseSeconds) it renders to (it is rendered in memory; nothing is written). "
            "Example: {\"path\":\"assets/audio/coin.sfx.json\"}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"path", str("A sound patch file, project-relative, ending in .sfx.json.")},
                                                             {"patch", Json::object({{"type", "object"}, {"description", "The patch itself, as JSON, to check before writing it to a file."}})},
                                                             {"preset", str("The name of a preset (see sfx.preset).")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Render this take for the measurements (default 0)."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_info_command(projectDir, args.is_null() ? Json::object() : args); });
    }
}

}  // namespace fa::assets_detail
