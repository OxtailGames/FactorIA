// The Music panel's model (music_model.h): the open song, the notes and drum grids of its patterns, the render the panel plays and the undo steps.
// Every edit is a command; this file builds their arguments from what the user did.
#include "music_model.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "inspector_model.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

std::optional<std::string> read_file(const stdfs::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return std::nullopt;
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

std::uint64_t mix_hash(std::uint64_t h, std::uint64_t v) { return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL; }

double now_ms() {
    using clock = std::chrono::steady_clock;  // UI timing only: no simulation reads it
    return std::chrono::duration<double, std::milli>(clock::now().time_since_epoch()).count();
}

bool ends_with_(const std::string& s, const std::string& suffix) { return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0; }

std::string issues_line(const std::vector<SongIssue>& issues) {
    std::string out;
    for (std::size_t i = 0; i < issues.size() && i < 3; ++i) out += (i ? " " : "") + issues[i].pointer + ": " + issues[i].message;
    return out;
}

Json set_pattern_op(const std::string& track, const std::string& pattern) {
    return Json::object({{"op", "set_pattern"}, {"track", track}, {"pattern", pattern}});
}

}  // namespace

// ---- drum grids -----------------------------------------------------------------------------------------------------------------

std::int64_t music_step_ticks(const std::string& step) {
    if (step == "8") return kSongPpq / 2;
    if (step == "16") return kSongPpq / 4;
    if (step == "32") return kSongPpq / 8;
    if (step == "8t") return kSongPpq / 3;
    if (step == "16t") return kSongPpq / 6;
    return 0;
}

int MusicDrumGrid::steps_per_bar(const SongMeter& meter) const {
    const std::int64_t t = music_step_ticks(step);
    return t > 0 ? int(std::max<std::int64_t>(1, meter.barTicks() / t)) : 0;
}

std::string MusicDrumGrid::row(const std::string& lane, const SongMeter& meter) const {
    for (const auto& [name, text] : lanes) {
        if (name != lane) continue;
        std::string out = text;
        out.resize(std::size_t(total_steps(meter)), '.');
        return out;
    }
    return {};
}

char MusicDrumGrid::at(const std::string& lane, int stepIndex, const SongMeter& meter) const {
    const std::string r = row(lane, meter);
    if (stepIndex < 0 || std::size_t(stepIndex) >= r.size()) return '.';
    return r[std::size_t(stepIndex)];
}

void MusicDrumGrid::set(const std::string& lane, int stepIndex, char c, const SongMeter& meter) {
    if (stepIndex < 0 || stepIndex >= total_steps(meter)) return;
    for (auto& [name, text] : lanes)
        if (name == lane) {
            text = row(lane, meter);
            text[std::size_t(stepIndex)] = c;
            return;
        }
    std::string text(std::size_t(total_steps(meter)), '.');
    text[std::size_t(stepIndex)] = c;
    lanes.emplace_back(lane, text);
}

Json MusicDrumGrid::op_fields(const SongMeter& meter) const {
    Json g = Json::object();
    for (const auto& [name, text] : lanes) g[name] = row(name, meter);
    return Json::object({{"grid", g}, {"step", step}, {"bars", bars}});
}

std::optional<MusicDrumGrid> music_drum_grid(const SongPattern& pattern) {
    if (!pattern.grid.is_object() || !pattern.grid.contains("grid") || !pattern.grid["grid"].is_object()) return std::nullopt;
    MusicDrumGrid g;
    g.step = pattern.grid.contains("step") && pattern.grid["step"].is_string() ? pattern.grid["step"].get<std::string>() : "16";
    g.bars = std::max(1, pattern.bars);
    for (auto it = pattern.grid["grid"].begin(); it != pattern.grid["grid"].end(); ++it) {
        if (!it.value().is_string()) continue;
        std::string text;
        for (char c : it.value().get<std::string>()) {
            if (c == ' ' || c == '|') continue;
            text += (c == '-' || c == '_') ? '.' : c;
        }
        g.lanes.emplace_back(it.key(), text);
    }
    return g;
}

bool music_in_scale(const SongDoc& song, int pitch) {
    const std::vector<int> pcs = song.scale_pitch_classes();
    if (pcs.empty()) return true;   // an unknown scale highlights nothing out of key
    const int pc = ((pitch % 12) + 12) % 12;
    return std::find(pcs.begin(), pcs.end(), pc) != pcs.end();
}

// ---- the document ---------------------------------------------------------------------------------------------------------------

MusicModel::MusicModel(std::string projectDir, MusicCommandFn call) : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

