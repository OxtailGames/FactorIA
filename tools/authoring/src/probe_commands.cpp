// probe.bake (M73-P3b): captures a ReflectionProbe once, filters it like the renderer's realtime capture, and writes the result into the
// project as a page (<name>.probe.<hash>.hdr: the octahedral tile without its SH row, RGBE) and a manifest (<name>.probe.json: the resolution,
// the nine SH coefficients, the page and its hash). docs/design/ARCHITECTURE_PROBES.md, "Baked probes".
//
// The page is written first and the manifest last (fs::write_bytes replaces atomically), so a reader (the renderer's hot reload, an editor)
// sees the old pair or the new one, never a manifest whose page is missing. The page's name has its hash in it: a changed bake is a new
// file, so a page a running game holds open is never replaced; the old page is removed once the manifest names the new one (a page that is
// still open elsewhere stays, and the next bake takes it).
#include <algorithm>
#include <cctype>
#include <string>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/core/image_float.h"
#include "fa/core/strings.h"
#include "fa/render/probe.h"
#include "fa/render/renderer.h"

namespace fa {

namespace {

using namespace fa::render;

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void check_args_known(const Json& a, std::initializer_list<const char*> known, const char* command) {
    if (!a.is_object()) return;
    std::vector<std::string> names;
    for (const char* k : known) names.push_back(k);
    for (auto it = a.begin(); it != a.end(); ++it)
        if (std::find(names.begin(), names.end(), it.key()) == names.end())
            throw CommandError("invalid_argument",
                               std::string(command) + ": unknown argument '" + it.key() + "'. " +
                                   did_you_mean(it.key(), names),
                               "The arguments are: " + join(names, ", ") + ".");
}

constexpr const char* kSuffix = ".probe.json";

std::string dir_of(const std::string& path) {
    const std::size_t slash = path.find_last_of('/');
    return slash == std::string::npos ? std::string() : path.substr(0, slash + 1);
}

std::string file_of(const std::string& path) {
    const std::size_t slash = path.find_last_of('/');
    return slash == std::string::npos ? path : path.substr(slash + 1);
}

// The entity's id with only the characters of a file name.
std::string safe_name(const std::string& id) {
    std::string out;
    for (char c : id) out.push_back(std::isalnum(static_cast<unsigned char>(c)) || c == '-' || c == '_' ? c : '_');
    return out.empty() ? std::string("probe") : out;
}

// The manifest a probe.bake without `path` writes: next to the open scene, named after the scene and the entity.
std::string default_manifest(Engine::Impl& I, const std::string& entityId) {
    if (I.currentScene.empty())
        throw CommandError(
            "invalid_argument", "/path: is missing and no scene is open to name the manifest after.",
            "Pass the manifest to write, e.g. \"scenes/probes/room.probe.json\", or open a scene first.");
    std::string stem = I.currentScene;
    const std::string tail = ".scene.json";
    if (ends_with(to_lower(stem), tail))
        stem.resize(stem.size() - tail.size());
    else if (ends_with(to_lower(stem), ".json"))
        stem.resize(stem.size() - 5);
    return stem + "." + safe_name(entityId) + kSuffix;
}

}  // namespace

void register_probe_commands(Engine& engine, Engine::Impl& impl) {
    (void)engine;
    Engine::Impl& I = impl;

    I.commands.add(
        {"probe.bake", "Capture a ReflectionProbe once and write its baked page and manifest into the project.",
         "Draws the scene from the probe's position into a cube map (six 90 degree views of the scene, sky included "
         "unless the probe's `clear` is "
         "color), converts it to the probe's octahedral map, filters the rough levels with the same GGX filter as the "
         "sky's reflections and "
         "projects the diffuse light onto nine spherical-harmonics coefficients. It writes `<name>.probe.<hash>.hdr` "
         "(the page, RGBE) and then "
         "`<name>.probe.json` (the manifest: resolution, coefficients, page, hash) atomically, and sets "
         "ReflectionProbe.bakedMap to the manifest "
         "(`apply`, default true) so a probe in `baked` mode shows it; the renderer reads a changed pair again by "
         "itself (hot reload). The "
         "ReflectionProbe's resolution, nearPlane, farPlane, clear, clearColor, showTags and hideTags decide what is "
         "captured; its intensity is "
         "not baked in (it multiplies what the probe shows at run time). The same scene on the same GPU gives the same "
         "bytes; another GPU may "
         "differ in the last bit of a texel, which is why the page's name holds the hash of its bytes. Needs graphics "
         "with RGBA16F render targets "
         "(`render.supports floatTargets`). Result: {entity, manifest, page, hash, resolution, bytes, applied, note?}. "
         "Example: probe.bake {\"entity\":\"lobby_probe\"}",
         parse_schema(R"({"type":"object","required":["entity"],"properties":{
               "entity":{"type":"string","description":"The entity with the ReflectionProbe component (id or name)."},
               "path":{"type":"string","x-fa-path":"write","description":"The manifest to write, inside the project, ending in .probe.json (the page goes next to it). Default: next to the open scene, scenes/main.scene.json -> scenes/main.<entity id>.probe.json."},
               "apply":{"type":"boolean","default":true,"description":"Set ReflectionProbe.bakedMap to the manifest when it is done (the scene is not saved: scene.save does)."}}})"),
         false, "assets",
         "The captured scene is the 3D scene as a camera at the probe's position would draw it (meshes with their "
         "materials, lights, shadows). "
         "The probe's own entity is not special: hide what must not appear with hideTags. Writes: the page, then the "
         "manifest (a file another program holds open cannot be replaced on "
         "Windows: close it, or use another `path`). docs/design/ARCHITECTURE_PROBES.md, \"Baked probes\"."},
        [&I](const Json& a) {
            check_args_known(a, {"entity", "path", "apply"}, "probe.bake");
            if (a.contains("apply") && !a["apply"].is_null() && !a["apply"].is_boolean())
                throw CommandError(
                    "invalid_argument", "/apply: must be true or false.",
                    "true (default) sets ReflectionProbe.bakedMap to the manifest when the bake is done.");
            const bool apply = !a.contains("apply") || a["apply"].is_null() || a["apply"].get<bool>();
            if (a.contains("path") && !a["path"].is_null() && !a["path"].is_string())
                throw CommandError("invalid_argument", "/path: must be a string.",
                                   "A project path like \"scenes/room.probe.json\".");
            // The caller's path is judged before anything else: a path it may not write fails without a lookup and without drawing.
            std::string raw =
                a.contains("path") && a["path"].is_string() ? a["path"].get<std::string>() : std::string();
            std::string manifestAbs, manifestProject;
            auto judge_path = [&]() {
                if (!ends_with(to_lower(raw), kSuffix))
                    throw CommandError(
                        "invalid_argument", "/path: '" + raw + "' does not end in .probe.json.",
                        "Name the manifest like scenes/room.probe.json: the page is written next to it.");
                manifestAbs = resolve_caller_write_path(raw, "probe.bake");
                manifestProject = resolve_caller_project_path(raw, "probe.bake");
                if (fs::is_absolute(manifestProject))
                    throw CommandError(
                        "invalid_argument", "/path: '" + raw + "' is outside the project.",
                        "The manifest and its page must be inside the project, so the game can load them.");
            };
            if (!raw.empty()) judge_path();
            const Entity e = need_entity(I.world, a, "entity");
            const ReflectionProbe* probe = I.world.get<ReflectionProbe>(e);
            const std::string id = I.world.id_of(e);
            if (!probe)
                throw CommandError("invalid_argument", "/entity: '" + id + "' has no ReflectionProbe component.",
                                   "Add one first: scene.set_component {\"id\":\"" + id +
                                       "\",\"component\":\"ReflectionProbe\"}.");
            if (raw.empty()) {
                raw = default_manifest(I, id);
                judge_path();
            }
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.",
                                   "probe.bake draws the scene: run with graphics (headless needs Mesa/EGL on Linux).");
            if (!I.renderer->supports("floatTargets"))
                throw CommandError("unavailable",
                                   "This GPU cannot render to RGBA16F, and a baked probe holds light above 1.",
                                   "Bake on a machine with half-float render targets (render.supports floatTargets), "
                                   "or use a realtime probe.");

