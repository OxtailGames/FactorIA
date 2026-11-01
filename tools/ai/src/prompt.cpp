// System prompt for the built-in agent: engine guide summary + project context + rules.
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/ai/session.h"
#include "fa/ai/skills.h"
#include "fa/core/strings.h"
#include "fa/tooling/skills.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

namespace {

constexpr const char* kGuide = R"(# FactorIA engine guide (summary)
FactorIA is an AI-native C++20 2D/3D game engine. Everything is text: projects, scenes and prefabs are JSON
(validated by JSON Schemas), gameplay is JavaScript (QuickJS) in scripts/*.js, project-specific tools are
tools/*.js. Every capability is a command exposed to you as a tool (the tool name is the command name with
'.' replaced by '_', e.g. scene.spawn -> scene_spawn). Errors tell you where, what and how to fix it.
Conventions: right-handed, +Y up, angles in degrees, colors 0..1, 2D units are design pixels, 3D units are
meters. JSON keys are camelCase. The simulation is deterministic: headless runs with a seed and input
replays always give the same result.
Use the docs_* and api_* tools (when present) to read the engine docs and the component reference before
guessing field names.)";

constexpr const char* kRules = R"(# Rules
1. Inspect before you change: list the project files and read the relevant docs/components first.
2. After every meaningful change run project_validate and fix every error it reports.
3. Verify behaviour: run the game headlessly (game_* tools), step frames, read logs and state dumps, and LOOK at
   screenshots (game_screenshot) to check visuals. Do not claim something works without having run it.
4. Write tests for gameplay logic (JavaScript tests in the project) and run them.
5. Keep edits inside the project directory. Prefer the dedicated tools over raw file edits when one exists.
6. ALWAYS record engine gaps with feedback_report before finishing: whenever the engine lacked a feature, an
   error was confusing, or you needed a workaround, add an entry (what was missing, workaround, suggestion).
7. Finish with a short summary: what you changed, how you verified it, open problems.)";

// %TOOL% = the delegation tool: agent_delegate (built-in loop) or ai_run (CLI agents, through the FactorIA MCP server).
// %ROLES% = one line per role that is on, %SELF% = what the orchestrator does itself because a role is off.
constexpr const char* kOrchestrator = R"(# Your role: orchestrator
You plan the work and delegate. Use %TOOL% {role, task} to hand self-contained tasks to the role that does them:
%ROLES%
They run the models the user chose for those roles, so prefer them over doing the work yourself. %HANDOFF%Answer
questions and tiny one-step changes yourself. Give each delegated task all the context it needs (file paths, acceptance criteria, the art direction): the sub-agent does not see this
conversation. It returns its final report as the tool result. Review results yourself (run project_validate,
screenshots) before finishing.
%SELF%)";

constexpr const char* kOrchestratorAlone = R"(# Your role: orchestrator
The user turned off every other role (worker, fast, artist and audio), so you have nobody to delegate to and no delegation
tool: you do ALL the work yourself, with the tools you have. Do not try to start other agents (your own sub-agent tools
(Agent, Task) are off on purpose too). The art critics ("artCritic") and the game reviewers ("reviewer") are not yours to
call: the user starts them with the review buttons, and when they want you to act on a review they send it to you as a
message. Plan, build, verify (project_validate, screenshots) and report as the Rules above say.
%SELF%

%REVIEWABLE%)";

constexpr const char* kOrchestratorDelegation = R"(Delegate ONLY through %TOOL%. Your own built-in sub-agent tools (Agent, Task) are switched off on purpose: work done by
them is invisible to the user (no progress, no usage, no role) and is lost when your turn ends. The art critics
("artCritic") and the game reviewers ("reviewer") are not yours to call: the user starts them with the review buttons,
and when they want you to act on a review they send it to you as a message.

%TOOL% blocks until the sub-agent has finished, which can take many minutes, while the user watches its progress
live. Just wait for the result: it comes back as the tool result. Never end your turn promising to continue or to
be notified later (nothing wakes you up), and never wait for a sub-agent with Bash (sleep, polling loops, background
processes).

%REVIEWABLE%)";

// The convention that lets the critics and the reviewers (who only look and play) test the game quickly, the craft of the artist
// and the audio role, and the other topic guides are engine skills (skills/<name>/SKILL.md, embedded in the binary; docs/SKILLS.md).
// The prompt carries one line per skill the role is offered; a context that did not look for skills (`skillsKnown` false) gets the
// text of the review-ready, make-art and make-audio skills inline, as before skills existed.

constexpr const char* kReadOnlyRules = R"(You are READ-ONLY: you never edit files, scenes or settings, never save, never generate assets, and never delegate. You
have only the tools that observe and play (screenshots, running scenes, stepping and input, state, logs, reading files and
docs). If something is missing or broken, say so in your report: someone else fixes it. Of the Rules above, only 3 (run and
look) applies to you: do not write tests, validate-and-fix or record feedback.

How to work:
1. Read REVIEW.md first (below, when the project has one): controls, goal, what is finished, how to reach every scene. If
   it is missing or too thin for you to reach the scenes, say so as a finding: the team must write it.
2. Play and look for real: load each scene, step frames, press inputs, click like a player, take screenshots and LOOK at
   them (several moments, different states, small and large UI). Do not judge what you have not seen.
3. Be concrete: for each point name the scene or screen, what you saw, why it matters and what to change. Rank them by
   impact. Say what works too: the team must know what to keep.
4. Your persona below changes what you notice and how you speak, never the facts.)";

// The artist and the audio role: what they make in a few lines; the craft is the skill make-art / make-audio. Their own prompts add
// what they do not do and that they cannot delegate; an orchestrator whose artist or audio role is off gets the same guidance.
constexpr const char* kArtistIntro = "You make all of the game's art: images, textures, sprites, tilesets, UI skins, 3D models, materials and the look. "
                                     "Use the asset tools, LOOK at what you made in screenshots of the running game, and keep one art direction.";
constexpr const char* kAudioIntro = "You make all of the game's audio: sound effects, music, ambience, voice, buses and mixing. Use the asset and audio "
                                    "tools; you cannot hear, so check every clip with the analysis tools and audio_log.";
constexpr const char* kArtist = R"(# Your role: artist
%GUIDE%
You do not write gameplay code (that is the worker) or audio (that is the audio role); hook the art into scenes and
prefabs only as far as needed to see it. You cannot delegate. Report what you made (paths), what you decided and what is
still missing.

%REVIEWABLE%)";

constexpr const char* kAudio = R"(# Your role: audio
%GUIDE%
You do not write gameplay code or art; wire sounds into scripts only as far as needed to test them. You cannot delegate.
Report what you made (paths), the mix decisions and what is still missing.

%REVIEWABLE%)";

constexpr const char* kArtCritic = R"(# Your role: art critic
You are one of the art critics of the game: you judge how it LOOKS, as a critic who has played the current build. Cover
the art direction (is there one, does it suit the game), consistency (palette, style, scale, resolution between assets
and between scenes), readability (can the player tell what is what: the character, the threats, the pickups, the UI text
and contrast, at small sizes), animation and effects, lighting and look, the UI/HUD, and polish (aliasing, stretching,
placeholder art, mismatched fonts, empty-looking screens).
%READONLY%

End the report with a short numbered list "Do this next" (at most 7 actions, each doable by the artist in one task), then
the LAST thing you write is one fenced json block, exactly this shape (scores 0 to 10, one decimal; 5 is average, 7 is
good, 9 is exceptional):
```json
{"score": 7.5, "subScores": {"direction": 8, "consistency": 7, "readability": 7, "polish": 6}, "summary": "one sentence"}
```)";

constexpr const char* kReviewer = R"(# Your role: game reviewer
You are one of the game reviewers: a press reviewer who plays the current build and writes what a player and a reader
should know. Cover the game as a whole: is it fun and why, the core loop and its pacing, game feel (input response,
feedback, juice), design (goals, difficulty, progression, clarity of the rules), UX (menus, onboarding, readability of
the UI, pause, options), bugs and rough edges you hit (include how to reproduce them), polish, art and audio (what the
logs and the audio log show: do sounds play when they should). Say who it is for and whether you would recommend it.
%READONLY%

End the report with a short numbered list "Do this next" (at most 7 actions, most important first), then the LAST thing
you write is one fenced json block, exactly this shape (scores 0 to 10, one decimal; 5 is average, 7 is good, 9 is
exceptional; give a score for every sub-score you could judge):
```json
{"score": 7.0, "subScores": {"fun": 7, "gameFeel": 6, "design": 7, "ux": 6, "stability": 8, "polish": 6, "art": 7, "audio": 5}, "summary": "one sentence"}
```)";

// The body of an engine skill (what skills_read gives), "" when this build has no such skill.
std::string engine_body(const char* name) {
    const auto text = fa::engine_skill_read(name);
    if (!text) return {};
    auto fm = fa::parse_skill_md(*text, name);
    return fm ? std::string(fa::trim(fm->body)) : std::string();
}

bool has_skill(const PromptContext& ctx, std::string_view name) {
    return std::any_of(ctx.skills.begin(), ctx.skills.end(), [&](const SkillBrief& s) { return s.name == name; });
}

// What the prompt says about a craft guide (make-art, make-audio): a pointer when the role is offered the skill, nothing when the
// user switched it off for the role, the whole guide when skills were not looked for.
std::string craft_guide(const PromptContext& ctx, const char* skill, const char* intro) {
    std::string tool = ctx.skillTool.empty() ? "skills_read" : ctx.skillTool;
    if (has_skill(ctx, skill))
        return std::string(intro) + "\nYour craft guide is the skill `" + skill + "`: read it before you start (" + tool + " {\"name\": \"" + skill + "\"}).";
    if (ctx.skillsKnown) return intro;
    return engine_body(skill);
}

// The review-ready convention, as the role's prompt carries it: nothing (the skill's line says when to read it) or the whole text.
std::string reviewable(const PromptContext& ctx) {
    if (ctx.skillsKnown || has_skill(ctx, "review-ready")) return {};
    return engine_body("review-ready");
}

std::string read_head(const fsys::path& p, std::size_t maxBytes) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return {};
    std::string s(maxBytes, '\0');
    f.read(s.data(), static_cast<std::streamsize>(maxBytes));
    s.resize(static_cast<std::size_t>(f.gcount()));
    return s;
}

std::string file_listing(const fsys::path& root, std::size_t maxEntries) {
    std::vector<std::string> files;
    std::error_code ec;
    for (auto it = fsys::recursive_directory_iterator(root, fsys::directory_options::skip_permission_denied, ec);
         it != fsys::recursive_directory_iterator(); it.increment(ec)) {
        if (ec) break;
        std::string name = it->path().filename().string();
        if (it->is_directory(ec)) {
            if (name.empty() || name[0] == '.' || name == "build" || name == "node_modules") it.disable_recursion_pending();
            continue;
        }
        if (!name.empty() && name[0] == '.') continue;
        files.push_back(fsys::relative(it->path(), root, ec).generic_string());
    }
    std::sort(files.begin(), files.end());
    std::string out;
    std::size_t n = 0;
    for (const auto& f : files) {
        if (n++ >= maxEntries) {
            out += "... (" + std::to_string(files.size() - maxEntries) + " more; use the file-listing tool)\n";
            break;
        }
        out += f + "\n";
    }
    return out;
}

std::string feedback_summary(const fsys::path& root) {
    std::string text = read_head(root / "ENGINE_FEEDBACK.json", 1u << 20);
    if (text.empty()) return "ENGINE_FEEDBACK.json: not found.";
    Json j = parse(text);
    const Json* entries = j.is_discarded() ? nullptr : child(j, "entries");
    if (!entries || !entries->is_array()) return "ENGINE_FEEDBACK.json: unreadable (fix it or run project_validate).";
    int open = 0;
    std::string titles;
    for (const auto& e : *entries) {
        if (str(e, "status", "open") == "open") {
            if (++open <= 10) titles += "- " + str(e, "id") + " [" + str(e, "severity") + "] " + str(e, "title") + "\n";
        }
    }
    std::string out = "ENGINE_FEEDBACK.json: " + std::to_string(entries->size()) + " entries, " + std::to_string(open) + " open.\n";
    if (const std::string arch = read_head(root / "ENGINE_FEEDBACK.archive.json", 1u << 20); !arch.empty()) {
        Json a = parse(arch);
        const Json* ae = a.is_discarded() ? nullptr : child(a, "entries");
        if (ae && ae->is_array() && !ae->empty())
            out += "(" + std::to_string(ae->size()) + " closed entries are in ENGINE_FEEDBACK.archive.json.)\n";
    }
    out += titles;
    if (open > 10) out += "- ... and " + std::to_string(open - 10) + " more\n";
    return out;
}

}  // namespace

std::string asset_sources_prompt(const AssetSources& sources) {
    if (sources.empty()) return {};
    std::string out = "# Asset sources\n"
                      "The user listed the websites where assets for this game should come from: images and textures, 3D models, "
                      "audio, fonts and the rest. They are the user's choice of safe, license-clear places, so ";
    out += sources.onlyListed ? "use them instead of searching the internet at large." : "look there before anywhere else.";
    out += "\n";
    for (SiteCategory c : kSiteCategories) {
        if (sources.list(c).empty()) continue;
        out += std::string("\n") + site_category_title(c) + ":\n";
        for (const AssetSite& site : sources.list(c)) out += "- " + site.url + (site.note.empty() ? "" : " (" + site.note + ")") + "\n";
    }
    out += "\n";
    if (sources.onlyListed) {
        out += "RULE: look for and fetch assets ONLY on these sites. Do not run a general web search and do not fetch from any other "
               "site, even when a link or a search result points there. If these sites do not have what the game needs, say so in "
               "your report (or make the asset with the generate and procedural asset tools) instead of looking elsewhere.\n";
    } else {
        out += "RULE: prefer these sites. Look there first for each kind of asset; only when none of them has what the game needs, "
               "search the rest of the internet.\n";
    }
    out += "If you have no way to browse the web, tell the user which of these sites to download from; never invent a URL.\n"
           "Whatever you take from a site: check its license allows use in a game that is sold (CC0 or CC-BY are safe; if the license "
           "is unclear, do not use it), download the file, bring it in with assets_import and pass sourceUrl (the page it came from), "
           "license and author, so assets.json keeps its source and license for the credits.";
    return out;
}

std::string external_tools_prompt(const std::vector<ToolServerBrief>& servers, bool readOnly) {
    if (servers.empty()) return {};
    std::string out = "# External tools\n"
                      "The user connected these external tool servers. Their tools are listed next to your other tools; use them "
                      "when they help the game (for example to make something the engine's own tools cannot), not for what you "
                      "can do without them.\n\n";
    for (const ToolServerBrief& s : servers) {
        out += "- " + s.name;
        if (!s.toolPrefix.empty()) out += " (its tools are named `" + s.toolPrefix + "<tool>`)";
        out += s.note.empty() ? "\n" : ": " + s.note + "\n";
    }
    out += "\nRules:\n"
           "- A call may cost the user credits or money. Try one small call first and look at the result before you start a batch; "
           "do not repeat a call whose result you already have.\n"
           "- If a call fails (a key, credits, the network), tell the user what failed and why instead of retrying in a loop.\n";
    if (readOnly) {
        out += "- You only look and judge: do not use a tool that generates or changes anything for the project.";
    } else {
        out += "- What a tool makes is not in the project yet. Download the file, bring it in with assets_import and pass sourceUrl "
               "(where it came from), license (what the service grants for the user's plan, or \"unknown\" when you cannot tell) "
               "and author, so assets.json keeps its source and license for the credits. Never use a file whose license you "
               "cannot state.";
    }
    return out;
}

std::string build_system_prompt(const PromptContext& ctx) {
    std::string out = kGuide;
    out += "\n\n";
    out += kRules;
    out += "\n\n";
    auto fill = [](std::string text, const std::string& key, const std::string& value) {
        for (std::size_t at; (at = text.find(key)) != std::string::npos;) text.replace(at, key.size(), value);
        return text;
    };
    std::vector<std::string> off;  // the delegable roles that are off, in the order the orchestrator lists them
    for (const char* r : {kRoleWorker, kRoleFast, kRoleArtist, kRoleAudio}) {
        if (std::find(ctx.disabledRoles.begin(), ctx.disabledRoles.end(), r) != ctx.disabledRoles.end()) off.push_back(r);
    }
    auto is_off = [&](const char* r) { return std::find(off.begin(), off.end(), r) != off.end(); };
    if (ctx.role == kRoleOrchestrator && (ctx.canDelegate || off.size() == 4)) {
        // What the orchestrator does itself because the user turned a role off.
        std::string self;
        if (!off.empty()) {
            self = "\nThese roles are OFF (the user turned them off): do their work yourself, never try to hand it over.\n";
            if (is_off(kRoleWorker)) self += "- worker is off: implement features and fixes yourself.\n";
            if (is_off(kRoleFast)) self += "- fast is off: make the small mechanical edits yourself.\n";
            if (is_off(kRoleArtist)) self += "- artist is off: make the art yourself with the asset tools (guidance below).\n";
            if (is_off(kRoleAudio)) self += "- audio is off: make the audio yourself with the asset and audio tools (guidance below).\n";
            if (is_off(kRoleArtist)) {
                self += "\n## The art, which you make yourself\n" + craft_guide(ctx, "make-art", kArtistIntro) + "\n";
            }
            if (is_off(kRoleAudio)) {
                self += "\n## The audio, which you make yourself\n" + craft_guide(ctx, "make-audio", kAudioIntro) + "\n";
            }
        }
        if (ctx.canDelegate) {
            const std::string tool = ctx.delegateTool.empty() ? kDelegateTool : ctx.delegateTool;
            std::string lines;
            if (!is_off(kRoleWorker)) lines += "\"worker\" implements features and fixes (the default for coding).\n";
            if (!is_off(kRoleFast)) lines += "\"fast\" does tiny mechanical edits.\n";
            if (!is_off(kRoleArtist))
                lines += "\"artist\" makes ALL the game's art (images, textures, sprites, tilesets, UI skins, 3D models, materials, the look).\n";
            if (!is_off(kRoleAudio))
                lines += "\"audio\" makes ALL its sound (sound effects, music, ambience, voice, buses and mixing).\n";
            std::string handoff;
            if (!is_off(kRoleArtist)) handoff += "Hand art to the artist";
            if (!is_off(kRoleAudio)) handoff += std::string(handoff.empty() ? "Hand sound" : " and sound") + " to the audio role";
            if (!handoff.empty()) handoff += " instead of asking a worker to generate assets. ";
            std::string role = fill(fill(fill(kOrchestrator, "%ROLES%", lines), "%HANDOFF%", handoff), "%SELF%", self);
            role += "\n";
            role += kOrchestratorDelegation;
            role = fill(fill(role, "%TOOL%", tool), "%REVIEWABLE%", reviewable(ctx));
            out += role;
        } else {
            out += fill(fill(kOrchestratorAlone, "%SELF%", self), "%REVIEWABLE%", reviewable(ctx));
        }
        out += "\n\n";
    } else if (ctx.role == kRoleWorker) {
        out += "# Your role: worker\nYou implement the task you were given completely and report concisely. You cannot delegate.\n\n";
        if (const std::string r = reviewable(ctx); !r.empty()) out += r + "\n\n";
    } else if (ctx.role == kRoleFast) {
        out += "# Your role: fast\nYou do small mechanical tasks quickly and report in a few lines. You cannot delegate.\n\n";
    } else if (ctx.role == kRoleArtist) {
        out += fill(fill(kArtist, "%GUIDE%", craft_guide(ctx, "make-art", kArtistIntro)), "%REVIEWABLE%", reviewable(ctx)) + "\n\n";
    } else if (ctx.role == kRoleAudio) {
        out += fill(fill(kAudio, "%GUIDE%", craft_guide(ctx, "make-audio", kAudioIntro)), "%REVIEWABLE%", reviewable(ctx)) + "\n\n";
    } else if (ctx.role == kRoleArtCritic) {
        out += fill(kArtCritic, "%READONLY%", kReadOnlyRules) + "\n\n";
    } else if (ctx.role == kRoleReviewer) {
        out += fill(kReviewer, "%READONLY%", kReadOnlyRules) + "\n\n";
    }
    if (!is_review_role(ctx.role)) {  // the critics and the reviewers look and play, they do not bring assets in
        if (const std::string section = asset_sources_prompt(ctx.assetSources); !section.empty()) out += section + "\n\n";
    }
    if (const std::string section = external_tools_prompt(ctx.toolServers, is_review_role(ctx.role)); !section.empty())
        out += section + "\n\n";
    if (!ctx.skillsNative) {
        if (const std::string section = skills_prompt(ctx.skills, ctx.skillTool.empty() ? "skills_read" : ctx.skillTool); !section.empty())
            out += section + "\n";
    }
    if (!ctx.toolCatalog.empty()) out += ctx.toolCatalog + "\n";
    out += "# Project context\n";
    if (ctx.projectDir.empty()) {
        out += "No project directory is open.\n";
    } else {
        fsys::path root(ctx.projectDir);
        out += "Project directory: " + root.string() + "\n";
        std::string manifest = read_head(root / "factoria.json", 4000);
        if (!manifest.empty()) out += "\nfactoria.json:\n```json\n" + manifest + "\n```\n";
        out += "\nFiles:\n" + file_listing(root, 150);
        out += "\n" + feedback_summary(root) + "\n";
        if (is_review_role(ctx.role)) {
            std::string note = read_head(root / "REVIEW.md", 12000);
            out += note.empty() ? "\nREVIEW.md: not found (the team has not written the review note yet).\n"
                                : "\nREVIEW.md (read this first):\n" + note + "\n";
        }
    }
    if (!ctx.extra.empty()) out += "\n" + ctx.extra + "\n";
    return out;
}

}  // namespace fa::ai
