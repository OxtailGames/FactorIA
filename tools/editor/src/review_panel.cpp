// Review window (View > Review; docs/EDITOR.md "Review window"): the sheets review.sheet made (.factoria/review/), one shown big with
// its numbered thumbnails, picked with the keyboard (1-9, arrows, Enter) or the mouse; Compare two numbers side by side; the History of
// past picks. The reader thread (review_loader.h) lists the sheets, reads manifests and decodes pictures; the UI thread uploads at most
// one picture a frame and frees the textures it stopped drawing. A pick is the command itself (review.pick, or assets.pick for a sheet
// of asset candidates) through the engine's registry, exactly what the AI or the Console would call. The Level generator's "Sheet of
// N seeds" runs review.sheet in a child process (child_command_job.h) and opens its sheet here; picking one brings the seed back.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <format>

#include "editor_internal.h"
#include "fa/tooling/review.h"
#include "ui_backend.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

constexpr std::uint64_t kUnusedFrames = 120;     // a picture not drawn for this many frames is freed
constexpr double kSeedsTimeoutSeconds = 1800;    // a safety net: N levels at the default work cap take seconds
constexpr double kPickTimeoutSeconds = 300;      // a safety net: a pick moves a few files (about a second of retries each on Windows)

// A tooltip for the widget just drawn that also shows while it is disabled (where the reason it is disabled belongs).
void tooltip_even_when_disabled(const char* text) {
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_ForTooltip)) ImGui::SetTooltip("%s", text);
}

// A string member of untrusted JSON (a command result, a manifest): "" when it is missing or not a string (Json::value would throw).
std::string json_text(const Json& j, const char* key) {
    if (!j.is_object()) return {};
    const auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// A project-relative path from a manifest, or "" when it would leave its folder (a hand-edited manifest is not trusted).
std::string safe_rel(const std::string& rel) {
    if (rel.empty() || fs::is_absolute(rel)) return {};
    return fs::normalize(rel);
}

// Smooth when the picture is drawn smaller than it is, sharp pixels when it is blown up (pixel art stays crisp).
ImTextureRef tex_ref(const TextureEntry& t, float scale) { return ImTextureRef(ImTextureID(ui::texture_from_view(t.view, scale < 1.0f))); }

}  // namespace

// ----------------------------------------------------------------------------------------------------------------- state --
void Editor::open_review(const std::string& sheet, bool focus) {
    review_.show = true;
    if (focus) review_.focus = true;
    review_.listDirty = true;
    if (!sheet.empty()) {
        review_show_sheet(sheet);
        review_.tabSet = 0;
    }
}

void Editor::review_show_sheet(const std::string& id) {
    if (id == review_.sheetId && (review_.sheet || review_.sheetLoading)) return;
    review_release_textures();   // the pictures of the sheet shown before are not kept
    review_.sheetId = id;
    review_.sheet.reset();
    review_.sheetError.clear();
    review_.selected = 0;
    review_.zoom = 0;
    review_.compareA = 1;
    review_.compareB = 2;
    review_.pickMessage.clear();
    review_.pickLines.clear();
    review_.pickBad = false;
    ++review_.sheetGen;
    reviewLoader_.drop_pictures();
    review_.uploads.clear();
    if (id.empty() || projectDir_.empty()) return;
    review_.sheetLoading = true;
    reviewLoader_.request_sheet(projectDir_, id, review_.sheetGen);
}

void Editor::review_release_textures() {
    for (auto& [key, slot] : review_.textures) {
        (void)key;
        if (slot.tex.image || slot.tex.view) reviewGraveyard_.push_back({slot.tex.image, slot.tex.view, uiFrame_});
    }
    review_.textures.clear();
}

void Editor::reset_review_state() {
    reviewSeedsJob_.cancel();   // the child is killed: a sheet it did not finish is never listed (review.sheet writes its manifest last)
    reviewSeedsJob_.wait();
    (void)reviewSeedsJob_.take_result();
    // A pick is not killed: its files are moved and its manifest written together. It finishes (a second or so) and its result is
    // dropped with the rest of this project's window state.
    reviewPickJob_.wait();
    (void)reviewPickJob_.take_result();
    reviewLoader_.stop();       // joins the reader; what it had read is dropped
    review_release_textures();
    for (const ReviewDeadTexture& d : reviewGraveyard_) ui::destroy_texture(d.image, d.view);
    reviewGraveyard_.clear();
    const std::uint64_t gen = review_.gen + 1, sheetGen = review_.sheetGen + 1;
    const int seeds = review_.seedsCount;
    review_ = ReviewUi{};
    review_.gen = gen;
    review_.sheetGen = sheetGen;
    review_.seedsCount = seeds;
}

const ReviewTextureSlot& Editor::review_texture(const std::string& key, const stdfs::path& file, int maxSide, bool projectFile) {
    auto [it, added] = review_.textures.try_emplace(key);
    ReviewTextureSlot& slot = it->second;
    slot.usedFrame = uiFrame_;
    if (added) reviewLoader_.request_picture(key, file, maxSide, projectFile, review_.sheetGen);
    return slot;
}

void Editor::review_announce_sheet(const std::string& sheet, const std::string& label, const std::string& who) {
    review_.listDirty = true;
    if (sheet.empty()) return;
    // A toast, not a window: the person may be typing elsewhere. The button opens the sheet in the Review window.
    const std::string text = who + " made the review sheet " + sheet + (label.empty() ? std::string() : " (\"" + label + "\")") +
                             ": look at it and pick a number.";
    notify_action(text, "Open in Review", [this, sheet] { open_review(sheet); }, "review:open-announced");
}

