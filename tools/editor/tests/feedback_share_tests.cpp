// The Engine Feedback panel's view of sharing without a window: the share column, the share fields and their limits, the
// suggested share text and which entries get queued (feedback_share_model.h). The drawing is covered by the autotest (section E2).
#include <filesystem>

#include "doctest.h"
#include "fa/core/fs.h"
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
    CHECK(share_column(noShare).label == "not sent");
    CHECK(share_column(noShare).kind == ShareKind::NotShared);
    CHECK(share_column(entry_with(Json())).label == "not sent");
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

// ------------------------------------------------------------------------------------------------ the Send feedback window

namespace {
EngineNames send_engine() {
    EngineNames e;
    e.lower = {"collider2d", "onewayplatform", "tilemap", "camera2d", "follow", "shake"};
    return e;
}
Json open_entry(const std::string& id, const std::string& title, const std::string& missing, const Json& share = Json(),
                const Json& shared = Json()) {
    Json e = Json::object({{"id", id}, {"status", "open"}, {"category", "physics"}, {"severity", "major"}, {"occurrences", 1},
                           {"title", title}, {"missing", missing}, {"suggestion", "Add Collider2D.oneWay"}});
    if (!share.is_null()) e["share"] = share;
    if (!shared.is_null()) e["shared"] = shared;
    return e;
}
Json doc_of(std::initializer_list<Json> entries) {
    Json doc = Json::object();
    doc["entries"] = Json::array();
    for (const Json& e : entries) doc["entries"].push_back(e);
    return doc;
}
const std::string kLongMissing = "Collider2D cannot be one-way, so a player cannot jump up through a platform and land on it.";
}  // namespace

TEST_CASE("send plan: lists the entries that would be sent, all checked, with the text that leaves") {
    Json shareOk = Json::object({{"title", "No one-way platforms"}, {"missing", kLongMissing}});
    const Json doc = doc_of({
        open_entry("FB-0001", "Collider2D has no one-way option", kLongMissing),                        // AI entry without a share
        open_entry("FB-0002", "Camera2D has no shake", kLongMissing, shareOk),                          // with its own share
        open_entry("FB-0003", "Closed one", kLongMissing, shareOk),
    });
    Json closed = doc;
    closed["entries"][2]["status"] = "fixed-in-engine";
    const std::vector<SendRow> rows = plan_send(closed, {}, send_engine(), {});
    REQUIRE(rows.size() == 2);
    CHECK(rows[0].id == "FB-0001");
    CHECK(rows[0].canSend);
    CHECK(rows[0].checked);
    CHECK(rows[0].madeHere);  // text made from the entry, nothing stored yet
    CHECK(!rows[0].hasShare);
    CHECK(!rows[0].fields.title.empty());
    CHECK(rows[1].id == "FB-0002");
    CHECK(rows[1].hasShare);
    CHECK(!rows[1].madeHere);
    CHECK(rows[1].checked);
    CHECK(rows[1].fields.title == "No one-way platforms");
    // The text shown is exactly what the server receives.
    CHECK(rows[1].sent["title"] == rows[1].fields.title);
    CHECK(rows[1].sent["missing"] == rows[1].fields.missing);
    CHECK(rows[1].sent["localId"] == "FB-0002");
    CHECK(rows[0].category == "physics");
}

TEST_CASE("send plan: sent, rejected and queued entries stay out; hit again after a send goes once more; left out is unchecked") {
    Json shareOk = Json::object({{"title", "No one-way platforms"}, {"missing", kLongMissing}});
    Json sent = Json::object({{"status", "sent"}, {"occurrences", 1}});
    Json rejected = Json::object({{"status", "rejected"}, {"reason", "too vague"}});
    Json skipped = Json::object({{"status", "skipped"}, {"reason", "left out"}});
    Json pending = Json::object({{"status", "pending"}});
    Json doc = doc_of({
        open_entry("FB-0001", "Sent already", kLongMissing, shareOk, sent),
        open_entry("FB-0002", "Hit again after it was sent", kLongMissing, shareOk, sent),
        open_entry("FB-0003", "Refused by the server", kLongMissing, shareOk, rejected),
        open_entry("FB-0004", "Left out last time", kLongMissing, shareOk, skipped),
        open_entry("FB-0005", "On its way", kLongMissing, shareOk, pending),
        open_entry("FB-0006", "Waiting for an answer", kLongMissing, shareOk, pending),
        open_entry("FB-0007", "Pending but not in the outbox", kLongMissing, shareOk, pending),
    });
    doc["entries"][1]["occurrences"] = 2;
    SendOutbox outbox;
    outbox.queued = {"FB-0005"};
    outbox.waiting = {"FB-0006"};
    const std::vector<SendRow> rows = plan_send(doc, outbox, send_engine(), {});
    REQUIRE(rows.size() == 4);
    CHECK(rows[0].id == "FB-0002");
    CHECK(rows[0].resend);
    CHECK(rows[0].checked);
    CHECK(rows[1].id == "FB-0004");
    CHECK(rows[1].leftOut);
    CHECK(rows[1].canSend);
    CHECK(!rows[1].checked);
    CHECK(rows[2].id == "FB-0006");
    CHECK(rows[2].waiting);
    CHECK(rows[2].checked);
    CHECK(rows[3].id == "FB-0007");

    // At most three sends of one entry.
    doc["entries"][1]["occurrences"] = 9;
    doc["entries"][1]["shared"]["occurrences"] = 3;
    CHECK(!entry_can_be_sent(doc["entries"][1]));
    doc["entries"][1]["shared"]["occurrences"] = 2;
    CHECK(entry_can_be_sent(doc["entries"][1]));
}

