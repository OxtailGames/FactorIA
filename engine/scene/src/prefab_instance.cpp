// How an entity differs from the prefab it was instantiated from: the scene entry {id, prefab, differences} that
// scene.save writes for an instance (docs/AI_GUIDE.md, section 6). The prefab is loaded into a scratch World and walked
// together with the entity; whatever differs becomes an override the loader (serialize.cpp, expand_prefab) applies back.
#include <algorithm>
#include <map>
#include <optional>
#include <unordered_map>

#include "fa/core/fs.h"
#include "fa/scene/serialize.h"
#include "serialize_internal.h"

namespace fa {

namespace detail {
// A prefab loaded once into a scratch World (see PrefabBaseCache).
struct PrefabBase {
    World world;
    Entity root;
    Json authored;      // the "entity" of the prefab file, as written: the override keys name its nodes
    std::string error;  // empty = loaded
};
}  // namespace detail

struct PrefabBaseCache::Impl {
    std::map<std::string, std::unique_ptr<detail::PrefabBase>> bases;
    // Every string value of every component of `stringsWorld`, counted: built the first time an instance has a descendant
    // whose id differs from the prefab's, to find out whether anything else names that id.
    bool stringsBuilt = false;
    std::unordered_map<std::string, int> strings;
};

PrefabBaseCache::PrefabBaseCache() : impl_(std::make_unique<Impl>()) {}
PrefabBaseCache::~PrefabBaseCache() = default;
void PrefabBaseCache::forget_world() {
    impl_->stringsBuilt = false;
    impl_->strings.clear();
}

namespace {

using detail::PrefabBase;

detail::PrefabBase& base_for(PrefabBaseCache::Impl& cache, const std::string& path) {
    auto& slot = cache.bases[path];
    if (slot) return *slot;
    slot = std::make_unique<PrefabBase>();
    PrefabBase& b = *slot;
    auto loaded = load_json_file(path);
    if (!loaded) {
        b.error = "the prefab '" + path + "' cannot be read: " + loaded.error().message;
        return b;
    }
    const Json& pj = loaded.value();
    if (!pj.is_object() || !pj.contains("entity") || !pj["entity"].is_object()) {
        b.error = "the prefab '" + path + "' has no \"entity\" object";
        return b;
    }
    b.authored = pj["entity"];
    LoadReport report;
    b.root = instantiate_prefab(b.world, path, kNullEntity, report);
    if (b.root.is_null()) b.error = "the prefab '" + path + "' does not load: " + report.summary();
    return b;
}

bool all_digits(const std::string& s, std::size_t from) {
    if (from >= s.size()) return false;
    for (std::size_t i = from; i < s.size(); ++i)
        if (s[i] < '0' || s[i] > '9') return false;
    return true;
}
// An id the world gave an entity of the prefab: the prefab's own, with the "_2" suffix World::create adds when the id is
// taken, or an automatic one ("e12") for an entity the prefab file gives no id.
bool id_compatible(const std::string& prefabId, const std::string& id) {
    if (prefabId == id) return true;
    const auto automatic = [](const std::string& s) { return s.size() > 1 && s[0] == 'e' && all_digits(s, 1); };
    if (automatic(prefabId) && automatic(id)) return true;
    return id.size() > prefabId.size() + 1 && id.compare(0, prefabId.size(), prefabId) == 0 && id[prefabId.size()] == '_' &&
           all_digits(id, prefabId.size() + 1);
}

void count_strings(const Json& j, std::unordered_map<std::string, int>& out) {
    if (j.is_string()) ++out[j.get<std::string>()];
    else if (j.is_object() || j.is_array())
        for (const Json& v : j) count_strings(v, out);
}
void count_entity_strings(const World& w, Entity e, std::unordered_map<std::string, int>& out) {
    for (const TypeInfo* t : w.components_of(e))
        if (t->name != "EntityInfo") count_strings(component_to_json(w, e, *t, false, false), out);
}
void count_subtree_strings(const World& w, Entity e, std::unordered_map<std::string, int>& out) {
    count_entity_strings(w, e, out);
    for (Entity c : w.children(e)) count_subtree_strings(w, c, out);
}

Json tags_json(const std::vector<std::string>& tags) {
    Json a = Json::array();
    for (const std::string& t : tags) a.push_back(t);
    return a;
}

struct Pair {
    Entity b, c;               // the prefab's entity and the entity that stands for it
    Json* node = nullptr;      // its node in the prefab file (null inside a nested prefab: no override key can name it)
    std::vector<Json*> chain;  // the nodes from the root's child down to `node`
};

class Differ {
public:
    Differ(const World& cur, PrefabBaseCache::Impl& cache, PrefabBase& base, const PrefabDiffOptions& opt,
           const EntityJsonOptions& childOpts, std::string path)
        : cw_(cur), cache_(cache), base_(base), bw_(base.world), opt_(opt), childOpts_(childOpts), path_(std::move(path)) {}

