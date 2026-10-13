#include "fa/ai/commands.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

TEST_CASE("ai.providers and ai.run commands") {
    TempDir dir;
    CommandRegistry registry = make_registry();
    auto provider = std::make_shared<FakeProvider>();
    provider->script = {text_response("Task finished.")};
    std::ofstream(dir.path / "leak.js") << "const k='sk-ant-api03-abcdefghijklmnopqrstuvwxyz';\n";

    AiCommandOptions opt;
    opt.loadConfig = [] { return Result<AiConfig>(default_config()); };
    opt.projectDir = [&] { return dir.str(); };
    opt.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    };
    register_ai_commands(registry, opt);
    REQUIRE(registry.has("ai.providers"));
    REQUIRE(registry.has("ai.run"));

    auto list = registry.call("ai.providers", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["roles"]["orchestrator"]["model"] == "claude-opus-5-5");
    CHECK(list.result["providers"].size() >= 10);

    auto doctor = registry.call("ai.providers", Json::object({{"action", "doctor"}}));
    REQUIRE(doctor.ok);
    CHECK(doctor.result["report"].get<std::string>().find("Roles:") != std::string::npos);

    // the key never appears in the report
    CHECK(doctor.result.dump().find("sk-ant") == std::string::npos);

    auto run = registry.call("ai.run", Json::object({{"task", "Do something"}, {"role", "worker"}}));
    REQUIRE(run.ok);
    CHECK(run.result["finalText"] == "Task finished.");
    CHECK(provider->requests[0].model == "claude-sonnet-5-5");
    bool warned = false;
    for (auto& w : run.result["warnings"]) warned = warned || w.get<std::string>().find("leak.js:1") != std::string::npos;
    CHECK(warned);
    for (auto& t : provider->requests[0].tools) CHECK(t.name != "ai_run");  // no recursion

    provider->script = {text_response("x", StopReason::Refusal)};
    provider->calls = 0;
    auto bad = registry.call("ai.run", Json::object({{"task", "t"}}));
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["code"] == "refusal");

    auto invalid = registry.call("ai.run", Json::object({{"role", "orchestrator"}}));
    CHECK_FALSE(invalid.ok);  // task is required
}
