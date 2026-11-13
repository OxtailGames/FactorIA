// model.preview and model.check: looking at a model document (docs/MODELING.md, "Looking at a model"). The preview is a turntable sheet drawn by
// the software rasterizer of fa/tooling/model_view.h (no graphics device, the same pixels everywhere); the check measures the mesh with
// fa/scene/model_check.h. Both look at the mesh the game gets: the evaluated document with its `gameReady` origin and merge applied.
#include <algorithm>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "assets_shots.h"
#include "fa/core/strings.h"
#include "fa/scene/model_check.h"
#include "fa/scene/model_game_ready.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/model_view.h"
#include "fa/tooling/project_fs.h"
#include "picture_canvas.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

using picture::Canvas;
using picture::Rgb;

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json vec3_json(Vec3 v) { return Json::array({round_to(v.x, 4), round_to(v.y, 4), round_to(v.z, 4)}); }
Json str_prop(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json bool_prop(const char* what, bool def) {
    return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}});
}
Json num_prop(const char* what, double def, double lo, double hi) {
    return Json::object(
        {{"type", "number"}, {"default", def}, {"minimum", lo}, {"maximum", hi}, {"description", what}});
}
Json list_prop(const char* what) {
    return Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}, {"description", what}});
}

double number_arg(const char* command, const Json& a, const char* key, double def, double lo, double hi,
                  const char* hint) {
    if (!a.contains(key) || a[key].is_null()) return def;
    if (!a[key].is_number())
        fail("invalid_argument",
             std::string(command) + ": `" + key + "` must be a number, got " + describe_json_value(a[key]) + ".", hint);
    const double v = a[key].get<double>();
    if (!(v >= lo && v <= hi))
        fail("invalid_argument", std::format("{}: `{}` must be from {} to {}, got {}.", command, key, lo, hi, v), hint);
    return v;
}

std::string model_path_arg(const char* command, const std::string& arg) {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string(command) + ": `path` '" + arg + "' is not a model document under assets/.",
             "Model documents live in assets/, e.g. \"assets/models/door.model.json\" (model.create writes one).");
    if (!ends_with(to_lower(*norm), kModelDocSuffix))
        fail("invalid_argument", std::string(command) + ": '" + *norm + "' does not end in .model.json.",
             "Name model documents <name>.model.json, e.g. \"assets/models/door.model.json\".");
    return *norm;
}

[[noreturn]] void invalid_doc(const std::string& rel, const Error& error, const std::vector<ModelIssue>& issues) {
    Json list = Json::array();
    for (const ModelIssue& i : issues)
        list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    throw CommandError("invalid_document", error.message,
                       error.hint.empty() ? "model.info {\"path\": ...} checks a document and lists every issue."
                                          : error.hint,
                       Json::object({{"path", rel}, {"issues", list}}));
}

// The mesh a document gives the game, and what it came from.
struct Subject {
    std::string label;  // the path, or "document"
    ModelDoc doc;
    ModelBuild build;
    MeshData
        mesh;  // the evaluated mesh with the gameReady origin and merge applied (the evaluated mesh when the document has none)
    bool shipped = false;                   // the document has gameReady settings and `mesh` is the one they give
    std::vector<std::size_t> lodTriangles;  // LOD1.. when the settings ask for LODs
    std::vector<std::string> warnings;
};

