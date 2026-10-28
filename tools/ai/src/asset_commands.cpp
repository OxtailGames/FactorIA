// The assets.* commands that generate assets and keep their provenance (docs/ASSETS.md, "Generating assets").
#include "asset_commands.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <set>

#include "fa/ai/assets.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/tooling/ai_disclosure.h"
#include "fa/tooling/palette.h"
#include "util.h"

namespace fa::ai {

namespace {

using namespace util;

struct Ctx {
    std::function<Result<AiConfig>()> load;
    std::function<std::string()> projectDir;
    ProviderRuntime runtime;
    const CancelFlag* cancel = nullptr;
};

[[noreturn]] void fail(const char* code, const Error& e) { throw CommandError(code, e.message, e.hint); }

// The asset helpers (fa::assets, fa::fs) work on the global project root: point it at the project of the call.
struct ProjectScope {
    std::filesystem::path previous = fs::project_root();
    bool changed;  // a call that already runs in that folder leaves the root alone
    explicit ProjectScope(const std::string& dir) : changed(std::filesystem::path(dir) != previous) {
        if (changed) fs::set_project_root(dir);
    }
    ~ProjectScope() {
        if (changed) fs::set_project_root(previous);
    }
};

void add_command(CommandRegistry& registry, const std::shared_ptr<Ctx>& ctx, const char* name, const char* summary,
                 const char* description, Json inputSchema, bool readOnly, std::function<Json(const Ctx&, const Json&)> handler) {
    CommandInfo info;
    info.name = name;
    info.summary = summary;
    info.description = description;
    info.inputSchema = std::move(inputSchema);
    info.readOnly = readOnly;
    info.category = "assets";
    registry.add(std::move(info), [ctx, handler = std::move(handler)](const Json& args) -> Json {
        const std::string dir = ctx->projectDir();
        if (dir.empty()) {
            throw CommandError("no_project", "There is no project folder to put the asset in",
                               "Run from a project folder (the one with project.json) or pass --project to the factoria CLI.");
        }
        ProjectScope scope(dir);
        return handler(*ctx, args);
    });
}

// ---- Arguments ------------------------------------------------------------------------------------------------------

std::vector<std::string> string_list(const Json& args, const char* key) {
    std::vector<std::string> out;
    if (const Json* a = child(args, key); a && a->is_array()) {
        for (const Json& v : *a) {
            if (v.is_string()) out.push_back(v.get<std::string>());
        }
    }
    return out;
}

std::optional<i64> seed_arg(const Json& args) {
    const Json* seed = child(args, "seed");
    return seed && seed->is_number_integer() ? std::optional<i64>(seed->get<i64>()) : std::nullopt;
}

// A seed that the provider did not take is said, not hidden.
void warn_ignored_seed(std::vector<std::string>& warnings, const AssetRequest& request, const AssetResult& made,
                       const ProviderConfig& provider) {
    if (request.seed && !made.seed) {
        warnings.push_back(std::format("The provider '{}' takes no seed; it was ignored.", provider.name));
    }
}

std::string required_text(const Json& args, const char* key) {
    std::string text = str(args, key);
    if (text.find_first_not_of(" \t\r\n") == std::string::npos) {
        throw CommandError("invalid_argument", std::format("'{}' is empty", key), std::format("Say in `{}` what to make.", key));
    }
    return text;
}

// The project-relative, normalized path of the file to write; it must be under assets/.
std::string asset_path(const Json& args) {
    const std::string raw = str(args, "path");
    auto n = fs::normalize_checked(raw);
    if (!n) fail("invalid_path", n.error());
    const std::string& p = n.value();
    if (fs::is_absolute(raw) || p.rfind("assets/", 0) != 0 || p.back() == '/') {
        const std::string name = fs::filename(p).empty() ? "file.png" : fs::filename(p);
        throw CommandError("invalid_path", std::format("'{}' is not a file under assets/", raw),
                           std::format("Assets live under assets/ in the project, for example 'assets/{}'.", name));
    }
    return p;
}

void require_extension(const std::string& path, const std::string& wanted, const std::string& why) {
    const std::string ext = fs::extension(path);
    if (ext == wanted) return;
    throw CommandError("wrong_extension",
                       std::format("'{}' {}, but {}", path, ext.empty() ? "has no extension" : "ends in '" + ext + "'", why),
                       std::format("Use '{}/{}{}'.", fs::parent(path), fs::stem(path), wanted));
}

void require_free(const std::string& path, bool overwrite) {
    if (!overwrite && fs::exists(path)) {
        throw CommandError("exists", std::format("'{}' already exists", path),
                           "Pass overwrite:true to replace it (the old file is not kept), or choose another path.");
    }
}

// ---- Style ------------------------------------------------------------------------------------------------------------

// assets.json "style": the house style that keeps generated images consistent.
struct Style {
    std::string prompt;
    std::vector<std::string> references;
    std::optional<Palette> palette;
};

Style load_style() {
    Style s;
    const Json manifest = assets::manifest();
    const Json* style = child(manifest, "style");
    if (!style || !style->is_object()) return s;
    s.prompt = str(*style, "prompt");
    s.references = string_list(*style, "references");
    if (const Json* spec = child(*style, "palette")) {
        auto palette = load_palette(*spec);
        if (!palette) {
            throw CommandError("invalid_style", "assets.json style.palette: " + palette.error().message,
                               (palette.error().hint.empty() ? "" : palette.error().hint + " ") +
                                   "Pass style:false to skip the house style for this call.");
        }
        s.palette = std::move(*palette);
    }
    return s;
}

// The reference paths as project-relative normalized paths, each once.
std::vector<std::string> unique_paths(const std::vector<std::string>& raw) {
    std::vector<std::string> out;
    for (const std::string& path : raw) {
        auto n = fs::normalize_checked(path);
        if (!n) fail("invalid_path", n.error());
        if (std::find(out.begin(), out.end(), *n) == out.end()) out.push_back(*n);
    }
    return out;
}

std::vector<ReferenceImage> load_references(const std::vector<std::string>& paths) {
    std::vector<ReferenceImage> out;
    for (const std::string& path : paths) {
        const std::string mediaType = image_media_type_for_path(path);
        if (mediaType.empty()) {
            throw CommandError("invalid_reference", std::format("Reference image '{}' is not a png, jpg, gif or webp file", path),
                               "References are project-relative paths of png, jpg or webp images.");
        }
        auto bytes = fs::read_bytes(path);
        if (!bytes) {
            throw CommandError("not_found", std::format("Reference image '{}' cannot be read: {}", path, bytes.error().message),
                               "References are project-relative paths of existing files, for example 'assets/hero.png'.");
        }
        out.push_back({fs::filename(path), mediaType, std::string(bytes->begin(), bytes->end())});
    }
    return out;
}

// ---- Provenance -------------------------------------------------------------------------------------------------------

Json generated_provenance(const Json& args, const ProviderConfig& provider, const AssetResult& made, MediaKind kind,
                          const std::string& prompt, const std::vector<std::string>& references, const std::string& notes) {
    Json p = Json::object({{"origin", "generated"}, {"ai", true}, {"kind", media_kind_name(kind)}, {"provider", provider.name}});
    if (!made.model.empty()) p["model"] = made.model;
    p["prompt"] = prompt;
    if (!references.empty()) p["references"] = references;
    if (made.seed) p["seed"] = *made.seed;
    if (const std::string license = asset_license(provider); !license.empty()) p["license"] = license;
    p["author"] = str(args, "author", "factoria");
    if (!notes.empty()) p["notes"] = notes;
    p["date"] = assets::today();
    return p;
}

// Stores the provenance (and the sheet layout) of a file that was just written. A new file replaces what the tools measured
// or sliced from the old one.
void record(const std::string& path, const Json& provenance, const Json& sheet = nullptr) {
    auto r = assets::update_entry(path, [&](Json& entry) {
        entry.erase("analysis");
        entry.erase("sheet");
        entry["provenance"] = provenance;
        if (sheet.is_object()) entry["sheet"] = sheet;
    });
    if (!r) {
        throw CommandError("manifest_failed",
                           std::format("'{}' was written, but its provenance could not be recorded: {}", path, r.error().message),
                           (r.error().hint.empty() ? "" : r.error().hint + " ") + "Then run assets.set_provenance for the file.");
    }
}

AiConfig load_ai_config(const Ctx& ctx) {
    auto cfg = ctx.load();
    if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
    return std::move(*cfg);
}

AssetTarget resolve_target(const Ctx& ctx, const AiConfig& cfg, const Json& args, MediaKind kind) {
    auto target = resolve_asset_target(cfg, kind, str(args, "provider"), str(args, "model"),
                                       kind == MediaKind::Voice ? str(args, "voice") : std::string(), ctx.runtime.env);
    if (!target) fail("no_provider", target.error());
    return std::move(*target);
}

// ---- Images -----------------------------------------------------------------------------------------------------------

struct ImageJob {
    std::string path, prompt;
    int width = 512, height = 512;
    int columns = 0, rows = 0;  // > 0: a sprite sheet of this grid
    bool transparent = false;
    Json sheet;                 // the "sheet" entry to record, or null
};

Json generate_image_file(const Ctx& ctx, const Json& args, const ImageJob& job) {
    require_extension(job.path, ".png", "generated images are written as PNG");
    require_free(job.path, flag(args, "overwrite"));
    const AiConfig cfg = load_ai_config(ctx);
    const AssetTarget target = resolve_target(ctx, cfg, args, MediaKind::Image);
    const Style style = flag(args, "style", true) ? load_style() : Style{};

    AssetRequest request;
    request.kind = MediaKind::Image;
    request.prompt = style.prompt.empty() ? job.prompt : job.prompt + "\n\nStyle: " + style.prompt;
    request.model = target.model;
    request.width = job.width;
    request.height = job.height;
    request.columns = job.columns;
    request.rows = job.rows;
    request.transparent = job.transparent;
    request.seed = seed_arg(args);
    std::vector<std::string> referencePaths = string_list(args, "references");
    referencePaths.insert(referencePaths.end(), style.references.begin(), style.references.end());
    referencePaths = unique_paths(referencePaths);
    request.references = load_references(referencePaths);

    auto made = generate_asset(*target.provider, request, ctx.runtime, ctx.cancel);
    if (!made) fail("generation_failed", made.error());

    auto decoded = decode_image(reinterpret_cast<const std::uint8_t*>(made->bytes.data()), made->bytes.size());
    if (!decoded) {
        throw CommandError("bad_output",
                           std::format("The provider '{}' returned data that is not an image: {}", target.provider->name, decoded.error().message),
                           "Check the provider and model with ai.providers (action doctor).");
    }
    Image image = std::move(*decoded);
    std::string notes;
    if (image.width != job.width || image.height != job.height) {
        notes = std::format("Resized from {}x{}.", image.width, image.height);
        image = resize_image(image, job.width, job.height);
    }
    if (style.palette) {
        image = quantize_to_palette(image, *style.palette);
        notes += std::format("{}Reduced to the {} colours of the style palette.", notes.empty() ? "" : " ", style.palette->size());
    }
    const std::vector<std::uint8_t> png = encode_png(image);
    if (auto w = fs::write_bytes(job.path, png.data(), png.size()); !w) fail("write_failed", w.error());

    std::vector<std::string> warnings;
    if (!request.references.empty() && !made->usedReferences) {
        warnings.push_back(std::format("The provider '{}' cannot take reference images, so the {} reference(s) were not sent (the style prompt was).",
                                       target.provider->name, request.references.size()));
    }
    warn_ignored_seed(warnings, request, *made, *target.provider);

    const Json provenance = generated_provenance(args, *target.provider, *made, MediaKind::Image, request.prompt,
                                                 made->usedReferences ? referencePaths : std::vector<std::string>(), notes);
    record(job.path, provenance, job.sheet);

    Json out = Json::object({{"path", job.path},
                             {"width", image.width},
                             {"height", image.height},
                             {"bytes", png.size()},
                             {"provenance", provenance}});
    if (!warnings.empty()) out["warnings"] = warnings;
    out["$image"] = Json::object({{"path", fs::resolve(job.path).string()}, {"mimeType", "image/png"}});
    return out;
}

Json generate_image(const Ctx& ctx, const Json& args) {
    ImageJob job;
    job.path = asset_path(args);
    job.prompt = required_text(args, "prompt");
    job.width = static_cast<int>(num(args, "width", 512));
    job.height = static_cast<int>(num(args, "height", 512));
    job.transparent = flag(args, "transparent");
    return generate_image_file(ctx, args, job);
}

Json generate_sprite_sheet(const Ctx& ctx, const Json& args) {
    ImageJob job;
    job.path = asset_path(args);
    const std::string prompt = required_text(args, "prompt");
    const int frames = static_cast<int>(num(args, "frames", 1));
    const int columns = static_cast<int>(num(args, "columns", std::ceil(std::sqrt(static_cast<double>(frames)))));
    const int rows = (frames + columns - 1) / columns;
    const int frameWidth = static_cast<int>(num(args, "frameWidth", 64));
    const int frameHeight = static_cast<int>(num(args, "frameHeight", 64));
    const double fps = num(args, "fps", 8);
    if (columns > frames) {
        throw CommandError("invalid_argument", std::format("columns ({}) is more than frames ({})", columns, frames),
                           "Use at most one column per frame, or leave columns out for a square-ish grid.");
    }
    if (columns * frameWidth > 4096 || rows * frameHeight > 4096) {
        throw CommandError("too_large",
                           std::format("{} columns of {} px by {} rows of {} px make a {}x{} sheet; the limit is 4096 px per side",
                                       columns, frameWidth, rows, frameHeight, columns * frameWidth, rows * frameHeight),
                           "Use smaller frames, fewer frames or more columns.");
    }
    job.width = columns * frameWidth;
    job.height = rows * frameHeight;
    job.columns = columns;
    job.rows = rows;
    job.transparent = flag(args, "transparent", true);
    job.prompt = std::format("{}\n\nLayout: a sprite sheet of {} animation frames in a grid of {} columns by {} rows, read left to right "
                             "and then top to bottom. Every frame has the same size and the subject sits in the same place in each "
                             "frame. No borders, labels or gaps between frames.",
                             prompt, frames, columns, rows);
    job.sheet = Json::object({{"columns", columns},
                              {"rows", rows},
                              {"frameWidth", frameWidth},
                              {"frameHeight", frameHeight},
                              {"frames", frames},
                              {"clips", Json::array({Json::object({{"name", "default"}, {"firstFrame", 0}, {"lastFrame", frames - 1}, {"fps", fps}})})}});
    Json out = generate_image_file(ctx, args, job);
    out["setup"] = Json::object({{"Sprite", Json::object({{"texture", job.path}})},
                                 {"SpriteAnimator", Json::object({{"columns", columns},
                                                                  {"rows", rows},
                                                                  {"firstFrame", 0},
                                                                  {"lastFrame", frames - 1},
                                                                  {"fps", fps}})}});
    out["next"] = "Give an entity the Sprite and SpriteAnimator components from `setup` (scene.spawn or scene.add_component); the "
                  "frames play from the first to the last. The layout is recorded in assets.json under this path.";
    return out;
}

// ---- Sounds, music, voice, 3D models ----------------------------------------------------------------------------------

// A mono 16-bit 22.05 kHz WAV of digital silence, `seconds` long.
std::string silent_wav(double seconds) {
    constexpr std::uint32_t rate = 22050;
    const std::uint32_t frames = static_cast<std::uint32_t>(std::llround(seconds * rate)), dataBytes = frames * 2;
    std::string out;
    const auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(static_cast<char>((v >> (8 * i)) & 0xFF)); };
    const auto u16 = [&](std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(static_cast<char>((v >> (8 * i)) & 0xFF)); };
    out += "RIFF"; u32(36 + dataBytes); out += "WAVEfmt "; u32(16); u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16);
    out += "data"; u32(dataBytes);
    out.append(dataBytes, '\0');
    return out;
}

