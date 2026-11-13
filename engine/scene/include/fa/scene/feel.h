// Game feel: the short effects that make a hit, a jump or an explosion read on screen. Camera shake, hit-stop, a flash of
// colour, knockback, and squash and stretch. docs/GAME_FEEL.md is the guide; this header is the C++ side that the script
// API (camera.shake, time.hitStop, entity.flash / knockback / squash), the `feel.*` commands and the clip events of the
// Animator, the SpriteAnimator and the clip files (M62.2) all call, so there is one implementation of each effect.
//
// WHERE THE STATE LIVES. Not in components: an effect is a moment, not part of a scene file. World owns one FeelState
// (World::feel()); World::clear() (every scene load that is not additive) drops the effects, hit-stop included, and keeps the
// player's accessibility choices. Nothing here writes a Transform except knockback of an entity without a physics body.
//
// A VISUAL EFFECT NEVER CHANGES THE SCENE. Shake and squash are a "visual pose" added at DRAW time: World::drawn_matrix() is
// the same chain as world_matrix() with each entity's pose multiplied in, and only fa_render's drawing uses it (the camera's
// shake offset and roll also go into OrthoView, the pointer mapping, so a click lands on what is drawn). Physics, audio, bounds,
// UI hit-tests, scripts and saved scenes keep reading world_matrix() and the Transform fields, so
// `entity.scale` is exactly what the script set, a follow camera does not chase its own shake, and squash can never leave a
// scale behind.
//
// CLOCKS (feel_update, feel_fixed_update). Shake, flash and squash run on the game clock WITHOUT hit-stop (real time times
// `time.scale`): they keep moving while the game is frozen, which is what makes the frozen frame read as an impact; they
// stop with `time.scale = 0` (a paused game does not shake). Knockback runs on the game clock WITH hit-stop (it is part of the
// simulation). The hit-stop timer itself runs in real time (feel_begin_frame).
//
// ACCESSIBILITY. reduce_motion() and reduced_effects() (below) follow the system's "reduce motion" unless the game set its own
// (FeelState::reduceMotionSetting / reducedEffectsSetting): shake and squash shrink to kReduceMotionShake / kReduceMotionSquash,
// hit-stop to kReduceMotionHitStop of its duration, flash to at most kReducedEffectsFlash and always fading (no square-wave
// strobe). The reduction is applied when the action starts.
#pragma once

#include <map>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

class World;

// ----------------------------------------------------------------------------------------------- accessibility factors
inline constexpr float kReduceMotionShake = 0.25f;    // shake amount multiplier with reduce motion on
inline constexpr float kReduceMotionSquash = 0.25f;   // squash amount multiplier with reduce motion on
inline constexpr float kReduceMotionHitStop = 0.5f;   // hit-stop duration multiplier with reduce motion on
inline constexpr float kReducedEffectsFlash = 0.35f;  // largest flash strength with reduced effects on

inline constexpr float kDefaultKnockbackSpeed = 6.0f;  // metres per second when `speed` is not given

inline constexpr float kMaxHitStopSeconds =
    5.0f;  // a longer freeze is almost always a mistake (a script that forgot a unit)

// ------------------------------------------------------------------------------------------------------------ options
struct ShakeOptions {
    float amount = 0.4f;      // trauma to add, 0..1; trauma stacks up to `cap` and the shake is trauma squared
    float duration = 0.4f;    // seconds the shake takes to die out (a longer one already running is kept)
    float frequency = 25.0f;  // noise samples per second (how jittery)
    float maxOffset =
        0.0f;  // largest offset at trauma 1, world units; 0 = the camera's default (feel_default_shake_offset)
    float maxAngle = 2.0f;  // largest turn at trauma 1, degrees
    float cap = 1.0f;       // trauma never goes above this (0..1)
};