MusicModel::~MusicModel() {
    if (running_.valid && running_.future.valid()) running_.future.wait();
}

std::string MusicModel::title() const {
    const std::size_t slash = rel_.find_last_of('/');
    return slash == std::string::npos ? rel_ : rel_.substr(slash + 1);
}

bool MusicModel::open(const std::string& rel) {
    close();
    if (!ends_with_(rel, ".song.json")) {
        error_ = "'" + rel + "' is not a song the panel opens.";
        status_ = error_ + " Open a *.song.json (music.create makes one).";
        return false;
    }
    open_ = true;
    rel_ = rel;
    renderError_.clear();
    const bool ok = load_from_disk();
    request_render();
    return ok;
}

void MusicModel::close() {
    if (running_.valid && running_.future.valid()) running_.future.wait();
    running_ = Running{};
    open_ = false;
    valid_ = false;
    rel_.clear();
    error_.clear();
    status_.clear();
    renderError_.clear();
    json_ = Json();
    text_.clear();
    doc_.reset();
    timeline_.reset();
    src_.reset();
    srcRev_ = failedRev_ = ~0ULL;
    dirty_ = false;
}

bool MusicModel::load_from_disk() {
    doc_.reset();
    timeline_.reset();
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        valid_ = false;
        error_ = abs.error().message;
        return false;
    }
    std::error_code ec;
    if (!stdfs::is_regular_file(*abs, ec)) {
        valid_ = false;
        error_ = "'" + rel_ + "' does not exist.";
        json_ = Json();
        stamp_ = compute_stamp();
        return false;
    }
    auto text = read_file(*abs);
    if (!text) {
        valid_ = false;
        error_ = "Cannot read '" + rel_ + "'.";
        return false;
    }
    if (*text != text_) {
        text_ = *text;
        ++docRev_;
    }
    auto json = parse_json(text_, rel_);
    if (!json.ok()) {
        valid_ = false;
        error_ = json.error().message + (json.error().hint.empty() ? "" : " " + json.error().hint);
        json_ = Json();
        stamp_ = compute_stamp();
        return false;
    }
    json_ = std::move(*json);
    std::vector<SongIssue> issues;
    auto d = parse_song(json_, rel_, &issues);
    if (d.ok()) {
        doc_ = std::move(*d);
        auto tl = expand_song(*doc_);
        if (tl.ok()) timeline_ = std::move(*tl);
        else {
            error_ = tl.error().message + " " + tl.error().hint;
            doc_.reset();
        }
    } else {
        error_ = d.error().message + " " + issues_line(issues);
    }
    valid_ = doc_.has_value();
    if (valid_) error_.clear();
    stamp_ = compute_stamp();
    return valid_;
}

bool MusicModel::reload() {
    if (!is_open()) return false;
    const bool ok = load_from_disk();
    request_render();
    return ok;
}

std::uint64_t MusicModel::compute_stamp() const {
    std::uint64_t h = 1469598103934665603ULL;
    auto abs = resolve_project_path(projectDir_, rel_);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) return h;
    h = mix_hash(h, std::uint64_t(stdfs::file_size(*abs, ec)));
    h = mix_hash(h, std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    return h;
}

bool MusicModel::poll_external() {
    if (!is_open() || compute_stamp() == stamp_) return false;
    load_from_disk();
    request_render();
    status_ = "Reloaded: the file changed on disk.";
    return true;
}

// ---- reading ---------------------------------------------------------------------------------------------------------------------

const SongTrack* MusicModel::track(const std::string& name) const { return doc_ ? doc_->find_track(name) : nullptr; }

const SongPattern* MusicModel::pattern(const std::string& trackName, const std::string& patternName) const {
    const SongTrack* t = track(trackName);
    return t ? t->find_pattern(patternName) : nullptr;
}

std::vector<SongRollNote> MusicModel::notes(const std::string& trackName, const std::string& patternName) const {
    const SongPattern* p = pattern(trackName, patternName);
    return p ? song_roll_notes(*p) : std::vector<SongRollNote>{};
}

std::vector<std::string> MusicModel::pitched_tracks() const {
    std::vector<std::string> out;
    if (doc_)
        for (const SongTrack& t : doc_->tracks)
            if (!t.drums) out.push_back(t.name);
    return out;
}

std::vector<std::string> MusicModel::drum_tracks() const {
    std::vector<std::string> out;
    if (doc_)
        for (const SongTrack& t : doc_->tracks)
            if (t.drums) out.push_back(t.name);
    return out;
}

