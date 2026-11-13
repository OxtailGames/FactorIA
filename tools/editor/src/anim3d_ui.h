// The state of the Animation panel's 3D mode (anim3d_panel.cpp): which 3D clip and rig are open, what the user picked, what is being dragged, and the
// pictures of the viewport and of the filmstrip. The rules that need no window are in anim3d_model.h. Lives inside the Editor.
#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "anim3d_model.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/tooling/model_view.h"

namespace fa::editor {

enum class Bone3DTool { Rotate, Ik };

struct Anim3DUi {
    bool mode3d = false;  // the panel shows 3D clips instead of the Animator's 2D ones
    std::unique_ptr<Anim3DModel> model;
    std::uint64_t lastPoll = 0;  // uiFrame_ of the last look at the file on disk
    std::string openError;
    std::string lastRig;     // the rig that posed the last clip (a clip that names none is posed with it)
    bool floatNext = false;  // the next frame lifts the panel out of its dock and gives it room
    std::vector<std::string> clipList, rigList;  // the project's 3D clips and rigs (read when a chooser opens)
    std::string generateOut, retargetOut;        // the file names the forms propose ("" = derive from the rig)
    bool generateOutEdited = false, retargetOutEdited = false;

    // ---- time
    double playhead = 0;
    bool playing = false;
    bool loopPreview = true;
    float speed = 1.0f;
    int fps = 30;
    bool snap = true;
    float pps = 220.0f;  // pixels per second in the dopesheet
    double viewStart = 0;
    bool fitNext = true;

    // ---- what is picked
    std::string bone;  // the picked bone ("" = none)
    Key3DSet selection;
    int selectedEvent = -1;
    std::uint64_t selRevision = 0;  // the model revision the selection was last checked against
    bool onlyBone = false;          // the dopesheet lists only the picked bone's tracks
    Bone3DTool tool = Bone3DTool::Rotate;

    // ---- the viewport
    float yaw = -25.0f, pitch = 12.0f, zoom = 1.0f;
    bool orthographic = false, showBones = true, showMesh = true;
    Vec3 frameCenter{};
    double frameRadius = 1;
    std::string frameRig;  // the rig the frame was made for
    ModelViewCamera cam;   // the camera of the last picture (pixels of the picture)
    bool camValid = false;
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

    // ---- a drag in the viewport
    enum class Drag { None, Orbit, Ring, Arrow, IkTarget, IkPole, LookTarget } drag = Drag::None;
    int dragAxis = 0;
    int dragButton = 0;  // the mouse button that began the drag
    Vec3 dragEnd{};      // the end effector's head when an IK drag began (the target a pole drag keeps)
    double dragAngle = 0, dragTotal = 0;  // the ring angle at the last frame and the turn so far (radians)
    double dragStartS = 0;                // the arrow's line parameter at the press
    Pose dragBase;                        // the pose when the drag began
    Vec3 dragPoint{};                     // the point a handle is dragged to (target, pole, aim)
    Vec3 dragOffset{};                    // handle position minus the point the mouse grabbed it at
    float pressX = 0, pressY = 0;         // the mouse at the press (screen)
    bool dragMoved = false;
    double dragTime = 0;  // the playhead (snapped) the result is keyed at
    bool live = false;    // the viewport shows `livePose` instead of the clip
    Pose livePose;
    std::uint64_t liveSerial = 0;  // changes with every live pose (the picture's cache key)
    Json liveSolver;               // the IK solver of the drag in progress
    Vec3 ikPole{};                 // where the pole handle sits (kept while the same bone stays picked)
    std::string ikPoleBone;
    double ikPoleTime = -1;
    Vec3 lookPoint{};  // where the look-at handle sits (kept while the same bone stays picked)
    std::string lookBone;
    double lookTime = -1;

    // ---- a drag in the dopesheet
    enum class SheetDrag { None, Scrub, Keys, Event } sheetDrag = SheetDrag::None;
    double sheetPressT = 0, sheetDt = 0;
    int sheetEvent = -1;
    bool sheetMoved = false;
    float timeX0 = 0, timeX1 = 0, rulerY = 0, rowsY0 = 0;  // layout of the last frame (the autotest clicks by these)

    // ---- forms
    std::string newClipName = "pose";
    float newClipDuration = 1.0f;
    std::string kind = "walk";
    std::string retargetTo;
    int mirrorFrom = 0;  // 0 swap, 1 left, 2 right
    bool mirrorOther = false;
    float mirrorTo = 0.5f;
    std::string generateParams;  // optional JSON object of generator parameters
    bool replaceOutput = false;  // generate / retarget may replace an existing file
    std::string eventName = "footstep";
    std::string eventText,
        eventTextKey;  // the picked event's name as edited, and the (clip, index, revision) it was read for
    std::string eventData, eventDataError;  // its data as JSON text
    std::string newEventFeel,
        newEventError;  // the new-event row: feel actions as JSON text (optional when there is a name), and why Add refused
    std::string eventFeel, eventFeelError;  // its game feel actions as JSON text (an object or an array)
    float eventTime = 0;
    std::array<float, 4> keyVals{};  // the picked key's value as edited
    Key3D keyShown;                  // the key keyVals was read from
    std::uint64_t keyShownRev = ~0ULL;

    // ---- the sheets the preview commands draw (filmstrip, weights)
    struct Sheet {
        Texture tex;
        std::string clip;            // the clip it was made for
        std::uint64_t revision = 0;  // the model revision it shows
        std::string what;            // "filmstrip" or "weights"
        std::string note;
        std::string error;
    };
    Sheet film, weights;
    bool showSheets = false;
    int sheetTab = 0;  // 0 filmstrip, 1 weights

    // ---- counters the autotest reads
    int bonesDrawn = 0;    // bone outlines the viewport drew in the last frame
    int handlesDrawn = 0;  // gizmo and IK handles drawn in the last frame
    int keysDrawn = 0;
    int commits = 0;     // edits the panel sent as commands
    std::string status;  // the last problem or note
};

}  // namespace fa::editor
