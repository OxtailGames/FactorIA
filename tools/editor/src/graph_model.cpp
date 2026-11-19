// The Graph panel's model (graph_model.h): the open material, the graph as edited, what the checker says, the edits and their undo steps.
#include "graph_model.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "inspector_model.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

constexpr const char* kClipKey = "factoria.graph.clip";

std::string link_end(const std::string& node, const std::string& port) { return node + "." + port; }

bool split_end(const std::string& end, std::string& node, std::string& port) {
    const auto dot = end.find('.');
    if (dot == std::string::npos || dot == 0 || dot + 1 >= end.size()) return false;
    node = end.substr(0, dot);
    port = end.substr(dot + 1);
    return true;
}

// "/graph/nodes/3/inputs/scale" -> 3 for prefix "/graph/nodes/"; -1 when the pointer is not inside that array.
int pointer_index(const std::string& pointer, const std::string& prefix) {
    if (pointer.compare(0, prefix.size(), prefix) != 0) return -1;
    std::size_t i = prefix.size();
    if (i >= pointer.size() || pointer[i] < '0' || pointer[i] > '9') return -1;
    long v = 0;
    while (i < pointer.size() && pointer[i] >= '0' && pointer[i] <= '9' && v < 100000000)
        v = v * 10 + (pointer[i++] - '0');
    if (i < pointer.size() && pointer[i] != '/') return -1;
    return int(v);
}

std::string base_id(const std::string& type) {
    if (type == kGraphOutputNode) return "out";
    std::string s;
    for (char c : type) s += (std::isalnum(static_cast<unsigned char>(c)) ? c : '_');
    return s;
}

std::string strip_digits(std::string s) {
    while (s.size() > 1 && std::isdigit(static_cast<unsigned char>(s.back()))) s.pop_back();
    return s;
}

double round_pos(double v) { return std::round(v * 10.0) / 10.0; }

Json pos_json(double x, double y) { return Json::array({round_pos(x), round_pos(y)}); }

Vec2 pos_of(const Json& node) {
    auto it = node.find("pos");
    if (it == node.end() || !it->is_array() || it->size() < 2 || !(*it)[0].is_number() || !(*it)[1].is_number())
        return Vec2{0, 0};
    return Vec2{(*it)[0].get<float>(), (*it)[1].get<float>()};
}

const Json* find_node(const Json& nodes, const std::string& id) {
    if (!nodes.is_array()) return nullptr;
    for (const Json& n : nodes)
        if (n.is_object() && n.value("id", std::string()) == id) return &n;
    return nullptr;
}

Json starter_graph() {
    return Json::parse(R"({
  "version": 1,
  "nodes": [
    { "id": "out", "type": "output", "pos": [320, 0], "inputs": { "albedo": [0.8, 0.8, 0.8], "roughness": 0.6 } }
  ],
  "links": []
})");
}

// Where the command put (create) or found (delete) the entry in the file's order; -1 when it said nothing (an older command).
int entry_index(const Json& result) {
    if (!result.is_object()) return -1;
    auto it = result.find("index");
    return it != result.end() && it->is_number_integer() ? int(std::clamp<long long>(it->get<long long>(), -1, 100000))
                                                         : -1;
}

}  // namespace

// The graph without what the generator ignores and a save adds ("version", "editor"): two graphs that differ only there are one graph.
bool GraphModel::same_graph(const Json& a, const Json& b) {
    if (!a.is_object() || !b.is_object()) return a == b;
    Json x = a, y = b;
    for (const char* k : {"version", "editor"}) {
        x.erase(k);
        y.erase(k);
    }
    return x == y;
}

bool graph_file_has_graph(const std::string& projectDir, const std::string& rel) {
    auto abs = resolve_project_path(projectDir, rel);
    if (!abs.ok()) return false;
    std::error_code ec;
    const auto size = stdfs::file_size(*abs, ec);
    if (ec || size > (std::uintmax_t(8) << 20)) return false;
    auto text = fs::read_text(abs->generic_string());
    if (!text.ok()) return false;
    const Json parsed = Json::parse(*text, nullptr, false);
    return !parsed.is_discarded() && parsed.is_object() && parsed.contains("graph") && parsed["graph"].is_object();
}

int graph_port_class(const std::string& type) {
    if (type == "float") return 0;
    if (type == "vec2") return 1;
    if (type == "vec3") return 2;
    if (type == "vec4") return 3;
    if (type == "texture") return 5;
    return 4;
}

bool graph_ports_may_link(const std::string& from, const std::string& to) {
    if (from == "float" || from == "gen" || from == "param" || to == "gen" || to == "param") return true;
    return from == to;
}

GraphModel::GraphModel(std::string projectDir, GraphCommandFn call)
    : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

std::string GraphModel::title() const {
    const auto slash = rel_.find_last_of('/');
    return slash == std::string::npos ? rel_ : rel_.substr(slash + 1);
}

GraphModel::Stamp GraphModel::stamp() const {
    Stamp s;
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) return s;
    std::error_code ec;
    const auto t = stdfs::last_write_time(*abs, ec);
    if (!ec) s.time = std::int64_t(t.time_since_epoch().count());
    const auto sz = stdfs::file_size(*abs, ec);
    if (!ec) s.size = sz;
    return s;
}

