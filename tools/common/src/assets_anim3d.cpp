// anim3d.* and ik3d.*: the 3D bone clips (`*.anim.json` with "format": "factoria.anim3d/1") of a skinned rig and the 3D IK solvers as project
// commands (docs/ANIMATION.md, "3D bone clips", "Generators", "Retargeting", "3D IK"). The formats and maths are fa_scene's (anim3d.h,
// anim3d_gen.h, anim3d_retarget.h, ik3d.h); this file reads and writes the project files, checks them with the loader's own rules and draws the
// filmstrip of anim3d.preview with the software renderer of model.preview (fa/tooling/model_view.h), so a clip can be SEEN without a window.
#include <algorithm>
#include <cmath>
#include <array>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "assets_shots.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/anim3d_gen.h"
#include "fa/scene/anim3d_retarget.h"
#include "fa/scene/animation.h"
#include "fa/scene/feel.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/ik3d.h"
#include "fa/scene/rig3d.h"
#include "fa/scene/skeleton.h"
#include "fa/tooling/anim3d_tools.h"
#include "fa/tooling/model_view.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/rig_bake.h"
#include "picture_canvas.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

using picture::Canvas;

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json str_prop(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json bool_prop(const char* what) { return Json::object({{"type", "boolean"}, {"description", what}}); }
Json num_prop(const char* what, double lo, double hi) {
    return Json::object({{"type", "number"}, {"minimum", lo}, {"maximum", hi}, {"description", what}});
}
Json obj_prop(const char* what) { return Json::object({{"type", "object"}, {"description", what}}); }

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

double number_arg(const char* command, const Json& a, const char* key, double def, double lo, double hi,
                  const char* hint) {
    if (!a.contains(key) || a[key].is_null()) return def;
    if (!a[key].is_number())
        fail("invalid_argument",
             std::string(command) + ": `" + key + "` must be a number, got " + describe_json_value(a[key]) + ".", hint);
    const double v = a[key].get<double>();
    if (!(v >= lo && v <= hi))
        fail("invalid_argument", std::format("{}: `{}` must be from {} to {}, got {}.", command, key, lo, hi, v), hint);
    return v;
}

// ---- files --------------------------------------------------------------------------------------------------------------------------------

constexpr const char* kClipSuffix = ".anim.json";

const char* const kClipHint =
    "Clip files end in .anim.json and live in the project, e.g. \"anim/hero_walk.anim.json\".";

Json issues_json(const std::vector<ClipIssue>& issues) {
    Json list = Json::array();
    for (const ClipIssue& i : issues)
        list.push_back(obj({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

std::string clip_path_arg(const char* command, const Json& a, const char* key) {
    if (!a.contains(key) || !a[key].is_string() || a[key].get<std::string>().empty())
        fail("invalid_argument", std::string(command) + ": give `" + key + "`, the clip file.", kClipHint);
    auto norm = fs::normalize_checked(a[key].get<std::string>());
    if (!norm.ok() || norm->empty())
        fail("invalid_argument",
             std::string(command) + ": `" + key + "` '" + a[key].get<std::string>() +
                 "' is not a path inside the project.",
             kClipHint);
    if (!ends_with(to_lower(*norm), kClipSuffix))
        fail("invalid_argument", std::string(command) + ": `" + key + "` '" + *norm + "' does not end in .anim.json.",
             kClipHint);
    return *norm;
}

std::vector<std::string> clip3d_files(const std::string& projectDir) {
    ProjectRootGuard root(projectDir);
    std::vector<std::string> out;
    for (const std::string& f : fs::list(".", true, ".json")) {
        if (!ends_with(to_lower(f), kClipSuffix)) continue;
        auto text = fs::read_text(f);
        if (!text.ok()) continue;
        auto json = parse_json(*text, f);
        if (json.ok() && is_anim3d_json(*json)) out.push_back(f);
    }
    std::sort(out.begin(), out.end());
    return out;
}

// The clip file as JSON.
Json read_clip_json(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = clip3d_files(projectDir);
        fail("not_found", "'" + rel + "' does not exist.",
             all.empty() ? "anim3d.generate makes a clip from a rig; anim3d.create writes an empty one."
                         : did_you_mean(rel, all) + " 3D clips: " + join(all, ", ") + ".");
    }
    auto json = parse_json(*text, rel);
    if (!json.ok())
        fail("invalid_document", json.error().message,
             json.error().hint.empty() ? "Fix the JSON syntax; schemas/anim3d.schema.json describes the format."
                                       : json.error().hint);
    if (!is_anim3d_json(*json))
        fail("invalid_argument",
             "'" + rel + "' is not a 3D bone clip (its `format` is not \"" + std::string(kAnim3DFormat) + "\").",
             "A 2D clip (\"factoria.anim/1\") is edited with the anim.* commands; anim3d.create writes a 3D one.");
    return std::move(*json);
}

std::shared_ptr<const Anim3DClip> parse_clip_or_fail(const Json& json, const std::string& rel) {
    std::vector<ClipIssue> issues;
    auto clip = parse_anim3d(json, rel, &issues);
    if (!clip.ok())
        throw CommandError("invalid_document", clip.error().message,
                           clip.error().hint.empty() ? "schemas/anim3d.schema.json describes the format."
                                                     : clip.error().hint,
                           obj({{"path", rel}, {"issues", issues_json(issues)}}));
    return *clip;
}

std::shared_ptr<const Anim3DClip> read_clip(const std::string& projectDir, const std::string& rel) {
    return parse_clip_or_fail(read_clip_json(projectDir, rel), rel);
}

void check_can_write(const char* command, const std::string& projectDir, const std::string& rel, bool overwrite) {
    std::error_code ec;
    (void)project_write_file(projectDir, rel);  // refused before any work: managed folders, links out of the project
    if (!overwrite && stdfs::exists(project_file(projectDir, rel), ec))
        fail("exists", std::string(command) + ": '" + rel + "' already exists.",
             "Pass overwrite: true to replace it, or choose another path.");
}

// Writes the clip and its record in assets.json. `made` is the provenance of a clip a command made again from a recipe (anim3d.generate,
// anim3d.retarget); null for every edit: the clip then keeps its record, minus the recipe (a stale hand edit must not be overwritten by
// assets.regenerate), and a clip without a record gets "original" (made by hand with the anim3d commands).
// Returns the provenance the clip had before (null when it had none): the undo puts it back. `exact` (anim3d.restore) sets the provenance to `made`
// as it is, null removing it, instead of the rules above.
Json write_clip_json(const std::string& projectDir, const std::string& rel, const Json& json,
                     const Json& made = nullptr, bool exact = false) {
    require_usable_manifest(
        projectDir);  // before any file changes: a broken assets.json must not leave a written clip and an error
    std::string err;
    if (!tooling_detail::write_file(project_write_file(projectDir, rel), dump_json(json), &err))
        fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
    clear_anim3d_cache();  // the next load reads the file again, whatever its modification time says
    ProjectRootGuard root(projectDir);
    Json previous = nullptr;
    auto r = assets::update_entry(rel, [&](Json& e) {
        if (e.contains("provenance") && e["provenance"].is_object()) previous = e["provenance"];
        if (exact) {
            if (made.is_object())
                e["provenance"] = made;
            else
                e.erase("provenance");
            return;
        }
        if (made.is_object()) {
            e["provenance"] = made;
            return;
        }
        if (e.contains("provenance") && e["provenance"].is_object()) {
            Json& p = e["provenance"];
            if (p.contains("recipe")) {
                p.erase("recipe");
                const std::string note = "Edited by hand with the anim3d commands after it was made; the recipe was "
                                         "removed so assets.regenerate does not overwrite the edit.";
                p["notes"] =
                    p.contains("notes") && p["notes"].is_string() ? p["notes"].get<std::string>() + " " + note : note;
            }
            return;
        }
        e["provenance"] = obj({{"origin", "original"},
                               {"ai", false},
                               {"kind", "anim3d"},
                               {"provider", "factoria anim3d"},
                               {"license", "CC0-1.0"},
                               {"author", "factoria"},
                               {"notes", "Keyed with the anim3d commands."},
                               {"date", assets::today()}});
    });
    if (!r.ok())
        fail("failed", "The clip '" + rel + "' was written, but assets.json was not updated: " + r.error().message,
             r.error().hint);
    return previous;
}

// The provenance of a clip anim3d.generate or anim3d.retarget made: the recipe holds the call and the SHA-256 of the rigs and the source clip.
Json made_clip_provenance(const std::string& projectDir, const char* command, Json recipeArgs,
                          const std::vector<std::string>& inputs, const std::string& notes) {
    return obj({{"origin", "original"},
                {"ai", false},
                {"kind", "anim3d"},
                {"provider", std::string("factoria ") + command},
                {"license", "CC0-1.0"},
                {"author", "factoria"},
                {"notes", notes},
                {"date", assets::today()},
                {"recipe", make_recipe(projectDir, command, std::move(recipeArgs), inputs)}});
}

// The clip file as it is now, or null when it does not exist or is not readable JSON: what anim3d.restore puts back.
Json clip_before(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) return nullptr;
    auto json = parse_json(*text, rel);
    return json.ok() ? *json : Json(nullptr);
}

// {command, args} that puts the clip back to `before` (null = the file did not exist: delete it). Every writing anim3d.* command returns it
// as `undo`, so an editor or an AI can step back; the result of calling it carries the undo that goes forward again.
// `provenance` is the record the clip had in assets.json (null = none), so the undo puts the recipe back too.
Json undo_restore(const std::string& rel, const Json& before, const Json& provenance) {
    return obj(
        {{"command", "anim3d.restore"}, {"args", obj({{"path", rel}, {"clip", before}, {"provenance", provenance}})}});
}

// ---- rigs ---------------------------------------------------------------------------------------------------------------------------------

// A baked rig loaded for a command: the skeleton is shared (cached by path), the Rig3D points into it.
struct RigHold {
    std::string path;  // the project-relative .glb
    std::shared_ptr<const SkeletonAsset> skeleton;
    Rig3D rig;
};

RigHold load_rig_arg(const char* command, const std::string& projectDir, const std::string& arg, const char* key) {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty())
        fail("invalid_argument",
             std::string(command) + ": `" + key + "` '" + arg + "' is not a path inside the project.",
             "A baked rig, e.g. \"assets/models/hero.rig.glb\", or its rig document \"assets/models/hero.rig.json\".");
    std::string glb = *norm;
    if (ends_with(to_lower(glb), kRigDocSuffix)) {
        std::vector<RigIssue> issues;
        auto doc = load_rig_document(projectDir, glb, &issues);
        if (!doc.ok()) fail("invalid_document", std::string(command) + ": " + doc.error().message, doc.error().hint);
        glb = rig_document_output(*doc, glb);
    }
    const std::string lower = to_lower(glb);
    if (!ends_with(lower, ".glb") && !ends_with(lower, ".gltf"))
        fail("invalid_argument", std::string(command) + ": `" + key + "` '" + glb + "' is not a skinned model.",
             "Give the .glb that rig.bake wrote (<name>.rig.glb), or the .rig.json that bakes it.");
    std::error_code ec;
    if (!stdfs::exists(project_file(projectDir, glb), ec)) {
        std::vector<std::string> all;
        {
            ProjectRootGuard root(projectDir);
            for (const std::string& f : fs::list(".", true, ".glb"))
                if (ends_with(to_lower(f), ".rig.glb")) all.push_back(f);
        }
        std::sort(all.begin(), all.end());
        fail("not_found", std::string(command) + ": '" + glb + "' does not exist.",
             all.empty() ? "rig.bake writes it from a rig document (rig.create makes both)."
                         : did_you_mean(glb, all) + " Baked rigs: " + join(all, ", ") + ".");
    }
    RigHold hold;
    hold.path = glb;
    {
        ProjectRootGuard root(projectDir);
        auto sk = load_skeleton(glb);
        if (!sk.ok()) fail("invalid_document", std::string(command) + ": " + sk.error().message, sk.error().hint);
        hold.skeleton = *sk;
    }
    if (hold.skeleton->skins.empty())
        fail("invalid_argument", std::string(command) + ": '" + glb + "' has no skin, so it has no bones to animate.",
             "Use the .glb that rig.bake wrote from a rig document.");
    hold.rig = make_rig3d(*hold.skeleton, 0);
    return hold;
}

RigHold rig_from_args(const char* command, const std::string& projectDir, const Json& a, const char* key = "rig") {
    if (!a.contains(key) || !a[key].is_string() || a[key].get<std::string>().empty())
        fail("invalid_argument",
             std::string(command) + ": give `" + key + "`, the baked rig (a .rig.glb or the .rig.json that bakes it).",
             "Example: {\"" + std::string(key) + "\":\"assets/models/hero.rig.glb\"}.");
    return load_rig_arg(command, projectDir, a[key].get<std::string>(), key);
}

std::string stem_of(const std::string& path) {
    const std::size_t slash = path.find_last_of('/');
    const std::string name = path.substr(slash == std::string::npos ? 0 : slash + 1);
    for (const char* suffix : {".rig.glb", ".rig.json", ".glb", ".gltf", ".anim.json"})
        if (ends_with(to_lower(name), suffix)) return name.substr(0, name.size() - std::string_view(suffix).size());
    return name;
}

Json bone_list(const Rig3D& rig) {
    Json list = Json::array();
    for (const std::string& n : rig.bone_names()) list.push_back(n);
    return list;
}

Json string_list(const std::vector<std::string>& v) {
    Json j = Json::array();
    for (const std::string& s : v) j.push_back(s);
    return j;
}

std::string join_numbers(const std::vector<double>& v) {
    std::string out;
    for (double d : v) out += (out.empty() ? "" : ", ") + std::format("{:.0f}", d);
    return out;
}

// ---- anim3d.generators / create / info ----------------------------------------------------------------------------------------------------

Json anim3d_generators_command(const Json& a) {
    check_arg_keys("anim3d.generators", a, "", {});
    Json r = Json::object();
    r["generators"] = anim3d_generator_catalog();
    r["nextSteps"] = Json::array({"anim3d.generate "
                                  "{\"rig\":\"assets/models/hero.rig.glb\",\"kind\":\"walk\",\"out\":\"anim/"
                                  "hero_walk.anim.json\"} writes one for a baked rig; `params` changes the stride, "
                                  "cadence, bounce... (the same call with the same params writes the same clip).",
                                  "anim3d.preview draws the result as a filmstrip."});
    return r;
}

Json clip_summary(const Anim3DClip& c) {
    std::set<std::string> bones;
    std::size_t keys = 0;
    for (const Anim3DTrack& t : c.tracks) {
        bones.insert(t.bone);
        keys += t.keys.size();
    }
    return obj({{"duration", round_to(c.duration, 4)},
                {"loop", c.loop},
                {"rotation", c.quat ? "quat" : "euler"},
                {"groundSpeed", round_to(c.groundSpeed, 4)},
                {"tracks", c.tracks.size()},
                {"bones", bones.size()},
                {"keys", keys},
                {"events", c.events.size()},
                {"contacts", c.contacts.size()}});
}

Json contact_list(const Anim3DClip& c) {
    Json list = Json::array();
    for (const Anim3DContact& k : c.contacts)
        list.push_back(obj({{"bone", k.bone}, {"from", round_to(k.from, 4)}, {"to", round_to(k.to, 4)}}));
    return list;
}

std::string animator_snippet(const std::string& clipName, const std::string& path, const std::string& rigPath) {
    return "On the entity that shows " + rigPath + ": Animator {\"model\":\"" + rigPath + "\",\"clips\":{\"" +
           clipName + "\":\"" + path + "\"},\"clip\":\"" + clipName + "\"}.";
}

Json anim3d_create_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.create", a, "", {"path", "duration", "loop", "rotation", "rig", "doc", "overwrite"});
    const std::string rel = clip_path_arg("anim3d.create", a, "path");
    const double duration =
        number_arg("anim3d.create", a, "duration", 1.0, 0.0, 3600.0, "The length of the clip in seconds, e.g. 0.8.");
    Json doc = obj({{"format", kAnim3DFormat}});
    if (a.contains("doc") && a["doc"].is_string()) doc["doc"] = a["doc"];
    std::string rotation = "euler";
    if (a.contains("rotation") && !a["rotation"].is_null()) {
        if (!a["rotation"].is_string() ||
            (a["rotation"].get<std::string>() != "euler" && a["rotation"].get<std::string>() != "quat"))
            fail("invalid_argument",
                 "anim3d.create: `rotation` is " + describe_json_value(a["rotation"]) + ", not \"euler\" or \"quat\".",
                 "\"euler\" keys are [pitch, yaw, roll] degrees, \"quat\" keys are [x, y, z, w].");
        rotation = a["rotation"].get<std::string>();
    }
    if (a.contains("rig") && !a["rig"].is_null()) {
        const RigHold rig = rig_from_args("anim3d.create", projectDir, a);
        doc["rig"] = rig.path;
        if (!rig.rig.templateName.empty()) doc["template"] = rig.rig.templateName;
    }
    doc["duration"] = duration;
    doc["loop"] = tooling_detail::arg_bool(a, "loop", true);
    if (rotation == "quat") doc["rotation"] = "quat";
    doc["tracks"] = Json::array();
    parse_clip_or_fail(doc, rel);
    check_can_write("anim3d.create", projectDir, rel, tooling_detail::arg_bool(a, "overwrite", false));
    const Json before = clip_before(projectDir, rel);
    const Json prevProv = write_clip_json(projectDir, rel, doc);
    Json r = obj({{"path", rel},
                  {"duration", duration},
                  {"loop", doc["loop"]},
                  {"rotation", rotation},
                  {"undo", undo_restore(rel, before, prevProv)}});
    r["nextSteps"] =
        Json::array({"anim3d.set_keys {\"path\":\"" + rel +
                         "\",\"bone\":\"spine_1\",\"keys\":[{\"t\":0,\"value\":[0,0,0]},{\"t\":0.5,\"value\":[10,0,0],"
                         "\"interp\":\"quadInOut\"}]} adds the keys of one bone (euler degrees: pitch, yaw, roll).",
                     "anim3d.generate writes a whole walk, run, idle, swing or hit clip from a rig instead."});
    return r;
}

Json anim3d_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.info", a, "", {"path", "rig"});
    if (!a.contains("path") || a["path"].is_null()) {
        Json files = Json::array();
        for (const std::string& f : clip3d_files(projectDir)) files.push_back(f);
        Json r = obj({{"clips", files}});
        r["nextSteps"] = Json::array(
            {files.empty() ? "No 3D clips yet: anim3d.generate {rig, kind, out} writes one."
                           : "anim3d.info {\"path\": <one of these>} lists its tracks, events and contacts."});
        return r;
    }
    const std::string rel = clip_path_arg("anim3d.info", a, "path");
    const auto clip = read_clip(projectDir, rel);
    Json tracks = Json::array();
    for (const Anim3DTrack& t : clip->tracks)
        tracks.push_back(obj({{"bone", t.bone},
                              {"channel", anim3d_channel_name(t.channel)},
                              {"keys", t.keys.size()},
                              {"first", round_to(t.keys.front().t, 4)},
                              {"last", round_to(t.keys.back().t, 4)}}));
    Json events = Json::array();
    for (const ClipEvent& e : clip->events) {
        Json ev = obj({{"t", round_to(e.t, 4)}, {"name", e.name}});
        if (!e.feel.empty()) ev["feel"] = Json(e.feel);
        events.push_back(std::move(ev));
    }
    Json r = clip_summary(*clip);
    r["path"] = rel;
    r["doc"] = clip->doc;
    r["rig"] = clip->rig;
    r["template"] = clip->templateName;
    r["trackList"] = tracks;
    r["eventList"] = events;
    r["contactList"] = contact_list(*clip);
    if (clip->generated.is_object()) r["generated"] = clip->generated;
    Json steps = Json::array();
    if (a.contains("rig") && !a["rig"].is_null()) {
        const RigHold rig = rig_from_args("anim3d.info", projectDir, a);
        const std::vector<ClipIssue> issues = check_anim3d_rig(*clip, rig.rig);
        r["rigCheck"] = obj({{"rig", rig.path}, {"ok", issues.empty()}, {"issues", issues_json(issues)}});
        if (!issues.empty())
            steps.push_back("The clip names bones " + rig.path + " lacks: anim3d.retarget {\"path\":\"" + rel +
                            "\",\"from\":\"" + (clip->rig.empty() ? std::string("<its rig>") : clip->rig) +
                            "\",\"to\":\"" + rig.path + "\",\"out\":...} carries it over by role.");
    } else {
        steps.push_back("Pass `rig` to check the bones of the clip against a baked rig.");
    }
    steps.push_back("anim3d.preview {\"path\":\"" + rel + "\",\"rig\":...} draws the clip.");
    r["nextSteps"] = steps;
    return r;
}