// ------------------------------------------------------------------------------------------------------------ every frame --
void Editor::poll_review() {
    // The Level generator's sheet of seeds.
    if (std::optional<ChildCommandOutcome> done = reviewSeedsJob_.take_result()) {
        if (done->cancelled) {
            levelGenMessage_ = "The sheet of seeds was cancelled; no sheet was made.";
            levelGenMessageBad_ = false;
        } else if (!done->ok) {
            levelGenMessage_ = "Could not make the sheet of seeds: " + done->error + (done->hint.empty() ? std::string() : " " + done->hint);
            levelGenMessageBad_ = true;
        } else {
            const auto s = done->value.find("sheet");
            const std::string id = s != done->value.end() && s->is_string() ? s->get<std::string>() : std::string();
            levelGenMessage_ = "Made " + id + ": pick the level you like in the Review window (1-9 or the arrows, then Enter); the Level generator then shows that seed.";
            levelGenMessageBad_ = false;
            if (!id.empty()) open_review(id);
        }
    }
    // A pick that finished in its child process.
    if (std::optional<ChildCommandOutcome> done = reviewPickJob_.take_result()) review_finish_pick(*done);
    // A command changed the sheet shown (the AI picked it, review.cleanup ran): read its manifest again.
    if (review_.sheetDirty && review_.show && !review_.sheetId.empty() && !review_.sheetLoading && !projectDir_.empty()) {
        review_.sheetDirty = false;
        review_.sheetLoading = true;
        reviewLoader_.request_sheet(projectDir_, review_.sheetId, review_.sheetGen);
    }
    // A pick that waited for the reader to close a candidate's file.
    if (review_.pickPending && !reviewLoader_.reading_project_file()) {
        review_.pickPending = false;
        review_do_pick();
    }
    // What the reader finished.
    for (ReviewLoaded& r : reviewLoader_.take()) {
        switch (r.kind) {
            case ReviewLoaded::Kind::List:
                if (r.gen != review_.gen) break;
                review_.listLoading = false;
                review_.listLoaded = true;
                review_.listError = r.error;
                review_.rows = std::move(r.rows);
                review_.history = std::move(r.history);
                if (review_.sheetId.empty() && !review_.rows.empty() && review_.show) review_show_sheet(review_.rows.front().id);
                break;
            case ReviewLoaded::Kind::Sheet: {
                if (r.gen != review_.sheetGen || r.sheet != review_.sheetId) break;
                review_.sheetLoading = false;
                if (!r.error.empty()) {
                    review_.sheetError = r.error;
                    review_.sheet.reset();
                    break;
                }
                review_.sheetError.clear();
                review_.sheet = review_sheet_view(r.manifest);
                const int count = int(review_.sheet->items.size());
                if (review_.selected < 1 || review_.selected > count)
                    review_.selected = review_.sheet->is_picked() ? review_.sheet->picked_n() : (count > 0 ? 1 : 0);
                review_.compareA = std::clamp(review_.compareA, 1, std::max(1, count));
                review_.compareB = std::clamp(review_.compareB, 1, std::max(1, count));
                break;
            }
            case ReviewLoaded::Kind::Picture:
                if (r.gen != review_.sheetGen) break;
                review_.uploads.push_back(std::move(r));
                break;
        }
    }
    // One upload a frame: a big sheet never stalls a frame with several textures at once.
    if (!review_.uploads.empty()) {
        ReviewLoaded up = std::move(review_.uploads.front());
        review_.uploads.pop_front();
        auto it = review_.textures.find(up.key);
        if (it != review_.textures.end() && !it->second.tex.view) {
            ReviewTextureSlot& slot = it->second;
            if (!up.error.empty() || up.picture.empty()) {
                slot.error = up.error.empty() ? std::string("the picture is empty") : up.error;
                slot.tex.failed = true;
            } else if (ui::make_texture(up.picture.width, up.picture.height, up.picture.rgba.data(), slot.tex.image, slot.tex.view)) {
                slot.tex.w = up.picture.width;
                slot.tex.h = up.picture.height;
            } else {
                slot.error = "the picture could not be uploaded to the GPU";
                slot.tex.failed = true;
            }
        }
    }
    // Pictures nobody drew for a while (the window is closed, another sheet, another pair in Compare) are freed...
    for (auto it = review_.textures.begin(); it != review_.textures.end();) {
        if (it->second.usedFrame + kUnusedFrames < uiFrame_) {
            if (it->second.tex.image || it->second.tex.view) reviewGraveyard_.push_back({it->second.tex.image, it->second.tex.view, uiFrame_});
            it = review_.textures.erase(it);
        } else {
            ++it;
        }
    }
    // ...a few frames later, once no frame in flight draws them.
    for (std::size_t i = 0; i < reviewGraveyard_.size();) {
        if (reviewGraveyard_[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(reviewGraveyard_[i].image, reviewGraveyard_[i].view);
            reviewGraveyard_.erase(reviewGraveyard_.begin() + std::ptrdiff_t(i));
        } else {
            ++i;
        }
    }
}

// ------------------------------------------------------------------------------------------------------------------ pick --
ReviewPickPlan Editor::review_plan_for(const ReviewSheetView& sheet, int n, bool drop, const std::string& note) const {
    ReviewPickPlan plan = review_pick_plan(sheet, n, drop, note);
    if (!plan.error.empty()) return plan;
    if (reviewPickJob_.running() || review_.pickPending)
        plan.error = "A pick is running: wait for it to finish.";
    else if (const std::string newest = review_superseded_by(review_.rows, sheet); !newest.empty())
        plan.error = "Superseded by " + newest + ", a newer sheet of candidates for " + sheet.slot +
                     ": only the newest one can be picked, so this one is read-only. Open " + newest + " to choose.";
    return plan;
}

void Editor::review_request_pick(int n) {
    if (!review_.sheet) return;
    const ReviewPickPlan plan = review_plan_for(*review_.sheet, n, true, std::string());
    if (!plan.error.empty()) {
        review_.pickMessage = plan.error;
        review_.pickBad = true;
        review_.pickLines.clear();
        return;
    }
    review_.confirmN = n;
    review_.keepFiles = false;
    review_.note.clear();
    review_.confirmRequest = true;
}

void Editor::review_do_pick() {
    if (!engine_ || !review_.sheet || reviewPickJob_.running()) return;
    const ReviewSheetView sheet = *review_.sheet;   // a copy: the window can show another sheet while the pick runs
    review_.pickPending = false;                     // (review_plan_for refuses while a pick waits)
    const ReviewPickPlan plan = review_plan_for(sheet, review_.confirmN, !review_.keepFiles, review_.note);
    review_.pickLines.clear();
    if (!plan.error.empty()) {
        review_.pickMessage = plan.error;
        review_.pickBad = true;
        return;
    }
    // A sheet of asset candidates is answered by assets.pick (it puts the picked file into the slot). Never review.pick instead: that
    // command refuses such a sheet, and would not fill the slot.
    if (!engine_->commands().info(plan.command)) {
        review_.pickMessage = "This sheet holds asset candidates for the slot " + sheet.slot + ", and picking one needs the command " + plan.command +
                              ", which this FactorIA does not have. Nothing was picked. Update FactorIA, or ask the AI that made the sheet to finish the choice.";
        review_.pickBad = true;
        notify(review_.pickMessage, 2);
        return;
    }
    // Windows cannot move a file another thread holds open: the reader lets go of a candidate's picture before the pick moves it.
    reviewLoader_.drop_pictures();
    if (reviewLoader_.reading_project_file()) {
        review_.pickPending = true;   // poll_review calls this again once the reader closed it
        return;
    }
    // In a child factoria, never on the UI thread: a pick reads manifests, moves files (retrying a busy one for about a second on
    // Windows) and writes the manifest (assets.pick also assets.json). It is the command itself, exactly what the AI would call.
    review_.pickSheet = sheet;
    review_.pickPlan = plan;
    review_.pickN = review_.confirmN;
    reviewPickJob_.start(stdfs::path(projectDir_), plan.command, plan.args, kPickTimeoutSeconds);
    review_.pickMessage = std::format("Picking #{} of {}...", review_.pickN, sheet.id);
    review_.pickBad = false;
}

void Editor::review_finish_pick(const ChildCommandOutcome& done) {
    if (!review_.pickSheet) return;   // the project changed while it ran
    const ReviewSheetView sheet = std::move(*review_.pickSheet);
    review_.pickSheet.reset();
    const ReviewPickPlan plan = std::move(review_.pickPlan);
    const int n = review_.pickN;
    review_.pickLines.clear();
    // The editor reacts as to any command (the Project panel reads the folder again, the window its sheets).
    CommandResult r;
    r.ok = done.ok;
    if (done.ok) r.result = done.value;
    else r.error = Json{{"code", done.code}, {"message", done.error}, {"hint", done.hint}};
    after_command(plan.command, plan.args, r);
    review_.listDirty = true;
    review_.sheetDirty = true;
    if (!done.ok) {
        if (done.code == "busy")
            review_.pickMessage = "Nothing was picked: a file of this sheet is open in another program, or another program is changing the "
                                  "review sheets right now. Close it and try again." + (done.error.empty() ? std::string() : " (" + done.error + ")");
        else if (done.code == "superseded")
            review_.pickMessage = "Nothing was picked: a newer sheet of candidates for " + sheet.slot + " replaced this one. " + done.error +
                                  (done.hint.empty() ? std::string() : " " + done.hint);
        else
            review_.pickMessage = "The pick failed: " + done.error + (done.hint.empty() ? std::string() : " " + done.hint);
        review_.pickBad = true;
        notify(review_.pickMessage, 2);
        return;
    }
    const Json& res = done.value;
    int moved = 0;
    if (const auto d = res.find("dropped"); d != res.end() && d->is_array())
        for (const Json& f : *d) {
            if (!f.is_object()) continue;
            const std::string from = json_text(f, "from"), to = json_text(f, "to");
            review_.pickLines.push_back("moved " + from + " -> " + to);
            ++moved;
        }
    if (const auto w = res.find("warnings"); w != res.end() && w->is_array())
        for (const Json& line : *w)
            if (line.is_string()) review_.pickLines.push_back(line.get<std::string>());
    const ReviewItemView* item = sheet.item(n);
    review_.pickMessage = std::format("Picked #{} \"{}\" of {}.", n, item ? item->label : std::string(), sheet.id);
    if (plan.command == "assets.pick") review_.pickMessage += " It is now the asset of " + sheet.slot + ".";
    if (moved > 0) review_.pickMessage += std::format(" {} file(s) moved to {}/{}/ (moving one back undoes it).", moved, sheet.dropDir, sheet.id);
    review_.pickBad = false;
    notify(review_.pickMessage);
    // A sheet of level seeds: the Level generator shows the picked level (its sample, size, options and seed).
    if (sheet.kind == "levelSeeds") {
        LevelGenOptions o = levelGenOpt_;
        if (review_level_options_from_pick(res, sheet.meta, o)) {
            const bool sampleChanged = o.sampleFile != levelGenOpt_.sampleFile || o.sampleEntity != levelGenOpt_.sampleEntity;
            const LevelGenCaller call = level_gen_caller();
            if (sampleChanged) levelGen_.clear(call);
            else if (levelGen_.running()) levelGen_.cancel(call);
            levelGenOpt_ = o;
            levelGenSampleStale_ = true;
            showLevelGen_ = true;
            levelGen_.start(levelGenOpt_, call);
            levelGenMessage_ = std::format("Seed {} from {} (#{}).", static_cast<long long>(o.seed), sheet.id, n);
            levelGenMessageBad_ = false;
            const auto scene = sheet.meta.find("sampleScene");
            if (o.sampleFile.empty() && scene != sheet.meta.end() && scene->is_string() && fs::normalize(scene->get<std::string>()) != fs::normalize(scenePath_)) {
                levelGenMessage_ += " Its sample '" + o.sampleEntity + "' is in " + scene->get<std::string>() + ": open that scene to generate it here.";
                levelGenMessageBad_ = true;
            }
        }
    }
}

void Editor::start_level_seeds_sheet() {
    if (!engine_ || reviewSeedsJob_.running()) return;
    std::string scene;
    if (levelGenOpt_.sampleFile.empty()) {
        if (dirty_) {
            levelGenMessage_ = "Save the scene first: the sheet of seeds is made from the project as saved on disk, and the sample entity is in this scene.";
            levelGenMessageBad_ = true;
            return;
        }
        scene = scenePath_;
    }
    Result<Json> args = review_level_seeds_args(levelGenOpt_, review_.seedsCount, scene);
    if (!args.ok()) {
        levelGenMessage_ = args.error().message + (args.error().hint.empty() ? std::string() : " " + args.error().hint);
        levelGenMessageBad_ = true;
        return;
    }
    // In a child process: N levels take seconds, and review.sheet sets the process-wide project root while it works.
    reviewSeedsJob_.start(stdfs::path(projectDir_), "review.sheet", *args, kSeedsTimeoutSeconds);
    levelGenMessage_ = std::format("Making a sheet of {} seeds from seed {}...", review_.seedsCount, static_cast<long long>(levelGenOpt_.seed));
    levelGenMessageBad_ = false;
}

// ---------------------------------------------------------------------------------------------------------------- window --
void Editor::draw_review_window() {
    const bool opened = review_.show && !review_.wasShown;
    review_.wasShown = review_.show;
    if (!review_.show || !engine_) return;
    if (opened) review_.listDirty = true;
    // The listing reads up to 200 small manifests: on the reader thread, when the window opens or something changed.
    if (review_.listDirty && !projectDir_.empty()) {
        review_.listDirty = false;
        review_.listLoading = true;
        reviewLoader_.request_list(projectDir_, review_.gen);
    }
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(fit_work_area(ImVec2(980, 620)), ImGuiCond_FirstUseEver);  // a small screen scrolls it
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f), ImGuiCond_Appearing,
                            ImVec2(0.5f, 0.5f));
    if (review_.focus) {
        ImGui::SetNextWindowFocus();
        review_.focus = false;
    }
    // NoNavInputs: the arrows, the digits and Enter are the window's own keys (select, pick), not ImGui's keyboard navigation.
    if (!ImGui::Begin("Review###Review", &review_.show, ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoNavInputs)) {
        ImGui::End();
        return;
    }
    at_track("review:window");

    // ---- the list of sheets (left)
    const float listW = std::min(240.0f, ImGui::GetContentRegionAvail().x * 0.3f);
    ImGui::BeginChild("##reviewlist", ImVec2(listW, 0), ImGuiChildFlags_Borders, ImGuiWindowFlags_NoNavInputs);
    if (ImGui::SmallButton("Refresh")) review_.listDirty = true;
    at_track("review:refresh");
    ImGui::SetItemTooltip("Read the sheets of .factoria/review/ again");
    if (review_.listLoading) {
        ImGui::SameLine();
        ImGui::TextDisabled("reading...");
    }
    if (!review_.listError.empty()) ImGui::TextColored(kStatusFailed, "%s", review_.listError.c_str());
    if (review_.listLoaded && review_.rows.empty())
        ImGui::TextWrapped("No sheet yet. A sheet shows N candidates as numbered thumbnails: the AI makes one with review.sheet, and the "
                           "Level generator with \"Sheet of seeds\".");
    bool shownWaiting = false, shownAnswered = false;
    for (const ReviewListRow& row : review_.rows) {
        if (row.picked == 0 && !shownWaiting) {
            ImGui::SeparatorText("Waiting for you");
            shownWaiting = true;
        } else if (row.picked != 0 && !shownAnswered) {
            ImGui::SeparatorText("Answered");
            shownAnswered = true;
        }
        ImGui::PushID(row.id.c_str());
        ReviewSheetView asSheet;   // what review_superseded_by needs of a row
        asSheet.id = row.id;
        asSheet.createdAt = row.createdAt;
        asSheet.kind = row.kind;
        asSheet.slot = row.slot;
        const bool superseded = row.picked == 0 && !review_superseded_by(review_.rows, asSheet).empty();
        const std::string text = row.id + (row.label.empty() ? std::string() : "  " + row.label) + (superseded ? "  (superseded)" : "") + "###row";
        if (ImGui::Selectable(text.c_str(), row.id == review_.sheetId)) {
            review_show_sheet(row.id);
            if (review_.tab == 2) review_.tabSet = 0;
        }
        at_track("review:row:" + row.id);
        const std::string facts = std::to_string(row.count) + " item(s)" + (row.kind == "assetCandidates" ? ", asset candidates" : row.kind == "levelSeeds" ? ", level seeds" : "") +
                                  (row.picked ? ", picked #" + std::to_string(row.picked) : "") +
                                  (superseded ? ", superseded by a newer sheet of the same slot (read-only)" : "") + (row.createdAt.empty() ? std::string() : "\n" + row.createdAt);
        ImGui::SetItemTooltip("%s", facts.c_str());
        ImGui::PopID();
    }
    ImGui::EndChild();
    ImGui::SameLine();

    // ---- the sheet, Compare, History (right)
    ImGui::BeginGroup();
    if (ImGui::BeginTabBar("##reviewtabs")) {
        const char* names[] = {"Sheet", "Compare", "History"};
        for (int t = 0; t < 3; ++t) {
            const ImGuiTabItemFlags flags = review_.tabSet == t ? ImGuiTabItemFlags_SetSelected : 0;
            if (ImGui::BeginTabItem(names[t], nullptr, flags)) {
                review_.tab = t;
                ImGui::EndTabItem();
            }
            at_track(std::string("review:tab:") + names[t]);
        }
        review_.tabSet = -1;
        ImGui::EndTabBar();
    }
    if (review_.tab == 2) draw_review_history_tab();
    else if (!review_.sheet) {
        if (review_.sheetLoading) ImGui::TextDisabled("Reading %s...", review_.sheetId.c_str());
        else if (!review_.sheetError.empty()) ImGui::TextColored(kStatusFailed, "%s", review_.sheetError.c_str());
        else ImGui::TextDisabled("Choose a sheet on the left.");
    } else if (review_.tab == 1) {
        draw_review_compare_tab();
    } else {
        draw_review_sheet_tab();
    }
    ImGui::EndGroup();

    // ---- the keys: 1-9 select, the arrows move, Enter asks to pick (not while typing, not under the confirmation)
    const ImGuiIO& io = ImGui::GetIO();
    if (review_.sheet && review_.tab != 2 && !review_.confirmOpen && !review_.confirmRequest && !io.WantTextInput &&
        ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows)) {
        const int count = int(review_.sheet->items.size());
        for (int d = 1; d <= 9; ++d)
            if (ImGui::IsKeyPressed(ImGuiKey(ImGuiKey_0 + d), false) || ImGui::IsKeyPressed(ImGuiKey(ImGuiKey_Keypad0 + d), false))
                if (const int n = review_digit_selection(d, count); n > 0) review_.selected = n;
        const int columns = review_.sheet->columns;
        if (ImGui::IsKeyPressed(ImGuiKey_LeftArrow)) review_.selected = review_move_selection(review_.selected, count, columns, ReviewMove::Left);
        if (ImGui::IsKeyPressed(ImGuiKey_RightArrow)) review_.selected = review_move_selection(review_.selected, count, columns, ReviewMove::Right);
        if (ImGui::IsKeyPressed(ImGuiKey_UpArrow)) review_.selected = review_move_selection(review_.selected, count, columns, ReviewMove::Up);
        if (ImGui::IsKeyPressed(ImGuiKey_DownArrow)) review_.selected = review_move_selection(review_.selected, count, columns, ReviewMove::Down);
        if ((ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false)) && review_.selected > 0)
            review_request_pick(review_.selected);
    }
    draw_review_pick_popup();
    ImGui::End();
}