// ------------------------------------------------------------------------------------------------------- document --
bool GraphModel::load_from_disk(bool startGraph) {
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        error_ = abs.error().message;
        return false;
    }
    auto text = fs::read_text(abs->generic_string());
    if (!text.ok()) {
        error_ = "Cannot read " + rel_ + ": " + text.error().message;
        return false;
    }
    Json parsed;
    try {
        parsed = Json::parse(*text);
    } catch (const std::exception& e) {
        error_ =
            rel_ + " is not valid JSON: " + e.what() + " Fix the file (or `factoria validate`), then open it again.";
        return false;
    }
    if (!parsed.is_object()) {
        error_ = rel_ + " is not a material (a JSON object).";
        return false;
    }
    // Everything is checked on locals first: a file that cannot be shown leaves the document that is open untouched.
    Json newGraph;
    Json newSaved;
    auto g = parsed.find("graph");
    if (g != parsed.end() && g->is_object()) {
        newGraph = *g;
        newSaved = *g;
        auto n = newGraph.find("nodes");
        if (n == newGraph.end() || !n->is_array()) {
            error_ = rel_ + " has a \"graph\" with no \"nodes\" list (/graph/nodes): a graph is {\"nodes\": [...], "
                            "\"links\": [...]}. "
                            "Run `material.graph.validate` on it, add the list, or delete \"graph\" to keep the shader "
                            "as hand-written code.";
            return false;
        }
    } else if (startGraph) {
        newGraph = starter_graph();
        parsed["graph"] = newGraph;
    } else {
        error_ = rel_ +
                 " has no \"graph\": its shader is hand-written. Open it with \"Start a graph\" to make nodes, or edit "
                 "the snippet by hand.";
        return false;
    }
    doc_ = std::move(parsed);
    graph_ = std::move(newGraph);
    savedGraph_ = std::move(newSaved);
    ++savedRevision_;
    stamp_ = stamp();
    conflict_ = false;
    view_ = View{};
    if (graph_.contains("editor") && graph_["editor"].is_object() && graph_["editor"].contains("view") &&
        graph_["editor"]["view"].is_object()) {
        const Json& v = graph_["editor"]["view"];
        auto num = [&](const char* k, float lo, float hi, float d) {
            return v.contains(k) && v[k].is_number() ? std::clamp(v[k].get<float>(), lo, hi) : d;
        };
        view_.zoom = num("zoom", 0.1f, 4.0f, 1.0f);
        view_.panX = num("panX", -1e6f, 1e6f, 0.0f);
        view_.panY = num("panY", -1e6f, 1e6f, 0.0f);
        view_.known = true;
    }
    return true;
}

bool GraphModel::open(const std::string& rel, bool startGraph) {
    if (!ends_with(to_lower(rel), ".material.json")) {
        error_ = "'" + rel + "' is not a material (*.material.json).";
        return false;
    }
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        error_ = "'" + rel + "' does not exist in the project.";
        return false;
    }
    if (is_open() && rel == rel_)
        return true;  // already the open document: its edits stay (reload() reads the file again)
    const std::string before = rel_;
    rel_ = rel;
    error_.clear();
    if (!load_from_disk(startGraph)) {
        rel_ = before;  // load_from_disk changed nothing else: the document that was open (and its edits) stays
        return false;
    }
    status_.clear();
    selected_.clear();
    gesture_ = false;
    snippetState_ = "unchecked";
    ++revision_;
    refresh_snippet_state();
    return true;
}

GraphEditOutcome GraphModel::create(const std::string& rel) {
    GraphEditOutcome out;
    if (!ends_with(to_lower(rel), ".material.json")) return fail("'" + rel + "' must end in .material.json.");
    auto abs = resolve_project_path(projectDir_, rel);
    if (!abs.ok()) return fail(abs.error().message);
    if (!call_) return fail("The Graph panel has no command line to write through.");
    const stdfs::path file = *abs;
    const std::string already =
        "'" + rel + "' already exists: open it instead, or pick another name (nothing is overwritten).";
    std::error_code ec;
    if (stdfs::exists(file, ec)) return fail(already);
    std::string stem = fs::path_to_utf8(file.filename());
    stem = stem.substr(0, stem.size() - std::string(".material.json").size());
    for (auto it = strayTmp_.begin(); it != strayTmp_.end();) {  // what an earlier create could not remove
        std::error_code gone;
        stdfs::remove(fs::path_from_utf8(*it), gone);
        it = gone ? std::next(it) : strayTmp_.erase(it);
    }
    Json doc = Json::object();
    doc["format"] = kMaterialFormat;
    doc["doc"] = "A material made of nodes: edit it in the Graph panel (View > Graph).";
    doc["shader"] = "shaders/" + stem + ".surface.glsl";
    Json graph = starter_graph();
    graph["version"] = kGraphVersion;
    // The snippet the generator will write: noted before, so a failure removes only what this call made. A file of that name is somebody's (a
    // hand-written snippet): the generator would refuse to replace it, so say so before anything is written.
    bool snippetExisted = true;
    stdfs::path snippetFile;
    if (auto sn = resolve_project_path(projectDir_, doc["shader"].get<std::string>()); sn.ok()) {
        snippetFile = *sn;
        snippetExisted = stdfs::exists(snippetFile, ec);
        if (snippetExisted && !stdfs::is_directory(snippetFile, ec))
            return fail("'" + doc["shader"].get<std::string>() +
                        "' already exists (a shader snippet written by hand?) and the new material would "
                        "use that name. Pick another name for the material; nothing was written.");
    }
    // Published whole and never over a file: the text goes to a sibling first, then a hard link gives it its name, which fails when the name is taken
    // (even by a file another process made since the check above). A volume without hard links falls back to a look and a rename.
    stdfs::path tmp = file;
    tmp += ".new.tmp";
    if (auto w = fs::write_text(fs::path_to_utf8(tmp), doc.dump(2) + "\n"); !w.ok())
        return fail("Cannot write " + rel + ": " + w.error().message + " " + w.error().hint);
    std::error_code link;
    stdfs::create_hard_link(tmp, file, link);
    if (link && link != std::errc::file_exists) {
        link.clear();
        if (stdfs::exists(file, ec))
            link = std::make_error_code(std::errc::file_exists);
        else
            stdfs::rename(tmp, file, link);
    }
    std::error_code rm;
    stdfs::remove(tmp, rm);
    if (rm &&
        stdfs::exists(
            tmp, ec)) {  // a file open elsewhere (a virus scanner on Windows): tried again below and by the next create
        strayTmp_.push_back(fs::path_to_utf8(tmp));
    }
    if (link) return fail(link == std::errc::file_exists ? already : "Cannot write " + rel + ": " + link.message());
    auto undo_files = [&] {
        std::error_code e;
        stdfs::remove(file, e);
        if (!snippetExisted && !snippetFile.empty()) stdfs::remove(snippetFile, e);
    };
    const CommandResult made = call_("material.graph.generate", Json::object({{"material", rel}, {"graph", graph}}));
    if (!made.ok) {
        undo_files();
        return fail("Cannot write the shader snippet of " + rel + ": " + command_error_text(made.error));
    }
    if (!open(rel)) {  // (the document that was open stays: open changes nothing when it fails)
        const std::string why = error_;
        undo_files();
        return fail(why);
    }
    status_ = "Made " + rel + " and its snippet.";
    for (auto it = strayTmp_.begin(); it != strayTmp_.end();) {
        std::error_code gone;
        stdfs::remove(fs::path_from_utf8(*it), gone);
        if (!gone) {
            it = strayTmp_.erase(it);
        } else {
            status_ +=
                " The temporary file " + *it + " could not be removed (" + gone.message() + "): delete it by hand.";
            ++it;
        }
    }
    return out;
}