// assets.generate_voice with silent:true: no provider, no key. Code that plays voice lines (captions that last as long as the
// clip, ducking, a validator that checks the file) is tested with a clip of the right length that makes no sound.
Json generate_silent_voice(const Json& args, const std::string& path, const std::string& text) {
    require_extension(path, ".wav", "a silent voice clip is a WAV file");
    require_free(path, flag(args, "overwrite"));
    // about 15 characters a second, like the fake provider's buzz: 0.4 to 20 s unless `seconds` says
    const double seconds = args.contains("seconds") ? num(args, "seconds", 0) : std::clamp(0.06 * static_cast<double>(text.size()), 0.4, 20.0);
    if (!(seconds >= 0.1 && seconds <= 60)) {
        throw CommandError("invalid_argument", "seconds must be from 0.1 to 60 for a silent clip", "Leave `seconds` out to get a length from the text.");
    }
    const std::string bytes = silent_wav(seconds);
    if (auto w = fs::write_bytes(path, bytes.data(), bytes.size()); !w) fail("write_failed", w.error());
    const Json provenance = Json::object({{"origin", "original"},
                                          {"ai", false},
                                          {"kind", "voice"},
                                          {"provider", "factoria silent placeholder"},
                                          {"prompt", text},
                                          {"license", "CC0-1.0"},
                                          {"author", str(args, "author", "factoria")},
                                          {"notes", "Digital silence of " + std::format("{:.2f}", seconds) + " s standing in for the spoken line; replace it with a real recording or assets.generate_voice before shipping."},
                                          {"date", assets::today()}});
    record(path, provenance);
    return Json::object({{"path", path},
                         {"bytes", bytes.size()},
                         {"kind", "voice"},
                         {"seconds", seconds},
                         {"silent", true},
                         {"provenance", provenance},
                         {"next", "Play it like any clip; run assets.generate_voice again without `silent` (and with overwrite:true) once a voice provider is configured."}});
}

