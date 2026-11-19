// The Graph panel's live preview: the material as it is being edited (not as saved) drawn on a sphere, a cube or a flat quad by the engine's own
// renderer (Renderer::capture_world on a scratch World that holds one mesh and one light), so what the preview shows is what the game shows. A
// sprite material is drawn on a 2D quad (a Sprite with the material) instead of on a mesh. A post material is drawn as a pass of a camera: a small
// scratch scene (lit shapes at several depths over a sky) seen by a Camera whose PostProcess.customPasses holds only the material, captured with
// Renderer::capture_camera over kPreviewPostFrames frames (so fa_history has a frame before it, and fa_depth / fa_normal have their prepass).
//
// Every edit changes the document; the preview waits for the edits to stop (kDebounceFrames frames without one), then
//   1. generates the snippet in memory (check_material_document, the code of material.graph.generate): an error there is shown and nothing else runs;
//   2. compiles the material on a WORKER thread with the engine's shader compiler (compile_material, sokol-shdc, for the dialect of the renderer's
//      backend), which fills the content-keyed shader cache; the UI thread never waits for it (poll only);
//   3. when the compile is done and still current, writes the material and snippet to .factoria/material-preview/ (the files the renderer reads),
//      tells the renderer to reload them (a cache hit now: no process) and draws.
// A compile error is shown with its line and the quoted snippet line, and the last good picture stays. When the line belongs to a node (the generator
// keeps the map, GeneratedGraph::lineNodes) the node is named in node_errors(), and the panel paints it red with the message.
//
// Params: the preview can show the material with other values than the ones in the file. set_param() overrides one param of the PREVIEW only (it becomes
// MeshRenderer.materialParams or Sprite.materialParams of the scratch entity, so no file is touched and nothing compiles again); the overrides go away when
// the document is another material. The panel's "Set as default" button writes a value into the file through the model (material.param.set_default).
//
// Compare: with set_compare(true) and a saved document (set_saved_document) the preview also draws the last SAVED version of the graph, next to the
// current one, with the same shape and the same param values; it compiles on its own worker, in its own files.
//
// tick() must run OUTSIDE the editor's UI build (capture_world commits the GPU frame): the editor calls it before ui::new_frame.
#pragma once

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/world.h"
#include "fa/tooling/shaders.h"

namespace fa {
class Renderer;
}

namespace fa::editor {

enum class PreviewShape { Sphere, Cube, Quad };

enum class PreviewState {
    Empty,      // no document
    Waiting,    // edits are still arriving (the debounce)
    Compiling,  // the worker is compiling
    Ready,      // the picture is the latest document
    Error,  // the latest document does not check or does not compile: message() says why; the last good picture stays
    NoRenderer,  // the editor has no GPU renderer (a headless run): nothing to draw with
    Unsupported  // the kind of the material is one the preview cannot draw (sky, compute): message() says why; no picture
};

// What the preview draws a material of a given kind with.
enum class PreviewKind { Mesh, Sprite, Post, None, Unknown };
struct PreviewPlan {
    PreviewKind kind = PreviewKind::Unknown;
    std::string reason;  // None: why the preview cannot show this kind
};
PreviewPlan preview_plan(const std::string& materialKind);

// A compile error that belongs to a node of the graph: the generator wrote the line the compiler complained about.
struct PreviewNodeError {
    std::string node;  // the node id
    int line = 0;      // the line of the generated snippet
    std::string message;
};
// Maps the issues of a failed compile to the nodes that wrote their lines (`lineNodes` is GeneratedGraph::lineNodes). An issue on a line no node wrote
// (a helper function, a brace, a JSON error of the material) is left out: the panel keeps showing the whole message for those. One entry per
// node and line, in order.
std::vector<PreviewNodeError> map_compile_errors(const std::vector<ShaderIssue>& issues,
                                                 const std::vector<std::string>& lineNodes);

// A compile error says where: the preview compiles a copy under a stage name ("stage-<n>-<hex>.surface.glsl") that the worker has deleted by the time the
// message is read. This puts the file the user knows in its place: `stageSnippet` and `stageMaterial` (project-relative, or under `projectDir`) become
// `snippet` and `material` (the project-relative paths of the real snippet and material).
std::string name_real_files(std::string text, const std::string& projectDir, const std::string& stageMaterial,
                            const std::string& stageSnippet, const std::string& material, const std::string& snippet);

// Frames without an edit before the preview starts (a frame is ~16 ms: the user has stopped typing or dragging).
inline constexpr int kPreviewDebounceFrames = 18;
inline constexpr int kPreviewSide = 256;  // pixels of the picture
inline constexpr int kPreviewPostFrames =
    4;  // frames of a post material's capture: the passes that read their history see three before the last
inline constexpr int kPreviewMaxMessage = 4000;

class GraphPreview {
public:
    explicit GraphPreview(std::string projectDir);
    // A compile that is running (at most one per picture, sokol-shdc takes about a second) is waited for up to kCloseWaitMs in all, so changing the project
    // or quitting the editor (the only times a GraphPreview is destroyed) normally leaves no thread behind; one that is still running after that is let go (it only holds copies and its own
    // stage files) and ends by itself.
    ~GraphPreview();
    static constexpr int kCloseWaitMs = 2000;
    // Files `stage-*` and `saved-stage-*` in .factoria/material-preview/ that are older than `olderThanSeconds`: what an editor that quit with a compile
    // still running left behind (the worker removes its own files when it ends). The constructor removes them. A file that cannot be removed (open
    // elsewhere on Windows) is left for the next time, with no error. Looks at the first few thousand entries only. Returns how many it removed.
    static int remove_stale_stage_files(const std::string& projectDir, int olderThanSeconds = kStaleStageSeconds);
    static constexpr int kStaleStageSeconds = 600;

