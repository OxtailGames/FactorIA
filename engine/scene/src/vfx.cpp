#include "fa/scene/vfx.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <format>
#include <map>
#include <mutex>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/scene/particles.h"

namespace fa {

namespace {

constexpr const char* kFormat = "factoria.vfx/1";
constexpr double kMaxOffset = 1.0e6;

const char* kind_name(VfxPartKind k) {
    switch (k) {
        case VfxPartKind::Emitter: return "emitter";
        case VfxPartKind::Light: return "light";
        case VfxPartKind::Sound: return "sound";
        case VfxPartKind::Command: return "command";
    }
    return "emitter";
}

const std::vector<std::string>& common_keys() {
    static const std::vector<std::string> k = {"type", "name", "at", "duration", "offset"};
    return k;
}
const std::vector<std::string>& keys_of(VfxPartKind k) {
    static const std::vector<std::string> emitter = {"emitter"}, light = {"light", "is3D", "fade"},
                                          sound = {"clip", "volume", "pitch", "bus"}, command = {"command", "args"};
    switch (k) {
        case VfxPartKind::Emitter: return emitter;
        case VfxPartKind::Light: return light;
        case VfxPartKind::Sound: return sound;
        case VfxPartKind::Command: return command;
    }
    return emitter;
}

template <class T>
const TypeInfo& type_of_component() {
    ensure_builtin_components();
    return World::type_of<T>();
}

struct Parser {
    std::string file;
    std::vector<VfxIssue> issues;

