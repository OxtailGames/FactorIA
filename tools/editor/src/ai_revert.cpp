// Revert an AI run: before every run the editor takes a project checkpoint (fa/tooling/checkpoint.h) and remembers the
// open scene; after the run the transcript gets a "This run changed N files" item with a Revert button. Revert restores the
// checkpoint (which first saves a safety checkpoint) and puts the world back as ONE undo step; "Undo revert" restores the
// safety checkpoint. The AI is told about a revert in the next prompt (revert_line in ai_chat.h). docs/EDITOR.md.
#include <algorithm>
#include <ctime>

#include "editor_internal.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

constexpr std::size_t kKeepScenes = 10;  // in-memory scenes kept for Revert (each is a whole scene snapshot)

// Keeps the first kMaxListedFiles names; the rest only count.
void cap_list(std::vector<std::string>& names, int& omitted) {
    if (names.size() <= kMaxListedFiles) return;
    omitted += static_cast<int>(names.size() - kMaxListedFiles);
    names.resize(kMaxListedFiles);
}

int file_count(const ChatItem& c) { return static_cast<int>(c.modified.size() + c.added.size() + c.deleted.size()) + c.omitted; }

void list_files(const CheckpointDiff& d, std::size_t perList) {
    auto block = [&](const std::vector<std::string>& names, const char* tag) {
        for (std::size_t i = 0; i < names.size() && i < perList; ++i) ImGui::BulletText("%s  %s", tag, names[i].c_str());
        if (names.size() > perList) ImGui::TextDisabled("   ... and %d more", static_cast<int>(names.size() - perList));
    };
    block(d.modified, "modified");
    block(d.added, "added   ");
    block(d.deleted, "deleted ");
}

}  // namespace

void Editor::ai_remember_scene(const std::string& checkpointId, bool dirty) {
    if (!engine_ || checkpointId.empty()) return;
    SceneAtCheckpoint s;
    s.id = checkpointId;
    s.scenePath = scenePath_;
    s.scene = save_scene(world());
    s.dirty = dirty;
    aiScenes_.push_back(std::move(s));
    if (aiScenes_.size() > kKeepScenes) aiScenes_.erase(aiScenes_.begin());
}

void Editor::ai_run_checkpoint_begin(const std::string& task) {
    aiRunCheckpoint_.clear();
    if (!engine_) return;
    const std::string label = chat_title_from(task, 60);
    auto cp = checkpoint_create(projectDir_, label.empty() ? "AI run" : label);
    if (!cp.ok()) {
        notify("The AI run starts without a checkpoint, so it cannot be reverted: " + cp.error().to_string(), 1);
        return;
    }
    aiRunCheckpoint_ = cp.value().info.id;
    ai_remember_scene(aiRunCheckpoint_, dirty_);
}

void Editor::ai_run_checkpoint_finish(AiChat& chat) {
    const std::string id = std::exchange(aiRunCheckpoint_, std::string());
    if (id.empty() || !engine_) return;
    auto diff = checkpoint_diff(projectDir_, id);
    if (!diff.ok()) return;
    bool sceneChanged = false;
    auto remembered = std::find_if(aiScenes_.begin(), aiScenes_.end(), [&](const SceneAtCheckpoint& s) { return s.id == id; });
    if (remembered != aiScenes_.end()) sceneChanged = remembered->scenePath != scenePath_ || remembered->scene != save_scene(world());
    if (diff.value().empty() && !sceneChanged) {  // nothing to take back
        if (remembered != aiScenes_.end()) aiScenes_.erase(remembered);
        return;
    }
    ChatItem it;
    it.kind = ChatItem::Kind::Run;
    it.checkpointId = id;
    it.modified = std::move(diff.value().modified);
    it.added = std::move(diff.value().added);
    it.deleted = std::move(diff.value().deleted);
    cap_list(it.modified, it.omitted);
    cap_list(it.added, it.omitted);
    cap_list(it.deleted, it.omitted);
    it.sceneChanged = sceneChanged;
    chat.items.push_back(std::move(it));
}

int Editor::ai_last_revertable_run() const {
    const auto& items = chat_.current().items;
    for (int i = static_cast<int>(items.size()) - 1; i >= 0; --i)
        if (items[static_cast<std::size_t>(i)].kind == ChatItem::Kind::Run && items[static_cast<std::size_t>(i)].revertedBy.empty()) return i;
    return -1;
}

