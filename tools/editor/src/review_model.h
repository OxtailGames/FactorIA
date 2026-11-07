// The Review window's model (View > Review, docs/EDITOR.md "Review window"): the sheets review.sheet made, read from their
// manifests (fa/tooling/review.h) into what the window draws, the keyboard moves of the selection, the size a picture is uploaded
// at, what a pick will do before it is asked (the command, its arguments and the files it moves), the history of past picks and the
// review.sheet arguments of the Level generator's "Sheet of N seeds". No ImGui, no Editor: tests/review_tests.cpp drives it. The window
// never reimplements a pick: it calls review.pick (or assets.pick for a sheet of asset candidates) through the command registry.
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "level_gen_model.h"

namespace fa::editor {

// One thumbnail of a sheet.
struct ReviewItemView {
    int n = 0;                       // the number printed on the sheet (1-based)
    std::string type, label, source, info, thumb, error;
    bool ok = true, candidate = false;
    int x = 0, y = 0, w = 0, h = 0;  // its picture's rectangle in sheet.png pixels (item.picture, else item.cell)
};

// A sheet as the window shows it (review_sheet_view reads it from manifest.json).
struct ReviewSheetView {
    std::string id, label, createdAt, dropDir;
    std::string picture;             // sheet.png, project-relative (manifest picture.path; the sheet folder's sheet.png when missing)
    int width = 0, height = 0, columns = 1, rows = 1;
    std::vector<ReviewItemView> items;
    Json meta = Json::object();
    Json picked;                     // null, or the manifest's `picked` object
    std::vector<std::string> warnings;
    std::string kind;                // meta.kind ("assetCandidates", "levelSeeds", or "")
    std::string slot;                // meta.slot of a sheet of asset candidates
    bool is_picked() const { return picked.is_object(); }
    int picked_n() const;            // 0 when not picked
    const ReviewItemView* item(int n) const;  // nullptr when out of range
};

// Reads a manifest (review_load's value) without trusting it: a missing or wrong-typed key gives its default, never an exception.
ReviewSheetView review_sheet_view(const Json& manifest);

// One row of the list on the left of the window (a review_list row).
struct ReviewListRow {
    std::string id, label, createdAt, kind, pickedLabel;
    std::string slot;                // meta.slot (a sheet of asset candidates)
    int count = 0;
    int picked = 0;                  // the number picked, 0 = still waiting for an answer
};
// review_list's value as rows: the sheets still waiting for an answer first, then the answered ones; newest first in each group.
std::vector<ReviewListRow> review_rows(const Json& listValue);

// Only the newest sheet of asset candidates of a slot can be picked (assets.pick answers an older one with code "superseded"). The id of
// the newest such sheet in `rows` when `sheet` is an older, unanswered one; "" otherwise (not candidates, answered, or the newest).
std::string review_superseded_by(const std::vector<ReviewListRow>& rows, const ReviewSheetView& sheet);

// The arrow keys move the selection over the grid of `count` items in `columns` columns; 0 (nothing selected) starts at 1.
enum class ReviewMove { Left, Right, Up, Down };
int review_move_selection(int current, int count, int columns, ReviewMove move);
// The item a digit key 1..9 selects, or 0 when the sheet has fewer items.
int review_digit_selection(int digit, int count);

// The scale that fits a w x h picture into availW x availH (at most `maxScale`; 1 for an empty picture).
float review_fit_scale(int w, int h, float availW, float availH, float maxScale = 2.0f);
// The size a picture is uploaded at: the same, or shrunk (aspect kept, at least 1 px) so neither side is above maxSide.
void review_upload_size(int w, int h, int maxSide, int& outW, int& outH);
inline constexpr int kReviewSheetMaxSide = 4096;   // sheet.png (up to 8192 a side) is uploaded at most this big: 64 MB of texture
inline constexpr int kReviewCompareMaxSide = 2048; // a picture of the Compare view
inline constexpr int kReviewThumbMaxSide = 512;    // a thumbnail
// The width and height in the header of a PNG file (the first 24 bytes are enough), or nullopt when it is not a PNG.
std::optional<std::pair<int, int>> review_png_size(const std::uint8_t* data, std::size_t size);

// What a pick of item `n` will do: the command the window calls (review.pick, or assets.pick for a sheet whose meta.kind is
// "assetCandidates"), its arguments, and the files it moves to the drop folder (the same rule as review_pick: the other items marked
// `candidate` that have a source file, each file once, never the picked item's own file). `error` says why the pick cannot be asked
// (already answered, a number not on the sheet, an item that failed to render, a sheet of candidates without its slot).
struct ReviewMoveLine {
    int n = 0;
    std::string label, from, to;
};
struct ReviewPickPlan {
    std::string command;
    Json args = Json::object();
    std::vector<ReviewMoveLine> moves;
    std::string error;
    bool canKeepFiles = true;        // the command takes `drop` (review.pick): "Keep the other files" is offered
};
ReviewPickPlan review_pick_plan(const ReviewSheetView& sheet, int n, bool drop, const std::string& note);

// One past pick for the History tab (a picked sheet's manifest).
struct ReviewDroppedLine {
    int n = 0;
    std::string label, from, to, status;   // status: moved | expired | gone
};
struct ReviewHistoryRow {
    std::string id, label, at, who, note, pickedLabel, kind;
    int n = 0, count = 0;
    std::int64_t atUnix = 0;
    std::vector<ReviewDroppedLine> dropped;
};
// nullopt when the manifest has no pick.
std::optional<ReviewHistoryRow> review_history_row(const Json& manifest);
// Newest pick first.
void review_sort_history(std::vector<ReviewHistoryRow>& rows);

// The Level generator's "Sheet of N seeds": review.sheet arguments with ONE level item of the window's options (tilemap.generate
// arguments without `seed`) and `seeds` = the window's seed and the next count-1 (wrapping after kLevelGenMaxSeed), `sampleScene`
// when the sample is an entity (the scene it is in, as saved), and meta {"kind":"levelSeeds", "sampleFile"|"sampleEntity", "size"}
// so a pick can bring the window back to these options. Fails like level_gen_arguments, and for a level above 1024 cells a side
// (the most review.sheet draws) or a count outside 2..kReviewSeedsMax.
inline constexpr int kReviewSeedsMin = 2;
inline constexpr int kReviewSeedsMax = 16;
inline constexpr int kReviewSeedsDefault = 6;
inline constexpr int kReviewLevelMaxSide = 1024;
Result<Json> review_level_seeds_args(const LevelGenOptions& o, int count, const std::string& sampleScene);
// The seed a pick of a level item chose: spec.level.seed of the pick result (or of manifest.picked.spec); nullopt when it is not a level.
std::optional<std::int64_t> review_picked_level_seed(const Json& pickedOrResult);
// The Level generator options that make the picked level of a "levelSeeds" sheet: the sample of its meta, and the size, model, window,
// symmetry, wrapping and seed of the pick's spec.level (its other keys go to `extra`, so the window generates exactly the picked
// thumbnail's level). False (and `o` untouched) when the pick is not a level of such a sheet.
bool review_level_options_from_pick(const Json& picked, const Json& meta, LevelGenOptions& o);

}  // namespace fa::editor
