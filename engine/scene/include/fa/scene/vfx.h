// Effect documents: a `*.vfx.json` bundles several emitters, a light flash, sounds and commands (a camera shake, a hit-stop, ...)
// on one timeline, so a game plays "the hit effect" with one call: `vfx.play` (a command and `vfx.play()` in scripts) or an entity
// with a `Vfx` component placed in a scene like a prefab. See docs/PARTICLES.md, "Effect documents".
//
// The file (format "factoria.vfx/1", schemas/vfx.schema.json) is parsed into a VfxDoc: plain data, checked once, with errors that
// name the file and the JSON pointer and say how to fix it. update_vfx() is the system: once per fixed step, with the step's length
// times time.scale, it advances every playing Vfx and starts the parts whose time has come. It uses no clock and no random numbers:
// the same effects at the same steps do the same things on every run and platform.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/curve.h"
#include "fa/scene/world.h"

namespace fa {

// ------------------------------------------------------------------------------------------------------------ limits --
constexpr int kVfxMaxParts = 16;          // parts (emitters, lights, sounds, commands) of one effect
constexpr int kVfxMaxEmitters = 8;        // of those, emitters
constexpr int kVfxMaxCommands = 8;        // of those, commands
constexpr double kVfxMaxDuration = 30.0;  // seconds: the longest an effect, or a part of it, may last
constexpr double kVfxMaxLifespan =
    30.0;  // seconds: the longest one particle of an emitter of an effect may be seen (lifetime with variance, plus trailTime); parse_vfx refuses more
constexpr double kVfxMinLoop =
    0.1;  // seconds: a looping effect shorter than this waits until it is this long before it restarts
// seconds added to the time an emitter's particles need to die before its entity is removed (particles are stepped in
// whole fixed steps)
constexpr double kVfxDrainSlack = 0.1;
constexpr int kVfxMaxPlaying =
    64;  // Vfx playing, or still holding emitters and lights, at once: a play past this is dropped (and logged once)
constexpr int kVfxMaxLiveParticles =
    4000;  // warning: the emitters of one effect may hold more live particles than this together

enum class VfxPartKind { Emitter, Light, Sound, Command };

// One thing the effect does. Which fields are used depends on `kind`; the rest keep their defaults.
struct VfxPart {
    VfxPartKind kind = VfxPartKind::Emitter;
    std::string
        name;         // names the child entity an emitter or a light becomes ("sparks"); defaults to the kind and index
    double at = 0.0;  // seconds after the effect starts
    double duration =
        0.0;  // emitter: how long it keeps emitting its `rate` (0: only its burst); light: how long it lasts
    Vec3 offset{0, 0, 0};  // emitter and light: where, relative to the effect

    Json emitter = Json::object();  // Emitter: the fields of a ParticleEmitter (a patch over the defaults)
    bool light3d = false;           // Light: a 3D Light instead of a Light2D
    Json light = Json::object();    // Light: the fields of the Light2D (or Light when light3d)
    Curve fade;  // Light: multiplies its intensity over its life, position 0..1; empty = a straight fade out

    std::string clip;         // Sound: the audio file
    float volume = 1.0f;      // Sound
    float pitch = 1.0f;       // Sound
    std::string bus = "sfx";  // Sound: mixer bus

