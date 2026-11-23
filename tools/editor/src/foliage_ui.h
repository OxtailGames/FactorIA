// The state of the foliage tool (foliage_tool.cpp; View > Foliage tool): the mode and brush the user picked, the cursor under the
// mouse and the stroke being drawn. The brush itself (settings, stamps, ring, ray) is in brush.h and is shared with the terrain
// tool; this file only adds what is the foliage's: the arguments of a foliage.paint piece and how often a piece may be sent.
// Lives inside the Editor.
#pragma once

#include <cstddef>
#include <string>
#include <vector>

#include "brush.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/foliage.h"

namespace fa::editor {

enum class FoliageMode { Off, Add, Remove };

// Stamps of a foliage stroke along the mouse path: every half radius (a stamp is a whole disc of instances, not a nudge).
inline constexpr float kFoliageStampsPerRadius = 2.0f;
// Every piece of a stroke rewrites the whole instances file (52 MB at 2,000,000 instances), so the pieces of one stroke are sent at
// most one per kFoliageMinPieceSeconds and, when a call took longer than half of that, one per twice its duration: the stamps the
// mouse draws meanwhile wait and go in ONE call (up to kMaxFoliagePaintPoints). The release always sends what is left.
inline constexpr double kFoliageMinPieceSeconds = 0.2;
inline constexpr double kFoliageMaxPieceSeconds = 3.0;

struct FoliageUi {
    // ---- what the user picked (the panel)
    FoliageMode mode = FoliageMode::Off;
    BrushSettings brush{8.0f, 0.5f, 1.0f};
    float density = 0.5f;  // instances per square metre of an add stroke...
    bool ruleDensity =
        true;  // ... or the density of the entity's ScatterRule (0.1 when it has none): the `density` argument is left out
    int mesh = -1;            // an index into Foliage.meshes the brush is limited to; -1 = every mesh
    bool clearArmed = false;  // the Clear button was pressed once: the next press clears
    // ---- the ground under the mouse this frame
    bool hasHit = false;
    Vec3 hit{};
    int ringSegments = 0;  // points of the ring drawn in the last frame (the autotest reads it)
    // ---- the stroke being drawn
    BrushStroke stroke;
    std::string strokeEntity;   // id of the Foliage the stroke edits
    BrushSettings strokeBrush;  // the settings at the press: a change of the panel mid-stroke does not change it
    FoliageMode strokeMode = FoliageMode::Add;
    bool strokeInvert =
        false;  // Ctrl (Cmd on a Mac: ImGui's io.KeyCtrl) held at the press: add removes and remove adds
    float strokeDensity = 0.5f;
    bool strokeRuleDensity = true;
    double strokeCellDensity = 0.1;  // the density the stroke plants at (the slider's, or the rule's): sizes the pieces
    std::string strokeMesh;          // the mesh the stroke is limited to ("" = every one)
    bool started = false;            // a piece made a step of the Foliage's history: the next ones continue it
    bool failed =
        false;  // a command refused a piece: the stroke is over, nothing more is sent (and the error shown once)
    bool dirtyBefore = false;  // the editor's dirty flag at the press, which Esc puts back
    std::uint64_t historyId =
        0;  // the history and step number of the stroke's undo step (the result of its first piece)
    std::uint64_t historyStep = 0;
    double lastPieceAt = -1e9;   // Editor time_ of the last piece
    double lastPieceCost = 0.0;  // seconds the last piece's command took
    int pieces = 0;              // commands sent by the stroke so far
    int strokes = 0;             // strokes finished (the autotest reads it)
    long long instances = -1;    // the instance count the last result of `instancesOf` reported (-1 = not known)
    std::string instancesOf;
    std::string error;  // the last problem, shown in the panel
};

// One command call that applies some stamps of a stroke: `continueStroke` is set from the second piece of a stroke on. Pure.
struct FoliageCall {
    std::string command;  // foliage.paint
    Json args;
};
FoliageCall foliage_stroke_call(const FoliageUi& ui, const std::string& entityId, const std::vector<Vec2>& points,
                                bool continueStroke);

// foliage.paint refuses a call whose stamps visit more than this many grid cells (kMaxFoliageCandidates, fa/scene/foliage.h, the very
// number the command checks): (2 * radius * sqrt(density) + 2)^2 per stamp, times the stamps of the call.
inline constexpr double kFoliageCandidateBudget = double(kMaxFoliageCandidates);

// The grid cells one stamp of radius `radius` at `density` visits (the formula above, with 1 % of margin for the rounding of the
// arguments). Pure.
double foliage_stamp_cells(double radius, double density);
// The most stamps one add piece may carry so that the call stays inside the budget: at most kMaxFoliagePaintPoints (512), at least 1
// (a single stamp over the budget is refused by the command with its own message: see foliage_max_density). Pure.
std::size_t foliage_points_per_piece(double radius, double density);
// The highest density at which ONE stamp of that radius fits the budget (rounded down to 4 digits, the digits the call sends), and the
// largest radius for a density. Pure.
double foliage_max_density(double radius);
double foliage_max_radius(double density);

// Seconds that must pass after a piece before the next one goes: kFoliageMinPieceSeconds, or twice what the last call took when
// that is more (never above kFoliageMaxPieceSeconds). Pure.
double foliage_piece_interval(double lastCostSeconds);

}  // namespace fa::editor