std::optional<double> MusicModel::pattern_tick(const MusicMap& map, double frame, const std::string& trackName, const std::string& patternName) const {
    if (!doc_ || map.barFrames <= 0.0) return std::nullopt;
    const int si = map.span_at(frame);
    if (si < 0) return std::nullopt;
    const MusicSpan& span = map.spans[std::size_t(si)];
    if (span.section < 0 || std::size_t(span.section) >= doc_->sections.size()) return std::nullopt;
    const SongSection& section = doc_->sections[std::size_t(span.section)];
    if (std::find(section.mute.begin(), section.mute.end(), trackName) != section.mute.end()) return std::nullopt;
    const SongTrack* t = track(trackName);
    if (!t) return std::nullopt;
    const double bar = (frame - span.start) / map.barFrames;
    double at = 0.0;
    for (const SongSectionTrack& st : section.play) {
        if (st.track != trackName) continue;
        for (const SongPlayEntry& e : st.entries) {
            const SongPattern* p = e.pattern.empty() ? nullptr : t->find_pattern(e.pattern);
            const double bars = p ? double(std::max(1, p->bars)) * double(e.repeat) : double(e.repeat);
            if (bar < at + bars) {
                if (!p || p->name != patternName) return std::nullopt;
                return std::fmod(bar - at, double(std::max(1, p->bars))) * double(doc_->meter.barTicks());
            }
            at += bars;
        }
    }
    return std::nullopt;
}

std::string MusicModel::free_name(const std::string& base, const std::vector<std::string>& used) const {
    auto taken = [&](const std::string& n) { return std::find(used.begin(), used.end(), n) != used.end(); };
    if (!taken(base)) return base;
    for (int i = 2; i < 1000; ++i)
        if (!taken(base + std::to_string(i))) return base + std::to_string(i);
    return base;
}

// ---- undo plumbing -----------------------------------------------------------------------------------------------------------------

MusicBlob MusicModel::read_blob(const std::string& rel) {
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) return nullptr;
    auto data = read_file(*abs);
    if (!data) return nullptr;
    return std::make_shared<const std::string>(std::move(*data));
}

bool MusicModel::write_blob(const MusicBlob& blob) {
    auto abs = resolve_project_path(projectDir_, rel_);
    if (!abs.ok()) {
        status_ = abs.error().message;
        return false;
    }
    std::error_code ec;
    if (!blob) {
        stdfs::remove(*abs, ec);
        return true;
    }
    stdfs::create_directories(abs->parent_path(), ec);
    std::ofstream f(*abs, std::ios::binary | std::ios::trunc);
    if (!f || !f.write(blob->data(), std::streamsize(blob->size()))) {
        status_ = "Cannot write " + rel_ + ".";
        return false;
    }
    return true;
}

MusicEditOutcome MusicModel::fail(MusicEditOutcome out, const std::string& message) {
    out.ok = false;
    out.error = message;
    status_ = message;
    return out;
}

MusicEditOutcome MusicModel::run(const std::string& label, const std::function<CommandResult()>& body) {
    MusicEditOutcome out;
    if (!is_open()) return fail(out, label + ": no song is open.");
    if (!valid_ && json_.is_null()) return fail(out, label + ": the file does not load: " + error_);
    // The command writes files and sets the VFS root: let a render on the worker finish first.
    if (running_.valid) running_.future.wait();
    collect();
    MusicBlob before = read_blob(rel_);
    CommandResult r = body();
    if (!r.ok) {
        write_blob(before);   // the command wrote nothing valid; a half-done change would not be an undo step
        load_from_disk();
        return fail(out, label + ": " + command_error_text(r.error));
    }
    out.result = r.result;
    load_from_disk();
    MusicBlob after = read_blob(rel_);
    const bool same = before == after || (before && after && *before == *after);
    if (!same) {
        MusicStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.label = label;
        s.before = std::move(before);
        s.after = std::move(after);
        out.step = s.id;
        steps_[s.id] = std::move(s);
    }
    status_ = label;
    request_render();
    return out;
}

// ---- edits -------------------------------------------------------------------------------------------------------------------------

MusicEditOutcome MusicModel::edit(const std::string& label, const Json& ops) {
    return run(label, [&] { return call_("music.edit", Json::object({{"path", rel_}, {"ops", ops}})); });
}

