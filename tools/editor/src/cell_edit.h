// Editing a streamed world in the editor (docs/BIG_WORLDS_STREAMING.md, "Editing a streamed world"; docs/editor/EDITOR_PANELS.md, "Cells panel").
//
// The open scene holds a StreamedWorld; its index (<name>.world.json) lists the cells, each its own scene file. In Edit mode the engine
// is paused, so the streamer never loads or unloads by distance: the editor loads the cells the user picks (or the ones around the
// camera) as ordinary entities under a root "cell_<i>_<j>" (the same shape the streamer makes: the root at the absolute (0, 0, 0), the
// entities' positions absolute), and this class remembers for each one what its file held when it was loaded or last saved.
//
//   DIRTY. A loaded cell is dirty when its entities, written the way a save writes them (prefab instances as instances), differ from
//   that baseline. The check runs when the editor says something may have changed (note_edit, once per frame at most, and not while the
//   mouse drags), so Undo back to the saved state clears the mark.
//   SAVE. Writes only the dirty cells, each to its own file (the file's other top-level keys are kept), and the index only when a cell was
//   added or a cell's height bounds had to grow. Before writing, a top-level entity of a cell whose position is in another cell is moved
//   to that cell (loading it, or making a new one that the index then lists): the "re-file".
//   SNAPSHOTS. snapshot_scene leaves cells out, so the editor's snapshots (undo, play) carry capture() under "$cells" and restore() puts
//   it back; the baselines stay here, so an undo that returns to the saved state shows a clean cell.
//   PLAY. suspend() forgets the entities (the world is replaced and the game streams by distance); the set of loaded cells, with its
//   baselines, stays, and restore() brings the cells back at Stop.
//
// Main thread only. No exceptions leave this class.
#pragma once

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "fa/scene/world_index.h"

namespace fa::editor {

struct CellRow {
    std::int32_t i = 0, j = 0;
    std::string scene;
    bool inIndex = false;  // false: a cell that Save will add to the index
    bool loaded = false;
    bool dirty = false;
    std::int64_t entities = 0;  // the cell's own root entities while loaded
    double distance = 0;        // metres on the plane from the view point to its bounds
};

struct CellSaveReport {
    bool ok = true;
    std::string error;                 // what went wrong; nothing was changed then
    std::vector<std::string> written;  // files written, in order
    int moved = 0;                     // entities re-filed into another cell
    bool indexWritten = false;
    std::vector<std::string> notes;
};

class CellEdit {
public:
    static constexpr int kMaxLoaded = 256;  // cells loaded at once in the editor
    static constexpr int kMaxAround = 64;   // cells one "load around the view" loads

    // ---- the index
    // Reads the index of the scene's StreamedWorld when its path changed. Cheap: call it once per frame in Edit.
    void refresh(World& world, bool force = false);  // force: read the index again (it changed on disk)
    bool has_index() const { return hasIndex_; }
    const std::string& index_path() const { return indexPath_; }
    const WorldIndex& index() const { return index_; }
    const std::string& error() const { return error_; }  // the index could not be read ("" = none)
    // Forgets everything (another scene is open): loaded cells are not touched in the world (the caller replaced it).
    void reset();

    // ---- loading
    bool load(World& world, std::int32_t i, std::int32_t j, std::string* error);
    // Loads the cells of the index whose bounds are within `radius` metres of the plane point (a, b), nearest first (ties by (j, i)),
    // at most `maxCells` that are not loaded yet. `loaded` = how many it loaded, `left` = how many more were in range.
    bool load_around(World& world, double a, double b, double radius, int maxCells, int* loaded, int* left,
                     std::string* error);
    // Unloads a cell. A dirty one is refused unless `discard` (its changes are lost).
    bool unload(World& world, std::int32_t i, std::int32_t j, bool discard, std::string* error);
    int unload_clean(World& world);  // every loaded cell that is not dirty; returns how many
    bool is_loaded(std::int32_t i, std::int32_t j) const { return slots_.count({i, j}) != 0; }
    int loaded_count() const { return int(slots_.size()); }
    Entity root_of(std::int32_t i, std::int32_t j) const;
    const std::string& warnings() const { return warnings_; }  // what the last load said (references to other cells...)

    // ---- dirty
    void note_edit() { pending_ = true; }
    // Rechecks the loaded cells when something may have changed (`busy`: the mouse is dragging; the check waits).
    void update(World& world, bool busy);
    bool is_dirty(std::int32_t i, std::int32_t j) const;
    bool any_dirty() const;
    int dirty_count() const;
    bool index_changed() const { return indexDirty_; }
    // A root entity of a loaded cell: which cell holds it (true), and where its position puts it (`toI`, `toJ`; the same cell when it
    // did not move). False for an entity that is in no loaded cell.
    bool cell_of_entity(const World& world, Entity e, std::int32_t& i, std::int32_t& j) const;
    bool destination_of(const World& world, Entity e, std::int32_t& toI, std::int32_t& toJ) const;
    // The plane point (a, b) of an absolute position for this world's dimension.
    void plane_of(const DVec3& absolute, double& a, double& b) const;
    // The cells to list: every loaded one, then the nearest of the index, `maxRows` in all, sorted by distance (then (j, i)).
    std::vector<CellRow> rows(const World& world, double a, double b, std::size_t maxRows) const;

    // ---- snapshots and play
    Json capture(World& world);  // {"i,j": [entity json]} of the loaded cells (empty while suspended)
    void suspend() {
        suspended_ = true;
        for (auto& [k, s] : slots_) s.root = Entity{};
    }
    bool suspended() const { return suspended_; }
    // After the world was replaced: loads every cell of the set again, from `snap` (the snapshot's `$cells`), else from `keep` (what was
    // loaded just before), else from its file.
    void restore(World& world, const Json& snap, const Json& keep);

    // The scene was loaded again from its file (Reload): the index is read again and every loaded cell is loaded again from its file,
    // clean (the changes of a dirty one are gone, which the caller asked about first).
    void reload(World& world);

    // ---- save
    // Writes the dirty cells (only `onlyI`/`onlyJ` and the cells that receive its entities when `only` is true) and the index when it
    // changed. Nothing is written when a path breaks the project's write rules or a target cannot be made.
    CellSaveReport save(World& world, bool only = false, std::int32_t onlyI = 0, std::int32_t onlyJ = 0);

private:
    struct Key {
        std::int32_t i = 0, j = 0;
        bool operator<(const Key& o) const { return j != o.j ? j < o.j : i < o.i; }
        bool operator==(const Key& o) const { return i == o.i && j == o.j; }
    };
    struct Slot {
        Entity root;
        std::uint64_t baseline = 0, current = 0;
        bool isNew = false;  // not in the index yet
        std::string scene;
        Json top = Json::object();  // the file's top-level keys but "entities"
    };
    static std::string key_text(const Key& k) { return std::to_string(k.i) + "," + std::to_string(k.j); }
    Json entities_json(World& world, Entity root, PrefabSave mode);
    std::uint64_t fingerprint(World& world, Entity root);
    Entity make_root(World& world, const Key& k);
    bool place(World& world, const Key& k, Slot& slot, const Json& entities, std::string* error);
    const WorldCell* find_cell(const Key& k) const;
    std::string new_cell_path(const Key& k) const;
    Key key_at(const World& world, Entity e) const;

    bool hasIndex_ = false;
    std::string indexPath_, triedPath_, error_, warnings_;
    WorldIndex index_;
    std::map<Key, Slot> slots_;
    bool pending_ = false, suspended_ = false, indexDirty_ = false;
    PrefabBaseCache cache_;
};

}  // namespace fa::editor