void Editor::draw_review_sheet_tab() {
    const ReviewSheetView& s = *review_.sheet;
    const int count = int(s.items.size());
    // Header: what the sheet is and whether it waits for an answer.
    ImGui::TextUnformatted((s.id + (s.label.empty() ? std::string() : "  " + s.label)).c_str());
    if (s.kind == "assetCandidates")
        ImGui::TextColored(ImVec4(0.55f, 0.75f, 1.0f, 1), "Asset candidates for %s: the pick becomes that asset (assets.pick).",
                           s.slot.empty() ? "(no slot)" : s.slot.c_str());
    if (const std::string newest = review_superseded_by(review_.rows, s); !newest.empty()) {
        ImGui::TextColored(kStatusWarn, "Superseded by %s: only the newest sheet of candidates for %s can be picked; this one is read-only.",
                           newest.c_str(), s.slot.c_str());
        at_track("review:superseded");
    }
    if (s.is_picked()) {
        const ReviewItemView* p = s.item(s.picked_n());
        const std::string who = json_text(s.picked, "who");
        const std::string at = json_text(s.picked, "at");
        ImGui::TextColored(kStatusReady, "Answered: #%d \"%s\" was picked%s%s. A choice is final; this sheet is read-only.", s.picked_n(),
                           p ? p->label.c_str() : "", who.empty() ? "" : (" by " + who).c_str(), at.empty() ? "" : (" on " + at).c_str());
    } else {
        ImGui::TextDisabled("%d item(s), made %s. Waiting for your answer.", count, s.createdAt.c_str());
    }
    at_track("review:status");
    for (const std::string& w : s.warnings) ImGui::TextColored(kStatusWarn, "%s", w.c_str());

    // Zoom.
    if (ImGui::SmallButton("Fit")) review_.zoom = 0;
    at_track("review:zoom-fit");
    ImGui::SetItemTooltip("Fit the whole sheet in the window");
    ImGui::SameLine();
    const float fitScale = review_.zoom > 0 ? review_.zoom : -1.0f;
    if (ImGui::SmallButton("-")) review_.zoom = std::max(0.05f, (review_.zoom > 0 ? review_.zoom : 0.5f) / 1.25f);
    ImGui::SetItemTooltip("Smaller");
    ImGui::SameLine();
    if (ImGui::SmallButton("+")) review_.zoom = std::min(4.0f, (review_.zoom > 0 ? review_.zoom : 0.5f) * 1.25f);
    ImGui::SetItemTooltip("Bigger (scroll to move around)");
    ImGui::SameLine();
    if (ImGui::SmallButton("100%")) review_.zoom = 1.0f;
    ImGui::SetItemTooltip("One pixel of the sheet per pixel of the screen");
    ImGui::SameLine();
    if (fitScale > 0) ImGui::TextDisabled("%.0f%%", double(fitScale) * 100.0);
    else ImGui::TextDisabled("fit");

    // The picture, with a button over each thumbnail.
    const float footer = ImGui::GetFrameHeightWithSpacing() * 2.0f + ImGui::GetTextLineHeightWithSpacing() * (review_.pickMessage.empty() ? 1.0f : 2.0f + float(std::min<std::size_t>(review_.pickLines.size(), 3)));
    const float childH = std::max(80.0f, ImGui::GetContentRegionAvail().y - footer);
    ImGui::BeginChild("##reviewsheet", ImVec2(0, childH), ImGuiChildFlags_Borders, ImGuiWindowFlags_HorizontalScrollbar | ImGuiWindowFlags_NoNavInputs);
    const stdfs::path sheetDir = stdfs::path(projectDir_) / fs::path_from_utf8(std::string(kReviewDir) + "/" + s.id);
    const std::string picRel = safe_rel(s.picture);
    const ReviewTextureSlot& slot = review_texture("sheet", picRel.empty() ? sheetDir / "sheet.png" : stdfs::path(projectDir_) / fs::path_from_utf8(picRel),
                                                   kReviewSheetMaxSide, false);
    if (!slot.error.empty()) {
        ImGui::TextColored(kStatusFailed, "The sheet's picture cannot be shown: %s", slot.error.c_str());
    } else if (!slot.tex.view) {
        ImGui::TextDisabled("Loading the picture...");
    } else {
        const int w = s.width > 0 ? s.width : slot.tex.w, h = s.height > 0 ? s.height : slot.tex.h;
        const ImVec2 avail = ImGui::GetContentRegionAvail();
        const float scale = review_.zoom > 0 ? review_.zoom : review_fit_scale(w, h, avail.x, avail.y);
        const ImVec2 size(float(w) * scale, float(h) * scale);
        const ImVec2 origin = ImGui::GetCursorScreenPos();
        ImDrawList* dl = ImGui::GetWindowDrawList();
        dl->AddImage(tex_ref(slot.tex, scale * float(w) / float(std::max(1, slot.tex.w))), origin, ImVec2(origin.x + size.x, origin.y + size.y));
        for (const ReviewItemView& it : s.items) {
            if (it.w <= 0 || it.h <= 0) continue;
            const ImVec2 a(origin.x + float(it.x) * scale, origin.y + float(it.y) * scale);
            const ImVec2 b(a.x + std::max(1.0f, float(it.w) * scale), a.y + std::max(1.0f, float(it.h) * scale));
            ImGui::SetCursorScreenPos(a);
            ImGui::PushID(it.n);
            if (ImGui::InvisibleButton("##item", ImVec2(b.x - a.x, b.y - a.y))) review_.selected = it.n;
            if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
                review_.selected = it.n;
                review_request_pick(it.n);
            }
            at_track("review:item:" + std::to_string(it.n));
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
                ImGui::SetTooltip("#%d %s\n%s%s%s", it.n, it.label.c_str(), it.info.c_str(), it.ok ? "" : "\nCould not be drawn: ", it.ok ? "" : it.error.c_str());
            ImGui::PopID();
            if (s.picked_n() == it.n) dl->AddRect(a, b, IM_COL32(110, 230, 120, 255), 2.0f, 0, 3.0f);
            if (review_.selected == it.n) dl->AddRect(ImVec2(a.x - 2, a.y - 2), ImVec2(b.x + 2, b.y + 2), IM_COL32(255, 214, 64, 255), 3.0f, 0, 3.0f);
        }
        ImGui::SetCursorScreenPos(origin);
        ImGui::Dummy(size);   // the scroll area is the picture
        at_track("review:picture");
    }
    ImGui::EndChild();

    // The selection and the pick.
    const ReviewItemView* sel = s.item(review_.selected);
    if (sel) ImGui::Text("#%d %s   %s", sel->n, sel->label.c_str(), sel->info.c_str());
    else ImGui::TextDisabled("Click a thumbnail or press its number.");
    at_track("review:selection");
    const ReviewPickPlan plan = review_plan_for(s, review_.selected, true, std::string());
    const bool canPick = sel && plan.error.empty();
    ImGui::BeginDisabled(!canPick);
    const std::string pickLabel = sel ? std::format("Pick #{}...", sel->n) : std::string("Pick...");
    if (ImGui::Button(pickLabel.c_str())) review_request_pick(review_.selected);
    ImGui::EndDisabled();
    at_track("review:pick", canPick);
    tooltip_even_when_disabled(canPick ? "Choose this one: a window says which files move first. Same as pressing Enter."
                                       : (sel ? plan.error.c_str() : "Select a thumbnail first (click it, or press 1-9)."));
    fit_same_line("1-9 select, the arrows move, Enter picks");
    ImGui::TextDisabled("1-9 select, the arrows move, Enter picks");
    if (!review_.pickMessage.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, review_.pickBad ? kStatusFailed : kStatusReady);
        ImGui::TextWrapped("%s", review_.pickMessage.c_str());
        ImGui::PopStyleColor();
        at_track("review:pick-message");
        for (std::size_t i = 0; i < review_.pickLines.size() && i < 3; ++i) ImGui::TextDisabled("%s", review_.pickLines[i].c_str());
        if (review_.pickLines.size() > 3) ImGui::SetItemTooltip("%zu more line(s): see the History tab.", review_.pickLines.size() - 3);
    }
}

