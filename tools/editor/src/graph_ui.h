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
    bool askConflict = false;    // the file changed on disk since it was read: Overwrite, Reload or Cancel
    bool conflictForce = false;  // ...and the Save that asked had force set (a hand-edited snippet was confirmed)
    bool forceOverwritesExternal =
        false;  // the hand-edited snippet question follows an Overwrite already answered: do not ask about the file again
    std::string pendingOpen;           // ...the one the user asked for
    bool pendingStart = false;         // ...and whether it starts a graph
    bool pendingCreate = false;        // ...which is a new material to make, not an existing one
    std::string pendingKind = "mesh";  // ...and the kind of that new material
    std::string newKind =
        "mesh";  // the kind the New graph material button makes ("mesh" or "sprite", the combo next to it)

    // ---- the preview's picture
    struct Texture {
        std::uint32_t image = 0, view = 0;
        int w = 0, h = 0;
        std::uint64_t serial = ~0ULL;
    } picture;
    Texture savedPicture;  // the last saved version of the graph (Compare)
    // The saved document the preview was last given (the material's path and the model's saved_revision()): a new one is pushed when either changes.
    std::string savedPushedPath;
    std::uint64_t savedPushedRevision = 0;
    struct Dead {
        std::uint32_t image, view;
        std::uint64_t frame;
    };
    std::vector<Dead> graveyard;

    // ---- the params and textures of the material (the Params and Textures sections of the side panel)
    struct EntryForm {
        bool open = false;
        bool texture = false;  // a texture (name, sampler, doc) or a param (name, type, default, range, doc)
        bool focus = false;    // the name box takes the keyboard the first frame
        char name[64] = {};
        int type =
            0;  // a param: 0 float, 1 vec2, 2 vec3, 3 vec4, 4 color; a texture: 0 linear, 1 linearRepeat, 2 nearest, 3 nearestRepeat
        float value[4] = {0, 0, 0, 0};
        bool ranged = false;
        float lo = 0, hi = 1;
        char doc[200] = {};
        std::string error;  // why the last Create was refused
    } entryForm;
    std::string renaming;  // the param or texture whose name is being typed ("" = none)
    bool renamingTexture = false;
    char renameBuf[64] = {};
    bool renameFocus = false;
    std::string
        entryMessage;  // why the last rename or delete was refused (a delete of a name nodes still read lists them)
    bool entryMessageIsNote =
        false;  // ...or what a rename or delete that went through still has to say (shown as a warning, not an error)

    bool focused = false;
    std::uint64_t lastPoll = 0;
    std::string clipboard;  // the last copy (the system clipboard too, when it holds one)
};

}  // namespace fa::editor
