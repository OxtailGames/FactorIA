// The Vector panel's model (vector_model.h): the open SVG, the scene, the selection, the pen, snapping and the undo steps. Every edit is a
// vector.* command; this file builds their arguments from what the user did.
#include "vector_model.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/style_guide.h"
#include "inspector_model.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

std::optional<std::string> read_file(const stdfs::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return std::nullopt;
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

std::uint64_t mix(std::uint64_t h, std::uint64_t v) { return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL; }

double now_ms() {
    using clock = std::chrono::steady_clock;   // UI timing only: no simulation reads it
    return std::chrono::duration<double, std::milli>(clock::now().time_since_epoch()).count();
}

Json refs_json(const std::vector<std::string>& refs) {
    Json a = Json::array();
    for (const std::string& r : refs) a.push_back(r);
    return a;
}

Json point_json(VecPoint p) { return Json::array({p.x, p.y}); }

// The layer of an image document that `ref` names (an index path "1/0", or a name; "" = the only svg layer). Returns null when there is
// none; `path` is its index path.
const Json* find_svg_layer(const Json& doc, const std::string& ref, std::string& path, std::string& why) {
    if (!doc.is_object() || !doc.contains("layers") || !doc["layers"].is_array()) {
        why = "The document has no layers.";
        return nullptr;
    }
    std::vector<std::pair<std::string, const Json*>> svgs;
    std::function<void(const Json&, const std::string&)> walk = [&](const Json& layers, const std::string& prefix) {
        for (std::size_t i = 0; i < layers.size(); ++i) {
            const Json& l = layers[i];
            if (!l.is_object()) continue;
            const std::string p = prefix.empty() ? std::to_string(i) : prefix + "/" + std::to_string(i);
            if (l.value("kind", std::string()) == "svg") svgs.push_back({p, &l});
            if (l.contains("layers") && l["layers"].is_array()) walk(l["layers"], p);
        }
    };
    walk(doc["layers"], "");
    if (ref.empty()) {
        if (svgs.size() == 1) {
            path = svgs[0].first;
            return svgs[0].second;
        }
        why = svgs.empty() ? "The document has no svg layer." : "The document has several svg layers: name one.";
        return nullptr;
    }
    for (const auto& [p, l] : svgs)
        if (p == ref) {
            path = p;
            return l;
        }
    for (const auto& [p, l] : svgs)
        if (l->value("name", std::string()) == ref) {
            path = p;
            return l;
        }
    std::string names;
    for (const auto& [p, l] : svgs) names += (names.empty() ? "" : ", ") + std::string("\"") + l->value("name", p) + "\"";
    why = "The document has no svg layer \"" + ref + "\"." + (svgs.empty() ? " It has no svg layer at all." : " Its svg layers: " + names + ".");
    return nullptr;
}

double dist(VecPoint a, VecPoint b) { return std::hypot(a.x - b.x, a.y - b.y); }

}  // namespace

// ---- tools -----------------------------------------------------------------------------------------------------------------

const char* vector_tool_name(VectorTool tool) {
    switch (tool) {
        case VectorTool::Select: return "Select";
        case VectorTool::Node: return "Node";
        case VectorTool::Pen: return "Pen";
        case VectorTool::Rectangle: return "Rectangle";
        case VectorTool::Ellipse: return "Ellipse";
        case VectorTool::Line: return "Line";
        case VectorTool::Shape: return "Shape";
    }
    return "?";
}

const std::vector<VectorTool>& vector_tools() {
    static const std::vector<VectorTool> t = {VectorTool::Select, VectorTool::Node,    VectorTool::Pen, VectorTool::Rectangle,
                                              VectorTool::Ellipse, VectorTool::Line, VectorTool::Shape};
    return t;
}

// ---- construction, loading -------------------------------------------------------------------------------------------------

VectorModel::VectorModel(std::string projectDir, VectorCommandFn call) : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

std::string VectorModel::title() const {
    if (!is_open()) return "";
    return isLayer_ ? rel_ + " > " + layer_ : rel_;
}

bool VectorModel::open(const std::string& svgRel) {
    close();
    rel_ = svgRel;
    isLayer_ = false;
    status_.clear();
    load_from_disk();
    load_palette();
    return valid_;
}

void VectorModel::load_palette() {
    palette_.clear();
    const StyleParse sp = load_style_guide(projectDir_);
    if (!sp.guide.palette) return;
    for (const auto& c : *sp.guide.palette) {
        char buf[16];
        std::snprintf(buf, sizeof buf, "#%02x%02x%02x", c[0], c[1], c[2]);
        palette_.push_back(buf);
    }
}

bool VectorModel::open_layer(const std::string& documentRel, const std::string& layer) {
    close();
    rel_ = documentRel;
    layer_ = layer;
    isLayer_ = true;
    status_.clear();
    load_from_disk();
    load_palette();
    return valid_;
}

void VectorModel::close() {
    rel_.clear();
    layer_.clear();
    layerPath_.clear();
    layerSource_.clear();
    isLayer_ = false;
    error_.clear();
    valid_ = false;
    svg_.clear();
    shown_.clear();
    previewing_ = false;
    scene_ = VecScene{};
    selection_.clear();
    context_.clear();
    nodeSel_.clear();
    palette_.clear();
    pen_ = VectorPen{};
    stamp_ = 0;
    ++rev_;
}

