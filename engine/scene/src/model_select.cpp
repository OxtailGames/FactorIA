// Selections of model documents: the catalog of queries, checking them, and evaluating them on a mesh (fa/scene/model_select.h).
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/det_math.h"
#include "fa/core/strings.h"
#include "model_select_impl.h"

namespace fa {

namespace {

constexpr double kMax = 1000.0;

ModelFieldInfo fld(std::string key, std::string type, std::string doc, bool required = false,
                   std::optional<Json> def = std::nullopt, std::optional<double> mn = std::nullopt,
                   std::optional<double> mx = std::nullopt, std::vector<std::string> choices = {}) {
    ModelFieldInfo f;
    f.key = std::move(key);
    f.type = std::move(type);
    f.doc = std::move(doc);
    f.required = required;
    f.def = std::move(def);
    f.min = mn;
    f.max = mx;
    f.choices = std::move(choices);
    return f;
}

ModelFieldInfo space_field() {
    return fld("space", "choice",
               "Where the numbers of this query are measured. \"node\": the space of the edit node's children (before "
               "the node's own position, rotation and scale). \"model\": the model's space, "
               "through the transforms of this node and of the groups and modifiers above it (a mirror or array above "
               "does not count).",
               false, Json("node"), std::nullopt, std::nullopt, {"node", "model"});
}
ModelFieldInfo contain_field() {
    return fld("contain", "choice",
               "When a face is inside the shape: \"center\" its centre is, \"all\" all three corners are, \"any\" at "
               "least one corner is.",
               false, Json("center"), std::nullopt, std::nullopt, {"center", "all", "any"});
}
ModelFieldInfo axis_f(const std::string& doc, const char* def = "y") {
    return fld("axis", "choice", doc, false, Json(def), std::nullopt, std::nullopt, {"x", "y", "z"});
}

std::vector<ModelQueryInfo> build_queries() {
    using K = ModelSelectKind;
    std::vector<ModelQueryInfo> q;
    q.push_back({K::Faces, "all", "Every face.", {}});
    q.push_back({K::Faces,
                 "part",
                 "The faces of one or more parts (the `part` names of the nodes that made them; \"\" is the faces of "
                 "nodes that name no part). A face keeps its part through extrusions and modifiers.",
                 {fld("part", "string", "The part name, e.g. \"lid\"."),
                  fld("parts", "strings", "Several part names; the faces of any of them.")}});
    q.push_back({K::Faces,
                 "normal",
                 "The faces that point in a direction: the angle between the face's normal and `direction` is at most "
                 "`tolerance`. {\"by\": \"normal\", \"direction\": \"top\"} picks the upward-facing faces of a box.",
                 {fld("direction", "direction",
                      "Where the faces point: top (+Y), bottom (-Y), front (+Z), back (-Z), left (-X), right (+X), or "
                      "a vector [x, y, z] (any length above 0).",
                      true),
                  fld("tolerance", "number",
                      "Degrees of difference allowed. 30 takes the top of a dome and its slopes; 1 takes only faces "
                      "that are exactly flat towards the direction.",
                      false, Json(30), 0, 180),
                  space_field()}});
    for (const char* which : {"top", "bottom"}) {
        const bool top = std::string(which) == "top";
        q.push_back({K::Faces,
                     which,
                     std::string("The ") + (top ? "highest" : "lowest") +
                         " faces along an axis: the faces whose centre is within `within` of the " +
                         (top ? "highest" : "lowest") +
                         " face centre. The cap of a cylinder, the top row of a wall, the faces around a sphere's "
                         "pole. Unlike `normal` it picks by position, so it finds the " +
                         (top ? "top" : "bottom") +
                         " of a part whatever way its faces point; give `of` to look only among some faces (the " +
                         (top ? "top" : "bottom") + " of the part \"body\").",
                     {axis_f(std::string("The axis the ") + which + " is measured along (the faces at the " +
                             (top ? "largest" : "smallest") +
                             " coordinate of it). y by default: " + (top ? "up" : "down") + "."),
                      fld("within", "number",
                          "Metres from the extreme within which faces count. Left out: 0.01% of the size of the faces "
                          "looked at, which takes exactly the flat cap and nothing below it.",
                          false, std::nullopt, 0, kMax),
                      fld("of", "faces", "Look only among the faces this query chooses. Left out: all faces."),
                      space_field()}});
    }
    q.push_back({K::Faces,
                 "box",
                 "The faces inside an axis-aligned box.",
                 {fld("min", "vec3", "One corner of the box, [x, y, z] in metres.", true, std::nullopt, -kMax, kMax),
                  fld("max", "vec3", "The opposite corner, each number at least that of `min`.", true, std::nullopt,
                      -kMax, kMax),
                  contain_field(), space_field()}});
    q.push_back({K::Faces,
                 "sphere",
                 "The faces inside a ball.",
                 {fld("center", "vec3", "The centre, [x, y, z] in metres.", true, std::nullopt, -kMax, kMax),
                  fld("radius", "number", "The radius in metres.", true, std::nullopt, 0.0001, kMax), contain_field(),
                  space_field()}});
    q.push_back({K::Faces,
                 "halfspace",
                 "The faces on one side of a plane: the side `normal` points to. {\"by\": \"halfspace\", \"point\": "
                 "[0, 0.5, 0], \"normal\": [0, 1, 0]} is everything above y = 0.5.",
                 {fld("point", "vec3", "A point on the plane, [x, y, z] in metres.", true, std::nullopt, -kMax, kMax),
                  fld("normal", "vec3", "Which side is chosen, [x, y, z] (any length above 0).", true, std::nullopt,
                      -kMax, kMax),
                  contain_field(), space_field()}});
    q.push_back({K::Faces,
                 "and",
                 "The faces that every query in `of` chooses.",
                 {fld("of", "faces_list", "The queries, at least one.", true)}});
    q.push_back({K::Faces,
                 "or",
                 "The faces that any query in `of` chooses.",
                 {fld("of", "faces_list", "The queries, at least one.", true)}});
    q.push_back(
        {K::Faces, "not", "Every face that `of` does not choose.", {fld("of", "faces", "The query to invert.", true)}});
    q.push_back({K::Faces,
                 "grow",
                 "The faces `of` chooses plus the faces that share an edge with them, `steps` times.",
                 {fld("of", "faces", "The query to grow.", true),
                  fld("steps", "integer", "Rings of neighbours to add.", false, Json(1), 1, 16)}});
    q.push_back({K::Faces,
                 "shrink",
                 "The faces `of` chooses minus the ones on its border (the faces with an edge shared with a face that "
                 "is not chosen), `steps` times.",
                 {fld("of", "faces", "The query to shrink.", true),
                  fld("steps", "integer", "Rings to take off.", false, Json(1), 1, 16)}});

    q.push_back({K::Edges, "all", "Every edge.", {}});
    q.push_back({K::Edges,
                 "border",
                 "The edges around a group of faces: edges with a chosen face on one side and a face that is not "
                 "chosen (or nothing: the open edge of a surface) on the other. Bevel the border of the top faces to "
                 "round the rim of a lid.",
                 {fld("faces", "faces", "The face query whose border is taken.", true)}});
    q.push_back(
        {K::Edges,
         "sharp",
         "The edges where the two faces turn by more than `angle` degrees (the corners of a box, not the seams of a "
         "smooth sphere). Edges with one face or more than two are never sharp.",
         {fld("angle", "number",
              "Degrees. 30 leaves the gently curved parts alone; 80 takes only the corners of a box.", false, Json(30),
              0, 180),
          fld("faces", "faces", "Only edges that touch a face this query chooses. Left out: the whole mesh.")}});
    q.push_back(
        {K::Edges,
         "between_parts",
         "The edges where one part meets another: the seam between the lid and the box. With `a` and `b` only the seam "
         "between those two; with `a` alone every seam of that part; with neither every seam of the model.",
         {fld("a", "string", "A part name (\"\" is the faces of nodes that name no part)."),
          fld("b", "string", "The other part name.")}});
    q.push_back({K::Edges,
                 "loop",
                 "The edges that lie in the plane perpendicular to `axis` at a height: the ring round a vase at 40% of "
                 "its height. Use it after `loop_cut` (which makes such a ring) or on a mesh that already has one. "
                 "`at` is a coordinate, `ratio` a fraction of the mesh's extent along the axis.",
                 {axis_f("The axis the ring goes round; the plane is perpendicular to it."),
                  fld("at", "number", "The coordinate of the plane along the axis, in metres. Give this or `ratio`.",
                      false, std::nullopt, -kMax, kMax),
                  fld("ratio", "number",
                      "Where the plane is, from 0 (the lowest vertex) to 1 (the highest) of the mesh at this point of "
                      "the tree. 0.5 when neither is given.",
                      false, std::nullopt, 0, 1),
                  fld("tolerance", "number",
                      "Metres from the plane within which an edge counts as lying in it. Left out: 0.01% of the mesh's "
                      "extent along the axis.",
                      false, std::nullopt, 0, kMax),
                  space_field()}});
    q.push_back({K::Edges,
                 "and",
                 "The edges that every query in `of` chooses.",
                 {fld("of", "edges_list", "The queries, at least one.", true)}});
    q.push_back({K::Edges,
                 "or",
                 "The edges that any query in `of` chooses.",
                 {fld("of", "edges_list", "The queries, at least one.", true)}});
    q.push_back(
        {K::Edges, "not", "Every edge that `of` does not choose.", {fld("of", "edges", "The query to invert.", true)}});
    return q;
}

const char* kind_name(ModelSelectKind k) { return k == ModelSelectKind::Faces ? "face" : "edge"; }

std::vector<std::string> by_names(ModelSelectKind kind) {
    std::vector<std::string> names;
    for (const ModelQueryInfo& q : model_queries())
        if (q.kind == kind) names.push_back(q.by);
    return names;
}

std::string quoted(const std::vector<std::string>& names) {
    std::string s;
    for (std::size_t i = 0; i < names.size(); ++i) s += (i ? ", \"" : "\"") + names[i] + "\"";
    return s;
}

std::string num_text(double v) {
    if (v == std::floor(v) && std::fabs(v) < 1e9) return std::format("{}", static_cast<long long>(v));
    return std::format("{:g}", v);
}

const ModelQueryInfo* find_query(ModelSelectKind kind, const std::string& by) {
    for (const ModelQueryInfo& q : model_queries())
        if (q.kind == kind && q.by == by) return &q;
    return nullptr;
}

constexpr int kMaxDepth = 8;

void check_query(const Json& q, ModelSelectKind kind, const std::string& at, std::vector<ModelIssue>& issues,
                 int depth);

void check_value(const ModelFieldInfo& f, const Json& v, const std::string& at, std::vector<ModelIssue>& issues,
                 int depth) {
    const std::string& t = f.type;
    auto err = [&](std::string message, std::string hint) {
        issues.push_back({at, std::move(message), std::move(hint)});
    };
    auto finite = [](const Json& x) { return x.is_number() && std::isfinite(x.get<double>()); };
    auto in_range = [&](double d) { return (!f.min || d >= *f.min) && (!f.max || d <= *f.max); };
    auto range_text = [&] {
        if (f.min && f.max) return "from " + num_text(*f.min) + " to " + num_text(*f.max);
        if (f.min) return "at least " + num_text(*f.min);
        return "at most " + num_text(*f.max);
    };
    if (t == "number" || t == "integer") {
        if (!finite(v) || (t == "integer" && v.get<double>() != std::floor(v.get<double>()))) {
            err(f.key + " must be " + (t == "integer" ? "a whole number" : "a number") + ", got " +
                    describe_json_value(v),
                f.doc);
            return;
        }
        if (!in_range(v.get<double>()))
            err(f.key + " must be " + range_text() + ", got " + num_text(v.get<double>()), f.doc);
    } else if (t == "boolean") {
        if (!v.is_boolean()) err(f.key + " must be true or false, got " + describe_json_value(v), f.doc);
    } else if (t == "string") {
        if (!v.is_string() || v.get<std::string>().size() > 64)
            err(f.key + " must be text of at most 64 characters, got " + describe_json_value(v), f.doc);
    } else if (t == "choice") {
        if (!v.is_string())
            err(f.key + " must be one of " + quoted(f.choices) + ", got " + describe_json_value(v), f.doc);
        else if (std::find(f.choices.begin(), f.choices.end(), v.get<std::string>()) == f.choices.end())
            err(f.key + " must be one of " + quoted(f.choices) + ", got \"" + v.get<std::string>() + "\"",
                did_you_mean(v.get<std::string>(), f.choices));
    } else if (t == "strings") {
        bool ok = v.is_array() && !v.empty();
        if (ok)
            for (const Json& s : v) ok = ok && s.is_string() && s.get<std::string>().size() <= 64;
        if (!ok)
            err(f.key + " must be a list of part names such as [\"lid\", \"box\"], got " + describe_json_value(v),
                f.doc);
    } else if (t == "vec3" || t == "direction") {
        if (t == "direction" && v.is_string()) {
            std::vector<std::string> names;
            for (const auto& [n, d] : model_named_directions()) names.push_back(n);
            if (std::find(names.begin(), names.end(), v.get<std::string>()) == names.end())
                err("direction \"" + v.get<std::string>() + "\" is not a known direction (" + quoted(names) + ")",
                    did_you_mean(v.get<std::string>(), names) + " Or give a vector [x, y, z].");
            return;
        }
        if (!v.is_array() || v.size() != 3 || !finite(v[0]) || !finite(v[1]) || !finite(v[2])) {
            err(f.key + " must be " + (t == "direction" ? "a direction name or " : "") +
                    "a list [x, y, z] of numbers, got " + describe_json_value(v),
                f.doc);
            return;
        }
        for (std::size_t k = 0; k < 3; ++k)
            if (!in_range(v[k].get<double>())) {
                err(f.key + "[" + std::to_string(k) + "] must be " + range_text() + ", got " +
                        num_text(v[k].get<double>()),
                    f.doc);
                return;
            }
    } else if (t == "faces" || t == "edges") {
        check_query(v, t == "faces" ? ModelSelectKind::Faces : ModelSelectKind::Edges, at, issues, depth + 1);
    } else if (t == "faces_list" || t == "edges_list") {
        if (!v.is_array() || v.empty()) {
            err(f.key + " must be a list of at least one query, got " + describe_json_value(v),
                f.doc +
                    " Example: [{\"by\": \"normal\", \"direction\": \"top\"}, {\"by\": \"part\", \"part\": \"lid\"}].");
            return;
        }
        for (std::size_t i = 0; i < v.size(); ++i)
            check_query(v[i], t == "faces_list" ? ModelSelectKind::Faces : ModelSelectKind::Edges,
                        at + "/" + std::to_string(i), issues, depth + 1);
    }
}

void check_query(const Json& q, ModelSelectKind kind, const std::string& at, std::vector<ModelIssue>& issues,
                 int depth) {
    const std::string what = kind_name(kind);
    const std::vector<std::string> names = by_names(kind);
    if (!q.is_object()) {
        issues.push_back(
            {at, "a " + what + " selection must be an object with \"by\", got " + describe_json_value(q),
             "Write e.g. " +
                 std::string(kind == ModelSelectKind::Faces ? "{\"by\": \"normal\", \"direction\": \"top\"}"
                                                            : "{\"by\": \"sharp\", \"angle\": 30}") +
                 ". The " + what + " queries are: " + quoted(names) + "."});
        return;
    }
    if (depth > kMaxDepth) {
        issues.push_back({at, std::format("selections are nested more than {} levels deep", kMaxDepth),
                          "Flatten it: `and` and `or` take a list, so they rarely need to nest."});
        return;
    }
    auto byIt = q.find("by");
    if (byIt == q.end() || !byIt->is_string()) {
        issues.push_back({at + (byIt == q.end() ? "" : "/by"),
                          byIt == q.end() ? "a " + what + " selection needs \"by\""
                                          : "by must be text, got " + describe_json_value(*byIt),
                          "Say what to select by: " + quoted(names) + "."});
        return;
    }
    const std::string by = byIt->get<std::string>();
    const ModelQueryInfo* info = find_query(kind, by);
    if (!info) {
        const ModelSelectKind other = kind == ModelSelectKind::Faces ? ModelSelectKind::Edges : ModelSelectKind::Faces;
        std::string hint = did_you_mean(by, names);
        if (find_query(other, by) && by != "all" && by != "and" && by != "or" && by != "not")
            hint = "\"" + by + "\" selects " + kind_name(other) + "s, and this field takes " + what + "s. " + hint;
        issues.push_back({at + "/by", "unknown " + what + " query \"" + by + "\"",
                          hint + " The " + what + " queries are: " + quoted(names) + "."});
        return;
    }
    std::vector<std::string> keys{"by"};
    for (const ModelFieldInfo& f : info->fields) keys.push_back(f.key);
    for (auto it = q.begin(); it != q.end(); ++it)
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
            issues.push_back({at + "/" + it.key(), "\"" + it.key() + "\" is not a field of the \"" + by + "\" query",
                              did_you_mean(it.key(), keys) + " " + info->doc});
    const std::size_t before = issues.size();
    for (const ModelFieldInfo& f : info->fields) {
        auto it = q.find(f.key);
        if (it == q.end()) {
            if (f.required) issues.push_back({at, "the \"" + by + "\" query needs \"" + f.key + "\"", f.doc});
            continue;
        }
        check_value(f, *it, at + "/" + f.key, issues, depth);
    }
    if (issues.size() != before) return;
    // rules that involve several fields
    auto vec = [&](const char* k) { return Vec3{q[k][0].get<float>(), q[k][1].get<float>(), q[k][2].get<float>()}; };
    if (by == "part" && !q.contains("part") && !q.contains("parts"))
        issues.push_back({at, "the \"part\" query needs \"part\" (a name) or \"parts\" (a list of names)",
                          "Example: {\"by\": \"part\", \"part\": \"lid\"}."});
    if (by == "normal" && q["direction"].is_array() && length(vec("direction")) < 1e-9f)
        issues.push_back({at + "/direction", "direction [0, 0, 0] has no direction",
                          "Give a vector such as [0, 1, 0], or a name: top, bottom, front, back, left, right."});
    if (by == "halfspace" && length(vec("normal")) < 1e-9f)
        issues.push_back({at + "/normal", "normal [0, 0, 0] has no direction",
                          "Give the side that is chosen, e.g. [0, 1, 0] for everything above the point."});
    if (by == "box") {
        const Vec3 a = vec("min"), b = vec("max");
        if (a.x > b.x || a.y > b.y || a.z > b.z)
            issues.push_back({at + "/max",
                              "box max " + Json::array({b.x, b.y, b.z}).dump() + " is below min " +
                                  Json::array({a.x, a.y, a.z}).dump() + " on some axis",
                              "Swap them so each number of `min` is at most the same number of `max`."});
    }
    if (by == "loop" && q.contains("at") && q.contains("ratio"))
        issues.push_back({at + "/ratio",
                          "a loop takes `at` (a coordinate) or `ratio` (a fraction of the extent), not both",
                          "Remove one of them."});
}

}  // namespace

const std::vector<ModelQueryInfo>& model_queries() {
    static const std::vector<ModelQueryInfo> queries = build_queries();
    return queries;
}

const std::vector<std::pair<std::string, Vec3>>& model_named_directions() {
    static const std::vector<std::pair<std::string, Vec3>> dirs = {{"top", {0, 1, 0}},   {"bottom", {0, -1, 0}},
                                                                   {"front", {0, 0, 1}}, {"back", {0, 0, -1}},
                                                                   {"left", {-1, 0, 0}}, {"right", {1, 0, 0}}};
    return dirs;
}

void check_model_selection(const Json& query, ModelSelectKind kind, const std::string& pointer,
                           std::vector<ModelIssue>& issues) {
    check_query(query, kind, pointer, issues, 0);
}

Json model_selection_schema(ModelSelectKind kind) {
    Json props = Json::object();
    Json bys = Json::array();
    std::string doc = kind == ModelSelectKind::Faces
                          ? "A choice of faces by meaning, evaluated on the mesh at this point of the tree (never "
                            "indices): `by` says how, the other fields depend on it. "
                          : "A choice of edges by meaning, evaluated on the mesh at this point of the tree (never "
                            "indices): `by` says how, the other fields depend on it. ";
    Json alternatives = Json::array();
    for (const ModelQueryInfo& q : model_queries()) {
        if (q.kind != kind) continue;
        bys.push_back(q.by);
        doc += "\"" + q.by + "\": " + q.doc + " ";
        Json p = Json::object({{"by", Json::object({{"const", q.by}})}});
        Json required = Json::array({"by"});
        for (const ModelFieldInfo& f : q.fields) {
            Json s;
            const std::string& t = f.type;
            auto nested = [&](const char* name) { return Json::object({{"$ref", std::string("#/$defs/") + name}}); };
            if (t == "number" || t == "integer") {
                s = Json::object({{"type", t == "integer" ? "integer" : "number"}});
                if (f.min) s["minimum"] = *f.min;
                if (f.max) s["maximum"] = *f.max;
            } else if (t == "boolean")
                s = Json::object({{"type", "boolean"}});
            else if (t == "string")
                s = Json::object({{"type", "string"}});
            else if (t == "choice")
                s = Json::object({{"type", "string"}, {"enum", f.choices}});
            else if (t == "strings")
                s = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}, {"minItems", 1}});
            else if (t == "vec3" || t == "direction") {
                Json num = Json::object({{"type", "number"}});
                if (f.min) num["minimum"] = *f.min;
                if (f.max) num["maximum"] = *f.max;
                Json array = Json::object({{"type", "array"}, {"items", num}, {"minItems", 3}, {"maxItems", 3}});
                if (t == "direction") {
                    Json names = Json::array();
                    for (const auto& [n, d] : model_named_directions()) names.push_back(n);
                    s = Json::object(
                        {{"anyOf", Json::array({Json::object({{"type", "string"}, {"enum", names}}), array})}});
                } else
                    s = array;
            } else if (t == "faces")
                s = nested("face_selection");
            else if (t == "edges")
                s = nested("edge_selection");
            else if (t == "faces_list")
                s = Json::object({{"type", "array"}, {"minItems", 1}, {"items", nested("face_selection")}});
            else
                s = Json::object({{"type", "array"}, {"minItems", 1}, {"items", nested("edge_selection")}});
            s["description"] = f.doc;
            if (f.def) s["default"] = *f.def;
            p[f.key] = s;
            if (f.required) required.push_back(f.key);
        }
        alternatives.push_back(Json::object({{"type", "object"},
                                             {"description", q.doc},
                                             {"required", required},
                                             {"additionalProperties", false},
                                             {"properties", p}}));
    }
    return Json::object({{"description", doc}, {"oneOf", alternatives}});
}