TEST_CASE("send plan: an entry no text can be made from is a disabled row with the reason") {
    const Json doc = doc_of({open_entry("FB-0001", "x", "short")});
    const std::vector<SendRow> rows = plan_send(doc, {}, send_engine(), {});
    REQUIRE(rows.size() == 1);
    CHECK(!rows[0].canSend);
    CHECK(!rows[0].checked);
    CHECK(!rows[0].problem.empty());
    CHECK(rows[0].sent.is_null());
}

TEST_CASE("send plan: the project's names never leave in the text made from the entry") {
    ProjectNames project;
    project.names = {"Moonlit Heist"};
    const Json doc = doc_of({open_entry("FB-0001", "Collider2D cannot be one-way in Moonlit Heist",
                                        "Collider2D has no way to let a player jump up through a platform in Moonlit Heist.")});
    const std::vector<SendRow> rows = plan_send(doc, {}, send_engine(), project);
    REQUIRE(rows.size() == 1);
    REQUIRE(rows[0].canSend);
    CHECK(rows[0].fields.title.find("Moonlit") == std::string::npos);
    CHECK(rows[0].sent.dump().find("Moonlit") == std::string::npos);
}

TEST_CASE("send plan: set_send_text replaces the text when usable and keeps the row when not") {
    const Json entry = open_entry("FB-0001", "Collider2D has no one-way option", kLongMissing);
    std::vector<SendRow> rows = plan_send(doc_of({entry}), {}, send_engine(), {});
    REQUIRE(rows.size() == 1);
    ShareFields better;
    better.title = "Collider2D lacks a one-way mode";
    better.missing = "A Collider2D cannot be crossed from below, so one-way platforms are impossible.";
    std::string problem;
    CHECK(set_send_text(rows[0], entry, better, send_engine(), {}, problem));
    CHECK(rows[0].fields.title == "Collider2D lacks a one-way mode");
    CHECK(rows[0].sent["title"] == "Collider2D lacks a one-way mode");

    ShareFields bad = better;
    bad.title = "no";
    CHECK(!set_send_text(rows[0], entry, bad, send_engine(), {}, problem));
    CHECK(!problem.empty());
    CHECK(rows[0].fields.title == "Collider2D lacks a one-way mode");
}

TEST_CASE("send plan: share_edit_for_send stores the text only when it differs, and the reviewed flag") {
    Json shareOk = Json::object({{"title", "No one-way platforms"}, {"missing", kLongMissing}});
    Json noShare = open_entry("FB-0001", "Collider2D has no one-way option", kLongMissing);
    Json withShare = open_entry("FB-0002", "Collider2D has no one-way option", kLongMissing, shareOk);
    ShareFields shown = ShareFields::from_entry(withShare);

    auto edit = share_edit_for_send(noShare, shown, false);
    REQUIRE(edit.has_value());
    CHECK(edit->share["title"] == "No one-way platforms");
    REQUIRE(edit->reviewed.has_value());
    CHECK(*edit->reviewed == false);

    CHECK(!share_edit_for_send(withShare, shown, false).has_value());  // nothing to write

    auto flagged = share_edit_for_send(withShare, shown, true);  // same text, the review passed
    REQUIRE(flagged.has_value());
    CHECK(flagged->share.is_null());
    CHECK(*flagged->reviewed == true);

    ShareFields rewritten = shown;
    rewritten.title = "Collider2D lacks a one-way mode";
    auto changed = share_edit_for_send(withShare, rewritten, true);
    REQUIRE(changed.has_value());
    CHECK(changed->share["title"] == "Collider2D lacks a one-way mode");
    CHECK(*changed->reviewed == true);

    withShare["reviewed"] = true;
    CHECK(!share_edit_for_send(withShare, shown, true).has_value());  // already reviewed
}

