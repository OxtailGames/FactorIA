#include "fa/render/probe.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/hash.h"
#include "fa/core/strings.h"

namespace fa::render {

namespace {

float sgn(float v) { return v < 0.0f ? -1.0f : 1.0f; }

}  // namespace

// ---- the octahedral map -----------------------------------------------------------------------------------------------------

Vec2 oct_fold(Vec2 e) {
    if (e.x > 1.0f) {
        e.x = 2.0f - e.x;
        e.y = -e.y;
    } else if (e.x < -1.0f) {
        e.x = -2.0f - e.x;
        e.y = -e.y;
    }
    if (e.y > 1.0f) {
        e.y = 2.0f - e.y;
        e.x = -e.x;
    } else if (e.y < -1.0f) {
        e.y = -2.0f - e.y;
        e.x = -e.x;
    }
    return e;
}

// The pole is +Y: (x, z) are the map's two axes. The inner diamond |x| + |z| <= 1 is the upper half-sphere.
Vec3 oct_decode(Vec2 e) {
    e = oct_fold(e);
    float x = e.x, z = e.y;
    float y = 1.0f - std::fabs(x) - std::fabs(z);
    if (y < 0.0f) {
        const float nx = (1.0f - std::fabs(z)) * sgn(x);
        const float nz = (1.0f - std::fabs(x)) * sgn(z);
        x = nx;
        z = nz;
    }
    const float len = std::sqrt(x * x + y * y + z * z);
    return len > 0.0f ? Vec3{x / len, y / len, z / len} : Vec3{0.0f, 1.0f, 0.0f};
}

Vec2 oct_encode(Vec3 d) {
    const float sum = std::fabs(d.x) + std::fabs(d.y) + std::fabs(d.z);
    if (!(sum > 0.0f)) return Vec2{0.0f, 0.0f};
    float x = d.x / sum, y = d.y / sum, z = d.z / sum;
    if (y < 0.0f) {
        const float nx = (1.0f - std::fabs(z)) * sgn(x);
        const float nz = (1.0f - std::fabs(x)) * sgn(z);
        x = nx;
        z = nz;
    }
    return Vec2{x, z};
}

Vec2 oct_texel_coordinate(int x, int y, int size) {
    return Vec2{(float(x) + 0.5f) / float(size) * 2.0f - 1.0f, (float(y) + 0.5f) / float(size) * 2.0f - 1.0f};
}

float oct_texel_weight(Vec2 e, int size) {
    // The area the texel's footprint covers on the sphere, from the derivatives of the direction (central differences over a
    // texel). Exact up to the texel's curvature; the weights are normalised by the caller.
    const float h = 1.0f / float(size);
    const Vec3 dx = oct_decode(Vec2{e.x + h, e.y}) - oct_decode(Vec2{e.x - h, e.y});
    const Vec3 dz = oct_decode(Vec2{e.x, e.y + h}) - oct_decode(Vec2{e.x, e.y - h});
    return length(cross(dx, dz));
}

// ---- the tile ---------------------------------------------------------------------------------------------------------------

int probe_resolution(int requested) {
    static constexpr int kSizes[4] = {32, 64, 128, 256};
    int best = kSizes[0];
    for (int s : kSizes)
        if (std::abs(s - requested) <= std::abs(best - requested)) best = s;  // a tie goes to the larger
    return best;
}

int probe_levels(int resolution) {
    int log2r = 0;
    while ((1 << (log2r + 1)) <= resolution) ++log2r;
    return std::clamp(log2r - 2, 1, kProbeMaxLevels);
}

float probe_level_roughness(int levels, int level) {
    return levels <= 1 ? 0.0f : float(std::clamp(level, 0, levels - 1)) / float(levels - 1);
}

int probe_sh_source(int resolution) {
    int j = 0;
    while ((resolution >> j) > 16) ++j;
    return j;
}

ProbeLayout probe_layout(int resolutionIn) {
    ProbeLayout l;
    l.resolution = probe_resolution(resolutionIn);
    l.levels = probe_levels(l.resolution);
    int y = 0;
    for (int k = 0; k < l.levels; ++k) {
        l.levelSize[k] = l.resolution >> k;
        l.levelX[k] = k == 0 ? 0 : l.resolution + 2 * kProbeBorder;
        l.levelY[k] = k <= 1 ? 0 : y;
        if (k >= 1) y = l.levelY[k] + l.levelSize[k] + 2 * kProbeBorder;
    }
    l.tileW = l.resolution + 2 * kProbeBorder + (l.levels > 1 ? (l.resolution >> 1) + 2 * kProbeBorder : 0);
    l.tileH = l.resolution + 2 * kProbeBorder + 1;
    l.shY = l.tileH - 1;
    return l;
}

int probe_page_width(int resolution) { return probe_layout(resolution).tileW; }
int probe_page_height(int resolution) { return probe_layout(resolution).tileH - 1; }

// ---- the atlas allocator ----------------------------------------------------------------------------------------------------

ProbeAtlasAllocator::Slot* ProbeAtlasAllocator::slot_of(std::uint64_t id, Shelf** shelf, int* index) {
    for (Shelf& s : shelves_)
        for (std::size_t i = 0; i < s.slots.size(); ++i)
            if (s.slots[i].used && s.slots[i].id == id) {
                if (shelf) *shelf = &s;
                if (index) *index = int(i);
                return &s.slots[i];
            }
    return nullptr;
}

const ProbeAtlasAllocator::Slot* ProbeAtlasAllocator::slot_of(std::uint64_t id, const Shelf** shelf, int* index) const {
    for (const Shelf& s : shelves_)
        for (std::size_t i = 0; i < s.slots.size(); ++i)
            if (s.slots[i].used && s.slots[i].id == id) {
                if (shelf) *shelf = &s;
                if (index) *index = int(i);
                return &s.slots[i];
            }
    return nullptr;
}

ProbeTile ProbeAtlasAllocator::tile_at(const Shelf& s, int index) const {
    return ProbeTile{index * s.w, s.y, s.resolution};
}

void ProbeAtlasAllocator::trim() {
    while (!shelves_.empty()) {
        bool anyUsed = false;
        for (const Slot& s : shelves_.back().slots) anyUsed = anyUsed || s.used;
        if (anyUsed) break;
        shelves_.pop_back();
    }
}

std::optional<ProbeTile> ProbeAtlasAllocator::acquire(std::uint64_t id, int resolutionIn, int importance,
                                                      std::uint64_t frame, std::vector<std::uint64_t>* evicted) {
    const int resolution = probe_resolution(resolutionIn);
    {
        Shelf* shelf = nullptr;
        int index = 0;
        if (Slot* s = slot_of(id, &shelf, &index)) {
            if (shelf->resolution == resolution) {
                s->importance = importance;
                s->lastUsed = std::max(s->lastUsed, frame);
                return tile_at(*shelf, index);
            }
            release(id);  // another resolution: a new place
        }
    }
    const ProbeLayout layout = probe_layout(resolution);
    const int w = layout.tileW, h = layout.tileH;
    if (w > size_ || h > size_) return std::nullopt;
    auto take = [&](Shelf& s, int index) {
        s.slots[std::size_t(index)] = Slot{id, true, importance, frame};
        return tile_at(s, index);
    };
    // 1. A free slot of a shelf of this resolution (the first, in the order the shelves and slots were made).
    for (Shelf& s : shelves_) {
        if (s.resolution != resolution) continue;
        for (std::size_t i = 0; i < s.slots.size(); ++i)
            if (!s.slots[i].used) return take(s, int(i));
    }
    // 2. A new shelf under the last one.
    int bottom = 0;
    for (const Shelf& s : shelves_) bottom = std::max(bottom, s.y + s.h);
    if (bottom + h <= size_) {
        Shelf s;
        s.y = bottom;
        s.h = h;
        s.w = w;
        s.resolution = resolution;
        s.slots.resize(std::size_t(size_ / w));
        shelves_.push_back(std::move(s));
        return take(shelves_.back(), 0);
    }
    // 3. The tile of a probe that matters less, in a shelf of this resolution; else a shelf at the bottom that holds nothing but
    // such probes is cleared, which gives its room to a new shelf.
    Shelf* victimShelf = nullptr;
    int victimIndex = -1;
    auto worse = [&](const Slot& a, const Slot& b) {  // a is a better victim than b
        if (a.importance != b.importance) return a.importance < b.importance;
        if (a.lastUsed != b.lastUsed) return a.lastUsed < b.lastUsed;
        return a.id > b.id;
    };
    for (Shelf& s : shelves_) {
        if (s.resolution != resolution) continue;
        for (std::size_t i = 0; i < s.slots.size(); ++i) {
            const Slot& c = s.slots[i];
            if (!c.used || c.importance >= importance) continue;
            if (victimIndex < 0 || worse(c, victimShelf->slots[std::size_t(victimIndex)])) {
                victimShelf = &s;
                victimIndex = int(i);
            }
        }
    }
    if (victimIndex >= 0) {
        Slot& v = victimShelf->slots[std::size_t(victimIndex)];
        if (evicted) evicted->push_back(v.id);
        return take(*victimShelf, victimIndex);
    }
    // The last shelf (any resolution) whose probes all matter less: clear it and make a shelf of this resolution there.
    if (!shelves_.empty()) {
        Shelf& last = shelves_.back();
        bool allLess = true;
        for (const Slot& c : last.slots) allLess = allLess && (!c.used || c.importance < importance);
        if (allLess && last.y + h <= size_) {
            std::vector<std::uint64_t> ids;
            for (const Slot& c : last.slots)
                if (c.used) ids.push_back(c.id);
            std::sort(ids.begin(), ids.end());
            if (evicted) evicted->insert(evicted->end(), ids.begin(), ids.end());
            const int y = last.y;
            shelves_.pop_back();
            Shelf s;
            s.y = y;
            s.h = h;
            s.w = w;
            s.resolution = resolution;
            s.slots.resize(std::size_t(size_ / w));
            shelves_.push_back(std::move(s));
            return take(shelves_.back(), 0);
        }
    }
    return std::nullopt;
}

void ProbeAtlasAllocator::release(std::uint64_t id) {
    if (Slot* s = slot_of(id)) {
        *s = Slot{};
        trim();
    }
}

void ProbeAtlasAllocator::touch(std::uint64_t id, std::uint64_t frame) {
    if (Slot* s = slot_of(id)) s->lastUsed = std::max(s->lastUsed, frame);
}

std::optional<ProbeTile> ProbeAtlasAllocator::find(std::uint64_t id) const {
    const Shelf* shelf = nullptr;
    int index = 0;
    if (slot_of(id, &shelf, &index)) return tile_at(*shelf, index);
    return std::nullopt;
}

int ProbeAtlasAllocator::count() const {
    int n = 0;
    for (const Shelf& s : shelves_)
        for (const Slot& c : s.slots) n += c.used ? 1 : 0;
    return n;
}

std::uint64_t ProbeAtlasAllocator::used_texels() const {
    std::uint64_t t = 0;
    for (const Shelf& s : shelves_)
        for (const Slot& c : s.slots) t += c.used ? std::uint64_t(s.w) * std::uint64_t(s.h) : 0;
    return t;
}

std::uint64_t ProbeAtlasAllocator::reserved_texels() const {
    std::uint64_t t = 0;
    for (const Shelf& s : shelves_) t += std::uint64_t(size_) * std::uint64_t(s.h);
    return t;
}

// ---- the scheduler ----------------------------------------------------------------------------------------------------------

void ProbeScheduler::set_budget(int faces) { budget_ = std::clamp(faces, 1, 6 * kProbeSlots); }

void ProbeScheduler::set_probes(const std::vector<ProbeSpec>& probes) {
    std::vector<State> next;
    next.reserve(probes.size());
    for (const ProbeSpec& spec : probes) {
        State s;
        auto it = std::find_if(probes_.begin(), probes_.end(), [&](const State& o) { return o.spec.id == spec.id; });
        if (it != probes_.end()) {
            s = *it;
            if (it->spec.resolution != spec.resolution) {  // the images of the capture under way no longer fit
                if (s.slot >= 0) slotBusy_[s.slot] = false;
                s.slot = -1;
                s.info = Info{};
            }
        }
        s.spec = spec;
        next.push_back(s);
    }
    // The slots of the probes that went away are free.
    for (const State& o : probes_)
        if (o.slot >= 0 && std::none_of(next.begin(), next.end(), [&](const State& n) { return n.spec.id == o.spec.id; }))
            slotBusy_[o.slot] = false;
    std::sort(next.begin(), next.end(), [](const State& a, const State& b) { return a.spec.id < b.spec.id; });
    probes_ = std::move(next);
}

void ProbeScheduler::refresh(std::uint64_t id) {
    for (State& s : probes_)
        if (s.spec.id == id) s.refresh = true;
}

ProbeScheduler::Info ProbeScheduler::info(std::uint64_t id) const {
    for (const State& s : probes_)
        if (s.spec.id == id) {
            Info i = s.info;
            i.pending = s.slot >= 0 || s.refresh || s.info.captures == 0 || s.spec.update != ProbeUpdateKind::OnDemand;
            return i;
        }
    return Info{};
}

std::vector<ProbeScheduler::Work> ProbeScheduler::plan(std::uint64_t frame) {
    std::vector<Work> work;
    int remaining = budget_;
    auto advance = [&](State& s) {
        const int n = std::min(remaining, kProbeFaces - s.info.facesDone);
        for (int i = 0; i < n; ++i) {
            const int face = s.info.facesDone + i;
            work.push_back(Work{s.spec.id, s.slot, face, face == kProbeFaces - 1});
        }
        s.info.facesDone += n;
        remaining -= n;
        if (s.info.facesDone >= kProbeFaces) {  // complete: the filtering follows in this frame
            s.info.facesDone = 0;
            ++s.info.captures;
            s.info.lastFrame = frame;
            slotBusy_[s.slot] = false;
            s.slot = -1;
            s.refresh = false;
        }
    };
    // Under way first, in the order of their slots (so a capture is never starved by a newcomer).
    for (int slot = 0; slot < kProbeSlots && remaining > 0; ++slot)
        for (State& s : probes_)
            if (s.slot == slot && remaining > 0) advance(s);
    // Then the probes that are due: never captured or asked for first, then the every-frame ones, the more important, the one captured
    // longest ago, the smaller id.
    while (remaining > 0) {
        int slot = -1;
        for (int i = 0; i < kProbeSlots && slot < 0; ++i)
            if (!slotBusy_[i]) slot = i;
        if (slot < 0) break;
        State* best = nullptr;
        auto better = [](const State& a, const State& b) {
            const bool an = a.info.captures == 0 || a.refresh, bn = b.info.captures == 0 || b.refresh;
            if (an != bn) return an;
            const bool ae = a.spec.update == ProbeUpdateKind::EveryFrame, be = b.spec.update == ProbeUpdateKind::EveryFrame;
            if (ae != be) return ae;
            if (a.spec.importance != b.spec.importance) return a.spec.importance > b.spec.importance;
            if (a.info.lastFrame != b.info.lastFrame) return a.info.lastFrame < b.info.lastFrame;
            return a.spec.id < b.spec.id;
        };
        for (State& s : probes_) {
            if (s.slot >= 0) continue;
            const bool due = s.info.captures == 0 || s.refresh || s.spec.update != ProbeUpdateKind::OnDemand;
            // A probe captured this very frame waits for the next one (an every-frame probe is due again every frame, not twice in one).
            if (!due || s.info.lastFrame == frame) continue;
            if (!best || better(s, *best)) best = &s;
        }
        if (!best) break;
        best->slot = slot;
        slotBusy_[slot] = true;
        advance(*best);
    }
    return work;
}

// ---- baked probes -----------------------------------------------------------------------------------------------------------

Json probe_manifest_to_json(const ProbeManifest& m) {
    Json sh = Json::array();
    for (int i = 0; i < kProbeShCoefficients; ++i)
        sh.push_back(Json::array({double(m.sh[i][0]), double(m.sh[i][1]), double(m.sh[i][2])}));
    Json j = Json::object();
    j["version"] = m.version;
    j["resolution"] = m.resolution;
    j["levels"] = m.levels;
    j["page"] = m.page;
    j["entity"] = m.entity;
    j["hash"] = m.hash;
    j["sh"] = sh;
    return j;
}

Result<ProbeManifest> probe_manifest_from_json(const Json& j, const std::string& name) {
    auto bad = [&](const std::string& pointer, const std::string& what, const std::string& hint) {
        return make_error(name + pointer + ": " + what, hint);
    };
    if (!j.is_object())
        return bad("", "is not a JSON object.", "Bake the probe again with probe.bake; do not edit this file by hand.");
    ProbeManifest m;
    if (!j.contains("version") || !j["version"].is_number_integer() || j["version"].get<int>() != kProbeManifestVersion)
        return bad("/version", "is missing or not " + std::to_string(kProbeManifestVersion) + ".",
                   "The file is from another engine version: bake the probe again with probe.bake.");
    m.version = kProbeManifestVersion;
    if (!j.contains("resolution") || !j["resolution"].is_number_integer())
        return bad("/resolution", "is missing or not a whole number.", "Bake the probe again with probe.bake.");
    const long long res = j["resolution"].get<long long>();
    if (res != 32 && res != 64 && res != 128 && res != 256)
        return bad("/resolution", "is " + std::to_string(res) + ", not 32, 64, 128 or 256.",
                   "Bake the probe again with probe.bake.");
    m.resolution = int(res);
    m.levels = probe_levels(m.resolution);
    if (j.contains("levels") && j["levels"].is_number_integer() && j["levels"].get<int>() != m.levels)
        return bad("/levels", "is " + std::to_string(j["levels"].get<int>()) + " but a map of " + std::to_string(m.resolution) +
                                  " has " + std::to_string(m.levels) + ".",
                   "Bake the probe again with probe.bake.");
    if (!j.contains("page") || !j["page"].is_string() || j["page"].get<std::string>().empty())
        return bad("/page", "is missing or not a path.", "Bake the probe again with probe.bake.");
    m.page = j["page"].get<std::string>();
    m.entity = j.value("entity", std::string());
    m.hash = j.value("hash", std::string());
    if (!j.contains("sh") || !j["sh"].is_array() || j["sh"].size() != std::size_t(kProbeShCoefficients))
        return bad("/sh", "is missing or does not have nine coefficients.", "Bake the probe again with probe.bake.");
    for (int i = 0; i < kProbeShCoefficients; ++i) {
        const Json& c = j["sh"][std::size_t(i)];
        if (!c.is_array() || c.size() != 3)
            return bad("/sh/" + std::to_string(i), "is not [r, g, b].", "Bake the probe again with probe.bake.");
        for (int k = 0; k < 3; ++k) {
            const Json& v = c[std::size_t(k)];
            if (!v.is_number())
                return bad("/sh/" + std::to_string(i) + "/" + std::to_string(k), "is not a number.",
                           "Bake the probe again with probe.bake.");
            const double d = v.get<double>();
            m.sh[i][k] = std::isfinite(d) ? float(std::clamp(d, -65000.0, 65000.0)) : 0.0f;
        }
    }
    return m;
}

fa::ShL2 probe_sh_from_page(const ImageF& page, int resolutionIn) {
    const int resolution = probe_resolution(resolutionIn);
    fa::ShL2 sh;
    if (page.empty() || page.width < resolution + 2 * kProbeBorder || page.height < resolution + 2 * kProbeBorder) return sh;
    double sum[9][3] = {};
    double wsum = 0.0;
    for (int y = 0; y < resolution; ++y)
        for (int x = 0; x < resolution; ++x) {
            const Vec2 e = oct_texel_coordinate(x, y, resolution);
            const double w = double(oct_texel_weight(e, resolution));
            const Vec3 d = oct_decode(e);
            float basis[9];
            fa::sh_basis(d, basis);
            const float* px = page.at(x + kProbeBorder, y + kProbeBorder);
            for (int k = 0; k < 9; ++k)
                for (int c = 0; c < 3; ++c) sum[k][c] += double(px[c]) * double(basis[k]) * w;
            wsum += w;
        }
    if (!(wsum > 0.0)) return sh;
    const double norm = 4.0 * 3.14159265358979323846 / wsum;
    for (int k = 0; k < 9; ++k) sh.c[k] = Vec3{float(sum[k][0] * norm), float(sum[k][1] * norm), float(sum[k][2] * norm)};
    return sh;
}

std::string probe_hash_hex(const std::vector<std::uint8_t>& bytes) { return sha256_hex(bytes.data(), bytes.size()).substr(0, 16); }

Result<ImageF> probe_page_from_rgbe(const std::vector<std::uint8_t>& rgbe, int resolution) {
    const int w = probe_page_width(resolution), h = probe_page_height(resolution);
    if (rgbe.size() != std::size_t(w) * std::size_t(h) * 4u)
        return make_error("the RGBE texels of a probe page are " + std::to_string(rgbe.size()) + " bytes, not " +
                              std::to_string(std::size_t(w) * std::size_t(h) * 4u),
                          "This is a bug of the renderer's read-back; report it.");
    auto page = ImageF::create(w, h, 3);
    if (!page) return page.error();
    ImageF image = std::move(page.value());
    for (std::size_t i = 0; i < std::size_t(w) * std::size_t(h); ++i) {
        const std::uint8_t* p = &rgbe[i * 4];
        float* o = &image.data[i * 3];
        if (p[3] == 0) continue;
        const float f = std::ldexp(1.0f, int(p[3]) - 136);
        for (int c = 0; c < 3; ++c) o[c] = float(p[c]) * f;
    }
    return image;
}

}  // namespace fa::render
