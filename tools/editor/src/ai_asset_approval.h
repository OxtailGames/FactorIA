// The editor's answer to "this call is going to cost money: make it?" (docs/AI_COSTS.md, "Asset generation").
//
// A paid asset call from an AI run (assets.generate_*, image.inpaint, image.generate_layer) that is above limits.askAboveUsd calls
// the editor's approver (fa/ai/asset_cost.h, AiCommandOptions::assetApprover) on the thread of the call: an agent thread or an MCP
// connection thread, never the UI thread. AssetApprovals::ask() puts a card in the list and waits there. The AI panel draws the cards
// of the chat in front (what, how many, which provider, the estimate; Approve, Approve all for this run, Cancel) and answer()s
// them from the UI thread; nothing on the UI thread waits for anything.
//
// A card ends one of three ways: the user answers, the run is stopped (its cancel flag: the wait gives up with Stopped), or the
// editor closes the project (close(): every waiting call gets Stopped).
#pragma once

#include <condition_variable>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "fa/ai/asset_cost.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::editor {

struct AssetCard {
    u64 id = 0;
    std::string chatId;  // the chat whose run asked (AssetApprovalRequest::runKey)
    Json plan;  // {command, what, kind, provider, model, count, estimatedCostUsd, basis, prompt, priceChecked...}
};

class AssetApprovals {
public:
    // The agent thread's side: shows the card, waits for the answer. Stopped when `req.cancel` is set, or after close().
    ai::AssetDecision ask(const ai::AssetApprovalRequest& req);

    // The UI thread's side. cards(): the cards still waiting, oldest first (a snapshot). answer(): false when the card is gone
    // (the run was stopped meanwhile).
    std::vector<AssetCard> cards() const;
    bool answer(u64 id, ai::AssetDecision decision);
    // True when a card of this chat is waiting.
    bool waiting_for(const std::string& chatId) const;
    // Counts up with every card that appears or goes away (the UI redraws a chat's strip only when it changes).
    u64 generation() const;

    // Every waiting call gets Stopped and new ones are answered Stopped at once, until reopen().
    void close();
    void reopen();

private:
    struct Slot {
        AssetCard card;
        const CancelFlag* cancel = nullptr;
        std::optional<ai::AssetDecision> answer;
    };
    mutable std::mutex mu_;
    std::condition_variable cv_;
    std::vector<Slot> slots_;
    u64 nextId_ = 1;
    u64 generation_ = 0;
    bool closed_ = false;
};

// "What will be made" lines for the card, from a plan (the "plan" of a needsApproval answer): the same text the card shows and the
// autotest reads. Pure; no ImGui.
struct AssetCardText {
    std::string title;     // "Approve $1.20? 4 images with openai"
    std::string what;      // "a 64x64 image at assets/items/potion.png"
    std::string estimate;  // "about $1.20 (4 x 1024x1024 auto at $0.30), prices checked 2026-11-06 at https://..."
    std::string prompt;    // what was asked for, shortened
};
AssetCardText asset_card_text(const Json& plan);

}  // namespace fa::editor