// ---- anim3d.set_keys / remove_track -------------------------------------------------------------------------------------------------------

constexpr double kTimeEps = 1e-4;

Anim3DChannel channel_arg(const char* command, const Json& a) {
    if (!a.contains("channel") || a["channel"].is_null()) return Anim3DChannel::Rotation;
    const std::vector<std::string> names = {"rotation", "translation", "scale"};
    if (!a["channel"].is_string() ||
        std::find(names.begin(), names.end(), a["channel"].get<std::string>()) == names.end())
        fail("invalid_argument",
             std::string(command) + ": `channel` is " + describe_json_value(a["channel"]) +
                 ", not one of rotation, translation, scale.",
             a["channel"].is_string()
                 ? did_you_mean(a["channel"].get<std::string>(), names)
                 : "rotation turns the bone, translation moves it (normally the root), scale multiplies its size.");
    const std::string c = a["channel"].get<std::string>();
    return c == "rotation"      ? Anim3DChannel::Rotation
           : c == "translation" ? Anim3DChannel::Translation
                                : Anim3DChannel::Scale;
}

// The index in doc["tracks"] of the track for (bone, channel), or -1.
int find_track_json(const Json& doc, const std::string& bone, Anim3DChannel channel) {
    if (!doc.contains("tracks") || !doc["tracks"].is_array()) return -1;
    for (std::size_t i = 0; i < doc["tracks"].size(); ++i) {
        const Json& t = doc["tracks"][i];
        const std::string c =
            t.contains("channel") && t["channel"].is_string() ? t["channel"].get<std::string>() : "rotation";
        if (t.contains("bone") && t["bone"] == bone && c == anim3d_channel_name(channel)) return int(i);
    }
    return -1;
}

Json anim3d_set_keys_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.set_keys", a, "", {"path", "bone", "channel", "keys", "duration", "rig"});
    const std::string rel = clip_path_arg("anim3d.set_keys", a, "path");
    if (!a.contains("bone") || !a["bone"].is_string() || a["bone"].get<std::string>().empty())
        fail("invalid_argument",
             "anim3d.set_keys: give `bone`, the canonical name of the bone (spine_1, thigh_l, root...).",
             "A baked rig names its bones like that; pass `rig` to check the name, or see rig.info for a template's "
             "bones.");
    const std::string bone = a["bone"].get<std::string>();
    const Anim3DChannel channel = channel_arg("anim3d.set_keys", a);
    if (!a.contains("keys") || !a["keys"].is_array() || a["keys"].empty())
        fail(
            "invalid_argument", "anim3d.set_keys: give `keys`, a list of {t, value, interp} (value is [x, y, z]).",
            "Example: \"keys\":[{\"t\":0,\"value\":[0,0,0]},{\"t\":0.5,\"value\":[20,0,0],\"interp\":\"quadInOut\"}].");
    Json doc = read_clip_json(projectDir, rel);
    const Json before = doc;
    if (a.contains("rig") && !a["rig"].is_null()) {
        const RigHold rig = rig_from_args("anim3d.set_keys", projectDir, a);
        if (rig.rig.find(bone) < 0)
            fail("invalid_argument", "anim3d.set_keys: the rig " + rig.path + " has no bone '" + bone + "'.",
                 did_you_mean(bone, rig.rig.bone_names()) + " Bones: " + join(rig.rig.bone_names(), ", ") + ".");
    }
    if (a.contains("duration") && !a["duration"].is_null())
        doc["duration"] =
            number_arg("anim3d.set_keys", a, "duration", 1.0, 0.0, 3600.0, "The length of the clip in seconds.");
    if (!doc.contains("tracks") || !doc["tracks"].is_array()) doc["tracks"] = Json::array();
    int index = find_track_json(doc, bone, channel);
    if (index < 0) {
        doc["tracks"].push_back(
            obj({{"bone", bone}, {"channel", anim3d_channel_name(channel)}, {"keys", Json::array()}}));
        index = int(doc["tracks"].size()) - 1;
    }
    Json& keys = doc["tracks"][std::size_t(index)]["keys"];
    int replaced = 0, added = 0;
    for (std::size_t i = 0; i < a["keys"].size(); ++i) {
        const Json& key = a["keys"][i];
        if (!key.is_object() || !key.contains("t") || !key["t"].is_number())
            fail("invalid_argument",
                 std::format("anim3d.set_keys: keys/{} must be an object with a numeric `t`, got {}.", i,
                             describe_json_value(key)),
                 "Example: {\"t\":0.25,\"value\":[10,0,0]}.");
        bool done = false;
        for (Json& old : keys)
            if (std::fabs(old["t"].get<double>() - key["t"].get<double>()) < kTimeEps) {
                old = key;
                ++replaced;
                done = true;
                break;
            }
        if (!done) {
            keys.push_back(key);
            ++added;
        }
    }
    std::stable_sort(keys.begin(), keys.end(),
                     [](const Json& x, const Json& y) { return x["t"].get<double>() < y["t"].get<double>(); });
    const auto clip = parse_clip_or_fail(doc, rel);  // a refused edit leaves the file as it was
    const Json prevProv = write_clip_json(projectDir, rel, anim3d_to_json(*clip));
    Json r = obj({{"path", rel},
                  {"bone", bone},
                  {"channel", anim3d_channel_name(channel)},
                  {"added", added},
                  {"replaced", replaced},
                  {"duration", round_to(clip->duration, 4)},
                  {"undo", undo_restore(rel, before, prevProv)}});
    for (const Anim3DTrack& t : clip->tracks)
        if (t.bone == bone && t.channel == channel) r["keys"] = t.keys.size();
    r["nextSteps"] = Json::array(
        {"anim3d.preview {\"path\":\"" + rel +
         "\",\"rig\":...} draws the clip as a filmstrip; keys at the same time as an existing one replace it."});
    return r;
}

Json anim3d_remove_track_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.remove_track", a, "", {"path", "bone", "channel"});
    const std::string rel = clip_path_arg("anim3d.remove_track", a, "path");
    if (!a.contains("bone") || !a["bone"].is_string() || a["bone"].get<std::string>().empty())
        fail("invalid_argument", "anim3d.remove_track: give `bone`, the bone whose track to remove.",
             "anim3d.info {path} lists the tracks of the clip.");
    const std::string bone = a["bone"].get<std::string>();
    const bool oneChannel = a.contains("channel") && !a["channel"].is_null();
    const Anim3DChannel channel = oneChannel ? channel_arg("anim3d.remove_track", a) : Anim3DChannel::Rotation;
    Json doc = read_clip_json(projectDir, rel);
    const Json before = doc;
    Json kept = Json::array();
    Json removed = Json::array();
    std::vector<std::string> existing;
    if (doc.contains("tracks") && doc["tracks"].is_array()) {
        for (const Json& t : doc["tracks"]) {
            const std::string c =
                t.contains("channel") && t["channel"].is_string() ? t["channel"].get<std::string>() : "rotation";
            const std::string b = t.contains("bone") && t["bone"].is_string() ? t["bone"].get<std::string>() : "";
            existing.push_back(b);
            if (b == bone && (!oneChannel || c == anim3d_channel_name(channel)))
                removed.push_back(c);
            else
                kept.push_back(t);
        }
    }
    if (removed.empty()) {
        std::sort(existing.begin(), existing.end());
        existing.erase(std::unique(existing.begin(), existing.end()), existing.end());
        fail("not_found",
             "anim3d.remove_track: '" + rel + "' has no track for '" + bone + "'" +
                 (oneChannel ? std::string(" (") + anim3d_channel_name(channel) + ")" : std::string()) + ".",
             existing.empty() ? "The clip has no tracks."
                              : did_you_mean(bone, existing) + " Bones with a track: " + join(existing, ", ") + ".");
    }
    doc["tracks"] = kept;
    const auto clip = parse_clip_or_fail(doc, rel);
    const Json prevProv = write_clip_json(projectDir, rel, anim3d_to_json(*clip));
    Json r = obj({{"path", rel},
                  {"bone", bone},
                  {"removed", removed},
                  {"tracks", clip->tracks.size()},
                  {"undo", undo_restore(rel, before, prevProv)}});
    r["nextSteps"] = Json::array({"anim3d.set_keys adds a track back."});
    return r;
}

