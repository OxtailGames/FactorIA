// AI settings window: where each kind of asset is made (provider, model, voice, API key) and which websites the AI should
// look at when it searches for assets. Save writes "assets", "assetSources" and the few provider fields these need into the
// user's ai.json (ai::save_asset_settings: every other section of the file stays) and reloads it. docs/EDITOR.md
// ("AI settings"), docs/AI_PROVIDERS.md ("The AI settings window", "Asset sources").
#include <algorithm>
#include <cfloat>

#include "editor_internal.h"
#include "fa/ai/assets.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {

const char* const kNoneLabel = "None (made procedurally)";
const char* const kAssetCommand = "asset-command";  // the name given to a program of the user's when ai.json has none yet

const char* kind_title(ai::MediaKind k) {
    switch (k) {
        case ai::MediaKind::Image: return "Image";
        case ai::MediaKind::Sound: return "Sound";
        case ai::MediaKind::Music: return "Music";
        case ai::MediaKind::Voice: return "Voice";
        case ai::MediaKind::Model3d: return "3D model";
    }
    return "?";
}

bool needs_key(ai::ProviderKind k) {
    return k == ai::ProviderKind::OpenAICompatible || k == ai::ProviderKind::ElevenLabs || k == ai::ProviderKind::Meshy;
}

// The provider the draft's route names, as the config knows it (or the "asset-command" a first Save would create).
ai::ProviderConfig provider_of(const ai::AiConfig& cfg, const std::string& name) {
    if (const ai::ProviderConfig* p = cfg.provider(name)) return *p;
    ai::ProviderConfig synthetic;
    synthetic.name = name;
    synthetic.kind = ai::ProviderKind::AssetCommand;
    return synthetic;
}

bool same_sites(const std::vector<ai::AssetSite>& a, const std::vector<ai::AssetSite>& b) {
    if (a.size() != b.size()) return false;
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a[i].url != b[i].url || a[i].note != b[i].note) return false;
    }
    return true;
}

ImVec4 text_color(bool ok) { return ok ? kStatusReady : kStatusWarn; }

}  // namespace

void Editor::open_ai_settings(bool rolesTab) {
    if (!showAiSettings_) aiRolesOpen_ = true;  // a window opened now edits the roles as they are in the file
    if (rolesTab) aiSettingsTab_ = 1;
    showAiSettings_ = true;
    aiSettingsFocus_ = true;
    aiSettings_.loaded = false;
    if (!aiDetected_.load() && !aiDetecting_.load()) ai_refresh_providers();
}

// Fills the draft from the loaded config (and the status of the providers from this machine).
void Editor::ai_settings_load(const ai::AiConfig& cfg) {
    AiSettingsDraft& d = aiSettings_;
    d = AiSettingsDraft{};
    d.loaded = true;
    d.path = cfg.sourcePath.empty() ? ai::default_config_path() : cfg.sourcePath;
    for (ai::MediaKind k : ai::kMediaKinds) {
        const auto it = cfg.assets.find(ai::media_kind_name(k));
        d.routes[ai::media_kind_name(k)] = it == cfg.assets.end() ? ai::AssetRoute{} : it->second;
    }
    d.sources = cfg.assetSources;
    for (const auto& [name, p] : cfg.providers) {
        if (p.kind != ai::ProviderKind::AssetCommand) continue;
        d.command[name] = p.command;
        d.args[name] = ai::join_args(p.argv);
    }
    ai::DetectOptions options;
    options.probeVersions = false;  // only PATH lookups and key checks: nothing slow on the UI thread
    d.status = ai::detect_providers(cfg, options);
}

