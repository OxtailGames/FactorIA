#include "vfx_review.h"

#include <chrono>
#include <filesystem>
#include <memory>
#include <sstream>
#include <thread>

#include "fa/ai/text_model.h"
#include "review_util.h"
#include "util.h"

namespace fa::ai {

using namespace util;
using namespace review;
namespace stdfs = std::filesystem;

namespace {

const char* kSystem =
    "You review a visual effect (particles, a light flash) made for a game, as its VFX artist. You are given: the effect document "
    "(a *.vfx.json: parts with an `at` time, a `duration` and, for an emitter, the fields of a ParticleEmitter), the measurements of "
    "an automatic budget check (vfx.budget: live particles, overdraw in screens of quad area, a finding with a pointer for everything over "
    "the device's budget) and ONE picture: a filmstrip of the effect playing in the game, left to right and top to bottom, each tile "
    "labelled \"f<n> +<milliseconds since the effect started>\".\n"
    "Grade it against this checklist, looking at the picture and not only at the numbers:\n"
    "1. readability: does the effect read at the size the player sees it? Is the silhouette clear in the first frames, does it stand out "
    "from the backdrop (contrast, not the same colour as the floor or the character), is it too small or too busy?\n"
    "2. timing: does it hit hard at the start (anticipation, then the peak within the first 3 to 6 tiles), hold, then fade? Does it linger "
    "after the point where nothing is happening (a long tail of one or two particles), or end abruptly? Do the lights and the other parts "
    "line up with the particles?\n"
    "3. palette: few colours that agree with each other and with the game; a gradient that ends transparent rather than grey; additive "
    "blend only for light, not for smoke or dust.\n"
    "4. overdraw: stacked large soft sprites hide the scene and cost the phone's GPU. Trust the budget numbers for the count; use the "
    "picture to say which part is responsible.\n"
    "Trust the numbers for what they measure; never call the effect good when the budget has a finding.\n"
    "Every fix must be something the person making the effect can DO: a vfx.edit call {path, op, pointer, value} (op set / remove / add / "
    "move on the JSON pointer of the document, for example set /parts/0/emitter/startSize), and then vfx.budget or vfx.filmstrip to "
    "look again. Give the real pointer from the document and a concrete value, not \"make it bigger\". Never invent a command or a field.\n"
    "Answer with ONE JSON object and nothing else:\n"
    "{\"verdict\":\"good|fix|redo\",\"summary\":\"one or two sentences\","
    "\"checklist\":[{\"item\":\"readability|timing|palette|overdraw\",\"grade\":\"ok|weak|bad\",\"note\":\"what you see\"}],"
    "\"fixes\":[{\"what\":\"the problem and the change\",\"where\":\"the part and field of the document\",\"command\":\"vfx.edit {...}\"}]}\n"
    "`good`: nothing to change (fixes empty). `fix`: keep the effect, change what the fixes say. `redo`: start the effect again. "
    "At most 6 fixes, most important first.";

bool is_known_command(const CommandRegistry& registry, std::string_view text) {
    // "vfx.edit {...}", "vfx_edit"
    std::string first(text.substr(0, text.find_first_of(" {(")));
    if (registry.has(first)) return true;
    std::string dotted = first;
    if (const std::size_t u = dotted.find('_'); u != std::string::npos) dotted[u] = '.';
    return registry.has(dotted);
}

std::string failure_of(const CommandResult& r, const char* fallback, std::string* hint) {
    if (hint) *hint = r.error.is_object() ? str(r.error, "hint") : std::string();
    return r.error.is_object() ? str(r.error, "message") : std::string(fallback);
}

}  // namespace

void register_vfx_review(CommandRegistry& registry, std::function<Result<AiConfig>()> load, std::function<std::string()> projectDir,
                         const AiCommandOptions& options) {
    CommandInfo info;
    info.name = "vfx.review";
    info.category = "game";
    info.summary = "A cheap one-shot vision review of an effect: its filmstrip graded for readability, timing, palette and overdraw, with vfx.edit fixes.";
    info.description =
        "The last look of the make, film, grade, fix loop for effects (docs/PARTICLES.md \"Reviewing an "
        "effect\"). It runs vfx.budget on the document and vfx.filmstrip on the running game (so THE GAME "
        "ADVANCES by about the length of the effect, at most 3 s, and the game must have graphics), then "
        "sends a vision model the filmstrip, the budget numbers and the document with a checklist: "
        "readability at game size, timing, palette, overdraw. It uses the model of the \"fast\" role of "
        "ai.json (the orchestrator when fast is off), so the model must accept pictures; with no provider, "
        "no key or a text-only model the error says what to set up (docs/AI_PROVIDERS.md) and you carry on "
        "with vfx.budget and vfx.filmstrip, which you can read yourself. One model call per review: call it "
        "once vfx.check passes and vfx.budget has no finding, not after every edit. Example: "
        "{\"effect\":\"assets/vfx/hit.vfx.json\",\"position\":[640,360],\"focus\":\"does it read on the dark "
        "floor?\"}"
        FA_COMMAND_DETAILS
        "Result: {verdict: good | fix | redo (never `good` while vfx.budget has a finding), summary, "
        "checklist: [{item, grade, note}], fixes: [{what, where, command}], budget: {peakParticles, "
        "peakOverdraw, findings, ...}, filmstrip: {frames, columns, rows, tileWidth, tileHeight, zoom, "
        "region, position (where it was filmed), positionDefault, positionNote}, role, provider, model, "
        "warnings, nextSteps}. A fix names a command, usually a vfx.edit call; one that names something this "
        "engine does not have is listed in `warnings`. The document is not changed. Pass `picturePath` to "
        "keep the filmstrip PNG.";
    info.inputSchema = Json::parse(R"({"type":"object","required":["effect"],"properties":{
        "effect":{"type":"string","description":"Project path of the effect document, e.g. \"assets/vfx/hit.vfx.json\"."},
        "position":{"type":"array","items":{"type":"number"},"description":"[x, y] or [x, y, z]: where in the game the effect is filmed, in world units (as vfx.filmstrip). Default: the middle of the view in a 2D game, the point 5 m in front of the main camera in a 3D game (`filmstrip.position` and `filmstrip.positionNote` say which)."},
        "preset":{"type":"string","enum":["phone","desktop"],"description":"Whose budget the review uses (as vfx.budget). Default phone."},
        "frames":{"type":"integer","minimum":2,"maximum":64,"description":"Pictures in the filmstrip (as vfx.filmstrip). Default 12."},
        "focus":{"type":"string","description":"What you want judged (\"does it read on the dark floor?\", \"is the hit too long?\"). Optional."},
        "picturePath":{"type":"string","description":"Keep the filmstrip PNG here (project-relative or absolute). Without it the picture is deleted after the review."}},
        "additionalProperties":false})");
    info.readOnly = false;  // the game advances while the effect is filmed (it writes nothing to the project)
    auto opts = std::make_shared<AiCommandOptions>(options);
    registry.add(std::move(info), [&registry, load, projectDir, opts](const Json& args) -> Json {
        const std::string effect = str(args, "effect");
        if (effect.empty()) throw CommandError("invalid_arguments", "vfx.review needs an effect", "Pass `effect`, for example {\"effect\":\"assets/vfx/hit.vfx.json\"}.");
        const std::string dir = projectDir();
        if (dir.empty()) throw CommandError("no_project", "vfx.review needs a project", "Open a project (or pass --project).");

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
            throw CommandError("no_model", "vfx.review needs a vision model, and " + model.error().message,
                               model.error().hint + (model.error().hint.empty() ? "" : " ") +
                                   "Meanwhile vfx.check, vfx.budget and vfx.filmstrip give you the problems, the numbers and the picture to judge yourself.");

        // The numbers, from the very same commands the AI uses on its own. The budget needs no graphics, so it goes first.
        Json budgetArgs = Json::object({{"path", effect}});
        if (const std::string preset = str(args, "preset"); !preset.empty()) budgetArgs["preset"] = preset;
        const CommandResult budget = registry.call("vfx.budget", budgetArgs);
        if (!budget.ok) {
            std::string hint;
            const std::string msg = failure_of(budget, "vfx.budget failed", &hint);
            throw CommandError("budget_failed", "vfx.review runs vfx.budget first, and it failed: " + msg, hint.empty() ? "vfx.check lists every problem of the file; fix them, then call vfx.review again." : hint);
        }

        // The picture: the effect playing in the game. A temporary file is ours to delete once the model has it.
        Json filmArgs = Json::object({{"effect", effect}});
        for (const char* key : {"position", "frames"})
            if (const Json* v = child(args, key)) filmArgs[key] = *v;
        const std::string keep = str(args, "picturePath");
        if (!keep.empty()) filmArgs["path"] = keep;
        const CommandResult film = registry.call("vfx.filmstrip", filmArgs);
        if (!film.ok) {
            std::string hint;
            const std::string msg = failure_of(film, "vfx.filmstrip failed", &hint);
            throw CommandError("film_failed", "vfx.review films the effect with vfx.filmstrip first, and it failed: " + msg,
                               (hint.empty() ? std::string("Fix that, then call vfx.review again.") : hint) +
                                   " The numbers of vfx.budget alone are in the result of vfx.budget {\"path\":\"" + effect + "\"}.");
        }
        std::string picture;
        bool temporary = false;
        if (const Json* im = child(film.result, "$image"); im && im->is_object()) {
            picture = str(*im, "path");
            temporary = flag(*im, "temporary", false);
        }
        struct Cleanup {
            std::string path;
            bool armed = false;
            ~Cleanup() {
                if (armed && !path.empty()) {
                    // On Windows a scanner (antivirus, the indexer) may hold the new PNG open for a moment: try again a few times.
                    for (int attempt = 0; attempt < 3; ++attempt) {
                        std::error_code ec;
                        stdfs::remove(path, ec);
                        if (!ec || !stdfs::exists(path, ec)) break;
                        std::this_thread::sleep_for(std::chrono::milliseconds(60));
                    }
                }
            }
        } cleanup{picture, temporary};
        std::vector<std::string> warnings;
        bool shrunk = false;
        auto img = picture_for_model(stdfs::path(picture), &shrunk);
        if (!img.ok())
            throw CommandError("film_failed", "The filmstrip picture cannot be sent to the model: " + img.error().message,
                               img.error().hint.empty() ? "Call vfx.review again, or look at the picture of vfx.filmstrip yourself." : img.error().hint);
        if (shrunk) warnings.push_back("The filmstrip is large, so the model saw it shrunk to " + std::to_string(kLongSide) + " px on the long side: small details may be lost. Pass a smaller `frames`.");

        // What the model reads: the document (so its fixes point at real fields), the numbers, how the picture is laid out.
        const Json& bj = budget.result;
        std::ostringstream user;
        user << "## The effect document (" << effect << ")\n" << read_text(resolve(dir, effect)) << "\n";
        user << "\n## vfx.budget result (the numbers; overdraw is in screens of quad area, 1.0 = the view covered once)\n" << dump_pretty(bj) << "\n";
        user << "\n## The picture\nA filmstrip: " << num(film.result, "columns") << " columns x " << num(film.result, "rows") << " rows, tiles "
             << num(film.result, "tileWidth") << " x " << num(film.result, "tileHeight") << " px, read left to right and top to bottom; each tile is labelled with the time since the effect started.\n";
        if (const Json* fr = child(film.result, "frames")) user << "Frames: " << dump(*fr) << "\n";
        const std::string focus = str(args, "focus");
        if (!focus.empty()) user << "\n## What the author wants judged\n" << focus << "\n";

        auto answer = (*model)(kSystem, user.str(), {*img});
        if (!answer.ok())
            throw CommandError("review_failed", "The " + modelInfo.role + " model (" + modelInfo.provider + "/" + modelInfo.model + ") did not answer: " + answer.error().message,
                               answer.error().hint.empty() ? "Check `factoria ai providers` for the role '" + modelInfo.role + "', and that its model accepts pictures." : answer.error().hint);
        const Json reply = parse(json_object_in(*answer));
        const Json* fixesIn = reply.is_object() ? child(reply, "fixes") : nullptr;
        std::string verdict = reply.is_object() ? str(reply, "verdict") : std::string();
        if (!reply.is_object() || (verdict != "good" && verdict != "fix" && verdict != "redo") || !fixesIn || !fixesIn->is_array())
            throw CommandError("review_failed",
                               "The " + modelInfo.role + " model did not answer with the JSON the review needs ({verdict: good | fix | redo, summary, checklist, fixes: [{what, where, command}]}).",
                               "Call vfx.review again, or point the \"" + modelInfo.role + "\" role at a stronger vision model (docs/AI_PROVIDERS.md). Its answer began: " +
                                   answer->substr(0, 160));

        Json fixes = Json::array();
        for (const Json& f : *fixesIn) {
            if (!f.is_object() || str(f, "what").empty()) continue;
            Json row = Json::object({{"what", str(f, "what")}, {"where", str(f, "where")}, {"command", str(f, "command")}});
            if (row["command"].get<std::string>().empty())
                warnings.push_back("Fix '" + str(f, "what") + "' names no command; apply it with vfx.edit {path, op, pointer, value}.");
            else if (!is_known_command(registry, row["command"].get<std::string>()))
                warnings.push_back("Fix '" + str(f, "what") + "' names '" + row["command"].get<std::string>() + "', which is not a command of this engine; the editing command is vfx.edit.");
            fixes.push_back(row);
        }
        Json checklist = Json::array();
        if (const Json* c = child(reply, "checklist"); c && c->is_array())
            for (const Json& item : *c) {
                if (!item.is_object() || str(item, "item").empty()) continue;
                checklist.push_back(Json::object({{"item", str(item, "item")}, {"grade", str(item, "grade")}, {"note", str(item, "note")}}));
            }
        const bool overBudget = child(budget.result, "findings") && !(*child(budget.result, "findings")).empty();
        if (overBudget && verdict == "good") {
            verdict = "fix";
            warnings.push_back("The model called the effect good, but vfx.budget has findings: the verdict is fix. Apply the `fix` of each finding of `budget.findings` first.");
        }
        if (verdict != "good" && fixes.empty()) warnings.push_back("The verdict is " + verdict + " but the model listed no fix: read `summary`, `checklist` and the findings of vfx.budget.");

        Json steps = Json::array();
        if (verdict == "good") steps.push_back("Nothing to change. Use the effect (vfx.play, or a Vfx component in a scene).");
        else {
            steps.push_back(verdict == "redo" ? "Start the effect again with the changes in `fixes` (vfx.create {overwrite:true}, then vfx.edit)." : "Apply the `fixes` with vfx.edit, one at a time, most important first.");
            steps.push_back("Look again (vfx.filmstrip, vfx.budget) and call vfx.review once more only if the change was large.");
        }
        Json summaryBudget = budget.result;
        summaryBudget.erase("timeline");
        Json out = Json::object({{"verdict", verdict}, {"summary", str(reply, "summary")}, {"checklist", checklist}, {"fixes", fixes},
                                 {"budget", summaryBudget}, {"role", modelInfo.role}, {"provider", modelInfo.provider}, {"model", modelInfo.model},
                                 {"effect", effect}, {"warnings", warnings}, {"nextSteps", steps}});
        Json filmOut = Json::object();
        for (const char* key : {"frames", "columns", "rows", "tileWidth", "tileHeight", "zoom", "region", "everyFrames", "position", "positionDefault", "positionNote"})
            if (const Json* v = child(film.result, key)) filmOut[key] = *v;
        if (!keep.empty()) filmOut["path"] = str(film.result, "path");
        out["filmstrip"] = filmOut;
        return out;
    });
    // The game advances while the effect is filmed (state); one vision-model call (network, spend, process for a CLI agent). `picturePath` is written by
    // vfx.filmstrip, which asks for writeProject itself (and writeAnywhere outside the project) when the path is given.
    declare_command_capabilities(registry, {{"vfx.review", CapabilitySet{Capability::Read, Capability::State, Capability::Process, Capability::Network, Capability::Spend}}});
}

}  // namespace fa::ai
