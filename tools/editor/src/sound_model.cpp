// The Sound panel's model (sound_model.h): the open sound, its renders, the knobs, the variants, the A/B slots, the chain of an audio document, the loop
// points and the undo steps. Every edit is a command; this file builds their arguments from what the user did.
#include "sound_model.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/audio_doc.h"
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

std::uint64_t mix(std::uint64_t h, std::uint64_t v) {
    return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL;
}

double now_ms() {
    using clock = std::chrono::steady_clock;  // UI timing only: no simulation reads it
    return std::chrono::duration<double, std::milli>(clock::now().time_since_epoch()).count();
}

bool ends_with_(const std::string& s, const std::string& suffix) {
    return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

std::string without_suffix(const std::string& s, const std::string& suffix) {
    return ends_with_(s, suffix) ? s.substr(0, s.size() - suffix.size()) : s;
}

// The text of the issues of a patch / document that does not parse.
std::string issues_line(const std::vector<SfxIssue>& issues) {
    std::string out;
    for (std::size_t i = 0; i < issues.size() && i < 3; ++i)
        out += (i ? " " : "") + issues[i].pointer + ": " + issues[i].message;
    return out;
}

// A value for a required field that has no default: the lowest allowed value, or the first choice.
Json required_value(const AudioFieldInfo& f) {
    if (f.def) return *f.def;
    if (!f.choices.empty()) return f.choices.front();
    if (f.type == "boolean") return false;
    if (f.type == "string" || f.type == "path") return "";
    if (f.type == "bands") return Json::array();
    if (f.type == "integer") return f.min ? Json(static_cast<long long>(*f.min)) : Json(0);
    return f.min ? Json(*f.min) : Json(0.0);
}

}  // namespace

// ---- renders -------------------------------------------------------------------------------------------------------------

float SoundRender::mid(std::size_t i) const {
    if (channels <= 1) return i < samples.size() ? samples[i] : 0.0f;
    const std::size_t at = i * 2;
    return at + 1 < samples.size() ? 0.5f * (samples[at] + samples[at + 1]) : 0.0f;
}

SoundRenderPtr make_sound_render(const RenderedSound& sound) {
    static std::uint64_t nextId = 1;
    auto r = std::make_shared<SoundRender>();
    r->id = nextId++;
    r->rate = sound.sampleRate;
    r->channels = sound.channels;
    r->samples = sound.samples;
    r->lufs = sound.lufs;
    r->peakDb = sound.peakDb;
    r->loop = sound.loop;
    r->steps = sound.steps;
    r->truncated = sound.truncated;
    r->inputs = sound.inputs;
    const std::size_t frames = r->frames();
    r->seconds = r->rate > 0 ? double(frames) / double(r->rate) : 0.0;
    if (frames > 0) {
        const std::size_t blocks = (frames + std::size_t(r->peakBlock) - 1) / std::size_t(r->peakBlock);
        r->peakMin.assign(blocks, 0.0f);
        r->peakMax.assign(blocks, 0.0f);
        std::vector<float> monoSamples(frames);
        for (std::size_t b = 0; b < blocks; ++b) {
            float lo = 1e9f, hi = -1e9f;
            const std::size_t from = b * std::size_t(r->peakBlock),
                              to = std::min(frames, from + std::size_t(r->peakBlock));
            for (std::size_t i = from; i < to; ++i) {
                const float v = r->mid(i);
                monoSamples[i] = v;
                lo = std::min(lo, v);
                hi = std::max(hi, v);
            }
            r->peakMin[b] = lo;
            r->peakMax[b] = hi;
        }
        SfxAudio mono;
        mono.sampleRate = r->rate;
        mono.samples = std::move(monoSamples);
        r->centroidHz = sfx_centroid_hz(mono);
        r->riseSeconds = sfx_rise_seconds(mono);
        DecodedAudio decoded;
        decoded.channels = r->channels;
        decoded.rate = r->rate;
        decoded.samples = r->samples;
        r->view = audio_view_metrics(decoded);
        const int columns = std::clamp(int(r->seconds * 120.0), 96, 1100);
        r->spectrogram = audio_spectrogram(decoded, columns, 128);
    }
    return r;
}

std::string sound_slot_label(const SoundSlot& s) {
    switch (s.kind) {
        case SoundSlotKind::Current: return "Current";
        case SoundSlotKind::Variant: return "Variant " + std::to_string(s.variant);
        case SoundSlotKind::Before: return "Before the last edit";
        case SoundSlotKind::Baked: return "Baked file";
    }
    return "";
}

std::pair<double, double> sound_level_match(double lufsA, double lufsB) {
    if (lufsA <= -69.0 || lufsB <= -69.0) return {0.0, 0.0};
    const double d = lufsA - lufsB;  // > 0: A is louder
    return d > 0 ? std::pair<double, double>{-d, 0.0} : std::pair<double, double>{0.0, d};
}

