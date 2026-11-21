#include "fa/tooling/docs.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <initializer_list>
#include <iterator>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <string_view>

#include "fa/core/strings.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/notices.h"
#include "util.h"

namespace fa {

namespace {

std::string doc_name_from_path(std::string_view path) {
    std::string stem(path.substr(path.rfind('/') == std::string_view::npos ? 0 : path.rfind('/') + 1));
    if (ends_with(stem, ".md")) stem.resize(stem.size() - 3);
    for (char& c : stem) c = c == '_' ? '-' : static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return stem;
}

std::string first_heading(const std::string& text) {
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line))
        if (line.rfind("# ", 0) == 0) return std::string(trim(line.substr(2)));
    return {};
}

std::vector<std::string> lines_of(const std::string& text) {
    std::vector<std::string> out;
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line)) out.push_back(line);
    return out;
}

// A heading line of the page ("## 9.23 Art" -> level 2, title "9.23 Art"), found outside code fences.
struct DocHeading {
    int level = 0;
    std::string title;
    size_t line = 0;  // 1-based
};

std::vector<DocHeading> headings_of(const std::vector<std::string>& lines) {
    std::vector<DocHeading> out;
    bool inFence = false;
    for (size_t i = 0; i < lines.size(); ++i) {
        const std::string& l = lines[i];
        if (l.rfind("```", 0) == 0 || l.rfind("~~~", 0) == 0) {
            inFence = !inFence;
            continue;
        }
        if (inFence || l.empty() || l[0] != '#') continue;
        size_t n = 0;
        while (n < l.size() && l[n] == '#') ++n;
        if (n > 6 || n >= l.size() || l[n] != ' ') continue;
        out.push_back({int(n), std::string(trim(l.substr(n))), i + 1});
    }
    return out;
}

// Cuts `s` to at most `n` bytes without splitting a UTF-8 character.
std::string cut_utf8(const std::string& s, size_t n) {
    if (s.size() <= n) return s;
    while (n > 0 && (static_cast<unsigned char>(s[n]) & 0xC0) == 0x80) --n;
    return s.substr(0, n);
}

// The table of contents of a page that was cut: headings with their line numbers, as many levels as fit in `budget` bytes.
std::string contents_text(const std::vector<DocHeading>& heads, size_t budget) {
    for (int maxLevel = 6; maxLevel >= 1; --maxLevel) {
        std::string out;
        for (const DocHeading& h : heads) {
            if (h.level > maxLevel) continue;
            out +=
                std::string(size_t(h.level - 1) * 2, ' ') + "- " + h.title + " (line " + std::to_string(h.line) + ")\n";
        }
        if (out.size() <= budget || maxLevel == 1) return cut_utf8(out, budget);
    }
    return {};
}

const DocFiles* g_docFiles = nullptr;

std::vector<std::string> doc_files_list() { return g_docFiles ? g_docFiles->list("docs/") : bundled_list("docs/"); }

std::optional<std::string> doc_file_read(std::string_view path) {
    return g_docFiles ? g_docFiles->read(path) : bundled_read(path);
}

std::string dir_of(const std::string& path) {
    const size_t s = path.rfind('/');
    return s == std::string::npos ? std::string() : path.substr(0, s);
}

std::string base_of(const std::string& path) {
    const size_t s = path.rfind('/');
    return s == std::string::npos ? path : path.substr(s + 1);
}

std::string upper_of(std::string s) {
    for (char& c : s) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return s;
}

// Only the generated reference and the translations are not part of the doc layout.
bool is_layout_path(const std::string& path) {
    return ends_with(path, ".md") && path.rfind("docs/reference/", 0) != 0 && path.rfind("docs/i18n/", 0) != 0;
}

// The entry page of the folder a doc sits in: docs/scripting/SCRIPTING_INPUT.md -> docs/SCRIPTING.md (the doc in the folder's
// parent whose name is the folder's). Empty when the doc is not in such a folder.
std::string entry_path_of(const std::string& path, const std::vector<std::string>& all) {
    const std::string dir = dir_of(path);
    if (dir.empty() || dir == "docs") return {};
    const std::string parent = dir_of(dir);
    const std::string want = doc_name_from_path(base_of(dir));
    for (const std::string& e : all)
        if (dir_of(e) == parent && doc_name_from_path(e) == want) return e;
    return {};
}

constexpr long kDocReadDefaultBytes = 40000;  // ~10k tokens: an MCP tool result is capped near 25k tokens
constexpr long kDocReadMaxBytes = 90000;

// The one place that says what each embedded doc is for. A table here (not a docs/index.json) because it needs no
// CMake embed rule and sits next to the code that serves it; the test "docs: every embedded doc has a manifest entry"
// fails when a doc has no entry or an entry names no doc, and says what to add.
// constexpr string_views (no dynamic initialisation: manifest() may be read by any static initialiser); aud() builds the vector.
constexpr std::string_view kGameAi = "gameAi";        // the AI making a game
constexpr std::string_view kUser = "user";            // the person using the engine
constexpr std::string_view kEngineDev = "engineDev";  // working on the engine itself

std::vector<std::string> aud(std::initializer_list<std::string_view> audiences) {
    std::vector<std::string> out;
    for (std::string_view a : audiences) out.emplace_back(a);
    return out;
}