Json generate_file(const Ctx& ctx, const Json& args, MediaKind kind) {
    const bool voice = kind == MediaKind::Voice;
    const std::string path = asset_path(args);
    const std::string prompt = required_text(args, voice ? "text" : "prompt");
    if (voice && flag(args, "silent")) return generate_silent_voice(args, path, prompt);
    const AiConfig cfg = load_ai_config(ctx);
    const AssetTarget target = resolve_target(ctx, cfg, args, kind);
    const std::string wanted = asset_extension(*target.provider, kind);
    require_extension(path, wanted,
                      std::format("the provider '{}' makes {} as {} files", target.provider->name, media_kind_name(kind), wanted));
    require_free(path, flag(args, "overwrite"));

    AssetRequest request;
    request.kind = kind;
    request.prompt = prompt;
    request.model = target.model;
    request.voice = target.voice;
    request.seconds = num(args, "seconds", 0);
    request.seed = seed_arg(args);

    auto made = generate_asset(*target.provider, request, ctx.runtime, ctx.cancel);
    if (!made) fail("generation_failed", made.error());
    const std::string got = sniff_extension(made->bytes);
    if (got != wanted) {
        throw CommandError("bad_output",
                           std::format("The provider '{}' returned {} data, not the {} file expected for {}", target.provider->name,
                                       got.empty() ? "unrecognised" : got, wanted, media_kind_name(kind)),
                           "Check the provider and model with ai.providers (action doctor).");
    }
    if (auto w = fs::write_bytes(path, made->bytes.data(), made->bytes.size()); !w) fail("write_failed", w.error());

    std::vector<std::string> warnings;
    warn_ignored_seed(warnings, request, *made, *target.provider);
    const Json provenance = generated_provenance(args, *target.provider, *made, kind, prompt, {},
                                                  voice && !made->voice.empty() ? "Voice: " + made->voice + "." : std::string());
    record(path, provenance);

    Json out = Json::object({{"path", path},
                             {"bytes", made->bytes.size()},
                             {"kind", media_kind_name(kind)},
                             {"provenance", provenance}});
    if (!warnings.empty()) out["warnings"] = warnings;
    out["next"] = kind == MediaKind::Model3d
                      ? "Use it as the `mesh` of a MeshRenderer component, then check the look with game.screenshot."
                      : "Use it as the `clip` of an AudioSource component, or play it with audio.play(path) from a script.";
    return out;
}

