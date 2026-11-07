// play.auto (fa/tooling/play_auto.h): validates the arguments, runs the driver in a second headless engine and answers with the summary.
#include "fa/tooling/play_auto.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <format>

#include "assets_shots.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/play_auto.h"
#include "fa/tooling/self_update.h"
#include "headless_run.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;

[[noreturn]] void bad(const std::string& pointer, const std::string& message, const std::string& hint) {
    throw CommandError("invalid_argument", pointer + ": " + message, hint);
}

// `projectDir` is the folder as the rest of the tooling carries it (a native string: the engine builds its project root from it the same
// way); arguments and results that are JSON are UTF-8 text and go through fs::path_from_utf8 / fs::path_to_utf8, never the Windows code page.
stdfs::path project_root_path(const std::string& projectDir) { return stdfs::path(projectDir); }

// The scene files under the project, project-relative, for the "did you mean" of a wrong scene argument.
std::vector<std::string> scene_candidates(const std::string& projectDir) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path root = fs::os_path(project_root_path(projectDir));
    stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end;
    int visited = 0;
    for (; !ec && it != end && visited < 5000; it.increment(ec), ++visited) {
        if (fs::path_to_utf8(it->path().filename()).find(".scene.json") == std::string::npos) continue;
        out.push_back(fs::path_to_utf8(stdfs::relative(it->path(), root, ec)));
    }
    std::sort(out.begin(), out.end());
    return out;
}

double number_arg(const Json& a, const char* key, double def, double lo, double hi, const char* hint) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number() || !(it->get<double>() >= lo) || !(it->get<double>() <= hi))
        bad(std::string("/") + key, std::format("must be a number from {} to {}.", lo, hi), hint);
    return it->get<double>();
}

Json run_play_auto(const Json& a, const std::string& projectDir) {
    tooling_detail::require_project_dir(projectDir, "play.auto");
    PlayAutoOptions opt;
    opt.seconds = number_arg(a, "seconds", 60.0, 0.1, kPlayAutoMaxSeconds, "A minute of play is 60; the longest run is an hour of game time.");
    // Not given: 10 game seconds, or half of a shorter run (a short run could never call a game stuck otherwise); never more than the run.
    opt.stuckSeconds = number_arg(a, "stuckSeconds", std::min(opt.seconds, std::max(0.5, std::min(10.0, opt.seconds / 2.0))), 0.5, kPlayAutoMaxSeconds,
                                  "10 game seconds without anything moving is long enough for a platformer; slow games need more.");
    {
        auto it = a.find("speed");
        if (it != a.end() && !it->is_null()) {
            if (!it->is_number_integer() || it->get<long long>() < 1 || it->get<long long>() > kPlayAutoMaxSpeed)
                bad("/speed", std::format("must be a whole number from 1 to {}.", kPlayAutoMaxSpeed), "It is how many fixed steps one frame runs; 1 plays every step, 4 is about four times as fast.");
            opt.speed = int(it->get<long long>());
        }
        it = a.find("seed");
        if (it != a.end() && !it->is_null()) {
            if (!it->is_number_integer() || it->get<long long>() < 0 || it->get<long long>() > 9007199254740991LL)
                bad("/seed", "must be a whole number from 0 to 9007199254740991.", "The same seed plays the same game; try another to see a different run.");
            opt.seed = std::uint64_t(it->get<long long>());
        }
    }
    if (opt.stuckSeconds > opt.seconds)
        bad("/stuckSeconds", std::format("is {} game seconds but the run only lasts {}, so a stuck game could never be told apart from a short run.", opt.stuckSeconds, opt.seconds),
            "Ask for more seconds, or lower stuckSeconds below seconds.");
    const std::string botKind = tooling_detail::arg_string(a, "bot", false, "auto");
    if (botKind != "auto" && botKind != "hook" && botKind != "explorer")
        bad("/bot", "must be \"auto\", \"hook\" or \"explorer\", got \"" + botKind + "\". " + did_you_mean(botKind, std::vector<std::string>{"auto", "hook", "explorer"}),
            "auto uses scripts/autoplay.js when there is one, else the generic explorer.");
    const bool hasHookFile = stdfs::exists(fs::os_path(project_root_path(projectDir) / "scripts" / "autoplay.js"));
    if (botKind == "hook" && !hasHookFile)
        bad("/bot", "\"hook\" needs scripts/autoplay.js, and the project has none.",
            "Create it with game.autoplay((bot) => [...]) (docs/SCRIPTING.md, \"The bot\"), or leave bot out to let the generic explorer play.");
    opt.useHook = botKind != "explorer";
    opt.hookRequired = botKind == "hook";
    opt.screenshots = tooling_detail::arg_bool(a, "screenshots", true);
    const std::string scene = tooling_detail::arg_string(a, "scene", false);
    const stdfs::path scenePath = scene.empty() ? stdfs::path() : (fs::is_absolute(scene) ? fs::path_from_utf8(scene) : project_root_path(projectDir) / fs::path_from_utf8(scene));
    if (!scene.empty() && !stdfs::exists(fs::os_path(scenePath))) {
        const std::vector<std::string> scenes = scene_candidates(projectDir);
        bad("/scene", "the scene '" + scene + "' does not exist in the project. " + did_you_mean(scene, scenes),
            "Pass a project-relative path such as scenes/level1.scene.json, or leave scene out for the project's mainScene.");
    }

    // A process has one graphics device: when this one has it (the editor, a window) the pictures need a child process.
    if (opt.screenshots && gfx_device_active()) return assets_detail::call_in_child(projectDir, "play.auto", a);

    EngineConfig cfg = tooling_detail::headless_engine_config(projectDir, scene, opt.screenshots && !gfx_device_active(), RenderMode::OnDemand);
    auto r = play_auto(cfg, opt);
    if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
    Json out = r.value();
    const std::string endShot = out.value("endScreenshot", std::string());
    if (!endShot.empty() && stdfs::exists(fs::os_path(fs::path_from_utf8(endShot))))
        out["$image"] = Json::object({{"path", endShot}, {"mimeType", "image/png"}});
    return out;
}

}  // namespace

