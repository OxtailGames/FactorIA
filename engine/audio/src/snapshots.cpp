// The "audio" section of factoria.json: parse_audio_settings.
#include "fa/audio/snapshots.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "fa/core/strings.h"

namespace fa {

namespace {

const std::vector<std::string> kBuiltinBuses = {"sfx", "music", "ui", "master"};
constexpr std::size_t kMaxProjectBuses = 32;

bool valid_bus_name(const std::string& n) {
    if (n.empty() || !(n[0] >= 'a' && n[0] <= 'z')) return false;
    for (char c : n)
        if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '-')) return false;
    return true;
}

struct Reader {
    AudioSettingsParse& r;
    std::vector<std::string> kBuses = kBuiltinBuses;  // the built-in buses and the project's, master last of the built-ins
    std::vector<std::string> kDuckSources = {"sfx", "music", "ui"};  // every bus but the master

    std::string bus_list() const {
        std::string list;
        for (const std::string& n : kBuses) list += (list.empty() ? "\"" : ", \"") + n + "\"";
        return list;
    }

    // "buses": {"ambience": {"parent": "sfx"}}. Fills r.buses (parents before children is not required) and the name lists.
    void buses(const Json& value) {
        if (!value.is_object()) {
            issue("/buses", "expected an object mapping bus names to {\"parent\": ...}, got " + describe_json_value(value),
                  "Example: \"buses\": {\"ambience\": {\"parent\": \"sfx\"}}");
            return;
        }
        if (value.size() > kMaxProjectBuses)
            issue("/buses", "a project declares at most " + std::to_string(kMaxProjectBuses) + " buses, got " + std::to_string(value.size()),
                  "Merge buses that are always set together.");
        // The names first, so a parent may be declared after its child.
        std::vector<std::string> declared;
        for (auto it = value.begin(); it != value.end(); ++it) {
            const std::string where = "/buses/" + it.key();
            if (std::find(kBuiltinBuses.begin(), kBuiltinBuses.end(), it.key()) != kBuiltinBuses.end()) {
                issue(where, "\"" + it.key() + "\" is a built-in bus, it cannot be declared again",
                      "Pick another name, or drop the entry: \"sfx\", \"music\", \"ui\" and \"master\" always exist.");
                continue;
            }
            if (!valid_bus_name(it.key())) {
                std::string lower = to_lower(it.key());
                issue(where, "\"" + it.key() + "\" is not a bus name",
                      "A bus name starts with a lowercase letter and then has lowercase letters, digits, '_' or '-' (audio.setVolume "
                      "lowercases names)" + (valid_bus_name(lower) ? ", for example \"" + lower + "\"." : "."));
                continue;
            }
            declared.push_back(it.key());
        }
        std::vector<std::string> known = kBuiltinBuses;
        known.insert(known.end(), declared.begin(), declared.end());
        std::map<std::string, std::string> parentOf;
        for (const std::string& name : declared) {
            const Json& def = value[name];
            const std::string where = "/buses/" + name;
            std::string parent = "master";
            if (def.is_object()) {
                unknown_keys(def, {"parent"}, where);
                auto p = def.find("parent");
                if (p != def.end() && !p->is_null()) {
                    if (!p->is_string()) {
                        issue(where + "/parent", "expected the name of a bus, got " + describe_json_value(*p),
                              "Example: {\"parent\": \"sfx\"}; leave it out for \"master\".");
                    } else if (std::find(known.begin(), known.end(), p->get<std::string>()) == known.end()) {
                        issue(where + "/parent", "\"" + p->get<std::string>() + "\" is not a bus. " + did_you_mean(p->get<std::string>(), known),
                              "The parent is \"sfx\", \"music\", \"ui\", \"master\" or a bus declared in \"buses\".");
                    } else if (p->get<std::string>() == name) {
                        issue(where + "/parent", "the bus \"" + name + "\" cannot be its own parent", "Name another bus, or leave it out for \"master\".");
                    } else {
                        parent = p->get<std::string>();
                    }
                }
            } else if (!def.is_null()) {
                issue(where, "expected an object like {\"parent\": \"sfx\"}, got " + describe_json_value(def),
                      "An empty object {} is a bus under the master.");
            }
            parentOf[name] = parent;
        }
        // A parent chain must reach a built-in bus.
        for (const std::string& name : declared) {
            std::string at = name;
            std::size_t steps = 0;
            while (parentOf.count(at) && steps <= declared.size()) { at = parentOf[at]; ++steps; }
            if (parentOf.count(at)) {
                issue("/buses/" + name + "/parent", "the parents of \"" + name + "\" loop back on themselves",
                      "Every chain of parents must end at \"sfx\", \"music\", \"ui\" or \"master\".");
                break;
            }
        }
        for (const std::string& name : declared) {
            r.buses.push_back({name, parentOf[name]});
            kBuses.push_back(name);
            kDuckSources.push_back(name);
        }
    }

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
                  "Add \"by\": \"sfx\" (or \"music\", \"ui\" or a bus of \"buses\"): this bus gets quieter while that one plays.");
            return;
        }
        if (!by->is_string() || std::find(kDuckSources.begin(), kDuckSources.end(), by->get<std::string>()) == kDuckSources.end()) {
            const std::string got = by->is_string() ? by->get<std::string>() : describe_json_value(*by);
            issue(pointer + "/by", "\"" + got + "\" is not a bus that can duck another. " + did_you_mean(got, kDuckSources),
                  "Use a bus other than the master: " + bus_list() + ".");
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
            if (name == "master") issue(pointer + "/duck", "the master cannot be ducked", "Duck any other bus.");
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
                      "The buses are " + bus_list() + ".");
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
        in.issue("", "expected an object like {\"buses\": {...}, \"snapshots\": {...}}, got " + describe_json_value(section),
                 "The audio section holds the mixer snapshots: \"audio\": {\"snapshots\": {\"underwater\": {\"buses\": "
                 "{\"music\": {\"lowpass\": 600}}}}}.");
        return r;
    }
    in.unknown_keys(section, {"buses", "snapshots"}, "");
    if (auto b = section.find("buses"); b != section.end() && !b->is_null()) in.buses(*b);
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
