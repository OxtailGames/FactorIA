// State of the Post-processing panel (View > Post-processing, postfx_panel.cpp). Plain data: the panel redraws from it and from the
// engine's answers every frame, nothing here is saved with the project.
#pragma once

#include <set>
#include <string>

#include "fa/core/json.h"

namespace fa::editor {

struct PostFxUi {
    std::string camera;  // the Camera entity whose stack is shown; "" = the main camera
    std::string target;  // where an edit goes: "" = the camera's own PostProcess, else the id of a volume entity
    bool compare = false;      // A/B: the renderer draws every camera without a stack (Renderer::set_post_bypass); no data changes
    bool keepOthers = false;   // a preset keeps the effects it does not name (postprocess.apply_preset keep)
    Json report;               // postprocess.get {resolved: true} of the last frame: {id, resolved: {layers, effects, count, ...}}
    Json support;              // render.supports: {backend, backendLabel, features: [...]}; null until asked
    double supportAt = -1e9;   // editor time of that answer: the table is asked again every few seconds
    std::string error;         // what the last command said when it failed (shown under the buttons)
    std::string note;          // what the last preset said about effects the renderer does not draw yet
    std::set<std::string> open;  // the effects whose fields are shown
    bool bypassSet = false;    // the panel switched the renderer's bypass on: it is switched off when the panel closes
};

}  // namespace fa::editor
