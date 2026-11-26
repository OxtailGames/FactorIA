// The skinned meshes of the ray tracing scene (M79 P1k): one BLAS per skinned instance, the positions it is built from skinned by a compute
// kernel (rt_skin.glsl) and the BLAS refitted every frame. See rt_scene.h and docs/design/ARCHITECTURE_RT_SCENE.md, "Skinned meshes".
#include <algorithm>
#include <array>
#include <cmath>
#include <format>
#include <unordered_map>

#include "fa/core/log.h"
#include "render_internal.h"
#include "render_jobs.h"
#include "rt_scene.h"
#include "rt_skin.h"

namespace fa::render {

namespace {

std::uint64_t round_up(std::uint64_t v, std::uint64_t unit) { return (v + unit - 1) / unit * unit; }

std::uint32_t next_pow2_u32(std::uint32_t v) {
    std::uint32_t p = 1;
    while (p < v && p < (1u << 31)) p <<= 1;
    return p;
}

// A skinned BLAS is refitted every frame: built with allowUpdate, never compacted (a compacted structure cannot be refitted).
gpu::AccelBuildFlags skin_flags() {
    gpu::AccelBuildFlags f;
    f.allowUpdate = true;
    f.preferFastTrace = true;
    f.allowCompaction = false;
    return f;
}

// Whether the box of the bones moved from the box the BLAS was built for by more than kSkinExtentJump of that box's largest side
// (a NaN counts as a jump: a rebuild is always safe).
bool extent_jumped(const Vec3& builtMin, const Vec3& builtMax, const Vec3& min, const Vec3& max) {
    const float side = std::max({builtMax.x - builtMin.x, builtMax.y - builtMin.y, builtMax.z - builtMin.z, 1e-6f});
    const float limit = RtScene::kSkinExtentJump * side;
    const float d[6] = {std::fabs(min.x - builtMin.x), std::fabs(min.y - builtMin.y), std::fabs(min.z - builtMin.z),
                        std::fabs(max.x - builtMax.x), std::fabs(max.y - builtMax.y), std::fabs(max.z - builtMax.z)};
    for (float v : d)
        if (!(v <= limit)) return true;
    return false;
}

}  // namespace

void RtScene::warn_skin_budget(const std::string& key, std::uint32_t vertices) {
    if (warnedSkinned_) return;
    warnedSkinned_ = true;
    FA_WARN("render",
            "Ray tracing scene: skinned meshes over the budget are left out of the acceleration structure (e.g. '{}', "
            "{} vertices): the scene "
            "skins at most {} vertices of one part, {} vertices and {} instances in a frame (the nearest to the main "
            "camera stay), so what is "
            "left out casts no ray-traced shadow and appears in no reflection. Hint: use a mesh with fewer vertices (a "
            "lower LOD) for the "
            "skinned crowd, or fewer animated characters in view.",
            key, vertices, kRtSkinMaxPartVertices, kMaxSkinnedVertices, kMaxSkinnedInstances);
}

void RtScene::release_skin() {
    for (auto& [mesh, e] : meshes_) {
        for (SkinSource& s : e.sources) {
            if (s.vbView.id) device_->destroy_view(s.vbView);
            if (s.skinView.id) device_->destroy_view(s.skinView);
        }
        e.sources.clear();
    }
    for (auto& [id, b] : blas_) {
        if (!b.skinned) continue;
        if (b.outView.id) device_->destroy_view(b.outView);
        if (b.positions.id) device_->destroy_buffer(b.positions);
        b.outView = {};
        b.positions = {};
    }
    if (paletteView_.id) device_->destroy_view(paletteView_);
    if (paletteBuffer_.id) device_->destroy_buffer(paletteBuffer_);
    skinned_.clear();
    paletteRows_.clear();
    paletteCount_ = 0;
    paletteCapacity_ = 0;
    paletteView_ = {};
    paletteBuffer_ = {};
}

gpu::Pipeline RtScene::skin_kernel() const { return skinKernel ? skinKernel() : gpu::Pipeline{}; }

void RtScene::free_unseen_skinned() {
    if (skinned_.empty()) return;
    std::vector<std::uint32_t> gone;
    for (const auto& [id, b] : blas_)
        if (b.skinned && b.seen != frameCounter_) gone.push_back(id);
    for (std::uint32_t id : gone) free_blas(id);
}

std::uint32_t RtScene::skinned_blas(MeshEntry& entry, const MeshAsset& mesh, std::uint32_t part, std::uint64_t entity) {
    const SkinKey key{entity, &mesh, part};
    const std::uint64_t signature = entry.signature * 1099511628211ull + entry.version;
    if (auto f = skinned_.find(key); f != skinned_.end()) {
        Blas& old = blas_.at(f->second);
        if (old.signature == signature) {
            old.seen = frameCounter_;
            return old.id;
        }
        free_blas(f->second);  // the mesh's buffers changed: a new BLAS from the new ones
    }
    const SubMesh& sm = mesh.parts[part];
    const int indices = sm.indexCount - sm.indexCount % 3;
    Blas b;
    b.id = nextId_++;
    b.skinned = true;
    b.entity = entity;
    b.mesh = &mesh;
    b.part = part;
    b.signature = signature;
    b.vertexCount = std::uint32_t(sm.vertexCount);
    b.seen = frameCounter_;
    b.label = std::format("blas:{}#{}@{}", mesh.key, part, entity & 0xffffffffull);
    const auto fail = [&](const std::string& why) {
        b.state = State::Failed;
        warn_once(warnedBlasMake_, "a skinned mesh could not get an acceleration structure",
                  std::format("'{}' part {}: {} Its instances are not traced.", mesh.key, part, why));
    };
    gpu::BufferDesc bd;
    bd.size = std::size_t(b.vertexCount) * 3 * sizeof(float);
    bd.usage.storageBuffer = true;    // the kernel writes it
    bd.usage.accelBuildInput = true;  // the build reads it
    bd.usage.copyDst =
        true;  // sokol: a storage buffer with no initial data is made with copy_dst (the shader fills it)
    bd.label = b.label.c_str();
    b.positions = device_->make_buffer(bd);
    if (device_->state(b.positions) != gpu::ResourceState::Valid) {
        if (b.positions.id) device_->destroy_buffer(b.positions);
        b.positions = {};
        fail("the buffer of the skinned positions could not be made.");
    } else {
        gpu::ViewDesc vd;
        vd.storageBuffer.buffer = b.positions;
        vd.label = b.label.c_str();
        b.outView = device_->make_view(vd);
        if (device_->state(b.outView) != gpu::ResourceState::Valid) {
            if (b.outView.id) device_->destroy_view(b.outView);
            b.outView = {};
            device_->destroy_buffer(b.positions);
            b.positions = {};
            fail("the view of the skinned positions could not be made.");
        }
    }
    if (b.state != State::Failed) {
        b.triangles.vertexBuffer = b.positions;
        b.triangles.vertexOffset = 0;
        b.triangles.vertexStride = 3 * sizeof(float);
        b.triangles.vertexCount = b.vertexCount;
        b.triangles.vertexFormat = gpu::VertexFormat::Float3;
        b.triangles.indexBuffer = sm.ib;
        b.triangles.indexOffset = std::size_t(std::max(sm.ibOffset, 0));
        b.triangles.indexType = gpu::IndexType::Uint32;
        b.triangles.indexCount = std::uint32_t(indices);
        b.triangles.opaque =
            false;  // the instance forces it opaque where the material has no alpha test (like the static BLASes)
        const std::array<gpu::AccelTriangles, 1> geometry{b.triangles};
        const Result<gpu::AccelSizes> sizes = device_->blas_sizes(geometry, skin_flags());
        if (!sizes) {
            fail(sizes.error().message);
        } else {
            gpu::AccelStructureDesc d;
            d.kind = gpu::AccelKind::Blas;
            d.size = sizes.value().structure;
            d.label = b.label.c_str();
            const Result<gpu::AccelStructure> made = device_->make_accel_structure(d);
            if (!made) {
                fail(made.error().message);
            } else {
                b.structure = made.value();
                b.size = sizes.value().structure;
                b.buildScratch = sizes.value().buildScratch;
                b.updateScratch = sizes.value().updateScratch;
            }
        }
        if (b.state == State::Failed) {  // what was made before the failure goes
            if (b.outView.id) device_->destroy_view(b.outView);
            if (b.positions.id) device_->destroy_buffer(b.positions);
            b.outView = {};
            b.positions = {};
        }
    }
    const std::uint32_t id = b.id;
    skinned_[key] = id;
    blas_.emplace(id, std::move(b));
    return id;
}

// After the cap: the skinned items are checked against the skinning program and the skinned budget (nearest first, a stable order), the
// BLASes of the ones that stay are found or made, their palettes copied, and the BLASes of instances that left are freed.
void RtScene::prepare_skinned(const Vec3&) {
    std::vector<std::uint32_t> skinned;
    for (std::uint32_t i = 0; i < items_.size(); ++i)
        if (items_[i].skinned) skinned.push_back(i);
    if (skinned.empty()) {
        free_unseen_skinned();
        return;
    }
    // Asked for again every frame that skins: the renderer's pipeline cache destroys one that nobody asked for in a while (Gpu::sweep_pipelines),
    // so a handle kept from an earlier frame may be dead.
    const gpu::Pipeline pipeline = skin_kernel();
    std::vector<char> keep(items_.size(), 1);
    std::uint32_t dropped = 0;
    if (!pipeline.id || !device_->features().compute) {
        for (std::uint32_t i : skinned) {
            keep[i] = 0;
            // Out of the TLAS, so its sun shadow comes from the cascades (the lit pass takes the min when this is not zero).
            if (items_[i].instance.mask & kRtMaskCastsShadow) ++stats_.untracedCasters;
        }
        dropped = std::uint32_t(skinned.size());
        if (!warnedSkinKernel_) {
            warnedSkinKernel_ = true;
            FA_WARN("render",
                    "Ray tracing scene: the skinning program is not available ({}), so the skinned meshes (e.g. '{}') "
                    "are not traced: they cast no "
                    "ray-traced shadow and appear in no reflection. Hint: the program is a compute shader "
                    "(rt_skin.glsl); a driver that refuses "
                    "it is named in the log lines above.",
                    device_->features().compute ? "the graphics driver refused it"
                                                : "this device has no compute shaders",
                    items_[skinned.front()].mesh->key);
        }
    } else {
        std::stable_sort(skinned.begin(), skinned.end(), [&](std::uint32_t a, std::uint32_t b) {
            return rjobs::order_float(items_[a].dist) < rjobs::order_float(items_[b].dist);
        });
        std::uint64_t vertices = 0;
        std::uint32_t count = 0;
        for (std::uint32_t i : skinned) {
            const std::uint64_t next = vertices + items_[i].vertexCount;
            if (next > kMaxSkinnedVertices || count >= kMaxSkinnedInstances) {
                keep[i] = 0;
                ++dropped;
                if (items_[i].instance.mask & kRtMaskCastsShadow) ++stats_.untracedCasters;
                warn_skin_budget(items_[i].mesh->key, items_[i].vertexCount);
                continue;
            }
            vertices = next;
            ++count;
        }
    }
    if (dropped) {
        stats_.skippedSkinned += dropped;
        std::size_t out = 0;
        for (std::size_t i = 0; i < items_.size(); ++i)
            if (keep[i]) {
                if (out != i) items_[out] = std::move(items_[i]);
                ++out;
            }
        items_.resize(out);
    }
    // The BLASes, the palettes and the bone extent of the instances that stay.
    std::unordered_map<const void*, std::uint32_t> palettes;  // only looked up
    paletteRows_.clear();
    paletteCount_ = 0;
    for (Item& it : items_) {
        if (!it.skinned) continue;
        MeshEntry& e = meshes_.at(it.mesh);
        it.blasId = skinned_blas(e, *it.mesh, it.part, it.entity);
        it.record.blasId = it.blasId;
        auto [at, fresh] = palettes.emplace(static_cast<const void*>(it.palette), paletteCount_);
        if (fresh) {
            paletteRows_.resize(std::size_t(paletteCount_ + 1) * kRtSkinPaletteFloats);
            rt_skin_pack_palette(*it.palette, paletteRows_.data() + std::size_t(paletteCount_) * kRtSkinPaletteFloats);
            ++paletteCount_;
        }
        it.paletteIndex = at->second;
        const SubMesh& part = it.mesh->parts[it.part];
        skinned_bounds(*it.palette, part.bmin, part.bmax, it.boneMin, it.boneMax);
        it.palette = nullptr;  // the World's: not kept past this call
    }
    free_unseen_skinned();
}

bool RtScene::skin_sources(MeshEntry& entry, const MeshAsset& mesh, std::uint32_t part) {
    if (entry.sources.size() != mesh.parts.size()) entry.sources.resize(mesh.parts.size());
    SkinSource& s = entry.sources[part];
    const SubMesh& sm = mesh.parts[part];
    if (s.vbView.id && s.skinView.id && s.vb.id == sm.vb.id && s.skinVb.id == sm.skinVb.id) return true;
    if (s.vbView.id) device_->destroy_view(s.vbView);
    if (s.skinView.id) device_->destroy_view(s.skinView);
    s = {};
    const auto make = [&](gpu::Buffer buffer, const char* label, gpu::View& out) {
        gpu::ViewDesc vd;
        vd.storageBuffer.buffer = buffer;
        vd.label = label;
        out = device_->make_view(vd);
        if (device_->state(out) == gpu::ResourceState::Valid) return true;
        if (out.id) device_->destroy_view(out);
        out = {};
        return false;
    };
    if (!make(sm.vb, "rt skin vertices", s.vbView) || !make(sm.skinVb, "rt skin influences", s.skinView)) {
        if (s.vbView.id) device_->destroy_view(s.vbView);
        s = {};
        return false;
    }
    s.vb = sm.vb;
    s.skinVb = sm.skinVb;
    return true;
}

bool RtScene::ensure_palette_buffer() {
    if (paletteCount_ == 0) return false;
    if (paletteBuffer_.id && paletteView_.id && paletteCount_ <= paletteCapacity_) return true;
    if (paletteView_.id) device_->destroy_view(paletteView_);
    if (paletteBuffer_.id) device_->destroy_buffer(paletteBuffer_);
    paletteView_ = {};
    paletteBuffer_ = {};
    paletteCapacity_ = 0;
    const std::uint32_t capacity = std::max<std::uint32_t>(16, next_pow2_u32(paletteCount_));
    gpu::BufferDesc bd;
    bd.size = std::size_t(capacity) * kRtSkinPaletteFloats * sizeof(float);
    bd.usage.storageBuffer = true;
    bd.usage.writeTransient = true;
    bd.label = "rt skin palettes";
    paletteBuffer_ = device_->make_buffer(bd);
    if (device_->state(paletteBuffer_) == gpu::ResourceState::Valid) {
        gpu::ViewDesc vd;
        vd.storageBuffer.buffer = paletteBuffer_;
        vd.label = "rt skin palettes";
        paletteView_ = device_->make_view(vd);
        if (device_->state(paletteView_) == gpu::ResourceState::Valid) {
            paletteCapacity_ = capacity;
            return true;
        }
        if (paletteView_.id) device_->destroy_view(paletteView_);
        paletteView_ = {};
    }
    if (paletteBuffer_.id) device_->destroy_buffer(paletteBuffer_);
    paletteBuffer_ = {};
    warn_once(warnedBuffers_, "the palette buffer of the skinned meshes could not be made",
              "The skinned meshes are not traced.");
    return false;
}

// What the frame does for the skinned BLASes: which are built from scratch, which refitted, where their scratch memory sits.
void RtScene::plan_skin(std::vector<SkinWork>& work, std::uint32_t buildBudget, std::uint64_t& scratchNeed) {
    work.clear();
    scratchNeed = 0;
    stats_.skinnedDispatches = stats_.skinnedBuilds = stats_.skinnedRefits = 0;
    stats_.skinnedVertices = 0;
    std::vector<const Item*> firsts;  // the first item of each skinned BLAS, in id order
    for (const Item& it : items_)
        if (it.skinned) firsts.push_back(&it);
    if (firsts.empty()) return;
    std::stable_sort(firsts.begin(), firsts.end(), [](const Item* a, const Item* b) { return a->blasId < b->blasId; });
    firsts.erase(
        std::unique(firsts.begin(), firsts.end(), [](const Item* a, const Item* b) { return a->blasId == b->blasId; }),
        firsts.end());
    if (!ensure_palette_buffer()) return;
    const std::uint64_t alignment = std::max<std::uint32_t>(1, device_->accel_scratch_alignment());
    // Pass 1: what each BLAS wants. A first build (the instance is not in the TLAS without it) is granted in id order; the rebuilds that
    // are due (the periodic one, the box jump) share what is left of the frame's build budget, the most urgent first, so that a crowd whose
    // rebuilds are more than the budget (4096 instances over 16 frames of 256 builds) is rebuilt oldest first and no id waits for ever.
    struct Entry {
        SkinWork w;
        bool firstBuild = false;
        bool rebuildDue = false;
        bool jumped = false;
        std::uint64_t age = 0;
    };
    std::vector<Entry> entries;
    entries.reserve(firsts.size());
    for (const Item* it : firsts) {
        auto bi = blas_.find(it->blasId);
        if (bi == blas_.end() || bi->second.state == State::Failed) continue;
        Blas& b = bi->second;
        auto me = meshes_.find(b.mesh);
        if (me == meshes_.end()) continue;
        if (!skin_sources(me->second, *b.mesh, b.part)) {
            b.state = State::Failed;
            warn_once(warnedBlasMake_, "a skinned mesh's buffers could not be read by the skinning program",
                      std::format("'{}' part {}: the storage views could not be made. Its instances are not traced.",
                                  b.mesh->key, b.part));
            continue;
        }
        Entry e;
        e.w.id = b.id;
        e.w.boneMin = it->boneMin;
        e.w.boneMax = it->boneMax;
        e.w.paletteIndex = it->paletteIndex;
        if (b.state == State::Pending) {
            e.firstBuild = true;
        } else {
            e.age = frameCounter_ > b.builtFrame ? frameCounter_ - b.builtFrame : 0;
            // The periodic rebuild waits for its phase (the id mod kSkinRebuildSpread): BLASes made in one frame do not all rebuild in one.
            // One that is a whole spread overdue (its phases went by with no budget left) no longer waits for its phase.
            const bool periodic =
                e.age >= kSkinRebuildFrames && ((frameCounter_ + b.id) % kSkinRebuildSpread == 0 ||
                                                e.age >= std::uint64_t(kSkinRebuildFrames) + kSkinRebuildSpread);
            e.jumped = extent_jumped(b.builtMin, b.builtMax, e.w.boneMin, e.w.boneMax);
            e.rebuildDue = periodic || e.jumped;
        }
        entries.push_back(e);
    }
    for (Entry& e : entries)
        if (e.firstBuild && buildBudget > 0) {
            --buildBudget;
            e.w.full = true;
        }
    std::vector<std::uint32_t> due;
    for (std::uint32_t i = 0; i < entries.size(); ++i)
        if (entries[i].rebuildDue) due.push_back(i);
    std::stable_sort(due.begin(), due.end(), [&](std::uint32_t a, std::uint32_t b) {
        if (entries[a].jumped != entries[b].jumped) return entries[a].jumped;
        return entries[a].age > entries[b].age;
    });
    for (std::uint32_t i : due) {
        if (buildBudget == 0) break;  // a refit this frame, the rebuild a later one (older first)
        --buildBudget;
        entries[i].w.full = true;
    }
    // Pass 2, in id order: the scratch memory of each.
    std::uint64_t offset = 0, high = 0;
    for (Entry& e : entries) {
        if (e.firstBuild && !e.w.full)
            continue;  // the builds of a frame are bounded: it joins the TLAS in a later frame
        const Blas& b = blas_.at(e.w.id);
        const std::uint64_t need = std::max<std::uint64_t>(1, e.w.full ? b.buildScratch : b.updateScratch);
        offset = round_up(offset, alignment);
        if (offset + need > kSkinScratchBytes)
            offset = 0;  // past the budget the builds share the start: the backend serializes them
        e.w.scratchOffset = std::size_t(offset);
        offset += need;
        high = std::max(high, offset);
        work.push_back(e.w);
    }
    scratchNeed = high;
}

void RtScene::record_skin_dispatches(gpu::CommandList& list, const std::vector<SkinWork>& work) {
    if (work.empty()) return;
    gpu::BufferWrite wr;
    const std::size_t bytes = std::size_t(paletteCount_) * kRtSkinPaletteFloats * sizeof(float);
    wr.data = gpu::Range{paletteRows_.data(), bytes};
    wr.buffer = paletteBuffer_;
    wr.dstOffset = 0;
    wr.size = bytes;
    list.write_buffer(wr);
    list.begin_compute_pass("rt-skin");
    list.set_pipeline(skin_kernel());
    for (const SkinWork& w : work) {
        const Blas& b = blas_.at(w.id);
        const SkinSource& src = meshes_.at(b.mesh).sources[b.part];
        gpu::Bindings bind;
        bind.views[kRtSkinViewVertices] = src.vbView;
        bind.views[kRtSkinViewInfluences] = src.skinView;
        bind.views[kRtSkinViewPalette] = paletteView_;
        bind.views[kRtSkinViewOut] = b.outView;
        list.set_bindings(bind);
        const std::int32_t params[4] = {std::int32_t(b.vertexCount), std::int32_t(w.paletteIndex * kRtSkinPaletteRows),
                                        0, 0};
        list.set_uniforms(kRtSkinUniformParams, gpu::Range{params, sizeof(params)});
        list.dispatch(int((b.vertexCount + kRtSkinGroupSize - 1) / kRtSkinGroupSize), 1, 1);
        ++stats_.skinnedDispatches;
        stats_.skinnedVertices += b.vertexCount;
    }
    list.end_pass();
}

std::uint32_t RtScene::record_skin_builds(gpu::CommandList& list, const std::vector<SkinWork>& work) {
    std::uint32_t full = 0;
    for (const SkinWork& w : work) {
        Blas& b = blas_.at(w.id);
        gpu::BlasBuild bb;
        bb.dst = b.structure;
        bb.geometries = std::span<const gpu::AccelTriangles>(&b.triangles, 1);
        bb.flags = skin_flags();
        bb.update = !w.full;  // src stays invalid: refit in place
        bb.scratch = scratch_;
        bb.scratchOffset = w.scratchOffset;
        if (const Result<void> r = list.build_blas(bb); !r) {
            b.state = State::Failed;
            warn_once(warnedBlasBuild_, "a BLAS could not be built", b.label + ": " + r.error().message);
            continue;
        }
        if (w.full) {
            b.state = State::Built;
            b.builtFrame = frameCounter_;
            b.builtMin = w.boneMin;
            b.builtMax = w.boneMax;
            ++stats_.skinnedBuilds;
            ++full;
        } else {
            ++stats_.skinnedRefits;
        }
    }
    return full;
}

}  // namespace fa::render
