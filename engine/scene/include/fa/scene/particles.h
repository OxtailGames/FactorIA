// The simulation of a ParticleEmitter (docs/PARTICLES.md), without a GPU: spawning (emission shapes, inherited velocity), motion
// (gravity, drag, turbulence, speed over life), collision with a plane or a Tilemap, trails, and sub-emitters. fa_render keeps one
// ParticleSim per emitter and draws what it holds; a test drives one directly.
//
// Deterministic: a sim owns its Rng, seeded from the emitter, and uses only + - * / sqrt, floor and fa::det trigonometry, so the
// same seed and the same steps give the same particles on every platform. Nothing reads a clock or `world.rng()`.
//
// Budgets (a phone must not pay for a mistake):
//   * at most kParticleHardCap live particles per emitter, sub-emitter particles included (ParticleEmitter.maxParticles can only lower it);
//   * a trail keeps at most kParticleTrailPoints points per particle, and all the trails of one emitter share a pool of
//     kParticleTrailBudget points (so at most that many ribbon quads are drawn for it, 16384 = about 2 MB of vertices): a particle born
//     when the pool is full draws no trail until a trailed particle dies. The pool is one array, not one vector per particle;
//   * sub-emitters go kParticleSubDepth levels deep (an emitter, its children, their children), at most kParticleSubCount particles
//     per event, at most kParticleSubGroups sub-emitters in total, and at most kParticleSubPerStep sub-emitter particles per step.
//   * a prefab or entity sub-emitter that failed to build is tried again once per kParticleLinkRetry seconds of sim time.
//   Whatever does not fit is not spawned.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <type_traits>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/components.h"
#include "fa/scene/curve.h"
#include "fa/scene/mesh_surface.h"
#include "fa/scene/tilemap.h"

namespace fa {

inline constexpr int kParticleHardCap = 10000;
inline constexpr int kParticleTrailPoints = 32;  // a power of two: a trail is a ring of this many points
inline constexpr int kParticleTrailBudget = 16384;  // trail points (ring slots * kParticleTrailPoints) one emitter may hold
inline constexpr int kParticleTrailSlots = kParticleTrailBudget / kParticleTrailPoints;
static_assert((kParticleTrailPoints & (kParticleTrailPoints - 1)) == 0, "a trail ring indexes with a mask");
inline constexpr int kParticleSubDepth = 2;
inline constexpr int kParticleSubCount = 32;
inline constexpr int kParticleSubGroups = 8;
inline constexpr int kParticleSubPerStep = 256;
inline constexpr double kParticleLinkSync = 0.1;   // seconds of sim time between copies of the emitter an {"entity": id} sub-emitter names
inline constexpr double kParticleLinkRetry = 1.0;  // seconds of sim time between tries to build a prefab or entity sub-emitter that failed

// ------------------------------------------------------------------ checking --
// One thing wrong (or useless) in an emitter's data: `pointer` is relative to the component ("/sizeCurve"), the same convention as
// TilemapIssue. The scene loader reports errors and warnings with file and pointer; the renderer logs a parse error once.
struct ParticleProblem {
    bool error = true;  // false = a warning: the emitter still works, a setting just does nothing
    std::string pointer;
    std::string message;
    std::string hint;
};
std::vector<ParticleProblem> particle_emitter_problems(const ParticleEmitter& em);

// The ParticleEmitter a prefab file holds (the first one in the tree of its entities), as a prefab `*.prefab.json`.
Result<ParticleEmitter> load_prefab_particle_emitter(const std::string& path);

// ---------------------------------------------------------------- the parsed JSON --
// The curves and gradients of an emitter, parsed from its Json fields. refresh() parses again only when a field changed (it compares
// with a copy of what it parsed: no allocation, and an empty field is one comparison), so reading it every frame is cheap. A field
// that does not parse stays empty and is listed in `problems` (`news` holds the ones not reported before).
struct ParticleStyle {
    Gradient color, trailColor;
    Curve size, speed, alpha, trailWidth;
    std::vector<std::string> problems;
    std::vector<std::string> news;  // problems found by the last refresh() that the previous one did not have

