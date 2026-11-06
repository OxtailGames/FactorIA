#include "ai_asset_approval.h"

#include <algorithm>
#include <chrono>
#include <format>

namespace fa::editor {

namespace {
std::string text_of(const Json& j, const char* key) {
    const auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}
}  // namespace

ai::AssetDecision AssetApprovals::ask(const ai::AssetApprovalRequest& req) {
    std::unique_lock<std::mutex> lock(mu_);
    if (closed_ || (req.cancel && req.cancel->load())) return ai::AssetDecision::Cancel;
    Slot slot;
    slot.card.id = nextId_++;
    slot.card.chatId = req.runKey;
    slot.card.plan = req.plan;
    slot.cancel = req.cancel;
    const u64 id = slot.card.id;
    slots_.push_back(std::move(slot));
    ++generation_;
    auto find = [&] {
        for (auto it = slots_.begin(); it != slots_.end(); ++it)
            if (it->card.id == id) return it;
        return slots_.end();
    };
    // A short poll on the cancel flag (it is not tied to this condition variable). It only costs a wake-up ten times a second.
    ai::AssetDecision result = ai::AssetDecision::Cancel;
    for (;;) {
        auto it = find();
        if (it == slots_.end()) break;  // (cannot happen: only this thread erases its slot)
        if (it->answer) {
            result = *it->answer;
            break;
        }
        if (closed_ || (it->cancel && it->cancel->load())) break;
        cv_.wait_for(lock, std::chrono::milliseconds(100));
    }
    if (auto it = find(); it != slots_.end()) slots_.erase(it);
    ++generation_;
    return result;
}

std::vector<AssetCard> AssetApprovals::cards() const {
    std::lock_guard<std::mutex> lock(mu_);
    std::vector<AssetCard> out;
    for (const Slot& s : slots_)
        if (!s.answer) out.push_back(s.card);
    return out;
}

bool AssetApprovals::answer(u64 id, ai::AssetDecision decision) {
    {
        std::lock_guard<std::mutex> lock(mu_);
        for (Slot& s : slots_) {
            if (s.card.id == id && !s.answer) {
                s.answer = decision;
                ++generation_;
                cv_.notify_all();
                return true;
            }
        }
    }
    return false;
}

bool AssetApprovals::waiting_for(const std::string& chatId) const {
    std::lock_guard<std::mutex> lock(mu_);
    for (const Slot& s : slots_)
        if (!s.answer && s.card.chatId == chatId) return true;
    return false;
}

u64 AssetApprovals::generation() const {
    std::lock_guard<std::mutex> lock(mu_);
    return generation_;
}

void AssetApprovals::close() {
    {
        std::lock_guard<std::mutex> lock(mu_);
        closed_ = true;
    }
    cv_.notify_all();
}

void AssetApprovals::reopen() {
    std::lock_guard<std::mutex> lock(mu_);
    closed_ = false;
}

AssetCardText asset_card_text(const Json& plan) {
    AssetCardText t;
    const std::string provider = text_of(plan, "provider");
    const std::string kind = text_of(plan, "kind");
    double countValue = 1;
    if (const auto it = plan.find("count"); it != plan.end() && it->is_number()) countValue = it->get<double>();
    const int count = std::max(1, static_cast<int>(std::clamp(countValue, 1.0, 1000.0)));
    const auto usd = plan.find("estimatedCostUsd");
    const bool known = usd != plan.end() && usd->is_number();
    t.what = text_of(plan, "what");
    if (t.what.empty()) t.what = text_of(plan, "command");
    const std::string money = known ? ai::format_usd(usd->get<double>()) : std::string("an unknown price");
    t.title = std::format("Approve {}? {}{} with {}", known ? "about " + money : money, count > 1 ? std::to_string(count) + " x " : std::string(),
                          kind.empty() ? std::string("asset") : kind, provider.empty() ? std::string("a provider") : provider);
    t.estimate = known ? "about " + money : "price unknown";
    if (const std::string basis = text_of(plan, "basis"); !basis.empty()) t.estimate += " (" + basis + ")";
    if (const auto u = plan.find("priceUnverified"); u != plan.end() && u->is_boolean() && u->get<bool>()) t.estimate += ", the engine could not verify this price";
    if (const std::string checked = text_of(plan, "priceChecked"); !checked.empty()) {
        t.estimate += ", prices checked " + checked;
        if (const std::string source = text_of(plan, "priceSource"); !source.empty()) t.estimate += " at " + source;
    }
    t.prompt = text_of(plan, "prompt");
    return t;
}

}  // namespace fa::editor