    PrefabDiff run(Entity root) {
        PrefabDiff out;
        std::vector<Json*> chain;
        root_ = root;
        if (!pair_tree(base_.root, root, &base_.authored, chain, true)) return inexpressible();
        Json rootNode = Json::object();
        Json overrides = Json::object();
        for (const Pair& p : pairs_) {
            Json node = Json::object();
            if (!diff_node(p, node)) return inexpressible();
            if (&p == &pairs_.front()) {
                rootNode = std::move(node);
            } else if (!node.empty()) {
                const std::string key = override_key(p);
                if (key.empty()) return inexpressible();
                overrides[key] = std::move(node);
            }
        }
        Json entry = Json::object();
        entry["id"] = cw_.info(root).id;
        entry["prefab"] = path_;
        for (const char* k : {"name", "tags", "active", "components"})
            if (rootNode.contains(k)) entry[k] = rootNode[k];
        if (!overrides.empty()) entry["overrides"] = std::move(overrides);
        if (!added_.empty()) {
            Json kids = Json::array();
            for (Entity x : added_) kids.push_back(entity_to_json(cw_, x, childOpts_));
            entry["children"] = std::move(kids);
            changes_ += added_.size();
        }
        if (childOpts_.skipSpawned)
            for (Entity x : skippedSpawned_) detail::skip_spawned_entity(cw_, x, childOpts_);
        out.expressible = true;
        out.entry = std::move(entry);
        out.changes = changes_;
        return out;
    }

private:
    PrefabDiff inexpressible() {
        PrefabDiff out;
        out.reason = reason_.empty() ? "the differences cannot be written as overrides" : reason_;
        return out;
    }
    bool fail(std::string why) {
        if (reason_.empty()) reason_ = std::move(why);
        return false;
    }

