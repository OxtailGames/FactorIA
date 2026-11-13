// The logic of the editor's Model panel with no ImGui and no window: the model document being edited (a *.model.json), the operation tree it
// shows, the mesh it evaluates to (what the viewport draws) and the undo steps. modeler_panel.cpp draws it; modeler_tests.cpp and the autotest
// drive it.
//
// ONE SET OF CODE. Every edit that is kept is a model.edit call (op set, add, remove), the same call the Console, an AI or a script makes, so the
// file on disk is what the command would have written. A slider being dragged only changes the panel's own copy of the document (the live
// overlay: the viewport follows it); letting go makes the one model.edit set. Edits do NOT bake (the .glb next to the document stays as it was
// until Save). The mesh is evaluated again in the background a few frames after a change (a worker thread; tests evaluate inline).
//
// Undo is a table of steps, the before and after contents of the document; the editor's undo stack holds only {"$modeler": {"step": id}}
// entries that point into it (the same plan as the Music panel).
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/scene/model_doc.h"
#include "image_model.h"

namespace fa::editor {

using ModelerCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;
using ModelerBlob = ImageBlob;
using ModelerBuildPtr = std::shared_ptr<const ModelBuild>;

struct ModelerStep {
    int id = 0;
    std::string rel;  // the document the panel had open
    std::string label;
    ModelerBlob before, after;
};

struct ModelerEditOutcome {
    bool ok = true;
    std::string error;  // what went wrong, with the command's hint
    int step = 0;       // the undo step it recorded (0 = the edit changed nothing on disk)
    Json result;        // the command's result
};

// One line of the operation tree.
struct ModelerRow {
    std::string pointer;  // "/nodes/0/children/1"
    std::string id;       // "" when the node has none
    std::string op;
    std::string part;  // the part named ON this node ("" = none; the nodes below a group inherit it)
    std::string kind;  // "primitive", "modifier", "group", "sdf"... as the catalog says
    int depth = 0;
    bool enabled = true;
    bool container = false;  // takes children (a group, a modifier, an sdf)
    std::size_t childCount = 0;
};

class ModelerModel {
public:
    ModelerModel(std::string projectDir, ModelerCommandFn call);
    ~ModelerModel();
    ModelerModel(const ModelerModel&) = delete;
    ModelerModel& operator=(const ModelerModel&) = delete;

    // ---- the document ---------------------------------------------------------------------------------------------
    bool open(const std::string& rel);  // *.model.json; false: error() says why
    void close();
    bool is_open() const { return open_; }
    bool valid() const {
        return valid_;
    }  // the file is a valid model document (it may be open and broken: error() has the reason)
    const std::string& path() const { return rel_; }
    std::string title() const;
    const std::string& error() const { return error_; }
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }
    const Json& json() const { return json_; }
    const ModelDoc* doc() const { return doc_ ? &*doc_ : nullptr; }
    std::uint64_t doc_revision() const { return docRev_; }
    // The file changed on disk behind our back: reads it again. Returns true when it did.
    bool poll_external();
    bool reload();

    // ---- the tree and the catalog -----------------------------------------------------------------------------------
    // Every node in document order (a parent before its children).
    std::vector<ModelerRow> rows() const;
    // The node's JSON as written in the file; null for a pointer that names no node.
    const Json* node(const std::string& pointer) const;
    // The pointer of the node with this id ("" = none).
    std::string pointer_of(const std::string& id) const;
    // The operations and the common fields as model.info {} lists them (loaded once); the entry of `op`, or null.
    const Json& catalog();
    const Json* op_info(const std::string& op);
    // The field descriptions (key, type, min, max, default, choices, doc) of the node's op, then the common ones (position, rotation...).
    std::vector<Json> fields_of(const std::string& op);
    // The parts the evaluated mesh has, in submesh order.
    std::vector<std::string> part_names() const;
    // The part a node belongs to: its own `part`, else the nearest group above that names one ("" = none).
    std::string part_of(const std::string& pointer) const;