std::string GraphModel::new_material_name() const {
    for (int i = 1; i < 1000; ++i) {
        const std::string stem = i == 1 ? "graph" : "graph" + std::to_string(i);
        const std::string rel = "assets/materials/" + stem + ".material.json";
        std::error_code ec;
        bool taken = false;
        for (const std::string& r : {rel, "shaders/" + stem + ".surface.glsl"}) {
            auto abs = resolve_project_path(projectDir_, r);
            taken = taken || (abs.ok() && stdfs::exists(*abs, ec));
        }
        if (!taken) return rel;
    }
    return std::string();
}

void GraphModel::close() {
    rel_.clear();
    doc_ = Json();
    graph_ = Json();
    savedGraph_ = Json();
    ++savedRevision_;
    error_.clear();
    selected_.clear();
    gesture_ = false;
    conflict_ = false;
    snippetState_ = "unchecked";
    ++revision_;
}

bool GraphModel::dirty() const { return is_open() && (savedGraph_.is_null() || !same_graph(graph_, savedGraph_)); }

Json GraphModel::saved_material_json() const {
    if (!has_saved()) return Json();
    Json d = doc_;
    d["graph"] = savedGraph_;
    return d;
}

Json GraphModel::current_param_default(const std::string& name) const {
    if (!is_open()) return Json();
    auto params = doc_.find("params");
    if (params != doc_.end() && params->is_object()) {
        auto p = params->find(name);
        if (p != params->end() && p->is_object()) {
            auto d = p->find("default");
            if (d != p->end() && !d->is_null()) return *d;
        }
    }
    for (const MaterialParam& p : report().material.params)
        if (p.name == name) return p.defaultValue;  // a param with no "default" in the file: the parsed one (zeros)
    return Json();
}

std::string GraphModel::write_param_default(const std::string& name, const Json& value, Json* previous, bool* written) {
    if (!call_) return "The Graph panel has no command line to write through.";
    const bool externalPending =
        external_pending();  // an outside change the poll has not seen yet must stay visible to it
    const CommandResult r =
        call_("material.param.set_default", Json::object({{"material", rel_}, {"param", name}, {"value", value}}));
    if (!r.ok) return command_error_text(r.error);
    if (written) *written = r.result.is_object() && r.result.value("written", false);
    if (previous) *previous = r.result.is_object() ? r.result.value("previous", Json()) : Json();
    if (previous && previous->is_null()) *previous = current_param_default(name);
    if (!doc_["params"].is_object() || !doc_["params"][name].is_object()) return "";
    doc_["params"][name]["default"] = value;
    if (!externalPending) stamp_ = stamp();  // the file changed by our own hand: not an external edit
    ++revision_;
    ++savedRevision_;
    return "";
}

GraphEditOutcome GraphModel::set_param_default(const std::string& name, const Json& value) {
    if (!is_open()) return fail("No material is open in the Graph panel.");
    Json previous;
    bool written = false;
    const std::string err = write_param_default(name, value, &previous, &written);
    if (!err.empty()) return fail(err);
    GraphEditOutcome out;
    if (!written) return out;  // already the default: nothing was written
    if (!gesture_) {
        GraphStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.label = "Set default of " + name;
        s.param = name;
        s.beforeValue = previous;
        s.afterValue = value;
        out.step = s.id;
        steps_[s.id] = std::move(s);
    }
    status_.clear();
    return out;
}

// ------------------------------------------------------------------------------------------ params and textures --
std::vector<std::string> GraphModel::entry_readers(bool texture, const std::string& name) const {
    std::vector<std::string> ids;
    const char* key = texture ? "texture" : "param";
    if (!graph_.is_object() || !nodes().is_array()) return ids;
    for (const Json& n : nodes()) {
        if (!n.is_object()) continue;
        const GraphNodeType* t = find_graph_node_type(n.value("type", std::string()));
        if (t && t->ref == key && n.value(key, std::string()) == name) ids.push_back(n.value("id", std::string()));
    }
    return ids;
}

// The file was changed by one of the material.param.* / material.texture.* commands: take its params, textures and what they changed in the
// graph (`newGraph`, the in-memory graph the command followed) as the editor's own document.
void GraphModel::take_entries_from_file(const Json* newGraph, bool externalPending) {
    auto abs = resolve_project_path(projectDir_, rel_);
    const Stamp before = stamp();
    if (abs.ok()) {
        auto text = fs::read_text(abs->generic_string());
        const Json parsed = text.ok() ? Json::parse(*text, nullptr, false) : Json();
        if (parsed.is_object()) {
            for (const char* key : {"params", "textures", "graphHash"}) {
                auto it = parsed.find(key);
                if (it != parsed.end())
                    doc_[key] = *it;
                else
                    doc_.erase(key);
            }
            auto g = parsed.find("graph");
            if (g != parsed.end() && g->is_object() && !savedGraph_.is_null()) savedGraph_ = *g;
        }
    }
    if (newGraph) graph_ = *newGraph;
    // The file changed by our own hand: not an external edit. The stamp is the one of the file as it was when it was read here (the same before and
    // after the read); a file written by someone else in between, or before our command, keeps its old stamp and the next poll reports it.
    const Stamp after = stamp();
    if (!externalPending && before == after) stamp_ = after;
    ++savedRevision_;
    touch();
    refresh_snippet_state();
}

std::string GraphModel::run_entry_command(const std::string& op, bool texture, const Json& args, Json* result,
                                          std::vector<std::string>* readers) {
    if (!call_) return "The Graph panel has no command line to write through.";
    lastNote_.clear();
    const bool externalPending = external_pending();
    Json a = args;
    a["material"] = rel_;
    if (op != "create" && graph_.is_object()) a["graph"] = graph_;
    const CommandResult r = call_(std::string("material.") + (texture ? "texture." : "param.") + op, a);
    if (!r.ok) {
        if (readers && r.error.is_object() && r.error.contains("data") && r.error["data"].is_object() &&
            r.error["data"].contains("nodes") && r.error["data"]["nodes"].is_array())
            for (const Json& id : r.error["data"]["nodes"])
                if (id.is_string()) readers->push_back(id.get<std::string>());
        return command_error_text(r.error);
    }
    if (result) *result = r.result;
    const Json* newGraph = r.result.is_object() && r.result.contains("graph") && r.result["graph"].is_object()
                               ? &r.result["graph"]
                               : nullptr;
    take_entries_from_file(newGraph, externalPending);
    // What the command says besides "done": the snippet it had to write again and could not, and the snippets that still use the old name.
    if (r.result.is_object()) {
        std::string note;
        auto add = [&](const std::string& text) {
            if (text.empty()) return;
            if (!note.empty()) note += " ";
            note += text;
        };
        auto sn = r.result.find("snippet");
        if (sn != r.result.end() && sn->is_object()) {
            const std::string err = sn->value("error", std::string());
            if (!err.empty()) add("The shader snippet was not written again: " + std::string(trim(err)));
        }
        auto w = r.result.find("warnings");
        if (w != r.result.end() && w->is_array())
            for (const Json& item : *w)
                if (item.is_object()) {
                    std::string text = item.value("message", std::string());
                    const std::string hintText = item.value("hint", std::string());
                    if (!hintText.empty()) text += (text.empty() || text.back() == '.' ? " " : ". ") + hintText;
                    add(text);
                }
        lastNote_ = note;
    }
    return "";
}

