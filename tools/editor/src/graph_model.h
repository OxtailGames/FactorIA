// The logic of the editor's Graph panel with no ImGui and no window: the material being edited (a *.material.json with a "graph", docs/SHADERS.md
// "Node graphs"), the graph as the user is changing it, what the checker says about it, and the undo steps. graph_panel.cpp draws it;
// graph_preview.h renders it; graph_tests.cpp and the autotest drive it.
//
// ONE SET OF CODE. The graph is checked by check_material_document (the code behind `material.graph.validate`) and saved by
// `material.graph.generate` with the graph as the `graph` argument, so the file and the snippet the editor writes are what an AI, the Console or a
// script would write for the same graph. The panel never writes a snippet itself. A hand-edited snippet is shown (snippet_state()) and
// overwritten only when save() is called with force.
//
// The graph lives in memory until Save. Every edit (a node added, moved or removed, a link made or cut, a constant typed, a paste) is one undo
// step, recorded as the graph before and after; the editor's undo stack holds only {"$graph": {"step": id}} entries that point into the table.
// A drag (nodes being moved, a slider) is a gesture: begin_gesture(), any number of live edits, end_gesture() makes the one step. An edit that
// would add an error the graph did not have (a link of the wrong type, a cycle, a constant of the wrong size) is refused with the checker's
// message and the graph stays as it was.
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/tooling/material_graph.h"

namespace fa::editor {

using GraphCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;

struct GraphStep {
    int id = 0;
    std::string rel;  // the material the edit was made on
    std::string label;
    Json before, after;  // the "graph" object
    // A step that set the default of a param ("Set as default"): the param and its default before and after. It touches the file,
    // not the graph (before and after are null).
    std::string param;
    Json beforeValue, afterValue;
    // A step that made, renamed or deleted a param or texture of the file ("create", "rename", "delete"): it goes through the material.param.* /
    // material.texture.* commands in both directions. `entry` is the definition (create: what was made, delete: what was removed).
    std::string op;
    bool texture = false;
    std::string name, newName;
    Json entry;
    // create and delete: where the entry sits in the file's "params" / "textures" (the command's `index`), so the undo of a delete puts it back
    // in the same place (the order of "textures" decides the slots) and the redo of a create does too. -1: at the end.
    int index = -1;
};

struct GraphEditOutcome {
    bool ok = true;
    std::string error;               // what is wrong, with the checker's hint
    int step = 0;                    // the undo step recorded (0 = nothing changed, or a gesture is open)
    std::string id;                  // add_node / paste: the id of the (first) node made
    std::vector<std::string> nodes;  // delete_entry refused because nodes read it: their ids
    // A param or texture command that went through but left something the user has to know (the snippet it had to write again was not
    // written, or still names the old identifier): the sentences of the command, also in status(). Empty when all is well.
    std::string note;
};

struct GraphSaveOutcome {
    bool ok = false;
    bool needsForce = false;  // the snippet was edited by hand (or no generator wrote it): ask, then save(true)
    // The file changed on disk since the editor read it (or wrote it itself): nothing was written. Ask (Overwrite / Reload / Cancel); Overwrite is
    // save(force, true), Reload is reload().
    bool externalChange = false;
    bool written = false;  // the snippet or the material file changed on disk
    std::string state;     // the snippet's state before the save ("missing", "graph_changed", "hand_edited"...)
    std::string error;
};

// What the checker said about one node or link (or the graph as a whole).
struct GraphIssue {
    bool warning = false;
    MaterialIssue issue;
};

// A port of a node: used for the canvas and the link drag.
struct GraphPortId {
    std::string node, port;
    bool output = false;
    bool valid() const { return !node.empty(); }
};

// Colours of port types, shared by the canvas and the tests: 0 float, 1 vec2, 2 vec3, 3 vec4, 4 generic (gen/param), 5 texture.
int graph_port_class(const std::string& type);

// False when a link from an output of type `from` into an input of type `to` can never type-check (vec2 into vec3...). A float widens to
// anything and `gen` and `param` ports take what they are given, so those are "maybe": the checker decides when the link is made.
bool graph_ports_may_link(const std::string& from, const std::string& to);

// True when the project file `rel` is a material that holds a "graph" (the Project panel opens such a file in the Graph panel on a double click).
bool graph_file_has_graph(const std::string& projectDir, const std::string& rel);

class GraphModel {
public:
    GraphModel(std::string projectDir, GraphCommandFn call);

