// The assets.* commands that generate assets and keep their provenance (docs/ASSETS.md, "Generating assets").
#include "asset_commands.h"

#include <algorithm>
#include <cmath>
#include <exception>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <set>
#include <utility>

#include "fa/ai/asset_cost.h"
#include "fa/ai/assets.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/tooling/ai_disclosure.h"
#include "fa/tooling/palette.h"
#include "fa/tooling/review.h"
#include "fa/tooling/style_guide.h"
#include "util.h"

namespace fa::ai {

namespace {

using namespace util;

// The "$image" path of a project file named by a JSON (UTF-8) argument: absolute, forward slashes, UTF-8 (it goes into a result). The name is
// UTF-8, so the host path is built from it with path_from_utf8; fs::resolve(std::string) would read it through the ANSI code page on Windows
// and mangle an accented asset name.
std::string image_result_path(const std::string& relUtf8) {
    const std::string norm = fs::normalize(relUtf8);
    if (norm.empty()) return relUtf8;
    const std::filesystem::path p = fs::path_from_utf8(norm);
    return fs::path_to_utf8(fs::is_absolute(norm) ? p : fs::project_root() / p);
}

struct Ctx {
    std::function<Result<AiConfig>()> load;
    std::function<std::string()> projectDir;
    ProviderRuntime runtime;
    const CancelFlag* cancel = nullptr;
    std::string runKey;  // the run the cost of this registry's calls counts into ("" = the calling thread's)
    AssetApprover approver;  // who is asked when a call needs the user's yes (empty = the process-wide one, else needsApproval)
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
    if (info.inputSchema["properties"].contains("approved")) {
        // The approval rule stays in the short description; the full COST paragraph joins the details.
        std::string rest;
        if (const std::size_t cut = info.description.find(kCommandDetailsMark); cut != std::string::npos) {
            rest = info.description.substr(cut + 1);
            info.description.resize(cut);
            while (!info.description.empty() && (info.description.back() == ' ' || info.description.back() == '\n')) info.description.pop_back();
        }
        info.description += asset_cost_short();
        info.details = rest + asset_cost_doc();
    }
    info.readOnly = readOnly;
    info.category = "assets";
    registry.add(std::move(info), [ctx, handler = std::move(handler)](const Json& args) -> Json {
        const std::string dir = ctx->projectDir();
        if (dir.empty()) {
            throw CommandError("no_project", "There is no project folder to put the asset in",
                               "Run from a project folder (the one with project.json) or pass --project to the factoria CLI.");
        }
        ProjectScope scope(dir);
        std::optional<AssetRunScope> run;
        if (!ctx->runKey.empty() || ctx->approver) run.emplace(ctx->runKey.empty() ? asset_run_key() : ctx->runKey, ctx->approver);
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
// `key` names the argument ("path", or "slot" for assets.pick, whose errors start with the JSON pointer).
std::string asset_path(const Json& args, const char* key = "path") {
    const std::string raw = str(args, key);
    const std::string where = std::string(key) == "path" ? std::string() : std::format("/{}: ", key);
    auto n = fs::normalize_checked(raw);
    if (!n) throw CommandError("invalid_path", where + n.error().message, n.error().hint);
    const std::string& p = n.value();
    if (fs::is_absolute(raw) || p.rfind("assets/", 0) != 0 || p.back() == '/') {
        const std::string name = fs::filename(p).empty() ? "file.png" : fs::filename(p);
        throw CommandError("invalid_path", std::format("{}'{}' is not a file under assets/", where, raw),
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

// ---- Candidates ---------------------------------------------------------------------------------------------------

constexpr int kMaxCandidates = 4;                                          // assets.generate_image `count`
constexpr const char* kCandidatesKind = kReviewAssetCandidatesKind;        // meta.kind of a candidates sheet
constexpr const char* kCandidatesDropDir = ".factoria/assets/candidates";  // where assets.pick moves the candidates not chosen

// The files of `count` candidates for `slot`: next to it, "<stem>.candidate-<n>.png" (n from 1).
std::vector<std::string> candidate_paths(const std::string& slot, int count) {
    std::vector<std::string> out;
    const std::string dir = fs::parent(slot);
    for (int n = 1; n <= count; ++n)
        out.push_back((dir.empty() ? std::string() : dir + "/") + fs::stem(slot) + ".candidate-" + std::to_string(n) + fs::extension(slot));
    return out;
}

// ---- Style ------------------------------------------------------------------------------------------------------------

// assets.json "style": the house style that keeps generated images consistent. The parser is the shared one of the tools
// (fa/tooling/style_guide.h), which also reads the measurable rules that assets.check_art and project.validate check.
using Style = StyleGuide;

Style load_style() {
    StyleParse parsed = load_style_guide();
    if (!parsed.problems.empty()) {
        const StyleProblem& p = parsed.problems.front();
        std::string more = parsed.problems.size() > 1 ? std::format(" ({} more problems in style; project.validate lists them.)", parsed.problems.size() - 1) : "";
        throw CommandError("invalid_style", std::format("assets.json {}: {}{}", p.pointer.empty() ? "/style" : p.pointer, p.message, more),
                           (p.hint.empty() ? "" : p.hint + " ") + "Pass style:false to skip the house style for this call.");
    }
    return std::move(parsed.guide);
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

// Before the provider is called: the estimate, the limits and the user's yes (docs/AI_COSTS.md, "Asset generation"). When go() is false
// the command returns needs_approval() and calls nothing. The guard counts the money as spent until it is destroyed uncommitted.
// `count` calls like `request` are asked for at once (the candidates of assets.generate_image): one estimate, one question, one yes.
AssetCostGuard cost_gate(const Ctx& ctx, const AiConfig& cfg, const Json& args, const char* command, const std::string& what,
                         const std::string& prompt, const AssetTarget& target, const AssetRequest& request, int count = 1) {
    AssetCall call;
    call.command = command;
    call.what = what;
    call.prompt = prompt;
    call.projectDir = ctx.projectDir();
    call.provider = target.provider->name;
    call.model = target.model;
    call.kind = request.kind;
    call.estimate = estimate_asset_cost(*target.provider, request, count);
    call.cancel = ctx.cancel;
    return AssetCostGuard::begin(cfg.limits, call, flag(args, "approved"));
}

// The estimate and what was spent go into the command's result next to the files it made.
void add_cost(Json& out, const AssetCostGuard& guard, std::vector<std::string>& warnings) {
    const Json cost = guard.cost_json();  // a named object: the range below must outlive the loop
    for (const auto& [key, value] : cost.items()) out[key] = value;
    warnings.insert(warnings.end(), guard.warnings().begin(), guard.warnings().end());
}

struct ImageJob {
    std::string path, prompt;
    int width = 512, height = 512;
    int columns = 0, rows = 0;  // > 0: a sprite sheet of this grid
    bool transparent = false;
    Json sheet;                 // the "sheet" entry to record, or null
    const char* command = "assets.generate_image";
};

// What every picture of a call shares: the provider, the house style, the request (the seed of each candidate is set apart).
struct ImagePlan {
    AiConfig cfg;
    AssetTarget target;
    Style style;
    AssetRequest request;
    std::vector<std::string> referencePaths;
};

ImagePlan plan_image(const Ctx& ctx, const Json& args, const ImageJob& job) {
    ImagePlan plan;
    plan.cfg = load_ai_config(ctx);
    plan.target = resolve_target(ctx, plan.cfg, args, MediaKind::Image);
    plan.style = flag(args, "style", true) ? load_style() : Style{};
    AssetRequest& request = plan.request;
    request.kind = MediaKind::Image;
    request.prompt = plan.style.prompt.empty() ? job.prompt : job.prompt + "\n\nStyle: " + plan.style.prompt;
    request.model = plan.target.model;
    request.width = job.width;
    request.height = job.height;
    request.columns = job.columns;
    request.rows = job.rows;
    request.transparent = job.transparent;
    request.seed = seed_arg(args);
    std::vector<std::string> referencePaths = string_list(args, "references");
    referencePaths.insert(referencePaths.end(), plan.style.references.begin(), plan.style.references.end());
    plan.referencePaths = unique_paths(referencePaths);
    request.references = load_references(plan.referencePaths);
    return plan;
}

// A picture the provider made, fitted to the job and written at `path` (assets.json is not touched here).
struct WrittenImage {
    Image image;
    std::size_t bytes = 0;
    std::string notes;   // what was done to the provider's picture (resized, reduced to the palette)
    std::string sha256;  // of the PNG file written
};

WrittenImage write_image(const ImageJob& job, const ImagePlan& plan, const AssetResult& made, const std::string& path) {
    auto decoded = decode_image(reinterpret_cast<const std::uint8_t*>(made.bytes.data()), made.bytes.size());
    if (!decoded) {
        throw CommandError("bad_output",
                           std::format("The provider '{}' returned data that is not an image: {}", plan.target.provider->name, decoded.error().message),
                           "Check the provider and model with ai.providers (action doctor).");
    }
    WrittenImage out;
    out.image = std::move(*decoded);
    if (out.image.width != job.width || out.image.height != job.height) {
        out.notes = std::format("Resized from {}x{}.", out.image.width, out.image.height);
        out.image = resize_image(out.image, job.width, job.height);
    }
    if (plan.style.palette) {
        out.image = quantize_to_palette(out.image, *plan.style.palette);
        out.notes += std::format("{}Reduced to the {} colours of the style palette.", out.notes.empty() ? "" : " ", plan.style.palette->size());
    }
    const std::vector<std::uint8_t> png = encode_png(out.image);
    if (auto w = fs::write_bytes(path, png.data(), png.size()); !w) fail("write_failed", w.error());
    out.bytes = png.size();
    out.sha256 = sha256_hex(png.data(), png.size());
    return out;
}

void warn_unsent_references(std::vector<std::string>& warnings, const ImagePlan& plan, const AssetResult& made) {
    if (!plan.request.references.empty() && !made.usedReferences) {
        warnings.push_back(std::format("The provider '{}' cannot take reference images, so the {} reference(s) were not sent (the style prompt was).",
                                       plan.target.provider->name, plan.request.references.size()));
    }
}

Json generate_image_file(const Ctx& ctx, const Json& args, const ImageJob& job) {
    require_extension(job.path, ".png", "generated images are written as PNG");
    require_free(job.path, flag(args, "overwrite"));
    const ImagePlan plan = plan_image(ctx, args, job);
    const AssetTarget& target = plan.target;
    const AssetRequest& request = plan.request;

    AssetCostGuard guard = cost_gate(ctx, plan.cfg, args, job.command,
                                     job.columns > 0 ? std::format("a {}x{} sprite sheet ({} columns by {} rows) at {}", job.width, job.height, job.columns, job.rows, job.path)
                                                     : std::format("a {}x{} image at {}", job.width, job.height, job.path),
                                     job.prompt, target, request);
    if (!guard.go()) return guard.needs_approval();
    auto made = generate_asset(*target.provider, request, ctx.runtime, ctx.cancel);
    if (!made) fail("generation_failed", made.error());
    guard.commit();

    const WrittenImage written = write_image(job, plan, *made, job.path);
    std::vector<std::string> warnings;
    warn_unsent_references(warnings, plan, *made);
    warn_ignored_seed(warnings, request, *made, *target.provider);

    const Json provenance = generated_provenance(args, *target.provider, *made, MediaKind::Image, request.prompt,
                                                 made->usedReferences ? plan.referencePaths : std::vector<std::string>(), written.notes);
    record(job.path, provenance, job.sheet);

    Json out = Json::object({{"path", job.path},
                             {"width", written.image.width},
                             {"height", written.image.height},
                             {"bytes", written.bytes},
                             {"provenance", provenance}});
    add_cost(out, guard, warnings);
    if (!warnings.empty()) out["warnings"] = warnings;
    out["$image"] = Json::object({{"path", image_result_path(job.path)}, {"mimeType", "image/png"}});
    return out;
}

// ---- Candidates (count > 1) -------------------------------------------------------------------------------------------

// Whether `meta` is the meta of a candidates sheet made for `slot` (compared like the file system of Windows and macOS: case aside).
bool candidates_sheet_for(const Json& meta, const std::string& slot) {
    return meta.is_object() && str(meta, "kind") == kCandidatesKind && review_path_key(str(meta, "slot")) == review_path_key(slot);
}

// The candidates sheet of `slot` that is current: the newest one. A newer sheet for the same slot replaced the older ones, whose thumbnails
// show pictures the candidate files may no longer hold (a regeneration with overwrite writes the same file names). "" when there is none.
std::string current_candidates_sheet(const std::string& projectDir, const std::string& slot) {
    return review_newest(projectDir, [&](const Json& meta) { return candidates_sheet_for(meta, slot); });
}

// A seed for the first candidate when the call gives none: the same prompt gives the same candidates (FNV-1a of the prompt, 31 bits).
i64 prompt_seed(const std::string& prompt) {
    std::uint32_t h = 2166136261u;
    for (const unsigned char c : prompt) {
        h ^= c;
        h *= 16777619u;
    }
    return static_cast<i64>(h & 0x7fffffffu);
}

// `text` on one line, at most `maxBytes` bytes, cut at a UTF-8 character boundary ("..." when cut).
std::string one_line(const std::string& text, std::size_t maxBytes) {
    std::string flat;
    for (const char c : text) flat.push_back(c == '\n' || c == '\r' || c == '\t' ? ' ' : c);
    if (flat.size() <= maxBytes) return flat;
    std::size_t cut = maxBytes > 3 ? maxBytes - 3 : 0;
    while (cut > 0 && (static_cast<unsigned char>(flat[cut]) & 0xC0) == 0x80) --cut;
    return flat.substr(0, cut) + "...";
}

// assets.generate_image with count 2..4: N pictures for ONE slot, written next to it, shown on one review sheet; assets.pick keeps one.
Json generate_image_candidates(const Ctx& ctx, const Json& args, const ImageJob& job, int count) {
    require_extension(job.path, ".png", "generated images are written as PNG");
    const bool overwrite = flag(args, "overwrite");
    require_free(job.path, overwrite);
    const std::vector<std::string> paths = candidate_paths(job.path, count);
    // Everything that can be refused is refused before anything is paid for.
    Json meta = Json::object({{"kind", kCandidatesKind},
                              {"slot", job.path},
                              {"command", "assets.generate_image"},
                              {"count", count},
                              {"candidates", paths},
                              {"overwrite", overwrite},
                              {"estimatedCostUsd", nullptr},
                              {"sha256", Json::array()}});
    // Measured as it will be written: the estimated cost (filled in after the approval) gets 32 bytes (a double takes at most 24 as
    // JSON), and each file's SHA-256 (filled in once written) its 64 hex digits.
    Json measured = meta;
    measured["sha256"] = std::vector<std::string>(std::size_t(count), std::string(64, '0'));
    if (measured.dump().size() + 32 > std::size_t(kReviewMetaMaxBytes)) {
        throw CommandError("invalid_path", std::format("assets.generate_image /path: '{}' is too long for a sheet of {} candidates", job.path, count),
                           "Use a shorter path for the slot (folders and file name), or count 1.");
    }
    std::vector<std::string> taken;
    for (const std::string& p : paths)
        if (fs::exists(p)) taken.push_back(p);
    if (!taken.empty() && !overwrite) {
        throw CommandError("exists",
                           std::format("assets.generate_image /count: the candidate file(s) {} already exist", join(taken, ", ")),
                           "They are likely the candidates of an earlier call for this slot: answer that sheet with assets.pick {\"slot\": \"" + job.path +
                               "\", \"n\": <the person's number>} first, or pass overwrite:true to make new ones in their place (the old ones are not kept, and "
                               "their sheet can no longer be answered). Change the prompt or pass another `seed` for different pictures: the same prompt without a "
                               "seed gives the same ones with providers that honour seeds.");
    }
    std::vector<std::string> warnings;
    // overwrite:true over a file that only looks like a candidate of this slot (assets.json records it as something else): say what was lost.
    if (!taken.empty()) {
        const Json manifestNow = assets::manifest();
        const Json* listed = child(manifestNow, "assets");
        for (const std::string& p : taken) {
            const Json* entry = listed && listed->is_object() ? child(*listed, p.c_str()) : nullptr;
            const Json* provenance = entry ? child(*entry, "provenance") : nullptr;
            const Json* candidate = provenance ? child(*provenance, "candidate") : nullptr;
            if (candidate && candidate->is_object() && review_path_key(str(*candidate, "slot")) == review_path_key(job.path)) continue;
            warnings.push_back(std::format("'{}' was overwritten, and assets.json did not record it as a candidate of '{}' ({}): if it was a file of its own, "
                                           "it is gone (version control may still have it).",
                                           p, job.path, entry ? "it was listed with other provenance" : "it was not listed at all"));
        }
    }
    const std::string projectDir = ctx.projectDir();
    for (const std::string& p : paths) {
        if (const std::string why = review_candidate_problem(projectDir, "image", p); !why.empty())
            throw CommandError("invalid_path", std::format("assets.generate_image /path: the candidates of '{}' cannot be made: {}", job.path, why),
                               "Use a slot under assets/, for example 'assets/items/potion.png'.");
    }
    const ImagePlan plan = plan_image(ctx, args, job);
    const AssetTarget& target = plan.target;
    const std::optional<i64> askedSeed = plan.request.seed;
    const i64 baseSeed = askedSeed ? *askedSeed : prompt_seed(job.prompt);
    AssetCostGuard guard = cost_gate(ctx, plan.cfg, args, job.command,
                                     std::format("{} candidate {}x{} images for {} (one is kept with assets.pick)", count, job.width, job.height, job.path),
                                     job.prompt, target, plan.request, count);
    if (!guard.go()) return guard.needs_approval();
    meta["estimatedCostUsd"] = guard.cost_json().value("estimatedCostUsd", Json(nullptr));

    Json made = Json::array();
    std::vector<std::string> written;
    // A failure part way: what was made stays (it is paid for, and its provenance is recorded), and the error says so.
    const auto fail_part_way = [&](int paid, int failedN, const std::string& message, const std::string& hint) {
        const double kept = guard.commit_part(paid, count);
        std::string text = std::format("assets.generate_image: candidate {} of {} for '{}' failed: {}.", failedN, count, job.path, message);
        text += written.empty() ? " No candidate was written." : std::format(" Written and kept (with their provenance in assets.json): {}.", join(written, ", "));
        text += std::format(" Estimated cost of what was made: {} (the rest of the estimate was given back).", format_usd(kept));
        throw CommandError("generation_failed", text,
                           (hint.empty() ? "" : hint + " ") +
                               (written.empty() ? std::string("Nothing is left behind; try again when the provider works.")
                                                : "No review sheet was made. Delete the written candidates, or show them with review.sheet (candidate:true, dropDir \"" +
                                                      std::string(kCandidatesDropDir) + "\") and keep one; calling again with overwrite:true makes all " +
                                                      std::to_string(count) + " again (and pays for them again)."),
                           Json::object({{"written", written}, {"failedCandidate", failedN}, {"count", count}, {"estimatedCostUsd", kept}, {"costIsEstimate", true}}));
    };
    for (int i = 0; i < count; ++i) {
        AssetRequest request = plan.request;
        request.seed = static_cast<i64>(static_cast<std::uint64_t>(baseSeed) + static_cast<std::uint64_t>(i));
        std::optional<AssetResult> result;
        std::string whyNot, whyNotHint;
        try {
            auto asked = generate_asset(*target.provider, request, ctx.runtime, ctx.cancel);
            if (asked) result = std::move(*asked);
            else {
                whyNot = asked.error().message;
                whyNotHint = asked.error().hint;
            }
        } catch (const CommandError& e) {
            whyNot = e.what();
            whyNotHint = e.hint;
        } catch (const std::exception& e) {
            whyNot = e.what();
        }
        if (!result) fail_part_way(i, i + 1, whyNot, whyNotHint);
        // From here the picture is paid for: whatever fails, it is committed, not given back.
        WrittenImage picture;
        Json provenance;
        bool fileWritten = false;
        try {
            picture = write_image(job, plan, *result, paths[std::size_t(i)]);
            fileWritten = true;
            written.push_back(paths[std::size_t(i)]);
            if (i == 0) {
                warn_unsent_references(warnings, plan, *result);
                if (askedSeed) warn_ignored_seed(warnings, request, *result, *target.provider);
            }
            provenance = generated_provenance(args, *target.provider, *result, MediaKind::Image, request.prompt,
                                              result->usedReferences ? plan.referencePaths : std::vector<std::string>(), picture.notes);
            provenance["candidate"] = Json::object({{"slot", job.path}, {"n", i + 1}, {"count", count}});
            meta["sha256"].push_back(picture.sha256);
            record(paths[std::size_t(i)], provenance);
        } catch (const CommandError& e) {
            fail_part_way(i + 1, i + 1, e.what(), e.hint + (fileWritten ? " The file was written but its provenance was not recorded." : ""));
        } catch (const std::exception& e) {
            fail_part_way(i + 1, i + 1, e.what(), fileWritten ? "The file was written but its provenance was not recorded." : "");
        }
        Json c = Json::object({{"n", i + 1}, {"path", paths[std::size_t(i)]}, {"width", picture.image.width}, {"height", picture.image.height}, {"bytes", picture.bytes}});
        if (result->seed) c["seed"] = *result->seed;
        made.push_back(std::move(c));
    }
    guard.commit();

    // One sheet with every candidate, through review.sheet itself (the same checks, the same manifest, the same pick).
    Json items = Json::array();
    for (const Json& c : made) {
        const std::string label = c.contains("seed") ? "seed " + std::to_string(c["seed"].get<i64>()) : "candidate " + std::to_string(c["n"].get<int>());
        items.push_back(Json::object({{"image", c["path"]}, {"label", label}, {"candidate", true}}));
    }
    const Json sheetArgs = Json::object({{"label", one_line(job.prompt, 120)}, {"items", items}, {"dropDir", kCandidatesDropDir}, {"meta", meta}});
    const std::string replaced = current_candidates_sheet(projectDir, job.path);  // the sheet this one replaces (assets.pick answers the newest only)
    ReviewOutcome sheet = review_sheet(projectDir, sheetArgs);
    if (!sheet.ok) {
        throw CommandError(sheet.code.empty() ? "failed" : sheet.code,
                           std::format("assets.generate_image: the {} candidates were made ({}), but their review sheet could not be: {}", count, join(written, ", "), sheet.message),
                           (sheet.hint.empty() ? "" : sheet.hint + " ") + "The candidates are kept with their provenance. Call review.sheet with `reviewSheet` of this error's data, then assets.pick.",
                           Json::object({{"written", written}, {"reviewSheet", sheetArgs}}));
    }
    const std::string sheetId = sheet.value.value("sheet", std::string());
    if (const auto w = sheet.value.find("warnings"); w != sheet.value.end() && w->is_array())
        for (const Json& text : *w)
            if (text.is_string()) warnings.push_back(text.get<std::string>());

    Json out = Json::object({{"slot", job.path},
                             {"count", count},
                             {"candidates", made},
                             {"sheet", sheetId},
                             {"sheetPicture", sheet.value.value("picture", Json::object())}});
    if (sheet.value.contains("housekeeping")) out["housekeeping"] = sheet.value["housekeeping"];
    if (!replaced.empty() && replaced != sheetId) {
        const ReviewOutcome old = review_load(projectDir, replaced);
        const Json* picked = old.ok ? child(old.value, "picked") : nullptr;
        if (old.ok && !(picked && picked->is_object())) {
            out["replacedSheet"] = replaced;
            warnings.push_back(std::format("{} replaces {}, which was not answered yet: assets.pick answers only the newest candidates sheet of '{}' and "
                                           "refuses a number given for {} (code superseded). Show {} to the person instead.",
                                           sheetId, replaced, job.path, replaced, sheetId));
        }
    }
    add_cost(out, guard, warnings);
    if (!warnings.empty()) out["warnings"] = warnings;
    out["nextSteps"] = Json::array(
        {"Show the sheet (the picture of this result) to the person and ask for ONE number from 1 to " + std::to_string(count) + ". Do not choose for them.",
         "Then call assets.pick {\"slot\": \"" + job.path + "\", \"n\": <their number>}: that candidate becomes " + job.path +
             " with its provenance, and the others move to " + kCandidatesDropDir + "/" + sheetId + "/ (deleted " + std::to_string(kReviewDroppedDays) +
             " days later by review.cleanup).",
         "Until then the candidates are files under assets/ next to the slot (an export would ship them): pick before exporting."});
    if (sheet.value.contains("$image")) out["$image"] = sheet.value["$image"];
    return out;
}

Json generate_image(const Ctx& ctx, const Json& args) {
    ImageJob job;
    job.path = asset_path(args);
    job.prompt = required_text(args, "prompt");
    job.width = static_cast<int>(num(args, "width", 512));
    job.height = static_cast<int>(num(args, "height", 512));
    job.transparent = flag(args, "transparent");
    const double countArg = num(args, "count", 1);
    if (!(countArg >= 1 && countArg <= kMaxCandidates) || countArg != std::floor(countArg)) {
        throw CommandError("invalid_argument", std::format("assets.generate_image /count: {} is not a whole number from 1 to {}", countArg, kMaxCandidates),
                           std::format("count is how many candidates to make for the slot (default 1, at most {}); the person picks one from one sheet.", kMaxCandidates));
    }
    const int count = static_cast<int>(countArg);
    if (count > 1) return generate_image_candidates(ctx, args, job, count);
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
    job.command = "assets.generate_sprite_sheet";
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
    if (is_needs_approval(out)) return out;
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

    AssetCostGuard guard = cost_gate(ctx, cfg, args, kind == MediaKind::Sound ? "assets.generate_sound" : kind == MediaKind::Music ? "assets.generate_music"
                                                       : voice ? "assets.generate_voice" : "assets.generate_model",
                                     std::format("{} at {}", kind == MediaKind::Model3d ? "a 3D model" : voice ? "a voice clip" : std::string("a ") + media_kind_name(kind), path),
                                     prompt, target, request);
    if (!guard.go()) return guard.needs_approval();
    auto made = generate_asset(*target.provider, request, ctx.runtime, ctx.cancel);
    if (!made) fail("generation_failed", made.error());
    guard.commit();
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
    add_cost(out, guard, warnings);
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
    // A 3D bone clip (*.anim.json) is recorded wherever the project keeps it; every other asset lives under assets/.
    std::string path;
    if (const std::string raw = str(args, "path"); raw.size() > 10 && raw.compare(raw.size() - 10, 10, ".anim.json") == 0) {
        auto n = fs::normalize_checked(raw);
        if (!n) throw CommandError("invalid_path", n.error().message, n.error().hint);
        if (fs::is_absolute(raw) || n->empty()) throw CommandError("invalid_path", std::format("'{}' is not a project path", raw), "Use a project-relative path such as 'anim/hero_walk.anim.json'.");
        path = *n;
    } else {
        path = asset_path(args);
    }
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
    // The recipe of a made asset (assets.regenerate) is not something to type here: describing who made the file keeps it.
    auto r = assets::update_entry(path, [&](Json& entry) {
        if (entry.contains("provenance") && entry["provenance"].is_object() && entry["provenance"].contains("recipe")) p["recipe"] = entry["provenance"]["recipe"];
        entry["provenance"] = p;
    });
    if (!r) fail("manifest_failed", r.error());
    return Json::object({{"path", path}, {"provenance", p}});
}

Json disclosure(const Ctx&, const Json&) {
    const Json manifest = assets::manifest();
    std::vector<std::string> files = fs::list("assets");
    // A 3D clip lives wherever the project keeps its animations (anim/...), not under assets/: its record counts when the file exists.
    if (const Json* all = child(manifest, "assets"); all && all->is_object())
        for (const auto& [path, entry] : all->items())
            if (path.rfind("assets/", 0) != 0 && path.size() > 10 && path.compare(path.size() - 10, 10, ".anim.json") == 0 && fs::exists(path)) files.push_back(path);
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
    "approved":{"type":"boolean","default":false,"description":"The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed."},
    "author":{"type":"string","description":"Who gets the credit in the provenance record. Default: \"factoria\"."})J";

const std::string kImageProperties = R"J(
    "references":{"type":"array","items":{"type":"string"},"description":"Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json."},
    "style":{"type":"boolean","default":true,"description":"Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call."})J";

Json schema(const std::string& properties, const std::string& required) {
    return Json::parse(R"({"type":"object","properties":{)" + properties + R"(},"required":)" + required + R"(,"additionalProperties":false})");
}

// ---- assets.pick ------------------------------------------------------------------------------------------------------

ReviewOutcome refuse(const std::string& code, std::string message, std::string hint) {
    ReviewOutcome o;
    o.ok = false;
    o.code = code;
    o.message = std::move(message);
    o.hint = std::move(hint);
    return o;
}

// The item number `n` of a manifest item (a file anyone can edit: anything but a whole number is 0).
int item_number(const Json& item) {
    const Json* n = child(item, "n");
    return n && n->is_number_integer() ? static_cast<int>(std::clamp<i64>(n->get<i64>(), 0, kReviewMaxItems)) : 0;
}

// The refusal of a sheet that is not the current one of its slot.
ReviewOutcome superseded(const std::string& sheetId, const std::string& slot, const std::string& current) {
    return refuse("superseded",
                  std::format("assets.pick /sheet: {} is no longer the candidates sheet of '{}': {} replaced it (made later for the same slot; "
                              "the candidate files now hold its pictures, not the ones on {})", sheetId, slot, current, sheetId),
                  std::format("Show {} to the person, ask for their number again, then call assets.pick {{\"slot\": \"{}\", \"n\": <their number>}} "
                              "(or with \"sheet\": \"{}\"). Only the newest candidates sheet of a slot can be answered.", current, slot, current));
}

std::string already_picked_hint(const std::string& slot) {
    return "A choice is final. To choose again make new candidates with assets.generate_image {\"path\": \"" + slot +
           "\", \"count\": 3, \"overwrite\": true} and a changed prompt or another `seed` (the same prompt without a seed gives the same pictures "
           "with providers that honour seeds), show the sheet and ask again.";
}

// The sheet assets.pick answers: the newest candidates sheet of the slot, which `given` (when set) must be.
std::string find_candidates_sheet(const std::string& projectDir, const std::string& slot, const std::string& given) {
    const std::string current = current_candidates_sheet(projectDir, slot);
    std::string id = current;
    if (!given.empty()) {
        ReviewOutcome loaded = review_load(projectDir, given);
        if (!loaded.ok) throw CommandError(loaded.code, "assets.pick /sheet: " + loaded.message, loaded.hint);
        const Json meta = loaded.value.value("meta", Json::object());
        if (!candidates_sheet_for(meta, slot)) {
            const std::string kind = str(meta, "kind");
            throw CommandError("invalid_argument",
                               kind != kCandidatesKind
                                   ? std::format("assets.pick /sheet: '{}' is not a sheet of asset candidates (it was not made by assets.generate_image with count)", given)
                                   : std::format("assets.pick /sheet: '{}' holds the candidates of '{}', not of '{}'", given, str(meta, "slot"), slot),
                               kind != kCandidatesKind ? "Answer other sheets with review.pick, or leave out `sheet` to answer the newest candidates sheet of the slot."
                                                       : "Pass the slot that sheet was made for, or leave out `sheet` to answer the newest candidates sheet of '" + slot + "'.");
        }
        id = str(loaded.value, "id", given);
        if (!current.empty() && id != current) {
            const ReviewOutcome refused = superseded(id, slot, current);
            throw CommandError(refused.code, refused.message, refused.hint);
        }
    }
    if (!id.empty()) {
        ReviewOutcome loaded = review_load(projectDir, id);
        if (loaded.ok) {
            if (const auto picked = loaded.value.find("picked"); picked != loaded.value.end() && picked->is_object())
                throw CommandError("already_picked",
                                   std::format("assets.pick /slot: the candidates of '{}' on {} were already picked (number {}); older sheets of the slot were replaced by it",
                                               slot, id, item_number(*picked)),
                                   already_picked_hint(slot));
        }
        return id;
    }
    // No candidates sheet for the slot: the slots that have one are the suggestions.
    std::vector<std::string> slots;
    if (ReviewOutcome listed = review_list(projectDir, kReviewListMax); listed.ok) {
        for (const Json& sheet : listed.value.value("sheets", Json::array())) {
            const Json meta = sheet.value("meta", Json::object());
            if (!meta.is_object() || str(meta, "kind") != kCandidatesKind) continue;
            if (const std::string other = str(meta, "slot"); !other.empty() && std::find(slots.begin(), slots.end(), other) == slots.end()) slots.push_back(other);
        }
    }
    throw CommandError("not_found",
                       std::format("assets.pick /slot: there is no sheet of candidates for '{}'.{}", slot,
                                   slots.empty() ? std::string(" No candidates sheet exists in this project.") : " " + did_you_mean(slot, slots)),
                       "Make candidates first with assets.generate_image {\"path\": \"" + slot + "\", \"count\": 3}; review.list shows every sheet.");
}

// What the pick changed, so an undo can put it back.
struct PickState {
    std::string slot, candidate, backupRel;
    std::filesystem::path absSlot, absCandidate, absBackup;
    bool movedOld = false, movedChosen = false, manifestChanged = false;
    std::vector<std::pair<std::string, Json>> oldEntries;  // assets.json entries before the change (null: there was none)
};

// Puts back what the pick did, the last step first; returns what could not be put back ("" = all).
std::string undo_pick(PickState& st) {
    std::vector<std::string> stuck;
    if (st.manifestChanged) {
        auto r = assets::update_manifest([&](Json& doc) {
            if (!doc.contains("assets") || !doc["assets"].is_object()) doc["assets"] = Json::object();
            Json& list = doc["assets"];
            for (const auto& [key, entry] : st.oldEntries) {
                if (entry.is_null()) list.erase(key);
                else list[key] = entry;
            }
        });
        if (!r) stuck.push_back("the assets.json entries of " + st.slot + " and its candidates (" + r.error().message + ")");
        else st.manifestChanged = false;
    }
    std::error_code ec;
    if (st.movedChosen) {
        fs::replace_file(st.absSlot, st.absCandidate, ec);
        if (ec) stuck.push_back(st.slot + " -> " + st.candidate + " (" + ec.message() + ")");
        else st.movedChosen = false;
    }
    if (st.movedOld) {
        ec.clear();
        fs::replace_file(st.absBackup, st.absSlot, ec);
        if (ec) stuck.push_back(st.backupRel + " -> " + st.slot + " (" + ec.message() + ")");
        else st.movedOld = false;
    }
    return join(stuck, "; ");
}

ReviewOutcome move_failure(const std::string& what, const std::string& from, const std::string& to, const std::error_code& ec) {
    const bool busy = fs::is_sharing_violation(ec);
    return refuse(busy ? "busy" : "failed", std::format("assets.pick: cannot move {} '{}' to '{}': {}.", what, from, to, ec.message()),
                  busy ? "The file is open in another program (an image viewer, the editor, an antivirus scan). Close it and call assets.pick again."
                       : "Check that the project folder is writable, then call assets.pick again.");
}

// After the other candidates moved: the old slot file to the drop folder, the chosen one onto the slot, its provenance to the slot.
ReviewOutcome apply_pick(PickState& st, const Json& sheetMeta, const std::string& sheetId, const Json& chosen, const std::string& dropFolder) {
    Json dropped = Json::array();
    std::error_code ec;
    if (fs::exists(st.slot)) {
        if (dropFolder.empty())
            return refuse("failed", std::format("assets.pick: {} names no usable drop folder, so the old '{}' cannot be kept", sheetId, st.slot),
                          std::string("Edit dropDir in the sheet's manifest back to \"") + kCandidatesDropDir + "\", or remove the old file first.");
        st.backupRel = dropFolder + "/" + review_drop_file_name(0, st.slot);
        st.absBackup = fs::os_path(fs::resolve(st.backupRel));
        if (std::filesystem::exists(st.absBackup, ec))
            return refuse("exists", std::format("assets.pick: '{}' already exists, so the old '{}' cannot be kept there", st.backupRel, st.slot),
                          "Move that file away, then call assets.pick again.");
        std::filesystem::create_directories(st.absBackup.parent_path(), ec);
        if (ec) return refuse("failed", std::format("assets.pick: cannot create '{}': {}", dropFolder, ec.message()), "Check that the project folder is writable.");
        fs::replace_file(st.absSlot, st.absBackup, ec);
        if (ec) return move_failure("the old", st.slot, st.backupRel, ec);
        st.movedOld = true;
        dropped.push_back(Json::object({{"n", 0}, {"label", "the old " + fs::filename(st.slot)}, {"from", st.slot}, {"to", st.backupRel}}));
    }
    ec.clear();
    std::filesystem::create_directories(st.absSlot.parent_path(), ec);
    ec.clear();
    fs::replace_file(st.absCandidate, st.absSlot, ec);
    if (ec) {
        ReviewOutcome failed = move_failure("the chosen candidate", st.candidate, st.slot, ec);
        if (const std::string stuck = undo_pick(st); !stuck.empty()) failed.message += " Could not put back, move by hand: " + stuck + ".";
        return failed;
    }
    st.movedChosen = true;

    // assets.json: the slot gets the chosen candidate's provenance, and the candidates' own entries go.
    const Json& meta = sheetMeta;
    std::vector<std::string> keys{st.slot};
    if (const Json* list = child(meta, "candidates"); list && list->is_array())
        for (const Json& c : *list)
            if (c.is_string())
                if (const std::string k = fs::normalize(c.get<std::string>()); !k.empty() && k.rfind("assets/", 0) == 0 && std::find(keys.begin(), keys.end(), k) == keys.end())
                    keys.push_back(k);
    if (std::find(keys.begin(), keys.end(), st.candidate) == keys.end()) keys.push_back(st.candidate);
    Json provenance;
    std::vector<std::string> warnings;
    auto written = assets::update_manifest([&](Json& doc) {
        if (!doc.contains("assets") || !doc["assets"].is_object()) doc["assets"] = Json::object();
        Json& list = doc["assets"];
        st.oldEntries.clear();
        for (const std::string& k : keys) st.oldEntries.emplace_back(k, list.contains(k) ? list[k] : Json(nullptr));
        const auto cand = list.find(st.candidate);
        if (cand != list.end() && cand->is_object() && cand->contains("provenance") && (*cand)["provenance"].is_object()) {
            provenance = (*cand)["provenance"];
        } else {
            provenance = Json::object({{"origin", "generated"}, {"ai", true}, {"kind", "image"}, {"date", assets::today()}});
            warnings.push_back("assets.json had no provenance for '" + st.candidate + "', so '" + st.slot +
                               "' got a minimal record (origin generated, ai true): complete it with assets.set_provenance.");
        }
        provenance.erase("candidate");
        Json batch = Json::object({{"sheet", sheetId}, {"picked", item_number(chosen)}, {"count", meta.value("count", Json(nullptr))}});
        if (const auto cost = meta.find("estimatedCostUsd"); cost != meta.end() && cost->is_number()) {
            batch["estimatedCostUsd"] = *cost;
            batch["costIsEstimate"] = true;
        }
        provenance["candidates"] = batch;
        Json entry = list.contains(st.slot) && list[st.slot].is_object() ? list[st.slot] : Json::object();
        entry.erase("analysis");  // what the tools measured or sliced from the old file
        entry.erase("sheet");
        entry["provenance"] = provenance;
        for (const std::string& k : keys) list.erase(k);
        list[st.slot] = entry;
    });
    if (!written) {
        ReviewOutcome failed = refuse("manifest_failed", std::format("assets.pick: assets.json could not be updated for '{}': {}.", st.slot, written.error().message),
                                      (written.error().hint.empty() ? "" : written.error().hint + " ") + "Fix assets.json (project.validate shows the problem), then call assets.pick again.");
        if (const std::string stuck = undo_pick(st); !stuck.empty()) failed.message += " Could not put back, move by hand: " + stuck + ".";
        else failed.message += " Nothing was changed.";
        return failed;
    }
    st.manifestChanged = true;
    ReviewOutcome ok;
    ok.value = Json::object({{"dropped", dropped}, {"provenance", provenance}, {"replaced", st.movedOld}, {"warnings", warnings}});
    if (st.movedOld) ok.value["oldFile"] = st.backupRel;
    return ok;
}

Json pick_command(const Ctx& ctx, const Json& args) {
    const std::string slot = asset_path(args, "slot");
    const std::string projectDir = ctx.projectDir();
    const double nArg = num(args, "n", 0);
    const long n = nArg >= 1 && nArg <= kMaxCandidates ? static_cast<long>(nArg) : 0;  // the schema keeps it to 1..4
    const bool overwriteArg = flag(args, "overwrite");
    const std::string sheetId = find_candidates_sheet(projectDir, slot, str(args, "sheet"));

    auto st = std::make_shared<PickState>();
    st->slot = slot;
    st->absSlot = fs::os_path(fs::resolve(slot));
    auto sheetMeta = std::make_shared<Json>(Json::object());

    ReviewPickOptions options;
    options.note = str(args, "note");
    // Under the review lock, with the manifest as it is now: the same sheet, the same slot, a chosen candidate that is really there.
    options.step.check = [st, sheetMeta, overwriteArg, projectDir, sheetId](const Json& manifest, const Json& chosen) -> ReviewOutcome {
        const Json meta = manifest.value("meta", Json::object());
        if (!candidates_sheet_for(meta, st->slot))
            return refuse("invalid_argument", std::format("assets.pick /sheet: {} is not a sheet of candidates for '{}' (its meta changed)", sheetId, st->slot),
                          "Leave out `sheet` to answer the newest candidates sheet of the slot.");
        // Under the lock, so a regeneration that finished after the lookup is seen too.
        if (const std::string current = current_candidates_sheet(projectDir, st->slot); !current.empty() && current != sheetId)
            return superseded(sheetId, str(meta, "slot"), current);
        *sheetMeta = meta;
        // The slot as the sheet spells it (the call may differ in case, which is the same file on Windows and macOS only).
        const std::string metaSlot = fs::normalize(str(meta, "slot"));
        if (metaSlot.rfind("assets/", 0) != 0 || fs::extension(metaSlot) != ".png")
            return refuse("invalid_argument", std::format("assets.pick /sheet: the slot '{}' in the meta of {} is not a .png under assets/", str(meta, "slot"), sheetId),
                          "The manifest was edited by hand: make new candidates with assets.generate_image {count}.");
        st->slot = metaSlot;
        st->absSlot = fs::os_path(fs::resolve(st->slot));
        const std::string source = str(chosen, "source");
        bool listed = false;
        std::size_t index = 0;  // its place in meta.candidates (and meta.sha256)
        if (const Json* list = child(meta, "candidates"); list && list->is_array())
            for (std::size_t i = 0; i < list->size() && !listed; ++i)
                if ((*list)[i].is_string() && review_path_key((*list)[i].get<std::string>()) == review_path_key(source)) {
                    listed = true;
                    index = i;
                }
        if (str(chosen, "type") != "image" || !listed)
            return refuse("invalid_argument", std::format("assets.pick /n: item {} of {} is not one of the candidates made for '{}'", item_number(chosen), sheetId, st->slot),
                          "Use the number of a candidate on the sheet; the sheet's meta.candidates lists their files.");
        if (const std::string why = review_candidate_problem(projectDir, "image", source); !why.empty())
            return refuse("invalid_argument", std::format("assets.pick /n: candidate '{}' cannot become '{}': {}", source, st->slot, why), "Make new candidates with assets.generate_image {count}.");
        auto norm = fs::normalize_checked(source);
        if (!norm || !fs::exists(*norm))
            return refuse("not_found", std::format("assets.pick /n: candidate {} ('{}') is no longer there", item_number(chosen), source),
                          "It was moved or deleted after the sheet was made. Pick another number, or make new candidates with assets.generate_image {count}.");
        st->candidate = *norm;
        st->absCandidate = fs::os_path(fs::resolve(st->candidate));
        // The file must still be the picture on the sheet: a later generation with overwrite (one that failed part way and made no
        // sheet of its own) or an edit writes other pixels under the same name.
        if (const Json* sums = child(meta, "sha256"); sums && sums->is_array() && index < sums->size() && (*sums)[index].is_string()) {
            auto now = sha256_file_hex(st->absCandidate);
            if (!now || *now != (*sums)[index].get<std::string>())
                return refuse("superseded",
                              std::format("assets.pick /n: candidate {} ('{}') is not the picture on {}: the file {} after the sheet was made", item_number(chosen),
                                          st->candidate, sheetId, now ? "changed" : "cannot be read (" + now.error().message + ")"),
                              "A later assets.generate_image with overwrite (or an edit) wrote it again. Make new candidates with assets.generate_image "
                              "{\"path\": \"" + st->slot + "\", \"count\": 3, \"overwrite\": true}, show the new sheet and ask again.");
        }
        if (fs::exists(st->slot) && !overwriteArg && !flag(meta, "overwrite"))
            return refuse("exists", std::format("assets.pick /slot: '{}' already exists", st->slot),
                          "Pass overwrite:true to replace it (the old file is kept for " + std::to_string(kReviewDroppedDays) +
                              " days in the sheet's drop folder), or ask the person first.");
        return {};
    };
    options.step.apply = [st, sheetMeta, sheetId](const Json&, const Json& chosen, const std::string& dropFolder) -> ReviewOutcome {
        try {
            return apply_pick(*st, *sheetMeta, sheetId, chosen, dropFolder);
        } catch (const std::exception& e) {  // whatever happened, the files go back where they were
            ReviewOutcome failed = refuse("failed", std::string("assets.pick: ") + e.what() + ".", "Call assets.pick again once the cause is fixed.");
            if (const std::string stuck = undo_pick(*st); !stuck.empty()) failed.message += " Could not put back, move by hand: " + stuck + ".";
            return failed;
        }
    };
    options.step.undo = [st]() { return undo_pick(*st); };

    ReviewOutcome picked = review_pick(projectDir, sheetId, n, options);
    if (!picked.ok) {
        std::string hint = picked.hint;
        if (picked.code == "already_picked") hint = already_picked_hint(slot);
        throw CommandError(picked.code.empty() ? "failed" : picked.code, picked.message, hint);
    }
    const Json& v = picked.value;
    const Json step = v.value("step", Json::object());
    Json warnings = v.value("warnings", Json::array());
    for (const Json& w : step.value("warnings", Json::array())) warnings.push_back(w);
    const std::string chosenSlot = st->slot;  // the sheet's own spelling of the slot
    Json out = Json::object({{"slot", chosenSlot},
                             {"sheet", v.value("sheet", sheetId)},
                             {"n", v.value("n", Json(n))},
                             {"label", v.value("label", std::string())},
                             {"candidate", v.value("source", std::string())},
                             {"provenance", step.value("provenance", Json::object())},
                             {"replaced", step.value("replaced", false)},
                             {"dropped", v.value("dropped", Json::array())},
                             {"who", v.value("who", Json(nullptr))},
                             {"at", v.value("at", Json(nullptr))},
                             {"warnings", warnings}});
    if (step.contains("oldFile")) out["oldFile"] = step["oldFile"];
    out["nextSteps"] = Json::array({std::format("'{}' is now the chosen picture; the others are in {}/{}/ and review.cleanup deletes them {} days from now.", chosenSlot,
                                                kCandidatesDropDir, out["sheet"].get<std::string>(), kReviewDroppedDays)});
    out["$image"] = Json::object({{"path", image_result_path(chosenSlot)}, {"mimeType", "image/png"}});
    return out;
}

}  // namespace

void register_asset_commands(CommandRegistry& registry, std::function<Result<AiConfig>()> load, std::function<std::string()> projectDir,
                             ProviderRuntime runtime, const CancelFlag* cancel, std::string runKey, AssetApprover approver) {
    auto ctx = std::make_shared<Ctx>(Ctx{std::move(load), std::move(projectDir), std::move(runtime), cancel, std::move(runKey), std::move(approver)});
    const std::string pathProperty = R"J("path":{"type":"string","description":"Where to write the file, project-relative, under assets/ (for example \"assets/sfx/jump.wav\"). The extension must match what the provider makes."},)J";

    add_command(
        registry, ctx, "assets.generate_image", "Generate a PNG image with the image asset provider and record where it came from.",
        "Calls the provider that ai.json assigns to \"image\" (assets.image; there is no default, so add "
        "one, or pass `provider` such as \"fake\" for an offline placeholder), writes a PNG of exactly width "
        "x height at `path` and records provenance (origin generated, ai true, provider, model, the full "
        "prompt, references, date, license note) in assets.json. The house style of assets.json is applied "
        "unless style is false: its `prompt` is appended to yours, its `references` are sent along with "
        "`references`, and its `palette` reduces the result to those colours. Returns the path, size, "
        "provenance and the image itself. Generation costs money with paid providers: check the first result "
        "before generating more. With `count` 2 to 4 it makes candidates and ONE review sheet: show it, ask "
        "for one number, call assets.pick; never pick for the person. "
        FA_COMMAND_DETAILS
        "With `count` 2 to 4 it makes that many candidates for the slot `path` "
        "instead (files next to it named <name>.candidate-<n>.png, each with its own seed and provenance; "
        "the cost estimate and the approval cover all of them at once) and ONE review sheet that shows them "
        "numbered: show that sheet to the person, ask for one number and call assets.pick {slot, n}. Never "
        "pick for them. Example: {\"prompt\":\"a red potion bottle, side "
        "view\",\"path\":\"assets/items/potion.png\",\"width\":64,\"height\":64,\"transparent\":true}",
        schema(pathProperty +
                   R"J("prompt":{"type":"string","description":"What to draw. Describe the subject and the view; the house style is added for you."},
    "width":{"type":"integer","minimum":8,"maximum":4096,"default":512,"description":"Width of the PNG in pixels. The provider's picture is resized to it."},
    "height":{"type":"integer","minimum":8,"maximum":4096,"default":512,"description":"Height of the PNG in pixels."},
    "transparent":{"type":"boolean","default":false,"description":"Ask for a transparent background (sprites, items, icons)."},
    "count":{"type":"integer","minimum":1,"maximum":4,"default":1,"description":"How many candidates to make for the slot `path` (1 to 4). 1 writes `path` itself. 2 to 4 write <name>.candidate-1.png... next to it (seeds seed, seed+1...; without `seed` they come from the prompt) and one review sheet; the person picks one with assets.pick, which moves it to `path`. With overwrite false, existing candidate files are refused; with overwrite true they are replaced, and the slot's earlier sheet can no longer be answered (assets.pick answers the newest)."},)J" +
                   kImageProperties + "," + kCommonProperties,
               R"(["prompt","path"])"),
        false, generate_image);
    add_command(
        registry, ctx, "assets.pick", "Keep the candidate the person chose: it becomes the slot, the others are dropped.",
        "Answers the review sheet that assets.generate_image {count} made for `slot` (its newest one: a newer sheet for the same slot "
        "replaces the older ones, which are refused as superseded) "
        "with the number the PERSON chose: never pick for them; show the sheet and ask. Candidate `n` is moved to `slot` and the "
        "slot's entry in assets.json gets its provenance (prompt, provider, model, seed, plus `candidates`: the sheet, the number "
        "picked, how many there were and the estimated cost of the batch); the candidates' own entries are removed. The other "
        "candidates move to .factoria/assets/candidates/<sheet id>/, where review.cleanup deletes them after 7 days. An existing "
        "slot file needs overwrite (here or in the generate call) and is kept in the same folder. All or nothing: when a file "
        "cannot be moved (open in another program: code busy) nothing changes. Refused: a slot whose newest sheet was already answered "
        "(already_picked), and a candidate file that is no longer the picture on the sheet (superseded). The editor's Review window calls "
        "it with {sheet, n, slot}. "
        "Example: {\"slot\":\"assets/items/potion.png\",\"n\":2}",
        Json::parse(R"({"type":"object","properties":{
            "slot":{"type":"string","description":"The path the candidates were made for: the `path` given to assets.generate_image, project-relative under assets/."},
            "n":{"type":"integer","minimum":1,"maximum":4,"description":"The number printed on the thumbnail the person chose (1 is the first candidate)."},
            "sheet":{"type":"string","description":"The candidates sheet to answer (\"sheet-0007\", or its number). It must be the newest candidates sheet of `slot` (an older one is refused as superseded). Default: that newest sheet."},
            "note":{"type":"string","maxLength":500,"description":"Why this one, in the person's words; kept in the sheet's manifest with the choice."},
            "overwrite":{"type":"boolean","default":false,"description":"Replace a file that already exists at `slot` (the old file is kept in the sheet's drop folder for 7 days). Not needed when the generate call had overwrite:true."}},
            "required":["slot","n"],"additionalProperties":false})"),
        false, pick_command);
    add_command(
        registry, ctx, "assets.generate_sprite_sheet",
        "Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator.",
        "Like assets.generate_image, but the picture is a grid of `frames` animation frames of frameWidth x "
        "frameHeight, normalized to exactly columns * frameWidth by rows * frameHeight pixels (each side at "
        "most 4096). The layout is written to assets.json as the `sheet` of the file with one clip "
        "\"default\" (all frames, at `fps`), and the result shows the Sprite and SpriteAnimator components "
        "to use. Providers draw grids unevenly: look at the result and regenerate when frames wander. "
        "Example: {\"prompt\":\"a knight walking "
        "right\",\"path\":\"assets/knight_walk.png\",\"frames\":6,\"columns\":3,\"frameWidth\":64,\"frameHeight\":64,\"fps\":10} "
        FA_COMMAND_DETAILS,
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
        "Calls the provider that ai.json assigns to \"voice\" (assets.voice) to speak `text` with `voice` "
        "(default: the voice in ai.json) and writes the audio file at `path`. Records provenance in "
        "assets.json (the text is the prompt). Needs a key in the environment: ELEVENLABS_API_KEY "
        "(elevenlabs) or OPENAI_API_KEY (openai); without a provider the error says what to add to ai.json. "
        "To test code that depends on voice lines without a provider or a key, pass `silent: true`: it "
        "writes a silent .wav as long as the line (about 0.06 s per character, or `seconds`) and records it "
        "as a placeholder, not AI. Example: {\"text\":\"Welcome, "
        "traveller.\",\"path\":\"assets/voice/welcome.mp3\"} "
        FA_COMMAND_DETAILS,
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
        "Replaces the provenance record of an existing file in assets.json (the recipe that assets.regenerate runs, when the file has one, is kept). The generate commands write it for you; use this "
        "for files they did not make, so the AI disclosure is complete. `ai` says whether AI made the content (it defaults to "
        "true for origin generated, false otherwise). Example: {\"path\":\"assets/music/theme.ogg\",\"origin\":\"imported\","
        "\"ai\":false,\"license\":\"CC0\",\"source\":\"https://example.com/theme\",\"author\":\"A. Composer\"}",
        Json::parse(R"({"type":"object","properties":{
            "path":{"type":"string","description":"Project-relative path of an existing file under assets/ (or a 3D clip, *.anim.json, anywhere in the project)."},
            "origin":{"type":"string","enum":["generated","imported","original"],"description":"generated: made by an asset provider. imported: brought in from a file made elsewhere. original: made by hand for this game."},
            "ai":{"type":"boolean","description":"Whether AI made the content. Default: true for origin generated, false otherwise."},
            "kind":{"type":"string","enum":["image","sound","music","voice","model3d","anim3d"],"description":"What the asset is, so the disclosure can tell sound effects, music and voice apart. anim3d: a 3D bone clip (*.anim.json), which the anim3d commands record themselves."},
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

namespace asset_support {

ProjectScope::ProjectScope(const std::string& dir) : previous(fs::project_root()), changed(std::filesystem::path(dir) != previous) {
    if (changed) fs::set_project_root(dir);
}
ProjectScope::~ProjectScope() {
    if (changed) fs::set_project_root(previous);
}
StyleGuide load_house_style() { return load_style(); }
std::vector<ReferenceImage> load_reference_images(const std::vector<std::string>& paths) { return load_references(paths); }
std::vector<std::string> normalized_unique_paths(const std::vector<std::string>& raw) { return unique_paths(raw); }
Json image_provenance(const Json& args, const ProviderConfig& provider, const AssetResult& made, const std::string& prompt,
                      const std::vector<std::string>& references, const std::string& notes) {
    return generated_provenance(args, provider, made, MediaKind::Image, prompt, references, notes);
}
void record_provenance(const std::string& path, const Json& provenance) { record(path, provenance); }

}  // namespace asset_support

}  // namespace fa::ai
