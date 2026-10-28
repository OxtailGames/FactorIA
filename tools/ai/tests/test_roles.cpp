// The seven AI roles: defaults that follow the user's provider, read-only enforcement, reviews (parse, save, list) and the
// commands around them (ai.review, ai.reviews, ai.run refusing the critics).
#include <fstream>

#include "fa/ai/commands.h"
#include "fa/ai/review.h"
#include "fa/core/fs.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

// make_registry() plus a command that edits (readOnly=false) and the commands that play.
CommandRegistry roles_registry() {
    CommandRegistry r = make_registry();
    auto add = [&r](const char* name, bool readOnly) {
        CommandInfo c;
        c.name = name;
        c.summary = name;
        c.readOnly = readOnly;
        r.add(c, [](const Json&) { return Json::object(); });
    };
    add("scene.spawn", false);
    add("fs.write", false);
    add("assets.generate_image", false);
    add("game.step", false);
    add("game.click", false);
    add("scene.load", false);
    return r;
}

std::vector<std::string> tool_names(const std::vector<ToolDef>& tools) {
    std::vector<std::string> out;
    for (const auto& t : tools) out.push_back(t.name);
    return out;
}

}  // namespace

TEST_CASE("roles: the Anthropic defaults of the four new roles") {
    AiConfig c = default_config();
    CHECK(c.role("artist").model == "claude-opus-5-5");
    CHECK(c.role("artist").effort == "high");
    CHECK(c.role("audio").model == "claude-sonnet-5-5");
    CHECK(c.role("audio").effort == "medium");
    CHECK(c.role("artCritic").model == "claude-opus-5-5");
    CHECK(c.role("artCritic").effort == "high");
    CHECK(c.role("reviewer").model == "claude-opus-5-5");
    CHECK(c.role("reviewer").effort == "high");
    for (const char* r : kAllRoles) CHECK_MESSAGE(c.roles.count(r) == 1, r);
    CHECK(std::size(kAllRoles) == 7);
}

TEST_CASE("roles: an old ai.json with three Claude Code roles gives the new roles Claude Code too, never an API key") {
    auto cfg = parse_config(Json::parse(R"({"roles":{
        "orchestrator":{"provider":"claude-code","model":"opus"},
        "worker":{"provider":"claude-code","model":"sonnet"},
        "fast":{"provider":"claude-code","model":"haiku"}}})"),
                            "old");
    REQUIRE(cfg);
    for (const char* r : {"artist", "audio", "artCritic", "reviewer"}) CHECK_MESSAGE(cfg->role(r).provider == "claude-code", r);
    CHECK(cfg->role("artist").model == "opus");
    CHECK(cfg->role("artCritic").model == "opus");
    CHECK(cfg->role("reviewer").model == "opus");
    CHECK(cfg->role("audio").model == "sonnet");
    CHECK(cfg->role("artist").effort == "high");
    CHECK(cfg->role("audio").effort == "medium");
}

TEST_CASE("roles: the new roles follow the base role's provider, not an Anthropic default") {
    // Only the orchestrator and worker are set, to Codex: the others follow, with no Anthropic effort levels.
    auto cfg = parse_config(Json::parse(R"({"roles":{
        "orchestrator":{"provider":"codex","model":"gpt-x"},
        "worker":{"provider":"codex","model":"gpt-y"}}})"),
                            "codex");
    REQUIRE(cfg);
    CHECK(cfg->role("reviewer").provider == "codex");
    CHECK(cfg->role("reviewer").model == "gpt-x");
    CHECK(cfg->role("reviewer").effort.empty());
    CHECK(cfg->role("audio").provider == "codex");
    CHECK(cfg->role("audio").model == "gpt-y");
    // A file that names a new role wins over the derived value, and the others keep following.
    auto own = parse_config(Json::parse(R"({"roles":{
        "orchestrator":{"provider":"claude-code","model":"opus"},
        "artist":{"provider":"anthropic","model":"claude-opus-5-5","effort":"max"}}})"),
                            "own");
    REQUIRE(own);
    CHECK(own->role("artist").provider == "anthropic");
    CHECK(own->role("artist").effort == "max");
    CHECK(own->role("reviewer").provider == "claude-code");
}