    void refresh(const ParticleEmitter& em);

private:
    Json srcColor_, srcSize_, srcSpeed_, srcAlpha_, srcTrailWidth_, srcTrailColor_;
    bool valid_ = false;
};

// The frame of a flipbook: which cell (column, row) a particle shows, `t` = age / life, `startFrame01` = the particle's random 0..1.
struct FlipbookFrame {
    int column = 0, row = 0;
};
int flipbook_frame_count(const ParticleEmitter& em);  // flipbookFrames, or columns * rows; at least 1
FlipbookFrame flipbook_frame(const ParticleEmitter& em, float age, float life, float startFrame01);

// A smooth random vector field in [-1, 1]^3 at `p` (world units) at time `t`, for turbulence: value noise on an integer lattice, so
// every platform computes the same numbers. `scale` is the size of one eddy and `speed` the eddies per second the field drifts.
Vec3 particle_noise(Vec3 p, float t, float scale, float speed, std::uint32_t seed);

// ------------------------------------------------------------------ the sim --
struct ParticleTrailPoint {
    Vec3 pos;
    float time = 0.0f;  // the sim's clock when it was recorded
};
static_assert(sizeof(ParticleTrailPoint) == 16, "a trail point is 16 bytes: the pool of one emitter is at most 256 KB");

struct Particle {
    Vec3 pos, vel;
    float age = 0.0f, life = 1.0f;
    float rotation = 0.0f;   // degrees
    float spin = 0.0f;       // degrees per second
    float sizeScale = 1.0f;  // 1 +- sizeVariance
    float random = 0.0f;     // 0..1, fixed at birth (a flipbook's start frame)
    std::uint8_t group = 0;  // 0 = the emitter's own particles, else the sub-emitter it came from (ParticleSim::group)
    // The trail (a group whose trail is "particle"): a ring of kParticleTrailPoints points in the sim's pool, slot `trailSlot` (-1 = no
    // trail: not asked for, or the pool was full). Read it with ParticleSim::trail_size / trail_point.
    std::int32_t trailSlot = -1;
    std::uint8_t trailHead = 0;   // where the next point is written
    std::uint8_t trailCount = 0;  // points held
};
static_assert(std::is_trivially_copyable_v<Particle>, "a particle owns nothing: no allocation per particle");

// What the sim needs to know about the world around the emitter for one step. Everything may stay empty.
struct ParticleEnv {
    Mat4 emitter;                      // the emitter's world matrix
    bool is3D = false;                 // = em.is3D
    bool screen = false;               // a screen-space emitter: the sim runs +Y up on the screen position (see render particles.cpp)
    const Tilemap* tilemap = nullptr;  // collision = tilemap of the emitter itself (when null, findTilemap is asked)
    Mat4 tilemapWorld;                 // that tilemap's world matrix
    // The Tilemap an emitter (the emitter itself or one of its sub-emitters) whose `collision` is "tilemap" bounces on, and its world
    // matrix; null when there is none. Sub-emitters ask this too, so they bounce off the map like their parent.
    std::function<const Tilemap*(const ParticleEmitter& emitter, Mat4& world)> findTilemap;
    const MeshSurface* mesh = nullptr; // shape = mesh
    // The ParticleEmitter of the entity with this id (a sub-emitter given as {"entity": id}); null when there is none.
    std::function<const ParticleEmitter*(std::string_view id)> findEmitter;
};

class ParticleSim {
public:
    std::vector<Particle> particles;                 // every group, in birth order
    std::vector<ParticleTrailPoint> emitterTrail;    // trail = emitter: the emitter's own path, newest last
    bool everSpawned = false;                        // at least one particle was ever born (guards autoDestroy)

    void seed(std::uint64_t s);
    bool seeded() const { return seeded_; }
    double clock() const { return clock_; }          // seconds simulated so far (trail points are stamped with it)
    std::uint64_t rng_state() const { return rng_.state(); }  // where the emitter's random sequence is (the world hash reads it)
    float emission_accumulator() const { return acc_; }       // the fraction of a particle the continuous emission still owes

    // `count` particles born at the next step (or at flush()): the bursts scripts ask for.
    void queue_burst(int count) { pendingBurst_ += count; }
    int pending_burst() const { return pendingBurst_; }
    // Spawns the queued bursts now, without simulating (what an emitter drawn before its first update needs).
    void flush(const ParticleEmitter& em, const ParticleEnv& env);
    // Spawns `count` particles of the emitter itself right now (the budgets still apply).
    void spawn(const ParticleEmitter& em, const ParticleEnv& env, int count);
    // One step of `dt` seconds: queued bursts, the start burst, continuous emission, motion, collision, sub-emitters, deaths. dt = 0
    // only spawns.
    void step(const ParticleEmitter& em, const ParticleEnv& env, float dt);

    // Group 0 is the emitter itself (`root`), the others are its sub-emitters (copies the sim keeps, see ParticleEmitter.subEmitters).
    int group_count() const { return int(groups_.size()) < 1 ? 1 : int(groups_.size()); }
    const ParticleEmitter& group_emitter(int g, const ParticleEmitter& root) const;
    const ParticleStyle& group_style(int g) const { return groups_[std::size_t(g)].style; }
    // Problems with the sub-emitter specification found since the last call (each only once), for the caller to log.
    std::vector<std::string> take_problems();

    // The trail of a particle: `trail_size` points, `trail_point(p, 0)` the newest (where the particle was last recorded) and
    // `trail_size(p) - 1` the oldest. 0 points for a particle without a trail.
    int trail_size(const Particle& p) const { return p.trailSlot < 0 ? 0 : int(p.trailCount); }
    const ParticleTrailPoint& trail_point(const Particle& p, int i) const;
    // Ribbon quads the particle trails and the emitter trail make now (points - 1 per trail): never more than kParticleTrailBudget.
    int trail_quads() const;
    // Trail points the pool has allocated (grows up to kParticleTrailBudget, never shrinks) and the trails that hold a slot.
    std::size_t trail_pool_points() const { return trailPool_.size(); }
    int trails_in_use() const { return trailsInUse_; }