Subject load_subject(const char* command, const std::string& projectDir, const Json& a, bool wantLods) {
    const bool hasPath = a.contains("path") && !a["path"].is_null(),
               hasDoc = a.contains("document") && !a["document"].is_null();
    if (hasPath == hasDoc)
        fail("invalid_argument",
             std::string(command) + (hasPath ? ": give `path` or `document`, not both."
                                             : ": give `path` (a .model.json file) or `document` (the JSON itself)."),
             "Example: {\"path\":\"assets/models/door.model.json\"}.");
    Subject s;
    Json json;
    if (hasPath) {
        if (!a["path"].is_string())
            fail("invalid_argument",
                 std::string(command) + ": `path` must be text, got " + describe_json_value(a["path"]) + ".",
                 "Example: \"assets/models/door.model.json\".");
        s.label = model_path_arg(command, a["path"].get<std::string>());
        auto text = tooling_detail::read_file(project_file(projectDir, s.label));
        if (!text) {
            const std::vector<std::string> all = list_model_documents(projectDir);
            fail("not_found", "'" + s.label + "' does not exist.",
                 all.empty() ? "Make one with model.create {\"path\":\"" + s.label + "\"}."
                             : did_you_mean(s.label, all) + " Model documents: " + join(all, ", ") + ".");
        }
        auto parsed = parse_json(*text, s.label);
        if (!parsed.ok())
            fail("invalid_document", parsed.error().message,
                 parsed.error().hint.empty() ? "Fix the JSON syntax; schemas/model.schema.json describes the format."
                                             : parsed.error().hint);
        json = std::move(*parsed);
    } else {
        if (!a["document"].is_object())
            fail("invalid_argument", std::string(command) + ": `document` must be an object.",
                 "Start from {\"format\":\"factoria.model/1\",\"nodes\":[{\"op\":\"box\"}]}.");
        json = a["document"];
        if (!json.contains("format")) json["format"] = kModelDocFormat;
        s.label = "document";
    }
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(json, s.label, &issues);
    if (!doc.ok()) invalid_doc(hasPath ? s.label : std::string(), doc.error(), issues);
    s.doc = std::move(*doc);
    {
        ProjectRootGuard root(projectDir);
        auto built = evaluate_model(s.doc, model_project_eval_options(projectDir));
        if (!built.ok()) fail("failed", s.label + ": " + built.error().message, built.error().hint);
        s.build = std::move(*built);
    }
    s.mesh = s.build.data;
    if (!s.doc.gameReady.is_null()) {
        auto g = parse_game_ready(s.doc.gameReady, "/gameReady");
        if (!g.ok()) fail("invalid_document", g.error().message, g.error().hint);
        ModelGameReady settings = *g;
        settings.collider = ModelColliderSpec{};
        settings.collider.shape = "none";
        if (!wantLods) settings.lods.clear();
        auto made = make_game_ready(s.build.data, settings);
        if (!made.ok()) fail("failed", s.label + ": gameReady: " + made.error().message, made.error().hint);
        s.mesh = std::move(made->mesh);
        s.shipped = true;
        for (std::size_t i = 1; i < made->lodInfo.size(); ++i) s.lodTriangles.push_back(made->lodInfo[i].triangles);
    }
    return s;
}

Json bounds_json(Vec3 lo, Vec3 hi) {
    return obj({{"min", vec3_json(lo)}, {"max", vec3_json(hi)}, {"size", vec3_json(hi - lo)}});
}

std::vector<std::string> string_list(const char* command, const Json& a, const char* key,
                                     const std::vector<std::string>& allowed, const char* what) {
    std::vector<std::string> out;
    if (!a.contains(key) || a[key].is_null()) return out;
    if (!a[key].is_array())
        fail("invalid_argument",
             std::string(command) + ": `" + key + "` must be a list of " + what + ", got " +
                 describe_json_value(a[key]) + ".",
             "Allowed: " + join(allowed, ", ") + ".");
    for (std::size_t i = 0; i < a[key].size(); ++i) {
        const Json& v = a[key][i];
        if (!v.is_string() || std::find(allowed.begin(), allowed.end(), v.get<std::string>()) == allowed.end())
            fail("invalid_argument",
                 std::format("{}: `{}`[{}] is {}, not one of the {}.", command, key, i, describe_json_value(v), what),
                 v.is_string() ? did_you_mean(v.get<std::string>(), allowed) : "Allowed: " + join(allowed, ", ") + ".");
        if (std::find(out.begin(), out.end(), v.get<std::string>()) == out.end()) out.push_back(v.get<std::string>());
    }
    return out;
}

// ---- model.check ----

Json finding_json(const ModelFinding& f) {
    Json j = obj({{"code", f.code}, {"severity", f.severity}, {"message", f.message}, {"hint", f.hint}});
    if (!f.platform.empty()) j["platform"] = f.platform;
    if (f.count > 0) {
        j["count"] = f.count;
        j["bounds"] = obj({{"min", vec3_json(f.bmin)}, {"max", vec3_json(f.bmax)}});
        Json samples = Json::array();
        for (const Vec3& p : f.samples) samples.push_back(vec3_json(p));
        j["samples"] = samples;
    }
    if (!f.parts.empty()) j["parts"] = f.parts;
    return j;
}

