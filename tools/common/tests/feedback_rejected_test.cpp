// Feedback that claims a gap the engine does not have (docs/ENGINE_FEEDBACK.md, "The check before filing", "Rejected entries"):
// the check, the rejected status with its reason, delete, and the engine developers' verdicts. Nothing reaches the network.
#include <doctest.h>

#include <filesystem>

#include "fa/core/strings.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_check.h"
#include "fa/tooling/feedback_share.h"
#include "test_helpers.h"

using namespace fa;

namespace {

ClaimResult check(const std::string& title, const std::string& missing, const std::string& suggestion = {}) {
    return check_feedback_claim(ClaimInput{title, missing, suggestion});
}

FeedbackInput input(const std::string& title, const std::string& missing = {}) {
    FeedbackInput in;
    in.category = "physics";
    in.severity = "minor";
    in.title = title;
    in.missing = missing.empty() ? "The engine lacks " + title + " in this game." : missing;
    in.workaround = "Wrote a script for it.";
    return in;
}

std::string one_way_missing() { return "Collider2D has no one-way option, so a body cannot pass up through a platform and land on it."; }

Json status_of(const std::string& file, const std::string& id) {
    for (const std::string& path : {file, feedback_archive_path(file)}) {
        auto doc = load_feedback(path);
        if (!doc.ok()) continue;
        for (const Json& e : (*doc)["entries"])
            if (e.value("id", std::string()) == id) return e;
    }
    return Json();
}

HttpResponse reply(const Json& body) {
    HttpResponse r;
    r.ok = true;
    r.status = 200;
    r.body = body.dump();
    return r;
}

// A user config folder in a temp dir and a transport that records the requests and answers from `answer`.
struct Net {
    testing::TempDir dir;
    ShareEnv env;
    std::vector<HttpRequest> requests;
    std::function<HttpResponse(const HttpRequest&)> answer;