    std::string command;         // Command: the command to call, e.g. "feel.shake"
    Json args = Json::object();  // Command: its arguments
};

struct VfxDoc {
    std::string path;         // where it was read from
    std::string description;  // the file's "doc"
    double duration = 0.0;    // seconds until every part has started and ended (the file's "duration", or worked out)
    std::vector<VfxPart> parts;
    std::int64_t mtime = 0;  // of the file when it was read (cache validity)
};

// One thing wrong, or useless, in a document. `pointer` is a JSON pointer inside the file ("/parts/2/clip").
struct VfxIssue {
    bool error = true;  // false: a warning, the effect still plays
    std::string pointer;
    std::string message;
    std::string hint;
};

// The commands a `command` part may call, by exact name: the game feel effects (feel.shake, feel.hitStop, feel.flash, feel.knockback,
// feel.squash, feel.spawn, feel.sound) and the playback ones of the mixer (audio.bus, audio.snapshot, audio.music). Nothing that writes a
// file (audio.create, audio.edit, audio.bake) or changes a setting of the player (feel.settings) or ends other effects (feel.cancel).
// parse_vfx rejects any other name, and the runtime checks it again before it calls the command.
const std::vector<std::string>& vfx_allowed_commands();
bool vfx_command_allowed(std::string_view command);

// Checks a parsed JSON document. On an error the Error names the file, the pointer and the fix of the first problem (and says how
// many more there are); `issues` receives every problem, warnings included, and is filled on success too.
Result<std::shared_ptr<const VfxDoc>> parse_vfx(const Json& json, std::string_view file,
                                                std::vector<VfxIssue>* issues = nullptr);

// Reads a document through fa::fs. Cached per path, modification time and size: every Vfx that plays the same file shares one
// VfxDoc, and a file that changed on disk is read again by the next call (hot reload: a play that has begun finishes the version it
// started with; a looping effect reads the file again at the start of each round). A file touched in the last two seconds is also
// compared by content, because a file's time moves in steps and a second edit of the same size can keep the same time. A file the backend gives
// no time for (modified_time -1: the assets of an Android APK) is always compared by content, never parsed again while its text is the same.
// An unreadable or invalid file is an Error; the cache keeps the last good version.
Result<std::shared_ptr<const VfxDoc>> load_vfx(std::string_view path, std::vector<VfxIssue>* issues = nullptr);
// What load_vfx does with the cache for a file (its decision, public for tests): Parse = no entry for this time and size (or the caller wants
// the issues), read and parse; Compare = read the file and reuse the entry when the text hash is the same; Trust = reuse the entry without
// reading. `nowNs` is the clock of fs::file_time_ns; an entry is given as `hasEntry` with the time and size it was made for.
enum class VfxCacheUse { Parse, Compare, Trust };
VfxCacheUse vfx_cache_use(std::int64_t mtime, std::int64_t size, std::int64_t nowNs, bool hasEntry,
                          std::int64_t entryMtime, std::int64_t entrySize, bool wantIssues);
void clear_vfx_cache();  // forgets every cached document (tests)

// The files a document names that `exists` says are not there (the clips of its sound parts), as errors with the JSON pointer and
// the fix. `exists` takes the path as written in the file; the runtime passes fa::fs::exists, the project validator a check
// against the project folder.
std::vector<VfxIssue> vfx_missing_assets(const VfxDoc& doc, const std::function<bool(const std::string&)>& exists);

// What the system needs from the game. Unset members do nothing (a headless test with no audio).
struct VfxHost {
    // Plays a one-shot sound; returns false when it could not start (logged by the caller once).
    std::function<bool(const std::string& clip, float volume, float pitch, const std::string& bus)> play_sound;
    // Calls a command; returns "" when it worked, else what went wrong.
    std::function<std::string(const std::string& command, const Json& args)> call;
    // Where the documents come from. Unset (the game): load_vfx, the file through fa::fs. The editor's Particle panel sets it to
    // play the document it is editing from memory, so a preview never waits for a file's modification time. An empty pointer is a
    // document that cannot be read (logged once, nothing plays), as an unreadable file is.
    std::function<std::shared_ptr<const VfxDoc>(const std::string& effect)> load;
};

// Advances every active Vfx by `dt` seconds (dt 0: only a change of `playing` or `effect` applies): loads its
// document, starts the parts whose time has come (children of the Vfx entity: ParticleEmitter, Light2D / Light),
// animates the lights, and at the end of the effect clears `playing`, ends its lights and stops its emitters. A
// stopped emitter's entity is removed a fixed time later, the longest its particles (and those of its sub-emitters)
// can live, so the entities that exist depend only on the document (the particles themselves are stepped in the fixed
// step, with or without a renderer). With `autoDestroy` the Vfx entity goes with its last emitter. A document that
// cannot be read is logged once per file and change. Run once per FIXED step, like update_videos().
void update_vfx(World& world, float dt, const VfxHost& host);

// Starts an effect: a new entity with a Vfx component (autoDestroy on), at `position` in the world, or a child of `parent` at
// `position` relative to it. Returns the entity, or the reason it could not start (file problem, budget). The effect starts at
// the next update_vfx. `scale` sets the Transform scale of the effect's entity, and the effect looks like the same one that many times
// larger: the matrix scales the offsets of the parts, the emission shape and (for an emitter that is not in worldSpace) the distance
// particles fly; when a part starts, the particle and trail size, and for worldSpace emitters the start speed, gravity and turbulence,
// the light radius (range for a 3D light) and its height are multiplied by it too. Times stay as written, command parts call their
// command with the arguments written in the file, and a sub-emitter given as a prefab or an entity keeps its own size. The factor is
// the geometric mean of the x and y scale of the Vfx entity's world matrix, so a Vfx placed in a scene under a scaled parent scales too.
struct VfxPlayOptions {
    Vec3 position{0, 0, 0};
    Entity parent = kNullEntity;  // not null: follows this entity, `position` is local to it
    float rotation = 0.0f;        // degrees around z (2D)
    float scale =
        1.0f;  // 2 = the same effect twice as large (see update_vfx); times and command arguments are not scaled
    float speed = 1.0f;  // 1 = as written; 2 = twice as fast
    bool loop = false;
};
Result<Entity> vfx_play(World& world, std::string_view effect, const VfxPlayOptions& options = {});

// Ends an effect. immediate: the entity and its children go at once (their particles vanish); else the parts that have not
// started never do, lights end, and emitters stop emitting but let their particles finish (their entities go once those have had the
// time to die, as at the end of an effect).
void vfx_stop(World& world, Entity vfx, bool immediate);

// True when the effect plays now, or will start at the next update_vfx (vfx_play just made it, or a scene has it on autoplay and the
// system has not looked at it yet): what the vfx.list command lists.
inline bool vfx_starts_next_step(const Vfx& v) { return !v.playing && v.autoplay && !v.rt.seen && !v.effect.empty(); }

// The longest the particles of `em` can be seen after it stopped emitting, in game seconds: lifetime with its variance, plus the trail, plus
// for each sub-emitter level the longest chain of the same (a sub-emitter that cannot be read counts kVfxMaxDuration). The time an emitter
// entity of an effect stays before the system removes it, less kVfxDrainSlack. `world` resolves sub-emitters given as an entity.
double vfx_emitter_drain_seconds(const World& world, const ParticleEmitter& em);

// How many effects play or still hold emitters and lights (the budget kVfxMaxPlaying counts them). A counter the system keeps
// (World::vfx_live), not a scan.
int vfx_playing_count(const World& world);

}  // namespace fa
