// image.frame.add / remove / move / set / cel / sheet and image.tag.set / remove: the frames and tags of an image document
// (docs/IMAGES.md, "Frames and tags"). Each edits the document's `frames`, `tags`, `sheet` and the layers' cels through the timeline
// (image_frames.h) and bakes the document, which for an animated document is the sprite sheet.
#include <algorithm>
#include <format>
#include <numeric>

#include "fa/core/strings.h"
#include "image_frames.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

// ---- the document's animation as plain data ---------------------------------------------------------------------------------

struct Tag {
    std::string name;
    int from = 0, to = 0;
    std::string direction = "forward";
    int repeat = 0;
};

std::vector<int> read_durations(const Json& doc) {
    std::vector<int> d(std::size_t(json_frame_count(doc)), 100);
    if (doc.contains("frames") && doc["frames"].is_array())
        for (std::size_t i = 0; i < d.size() && i < doc["frames"].size(); ++i)
            if (doc["frames"][i].is_object() && doc["frames"][i].contains("duration") &&
                doc["frames"][i]["duration"].is_number_integer())
                d[i] = doc["frames"][i]["duration"].get<int>();
    return d;
}

void write_durations(Json& doc, const std::vector<int>& d) {
    Json frames = Json::array();
    for (int ms : d) frames.push_back(Json::object({{"duration", ms}}));
    doc["frames"] = frames;
}

std::vector<Tag> read_tags(const Json& doc) {
    std::vector<Tag> out;
    if (doc.contains("tags") && doc["tags"].is_array())
        for (const Json& t : doc["tags"]) {
            if (!t.is_object()) continue;
            Tag tag;
            tag.name = t.value("name", std::string());
            tag.from = t.value("from", 0);
            tag.to = t.value("to", 0);
            tag.direction = t.value("direction", std::string("forward"));
            tag.repeat = t.value("repeat", 0);
            out.push_back(std::move(tag));
        }
    return out;
}

Json tag_json(const Tag& t) {
    Json j = Json::object({{"name", t.name}, {"from", t.from}, {"to", t.to}});
    if (t.direction != "forward") j["direction"] = t.direction;
    if (t.repeat != 0) j["repeat"] = t.repeat;
    return j;
}

void write_tags(Json& doc, const std::vector<Tag>& tags) {
    Json list = Json::array();
    for (const Tag& t : tags) list.push_back(tag_json(t));
    if (list.empty())
        doc.erase("tags");
    else
        doc["tags"] = list;
}

// A document the frame commands work on: its timeline, durations and tags, written back (and normalized) by `store`.
struct Anim {
    std::vector<TimelineLayer> layers;
    std::vector<int> durations;
    std::vector<Tag> tags;
    explicit Anim(const Json& doc) : layers(load_timeline(doc)), durations(read_durations(doc)), tags(read_tags(doc)) {}
    int count() const { return int(durations.size()); }
    void store(const std::string& projectDir, Json& doc) const {
        store_timeline(doc, layers, projectDir);
        write_durations(doc, durations);
        write_tags(doc, tags);
        normalize_animation(doc);
    }
};

Json animation_json(const Json& doc) {
    const std::vector<int> d = read_durations(doc);
    Json frames = Json::array();
    int total = 0;
    for (std::size_t i = 0; i < d.size(); ++i) {
        frames.push_back(Json::object({{"frame", int(i)}, {"duration", d[i]}}));
        total += d[i];
    }
    Json tags = Json::array();
    for (const Tag& t : read_tags(doc)) tags.push_back(tag_json(t));
    return Json::object({{"frameCount", int(d.size())}, {"totalMs", total}, {"frames", frames}, {"tags", tags}});
}

// ---- argument helpers -------------------------------------------------------------------------------------------------------------

const Json& need(const Json& a, const char* cmd, const char* key, const char* what, const char* example) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null())
        arg_error(cmd, std::string("/") + key, std::string("`") + key + "` is required: " + what + ".", example);
    return *it;
}

