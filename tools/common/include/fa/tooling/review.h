// Review sheets: the storage behind review.sheet / review.pick / review.list / review.info (docs/AI_GUIDE.md, "Show choices").
//
// A review sheet is ONE picture with numbered thumbnails of N candidates (images, scenes, prefabs, level seeds, vector art,
// effects) that a person looks at and answers with one number. Each sheet lives in its own folder under `.factoria/review/`:
//
//   .factoria/review/sheet-0001/manifest.json    what is on the sheet (format "factoria.review/1", described below)
//   .factoria/review/sheet-0001/sheet.png        the picture
//   .factoria/review/sheet-0001/thumbs/01.png    each thumbnail on its own (what a window shows without cutting the sheet)
//   .factoria/review/dropped/sheet-0001/         where review.pick MOVES the candidates it drops (never deletes)
//
// manifest.json: { format, id, label, createdAt ("2026-11-06T12:00:00.000Z", from the engine's clock), createdUnix (seconds),
//   engineVersion, columns, rows, thumbSize, picture: {path, width, height}, dropDir, items: [{n (1-based, the number printed
//   on the sheet), type (image|scene|prefab|level|vector|vfx), label, source (the project file, "" for a level), candidate
//   (true: review.pick moves `source` away when another item is picked), ok, error?, info (the line under the thumbnail),
//   numbers {...} (the same facts as numbers), thumb (path inside the sheet folder), cell {x,y,w,h}, picture {x,y,w,h} (pixels
//   of sheet.png), spec (the item as it was asked, a level with its seed filled in)}], picked: null | {n, at, atUnix, who, note,
//   drop, dropped: [{n, label, from, to, status}], spec}, warnings }.
//
// The files are written by this module only: the sheet folder is complete when manifest.json exists (it is written last), and
// every change of an existing manifest (review.pick) happens under the repo's cross-process lock (ShareLock in
// fa/tooling/feedback_share.h, the lock file in `.factoria/review/`), so the editor, the CLI and an agent may use it at once.
// Reading is lock-free. Nothing here waits on the network; the lock wait is bounded by share_env().lockWaitSec, so a caller on
// the editor's UI thread runs these on a worker (or passes a ScopedShareEnv with a short wait).
#pragma once

#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"

namespace fa {

inline constexpr const char* kReviewDir = ".factoria/review";
inline constexpr const char* kReviewDropDir = ".factoria/review/dropped";
inline constexpr const char* kReviewFormat = "factoria.review/1";
inline constexpr int kReviewMaxItems = 48;      // items on one sheet (after a level's `seeds` are expanded)
inline constexpr int kReviewListDefault = 20;   // sheets review_list returns without a limit
inline constexpr int kReviewListMax = 200;      // and the most it ever returns

// The answer of the functions below: `value` when ok, else a CommandError-style code ("not_found", "invalid_argument", "exists",
// "already_picked", "busy", "failed"), message and hint.
struct ReviewOutcome {
    bool ok = true;
    Json value;
    std::string code, message, hint;
};

struct ReviewThumb {
    int n = 0;       // 1-based item number
    Image picture;   // straight-alpha RGBA, already fitted into the thumbnail area
};

// Takes the next sheet id (sheet-0001, sheet-0002...) and creates its folder. value: {id, dir (project-relative)}. Under the lock,
// so two callers never get the same id. A sheet whose manifest was never written is removed with review_abandon.
ReviewOutcome review_reserve(const std::string& projectDir);
// Removes the folder review_reserve made when the sheet could not be finished. Never throws; it does nothing when the sheet has a
// manifest (a finished sheet is never removed by this).
void review_abandon(const std::string& projectDir, const std::string& id);
// Writes thumbs, sheet.png and then manifest.json of the reserved sheet `id`. `manifest` holds everything but format, id,
// createdAt, createdUnix and engineVersion, which are set here. value: the manifest as written.
ReviewOutcome review_commit(const std::string& projectDir, const std::string& id, Json manifest, const Image& sheet,
                            const std::vector<ReviewThumb>& thumbs);

// The manifest of a sheet: `sheet` is an id ("sheet-0003"), its number ("3") or "latest" (the newest finished sheet).
ReviewOutcome review_load(const std::string& projectDir, const std::string& sheet);
// The sheets, newest first: value {total, sheets: [{id, label, createdAt, count, picked (the number, or null), pickedLabel,
// picture, dir}]}. `limit` is clamped to 1..kReviewListMax. Sheets whose manifest cannot be read are listed in `unreadable`.
ReviewOutcome review_list(const std::string& projectDir, int limit);

struct ReviewPickOptions {
    bool drop = true;   // move the files of the other candidates to the sheet's dropDir (false: only record the choice)
    std::string note;   // free text kept with the choice (why)
    std::string who;    // "user", "agent" or "mcp"; empty: taken from command_caller()
};
// Records that item `n` of the sheet was chosen, and (drop) moves the source files of the OTHER items marked `candidate` to
// `<dropDir>/<sheet id>/<NN>_<file name>`. Nothing is ever deleted: the result and the manifest list every move (from, to), so a
// move is undone by moving the file back. All or nothing: a move that fails puts back the ones already made and changes no manifest.
// Refused: a sheet that was already picked, an item that failed to render, a number out of range. value: the choice (see
// review.pick in docs/AI_GUIDE.md).
ReviewOutcome review_pick(const std::string& projectDir, const std::string& sheet, long n, const ReviewPickOptions& options);

}  // namespace fa