    Net() {
        const std::string home = dir.sub("home");
        env.env = [home](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? home : ""; };
        env.now = [] { return std::int64_t(1'800'000'000); };
        env.sleep = [](double) {};
        env.makeUuid = [] { return std::string("11111111-2222-4333-8444-555555555555"); };
        env.defaultEndpoint = "https://feedback.example.test";
        env.githubClientId = "client-id-1";
        env.platform = "linux";
        env.engineVersion = "9.9.9";
        env.transport = [this](const HttpRequest& rq) {
            requests.push_back(rq);
            if (!answer) {
                HttpResponse r;
                r.ok = false;
                r.error = "no answer scripted";
                return r;
            }
            return answer(rq);
        };
    }
};

// A feedback file with two entries that were sent (shareIds r_1 and r_2) and one that was not.
std::string file_with_sent(const std::string& dir) {
    const std::string file = dir + "/ENGINE_FEEDBACK.json";
    Json doc = create_empty_feedback("Lantern Keep", "9.9.9");
    for (const char* title : {"Rope bridges sway", "Weather changes slowly", "Boats float upstream"}) {
        auto r = add_feedback_entry(doc, input(title));
        REQUIRE(r.ok());
    }
    REQUIRE(save_feedback(file, doc).ok());
    write_entry_shared(file, "FB-0001", Json::object({{"status", "sent"}, {"shareId", "r_1"}, {"date", "2027-01-15"}}));
    write_entry_shared(file, "FB-0002", Json::object({{"status", "sent"}, {"shareId", "r_2"}, {"date", "2027-01-15"}}));
    return file;
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ the check

TEST_CASE("feedback check: a report that says the engine lacks what it has is refused, with what exists") {
    const ClaimResult r = check("No one-way platforms", one_way_missing(), "Add Collider2D.oneWay (bool).");
    REQUIRE(r.refused());
    CHECK(r.matches.front().name == "Collider2D.oneWay");
    CHECK(r.matches.front().kind == "field");
    CHECK_FALSE(r.matches.front().doc.empty());                      // its doc string
    CHECK(r.matches.front().documentedIn.find("docs/") == 0);       // where it is documented
    const std::string message = r.message(), hint = r.hint();
    CHECK(message.find("Collider2D.oneWay") != std::string::npos);
    CHECK(message.find("Its doc string") != std::string::npos);
    CHECK(hint.find("file it as a bug") != std::string::npos);
    CHECK(hint.find("what you set") != std::string::npos);
    const std::string reason = r.reason();  // what a rejected entry stores: one line, within the limit
    CHECK(reason.find('\n') == std::string::npos);
    CHECK(int(reason.size()) <= kFeedbackReasonMax);
    CHECK(reason.find("Collider2D.oneWay") != std::string::npos);
    const Json j = r.to_json();
    CHECK(j["exists"] == true);
    CHECK(j["matches"].size() >= 1);
}

TEST_CASE("feedback check: no false positive when the report names a bug, or asks for more than exists") {
    SUBCASE("a bug: the thing exists and does not work as documented") {
        const ClaimResult r = check("Collider2D.oneWay is ignored", "I set oneWay to true on the platform and a body still collides from below.");
        CHECK_FALSE(r.refused());
    }
    SUBCASE("an extra option on an existing component") {
        const ClaimResult r = check("Collider2D needs a bounce curve", "Collider2D has a bounciness number, but the bounce cannot follow a curve over speed.",
                                    "Add Collider2D.bounceCurve (a curve).");
        CHECK_FALSE(r.refused());
    }
    SUBCASE("a real gap") {
        CHECK_FALSE(check("No fluid simulation", "Nothing simulates water that flows around obstacles.").refused() == false);  // the example
        CHECK_FALSE(check("Rope bridges sway", "Nothing makes a chain of planks swing under a body's weight.").refused());
    }
    SUBCASE("related docs without a refusal") {
        const ClaimResult r = check_feedback_claim(ClaimInput{"Rope bridges sway", "Nothing makes a chain of planks swing.", ""}, nullptr, 3);
        CHECK_FALSE(r.refused());
        CHECK(r.related.is_array());
        CHECK(r.related.size() <= 3);
    }
}

TEST_CASE("feedback check: the invented example of the feedback.report docs is not filed as it is") {
    const ClaimResult r = check(kFeedbackExampleTitle, "Nothing simulates a fluid.");
    REQUIRE(r.refused());
    CHECK(r.matches.front().kind == "example");
    CHECK(r.message().find("invented example") != std::string::npos);
}

TEST_CASE("feedback check: a command the engine has is named too") {
    CommandRegistry registry;
    register_feedback_commands(registry, ".");
    const ClaimResult r = check_feedback_claim(ClaimInput{"Missing a command to delete feedback", "There is no feedback.delete command.", ""}, &registry);
    REQUIRE(r.refused());
    CHECK(r.matches.front().name == "feedback.delete");
}

// ----------------------------------------------------------------------------------------- feedback.report, the commands

TEST_CASE("feedback.report refuses a claim the engine already covers, and files a bug about the same thing") {
    testing::TempDir dir;
    CommandRegistry registry;
    register_feedback_commands(registry, dir.str());
    Json args = Json::object({{"category", "physics"}, {"severity", "major"}, {"title", "No one-way platforms"},
                              {"missing", one_way_missing()}, {"workaround", "A script toggles the collider."}});
    auto refused = registry.call("feedback.report", args);
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error.value("code", std::string()) == "already_exists");
    CHECK(refused.error.dump().find("Collider2D.oneWay") != std::string::npos);
    CHECK(refused.error.dump().find("bug") != std::string::npos);
    CHECK_FALSE(std::filesystem::exists(dir.sub("ENGINE_FEEDBACK.json")));  // nothing was written

    args["title"] = "Collider2D.oneWay is ignored";
    args["missing"] = "I set oneWay to true and the body still collides from below, although the docs say it passes.";
    auto bug = registry.call("feedback.report", args);
    REQUIRE(bug.ok);
    CHECK(bug.result["id"] == "FB-0001");
}

TEST_CASE("feedback.check: the check on its own, and over the open entries") {
    testing::TempDir dir;
    CommandRegistry registry;
    register_feedback_commands(registry, dir.str());
    auto exists = registry.call("feedback.check", Json::object({{"title", "No one-way platforms"}, {"missing", one_way_missing()}}));
    REQUIRE(exists.ok);
    CHECK(exists.result["exists"] == true);
    auto fine = registry.call("feedback.check", Json::object({{"title", "Rope bridges sway"}, {"missing", "Nothing makes a chain of planks swing."}}));
    REQUIRE(fine.ok);
    CHECK(fine.result["exists"] == false);
}

// ----------------------------------------------------------------------------------------------- rejected and its reason

TEST_CASE("rejected: a reason is required, stored with who decided, and the entry goes to the archive") {
    testing::TempDir dir;
    const std::string file = dir.sub("ENGINE_FEEDBACK.json");
    REQUIRE(add_feedback_entry_to_file(file, input("Rope bridges sway"), "g").ok());

    auto noReason = update_feedback_file(file, "FB-0001", "rejected", "");
    REQUIRE_FALSE(noReason.ok());
    CHECK(noReason.error().message.find("reason") != std::string::npos);
    CHECK(status_of(file, "FB-0001").value("status", std::string()) == "open");

    auto done = update_feedback_file(file, "FB-0001", "rejected", "", "", "  Not a gap:\n the engine has it.\t", "user");
    REQUIRE(done.ok());
    CHECK((*done)["status"] == "rejected");
    CHECK((*done)["statusReason"] == "Not a gap: the engine has it.");  // plain text on one line
    CHECK((*done)["statusBy"] == "user");

    auto moved = archive_closed_feedback_file(file);
    REQUIRE(moved.ok());
    CHECK(moved->moved == 1);
    CHECK(status_of(file, "FB-0001").value("statusReason", std::string()) == "Not a gap: the engine has it.");
    CHECK(validate_feedback(*load_feedback(feedback_archive_path(file))).empty());

    auto reopened = update_feedback_file(file, "FB-0001", "open", "");  // an archived entry reopens into the file
    REQUIRE(reopened.ok());
    CHECK_FALSE(reopened->contains("statusReason"));
    CHECK_FALSE(reopened->contains("statusBy"));
    CHECK(load_feedback(file)->at("entries").size() == 1);
}

TEST_CASE("rejected: sanitize_status_reason keeps plain text within the limit, never cutting a character") {
    CHECK(sanitize_status_reason("  a \n\n b\tc ") == "a b c");
    CHECK(int(sanitize_status_reason(std::string(kFeedbackReasonMax + 40, 'x')).size()) == kFeedbackReasonMax);
    const std::string broken(2 * kFeedbackReasonMax + 40, '\xC3');  // not valid UTF-8: must still be cut, never overrun
    CHECK(int(sanitize_status_reason(broken).size()) <= 2 * kFeedbackReasonMax);
    std::string twoByte;
    for (int i = 0; i < kFeedbackReasonMax + 20; ++i) twoByte += "\xC3\xA9";  // e acute
    const std::string cut = sanitize_status_reason(twoByte);
    CHECK(cut.size() % 2 == 0);  // no half character
    CHECK(int(cut.size()) <= 2 * kFeedbackReasonMax);
}

TEST_CASE("rejected: the engine rejects the open entries whose claim fails the check, and leaves a reopened one alone") {
    testing::TempDir dir;
    const std::string file = dir.sub("ENGINE_FEEDBACK.json");
    REQUIRE(add_feedback_entry_to_file(file, input("No one-way platforms", one_way_missing()), "g").ok());
    REQUIRE(add_feedback_entry_to_file(file, input("Rope bridges sway"), "g").ok());
    auto rejected = reject_claimed_feedback_file(file);
    REQUIRE(rejected.ok());
    REQUIRE(rejected->size() == 1);
    CHECK((*rejected)[0] == "FB-0001");
    const Json e = status_of(file, "FB-0001");
    CHECK(e["status"] == "rejected");
    CHECK(e["statusBy"] == "engine");
    CHECK(e["statusReason"].get<std::string>().find("Collider2D.oneWay") != std::string::npos);
    CHECK(status_of(file, "FB-0002")["status"] == "open");

    // A person who disagrees reopens it: the engine never rejects it again.
    REQUIRE(update_feedback_file(file, "FB-0001", "open", "").ok());
    CHECK(status_of(file, "FB-0001")["claimCheck"] == "dismissed");
    auto again = reject_claimed_feedback_file(file);
    REQUIRE(again.ok());
    CHECK(again->empty());
    CHECK(status_of(file, "FB-0001")["status"] == "open");
}

// ---------------------------------------------------------------------------------------------------------------- delete

TEST_CASE("delete: a closed entry goes from the file or the archive, an open one is refused, and an id is never reused") {
    testing::TempDir dir;
    const std::string file = dir.sub("ENGINE_FEEDBACK.json");
    for (const char* title : {"Rope bridges sway", "Weather changes slowly", "Boats float upstream"}) REQUIRE(add_feedback_entry_to_file(file, input(title), "g").ok());

    std::string why;
    CHECK_FALSE(feedback_entry_deletable(status_of(file, "FB-0003"), &why));
    CHECK_FALSE(why.empty());
    auto refused = delete_feedback_file(file, "FB-0003");
    REQUIRE_FALSE(refused.ok());
    CHECK(status_of(file, "FB-0003").value("id", std::string()) == "FB-0003");  // untouched

    REQUIRE(update_feedback_file(file, "FB-0003", "rejected", "", "", "Not a gap.", "user").ok());
    REQUIRE(archive_closed_feedback_file(file).ok());  // FB-0003 is in the archive now
    auto gone = delete_feedback_file(file, "FB-0003");
    REQUIRE(gone.ok());
    CHECK((*gone)["id"] == "FB-0003");
    CHECK(status_of(file, "FB-0003").is_null());

    auto fresh = add_feedback_entry_to_file(file, input("Tides pull on boats"), "g");
    REQUIRE(fresh.ok());
    CHECK(fresh->id == "FB-0004");  // not FB-0003 again

    REQUIRE(update_feedback_file(file, "FB-0001", "wont-fix", "").ok());  // still in the file: deleted from there
    REQUIRE(delete_feedback_file(file, "FB-0001").ok());
    CHECK(status_of(file, "FB-0001").is_null());
    CHECK(delete_feedback_file(file, "FB-0099").ok() == false);
}

TEST_CASE("delete: an open entry the engine developers refused can go; the command takes it out of the outbox") {
    Net net;
    ScopedShareEnv scoped(net.env);
    const std::string file = file_with_sent(net.dir.sub("game"));
    write_entry_shared(file, "FB-0003", Json::object({{"status", "declined"}, {"shareId", "r_3"}, {"reason", "Not a gap."}}));
    CHECK(feedback_entry_deletable(status_of(file, "FB-0003")));
    CHECK_FALSE(feedback_entry_deletable(status_of(file, "FB-0001")));  // sent, nobody refused it
    CommandRegistry registry;
    register_feedback_commands(registry, net.dir.sub("game"));
    auto r = registry.call("feedback.delete", Json::object({{"id", "FB-0003"}}));
    REQUIRE(r.ok);
    CHECK(r.result["deleted"] == "FB-0003");
    auto open = registry.call("feedback.delete", Json::object({{"id", "FB-0001"}}));
    CHECK_FALSE(open.ok);
}

// -------------------------------------------------------------------------------------------------------------- verdicts

TEST_CASE("verdicts: a rejected report comes back as a rejected entry with the developers' reason, once") {
    Net net;
    ScopedShareEnv scoped(net.env);
    net.answer = [](const HttpRequest& rq) {
        REQUIRE(rq.url == "https://feedback.example.test/v1/verdicts");
        const Json body = Json::parse(rq.body);
        Json verdicts = Json::array();
        for (const Json& id : body["shareIds"]) {
            if (id == "r_1") verdicts.push_back(Json::object({{"shareId", "r_1"}, {"status", "rejected"}, {"reason", "Not a gap: it is documented."}}));
            else verdicts.push_back(Json::object({{"shareId", id}, {"status", "received"}}));
        }
        return reply(Json::object({{"ok", true}, {"verdicts", verdicts}}));
    };
    const std::string file = file_with_sent(net.dir.sub("game"));
    REQUIRE(set_share_mode(net.env, ShareMode::Ask).ok());

    const VerdictResult first = share_sync_verdicts(net.env, file);
    CHECK(first.outcome == "ok");
    CHECK(first.declined == 1);
    CHECK(first.changed == std::vector<std::string>{"FB-0001"});
    REQUIRE(net.requests.size() == 1);
    // authenticated by the installation header, asking only for this file's own sent shareIds
    bool install = false;
    for (const auto& [k, v] : net.requests[0].headers) install = install || (k == "X-Factoria-Install" && !v.empty());
    CHECK(install);
    const Json asked = Json::parse(net.requests[0].body);
    CHECK(asked["shareIds"] == Json::parse(R"(["r_1","r_2"])"));
    const Json e = status_of(file, "FB-0001");
    CHECK(e["status"] == "rejected");
    CHECK(e["statusBy"] == "developer");
    CHECK(e["statusReason"] == "Not a gap: it is documented.");
    CHECK(e["shared"]["status"] == "declined");
    CHECK(status_of(file, "FB-0002")["status"] == "open");

    // The next question changes nothing and the declined entry is never sent again.
    const VerdictResult second = share_sync_verdicts(net.env, file);
    CHECK(second.declined == 0);
    CHECK(second.changed.empty());
    CHECK_FALSE(entry_is_shareable(status_of(file, "FB-0001")));
}

TEST_CASE("verdicts: a rejection taken back reopens the entry; an answer for an id that is not ours is ignored") {
    Net net;
    ScopedShareEnv scoped(net.env);
    const std::string file = file_with_sent(net.dir.sub("game"));
    REQUIRE(set_share_mode(net.env, ShareMode::Always).ok());
    net.answer = [](const HttpRequest&) {
        return reply(Json::object({{"ok", true},
                                   {"verdicts", Json::array({Json::object({{"shareId", "r_1"}, {"status", "rejected"}, {"reason", "No."}}),
                                                             Json::object({{"shareId", "r_77"}, {"status", "rejected"}, {"reason", "Somebody else's."}})})}}));
    };
    CHECK(share_sync_verdicts(net.env, file).declined == 1);
    CHECK(status_of(file, "FB-0001")["status"] == "rejected");

    net.answer = [](const HttpRequest&) {
        return reply(Json::object({{"ok", true}, {"verdicts", Json::array({Json::object({{"shareId", "r_1"}, {"status", "received"}})})}}));
    };
    const VerdictResult back = share_sync_verdicts(net.env, file);
    CHECK(back.restored == 1);
    const Json e = status_of(file, "FB-0001");
    CHECK(e["status"] == "open");
    CHECK(e["shared"]["status"] == "sent");
    CHECK_FALSE(e.contains("statusReason"));
    CHECK(status_of(file, "FB-0003").value("shared", Json::object()).empty());  // nothing written for an id that is not ours
}

TEST_CASE("verdicts: an old server (404), a server that is down, sharing off and nothing sent change nothing") {
    Net net;
    ScopedShareEnv scoped(net.env);
    const std::string file = file_with_sent(net.dir.sub("game"));

    CHECK(share_sync_verdicts(net.env, file).outcome == "off");  // the mode is not chosen: nothing is asked
    CHECK(net.requests.empty());

    REQUIRE(set_share_mode(net.env, ShareMode::Ask).ok());
    net.answer = [](const HttpRequest&) {
        HttpResponse r;
        r.ok = true;
        r.status = 404;
        r.body = R"({"ok":false,"error":{"code":"not_found"}})";
        return r;
    };
    const VerdictResult old = share_sync_verdicts(net.env, file);
    CHECK(old.outcome == "unsupported");
    CHECK(old.declined == 0);
    CHECK(status_of(file, "FB-0001")["status"] == "open");

    net.answer = nullptr;  // transport failure
    CHECK(share_sync_verdicts(net.env, file).outcome == "failed");

    const std::string empty = net.dir.sub("other/ENGINE_FEEDBACK.json");
    REQUIRE(add_feedback_entry_to_file(empty, input("Rope bridges sway"), "g").ok());
    const std::size_t before = net.requests.size();
    CHECK(share_sync_verdicts(net.env, empty).outcome == "idle");  // nothing was sent: no request
    CHECK(net.requests.size() == before);
}