const std::vector<DocManifestEntry>& manifest() {
    static const std::vector<DocManifestEntry> m = {
        {"ai-costs", "What making a game with an AI costs in tokens and money, and how to spend less.",
         aud({kUser, kGameAi})},
        {"ai-guide", "How to build a game: the loop, project layout, recipes by genre. Read its Index, then sections.",
         aud({kGameAi})},
        {"ai-guide-tools",
         "AI guide pages: MCP tools and CLI, skills, units, scene and prefab files, components (sections 4 to 7).",
         aud({kGameAi})},
        {"ai-guide-scripts",
         "AI guide pages: the JavaScript API; recipes 9.1 to 9.7 (platformer, top-down, HUD, camera, sounds).",
         aud({kGameAi})},
        {"ai-guide-tilemaps", "AI guide pages: recipe 9.8, tilemap levels, objects and tile collision.",
         aud({kGameAi})},
        {"ai-guide-recipes-world",
         "AI guide pages: recipes 9.9 to 9.21 (3D scene, save data, levels, particles, patrol AI, 3D cameras, glow, "
         "sweeps).",
         aud({kGameAi})},
        {"ai-guide-recipes-ui-assets",
         "AI guide pages: recipes 9.22 to 9.25 (menus, art and sound pipeline, game menus, animated characters, "
         "analytics).",
         aud({kGameAi})},
        {"ai-guide-recipes-production",
         "AI guide pages: recipes 9.26 to 9.32 (2D production, enemy AI, multiplayer, split screen, game feel).",
         aud({kGameAi})},
        {"ai-guide-checks",
         "AI guide pages: tests, debugging and replays, common mistakes, performance, where to read more (sections 10 "
         "to 14).",
         aud({kGameAi})},
        {"ai-providers", "Connect an AI to FactorIA: MCP clients, API keys, the built-in assistant and its providers.",
         aud({kUser})},
        {"ai-providers-config", "AI providers: the config file, roles and reviews.", aud({kUser})},
        {"ai-providers-agent",
         "AI providers: how the built-in agent behaves, asset providers, permission mode, the AI settings window.",
         aud({kUser})},
        {"ai-providers-extensions", "AI providers: external MCP tools, token savers, the retrospective and extensions.",
         aud({kUser})},
        {"analytics", "Analytics events and remote config: send, read and test them from a game.", aud({kGameAi})},
        {"animation", "Skeletal and 2D clips, animator state machines and tweens.", aud({kGameAi})},
        {"animation-2d",
         "Animation pages: 2D clips (*.anim.json), sprite sheets, rigid parts, 2D bones, SpriteSkin and IK2D.",
         aud({kGameAi})},
        {"animation-3d", "Animation pages: 3D bone clips, 3D IK, generators, retargeting and previews.",
         aud({kGameAi})},
        {"animation-tweens", "Animation pages: tween() and ease, two worked examples, what is not there yet.",
         aud({kGameAi})},
        {"assets", "Generate, import and ship textures, models, sounds and other assets.", aud({kGameAi, kUser})},
        {"assets-generate", "Assets without a provider: house style, sounds, materials and SVG pictures.",
         aud({kGameAi, kUser})},
        {"assets-animate-svg", "assets.animate_svg: animations written as SVG code, baked into sprite sheets.",
         aud({kGameAi, kUser})},
        {"assets-review", "Checking and choosing assets: sheets, candidates, art checks, the icon and store capsules.",
         aud({kGameAi, kUser})},
        {"assets-import", "Import settings, importing files and the asset checks.", aud({kGameAi, kUser})},
        {"cli", "Every `factoria` command line verb and flag.", aud({kGameAi, kUser})},
        {"debugging", "Debug scripts: breakpoints, the script debugger and the VS Code extension.",
         aud({kGameAi, kUser})},
        {"editor", "The FactorIA editor: panels, shortcuts, play mode, autotest.", aud({kUser, kEngineDev})},
        {"editor-assistant", "Editor pages: the AI Assistant panel and the Sharing feedback window.",
         aud({kUser, kEngineDev})},
        {"editor-setup", "Editor pages: updates, exporting, Play on Phone, setting up the computer, platform settings.",
         aud({kUser, kEngineDev})},
        {"editor-review", "Editor pages: profiler, level generator, review window and play sessions.",
         aud({kUser, kEngineDev})},
        {"editor-panels", "Editor pages: the project, image, vector, sound and music panels.",
         aud({kUser, kEngineDev})},
        {"editor-animation", "Editor pages: the model, particles and animation panels and the bone tools.",
         aud({kUser, kEngineDev})},
        {"editor-testing", "Editor pages: testing the editor, the autotest sections and how to add a check.",
         aud({kUser, kEngineDev})},
        {"effects", "Visual and audio effects: the loop for making one, with three worked examples.", aud({kGameAi})},
        {"engine-feedback", "ENGINE_FEEDBACK.json: how to report engine gaps, efficiency feedback and triage.",
         aud({kGameAi, kEngineDev})},
        {"exporting", "Export a game for desktop, web, Android and iOS; CI for your game.", aud({kGameAi, kUser})},
        {"exporting-contents",
         "Exporting, part: what is shipped, replacing an export, license notices, AI disclosure, what each export "
         "needs.",
         aud({kGameAi, kUser})},
        {"exporting-setup",
         "Exporting, part: setting up this computer (factoria setup) and the platform settings of factoria.json.",
         aud({kGameAi, kUser})},
        {"exporting-desktop",
         "Exporting, part: Linux, Windows and macOS builds, release pack, signing, Steam, Epic, GOG, itch.io, MS "
         "Store.",
         aud({kGameAi, kUser})},
        {"exporting-web", "Exporting, part: the web build, serving it, one HTML file, hosting.", aud({kGameAi, kUser})},
        {"exporting-mobile", "Exporting, part: Android and iOS exports, prebuilt or from source.",
         aud({kGameAi, kUser})},
        {"exporting-stores", "Exporting, part: uploading to stores and the store page material.",
         aud({kGameAi, kUser})},
        {"extending", "Write project tools, native plugins and extend the engine itself.", aud({kGameAi, kEngineDev})},
        {"finishing", "From playable to ready for a store: polish, settings, accessibility, checks.",
         aud({kGameAi, kUser})},
        {"first-game-with-ai", "Tutorial for a person: make a first game by talking to an AI.", aud({kUser})},
        {"game-feel", "Shake, hit-stop, flash, knockback, squash and stretch.", aud({kGameAi})},
        {"getting-started", "Install FactorIA, create a project and run it.", aud({kUser})},
        {"hooks",
         "Hooks: programs or JS run when the AI calls a tool or engine command; they add context, refuse or change it.",
         aud({kGameAi, kUser})},
        {"images", "Layered images (*.image.json): layers, masks, palettes and drawing commands.", aud({kGameAi})},
        {"images-effects-commands", "Layered images: adjustments, effects, baking and the commands.", aud({kGameAi})},
        {"images-pixel-art", "Layered images: pixel art drawing and palettes.", aud({kGameAi})},
        {"images-frames-tiles", "Layered images: animation frames, tags and tiles.", aud({kGameAi})},
        {"legal", "Privacy policy and EULA templates for a game you ship.", aud({kUser, kGameAi})},
        {"localization", "Translate a game: string tables, languages, plurals and fonts.", aud({kGameAi})},
        {"make-by-hand", "Tutorial: make a small game by editing the files yourself, no AI.", aud({kUser})},
        {"mcp", "The MCP server: tools, resources, prompts and how to connect a client.",
         aud({kUser, kGameAi, kEngineDev})},
        {"menus", "Main menu, options, credits, loading screen and pause menu.", aud({kGameAi})},
        {"menus-how", "Menu kit pages: how the kit works and what to change in it.", aud({kGameAi})},
        {"menus-recipes", "Menu kit pages: save slots, anchors, widgets, tooltips, charts, a studio intro.",
         aud({kGameAi})},
        {"mobile", "Android and iOS: touch input, safe areas, export and device testing.", aud({kGameAi, kUser})},
        {"mobile-android", "Mobile, part: Android SDK, build, plugins, signing and release.", aud({kGameAi, kUser})},
        {"mobile-ios", "Mobile, part: iOS build, plugins, signing and TestFlight.", aud({kGameAi, kUser})},
        {"mobile-privacy", "Mobile, part: the store privacy forms (Data safety, App Store privacy).",
         aud({kGameAi, kUser})},
        {"mobile-device", "Mobile, part: touch input, phone features and the web build on a phone.",
         aud({kGameAi, kUser})},
        {"modeling", "3D models as data (*.model.json): parts, materials and commands.", aud({kGameAi})},
        {"modeling-shapes", "3D models: primitives, profile shapes, modifiers and sdf.", aud({kGameAi})},
        {"modeling-editing", "3D models: selections and edits, UVs, parts, materials and texturing.", aud({kGameAi})},
        {"modeling-game", "3D models: game-ready models, preview and check, cleaning an imported mesh.",
         aud({kGameAi})},
        {"music", "Music as data: song documents (*.song.json), stems and playback.", aud({kGameAi})},
        {"music-songs",
         "Music pages: the song document, notes, swing, instruments, the mixer, SoundFonts, layers and stems.",
         aud({kGameAi})},
        {"music-game",
         "Music pages: rendering a song for a game and the MusicPlayer component (live, stems, memory, hot reload).",
         aud({kGameAi})},
        {"music-commands",
         "Music pages: MIDI, helpers, commands, checks, worked examples, the Music panel, adaptive score, errors.",
         aud({kGameAi})},
        {"navigation", "Paths over 3D ground and tile maps: navmeshes and agents.", aud({kGameAi})},
        {"networking", "http.fetch: requests from scripts, limits and permissions.", aud({kGameAi})},
        {"particles", "Particle emitters: fields, presets and performance.", aud({kGameAi})},
        {"performance", "Performance budgets, profiling and the perf commands.", aud({kGameAi, kEngineDev})},
        {"performance-areas",
         "Performance, part: budgets by area (2D lights, path finding, startup, loading, scripts, background loading).",
         aud({kGameAi, kEngineDev})},
        {"performance-profiling", "Performance, part: the profiler and the job threads.", aud({kGameAi, kEngineDev})},
        {"performance-bench", "Performance, part: microbenchmarks (fa_bench).", aud({kGameAi, kEngineDev})},
        {"platform", "Store services: achievements, stats, leaderboards, cloud saves and purchases.", aud({kGameAi})},
        {"platform-api", "Store services, part: the script API and the fake store to test with.", aud({kGameAi})},
        {"platform-backends", "Store services, part: which backend runs, and writing a backend plugin.",
         aud({kGameAi})},
        {"platform-apple-google",
         "Store services, part: Apple (StoreKit 2, Game Center, iCloud) and Google Play (Billing, Play Games, Play "
         "Integrity).",
         aud({kGameAi})},
        {"platform-ads", "Store services, part: ads (AdMob) and consent on Android and iOS.", aud({kGameAi})},
        {"publishing", "One checklist per store: Steam, itch.io, Epic, Google Play, App Store.", aud({kUser, kGameAi})},
        {"rendering", "Cameras that draw into textures and photographs of the world.", aud({kGameAi})},
        {"rendering-decals-fog", "Rendering, part: Decal projection and the volumetric fog with light shafts (M73.5).",
         aud({kGameAi})},
        {"rendering-effects",
         "Screen-space effects: ambient occlusion, reflections and the outline, their fields, cost and limits.",
         aud({kGameAi})},
        {"rendering-light-probes",
         "Rendering, part: LightProbeGroup, baked light for moving objects, and light mode against receiver.",
         aud({kGameAi})},
        {"rendering-lightmaps", "Rendering, part: lightmaps, baking, light probes and mixed lights (M73.4).",
         aud({kGameAi})},
        {"rendering-lighting",
         "Rendering, part: the M73 lighting fields. Lightmaps, decals, probes: rendering-lightmaps, -decals-fog, "
         "-probes.",
         aud({kGameAi})},
        {"rendering-passes", "Rendering, part: the passes of a frame, when each runs and what it draws.",
         aud({kGameAi})},
        {"rendering-probes",
         "Rendering, part: reflection probes: realtime and baked captures, probe.bake, render.probes, the atlas.",
         aud({kGameAi})},
        {"rendering-transmission",
         "Rendering, part: glass and liquids (transmission, thickness, attenuation) and the material cost view.",
         aud({kGameAi})},
        {"rendering-screen-effects",
         "Rendering, part: shockwave, heat haze, radial blur pulse, flash and fade of the camera.", aud({kGameAi})},
        {"rigging", "Skeletons for 3D models (*.rig.json): bones, weights and poses.", aud({kGameAi})},
        {"scripting", "The JavaScript API: behaviours, entities, events, input, timers, modules.", aud({kGameAi})},
        {"scripting-world-input", "Scripting pages: the entity API, world, input, window, device presets and gamepads.",
         aud({kGameAi})},
        {"scripting-audio-world",
         "Scripting pages: audio, buses, physics, nav, behaviour trees, camera, tweens, tilemaps, particles.",
         aud({kGameAi})},
        {"scripting-ui-scenes",
         "Scripting pages: UI widgets, level generation, loading, scene, game and storage, the bot.", aud({kGameAi})},
        {"scripting-render-services",
         "Scripting pages: render textures, meshes, rng, math, platform, http, i18n, fa commands.", aud({kGameAi})},
        {"scripting-tests-tools", "Scripting pages: script tests, tools, hook modules and runtime notes.",
         aud({kGameAi})},
        {"shaders",
         "Custom shaders and materials: the template, uniforms, limits. Child pages: shaders-examples, -sprites, "
         "-lighting, "
         "-full, -post, -compute.",
         aud({kGameAi, kEngineDev})},
        {"shaders-compute",
         "Custom shaders, part: compute materials, their storage buffers and the compute.* commands.",
         aud({kGameAi, kEngineDev})},
        {"shaders-examples",
         "Custom shaders, part: nine worked examples of mesh materials, from a pulsing emission to a displacement.",
         aud({kGameAi, kEngineDev})},
        {"shaders-full",
         "Custom shaders, part: full shaders for mesh materials, your own vertex and fragment stages and passes.",
         aud({kGameAi, kEngineDev})},
        {"shaders-lighting",
         "Custom shaders, part: your own light loop (lighting()), the light functions and the sky light of custom "
         "lighting.",
         aud({kGameAi, kEngineDev})},
        {"shaders-post", "Custom shaders, part: post-process materials, the custom passes of a camera's post stack.",
         aud({kGameAi, kEngineDev})},
        {"shaders-sprites",
         "Custom shaders, part: materials on sprites, shapes, tiles, text and particles (kind sprite) and a worked "
         "example.",
         aud({kGameAi, kEngineDev})},
        {"skills", "Agent Skills: topic guides an AI loads when the work needs them.", aud({kGameAi, kUser})},
        {"sound", "Sound patches (*.sfx.json) and audio documents (*.audio.json).", aud({kGameAi})},
        {"sound-patches",
         "Sound pages: writing a *.sfx.json patch: layers, oscillators, envelopes, filters, effects, presets, macros.",
         aud({kGameAi})},
        {"sound-documents",
         "Sound pages: writing an *.audio.json document: steps, loops, its commands, baking and a worked example.",
         aud({kGameAi})},
        {"sound-spatial",
         "Sound pages: a sound at a place in the scene: rolloff, cones, Doppler, occlusion and headphones.",
         aud({kGameAi})},
        {"sound-mixer",
         "Sound pages: what happens when too many sounds play (voice stealing), the Sound panel, the audio callback.",
         aud({kGameAi})},
        {"text", "Fonts, languages and text size.", aud({kGameAi})},
        {"vector", "Vector illustration: the vector.* commands and SVG import.", aud({kGameAi})},
    };
    return m;
}

