#include <algorithm>
#include <atomic>
#include <chrono>
#include <filesystem>
#include <optional>
#include <thread>

#include "fa/ai/cli_agent.h"
#include "fa/ai/config.h"
#include "fa/ai/extensions.h"
#include "fa/core/fs.h"
#include "fa/tooling/feedback_share.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {
using V = std::vector<std::string>;

V claude_base() { return {"-p", "--model", "m", "--allowedTools", "mcp__factoria"}; }
V codex_base() { return {"exec", "--json", "-m", "gpt-x", "-c", "mcp_servers.factoria.args=[\"mcp\",\"--project\",\"/p\"]", "-"}; }

V run_mode(ProviderKind kind, bool builtIn, const std::string& mode, bool readOnly, V argv) {
    apply_permission_mode(kind, builtIn, mode, readOnly, argv);
    CliRunRequest req{"x", "m", "/p"};
    req.readOnly = readOnly;
    apply_role_restrictions(kind, builtIn, req, argv);
    return argv;
}
}  // namespace

TEST_CASE("permissionMode: read, written back, defaults per kind, and the table of what each value allows") {
    // Nothing written: the kind's default, no key in the file.
    AiConfig def = default_config();
    CHECK(def.provider("claude-code")->permissionMode.empty());
    CHECK(effective_permission_mode(*def.provider("claude-code")) == "acceptEdits");
    CHECK(effective_permission_mode(*def.provider("codex")) == "default");
    CHECK(effective_permission_mode(*def.provider("anthropic")).empty());
    CHECK_FALSE(config_to_json(def)["providers"]["claude-code"].contains("permissionMode"));

    const Json j = Json::parse(
        R"({"providers": {"claude-code": {"permissionMode": "plan"}, "codex": {"permissionMode": "workspace-write"}}})");
    CHECK(validate_config_json(j).empty());
    auto cfg = parse_config(j, "ai.json");
    REQUIRE(cfg);
    CHECK(effective_permission_mode(*cfg->provider("claude-code")) == "plan");
    CHECK(effective_permission_mode(*cfg->provider("codex")) == "workspace-write");
    const Json back = config_to_json(*cfg);
    CHECK(back["providers"]["claude-code"]["permissionMode"] == "plan");
    CHECK(back["providers"]["codex"]["permissionMode"] == "workspace-write");
    auto again = parse_config(back, "again");
    REQUIRE(again);
    CHECK(again->provider("codex")->permissionMode == "workspace-write");

    // Every value has a line that says what it allows; the default is one of the values; the dangerous one is marked.
    for (ProviderKind k : {ProviderKind::ClaudeCode, ProviderKind::Codex}) {
        const auto modes = permission_modes(k);
        REQUIRE_FALSE(modes.empty());
        bool hasDefault = false;
        int dangerous = 0;
        for (const PermissionMode& m : modes) {
            CHECK(std::string(m.allows).size() > 20);
            hasDefault = hasDefault || default_permission_mode(k) == m.value;
            dangerous += m.dangerous ? 1 : 0;
            CHECK(m.dangerous == (std::string(m.value) == "bypassPermissions" || std::string(m.value) == "danger-full-access"));
        }
        CHECK(hasDefault);
        CHECK(dangerous == 1);
    }
    CHECK(permission_modes(ProviderKind::GenericCli).empty());
}

TEST_CASE("permissionMode: an unknown value or a provider without modes is an error with its JSON pointer and a fix") {
    auto bad = parse_config(Json::parse(R"({"providers": {"claude-code": {"permissionMode": "acceptEdit"}}})"), "ai.json");
    REQUIRE_FALSE(bad.ok());
    // the schema (checked first) already names the pointer and suggests
    const std::string all = bad.error().message + " " + bad.error().hint;
    CHECK(all.find("/providers/claude-code/permissionMode") != std::string::npos);
    CHECK(all.find("Did you mean 'acceptEdits'") != std::string::npos);
    CHECK(all.find("bypassPermissions") != std::string::npos);  // the choices are listed
    // a Claude Code value is not a Codex one
    auto wrong = parse_config(Json::parse(R"({"providers": {"codex": {"permissionMode": "acceptEdits"}}})"), "ai.json");
    REQUIRE_FALSE(wrong.ok());
    CHECK(wrong.error().message.find("/providers/codex/permissionMode") != std::string::npos);
    CHECK_FALSE(parse_config(Json::parse(R"({"providers": {"codex": {"permissionMode": 3}}})"), "ai.json").ok());
    auto generic = parse_config(
        Json::parse(R"({"providers": {"mine": {"type": "generic-cli", "command": "x", "permissionMode": "plan"}}})"), "ai.json");
    REQUIRE_FALSE(generic.ok());
    CHECK(generic.error().message.find("/providers/mine/permissionMode") != std::string::npos);
    CHECK(generic.error().message.find("only claude-code and codex") != std::string::npos);
    // the schema rejects it too
    CHECK_FALSE(validate_config_json(Json::parse(R"({"providers": {"claude-code": {"permissionMode": "everything"}}})")).empty());
}