    // ---- the document ---------------------------------------------------------------------------------------------
    // Opens a *.material.json. A material with no graph is refused unless `startGraph` (the editor then starts an empty one, a draft the first Save
    // writes). False: error() says why.
    bool open(const std::string& rel, bool startGraph = false);
    // A new material `rel` with a one-node graph (the output), written through material.graph.generate; opens it. Never overwrites (the file is
    // published with a hard link, which fails when the name exists, even when another process made it a moment ago), and when the write of the
    // snippet fails the files it made are removed and the document that was open stays.
    // Refused (nothing is written) when the snippet it would write (shaders/<name>.surface.glsl, .fragment.glsl for a sprite) is already a
    // file: that one is somebody's. `kind` is the material kind of the graph (graph_supported_kinds(): "mesh" or "sprite"); a sprite
    // material is written with "kind": "sprite" and the output node of a sprite.
    GraphEditOutcome create(const std::string& rel, const std::string& kind = "mesh");
    // The first free `assets/materials/graph[N].material.json` (`sprite_graph[N]` for a sprite) whose snippet `shaders/<name>.surface.glsl`
    // (`.fragment.glsl`) is free too (a hand-written snippet of that name is never taken over), for the New graph material button. Empty
    // when a thousand names are taken.
    std::string new_material_name(const std::string& kind = "mesh") const;
    void close();
    bool is_open() const { return !rel_.empty(); }
    const std::string& path() const { return rel_; }
    std::string title() const;
    const std::string& error() const { return error_; }
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }
    const std::string& project_dir() const { return projectDir_; }

    // ---- the graph and what the checker says ---------------------------------------------------------------------
    const Json& graph() const { return graph_; }
    const Json& material_json() const { return doc_; }  // the file with the graph as edited
    std::uint64_t revision() const { return revision_; }
    bool dirty() const;  // the graph is not the one in the file
    // The material as it is in the file: the graph as last saved (or read from disk), the params as they are. Null when the graph was never saved.
    // saved_revision() changes whenever that document does (a save, a reload, a param default), so a caller can tell a new one from the same one.
    Json saved_material_json() const;
    std::uint64_t saved_revision() const { return savedRevision_; }
    bool has_saved() const { return is_open() && !savedGraph_.is_null(); }
    // The check of the material with the graph as edited (cached per revision).
    // While a gesture is open (a drag) the report of the graph at its start is returned and nothing is checked again, so a drag runs no
    // validation per frame; the end of the gesture checks the graph once.
    const MaterialGraphReport& report() const;
    int report_runs() const {
        return reportRuns_;
    }  // how many times the checker ran for report() (the tests count them)
    int node_count() const;
    int link_count() const;
    int node_index(const std::string& id) const;  // -1: none
    std::string node_id(int index) const;
    const GraphNodeType* node_type(const std::string& id) const;
    Vec2 node_pos(const std::string& id) const;
    // Errors and warnings whose pointer is inside node `id` (/graph/nodes/N...) or link `index` (/graph/links/N...), and the rest ("/graph/nodes",
    // "/params/gn_x"...).
    std::vector<GraphIssue> node_issues(const std::string& id) const;
    std::vector<GraphIssue> link_issues(int index) const;
    std::vector<GraphIssue> graph_issues() const;
    bool has_errors() const { return !report().errors.empty(); }
    // The value of an input as written ("inputs" of the node) or null.
    Json input_value(const std::string& id, const std::string& port) const;
    // The id of the node (and output) whose link ends at `id.port`, or an invalid GraphPortId.
    GraphPortId link_source(const std::string& id, const std::string& port) const;
    int link_index_into(const std::string& id, const std::string& port) const;  // -1 none

    // The view the user left the canvas in: kept in the graph's "editor" object when saving (the generator ignores it).
    struct View {
        float zoom = 1.0f, panX = 0, panY = 0;
        bool known = false;
    };
    const View& saved_view() const { return view_; }
    void set_view(float zoom, float panX, float panY);

    // ---- selection ------------------------------------------------------------------------------------------------
    const std::set<std::string>& selection() const { return selected_; }
    bool is_selected(const std::string& id) const { return selected_.count(id) > 0; }
    void select(const std::string& id, bool additive = false);
    void select_only(const std::set<std::string>& ids);
    void deselect(const std::string& id);
    void clear_selection() { selected_.clear(); }
    void select_all();

