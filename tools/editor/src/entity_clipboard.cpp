// Copy, Cut, Paste and Duplicate of entities (docs/EDITOR.md, "Copy, cut, paste and duplicate"). The work is done by the commands
// scene.copy_entities and scene.paste_entities (tools/authoring/src/scene_clipboard_commands.cpp); this file only chooses what to
// copy (the selection), where the text goes (the system clipboard, so it can be pasted into another editor or a chat), where a paste
// lands (next to the primary), and what is selected afterwards. Every edit goes through Editor::edit_command, so a Cut and a Paste
// are one undo step each.
#include "sokol_app.h"

#include "editor_internal.h"

namespace fa::editor {

void Editor::select_ids(const std::vector<std::string>& ids, const std::string& primary) {
    selection_.set(ids, primary);
    hierAnchor_ = selection_.primary();  // the next Shift click selects from here, and the tree scrolls to it
    hierLastSelected_ = selection_.primary();
}

namespace {

// What the user is told about the references a paste could not keep.
std::string cleared_note(const Json& cleared) {
    if (!cleared.is_array() || cleared.empty()) return {};
    return " " + std::to_string(cleared.size()) +
           (cleared.size() == 1 ? " reference to an entity that is not in this scene was cleared."
                                : " references to entities that are not in this scene were cleared.");
}

std::string count_text(std::size_t n) { return std::to_string(n) + (n == 1 ? " entity" : " entities"); }

}  // namespace

bool Editor::entity_clipboard_keys_active() const {
    if (!engine_ || play_ != PlayState::Edit || ImGui::GetIO().WantTextInput) return false;
    return vpFocused_ || (hierFocusFrame_ != 0 && hierFocusFrame_ + 1 >= uiFrame_);
}

bool Editor::entity_copy() {
    if (!engine_) return false;
    const std::vector<std::string> ids = selection_roots();
    if (ids.empty()) return false;
    Json args = Json::object({{"ids", Json::array()}});
    for (const std::string& id : ids) args["ids"].push_back(id);
    if (!selection_.primary().empty()) args["primary"] = selection_.primary();
    const CommandResult r = engine_->commands().call("scene.copy_entities", args);
    if (!r.ok) {
        notify("Could not copy: " + command_error_text(r.error), 2);
        return false;
    }
    const std::string text = r.result.value("text", std::string());
    if (text.size() + 1 >=
        kClipboardBytes) {  // sokol_app would cut the text, and a Cut would delete what no paste can bring back
        notify("Could not copy: the copy of " + count_text(r.result.value("count", std::size_t(0))) + " is " +
                   std::to_string(text.size() / 1024) + " KB of text and the clipboard holds " +
                   std::to_string(kClipboardBytes / 1024 - 1) +
                   " KB at most. Copy fewer entities, or use scene.copy_entities from a script or the MCP tools. "
                   "Nothing was "
                   "cut.",
               2);
        return false;
    }
    clipboard_set_text(text.c_str());
    return true;
}

void Editor::entity_cut() {
    if (selection_roots().empty() || !entity_copy()) return;
    const std::string what = count_text(selection_roots().size());
    hierarchy_destroy_selection();  // one undo step; Undo brings them back
    notify("Cut " + what + ". Paste puts them back.");
}

void Editor::entity_paste() {
    if (!engine_) return;
    const char* clip = clipboard_has_text() ? clipboard_get_text() : nullptr;
    const std::string text = clip ? clip : "";
    if (text.empty()) {
        notify("Nothing to paste: copy some entities first (Ctrl+C in the Hierarchy or the Viewport).", 1);
        return;
    }
    if (text.find("factoria.entities/") == std::string::npos) {  // ordinary text: say so, ask the command nothing
        notify("The clipboard holds no copied entities: select some in the Hierarchy and copy them (Ctrl+C) first.", 1);
        return;
    }
    // Under the parent of the primary (next to it), or at the top level.
    Json parent = nullptr;
    World& w = world();
    const Entity primary = w.find_by_id(selection().primary());
    if (!primary.is_null())
        if (const Entity p = w.parent(primary); !p.is_null()) parent = w.id_of(p);
    std::string err;
    const CommandResult r = edit_command("hier:paste:" + std::to_string(uiFrame_), "scene.paste_entities",
                                         Json::object({{"text", text}, {"parent", parent}}), &err);
    if (!r.ok) {
        notify("Could not paste: " + err, 2);
        return;
    }
    std::vector<std::string> ids;
    for (const Json& id : r.result["ids"])
        if (id.is_string()) ids.push_back(id.get<std::string>());
    select_ids(ids, r.result.value("primary", std::string()));
    notify("Pasted " + count_text(r.result.value("count", std::size_t(0))) + "." + cleared_note(r.result["cleared"]));
}

void Editor::hierarchy_duplicate_selection() {
    const std::vector<std::string> ids = selection_roots();
    if (ids.empty() || !engine_) return;
    Json copyArgs = Json::object({{"ids", Json::array()}});
    for (const std::string& id : ids) copyArgs["ids"].push_back(id);
    if (!selection_.primary().empty()) copyArgs["primary"] = selection_.primary();
    const CommandResult copied = engine_->commands().call("scene.copy_entities", copyArgs);
    if (!copied.ok) {
        notify("Could not duplicate the entity: " + command_error_text(copied.error), 2);
        return;
    }
    // Each copy goes next to its original, named "<name> copy"; an Entity field inside the set names the copy.
    std::string err;
    const CommandResult r = edit_command(
        "hier:duplicate:" + std::to_string(uiFrame_), "scene.paste_entities",
        Json::object(
            {{"text", copied.result.value("text", std::string())}, {"keepParents", true}, {"nameSuffix", " copy"}}),
        &err);
    if (!r.ok) {
        notify("Could not duplicate the entity: " + err, 2);
        return;
    }
    std::vector<std::string> copies;
    for (const Json& id : r.result["ids"])
        if (id.is_string()) copies.push_back(id.get<std::string>());
    select_ids(copies, r.result.value("primary", std::string()));  // the copy of the primary stays the primary
}

}  // namespace fa::editor
