// The logic of the editor's Vector panel with no ImGui and no window: the SVG being edited (a *.svg file, or an svg layer of an image
// document), the scene read from it (fa/tooling/vector_edit.h), the selection, the pen, the snapping and the undo steps. vector_panel.cpp
// and vector_canvas.cpp draw it; vector_tests.cpp and the autotest drive it.
//
// ONE SET OF CODE. Every edit that is kept is a call of a vector.* command (vector.add, vector.nodes, vector.transform, vector.set,
// vector.boolean, vector.reorder, ...), the same call the Console, an AI or a script makes, so the SVG keeps its ids, groups and
// transforms by the rules of docs/VECTOR.md. What the canvas shows while a handle is being dragged is the result of the same command run
// with dryRun on the text in memory, so what you see is what the command writes when you let go.
//
// Edits are written to disk as they happen (like the commands do; the svg layer of an image document is written without baking, Save
// bakes it). Undo is a table of steps: the before and after contents of the files an edit changed. The editor's undo stack holds only
// {"$vector": {"step": id}} entries that point into this table, the same idea as the {"$image": ...} entries of the Image panel.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/vector_edit.h"
#include "image_model.h"

namespace fa::editor {

using VectorCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;

enum class VectorTool { Select, Node, Pen, Rectangle, Ellipse, Line, Shape };
const char* vector_tool_name(VectorTool tool);
// The tools the panel's toolbar lists, in order.
const std::vector<VectorTool>& vector_tools();

// The contents of the files an edit touches, by project-relative path (the same blobs as the Image panel's steps).
using VectorBlob = ImageBlob;
using VectorFileSet = ImageFileSet;

struct VectorStep {
    int id = 0;
    std::string rel;                // the file the panel had open (the image document for an svg layer)
    std::string layer;              // the svg layer ("" for an svg file)
    std::string label;
    VectorFileSet before, after;
};

struct VectorEditOutcome {
    bool ok = true;
    std::string error;              // what went wrong, with the command's hint
    int step = 0;                   // the undo step it recorded (0 = the edit changed nothing on disk)
    Json result;                    // the last command's result
};

// One anchor of one shape: the id or selector of the element (VecItem::ref), the subpath and the node in it.
struct VectorNodeRef {
    std::string shape;
    int subpath = 0;
    int node = 0;
    bool operator==(const VectorNodeRef& o) const { return shape == o.shape && subpath == o.subpath && node == o.node; }
};

struct VectorSnapSettings {
    bool grid = false;
    bool points = true;
    bool guides = true;
    double gridSize = 10;           // drawing units
};

enum class VectorSnapKind { None, Grid, Point, Guide };

// The style a new shape starts with.
struct VectorStyle {
    std::string fill = "#6d9eeb";
    std::string stroke = "#101018";
    double strokeWidth = 2;
    bool useStroke = false;
};

// The pen tool's path while it is being drawn: ONE subpath in the drawing space.
struct VectorPen {
    bool active = false;
    VecNodePath path;               // the nodes so far (one subpath); when continuing, the existing nodes come first
    bool dragging = false;          // the last node's handle follows the mouse
    // continuing an existing open path
    std::string continueShape;      // the element ("" = a new path)
    int continueSubpath = 0;
    bool continueAtEnd = true;
    int existing = 0;               // how many nodes were there when it started
};

class VectorModel {
public:
    VectorModel(std::string projectDir, VectorCommandFn call);

    // ---- the document ----------------------------------------------------------------------------------------------
    bool open(const std::string& svgRel);                                         // a *.svg file; false: error() says why
    bool open_layer(const std::string& documentRel, const std::string& layer);   // an svg layer: its name or index path ("1", "1/0")
    void close();
    bool is_open() const { return !rel_.empty(); }
    bool valid() const { return valid_; }           // the SVG loads (it may be open and broken: error() has the reason)
    bool is_layer() const { return isLayer_; }
    const std::string& path() const { return rel_; }               // the .svg file, or the image document
    const std::string& layer() const { return layer_; }            // the layer as given to open_layer
    const std::string& layer_path() const { return layerPath_; }   // its index path in the document
    std::string title() const;
    const std::string& error() const { return error_; }
    // The SVG text on the canvas: the file's, or with a drag going on the result of that drag.
    const std::string& svg() const { return previewing_ ? shown_ : svg_; }
    const VecScene& scene() const { return scene_; }
    // Changes every time what the canvas shows changes (an edit, a preview, a reload); the panel makes a new picture when it does.
    std::uint64_t revision() const { return rev_; }
    // The files changed on disk behind our back (the Console, an AI, the Image panel): reads them again. Returns true when it did.
    bool poll_external();
    bool reload();
    // Milliseconds the last scene read and the last picture took (the status line shows them; the tests log them).
    double last_scene_ms() const { return sceneMs_; }
    double last_raster_ms() const { return rasterMs_; }
    // The picture of `region` (the drawing space) at width x height pixels, as the engine's rasterizer draws it.
    Result<Image> rasterize(const VecRect* region, int width, int height);
    // The colours of the project's style palette ("#rrggbb"); empty when the project has none (assets.json "style").
    const std::vector<std::string>& palette() const { return palette_; }
    // The text for the status line (what the last action did or why it could not).
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }

