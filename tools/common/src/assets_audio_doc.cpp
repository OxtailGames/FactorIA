// audio.info, audio.render, audio.bake, audio.create and audio.edit: audio documents (`*.audio.json`, docs/SOUND.md "Audio documents") as
// project files. The format and the renderer are fa_audio's (fa/audio/audio_doc.h); baking and its recipe are audio_doc_bake.cpp.
#include <algorithm>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "audio_mix.h"
#include "fa/audio/audio_doc.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/audio_doc.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json integer(const char* what, int lo, int hi) { return Json::object({{"type", "integer"}, {"minimum", lo}, {"maximum", hi}, {"description", what}}); }
Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }
Json object_arg(const char* what) { return Json::object({{"type", "object"}, {"description", what}}); }

std::string doc_path(const std::string& arg, const char* what = "path") {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("`") + what + "` '" + arg + "' is not an audio document under assets/.", "Audio documents live in assets/, e.g. \"assets/audio/door.audio.json\" (audio.create writes one).");
    if (!ends_with(to_lower(*norm), kAudioDocSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .audio.json.", "Name audio documents <name>.audio.json, e.g. \"assets/audio/door.audio.json\".");
    return *norm;
}

Json issues_json(const std::vector<AudioDocIssue>& issues) {
    Json list = Json::array();
    for (const AudioDocIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

struct Loaded {
    std::string rel;
    Json json;
    AudioDoc doc;
};

[[noreturn]] void invalid_document(const std::string& rel, const Result<AudioDoc>& r, const std::vector<AudioDocIssue>& issues) {
    throw CommandError("invalid_document", r.error().message, r.error().hint.empty() ? "schemas/audio.schema.json describes the format; audio.info lists the steps." : r.error().hint,
                       Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
}

Json read_json_file(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = list_audio_documents(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with audio.create {\"path\":\"" + rel + "\",\"source\":\"assets/raw/sound.wav\"}." : did_you_mean(rel, all) + " Audio documents: " + join(all, ", ") + ".");
    }
    auto json = parse_json(*text, rel);
    if (!json.ok()) fail("invalid_document", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/audio.schema.json describes the format." : json.error().hint);
    return std::move(*json);
}

Loaded load_document(const std::string& projectDir, const std::string& rel) {
    Loaded out;
    out.rel = rel;
    out.json = read_json_file(projectDir, rel);
    std::vector<AudioDocIssue> issues;
    auto doc = parse_audio_doc(out.json, rel, &issues);
    if (!doc.ok()) invalid_document(rel, doc, issues);
    out.doc = std::move(*doc);
    return out;
}

Json measurements_json(const AudioClip& clip) {
    SfxAudio mono;
    mono.sampleRate = clip.sampleRate;
    mono.samples = clip.mono();
    Json m = Json::object({{"seconds", round_to(clip.seconds(), 3)}, {"lufs", round_to(clip.lufs, 1)}, {"peakDb", round_to(clip.peakDb, 1)}, {"sampleRate", clip.sampleRate},
                           {"channels", clip.channels}, {"centroidHz", round_to(sfx_centroid_hz(mono), 0)}});
    if (clip.loop)
        m["loop"] = Json::object({{"startSeconds", round_to(double(clip.loop->start) / clip.sampleRate, 4)}, {"endSeconds", round_to(double(clip.loop->end) / clip.sampleRate, 4)}});
    return m;
}

Json steps_report(const AudioDoc& doc, const AudioClip& clip) {
    Json list = Json::array();
    for (std::size_t i = 0; i < clip.steps.size(); ++i) {
        const AudioStepReport& s = clip.steps[i];
        Json item = Json::object({{"index", i}, {"type", s.type}, {"seconds", round_to(s.seconds, 3)}, {"peakDb", round_to(s.peakDb, 1)}});
        if (s.skipped) item["skipped"] = true;
        list.push_back(item);
    }
    (void)doc;
    return list;
}

AudioClip render_or_fail(const std::string& projectDir, const AudioDoc& doc, const std::string& rel, const AudioRenderOptions& options = {}) {
    ProjectRootGuard root(projectDir);
    auto clip = render_audio_doc(doc, rel, options);
    if (!clip.ok()) fail("failed", clip.error().message, clip.error().hint);
    return std::move(*clip);
}

audio_mix::SheetRow sheet_row(const std::string& label, const AudioClip& clip) {
    audio_mix::SheetRow row;
    row.label = label;
    SfxAudio mono;
    mono.sampleRate = clip.sampleRate;
    mono.samples = clip.mono();
    row.note = std::format("{:.1f} LUFS  {:.2f} s  {:.0f} Hz", clip.lufs, clip.seconds(), sfx_centroid_hz(mono));
    row.samples = std::move(mono.samples);
    row.rate = clip.sampleRate;
    return row;
}

Json bake_json(const AudioBakeStatus& s) { return Json::object({{"state", audio_bake_state_name(s.state)}, {"output", s.output}, {"reason", s.reason}}); }

void check_seed(const char* command, const Json& a, AudioRenderOptions& options) {
    if (!a.contains("seed")) return;
    if (!a["seed"].is_number_integer() || a["seed"].get<long long>() < 0)
        fail("invalid_argument", std::string(command) + ": `seed` must be a whole number, 0 or more.", "It replaces the document's seed for this render: another take of every random step (granular, an .sfx.json source).");
    options.seed = a["seed"].get<std::uint64_t>();
}

// The document as the arguments give it: a file (`path`) or an inline `document` to check before writing.
Loaded document_arg(const char* command, const std::string& projectDir, const Json& a, bool& inlineDoc) {
    inlineDoc = false;
    const bool hasPath = a.contains("path"), hasDoc = a.contains("document");
    if (hasPath == hasDoc) fail("invalid_argument", std::string(command) + (hasPath ? ": give `path` or `document`, not both." : ": give `path` (an .audio.json file) or `document` (the JSON itself)."), "Example: {\"path\":\"assets/audio/door.audio.json\"}.");
    if (hasPath) return load_document(projectDir, doc_path(tooling_detail::arg_string(a, "path", true)));
    Loaded out;
    out.rel = "";
    if (!a["document"].is_object()) fail("invalid_argument", std::string(command) + ": `document` must be an object.", "Start from {\"format\":\"factoria.audio/1\",\"source\":\"assets/raw/door.wav\",\"steps\":[]}.");
    out.json = a["document"];
    if (!out.json.contains("format")) out.json["format"] = kAudioDocFormat;
    std::vector<AudioDocIssue> issues;
    auto doc = parse_audio_doc(out.json, "document", &issues);
    if (!doc.ok()) invalid_document("", doc, issues);
    out.doc = std::move(*doc);
    inlineDoc = true;
    return out;
}

// ---- audio.info ----

Json step_catalog() {
    Json list = Json::array();
    for (const AudioStepInfo& s : audio_step_types()) {
        Json fields = Json::array();
        for (const AudioFieldInfo& f : s.fields) {
            Json item = Json::object({{"key", f.key}, {"type", f.type}, {"doc", f.doc}});
            if (f.required) item["required"] = true;
            if (f.min) item["min"] = *f.min;
            if (f.max) item["max"] = *f.max;
            if (f.def) item["default"] = *f.def;
            if (!f.choices.empty()) item["choices"] = f.choices;
            fields.push_back(item);
        }
        list.push_back(Json::object({{"type", s.type}, {"doc", s.doc}, {"fields", fields}}));
    }
    return list;
}

Json audio_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("audio.info", a, "", {"path", "document", "seed", "render"});
    if (!a.contains("path") && !a.contains("document")) {
        return Json::object({{"steps", step_catalog()},
                             {"nextSteps", Json::array({"audio.create {\"path\":\"assets/audio/door.audio.json\",\"source\":\"assets/raw/door.wav\",\"steps\":[{\"type\":\"trim\",\"auto\":true},{\"type\":\"normalize\",\"target\":-3}]} writes a document and bakes it.",
                                                        "audio.info {\"path\":...} checks a document and says what it renders to."})}});
    }
    bool inlineDoc = false;
    Json result = Json::object();
    Loaded loaded;
    try {
        loaded = document_arg("audio.info", projectDir, a, inlineDoc);
    } catch (const CommandError& e) {
        if (e.code != "invalid_document") throw;
        Json r = Json::object({{"valid", false}, {"issues", e.data.value("issues", Json::array())}});
        if (e.data.contains("path") && !e.data["path"].get<std::string>().empty()) r["path"] = e.data["path"];
        r["nextSteps"] = Json::array({"Fix every issue (each has its JSON pointer and a hint), then call audio.info again. audio.info {} lists the steps and their fields."});
        return r;
    }
    result["valid"] = true;
    if (!inlineDoc) result["path"] = loaded.rel;
    result["source"] = loaded.doc.source.path;
    result["seed"] = loaded.doc.seed;
    result["output"] = Json::object({{"format", loaded.doc.output.format}, {"channels", loaded.doc.output.channels}, {"quality", loaded.doc.output.quality},
                                     {"path", audio_document_output(loaded.doc, loaded.rel.empty() ? "document.audio.json" : loaded.rel)}});
    Json steps = Json::array();
    for (std::size_t i = 0; i < loaded.doc.steps.size(); ++i) {
        Json p = loaded.doc.steps[i].params;
        steps.push_back(Json::object({{"index", i}, {"type", loaded.doc.steps[i].type}, {"params", p}}));
    }
    result["steps"] = steps;
    if (!inlineDoc) result["bake"] = bake_json(audio_bake_status(projectDir, loaded.rel));
    if (tooling_detail::arg_bool(a, "render", true)) {
        AudioRenderOptions options;
        check_seed("audio.info", a, options);
        const AudioClip clip = render_or_fail(projectDir, loaded.doc, loaded.rel, options);
        result["measurements"] = measurements_json(clip);
        result["stepResults"] = steps_report(loaded.doc, clip);
        Json inputs = Json::array();
        for (const std::string& i : clip.inputs) inputs.push_back(i);
        result["inputs"] = inputs;
    }
    result["nextSteps"] = Json::array({"audio.render shows the waveform and spectrogram; audio.edit adds, changes or removes a step; audio.bake writes the sound."});
    return result;
}

// ---- audio.render ----

Json audio_render_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("audio.render", a, "", {"path", "document", "seed", "stopAfter", "compare", "picture", "pictureOut", "width"});
    // A kept picture is a file the caller names: refuse it before the render (writeProject, inside the project).
    if (tooling_detail::arg_bool(a, "picture", true)) check_kept_picture(projectDir, a, "audio.render");
    bool inlineDoc = false;
    const Loaded loaded = document_arg("audio.render", projectDir, a, inlineDoc);
    AudioRenderOptions options;
    check_seed("audio.render", a, options);
    if (a.contains("stopAfter")) {
        if (!a["stopAfter"].is_number_integer() || a["stopAfter"].get<int>() < 0 || std::size_t(a["stopAfter"].get<int>()) >= loaded.doc.steps.size())
            fail("invalid_argument", "audio.render: `stopAfter` must be the index of a step, 0 to " + std::to_string(loaded.doc.steps.empty() ? 0 : loaded.doc.steps.size() - 1) + ".",
                 "It renders only steps 0..stopAfter, to hear the chain up to that step; audio.info lists the steps with their indexes.");
        options.stopAfter = a["stopAfter"].get<int>();
    }
    const AudioClip clip = render_or_fail(projectDir, loaded.doc, loaded.rel, options);
    Json result = Json::object({{"measurements", measurements_json(clip)}, {"steps", steps_report(loaded.doc, clip)}});
    if (!inlineDoc) result["path"] = loaded.rel;
    if (tooling_detail::arg_bool(a, "picture", true)) {
        std::vector<audio_mix::SheetRow> rows;
        if (tooling_detail::arg_bool(a, "compare", true)) {
            AudioDoc plain = loaded.doc;
            plain.steps.clear();
            plain.output.channels = "mono";
            rows.push_back(sheet_row("source", render_or_fail(projectDir, plain, loaded.rel)));
        }
        rows.push_back(sheet_row(options.stopAfter >= 0 ? "after step " + std::to_string(options.stopAfter) : "result", clip));
        Json pic = audio_mix::spectrogram_sheet(projectDir, loaded.rel.empty() ? "audio document" : loaded.rel, rows, a.value("width", 1000), a.value("pictureOut", std::string()), "audio.render");
        if (pic.contains("$image")) result["$image"] = pic["$image"];
        if (pic.contains("picture")) result["picture"] = pic["picture"];
    }
    Json steps = Json::array();
    if (clip.peakDb > -0.5) steps.push_back(std::format("It peaks at {:.1f} dBFS: lower a gain or end the chain with {{\"type\":\"normalize\",\"target\":-1}}.", clip.peakDb));
    steps.push_back("No sound was written. audio.bake writes the sound next to the document (" + audio_document_output(loaded.doc, loaded.rel.empty() ? "document.audio.json" : loaded.rel) + ") with its recipe, so it is rebuilt when the source changes.");
    result["nextSteps"] = steps;
    return result;
}

// ---- audio.bake ----

Json baked_item(const AudioBakeResult& b, const std::string& reason) {
    Json item = Json::object({{"document", b.document}, {"out", b.output}, {"reason", reason}, {"bytes", b.bytes}});
    if (b.written) item["measurements"] = measurements_json(b.clip);
    return item;
}

Json audio_bake_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("audio.bake", a, "", {"path", "force", "dryRun", "overwrite"});
    const bool force = tooling_detail::arg_bool(a, "force", false), dryRun = tooling_detail::arg_bool(a, "dryRun", false), overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::vector<std::string> docs;
    const bool single = a.contains("path");
    if (single) docs.push_back(doc_path(tooling_detail::arg_string(a, "path", true)));
    else docs = list_audio_documents(projectDir);
    Json baked = Json::array(), unchanged = Json::array(), failed = Json::array();
    for (const std::string& rel : docs) {
        const AudioBakeStatus status = audio_bake_status(projectDir, rel);
        std::string reason = audio_bake_state_name(status.state);
        if (status.state == AudioBakeState::Fresh) {
            if (!force && !single) {
                unchanged.push_back(status.output);
                continue;
            }
            reason = "forced";
        }
        if (status.state == AudioBakeState::Broken) {
            if (single) fail("invalid_document", status.reason, status.hint);
            failed.push_back(Json::object({{"document", rel}, {"error", Json::object({{"message", status.reason}, {"hint", status.hint}})}}));
            continue;
        }
        if (dryRun) {
            baked.push_back(Json::object({{"document", rel}, {"out", status.output}, {"reason", reason}}));
            continue;
        }
        // `overwrite` is for one named document: a project-wide bake never replaces a file nothing made.
        auto b = bake_audio_document(projectDir, rel, {false, overwrite});
        if (!b.ok()) {
            if (single) fail("failed", b.error().message, b.error().hint);
            failed.push_back(Json::object({{"document", rel}, {"out", status.output}, {"error", Json::object({{"message", b.error().message}, {"hint", b.error().hint}})}}));
            continue;
        }
        baked.push_back(baked_item(*b, reason));
    }
    Json result = Json::object({{dryRun ? "wouldBake" : "baked", baked}, {"count", baked.size()}, {"unchanged", unchanged}});
    if (dryRun) result["dryRun"] = true;
    if (!failed.empty()) result["failed"] = failed;
    Json steps = Json::array();
    if (docs.empty()) steps.push_back("There are no audio documents yet: audio.create {\"path\":\"assets/audio/door.audio.json\",\"source\":\"assets/raw/door.wav\"} writes one.");
    if (!failed.empty()) steps.push_back("Fix the documents in `failed` (audio.info {\"path\":...} lists every issue with its JSON pointer) and call audio.bake again.");
    steps.push_back("audio.render {\"path\":...} shows the waveform and spectrogram of a document without writing anything.");
    result["nextSteps"] = steps;
    return result;
}

// ---- audio.create and audio.edit ----

// Writes `json` (already checked) to `rel` as canonical JSON.
void write_document(const std::string& projectDir, const std::string& rel, const Json& json) {
    std::string err;
    if (!tooling_detail::write_file(project_write_file(projectDir, rel), dump_json(json), &err)) fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
}

Json checked(const Json& json, const std::string& rel) {
    std::vector<AudioDocIssue> issues;
    auto doc = parse_audio_doc(json, rel, &issues);
    if (!doc.ok()) {
        Json data = Json::object({{"path", rel}, {"issues", issues_json(issues)}});
        throw CommandError("invalid_document", doc.error().message + " Nothing was written.", doc.error().hint, data);
    }
    return json;
}

Json written_result(const std::string& projectDir, const std::string& rel, const Json& json, bool bake, const Json& a) {
    const AudioDoc doc = *parse_audio_doc(json, rel);
    Json result = Json::object({{"path", rel}, {"output", audio_document_output(doc, rel)}, {"steps", doc.steps.size()}});
    if (bake) {
        auto b = bake_audio_document(projectDir, rel, {false, tooling_detail::arg_bool(a, "overwrite", false)});
        if (!b.ok()) {
            result["bake"] = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
            result["nextSteps"] = Json::array({"The document was written but could not be baked: " + b.error().message + " " + b.error().hint});
            return result;
        }
        result["bytes"] = b->bytes;
        result["measurements"] = measurements_json(b->clip);
        result["stepResults"] = steps_report(doc, b->clip);
        result["provenance"] = b->provenance;
    } else {
        result["bake"] = bake_json(audio_bake_status(projectDir, rel));
    }
    if (tooling_detail::arg_bool(a, "picture", false) && bake) {
        Json r = audio_render_command(projectDir, Json::object({{"path", rel}}));
        if (r.contains("$image")) result["$image"] = r["$image"];
    }
    result["nextSteps"] = Json::array({"audio.render {\"path\":\"" + rel + "\"} shows the waveform and spectrogram; audio.edit changes one step; the baked sound is rebuilt by audio.bake or factoria export."});
    return result;
}

Json audio_create_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("audio.create", a, "", {"path", "source", "steps", "seed", "output", "doc", "overwrite", "bake"});
    const std::string rel = doc_path(tooling_detail::arg_string(a, "path", true));
    const std::string source = tooling_detail::arg_string(a, "source", true);
    (void)project_write_file(projectDir, rel);  // refuse a path outside the project before anything else
    std::error_code ec;
    if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(project_file(projectDir, rel), ec))
        fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or change its steps with audio.edit.");
    Json json = Json::object({{"format", kAudioDocFormat}});
    if (a.contains("doc")) json["doc"] = a["doc"];
    json["source"] = source;
    if (a.contains("seed")) json["seed"] = a["seed"];
    if (a.contains("output")) json["output"] = a["output"];
    json["steps"] = a.contains("steps") ? a["steps"] : Json::array();
    checked(json, rel);
    require_usable_manifest(projectDir);
    write_document(projectDir, rel, json);
    return written_result(projectDir, rel, json, tooling_detail::arg_bool(a, "bake", true), a);
}

