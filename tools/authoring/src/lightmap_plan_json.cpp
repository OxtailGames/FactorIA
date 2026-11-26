// A bake Plan as JSON and back (lightmap_bake_job.h): what the bake's helper process is given. The Plan is plain data (the World was already read), so
// the child needs nothing of the editor's memory: the same Plan gives the same bake. Floats are written as doubles, which a float converts to and
// from exactly, so the child sees the numbers the parent planned with.
#include <cmath>
#include <cstdint>
#include <string>

#include "fa/core/strings.h"
#include "lightmap_bake_job.h"

namespace fa::lightmap_job {

namespace {

Json vec3_json(Vec3 v) { return Json::array({v.x, v.y, v.z}); }

struct Reader {
    std::string error;
    bool ok() const { return error.empty(); }
    void fail(const std::string& pointer, const std::string& what) {
        if (error.empty()) error = pointer + ": " + what;
    }
    const Json* member(const Json& o, const std::string& base, const char* key) {
        if (!o.is_object()) {
            fail(base, "must be an object.");
            return nullptr;
        }
        auto it = o.find(key);
        if (it == o.end()) {
            fail(base + "/" + key, "is missing.");
            return nullptr;
        }
        return &*it;
    }
    double number(const Json& o, const std::string& base, const char* key) {
        const Json* v = member(o, base, key);
        if (!v) return 0;
        if (!v->is_number()) {
            fail(base + "/" + key, "must be a number.");
            return 0;
        }
        const double d = v->get<double>();
        if (!std::isfinite(d)) fail(base + "/" + key, "must be finite.");
        return d;
    }
    float f(const Json& o, const std::string& base, const char* key) { return float(number(o, base, key)); }
    int i(const Json& o, const std::string& base, const char* key) {
        const double d = number(o, base, key);
        if (std::fabs(d) > 2147483647.0 || d != std::floor(d)) {
            fail(base + "/" + key, "must be a whole number that fits 32 bits.");
            return 0;
        }
        return int(d);
    }
    std::uint64_t u64(const Json& o, const std::string& base, const char* key) {
        const Json* v = member(o, base, key);
        if (!v) return 0;
        if (!v->is_number_unsigned()) {
            fail(base + "/" + key, "must be a non-negative whole number.");
            return 0;
        }
        return v->get<std::uint64_t>();
    }
    bool b(const Json& o, const std::string& base, const char* key) {
        const Json* v = member(o, base, key);
        if (!v) return false;
        if (!v->is_boolean()) {
            fail(base + "/" + key, "must be true or false.");
            return false;
        }
        return v->get<bool>();
    }
    std::string s(const Json& o, const std::string& base, const char* key) {
        const Json* v = member(o, base, key);
        if (!v) return {};
        if (!v->is_string()) {
            fail(base + "/" + key, "must be a string.");
            return {};
        }
        return v->get<std::string>();
    }
    Vec3 v3(const Json& o, const std::string& base, const char* key) {
        const Json* v = member(o, base, key);
        if (!v) return {};
        if (!v->is_array() || v->size() != 3 || !(*v)[0].is_number() || !(*v)[1].is_number() || !(*v)[2].is_number()) {
            fail(base + "/" + key, "must be three numbers.");
            return {};
        }
        return {(*v)[0].get<float>(), (*v)[1].get<float>(), (*v)[2].get<float>()};
    }
    const Json* array(const Json& o, const std::string& base, const char* key) {
        const Json* v = member(o, base, key);
        if (v && !v->is_array()) {
            fail(base + "/" + key, "must be an array.");
            return nullptr;
        }
        return v;
    }
    // An enum stored as its number, checked against the last valid one.
    int en(const Json& o, const std::string& base, const char* key, int last) {
        const int v = i(o, base, key);
        if (ok() && (v < 0 || v > last)) fail(base + "/" + key, "is not a known value (0.." + std::to_string(last) + ").");
        return v;
    }
};

Json settings_json(const BakeSettings& s) {
    return Json::object({{"samples", s.samples},
                         {"bounces", s.bounces},
                         {"shadowSamples", s.shadowSamples},
                         {"seed", s.seed},
                         {"dilatePasses", s.dilatePasses},
                         {"denoiseRadius", s.denoiseRadius},
                         {"denoiseSigma", s.denoiseSigma},
                         {"rayEpsilon", s.rayEpsilon},
                         {"shIncludeDirect", s.shIncludeDirect},
                         {"probeBackfaceTolerance", s.probeBackfaceTolerance},
                         {"maxAtlasSize", s.maxAtlasSize},
                         {"maxMemoryBytes", s.maxMemoryBytes},
                         {"maxRays", s.maxRays}});
}

BakeSettings settings_from(Reader& r, const Json& o, const std::string& base) {
    BakeSettings s;
    s.samples = r.i(o, base, "samples");
    s.bounces = r.i(o, base, "bounces");
    s.shadowSamples = r.i(o, base, "shadowSamples");
    s.seed = std::uint32_t(r.u64(o, base, "seed"));
    s.dilatePasses = r.i(o, base, "dilatePasses");
    s.denoiseRadius = r.i(o, base, "denoiseRadius");
    s.denoiseSigma = r.f(o, base, "denoiseSigma");
    s.rayEpsilon = r.f(o, base, "rayEpsilon");
    s.shIncludeDirect = r.b(o, base, "shIncludeDirect");
    s.probeBackfaceTolerance = r.f(o, base, "probeBackfaceTolerance");
    s.maxAtlasSize = r.i(o, base, "maxAtlasSize");
    s.maxMemoryBytes = r.u64(o, base, "maxMemoryBytes");
    s.maxRays = r.u64(o, base, "maxRays");
    return s;
}

Json light_json(const BakeLight& l) {
    return Json::object({{"kind", int(l.kind)},
                         {"mode", int(l.mode)},
                         {"color", vec3_json(l.color)},
                         {"intensity", l.intensity},
                         {"position", vec3_json(l.position)},
                         {"direction", vec3_json(l.direction)},
                         {"range", l.range},
                         {"falloff", int(l.falloff)},
                         {"spotAngleDeg", l.spotAngleDeg},
                         {"spotInnerDeg", l.spotInnerDeg},
                         {"softRadius", l.softRadius},
                         {"softAngleDeg", l.softAngleDeg},
                         {"width", l.width},
                         {"height", l.height},
                         {"up", vec3_json(l.up)}});
}

BakeLight light_from(Reader& r, const Json& o, const std::string& base) {
    BakeLight l;
    l.kind = BakeLightKind(r.en(o, base, "kind", int(BakeLightKind::Area)));
    l.mode = BakeLightMode(r.en(o, base, "mode", int(BakeLightMode::Realtime)));
    l.color = r.v3(o, base, "color");
    l.intensity = r.f(o, base, "intensity");
    l.position = r.v3(o, base, "position");
    l.direction = r.v3(o, base, "direction");
    l.range = r.f(o, base, "range");
    l.falloff = BakeFalloff(r.en(o, base, "falloff", int(BakeFalloff::InverseSquare)));
    l.spotAngleDeg = r.f(o, base, "spotAngleDeg");
    l.spotInnerDeg = r.f(o, base, "spotInnerDeg");
    l.softRadius = r.f(o, base, "softRadius");
    l.softAngleDeg = r.f(o, base, "softAngleDeg");
    l.width = r.f(o, base, "width");
    l.height = r.f(o, base, "height");
    l.up = r.v3(o, base, "up");
    return l;
}

}  // namespace

Json plan_to_json(const Plan& plan) {
    const Options& o = plan.options;
    Json meshes = Json::array();
    for (const PlanMesh& m : plan.meshes) {
        Json world = Json::array();
        for (float v : m.world.m) world.push_back(v);
        meshes.push_back(Json::object({{"id", m.id},
                                       {"mesh", m.mesh},
                                       {"world", world},
                                       {"albedo", vec3_json(m.albedo)},
                                       {"emissive", vec3_json(m.emissive)},
                                       {"castsShadow", m.castsShadow},
                                       {"receiver", m.receiver},
                                       {"texelsPerMeter", m.texelsPerMeter}}));
    }
    Json lights = Json::array();
    for (const BakeLight& l : plan.lights) lights.push_back(light_json(l));
    Json groups = Json::array();
    for (const ProbeGroup& g : plan.probes.groups)
        groups.push_back(Json::object({{"id", g.id},
                                       {"kind", int(g.kind)},
                                       {"first", g.first},
                                       {"count", g.count},
                                       {"nx", g.nx},
                                       {"ny", g.ny},
                                       {"nz", g.nz},
                                       {"spacing", g.spacing},
                                       {"origin", vec3_json(g.origin)}}));
    Json positions = Json::array();
    for (const Vec3& p : plan.probes.positions) positions.push_back(vec3_json(p));
    Json warnings = Json::array();
    for (const std::string& w : plan.warnings) warnings.push_back(w);
    return Json::object(
        {{"options", Json::object({{"texelsPerMeter", o.texelsPerMeter},
                                   {"maxPageSize", o.maxPageSize},
                                   {"sky", int(o.sky)},
                                   {"device", int(o.device)},
                                   {"settings", settings_json(o.settings)}})},
         {"scene", plan.scene},
         {"manifestAbs", plan.manifestAbs},
         {"manifestProject", plan.manifestProject},
         {"meshes", meshes},
         {"lights", lights},
         {"probes", Json::object({{"groups", groups}, {"positions", positions}})},
         {"sky", Json::object({{"zenith", vec3_json(plan.sky.zenith)},
                               {"horizon", vec3_json(plan.sky.horizon)},
                               {"ground", vec3_json(plan.sky.ground)},
                               {"intensity", plan.sky.intensity}})},
         {"environmentMap", plan.environmentMap},
         {"environmentScale", plan.environmentScale},
         {"environmentRotation", plan.environmentRotation},
         {"settingsHash", plan.settingsHash},
         {"warnings", warnings}});
}

Result<Plan> plan_from_json(const Json& j) {
    Reader r;
    Plan plan;
    if (!j.is_object()) return make_error("the bake plan must be a JSON object", "Pass what plan_to_json wrote.");
    if (const Json* o = r.member(j, "", "options"); o) {
        Options& op = plan.options;
        op.texelsPerMeter = r.number(*o, "/options", "texelsPerMeter");
        op.maxPageSize = r.i(*o, "/options", "maxPageSize");
        op.sky = SkyChoice(r.en(*o, "/options", "sky", int(SkyChoice::None)));
        op.device = DeviceChoice(r.en(*o, "/options", "device", int(DeviceChoice::Auto)));
        if (const Json* s = r.member(*o, "/options", "settings"); s) op.settings = settings_from(r, *s, "/options/settings");
    }
    plan.scene = r.s(j, "", "scene");
    plan.manifestAbs = r.s(j, "", "manifestAbs");
    plan.manifestProject = r.s(j, "", "manifestProject");
    if (const Json* ms = r.array(j, "", "meshes"); ms)
        for (std::size_t k = 0; k < ms->size() && r.ok(); ++k) {
            const Json& m = (*ms)[k];
            const std::string base = "/meshes/" + std::to_string(k);
            PlanMesh pm;
            pm.id = r.s(m, base, "id");
            pm.mesh = r.s(m, base, "mesh");
            if (const Json* w = r.array(m, base, "world"); w) {
                if (w->size() != 16) r.fail(base + "/world", "must be 16 numbers.");
                for (std::size_t c = 0; c < 16 && r.ok(); ++c) {
                    if (!(*w)[c].is_number()) r.fail(base + "/world/" + std::to_string(c), "must be a number.");
                    else pm.world.m[c] = (*w)[c].get<float>();
                }
            }
            pm.albedo = r.v3(m, base, "albedo");
            pm.emissive = r.v3(m, base, "emissive");
            pm.castsShadow = r.b(m, base, "castsShadow");
            pm.receiver = r.b(m, base, "receiver");
            pm.texelsPerMeter = r.number(m, base, "texelsPerMeter");
            plan.meshes.push_back(std::move(pm));
        }
    if (const Json* ls = r.array(j, "", "lights"); ls)
        for (std::size_t k = 0; k < ls->size() && r.ok(); ++k)
            plan.lights.push_back(light_from(r, (*ls)[k], "/lights/" + std::to_string(k)));
    if (const Json* p = r.member(j, "", "probes"); p) {
        if (const Json* gs = r.array(*p, "/probes", "groups"); gs)
            for (std::size_t k = 0; k < gs->size() && r.ok(); ++k) {
                const Json& g = (*gs)[k];
                const std::string base = "/probes/groups/" + std::to_string(k);
                ProbeGroup pg;
                pg.id = r.s(g, base, "id");
                pg.kind = ProbeGroupKind(r.en(g, base, "kind", int(ProbeGroupKind::Points)));
                pg.first = r.i(g, base, "first");
                pg.count = r.i(g, base, "count");
                pg.nx = r.i(g, base, "nx");
                pg.ny = r.i(g, base, "ny");
                pg.nz = r.i(g, base, "nz");
                pg.spacing = r.f(g, base, "spacing");
                pg.origin = r.v3(g, base, "origin");
                plan.probes.groups.push_back(std::move(pg));
            }
        if (const Json* ps = r.array(*p, "/probes", "positions"); ps)
            for (std::size_t k = 0; k < ps->size() && r.ok(); ++k) {
                const Json& v = (*ps)[k];
                if (!v.is_array() || v.size() != 3 || !v[0].is_number() || !v[1].is_number() || !v[2].is_number())
                    r.fail("/probes/positions/" + std::to_string(k), "must be three numbers.");
                else
                    plan.probes.positions.push_back({v[0].get<float>(), v[1].get<float>(), v[2].get<float>()});
            }
        plan.probes.build_bounds();
    }
    if (const Json* s = r.member(j, "", "sky"); s) {
        plan.sky.zenith = r.v3(*s, "/sky", "zenith");
        plan.sky.horizon = r.v3(*s, "/sky", "horizon");
        plan.sky.ground = r.v3(*s, "/sky", "ground");
        plan.sky.intensity = r.f(*s, "/sky", "intensity");
    }
    plan.environmentMap = r.s(j, "", "environmentMap");
    plan.environmentScale = r.f(j, "", "environmentScale");
    plan.environmentRotation = r.f(j, "", "environmentRotation");
    plan.settingsHash = r.s(j, "", "settingsHash");
    if (const Json* ws = r.array(j, "", "warnings"); ws)
        for (std::size_t k = 0; k < ws->size() && r.ok(); ++k) {
            if (!(*ws)[k].is_string())
                r.fail("/warnings/" + std::to_string(k), "must be a string.");
            else
                plan.warnings.push_back((*ws)[k].get<std::string>());
        }
    if (!r.ok()) return make_error("the bake plan is not valid: " + r.error, "Pass what plan_to_json wrote.");
    return plan;
}

}  // namespace fa::lightmap_job
