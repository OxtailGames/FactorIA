#include "renderer_foliage.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <format>
#include <numeric>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/scene/components_world.h"
#include "fa/scene/world.h"
#include "occlusion.h"
#include "render_scene.h"

namespace fa::render {

namespace {

constexpr std::size_t kMaxMeshes = 16;    // Foliage.meshes, kMaxScatterMeshes
constexpr std::uint64_t kStatEvery = 30;  // frames between two looks at the instances file's size and time

// True when the whole box (local space, carried by `m` = viewProj * model) is inside the clip volume: its instances need no test of their own.
bool box_fully_inside(const Mat4& m, bool z01, Vec3 lo, Vec3 hi) {
    for (int c = 0; c < 8; ++c) {
        const Vec4 p = m * Vec4{(c & 1) ? hi.x : lo.x, (c & 2) ? hi.y : lo.y, (c & 4) ? hi.z : lo.z, 1.0f};
        if (!(p.w > 0.0f) || p.x < -p.w || p.x > p.w || p.y < -p.w || p.y > p.w || p.z < (z01 ? 0.0f : -p.w) ||
            p.z > p.w)
            return false;
    }
    return true;
}

// The distance from `p` to the box lo..hi (0 inside it).
float distance_to_box(Vec3 p, Vec3 lo, Vec3 hi) {
    const Vec3 c{std::clamp(p.x, lo.x, hi.x), std::clamp(p.y, lo.y, hi.y), std::clamp(p.z, lo.z, hi.z)};
    return length(c - p);
}

}  // namespace

struct FoliageRenderer::Load {
    std::shared_ptr<const FoliageChunks> data;
    std::string error, hint;
};

namespace {

// Whether the last `n` characters of `s` are `lower` (a lower-case literal), whatever their case.
bool ends_with_nocase(const std::string& s, const char* lower, std::size_t n) {
    if (s.size() < n) return false;
    for (std::size_t i = 0; i < n; ++i)
        if (std::tolower(static_cast<unsigned char>(s[s.size() - n + i])) != lower[i]) return false;
    return true;
}

// What stops a Foliage from drawing anything, from its own fields ("" = nothing): the scene loader reports the same at load
// (foliage_problems), but a script or the inspector can change the fields while the game runs.
std::string foliage_field_problem(const Foliage& f) {
    if (!f.meshes.is_array() || f.meshes.empty())
        return "Foliage.meshes must be an array of 1 to 16 mesh names, it is empty or not an array";
    if (f.meshes.size() > kMaxMeshes)
        return std::format("Foliage.meshes holds {} meshes, at most {} are drawn", f.meshes.size(), kMaxMeshes);
    for (std::size_t i = 0; i < f.meshes.size(); ++i)
        if (!f.meshes[i].is_string() || f.meshes[i].get<std::string>().empty())
            return std::format("Foliage.meshes[{}] is not a mesh name (a non-empty string)", i);
    if (!std::isfinite(f.fadeStart) || !std::isfinite(f.fadeEnd) || !(f.fadeEnd > f.fadeStart))
        return std::format("Foliage.fadeEnd ({}) must be a number above fadeStart ({})", f.fadeEnd, f.fadeStart);
    return {};
}

}  // namespace

std::string foliage_lod_name(const std::string& mesh) {
    for (const char* ext : {".glb", ".gltf"}) {
        const std::size_t n = std::strlen(ext);
        if (mesh.size() <= n || !ends_with_nocase(mesh, ext, n)) continue;
        const std::string stem = mesh.substr(0, mesh.size() - n);
        if (ends_with_nocase(stem, ".lod1", 5)) return {};  // already a level
        return stem + ".lod1" + ext;                        // the name the bake writes: the extension in lower case
    }
    return {};
}

void FoliageRenderer::destroy() {
    entries_.clear();
    buckets_.clear();
    pruned_ = ~std::uint64_t(0);
}

bool FoliageRenderer::loading() const {
    for (const auto& [bits, en] : entries_)
        if (en->load && !en->handle.done()) return true;
    return false;
}

void FoliageRenderer::wait_loaded() {
    for (auto& [bits, en] : entries_)
        if (en->load && en->handle.valid()) (void)jobs::wait(en->handle);
}

std::size_t FoliageRenderer::bytes() const {
    std::size_t total = 0;
    for (const auto& [bits, en] : entries_)
        if (en->data)
            total += en->data->items.size() * sizeof(FoliagePacked) + en->data->chunks.size() * sizeof(FoliageChunk) +
                     en->kept.size() * sizeof(std::uint32_t);
    return total;
}

void FoliageRenderer::start_load(Entry& en, const std::string& file, std::size_t meshes) {
    auto load = std::make_shared<Load>();
    en.load = load;
    en.loadFile = file;
    en.loadMeshes = meshes;
    // The file's state first, then the read: a rewrite in between is found by the next look and read again.
    en.fileTime = fs::modified_time(file);
    en.fileSize = fs::file_size(file);
    ++loads_;
    en.handle = jobs::submit("render.foliage_load", [load, file, meshes] {
        // The file's bytes are freed when read_foliage returns, and the decoded instances when the chunks are built: the peak of a 2 million
        // instance file is the decoded list, the sort's keys and the chunked copy together (about 170 MB), never the file as well.
        [&] {
            auto r = read_foliage(file, meshes);
            if (!r) {
                load->error = r.error().message;
                load->hint = r.error().hint;
                return;
            }
            load->data = std::make_shared<const FoliageChunks>(build_foliage_chunks(*r));
        }();
    });
}

void FoliageRenderer::adopt(Entry& en, const std::string& entityId) {
    std::shared_ptr<Load> load = std::move(en.load);
    en.load.reset();
    en.handle = {};
    en.file = en.loadFile;
    en.meshCount = en.loadMeshes;
    en.kept.clear();
    en.keptDensity = -1.0f;
    if (load->data) {
        en.data = std::move(load->data);
        en.failed = false;
        en.warned.clear();
        return;
    }
    en.data.reset();
    en.failed = true;
    const std::string what = load->error.empty()
                                 ? std::format("foliage file '{}' was not read (the job was cancelled)", en.file)
                                 : load->error;
    const std::string said = load->hint.empty() ? what : what + " Hint: " + load->hint;
    if (said != en.warned) {
        en.warned = said;
        FA_WARN("render", "Foliage.instances on '{}': {} Nothing is drawn for it until the file is fixed.", entityId,
                said);
    }
}

FoliageRenderer::Counts FoliageRenderer::gather(const View& view, std::vector<MeshItem>& out,
                                                std::vector<char>& blended) {
    Counts counts;
    if (!view.world || !view.assets) return counts;
    World& world = *view.world;
    if (pruned_ != view.serial) {  // once a frame: what no camera asked for in the last few frames is forgotten
        pruned_ =
            view.serial;  // (a capture of another world between two frames of this one does not make it start over)
        for (auto it = entries_.begin(); it != entries_.end();) {
            if (view.serial > it->second->seen + 3)
                it = entries_.erase(it);
            else
                ++it;
        }
    }
    if (!world.any<Foliage>()) return counts;
    Assets& assets = *view.assets;
    const std::uint64_t generation = assets.reload_generation();
    const std::size_t maxItems = view.maxItems;

    // What one chunk that can show something is, and what one Foliage entity needs to turn its chunks into items.
    struct Cand {
        float dist = 0;
        std::uint32_t chunk = 0;
        bool shadowOnly = false, inside = false;
    };
    // The meshes, by (mesh, level): a MeshItem to copy for every instance.
    struct Group {
        MeshItem item;
        bool ready = false;
        char blended = 0;  // 0 = not known yet, 1 = drawn with the blended meshes, 2 = with the opaque ones
    };
    struct Job {
        Entry* en = nullptr;
        Entity entity;
        Mat4 model;
        const FoliageChunks* data = nullptr;
        std::size_t meshCount = 0, bucketBase = 0;
        std::vector<Group> grp;
        std::vector<Cand> cands;
        float wind = 0, freq = 0, fadeStart = 0, fadeEnd = 0, lodDistance = 0;
        std::uint32_t below = 0;
        bool castShadows = false;
    };
    std::vector<Job> fields;

    world.each<Foliage>([&](Entity e, Foliage& f) {
        if (!entity_active_in_scope(world, view.scopeRoot, e)) return;
        if (view.drawn && !view.drawn(e)) return;
        if (f.instances.empty()) return;  // none to draw: not a problem
        std::unique_ptr<Entry>& slot = entries_[{view.world, e.bits()}];
        if (!slot) slot = std::make_unique<Entry>();
        Entry& en = *slot;
        en.seen = view.serial;
        const std::string id = world.id_of(e);
        // What foliage_problems reports as an error draws nothing; said once here, for the fields a script changed after the load.
        std::string problem = foliage_field_problem(f);
        const Mat4 model = world.drawn_matrix(e);
        float sc = 0.0f;
        if (problem.empty()) {
            for (float v : model.m)
                if (!std::isfinite(v)) problem = "its transform holds a NaN or an infinite number";
            sc = std::min({length(Vec3{model.at(0, 0), model.at(0, 1), model.at(0, 2)}),
                           length(Vec3{model.at(1, 0), model.at(1, 1), model.at(1, 2)}),
                           length(Vec3{model.at(2, 0), model.at(2, 1), model.at(2, 2)})});
            if (problem.empty() && !(sc > 1e-6f))
                problem = "its transform scale is 0, so every instance collapses to a point";
        }
        if (!problem.empty()) {
            if (problem != en.problemSaid) {
                en.problemSaid = problem;
                FA_WARN(
                    "render",
                    "Foliage on '{}' draws nothing: {}. Hint: fix that field (or the transform) and it draws again.",
                    id, problem);
            }
            return;
        }
        en.problemSaid.clear();
        std::vector<std::string> names;
        for (const Json& m : f.meshes) names.push_back(m.get<std::string>());
        const std::string file = fs::normalize(f.instances);

        // The meshes: what the items point at; rebuilt when the list changes.
        if (en.names != names) {
            en.names = names;
            en.lodNames.assign(names.size(), std::string());
            en.lodCheck = ~std::uint64_t(0);
        }
        if (en.lodCheck != generation) {
            en.lodCheck = generation;
            for (std::size_t i = 0; i < names.size(); ++i) {
                const std::string lod = foliage_lod_name(names[i]);
                en.lodNames[i] = !lod.empty() && fs::exists(lod) ? lod : std::string();
            }
        }
        if (en.mrs.size() != names.size() * 2) {
            en.mrs.assign(names.size() * 2, MeshRenderer{});
            for (std::size_t i = 0; i < names.size(); ++i) en.mrs[i * 2].mesh = names[i];
        }
        for (std::size_t i = 0; i < names.size(); ++i) {
            en.mrs[i * 2].mesh = names[i];
            en.mrs[i * 2 + 1].mesh = en.lodNames[i].empty() ? names[i] : en.lodNames[i];
        }
        for (MeshRenderer& mr : en.mrs) mr.castShadows = f.castShadows;

        // The instances file: read off this thread; a finished read is adopted here; a new file or a rewrite starts another.
        if (en.load && en.handle.done()) adopt(en, id);
        if (en.file != file && en.data) {  // another file: the old instances are not this one's
            en.data.reset();
            en.kept.clear();
            en.keptDensity = -1.0f;
        }
        if (!en.load) {
            bool start = en.file != file || en.meshCount != names.size();
            if (!start && view.serial >= en.checkedAt + kStatEvery) {
                en.checkedAt = view.serial;
                start = fs::modified_time(file) != en.fileTime || fs::file_size(file) != en.fileSize;
            }
            if (start) {
                en.checkedAt = view.serial;
                en.failed = false;
                start_load(en, file, names.size());
                if (en.handle.done()) adopt(en, id);  // no workers: it ran inside submit()
            }
        }
        if (!en.data || en.file != file) return;
        const FoliageChunks& data = *en.data;
        const float density = std::isfinite(f.density) ? std::clamp(f.density, 0.0f, 1.0f) : 0.0f;
        if (en.keptDensity != density || en.kept.size() != data.chunks.size()) {
            en.keptDensity = density;
            en.kept.resize(data.chunks.size());
            for (std::size_t i = 0; i < data.chunks.size(); ++i)
                en.kept[i] = foliage_kept_count(data, data.chunks[i], density);
        }
        ++counts.entities;

        Job& job = fields.emplace_back();
        job.en = &en;
        job.entity = e;
        job.model = model;
        job.data = &data;
        job.meshCount = names.size();
        job.grp.resize(names.size() * 2);
        job.below = foliage_keep_below(density);
        job.castShadows = f.castShadows;
        job.wind = std::isfinite(f.windStrength) ? std::max(f.windStrength, 0.0f) : 0.0f;
        job.freq = std::isfinite(f.windFrequency) ? f.windFrequency : 0.0f;
        job.fadeStart = f.fadeStart;
        job.fadeEnd = f.fadeEnd;
        job.lodDistance = f.lodDistance;

        float radius = 0.0f;  // from the origin of an instance to its farthest corner, for scale 1
        for (std::size_t i = 0; i < names.size(); ++i) {
            MeshAsset* mesh = assets.mesh(names[i]);
            if (!mesh) continue;
            radius = std::max({radius, length(mesh->bmin), length(mesh->bmax)});
        }
        const Mat4 inverse = model.inverse();
        const Vec3 camLocal = inverse.transform_point(view.camera);
        const Mat4 viewModel = view.viewProj * model;
        const float windLocal = job.wind / sc;

        // The chunks that can show something.
        for (std::size_t ci = 0; ci < data.chunks.size(); ++ci) {
            const std::uint32_t kept = en.kept[ci];
            if (!kept) continue;
            const FoliageChunk& ch = data.chunks[ci];
            const float dmin = distance_to_box(camLocal, ch.lo, ch.hi) * sc;
            if (!(dmin < job.fadeEnd)) {  // beyond the fade, shadows too
                counts.culled += int(kept);
                continue;
            }
            const float infl = radius * ch.maxScale + windLocal;
            const Vec3 lo = ch.lo - Vec3{infl, infl, infl}, hi = ch.hi + Vec3{infl, infl, infl};
            Cand c;
            c.dist = dmin;
            c.chunk = std::uint32_t(ci);
            bool inView = box_in_frustum(view.viewProj, view.z01, lo, hi, model);
            if (inView && view.occlusion && view.occlusion->hidden(lo, hi, model)) {
                inView = false;
                if (f.castShadows)
                    c.shadowOnly = true;  // behind an Occluder, but its shadow can fall in the picture
                else {
                    counts.culled += int(kept);
                    continue;
                }
            } else if (!inView) {
                const float m = kFoliageShadowMargin / sc;
                const Vec3 mlo = lo - Vec3{m, m, m}, mhi = hi + Vec3{m, m, m};
                if (f.castShadows && box_in_frustum(view.viewProj, view.z01, mlo, mhi, model))
                    c.shadowOnly = true;
                else {
                    counts.culled += int(kept);
                    continue;
                }
            }
            c.inside = inView && box_fully_inside(viewModel, view.z01, lo, hi);
            job.cands.push_back(c);
        }
    });

    // The chunks of every entity together, nearest first (then in the order of the entities and of the files), so the cap of items keeps
    // the near ones whichever entity they are of.
    struct Ref {
        float dist;
        std::uint32_t job, cand;
    };
    std::vector<Ref> order;
    std::size_t want = 0, groupsTotal = 0;
    for (std::size_t j = 0; j < fields.size(); ++j) {
        fields[j].bucketBase = groupsTotal;
        groupsTotal += fields[j].grp.size();
        for (std::size_t k = 0; k < fields[j].cands.size(); ++k) {
            order.push_back({fields[j].cands[k].dist, std::uint32_t(j), std::uint32_t(k)});
            want += fields[j].data->chunks[fields[j].cands[k].chunk].count;
        }
    }
    std::stable_sort(order.begin(), order.end(), [](const Ref& a, const Ref& b) { return a.dist < b.dist; });
    if (buckets_.size() < groupsTotal) buckets_.resize(groupsTotal);
    // One reserve for the items and their flags, so the many appends of a big field never reallocate (a MeshItem is a few hundred bytes).
    const std::size_t room = std::min(want, maxItems);
    out.reserve(out.size() + room);
    blended.reserve(blended.size() + room);

    std::size_t budget = maxItems;
    bool capped = false;
    for (const Ref& ref : order) {
        Job& job = fields[ref.job];
        Entry& en = *job.en;
        const FoliageChunks& data = *job.data;
        const Cand& c = job.cands[ref.cand];
        const FoliageChunk& ch = data.chunks[c.chunk];
        if (budget < ch.count) {  // a chunk goes in whole or not at all
            counts.culled += int(en.kept[c.chunk]);
            capped = true;
            continue;
        }
        const auto prepare = [&](std::size_t g) -> Group& {
            Group& gr = job.grp[g];
            if (gr.ready) return gr;
            gr.ready = true;
            const std::size_t mi = g / 2;
            MeshAsset* mesh = assets.mesh(g % 2 ? en.mrs[g].mesh : en.names[mi]);
            MeshItem& it = gr.item;
            it.mesh = mesh;
            it.mr = &en.mrs[g];
            it.entity = job.entity;
            it.bmin = mesh->bmin;
            it.bmax = mesh->bmax;
            it.foliage = true;
            it.keyed = true;
            it.sortKey = kFoliageSortKey;
            return gr;
        };
        for (std::uint32_t k = 0; k < ch.count; ++k) {
            const FoliagePacked& p = data.items[ch.first + k];
            if (p.rank >= job.below) continue;
            if (p.mesh >= job.meshCount) continue;
            const Vec3 wp = job.model.transform_point(p.position);
            const float dist = length(wp - view.camera);
            const int step = foliage_fade_step(dist, job.fadeStart, job.fadeEnd);
            if (step < 0) {
                ++counts.culled;
                continue;
            }
            const std::size_t g =
                std::size_t(p.mesh) * 2 + ((dist >= job.lodDistance && !en.lodNames[p.mesh].empty()) ? 1 : 0);
            Group& gr = prepare(g);
            if (!gr.blended && gr.item.mesh) gr.blended = mesh_is_blended(en.mrs[g], *gr.item.mesh, nullptr) ? 1 : 2;
            Mat4 m = job.model * foliage_local_matrix(p);
            if (job.wind > 0.0f) {
                float dx = 0.0f, dz = 0.0f;
                foliage_sway(job.wind, job.freq, view.time, p.position.x, p.position.z, dx, dz);
                const float h = std::max(gr.item.bmax.y, 0.05f) * length(Vec3{m.at(1, 0), m.at(1, 1), m.at(1, 2)});
                if (h > 1e-6f) {  // the top moves by (dx, dz): a shear that grows with the height above the origin
                    const float kx = dx / h, kz = dz / h;
                    for (int col = 0; col < 3; ++col) {
                        m.at(col, 0) += kx * m.at(col, 1);
                        m.at(col, 2) += kz * m.at(col, 1);
                    }
                }
            }
            bool visible = !c.shadowOnly;
            if (visible && !c.inside) visible = box_in_frustum(view.viewProj, view.z01, gr.item.bmin, gr.item.bmax, m);
            if (!visible && !job.castShadows) {
                ++counts.culled;
                continue;
            }
            if (!visible) ++counts.culled;  // not in the picture; kept for the shadow maps
            MeshItem mi = gr.item;
            mi.model = m;
            mi.dist = dist;
            mi.visible = visible;
            mi.lodFade = step > 0 ? foliage_fade_amount(step) : 0.0f;
            buckets_[job.bucketBase + g].push_back(std::move(mi));
            --budget;
        }
    }
    for (const Job& job : fields) {
        for (std::size_t g = 0; g < job.grp.size(); ++g) {
            std::vector<MeshItem>& b = buckets_[job.bucketBase + g];
            const std::size_t n = b.size();
            for (MeshItem& mi : b) {
                out.push_back(std::move(mi));
                blended.push_back(job.grp[g].blended == 1 ? 1 : 0);
            }
            counts.items += int(n);
            b.clear();
            release_peak(b, n);
        }
    }
    if (capped && !capWarned_) {
        capWarned_ = true;
        FA_WARN(
            "render",
            "A camera is asked to draw more than {} Foliage instances at once: the farthest chunks are left out (the "
            "nearest are kept). "
            "Hint: lower Foliage.fadeEnd or density, or split the foliage over several entities that are far apart.",
            maxItems);
    }
    return counts;
}

}  // namespace fa::render
