// The Engine Feedback panel's view of sharing without a window: the share column, the share fields and their limits, the
// suggested share text and which entries get queued (feedback_share_model.h). The drawing is covered by the autotest (section E2).
#include "doctest.h"
#include "feedback_share_model.h"

using namespace fa;
using namespace fa::editor;

namespace {
Json entry_with(const Json& shared) {
    Json e = Json::object({{"id", "FB-0001"}, {"status", "open"}, {"title", "t"}});
    e["share"] = Json::object({{"title", "No one-way platforms"}, {"missing", "Colliders cannot be one-way, so a player cannot jump up through a platform."}});
    if (!shared.is_null()) e["shared"] = shared;
    return e;
}
}  // namespace

TEST_CASE("share column: one word per state, the reason as tooltip") {
    Json noShare = Json::object({{"id", "FB-0001"}});
    CHECK(share_column(noShare).label == "-");
    CHECK(share_column(noShare).kind == ShareKind::NotShared);
    CHECK(share_column(entry_with(Json())).label == "not shared");
    CHECK(share_column(entry_with(Json::object({{"status", "pending"}}))).kind == ShareKind::Waiting);
    CHECK(share_column(entry_with(Json::object({{"status", "sent"}}))).label == "sent");
    const ShareColumn rej = share_column(entry_with(Json::object({{"status", "rejected"}, {"reason", "title is too short"}})));
    CHECK(rej.kind == ShareKind::Rejected);
    CHECK(rej.tooltip == "title is too short");
    const ShareColumn skip = share_column(entry_with(Json::object({{"status", "skipped"}, {"reason", "you chose Don't send"}})));
    CHECK(skip.kind == ShareKind::Skipped);
    CHECK(skip.tooltip == "you chose Don't send");
}

TEST_CASE("share fields: round trip, optional ones left out, limits count characters") {
    Json e = entry_with(Json());
    ShareFields f = ShareFields::from_entry(e);
    CHECK(f.title == "No one-way platforms");
    CHECK(f.suggestion.empty());
    Json j = f.to_json();
    CHECK(!j.contains("suggestion"));
    CHECK(!j.contains("workaround"));
    CHECK(ShareFields::from_entry(Json::object()).empty());
    CHECK(share_fields_problem(f).empty());

    f.title = "short";
    CHECK(share_fields_problem(f).find("share.title is too short") == 0);
    f.title = "No one-way platforms";
    f.missing = std::string(kShareMissingMax + 1, 'x');
    CHECK(share_fields_problem(f).find("share.missing is too long") == 0);
    f.missing = "";
    CHECK(share_fields_problem(f).find("share.missing is missing") == 0);
    f.missing = std::string(20, 'x');
    f.workaround = std::string(kShareWorkaroundMax + 1, 'y');
    CHECK(share_fields_problem(f).find("share.workaround is too long") == 0);

    // 8 two-byte characters are 8 characters, not 16.
    CHECK(text_chars("\xC3\xA9\xC3\xA9\xC3\xA9\xC3\xA9\xC3\xA9\xC3\xA9\xC3\xA9\xC3\xA9") == 8);
}

TEST_CASE("suggest share: engine words stay, the project's names and quotes go, the workaround is left out") {
    EngineNames engine;
    engine.lower = {"collider2d", "onewayplatform"};
    ProjectNames project;
    project.names = {"Moonlit Heist"};
    Json e = Json::object({{"id", "FB-0002"}, {"status", "open"},
                           {"title", "Collider2D cannot be one-way in Moonlit Heist"},
                           {"missing", "Collider2D has no way to let a player jump up through a platform in Moonlit Heist."},
                           {"suggestion", "Add Collider2D.oneWay"},
                           {"workaround", "I moved the platform in level_3.scene.json"}});
    const ShareSuggestion s = suggest_share(e, engine, project);
    REQUIRE(s.ok);
    CHECK(s.fields.title.find("Moonlit") == std::string::npos);
    CHECK(s.fields.missing.find("Moonlit") == std::string::npos);
    CHECK(s.fields.workaround.empty());
    CHECK(!s.removed.empty());

    const ShareSuggestion none = suggest_share(Json::object({{"title", "x"}}), engine, project);
    CHECK(!none.ok);
    CHECK(!none.reason.empty());
}

TEST_CASE("entries to queue: a share text and no shared yet, open entries only") {
    Json doc = Json::object();
    Json a = entry_with(Json());
    a["id"] = "FB-0001";
    Json b = entry_with(Json::object({{"status", "skipped"}}));
    b["id"] = "FB-0002";
    Json c = Json::object({{"id", "FB-0003"}, {"status", "open"}});
    Json d = entry_with(Json());
    d["id"] = "FB-0004";
    d["status"] = "fixed-in-engine";
    doc["entries"] = Json::array({a, b, c, d});
    const std::vector<std::string> ids = entries_to_queue(doc);
    REQUIRE(ids.size() == 1);
    CHECK(ids[0] == "FB-0001");
    CHECK(entries_to_queue(Json::object()).empty());
}