const DocManifestEntry* find_manifest(const std::string& name) {
    for (const DocManifestEntry& e : manifest())
        if (e.name == name) return &e;
    return nullptr;
}

// The menu kit (templates/menus/) is served from the embedded kit, not copied into docs/MENUS.md: "menu-kit" lists its
// files, "menu-kit/<path>" reads one.
constexpr std::string_view kMenuKitName = "menu-kit";
constexpr std::string_view kMenuKitRoot = "templates/menus/";

std::string menu_kit_listing() {
    std::vector<std::string> files = bundled_list(kMenuKitRoot);
    std::sort(files.begin(), files.end());
    std::string out =
        "# Menu kit files\n\n"
        "The files of the menu kit (`templates/menus/` in the FactorIA install): what `project.add_menu_kit` copies "
        "into a "
        "game, and what FactorIA's own tests run. Read one with `docs.read {\"name\":\"menu-kit/<file>\"}` (for "
        "example "
        "`menu-kit/scripts/settings.js`); `kit.json` says which files make each part. The recipes are in the `menus` "
        "page.\n\n| File | Bytes |\n|---|---|\n";
    for (const std::string& f : files) {
        auto text = bundled_read(f);
        out += "| `" + f.substr(kMenuKitRoot.size()) + "` | " + std::to_string(text ? text->size() : 0) + " |\n";
    }
    return out;
}

