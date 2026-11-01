// The engine's own token savers of the built-in agent loop (the API providers; Claude Code and Codex run their own loops).
// ai.json "savers" switches each one (config.h Savers); docs/AI_PROVIDERS.md, "Token savers".
//
//  * LOOP GUARD: the same command failing with the same error code three times in a run gets one short redirect, added to the
//    third error the model reads. No model call is made for it; an optional judge (a role the user picks) writes the redirect
//    instead and its tokens go into the run's cost and limits.
//  * LEARNED TOOL GROUPS: per project, the commands a run loads from the tool catalog (tool_describe, or tool_call of a command
//    that is not offered in full) are counted with their group (command category). A group several runs needed is PROPOSED for
//    loading up front; it is applied only when the user accepts. Nothing is ever denied: a command that is not in a group stays
//    reachable through the catalog.
//  * PROJECT FACTS: a command that failed with the same error code in several runs until a later call of it worked proposes one
//    line for the project's AGENTS.md. It is written only when the user accepts.
//
// What is learned is kept in <project>/.factoria/ai/savers.json (the folder is gitignored: it belongs to this computer).
#pragma once

#include <map>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/config.h"
#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::ai {

inline constexpr int kLoopGuardFailures = 3;  // failures of one (command, error code) in a run before the redirect
inline constexpr int kGroupProposalRuns = 3;  // runs that loaded a group's commands before it is proposed
inline constexpr int kFactProposalRuns = 3;   // runs that hit a failure and then fixed it before a line is proposed
inline constexpr const char* kSaversFile = ".factoria/ai/savers.json";
inline constexpr const char* kFactsHeading = "## Project facts";

// --- loop guard ------------------------------------------------------------------------------------------------------------

struct LoopRedirect {
    std::string command;  // "scene.load" (a tool_call wrapper is resolved to the command it carried)
    std::string code;     // the error's code
    std::string message;
    std::string hint;
    int count = 0;        // how many times it failed
    std::string text;     // what the model is told (loop_redirect_text)
};

class LoopGuard {
public:
    // The result of one command call. Returns the redirect when this is the kLoopGuardFailures-th failure of (command, code) since
    // the command last worked; once per (command, code) in a run. A success of the command starts its counts again.
    std::optional<LoopRedirect> record(const std::string& command, bool ok, const std::string& code, const std::string& message,
                                       const std::string& hint);

private:
    struct Entry {
        int failures = 0;
        bool redirected = false;
    };
    std::map<std::string, Entry> entries_;  // by command + "\n" + code
};

// The fixed redirect: what failed, the error's hint, try a different way. One short paragraph.
std::string loop_redirect_text(const LoopRedirect& r);
// What the judge model is asked: the stuck command, its error and the last arguments it was called with.
std::string loop_judge_prompt(const LoopRedirect& r, const std::string& lastArguments);
// The text a judge answered, made fit to hand to the model: trimmed, one paragraph, at most ~600 characters, with the prefix.
// "" when the answer is empty.
std::string loop_judge_redirect(const LoopRedirect& r, const std::string& answer);

// --- what the runs of a project learn --------------------------------------------------------------------------------------

// One run's observations, written to the project's savers.json when the run ends (commit). Thread-safe against other runs: the
// file is read, changed and written under one lock.
class RunLearner {
public:
    RunLearner(std::string projectDir, std::string role, bool groups, bool facts);

    // The run loaded the definition of `command` (category `category`) from the catalog.
    void tool_loaded(const std::string& command, const std::string& category);
    // The result of a call of `command` with `args`.
    void command_result(const std::string& command, bool ok, const std::string& code, const std::string& message,
                        const std::string& hint, const Json& args);
    // Adds the run to the project's counts. Does nothing when nothing was observed or the project folder is empty.
    void commit();

private:
    struct Pending {
        std::string command, code, message, hint;
        std::string failedArgs;
    };
    struct Resolved {
        Pending failure;
        std::string fixArgs;  // the arguments of the call that worked, when they differ from the failed call's
    };
    std::string projectDir_, role_;
    bool groups_, facts_;
    std::map<std::string, std::set<std::string>> loaded_;  // category -> commands
    std::map<std::string, Pending> pending_;               // by command + "\n" + code: failed, not fixed yet
    std::map<std::string, Resolved> resolved_;             // failed and then worked
};

struct GroupProposal {
    std::string role;
    std::string group;                   // a command category
    int runs = 0;                        // runs that loaded one of its commands
    std::vector<std::string> commands;   // the commands the runs loaded, most loaded first
    u64 definitionBytes = 0;             // what loading the whole group up front adds to every step of that role
};
struct FactProposal {
    std::string id;       // "scene.load:not_found"
    std::string command;
    std::string code;
    int runs = 0;
    std::string line;     // the line for AGENTS.md ("- ..."), one line
};

// The groups the user accepted for `role` in this project, to load up front besides the role's own (toolGroups). Empty when the
// project has none.
std::vector<std::string> accepted_tool_groups(std::string_view projectDir, std::string_view role);
// Proposals that wait for an answer: groups of runs of the project that the role does not load up front yet, and facts.
std::vector<GroupProposal> group_proposals(const AiConfig& cfg, const CommandRegistry& registry, std::string_view projectDir);
std::vector<FactProposal> fact_proposals(std::string_view projectDir);

// The state `ai.savers` shows: the switches, the counts, the accepted groups, the proposals.
Json savers_report(const AiConfig& cfg, const CommandRegistry& registry, std::string_view projectDir);

enum class SaverAnswer { Accept, Decline, Forget };
std::optional<SaverAnswer> parse_saver_answer(std::string_view text);  // "accept", "decline", "forget"

// Accept: the group is loaded up front for that role in this project from the next run on. Decline: it is not proposed again.
// Forget: back to undecided (the counts stay). Unknown role or group: a teaching error.
Result<Json> answer_tool_group(const CommandRegistry& registry, std::string_view projectDir, std::string_view role,
                               std::string_view group, SaverAnswer answer);
// Accept: appends the line (`line` replaces the proposed one when not empty) under "## Project facts" in the project's AGENTS.md
// (created when missing). Decline: not proposed again. Forget: undecided. Nothing is written to AGENTS.md before Accept.
Result<Json> answer_fact(std::string_view projectDir, std::string_view id, SaverAnswer answer, std::string_view line = {});

}  // namespace fa::ai
