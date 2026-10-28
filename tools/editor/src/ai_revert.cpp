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

void Editor::ai_run_checkpoint_begin(AiRun& run, const std::string& task) {
    run.checkpointId.clear();
    if (!engine_) return;
    const std::string label = chat_title_from(task, 60);
    auto cp = checkpoint_create(projectDir_, label.empty() ? "AI run" : label);
    if (!cp.ok()) {
        notify("The AI run starts without a checkpoint, so it cannot be reverted: " + cp.error().to_string(), 1);
        return;
    }
    run.checkpointId = cp.value().info.id;
    ai_remember_scene(run.checkpointId, dirty_);
}

void Editor::ai_run_checkpoint_finish(AiRun& run, AiChat& chat) {
    const std::string id = std::exchange(run.checkpointId, std::string());
    const std::string chatId = run.chatId;
    // Read what this run and the runs that overlapped it changed BEFORE the tracker forgets them (RunTouchTracker::end).
    const std::set<std::string> own = aiTouch_.touched(chatId), others = aiTouch_.touched_by_others(chatId);
    const bool overlapped = aiTouch_.overlapped(chatId);
    auto close_tracker = [&](const std::vector<std::string>& changed) {
        ai_warn_conflicts(aiTouch_.end(chatId, changed));
        ai_flush_conflicts();
    };
    if (id.empty() || !engine_) {
        close_tracker({});
        return;
    }
    auto diff = checkpoint_diff(projectDir_, id);
    if (!diff.ok()) {
        close_tracker({});
        return;
    }
    CheckpointDiff changes = std::move(diff.value());
    // Other chats ran at the same time: the checkpoint's diff also holds what THEY changed. This run keeps the files it
    // touched itself and those nobody else touched (a Bash command wrote them: no tool call names them).
    if (overlapped) {
        std::vector<std::string> all = changes.modified;
        all.insert(all.end(), changes.added.begin(), changes.added.end());
        all.insert(all.end(), changes.deleted.begin(), changes.deleted.end());
        const std::vector<std::string> mine = attribute_files(all, own, others);
        const std::set<std::string> keep(mine.begin(), mine.end());
        for (std::vector<std::string>* list : {&changes.modified, &changes.added, &changes.deleted})
            std::erase_if(*list, [&](const std::string& f) { return !keep.contains(f); });
    }
    const std::string sceneRel = project_relative(scenePath_, projectDir_);
    bool sceneChanged = false;
    auto remembered = std::find_if(aiScenes_.begin(), aiScenes_.end(), [&](const SceneAtCheckpoint& s) { return s.id == id; });
    if (remembered != aiScenes_.end()) sceneChanged = remembered->scenePath != scenePath_ || remembered->scene != save_scene(world());
    // The world is one for every chat: it differs from the start of this run also when another chat edited it. Only a run that
    // sent a scene command of its own (or no one else could have) gets the scene.
    if (overlapped && !own.contains(sceneRel)) sceneChanged = false;
    if (changes.empty() && !sceneChanged) {  // nothing to take back
        if (remembered != aiScenes_.end()) aiScenes_.erase(remembered);
        close_tracker({});
        return;
    }
    ChatItem it;
    it.kind = ChatItem::Kind::Run;
    it.checkpointId = id;
    std::vector<std::string> credited = changes.modified;
    credited.insert(credited.end(), changes.added.begin(), changes.added.end());
    credited.insert(credited.end(), changes.deleted.begin(), changes.deleted.end());
    if (sceneChanged && !sceneRel.empty()) credited.push_back(sceneRel);
    it.modified = std::move(changes.modified);
    it.added = std::move(changes.added);
    it.deleted = std::move(changes.deleted);
    cap_list(it.modified, it.omitted);
    cap_list(it.added, it.omitted);
    cap_list(it.deleted, it.omitted);
    it.sceneChanged = sceneChanged;
    it.startedAt = run.startedAt;
    it.endedAt = static_cast<i64>(std::time(nullptr));
    if (sceneChanged) it.scenePath = sceneRel;
    chat.items.push_back(std::move(it));
    close_tracker(credited);
}

// A run changed `files`: if another chat's run that overlapped it changed one too, both chats are told (at the end of the
// frame, one note per pair of chats).
void Editor::ai_note_files(const std::string& chatId, const std::vector<std::string>& files) {
    if (files.empty() || !ai_run_of(chatId)) return;
    for (const std::string& f : files) ai_warn_conflicts(aiTouch_.touch(chatId, f));
}

