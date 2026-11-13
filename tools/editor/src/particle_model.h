// The logic of the editor's Particle panel with no ImGui and no window: the effect document being edited (a *.vfx.json file, docs/PARTICLES.md
// "Effect documents"), what it parses to, and the undo steps. particle_panel.cpp draws it and plays it with ParticlePreview; particle_tests.cpp
// and the autotest drive it.
//
// ONE SET OF CODE. Every edit that is kept is a vfx.edit call (a field set, a part added, removed or moved), the same call the Console, an AI or
// a script makes, and a new file is a vfx.create call, so the file on disk is what the commands would have written. A slider or a gradient
// key being dragged only shows the document with that value in memory (the preview plays it); letting go makes the one vfx.edit.
//
// Undo is a table of steps (the text of the file before and after an edit); the editor's undo stack holds only {"$particle": {"step": id}}
// entries that point into it.
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/scene/vfx.h"

namespace fa::editor {

using ParticleCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;

struct ParticleStep {
    int id = 0;
    std::string rel;  // the document the edit was made on
    std::string label;
    std::string before, after;  // the text of the file
};

struct ParticleEditOutcome {
    bool ok = true;
    std::string error;  // what went wrong, with the command's hint
    int step = 0;       // the undo step it recorded (0 = the edit changed nothing on disk)
    Json result;        // the command's result
};

// A short line for a part of the document: "0  emitter  sparks  at 0.00 s".
struct ParticlePartInfo {
    int index = 0;
    std::string type;
    std::string name;
    double at = 0.0;
    double duration = 0.0;
};

class ParticleModel {
public:
    ParticleModel(std::string projectDir, ParticleCommandFn call);

    // ---- the document ---------------------------------------------------------------------------------------------
    bool open(const std::string& rel);  // *.vfx.json; false: error() says why
    void close();
    bool is_open() const { return !rel_.empty(); }
    bool valid() const { return valid_; }  // the file is JSON (it may still not be a valid effect: see issues())
    const std::string& path() const { return rel_; }
    std::string title() const;
    const std::string& error() const { return error_; }
    const std::string& status() const { return status_; }
    void set_status(const std::string& s) { status_ = s; }
    // The document as parsed (or null while it does not parse as an effect); with a field preview applied.
    std::shared_ptr<const VfxDoc> doc() const { return doc_; }
    const std::vector<VfxIssue>& issues() const { return issues_; }
    // The file's JSON as the panel shows it (with a field preview applied) and as saved.
    const Json& shown_json() const { return preview_ ? previewJson_ : json_; }
    const Json& saved_json() const { return json_; }
    std::vector<ParticlePartInfo> parts() const;
    std::uint64_t doc_revision() const { return docRev_; }
    // The file changed on disk behind our back: reads it again. Returns true when it did. Does nothing while conflict() is set (Reload decides).
    bool poll_external();
    bool reload();

    // ---- new effects ------------------------------------------------------------------------------------------------
    // vfx.create at `rel` (not overwriting) and opens it.
    ParticleEditOutcome create(const std::string& rel);

    // ---- edits (vfx.edit): one undo step each ------------------------------------------------------------------------
    ParticleEditOutcome set_field(const std::string& pointer, const Json& value, const std::string& label = "");
    ParticleEditOutcome remove_field(const std::string& pointer, const std::string& label = "");
    ParticleEditOutcome add_item(const std::string& pointer, const Json& value, int index = -1,
                                 const std::string& label = "");
    ParticleEditOutcome move_item(const std::string& pointer, int from, int to, const std::string& label = "");
    // The part to add for each kind (a sound needs the clip; a command the name).
    static Json starter_part(const std::string& type, const std::string& clipOrCommand = "");

    // Slider and key drags: show the document with the value in memory (the preview plays it); commit_field makes it one edit.
    void preview_field(const std::string& pointer, const Json& value);
    bool field_previewing() const { return preview_; }
    const std::string& preview_pointer() const { return previewPointer_; }
    ParticleEditOutcome commit_field(const std::string& label = "");
    void cancel_field_preview();

    // ---- undo -------------------------------------------------------------------------------------------------------
    const ParticleStep* step(int id) const;
    // Restores the file as the step left it (forward) or found it. Refused (false, conflict() true, status() says why) when the file is not
    // what the step expects: it was edited outside the editor, and the restore would overwrite that.
    bool apply_step(int id, bool forward);
    bool conflict() const { return conflict_; }
    // The step whose undo/redo was refused by a conflict (0 when none), once: the file no longer is what it expects, so the editor drops it
    // from its undo and redo stacks when the user reloads (or edits again), and the steps behind it can be used.
    int take_stale_step();
    void retain_steps(const std::set<int>& keep);
    std::size_t step_count() const { return steps_.size(); }
    std::string step_document(int id) const;

private:
    bool load_from_disk();
    void parse_shown();
    ParticleEditOutcome run(const std::string& label, const std::string& command, const Json& args);
    ParticleEditOutcome fail(ParticleEditOutcome out, const std::string& message);
    std::string read_text() const;
    bool write_text(const std::string& text);

    std::string projectDir_;
    ParticleCommandFn call_;
    std::string rel_, error_, status_, text_;
    bool valid_ = false;
    int staleStep_ = 0;  // the step the last refused undo/redo was about, until take_stale_step
    bool conflict_ =
        false;  // the last undo/redo was refused because the file changed outside the editor; cleared when the file is read again
    Json json_;
    std::shared_ptr<const VfxDoc> doc_;
    std::vector<VfxIssue> issues_;
    std::uint64_t docRev_ = 0;
    std::int64_t stampTime_ = 0;
    std::uintmax_t stampSize_ = 0;
    std::map<int, ParticleStep> steps_;
    int nextStep_ = 1;
    bool preview_ = false;
    std::string previewPointer_;
    Json previewValue_, previewJson_;
};

}  // namespace fa::editor
