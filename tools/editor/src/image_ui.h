// The state of the Image panel (image_panel.cpp, image_canvas.cpp): what the user picked, how the canvas is looked at, what is being
// dragged. The rules that need no window (the document, the strokes, the selections, the undo steps) are in image_model.h.
#pragma once

#include <cstdint>
#include <memory>
#include <atomic>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include <thread>

#include "fa/ai/image_provider.h"
#include "image_model.h"

namespace fa::editor {

// A texture the panel owns. The panel makes a new one when the picture changes; the old one is destroyed a few frames later, when the
// draw list that named it has been drawn.
struct ImageTexture {
    std::uint32_t image = 0, view = 0;
    int w = 0, h = 0;
    std::uint64_t revision = ~std::uint64_t(0);
};

// A picture asked of an image provider from the panel (Inpaint selection / Generate layer). The planning (it reads the document, the style
// references and the price list), the cost check and the provider call run on the job's own thread and touch only `shared`; the answer is
// stored on the main thread (image_provider_panel.cpp).
// The asset run the Image panel's calls count into (ai::AssetRunScope): its own total for limits.maxAssetCostUsd.perRun, not the process's
// run "" that the CLI and external MCP clients share. A new project starts it again (Editor::ai_stop).
inline constexpr const char* kImagePanelRun = "image-panel";

struct ImageProviderShared {
    std::atomic<bool> cancel{false}, done{false}, planned{false};
    std::optional<ai::ImageEditPlan> plan;           // set before `planned` (and so before `done` when planning worked)
    std::optional<Result<ai::AssetResult>> result;   // set before `done`
    std::vector<std::string> warnings;               // of the cost check (the per-day file could not be read...); set before `done`
    double spentUsd = 0;                             // the estimate that was counted for the call (0 for a free one or a failure)
};
struct ImageProviderJob {
    bool inpaint = false;
    std::string doc;                    // the document the picture is for: the answer is dropped if another one is open by then
    std::shared_ptr<ImageProviderShared> shared;
    std::thread thread;
    double startedAt = 0;               // ImGui time, for the elapsed seconds
    ImageProviderJob() = default;
    ImageProviderJob(const ImageProviderJob&) = delete;
    ImageProviderJob& operator=(const ImageProviderJob&) = delete;
    ~ImageProviderJob() {
        if (shared) shared->cancel = true;
        if (thread.joinable()) thread.join();
    }
};

// The price of the popup's "Make it", worked out on a thread: planning reads the document, the style references and the price list,
// which is not work for the UI thread. The thread touches only this object (the configuration is copied in before it starts).
struct ImageProviderEstimate {
    std::atomic<bool> done{false};
    std::string doc;                    // the document it is for
    std::string text, error;            // set before `done`: the sentence to show, or why there is no estimate
    std::thread thread;
    ImageProviderEstimate() = default;
    ImageProviderEstimate(const ImageProviderEstimate&) = delete;
    ImageProviderEstimate& operator=(const ImageProviderEstimate&) = delete;
    ~ImageProviderEstimate() {
        if (thread.joinable()) thread.join();
    }
};

struct ImageUi {
    std::unique_ptr<ImageModel> model;
    std::string openError;          // why the document the user asked for could not be opened

    // ---- tools
    ImageTool tool = ImageTool::Brush;
    ImageBrushSettings brush;       // the primary colour (left button)
    int secondaryIndex = 1;         // the secondary colour (right button): a palette index on an indexed layer,
    Color secondaryColor{1, 1, 1, 1};   // a colour on a pixels layer
    int dragButton = 0;             // the mouse button of the drag in progress: 0 left, 1 right
    ImageWandSettings wand;
    SelectOp selectOp = SelectOp::Replace;
    float selectionPx = 2;          // grow / shrink / feather amount
    bool tint = false;              // the selection as a tint instead of marching ants
    bool nearestTransform = false;  // set when a transform starts from the layer kind

