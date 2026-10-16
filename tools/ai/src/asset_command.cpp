// The `asset-command` provider: a local program makes the asset (ComfyUI, a local Stable Diffusion, a Blender script...).
// "command" and "argv" of the provider are a template; the program writes the file to {output}. The process runner
// applies the argument rules it applies to every child (a .cmd/.bat file cannot receive % & | < > ^ or line breaks).
#include <algorithm>
#include <filesystem>
#include <format>

#include "asset_providers.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"

namespace fa::ai {

namespace fsys = std::filesystem;

Result<AssetResult> command_asset(const ProviderConfig& cfg, const AssetRequest& req, const CancelFlag* cancel) {
    const fsys::path dir = fs::make_temp_dir("fa_asset");
    struct Cleanup {
        fsys::path dir;
        ~Cleanup() { std::error_code ec; fsys::remove_all(dir, ec); }
    } cleanup{dir};
    const fsys::path output = dir / ("asset" + asset_extension(cfg, req.kind));

    // No seed given: one from the prompt, so the same request gives the same picture on a program that honours it.
    const bool takesSeed = std::any_of(cfg.argv.begin(), cfg.argv.end(), [](const std::string& a) { return a.find("{seed}") != std::string::npos; });
    const std::int64_t seed = req.seed ? *req.seed : static_cast<std::int64_t>(std::stoull(sha256_hex(req.prompt).substr(0, 8), nullptr, 16));
    std::string prompt = req.prompt;  // one line: a .cmd/.bat program cannot take line breaks
    std::replace_if(prompt.begin(), prompt.end(), [](char c) { return c == '\n' || c == '\r'; }, ' ');
    const std::pair<const char*, std::string> subs[] = {{"{prompt}", prompt},
                                                         {"{output}", output.string()},
                                                         {"{width}", std::to_string(req.width)},
                                                         {"{height}", std::to_string(req.height)},
                                                         {"{seconds}", std::format("{}", req.seconds)},
                                                         {"{kind}", media_kind_name(req.kind)},
                                                         {"{model}", req.model},
                                                         {"{seed}", std::to_string(seed)}};
    ProcessOptions po;
    po.argv.push_back(cfg.command);
    for (std::string arg : cfg.argv) {
        for (const auto& [key, value] : subs) arg = fa::replace_all(std::move(arg), key, value);
        po.argv.push_back(std::move(arg));
    }
    po.env = cfg.env;
    po.unsetEnv = cfg.unsetEnv;
    po.timeoutSeconds = cfg.timeoutSeconds;
    po.cancel = cancel;

    auto ran = run_process(po);
    if (!ran) {
        return make_error(ran.error().message, ran.error().message.find("cmd.exe") == std::string::npos
                                                   ? ran.error().hint
                                                   : "A .cmd/.bat program cannot take % & | < > ^ or line breaks in an argument: leave them "
                                                     "out of the prompt, or run an .exe/.py wrapper instead.");
    }
    if (ran->cancelled) return make_error("Cancelled");
    if (ran->timedOut) {
        return make_error("'" + cfg.command + "' did not finish in " + std::format("{}", cfg.timeoutSeconds) + " seconds",
                          "Raise \"timeoutSeconds\" of provider '" + cfg.name + "' in ai.json.");
    }
    if (ran->exitCode != 0) {
        return make_error("'" + cfg.command + "' failed (exit code " + std::to_string(ran->exitCode) + "): " +
                              std::string(fa::trim(ran->stderrText.substr(0, 400))),
                          "Run it by hand with the same arguments to see why; \"argv\" of provider '" + cfg.name + "' is the template.");
    }
    std::error_code ec;
    if (!fsys::is_regular_file(output, ec) || fsys::file_size(output, ec) == 0) {
        return make_error("'" + cfg.command + "' exited without writing " + output.filename().string() + " (the {output} path)",
                          "The program must write the " + std::string(media_kind_name(req.kind)) + " to the path {output} stands for. Put {output} in \"argv\" of provider '" +
                              cfg.name + "'.");
    }
    auto bytes = fs::read_bytes(output.generic_string());
    if (!bytes) return bytes.error();
    AssetResult out;
    out.bytes.assign(bytes->begin(), bytes->end());
    out.model = req.model;
    if (takesSeed) out.seed = seed;
    return out;
}

}  // namespace fa::ai