void Editor::draw_review_compare_tab() {
    const ReviewSheetView& s = *review_.sheet;
    const int count = int(s.items.size());
    if (count < 1) {
        ImGui::TextDisabled("This sheet has no items.");
        return;
    }
    // Which two.
    for (int side = 0; side < 2; ++side) {
        int& pickSide = side == 0 ? review_.compareA : review_.compareB;
        ImGui::TextUnformatted(side == 0 ? "Left: " : "Right:");
        for (int n = 1; n <= count; ++n) {
            char label[24];
            std::snprintf(label, sizeof(label), "%d##cmp%d_%d", n, side, n);
            fit_same_line(label);
            const bool on = pickSide == n;
            if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive));
            if (ImGui::SmallButton(label)) pickSide = n;
            if (on) ImGui::PopStyleColor();
            at_track(std::format("review:cmp-{}:{}", side == 0 ? 'a' : 'b', n));
            if (const ReviewItemView* it = s.item(n)) ImGui::SetItemTooltip("#%d %s", n, it->label.c_str());
        }
    }
    ImGui::Checkbox("The candidates' own pictures", &review_.compareSource);
    at_track("review:cmp-source");
    ImGui::SetItemTooltip("Show the image files themselves (sharper than the thumbnails); a level, a scene or an effect always shows its thumbnail.");

    const stdfs::path project(projectDir_);
    const stdfs::path sheetDir = project / fs::path_from_utf8(std::string(kReviewDir) + "/" + s.id);
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float spacing = ImGui::GetStyle().ItemSpacing.x;
    const float colW = std::max(80.0f, (avail.x - spacing) * 0.5f);
    for (int side = 0; side < 2; ++side) {
        const int n = side == 0 ? review_.compareA : review_.compareB;
        const ReviewItemView* it = s.item(n);
        if (side == 1) ImGui::SameLine();
        ImGui::BeginChild(side == 0 ? "##cmpleft" : "##cmpright", ImVec2(colW, std::max(80.0f, avail.y)), ImGuiChildFlags_Borders, ImGuiWindowFlags_NoNavInputs);
        if (!it) {
            ImGui::TextDisabled("Choose a number above.");
            ImGui::EndChild();
            continue;
        }
        ImGui::Text("#%d %s", it->n, it->label.c_str());
        at_track(std::format("review:cmp-title-{}", side == 0 ? 'a' : 'b'));
        // The candidate's own picture when asked and readable, else its thumbnail.
        const ReviewTextureSlot* shown = nullptr;
        const std::string src = it->type == "image" ? safe_rel(it->source) : std::string();
        if (review_.compareSource && !src.empty()) {
            const ReviewTextureSlot& own = review_texture("src:" + std::to_string(n), project / fs::path_from_utf8(src), kReviewCompareMaxSide, true);
            if (own.error.empty()) shown = &own;
        }
        if (!shown) {
            const std::string thumb = safe_rel(it->thumb);
            if (!thumb.empty()) shown = &review_texture("thumb:" + std::to_string(n), sheetDir / fs::path_from_utf8(thumb), kReviewThumbMaxSide, false);
        }
        const float textH = ImGui::GetTextLineHeightWithSpacing() * 3.0f + ImGui::GetFrameHeightWithSpacing();
        const ImVec2 room(ImGui::GetContentRegionAvail().x, std::max(40.0f, ImGui::GetContentRegionAvail().y - textH));
        if (!shown) {
            ImGui::TextDisabled("No picture for this item.");
        } else if (!shown->error.empty()) {
            ImGui::TextColored(kStatusFailed, "%s", shown->error.c_str());
        } else if (!shown->tex.view) {
            ImGui::TextDisabled("Loading...");
        } else {
            const float scale = review_fit_scale(shown->tex.w, shown->tex.h, room.x, room.y, 8.0f);
            ImGui::Image(tex_ref(shown->tex, scale), ImVec2(float(shown->tex.w) * scale, float(shown->tex.h) * scale));
            at_track(std::format("review:cmp-picture-{}", side == 0 ? 'a' : 'b'));
        }
        ImGui::TextWrapped("%s", it->info.c_str());
        if (!it->ok) ImGui::TextColored(kStatusFailed, "Could not be drawn: %s", it->error.c_str());
        const ReviewPickPlan plan = review_plan_for(s, n, true, std::string());
        ImGui::BeginDisabled(!plan.error.empty());
        if (ImGui::Button(std::format("Pick #{}...##cmp{}", n, side).c_str())) {
            review_.selected = n;
            review_request_pick(n);
        }
        ImGui::EndDisabled();
        at_track(std::format("review:cmp-pick-{}", side == 0 ? 'a' : 'b'), plan.error.empty());
        tooltip_even_when_disabled(plan.error.empty() ? "Choose this one (a window says which files move first)" : plan.error.c_str());
        ImGui::EndChild();
    }
}

