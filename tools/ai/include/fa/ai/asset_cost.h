// What paid asset generation costs, what it may cost, and who has to say yes (docs/AI_COSTS.md, "Asset generation").
//
//   estimate_asset_cost   the price of a call from the provider's assetPricing table (ai.json; the built-in providers ship one with
//                         the day it was looked up and where). An ESTIMATE: never an invoice.
//   AssetCostGuard        what every generating command does BEFORE it calls the provider: refuse a call that would pass
//                         limits.maxAssetCostUsd (this run, today), ask the user when the estimate is above limits.askAboveUsd
//                         (or when the calls since the last yes add up to more than that: many small calls are not a way round it),
//                         and count the money as spent (it is given back when the call fails).
//   AssetRunScope         names the agent run the commands of this thread belong to, so "per run" means a chat's run in the editor
//                         and the whole process for the CLI and MCP.
//
// The day total lives in <user config folder>/asset-spend.json and is changed under the same cross-process lock as the other files
// of that folder (fa/tooling/feedback_share.h, ShareLock): a second editor or a terminal counts into the same total. When the lock
// cannot be taken the call is refused if a per-day limit is set (nothing is counted), and goes ahead with a warning otherwise.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "fa/ai/assets.h"
#include "fa/ai/config.h"
#include "fa/core/json.h"

namespace fa {
struct ShareEnv;  // fa/tooling/feedback_share.h
}

namespace fa::ai {

// The price of one generating call.
struct AssetEstimate {
    bool free = false;               // nothing is charged: the fake provider, a local program or server without an assetPricing table
    std::optional<double> usd;       // the whole call, count included; empty = the provider's price for this kind is unknown
    int count = 1;                   // how many identical results the call asks for (candidates)
    bool verified = true;            // false: the figure is the engine's derivation, not a published price
    std::string basis;               // "2 x 1024x1024 auto at $0.167" or why the price is unknown
    std::string checked, source;     // the provider's price list: the day it was looked up and where it is published
    std::string note;
    // 0 for a free call or an unknown price (use `usd` to tell them apart).
    double usd_or_zero() const { return usd.value_or(0.0); }
};

// The price of `count` (>= 1) calls like `request` to `provider`. The provider's own sizes decide an image's price (the OpenAI
// provider draws 1024x1024, 1536x1024 or 1024x1536 whatever size the file ends up), the text decides a voice's, `seconds` a sound's
// and music's (10 s and 60 s are assumed when the call leaves the length to the provider).
AssetEstimate estimate_asset_cost(const ProviderConfig& provider, const AssetRequest& request, int count = 1);

// The paragraph every command that can spend money adds to its description (what the result carries, the limits, the approval).
const char* asset_cost_doc();

// "$0.167", "$0.50", "$12.40": money as text (at least two decimals, at most four).
std::string format_usd(double usd);
// The estimate as the fields of a result: {estimatedCostUsd (null when unknown), costIsEstimate: true, cost: {basis, ...}}.
Json estimate_to_json(const AssetEstimate& estimate);

// ---- who says yes (the hook; the guard below uses it) -------------------------------------------------------------------------

// What the user answered to "make this?". Stopped: nobody answered, the run was stopped (Stop, a closed project) while the question waited.
enum class AssetDecision { Approve, ApproveAll, Cancel, Stopped };
// One call waiting for the user's yes. `plan` is the "plan" of the needsApproval answer ({command, what, kind, provider, model, count,
// estimatedCostUsd, basis, prompt...}). `cancel` is the cancel flag of the run (may be null): the approver gives up with Cancel when it
// is set (the approver answers Stopped). `runKey` is asset_run_key() of the calling thread (the editor: the chat id).
struct AssetApprovalRequest {
    std::string runKey;
    Json plan;
    const CancelFlag* cancel = nullptr;
};
// A host that has a person to ask (the editor) gives its generating commands one (AiCommandOptions::assetApprover, or
// set_asset_approver for the whole process). It runs on the thread of the generating call (an agent or MCP thread,
// never the UI thread), blocks until the user answers and returns the answer. Without an approver a call that needs the user's yes
// returns the needsApproval answer instead (the CLI, MCP and scripts: the AI asks its user, then passes approved:true).
// WITH an approver the approved argument is ignored: the person answers the card, and an AI cannot answer for them.
using AssetApprover = std::function<AssetDecision(const AssetApprovalRequest&)>;

// ---- the run a thread works for -----------------------------------------------------------------------------------------------

// Within the life of the object the asset calls of this thread count into the run `key` (the editor: the chat id of the AI run
// that made the call). Without one they count into the run "" (the process): every caller without a run of its own (the CLI, an
// external MCP client, the Image panel, a script) shares one total and one "asked since the last yes" total, which only
// asset_run_begin("") starts again. `approver` (optional) is who these calls ask when they need the user's yes:
// set_asset_approver()'s one is used when it is empty. `spendEnv` (optional, must outlive the scope) is the user folder whose
// asset-spend.json this thread's calls use instead of the process's (an autotest must not write the real one; the process-wide
// ScopedShareEnv would race the other threads).
class AssetRunScope {
public:
    explicit AssetRunScope(std::string key, AssetApprover approver = {}, const ShareEnv* spendEnv = nullptr);
    ~AssetRunScope();
    AssetRunScope(const AssetRunScope&) = delete;
    AssetRunScope& operator=(const AssetRunScope&) = delete;

private:
    std::string previous_;
    AssetApprover previousApprover_;
    const ShareEnv* previousEnv_ = nullptr;
};
// A run starts: its spent total goes back to 0 and "approve all" is off.
void asset_run_begin(const std::string& key);
// "Approve all for this run": the run's calls above askAboveUsd stop asking (the limits still hold).
void asset_run_approve_all(const std::string& key, bool on = true);
bool asset_run_approves_all(const std::string& key);
// The estimated dollars the run has spent on assets so far.
double asset_run_spent(const std::string& key);
// ...of which nobody was asked about since the last yes. A call is asked about when this plus its own estimate is above askAboveUsd.
double asset_run_unapproved(const std::string& key);
// The key of the run this thread counts into.
std::string asset_run_key();

// ---- the day total ----------------------------------------------------------------------------------------------------------

// <user config folder>/asset-spend.json.
std::string asset_spend_path();
// What `projectDir` has spent today across every process (estimated dollars), read without the lock (the file is replaced
// atomically); empty when the file cannot be read.
std::optional<double> asset_spent_today(const std::string& projectDir);

// ---- who says yes -------------------------------------------------------------------------------------------------------------

// Installs `approver` (empty removes it) and returns the previous one.
AssetApprover set_asset_approver(AssetApprover approver);
// For tests: installs an approver for the life of the object.
class ScopedAssetApprover {
public:
    explicit ScopedAssetApprover(AssetApprover approver) : previous_(set_asset_approver(std::move(approver))) {}
    ~ScopedAssetApprover() { set_asset_approver(std::move(previous_)); }
    ScopedAssetApprover(const ScopedAssetApprover&) = delete;
    ScopedAssetApprover& operator=(const ScopedAssetApprover&) = delete;

private:
    AssetApprover previous_;
};

// ---- before the call --------------------------------------------------------------------------------------------------------

// What is about to be made.
struct AssetCall {
    std::string command;       // "assets.generate_image"
    std::string what;          // one line for the person: "a 64x64 image at assets/items/potion.png"
    std::string prompt;        // what was asked for (shown shortened)
    std::string projectDir;
    std::string provider, model;
    MediaKind kind = MediaKind::Image;
    AssetEstimate estimate;
    const CancelFlag* cancel = nullptr;  // the run's cancel flag: waiting for the user's yes ends when it is set
    // The person said yes through a button of the host (the Image panel's Make it), not through an argument an AI could pass: it
    // counts whatever approver there is.
    bool userApproved = false;
};

class AssetCostGuard {
public:
    AssetCostGuard() = default;
    AssetCostGuard(AssetCostGuard&& other) noexcept;
    AssetCostGuard& operator=(AssetCostGuard&& other) noexcept;
    AssetCostGuard(const AssetCostGuard&) = delete;
    AssetCostGuard& operator=(const AssetCostGuard&) = delete;
    ~AssetCostGuard();  // a guard that was not committed gives the money back