// For an example built at run time. The `const char*` overload above is the one `const Json& x = need(...)` uses with a literal: a
// temporary std::string bound to a reference parameter makes GCC's -Wdangling-reference warn there.
const Json& need(const Json& a, const char* cmd, const char* key, const char* what, const std::string& example) {
    return need(a, cmd, key, what, example.c_str());
}

int whole_arg(const Json& a, const char* cmd, const char* key, int lo, int hi, int def) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(
            cmd, std::string("/") + key,
            std::format("`{}` must be a whole number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)),
            "");
    return it->get<int>();
}

// The result of a frame command: the bake result plus the animation. `region` and `changed` describe the picture of frame 0, which these
// commands do not draw on, so they are left out.
Json finish(const std::string& projectDir, DocFile& d, const Json& a, const char* cmd, Json extra,
            const std::vector<std::string>& warnings) {
    const bool bake = arg_bool(a, "bake", true);
    extra["animation"] = animation_json(d.json);
    Json out = commit_document(projectDir, d.rel, d.json, std::nullopt, bake, extra, warnings, cmd);
    out.erase("region");
    out.erase("changed");
    return out;
}

DocFile open_anim(const std::string& projectDir, const Json& a, const char* cmd) {
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    assets_detail::require_usable_manifest(projectDir);
    return d;
}

const Tag* find_tag(const std::vector<Tag>& tags, const std::string& name) {
    for (const Tag& t : tags)
        if (t.name == name) return &t;
    return nullptr;
}

// ---- image.frame.add -------------------------------------------------------------------------------------------------------------

