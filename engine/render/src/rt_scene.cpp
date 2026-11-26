// The acceleration structures of the scene (M79 P1s). See rt_scene.h and docs/design/ARCHITECTURE_RT_SCENE.md.
#include "rt_scene.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <format>
#include <limits>

#include "color_space.h"
#include "fa/core/log.h"
#include "render_internal.h"
#include "render_jobs.h"
#include "render_scene.h"
#include "rt_skin.h"

namespace fa::render {

namespace {

constexpr std::uint32_t kMinRecordCapacity = 256;  // records the buffer holds at least (24 KB)
constexpr std::uint32_t kMinTlasCapacity = 256;
// A retired BLAS is destroyed this many frames after the frame it was retired in: the TLAS of every frame the GPU may still be executing
// names it (a TLAS does not keep its BLASes alive), and the CPU runs kInflightFrames ahead.
constexpr std::uint64_t kRetireFrames = std::uint64_t(gpu::kInflightFrames) + 1;

// Whether a part has anything a build can read.
bool traceable_part(const SubMesh& sm) {
    return sm.vb.id && sm.ib.id && sm.vertexCount >= 3 && sm.indexCount - sm.indexCount % 3 >= 3;
}

float saturate01(float v) { return v > 0.0f ? (v < 1.0f ? v : 1.0f) : 0.0f; }  // NaN gives 0

std::uint32_t next_pow2(std::uint32_t v) {
    std::uint32_t p = 1;
    while (p < v && p < (1u << 31)) p <<= 1;
    return p;
}

std::uint64_t round_up_u64(std::uint64_t v, std::uint64_t unit) { return (v + unit - 1) / unit * unit; }

gpu::AccelBuildFlags blas_flags() {
    gpu::AccelBuildFlags f;
    f.preferFastTrace = true;  // built once, traced every frame
    f.allowCompaction = true;  // query_compacted_size + copy (Compact) after the first build
    return f;
}

gpu::AccelBuildFlags tlas_flags() {
    gpu::AccelBuildFlags f;
    f.preferFastBuild = true;  // rebuilt every frame
    f.preferFastTrace = false;
    return f;
}

// A signature of what a build reads of a mesh: the buffers and ranges of every part.
std::uint64_t mesh_signature(const MeshAsset& m) {
    std::uint64_t h = 1469598103934665603ull;
    const auto mix = [&h](std::uint64_t v) {
        h ^= v + 0x9e3779b97f4a7c15ull + (h << 6) + (h >> 2);
        h *= 1099511628211ull;
    };
    mix(m.parts.size());
    for (const SubMesh& p : m.parts) {
        mix(p.vb.id);
        mix(p.skinVb.id);
        mix(p.ib.id);
        mix(std::uint64_t(std::uint32_t(p.ibOffset)));
        mix(std::uint64_t(std::uint32_t(p.vertexCount)));
        mix(std::uint64_t(std::uint32_t(p.indexCount)));
    }
    return h;
}

}  // namespace

RtScene::~RtScene() { release(); }

bool RtScene::configure(gpu::Device* device, bool on, std::uint32_t maxInstances) {
    if (!on || !device || !device->features().accelerationStructure) {
        release();
        return false;
    }
    if (device_ != device) release();
    device_ = device;
    maxInstances_ = maxInstances;
    std::uint32_t cap = std::max<std::uint32_t>(1, maxInstances);
    const std::uint32_t limit = device->limits().maxAccelInstances;
    if (limit > 0) cap = std::min(cap, limit);
    cap = std::min(cap, kRtMaxInstanceIndex + 1);  // customIndex is 24 bits
    if (cap != cap_) warnedCap_ = false;
    cap_ = cap;
    stats_.cap = cap_;
    return true;
}

void RtScene::warn_once(bool& flag, const char* what, const std::string& message) {
    if (flag) return;
    flag = true;
    FA_WARN("render", "Ray tracing scene: {}: {}", what, message);
}

std::int32_t RtScene::take_slot() {
    if (!freeSlots_.empty()) {
        const std::int32_t s = freeSlots_.back();
        freeSlots_.pop_back();
        return s;
    }
    if (slotHigh_ >= std::int32_t(kSizeSlots)) return -1;
    if (!sizeBuffer_.id) {
        gpu::BufferDesc bd;
        bd.size = std::size_t(kSizeSlots) * 8;
        bd.usage.storageBuffer = true;
        bd.usage.copyDst = true;
        bd.label = "rt compacted sizes";
        sizeBuffer_ = device_->make_buffer(bd);
        if (device_->state(sizeBuffer_) != gpu::ResourceState::Valid) {
            if (sizeBuffer_.id) device_->destroy_buffer(sizeBuffer_);
            sizeBuffer_ = {};
            slotHigh_ = std::int32_t(kSizeSlots);  // no buffer: no BLAS is compacted
            return -1;
        }
    }
    return slotHigh_++;
}

void RtScene::retire_blas(gpu::AccelStructure structure) {
    if (device_ && structure.id) graveyard_.push_back({structure, frameCounter_});
}

void RtScene::drain_graveyard(bool all) {
    std::size_t n = 0;
    while (n < graveyard_.size() && (all || graveyard_[n].frame + kRetireFrames <= frameCounter_)) {
        device_->destroy_accel_structure(graveyard_[n].structure);
        ++n;
    }
    graveyard_.erase(graveyard_.begin(), graveyard_.begin() + std::ptrdiff_t(n));
}

void RtScene::free_blas(std::uint32_t id) {
    auto it = blas_.find(id);
    if (it == blas_.end()) return;
    Blas& b = it->second;
    if (b.skinned) {  // its own buffer and view go with it; the structure waits for the frames in flight
        skinned_.erase(SkinKey{b.entity, b.mesh, b.part});
        if (b.outView.id) device_->destroy_view(b.outView);
        if (b.positions.id) device_->destroy_buffer(b.positions);
        if (b.structure.id) retire_blas(b.structure);
        blas_.erase(it);
        return;
    }
    if (b.slot >= 0 && b.state == State::Queried)
        freeSlots_.push_back(b.slot);  // a Reading one frees its slot when the answer comes
    retire_blas(b.structure);
    retire_blas(b.compact);
    const auto drop = [id](std::vector<std::uint32_t>& v) { v.erase(std::remove(v.begin(), v.end(), id), v.end()); };
    drop(pending_);
    drop(queried_);
    drop(copyPending_);
    drop(swap_);
    blas_.erase(it);
}

void RtScene::free_mesh_entry(MeshEntry& e) {
    for (std::uint32_t id : e.blas)
        if (id) free_blas(id);
    e.blas.clear();
    for (SkinSource& s : e.sources) {
        if (s.vbView.id) device_->destroy_view(s.vbView);
        if (s.skinView.id) device_->destroy_view(s.skinView);
    }
    e.sources.clear();
}

void RtScene::forget(const MeshAsset* mesh) {
    if (!device_) return;
    std::vector<std::uint32_t>
        mine;  // the skinned instances of the asset (their entities may live on: they are made again if it comes back)
    for (const auto& [id, b] : blas_)
        if (b.skinned && b.mesh == mesh) mine.push_back(id);
    for (std::uint32_t id : mine) free_blas(id);
    auto it = meshes_.find(mesh);
    if (it == meshes_.end()) return;
    free_mesh_entry(it->second);
    meshes_.erase(it);
}

void RtScene::release() {
    // Anything the GPU may still read or write: the TLAS, a BLAS, a retired object, one of the buffers and views, a read in flight, a
    // source view of a skinned mesh. A scene that never built anything (ray tracing turned on and off before a frame, a device
    // that failed to make its objects) has nothing to wait for.
    bool anyAlive = tlas_.id || !blas_.empty() || !graveyard_.empty() || recordsBuffer_.id || scratch_.id ||
                    sizeBuffer_.id || paletteBuffer_.id || paletteView_.id || readTicket_.valid();
    for (const auto& [mesh, e] : meshes_) anyAlive = anyAlive || !e.sources.empty();
    if (device_ && anyAlive) {
        // The frames in flight may still trace the TLAS and the BLASes: wait for the GPU once (turning ray tracing off, a new device, the
        // renderer's shutdown; never per frame) so everything can go now. A device that orders its work itself does nothing here.
        if (const Result<void> idle = device_->wait_idle(); !idle)
            FA_WARN(
                "render",
                "Ray tracing scene: the GPU could not be waited for before the acceleration structures are freed: {}",
                idle.error().message);
        release_skin();
        if (readTicket_.valid()) device_->release_buffer_read(readTicket_);
        for (auto& [id, b] : blas_) {
            if (b.structure.id) device_->destroy_accel_structure(b.structure);
            if (b.compact.id) device_->destroy_accel_structure(b.compact);
        }
        drain_graveyard(true);
        if (tlas_.id) device_->destroy_accel_structure(tlas_);
        for (gpu::Buffer* b : {&recordsBuffer_, &scratch_, &sizeBuffer_})
            if (b->id) device_->destroy_buffer(*b);
    }
    blas_.clear();
    meshes_.clear();
    pending_.clear();
    queried_.clear();
    copyPending_.clear();
    swap_.clear();
    freeSlots_.clear();
    reading_.clear();
    items_.clear();
    frame_.clear();
    previous_.clear();
    readTicket_ = {};
    tlas_ = {};
    recordsBuffer_ = {};
    scratch_ = {};
    sizeBuffer_ = {};
    slotHigh_ = 0;
    tlasCapacity_ = 0;
    recordsCapacity_ = 0;
    scratchSize_ = 0;
    tlasBuilt_ = false;
    tlasInstances_ = 0;
    collected_ = false;
    device_ = nullptr;
    cap_ = 0;
    maxInstances_ = 0;
    stats_ = {};
    warnedCap_ = warnedSkinned_ = warnedBlasMake_ = warnedBlasBuild_ = warnedTlasMake_ = warnedTlasBuild_ =
        warnedBuffers_ = warnedRead_ = warnedSkinKernel_ = false;
    graveyard_.clear();
}

void RtScene::shift(const Vec3& offset) {
    // The records of the frame before are world positions (the temporal effects of later packages reproject from them): the entity moved
    // with the world, so each is `offset` closer to the origin.
    for (RtInstanceRecord& r : previous_) {
        r.objectToWorld[3] -= offset.x;
        r.objectToWorld[7] -= offset.y;
        r.objectToWorld[11] -= offset.z;
    }
}

std::vector<std::uint32_t> RtScene::blas_ids_of(const MeshAsset* mesh) const {
    auto it = meshes_.find(mesh);
    return it == meshes_.end() ? std::vector<std::uint32_t>{} : it->second.blas;
}

std::string RtScene::blas_state(std::uint32_t id) const {
    auto it = blas_.find(id);
    if (it == blas_.end()) return "gone";
    switch (it->second.state) {
        case State::Pending: return "pending";
        case State::Built: return it->second.compactedSize ? "compacted" : "built";
        case State::Queried: return "queried";
        case State::Reading: return "reading";
        case State::CopyPending: return "compact-pending";
        case State::Swap: return "swap";
        case State::Compacted: return "compacted";
        case State::Failed: return "failed";
    }
    return "?";
}

// ---- compaction ------------------------------------------------------------------------------------------------------------------

void RtScene::apply_compacted(std::uint32_t id, std::uint64_t size) {
    auto it = blas_.find(id);
    if (it == blas_.end() || it->second.state != State::Reading) return;
    Blas& b = it->second;
    b.state = State::Built;
    if (size == 0 || size >= b.size) return;  // not smaller: the original stays
    gpu::AccelStructureDesc d;
    d.kind = gpu::AccelKind::Blas;
    d.size = size;
    const std::string label = b.label + " (compacted)";
    d.label = label.c_str();
    const Result<gpu::AccelStructure> made = device_->make_accel_structure(d);
    if (!made) return;  // keep the original; the device reported why
    b.compact = made.value();
    b.compactedSize = size;
    b.state = State::CopyPending;
    copyPending_.push_back(id);
}

void RtScene::poll_compaction(bool headless, const std::function<void()>& commit) {
    const auto apply = [&](const std::vector<std::uint8_t>& bytes) {
        for (const Reading& r : reading_) {
            std::uint64_t value = 0;
            const std::size_t at = std::size_t(r.slot) * 8;
            if (at + 8 <= bytes.size())
                for (int i = 0; i < 8; ++i) value |= std::uint64_t(bytes[at + std::size_t(i)]) << (8 * i);
            freeSlots_.push_back(r.slot);
            apply_compacted(r.id, value);
        }
        reading_.clear();
    };
    const auto give_up = [&](const std::string& why) {
        // The originals stay as they are (no compaction): the scene works, it only keeps a bigger BLAS.
        for (const Reading& r : reading_) {
            freeSlots_.push_back(r.slot);
            auto it = blas_.find(r.id);
            if (it != blas_.end() && it->second.state == State::Reading) it->second.state = State::Built;
        }
        reading_.clear();
        warn_once(warnedRead_, "the compacted size of a BLAS could not be read back",
                  why + " The acceleration structures stay at their built size (more memory, the same picture).");
    };
    std::vector<std::uint8_t> bytes;
    if (readTicket_.valid()) {
        if (!device_->poll_buffer_read(readTicket_, bytes, headless))
            return;  // not there yet: the next frame asks again
        readTicket_ = {};
        apply(bytes);
    }
    if (queried_.empty()) return;
    if (commit) commit();  // the queries are recorded in a frame that must reach the GPU before they are read
    for (std::uint32_t id : queried_) {
        Blas& b = blas_.at(id);
        b.state = State::Reading;
        reading_.push_back({id, b.slot});
    }
    queried_.clear();
    const std::size_t bytesToRead = std::size_t(slotHigh_) * 8;
    if (device_->async_read_supported()) {
        const Result<gpu::ReadTicket> asked = device_->request_buffer_read(sizeBuffer_, 0, bytesToRead);
        if (asked && asked.value().valid()) {
            readTicket_ = asked.value();
            return;  // polled by a later frame
        }
        if (asked) {  // every slot is in flight: ask again next frame
            for (const Reading& r : reading_) blas_.at(r.id).state = State::Queried, queried_.push_back(r.id);
            reading_.clear();
            return;
        }
        give_up(asked.error().message);
        return;
    }
    // The synchronous read BLOCKS the render thread until the GPU has finished the frames before (the commit above sent them). It is
    // only reached where the device cannot read asynchronously (the RecordingDevice, a headless run, a backend with no ticket
    // support), where the wait is what makes a result independent of the GPU's speed; on a window the asynchronous read above is used.
    const Result<void> got = device_->read_buffer(sizeBuffer_, 0, bytesToRead, bytes);
    if (!got) {
        give_up(got.error().message);
        return;
    }
    apply(bytes);
}

// ---- frame -----------------------------------------------------------------------------------------------------------------------

void RtScene::begin_frame(bool headless, const std::function<void()>& commit) {
    collected_ = false;
    if (!device_) return;
    ++frameCounter_;
    drain_graveyard(false);
    // The compacted copies the frame before recorded are done: the compact BLAS takes the place of the original. The TLAS of the frames
    // in flight still names the original, so it is retired (destroyed kRetireFrames frames from now), not destroyed.
    for (std::uint32_t id : swap_) {
        auto it = blas_.find(id);
        if (it == blas_.end()) continue;
        Blas& b = it->second;
        retire_blas(b.structure);
        b.structure = b.compact;
        b.compact = {};
        b.size = b.compactedSize;
        b.state = State::Built;
    }
    swap_.clear();
    poll_compaction(headless, commit);
}

std::uint32_t RtScene::blas_for(const MeshAsset& mesh, std::size_t part, const std::string& key, bool& untraceable) {
    untraceable = false;
    const SubMesh& sm = mesh.parts[part];
    const int indices = sm.indexCount - sm.indexCount % 3;
    if (!traceable_part(sm)) {
        untraceable = true;
        return 0;
    }
    Blas b;
    b.id = nextId_++;
    b.label = std::format("blas:{}#{}", key, part);
    b.triangles.vertexBuffer = sm.vb;
    b.triangles.vertexOffset = 0;  // MeshVertex starts with the position
    b.triangles.vertexStride = sizeof(MeshVertex);
    b.triangles.vertexCount = std::uint32_t(sm.vertexCount);
    b.triangles.vertexFormat = gpu::VertexFormat::Float3;
    b.triangles.indexBuffer = sm.ib;
    b.triangles.indexOffset = std::size_t(std::max(sm.ibOffset, 0));
    b.triangles.indexType = gpu::IndexType::Uint32;
    b.triangles.indexCount = std::uint32_t(indices);
    // Not opaque: the BLAS is the geometry only and is shared by every material; the instance forces it opaque (AccelInstance::opaque)
    // wherever the material has no alpha test.
    b.triangles.opaque = false;
    const std::array<gpu::AccelTriangles, 1> geometry{b.triangles};
    const Result<gpu::AccelSizes> sizes = device_->blas_sizes(geometry, blas_flags());
    if (!sizes) {
        b.state = State::Failed;
        warn_once(warnedBlasMake_, "a mesh could not get an acceleration structure",
                  std::format("'{}' part {}: {} Its instances are not traced.", key, part, sizes.error().message));
    } else {
        gpu::AccelStructureDesc d;
        d.kind = gpu::AccelKind::Blas;
        d.size = sizes.value().structure;
        d.label = b.label.c_str();
        const Result<gpu::AccelStructure> made = device_->make_accel_structure(d);
        if (!made) {
            b.state = State::Failed;
            warn_once(warnedBlasMake_, "a mesh could not get an acceleration structure",
                      std::format("'{}' part {}: {} Its instances are not traced.", key, part, made.error().message));
        } else {
            b.structure = made.value();
            b.size = sizes.value().structure;
            b.buildScratch = sizes.value().buildScratch;
            pending_.push_back(b.id);
        }
    }
    const std::uint32_t id = b.id;
    blas_.emplace(id, std::move(b));
    return id;
}

void RtScene::collect(const std::vector<MeshItem>& opaque, const std::vector<MeshItem>& blended, const Vec3& camera,
                      bool linear) {
    items_.clear();
    collected_ = true;
    stats_.candidates = stats_.instances = stats_.droppedOverCap = 0;
    stats_.skippedSkinned = stats_.skippedImpostor = stats_.skippedTerrain = stats_.skippedFading = 0;
    stats_.skippedGpuDriven = stats_.skippedUntraceable = stats_.skippedNoBlas = 0;
    stats_.untracedCasters = 0;
    stats_.skinnedInstances = 0;
    stats_.cap = cap_;
    if (!device_) return;
    paletteCount_ = 0;
    items_.reserve(opaque.size() + blended.size());
    for (int list = 0; list < 2; ++list) {
        const bool isBlended = list == 1;
        for (const MeshItem& mi : isBlended ? blended : opaque) {
            ++stats_.candidates;
            if (!mi.mesh || !mi.mr) continue;
            const bool casts = mi.mr->castShadows;
            if (mi.terrain) {
                ++stats_.skippedTerrain;
                if (casts) ++stats_.untracedCasters;
                continue;
            }
            if (mi.impostor) {
                ++stats_.skippedImpostor;
                if (casts) ++stats_.untracedCasters;
                continue;
            }
            if (mi.lodFade < 0.0f &&
                !mi.foliage) {  // the level fading out: the level fading in (or settled) is the pick
                ++stats_.skippedFading;
                continue;
            }
            if (mi.material && !mi.material->buffers.empty()) {
                ++stats_.skippedGpuDriven;
                if (casts) ++stats_.untracedCasters;
                continue;
            }
            const MeshAsset& mesh = *mi.mesh;
            if (mesh.placeholder || mesh.parts.empty()) {
                ++stats_.skippedUntraceable;
                if (casts) ++stats_.untracedCasters;
                continue;
            }
            const MeshRenderer& mr = *mi.mr;
            const MaterialAsset* mat = mi.material;
            const bool matOk = mat && mat->ok;
            const bool matError = mat && !mat->ok;
            const bool cutout = matOk && mat->alphaMode == "clip";
            const bool unlit = mr.unlit || matError || (matOk && mat->lighting == "unlit");
            const float strength = mr.emissiveStrength > 0.0f ? std::min(mr.emissiveStrength, 1000.0f) : 0.0f;
            const Color emissive = to_scene(mr.emissive, linear);
            const float dist = length(mi.model.translation() - camera);
            for (std::size_t p = 0; p < mesh.parts.size(); ++p) {
                const SubMesh& part = mesh.parts[p];
                // A part the Animator's palette deforms (the draw's own test): traced from its own BLAS, made after the cap (prepare_skinned).
                const bool skinnedPart = mi.anim && part.skinVb.id;
                if (!traceable_part(part)) {
                    ++stats_.skippedUntraceable;
                    if (casts) ++stats_.untracedCasters;
                    continue;
                }
                if (skinnedPart && std::uint32_t(part.vertexCount) > kRtSkinMaxPartVertices) {
                    ++stats_.skippedSkinned;
                    if (casts) ++stats_.untracedCasters;
                    warn_skin_budget(mesh.key, std::uint32_t(part.vertexCount));
                    continue;
                }
                Item it;
                it.mesh = mi.mesh;
                it.part = std::uint32_t(p);
                if (skinnedPart) {
                    it.skinned = true;
                    it.entity = mi.entity.bits();
                    it.palette = &palette_of(*mi.anim, part.skin);
                    it.vertexCount = std::uint32_t(part.vertexCount);
                }
                it.entityId = std::uint32_t(mi.entity.bits());
                it.dist = dist;
                // The transform: row-major 3x4 from the column-major matrix.
                for (int r = 0; r < 3; ++r)
                    for (int c = 0; c < 4; ++c) it.instance.transform[r * 4 + c] = mi.model.at(c, r);
                const bool twoSided = part.doubleSided || (matOk && mat->doubleSided);
                bool authored = false;
                const Color pc = matError ? Color{1, 0, 1, 1} : part_base_color(mr, part, &authored);
                const Color base = matError ? pc : to_scene(mr.color, linear) * (authored ? to_scene(pc, linear) : pc);
                RtInstanceRecord& rec = it.record;
                std::memcpy(rec.objectToWorld, it.instance.transform, sizeof(rec.objectToWorld));
                rec.albedo[0] = base.r;
                rec.albedo[1] = base.g;
                rec.albedo[2] = base.b;
                rec.albedo[3] = base.a;
                float em[3] = {0, 0, 0};
                if (!matError) {
                    em[0] = (emissive.r + part.emissiveFactor.r) * strength;
                    em[1] = (emissive.g + part.emissiveFactor.g) * strength;
                    em[2] = (emissive.b + part.emissiveFactor.b) * strength;
                }
                rec.emissive[0] = em[0];
                rec.emissive[1] = em[1];
                rec.emissive[2] = em[2];
                rec.emissive[3] = 0.0f;
                rec.metalness = part.hasPbr ? saturate01(part.metallic) : saturate01(mr.metallic);
                rec.roughness = part.hasPbr ? saturate01(part.roughness) : saturate01(mr.roughness);
                std::uint32_t flags = 0;
                if (!cutout) flags |= kRtFlagOpaque;
                if (cutout) flags |= kRtFlagCutout;
                if (twoSided) flags |= kRtFlagTwoSided;
                if (isBlended) flags |= kRtFlagBlended;
                if (unlit) flags |= kRtFlagUnlit;
                if (mi.foliage) flags |= kRtFlagFoliage;
                if (mr.castShadows) flags |= kRtFlagCastsShadow;
                if (cutout && mr.castShadows)
                    ++stats_.untracedCasters;  // in the TLAS, but the shadow kernel cannot test its alpha
                if (matOk) flags |= kRtFlagCustomMaterial;
                if (skinnedPart) flags |= kRtFlagSkinned;
                // Transmission (M79-P3b): the part the mesh pass draws with the refraction (the draw's own test, fill_fs:
                // not unlit, not a full shader, a transmission above 0, and a metalness below 1: the shader lets through
                // `transmission * (1 - metallic)`, so a full metal bends nothing) is a surface the translucency kernel
                // bends rays at. It is traced from both sides (a closed glass has to be left through its far wall), which
                // makes the shadow and reflection rays hit its back faces too.
                const PartTransmission pt = resolve_part_transmission(mr, part, linear);
                const bool refractive =
                    isBlended && !unlit && !(matOk && mat->full) && pt.transmission > 0.0f && rec.metalness < 1.0f;
                rec.volume[0] = pt.ior;
                rec.volume[1] = refractive ? pt.thickness : 0.0f;
                rec.volume[2] = refractive ? pt.attenuationDistance : 0.0f;
                rec.volume[3] = refractive ? pt.transmission : 0.0f;
                for (int c = 0; c < 3; ++c) rec.attenuation[c] = refractive ? pt.attenuationColor[c] : 1.0f;
                rec.attenuation[3] = 0.0f;
                if (refractive) flags |= kRtFlagRefractive;
                rec.flags = flags;
                std::uint8_t mask = isBlended ? kRtMaskBlended : (cutout ? kRtMaskCutout : kRtMaskOpaque);
                if (mr.castShadows) mask |= kRtMaskCastsShadow;
                if (mi.foliage) mask |= kRtMaskFoliage;
                if (em[0] > 0.0f || em[1] > 0.0f || em[2] > 0.0f) mask |= kRtMaskEmissive;
                if (refractive) mask |= kRtMaskRefractive;
                it.instance.mask = mask;
                it.instance.opaque = !cutout;
                it.instance.cullDisable = twoSided || refractive;
                items_.push_back(std::move(it));
            }
        }
    }
    // More than the scene may hold: the nearest to the main camera stay (a stable order: ties and NaN go by position in the list).
    if (items_.size() > cap_) {
        stats_.droppedOverCap = std::uint32_t(items_.size() - cap_);
        std::vector<std::uint32_t> order(items_.size());
        for (std::size_t i = 0; i < order.size(); ++i) order[i] = std::uint32_t(i);
        std::stable_sort(order.begin(), order.end(), [&](std::uint32_t a, std::uint32_t b) {
            return rjobs::order_float(items_[a].dist) < rjobs::order_float(items_[b].dist);
        });
        std::vector<char> keep(items_.size(), 0);
        for (std::uint32_t i = 0; i < cap_; ++i) keep[order[i]] = 1;
        for (std::size_t i = cap_; i < order.size();
             ++i)  // the farthest leave: those that cast keep their cascade shadow
            if (items_[order[i]].instance.mask & kRtMaskCastsShadow) ++stats_.untracedCasters;
        std::size_t out = 0;
        for (std::size_t i = 0; i < items_.size(); ++i)
            if (keep[i]) {
                if (out != i) items_[out] = std::move(items_[i]);
                ++out;
            }
        const std::size_t total = items_.size();
        items_.resize(out);
        if (!warnedCap_) {
            warnedCap_ = true;
            FA_WARN("render",
                    "Ray tracing scene: the scene has {} instances but the acceleration structure holds {} "
                    "(render.rayTracing.maxInstances "
                    "is {}{}): the {} farthest from the main camera are not traced, so they cast no ray-traced shadow "
                    "and appear in no "
                    "reflection. Hint: raise render.rayTracing.maxInstances (up to {}), or draw fewer objects.",
                    total, cap_, maxInstances_,
                    cap_ < maxInstances_ ? std::format("; this GPU allows {}", device_->limits().maxAccelInstances)
                                         : std::string(),
                    stats_.droppedOverCap,
                    std::uint64_t(
                        device_->limits().maxAccelInstances
                            ? std::min<std::uint32_t>(device_->limits().maxAccelInstances, kRtMaxInstanceIndex + 1)
                            : kRtMaxInstanceIndex + 1));
        }
    }
    // The BLASes of the instances that stay (an item the cap left out makes none): made on first sight, made again when the geometry of
    // the asset changed (the old ones are retired, not destroyed: a TLAS of a frame in flight names them).
    std::size_t out = 0;
    for (std::size_t i = 0; i < items_.size(); ++i) {
        Item& it = items_[i];
        const MeshAsset& mesh = *it.mesh;
        MeshEntry& e = meshes_[it.mesh];
        if (e.checkedFrame != frameCounter_ || e.blas.size() != mesh.parts.size()) {
            e.checkedFrame = frameCounter_;
            const std::uint64_t sig = mesh_signature(mesh);
            if (e.blas.size() != mesh.parts.size() || e.version != mesh.geometryVersion || e.signature != sig) {
                free_mesh_entry(e);
                e.version = mesh.geometryVersion;
                e.signature = sig;
                e.blas.assign(mesh.parts.size(), 0);
                e.untraceable.assign(mesh.parts.size(), 0);
            }
        }
        if (it.skinned) {  // its BLAS is the instance's own (prepare_skinned); a static one only if an item draws the part unskinned
            if (out != i) items_[out] = std::move(items_[i]);
            ++out;
            continue;
        }
        std::uint32_t& id = e.blas[it.part];
        if (!id && !e.untraceable[it.part]) {
            bool bad = false;
            id = blas_for(mesh, it.part, mesh.key, bad);
            e.untraceable[it.part] = bad ? 1 : 0;
        }
        if (!id) {
            ++stats_.skippedUntraceable;
            if (it.instance.mask & kRtMaskCastsShadow) ++stats_.untracedCasters;
            continue;
        }
        it.blasId = id;
        it.record.blasId = id;
        if (out != i) items_[out] = std::move(items_[i]);
        ++out;
    }
    items_.resize(out);
    prepare_skinned(camera);
    untracedCollected_ = stats_.untracedCasters;  // record_frame adds the instances whose BLAS is not ready
    stats_.blasLive = std::uint32_t(blas_.size());
}

// ---- the pass --------------------------------------------------------------------------------------------------------------------

bool RtScene::ensure_buffers(std::uint64_t scratchNeed, std::uint32_t instances) {
    // A buffer the device could not make is destroyed and left empty (the next frame tries again), and the frame builds nothing.
    const auto make = [&](gpu::Buffer& buffer, const gpu::BufferDesc& desc) {
        buffer = device_->make_buffer(desc);
        if (device_->state(buffer) == gpu::ResourceState::Valid) return true;
        if (buffer.id) device_->destroy_buffer(buffer);
        buffer = {};
        warn_once(
            warnedBuffers_, "a buffer of the scene could not be made",
            std::format(
                "'{}' of {} bytes. Nothing is built or traced until it can be made (the picture is the one without "
                "ray tracing); the device's own message is in its log.",
                desc.label ? desc.label : "", desc.size));
        return false;
    };
    if (scratchNeed > scratchSize_ || !scratch_.id || device_->state(scratch_) != gpu::ResourceState::Valid) {
        if (scratch_.id) device_->destroy_buffer(scratch_);
        scratch_ = {};
        scratchSize_ = round_up_u64(std::max<std::uint64_t>(scratchNeed, 1), 1u << 20);
        gpu::BufferDesc bd;
        bd.size = std::size_t(scratchSize_);
        bd.usage.accelScratch = true;
        bd.label = "rt scratch";
        if (!make(scratch_, bd)) {
            scratchSize_ = 0;
            return false;
        }
    }
    if (instances > recordsCapacity_ || !recordsBuffer_.id ||
        device_->state(recordsBuffer_) != gpu::ResourceState::Valid) {
        if (recordsBuffer_.id) device_->destroy_buffer(recordsBuffer_);
        recordsBuffer_ = {};
        const std::uint32_t capacity = std::max(kMinRecordCapacity, next_pow2(instances));
        gpu::BufferDesc bd;
        bd.size = std::size_t(capacity) * sizeof(RtInstanceRecord);
        bd.usage.storageBuffer = true;
        bd.usage.writeTransient = true;
        bd.label = "rt instance records";
        if (!make(recordsBuffer_, bd)) {
            recordsCapacity_ = 0;
            return false;
        }
        recordsCapacity_ = capacity;
    }
    return true;
}

void RtScene::record(gpu::CommandList& list) {
    record_frame(list);
    // The memory the structures hold, whether or not this frame built anything.
    std::uint64_t bytes = 0;
    for (const auto& [id, b] : blas_) bytes += b.state == State::Failed ? 0 : b.size;
    stats_.blasBytes = bytes;
    stats_.blasLive = std::uint32_t(blas_.size());
    if (!tlas_.id) stats_.tlasBytes = 0;
}

void RtScene::record_frame(gpu::CommandList& list) {
    tlasBuilt_ = false;
    tlasInstances_ = 0;
    frame_.clear();
    contentHash_ = 0;
    stats_.instances = stats_.blasBuilt = stats_.blasCompacted = 0;
    if (!device_ || !collected_) return;
    // The builds of the frame: the first kMaxBuildsPerFrame BLASes waiting (creation order). An instance of one that waits joins the TLAS
    // when it is built, a frame or more later.
    std::vector<std::uint32_t> building;
    for (std::uint32_t id : pending_) {
        if (building.size() >= buildsPerFrame_) break;
        building.push_back(id);
    }
    const auto is_building = [&](std::uint32_t id) { return std::binary_search(building.begin(), building.end(), id); };
    // pending_ is in creation order = increasing id, so `building` is sorted.
    // The skinned BLASes this frame builds or refits (the skinning dispatches come first), in id order.
    std::vector<SkinWork> skinWork;
    std::uint64_t skinScratch = 0;
    plan_skin(skinWork, std::uint32_t(buildsPerFrame_ - building.size()), skinScratch);
    const auto skin_ready = [&](std::uint32_t id) {
        const auto at = std::lower_bound(skinWork.begin(), skinWork.end(), id,
                                         [](const SkinWork& w, std::uint32_t v) { return w.id < v; });
        return at != skinWork.end() && at->id == id;
    };
    std::vector<const Item*> kept;
    kept.reserve(items_.size());
    std::uint32_t waiting = 0, waitingCasters = 0;
    stats_.skinnedInstances = 0;
    for (const Item& it : items_) {
        if (it.skinned) {
            if (skin_ready(it.blasId)) {
                kept.push_back(&it);
                ++stats_.skinnedInstances;
            } else {
                ++waiting;
                waitingCasters += (it.instance.mask & kRtMaskCastsShadow) ? 1 : 0;
            }
            continue;
        }
        auto b = blas_.find(it.blasId);
        if (b == blas_.end() || b->second.state == State::Failed) {
            ++waiting;
            waitingCasters += (it.instance.mask & kRtMaskCastsShadow) ? 1 : 0;
            continue;
        }
        if (b->second.state == State::Pending && !is_building(it.blasId)) {
            ++waiting;
            waitingCasters += (it.instance.mask & kRtMaskCastsShadow) ? 1 : 0;
            continue;
        }
        kept.push_back(&it);
    }
    stats_.skippedNoBlas = waiting;
    stats_.untracedCasters = untracedCollected_ + waitingCasters;
    const std::uint32_t n = std::uint32_t(kept.size());
    // Memory first (it may make buffers), then the work.
    std::uint64_t scratchNeed = skinScratch;
    for (std::uint32_t id : building) scratchNeed = std::max(scratchNeed, blas_.at(id).buildScratch);
    std::uint32_t capacity = tlasCapacity_;
    if (n > 0 && (n > tlasCapacity_ || !tlas_.id))
        capacity = std::min(std::max(kMinTlasCapacity, next_pow2(n)), std::max(cap_, n));
    gpu::AccelSizes tsizes;
    if (n > 0) {
        const Result<gpu::AccelSizes> ts = device_->tlas_sizes(capacity, tlas_flags());
        if (!ts) {
            warn_once(warnedTlasMake_, "the top level structure could not be sized", ts.error().message);
            return;
        }
        tsizes = ts.value();
        scratchNeed = std::max(scratchNeed, tsizes.buildScratch);
    }
    if (building.empty() && n == 0) return;
    if (!ensure_buffers(scratchNeed, n)) return;
    if (n > 0 && (capacity != tlasCapacity_ || !tlas_.id)) {
        if (tlas_.id) device_->destroy_accel_structure(tlas_);
        tlas_ = {};
        gpu::AccelStructureDesc d;
        d.kind = gpu::AccelKind::Tlas;
        d.size = tsizes.structure;
        d.label = "rt tlas";
        const Result<gpu::AccelStructure> made = device_->make_accel_structure(d);
        if (!made) {
            warn_once(warnedTlasMake_, "the top level structure could not be made", made.error().message);
            tlasCapacity_ = 0;
            return;
        }
        tlas_ = made.value();
        tlasCapacity_ = capacity;
        stats_.tlasBytes = tsizes.structure;
    }
    record_skin_dispatches(list, skinWork);
    // Build the new BLASes, ask for their compacted size.
    std::uint32_t built = 0;
    for (std::uint32_t id : building) {
        Blas& b = blas_.at(id);
        pending_.erase(std::remove(pending_.begin(), pending_.end(), id), pending_.end());
        gpu::BlasBuild bb;
        bb.dst = b.structure;
        bb.geometries = std::span<const gpu::AccelTriangles>(&b.triangles, 1);
        bb.flags = blas_flags();
        bb.scratch = scratch_;
        bb.scratchOffset = 0;
        if (const Result<void> r = list.build_blas(bb); !r) {
            b.state = State::Failed;
            warn_once(warnedBlasBuild_, "a BLAS could not be built", b.label + ": " + r.error().message);
            continue;
        }
        b.state = State::Built;
        ++built;
        const std::int32_t slot = take_slot();
        if (slot >= 0) {
            if (const Result<void> q = list.query_compacted_size(b.structure, sizeBuffer_, std::size_t(slot) * 8); q) {
                b.slot = slot;
                b.state = State::Queried;
                queried_.push_back(id);
            } else {
                freeSlots_.push_back(slot);
            }
        }
    }
    record_skin_builds(list, skinWork);
    // Copy the BLASes whose compacted size came back: the TLAS built below still names the original, the next frame swaps.
    std::uint32_t compacted = 0;
    for (std::uint32_t id : copyPending_) {
        Blas& b = blas_.at(id);
        if (const Result<void> r = list.copy_accel_structure(b.structure, b.compact, gpu::AccelCopyMode::Compact); !r) {
            device_->destroy_accel_structure(b.compact);
            b.compact = {};
            b.compactedSize = 0;
            b.state = State::Built;
            continue;
        }
        b.state = State::Swap;
        swap_.push_back(id);
        ++compacted;
    }
    copyPending_.clear();
    stats_.blasBuilt = built;
    stats_.blasCompacted = compacted;
    // The records and the TLAS. A BLAS whose build failed just now stays out of it (its instances would name a structure that was never
    // built): `kept` was chosen before the builds, so it is filtered again.
    kept.erase(std::remove_if(kept.begin(), kept.end(),
                              [&](const Item* it) {
                                  const auto b = blas_.find(it->blasId);
                                  const bool failed = b == blas_.end() || b->second.state == State::Failed;
                                  waiting += failed ? 1 : 0;
                                  waitingCasters += (failed && (it->instance.mask & kRtMaskCastsShadow)) ? 1 : 0;
                                  return failed;
                              }),
               kept.end());
    stats_.skippedNoBlas = waiting;
    stats_.untracedCasters = untracedCollected_ + waitingCasters;
    stats_.skinnedInstances =
        std::uint32_t(std::count_if(kept.begin(), kept.end(), [](const Item* it) { return it->skinned; }));
    const std::uint32_t count = std::uint32_t(kept.size());
    if (count == 0) {
        previous_.clear();
        return;
    }
    std::vector<gpu::AccelInstance> instances(count);
    std::vector<RtInstanceRecord> records(count);
    frame_.reserve(count);
    for (std::uint32_t i = 0; i < count; ++i) {
        const Item& it = *kept[i];
        instances[i] = it.instance;
        instances[i].customIndex = i;
        instances[i].blas = blas_.at(it.blasId).structure;
        records[i] = it.record;
        FrameInstance f;
        f.instance = instances[i];
        f.record = records[i];
        f.blasId = it.blasId;
        f.entityId = it.entityId;
        frame_.push_back(f);
    }
    gpu::BufferWrite w;
    w.data = gpu::Range{records.data(), std::size_t(count) * sizeof(RtInstanceRecord)};
    w.buffer = recordsBuffer_;
    w.dstOffset = 0;
    w.size = std::size_t(count) * sizeof(RtInstanceRecord);
    list.write_buffer(w);
    gpu::TlasBuild tb;
    tb.dst = tlas_;
    tb.instances = std::span<const gpu::AccelInstance>(instances.data(), instances.size());
    tb.flags = tlas_flags();
    tb.scratch = scratch_;
    tb.scratchOffset = 0;
    if (const Result<void> r = list.build_tlas(tb); !r) {
        warn_once(warnedTlasBuild_, "the top level structure could not be built", r.error().message);
        frame_.clear();
        return;
    }
    tlasBuilt_ = true;
    tlasInstances_ = count;
    stats_.instances = count;
    if (trackChanges_) {
        std::uint64_t h = 0xCBF29CE484222325ull;  // FNV-1a over the bytes the rays see
        auto mix = [&h](const void* data, std::size_t size) {
            const auto* p = static_cast<const unsigned char*>(data);
            for (std::size_t i = 0; i < size; ++i) h = (h ^ p[i]) * 0x100000001B3ull;
        };
        for (const FrameInstance& f : frame_) {
            mix(f.instance.transform, sizeof f.instance.transform);
            mix(&f.instance.mask, sizeof f.instance.mask);
            mix(&f.blasId, sizeof f.blasId);
            mix(&f.record, sizeof f.record);
        }
        mix(&count, sizeof count);
        if (stats_.skinnedInstances > 0) {
            ++skinSerial_;  // a skinned mesh moves its vertices: the frame is never the one before
            mix(&skinSerial_, sizeof skinSerial_);
        }
        contentHash_ = h ? h : 1;
    }
    previous_ = std::move(records);
}

}  // namespace fa::render