void Editor::draw_review_history_tab() {
    if (review_.history.empty()) {
        ImGui::TextDisabled(review_.listLoaded ? "No sheet has been answered yet." : "Reading...");
        return;
    }
    ImGui::BeginChild("##reviewhistory", ImVec2(0, 0), ImGuiChildFlags_None, ImGuiWindowFlags_NoNavInputs);
    for (const ReviewHistoryRow& h : review_.history) {
        ImGui::PushID(h.id.c_str());
        ImGui::SeparatorText((h.id + (h.label.empty() ? std::string() : "  " + h.label)).c_str());
        ImGui::Text("#%d \"%s\" of %d, picked%s%s", h.n, h.pickedLabel.c_str(), h.count, h.who.empty() ? "" : (" by " + h.who).c_str(),
                    h.at.empty() ? "" : (" on " + h.at).c_str());
        at_track("review:history:" + h.id);
        if (!h.note.empty()) ImGui::TextWrapped("Note: %s", h.note.c_str());
        for (const ReviewDroppedLine& d : h.dropped) {
            const ImVec4 colour = d.status == "moved" ? ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled) : d.status == "expired" ? kStatusWarn : kStatusFailed;
            ImGui::TextColored(colour, "  #%d %s: %s -> %s (%s)", d.n, d.label.c_str(), d.from.c_str(), d.to.c_str(), d.status.c_str());
            ImGui::SetItemTooltip("%s", d.status == "moved"     ? "In the drop folder: move it back to undo the drop."
                                        : d.status == "expired" ? "Deleted by review.cleanup, days after the pick."
                                                                : "No longer in the drop folder (moved back or deleted by hand).");
        }
        if (h.dropped.empty()) ImGui::TextDisabled("  No file was moved.");
        if (ImGui::SmallButton("Open")) {
            review_show_sheet(h.id);
            review_.tabSet = 0;
        }
        at_track("review:history-open:" + h.id);
        ImGui::SetItemTooltip("Show this sheet (read-only: it was answered)");
        ImGui::PopID();
    }
    ImGui::EndChild();
}

