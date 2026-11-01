// "Add TokenEconomizer" in the Extensions tab of the AI settings window (docs/AI_PROVIDERS.md, "Installing a plugin"): a read-only
// dry run of ai::plugin_install says what is already installed, the button asks first (what will be installed and why Python is
// needed), the install runs on its own thread (ai::plugin_install runs the Claude Code CLI's plugin commands) and the entry it adds
// to ai.json is merged into the tab's working copy without touching the user's other unsaved edits.
#include <algorithm>
#include <thread>

#include "editor_internal.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {

std::string lower_copy(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

// `claude plugin install tokeneconomizer@tokeneconomizer`: the program is shown by its name, not by its path.
std::string command_text(const Json& argv) {
    std::string out;
    for (std::size_t i = 0; argv.is_array() && i < argv.size(); ++i) {
        std::string a = argv[i].is_string() ? argv[i].get<std::string>() : std::string();
        if (i == 0) a = "claude";
        out += (out.empty() ? "" : " ") + a;
    }
    return out;
}

}  // namespace

void Editor::ai_plugin_start(const ai::AiConfig& cfg, const ai::PluginInstallRequest& request, bool install) {
    auto job = aiPluginJob_;
    {
        std::lock_guard<std::mutex> lock(job->mu);
        if (job->running) return;
        job->running = true;
        job->installing = install;
        job->cancel = false;
        if (install) {
            job->lines.clear();
            job->finished = false;
            job->message.clear();
        }
    }
    if (aiPluginThread_.joinable()) aiPluginThread_.join();
    ai::PluginInstallRequest req = request;
    req.dryRun = !install;
    req.configPath = aiSettings_.path;
    aiPluginThread_ = std::thread([job, cfg, req, install, python = aiPluginPython_] {
        ai::PluginInstallHooks hooks;
        hooks.cancel = &job->cancel;
        hooks.pythonCommands = python;
        if (install) {
            hooks.onStep = [job](const Json& step) {
                const std::string status = step.value("status", std::string());
                const std::string id = step.value("id", std::string());
                std::string line;
                if (status == "running") line = "Running: " + (id == "entry" ? std::string("adding the entry to ai.json") : command_text(step["command"]));
                else if (status == "done") line = "Done: " + id;
                else if (status == "skipped") line = "Skipped " + id + ": " + step.value("detail", std::string());
                else if (status == "failed") line = "Failed " + id + ": " + step.value("detail", std::string());
                if (line.empty()) return;
                std::lock_guard<std::mutex> lock(job->mu);
                job->lines.push_back(line);
            };
        }
        auto result = ai::plugin_install(cfg, req, hooks);
        std::lock_guard<std::mutex> lock(job->mu);
        job->running = false;
        if (install) {
            job->installing = false;
            job->finished = true;
            job->ok = bool(result);
            job->message = result ? result->value("message", std::string("Done.")) : result.error().to_string();
        } else {
            job->probeDone = true;
            job->probeError = result ? std::string() : result.error().to_string();
            job->probe = result ? *result : Json::object();
        }
    });
}

