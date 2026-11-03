// The logic of the editor's Image panel with no ImGui and no window: the document being edited, what the canvas shows, the layer
// tree, brush strokes, selections, the transform of a selection and the undo steps of all of them. image_panel.cpp draws it;
// image_tests.cpp and the autotest drive it.
//
// ONE SET OF CODE. Every edit that is kept is a call of an image.* command (image.paint, image.pixel, image.select, image.edit,
// image.layer.set, ...), the same call the Console, an AI or a script makes, and saving is image.save. The picture the panel shows
// while a stroke is going on or a slider is being dragged is made by the shared functions (fa/tooling/image_paint.h: the stamping of
// image.paint, the patches of image.edit; pixel_art.h for indexed layers) and the one compositor (composite_image_document with a
// `pictures` override for the pixels that are not on disk yet), so what you see is what the command writes when you let go.
//
// Edits write the document to disk as they happen (like the commands do, without baking); Save bakes the PNG. Undo is a table of
// steps: before and after contents of the files an edit changed (the document, the PNGs of the layers, the stored selection). The
// editor's undo stack holds only {"$image": {step}} entries that point into this table (the same idea as the "$clip" entries of the
// Animation panel), so Ctrl+Z / Ctrl+Y undo scene edits and image edits in the order they were made.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/image_paint.h"
#include "fa/tooling/pixel_art.h"

namespace fa::editor {

using ImageCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;

enum class ImageTool { Move, Brush, Eraser, Fill, Picker, SelectRect, SelectEllipse, SelectLasso, SelectPolygon, Wand, Transform };
const char* image_tool_name(ImageTool tool);
// The tools the panel's toolbar lists, in order.
const std::vector<ImageTool>& image_tools();
bool image_tool_selects(ImageTool tool);

enum class SelectOp { Replace, Add, Subtract, Intersect };
const char* select_op_name(SelectOp op);   // the `mode` of image.select

struct ImageBrushSettings {
    double size = 8;                // diameter in pixels
    double hardness = 1;
    double opacity = 1;
    Color color{0, 0, 0, 1};        // pixels layers
    int paletteIndex = 0;           // indexed layers: the palette colour (-1 = erase)
};

struct ImageWandSettings {
    int tolerance = 16;
    bool contiguous = true;
};

// The contents of the files an edit touches, by project-relative path. A null blob = the file does not exist.
using ImageBlob = std::shared_ptr<const std::string>;
using ImageFileSet = std::map<std::string, ImageBlob>;

struct ImageStep {
    int id = 0;
    std::string rel;                // the document
    std::string label;
    ImageFileSet before, after;
};

struct ImageLayerRow {
    std::string path;               // index path: "1", "1/0"
    int depth = 0;
    std::string name;
    ImageLayerKind kind = ImageLayerKind::Fill;
    bool visible = true;
    float opacity = 1;
    ImageBlend blend = ImageBlend::Normal;
    bool isGroup = false;
    bool open = true;               // a group: its children are listed
    bool locked = false;
    bool clip = false;
    int childCount = 0;
};

struct ImageEditOutcome {
    bool ok = true;
    std::string error;              // what went wrong, with the command's hint
    int step = 0;                   // the undo step it recorded (0 = the edit changed nothing on disk)
    Json result;                    // the last command's result
};

// One edge between a selected and an unselected pixel (marching ants), canvas coordinates.
struct ImageEdge {
    float x0, y0, x1, y1;
};

// The fields of an adjustment or effect, for the inspector and for the entry a new one starts with. Every type of image_adjustment_types()
// and image_effect_types() has a row (the model test checks it).
struct ImageOpField {
    enum class Kind { Number, Int, Bool, Choice, Color, Text, Vec3, Curve, Stops } kind = Kind::Number;
    std::string key, label;
    double min = 0, max = 1, def = 0;       // Number, Int, Vec3 (range of each component)
    std::vector<std::string> options;       // Choice; "" in the list = leave the key out
    std::string defText;                    // Choice, Color, Text
    bool optional = false;                  // a new operation does not write it (the engine default applies)
};
const std::vector<ImageOpField>& image_op_fields(const std::string& type, bool effect);

class ImageModel {
public:
    ImageModel(std::string projectDir, ImageCommandFn call);

