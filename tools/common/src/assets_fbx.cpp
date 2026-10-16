// FBX (.fbx) -> glb. FBX is a closed format, so the file is converted by a program that reads it: FBX2glTF, or Blender run
// in the background. Neither ships with FactorIA; without them assets.import says where to get one.
#include <algorithm>
#include <cstdlib>
#include <format>
#include <mutex>
#include <optional>

#include "assets_internal.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "util.h"

namespace fa {

namespace {

std::mutex g_overrideMutex;
std::optional<FbxConverters> g_override;  // set by tests

std::string blender_in_install_folders() {
    namespace stdfs = std::filesystem;
    std::error_code ec;
#if defined(_WIN32)
    // "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe": the newest version wins.
    std::string best;
    std::vector<int> bestVersion;
    for (const char* var : {"ProgramFiles", "ProgramW6432", "ProgramFiles(x86)"}) {
        const char* root = std::getenv(var);
        if (!root) continue;
        for (const auto& dir : stdfs::directory_iterator(stdfs::path(root) / "Blender Foundation", ec)) {
            const stdfs::path exe = dir.path() / "blender.exe";
            if (!stdfs::is_regular_file(exe, ec)) continue;
            std::vector<int> version;
            for (const std::string& part : split(replace_all(dir.path().filename().string(), "Blender", ""), '.'))
                version.push_back(std::atoi(part.c_str()));
            if (best.empty() || version > bestVersion) {
                best = exe.string();
                bestVersion = version;
            }
        }
    }
    return best;
#elif defined(__APPLE__)
    const stdfs::path exe = "/Applications/Blender.app/Contents/MacOS/Blender";
    return stdfs::is_regular_file(exe, ec) ? exe.string() : std::string();
#else
    for (const char* exe : {"/usr/bin/blender", "/usr/local/bin/blender", "/snap/bin/blender", "/opt/blender/blender"})
        if (stdfs::is_regular_file(exe, ec)) return exe;
    return {};
#endif
}

// Written next to the FBX, run by Blender: imports it into an empty scene and exports a glb.
constexpr const char* kBlenderScript = R"(import sys
import bpy
src, dst = sys.argv[sys.argv.index("--") + 1:][:2]
for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
if hasattr(bpy.ops.import_scene, "fbx"):
    bpy.ops.import_scene.fbx(filepath=src)
else:
    bpy.ops.wm.fbx_import(filepath=src)
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB")
)";

std::string tail(const ProcessResult& r) {
    std::vector<std::string> lines = split(r.stderrText + "\n" + r.stdoutText, '\n');
    if (lines.size() > 12) lines.erase(lines.begin(), lines.end() - 12);
    return join(lines, "\n");
}

}  // namespace

FbxConverters find_fbx_converters() {
    {
        std::lock_guard lock(g_overrideMutex);
        if (g_override) return *g_override;
    }
    namespace stdfs = std::filesystem;
    FbxConverters found;
    std::error_code ec;
    if (const char* env = std::getenv("FACTORIA_FBX2GLTF"); env && *env && stdfs::is_regular_file(env, ec)) found.fbx2gltf = env;
    if (found.fbx2gltf.empty()) found.fbx2gltf = which("FBX2glTF");
    found.blender = which("blender");
    if (found.blender.empty()) found.blender = blender_in_install_folders();
    return found;
}

void set_fbx_converters(const FbxConverters* converters) {
    std::lock_guard lock(g_overrideMutex);
    if (converters) g_override = *converters;
    else g_override.reset();
}

namespace assets_detail {

Result<ImportOutput> import_fbx(const ImportRequest& request) {
    const FbxConverters converters = find_fbx_converters();
    if (converters.fbx2gltf.empty() && converters.blender.empty())
        return make_error("FBX is a closed format, so FactorIA converts it with another program, and neither FBX2glTF nor Blender was found.",
                          "Install Blender (free, https://www.blender.org/download/; it is found in PATH or its standard install folder) or FBX2glTF "
                          "(https://github.com/godotengine/FBX2glTF/releases; put it in PATH or set FACTORIA_FBX2GLTF to its path), then import "
                          "again. Or convert the model to .glb yourself (Blender: File > Export > glTF 2.0) and import that file.");

    const stdfs::path work = fs::make_temp_dir("fa_fbx");
    struct Cleanup {
        stdfs::path dir;
        ~Cleanup() { std::error_code ec; stdfs::remove_all(dir, ec); }
    } cleanup{work};
    const stdfs::path glb = work / "model.glb";
    std::string used, failure;

    auto run = [&](const std::string& program, std::vector<std::string> args) {
        ProcessOptions options;
        options.argv = {program};
        options.argv.insert(options.argv.end(), args.begin(), args.end());
        options.timeoutSeconds = 300;
        auto r = run_process(options);
        std::error_code ec;
        if (r.ok() && r->exitCode == 0 && stdfs::is_regular_file(glb, ec) && stdfs::file_size(glb, ec) > 0) return true;
        failure = r.ok() ? (r->timedOut ? "it did not finish in 5 minutes" : "it exited with code " + std::to_string(r->exitCode) + ":\n" + tail(*r))
                         : r.error().message;
        stdfs::remove(glb, ec);
        return false;
    };
    if (!converters.fbx2gltf.empty() &&
        run(converters.fbx2gltf, {"--binary", "--input", request.source.string(), "--output", (work / "model").string()}))
        used = "FBX2glTF";
    if (used.empty() && !converters.blender.empty()) {
        const stdfs::path script = work / "convert.py";
        if (!tooling_detail::write_file(script, kBlenderScript)) return make_error("cannot write a temporary file in " + work.string());
        if (run(converters.blender, {"-b", "--factory-startup", "--python-exit-code", "1", "--python", script.string(), "--",
                                     request.source.string(), glb.string()}))
            used = "Blender";
    }
    if (used.empty())
        return make_error("Converting '" + request.source.filename().string() + "' failed: " + failure,
                          "Open the FBX in Blender (File > Import > FBX) to see whether it loads, and export it as .glb from there; then import the .glb.");

    auto bytes = read_bytes(glb);
    if (!bytes.ok()) return make_error("The converter did not leave a readable file.");
    ImportOutput out;
    out.files.push_back({request.dest, std::move(*bytes)});
    out.details = Json::object({{"converter", used}});
    out.warnings.push_back("Converted with " + used + ". The engine draws the meshes and materials; skins and animations are not used yet. Check the "
                           "scale and orientation with game.screenshot.");
    return out;
}

}  // namespace assets_detail

}  // namespace fa
