// The Model panel's model (modeler_model.h): the open model document, its operation tree, the mesh the viewport draws and the undo steps.
// Every edit is a model.edit call; this file builds their arguments from what the user did.
#include "modeler_model.h"

#include <algorithm>
#include <chrono>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
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

std::uint64_t mix_hash(std::uint64_t h, std::uint64_t v) { return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL; }

double now_ms() {
    using clock = std::chrono::steady_clock;  // UI timing only: no simulation reads it
    return std::chrono::duration<double, std::milli>(clock::now().time_since_epoch()).count();
}

bool ends_with_(const std::string& s, const std::string& suffix) { return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0; }

// The node at "/nodes/0/children/1" in the document's JSON (nullptr when the path leads nowhere).
const Json* walk(const Json& root, const std::string& pointer) {
    if (pointer.empty() || pointer[0] != '/') return nullptr;
    const Json* at = &root;
    std::size_t i = 1;
    while (i <= pointer.size()) {
        const std::size_t next = pointer.find('/', i);
        const std::string seg = pointer.substr(i, next == std::string::npos ? std::string::npos : next - i);
        if (at->is_array()) {
            if (seg.empty() || seg.find_first_not_of("0123456789") != std::string::npos) return nullptr;
            const std::size_t k = std::stoul(seg);
            if (k >= at->size()) return nullptr;
            at = &(*at)[k];
        } else if (at->is_object()) {
            if (!at->contains(seg)) return nullptr;
            at = &(*at)[seg];
        } else {
            return nullptr;
        }
        if (next == std::string::npos) break;
        i = next + 1;
    }
    return at;
}

Json* walk_mut(Json& root, const std::string& pointer) { return const_cast<Json*>(walk(root, pointer)); }

void collect_rows(const std::vector<ModelNode>& nodes, int depth, const Json& catalog, std::vector<ModelerRow>& out) {
    for (const ModelNode& n : nodes) {
        ModelerRow r;
        r.pointer = n.pointer;
        r.id = n.id;
        r.op = n.op;
        r.part = n.part.value_or(std::string());
        r.depth = depth;
        r.enabled = n.enabled;
        r.childCount = n.children.size();
        if (catalog.is_array())
            for (const Json& o : catalog)
                if (o.value("op", std::string()) == n.op) {
                    r.kind = o.value("kind", std::string());
                    break;
                }
        r.container = r.kind == "group" || r.kind == "modifier" || r.kind == "sdf" || r.kind == "sdf_group" || !n.children.empty();
        out.push_back(r);
        collect_rows(n.children, depth + 1, catalog, out);
    }
}

}  // namespace

ModelerModel::ModelerModel(std::string projectDir, ModelerCommandFn call) : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

ModelerModel::~ModelerModel() {
    if (running_.valid && running_.future.valid()) running_.future.wait();
}

std::string ModelerModel::title() const {
    const std::size_t slash = rel_.find_last_of('/');
    return slash == std::string::npos ? rel_ : rel_.substr(slash + 1);
}

// ---- the document ----------------------------------------------------------------------------------------------------------------

bool ModelerModel::open(const std::string& rel) {
    close();
    if (!ends_with_(rel, ".model.json")) {
        error_ = "'" + rel + "' is not a model document the panel opens.";
        status_ = error_ + " Open a *.model.json (model.create makes one).";
        return false;
    }
    open_ = true;
    rel_ = rel;
    evalError_.clear();
    const bool ok = load_from_disk();
    request_eval();
    return ok;
}

void ModelerModel::close() {
    if (running_.valid && running_.future.valid()) running_.future.wait();
    running_ = Running{};
    open_ = false;
    valid_ = false;
    rel_.clear();
    error_.clear();
    status_.clear();
    evalError_.clear();
    checkError_.clear();
    json_ = Json();
    text_.clear();
    doc_.reset();
    build_.reset();
    ++buildRev_;
    builtFor_ = failedFor_ = 0;
    livePointer_.clear();
    liveJson_ = Json();
    wait_ = 0;
}