// ---- Provenance records and the disclosure ----------------------------------------------------------------------------

Json provenance_command(const Ctx&, const Json& args) {
    if (args.contains("path")) {
        const std::string path = asset_path(args);
        const Json entry = assets::entry(path);
        const Json* p = child(entry, "provenance");
        return Json::object({{"path", path}, {"exists", fs::exists(path)}, {"provenance", p ? *p : Json(nullptr)}});
    }
    const Json manifest = assets::manifest();
    Json list = Json::array();
    int ai = 0;
    if (const Json* all = child(manifest, "assets"); all && all->is_object()) {
        for (const auto& [path, entry] : all->items()) {
            const Json* p = child(entry, "provenance");
            if (!p) continue;
            if (flag(*p, "ai")) ++ai;
            list.push_back(Json::object({{"path", path}, {"fileExists", fs::exists(path)}, {"provenance", *p}}));
        }
    }
    const std::vector<std::string> missing = assets_without_provenance(manifest, fs::list("assets"));
    return Json::object({{"assets", list},
                         {"aiCount", ai},
                         {"withoutProvenance", missing},
                         {"summary", std::format("{} asset(s) with provenance, {} made with AI, {} file(s) under assets/ without a record.",
                                                 list.size(), ai, missing.size())}});
}

Json set_provenance(const Ctx&, const Json& args) {
    const std::string path = asset_path(args);
    if (!fs::exists(path)) {
        throw CommandError("not_found", std::format("'{}' does not exist", path),
                           "Create or import the file first: provenance describes a file that is in the project.");
    }
    const std::string origin = required_text(args, "origin");
    const bool ai = args.contains("ai") ? flag(args, "ai") : origin == "generated";
    if (origin == "generated" && !ai) {
        throw CommandError("invalid_argument", "origin \"generated\" means an AI made the asset, but ai is false",
                           "Use origin \"original\" (made by hand) or \"imported\" (brought in from a file) for assets AI did not make.");
    }
    Json p = Json::object({{"origin", origin}, {"ai", ai}, {"date", str(args, "date", assets::today())}});
    for (const char* key : {"kind", "provider", "model", "prompt", "license", "author", "source", "notes"}) {
        if (const std::string v = str(args, key); !v.empty()) p[key] = v;
    }
    if (const std::optional<i64> seed = seed_arg(args)) p["seed"] = *seed;
    if (std::vector<std::string> refs = string_list(args, "references"); !refs.empty()) p["references"] = refs;
    auto r = assets::update_entry(path, [&](Json& entry) { entry["provenance"] = p; });
    if (!r) fail("manifest_failed", r.error());
    return Json::object({{"path", path}, {"provenance", p}});
}