struct FlashOptions {
    Color color{1, 1, 1, 1};  // the colour the entity is drawn in (alpha ignored)
    float duration = 0.12f;   // seconds
    bool fade =
        true;  // true: from `strength` down to 0 over the duration; false: `strength` for the whole duration, then off
    float strength = 1.0f;  // 0..1: how much of the colour replaces the entity's own (1 = solid)
};

struct SquashOptions {
    float amount =
        0.3f;  // > 0 squashes (wider and flatter), < 0 stretches (taller and thinner); 0.3 is a clear landing
    float duration = 0.3f;  // seconds until the entity is back to exactly its own scale
    char axis = 'y';        // 'y' or 'x': the axis that gets shorter when `amount` > 0
};

struct KnockbackOptions {
    Vec3 direction{1, 0, 0};  // which way (any length; normalised). z is used by 3D bodies only
    // World units per second added to the velocity at once. Unset = kDefaultKnockbackSpeed metres per second: for an entity with
    // a 3D body or mesh that many units, for every other (2D) one times FeelState::pixelsPerMeter, because a 2D world unit is a
    // pixel and 6 pixels per second would not be seen. A speed you give is in world units, whatever the entity.
    std::optional<float> speed;
    float lockTime = 0.25f;  // seconds `isKnockedBack` stays true (the loss of control)
    float decay = 8.0f;      // entities WITHOUT a dynamic body: the velocity falls by exp(-decay * dt) per second
    bool local =
        false;  // true: `direction` is in the entity's own space (its world matrix turns it, a mirrored sprite flips x)
};

struct HitStopOptions {
    float duration = 0.08f;  // real seconds
    float scale = 0.0f;      // game-time scale during the stop: 0 = frozen, 0.2 = slow motion
};

// Makes an effect appear: a prefab instantiated at the entity (plus `offset`) the next time feel_update runs.
struct SpawnOptions {
    std::string prefab;    // project-relative path of the prefab (required)
    Vec3 offset{0, 0, 0};  // added to the world position of the entity the action belongs to
    bool local = false;    // true: `offset` is in the entity's own space (a mirrored sprite flips x)
    float lifetime =
        0.0f;  // seconds of game time (a hit-stop or a pause holds it) after which the spawned entity is destroyed; 0 = the prefab ends itself
};

// Plays a sound once. The sound goes to a queue that Audio::update drains (the audio module sits above this one).
struct SoundOptions {
    std::string path;         // project-relative path of the clip (required)
    float volume = 1.0f;      // 0..4
    float pitch = 1.0f;       // 0.1..4
    float pan = 0.0f;         // -1 left .. 1 right
    std::string bus = "sfx";  // "sfx", "music", "ui" or a bus of the project
};

// ------------------------------------------------------------------------------------------------------------- state
// What World::drawn_matrix adds to an entity's local transform: position and euler degrees are added, scale is multiplied.
struct FeelPose {
    Vec3 position{0, 0, 0};
    Vec3 rotation{0, 0, 0};
    Vec3 scale{1, 1, 1};
};

struct FeelShake {
    float trauma = 0.0f;
    float remaining = 0.0f;  // seconds until it is over
    float decay = 0.0f;      // trauma per second
    float frequency = 25.0f;
    float maxOffset = 0.0f;
    float maxAngle = 2.0f;
    std::uint32_t seed = 0;
    double phase = 0.0;  // position in the noise (samples)
    bool perspective = false;
};

struct FeelFlash {
    Color color{1, 1, 1, 1};
    float duration = 0.0f;
    float remaining = 0.0f;
    float strength = 1.0f;
    bool fade = true;
};

struct FeelSquash {
    float amount = 0.0f;
    float duration = 0.0f;
    float time = 0.0f;
    char axis = 'y';
    bool volume3d = false;  // an entity with a mesh keeps x * y * z constant, a 2D one x * y
};

struct FeelKnock {
    Vec3 velocity{};  // body-less entities: world units per second, decaying
    float decay = 8.0f;
    float lockRemaining = 0.0f;
};

