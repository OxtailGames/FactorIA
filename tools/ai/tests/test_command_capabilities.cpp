// The capabilities every tools/ai command declares (capability.h), and what a scope of a role does with them.
#include <map>
#include <string>

#include "fa/ai/commands.h"
#include "fa/ai/skills.h"
#include "fa/core/command.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

struct World {
    TempDir proj;
    CommandRegistry reg;
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    World() {
        AiCommandOptions opt;
        opt.loadConfig = [] { return Result<AiConfig>(default_config()); };
        opt.runtime.env = fake_env({});
        opt.projectDir = [this] { return proj.str(); };
        opt.providerFactory = [this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        };
        register_ai_commands(reg, opt);
        SkillsCommandOptions so;
        so.loadConfig = opt.loadConfig;
        so.projectDir = opt.projectDir;
        so.env = opt.runtime.env;
        register_skills_commands(reg, so);
    }
};

using C = Capability;

}  // namespace

TEST_CASE("tools/ai commands: every one declares exactly the capabilities of what it does") {
    World w;
    const CapabilitySet reads{C::Read};
    const CapabilitySet writes{C::Read, C::WriteProject};
    const CapabilitySet generate{C::Read, C::WriteProject, C::Process, C::Network, C::Spend};
    const CapabilitySet agentRun{C::Read, C::WriteProject, C::Process, C::Network, C::Spend};
    const CapabilitySet imageEdit{C::Read, C::State, C::WriteProject, C::Process, C::Network, C::Spend};
    const std::map<std::string, CapabilitySet> expected = {
        {"ai.providers", {C::Read, C::Process}},
        {"ai.models", {C::Read, C::Process, C::Network}},
        {"ai.tool_servers", {C::Read, C::Process, C::Network}},
        {"ai.extensions", reads},
        {"ai.hooks", reads},
        {"ai.hooks_test", {C::Read, C::Process, C::Network, C::Spend}},
        {"ai.savers", reads},
        {"ai.saver_group", writes},
        {"ai.saver_fact", writes},
        {"ai.plugin_install", {C::Read, C::WriteAnywhere, C::Process, C::Network}},
        {"ai.run", agentRun},
        {"ai.review", agentRun},
        {"ai.review_feedback", generate},
        {"ai.reviews", reads},
        {"ai.session_timeline", reads},
        {"ai.retrospective", generate},
        {"ai.tool_plan", reads},
        {"ai.settings.get", reads},
        {"ai.settings.set", writes},
        {"assets.provenance", reads},
        {"assets.disclosure", reads},
        {"assets.generate_image", generate},
        {"assets.generate_sprite_sheet", generate},
        {"assets.generate_sound", generate},
        {"assets.generate_music", generate},
        {"assets.generate_voice", generate},
        {"assets.generate_model", generate},
        {"assets.pick", writes},
        {"assets.set_provenance", writes},
        {"assets.review", {C::Read, C::Process, C::Network, C::Spend}},
        {"vfx.review", {C::Read, C::State, C::Process, C::Network, C::Spend}},
        {"image.inpaint", imageEdit},
        {"image.generate_layer", imageEdit},
        {"skills.list", reads},
        {"skills.read", reads},
        {"skills.new", writes},
    };
    for (const auto& [name, caps] : expected) {
        CAPTURE(name);
        const CommandInfo* info = w.reg.info(name);
        // vfx.review and a few others register in the same call; every name here must exist
        REQUIRE(info != nullptr);
        CHECK_MESSAGE(info->capabilities == caps, name, ": declared ", info->capabilities.to_string(), ", expected ", caps.to_string());
    }
}

TEST_CASE("tools/ai commands: a {read, state} scope is refused ai.run and ai.settings.set, an agent scope is not") {
    World w;
    {
        CommandCallerScope caller(CommandCaller::Agent);
        CommandCapabilityScope caps(CapabilitySet{C::Read, C::State});
        const CommandResult run = w.reg.call("ai.run", Json::object({{"task", "code"}, {"role", "worker"}}));
        REQUIRE_FALSE(run.ok);
        CHECK(run.error["code"] == "capability_denied");
        const CommandResult set = w.reg.call("ai.settings.set", Json::object({{"scope", "project"}, {"pointer", "/limits/maxTurns"}, {"value", 20}}));
        REQUIRE_FALSE(set.ok);
        CHECK(set.error["code"] == "capability_denied");
        CHECK(w.provider->requests.empty());
        // reading commands still work
        CHECK(w.reg.call("ai.settings.get", Json::object({{"scope", "resolved"}})).ok);
    }
    {  // what the builder roles hold: ai.run starts a run, ai.plugin_install (writeAnywhere) stays with the user
        CommandCallerScope caller(CommandCaller::Agent);
        CommandCapabilityScope caps(role_capabilities(kRoleOrchestrator));
        w.provider->script = {text_response("done")};
        CHECK(w.reg.call("ai.run", Json::object({{"task", "code"}, {"role", "worker"}})).ok);
        const CommandResult install = w.reg.call("ai.plugin_install", Json::object({{"plugin", "x@y"}, {"dryRun", true}}));
        REQUIRE_FALSE(install.ok);
        CHECK(install.error["code"] == "capability_denied");
        const CommandResult user = w.reg.call("skills.new", Json::object({{"name", "enemy-design"}, {"scope", "user"}}));
        REQUIRE_FALSE(user.ok);
        CHECK(user.error["code"] == "capability_denied");
    }
}
