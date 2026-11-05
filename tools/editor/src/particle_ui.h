// The state of the Particle panel (particle_panel.cpp): what plays, how the preview is looked at, the selected part and the curve key being
// dragged. The rules that need no window (the document, the edits, the undo steps) are in particle_model.h and the playback in
// particle_preview.h.
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <string>

#include "particle_model.h"
#include "particle_preview.h"

namespace fa::editor {

struct ParticleUi {
    std::unique_ptr<ParticleModel> model;
    std::unique_ptr<ParticlePreview> preview;
    std::string openError;            // why the file the user asked for could not be opened

    // ---- playing
    bool playing = true;              // the preview advances with the clock
    bool loop = true;                 // starts again after the last particle is gone
    float speed = 1.0f;               // playback speed (0.1 .. 2)
    double loopWait = 0.0;            // seconds of pause before a loop restarts
    bool scrubbing = false;           // the playhead is being dragged

    // ---- the view of the canvas
    float zoom = 1.0f;                // pixels per world unit
    bool showGrid = true;
    float canvasX = 0, canvasY = 0, canvasW = 0, canvasH = 0;   // screen rectangle of the canvas (last frame)
    float tlX = 0, tlY = 0, tlW = 0, tlH = 0;                   // screen rectangle of the timeline's track area (last frame)
    double tlLength = 1.0;                                      // seconds the timeline covered (last frame)

    // ---- selection
    int selectedPart = -1;
    bool showAllFields = false;
    std::string fieldFilter;

    // ---- the curve and gradient editors: which key of which field is selected / dragged
    std::string editorKey;            // the field whose key is selected ("emitter:/parts/0/emitter/sizeCurve")
    int selectedKey = -1;
    int dragKey = -1;                 // the key being dragged (-1 none)
    std::string dragField;
    float dragLo = 0, dragHi = 1;     // the value range of the curve being dragged (fixed while the key moves)

    bool focused = false;
    std::uint64_t lastPoll = 0;
};

}  // namespace fa::editor
