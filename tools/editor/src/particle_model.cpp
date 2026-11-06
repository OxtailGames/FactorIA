// The Particle panel's model (particle_model.h): the open effect document, what it parses to, the edits as vfx.edit calls and the undo steps.
#include "particle_model.h"

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "inspector_model.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

ParticleModel::ParticleModel(std::string projectDir, ParticleCommandFn call) : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

std::string ParticleModel::title() const {
    const auto slash = rel_.find_last_of('/');
    return slash == std::string::npos ? rel_ : rel_.substr(slash + 1);
}

std::string ParticleModel::read_text() const {
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) return {};
    auto text = fs::read_text(abs->generic_string());
    return text.ok() ? *text : std::string();
}

bool ParticleModel::write_text(const std::string& text) {
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        status_ = abs.error().message;
        return false;
    }
    // fs::write_bytes replaces the file atomically, so an undo never leaves half a document, and says why when it cannot (a file open elsewhere).
    if (auto w = fs::write_bytes(abs->generic_string(), text.data(), text.size()); !w.ok()) {
        status_ = "Cannot write " + rel_ + ": " + w.error().message + (w.error().hint.empty() ? "" : " " + w.error().hint);
        return false;
    }
    return true;
}

bool ParticleModel::open(const std::string& rel) {
    if (!ends_with(to_lower(rel), ".vfx.json")) {
        error_ = "'" + rel + "' is not an effect document (*.vfx.json).";
        return false;
    }
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        error_ = "'" + rel + "' does not exist in the project.";
        return false;
    }
    preview_ = false;
    conflict_ = false;
    rel_ = rel;
    text_.clear();
    status_.clear();
    load_from_disk();
    return true;
}

void ParticleModel::close() {
    rel_.clear();
    json_ = Json();
    doc_.reset();
    issues_.clear();
    valid_ = false;
    error_.clear();
    text_.clear();
    preview_ = false;
}

bool ParticleModel::load_from_disk() {
    preview_ = false;
    doc_.reset();
    issues_.clear();
    auto abs = resolve_project_path(projectDir_, rel_);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        valid_ = false;
        error_ = "'" + rel_ + "' does not exist.";
        json_ = Json();
        stampTime_ = 0;
        stampSize_ = 0;
        return false;
    }
    conflict_ = false;
    stampTime_ = fs::host_modified_time(*abs);
    stampSize_ = stdfs::file_size(*abs, ec);
    const std::string text = read_text();
    if (text != text_) {
        text_ = text;
        ++docRev_;
    }
    auto json = parse_json(text_, rel_);
    if (!json.ok()) {
        valid_ = false;
        error_ = json.error().message + (json.error().hint.empty() ? "" : " " + json.error().hint);
        json_ = Json();
        return false;
    }
    json_ = std::move(*json);
    valid_ = true;
    error_.clear();
    parse_shown();
    return true;
}

void ParticleModel::parse_shown() {
    std::vector<VfxIssue> issues;
    auto doc = parse_vfx(shown_json(), rel_, &issues);
    issues_ = std::move(issues);
    if (doc.ok()) {
        doc_ = *doc;
        if (!preview_) error_.clear();
    } else if (!preview_) {
        doc_.reset();   // the saved file is not an effect: nothing plays, the issues say why
        error_ = doc.error().message;
    }
    // While a value is dragged, a value that does not make a valid effect keeps the last good document playing.
}

bool ParticleModel::poll_external() {
    // After a refused undo/redo the user decides (Reload): reading the file here would clear the warning in whatever frame the poll falls.
    if (!is_open() || preview_ || conflict_) return false;
    auto abs = resolve_project_path(projectDir_, rel_);
    std::error_code ec;
    if (!abs.ok()) return false;
    const bool exists = stdfs::is_regular_file(*abs, ec);
    const std::int64_t t = exists ? fs::host_modified_time(*abs) : 0;
    const std::uintmax_t sz = exists ? stdfs::file_size(*abs, ec) : 0;
    // The file's time moves in steps (about 15 ms on Windows), so a same-size edit right after our own read can keep both numbers: the
    // content is compared too (the file is a few KB, polled every 20 frames).
    if (t == stampTime_ && sz == stampSize_ && (!exists || read_text() == text_)) return false;
    load_from_disk();
    status_ = "Reloaded: the file changed on disk.";
    return true;
}

bool ParticleModel::reload() {
    if (!is_open()) return false;
    text_.clear();
    load_from_disk();
    status_ = "Reloaded.";
    return true;
}

int ParticleModel::take_stale_step() {
    const int id = staleStep_;
    staleStep_ = 0;
    return id;
}

std::vector<ParticlePartInfo> ParticleModel::parts() const {
    std::vector<ParticlePartInfo> out;
    const Json& j = shown_json();
    if (!j.is_object() || !j.contains("parts") || !j["parts"].is_array()) return out;
    int i = 0;
    for (const Json& p : j["parts"]) {
        ParticlePartInfo info;
        info.index = i++;
        if (p.is_object()) {
            info.type = p.value("type", std::string());
            info.name = p.value("name", std::string());
            info.at = p.contains("at") && p["at"].is_number() ? p["at"].get<double>() : 0.0;
            info.duration = p.contains("duration") && p["duration"].is_number() ? p["duration"].get<double>() : 0.0;
        }
        out.push_back(info);
    }
    return out;
}

ParticleEditOutcome ParticleModel::fail(ParticleEditOutcome out, const std::string& message) {
    out.ok = false;
    out.error = message;
    status_ = message;
    return out;
}

