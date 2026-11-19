#include "undo_stack.h"

#include <algorithm>
#include <iterator>
#include <utility>

namespace fa::editor {

namespace {

constexpr size_t kNodeBytes = sizeof(Json);
constexpr size_t kStringSlack = 32;  // header and allocator slack of a string that does not fit in place

size_t add_sat(size_t a, size_t b) { return a > SIZE_MAX - b ? SIZE_MAX : a + b; }

size_t commands_bytes(const std::vector<UndoCommand>& v) {
    size_t n = 0;
    for (const UndoCommand& c : v) {
        const size_t own = add_sat(add_sat(sizeof(UndoCommand), c.cmd.size()), c.target.size());
        n = add_sat(n, add_sat(own, estimate_json_bytes(c.args)));
    }
    return n;
}

const Json kNull;

// `base` followed by `patch`, as ONE RFC 7386 merge patch (nulls stay: they are the "delete this key" of the patch). A
// value replaces what is there; two objects compose key by key. False when one patch cannot stand for both: an object
// after a null or a plain value would merge into the current value instead of replacing what the first patch set or
// deleted.
bool compose_patch(Json& base, const Json& patch) {
    if (!patch.is_object()) {
        base = patch;
        return true;
    }
    if (!base.is_object()) return false;
    Json out = base;
    for (auto it = patch.begin(); it != patch.end(); ++it) {
        if (!out.contains(it.key())) {
            out[it.key()] = it.value();
            continue;
        }
        if (!compose_patch(out[it.key()], it.value())) return false;
    }
    base = std::move(out);
    return true;
}

// The merge patch of a scene.set_component-style call with `merge: true` (its `fields`), or null.
const Json* merge_patch_of(const UndoCommand& c) {
    if (!c.args.is_object()) return nullptr;
    const auto merge = c.args.find("merge");
    const auto fields = c.args.find("fields");
    if (merge == c.args.end() || !merge->is_boolean() || !merge->get<bool>()) return nullptr;
    return fields != c.args.end() && fields->is_object() ? &*fields : nullptr;
}

// Whether two argument objects name the same target: every argument but "fields" equal (the entity, the component,
// "merge"...). Both have "fields" (merge_patch_of found it), so equal sizes and every other key of `a` equal in `b`
// make the key sets equal too. A drag runs this once per frame, so nothing is copied.
bool same_target(const Json& a, const Json& b) {
    if (!a.is_object() || !b.is_object() || a.size() != b.size()) return false;
    for (auto it = a.begin(); it != a.end(); ++it) {
        if (it.key() == "fields") continue;
        const auto other = b.find(it.key());
        if (other == b.end() || *other != it.value()) return false;
    }
    return true;
}

// `older` then `newer` (same target: the same fields of the same component) as ONE call whose patches are composed, in
// `newer`. False when they are not two merge patches of one entity and component, or do not compose: the caller keeps
// both.
bool compose_merge_calls(const UndoCommand& older, UndoCommand& newer) {
    const Json* first = merge_patch_of(older);
    const Json* second = merge_patch_of(newer);
    if (!first || !second || older.cmd != newer.cmd) return false;
    if (!same_target(older.args, newer.args)) return false;
    Json composed = *first;
    if (!compose_patch(composed, *second)) return false;
    newer.args["fields"] = std::move(composed);
    return true;
}

}  // namespace

size_t estimate_json_bytes(const Json& j) {
    size_t n = kNodeBytes;
    if (j.is_string()) {
        n = add_sat(n, add_sat(j.get_ref<const std::string&>().size(), kStringSlack));
    } else if (j.is_array()) {
        for (const Json& c : j) n = add_sat(n, estimate_json_bytes(c));
    } else if (j.is_object()) {
        for (auto it = j.begin(); it != j.end(); ++it)
            n = add_sat(n, add_sat(add_sat(sizeof(std::string), it.key().size()), estimate_json_bytes(it.value())));
    }
    return n;
}

bool edit_coalesces(const std::string& key, const std::string& lastKey, double now, double lastTime) {
    return key == lastKey && (now - lastTime) < kEditCoalesceSeconds;
}

UndoEntry::UndoEntry(Json j) {
    const bool isSpecial = j.is_object() && !j.empty() && j.begin().key().size() > 0 && j.begin().key()[0] == '$';
    kind = isSpecial ? Kind::Special : Kind::Snapshot;
    data = std::move(j);
    bytes = estimate_json_bytes(data);
}

UndoEntry UndoEntry::snapshot(Json scene) {
    UndoEntry e;
    e.kind = Kind::Snapshot;
    e.data = std::move(scene);
    e.bytes = estimate_json_bytes(e.data);
    return e;
}

UndoEntry UndoEntry::special(Json obj) {
    UndoEntry e;
    e.kind = Kind::Special;
    e.data = std::move(obj);
    e.bytes = estimate_json_bytes(e.data);
    return e;
}

UndoEntry UndoEntry::command(std::vector<UndoCommand> fwd, std::vector<UndoCommand> inv) {
    UndoEntry e;
    e.kind = Kind::Command;
    e.forward = std::move(fwd);
    e.inverse = std::move(inv);
    e.bytes = add_sat(sizeof(UndoEntry), add_sat(commands_bytes(e.forward), commands_bytes(e.inverse)));
    return e;
}

bool UndoEntry::is_special(const char* key) const {
    return kind == Kind::Special && data.is_object() && data.contains(key);
}

const Json& UndoEntry::special_payload(const char* key) const { return is_special(key) ? data[key] : kNull; }

void UndoStack::trim() {
    size_t drop = 0;
    size_t bytes = bytes_;
    while (v_.size() - drop > 1 && (v_.size() - drop > maxEntries_ || bytes > maxBytes_)) {
        bytes -= v_[drop].bytes;
        ++drop;
    }
    if (drop == 0) return;
    lost_ += drop;
    v_.erase(v_.begin(), v_.begin() + std::ptrdiff_t(drop));
    bytes_ = bytes;
}

void UndoStack::recount() {
    bytes_ = 0;
    for (const UndoEntry& e : v_) bytes_ = add_sat(bytes_, e.bytes);
}

void UndoStack::push_back(UndoEntry e) {
    bytes_ = add_sat(bytes_, e.bytes);
    v_.push_back(std::move(e));
    trim();
}

bool UndoStack::push_command(std::vector<UndoCommand> forward, std::vector<UndoCommand> inverse, bool coalesce,
                             CoalesceMode mode) {
    if (coalesce && !v_.empty() && v_.back().kind == UndoEntry::Kind::Command) {
        UndoEntry& last = v_.back();
        bytes_ -= last.bytes;
        // Merge needs one-to-one lists (forward[k] undone by inverse[n-1-k]) and a non-empty target; else it chains.
        if (mode == CoalesceMode::Merge && !(forward.size() == 1 && inverse.size() == 1 && !forward[0].target.empty() &&
                                             last.forward.size() == last.inverse.size()))
            mode = CoalesceMode::Chain;
        if (mode == CoalesceMode::Replace) {
            last.forward = std::move(forward);
        } else if (mode == CoalesceMode::Merge) {
            auto same = [&](const UndoCommand& c) { return c.target == forward[0].target; };
            auto at = std::find_if(last.forward.rbegin(), last.forward.rend(), same);
            // Two merge patches of one target are one patch (a drag of one colour of skyMaterialParams, then of
            // another): the newest alone would leave the first out of redo. Patches that do not compose are both kept,
            // in order.
            const bool isMergeCall = merge_patch_of(forward[0]) != nullptr;
            if (at != last.forward.rend() && isMergeCall && !compose_merge_calls(*at, forward[0])) {
                last.forward.push_back(std::move(forward[0]));
                last.inverse.insert(last.inverse.begin(), std::move(inverse[0]));
            } else if (at != last.forward.rend()) {
                // The newest call goes last: an older command of another target may set the same field too (position, then
                // position and scale, then position again), and redo must end with the newest value. The inverse list stays
                // as it is: its oldest-first-seen values are what undo has to give back.
                last.forward.erase(std::next(at).base());
                last.forward.push_back(std::move(forward[0]));
            } else {
                last.forward.push_back(std::move(forward[0]));
                last.inverse.insert(last.inverse.begin(), std::move(inverse[0]));
            }
        } else {
            for (UndoCommand& c : forward) last.forward.push_back(std::move(c));
            for (UndoCommand& c : last.inverse) inverse.push_back(std::move(c));
            last.inverse = std::move(inverse);
        }
        last.bytes = add_sat(sizeof(UndoEntry), add_sat(commands_bytes(last.forward), commands_bytes(last.inverse)));
        bytes_ = add_sat(bytes_, last.bytes);
        trim();
        return false;
    }
    push_back(UndoEntry::command(std::move(forward), std::move(inverse)));
    return true;
}

void UndoStack::pop_back() {
    bytes_ -= v_.back().bytes;
    v_.pop_back();
}

UndoEntry UndoStack::take_back() {
    UndoEntry e = std::move(v_.back());
    bytes_ -= e.bytes;
    v_.pop_back();
    return e;
}

void UndoStack::clear() {
    lost_ += v_.size();
    v_.clear();
    bytes_ = 0;
}

}  // namespace fa::editor
