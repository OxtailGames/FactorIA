// Review sheets: the storage behind review.sheet / review.pick / review.list / review.info (docs/AI_GUIDE.md, "Show choices").
//
// A review sheet is ONE picture with numbered thumbnails of N candidates (images, scenes, prefabs, level seeds, vector art,
// effects) that a person looks at and answers with one number. Each sheet lives in its own folder under `.factoria/review/`:
//
//   .factoria/review/sheet-0001/manifest.json    what is on the sheet (format "factoria.review/1", described below)
//   .factoria/review/sheet-0001/sheet.png        the picture
//   .factoria/review/sheet-0001/thumbs/01.png    each thumbnail on its own (what a window shows without cutting the sheet)
//   .factoria/review/dropped/sheet-0001/         where review.pick MOVES the candidates it drops (a pick never deletes; review_cleanup deletes them after kReviewDroppedDays)
//
// manifest.json: { format, id, label, createdAt ("2026-11-06T12:00:00.000Z", from the engine's clock), createdUnix (seconds),
//   engineVersion, columns, rows, thumbSize, picture: {path, width, height}, dropDir, items: [{n (1-based, the number printed
//   on the sheet), type (image|scene|prefab|level|vector|vfx), label, source (the project file, "" for a level), candidate
//   (true: review.pick moves `source` away when another item is picked), ok, error?, info (the line under the thumbnail),
//   numbers {...} (the same facts as numbers), thumb (path inside the sheet folder), cell {x,y,w,h}, picture {x,y,w,h} (pixels
//   of sheet.png), spec (the item as it was asked, a level with its seed filled in)}], picked: null | {n, at, atUnix, who, note,
//   drop, dropped: [{n, label, from, to, status}], spec}, warnings, meta (the free object review.sheet was given, {} when none:
//   a caller's own key such as the slot the choice is for, stored and returned untouched) }. A dropped entry's status is "moved",
//   or "expired" once review_cleanup deleted the file after kReviewDroppedDays.
//
// The files are written by this module only: the sheet folder is complete when manifest.json exists (it is written last), and
// every change of an existing manifest (review.pick) happens under the repo's cross-process lock (ShareLock in
// fa/tooling/feedback_share.h, the lock file in `.factoria/review/`), so the editor, the CLI and an agent may use it at once.
// Reading is lock-free. A crash (or power loss) between review_pick's file moves and its manifest write leaves the moved files in the
// drop folder with `picked` still null: the sheet can be picked again (the files that are gone are reported, not an error), and
// moving the files back by hand undoes the rest. Nothing here waits on the network; the lock wait is bounded by share_env().lockWaitSec, so a caller on
// the editor's UI thread runs these on a worker (or passes a ScopedShareEnv with a short wait).
#pragma once

#include <cstdint>
#include <functional>
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
inline constexpr int kReviewDroppedDays = 7;    // review_cleanup deletes the files a pick dropped this many days after the pick
inline constexpr int kReviewOrphanMinutes = 60; // and the folders of a sheet whose manifest was never written, this long after their last change
inline constexpr int kReviewCleanupMax = 200;   // sheets one review_cleanup changes (the oldest first; the next call goes on)
inline constexpr int kReviewMetaMaxBytes = 4096; // the most a sheet's `meta` object may take written as JSON

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
// picture, meta, dir}], unreadable?, orphans?}. `limit` is clamped to 1..kReviewListMax. Sheets whose manifest cannot be read are listed
// in `unreadable`; folders with no manifest (a sheet in the making, or one whose process died) in `orphans`.
ReviewOutcome review_list(const std::string& projectDir, int limit);

// A change of the caller's own that a pick makes part of its all-or-nothing change (assets.pick: the chosen candidate becomes the
// slot it was made for). Every function runs under the review lock, on the thread of review_pick; each may be empty.
struct ReviewPickStep {
    // Before any file moves, after the sheet was read and the number checked: ok false refuses the pick (that outcome is returned)
    // and nothing changes. `manifest` is the sheet as read under the lock, `chosen` its item number n.
    std::function<ReviewOutcome(const Json& manifest, const Json& chosen)> check;
    // After the other candidates were moved, before the manifest is written. `dropFolder` is the project-relative folder this sheet's
    // dropped files go to ("<dropDir>/<sheet id>", "" when the manifest names no usable drop folder). ok false: the moves are put back,
    // that outcome is returned and nothing changes (apply must leave nothing of its own behind). On success `value` may hold
    // "dropped": [{n, label, from, to}], files apply itself MOVED to <dropFolder>/<review_drop_file_name(n, from)> (n 0 for a file that is
    // not an item of the sheet): they are recorded with the pick's own, so review_cleanup deletes them on the same day. The rest of
    // `value` comes back as `step` in the result.
    std::function<ReviewOutcome(const Json& manifest, const Json& chosen, const std::string& dropFolder)> apply;
    // The manifest could not be written after apply succeeded: put back what apply did. Returns what could not be put back ("" = all).
    std::function<std::string()> undo;
};