bool VectorModel::read_text(std::string& svg, std::string& why) {
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        why = abs.error().message + (abs.error().hint.empty() ? "" : " " + abs.error().hint);
        return false;
    }
    auto data = read_file(*abs);
    if (!data) {
        why = "Cannot read " + rel_ + ": the file does not exist. Create it with a vector.* command or an editor.";
        return false;
    }
    if (!isLayer_) {
        svg = std::move(*data);
        return true;
    }
    auto doc = parse_json(*data, rel_);
    if (!doc.ok()) {
        why = doc.error().message + (doc.error().hint.empty() ? "" : " " + doc.error().hint);
        return false;
    }
    std::string path;
    const Json* l = find_svg_layer(*doc, layer_, path, why);
    if (!l) return false;
    layerPath_ = path;
    layerSource_.clear();
    if (l->contains("svg") && (*l)["svg"].is_string()) {
        svg = (*l)["svg"].get<std::string>();
        return true;
    }
    if (l->contains("source") && (*l)["source"].is_string()) {
        layerSource_ = (*l)["source"].get<std::string>();
        auto sabs = resolve_project_path(projectDir_, layerSource_);
        auto sdata = sabs.ok() ? read_file(*sabs) : std::nullopt;
        if (!sdata) {
            why = "Cannot read " + layerSource_ + ", the source of the svg layer.";
            return false;
        }
        svg = std::move(*sdata);
        return true;
    }
    why = "The svg layer has neither `svg` nor `source`.";
    return false;
}

std::set<std::string> VectorModel::tracked_paths() const {
    std::set<std::string> out;
    if (!rel_.empty()) out.insert(rel_);
    if (!layerSource_.empty()) out.insert(layerSource_);
    return out;
}

std::uint64_t VectorModel::compute_stamp() const {
    std::uint64_t h = 1469598103934665603ULL;
    for (const std::string& p : tracked_paths()) {
        auto abs = resolve_project_path(projectDir_, p);
        std::error_code ec;
        if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) continue;
        for (char c : p) h = mix(h, std::uint64_t(static_cast<unsigned char>(c)));
        h = mix(h, std::uint64_t(stdfs::file_size(*abs, ec)));
        h = mix(h, std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    }
    return h;
}

bool VectorModel::rescene(const std::string& text) {
    const double t0 = now_ms();
    auto sc = vector_scene(text);
    sceneMs_ = now_ms() - t0;
    ++rev_;
    if (!sc.ok()) {
        error_ = sc.error().message + (sc.error().hint.empty() ? "" : " " + sc.error().hint);
        return false;
    }
    scene_ = std::move(*sc);
    return true;
}

bool VectorModel::load_from_disk() {
    previewing_ = false;
    shown_.clear();
    std::string text, why;
    if (!read_text(text, why)) {
        valid_ = false;
        error_ = why;
        svg_.clear();
        scene_ = VecScene{};
        ++rev_;
        stamp_ = compute_stamp();
        return false;
    }
    svg_ = text;
    if (!rescene(svg_)) {
        valid_ = false;
        scene_ = VecScene{};
        stamp_ = compute_stamp();
        return false;
    }
    valid_ = true;
    error_.clear();
    // keep what still exists of the selection
    selection_.erase(std::remove_if(selection_.begin(), selection_.end(), [&](const std::string& r) { return scene_.find(r) < 0; }), selection_.end());
    if (!context_.empty() && scene_.find(context_) < 0) context_.clear();
    nodeSel_.erase(std::remove_if(nodeSel_.begin(), nodeSel_.end(), [&](const VectorNodeRef& n) { return scene_.find(n.shape) < 0; }), nodeSel_.end());
    stamp_ = compute_stamp();
    return true;
}

bool VectorModel::reload() {
    if (!is_open()) return false;
    pen_ = VectorPen{};
    return load_from_disk();
}

bool VectorModel::poll_external() {
    if (!is_open() || previewing_) return false;
    if (compute_stamp() == stamp_) return false;
    load_from_disk();
    return true;
}

Result<Image> VectorModel::rasterize(const VecRect* region, int width, int height) {
    if (!valid_) return Error{"The SVG does not load: " + error_, "Fix it, then Reload."};
    const double t0 = now_ms();
    auto r = vector_rasterize(svg(), region, width, height);
    rasterMs_ = now_ms() - t0;
    return r;
}

// ---- selection -------------------------------------------------------------------------------------------------------------

std::vector<int> VectorModel::selected_items() const {
    std::vector<int> out;
    for (const std::string& r : selection_)
        if (int i = scene_.find(r); i >= 0) out.push_back(i);
    return out;
}

bool VectorModel::is_selected(const std::string& ref) const { return std::find(selection_.begin(), selection_.end(), ref) != selection_.end(); }

void VectorModel::select(const std::vector<std::string>& refs) {
    selection_.clear();
    for (const std::string& r : refs)
        if (scene_.find(r) >= 0 && !is_selected(r)) selection_.push_back(r);
    nodeSel_.clear();
}

void VectorModel::toggle_selected(const std::string& ref) {
    auto it = std::find(selection_.begin(), selection_.end(), ref);
    if (it != selection_.end()) selection_.erase(it);
    else if (scene_.find(ref) >= 0) selection_.push_back(ref);
}

