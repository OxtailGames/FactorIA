// What a game costs an AI with no context (docs/AI_COSTS.md, "Measuring it"; scripts/agent-cost.sh): the report over the transcript of one
// run of an AI CLI (Claude Code's `--output-format stream-json`) that was asked for "a platformer with three levels".
//
//   agent_cost_report   the numbers: steps, tokens and minutes to the first playable build (the first `play.auto` that reaches the last level),
//                       the engine errors the AI met, and the ones nothing caught (a script error in an output while every test passed)
//   agent.cost          the command over files (the transcript, and the final game's own `play.auto` answer); the script writes its
//                       answer to feedback/agent-cost/<version>-<cli>.json
//
// The step numbers and tokens are those of efficiency.h (read_claude_stream_session); nothing here reads the clock or asks a model.
#pragma once

#include <string>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa {

struct AgentCostInput {
    std::string transcript;      // the stream-json lines
    Json finalPlay;              // the answer of `play.auto` on the final game (null = not run)
    std::string cli, model, brief, factoriaVersion;
    std::string cliVersion;      // `claude --version` of the CLI that ran ("" = not recorded)
    int homeIsolated = -1;       // 1 = the CLI ran with a throw-away HOME, 0 = with the real one (its CLAUDE.md and memory may have loaded), -1 = unknown
    int exitStatus = 0;          // of the CLI
    int elapsedSeconds = 0;
    int levels = 3;              // how many levels the brief asks for
};

// A play.auto answer (the JSON object, or a text that contains it) read as: how many distinct `phases` it recorded (the scenes it loaded,
// named by path, and the game.phase marks: play.auto records nothing about a level loaded inside one scene), how it ended, and the script errors it counted. {phases, ended, scriptErrors, parsed}.
Json agent_cost_read_play_auto(const std::string& text);

// {format, cli, model, brief, factoriaVersion, exitStatus, elapsedSeconds, total, firstPlayable, finalGame, engineErrors, notCaught, notes}.
Json agent_cost_report(const AgentCostInput& in);

void register_agent_cost_commands(CommandRegistry& registry);

}  // namespace fa