    // ---- the document ----------------------------------------------------------------------------------------------
    bool open(const std::string& rel);              // false: error() says why
    void close();
    bool is_open() const { return !rel_.empty(); }
    bool valid() const { return valid_; }           // the document loads (it may be open and broken: error() has the reason)
    const std::string& path() const { return rel_; }
    const std::string& error() const { return error_; }
    const Json& json() const { return json_; }
    const ImageDocument& doc() const { return doc_; }
    int width() const { return doc_.width; }
    int height() const { return doc_.height; }
    // The document changed on disk behind our back (an AI, the Console, an editor): reloads it. Returns true when it did.
    bool poll_external();
    bool reload();
    ImageBakeStatus bake_status() const { return bake_; }
    std::uint64_t doc_revision() const { return docRev_; }   // changes every time the document is read again

    // ---- the picture -----------------------------------------------------------------------------------------------
    // What the canvas shows: the composite of the current frame, with the stroke / transform / slider being dragged. Recomposited on
    // demand: call it once per frame.
    const Image& picture();
    std::uint64_t revision() const { return pictureRev_; }
    // Milliseconds the last composite took (the panel shows it in the status line; the autotest logs it).
    double last_composite_ms() const { return compositeMs_; }
    std::uint64_t composites() const { return composites_; }

    // ---- frames ----------------------------------------------------------------------------------------------------
    bool animated() const { return doc_.animated || image_frame_count(doc_) > 1; }
    int frame_count() const { return image_frame_count(doc_); }
    int frame() const { return frame_; }
    void set_frame(int frame);
    bool onion() const { return onion_; }
    void set_onion(bool on);
    int frame_duration(int frame) const;

    // ---- layers ----------------------------------------------------------------------------------------------------
    std::vector<ImageLayerRow> layer_rows() const;  // top first, depth first; a closed group hides its children
    const std::string& selected_layer() const { return selected_; }
    void select_layer(const std::string& path);
    const ImageLayer* layer(const std::string& path) const;
    const Json* layer_json(const std::string& path) const;
    // x, y of the groups a layer sits in.
    std::pair<int, int> parent_offset(const std::string& path) const;
    bool is_locked(const std::string& path) const;
    void set_locked(const std::string& path, bool locked);
    bool is_open(const std::string& path) const;
    void set_open(const std::string& path, bool open);
    // Whether the tools can draw on the layer, and if not why (a sentence for the status line).
    bool paintable(const std::string& path, std::string* why = nullptr) const;

    ImageEditOutcome add_layer(const std::string& kind);          // above the selected layer (inside its group), selects it
    ImageEditOutcome duplicate_layer(const std::string& path);
    ImageEditOutcome remove_layer(const std::string& path);
    ImageEditOutcome rename_layer(const std::string& path, const std::string& name);
    ImageEditOutcome set_layer(const std::string& path, const Json& set, const std::string& label = "Change layer");
    // Moves a layer to `index` (0 = the bottom) of the group `parent` ("" = the top level).
    ImageEditOutcome move_layer(const std::string& path, const std::string& parent, int index);
    // Slider drags: preview_layer shows `set` merged into the layer without touching the disk; commit_preview makes it an edit
    // (one undo step); cancel_preview forgets it.
    void preview_layer(const std::string& path, const Json& set);
    bool previewing() const { return !previewSet_.is_null(); }
    ImageEditOutcome commit_preview(const std::string& label = "Change layer");
    void cancel_preview();

    // ---- adjustments and effects ("adjustments" / "effects" of the layer) ------------------------------------------
    // The entry a new adjustment / effect of `type` starts with (every type of image_adjustment_types() / image_effect_types() has one).
    static Json default_operation(const std::string& type, bool effect);
    ImageEditOutcome add_operation(const std::string& path, bool effect, const std::string& type);
    ImageEditOutcome remove_operation(const std::string& path, bool effect, int index);
    ImageEditOutcome move_operation(const std::string& path, bool effect, int from, int to);
    // Shows the operation `index` with `fields` merged in (live preview of a drag) / keeps it.
    void preview_operation(const std::string& path, bool effect, int index, const Json& fields);
    ImageEditOutcome commit_operation_preview(const std::string& label = "Change adjustment");