void Editor::ai_revert_request(const std::string& chatId, int item) {
    AiChat* chat = chat_.find(chatId);
    if (!chat || item < 0 || static_cast<std::size_t>(item) >= chat->items.size() || !engine_) return;
    if (ai_busy() || play_ != PlayState::Edit) return;
    const ChatItem& c = chat->items[static_cast<std::size_t>(item)];
    AiRevertRequest req;
    req.chatId = chatId;
    req.item = item;
    if (c.kind == ChatItem::Kind::Run && c.revertedBy.empty()) {
        req.target = c.checkpointId;
        for (std::size_t i = static_cast<std::size_t>(item) + 1; i < chat->items.size(); ++i)
            if (chat->items[i].kind == ChatItem::Kind::Run && chat->items[i].revertedBy.empty()) ++req.laterRuns;
    } else if (c.kind == ChatItem::Kind::Revert && !c.isUndo && !c.undone) {
        req.undo = true;
        req.target = c.safetyId;
    } else {
        return;
    }
    auto diff = checkpoint_diff(projectDir_, req.target);
    if (!diff.ok()) {
        notify("Cannot revert: " + diff.error().message + " The editor keeps the newest " + std::to_string(kCheckpointLimit) +
                   " checkpoints (Help > Docs: Editor, \"Revert an AI run\").",
               2);
        return;
    }
    req.diff = std::move(diff.value());
    req.open = true;
    aiRevert_ = std::move(req);
}

void Editor::draw_ai_revert_dialog() {
    if (aiRevert_.open && !aiRevert_.shown) {
        ImGui::OpenPopup("Revert AI run##revert");
        aiRevert_.shown = true;
    }
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (!ImGui::BeginPopupModal("Revert AI run##revert", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        if (aiRevert_.shown && !ImGui::IsPopupOpen("Revert AI run##revert")) aiRevert_ = {};
        return;
    }
    const CheckpointDiff& d = aiRevert_.diff;
    const bool undo = aiRevert_.undo;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 36.0f);
    ImGui::TextUnformatted(undo ? "Undo the revert: the project goes back to how it was just before you reverted."
                                : "Put the project back as it was before this AI run.");
    ImGui::Spacing();
    if (d.empty()) {
        ImGui::TextDisabled("No file differs from that moment; only the open scene goes back.");
    } else {
        ImGui::Text("%d file(s) written back to their earlier content, %d file(s) created again, %d file(s) deleted.",
                    static_cast<int>(d.modified.size()), static_cast<int>(d.deleted.size()), static_cast<int>(d.added.size()));
        ImGui::BeginChild("##revertfiles", ImVec2(ImGui::GetFontSize() * 36.0f, ImGui::GetTextLineHeightWithSpacing() * static_cast<float>(std::min<std::size_t>(9, d.modified.size() + d.added.size() + d.deleted.size()) + 1)),
                          ImGuiChildFlags_Borders);
        list_files(d, 60);
        ImGui::EndChild();
    }
    if (aiRevert_.laterRuns > 0)
        ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "This is not the newest run: the %d later run(s) are taken back too.", aiRevert_.laterRuns);
    ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "Anything you edited by hand in these files since then is lost.");
    ImGui::TextDisabled("The scene goes back as one Undo step (Ctrl+Z). A safety checkpoint is saved first, so you can take this back.");
    ImGui::PopTextWrapPos();
    ImGui::Spacing();
    if (ImGui::Button(undo ? "Undo revert" : "Revert")) {
        ImGui::CloseCurrentPopup();
        ai_revert_apply();
    }
    at_track("ai:revert:confirm");
    ImGui::SameLine();
    if (ImGui::Button("Cancel")) {
        ImGui::CloseCurrentPopup();
        aiRevert_ = {};
    }
    at_track("ai:revert:cancel");
    ImGui::EndPopup();
}