            Renderer::ProbePage page;
            std::string error;
            if (!I.renderer->probe_capture(I.world, e, page, &error))
                throw CommandError("bake_failed", "the capture of '" + id + "' failed: " + error,
                                   "Check the log for the GPU's message; a probe with resolution 256 needs about 3 MB "
                                   "of scratch images.");

            auto image = ImageF::create(page.width, page.height, 3);
            if (!image) throw CommandError("bake_failed", image.error().message, image.error().hint);
            if (image->data.size() != page.rgb.size())
                throw CommandError("bake_failed", "the capture has an unexpected size.", "Report this with the scene.");
            image->data = page.rgb;
            const std::vector<std::uint8_t> bytes = encode_hdr(*image);

            ProbeManifest manifest;
            manifest.resolution = page.resolution;
            manifest.levels = probe_levels(page.resolution);
            manifest.hash = probe_hash_hex(bytes);
            manifest.entity = id;
            for (int k = 0; k < kProbeShCoefficients; ++k)
                for (int c = 0; c < 3; ++c) manifest.sh[k][c] = page.sh[k][c];
            const std::string dirAbs = dir_of(manifestAbs), dirProject = dir_of(manifestProject);
            std::string stem = file_of(manifestProject);
            stem.resize(stem.size() - std::string(kSuffix).size());
            const std::string pageName = stem + ".probe." + manifest.hash + ".hdr";
            manifest.page = dirProject + pageName;