bool ModelerModel::load_from_disk() {
    doc_.reset();
    livePointer_.clear();
    liveJson_ = Json();
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        valid_ = false;
        error_ = abs.error().message;
        return false;
    }
    std::error_code ec;
    if (!stdfs::is_regular_file(*abs, ec)) {
        valid_ = false;
        error_ = "'" + rel_ + "' does not exist.";
        json_ = Json();
        stamp_ = compute_stamp();
        return false;
    }
    auto text = read_file(*abs);
    if (!text) {
        valid_ = false;
        error_ = "Cannot read '" + rel_ + "'.";
        return false;
    }
    if (*text != text_) {
        text_ = *text;
        ++docRev_;
        ++rev_;
    }
    auto json = parse_json(text_, rel_);
    if (!json.ok()) {
        valid_ = false;
        error_ = json.error().message + (json.error().hint.empty() ? "" : " " + json.error().hint);
        json_ = Json();
        stamp_ = compute_stamp();
        return false;
    }
    json_ = std::move(*json);
    std::vector<ModelIssue> issues;
    auto d = parse_model_doc(json_, rel_, &issues);
    if (d.ok()) {
        doc_ = std::move(*d);
        error_.clear();
    } else {
        error_ = d.error().message + (d.error().hint.empty() ? "" : " " + d.error().hint);
        if (issues.size() > 1) error_ += " (" + std::to_string(issues.size()) + " problems; model.info lists them all.)";
    }
    valid_ = doc_.has_value();
    stamp_ = compute_stamp();
    return valid_;
}

bool ModelerModel::reload() {
    if (!is_open()) return false;
    const bool ok = load_from_disk();
    request_eval();
    return ok;
}

std::uint64_t ModelerModel::compute_stamp() const {
    std::uint64_t h = 1469598103934665603ULL;
    auto abs = resolve_project_path(projectDir_, rel_);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) return h;
    h = mix_hash(h, std::uint64_t(stdfs::file_size(*abs, ec)));
    h = mix_hash(h, std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    return h;
}

bool ModelerModel::poll_external() {
    if (!is_open() || compute_stamp() == stamp_) return false;
    load_from_disk();
    request_eval();
    status_ = "Reloaded: the file changed on disk.";
    return true;
}

// ---- the tree and the catalog ----------------------------------------------------------------------------------------------------

const Json& ModelerModel::catalog() {
    if (!catalogLoaded_) {
        catalogLoaded_ = true;
        CommandResult r = call_("model.info", Json::object());
        if (r.ok && r.result.contains("operations")) {
            catalog_ = Json::object({{"operations", r.result["operations"]}, {"commonFields", r.result.value("commonFields", Json::array())}});
        } else {
            catalog_ = Json::object({{"operations", Json::array()}, {"commonFields", Json::array()}});
        }
    }
    return catalog_;
}

const Json* ModelerModel::op_info(const std::string& op) {
    const Json& c = catalog();
    for (const Json& o : c["operations"])
        if (o.value("op", std::string()) == op) return &o;
    return nullptr;
}

std::vector<Json> ModelerModel::fields_of(const std::string& op) {
    std::vector<Json> out;
    if (const Json* o = op_info(op))
        for (const Json& f : (*o)["fields"]) out.push_back(f);
    for (const Json& f : catalog()["commonFields"]) {
        const std::string key = f.value("key", std::string());
        if (key == "position" || key == "rotation" || key == "scale" || key == "align" || key == "part" || key == "material") out.push_back(f);
    }
    return out;
}

std::vector<ModelerRow> ModelerModel::rows() const {
    std::vector<ModelerRow> out;
    if (!doc_) return out;
    // The catalog is loaded on first use; a const method cannot load it, so the kind may be empty until the panel asked once.
    collect_rows(doc_->nodes, 0, catalogLoaded_ ? catalog_["operations"] : Json(), out);
    return out;
}

const Json* ModelerModel::node(const std::string& pointer) const {
    if (json_.is_null()) return nullptr;
    const Json* n = walk(json_, pointer);
    return n && n->is_object() && n->contains("op") ? n : nullptr;
}

