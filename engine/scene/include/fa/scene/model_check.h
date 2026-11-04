// Checking a model's mesh (docs/MODELING.md, "Looking at a model: model.preview and model.check"): the faults an artist finds by eye, found by
// measuring. Works on any MeshData (a model document's result, an organic `sdf` node, an imported mesh), GPU-free and deterministic.
//
// What it looks for, each as a finding that says WHERE (parts, bounds, sample positions), WHAT and HOW TO FIX:
//   scale                  the size against the 1.8 m reference figure (or the height the caller states): tiny, huge, probably authored in cm / mm
//   origin                 the model is far from its own origin (the game places an entity by it)
//   inside_out             a closed piece whose winding gives it a negative volume: every triangle faces inward
//   flipped_normals        triangles whose stored normals point against their winding (lit from the wrong side)
//   inconsistent_winding   two neighbouring triangles that disagree on which side is out (one of them is flipped)
//   non_manifold           edges shared by more than two triangles
//   open_edges             edges used by a single triangle: a hole in the surface
//   degenerate             triangles with no area
//   triangle_budget        more triangles than a platform's budget for one model (model_platform_budgets)
//   draw_call_budget       more submeshes (draw calls) than a platform's budget
#pragma once

#include <cstddef>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/mesh_store.h"

namespace fa {

inline constexpr double kModelReferenceHeight = 1.8;  // the reference figure beside a model in model.preview, metres

struct ModelCheckOptions {
    std::vector<std::string> platforms;  // the budgets to check (desktop, mobile, web); empty = all of them
    std::vector<std::size_t> lodTriangles;  // triangles of LOD1.. (made by the caller from the document's gameReady): a platform an LOD fits is told so
    double expectedHeight = 0;           // metres; the model's height (Y) should be about this (0 = no expectation)
    double tolerance = 0.25;             // fraction of expectedHeight the height may differ by
    std::size_t maxSamples = 6;          // sample positions listed per finding
    std::vector<std::string> ignore;     // finding codes not to report (an open surface that is meant to be open)
};

struct ModelFinding {
    std::string code;      // see the list above
    std::string severity;  // "error" (fix before shipping), "warning" (probably wrong), "info" (worth knowing)
    std::string message;   // what is wrong and where
    std::string hint;      // how to fix it
    std::size_t count = 0; // triangles or edges involved (0 for whole-model findings)
    std::vector<std::string> parts;  // the parts they belong to ("" = no part, named "(no part)" in messages), in submesh order
    Vec3 bmin{}, bmax{};   // bounds of what the finding is about (only when `count` > 0)
    std::vector<Vec3> samples;  // up to maxSamples positions on it, in model space
    std::string platform;  // budget findings: the platform
};

struct ModelCheckScale {
    Vec3 size{};                 // bounding box extents, metres
    Vec3 bmin{}, bmax{};
    double height = 0;           // size.y
    double versusFigure = 0;     // height / 1.8
    double volume = 0;           // m3, the sum of the closed pieces (0 when none)
};

struct ModelCheckReport {
    std::vector<ModelFinding> findings;  // errors first, then warnings, then info; each group in the order of the list above
    ModelCheckScale scale;
    std::size_t triangles = 0, vertices = 0, submeshes = 0;
    std::size_t openEdges = 0, nonManifoldEdges = 0, inconsistentEdges = 0, degenerateTriangles = 0, flippedNormalTriangles = 0, pieces = 0, insideOutPieces = 0;
    std::size_t errors = 0, warnings = 0, infos = 0;
    bool ok() const { return errors == 0; }
};

// Measures `mesh` and lists what is wrong with it. Never fails: an empty mesh gives an error finding.
ModelCheckReport check_model_mesh(const MeshData& mesh, const ModelCheckOptions& options = {});

// The codes in the order a report lists them, with one line each (what model.check's catalog returns).
struct ModelCheckKind {
    std::string code, severity, doc;
};
const std::vector<ModelCheckKind>& model_check_kinds();

}  // namespace fa