// ---- undo, key references, the edit commands of the Animation panel ---------------------------------------------------------------------

Json round_floats(const std::array<float, 4>& v, int comps) {
    Json out = Json::array();
    for (int i = 0; i < comps; ++i) out.push_back(round_to(double(v[std::size_t(i)]), 5));
    return out;
}

// Checks the edited document with the loader's rules (a refused edit leaves the file as it was), writes it canonical and builds the result.
// `exactProvenance` (anim3d.restore only) sets the clip's record to that object, or removes it when null, instead of the usual rules.
Json commit_clip(const std::string& projectDir, const std::string& rel, const Json& before, const Json& edited,
                 Json extra = Json::object(), const Json* exactProvenance = nullptr) {
    const auto clip = parse_clip_or_fail(edited, rel);
    const Json prevProv =
        write_clip_json(projectDir, rel, anim3d_to_json(*clip), exactProvenance ? *exactProvenance : Json(nullptr),
                        exactProvenance != nullptr);
    Json r = clip_summary(*clip);
    r["path"] = rel;
    for (auto it = extra.begin(); it != extra.end(); ++it) r[it.key()] = *it;
    r["undo"] = undo_restore(rel, before, prevProv);
    return r;
}

// Sets (or adds) the key at time `t` of the (bone, channel) track in `doc`; interp "" keeps what an existing key has.
void put_key(Json& doc, const std::string& bone, Anim3DChannel channel, double t, const Json& value,
             const std::string& interp) {
    if (!doc.contains("tracks") || !doc["tracks"].is_array()) doc["tracks"] = Json::array();
    int index = find_track_json(doc, bone, channel);
    if (index < 0) {
        doc["tracks"].push_back(
            obj({{"bone", bone}, {"channel", anim3d_channel_name(channel)}, {"keys", Json::array()}}));
        index = int(doc["tracks"].size()) - 1;
    }
    Json& keys = doc["tracks"][std::size_t(index)]["keys"];
    bool done = false;
    for (Json& old : keys)
        if (std::fabs(old["t"].get<double>() - t) < kTimeEps) {
            old["value"] = value;
            old.erase("in");
            old.erase("out");
            if (!interp.empty()) old["interp"] = interp;
            done = true;
            break;
        }
    if (!done) {
        Json key = obj({{"t", t}, {"value", value}});
        if (!interp.empty()) key["interp"] = interp;
        keys.push_back(key);
    }
    std::stable_sort(keys.begin(), keys.end(),
                     [](const Json& x, const Json& y) { return x["t"].get<double>() < y["t"].get<double>(); });
}

std::string interp_arg(const char* command, const Json& a, const char* key, bool required) {
    if (!a.contains(key) || a[key].is_null()) {
        if (required)
            fail("invalid_argument",
                 std::string(command) + ": give `" + key + "`: linear, step, bezier or an easing such as quadInOut.",
                 "Example: \"" + std::string(key) + "\":\"quadInOut\".");
        return "";
    }
    std::vector<std::string> names = {"linear", "step", "bezier"};
    for (const std::string& e : clip_ease_names()) names.push_back(e);
    if (!a[key].is_string() || std::find(names.begin(), names.end(), a[key].get<std::string>()) == names.end())
        fail("invalid_argument",
             std::string(command) + ": `" + key + "` is " + describe_json_value(a[key]) + ", not an interpolation.",
             (a[key].is_string() ? did_you_mean(a[key].get<std::string>(), names) + " " : std::string()) +
                 "Valid: linear, step, bezier or an easing (" + join(clip_ease_names(), ", ") + ").");
    return a[key].get<std::string>();
}

struct KeyRef {
    std::string bone;
    Anim3DChannel channel = Anim3DChannel::Rotation;
    double t = 0;
};

std::vector<KeyRef> key_refs_arg(const char* command, const Json& a) {
    if (!a.contains("keys") || !a["keys"].is_array() || a["keys"].empty())
        fail("invalid_argument", std::string(command) + ": give `keys`, the keys to change as [{bone, channel?, t}].",
             "Example: \"keys\":[{\"bone\":\"thigh_l\",\"t\":0.5}]. anim3d.info {path} lists the tracks; channel "
             "defaults to rotation.");
    std::vector<KeyRef> out;
    for (std::size_t i = 0; i < a["keys"].size(); ++i) {
        const Json& k = a["keys"][i];
        if (!k.is_object() || !k.contains("bone") || !k["bone"].is_string() || !k.contains("t") || !k["t"].is_number())
            fail("invalid_argument",
                 std::format("{}: keys/{} must be {{bone, channel?, t}}, got {}.", command, i, describe_json_value(k)),
                 "Example: {\"bone\":\"thigh_l\",\"channel\":\"rotation\",\"t\":0.5}.");
        KeyRef r;
        r.bone = k["bone"].get<std::string>();
        r.channel = channel_arg(command, k);
        r.t = k["t"].get<double>();
        out.push_back(r);
    }
    return out;
}

// (track index, key index) of a referenced key of `doc`, or a not_found that lists the times the track has.
std::pair<int, int> locate_key(const char* command, const Json& doc, const KeyRef& r, const std::string& rel) {
    const int ti = find_track_json(doc, r.bone, r.channel);
    if (ti < 0) {
        std::vector<std::string> bones;
        if (doc.contains("tracks") && doc["tracks"].is_array())
            for (const Json& t : doc["tracks"])
                if (t.contains("bone") && t["bone"].is_string()) bones.push_back(t["bone"].get<std::string>());
        std::sort(bones.begin(), bones.end());
        bones.erase(std::unique(bones.begin(), bones.end()), bones.end());
        fail("not_found",
             std::string(command) + ": '" + rel + "' has no " + anim3d_channel_name(r.channel) + " track for '" +
                 r.bone + "'.",
             bones.empty() ? "The clip has no tracks."
                           : did_you_mean(r.bone, bones) + " Bones with a track: " + join(bones, ", ") + ".");
    }
    const Json& keys = doc["tracks"][std::size_t(ti)]["keys"];
    std::string times;
    for (std::size_t k = 0; k < keys.size(); ++k) {
        if (std::fabs(keys[k]["t"].get<double>() - r.t) < 1e-3) return {ti, int(k)};
        times += (times.empty() ? "" : ", ") + std::format("{:g}", keys[k]["t"].get<double>());
    }
    fail("not_found",
         std::format("{}: the {} track of '{}' has no key at t={}.", command, anim3d_channel_name(r.channel), r.bone,
                     r.t),
         "Its keys are at: " + times + ".");
}

Json anim3d_restore_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.restore", a, "", {"path", "clip", "provenance"});
    const std::string rel = clip_path_arg("anim3d.restore", a, "path");
    if (!a.contains("clip"))
        fail("invalid_argument",
             "anim3d.restore: give `clip`, the whole document to write, or null to delete the file.",
             "Every writing anim3d.* command returns the call that undoes it as `undo`.");
    const bool hasProv = a.contains("provenance");
    if (hasProv && !a["provenance"].is_null()) {
        const Json& pv = a["provenance"];
        if (!pv.is_object())
            fail("invalid_argument",
                 "anim3d.restore: `provenance` is " + describe_json_value(pv) + ", not an object or null.",
                 "Pass the `provenance` the undo returned, or leave it out.");
        const std::string origin =
            pv.contains("origin") && pv["origin"].is_string() ? pv["origin"].get<std::string>() : std::string();
        if (origin != "generated" && origin != "imported" && origin != "original")
            fail("invalid_argument",
                 "anim3d.restore: /provenance/origin is " +
                     (pv.contains("origin") ? describe_json_value(pv["origin"]) : std::string("missing")) +
                     ", not \"generated\", \"imported\" or \"original\".",
                 "A provenance record needs `origin` and `date` (schemas/assets.schema.json); pass the `provenance` "
                 "the undo returned.");
        if (!pv.contains("date") || !pv["date"].is_string())
            fail("invalid_argument",
                 "anim3d.restore: /provenance/date is " +
                     (pv.contains("date") ? describe_json_value(pv["date"]) : std::string("missing")) +
                     ", not a string like \"2026-01-31\".",
                 "A provenance record needs `origin` and `date` (schemas/assets.schema.json); pass the `provenance` "
                 "the undo returned.");
    }
    require_usable_manifest(projectDir);
    const Json before = clip_before(projectDir, rel);
    if (a["clip"].is_null()) {
        const stdfs::path file = project_write_file(projectDir, rel);
        std::error_code ec;
        if (!stdfs::exists(file, ec))
            fail("not_found", "anim3d.restore: '" + rel + "' does not exist, so there is nothing to delete.",
                 "Nothing to undo here.");
        stdfs::remove(file, ec);
        if (ec)
            fail("failed", "anim3d.restore: cannot delete '" + rel + "': " + ec.message(),
                 "Check that the file is not open elsewhere.");
        clear_anim3d_cache();
        // the record goes with the file (a record of a missing clip would keep a recipe assets.regenerate runs again); the undo puts it back
        Json previous = nullptr;
        ProjectRootGuard root(projectDir);
        auto upd = assets::update_entry(rel, [&](Json& e) {
            if (e.contains("provenance") && e["provenance"].is_object()) previous = e["provenance"];
            e.erase("provenance");
        });
        if (!upd.ok())
            fail("failed",
                 "The clip '" + rel + "' was deleted, but assets.json was not updated: " + upd.error().message,
                 upd.error().hint);
        Json deleted = obj({{"path", rel}, {"deleted", true}, {"undo", undo_restore(rel, before, previous)}});
        if (hasProv && !a["provenance"].is_null())
            deleted["warnings"] = Json::array({"`provenance` was ignored: deleting a clip removes its record too."});
        return deleted;
    }
    if (!a["clip"].is_object() || !is_anim3d_json(a["clip"]))
        fail("invalid_argument",
             "anim3d.restore: `clip` is " + describe_json_value(a["clip"]) + ", not a 3D clip document.",
             "Pass the whole document (format \"" + std::string(kAnim3DFormat) + "\") or null.");
    return commit_clip(projectDir, rel, before, a["clip"], Json::object(), hasProv ? &a["provenance"] : nullptr);
}

Json anim3d_move_keys_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.move_keys", a, "", {"path", "keys", "dt", "extendDuration"});
    const std::string rel = clip_path_arg("anim3d.move_keys", a, "path");
    const std::vector<KeyRef> refs = key_refs_arg("anim3d.move_keys", a);
    const double dt = number_arg("anim3d.move_keys", a, "dt", 0.0, -3600.0, 3600.0,
                                 "Seconds to move the keys by (negative = earlier).");
    const bool extend = tooling_detail::arg_bool(a, "extendDuration", false);
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    std::map<int, std::set<int>> selected;  // track -> key indices
    for (const KeyRef& r : refs) {
        const auto [ti, ki] = locate_key("anim3d.move_keys", doc, r, rel);
        selected[ti].insert(ki);
    }
    double duration = doc.value("duration", 1.0);
    for (auto& [ti, picked] : selected) {
        Json& keys = doc["tracks"][std::size_t(ti)]["keys"];
        const std::string bone = doc["tracks"][std::size_t(ti)]["bone"].get<std::string>();
        std::vector<std::pair<double, int>> moved;  // new time, old index
        for (int ki : picked) {
            const double t = round_to(keys[std::size_t(ki)]["t"].get<double>() + dt, 4);
            if (t < -1e-9)
                fail("invalid_argument",
                     std::format(
                         "anim3d.move_keys: the key of '{}' at t={} would move to t={}, before the start of the clip.",
                         bone, keys[std::size_t(ki)]["t"].get<double>(), t),
                     "Move it by a smaller dt, or move the other keys later first.");
            if (t > duration + 1e-9) {
                if (!extend)
                    fail("invalid_argument",
                         std::format(
                             "anim3d.move_keys: the key of '{}' would move to t={}, after the end of the clip ({} s).",
                             bone, t, duration),
                         "Pass extendDuration: true to lengthen the clip, or anim3d.set_clip {duration} first.");
                duration = t;
            }
            moved.push_back({std::max(0.0, t), ki});
        }
        for (std::size_t i = 0; i < moved.size(); ++i)
            for (std::size_t j = i + 1; j < moved.size(); ++j)
                if (std::fabs(moved[i].first - moved[j].first) < kTimeEps)
                    fail("invalid_argument",
                         std::format("anim3d.move_keys: two keys of '{}' would land on t={}.", bone, moved[i].first),
                         "Select keys that do not collide, or move them by a different dt.");
        Json next = Json::array();
        for (std::size_t ki = 0; ki < keys.size(); ++ki) {
            if (picked.count(int(ki))) continue;
            bool covered = false;  // a moved key replaces the key it lands on
            for (const auto& m : moved)
                if (std::fabs(keys[ki]["t"].get<double>() - m.first) < kTimeEps) covered = true;
            if (!covered) next.push_back(keys[ki]);
        }
        for (const auto& m : moved) {
            Json k = keys[std::size_t(m.second)];
            k["t"] = m.first;
            k.erase("in");  // a moved bezier key gets smooth tangents again
            k.erase("out");
            next.push_back(k);
        }
        std::stable_sort(next.begin(), next.end(),
                         [](const Json& x, const Json& y) { return x["t"].get<double>() < y["t"].get<double>(); });
        keys = next;
    }
    doc["duration"] = duration;
    Json r = commit_clip(projectDir, rel, before, doc, obj({{"moved", refs.size()}, {"dt", dt}}));
    r["nextSteps"] = Json::array({"anim3d.preview {\"path\":\"" + rel + "\"} draws the result."});
    return r;
}

