// The lightmap bake commands (M73.4c): lightmap.bake (synchronous: the CLI, tests, scripts that can wait), lightmap.bake_start / bake_status /
// bake_cancel (a job: the editor, MCP). What they compute is in lightmap_bake_job.h; this file is the arguments, the jobs and the hand-over of
// a finished bake to the scene (SceneSettings.lightmaps, the renderer's reload). docs/design/ARCHITECTURE_BAKING.md, "The lightmap.bake commands".
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <map>
#include <memory>
#include <mutex>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/jobs.h"
#include "fa/core/strings.h"
#include "fa/render/renderer.h"
#include "fa/scene/lightmap_manifest.h"
#include "lightmap_bake_job.h"

namespace fa {

namespace {

using Clock =
    std::chrono::steady_clock;  // only for the elapsed time and the estimate shown to the user, never for the result

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) {
    throw CommandError("invalid_argument", pointer + ": " + what, hint);
}

std::string num_text(double v) {
    char buf[64];
    std::snprintf(buf, sizeof buf, "%.6g", v);
    return buf;
}

// A number argument inside [lo, hi] (an integer when `integer`), checked before it is narrowed.
double number(const Json& a, const char* key, double lo, double hi, double fallback, bool integer, const char* hint) {
    if (!a.contains(key) || a[key].is_null()) return fallback;
    const std::string pointer = std::string("/") + key;
    if (!a[key].is_number()) bad(pointer, "must be a number.", hint);
    const double v = a[key].get<double>();
    if (!std::isfinite(v) || v < lo || v > hi)
        bad(pointer, "is " + num_text(v) + ", outside " + num_text(lo) + ".." + num_text(hi) + ".", hint);
    if (integer && v != std::floor(v)) bad(pointer, "must be a whole number, not " + num_text(v) + ".", hint);
    return v;
}

struct Request {
    lightmap_job::Options options;
    std::string manifestProject, manifestAbs;
    bool apply = true;
};

// The arguments of lightmap.bake and lightmap.bake_start; judged on the thread the registry called us on (the caller's capabilities).
Request read_request(Engine::Impl& I, const Json& a, const char* command) {
    // The editor's Play runs in this world: a bake would read the game as it is now, not the scene as it is saved, and what it set
    // would be thrown away at Stop. The Lightmap panel refuses the same way.
    if (I.playWorld)
        throw CommandError("game_running", std::string(command) + ": the game is running in the editor.",
                           "Stop the game (Play > Stop, F5), then bake: a bake reads the scene as it is saved.");
    Request r;
    lightmap_job::Options& o = r.options;
    BakeSettings& s = o.settings;
    o.texelsPerMeter =
        number(a, "texelsPerMeter", 0.01, 4096, 16, false,
               "Texels per meter of surface: 16 is a good start, 64 for sharp shadows (more pages and a longer bake).");
    o.maxPageSize = int(number(a, "maxPageSize", 16, kLightmapMaxPageSize, 2048, true,
                               "The longest side of a page: 1024, 2048 or 4096 are usual."));
    s.samples =
        int(number(a, "samples", 1, 65536, s.samples, true, "Gather rays per texel: 64 is smooth, 16 is a draft."));
    s.bounces = int(number(a, "bounces", 0, 16, s.bounces, true, "0 = direct light only, 2 is the default."));
    s.shadowSamples = int(number(a, "shadowSamples", 1, 1024, s.shadowSamples, true,
                                 "Shadow rays per light per texel: more = softer, smoother shadows."));
    s.seed =
        std::uint32_t(number(a, "seed", 0, 4294967295.0, 0, true, "Another seed is another, equally good, noise."));
    s.dilatePasses = int(number(a, "dilatePasses", 0, 64, s.dilatePasses, true,
                                "Texels of gutter around each mesh: 4 hides the seams of bilinear filtering."));
    s.denoiseRadius = int(number(a, "denoiseRadius", 0, 8, s.denoiseRadius, true, "0 turns the denoiser off."));
    s.denoiseSigma = float(number(a, "denoiseSigma", 0.01, 10, s.denoiseSigma, false,
                                  "How different two neighbours may be and still be blended."));
    s.rayEpsilon =
        float(number(a, "rayEpsilon", 0, 100, 0, false, "Meters; 0 picks it from the scene and the texel size."));
    s.maxRays = std::uint64_t(number(a, "maxRays", 1, 1e15, double(s.maxRays), true,
                                     "A bake over this many rays is refused. One core traces about 2-10 million rays "
                                     "per second, so 1e9 rays are minutes."));
    if (a.contains("device") && !a["device"].is_null()) {
        const std::string v = a["device"].is_string() ? a["device"].get<std::string>() : std::string();
        if (v == "cpu")
            o.device = lightmap_job::DeviceChoice::Cpu;
        else if (v == "gpu")
            o.device = lightmap_job::DeviceChoice::Gpu;
        else if (v == "auto")
            o.device = lightmap_job::DeviceChoice::Auto;
        else
            bad("/device",
                "\"" + v + "\" is not a device. " + did_you_mean(v, std::vector<std::string>{"cpu", "gpu", "auto"}),
                "One of cpu (the default: exact, the same bytes every time), gpu (a fast preview on a graphics card "
                "that traces rays), "
                "auto (a GPU when there is one, else the CPU).");
    }
    if (a.contains("apply") && !a["apply"].is_null()) {
        if (!a["apply"].is_boolean())
            bad("/apply", "must be true or false.",
                "true (default) sets SceneSettings.lightmaps to the manifest when it is done.");
        r.apply = a["apply"].get<bool>();
    }
    if (a.contains("sky") && !a["sky"].is_null()) {
        const std::string v = a["sky"].is_string() ? a["sky"].get<std::string>() : std::string();
        static const std::vector<std::pair<std::string, lightmap_job::SkyChoice>> names = {
            {"auto", lightmap_job::SkyChoice::Auto},
            {"environment", lightmap_job::SkyChoice::Environment},
            {"gradient", lightmap_job::SkyChoice::Gradient},
            {"ambient", lightmap_job::SkyChoice::Ambient},
            {"none", lightmap_job::SkyChoice::None}};
        bool found = false;
        for (const auto& [n, c] : names)
            if (n == v) {
                o.sky = c;
                found = true;
            }
        if (!found) {
            std::vector<std::string> list;
            for (const auto& [n, c] : names) list.push_back(n);
            bad("/sky", "\"" + v + "\" is not a sky source. " + did_you_mean(v, list),
                "One of auto (the environment map when the scene has one, else its ambient light), environment, "
                "gradient, ambient, none.");
        }
    }
    // The manifest path: the caller's, else next to the open scene.
    std::string raw = a.contains("path") && a["path"].is_string() ? a["path"].get<std::string>() : std::string();
    if (raw.empty()) {
        if (I.currentScene.empty())
            bad("/path", "is missing and no scene is open to name the manifest after.",
                "Pass the manifest to write, e.g. \"scenes/main.lightmap.json\", or open a scene first.");
        std::string stem = I.currentScene;
        const std::string tail = ".scene.json";
        if (ends_with(to_lower(stem), tail))
            stem.resize(stem.size() - tail.size());
        else if (ends_with(to_lower(stem), ".json"))
            stem.resize(stem.size() - 5);
        raw = stem + ".lightmap.json";
    }
    if (!ends_with(to_lower(raw), ".lightmap.json"))
        bad("/path", "'" + raw + "' does not end in .lightmap.json.",
            "Name the manifest like scenes/main.lightmap.json: the pages are written next to it.");
    r.manifestAbs = resolve_caller_write_path(raw, command);
    r.manifestProject = resolve_caller_project_path(raw, command);
    if (fs::is_absolute(r.manifestProject))
        bad("/path", "'" + raw + "' is outside the project.",
            "The manifest and its pages must be inside the project, so the game can load them.");
    return r;
}

// ---- the jobs -------------------------------------------------------------------------------------------------------------------------------

struct Job {
    std::string id, manifestProject, manifestAbs, scene;
    bool apply = true;
    std::atomic<bool> cancel{false};
    std::mutex mu;                  // guards everything below
    std::string state = "running";  // running, done, failed, cancelled
    std::string phase = "queued";
    double progress = 0;
    std::uint64_t rays = 0;
    Json result;
    std::string error, hint;
    bool handedOver = false;  // the finished bake was given to the scene (once)
    Json handover;
    Clock::time_point started = Clock::now(), finished = Clock::now();
    jobs::Handle handle;
};

struct Registry {
    std::mutex mu;
    std::map<std::string, std::shared_ptr<Job>> byId;
    int next = 1;
};

constexpr std::size_t kKeepFinished = 8;
// A finished bake that has an `apply` still to hand over is kept beyond kKeepFinished (dropping it would lose the SceneSettings.lightmaps
// the caller asked for), up to this many: a caller that never polls cannot make the registry grow without end.
constexpr std::size_t kKeepUnhandedApply = 64;

// Forgets the oldest finished jobs beyond kKeepFinished (done, failed or cancelled, whether or not anybody asked for their status: a job
// nobody polls must not stay for ever). A done job with `apply` that was not handed over yet is not counted among them: it stays until
// somebody asks (at most kKeepUnhandedApply of them, the oldest go first). The caller holds Registry::mu and no Job::mu.
void prune_finished(Registry& reg) {
    std::vector<std::pair<Clock::time_point, std::string>> finished, pending;
    for (const auto& [id, job] : reg.byId) {
        std::lock_guard jl(job->mu);
        if (job->state == "running") continue;
        const bool owesApply = job->state == "done" && job->apply && !job->handedOver;
        (owesApply ? pending : finished).emplace_back(job->finished, id);
    }
    std::sort(finished.begin(), finished.end());
    for (std::size_t i = 0; i + kKeepFinished < finished.size(); ++i) reg.byId.erase(finished[i].second);
    std::sort(pending.begin(), pending.end());
    for (std::size_t i = 0; i + kKeepUnhandedApply < pending.size(); ++i) reg.byId.erase(pending[i].second);
}

// Two spellings of one manifest: the filesystems of Windows and macOS do not tell "Scenes/A.lightmap.json" from "scenes/a.lightmap.json".
bool same_manifest(const std::string& a, const std::string& b) {
#if defined(_WIN32) || defined(__APPLE__)
    return to_lower(a) == to_lower(b);
#else
    return a == b;
#endif
}

// Lock order everywhere: Registry::mu first, then Job::mu. Throws `busy` when a running job writes `manifestProject`.
void refuse_if_busy(Registry& reg, const std::string& manifestProject) {
    std::lock_guard lock(reg.mu);
    for (const auto& [id, other] : reg.byId) {
        std::lock_guard jl(other->mu);
        if (other->state == "running" && same_manifest(other->manifestProject, manifestProject))
            throw CommandError("busy", "a bake of '" + manifestProject + "' is already running (" + id + ").",
                               "Wait for it (lightmap.bake_status {\"job\":\"" + id +
                                   "\"}), cancel it (lightmap.bake_cancel), or bake to another `path`.");
    }
}

double round_to(double v, double scale) { return std::round(v * scale) / scale; }

// Gives a finished bake to the scene: SceneSettings.lightmaps (when `apply`) and the renderer's reload. Only for the scene the bake was made for.
Json hand_over(Engine::Impl& I, const std::string& scene, const std::string& manifestProject, bool apply) {
    Json out = Json::object();
    if (I.currentScene != scene) {
        out["applied"] = false;
        out["note"] = "the open scene is no longer '" + scene +
                      "', so SceneSettings.lightmaps was not changed; the files are written. Open that scene and set "
                      "SceneSettings.lightmaps to '" +
                      manifestProject + "'.";
        return out;
    }
    if (I.playWorld) {  // a bake started before the game: the world now is the Play copy, which Stop throws away
        out["applied"] = false;
        out["note"] = "the game is running in the editor, so SceneSettings.lightmaps was not changed (Stop would throw "
                      "it away); the files are written. Stop the game and set SceneSettings.lightmaps to '" +
                      manifestProject + "'.";
        return out;
    }
    bool changed = false;
    if (apply && I.world.settings().lightmaps != manifestProject) {
        I.world.settings().lightmaps = manifestProject;
        changed = true;
    }
    if (I.renderer)
        I.renderer->reload_asset(manifestProject);  // a rebake under the same name: the renderer reads the new pages
    out["applied"] = apply;
    out["settingsChanged"] = changed;
    if (!apply)
        out["note"] = "apply was false: set SceneSettings.lightmaps to '" + manifestProject + "' to see the bake.";
    return out;
}

Json status_json(const Job& j, std::string_view stateOverride = {}) {
    Json out = Json::object();
    out["job"] = j.id;
    out["state"] = stateOverride.empty() ? j.state : std::string(stateOverride);
    out["phase"] = j.phase;
    out["progress"] = round_to(j.progress, 1000);
    out["rays"] = j.rays;
    out["manifest"] = j.manifestProject;
    const double elapsed =
        std::chrono::duration<double>((j.state == "running" ? Clock::now() : j.finished) - j.started).count();
    out["elapsedSeconds"] = round_to(elapsed, 10);
    if (j.state == "running" && j.progress > 0.02 && elapsed > 1.0)
        out["etaSeconds"] = std::max(0.0, round_to(elapsed * (1.0 - j.progress) / j.progress, 1));
    if (j.state == "done") out["result"] = j.result;
    if (j.state == "failed" || j.state == "cancelled") {
        out["error"] = j.error;
        if (!j.hint.empty()) out["hint"] = j.hint;
    }
    return out;
}

std::string live_ids(Registry& reg) {
    std::string s;
    for (const auto& [id, job] : reg.byId) s += (s.empty() ? "" : ", ") + id;
    return s.empty() ? "no bake job exists (lightmap.bake_start makes one)" : "known jobs: " + s;
}

std::shared_ptr<Job> need_job(Registry& reg, const Json& a) {
    if (!a.contains("job") || !a["job"].is_string() || a["job"].get<std::string>().empty())
        throw CommandError("invalid_argument", "/job: missing.",
                           "Pass the id lightmap.bake_start returned, e.g. {\"job\":\"bake:1\"}.");
    const std::string id = a["job"].get<std::string>();
    std::lock_guard lock(reg.mu);
    auto it = reg.byId.find(id);
    if (it == reg.byId.end())
        throw CommandError("unknown_job",
                           "/job: no bake job '" + id + "'. " +
                               did_you_mean(id,
                                            [&] {
                                                std::vector<std::string> v;
                                                for (const auto& [k, j] : reg.byId) v.push_back(k);
                                                return v;
                                            }()),
                           live_ids(reg) + ". Only the last " + std::to_string(kKeepFinished) +
                               " finished jobs are kept.");
    return it->second;
}

// Registers a job for `plan` and starts it on a job thread. `inHelper`: this process is the helper of another one (lightmap.bake_plan_start), so
// the bake must trace here and never start a helper of its own. Returns the job's status.
Json start_job(Registry& reg, lightmap_job::Plan plan, bool apply, bool inHelper) {
    auto job = std::make_shared<Job>();
    {
        std::lock_guard lock(reg.mu);  // the busy check and the registration are one step: two starts cannot both pass
        for (const auto& [id, other] : reg.byId) {
            std::lock_guard jl(other->mu);
            if (other->state == "running" && same_manifest(other->manifestProject, plan.manifestProject))
                throw CommandError("busy", "a bake of '" + plan.manifestProject + "' is already running (" + id + ").",
                                   "Wait for it (lightmap.bake_status {\"job\":\"" + id +
                                       "\"}), cancel it (lightmap.bake_cancel), or bake to another `path`.");
        }
        prune_finished(reg);  // jobs nobody asked about must not pile up
        job->id = "bake:" + std::to_string(reg.next++);
        job->manifestProject =
            plan.manifestProject;  // set before the job is visible: a second start sees the path at once
        reg.byId[job->id] = job;
    }
    job->manifestAbs = plan.manifestAbs;
    job->scene = plan.scene;
    job->apply = apply;
    job->started = Clock::now();
    auto shared = std::make_shared<lightmap_job::Plan>(std::move(plan));
    job->handle = jobs::submit("lightmap.bake", [job, shared, inHelper] {
        const CommandCancelScope scope(&job->cancel);
        Result<Json> r = make_error("the bake did not run", "");
        try {
            auto report = [&](const std::string& phase, double progress, std::uint64_t rays) {
                std::lock_guard lock(job->mu);
                job->phase = phase;
                job->progress = std::clamp(progress, 0.0, 1.0);
                job->rays = rays;
            };
            r = inHelper ? lightmap_job::execute_here(*shared, report) : lightmap_job::execute(*shared, report);
        } catch (const std::exception& e) {
            r = make_error(std::string("the bake stopped by an exception: ") + e.what(),
                           "Report this with the scene; nothing was changed.");
        }
        std::lock_guard lock(job->mu);
        job->finished = Clock::now();
        if (r.ok()) {
            job->state = "done";
            job->progress = 1.0;
            job->phase = "done";
            job->result = std::move(*r);
        } else if (r.error().message == "cancelled") {
            job->state = "cancelled";
            job->phase = "cancelled";
            job->error = "the bake was cancelled; no file was changed.";
        } else {
            job->state = "failed";
            job->phase = "failed";
            job->error = r.error().message;
            job->hint = r.error().hint;
        }
    });
    std::lock_guard lock(job->mu);
    return status_json(*job);
}

const char* kRequestProps = R"(
    "path":{"type":"string","x-fa-path":"write","description":"The manifest to write, inside the project, ending in .lightmap.json (the pages .hdr go next to it). Default: next to the open scene, scenes/main.scene.json -> scenes/main.lightmap.json."},
    "texelsPerMeter":{"type":"number","minimum":0.01,"maximum":4096,"default":16,"description":"Lightmap texels per meter of surface at MeshRenderer.lightmapScale 1. 16 is a good start; 64 gives sharp shadows with 16 times the texels."},
    "maxPageSize":{"type":"integer","minimum":16,"maximum":8192,"default":2048,"description":"The longest side of a page in texels. More meshes than fit make more pages (at most 256)."},
    "samples":{"type":"integer","minimum":1,"maximum":65536,"default":64,"description":"Gather rays per texel for the sky, emissive surfaces and bounces. 16 is a draft, 64 smooth."},
    "bounces":{"type":"integer","minimum":0,"maximum":16,"default":2,"description":"Times light is reflected before it reaches a texel. 0 = direct light and sky only."},
    "shadowSamples":{"type":"integer","minimum":1,"maximum":1024,"default":4,"description":"Shadow rays per light per texel; soft shadows (Pcss lights, area lights) need more."},
    "seed":{"type":"integer","minimum":0,"maximum":4294967295,"default":0,"description":"The noise pattern. The same seed and scene give the same bytes on any number of threads."},
    "dilatePasses":{"type":"integer","minimum":0,"maximum":64,"default":4,"description":"Texels of gutter filled around each mesh so bilinear filtering does not bleed black."},
    "denoiseRadius":{"type":"integer","minimum":0,"maximum":8,"default":2,"description":"Edge-aware blur radius in texels; 0 turns the denoiser off."},
    "denoiseSigma":{"type":"number","minimum":0.01,"maximum":10,"default":0.3,"description":"How different two neighbouring texels may be (relative to their light) and still be blended."},
    "rayEpsilon":{"type":"number","minimum":0,"maximum":100,"default":0,"description":"Meters a ray starts off its surface. 0 = automatic: the scene size / 10000, at most 1 cm and, for the lightmap, at most 1/20 of a texel."},
    "maxRays":{"type":"number","minimum":1,"default":50000000000,"description":"The bake is refused when it could trace more rays than this. One core traces roughly 2-10 million rays per second, so 1e9 rays are minutes and the default 5e10 are hours: lower it to give a bake a time limit."},
    "sky":{"type":"string","enum":["auto","environment","gradient","ambient","none"],"default":"auto","description":"The light from outside: auto = SceneSettings.environmentMap when set, else its ambientLight; environment = the HDRI; gradient = skyColor and horizonColor; ambient = the constant ambientLight; none = black. A physical sky or sky material cannot be evaluated: it falls back as said in the result's warnings."},
    "device":{"type":"string","enum":["cpu","gpu","auto"],"default":"cpu","description":"What traces the texels. cpu (default) = the CPU baker: exact, the same bytes on every machine and thread count; use it for a final bake. gpu = a fast PREVIEW on the graphics card (ray queries: Metal on Apple silicon, D3D12 or Vulkan elsewhere): the image matches the CPU's within a small tolerance (the GPU's own rounding), repeats on one GPU and driver, and can differ in the last bits on another; the bake fails with the reason when no GPU here traces rays. auto = gpu when this machine has a GPU that can (a software rasteriser such as WARP or lavapipe does not count; gpu accepts it), else cpu with the reason in the result's device.note. A mid-bake GPU failure with auto bakes again on the CPU, with the reason in device.note. The light probes always bake on the CPU (a scene with probes and no lightmap texels says so in device.note). samples (1..65536), bounces (0..16) and shadowSamples (1..1024) are the CPU's ranges on the GPU too: outside them the bake is refused, never clamped. Where this process already has a graphics context on a Mac (the editor, a window, factoria call without --no-graphics) the texels are traced by a child `factoria session --no-graphics` (device.process is \"helper\"; progress and cancel work the same, a crash of the child never reaches this process: gpu fails with the reason, auto bakes on the CPU); otherwise device.process is \"here\". The result's `device` says which one baked, `process` where."},
    "apply":{"type":"boolean","default":true,"description":"Set SceneSettings.lightmaps to the manifest when the bake is done (the renderer reloads the pages either way)."})";