// What the draft would write, or the reason it cannot be written yet.
Result<ai::AssetSettings> Editor::ai_settings_build(const ai::AiConfig& cfg) const {
    const AiSettingsDraft& d = aiSettings_;
    ai::AssetSettings out;
    out.sources = d.sources;
    std::set<std::string> used;
    for (ai::MediaKind k : ai::kMediaKinds) {
        const auto it = d.routes.find(ai::media_kind_name(k));
        if (it == d.routes.end() || it->second.provider.empty()) continue;
        out.routes[ai::media_kind_name(k)] = it->second;
        used.insert(it->second.provider);
    }
    for (ai::SiteCategory c : ai::kSiteCategories) {
        std::size_t index = 0;
        for (const ai::AssetSite& site : out.sources.list(c)) {
            if (ai::asset_site_host(site.url).empty()) {
                return make_error(std::string(ai::site_category_title(c)) + ", site " + std::to_string(index + 1) + ": '" + site.url +
                                      "' is not a web address",
                                  "Write a domain such as opengameart.org or an address such as https://kenney.nl/assets, "
                                  "or remove the row.");
            }
            ++index;
        }
    }
    for (const std::string& name : used) {
        const ai::ProviderConfig p = provider_of(cfg, name);
        if (p.kind != ai::ProviderKind::AssetCommand) continue;
        const auto cmd = d.command.find(name);
        const std::string program = cmd == d.command.end() ? std::string() : std::string(trim(cmd->second));
        if (program.empty()) {
            return make_error("The asset-command provider '" + name + "' needs a program",
                              "Fill in Program under \"Your own program\" (for example python), or choose another provider.");
        }
        ai::AssetProviderEdit& edit = out.providers[name];
        edit.command = program;
        const auto args = d.args.find(name);
        edit.argv = ai::split_args(args == d.args.end() ? std::string() : args->second);
        if (!cfg.provider(name)) edit.type = "asset-command";
    }
    for (const auto& [name, key] : d.keys) {
        if (!key.empty() && !trim(key).empty()) out.providers[name].apiKey = std::string(trim(key));
    }
    for (const std::string& name : d.removeKey) {
        if (!d.keys.contains(name) || d.keys.at(name).empty()) out.providers[name].apiKey = std::string();
    }
    return out;
}

bool Editor::ai_settings_dirty(const ai::AiConfig& cfg) const {
    const AiSettingsDraft& d = aiSettings_;
    if (!d.keys.empty() && std::ranges::any_of(d.keys, [](const auto& kv) { return !kv.second.empty(); })) return true;
    if (!d.removeKey.empty()) return true;
    if (d.sources.onlyListed != cfg.assetSources.onlyListed) return true;
    for (ai::SiteCategory c : ai::kSiteCategories) {
        if (!same_sites(d.sources.list(c), cfg.assetSources.list(c))) return true;
    }
    for (ai::MediaKind k : ai::kMediaKinds) {
        const std::string name = ai::media_kind_name(k);
        const auto now = d.routes.find(name);
        const auto was = cfg.assets.find(name);
        const ai::AssetRoute a = now == d.routes.end() ? ai::AssetRoute{} : now->second;
        const ai::AssetRoute b = was == cfg.assets.end() ? ai::AssetRoute{} : was->second;
        if (a.provider != b.provider || a.model != b.model || a.voice != b.voice) return true;
        if (a.provider.empty()) continue;
        const ai::ProviderConfig p = provider_of(cfg, a.provider);
        if (p.kind != ai::ProviderKind::AssetCommand) continue;
        if (trim(d.command.count(a.provider) ? d.command.at(a.provider) : std::string()) != p.command) return true;
        if (ai::split_args(d.args.count(a.provider) ? d.args.at(a.provider) : std::string()) != p.argv) return true;
    }
    return false;
}