// ---- the document --------------------------------------------------------------------------------------------------------

SoundModel::SoundModel(std::string projectDir, SoundCommandFn call)
    : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

SoundModel::~SoundModel() {
    if (running_.valid && running_.future.valid()) running_.future.wait();
}

std::string SoundModel::title() const {
    const std::size_t slash = rel_.find_last_of('/');
    return slash == std::string::npos ? rel_ : rel_.substr(slash + 1);
}

bool SoundModel::open(const std::string& rel) {
    close();
    SoundKind k = SoundKind::None;
    if (ends_with_(rel, ".sfx.json"))
        k = SoundKind::Patch;
    else if (ends_with_(rel, ".audio.json"))
        k = SoundKind::Document;
    else {
        const std::string ext = to_lower(stdfs::path(rel).extension().string());
        if (ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa") k = SoundKind::File;
    }
    if (k == SoundKind::None) {
        error_ = "'" + rel + "' is not a sound the panel opens.";
        status_ = error_ + " Open a .sfx.json patch, an .audio.json document or a .wav/.ogg file.";
        return false;
    }
    kind_ = k;
    rel_ = rel;
    renderError_.clear();
    const bool ok = load_from_disk();
    request_render();
    return ok;
}

void SoundModel::close() {
    if (running_.valid && running_.future.valid()) running_.future.wait();
    running_ = Running{};
    kind_ = SoundKind::None;
    rel_.clear();
    error_.clear();
    status_.clear();
    renderError_.clear();
    valid_ = false;
    json_ = Json();
    text_.clear();
    results_.clear();
    extras_.clear();
    current_.reset();
    before_.reset();
    baked_.reset();
    macroPreview_.clear();
    jsonPreview_ = false;
    loopPreview_.reset();
    dirty_ = false;
    patch_.reset();
    doc_.reset();
    stopAfter_ = -1;
    mainKey_.clear();
}

void SoundModel::apply_loaded_text(const std::string& text) {
    text_ = text;
    ++docRev_;
}

bool SoundModel::load_from_disk() {
    jsonPreview_ = false;
    patch_.reset();
    doc_.reset();
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
    if (kind_ == SoundKind::File) {
        valid_ = true;
        error_.clear();
        stamp_ = compute_stamp();
        return true;
    }
    auto text = read_file(*abs);
    if (!text) {
        valid_ = false;
        error_ = "Cannot read '" + rel_ + "'.";
        return false;
    }
    if (*text != text_) apply_loaded_text(*text);
    auto json = parse_json(text_, rel_);
    if (!json.ok()) {
        valid_ = false;
        error_ = json.error().message + (json.error().hint.empty() ? "" : " " + json.error().hint);
        json_ = Json();
        stamp_ = compute_stamp();
        return false;
    }
    json_ = std::move(*json);
    std::vector<SfxIssue> issues;
    if (kind_ == SoundKind::Patch) {
        auto p = parse_sfx(json_, rel_, &issues);
        if (p.ok())
            patch_ = std::move(*p);
        else
            error_ = p.error().message + " " + issues_line(issues);
        valid_ = p.ok();
    } else {
        auto d = parse_audio_doc(json_, rel_, &issues);
        if (d.ok())
            doc_ = std::move(*d);
        else
            error_ = d.error().message + " " + issues_line(issues);
        valid_ = d.ok();
    }
    if (valid_) error_.clear();
    stamp_ = compute_stamp();
    return valid_;
}

bool SoundModel::reload() {
    if (!is_open()) return false;
    const bool ok = load_from_disk();
    results_.clear();
    request_render();
    return ok;
}

std::uint64_t SoundModel::compute_stamp() const {
    std::uint64_t h = 1469598103934665603ULL;
    std::set<std::string> paths;
    if (!rel_.empty()) paths.insert(rel_);
    if (current_) paths.insert(current_->inputs.begin(), current_->inputs.end());
    for (const std::string& p : paths) {
        auto abs = resolve_project_path(projectDir_, p);
        std::error_code ec;
        if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) continue;
        for (char c : p) h = mix(h, std::uint64_t(static_cast<unsigned char>(c)));
        h = mix(h, std::uint64_t(stdfs::file_size(*abs, ec)));
        h = mix(h, std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    }
    return h;
}

bool SoundModel::poll_external() {
    if (!is_open() || jsonPreview_ || !macroPreview_.empty()) return false;
    if (compute_stamp() == stamp_) return false;
    const std::string old = text_;
    load_from_disk();
    results_.clear();
    request_render();
    status_ = "Reloaded: the file changed on disk.";
    (void)old;
    return true;
}

// ---- rendering -----------------------------------------------------------------------------------------------------------

SoundSpec SoundModel::main_spec() const {
    SoundSpec spec;
    spec.file = rel_;
    spec.seed = seed_;
    switch (kind_) {
        case SoundKind::Patch:
            spec.kind = SoundSpec::Kind::Patch;
            spec.json = shown_json();
            spec.macros = macroPreview_;
            break;
        case SoundKind::Document:
            spec.kind = SoundSpec::Kind::Document;
            spec.json = shown_json();
            spec.seedSet = seed_ != 0;
            spec.stopAfter = stopAfter_;
            break;
        default:
            spec.kind = SoundSpec::Kind::File;
            spec.maxSeconds = 30.0;
            break;
    }
    return spec;
}

std::string SoundModel::key_of(const SoundSpec& spec) const {
    std::string k = std::to_string(int(spec.kind)) + "|" + spec.file + "|" + std::to_string(spec.seed) + "|" +
                    std::to_string(spec.seedSet) + "|" + std::to_string(spec.variant) + "|" +
                    std::to_string(spec.stopAfter) + "|";
    for (const auto& [n, v] : spec.macros) k += n + "=" + std::to_string(v) + ",";
    if (!spec.json.is_null()) k += "|" + spec.json.dump();
    return k;
}

void SoundModel::request_render() {
    if (!is_open()) return;
    mainKey_ = key_of(main_spec());
    auto it = results_.find(mainKey_);
    if (it != results_.end()) {
        if (it->second.render) {
            current_ = it->second.render;
            renderError_.clear();
        } else {
            renderError_ = it->second.error;
        }
        dirty_ = false;
        return;
    }
    dirty_ = true;
    wait_ = debounce_;
}

void SoundModel::set_render_seed(std::uint64_t seed) {
    if (seed == seed_) return;
    seed_ = seed;
    request_render();
}

void SoundModel::set_stop_after(int index) {
    if (index == stopAfter_) return;
    stopAfter_ = index;
    request_render();
}

SoundRenderPtr SoundModel::current() const { return current_; }

bool SoundModel::current_is_fresh() const {
    auto it = results_.find(mainKey_);
    return it != results_.end() && it->second.render && it->second.render == current_;
}

void SoundModel::start_job(const std::string& key, SoundSpec spec) {
    const std::string dir = projectDir_;
    // A document or a file reads the project through the VFS: off the UI thread only while the VFS is already on this project.
    const bool inline_ = !async_ || (spec.kind != SoundSpec::Kind::Patch && fs::project_root() != stdfs::path(dir));
    auto work = [spec = std::move(spec), dir]() -> std::pair<SoundRenderPtr, std::string> {
        auto r = render_sound(spec, dir);
        if (!r.ok()) return {nullptr, r.error().message + (r.error().hint.empty() ? "" : " " + r.error().hint)};
        return {make_sound_render(*r), ""};
    };
    running_.future = std::async(inline_ ? std::launch::deferred : std::launch::async, std::move(work));
    running_.key = key;
    running_.startedMs = now_ms();
    running_.valid = true;
}

void SoundModel::collect() {
    if (!running_.valid) return;
    if (running_.future.wait_for(std::chrono::seconds(0)) == std::future_status::timeout) return;
    auto [render, error] = running_.future.get();
    running_.valid = false;
    Entry e;
    e.render = std::move(render);
    e.error = std::move(error);
    if (running_.key == mainKey_) {
        renderMs_ = now_ms() - running_.startedMs;
        ++renders_;
        if (e.render) {
            current_ = e.render;
            renderError_.clear();
            stamp_ = compute_stamp();
        } else {
            renderError_ = e.error;
        }
    }
    results_[running_.key] = std::move(e);
    if (results_.size() > 48) {
        for (auto it = results_.begin(); it != results_.end();) {
            if (it->first == mainKey_ || extras_.count(it->first))
                ++it;
            else
                it = results_.erase(it);
        }
    }
}

bool SoundModel::busy() const {
    if (running_.valid) return true;
    if (!is_open()) return false;
    if (dirty_ && !results_.count(mainKey_)) return true;
    for (const auto& [key, spec] : extras_)
        if (!results_.count(key)) return true;
    return false;
}

void SoundModel::tick() {
    if (!is_open()) return;
    collect();
    if (!results_.count(mainKey_) && !dirty_ && !running_.valid) {
        dirty_ = true;
        wait_ = 0;
    }
    if (running_.valid) return;
    if (dirty_) {
        if (results_.count(mainKey_)) {
            dirty_ = false;
        } else if (wait_ > 0) {
            --wait_;
            return;
        } else {
            dirty_ = false;
            start_job(mainKey_, main_spec());
            return;
        }
    }
    for (const auto& [key, spec] : extras_) {
        if (results_.count(key)) continue;
        start_job(key, spec);
        return;
    }
}

void SoundModel::settle() {
    for (int i = 0; i < 400; ++i) {
        wait_ = 0;
        tick();
        if (running_.valid) {
            running_.future.wait();
            continue;
        }
        if (!busy()) break;
    }
}

SoundRenderPtr SoundModel::variant(int n) {
    if (kind_ != SoundKind::Patch || !patch_ || n < 1 || n > patch_->variations.count) return nullptr;
    SoundSpec spec = main_spec();
    spec.macros.clear();
    spec.json = json_;
    spec.variant = n - 1;
    const std::string key = key_of(spec);
    extras_[key] = spec;
    auto it = results_.find(key);
    return it == results_.end() ? nullptr : it->second.render;
}

SoundRenderPtr SoundModel::loop_ghost() {
    if (kind_ != SoundKind::Document) return nullptr;
    const int li = loop_step();
    if (li < 0) return nullptr;
    SoundSpec spec = main_spec();
    spec.json = json_;
    spec.stopAfter = li - 1;
    if (li == 0) return nullptr;
    const std::string key = key_of(spec);
    extras_[key] = spec;
    auto it = results_.find(key);
    return it == results_.end() ? nullptr : it->second.render;
}

std::string SoundModel::baked_path() const {
    if (kind_ == SoundKind::Patch) return without_suffix(rel_, ".sfx.json") + ".wav";
    if (kind_ == SoundKind::Document && doc_) return audio_document_output(*doc_, rel_);
    if (kind_ == SoundKind::File) return rel_;
    return "";
}

SoundRenderPtr SoundModel::baked() {
    if (kind_ == SoundKind::None || kind_ == SoundKind::File) return nullptr;
    const std::string path = baked_path();
    auto abs = resolve_project_path(projectDir_, path);
    std::error_code ec;
    if (path.empty() || !abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        baked_.reset();
        bakedStamp_ = ~0ULL;
        return nullptr;
    }
    std::uint64_t h = mix(mix(1469598103934665603ULL, std::uint64_t(stdfs::file_size(*abs, ec))),
                          std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    if (baked_ && h == bakedStamp_) return baked_;
    SoundSpec spec;
    spec.kind = SoundSpec::Kind::File;
    spec.file = path;
    spec.maxSeconds = 30.0;
    auto r = render_sound(spec, projectDir_);
    if (!r.ok()) {
        baked_.reset();
        return nullptr;
    }
    baked_ = make_sound_render(*r);
    bakedStamp_ = h;
    return baked_;
}

SoundRenderPtr SoundModel::slot(const SoundSlot& s) {
    switch (s.kind) {
        case SoundSlotKind::Current: return current_;
        case SoundSlotKind::Variant: return variant(s.variant);
        case SoundSlotKind::Before: return before_;
        case SoundSlotKind::Baked: return baked();
    }
    return nullptr;
}

// ---- patches: knobs, variants ----------------------------------------------------------------------------------------------

std::vector<SoundMacro> SoundModel::macros() const {
    std::vector<SoundMacro> out;
    if (kind_ != SoundKind::Patch || !patch_) return out;
    for (const SfxMacroInfo& m : sfx_macros()) {
        SoundMacro k;
        k.name = m.name;
        k.what = m.what;
        k.value = patch_->macro_value(m.name);
        k.shown = k.value;
        out.push_back(k);
    }
    for (const SfxMacroDef& d : patch_->macroDefs) {
        auto it = std::find_if(out.begin(), out.end(), [&](const SoundMacro& k) { return k.name == d.name; });
        if (it != out.end()) continue;
        SoundMacro k;
        k.name = d.name;
        k.what = d.doc;
        k.value = d.value;
        k.shown = d.value;
        k.builtin = false;
        out.push_back(k);
    }
    for (SoundMacro& k : out) {
        auto p = macroPreview_.find(k.name);
        if (p != macroPreview_.end()) k.shown = p->second;
    }
    return out;
}

void SoundModel::preview_macro(const std::string& name, double value) {
    if (kind_ != SoundKind::Patch || !valid_) return;
    macroPreview_[name] = std::clamp(value, -1.0, 1.0);
    request_render();
}

void SoundModel::cancel_macro_preview() {
    if (macroPreview_.empty()) return;
    macroPreview_.clear();
    request_render();
}

SoundVariantInfo SoundModel::variations() const {
    SoundVariantInfo v;
    if (kind_ != SoundKind::Patch || !patch_) return v;
    const SfxVariations& s = patch_->variations;
    v.count = s.count;
    v.seed = s.seed;
    v.pitchCents = s.pitchCents;
    v.lengthFraction = s.lengthFraction;
    v.gainDb = s.gainDb;
    v.filterOctaves = s.filterOctaves;
    v.noise = s.noise;
    return v;
}

// ---- edits ---------------------------------------------------------------------------------------------------------------

SoundBlob SoundModel::blob_of(const std::string& rel) {
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        fileCache_.erase(rel);
        return nullptr;
    }
    auto data = read_file(*abs);
    if (!data) return nullptr;
    auto it = fileCache_.find(rel);
    if (it != fileCache_.end() && it->second && *it->second == *data) return it->second;
    SoundBlob blob = std::make_shared<const std::string>(std::move(*data));
    fileCache_[rel] = blob;
    return blob;
}

SoundFileSet SoundModel::capture(const std::set<std::string>& paths) {
    SoundFileSet out;
    for (const std::string& p : paths) out[p] = blob_of(p);
    return out;
}

bool SoundModel::restore(const SoundFileSet& files) {
    for (const auto& [rel, blob] : files) {
        auto abs = resolve_project_path(projectDir_, rel);
        if (!abs.ok()) {
            status_ = abs.error().message;
            return false;
        }
        std::error_code ec;
        if (!blob) {
            stdfs::remove(*abs, ec);
        } else {
            stdfs::create_directories(abs->parent_path(), ec);
            std::ofstream f(*abs, std::ios::binary | std::ios::trunc);
            if (!f || !f.write(blob->data(), std::streamsize(blob->size()))) {
                status_ = "Cannot write " + rel + ".";
                return false;
            }
        }
        fileCache_.erase(rel);
    }
    return true;
}

SoundEditOutcome SoundModel::fail(SoundEditOutcome out, const std::string& message) {
    out.ok = false;
    out.error = message;
    status_ = message;
    return out;
}

namespace {

// The files under the project directory `dir` (project-relative), recursive.
std::set<std::string> list_files(const std::string& projectDir, const std::string& dir) {
    std::set<std::string> out;
    if (dir.empty()) return out;
    auto abs = resolve_project_path(projectDir, dir);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_directory(*abs, ec)) return out;
    for (stdfs::recursive_directory_iterator it(*abs, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec)) continue;
        out.insert(dir + "/" + it->path().lexically_relative(*abs).generic_string());
    }
    return out;
}

}  // namespace