    // ---- edits: one undo step each (or one per gesture) -----------------------------------------------------------
    // A node of `type` at `pos`. A param or texture node names the first param or texture of the material when `ref` is empty.
    GraphEditOutcome add_node(const std::string& type, Vec2 pos, const std::string& ref = "");
    // The nodes and the links of them. The output node stays.
    GraphEditOutcome remove_nodes(const std::set<std::string>& ids);
    GraphEditOutcome move_nodes(const std::set<std::string>& ids, float dx, float dy);
    // "node.port" ends. A link into an input that has one replaces it. Refused when the checker would find a new error.
    GraphEditOutcome connect(const std::string& from, const std::string& to);
    GraphEditOutcome disconnect(const std::string& to);  // the link into "node.port"
    GraphEditOutcome remove_link(int index);
    // A constant of an input (a number or an array of numbers); null removes it (the input is then its default).
    GraphEditOutcome set_input(const std::string& id, const std::string& port, const Json& value);
    // The param or texture a param/texture node reads.
    GraphEditOutcome set_ref(const std::string& id, const std::string& name);
    // Writes `value` (a number, or an array of numbers) as the default of param `name` in the FILE (material.param.set_default), at once: the
    // graph's unsaved edits stay unsaved. One undo step (none while a gesture is open, or when the value is the default already).
    GraphEditOutcome set_param_default(const std::string& name, const Json& value);
    // The params and textures of the material FILE, written at once through material.param.* / material.texture.* (the same commands as the
    // Console and an AI), one undo step each. `spec` is what the command takes besides material and name: a param {type, default?, min?, max?,
    // doc?}, a texture {default?, sampler?, doc?}. Like a default, they touch the file, not the graph: the graph's unsaved edits stay unsaved.
    GraphEditOutcome add_entry(bool texture, const std::string& name, const Json& spec);
    // Renames it in the file and in the nodes that read it (the file's graph and the one held here, unsaved edits included).
    GraphEditOutcome rename_entry(bool texture, const std::string& name, const std::string& newName);
    // Refused (ids in GraphEditOutcome::nodes) while nodes of the graph read it: the panel selects them.
    GraphEditOutcome delete_entry(bool texture, const std::string& name);
    // The ids of the nodes of the graph as edited that read the param or texture `name`.
    std::vector<std::string> entry_readers(bool texture, const std::string& name) const;
    // The selection as clipboard text ({"factoria.graph.clip": 1, "nodes": [...], "links": [...]}); empty when nothing is selected.
    std::string copy(const std::set<std::string>& ids) const;
    GraphEditOutcome cut(const std::set<std::string>& ids, std::string* clip);
    // Pastes clipboard text with its top-left corner at `at`; new ids; the pasted nodes become the selection.
    GraphEditOutcome paste(const std::string& clip, Vec2 at);
    GraphEditOutcome duplicate(const std::set<std::string>& ids);

    // A drag: live edits made between begin and end make one step labelled `label` (none when nothing changed).
    void begin_gesture();
    GraphEditOutcome end_gesture(const std::string& label);
    bool gesture_open() const { return gesture_; }
    void cancel_gesture();  // back to the graph at begin_gesture

    // ---- the file ---------------------------------------------------------------------------------------------------
    // The state of the snippet on disk against the graph in the FILE ("in_sync", "graph_changed", "hand_edited", "unmanaged", "missing",
    // "unreadable" (it is there and cannot be read: snippet_error() says why)...), read by material.graph.validate. Call it when a document is
    // opened and after a save, never every frame.
    const std::string& snippet_state() const { return snippetState_; }
    const std::string& snippet_error() const {
        return snippetError_;
    }  // why the snippet is "unreadable"; empty otherwise
    void refresh_snippet_state();
    // Saves: material.graph.generate {material, graph, force}. Refused (needsForce) when the snippet was edited by hand and `force` is false, and
    // (externalChange) when the file changed on disk behind the editor and `overwriteExternal` is false: the poll runs every 20 frames, so save looks
    // at the file itself. A file that was deleted meanwhile is written again from the document as it was read (only with `overwriteExternal`: the
    // user answered Overwrite), then generate runs on it.
    GraphSaveOutcome save(bool force, bool overwriteExternal = false);
    // The file changed on disk behind our back (not by save): true once, when a poll finds it. With nothing unsaved the graph is read again.
    bool poll_external();
    bool external_conflict() const { return conflict_; }  // changed on disk while the graph has unsaved edits
    bool reload();                                        // takes the file as it is; the unsaved edits are gone