Json anim3d_remove_keys_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.remove_keys", a, "", {"path", "keys"});
    const std::string rel = clip_path_arg("anim3d.remove_keys", a, "path");
    const std::vector<KeyRef> refs = key_refs_arg("anim3d.remove_keys", a);
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    std::map<int, std::set<int>> selected;
    for (const KeyRef& r : refs) {
        const auto [ti, ki] = locate_key("anim3d.remove_keys", doc, r, rel);
        selected[ti].insert(ki);
    }
    int emptied = 0;
    Json tracks = Json::array();
    for (std::size_t ti = 0; ti < doc["tracks"].size(); ++ti) {
        Json track = doc["tracks"][ti];
        auto it = selected.find(int(ti));
        if (it != selected.end()) {
            Json keys = Json::array();
            for (std::size_t ki = 0; ki < track["keys"].size(); ++ki)
                if (!it->second.count(int(ki))) keys.push_back(track["keys"][ki]);
            track["keys"] = keys;
            if (keys.empty()) {
                ++emptied;
                continue;  // a track with no key is no track
            }
        }
        tracks.push_back(track);
    }
    doc["tracks"] = tracks;
    Json r = commit_clip(projectDir, rel, before, doc, obj({{"removed", refs.size()}, {"tracksRemoved", emptied}}));
    r["nextSteps"] = Json::array({"anim3d.set_keys adds keys back."});
    return r;
}

Json anim3d_set_interp_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.set_interp", a, "", {"path", "keys", "interp"});
    const std::string rel = clip_path_arg("anim3d.set_interp", a, "path");
    const std::vector<KeyRef> refs = key_refs_arg("anim3d.set_interp", a);
    const std::string interp = interp_arg("anim3d.set_interp", a, "interp", true);
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    for (const KeyRef& r : refs) {
        const auto [ti, ki] = locate_key("anim3d.set_interp", doc, r, rel);
        Json& key = doc["tracks"][std::size_t(ti)]["keys"][std::size_t(ki)];
        key["interp"] = interp;
        if (interp != "bezier") {
            key.erase("in");
            key.erase("out");
        }
    }
    return commit_clip(projectDir, rel, before, doc, obj({{"changed", refs.size()}, {"interp", interp}}));
}

Json anim3d_set_clip_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.set_clip", a, "", {"path", "duration", "loop", "groundSpeed", "doc"});
    const std::string rel = clip_path_arg("anim3d.set_clip", a, "path");
    if (!a.contains("duration") && !a.contains("loop") && !a.contains("groundSpeed") && !a.contains("doc"))
        fail("invalid_argument", "anim3d.set_clip: nothing to change.",
             "Pass `duration`, `loop`, `groundSpeed` and/or `doc`.");
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    if (a.contains("duration"))
        doc["duration"] = round_to(
            number_arg("anim3d.set_clip", a, "duration", 1.0, 0.0, 3600.0, "The length of the clip in seconds."), 4);
    if (a.contains("loop")) {
        if (!a["loop"].is_boolean())
            fail("invalid_argument",
                 "anim3d.set_clip: `loop` must be true or false, got " + describe_json_value(a["loop"]) + ".",
                 "true repeats the clip, false stops on its last pose.");
        doc["loop"] = a["loop"];
    }
    if (a.contains("groundSpeed")) {
        const double g = number_arg("anim3d.set_clip", a, "groundSpeed", 0.0, 0.0, 1000.0,
                                    "Model units per second the ground moves under the planted feet; 0 = in place.");
        if (g > 0)
            doc["groundSpeed"] = g;
        else
            doc.erase("groundSpeed");
    }
    if (a.contains("doc")) {
        if (!a["doc"].is_string())
            fail("invalid_argument",
                 "anim3d.set_clip: `doc` must be a string, got " + describe_json_value(a["doc"]) + ".",
                 "What the clip shows, in a sentence.");
        if (a["doc"].get<std::string>().empty())
            doc.erase("doc");
        else
            doc["doc"] = a["doc"];
    }
    return commit_clip(projectDir, rel, before, doc);
}

// An event of `doc` by index or {t, name?}.
int event_ref(const char* command, const Json& doc, const Json& ref, const std::string& rel) {
    const Json& events = doc.contains("events") && doc["events"].is_array() ? doc["events"] : Json::array();
    auto list = [&] {
        std::string s;
        for (std::size_t i = 0; i < events.size(); ++i) {
            std::string label = events[i].value("name", std::string());
            std::string acts;
            for (const Json& act : feel_event_actions(events[i])) acts += "+" + act.value("action", std::string("?"));
            if (!acts.empty()) label += (label.empty() ? "feel" : " feel") + acts;
            s += (s.empty() ? "" : ", ") + std::format("{}: {} at {:g}", i, label, events[i].value("t", 0.0));
        }
        return s.empty() ? std::string("The clip has no events (anim3d.add_event adds one).")
                         : "The events: " + s + ".";
    };
    if (ref.is_number_integer()) {
        const long long i = ref.get<long long>();
        if (i < 0 || std::size_t(i) >= events.size())
            fail("not_found", std::format("{}: '{}' has no event {}.", command, rel, i), list());
        return int(i);
    }
    if (ref.is_object() && ref.contains("t") && ref["t"].is_number()) {
        int found = -1, matches = 0;
        for (std::size_t i = 0; i < events.size(); ++i) {
            if (std::fabs(events[i].value("t", -1.0) - ref["t"].get<double>()) > 1e-3) continue;
            if (ref.contains("name") && events[i].value("name", std::string()) != ref["name"].get<std::string>())
                continue;
            found = int(i);
            ++matches;
        }
        if (matches == 0)
            fail("not_found", std::format("{}: '{}' has no event at t={}.", command, rel, ref["t"].get<double>()),
                 list());
        if (matches > 1)
            fail("invalid_argument",
                 std::format("{}: {} events are at t={}.", command, matches, ref["t"].get<double>()),
                 "Add `name` to {t, name}, or use the index. " + list());
        return found;
    }
    fail("invalid_argument",
         std::string(command) + ": `event` must be the event's index or {t, name?}, got " + describe_json_value(ref) +
             ".",
         list());
}

Json anim3d_add_event_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.add_event", a, "", {"path", "t", "name", "data", "feel", "extendDuration"});
    const std::string rel = clip_path_arg("anim3d.add_event", a, "path");
    const bool hasName = a.contains("name") && !a["name"].is_null();
    if (hasName && (!a["name"].is_string() || a["name"].get<std::string>().empty()))
        fail("invalid_argument", "anim3d.add_event: `name` must be a non-empty string.",
             "The game event name world.on(name, fn) listens to.");
    if (!hasName && !a.contains("feel"))
        fail("invalid_argument",
             "anim3d.add_event: give `name` (the game event this raises) or `feel` (game feel actions to run).",
             "Example: {\"t\":0.2,\"name\":\"footstep\",\"data\":{\"foot\":\"left\"}} or "
             "{\"t\":0.2,\"feel\":{\"action\":\"hitStop\"}}.");
    const double t =
        round_to(number_arg("anim3d.add_event", a, "t", -1.0, 0.0, 3600.0, "Seconds from the start of the clip."), 4);
    if (!a.contains("t"))
        fail("invalid_argument", "anim3d.add_event: give `t`, the time of the event in seconds.",
             "Example: \"t\":0.2.");
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    if (t > doc.value("duration", 1.0) + 1e-9) {
        if (!tooling_detail::arg_bool(a, "extendDuration", false))
            fail("invalid_argument",
                 std::format("anim3d.add_event: t={} is after the end of the clip ({} s).", t,
                             doc.value("duration", 1.0)),
                 "Pass extendDuration: true, or anim3d.set_clip {duration} first.");
        doc["duration"] = t;
    }
    Json ev = obj({{"t", t}});
    if (hasName) ev["name"] = a["name"];
    if (a.contains("data") && !a["data"].is_null()) ev["data"] = a["data"];
    if (a.contains("feel") && !a["feel"].is_null()) ev["feel"] = a["feel"];
    if (!doc.contains("events") || !doc["events"].is_array()) doc["events"] = Json::array();
    doc["events"].push_back(ev);
    return commit_clip(projectDir, rel, before, doc, obj({{"event", ev}}));
}

Json anim3d_set_event_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.set_event", a, "", {"path", "event", "t", "name", "data", "feel", "extendDuration"});
    const std::string rel = clip_path_arg("anim3d.set_event", a, "path");
    if (!a.contains("event"))
        fail("invalid_argument", "anim3d.set_event: give `event`, the index of the event or {t, name?}.",
             "anim3d.info {path} lists the events.");
    if (!a.contains("t") && !a.contains("name") && !a.contains("data") && !a.contains("feel"))
        fail("invalid_argument", "anim3d.set_event: nothing to change.",
             "Pass `t` (move it), `name`, `data` and/or `feel`.");
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    const int i = event_ref("anim3d.set_event", doc, a["event"], rel);
    Json& ev = doc["events"][std::size_t(i)];
    if (a.contains("t")) {
        const double t = round_to(
            number_arg("anim3d.set_event", a, "t", 0.0, 0.0, 3600.0, "Seconds from the start of the clip."), 4);
        if (t > doc.value("duration", 1.0) + 1e-9) {
            if (!tooling_detail::arg_bool(a, "extendDuration", false))
                fail("invalid_argument",
                     std::format("anim3d.set_event: t={} is after the end of the clip ({} s).", t,
                                 doc.value("duration", 1.0)),
                     "Pass extendDuration: true, or anim3d.set_clip {duration} first.");
            doc["duration"] = t;
        }
        ev["t"] = t;
    }
    if (a.contains("name")) {
        if (!a["name"].is_string() || a["name"].get<std::string>().empty())
            fail("invalid_argument", "anim3d.set_event: `name` must be a non-empty string.",
                 "The game event name world.on(name, fn) listens to.");
        ev["name"] = a["name"];
    }
    if (a.contains("data")) {
        if (a["data"].is_null() || (a["data"].is_object() && a["data"].empty()))
            ev.erase("data");
        else
            ev["data"] = a["data"];
    }
    if (a.contains("feel")) {
        if (a["feel"].is_null() || (a["feel"].is_array() && a["feel"].empty()))
            ev.erase("feel");
        else
            ev["feel"] = a["feel"];
    }
    return commit_clip(projectDir, rel, before, doc);
}

Json anim3d_remove_event_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.remove_event", a, "", {"path", "event"});
    const std::string rel = clip_path_arg("anim3d.remove_event", a, "path");
    if (!a.contains("event"))
        fail("invalid_argument", "anim3d.remove_event: give `event`, the index of the event or {t, name?}.",
             "anim3d.info {path} lists the events.");
    const Json before = read_clip_json(projectDir, rel);
    Json doc = before;
    const int i = event_ref("anim3d.remove_event", doc, a["event"], rel);
    const Json removed = doc["events"][std::size_t(i)];
    Json events = Json::array();
    for (std::size_t k = 0; k < doc["events"].size(); ++k)
        if (int(k) != i) events.push_back(doc["events"][k]);
    if (events.empty())
        doc.erase("events");
    else
        doc["events"] = events;
    return commit_clip(projectDir, rel, before, doc, obj({{"removed", removed}}));
}

// The baked rig a command works with: `rig`, else the one the clip records.
RigHold rig_for_clip(const char* command, const std::string& projectDir, const Json& a, const Anim3DClip& clip) {
    if (a.contains("rig") && a["rig"].is_string() && !a["rig"].get<std::string>().empty())
        return load_rig_arg(command, projectDir, a["rig"].get<std::string>(), "rig");
    if (!clip.rig.empty()) return load_rig_arg(command, projectDir, clip.rig, "rig");
    fail("invalid_argument", std::string(command) + ": give `rig`, the baked rig of the clip.",
         "The clip names no rig of its own. Example: {\"rig\":\"assets/models/hero.rig.glb\"}.");
}

double time_arg(const char* command, const Json& a, const Anim3DClip& clip) {
    if (!a.contains("time") || !a["time"].is_number())
        fail("invalid_argument", std::string(command) + ": give `time`, the second of the clip to key.",
             "Example: \"time\":0.5.");
    return round_to(number_arg(command, a, "time", 0.0, 0.0, double(clip.duration),
                               "Seconds into the clip, from 0 to its duration."),
                    4);
}

Json anim3d_mirror_pose_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.mirror_pose", a, "", {"path", "rig", "time", "from", "to", "interp"});
    const std::string rel = clip_path_arg("anim3d.mirror_pose", a, "path");
    const Json before = read_clip_json(projectDir, rel);
    const auto clip = parse_clip_or_fail(before, rel);
    const RigHold rig = rig_for_clip("anim3d.mirror_pose", projectDir, a, *clip);
    const double time = time_arg("anim3d.mirror_pose", a, *clip);
    const double dest = a.contains("to") && !a["to"].is_null()
                            ? round_to(number_arg("anim3d.mirror_pose", a, "to", time, 0.0, double(clip->duration),
                                                  "Seconds into the clip where the mirrored pose is keyed."),
                                       4)
                            : time;
    std::string from = "swap";
    if (a.contains("from") && !a["from"].is_null()) {
        const std::vector<std::string> names = {"swap", "left", "right"};
        if (!a["from"].is_string() ||
            std::find(names.begin(), names.end(), a["from"].get<std::string>()) == names.end())
            fail("invalid_argument",
                 "anim3d.mirror_pose: `from` is " + describe_json_value(a["from"]) + ", not swap, left or right.",
                 a["from"].is_string()
                     ? did_you_mean(a["from"].get<std::string>(), names)
                     : "swap exchanges both sides, left copies the left pose onto the right, right the other way.");
        from = a["from"].get<std::string>();
    }
    const std::string interp = interp_arg("anim3d.mirror_pose", a, "interp", false);
    const std::vector<Anim3DPoseKey> keys = mirror_pose_keys(*clip, rig.rig, float(time), from);
    if (keys.empty())
        fail("invalid_argument",
             "anim3d.mirror_pose: the clip has no track to mirror" +
                 std::string(from == "swap" ? "." : " on that side."),
             "Key some bones first (anim3d.set_keys), or pass from: \"swap\" for the bones on the mid plane.");
    Json doc = before;
    Json bones = Json::array();
    for (const Anim3DPoseKey& k : keys) {
        const int comps = k.channel == Anim3DChannel::Rotation && clip->quat ? 4 : 3;
        put_key(doc, k.bone, k.channel, dest, round_floats(k.value, comps), interp);
        bones.push_back(k.bone);
    }
    Json r = commit_clip(projectDir, rel, before, doc,
                         obj({{"time", dest}, {"from", from}, {"keys", keys.size()}, {"bones", bones}}));
    r["nextSteps"] =
        Json::array({"anim3d.preview {\"path\":\"" + rel +
                     "\"} draws the clip; mirror the pose at another time to build the second half of a cycle."});
    return r;
}

