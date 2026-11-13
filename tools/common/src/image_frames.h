// Private declarations of the frames and tags of image documents (docs/IMAGES.md, "Frames and tags"). The format and the bake are in
// fa/tooling/image_doc.h; this is what the editing commands need:
//
//   a timeline   what every pixels / indexed layer shows in every frame, as a plain table (held cels and links followed). The frame
//                commands change the table and write it back as the shortest `cels` list that spells it out.
//   FrameScope   makes an existing command (image.pixel, image.draw, image.edit, image.paint, ...) work on one frame: while it lives,
//                find_layer hands out the layer as it is in that frame, and commit_document folds the result back into a cel.
//
//   image_frames.cpp   the timeline, FrameScope and the frame / tag helpers
//   image_frame_commands.cpp   image.frame.* and image.tag.*
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "image_edit.h"

namespace fa::imgedit {

// ---- the timeline ---------------------------------------------------------------------------------------------------

// What one layer shows in one frame.
struct CelData {
    bool empty = false;             // nothing
    std::string source;             // pixels: a PNG of the project
    std::vector<std::string> rows;  // indexed: the picture as text rows
    int x = 0, y = 0;               // where its top-left corner lands, in the layer's own coordinates
    float opacity = 1;
    bool
    same(const CelData& other,
         const std::string& projectDir) const;  // the same picture, place and opacity (pixels: the same file or bytes)
};

// The layers that can have cels (pixels and indexed), in document order, depth first.
struct TimelineLayer {
    std::string pointer;  // "/layers/1/layers/0"
    bool indexed = false;
    std::vector<CelData> frames;  // one per frame
};

// The frame count of the document JSON (1 when it has no `frames`).
int json_frame_count(const Json& doc);
bool json_animated(const Json& doc);

// What `layer` shows in each of `frames` frames (an invalid cel is skipped, as a parse error would report it).
std::vector<CelData> layer_cels(const Json& layer, int frames);
// Writes `cels` into `layer`: its own `source` / `rows` / x / y are frame 0, the shortest `cels` list spells out the rest (a frame equal
// to the one before has none; a frame equal to an earlier one that is not the one before links to it).
void write_layer_cels(Json& layer, const std::vector<CelData>& cels, const std::string& projectDir);

std::vector<TimelineLayer> load_timeline(const Json& doc);
void store_timeline(Json& doc, const std::vector<TimelineLayer>& layers, const std::string& projectDir);

// Makes the document animated or a still again: `frames` is written (durations, in milliseconds) when there are several frames, a tag or
// a sheet setting, and left out otherwise.
void normalize_animation(Json& doc);

// Frame numbers as the commands take them: an integer in 0 .. count - 1 (an error with the range and a fix otherwise).
int frame_number(const char* command, const Json& value, const std::string& pointer, int count,
                 const char* what = "frame");

// ---- working on one frame -------------------------------------------------------------------------------------------------

// Parses the `frame` and `onion` arguments of a command and, for an animated document or a frame other than 0, makes the command work on
// that frame until the scope ends. A document with one frame and no `frame` argument leaves the command exactly as it was.
class FrameScope {
public:
    // `doc` is the JSON the command is editing: the scope is the ambient frame for it only. Throws a CommandError for a bad argument.
    FrameScope(const std::string& projectDir, const std::string& rel, Json& doc, const Json& args, const char* command);
    ~FrameScope();
    FrameScope(const FrameScope&) = delete;
    FrameScope& operator=(const FrameScope&) = delete;

    bool active() const { return active_; }
    int frame() const { return frame_; }
    int frames() const { return frames_; }
    const std::optional<ImageOnionSkin>& onion() const { return onion_; }
    bool frame_given() const { return frameGiven_; }  // the command got a `frame` argument

    // A layer the command has just added (index path "1" or "1/0", as add_pixels_layer returns it) shows its picture in this frame only
    // and nothing in the others. Does nothing without a `frame` argument or in a document of one frame: the new layer then shows in
    // every frame, as it always did.
    void confine_new_layer(Json& doc, const std::string& indexPath);

    // The scope of the running command (nullptr outside one, or when it has none).
    static FrameScope* current();
    // Called by find_layer for the document the scope belongs to: the layer is replaced by what it shows in the frame, with a file of its
    // own to write.
    void open_layer(const Json& doc, const LayerRef& ref);
    // `doc` with every layer that was opened folded back: its picture is the cel of the frame, the rest of the frames unchanged. The
    // files that did not change are deleted.
    Json folded(const Json& doc);
    // Records provenance for the files the command wrote for the frame (called once the document is saved).
    void record_files(const std::string& command);

private:
    struct Opened {
        std::string pointer;
        bool indexed = false;
        std::vector<CelData> original;  // the layer's cels before the command
        std::string clone;              // pixels: the file the command writes
        bool kept = false;
    };
    std::string projectDir_, rel_, command_;
    const Json* doc_ = nullptr;
    bool active_ = false;
    bool frameGiven_ = false;
    int frame_ = 0, frames_ = 1;
    std::optional<ImageOnionSkin> onion_;
    std::vector<Opened> opened_;
    FrameScope* previous_ = nullptr;
};

// Adds the `frame` and `onion` properties to the command's input schema and a sentence to its description. `what` finishes "Which frame of
// an animated document <what>".
void add_frame_support(CommandInfo& info, const char* what, bool withOnion = true, const char* tail = nullptr);
// The keys check_arg_keys must let through for those properties.
void add_frame_keys(std::vector<std::string>& keys);

// After a command saved the document: deletes the cel pictures the old document read from its `<name>.layers/` folder that nothing reads any
// more (a removed frame, a cleared or replaced cel, a removed layer), and returns their project paths. Only a PNG directly in that folder
// goes; a file that the new document still names anywhere, or that another image document of the project names, stays. Their
// assets.json records go with them. Nothing happens unless one of the two documents is animated.
std::vector<std::string> prune_orphan_cels(const std::string& projectDir, const std::string& rel, const Json& oldDoc,
                                           const Json& newDoc);

// The picture of the document at one frame (with the onion skin when given); None when the document does not load.
std::optional<Image> render_frame_json(const std::string& projectDir, const Json& doc, int frame,
                                       const std::optional<ImageOnionSkin>& onion = std::nullopt);

// Writes the PNG (with optional onion skin) to .factoria/previews/<rel>.png scaled by whole pixels and returns the result's `$image`,
// or null when it cannot. Used by the frame commands.
Json frame_preview(const std::string& projectDir, const std::string& rel, const Json& doc, int frame,
                   const std::optional<ImageOnionSkin>& onion, int scale);

void register_frame_commands(CommandRegistry& registry, const std::string& projectDir);  // image_frame_commands.cpp

}  // namespace fa::imgedit