    // ---- editing (each is ONE undo step) ---------------------------------------------------------------------------
    // A model.edit set of the node: `values` is {field: value}; a null value removes the field (back to its default).
    ModelerEditOutcome set_values(const std::string& pointer, const Json& values, const std::string& label = "");
    // A model.edit add of `node` ({"op":"box"...}) into the group or modifier `parent` (an id or a pointer; "" = the top level) at `index` (-1 = the end).
    ModelerEditOutcome add_node(const std::string& parent, const Json& node, int index = -1,
                                const std::string& label = "");
    ModelerEditOutcome remove_node(const std::string& pointer);
    ModelerEditOutcome set_enabled(const std::string& pointer, bool enabled);
    // A model.edit move of the node into `parent` ("" = the top level) at `index`.
    ModelerEditOutcome move_node(const std::string& pointer, const std::string& parent, int index);
    // The document's own fields: materials, uv, gameReady... (model.edit op document).
    ModelerEditOutcome set_document_field(const std::string& key, const Json& value, const std::string& label = "");

    // ---- a slider being dragged ----------------------------------------------------------------------------------------
    // Shows `values` on the node in the viewport without writing the file. clear_live() goes back to the file's contents.
    void set_live(const std::string& pointer, const Json& values);
    void clear_live();
    bool has_live() const { return !livePointer_.empty(); }
    const std::string& live_pointer() const { return livePointer_; }
    // What the node shows: the live value when one is being dragged, else the file's.
    const Json* shown_node(const std::string& pointer) const;

    // ---- files ------------------------------------------------------------------------------------------------------
    // Bakes the .glb next to the document (model.bake).
    ModelerEditOutcome save();
    void set_overwrite_on_save(bool on) { overwriteOnSave_ = on; }
    // The .glb model.bake writes ("" when the document names none).
    std::string baked_path() const;
    // model.check of the file: the findings the panel lists (null on failure; error in `checkError`).
    Json check();
    const std::string& check_error() const { return checkError_; }

    // ---- the mesh the viewport draws ----------------------------------------------------------------------------------
    // Called every UI frame: collects a finished evaluation, starts the next one when the debounce has run out.
    void tick();
    void set_async(bool async) { async_ = async; }
    void set_debounce_ticks(int n) { debounce_ = n; }
    // Evaluates what is wanted, blocking, until nothing is pending (tests, and the autotest's "wait for the mesh").
    void settle();
    bool busy() const;  // an evaluation is running or about to start
    void request_eval();
    ModelerBuildPtr build() const { return build_; }            // the last finished evaluation (null before the first)
    std::uint64_t build_revision() const { return buildRev_; }  // changes whenever build() does
    bool build_is_fresh() const { return build_ && builtFor_ == rev_; }
    const std::string& eval_error() const { return evalError_; }
    int eval_count() const { return evals_; }
    double last_eval_ms() const { return evalMs_; }

    // ---- undo -------------------------------------------------------------------------------------------------------
    const ModelerStep* step(int id) const;
    bool apply_step(int id, bool forward);
    void retain_steps(const std::set<int>& keep);
    std::string step_document(int id) const;
    std::size_t step_count() const { return steps_.size(); }

private:
    bool load_from_disk();
    std::uint64_t compute_stamp() const;
    ModelerBlob read_blob(const std::string& rel);
    bool write_blob(const ModelerBlob& blob);
    ModelerEditOutcome fail(ModelerEditOutcome out, const std::string& message);
    // Runs a command as ONE undo step over the document file.
    ModelerEditOutcome run(const std::string& label, const std::function<CommandResult()>& body);
    Json edit_args(const std::string& op) const;
    Json eval_source() const;  // the JSON the viewport evaluates: the file's, or the live overlay
    void start_job();
    void collect();

    std::string projectDir_;
    ModelerCommandFn call_;
    bool open_ = false, valid_ = false;
    std::string rel_, error_, status_, evalError_, checkError_;
    Json json_;
    std::string text_;
    std::optional<ModelDoc> doc_;
    std::uint64_t docRev_ = 0, stamp_ = 0;
    std::map<int, ModelerStep> steps_;
    int nextStep_ = 1;
    bool overwriteOnSave_ = false;
    Json catalog_;
    bool catalogLoaded_ = false;

    // the live overlay
    std::string livePointer_;
    Json liveJson_;

    // evaluation
    bool async_ = true;
    int debounce_ = 2, wait_ = 0;
    std::uint64_t rev_ = 1;  // what the viewport wants: changes with the file and with the live overlay
    std::uint64_t builtFor_ = 0, failedFor_ = 0;
    std::uint64_t buildRev_ = 0;
    ModelerBuildPtr build_;
    int evals_ = 0;
    double evalMs_ = 0;
    struct Running {
        std::future<std::pair<ModelerBuildPtr, std::string>> future;
        std::uint64_t rev = 0;
        double startedMs = 0;
        bool valid = false;
    } running_;
};

}  // namespace fa::editor
