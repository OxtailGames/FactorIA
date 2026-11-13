#include "assets_review.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <sstream>

#include "fa/ai/text_model.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/tooling/style_guide.h"
#include "review_util.h"
#include "util.h"

namespace fa::ai {

using namespace util;
using namespace review;
namespace stdfs = std::filesystem;

namespace {

constexpr std::size_t kMaxPaths = 4;
constexpr std::size_t kMaxReferences = 3;

const char* kSystem =
    "You review pictures made for a game, as the art director of its style. You are given: the house style rules of "
    "the game "
    "(assets.json `style`), the measurements of an automatic check (assets.check_art: each rule has a value, a verdict "
    "ok / warn / "
    "fail and a hint), then images in this order: the style reference images (if any), the pictures under review, and "
    "the check's "
    "annotated picture (one row per asset: the picture, its greyscale value, over each background, at each on-screen "
    "size).\n"
    "Judge what the numbers cannot: does the picture match the references and the style (shapes, shading, line "
    "quality, level of "
    "detail), does it read at its on-screen size, does it suit what it is for, are there artifacts (stray pixels, "
    "blur, cut-off "
    "limbs, text-like noise). Trust the numbers for what they measure; never contradict a `fail` by calling the "
    "picture fine.\n"
    "Every fix must be something the person making the art can DO with a command of the engine or a setting of "
    "assets.json: "
    "regenerate with assets.generate_image {prompt, path, overwrite:true} (say what to change in the prompt), "
    "assets.generate_texture, assets.rasterize_svg (say which shape to change), a `style.*` setting of assets.json, "
    "assets.check_art / assets.contact_sheet / assets.preview_in_scene to look again. Never invent a command or a "
    "setting.\n"
    "Answer with ONE JSON object and nothing else:\n"
    "{\"verdict\":\"good|fix|redo\",\"summary\":\"one or two sentences\",\"fixes\":[{\"what\":\"the problem and the "
    "change\","
    "\"where\":\"the picture path, and the part of it\",\"command\":\"the command with its main arguments, or the "
    "assets.json setting\"}]}\n"
    "`good`: nothing to change (fixes empty). `fix`: keep the picture, change what the fixes say. `redo`: start the "
    "picture again. "
    "At most 6 fixes, most important first.";

// The numbers the model is given: the verdict and every rule that is not ok (with its value, threshold and hint), per asset and for the set.
Json check_summary(const Json& check) {
    Json out = Json::object(
        {{"verdict", str(check, "verdict")}, {"counts", check.contains("counts") ? check["counts"] : Json::object()}});
    auto rules_of = [](const Json& rules) {
        Json list = Json::array();
        if (!rules.is_array()) return list;
        for (const Json& r : rules) {
            Json row = r;
            row.erase("detail");
            list.push_back(row);
        }
        return list;
    };
    Json assets = Json::array();
    if (const Json* a = child(check, "assets"); a && a->is_array())
        for (const Json& as : *a) {
            Json j = Json::object({{"path", str(as, "path")}, {"verdict", str(as, "verdict")}});
            if (const Json* m = child(as, "measure")) j["measure"] = *m;
            if (const Json* p = child(as, "palette")) j["palette"] = *p;
            if (const Json* r = child(as, "rules")) j["rules"] = rules_of(*r);
            assets.push_back(j);
        }
    out["assets"] = assets;
    if (const Json* s = child(check, "set"); s && s->is_object())
        if (const Json* r = child(*s, "rules")) out["set"] = Json::object({{"rules", rules_of(*r)}});
    return out;
}

bool is_known_command(const CommandRegistry& registry, std::string_view text) {
    // "assets.generate_image {...}", "assets_generate_image", or a setting of assets.json ("style.outline.width")
    std::string first(text.substr(0, text.find_first_of(" {(")));
    if (registry.has(first)) return true;
    std::string dotted = first;
    if (const std::size_t u = dotted.find('_'); u != std::string::npos) dotted[u] = '.';
    if (registry.has(dotted)) return true;
    return first.rfind("style", 0) == 0 || first.rfind("assets.json", 0) == 0;
}

}  // namespace

void register_assets_review(CommandRegistry& registry, std::function<Result<AiConfig>()> load,
                            std::function<std::string()> projectDir, const AiCommandOptions& options) {
    CommandInfo info;
    info.name = "assets.review";
    info.category = "assets";
    info.summary = "A cheap one-shot vision review of the pictures you made: a verdict and concrete fixes, grounded on "
                   "assets.check_art and the style references.";
    info.description =
        "The optional last look of the make, preview, check, fix loop (docs/AI_GUIDE.md 9.23, docs/ASSETS.md "
        "\"Reviewing art\"). It runs assets.check_art on the same pictures first, then sends a vision model "
        "the pictures, the annotated picture of the check, the check's numbers, the style rules of "
        "assets.json and the style `references` images, and asks what the numbers cannot tell: does it match "
        "the style, does it read, does it suit its use. Unlike the user-only art critics of ai.review, you "
        "can call it yourself while you work. It uses the model of the \"fast\" role of ai.json (the "
        "orchestrator when fast is off; the artist role is usually an image generator, not a viewer), so the "
        "model must accept pictures; with no provider, no key or a text-only model the error says what to "
        "set up (docs/AI_PROVIDERS.md) and you carry on with assets.check_art alone. One model call per "
        "review: call it once the check shows no `fail`, not after every edit. Example: "
        "{\"paths\":[\"assets/knight.png\",\"assets/orc.png\"],\"focus\":\"do they look like the same game "
        "at 48 px?\"}" FA_COMMAND_DETAILS
        "Result: {verdict: good | fix | redo (never `good` while the check has a fail), summary, fixes: "
        "[{what, where, command}], checkArt: {verdict, counts, assets, set}, role, provider, model, "
        "warnings, nextSteps}. A fix names a command or an assets.json setting; one that names something "
        "this engine does not have is listed in `warnings`. Nothing is written to the project.";
    info.inputSchema = Json::parse(R"({"type":"object","properties":{
        "path":{"type":"string","description":"Project-relative path of the picture to review. Give this or `paths`."},
        "paths":{"type":"array","minItems":1,"maxItems":4,"items":{"type":"string"},"description":"Up to 4 pictures reviewed together, as a set. Give this or `path`."},
        "focus":{"type":"string","description":"What you want judged (\"does the outline match the references?\", \"is the coin readable on the dark floor?\"). Optional."}},
        "additionalProperties":false})");
    info.readOnly = true;  // writes nothing to the project; spends tokens
    auto opts = std::make_shared<AiCommandOptions>(options);
    registry.add(std::move(info), [&registry, load, projectDir, opts](const Json& args) -> Json {
        std::vector<std::string> paths;
        if (const Json* p = child(args, "paths"); p && p->is_array())
            for (const Json& x : *p)
                if (x.is_string()) paths.push_back(x.get<std::string>());
        if (const std::string one = str(args, "path"); !one.empty()) paths.insert(paths.begin(), one);
        if (paths.empty())
            throw CommandError("invalid_arguments", "assets.review needs a picture",
                               "Pass `path` (or `paths`), for example {\"path\":\"assets/knight.png\"}.");
        if (paths.size() > kMaxPaths)
            throw CommandError("invalid_arguments",
                               "assets.review takes at most " + std::to_string(kMaxPaths) + " pictures, got " +
                                   std::to_string(paths.size()),
                               "Review the set in groups of " + std::to_string(kMaxPaths) +
                                   ", or run assets.check_art for the numbers of a larger set.");
        const std::string dir = projectDir();
        if (dir.empty())
            throw CommandError("no_project", "assets.review needs a project", "Open a project (or pass --project).");

        // The model first: no provider is the commonest failure and costs nothing to find out.
        auto cfg = load();
        if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
        TextModelOptions mo;
        mo.role = kRoleFast;
        mo.providerFactory = opts->providerFactory;
        mo.runtime = opts->runtime;
        TextModelInfo modelInfo;
        auto model = make_vision_model(*cfg, mo, &modelInfo);
        if (!model.ok())
            throw CommandError("no_model", "assets.review needs a vision model, and " + model.error().message,
                               model.error().hint + (model.error().hint.empty() ? "" : " ") +
                                   "Meanwhile assets.check_art, assets.contact_sheet and assets.preview_in_scene give "
                                   "you the numbers and the pictures to judge yourself.");

        // The numbers, from the very same command the AI uses on its own.
        Json checkArgs = Json::object({{"paths", Json(paths)}});
        const CommandResult check = registry.call("assets.check_art", checkArgs);
        if (!check.ok) {
            const std::string msg =
                check.error.is_object() ? str(check.error, "message") : std::string("assets.check_art failed");
            const std::string hint = check.error.is_object() ? str(check.error, "hint") : std::string();
            throw CommandError("check_failed", "assets.review runs assets.check_art first, and it failed: " + msg,
                               hint.empty() ? "Fix that, then call assets.review again." : hint);
        }
        const Json summary = check_summary(check.result);

        std::vector<std::string> warnings;
        std::vector<ImageData> images;
        std::ostringstream user;

        // The house style: the rules and the reference pictures.
        const StyleParse style = load_style_guide(dir);
        Json styleJson = Json::object();
        {
            Json assetsJson = Json::parse(read_text(stdfs::path(dir) / "assets.json"), nullptr, false);
            if (assetsJson.is_object())
                if (const Json* s = child(assetsJson, "style"); s && s->is_object()) styleJson = *s;
        }
        for (const StyleProblem& p : style.problems) warnings.push_back("assets.json " + p.pointer + ": " + p.message);
        user << "## House style (assets.json `style`)\n";
        if (styleJson.empty()) {
            user << "(none set)\n";
            warnings.push_back("assets.json has no `style`, so the review has no house style or reference pictures to "
                               "compare with. Set one (docs/ASSETS.md, \"House style\").");
        } else
            user << dump_pretty(styleJson) << "\n";

        std::size_t refCount = 0;
        std::ostringstream refNames;
        for (const std::string& ref : style.guide.references) {
            if (refCount >= kMaxReferences) {
                warnings.push_back("Only the first " + std::to_string(kMaxReferences) + " style references were sent.");
                break;
            }
            auto img = picture_for_model(resolve(dir, ref), nullptr);
            if (!img.ok()) {
                warnings.push_back("Style reference '" + ref + "' was not sent: " + img.error().message);
                continue;
            }
            images.push_back(*img);
            refNames << (refCount ? ", " : "") << ref;
            ++refCount;
        }
        const std::size_t refImages = images.size();

        for (const std::string& p : paths) {
            bool shrunk = false;
            auto img = picture_for_model(resolve(dir, p), &shrunk);
            if (!img.ok())
                throw CommandError("invalid_arguments", "Cannot send '" + p + "' to the model: " + img.error().message,
                                   img.error().hint.empty() ? "Pass pictures the AI accepts (PNG, JPEG, WebP, GIF)."
                                                            : img.error().hint);
            if (shrunk)
                warnings.push_back("'" + p + "' is large, so the model saw it shrunk to " + std::to_string(kLongSide) +
                                   " px on the long side.");
            images.push_back(*img);
        }
        bool annotated = false;
        if (const Json* im = child(check.result, "$image"); im && im->is_object()) {
            auto img = picture_for_model(stdfs::path(str(*im, "path")), nullptr);
            if (img.ok()) {
                images.push_back(*img);
                annotated = true;
            } else
                warnings.push_back("The annotated picture of assets.check_art was not sent: " + img.error().message);
        }

        user << "\n## Images, in order\n";
        if (refImages) user << "1-" << refImages << ": style references (" << refNames.str() << ")\n";
        user << (refImages + 1) << (paths.size() > 1 ? "-" + std::to_string(refImages + paths.size()) : std::string())
             << ": the picture(s) under review: ";
        for (std::size_t i = 0; i < paths.size(); ++i) user << (i ? ", " : "") << paths[i];
        user << "\n";
        if (annotated) user << images.size() << ": the annotated picture of assets.check_art\n";
        user << "\n## assets.check_art result (the numbers)\n" << dump_pretty(summary) << "\n";
        const std::string focus = str(args, "focus");
        if (!focus.empty()) user << "\n## What the author wants judged\n" << focus << "\n";

        auto answer = (*model)(kSystem, user.str(), images);
        if (!answer.ok())
            throw CommandError("review_failed",
                               "The " + modelInfo.role + " model (" + modelInfo.provider + "/" + modelInfo.model +
                                   ") did not answer: " + answer.error().message,
                               answer.error().hint.empty()
                                   ? "Check `factoria ai providers` for the role '" + modelInfo.role +
                                         "', and that its model accepts pictures."
                                   : answer.error().hint);
        const Json reply = parse(json_object_in(*answer));
        const Json* fixesIn = reply.is_object() ? child(reply, "fixes") : nullptr;
        std::string verdict = reply.is_object() ? str(reply, "verdict") : std::string();
        if (!reply.is_object() || (verdict != "good" && verdict != "fix" && verdict != "redo") || !fixesIn ||
            !fixesIn->is_array())
            throw CommandError("review_failed",
                               "The " + modelInfo.role +
                                   " model did not answer with the JSON the review needs ({verdict: good | fix | redo, "
                                   "summary, fixes: [{what, where, command}]}).",
                               "Call assets.review again, or point the \"" + modelInfo.role +
                                   "\" role at a stronger vision model (docs/AI_PROVIDERS.md). Its answer began: " +
                                   answer->substr(0, 160));

        Json fixes = Json::array();
        for (const Json& f : *fixesIn) {
            if (!f.is_object() || str(f, "what").empty()) continue;
            Json row =
                Json::object({{"what", str(f, "what")}, {"where", str(f, "where")}, {"command", str(f, "command")}});
            if (row["command"].get<std::string>().empty())
                warnings.push_back("Fix '" + str(f, "what") +
                                   "' names no command or setting; use assets.generate_image {overwrite:true} or the "
                                   "assets.json `style` to apply it.");
            else if (!is_known_command(registry, row["command"].get<std::string>()))
                warnings.push_back("Fix '" + str(f, "what") + "' names '" + row["command"].get<std::string>() +
                                   "', which is not a command of this engine; find the real one with commands_list or "
                                   "docs_read assets.");
            fixes.push_back(row);
        }
        const std::string checkVerdict = str(check.result, "verdict");
        if (checkVerdict == "fail" && verdict == "good") {
            verdict = "fix";
            warnings.push_back("The model called the pictures good, but assets.check_art has a `fail`: the verdict is "
                               "fix. Fix the failing rules first (each has a hint).");
        }
        if (verdict != "good" && fixes.empty())
            warnings.push_back("The verdict is " + verdict +
                               " but the model listed no fix: read `summary`, and the hints of assets.check_art.");

        Json steps = Json::array();
        if (verdict == "good")
            steps.push_back("Nothing to change. Use the pictures; run assets.preview_in_scene once more if they are "
                            "not in a scene yet.");
        else {
            steps.push_back(verdict == "redo" ? "Make the picture again with the changes in `fixes`."
                                              : "Apply the `fixes`, one at a time, most important first.");
            steps.push_back(
                "Look at the result (assets.contact_sheet or assets.preview_in_scene), run assets.check_art until it "
                "has no fail, and call assets.review once more only if the change was large.");
        }
        Json out = Json::object({{"verdict", verdict},
                                 {"summary", str(reply, "summary")},
                                 {"fixes", fixes},
                                 {"checkArt", summary},
                                 {"role", modelInfo.role},
                                 {"provider", modelInfo.provider},
                                 {"model", modelInfo.model},
                                 {"paths", Json(paths)},
                                 {"warnings", warnings},
                                 {"nextSteps", steps}});
        return out;
    });
    // Reads the pictures and sends them to a vision model (network, spend; process when the model is a CLI agent): nothing written.
    declare_command_capabilities(registry, {{"assets.review", CapabilitySet{Capability::Read, Capability::Process,
                                                                            Capability::Network, Capability::Spend}}});
}

}  // namespace fa::ai