struct FeelEntity {
    std::optional<FeelShake> shake;
    std::optional<FeelFlash> flash;
    std::optional<FeelSquash> squash;
    std::optional<FeelKnock> knock;
    FeelPose pose;  // computed by feel_update from shake and squash
    bool hasPose = false;
};

struct FeelHitStop {
    float remaining = 0.0f;
    float scale = 0.0f;
};

// A sound waiting for the audio system (FeelState::sounds).
struct FeelSound {
    SoundOptions options;
    std::string
        source;  // id of the entity whose action asked for it ("" when none): the audio play log shows it as the source of the sound
};

// An effect prefab waiting to be instantiated, and a spawned entity that is destroyed when its time is up.
struct FeelSpawn {
    SpawnOptions options;
    Vec3 position{};  // where, in the world: computed when the action ran
};
struct FeelLifetime {
    std::uint64_t entity = 0;  // Entity::bits()
    float remaining = 0.0f;
};

class FeelState {
public:
    // The per-entity records, keyed by Entity::bits() (ordered, so output and iteration are deterministic).
    std::map<std::uint64_t, FeelEntity> entities;
    std::vector<FeelHitStop> hitStops;  // the running hit-stops (a few at most)
    std::uint32_t counter = 0;          // makes the seed of every shake different
    std::size_t poseCount = 0;          // records with hasPose: 0 = drawn_matrix is world_matrix
    float pixelsPerMeter =
        100.0f;  // factoria.json physics.pixelsPerMeter, pushed by the runtime: the 2D default of knockback
    bool warnedNoCamera = false;    // a shake with no camera in the scene was ignored and said so (once per scene)
    std::vector<FeelSound> sounds;  // `sound` actions since the audio system last drained them (feel_take_sounds)
    std::vector<FeelSpawn>
        spawns;  // `spawn` actions waiting for feel_update (a spawn never happens inside an iteration)
    std::vector<FeelLifetime> lifetimes;      // spawned effects with a `lifetime`
    std::set<std::string> warnedClipActions;  // clip-event actions that failed and said so (once each per scene)
    std::set<std::string>
        failedSounds;  // `sound` paths the audio system could not play in this scene: not tried (decoded, listed) again until the scene changes

    // The player's choices; they survive World::clear() (they are not part of a scene). null = follow the system.
    std::optional<bool> reduceMotionSetting;
    std::optional<bool> reducedEffectsSetting;
    bool systemReduceMotion = false;  // the operating system's value, pushed by the runtime every frame

    bool reduce_motion() const { return reduceMotionSetting ? *reduceMotionSetting : systemReduceMotion; }
    bool reduced_effects() const { return reducedEffectsSetting ? *reducedEffectsSetting : systemReduceMotion; }

    // Multiplier of the game clock caused by hit-stops: 1 when none runs, else the smallest scale of the running ones.
    float hit_stop_factor() const;
    float hit_stop_remaining() const;  // the longest running one, seconds (0 = none)

    const FeelEntity* find(Entity e) const;
    FeelEntity* find(Entity e);
    const FeelPose* pose_of(Entity e) const;  // null = no visual pose now
    // The flash colour of `e` itself with alpha = how much of it shows now (0..1); null = not flashing.
    std::optional<Color> flash_of(Entity e) const;
    bool any_flash() const;
    bool knocked_back(Entity e) const;
    float knockback_remaining(Entity e) const;

    void clear_scene();  // World::clear(): drops the effects, keeps the settings
};