void VectorModel::add_to_selection(const std::string& ref) {
    if (scene_.find(ref) >= 0 && !is_selected(ref)) selection_.push_back(ref);
}

void VectorModel::clear_selection() {
    selection_.clear();
    nodeSel_.clear();
}

void VectorModel::select_all() {
    selection_.clear();
    nodeSel_.clear();
    const int ctx = scene_.find(context_);
    for (const VecItem& it : scene_.items) {
        if (it.parent != ctx || it.hidden || it.locked) continue;
        selection_.push_back(it.ref);
    }
}

bool VectorModel::selection_bounds(VecRect& out, bool visual) const {
    bool has = false;
    for (int i : selected_items()) {
        const VecItem& it = scene_.items[std::size_t(i)];
        if (!it.hasBounds) continue;
        const VecRect b = visual ? it.visualBounds : it.bounds;
        if (!has) {
            out = b;
            has = true;
        } else {
            out.x0 = std::min(out.x0, b.x0);
            out.y0 = std::min(out.y0, b.y0);
            out.x1 = std::max(out.x1, b.x1);
            out.y1 = std::max(out.y1, b.y1);
        }
    }
    return has;
}

void VectorModel::enter_group(const std::string& ref) {
    const int i = scene_.find(ref);
    if (i < 0 || !scene_.items[std::size_t(i)].isGroup) return;
    context_ = ref;
    selection_.clear();
    nodeSel_.clear();
}

void VectorModel::leave_group() {
    const int ctx = scene_.find(context_);
    context_.clear();
    selection_.clear();
    nodeSel_.clear();
    if (ctx >= 0) {
        const int parent = scene_.items[std::size_t(ctx)].parent;
        if (parent >= 0) context_ = scene_.items[std::size_t(parent)].ref;
        selection_.push_back(scene_.items[std::size_t(ctx)].ref);
    }
}

int VectorModel::pick(VecPoint p, double tolerance) const {
    const int hit = vector_hit_test(scene_, p, tolerance, true);
    if (hit < 0) return -1;
    return scene_.pick_in_context(hit, scene_.find(context_));
}

std::vector<int> VectorModel::marquee(const VecRect& box, bool touch) const {
    std::vector<int> out;
    const int ctx = scene_.find(context_);
    for (int hit : vector_shapes_in_rect(scene_, box, touch, true)) {
        const int level = scene_.pick_in_context(hit, ctx);
        if (level >= 0 && std::find(out.begin(), out.end(), level) == out.end()) out.push_back(level);
    }
    return out;
}

void VectorModel::toggle_node(const VectorNodeRef& n) {
    auto it = std::find(nodeSel_.begin(), nodeSel_.end(), n);
    if (it != nodeSel_.end()) nodeSel_.erase(it);
    else nodeSel_.push_back(n);
}

bool VectorModel::node_selected(const VectorNodeRef& n) const { return std::find(nodeSel_.begin(), nodeSel_.end(), n) != nodeSel_.end(); }

const VecNodePath* VectorModel::nodes_of(const std::string& ref) const {
    const int i = scene_.find(ref);
    if (i < 0) return nullptr;
    const VecItem& it = scene_.items[std::size_t(i)];
    return it.isGroup || !it.problem.empty() ? nullptr : &it.nodes;
}

// ---- files and undo steps --------------------------------------------------------------------------------------------------

VectorBlob VectorModel::blob_of(const std::string& rel) {
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        fileCache_.erase(rel);
        return nullptr;
    }
    auto data = read_file(*abs);
    if (!data) return nullptr;
    auto it = fileCache_.find(rel);
    if (it != fileCache_.end() && it->second && *it->second == *data) return it->second;
    VectorBlob blob = std::make_shared<const std::string>(std::move(*data));
    fileCache_[rel] = blob;
    return blob;
}

VectorFileSet VectorModel::capture(const std::set<std::string>& paths) {
    VectorFileSet out;
    for (const std::string& p : paths) out[p] = blob_of(p);
    return out;
}

bool VectorModel::restore(const VectorFileSet& files) {
    for (const auto& [rel, blob] : files) {
        auto abs = resolve_project_path(projectDir_, rel);
        if (!abs.ok()) {
            note_error(abs.error().message);
            return false;
        }
        std::error_code ec;
        if (!blob) {
            stdfs::remove(*abs, ec);
        } else {
            std::ofstream f(*abs, std::ios::binary | std::ios::trunc);
            if (!f || !f.write(blob->data(), std::streamsize(blob->size()))) {
                note_error("Cannot write " + rel + ".");
                return false;
            }
        }
        fileCache_.erase(rel);
    }
    return true;
}

void VectorModel::note_error(const std::string& m) {
    status_ = m;
    error_ = error_.empty() || valid_ ? error_ : error_;
}

VectorEditOutcome VectorModel::fail(VectorEditOutcome out, const std::string& message) {
    out.ok = false;
    out.error = message;
    status_ = message;
    return out;
}

Json VectorModel::target_args() const {
    Json a = Json::object();
    if (isLayer_) {
        a["document"] = rel_;
        a["layer"] = layerPath_.empty() ? layer_ : layerPath_;
        a["bake"] = false;
    } else {
        a["source"] = rel_;
    }
    return a;
}