MusicEditOutcome MusicModel::set_notes(const std::string& trackName, const std::string& patternName, const std::vector<SongRollNote>& notes, int bars, const std::string& label) {
    Json list = Json::array();
    for (const SongRollNote& n : notes) {
        Json j = Json::object({{"pitch", n.pitch}, {"tick", n.tick}, {"duration", n.duration}, {"velocity", n.velocity}});
        if (n.accent) j["accent"] = true;
        if (n.staccato) j["staccato"] = true;
        list.push_back(j);
    }
    if (bars <= 0)
        if (const SongPattern* p = pattern(trackName, patternName)) bars = p->bars;
    Json op = set_pattern_op(trackName, patternName);
    op["notes"] = list;
    if (bars > 0) op["bars"] = bars;
    return edit(label, Json::array({op}));
}

MusicEditOutcome MusicModel::set_grid(const std::string& trackName, const std::string& patternName, const MusicDrumGrid& grid, const std::string& label) {
    Json op = set_pattern_op(trackName, patternName);
    const SongMeter meter = doc_ ? doc_->meter : SongMeter{};
    const Json fields = grid.op_fields(meter);
    for (auto it = fields.begin(); it != fields.end(); ++it) op[it.key()] = it.value();
    return edit(label, Json::array({op}));
}

MusicEditOutcome MusicModel::add_pattern(const std::string& trackName, const std::string& patternName, int bars, bool drums) {
    Json op = set_pattern_op(trackName, patternName);
    if (drums) {
        op["grid"] = Json::object({{"kick", "."}});
        op["step"] = "16";
        op["bars"] = std::max(1, bars);
    } else {
        op["notes"] = std::string("r:1");
        op["bars"] = std::max(1, bars);
    }
    return edit("Add pattern " + patternName, Json::array({op}));
}

MusicEditOutcome MusicModel::remove_pattern(const std::string& trackName, const std::string& patternName) {
    return edit("Remove pattern " + patternName, Json::array({Json::object({{"op", "remove_pattern"}, {"track", trackName}, {"pattern", patternName}})}));
}

MusicEditOutcome MusicModel::set_track(const std::string& trackName, const Json& fields, const std::string& label) {
    Json op = Json::object({{"op", "set_track"}, {"track", trackName}});
    for (auto it = fields.begin(); it != fields.end(); ++it) op[it.key()] = it.value();
    return edit(label.empty() ? "Change track " + trackName : label, Json::array({op}));
}

MusicEditOutcome MusicModel::set_mixer(const Json& fields, const std::string& label) {
    Json op = Json::object({{"op", "set_mixer"}});
    for (auto it = fields.begin(); it != fields.end(); ++it) op[it.key()] = it.value();
    return edit(label.empty() ? "Change the mixer" : label, Json::array({op}));
}

MusicEditOutcome MusicModel::set_song(const Json& fields, const std::string& label) {
    Json op = Json::object({{"op", "set_song"}});
    for (auto it = fields.begin(); it != fields.end(); ++it) op[it.key()] = it.value();
    return edit(label.empty() ? "Change the song" : label, Json::array({op}));
}

MusicEditOutcome MusicModel::set_section(const std::string& section, const Json& fields, const std::string& label) {
    Json op = Json::object({{"op", "set_section"}, {"section", section}});
    for (auto it = fields.begin(); it != fields.end(); ++it) op[it.key()] = it.value();
    return edit(label.empty() ? "Change section " + section : label, Json::array({op}));
}

MusicEditOutcome MusicModel::set_layers(const Json& layers) {
    return edit("Change the layers", Json::array({Json::object({{"op", "set_layers"}, {"layers", layers}})}));
}

MusicEditOutcome MusicModel::generate(const std::string& command, const Json& args) {
    Json a = args;
    a["path"] = rel_;
    a["picture"] = false;
    return run("Generate with " + command, [&] { return call_(command, a); });
}

std::vector<int> MusicModel::chord_pitches(const std::string& name, int octave, std::string* error) {
    Json a = Json::object({{"name", name}, {"octave", std::clamp(octave, 0, 7)}});
    if (valid_) a["path"] = rel_;
    CommandResult r = call_("music.chord", a);
    std::vector<int> out;
    if (!r.ok) {
        if (error) *error = command_error_text(r.error);
        return out;
    }
    if (r.result.contains("midi") && r.result["midi"].is_array())
        for (const Json& m : r.result["midi"])
            if (m.is_number_integer()) out.push_back(m.get<int>());
    if (out.empty() && error) *error = "'" + name + "' is not a chord.";
    return out;
}

Json MusicModel::measure() {
    if (!is_open() || !valid_) return Json();
    if (running_.valid) running_.future.wait();
    collect();
    CommandResult r = call_("music.mix", Json::object({{"path", rel_}}));
    if (!r.ok) {
        status_ = "Measure: " + command_error_text(r.error);
        return Json();
    }
    return r.result;
}