    void err(std::string pointer, std::string message, std::string hint = {}) {
        issues.push_back({true, std::move(pointer), std::move(message), std::move(hint)});
    }
    void warn(std::string pointer, std::string message, std::string hint = {}) {
        issues.push_back({false, std::move(pointer), std::move(message), std::move(hint)});
    }
    bool has_error() const {
        return std::any_of(issues.begin(), issues.end(), [](const VfxIssue& i) { return i.error; });
    }
};

// A finite number inside [lo, hi]; says what is wrong otherwise.
bool read_number(Parser& p, const Json& obj, const char* key, const std::string& pointer, double lo, double hi, double& out, const char* what) {
    auto it = obj.find(key);
    if (it == obj.end()) return true;
    if (!it->is_number() || !std::isfinite(it->get<double>()) || it->get<double>() < lo || it->get<double>() > hi) {
        p.err(pointer + "/" + key, std::string(key) + " must be " + what + ", got " + describe_json_value(*it),
              std::format("Example: \"{}\": {}", key, std::clamp(1.0, lo, hi)));
        return false;
    }
    out = it->get<double>();
    return true;
}

// The longest one particle of `em` can be seen: its lifetime plus its variance, plus the trail it leaves.
double lifespan(const ParticleEmitter& em) {
    const double life = double(std::max(em.lifetime, 0.0f)) * (1.0 + double(std::clamp(em.lifetimeVariance, 0.0f, 1.0f)));
    return life + (em.trail != ParticleTrail::None ? double(std::max(em.trailTime, 0.0f)) : 0.0);
}

// An emitter of an effect (and the emitters written inline in its subEmitters) must not hold its particles longer than kVfxMaxLifespan: a
// particle of 3600 s would keep the effect's entity, and one of the kVfxMaxPlaying slots, for an hour.
void check_lifespan(Parser& p, const std::string& ptr, const ParticleEmitter& em, const Json& emitterJson, int depth) {
    if (lifespan(em) > kVfxMaxLifespan)
        p.err(ptr + "/lifetime",
              std::format("a particle of this emitter can be seen for {:.1f} s (lifetime with its lifetimeVariance, plus trailTime); an effect allows at most {:.0f} s",
                          lifespan(em), kVfxMaxLifespan),
              "Lower `lifetime` (a spark lives 0.2 to 2 s). A particle that must stay on screen for long is not an effect: put a ParticleEmitter on an entity of the scene.");
    auto subs = emitterJson.find("subEmitters");
    if (depth >= kParticleSubDepth || subs == emitterJson.end() || !subs->is_object()) return;
    for (auto ev = subs->begin(); ev != subs->end(); ++ev) {
        std::vector<const Json*> links;
        if (ev.value().is_object()) links.push_back(&ev.value());
        else if (ev.value().is_array()) for (const Json& l : ev.value()) links.push_back(&l);
        std::size_t n = 0;
        for (const Json* l : links) {
            const std::size_t at = n++;
            if (!l->is_object()) continue;
            auto inner = l->find("emitter");
            if (inner == l->end() || !inner->is_object()) continue;
            ParticleEmitter child;
            if (!object_patch_from_json(type_of_component<ParticleEmitter>(), &child, *inner)) continue;
            check_lifespan(p, ptr + "/subEmitters/" + ev.key() + (ev.value().is_array() ? "/" + std::to_string(at) : std::string()) + "/emitter", child, *inner, depth + 1);
        }
    }
}

void unknown_keys(Parser& p, const Json& obj, const std::string& pointer, VfxPartKind kind) {
    std::vector<std::string> allowed = common_keys();
    for (const std::string& k : keys_of(kind)) allowed.push_back(k);
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        if (std::find(allowed.begin(), allowed.end(), it.key()) != allowed.end()) continue;
        std::string hint = did_you_mean(it.key(), allowed);
        for (VfxPartKind other : {VfxPartKind::Emitter, VfxPartKind::Light, VfxPartKind::Sound, VfxPartKind::Command}) {
            const auto& ks = keys_of(other);
            if (other != kind && std::find(ks.begin(), ks.end(), it.key()) != ks.end()) {
                hint = "'" + it.key() + "' belongs to a part of type \"" + kind_name(other) + "\"; this part is \"" + kind_name(kind) +
                       "\". Keys of a " + kind_name(kind) + " part: " + join(keys_of(kind), ", ") + ".";
                break;
            }
        }
        p.err(pointer + "/" + it.key(), "unknown key '" + it.key() + "' in a " + kind_name(kind) + " part", hint);
    }
}

void parse_part(Parser& p, const Json& j, std::size_t index, VfxDoc& doc, std::set<std::string>& names) {
    const std::string ptr = "/parts/" + std::to_string(index);
    if (!j.is_object()) {
        p.err(ptr, "a part must be an object, got " + describe_json_value(j),
              "Example: {\"type\": \"emitter\", \"at\": 0, \"emitter\": {\"burst\": 12}}");
        return;
    }
    static const std::vector<std::string> types = {"emitter", "light", "sound", "command"};
    VfxPart part;
    auto ti = j.find("type");
    if (ti == j.end() || !ti->is_string() || std::find(types.begin(), types.end(), ti->get<std::string>()) == types.end()) {
        p.err(ptr + "/type", ti == j.end() ? "a part needs a `type`" : "unknown part type " + describe_json_value(*ti),
              ti != j.end() && ti->is_string() ? did_you_mean(ti->get<std::string>(), types)
                                               : "type is one of: emitter, light, sound, command.");
        return;
    }
    const std::string type = ti->get<std::string>();
    part.kind = type == "emitter" ? VfxPartKind::Emitter : type == "light" ? VfxPartKind::Light
              : type == "sound" ? VfxPartKind::Sound : VfxPartKind::Command;
    unknown_keys(p, j, ptr, part.kind);

    read_number(p, j, "at", ptr, 0.0, kVfxMaxDuration, part.at, "a number of seconds from 0 to 30");
    read_number(p, j, "duration", ptr, 0.0, kVfxMaxDuration, part.duration, "a number of seconds from 0 to 30");
    if (auto it = j.find("offset"); it != j.end()) {
        bool ok = it->is_array() && (it->size() == 2 || it->size() == 3);
        if (ok)
            for (const Json& c : *it) ok = ok && c.is_number() && std::isfinite(c.get<double>()) && std::fabs(c.get<double>()) <= kMaxOffset;
        if (!ok) p.err(ptr + "/offset", "offset must be [x, y] or [x, y, z] (finite numbers), got " + describe_json_value(*it),
                       "Example: \"offset\": [0, 12] puts the part 12 units above the effect's position.");
        else part.offset = {(*it)[0].get<float>(), (*it)[1].get<float>(), it->size() == 3 ? (*it)[2].get<float>() : 0.0f};
    }
    part.name = std::string(kind_name(part.kind)) + std::to_string(index);
    if (auto it = j.find("name"); it != j.end()) {
        const std::string text = it->is_string() ? it->get<std::string>() : std::string();
        const bool ok = !text.empty() &&
                        std::all_of(text.begin(), text.end(), [](unsigned char c) { return std::isalnum(c) || c == '_' || c == '-'; });
        if (!ok) p.err(ptr + "/name", "name must be letters, digits, '_' or '-', got " + describe_json_value(*it),
                       "The name is given to the entity an emitter or a light becomes. Example: \"name\": \"sparks\".");
        else part.name = text;
    }
    if (!names.insert(part.name).second)
        p.err(ptr + "/name", "two parts are called '" + part.name + "'", "Give each part its own `name` (or leave it out).");

    switch (part.kind) {
        case VfxPartKind::Emitter: {
            auto it = j.find("emitter");
            if (it == j.end() || !it->is_object()) {
                p.err(ptr + "/emitter", it == j.end() ? "an emitter part needs `emitter`" : "emitter must be an object of ParticleEmitter fields, got " + describe_json_value(*it),
                      "Example: \"emitter\": {\"burst\": 14, \"lifetime\": 0.4, \"speed\": 90, \"spread\": 180} (docs/PARTICLES.md lists the fields).");
                break;
            }
            part.emitter = *it;
            ParticleEmitter scratch;
            const TypeInfo& ti2 = type_of_component<ParticleEmitter>();
            if (auto r = object_patch_from_json(ti2, &scratch, *it); !r) {
                p.err(ptr + "/emitter", r.error().message, r.error().hint);
                break;
            }
            for (const ParticleProblem& issue : particle_emitter_problems(scratch)) {
                if (issue.error) p.err(ptr + "/emitter" + issue.pointer, issue.message, issue.hint);
                else p.warn(ptr + "/emitter" + issue.pointer, issue.message, issue.hint);
            }
            check_lifespan(p, ptr + "/emitter", scratch, *it, 0);
            for (const char* k : {"emitting", "autoDestroy"})
                if (it->contains(k))
                    p.warn(ptr + "/emitter/" + k, std::string("the effect sets `") + k + "` of its emitters itself, so this is ignored",
                           "An emitter part emits its `burst` once, and its `rate` for `duration` seconds; the entity goes when its particles are gone.");
            if (scratch.burst <= 0 && (scratch.rate <= 0.0f || part.duration <= 0.0))
                p.err(ptr + "/emitter", "this emitter part never emits a particle: its `burst` is 0 and it has no `rate` over a `duration`",
                      "Set \"burst\": 12 in the emitter, or give the part \"duration\": 0.5 and the emitter a `rate`.");
            else if (it->contains("rate") && scratch.rate > 0.0f && part.duration <= 0.0)
                p.warn(ptr + "/emitter/rate", "`rate` does nothing while the part's `duration` is 0: only the `burst` is emitted",
                       "Add \"duration\": 0.5 to the part (not to the emitter) to emit the `rate` for half a second.");
            break;
        }
        case VfxPartKind::Light: {
            if (j.contains("duration") == false) part.duration = 0.2;
            if (part.duration <= 0.0) p.err(ptr + "/duration", "a light needs a duration above 0, it fades out over it", "Example: \"duration\": 0.15.");
            if (auto it = j.find("is3D"); it != j.end()) {
                if (!it->is_boolean()) p.err(ptr + "/is3D", "is3D must be true or false, got " + describe_json_value(*it), "true makes a 3D point light, false (default) a Light2D.");
                else part.light3d = it->get<bool>();
            }
            if (auto it = j.find("light"); it != j.end()) {
                if (!it->is_object()) p.err(ptr + "/light", "light must be an object of " + std::string(part.light3d ? "Light" : "Light2D") + " fields, got " + describe_json_value(*it),
                                           "Example: \"light\": {\"color\": \"#ffe9a0\", \"intensity\": 2, \"radius\": 160}.");
                else {
                    part.light = *it;
                    if (part.light3d) {
                        Light scratch;
                        if (auto r = object_patch_from_json(type_of_component<Light>(), &scratch, *it); !r) p.err(ptr + "/light", r.error().message, r.error().hint);
                    } else {
                        Light2D scratch;
                        if (auto r = object_patch_from_json(type_of_component<Light2D>(), &scratch, *it); !r) p.err(ptr + "/light", r.error().message, r.error().hint);
                    }
                }
            }
            if (auto it = j.find("fade"); it != j.end()) {
                auto c = Curve::parse(*it, "fade");
                if (!c) p.err(ptr + "/fade", c.error().message, c.error().hint);
                else part.fade = *c;
            }
            break;
        }
        case VfxPartKind::Sound: {
            auto it = j.find("clip");
            if (it == j.end() || !it->is_string() || it->get<std::string>().empty())
                p.err(ptr + "/clip", it == j.end() ? "a sound part needs `clip`" : "clip must be an audio file path, got " + describe_json_value(*it),
                      "Example: \"clip\": \"assets/sfx/hit.wav\" (sfx.bake and the audio tools write them).");
            else part.clip = it->get<std::string>();
            double v = part.volume, pi = part.pitch;
            read_number(p, j, "volume", ptr, 0.0, 1.0, v, "a number from 0 to 1");
            read_number(p, j, "pitch", ptr, 0.1, 4.0, pi, "a number from 0.1 to 4");
            part.volume = float(v);
            part.pitch = float(pi);
            if (auto b = j.find("bus"); b != j.end()) {
                if (!b->is_string() || b->get<std::string>().empty()) p.err(ptr + "/bus", "bus must be the name of a mixer bus, got " + describe_json_value(*b), "\"sfx\" (default), \"music\" or \"ui\".");
                else part.bus = b->get<std::string>();
            }
            break;
        }
        case VfxPartKind::Command: {
            auto it = j.find("command");
            if (it == j.end() || !it->is_string()) {
                p.err(ptr + "/command", it == j.end() ? "a command part needs `command`" : "command must be a command name, got " + describe_json_value(*it),
                      "Example: \"command\": \"feel.shake\".");
                break;
            }
            part.command = it->get<std::string>();
            if (!vfx_command_allowed(part.command))
                p.err(ptr + "/command", "an effect may not call '" + part.command + "'",
                      did_you_mean(part.command, vfx_allowed_commands()) +
                          " An effect calls only the game feel effects and the mixer's playback commands, so a file you did not write cannot write files, and the mixer commands change the runtime mix, never the player's saved settings.");
            if (auto a = j.find("args"); a != j.end()) {
                if (!a->is_object()) p.err(ptr + "/args", "args must be an object of the command's arguments, got " + describe_json_value(*a), "Example: \"args\": {\"amount\": 0.5}.");
                else part.args = *a;
            }
            break;
        }
    }
    doc.parts.push_back(std::move(part));
}

}  // namespace