void VectorModel::remap(const std::map<std::string, std::string>& mapping) {
    auto fix = [&](std::string& s) {
        auto it = mapping.find(s);
        if (it != mapping.end()) s = it->second;
    };
    for (std::string& s : selection_) fix(s);
    fix(context_);
    for (VectorNodeRef& n : nodeSel_) fix(n.shape);
}

// Gives an id to every element `args` (and the selection) name by a selector, so the refs stay valid through the edit.
bool VectorModel::resolve_ids(Json& args, std::string& error) {
    std::set<std::string> need;
    auto consider = [&](const std::string& ref) {
        if (ref.empty() || ref == "root") return;
        const int i = scene_.find(ref);
        if (i >= 0 && scene_.items[std::size_t(i)].id.empty()) need.insert(ref);
    };
    static const char* kKeys[] = {"elements", "element", "parent", "before", "replace"};
    for (const char* k : kKeys) {
        if (!args.is_object() || !args.contains(k)) continue;
        const Json& v = args[k];
        if (v.is_string()) consider(v.get<std::string>());
        else if (v.is_array())
            for (const Json& e : v)
                if (e.is_string()) consider(e.get<std::string>());
    }
    if (need.empty()) return true;
    for (const std::string& s : selection_) consider(s);
    consider(context_);
    Json a = target_args();
    a["elements"] = refs_json(std::vector<std::string>(need.begin(), need.end()));
    a["preview"] = false;
    CommandResult r = call_("vector.assign_ids", a);
    if (!r.ok) {
        error = "Giving the elements ids: " + command_error_text(r.error);
        return false;
    }
    std::map<std::string, std::string> mapping;
    if (r.result.contains("assigned") && r.result["assigned"].is_array())
        for (const Json& e : r.result["assigned"])
            if (e.is_object() && e.contains("selector") && e.contains("id")) mapping[e["selector"].get<std::string>()] = e["id"].get<std::string>();
    remap(mapping);
    auto fixv = [&](Json& v) {
        if (v.is_string()) {
            auto it = mapping.find(v.get<std::string>());
            if (it != mapping.end()) v = it->second;
        }
    };
    for (const char* k : kKeys) {
        if (!args.contains(k)) continue;
        if (args[k].is_array())
            for (Json& e : args[k]) fixv(e);
        else
            fixv(args[k]);
    }
    return true;
}

VectorEditOutcome VectorModel::edit(const std::string& label, const std::string& command, Json args) {
    VectorEditOutcome out;
    if (!valid_) return fail(out, "The SVG does not load" + (error_.empty() ? std::string(".") : ": " + error_));
    if (previewing_) cancel_preview();
    const std::set<std::string> paths = tracked_paths();
    VectorFileSet before = capture(paths);
    auto rollback = [&](const std::string& message) {
        restore(before);
        load_from_disk();
        return fail(out, message);
    };
    std::string err;
    if (!resolve_ids(args, err)) return rollback(label + ": " + err);
    Json a = args;
    const Json target = target_args();   // a local: a range-for over a temporary's items() would read freed memory
    for (auto& [k, v] : target.items()) a[k] = v;
    a["preview"] = false;
    CommandResult r = call_(command, a);
    if (!r.ok) return rollback(label + ": " + command_error_text(r.error));
    out.result = r.result;
    if (!load_from_disk()) return rollback(label + ": the SVG no longer loads (" + error_ + ").");
    std::set<std::string> now = paths;
    for (const std::string& p : tracked_paths()) now.insert(p);
    VectorFileSet after = capture(now);
    for (const std::string& p : now)
        if (!before.count(p)) before[p] = nullptr;
    for (auto it = before.begin(); it != before.end();) {
        auto f = after.find(it->first);
        const bool same = f != after.end() && (f->second == it->second || (f->second && it->second && *f->second == *it->second));
        if (same) {
            after.erase(f);
            it = before.erase(it);
        } else {
            ++it;
        }
    }
    if (!after.empty() || !before.empty()) {
        VectorStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.layer = isLayer_ ? layer_ : std::string();
        s.label = label;
        s.before = std::move(before);
        s.after = std::move(after);
        for (const auto& [p, b] : s.before)
            if (!s.after.count(p)) s.after[p] = blob_of(p);
        for (const auto& [p, b] : s.after)
            if (!s.before.count(p)) s.before[p] = nullptr;
        out.step = s.id;
        steps_[s.id] = std::move(s);
    }
    status_ = label;
    return out;
}

VectorEditOutcome VectorModel::edit_selection(const std::string& label, const std::string& command, Json args) {
    if (selection_.empty()) {
        VectorEditOutcome out;
        return fail(out, label + ": nothing is selected. Click a shape first.");
    }
    if (!args.is_object()) args = Json::object();
    args["elements"] = refs_json(selection_);
    return edit(label, command, std::move(args));
}

bool VectorModel::preview_edit(const std::string& command, Json args) {
    if (!valid_) return false;
    Json a = args;
    a["svg"] = svg_;
    a["dryRun"] = true;
    a["preview"] = false;
    CommandResult r = call_(command, a);
    if (!r.ok) {
        status_ = command_error_text(r.error);
        return false;
    }
    if (!r.result.contains("svg") || !r.result["svg"].is_string()) return false;
    shown_ = r.result["svg"].get<std::string>();
    previewing_ = true;
    previewCommand_ = command;
    previewArgs_ = std::move(args);
    if (!rescene(shown_)) {
        previewing_ = false;
        shown_.clear();
        return false;
    }
    return true;
}

