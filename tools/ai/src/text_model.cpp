#include "fa/ai/text_model.h"

#include <filesystem>
#include <memory>

#include "fa/ai/anthropic.h"
#include "fa/ai/cli_agent.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa::ai {

namespace {
namespace stdfs = std::filesystem;

// "may be refused because of the pictures": a provider error that talks about images, vision or multimodal input.
bool mentions_images(const std::string& message) {
    const std::string m = fa::to_lower(message);
    return m.find("image") != std::string::npos || m.find("vision") != std::string::npos || m.find("multimodal") != std::string::npos ||
           m.find("multi-modal") != std::string::npos;
}

Error with_vision_hint(Error e, const std::string& model, const std::string& roleName) {
    if (mentions_images(e.message) || mentions_images(e.hint))
        e.hint = (e.hint.empty() ? std::string() : e.hint + " ") + "The model '" + model + "' of the \"" + roleName +
                 "\" role may not accept pictures: point that role at a vision model (Claude, GPT-4o and later, Gemini, a llava model in Ollama; docs/AI_PROVIDERS.md).";
    return e;
}

Message user_message(const std::string& user, const std::vector<ImageData>& images) { return Message::user(user, images); }

std::string default_work_dir() {
    std::error_code ec;
    stdfs::path dir = stdfs::temp_directory_path(ec) / "factoria-text-model";
    return dir.string();
}
}  // namespace