MusicEditOutcome MusicModel::save() {
    MusicEditOutcome out;
    if (!is_open()) return fail(out, "Save: no song is open.");
    if (!valid_) return fail(out, "Save: the file does not load: " + error_);
    if (running_.valid) running_.future.wait();
    collect();
    Json a = Json::object({{"path", rel_}, {"overwrite", overwriteOnSave_}});
    if (!doc_->layers.empty()) a["stems"] = "layers";
    CommandResult r = call_("music.render", a);
    if (!r.ok) return fail(out, "Save: " + command_error_text(r.error));
    out.result = r.result;
    status_ = "Baked " + baked_path() + (doc_->layers.empty() ? "." : " and one stem per layer.");
    return out;
}

std::string MusicModel::baked_path() const {
    if (!ends_with_(rel_, ".song.json")) return {};
    return rel_.substr(0, rel_.size() - 10) + ".wav";
}

// ---- rendering ---------------------------------------------------------------------------------------------------------------------

void MusicModel::request_render() {
    dirty_ = true;
    wait_ = debounce_;
}

void MusicModel::start_job() {
    const std::string dir = projectDir_;
    const SongDoc doc = *doc_;
    const std::string path = rel_;
    // The instruments (a .sfx.json, a SoundFont) are read through the VFS: off the UI thread only while the VFS is already on this project.
    const bool inline_ = !async_ || fs::project_root() != stdfs::path(dir);
    auto work = [doc, path]() -> std::pair<MusicSourcePtr, std::string> {
        auto tl = expand_song(doc);
        if (!tl.ok()) return {nullptr, tl.error().message + (tl.error().hint.empty() ? "" : " " + tl.error().hint)};
        auto src = music_render_source(doc, *tl, path);
        if (!src.ok()) return {nullptr, src.error().message + (src.error().hint.empty() ? "" : " " + src.error().hint)};
        return {MusicSourcePtr(*src), ""};
    };
    running_.future = std::async(inline_ ? std::launch::deferred : std::launch::async, std::move(work));
    running_.rev = docRev_;
    running_.startedMs = now_ms();
    running_.valid = true;
}

void MusicModel::collect() {
    if (!running_.valid) return;
    if (running_.future.wait_for(std::chrono::seconds(0)) == std::future_status::timeout) return;
    auto [src, error] = running_.future.get();
    running_.valid = false;
    renderMs_ = now_ms() - running_.startedMs;
    ++renders_;
    if (src) {
        src_ = std::move(src);
        srcRev_ = running_.rev;
        renderError_.clear();
    } else {
        failedRev_ = running_.rev;
        renderError_ = error;
    }
}

bool MusicModel::busy() const {
    if (running_.valid) return true;
    if (!is_open() || !valid_) return false;
    return srcRev_ != docRev_ && failedRev_ != docRev_;
}

void MusicModel::tick() {
    if (!is_open()) return;
    collect();
    if (running_.valid || !valid_) return;
    if (srcRev_ == docRev_ || failedRev_ == docRev_) {
        dirty_ = false;
        return;
    }
    if (wait_ > 0) {
        --wait_;
        return;
    }
    dirty_ = false;
    start_job();
}

void MusicModel::settle() {
    for (int i = 0; i < 400; ++i) {
        wait_ = 0;
        tick();
        if (running_.valid) {
            running_.future.wait();
            continue;
        }
        if (!busy()) return;
    }
}

// ---- undo ----------------------------------------------------------------------------------------------------------------------------

const MusicStep* MusicModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string MusicModel::step_document(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? std::string() : it->second.rel;
}

bool MusicModel::apply_step(int id, bool forward) {
    auto it = steps_.find(id);
    if (it == steps_.end()) {
        status_ = "That music edit is no longer remembered.";
        return false;
    }
    const MusicStep& s = it->second;
    if (running_.valid) running_.future.wait();
    collect();
    const std::string keep = rel_;
    rel_ = s.rel;   // write_blob writes the file the step belongs to
    const bool ok = write_blob(forward ? s.after : s.before);
    rel_ = keep;
    if (!ok) return false;
    if (s.rel == rel_) {
        load_from_disk();
        request_render();
    }
    status_ = std::string(forward ? "Redo: " : "Undo: ") + s.label;
    return true;
}

void MusicModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) {
        if (keep.count(it->first)) ++it;
        else it = steps_.erase(it);
    }
}

}  // namespace fa::editor