struct ReviewPickOptions {
    bool drop = true;   // move the files of the other candidates to the sheet's dropDir (false: only record the choice)
    std::string note;   // free text kept with the choice (why)
    std::string who;    // "user", "agent" or "mcp"; empty: taken from command_caller()
    ReviewPickStep step;  // the caller's own change, done with the pick or not at all
};
// Records that item `n` of the sheet was chosen, and (drop) moves the source files of the OTHER items marked `candidate` to
// `<dropDir>/<sheet id>/<NN>_<file name>` (the name cut to 255 bytes). The pick deletes nothing (review_cleanup deletes the dropped files after droppedDays); the result and the manifest
// list every move (from, to), so a move is undone by moving the file back. All or nothing: a move that fails puts back the ones already made and changes no manifest.
// options.step (when set) is part of the same all or nothing: its check runs before the first move, its apply after the last one
// (a failure puts the moves back) and its undo when the manifest cannot be written.
// Refused: a sheet that was already picked, an item that failed to render, a number out of range. value: the choice (see
// review.pick in docs/AI_GUIDE.md).
ReviewOutcome review_pick(const std::string& projectDir, const std::string& sheet, long n, const ReviewPickOptions& options);

// review.sheet itself, for a command that makes a sheet as part of its own work (assets.generate_image with `count`): `args` are the
// arguments of review.sheet (validated the same way), value is its result ($image and nextSteps included). An argument error or any
// other failure comes back as the outcome (code, message, hint), never as an exception. A sheet that needs a GPU item and a graphics
// device runs like the command does.
ReviewOutcome review_sheet(const std::string& projectDir, const Json& args);

// Why review.pick may never move `rel` (a project-relative path) as a candidate of an item of type `type` (image, vector, scene,
// prefab, vfx), or "" when it may: outside the project (absolute, "..", a link that leads out), not the kind of file the type
// needs (.scene.json, .prefab.json, .vfx.json, .svg, a picture), factoria.json, assets.json, anything under .factoria/ or a
// version-control folder, or the project's main scene. The paths are compared after normalizing (./, backslashes, case, a trailing dot
// or space on Windows) and again by the file they really are (a link to a folder inside the project cannot dodge a rule). review.sheet asks it up front and review_pick asks it again for every file it is about to move, so a
// hand-edited manifest cannot make a pick move a file it could not have been asked for.
std::string review_candidate_problem(const std::string& projectDir, const std::string& type, const std::string& rel);
// Why `dropDir` (project-relative) cannot hold dropped candidates, or "": it must be a folder below .factoria/, not .factoria/tmp
// (the scratch folder commands delete from), not .factoria/review itself and not inside another sheet's folder.
std::string review_drop_dir_problem(const std::string& dropDir);
// The name review.pick gives a dropped file: "NN_<file name of source>" (NN the item number, two digits), at most 255 bytes, the limit of
// a file name on every file system the engine runs on. A longer name loses the end of its stem, cut at a UTF-8 character boundary; the
// extension (when it is at most 16 bytes) stays. review_cleanup recomputes it to know which file a pick wrote.
std::string review_drop_file_name(int number, const std::string& source);
// The comparison key of a project path: normalized, lower case, no trailing dots or spaces. Two paths with the same key are the same file
// on Windows and macOS.
std::string review_path_key(const std::string& rel);

struct ReviewCleanupOptions {
    int droppedDays = kReviewDroppedDays;   // 0: keep the dropped files for ever
    int orphanMinutes = kReviewOrphanMinutes;  // 0: leave the orphaned sheet folders
    bool dryRun = false;                    // report what would be removed and remove nothing
};
// Housekeeping under the review lock, never touching a chosen file or an unanswered sheet:
//  - the files a pick MOVED to the drop folder are deleted `droppedDays` days after the pick (the engine clock against
//    picked.atUnix); the manifest entry becomes status "expired" (or "gone" when the file was already moved back or removed) and the
//    sheet's empty drop folder goes. Only the file `<dropDir>/<id>/<NN>_<name>` a pick recorded is ever deleted.
//  - a sheet folder with no manifest (the process died between review_reserve and review_commit) is removed once nothing in it has
//    changed for `orphanMinutes` minutes (file times), so a sheet that is being made right now is never taken.
// At most kReviewCleanupMax sheets are CHANGED per call (`more`: there are others, call again). value: {droppedExpired: [{sheet, files: [...]}],
// orphansRemoved: [ids], skipped: [{sheet, reason}], examined, more, dryRun, droppedDays, orphanMinutes}. A busy lock is code "busy" and
// nothing changes. Orphans are listed by review_list under `orphans`.
ReviewOutcome review_cleanup(const std::string& projectDir, const ReviewCleanupOptions& options);

}  // namespace fa