Json check_catalog() {
    Json kinds = Json::array();
    for (const ModelCheckKind& k : model_check_kinds())
        kinds.push_back(obj({{"code", k.code}, {"severity", k.severity}, {"doc", k.doc}}));
    Json budgets = Json::array();
    for (const ModelPlatformBudget& b : model_platform_budgets())
        budgets.push_back(
            obj({{"platform", b.platform}, {"triangles", b.triangles}, {"submeshes", b.submeshes}, {"doc", b.doc}}));
    return obj(
        {{"checks", kinds},
         {"platformBudgets", budgets},
         {"referenceFigure", obj({{"height", kModelReferenceHeight},
                                  {"doc", "model.preview draws a figure of this height beside the model; model.check "
                                          "compares the height with `expectedHeight` when given."}})},
         {"nextSteps",
          Json::array({"model.check {\"path\":\"assets/models/crate.model.json\"} measures a document and lists what "
                       "is wrong with it, each finding with where, what and how to fix.",
                       "model.preview {\"path\":...} draws it from several sides beside a 1.8 m figure."})}});
}

Json model_check_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.check", a, "",
                   {"path", "document", "expectedHeight", "tolerance", "platforms", "ignore", "samples"});
    if (!a.contains("path") && !a.contains("document")) return check_catalog();
    ModelCheckOptions o;
    std::vector<std::string> platformNames, codes;
    for (const ModelPlatformBudget& b : model_platform_budgets()) platformNames.push_back(b.platform);
    for (const ModelCheckKind& k : model_check_kinds()) codes.push_back(k.code);
    o.platforms = string_list("model.check", a, "platforms", platformNames, "platforms");
    o.ignore = string_list("model.check", a, "ignore", codes, "check codes");
    o.expectedHeight =
        number_arg("model.check", a, "expectedHeight", 0, 0, 10000,
                   "The height (Y) the model should have, in metres: 1.8 for a person, 0.75 for a table.");
    o.tolerance = number_arg("model.check", a, "tolerance", 0.25, 0.01, 10,
                             "A fraction of expectedHeight: 0.25 accepts 1.35 to 2.25 m for 1.8.");
    o.maxSamples =
        std::size_t(number_arg("model.check", a, "samples", 6, 0, 50, "Sample positions listed per finding."));
    Subject s = load_subject("model.check", projectDir, a, true);
    o.lodTriangles = s.lodTriangles;
    const ModelCheckReport r = check_model_mesh(s.mesh, o);

    Json findings = Json::array();
    for (const ModelFinding& f : r.findings) findings.push_back(finding_json(f));
    Json result = obj({{"path", s.label},
                       {"ok", r.ok()},
                       {"errors", r.errors},
                       {"warnings", r.warnings},
                       {"infos", r.infos},
                       {"findings", findings}});
    result["mesh"] = obj({{"triangles", r.triangles},
                          {"vertices", r.vertices},
                          {"submeshes", r.submeshes},
                          {"pieces", r.pieces},
                          {"bounds", bounds_json(r.scale.bmin, r.scale.bmax)},
                          {"height", round_to(r.scale.height, 4)},
                          {"heightVersusFigure", round_to(r.scale.versusFigure, 3)},
                          {"closedVolume", round_to(r.scale.volume, 5)},
                          {"openEdges", r.openEdges},
                          {"nonManifoldEdges", r.nonManifoldEdges},
                          {"inconsistentEdges", r.inconsistentEdges},
                          {"degenerateTriangles", r.degenerateTriangles},
                          {"flippedNormalTriangles", r.flippedNormalTriangles},
                          {"insideOutPieces", r.insideOutPieces}});
    Json platforms = Json::array();
    const std::vector<std::string> used = o.platforms.empty() ? platformNames : o.platforms;
    for (const std::string& p : used) platforms.push_back(p);
    result["checked"] = obj({{"platforms", platforms},
                             {"expectedHeight", o.expectedHeight > 0 ? Json(o.expectedHeight) : Json()},
                             {"mesh", s.shipped ? "gameReady" : "evaluated"}});
    Json steps = Json::array();
    if (r.findings.empty())
        steps.push_back("Nothing found. model.preview {\"path\":\"" + s.label +
                        "\"} draws the model beside a 1.8 m figure for the check no number replaces: how it looks.");
    else {
        steps.push_back(
            "Fix the errors first (they make the model wrong), then the warnings; each finding's `hint` says how and "
            "its `samples` and `bounds` say where. model.preview with `part` highlights one part.");
        steps.push_back("After editing the document (model.edit), run model.check again; a finding that is intended "
                        "(an open surface) can be listed in `ignore`.");
    }
    result["nextSteps"] = steps;
    return result;
}

