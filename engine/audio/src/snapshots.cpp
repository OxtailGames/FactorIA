// The "audio" section of factoria.json: parse_audio_settings.
#include "fa/audio/snapshots.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"

namespace fa {

namespace {

const std::vector<std::string> kBuses = {"sfx", "music", "ui", "master"};
const std::vector<std::string> kDuckSources = {"sfx", "music", "ui"};

struct Reader {
    AudioSettingsParse& r;

    void issue(const std::string& pointer, const std::string& message, const std::string& hint) {
        r.issues.push_back({"/audio" + pointer, message, hint});
    }
    // Unknown keys of an object are a warning with a suggestion: the engine ignores them, a typo would go unnoticed.
    void unknown_keys(const Json& obj, const std::vector<std::string>& known, const std::string& pointer) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
            r.warnings.push_back({"/audio" + pointer + "/" + it.key(),
                                  "unknown key \"" + it.key() + "\" (ignored). " + did_you_mean(it.key(), known),
                                  "The keys here are: " + join(known, ", ") + "."});
        }
    }
    // A number in [lo, hi] at obj[key]; false when absent or wrong (and then reported).
    bool number(const Json& obj, const char* key, const std::string& pointer, double lo, double hi, const std::string& hint, float& out) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        const std::string where = pointer + "/" + key;
        if (!it->is_number()) {
            issue(where, "expected a number, got " + describe_json_value(*it), hint);
            return false;
        }
        const double v = it->get<double>();
        if (!std::isfinite(v) || v < lo || v > hi) {
            issue(where, std::format("expected a number from {} to {}, got {}", lo, hi, describe_json_value(*it)), hint);
            return false;
        }
        out = float(v);
        return true;
    }

    void duck(const Json& value, const std::string& pointer, const std::string& bus, BusSnapshot& into) {
        const std::string hint = "Example: \"duck\": {\"by\": \"sfx\", \"amount\": 0.5, \"attack\": 0.05, \"release\": 0.5}.";
        if (!value.is_object()) {
            issue(pointer, "expected an object like {\"by\": \"sfx\", \"amount\": 0.5}, got " + describe_json_value(value), hint);
            return;
        }
        unknown_keys(value, {"by", "amount", "attack", "release"}, pointer);
        DuckSettings d;
        d.amount = 0.5f;
        auto by = value.find("by");
        if (by == value.end()) {
            issue(pointer + "/by", "missing: the bus that ducks this one",
                  "Add \"by\": \"sfx\" (or \"music\", \"ui\"): this bus gets quieter while that one plays.");
            return;
        }
        if (!by->is_string() || std::find(kDuckSources.begin(), kDuckSources.end(), by->get<std::string>()) == kDuckSources.end()) {
            const std::string got = by->is_string() ? by->get<std::string>() : describe_json_value(*by);
            issue(pointer + "/by", "\"" + got + "\" is not a bus that can duck another. " + did_you_mean(got, kDuckSources),
                  "Use \"sfx\", \"music\" or \"ui\".");
            return;
        }
        d.by = by->get<std::string>();
        if (d.by == bus) {
            issue(pointer + "/by", "the bus \"" + bus + "\" cannot duck itself", "Name the other bus.");
            return;
        }
        number(value, "amount", pointer, 0.0, 1.0, "The fraction removed: 0.5 halves the bus while the other plays, 1 silences it.", d.amount);
        number(value, "attack", pointer, 0.0, 30.0, "Seconds to get down to the ducked level, e.g. 0.05.", d.attack);
        number(value, "release", pointer, 0.0, 30.0, "Seconds to come back, e.g. 0.5.", d.release);
        if (d.amount > 0.0f) into.duck = d;
    }

    void bus(const Json& value, const std::string& pointer, const std::string& name, BusSnapshot& into) {
        if (!value.is_object()) {
            issue(pointer, "expected an object like {\"volume\": 0.8, \"lowpass\": 600}, got " + describe_json_value(value),
                  "Keys: volume, lowpass, reverb, duck.");
            return;
        }
        unknown_keys(value, {"volume", "lowpass", "reverb", "duck"}, pointer);
        number(value, "volume", pointer, 0.0, 4.0, "A scale on the bus's volume: 1 = unchanged, 0.5 = half, 0 = silent.", into.volume);
        auto lp = value.find("lowpass");
        if (lp != value.end() && !lp->is_null()) {
            float hz = 0.0f;
            if (number(value, "lowpass", pointer, 0.0, 20000.0, "The cutoff in Hz, 20..20000; 0 (or null) leaves the filter off.", hz)) {
                if (hz > 0.0f && hz < 20.0f)
                    issue(pointer + "/lowpass", "a cutoff of " + describe_json_value(*lp) + " Hz is below hearing",
                          "Use 20..20000 Hz, or 0 for no filter.");
                else
                    into.lowpass = hz;
            }
        }
        number(value, "reverb", pointer, 0.0, 1.0, "The wet mix: 0 = no reverb, 0.3 = a touch of room, 1 = all wet.", into.reverb);
        if (auto d = value.find("duck"); d != value.end() && !d->is_null()) {
            if (name == "master") issue(pointer + "/duck", "the master cannot be ducked", "Duck \"sfx\", \"music\" or \"ui\".");
            else duck(*d, pointer + "/duck", name, into);
        }
    }

    void snapshot(const Json& value, const std::string& pointer, AudioSnapshot& into) {
        if (!value.is_object()) {
            issue(pointer, "expected an object like {\"fade\": 0.5, \"buses\": {\"music\": {\"lowpass\": 600}}}, got " +
                               describe_json_value(value),
                  "An empty object {} is a valid snapshot: every bus neutral.");
            return;
        }
        unknown_keys(value, {"fade", "buses"}, pointer);
        number(value, "fade", pointer, 0.0, 60.0, "Seconds the snapshot takes when audio.snapshot gives no time, e.g. 0.5.", into.fade);
        auto buses = value.find("buses");
        if (buses == value.end() || buses->is_null()) return;
        if (!buses->is_object()) {
            issue(pointer + "/buses", "expected an object mapping bus names to settings, got " + describe_json_value(*buses),
                  "Example: \"buses\": {\"music\": {\"lowpass\": 600}}");
            return;
        }
        for (auto it = buses->begin(); it != buses->end(); ++it) {
            const std::string where = pointer + "/buses/" + it.key();
            if (std::find(kBuses.begin(), kBuses.end(), it.key()) == kBuses.end()) {
                issue(where, "\"" + it.key() + "\" is not an audio bus. " + did_you_mean(it.key(), kBuses),
                      "The buses are \"sfx\", \"music\", \"ui\" and \"master\".");
                continue;
            }
            bus(it.value(), where, it.key(), into.buses[it.key()]);
        }
    }
};

}  // namespace

