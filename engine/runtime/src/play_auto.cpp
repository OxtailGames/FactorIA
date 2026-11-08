// play.auto (see fa/runtime/play_auto.h): the driver that plays a project with its bot and writes the play session.
#include "fa/runtime/play_auto.h"

#include <algorithm>
#include <chrono>
#include <cerrno>
#include <cmath>
#include <ctime>
#include <filesystem>
#include <format>
#include <atomic>
#include <set>
#include <unordered_map>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/perf.h"
#include "fa/core/strings.h"
#include "fa/runtime/play_session.h"
#include "fa/ui/ui.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <process.h>
#include <windows.h>
#else
#include <csignal>
#include <unistd.h>
#endif

namespace fa {

namespace {

constexpr std::size_t kMaxTracked = 256;      // entities whose movement is watched (the first ones, in creation order)
constexpr int kMaxMarks = 20;                  // problems a session lists
constexpr int kLoopErrorsPerSecond = 5;        // script errors in one game second that make it a "bad second" ...
constexpr int kLoopSeconds = 3;                // ... and this many bad seconds in a row are an exception loop
constexpr double kScenePictureDelay = 0.5;     // game seconds after a scene loads before its picture is taken
constexpr std::size_t kMaxNotes = 20;

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

// ---- the scratch folder of the pictures
// A run takes its pictures into <project>/.factoria/cache/play-auto-<process id>-<n>/ and moves them into the session's folder when
// the session is complete. The folder is inside the project on purpose: the engine's paths are project-relative native strings (the
// ANSI code page on Windows), so a temp folder of the system under C:\Users\José\ could not be handed to Engine::screenshot.
constexpr const char* kScratchRoot = ".factoria/cache";
constexpr const char* kScratchPrefix = "play-auto-";

long long this_process_id() {
#if defined(_WIN32)
    return _getpid();
#else
    return static_cast<long long>(::getpid());
#endif
}

// False only when the process is known to be gone (a run that was killed): a doubt keeps the folder, the age rule deals with it.
bool process_may_exist(long long pid) {
    if (pid <= 0 || pid > 0x7fffffffLL) return false;
#if defined(_WIN32)
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, DWORD(pid));
    if (!h) return GetLastError() != ERROR_INVALID_PARAMETER;
    DWORD code = 0;
    const bool alive = !GetExitCodeProcess(h, &code) || code == STILL_ACTIVE;
    CloseHandle(h);
    return alive;
#else
    return ::kill(static_cast<pid_t>(pid), 0) == 0 || errno != ESRCH;
#endif
}

// Deletes the scratch folders a run that was killed left behind: those of a process that is gone, and any older than an hour (an
// hour is far above the longest run). Never one of this process that is younger than that: another run of it may be using it.
void remove_stale_scratch_dirs() {
    namespace stdfs = std::filesystem;
    std::error_code ec;
    const stdfs::path root = fs::os_path(fs::resolve(kScratchRoot));
    std::vector<stdfs::path> stale;
    for (const auto& e : stdfs::directory_iterator(root, ec)) {
        std::error_code e2;
        if (!e.is_directory(e2)) continue;
        const std::string name = fs::path_to_utf8(e.path().filename());  // never .string(): it throws for a name the code page lacks
        if (name.rfind(kScratchPrefix, 0) != 0) continue;
        const std::size_t dash = name.find('-', std::char_traits<char>::length(kScratchPrefix));
        if (dash == std::string::npos) continue;
        long long pid = 0;
        bool digits = dash > std::char_traits<char>::length(kScratchPrefix);
        for (std::size_t i = std::char_traits<char>::length(kScratchPrefix); i < dash && digits; ++i) {
            digits = name[i] >= '0' && name[i] <= '9' && pid < 100000000000LL;
            if (digits) pid = pid * 10 + (name[i] - '0');
        }
        if (!digits) continue;
        const auto written = stdfs::last_write_time(e.path(), e2);
        const bool old = !e2 && stdfs::file_time_type::clock::now() - written > std::chrono::hours(1);
        const bool gone = pid != this_process_id() && !process_may_exist(pid);
        if (old || gone) stale.push_back(e.path());
    }
    for (const stdfs::path& p : stale) fs::remove_tree(p, ec);
}

// The explorer's generator: mulberry32, the algorithm of rng.create in scripts. Local to the bot: the world's RNG is never touched,
// so a replay (which has no bot) draws the same numbers the game did.
class BotRng {
public:
    explicit BotRng(std::uint64_t seed) : s_(std::uint32_t(seed * 2654435761ull) ^ 0x9E3779B9u ^ std::uint32_t(seed >> 32)) {}
    double next() {
        s_ += 0x6D2B79F5u;
        std::uint32_t t = s_;
        t = (t ^ (t >> 15)) * (t | 1u);
        t ^= t + (t ^ (t >> 7)) * (t | 61u);
        return double((t ^ (t >> 14))) / 4294967296.0;
    }
    int pick(int n) { return n <= 1 ? 0 : std::min(n - 1, int(next() * n)); }

private:
    std::uint32_t s_;
};

// The generic bot of a game without scripts/autoplay.js: segments of 0.5 to 1.5 game seconds; in each, one or two of the declared
// actions are held (sometimes only for a tap), and when the scene has buttons it also taps ui_submit, ui_down or ui_next.
class Explorer {
public:
    explicit Explorer(std::uint64_t seed) : rng_(seed) {}