// The size of the whole kit: the sum of the bytes of its files (what docs.list says for the "menu-kit" entry).
long menu_kit_bytes() {
    long total = 0;
    for (const std::string& f : bundled_list(kMenuKitRoot))
        if (auto text = bundled_read(f)) total += long(text->size());
    return total;
}

Result<std::string> read_menu_kit(const std::string& q) {
    std::string rel = q.size() > kMenuKitName.size() ? q.substr(kMenuKitName.size() + 1) : std::string();
    if (rel.empty()) return menu_kit_listing();
    if (auto t = bundled_read(std::string(kMenuKitRoot) + rel)) {
        if (t->find('\0') != std::string::npos)
            return make_error(
                "The menu kit file '" + rel + "' is binary (it contains NUL bytes), not text.",
                "docs.read serves text files only; `docs.read {\"name\":\"menu-kit\"}` lists the kit with the "
                "size of each file.");
        return *t;
    }
    std::vector<std::string> names;
    for (const std::string& f : bundled_list(kMenuKitRoot)) names.push_back(f.substr(kMenuKitRoot.size()));
    return make_error("The menu kit has no file '" + rel + "'. " + did_you_mean(rel, names),
                      "docs.read {\"name\":\"menu-kit\"} lists the files of the kit.");
}

bool is_menu_kit_name(const std::string& q) {
    return q == kMenuKitName || (q.size() > kMenuKitName.size() &&
                                 q.compare(0, kMenuKitName.size(), kMenuKitName) == 0 && q[kMenuKitName.size()] == '/');
}

std::vector<DocInfo> scan_docs(const std::vector<std::string>& files) {
    std::vector<DocInfo> out;
    std::vector<std::string> mds;
    for (const auto& p : files)
        if (ends_with(p, ".md")) mds.push_back(p);
    for (const auto& p : mds) {
        auto text = doc_file_read(p);
        if (!text) continue;
        DocInfo d{doc_name_from_path(p), p, first_heading(*text), text->size(), {}, {}, {}};
        if (is_layout_path(p)) {
            const std::string entry = entry_path_of(p, mds);
            if (!entry.empty()) d.family = doc_name_from_path(entry);
        }
        if (const DocManifestEntry* e = find_manifest(d.name)) {
            d.summary = e->summary;
            d.audience = e->audience;
        }
        out.push_back(std::move(d));
    }
    return out;
}

struct DocCache {
    bool valid = false;
    std::vector<std::string> files;
    std::vector<DocInfo> docs;
};
DocCache g_docCache;
std::mutex g_docCacheMutex;

}  // namespace

const std::vector<DocManifestEntry>& doc_manifest() { return manifest(); }

void set_doc_files_for_tests(const DocFiles* files) {
    std::lock_guard<std::mutex> lock(g_docCacheMutex);
    g_docFiles = files;
    g_docCache.valid = false;
}

std::vector<DocInfo> list_docs() {
    // Reading every embedded doc to get its title and size is done once, while the list of files stays the same (the
    // embedded files never change; a test's source is replaced through set_doc_files_for_tests).
    std::vector<std::string> files = doc_files_list();
    {
        std::lock_guard<std::mutex> lock(g_docCacheMutex);
        if (g_docCache.valid && g_docCache.files == files) return g_docCache.docs;
    }
    std::vector<DocInfo> out = scan_docs(files);
    std::lock_guard<std::mutex> lock(g_docCacheMutex);
    g_docCache = {true, std::move(files), out};
    return out;
}

