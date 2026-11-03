// sfx.render, sfx.bake, sfx.preset and sfx.info: sound patches (`*.sfx.json`, docs/SOUND.md) as project files. The synthesizer is
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
    return r;
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
Baked bake_patch(const std::string& projectDir, const LoadedPatch& loaded, const std::string& outRel, const RenderArgs& args, const Json& recipeArgs, bool overwrite) {
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

    auto audio = render_sfx(loaded.patch, args.options);
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
    const std::string notes = std::format("sound patch {}, {:.2f} s, seed {}", loaded.rel, audio->seconds(), args.seed);
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
    return Json::object({{"lufs", round_to(audio.lufs, 1)}, {"peakDb", round_to(audio.peakDb, 1)}, {"seconds", round_to(audio.seconds(), 3)}, {"sampleRate", audio.sampleRate}});
}

// ---- sfx.render ----

Json sfx_render_command(const std::string& projectDir, const Json& a) {
    check_arg_keys(kRender, a, "", {"path", "out", "seed", "freq", "note", "length", "tail", "picture", "pictureOut", "width", "height", "overwrite"});
    const std::string rel = patch_path(tooling_detail::arg_string(a, "path", true));
    const std::string outArg = tooling_detail::arg_string(a, "out", false);
    const std::string out = outArg.empty() ? default_out(rel) : outArg;
    const RenderArgs args = render_args(kRender, a);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const LoadedPatch loaded = load_patch(projectDir, rel);
    Baked baked = bake_patch(projectDir, loaded, out, args, recipe_args(a, {{"path", rel}, {"out", outArg.empty() ? Json() : Json(out)}, {"picture", Json()}, {"pictureOut", Json()}, {"width", Json()}, {"height", Json()}}), overwrite);

    Json result = Json::object({{"patch", rel}, {"path", baked.out}, {"bytes", baked.bytes}, {"seed", args.seed}, {"measurements", measurements_json(baked.audio)}, {"provenance", baked.provenance}});
    Json steps = Json::array();
    if (tooling_detail::arg_bool(a, "picture", true)) {
        Json picArgs = Json::object({{"path", baked.out}});
        for (const char* key : {"width", "height"})
            if (a.contains(key)) picArgs[key] = a[key];
        if (a.contains("pictureOut")) picArgs["out"] = a["pictureOut"];
        Json pic = audio_mix::spectrogram_picture(projectDir, picArgs);
        if (pic.contains("$image")) {
            result["$image"] = pic["$image"];
            pic.erase("$image");
        }
        pic.erase("nextSteps");
        pic.erase("path");
        result["analysis"] = pic;  // the numbers of the file as written: integratedLufs, truePeakDb, clippedSamples, dominantBand...
        steps.push_back("Read the picture: waveform on top, spectrogram (log frequency) in the middle, loudness at the bottom. Change a number in " + rel + " and call sfx.render again.");
    }
    if (baked.audio.peakDb > -0.5) steps.push_back("It peaks at " + std::format("{:.1f}", baked.audio.peakDb) + " dBFS: lower a layer `gain` or the master `normalize` target.");
    steps.push_back("Play it: audio.play(\"" + baked.out + "\") in a script, or an AudioSource \"clip\". Same patch, same seed, same bytes.");
    steps.push_back("After editing the patch, sfx.bake renders every patch whose sound is missing or out of date.");
    result["nextSteps"] = steps;
    return result;
}

// ---- sfx.bake ----