    // ---- selection -------------------------------------------------------------------------------------------------
    // Elements are named by VecItem::ref: the id, or a selector for an element with no id (an edit gives it an id first).
    const std::vector<std::string>& selection() const { return selection_; }
    std::vector<int> selected_items() const;
    bool is_selected(const std::string& ref) const;
    void select(const std::vector<std::string>& refs);
    void toggle_selected(const std::string& ref);
    void add_to_selection(const std::string& ref);
    void clear_selection();
    void select_all();                                  // every element of the current group level
    bool selection_bounds(VecRect& out, bool visual = true) const;
    // The group the user went into (double click); clicks pick the children of it. "" = the top level.
    const std::string& context() const { return context_; }
    void enter_group(const std::string& ref);
    // Makes `ref` (a group, or "" for the top level) the level clicks pick at, keeping the selection.
    void set_context(const std::string& ref) { context_ = ref; nodeSel_.clear(); }
    void leave_group();
    // The element a click at `p` picks at the current group level (-1 = none). `tolerance` is in drawing units.
    int pick(VecPoint p, double tolerance) const;
    // The elements a marquee picks at the current group level.
    std::vector<int> marquee(const VecRect& box, bool touch) const;
    // The node selection of the Node tool.
    const std::vector<VectorNodeRef>& selected_nodes() const { return nodeSel_; }
    void select_nodes(const std::vector<VectorNodeRef>& nodes) { nodeSel_ = nodes; }
    void toggle_node(const VectorNodeRef& n);
    bool node_selected(const VectorNodeRef& n) const;

    // ---- edits (each one is ONE undo step) -------------------------------------------------------------------------
    // Runs a vector.* command on the open SVG. Elements named by an id or selector in `elements`, `element`, `parent` or `before` of
    // `args` (and the selection) that have no id get one first (vector.assign_ids), in the same undo step. The command's own arguments
    // (source / svg / document / layer / bake / preview) are added here.
    VectorEditOutcome edit(const std::string& label, const std::string& command, Json args);
    // The same with `elements` = the selection.
    VectorEditOutcome edit_selection(const std::string& label, const std::string& command, Json args = Json::object());
    // Slider and handle drags: preview_edit shows the result of the command on the canvas without touching the disk (run it again for
    // each mouse position); commit_preview makes the last one a real edit (one undo step); cancel_preview forgets it.
    bool preview_edit(const std::string& command, Json args);
    bool previewing() const { return previewing_; }
    VectorEditOutcome commit_preview(const std::string& label);
    void cancel_preview();

    // The common edits, built from the commands above.
    VectorEditOutcome move_selection(double dx, double dy);                          // vector.transform translate
    VectorEditOutcome delete_selection();                                            // vector.delete
    VectorEditOutcome duplicate_selection(double dx = 0, double dy = 0);             // vector.duplicate (the copies are selected)
    VectorEditOutcome group_selection();                                             // vector.group (the group is selected)
    VectorEditOutcome ungroup_selection();                                           // vector.ungroup
    VectorEditOutcome set_style(const Json& props, const std::string& label = "Change style");    // vector.set on the selection
    VectorEditOutcome set_hidden(const std::string& ref, bool hidden);
    VectorEditOutcome set_locked(const std::string& ref, bool locked);
    VectorEditOutcome rename(const std::string& ref, const std::string& id);
    // Moves elements in the drawing order or into another group: `to` front|back|forward|backward, or `parent` ("root" or a group) and
    // `before` (an element; "" = the end of the parent).
    VectorEditOutcome reorder(const std::vector<std::string>& refs, const std::string& to);
    VectorEditOutcome regroup(const std::vector<std::string>& refs, const std::string& parent, const std::string& before);
    // Boolean operation on the selection (union, subtract, intersect, exclude); the result is selected.
    VectorEditOutcome boolean_op(const std::string& op);
    // Adds a shape at the level the user is in (the current group) and selects it.
    VectorEditOutcome add_rect(VecPoint a, VecPoint b);
    VectorEditOutcome add_ellipse(VecPoint a, VecPoint b);
    VectorEditOutcome add_line(VecPoint a, VecPoint b);
    // A parametric vector.shape kind (star, gear, polygon, arrow, bubble, ribbon) dragged out as a box (a, b) with `args` as its parameters.
    VectorEditOutcome add_shape(const std::string& kind, VecPoint a, VecPoint b, const Json& args);
    // Redraws the parametric shape `ref` with new parameters (vector.shape replace). preview_ = live.
    VectorEditOutcome set_shape_args(const std::string& ref, const std::string& kind, const Json& args);
    bool preview_shape_args(const std::string& ref, const std::string& kind, const Json& args);
    // Node operations on one shape ([{"op": "move", ...}], docs/VECTOR.md vector.nodes) in the drawing space.
    VectorEditOutcome node_ops(const std::string& shape, const Json& ops, const std::string& label = "Edit nodes");
    bool preview_node_ops(const std::string& shape, const Json& ops);
    // The nodes of the element `ref` with their handles, in the drawing space (empty when it is not a shape).
    const VecNodePath* nodes_of(const std::string& ref) const;
    VectorStyle style;                                  // what new shapes get