Json request_schema(bool withJob) {
    std::string text = R"({"type":"object","properties":{)";
    if (withJob)
        text += R"("job":{"type":"string","description":"The id lightmap.bake_start returned (\"bake:1\")."},)";
    text += kRequestProps;
    text += "}}";
    return parse_schema(text.c_str());
}

}  // namespace

void register_lightmap_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    auto reg = std::make_shared<Registry>();

    // A running bake must stop before the engine waits for its jobs at shutdown.
    I.shutdownHooks.push_back([reg] {
        std::lock_guard lock(reg->mu);
        for (auto& [id, job] : reg->byId) job->cancel.store(true);
    });

    I.commands.add(
        {"lightmap.bake",
         "Bake the scene's baked and mixed lights and its sky into lightmaps, wait for it, and write the pages and the "
         "manifest.",
         "Reads the active MeshRenderers (static geometry that shadows and bounces light; the ones with receiveGI, "
         "lightmapScale > 0 and unlit false "
         "also get lightmap texels), the Lights with mode baked (direct + bounce light baked) or mixed (only the "
         "bounce is baked, the direct light stays "
         "realtime) and the sky, then writes `<name>.lightmap.<hash>.<n>.hdr` pages and `<name>.lightmap.json` "
         "atomically and sets "
         "SceneSettings.lightmaps. A model without a second UV set is unwrapped for you. Blocks until done: a long "
         "bake belongs in lightmap.bake_start. The "
         "same scene and settings give byte-identical pages on any thread count (device \"cpu\", the default; device "
         "\"gpu\" is a fast preview within a small tolerance, see `device`). The LightProbeGroups of the scene are "
         "baked by the same job (phase \"probes\") into `<name>.lightmap.<hash>.probes`, which the manifest lists: "
         "moving objects read them as their ambient light; a probe inside geometry is flagged invalid and counted. "
         "Result: {manifest, pages, entities, "
         "texels, rays, device {requested, used, name, note, process}, skipped, warnings, probes {file, count, "
         "invalid, "
         "groups}, "
         "applied}. Example: lightmap.bake {\"texelsPerMeter\":16,\"samples\":64}",
         request_schema(false), false, "assets",
         "Mapping. Light: Baked -> baked (direct light and bounces; in the probes too), Mixed -> indirect only (the "
         "realtime light stays; only its bounce is baked into the lightmap and the probes), Realtime is left out; "
         "intensity, color, range and "
         "spotAngle carry over; "
         "Pcss shadowSoftness widens the shadow. An area light is a one-sided rectangle of radiance = intensity (a "
         "Disc or Tube becomes a rectangle of "
         "the same area). Sky: see `sky`. A MeshRenderer is its color (albedo) and emissive * emissiveStrength; "
         "textures are not read; a skinned mesh "
         "is baked in its bind pose. A mesh the unwrap cannot handle (a procedural mesh:N, over 250000 triangles) is "
         "listed in `skipped`. The result's "
         "`warnings` name everything that was approximated. Files: pages are written first, the manifest last; on "
         "Windows a file another program "
         "holds open cannot be replaced: close it and bake again, or use another `path`. "
         "docs/rendering/RENDERING_LIGHTMAPS.md, \"Baking\"."},
        [&I, reg](const Json& a) {
            Request req = read_request(I, a, "lightmap.bake");
            refuse_if_busy(*reg, req.manifestProject);
            auto plan =
                lightmap_job::make_plan(I.world, I.currentScene, req.options, req.manifestAbs, req.manifestProject);
            if (!plan.ok()) throw CommandError("invalid_scene", plan.error().message, plan.error().hint);
            report_command_progress("lightmap bake: starting");
            std::string lastPhase;
            int lastPercent = -1;
            auto done = lightmap_job::execute(*plan, [&](const std::string& phase, double progress, std::uint64_t) {
                const int percent = int(progress * 100.0);
                if (phase == lastPhase && percent == lastPercent) return;
                lastPhase = phase;
                lastPercent = percent;
                report_command_progress("lightmap bake: " + phase + " " + std::to_string(percent) + "%");
            });
            if (!done.ok()) {
                const bool wasCancelled = done.error().message == "cancelled" || command_cancelled();
                throw CommandError(wasCancelled ? "cancelled" : "bake_failed", done.error().message, done.error().hint);
            }
            Json out = std::move(*done);
            const Json h = hand_over(I, I.currentScene, req.manifestProject, req.apply);
            for (auto it = h.begin(); it != h.end(); ++it) out[it.key()] = it.value();
            return out;
        });

    I.commands.add(
        {"lightmap.bake_start",
         "Start a lightmap bake in the background and get a job id; poll lightmap.bake_status, stop it with "
         "lightmap.bake_cancel.",
         "The same bake as lightmap.bake (same arguments and result) on a job thread, so the editor and an agent stay "
         "responsive. The scene is read "
         "when you call this: changing the scene while it runs does not change the bake, and a result is only given to "
         "the scene it was made for. "
         "Call lightmap.bake_status until its state is done, failed or cancelled: that call also hands the result to "
         "the scene (SceneSettings.lightmaps "
         "and the renderer's reload). Result: {job, state, phase, progress, manifest}. Example: lightmap.bake_start "
         "{\"path\":\"scenes/main.lightmap.json\"}",
         request_schema(false), false, "assets"},
        [&I, reg](const Json& a) {
            Request req = read_request(I, a, "lightmap.bake_start");
            auto plan =
                lightmap_job::make_plan(I.world, I.currentScene, req.options, req.manifestAbs, req.manifestProject);
            if (!plan.ok()) throw CommandError("invalid_scene", plan.error().message, plan.error().hint);
            return start_job(*reg, std::move(*plan), req.apply, false);
        });

    I.commands.add(
        {"lightmap.bake_plan_start",
         "Internal: start a bake job from a plan another process made (the helper process of a GPU bake).",
         "What the editor, a window or a session with graphics runs in a child `factoria session --no-graphics` when "
         "it "
         "bakes with device gpu or auto on a Mac, where a process that has a graphics context cannot open the "
         "tracer's own (see lightmap.bake_start, `device`). `plan` is what the parent read from its world "
         "(lightmap_job::plan_to_json); the job traces its texels in THIS process, never starts a helper of its "
         "own, writes the files with the same code as lightmap.bake and is followed with lightmap.bake_status "
         "{\"job\":...,\"apply\":false} and stopped with lightmap.bake_cancel. It does not change the scene. Nobody "
         "calls it by hand: an invalid plan is refused with a JSON pointer. Result: lightmap.bake_start's. "
         "Example: lightmap.bake_plan_start {\"plan\":{...}}",
         parse_schema(
             R"({"type":"object","required":["plan"],"properties":{"plan":{"type":"object","description":"The bake plan: options, scene, manifest paths, meshes, lights, probes, sky (what lightmap_job::plan_to_json writes)."}}})"),
         false, "assets"},
        [reg](const Json& a) {
            if (!a.contains("plan") || !a["plan"].is_object())
                bad("/plan", "is missing or not an object.",
                    "This command is for the helper process of a GPU bake; call lightmap.bake_start instead.");
            auto plan = lightmap_job::plan_from_json(a["plan"]);
            if (!plan.ok()) throw CommandError("invalid_argument", plan.error().message, plan.error().hint);
            return start_job(*reg, std::move(*plan), false, true);
        });

    I.commands.add(
        {"lightmap.bake_status",
         "The state of a bake job: running with a phase and progress, or done with its result, failed or cancelled.",
         "Result: {job, state (running|done|failed|cancelled), phase (geometry, layout, prepare, rasterize, trace, "
         "denoise, dilate, probes, writing), progress "
         "0..1, rays, elapsedSeconds, etaSeconds (once there is enough to estimate), manifest} and, when finished, "
         "`result` (the lightmap.bake result: "
         "pages, texels, rays, skipped, warnings) or `error` and `hint`. The first call that sees a bake done hands it "
         "to the scene (SceneSettings.lightmaps "
         "and the renderer's reload) unless the bake was started with apply false, or the scene changed since; "
         "`handOver` says what happened (while the editor's game runs it is not applied: Stop would throw it "
         "away). " FA_COMMAND_DETAILS
         "With no worker thread (runtime.jobThreads 0, or a web build without threads) a job runs when somebody waits "
         "for it or at the end of the frame, so the first bake_status blocks until the bake is done and answers done, "
         "failed or cancelled, never running. With runtime.jobThreads \"inline\" bake_start itself runs the whole "
         "bake. "
         "Only the last 8 finished jobs are kept, whether or not their status was read; a done job that still has its "
         "`apply` to hand over is kept (up to 64) until a status call hands it over. "
         "Example: lightmap.bake_status {\"job\":\"bake:1\"}",
         parse_schema(
             R"({"type":"object","required":["job"],"properties":{"job":{"type":"string","description":"The id lightmap.bake_start returned."},
            "apply":{"type":"boolean","description":"Overrides the apply of lightmap.bake_start for this hand-over. The editor passes false and edits the setting itself (undo, dirty scene)."}}})"),
         false, "assets"},
        [&I, reg](const Json& a) {
            auto job = need_job(*reg, a);
            // With no worker thread the job only runs when somebody waits for it (inline pool, 0 workers).
            if (!job->handle.done() && jobs::worker_count() == 0) (void)jobs::wait(job->handle);
            std::lock_guard registryLock(reg->mu);  // Registry::mu, then Job::mu: the one lock order
            Json out;
            {
                std::lock_guard lock(job->mu);
                out = status_json(*job);
                if (job->state == "done") {
                    if (!job->handedOver) {
                        const bool apply =
                            a.contains("apply") && a["apply"].is_boolean() ? a["apply"].get<bool>() : job->apply;
                        job->handover = hand_over(I, job->scene, job->manifestProject, apply);
                        job->handedOver = true;
                    }
                    out["handOver"] = job->handover;
                } else if (job->state != "running") {
                    job->handedOver = true;
                }
            }
            prune_finished(*reg);  // the oldest finished jobs beyond kKeepFinished are forgotten
            return out;
        });

    I.commands.add(
        {"lightmap.bake_cancel", "Stop a running bake job; no file is changed unless it was already writing them.",
         "Sets the job's cancel flag: every phase (the BVH build, the texel mapping, the rays, the denoiser, the "
         "gutter fill) looks at it within a short "
         "time, and the job ends with state cancelled. A job that reached the writing phase finishes (a half-written "
         "set would be worse) and ends done. "
         "Cancelling a finished or already cancelled job is not an error. Result: lightmap.bake_status's shape. "
         "Example: lightmap.bake_cancel {\"job\":\"bake:1\"}",
         parse_schema(
             R"({"type":"object","required":["job"],"properties":{"job":{"type":"string","description":"The id lightmap.bake_start returned."}}})"),
         false, "assets"},
        [reg](const Json& a) {
            auto job = need_job(*reg, a);
            std::lock_guard lock(job->mu);
            Json out;
            if (job->state == "running") {
                job->cancel.store(true);
                out = status_json(*job);
                out["note"] = "cancel requested: the job stops at its next check; poll lightmap.bake_status until the "
                              "state is cancelled.";
            } else {
                out = status_json(*job);
                out["note"] = "the job already ended (" + job->state + "): nothing to cancel.";
            }
            return out;
        });

    declare_command_capabilities(I.commands, {{"lightmap.bake", capability_sets::edits_project()},
                                              {"lightmap.bake_start", capability_sets::edits_project()},
                                              {"lightmap.bake_plan_start", capability_sets::edits_project()},
                                              {"lightmap.bake_status", capability_sets::edits_project()},
                                              {"lightmap.bake_cancel", capability_sets::changes_state()}});
}

}  // namespace fa