TEST_CASE("save_provider_permission_mode: writes one key, keeps the rest, refuses a bad value and leaves the file alone") {
    TempDir dir;
    const std::string path = (dir.path / "ai.json").string();
    REQUIRE(fs::write_text(path, R"({"defaultProvider": "claude-code", "inheritEnv": ["AWS_PROFILE"]})").ok());
    REQUIRE(save_provider_permission_mode("claude-code", "plan", path).ok());
    auto cfg = load_config(path);
    REQUIRE(cfg);
    CHECK(cfg->provider("claude-code")->permissionMode == "plan");
    CHECK(cfg->defaultProvider == "claude-code");
    CHECK(cfg->inheritEnv == std::vector<std::string>{"AWS_PROFILE"});
    const std::string before = read_file(path);
    auto badMode = save_provider_permission_mode("claude-code", "danger-full-access", path);
    REQUIRE_FALSE(badMode.ok());
    CHECK(badMode.error().message.find("/providers/claude-code/permissionMode") != std::string::npos);
    CHECK(read_file(path) == before);
    CHECK_FALSE(save_provider_permission_mode("anthropic", "plan", path).ok());
    CHECK(read_file(path) == before);
    // an empty provider name, and a provider the configuration does not have (also with the default mode), teach and change nothing
    auto noName = save_provider_permission_mode("", "plan", path);
    REQUIRE_FALSE(noName.ok());
    CHECK(noName.error().message.find("empty") != std::string::npos);
    CHECK_FALSE(noName.error().hint.empty());
    auto noProvider = save_provider_permission_mode("claude-cod", "", path);
    REQUIRE_FALSE(noProvider.ok());
    CHECK(noProvider.error().message.find("claude-cod") != std::string::npos);
    CHECK(noProvider.error().hint.find("claude-code") != std::string::npos);  // did you mean
    CHECK(read_file(path) == before);
    // an empty mode removes the key and the entry it leaves empty
    REQUIRE(save_provider_permission_mode("claude-code", "", path).ok());
    CHECK_FALSE(Json::parse(read_file(path)).contains("providers"));
}

TEST_CASE("parse_env_names: '*' alone and any whitespace are refused with a teaching error") {
    auto star = parse_env_names(Json::parse(R"(["*"])"), "ai.json: /inheritEnv");
    REQUIRE_FALSE(star.ok());
    CHECK(star.error().message.find("/inheritEnv/0") != std::string::npos);
    CHECK(star.error().message.find("every variable") != std::string::npos);
    CHECK(star.error().hint.find("AWS_*") != std::string::npos);
    for (const char* bad : {R"(["A\tB"])", R"(["A\nB"])", R"([" A"])", R"(["A\u000bB"])", R"(["A\u000cB"])"}) {
        INFO(bad);
        CHECK_FALSE(parse_env_names(Json::parse(bad), "x").ok());
    }
    auto ok = parse_env_names(Json::parse(R"(["AWS_*", "HOME", "HOME"])"), "x");
    REQUIRE(ok);
    CHECK(*ok == std::vector<std::string>{"AWS_*", "HOME"});
}