    // Pairs the prefab's entities with the entity's, in the order of a pre-order walk; the root is pairs_.front().
    bool pair_tree(Entity b, Entity c, Json* node, std::vector<Json*>& chain, bool isRoot) {
        const EntityInfo& bi = bw_.info(b);
        const EntityInfo& ci = cw_.info(c);
        if (!isRoot && !id_compatible(bi.id, ci.id))
            return fail("the id of '" + bi.id + "', a part of the prefab, was changed to '" + ci.id + "'");
        // The saved instance does not keep a descendant's id: loading it gives the prefab's id (or the next free one), so a
        // different id would dangle for a string elsewhere in the scene that names it.
        if (!isRoot && bi.id != ci.id && id_referenced(ci.id))
            return fail("the id '" + ci.id + "' of a part of the prefab ('" + bi.id + "') differs from the prefab's and is named by a string "
                        "elsewhere in the scene (a value equal to the id; an id inside a longer text or a script's find_by_id is not "
                        "looked for), which would no longer find it once the instance is loaded again");
        pairs_.push_back({b, c, node, chain});
        map_[b.bits()] = c;

        std::vector<Entity> cch;
        for (Entity x : cw_.children(c)) {
            if (childOpts_.skipSpawned && cw_.info(x).scriptSpawned) {
                skippedSpawned_.push_back(x);
                continue;
            }
            cch.push_back(x);
        }
        const std::vector<Entity>& bch = bw_.children(b);
        const std::size_t nb = bch.size();
        if (cch.size() < nb) return fail("a child of the prefab was removed from '" + ci.id + "'");
        for (std::size_t i = 0; i < cch.size() && opt_.useMarks; ++i)
            if (cw_.info(cch[i]).fromPrefab != (i < nb))
                return fail("the children of '" + ci.id + "' were reordered, or a child of the prefab was replaced");
        if (!isRoot && cch.size() > nb)
            return fail("'" + cw_.info(cch[nb]).id + "' was added under '" + ci.id + "', a part of the prefab (an instance can only add children to its root)");
        if (isRoot) added_.assign(cch.begin() + std::ptrdiff_t(nb), cch.end());

        Json* kids = nullptr;
        if (node && !node->contains("prefab") && node->contains("children") && (*node)["children"].is_array() &&
            (*node)["children"].size() == nb &&
            std::all_of((*node)["children"].begin(), (*node)["children"].end(), [](const Json& k) { return k.is_object(); }))
            kids = &(*node)["children"];
        for (std::size_t i = 0; i < nb; ++i) {
            Json* childNode = kids ? &(*kids)[i] : nullptr;
            chain.push_back(childNode);
            const bool ok = pair_tree(bch[i], cch[i], childNode, chain, false);
            chain.pop_back();
            if (!ok) return false;
        }
        return true;
    }

    // True when a string value of a component outside this instance equals `id`.
    bool id_referenced(const std::string& id) {
        if (!cache_.stringsBuilt) {
            cache_.strings.clear();
            for (Entity e : cw_.entities()) count_entity_strings(cw_, e, cache_.strings);
            cache_.stringsBuilt = true;
        }
        const auto total = cache_.strings.find(id);
        if (total == cache_.strings.end()) return false;
        if (!inside_) {
            inside_ = std::unordered_map<std::string, int>();
            count_subtree_strings(cw_, root_, *inside_);
        }
        const auto own = inside_->find(id);
        return total->second > (own == inside_->end() ? 0 : own->second);
    }

    bool same_ref(Entity bt, Entity ct) const {
        const bool bAlive = !bt.is_null() && bw_.alive(bt);
        const bool cAlive = !ct.is_null() && cw_.alive(ct);
        if (!bAlive) return !cAlive;
        if (!cAlive) return false;
        const auto it = map_.find(bt.bits());
        return it != map_.end() && it->second == ct;
    }

    // name, tags, active and components of one pair: only what differs.
    bool diff_node(const Pair& p, Json& node) {
        const EntityInfo& bi = bw_.info(p.b);
        const EntityInfo& ci = cw_.info(p.c);
        if (ci.name != bi.name) { node["name"] = ci.name; ++changes_; }
        if (ci.tags != bi.tags) { node["tags"] = tags_json(ci.tags); ++changes_; }
        if (ci.active != bi.active) { node["active"] = ci.active; ++changes_; }

        for (const TypeInfo* t : bw_.components_of(p.b))
            if (t->name != "EntityInfo" && !cw_.get(p.c, *t))
                return fail("the component " + t->name + " of the prefab was removed from '" + ci.id + "'");

        Json comps = Json::object();
        for (const TypeInfo* t : cw_.components_of(p.c)) {
            if (t->name == "EntityInfo") continue;
            const void* co = cw_.get(p.c, *t);
            const void* bo = bw_.get(p.b, *t);
            if (!bo) {   // a component the prefab does not have: written whole
                Json full = component_to_json(cw_, p.c, *t, false, false);
                if (opt_.poseRest) detail::apply_pose_rest_values(*opt_.poseRest, p.c, *t, false, full);
                comps[t->name] = std::move(full);
                ++changes_;
                continue;
            }
            Json curAll = component_to_json(cw_, p.c, *t, true, false);
            if (opt_.poseRest) detail::apply_pose_rest_values(*opt_.poseRest, p.c, *t, true, curAll);
            Json fields = Json::object();
            for (const FieldInfo& f : t->fields) {
                if (!f.serialized) continue;
                const auto cv = curAll.find(f.name);
                if (cv == curAll.end()) continue;
                bool same;
                if (f.kind == FieldKind::Entity) {
                    same = same_ref(*static_cast<const Entity*>(f.ptr(bo)), *static_cast<const Entity*>(f.ptr(co)));
                } else {
                    const Json bv = detail::field_json(bw_, f, bo);
                    same = bv == *cv;
                    if (!same && bv.is_object() && cv->is_object()) {
                        // The loader deep-merges an override into the prefab's value: it cannot remove a key.
                        Json merged = bv;
                        json_merge(merged, *cv);
                        if (merged != *cv)
                            return fail(t->name + "." + f.name + " of '" + ci.id + "' lost a key of the prefab's value, which an override cannot remove");
                    }
                }
                if (!same) { fields[f.name] = *cv; ++changes_; }
            }
            if (!fields.empty()) comps[t->name] = std::move(fields);
        }
        if (!comps.empty()) node["components"] = std::move(comps);
        return true;
    }

