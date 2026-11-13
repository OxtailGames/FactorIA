// What a command run by `fa.call` may do (capability.h): the set a game script, the editor's Play and a test get, and the hint of
// the refusal that says where that caller gets more. docs/SCRIPTING.md, "What fa.call can do", docs/ARCHITECTURE.md, "Capabilities".
#include <string>

#include "script_internal.h"

namespace fa {

using Impl = ScriptSystem::Impl;

namespace {

// "'writeProject'" or "'writeProject', 'network'": the capabilities a denied command is missing, for an example.
std::string quoted_list(CapabilitySet set) {
    std::string out;
    for (const std::string& n : set.names()) out += (out.empty() ? "'" : ", '") + n + "'";
    return out;
}

// The hint of a capability_denied error raised inside a game script (behaviour, timer, event handler...).
class GameHint final : public CapabilityHintProvider {
public:
    explicit GameHint(bool editorPlay, CapabilitySet granted) : editorPlay_(editorPlay), granted_(granted) {}
    std::string hint(const CapabilityDenial& d) const override {
        std::string who = editorPlay_ ? "Scripts of the game running in the editor's Play get " : "Game scripts get ";
        std::string out = who + granted_.to_string() +
                          ": they can change the running game but not write files, reach the network or start "
                          "programs, so a shipped game "
                          "cannot do to a player's machine what a tool does to a project. Do " +
                          d.command.name +
                          " from the editor, from a project tool (tools/*.js, which runs with the permissions of "
                          "whoever starts it) or "
                          "with `factoria call`";
        if (!d.missing.has(Capability::WriteAnywhere) && !d.missing.has(Capability::Network) &&
            !d.missing.has(Capability::Process) && !d.missing.has(Capability::Spend) &&
            !d.missing.has(Capability::Publish))
            out += "; a test of the game can ask for it with test(name, fn, { capabilities: [" +
                   quoted_list(d.missing) + "] })";
        else
            out += "; a test can ask for " + quoted_list(d.missing) +
                   " with test(name, fn, { capabilities: [...] }) only when whoever runs the tests has it";
        return out + ".";
    }

private:
    bool editorPlay_;
    CapabilitySet granted_;
};

// The hint inside a test file's code.
class TestHint final : public CapabilityHintProvider {
public:
    std::string hint(const CapabilityDenial& d) const override {
        return "This test is granted " + d.granted.to_string() +
               " (read and state, plus what the test asks for). Ask for more with the "
               "`capabilities` option of the test: test('name', () => { ... }, { capabilities: [" +
               quoted_list(d.missing) +
               "] }). A test can only get what whoever runs it has: `factoria test` has every capability; a run over "
               "MCP never gets "
               "writeAnywhere and a read-only MCP server runs no test that writes. Game scripts called by the test "
               "keep {read, state}.";
    }
};

}  // namespace

void Impl::set_game_role(ScriptSystem::GameRole role) {
    gameRole = role;
    const bool editorPlay = role == ScriptSystem::GameRole::EditorPlay;
    gameCaps = editorPlay ? capability_sets::editor_play() : capability_sets::game_player();
    gameHint = std::make_shared<GameHint>(editorPlay, gameCaps);
    if (!testHint) testHint = std::make_shared<TestHint>();
}

CommandResult Impl::run_command(const std::string& name, const Json& args) {
    switch (capMode) {
        case CapMode::Game: {
            CommandCapabilityScope scope(gameCaps, gameHint);
            return host->commands().call(name, args);
        }
        case CapMode::Test: {
            CommandCapabilityScope scope(testCaps, testHint);
            return host->commands().call(name, args);
        }
        case CapMode::Caller: break;
    }
    return host->commands().call(name, args);
}

}  // namespace fa