GraphEditOutcome GraphModel::add_entry(bool texture, const std::string& name, const Json& spec) {
    if (!is_open()) return fail("No material is open in the Graph panel.");
    if (gesture_) return fail("Finish the drag first.");
    Json args = spec.is_object() ? spec : Json::object();
    args["name"] = name;
    Json result;
    const std::string err = run_entry_command("create", texture, args, &result, nullptr);
    if (!err.empty()) return fail(err);
    GraphStep s;
    s.id = nextStep_++;
    s.rel = rel_;
    s.label = std::string("Add ") + (texture ? "texture " : "param ") + name;
    s.op = "create";
    s.texture = texture;
    s.name = name;
    s.entry = result.is_object() ? result.value("entry", Json()) : Json();
    s.index = entry_index(result);
    GraphEditOutcome out;
    out.step = s.id;
    out.note = lastNote_;
    steps_[s.id] = std::move(s);
    status_ = lastNote_;
    return out;
}

GraphEditOutcome GraphModel::rename_entry(bool texture, const std::string& name, const std::string& newName) {
    if (!is_open()) return fail("No material is open in the Graph panel.");
    if (gesture_) return fail("Finish the drag first.");
    if (name == newName) return GraphEditOutcome{};
    const std::string err =
        run_entry_command("rename", texture, Json::object({{"name", name}, {"newName", newName}}), nullptr, nullptr);
    if (!err.empty()) return fail(err);
    GraphStep s;
    s.id = nextStep_++;
    s.rel = rel_;
    s.label = std::string("Rename ") + (texture ? "texture " : "param ") + name + " to " + newName;
    s.op = "rename";
    s.texture = texture;
    s.name = name;
    s.newName = newName;
    GraphEditOutcome out;
    out.step = s.id;
    out.note = lastNote_;
    steps_[s.id] = std::move(s);
    status_ = lastNote_;
    return out;
}

GraphEditOutcome GraphModel::delete_entry(bool texture, const std::string& name) {
    if (!is_open()) return fail("No material is open in the Graph panel.");
    if (gesture_) return fail("Finish the drag first.");
    Json result;
    std::vector<std::string> readers;
    const std::string err = run_entry_command("delete", texture, Json::object({{"name", name}}), &result, &readers);
    if (!err.empty()) {
        GraphEditOutcome out = fail(err);
        out.nodes = readers;
        return out;
    }
    GraphStep s;
    s.id = nextStep_++;
    s.rel = rel_;
    s.label = std::string("Delete ") + (texture ? "texture " : "param ") + name;
    s.op = "delete";
    s.texture = texture;
    s.name = name;
    s.entry = result.is_object() ? result.value("entry", Json()) : Json();
    s.index = entry_index(result);
    GraphEditOutcome out;
    out.step = s.id;
    out.note = lastNote_;
    steps_[s.id] = std::move(s);
    status_ = lastNote_;
    return out;
}

std::string GraphModel::apply_entry_step(const GraphStep& s, bool forward) {
    const std::string what = std::string(s.texture ? "texture " : "param ") + s.name;
    // a create is a delete backwards, a delete a create backwards, a rename swaps its names
    std::string op = s.op;
    if (!forward) op = s.op == "create" ? "delete" : s.op == "delete" ? "create" : "rename";
    Json args = Json::object();
    if (op == "create") {
        args = s.entry.is_object() ? s.entry : Json::object();
        args["name"] = s.name;
        if (s.index >= 0) args["index"] = s.index;  // the place it had: the undo of a delete, the redo of a create
    } else if (op == "delete") {
        args["name"] = s.name;
    } else {
        args["name"] = forward ? s.name : s.newName;
        args["newName"] = forward ? s.newName : s.name;
    }
    const std::string err = run_entry_command(op, s.texture, args, nullptr, nullptr);
    if (!err.empty())
        return "The edit of " + what + " cannot be applied now (the file or the graph changed since): " + err;
    return "";
}

void GraphModel::touch() {
    doc_["graph"] = graph_;
    ++revision_;
    for (auto it = selected_.begin(); it != selected_.end();)
        it = find_node(graph_["nodes"], *it) ? std::next(it) : selected_.erase(it);
}

const MaterialGraphReport& GraphModel::report() const {
    // A drag changes the document every frame: the check waits for the gesture to end (begin_gesture made the report current first).
    if (gesture_ && is_open() && reportRevision_ != 0) return report_;
    if (reportRevision_ != revision_) {
        reportRevision_ = revision_;
        ++reportRuns_;
        report_ = is_open() ? check_material_document(doc_, projectDir_, rel_) : MaterialGraphReport{};
    }
    return report_;
}

int GraphModel::node_count() const { return graph_.is_object() && nodes().is_array() ? int(nodes().size()) : 0; }
int GraphModel::link_count() const {
    return graph_.is_object() && graph_.contains("links") && graph_["links"].is_array() ? int(graph_["links"].size())
                                                                                        : 0;
}

int GraphModel::node_index(const std::string& id) const {
    for (int i = 0; i < node_count(); ++i)
        if (nodes()[i].is_object() && nodes()[i].value("id", std::string()) == id) return i;
    return -1;
}

std::string GraphModel::node_id(int index) const {
    return index >= 0 && index < node_count() ? nodes()[index].value("id", std::string()) : std::string();
}

const GraphNodeType* GraphModel::node_type(const std::string& id) const {
    const int i = node_index(id);
    return i < 0 ? nullptr : find_graph_node_type(nodes()[i].value("type", std::string()));
}

Vec2 GraphModel::node_pos(const std::string& id) const {
    const int i = node_index(id);
    return i < 0 ? Vec2{0, 0} : pos_of(nodes()[i]);
}

