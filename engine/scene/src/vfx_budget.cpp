#include "fa/scene/vfx_budget.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "fa/core/det_math.h"
#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/particles.h"

namespace fa {

namespace {

constexpr double kStep = 1.0 / 60.0;
constexpr int kTimelineSamples = 24;
constexpr double kExtraSeconds = 30.0;  // past kVfxMaxDuration: the longest the measuring plays on
constexpr int kMinFixCap = 4;           // a suggested maxParticles below this is no longer the effect: no fix is offered
constexpr double kMinFixSize = 0.5;     // the same for a suggested startSize, in design pixels

std::uint64_t mix(std::uint64_t h, std::uint64_t v) { return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL; }

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

double round2(double v) { return std::round(v * 100.0) / 100.0; }

// Sums `f(size)` over the quads one sim draws now (size in the emitter's own unit: design pixels, or world units for a 3D emitter).
// A particle that is invisible (no size, no alpha) costs nothing.
template <class F>
double sum_quads(const ParticleSim& sim, const ParticleEmitter& root, F&& f) {
    double total = 0.0;
    for (const Particle& p : sim.particles) {
        const int g = std::clamp(int(p.group), 0, sim.group_count() - 1);
        const ParticleEmitter& c = sim.group_emitter(g, root);
        const ParticleStyle& st = sim.group_style(g);
        const float t = p.life > 0.0f ? std::clamp(p.age / p.life, 0.0f, 1.0f) : 1.0f;
        const float size = lerp(c.startSize, c.endSize, t) * st.size.eval_or(t, 1.0f) * p.sizeScale;
        const float alpha = (st.color.empty() ? lerp(c.startColor, c.endColor, t) : st.color.eval(t)).a * st.alpha.eval_or(t, 1.0f);
        if (size > 0.0f && alpha > 0.0f) total += f(p, double(size));
    }
    return total;
}

// The area, in square design pixels, of the quads of a 2D or screen-space emitter.
double quad_area(const ParticleSim& sim, const ParticleEmitter& root) {
    return sum_quads(sim, root, [](const Particle&, double size) { return size * size; });
}

// The screens covered by the quads of a 3D emitter seen through `cam`. The effect sits on the camera's axis `distance` in front of it and
// the sim's positions are world positions around it, so a particle's depth is distance + its offset along the view axis. A quad is a
// camera-facing square of `size` world units; one wholly outside the view or not past the near plane costs nothing, one partly outside
// counts whole (the edge is not clipped).
double quad_screens_3d(const ParticleSim& sim, const ParticleEmitter& root, const VfxBudgetCamera& cam, double distance, double aspect) {
    return sum_quads(sim, root, [&](const Particle& p, double size) {
        const double depth = distance + double(dot(p.pos, cam.forward));
        double halfH = cam.orthoHalfHeight;
        if (cam.perspective) {
            if (depth <= std::max(cam.nearPlane, 1e-6)) return 0.0;
            halfH = depth * det::f64::tan(cam.fovDegrees * 0.5 * 3.14159265358979323846 / 180.0);
        }
        if (!(halfH > 1e-9)) return 0.0;
        const double halfW = halfH * aspect;
        const double x = double(dot(p.pos, cam.right)), y = double(dot(p.pos, cam.up));
        if (std::fabs(x) - size * 0.5 > halfW || std::fabs(y) - size * 0.5 > halfH) return 0.0;
        return size * size / (4.0 * halfH * halfW);
    });
}

std::string pointer_of(int part, const char* field) { return "/parts/" + std::to_string(part) + "/emitter/" + field; }

std::string label_of(const VfxEmitterBudget& b) {
    return b.name.empty() ? std::format("emitter {}", b.part) : std::format("'{}'", b.name);
}

Json edit_set(const std::string& path, const std::string& pointer, const Json& value) {
    return Json::object({{"command", "vfx.edit"},
                         {"args", Json::object({{"path", path}, {"op", "set"}, {"pointer", pointer}, {"value", value}})}});
}

}  // namespace

const VfxBudgetLimits& vfx_budget_limits(std::string_view name) {
    static const VfxBudgetLimits phone{"phone", 300, 1.5, 5};
    static const VfxBudgetLimits desktop{"desktop", 2000, 4.0, 8};
    return name == "desktop" ? desktop : phone;
}

VfxBudget vfx_measure(const VfxDoc& doc, const VfxBudgetOptions& options) {
    ensure_builtin_components();
    const VfxBudgetLimits& limits = vfx_budget_limits(options.preset);
    VfxBudget out;
    out.path = doc.path;
    out.preset = limits.name;
    out.duration = doc.duration;
    const double viewArea = std::max(1.0, options.viewWidth * options.viewHeight);
    const double aspect = std::max(1.0, options.viewWidth) / std::max(1.0, options.viewHeight);

    auto shared = std::make_shared<const VfxDoc>(doc);
    World world;
    const Entity root = world.create("measure");
    auto& v = world.add<Vfx>(root);
    v.effect = "measure.vfx.json";
    v.autoplay = true;
    v.autoDestroy = false;

    VfxHost host;
    host.load = [shared](const std::string&) { return shared; };  // sounds and commands are not run: no play_sound, no call

    double longest = 0.0;
    for (const VfxPart& p : doc.parts) {
        if (p.kind == VfxPartKind::Emitter) {
            ParticleEmitter pe;
            (void)object_patch_from_json(World::type_of<ParticleEmitter>(), &pe, p.emitter);
            longest = std::max(longest, double(pe.lifetime) * (1.0 + double(pe.lifetimeVariance)));
            ++out.emitters;
        } else if (p.kind == VfxPartKind::Light) {
            ++out.lights;
        }
    }
    const double limit = std::min(kVfxMaxDuration + kExtraSeconds, std::max(doc.duration, 0.0) + longest + kVfxDrainSlack + 1.0);
    const int maxSteps = int(std::ceil(limit / kStep));

    std::map<std::uint64_t, ParticleSim> sims;
    std::map<int, VfxEmitterBudget> byPart;
    std::map<int, bool> is3d;
    std::map<std::uint64_t, int> partOf;  // VfxChild::origin keeps the part of an emitter that was detached to drain (an effect of duration 0 ends in the step that makes it)
    std::vector<VfxSample> raw;
    double overdrawSum = 0.0;
    int overdrawSteps = 0;
    double lastAlive = 0.0;
    long long particleSteps = 0;

    for (int s = 1; s <= maxSteps; ++s) {
        update_vfx(world, float(kStep), host);
        const double t = double(s) * kStep;
        const Vfx* vfx = world.get<Vfx>(root);
        if (vfx)
            for (const VfxChild& c : vfx->rt.children)
                if (c.origin >= 0) partOf[c.entity.bits()] = c.origin;
        std::map<std::uint64_t, bool> seen;
        int total = 0;
        double screens = 0.0;   // the screens of quad area of all emitters at this step
        world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
            seen[e.bits()] = true;
            const auto pit = partOf.find(e.bits());
            const int part = pit == partOf.end() ? 0 : pit->second;
            ParticleSim& sim = sims[e.bits()];
            if (!sim.seeded()) sim.seed(mix(mix(1469598103934665603ULL, std::uint64_t(part + 1)), options.seed));
            ParticleEnv env;
            env.emitter = world.world_matrix(e);
            env.is3D = em.is3D;
            sim.step(em, env, float(kStep));
            const int n = int(sim.particles.size());
            const double a = em.is3D ? (options.camera ? quad_screens_3d(sim, em, *options.camera, options.cameraDistance, aspect) : 0.0)
                                     : quad_area(sim, em) / viewArea;
            VfxEmitterBudget& b = byPart[part];
            if (em.is3D && !is3d.count(part)) {
                is3d[part] = true;
                const std::string who = part >= 0 && part < int(doc.parts.size()) && !doc.parts[std::size_t(part)].name.empty()
                                            ? "'" + doc.parts[std::size_t(part)].name + "'" : "emitter " + std::to_string(part);
                if (options.camera) {
                    out.camera3d = true;
                    out.notes.push_back(std::format("{} is a 3D emitter: its overdraw is measured by projecting its quads through the project's main camera ({}), with the effect {:.1f} m in "
                                                    "front of it on its axis; a quad partly outside the view counts whole.", who,
                                                    options.camera->perspective ? std::format("perspective, {:.0f} degrees vertical field of view", options.camera->fovDegrees)
                                                                                : std::format("orthographic, {:.1f} units tall", options.camera->orthoHalfHeight * 2.0),
                                                    options.cameraDistance));
                } else {
                    out.notes.push_back(std::format("{} is a 3D emitter: its particles are counted, but its overdraw is not measured: there is no camera to project its quads through "
                                                    "(its size is in world units, the camera decides how much screen it covers). Load a scene that has a primary Camera, then measure again.", who));
                }
            }
            b.part = part;
            if (b.name.empty() && part >= 0 && part < int(doc.parts.size())) b.name = doc.parts[std::size_t(part)].name;
            b.maxParticles = std::min(em.maxParticles, kParticleHardCap);
            b.startSize = em.startSize;
            if (n > b.peakParticles) {
                b.peakParticles = n;
                b.peakAt = t;
            }
            b.peakOverdraw = std::max(b.peakOverdraw, a);
            total += n;
            screens += a;
        });
        for (auto it = sims.begin(); it != sims.end();) {
            if (seen.count(it->first)) ++it;
            else it = sims.erase(it);
        }
        world.flush();
        ++out.steps;
        particleSteps += total;
        const double od = screens;
        raw.push_back({t, total, od});
        if (total > out.peakParticles) {
            out.peakParticles = total;
            out.peakAt = t;
        }
        if (od > out.peakOverdraw) {
            out.peakOverdraw = od;
            out.peakOverdrawAt = t;
        }
        if (total > 0) {
            overdrawSum += od;
            ++overdrawSteps;
            lastAlive = t;
        }
        const bool over = vfx && vfx->rt.finished;
        if (over && total == 0) break;
        if (particleSteps >= options.maxParticleUpdates) {
            // Few steps can still be a lot of work: up to 8 emitters of 10 000 particles each is 80 000 updates per step.
            out.truncated = true;
            const std::string updates = options.maxParticleUpdates >= 1'000'000 ? std::format("{} million", options.maxParticleUpdates / 1'000'000)
                                                                                : std::to_string(options.maxParticleUpdates);
            out.notes.push_back(std::format("The measuring stopped at {:.2f} s after {} particle updates (the effect holds a great many particles for a long time): "
                                            "the numbers cover the first {:.2f} s only.", t, updates, t));
            break;
        }
        if (s == maxSteps) out.truncated = true;
    }
    out.peakOverdraw = round2(out.peakOverdraw);   // what the message prints is what the finding compares
    out.settledAt = lastAlive;
    out.meanOverdraw = overdrawSteps > 0 ? overdrawSum / overdrawSteps : 0.0;

    // The timeline: each slice keeps its largest particle count and overdraw (a peak between two samples must not be missed).
    if (!raw.empty()) {
        const int slices = std::min<int>(kTimelineSamples, int(raw.size()));
        for (int i = 0; i < slices; ++i) {
            const std::size_t a = raw.size() * std::size_t(i) / std::size_t(slices);
            const std::size_t b = std::max(a + 1, raw.size() * std::size_t(i + 1) / std::size_t(slices));
            VfxSample smp;
            smp.t = round3(raw[a].t);
            for (std::size_t k = a; k < b && k < raw.size(); ++k) {
                smp.particles = std::max(smp.particles, raw[k].particles);
                smp.overdraw = std::max(smp.overdraw, raw[k].overdraw);
            }
            smp.overdraw = round2(smp.overdraw);
            out.timeline.push_back(smp);
        }
    }
    for (auto& [part, b] : byPart) {
        b.capped = b.peakParticles >= b.maxParticles && b.maxParticles > 0;
        out.perEmitter.push_back(b);
    }

    // Findings against the preset.
    const VfxEmitterBudget* mostParticles = nullptr;
    const VfxEmitterBudget* mostOverdraw = nullptr;
    for (const VfxEmitterBudget& b : out.perEmitter) {
        if (!mostParticles || b.peakParticles > mostParticles->peakParticles) mostParticles = &b;
        if (!mostOverdraw || b.peakOverdraw > mostOverdraw->peakOverdraw) mostOverdraw = &b;
    }
    if (out.peakParticles > limits.maxParticles && mostParticles) {
        // Lower the cap of the biggest emitter by the share it has to give up, so the total falls toward the limit.
        const int over = out.peakParticles - limits.maxParticles;
        const int cap = mostParticles->peakParticles - over;
        VfxBudgetFinding f;
        f.kind = "particles";
        f.severity = "warning";
        f.pointer = pointer_of(mostParticles->part, "maxParticles");
        f.message = std::format("{} particles live at once at {:.2f} s (a {} budget is {}); {} holds {} of them.", out.peakParticles, out.peakAt,
                                limits.name, limits.maxParticles, label_of(*mostParticles), mostParticles->peakParticles);
        if (cap >= kMinFixCap) {
            f.hint = std::format("Lower its maxParticles to {} (this moves the total toward the limit; run vfx.budget again), or its burst / rate, or its lifetime: "
                                 "fewer, bigger particles read the same on a small screen.", cap);
            f.fix = edit_set(doc.path, f.pointer, cap);
        } else {
            f.hint = std::format("The other emitters hold {} of them already, so lowering this one alone would leave it with {} particles: no single edit is offered. "
                                 "Lower the burst / rate or lifetime of several emitters, or merge them.", out.peakParticles - mostParticles->peakParticles, std::max(cap, 0));
        }
        out.findings.push_back(std::move(f));
    }
    if (out.peakOverdraw > limits.maxOverdraw && mostOverdraw && mostOverdraw->peakOverdraw > 0.0) {
        // The area of the biggest emitter must give up what the others cannot absorb: its share d falls to (limit - others). Area goes with the
        // square of the size, so the size falls by sqrt of that ratio (exact only if the sizes are constant and the peaks fall at the same moment).
        const double d = mostOverdraw->peakOverdraw;
        const double others = std::max(0.0, out.peakOverdraw - d);
        const double room = limits.maxOverdraw - others;
        const double size = room > 0.0 ? std::floor(double(mostOverdraw->startSize) * std::sqrt(room / d) * 10.0) / 10.0 : 0.0;
        VfxBudgetFinding f;
        f.kind = "overdraw";
        f.severity = "warning";
        f.pointer = pointer_of(mostOverdraw->part, "startSize");
        f.message = std::format("The particles cover {:.2f} screens of quad area at once, at {:.2f} s (a {} budget is {:.1f}); {} covers the most.",
                                out.peakOverdraw, out.peakOverdrawAt, limits.name, limits.maxOverdraw, label_of(*mostOverdraw));
        if (size >= kMinFixSize) {
            f.hint = std::format("Make its particles smaller (startSize {:.1f} moves the total toward the limit if their size is constant; run vfx.budget again), or give it fewer "
                                 "particles. Large soft additive sprites stacked on each other cost the most.", size);
            f.fix = edit_set(doc.path, f.pointer, size);
        } else {
            f.hint = std::format("The other emitters cover {:.2f} screens already, so smaller particles of this one alone would not get there: no single edit is offered. "
                                 "Give several emitters fewer or smaller particles. Large soft additive sprites stacked on each other cost the most.", others);
        }
        out.findings.push_back(std::move(f));
    }
    if (out.emitters > limits.maxEmitters) {
        VfxBudgetFinding f;
        f.kind = "emitters";
        f.severity = "warning";
        f.pointer = "/parts";
        f.message = std::format("{} emitters in one effect (a {} budget is {}).", out.emitters, limits.name, limits.maxEmitters);
        f.hint = "Merge emitters that differ only in colour, or remove the one that adds least to the filmstrip.";
        f.fix = Json();
        out.findings.push_back(std::move(f));
    }
    return out;
}

}  // namespace fa
