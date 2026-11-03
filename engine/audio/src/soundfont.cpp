// The SoundFont wrapper (fa/audio/soundfont.h) over TinySoundFont.
#include "fa/audio/soundfont.h"

#include <algorithm>
#include <cctype>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "tsf.h"

namespace fa {

struct Soundfont::Impl {
    tsf* font = nullptr;
    ~Impl() {
        if (font) tsf_close(font);
    }
};

namespace {

std::string lower(std::string_view s) {
    std::string out(s);
    for (char& c : out) c = char(std::tolower(static_cast<unsigned char>(c)));
    return out;
}

std::string names_text(const std::vector<SoundfontPreset>& presets, std::size_t limit = 12) {
    std::string out;
    for (std::size_t i = 0; i < presets.size() && i < limit; ++i) out += (out.empty() ? "" : ", ") + std::string("\"") + presets[i].name + "\"";
    if (presets.size() > limit) out += std::format(", ... ({} presets in all; music.instrument lists them)", presets.size());
    return out;
}

}  // namespace

Result<Soundfont> Soundfont::load(std::string_view path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes)
        return make_error(std::string(path) + ": cannot read the SoundFont: " + bytes.error().message,
                          "Put the .sf2 file in the project (assets/audio/piano.sf2) and name it with that project-relative path. " + bytes.error().hint);
    auto font = from_memory(*bytes, path);
    if (!font) return font.error();
    font->path_ = std::string(path);
    return font;
}

Result<Soundfont> Soundfont::from_memory(const std::vector<std::uint8_t>& bytes, std::string_view label) {
    if (bytes.empty() || bytes.size() > 0x7fffffffu)
        return make_error(std::string(label) + ": the SoundFont is " + (bytes.empty() ? "empty" : "too large"), "A SoundFont is a .sf2 file of a few hundred kilobytes to a few hundred megabytes.");
    tsf* font = tsf_load_memory(bytes.data(), int(bytes.size()));
    if (!font)
        return make_error(std::string(label) + ": not a SoundFont 2 file, or it is damaged",
                          "Only .sf2 files are read (RIFF \"sfbk\"). A compressed .sf3 must be converted to .sf2 first, and a .sfz or .dls file is another format.");
    Soundfont sf;
    sf.impl_ = std::make_shared<Impl>();
    sf.impl_->font = font;
    sf.path_ = std::string(label);
    const int count = tsf_get_presetcount(font);
    if (count <= 0) return make_error(std::string(label) + ": the SoundFont has no presets", "Export it again with at least one instrument.");
    // TinySoundFont lists names by index only: find each preset's bank and program number by asking for every combination.
    std::vector<int> bankOf(std::size_t(count), -1), programOf(std::size_t(count), -1);
    for (int bank = 0; bank <= 128; ++bank)
        for (int program = 0; program < 128; ++program) {
            const int index = tsf_get_presetindex(font, bank, program);
            if (index >= 0 && index < count && bankOf[std::size_t(index)] < 0) {
                bankOf[std::size_t(index)] = bank;
                programOf[std::size_t(index)] = program;
            }
        }
    for (int i = 0; i < count; ++i) {
        const char* name = tsf_get_presetname(font, i);
        sf.presets_.push_back({name ? std::string(name) : std::string(), std::max(0, bankOf[std::size_t(i)]), std::max(0, programOf[std::size_t(i)])});
    }
    return sf;
}

Result<int> Soundfont::find_preset(std::string_view name) const {
    for (std::size_t i = 0; i < presets_.size(); ++i)
        if (presets_[i].name == name) return int(i);
    const std::string wanted = lower(name);
    for (std::size_t i = 0; i < presets_.size(); ++i)
        if (lower(presets_[i].name) == wanted) return int(i);
    std::vector<std::string> names;
    for (const SoundfontPreset& p : presets_) names.push_back(p.name);
    return make_error(path_ + ": no preset named \"" + std::string(name) + "\"",
                      did_you_mean(std::string(name), names) + " Presets: " + names_text(presets_) + ". Or pick one by number: {\"soundfont\": \"" + path_ + "\", \"preset\": 0, \"bank\": 0}.");
}

Result<int> Soundfont::find_preset(int bank, int program) const {
    for (std::size_t i = 0; i < presets_.size(); ++i)
        if (presets_[i].bank == bank && presets_[i].program == program) return int(i);
    std::string available;
    for (std::size_t i = 0; i < presets_.size() && i < 10; ++i)
        available += std::format("{}{}:{} \"{}\"", available.empty() ? "" : ", ", presets_[i].bank, presets_[i].program, presets_[i].name);
    if (presets_.size() > 10) available += ", ...";
    return make_error(std::format("{}: no preset with bank {} and program {}", path_, bank, program),
                      "Presets (bank:program): " + available + ". Banks 0 to 127 are melodic; 128 is the percussion kit.");
}

Result<void> Soundfont::render(int preset, int rate, const std::vector<SoundfontNote>& notes, std::size_t frames, std::vector<double>& left,
                               std::vector<double>& right) const {
    if (!impl_ || !impl_->font) return make_error("the SoundFont is not loaded", "Load it with Soundfont::load.");
    if (preset < 0 || std::size_t(preset) >= presets_.size()) return make_error(std::format("preset {} is out of range", preset), "Use find_preset.");
    left.assign(frames, 0.0);
    right.assign(frames, 0.0);
    tsf* f = tsf_copy(impl_->font);  // shares the sample data, has its own voices
    if (!f) return make_error(path_ + ": out of memory while starting the SoundFont", "Close other programs or use a smaller SoundFont.");
    tsf_set_output(f, TSF_STEREO_INTERLEAVED, rate, 0.0f);

    struct Event {
        std::int64_t frame;
        bool on;
        int key;
        float velocity;
        std::size_t order;
    };
    std::vector<Event> events;
    events.reserve(notes.size() * 2);
    for (std::size_t i = 0; i < notes.size(); ++i) {
        const SoundfontNote& n = notes[i];
        if (n.startFrame < 0 || n.startFrame >= std::int64_t(frames)) continue;
        const int key = std::clamp(n.key, 0, 127);
        events.push_back({n.startFrame, true, key, std::clamp(n.velocity, 0.0f, 1.0f), i});
        events.push_back({n.startFrame + std::max<std::int64_t>(1, n.heldFrames), false, key, 0.0f, i});
    }
    // At one frame a release comes before a note-on, so a repeated key restarts cleanly; ties keep the order the notes were given in.
    std::stable_sort(events.begin(), events.end(), [](const Event& a, const Event& b) {
        if (a.frame != b.frame) return a.frame < b.frame;
        if (a.on != b.on) return !a.on;
        return a.order < b.order;
    });
    std::vector<float> block;
    std::size_t done = 0;
    auto render_to = [&](std::size_t target) {
        constexpr std::size_t kBlock = 4096;
        while (done < target) {
            const std::size_t n = std::min(kBlock, target - done);
            block.assign(n * 2, 0.0f);
            tsf_render_float(f, block.data(), int(n), 0);
            for (std::size_t i = 0; i < n; ++i) {
                left[done + i] = double(block[2 * i]);
                right[done + i] = double(block[2 * i + 1]);
            }
            done += n;
        }
    };
    for (const Event& e : events) {
        render_to(std::size_t(std::min<std::int64_t>(e.frame, std::int64_t(frames))));
        if (e.on) tsf_note_on(f, preset, e.key, e.velocity);
        else tsf_note_off(f, preset, e.key);
    }
    render_to(frames);
    tsf_close(f);
    return {};
}

}  // namespace fa
