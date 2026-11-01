#include "fa/ai/text_model.h"

#include <filesystem>
#include <memory>

#include "fa/ai/cli_agent.h"
#include "fa/core/fs.h"

namespace fa::ai {

namespace {
namespace stdfs = std::filesystem;

std::string default_work_dir() {
    std::error_code ec;
    stdfs::path dir = stdfs::temp_directory_path(ec) / "factoria-text-model";
    return dir.string();
}
}  // namespace

Result<TextModel> make_text_model(const AiConfig& cfg, const TextModelOptions& options, TextModelInfo* info) {
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
        return TextModel([chat, model, effort](const std::string& system, const std::string& user) -> Result<std::string> {
            ChatRequest req;
            req.model = model;
            req.effort = effort;
            req.maxTokens = 4096;
            req.system = system;
            req.messages.push_back(Message::user(user));
            auto res = chat->chat(req, {}, nullptr);
            if (!res.ok()) return res.error();
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
        return TextModel([provider, model, workDir](const std::string& system, const std::string& user) -> Result<std::string> {
            std::error_code ec;
            stdfs::create_directories(workDir, ec);
            CliRunRequest req;
            req.prompt = system + "\n\n" + user;
            req.model = model;
            req.projectDir = workDir;
            req.readOnly = true;
            req.disallowedTools = {"Bash", "Edit", "Write", "NotebookEdit", "WebFetch", "WebSearch", "Agent", "Task"};
            auto run = CliAgent(provider).run(req, [](const AgentEvent&) {}, nullptr);
            if (!run.ok()) return run.error();
            if (!run->ok) return make_error(run->error.empty() ? "The CLI agent failed." : run->error, run->hint);
            return run->finalText;
        });
    }
    if (is_asset_only_kind(pc->kind))
        return make_error("The provider '" + pc->name + "' of the \"" + roleName + "\" role only makes assets.",
                          "Point roles." + roleName + " at a chat provider (docs/AI_PROVIDERS.md).");

    const bool keyless = pc->preset == "ollama" || pc->preset == "lmstudio" || pc->baseUrl.find("localhost") != std::string::npos ||
                         pc->baseUrl.find("127.0.0.1") != std::string::npos;
    if (!keyless && !resolve_api_key(*pc, options.runtime.env).found() &&
        !(pc->kind == ProviderKind::Anthropic && pc->useAntCli && !find_cli("ant", options.runtime.env).empty()))
        return make_error("The provider '" + pc->name + "' of the \"" + roleName + "\" role has no API key.",
                          "Set " + default_key_env(*pc) + " or put the key in " + where + " (docs/AI_PROVIDERS.md).");
    auto provider = make_chat_provider(*pc, options.runtime);
    if (!provider.ok()) return provider.error();
    const std::shared_ptr<ChatProvider> chat = *provider;
    const std::string model = rc.model, effort = rc.effort;
    return TextModel([chat, model, effort](const std::string& system, const std::string& user) -> Result<std::string> {
        ChatRequest req;
        req.model = model;
        req.effort = effort;
        req.maxTokens = 4096;
        req.system = system;
        req.messages.push_back(Message::user(user));
        auto res = chat->chat(req, {}, nullptr);
        if (!res.ok()) return res.error();
        return res->message.text;
    });
}

}  // namespace fa::ai