    // ---- selections ------------------------------------------------------------------------------------------------
    static constexpr const char* kSelectionName = "selection";
    bool has_selection() const { return !selection_.empty(); }
    const ImageSelection& selection() const { return selection_; }
    std::uint64_t selection_revision() const { return selRev_; }
    // The box of the pixels with coverage >= 128 (false when nothing is selected).
    bool selection_bounds(int& x, int& y, int& w, int& h) const;
    // The edges of the selection for the marching ants (cached; at most `kMaxEdges`; more = the panel tints instead).
    const std::vector<ImageEdge>& selection_edges();
    static constexpr std::size_t kMaxEdges = 60000;
    bool selection_edges_truncated() const { return edgesTruncated_; }
    ImageEditOutcome select_rect(int x, int y, int w, int h, SelectOp op);
    ImageEditOutcome select_ellipse(int x, int y, int w, int h, SelectOp op);
    ImageEditOutcome select_polygon(const std::vector<std::pair<double, double>>& points, SelectOp op);
    ImageEditOutcome select_wand(int x, int y, const ImageWandSettings& wand, SelectOp op);
    ImageEditOutcome select_all();
    ImageEditOutcome deselect();
    ImageEditOutcome selection_grow(double px);
    ImageEditOutcome selection_shrink(double px);
    ImageEditOutcome selection_feather(double px);
    ImageEditOutcome selection_invert();

    // ---- brush strokes ---------------------------------------------------------------------------------------------
    // erase = true: the eraser. On an indexed layer the stroke is palette-exact (size = square/round stamp of whole pixels, no
    // anti-aliasing; hardness and opacity do not apply). Returns false (see status()) when the layer cannot be painted.
    bool begin_stroke(bool erase, const ImageBrushSettings& brush, double x, double y);
    void stroke_to(double x, double y);
    ImageEditOutcome end_stroke();
    void cancel_stroke();
    bool stroking() const { return live_.kind == Live::Kind::Stroke; }
    // Bucket fill at a canvas pixel: a pixels layer fills the connected area of similar colour (inside the selection when there is
    // one); an indexed layer flood-fills with the palette colour.
    ImageEditOutcome fill_at(int x, int y, const ImageBrushSettings& brush, int tolerance);
    // The colour of the picture at a canvas pixel (straight alpha), and on an indexed layer the palette index there (-1 = none).
    std::optional<Color> pick_color(int x, int y) const;
    int pick_index(int x, int y) const;
    // The pixels of the stroke being painted on an indexed layer (tests).
    static std::vector<PixelPoint> indexed_stamp(const std::vector<std::pair<double, double>>& points, double size);

    // ---- move and transform of the selection (or of the layer) ----------------------------------------------------
    // The Move tool: dragging pixels of a selection (a pixels layer) or the whole layer (any kind: its x, y).
    bool begin_move();
    void move_by(int dx, int dy);
    ImageEditOutcome end_move();
    bool moving() const { return live_.kind == Live::Kind::Move; }
    // The Transform tool: scale, rotate and flip the selected pixels (the whole layer without a selection).
    struct TransformState {
        bool active = false;
        double scaleX = 1, scaleY = 1;
        double rotate = 0;          // degrees, clockwise
        bool flipH = false, flipV = false;
        int dx = 0, dy = 0;         // whole pixels
        bool nearest = false;
        int boxX = 0, boxY = 0, boxW = 0, boxH = 0;   // the box of the pixels being transformed (canvas), before any change
        double pivotX = 0, pivotY = 0;
    };
    bool begin_transform();
    const TransformState& transform() const { return live_.tf; }
    bool transforming() const { return live_.kind == Live::Kind::Transform; }
    void set_transform(double scaleX, double scaleY, double rotate, bool flipH, bool flipV, int dx, int dy);
    void set_transform_nearest(bool nearest);
    ImageEditOutcome apply_transform();
    void cancel_transform();

    // ---- palette (indexed layers) ----------------------------------------------------------------------------------
    const PixelPalette& palette() const { return doc_.palette; }
    ImageEditOutcome set_palette_color(int index, const std::string& hex);

    // ---- saving ----------------------------------------------------------------------------------------------------
    // Writes the document and bakes its PNG (image.save). Returns the command's result (its `output`, `sha256`, ...).
    ImageEditOutcome save();