SoundEditOutcome SoundModel::run(const std::string& label, const std::function<CommandResult()>& body,
                                 const std::string& scanDir, bool manifest) {
    SoundEditOutcome out;
    if (!editable())
        return fail(out, label + ": this sound is read-only here. Use \"Make audio document\" to edit it.");
    if (!valid_ && kind_ != SoundKind::None && json_.is_null())
        return fail(out, label + ": the file does not load: " + error_);
    // The command writes files and sets the VFS root: let a render on the worker finish first.
    if (running_.valid) running_.future.wait();
    collect();
    std::set<std::string> paths = {rel_};
    if (manifest) paths.insert("assets.json");
    for (const std::string& p : list_files(projectDir_, scanDir)) paths.insert(p);
    SoundFileSet before = capture(paths);
    auto rollback = [&](const std::string& message) {
        restore(before);
        for (const auto& [p, b] : before)
            if (!b) {
                // a file the command created: gone with the restore
            }
        load_from_disk();
        return fail(out, message);
    };
    CommandResult r = body();
    if (!r.ok) return rollback(label + ": " + command_error_text(r.error));
    out.result = r.result;
    load_from_disk();
    std::set<std::string> now = paths;
    for (const std::string& p : list_files(projectDir_, scanDir)) now.insert(p);
    SoundFileSet after = capture(now);
    for (const std::string& p : now)
        if (!before.count(p)) before[p] = nullptr;
    for (auto it = before.begin(); it != before.end();) {
        auto f = after.find(it->first);
        const bool same =
            f != after.end() && (f->second == it->second || (f->second && it->second && *f->second == *it->second));
        if (same) {
            after.erase(f);
            it = before.erase(it);
        } else {
            ++it;
        }
    }
    if (!after.empty() || !before.empty()) {
        SoundStep s;
        s.id = nextStep_++;
        s.rel = rel_;
        s.label = label;
        s.before = std::move(before);
        s.after = std::move(after);
        for (const auto& [p, b] : s.before)
            if (!s.after.count(p)) s.after[p] = blob_of(p);
        for (const auto& [p, b] : s.after)
            if (!s.before.count(p)) s.before[p] = nullptr;
        out.step = s.id;
        steps_[s.id] = std::move(s);
        before_ = current_;
    }
    status_ = label;
    request_render();
    return out;
}