AudioSettingsParse parse_audio_settings(const Json& section) {
    AudioSettingsParse r;
    if (section.is_null()) return r;
    Reader in{r};
    if (!section.is_object()) {
        in.issue("", "expected an object like {\"snapshots\": {...}}, got " + describe_json_value(section),
                 "The audio section holds the mixer snapshots: \"audio\": {\"snapshots\": {\"underwater\": {\"buses\": "
                 "{\"music\": {\"lowpass\": 600}}}}}.");
        return r;
    }
    in.unknown_keys(section, {"snapshots"}, "");
    auto snaps = section.find("snapshots");
    if (snaps == section.end() || snaps->is_null()) return r;
    if (!snaps->is_object()) {
        in.issue("/snapshots", "expected an object mapping snapshot names to snapshots, got " + describe_json_value(*snaps),
                 "Example: \"snapshots\": {\"underwater\": {\"buses\": {\"music\": {\"lowpass\": 600}}}}");
        return r;
    }
    for (auto it = snaps->begin(); it != snaps->end(); ++it) {
        if (it.key().empty()) {
            in.issue("/snapshots/", "a snapshot needs a name", "Use a name such as \"underwater\" or \"pause\".");
            continue;
        }
        in.snapshot(it.value(), "/snapshots/" + it.key(), r.snapshots[it.key()]);
    }
    return r;
}

}  // namespace fa
