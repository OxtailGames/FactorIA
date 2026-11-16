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
    // Replaces the whole selection by `ids` in that order (empty and repeated ids are skipped) and makes `primary` the
    // primary; a `primary` that is not in the list (or empty) leaves the last id as the primary.
    void set(const std::vector<std::string>& ids, const std::string& primary);
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

// ---------------------------------------------------------------------------------------------- what a click does
// The modifier keys of a click or a marquee (Ctrl is Cmd on macOS: Dear ImGui swaps them).
struct SelectMods {
    bool ctrl = false;
    bool shift = false;
};

// A click on a row of the Hierarchy. No modifier replaces the selection; Ctrl toggles the row; Shift selects the rows from
// `anchor` (the row last clicked without Shift) to this one in the order of `ordered` (the rows as the tree shows them),
// Ctrl+Shift adds that range to what is selected. `anchor` is updated: a click without Shift makes this row the anchor, a
// Shift click keeps it. A Shift click with no usable anchor (empty, or not in `ordered`) starts from the primary, and
// from this row alone when that is not shown either.
void click_in_list(Selection& sel, const std::string& id, SelectMods mods, std::string& anchor,
                   const std::vector<std::string>& ordered);

// A click on an entity in the viewport. No modifier replaces the selection, Ctrl toggles the entity, Shift adds it (a range
// of entities in space means nothing, so Shift is "add" here, as it is for the marquee).
void click_in_space(Selection& sel, const std::string& id, SelectMods mods);

// The end of a marquee that covered `hits` (in the order to select them; the last becomes the primary). No modifier
// replaces the selection by the hits (nothing hit: clears it), Shift adds them, Ctrl toggles each.
void apply_marquee(Selection& sel, const std::vector<std::string>& hits, SelectMods mods);

// The ids of `ids` with no selected ancestor, in the order given: what a move, a duplicate or a delete of the selection acts
// on (an entity whose ancestor is selected comes along with it, and would move or be copied twice). `parent_of` returns the
// parent's id, "" for a root or an unknown id.
std::vector<std::string> without_selected_descendants(const std::vector<std::string>& ids,
                                                      const std::function<std::string(const std::string&)>& parent_of);

}  // namespace fa::editor