const Json* ModelerModel::shown_node(const std::string& pointer) const {
    if (!livePointer_.empty() && livePointer_ == pointer && !liveJson_.is_null()) {
        const Json* n = walk(liveJson_, pointer);
        if (n) return n;
    }
    return node(pointer);
}

std::string ModelerModel::pointer_of(const std::string& id) const {
    if (id.empty()) return {};
    for (const ModelerRow& r : rows())
        if (r.id == id) return r.pointer;
    return {};
}

std::vector<std::string> ModelerModel::part_names() const {
    std::vector<std::string> out;
    if (!build_) return out;
    for (const ModelPartInfo& p : build_->parts)
        if (!p.part.empty() && std::find(out.begin(), out.end(), p.part) == out.end()) out.push_back(p.part);
    return out;
}

std::string ModelerModel::part_of(const std::string& pointer) const {
    // Walk down from the top: the nearest node on the path that names a part.
    if (json_.is_null() || pointer.empty()) return {};
    std::string best, at;
    std::size_t i = 0;
    while (i < pointer.size()) {
        const std::size_t next = pointer.find('/', i + 1);
        at = pointer.substr(0, next == std::string::npos ? pointer.size() : next);
        if (const Json* n = walk(json_, at))
            if (n->is_object() && n->contains("op") && n->contains("part") && (*n)["part"].is_string()) best = (*n)["part"].get<std::string>();
        if (next == std::string::npos) break;
        i = next;
    }
    return best;
}

// ---- undo plumbing -----------------------------------------------------------------------------------------------------------------

ModelerBlob ModelerModel::read_blob(const std::string& rel) {
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) return nullptr;
    auto data = read_file(*abs);
    if (!data) return nullptr;
    return std::make_shared<const std::string>(std::move(*data));
}

bool ModelerModel::write_blob(const ModelerBlob& blob) {
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        status_ = abs.error().message;
        return false;
    }
    std::error_code ec;
    if (!blob) {
        stdfs::remove(*abs, ec);
        return true;
    }
    stdfs::create_directories(abs->parent_path(), ec);
    std::ofstream f(*abs, std::ios::binary | std::ios::trunc);
    if (!f || !f.write(blob->data(), std::streamsize(blob->size()))) {
        status_ = "Cannot write " + rel_ + ".";
        return false;
    }
    return true;
}

ModelerEditOutcome ModelerModel::fail(ModelerEditOutcome out, const std::string& message) {
    out.ok = false;
    out.error = message;
    status_ = message;
    return out;
}

ModelerEditOutcome ModelerModel::run(const std::string& label, const std::function<CommandResult()>& body) {
    ModelerEditOutcome out;
    if (!is_open()) return fail(out, label + ": no model is open.");
    if (!valid_) return fail(out, label + ": the file does not load: " + error_);
    // The command writes files and sets the VFS root: let an evaluation on the worker finish first.
    if (running_.valid) running_.future.wait();
    collect();
    ModelerBlob before = read_blob(rel_);
    CommandResult r = body();
    if (!r.ok) {
        write_blob(before);   // the command wrote nothing valid; a half-done change would not be an undo step
        load_from_disk();
        return fail(out, label + ": " + command_error_text(r.error));
    }
    out.result = r.result;
    load_from_disk();
    ModelerBlob after = read_blob(rel_);
    const bool same = before == after || (before && after && *before == *after);
    if (!same) {
        ModelerStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.label = label;
        s.before = std::move(before);
        s.after = std::move(after);
        out.step = s.id;
        steps_[s.id] = std::move(s);
    }
    status_ = label;
    request_eval();
    return out;
}

Json ModelerModel::edit_args(const std::string& op) const {
    // bake:false: an edit changes the document; the .glb is written by Save.
    return Json::object({{"path", rel_}, {"op", op}, {"bake", false}});
}

// ---- edits -------------------------------------------------------------------------------------------------------------------------