std::vector<DocInfo> doc_family_pages(std::string_view entryName) {
    std::vector<DocInfo> out;
    for (DocInfo& d : list_docs())
        if (d.family == entryName) out.push_back(std::move(d));
    std::sort(out.begin(), out.end(), [](const DocInfo& a, const DocInfo& b) { return a.path < b.path; });
    return out;
}

std::vector<std::string> doc_layout_problems() {
    // The same rules whether the docs come from the binary or from the repository: docs/design/ is not embedded, so its
    // names are not checked for uniqueness there, but its families are checked for links in both.
    std::vector<std::string> problems;
    const std::vector<DocInfo> docs = list_docs();
    std::vector<std::string> mds;
    std::map<std::string, std::string> byName;
    for (const DocInfo& d : docs) {
        if (!is_layout_path(d.path)) continue;
        mds.push_back(d.path);
        if (d.path.rfind("docs/design/", 0) == 0) continue;
        auto [it, fresh] = byName.emplace(d.name, d.path);
        if (!fresh)
            problems.push_back(
                "Two docs are named '" + d.name + "': " + it->second + " and " + d.path +
                ". The name is the file name without the folder, lower case, '_' as '-': prefix a page's "
                "file name with its doc's name (docs/scripting/SCRIPTING_INPUT.md).");
    }
    for (const std::string& p : mds) {
        const std::string dir = dir_of(p);
        if (dir.empty() || dir == "docs" || dir == "docs/design") continue;
        const std::string entry = entry_path_of(p, mds);
        if (entry.empty()) {
            problems.push_back(p + " sits in the folder " + dir + " but there is no entry page " + dir_of(dir) + "/" +
                               upper_of(base_of(dir)) +
                               ".md for it. A page lives in docs/<name>/ next to its entry page "
                               "docs/<NAME>.md; move it or add the entry page.");
            continue;
        }
        const std::string entryStem = base_of(entry).substr(0, base_of(entry).size() - 3);
        if (base_of(p).rfind(entryStem + "_", 0) != 0)
            problems.push_back(p + " must be named " + entryStem +
                               "_<PART>.md: the file name starts with its entry "
                               "page's (" +
                               entry + "), so the embedded name is unique.");
        // A real Markdown link: `](folder/FILE.md` followed by `)` or `#`, not the path in some other text.
        const std::string entryText = doc_file_read(entry).value_or("");
        const std::string link = base_of(dir) + "/" + base_of(p);
        bool linked = false;
        for (size_t pos = entryText.find("](" + link); pos != std::string::npos && !linked;
             pos = entryText.find("](" + link, pos + 1)) {
            const size_t after = pos + 2 + link.size();
            linked = after < entryText.size() && (entryText[after] == ')' || entryText[after] == '#');
        }
        if (!linked)
            problems.push_back(entry + " does not link to its page " + p +
                               ". Add a line to its index of pages with a Markdown link to the relative path, "
                               "`[Title](" +
                               link + ")`, and what the page covers.");
    }
    return problems;
}

Result<std::string> read_doc(std::string_view nameOrPath) {
    std::string q(trim(nameOrPath));
    if (q.rfind("factoria://docs/", 0) == 0) q = q.substr(16);
    if (q.rfind("docs/", 0) == 0 || q.rfind("schemas/", 0) == 0) {
        if (auto t = doc_file_read(q)) return *t;
    }
    if (is_menu_kit_name(q)) return read_menu_kit(q);
    std::string want = doc_name_from_path(q);
    if (want == "components" || want == "commands")
        return make_error(
            "There is no '" + want +
                "' page to read: the whole reference (components, fields, commands and the scripting "
                "API) is 1.8 MB, so it is served in pieces and not embedded as a page.",
            want == "components"
                ? "docs.components {\"name\":\"Sprite\"} reads one component (or {\"filter\":\"physics\"}; with no "
                  "argument it lists the names and pages with a cursor). The scripting API is in the `scripting` page "
                  "and "
                  "`factoria api --md`; the commands are docs.commands."
                : "docs.commands {\"name\":\"scene.spawn\"} reads one command (or {\"filter\":\"scene\"}); with no "
                  "argument it lists the names and pages with a cursor.");
    std::vector<std::string> names;
    for (const auto& d : list_docs()) {
        if (d.name == want) {
            if (auto t = doc_file_read(d.path)) return *t;
        }
        names.push_back(d.name);
    }
    if (want == "licenses" || want == "license" || want == "notices" || want == "third-party-notices")
        return third_party_notices(NoticeScope::All);
    if (want == "schemas" || want == "schema") {
        std::string all;
        for (const auto& p : bundled_list("schemas/"))
            all += "## " + p + "\n\n```json\n" + bundled_read(p).value_or("") + "\n```\n\n";
        return all;
    }
    names.push_back("licenses");
    return make_error("No document named '" + q + "'. " + did_you_mean(want, names),
                      "Use docs.list to see all documents.");
}