const std::vector<std::string>& vfx_allowed_commands() {
    static const std::vector<std::string> names = {"feel.shake", "feel.hitStop", "feel.flash", "feel.knockback", "feel.squash",
                                                   "feel.spawn", "feel.sound",   "audio.bus",   "audio.snapshot", "audio.music"};
    return names;
}

bool vfx_command_allowed(std::string_view command) {
    const auto& names = vfx_allowed_commands();
    return std::find(names.begin(), names.end(), command) != names.end();
}

Result<std::shared_ptr<const VfxDoc>> parse_vfx(const Json& json, std::string_view fileView, std::vector<VfxIssue>* issuesOut) {
    Parser p;
    p.file = std::string(fileView);
    auto doc = std::make_shared<VfxDoc>();
    doc->path = p.file;

    auto finish = [&]() -> Result<std::shared_ptr<const VfxDoc>> {
        if (issuesOut) *issuesOut = p.issues;
        const VfxIssue* first = nullptr;
        std::size_t errors = 0;
        for (const VfxIssue& i : p.issues)
            if (i.error) {
                if (!first) first = &i;
                ++errors;
            }
        if (!first) return std::shared_ptr<const VfxDoc>(doc);
        std::string msg = (p.file.empty() ? "<effect>" : p.file) + " " + (first->pointer.empty() ? "/" : first->pointer) + ": " + first->message;
        if (errors > 1) msg += std::format(" (and {} more problem{})", errors - 1, errors == 2 ? "" : "s");
        return make_error(msg, first->hint);
    };

    if (!json.is_object()) {
        p.err("", "an effect file must be a JSON object, got " + describe_json_value(json),
              "Start from {\"format\": \"factoria.vfx/1\", \"parts\": [{\"type\": \"emitter\", \"emitter\": {\"burst\": 12}}]} (schemas/vfx.schema.json).");
        return finish();
    }
    static const std::vector<std::string> topKeys = {"$schema", "format", "doc", "duration", "parts"};
    for (auto it = json.begin(); it != json.end(); ++it)
        if (std::find(topKeys.begin(), topKeys.end(), it.key()) == topKeys.end())
            p.err("/" + it.key(), "unknown key '" + it.key() + "'", did_you_mean(it.key(), topKeys));
    if (auto it = json.find("format"); it == json.end() || !it->is_string() || it->get<std::string>() != kFormat)
        p.err("/format", it == json.end() ? "missing `format`" : "format is " + describe_json_value(*it) + ", expected \"factoria.vfx/1\"",
              "Add \"format\": \"factoria.vfx/1\" at the top of the file.");
    if (auto it = json.find("doc"); it != json.end() && it->is_string()) doc->description = it->get<std::string>();

    double fileDuration = -1.0;
    if (auto it = json.find("duration"); it != json.end()) {
        if (!it->is_number() || !std::isfinite(it->get<double>()) || it->get<double>() <= 0.0 || it->get<double>() > kVfxMaxDuration)
            p.err("/duration", "duration must be a number of seconds above 0 and up to 30, got " + describe_json_value(*it),
                  "Leave it out to end the effect when its last part has: \"duration\": 0.8.");
        else fileDuration = it->get<double>();
    }

    auto parts = json.find("parts");
    if (parts == json.end() || !parts->is_array() || parts->empty()) {
        p.err("/parts", parts == json.end() ? "missing `parts`" : parts->is_array() ? "an effect needs at least one part" : "parts must be an array, got " + describe_json_value(*parts),
              "Example: \"parts\": [{\"type\": \"emitter\", \"at\": 0, \"emitter\": {\"burst\": 12}}, {\"type\": \"sound\", \"clip\": \"assets/sfx/hit.wav\"}].");
        return finish();
    }
    if (parts->size() > std::size_t(kVfxMaxParts)) {
        p.err("/parts", std::format("an effect has at most {} parts, this one has {}", kVfxMaxParts, parts->size()),
              "Split it into two effects and play both (a command part cannot start another effect), or merge emitters.");
        return finish();
    }
    std::set<std::string> names;
    std::size_t index = 0;
    for (const Json& part : *parts) parse_part(p, part, index++, *doc, names);
    // A part that failed to parse is not in `doc->parts`, so the indexes below follow the file only when all are fine.
    if (p.has_error()) return finish();

    int emitters = 0, commands = 0;
    double liveParticles = 0.0, end = 0.0;
    for (std::size_t i = 0; i < doc->parts.size(); ++i) {
        const VfxPart& part = doc->parts[i];
        emitters += part.kind == VfxPartKind::Emitter;
        commands += part.kind == VfxPartKind::Command;
        end = std::max(end, part.at + part.duration);
        if (part.kind == VfxPartKind::Emitter) {
            ParticleEmitter scratch;
            (void)object_patch_from_json(type_of_component<ParticleEmitter>(), &scratch, part.emitter);
            liveParticles += std::min<double>(scratch.maxParticles, kParticleHardCap);
        }
        if (fileDuration > 0.0 && part.at > fileDuration)
            p.err("/parts/" + std::to_string(i) + "/at",
                  std::format("this part starts at {:.2f} s but the effect's duration is {:.2f} s, so it would never start", part.at, fileDuration),
                  "Raise \"duration\" or leave it out (the effect then lasts until its last part has ended).");
    }
    if (emitters > kVfxMaxEmitters)
        p.err("/parts", std::format("an effect has at most {} emitters, this one has {}", kVfxMaxEmitters, emitters), "Merge emitters, or use sub-emitters inside one (docs/PARTICLES.md).");
    if (commands > kVfxMaxCommands)
        p.err("/parts", std::format("an effect has at most {} command parts, this one has {}", kVfxMaxCommands, commands), "Fewer commands: one shake and one hit-stop are plenty.");
    if (liveParticles > kVfxMaxLiveParticles)
        p.warn("/parts", std::format("the emitters of this effect may hold up to {:.0f} live particles together", liveParticles),
               std::format("Keep it under {}: lower `maxParticles` of its emitters, so a phone can play several of these at once.", kVfxMaxLiveParticles));
    doc->duration = fileDuration > 0.0 ? fileDuration : end;
    return finish();
}