    // With an approver installed the call waits here for the user's answer (Cancel throws "asset_declined", a stopped run
    // "cancelled"). Throws CommandError "asset_cost_limit" (a limit would be passed), "asset_cost_unknown" (a limit is set and the
    // price is unknown) or "asset_cost_unavailable" (the per-day total cannot be read or changed). `approved` is the command's
    // approved argument: it counts only when there is NO approver (CLI, MCP without the editor, scripts); with one it is ignored
    // (and the result says so). AssetCall::userApproved is the host's own yes. Returns a guard whose go() is false when the user
    // still has to say yes: return needs_approval() as the command's result and do not call the provider.
    static AssetCostGuard begin(const Limits& limits, const AssetCall& call, bool approved);

    bool go() const { return go_; }
    const Json& needs_approval() const { return needsApproval_; }
    // The call succeeded: the estimate stays counted as spent.
    void commit();
    // Only `made` of the `count` results the guard was taken for were made (a batch of candidates that failed part way): that share of
    // the estimate stays counted as spent and the rest is given back now. made >= count is commit(); made <= 0 gives everything back.
    // Returns the estimated dollars that stay counted.
    double commit_part(int made, int count);
    // For the result of the command: {estimatedCostUsd, costIsEstimate, cost: {...spent...}}.
    Json cost_json() const;
    const std::vector<std::string>& warnings() const { return warnings_; }

private:
    void release();
    bool go_ = false, reserved_ = false, committed_ = false, dayReserved_ = false;
    double amount_ = 0, unapprovedAdded_ = 0;
    std::string runKey_, projectDir_, dayDate_;
    const ShareEnv* spendEnv_ = nullptr;
    Json cost_ = Json::object();
    Json needsApproval_;
    std::vector<std::string> warnings_;
};

// True when the result of a command is a "needsApproval" answer (the editor's agent proxy and the tests look at this).
bool is_needs_approval(const Json& result);

}  // namespace fa::ai