void Editor::draw_review_pick_popup() {
    if (review_.confirmRequest) {
        review_.confirmRequest = false;
        review_.confirmOpen = true;
        review_.confirmFrame = uiFrame_;
        ImGui::OpenPopup("Pick this one?###ReviewPick");
    }
    const ImVec2 maxSize = fit_work_area(ImVec2(680, 520));
    ImGui::SetNextWindowSizeConstraints(ImVec2(std::min(360.0f, maxSize.x), 0), maxSize);
    if (!ImGui::BeginPopupModal("Pick this one?###ReviewPick", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        review_.confirmOpen = false;
        return;
    }
    bool confirm = false, cancel = false;
    if (!review_.sheet) {
        cancel = true;
    } else {
        const ReviewSheetView& s = *review_.sheet;
        const ReviewPickPlan plan = review_plan_for(s, review_.confirmN, !review_.keepFiles, review_.note);
        const ReviewItemView* it = s.item(review_.confirmN);
        ImGui::Text("Pick #%d \"%s\" of %s?", review_.confirmN, it ? it->label.c_str() : "", s.id.c_str());
        if (plan.command == "assets.pick") ImGui::TextWrapped("assets.pick makes it the asset of %s.", s.slot.c_str());
        if (!plan.error.empty()) ImGui::TextColored(kStatusFailed, "%s", plan.error.c_str());
        if (plan.moves.empty()) {
            ImGui::TextDisabled(review_.keepFiles ? "No file is moved: only the choice is recorded." : "No file is moved (no other item is a candidate file).");
        } else {
            ImGui::TextWrapped("These %zu file(s) are MOVED to %s/%s/ (nothing is deleted now; review.cleanup deletes them %d days after the pick, "
                               "and moving one back undoes it):",
                               plan.moves.size(), s.dropDir.c_str(), s.id.c_str(), kReviewDroppedDays);
            const float h = std::min(160.0f, ImGui::GetTextLineHeightWithSpacing() * float(plan.moves.size()) + 8.0f);
            ImGui::BeginChild("##reviewmoves", ImVec2(std::min(600.0f, maxSize.x - 24.0f), h), ImGuiChildFlags_Borders);
            for (const ReviewMoveLine& m : plan.moves) ImGui::Text("#%d %s   %s", m.n, m.label.c_str(), m.from.c_str());
            ImGui::EndChild();
            at_track("review:confirm-moves");
        }
        if (plan.canKeepFiles) {
            ImGui::Checkbox("Keep the other files where they are", &review_.keepFiles);
            at_track("review:keep-files");
            ImGui::SetItemTooltip("Only record the choice (review.pick with drop: false): no file moves.");
        }
        ImGui::SetNextItemWidth(std::min(420.0f, maxSize.x - 24.0f));
        ImGui::InputTextWithHint("##reviewnote", "Why this one? (optional, kept with the choice)", &review_.note);
        at_track("review:note");
        ImGui::BeginDisabled(!plan.error.empty());
        if (ImGui::Button(std::format("Pick #{}", review_.confirmN).c_str())) confirm = true;
        ImGui::EndDisabled();
        at_track("review:confirm", plan.error.empty());
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) cancel = true;
        at_track("review:cancel");
        // Enter confirms (not the Enter that opened this window, nor one typed in the note), Escape cancels.
        const ImGuiIO& io = ImGui::GetIO();
        if (!io.WantTextInput && review_.confirmFrame + 2 < uiFrame_ && plan.error.empty() &&
            (ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false)))
            confirm = true;
        if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) cancel = true;
    }
    if (confirm || cancel) {
        ImGui::CloseCurrentPopup();
        review_.confirmOpen = false;
    }
    ImGui::EndPopup();
    if (confirm) review_do_pick();
}

}  // namespace fa::editor
