// Game feel: the short effects that make a hit, a jump or an explosion read on screen. Camera shake, hit-stop, a flash of
// colour, knockback, and squash and stretch. docs/GAME_FEEL.md is the guide; this header is the C++ side that the script
// API (camera.shake, time.hitStop, entity.flash / knockback / squash), the `feel.*` commands and (M62.2) the clip events of
// the Animator and the timeline all call, so there is one implementation of each effect.
//
// WHERE THE STATE LIVES. Not in components: an effect is a moment, not part of a scene file. World owns one FeelState
// (World::feel()); World::clear() (every scene load that is not additive) drops the effects, hit-stop included, and keeps the
// player's accessibility choices. Nothing here writes a Transform except knockback of an entity without a physics body.
//
// A VISUAL EFFECT NEVER CHANGES THE SCENE. Shake and squash are a "visual pose" added at DRAW time: World::drawn_matrix() is
// the same chain as world_matrix() with each entity's pose multiplied in, and fa_render, the 2D bounds and the pointer
// mapping use it. Physics, audio, scripts and saved scenes keep reading world_matrix() and the Transform fields, so
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
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

class World;

// ----------------------------------------------------------------------------------------------- accessibility factors
inline constexpr float kReduceMotionShake = 0.25f;     // shake amount multiplier with reduce motion on
inline constexpr float kReduceMotionSquash = 0.25f;    // squash amount multiplier with reduce motion on
inline constexpr float kReduceMotionHitStop = 0.5f;    // hit-stop duration multiplier with reduce motion on
inline constexpr float kReducedEffectsFlash = 0.35f;   // largest flash strength with reduced effects on

inline constexpr float kMaxHitStopSeconds = 5.0f;      // a longer freeze is almost always a mistake (a script that forgot a unit)

// ------------------------------------------------------------------------------------------------------------ options
struct ShakeOptions {
    float amount = 0.4f;      // trauma to add, 0..1; trauma stacks up to `cap` and the shake is trauma squared
    float duration = 0.4f;    // seconds the shake takes to die out (a longer one already running is kept)
    float frequency = 25.0f;  // noise samples per second (how jittery)
    float maxOffset = 0.0f;   // largest offset at trauma 1, world units; 0 = the camera's default (feel_default_shake_offset)
    float maxAngle = 2.0f;    // largest turn at trauma 1, degrees
    float cap = 1.0f;         // trauma never goes above this (0..1)
};

struct FlashOptions {
    Color color{1, 1, 1, 1};  // the colour the entity is drawn in (alpha ignored)
    float duration = 0.12f;   // seconds
    bool fade = true;         // true: from `strength` down to 0 over the duration; false: `strength` for the whole duration, then off
    float strength = 1.0f;    // 0..1: how much of the colour replaces the entity's own (1 = solid)
};

struct SquashOptions {
    float amount = 0.3f;      // > 0 squashes (wider and flatter), < 0 stretches (taller and thinner); 0.3 is a clear landing
    float duration = 0.3f;    // seconds until the entity is back to exactly its own scale
    char axis = 'y';          // 'y' or 'x': the axis that gets shorter when `amount` > 0
};

struct KnockbackOptions {
    Vec3 direction{1, 0, 0};  // which way (any length; normalised). z is used by 3D bodies only
    float speed = 6.0f;       // world units per second added to the velocity at once
    float lockTime = 0.25f;   // seconds `isKnockedBack` stays true (the loss of control)
    float decay = 8.0f;       // entities WITHOUT a dynamic body: the velocity falls by exp(-decay * dt) per second
};

struct HitStopOptions {
    float duration = 0.08f;   // real seconds
    float scale = 0.0f;       // game-time scale during the stop: 0 = frozen, 0.2 = slow motion
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
    float remaining = 0.0f;   // seconds until it is over
    float decay = 0.0f;       // trauma per second
    float frequency = 25.0f;
    float maxOffset = 0.0f;
    float maxAngle = 2.0f;
    std::uint32_t seed = 0;
    double phase = 0.0;       // position in the noise (samples)
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
    bool volume3d = false;    // an entity with a mesh keeps x * y * z constant, a 2D one x * y
};

struct FeelKnock {
    Vec3 velocity{};          // body-less entities: world units per second, decaying
    float decay = 8.0f;
    float lockRemaining = 0.0f;
};

