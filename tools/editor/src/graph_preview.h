// The Graph panel's live preview: the material as it is being edited (not as saved) drawn on a sphere, a cube or a flat quad by the engine's own
// renderer (Renderer::capture_world on a scratch World that holds one mesh and one light), so what the preview shows is what the game shows.
//
// Every edit changes the document; the preview waits for the edits to stop (kDebounceFrames frames without one), then
//   1. generates the snippet in memory (check_material_document, the code of material.graph.generate): an error there is shown and nothing else runs;
//   2. compiles the material on a WORKER thread with the engine's shader compiler (compile_material, sokol-shdc, for the dialect of the renderer's
//      backend), which fills the content-keyed shader cache; the UI thread never waits for it (poll only);
//   3. when the compile is done and still current, writes the material and snippet to .factoria/material-preview/ (the files the renderer reads),
//      tells the renderer to reload them (a cache hit now: no process) and draws.
// A compile error is shown with its line and the quoted snippet line, and the last good picture stays.
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
    Error,      // the latest document does not check or does not compile: message() says why; the last good picture stays
    NoRenderer  // the editor has no GPU renderer (a headless run): nothing to draw with
};

// Frames without an edit before the preview starts (a frame is ~16 ms: the user has stopped typing or dragging).
inline constexpr int kPreviewDebounceFrames = 18;
inline constexpr int kPreviewSide = 256;  // pixels of the picture
inline constexpr int kPreviewMaxMessage = 4000;

class GraphPreview {
public:
    explicit GraphPreview(std::string projectDir);
    ~GraphPreview();  // waits for a compile that is running (at most one), never at an edit

    // The material to show (the file's JSON with the graph as edited) and the model's revision, which tells a new edit from the same document.
    void set_document(const Json& material, std::uint64_t revision);
    void clear();
    void set_shape(PreviewShape shape);
    PreviewShape shape() const { return shape_; }
    // Draw again every few frames (a graph that reads the clock moves).
    void set_animated(bool on) { animated_ = on; }
    bool animated() const { return animated_; }
    // Test hooks: no debounce; compile on the calling thread.
    void set_immediate(bool on) { immediate_ = on; }

    // Once per frame, before the UI is built.
    void tick(Renderer* renderer);

    PreviewState state() const { return state_; }
    const std::string& message() const { return message_; }  // an error, with its line; or ""
    const Image& image() const { return image_; }
    std::uint64_t image_serial() const { return serial_; }  // changes whenever image() does
    int compiles() const { return compiles_; }              // how many compiles finished (the autotest waits on it)
    bool busy() const { return state_ == PreviewState::Waiting || state_ == PreviewState::Compiling; }
    std::uint64_t shown_revision() const { return shownRevision_; }  // the revision the picture shows
    // The material the renderer was last asked to draw (project-relative), for the autotest and the docs.
    static const char* material_path() { return ".factoria/material-preview/preview.material.json"; }

private:
    struct Job;
    void start(Renderer* renderer);
    void finish(Renderer* renderer);
    void draw(Renderer* renderer);
    void build_world();

    std::string projectDir_;
    Json doc_;
    std::uint64_t revision_ = 0, requested_ = 0, shownRevision_ = 0;
    bool haveDoc_ = false;
    int quiet_ = 0;
    bool immediate_ = false, animated_ = false;
    PreviewShape shape_ = PreviewShape::Sphere;
    bool shapeChanged_ = false;
    PreviewState state_ = PreviewState::Empty;
    std::string message_;
    Image image_;
    std::uint64_t serial_ = 0;
    int compiles_ = 0;
    int animFrame_ = 0;
    std::thread worker_;
    std::shared_ptr<Job> job_;
    std::unique_ptr<World> world_;
    Entity meshEntity_ = kNullEntity;
    bool drawn_ = false;
};

}  // namespace fa::editor