// -------------------------------------------------------------------------------------------------------------- loading --

namespace {

// A file's modification time moves in steps (15.6 ms on Windows, whole seconds on some network drives), so a second edit of the same
// size within a step keeps the same (mtime, size). Until the file has been left alone for kSettleNs the cache therefore compares the
// content too (a hash of the text); an older file is trusted by (mtime, size), which costs no read.
constexpr std::int64_t kSettleNs = 2'000'000'000;

struct CacheEntry {
    std::int64_t mtime = 0;
    std::int64_t size = 0;
    std::uint64_t hash = 0;
    std::shared_ptr<const VfxDoc> doc;
};
std::mutex g_mutex;
std::map<std::string, CacheEntry>& cache() {
    static auto* c = new std::map<std::string, CacheEntry>();  // leaked: effects may play while statics are destroyed
    return *c;
}

std::uint64_t content_hash(std::string_view text) {
    std::uint64_t h = 1469598103934665603ULL;  // FNV-1a
    for (unsigned char c : text) h = (h ^ c) * 1099511628211ULL;
    return h;
}

std::int64_t now_ns() { return fs::file_time_ns(std::filesystem::file_time_type::clock::now()); }

}  // namespace

VfxCacheUse vfx_cache_use(std::int64_t mtime, std::int64_t size, std::int64_t nowNs, bool hasEntry, std::int64_t entryMtime, std::int64_t entrySize,
                          bool wantIssues) {
    if (!hasEntry || wantIssues || mtime != entryMtime || size != entrySize) return VfxCacheUse::Parse;
    // No time (-1: an APK asset, a backend without one) is never "settled": the text is compared, which costs a read and no parse.
    const bool settled = mtime >= 0 && nowNs - mtime > kSettleNs;
    return settled ? VfxCacheUse::Trust : VfxCacheUse::Compare;
}