Json sfx_bake_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("sfx.bake", a, "", {"force", "dryRun"});
    const bool force = tooling_detail::arg_bool(a, "force", false), dryRun = tooling_detail::arg_bool(a, "dryRun", false);
    Json baked = Json::array(), unchanged = Json::array(), skipped = Json::array(), failed = Json::array();
    const std::vector<std::string> patches = list_patches(projectDir);
    std::string manifestText = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile).value_or(std::string());
    Json entries = Json::object();
    if (!manifestText.empty())
        if (auto parsed = parse_json(manifestText, assets::kManifestFile); parsed.ok() && parsed->is_object() && parsed->contains("assets") && (*parsed)["assets"].is_object()) entries = (*parsed)["assets"];
    for (const std::string& rel : patches) {
        const std::string out = default_out(rel);
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
        } else if (force) reason = "forced";
        else if (check_recipe(projectDir, recipe).stale()) reason = "stale";
        if (reason.empty()) {
            unchanged.push_back(rel);
            continue;
        }
        if (dryRun) {
            baked.push_back(Json::object({{"patch", rel}, {"out", out}, {"reason", reason}}));
            continue;
        }
        try {
            const LoadedPatch loaded = load_patch(projectDir, rel);
            // An existing recipe keeps its own arguments (seed, note, a .ogg out): the bake renders what it recorded.
            Json recipeArgs = ours ? recipe["args"] : Json::object({{"path", rel}});
            const RenderArgs args = render_args(kRender, recipeArgs);
            const std::string target = ours ? recipeArgs.value("out", out) : out;
            const Baked b = bake_patch(projectDir, loaded, target, args, recipeArgs, true);
            baked.push_back(Json::object({{"patch", rel}, {"out", b.out}, {"reason", reason}, {"measurements", measurements_json(b.audio)}}));
        } catch (const CommandError& e) {
            Json f = Json::object({{"patch", rel}, {"error", Json::object({{"code", e.code}, {"message", e.what()}, {"hint", e.hint}})}});
            if (e.data.is_object() && e.data.contains("issues")) f["error"]["issues"] = e.data["issues"];
            failed.push_back(f);
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
    if (!patch->macros.is_null() && !patch->macros.empty()) result["hasMacros"] = true;
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
            "Reads the sound patch at `path` (assets/.../name.sfx.json, format factoria.sfx/1: layers of oscillators with envelopes, pitch sweeps and arpeggios, filters, FM and ring modulation, "
            "distortion, bitcrush, delay and reverb; docs/SOUND.md and schemas/sfx.schema.json) and renders it to mono 16-bit WAV at `out` (default: the patch's path with .wav; a path ending in .ogg "
            "encodes Ogg Vorbis). No provider, no key, no other program: the same patch, `seed` and options give the same bytes on every platform. The sound is levelled to the patch's normalization "
            "(default -18 LUFS, peak under -1 dBFS). The file gets provenance and a recipe in assets.json whose input is the patch, so project.validate warns when the patch changed after the sound "
            "was made and assets.regenerate renders it again. A patch with mistakes fails with `invalid_patch` and every problem in data.issues (JSON pointer, what is wrong, how to fix it). "
            "The result has measurements (lufs, peakDb, seconds), the numbers of the file as written (`analysis`, from assets.spectrogram) and the picture (`$image`): waveform, spectrogram and loudness curve. "
            "Options that change one render without editing the patch: `seed` (another take of the noise), `freq` or `note` (transpose so the patch's base pitch becomes this), `length`, `tail`. "
            "An existing file that sfx.render did not make is an `exists` error unless overwrite is true. Example: {\"path\":\"assets/audio/coin.sfx.json\"}";
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
            "and a patch with mistakes is listed in `failed` with its issues while the others are still baked. An existing recipe keeps its own arguments (seed, note, an .ogg `out`). "
            "No pictures are returned; use sfx.render for one patch. Example: {\"dryRun\":true} lists what would be rendered.";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"force", boolean("Render every patch again, even when its sound is up to date.", false)},
                                                             {"dryRun", boolean("List what would be rendered and why, and write nothing.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return sfx_bake_command(projectDir, args.is_null() ? Json::object() : args); });
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
            "effects, the base pitch (rootHz), whether its baked sound exists and is stale, and the loudness, peak and length it renders to (it is rendered in memory; nothing is written). "
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