Json ik3d_key_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("ik3d.key", a, "", {"path", "rig", "time", "solver", "interp", "groundHeight"});
    const std::string rel = clip_path_arg("ik3d.key", a, "path");
    if (!a.contains("solver") || !a["solver"].is_object())
        fail("invalid_argument", "ik3d.key: give `solver`, one entry of IK3D.solvers with [x, y, z] targets.",
             "Example: "
             "{\"type\":\"twoBone\",\"root\":\"thigh_l\",\"mid\":\"shin_l\",\"end\":\"foot_l\",\"target\":[0.3,0.2,0.4]"
             ",\"pole\":[0.3,0.5,1.5]}.");
    const Json before = read_clip_json(projectDir, rel);
    const auto clip = parse_clip_or_fail(before, rel);
    const RigHold rig = rig_for_clip("ik3d.key", projectDir, a, *clip);
    const double time = time_arg("ik3d.key", a, *clip);
    const std::string interp = interp_arg("ik3d.key", a, "interp", false);
    const float ground = float(number_arg("ik3d.key", a, "groundHeight", 0.0, -1000.0, 1000.0,
                                          "The height of the flat ground a `foot` solver stands on."));
    const Anim3DBinding binding = bind_anim3d(*clip, *rig.skeleton);
    Pose pose = rig.rig.rest;
    sample_anim3d(*clip, binding, *rig.skeleton, float(time), pose);
    const Pose animated = pose;
    auto solved = ik3d_solve_once(rig.rig, pose, a["solver"], ground);
    if (!solved.ok()) fail("invalid_argument", "ik3d.key: " + solved.error().message, solved.error().hint);
    Json doc = before;
    Json keyed = Json::array();
    for (int n : rig.rig.bones) {
        const std::string& name = rig.rig.node(n).name;
        const Quat da = pose_delta_rotation(rig.rig, animated, n), db = pose_delta_rotation(rig.rig, pose, n);
        if (std::fabs(da.x - db.x) + std::fabs(da.y - db.y) + std::fabs(da.z - db.z) + std::fabs(da.w - db.w) > 1e-5f) {
            const std::array<float, 4> v = rotation_key_value(*clip, db);
            put_key(doc, name, Anim3DChannel::Rotation, time, round_floats(v, clip->quat ? 4 : 3), interp);
            keyed.push_back(obj({{"bone", name}, {"channel", "rotation"}}));
        }
        const Vec3 d = pose.translation[std::size_t(n)] - animated.translation[std::size_t(n)];
        if (std::fabs(d.x) + std::fabs(d.y) + std::fabs(d.z) > 1e-6f) {
            const Vec3 off = pose.translation[std::size_t(n)] - rig.rig.rest.translation[std::size_t(n)];
            put_key(doc, name, Anim3DChannel::Translation, time, round_floats({off.x, off.y, off.z, 0.0f}, 3), interp);
            keyed.push_back(obj({{"bone", name}, {"channel", "translation"}}));
        }
    }
    if (keyed.empty())
        fail("invalid_argument",
             "ik3d.key: the solver changed no bone at t=" + std::to_string(time) + ", so there is nothing to key.",
             "The pose already satisfies it, or the bones it names are not part of the chain.");
    Json r = commit_clip(projectDir, rel, before, doc, obj({{"time", time}, {"keyed", keyed}, {"solved", *solved}}));
    r["nextSteps"] =
        Json::array({"anim3d.preview {\"path\":\"" + rel +
                     "\"} draws the clip; the keys are ordinary ones (anim3d.set_keys, anim3d.move_keys edit them)."});
    return r;
}

// ---- anim3d.generate / retarget ---------------------------------------------------------------------------------------------------------

Json anim3d_generate_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.generate", a, "", {"rig", "kind", "params", "out", "overwrite"});
    const RigHold rig = rig_from_args("anim3d.generate", projectDir, a);
    if (!a.contains("kind") || !a["kind"].is_string())
        fail("invalid_argument", "anim3d.generate: give `kind`, one of " + join(anim3d_generator_kinds(), ", ") + ".",
             "anim3d.generators {} lists the kinds with their parameters.");
    const std::string kind = a["kind"].get<std::string>();
    Json params = Json::object();
    if (a.contains("params") && !a["params"].is_null()) {
        if (!a["params"].is_object())
            fail("invalid_argument",
                 "anim3d.generate: `params` must be an object, got " + describe_json_value(a["params"]) + ".",
                 "Example: {\"strideLength\":1.1,\"cadence\":1.0}. anim3d.generators {} lists them.");
        params = a["params"];
    }
    std::string out;
    if (a.contains("out") && !a["out"].is_null())
        out = clip_path_arg("anim3d.generate", a, "out");
    else
        out = "anim/" + stem_of(rig.path) + "_" + kind + kClipSuffix;
    check_can_write("anim3d.generate", projectDir, out, tooling_detail::arg_bool(a, "overwrite", false));
    auto made = generate_anim3d(rig.rig, kind, params);
    if (!made.ok()) fail("invalid_argument", "anim3d.generate: " + made.error().message, made.error().hint);
    Anim3DClip clip = std::move(*made);
    clip.rig = rig.path;
    if (clip.templateName.empty()) clip.templateName = rig.rig.templateName;
    const Json json = anim3d_to_json(clip);
    parse_clip_or_fail(json, out);  // what was made reads back
    const Json before = clip_before(projectDir, out);
    const Json recorded =
        made_clip_provenance(projectDir, "anim3d.generate",
                             recipe_args(a, {{"rig", rig.path}, {"kind", kind}, {"params", params}, {"out", out}}),
                             {rig.path}, "Generated from " + rig.path + ": " + kind + ".");
    const Json prevProv = write_clip_json(projectDir, out, json, recorded);
    Json r = clip_summary(clip);
    r["path"] = out;
    r["undo"] = undo_restore(out, before, prevProv);
    r["kind"] = kind;
    r["rig"] = rig.path;
    r["generated"] = clip.generated;
    r["contactList"] = contact_list(clip);
    Json steps = Json::array();
    steps.push_back(animator_snippet(kind, out, rig.path));
    steps.push_back("anim3d.preview {\"path\":\"" + out + "\",\"rig\":\"" + rig.path +
                    "\"} draws it as a filmstrip; anim3d.set_keys edits single keys; the same call with the "
                    "`generated.params` above writes the same clip.");
    if (clip.groundSpeed > 0)
        steps.push_back(
            std::format("Move the entity at {:.3f} units per second and the planted feet stand still on the ground.",
                        clip.groundSpeed));
    r["nextSteps"] = steps;
    return r;
}

Json anim3d_retarget_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.retarget", a, "", {"path", "from", "to", "out", "plantFeet", "scale", "fps", "overwrite"});
    const std::string rel = clip_path_arg("anim3d.retarget", a, "path");
    const auto clip = read_clip(projectDir, rel);
    std::string fromArg;
    if (a.contains("from") && a["from"].is_string())
        fromArg = a["from"].get<std::string>();
    else if (!clip->rig.empty())
        fromArg = clip->rig;
    else
        fail("invalid_argument", "anim3d.retarget: give `from`, the rig the clip was made for.",
             "The clip names no rig of its own. Example: "
             "{\"from\":\"assets/models/hero.rig.glb\",\"to\":\"assets/models/guard.rig.glb\"}.");
    const RigHold from = load_rig_arg("anim3d.retarget", projectDir, fromArg, "from");
    const RigHold to = rig_from_args("anim3d.retarget", projectDir, a, "to");
    if (!a.contains("out") || !a["out"].is_string())
        fail("invalid_argument", "anim3d.retarget: give `out`, where to write the retargeted clip.",
             "Example: \"anim/guard_walk.anim.json\".");
    const std::string out = clip_path_arg("anim3d.retarget", a, "out");
    check_can_write("anim3d.retarget", projectDir, out, tooling_detail::arg_bool(a, "overwrite", false));
    RetargetOptions options;
    options.plantFeet = tooling_detail::arg_bool(a, "plantFeet", true);
    options.scale = float(
        number_arg("anim3d.retarget", a, "scale", 0.0, 0.0, 100.0,
                   "0 = the ratio of the leg lengths; else the factor for root motion, ground speed and the feet."));
    options.fps =
        float(number_arg("anim3d.retarget", a, "fps", 30.0, 4.0, 120.0, "Keys per second of the legs solved again."));
    auto made = retarget_anim3d(*clip, from.rig, to.rig, options);
    if (!made.ok()) fail("failed", "anim3d.retarget: " + made.error().message, made.error().hint);
    RetargetResult result = std::move(*made);
    result.clip.rig = to.path;
    if (!to.rig.templateName.empty()) result.clip.templateName = to.rig.templateName;
    const Json json = anim3d_to_json(result.clip);
    parse_clip_or_fail(json, out);
    const Json before = clip_before(projectDir, out);
    std::vector<std::string> inputs{recipe_path(rel), from.path};
    if (to.path != from.path) inputs.push_back(to.path);
    const Json recorded = made_clip_provenance(
        projectDir, "anim3d.retarget",
        recipe_args(a, {{"path", recipe_path(rel)}, {"from", from.path}, {"to", to.path}, {"out", out}}), inputs,
        "Retargeted from " + rel + " (" + from.path + ") to " + to.path + ".");
    const Json prevProv = write_clip_json(projectDir, out, json, recorded);
    Json r = clip_summary(result.clip);
    r["path"] = out;
    r["undo"] = undo_restore(out, before, prevProv);
    r["from"] = from.path;
    r["to"] = to.path;
    r["scale"] = round_to(result.scale, 4);
    r["mapped"] = result.mapped;
    r["dropped"] = string_list(result.dropped);
    r["resampled"] = string_list(result.resampled);
    r["planted"] = string_list(result.planted);
    r["notes"] = string_list(result.notes);
    Json steps = Json::array();
    steps.push_back(animator_snippet(stem_of(out), out, to.path));
    if (!result.dropped.empty())
        steps.push_back("These source bones have no counterpart in the target and were dropped: " +
                        join(result.dropped, ", ") + ".");
    steps.push_back("anim3d.preview {\"path\":\"" + out + "\",\"rig\":\"" + to.path + "\"} draws the result.");
    r["nextSteps"] = steps;
    return r;
}

// ---- anim3d.preview ---------------------------------------------------------------------------------------------------------------------

constexpr int kHeader = 46, kPad = 8, kLabel = 34;

bool in_contact(const Anim3DContact& c, float t) {
    if (c.from <= c.to) return t >= c.from && t <= c.to;
    return t >= c.from || t <= c.to;  // wraps through the end of a looping clip
}

// A baked rig with its bind mesh, or a CommandError that says what is wrong with it.
std::shared_ptr<Anim3DRigModel> rig_model_arg(const char* command, const std::string& projectDir,
                                              const std::string& arg, const char* key) {
    const RigHold hold = load_rig_arg(command, projectDir, arg, key);
    auto model = std::make_shared<Anim3DRigModel>();
    model->path = hold.path;
    model->skeleton = hold.skeleton;
    model->rig = make_rig3d(*model->skeleton, hold.rig.skin);
    GltfMesh glb;
    {
        ProjectRootGuard root(projectDir);
        auto mesh = read_gltf_mesh(model->path);
        if (!mesh.ok()) fail("failed", std::string(command) + ": " + mesh.error().message, mesh.error().hint);
        glb = std::move(*mesh);
    }
    std::size_t skinned = 0;
    for (const SkinVertices& sv : model->skeleton->skinVertices) skinned += sv.joints.size();
    if (skinned != glb.data.vertex_count())
        fail("failed",
             std::format("{}: '{}' has {} skinned vertices but {} in its mesh, so the skin cannot be applied.", command,
                         model->path, skinned, glb.data.vertex_count()),
             "Bake the rig again (rig.bake); the .glb must hold one skin and its mesh.");
    model->bind = std::move(glb.data);
    return model;
}

