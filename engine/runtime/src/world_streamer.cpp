// The world streamer: see fa/runtime/internal/world_streamer.h.
#include "fa/runtime/internal/world_streamer.h"

#include <algorithm>
#include <cmath>
#include <limits>

#include "fa/core/log.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"

namespace fa {

namespace {

constexpr double kInf = std::numeric_limits<double>::infinity();

std::int64_t count_subtree(const World& world, Entity e) {
    std::int64_t n = 1;
    for (Entity c : world.children(e)) n += count_subtree(world, c);
    return n;
}

struct Eval {
    bool want = false;  // nearer than the load radius of an anchor: load it
    bool keep = false;  // nearer than the unload radius of an anchor: do not unload it
    std::int32_t priority = std::numeric_limits<std::int32_t>::min();
    double distance = kInf;  // of the anchor that wants it (the best by priority, then distance)
    double nearest = kInf;   // to the nearest anchor, whatever it wants
};

}  // namespace

void absolute_plane_position(const WorldIndex& index, Vec3 local, double& a, double& b) {
    // The floating origin of M75.4 is added here (in doubles); until it is built the origin is 0.
    a = double(local.x);
    b = index.dimension == WorldDimension::D3 ? double(local.z) : double(local.y);
}

const char* WorldStreamer::state_name(State s) {
    switch (s) {
        case State::Unloaded: return "unloaded";
        case State::Queued: return "queued";
        case State::Loading: return "loading";
        case State::Loaded: return "loaded";
        case State::Unloading: return "unloading";
    }
    return "unloaded";
}

WorldStreamer::WorldStreamer(World& world, BackgroundLoader& loader) : world_(world), loader_(loader) {}

WorldStreamer::Settings WorldStreamer::read_settings() const {
    Settings s;
    const StreamedWorld* chosen = nullptr;
    const StreamedWorld* firstActive = nullptr;
    int enabledCount = 0;
    world_.each<StreamedWorld>([&](Entity e, StreamedWorld& c) {
        if (!world_.active_in_hierarchy(e)) return;
        if (!firstActive) firstActive = &c;
        if (c.enabled) {
            if (!chosen) chosen = &c;
            ++enabledCount;
        }
    });
    if (!chosen) chosen = firstActive;
    if (enabledCount > 1 && !warnedMultiple_) {
        warnedMultiple_ = true;
        FA_WARN("stream",
                "{} entities have an enabled StreamedWorld: the streamer uses the first one. Keep one StreamedWorld "
                "per scene (a second world "
                "is not streamed); disable or remove the others.",
                enabledCount);
    }
    if (!chosen) return s;
    s.found = true;
    s.enabled = chosen->enabled;
    s.world = chosen->world;
    s.maxLoads = std::clamp(int(chosen->maxLoadsInFlight), 1, kMaxLoadsInFlight);
    s.maxApplies = std::clamp(int(chosen->maxAppliesPerFrame), 1, kMaxAppliesPerFrame);
    s.keepLoaded = chosen->keepLoaded;
    s.cameraLoad = chosen->cameraLoadRadius;
    s.cameraUnload = chosen->cameraUnloadRadius;
    return s;
}

std::vector<WorldStreamer::Anchor> WorldStreamer::gather_anchors(const Settings& s) const {
    std::vector<Anchor> out;
    world_.each<StreamingAnchor>([&](Entity e, StreamingAnchor& a) {
        if (!a.enabled || !world_.active_in_hierarchy(e)) return;
        Anchor an;
        absolute_plane_position(index_, world_.world_position(e), an.a, an.b);
        if (!std::isfinite(an.a) || !std::isfinite(an.b))
            return;  // NaN or infinite position (a script's bug): it loads nothing
        an.loadRadius = std::max(0.0, double(a.loadRadius));
        an.unloadRadius = std::max(an.loadRadius, double(a.unloadRadius));
        an.priority = a.priority;
        out.push_back(an);
    });
    if (s.cameraLoad > 0.0f) {  // the active camera with the lowest depth (the first one on a tie)
        Entity best;
        std::int32_t bestDepth = std::numeric_limits<std::int32_t>::max();
        bool have = false;
        world_.each<Camera, Transform>([&](Entity e, Camera& c, Transform&) {
            if (!c.primary || !world_.active_in_hierarchy(e)) return;
            if (!have || c.depth < bestDepth) {
                have = true;
                best = e;
                bestDepth = c.depth;
            }
        });
        if (have) {
            Anchor an;
            absolute_plane_position(index_, world_.world_position(best), an.a, an.b);
            an.loadRadius = double(s.cameraLoad);
            an.unloadRadius = s.cameraUnload > s.cameraLoad ? double(s.cameraUnload) : double(s.cameraLoad) * 1.25;
            an.priority = 0;
            if (std::isfinite(an.a) && std::isfinite(an.b)) out.push_back(an);
        }
    }
    return out;
}

void WorldStreamer::load_index(const std::string& path) {
    WorldIndexOptions options;
    options.maxFileChecks = kEagerFileChecks;
    std::vector<WorldIndexIssue> issues;
    auto r = load_world_index(path, options, &issues);
    for (const WorldIndexIssue& is : issues)
        if (!is.error) FA_WARN("stream", "{}: {} {}", path + is.pointer, is.message, is.hint);
    if (!r) {
        failedPath_ = path;
        lastError_ = r.error().message + (r.error().hint.empty() ? std::string() : " " + r.error().hint);
        FA_WARN("stream", "{}", lastError_);
        return;
    }
    index_ = std::move(r.value());
    indexPath_ = path;
    failedPath_.clear();
    lastError_.clear();
    lastErrorCell_.clear();
    cells_.assign(index_.cells.size(), CellState{});
    minI_ = std::numeric_limits<std::int64_t>::max();
    maxI_ = std::numeric_limits<std::int64_t>::min();
    minJ_ = minI_;
    maxJ_ = maxI_;
    for (const WorldCell& c : index_.cells) {
        minI_ = std::min<std::int64_t>(minI_, c.i);
        maxI_ = std::max<std::int64_t>(maxI_, c.i);
        minJ_ = std::min<std::int64_t>(minJ_, c.j);
        maxJ_ = std::max<std::int64_t>(maxJ_, c.j);
    }
}

bool WorldStreamer::ensure_index() {
    if (indexPath_.empty()) {
        const Settings s = read_settings();
        settings_ = s;
        if (s.found && !s.world.empty() && s.world != failedPath_) load_index(s.world);
    }
    return !indexPath_.empty();
}

// The cells whose rectangle is within `radius` of the plane point (a, b): the cells of the index in the coordinate range around it (or all of
// them when the range holds more coordinates than the index has cells). Ascending index order.
std::vector<std::size_t> WorldStreamer::candidates(double a, double b, double radius) const {
    std::vector<std::size_t> out;
    if (index_.cells.empty()) return out;
    auto coord = [&](double v, double origin) {
        const double f = std::floor((v - origin) / index_.cellSize);
        return std::int64_t(std::clamp(f, -double(kMaxWorldCoord) - 1.0, double(kMaxWorldCoord) + 1.0));
    };
    const std::int64_t i0 = std::max(coord(a - radius, index_.originA), minI_);
    const std::int64_t i1 = std::min(coord(a + radius, index_.originA), maxI_);
    const std::int64_t j0 = std::max(coord(b - radius, index_.originB), minJ_);
    const std::int64_t j1 = std::min(coord(b + radius, index_.originB), maxJ_);
    if (i0 > i1 || j0 > j1) return out;
    const double range = double(i1 - i0 + 1) * double(j1 - j0 + 1);
    if (range > double(index_.cells.size())) {
        for (std::size_t k = 0; k < index_.cells.size(); ++k) {
            const WorldCell& c = index_.cells[k];
            if (c.i >= i0 && c.i <= i1 && c.j >= j0 && c.j <= j1) out.push_back(k);
        }
        return out;
    }
    // cells are sorted by (j, i): walk the range row by row, which is ascending index order
    for (std::int64_t j = j0; j <= j1; ++j)
        for (std::int64_t i = i0; i <= i1; ++i) {
            const WorldCell* c = index_.find(std::int32_t(i), std::int32_t(j));
            if (c) out.push_back(std::size_t(c - index_.cells.data()));
        }
    return out;
}

void WorldStreamer::set_state(std::size_t idx, State s) {
    cells_[idx].state = s;
    if (s == State::Unloaded)
        tracked_.erase(idx);
    else
        tracked_.insert(idx);
}

void WorldStreamer::cancel_cell(std::size_t idx) {
    CellState& st = cells_[idx];
    if (st.job != 0) {
        loader_.cancel(st.job, nullptr);  // running: stops; finished: gives back the files it kept warm
        ++loadsCancelled_;
    }
    st.job = 0;
    st.doc.reset();
    set_state(idx, State::Unloaded);
}

void WorldStreamer::send_event(const char* name, const WorldCell& cell, Json extra, Entity source) {
    Json data = Json::object(
        {{"world", indexPath_}, {"id", cell.id()}, {"coord", Json::array({cell.i, cell.j})}, {"scene", cell.scene}});
    for (auto it = extra.begin(); it != extra.end(); ++it) data[it.key()] = it.value();
    world_.events().game.push_back(GameEvent{name, std::move(data), source});
}

void WorldStreamer::do_apply(std::size_t idx) {
    CellState& st = cells_[idx];
    const WorldCell& cell = index_.cells[idx];
    const Entity root =
        world_.create("cell " + cell.id(), "cell_" + std::to_string(cell.i) + "_" + std::to_string(cell.j));
    world_.info(root).streamedCell = true;
    SceneLoadOptions opts;
    opts.additive = true;
    opts.parent = root;
    opts.streamedCell = true;
    const LoadReport report = load_scene(world_, *st.doc, cell.scene, opts);
    bool hadError = false;
    for (const LoadMessage& m : report.messages) {
        if (m.severity == LoadMessage::Severity::Error) {
            hadError = true;
            lastErrorCell_ = cell.id();
            lastError_ = m.to_string();
            FA_WARN("stream", "{}", m.to_string());
        } else {
            FA_WARN("stream", "{}", m.to_string());
        }
    }
    if (!hadError && lastErrorCell_ == cell.id()) {  // the cell that last failed loads fine now: the error is over
        lastError_.clear();
        lastErrorCell_.clear();
    }
    st.root = root;
    st.entities = count_subtree(world_, root) - 1;
    st.doc.reset();
    if (st.job != 0) loader_.cancel(st.job, nullptr);  // gives back the files the load kept warm
    st.job = 0;
    set_state(idx, State::Loaded);
    ++cellsApplied_;
    ++appliedThisFrame_;
    send_event("cellLoaded", cell, Json::object({{"entities", st.entities}, {"bytes", st.bytes}}), root);
}

void WorldStreamer::do_unload(std::size_t idx) {
    CellState& st = cells_[idx];
    const WorldCell& cell = index_.cells[idx];
    const std::int64_t entities = st.entities;
    if (world_.alive(st.root)) world_.destroy(st.root);
    st.root = Entity{};
    st.entities = 0;
    set_state(idx, State::Unloaded);
    ++unloadsDone_;
    ++unloadedThisFrame_;
    send_event("cellUnloaded", cell, Json::object({{"entities", entities}}), Entity{});
}

void WorldStreamer::drop_everything(bool sendEvents) {
    const std::vector<std::size_t> ids(tracked_.begin(), tracked_.end());
    for (std::size_t idx : ids) {
        const State s = cells_[idx].state;
        if (s == State::Loaded || s == State::Unloading) {
            if (sendEvents) {
                do_unload(idx);
            } else {
                if (world_.alive(cells_[idx].root)) world_.destroy(cells_[idx].root);
            }
        } else {
            cancel_cell(idx);
        }
    }
    tracked_.clear();
    failed_.clear();
    cells_.clear();
    index_ = WorldIndex{};
    indexPath_.clear();
    minI_ = 0;
    maxI_ = -1;
    minJ_ = 0;
    maxJ_ = -1;
}

void WorldStreamer::reset() {
    // The caller replaces the world: roots are gone with it. Cancel the jobs and forget everything, without destroying or sending anything.
    for (std::size_t idx : std::vector<std::size_t>(tracked_.begin(), tracked_.end())) {
        if (cells_[idx].state == State::Loading) cancel_cell(idx);
    }
    tracked_.clear();
    failed_.clear();
    cells_.clear();
    index_ = WorldIndex{};
    indexPath_.clear();
    failedPath_.clear();
    lastError_.clear();
    lastErrorCell_.clear();
    tick_ = 0;
    settings_ = Settings{};
    minI_ = 0;
    maxI_ = -1;
    minJ_ = 0;
    maxJ_ = -1;
    loadsStarted_ = loadsCancelled_ = cellsApplied_ = unloadsDone_ = bytesLoaded_ = 0;
    appliedThisFrame_ = unloadedThisFrame_ = unitsThisFrame_ = 0;
    anchorCount_ = 0;
    warnedMultiple_ = false;
}

void WorldStreamer::update() {
    ++tick_;
    settings_ = read_settings();
    const Settings& s = settings_;
    if (!s.found || s.world.empty()) {  // no streamed world (any more): what is loaded goes
        if (!indexPath_.empty() || !tracked_.empty()) drop_everything(true);
        anchorCount_ = 0;
        return;
    }
    if (s.world != indexPath_) {  // another index: the cells of the old one go before the new one is read
        if (!indexPath_.empty() || !tracked_.empty()) drop_everything(true);
        if (s.world == failedPath_) return;
        load_index(s.world);
        if (indexPath_.empty()) return;
    }

    // ---- which cells are wanted and which are kept -----------------------------------------------------------------------------------
    std::map<std::size_t, Eval> evals;  // by cell index: the order every tie-break uses
    std::vector<Anchor> anchors;
    if (s.enabled) anchors = gather_anchors(s);
    anchorCount_ = anchors.size();
    if (s.enabled && s.keepLoaded) {
        for (std::size_t k = 0; k < index_.cells.size(); ++k) {
            Eval& ev = evals[k];
            ev.want = ev.keep = true;
            ev.priority = 0;
            double nearest = kInf;
            for (const Anchor& an : anchors)
                nearest = std::min(nearest, index_.distance_to(index_.cells[k], an.a, an.b));
            ev.distance = std::isinf(nearest) ? 0.0 : nearest;
        }
    } else {
        for (const Anchor& an : anchors) {
            for (std::size_t k : candidates(an.a, an.b, an.unloadRadius)) {
                const double d = index_.distance_to(index_.cells[k], an.a, an.b);
                Eval& ev = evals[k];
                ev.nearest = std::min(ev.nearest, d);
                if (d <= an.unloadRadius) ev.keep = true;
                if (d <= an.loadRadius) {
                    if (!ev.want || an.priority > ev.priority || (an.priority == ev.priority && d < ev.distance)) {
                        ev.priority = an.priority;
                        ev.distance = d;
                    }
                    ev.want = true;
                    ev.keep = true;
                }
            }
        }
    }
    auto eval_of = [&](std::size_t k) -> Eval {
        auto it = evals.find(k);
        return it == evals.end() ? Eval{} : it->second;
    };

    // ---- what is no longer wanted ----------------------------------------------------------------------------------------------------
    for (std::size_t idx : std::vector<std::size_t>(tracked_.begin(), tracked_.end())) {
        const Eval ev = eval_of(idx);
        switch (cells_[idx].state) {
            case State::Loaded:
                if (!world_.alive(cells_[idx].root))  // something else removed it: forget it quietly
                    set_state(idx, State::Unloaded);
                else if (!ev.keep)
                    set_state(idx, State::Unloading);
                break;
            case State::Unloading:
                if (!world_.alive(cells_[idx].root))
                    set_state(idx, State::Unloaded);
                else if (ev.keep)
                    set_state(idx, State::Loaded);  // an anchor came back before the unload happened
                break;
            case State::Loading:
                if (!ev.keep) cancel_cell(idx);
                break;
            case State::Queued:
                if (!ev.want) set_state(idx, State::Unloaded);
                break;
            case State::Unloaded: break;
        }
    }
    // A failed cell is tried again once it has left the wanted set, or after kRetryTicks fixed ticks while it is still wanted (a
    // count, not a time: the same run retries on the same tick on every machine). Another index path forgets every failure at once.
    for (std::size_t idx : std::vector<std::size_t>(failed_.begin(), failed_.end()))
        if (!eval_of(idx).want || tick_ - cells_[idx].failedAtTick >= std::uint64_t(kRetryTicks)) {
            cells_[idx].failed = false;
            failed_.erase(idx);
        }

    // ---- what is wanted: queue it, then start the best ones that fit under maxLoadsInFlight ---------------------------------------
    for (const auto& [k, ev] : evals)
        if (ev.want && cells_[k].state == State::Unloaded && !cells_[k].failed) set_state(k, State::Queued);
    struct Queued {
        std::int32_t priority;
        double distance;
        std::size_t idx;
    };
    std::vector<Queued> queued;
    int inFlight = 0;
    for (std::size_t idx : tracked_) {
        if (cells_[idx].state == State::Loading) ++inFlight;
        if (cells_[idx].state == State::Queued) {
            const Eval ev = eval_of(idx);
            queued.push_back({ev.priority, ev.distance, idx});
        }
    }
    std::sort(queued.begin(), queued.end(), [](const Queued& x, const Queued& y) {
        if (x.priority != y.priority) return x.priority > y.priority;
        if (x.distance != y.distance) return x.distance < y.distance;
        return x.idx < y.idx;
    });
    for (const Queued& q : queued) {
        if (inFlight >= s.maxLoads) break;
        CellState& st = cells_[q.idx];
        const WorldCell& cell = index_.cells[q.idx];
        auto r = loader_.start(BackgroundLoader::Kind::CellLoad, {cell.scene}, std::nullopt,
                               BackgroundLoader::Origin::Tool, nullptr);
        if (!r) {
            st.failed = true;
            st.failedAtTick = tick_;
            failed_.insert(q.idx);
            set_state(q.idx, State::Unloaded);
            lastErrorCell_ = cell.id();
            lastError_ = "cell " + cell.id() + ": " + r.error().message;
            FA_WARN("stream", "{} {}", lastError_, r.error().hint);
            continue;
        }
        st.job = r.value();
        set_state(q.idx, State::Loading);
        ++loadsStarted_;
        ++inFlight;
    }
}

void WorldStreamer::apply(std::vector<BackgroundLoader::CellResult>& results, int units) {
    appliedThisFrame_ = 0;
    unloadedThisFrame_ = 0;
    unitsThisFrame_ = units;
    for (BackgroundLoader::CellResult& r : results) {
        std::size_t found = cells_.size();
        for (std::size_t idx : tracked_)
            if (cells_[idx].state == State::Loading && cells_[idx].job == r.id) {
                found = idx;
                break;
            }
        if (found == cells_.size()) {  // not ours (any more): give its files back
            loader_.cancel(r.id, nullptr);
            continue;
        }
        CellState& st = cells_[found];
        bytesLoaded_ += std::int64_t(r.bytes);
        st.bytes = r.bytes;
        if (!r.error.empty() || !r.scene) {
            st.failed = true;
            st.failedAtTick = tick_;
            failed_.insert(found);
            st.job = 0;
            lastErrorCell_ = index_.cells[found].id();
            lastError_ =
                "cell " + index_.cells[found].id() + ": " + r.error + (r.hint.empty() ? std::string() : " " + r.hint);
            FA_WARN("stream", "{}", lastError_);
            set_state(found, State::Unloaded);
            continue;
        }
        st.doc = std::move(r.scene);  // the job stays Loading until the main thread has applied it
    }
    results.clear();
    if (tracked_.empty()) return;
    int budget = std::clamp(settings_.maxApplies, 1, kMaxAppliesPerFrame);
    // Unloads first (they free memory), in index order; then the cells that are ready, in the order their jobs started.
    for (std::size_t idx : std::vector<std::size_t>(tracked_.begin(), tracked_.end())) {
        if (budget <= 0) break;
        if (cells_[idx].state == State::Unloading) {
            do_unload(idx);
            --budget;
        }
    }
    std::vector<std::size_t> ready;
    for (std::size_t idx : tracked_)
        if (cells_[idx].state == State::Loading && cells_[idx].doc) ready.push_back(idx);
    std::sort(ready.begin(), ready.end(), [&](std::size_t x, std::size_t y) { return cells_[x].job < cells_[y].job; });
    for (std::size_t idx : ready) {
        if (budget <= 0) break;
        do_apply(idx);
        --budget;
    }
}

Json WorldStreamer::cells(const std::string& stateFilter, std::size_t limit) {
    ensure_index();
    settings_ = read_settings();
    const std::vector<Anchor> anchors = settings_.enabled ? gather_anchors(settings_) : std::vector<Anchor>{};
    struct Row {
        std::size_t idx;
        double distance;
    };
    std::vector<Row> rows;
    for (std::size_t k = 0; k < index_.cells.size(); ++k) {
        if (!stateFilter.empty() && stateFilter != state_name(cells_[k].state)) continue;
        double d = kInf;
        for (const Anchor& an : anchors) d = std::min(d, index_.distance_to(index_.cells[k], an.a, an.b));
        rows.push_back({k, d});
    }
    std::stable_sort(rows.begin(), rows.end(), [](const Row& x, const Row& y) { return x.distance < y.distance; });
    Json list = Json::array();
    const bool plane2d = index_.dimension == WorldDimension::D2;
    for (const Row& row : rows) {
        if (list.size() >= limit) break;
        const WorldCell& c = index_.cells[row.idx];
        const CellState& st = cells_[row.idx];
        Json min = plane2d ? Json::array({c.boundsMin.x, c.boundsMin.y})
                           : Json::array({c.boundsMin.x, c.boundsMin.y, c.boundsMin.z});
        Json max = plane2d ? Json::array({c.boundsMax.x, c.boundsMax.y})
                           : Json::array({c.boundsMax.x, c.boundsMax.y, c.boundsMax.z});
        Json item = Json::object(
            {{"id", c.id()},
             {"coord", Json::array({c.i, c.j})},
             {"scene", c.scene},
             {"bounds", Json::object({{"min", min}, {"max", max}})},
             {"state", state_name(st.state)},
             {"entities", st.entities},
             {"distance", std::isinf(row.distance) ? Json() : Json(std::round(row.distance * 1000.0) / 1000.0)}});
        if (c.sizeBytes >= 0) item["sizeBytes"] = c.sizeBytes;
        if (st.failed) item["failed"] = true;
        list.push_back(std::move(item));
    }
    Json out = Json::object({{"world", indexPath_},
                             {"dimension", index_.dimension == WorldDimension::D3 ? "3d" : "2d"},
                             {"cellSize", index_.cellSize},
                             {"total", index_.cells.size()},
                             {"matching", rows.size()},
                             {"truncated", rows.size() > list.size()},
                             {"cells", list}});
    if (indexPath_.empty())
        out["error"] =
            lastError_.empty() ? std::string("no StreamedWorld with a world index in the scene") : lastError_;
    return out;
}

Json WorldStreamer::status() {
    ensure_index();
    settings_ = read_settings();
    if (settings_.enabled) anchorCount_ = gather_anchors(settings_).size();
    std::int64_t loaded = 0, loading = 0, queuedN = 0, unloading = 0, ready = 0;
    for (std::size_t idx : tracked_) {
        switch (cells_[idx].state) {
            case State::Loaded: ++loaded; break;
            case State::Loading:
                ++loading;
                if (cells_[idx].doc) ++ready;
                break;
            case State::Queued: ++queuedN; break;
            case State::Unloading: ++unloading; break;
            case State::Unloaded: break;
        }
    }
    Json pending = Json::array();
    std::vector<std::pair<int, std::size_t>>
        order;  // loading cells by job id (the order they were started), then the queued ones
    for (std::size_t idx : tracked_)
        if (cells_[idx].state == State::Loading) order.push_back({cells_[idx].job, idx});
    std::sort(order.begin(), order.end());
    for (const auto& o : order) pending.push_back(index_.cells[o.second].id());
    for (std::size_t idx : tracked_)
        if (cells_[idx].state == State::Queued) pending.push_back(index_.cells[idx].id());
    return Json::object({{"enabled", settings_.found && settings_.enabled},
                         {"world", indexPath_},
                         {"cellsTotal", index_.cells.size()},
                         {"cellsLoaded", loaded},
                         {"cellsLoading", loading},
                         {"cellsQueued", queuedN},
                         {"cellsUnloading", unloading},
                         {"inFlight", loading},
                         {"waitingToApply", ready},
                         {"queued", queuedN},
                         {"anchors", anchorCount_},
                         {"loadsStarted", loadsStarted_},
                         {"loadsCancelled", loadsCancelled_},
                         {"cellsApplied", cellsApplied_},
                         {"unloadsDone", unloadsDone_},
                         {"bytesLoaded", bytesLoaded_},
                         {"appliedThisFrame", appliedThisFrame_},
                         {"unloadedThisFrame", unloadedThisFrame_},
                         {"unitsThisFrame", unitsThisFrame_},
                         {"maxLoadsInFlight", settings_.found ? settings_.maxLoads : 0},
                         {"maxAppliesPerFrame", settings_.found ? settings_.maxApplies : 0},
                         {"pending", pending},
                         {"lastError", lastError_}});
}

}  // namespace fa