TEST_CASE("apply_permission_mode: Claude Code gets the mode, the default when none, and a read-only role never runs loose") {
    // Built-in argv: always one flag; the default is what FactorIA always passed.
    CHECK(run_mode(ProviderKind::ClaudeCode, true, "", false, claude_base()) ==
          V{"-p", "--model", "m", "--allowedTools", "mcp__factoria", "--permission-mode", "acceptEdits"});
    for (const PermissionMode& m : permission_modes(ProviderKind::ClaudeCode)) {
        INFO(m.value);
        const V argv = run_mode(ProviderKind::ClaudeCode, true, m.value, false, claude_base());
        REQUIRE(argv.size() == 7);
        CHECK(argv[5] == "--permission-mode");
        CHECK(argv[6] == m.value);
    }
    // A read-only role: bypassPermissions and auto become acceptEdits (its edit tools are off), the stricter ones stay.
    CHECK(run_mode(ProviderKind::ClaudeCode, true, "bypassPermissions", true, claude_base()).back() == "acceptEdits");
    CHECK(run_mode(ProviderKind::ClaudeCode, true, "auto", true, claude_base()).back() == "acceptEdits");
    CHECK(run_mode(ProviderKind::ClaudeCode, true, "plan", true, claude_base()).back() == "plan");
    CHECK(run_mode(ProviderKind::ClaudeCode, true, "manual", true, claude_base()).back() == "manual");
    // A user template: untouched unless the provider names a mode.
    CHECK(run_mode(ProviderKind::ClaudeCode, false, "", false, claude_base()) == claude_base());
    CHECK(run_mode(ProviderKind::ClaudeCode, false, "plan", false, claude_base()).back() == "plan");
    // ...and a permission flag of its own wins, with no second flag.
    for (const V& own : {V{"-p", "--permission-mode", "dontAsk"}, V{"-p", "--permission-mode=plan"},
                         V{"-p", "--dangerously-skip-permissions"}}) {
        INFO(own[1]);
        CHECK(run_mode(ProviderKind::ClaudeCode, false, "bypassPermissions", false, own) == own);
        CHECK(run_mode(ProviderKind::ClaudeCode, false, "plan", true, own) == own);
    }
    // Other CLIs are left alone.
    CHECK(run_mode(ProviderKind::GenericCli, false, "plan", false, claude_base()) == claude_base());
}

TEST_CASE("apply_permission_mode: Codex gets --sandbox before the stdin marker, none for default, read-only for a read-only role") {
    CHECK(run_mode(ProviderKind::Codex, true, "", false, codex_base()) == codex_base());  // today's argv: no flag
    CHECK(run_mode(ProviderKind::Codex, true, "default", false, codex_base()) == codex_base());
    for (const char* mode : {"read-only", "workspace-write", "danger-full-access"}) {
        INFO(mode);
        const V argv = run_mode(ProviderKind::Codex, true, mode, false, codex_base());
        REQUIRE(argv.size() == codex_base().size() + 2);
        CHECK(argv[argv.size() - 3] == "--sandbox");
        CHECK(argv[argv.size() - 2] == mode);
        CHECK(argv.back() == "-");
    }
    // A read-only role gets the read-only sandbox once, whatever the mode, and the read-only FactorIA server.
    for (const char* mode : {"", "default", "workspace-write", "danger-full-access"}) {
        INFO(mode);
        const V argv = run_mode(ProviderKind::Codex, true, mode, true, codex_base());
        CHECK(std::count(argv.begin(), argv.end(), "--sandbox") == 1);
        CHECK(std::find(argv.begin(), argv.end(), "read-only") != argv.end());
        CHECK(std::find(argv.begin(), argv.end(), "workspace-write") == argv.end());
        CHECK(std::find(argv.begin(), argv.end(), "danger-full-access") == argv.end());
        CHECK(argv[3] == "gpt-x");
        CHECK(argv[5].find("\"--read-only\"") != std::string::npos);
    }
    // A user template: only when the provider names a mode; its own sandbox flag wins.
    const V own = {"exec", "--sandbox", "workspace-write", "-"};
    CHECK(run_mode(ProviderKind::Codex, false, "", false, own) == own);
    CHECK(run_mode(ProviderKind::Codex, false, "danger-full-access", false, own) == own);
    CHECK(run_mode(ProviderKind::Codex, false, "danger-full-access", true, own) == own);
    for (const V& other : {V{"exec", "-s", "read-only", "-"}, V{"exec", "--full-auto", "-"},
                           V{"exec", "--dangerously-bypass-approvals-and-sandbox", "-"},
                           V{"exec", "-c", "sandbox_mode=\"workspace-write\"", "-"}}) {
        INFO(other[1]);
        CHECK(run_mode(ProviderKind::Codex, false, "danger-full-access", false, other) == other);
    }
    const V bare = {"exec", "-"};
    CHECK(run_mode(ProviderKind::Codex, false, "", false, bare) == bare);
    CHECK(run_mode(ProviderKind::Codex, false, "workspace-write", false, bare) == V{"exec", "--sandbox", "workspace-write", "-"});
}