Json anim3d_preview_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("anim3d.preview", a, "",
                   {"path", "rig", "frames", "cell", "yaw", "yaws", "pitch", "out", "overwrite"});
    const std::string rel = clip_path_arg("anim3d.preview", a, "path");
    const int frames = int(number_arg("anim3d.preview", a, "frames", 8, 2, 12,
                                      "How many poses to draw, 2 to 12, evenly spaced over the clip."));
    if (a.contains("frames") && a["frames"].is_number() &&
        a["frames"].get<double>() != std::floor(a["frames"].get<double>()))
        fail("invalid_argument", "anim3d.preview: `frames` must be a whole number from 2 to 12.", "Example: 8.");
    const int cell = int(number_arg("anim3d.preview", a, "cell", 200, 96, 480, "Pixels per side of each pose."));
    const double yaw = number_arg("anim3d.preview", a, "yaw", -70, -360, 360,
                                  "The side to look from, in degrees: 0 looks at the character's front (+Z), 90 from "
                                  "its +X side (the character's left), -90 from its right.");
    const double pitch = number_arg("anim3d.preview", a, "pitch", 10, -80, 80, "Degrees above the horizon.");
    std::vector<double> yaws;  // one row of poses per angle
    if (a.contains("yaws") && !a["yaws"].is_null()) {
        if (a.contains("yaw"))
            fail("invalid_argument", "anim3d.preview: give `yaw` (one side) or `yaws` (several rows), not both.",
                 "Example: \"yaws\":[-70,0,90].");
        if (!a["yaws"].is_array() || a["yaws"].empty() || a["yaws"].size() > 6)
            fail("invalid_argument",
                 "anim3d.preview: `yaws` must be a list of 1 to 6 angles in degrees, got " +
                     describe_json_value(a["yaws"]) + ".",
                 "Example: \"yaws\":[-70,0,90] draws the clip from the right, the front and the left.");
        for (const Json& y : a["yaws"]) {
            if (!y.is_number() || y.get<double>() < -360 || y.get<double>() > 360)
                fail("invalid_argument",
                     "anim3d.preview: every entry of `yaws` must be a number of degrees from -360 to 360, got " +
                         describe_json_value(y) + ".",
                     "0 is the front (+Z), 90 the character's left, -90 its right, 180 the back.");
            yaws.push_back(y.get<double>());
        }
        if (int(yaws.size()) * frames > 48)
            fail("invalid_argument",
                 std::format("anim3d.preview: {} angles x {} frames is {} poses, more than the 48 a sheet holds.",
                             yaws.size(), frames, int(yaws.size()) * frames),
                 "Lower `frames` or give fewer `yaws`.");
    } else {
        yaws.push_back(yaw);
    }
    std::string outRel;
    stdfs::path outFile;
    if (a.contains("out") && !a["out"].is_null()) {
        if (!a["out"].is_string() || a["out"].get<std::string>().empty() ||
            to_lower(fs::extension(a["out"].get<std::string>())) != ".png")
            fail("invalid_argument", "anim3d.preview: `out` must be a project-relative path ending in .png.",
                 "Example: \"docs/review/walk.png\". Leave it out to only look at the picture (nothing is written to "
                 "the project).");
        outFile = caller_output_file(projectDir, a["out"].get<std::string>(),
                                     "anim3d.preview");  // before the render: writeProject, inside the project
        outRel = output_spelling(a["out"].get<std::string>());
        std::error_code ec;
        if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(outFile, ec))
            fail("exists", "anim3d.preview: '" + outRel + "' already exists.",
                 "Pass overwrite: true to replace it, or choose another path.");
    }
    const auto clip = read_clip(projectDir, rel);
    std::string rigArg;
    if (a.contains("rig") && a["rig"].is_string())
        rigArg = a["rig"].get<std::string>();
    else if (!clip->rig.empty())
        rigArg = clip->rig;
    else
        fail("invalid_argument", "anim3d.preview: give `rig`, the baked rig to pose.",
             "The clip names no rig of its own. Example: {\"rig\":\"assets/models/hero.rig.glb\"}.");
    const std::shared_ptr<Anim3DRigModel> model = rig_model_arg("anim3d.preview", projectDir, rigArg, "rig");
    const SkeletonAsset& sk = *model->skeleton;

    const Anim3DBinding binding = bind_anim3d(*clip, sk);
    std::vector<MeshData> posed;
    std::vector<float> times;
    for (int i = 0; i < frames; ++i) {
        const float t =
            clip->loop ? clip->duration * float(i) / float(frames) : clip->duration * float(i) / float(frames - 1);
        Pose pose = model->rig.rest;
        sample_anim3d(*clip, binding, sk, t, pose);
        posed.push_back(skin_rig_mesh(*model, pose));
        times.push_back(t);
    }
    // One framing for every pose, so the motion reads across the strip: centred on the first pose horizontally, the sphere that holds them all.
    ModelViewFrame frame;
    {
        Vec3 lo = posed.front().bmin, hi = posed.front().bmax;
        for (const MeshData& m : posed) {
            lo = min(lo, m.bmin);
            hi = max(hi, m.bmax);
        }
        frame.center = {(posed.front().bmin.x + posed.front().bmax.x) * 0.5f, (lo.y + hi.y) * 0.5f,
                        (posed.front().bmin.z + posed.front().bmax.z) * 0.5f};
        double radius = 0.05;
        for (const MeshData& m : posed)
            for (std::size_t v = 0; v + 2 < m.positions.size(); v += 3) {
                const double dx = m.positions[v] - frame.center.x, dy = m.positions[v + 1] - frame.center.y,
                             dz = m.positions[v + 2] - frame.center.z;
                radius = std::max(radius, std::sqrt(dx * dx + dy * dy + dz * dz));
            }
        frame.radius = radius;
    }

    // One angle: the poses fill a grid (4 across at most). Several angles: one row of `frames` poses per angle.
    const bool several = yaws.size() > 1;
    const int columns = several ? frames : frames <= 4 ? frames : frames <= 6 ? 3 : 4;
    const int rows = several ? int(yaws.size()) : (frames + columns - 1) / columns;
    const int width = columns * cell + (columns + 1) * kPad,
              height = kHeader + rows * (cell + kLabel) + (rows + 1) * kPad;
    Canvas canvas(width, height, {22, 24, 28});
    ModelViewOptions vo;
    vo.width = vo.height = cell;
    vo.pitchDeg = pitch;
    vo.shaded = true;
    vo.ground = true;
    vo.center = frame.center;
    vo.radius = frame.radius;
    vo.supersample = cell > 320 ? 1 : 2;
    const int cells = several ? rows * frames : frames;
    for (int n = 0; n < cells; ++n) {
        const int i = several ? n % frames : n;
        const double cellYaw = several ? yaws[std::size_t(n / frames)] : yaws.front();
        vo.yawDeg = cellYaw;
        ModelViewItem item;
        item.mesh = &posed[std::size_t(i)];
        const Image cellImage = render_model_view({item}, vo);
        const int col = several ? i : n % columns, row = several ? n / frames : n / columns;
        const int x = kPad + col * (cell + kPad), y = kHeader + kPad + row * (cell + kLabel + kPad);
        draw_over(canvas.img, cellImage, x, y);
        canvas.rect(x, y + cell, x + cell - 1, y + cell + kLabel - 1, {30, 33, 39});
        canvas.text(std::format("{} / {}   t {:.2f} s", i + 1, frames, times[std::size_t(i)]), x + 6, y + cell + 4, 12,
                    {170, 178, 190});
        if (several) canvas.text(std::format("yaw {:.0f}", cellYaw), x + cell - 62, y + cell + 4, 12, {150, 170, 210});
        std::vector<std::string> planted;
        for (const Anim3DContact& c : clip->contacts)
            if (in_contact(c, times[std::size_t(i)])) planted.push_back(c.bone);
        if (!planted.empty())
            canvas.text("on ground: " + join(planted, ", "), x + 6, y + cell + 19, 12, {120, 200, 140});
    }
    canvas.text(rel, kPad + 2, 6, 17, {235, 238, 245});
    canvas.text(std::format("{:.2f} s  {}   {} track{}   ground speed {:.2f} per s   rig {}", clip->duration,
                            clip->loop ? "loops" : "plays once", clip->tracks.size(),
                            clip->tracks.size() == 1 ? "" : "s", clip->groundSpeed, model->path),
                kPad + 2, 28, 13, {185, 192, 204});

    Json result = obj({{"path", rel}, {"rig", model->path}});
    result["clip"] = clip_summary(*clip);
    result["frames"] = frames;
    Json timeList = Json::array();
    for (int i = 0; i < frames; ++i) timeList.push_back(round_to(times[std::size_t(i)], 4));
    result["times"] = timeList;
    Json yawList = Json::array();
    for (double y : yaws) yawList.push_back(y);
    result["yaws"] = yawList;
    result["picture"] = obj({{"width", canvas.img.width},
                             {"height", canvas.img.height},
                             {"cell", cell},
                             {"columns", columns},
                             {"rows", rows}});
    if (!binding.missing.empty()) result["missingBones"] = string_list(binding.missing);
    if (!outRel.empty()) {
        const std::vector<std::uint8_t> png = encode_png(canvas.img);
        std::string err;
        const stdfs::path& out = outFile;
        if (!tooling_detail::write_file(out, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()),
                                        &err))
            fail("failed", err);
        result["written"] = outRel;
        result["$image"] = image_member(out, false);
    } else {
        result["$image"] = image_member(write_temporary_picture(projectDir, canvas.img, "anim3d"), true);
    }
    Json steps = Json::array();
    if (several)
        steps.push_back(std::format(
            "Read the sheet left to right (time) and top to bottom (the sides: yaw {}): the rig posed at {} times of "
            "the clip on the ground grid y = 0. The mesh is skinned with the rig's weights as the .glb stores them.",
            join_numbers(yaws), frames));
    else
        steps.push_back(std::format(
            "Read the strip left to right, top to bottom: the rig posed at {} times of the clip, seen from yaw {:.0f} "
            "on the ground grid y = 0. The mesh is skinned with the rig's weights as the .glb stores them.",
            frames, yaws.front()));
    steps.push_back("A green line under a pose names the bones the clip's contacts say are on the ground then.");
    if (!binding.missing.empty())
        steps.push_back("The clip has tracks for bones this rig lacks (`missingBones`); anim3d.retarget carries a clip "
                        "to another rig.");
    if (!several) steps.push_back("`yaws` (e.g. [-70, 0, 90]) draws one row per side in one sheet.");
    if (outRel.empty()) steps.push_back("Pass `out` to keep the picture as a PNG in the project.");
    result["nextSteps"] = steps;
    return result;
}

// ---- ik3d.check / solve -------------------------------------------------------------------------------------------------------------------

Json ik3d_check_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("ik3d.check", a, "", {"rig", "solvers"});
    const RigHold rig = rig_from_args("ik3d.check", projectDir, a);
    if (!a.contains("solvers") || !a["solvers"].is_array())
        fail("invalid_argument", "ik3d.check: give `solvers`, the list an IK3D component holds.",
             "Example: [{\"type\":\"lookAt\",\"bone\":\"head\",\"target\":[0,1.6,3]}].");
    const std::vector<IKIssue> issues = ik3d_check_solvers(a["solvers"], &rig.rig);
    Json list = Json::array();
    for (const IKIssue& i : issues)
        list.push_back(obj({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    Json r = obj({{"rig", rig.path}, {"ok", issues.empty()}, {"issues", list}, {"solvers", a["solvers"].size()}});
    r["bones"] = bone_list(rig.rig);
    r["nextSteps"] =
        Json::array({issues.empty() ? "Set them on an entity: IK3D {\"solvers\": ...} next to its Animator. ik3d.solve "
                                      "tries one on the rest pose or a clip pose."
                                    : "Fix the listed problems (each has a JSON pointer into `solvers` and a hint)."});
    return r;
}

Json ik3d_solve_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("ik3d.solve", a, "", {"rig", "solver", "clip", "time", "groundHeight"});
    const RigHold rig = rig_from_args("ik3d.solve", projectDir, a);
    if (!a.contains("solver") || !a["solver"].is_object())
        fail("invalid_argument", "ik3d.solve: give `solver`, one entry of IK3D.solvers.",
             "Example: "
             "{\"type\":\"twoBone\",\"root\":\"thigh_l\",\"mid\":\"shin_l\",\"end\":\"foot_l\",\"target\":[0.3,0.2,0.4]"
             "}.");
    Pose pose = rig.rig.rest;
    std::string clipLabel;
    if (a.contains("clip") && !a["clip"].is_null()) {
        const std::string rel = clip_path_arg("ik3d.solve", a, "clip");
        const auto clip = read_clip(projectDir, rel);
        const Anim3DBinding binding = bind_anim3d(*clip, *rig.skeleton);
        const double time = number_arg("ik3d.solve", a, "time", 0.0, 0.0, double(clip->duration),
                                       "Seconds into the clip, from 0 to its duration.");
        sample_anim3d(*clip, binding, *rig.skeleton, float(time), pose);
        clipLabel = rel;
    } else if (a.contains("time") && !a["time"].is_null()) {
        fail("invalid_argument", "ik3d.solve: `time` needs a `clip` to sample.",
             "Give clip: \"anim/hero_walk.anim.json\", or leave `time` out to solve on the rest pose.");
    }
    const float ground =
        float(number_arg("ik3d.solve", a, "groundHeight", 0.0, -1000.0, 1000.0,
                         "The height of the flat ground a `foot` solver stands on, in the model's units."));
    auto solved = ik3d_solve_once(rig.rig, pose, a["solver"], ground);
    if (!solved.ok()) fail("invalid_argument", "ik3d.solve: " + solved.error().message, solved.error().hint);
    Json r = *solved;
    r["rig"] = rig.path;
    r["pose"] = clipLabel.empty() ? Json("rest") : Json(clipLabel);
    r["nextSteps"] = Json::array(
        {"The same solver in IK3D.solvers runs every step on the Animator's pose; ik3d.check validates a whole list."});
    return r;
}

}  // namespace