TEST_CASE("roles: the schema accepts the new roles and save_roles writes only the roles it is given") {
    CHECK(validate_config_json(Json::parse(R"({"roles":{"artist":{"provider":"claude-code","model":"opus","effort":"high"},
        "audio":{"provider":"claude-code"},"artCritic":{"provider":"claude-code"},"reviewer":{"provider":"claude-code"}}})"))
              .empty());
    CHECK_FALSE(validate_config_json(Json::parse(R"({"roles":{"artst":{"provider":"claude-code"}}})")).empty());
    TempDir dir;
    const std::string file = (dir.path / "ai.json").string();
    std::map<std::string, RoleConfig> roles;
    roles["orchestrator"] = {"claude-code", "opus", "", 0};
    REQUIRE(save_roles(roles, file));
    Json j = Json::parse(*fs::read_text(file));
    CHECK(j["roles"].size() == 1);  // nothing about the other six
    auto cfg = load_config(file);
    REQUIRE(cfg);
    CHECK(cfg->role("reviewer").provider == "claude-code");
}

TEST_CASE("roles: which roles may be delegated") {
    for (const char* r : {"worker", "fast", "artist", "audio"}) CHECK_MESSAGE(is_delegable_role(r), r);
    for (const char* r : {"orchestrator", "artCritic", "reviewer", "nope"}) CHECK_MESSAGE(!(is_delegable_role(r)), r);
    CHECK(is_review_role("artCritic"));
    CHECK(is_review_role("reviewer"));
    CHECK_FALSE(is_review_role("artist"));
    CHECK(is_known_role("audio"));
    CHECK_FALSE(is_known_role("critic"));
}

TEST_CASE("read-only: the tools of a review role are only the ones that look and play") {
    CommandRegistry reg = roles_registry();
    const auto all = tool_names(tools_from_registry(reg, false));
    const auto ro = tool_names(tools_from_registry(reg, false, true));
    CHECK(contains(all, "scene_spawn"));
    CHECK_FALSE(contains(ro, "scene_spawn"));
    CHECK_FALSE(contains(ro, "fs_write"));
    CHECK_FALSE(contains(ro, "assets_generate_image"));
    for (const char* t : {"game_screenshot", "scene_list_entities", "game_step", "game_click", "scene_load"})
        CHECK_MESSAGE(contains(ro, t), t);
    // the orchestrator may delegate to the four roles, never to the critics
    const auto withDelegate = tools_from_registry(reg, true);
    for (const auto& t : withDelegate) {
        if (t.name != "agent_delegate") continue;
        const auto& en = t.inputSchema["properties"]["role"]["enum"];
        CHECK(en == Json::parse(R"(["worker","fast","artist","audio"])"));
    }
}

TEST_CASE("read-only: a reviewer run offers no editing tool and cannot call one either") {
    TempDir dir;
    CommandRegistry reg = roles_registry();
    auto provider = std::make_shared<FakeProvider>();
    ToolCall spawn;
    spawn.id = "t1";
    spawn.name = "scene_spawn";
    provider->script = {tool_response({spawn}), text_response("Done.\n```json\n{\"score\":6}\n```")};
    AiConfig cfg = default_config();
    SessionOptions so;
    so.projectDir = dir.str();
    so.role = kRoleReviewer;
    so.allowDelegation = false;
    AgentSession s(reg, cfg, so);
    s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    });
    auto r = s.run("review");
    REQUIRE(r.ok);
    REQUIRE(provider->requests.size() == 2);
    const auto offered = tool_names(provider->requests[0].tools);
    CHECK_FALSE(contains(offered, "scene_spawn"));
    CHECK_FALSE(contains(offered, "agent_delegate"));
    CHECK(contains(offered, "game_screenshot"));
    // the model called it anyway: refused, not run
    REQUIRE(provider->requests[1].messages.back().toolResults.size() == 1);
    CHECK(provider->requests[1].messages.back().toolResults[0].isError);
    CHECK(provider->requests[0].model == "claude-opus-5-5");
}