#ifndef _WIN32  // the fake CLIs are shell scripts (fake_codex has no .cmd twin)
TEST_CASE("permission mode reaches the program: the CLI is started with the mode of its provider") {
    TempDir dir, scratch;
    auto argv_of = [&](ProviderConfig cfg, const char* script_name, bool readOnly) {
        const std::string argvFile = (scratch.path / (std::string(script_name) + std::to_string(readOnly) + ".txt")).string();
        std::error_code ec;
        std::filesystem::remove(argvFile, ec);
        cfg.command = std::string(FA_AI_FIXTURES) + "/" + script_name;
        cfg.env["FAKE_ARGV_FILE"] = argvFile;
        CliRunRequest req{"Do it", "m", dir.str()};
        req.readOnly = readOnly;
        auto r = CliAgent(cfg).run(req, [](const AgentEvent&) {}, nullptr);
        REQUIRE(r);
        return read_file(argvFile);
    };
    ProviderConfig claude = default_config().providers["claude-code"];
    CHECK(argv_of(claude, "fake_claude.sh", false).find("--permission-mode\nacceptEdits\n") != std::string::npos);
    claude.permissionMode = "plan";
    const std::string plan = argv_of(claude, "fake_claude.sh", false);
    CHECK(plan.find("--permission-mode\nplan\n") != std::string::npos);
    CHECK(plan.find("acceptEdits") == std::string::npos);
    claude.permissionMode = "bypassPermissions";
    CHECK(argv_of(claude, "fake_claude.sh", false).find("--permission-mode\nbypassPermissions\n") != std::string::npos);
    CHECK(argv_of(claude, "fake_claude.sh", true).find("--permission-mode\nacceptEdits\n") != std::string::npos);

    ProviderConfig codex = default_config().providers["codex"];
    CHECK(argv_of(codex, "fake_codex.sh", false).find("--sandbox") == std::string::npos);
    codex.permissionMode = "workspace-write";
    CHECK(argv_of(codex, "fake_codex.sh", false).find("--sandbox\nworkspace-write\n") != std::string::npos);
    const std::string ro = argv_of(codex, "fake_codex.sh", true);
    CHECK(ro.find("--sandbox\nread-only\n") != std::string::npos);
    CHECK(ro.find("\n-\nstdin:") != std::string::npos);  // the last argument is `-`: the prompt comes through stdin
    CHECK(ro.find("workspace-write") == std::string::npos);
}
#endif

TEST_CASE("saving ai.json waits for the lock of its folder and, when another program keeps it, changes nothing and says why") {
    TempDir dir;
    const std::string path = (dir.path / "ai.json").string();
    REQUIRE(fs::write_text(path, R"({"defaultProvider": "claude-code"})").ok());
    const std::string before = read_file(path);
    {
        ShareEnv env = share_env();
        env.lockWaitSec = 0.05;  // a busy lock is reported after this long
        ScopedShareEnv scoped(env);
        // `ready` says the thread went through the lock, `held` that it got it: a thread that did not get it still ends.
        std::atomic<bool> ready{false}, held{false}, release{false};
        // The lock belongs to the thread that took it: this one stands for another program.
        std::thread other([&] {
            ShareLock lock(share_env(), dir.path, -1, "ai-config.lock");
            held = lock.held();
            ready = true;
            while (held && !release) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        });
        while (!ready) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        const bool otherHolds = held;
        std::optional<Result<void>> busy, busyRoles, busyTrust;
        if (otherHolds) {
            busy = save_provider_permission_mode("claude-code", "plan", path);
            busyRoles = save_roles({}, path);
            busyTrust = trust_project_ai_settings(extensions_trust_path(path), dir.str(), "abc");
        }
        release = true;
        other.join();
        REQUIRE(otherHolds);
        REQUIRE_FALSE(busy->ok());
        CHECK(busy->error().message.find("Cannot save") != std::string::npos);
        CHECK(busy->error().message.find("ai-config.lock") != std::string::npos);
        CHECK(busy->error().message.find("sharing files") == std::string::npos);
        CHECK(busy->error().hint.find("Try again") != std::string::npos);
        CHECK(busy->error().hint.find("10 s") != std::string::npos);
        CHECK_FALSE(busyRoles->ok());
        CHECK_FALSE(busyTrust->ok());  // the trust file is saved under the same lock
        CHECK(read_file(path) == before);
        CHECK_FALSE(std::filesystem::exists(dir.path / "ai-trust.json"));
    }
    // the lock is free again (the test's short wait is gone too): the same save works, and leaves no lock file behind
    REQUIRE(save_provider_permission_mode("claude-code", "plan", path).ok());
    CHECK(Json::parse(read_file(path))["providers"]["claude-code"]["permissionMode"] == "plan");
    REQUIRE(trust_project_ai_settings(extensions_trust_path(path), dir.str(), "abc").ok());
    CHECK(std::filesystem::exists(dir.path / "ai-trust.json"));
    CHECK_FALSE(std::filesystem::exists(dir.path / "ai-config.lock"));
    CHECK_FALSE(std::filesystem::exists(dir.path / "feedback-share.lock"));  // the feedback sharing's lock is another file
}