Result<VisionModel> make_vision_model(const AiConfig& cfg, const TextModelOptions& options, TextModelInfo* info) {
    std::string roleName = options.role.empty() ? std::string(kRoleFast) : options.role;
    if (!cfg.role_enabled(roleName)) roleName = kRoleOrchestrator;
    const RoleConfig rc = cfg.role(roleName);
    const ProviderConfig* pc = cfg.provider(rc.provider);
    const std::string where = cfg.sourcePath.empty() ? std::string("the AI settings") : cfg.sourcePath;
    if (!pc)
        return make_error("The \"" + roleName + "\" role names the provider '" + rc.provider + "', which " + where + " does not define.",
                          "Pick a provider in the editor (AI settings > Roles) or see docs/AI_PROVIDERS.md.");
    if (info) {
        info->role = roleName;
        info->provider = pc->name;
        info->model = rc.model;
    }

    if (options.providerFactory) {
        auto made = options.providerFactory(*pc);
        if (!made.ok()) return made.error();
        const std::shared_ptr<ChatProvider> chat = *made;
        const std::string model = rc.model, effort = rc.effort;
        const Pricing pricing = pc->pricing.known ? pc->pricing : builtin_pricing(model);
        const auto onUsage = options.onUsage;
        return VisionModel([chat, model, effort, roleName, pricing, onUsage](const std::string& system, const std::string& user,
                                                 const std::vector<ImageData>& images) -> Result<std::string> {
            ChatRequest req;
            req.model = model;
            req.effort = effort;
            req.maxTokens = 4096;
            req.system = system;
            req.messages.push_back(user_message(user, images));
            auto res = chat->chat(req, {}, nullptr);
            if (!res.ok()) return with_vision_hint(res.error(), model, roleName);
            if (onUsage) onUsage(res->usage, estimate_cost(res->usage, pricing));
            return res->message.text;
        });
    }

    if (is_cli_kind(pc->kind)) {
        const std::string command = pc->command.empty() ? default_cli_command(pc->kind) : pc->command;
        if (command.empty() || find_cli(command, options.runtime.env).empty())
            return make_error("The CLI '" + command + "' of provider '" + pc->name + "' is not installed.", cli_install_hint(*pc));
        const ProviderConfig provider = *pc;
        const std::string model = rc.model;
        const std::string workDir = options.cliWorkDir.empty() ? default_work_dir() : options.cliWorkDir;
        const auto onUsage = options.onUsage;
        return VisionModel([provider, model, workDir, onUsage](const std::string& system, const std::string& user,
                                                      const std::vector<ImageData>& images) -> Result<std::string> {
            std::error_code ec;
            stdfs::create_directories(workDir, ec);
            CliRunRequest req;
            req.prompt = system + "\n\n" + user;
            // The CLI reads the pictures inline (stream-json) or from files named in the prompt: write them in its folder.
            std::vector<stdfs::path> written;
            for (std::size_t i = 0; i < images.size(); ++i) {
                const std::string ext = images[i].mediaType == "image/jpeg" ? ".jpg" : images[i].mediaType == "image/webp" ? ".webp"
                                        : images[i].mediaType == "image/gif" ? ".gif" : ".png";
                const stdfs::path file = stdfs::path(workDir) / ("image-" + std::to_string(i + 1) + ext);
                const std::vector<unsigned char> bytes = fa::base64_decode(images[i].base64);
                if (auto wrote = fa::fs::write_bytes(file.string(), bytes.data(), bytes.size()); !wrote.ok()) {
                    for (const auto& w : written) stdfs::remove(w, ec);
                    return make_error("Cannot write the picture for the CLI agent to " + file.string() + ": " + wrote.error().message,
                                      "Check the disk space and the folder's permissions.");
                }
                written.push_back(file);
                req.images.push_back(images[i]);
                req.imagePaths.push_back(file.string());
            }
            req.model = model;
            req.projectDir = workDir;
            req.readOnly = true;
            req.disallowedTools = {"Bash", "Edit", "Write", "NotebookEdit", "WebFetch", "WebSearch", "Agent", "Task"};
            auto run = CliAgent(provider).run(req, [](const AgentEvent&) {}, nullptr);
            for (const auto& w : written) stdfs::remove(w, ec);
            if (!run.ok()) return run.error();
            if (!run->ok) return make_error(run->error.empty() ? "The CLI agent failed." : run->error, run->hint);
            if (onUsage) onUsage(run->usage, run->costUsd);
            return run->finalText;
        });
    }
    if (is_asset_only_kind(pc->kind))
        return make_error("The provider '" + pc->name + "' of the \"" + roleName + "\" role only makes assets.",
                          "Point roles." + roleName + " at a chat provider (docs/AI_PROVIDERS.md).");

    const bool keyless = pc->preset == "ollama" || pc->preset == "lmstudio" || pc->baseUrl.find("localhost") != std::string::npos ||
                         pc->baseUrl.find("127.0.0.1") != std::string::npos;
    // Anthropic without a key falls back to the token of the `ant` CLI: ask it for one (resolve_auth), since a program
    // called `ant` on the PATH can be Apache Ant, which has no token to give.
    if (!keyless && !resolve_api_key(*pc, options.runtime.env).found() &&
        !(pc->kind == ProviderKind::Anthropic && pc->useAntCli && anthropic::resolve_auth(*pc, options.runtime).ok()))
        return make_error("The provider '" + pc->name + "' of the \"" + roleName + "\" role has no API key.",
                          "Set " + default_key_env(*pc) + " or put the key in " + where + " (docs/AI_PROVIDERS.md).");
    auto provider = make_chat_provider(*pc, options.runtime);
    if (!provider.ok()) return provider.error();
    const std::shared_ptr<ChatProvider> chat = *provider;
    const std::string model = rc.model, effort = rc.effort;
    const Pricing pricing = pc->pricing.known ? pc->pricing : builtin_pricing(model);
    const auto onUsage = options.onUsage;
    return VisionModel([chat, model, effort, roleName, pricing, onUsage](const std::string& system, const std::string& user,
                                                 const std::vector<ImageData>& images) -> Result<std::string> {
        ChatRequest req;
        req.model = model;
        req.effort = effort;
        req.maxTokens = 4096;
        req.system = system;
        req.messages.push_back(user_message(user, images));
        auto res = chat->chat(req, {}, nullptr);
        if (!res.ok()) return with_vision_hint(res.error(), model, roleName);
        if (onUsage) onUsage(res->usage, estimate_cost(res->usage, pricing));
        return res->message.text;
    });
}

Result<TextModel> make_text_model(const AiConfig& cfg, const TextModelOptions& options, TextModelInfo* info) {
    auto vision = make_vision_model(cfg, options, info);
    if (!vision.ok()) return vision.error();
    const VisionModel model = *vision;
    return TextModel([model](const std::string& system, const std::string& user) { return model(system, user, {}); });
}

}  // namespace fa::ai