// ------------------------------------------------------------------------------------------------------------ actions
// Each returns an error that says what to fix, or {}. `camera` null = the main camera (camera.main).
Result<void> feel_shake(World& w, Entity camera, const ShakeOptions& o);
Result<void> feel_hit_stop(World& w, const HitStopOptions& o);
Result<void> feel_flash(World& w, Entity e, const FlashOptions& o);
Result<void> feel_knockback(World& w, Entity e, const KnockbackOptions& o);
Result<void> feel_squash(World& w, Entity e, const SquashOptions& o);
// Queues the spawn of `o.prefab` at `e`'s position (+ offset), or at `o.offset` when `e` is null; feel_update instantiates it. The prefab path is checked when it
// is instantiated (a missing file is logged once), not here. At most kMaxQueuedSpawns per frame: past that the call returns an error that says so (a clip event logs it once per scene; the effect is not queued).
Result<void> feel_spawn(World& w, Entity e, const SpawnOptions& o);
// Queues a sound for Audio::update. `source` is the entity the action belongs to (null = none).
Result<void> feel_sound(World& w, Entity source, const SoundOptions& o);
// The sounds queued since the last call, oldest first; the audio system plays them. At most kMaxQueuedSounds wait (a world
// that nobody drains, e.g. a headless test without audio, does not grow without limit: the oldest are dropped).
std::vector<FeelSound> feel_take_sounds(World& w);
inline constexpr std::size_t kMaxQueuedSounds = 64;
// At most this many `spawn` actions wait for one feel_update; the extra ones of that frame are refused with an error.
inline constexpr std::size_t kMaxQueuedSpawns = 64;
// Stops everything of `e` (null = every effect of the world, hit-stops included). Flash, squash and shake end at once.
void feel_cancel(World& w, Entity e);

// The action as JSON, what clip events and the `feel.*` commands pass: {"action": "shake" | "hitStop" | "flash" | "knockback" |
// "push" | "squash" | "spawn" | "sound", ...the options of that action by their field names}. "push" is "knockback". `target`
// is the entity of flash, knockback, squash, spawn and sound (and the camera of shake, null = main). Unknown keys and wrong
// types are errors with a "did you mean".
Result<void> feel_apply_action(World& w, Entity target, const Json& action);
// Checks an action as feel_apply_action would (keys, types, ranges) without a world and without doing anything: what a clip
// file's load and `validate` use, so a typo in a clip is found before the game runs.
Result<void> feel_check_action(const Json& action);
// The names feel_apply_action accepts for "action".
const std::vector<std::string>& feel_action_names();

// The actions of one clip event (what `feel` of an event holds, already split into single actions), run for the entity that
// plays the clip: shake goes to that entity when it is a camera, else to the main one. A failing action is logged once per
// scene with `where` ("Animator 'hero' clip 'attack' at 0.3 s") and the rest still run: an event never stops an animation.
void feel_run_clip_actions(World& w, Entity player, const std::vector<Json>& actions, std::string_view where);
// The `feel` of an event object as a list of actions (one object = a list of one); empty when it has none or it is not an object
// or array. No checking: read_event_feel (anim_clip.h) checks, this is what the playback of an inline event reads.
std::vector<Json> feel_event_actions(const Json& event);

// Camera default for ShakeOptions::maxOffset: 2.5% of the visible height of an orthographic camera (16 units when its size is
// design-height based), 0.3 for a perspective one.
float feel_default_shake_offset(const World& w, Entity camera);

// ------------------------------------------------------------------------------------------------------------- clocks
// Start of a frame, real seconds: runs the hit-stop timers and receives the system's "reduce motion".
void feel_begin_frame(World& w, double realDt, bool systemReduceMotion);
// Once per frame before drawing: `clockDt` = real seconds times `time.scale` (shake, flash, squash); recomputes the poses.
// `gameDt` = real seconds times the effective game scale (`time.scale` AND the hit-stop): the clock the lifetimes of spawned
// effects run on, so a hit-stop or a pause holds them.
void feel_update(World& w, double clockDt, double gameDt);
// Once per FIXED step that advances the game (not while hit-stop freezes it); `dt` = fixed step times the effective scale.
void feel_fixed_update(World& w, double dt);

// The noise the shake is made of, exposed for tests: smooth, in [-1, 1], a pure function of its arguments.
float feel_noise(std::uint32_t seed, std::uint32_t channel, double x);

// Debug view of the state, what `feel.state` returns.
Json feel_state_json(const World& w);

}  // namespace fa