    bool empty() const { return particles.empty(); }
    // Live particles of a group (after the last step).
    int live(int group) const { return group >= 0 && group < int(counts_.size()) ? counts_[std::size_t(group)] : 0; }

private:
    struct Link {
        int group = -1;  // the sub-emitter's group index (>= 1)
        int count = 1;
        float chance = 1.0f;
        float inherit = 0.0f;
    };
    struct Group {
        std::unique_ptr<ParticleEmitter> emitter;  // null for group 0: the caller's emitter
        ParticleStyle style;
        std::vector<Link> on[3];  // sub-emitters of birth, death and collision
        std::string entityId;     // {"entity": id}: copied from that emitter now and then (kParticleLinkSync)
        bool styleDirty = true;   // the emitter changed since the style was parsed (a sub-emitter's own fields never change)
        // Collision = tilemap: what the emitter bounces on (found again at every step), and the solid tiles read from it.
        const Tilemap* tilemap = nullptr;
        Mat4 tilemapWorld, tilemapInv;
        Json solidSrc;
        std::vector<int> solid;
        bool solidValid = false;
        float cellMap[4] = {0, 0, 0, 0};
        TilemapSize tilemapSize;
        bool tilemapWarned = false;
    };
    // A prefab or entity sub-emitter that could not be built: tried again once per second of the sim's clock.
    struct Retry {
        int parent = 0;
        int kind = 0;
        int depth = 0;
        Json link;
        std::string event;
        double next = 0.0;
    };
    // Where a particle is born: the matrix and its parts the shape and direction are read from.
    struct Place {
        Mat4 m;
        Vec3 origin;
        float rotZ = 0.0f;
        Vec2 scale{1.0f, 1.0f};
    };
    struct Event {
        int kind = 0;  // 1 = death, 2 = collision (an index of Group::on)
        int group = 0;
        Vec3 pos, vel, normal;
    };

    const ParticleEmitter& cfg(int g) const { return g == 0 ? *root_ : *groups_[std::size_t(g)].emitter; }
    void begin(const ParticleEmitter& em, const ParticleEnv& env, bool forceSync);
    Place root_place(const ParticleEnv& env) const;
    bool can_spawn(int g) const;
    void spawn_one(int g, const Place& place, Vec3 extraVel, bool child);
    void fire(int g, int kind, Vec3 pos, Vec3 vel, Vec3 normal);
    void spawn_children(const Link& link, Vec3 pos, Vec3 vel, Vec3 normal, bool hasNormal);
    void sync_sub_emitters(const ParticleEnv& env, bool forceSync);
    void build_links(int g, const Json& spec, int depth, const ParticleEnv& env);
    enum class LinkResult { Built, Dropped, Retry, Full };  // Retry: a prefab or entity that could not be had yet
    LinkResult add_link(int g, int kind, const std::string& event, const Json& link, int depth, const ParticleEnv& env);
    void retry_links(const ParticleEnv& env);
    int acquire_trail_slot();
    void release_trail(Particle& p);
    void record_trail(Particle& p, const ParticleEmitter& c);
    void move(Particle& p, const ParticleEmitter& c, const ParticleStyle& style, float dt);
    void note(const std::string& problem);
    void collide(Particle& p, const ParticleEmitter& c, Vec3 before, float dt);
    void bounce(Particle& p, const ParticleEmitter& c, Vec3 normal, float dt);
    // `dirMode`: 0 = the shape does not say where to go, 1 = `dir` is the direction particles leave along (spread still applies),
    // 2 = `dir` is the exact direction.
    void sample_shape(const ParticleEmitter& c, const Place& place, Vec3& offset, int& dirMode, Vec3& dir);
    void refresh_cdf();
    bool solid_cell(const Group& g, int col, int row) const;
    void refresh_solid(int g);

    Rng rng_;
    bool seeded_ = false;
    std::uint32_t noiseSeed_ = 0;
    double clock_ = 0.0;
    float acc_ = 0.0f;
    bool wasEmitting_ = false;
    bool fresh_ = true;
    int pendingBurst_ = 0;
    int subBudget_ = kParticleSubPerStep;
    bool haveLastPos_ = false;
    Vec3 lastPos_;
    Vec3 emitterVel_;

    const ParticleEmitter* root_ = nullptr;
    const ParticleEnv* env_ = nullptr;
    std::vector<Group> groups_;
    Json subSpec_;
    bool subSpecValid_ = false;
    std::vector<std::string> problems_, reported_;
    std::vector<int> counts_;
    std::vector<Event> events_;
    std::vector<Retry> retries_;
    double nextLinkSync_ = 0.0;
    std::vector<ParticleTrailPoint> trailPool_;  // kParticleTrailPoints per slot
    std::vector<int> freeSlots_;
    int trailsInUse_ = 0;
    // shape = mesh: the cumulative triangle areas of the surface sampled last.
    const MeshSurface* cdfSurface_ = nullptr;
    std::size_t cdfTriangles_ = 0;
    std::vector<float> cdf_;
};

}  // namespace fa
