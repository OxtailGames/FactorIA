// The state of the Graph panel (graph_panel.cpp): the view of the canvas, what is being dragged, the preview's texture. The rules that need no
// window (the graph, its edits, the undo steps) are in graph_model.h and the live preview in graph_preview.h.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "graph_model.h"
#include "graph_preview.h"

namespace fa::editor {

struct GraphUi {
    std::unique_ptr<GraphModel> model;
    std::unique_ptr<GraphPreview> preview;
    std::string openError;   // why the file the user asked for could not be opened
    std::string projectDir;  // the project the model and the preview belong to

    // ---- the view of the canvas
    float zoom = 1.0f;
    float panX = 40.0f, panY = 40.0f;  // screen offset of the graph's origin from the canvas's top-left corner
    bool viewApplied = false;          // the view the file remembers was applied (once per document)
    bool wantFit = false;              // fit the whole graph into the canvas next frame
    float canvasX = 0, canvasY = 0, canvasW = 0, canvasH = 0;  // screen rectangle of the canvas (last frame)
    std::string filter;                                        // the palette's search box
    Vec2 menuAt{0, 0};                                         // graph position where the palette popup was asked for
    bool openPalette = false;
    bool focusFilter = false;

    // ---- what the mouse is doing
    enum class Drag { None, Nodes, Pan, Box, Link } drag = Drag::None;
    Vec2 dragStart{0, 0};     // mouse position when the drag began (screen)
    Vec2 dragApplied{0, 0};   // graph units already applied to the nodes of a Nodes drag
    GraphPortId linkFrom;     // a Link drag: the port it started on
    GraphPortId linkPicked;   // ...and the output it carries when it picked up an existing link from an input
    std::string linkMessage;  // why the last link was refused
    int selectedLink = -1;
    bool rightPanCandidate = false;

    // ---- the pending questions
    bool askForce = false;       // the snippet was edited by hand: ask before overwriting
    bool askDiscard = false;     // opening another material with unsaved changes
    std::string pendingOpen;     // ...the one the user asked for
    bool pendingStart = false;   // ...and whether it starts a graph
    bool pendingCreate = false;  // ...which is a new material to make, not an existing one

    // ---- the preview's picture
    struct Texture {
        std::uint32_t image = 0, view = 0;
        int w = 0, h = 0;
        std::uint64_t serial = ~0ULL;
    } picture;
    struct Dead {
        std::uint32_t image, view;
        std::uint64_t frame;
    };
    std::vector<Dead> graveyard;

    bool focused = false;
    std::uint64_t lastPoll = 0;
    std::string clipboard;  // the last copy (the system clipboard too, when it holds one)
};

}  // namespace fa::editor