ModelerEditOutcome ModelerModel::set_values(const std::string& pointer, const Json& values, const std::string& label) {
    std::string what = label;
    if (what.empty()) {
        what = "Edit";
        if (const Json* n = node(pointer)) {
            what += " " + (n->contains("id") && (*n)["id"].is_string() ? (*n)["id"].get<std::string>() : n->value("op", std::string("node")));
        }
        if (values.is_object() && values.size() == 1) what += " " + values.begin().key();
    }
    return run(what, [&] {
        Json a = edit_args("set");
        a["target"] = pointer;
        a["values"] = values;
        return call_("model.edit", a);
    });
}

ModelerEditOutcome ModelerModel::add_node(const std::string& parent, const Json& nodeJson, int index, const std::string& label) {
    return run(label.empty() ? "Add " + nodeJson.value("op", std::string("node")) : label, [&] {
        Json a = edit_args("add");
        a["node"] = nodeJson;
        if (!parent.empty()) a["parent"] = parent;
        if (index >= 0) a["index"] = index;
        return call_("model.edit", a);
    });
}

ModelerEditOutcome ModelerModel::remove_node(const std::string& pointer) {
    std::string what = "Remove node";
    if (const Json* n = node(pointer)) what = "Remove " + (n->contains("id") && (*n)["id"].is_string() ? (*n)["id"].get<std::string>() : n->value("op", std::string("node")));
    return run(what, [&] {
        Json a = edit_args("remove");
        a["target"] = pointer;
        return call_("model.edit", a);
    });
}

ModelerEditOutcome ModelerModel::set_enabled(const std::string& pointer, bool enabled) {
    // enabled: true is the default, so turning it on removes the field.
    return set_values(pointer, Json::object({{"enabled", enabled ? Json() : Json(false)}}), enabled ? "Enable node" : "Disable node");
}

ModelerEditOutcome ModelerModel::move_node(const std::string& pointer, const std::string& parent, int index) {
    return run("Move node", [&] {
        Json a = edit_args("move");
        a["target"] = pointer;
        if (!parent.empty()) a["parent"] = parent;
        if (index >= 0) a["index"] = index;
        return call_("model.edit", a);
    });
}

ModelerEditOutcome ModelerModel::set_document_field(const std::string& key, const Json& value, const std::string& label) {
    return run(label.empty() ? "Edit " + key : label, [&] {
        Json a = edit_args("document");
        a[key] = value;
        return call_("model.edit", a);
    });
}

// ---- the live overlay --------------------------------------------------------------------------------------------------------------

void ModelerModel::set_live(const std::string& pointer, const Json& values) {
    if (!valid_ || json_.is_null()) return;
    Json copy = json_;
    Json* n = walk_mut(copy, pointer);
    if (!n || !n->is_object()) return;
    for (auto it = values.begin(); it != values.end(); ++it) {
        if (it.value().is_null()) n->erase(it.key());
        else (*n)[it.key()] = it.value();
    }
    livePointer_ = pointer;
    liveJson_ = std::move(copy);
    ++rev_;
    request_eval();
}

void ModelerModel::clear_live() {
    if (livePointer_.empty()) return;
    livePointer_.clear();
    liveJson_ = Json();
    ++rev_;
    request_eval();
}

Json ModelerModel::eval_source() const { return livePointer_.empty() ? json_ : liveJson_; }

// ---- files -------------------------------------------------------------------------------------------------------------------------

ModelerEditOutcome ModelerModel::save() {
    ModelerEditOutcome out;
    if (!is_open()) return fail(out, "Save: no model is open.");
    if (!valid_) return fail(out, "Save: the file does not load: " + error_);
    if (running_.valid) running_.future.wait();
    collect();
    CommandResult r = call_("model.bake", Json::object({{"path", rel_}, {"overwrite", overwriteOnSave_}, {"force", true}}));
    if (!r.ok) return fail(out, "Save: " + command_error_text(r.error));
    out.result = r.result;
    status_ = "Baked " + baked_path() + ".";
    return out;
}

std::string ModelerModel::baked_path() const {
    if (!doc_) return {};
    return model_document_output(*doc_, rel_);
}

