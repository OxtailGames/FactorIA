#include "headless_run.h"

#include <filesystem>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/shaders.h"

namespace fa::tooling_detail {

void require_project_dir(const std::string& projectDir, const std::string& command) {
    if (projectDir.empty() || !std::filesystem::exists(fs::os_path(std::filesystem::path(projectDir) / "factoria.json")))
        throw CommandError("not_found", command + " needs a project (factoria.json not found).",
                           "Run it inside a game folder or pass --project <folder>.");
}

std::string project_path(const std::string& projectDir, const std::string& p) {
    return fs::is_absolute(p) ? p : (std::filesystem::path(projectDir) / p).generic_string();
}

EngineConfig headless_engine_config(const std::string& projectDir, const std::string& scene, bool graphics, RenderMode renderMode) {
    EngineConfig cfg;
    cfg.projectDir = projectDir;
    cfg.shaderCompiler = make_engine_shader_compiler(projectDir);
    cfg.scene = scene;
    cfg.headless = true;
    cfg.graphics = graphics;
    cfg.audioDevice = false;
    cfg.hotReload = false;
    cfg.renderMode = renderMode;
    cfg.memoryStorage = true;
    cfg.platformBackend = "fake";
    return cfg;
}

}  // namespace fa::tooling_detail