    // ---- undo -------------------------------------------------------------------------------------------------------
    const GraphStep* step(int id) const;
    // Applies the step forward or back. Refused (false, status() says why) when the graph is not what the step expects.
    bool apply_step(int id, bool forward);
    void retain_steps(const std::set<int>& keep);
    std::size_t step_count() const { return steps_.size(); }
    std::string step_document(int id) const;

    // ---- the library, shaped for the palette ------------------------------------------------------------------------
    // Node types usable in the material's kind, the ones whose name, category or doc contain `filter` (case-insensitive), in library order.
    std::vector<const GraphNodeType*> palette(const std::string& filter) const;

private:
    struct Stamp {
        std::int64_t time = 0;
        std::uintmax_t size = 0;
        bool operator==(const Stamp& o) const { return time == o.time && size == o.size; }
    };
    bool load_from_disk(bool startGraph);
    Stamp stamp() const;
    Json& nodes() { return graph_["nodes"]; }
    const Json&
    nodes() const {  // never inserts: a graph with no "nodes" (a file edited by hand) reads as an empty list
        static const Json none = Json::array();
        auto it = graph_.is_object() ? graph_.find("nodes") : graph_.end();
        return graph_.is_object() && it != graph_.end() ? *it : none;
    }
    // Replaces the graph with `next`: strict = refuse when the check finds an error the graph had not; records the step.
    GraphEditOutcome commit(Json next, const std::string& label, bool strict);
    GraphEditOutcome fail(const std::string& message) const;
    void touch();
    static bool same_graph(const Json& a, const Json& b);
    static std::string unique_id(const Json& list, const std::string& base);
    Json graph_for_save() const;
    // The default of param `name` as the file has it now (the parsed one when the file gives none); null when there is no such param.
    Json current_param_default(const std::string& name) const;
    // Calls material.param.set_default and takes the new default into doc_ (the file's stamp too). Returns "" or what went wrong.
    std::string write_param_default(const std::string& name, const Json& value, Json* previous, bool* written);
    // One of the six param/texture commands with the graph held here; on success takes the file's params, textures and hash (and the graph the
    // command changed) into the document. Returns "" or what went wrong (readers: the nodes that kept it from being deleted).
    // lastNote_ gets what the command said that the user must know (snippet.error, warnings); the callers copy it to the outcome and to status().
    std::string run_entry_command(const std::string& op, bool texture, const Json& args, Json* result,
                                  std::vector<std::string>* readers);
    // `externalPending`: the file already differed from stamp_ before our write (an outside change not polled yet): stamp_ stays, so the next
    // poll finds it. Otherwise stamp_ takes the stamp of the file as read here, when no one wrote it between the two stats around the read.
    void take_entries_from_file(const Json* newGraph, bool externalPending);
    bool external_pending() const { return is_open() && stamp() != stamp_; }
    std::string apply_entry_step(const GraphStep& s, bool forward);

    std::string projectDir_;
    GraphCommandFn call_;
    std::string rel_, error_, status_;
    std::vector<std::string>
        strayTmp_;  // temporary files of create() that could not be removed (a virus scanner holds them): tried again
    Json doc_;      // the file, with doc_["graph"] == graph_ (kept in step)
    Json graph_;    // the graph as edited
    Json savedGraph_;  // the graph as in the file (null: a draft that was never saved)
    View view_;
    std::string snippetState_ = "unchecked";
    std::string snippetError_;  // validate's snippet.error of an "unreadable" snippet
    std::set<std::string> selected_;
    std::uint64_t revision_ = 1;
    std::uint64_t savedRevision_ = 1;
    Stamp stamp_;
    std::string lastNote_;
    bool conflict_ = false;
    bool gesture_ = false;
    Json gestureBefore_;
    std::map<int, GraphStep> steps_;
    int nextStep_ = 1;
    mutable std::uint64_t reportRevision_ = 0;
    mutable int reportRuns_ = 0;
    mutable MaterialGraphReport report_;
};

}  // namespace fa::editor