void Editor::draw_ai_settings_window() {
    if (!showAiSettings_) return;
    AiSettingsDraft& d = aiSettings_;
    ai::AiConfig cfg;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_;
    }
    const bool detected = aiDetected_.load();
    if (detected && !d.loaded) ai_settings_load(cfg);

    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(fit_work_area(ImVec2(940, 720)), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f), ImGuiCond_Appearing,
                            ImVec2(0.5f, 0.5f));
    if (aiSettingsFocus_) {
        ImGui::SetNextWindowFocus();
        aiSettingsFocus_ = false;
    }
    bool open = true;
    const bool visible = ImGui::Begin("AI settings###AiSettings", &open, ImGuiWindowFlags_NoDocking);
    if (!open) {
        showAiSettings_ = false;
        d = AiSettingsDraft{};  // a typed key does not outlive the window
    }
    if (!visible || !open) {
        ImGui::End();
        return;
    }
    ImGui::PushTextWrapPos(0);
    if (!d.loaded) {
        ImGui::TextDisabled(aiDetecting_.load() ? "Reading ai.json..." : "Reading ai.json (press Re-detect in the AI Assistant if this stays).");
        ImGui::PopTextWrapPos();
        ImGui::End();
        return;
    }
    const std::string cfgErr = [&] {
        std::lock_guard<std::mutex> lock(aiMu_);
        return aiConfigError_;
    }();
    const auto status_of = [&](const std::string& name) -> const ai::ProviderStatus* {
        const auto it = std::ranges::find(d.status, name, &ai::ProviderStatus::name);
        return it == d.status.end() ? nullptr : &*it;
    };

    if (!cfgErr.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("ai.json could not be read: %s", cfgErr.c_str());
        ImGui::PopStyleColor();
        ImGui::TextWrapped("Fix the file first (or delete it); saving here would not be able to keep what is in it.");
    }

    if (!ImGui::BeginTabBar("##aisettingstabs")) {
        ImGui::PopTextWrapPos();
        ImGui::End();
        return;
    }
    const int wantTab = aiSettingsTab_;
    aiSettingsTab_ = 0;
    // ------------------------------------------------------------------------------------------------ Roles
    const bool rolesShown = ImGui::BeginTabItem("Roles", nullptr, wantTab == 1 ? ImGuiTabItemFlags_SetSelected : ImGuiTabItemFlags_None);
    at_track("aiset:tab:roles");
    ImGui::SetItemTooltip("Which provider and model plays each role (orchestrator, worker, artist, critics...). Takes effect with the next message.");
    if (rolesShown) {
        std::vector<ai::ProviderStatus> liveStatus;  // the panel's, refreshed by Re-detect (d.status is a snapshot)
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            liveStatus = aiStatus_;
        }
        draw_ai_roles_tab(cfg, liveStatus);
        ImGui::EndTabItem();
    }
    const bool assetsShown = ImGui::BeginTabItem("Assets", nullptr, wantTab == 2 ? ImGuiTabItemFlags_SetSelected : ImGuiTabItemFlags_None);
    at_track("aiset:tab:assets");
    ImGui::SetItemTooltip("Where the AI's images, sounds and 3D models are made (provider, model, API key) and the websites it looks at for assets.");
    if (!assetsShown) {
        ImGui::EndTabBar();
        ImGui::PopTextWrapPos();
        ImGui::End();
        return;
    }
    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("Saved in %s, your own file outside any project. Only the asset parts are rewritten: your providers, roles and limits stay.",
                       d.path.c_str());
    ImGui::PopStyleColor();

    const float footerH = ImGui::GetFrameHeight() + ImGui::GetStyle().ItemSpacing.y * 3.0f + ImGui::GetTextLineHeightWithSpacing() * 2.0f;
    ImGui::BeginChild("##aisettingsbody", ImVec2(0, -footerH));

    // ------------------------------------------------------------------------------------------------ Asset generation
    ImGui::SeparatorText("Asset generation");
    ImGui::TextDisabled("Which service makes each kind of asset the AI asks for. With None, the AI makes it procedurally\n"
                        "(generated textures, SVG, synthesised sound) and tells you so.");
    std::set<std::string> usedProviders;  // the providers some route names: their key / program rows follow the table
    if (ImGui::BeginTable("##assetroutes", 5, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings)) {
        const float em = ImGui::GetFontSize();
        ImGui::TableSetupColumn("Kind", ImGuiTableColumnFlags_WidthFixed, em * 5.5f);
        ImGui::TableSetupColumn("Provider", ImGuiTableColumnFlags_WidthFixed, em * 14.0f);
        ImGui::TableSetupColumn("Model", ImGuiTableColumnFlags_WidthFixed, em * 13.0f);
        ImGui::TableSetupColumn("Voice", ImGuiTableColumnFlags_WidthFixed, em * 11.0f);
        ImGui::TableSetupColumn("Status", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableHeadersRow();
        for (ai::MediaKind kind : ai::kMediaKinds) {
            const std::string kname = ai::media_kind_name(kind);
            ai::AssetRoute& route = d.routes[kname];
            ImGui::PushID(kname.c_str());
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted(kind_title(kind));
            ImGui::TableNextColumn();
            ImGui::SetNextItemWidth(-FLT_MIN);
            if (ImGui::BeginCombo("##provider", route.provider.empty() ? kNoneLabel : route.provider.c_str())) {
                if (ImGui::Selectable(kNoneLabel, route.provider.empty()) && !route.provider.empty()) route = {};
                std::vector<std::string> names;
                for (const auto& [name, p] : cfg.providers) {
                    if (ai::provider_makes(p.kind, kind)) names.push_back(name);
                }
                const bool hasCommand = std::ranges::any_of(cfg.providers, [](const auto& kv) { return kv.second.kind == ai::ProviderKind::AssetCommand; });
                if (!hasCommand) names.push_back(kAssetCommand);
                for (const std::string& name : names) {
                    const ai::ProviderStatus* st = status_of(name);
                    const std::string label = name + (st && !st->available ? "  (not set up)" : "");
                    if (ImGui::Selectable(label.c_str(), route.provider == name) && route.provider != name) {
                        route = {name, "", ""};  // another provider: its default model, no voice of the old one
                    }
                    if (ImGui::IsItemHovered()) {
                        if (st) ImGui::SetTooltip("%s%s%s", st->detail.c_str(), st->available ? "" : "\n", st->available ? "" : st->hint.c_str());
                        else ImGui::SetTooltip("A program of yours makes the file (ComfyUI, Stable Diffusion, a Blender script...). Set it below.");
                    }
                }
                ImGui::EndCombo();
            }
            at_track("aiset:provider:" + kname);
            ImGui::SetItemTooltip("Who makes %s assets. Only providers that can make this kind are listed.", kind_title(kind));
            ImGui::TableNextColumn();
            const bool none = route.provider.empty();
            if (!none) usedProviders.insert(route.provider);
            const ai::ProviderConfig prov = none ? ai::ProviderConfig{} : provider_of(cfg, route.provider);
            ImGui::BeginDisabled(none);
            ImGui::SetNextItemWidth(-FLT_MIN);
            const std::string defModel = none ? std::string() : ai::asset_default_model(prov, kind);
            ImGui::InputTextWithHint("##model", none ? "" : defModel.empty() ? "provider default" : defModel.c_str(), &route.model);
            ImGui::EndDisabled();
            at_track("aiset:model:" + kname);
            ImGui::SetItemTooltip("The model to use. Empty = the provider's default%s.", defModel.empty() ? "" : (" (" + defModel + ")").c_str());
            ImGui::TableNextColumn();
            if (kind == ai::MediaKind::Voice) {
                ImGui::BeginDisabled(none);
                ImGui::SetNextItemWidth(-FLT_MIN);
                ImGui::InputTextWithHint("##voice", prov.kind == ai::ProviderKind::ElevenLabs ? "voice id" : "alloy", &route.voice);
                ImGui::EndDisabled();
                at_track("aiset:voice");
                ImGui::SetItemTooltip("The voice. ElevenLabs needs a voice id from your voice library on elevenlabs.io.\n"
                                      "OpenAI uses a voice name (alloy, nova, ...), alloy when empty.");
            }
            ImGui::TableNextColumn();
            ImGui::AlignTextToFramePadding();
            if (none) {
                ImGui::TextDisabled("Made procedurally");
            } else {
                const ai::ProviderStatus* st = status_of(route.provider);
                const bool typed = d.keys.contains(route.provider) && !d.keys.at(route.provider).empty();
                if (prov.kind == ai::ProviderKind::AssetCommand) {
                    const std::string program = std::string(trim(d.command.count(route.provider) ? d.command.at(route.provider) : std::string()));
                    ImGui::TextColored(text_color(!program.empty()), "%s", program.empty() ? "Set the program below" : ("Runs " + program).c_str());
                } else if (typed) {
                    ImGui::TextColored(kStatusWarn, "Key typed: Save stores it");
                } else if (st && st->available) {
                    ImGui::TextColored(kStatusReady, "Ready%s", st->keySource.empty() ? "" : (" (" + st->keySource + ")").c_str());
                    ImGui::SetItemTooltip("%s", st->detail.c_str());
                } else if (st) {
                    ImGui::TextColored(kStatusWarn, "%s", st->detail.c_str());
                    if (ImGui::IsItemHovered() && !st->hint.empty()) ImGui::SetTooltip("%s", st->hint.c_str());
                }
            }
            ImGui::PopID();
        }
        ImGui::EndTable();
    }

    // The keys of the providers in use.
    bool anyKeyRow = false;
    for (const std::string& name : usedProviders) {
        const ai::ProviderConfig prov = provider_of(cfg, name);
        if (!needs_key(prov.kind)) continue;
        if (!anyKeyRow) {
            ImGui::Spacing();
            ImGui::SeparatorText("API keys");
            ImGui::TextDisabled("An environment variable is the safest place for a key. If you cannot set one, paste it here.");
            anyKeyRow = true;
        }
        ImGui::PushID(name.c_str());
        const ai::ProviderStatus* st = status_of(name);
        const std::string env = ai::default_key_env(prov);
        const bool stored = !prov.apiKey.empty() && !d.removeKey.contains(name);
        ImGui::AlignTextToFramePadding();
        ImGui::Text("%s", name.c_str());
        ImGui::SameLine(ImGui::GetFontSize() * 8.0f);
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 22.0f);
        std::string& typed = d.keys[name];
        ImGui::InputTextWithHint("##key", stored ? "a key is stored (paste a new one to replace it)" : "paste an API key", &typed,
                                 ImGuiInputTextFlags_Password);
        at_track("aiset:key:" + name);
        ImGui::SetItemTooltip("Stored as providers.%s.apiKey in %s: your own file outside any project, not shared with the games\n"
                              "you make. FactorIA never writes it into a project, a log or a command result and the file is made\n"
                              "readable only by you. It is used before the environment variable%s.",
                              name.c_str(), d.path.c_str(), env.empty() ? "" : (" " + env).c_str());
        ImGui::SameLine();
        if (stored) {
            if (ImGui::SmallButton("Remove stored key")) {
                d.removeKey.insert(name);
                typed.clear();
            }
            at_track("aiset:key-remove:" + name);
            ImGui::SetItemTooltip("Delete the key from ai.json on Save. The environment variable, if set, is used again.");
            ImGui::SameLine();
        } else if (d.removeKey.contains(name)) {
            if (ImGui::SmallButton("Keep stored key")) d.removeKey.erase(name);
            ImGui::SameLine();
        }
        const std::string source = st ? st->keySource : std::string();
        if (!typed.empty()) ImGui::TextColored(kStatusWarn, "Save stores this key");
        else if (d.removeKey.contains(name)) ImGui::TextColored(kStatusWarn, "Save removes the stored key");
        else if (source == "config") ImGui::TextColored(kStatusReady, "Key stored in ai.json");
        else if (source.rfind("env:", 0) == 0) ImGui::TextColored(kStatusReady, "Key found in %s", source.c_str() + 4);
        else ImGui::TextColored(kStatusWarn, "No key%s", env.empty() ? "" : (": set " + env + " or paste one").c_str());
        ImGui::PopID();
    }

    // The program of an asset-command route.
    for (const std::string& name : usedProviders) {
        if (provider_of(cfg, name).kind != ai::ProviderKind::AssetCommand) continue;
        ImGui::Spacing();
        ImGui::SeparatorText(("Your own program (" + name + ")").c_str());
        ImGui::PushID(name.c_str());
        ImGui::TextDisabled("A command that writes the file. In the arguments, {prompt} is the prompt and {output} the file to write\n"
                            "(also {width} {height} {seconds} {kind} {model} {seed}). docs/AI_PROVIDERS.md, \"asset-command\".");
        std::string& program = d.command[name];
        std::string& args = d.args[name];
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Program");
        ImGui::SameLine(ImGui::GetFontSize() * 8.0f);
        ImGui::SetNextItemWidth(-FLT_MIN);
        ImGui::InputTextWithHint("##program", "python", &program);
        at_track("aiset:program");
        ImGui::SetItemTooltip("The program to run: a name on the PATH or a full path. Leave out the arguments.");
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Arguments");
        ImGui::SameLine(ImGui::GetFontSize() * 8.0f);
        ImGui::SetNextItemWidth(-FLT_MIN);
        ImGui::InputTextWithHint("##args", "/path/txt2img.py --prompt {prompt} --out {output}", &args);
        at_track("aiset:args");
        ImGui::SetItemTooltip("Separated by spaces; put \"double quotes\" around one that has spaces.\nThe program must write the result to {output}.");
        ImGui::PopID();
    }

    // ------------------------------------------------------------------------------------------------ Asset sources
    ImGui::Spacing();
    ImGui::SeparatorText("Asset sources");
    ImGui::TextWrapped("Websites the AI should look at when it searches for images, models, sounds or fonts. It takes them from these pages "
                       "and writes down each asset's source and license.");
    ImGui::Checkbox("Use only these sites", &d.sources.onlyListed);
    at_track("aiset:only-listed");
    ImGui::SetItemTooltip("On: the AI searches and fetches ONLY the listed sites, never the open internet. Claude Code is held to it\n"
                          "(WebFetch of other sites is denied and WebSearch is off); for the other providers it is an instruction.\n"
                          "Off: it looks at the listed sites first and may search the internet too, as it does without a list.");
    if (d.sources.empty()) {
        ImGui::TextDisabled("No site yet: the AI searches the internet as it wishes.");
    } else if (d.sources.onlyListed) {
        ImGui::TextDisabled("Only the sites below are used for assets.");
    } else {
        ImGui::TextDisabled("The sites below come first; the AI may search the internet as well.");
    }
    for (ai::SiteCategory c : ai::kSiteCategories) {
        std::vector<ai::AssetSite>& sites = d.sources.list(c);
        const std::string title = std::string(ai::site_category_title(c)) + (sites.empty() ? "" : "  (" + std::to_string(sites.size()) + ")");
        ImGui::PushID(ai::site_category_key(c));
        if (ImGui::CollapsingHeader((title + "###cat").c_str(), sites.empty() ? 0 : ImGuiTreeNodeFlags_DefaultOpen)) {
            int remove = -1;
            for (std::size_t i = 0; i < sites.size(); ++i) {
                ImGui::PushID(static_cast<int>(i));
                const bool valid = !ai::asset_site_host(sites[i].url).empty();
                ImGui::SetNextItemWidth(ImGui::GetFontSize() * 20.0f);
                if (!valid) ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
                ImGui::InputTextWithHint("##url", "opengameart.org", &sites[i].url);
                if (!valid) ImGui::PopStyleColor();
                at_track("aiset:url:" + std::string(ai::site_category_key(c)) + ":" + std::to_string(i));
                if (!valid) ImGui::SetItemTooltip("Not a web address. Write a domain (opengameart.org) or an address (https://kenney.nl/assets).");
                ImGui::SameLine();
                ImGui::SetNextItemWidth(ImGui::GetFontSize() * 16.0f);
                ImGui::InputTextWithHint("##note", "note (optional)", &sites[i].note);
                ImGui::SetItemTooltip("What the site is good for or its license, e.g. CC0 packs. The AI reads it.");
                ImGui::SameLine();
                if (ImGui::SmallButton("Remove")) remove = static_cast<int>(i);
                at_track("aiset:remove:" + std::string(ai::site_category_key(c)) + ":" + std::to_string(i));
                ImGui::PopID();
            }
            if (remove >= 0) sites.erase(sites.begin() + remove);
            std::string& newUrl = d.newUrl[static_cast<int>(c)];
            std::string& newNote = d.newNote[static_cast<int>(c)];
            ImGui::SetNextItemWidth(ImGui::GetFontSize() * 20.0f);
            const bool enter = ImGui::InputTextWithHint("##newurl", "add a site: opengameart.org", &newUrl, ImGuiInputTextFlags_EnterReturnsTrue);
            at_track("aiset:newurl:" + std::string(ai::site_category_key(c)));
            ImGui::SameLine();
            ImGui::SetNextItemWidth(ImGui::GetFontSize() * 16.0f);
            ImGui::InputTextWithHint("##newnote", "note (optional)", &newNote);
            ImGui::SameLine();
            const bool add = ImGui::SmallButton("Add") || enter;
            at_track("aiset:add:" + std::string(ai::site_category_key(c)));
            if (add && !trim(newUrl).empty()) {
                if (ai::asset_site_host(newUrl).empty()) {
                    d.siteError = "'" + std::string(trim(newUrl)) + "' is not a web address. Write a domain such as opengameart.org, or an address "
                                  "such as https://kenney.nl/assets.";
                } else {
                    sites.push_back({std::string(trim(newUrl)), std::string(trim(newNote))});
                    newUrl.clear();
                    newNote.clear();
                    d.siteError.clear();
                }
            }
        }
        ImGui::PopID();
    }
    if (!d.siteError.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("%s", d.siteError.c_str());
        ImGui::PopStyleColor();
    }
    ImGui::EndChild();

    // ------------------------------------------------------------------------------------------------ footer
    const bool dirty = ai_settings_dirty(cfg);
    if (!d.saveError.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("%s", d.saveError.c_str());
        ImGui::PopStyleColor();
    } else if (dirty) {
        ImGui::TextColored(kStatusWarn, "Unsaved changes");
    } else {
        ImGui::TextDisabled("Saved. The next asset the AI makes uses these settings.");
    }
    ImGui::BeginDisabled(!cfgErr.empty());
    if (ImGui::Button("Save")) {
        d.saveError.clear();
        auto built = ai_settings_build(cfg);
        if (!built) {
            d.saveError = built.error().to_string();
        } else if (auto saved = ai::save_asset_settings(*built, d.path); !saved) {
            d.saveError = saved.error().to_string();
        } else {
            auto loaded = ai::load_config(d.path);
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                if (loaded) aiConfig_ = *loaded;
                aiConfigError_ = loaded ? std::string() : loaded.error().to_string();
            }
            if (loaded) {
                ai_settings_load(*loaded);  // also forgets the typed keys
                notify("AI settings saved. The next asset the AI makes uses them.");
            } else {
                d.saveError = "Saved, but ai.json no longer loads: " + loaded.error().to_string();
            }
            if (!aiDetecting_.load()) ai_refresh_providers();  // the Roles window and the panel see the new providers too
        }
    }
    ImGui::EndDisabled();
    at_track("aiset:save", cfgErr.empty());
    ImGui::SameLine();
    if (ImGui::Button("Close")) {
        showAiSettings_ = false;
        d = AiSettingsDraft{};
    }
    at_track("aiset:close");
    ImGui::EndTabItem();
    ImGui::EndTabBar();
    ImGui::PopTextWrapPos();
    ImGui::End();
}

}  // namespace fa::editor