std::vector<DocHit> search_docs(std::string_view query, std::size_t maxResults) {
    std::vector<std::string> terms;
    for (const auto& t : split(to_lower(query), ' ')) terms.push_back(t);
    std::vector<DocHit> hits;
    if (terms.empty()) return hits;
    for (const auto& d : list_docs()) {
        auto text = doc_file_read(d.path);
        if (!text) continue;
        auto lines = lines_of(*text);
        // Sections split at headings.
        size_t start = 0;
        std::string heading = d.title;
        auto flush = [&](size_t end) {
            double score = 0;
            int bestLine = -1;
            double bestLineScore = 0;
            std::string lowerHeading = to_lower(heading);
            for (const auto& t : terms)
                if (lowerHeading.find(t) != std::string::npos) score += 6;
            if (to_lower(d.name).find(to_lower(terms[0])) != std::string::npos) score += 1;
            size_t termsMatched = 0;
            std::vector<bool> matched(terms.size(), false);
            for (size_t i = start; i < end; ++i) {
                std::string l = to_lower(lines[i]);
                double ls = 0;
                for (size_t k = 0; k < terms.size(); ++k) {
                    size_t pos = 0, n = 0;
                    while ((pos = l.find(terms[k], pos)) != std::string::npos) {
                        ++n;
                        pos += terms[k].size();
                    }
                    if (n) {
                        ls += 1 + 0.25 * double(n - 1);
                        matched[k] = true;
                    }
                }
                score += ls;
                if (ls > bestLineScore) {
                    bestLineScore = ls;
                    bestLine = int(i);
                }
            }
            for (bool m : matched) termsMatched += m;
            if (bestLine < 0 || termsMatched == 0) return;
            score *= 1.0 + double(termsMatched) / double(terms.size());  // reward covering all terms
            DocHit h;
            h.doc = d.name;
            h.family = d.family;
            h.path = d.path;
            h.heading = heading;
            h.line = bestLine + 1;
            h.score = score;
            size_t from = size_t(std::max<int>(int(start), bestLine - 1));
            size_t to = std::min(end, size_t(bestLine) + 4);
            std::string snip;
            for (size_t i = from; i < to; ++i) snip += lines[i] + "\n";
            if (snip.size() > 500) snip = snip.substr(0, 500) + "...";
            h.snippet = std::move(snip);
            hits.push_back(std::move(h));
        };
        bool inFence = false;
        for (size_t i = 0; i < lines.size(); ++i) {
            if (lines[i].rfind("```", 0) == 0) inFence = !inFence;
            if (!inFence && lines[i].rfind("#", 0) == 0 && i > start) {
                flush(i);
                start = i;
                heading = std::string(trim(lines[i].substr(lines[i].find_first_not_of('#'))));
            } else if (!inFence && lines[i].rfind("#", 0) == 0) {
                heading = std::string(trim(lines[i].substr(lines[i].find_first_not_of('#'))));
            }
        }
        flush(lines.size());
    }
    std::stable_sort(hits.begin(), hits.end(), [](const DocHit& a, const DocHit& b) { return a.score > b.score; });
    // Diverse top: each doc's best section first (by score), then every other section by score. Nothing is dropped; a
    // query for an API name no longer returns eight sections of one guide ahead of the reference. An explicit loop, not
    // std::stable_partition: libstdc++ copies the predicate, so a "seen" set inside it loses docs already counted.
    std::set<std::string> seen;
    std::vector<DocHit> ordered, rest;
    for (auto& h : hits) (seen.insert(h.doc).second ? ordered : rest).push_back(std::move(h));
    ordered.insert(ordered.end(), std::make_move_iterator(rest.begin()), std::make_move_iterator(rest.end()));
    if (ordered.size() > maxResults) ordered.resize(maxResults);
    return ordered;
}