void register_anim3d_commands(CommandRegistry& registry, const std::string& projectDir) {
    const std::string kUndoNote =
        " The result carries `undo`: {command: \"anim3d.restore\", args} puts the whole clip file back as it was (or "
        "deletes a file this call created), which is how the editor undoes it.";
    const Json rigProp = path_property(
        "read", "The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative.");
    const Json pathProp = path_property("write", "The 3D clip file, project-relative, ending in .anim.json.");
    const Json pathReadProp = path_property(
        "read", "The 3D clip file, project-relative, ending in .anim.json.");  // commands that only read it
    const Json channelProp = Json::object({{"type", "string"},
                                           {"enum", Json::array({"rotation", "translation", "scale"})},
                                           {"description", "Which channel of the bone (default rotation)."}});
    {
        CommandInfo info;
        info.name = "anim3d.generators";
        info.category = "anim";
        info.readOnly = true;
        info.summary = "List the clip generators of anim3d.generate (walk, run, trot, gallop, idle, swing, hit) with "
                       "their parameters, ranges and defaults.";
        info.description = "The catalog behind anim3d.generate: for each kind what it makes, the rig templates it fits "
                           "and every parameter with its meaning, default and range. Defaults that scale with the leg "
                           "are written as 'N x leg' (the leg is hip to ankle "
                           "in the rig's rest pose). The gait tables are in docs/ANIMATION.md, \"Generators\". Nothing "
                           "is written. Example: {}";
        info.inputSchema =
            Json::object({{"type", "object"}, {"additionalProperties", false}, {"properties", Json::object()}});
        registry.add(
            info, [](const Json& args) { return anim3d_generators_command(args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "anim3d.create";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Write a new, empty 3D bone clip (*.anim.json, format factoria.anim3d/1) for a skinned rig; add "
                       "tracks with anim3d.set_keys.";
        info.description = "Creates the file with `duration` seconds and `loop`, no tracks. `rotation` is \"euler\" "
                           "(keys are [pitch, yaw, roll] degrees, the default) or \"quat\" (keys are [x, y, z, w]). "
                           "`rig` (optional) records the rig the clip is for and its template "
                           "(retargeting and anim3d.preview read it). It refuses to replace a file unless `overwrite` "
                           "is true. For a whole walk, run, idle, swing or hit clip use anim3d.generate instead. "
                           "Format: schemas/anim3d.schema.json, docs/ANIMATION.md, \"3D bone clips\". "
                           "Example: "
                           "{\"path\":\"anim/hero_wave.anim.json\",\"duration\":1.2,\"loop\":false,\"rig\":\"assets/"
                           "models/hero.rig.glb\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path"})},
             {"properties",
              obj({{"path", pathProp},
                   {"duration", num_prop("Length of the clip in seconds (default 1).", 0, 3600)},
                   {"loop", bool_prop("true repeats the clip (default), false stops on its last pose.")},
                   {"rotation",
                    Json::object(
                        {{"type", "string"},
                         {"enum", Json::array({"euler", "quat"})},
                         {"description", "How rotation keys are written: euler degrees (default) or quaternions."}})},
                   {"rig", rigProp},
                   {"doc", str_prop("What the clip shows and when it is used.")},
                   {"overwrite", bool_prop("Replace the file if it exists.")}})}});
        info.description += kUndoNote;
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_create_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.info";
        info.category = "anim";
        info.readOnly = true;
        info.summary = "Describe a 3D bone clip (duration, tracks, events, contacts, how it was generated) and, with "
                       "`rig`, check its bones against a baked rig; with no `path`, list the 3D clips of the project.";
        info.description = "Reads the clip with the loader's own rules, so a file the game could not play comes back "
                           "as an error with the JSON pointer of each problem. The result gives the length, whether it "
                           "loops, the ground speed, the tracks (bone, channel, key count, first and "
                           "last time), the events and the contacts (stretches where a foot is on the ground), and, "
                           "for a generated clip, `generated` (kind and parameters). With `rig` it also reports bones "
                           "the rig does not have (with 'did you mean'). "
                           "Example: {\"path\":\"anim/hero_walk.anim.json\",\"rig\":\"assets/models/hero.rig.glb\"}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"properties", obj({{"path", pathReadProp}, {"rig", rigProp}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_info_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.set_keys";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Add or replace keys of one bone's track in a 3D clip (rotation as euler degrees or quaternion, "
                       "translation, scale); a key at the time of an existing one replaces it.";
        info.description = "Edits one track (`bone` + `channel`, made when it does not exist): each key is {t, value, "
                           "interp, in, out} as in the file (schemas/anim3d.schema.json). `value` is [x, y, z] "
                           "(rotation: pitch, yaw, roll degrees; translation: an offset from the "
                           "rest position in the parent's frame, model units; scale: a multiplier) or [x, y, z, w] for "
                           "a quaternion clip. `interp` is linear (default), step, bezier or an easing name "
                           "(quadInOut, backOut...). Keys within 0.1 ms of an existing key replace it; the "
                           "rest are added; keys end up in time order. `duration` sets the length of the clip (a key "
                           "later than it is an error). `rig` (optional) checks that the bone exists in that rig (with "
                           "'did you mean'). The whole clip is checked with the loader's rules and "
                           "nothing is written if it is wrong. The file is written in canonical form. Example: "
                           "{\"path\":\"anim/"
                           "hero_wave.anim.json\",\"bone\":\"arm_upper_l\",\"keys\":[{\"t\":0,\"value\":[0,0,0]},{"
                           "\"t\":0.4,\"value\":[0,0,150],\"interp\":\"quadOut\"}]}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "bone", "keys"})},
             {"properties",
              obj({{"path", pathProp},
                   {"bone",
                    str_prop("Canonical bone name: role[_index][_side], e.g. \"spine_1\", \"thigh_l\", \"root\".")},
                   {"channel", channelProp},
                   {"keys", Json::object({{"type", "array"},
                                          {"items", Json::object({{"type", "object"}})},
                                          {"description", "[{t, value, interp?, in?, out?}]: seconds from the start "
                                                          "and the value (3 numbers, or 4 for a quaternion)."}})},
                   {"duration", num_prop("Set the clip's length in seconds (it must reach the last key).", 0, 3600)},
                   {"rig", rigProp}})}});
        info.description += kUndoNote;
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_set_keys_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.remove_track";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Remove the tracks of one bone from a 3D clip (all its channels, or the one in `channel`).";
        info.description = "The clip is checked with the loader's rules and written in canonical form. A bone with no "
                           "track is an error that lists the bones that have one. Example: "
                           "{\"path\":\"anim/hero_walk.anim.json\",\"bone\":\"hand_l\"}";
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"required", Json::array({"path", "bone"})},
                                         {"properties", obj({{"path", pathProp},
                                                             {"bone", str_prop("The bone whose track to remove.")},
                                                             {"channel", channelProp}})}});
        info.description += kUndoNote;
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_remove_track_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.generate";
        info.category = "anim";
        info.readOnly = false;  // it writes a clip, and assets.regenerate only runs commands that write
        info.summary = "Generate a 3D bone clip for a baked rig from parameters: walk and run (stride, cadence, "
                       "bounce, arm swing), quadruped trot and gallop, idle breathing, swings of tails and chains, hit "
                       "reactions. Planted feet do not slide.";
        info.description =
            "Writes `out` (default anim/<rig>_<kind>.anim.json), an ordinary 3D clip you can then edit key "
            "by key (anim3d.set_keys). `kind`: walk, run (biped legs; walk also fits a quadruped), trot, "
            "gallop (a quadruped's four legs), idle (spine breathing, a little sway), swing (the bones of a "
            "tail or chain swinging with a phase delay), hit (a reaction that recoils and settles). `params` "
            "are the kind's own (anim3d.generators lists them with ranges; an unknown name is an error with "
            "'did you mean'). A gait is solved with the rig's own proportions: each foot follows a path that "
            "stands still on the ground in stance (the clip's `contacts` say when) and the clip's "
            "`groundSpeed` is the speed to move the entity at so the planted feet do not slide. The clip "
            "records the kind and every parameter used in `generated`, so the same call writes the same "
            "bits. A rig that lacks what the kind needs (legs, spine, tail) is an error that says which "
            "template has it. Refuses to replace a file unless `overwrite`." FA_COMMAND_DETAILS "Example: "
            "{\"rig\":\"assets/models/"
            "hero.rig.glb\",\"kind\":\"walk\",\"params\":{\"strideLength\":1.2,\"cadence\":1.0},\"out\":\"anim/"
            "hero_walk.anim.json\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"rig", "kind"})},
             {"properties",
              obj({{"rig", rigProp},
                   {"kind",
                    Json::object({{"type", "string"},
                                  {"enum", Json::array({"walk", "run", "trot", "gallop", "idle", "swing", "hit"})},
                                  {"description", "What to generate."}})},
                   {"params", obj_prop("The kind's parameters (anim3d.generators lists them): strideLength, cadence, "
                                       "bounce, armSwing, fps...")},
                   {"out",
                    path_property(
                        "write",
                        "Where to write the clip (ending in .anim.json). Default anim/<rig name>_<kind>.anim.json.")},
                   {"overwrite", bool_prop("Replace the file if it exists.")}})}});
        info.description += kUndoNote;
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_generate_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.retarget";
        info.category = "anim";
        info.readOnly = false;
        info.summary = "Carry a 3D clip from one baked rig to another (other proportions, a different template) by "
                       "bone role, index and side; root motion and feet are scaled and planted feet stay planted.";
        info.description = "Bones are matched by (role, index, side). Rotations are copied (every rig.bake bone rests "
                           "with an identity rotation), a chain with a different bone count keeps its total bend, a "
                           "bone the target lacks is dropped and listed in `dropped`, a bone the clip does not "
                           "move rests. Root translation, ground speed and feet are scaled by the ratio of the leg "
                           "lengths (hip to ankle) or `scale`; with `plantFeet` (default) the legs the clip has "
                           "contacts for are solved again with the two-bone solver so planted feet stay planted on "
                           "the new proportions (`planted`); a foot the new legs cannot reach stretches straight and "
                           "is reported in `notes`. `from` defaults to the rig recorded in the clip. Result: {path, "
                           "scale, mapped, dropped, resampled, planted, notes}. "
                           "Example: "
                           "{\"path\":\"anim/hero_walk.anim.json\",\"to\":\"assets/models/"
                           "guard.rig.glb\",\"out\":\"anim/guard_walk.anim.json\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "to", "out"})},
             {"properties",
              obj({{"path", pathProp},
                   {"from",
                    path_property("read", "The rig the clip was made for (default: the rig recorded in the clip).")},
                   {"to", path_property("read", "The rig to carry the clip to.")},
                   {"out", path_property("write", "Where to write the retargeted clip (ending in .anim.json).")},
                   {"plantFeet",
                    bool_prop("Solve the legs with a contact again so planted feet stay planted (default true).")},
                   {"scale",
                    num_prop(
                        "Factor for root motion, ground speed and feet; 0 (default) = the ratio of the leg lengths.", 0,
                        100)},
                   {"fps", num_prop("Keys per second of the legs solved again (default 30).", 4, 120)},
                   {"overwrite", bool_prop("Replace the file at `out` if it exists.")}})}});
        info.description += kUndoNote;
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_retarget_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.preview";
        info.category = "anim";
        info.readOnly = true;
        info.summary = "Draw a 3D bone clip as a filmstrip: the baked rig posed at evenly spaced times, shaded, on a "
                       "ground grid, with the feet that are on the ground marked; returns the PNG.";
        info.description =
            "The way to SEE a clip without a window. It poses the rig's skin with the clip at `frames` times (a "
            "looping clip does not repeat its first pose at the end) and draws each with the software renderer of "
            "model.preview (no graphics device, the same pixels on "
            "every machine), all framed the same way so the motion reads across the strip. Under each pose: its time "
            "and the bones the clip's contacts say are on the ground. The mesh is skinned with the vertex weights "
            "stored in the .glb (rigid per bone as rig.bake writes them). "
            "`yaw` picks the side (default -70: from the character's right and a little in front); `yaws` (a list, "
            "e.g. [-70, 0, 90]) draws one row of poses per side in one sheet, which is how a pose is checked from "
            "several angles at once; the picture is returned as $image in a temporary file, pass `out` (a .png) to "
            "keep it. Nothing in the project changes otherwise. "
            "Example: {\"path\":\"anim/hero_walk.anim.json\",\"rig\":\"assets/models/hero.rig.glb\",\"frames\":8}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path"})},
             {"properties",
              obj({{"path", pathReadProp},
                   {"rig", rigProp},
                   {"frames", num_prop("How many poses, 2 to 12 (default 8), evenly spaced over the clip.", 2, 12)},
                   {"cell", num_prop("Pixels per side of each pose (default 200).", 96, 480)},
                   {"yaw", num_prop("The side to look from in degrees: 0 the front (+Z), 90 the character's left (+X), "
                                    "-90 its right (default -70).",
                                    -360, 360)},
                   {"yaws",
                    Json::object(
                        {{"type", "array"},
                         {"minItems", 1},
                         {"maxItems", 6},
                         {"items", Json::object({{"type", "number"}, {"minimum", -360}, {"maximum", 360}})},
                         {"description", "Several sides in one sheet: one row of `frames` poses per angle (instead of "
                                         "`yaw`), at most 6 angles and 48 poses. Example [-70, 0, 90]."}})},
                   {"pitch", num_prop("Degrees above the horizon (default 10).", -80, 80)},
                   {"out",
                    path_property("write",
                                  "Keep the picture as a PNG at this project-relative path (needs the writeProject "
                                  "capability). Left out, it is a temporary file under .factoria/.")},
                   {"overwrite", bool_prop("Replace the file at `out` if it exists.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_preview_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    const Json keyRefsProp =
        Json::object({{"type", "array"},
                      {"minItems", 1},
                      {"items", obj({{"type", "object"},
                                     {"properties", obj({{"bone", str_prop("Canonical bone name.")},
                                                         {"channel", channelProp},
                                                         {"t", num_prop("The key's time in seconds.", 0, 3600)}})},
                                     {"required", Json::array({"bone", "t"})}})},
                      {"description", "The keys, each {bone, channel (default rotation), t}."}});
    const Json feelProp = Json::object(
        {{"type", Json::array({"object", "array", "null"})},
         {"description",
          "Game feel action(s) to run, each {action: shake|hitStop|flash|knockback|push|squash|spawn|sound, "
          "...options}; on set_event they replace the old ones, null or [] removes them."}});
    const Json eventRefProp =
        Json::object({{"description", "The event: its index in the clip's events, or {t, name?}."}});
    {
        CommandInfo info;
        info.name = "anim3d.restore";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary =
            "Put a 3D clip file back to a whole document, or delete it: the undo and redo of the anim3d.* edits.";
        info.description =
            "Every writing anim3d.* command returns `undo` = {command: \"anim3d.restore\", args: {path, clip, "
            "provenance}}; calling it writes `clip` (the whole previous document, checked with the loader's rules) or, "
            "when `clip` is null, deletes the file and its record in assets.json (the undo of a "
            "command that created it). `provenance` is the record the clip had in assets.json (the recipe included): "
            "restoring writes it back exactly (it needs `origin` and `date`), null removes it; with `clip: null` it is "
            "ignored (the record is removed with the file); without it a restore keeps the record the usual way. The "
            "manifest is checked first. Its own result carries the `undo` that goes forward again (redo). Example: "
            "{\"path\":\"anim/hero_walk.anim.json\",\"clip\":null}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "clip"})},
             {"properties",
              obj({{"path", pathProp},
                   {"clip",
                    Json::object({{"type", Json::array({"object", "null"})},
                                  {"description", "The whole clip document to write, or null to delete the file."}})},
                   {"provenance",
                    Json::object({{"type", Json::array({"object", "null"})},
                                  {"description", "The assets.json provenance record to put back as it is (null "
                                                  "removes it); the undo of a call returns it."}})}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_restore_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.move_keys";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Move keys of a 3D clip in time by dt seconds (a dopesheet drag); a moved key replaces the key "
                       "it lands on.";
        info.description =
            "`keys` selects keys as [{bone, channel?, t}]; each moves to t + dt (rounded to 0.1 ms). A key may not "
            "leave the clip: before 0 is an error, past the duration is an error unless `extendDuration`. Two moved "
            "keys of one track landing on the same time is an error; "
            "a moved key replaces an unselected key at its new time. Bezier keys get smooth tangents again. Result: "
            "the clip summary plus {moved, dt, undo}. Example: "
            "{\"path\":\"anim/hero_walk.anim.json\",\"keys\":[{\"bone\":\"thigh_l\",\"t\":0.5}],\"dt\":0.05}" +
            kUndoNote;
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "keys", "dt"})},
             {"properties", obj({{"path", pathProp},
                                 {"keys", keyRefsProp},
                                 {"dt", num_prop("Seconds to move by (negative = earlier).", -3600, 3600)},
                                 {"extendDuration", bool_prop("Lengthen the clip when a key moves past its end.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_move_keys_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.remove_keys";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Delete keys of a 3D clip by bone, channel and time; a track left with no key goes away.";
        info.description =
            "`keys` selects keys as [{bone, channel?, t}] (anim3d.info lists the tracks; a time within 1 ms matches). "
            "Result: the clip summary plus {removed, tracksRemoved, undo}. "
            "Example: {\"path\":\"anim/hero_walk.anim.json\",\"keys\":[{\"bone\":\"thigh_l\",\"t\":0.5}]}" +
            kUndoNote;
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"required", Json::array({"path", "keys"})},
                                         {"properties", obj({{"path", pathProp}, {"keys", keyRefsProp}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_remove_keys_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.set_interp";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Set how selected keys of a 3D clip reach the next key: linear, step, bezier or an easing (the "
                       "M42 curves).";
        info.description =
            "`keys` selects keys as [{bone, channel?, t}]; `interp` is linear, step, bezier (smooth tangents through "
            "the neighbours) or an easing name (quadIn, quadOut, quadInOut, backOut, elasticOut... as tween()). "
            "A quaternion clip takes linear, step or an easing. Result: the clip summary plus {changed, interp, undo}. "
            "Example: "
            "{\"path\":\"anim/"
            "hero_walk.anim.json\",\"keys\":[{\"bone\":\"thigh_l\",\"t\":0.5}],\"interp\":\"quadInOut\"}" +
            kUndoNote;
        info.inputSchema =
            Json::object({{"type", "object"},
                          {"additionalProperties", false},
                          {"required", Json::array({"path", "keys", "interp"})},
                          {"properties", obj({{"path", pathProp},
                                              {"keys", keyRefsProp},
                                              {"interp", str_prop("linear, step, bezier or an easing name.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_set_interp_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.set_clip";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Set the duration, loop, ground speed or description of a 3D clip.";
        info.description = "Give any of `duration` (seconds; shorter than the last key or event is refused), `loop`, "
                           "`groundSpeed` (model units per second the planted feet move back at; 0 = in place) and "
                           "`doc`. Result: the clip summary plus {undo}. "
                           "Example: {\"path\":\"anim/hero_walk.anim.json\",\"duration\":1.2,\"loop\":false}" +
                           kUndoNote;
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path"})},
             {"properties",
              obj({{"path", pathProp},
                   {"duration", num_prop("Length of the clip in seconds.", 0, 3600)},
                   {"loop", bool_prop("true repeats the clip, false stops on its last pose.")},
                   {"groundSpeed",
                    num_prop("Model units per second the ground moves under the planted feet; 0 = in place.", 0, 1000)},
                   {"doc", str_prop("What the clip shows.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_set_clip_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.add_event";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Add an event to a 3D clip: a game event and/or game feel actions the Animator runs when the "
                       "clip passes its time.";
        info.description =
            "The event {t, name?, data?, feel?} reaches world.on(name, fn) and entity.animator.on(name, fn) with {id, "
            "clip, time} plus `data` (an object; the keys id, clip and time are reserved), once per loop. `feel` is "
            "one game feel action or an array "
            "(hitStop, shake, flash, knockback or push, squash, spawn, sound: docs/GAME_FEEL.md, \"Effects as data\") "
            "run on the entity that plays the clip; they are checked now. An event needs `name` or `feel`. Events stay "
            "sorted by t. A time past the duration is refused unless "
            "`extendDuration`. Result: the clip summary plus {event, undo}. Example: "
            "{\"path\":\"anim/hero_walk.anim.json\",\"t\":0.2,\"name\":\"footstep\",\"data\":{\"foot\":\"left\"}}" +
            kUndoNote;
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "t"})},
             {"properties", obj({{"path", pathProp},
                                 {"t", num_prop("Seconds from the start of the clip.", 0, 3600)},
                                 {"name", str_prop("The game event name. Optional when `feel` is given.")},
                                 {"data", obj_prop("Extra fields sent with the event.")},
                                 {"feel", feelProp},
                                 {"extendDuration", bool_prop("Lengthen the clip when t is past its end.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_add_event_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.set_event";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Move, rename or change the data or the game feel actions of an event of a 3D clip.";
        info.description =
            "`event` is the event's index in the clip's events, or {t, name?} (name needed when two events share the "
            "time). Give any of `t` (move it), `name`, `data` (an empty object or null clears it) and `feel` (an "
            "action or an array that REPLACES the event's; null or [] removes them). Events stay sorted by t. "
            "Result: the clip summary plus {undo}. Example: "
            "{\"path\":\"anim/hero_walk.anim.json\",\"event\":{\"t\":0.2,\"name\":\"footstep\"},\"t\":0.25}" +
            kUndoNote;
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "event"})},
             {"properties", obj({{"path", pathProp},
                                 {"event", eventRefProp},
                                 {"t", num_prop("The new time in seconds.", 0, 3600)},
                                 {"name", str_prop("The new event name.")},
                                 {"data", obj_prop("The new data (replaces the old).")},
                                 {"feel", feelProp},
                                 {"extendDuration", bool_prop("Lengthen the clip when t is past its end.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_set_event_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.remove_event";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Remove an event from a 3D clip.";
        info.description = "`event` is the event's index in the clip's events, or {t, name?}. Result: the clip summary "
                           "plus {removed, undo}. Example: {\"path\":\"anim/hero_walk.anim.json\",\"event\":0}" +
                           kUndoNote;
        info.inputSchema = Json::object({{"type", "object"},
                                         {"additionalProperties", false},
                                         {"required", Json::array({"path", "event"})},
                                         {"properties", obj({{"path", pathProp}, {"event", eventRefProp}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_remove_event_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "anim3d.mirror_pose";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Key the left/right mirror of a 3D clip's pose at a time: swap both sides, or copy one side "
                       "onto the other (bones are paired by canonical name: thigh_l <-> thigh_r).";
        info.description =
            "Samples the clip at `time`, mirrors the pose across the character's mid plane and writes it as keys at "
            "`to` (default `time`) for every bone the clip animates: `from` \"swap\" (default) puts each side's pose "
            "on the other side and mirrors the bones with no side "
            "(spine, head, root) in place; \"left\" copies the left side onto the right bones; \"right\" the other "
            "way. A mirrored rotation keeps pitch and flips yaw and roll (a quaternion (x, y, z, w) becomes (x, -y, "
            "-z, w)); a translation flips x. Only channels the clip has a "
            "track for are keyed. `rig` defaults to the clip's own. Use it to build the second half of a cycle from "
            "the first. Result: the clip summary plus {time, from, keys, bones, undo}. "
            "Example: {\"path\":\"anim/hero_walk.anim.json\",\"time\":0,\"to\":0.5}" +
            kUndoNote;
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "time"})},
             {"properties",
              obj({{"path", pathProp},
                   {"rig", rigProp},
                   {"time", num_prop("Seconds into the clip: the pose to mirror.", 0, 3600)},
                   {"to", num_prop("Where to key the mirrored pose (default: `time`).", 0, 3600)},
                   {"from",
                    Json::object({{"type", "string"},
                                  {"enum", Json::array({"swap", "left", "right"})},
                                  {"description", "swap (default), left or right: which side's pose is copied."}})},
                   {"interp",
                    str_prop("Interpolation of the new keys (default: what an existing key has, else linear).")}})}});
        registry.add(info, [projectDir](const Json& args) {
            return anim3d_mirror_pose_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "ik3d.key";
        info.category = "anim";
        info.readOnly = false;  // it writes the clip and its record in assets.json
        info.summary = "Solve a 3D IK solver (two-bone with pole, or look-at) on a clip's pose at a time and key the "
                       "bones it moved: the way an IK handle poses a chain.";
        info.description =
            "Poses the rig with the clip at `time`, runs `solver` (one entry of IK3D.solvers with [x, y, z] targets in "
            "the model's space, as ik3d.solve) and writes rotation keys at that time for every bone the solver changed "
            "(translation for a foot solver that lowers the pelvis). "
            "The keys are ordinary ones: anim3d.set_keys, anim3d.move_keys and the Animation panel edit them. Result: "
            "the clip summary plus {time, keyed: [{bone, channel}], solved (as ik3d.solve), undo}. "
            "An error says the solver changed nothing when the pose already satisfied it. Example: "
            "{\"path\":\"anim/"
            "hero_wave.anim.json\",\"time\":0.4,\"solver\":{\"type\":\"twoBone\",\"root\":\"arm_upper_r\",\"mid\":"
            "\"arm_lower_r\",\"end\":\"hand_r\",\"target\":[-0.4,1.5,0.4],\"pole\":[-0.5,1.2,-0.5]}}" +
            kUndoNote;
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"path", "time", "solver"})},
             {"properties",
              obj({{"path", pathProp},
                   {"rig", rigProp},
                   {"time", num_prop("Seconds into the clip to key.", 0, 3600)},
                   {"solver", obj_prop("One IK3D solver with fixed [x, y, z] targets (twoBone, lookAt or foot).")},
                   {"interp",
                    str_prop("Interpolation of the new keys (default: what an existing key has, else linear).")},
                   {"groundHeight",
                    num_prop("Height of the flat ground a foot solver stands on (default 0).", -1000, 1000)}})}});
        registry.add(info, [projectDir](const Json& args) {
            return ik3d_key_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "ik3d.check";
        info.category = "anim";
        info.readOnly = true;
        info.summary = "Check the `solvers` of an IK3D component against a baked rig: types, keys, number ranges, bone "
                       "names ('did you mean') and chains (root -> mid -> end).";
        info.description = "The same check project.validate runs on every IK3D in a scene, available before the scene "
                           "exists. Each problem has a JSON pointer into `solvers` (\"/2/root\"), what is wrong and "
                           "how to fix it. The result also lists the rig's bones. Nothing is written. "
                           "Example: "
                           "{\"rig\":\"assets/models/"
                           "hero.rig.glb\",\"solvers\":[{\"type\":\"lookAt\",\"bone\":\"head\",\"target\":\"player\"},{"
                           "\"type\":\"foot\",\"thigh\":\"thigh_l\",\"shin\":\"shin_l\",\"foot\":\"foot_l\"}]}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"rig", "solvers"})},
             {"properties",
              obj({{"rig", rigProp},
                   {"solvers", Json::object({{"type", "array"},
                                             {"items", Json::object({{"type", "object"}})},
                                             {"description", "The solvers as an IK3D component holds them."}})}})}});
        registry.add(info, [projectDir](const Json& args) {
            return ik3d_check_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "ik3d.solve";
        info.category = "anim";
        info.readOnly = true;
        info.summary = "Run one IK3D solver offline on a baked rig (its rest pose, or a clip's pose at a time) and "
                       "report whether it reached, the error and where the bones ended up.";
        info.description = "`solver` is one entry of IK3D.solvers whose targets are positions [x, y, z] in the model's "
                           "space (an entity target is an error: there is no scene). twoBone moves root, mid and end "
                           "so the end reaches `target` bending towards `pole`; lookAt aims `bone` within its "
                           "yaw and pitch limits; foot puts the ankle at the height of a flat ground at `groundHeight` "
                           "over where it is. Result: for a limb {reached, error, target, bones: [{bone, head}]}, for "
                           "lookAt {clamped, yaw, pitch, aim}. Use it to find a target the limb can reach "
                           "and limits that look right. Nothing is written. Example: "
                           "{\"rig\":\"assets/models/"
                           "hero.rig.glb\",\"solver\":{\"type\":\"twoBone\",\"root\":\"arm_upper_r\",\"mid\":\"arm_"
                           "lower_r\",\"end\":\"hand_r\",\"target\":[-0.4,1.3,0.5]}}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"required", Json::array({"rig", "solver"})},
             {"properties",
              obj({{"rig", rigProp},
                   {"solver", obj_prop("One IK3D solver with fixed [x, y, z] targets.")},
                   {"clip", path_property("read", "A 3D clip to pose the rig with first (default: the rest pose).")},
                   {"time", num_prop("Seconds into `clip` (default 0).", 0, 3600)},
                   {"groundHeight",
                    num_prop("Height of the flat ground a foot solver stands on (default 0).", -1000, 1000)}})}});
        registry.add(info, [projectDir](const Json& args) {
            return ik3d_solve_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }

    // Capabilities (capability.h). The clip commands write a clip file and its record in assets.json and never touch the running game;
    // anim3d.preview writes only a temporary picture under .factoria/ unless `out` is given, and then needs writeProject itself.
    using namespace capability_sets;
    declare_command_capabilities(registry, {
                                               {"anim3d.generators", reads()},
                                               {"anim3d.info", reads()},
                                               {"anim3d.preview", changes_state()},
                                               {"ik3d.check", reads()},
                                               {"ik3d.solve", reads()},
                                               {"anim3d.create", writes_project()},
                                               {"anim3d.set_keys", writes_project()},
                                               {"anim3d.remove_track", writes_project()},
                                               {"anim3d.generate", writes_project()},
                                               {"anim3d.retarget", writes_project()},
                                               {"anim3d.restore", writes_project()},
                                               {"anim3d.move_keys", writes_project()},
                                               {"anim3d.remove_keys", writes_project()},
                                               {"anim3d.set_interp", writes_project()},
                                               {"anim3d.set_clip", writes_project()},
                                               {"anim3d.add_event", writes_project()},
                                               {"anim3d.set_event", writes_project()},
                                               {"anim3d.remove_event", writes_project()},
                                               {"anim3d.mirror_pose", writes_project()},
                                               {"ik3d.key", writes_project()},
                                           });
}

}  // namespace fa::assets_detail

namespace fa {

Result<std::shared_ptr<Anim3DRigModel>> load_anim3d_rig_model(const std::string& projectDir,
                                                              const std::string& rigPath) {
    try {
        return assets_detail::rig_model_arg("anim3d", projectDir, rigPath, "rig");
    } catch (const CommandError& e) {
        return Error{e.what(), e.hint};
    }
}

}  // namespace fa