Result<std::shared_ptr<const VfxDoc>> load_vfx(std::string_view pathView, std::vector<VfxIssue>* issues) {
    const std::string path(pathView);
    const std::int64_t mtime = fs::modified_time(path);
    const std::int64_t size = fs::file_size(path);
    std::shared_ptr<const VfxDoc> cached;
    std::uint64_t cachedHash = 0;
    VfxCacheUse use = VfxCacheUse::Parse;
    {
        std::lock_guard lock(g_mutex);
        auto it = cache().find(path);
        if (it != cache().end()) {
            use = vfx_cache_use(mtime, size, now_ns(), true, it->second.mtime, it->second.size, issues != nullptr);
            if (use != VfxCacheUse::Parse) {
                cached = it->second.doc;
                cachedHash = it->second.hash;
            }
        }
    }
    if (use == VfxCacheUse::Trust) return cached;
    auto text = fs::read_text(path);
    if (!text)
        return make_error(path + ": cannot read the effect: " + text.error().message,
                          text.error().hint.empty() ? "Effects are *.vfx.json files; check the path." : text.error().hint);
    const std::uint64_t hash = content_hash(*text);
    if (cached && hash == cachedHash) return cached;
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    auto parsed = parse_vfx(*json, path, issues);
    if (!parsed) return parsed.error();
    auto doc = std::make_shared<VfxDoc>(**parsed);
    doc->mtime = mtime;
    std::shared_ptr<const VfxDoc> shared = doc;
    std::lock_guard lock(g_mutex);
    cache()[path] = CacheEntry{mtime, size, hash, shared};
    return shared;
}

std::vector<VfxIssue> vfx_missing_assets(const VfxDoc& doc, const std::function<bool(const std::string&)>& exists) {
    std::vector<VfxIssue> out;
    for (std::size_t i = 0; i < doc.parts.size(); ++i) {
        const VfxPart& part = doc.parts[i];
        if (part.kind != VfxPartKind::Sound || exists(part.clip)) continue;
        out.push_back({true, "/parts/" + std::to_string(i) + "/clip", "the sound '" + part.clip + "' does not exist",
                       "Put the audio file there (sfx.bake and audio.bake write them), or name another clip."});
    }
    return out;
}

void clear_vfx_cache() {
    std::lock_guard lock(g_mutex);
    cache().clear();
}

// ------------------------------------------------------------------------------------------------------------- playing --

