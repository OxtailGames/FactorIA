// The AI settings window's data: asset routes and asset sites in ai.json, how they reach the prompt and Claude Code's argv.
#include "fa/ai/assets.h"
#include "fa/ai/cli_agent.h"
#include "fa/core/fs.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {
bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }
}  // namespace

TEST_CASE("asset_site_host: a web address or a bare domain becomes the host; anything else is refused") {
    CHECK(asset_site_host("https://OpenGameArt.org/content/foo?a=1#b") == "opengameart.org");
    CHECK(asset_site_host("kenney.nl") == "kenney.nl");
    CHECK(asset_site_host("  http://www.freesound.org:8080/search ") == "www.freesound.org");
    CHECK(asset_site_host("github.com/KhronosGroup/glTF-Sample-Assets") == "github.com");
    CHECK(asset_site_host("user@fonts.google.com") == "fonts.google.com");
    CHECK(asset_site_host("localhost:3000") == "localhost");
    CHECK(asset_site_host("example.com.") == "example.com");
    for (const char* bad : {"", "   ", "not a site", "opengameart", "a..b", "-a.com", "a-.com", "http://", "://x.com", "exa$mple.com",
                            "host:port.com", "https:/x.com"})
        CHECK_MESSAGE(asset_site_host(bad).empty(), bad);
}

TEST_CASE("assetSources: the schema takes strings and objects and rejects typos; parse and config_to_json round trip") {
    const Json good = Json::parse(R"({"assetSources": {
        "images": [{"url": "https://opengameart.org", "note": "CC0 packs"}, "kenney.nl"],
        "models": ["poly.pizza"], "audio": [{"url": "freesound.org"}], "fonts": [], "onlyListed": true}})");
    CHECK(validate_config_json(good).empty());
    for (const char* bad : {R"({"assetSources": {"image": []}})", R"({"assetSources": {"images": [{"link": "x.com"}]}})",
                            R"({"assetSources": {"images": [{"url": ""}]}})", R"({"assetSources": {"onlyListed": "yes"}})",
                            R"({"assetSources": {"images": "kenney.nl"}})", R"({"assetSources": {"images": [3]}})"})
        CHECK_MESSAGE(!validate_config_json(Json::parse(bad)).empty(), bad);

    auto cfg = parse_config(good);
    REQUIRE(cfg);
    CHECK(cfg->assetSources.onlyListed);
    REQUIRE(cfg->assetSources.images.size() == 2);
    CHECK(cfg->assetSources.images[0].url == "https://opengameart.org");
    CHECK(cfg->assetSources.images[0].note == "CC0 packs");
    CHECK(cfg->assetSources.images[1].url == "kenney.nl");
    CHECK(cfg->assetSources.images[1].note.empty());
    CHECK(cfg->assetSources.models.size() == 1);
    CHECK(cfg->assetSources.audio.size() == 1);
    CHECK(cfg->assetSources.fonts.empty());
    CHECK(cfg->assetSources.other.empty());
    CHECK(asset_source_hosts(cfg->assetSources) == std::vector<std::string>{"opengameart.org", "kenney.nl", "poly.pizza", "freesound.org"});

    auto back = parse_config(config_to_json(*cfg));
    REQUIRE(back);
    CHECK(back->assetSources.onlyListed);
    CHECK(back->assetSources.images.size() == 2);
    CHECK(back->assetSources.images[0].note == "CC0 packs");

    // without the section: empty lists, not onlyListed, and nothing in the output
    AiConfig none = default_config();
    CHECK(none.assetSources.empty());
    CHECK_FALSE(none.assetSources.onlyListed);
    CHECK_FALSE(config_to_json(none).contains("assetSources"));
}

TEST_CASE("assetSources: an entry that is not a web address says where, why and how to fix it") {
    auto bad = parse_config(Json::parse(R"({"assetSources": {"audio": ["freesound.org", {"url": "not a site"}]}})"), "ai.json");
    REQUIRE_FALSE(bad);
    CHECK(has(bad.error().message, "ai.json"));
    CHECK(has(bad.error().message, "/assetSources/audio/1/url"));
    CHECK(has(bad.error().message, "'not a site' is not a web address"));
    CHECK(has(bad.error().hint, "opengameart.org"));
    auto asString = parse_config(Json::parse(R"({"assetSources": {"models": ["a b"]}})"), "ai.json");
    REQUIRE_FALSE(asString);
    CHECK(has(asString.error().message, "/assetSources/models/0:"));
}