void register_docs_commands(CommandRegistry& registry) {
    {
        CommandInfo info;
        info.name = "docs.list";
        info.category = "docs";
        info.summary = "List the engine documentation available offline.";
        info.description =
            "Start here. Returns {docs:[{name, title, summary, audience[], path, bytes, family?}]}: `family` is only "
            "on a "
            "page of a big doc that is split (the name of its entry page: read the entry page first, it indexes its "
            "pages); `summary` is one sentence "
            "on what the "
            "page is for, `audience` says who it is for (gameAi: the AI making a game, user: the person using the "
            "engine, "
            "engineDev: working on the engine itself), `bytes` its size. Pick by summary and read only what the task "
            "needs "
            "with docs.read (by `heading`). The document 'ai-guide' explains how to build games with FactorIA. "
            "Example: {\"audience\":\"gameAi\"}.";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"properties",
              Json::object(
                  {{"audience",
                    Json::object(
                        {{"type", "string"},
                         {"enum", Json::array({"gameAi", "user", "engineDev"})},
                         {"description",
                          "Only the docs for this audience (a doc can have several). Default: all docs."}})}})}});
        registry.add(info, [](const Json& args) {
            const std::string audience = tooling_detail::arg_string(args, "audience", false);
            if (!audience.empty() && audience != "gameAi" && audience != "user" && audience != "engineDev")
                throw CommandError("invalid_argument",
                                   "Unknown audience '" + audience + "'. " +
                                       did_you_mean(audience, std::vector<std::string>{"gameAi", "user", "engineDev"}),
                                   "Use gameAi, user or engineDev, or leave audience out for all docs.");
            auto wanted = [&](const std::vector<std::string>& a) {
                return audience.empty() || std::find(a.begin(), a.end(), audience) != a.end();
            };
            Json arr = Json::array();
            for (const auto& d : list_docs()) {
                if (!wanted(d.audience)) continue;
                Json aud = Json::array();
                for (const std::string& a : d.audience) aud.push_back(a);
                Json entry = Json::object({{"name", d.name},
                                           {"title", d.title},
                                           {"summary", d.summary},
                                           {"audience", aud},
                                           {"path", d.path},
                                           {"bytes", d.bytes}});
                if (!d.family.empty()) entry["family"] = d.family;
                arr.push_back(std::move(entry));
            }
            if (wanted({"gameAi"}))
                arr.push_back(Json::object(
                    {{"name", std::string(kMenuKitName)},
                     {"title", "The files of the menu kit (templates/menus/)"},
                     {"summary",
                      "The files of the menu kit, one by one: read `menu-kit/<file>`; this name lists them."},
                     {"audience", Json::array({"gameAi"})},
                     {"path", std::string(kMenuKitRoot)},
                     {"bytes", menu_kit_bytes()}}));
            if (wanted({"user", "engineDev"}))
                arr.push_back(Json::object(
                    {{"name", "licenses"},
                     {"title", "License notices: FactorIA and the third-party code inside it (generated)"},
                     {"summary", "License notices of FactorIA and the third-party code inside it (generated)."},
                     {"audience", Json::array({"user", "engineDev"})},
                     {"path", ""},
                     {"bytes", 0}}));
            return Json::object({{"docs", arr}});
        });
    }
    {
        CommandInfo info;
        info.name = "docs.read";
        info.category = "docs";
        info.summary = "Read a documentation page (Markdown), a section or a line range; long pages come in parts.";
        info.description =
            "Example: {\"name\":\"scripting\"}. A result is at most `maxBytes` (default 40000, about 10k tokens; an "
            "MCP client refuses "
            "much more), so a long page is cut and the result then carries `contents` (the headings with their line "
            "numbers) and "
            "`next`, the exact call that continues. Read one section by heading: "
            "{\"name\":\"ai-guide\",\"heading\":\"Platformer character\"} "
            "(case-insensitive; an exact title wins, else a part of a title; several matches list them), or a range "
            "with "
            "startLine/maxLines. Names: see docs.list (e.g. ai-guide, scripting, licenses). The menu kit's files are "
            "`menu-kit/<file>` (the name \"menu-kit\" lists them). The component and command references are not pages: "
            "use docs.components and docs.commands. "
            "To find where something is, docs.search returns sections with their line numbers. A big doc is split: its "
            "entry page (the name you know) indexes its pages, and a read of it without `heading` carries `pages` "
            "([{name,title,bytes,path}]; a cut read lists them in `contents` too). A `heading` that is not in the "
            "entry "
            "page but is a heading of one of its pages is served from that page: the result then has `page` (its name; "
            "`name` is the page too, so `next` continues there), `requestedName` and a `note`. A heading on two pages "
            "is "
            "an error that lists both; read the page by name.";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"properties",
              Json::object(
                  {{"name",
                    Json::object({{"type", "string"},
                                  {"description", "Doc name (\"scripting\") or path (\"docs/SCRIPTING.md\")."}})},
                   {"heading",
                    Json::object({{"type", "string"},
                                  {"description", "Read only the section with this heading (and its subsections), e.g. "
                                                  "\"Pause menu\". See `contents` of a cut read."}})},
                   {"startLine",
                    Json::object({{"type", "integer"},
                                  {"minimum", 1},
                                  {"description", "First line to return (1-based, default 1). With `heading`: the line "
                                                  "to continue a long section from."}})},
                   {"maxLines", Json::object({{"type", "integer"},
                                              {"minimum", 1},
                                              {"default", 2000},
                                              {"description", "Maximum number of lines."}})},
                   {"maxBytes",
                    Json::object({{"type", "integer"},
                                  {"minimum", 1000},
                                  {"maximum", kDocReadMaxBytes},
                                  {"default", kDocReadDefaultBytes},
                                  {"description",
                                   "Maximum size of `content` in bytes; the read stops at a line boundary."}})}})},
             {"required", Json::array({"name"})}});
        registry.add(info, [](const Json& args) {
            const std::string name = tooling_detail::arg_string(args, "name", true);
            auto text = read_doc(name);
            if (!text.ok()) throw CommandError("not_found", text.error().message, text.error().hint);
            std::vector<std::string> lines = lines_of(*text);
            long total = long(lines.size());
            std::vector<DocHeading> heads = headings_of(lines);
            const std::string familyName = is_menu_kit_name(name) ? std::string() : doc_name_from_path(name);
            std::string servedName = name;  // the doc the content comes from: a page when the heading lives on one
            std::string pageNote;
            std::vector<std::string> alsoOn;  // pages with the same exact title as the entry page's section
            long start = std::max<long>(1, tooling_detail::arg_int(args, "startLine", 1));
            long end = total;  // last line (1-based) the read may reach
            const std::string wanted = tooling_detail::arg_string(args, "heading", false);
            std::string sectionTitle;
            if (!wanted.empty()) {
                const std::string w = to_lower(std::string(trim(wanted)));
                // The headings of `hs` that match: an exact title wins, else a part of a title.
                struct Match {
                    std::vector<const DocHeading*> found;
                    bool exact = false;
                };
                auto match_in = [&](const std::vector<DocHeading>& hs) {
                    Match m;
                    std::vector<const DocHeading*> partial;
                    for (const DocHeading& h : hs) {
                        const std::string t = to_lower(h.title);
                        if (t == w)
                            m.found.push_back(&h);
                        else if (t.find(w) != std::string::npos)
                            partial.push_back(&h);
                    }
                    m.exact = !m.found.empty();
                    if (!m.exact) m.found = std::move(partial);
                    return m;
                };
                Match m = match_in(heads);
                // Not in this doc: a section of a doc that was split into pages lives on one of them, so an old
                // reference ("docs/SCRIPTING.md, \"Input\"") keeps working.
                struct PageText {
                    DocInfo info;
                    std::vector<std::string> lines;
                    std::vector<DocHeading> heads;
                    Match m;
                };
                std::vector<PageText> pages;  // the family's pages with a match
                std::vector<std::string> familyTitles;
                for (const DocHeading& h : heads) familyTitles.push_back(h.title);
                if (!familyName.empty()) {
                    for (DocInfo& info : doc_family_pages(familyName)) {
                        auto pageText = doc_file_read(info.path);
                        if (!pageText) continue;
                        PageText pt{std::move(info), lines_of(*pageText), {}, {}};
                        pt.heads = headings_of(pt.lines);
                        pt.m = match_in(pt.heads);
                        for (const DocHeading& h : pt.heads) familyTitles.push_back(h.title);
                        if (!pt.m.found.empty()) pages.push_back(std::move(pt));
                    }
                }
                std::vector<PageText*> exactPages;
                for (PageText& p : pages)
                    if (p.m.exact) exactPages.push_back(&p);
                // Where the section is: an exact title on the entry page wins (and says which pages have a longer
                // version); else an exact title on exactly one page; else the only place with a partial match. Two
                // or more candidates are an error that lists the entry page and the pages.
                PageText* chosen = nullptr;  // nullptr: the entry page
                std::vector<PageText*> candidates;
                if (m.exact) {
                    for (PageText* p : exactPages) alsoOn.push_back(p->info.name);
                } else if (!exactPages.empty()) {
                    candidates = exactPages;
                    if (exactPages.size() == 1) chosen = exactPages.front();
                } else {
                    for (PageText& p : pages) candidates.push_back(&p);
                    if (candidates.size() == 1 && m.found.empty()) chosen = candidates.front();
                }
                if (m.found.empty() && pages.empty())
                    throw CommandError("not_found",
                                       "Doc '" + name + "' has no heading matching '" + wanted + "'. " +
                                           did_you_mean(wanted, familyTitles),
                                       "Read the page without `heading` to get its contents (headings with line "
                                       "numbers), or docs.search {\"query\":\"...\"}.");
                const size_t places = candidates.size() + (!m.exact && !m.found.empty() ? 1 : 0);
                if (!chosen && !m.exact && places > 1) {
                    std::string list;
                    if (!m.found.empty())
                        list += "\n  - the entry page `" + name + "`: \"" + m.found.front()->title + "\" (line " +
                                std::to_string(m.found.front()->line) + ")";
                    for (const PageText* p : candidates)
                        list += "\n  - page `" + p->info.name + "`: \"" + p->m.found.front()->title + "\" (line " +
                                std::to_string(p->m.found.front()->line) + ")";
                    throw CommandError("invalid_argument",
                                       "'" + wanted + "' matches headings on " + std::to_string(places) +
                                           " pages of '" + name + "':" + list,
                                       "Read it from the page you mean: docs.read {\"name\":\"<page>\",\"heading\":"
                                       "\"<full title>\"}.");
                }
                if (chosen) {
                    servedName = chosen->info.name;
                    pageNote = "this section is on page `" + servedName + "`";
                    lines = std::move(chosen->lines);
                    heads = std::move(chosen->heads);
                    total = long(lines.size());
                    end = total;
                    m = std::move(chosen->m);
                }
                const std::vector<const DocHeading*>& found = m.found;
                if (found.size() > 1 && !m.exact) {
                    std::string list;
                    for (size_t i = 0; i < found.size() && i < 12; ++i)
                        list += "\n  - \"" + found[i]->title + "\" (line " + std::to_string(found[i]->line) + ")";
                    throw CommandError("invalid_argument",
                                       "'" + wanted + "' matches " + std::to_string(found.size()) + " headings of '" +
                                           servedName + "':" + list,
                                       "Repeat the call with the full title of one of them, or with startLine.");
                }
                const DocHeading* h = found.front();
                sectionTitle = h->title;
                long sectionEnd = total;
                for (const DocHeading& n : heads)
                    if (n.line > h->line && n.level <= h->level) {
                        sectionEnd = long(n.line) - 1;
                        break;
                    }
                if (!args.contains("startLine")) start = long(h->line);
                end = sectionEnd;
            }
            const long maxLines = std::max<long>(1, tooling_detail::arg_int(args, "maxLines", 2000));
            const long maxBytes = std::clamp<long>(tooling_detail::arg_int(args, "maxBytes", kDocReadDefaultBytes),
                                                   1000, kDocReadMaxBytes);
            std::string out;
            long last = start - 1;  // last line included
            for (long i = start - 1; i < end && i - (start - 1) < maxLines; ++i) {
                const std::string& l = lines[size_t(i)];
                if (long(out.size() + l.size() + 1) > maxBytes) {
                    if (out.empty()) {  // one line longer than the budget: return its start
                        out = cut_utf8(l, size_t(maxBytes)) + "\n";
                        last = i + 1;
                    }
                    break;
                }
                out += l + "\n";
                last = i + 1;
            }
            const bool truncated = last < end;
            Json r = Json::object({{"name", servedName},
                                   {"content", out},
                                   {"startLine", start},
                                   {"endLine", last},
                                   {"totalLines", total},
                                   {"truncated", truncated}});
            if (!sectionTitle.empty()) r["heading"] = sectionTitle;
            if (!pageNote.empty()) {
                r["page"] = servedName;  // the section was found on this page of `name`'s family
                r["requestedName"] = name;
                r["note"] = pageNote + " (docs.read {\"name\":\"" + servedName + "\"}).";
            }
            if (!alsoOn.empty()) {
                Json also = Json::array();
                std::string names;
                for (const std::string& n : alsoOn) {
                    also.push_back(n);
                    names += std::string(names.empty() ? "`" : ", `") + n + "`";
                }
                r["alsoOnPages"] = also;
                r["note"] = "a longer version of this section is on page " + names + " (docs.read {\"name\":\"" +
                            alsoOn.front() + "\",\"heading\":\"" + sectionTitle + "\"}).";
            }
            // An entry page lists its pages (read it without `heading`: that is the read that needs a map).
            Json pagesJson = Json::array();
            std::string pagesText;
            if (wanted.empty() && !familyName.empty())
                for (const DocInfo& p : doc_family_pages(familyName)) {
                    pagesJson.push_back(
                        Json::object({{"name", p.name}, {"title", p.title}, {"bytes", p.bytes}, {"path", p.path}}));
                    pagesText += "- " + p.name + ": " + p.title + " (" + std::to_string(p.bytes) + " bytes)\n";
                }
            if (!pagesJson.empty()) r["pages"] = pagesJson;
            if (truncated) {
                {
                    r["nextStartLine"] = last + 1;
                    Json call = Json::object({{"name", servedName}, {"startLine", last + 1}});
                    if (!sectionTitle.empty()) call["heading"] = sectionTitle;
                    r["next"] = "docs.read " + call.dump() + " continues from line " + std::to_string(last + 1) +
                                " of " + std::to_string(total) + ".";
                }
                std::string contents = contents_text(heads, 8000);
                if (!pagesText.empty())
                    contents += "Pages of this doc (docs.read {\"name\":\"<page>\"}, or the same heading on `" + name +
                                "`):\n" + pagesText;
                r["contents"] = contents;
                r["readSection"] = "docs.read {\"name\":\"" + servedName +
                                   "\",\"heading\":\"<a heading of `contents`>\"} reads one section; "
                                   "startLine/maxLines read a range of the lines numbered in `contents`.";
            }
            return r;
        });
    }
    {
        CommandInfo info;
        info.name = "docs.search";
        info.category = "docs";
        info.summary = "Search the documentation by keywords.";
        info.description = "Case-insensitive; every word counts, headings weigh more. Returns best sections with a "
                           "snippet; `doc` names "
                           "the page that holds it (`family` too when that is a page of a split doc: read it with "
                           "docs.read {name:doc}). "
                           "Example: {\"query\":\"input actions\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"properties", Json::object({{"query", Json::object({{"type", "string"}, {"description", "Keywords."}})},
                                          {"limit", Json::object({{"type", "integer"},
                                                                  {"minimum", 1},
                                                                  {"maximum", 50},
                                                                  {"default", 8},
                                                                  {"description", "Max results."}})}})},
             {"required", Json::array({"query"})}});
        registry.add(info, [](const Json& args) {
            auto hits = search_docs(tooling_detail::arg_string(args, "query", true),
                                    size_t(tooling_detail::arg_int(args, "limit", 8)));
            Json arr = Json::array();
            for (const auto& h : hits) {
                Json hit = Json::object({{"doc", h.doc},
                                         {"heading", h.heading},
                                         {"line", h.line},
                                         {"score", std::round(h.score * 100) / 100},
                                         {"snippet", h.snippet}});
                if (!h.family.empty()) hit["family"] = h.family;  // `doc` is a page of this entry page's doc
                arr.push_back(std::move(hit));
            }
            return Json::object({{"count", arr.size()}, {"results", arr}});
        });
    }
    declare_command_capabilities(registry, {{"docs.list", capability_sets::reads()},
                                            {"docs.read", capability_sets::reads()},
                                            {"docs.search", capability_sets::reads()}});
}

}  // namespace fa