// ---- evaluating -------------------------------------------------------------------------------------------------------------------

namespace sel {

using mm::Edges;
using mm::Soup;

namespace {

Vec3 vec_of(const Json& a) { return {a[0].get<float>(), a[1].get<float>(), a[2].get<float>()}; }
float num_of(const Json& q, const char* key, float def) { return q.contains(key) ? q[key].get<float>() : def; }
std::string str_of(const Json& q, const char* key, const char* def) {
    return q.contains(key) ? q[key].get<std::string>() : def;
}
int axis_index(const std::string& a) { return a == "x" ? 0 : a == "y" ? 1 : 2; }
float component(Vec3 v, int axis) { return axis == 0 ? v.x : axis == 1 ? v.y : v.z; }
const char* axis_letter(int axis) { return axis == 0 ? "x" : axis == 1 ? "y" : "z"; }

std::size_t count_of(const std::vector<char>& m) { return std::size_t(std::count(m.begin(), m.end(), char(1))); }

std::string vec_text(Vec3 v) {
    return std::format("[{}, {}, {}]", num_text(std::round(v.x * 1000.0) / 1000.0),
                       num_text(std::round(v.y * 1000.0) / 1000.0), num_text(std::round(v.z * 1000.0) / 1000.0));
}

Vec3 direction_of(const Json& d) {
    if (d.is_string()) {
        for (const auto& [n, v] : model_named_directions())
            if (n == d.get<std::string>()) return v;
    }
    return vec_of(d);
}

std::string direction_text(const Json& d) {
    return d.is_string() ? "\"" + d.get<std::string>() + "\"" : vec_text(vec_of(d));
}

}  // namespace

Selector::Selector(const Soup& soup, const Edges& edges, const ModelEditContext& context)
    : s_(soup), e_(edges), ctx_(context) {
    const std::size_t tc = s_.tris.size();
    area_.assign(tc, 0.0f);
    node_.center.resize(tc);
    node_.normal.resize(tc);
    node_.corner.resize(tc);
    for (std::size_t t = 0; t < tc; ++t) {
        const Vec3 a = s_.pos[s_.tris[t][0]], b = s_.pos[s_.tris[t][1]], c = s_.pos[s_.tris[t][2]];
        const Vec3 cr = cross(b - a, c - a);
        node_.corner[t] = {a, b, c};
        node_.center[t] = (a + b + c) / 3.0f;
        node_.normal[t] = mm::unit_or(cr, Vec3{0, 0, 0});
        area_[t] = 0.5f * length(cr);
    }
    node_.ready = true;
}

const SpaceData& Selector::node_data() const { return node_; }

const SpaceData& Selector::space(bool model) {
    if (!model) return node_;
    if (model_.ready) return model_;
    const std::size_t tc = s_.tris.size();
    model_.center.resize(tc);
    model_.normal.resize(tc);
    model_.corner.resize(tc);
    const float flip = dot(ctx_.toModel.transform_dir({1, 0, 0}),
                           cross(ctx_.toModel.transform_dir({0, 1, 0}), ctx_.toModel.transform_dir({0, 0, 1}))) < 0
                           ? -1.0f
                           : 1.0f;
    for (std::size_t t = 0; t < tc; ++t) {
        for (std::size_t k = 0; k < 3; ++k) model_.corner[t][k] = ctx_.toModel.transform_point(node_.corner[t][k]);
        model_.center[t] = (model_.corner[t][0] + model_.corner[t][1] + model_.corner[t][2]) / 3.0f;
        // the normal is the cross product of the moved corners, turned back when the transform mirrors
        const auto& c = model_.corner[t];
        model_.normal[t] = length_sq(node_.normal[t]) > 0
                               ? mm::unit_or(cross(c[1] - c[0], c[2] - c[0]) * flip, Vec3{0, 0, 0})
                               : Vec3{0, 0, 0};
    }
    model_.ready = true;
    return model_;
}

const std::string& Selector::part_name(std::size_t tri) const {
    static const std::string none;
    const std::uint32_t p = s_.part[tri];
    return p < ctx_.partNames.size() ? ctx_.partNames[p] : none;
}

std::vector<std::string> Selector::existing_parts() const {
    std::set<std::string> names;
    for (std::size_t t = 0; t < s_.tris.size(); ++t) names.insert(part_name(t));
    return {names.begin(), names.end()};
}

namespace {

std::string parts_text(const std::vector<std::string>& parts) {
    std::string out;
    for (const std::string& p : parts)
        out += (out.empty() ? "" : ", ") + (p.empty() ? std::string("(no part)") : "\"" + p + "\"");
    return out;
}

}  // namespace

std::vector<char> Selector::faces(const Json& q) {
    const std::size_t tc = s_.tris.size();
    const std::string by = q["by"].get<std::string>();
    if (by == "and" || by == "or") {
        std::vector<char> acc;
        for (const Json& sub : q["of"]) {
            std::vector<char> m = faces(sub);
            if (acc.empty())
                acc = std::move(m);
            else
                for (std::size_t t = 0; t < tc; ++t) acc[t] = by == "and" ? char(acc[t] && m[t]) : char(acc[t] || m[t]);
        }
        if (by == "and" && count_of(acc) == 0 && notes.empty())
            notes.push_back("every part of the `and` matched some faces, but no face is in all of them");
        return acc;
    }
    if (by == "not") {
        std::vector<char> m = faces(q["of"]);
        for (char& c : m) c = c ? 0 : 1;
        if (count_of(m) == 0) notes.push_back("the `not` inverts a selection that already matches every face");
        return m;
    }
    if (by == "grow" || by == "shrink") {
        std::vector<char> m = faces(q["of"]);
        const int steps = q.contains("steps") ? q["steps"].get<int>() : 1;
        for (int step = 0; step < steps; ++step) {
            std::vector<char> next = m;
            for (const Edges::Edge& edge : e_.edges) {
                bool anyOn = false, anyOff = false;
                for (std::uint32_t k = 0; k < edge.count; ++k) (m[e_.uses[edge.first + k].tri] ? anyOn : anyOff) = true;
                if (!anyOn || !anyOff) continue;
                for (std::uint32_t k = 0; k < edge.count; ++k) {
                    const std::uint32_t t = e_.uses[edge.first + k].tri;
                    if (by == "grow" && !m[t]) next[t] = 1;
                    if (by == "shrink" && m[t]) next[t] = 0;
                }
            }
            m = std::move(next);
        }
        if (by == "shrink" && count_of(m) == 0)
            notes.push_back(std::format("shrinking {} step(s) took off every face it had: use fewer steps", steps));
        return m;
    }
    return face_leaf(by, q);
}

std::vector<char> Selector::face_leaf(const std::string& by, const Json& q) {
    const std::size_t tc = s_.tris.size();
    std::vector<char> mask(tc, 0);
    if (by == "all") {
        std::fill(mask.begin(), mask.end(), char(1));
        return mask;
    }
    if (by == "part") {
        std::set<std::string> want;
        if (q.contains("part")) want.insert(q["part"].get<std::string>());
        if (q.contains("parts"))
            for (const Json& p : q["parts"]) want.insert(p.get<std::string>());
        for (std::size_t t = 0; t < tc; ++t) mask[t] = want.count(part_name(t)) ? 1 : 0;
        if (count_of(mask) == 0) {
            const std::vector<std::string> have = existing_parts();
            std::string note;
            for (const std::string& w : want)
                if (std::find(have.begin(), have.end(), w) == have.end())
                    note += (note.empty() ? "" : "; ") + std::string("no face belongs to part \"") + w + "\"";
            if (have.size() == 1 && have[0].empty())
                note += ". No node here names a part: give the nodes a `part` first";
            else {
                std::vector<std::string> named;
                for (const std::string& h : have)
                    if (!h.empty()) named.push_back(h);
                note += ". The parts at this point are " + parts_text(have);
                if (!want.empty() && !named.empty()) note += ". " + did_you_mean(*want.begin(), named);
            }
            notes.push_back(note);
        }
        return mask;
    }
    if (by == "normal") {
        const bool model = str_of(q, "space", "node") == "model";
        const SpaceData& sp = space(model);
        const Vec3 dir = mm::unit_or(direction_of(q["direction"]), Vec3{0, 1, 0});
        const float tol = num_of(q, "tolerance", 30);
        const float cosTol = det::cos(radians(tol)) - 1e-6f;
        float best = -2;
        for (std::size_t t = 0; t < tc; ++t) {
            if (length_sq(sp.normal[t]) < 0.5f) continue;
            const float d = dot(sp.normal[t], dir);
            best = std::max(best, d);
            if (d >= cosTol) mask[t] = 1;
        }
        if (count_of(mask) == 0) {
            const float closest = best < -1.5f ? 180.0f : mm::angle_deg(dir, dir * clamp(best, -1.0f, 1.0f));
            if (best < -1.5f)
                notes.push_back("the mesh has no face with an area, so no normal points anywhere");
            else
                notes.push_back(std::format(
                    "no face points within {} degrees of {} (the closest is {:.1f} degrees away: use a tolerance of {} "
                    "or more, or check the direction{})",
                    num_text(tol), direction_text(q["direction"]), closest, std::ceil(closest),
                    model ? "" : "; if the node is rotated, `space` \"model\" measures in the model's axes"));
        }
        return mask;
    }
    if (by == "top" || by == "bottom") return by_extreme(q, by == "top");
    return by_region(by, q);
}

std::vector<char> Selector::by_extreme(const Json& q, bool top) {
    const std::size_t tc = s_.tris.size();
    std::vector<char> cand(tc, 1), mask(tc, 0);
    if (q.contains("of")) cand = faces(q["of"]);
    const int axis = axis_index(str_of(q, "axis", "y"));
    const SpaceData& sp = space(str_of(q, "space", "node") == "model");
    float lo = 1e30f, hi = -1e30f;
    for (std::size_t t = 0; t < tc; ++t) {
        if (!cand[t] || area_[t] <= 0) continue;
        const float k = component(sp.center[t], axis);
        lo = std::min(lo, k);
        hi = std::max(hi, k);
    }
    if (hi < lo) {
        notes.push_back(std::string("the faces to look among (`of`) are empty, so there is no ") +
                        (top ? "top" : "bottom"));
        return mask;
    }
    const float within = q.contains("within") ? q["within"].get<float>() : 1e-4f * (hi - lo) + 1e-6f;
    for (std::size_t t = 0; t < tc; ++t) {
        if (!cand[t] || area_[t] <= 0) continue;
        const float k = component(sp.center[t], axis);
        if (top ? k >= hi - within : k <= lo + within) mask[t] = 1;
    }
    return mask;
}

std::vector<char> Selector::by_region(const std::string& by, const Json& q) {
    const std::size_t tc = s_.tris.size();
    std::vector<char> mask(tc, 0);
    const bool model = str_of(q, "space", "node") == "model";
    const SpaceData& sp = space(model);
    const std::string contain = str_of(q, "contain", "center");
    const float eps = 1e-5f;
    Vec3 lo{}, hi{}, center{}, point{}, normal{};
    float radius = 0;
    if (by == "box") {
        lo = vec_of(q["min"]);
        hi = vec_of(q["max"]);
    } else if (by == "sphere") {
        center = vec_of(q["center"]);
        radius = q["radius"].get<float>();
    } else {
        point = vec_of(q["point"]);
        normal = mm::unit_or(vec_of(q["normal"]), Vec3{0, 1, 0});
    }
    auto inside = [&](Vec3 p) {
        if (by == "box")
            return p.x >= lo.x - eps && p.x <= hi.x + eps && p.y >= lo.y - eps && p.y <= hi.y + eps &&
                   p.z >= lo.z - eps && p.z <= hi.z + eps;
        if (by == "sphere") return length(p - center) <= radius + eps;
        return dot(p - point, normal) >= -eps;
    };
    for (std::size_t t = 0; t < tc; ++t) {
        bool in;
        if (contain == "center")
            in = inside(sp.center[t]);
        else {
            const int n = int(inside(sp.corner[t][0])) + int(inside(sp.corner[t][1])) + int(inside(sp.corner[t][2]));
            in = contain == "all" ? n == 3 : n > 0;
        }
        mask[t] = in ? 1 : 0;
    }
    if (count_of(mask) == 0 && tc > 0) {
        Vec3 bmin = sp.corner[0][0], bmax = bmin;
        for (std::size_t t = 0; t < tc; ++t)
            for (const Vec3& p : sp.corner[t]) {
                bmin = {std::min(bmin.x, p.x), std::min(bmin.y, p.y), std::min(bmin.z, p.z)};
                bmax = {std::max(bmax.x, p.x), std::max(bmax.y, p.y), std::max(bmax.z, p.z)};
            }
        std::string shape = by == "box" ? "the box " + vec_text(lo) + " to " + vec_text(hi)
                            : by == "sphere"
                                ? "the sphere at " + vec_text(center) + " of radius " + num_text(radius)
                                : "the half-space past " + vec_text(point) + " towards " + vec_text(normal);
        notes.push_back("no face " +
                        std::string(contain == "center" ? "has its centre"
                                    : contain == "all"  ? "has all its corners"
                                                        : "has a corner") +
                        " inside " + shape + "; the mesh spans " + vec_text(bmin) + " to " + vec_text(bmax) + " in " +
                        (model ? "model" : "node") + " space" + (contain == "center" ? " (try contain \"any\")" : ""));
    }
    return mask;
}

std::vector<char> Selector::edges(const Json& q) {
    const std::size_t ec = e_.edges.size();
    const std::string by = q["by"].get<std::string>();
    if (by == "and" || by == "or") {
        std::vector<char> acc;
        for (const Json& sub : q["of"]) {
            std::vector<char> m = edges(sub);
            if (acc.empty())
                acc = std::move(m);
            else
                for (std::size_t i = 0; i < ec; ++i) acc[i] = by == "and" ? char(acc[i] && m[i]) : char(acc[i] || m[i]);
        }
        if (by == "and" && count_of(acc) == 0 && notes.empty())
            notes.push_back("every part of the `and` matched some edges, but no edge is in all of them");
        return acc;
    }
    if (by == "not") {
        std::vector<char> m = edges(q["of"]);
        for (char& c : m) c = c ? 0 : 1;
        if (count_of(m) == 0) notes.push_back("the `not` inverts a selection that already matches every edge");
        return m;
    }
    return edge_leaf(by, q);
}

std::vector<char> Selector::edge_leaf(const std::string& by, const Json& q) {
    const std::size_t ec = e_.edges.size();
    std::vector<char> mask(ec, 0);
    if (by == "all") {
        std::fill(mask.begin(), mask.end(), char(1));
        return mask;
    }
    if (by == "border") {
        const std::vector<char> f = faces(q["faces"]);
        const std::size_t faceCount = count_of(f);
        for (std::size_t i = 0; i < ec; ++i) {
            const Edges::Edge& edge = e_.edges[i];
            std::uint32_t on = 0;
            for (std::uint32_t k = 0; k < edge.count; ++k) on += f[e_.uses[edge.first + k].tri] ? 1 : 0;
            mask[i] = on > 0 && (edge.count == 1 || on < edge.count) ? 1 : 0;
        }
        if (count_of(mask) == 0 && notes.empty())
            notes.push_back(faceCount == 0 ? "the faces whose border is wanted matched nothing"
                                           : "the selected faces have no border: they are every face of a closed mesh "
                                             "(invert them, or select a part of it)");
        return mask;
    }
    if (by == "sharp") {
        std::vector<char> within;
        if (q.contains("faces")) within = faces(q["faces"]);
        const float angle = num_of(q, "angle", 30);
        const float cosA = det::cos(radians(angle));
        float sharpest = 0;
        for (std::size_t i = 0; i < ec; ++i) {
            if (!e_.regular(i)) continue;
            const std::uint32_t t0 = e_.uses[e_.edges[i].first].tri, t1 = e_.uses[e_.edges[i].first + 1].tri;
            if (!within.empty() && !within[t0] && !within[t1]) continue;
            const Vec3 a = node_.normal[t0], b = node_.normal[t1];
            if (length_sq(a) < 0.5f || length_sq(b) < 0.5f) continue;
            const float d = dot(a, b);
            sharpest = std::max(sharpest, mm::angle_deg(a, b));
            if (d < cosA) mask[i] = 1;
        }
        if (count_of(mask) == 0 && (within.empty() || count_of(within) > 0))
            notes.push_back(
                std::format("no edge turns by more than {} degrees (the sharpest turns {:.1f}: use an angle below {})",
                            num_text(angle), sharpest, std::floor(sharpest)));
        return mask;
    }
    if (by == "between_parts") {
        const bool hasA = q.contains("a"), hasB = q.contains("b");
        const std::string a = hasA ? q["a"].get<std::string>() : "", b = hasB ? q["b"].get<std::string>() : "";
        for (std::size_t i = 0; i < ec; ++i) {
            if (e_.edges[i].count != 2) continue;
            const std::string& p0 = part_name(e_.uses[e_.edges[i].first].tri);
            const std::string& p1 = part_name(e_.uses[e_.edges[i].first + 1].tri);
            if (p0 == p1) continue;
            bool ok = true;
            if (hasA && hasB)
                ok = (p0 == a && p1 == b) || (p0 == b && p1 == a);
            else if (hasA)
                ok = p0 == a || p1 == a;
            else if (hasB)
                ok = p0 == b || p1 == b;
            mask[i] = ok ? 1 : 0;
        }
        if (count_of(mask) == 0) {
            const std::vector<std::string> have = existing_parts();
            std::vector<std::string> named;
            for (const std::string& h : have)
                if (!h.empty()) named.push_back(h);
            std::string note = "no edge lies between ";
            note += hasA && hasB ? "part \"" + a + "\" and part \"" + b + "\""
                    : hasA       ? "part \"" + a + "\" and another part"
                    : hasB       ? "part \"" + b + "\" and another part"
                                 : "two different parts";
            note += have.size() < 2 ? "; the mesh has only " + parts_text(have) + " at this point"
                                    : "; the parts at this point are " + parts_text(have);
            for (const std::string* p : {&a, &b})
                if (!p->empty() && std::find(have.begin(), have.end(), *p) == have.end() && !named.empty())
                    note += ". " + did_you_mean(*p, named);
            notes.push_back(note);
        }
        return mask;
    }
    // loop
    const int axis = axis_index(str_of(q, "axis", "y"));
    const bool model = str_of(q, "space", "node") == "model";
    float lo = 1e30f, hi = -1e30f;
    std::vector<float> coord(s_.pos.size(), 0.0f);
    std::vector<char> used(s_.pos.size(), 0);
    for (const auto& tri : s_.tris)
        for (std::uint32_t v : tri) used[v] = 1;
    std::vector<float> rows;
    for (std::size_t v = 0; v < s_.pos.size(); ++v) {
        if (!used[v]) continue;
        coord[v] = component(model ? ctx_.toModel.transform_point(s_.pos[v]) : s_.pos[v], axis);
        lo = std::min(lo, coord[v]);
        hi = std::max(hi, coord[v]);
    }
    if (hi < lo) return mask;
    const float at = q.contains("at") ? q["at"].get<float>() : lo + num_of(q, "ratio", 0.5f) * (hi - lo);
    const float tol = q.contains("tolerance") ? q["tolerance"].get<float>() : 1e-4f * (hi - lo) + 1e-6f;
    for (std::size_t i = 0; i < ec; ++i) {
        const float a = coord[e_.edges[i].lo], b = coord[e_.edges[i].hi];
        mask[i] = std::fabs(a - at) <= tol && std::fabs(b - at) <= tol ? 1 : 0;
    }
    if (count_of(mask) == 0) {
        float nearest = lo;
        for (std::size_t v = 0; v < coord.size(); ++v)
            if (used[v] && std::fabs(coord[v] - at) < std::fabs(nearest - at)) nearest = coord[v];
        std::string note = std::format(
            "no edge lies in the plane {} = {} (within {}); the mesh spans {} to {} along {}", axis_letter(axis),
            num_text(std::round(at * 10000.0) / 10000.0), num_text(tol), num_text(std::round(lo * 10000.0) / 10000.0),
            num_text(std::round(hi * 10000.0) / 10000.0), axis_letter(axis));
        if (at >= lo && at <= hi)
            note += std::format(
                "; the nearest vertices are at {}: cut a loop there first with `loop_cut` at {}, or use `at` {}",
                num_text(std::round(nearest * 10000.0) / 10000.0), num_text(std::round(at * 10000.0) / 10000.0),
                num_text(std::round(nearest * 10000.0) / 10000.0));
        else
            note += ": the plane is outside the mesh";
        notes.push_back(note);
    }
    return mask;
}

std::string empty_warning(const std::string& what, const std::vector<std::string>& notes) {
    std::string out = "the selection matched no " + what;
    for (std::size_t i = 0; i < notes.size(); ++i) out += (i ? "; " : ": ") + notes[i];
    return out;
}

ModelSelectionReport make_report(const Selector& selector, const std::vector<char>& mask, ModelSelectKind kind,
                                 const std::string&) {
    const Soup& s = selector.soup();
    const Edges& e = selector.edge_table();
    ModelSelectionReport r;
    r.select = kind == ModelSelectKind::Faces ? "faces" : "edges";
    r.total = kind == ModelSelectKind::Faces ? s.tris.size() : e.edges.size();
    std::map<std::string, std::size_t> parts;
    bool first = true;
    auto grow = [&](Vec3 p) {
        if (first) r.bmin = r.bmax = p;
        first = false;
        r.bmin = {std::min(r.bmin.x, p.x), std::min(r.bmin.y, p.y), std::min(r.bmin.z, p.z)};
        r.bmax = {std::max(r.bmax.x, p.x), std::max(r.bmax.y, p.y), std::max(r.bmax.z, p.z)};
    };
    if (kind == ModelSelectKind::Faces) {
        for (std::size_t t = 0; t < s.tris.size(); ++t) {
            if (!mask[t]) continue;
            ++r.matched;
            r.measure += selector.face_area(t);
            ++parts[selector.part_name(t)];
            for (std::uint32_t v : s.tris[t]) grow(s.pos[v]);
        }
    } else {
        std::set<std::uint32_t> beside;
        for (std::size_t i = 0; i < e.edges.size(); ++i) {
            if (!mask[i]) continue;
            ++r.matched;
            r.measure += length(s.pos[e.edges[i].hi] - s.pos[e.edges[i].lo]);
            grow(s.pos[e.edges[i].lo]);
            grow(s.pos[e.edges[i].hi]);
            for (std::uint32_t k = 0; k < e.edges[i].count; ++k) beside.insert(e.uses[e.edges[i].first + k].tri);
        }
        for (std::uint32_t t : beside) ++parts[selector.part_name(t)];
    }
    r.parts.assign(parts.begin(), parts.end());
    return r;
}

}  // namespace sel