namespace {

// A problem that comes back every play is logged once, not every time.
void warn_once(const std::string& key, const std::string& text) {
    static auto* seen = new std::set<std::string>();
    static auto* mutex = new std::mutex();
    std::lock_guard lock(*mutex);
    if (seen->size() >= 256 || !seen->insert(key).second) return;
    FA_WARN("vfx", "{}", text);
}

bool usable(const World& w, Entity e) { return !e.is_null() && w.alive(e) && !w.pending_destroy(e); }

// ---- how long an emitter's entity stays after it stopped emitting ----
// The particles are stepped in the fixed simulation step (World::particles()), with or without a renderer. The entity of a stopped
// emitter is removed by this system, a fixed number of game seconds later: the most its particles can live (lifetime plus its
// variance, plus the trail they leave), plus, for each sub-emitter level, the same again (a particle's death can start the next
// one). It depends only on the emitter's fields and the document, so it is the same on every machine and every frame rate.

double drain_bound(const World& w, const ParticleEmitter& em, int depth) {
    double deepest = 0.0;
    const Json& spec = em.subEmitters;
    if (depth < kParticleSubDepth && spec.is_object()) {
        for (auto ev = spec.begin(); ev != spec.end(); ++ev) {
            std::vector<const Json*> links;
            if (ev.value().is_object()) links.push_back(&ev.value());
            else if (ev.value().is_array()) for (const Json& l : ev.value()) links.push_back(&l);
            for (const Json* l : links) {
                if (!l->is_object()) continue;
                double sub = kVfxMaxDuration;  // a sub-emitter that cannot be read now (it is tried again while the effect plays)
                ParticleEmitter child;
                bool have = false;
                if (auto it = l->find("emitter"); it != l->end()) {
                    have = bool(object_patch_from_json(type_of_component<ParticleEmitter>(), &child, *it));
                } else if (auto pf = l->find("prefab"); pf != l->end() && pf->is_string()) {
                    if (auto r = load_prefab_particle_emitter(pf->get<std::string>())) {
                        child = std::move(*r);
                        have = true;
                    }
                } else if (auto en = l->find("entity"); en != l->end() && en->is_string()) {
                    const Entity target = w.find_by_id(en->get<std::string>());
                    if (!target.is_null())
                        if (const ParticleEmitter* other = w.get<ParticleEmitter>(target)) {
                            child = *other;
                            have = true;
                        }
                }
                if (have) sub = drain_bound(w, child, depth + 1);
                deepest = std::max(deepest, sub);
            }
        }
    }
    return lifespan(em) + deepest;
}

// The emitter of a child stops emitting; from now its entity waits for its particles to be gone, then is removed.
void stop_emitter(World& w, VfxChild& c) {
    if (auto* pe = w.get<ParticleEmitter>(c.entity)) pe->emitting = false;
    if (c.drainLeft < 0.0f) c.drainLeft = c.drainFor;
}

// The play ends (it finished, was stopped, restarts, or the effect changed): its lights go, its emitters stop emitting and are
// kept in the list, detached (part -1), until their particles have drained.
void end_children(World& w, Vfx& v) {
    auto& list = v.rt.children;
    std::size_t keep = 0;
    for (std::size_t i = 0; i < list.size(); ++i) {
        VfxChild c = list[i];
        if (!usable(w, c.entity)) continue;
        if (c.part < 0 || w.get<ParticleEmitter>(c.entity)) {
            stop_emitter(w, c);
            c.part = -1;
            list[keep++] = c;
        } else {
            w.destroy(c.entity);
        }
    }
    list.resize(keep);
}

// Removes the emitters whose particles have had the time to die. `dt`: game seconds since the last call.
void drain_children(World& w, Vfx& v, float dt) {
    auto& list = v.rt.children;
    std::size_t keep = 0;
    for (std::size_t i = 0; i < list.size(); ++i) {
        VfxChild c = list[i];
        if (!usable(w, c.entity)) continue;
        if (c.drainLeft >= 0.0f) {
            c.drainLeft -= dt;
            if (c.drainLeft <= 0.0f) {
                w.destroy(c.entity);
                continue;
            }
        }
        list[keep++] = c;
    }
    list.resize(keep);
}

// ---- the scale of an effect ----
// `vfx.play` `scale` (or the Transform scale of a Vfx placed in a scene) makes the effect look like the same effect that much larger:
// the entity's matrix already scales the offsets of the parts and, through the emitter children, where particles are born and (for an
// emitter that is not in worldSpace) how far they fly. What the matrix does not reach is multiplied here, when a part starts: the size
// of the particles and of their trails, the speed, gravity and turbulence of particles that live in world space, the light radius. Times
// (lifetime, rate, timeline) stay as written, so an effect twice as large lasts as long. A sound or a command part is not touched.

constexpr double kMinEffectScale = 0.001;
constexpr double kMaxEffectScale = 1000.0;

// The size factor of the effect: the geometric mean of the x and y scale of the Vfx entity's world matrix (the scale in the plane;
// equal to the scale of a uniform one).
double effect_scale(const World& w, Entity e) {
    const Mat4 m = w.world_matrix(e);
    const double sx = double(length(Vec3{m.at(0, 0), m.at(0, 1), m.at(0, 2)}));
    const double sy = double(length(Vec3{m.at(1, 0), m.at(1, 1), m.at(1, 2)}));
    const double k = std::sqrt(sx * sy);
    if (!std::isfinite(k)) return 1.0;
    return std::clamp(k, kMinEffectScale, kMaxEffectScale);
}

Json vec3_json(Vec3 v) { return Json::array({v.x, v.y, v.z}); }

// Scales an emitter. `world`: its particles live in world space (the emitter's matrix does not stretch their motion), so their speed,
// gravity and turbulence are lengths of the world and grow with `k`; `shape`: the emission shape is not stretched by a matrix either
// (a sub-emitter's), so its size grows too.
void scale_emitter(ParticleEmitter& pe, float k, bool world, bool shape) {
    pe.startSize *= k;
    pe.endSize *= k;
    pe.trailWidth *= k;
    if (world) {
        pe.speed *= k;
        pe.gravity = pe.gravity * k;
        pe.noiseStrength *= k;
        pe.noiseScale *= k;
    }
    if (shape) pe.shapeSize = pe.shapeSize * k;
}

// The same for the inline sub-emitters of a patch (`subEmitters`): they are patches over the defaults, so the scaled values are written
// out explicitly. A sub-emitter given as a prefab or an entity keeps the size that file has (returned in `external`).
void scale_sub_emitters(Json& spec, float k, bool world, int depth, bool& external) {
    if (depth >= kParticleSubDepth || !spec.is_object()) return;
    for (auto ev = spec.begin(); ev != spec.end(); ++ev) {
        std::vector<Json*> links;
        if (ev.value().is_object()) links.push_back(&ev.value());
        else if (ev.value().is_array()) for (Json& l : ev.value()) links.push_back(&l);
        for (Json* l : links) {
            if (!l->is_object()) continue;
            auto it = l->find("emitter");
            if (it == l->end() || !it->is_object()) {
                if (l->contains("prefab") || l->contains("entity")) external = true;
                continue;
            }
            ParticleEmitter child;
            if (!object_patch_from_json(type_of_component<ParticleEmitter>(), &child, *it)) continue;
            scale_emitter(child, k, world, world);
            (*it)["startSize"] = child.startSize;
            (*it)["endSize"] = child.endSize;
            (*it)["trailWidth"] = child.trailWidth;
            if (world) {
                (*it)["speed"] = child.speed;
                (*it)["gravity"] = vec3_json(child.gravity);
                (*it)["noiseStrength"] = child.noiseStrength;
                (*it)["noiseScale"] = child.noiseScale;
                (*it)["shapeSize"] = vec3_json(child.shapeSize);
            }
            if (it->contains("subEmitters")) scale_sub_emitters((*it)["subEmitters"], k, world, depth + 1, external);
        }
    }
}

void start_part(World& w, Entity e, Vfx& v, std::size_t index, const VfxHost& host) {
    const VfxDoc& doc = *v.rt.doc;
    const VfxPart& part = doc.parts[index];
    auto child = [&]() -> Entity {
        Entity c = w.create(part.name);
        if (auto* info = w.get<EntityInfo>(c)) info->scriptSpawned = true;  // scene.save leaves it out: the effect makes it again
        w.set_parent(c, e, false);
        if (auto* t = w.get<Transform>(c)) t->position = part.offset;
        return c;
    };
    switch (part.kind) {
        case VfxPartKind::Emitter: {
            Entity c = child();
            auto& pe = w.add<ParticleEmitter>(c);
            (void)object_patch_from_json(type_of_component<ParticleEmitter>(), &pe, part.emitter);
            if (const double k = effect_scale(w, e); std::fabs(k - 1.0) > 1e-6) {
                scale_emitter(pe, float(k), pe.worldSpace, false);
                bool external = false;
                scale_sub_emitters(pe.subEmitters, float(k), pe.worldSpace, 0, external);
                if (external)
                    warn_once(doc.path + "|" + std::to_string(index) + "|scale-sub",
                              std::format("{} /parts/{}/emitter/subEmitters: a sub-emitter given as a prefab or an entity keeps its own size when the effect is scaled",
                                          doc.path, index));
            }
            pe.autoDestroy = false;  // this system removes it, at the same game time on every machine (drain_bound)
            pe.emitting = part.duration > 0.0;
            VfxChild vc{c, std::int32_t(index), 1.0f};
            vc.origin = std::int32_t(index);
            vc.drainFor = float(drain_bound(w, pe, 0) + kVfxDrainSlack);
            if (!pe.emitting) vc.drainLeft = vc.drainFor;  // a burst only: it stopped emitting before it began
            v.rt.children.push_back(vc);
            break;
        }
        case VfxPartKind::Light: {
            Entity c = child();
            float base = 1.0f;
            if (part.light3d) {
                auto& l = w.add<Light>(c);
                l.type = LightType::Point;
                (void)object_patch_from_json(type_of_component<Light>(), &l, part.light);
                l.range *= float(effect_scale(w, e));
                base = l.intensity;
            } else {
                auto& l = w.add<Light2D>(c);
                (void)object_patch_from_json(type_of_component<Light2D>(), &l, part.light);
                const float k = float(effect_scale(w, e));
                l.radius *= k;
                l.height *= k;
                base = l.intensity;
            }
            v.rt.children.push_back({c, std::int32_t(index), base});
            break;
        }
        case VfxPartKind::Sound:
            if (host.play_sound && !host.play_sound(part.clip, part.volume, part.pitch, part.bus))
                warn_once(doc.path + "|" + std::to_string(index) + "|sound",
                          std::format("{} /parts/{}/clip: the sound '{}' could not be played (see the audio log)", doc.path, index, part.clip));
            break;
        case VfxPartKind::Command:
            if (host.call) {
                const std::string why = host.call(part.command, part.args);
                if (!why.empty())
                    warn_once(doc.path + "|" + std::to_string(index) + "|" + why,
                              std::format("{} /parts/{}/command: {} failed: {}", doc.path, index, part.command, why));
            }
            break;
    }
}

void animate_children(World& w, Vfx& v) {
    const VfxDoc& doc = *v.rt.doc;
    auto& list = v.rt.children;
    std::size_t keep = 0;
    for (std::size_t i = 0; i < list.size(); ++i) {
        VfxChild c = list[i];
        if (!usable(w, c.entity)) continue;
        if (c.part < 0 || std::size_t(c.part) >= doc.parts.size()) {  // an emitter of an earlier play: it only drains
            list[keep++] = c;
            continue;
        }
        const VfxPart& part = doc.parts[std::size_t(c.part)];
        if (part.kind == VfxPartKind::Light) {
            const double t = part.duration > 0.0 ? (double(v.time) - part.at) / part.duration : 1.0;
            if (t >= 1.0) {
                w.destroy(c.entity);
                continue;
            }
            const float k = part.fade.empty() ? float(1.0 - std::max(0.0, t)) : part.fade.eval(float(std::max(0.0, t)));
            if (auto* l2 = w.get<Light2D>(c.entity)) l2->intensity = c.baseIntensity * k;
            else if (auto* l3 = w.get<Light>(c.entity)) l3->intensity = c.baseIntensity * k;
        } else if (part.kind == VfxPartKind::Emitter) {
            if (double(v.time) >= part.at + part.duration) stop_emitter(w, c);
        }
        list[keep++] = c;
    }
    list.resize(keep);
}

// A looping effect starts a new round: the file may have changed since the last one, so it is read again (hot reload; a round that has
// begun finishes the version it started with). A document that cannot be read now keeps the last good version.
void reload_for_round(Vfx& v, const VfxHost& host) {
    Result<std::shared_ptr<const VfxDoc>> doc = host.load ? Result<std::shared_ptr<const VfxDoc>>(host.load(v.effect)) : load_vfx(v.effect);
    if (!doc || !*doc) return;
    v.rt.doc = *doc;
    v.duration = float(v.rt.doc->duration);
}

void restart(Vfx& v) {
    v.time = 0.0f;
    v.rt.started = 0;
    v.rt.finished = false;
}

}  // namespace