Json SoundModel::step_target() const { return Json::object({{"path", rel_}}); }

SoundEditOutcome SoundModel::set_field(const std::string& pointer, const Json& value, const std::string& label) {
    cancel_field_preview();
    Json a = step_target();
    a["op"] = "set";
    a["pointer"] = pointer;
    a["value"] = value;
    return run(label.empty() ? "Change " + pointer : label, [&] { return call_("sfx.edit", a); });
}

SoundEditOutcome SoundModel::remove_field(const std::string& pointer, const std::string& label) {
    cancel_field_preview();
    Json a = step_target();
    a["op"] = "remove";
    a["pointer"] = pointer;
    return run(label.empty() ? "Remove " + pointer : label, [&] { return call_("sfx.edit", a); });
}

SoundEditOutcome SoundModel::add_item(const std::string& pointer, const Json& value, int index,
                                      const std::string& label) {
    cancel_field_preview();
    Json a = step_target();
    a["op"] = "add";
    a["pointer"] = pointer;
    a["value"] = value;
    if (index >= 0) a["index"] = index;
    return run(label.empty() ? "Add to " + pointer : label, [&] { return call_("sfx.edit", a); });
}

SoundEditOutcome SoundModel::move_item(const std::string& pointer, int from, int to, const std::string& label) {
    cancel_field_preview();
    Json a = step_target();
    a["op"] = "move";
    a["pointer"] = pointer;
    a["index"] = from;
    a["to"] = to;
    return run(label.empty() ? "Move in " + pointer : label, [&] { return call_("sfx.edit", a); });
}