    // The key of "overrides" that names the pair's node in the prefab file; empty (and reason_ set) when none does.
    std::string override_key(const Pair& p) {
        const std::string& id = cw_.info(p.c).id;
        if (!p.node) {
            fail("'" + id + "' is inside a prefab that the prefab itself instances, so no override key can name it");
            return {};
        }
        const auto names = [](const Json& n, const char* k) {
            return n.contains(k) && n[k].is_string() ? n[k].get<std::string>() : std::string();
        };
        const auto resolves = [&](const std::string& key) { return !key.empty() && detail::find_override_target(base_.authored, key) == p.node; };
        for (const char* k : {"id", "name"})
            if (const std::string key = names(*p.node, k); resolves(key)) return key;
        std::string path;
        for (const Json* n : p.chain) {
            std::string label = n ? names(*n, "id") : std::string();
            if (label.empty() && n) label = names(*n, "name");
            if (label.empty()) { path.clear(); break; }
            path += (path.empty() ? "" : "/") + label;
        }
        if (resolves(path)) return path;
        fail("'" + id + "' has neither an id nor a name in the prefab file that identifies it, so no override key can name it");
        return {};
    }

    const World& cw_;
    PrefabBaseCache::Impl& cache_;
    Entity root_;
    std::optional<std::unordered_map<std::string, int>> inside_;
    PrefabBase& base_;
    const World& bw_;
    const PrefabDiffOptions& opt_;
    const EntityJsonOptions& childOpts_;
    std::string path_;
    std::vector<Pair> pairs_;
    std::unordered_map<std::uint64_t, Entity> map_;
    std::vector<Entity> added_;
    std::vector<Entity> skippedSpawned_;
    std::size_t changes_ = 0;
    std::string reason_;
};

}  // namespace

PrefabDiff diff_entity_with_prefab(const World& world, Entity entity, std::string_view prefabPath, const PrefabDiffOptions& opts) {
    PrefabDiff none;
    if (!world.alive(entity)) { none.reason = "the entity is not alive"; return none; }
    if (prefabPath.empty()) { none.reason = "no prefab path"; return none; }
    PrefabBaseCache local;
    PrefabBaseCache::Impl& cache = opts.cache ? opts.cache->impl() : local.impl();
    detail::PrefabBase& base = base_for(cache, std::string(prefabPath));
    if (!base.error.empty()) { none.reason = base.error; return none; }
    EntityJsonOptions fallback;
    fallback.poseRest = opts.poseRest;
    Differ differ(world, cache, base, opts, opts.childOptions ? *opts.childOptions : fallback, std::string(prefabPath));
    return differ.run(entity);
}

}  // namespace fa