TEST_CASE("read-only: agent_delegate refuses the critics and the reviewers") {
    TempDir dir;
    CommandRegistry reg = roles_registry();
    auto provider = std::make_shared<FakeProvider>();
    ToolCall d;
    d.id = "d1";
    d.name = "agent_delegate";
    d.input = Json::object({{"role", "reviewer"}, {"task", "review the game"}});
    provider->script = {tool_response({d}), text_response("Ok, I will not.")};
    AiConfig cfg = default_config();
    SessionOptions so;
    so.projectDir = dir.str();
    AgentSession s(reg, cfg, so);
    s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    });
    REQUIRE(s.run("improve the game").ok);
    REQUIRE(provider->requests.size() == 2);  // no sub-session was started
    const auto& res = provider->requests[1].messages.back().toolResults[0];
    CHECK(res.isError);
    CHECK(res.content.find("not_delegable") != std::string::npos);
}

TEST_CASE("read-only: Claude Code is told which tools to switch off") {
    CommandRegistry reg = roles_registry();
    // The orchestrator: its own sub-agent tools are off (it delegates with ai_run), the reviews are not its to start.
    auto orch = cli_disallowed_tools(reg, kRoleOrchestrator, true);
    CHECK(contains(orch, "Agent"));
    CHECK(contains(orch, "Task"));
    CHECK(contains(orch, "mcp__factoria__ai_review"));
    CHECK_FALSE(contains(orch, "mcp__factoria__ai_run"));
    CHECK_FALSE(contains(orch, "Edit"));
    // A worker cannot delegate.
    CHECK(contains(cli_disallowed_tools(reg, kRoleWorker, false), "mcp__factoria__ai_run"));
    // A reviewer: nothing that edits.
    auto rev = cli_disallowed_tools(reg, kRoleReviewer, false);
    for (const char* t : {"Edit", "Write", "NotebookEdit", "Bash", "mcp__factoria__scene_spawn", "mcp__factoria__fs_write",
                          "mcp__factoria__assets_generate_image"})
        CHECK_MESSAGE(contains(rev, t), t);
    for (const char* t : {"mcp__factoria__game_step", "mcp__factoria__game_click", "mcp__factoria__scene_load",
                          "mcp__factoria__game_screenshot"})
        CHECK_MESSAGE(!(contains(rev, t)), t);
    CHECK(mcp_tool_name_for("assets.generate_image") == "assets_generate_image");
    CHECK(mcp_tool_name_for(std::string(100, 'a')).size() == 64);
}

TEST_CASE("review personas: five per role, the first is the all-rounder") {
    for (const char* role : {"artCritic", "reviewer"}) {
        const auto& p = review_personas(role);
        CHECK_MESSAGE(p.size() == static_cast<std::size_t>(kMaxReviewers), role);
        CHECK(p.front().name == "all-rounder");
        for (std::size_t i = 0; i < p.size(); ++i)
            for (std::size_t j = i + 1; j < p.size(); ++j) CHECK(p[i].name != p[j].name);
    }
    CHECK(review_role_for_kind("art") == "artCritic");
    CHECK(review_role_for_kind("game") == "reviewer");
    CHECK(review_role_for_kind("x").empty());
    CHECK(review_kind_for_role("reviewer") == "game");
}

TEST_CASE("review report: the last fenced json block is the score, the rest is the text") {
    auto p = parse_review_report("Good game.\n\nDo this next:\n1. fix the jump\n\n```json\n{\"score\": 7.5, \"subScores\": {\"fun\": 8, \"ux\": 6}, "
                                 "\"summary\": \"Fun but rough.\"}\n```\n");
    CHECK(p.score == doctest::Approx(7.5));
    CHECK(p.summary == "Fun but rough.");
    REQUIRE(p.subScores.size() == 2);
    CHECK(p.text.find("fix the jump") != std::string::npos);
    CHECK(p.text.find("subScores") == std::string::npos);
    CHECK(parse_review_report("```json\n{\"score\": 42}\n```").score == doctest::Approx(10));  // clamped
    CHECK(parse_review_report("```json\n{\"score\": -3}\n```").score == doctest::Approx(0));
    auto none = parse_review_report("No block here.");
    CHECK(none.score < 0);
    CHECK(none.text == "No block here.");
    auto twice = parse_review_report("```json\n{\"score\":1}\n```\ntext\n```json\n{\"score\":9}\n```");
    CHECK(twice.score == doctest::Approx(9));  // the last one counts
}

