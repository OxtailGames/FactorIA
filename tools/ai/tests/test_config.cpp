#include "fa/ai/config.h"
#include "fa/ai/detect.h"
#include "fa/core/fs.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

TEST_CASE("default roles: Anthropic opus/sonnet/haiku with efforts") {
    AiConfig c = default_config();
    CHECK(c.role("orchestrator").model == "claude-opus-5-5");
    CHECK(c.role("orchestrator").effort == "xhigh");
    CHECK(c.role("worker").model == "claude-sonnet-5-5");
    CHECK(c.role("worker").effort == "medium");
    CHECK(c.role("fast").model == "claude-haiku-5-5");
    CHECK(c.role("fast").effort == "max");
    CHECK(c.role("worker").provider == "anthropic");
    for (const char* p : {"anthropic", "openai", "openrouter", "gemini", "groq", "deepseek", "ollama", "lmstudio", "claude-code", "codex"})
        CHECK_MESSAGE(c.provider(p) != nullptr, p);
}

TEST_CASE("config schema file validates the example and rejects typos with pointers") {
    Json example = fixture_json("ai_config_example.json");
    CHECK(validate_config_json(example).empty());
    // the embedded schema equals the file in schemas/
    std::string onDisk = read_file(std::string(FA_REPO_ROOT) + "/schemas/ai-config.schema.json");
    CHECK(Json::parse(std::string(config_schema_text())) == Json::parse(onDisk));

    Json bad = example;
    bad["roles"]["worker"]["effort"] = "ultra";
    bad["providers"]["local"]["baseUrll"] = "x";
    bad["limits"]["maxTurns"] = 0;
    auto errs = validate_config_json(bad);
    REQUIRE(errs.size() >= 3);
    std::string all;
    for (auto& e : errs) all += e.to_string() + "\n";
    CHECK(all.find("/roles/worker/effort") != std::string::npos);
    CHECK(all.find("/providers/local") != std::string::npos);
    CHECK(all.find("/limits/maxTurns") != std::string::npos);
    auto parsed = parse_config(bad, "ai.json");
    REQUIRE_FALSE(parsed.ok());
    CHECK(parsed.error().message.find("ai.json") != std::string::npos);
}

TEST_CASE("config parsing merges over defaults") {
    auto cfg = parse_config(fixture_json("ai_config_example.json"), "example");
    REQUIRE(cfg);
    CHECK(cfg->limits.maxTurns == 12);
    CHECK(cfg->limits.maxCostUsd == doctest::Approx(3.5));
    // orchestrator: only provider given => Anthropic default model/effort
    CHECK(cfg->role("orchestrator").model == "claude-opus-5-5");
    CHECK(cfg->role("orchestrator").effort == "xhigh");
    CHECK(cfg->role("worker").provider == "openrouter");
    CHECK(cfg->role("worker").model == "deepseek/deepseek-chat");
    CHECK(cfg->role("worker").maxTokens == 8000);
    CHECK(cfg->role("worker").effort.empty());
    CHECK(cfg->role("fast").provider == "local");
    CHECK(cfg->role("fast").model == "qwen");  // provider defaultModel
    const ProviderConfig* or_ = cfg->provider("openrouter");
    REQUIRE(or_);
    CHECK(or_->baseUrl == "https://openrouter.ai/api/v1");  // preset kept
    REQUIRE(or_->headers.size() == 1);
    CHECK(or_->headers[0].first == "HTTP-Referer");
    const ProviderConfig* agent = cfg->provider("my-agent");
    REQUIRE(agent);
    CHECK(agent->kind == ProviderKind::GenericCli);
    CHECK(agent->argv.size() == 4);
    CHECK(cfg->provider("anthropic")->apiKeyEnv == "MY_ANTHROPIC_KEY");
}