void SoundModel::preview_field(const std::string& pointer, const Json& value) {
    if (!editable() || json_.is_null()) return;
    try {
        Json j = json_;
        j[Json::json_pointer(pointer)] = value;
        previewJson_ = std::move(j);
    } catch (const std::exception&) {
        return;
    }
    jsonPreview_ = true;
    fieldPreviewPointer_ = pointer;
    fieldPreviewValue_ = value;
    request_render();
}

void SoundModel::cancel_field_preview() {
    if (!jsonPreview_) return;
    jsonPreview_ = false;
    fieldPreviewPointer_.clear();
    stepPreviewIndex_ = -1;
    request_render();
}

SoundEditOutcome SoundModel::commit_field(const std::string& label) {
    SoundEditOutcome out;
    if (!jsonPreview_ || fieldPreviewPointer_.empty()) return out;
    const std::string pointer = fieldPreviewPointer_;
    const Json value = fieldPreviewValue_;
    return set_field(pointer, value, label);
}

SoundEditOutcome SoundModel::commit_macros(const std::string& label) {
    SoundEditOutcome out;
    if (macroPreview_.empty()) return out;
    const std::map<std::string, double> values = macroPreview_;
    macroPreview_.clear();
    SoundEditOutcome r = run(label, [&] {
        CommandResult last;
        last.ok = true;
        for (const auto& [name, v] : values) {
            Json a = step_target();
            a["macros"] = Json::object({{name, v}});
            a["absolute"] = true;
            a["render"] = false;
            last = call_("sfx.tweak", a);
            if (!last.ok) return last;
        }
        return last;
    });
    request_render();
    return r;
}