ModelSelectionReport model_select_report(const ModelMesh& mesh, const Json& query, ModelSelectKind kind,
                                         const ModelEditContext& context) {
    const mm::Soup soup = mm::to_soup(mesh);
    const mm::Edges edges = mm::build_edges(soup);
    sel::Selector selector(soup, edges, context);
    const std::vector<char> mask = kind == ModelSelectKind::Faces ? selector.faces(query) : selector.edges(query);
    ModelSelectionReport r = sel::make_report(selector, mask, kind, "");
    if (r.matched == 0)
        r.warnings.push_back(sel::empty_warning(kind == ModelSelectKind::Faces ? "faces" : "edges", selector.notes));
    return r;
}

std::vector<char> model_select_triangles(const ModelMesh& mesh, const Json& query, const ModelEditContext& context) {
    const mm::Soup soup = mm::to_soup(mesh);
    const mm::Edges edges = mm::build_edges(soup);
    sel::Selector selector(soup, edges, context);
    const std::vector<char> mask = selector.faces(query);
    std::vector<char> out(mesh.triangle_count(), 0);
    for (std::size_t t = 0; t < mask.size() && t < soup.src.size(); ++t)
        if (mask[t] && soup.src[t] < out.size()) out[soup.src[t]] = 1;
    return out;
}

}  // namespace fa