TEST_CASE("config errors: unknown role provider gets did-you-mean, custom provider needs type") {
    Json j = Json::parse(R"({"roles":{"worker":{"provider":"openrouterr"}}})");
    auto r = parse_config(j, "x");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/roles/worker/provider") != std::string::npos);
    CHECK(r.error().hint.find("openrouter") != std::string::npos);
    auto t = parse_config(Json::parse(R"({"providers":{"mine":{"baseUrl":"http://x/v1"}}})"), "x");
    REQUIRE_FALSE(t.ok());
    CHECK(t.error().message.find("needs a \"type\"") != std::string::npos);
}

TEST_CASE("non-Anthropic default provider gets placeholder models") {
    auto cfg = parse_config(Json::parse(R"({"defaultProvider":"openrouter"})"), "x");
    REQUIRE(cfg);
    CHECK(cfg->role("worker").provider == "openrouter");
    CHECK(cfg->role("worker").model == "CHANGE_ME");
    CHECK(cfg->role("worker").effort.empty());
}

TEST_CASE("API key resolution: apiKeyEnv > apiKey > conventional env; never empty strings") {
    ProviderConfig p = default_config().providers["openai"];
    CHECK_FALSE(resolve_api_key(p, fake_env({})).found());
    auto k1 = resolve_api_key(p, fake_env({{"OPENAI_API_KEY", "env-key"}}));
    CHECK(k1.key == "env-key");
    CHECK(k1.source == "env:OPENAI_API_KEY");
    auto fromFile = parse_config(Json::parse(R"({"providers":{"openai":{"apiKey":"file-key"}}})"), "x");
    REQUIRE(fromFile);
    p = *fromFile->provider("openai");
    CHECK(resolve_api_key(p, fake_env({{"OPENAI_API_KEY", "env-key"}})).key == "file-key");  // config beats implicit env
    CHECK(resolve_api_key(p, fake_env({{"OPENAI_API_KEY", "env-key"}})).source == "config");
    p.apiKeyEnv = "CUSTOM_KEY";
    CHECK(resolve_api_key(p, fake_env({{"CUSTOM_KEY", "custom"}, {"OPENAI_API_KEY", "x"}})).key == "custom");
    CHECK(resolve_api_key(p, fake_env({{"CUSTOM_KEY", ""}})).key == "file-key");

    ProviderConfig a = default_config().providers["anthropic"];
    CHECK(resolve_api_key(a, fake_env({{"ANTHROPIC_API_KEY", "a"}})).key == "a");
    CHECK(resolve_api_key(default_config().providers["gemini"], fake_env({{"GEMINI_API_KEY", "g"}})).key == "g");
    CHECK(resolve_api_key(default_config().providers["openrouter"], fake_env({{"OPENROUTER_API_KEY", "o"}})).key == "o");
}

TEST_CASE("config path: FACTORIA_AI_CONFIG override and home default") {
    CHECK(default_config_path(fake_env({{"FACTORIA_AI_CONFIG", "/tmp/x.json"}, {"HOME", "/home/u"}})) == "/tmp/x.json");
#ifndef _WIN32
    CHECK(default_config_path(fake_env({{"HOME", "/home/u"}})) == "/home/u/.factoria/ai.json");
#endif
}

TEST_CASE("load_config: missing file gives defaults, bad JSON gives location") {
    TempDir dir;
    auto none = load_config((dir.path / "nope.json").string());
    REQUIRE(none);
    CHECK(none->sourcePath.empty());
    CHECK(none->role("worker").model == "claude-sonnet-5-5");

    auto file = dir.path / "ai.json";
    std::ofstream(file) << "{ \"roles\": { \"worker\": { \"model\": \"m\" } ";
    auto bad = load_config(file.string());
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("ai.json") != std::string::npos);

    std::ofstream(file, std::ios::trunc) << R"({"roles":{"worker":{"model":"claude-sonnet-5-5","effort":"high"}}})";
    auto good = load_config(file.string());
    REQUIRE(good);
    CHECK(good->role("worker").effort == "high");
    CHECK(good->sourcePath == file.string());
}

TEST_CASE("save_config round trip") {
    TempDir dir;
    auto cfg = parse_config(fixture_json("ai_config_example.json"), "x");
    REQUIRE(cfg);
    auto file = (dir.path / "sub" / "ai.json").string();
    REQUIRE(save_config(*cfg, file));
    auto back = load_config(file);
    REQUIRE(back);
    CHECK(back->role("worker").model == "deepseek/deepseek-chat");
    CHECK(back->provider("groq")->apiKey == "gsk_example_not_real_key_value_12345");
    CHECK(config_to_json(*cfg)["providers"]["groq"]["apiKey"] == "***");  // redacted by default
}

TEST_CASE("save_roles changes only the roles and keeps the rest of the file") {
    TempDir dir;
    const std::string file = (dir.path / "ai.json").string();
    std::ofstream(file) << R"({"providers":{"claude-code":{"unsetEnv":["ANTHROPIC_API_KEY"]}},
        "roles":{"worker":{"provider":"anthropic","model":"old","maxTokens":8000}},"limits":{"maxTurns":7}})";
    std::map<std::string, RoleConfig> roles;
    roles["orchestrator"] = {"claude-code", "opus", "", 0, 400000};
    roles["worker"] = {"claude-code", "sonnet", "high", 0};
    roles["fast"] = {"anthropic", "", "", 0};  // no model: the role's default
    REQUIRE(save_roles(roles, file));
    Json j = Json::parse(*fs::read_text(file));
    CHECK(j["providers"]["claude-code"]["unsetEnv"][0] == "ANTHROPIC_API_KEY");
    CHECK(j["limits"]["maxTurns"] == 7);
    CHECK(j["roles"]["worker"]["maxTokens"] == 8000);
    CHECK_FALSE(j["roles"]["fast"].contains("model"));
    auto cfg = load_config(file);
    REQUIRE(cfg);
    CHECK(cfg->role("orchestrator").provider == "claude-code");
    CHECK(cfg->role("orchestrator").model == "opus");
    CHECK(cfg->role("orchestrator").maxContextTokens == 400000);
    CHECK_FALSE(j["roles"]["worker"].contains("maxContextTokens"));  // 0 = the model's whole window: no key
    CHECK_FALSE(validate_config_json(Json::parse(R"({"roles":{"worker":{"maxContextTokens":5000}}})")).empty());
    CHECK(cfg->role("worker").model == "sonnet");
    CHECK(cfg->role("worker").effort == "high");
    CHECK(cfg->role("fast").model == "claude-haiku-5-5");

    REQUIRE(save_roles(roles, (dir.path / "new" / "ai.json").string()));  // no file yet: created
    std::ofstream(file, std::ios::trunc) << "[1, 2]";
    CHECK_FALSE(save_roles(roles, file));
    CHECK(*fs::read_text(file) == "[1, 2]");  // not an object: left alone
}

