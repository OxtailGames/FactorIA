// The SoundFont wrapper (fa/audio/soundfont.h) over TinySoundFont.
#include "fa/audio/soundfont.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstring>
#include <format>
#include <vector>

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

// TinySoundFont trusts the index fields of a SoundFont's "hydra" (preset headers, bags, generators, instruments, sample headers):
// a bag that points past the generator list, indices that go backwards or an instrument number that is the terminal record make
// it read outside its arrays while loading. This walks the file's RIFF structure the way TinySoundFont does (no padding bytes) and
// checks every index the loader follows, with the file's length in hand. Returns what is wrong, or "" (also when the file is not a
// SoundFont or lacks a table: TinySoundFont refuses those itself).
std::string sf2_problem(const std::vector<std::uint8_t>& file) {
    const std::uint8_t* d = file.data();
    const std::uint64_t n = file.size();
    auto u16 = [&](std::uint64_t at) { return std::uint32_t(d[at]) | std::uint32_t(d[at + 1]) << 8; };
    auto u32 = [&](std::uint64_t at) { return u16(at) | u16(at + 2) << 16; };
    auto id_at = [&](std::uint64_t at, const char* four) { return std::memcmp(d + at, four, 4) == 0; };
    auto plausible_id = [&](std::uint64_t at) { return d[at] > ' ' && d[at] < 'z'; };

    if (n < 12 || !id_at(0, "RIFF") || !id_at(8, "sfbk")) return {};
    const std::uint64_t end = std::min<std::uint64_t>(n, 8 + std::uint64_t(u32(4)));
    static const char* const names[9] = {"phdr", "pbag", "pmod", "pgen", "inst", "ibag", "imod", "igen", "shdr"};
    static const std::uint32_t sizes[9] = {38, 4, 10, 4, 22, 4, 10, 4, 46};
    std::uint64_t at[9] = {};      // where each table's records start
    std::uint64_t count[9] = {};   // and how many it has
    bool seen[9] = {};
    for (std::uint64_t pos = 12; pos + 8 <= end;) {
        if (!plausible_id(pos)) break;
        const std::uint64_t size = u32(pos + 4), next = pos + 8 + size;
        if (next > end) return "a chunk of the file runs past its end";
        if (id_at(pos, "RIFF")) break;
        if (id_at(pos, "LIST") && size >= 4 && id_at(pos + 8, "pdta")) {
            for (std::uint64_t p = pos + 12; p < next;) {
                if (p + 8 > next || !plausible_id(p)) return "the 'pdta' list of the file is cut short";
                const std::uint64_t inner = u32(p + 4), innerNext = p + 8 + inner;
                if (innerNext > next) return "a table of the 'pdta' list runs past the end of the list";
                for (int t = 0; t < 9; ++t)
                    if (id_at(p, names[t]) && inner % sizes[t] == 0) {
                        at[t] = p + 8;
                        count[t] = inner / sizes[t];
                        seen[t] = true;
                    }
                p = innerNext;
            }
        } else if (!id_at(pos, "LIST") && (id_at(pos, "pdta") || id_at(pos, "sdta"))) {
            return "a 'pdta' or 'sdta' chunk is not a list";
        }
        pos = next;
    }
    for (bool s : seen)
        if (!s) return {};
    if (count[0] < 1 || count[1] < 1 || count[4] < 1 || count[5] < 1)
        return "its 'phdr', 'pbag', 'inst' or 'ibag' table has no terminal record";

    // Field readers: record `i` of table `t`, the u16 at byte `off`.
    auto field = [&](int t, std::uint64_t i, std::uint32_t off) { return u16(at[t] + i * sizes[t] + off); };
    // A table of "start index" records: indices never go backwards and the last real one stays inside the table it points into.
    auto chain = [&](int t, std::uint32_t off, std::uint64_t limit, const char* what) -> std::string {
        for (std::uint64_t i = 0; i + 1 < count[t]; ++i) {
            const std::uint32_t a = field(t, i, off), b = field(t, i + 1, off);
            if (a > b || b > limit) return what;
        }
        return {};
    };
    if (auto why = chain(0, 24, count[1] - 1, "a preset header points at preset zones that do not exist or run backwards"); !why.empty()) return why;
    if (auto why = chain(1, 0, count[3], "a preset zone points at generators that do not exist or run backwards"); !why.empty()) return why;
    if (auto why = chain(4, 20, count[5] - 1, "an instrument points at instrument zones that do not exist or run backwards"); !why.empty()) return why;
    if (auto why = chain(5, 0, count[7], "an instrument zone points at generators that do not exist or run backwards"); !why.empty()) return why;
    for (std::uint64_t i = 0; i < count[3]; ++i)  // preset generators: the instrument must be a real one, not the terminal record
        if (field(3, i, 0) == 41 && field(3, i, 2) < count[4] && field(3, i, 2) + 1 >= count[4]) return "a preset zone uses the terminal instrument record";
    for (std::uint64_t i = 0; i < count[7]; ++i)  // instrument generators: the sample header must exist
        if (field(7, i, 0) == 53 && field(7, i, 2) >= count[8]) return "an instrument zone names a sample header that does not exist";
    return {};
}

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
    if (const std::string why = sf2_problem(bytes); !why.empty())
        return make_error(std::string(label) + ": the SoundFont is damaged: " + why,
                          "Download the .sf2 file again or export it again from the SoundFont editor.");
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