            // The page that the manifest names now, to remove it after the new manifest is in place (never before: a reader may still be on it).
            std::string oldPage;
            if (fs::exists(manifestProject))
                if (auto text = fs::read_text(manifestProject); text)
                    if (auto json = parse_json(*text, manifestProject); json)
                        if (auto old = probe_manifest_from_json(*json, manifestProject); old) oldPage = old->page;

            const std::string pageAbs = dirAbs + pageName;
            bool same = false;
            if (fs::exists(pageAbs))
                if (auto old = fs::read_bytes(pageAbs); old && *old == bytes)
                    same = true;  // the same bake again: nothing to replace
            if (!same) {
                if (auto w = fs::write_bytes(pageAbs, bytes.data(), bytes.size()); !w)
                    throw CommandError(
                        "write_failed", "cannot write the probe page '" + pageAbs + "': " + w.error().message,
                        w.error().hint.empty() ? "Close the program that holds the file, or bake to another `path`."
                                               : w.error().hint);
            }
            const std::string text = dump_json(probe_manifest_to_json(manifest)) + "\n";
            if (auto w = fs::write_bytes(manifestAbs, text.data(), text.size()); !w) {
                if (!same && manifest.page != oldPage) {  // nothing names the new page: do not leave it behind
                    std::error_code ec;
                    fs::remove_file(fs::path_from_utf8(pageAbs), ec);
                }
                throw CommandError(
                    "write_failed", "cannot write the probe manifest '" + manifestAbs + "': " + w.error().message,
                    w.error().hint.empty() ? "Close the program that holds the file, or bake to another `path`."
                                           : w.error().hint);
            }
            // Only a page that looks like this manifest's own ('<stem>.probe.<hash>.hdr' in its folder) is removed.
            if (!oldPage.empty() && oldPage != manifest.page && dir_of(oldPage) == dirProject) {
                const std::string name = file_of(oldPage);
                const std::string prefix = stem + ".probe.";
                if (name.rfind(prefix, 0) == 0 && name.size() > 4 && name.substr(name.size() - 4) == ".hdr") {
                    std::error_code ec;
                    fs::remove_file(fs::path_from_utf8(dirAbs + name), ec);
                }
            }

            Json out = Json::object();
            out["entity"] = id;
            out["manifest"] = manifestProject;
            out["page"] = manifest.page;
            out["hash"] = manifest.hash;
            out["resolution"] = page.resolution;
            out["bytes"] = double(bytes.size());
            bool applied = false;
            if (apply) {
                if (ReflectionProbe* rp = I.world.get<ReflectionProbe>(e)) {
                    rp->bakedMap = manifestProject;
                    applied = true;
                    if (rp->mode != ProbeMode::Baked)
                        out["note"] = "ReflectionProbe.mode is realtime, so the probe is still captured while the game "
                                      "runs: set mode to baked to use the page.";
                }
            }
            out["applied"] = applied;
            I.renderer->reload_asset(manifestProject);  // a rebake under the same name: the renderer reads the new pair
            return out;
        });

    declare_command_capabilities(I.commands, {{"probe.bake", capability_sets::edits_project()}});
}

}  // namespace fa
