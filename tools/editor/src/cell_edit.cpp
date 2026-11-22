#include "cell_edit.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <set>

#include "fa/core/fs.h"
#include "fa/scene/components.h"
#include "fa/scene/components_world.h"

namespace fa::editor {

namespace {

constexpr const char* kSceneFormat = "factoria.scene/1";
constexpr const char* kWorldSuffix = ".world.json";

std::uint64_t fnv1a(const std::string& s) {
    std::uint64_t h = 1469598103934665603ULL;
    for (unsigned char c : s) {
        h ^= c;
        h *= 1099511628211ULL;
    }
    return h;
}

std::int32_t to_i32(std::int64_t v) {
    return std::int32_t(std::clamp<std::int64_t>(v, std::numeric_limits<std::int32_t>::min(),
                                                 std::numeric_limits<std::int32_t>::max()));
}

bool ends_with(const std::string& s, const std::string& suffix) {
    return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

}  // namespace

// ------------------------------------------------------------------------------------------------ the index
void CellEdit::refresh(World& world, bool force) {
    std::string path;
    world.each<StreamedWorld>([&](Entity, StreamedWorld& s) {
        if (path.empty() && !s.world.empty()) path = s.world;
    });
    if (!force && path == triedPath_) return;
    // Cells are loaded from the index that is in use: it changes only when none is loaded.
    if (!slots_.empty() && path != indexPath_) return;
    triedPath_ = path;
    hasIndex_ = false;
    error_.clear();
    index_ = WorldIndex{};
    indexPath_ = path;
    indexDirty_ = false;
    if (path.empty()) return;
    WorldIndexOptions opts;
    opts.checkFiles = false;
    auto loaded = load_world_index(path, opts);
    if (!loaded.ok()) {
        error_ = loaded.error().message + (loaded.error().hint.empty() ? "" : " (hint: " + loaded.error().hint + ")");
        return;
    }
    index_ = loaded.value();
    hasIndex_ = true;
}

void CellEdit::reset() {
    slots_.clear();
    hasIndex_ = false;
    indexPath_.clear();
    triedPath_.clear();
    error_.clear();
    warnings_.clear();
    index_ = WorldIndex{};
    pending_ = false;
    suspended_ = false;
    indexDirty_ = false;
}

const WorldCell* CellEdit::find_cell(const Key& k) const { return index_.find(k.i, k.j); }

std::string CellEdit::new_cell_path(const Key& k) const {
    std::string base = indexPath_;
    if (ends_with(base, kWorldSuffix))
        base.resize(base.size() - std::string(kWorldSuffix).size());
    else if (ends_with(base, ".json"))
        base.resize(base.size() - 5);
    return base + "_cells/" + std::to_string(k.i) + "_" + std::to_string(k.j) + ".scene.json";
}

void CellEdit::plane_of(const DVec3& p, double& a, double& b) const {
    a = p.x;
    b = index_.dimension == WorldDimension::D3 ? p.z : p.y;
}

// ------------------------------------------------------------------------------------------------ serialization
Json CellEdit::entities_json(World& world, Entity root, PrefabSave mode) {
    cache_.forget_world();
    const PoseRest pose = collect_pose_rest(world);
    EntityJsonOptions eo;
    eo.skipSpawned = true;
    eo.prefabs = mode;
    eo.prefabCache = &cache_;
    if (!pose.empty()) eo.poseRest = &pose;
    Json list = Json::array();
    for (Entity c : world.children(root)) {
        if (world.info(c).scriptSpawned) continue;
        list.push_back(entity_to_json(world, c, eo));
    }
    return list;
}

std::uint64_t CellEdit::fingerprint(World& world, Entity root) {
    return fnv1a(entities_json(world, root, PrefabSave::Keep).dump());
}

Entity CellEdit::make_root(World& world, const Key& k) {
    // The same shape the streamer makes (engine/runtime world_streamer.cpp, do_apply): the root at the ABSOLUTE (0, 0, 0).
    const Entity root = world.create("cell " + key_text(k), "cell_" + std::to_string(k.i) + "_" + std::to_string(k.j));
    world.info(root).streamedCell = true;
    if (Transform* t = world.get<Transform>(root)) t->position = world.to_local(DVec3{0.0, 0.0, 0.0});
    return root;
}

// Makes the root of cell `k` and loads `entities` under it.
bool CellEdit::place(World& world, const Key& k, Slot& slot, const Json& entities, std::string* error) {
    const Entity root = make_root(world, k);
    Json doc = Json::object({{"format", kSceneFormat}, {"entities", entities}});
    SceneLoadOptions opts;
    opts.additive = true;
    opts.parent = root;
    opts.streamedCell = true;
    const LoadReport report = load_scene(world, doc, slot.scene, opts);
    std::string errors, warns;
    for (const LoadMessage& m : report.messages) {
        std::string& to = m.severity == LoadMessage::Severity::Error ? errors : warns;
        if (!to.empty()) to += "\n";
        to += m.to_string();
    }
    if (!report.ok()) {
        world.destroy(root);
        if (error) *error = "Cell " + key_text(k) + " (" + slot.scene + ") does not load: " + errors;
        return false;
    }
    if (!warns.empty()) warnings_ = "Cell " + key_text(k) + ": " + warns;
    slot.root = root;
    return true;
}

// ------------------------------------------------------------------------------------------------ loading
bool CellEdit::load(World& world, std::int32_t i, std::int32_t j, std::string* error) {
    auto fail = [&](const std::string& m) {
        if (error) *error = m;
        return false;
    };
    const Key k{i, j};
    if (suspended_) return fail("Stop the game before loading cells: Play streams them by distance.");
    if (!hasIndex_)
        return fail("This scene has no streamed world to load cells from" +
                    (error_.empty() ? std::string(" (no StreamedWorld names an index).") : ": " + error_));
    if (slots_.count(k)) return true;
    if (slots_.size() >= std::size_t(kMaxLoaded))
        return fail("Already " + std::to_string(kMaxLoaded) +
                    " cells are loaded, the most the editor holds. Unload some first.");
    const WorldCell* cell = find_cell(k);
    if (!cell)
        return fail("The index " + indexPath_ + " has no cell " + key_text(k) +
                    ". (Moving an entity into that area and saving makes the cell.)");
    auto text = fs::read_text(cell->scene);
    if (!text.ok()) return fail("Cannot read cell " + key_text(k) + " '" + cell->scene + "': " + text.error().message);
    auto parsed = parse_json(text.value(), cell->scene);
    if (!parsed.ok()) return fail(parsed.error().message);
    Json doc = parsed.value();
    if (!doc.is_object()) return fail(cell->scene + " is not a scene file (a JSON object with \"entities\").");
    Json entities = doc.contains("entities") && doc["entities"].is_array() ? doc["entities"] : Json::array();
    Slot slot;
    slot.scene = cell->scene;
    slot.top = doc;
    slot.top.erase("entities");
    warnings_.clear();
    std::string err;
    if (!place(world, k, slot, entities, &err)) return fail(err);
    slot.baseline = slot.current = fingerprint(world, slot.root);
    slots_[k] = std::move(slot);
    return true;
}

bool CellEdit::load_around(World& world, double a, double b, double radius, int maxCells, int* loaded, int* left,
                           std::string* error) {
    if (loaded) *loaded = 0;
    if (left) *left = 0;
    if (suspended_) {
        if (error) *error = "Stop the game before loading cells: Play streams them by distance.";
        return false;
    }
    if (!hasIndex_) {
        if (error) *error = "This scene has no streamed world to load cells from.";
        return false;
    }
    struct Cand {
        double d;
        std::int32_t i, j;
    };
    std::vector<Cand> cands;
    for (const WorldCell& c : index_.cells) {
        if (slots_.count({c.i, c.j})) continue;
        const double d = index_.distance_to(c, a, b);
        if (d <= radius) cands.push_back({d, c.i, c.j});
    }
    std::sort(cands.begin(), cands.end(), [](const Cand& x, const Cand& y) {
        if (x.d != y.d) return x.d < y.d;
        return x.j != y.j ? x.j < y.j : x.i < y.i;
    });
    const std::size_t room = slots_.size() >= std::size_t(kMaxLoaded) ? 0 : std::size_t(kMaxLoaded) - slots_.size();
    const std::size_t take = std::min({cands.size(), std::size_t(std::clamp(maxCells, 0, kMaxAround)), room});
    bool ok = true;
    int n = 0;
    for (std::size_t c = 0; c < take; ++c) {
        std::string err;
        if (load(world, cands[c].i, cands[c].j, &err)) {
            ++n;
        } else if (ok) {
            ok = false;
            if (error) *error = err;
        }
    }
    if (loaded) *loaded = n;
    if (left) *left = int(cands.size() - take);
    return ok;
}

bool CellEdit::unload(World& world, std::int32_t i, std::int32_t j, bool discard, std::string* error) {
    auto it = slots_.find({i, j});
    if (it == slots_.end()) return true;
    const bool dirty = it->second.isNew || it->second.current != it->second.baseline;
    if (dirty && !discard) {
        if (error) *error = "Cell " + key_text(it->first) + " has unsaved changes. Save it first, or discard them.";
        return false;
    }
    if (!suspended_ && !it->second.root.is_null() && world.alive(it->second.root)) world.destroy(it->second.root);
    slots_.erase(it);
    return true;
}

int CellEdit::unload_clean(World& world) {
    std::vector<Key> keys;
    for (const auto& [k, s] : slots_)
        if (!s.isNew && s.current == s.baseline) keys.push_back(k);
    for (const Key& k : keys) unload(world, k.i, k.j, false, nullptr);
    return int(keys.size());
}

Entity CellEdit::root_of(std::int32_t i, std::int32_t j) const {
    auto it = slots_.find({i, j});
    return it == slots_.end() ? Entity{} : it->second.root;
}

// ------------------------------------------------------------------------------------------------ dirty
void CellEdit::update(World& world, bool busy) {
    if (!pending_ || suspended_ || busy) return;
    pending_ = false;
    std::vector<Key> gone;
    for (auto& [k, s] : slots_) {
        if (s.root.is_null() || !world.alive(s.root)) {
            gone.push_back(k);  // its root was deleted: the cell is closed, its file is unchanged
            continue;
        }
        s.current = fingerprint(world, s.root);
    }
    for (const Key& k : gone) {
        warnings_ =
            "The root entity of cell " + key_text(k) + " was deleted: the cell is closed and its file is unchanged.";
        slots_.erase(k);
    }
}

bool CellEdit::is_dirty(std::int32_t i, std::int32_t j) const {
    auto it = slots_.find({i, j});
    return it != slots_.end() && (it->second.isNew || it->second.current != it->second.baseline);
}

int CellEdit::dirty_count() const {
    int n = 0;
    for (const auto& [k, s] : slots_)
        if (s.isNew || s.current != s.baseline) ++n;
    return n;
}

bool CellEdit::any_dirty() const { return indexDirty_ || dirty_count() > 0; }

bool CellEdit::cell_of_entity(const World& world, Entity e, std::int32_t& i, std::int32_t& j) const {
    if (slots_.empty()) return false;
    for (Entity cur = e; !cur.is_null() && world.alive(cur); cur = world.parent(cur))
        if (world.info(cur).streamedCell) {
            for (const auto& [k, s] : slots_)
                if (s.root == cur) {
                    i = k.i;
                    j = k.j;
                    return true;
                }
            return false;
        }
    return false;
}

bool CellEdit::destination_of(const World& world, Entity e, std::int32_t& toI, std::int32_t& toJ) const {
    if (!hasIndex_ || slots_.empty() || e.is_null() || !world.alive(e)) return false;
    const Entity parent = world.parent(e);
    if (parent.is_null() || !world.info(parent).streamedCell) return false;
    bool inCell = false;
    for (const auto& [k, s] : slots_)
        if (s.root == parent) inCell = true;
    if (!inCell) return false;
    double a = 0, b = 0;
    plane_of(world.absolute_position(e), a, b);
    std::int64_t ci = 0, cj = 0;
    index_.cell_of(a, b, ci, cj);
    toI = to_i32(ci);
    toJ = to_i32(cj);
    return true;
}

std::vector<CellRow> CellEdit::rows(const World& world, double a, double b, std::size_t maxRows) const {
    std::vector<CellRow> out;
    auto row_of = [&](const WorldCell& c) {
        CellRow r;
        r.i = c.i;
        r.j = c.j;
        r.scene = c.scene;
        r.inIndex = true;
        r.distance = index_.distance_to(c, a, b);
        return r;
    };
    for (const auto& [k, s] : slots_) {
        CellRow r;
        if (const WorldCell* c = find_cell(k)) {
            r = row_of(*c);
        } else {
            r.i = k.i;
            r.j = k.j;
            r.scene = s.scene;
            WorldCell tmp;
            const double a0 = index_.originA + double(k.i) * index_.cellSize;
            const double b0 = index_.originB + double(k.j) * index_.cellSize;
            tmp.boundsMin = Vec3{float(a0), 0.0f, float(b0)};
            tmp.boundsMax = Vec3{float(a0 + index_.cellSize), 0.0f, float(b0 + index_.cellSize)};
            if (index_.dimension == WorldDimension::D2) {
                tmp.boundsMin = Vec3{float(a0), float(b0), 0.0f};
                tmp.boundsMax = Vec3{float(a0 + index_.cellSize), float(b0 + index_.cellSize), 0.0f};
            }
            r.distance = index_.distance_to(tmp, a, b);
        }
        r.loaded = true;
        r.dirty = s.isNew || s.current != s.baseline;
        r.entities = s.root.is_null() || !world.alive(s.root) ? 0 : std::int64_t(world.children(s.root).size());
        out.push_back(std::move(r));
    }
    // The nearest cells of the index that are not loaded: a partial sort, so a 262144-cell index costs one pass.
    struct Cand {
        double d;
        std::size_t idx;
    };
    std::vector<Cand> cands;
    cands.reserve(index_.cells.size());
    for (std::size_t n = 0; n < index_.cells.size(); ++n) {
        const WorldCell& c = index_.cells[n];
        if (slots_.count({c.i, c.j})) continue;
        cands.push_back({index_.distance_to(c, a, b), n});
    }
    auto less = [&](const Cand& x, const Cand& y) {
        if (x.d != y.d) return x.d < y.d;
        return x.idx < y.idx;  // the index is sorted by (j, i)
    };
    const std::size_t want = maxRows > out.size() ? maxRows - out.size() : 0;
    const std::size_t take = std::min(want, cands.size());
    std::partial_sort(cands.begin(), cands.begin() + std::ptrdiff_t(take), cands.end(), less);
    for (std::size_t n = 0; n < take; ++n) out.push_back(row_of(index_.cells[cands[n].idx]));
    std::sort(out.begin(), out.end(), [](const CellRow& x, const CellRow& y) {
        if (x.distance != y.distance) return x.distance < y.distance;
        return x.j != y.j ? x.j < y.j : x.i < y.i;
    });
    return out;
}

// ------------------------------------------------------------------------------------------------ snapshots
Json CellEdit::capture(World& world) {
    Json out = Json::object();
    if (suspended_) return out;
    for (auto& [k, s] : slots_)
        if (!s.root.is_null() && world.alive(s.root))
            out[key_text(k)] = entities_json(world, s.root, PrefabSave::Marks);
    return out;
}

void CellEdit::restore(World& world, const Json& snap, const Json& keep) {
    suspended_ = false;
    std::vector<Key> failed;
    for (auto& [k, s] : slots_) {
        const std::string kt = key_text(k);
        Json entities;
        const Json* from = nullptr;
        if (snap.is_object()) {
            auto it = snap.find(kt);
            if (it != snap.end() && it->is_array()) from = &*it;
        }
        if (!from && keep.is_object()) {
            auto it = keep.find(kt);
            if (it != keep.end() && it->is_array()) from = &*it;
        }
        if (from) {
            entities = *from;
        } else {
            auto text = fs::read_text(s.scene);
            auto parsed = text.ok() ? parse_json(text.value(), s.scene) : Result<Json>(text.error());
            if (!parsed.ok() || !parsed.value().is_object()) {
                failed.push_back(k);
                continue;
            }
            const Json& doc = parsed.value();
            entities = doc.contains("entities") && doc["entities"].is_array() ? doc["entities"] : Json::array();
        }
        std::string err;
        s.root = Entity{};
        if (!place(world, k, s, entities, &err)) {
            warnings_ = err;
            failed.push_back(k);
        }
    }
    for (const Key& k : failed) slots_.erase(k);
    pending_ = true;
}

void CellEdit::reload(World& world) {
    for (auto& [k, s] : slots_) s.isNew = false;
    indexDirty_ = false;
    refresh(world, true);
    if (!hasIndex_) {
        slots_.clear();
        return;
    }
    restore(world, Json(), Json());
    for (auto& [k, s] : slots_) {
        s.baseline = s.current = s.root.is_null() ? 0 : fingerprint(world, s.root);
        if (const WorldCell* c = find_cell(k)) s.scene = c->scene;
    }
    pending_ = false;
}

// ------------------------------------------------------------------------------------------------ save
CellSaveReport CellEdit::save(World& world, bool only, std::int32_t onlyI, std::int32_t onlyJ) {
    CellSaveReport rep;
    auto fail = [&](const std::string& m) {
        rep.ok = false;
        rep.error = m;
        return rep;
    };
    if (suspended_) return fail("Stop the game before saving cells (play-mode changes are temporary).");
    if (!hasIndex_ || (slots_.empty() && !indexDirty_)) return rep;
    pending_ = true;
    update(world, false);
    const Key onlyKey{onlyI, onlyJ};

    // 1. What moved to another cell (nothing is changed yet).
    struct Move {
        Entity e;
        Key to;
    };
    std::vector<Move> moves;
    std::set<Key> targets, sources;
    for (const auto& [k, s] : slots_) {
        if (only && !(k == onlyKey)) continue;
        if (s.root.is_null()) continue;
        for (Entity c : world.children(s.root)) {
            std::int32_t ti = 0, tj = 0;
            if (!destination_of(world, c, ti, tj)) continue;
            const Key to{ti, tj};
            if (to == k) continue;
            moves.push_back({c, to});
            targets.insert(to);
            sources.insert(k);
        }
    }
    // 2. Which cells are written, and whether every path is allowed, before anything changes.
    std::set<Key> writeSet = targets;
    for (const auto& [k, s] : slots_) {
        if (only && !(k == onlyKey)) continue;
        if (s.isNew || s.current != s.baseline) writeSet.insert(k);
    }
    for (const Key& k : sources) writeSet.insert(k);
    if (writeSet.empty() && !indexDirty_) return rep;
    auto allowed = [&](const std::string& path, const std::string& what) -> std::string {
        auto judged = fs::resolve_for_write(path, fs::WriteRoot::Project, false);
        if (!judged.ok())
            return what + " '" + path + "': " + judged.error().message +
                   (judged.error().hint.empty() ? "" : " (hint: " + judged.error().hint + ")");
        return {};
    };
    for (const Key& k : writeSet) {
        auto it = slots_.find(k);
        std::string path;
        if (it != slots_.end())
            path = it->second.scene;
        else if (const WorldCell* c = find_cell(k))
            path = c->scene;
        else
            path = new_cell_path(k);
        if (std::string bad = allowed(path, "Cell " + key_text(k)); !bad.empty())
            return fail(bad + " Nothing was saved.");
        if (it == slots_.end() && !find_cell(k) && fs::exists(path))
            return fail("Cell " + key_text(k) + " would be a new file '" + path +
                        "', but that file exists and is not in the index. Nothing was saved. Move or delete it, "
                        "or list it in the index.");
    }
    if (std::string bad = allowed(indexPath_, "The index"); !bad.empty()) return fail(bad + " Nothing was saved.");

    // 3. The cells that receive entities are loaded (or made).
    std::vector<Key> added;
    for (const Key& t : targets) {
        if (slots_.count(t)) continue;
        if (find_cell(t)) {
            std::string err;
            if (!load(world, t.i, t.j, &err)) {
                for (const Key& a : added) unload(world, a.i, a.j, true, nullptr);
                return fail(err + " Nothing was saved.");
            }
        } else {
            if (slots_.size() >= std::size_t(kMaxLoaded)) {
                for (const Key& a : added) unload(world, a.i, a.j, true, nullptr);
                return fail("Too many cells are loaded to add cell " + key_text(t) +
                            ". Unload some first. Nothing was saved.");
            }
            Slot s;
            s.scene = new_cell_path(t);
            s.top = Json::object({{"format", kSceneFormat}});
            s.isNew = true;
            s.root = make_root(world, t);
            slots_[t] = std::move(s);
        }
        added.push_back(t);
    }

    // 4. The re-file: the entity keeps its id, its components and its place in the new cell's order (appended).
    for (const Move& m : moves) {
        auto it = slots_.find(m.to);
        if (it == slots_.end() || it->second.root.is_null()) continue;
        world.set_parent(m.e, it->second.root, false);
        ++rep.moved;
    }
    pending_ = true;
    update(world, false);

    // 5. The files' text and the index they imply (validated before the first write).
    std::map<Key, Json> docs;
    WorldIndex next = index_;
    bool indexChange = false;
    const bool d3 = index_.dimension == WorldDimension::D3;
    for (const Key& k : writeSet) {
        auto it = slots_.find(k);
        if (it == slots_.end() || it->second.root.is_null()) continue;
        Slot& s = it->second;
        Json file = s.top;
        if (!file.is_object()) file = Json::object();
        if (!file.contains("format")) file["format"] = kSceneFormat;
        file["entities"] = entities_json(world, s.root, PrefabSave::Keep);
        // The bounds only grow: the plane rectangle is the cell's own, the height widens to what its entities need.
        double minY = 0, maxY = 0;
        bool haveY = false;
        if (d3)
            for (Entity c : world.children(s.root)) {
                const double y = world.absolute_position(c).y;
                minY = haveY ? std::min(minY, y) : y;
                maxY = haveY ? std::max(maxY, y) : y;
                haveY = true;
            }
        WorldCell* wc = nullptr;
        for (WorldCell& c : next.cells)
            if (c.i == k.i && c.j == k.j) wc = &c;
        if (!wc) {
            WorldCell n;
            n.i = k.i;
            n.j = k.j;
            n.scene = s.scene;
            const double a0 = next.originA + double(k.i) * next.cellSize,
                         b0 = next.originB + double(k.j) * next.cellSize;
            if (d3) {
                n.boundsMin = Vec3{float(a0), float(haveY ? minY : 0.0), float(b0)};
                n.boundsMax = Vec3{float(a0 + next.cellSize), float(haveY ? maxY : 0.0), float(b0 + next.cellSize)};
            } else {
                n.boundsMin = Vec3{float(a0), float(b0), 0.0f};
                n.boundsMax = Vec3{float(a0 + next.cellSize), float(b0 + next.cellSize), 0.0f};
            }
            n.sizeBytes = std::int64_t(dump_scene_json(file).size());
            next.cells.push_back(std::move(n));
            indexChange = true;
        } else if (d3 && haveY && (float(minY) < wc->boundsMin.y || float(maxY) > wc->boundsMax.y)) {
            wc->boundsMin.y = std::min(wc->boundsMin.y, float(minY));
            wc->boundsMax.y = std::max(wc->boundsMax.y, float(maxY));
            if (wc->sizeBytes >= 0) wc->sizeBytes = std::int64_t(dump_scene_json(file).size());
            indexChange = true;
        }
        docs[k] = std::move(file);
    }
    std::sort(next.cells.begin(), next.cells.end(),
              [](const WorldCell& x, const WorldCell& y) { return x.j != y.j ? x.j < y.j : x.i < y.i; });
    const bool writeIndex = indexChange || indexDirty_;
    if (writeIndex) {
        WorldIndexOptions opts;
        opts.checkFiles = false;
        auto checked = parse_world_index(world_index_to_json(next), indexPath_, opts);
        if (!checked.ok())
            return fail("The index would be invalid after this save: " + checked.error().message + " (" +
                        checked.error().hint +
                        ") Nothing was written; the entities stay where they are in the editor.");
    }

    // 6. Writes: the cells that receive entities first, so a failure in between leaves an entity twice, never lost.
    std::vector<Key> order(targets.begin(), targets.end());
    for (const Key& k : writeSet)
        if (!targets.count(k)) order.push_back(k);
    for (const Key& k : order) {
        auto d = docs.find(k);
        if (d == docs.end()) continue;
        Slot& s = slots_[k];
        auto w = save_scene_json_file(s.scene, d->second);
        if (!w.ok()) {
            if (writeIndex) {
                index_ = next;
                indexDirty_ = true;  // the next Save writes it
            }
            return fail("Cannot write cell " + key_text(k) + " '" + s.scene + "': " + w.error().message +
                        (w.error().hint.empty() ? "" : " (hint: " + w.error().hint + ")"));
        }
        s.baseline = s.current;
        s.isNew = false;
        rep.written.push_back(s.scene);
    }
    if (writeIndex) {
        index_ = next;
        auto w = fs::write_text(indexPath_, dump_json(world_index_to_json(next)));
        if (!w.ok()) {
            indexDirty_ = true;
            return fail("The cells were written but the index '" + indexPath_ + "' was not: " + w.error().message +
                        ". Save again.");
        }
        indexDirty_ = false;
        rep.indexWritten = true;
    }
    return rep;
}

}  // namespace fa::editor