    // ---- undo ------------------------------------------------------------------------------------------------------
    const ImageStep* step(int id) const;
    // Puts the files of step `id` back as they were before (forward = false) or after it (forward = true), reloads the document if it
    // is the open one. False and error() when a file cannot be written.
    bool apply_step(int id, bool forward);
    // Merges step `second` into `first` (first.after = second.after): a slider drag is one undo step.
    void merge_steps(int first, int second);
    // Drops the steps that are not in `keep` (the editor's stacks).
    void retain_steps(const std::set<int>& keep);
    // Forgets a step that did not change anything or that the editor could not keep.
    void drop_step(int id) { steps_.erase(id); }
    std::size_t step_count() const { return steps_.size(); }
    // A step's undo / redo is about to be applied on a document that is not open: the panel opens it first.
    std::string step_document(int id) const;
    // The text for the status line (what the last action did or why it could not).
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }

private:
    struct Live {
        enum class Kind { None, Stroke, Move, Transform } kind = Kind::None;
        std::string layer;                  // index path
        bool indexed = false;
        bool erase = false;
        ImageBrushSettings brush;
        std::vector<std::pair<double, double>> points;
        std::optional<ImageSelection> sel;  // the selection a stroke is limited to
        // pixels layers
        ImageEditBuffer base;               // the layer's pixels when the gesture began
        Image work;                         // the pixels being shown
        // indexed layers
        IndexGrid gridBase, grid;
        int gridX = 0, gridY = 0;           // canvas position of the grid's top-left pixel
        std::vector<std::string> baseRows;  // transform / move preview of an indexed layer's offset uses layerSet instead
        // move of the whole layer
        Json layerSet;                      // {"x":..,"y":..}
        int layerX0 = 0, layerY0 = 0;
        int moveDx = 0, moveDy = 0;
        // transform / pixel move
        ImagePatch patch;
        Image erased;                       // base with the selected pixels taken out
        ImageSelection selAll;
        bool useAll = false;
        bool wholeLayer = false;            // Move without a selection: the layer's x, y change
        bool stale = true;                  // `work` / `grid` must be made again from the points / offsets
        TransformState tf;
    };

    // ---- internals
    bool load_from_disk();
    void recomposite();
    Json preview_document() const;          // the document JSON with the drag / stroke applied, and the pictures it needs
    // Runs the commands one after the other as ONE undo step; `prepare` runs after the files were captured (it may write files an
    // edit needs: a copy of a PNG, the temporary selection of a fill).
    using Calls = std::vector<std::pair<std::string, Json>>;
    using Prepare = std::function<bool(std::string& error, Calls& calls)>;
    ImageEditOutcome run(const std::string& label, Calls calls, const Prepare& prepare = {});
    ImageEditOutcome run_select(Json args, const std::string& label);
    void update_live();
    bool apply_preview_json(ImageDocument& out) const;
    CommandResult call_image(const std::string& name, Json args, bool frameAware);
    ImageFileSet capture(const std::set<std::string>& paths);
    std::set<std::string> tracked_paths(const Json& doc) const;
    ImageBlob blob_of(const std::string& rel);
    bool restore(const ImageFileSet& files);
    void note_error(const std::string& m);
    void mark_dirty() { pictureDirty_ = true; }
    void refresh_selection();
    std::string unique_layer_name(const std::string& base) const;
    std::string find_path_by_name(const std::string& name) const;
    std::string lock_key(const std::string& path) const;

    std::string projectDir_;
    ImageCommandFn call_;
    std::string rel_, error_, status_;
    Json json_;
    ImageDocument doc_;
    bool valid_ = false;
    int frame_ = 0;
    bool onion_ = false;
    std::string selected_;
    std::set<std::string> lockedNames_, closedNames_;
    ImageBakeStatus bake_;
    std::uint64_t docRev_ = 0;
    std::uint64_t stamp_ = 0;               // size and times of the document and the files it names, to notice a change behind our back

    Image picture_;
    bool pictureDirty_ = true;
    std::uint64_t pictureRev_ = 0;
    double compositeMs_ = 0;
    std::uint64_t composites_ = 0;
    // The flattened layers under the one being edited (see recomposite).
    Image below_;
    std::map<std::string, Image> pics_;       // the stand-in pictures of one composite (see recomposite)
    std::string lastError_;
    std::string belowKey_;

    ImageSelection selection_;
    std::uint64_t selRev_ = 0;
    std::vector<ImageEdge> edges_;
    std::uint64_t edgesRev_ = ~std::uint64_t(0);
    bool edgesTruncated_ = false;

    Live live_;
    Json previewSet_;                       // layer preview: the fields
    std::string previewLayer_;
    bool previewOp_ = false, previewIsEffect_ = false;
    int previewOpIndex_ = 0;

    std::map<std::string, ImageBlob> fileCache_;   // the last contents read of each tracked file (equal contents share one blob)
    std::map<int, ImageStep> steps_;
    int nextStep_ = 1;
};

}  // namespace fa::editor
