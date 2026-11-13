// The state of the Model panel (modeler_panel.cpp): which node and part are picked, how the viewport looks at the model, the texture it
// draws and the findings of the last check. The rules that need no window (the document, the edits, the evaluation, the undo steps) are in
// modeler_model.h.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "modeler_model.h"

namespace fa::editor {

struct ModelerUi {
    std::unique_ptr<ModelerModel> model;
    std::string openError;  // why the file the user asked for could not be opened
    bool focused = false;
    std::uint64_t lastPoll = 0;

    // ---- what is picked
    std::string selected;       // the pointer of the node picked in the tree ("" = none)
    std::string highlight;      // the part drawn in the accent colour in the viewport ("" = none)
    std::string newOp = "box";  // the operation the Add button makes

    // ---- the viewport
    float yaw = 30.0f, pitch = 20.0f;  // degrees
    float zoom = 1.0f;
    bool shaded = true, wireframe = true, orthographic = false, ground = true, figure = false;
    bool dragging = false;                               // the mouse is orbiting the model
    float viewX0 = 0, viewY0 = 0, viewW = 0, viewH = 0;  // the picture in screen coordinates (last frame)
    struct Texture {
        std::uint32_t image = 0, view = 0;
        int w = 0, h = 0;
        std::uint64_t key = ~0ULL;
    } picture;
    struct Dead {
        std::uint32_t image, view;
        std::uint64_t frame;
    };
    std::vector<Dead> graveyard;
    std::uint64_t renderCount = 0;  // pictures made so far (the autotest waits for it to change)
    double renderMs = 0;

    // ---- parameters
    std::string textKey, text;  // the text field being typed in (its key) and what it holds
    bool overwriteBaked = false;

    // ---- the last model.check
    Json check;
    std::string checkError;
    std::uint64_t checkRev = ~0ULL;  // doc_revision() the findings were made for
};

}  // namespace fa::editor