Json audio_edit_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("audio.edit", a, "", {"path", "op", "index", "step", "values", "to", "source", "seed", "output", "bake", "picture", "overwrite"});
    const std::string rel = doc_path(tooling_detail::arg_string(a, "path", true));
    (void)project_write_file(projectDir, rel);
    const std::string op = tooling_detail::arg_string(a, "op", false, "");
    const std::vector<std::string> ops = {"add", "set", "remove", "move", "document"};
    if (std::find(ops.begin(), ops.end(), op) == ops.end())
        fail("invalid_argument", "audio.edit: `op` must be one of " + join(ops, ", ") + (op.empty() ? "." : ", got '" + op + "'. " + did_you_mean(op, ops)),
             "add inserts a step (`step`, at `index`, default the end); set changes fields of step `index` (`values`; a null value removes the field); remove deletes step `index`; move takes step `index` to position `to`; document changes `source`, `seed` or `output`.");
    Json json = read_json_file(projectDir, rel);
    if (!json.is_object()) fail("invalid_document", rel + ": the document is not an object.", "Fix it by hand or write it again with audio.create overwrite: true.");
    if (!json.contains("steps") || !json["steps"].is_array()) json["steps"] = Json::array();
    Json& steps = json["steps"];
    const long long count = (long long)steps.size();
    auto index_arg = [&](bool allowEnd) -> long long {
        if (!a.contains("index") || !a["index"].is_number_integer())
            fail("invalid_argument", "audio.edit " + op + ": `index` (a whole number) is required.", "Steps are numbered from 0; audio.info lists them.");
        const long long i = a["index"].get<long long>();
        if (i < 0 || i > (allowEnd ? count : count - 1))
            fail("invalid_argument", "audio.edit " + op + ": `index` " + std::to_string(i) + " is outside the " + std::to_string(count) + " step" + (count == 1 ? "" : "s") + " of " + rel + ".", count == 0 ? "The document has no steps yet: use op \"add\"." : "Use 0 to " + std::to_string(allowEnd ? count : count - 1) + ".");
        return i;
    };
    Json what = Json::object({{"op", op}});
    if (op == "add") {
        if (!a.contains("step") || !a["step"].is_object()) fail("invalid_argument", "audio.edit add: `step` must be an object such as {\"type\":\"fade\",\"out\":0.05}.", "audio.info {} lists the step types and their fields.");
        const long long at = a.contains("index") ? index_arg(true) : count;
        steps.insert(steps.begin() + at, a["step"]);
        what["index"] = at;
    } else if (op == "set") {
        const long long i = index_arg(false);
        if (!a.contains("values") || !a["values"].is_object() || a["values"].empty())
            fail("invalid_argument", "audio.edit set: `values` must say what to change, e.g. {\"semitones\": 3}.", "A null value removes the field (back to its default). The step's type cannot be changed: remove it and add another.");
        if (a["values"].contains("type") && a["values"]["type"] != steps[std::size_t(i)].value("type", Json()))
            fail("invalid_argument", "audio.edit set: the type of a step cannot be changed.", "Remove step " + std::to_string(i) + " and add the one you want at the same index.");
        for (auto it = a["values"].begin(); it != a["values"].end(); ++it) {
            if (it.value().is_null()) steps[std::size_t(i)].erase(it.key());
            else steps[std::size_t(i)][it.key()] = it.value();
        }
        what["index"] = i;
    } else if (op == "remove") {
        const long long i = index_arg(false);
        what["removed"] = steps[std::size_t(i)].value("type", std::string());
        steps.erase(steps.begin() + i);
        what["index"] = i;
    } else if (op == "move") {
        const long long i = index_arg(false);
        if (!a.contains("to") || !a["to"].is_number_integer() || a["to"].get<long long>() < 0 || a["to"].get<long long>() >= count)
            fail("invalid_argument", "audio.edit move: `to` must be a position from 0 to " + std::to_string(count - 1) + ".", "The step lands at that index; the others shift.");
        Json step = steps[std::size_t(i)];
        steps.erase(steps.begin() + i);
        steps.insert(steps.begin() + a["to"].get<long long>(), step);
        what["index"] = i;
        what["to"] = a["to"];
    } else {
        bool any = false;
        for (const char* key : {"source", "seed", "output"})
            if (a.contains(key)) {
                json[key] = a[key];
                any = true;
            }
        if (!any) fail("invalid_argument", "audio.edit document: give `source`, `seed` or `output`.", "Example: {\"op\":\"document\",\"output\":{\"format\":\"ogg\",\"quality\":0.6}}.");
    }
    checked(json, rel);
    require_usable_manifest(projectDir);
    write_document(projectDir, rel, json);
    Json result = written_result(projectDir, rel, json, tooling_detail::arg_bool(a, "bake", true), a);
    result["edit"] = what;
    return result;
}

}  // namespace

