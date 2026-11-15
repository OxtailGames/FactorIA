#include "frame_graph.h"

#include <algorithm>
#include <chrono>
#include <map>
#include <set>

#include "fa/core/strings.h"

namespace fa::render {

namespace {

const char* format_name(sg_pixel_format f) {
    switch (f) {
        case SG_PIXELFORMAT_NONE: return "none";
        case SG_PIXELFORMAT_RGBA8: return "rgba8";
        case SG_PIXELFORMAT_RGBA16F: return "rgba16f";
        case SG_PIXELFORMAT_DEPTH: return "depth";
        case SG_PIXELFORMAT_DEPTH_STENCIL: return "depth_stencil";
        default: return nullptr;
    }
}

Json format_json(sg_pixel_format f) {
    if (const char* n = format_name(f)) return n;
    return int(f);  // a format with no short name: sokol's enum value
}

Json target_format_json(const TargetFormat& f) {
    Json j = Json::object();
    j["color"] = format_json(f.color);
    j["depth"] = format_json(f.depth);
    j["samples"] = f.samples;
    return j;
}

std::string qname(const std::string& s) { return "'" + s + "'"; }

}  // namespace

ResourceId FrameGraph::import_target(const std::string& name, std::uint64_t handle, const TransientDesc& desc) {
    Resource r;
    r.name = name;
    r.imported = true;
    r.handle = handle;
    r.desc = desc;
    if (r.desc.label.empty()) r.desc.label = name;
    resources_.push_back(std::move(r));
    compiled_ = false;
    return ResourceId{std::uint32_t(resources_.size() - 1)};
}

bool FrameGraph::set_import_handle(ResourceId r, std::uint64_t handle, const TransientDesc* desc) {
    if (!r.valid() || r.index >= resources_.size() || !resources_[r.index].imported) return false;
    Resource& res = resources_[r.index];
    res.handle = handle;
    if (desc) {
        const std::string label = res.desc.label;
        res.desc = *desc;
        if (res.desc.label.empty()) res.desc.label = label;
    }
    return true;
}

ResourceId FrameGraph::create_transient(const TransientDesc& desc) {
    Resource r;
    r.name = desc.label.empty() ? "transient" + std::to_string(resources_.size()) : desc.label;
    r.desc = desc;
    resources_.push_back(std::move(r));
    compiled_ = false;
    return ResourceId{std::uint32_t(resources_.size() - 1)};
}

int FrameGraph::add_pass(GraphPass pass) {
    passes_.push_back(std::move(pass));
    compiled_ = false;
    released_ = false;
    return int(passes_.size() - 1);
}

void FrameGraph::clear() {
    resources_.clear();
    passes_.clear();
    culled_.clear();
    order_.clear();
    stats_.clear();
    physical_.clear();
    breaks_.clear();
    slotCount_ = 0;
    compiled_ = false;
    released_ = false;
}

void FrameGraph::release_callbacks() {
    for (GraphPass& p : passes_) p.execute = nullptr;
    released_ = true;
}

const std::string& FrameGraph::resource_name(ResourceId r) const { return resources_[r.index].name; }

Result<void> FrameGraph::compile() {
    compiled_ = false;
    const int n = int(passes_.size());
    order_.clear();
    breaks_.clear();
    culled_.assign(std::size_t(n), false);
    slotCount_ = 0;
    for (Resource& r : resources_) {
        r.firstUse = r.lastUse = r.slot = -1;
    }

    // Resources: names are unique, transients have a size, imported ones a handle.
    {
        std::map<std::string, std::size_t> resByName;
        for (std::size_t i = 0; i < resources_.size(); ++i) {
            const Resource& r = resources_[i];
            auto ins = resByName.emplace(r.name, i);
            if (!ins.second) {
                return make_error(
                    "Frame graph: two resources are named " + qname(r.name) + " (#" +
                        std::to_string(ins.first->second) + " and #" + std::to_string(i) + ").",
                    "Resource names must be unique (dumps and errors name resources by them); give one of "
                    "them another label in import_target() or create_transient().");
            }
            if (r.imported && r.handle == 0) {
                return make_error("Frame graph: the imported resource " + qname(r.name) + " has handle 0.",
                                  "Pass the id of the target the renderer owns to import_target(), or rebind it with "
                                  "set_import_handle() before compile(); 0 means no target.");
            }
            if (!r.imported && (r.desc.width <= 0 || r.desc.height <= 0)) {
                return make_error("Frame graph: the transient " + qname(r.name) + " has size " +
                                      std::to_string(r.desc.width) + "x" + std::to_string(r.desc.height) + ".",
                                  "Give create_transient() a width and a height of at least 1 pixel.");
            }
        }
    }

    // Names and ids.
    std::map<std::string, int> byName;
    std::vector<std::string> names;
    for (int i = 0; i < n; ++i) {
        const GraphPass& p = passes_[std::size_t(i)];
        if (p.name.empty()) {
            return make_error("Frame graph: pass #" + std::to_string(i) + " has no name.",
                              "Give every pass a unique name; it appears in errors, stats and render dumps.");
        }
        auto ins = byName.emplace(p.name, i);
        if (!ins.second) {
            return make_error("Frame graph: two passes are named " + qname(p.name) + " (#" +
                                  std::to_string(ins.first->second) + " and #" + std::to_string(i) + ").",
                              "Pass names must be unique; add the camera or the target to one of them.");
        }
        names.push_back(p.name);
    }
    for (int i = 0; i < n; ++i) {
        const GraphPass& p = passes_[std::size_t(i)];
        for (const std::vector<ResourceId>* list : {&p.reads, &p.writes}) {
            for (ResourceId r : *list) {
                if (!r.valid() || r.index >= resources_.size()) {
                    return make_error("Frame graph: pass " + qname(p.name) +
                                          " uses a resource that was never declared.",
                                      "Get every ResourceId from import_target() or create_transient() of this graph.");
                }
            }
        }
        for (const std::string& a : p.after) {
            if (!byName.count(a)) {
                const std::string dym = did_you_mean(a, names);
                const std::string suggestion = dym.empty() ? std::string() : " " + dym;
                return make_error("Frame graph: pass " + qname(p.name) + " must run after " + qname(a) +
                                      ", which is not a pass." + suggestion,
                                  "Declare the pass " + qname(a) + " or remove it from the after list of " +
                                      qname(p.name) + ".");
            }
        }
    }

    // Dependencies.
    std::vector<std::vector<Edge>> preds(static_cast<std::size_t>(n));
    auto add_edge = [&](int from, int to, bool data) {
        if (from == to) return;
        for (Edge& e : preds[std::size_t(to)]) {
            if (e.from == from) {
                e.data = e.data || data;
                return;
            }
        }
        preds[std::size_t(to)].push_back(Edge{from, data});
    };
    std::vector<int> lastWriter(resources_.size(), -1);
    std::vector<std::vector<int>> readers(resources_.size());
    for (int i = 0; i < n; ++i) {
        const GraphPass& p = passes_[std::size_t(i)];
        for (ResourceId r : p.reads) {
            int w = lastWriter[r.index];
            if (w >= 0) {
                add_edge(w, i, true);
            } else if (!resources_[r.index].imported) {
                // Written later or never: either way this pass would sample garbage.
                int later = -1;
                for (int k = i + 1; k < n && later < 0; ++k) {
                    for (ResourceId wr : passes_[std::size_t(k)].writes) {
                        if (wr == r) later = k;
                    }
                }
                std::string msg = "Frame graph: pass " + qname(p.name) + " reads " + qname(resource_name(r)) +
                                  ", but no pass declared before it writes it";
                std::string hint;
                if (later >= 0) {
                    const std::string& lp = passes_[std::size_t(later)].name;
                    msg += " (" + qname(lp) + " writes it, but is declared after).";
                    hint = "Declare " + qname(lp) + " before " + qname(p.name) + ".";
                } else {
                    msg += " (nothing writes it).";
                    hint = "Add a pass that writes " + qname(resource_name(r)) + " before " + qname(p.name) +
                           ", or import the target if it already has contents.";
                }
                return make_error(std::move(msg), std::move(hint));
            }
            readers[r.index].push_back(i);
        }
        for (ResourceId r : p.writes) {
            if (lastWriter[r.index] >= 0) add_edge(lastWriter[r.index], i, true);
            for (int k : readers[r.index]) add_edge(k, i, false);
            readers[r.index].clear();
            lastWriter[r.index] = i;
        }
        for (const std::string& a : p.after) add_edge(byName[a], i, false);
    }

    // Order: the ready pass with the smallest declaration index goes first.
    std::vector<int> degree(std::size_t(n), 0);
    std::vector<std::vector<int>> succs(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) {
        degree[std::size_t(i)] = int(preds[std::size_t(i)].size());
        for (const Edge& e : preds[std::size_t(i)]) succs[std::size_t(e.from)].push_back(i);
    }
    std::set<int> ready;
    for (int i = 0; i < n; ++i) {
        if (degree[std::size_t(i)] == 0) ready.insert(i);
    }
    std::vector<int> all;
    std::vector<bool> done(std::size_t(n), false);
    while (int(all.size()) < n) {
        if (ready.empty()) {
            if (cyclePolicy_ != CyclePolicy::Break) break;
            // A cycle: the pass declared first of those left goes next, without waiting for the passes that wait for it.
            int first = 0;
            while (done[std::size_t(first)]) ++first;
            CycleBreak cb;
            cb.pass = passes_[std::size_t(first)].name;
            std::vector<int> unmet;
            for (const Edge& e : preds[std::size_t(first)]) {
                if (!done[std::size_t(e.from)]) unmet.push_back(e.from);
            }
            std::sort(unmet.begin(), unmet.end());
            for (int u : unmet) cb.waitedFor.push_back(passes_[std::size_t(u)].name);
            breaks_.push_back(std::move(cb));
            ready.insert(first);
        }
        int p = *ready.begin();
        ready.erase(ready.begin());
        done[std::size_t(p)] = true;
        all.push_back(p);
        for (int s : succs[std::size_t(p)]) {
            if (done[std::size_t(s)]) continue;  // a pass that went first through a cycle break
            if (--degree[std::size_t(s)] == 0) ready.insert(s);
        }
    }
    if (int(all.size()) != n) {
        // Every pass left has a predecessor that is left too: walking predecessors must repeat one.
        int cur = 0;
        while (done[std::size_t(cur)]) ++cur;
        std::vector<int> walk;
        std::vector<int> seenAt(std::size_t(n), -1);
        while (seenAt[std::size_t(cur)] < 0) {
            seenAt[std::size_t(cur)] = int(walk.size());
            walk.push_back(cur);
            int next = -1;
            for (const Edge& e : preds[std::size_t(cur)]) {
                if (!done[std::size_t(e.from)] && (next < 0 || e.from < next)) next = e.from;
            }
            cur = next;
        }
        std::vector<int> cycle(walk.begin() + seenAt[std::size_t(cur)], walk.end());
        std::reverse(cycle.begin(), cycle.end());  // predecessors were walked: put it in running order
        std::string path;
        for (int c : cycle) path += qname(passes_[std::size_t(c)].name) + " -> ";
        path += qname(passes_[std::size_t(cycle.front())].name);
        return make_error("Frame graph: the passes form a cycle and none can run first: " + path + ".",
                          "Break the cycle: a pass cannot depend on a pass that depends on it. Remove an after() "
                          "entry of one of them, or give one of them another resource to read or write.");
    }

    // Cull: live = side effects, or writes an imported resource, or feeds a live pass.
    std::vector<bool> live(std::size_t(n), false);
    std::vector<int> work;
    for (int i = 0; i < n; ++i) {
        const GraphPass& p = passes_[std::size_t(i)];
        bool l = p.sideEffect;
        for (ResourceId r : p.writes) l = l || resources_[r.index].imported;
        if (l) {
            live[std::size_t(i)] = true;
            work.push_back(i);
        }
    }
    while (!work.empty()) {
        int p = work.back();
        work.pop_back();
        for (const Edge& e : preds[std::size_t(p)]) {
            if (e.data && !live[std::size_t(e.from)]) {
                live[std::size_t(e.from)] = true;
                work.push_back(e.from);
            }
        }
    }
    for (int p : all) {
        if (live[std::size_t(p)]) order_.push_back(p);
    }
    for (int i = 0; i < n; ++i) culled_[std::size_t(i)] = !live[std::size_t(i)];

    // Lifetimes of the transients, then alias slots (first fit, in order of first use).
    for (int pos = 0; pos < int(order_.size()); ++pos) {
        const GraphPass& p = passes_[std::size_t(order_[std::size_t(pos)])];
        for (const std::vector<ResourceId>* list : {&p.reads, &p.writes}) {
            for (ResourceId r : *list) {
                Resource& res = resources_[r.index];
                if (res.imported) continue;
                if (res.firstUse < 0) res.firstUse = pos;
                res.lastUse = pos;
            }
        }
    }
    std::vector<int> used;
    for (int i = 0; i < int(resources_.size()); ++i) {
        if (!resources_[std::size_t(i)].imported && resources_[std::size_t(i)].firstUse >= 0) used.push_back(i);
    }
    std::stable_sort(used.begin(), used.end(), [&](int a, int b) {
        return resources_[std::size_t(a)].firstUse < resources_[std::size_t(b)].firstUse;
    });
    std::vector<int> slotLast;
    std::vector<int> slotRep;  // a resource of the slot, for its shape
    for (int id : used) {
        Resource& r = resources_[std::size_t(id)];
        int slot = -1;
        for (int s = 0; s < int(slotLast.size()); ++s) {
            const Resource& rep = resources_[std::size_t(slotRep[std::size_t(s)])];
            if (slotLast[std::size_t(s)] < r.firstUse && rep.desc.same_shape(r.desc)) {
                slot = s;
                break;
            }
        }
        if (slot < 0) {
            slot = int(slotLast.size());
            slotLast.push_back(0);
            slotRep.push_back(id);
        }
        slotLast[std::size_t(slot)] = r.lastUse;
        r.slot = slot;
    }
    slotCount_ = slotLast.size();
    compiled_ = true;
    return {};
}

Result<void> FrameGraph::execute(TargetPool& pool) {
    if (released_) {
        return make_error("Frame graph: execute() called on a graph whose pass callbacks were released.",
                          "Declare the passes again (clear(), add_pass(), compile()) before executing.");
    }
    if (!compiled_) {
        return make_error("Frame graph: execute() called on a graph that is not compiled.",
                          "Call compile() after the last add_pass() and check its result.");
    }
    physical_.assign(resources_.size(), 0);
    for (std::size_t i = 0; i < resources_.size(); ++i) {
        if (resources_[i].imported) physical_[i] = resources_[i].handle;
    }
    stats_.clear();
    hookFailures_ = 0;
    // Gives every transient still held back to the pool on any way out (an error, a pass that throws).
    struct Release {
        const std::vector<Resource>& resources;
        std::vector<std::uint64_t>& physical;
        TargetPool& pool;
        ~Release() {
            for (std::size_t i = 0; i < resources.size(); ++i) {
                if (resources[i].imported || physical[i] == 0) continue;
                pool.release(physical[i]);
                physical[i] = 0;
            }
        }
    } release{resources_, physical_, pool};
    for (int pos = 0; pos < int(order_.size()); ++pos) {
        GraphPass& p = passes_[std::size_t(order_[std::size_t(pos)])];
        for (const std::vector<ResourceId>* list : {&p.reads, &p.writes}) {
            for (ResourceId r : *list) {
                Resource& res = resources_[r.index];
                if (res.imported || res.firstUse != pos || physical_[r.index] != 0) continue;
                physical_[r.index] = pool.acquire(res.desc);
                if (physical_[r.index] == 0) {
                    std::string msg = "Frame graph: the target pool could not create " + qname(res.name) + " (" +
                                      std::to_string(res.desc.width) + "x" + std::to_string(res.desc.height) +
                                      ") for pass " + qname(p.name) + ".";
                    return make_error(std::move(msg),
                                      "The GPU is out of memory or the size is invalid; check the size of the target.");
                }
            }
        }
        PassStats st;
        st.name = p.name;
        if (p.execute) {
            // Times the callback and calls the hooks on every way out of it, an exception included.
            struct Timed {
                const PassHooks& hooks;
                const std::string& name;
                double& cpuMs;
                int& failures;
                std::chrono::steady_clock::time_point t0;
                Timed(const PassHooks& h, const std::string& n, double& out, int& fails)
                    : hooks(h), name(n), cpuMs(out), failures(fails) {
                    if (hooks.begin) hooks.begin(name);
                    t0 = std::chrono::steady_clock::now();
                }
                ~Timed() {
                    cpuMs = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
                    // A destructor must not throw (an exception while one is unwinding is std::terminate): a hook
                    // that fails (a profiler zone that cannot allocate) loses its sample, not the frame; the
                    // loss is counted (hook_failures()).
                    try {
                        if (hooks.end) hooks.end(name, cpuMs);
                    } catch (...) {
                        ++failures;
                    }
                }
            } timed(hooks_, p.name, st.cpuMs, hookFailures_);
            p.execute(PassContext(*this, physical_, p));
        }
        stats_.push_back(std::move(st));
        for (const std::vector<ResourceId>* list : {&p.reads, &p.writes}) {
            for (ResourceId r : *list) {
                Resource& res = resources_[r.index];
                if (res.imported || res.lastUse != pos || physical_[r.index] == 0) continue;
                pool.release(physical_[r.index]);
                physical_[r.index] = 0;
            }
        }
    }
    for (int i = 0; i < int(passes_.size()); ++i) {
        if (culled_[std::size_t(i)]) {
            PassStats st;
            st.name = passes_[std::size_t(i)].name;
            st.culled = true;
            stats_.push_back(std::move(st));
        }
    }
    return {};
}

std::vector<std::string> FrameGraph::order_names() const {
    std::vector<std::string> out;
    if (!compiled_) return out;
    for (int p : order_) out.push_back(passes_[std::size_t(p)].name);
    return out;
}

std::vector<std::string> FrameGraph::culled_names() const {
    std::vector<std::string> out;
    if (!compiled_) return out;
    for (std::size_t i = 0; i < passes_.size(); ++i) {
        if (culled_[i]) out.push_back(passes_[i].name);
    }
    return out;
}

int FrameGraph::alias_slot(ResourceId r) const {
    return r.valid() && r.index < resources_.size() ? resources_[r.index].slot : -1;
}

Json FrameGraph::to_json() const {
    Json j = Json::object();
    j["compiled"] = compiled_;
    Json res = Json::array();
    for (const Resource& r : resources_) {
        Json o = Json::object();
        o["name"] = r.name;
        o["kind"] = r.imported ? "imported" : "transient";
        o["width"] = r.desc.width;
        o["height"] = r.desc.height;
        o["format"] = target_format_json(r.desc.format);
        if (!r.imported && compiled_) {
            o["firstUse"] = r.firstUse >= 0 ? Json(r.firstUse) : Json(nullptr);
            o["lastUse"] = r.lastUse >= 0 ? Json(r.lastUse) : Json(nullptr);
            o["aliasSlot"] = r.slot >= 0 ? Json(r.slot) : Json(nullptr);
        }
        res.push_back(std::move(o));
    }
    j["resources"] = std::move(res);
    auto rname = [&](ResourceId r) -> std::string {
        return r.valid() && r.index < resources_.size() ? resources_[r.index].name : std::string("?");
    };
    std::vector<int> pos(passes_.size(), -1);
    for (int i = 0; i < int(order_.size()); ++i) pos[std::size_t(order_[std::size_t(i)])] = i;
    Json ps = Json::array();
    for (std::size_t i = 0; i < passes_.size(); ++i) {
        const GraphPass& p = passes_[i];
        Json o = Json::object();
        o["name"] = p.name;
        Json rd = Json::array();
        Json wr = Json::array();
        for (ResourceId r : p.reads) rd.push_back(rname(r));
        for (ResourceId r : p.writes) wr.push_back(rname(r));
        o["reads"] = std::move(rd);
        o["writes"] = std::move(wr);
        o["after"] = p.after;
        o["sideEffect"] = p.sideEffect;
        if (compiled_) {
            o["culled"] = bool(culled_[i]);
            o["position"] = pos[i] >= 0 ? Json(pos[i]) : Json(nullptr);
        }
        ps.push_back(std::move(o));
    }
    j["passes"] = std::move(ps);
    j["order"] = compiled_ ? order_names() : std::vector<std::string>();
    j["culled"] = culled_names();
    Json breaks = Json::array();
    for (const CycleBreak& b : breaks_) {
        Json o = Json::object();
        o["pass"] = b.pass;
        o["waitedFor"] = b.waitedFor;
        breaks.push_back(std::move(o));
    }
    j["cycleBreaks"] = std::move(breaks);
    Json slots = Json::array();
    for (std::size_t s = 0; s < (compiled_ ? slotCount_ : 0); ++s) {
        Json names = Json::array();
        for (const Resource& r : resources_) {
            if (r.slot == int(s)) names.push_back(r.name);
        }
        Json o = Json::object();
        o["slot"] = int(s);
        o["resources"] = std::move(names);
        slots.push_back(std::move(o));
    }
    j["aliasSlots"] = std::move(slots);
    return j;
}

}  // namespace fa::render
