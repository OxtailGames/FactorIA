// The editor's undo and redo stacks (docs/EDITOR.md, "Undo entries").
//
// An UndoEntry is one step. Its kind says how it is undone:
//  - Snapshot: `data` is the whole scene as `snapshot_scene` wrote it; undoing restores it (Editor::begin_edit).
//  - Special: `data` is an object with one `$...` key (`$clip`, `$clip3d`, `$image`, `$vector`, `$sound`, `$particle`,
//    `$music`, `$modeler`) that points at a step of a document panel; the panel undoes it.
//  - Command: `forward` and `inverse` are lists of commands ({cmd, args}), in the order they are run. Undoing runs
//    `inverse`, redoing runs `forward`; nothing stores the scene. Editor::edit_command makes them for the commands that
//    have an inverse builder (undo_inverse.h: set_component, remove_component, spawn, destroy, set_parent, paste, bones.create);
//    the others still snapshot.
// Every entry knows its approximate size in bytes, so a stack can be capped by memory as well as by length.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa::editor {

struct UndoCommand {
    std::string cmd;
    Json args = Json::object();
    // What this call sets, for CoalesceMode::Merge: a later call with the same non-empty target replaces this one. Empty =
    // never merged by target.
    std::string target;
    // terrain.undo / terrain.redo only: the absolute number of the terrain's undo step this call undoes or redoes (the terrain's
    // history_lost() plus its undo_depth() when the step was made), 0 = not numbered. The editor's list and the terrain's history
    // trim on their own: the number says which entries name a step the terrain let go (undo_inverse.h, drop_terrain_steps).
    std::uint64_t step = 0;
};

struct UndoEntry {
    enum class Kind { Snapshot, Command, Special };

    Kind kind = Kind::Snapshot;
    Json data;                         // Snapshot: the scene; Special: {"$key": ...}; Command: null
    std::vector<UndoCommand> forward;  // Command only: what redo runs
    std::vector<UndoCommand> inverse;  // Command only: what undo runs
    size_t bytes = 0;                  // approximate memory of the entry (set by the constructors)

    UndoEntry() = default;
    // A raw Json is a Special entry when it is an object whose first key starts with '$', a Snapshot otherwise.
    UndoEntry(Json j);  // NOLINT: implicit on purpose, so `undo_.push_back(snapshot)` keeps working
    static UndoEntry snapshot(Json scene);
    static UndoEntry special(Json obj);
    static UndoEntry command(std::vector<UndoCommand> forward, std::vector<UndoCommand> inverse);
    // Estimates `bytes` again after the command lists changed (a Command entry that lost some of its commands).
    void refresh_bytes();

    // The scene or the special object (null for a Command entry): lets `for (const Json& e : stack)` loops that look for
    // their `$key` keep working.
    operator const Json&() const { return data; }  // NOLINT

    // True for a Special entry whose key is `key` ("$clip", ...). Replaces the old `entry.contains(key)`.
    bool is_special(const char* key) const;
    // The payload of that special entry, or null.
    const Json& special_payload(const char* key) const;
};

// Approximate bytes a Json value takes in memory: nodes, strings, container slots. Never allocates; walks the value once.
size_t estimate_json_bytes(const Json& j);

// True when an edit with `key` at `now` merges into the previous edit: same key within kEditCoalesceSeconds.
constexpr double kEditCoalesceSeconds = 0.8;
bool edit_coalesces(const std::string& key, const std::string& lastKey, double now, double lastTime);

enum class CoalesceMode {
    Replace,  // the new forward replaces the old one, the old inverse stays: for "set X to v" commands
    Chain,    // forward = old then new, inverse = new then old: for relative commands
    // A one-command call whose `target` an earlier forward command has replaces that command and goes last in the forward
    // list (the inverse list stays: it holds the oldest values); with a new target it is added like Chain. For a drag that
    // writes several entities under one key.
    Merge,
};

// A stack of entries capped by length and by memory. `push_back` drops the oldest entries while there are more than
// `max_entries()` or, with more than one entry, more than `max_bytes()` bytes (the newest entry always stays).
class UndoStack {
public:
    static constexpr size_t kMaxEntries = 100;
    static constexpr size_t kMaxBytes = size_t(256) << 20;  // estimated in-memory size, not file size

    UndoStack() = default;
    UndoStack(size_t maxEntries, size_t maxBytes) : maxEntries_(maxEntries), maxBytes_(maxBytes) {}

    void push_back(UndoEntry e);
    // Records a command entry, or merges it into the newest one when `coalesce` is true and that one is a Command entry
    // (then nothing else changes). Returns true when a new entry was pushed.
    bool push_command(std::vector<UndoCommand> forward, std::vector<UndoCommand> inverse, bool coalesce,
                      CoalesceMode mode = CoalesceMode::Replace);

    bool empty() const { return v_.empty(); }
    size_t size() const { return v_.size(); }
    size_t bytes() const { return bytes_; }
    // How many entries were ever lost to the caps, clear() or erase_if (not to pop_back: that is Undo). A depth noted
    // earlier means the same entry only while this has not changed.
    size_t lost() const { return lost_; }
    size_t max_entries() const { return maxEntries_; }
    size_t max_bytes() const { return maxBytes_; }
    UndoEntry& back() { return v_.back(); }
    const UndoEntry& back() const { return v_.back(); }
    void pop_back();
    void clear();
    UndoEntry take_back();  // pop_back that returns the entry
    // Removes the entries for which `pred` is true.
    template <class Pred>
    void erase_if(Pred pred) {
        std::vector<UndoEntry> kept;
        for (UndoEntry& e : v_)
            if (!pred(e)) kept.push_back(std::move(e));
        lost_ += v_.size() - kept.size();
        v_ = std::move(kept);
        recount();
    }
    std::vector<UndoEntry>::const_iterator begin() const { return v_.begin(); }
    std::vector<UndoEntry>::const_iterator end() const { return v_.end(); }
    const UndoEntry& operator[](size_t i) const { return v_[i]; }

private:
    void trim();
    void recount();
    std::vector<UndoEntry> v_;
    size_t bytes_ = 0;
    size_t lost_ = 0;
    size_t maxEntries_ = kMaxEntries;
    size_t maxBytes_ = kMaxBytes;
};

}  // namespace fa::editor
