// The shader step of an export (docs/design/CUSTOM_SHADERS.md, "Where and when it runs"): the player has no shader compiler,
// so every shipped *.material.json gets its compiled twins, one per shader dialect of the platform
// (materials/water.material.json -> materials/water.material.json.glsl300es.shader), and the GLSL snippets the materials
// name stay home. Twins come from compile_material, so an unchanged material is served from .factoria/shader-cache and
// starts no process; the shipped copies are written to <cacheDir>/shaders/.
#include <algorithm>

#include "export_internal.h"
#include "fa/tooling/shaders.h"
#include "fa/tooling/validate.h"

namespace fa::export_detail {

Result<void> convert_shaders(ExportAssets& ea) {
    std::vector<std::string> materials;
    for (const std::string& f : ea.files)
        if (f.ends_with(".material.json")) materials.push_back(f);
    if (materials.empty()) return {};
    std::sort(materials.begin(), materials.end());
    auto dialects = shader_dialects_for({ea.platform}, ea.vulkan);
    if (!dialects.ok()) return dialects.error();

    ShaderCompileOptions options;
    options.setup = ea.setup;
    options.dialects = *dialects;
    for (const std::string& path : materials) {
        auto compiled = compile_material(ea.project.dir.string(), path, options);
        if (!compiled.ok())
            return err("export: the shaders of " + path + " cannot be compiled: " + compiled.error().message,
                       compiled.error().hint);
        if (!compiled->ok) {
            std::string message = "export: the material " + path + " does not compile, so the game cannot be exported:";
            for (const ValidationIssue& i : shader_validation_issues(*compiled)) message += "\nerror: " + i.to_string();
            return err(message, "Fix it and export again; `factoria validate` lists the same errors.");
        }
        // spirv_vk alone is no shader the platform's own player can run (a compute material has it on android and the web has none).
        const bool ownTwin = std::any_of(compiled->twins.begin(), compiled->twins.end(),
                                         [](const auto& t) { return t.first != kShaderDialectVulkan; });
        if (!compiled->skippedDialects.empty() && !ownTwin)
            ea.report.warnings.push_back(
                "the " + compiled->material.kind + " material " + path + " has no shader for " + ea.platform +
                ": that platform has no compute shaders and no storage buffers in the vertex stage (" +
                join(compiled->skippedDialects, ", ") +
                "), so it is exported without one (compute.* calls fail there with an error, and a MeshRenderer with a "
                "material with buffers is drawn with the error material). Check "
                "render.supports computeShaders before using it, or leave the material out of this platform's export "
                "(it runs on " +
                join(shader_platforms_of_kind(compiled->material.kind, !compiled->material.buffers.empty()), ", ") +
                ").");
        for (const auto& [slang, twin] : compiled->twins) {
            const std::string shipped = path + "." + slang + ".shader";
            const stdfs::path source = ea.cacheDir / "shaders" / shipped;
            std::string e;
            if (!write_file(source, twin.dump(), &e)) return err("export: " + e);
            ea.replace("", shipped, source);
        }
        std::erase(ea.files, compiled->material.shader);  // `materials` is a copy
        ea.project.staged.erase(compiled->material.shader);
        ea.report.materials.push_back(path);
    }
    return {};
}

}  // namespace fa::export_detail