void Editor::ai_warn_conflicts(const std::vector<FileConflict>& conflicts) {
    aiConflicts_.insert(aiConflicts_.end(), conflicts.begin(), conflicts.end());
}

void Editor::ai_flush_conflicts() {
    if (aiConflicts_.empty()) return;
    const std::vector<ConflictNote> notes = group_conflicts(std::exchange(aiConflicts_, {}));
    auto title_of = [&](const AiChat* c) { return c ? c->title : std::string(); };
    for (const ConflictNote& n : notes) {
        AiChat* a = chat_.find(n.run);
        AiChat* b = chat_.find(n.other);
        if (!a || !b) continue;
        auto warn = [&](AiChat& to, const AiChat* about, const std::string& aboutId) {
            ChatItem it;
            it.kind = ChatItem::Kind::Info;
            it.isError = true;  // a warning: drawn in amber
            it.text = conflict_text(title_of(about), aiTouch_.active(aboutId), n.files);
            to.items.push_back(std::move(it));
            to.scrollDown = true;
        };
        warn(*a, b, n.other);
        warn(*b, a, n.run);
    }
}

// What a command that ran on the main thread for `chatId` changed (called from run_queued with the job's tag).
void Editor::ai_note_command(const std::string& chatId, const std::string& name, const Json& args, const CommandResult& result) {
    if (!engine_ || !result.ok || !ai_run_of(chatId)) return;
    const CommandInfo* info = engine_->commands().info(name);
    if (!info || info->readOnly) return;
    // A command that changes the world (not one that only writes files, nor one that swaps the whole scene).
    if (name == "scene.load" || name == "scene.reload") return;  // swaps the whole scene: its "path" is read, not written
    const bool editsWorld = (name.rfind("scene.", 0) == 0 || name == "tilemap.set_tile") && name != "scene.save" &&
                            name != "scene.load" && name != "scene.reload" && command_edits_scene(name, args);
    if (editsWorld) ai_run_of(chatId)->sceneEdited = true;
    ai_note_files(chatId, command_touched_files(name, args, result.result, false, editsWorld, scenePath_, projectDir_));
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
    if (ai_chat_busy(chatId) || play_ != PlayState::Edit) return;  // the other chats may be running: the dialog says what that means
    const ChatItem& c = chat->items[static_cast<std::size_t>(item)];
    AiRevertRequest req;
    req.chatId = chatId;
    req.item = item;
    if (c.kind == ChatItem::Kind::Run && c.revertedBy.empty()) {
        req.target = c.checkpointId;
        bool truncated = false;
        for (std::size_t i = static_cast<std::size_t>(item); i < chat->items.size(); ++i) {
            const ChatItem& r = chat->items[i];
            if (r.kind != ChatItem::Kind::Run || !r.revertedBy.empty()) continue;
            if (i > static_cast<std::size_t>(item)) ++req.laterRuns;
            for (const auto* list : {&r.modified, &r.added, &r.deleted}) req.own.insert(list->begin(), list->end());
            truncated = truncated || r.omitted > 0;
            if (r.sceneChanged) req.scene = r.scenePath.empty() ? project_relative(scenePath_, projectDir_) : r.scenePath;
        }
        if (!req.scene.empty()) req.own.insert(req.scene);
        // Other chats' runs that were going while this one was, or came after it: whatever they changed is in the checkpoint's
        // diff too. (A run saved before chats could run side by side has no start time: it is treated as alone.)
        std::vector<RunRecord> others;
        if (c.startedAt > 0) {
            for (AiChat& t : chat_.tabs) {
                if (t.id == chatId) continue;
                RunRecord rec;
                rec.chat = t.title.empty() ? "New chat" : t.title;
                bool any = false;
                for (const ChatItem& r : t.items) {
                    if (r.kind != ChatItem::Kind::Run || !r.revertedBy.empty() || r.endedAt < c.startedAt) continue;
                    for (const auto* list : {&r.modified, &r.added, &r.deleted}) rec.files.insert(list->begin(), list->end());
                    if (r.sceneChanged && !r.scenePath.empty()) rec.files.insert(r.scenePath);
                    any = true;
                }
                if (const AiRun* running = ai_run_of(t.id); running && running->active()) {
                    const std::set<std::string> touched = aiTouch_.touched(t.id);
                    rec.files.insert(touched.begin(), touched.end());
                    rec.running = true;
                    any = true;
                }
                if (any) others.push_back(std::move(rec));
            }
        }
        req.plan = plan_revert(req.own, req.scene, truncated, others);
    } else if (c.kind == ChatItem::Kind::Revert && !c.isUndo && !c.undone) {
        req.undo = true;
        req.target = c.safetyId;
        // A revert that kept another chat's files is taken back the same way: only the files it restored.
        if (c.scoped && c.omitted == 0) {
            req.plan.whole = false;
            for (const auto* list : {&c.modified, &c.added, &c.deleted}) req.own.insert(list->begin(), list->end());
            req.plan.files.assign(req.own.begin(), req.own.end());
            if (c.sceneChanged) req.scene = c.scenePath;
        }
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
    if (!req.plan.whole) {  // only the run's own files go back: that is what the dialog lists
        const std::set<std::string> scope(req.plan.files.begin(), req.plan.files.end());
        for (std::vector<std::string>* list : {&req.diff.modified, &req.diff.added, &req.diff.deleted})
            std::erase_if(*list, [&](const std::string& f) { return !scope.contains(f); });
    }
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
    const RevertPlan& plan = aiRevert_.plan;
    const ImVec4 amber(1, 0.85f, 0.4f, 1);
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
        ImGui::TextColored(amber, "This is not the newest run: the %d later run(s) are taken back too.", aiRevert_.laterRuns);
    // Other chats' runs changed files too (they ran at the same time, or after this one): never silently clobbered.
    const bool contested = !plan.shared.empty() || plan.sceneShared;
    if (!plan.whole && !undo) {
        ImGui::TextColored(amber, "Other chats worked in this project at the same time, so only the files this run changed go back; "
                                  "the rest stay as they are.");
    } else if (plan.whole && !undo && !plan.shared.empty()) {
        ImGui::TextColored(amber, "This run's file list is too long to tell its files from those of other chats: everything goes back, "
                                  "including files other chats changed (listed below).");
    }
    if (!plan.running.empty()) {
        std::string names;
        for (const std::string& n : plan.running) names += (names.empty() ? "" : ", ") + std::string("\"") + n + "\"";
        ImGui::TextColored(amber, "Still running: %s. Their edits to the files and the scene below are not undone unless you choose so.", names.c_str());
    }
    if (contested) {
        ImGui::TextColored(amber, "Another chat's run also changed:");
        const std::size_t shown = std::min<std::size_t>(plan.shared.size(), 8);
        for (std::size_t i = 0; i < shown; ++i) {
            std::string who;
            for (const std::string& c : plan.shared[i].chats) who += (who.empty() ? "" : ", ") + std::string("\"") + c + "\"";
            ImGui::BulletText("%s  (%s)", plan.shared[i].file.c_str(), who.c_str());
        }
        if (plan.shared.size() > shown) ImGui::TextDisabled("   ... and %d more", static_cast<int>(plan.shared.size() - shown));
        if (plan.sceneShared) ImGui::TextColored(amber, "The open scene was edited by another chat as well.");
    } else {
        ImGui::TextColored(amber, "Anything you edited by hand in these files since then is lost.");
    }
    ImGui::TextDisabled("The scene goes back as one Undo step (Ctrl+Z). A safety checkpoint is saved first, so you can take this back.");
    ImGui::PopTextWrapPos();
    ImGui::Spacing();
    const bool keepable = contested && !plan.whole && !undo;  // two ways to revert: keep their changes, or take those files back too
    if (ImGui::Button(undo ? "Undo revert" : keepable ? "Revert, keep their changes" : "Revert")) {
        ImGui::CloseCurrentPopup();
        ai_revert_apply(!keepable);
    }
    at_track("ai:revert:confirm");
    if (keepable) {
        ImGui::SetItemTooltip("Puts back the files only this run changed. The files listed above, and the open scene if another chat edited it, stay as they are now.");
        ImGui::SameLine();
        if (ImGui::Button("Revert including those files")) {
            ImGui::CloseCurrentPopup();
            ai_revert_apply(true);
        }
        at_track("ai:revert:confirm-all");
        ImGui::SetItemTooltip("Also puts back the listed files to how they were before this run: the other chat's changes to them are lost.");
    }
    ImGui::SameLine();
    if (ImGui::Button("Cancel")) {
        ImGui::CloseCurrentPopup();
        aiRevert_ = {};
    }
    at_track("ai:revert:cancel");
    ImGui::EndPopup();
}

void Editor::ai_revert_apply(bool includeShared) {
    const AiRevertRequest req = std::exchange(aiRevert_, AiRevertRequest{});
    if (!engine_ || ai_chat_busy(req.chatId) || play_ != PlayState::Edit) return;
    AiChat* chat = chat_.find(req.chatId);
    if (!chat || req.item < 0 || static_cast<std::size_t>(req.item) >= chat->items.size()) return;

    // Which files go back. The whole checkpoint, or (other chats involved) this run's files, minus those another chat also
    // changed unless the user asked for them.
    std::optional<std::vector<std::string>> only;
    std::vector<std::string> kept;  // contested files that stay as they are
    bool restoreScene = true;
    if (!req.plan.whole) {
        std::vector<std::string> files;
        std::set<std::string> contested;
        for (const SharedFile& s : req.plan.shared) contested.insert(s.file);
        for (const std::string& f : req.plan.files) {
            if (!includeShared && contested.contains(f)) kept.push_back(f);
            else files.push_back(f);
        }
        only = std::move(files);
        // The world is one: a run that did not edit the scene leaves it, and so does one whose scene another chat edited too.
        restoreScene = !req.scene.empty() && (includeShared || !req.plan.sceneShared);
    }

    // The world as it is now: it becomes the first Undo step and what "Undo revert" brings back.
    const Json worldBefore = save_scene(world());
    const bool dirtyBefore = dirty_;
    const std::string pathBefore = scenePath_;

    auto restored = checkpoint_restore(projectDir_, req.target, only);
    if (!restored.ok()) {
        notify("Revert failed: " + restored.error().to_string(), 2);
        return;
    }
    const std::string safety = restored.value().safetyId;

    // The files changed under the engine: scripts re-import, the Project panel lists again, then the world.
    engine_->scripts().refresh_modules(true);
    project_files_changed();
    auto remembered = std::find_if(aiScenes_.begin(), aiScenes_.end(), [&](const SceneAtCheckpoint& s) { return s.id == req.target; });
    if (restoreScene && remembered != aiScenes_.end() && remembered->scenePath == scenePath_) {
        undo_.push_back(worldBefore);
        if (undo_.size() > 100) undo_.erase(undo_.begin());
        redo_.clear();
        restore_scene(remembered->scene);
        dirty_ = remembered->dirty;
        lastEditKey_.clear();
    } else if (restoreScene) {
        reload_scene_from_disk(true);  // after a restart the in-memory scene is gone: the restored file is the scene
    } else if (only && std::ranges::find(*only, project_relative(scenePath_, projectDir_)) != only->end()) {
        reload_scene_from_disk(true);  // the open scene's file was restored but the world is left alone: show the file
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
    it.scoped = bool(only);
    if (req.undo) {
        it.isUndo = true;
        it.safetyId = source.safetyId;  // pairs it with the Revert it takes back (revert_line)
        source.undone = true;
        for (ChatItem& run : chat->items)
            if (run.kind == ChatItem::Kind::Run && run.revertedBy == source.safetyId) run.revertedBy.clear();
        it.text = "Undid the revert: " + std::to_string(file_count(it)) + " file(s) are as the run left them.";
    } else {
        it.safetyId = safety;
        it.sceneChanged = restoreScene && source.sceneChanged;
        if (it.sceneChanged) it.scenePath = req.scene;
        for (std::size_t i = static_cast<std::size_t>(req.item); i < chat->items.size(); ++i)
            if (chat->items[i].kind == ChatItem::Kind::Run && chat->items[i].revertedBy.empty()) chat->items[i].revertedBy = safety;
        it.text = "Reverted: " + std::to_string(file_count(it)) + " file(s) went back to how they were before the run" +
                  (it.sceneChanged ? ", and the open scene with them." : ".");
        if (!kept.empty() || (!restoreScene && req.plan.sceneShared && !req.scene.empty())) {
            it.text += " Kept as they are now, because another chat also changed them:";
            for (std::size_t i = 0; i < kept.size() && i < 6; ++i) it.text += (i ? ", " : " ") + kept[i];
            if (kept.size() > 6) it.text += " and " + std::to_string(kept.size() - 6) + " more";
            if (!restoreScene && req.plan.sceneShared) it.text += std::string(kept.empty() ? " " : "; ") + "the open scene";
            it.text += ".";
        }
    }
    chat->items.push_back(std::move(it));
    chat->scrollDown = true;
    chat->updated = static_cast<i64>(std::time(nullptr));
    chat_.save(*chat);
    chat_.save_open_list();
    notify(req.undo ? "Revert undone" : "Run reverted (Ctrl+Z undoes the scene part)");
}

void Editor::draw_ai_run_item(ChatItem& c, AiChat& chat, int index) {
    const bool disabled = ai_chat_busy(chat.id) || play_ != PlayState::Edit;
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
