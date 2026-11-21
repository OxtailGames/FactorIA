// Deprecations: API that still works but has a replacement (or none), and will be removed two minor versions after the one that
// deprecated it. The data lives in the "deprecated" section of tools/common/api_since.json (docs/design/ARCHITECTURE_CORE.md, "Deprecations");
// the tooling loads it into this table at start-up (fa::install_deprecations), the generated reference and typings print it, and
// the runtime warns through it: a command call (CommandRegistry), a scene or prefab field (the loader) and a script call (the
// "factoria" prelude). A process that never loads the table (an exported game) has an empty one and pays one atomic load.
#pragma once

#include <atomic>
#include <cstdint>
#include <map>
#include <mutex>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

// The three kinds of key, the same as the sections of api_since.json.
inline constexpr const char* kDeprecatedCommands = "commands";      // "scene.old_command"
inline constexpr const char* kDeprecatedComponents = "components";  // "Sprite" or "Sprite.oldField"
inline constexpr const char* kDeprecatedScript = "script";          // "oldExport" or "NavAPI.oldMember"

struct Deprecation {
    std::string since;  // "0.30.0" (or "unreleased" on main before the release)
    std::string use;    // the replacement: a key of the same section ("scene.new_command"); empty when there is none
    std::string note;   // one sentence: why, how to migrate; required when `use` is empty
};

// The version that removes something deprecated in `since`: the minor two after it ("0.30.2" -> "0.32.0"); "" for "unreleased"
// or text that is not x.y.z.
std::string deprecation_removal_version(std::string_view since);
// "Deprecated since 0.30.0 - use `x`. Removed in 0.32.0." (the line the reference prints and the typings' @deprecated carry:
// without the kind and the key); a dash (-) is the ASCII hyphen on purpose (the generated files are ASCII-safe on every OS).
std::string deprecation_summary(const Deprecation& d);
// What a warning says: "Deprecated: command 'x' (since 0.30.0) ...". `kind` is one of the constants above.
std::string deprecation_message(std::string_view kind, std::string_view key, const Deprecation& d);

// A field a component lost after its deprecation ("Camera", "bloom"): "Camera.bloom was removed in 0.33.0: add a PostProcess ...", the
// hint of the "Unknown field" error of a scene, a prefab or a patch that still holds it (replaces the did-you-mean, which cannot
// guess a field that is gone). The field name is matched without regard to case. "" for a field that was never removed. The table is in deprecation.cpp: add a row with the removal.
std::string removed_field_hint(std::string_view component, std::string_view field);

class Deprecations {
public:
    static Deprecations& global();

    // Replaces the table with {"commands": {key: {since, use, note}}, "components": {...}, "script": {...}} (the "deprecated"
    // section of api_since.json). Entries that are not objects are skipped. Forgets which warnings were given.
    void set(const Json& section);
    void clear();
    bool empty() const noexcept {
        return empty_.load(std::memory_order_acquire);
    }  // lock-free: the hot path of every call

    // Lock-free pre-checks for a hot path with a non-empty table (the editor and the CLI have one; the common call asks about
    // something that is not deprecated): false means `key` is certainly not in the table of `kind`, so the caller skips building
    // a key and taking the lock; true means it may be (a small Bloom filter: a rare false positive just takes the slow path).
    // They answer for the table as set() left it, and a table that was empty is seen with all its words (release/acquire on
    // empty()); a call that races a set() that replaces a non-empty table may see a mix of the old and the new words, so
    // for that one call "certainly not" can be wrong and the warning waits for the next call.
    bool may_contain(std::string_view kind, std::string_view key) const noexcept;
    // The same for a component: true when "Name" or any "Name.field" may be in the "components" section.
    bool may_contain_component(std::string_view component) const noexcept;

    std::optional<Deprecation> find(std::string_view kind, std::string_view key) const;
    // Every key of a kind, sorted.
    std::vector<std::string> keys(std::string_view kind) const;

    // The warning for `key` the first time it is asked since the table was set or reset_warned() ran; "" when the key is not
    // deprecated and on every later call. Thread-safe.
    std::string take_warning(std::string_view kind, std::string_view key);
    // The warnings may be given again (the editor calls it when it opens a project).
    void reset_warned();

private:
    mutable std::mutex mutex_;
    std::map<std::string, std::map<std::string, Deprecation, std::less<>>, std::less<>> table_;
    std::set<std::string> warned_;
    std::atomic<bool> empty_{true};
    // One Bloom filter per kind (commands, components by component name, script, anything else): 512 bits, two probes.
    static constexpr int kBloomWords = 8;
    std::atomic<std::uint64_t> bloom_[4][kBloomWords] = {};
};

// take_warning + a log line (category "deprecated", level warning) when there is one; true when it warned.
bool warn_deprecated(std::string_view kind, std::string_view key);

}  // namespace fa