Json ModelerModel::check() {
    checkError_.clear();
    if (!is_open() || !valid_) {
        checkError_ = "No valid model is open.";
        return Json();
    }
    if (running_.valid) running_.future.wait();
    collect();
    CommandResult r = call_("model.check", Json::object({{"path", rel_}}));
    if (!r.ok) {
        checkError_ = command_error_text(r.error);
        return Json();
    }
    return r.result;
}

// ---- evaluating --------------------------------------------------------------------------------------------------------------------

void ModelerModel::request_eval() { wait_ = debounce_; }

void ModelerModel::start_job() {
    const std::string dir = projectDir_;
    const Json source = eval_source();
    const std::string path = rel_;
    // Fonts and textures are read through the VFS: off the UI thread only while the VFS is already on this project.
    const bool inline_ = !async_ || fs::project_root() != stdfs::path(dir);
    auto work = [dir, source, path, inline_]() -> std::pair<ModelerBuildPtr, std::string> {
        std::vector<ModelIssue> issues;
        auto doc = parse_model_doc(source, path, &issues);
        if (!doc.ok()) return {nullptr, doc.error().message + (doc.error().hint.empty() ? "" : " " + doc.error().hint)};
        const stdfs::path saved = fs::project_root();
        if (inline_) fs::set_project_root(dir);
        auto built = evaluate_model(*doc, model_project_eval_options(dir));
        if (inline_) fs::set_project_root(saved);
        if (!built.ok()) return {nullptr, built.error().message + (built.error().hint.empty() ? "" : " " + built.error().hint)};
        return {std::make_shared<const ModelBuild>(std::move(*built)), ""};
    };
    running_.future = std::async(inline_ ? std::launch::deferred : std::launch::async, std::move(work));
    running_.rev = rev_;
    running_.startedMs = now_ms();
    running_.valid = true;
}

void ModelerModel::collect() {
    if (!running_.valid) return;
    if (running_.future.wait_for(std::chrono::seconds(0)) == std::future_status::timeout) return;
    auto [built, error] = running_.future.get();
    running_.valid = false;
    evalMs_ = now_ms() - running_.startedMs;
    ++evals_;
    if (built) {
        build_ = std::move(built);
        builtFor_ = running_.rev;
        ++buildRev_;
        evalError_.clear();
    } else {
        failedFor_ = running_.rev;
        evalError_ = error;
    }
}

bool ModelerModel::busy() const {
    if (running_.valid) return true;
    if (!is_open() || !valid_) return false;
    return builtFor_ != rev_ && failedFor_ != rev_;
}

void ModelerModel::tick() {
    if (!is_open()) return;
    collect();
    if (running_.valid || !valid_) return;
    if (builtFor_ == rev_ || failedFor_ == rev_) return;
    if (wait_ > 0) {
        --wait_;
        return;
    }
    start_job();
}

void ModelerModel::settle() {
    for (int i = 0; i < 400; ++i) {
        wait_ = 0;
        tick();
        if (running_.valid) {
            running_.future.wait();
            continue;
        }
        if (!busy()) return;
    }
}

// ---- undo ----------------------------------------------------------------------------------------------------------------------------

const ModelerStep* ModelerModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string ModelerModel::step_document(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? std::string() : it->second.rel;
}

bool ModelerModel::apply_step(int id, bool forward) {
    auto it = steps_.find(id);
    if (it == steps_.end()) {
        status_ = "That model edit is no longer remembered.";
        return false;
    }
    const ModelerStep& s = it->second;
    if (running_.valid) running_.future.wait();
    collect();
    const std::string keep = rel_;
    rel_ = s.rel;   // write_blob writes the file the step belongs to
    const bool ok = write_blob(forward ? s.after : s.before);
    rel_ = keep;
    if (!ok) return false;
    if (s.rel == rel_) {
        load_from_disk();
        request_eval();
    }
    status_ = std::string(forward ? "Redo: " : "Undo: ") + s.label;
    return true;
}

void ModelerModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) {
        if (keep.count(it->first)) ++it;
        else it = steps_.erase(it);
    }
}

}  // namespace fa::editor
