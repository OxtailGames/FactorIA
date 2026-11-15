// The editor's selection: an ordered set of stable entity ids with one primary (docs/EDITOR.md, "Selecting things").
//
// The ids are the `World::id_of` strings, not Entity handles, so the set survives undo, redo and a scene reload. The set
// never looks at the World itself: `prune` takes the question "does this id still exist". Everything here is plain data,
// so the unit tests need no window and no engine.
#pragma once

#include <functional>
#include <string>
#include <vector>

namespace fa::editor {

class Selection {
public:
    // Replaces the whole selection by one id (it becomes the primary). An empty id clears it.
    void replace(const std::string& id);
    // Adds an id at the end and makes it the primary (an id already in the set only becomes the primary).
    void add(const std::string& id);
    // Adds the id when it is not selected, removes it when it is (Ctrl-click). Removing the primary promotes the last
    // remaining id, in selection order.
    void toggle(const std::string& id);
    // Shift-click: selects the ids of `ordered` from `from` to `to` inclusive (either direction) and makes `to` the
    // primary. It replaces the selection, or adds to it when `additive`. Returns false and changes nothing when `from`
    // or `to` is not in `ordered`.
    bool range(const std::string& from, const std::string& to, const std::vector<std::string>& ordered,
               bool additive = false);
    // Removes one id; if it was the primary, the last remaining id becomes the primary.
    void remove(const std::string& id);
    void clear();
    // Drops every id for which `exists` is false (an entity that was deleted, or that an undo or a scene load removed).
    // Returns the number dropped. A dropped primary is replaced like in `remove`.
    int prune(const std::function<bool(const std::string&)>& exists);

    bool contains(const std::string& id) const;
    bool empty() const { return ids_.empty(); }
    size_t size() const { return ids_.size(); }
    // The id the inspector, the gizmos and the AI context follow: the one selected last. Empty when nothing is selected.
    const std::string& primary() const { return primary_; }
    // The selected ids in the order they were selected (the primary is the last one unless a toggle changed it).
    const std::vector<std::string>& ids() const { return ids_; }

private:
    int index_of(const std::string& id) const;
    void erase_at(size_t i);
    std::vector<std::string> ids_;
    std::string primary_;
};

}  // namespace fa::editor