TEST_CASE("reviews are saved with their metadata and listed newest first") {
    TempDir dir;
    std::ofstream(dir.path / "factoria.json") << R"({"name":"space-dodge","version":"0.4.2"})";
    Review a;
    a.role = "reviewer";
    a.persona = "newcomer";
    a.text = "Confusing start.";
    a.score = 4.5;
    a.subScores = {{"ux", 3}, {"fun", 6}};
    a.summary = "Needs a tutorial.";
    auto saved = save_review(dir.str(), a);
    REQUIRE(saved);
    CHECK(std::filesystem::exists(saved->path));
    CHECK(saved->path.find(".factoria") != std::string::npos);
    CHECK(saved->path.find("reviews") != std::string::npos);
    CHECK(saved->path.find("-reviewer") != std::string::npos);
    CHECK(saved->gameVersion == "0.4.2");
    CHECK(saved->gameName == "space-dodge");
    CHECK_FALSE(saved->engineVersion.empty());
    CHECK_FALSE(saved->time.empty());
    // the same second, the same role: another file
    Review b = a;
    b.persona = "QA tester";
    b.score = 7;
    auto second = save_review(dir.str(), b);
    REQUIRE(second);
    CHECK(second->id != saved->id);
    Review art;
    art.role = "artCritic";
    art.score = 8;
    REQUIRE(save_review(dir.str(), art));

    auto all = list_reviews(dir.str());
    CHECK(all.size() == 3);
    auto game = list_reviews(dir.str(), "reviewer");
    CHECK(game.size() == 2);
    CHECK(list_reviews(dir.str(), "artCritic", 1).size() == 1);
    for (const auto& r : game) CHECK(r.role == "reviewer");
    auto it = std::find_if(game.begin(), game.end(), [&](const Review& r) { return r.id == saved->id; });
    REQUIRE(it != game.end());
    CHECK(it->score == doctest::Approx(4.5));
    CHECK(it->persona == "newcomer");
    CHECK(it->text == "Confusing start.");
    CHECK(it->subScores.size() == 2);
    // a file that is not a review is skipped
    std::ofstream(std::filesystem::path(reviews_dir(dir.str())) / "notes.json") << "[1]";
    CHECK(list_reviews(dir.str()).size() == 3);
    CHECK(list_reviews((dir.path / "nothing").string()).empty());
}

TEST_CASE("a review is handed to the orchestrator as a message, with the score and the report") {
    Review r;
    r.role = "artCritic";
    r.persona = "art director";
    r.score = 6;
    r.subScores = {{"direction", 7}};
    r.text = "The palette drifts between scenes.";
    const std::string m = review_as_message(r);
    CHECK(m.find("art critique") != std::string::npos);
    CHECK(m.find("art director") != std::string::npos);
    CHECK(m.find("6.0/10") != std::string::npos);
    CHECK(m.find("direction 7.0") != std::string::npos);
    CHECK(m.find("The palette drifts") != std::string::npos);
    Review g;
    g.role = "reviewer";
    CHECK(review_as_message(g).find("game review") != std::string::npos);
}

TEST_CASE("system prompts: every role has its section; reviewers read REVIEW.md first and are told they are read-only") {
    TempDir dir;
    std::ofstream(dir.path / "factoria.json") << R"({"name":"g"})";
    std::ofstream(dir.path / "REVIEW.md") << "# How to play\nArrows move. Press F9 for the debug menu.\n";
    auto prompt = [&](const char* role, bool delegate) { return build_system_prompt(PromptContext{dir.str(), role, delegate, ""}); };
    const std::string orch = prompt("orchestrator", true);
    CHECK(orch.find("artist") != std::string::npos);
    CHECK(orch.find("audio") != std::string::npos);
    CHECK(orch.find("REVIEW.md") != std::string::npos);  // it keeps the file up to date
    CHECK(orch.find("Agent") != std::string::npos);      // it is told its own sub-agent tools are off
    CHECK(orch.find("not yours to call") != std::string::npos);  // it is told the critics are the user's to start
    CHECK(prompt("worker", false).find("REVIEW.md") != std::string::npos);
    CHECK(prompt("artist", false).find("# Your role: artist") != std::string::npos);
    CHECK(prompt("audio", false).find("# Your role: audio") != std::string::npos);
    for (const char* role : {"artCritic", "reviewer"}) {
        const std::string p = prompt(role, false);
        CHECK_MESSAGE(p.find("READ-ONLY") != std::string::npos, role);
        CHECK_MESSAGE(p.find("Press F9 for the debug menu") != std::string::npos, role);  // REVIEW.md is in the prompt
        CHECK_MESSAGE(p.find("subScores") != std::string::npos, role);
    }
    TempDir bare;
    std::ofstream(bare.path / "factoria.json") << R"({"name":"g"})";
    const std::string noNote = build_system_prompt(PromptContext{bare.str(), "reviewer", false, ""});
    CHECK(noNote.find("REVIEW.md") != std::string::npos);  // says it is missing
}