struct FeelEntity {
    std::optional<FeelShake> shake;
    std::optional<FeelFlash> flash;
    std::optional<FeelSquash> squash;
    std::optional<FeelKnock> knock;
    FeelPose pose;            // computed by feel_update from shake and squash
    bool hasPose = false;
};

struct FeelHitStop {
    float remaining = 0.0f;
    float scale = 0.0f;
};

class FeelState {
public:
    // The per-entity records, keyed by Entity::bits() (ordered, so output and iteration are deterministic).
    std::map<std::uint64_t, FeelEntity> entities;
    std::vector<FeelHitStop> hitStops;   // the running hit-stops (a few at most)
    std::uint32_t counter = 0;           // makes the seed of every shake different
    std::size_t poseCount = 0;           // records with hasPose: 0 = drawn_matrix is world_matrix

    // The player's choices; they survive World::clear() (they are not part of a scene). null = follow the system.
    std::optional<bool> reduceMotionSetting;
    std::optional<bool> reducedEffectsSetting;
    bool systemReduceMotion = false;     // the operating system's value, pushed by the runtime every frame

    bool reduce_motion() const { return reduceMotionSetting ? *reduceMotionSetting : systemReduceMotion; }
    bool reduced_effects() const { return reducedEffectsSetting ? *reducedEffectsSetting : systemReduceMotion; }

    // Multiplier of the game clock caused by hit-stops: 1 when none runs, else the smallest scale of the running ones.
    float hit_stop_factor() const;
    float hit_stop_remaining() const;    // the longest running one, seconds (0 = none)

    const FeelEntity* find(Entity e) const;
    FeelEntity* find(Entity e);
    const FeelPose* pose_of(Entity e) const;           // null = no visual pose now
    // The flash colour of `e` itself with alpha = how much of it shows now (0..1); null = not flashing.
    std::optional<Color> flash_of(Entity e) const;
    bool any_flash() const;
    bool knocked_back(Entity e) const;
    float knockback_remaining(Entity e) const;

    void clear_scene();                  // World::clear(): drops the effects, keeps the settings
};

// ------------------------------------------------------------------------------------------------------------ actions
// Each returns an error that says what to fix, or {}. `camera` null = the main camera (camera.main).
Result<void> feel_shake(World& w, Entity camera, const ShakeOptions& o);
Result<void> feel_hit_stop(World& w, const HitStopOptions& o);
Result<void> feel_flash(World& w, Entity e, const FlashOptions& o);
Result<void> feel_knockback(World& w, Entity e, const KnockbackOptions& o);
Result<void> feel_squash(World& w, Entity e, const SquashOptions& o);
// Stops everything of `e` (null = every effect of the world, hit-stops included). Flash, squash and shake end at once.
void feel_cancel(World& w, Entity e);

// The action as JSON, what clip events and the `feel.*` commands pass: {"action": "shake" | "hitStop" | "flash" | "knockback" |
// "squash", ...the options of that action by their field names}. `target` is the entity of flash, knockback and squash (and the
// camera of shake, null = main). Unknown keys and wrong types are errors with a "did you mean".
Result<void> feel_apply_action(World& w, Entity target, const Json& action);
// The names feel_apply_action accepts for "action".
const std::vector<std::string>& feel_action_names();

// Camera default for ShakeOptions::maxOffset: 2.5% of the visible height of an orthographic camera (16 units when its size is
// design-height based), 0.3 for a perspective one.
float feel_default_shake_offset(const World& w, Entity camera);

// ------------------------------------------------------------------------------------------------------------- clocks
// Start of a frame, real seconds: runs the hit-stop timers and receives the system's "reduce motion".
void feel_begin_frame(World& w, double realDt, bool systemReduceMotion);
// Once per frame before drawing: `clockDt` = real seconds times `time.scale` (shake, flash, squash); recomputes the poses.
void feel_update(World& w, double clockDt);
// Once per FIXED step that advances the game (not while hit-stop freezes it); `dt` = fixed step times the effective scale.
void feel_fixed_update(World& w, double dt);

// The noise the shake is made of, exposed for tests: smooth, in [-1, 1], a pure function of its arguments.
float feel_noise(std::uint32_t seed, std::uint32_t channel, double x);

// Debug view of the state, what `feel.state` returns.
Json feel_state_json(const World& w);

}  // namespace fa