    // The material to show (the file's JSON with the graph as edited) and the model's revision, which tells a new edit from the same document.
    // `path` names the material: when it changes the param overrides, the pictures and the saved document are dropped (a new material starts clean).
    void set_document(const Json& material, std::uint64_t revision, const std::string& path = {});
    void clear();
    void set_shape(PreviewShape newShape);
    PreviewShape shape() const { return shape_; }
    // Draw again every few frames (a graph that reads the clock moves).
    void set_animated(bool on) { animated_ = on; }
    bool animated() const { return animated_; }
    // Test hooks: no debounce; compile on the calling thread.
    void set_immediate(bool on) { immediate_ = on; }

    // ---- params of the preview (never written to the file)
    // Overrides param `name` with `value` (a number, or an array of numbers of the param's size) and draws again. Null removes the override.
    void set_param(const std::string& name, const Json& value);
    void reset_params();
    const Json& param_overrides() const { return overrides_; }  // {name: value}
    // The overrides that still fit the material (a param that was removed, or whose type changed, loses its override): called by set_document.
    static Json fitting_overrides(const Json& overrides, const Json& material);

    // ---- compare with the saved version
    void set_compare(bool on);
    bool compare() const { return compare_; }
    // The material as it is in the file (its graph as last saved); nullptr when the graph was never saved. The revision tells a new version from the same one.
    void set_saved_document(const Json* material, std::uint64_t revision);
    bool has_saved() const { return saved_.haveDoc; }

    // Once per frame, before the UI is built.
    void tick(Renderer* renderer);

    // The current document's picture.
    PreviewState state() const { return cur_.state; }
    const std::string& message() const { return cur_.message; }  // an error, with its line; or ""
    const Image& image() const { return cur_.image; }
    std::uint64_t image_serial() const { return cur_.serial; }  // changes whenever image() does
    int compiles() const { return compiles_; }                  // how many compiles finished (the autotest waits on it)
    bool busy() const { return cur_.state == PreviewState::Waiting || cur_.state == PreviewState::Compiling; }
    std::uint64_t shown_revision() const { return cur_.shownRevision; }  // the revision the picture shows
    // The nodes whose generated lines the compiler refused (empty after the next edit, and when the error is not on a node's line).
    const std::vector<PreviewNodeError>& node_errors() const { return cur_.nodeErrors; }
    PreviewKind drawing() const {
        return cur_.drawKind;
    }  // what the current picture is drawn on (Mesh, Sprite or Post)
    // The saved version's picture (compare on).
    PreviewState saved_state() const { return saved_.state; }
    const std::string& saved_message() const { return saved_.message; }
    const Image& saved_image() const { return saved_.image; }
    std::uint64_t saved_image_serial() const { return saved_.serial; }
    std::uint64_t saved_shown_revision() const { return saved_.shownRevision; }

    // The material the renderer was last asked to draw (project-relative), for the autotest and the docs.
    static const char* material_path() { return ".factoria/material-preview/preview.material.json"; }
    // The files a compile of this instance writes before it reads them: "stage-<token>.material.json" and its snippet, the token being different for every
    // GraphPreview of this process and unlikely to repeat in another, so a compile that outlives its instance (see the destructor) never writes
    // the files the next one is compiling from. The worker removes them when it is done.
    const std::string& stage_material_path() const { return cur_.stageMaterial; }
    static const char* saved_material_path() { return ".factoria/material-preview/saved.material.json"; }

private:
    struct Job;
    struct Slot {
        Json doc;
        std::uint64_t revision = 0, shownRevision = 0;
        bool haveDoc = false;
        bool pending = false;  // the document is newer than the last compile: waits for the debounce, then starts one
        std::uint64_t generation =
            1;  // bumped when this slot's document is closed or replaced: a compile of an older one is dropped
        int quiet = 0;
        PreviewState state = PreviewState::Empty;
        std::string message;
        std::vector<PreviewNodeError> nodeErrors;
        Image image;
        std::uint64_t serial = 0;
        PreviewKind drawKind = PreviewKind::Mesh;
        std::string spriteTexture;  // a sprite material: the texture the quad shows ("" = the checker)
        bool drawn = false;
        bool redraw = false;  // the shape or a param value changed: draw the last compiled material again
        std::thread worker;
        std::shared_ptr<Job> job;
        std::string
            stageMaterial;  // the files of this picture (project-relative); the stage ones carry the instance's token
        std::string stageSnippet;
        std::string liveMaterial;
        std::string liveSnippet;
        std::string
            stageStem;  // the snippet's names without the extension, which depends on the kind (.surface.glsl, .post.glsl)
        std::string liveStem;
    };
    void tick_slot(Slot& s, Renderer* renderer);
    void start(Slot& s, Renderer* renderer);
    void finish(Slot& s, Renderer* renderer);
    void draw(Slot& s, Renderer* renderer, bool markReady);
    void build_world(PreviewKind kind);
    void build_post_scene();
    void finish_picture(Slot& s, Renderer* renderer, Image img, bool markReady);
    void drop_pictures();
    void note_unsupported(Slot& s, const std::string& why);

    std::string projectDir_;
    std::string path_;
    Slot cur_, saved_;
    bool compare_ = false;
    Json overrides_ = Json::object();
    bool immediate_ = false, animated_ = false;
    PreviewShape shape_ = PreviewShape::Sphere;
    int compiles_ = 0;
    int animFrame_ = 0;
    std::unique_ptr<World> world_;
    PreviewKind worldKind_ = PreviewKind::Unknown;
    Entity subject_ = kNullEntity;
    Entity camera_ = kNullEntity;  // a post material: the camera whose PostProcess holds the pass
    bool checkerWritten_ = false;
};

}  // namespace fa::editor
