#include "particle_preview.h"

#include <algorithm>
#include <cmath>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"

namespace fa::editor {

namespace {

std::uint64_t mix(std::uint64_t h, std::uint64_t v) {
    return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL;
}

ParticleEmitter emitter_of(const VfxPart& part) {
    ParticleEmitter pe;
    ensure_builtin_components();
    (void)object_patch_from_json(World::type_of<ParticleEmitter>(), &pe, part.emitter);
    return pe;
}

}  // namespace

ParticlePreview::ParticlePreview() { rebuild(); }
ParticlePreview::~ParticlePreview() = default;

void ParticlePreview::set_document(std::shared_ptr<const VfxDoc> doc) {
    if (doc == doc_) return;
    doc_ = std::move(doc);
    lengthValid_ = false;
    stale_ = true;
    seek(target_time());
}

void ParticlePreview::set_seed(std::uint32_t seed) {
    if (seed == seed_) return;
    seed_ = seed;
    stale_ = true;
    seek(target_time());
}

void ParticlePreview::rebuild() {
    sims_.clear();
    fired_.clear();
    dots_.clear();
    lights_.clear();
    emitters_ = 0;
    steps_ = 0;
    time_ = 0.0;
    carry_ = 0.0;
    stale_ = false;
    world_ = std::make_unique<World>();
    vfx_ = kNullEntity;
    if (!doc_) return;
    vfx_ = world_->create("preview");
    auto& v = world_->add<Vfx>(vfx_);
    v.effect = "preview.vfx.json";
    v.autoplay = true;
    v.autoDestroy = false;
    snapshot();
}

void ParticlePreview::seek(double t) {
    const double target = std::clamp(t, 0.0, kPreviewMaxTime);
    // Step number n is at time n * kPreviewStep: counting whole steps keeps the same time from drifting between a seek and playing to it.
    targetSteps_ = int(std::floor(target / kPreviewStep + 1e-9));
    // A later moment goes on from the state the preview has; an earlier one, or a changed document or seed, starts again.
    if (stale_ || targetSteps_ < steps_) rebuild();
    if (!doc_) {
        time_ = double(targetSteps_) * kPreviewStep;
        steps_ = targetSteps_;
        return;
    }
    carry_ = 0.0;
    catch_up();
}

void ParticlePreview::begin_frame() {
    framed_ = true;
    slicedThisFrame_ = false;
}

void ParticlePreview::catch_up() {
    if (framed_) {
        if (slicedThisFrame_) return;  // seek, catch_up and advance of one frame share one bounded slice
        slicedThisFrame_ = true;
    }
    run_slice();
}

void ParticlePreview::run_slice() {
    if (!doc_ || !catching_up()) return;
    long work = 0;
    int n = 0;
    while (steps_ < targetSteps_ && n < kPreviewStepBudget && work < kPreviewWorkBudget) {
        work += step_once();
        ++n;
    }
    snapshot();
}

void ParticlePreview::settle() {
    while (catching_up() && doc_) run_slice();
}

void ParticlePreview::advance(double dt) {
    if (!doc_ || dt <= 0.0) return;
    if (catching_up()) {  // a seek is still on its way: finish it before playing on from there
        catch_up();
        return;
    }
    carry_ += dt;
    int n = 0;
    while (carry_ >= kPreviewStep && time_ < kPreviewMaxTime && n < 120) {
        carry_ -= kPreviewStep;
        step_once();
        ++n;
    }
    targetSteps_ = steps_;
    if (n > 0) snapshot();
    if (n == 120 || time_ >= kPreviewMaxTime) carry_ = 0.0;
}

long ParticlePreview::step_once() {
    if (!doc_ || !world_) return kPreviewStepCost;
    VfxHost host;
    host.load = [doc = doc_](const std::string&) { return doc; };
    // Sounds and commands are listed, not run.
    host.play_sound = [](const std::string&, float, float, const std::string&) { return true; };
    host.call = [](const std::string&, const Json&) { return std::string(); };
    update_vfx(*world_, float(kPreviewStep), host);
    ++steps_;
    time_ = double(steps_) * kPreviewStep;

    // Each emitter has its own sim, seeded from its part and the preview seed (never from a clock or the world's rng).
    Vfx* vfx = world_->get<Vfx>(vfx_);
    std::map<std::uint64_t, int> partOf;
    if (vfx)
        for (const VfxChild& c : vfx->rt.children) partOf[c.entity.bits()] = c.part;
    std::map<std::uint64_t, bool> seen;
    world_->each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        seen[e.bits()] = true;
        ParticleSim& sim = sims_[e.bits()];
        if (!sim.seeded()) {
            const auto it = partOf.find(e.bits());
            sim.seed(mix(mix(1469598103934665603ULL, std::uint64_t(it == partOf.end() ? 0 : it->second + 1)), seed_));
        }
        ParticleEnv env;
        env.emitter = world_->world_matrix(e);
        env.is3D = em.is3D;
        sim.step(em, env, float(kPreviewStep));
    });
    for (auto it = sims_.begin(); it != sims_.end();) {
        if (seen.count(it->first))
            ++it;
        else
            it = sims_.erase(it);
    }
    if (vfx) {
        fired_.clear();
        for (std::size_t i = 0; i < doc_->parts.size() && i < 32; ++i)
            if ((vfx->rt.started & (1u << i)) &&
                (doc_->parts[i].kind == VfxPartKind::Sound || doc_->parts[i].kind == VfxPartKind::Command))
                fired_.push_back(int(i));
    }
    world_->flush();
    long particles = 0;
    for (const auto& [bits, sim] : sims_) particles += long(sim.particles.size());
    return kPreviewStepCost + particles;
}