TEST_CASE("ai.review runs the personas, saves each review and ai.reviews lists them; ai.run refuses the critics") {
    TempDir dir;
    std::ofstream(dir.path / "factoria.json") << R"({"name":"g","version":"1.0.0"})";
    CommandRegistry registry = roles_registry();
    auto provider = std::make_shared<FakeProvider>();
    provider->script = {
        text_response("Solid.\n```json\n{\"score\":8,\"subScores\":{\"fun\":9},\"summary\":\"Great.\"}\n```"),
        text_response("Too easy.\n```json\n{\"score\":6,\"summary\":\"Meh.\"}\n```"),
    };
    AiCommandOptions opt;
    opt.loadConfig = [] { return Result<AiConfig>(default_config()); };
    opt.projectDir = [&] { return dir.str(); };
    opt.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    };
    register_ai_commands(registry, opt);
    REQUIRE(registry.has("ai.review"));
    REQUIRE(registry.has("ai.reviews"));

    auto r = registry.call("ai.review", Json::object({{"kind", "game"}, {"count", 2}, {"focus", "the first level"}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["reviews"].size() == 2);
    CHECK(r.result["reviews"][0]["persona"] == "all-rounder");
    CHECK(r.result["reviews"][0]["score"] == 8);
    CHECK(r.result["reviews"][1]["score"] == 6);
    CHECK(r.result["averageScore"] == 7);
    CHECK(r.result["reviews"][0]["text"].get<std::string>().find("Solid.") != std::string::npos);
    REQUIRE(provider->requests.size() == 2);
    CHECK(provider->requests[0].system.find("all-rounder") != std::string::npos);
    CHECK(provider->requests[1].system.find("all-rounder") == std::string::npos);  // the second one has another persona
    CHECK(provider->requests[0].messages[0].text.find("the first level") != std::string::npos);
    for (const auto& req : provider->requests) {
        for (const auto& t : req.tools) CHECK(t.name != "scene_spawn");
    }

    auto list = registry.call("ai.reviews", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["reviews"].size() == 2);
    CHECK(list.result["reviews"][0].contains("score"));
    CHECK_FALSE(list.result["reviews"][0].contains("text"));
    auto withText = registry.call("ai.reviews", Json::object({{"kind", "game"}, {"includeText", true}, {"limit", 1}}));
    REQUIRE(withText.ok);
    REQUIRE(withText.result["reviews"].size() == 1);
    CHECK(withText.result["reviews"][0].contains("text"));
    CHECK(registry.call("ai.reviews", Json::object({{"kind", "art"}})).result["reviews"].empty());

    // critics are not delegable
    for (const char* role : {"reviewer", "artCritic"}) {
        auto bad = registry.call("ai.run", Json::object({{"task", "t"}, {"role", role}}));
        CHECK_FALSE(bad.ok);
        CHECK(bad.error["code"] == "invalid_arguments");  // the schema enum already refuses them
    }
    auto unknown = registry.call("ai.run", Json::object({{"task", "t"}, {"role", "wizard"}}));
    CHECK_FALSE(unknown.ok);
    CHECK(unknown.error["code"] == "invalid_arguments");
    CHECK_FALSE(registry.call("ai.review", Json::object({{"kind", "sound"}})).ok);
    // ai.providers lists all seven roles
    auto prov = registry.call("ai.providers", Json::object());
    REQUIRE(prov.ok);
    for (const char* role : kAllRoles) CHECK_MESSAGE(prov.result["roles"].contains(role), role);
}
