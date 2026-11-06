// The Image panel's "Inpaint selection..." and "Generate layer...": the same work as the commands image.inpaint and image.generate_layer
// (tools/ai/src/image_provider_commands.cpp), split so the editor never waits for the provider:
//   1. plan_image_edit   (main thread) reads the document, the selection and the configuration, resolves the provider;
//   2. run_image_edit    (a worker thread) makes the call;
//   3. store_image_edit + ImageModel::add_provider_layer (main thread) write the picture and add the layer as ONE undo step.
// The picture is never added to another document than the one it was asked for.

#include <algorithm>
#include <format>

#include "editor_internal.h"
#include "fa/ai/assets.h"
#include "image_ui.h"

namespace fa::editor {

namespace {

constexpr const char* kOfflineRoute =
    "Offline and free: assets.generate_texture, assets.rasterize_svg, or a svg / gradient / procedural layer (image.layer.add, docs IMAGES).";

}  // namespace

// Why the two actions are off, from the configuration: asked a few times a second at most.
void Editor::image_provider_refresh() {
    ImageUi& u = image_;
    if (u.providerChecked != ~std::uint64_t(0) && uiFrame_ - u.providerChecked < 30) return;
    u.providerChecked = uiFrame_;
    // The project's AI settings may route images to another provider.
    ai::AiConfig cfg;
    if (auto resolved = ai_project_config()) {
        cfg = std::move(*resolved);
    } else {  // an invalid project file: the runs report it; the panel shows the editor's own routes meanwhile
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_.providers.empty() ? ai::default_config() : aiConfig_;
    }
    u.noGenerate.clear();
    u.noInpaint.clear();
    auto target = ai::resolve_asset_target(cfg, ai::MediaKind::Image);
    if (!target) {
        u.noGenerate = "No image provider is configured. Add one in AI Settings (ai.json, docs/AI_PROVIDERS.md, \"Asset providers\"). ";
        u.noGenerate += kOfflineRoute;
        u.noInpaint = u.noGenerate;
        return;
    }
    if (!ai::asset_can_inpaint(*target->provider))
        u.noInpaint = "The image provider '" + target->provider->name +
                      "' cannot repaint part of a picture. Use the openai provider, or an asset-command whose argv has {input} and {mask} "
                      "(docs/AI_PROVIDERS.md). " + kOfflineRoute;
}

namespace {

// The price of a call as one sentence for the popup. The money is only ever an estimate from the provider's price list.
std::string estimate_sentence(const ai::AssetEstimate& e, const std::string& provider) {
    if (e.free) return "Free: " + e.basis;
    if (!e.usd) return "The price is not known" + (e.basis.empty() ? std::string() : " (" + e.basis + ")") + ". Set it in AI Settings or ai.json (assetPricing).";
    return "About " + ai::format_usd(*e.usd) + " with " + provider + " (" + e.basis + "), an estimate from the provider's price list" +
           (e.checked.empty() ? std::string() : " checked " + e.checked) + ", not an invoice.";
}

}  // namespace

// What "Make it" would cost, shown in the popup before the user clicks. Made when the popup opens, not every frame.
void Editor::image_provider_estimate(ImageModel& m) {
    ImageUi& u = image_;
    u.providerEstimate.clear();
    Json args = Json::object({{"prompt", "estimate"}});
    if (m.has_selection()) args["selection"] = ImageModel::kSelectionName;
    if (m.animated() || m.frame_count() > 1) args["frame"] = m.frame();
    args["path"] = m.path();
    ai::ImageEditEnv env;
    env.projectDir = projectDir_;
    env.load = [this]() -> Result<ai::AiConfig> { return ai_project_config(true); };
    try {
        const ai::ImageEditPlan plan = ai::plan_image_edit(env, u.providerInpaint, args);
        u.providerEstimate = estimate_sentence(plan.cost, plan.provider.name);
        if (!plan.cost.free) u.providerEstimate += " Limits: AI Settings > Spending limits.";
    } catch (const CommandError&) {
        // the real request reports what is wrong
    }
}

// Starts the request: everything that can be wrong with it is found here, before a thread starts.
void Editor::image_provider_start(ImageModel& m) {
    ImageUi& u = image_;
    u.providerError.clear();
    const bool inpaint = u.providerInpaint;
    Json args = Json::object({{"prompt", u.providerPrompt}});
    if (m.has_selection()) args["selection"] = ImageModel::kSelectionName;
    if (m.animated() || m.frame_count() > 1) args["frame"] = m.frame();
    args["path"] = m.path();
    ai::ImageEditEnv env;
    env.projectDir = projectDir_;
    env.load = [this]() -> Result<ai::AiConfig> { return ai_project_config(true); };
    auto job = std::make_unique<ImageProviderJob>();
    try {
        job->plan = ai::plan_image_edit(env, inpaint, args);
    } catch (const CommandError& e) {
        u.providerError = std::string(e.what()) + (e.hint.empty() ? std::string() : "\n" + e.hint);
        return;
    }
    job->inpaint = inpaint;
    job->doc = m.path();
    job->shared = std::make_shared<ImageProviderShared>();
    job->startedAt = ImGui::GetTime();
    // "Make it" in a popup that showed the estimate is the user's yes (no second question); the limits still hold. The cost check takes
    // the cross-process lock of the day total, so it runs here and not on the UI thread.
    job->thread = std::thread([shared = job->shared, plan = job->plan, env] {
        try {
            ai::AssetCostGuard guard = ai::begin_image_edit_cost(plan, env, true, &shared->cancel);
            if (!guard.go()) {
                shared->result.emplace(make_error("The call needs your approval and was not made.", "Click Make it again."));
            } else {
                auto made = ai::run_image_edit(plan, ai::ProviderRuntime{}, &shared->cancel);
                if (made) guard.commit();
                shared->warnings = guard.warnings();
                shared->spentUsd = made && plan.cost.usd ? *plan.cost.usd : 0.0;
                shared->result.emplace(std::move(made));
            }
        } catch (const CommandError& e) {
            shared->result.emplace(make_error(e.what(), e.hint));
        }
        shared->done = true;
    });
    u.job = std::move(job);
    u.providerAsk = false;
}

// The answer of the worker: stored and added when the document it was asked for is still the open one.
void Editor::image_provider_poll(ImageModel& m) {
    ImageUi& u = image_;
    ImageProviderJob* job = u.job.get();
    if (!job || !job->shared->done.load() || play_ != PlayState::Edit) return;
    if (job->thread.joinable()) job->thread.join();
    std::unique_ptr<ImageProviderJob> own = std::move(u.job);
    const std::string what = own->inpaint ? "Inpaint" : "Generated layer";
    if (!own->shared->result->ok()) {
        const Error& e = own->shared->result->error();
        u.providerError = what + " failed: " + e.message + (e.hint.empty() ? std::string() : "\n" + e.hint);
        notify(what + " failed: " + e.message, 2);
        return;
    }
    if (!m.is_open() || m.path() != own->doc) {
        notify(what + " for " + own->doc + " arrived, but " + (m.is_open() ? m.path() : std::string("no image")) +
                   " is open now: nothing was added. Open " + own->doc + " and ask again.", 1);
        return;
    }
    ai::ImageEditEnv env;
    env.projectDir = projectDir_;
    try {
        ai::ImageEditStored stored = ai::store_image_edit(env, own->plan, **own->shared->result);
        const ImageEditOutcome out = m.add_provider_layer(what + " (" + own->plan.layerName + ")", std::move(stored.addArgs));
        image_edited(out);
        if (out.ok) {
            std::string msg = "Added the provider layer '" + own->plan.layerName + "'.";
            for (const std::string& w : stored.warnings) msg += " " + w;
            for (const std::string& w : own->shared->warnings) msg += " " + w;
            if (own->shared->spentUsd > 0) msg += " About " + ai::format_usd(own->shared->spentUsd) + " (an estimate).";
            m.set_status(msg);
            project_files_changed();
        }
    } catch (const CommandError& e) {
        u.providerError = std::string(e.what()) + (e.hint.empty() ? std::string() : "\n" + e.hint);
        notify(std::string(e.what()), 2);
    }
}

// The two buttons, the prompt popup and the progress line. Called under the layer list's Add row.
void Editor::draw_image_provider(ImageModel& m) {
    ImageUi& u = image_;
    image_provider_refresh();
    image_provider_poll(m);
    const bool editable = play_ == PlayState::Edit;
    const bool busy = u.job != nullptr;
    auto action = [&](const char* label, const char* id, bool inpaint, const std::string& problem, bool needSelection) {
        std::string why = problem;
        if (why.empty() && needSelection && !m.has_selection())
            why = "Select the part to repaint first (the Rect, Ellipse, Polygon or Wand tool): the picture is made for the selection and masked by it.";
        if (why.empty() && busy) why = "A picture is being made; wait for it or cancel it.";
        ImGui::BeginDisabled(!editable || !why.empty());
        if (ImGui::SmallButton(label)) {
            u.providerInpaint = inpaint;
            u.providerAsk = true;
            u.providerError.clear();
            image_provider_estimate(m);
        }
        at_track(id);
        ImGui::EndDisabled();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            ImGui::SetTooltip("%s", why.empty() ? (inpaint ? "Repaint the selection with the image provider (image.inpaint). The result is a new provider layer masked by the selection."
                                                           : "Add a picture made by the image provider as a new layer (image.generate_layer), masked by the selection if there is one.")
                                                 : why.c_str());
    };
    action("Inpaint selection...", "img:provider:inpaint", true, u.noInpaint, true);
    ImGui::SameLine();
    action("Generate layer...", "img:provider:generate", false, u.noGenerate, false);

    if (u.providerAsk) {
        ImGui::OpenPopup("##imgprovider");
        u.providerAsk = false;
    }
    ImGui::SetNextWindowSize(ImVec2(420, 0), ImGuiCond_Appearing);
    if (ImGui::BeginPopupModal("##imgprovider", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::TextUnformatted(u.providerInpaint ? "Inpaint the selection (image.inpaint)" : "Generate a layer (image.generate_layer)");
        ImGui::TextWrapped("%s", u.providerInpaint
                                     ? "The picture and the selection go to the provider; what comes back is a new provider layer masked by the selection."
                                     : "The provider makes a picture; it becomes a new provider layer (masked by the selection, if there is one).");
        if (!u.providerEstimate.empty()) {
            ImGui::TextWrapped("%s", u.providerEstimate.c_str());
            at_track("img:provider:estimate");
        }
        if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
        ImGui::InputTextMultiline("##prompt", &u.providerPrompt, ImVec2(400, 70));
        at_track("img:provider:prompt");
        if (!u.providerError.empty()) ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "%s", u.providerError.c_str());
        const bool ready = !u.providerPrompt.empty() && !busy;
        ImGui::BeginDisabled(!ready);
        if (ImGui::Button("Make it")) {
            image_provider_start(m);
            if (u.providerError.empty()) ImGui::CloseCurrentPopup();
        }
        at_track("img:provider:go");
        ImGui::SetItemTooltip("Make the picture. When the estimate above is not free, this click is your approval of that cost.");
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::Button("Close")) ImGui::CloseCurrentPopup();
        ImGui::EndPopup();
    }
    if (u.job) {
        ImGui::TextDisabled("%s", std::format("{} for '{}' ({} s)...", u.job->inpaint ? "Inpainting" : "Generating",
                                              u.job->plan.layerName, int(ImGui::GetTime() - u.job->startedAt)).c_str());
        ImGui::SameLine();
        if (ImGui::SmallButton("Cancel")) u.job->shared->cancel = true;
        at_track("img:provider:cancel");
    } else if (!u.providerError.empty() && !ImGui::IsPopupOpen("##imgprovider")) {
        ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1), "%s", u.providerError.c_str());
        ImGui::SameLine();
        if (ImGui::SmallButton("Dismiss")) u.providerError.clear();
    }
}

}  // namespace fa::editor