Json frame_add(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.frame.add";
    check_arg_keys(cmd, a, "", {"path", "at", "from", "blank", "count", "duration", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    Anim anim(d.json);
    const int F = anim.count();
    const int count = whole_arg(a, cmd, "count", 1, 256, 1);
    if (F + count > kImageMaxFrames)
        arg_error(cmd, "/count",
                  std::format("{} frames would be more than the {} a document may have.", F + count, kImageMaxFrames),
                  "Split the animation into several documents.");
    const int at = whole_arg(a, cmd, "at", 0, F, F);
    const int from = a.contains("from") && !a["from"].is_null() ? frame_number(cmd, a["from"], "/from", F, "from")
                                                                : (at > 0 ? at - 1 : 0);
    const bool blank = arg_bool(a, "blank", false);
    if (blank && a.contains("from") && !a["from"].is_null())
        arg_error(cmd, "/blank", "`blank` and `from` are two ways to fill the new frames.",
                  "Leave out `from` for blank frames, or leave out `blank` to copy frame `from`.");
    const int duration = whole_arg(a, cmd, "duration", 1, 60000, anim.durations[std::size_t(from)]);
    for (TimelineLayer& l : anim.layers) {
        CelData cel = l.frames[std::size_t(from)];
        if (blank) cel.empty = true;
        l.frames.insert(l.frames.begin() + at, std::size_t(count), cel);
    }
    anim.durations.insert(anim.durations.begin() + at, std::size_t(count), duration);
    std::vector<std::string> warnings;
    for (Tag& t : anim.tags) {
        if (t.from >= at) {
            t.from += count;
            t.to += count;
        } else if (t.to >= at) {
            t.to += count;  // inserted inside the tag
        }
    }
    anim.store(projectDir, d.json);
    Json extra = Json::object(
        {{"added", Json::object({{"first", at}, {"count", count}, {"copiedFrom", blank ? Json() : Json(from)}})}});
    if (blank)
        warnings.push_back("Only pixels and indexed layers have a picture per frame: the other layers (fills, "
                           "gradients, text, groups) show in the new frames as they do everywhere.");
    return finish(projectDir, d, a, cmd, extra, warnings);
}

// ---- image.frame.remove ----------------------------------------------------------------------------------------------------------

Json frame_remove(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.frame.remove";
    check_arg_keys(cmd, a, "", {"path", "frame", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    Anim anim(d.json);
    const int F = anim.count();
    const int r =
        frame_number(cmd, need(a, cmd, "frame", "the frame to remove", "Example: {\"frame\":2}."), "/frame", F);
    if (F == 1)
        arg_error(cmd, "/frame", "the document has one frame, and a document needs at least one.",
                  "To drop the animation but keep one picture, remove the other frames and the tags.");
    for (TimelineLayer& l : anim.layers) l.frames.erase(l.frames.begin() + r);
    anim.durations.erase(anim.durations.begin() + r);
    std::vector<std::string> warnings;
    std::vector<Tag> kept;
    for (Tag t : anim.tags) {
        if (t.from > r) {
            --t.from;
            --t.to;
        } else if (t.to >= r) {
            if (t.from == t.to) {
                warnings.push_back("The tag '" + t.name + "' was only that frame, so it was removed.");
                continue;
            }
            --t.to;
        }
        kept.push_back(std::move(t));
    }
    anim.tags = std::move(kept);
    anim.store(projectDir, d.json);
    if (!d.json.contains("frames"))
        warnings.push_back("One frame is left and there are no tags, so the document is a plain still image again (the "
                           "bake is its picture, not a sheet).");
    return finish(projectDir, d, a, cmd, Json::object({{"removed", r}}), warnings);
}

// ---- image.frame.move ------------------------------------------------------------------------------------------------------------

Json frame_move(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.frame.move";
    check_arg_keys(cmd, a, "", {"path", "frame", "to", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    Anim anim(d.json);
    const int F = anim.count();
    const int from =
        frame_number(cmd, need(a, cmd, "frame", "the frame to move", "Example: {\"frame\":3,\"to\":0}."), "/frame", F);
    const int to = frame_number(cmd, need(a, cmd, "to", "the place it ends up at", "Example: {\"frame\":3,\"to\":0}."),
                                "/to", F, "to");
    std::vector<int> order(static_cast<std::size_t>(F));
    std::iota(order.begin(), order.end(), 0);  // order[new] = old
    order.erase(order.begin() + from);
    order.insert(order.begin() + to, from);
    std::vector<int> newOf(static_cast<std::size_t>(F));
    for (int n = 0; n < F; ++n) newOf[std::size_t(order[std::size_t(n)])] = n;
    for (TimelineLayer& l : anim.layers) {
        std::vector<CelData> moved;
        for (int n = 0; n < F; ++n) moved.push_back(l.frames[std::size_t(order[std::size_t(n)])]);
        l.frames = std::move(moved);
    }
    std::vector<int> durations;
    for (int n = 0; n < F; ++n) durations.push_back(anim.durations[std::size_t(order[std::size_t(n)])]);
    anim.durations = std::move(durations);
    std::vector<std::string> warnings;
    for (Tag& t : anim.tags) {
        int lo = F, hi = -1;
        for (int f = t.from; f <= t.to; ++f) {
            lo = std::min(lo, newOf[std::size_t(f)]);
            hi = std::max(hi, newOf[std::size_t(f)]);
        }
        if (hi - lo != t.to - t.from)
            warnings.push_back(std::format("The tag '{}' had frames {} to {}; after the move its frames are no longer "
                                           "in one run, so it now covers {} to {}.",
                                           t.name, t.from, t.to, lo, hi));
        t.from = lo;
        t.to = hi;
    }
    anim.store(projectDir, d.json);
    return finish(projectDir, d, a, cmd, Json::object({{"moved", Json::object({{"from", from}, {"to", to}})}}),
                  warnings);
}

// ---- image.frame.set -------------------------------------------------------------------------------------------------------------

Json frame_set(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.frame.set";
    check_arg_keys(cmd, a, "", {"path", "frame", "duration", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    Anim anim(d.json);
    const int F = anim.count();
    const Json& spec = need(a, cmd, "frame", "the frame, a range [first, last] or \"all\"",
                            "Example: {\"frame\":\"all\",\"duration\":80} or {\"frame\":[2,4],\"duration\":200}.");
    int first = 0, last = F - 1;
    if (spec.is_string()) {
        if (spec.get<std::string>() != "all")
            arg_error(cmd, "/frame", "'" + spec.get<std::string>() + "' is not a frame.",
                      "A frame number, a range [first, last], or \"all\".");
    } else if (spec.is_array()) {
        if (spec.size() != 2)
            arg_error(cmd, "/frame", "a range is [first, last], got " + describe_json_value(spec) + ".",
                      "Example: [2, 4].");
        first = frame_number(cmd, spec[0], "/frame/0", F);
        last = frame_number(cmd, spec[1], "/frame/1", F);
        if (first > last)
            arg_error(cmd, "/frame", std::format("the range [{}, {}] ends before it starts.", first, last),
                      "Give the lower frame first.");
    } else {
        first = last = frame_number(cmd, spec, "/frame", F);
    }
    if (!a.contains("duration") || a["duration"].is_null())
        arg_error(cmd, "/duration", "`duration` is required: how long the frames show, in milliseconds.",
                  "Example: {\"frame\":\"all\",\"duration\":100}. 100 ms is 10 frames per second.");
    const int ms = whole_arg(a, cmd, "duration", 1, 60000, 100);
    for (int f = first; f <= last; ++f) anim.durations[std::size_t(f)] = ms;
    anim.store(projectDir, d.json);
    return finish(projectDir, d, a, cmd,
                  Json::object({{"set", Json::object({{"first", first}, {"last", last}, {"duration", ms}})}}), {});
}

// ---- image.frame.cel -------------------------------------------------------------------------------------------------------------

Json frame_cel(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.frame.cel";
    check_arg_keys(cmd, a, "", {"path", "layer", "frame", "from", "clear", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    const int F = json_frame_count(d.json);
    const int frame = frame_number(cmd,
                                   need(a, cmd, "frame", "the frame whose picture changes",
                                        "Example: {\"layer\":\"hero\",\"frame\":3,\"from\":0}."),
                                   "/frame", F);
    LayerRef ref = find_layer(d.json,
                              need(a, cmd, "layer", "the layer, by name or index path",
                                   "Example: \"layer\":\"hero\". " + describe_layers(d.json, 12)),
                              cmd);
    const std::string kind = ref.layer->value("kind", std::string());
    if (kind != "pixels" && kind != "indexed")
        arg_error(
            cmd, "/layer",
            std::format("layer '{}' is a {} layer: only pixels and indexed layers have a picture per frame.",
                        ref.layer->value("name", ref.indexPath), kind),
            "Fills, gradients, text and the like show the same in every frame; animate them by adding pixels layers.");
    const bool hasFrom = a.contains("from") && !a["from"].is_null();
    const bool clear = arg_bool(a, "clear", false);
    if (hasFrom == clear)
        arg_error(cmd, hasFrom ? "/clear" : "/from",
                  "give either `from` (show the picture this layer has in that frame) or `clear: true` (show nothing).",
                  "Example: {\"layer\":\"hero\",\"frame\":3,\"from\":0}.");
    std::vector<CelData> cels = layer_cels(*ref.layer, F);
    if (hasFrom)
        cels[std::size_t(frame)] = cels[std::size_t(frame_number(cmd, a["from"], "/from", F, "from"))];
    else
        cels[std::size_t(frame)].empty = true;
    write_layer_cels(*ref.layer, cels, projectDir);
    Json extra = Json::object(
        {{"layer",
          Json::object({{"index", ref.indexPath}, {"name", ref.layer->value("name", std::string())}, {"kind", kind}})},
         {"frame", frame}});
    return finish(projectDir, d, a, cmd, extra, {});
}

// ---- image.frame.sheet -----------------------------------------------------------------------------------------------------------

Json frame_sheet(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.frame.sheet";
    check_arg_keys(cmd, a, "", {"path", "columns", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    if (!a.contains("columns"))
        arg_error(cmd, "/columns",
                  "`columns` is required: frames per row of the sheet, or null for the automatic grid.",
                  "Example: {\"columns\":4}.");
    if (a["columns"].is_null())
        d.json.erase("sheet");
    else {
        const int cols = whole_arg(a, cmd, "columns", 1, 1024, 1);
        d.json["sheet"] = Json::object({{"columns", cols}});
    }
    normalize_animation(d.json);
    return finish(projectDir, d, a, cmd, Json::object(), {});
}

// ---- image.tag.set / image.tag.remove --------------------------------------------------------------------------------------------

Json tag_set(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tag.set";
    check_arg_keys(cmd, a, "", {"path", "name", "from", "to", "direction", "repeat", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    const int F = json_frame_count(d.json);
    const Json& nameArg = need(a, cmd, "name", "the tag's name, which is also the clip name",
                               "Example: {\"name\":\"walk\",\"from\":0,\"to\":3}.");
    if (!nameArg.is_string() || nameArg.get<std::string>().empty())
        arg_error(cmd, "/name", "`name` must be a non-empty string, got " + describe_json_value(nameArg) + ".",
                  "It is the clip name a SpriteAnimator plays: \"walk\", \"idle\".");
    Tag t;
    t.name = nameArg.get<std::string>();
    std::vector<Tag> tags = read_tags(d.json);
    const Tag* existing = find_tag(tags, t.name);
    if (!existing && (!a.contains("from") || !a.contains("to")))
        arg_error(cmd, "/from", "a new tag needs `from` and `to`: its first and last frame.", "Example: {\"name\":\"" + t.name + "\",\"from\":0,\"to\":3}. Tags: " + (tags.empty() ? std::string("none yet") : [&] { std::vector<std::string> n; for (const Tag& x : tags) n.push_back(x.name); return join(n, ", "); }()) + ".");
    if (existing) t = *existing;
    if (a.contains("from") && !a["from"].is_null()) t.from = frame_number(cmd, a["from"], "/from", F, "from");
    if (a.contains("to") && !a["to"].is_null()) t.to = frame_number(cmd, a["to"], "/to", F, "to");
    if (t.from > t.to)
        arg_error(cmd, "/to", std::format("`to` {} is before `from` {}.", t.to, t.from),
                  "A tag runs from the lower frame to the higher one; `direction` plays it backwards.");
    if (a.contains("direction") && !a["direction"].is_null()) {
        const auto dirs = image_tag_direction_names();
        if (!a["direction"].is_string() ||
            std::find(dirs.begin(), dirs.end(), a["direction"].get<std::string>()) == dirs.end())
            arg_error(cmd, "/direction", "unknown direction " + describe_json_value(a["direction"]) + ".",
                      (a["direction"].is_string() ? did_you_mean(a["direction"].get<std::string>(), dirs) + " "
                                                  : std::string()) +
                          "Directions: " + join(dirs, ", ") + ".");
        t.direction = a["direction"].get<std::string>();
    }
    t.repeat = whole_arg(a, cmd, "repeat", 0, 1000, t.repeat);
    bool replaced = false;
    for (Tag& x : tags)
        if (x.name == t.name) {
            x = t;
            replaced = true;
        }
    if (!replaced) tags.push_back(t);
    if (F == 1 && !d.json.contains("frames")) d.json["frames"] = Json::array({Json::object({{"duration", 100}})});
    write_tags(d.json, tags);
    normalize_animation(d.json);
    return finish(projectDir, d, a, cmd, Json::object({{"tag", tag_json(t)}, {"replaced", replaced}}), {});
}

Json tag_remove(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tag.remove";
    check_arg_keys(cmd, a, "", {"path", "name", "bake"});
    DocFile d = open_anim(projectDir, a, cmd);
    const std::string name = arg_string(a, "name", true);
    std::vector<Tag> tags = read_tags(d.json);
    std::vector<std::string> names;
    for (const Tag& t : tags) names.push_back(t.name);
    if (!find_tag(tags, name))
        arg_error(cmd, "/name", "there is no tag named '" + name + "'.",
                  (names.empty() ? std::string("The document has no tags.")
                                 : did_you_mean(name, names) + " Tags: " + join(names, ", ") + "."));
    tags.erase(std::remove_if(tags.begin(), tags.end(), [&](const Tag& t) { return t.name == name; }), tags.end());
    write_tags(d.json, tags);
    normalize_animation(d.json);
    return finish(projectDir, d, a, cmd, Json::object({{"removed", name}}), {});
}

}  // namespace

void register_frame_commands(CommandRegistry& registry, const std::string& projectDir) {
    const std::string pathDoc = "The image document, project-relative, ending in .image.json.";
    const std::string bakeDoc =
        "Also bake the document to its sprite sheet (default true). False only writes the document.";
    auto add = [&](const char* name, const char* summary, const std::string& description, const std::string& props,
                   const char* required, Json (*fn)(const std::string&, const Json&)) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = false;
        info.summary = summary;
        info.description = description;
        info.inputSchema = Json::parse(
            std::string("{\"type\":\"object\",\"required\":[") + required +
            "],\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"}," + props +
            "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}");
        add_image_command(registry, info, [projectDir, fn](const Json& args) { return fn(projectDir, args); });
    };
    const std::string resultDoc =
        " Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, "
        "totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in "
        "`<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, "
        "\\\"Frames and tags\\\".";

    add("image.frame.add",
        "Add frames to an image document (making it an animation), copying a frame or blank, and keep the tags in "
        "place.",
        "Inserts `count` frames at `at` (0..number of frames; default: at the end). Each new frame shows what frame "
        "`from` shows (default the frame before `at`, or frame 0 when `at` is 0), "
        "or nothing with `blank: true`, on every pixels and indexed layer; layers of other kinds are the same in every "
        "frame. A document with no `frames` is one frame, so the first call makes it an animation "
        "(it then bakes to a sprite sheet next to the document). `duration` is the new frames' time in milliseconds "
        "(default: the copied frame's, 100 for a new animation). Tags after `at` move along; "
        "a tag the new frames land inside grows. Draw on a frame with image.pixel / image.draw / image.edit / "
        "image.paint and `frame`." +
            resultDoc +
            " Example: {\"path\":\"assets/art/hero.image.json\",\"count\":3} makes a 4-frame animation of the same "
            "picture.",
        "\"at\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"Where the new frames go (default: after the last "
        "frame). Existing frames from here on move up.\"},"
        "\"from\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"The frame the new frames copy (default: the "
        "frame before `at`).\"},"
        "\"blank\":{\"type\":\"boolean\",\"default\":false,\"description\":\"The new frames show nothing on pixels and "
        "indexed layers. Not with `from`.\"},"
        "\"count\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":256,\"default\":1,\"description\":\"How many frames "
        "to add.\"},"
        "\"duration\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":60000,\"description\":\"Milliseconds each new "
        "frame shows (default: the copied frame's).\"},",
        "\"path\"", frame_add);

    add("image.frame.remove", "Remove one frame of an animated image document; later frames and tags move down.",
        "Deletes frame `frame` from every layer and from `frames`. Tags after it move down; a tag that held the frame "
        "shrinks (a tag that was only that frame is removed, with a warning). "
        "The last frame cannot be removed; when one frame is left and there are no tags the document is a plain still "
        "image again." +
            resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"frame\":2}.",
        "\"frame\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"The frame to remove (0 = the first).\"},",
        "\"path\",\"frame\"", frame_remove);

    add("image.frame.move", "Move a frame to another place in the animation; tags follow their frames.",
        "Takes frame `frame` out and puts it back so that it is frame `to` (the frames in between shift by one), on "
        "every layer, with its duration. A tag keeps its frames; when the move leaves them "
        "not in one run, the tag covers the run from the first to the last and a warning says so." +
            resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"frame\":3,\"to\":0}.",
        "\"frame\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"The frame to move.\"},"
        "\"to\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"The place it ends up at.\"},",
        "\"path\",\"frame\",\"to\"", frame_move);

    add("image.frame.set", "Set how long frames show, in milliseconds.",
        "`frame` is one frame number, a range [first, last] (inclusive) or \"all\"; `duration` is the milliseconds "
        "each of them shows (1..60000). A clip of the baked sheet plays at one speed: tags whose "
        "frames have different durations get extra cells that spell the timing out (the bake warns when a duration "
        "cannot be kept exactly)." +
            resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"frame\":\"all\",\"duration\":80}.",
        "\"frame\":{\"description\":\"A frame number, a range [first, last] or \\\"all\\\".\"},"
        "\"duration\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":60000,\"description\":\"Milliseconds each of "
        "those frames shows (100 = 10 frames per second).\"},",
        "\"path\",\"frame\",\"duration\"", frame_set);

    add("image.frame.cel", "Make a layer show in one frame what it shows in another, or show nothing there.",
        "A pixels or indexed layer has a picture (cel) per frame. This sets the cel of `layer` in `frame`: `from` "
        "copies what the layer shows in that frame (the two frames share one file or one set of rows), "
        "`clear: true` shows nothing. Use it to reuse a pose (a walk cycle's legs) or hide a layer in some frames." +
            resultDoc +
            " Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"legs\",\"frame\":4,\"from\":0}.",
        "\"layer\":{\"description\":\"A pixels or indexed layer: its name or an index path like \\\"1/0\\\".\"},"
        "\"frame\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"The frame whose cel changes.\"},"
        "\"from\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"Show what the layer shows in this frame.\"},"
        "\"clear\":{\"type\":\"boolean\",\"description\":\"true: the layer shows nothing in `frame`. Not with "
        "`from`.\"},",
        "\"path\",\"layer\",\"frame\"", frame_cel);

    add("image.frame.sheet", "Choose how many frames the baked sprite sheet has per row.",
        "The bake of an animated document is a sprite sheet. `columns` sets the frames (cells) per row; null goes back "
        "to the automatic grid (about square). The cells are all the size of the canvas." +
            resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"columns\":8}.",
        "\"columns\":{\"description\":\"Cells per row (1..1024), or null for the automatic grid.\"},",
        "\"path\",\"columns\"", frame_sheet);

    add("image.tag.set", "Name a run of frames (a tag); the bake makes a SpriteAnimator clip of it.",
        "Creates the tag `name`, or changes it when it exists (omitted fields keep their value): frames `from` to `to` "
        "(inclusive), played in `direction` (forward, reverse, pingpong), `repeat` times "
        "(0 = the clip loops; N plays N times and stops). The bake writes the clip into the sheet entry of assets.json "
        "under that name, so a game plays it with SpriteAnimator `clip` or "
        "entity.spriteAnimator.play(name) with no other step. SpriteAnimator plays contiguous cells at one speed, so a "
        "tag that is reverse, ping-pong, repeated or has frames of different durations "
        "gets extra cells after the frames that spell its order out (image.info shows the sheet with its cells and "
        "clips). Tags may overlap. A still image becomes a one-frame animation." +
            resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"name\":\"walk\",\"from\":0,\"to\":3}.",
        "\"name\":{\"type\":\"string\",\"description\":\"The tag's name; also the clip name. Unique in the "
        "document.\"},"
        "\"from\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"First frame (required for a new tag).\"},"
        "\"to\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"Last frame, inclusive (required for a new "
        "tag).\"},"
        "\"direction\":{\"type\":\"string\",\"enum\":[\"forward\",\"reverse\",\"pingpong\"],\"description\":\"Play "
        "order (default forward). pingpong goes to the end and back without repeating the end frames.\"},"
        "\"repeat\":{\"type\":\"integer\",\"minimum\":0,\"maximum\":1000,\"description\":\"How many times it plays; 0 "
        "(default) loops for ever.\"},",
        "\"path\",\"name\"", tag_set);

    add("image.tag.remove", "Remove a tag (and so its clip) from an image document.",
        "Deletes the tag `name`; the frames stay. The next bake drops its clip from the sheet entry." + resultDoc +
            " Example: {\"path\":\"assets/art/hero.image.json\",\"name\":\"walk\"}.",
        "\"name\":{\"type\":\"string\",\"description\":\"The tag to remove.\"},", "\"path\",\"name\"", tag_remove);
}

}  // namespace fa::imgedit