VectorEditOutcome VectorModel::commit_preview(const std::string& label) {
    VectorEditOutcome out;
    if (!previewing_) return out;
    const std::string cmd = previewCommand_;
    Json args = previewArgs_;
    previewing_ = false;
    shown_.clear();
    return edit(label, cmd, std::move(args));
}

void VectorModel::cancel_preview() {
    if (!previewing_) return;
    previewing_ = false;
    shown_.clear();
    rescene(svg_);
}

// ---- the common edits ------------------------------------------------------------------------------------------------------

VectorEditOutcome VectorModel::move_selection(double dx, double dy) {
    return edit_selection("Move", "vector.transform", Json::object({{"translate", Json::array({dx, dy})}}));
}

VectorEditOutcome VectorModel::delete_selection() {
    VectorEditOutcome out = edit_selection("Delete", "vector.delete");
    if (out.ok) clear_selection();
    return out;
}

VectorEditOutcome VectorModel::duplicate_selection(double dx, double dy) {
    Json args = Json::object();
    if (dx != 0 || dy != 0) args["offset"] = Json::array({dx, dy});
    VectorEditOutcome out = edit_selection("Duplicate", "vector.duplicate", args);
    if (out.ok && out.result.contains("copies")) {
        std::vector<std::string> copies;
        for (const Json& c : out.result["copies"])
            if (c.is_object() && c.contains("to")) copies.push_back(c["to"].get<std::string>());
        select(copies);
    }
    return out;
}

VectorEditOutcome VectorModel::group_selection() {
    VectorEditOutcome out = edit_selection("Group", "vector.group");
    if (out.ok && out.result.contains("element")) select({out.result["element"].get<std::string>()});
    return out;
}

VectorEditOutcome VectorModel::ungroup_selection() {
    VectorEditOutcome out = edit_selection("Ungroup", "vector.ungroup");
    if (out.ok && out.result.contains("children")) {
        std::vector<std::string> kids;
        for (const Json& c : out.result["children"])
            if (c.is_string()) kids.push_back(c.get<std::string>());
        select(kids);
    }
    return out;
}

VectorEditOutcome VectorModel::set_style(const Json& props, const std::string& label) {
    return edit_selection(label, "vector.set", props);
}

VectorEditOutcome VectorModel::set_hidden(const std::string& ref, bool hidden) {
    return edit(hidden ? "Hide" : "Show", "vector.set", Json::object({{"elements", Json::array({ref})}, {"hidden", hidden}}));
}

VectorEditOutcome VectorModel::set_locked(const std::string& ref, bool locked) {
    VectorEditOutcome out = edit(locked ? "Lock" : "Unlock", "vector.set", Json::object({{"elements", Json::array({ref})}, {"locked", locked}}));
    if (out.ok && locked) selection_.erase(std::remove(selection_.begin(), selection_.end(), ref), selection_.end());
    return out;
}

VectorEditOutcome VectorModel::rename(const std::string& ref, const std::string& id) {
    const bool wasSelected = is_selected(ref);
    VectorEditOutcome out = edit("Rename", "vector.set", Json::object({{"elements", Json::array({ref})}, {"id", id}}));
    if (out.ok) {
        std::map<std::string, std::string> m{{ref, id}};
        remap(m);
        if (wasSelected && !is_selected(id) && scene_.find(id) >= 0) selection_.push_back(id);
    }
    return out;
}

VectorEditOutcome VectorModel::reorder(const std::vector<std::string>& refs, const std::string& to) {
    return edit("Reorder", "vector.reorder", Json::object({{"elements", refs_json(refs)}, {"to", to}}));
}

VectorEditOutcome VectorModel::regroup(const std::vector<std::string>& refs, const std::string& parent, const std::string& before) {
    Json args = Json::object({{"elements", refs_json(refs)}, {"parent", parent.empty() ? std::string("root") : parent}});
    if (!before.empty()) args["before"] = before;
    return edit("Move to group", "vector.reorder", args);
}

VectorEditOutcome VectorModel::boolean_op(const std::string& op) {
    VectorEditOutcome out = edit_selection("Boolean " + op, "vector.boolean", Json::object({{"op", op}}));
    if (out.ok && out.result.contains("result") && out.result["result"].is_string()) select({out.result["result"].get<std::string>()});
    return out;
}

namespace {

Json style_args(const VectorStyle& s, bool closed) {
    Json a = Json::object();
    if (closed) {
        a["fill"] = s.fill;
        if (s.useStroke) {
            a["stroke"] = s.stroke;
            a["strokeWidth"] = s.strokeWidth;
        }
    } else {
        a["fill"] = "none";
        a["stroke"] = s.useStroke || s.stroke != "none" ? s.stroke : s.fill;
        a["strokeWidth"] = s.strokeWidth;
    }
    return a;
}

}  // namespace