namespace {
// A user config folder and a project in a temp dir; the transport fails every request: nothing reaches a network.
struct SendFixture {
    std::filesystem::path dir = fa::fs::make_temp_dir("fa_send_model").value();
    ShareEnv env;
    int requests = 0;
    std::string file;
    SendFixture() {
        const std::string home = ((dir / "home")).generic_string();
        env.env = [home](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? home : ""; };
        env.now = [] { return std::int64_t(1'800'000'000); };
        env.makeUuid = [] { return std::string("11111111-2222-4333-8444-555555555555"); };
        env.defaultEndpoint = "https://feedback.example.test";
        env.platform = "linux";
        env.engineVersion = "9.9.9";
        env.transport = [this](const HttpRequest&) {
            ++requests;
            HttpResponse r;
            r.ok = false;
            r.error = "offline in tests";
            return r;
        };
        file = ((dir / "game" / "ENGINE_FEEDBACK.json")).generic_string();
        std::filesystem::create_directories(dir / "game");
        Json doc = create_empty_feedback("Lantern Keep", "9.9.9");
        for (const char* title : {"Collider2D has no one-way option", "Camera2D has no shake support"}) {
            FeedbackInput in;
            in.category = "physics";
            in.severity = "major";
            in.title = title;
            in.missing = kLongMissing;
            in.workaround = "scripts/aldric_jump.js toggles the collider";
            in.reporter = Json::object({{"kind", "ai"}});
            REQUIRE(add_feedback_entry(doc, in).ok());
        }
        REQUIRE(save_feedback(file, doc).ok());
    }
    ~SendFixture() {
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
    std::string project() const { return ((dir / "game")).generic_string(); }
};
}  // namespace

TEST_CASE("send apply: the checked rows get their text stored and are queued, the unchecked are left out; nothing is sent") {
    SendFixture f;
    REQUIRE(set_share_mode(f.env, ShareMode::Always).ok());
    auto doc = load_feedback(f.file);
    REQUIRE(doc.ok());
    std::vector<SendRow> rows = plan_send(*doc, {}, send_engine(), {});
    REQUIRE(rows.size() == 2);

    std::vector<SendChoice> choices;
    for (size_t i = 0; i < rows.size(); ++i) choices.push_back({rows[i].id, i == 0, rows[i].fields, false});
    const SendApplied applied = apply_send(f.env, f.file, f.project(), send_engine(), choices);
    CHECK(applied.error.empty());
    REQUIRE(applied.rows.size() == 2);
    CHECK(applied.rows[0].id == "FB-0001");
    CHECK(applied.rows[0].status == "queued");
    CHECK(applied.rows[1].status == "skipped");
    CHECK(f.requests == 0);

    auto after = load_feedback(f.file);
    REQUIRE(after.ok());
    const Json& e1 = (*after)["entries"][0];
    CHECK(e1["share"]["title"] == rows[0].fields.title);   // stored on Send
    CHECK(e1["shared"]["status"] == "pending");
    const Json& e2 = (*after)["entries"][1];
    CHECK(!e2.contains("share"));                           // the unchecked one stored nothing
    CHECK(e2["shared"]["status"] == "skipped");

    const Outbox box = load_outbox(f.env);
    REQUIRE(box.items.size() == 1);
    CHECK(box.items[0].localId == "FB-0001");
    CHECK(box.items[0].entry["title"] == rows[0].fields.title);  // what is queued is what the window showed
    CHECK(box.items[0].entry["missing"] == rows[0].fields.missing);

    // Next time the left-out one is offered again, unchecked; the queued one is on its way.
    SendOutbox ob;
    ob.queued = {"FB-0001"};
    const std::vector<SendRow> again = plan_send(*after, ob, send_engine(), {});
    REQUIRE(again.size() == 1);
    CHECK(again[0].id == "FB-0002");
    CHECK(again[0].leftOut);
    CHECK(!again[0].checked);
}

TEST_CASE("send apply: ask mode confirms what was checked; never and unset send nothing") {
    SendFixture f;
    REQUIRE(set_share_mode(f.env, ShareMode::Ask).ok());
    auto doc = load_feedback(f.file);
    REQUIRE(doc.ok());
    std::vector<SendRow> rows = plan_send(*doc, {}, send_engine(), {});
    REQUIRE(rows.size() == 2);
    std::vector<SendChoice> choices;
    for (const SendRow& r : rows) choices.push_back({r.id, true, r.fields, true});
    const SendApplied applied = apply_send(f.env, f.file, f.project(), send_engine(), choices);
    CHECK(applied.error.empty());
    CHECK(applied.mode == ShareMode::Ask);
    CHECK(share_waiting(f.env, f.file).empty());  // pressing Send is the answer
    const Outbox box = load_outbox(f.env);
    REQUIRE(box.items.size() == 2);
    CHECK(box.items[0].state == OutboxState::Queued);
    auto after = load_feedback(f.file);
    CHECK((*after)["entries"][0]["reviewed"] == true);  // the AI check passed

    REQUIRE(set_share_mode(f.env, ShareMode::Never).ok());
    const SendApplied off = apply_send(f.env, f.file, f.project(), send_engine(), choices);
    CHECK(!off.error.empty());
    CHECK(off.rows.empty());
    CHECK(f.requests == 0);
}