std::vector<GraphIssue> GraphModel::node_issues(const std::string& id) const {
    std::vector<GraphIssue> out;
    const int index = node_index(id);
    if (index < 0) return out;
    const MaterialGraphReport& r = report();
    for (const MaterialIssue& e : r.errors)
        if (pointer_index(e.pointer, "/graph/nodes/") == index) out.push_back({false, e});
    for (const MaterialIssue& w : r.warnings)
        if (pointer_index(w.pointer, "/graph/nodes/") == index) out.push_back({true, w});
    return out;
}

std::vector<GraphIssue> GraphModel::link_issues(int index) const {
    std::vector<GraphIssue> out;
    const MaterialGraphReport& r = report();
    for (const MaterialIssue& e : r.errors)
        if (pointer_index(e.pointer, "/graph/links/") == index) out.push_back({false, e});
    for (const MaterialIssue& w : r.warnings)
        if (pointer_index(w.pointer, "/graph/links/") == index) out.push_back({true, w});
    return out;
}

std::vector<GraphIssue> GraphModel::graph_issues() const {
    std::vector<GraphIssue> out;
    const MaterialGraphReport& r = report();
    auto belongs = [](const MaterialIssue& i) {
        return pointer_index(i.pointer, "/graph/nodes/") >= 0 || pointer_index(i.pointer, "/graph/links/") >= 0;
    };
    for (const MaterialIssue& e : r.errors)
        if (!belongs(e)) out.push_back({false, e});
    for (const MaterialIssue& w : r.warnings)
        if (!belongs(w)) out.push_back({true, w});
    return out;
}

Json GraphModel::input_value(const std::string& id, const std::string& port) const {
    const int i = node_index(id);
    if (i < 0) return Json();
    auto in = nodes()[i].find("inputs");
    if (in == nodes()[i].end() || !in->is_object()) return Json();
    auto v = in->find(port);
    return v == in->end() ? Json() : *v;
}

int GraphModel::link_index_into(const std::string& id, const std::string& port) const {
    if (!graph_.contains("links") || !graph_["links"].is_array()) return -1;
    const std::string to = link_end(id, port);
    for (int i = 0; i < int(graph_["links"].size()); ++i)
        if (graph_["links"][i].is_object() && graph_["links"][i].value("to", std::string()) == to) return i;
    return -1;
}

GraphPortId GraphModel::link_source(const std::string& id, const std::string& port) const {
    const int li = link_index_into(id, port);
    GraphPortId out;
    if (li < 0) return out;
    std::string n, p;
    if (!split_end(graph_["links"][li].value("from", std::string()), n, p)) return out;
    out.node = n;
    out.port = p;
    out.output = true;
    return out;
}

void GraphModel::set_view(float zoom, float panX, float panY) {
    view_.zoom = std::clamp(zoom, 0.1f, 4.0f);
    view_.panX = std::clamp(panX, -1e6f, 1e6f);
    view_.panY = std::clamp(panY, -1e6f, 1e6f);
    view_.known = true;
}

// ---------------------------------------------------------------------------------------------------- selection --
void GraphModel::select(const std::string& id, bool additive) {
    if (node_index(id) < 0) return;
    if (!additive) selected_.clear();
    selected_.insert(id);
}
void GraphModel::select_only(const std::set<std::string>& ids) {
    selected_.clear();
    for (const std::string& id : ids)
        if (node_index(id) >= 0) selected_.insert(id);
}
void GraphModel::deselect(const std::string& id) { selected_.erase(id); }
void GraphModel::select_all() {
    selected_.clear();
    for (int i = 0; i < node_count(); ++i) selected_.insert(node_id(i));
}

// -------------------------------------------------------------------------------------------------------- edits --
GraphEditOutcome GraphModel::fail(const std::string& message) const {
    GraphEditOutcome out;
    out.ok = false;
    out.error = message;
    return out;
}

GraphEditOutcome GraphModel::commit(Json next, const std::string& label, bool strict) {
    if (!is_open()) return fail("No material is open in the Graph panel.");
    if (next == graph_) return GraphEditOutcome{};
    if (strict) {
        Json doc = doc_;
        doc["graph"] = next;
        const MaterialGraphReport after = check_material_document(doc, projectDir_, rel_);
        std::multiset<std::string> had;
        for (const MaterialIssue& e : report().errors) had.insert(e.message);
        for (const MaterialIssue& e : after.errors) {
            auto it = had.find(e.message);
            if (it != had.end()) {
                had.erase(it);
                continue;
            }
            return fail(e.message + (e.hint.empty() ? std::string() : " " + e.hint));
        }
    }
    GraphEditOutcome out;
    const Json before = graph_;
    graph_ = std::move(next);
    touch();
    if (!gesture_) {
        GraphStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.label = label;
        s.before = before;
        s.after = graph_;
        out.step = s.id;
        steps_[s.id] = std::move(s);
    }
    status_.clear();
    return out;
}

std::string GraphModel::unique_id(const Json& list, const std::string& base) {
    const std::string stem = strip_digits(base.empty() ? std::string("node") : base);
    if (!find_node(list, stem)) return stem;
    for (int n = 2; n < 100000; ++n) {
        const std::string id = stem + std::to_string(n);
        if (!find_node(list, id)) return id;
    }
    return stem + "_x";
}

GraphEditOutcome GraphModel::add_node(const std::string& type, Vec2 pos, const std::string& ref) {
    const GraphNodeType* t = find_graph_node_type(type);
    if (!t)
        return fail("There is no node type \"" + type +
                    "\": pick one from the palette (material.graph.nodes lists them).");
    if (type == kGraphOutputNode) {
        for (const Json& n : nodes())
            if (n.is_object() && n.value("type", std::string()) == kGraphOutputNode)
                return fail("The graph has an output node already: a graph has exactly one.");
    }
    Json next = graph_;
    if (!next["nodes"].is_array()) next["nodes"] = Json::array();
    Json node = Json::object();
    node["id"] = unique_id(next["nodes"], base_id(type));
    node["type"] = type;
    node["pos"] = pos_json(pos.x, pos.y);
    if (t->ref == "param" || t->ref == "texture") {
        std::string name = ref;
        const MaterialGraphReport& r = report();
        if (name.empty()) {
            if (t->ref == "param") {
                for (const MaterialParam& p : r.material.params)
                    if (!p.implicit) {
                        name = p.name;
                        break;
                    }
            } else if (!r.material.textures.empty()) {
                name = r.material.textures.front().name;
            }
        }
        if (!name.empty()) node[t->ref] = name;
    }
    const std::string id = node["id"];
    next["nodes"].push_back(node);
    GraphEditOutcome out = commit(std::move(next), "Add node " + type, false);
    if (out.ok) {
        out.id = id;
        select(id);
    }
    return out;
}