Json disclosure(const Ctx&, const Json&) {
    const Json manifest = assets::manifest();
    const std::vector<std::string> files = fs::list("assets");
    return Json::object({{"markdown", ai_content_disclosure(manifest, files)},
                         {"hasAiContent", has_ai_content(manifest)},
                         {"withoutProvenance", assets_without_provenance(manifest, files)},
                         {"next", "Answer the store's AI questions from `markdown`. `factoria export` writes the same text as "
                                  "AI_CONTENT_DISCLOSURE.md next to the game when any asset is made with AI."}});
}

// ---- Registration -----------------------------------------------------------------------------------------------------

// Properties every generate_* command takes (a JSON object body without braces).
const std::string kCommonProperties = R"J(
    "provider":{"type":"string","description":"Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example \"fake\" to try the flow offline)."},
    "model":{"type":"string","description":"Model to use instead of the one in ai.json. Empty: the provider's default."},
    "seed":{"type":"integer","description":"Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning."},
    "overwrite":{"type":"boolean","default":false,"description":"Replace the file when it already exists. The old file is not kept."},
    "author":{"type":"string","description":"Who gets the credit in the provenance record. Default: \"factoria\"."})J";

const std::string kImageProperties = R"J(
    "references":{"type":"array","items":{"type":"string"},"description":"Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json."},
    "style":{"type":"boolean","default":true,"description":"Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call."})J";