// ---- model.preview ----

constexpr int kHeader = 52, kPad = 8;

std::string with_commas(std::size_t n) {
    std::string digits = std::to_string(n), out;
    for (std::size_t i = 0; i < digits.size(); ++i) {
        if (i > 0 && (digits.size() - i) % 3 == 0) out += ',';
        out += digits[i];
    }
    return out;
}

Json model_preview_command(const std::string& projectDir, const Json& a) {
    check_arg_keys(
        "model.preview", a, "",
        {"path", "document", "views", "yaw", "pitch", "cell", "mode", "figure", "ground", "part", "out", "overwrite"});
    if (!a.contains("path") && !a.contains("document"))
        fail("invalid_argument", "model.preview: give `path` (a .model.json file) or `document` (the JSON itself).",
             "Example: {\"path\":\"assets/models/door.model.json\"}.");
    const int views = int(number_arg("model.preview", a, "views", 6, 4, 8,
                                     "How many sides to draw, 4 to 8, evenly spaced around the model."));
    if (a.contains("views") && a["views"].is_number() &&
        a["views"].get<double>() != std::floor(a["views"].get<double>()))
        fail("invalid_argument", "model.preview: `views` must be a whole number from 4 to 8.", "Example: 6.");
    const double yaw =
        number_arg("model.preview", a, "yaw", 30, -360, 360,
                   "The angle of the first view, in degrees: 0 looks at the model's +Z side, 90 at its +X side.");
    const double pitch = number_arg("model.preview", a, "pitch", 20, -80, 80, "Degrees above the horizon, -80 to 80.");
    const int cell = int(number_arg("model.preview", a, "cell", 320, 96, 640, "Pixels per side of each view."));
    const std::vector<std::string> modes = {"shaded", "wireframe", "shaded_wireframe"};
    std::string mode = "shaded";
    if (a.contains("mode") && !a["mode"].is_null()) {
        if (!a["mode"].is_string() ||
            std::find(modes.begin(), modes.end(), a["mode"].get<std::string>()) == modes.end())
            fail("invalid_argument",
                 "model.preview: `mode` is " + describe_json_value(a["mode"]) +
                     ", not one of shaded, wireframe, shaded_wireframe.",
                 a["mode"].is_string() ? did_you_mean(a["mode"].get<std::string>(), modes)
                                       : "shaded draws surfaces, wireframe the triangle edges (hidden edges stay "
                                         "hidden), shaded_wireframe both.");
        mode = a["mode"].get<std::string>();
    }
    const bool figure = tooling_detail::arg_bool(a, "figure", true),
               ground = tooling_detail::arg_bool(a, "ground", true);
    std::string outRel;
    stdfs::path outFile;
    if (a.contains("out") && !a["out"].is_null()) {
        if (!a["out"].is_string() || a["out"].get<std::string>().empty() ||
            to_lower(fs::extension(a["out"].get<std::string>())) != ".png")
            fail("invalid_argument", "model.preview: `out` must be a project-relative path ending in .png.",
                 "Example: \"docs/review/crate.png\". Leave it out to only look at the picture (nothing is written to "
                 "the project).");
        // The caller names a file: it needs writeProject and must stay inside the project (never .git or .factoria).
        outFile = caller_output_file(projectDir, a["out"].get<std::string>(), "model.preview");
        outRel = output_spelling(a["out"].get<std::string>());
        std::error_code ec;
        if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(outFile, ec))
            fail("exists", "'" + outRel + "' already exists.",
                 "Pass overwrite: true to replace it, or choose another `out`.");
    }

    Subject s = load_subject("model.preview", projectDir, a, false);
    std::string highlight;
    if (a.contains("part") && !a["part"].is_null()) {
        if (!a["part"].is_string())
            fail("invalid_argument", "model.preview: `part` must be text, got " + describe_json_value(a["part"]) + ".",
                 "A part name of the model, e.g. \"wheel\".");
        highlight = a["part"].get<std::string>();
        std::vector<std::string> names;
        for (const MeshSubmesh& sm : s.mesh.submeshes)
            if (!sm.part.empty()) names.push_back(sm.part);
        if (std::find(names.begin(), names.end(), highlight) == names.end())
            fail("invalid_argument", "model.preview: the model has no part \"" + highlight + "\".",
                 names.empty() ? "This model names no parts (give nodes a `part`)."
                               : did_you_mean(highlight, names) + " Parts: " + join(names, ", ") + ".");
    }

    // The model and, beside it, the reference figure; every view frames both the same way so the scale reads across the sheet.
    const MeshData& figureMesh = model_reference_figure();
    ModelViewItem modelItem;
    modelItem.mesh = &s.mesh;
    modelItem.highlightPart = highlight;
    ModelViewItem figureItem;
    figureItem.mesh = &figureMesh;
    figureItem.flat = true;
    figureItem.wire = false;
    figureItem.flatColor = Color{0.45f, 0.62f, 0.85f, 1};
    Vec3 lo{}, hi{};
    if (s.mesh.positions.size() >= 3) {
        lo = hi = {s.mesh.positions[0], s.mesh.positions[1], s.mesh.positions[2]};
        for (std::size_t i = 0; i + 2 < s.mesh.positions.size(); i += 3) {
            lo = min(lo, Vec3{s.mesh.positions[i], s.mesh.positions[i + 1], s.mesh.positions[i + 2]});
            hi = max(hi, Vec3{s.mesh.positions[i], s.mesh.positions[i + 1], s.mesh.positions[i + 2]});
        }
    }
    std::vector<ModelViewItem> items = {modelItem};
    if (figure && !figureMesh.positions.empty()) {
        figureItem.offset = reference_figure_offset(lo, hi);
        items.push_back(figureItem);
    }
    const ModelViewFrame frame = frame_model_items(items);

    const int columns = views <= 4 ? 2 : views <= 6 ? 3 : 4;
    const int rows = (views + columns - 1) / columns;
    const int width = columns * cell + (columns + 1) * kPad, height = kHeader + rows * (cell + 20) + (rows + 1) * kPad;
    Canvas canvas(width, height, {22, 24, 28});

    ModelViewOptions vo;
    vo.width = vo.height = cell;
    vo.pitchDeg = pitch;
    vo.shaded = mode != "wireframe";
    vo.wireframe = mode != "shaded";
    vo.ground = ground;
    vo.center = frame.center;
    vo.radius = frame.radius;
    vo.supersample = cell > 480 ? 1 : 2;
    Json viewList = Json::array();
    for (int i = 0; i < views; ++i) {
        vo.yawDeg = yaw + 360.0 * i / views;
        const Image cellImage = render_model_view(items, vo);
        const int col = i % columns, row = i / columns;
        const int x = kPad + col * (cell + kPad), y = kHeader + kPad + row * (cell + 20 + kPad);
        draw_over(canvas.img, cellImage, x, y);
        canvas.rect(x, y + cell, x + cell - 1, y + cell + 19, {30, 33, 39});
        const double shown = std::fmod(std::fmod(vo.yawDeg, 360.0) + 360.0, 360.0);
        canvas.text(std::format("yaw {:.0f}  pitch {:.0f}", shown, pitch), x + 6, y + cell + 10, 12, {170, 178, 190}, 0,
                    true);
        viewList.push_back(obj({{"yaw", round_to(shown, 2)}, {"pitch", pitch}}));
    }

    const Vec3 size = hi - lo;
    std::size_t partCount = 0;
    Json parts = Json::array();
    for (const ModelPartInfo& p : s.build.parts) {
        ++partCount;
        parts.push_back(obj({{"part", p.part}, {"triangles", p.triangles}}));
    }
    canvas.text(s.label, kPad + 2, 6, 17, {235, 238, 245});
    canvas.text(std::format("{} triangles   {:.2f} x {:.2f} x {:.2f} m (x, y, z)   {} part{}   {}",
                            with_commas(s.mesh.triangle_count()), size.x, size.y, size.z, partCount,
                            partCount == 1 ? "" : "s",
                            mode == "shaded"      ? "shaded"
                            : mode == "wireframe" ? "wireframe"
                                                  : "shaded + wireframe"),
                kPad + 2, 28, 13, {185, 192, 204});
    if (figure)
        canvas.text("blue figure: 1.8 m   red: the inside of a surface", width - kPad - 2, 8, 13, {120, 160, 215}, 2);
    if (!highlight.empty()) canvas.text("orange: " + highlight, width - kPad - 2, 28, 13, {255, 160, 30}, 2);

    Json result = obj({{"path", s.label}});
    result["stats"] = obj({{"triangles", s.mesh.triangle_count()},
                           {"vertices", s.mesh.vertex_count()},
                           {"submeshes", s.mesh.submeshes.size()},
                           {"bounds", bounds_json(lo, hi)},
                           {"heightVersusFigure", round_to(double(size.y) / kModelReferenceHeight, 3)},
                           {"parts", parts},
                           {"mesh", s.shipped ? "gameReady" : "evaluated"}});
    result["views"] = viewList;
    result["mode"] = mode;
    result["picture"] = obj({{"width", canvas.img.width},
                             {"height", canvas.img.height},
                             {"cell", cell},
                             {"columns", columns},
                             {"rows", rows}});
    if (!outRel.empty()) {
        const std::vector<std::uint8_t> png = encode_png(canvas.img);
        std::string err;
        const stdfs::path& out = outFile;
        if (!tooling_detail::write_file(out, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()),
                                        &err))
            fail("failed", err);
        result["written"] = outRel;
        result["$image"] = image_member(out, false);
    } else {
        result["$image"] = image_member(write_temporary_picture(projectDir, canvas.img, "model"), true);
    }
    Json steps = Json::array();
    steps.push_back("Read the sheet: the model beside the 1.8 m figure from " + std::to_string(views) +
                    " sides, the grid on the ground y = 0 with the origin's two axes brighter (x warm, z cool). A dark "
                    "red surface is seen from inside: model.check finds what is flipped.");
    if (mode == "shaded")
        steps.push_back("mode \"shaded_wireframe\" shows the triangles; `part` highlights one part in orange.");
    steps.push_back("model.check {\"path\":\"" + s.label +
                    "\"} measures what the picture cannot: open edges, flipped triangles, the platform budgets.");
    if (outRel.empty()) steps.push_back("Pass `out` to keep the picture as a PNG in the project.");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_model_eyes_commands(CommandRegistry& registry, const std::string& projectDir) {
    const Json pathProp = str_prop("The model document, project-relative, under assets/, ending in .model.json.");
    const Json docProp =
        Json::object({{"type", "object"},
                      {"description", "The document itself, as JSON, instead of a file (format is filled in)."}});
    {
        CommandInfo info;
        info.name = "model.preview";
        info.category = "assets";
        info.summary = "Draw a model document from 4 to 8 sides (a turntable sheet, shaded and/or wireframe) beside a "
                       "1.8 m reference figure, with its triangle count and size; returns the PNG.";
        info.description =
            "The way to SEE a model. It builds the document in memory and draws it with a software renderer (no "
            "graphics device, the same pixels on every machine): one picture with `views` sides evenly spaced around "
            "the model, starting at `yaw`, "
            "seen from `pitch` degrees above the horizon, each framed the same way so sizes compare across the sheet. "
            "A blue 1.8 m figure stands beside the model on the ground (turn it off with figure false) and a grid lies "
            "on y = 0 with the "
            "origin's axes brighter, so scale, how it stands and where its origin is can be read at once. The header "
            "gives the triangle count, the size in metres and the number of parts. A dark red surface is one seen from "
            "inside "
            "(a flipped triangle). `mode` is \"shaded\", \"wireframe\" (the triangle edges; hidden ones stay hidden) "
            "or \"shaded_wireframe\"; `part` draws one part in orange. "
            "It draws the mesh the game gets: with `gameReady` settings in the document, their origin and merge are "
            "applied. The picture is returned as $image in a temporary file; pass `out` (a project-relative .png) to "
            "keep it. "
            "Nothing in the project changes otherwise (a caller that may not write the project cannot use `out`). "
            "Example: {\"path\":\"assets/models/crate.model.json\",\"views\":4,\"mode\":\"shaded_wireframe\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"properties",
              obj({{"path", pathProp},
                   {"document", docProp},
                   {"views",
                    num_prop("How many sides to draw, 4 to 8, evenly spaced around the model (a whole number).", 6, 4,
                             8)},
                   {"yaw",
                    num_prop(
                        "The angle of the first view in degrees: 0 looks at the model's +Z side, 90 at its +X side.",
                        30, -360, 360)},
                   {"pitch", num_prop("Degrees above the horizon.", 20, -80, 80)},
                   {"cell", num_prop("Pixels per side of each view.", 320, 96, 640)},
                   {"mode",
                    Json::object({{"type", "string"},
                                  {"enum", Json::array({"shaded", "wireframe", "shaded_wireframe"})},
                                  {"default", "shaded"},
                                  {"description",
                                   "shaded draws surfaces, wireframe the triangle edges, shaded_wireframe both."}})},
                   {"figure", bool_prop("Draw the 1.8 m reference figure beside the model.", true)},
                   {"ground", bool_prop("Draw the grid on y = 0.", true)},
                   {"part", str_prop("A part of the model to draw in orange.")},
                   {"out",
                    Json::object({{"type", "string"},
                                  {"x-fa-path", "write"},
                                  {"description", "Keep the picture as a PNG at this project-relative path (ending in "
                                                  ".png; needs the writeProject capability, never inside .git or "
                                                  ".factoria). Left out, it is a temporary file."}})},
                   {"overwrite", bool_prop("Replace the file at `out` if it exists.", false)}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        registry.add(info, [projectDir](const Json& args) {
            return model_preview_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    {
        CommandInfo info;
        info.name = "model.check";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Measure a model document's mesh for faults an artist finds by eye: scale, origin, flipped or "
                       "inconsistent triangles, open and non-manifold edges, degenerate triangles, platform budgets. "
                       "Each finding says where, what and how to fix.";
        info.description =
            "Builds the document in memory and checks the mesh the game gets (the evaluated mesh, with the "
            "`gameReady` origin and merge applied). Findings, errors first: `inside_out` (a closed piece "
            "whose triangles all face inward), `inconsistent_winding` (neighbouring triangles disagree on "
            "the side that is out), `non_manifold` (an edge of more than two triangles), then warnings: "
            "`flipped_normals`, `open_edges` (holes: the model is not a closed solid), `degenerate` "
            "(triangles with no area), `scale` (the height differs from `expectedHeight` by more than "
            "`tolerance`, or, with no expectation, the largest side is under 2 cm or over 100 m: probably "
            "authored in the wrong unit), `origin` (the model is far from its origin), `triangle_budget` and "
            "`draw_call_budget` (more triangles or submeshes than a platform's budget for one model; the "
            "same table model.game_ready reports, and a LOD of the document's gameReady that fits makes the "
            "triangle finding information). Example: "
            "{\"path\":\"assets/models/"
            "door.model.json\",\"expectedHeight\":2.1,\"platforms\":[\"mobile\"]}" FA_COMMAND_DETAILS
            "Every finding has `message` (what is wrong, with the parts and bounds), `hint` (how to fix it), "
            "and for mesh faults `count`, `parts`, `bounds` and up to `samples` positions in model space. "
            "`ok` is false when there is an error. `platforms` limits the budgets checked (default all); "
            "`ignore` lists codes not to report (an open surface that is meant to be open: "
            "[\"open_edges\"]). With no `path` or `document` it returns the catalog of checks and budgets. "
            "Nothing is written.";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"properties",
              obj({{"path", pathProp},
                   {"document", docProp},
                   {"expectedHeight", num_prop("The height (Y) the model should have in metres, e.g. 1.8 for a person, "
                                               "0.75 for a table. 0 = no expectation.",
                                               0, 0, 10000)},
                   {"tolerance", num_prop("A fraction of expectedHeight the height may differ by.", 0.25, 0.01, 10)},
                   {"platforms",
                    list_prop(
                        "Platforms whose triangle and draw call budgets to check: desktop, mobile, web. Default all.")},
                   {"ignore",
                    list_prop(
                        "Check codes not to report, e.g. [\"open_edges\"] for a surface that is meant to be open.")},
                   {"samples", num_prop("Sample positions listed per finding.", 6, 0, 50)}})}});
        mark_paths(info.inputSchema, "read", {"path"});
        registry.add(info, [projectDir](const Json& args) {
            return model_check_command(projectDir, args.is_null() ? Json::object() : args);
        });
    }
    // Capabilities (capability.h): model.preview keeps its picture only when asked; model.check writes nothing.
    using namespace capability_sets;
    declare_command_capabilities(registry, {{"model.preview", changes_state()}, {"model.check", reads()}});
}

}  // namespace fa::assets_detail
