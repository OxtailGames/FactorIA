// The state of the terrain tool (terrain_tool.cpp; View > Terrain tool): the mode and brush the user picked, the cursor under the mouse
// and the stroke being drawn. The brush itself (settings, stamps, ring, ray) is in brush.h and is shared with the other brush tools;
// this file only adds what is the terrain's: which command a stamp goes to and with which arguments. Lives inside the Editor.
#pragma once

#include <array>
#include <string>
#include <vector>

#include "brush.h"
#include "fa/core/json.h"
#include "fa/core/math.h"

namespace fa::editor {

enum class TerrainMode { Off, Sculpt, Paint, Holes };
enum class SculptTool { Raise, Lower, Smooth, Flatten };

struct TerrainUi {
    // ---- what the user picked (the panel)
    TerrainMode mode = TerrainMode::Off;
    SculptTool sculpt = SculptTool::Raise;
    BrushSettings brush;
    float amount = 0.25f;     // raise / lower: metres a stamp changes the middle of the brush (terrain.sculpt `amount`)
    bool flattenAuto = true;  // flatten to the ground under the first click of the stroke
    float flattenHeight = 0.0f;  // ... or to this world y
    bool pickingHeight = false;  // the next click in the viewport picks flattenHeight from the ground
    int layer = 0;               // paint: an index into Terrain.layers
    bool cut = true;             // holes: cut (true) or fill
    // ---- the ground under the mouse this frame
    bool hasHit = false;
    Vec3 hit{};
    int ringSegments = 0;  // points of the ring drawn in the last frame (the autotest reads it)
    // ---- the stroke being drawn
    BrushStroke stroke;
    std::string strokeEntity;   // id of the Terrain the stroke edits
    BrushSettings strokeBrush;  // the settings at the press: a change of the panel mid-stroke does not change it
    SculptTool strokeSculpt = SculptTool::Raise;
    TerrainMode strokeMode = TerrainMode::Off;
    bool strokeInvert = false;  // Ctrl held at the press: lower instead of raise, fill instead of cut
    bool strokeCut = true;
    int strokeLayer = 0;
    float strokeAmount = 0.25f;
    float strokeHeight = 0.0f;  // flatten: the world y the whole stroke flattens to
    bool started = false;       // a piece changed the terrain: the next ones continue its undo step
    bool failed =
        false;  // a command refused a piece: the stroke is over, nothing more is sent (and the error shown once)
    bool dirtyBefore = false;  // the editor's dirty flag at the press, which Esc puts back with the terrain's data
    std::array<bool, 4>
        unsavedBefore{};  // heights, holes, splat 0, splat 1 "unsaved" flags of the terrain at the press
    int pieces = 0;       // commands sent by the stroke so far
    int strokes = 0;      // strokes finished (the autotest reads it)
    std::string error;    // the last problem, shown in the panel
};

// One command call that applies some stamps of a stroke: `continueStroke` is set from the second piece of a stroke on. Pure.
struct TerrainCall {
    std::string command;  // terrain.sculpt, terrain.paint or terrain.holes
    Json args;
};
TerrainCall terrain_stroke_call(const TerrainUi& ui, const std::string& entityId, const std::vector<Vec2>& points,
                                bool continueStroke);

// The largest brush radius in metres the tool lets the user dial in for a terrain of `size` metres whose edited plane is `planeSide`
// texels (or samples) a side: the commands refuse a brush wider than 1024 texels OF THE PLANE THEY EDIT, so a terrain with splat maps
// finer than its heights gets a smaller maximum while it paints. planeSide <= 0: only the size limits it.
float terrain_max_radius(Vec2 size, int planeSide);
// The side, in texels, of the plane `mode` edits: the heights and the holes mask have `cells` (a sculpt or a holes stroke), the splat
// maps `splatSide` (paint; 0 = none yet, terrain.paint makes them min(cells, 1024) wide).
int terrain_plane_side(TerrainMode mode, int cells, int splatSide);

}  // namespace fa::editor
