// The editor's side of "make this paid asset?": AssetApprovals (a call waits on its own thread, the UI thread answers) and the text of
// the card. No window: the autotest section A3 covers the drawn card.

#include <atomic>
#include <chrono>
#include <thread>

#include "ai_asset_approval.h"
#include "doctest.h"

using namespace fa;
using namespace fa::editor;

namespace {

Json paid_plan() {
    return Json::object({{"command", "assets.generate_image"},
                         {"what", "4 images of a ruby"},
                         {"kind", "image"},
                         {"provider", "openai"},
                         {"model", "gpt-image-1"},
                         {"count", 4},
                         {"estimatedCostUsd", 1.2},
                         {"basis", "4 x 1024x1024 auto at $0.30"},
                         {"priceChecked", "2026-11-06"},
                         {"priceSource", "https://example.com/prices"},
                         {"prompt", "a ruby"}});
}

// Waits (up to 5 s of wall time: a safety net, the test never depends on it) until `n` cards wait.
bool wait_for_cards(const AssetApprovals& a, std::size_t n) {
    for (int i = 0; i < 500; ++i) {
        if (a.cards().size() == n) return true;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    return false;
}

}  // namespace

TEST_CASE("AssetApprovals: a call waits for the answer given from another thread") {
    AssetApprovals approvals;
    std::atomic<int> got{-1};
    std::thread agent([&] { got = static_cast<int>(approvals.ask({"chat-1", paid_plan(), nullptr})); });
    REQUIRE(wait_for_cards(approvals, 1));
    CHECK(got.load() == -1);
    CHECK(approvals.waiting_for("chat-1"));
    CHECK_FALSE(approvals.waiting_for("chat-2"));
    const auto cards = approvals.cards();
    CHECK(cards[0].chatId == "chat-1");
    CHECK(approvals.answer(cards[0].id, ai::AssetDecision::ApproveAll));
    agent.join();
    CHECK(got.load() == static_cast<int>(ai::AssetDecision::ApproveAll));
    CHECK(approvals.cards().empty());
    CHECK_FALSE(approvals.answer(cards[0].id, ai::AssetDecision::Approve));  // the card is gone
}

TEST_CASE("AssetApprovals: the cancel flag of the run, close() and a closed list all answer Cancel") {
    AssetApprovals approvals;
    CancelFlag cancel{false};
    std::atomic<int> got{-1};
    std::thread byFlag([&] { got = static_cast<int>(approvals.ask({"c", paid_plan(), &cancel})); });
    REQUIRE(wait_for_cards(approvals, 1));
    cancel = true;
    byFlag.join();
    CHECK(got.load() == static_cast<int>(ai::AssetDecision::Cancel));
    CHECK(approvals.cards().empty());

    std::thread byClose([&] { got = static_cast<int>(approvals.ask({"c", paid_plan(), nullptr})); });
    REQUIRE(wait_for_cards(approvals, 1));
    approvals.close();
    byClose.join();
    CHECK(got.load() == static_cast<int>(ai::AssetDecision::Cancel));

    // closed: a new call is answered at once and no card appears
    CHECK(approvals.ask({"c", paid_plan(), nullptr}) == ai::AssetDecision::Cancel);
    CHECK(approvals.cards().empty());
    approvals.reopen();
    std::thread again([&] { got = static_cast<int>(approvals.ask({"c", paid_plan(), nullptr})); });
    REQUIRE(wait_for_cards(approvals, 1));
    CHECK(approvals.answer(approvals.cards()[0].id, ai::AssetDecision::Approve));
    again.join();
    CHECK(got.load() == static_cast<int>(ai::AssetDecision::Approve));
}

TEST_CASE("AssetApprovals: two chats ask at once and each card goes to its own chat") {
    AssetApprovals approvals;
    std::atomic<int> a{-1}, b{-1};
    std::thread t1([&] { a = static_cast<int>(approvals.ask({"one", paid_plan(), nullptr})); });
    std::thread t2([&] { b = static_cast<int>(approvals.ask({"two", paid_plan(), nullptr})); });
    REQUIRE(wait_for_cards(approvals, 2));
    const std::uint64_t before = approvals.generation();
    for (const AssetCard& c : approvals.cards())
        CHECK(approvals.answer(c.id, c.chatId == "one" ? ai::AssetDecision::Approve : ai::AssetDecision::Cancel));
    t1.join();
    t2.join();
    CHECK(a.load() == static_cast<int>(ai::AssetDecision::Approve));
    CHECK(b.load() == static_cast<int>(ai::AssetDecision::Cancel));
    CHECK(approvals.generation() > before);
}

TEST_CASE("asset_card_text: the estimate, the count, the provider and when the prices were checked") {
    const AssetCardText t = asset_card_text(paid_plan());
    CHECK(t.title == "Approve about $1.20? 4 x image with openai");
    CHECK(t.what == "4 images of a ruby");
    CHECK(t.estimate.find("about $1.20") == 0);
    CHECK(t.estimate.find("4 x 1024x1024 auto at $0.30") != std::string::npos);
    CHECK(t.estimate.find("prices checked 2026-11-06 at https://example.com/prices") != std::string::npos);
    CHECK(t.prompt == "a ruby");

    Json unknown = Json::object({{"command", "assets.generate_voice"}, {"kind", "voice"}, {"provider", "openai"}, {"estimatedCostUsd", nullptr}, {"priceUnverified", true}});
    const AssetCardText u = asset_card_text(unknown);
    CHECK(u.estimate.find("price unknown") == 0);
    CHECK(u.what == "assets.generate_voice");
    CHECK(u.title.find("an unknown price") != std::string::npos);

    // a count out of range does not break the title
    Json odd = paid_plan();
    odd["count"] = 1e12;
    CHECK(asset_card_text(odd).title.find("1000 x") != std::string::npos);
    odd["count"] = -3;
    CHECK(asset_card_text(odd).title.find(" x ") == std::string::npos);
}