double vfx_emitter_drain_seconds(const World& world, const ParticleEmitter& em) { return drain_bound(world, em, 0); }

int vfx_playing_count(const World& world) { return world.vfx_live(); }

void update_vfx(World& world, float dt, const VfxHost& host) {
    const std::vector<Entity> all = world.entities_with(&World::type_of<Vfx>());
    int live = 0;  // effects that play or still hold child entities: the budget of vfx_play
    for (Entity e : all) {
        if (!usable(world, e)) continue;
        Vfx* vp = world.get<Vfx>(e);
        if (!vp || !world.active_in_hierarchy(e)) continue;
        Vfx& v = *vp;
        VfxRuntime& rt = v.rt;
        if (!rt.seen) {
            rt.seen = true;
            if (v.autoplay) v.playing = true;
        }
        // A new `effect`, or a replay of one that ended: read the document (the file may have changed on disk).
        if (!rt.tried || v.effect != rt.loadedEffect || (v.playing && rt.finished)) {
            const bool changed = rt.tried && v.effect != rt.loadedEffect;
            if (changed || rt.finished) end_children(world, v);
            rt.tried = true;
            rt.loadedEffect = v.effect;
            rt.doc.reset();
            restart(v);
            v.duration = 0.0f;
            if (v.effect.empty()) {
                v.playing = false;
            } else if (v.playing) {
                Result<std::shared_ptr<const VfxDoc>> doc = host.load ? Result<std::shared_ptr<const VfxDoc>>(host.load(v.effect)) : load_vfx(v.effect);
                if (doc && !*doc) doc = make_error("the document '" + v.effect + "' is not available", "Check the path of the effect.");
                if (!doc) {
                    warn_once(v.effect + "|" + std::to_string(fs::modified_time(v.effect)) + "|load",
                              std::format("entity '{}' Vfx: {}{}", world.id_of(e), doc.error().message,
                                          doc.error().hint.empty() ? "" : " (hint: " + doc.error().hint + ")"));
                    v.playing = false;
                    rt.finished = true;
                } else {
                    rt.doc = *doc;
                    v.duration = float(rt.doc->duration);
                }
            } else {
                rt.tried = false;  // not playing yet: read the file when it starts
            }
        }
        if (rt.doc && v.playing) {
            const float speed = std::clamp(v.speed, 0.05f, 20.0f);
            if (dt > 0.0f) v.time += dt * speed;
            const VfxDoc& doc = *rt.doc;
            for (std::size_t i = 0; i < doc.parts.size(); ++i)
                if (!(rt.started & (1u << i)) && double(v.time) >= doc.parts[i].at) {
                    rt.started |= 1u << i;
                    start_part(world, e, v, i, host);
                }
            animate_children(world, v);
            const double end = v.loop ? std::max(doc.duration, kVfxMinLoop) : doc.duration;
            if (double(v.time) >= end && rt.started == (doc.parts.size() >= 32 ? ~0u : (1u << doc.parts.size()) - 1u)) {
                // The effect is over, whatever its parts were still doing (an explicit file `duration` can be shorter than a
                // part): lights end and emitters stop emitting, then drain.
                end_children(world, v);
                if (v.loop) {
                    reload_for_round(v, host);
                    restart(v);
                } else {
                    v.playing = false;
                    rt.finished = true;
                }
            }
        }
        // The emitters of an ended play leave when their particles have had the time to die, with or without a renderer.
        if (!rt.children.empty()) drain_children(world, v, dt);
        if (rt.finished && v.autoDestroy && rt.children.empty() && !world.pending_destroy(e)) world.destroy(e);
        else if (v.playing || !rt.children.empty()) ++live;
    }
    world.set_vfx_live(live);
}