SoundEditOutcome SoundModel::apply_preset(const std::string& name) {
    cancel_field_preview();
    macroPreview_.clear();
    Json a = Json::object({{"name", name}, {"path", rel_}, {"overwrite", true}});
    return run("Preset " + name, [&] { return call_("sfx.preset", a); });
}

std::string SoundModel::family_dir() const { return without_suffix(rel_, ".sfx.json") + "_family"; }

SoundEditOutcome SoundModel::make_family(const std::string& preset, bool overwrite) {
    Json a = Json::object({{"from", rel_}, {"overwrite", overwrite}, {"render", false}, {"picture", false}});
    a["preset"] = preset.empty() ? "ui" : preset;
    return run("Make a family", [&] { return call_("sfx.family", a); }, family_dir(), true);
}

// ---- documents -----------------------------------------------------------------------------------------------------------

std::vector<SoundChainStep> SoundModel::chain() const {
    std::vector<SoundChainStep> out;
    if (kind_ != SoundKind::Document || !json_.is_object() || !json_.contains("steps") || !json_["steps"].is_array())
        return out;
    int i = 0;
    for (const Json& s : json_["steps"]) {
        SoundChainStep c;
        c.index = i;
        c.type = s.is_object() ? s.value("type", std::string()) : std::string();
        c.enabled = s.is_object() ? s.value("enabled", true) : true;
        c.params = s;
        if (current_ && stopAfter_ < 0 && current_->steps.size() == json_["steps"].size()) {
            c.seconds = current_->steps[std::size_t(i)].seconds;
            c.peakDb = current_->steps[std::size_t(i)].peakDb;
            c.reported = true;
        }
        out.push_back(std::move(c));
        ++i;
    }
    return out;
}

SoundEditOutcome SoundModel::add_step(const std::string& type, int index, const Json& fields) {
    SoundEditOutcome out;
    Json step = Json::object({{"type", type}});
    for (const AudioStepInfo& info : audio_step_types()) {
        if (info.type != type) continue;
        for (const AudioFieldInfo& f : info.fields)
            if (f.required) step[f.key] = required_value(f);
    }
    for (auto it = fields.begin(); it != fields.end(); ++it) step[it.key()] = it.value();
    // A loop step ends the chain: anything but gain and normalize may not follow it.
    if (type != "loop" && kind_ == SoundKind::Document && json_.contains("steps")) {
        const int li = loop_step();
        if (li >= 0 && (index < 0 || index > li)) index = li;
    }
    Json a = step_target();
    a["op"] = "add";
    a["step"] = step;
    if (index >= 0) a["index"] = index;
    a["bake"] = false;
    return run("Add " + type, [&] { return call_("audio.edit", a); });
}