std::string factoria_executable() {
    std::error_code ec;
    if (const char* env = std::getenv("FA_FACTORIA_EXE"); env && *env) {  // a wrong override is not replaced by another program
        const stdfs::path p = fs::path_from_utf8(env);
        return stdfs::is_regular_file(p, ec) ? fs::path_to_utf8(p) : std::string();
    }
    stdfs::path exe = executable_path();
    if (exe.empty()) return {};
    if (exe.stem() != "factoria") {  // the editor or a game: the command line tool sits next to it
        stdfs::path sibling = exe.parent_path() / "factoria";
        sibling += exe.extension();  // ".exe" on Windows, nothing elsewhere; no round trip through std::string
        if (!stdfs::is_regular_file(sibling, ec)) return {};
        exe = sibling;
    }
    return fs::path_to_utf8(exe);
}

Json play_auto_in_child(const std::string& projectDir, const Json& args, const CancelFlag* cancel) {
    return assets_detail::call_in_child(projectDir, "play.auto", args, cancel);
}

void register_play_auto_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo c;
    c.name = "play.auto";
    c.category = "play";
    c.readOnly = false;
    c.summary = "Let the game play itself, headless and fast, and write the run as a play session: phases, score, how it ended, problems found, pictures.";
    c.description =
        "Run this after you build a feature and BEFORE you ask the user to play: it plays the game with nobody at the keyboard and tells you whether it can be finished, where it gets stuck and what breaks. "
        "A second headless engine in this process (fake platform, in-memory saves, fixed 1/fixedHz steps, the same `seed` plays the same game) plays up to `seconds` GAME seconds. The bot is the game's own: "
        "scripts/autoplay.js calls game.autoplay(fn) and fn(bot) answers, every step, the input actions to hold (docs/SCRIPTING.md, \"The bot\"; the project templates ship one that finishes their sample level). "
        "Without that file a generic explorer holds the declared input actions in seeded patterns (and taps the menu actions when the scene has buttons), so any game still gets smoke-played; bot \"explorer\" forces it. "
        "The run ends with `ended`: \"won\" or \"lost\" (the hook returned { end } or the game called game.phase(name, { ends })), \"timeout\" (the seconds passed), \"quit\" (the game quit), \"stuck\" (nothing moved and nothing changed for "
        "stuckSeconds, or a menu has nobody to press it), \"broken\" (a script raised errors every second for 3 seconds, something pulled by gravity fell out of the world, a position became NaN, or scripts/autoplay.js could not be loaded) or \"aborted\" (a real-time safety net of 800 seconds, far above any normal run). "
        "Each problem becomes a mark with its `kind`, the `step`, a screenshot and a one-line note. The session is written to .factoria/sessions/<name>/ with \"source\": \"auto\" next to the editor's: session.json (perf, spikes, warnings, errors, marks, "
        "`phases` = the scenes and the game.phase(\"boss\") marks with their game time and a screenshot, `score`, `ended`, `endedWhy`, `notes`, `scriptErrors`, `auto`), input.json (the bot's input in the replay format) and the pictures. "
        "Returns {session, dir, ended, endedWhy, score, gameSeconds, steps, frames, bot (\"hook\" or \"explorer\"), seed, speed, phases, problems, scriptErrors, warningsAndErrorsLogged, notes, avgFrameMs, maxFrameMs, screenshots, endScreenshot, replay, next} "
        "and the picture of the end ($image). Read the details with play.report {session}; replay the problem with the `replay` command (factoria run --headless --input ... --seed ...). "
        "Without a GPU the numbers, phases and marks are complete and `notes` says there are no pictures (a Linux machine without a display needs Mesa's EGL, llvmpipe). "
        "From the editor or any process that already uses the graphics card the command runs `factoria call play.auto` in a child process. The result never depends on how fast the machine is. "
        "Example: {\"seconds\":120,\"seed\":7} or {\"scene\":\"scenes/level2.scene.json\",\"bot\":\"explorer\",\"speed\":4}.";
    c.inputSchema = Json::parse(R"({"type":"object","additionalProperties":false,"properties":{
        "scene":{"type":"string","description":"Project-relative scene to start in (default: the project's mainScene)."},
        "seconds":{"type":"number","minimum":0.1,"maximum":3600,"default":60,"description":"How many GAME seconds to play at most (simulation time: steps / fixedHz, never the clock). The run ends \"timeout\" when they pass."},
        "seed":{"type":"integer","minimum":0,"maximum":9007199254740991,"default":1,"description":"Seed of the world's random numbers, of the explorer and of bot.rng in the hook: the same seed plays the same game."},
        "speed":{"type":"integer","minimum":1,"maximum":8,"default":1,"description":"Fixed steps run per frame. The bot answers once per frame, so 4 plays about four times as much game time per second of real time, with a coarser bot. Replays keep the same timing."},
        "stuckSeconds":{"type":"number","minimum":0.5,"maximum":3600,"description":"Game seconds without the player (or whatever can move) moving and without a scene, phase, score or menu-focus change before the run is called stuck. Must not be more than seconds. Default 10, or half of seconds when the run is shorter than 20."},
        "bot":{"type":"string","enum":["auto","hook","explorer"],"default":"auto","description":"auto: scripts/autoplay.js when the project has one, else the generic explorer. hook: the file is required (error without it). explorer: ignore the file and press the declared actions in seeded patterns."},
        "screenshots":{"type":"boolean","default":true,"description":"Take a screenshot per phase, per problem and at the end (needs a GPU; without one the session says so in its notes). false: numbers only, a little faster."}}})");
    registry.add(c, [projectDir](const Json& a) { return run_play_auto(a, projectDir); });
}

}  // namespace fa