    std::vector<std::string> decide(double t, const std::vector<std::string>& actions, bool uiPresent, const std::vector<std::string>& uiActions) {
        if (t >= segmentEnd_) {
            segmentEnd_ = t + 0.5 + rng_.next();
            held_.clear();
            const double r = rng_.next();
            const int count = actions.empty() ? 0 : (r < 0.2 ? 0 : (r < 0.7 ? 1 : 2));
            for (int i = 0; i < count; ++i) {
                const std::string& a = actions[std::size_t(rng_.pick(int(actions.size())))];
                if (std::find_if(held_.begin(), held_.end(), [&](const Held& h) { return h.name == a; }) != held_.end()) continue;
                held_.push_back({a, rng_.next() < 0.4 ? t + 0.12 : segmentEnd_});
            }
            if (uiPresent && !uiActions.empty()) {
                const double u = rng_.next();
                const char* want = u < 0.5 ? "ui_submit" : (u < 0.75 ? "ui_down" : "ui_next");
                if (std::find(uiActions.begin(), uiActions.end(), want) != uiActions.end()) held_.push_back({want, t + 0.1});
            }
        }
        std::vector<std::string> out;
        for (const Held& h : held_)
            if (t < h.until) out.push_back(h.name);
        return out;
    }

private:
    struct Held {
        std::string name;
        double until;
    };
    BotRng rng_;
    double segmentEnd_ = 0;
    std::vector<Held> held_;
};

struct Tracked {
    std::uint64_t bits = 0;
    Vec3 pos;
    bool is2d = false;
    bool falls = false;  // gravity pulls it (a dynamic body with gravity in the scene, or a character controller): only these can fall out of the world
};
enum class FocusKind { Player, Bodies, Scripts, None };
struct Snapshot {
    FocusKind kind = FocusKind::None;
    std::vector<Tracked> items;  // creation order
    std::vector<std::string> names;
};

// What the bot is judged by. "The player" (an entity tagged or named player, or with a CharacterController3D) when the scene has one;
// else every body that is not static; else every enabled script entity (a menu); else nothing.
Snapshot take_snapshot(World& w) {
    Snapshot s;
    std::set<std::uint64_t> seen;
    auto add = [&](Entity e) {
        if (!w.alive(e) || !w.active_in_hierarchy(e) || s.items.size() >= kMaxTracked) return;
        if (!seen.insert(e.bits()).second) return;
        Tracked t;
        t.bits = e.bits();
        t.pos = w.world_position(e);
        t.is2d = w.has<RigidBody2D>(e) || w.has<Collider2D>(e);
        const SceneSettings& st = w.settings();
        if (const RigidBody2D* b = w.get<RigidBody2D>(e)) t.falls = b->type == BodyType::Dynamic && b->gravityScale != 0.0f && (st.gravity2D.x != 0.0f || st.gravity2D.y != 0.0f);
        else if (const RigidBody3D* b3 = w.get<RigidBody3D>(e)) t.falls = b3->type == BodyType::Dynamic && b3->gravityScale != 0.0f && (st.gravity3D.x != 0.0f || st.gravity3D.y != 0.0f || st.gravity3D.z != 0.0f);
        else t.falls = w.has<CharacterController3D>(e);  // the controller has no gravity of its own: the game's script adds it
        s.items.push_back(t);
        s.names.push_back(w.info(e).id);
    };
    for (Entity e : w.find_by_tag("player")) add(e);
    if (Entity e = w.find_by_id("player")) add(e);
    for (Entity e : w.find_all_by_name("player")) add(e);
    w.each<CharacterController3D>([&](Entity e, CharacterController3D&) { add(e); });
    if (!s.items.empty()) {
        s.kind = FocusKind::Player;
        return s;
    }
    w.each<RigidBody2D>([&](Entity e, RigidBody2D& b) { if (b.type != BodyType::Static) add(e); });
    w.each<RigidBody3D>([&](Entity e, RigidBody3D& b) { if (b.type != BodyType::Static) add(e); });
    if (!s.items.empty()) {
        s.kind = FocusKind::Bodies;
        return s;
    }
    w.each<Script>([&](Entity e, Script& sc) { if (sc.enabled) add(e); });
    if (!s.items.empty()) s.kind = FocusKind::Scripts;
    return s;
}

bool finite3(const Vec3& v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }

// True when a tracked entity appeared, vanished or moved more than eps (0.01 m; 1 px at 100 px per meter) from where `ref` has it.
bool moved_since(const Snapshot& ref, const Snapshot& now, float pixelsPerMeter) {
    if (ref.kind != now.kind || ref.items.size() != now.items.size()) return true;
    for (std::size_t i = 0; i < ref.items.size(); ++i) {
        if (ref.items[i].bits != now.items[i].bits) return true;
        const float eps = now.items[i].is2d ? 0.01f * pixelsPerMeter : 0.01f;
        const Vec3 d{now.items[i].pos.x - ref.items[i].pos.x, now.items[i].pos.y - ref.items[i].pos.y, now.items[i].pos.z - ref.items[i].pos.z};
        if (std::fabs(d.x) > eps || std::fabs(d.y) > eps || std::fabs(d.z) > eps) return true;
    }
    return false;
}

std::uint64_t mix(std::uint64_t h, std::uint64_t v) {
    h ^= v + 0x9E3779B97F4A7C15ull + (h << 6) + (h >> 2);
    return h;
}

std::uint64_t hash_text(std::uint64_t h, const std::string& text) {
    for (unsigned char c : text) h = (h ^ c) * 1099511628211ull;
    return h;
}

// What the screen says: the text of every visible Text and Button (the first kMaxTracked). A turn-based game that only changes
// its score line or its board labels is making progress even though nothing moves.
std::uint64_t ui_text_hash(World& w) {
    std::uint64_t h = 1469598103934665603ull;
    std::size_t n = 0;
    w.each<Text>([&](Entity e, Text& t) {
        if (n >= kMaxTracked || !w.active_in_hierarchy(e)) return;
        ++n;
        h = hash_text(mix(h, e.bits()), t.text);
    });
    w.each<Button>([&](Entity e, Button& b) {
        if (n >= kMaxTracked || !w.active_in_hierarchy(e)) return;
        ++n;
        h = hash_text(mix(h, e.bits()), b.text);
    });
    return h;
}

// The scene's extent for the fall limit: every entity that is not itself a falling body (floors, walls, tilemaps, markers). A world that
// is generated after the start (a tilemap filled by a script, a WFC level) changes it: `worldSignature` tells when to measure again.
struct WorldExtent {
    bool any = false;
    double lowest = 0, highest = 0;
    bool any2d = false;
};
std::uint64_t world_signature(World& w) {
    std::uint64_t h = mix(mix(1469598103934665603ull, w.scene_generation()), std::uint64_t(w.entity_count()));
    w.each<Tilemap>([&](Entity, Tilemap& t) { h = mix(mix(h, std::uint64_t(t.width)), std::uint64_t(t.height)); });
    return h;
}
WorldExtent measure_world(World& w, const Snapshot& cur) {
    WorldExtent x;
    std::set<std::uint64_t> falling;
    for (const Tracked& t : cur.items) {
        if (t.falls) falling.insert(t.bits);
        x.any2d = x.any2d || t.is2d;
    }
    auto add = [&](double y) {
        if (!std::isfinite(y)) return;
        x.lowest = x.any ? std::min(x.lowest, y) : y;
        x.highest = x.any ? std::max(x.highest, y) : y;
        x.any = true;
    };
    for (Entity e : w.entities()) {
        if (falling.count(e.bits())) continue;
        const double y = double(w.world_position(e).y);
        add(y);
        if (const Tilemap* m = w.get<Tilemap>(e)) {  // the map hangs from its origin or stands on it: take both ends
            const double h = double(std::max(m->height, 0)) * double(m->tileSize.y);
            add(y - h);
            add(y + h);
        }
    }
    return x;
}

// A command line argument: plain text as it is, anything with a space or a shell character in double quotes.
std::string shell_word(const std::string& text) {
    if (!text.empty() && text.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-:") == std::string::npos) return text;
    std::string out = "\"";
    for (char c : text) {
        if (c == '"' || c == '\\') out += '\\';
        out += c;
    }
    return out + "\"";
}

std::string describe_pos(const Vec3& p) { return std::format("({:.1f}, {:.1f}, {:.1f})", p.x, p.y, p.z); }

}  // namespace

Result<Json> play_auto(const EngineConfig& configIn, const PlayAutoOptions& opt) {
    if (!(opt.seconds > 0.0) || opt.seconds > kPlayAutoMaxSeconds)
        return make_error(std::format("seconds must be between 0 and {} game seconds, got {}.", kPlayAutoMaxSeconds, opt.seconds), "A minute of play is 60.");
    if (opt.speed < 1 || opt.speed > kPlayAutoMaxSpeed)
        return make_error(std::format("speed must be a whole number from 1 to {}, got {}.", kPlayAutoMaxSpeed, opt.speed), "It is how many fixed steps one frame runs.");
    if (!(opt.stuckSeconds > 0.0) || opt.stuckSeconds > kPlayAutoMaxSeconds)
        return make_error(std::format("stuckSeconds must be between 0 and {} game seconds, got {}.", kPlayAutoMaxSeconds, opt.stuckSeconds), "10 is the default.");

    EngineConfig config = configIn;
    config.headless = true;
    config.audioDevice = false;
    config.hotReload = false;
    config.hotReloadAssets = false;
    config.memoryStorage = true;
    config.renderMode = RenderMode::OnDemand;
    config.seed = opt.seed;
    config.traceLoads = true;  // the session's `loading` section (play.report); the order goes to configIn's loadOrderSink, if any
    if (config.platformBackend.empty()) config.platformBackend = "fake";
    if (config.date.empty()) config.dateUtcOffsetMinutes = 0;

    Engine engine;
    std::string initError;
    if (!engine.init(config, nullptr, &initError))
        return make_error("The project did not start: " + initError, "Run 'factoria run --headless --frames 5' to see the same problem, and fix the scene or script it names.");
    // The session's reads are this engine's (its load trace and play.report's loading section): the frames, the draws and the
    // scene loads say so themselves, and this covers the bot hook too (autoplay_begin / autoplay_step load scripts).
    const LoadTrace::ReadingFor reading(engine.load_trace_owner());
    Engine::Impl& I = engine.runtime_impl();
    World& world = engine.world();
    if (!config.scene.empty() && !fs::is_absolute(config.scene) && !fs::exists(config.scene))  // init only logs it, and plays nothing
        return make_error(std::format("The scene '{}' does not exist in the project.", config.scene),
                          I.sceneIssues.empty() ? std::string("Name a scene file of the project, like scenes/main.scene.json.") : I.sceneIssues.front());
    const double fixedDt = engine.fixed_dt();
    const double hz = fixedDt > 0.0 ? 1.0 / fixedDt : 60.0;
    const std::uint64_t startFrame = engine.frame_index();
    const std::uint64_t logSeq = log_last_seq();
    const std::size_t errorsBefore = error_count();

    // ---- the bot
    bool hookFound = false;
    std::string hookError;
    if (opt.useHook) hookError = engine.scripts().autoplay_begin(true, &hookFound);
    else engine.scripts().autoplay_begin(false, nullptr);
    const bool useHook = opt.useHook && hookFound;
    const bool hookFileExists = opt.useHook && fs::exists("scripts/autoplay.js");
    Explorer explorer(opt.seed);
    PlaySession s;
    s.source = "auto";
    s.fixedHz = hz;
    Json notes = Json::array();
    auto note = [&](const std::string& text) {
        if (notes.size() < kMaxNotes) notes.push_back(text);
    };
    // A hook that is there but cannot be loaded is a problem of the game, never a reason to play with another bot unseen: the run ends
    // "broken" before the first step (below) and the session says why. A project with no hook file falls back to the explorer, and so does
    // a file that never calls game.autoplay unless the caller demanded the hook (bot "hook").
    std::string hookProblem;
    if (!hookError.empty()) hookProblem = "scripts/autoplay.js could not be loaded: " + hookError;
    else if (opt.useHook && !hookFound && opt.hookRequired)
        hookProblem = hookFileExists ? "scripts/autoplay.js never called game.autoplay(fn), so the project has no bot; call game.autoplay((bot) => [...]) at the top level of the file (docs/SCRIPTING.md, \"The bot\")"
                                     : "the project has no scripts/autoplay.js";
    if (!opt.useHook) note("The hook was switched off (bot \"explorer\"): the generic explorer played.");
    else if (hookProblem.empty() && !hookFound && hookFileExists)
        note("scripts/autoplay.js never called game.autoplay(fn), so the generic explorer played: it holds the declared actions in seeded patterns. Call game.autoplay((bot) => [...]) at the top level of the file, see docs/SCRIPTING.md, \"The bot\".");
    else if (hookProblem.empty() && !hookFound)
        note("The project has no scripts/autoplay.js (game.autoplay), so the generic explorer played: it holds the declared actions in seeded patterns. Write a hook to make the bot play the game, see docs/SCRIPTING.md, \"The bot\".");

    std::vector<std::string> actions, uiActions;
    if (I.project.inputActions.is_object())
        for (auto it = I.project.inputActions.begin(); it != I.project.inputActions.end(); ++it)
            if (!starts_with(it.key(), "ui_") && engine.input().has_action(it.key())) actions.push_back(it.key());
    for (const char* a : {"ui_up", "ui_down", "ui_left", "ui_right", "ui_next", "ui_previous", "ui_submit", "ui_cancel"})
        if (engine.input().has_action(a)) uiActions.push_back(a);

    // ---- the session folder and the pictures
    remove_stale_scratch_dirs();
    std::string name = opt.sessionName.empty() ? play_session_name(std::time(nullptr)) + "-auto" : opt.sessionName;
    {
        const std::string base = name;
        for (int n = 2; n < 1000; ++n) {
            std::error_code ec;
            if (!std::filesystem::exists(fs::os_path(fs::resolve(std::string(kPlaySessionsDir) + "/" + name)), ec)) break;
            name = base + "-" + std::to_string(n);
        }
    }
    s.name = name;
    const std::string relDir = std::string(kPlaySessionsDir) + "/" + name;
    const std::string absDir = fs::path_to_utf8(fs::resolve(relDir));  // UTF-8, never the Windows code page: it goes into JSON
    bool canShoot = opt.screenshots && engine.renderer() != nullptr;
    // The pictures are taken into a scratch folder of the project (.factoria/cache) and moved into the session's folder at the end,
    // when the session is complete: a run that is cancelled leaves nothing under .factoria/sessions, and a run that is killed leaves
    // only its scratch folder, which the next run deletes (remove_stale_scratch_dirs).
    static std::atomic<unsigned> scratchCounter{0};
    struct Scratch {
        std::string rel;  // project-relative, "" = none
        ~Scratch() {
            if (rel.empty()) return;
            std::error_code ec;
            fs::remove_tree(fs::resolve(rel), ec);
        }
    } scratch;
    std::vector<std::string> taken;  // the picture files in the scratch folder
    if (canShoot) {
        scratch.rel = std::format("{}/{}{}-{}", kScratchRoot, kScratchPrefix, this_process_id(), scratchCounter++);
        std::error_code ec;
        fs::remove_tree(fs::resolve(scratch.rel), ec);
        std::filesystem::create_directories(fs::os_path(fs::resolve(scratch.rel)), ec);
        if (ec) {
            note("No screenshots: the folder " + scratch.rel + " for them could not be made (" + ec.message() + ").");
            scratch.rel.clear();
            canShoot = false;
        }
    }
    if (!opt.screenshots) {
        note("Screenshots were switched off.");
    } else if (!engine.renderer()) {
        std::string why = config.graphics ? "this computer has no graphics device the engine can use" : "the run was started without graphics";
        for (const std::string& p : I.startupProblems)
            if (p.rfind("Graphics unavailable", 0) == 0) why = p;
        note("No screenshots: " + why + ". The session has no pictures; the numbers, phases and marks are complete. A Linux machine without a display needs Mesa's EGL (llvmpipe).");
    }
    int pictures = 0;
    bool pictureCapNoted = false;
    auto shoot = [&](const std::string& file) -> std::string {
        if (!canShoot) return {};
        if (pictures >= kPlayAutoMaxPictures && file != "end.png") {  // the end picture is the one that is always kept
            if (!pictureCapNoted) note(std::format("The run took {} screenshots, the most a session keeps: later phases and problems have none.", kPlayAutoMaxPictures));
            pictureCapNoted = true;
            return {};
        }
        std::string err;
        if (!engine.screenshot(scratch.rel + "/" + file, &err)) {  // project-relative, like every path the engine takes
            note("A screenshot failed, the rest were not tried: " + err);
            canShoot = false;
            return {};
        }
        ++pictures;
        taken.push_back(file);
        return file;
    };

    // ---- phases
    struct PendingPicture {
        std::size_t phase;
        std::int64_t dueStep;
    };
    std::vector<PendingPicture> pendingPictures;
    std::int64_t steps = 0;      // fixed steps run since the start of the run
    std::int64_t frames = 0;     // frames run
    std::uint64_t lastGeneration = world.scene_generation();
    std::string currentPhase;
    int droppedPhases = 0;
    auto add_phase = [&](const std::string& phaseName, const char* kind, bool scenePhase) {
        currentPhase = phaseName;
        if (int(s.phases.size()) >= kPlayAutoMaxPhases) {
            ++droppedPhases;
            return;
        }
        PlayPhase p;
        p.name = phaseName;
        p.kind = kind;
        p.scene = world.scene_path();
        p.frame = std::uint64_t(frames);
        p.time = double(steps) * fixedDt;
        s.phases.push_back(std::move(p));
        if (scenePhase) pendingPictures.push_back({s.phases.size() - 1, steps + std::int64_t(std::ceil(kScenePictureDelay * hz))});
        else s.phases.back().screenshot = shoot(std::format("phase-{}.png", s.phases.size()));
    };
    auto take_due_pictures = [&](bool all) {
        for (auto it = pendingPictures.begin(); it != pendingPictures.end();) {
            if (all || steps >= it->dueStep) {
                s.phases[it->phase].screenshot = shoot(std::format("phase-{}.png", it->phase + 1));
                it = pendingPictures.erase(it);
            } else {
                ++it;
            }
        }
    };
    add_phase(world.scene_path(), "scene", true);
    s.scene = world.scene_path();

    // ---- the run
    Json replayFrames = Json::object();
    Json replayTiming = Json::array();
    std::vector<std::string> held;
    std::vector<std::string> replayProblems;
    std::vector<double> frameMs;
    ProfileSummary profile;
    struct ProfilerGuard {
        bool was;
        ~ProfilerGuard() { Profiler::get().set_enabled(was); }
    } profilerGuard{Profiler::on()};
    Profiler::get().set_enabled(true);
    profile.add_memory(engine.profile_memory());
    constexpr int kProfileWarmup = 10;

    const std::int64_t totalSteps = std::int64_t(std::ceil(opt.seconds * hz - 1e-9));
    const std::int64_t stuckSteps = std::max<std::int64_t>(1, std::int64_t(std::ceil(opt.stuckSeconds * hz - 1e-9)));
    const std::int64_t checkEvery = std::max<std::int64_t>(opt.speed, std::int64_t(std::ceil(hz / 10.0)));  // 0.1 game seconds
    const auto wallStart = std::chrono::steady_clock::now();

    std::string ended, endedWhy;
    Json score;
    bool hasScore = false;
    int hookFailures = 0;
    std::set<std::string> botNotes;

    // stuck / broken bookkeeping
    Snapshot ref = take_snapshot(world);
    std::int64_t refStep = 0;
    std::uint64_t refSig = 0;
    double fallLimit = 0, sceneLowest = 0;
    bool haveFallLimit = false;
    std::uint64_t limitSignature = 0;
    std::uint64_t errorEventsSeen = engine.scripts().error_events();
    std::int64_t secondStart = 0;
    int badSeconds = 0;
    int phaseMarks = 0;  // game.phase marks seen: part of the signature
    std::vector<std::string> scriptErrorsExtra;  // problems of the hook itself, listed with the script errors

    auto signature = [&]() {
        std::uint64_t h = 1469598103934665603ull;
        h = mix(h, world.scene_generation());
        h = mix(h, std::uint64_t(phaseMarks));
        h = mix(h, std::uint64_t(hasScore ? std::llround(score.get<double>() * 1000.0) : -1));
        h = mix(h, I.ui.focused().bits());
        h = mix(h, std::uint64_t(world.entity_count()));  // something spawned or went away
        return h;
    };
    // The text on screen counts as a change too (a turn-based game shows its progress in labels), unless it changes more than twice a game
    // second, which is a clock or an animation and would hide every stuck screen.
    std::vector<std::int64_t> textChangeSteps;
    std::uint64_t refTextEpoch = 0;
    std::uint64_t lastText = ui_text_hash(world);
    refSig = mix(signature(), refTextEpoch);

    auto add_problem = [&](const char* kind, const std::string& text, const char* endedAs) {
        if (int(s.marks.size()) >= kMaxMarks) return;
        PlayMark m;
        m.frame = std::uint64_t(frames);
        m.time = double(steps) * fixedDt;
        m.kind = kind;
        m.step = steps;
        m.note = text;
        m.screenshot = shoot(std::format("mark-{}.png", s.marks.size() + 1));
        s.marks.push_back(std::move(m));
        if (ended.empty()) {
            ended = endedAs;
            endedWhy = text;
        }
    };

    auto latest_script_error = [&]() {
        const auto& errs = engine.scripts().errors();
        return errs.empty() ? std::string() : errs.back().to_string();
    };

    if (!hookProblem.empty()) {
        add_problem("hook", hookProblem, "broken");
        scriptErrorsExtra.push_back(hookProblem);
    }

    while (ended.empty()) {
        if (steps >= totalSteps) {
            ended = "timeout";
            endedWhy = std::format("the {} game seconds asked for passed without the game ending", round3(opt.seconds));
            break;
        }
        if (std::chrono::duration<double>(std::chrono::steady_clock::now() - wallStart).count() > opt.wallSecondsCap) {
            ended = "aborted";
            endedWhy = std::format("the safety limit of {} real seconds passed (the machine is far slower than normal use)", opt.wallSecondsCap);
            break;
        }

        // ---- decide what to hold during this frame
        const double now = double(steps) * fixedDt;
        std::vector<std::string> want;
        if (useHook) {
            Json st = Json::object({{"time", round3(now)}, {"step", steps}, {"dt", fixedDt * double(opt.speed)}, {"scene", world.scene_path()},
                                    {"sceneTime", round3(world.time())}, {"phase", currentPhase}, {"actions", actions}, {"uiActions", uiActions},
                                    {"held", held}, {"seed", opt.seed}});
            ScriptSystem::AutoplayAnswer ans = engine.scripts().autoplay_step(st);
            if (ans.failed) {
                ++hookFailures;  // the script error is recorded (and counted by the exception-loop check); this step presses nothing
            } else {
                want = ans.actions;
                if (ans.hasScore) {
                    score = round3(ans.score);
                    hasScore = true;
                }
                if (!ans.note.empty() && botNotes.size() < 10 && botNotes.insert(ans.note).second) note("bot: " + ans.note);
                if (ans.end == "won" || ans.end == "lost") {
                    ended = ans.end;
                    endedWhy = std::format("scripts/autoplay.js ended the run with \"{}\"{}", ans.end, ans.note.empty() ? std::string() : ": " + ans.note);
                    break;
                }
            }
        } else {
            want = explorer.decide(now, actions, [&] {
                bool any = false;
                world.each<Button>([&](Entity e, Button&) { any = any || world.active_in_hierarchy(e); });
                return any;
            }(), uiActions);
        }
        Json entry = Json::object();
        Json press = Json::array(), release = Json::array();
        for (const std::string& a : want)
            if (std::find(held.begin(), held.end(), a) == held.end()) press.push_back(a);
        for (const std::string& a : held)
            if (std::find(want.begin(), want.end(), a) == want.end()) release.push_back(a);
        if (!press.empty()) entry["press"] = press;
        if (!release.empty()) entry["release"] = release;
        if (!entry.empty()) {
            engine.apply_input_entry(entry, replayProblems, int(frames));
            replayFrames[std::to_string(frames)] = entry;
        }
        held = want;

        // ---- one frame of `speed` fixed steps (fewer at the very end)
        const int stepsThis = int(std::min<std::int64_t>(opt.speed, totalSteps - steps));
        const double dt = std::min(fixedDt * double(stepsThis), kMaxFrameDt);
        if (opt.speed > 1) {
            while (replayTiming.size() < std::size_t(frames)) replayTiming.push_back(Json::array({fixedDt, 1}));
            replayTiming.push_back(Json::array({dt, stepsThis}));
        }
        const double cpu0 = process_cpu_seconds();
        I.run_frame(dt, stepsThis);
        const double ms = (process_cpu_seconds() - cpu0) * 1000.0;
        steps += stepsThis;
        ++frames;
        frameMs.push_back(ms);
        if (frames > kProfileWarmup) profile.add_frame(Profiler::get().last());
        if (ms > 20.0 && (s.spikes.size() < 10 || ms > s.spikes.back().ms)) {
            PlaySpike k;
            k.frame = std::uint64_t(frames - 1);
            k.ms = ms;
            k.entities = int(world.entity_count());
            if (engine.renderer()) k.renderStats = engine.renderer()->stats().to_json();
            keep_worst_spike(s.spikes, std::move(k));
        }

        // ---- what happened in the frame
        if (engine.quit_requested()) {
            ended = "quit";
            endedWhy = "the game asked to quit";
            break;
        }
        if (world.scene_generation() != lastGeneration) {
            lastGeneration = world.scene_generation();
            pendingPictures.clear();  // the scene they were waiting for is gone
            add_phase(world.scene_path(), "scene", true);
        }
        for (const ScriptSystem::AutoplayPhase& p : engine.scripts().autoplay_take_phases()) {
            ++phaseMarks;
            add_phase(p.name, "mark", false);
            if (ended.empty() && (p.ends == "won" || p.ends == "lost")) {
                ended = p.ends;
                endedWhy = "game.phase(\"" + p.name + "\", { ends: \"" + p.ends + "\" }) ended the run";
            }
        }
        take_due_pictures(false);
        if (!ended.empty()) break;

        // ---- broken: script errors every second
        if (steps - secondStart >= std::int64_t(hz)) {
            const std::uint64_t events = engine.scripts().error_events();
            badSeconds = events - errorEventsSeen >= std::uint64_t(kLoopErrorsPerSecond) ? badSeconds + 1 : 0;
            errorEventsSeen = events;
            secondStart = steps;
            if (badSeconds >= kLoopSeconds) {
                const std::string last = latest_script_error();
                add_problem("exception loop", std::format("a script raised errors every frame for {} game seconds{}", kLoopSeconds, last.empty() ? std::string() : ": " + last), "broken");
                break;
            }
        }

        // ---- stuck / broken: looks at the player (or what moves) every 0.1 game seconds
        if (steps % checkEvery < opt.speed || frames == 1) {
            Snapshot cur = take_snapshot(world);
            if (const std::uint64_t ws = world_signature(world); ws != limitSignature) {  // the scene, or what a script generated in it, changed
                limitSignature = ws;
                const WorldExtent x = measure_world(world, cur);
                haveFallLimit = false;
                if (x.any) {
                    const double unit = x.any2d ? 10.0 * double(I.project.pixelsPerMeter) : 10.0;
                    sceneLowest = x.lowest;
                    fallLimit = x.lowest - std::max(x.highest - x.lowest, unit);
                    haveFallLimit = true;
                }
            }
            bool broken = false;
            for (std::size_t i = 0; i < cur.items.size() && !broken; ++i) {
                const Tracked& t = cur.items[i];
                if (!finite3(t.pos)) {
                    add_problem("not finite", std::format("'{}' has a position that is not a number ({}): a division by zero or a NaN in a script or the physics", cur.names[i], describe_pos(t.pos)), "broken");
                    broken = true;
                } else if (haveFallLimit && t.falls && double(t.pos.y) < fallLimit) {
                    add_problem("fall", std::format("'{}' fell out of the world: its y is {:.0f}, below the limit {:.0f} (the lowest thing in the scene is at y {:.0f})",
                                                    cur.names[i], t.pos.y, fallLimit, sceneLowest), "broken");
                    broken = true;
                }
            }
            if (broken) break;
            std::uint64_t sig = signature();
            if (const std::uint64_t text = ui_text_hash(world); text != lastText) {
                lastText = text;
                textChangeSteps.push_back(steps);
                while (!textChangeSteps.empty() && textChangeSteps.front() < steps - std::int64_t(hz)) textChangeSteps.erase(textChangeSteps.begin());
                if (textChangeSteps.size() <= 2) refTextEpoch += 1;  // a real change: the reference moves on
            }
            sig = mix(sig, refTextEpoch);
            if (sig != refSig || moved_since(ref, cur, I.project.pixelsPerMeter)) {
                ref = std::move(cur);
                refSig = sig;
                refStep = steps;
            } else if (steps - refStep >= stuckSteps) {
                const bool menu = cur.kind == FocusKind::Scripts || cur.kind == FocusKind::None || bool(ui_modal_panel(world)) || bool(I.ui.focused());
                std::string where;
                if (!cur.items.empty()) where = std::format(" ('{}' stays at {})", cur.names[0], describe_pos(cur.items[0].pos));
                if (menu)
                    add_problem("menu", std::format("nothing changed for {} game seconds and the bot found no way on: a menu or screen without an action that leaves it{}",
                                                    round3(double(steps - refStep) * fixedDt), where), "stuck");
                else
                    add_problem("stuck", std::format("nothing moved for {} game seconds{}", round3(double(steps - refStep) * fixedDt), where), "stuck");
                break;
            }
        }
    }

    // ---- the end
    engine.render_now();
    take_due_pictures(true);
    s.endScreenshot = shoot("end.png");
    if (!taken.empty()) {  // the session is complete: the pictures move to its folder (a picture that cannot is dropped from the session)
        std::error_code ec;
        const std::filesystem::path finalDir = fs::resolve(relDir);
        std::filesystem::create_directories(fs::os_path(finalDir), ec);
        std::set<std::string> lost;
        for (const std::string& file : taken) {
            const std::filesystem::path from = fs::os_path(fs::resolve(scratch.rel + "/" + file));
            const std::filesystem::path to = fs::os_path(finalDir / file);
            std::error_code mv;
            std::filesystem::rename(from, to, mv);  // another drive: copy
            if (mv) {
                mv.clear();
                std::filesystem::copy_file(from, to, std::filesystem::copy_options::overwrite_existing, mv);
            }
            if (mv) lost.insert(file);
        }
        if (!lost.empty()) {
            for (PlayPhase& p : s.phases)
                if (lost.count(p.screenshot)) p.screenshot.clear();
            for (PlayMark& m : s.marks)
                if (lost.count(m.screenshot)) m.screenshot.clear();
            if (lost.count(s.endScreenshot)) s.endScreenshot.clear();
            pictures -= int(lost.size());
            note(std::format("{} screenshot(s) could not be moved into the session's folder and were dropped.", lost.size()));
        }
    }
    if (droppedPhases > 0) note(std::format("{} more phase(s) were not listed: a session lists the first {}.", droppedPhases, kPlayAutoMaxPhases));
    if (hookFailures > 0) note(std::format("The hook threw in {} step(s) (nothing was pressed in them); see scriptErrors.", hookFailures));
    if (!replayProblems.empty()) note("The bot named an input the engine did not take: " + replayProblems.front());

    Json scriptErrors = Json::array();
    {
        std::set<std::string> distinct;
        for (const std::string& e : scriptErrorsExtra)
            if (scriptErrors.size() < 20 && distinct.insert(e).second) scriptErrors.push_back(e);
        for (const ScriptError& e : engine.scripts().errors())
            if (scriptErrors.size() < 20 && distinct.insert(e.to_string()).second) scriptErrors.push_back(e.to_string());
    }
    const std::size_t logErrors = error_count() - errorsBefore;
    profile.add_memory(engine.profile_memory());
    profile.set_gpu_status(false, "the GPU time is not measured in an automatic run");

    s.durationSec = double(steps) * fixedDt;
    s.frames = std::uint64_t(frames);
    s.perf = compute_frame_stats(frameMs);
    for (const LogEntry& l : recent_logs(200, LogLevel::Warn, logSeq))
        s.logs.push_back(Json::object({{"seq", l.seq}, {"frame", l.frame >= startFrame ? l.frame - startFrame : 0}, {"level", log_level_name(l.level)},
                                       {"category", l.category}, {"message", l.message}}));
    if (profile.frames() > 0) s.profile = profile.to_json();
    s.score = hasScore ? score : Json();
    s.ended = ended.empty() ? "aborted" : ended;
    s.endedWhy = endedWhy;
    s.notes = notes;
    s.scriptErrors = scriptErrors;
    s.input = Json::object({{"frames", replayFrames}});
    if (opt.speed > 1) s.input["timing"] = replayTiming;
    const std::string replayCommand =
        std::format("factoria run --headless --frames {} --input {}/input.json --seed {}{}", frames, relDir, opt.seed,
                    config.scene.empty() ? std::string() : " --scene " + shell_word(config.scene));
    s.autoInfo = Json::object({{"bot", useHook ? "hook" : "explorer"}, {"seed", opt.seed}, {"speed", opt.speed}, {"secondsAsked", round3(opt.seconds)},
                               {"stuckSeconds", round3(opt.stuckSeconds)}, {"steps", steps}, {"errorsLogged", logErrors}, {"replay", replayCommand}});
    engine.scripts().autoplay_end();
    s.loading = engine.loading_report();
    engine.shutdown();

    if (auto w = write_play_session(relDir, s); !w.ok())
        return make_error("The session could not be written to " + absDir + ": " + w.error().message, w.error().hint);
    prune_auto_play_sessions(std::size_t(kPlayAutoKeepSessions), name);  // the oldest automatic ones beyond the newest N go

    Json phases = Json::array();
    int n = 0;
    for (const PlayPhase& p : s.phases) phases.push_back(Json::object({{"n", ++n}, {"name", p.name}, {"kind", p.kind}, {"time", round3(p.time)}, {"screenshot", p.screenshot}}));
    Json problems = Json::array();
    n = 0;
    for (const PlayMark& m : s.marks)
        problems.push_back(Json::object({{"n", ++n}, {"kind", m.kind}, {"step", m.step}, {"time", round3(m.time)}, {"note", m.note}, {"screenshot", m.screenshot}}));
    Json out = Json::object();
    out["session"] = name;
    out["dir"] = absDir;
    out["ended"] = s.ended;
    out["endedWhy"] = s.endedWhy;
    out["score"] = s.score;
    out["gameSeconds"] = round3(s.durationSec);
    out["steps"] = steps;
    out["frames"] = frames;
    out["bot"] = useHook ? "hook" : "explorer";
    out["seed"] = opt.seed;
    out["speed"] = opt.speed;
    out["phases"] = phases;
    out["problems"] = problems;
    out["scriptErrors"] = scriptErrors;
    out["warningsAndErrorsLogged"] = s.logs.size();
    out["notes"] = notes;
    out["avgFrameMs"] = std::round(s.perf.avgMs * 10.0) / 10.0;
    out["maxFrameMs"] = std::round(s.perf.maxMs * 10.0) / 10.0;
    out["screenshots"] = pictures;  // shoot() counts the end picture too
    out["endScreenshot"] = s.endScreenshot.empty() ? std::string() : absDir + "/" + s.endScreenshot;
    out["replay"] = replayCommand;
    out["next"] = "play.report {\"session\":\"" + name + "\"} has the numbers, the logs and every picture; the replay command plays the same input again.";
    return out;
}

}  // namespace fa