void Editor::draw_ai_economizer_view(const ai::AiConfig& cfg, bool configReadable) {
    auto& x = aiSettings_.ext;
    const ai::PluginInstallRequest preset = ai::token_economizer_request();
    auto job = aiPluginJob_;
    const auto wrapped = [](const ImVec4& color, const std::string& text) {
        ImGui::PushStyleColor(ImGuiCol_Text, color);
        ImGui::TextWrapped("%s", text.c_str());
        ImGui::PopStyleColor();
    };

    ImGui::SeparatorText("TokenEconomizer");
    ImGui::TextWrapped("TokenEconomizer is Microsoft's plugin for Claude Code that cuts the tokens a coding agent spends. One click installs it with "
                       "Claude Code's own plugin commands and adds it to the list above.");

    // An install that ended: take its result, merge the entry into the working copy, ask the CLI again.
    bool finished = false, ok = false;
    std::string message;
    {
        std::lock_guard<std::mutex> lock(job->mu);
        if (job->finished) {
            finished = true;
            ok = job->ok;
            message = job->message;
            job->finished = false;
            job->probeDone = false;
        }
    }
    if (finished) {
        aiEconomizerOk_ = ok;
        aiEconomizerMessage_ = message;
        aiEconomizerConfirm_ = false;
        auto loaded = ai::load_config(aiSettings_.path);
        if (loaded) {
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                aiConfig_ = *loaded;
            }
            for (const ai::Extension& e : loaded->extensions.entries) {
                if (e.kind != ai::ExtensionKind::Plugin || lower_copy(e.plugin) != lower_copy(preset.plugin)) continue;
                const auto has = [&](const std::vector<ai::Extension>& list) {
                    return std::ranges::any_of(list, [&](const ai::Extension& o) { return o.kind == e.kind && lower_copy(o.plugin) == lower_copy(e.plugin); });
                };
                if (!has(x.user)) x.user.push_back(e);
                if (!has(x.userLoaded)) x.userLoaded.push_back(e);
            }
            x.statusAt = -10;
        }
    }

    bool running = false, installing = false, probeDone = false;
    Json probe = Json::object();
    std::string probeError;
    std::vector<std::string> lines;
    {
        std::lock_guard<std::mutex> lock(job->mu);
        running = job->running;
        installing = job->installing;
        probeDone = job->probeDone;
        probe = job->probe;
        probeError = job->probeError;
        lines = job->lines;
    }
    if (!running && !probeDone && configReadable && (!autotest_ || aiPluginProbeInTest_)) ai_plugin_start(cfg, preset, false);

    const Json steps = probe.value("steps", Json::array());
    const auto needed = [&](std::size_t i) { return i < steps.size() ? steps[i].value("needed", true) : true; };
    const bool pluginDone = probeDone && probeError.empty() && steps.size() == 3 && !needed(1);
    const bool entryInDraft = std::ranges::any_of(x.user, [&](const ai::Extension& e) {
        return e.kind == ai::ExtensionKind::Plugin && lower_copy(e.plugin) == lower_copy(preset.plugin);
    });
    const Json python = probe.value("python", Json::object());
    const bool pythonOk = python.value("ok", false);

    if (installing) {
        ImGui::TextDisabled("Installing...");
        for (const std::string& line : lines) ImGui::BulletText("%s", line.c_str());
        if (ImGui::Button("Stop")) job->cancel = true;
        at_track("aiset:eco:stop");
        ImGui::SetItemTooltip("Stops the Claude Code command that is running. What it already installed stays.");
    } else if (!probeDone) {
        ImGui::TextDisabled(running ? "Asking Claude Code what is installed..." : "Checking Claude Code...");
    } else if (!probeError.empty()) {
        wrapped(kStatusFailed, probeError);
        if (ImGui::Button("Check again")) {
            std::lock_guard<std::mutex> lock(job->mu);
            job->probeDone = false;
        }
        at_track("aiset:eco:recheck");
    } else if (pluginDone && entryInDraft) {
        wrapped(kStatusReady, "TokenEconomizer is installed in Claude Code and listed in your extensions.");
        ImGui::BeginDisabled();
        ImGui::Button("Installed");
        ImGui::EndDisabled();
        at_track("aiset:eco:installed", false);
    } else if (pluginDone) {
        wrapped(kStatusWarn, "TokenEconomizer is installed in Claude Code, but it is not in your extensions list, so FactorIA's runs do not load it.");
        ImGui::BeginDisabled(!configReadable);
        if (ImGui::Button("Add the entry")) ai_plugin_start(cfg, preset, true);
        ImGui::EndDisabled();
        at_track("aiset:eco:entry", configReadable);
        ImGui::SetItemTooltip("Adds only the entry %s to %s; nothing is installed. It is written now; your other unsaved changes stay in this window.",
                              preset.plugin.c_str(), aiSettings_.path.c_str());
    } else {
        if (ImGui::Button(aiEconomizerConfirm_ ? "Hide" : "Add TokenEconomizer...")) aiEconomizerConfirm_ = !aiEconomizerConfirm_;
        at_track("aiset:eco:add");
        ImGui::SetItemTooltip("Shows what will be installed. Nothing runs until you confirm.");
    }

    if (aiEconomizerConfirm_ && !installing && probeDone && probeError.empty() && !pluginDone) {
        ImGui::Indent();
        ImGui::TextUnformatted("This will:");
        const char* kWhat[3] = {"Add the marketplace", "Install the plugin", "Add the entry"};
        for (std::size_t i = 0; i < steps.size() && i < 3; ++i) {
            const bool need = steps[i].value("needed", true);
            std::string line = std::string(kWhat[i]) + " ";
            if (i == 0) line += preset.marketplace + " (GitHub)";
            else if (i == 1) line += preset.plugin;
            else line += "'" + preset.entryName + "' to " + aiSettings_.path + " (your other keys stay)";
            const std::string cmd = command_text(steps[i]["command"]);
            if (!need) line += ": already done";
            else if (!cmd.empty()) line += ": " + cmd;
            ImGui::Bullet();
            ImGui::TextWrapped("%s", line.c_str());
        }
        wrapped(pythonOk ? kStatusReady : kStatusFailed,
                "Needs Python " + preset.requiresPython + " or newer: " + python.value("message", std::string("not checked")) +
                    (pythonOk ? "." : ". Install it first (python.org or your package manager), then press Check again."));
        ImGui::TextUnformatted("What TokenEconomizer does:");
        ImGui::BulletText("learns micro-skills per repository, so the agent stops re-reading what it already worked out");
        ImGui::BulletText("prunes the tools the agent is offered, with one command to give the tools back");
        ImGui::BulletText("guards against failure loops (the same failing call over and over)");
        wrapped(kStatusWarn, "It is a third-party plugin: its hooks run on this computer whenever Claude Code runs for you.");
        ImGui::BeginDisabled(!pythonOk || !configReadable);
        if (ImGui::Button("Install")) ai_plugin_start(cfg, preset, true);
        ImGui::EndDisabled();
        at_track("aiset:eco:confirm", pythonOk && configReadable);
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) aiEconomizerConfirm_ = false;
        at_track("aiset:eco:cancel");
        ImGui::SameLine();
        if (ImGui::Button("Check again")) {
            std::lock_guard<std::mutex> lock(job->mu);
            job->probeDone = false;
        }
        at_track("aiset:eco:recheck");
        ImGui::Unindent();
    }
    if (!aiEconomizerMessage_.empty()) {
        wrapped(aiEconomizerOk_ ? kStatusReady : kStatusFailed, aiEconomizerMessage_);
        if (aiEconomizerOk_) ImGui::TextDisabled("It is in ai.json already; Save keeps any other change you made here.");
    }
}

}  // namespace fa::editor