VectorEditOutcome VectorModel::add_rect(VecPoint a, VecPoint b) {
    VectorEditOutcome out;
    const double x = std::min(a.x, b.x), y = std::min(a.y, b.y), w = std::abs(a.x - b.x), h = std::abs(a.y - b.y);
    if (w < 1e-3 || h < 1e-3) return fail(out, "Rectangle: drag a box with a width and a height.");
    Json args = style_args(style, true);
    args["kind"] = "rect";
    args["x"] = x;
    args["y"] = y;
    args["width"] = w;
    args["height"] = h;
    if (!context_.empty()) args["parent"] = context_;
    out = edit("Add rectangle", "vector.add", args);
    if (out.ok && out.result.contains("element")) select({out.result["element"].get<std::string>()});
    return out;
}

VectorEditOutcome VectorModel::add_ellipse(VecPoint a, VecPoint b) {
    VectorEditOutcome out;
    const double rx = std::abs(a.x - b.x) / 2, ry = std::abs(a.y - b.y) / 2;
    if (rx < 1e-3 || ry < 1e-3) return fail(out, "Ellipse: drag a box with a width and a height.");
    Json args = style_args(style, true);
    args["kind"] = "ellipse";
    args["center"] = point_json({(a.x + b.x) / 2, (a.y + b.y) / 2});
    args["rx"] = rx;
    args["ry"] = ry;
    if (!context_.empty()) args["parent"] = context_;
    out = edit("Add ellipse", "vector.add", args);
    if (out.ok && out.result.contains("element")) select({out.result["element"].get<std::string>()});
    return out;
}

VectorEditOutcome VectorModel::add_line(VecPoint a, VecPoint b) {
    VectorEditOutcome out;
    if (dist(a, b) < 1e-3) return fail(out, "Line: drag from one point to another.");
    Json args = style_args(style, false);
    args["kind"] = "line";
    args["from"] = point_json(a);
    args["to"] = point_json(b);
    if (!context_.empty()) args["parent"] = context_;
    out = edit("Add line", "vector.add", args);
    if (out.ok && out.result.contains("element")) select({out.result["element"].get<std::string>()});
    return out;
}

VectorEditOutcome VectorModel::add_shape(const std::string& kind, VecPoint a, VecPoint b, const Json& params) {
    VectorEditOutcome out;
    const double w = std::abs(a.x - b.x), h = std::abs(a.y - b.y);
    if (w < 1e-3 && h < 1e-3) return fail(out, "Shape: drag a box to size the shape.");
    Json args = params.is_object() ? params : Json::object();
    const VecPoint c{(a.x + b.x) / 2, (a.y + b.y) / 2};
    if (kind == "arrow") {
        args["from"] = point_json(a);
        args["to"] = point_json(b);
    } else if (kind == "bubble" || kind == "ribbon") {
        args["center"] = point_json(c);
        args["width"] = std::max(w, 1e-3);
        args["height"] = std::max(h, 1e-3);
    } else {
        args["center"] = point_json(c);
        args["radius"] = std::max(std::min(w, h), std::max(w, h) * 0.2) / 2;
    }
    args["kind"] = kind;
    if (kind != "ribbon") args["parametric"] = true;
    args["fill"] = style.fill;
    if (style.useStroke) {
        args["stroke"] = style.stroke;
        args["strokeWidth"] = style.strokeWidth;
    }
    if (!context_.empty()) args["parent"] = context_;
    out = edit("Add " + kind, "vector.shape", args);
    if (out.ok && out.result.contains("element")) select({out.result["element"].get<std::string>()});
    return out;
}

VectorEditOutcome VectorModel::set_shape_args(const std::string& ref, const std::string& kind, const Json& params) {
    Json args = params.is_object() ? params : Json::object();
    args["kind"] = kind;
    args["replace"] = ref;
    args["parametric"] = true;
    return edit("Change " + kind, "vector.shape", args);
}

bool VectorModel::preview_shape_args(const std::string& ref, const std::string& kind, const Json& params) {
    Json args = params.is_object() ? params : Json::object();
    args["kind"] = kind;
    args["replace"] = ref;
    args["parametric"] = true;
    return preview_edit("vector.shape", args);
}

VectorEditOutcome VectorModel::node_ops(const std::string& shape, const Json& ops, const std::string& label) {
    return edit(label, "vector.nodes", Json::object({{"element", shape}, {"ops", ops}}));
}

bool VectorModel::preview_node_ops(const std::string& shape, const Json& ops) {
    return preview_edit("vector.nodes", Json::object({{"element", shape}, {"ops", ops}}));
}

// ---- the pen ---------------------------------------------------------------------------------------------------------------

bool VectorModel::pen_press(VecPoint p, double tolerance) {
    if (!pen_.active) {
        pen_ = VectorPen{};
        pen_.active = true;
        pen_.path.push_back(VecSubpath{});
    }
    VecSubpath& sub = pen_.path[0];
    // a press on the first node closes the path (two nodes at least)
    if (sub.nodes.size() >= 2 && !sub.closed && dist(p, sub.nodes[0].p) <= tolerance) {
        pen_.dragging = false;
        return true;
    }
    VecNode n;
    n.p = p;
    sub.nodes.push_back(n);
    pen_.dragging = true;
    return false;
}