GraphEditOutcome GraphModel::remove_nodes(const std::set<std::string>& ids) {
    if (ids.empty()) return fail("Nothing is selected.");
    Json next = graph_;
    Json keptNodes = Json::array();
    bool outputKept = false;
    int removed = 0;
    for (const Json& n : next["nodes"]) {
        const std::string id = n.value("id", std::string());
        if (ids.count(id) && n.value("type", std::string()) == kGraphOutputNode) {
            outputKept = true;
            keptNodes.push_back(n);
        } else if (ids.count(id)) {
            ++removed;
        } else {
            keptNodes.push_back(n);
        }
    }
    if (removed == 0)
        return fail(outputKept ? "The output node stays: every graph has exactly one." : "Nothing to remove.");
    next["nodes"] = keptNodes;
    Json keptLinks = Json::array();
    if (next.contains("links") && next["links"].is_array())
        for (const Json& l : next["links"]) {
            std::string n1, p1, n2, p2;
            const bool a = split_end(l.value("from", std::string()), n1, p1);
            const bool b = split_end(l.value("to", std::string()), n2, p2);
            if ((a && ids.count(n1) && find_node(keptNodes, n1) == nullptr) ||
                (b && ids.count(n2) && find_node(keptNodes, n2) == nullptr))
                continue;
            keptLinks.push_back(l);
        }
    next["links"] = keptLinks;
    return commit(std::move(next), removed == 1 ? "Delete node" : "Delete nodes", false);
}

GraphEditOutcome GraphModel::move_nodes(const std::set<std::string>& ids, float dx, float dy) {
    if (ids.empty() || (dx == 0.0f && dy == 0.0f)) return GraphEditOutcome{};
    Json next = graph_;
    for (Json& n : next["nodes"]) {
        if (!ids.count(n.value("id", std::string()))) continue;
        const Vec2 p = pos_of(n);
        n["pos"] = pos_json(double(p.x) + dx, double(p.y) + dy);
    }
    return commit(std::move(next), ids.size() == 1 ? "Move node" : "Move nodes", false);
}

GraphEditOutcome GraphModel::connect(const std::string& from, const std::string& to) {
    std::string fn, fp, tn, tp;
    if (!split_end(from, fn, fp) || !split_end(to, tn, tp))
        return fail("A link joins \"node.output\" to \"node.input\" (got \"" + from + "\" and \"" + to + "\").");
    const GraphNodeType* ft = node_type(fn);
    const GraphNodeType* tt = node_type(tn);
    if (!ft) return fail("There is no node \"" + fn + "\" in the graph.");
    if (!tt) return fail("There is no node \"" + tn + "\" in the graph.");
    if (fn == tn) return fail("A node cannot be linked to itself: that would be a loop.");
    const GraphPort* out = nullptr;
    const GraphPort* in = nullptr;
    for (const GraphPort& p : ft->outputs)
        if (p.name == fp) out = &p;
    for (const GraphPort& p : tt->inputs)
        if (p.name == tp) in = &p;
    if (!out) return fail("Node \"" + fn + "\" (" + ft->type + ") has no output \"" + fp + "\".");
    if (!in) return fail("Node \"" + tn + "\" (" + tt->type + ") has no input \"" + tp + "\".");
    // The same link again (a drag that ends on the input it came from) changes nothing: no undo step.
    if (const int li = link_index_into(tn, tp); li >= 0 && graph_["links"][li].value("from", std::string()) == from)
        return GraphEditOutcome{};
    Json next = graph_;
    Json links = Json::array();
    if (next.contains("links") && next["links"].is_array())
        for (const Json& l : next["links"])
            if (l.value("to", std::string()) != to) links.push_back(l);
    links.push_back(Json::object({{"from", from}, {"to", to}}));
    next["links"] = links;
    return commit(std::move(next), "Link " + from + " to " + to, true);
}

GraphEditOutcome GraphModel::disconnect(const std::string& to) {
    std::string n, p;
    if (!split_end(to, n, p)) return fail("Name the input as \"node.input\".");
    const int li = link_index_into(n, p);
    if (li < 0) return fail("Nothing is linked into " + to + ".");
    return remove_link(li);
}

GraphEditOutcome GraphModel::remove_link(int index) {
    if (index < 0 || index >= link_count()) return fail("There is no link " + std::to_string(index) + ".");
    Json next = graph_;
    next["links"].erase(next["links"].begin() + index);
    return commit(std::move(next), "Cut link", false);
}

GraphEditOutcome GraphModel::set_input(const std::string& id, const std::string& port, const Json& value) {
    const int i = node_index(id);
    if (i < 0) return fail("There is no node \"" + id + "\" in the graph.");
    const GraphNodeType* t = node_type(id);
    if (!t) return fail("Node \"" + id + "\" has an unknown type.");
    bool known = false;
    for (const GraphPort& p : t->inputs) known = known || p.name == port;
    if (!known) return fail("Node \"" + id + "\" (" + t->type + ") has no input \"" + port + "\".");
    Json next = graph_;
    Json& node = next["nodes"][i];
    if (value.is_null()) {
        if (node.contains("inputs") && node["inputs"].is_object()) {
            node["inputs"].erase(port);
            if (node["inputs"].empty()) node.erase("inputs");
        }
    } else {
        if (!node.contains("inputs") || !node["inputs"].is_object()) node["inputs"] = Json::object();
        node["inputs"][port] = value;
    }
    return commit(std::move(next), "Set " + id + "." + port, true);
}

GraphEditOutcome GraphModel::set_ref(const std::string& id, const std::string& name) {
    const int i = node_index(id);
    const GraphNodeType* t = node_type(id);
    if (i < 0 || !t) return fail("There is no node \"" + id + "\" in the graph.");
    if (t->ref.empty()) return fail("Node \"" + id + "\" (" + t->type + ") does not name a param or a texture.");
    Json next = graph_;
    next["nodes"][i][t->ref] = name;
    return commit(std::move(next), "Set " + id + " " + t->ref, true);
}

