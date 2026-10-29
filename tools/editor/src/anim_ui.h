// The state of the Animation panel (anim_panel.cpp) and of the bone tools (bone_tools.cpp): what the user picked, what is being
// dragged, what is posed in the world. The rules that need no window are in anim_model.h. Both live inside the Editor.
#pragma once

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "anim_model.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::editor {

// A ghost quad the onion skin draws: a sprite (or one cell of a skin) of the animated entity in another pose, in world space.
struct OnionQuad {
    Vec2 corner[4];       // world positions, in the order of the texture corners top-left, top-right, bottom-right, bottom-left
    Vec2 uv[4];           // texture coordinates (0..1) of those corners
    std::string texture;  // "" = outline only
};
struct OnionPose {
    double t = 0;
    int side = 0;  // -1 before the playhead, +1 after
    std::vector<OnionQuad> quads;
};

struct AnimUi {
    // ---- what the panel edits
    std::string ownerId;   // the entity whose Animator the panel edits (the selection or a part of it)
    std::string clipName;  // a key of Animator.clips
    double playhead = 0;   // seconds into the clip
    // ---- preview playback (the panel advances the playhead; nothing runs in the engine)
    bool playing = false;
    bool loopPreview = true;
    float speed = 1.0f;
    // ---- record mode
    bool recording = false;
    // ---- onion skin
    bool onion = false;
    int onionBefore = 2, onionAfter = 2;
    int onionFrames = 3;  // frames between two ghost poses
    // ---- time grid
    int fps = 30;
    bool snap = true;
    // ---- view
    bool curves = false;       // the curve view instead of the dopesheet
    float pps = 240.0f;        // pixels per second
    double viewStart = 0;      // seconds at the left edge of the time area
    bool fitNext = true;       // fit the clip to the width on the next frame
    std::set<std::string> collapsed;  // parts (track paths) whose rows are folded
    std::set<int> curveTracks;        // tracks whose curves the curve view draws
    // ---- selection
    KeySet selection;
    int selectedEvent = -1;
    KeyClipboard clipboard;
    // ---- a drag in the time area
    enum class Drag { None, Scrub, Keys, Scale, Box, Event, Tangent, Value, Pan } drag = Drag::None;
    double dragPressT = 0, dragOffset = 0, dragScale = 1;
    float dragStartX = 0, dragStartY = 0;
    bool dragMoved = false, dragAdd = false;
    int dragTrack = -1, dragChannel = 0;
    double dragKeyT = 0;
    bool dragOutgoing = true;
    float dragSlope = 0, dragValue = 0;
    int dragEvent = -1;
    double dragEventTo = 0;
    KeySet dragBase;       // the selection when a drag began
    // ---- popups
    std::string newClipName = "idle";
    float newClipDuration = 1.0f;
    bool newClipLoop = true;
    std::string eventName = "event";
    double eventAt = 0;
    int eventEditing = -1;  // -1 = adding, else the index being renamed
    // ---- the pose the panel leaves the world in (edit mode only)
    bool posed = false;
    std::uint64_t posedGeneration = 0;  // World::scene_generation() when it posed: a reload makes the pose moot
    std::string posedOwner;
    std::string savedClip;              // Animator.clip / time / playing before the first pose: put back after every pose
    float savedTime = 0;
    bool savedPlaying = true;
    bool dirtyPose = true;              // the clip or the playhead changed: pose again
    struct BoneRest {                   // a Bone2D's Transform before the first pose (an IK solve moves bones no clip drives)
        std::string id;
        Json position, rotation, scale;
    };
    std::vector<BoneRest> boneRest;
    // ---- onion cache
    std::vector<OnionPose> ghosts;
    std::string ghostKey;
    // ---- layout of the last frame (the autotest clicks by these)
    float timeX0 = 0, timeX1 = 0;       // screen x of the time area's left and right edge
    float rulerY = 0, rowsY0 = 0;
    // ---- counters the autotest reads
    int recordedKeys = 0;               // keys record mode wrote
    int onionDrawn = 0;                 // ghost quads the viewport drew in the last frame
    // ---- the last problem
    std::string error;
};

// What the bone tools window asks of the viewport.
enum class BoneTool { Off, Chain, Weights, Ik };

struct BoneUi {
    BoneTool tool = BoneTool::Off;
    // ---- chain
    std::vector<Vec2> chain;   // clicked points, in the parent's local space
    std::string chainPrefix = "bone";
    std::string chainParent;   // the entity the chain hangs from (set at the first click: the selection)
    // ---- bind
    int meshColumns = 4, meshRows = 8;
    std::string bindRoot;      // a bone: it and the bones below it
    // ---- weights
    std::string skinId;        // the sprite whose weights are shown
    int boneIndex = 0;         // the bone painted (index in SpriteSkin.bones)
    float radius = 24.0f;      // brush radius, in the sprite's local units
    float strength = 0.5f;
    int mode = 0;              // 0 add, 1 set, 2 smooth
    bool painting = false;
    std::string paintKey;
    int strokes = 0;           // paint commands in this stroke
    Vec2 lastDab{};            // where the brush last painted in this stroke (sprite-local), so a still mouse does not pile up
    bool hasDab = false;
    // ---- ik
    int ikDragging = -1;
    std::string ikTarget;      // id of the target being dragged
    std::string ikKey;
    // ---- counters the autotest reads
    int bonesDrawn = 0;        // bone outlines the viewport drew in the last frame
    int weightDots = 0;        // weight dots the viewport drew in the last frame
    int ikHandles = 0;         // IK handles the viewport drew in the last frame
    std::string error;
};

}  // namespace fa::editor