void VectorModel::pen_drag(VecPoint p) {
    if (!pen_.active || !pen_.dragging || pen_.path.empty() || pen_.path[0].nodes.empty()) return;
    VecNode& n = pen_.path[0].nodes.back();
    if (dist(p, n.p) < 1e-6) {
        n.hasIn = n.hasOut = false;
        return;
    }
    n.out = p;
    n.in = {2 * n.p.x - p.x, 2 * n.p.y - p.y};
    n.hasIn = n.hasOut = true;
}

void VectorModel::pen_release() { pen_.dragging = false; }

bool VectorModel::pen_continue(const std::string& shape, int subpath, bool atEnd) {
    const VecNodePath* nodes = nodes_of(shape);
    if (!nodes || subpath < 0 || subpath >= int(nodes->size())) return false;
    const VecSubpath& sub = (*nodes)[std::size_t(subpath)];
    if (sub.closed || sub.nodes.empty()) return false;
    pen_ = VectorPen{};
    pen_.active = true;
    pen_.continueShape = shape;
    pen_.continueSubpath = subpath;
    pen_.continueAtEnd = atEnd;
    VecSubpath work = sub;
    if (!atEnd) {
        std::reverse(work.nodes.begin(), work.nodes.end());
        for (VecNode& n : work.nodes) {
            std::swap(n.in, n.out);
            std::swap(n.hasIn, n.hasOut);
        }
    }
    pen_.existing = int(work.nodes.size());
    pen_.path.push_back(std::move(work));
    return true;
}

bool VectorModel::pen_can_finish() const {
    if (!pen_.active || pen_.path.empty()) return false;
    const int count = int(pen_.path[0].nodes.size());
    return pen_.continueShape.empty() ? count >= 2 : count > pen_.existing;
}

void VectorModel::pen_cancel() { pen_ = VectorPen{}; }

VectorEditOutcome VectorModel::pen_finish(bool close) {
    VectorEditOutcome out;
    if (!pen_.active || pen_.path.empty()) return fail(out, "Pen: there is no path being drawn.");
    const VectorPen pen = pen_;
    VecSubpath sub = pen.path[0];
    if (pen.continueShape.empty()) {
        if (sub.nodes.size() < 2) {
            pen_ = VectorPen{};
            return fail(out, "Pen: a path needs at least two nodes. Click twice or more.");
        }
        if (sub.nodes.size() < 3) close = false;
        sub.closed = close;
        VecNodePath path{sub};
        Json args = style_args(style, close);
        args["kind"] = "path";
        args["d"] = vector_nodes_to_d(path, 3);
        if (!context_.empty()) args["parent"] = context_;
        pen_ = VectorPen{};
        out = edit("Draw path", "vector.add", args);
        if (out.ok && out.result.contains("element")) select({out.result["element"].get<std::string>()});
        return out;
    }
    Json ops = Json::array();
    if (!pen.continueAtEnd) ops.push_back(Json::object({{"op", "reverse"}, {"subpath", pen.continueSubpath}}));
    for (std::size_t i = std::size_t(pen.existing); i < sub.nodes.size(); ++i) {
        Json op = Json::object({{"op", "append"}, {"subpath", pen.continueSubpath}, {"at", point_json(sub.nodes[i].p)}});
        if (sub.nodes[i].hasOut) op["out"] = point_json(sub.nodes[i].out);
        ops.push_back(op);
    }
    if (close) ops.push_back(Json::object({{"op", "close"}, {"subpath", pen.continueSubpath}}));
    // the path keeps its direction: what was reversed to grow its start is turned back
    if (!pen.continueAtEnd) ops.push_back(Json::object({{"op", "reverse"}, {"subpath", pen.continueSubpath}}));
    pen_ = VectorPen{};
    out = node_ops(pen.continueShape, ops, "Continue path");
    if (out.ok) select({pen.continueShape});
    return out;
}

// ---- snapping --------------------------------------------------------------------------------------------------------------

namespace {

struct SnapHit {
    bool x = false, y = false;
    VectorSnapKind kx = VectorSnapKind::None, ky = VectorSnapKind::None;
    VecPoint p;
};

}  // namespace