std::string GraphModel::copy(const std::set<std::string>& ids) const {
    Json clipNodes = Json::array();
    std::set<std::string> have;
    for (const Json& n : nodes()) {
        const std::string id = n.value("id", std::string());
        if (!ids.count(id) || n.value("type", std::string()) == kGraphOutputNode) continue;
        clipNodes.push_back(n);
        have.insert(id);
    }
    if (clipNodes.empty()) return {};
    Json clipLinks = Json::array();
    if (graph_.contains("links") && graph_["links"].is_array())
        for (const Json& l : graph_["links"]) {
            std::string n1, p1, n2, p2;
            if (split_end(l.value("from", std::string()), n1, p1) && split_end(l.value("to", std::string()), n2, p2) &&
                have.count(n1) && have.count(n2))
                clipLinks.push_back(l);
        }
    Json clip = Json::object();
    clip[kClipKey] = 1;
    clip["nodes"] = clipNodes;
    clip["links"] = clipLinks;
    return clip.dump();
}

GraphEditOutcome GraphModel::cut(const std::set<std::string>& ids, std::string* clip) {
    const std::string text = copy(ids);
    if (text.empty()) return fail("Select nodes other than the output node to cut.");
    if (clip) *clip = text;
    std::set<std::string> without;
    for (const std::string& id : ids)
        if (node_type(id) && node_type(id)->type != kGraphOutputNode) without.insert(id);
    return remove_nodes(without);
}

GraphEditOutcome GraphModel::paste(const std::string& clipText, Vec2 at) {
    Json clip;
    try {
        clip = Json::parse(clipText);
    } catch (...) {
        return fail("The clipboard does not hold nodes copied from a graph.");
    }
    if (!clip.is_object() || !clip.contains(kClipKey) || !clip.contains("nodes") || !clip["nodes"].is_array() ||
        clip["nodes"].empty())
        return fail("The clipboard does not hold nodes copied from a graph.");
    Json next = graph_;
    if (!next["nodes"].is_array()) next["nodes"] = Json::array();
    float minX = 1e30f, minY = 1e30f;
    for (const Json& n : clip["nodes"]) {
        if (!n.is_object()) continue;
        const Vec2 p = pos_of(n);
        minX = std::min(minX, p.x);
        minY = std::min(minY, p.y);
    }
    if (clip["nodes"].size() > 500) return fail("The clipboard holds more than 500 nodes: paste fewer at a time.");
    std::map<std::string, std::string> renamed;
    std::set<std::string> madeIds;
    std::string first;
    for (const Json& n : clip["nodes"]) {
        if (!n.is_object() || n.value("type", std::string()) == kGraphOutputNode) continue;
        const std::string old = n.value("id", std::string());
        Json piece = n;
        // keep the name the node had when it is free, so a paste of one node is "noise" -> "noise2", not "noise_fbm"
        const std::string kept = unique_id(next["nodes"], old.empty() ? base_id(n.value("type", std::string())) : old);
        piece["id"] = kept;
        const Vec2 p = pos_of(n);
        piece["pos"] = pos_json(double(at.x) + (p.x - minX), double(at.y) + (p.y - minY));
        piece.erase("editor");
        renamed[old] = kept;
        madeIds.insert(kept);
        if (first.empty()) first = kept;
        next["nodes"].push_back(piece);
    }
    if (madeIds.empty()) return fail("The clipboard holds only the output node, and a graph has exactly one.");
    if (!next.contains("links") || !next["links"].is_array()) next["links"] = Json::array();
    if (clip.contains("links") && clip["links"].is_array())
        for (const Json& l : clip["links"]) {
            std::string n1, p1, n2, p2;
            if (!l.is_object() || !split_end(l.value("from", std::string()), n1, p1) ||
                !split_end(l.value("to", std::string()), n2, p2) || !renamed.count(n1) || !renamed.count(n2))
                continue;
            next["links"].push_back(
                Json::object({{"from", link_end(renamed[n1], p1)}, {"to", link_end(renamed[n2], p2)}}));
        }
    GraphEditOutcome out = commit(std::move(next), madeIds.size() == 1 ? "Paste node" : "Paste nodes", false);
    if (out.ok) {
        out.id = first;
        select_only(madeIds);
    }
    return out;
}

GraphEditOutcome GraphModel::duplicate(const std::set<std::string>& ids) {
    const std::string clip = copy(ids);
    if (clip.empty()) return fail("Select nodes other than the output node to duplicate.");
    float minX = 1e30f, minY = 1e30f;
    for (const std::string& id : ids) {
        if (node_index(id) < 0) continue;
        const Vec2 p = node_pos(id);
        minX = std::min(minX, p.x);
        minY = std::min(minY, p.y);
    }
    return paste(clip, Vec2{minX + 30.0f, minY + 30.0f});
}

void GraphModel::begin_gesture() {
    if (gesture_) return;
    if (is_open()) (void)report();  // what the drag shows is the report of the graph as it was when the drag began
    gesture_ = true;
    gestureBefore_ = graph_;
}

GraphEditOutcome GraphModel::end_gesture(const std::string& label) {
    GraphEditOutcome out;
    if (!gesture_) return out;
    gesture_ = false;
    if (graph_ == gestureBefore_) return out;
    GraphStep s;
    s.id = nextStep_++;
    s.rel = rel_;
    s.label = label;
    s.before = gestureBefore_;
    s.after = graph_;
    out.step = s.id;
    steps_[s.id] = std::move(s);
    gestureBefore_ = Json();
    return out;
}

void GraphModel::cancel_gesture() {
    if (!gesture_) return;
    gesture_ = false;
    graph_ = gestureBefore_;
    gestureBefore_ = Json();
    touch();
}

// ---------------------------------------------------------------------------------------------------------- file --
void GraphModel::refresh_snippet_state() {
    snippetState_ = "unchecked";
    if (!is_open() || !call_ || savedGraph_.is_null()) {
        if (is_open() && savedGraph_.is_null()) snippetState_ = "draft";
        return;
    }
    const CommandResult r = call_("material.graph.validate", Json::object({{"material", rel_}}));
    if (r.ok && r.result.is_object() && r.result.contains("snippet") && r.result["snippet"].is_object())
        snippetState_ = r.result["snippet"].value("state", std::string("unchecked"));
}

Json GraphModel::graph_for_save() const {
    Json g = graph_;
    g["version"] = kGraphVersion;
    if (view_.known) {
        if (!g.contains("editor") || !g["editor"].is_object()) g["editor"] = Json::object();
        g["editor"]["view"] = Json::object({{"zoom", std::round(view_.zoom * 100.0) / 100.0},
                                            {"panX", std::round(view_.panX)},
                                            {"panY", std::round(view_.panY)}});
    }
    return g;
}