void register_audio_doc_commands(CommandRegistry& registry, const std::string& projectDir) {
    auto pathArg = [] { return str("The audio document, project-relative, under assets/, ending in .audio.json."); };
    {
        CommandInfo info;
        info.name = "audio.info";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Check an audio document and say what its chain renders to; with no arguments, list the step types and their fields.";
        info.description =
            "An audio document (`*.audio.json`, docs/SOUND.md \"Audio documents\") is a non-destructive chain over a sound: a WAV/OGG, an .sfx.json patch or another audio document, then steps (trim, fade, "
            "normalize, gain, pitch, stretch, speed, eq, filter, compressor, distortion, bitcrush, reverb, delay, reverse, layer, loop, granular). With `path` (or an inline `document`) this checks it: a document with mistakes returns valid false "
            "and ALL its issues, each with the JSON pointer, what is wrong and the fix; a valid one returns its steps, where it bakes to and whether that sound is fresh or stale, and (unless render is false) "
            "renders it in memory: seconds, loudness, peak, brightness (centroidHz), the loop points of a loop step and the length and peak after each step. With no argument it returns the catalog of step types with every field, "
            "its range, default and doc string. Example: {\"path\":\"assets/audio/door.audio.json\"}";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()}, {"document", object_arg("The document itself, as JSON, to check before writing it to a file (format is filled in).")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Render this take (replaces the document's seed)."}})},
                                                             {"render", boolean("Render the chain in memory for the measurements. Turn it off to only check it.", true)}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        registry.add(info, [projectDir](const Json& args) { return audio_info_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "audio.render";
        info.category = "assets";
        info.summary = "Render an audio document in memory: measurements, what each step did, and a waveform/spectrogram picture. Writes no sound.";
        info.description =
            "Applies the chain of the document (`path`, or an inline `document`) and returns the measurements (seconds, integrated loudness in LUFS, peak in dBFS, centroidHz, loop points), "
            "the length and peak after every step, and a picture (`$image`): the source and the result, each as a waveform over a spectrogram with its numbers, on one time and level scale. "
            "`stopAfter` renders only steps 0..stopAfter to hear the chain up to a step; `seed` takes another take of the random steps. The same document and files always render the same samples. "
            "Example: {\"path\":\"assets/audio/door.audio.json\",\"stopAfter\":2}";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()}, {"document", object_arg("The document itself, as JSON, instead of `path`.")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Replaces the document's seed for this render."}})},
                                                             {"stopAfter", integer("Render only steps 0..stopAfter.", 0, 63)},
                                                             {"compare", boolean("Show the unprocessed source above the result in the picture.", true)},
                                                             {"picture", boolean("Return the picture (`$image`).", true)},
                                                             {"pictureOut", path_property("write", "Also keep the picture's PNG at this project path (ends in .png; needs the writeProject capability). Without it the picture is a temporary screenshot.")},
                                                             {"width", integer("Width of the picture in pixels (default 1000).", 400, 2400)}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        registry.add(info, [projectDir](const Json& args) { return audio_render_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "audio.bake";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Render audio documents to WAV/OGG files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.";
        info.description =
            "Without `path` this bakes every *.audio.json of the project whose sound is missing or out of date (its document or a file it reads changed: the recipe's hashes), like sfx.bake. With `path` it bakes that document. "
            "The sound goes to `output.path` of the document, else next to it as <name>.wav (or .ogg); assets.json records provenance (a CC0 license for synthesized sources; the license and author of the files it read otherwise) and the recipe, "
            "so assets.regenerate and project.validate know when it is stale. A `loop` step stores its points as the import settings loopStart/loopEnd of the output, which a looping AudioSource honours. A file that nothing baked is never replaced unless overwrite is true. "
            "`factoria export` bakes the stale documents first. Example: {} or {\"path\":\"assets/audio/door.audio.json\"}";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"path", str("Bake only this document (project-relative, ending in .audio.json). Leave out for every document.")},
                                                             {"force", boolean("Bake documents that are fresh too.", false)},
                                                             {"dryRun", boolean("List what would be baked and why, and write nothing.", false)},
                                                             {"overwrite", boolean("Replace a file at the output that no audio document baked.", false)}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        registry.add(info, [projectDir](const Json& args) { return audio_bake_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "audio.create";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Write a new audio document (a source and a chain of steps) and bake it.";
        info.description =
            "Writes `path` (*.audio.json under assets/) with the format, `source` (a project WAV/OGG/MP3, an .sfx.json patch or another .audio.json), the `steps` (list of step objects; audio.info {} lists the types and fields) and the "
            "optional `seed`, `output` ({format wav|ogg, channels source|mono, quality, path}) and `doc` note. The document is checked first: a mistake returns every issue and writes nothing. Then it is baked (unless bake is false) and the result "
            "holds the measurements. Example: {\"path\":\"assets/audio/door.audio.json\",\"source\":\"assets/raw/door.wav\",\"steps\":[{\"type\":\"trim\",\"auto\":true},{\"type\":\"fade\",\"out\":0.05},{\"type\":\"normalize\",\"target\":-3}]}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path", "source"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()}, {"source", str("The sound to start from: a project path ending in .wav/.ogg/.mp3/.qoa, .sfx.json or .audio.json.")},
                                                             {"steps", Json::object({{"type", "array"}, {"items", Json::object({{"type", "object"}})}, {"description", "The chain, in order. Each step is {\"type\": ..., fields}."}})},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Seed of the random steps."}})},
                                                             {"output", object_arg("{format: wav|ogg, channels: source|mono, quality: 0..1 (ogg), path: where to bake}.")},
                                                             {"doc", str("A note on what the sound is for.")},
                                                             {"overwrite", boolean("Replace the document when it exists (and the baked sound when nothing baked it).", false)},
                                                             {"bake", boolean("Bake the sound after writing.", true)}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        mark_paths(info.inputSchema, "read", {"source"});
        registry.add(info, [projectDir](const Json& args) { return audio_create_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "audio.edit";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Add, change, remove or move one step of an audio document (or change its source, seed or output), then bake it.";
        info.description =
            "`op` is one of: add (insert `step`, an object, at `index`, default the end), set (change the fields of step `index` with `values`; a null value removes a field), remove (delete step `index`), move (take step `index` to position `to`), "
            "document (change `source`, `seed` or `output`). The result document is checked as a whole before anything is written, so a bad value returns every issue with its JSON pointer and writes nothing; the file keeps the other steps as written. "
            "Then the sound is baked again (unless bake is false) and the measurements tell what the edit did. Example: {\"path\":\"assets/audio/door.audio.json\",\"op\":\"set\",\"index\":2,\"values\":{\"target\":-6}}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path", "op"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"op", Json::object({{"type", "string"}, {"enum", Json::array({"add", "set", "remove", "move", "document"})}, {"description", "What to do."}})},
                                                             {"index", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "The step to act on (add: where to insert it)."}})},
                                                             {"step", object_arg("add: the new step, {\"type\": ..., fields}.")},
                                                             {"values", object_arg("set: fields to change; null removes a field.")},
                                                             {"to", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "move: the new position."}})},
                                                             {"source", str("document: the new source.")},
                                                             {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "document: the new seed."}})},
                                                             {"output", object_arg("document: the new output settings.")},
                                                             {"bake", boolean("Bake the sound after writing.", true)},
                                                             {"picture", boolean("Return the waveform/spectrogram picture after baking.", false)},
                                                             {"overwrite", boolean("Replace a sound that no audio document baked.", false)}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        mark_paths(info.inputSchema, "read", {"source"});
        registry.add(info, [projectDir](const Json& args) { return audio_edit_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    // Capabilities (capability.h): the documents and the sounds they bake to are project files; audio.render keeps a picture only when asked.
    using namespace capability_sets;
    declare_command_capabilities(registry, {{"audio.info", reads()}, {"audio.render", changes_state()}, {"audio.bake", writes_project()},
                                            {"audio.create", writes_project()}, {"audio.edit", writes_project()}});
}

}  // namespace fa::assets_detail