void Editor::ai_revert_apply() {
    const AiRevertRequest req = std::exchange(aiRevert_, AiRevertRequest{});
    if (!engine_ || ai_busy() || play_ != PlayState::Edit) return;
    AiChat* chat = chat_.find(req.chatId);
    if (!chat || req.item < 0 || static_cast<std::size_t>(req.item) >= chat->items.size()) return;

    // The world as it is now: it becomes the first Undo step and what "Undo revert" brings back.
    const Json worldBefore = save_scene(world());
    const bool dirtyBefore = dirty_;
    const std::string pathBefore = scenePath_;

    auto restored = checkpoint_restore(projectDir_, req.target);
    if (!restored.ok()) {
        notify("Revert failed: " + restored.error().to_string(), 2);
        return;
    }
    const std::string safety = restored.value().safetyId;

    // The files changed under the engine: scripts re-import, the Project panel lists again, then the world.
    engine_->scripts().refresh_modules(true);
    project_files_changed();
    auto remembered = std::find_if(aiScenes_.begin(), aiScenes_.end(), [&](const SceneAtCheckpoint& s) { return s.id == req.target; });
    if (remembered != aiScenes_.end() && remembered->scenePath == scenePath_) {
        undo_.push_back(worldBefore);
        if (undo_.size() > 100) undo_.erase(undo_.begin());
        redo_.clear();
        restore_scene(remembered->scene);
        dirty_ = remembered->dirty;
        lastEditKey_.clear();
    } else {
        reload_scene_from_disk(true);  // after a restart the in-memory scene is gone: the restored file is the scene
    }
    SceneAtCheckpoint before;
    before.id = safety;
    before.scenePath = pathBefore;
    before.scene = worldBefore;
    before.dirty = dirtyBefore;
    aiScenes_.push_back(std::move(before));
    if (aiScenes_.size() > kKeepScenes) aiScenes_.erase(aiScenes_.begin());

    // The transcript.
    ChatItem& source = chat->items[static_cast<std::size_t>(req.item)];
    ChatItem it;
    it.kind = ChatItem::Kind::Revert;
    it.checkpointId = req.target;
    it.modified = std::move(restored.value().changes.modified);
    it.added = std::move(restored.value().changes.added);
    it.deleted = std::move(restored.value().changes.deleted);
    cap_list(it.modified, it.omitted);
    cap_list(it.added, it.omitted);
    cap_list(it.deleted, it.omitted);
    if (req.undo) {
        it.isUndo = true;
        it.safetyId = source.safetyId;  // pairs it with the Revert it takes back (revert_line)
        source.undone = true;
        for (ChatItem& run : chat->items)
            if (run.kind == ChatItem::Kind::Run && run.revertedBy == source.safetyId) run.revertedBy.clear();
        it.text = "Undid the revert: " + std::to_string(file_count(it)) + " file(s) are as the run left them.";
    } else {
        it.safetyId = safety;
        it.sceneChanged = source.sceneChanged;
        for (std::size_t i = static_cast<std::size_t>(req.item); i < chat->items.size(); ++i)
            if (chat->items[i].kind == ChatItem::Kind::Run && chat->items[i].revertedBy.empty()) chat->items[i].revertedBy = safety;
        it.text = "Reverted: " + std::to_string(file_count(it)) + " file(s) went back to how they were before the run" +
                  (it.sceneChanged ? ", and the open scene with them." : ".");
    }
    chat->items.push_back(std::move(it));
    chat->scrollDown = true;
    chat->updated = static_cast<i64>(std::time(nullptr));
    chat_.save(*chat);
    chat_.save_open_list();
    notify(req.undo ? "Revert undone" : "Run reverted (Ctrl+Z undoes the scene part)");
}

void Editor::draw_ai_run_item(ChatItem& c, AiChat& chat, int index) {
    const bool disabled = ai_busy() || play_ != PlayState::Edit;
    auto files = [&] {
        CheckpointDiff d{c.modified, c.added, c.deleted};
        const int n = file_count(c);
        if (n == 0) return;
        if (n <= 5) {
            list_files(d, 5);
        } else if (ImGui::TreeNodeEx("##files", ImGuiTreeNodeFlags_SpanAvailWidth, "files (%d)", n)) {
            list_files(d, kMaxListedFiles);
            if (c.omitted) ImGui::TextDisabled("   ... and %d more", c.omitted);
            ImGui::TreePop();
        }
    };
    if (c.kind == ChatItem::Kind::Run) {
        const bool reverted = !c.revertedBy.empty();
        const int n = file_count(c);
        const ImVec4 col = reverted ? ImVec4(0.6f, 0.6f, 0.6f, 1) : ImVec4(0.95f, 0.8f, 0.45f, 1);
        std::string what = n ? std::to_string(n) + (n == 1 ? " file" : " files") : std::string();
        if (c.sceneChanged) what += n ? " and the open scene" : "the open scene";
        ImGui::TextColored(col, "This run changed %s%s", what.c_str(), reverted ? " (reverted)" : "");
        files();
        if (!reverted) {
            ImGui::BeginDisabled(disabled);
            if (ImGui::SmallButton("Revert")) ai_revert_request(chat.id, index);
            ImGui::EndDisabled();
            at_track("ai:revert", !disabled);
            ImGui::SetItemTooltip("Put the project's files and the open scene back as they were before this run.\nAsks first; the scene part is one Ctrl+Z step.");
        }
    } else {
        ImGui::TextColored(ImVec4(0.6f, 0.75f, 0.95f, 1), "%s", c.text.c_str());
        files();
        if (!c.isUndo && !c.undone) {
            ImGui::BeginDisabled(disabled);
            if (ImGui::SmallButton("Undo revert")) ai_revert_request(chat.id, index);
            ImGui::EndDisabled();
            at_track("ai:undo-revert", !disabled);
            ImGui::SetItemTooltip("Take the revert back: the project returns to how it was just before you reverted.");
        } else if (c.undone) {
            ImGui::TextDisabled("(undone)");
        }
    }
}

}  // namespace fa::editor