TEST_CASE("project key scanning warns, ignores .git/.factoria and short strings") {
    TempDir dir;
    std::filesystem::create_directories(dir.path / "scripts");
    std::filesystem::create_directories(dir.path / ".factoria");
    std::ofstream(dir.path / "scripts" / "a.js") << "const k = 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz';\n";
    std::ofstream(dir.path / "notes.md") << "use sk-ant- keys carefully\n";           // too short: not a key
    std::ofstream(dir.path / ".factoria" / "x.json") << "sk-ant-api03-abcdefghijklmnopqrstuvwxyz";
    auto w = scan_project_for_keys(dir.str());
    REQUIRE(w.size() == 1);
    CHECK(w[0].find("scripts/a.js:1") != std::string::npos);
    CHECK(looks_like_api_key("key=AIzaSyA-1234567890abcdefghijklmnopqrstuv"));
    CHECK(looks_like_api_key("gsk_abcdefghijklmnopqrstuvwxyz"));
    CHECK_FALSE(looks_like_api_key("task-manager-description-long-enough-words"));
}

TEST_CASE("detect_providers with injected environment") {
    AiConfig cfg = default_config();
    DetectOptions o;
    o.env = fake_env({{"OPENAI_API_KEY", "k"}});
    o.which = [](const std::string& n) { return n == "claude" ? std::string("/usr/bin/claude") : std::string(); };
    o.version = [](const std::string&) { return std::string("2.0.0 (Claude Code)"); };
    auto st = detect_providers(cfg, o);
    auto find = [&](const std::string& n) -> const ProviderStatus& {
        for (auto& s : st) if (s.name == n) return s;
        FAIL("no status for " << n);
        return st[0];
    };
    CHECK(find("claude-code").available);
    CHECK(find("claude-code").version == "2.0.0 (Claude Code)");
    CHECK_FALSE(find("codex").available);
    CHECK(find("codex").hint.find("npm i -g @openai/codex") != std::string::npos);
    CHECK(find("openai").available);
    CHECK(find("openai").keySource == "env:OPENAI_API_KEY");
    CHECK_FALSE(find("anthropic").available);
    CHECK(find("anthropic").hint.find("ANTHROPIC_API_KEY") != std::string::npos);
    CHECK(find("ollama").available);  // local, no key
    o.which = [](const std::string& n) { return n == "ant" ? std::string("/usr/bin/ant") : std::string(); };
    auto st2 = detect_providers(cfg, o);
    for (auto& s : st2) if (s.name == "anthropic") { CHECK(s.available); CHECK(s.keySource == "ant-cli"); }
    CHECK(format_doctor_report(cfg, st2).find("orchestrator") != std::string::npos);
}