GraphSaveOutcome GraphModel::save(bool force, bool overwriteExternal) {
    GraphSaveOutcome out;
    if (!is_open()) {
        out.error = "No material is open in the Graph panel.";
        return out;
    }
    if (!call_) {
        out.error = "The Graph panel has no command line to save through.";
        return out;
    }
    if (!report().errors.empty()) {
        const MaterialIssue& e = report().errors.front();
        out.error = "The graph has errors (" + e.pointer + ": " + e.message +
                    "). Fix them first: nothing is written while the graph does not check.";
        return out;
    }
    if (!overwriteExternal) {
        // The poll runs every 20 frames and a change can come in between: look at the file now.
        const Stamp now = stamp();
        if (conflict_ || now != stamp_) {
            conflict_ = true;
            stamp_ = now;
            out.externalChange = true;
            out.error = rel_ + " changed on disk (or was deleted) since the editor read it. Nothing was written: "
                               "choose Overwrite to replace the "
                               "file with this graph, or Reload to take the file as it is.";
            return out;
        }
    }
    if (overwriteExternal) {
        // Overwrite on a file that was deleted: material.graph.generate needs the file to exist, so it is written again from the document as it was
        // read (its own graph replaced by the edited one, which is what Overwrite means). Never when the file is there: that one is replaced by the command.
        auto abs = resolve_project_path(projectDir_, rel_);
        std::error_code ec;
        if (abs.ok() && !stdfs::exists(*abs, ec)) {
            Json again = doc_;
            again["graph"] = graph_for_save();
            if (auto w = fs::write_text(fs::path_to_utf8(*abs), again.dump(2) + "\n"); !w.ok()) {
                out.error = "Cannot write " + rel_ + " again: " + w.error().message + " " + w.error().hint;
                return out;
            }
        }
    }
    Json args = Json::object({{"material", rel_}, {"graph", graph_for_save()}});
    if (force) args["force"] = true;
    const CommandResult r = call_("material.graph.generate", args);
    if (!r.ok) {
        const std::string code = r.error.is_object() ? r.error.value("code", std::string()) : std::string();
        if (code == "hand_edited") {
            out.needsForce = true;
            refresh_snippet_state();
            out.state = snippetState_;
        }
        out.error = command_error_text(r.error);
        return out;
    }
    out.ok = true;
    out.state = r.result.is_object() ? r.result.value("state", std::string()) : std::string();
    out.written = r.result.is_object() && r.result.value("written", false);
    // the file now holds the graph with its version and editor keys: that is the graph the editor holds from here on (same_graph ignores them,
    // so the undo steps made before the save still apply)
    load_from_disk(true);
    snippetState_ = "in_sync";
    ++revision_;
    status_ = out.written ? "Saved " + rel_ + " and its snippet." : "Saved " + rel_ + " (nothing changed on disk).";
    return out;
}

bool GraphModel::poll_external() {
    if (!is_open()) return false;
    const Stamp s = stamp();
    if (s == stamp_) return false;
    if (dirty()) {
        stamp_ = s;
        conflict_ = true;
        return true;
    }
    const Json before = graph_;
    if (!load_from_disk(false)) {
        // The file lost its "graph" (or cannot be read as a material any more). It is said once: the stamp is now the file as it is, so the
        // next polls find nothing new. The graph held here stays and counts as never saved, so Save writes it back into the file.
        stamp_ = s;
        status_ = error_ + " The graph shown here is the editor's copy: Save writes it back to the file.";
        error_.clear();
        savedGraph_ = Json();
        ++savedRevision_;
        snippetState_ = "draft";
        return true;
    }
    if (graph_ != before) {
        selected_.clear();
        touch();
    } else {
        ++revision_;
    }
    refresh_snippet_state();
    status_ = "The file changed on disk and was read again.";
    return true;
}

bool GraphModel::reload() {
    if (!is_open()) return false;
    const bool ok = load_from_disk(false);
    if (ok) {
        selected_.clear();
        gesture_ = false;
        touch();
        refresh_snippet_state();
    }
    return ok;
}

// ----------------------------------------------------------------------------------------------------------- undo --
const GraphStep* GraphModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string GraphModel::step_document(int id) const {
    const GraphStep* s = step(id);
    return s ? s->rel : std::string();
}

bool GraphModel::apply_step(int id, bool forward) {
    const GraphStep* s = step(id);
    if (!s) {
        status_ = "That graph edit is no longer remembered.";
        return false;
    }
    if (s->rel != rel_) {
        status_ = "That edit belongs to " + s->rel + ", which is not the open graph.";
        return false;
    }
    if (gesture_) cancel_gesture();
    if (!s->op.empty()) {  // a param or a texture of the file, made, renamed or deleted
        const std::string err = apply_entry_step(*s, forward);
        if (!err.empty()) {
            status_ = err;
            return false;
        }
        status_ = lastNote_;
        return true;
    }
    if (!s->param.empty()) {  // a param default: the file's value must be the one the step expects
        const Json& expectsValue = forward ? s->beforeValue : s->afterValue;
        const Json& target = forward ? s->afterValue : s->beforeValue;
        if (current_param_default(s->param) != expectsValue) {
            status_ = "The default of " + s->param +
                      " is not what that edit expects (it changed outside the editor): "
                      "the step is dropped.";
            return false;
        }
        const std::string err = write_param_default(s->param, target, nullptr, nullptr);
        if (!err.empty()) {
            status_ = err;
            return false;
        }
        status_.clear();
        return true;
    }
    const Json& expects = forward ? s->before : s->after;
    if (!same_graph(graph_, expects)) {
        status_ = "The graph is not what that edit expects (it changed outside the editor or by a reload): the step is "
                  "dropped.";
        return false;
    }
    graph_ = forward ? s->after : s->before;
    touch();
    status_.clear();
    return true;
}

void GraphModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) it = keep.count(it->first) ? std::next(it) : steps_.erase(it);
}

// ------------------------------------------------------------------------------------------------------ palette --
std::vector<const GraphNodeType*> GraphModel::palette(const std::string& filter) const {
    std::vector<const GraphNodeType*> out;
    const std::string kind = is_open() ? report().kind : std::string("mesh");
    const std::string needle = to_lower(filter);
    for (const GraphNodeType& t : graph_node_library()) {
        if (std::find(t.kinds.begin(), t.kinds.end(), kind) == t.kinds.end()) continue;
        if (!needle.empty() && to_lower(t.type).find(needle) == std::string::npos &&
            to_lower(t.category).find(needle) == std::string::npos && to_lower(t.doc).find(needle) == std::string::npos)
            continue;
        out.push_back(&t);
    }
    return out;
}

}  // namespace fa::editor