SoundEditOutcome SoundModel::remove_step(int index) {
    Json a = step_target();
    a["op"] = "remove";
    a["index"] = index;
    a["bake"] = false;
    std::string type;
    if (json_.contains("steps") && index >= 0 && std::size_t(index) < json_["steps"].size())
        type = json_["steps"][std::size_t(index)].value("type", std::string());
    return run("Remove " + type, [&] { return call_("audio.edit", a); });
}

SoundEditOutcome SoundModel::move_step(int index, int to) {
    Json a = step_target();
    a["op"] = "move";
    a["index"] = index;
    a["to"] = to;
    a["bake"] = false;
    return run("Move step", [&] { return call_("audio.edit", a); });
}

SoundEditOutcome SoundModel::set_step(int index, const Json& values, const std::string& label) {
    cancel_field_preview();
    Json a = step_target();
    a["op"] = "set";
    a["index"] = index;
    a["values"] = values;
    a["bake"] = false;
    std::string type;
    if (json_.contains("steps") && index >= 0 && std::size_t(index) < json_["steps"].size())
        type = json_["steps"][std::size_t(index)].value("type", std::string());
    return run(label.empty() ? "Edit " + type : label, [&] { return call_("audio.edit", a); });
}

SoundEditOutcome SoundModel::set_step_enabled(int index, bool enabled) {
    Json values = Json::object();
    if (enabled)
        values["enabled"] = nullptr;  // null removes the field: enabled is the default
    else
        values["enabled"] = false;
    return set_step(index, values, enabled ? "Enable step" : "Disable step");
}

void SoundModel::preview_step(int index, const Json& values) {
    if (kind_ != SoundKind::Document || !json_.contains("steps") || index < 0 ||
        std::size_t(index) >= json_["steps"].size())
        return;
    Json j = json_;
    Json& step = j["steps"][std::size_t(index)];
    for (auto it = values.begin(); it != values.end(); ++it) {
        if (it.value().is_null())
            step.erase(it.key());
        else
            step[it.key()] = it.value();
    }
    previewJson_ = std::move(j);
    jsonPreview_ = true;
    fieldPreviewPointer_.clear();
    stepPreviewIndex_ = index;
    stepPreviewValues_ = values;
    request_render();
}

SoundEditOutcome SoundModel::commit_step(const std::string& label) {
    SoundEditOutcome out;
    if (!jsonPreview_ || stepPreviewIndex_ < 0) return out;
    const int index = stepPreviewIndex_;
    const Json values = stepPreviewValues_;
    return set_step(index, values, label);
}

void SoundModel::cancel_step_preview() { cancel_field_preview(); }

SoundEditOutcome SoundModel::set_document(const Json& values) {
    Json a = step_target();
    a["op"] = "document";
    for (auto it = values.begin(); it != values.end(); ++it) a[it.key()] = it.value();
    a["bake"] = false;
    return run("Edit document", [&] { return call_("audio.edit", a); });
}

int SoundModel::loop_step() const {
    if (kind_ != SoundKind::Document || !json_.is_object() || !json_.contains("steps") || !json_["steps"].is_array())
        return -1;
    int found = -1, i = 0;
    for (const Json& s : json_["steps"]) {
        if (s.is_object() && s.value("type", std::string()) == "loop" && s.value("enabled", true)) found = i;
        ++i;
    }
    return found;
}

double SoundModel::loop_crossfade() const {
    const int li = loop_step();
    if (li < 0) return 0.05;
    const Json& s = json_["steps"][std::size_t(li)];
    return s.value("crossfade", 0.05);
}

std::optional<std::pair<double, double>> SoundModel::loop_seconds() const {
    if (loopPreview_) return loopPreview_;
    if (kind_ == SoundKind::Document) {
        if (current_ && current_->loop && current_->rate > 0 && current_->loop->end > current_->loop->start)
            return std::pair<double, double>{double(current_->loop->start) / current_->rate,
                                             double(current_->loop->end) / current_->rate};
        return std::nullopt;
    }
    if (kind_ == SoundKind::File) return import_loop();
    return std::nullopt;
}

