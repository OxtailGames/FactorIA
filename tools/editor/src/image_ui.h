// The state of the Image panel (image_panel.cpp, image_canvas.cpp): what the user picked, how the canvas is looked at, what is being
// dragged. The rules that need no window (the document, the strokes, the selections, the undo steps) are in image_model.h.
#pragma once

#include <cstdint>
#include <memory>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "image_model.h"

namespace fa::editor {

// A texture the panel owns. The panel makes a new one when the picture changes; the old one is destroyed a few frames later, when the
// draw list that named it has been drawn.
struct ImageTexture {
    std::uint32_t image = 0, view = 0;
    int w = 0, h = 0;
    std::uint64_t revision = ~std::uint64_t(0);
};

struct ImageUi {
    std::unique_ptr<ImageModel> model;
    std::string openError;          // why the document the user asked for could not be opened

    // ---- tools
    ImageTool tool = ImageTool::Brush;
    ImageBrushSettings brush;
    ImageWandSettings wand;
    SelectOp selectOp = SelectOp::Replace;
    float selectionPx = 2;          // grow / shrink / feather amount
    bool tint = false;              // the selection as a tint instead of marching ants
    bool nearestTransform = false;  // set when a transform starts from the layer kind

    // ---- the view
    float zoom = 1;
    float panX = 0, panY = 0;       // where the picture's top-left corner is, from the canvas's top-left (screen pixels)
    bool fitNext = true;            // fit the picture to the canvas on the next frame
    bool showGrid = true;           // the pixel grid, when zoomed in far enough
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
    bool focused = false;               // the panel's window had the keyboard last frame (Ctrl+S saves the image)
    std::uint64_t lastPoll = 0;         // uiFrame_ of the last look at the files on disk
    double antsPhase = 0;
};

}  // namespace fa::editor
