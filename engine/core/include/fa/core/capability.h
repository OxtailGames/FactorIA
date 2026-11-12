// Command capabilities: what a command can do to the world outside the engine's memory, and the sets of them that a
// caller is granted. A command declares the capabilities it needs (CommandInfo::capabilities, command.h); the registry
// refuses a call whose caller is not granted all of them (error code "capability_denied", docs/ARCHITECTURE.md,
// "Commands", "Capabilities"). This header only holds the vocabulary: the enum, the bitmask set and the named sets.
#pragma once

#include <cstdint>
#include <initializer_list>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

enum class Capability : std::uint8_t {
    // "read": reads project or engine state (scenes, project files, logs, docs, screenshots of the running game).
    Read,
    // "state": changes the running game or the open scene in memory only; writes no file.
    State,
    // "writeProject": writes files inside the project folder. That includes the game's own save folder (storage.clear
    // and the other storage commands), which lives under the project.
    WriteProject,
    // "writeAnywhere": writes outside the project (absolute paths, the user's folders, user-level settings).
    WriteAnywhere,
    // "network": talks to a remote service (HTTP, a cloud API, a feedback server).
    Network,
    // "process": starts an external program (a compiler, an installer, a CLI agent). The platform's own helper behind a
    // game feature is not this: the speech helper (spd-say) that ui.speak starts on Linux counts as "state".
    Process,
    Spend,          // "spend": can cost money (paid AI APIs, store fees).
    Publish,        // "publish": makes something public or uploads a build to a store.
};

inline constexpr int kCapabilityCount = 8;

// JSON name ("writeProject") and the one-line meaning of a capability (what an error or the docs print).
const char* capability_name(Capability c);
const char* capability_doc(Capability c);
// Exact (case-sensitive) camelCase name -> capability; nullopt for an unknown name.
std::optional<Capability> capability_from_name(std::string_view name);
// Every capability name in declaration order, for "valid: ..." lists.
std::vector<std::string> capability_names();

// A set of capabilities: a bitmask value type, cheap to copy and to test (one AND).
class CapabilitySet {
public:
    constexpr CapabilitySet() = default;
    constexpr CapabilitySet(std::initializer_list<Capability> list) {
        for (Capability c : list) bits_ |= bit(c);
    }
    static constexpr CapabilitySet all() { return from_bits((1u << kCapabilityCount) - 1u); }
    static constexpr CapabilitySet none() { return CapabilitySet(); }

    constexpr bool has(Capability c) const { return (bits_ & bit(c)) != 0; }
    constexpr bool empty() const { return bits_ == 0; }
    // Every capability of `other` is in this set.
    constexpr bool has_all(CapabilitySet other) const { return (other.bits_ & ~bits_) == 0; }
    constexpr CapabilitySet with(Capability c) const { return from_bits(bits_ | bit(c)); }
    constexpr CapabilitySet without(Capability c) const { return from_bits(bits_ & ~bit(c)); }
    constexpr CapabilitySet intersect(CapabilitySet other) const { return from_bits(bits_ & other.bits_); }
    constexpr CapabilitySet unite(CapabilitySet other) const { return from_bits(bits_ | other.bits_); }
    // What this set has and `other` lacks.
    constexpr CapabilitySet missing_from(CapabilitySet other) const { return from_bits(bits_ & ~other.bits_); }
    constexpr std::uint32_t bits() const { return bits_; }

    constexpr bool operator==(const CapabilitySet& o) const { return bits_ == o.bits_; }
    constexpr bool operator!=(const CapabilitySet& o) const { return bits_ != o.bits_; }

    // JSON names in declaration order: {"read", "state"}.
    std::vector<std::string> names() const;
    // ["read","state"]
    Json to_json() const;
    // "{read, state}" for messages; "{}" for the empty set.
    std::string to_string() const;

    // From JSON: an array of names (or one name as a string). An unknown name fails with its JSON pointer
    // (`pointer` + "/1") and fa::did_you_mean.
    static Result<CapabilitySet> parse(const Json& json, std::string_view pointer = {});
    // parse() for the capabilities a COMMAND declares (core's declare_command_capabilities, a JS tool's `capabilities`, a
    // plugin's set_command_capabilities): the same, but an empty set is an error that teaches ("a command needs at
    // least read"): an empty set would let every caller run it, even one granted nothing.
    static Result<CapabilitySet> parse_declaration(const Json& json, std::string_view pointer = {});
    // From text: names separated by commas and/or spaces ("read, state"); the CLI and test options use it.
    static Result<CapabilitySet> parse_list(std::string_view text);

private:
    static constexpr std::uint32_t bit(Capability c) { return 1u << static_cast<unsigned>(c); }
    static constexpr CapabilitySet from_bits(std::uint32_t b) {
        CapabilitySet s;
        s.bits_ = b;
        return s;
    }
    std::uint32_t bits_ = 0;
};

// The sets of capabilities a caller is granted. A call needs every capability of its command inside the set.
namespace capability_sets {
// The user's own CLI / editor console / settings windows: everything.
constexpr CapabilitySet cli_user() { return CapabilitySet::all(); }
// An MCP client (`factoria mcp`, the editor's per-run endpoint): everything but writeAnywhere.
constexpr CapabilitySet mcp() { return CapabilitySet::all().without(Capability::WriteAnywhere); }
// `factoria mcp --read-only`: read and state, together with a filter that serves only the readOnly commands and the
// play commands (game.step, game.screenshot, scene.load, ...; ai::is_read_only_tool). The play commands change the
// running game (state), so {read} alone would refuse them. game.screenshot, the filmstrips and play.auto write only
// under .factoria/ and declare {read, state}; their `path` argument needs writeProject, which this set lacks. The
// filter keeps the editing commands out (tools/call on an unlisted tool is refused).
constexpr CapabilitySet mcp_read_only() { return CapabilitySet{Capability::Read, Capability::State}; }
// The in-engine AI agents: everything but writeAnywhere and publish (a later package refines it per role).
constexpr CapabilitySet agent() {
    return CapabilitySet::all().without(Capability::WriteAnywhere).without(Capability::Publish);
}
// A script of the game the player is playing (fa.call from game scripts): read and state.
constexpr CapabilitySet game_player() { return CapabilitySet{Capability::Read, Capability::State}; }
// Scripts and tools the editor runs while the game plays in its window: read and state.
constexpr CapabilitySet editor_play() { return CapabilitySet{Capability::Read, Capability::State}; }
// A test file of the project (`factoria test`): read and state; its options can ask for more.
constexpr CapabilitySet test_script() { return CapabilitySet{Capability::Read, Capability::State}; }

// Sets that commands declare (CommandInfo::capabilities).
// Reads project or engine state, changes nothing.
constexpr CapabilitySet reads() { return CapabilitySet{Capability::Read}; }
// Changes the running game or the open scene in memory (entity edits, game.step, ui.*, in-memory authoring).
constexpr CapabilitySet changes_state() { return CapabilitySet{Capability::Read, Capability::State}; }
// Writes project files and may also change the running game (what a command that declares nothing and is not readOnly
// gets).
constexpr CapabilitySet edits_project() {
    return CapabilitySet{Capability::Read, Capability::State, Capability::WriteProject};
}
// Writes project files only and does not change the running game or the open scene, so it has no "state" (prefab.save,
// scene.format, anim clip edits). Every set holds "read": a command that writes may also read.
constexpr CapabilitySet writes_project() { return CapabilitySet{Capability::Read, Capability::WriteProject}; }
}  // namespace capability_sets

}  // namespace fa