std::optional<std::pair<double, double>> SoundModel::import_loop() const {
    if (kind_ != SoundKind::File) return std::nullopt;
    auto abs = resolve_project_path(projectDir_, "assets.json");
    if (!abs.ok()) return std::nullopt;
    auto text = read_file(*abs);
    if (!text) return std::nullopt;
    auto json = parse_json(*text, "assets.json");
    if (!json.ok() || !json->is_object() || !json->contains("assets") || !(*json)["assets"].is_object())
        return std::nullopt;
    auto it = (*json)["assets"].find(rel_);
    if (it == (*json)["assets"].end() || !it->is_object() || !it->contains("import") || !(*it)["import"].is_object())
        return std::nullopt;
    const Json& imp = (*it)["import"];
    const double s = imp.value("loopStart", 0.0), e = imp.value("loopEnd", 0.0);
    if (e > s && s >= 0.0) return std::pair<double, double>{s, e};
    return std::nullopt;
}

void SoundModel::preview_loop(double startSeconds, double endSeconds) {
    if (!current_) return;
    const double dur = std::max(current_->seconds, 0.0);
    double limit = dur;
    if (SoundRenderPtr g = loop_ghost()) limit = std::max(limit, g->seconds - loop_crossfade());
    const double minLen = 8.0 / std::max(current_->rate, 1);
    startSeconds = std::clamp(startSeconds, 0.0, std::max(0.0, limit - minLen));
    endSeconds = std::clamp(endSeconds, startSeconds + minLen, std::max(limit, startSeconds + minLen));
    loopPreview_ = std::pair<double, double>{startSeconds, endSeconds};
}

SoundEditOutcome SoundModel::commit_loop() {
    SoundEditOutcome out;
    if (!loopPreview_) return out;
    const auto pts = *loopPreview_;
    loopPreview_.reset();
    auto r4 = [](double v) { return std::round(v * 10000.0) / 10000.0; };
    const double xf = loop_crossfade();
    const int li = loop_step();
    if (li < 0) {
        Json fields = Json::object({{"start", r4(pts.first)}, {"end", r4(pts.second + xf)}});
        return add_step("loop", -1, fields);
    }
    return set_step(li, Json::object({{"start", r4(pts.first)}, {"end", r4(pts.second + xf)}}), "Move loop points");
}

// ---- files ---------------------------------------------------------------------------------------------------------------

SoundEditOutcome SoundModel::make_document() {
    SoundEditOutcome out;
    if (kind_ != SoundKind::File) return fail(out, "Make audio document: only a plain sound file becomes a document.");
    const std::string ext = stdfs::path(rel_).extension().string();
    const std::string base = rel_.substr(0, rel_.size() - ext.size());
    const std::string docRel = base + ".audio.json";
    Json a = Json::object({{"path", docRel}, {"source", rel_}, {"bake", false}, {"overwrite", false}});
    a["output"] = Json::object({{"format", "wav"}, {"path", base + "_edit.wav"}});
    CommandResult r = call_("audio.create", a);
    if (!r.ok) return fail(out, "Make audio document: " + command_error_text(r.error));
    out.result = r.result;
    status_ = "Made " + docRel + " (its sound bakes to " + base + "_edit.wav).";
    return out;
}

SoundEditOutcome SoundModel::save() {
    SoundEditOutcome out;
    if (!editable()) return fail(out, "Save: a plain sound file has nothing to bake.");
    if (!valid_) return fail(out, "Save: the file does not load: " + error_);
    if (running_.valid) running_.future.wait();
    collect();
    CommandResult r;
    if (kind_ == SoundKind::Patch) {
        Json a = Json::object({{"path", rel_}, {"picture", false}, {"overwrite", overwriteOnSave_}});
        r = call_("sfx.render", a);
        if (r.ok && patch_ && patch_->variations.count > 0) {
            a["variants"] = true;
            a.erase("overwrite");
            a["overwrite"] = overwriteOnSave_;
            r = call_("sfx.render", a);
        }
    } else {
        r = call_("audio.bake", Json::object({{"path", rel_}, {"overwrite", overwriteOnSave_}}));
    }
    if (!r.ok) return fail(out, "Save: " + command_error_text(r.error));
    out.result = r.result;
    status_ = "Baked " + baked_path() + ".";
    baked_.reset();
    bakedStamp_ = ~0ULL;
    return out;
}

// ---- undo ----------------------------------------------------------------------------------------------------------------

const SoundStep* SoundModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string SoundModel::step_document(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? std::string() : it->second.rel;
}

bool SoundModel::apply_step(int id, bool forward) {
    auto it = steps_.find(id);
    if (it == steps_.end()) {
        status_ = "That sound edit is no longer remembered.";
        return false;
    }
    const SoundStep& s = it->second;
    if (running_.valid) running_.future.wait();
    collect();
    if (!restore(forward ? s.after : s.before)) return false;
    if (s.rel == rel_) {
        macroPreview_.clear();
        loopPreview_.reset();
        load_from_disk();
        request_render();
    }
    status_ = std::string(forward ? "Redo: " : "Undo: ") + s.label;
    return true;
}

void SoundModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) {
        if (keep.count(it->first))
            ++it;
        else
            it = steps_.erase(it);
    }
}

}  // namespace fa::editor