    // ---- the view
    float zoom = 1;
    float panX = 0, panY = 0;       // where the picture's top-left corner is, from the canvas's top-left (screen pixels)
    bool fitNext = true;            // fit the picture to the canvas on the next frame
    bool showGrid = true;           // the pixel grid, when zoomed in far enough (from kGridZoom, 800%)
    int gridMajor = 8;              // every Nth grid line is stronger (0 = none); a tile document uses its tile size instead
    bool tiled = false;             // the picture repeated 3 x 3 around itself, to see the seams
    bool gridDrawn = false, tiledDrawn = false;   // what the last frame drew (autotest)
    bool checker = true;            // the checkerboard under transparent pixels
    float canvasX = 0, canvasY = 0, canvasW = 0, canvasH = 0;   // the canvas, in screen coordinates (last frame)
    float mouseImageX = -1, mouseImageY = -1;                   // the pixel under the mouse (-1 = outside)

    // ---- a drag on the canvas
    enum class Drag { None, Stroke, Rect, Ellipse, Lasso, Move, Pan, TransformMove, TransformScale, TransformRotate } drag = Drag::None;
    float pressX = 0, pressY = 0;       // image coordinates where the button went down
    float pressScreenX = 0, pressScreenY = 0;
    SelectOp dragOp = SelectOp::Replace;
    std::vector<std::pair<double, double>> points;   // lasso / polygon points, image coordinates
    bool polygonOpen = false;           // the polygon tool has points and waits for more
    int appliedDx = 0, appliedDy = 0;   // Move: the offset already given to the model
    double tfStartScaleX = 1, tfStartScaleY = 1, tfStartRotate = 0, tfStartDist = 1, tfStartAngle = 0;
    int tfStartDx = 0, tfStartDy = 0;
    int tfDirX = 0, tfDirY = 0;         // the scale handle being dragged: -1, 0 or 1 along each axis

    // ---- palette bar and frame timeline
    std::string paletteHex = "#808080", paletteName;   // the "+" popup
    bool playing = false;           // the timeline plays the frames (a preview: it changes the frame shown, never the document)
    double playClock = 0;           // milliseconds spent on the frame shown
    ImageTexture terrain;           // the terrain preview of a tileset document
    bool terrainShown = false;      // the last frame drew it (autotest)

    // ---- provider pictures (Inpaint selection... / Generate layer...)
    std::unique_ptr<ImageProviderJob> job;      // the one in flight
    bool providerAsk = false;                   // the prompt popup is to open
    bool providerInpaint = true;                // what the popup asks for
    std::string providerPrompt;
    std::string providerError;                  // why the last request could not start or finish (shown in the popup)
    std::string providerEstimate;               // what the popup's "Make it" would cost, as text (the estimate of the price list)
    std::string providerEstimateError;          // why there is no estimate (the request would fail the same way); shown in the popup
    std::unique_ptr<ImageProviderEstimate> estimate;   // the one being worked out
    std::string noGenerate, noInpaint;          // why each action is off ("" = a provider is ready)
    int layersBefore = 0;                       // autotest bookkeeping
    std::size_t providerUndo = 0;               // autotest bookkeeping
    std::uint64_t providerChecked = ~std::uint64_t(0);

    // ---- textures
    ImageTexture picture, selectionTint;
    struct Dead {
        std::uint32_t image, view;
        std::uint64_t frame;
    };
    std::vector<Dead> graveyard;
    std::vector<std::uint8_t> tintBytes;

    // ---- panels
    std::string renaming;               // the layer whose name is being typed
    std::string renameBuf;
    bool renameFocus = false;
    int selectedOp = -1;                // the adjustment / effect open in the inspector (index in its list)
    bool selectedOpEffect = false;
    bool opDragging = false;            // a field of the open operation is being dragged (a live preview)
    std::string addKind = "pixels";     // the kind the Add button of the layer list makes
    std::string newDocName = "art/new";
    int newDocSize = 64;
    int resizeWidth = 0, resizeHeight = 0;   // the Resize canvas popup (0 = take the document's size when it opens)
    int resizeAnchor = 4;                    // index into the nine anchors, 4 = center
    bool focused = false;               // the panel's window had the keyboard last frame (Ctrl+S saves the image)
    std::uint64_t lastPoll = 0;         // uiFrame_ of the last look at the files on disk
    double antsPhase = 0;
};

}  // namespace fa::editor