void ParticlePreview::snapshot() {
    dots_.clear();
    lights_.clear();
    emitters_ = 0;
    if (!world_) return;
    world_->each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        ++emitters_;
        const auto it = sims_.find(e.bits());
        if (it == sims_.end()) return;
        const ParticleSim& sim = it->second;
        const Mat4 m = world_->world_matrix(e);
        for (const Particle& p : sim.particles) {
            const int g = std::clamp(int(p.group), 0, sim.group_count() - 1);
            const ParticleEmitter& c = sim.group_emitter(g, em);
            const ParticleStyle& st = sim.group_style(g);
            const float t = p.life > 0.0f ? std::clamp(p.age / p.life, 0.0f, 1.0f) : 1.0f;
            PreviewDot d;
            const Vec3 at = em.worldSpace ? p.pos : m.transform_point(p.pos);
            d.x = at.x;
            d.y = -at.y;
            d.size = lerp(c.startSize, c.endSize, t) * st.size.eval_or(t, 1.0f) * p.sizeScale;
            d.color = st.color.empty() ? lerp(c.startColor, c.endColor, t) : st.color.eval(t);
            d.color.a *= st.alpha.eval_or(t, 1.0f);
            d.additive = c.blend == BlendMode::Additive;
            d.rotation = p.rotation;
            if (d.size > 0.0f && d.color.a > 0.0f) dots_.push_back(d);
        }
    });
    world_->each<Light2D>([&](Entity e, Light2D& l) {
        const Vec3 at = world_->world_matrix(e).translation();
        lights_.push_back({at.x, -at.y, l.radius, l.color, l.intensity});
    });
    world_->each<Light>([&](Entity e, Light& l) {
        if (l.type == LightType::Directional) return;
        const Vec3 at = world_->world_matrix(e).translation();
        lights_.push_back({at.x, -at.y, l.range * 32.0f, l.color, l.intensity});
    });
}

double ParticlePreview::timeline_length() const {
    if (!doc_) return 1.0;
    if (lengthValid_) return length_;
    // The same wait the effect system gives an emitter's entity: lifetime with its variance, the trail and the sub-emitters (worked out once
    // per document, not every frame: it parses the emitter fields).
    double longest = 0.0;
    for (const VfxPart& p : doc_->parts)
        if (p.kind == VfxPartKind::Emitter)
            longest = std::max(longest, vfx_emitter_drain_seconds(*world_, emitter_of(p)));
    length_ = std::clamp(doc_->duration + longest + kVfxDrainSlack, 0.25, kPreviewMaxTime);
    lengthValid_ = true;
    return length_;
}

bool ParticlePreview::finished() const {
    if (!doc_ || !world_) return true;
    const Vfx* v = world_->get<Vfx>(vfx_);
    return v && v->rt.finished && dots_.empty();
}

}  // namespace fa::editor