    // ---- the pen ---------------------------------------------------------------------------------------------------
    const VectorPen& pen() const { return pen_; }
    // A press of the mouse: a new node at `p` (the first node of a closed path when `p` is within `tolerance` of it and closes the path:
    // returns true then, and the caller finishes the pen). `continuePath`: a press on the end node of the selected open path continues it.
    bool pen_press(VecPoint p, double tolerance);
    void pen_drag(VecPoint p);                          // the mouse moves with the button down: the node's out handle follows
    void pen_release();
    // Continues the open path `shape` from the end (or the start) of its subpath.
    bool pen_continue(const std::string& shape, int subpath, bool atEnd);
    // Ends the path: writes it (vector.add for a new one, vector.nodes append for a continued one) and selects it.
    VectorEditOutcome pen_finish(bool close);
    void pen_cancel();
    // A new path needs at least two nodes (one for a point that is going to be continued, which writes nothing).
    bool pen_can_finish() const;

    // ---- snapping --------------------------------------------------------------------------------------------------
    VectorSnapSettings snapping;
    std::vector<double> guidesX, guidesY;
    // The point `p` moved onto the nearest grid line, guide or point of the drawing within `tolerance` (drawing units); the shapes in
    // `exclude` (the ones being moved) do not attract.
    VecPoint snap_point(VecPoint p, double tolerance, const std::vector<std::string>& exclude, VectorSnapKind* kind = nullptr) const;
    // The move `delta` of `box` corrected so that its edges, centre or corners land on a snap target.
    VecPoint snap_move(const VecRect& box, VecPoint delta, double tolerance, const std::vector<std::string>& exclude) const;

    // ---- saving ----------------------------------------------------------------------------------------------------
    // The edits are on disk already. For an svg layer of an image document, Save bakes the document's PNG (image.save).
    VectorEditOutcome save();

    // ---- undo ------------------------------------------------------------------------------------------------------
    const VectorStep* step(int id) const;
    // Puts the files of step `id` back as they were before (forward = false) or after it, and reads them again.
    bool apply_step(int id, bool forward);
    void retain_steps(const std::set<int>& keep);
    void drop_step(int id) { steps_.erase(id); }
    std::size_t step_count() const { return steps_.size(); }
    std::string step_document(int id) const;
    // A step's undo / redo is about to be applied on a file that is not open: the layer the panel must open first ("" = the file only).
    std::string step_layer(int id) const;

private:
    bool load_from_disk();
    void load_palette();
    bool read_text(std::string& svg, std::string& why);
    bool rescene(const std::string& text);
    Json target_args() const;
    std::set<std::string> tracked_paths() const;
    VectorBlob blob_of(const std::string& rel);
    VectorFileSet capture(const std::set<std::string>& paths);
    bool restore(const VectorFileSet& files);
    void note_error(const std::string& m);
    void remap(const std::map<std::string, std::string>& mapping);
    bool resolve_ids(Json& args, std::string& error);
    std::uint64_t compute_stamp() const;
    VectorEditOutcome fail(VectorEditOutcome out, const std::string& message);

    std::string projectDir_;
    VectorCommandFn call_;
    std::string rel_, layer_, layerPath_, layerSource_, error_, status_;
    bool isLayer_ = false;
    bool valid_ = false;
    std::string svg_, shown_;
    bool previewing_ = false;
    std::string previewCommand_;
    Json previewArgs_;
    VecScene scene_;
    std::uint64_t rev_ = 0;
    std::uint64_t stamp_ = 0;
    double sceneMs_ = 0, rasterMs_ = 0;
    std::vector<std::string> selection_;
    std::string context_;
    std::vector<VectorNodeRef> nodeSel_;
    std::vector<std::string> palette_;
    VectorPen pen_;
    std::map<std::string, VectorBlob> fileCache_;
    std::map<int, VectorStep> steps_;
    int nextStep_ = 1;
};

}  // namespace fa::editor