ParticleEditOutcome ParticleModel::create(const std::string& rel) {
    ParticleEditOutcome out;
    CommandResult r = call_("vfx.create", Json::object({{"path", rel}}));
    if (!r.ok) return fail(out, "New effect: " + command_error_text(r.error));
    out.result = r.result;
    if (!open(rel)) return fail(out, error_);
    status_ = "Created " + rel + ".";
    return out;
}

ParticleEditOutcome ParticleModel::run(const std::string& label, const std::string& command, const Json& args) {
    ParticleEditOutcome out;
    if (!is_open()) return fail(out, label + ": no effect is open.");
    if (!valid_) return fail(out, label + ": the file does not load: " + error_);
    cancel_field_preview();
    const std::string before = read_text();
    CommandResult r = call_(command, args);
    if (!r.ok) {
        // vfx.edit writes nothing when it refuses; read the file again so the panel shows what is on disk.
        load_from_disk();
        return fail(out, label + ": " + command_error_text(r.error));
    }
    out.result = r.result;
    load_from_disk();
    const std::string after = text_;
    if (after != before) {
        ParticleStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.label = label;
        s.before = before;
        s.after = after;
        out.step = s.id;
        steps_[s.id] = std::move(s);
    }
    status_ = label;
    return out;
}

ParticleEditOutcome ParticleModel::set_field(const std::string& pointer, const Json& value, const std::string& label) {
    return run(label.empty() ? "Set " + pointer : label, "vfx.edit", Json::object({{"path", rel_}, {"op", "set"}, {"pointer", pointer}, {"value", value}}));
}

ParticleEditOutcome ParticleModel::remove_field(const std::string& pointer, const std::string& label) {
    return run(label.empty() ? "Remove " + pointer : label, "vfx.edit", Json::object({{"path", rel_}, {"op", "remove"}, {"pointer", pointer}}));
}

ParticleEditOutcome ParticleModel::add_item(const std::string& pointer, const Json& value, int index, const std::string& label) {
    Json args = Json::object({{"path", rel_}, {"op", "add"}, {"pointer", pointer}, {"value", value}});
    if (index >= 0) args["index"] = index;
    return run(label.empty() ? "Add to " + pointer : label, "vfx.edit", args);
}

ParticleEditOutcome ParticleModel::move_item(const std::string& pointer, int from, int to, const std::string& label) {
    return run(label.empty() ? "Move in " + pointer : label, "vfx.edit",
               Json::object({{"path", rel_}, {"op", "move"}, {"pointer", pointer}, {"index", from}, {"to", to}}));
}

Json ParticleModel::starter_part(const std::string& type, const std::string& what) {
    if (type == "light")
        return Json::object({{"type", "light"}, {"duration", 0.2}, {"light", Json::object({{"color", "#ffe9a0"}, {"intensity", 1.5}, {"radius", 120}})}});
    if (type == "sound")
        return Json::object({{"type", "sound"}, {"clip", what}});
    if (type == "command")
        return Json::object({{"type", "command"}, {"command", what.empty() ? "feel.shake" : what}, {"args", Json::object()}});
    return Json::object({{"type", "emitter"},
                         {"emitter", Json::object({{"burst", 12}, {"lifetime", 0.6}, {"speed", 100}, {"spread", 180}, {"startSize", 8}, {"endSize", 2}})}});
}

void ParticleModel::preview_field(const std::string& pointer, const Json& value) {
    if (!is_open() || !valid_) return;
    Json copy = json_;
    try {
        const Json::json_pointer ptr(pointer);
        if (!copy.contains(ptr.parent_pointer())) return;
        copy[ptr] = value;
    } catch (const std::exception&) {
        return;
    }
    preview_ = true;
    previewPointer_ = pointer;
    previewValue_ = value;
    previewJson_ = std::move(copy);
    parse_shown();
}

ParticleEditOutcome ParticleModel::commit_field(const std::string& label) {
    if (!preview_) return {};
    const std::string pointer = previewPointer_;
    const Json value = previewValue_;
    const bool differs = !json_.contains(Json::json_pointer(pointer)) || json_.at(Json::json_pointer(pointer)) != value;
    cancel_field_preview();
    if (!differs) return {};
    return set_field(pointer, value, label);
}

void ParticleModel::cancel_field_preview() {
    if (!preview_) return;
    preview_ = false;
    previewPointer_.clear();
    previewValue_ = Json();
    previewJson_ = Json();
    parse_shown();
}

const ParticleStep* ParticleModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string ParticleModel::step_document(int id) const {
    const ParticleStep* s = step(id);
    return s ? s->rel : std::string();
}

bool ParticleModel::apply_step(int id, bool forward) {
    const ParticleStep* s = step(id);
    if (!s) {
        status_ = "That effect edit is no longer remembered.";
        return false;
    }
    if (s->rel != rel_) return false;
    cancel_field_preview();
    // The step restores a whole file. If the file is not what the step left (it was edited outside the editor since), restoring would throw
    // that edit away: refuse, and let the user choose Reload (take the file as it is) or fix it themselves.
    if (read_text() != (forward ? s->before : s->after)) {
        conflict_ = true;
        staleStep_ = id;
        status_ = std::string("Cannot ") + (forward ? "redo" : "undo") + " '" + s->label + "': " + rel_ +
                  " was changed outside the editor since, and this would overwrite that change. Press Reload to take the file as it is.";
        return false;
    }
    if (!write_text(forward ? s->after : s->before)) return false;
    load_from_disk();
    status_ = std::string(forward ? "Redo: " : "Undo: ") + s->label;
    return true;
}

void ParticleModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) {
        if (keep.count(it->first)) ++it;
        else it = steps_.erase(it);
    }
}

}  // namespace fa::editor