Json schema(const std::string& properties, const std::string& required) {
    return Json::parse(R"({"type":"object","properties":{)" + properties + R"(},"required":)" + required + R"(,"additionalProperties":false})");
}

}  // namespace

void register_asset_commands(CommandRegistry& registry, std::function<Result<AiConfig>()> load, std::function<std::string()> projectDir,
                             ProviderRuntime runtime, const CancelFlag* cancel) {
    auto ctx = std::make_shared<Ctx>(Ctx{std::move(load), std::move(projectDir), std::move(runtime), cancel});
    const std::string pathProperty = R"J("path":{"type":"string","description":"Where to write the file, project-relative, under assets/ (for example \"assets/sfx/jump.wav\"). The extension must match what the provider makes."},)J";

    add_command(
        registry, ctx, "assets.generate_image", "Generate a PNG image with the image asset provider and record where it came from.",
        "Calls the provider that ai.json assigns to \"image\" (assets.image; there is no default, so add one, or pass `provider` "
        "such as \"fake\" for an offline placeholder), writes a PNG of exactly width x height at `path` and records provenance "
        "(origin generated, ai true, provider, model, the full prompt, references, date, license note) in assets.json. The house "
        "style of assets.json is applied unless style is false: its `prompt` is appended to yours, its `references` are sent "
        "along with `references`, and its `palette` reduces the result to those colours. Returns the path, size, provenance and "
        "the image itself. Generation costs money with paid providers: check the first result before generating more. "
        "Example: {\"prompt\":\"a red potion bottle, side view\",\"path\":\"assets/items/potion.png\",\"width\":64,\"height\":64,\"transparent\":true}",
        schema(pathProperty +
                   R"J("prompt":{"type":"string","description":"What to draw. Describe the subject and the view; the house style is added for you."},
    "width":{"type":"integer","minimum":8,"maximum":4096,"default":512,"description":"Width of the PNG in pixels. The provider's picture is resized to it."},
    "height":{"type":"integer","minimum":8,"maximum":4096,"default":512,"description":"Height of the PNG in pixels."},
    "transparent":{"type":"boolean","default":false,"description":"Ask for a transparent background (sprites, items, icons)."},)J" +
                   kImageProperties + "," + kCommonProperties,
               R"(["prompt","path"])"),
        false, generate_image);
    add_command(
        registry, ctx, "assets.generate_sprite_sheet",
        "Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator.",
        "Like assets.generate_image, but the picture is a grid of `frames` animation frames of frameWidth x frameHeight, "
        "normalized to exactly columns * frameWidth by rows * frameHeight pixels (each side at most 4096). The layout is written "
        "to assets.json as the `sheet` of the file with one clip \"default\" (all frames, at `fps`), and the result shows the Sprite "
        "and SpriteAnimator components to use. Providers draw grids unevenly: look at the result and regenerate when frames "
        "wander. Example: {\"prompt\":\"a knight walking right\",\"path\":\"assets/knight_walk.png\",\"frames\":6,\"columns\":3,"
        "\"frameWidth\":64,\"frameHeight\":64,\"fps\":10}",
        schema(pathProperty +
                   R"J("prompt":{"type":"string","description":"What the animation shows: the subject and what it does over the frames."},
    "frames":{"type":"integer","minimum":1,"maximum":256,"description":"Number of animation frames."},
    "columns":{"type":"integer","minimum":1,"maximum":64,"description":"Frames per row. Default: the square root of frames, rounded up."},
    "frameWidth":{"type":"integer","minimum":8,"maximum":2048,"description":"Width of one frame in pixels."},
    "frameHeight":{"type":"integer","minimum":8,"maximum":2048,"description":"Height of one frame in pixels."},
    "fps":{"type":"number","minimum":0,"default":8,"description":"Frames per second of the \"default\" clip."},
    "transparent":{"type":"boolean","default":true,"description":"Ask for a transparent background (the usual choice for sprites)."},)J" +
                   kImageProperties + "," + kCommonProperties,
               R"(["prompt","path","frames","frameWidth","frameHeight"])"),
        false, generate_sprite_sheet);

    // sounds, music, voice and 3D models share one handler; only the kind and the properties differ
    const auto file_schema = [&](const std::string& properties, const char* required) {
        return schema(pathProperty + properties + kCommonProperties, required);
    };
    const auto file_handler = [](MediaKind kind) { return [kind](const Ctx& c, const Json& a) { return generate_file(c, a, kind); }; };
    add_command(
        registry, ctx, "assets.generate_sound", "Generate a sound effect with the sound asset provider and record where it came from.",
        "Calls the provider that ai.json assigns to \"sound\" (assets.sound) and writes the audio file at `path`, whose extension "
        "must be the one the provider makes (.mp3 for elevenlabs, .wav for fake and asset-command). Records provenance in "
        "assets.json. Example: {\"prompt\":\"short coin pickup chime\",\"path\":\"assets/sfx/coin.mp3\",\"seconds\":1}",
        file_schema(R"J("prompt":{"type":"string","description":"The sound to make, for example \"heavy wooden door slam\"."},
    "seconds":{"type":"number","minimum":0.5,"maximum":30,"description":"Length in seconds. Default: the provider chooses."},)J",
                    R"(["prompt","path"])"),
        false, file_handler(MediaKind::Sound));
    add_command(
        registry, ctx, "assets.generate_music", "Generate a music track with the music asset provider and record where it came from.",
        "Calls the provider that ai.json assigns to \"music\" (assets.music) and writes the audio file at `path` (extension as for "
        "assets.generate_sound). Tracks are instrumental. Records provenance in assets.json. Tracks are not looped for you: "
        "ask for a loopable piece in the prompt and set `loop` on the AudioSource. Example: {\"prompt\":\"calm forest theme, "
        "soft flute and strings\",\"path\":\"assets/music/forest.mp3\",\"seconds\":60}",
        file_schema(R"J("prompt":{"type":"string","description":"The music to make: mood, instruments, tempo."},
    "seconds":{"type":"number","minimum":3,"maximum":600,"description":"Length in seconds. Default: the provider chooses."},)J",
                    R"(["prompt","path"])"),
        false, file_handler(MediaKind::Music));
    add_command(
        registry, ctx, "assets.generate_voice", "Generate spoken audio from text with the voice asset provider and record where it came from.",
        "Calls the provider that ai.json assigns to \"voice\" (assets.voice) to speak `text` with `voice` (default: the voice in "
        "ai.json) and writes the audio file at `path`. Records provenance in assets.json (the text is the prompt). "
        "Needs a key in the environment: ELEVENLABS_API_KEY (elevenlabs) or OPENAI_API_KEY (openai); without a provider the error says "
        "what to add to ai.json. To test code that depends on voice lines without a provider or a key, pass `silent: true`: it writes a "
        "silent .wav as long as the line (about 0.06 s per character, or `seconds`) and records it as a placeholder, not AI. "
        "Example: {\"text\":\"Welcome, traveller.\",\"path\":\"assets/voice/welcome.mp3\"}",
        file_schema(R"J("text":{"type":"string","description":"The words to speak."},
    "silent":{"type":"boolean","default":false,"description":"Write a silent WAV of the line's length instead of calling a provider (no key needed). For tests of code that plays voice lines; `path` must end in .wav."},
    "seconds":{"type":"number","minimum":0.1,"maximum":60,"description":"With silent: the length of the clip. Default: about 0.06 s per character of `text`, from 0.4 to 20 s. Ignored by providers."},
    "voice":{"type":"string","description":"The provider's voice name or id (openai: alloy, verse...; elevenlabs: a voice id). Default: assets.voice.voice in ai.json."},)J",
                    R"(["text","path"])"),
        false, file_handler(MediaKind::Voice));
    add_command(
        registry, ctx, "assets.generate_model", "Generate a 3D model with the model3d asset provider and record where it came from.",
        "Calls the provider that ai.json assigns to \"model3d\" (assets.model3d) and writes the glTF binary at `path` (.glb; the "
        "fake provider makes a small .gltf cube). Generating models takes minutes with real providers. The model is not textured "
        "or rigged; check it in the scene before building on it. Records provenance in assets.json. "
        "Example: {\"prompt\":\"a low-poly wooden crate\",\"path\":\"assets/models/crate.glb\"}",
        file_schema(R"J("prompt":{"type":"string","description":"The object to make: shape, material, style."},)J", R"(["prompt","path"])"),
        false, file_handler(MediaKind::Model3d));

    add_command(
        registry, ctx, "assets.provenance", "Show where assets came from: the provenance record of one file, or all of them.",
        "With `path`, the provenance record of that file (null when it has none). Without, every record in assets.json, how many "
        "are AI-made, and the art, sound and model files under assets/ that have no record yet. Example: {\"path\":\"assets/hero.png\"}",
        Json::parse(R"({"type":"object","properties":{
            "path":{"type":"string","description":"Project-relative path under assets/. Omit to list every record."}},
            "additionalProperties":false})"),
        true, provenance_command);
    add_command(
        registry, ctx, "assets.set_provenance", "Record where an asset came from (hand-made, imported, or made with AI elsewhere).",
        "Replaces the provenance record of an existing file in assets.json. The generate commands write it for you; use this "
        "for files they did not make, so the AI disclosure is complete. `ai` says whether AI made the content (it defaults to "
        "true for origin generated, false otherwise). Example: {\"path\":\"assets/music/theme.ogg\",\"origin\":\"imported\","
        "\"ai\":false,\"license\":\"CC0\",\"source\":\"https://example.com/theme\",\"author\":\"A. Composer\"}",
        Json::parse(R"({"type":"object","properties":{
            "path":{"type":"string","description":"Project-relative path of an existing file under assets/."},
            "origin":{"type":"string","enum":["generated","imported","original"],"description":"generated: made by an asset provider. imported: brought in from a file made elsewhere. original: made by hand for this game."},
            "ai":{"type":"boolean","description":"Whether AI made the content. Default: true for origin generated, false otherwise."},
            "kind":{"type":"string","enum":["image","sound","music","voice","model3d"],"description":"What the asset is, so the disclosure can tell sound effects, music and voice apart."},
            "provider":{"type":"string","description":"Tool or provider that made it (\"openai\", \"suno\", \"Aseprite\"...)."},
            "model":{"type":"string","description":"Model that made it, for AI-made assets."},
            "prompt":{"type":"string","description":"The prompt it was made from, for AI-made assets."},
            "references":{"type":"array","items":{"type":"string"},"description":"Reference images used."},
            "seed":{"type":"integer","description":"Seed, when there was one."},
            "license":{"type":"string","description":"License or terms (\"CC0\", \"Purchased, standard license\"...)."},
            "author":{"type":"string","description":"Person, studio or agent that made or chose the asset."},
            "source":{"type":"string","description":"Where an imported asset came from: a URL or the original file."},
            "date":{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$","description":"YYYY-MM-DD. Default: today."},
            "notes":{"type":"string","description":"Anything else, such as edits made by hand."}},
            "required":["path","origin"],"additionalProperties":false})"),
        false, set_provenance);
    add_command(
        registry, ctx, "assets.disclosure", "Write the AI-generated content disclosure for store forms (Steam) from the provenance records.",
        "Returns Markdown that answers the AI-generated content questions of Steam's content survey and similar forms: what was "
        "pre-generated with AI by category (art, sound effects, music, voice, 3D models) with counts, providers and models; that "
        "nothing is generated while the game runs; the terms recorded for each provider; and the art, sound and model files that "
        "still have no provenance record (fix those with assets.set_provenance first). `factoria export` writes the same text as "
        "AI_CONTENT_DISCLOSURE.md. Example: {}",
        Json::parse(R"({"type":"object","properties":{},"additionalProperties":false})"), true, disclosure);
}

}  // namespace fa::ai