VecPoint VectorModel::snap_point(VecPoint p, double tolerance, const std::vector<std::string>& exclude, VectorSnapKind* kind) const {
    if (kind) *kind = VectorSnapKind::None;
    // the points: nodes and corners of the shapes that stay where they are, and the canvas
    if (snapping.points) {
        std::vector<char> skip(scene_.items.size(), 0);
        for (const std::string& r : exclude)
            if (int i = scene_.find(r); i >= 0) skip[std::size_t(i)] = 1;
        double best = tolerance;
        bool found = false;
        VecPoint hit;
        auto offer = [&](VecPoint c) {
            const double d = dist(p, c);
            if (d <= best) {
                best = d;
                hit = c;
                found = true;
            }
        };
        const VecRect cv = scene_.canvas;
        for (VecPoint c : {VecPoint{cv.x0, cv.y0}, VecPoint{cv.x1, cv.y0}, VecPoint{cv.x0, cv.y1}, VecPoint{cv.x1, cv.y1}, cv.center()}) offer(c);
        for (const VecItem& it : scene_.items) {
            bool skipped = skip[std::size_t(it.index)] != 0;
            for (int a = it.parent; !skipped && a >= 0; a = scene_.items[std::size_t(a)].parent) skipped = skip[std::size_t(a)] != 0;
            if (skipped || it.isGroup || !it.hasBounds || it.hidden || it.hiddenByAncestor) continue;
            const VecRect b = it.bounds;
            if (p.x < b.x0 - tolerance || p.x > b.x1 + tolerance || p.y < b.y0 - tolerance || p.y > b.y1 + tolerance) continue;
            for (const VecSubpath& s : it.nodes)
                for (const VecNode& n : s.nodes) offer(n.p);
            for (VecPoint c : {VecPoint{b.x0, b.y0}, VecPoint{b.x1, b.y0}, VecPoint{b.x0, b.y1}, VecPoint{b.x1, b.y1}, b.center()}) offer(c);
        }
        if (found) {
            if (kind) *kind = VectorSnapKind::Point;
            return hit;
        }
    }
    VecPoint out = p;
    VectorSnapKind k = VectorSnapKind::None;
    auto axis = [&](double v, const std::vector<double>& guides, double& result) {
        double best = tolerance;
        bool got = false;
        VectorSnapKind kk = VectorSnapKind::None;
        if (snapping.guides)
            for (double g : guides)
                if (std::abs(v - g) <= best) {
                    best = std::abs(v - g);
                    result = g;
                    got = true;
                    kk = VectorSnapKind::Guide;
                }
        if (snapping.grid && snapping.gridSize > 1e-9) {
            const double g = std::round(v / snapping.gridSize) * snapping.gridSize;
            if (std::abs(v - g) <= best) {
                result = g;
                got = true;
                kk = VectorSnapKind::Grid;
            }
        }
        if (got && k == VectorSnapKind::None) k = kk;
        return got;
    };
    axis(p.x, guidesX, out.x);
    axis(p.y, guidesY, out.y);
    if (kind) *kind = k;
    return out;
}

VecPoint VectorModel::snap_move(const VecRect& box, VecPoint delta, double tolerance, const std::vector<std::string>& exclude) const {
    // Each of the nine points of the box tries to land on a target; the nearest correction wins, per axis.
    double bestX = 1e300, bestY = 1e300;
    VecPoint corr{0, 0};
    const VecPoint c = box.center();
    const double xs[3] = {box.x0, c.x, box.x1}, ys[3] = {box.y0, c.y, box.y1};
    for (double x : xs)
        for (double y : ys) {
            const VecPoint q{x + delta.x, y + delta.y};
            VectorSnapKind kind;
            const VecPoint s = snap_point(q, tolerance, exclude, &kind);
            if (kind == VectorSnapKind::None) continue;
            const double dx = s.x - q.x, dy = s.y - q.y;
            if (std::abs(dx) <= tolerance && std::abs(dx) < bestX && (kind == VectorSnapKind::Point || std::abs(dx) > 0 || s.x == q.x)) {
                if (kind == VectorSnapKind::Point || std::abs(dx) > 0) {
                    bestX = std::abs(dx);
                    corr.x = dx;
                }
            }
            if (std::abs(dy) <= tolerance && std::abs(dy) < bestY) {
                if (kind == VectorSnapKind::Point || std::abs(dy) > 0) {
                    bestY = std::abs(dy);
                    corr.y = dy;
                }
            }
        }
    return {delta.x + corr.x, delta.y + corr.y};
}

// ---- saving, undo ----------------------------------------------------------------------------------------------------------

VectorEditOutcome VectorModel::save() {
    VectorEditOutcome out;
    if (!is_open()) return fail(out, "Nothing is open.");
    if (!isLayer_) {
        status_ = "Every edit is already written to " + rel_ + ".";
        return out;
    }
    // image.save takes the document itself: the edits are on disk already, so read it from there
    auto abs = resolve_project_path(projectDir_, rel_);
    auto data = abs.ok() ? read_file(*abs) : std::nullopt;
    if (!data) return fail(out, "Save: cannot read " + rel_ + ". Does the image document still exist?");
    auto doc = parse_json(*data, rel_);
    if (!doc.ok()) return fail(out, "Save: " + doc.error().message + (doc.error().hint.empty() ? "" : " " + doc.error().hint));
    CommandResult r = call_("image.save", Json::object({{"path", rel_}, {"document", *doc}, {"bake", true}}));
    if (!r.ok) return fail(out, "Save: " + command_error_text(r.error));
    out.result = r.result;
    status_ = "Saved " + rel_ + (r.result.contains("output") && r.result["output"].is_string() ? " and baked " + r.result["output"].get<std::string>() : std::string());
    stamp_ = compute_stamp();
    return out;
}

const VectorStep* VectorModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string VectorModel::step_document(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? std::string() : it->second.rel;
}

std::string VectorModel::step_layer(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? std::string() : it->second.layer;
}

bool VectorModel::apply_step(int id, bool forward) {
    auto it = steps_.find(id);
    if (it == steps_.end()) {
        note_error("That vector edit is no longer remembered.");
        return false;
    }
    const VectorStep& s = it->second;
    if (!restore(forward ? s.after : s.before)) return false;
    pen_ = VectorPen{};
    if (s.rel == rel_) load_from_disk();
    status_ = std::string(forward ? "Redo: " : "Undo: ") + s.label;
    return true;
}

void VectorModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) {
        if (keep.count(it->first)) ++it;
        else it = steps_.erase(it);
    }
}

}  // namespace fa::editor
