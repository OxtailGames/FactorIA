// The state of the Vector panel (vector_panel.cpp, vector_canvas.cpp): the tool, how the canvas is looked at, what is being dragged. The
// rules that need no window (the SVG, the selection, the pen, the snapping, the undo steps) are in vector_model.h.
#pragma once

#include <cstdint>
#include <memory>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "vector_model.h"

namespace fa::editor {

// The texture of the rasterized drawing: the part of the drawing space `region` at the zoom it was made for.
struct VectorTexture {
    std::uint32_t image = 0, view = 0;
    int w = 0, h = 0;
    std::uint64_t revision = ~std::uint64_t(0);
    VecRect region;
    float zoom = 0;
};

struct VectorUi {
    std::unique_ptr<VectorModel> model;
    std::string openError;          // why the file the user asked for could not be opened

    // ---- tools
    VectorTool tool = VectorTool::Select;
    std::string shapeKind = "star"; // the Shape tool's kind (vector.shape kinds that can be dragged out)
    bool showGrid = false;          // draw the snap grid
    bool showBounds = true;         // draw the outline of the shape under the pointer
    bool checker = true;            // the checkerboard under the drawing

    // ---- the view
    float zoom = 1;
    float panX = 0, panY = 0;       // where the drawing's top-left corner is, from the canvas's top-left (screen pixels)
    bool fitNext = true;
    float canvasX = 0, canvasY = 0, canvasW = 0, canvasH = 0;   // the canvas, in screen coordinates (last frame)
    VecPoint mouse{0, 0};           // the pointer in the drawing space (last frame)
    bool mouseInside = false;
    bool viewMoving = false;        // the view changed this frame: the picture is stretched, not made again
    int idleFrames = 0;
    VectorTexture picture;
    struct Dead {
        std::uint32_t image, view;
        std::uint64_t frame;
    };
    std::vector<Dead> graveyard;

    // ---- a drag on the canvas
    enum class Drag { None, Pan, Marquee, Move, Scale, Rotate, Create, Pen, NodeMove, HandleMove, NodeMarquee } drag = Drag::None;
    VecPoint press{0, 0};           // where the button went down (drawing space, snapped for the tools that snap)
    float pressScreenX = 0, pressScreenY = 0;   // the same place on screen
    VecPoint current{0, 0};         // the pointer now (snapped)
    bool dragged = false;           // the pointer moved far enough to count as a drag
    bool shiftAtPress = false;
    std::vector<std::string> dragRefs;   // the shapes a move / scale / rotate acts on
    VecRect dragBox;                // their bounds when the drag started
    VecPoint dragAnchor{0, 0};      // scale: the point that stays; rotate: the centre
    int dirX = 0, dirY = 0;         // the scale handle being dragged: -1, 0 or 1 along each axis
    double startAngle = 0;
    VecPoint applied{0, 0};         // the last move delta given to the preview
    VectorNodeRef nodeRef;          // the node (or the node a handle belongs to) being dragged
    bool handleOut = false;
    VecPoint nodeStart{0, 0};       // where that node or handle was
    bool snapShown = false;
    VecPoint snapAt{0, 0};
    VectorSnapKind snapKind = VectorSnapKind::None;
    std::string hover;              // the shape under the pointer
    std::vector<VecPoint> createPoints;

    // ---- panels
    std::set<std::string> collapsed;   // groups closed in the layer list
    std::string renaming;              // the element whose id is being typed
    std::string renameBuf;
    bool renameFocus = false;
    bool sliderDragging = false;       // a field of the inspector is being dragged (a live preview)
    std::string newDocName = "art/new";
    int newDocSize = 100;
    // the buttons that ask for numbers
    double offsetDistance = 4;
    int offsetJoin = 0;
    bool offsetCopy = false;
    double simplifyTolerance = 0.5;
    double smoothness = 1;
    int mirrorAxis = 0;
    bool mirrorWeld = true;
    double shadeDepth = 0;             // 0 = the command's default
    int shadeLight = 0;
    double newGuide = 0;
    bool focused = false;              // the panel's window had the keyboard last frame
    std::uint64_t lastPoll = 0;
    // the fill / stroke colour being edited in the inspector (kept while the colour popup is open)
    float fillCol[4] = {0, 0, 0, 1};
    float strokeCol[4] = {0, 0, 0, 1};
    std::string shownFor;              // the element the colour fields belong to
};

}  // namespace fa::editor
