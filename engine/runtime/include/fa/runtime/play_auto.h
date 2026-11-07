// play.auto: the game plays itself, headless, and the run is written as a play session (fa/runtime/play_session.h) with
// "source": "auto", so `play.report` reads it like a session a person played in the editor.
//
// The bot is the game's own: scripts/autoplay.js calls game.autoplay(fn) and fn answers, once per step, which input actions to
// hold (docs/SCRIPTING.md, "The bot"). A game without that file is smoke-played by a generic explorer that holds the declared
// actions in seeded patterns. Nothing here uses the clock or the world's RNG: the same project, scene, seed and speed always give
// the same input, the same phases, the same ending and the same session numbers (only the milliseconds of the frame times vary).
//
// Stuck and broken detection (docs/DEBUGGING.md, "Let the game play itself"): the run ends and a mark with a screenshot and the
// step is written when nothing moves for `stuckSeconds`, when a menu has nobody to press it, when a script raises errors every
// second, when something pulled by gravity falls out of the world or gets a position that is not a number, or when scripts/autoplay.js
// cannot be loaded. input.json is the bot's input in the
// replay format, so `factoria run --headless --input` plays the problem again.
#pragma once

#include <cstdint>
#include <string>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/runtime/engine.h"

namespace fa {

inline constexpr double kPlayAutoMaxSeconds = 3600.0;  // game seconds one run may ask for
inline constexpr int kPlayAutoMaxSpeed = 8;            // fixed steps one frame may run
inline constexpr int kPlayAutoMaxPhases = 60;          // phases a session lists (more are counted in the notes)
// Automatic sessions kept under .factoria/sessions: a run deletes the oldest ones beyond this once its own session is written.
inline constexpr int kPlayAutoKeepSessions = 30;
inline constexpr int kPlayAutoMaxPictures = 40;        // screenshots one run takes (phases + problems), the end one apart

struct PlayAutoOptions {
    double seconds = 60.0;        // game seconds to play at most (the run ends "timeout" then)
    std::uint64_t seed = 1;       // the world's RNG seed, the explorer's and the hook's (bot.rng); keep it below 2^53
    int speed = 1;                // fixed steps per frame, 1..kPlayAutoMaxSpeed: the bot answers once per frame
    double stuckSeconds = 10.0;   // game seconds without a change before the run is called stuck
    bool useHook = true;          // false: ignore scripts/autoplay.js and play with the generic explorer
    bool screenshots = true;      // false: no pictures (the session says so in its notes)
    std::string sessionName;      // folder name under .factoria/sessions ("" = the clock, then "-auto")
    bool hookRequired = false;    // true (bot "hook"): a project whose scripts/autoplay.js registers no bot ends "broken" instead of using the explorer
    double wallSecondsCap = 800;  // real seconds: a safety net far above normal use (and below the 900 s of the child process that may host the run); the run ends "aborted" when it passes
};

// Plays the project of `config` (its projectDir, scene, language...; the determinism settings are forced: headless, no audio
// device, fake platform, in-memory storage, `options.seed`) and writes the session under .factoria/sessions of that project.
// The error is for a run that could not start (the project does not load) or a session that could not be written; a game that
// misbehaves is a normal result. Result: {session, dir, ended, endedWhy, score, ...} (the summary the play.auto command returns).
Result<Json> play_auto(const EngineConfig& config, const PlayAutoOptions& options);

}  // namespace fa
