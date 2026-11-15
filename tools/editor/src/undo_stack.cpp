#include "undo_stack.h"

#include <utility>

namespace fa::editor {

namespace {

constexpr size_t kNodeBytes = sizeof(Json);
constexpr size_t kStringSlack = 32;  // header and allocator slack of a string that does not fit in place

size_t add_sat(size_t a, size_t b) { return a > SIZE_MAX - b ? SIZE_MAX : a + b; }

size_t commands_bytes(const std::vector<UndoCommand>& v) {
    size_t n = 0;
    for (const UndoCommand& c : v) n = add_sat(n, add_sat(add_sat(sizeof(UndoCommand), c.cmd.size()), estimate_json_bytes(c.args)));
    return n;
}

const Json kNull;

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
    const bool special = j.is_object() && !j.empty() && j.begin().key().size() > 0 && j.begin().key()[0] == '$';
    kind = special ? Kind::Special : Kind::Snapshot;
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

bool UndoEntry::is_special(const char* key) const { return kind == Kind::Special && data.is_object() && data.contains(key); }

const Json& UndoEntry::special_payload(const char* key) const { return is_special(key) ? data[key] : kNull; }

void UndoStack::trim() {
    size_t drop = 0;
    size_t bytes = bytes_;
    while (v_.size() - drop > 1 && (v_.size() - drop > maxEntries_ || bytes > maxBytes_)) {
        bytes -= v_[drop].bytes;
        ++drop;
    }
    if (drop == 0) return;
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
        if (mode == CoalesceMode::Replace) {
            last.forward = std::move(forward);
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
    v_.clear();
    bytes_ = 0;
}

}  // namespace fa::editor