TEST_CASE("save_asset_settings: rewrites assets and assetSources, keeps every other section and field") {
    TempDir dir;
    const std::string file = (dir.path / "ai.json").string();
    REQUIRE(fs::write_text(file, R"({
        "defaultProvider": "claude-code",
        "providers": {"openai": {"headers": {"X-Org": "me"}, "license": "my plan"}, "claude-code": {"command": "claude"}},
        "roles": {"worker": {"provider": "claude-code", "model": "opus", "maxTokens": 4000}},
        "limits": {"maxTurns": 7},
        "assets": {"image": {"provider": "fake"}, "sound": {"provider": "fake"}}
    })"));
    AssetSettings s;
    s.routes["image"] = {"openai", "gpt-image-1", ""};
    s.routes["voice"] = {"elevenlabs", "", "21m00Tcm4TlvDq8ikWAM"};  // "sound" is gone: the user chose None
    s.sources.images = {{"https://opengameart.org", "CC0 packs"}, {"kenney.nl", ""}};
    s.sources.fonts = {{"fonts.google.com", ""}};
    s.sources.onlyListed = true;
    REQUIRE(save_asset_settings(s, file));

    const Json j = Json::parse(*fs::read_text(file));
    CHECK(j["defaultProvider"] == "claude-code");
    CHECK(j["limits"] == Json::parse(R"({"maxTurns": 7})"));
    CHECK(j["roles"]["worker"]["maxTokens"] == 4000);
    CHECK(j["providers"]["openai"]["headers"]["X-Org"] == "me");
    CHECK(j["providers"]["openai"]["license"] == "my plan");
    CHECK(j["providers"]["claude-code"]["command"] == "claude");
    CHECK(j["assets"] == Json::parse(R"({"image": {"provider": "openai", "model": "gpt-image-1"},
                                        "voice": {"provider": "elevenlabs", "voice": "21m00Tcm4TlvDq8ikWAM"}})"));
    CHECK(j["assetSources"]["images"][0] == Json::parse(R"({"url": "https://opengameart.org", "note": "CC0 packs"})"));
    CHECK(j["assetSources"]["images"][1] == Json::parse(R"({"url": "kenney.nl"})"));
    CHECK(j["assetSources"]["onlyListed"] == true);
    CHECK_FALSE(j["assetSources"].contains("models"));
    CHECK(validate_config_json(j).empty());

    auto loaded = load_config(file);
    REQUIRE(loaded);
    CHECK(loaded->assets.at("image").model == "gpt-image-1");
    CHECK(loaded->assets.count("sound") == 0);
    CHECK(loaded->assetSources.onlyListed);
    CHECK(loaded->assetSources.fonts.size() == 1);
    CHECK(loaded->limits.maxTurns == 7);

    // an empty settings object takes both sections out and leaves the rest
    REQUIRE(save_asset_settings(AssetSettings{}, file));
    const Json cleared = Json::parse(*fs::read_text(file));
    CHECK_FALSE(cleared.contains("assets"));
    CHECK_FALSE(cleared.contains("assetSources"));
    CHECK(cleared["limits"]["maxTurns"] == 7);
}

TEST_CASE("save_asset_settings: creates the file, a key is written and removed, a local program gets its provider entry") {
    TempDir dir;
    const std::string file = (dir.path / "sub" / "ai.json").string();  // neither the folder nor the file exist
    AssetSettings s;
    s.routes["image"] = {"comfy", "", ""};
    AssetProviderEdit local;
    local.type = "asset-command";
    local.command = "python";
    local.argv = std::vector<std::string>{"txt2img.py", "--prompt", "{prompt}", "--out", "{output}"};
    s.providers["comfy"] = local;
    AssetProviderEdit key;
    key.apiKey = "sk-test-key-for-unit-tests-0123456789";
    s.providers["elevenlabs"] = key;
    REQUIRE(save_asset_settings(s, file));
    auto loaded = load_config(file);
    REQUIRE(loaded);
    const ProviderConfig* comfy = loaded->provider("comfy");
    REQUIRE(comfy);
    CHECK(comfy->kind == ProviderKind::AssetCommand);
    CHECK(comfy->command == "python");
    CHECK(comfy->argv.size() == 5);
    CHECK(loaded->provider("elevenlabs")->apiKey == "sk-test-key-for-unit-tests-0123456789");
    CHECK(resolve_api_key(*loaded->provider("elevenlabs"), fake_env({})).source == "config");
    REQUIRE(resolve_asset_target(*loaded, MediaKind::Image));
#ifndef _WIN32
    const auto perms = std::filesystem::status(file).permissions();
    CHECK((perms & (std::filesystem::perms::group_all | std::filesystem::perms::others_all)) == std::filesystem::perms::none);
    CHECK_FALSE(has(loaded->warnings.empty() ? std::string() : loaded->warnings[0], "readable by other users"));
#endif
    // the redacted view never shows it
    CHECK_FALSE(has(config_to_json(*loaded).dump(), "unit-tests"));

    // a later save that names no key leaves it; an empty key removes it, and the emptied provider entry goes away
    AssetSettings again;
    again.routes = s.routes;
    again.providers["comfy"] = AssetProviderEdit{};
    REQUIRE(save_asset_settings(again, file));
    CHECK(Json::parse(*fs::read_text(file))["providers"]["elevenlabs"]["apiKey"] == "sk-test-key-for-unit-tests-0123456789");
    AssetSettings remove;
    remove.routes = s.routes;
    AssetProviderEdit clear;
    clear.apiKey = "";
    remove.providers["elevenlabs"] = clear;
    REQUIRE(save_asset_settings(remove, file));
    const Json j = Json::parse(*fs::read_text(file));
    CHECK_FALSE(j["providers"].contains("elevenlabs"));
    CHECK(j["providers"].contains("comfy"));
}

TEST_CASE("save_asset_settings: a file that is not a JSON object is left alone") {
    TempDir dir;
    const std::string file = (dir.path / "ai.json").string();
    REQUIRE(fs::write_text(file, "[1, 2]"));
    CHECK_FALSE(save_asset_settings(AssetSettings{}, file));
    CHECK(*fs::read_text(file) == "[1, 2]");
    REQUIRE(fs::write_text(file, "{ not json"));
    CHECK_FALSE(save_asset_settings(AssetSettings{}, file));
    CHECK(*fs::read_text(file) == "{ not json");
}

TEST_CASE("asset_sources_prompt: the sites per category and the rule, with and without onlyListed") {
    AssetSources none;
    CHECK(asset_sources_prompt(none).empty());
    none.onlyListed = true;
    CHECK(asset_sources_prompt(none).empty());  // the box alone says nothing

    AssetSources s;
    s.images = {{"https://opengameart.org", "CC0 packs"}, {"kenney.nl", ""}};
    s.audio = {{"freesound.org", ""}};
    const std::string prefer = asset_sources_prompt(s);
    CHECK(has(prefer, "# Asset sources"));
    CHECK(has(prefer, "Images and textures:\n- https://opengameart.org (CC0 packs)\n- kenney.nl\n"));
    CHECK(has(prefer, "Audio (sounds and music):\n- freesound.org\n"));
    CHECK_FALSE(has(prefer, "3D models:"));
    CHECK(has(prefer, "prefer these sites"));
    CHECK(has(prefer, "search the rest of the internet"));
    CHECK_FALSE(has(prefer, "ONLY on these sites"));
    CHECK(has(prefer, "sourceUrl"));
    CHECK(has(prefer, "license"));

    s.onlyListed = true;
    const std::string only = asset_sources_prompt(s);
    CHECK(has(only, "ONLY on these sites"));
    CHECK(has(only, "Do not run a general web search"));
    CHECK_FALSE(has(only, "prefer these sites"));
    CHECK(has(only, "sourceUrl"));
}

TEST_CASE("build_system_prompt: the roles that bring assets in get the sites; the critics and reviewers do not; none configured = no section") {
    TempDir dir;
    std::ofstream(dir.path / "factoria.json") << R"({"name":"g"})";
    AssetSources s;
    s.models = {{"poly.pizza", ""}};
    s.onlyListed = true;
    for (const char* role : {"orchestrator", "worker", "fast", "artist", "audio"}) {
        PromptContext ctx{dir.str(), role, std::string(role) == "orchestrator", "", "", s};
        const std::string p = build_system_prompt(ctx);
        CHECK_MESSAGE(has(p, "3D models:\n- poly.pizza\n"), role);
        CHECK_MESSAGE(has(p, "ONLY on these sites"), role);
        PromptContext without{dir.str(), role, std::string(role) == "orchestrator"};
        CHECK_MESSAGE(!has(build_system_prompt(without), "Asset sources"), role);
    }
    for (const char* role : {"artCritic", "reviewer"}) {
        PromptContext ctx{dir.str(), role, false, "", "", s};
        CHECK_MESSAGE(!has(build_system_prompt(ctx), "Asset sources"), role);
    }
    // the section comes before the project context, so a long file list never pushes it out of view
    PromptContext ctx{dir.str(), "artist", false, "", "", s};
    const std::string p = build_system_prompt(ctx);
    CHECK(p.find("# Asset sources") < p.find("# Project context"));
}

TEST_CASE("Claude Code: the listed sites become WebFetch rules, onlyListed also switches WebSearch off") {
    CHECK(web_fetch_rules({"opengameart.org", "www.kenney.nl"}) ==
          std::vector<std::string>{"WebFetch(domain:opengameart.org)", "WebFetch(domain:www.opengameart.org)",
                                   "WebFetch(domain:www.kenney.nl)", "WebFetch(domain:kenney.nl)"});
    CHECK(web_fetch_rules({"a.com", "www.a.com"}).size() == 2);  // no duplicates
    CHECK(web_fetch_rules({}).empty());

    const std::vector<std::string> base = {"-p", "--allowedTools", "mcp__factoria", "--permission-mode", "acceptEdits"};
    CliRunRequest req{"x", "m", "/p"};
    req.disallowedTools = {"Agent", "Task"};
    req.webDomains = {"opengameart.org"};

    // the sites are allowed (in the --allowedTools list the argv already has); WebSearch stays available
    auto prefer = base;
    apply_role_restrictions(ProviderKind::ClaudeCode, true, req, prefer);
    CHECK(prefer == std::vector<std::string>{"-p", "--allowedTools",
                                             "mcp__factoria,WebFetch(domain:opengameart.org),WebFetch(domain:www.opengameart.org)",
                                             "--permission-mode", "acceptEdits", "--disallowedTools", "Agent,Task"});

    req.webOnlyListed = true;
    auto only = base;
    apply_role_restrictions(ProviderKind::ClaudeCode, true, req, only);
    CHECK(only.back() == "Agent,Task,WebSearch");
    CHECK(only[2] == "mcp__factoria,WebFetch(domain:opengameart.org),WebFetch(domain:www.opengameart.org)");

    // an argv without --allowedTools gets one; a flag in the last position is not mistaken for a value
    std::vector<std::string> bare = {"-p", "--allowedTools"};
    apply_role_restrictions(ProviderKind::ClaudeCode, true, req, bare);
    CHECK(bare.size() == 6);
    CHECK(bare[2] == "--disallowedTools");
    CHECK(bare[4] == "--allowedTools");
    CHECK(has(bare[5], "WebFetch(domain:opengameart.org)"));

    // onlyListed with no site (nothing to allow) does not switch WebSearch off; other CLIs are left alone
    CliRunRequest empty{"x", "m", "/p"};
    empty.webOnlyListed = true;
    auto untouched = base;
    apply_role_restrictions(ProviderKind::ClaudeCode, true, empty, untouched);
    CHECK(untouched == base);
    auto generic = base;
    apply_role_restrictions(ProviderKind::GenericCli, true, req, generic);
    CHECK(generic == base);
    auto codex = base;
    apply_role_restrictions(ProviderKind::Codex, true, req, codex);
    CHECK(codex == base);
}

TEST_CASE("assets.generate_*: the no_provider hint points at the editor's AI settings; asset_default_model names the defaults") {
    AiConfig cfg = default_config();
    auto target = resolve_asset_target(cfg, MediaKind::Image);
    REQUIRE_FALSE(target);
    CHECK(has(target.error().hint, "AI settings"));
    CHECK(has(target.error().hint, "\"assets\": {\"image\":"));  // ai.json is still named
    CHECK(asset_default_model(*cfg.provider("openai"), MediaKind::Image) == "gpt-image-1");
    CHECK(asset_default_model(*cfg.provider("openai"), MediaKind::Voice) == "gpt-4o-mini-tts");
    CHECK(asset_default_model(*cfg.provider("elevenlabs"), MediaKind::Sound) == "eleven_text_to_sound_v2");
    CHECK(asset_default_model(*cfg.provider("elevenlabs"), MediaKind::Music) == "music_v1");
    CHECK(asset_default_model(*cfg.provider("meshy"), MediaKind::Model3d) == "latest");
    CHECK(asset_default_model(*cfg.provider("fake"), MediaKind::Image).empty());
}

TEST_CASE("split_args and join_args round-trip the asset-command arguments line") {
    CHECK(split_args("--prompt {prompt} --out {output}") == std::vector<std::string>{"--prompt", "{prompt}", "--out", "{output}"});
    CHECK(split_args("  a   \"b c\" \"\" d\\e ") == std::vector<std::string>{"a", "b c", "", "d\\e"});
    CHECK(split_args("").empty());
    const std::vector<std::string> tricky{"plain", "with space", "", "quo\"te", "back\\slash", "{prompt}"};
    CHECK(split_args(join_args(tricky)) == tricky);
    CHECK(join_args({"a", "b c"}) == "a \"b c\"");
}