Result<Entity> vfx_play(World& world, std::string_view effect, const VfxPlayOptions& o) {
    auto doc = load_vfx(effect);
    if (!doc) return doc.error();
    if (!(o.speed >= 0.05f && o.speed <= 20.0f))
        return make_error("speed must be between 0.05 and 20, got " + std::to_string(o.speed), "1 plays the effect as written, 2 twice as fast.");
    if (!(o.scale > 0.0f && o.scale <= 1000.0f))
        return make_error("scale must be above 0 and at most 1000, got " + std::to_string(o.scale), "1 is the size the effect was written for.");
    if (!o.parent.is_null() && !usable(world, o.parent))
        return make_error("the parent entity of the effect is gone (destroyed, or about to be) so the effect cannot follow it",
                          "Pass an entity that is alive when vfx.play runs (a script checks entity.alive), or leave `entity` out to play the effect in world space at a position.");
    if (vfx_playing_count(world) >= kVfxMaxPlaying) {
        warn_once("vfx-budget", std::format("{} effects are playing already: further vfx.play calls are dropped until some end (kVfxMaxPlaying)", kVfxMaxPlaying));
        return kNullEntity;
    }
    std::string name = std::string(effect);
    if (auto slash = name.find_last_of('/'); slash != std::string::npos) name = name.substr(slash + 1);
    if (ends_with(name, ".vfx.json")) name.resize(name.size() - 9);
    Entity e = world.create("vfx " + name);
    if (auto* info = world.get<EntityInfo>(e)) info->scriptSpawned = true;
    if (!o.parent.is_null()) world.set_parent(e, o.parent, false);
    if (auto* t = world.get<Transform>(e)) {
        t->position = o.position;
        t->rotation = {0, 0, o.rotation};
        t->scale = {o.scale, o.scale, o.scale};
    }
    world.set_vfx_live(world.vfx_live() + 1);
    auto& v = world.add<Vfx>(e);
    v.effect = std::string(effect);
    v.autoplay = true;
    v.autoDestroy = true;
    v.loop = o.loop;
    v.speed = o.speed;
    return e;
}

void vfx_stop(World& world, Entity e, bool immediate) {
    if (!usable(world, e)) return;
    Vfx* v = world.get<Vfx>(e);
    if (!v) return;
    if (immediate) {
        world.destroy(e);
        return;
    }
    end_children(world, *v);
    v->playing = false;
    v->loop = false;
    v->rt.seen = true;
    v->rt.finished = true;
}

}  // namespace fa
