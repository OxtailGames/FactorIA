// Model documents: the catalog of operations, reading and checking a document, finding nodes, and the JSON schema built from the catalog.
// Evaluation is model_eval.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/model_doc.h"

namespace fa {

namespace {

// ---- the catalog -------------------------------------------------------------------------------------------------------------

ModelFieldInfo field(std::string key, std::string type, std::string doc, std::optional<Json> def = std::nullopt, std::optional<double> mn = std::nullopt,
                     std::optional<double> mx = std::nullopt) {
    ModelFieldInfo f;
    f.key = std::move(key);
    f.type = std::move(type);
    f.doc = std::move(doc);
    f.def = std::move(def);
    f.min = mn;
    f.max = mx;
    return f;
}
ModelFieldInfo number(std::string key, std::string doc, double def, double mn, double mx) {
    return field(std::move(key), "number", std::move(doc), Json(def), mn, mx);
}
ModelFieldInfo number_opt(std::string key, std::string doc, double mn, double mx) {
    return field(std::move(key), "number", std::move(doc), std::nullopt, mn, mx);
}
ModelFieldInfo integer(std::string key, std::string doc, int def, int mn, int mx) {
    return field(std::move(key), "integer", std::move(doc), Json(def), mn, mx);
}
ModelFieldInfo integer_opt(std::string key, std::string doc, int mn, int mx) {
    return field(std::move(key), "integer", std::move(doc), std::nullopt, mn, mx);
}
ModelFieldInfo boolean(std::string key, std::string doc, bool def) { return field(std::move(key), "boolean", std::move(doc), Json(def)); }

ModelOpInfo prim(std::string op, std::string doc, std::vector<ModelFieldInfo> fields) {
    return {std::move(op), "primitive", std::move(doc), std::move(fields)};
}

constexpr double kMaxSize = 1000.0;
constexpr double kMinSize = 0.001;

std::vector<ModelOpInfo> build_ops() {
    std::vector<ModelOpInfo> ops;
    ops.push_back(prim("box", "A box centred on its origin; its faces are grids when `segments` is above 1. The size is X (width), Y (height), Z (depth).",
                       {field("size", "size3", "Width, height and depth in metres: one number for a cube, or [x, y, z].", Json::array({1, 1, 1}), kMinSize, kMaxSize),
                        field("segments", "count3", "Subdivisions along X, Y and Z: one integer, or [x, y, z]. Raise it when a later step bends or deforms the box.",
                              Json::array({1, 1, 1}), 1, 64)}));
    ops.push_back(prim("rounded_box", "A box with rounded edges and corners, centred on its origin.",
                       {field("size", "size3", "Width, height and depth in metres: one number for a cube, or [x, y, z].", Json::array({1, 1, 1}), kMinSize, kMaxSize),
                        number("radius", "Radius of the edges and corners in metres. Above half of the smallest side it is cut down to half of it (a pill or a ball).", 0.1, kMinSize, kMaxSize),
                        integer("segments", "Quads in each rounded corner arc: 1 is a bevel, 4 is smooth.", 4, 1, 16)}));
    ops.push_back(prim("cylinder", "An upright cylinder (a frustum when `radiusTop` differs) centred on its origin, with flat caps, its axis along Y.",
                       {number("radius", "Radius of the bottom, in metres.", 0.5, 0, kMaxSize),
                        number_opt("radiusTop", "Radius of the top. Left out: the same as `radius` (a plain cylinder). 0 makes a point (prefer `cone`).", 0, kMaxSize),
                        number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256),
                        integer("heightSegments", "Rings along the side.", 1, 1, 64),
                        boolean("capBottom", "Close the bottom with a disc.", true),
                        boolean("capTop", "Close the top with a disc.", true)}));
    ops.push_back(prim("cone", "A cone with its point up (a frustum when `radiusTop` is above 0), centred on its origin, its axis along Y.",
                       {number("radius", "Radius of the base, in metres.", 0.5, kMinSize, kMaxSize),
                        number("radiusTop", "Radius of the top: 0 is a sharp point, above 0 cuts the tip off.", 0, 0, kMaxSize),
                        number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256),
                        integer("heightSegments", "Rings along the side.", 1, 1, 64),
                        boolean("cap", "Close the base with a disc.", true)}));
    ops.push_back(prim("sphere", "A UV sphere centred on its origin, poles on the Y axis.",
                       {number("radius", "Radius in metres.", 0.5, kMinSize, kMaxSize),
                        integer("segments", "Meridians: sides around the vertical axis.", 24, 3, 256),
                        integer_opt("rings", "Parallels from pole to pole. Left out: half of `segments`.", 2, 256)}));
    ops.push_back(prim("capsule", "A cylinder with a hemisphere at each end, upright, centred on its origin; `height` is tip to tip.",
                       {number("radius", "Radius of the cylinder and of the ends, in metres.", 0.5, kMinSize, kMaxSize),
                        number("height", "Tip to tip along Y, in metres. At least twice the radius (equal: a sphere).", 2, 2 * kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256),
                        integer("rings", "Rings in each hemisphere.", 8, 1, 64),
                        integer("heightSegments", "Rings along the straight part.", 1, 1, 64)}));
    ops.push_back(prim("torus", "A ring (a doughnut) lying flat in the XZ plane, centred on its origin, its hole along Y.",
                       {number("radius", "Radius of the ring: from the centre to the middle of the tube, in metres.", 0.5, kMinSize, kMaxSize),
                        number("tube", "Radius of the tube, in metres. At most `radius`.", 0.15, kMinSize, kMaxSize),
                        integer("segments", "Steps around the ring.", 32, 3, 256),
                        integer("sides", "Sides around the tube.", 16, 3, 128)}));
    ops.push_back(prim("grid", "A flat rectangle in the XZ plane facing +Y, centred on its origin: a floor, a water surface, a cloth to bend. One-sided.",
                       {number("width", "Size along X in metres.", 1, kMinSize, kMaxSize),
                        number("depth", "Size along Z in metres.", 1, kMinSize, kMaxSize),
                        field("segments", "count2", "Cells along X and Z: one integer, or [x, z].", Json::array({1, 1}), 1, 256)}));
    ops.push_back(prim("stairs", "A solid staircase, centred on its bounding box. It climbs towards -Z: the lowest step is at +Z, the top at -Z.",
                       {integer("steps", "Number of steps.", 6, 1, 128),
                        number("width", "Size along X in metres.", 1, kMinSize, kMaxSize),
                        number("height", "Height of the top step above the bottom, in metres.", 1, kMinSize, kMaxSize),
                        number("depth", "Length along Z in metres.", 1.5, kMinSize, kMaxSize)}));
    ops.push_back(prim("arch", "A wall with an arched doorway through it (round top), centred on its bounding box (use `align: \"bottom\"` to stand it on y = 0). The wall is X wide, Y high and Z thick; the doorway goes through along Z.",
                       {number("width", "Width of the wall (X) in metres.", 2, kMinSize, kMaxSize),
                        number("height", "Height of the wall (Y) in metres.", 2.5, kMinSize, kMaxSize),
                        number("depth", "Thickness of the wall (Z) in metres.", 0.4, kMinSize, kMaxSize),
                        number("openingWidth", "Width of the doorway in metres. Less than `width`.", 1, kMinSize, kMaxSize),
                        number("openingHeight", "Height of the doorway from the bottom edge to the top of the arch, in metres. At least half of `openingWidth`, less than `height`.", 1.8, kMinSize, kMaxSize),
                        integer("segments", "Straight pieces in the half circle of the arch.", 12, 2, 64)}));
    ops.push_back(prim("pipe", "A tube: a cylinder with a round hole through it, upright, centred on its origin, open at both ends.",
                       {number("radius", "Outer radius in metres.", 0.5, 2 * kMinSize, kMaxSize),
                        number("innerRadius", "Radius of the hole in metres. Less than `radius`.", 0.4, kMinSize, kMaxSize),
                        number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256)}));
    {
        ModelFieldInfo text = field("text", "string", "The text. Several lines with \"\\n\". At most 200 characters.");
        text.required = true;
        ModelFieldInfo anchor = field("anchor", "choice", "Where the text sits against the origin along X: \"start\" (it begins there), \"middle\" or \"end\".", Json("middle"));
        anchor.choices = {"start", "middle", "end"};
        ops.push_back(prim("text", "Text as a solid, made from the engine's own font data (no system fonts): the letters stand in the XY plane, readable from +Z, thickness along Z centred on 0, the baseline of the first line at y = 0. Holes (the inside of an O) are cut out.",
                           {text,
                            field("font", "string", "\"\" is the built-in DejaVu Sans; \"builtin:serif\", \"builtin:hand\", \"builtin:display\", \"builtin:blackletter\" and \"builtin:pixel\" are the other built-in faces; or a project .ttf / .otf.", Json("")),
                            number("size", "Height of an em in metres (a capital letter is about 0.7 of it).", 1, kMinSize, kMaxSize),
                            number("depth", "Thickness along Z in metres.", 0.2, kMinSize, kMaxSize),
                            integer("curveSegments", "Straight pieces per curve of a letter.", 6, 1, 32),
                            anchor,
                            number("letterSpacing", "Extra space after every letter, in ems.", 0, -1, 5),
                            number("lineSpacing", "Distance between lines, as a multiple of the font's own.", 1, 0.1, 5)}));
    }
    {
        ModelFieldInfo children = field("children", "nodes", "The nodes in the group, evaluated in order and merged into one mesh. A group is also how a `part`, `material` or `color` is given to several nodes at once, and how one transform moves them together.");
        ops.push_back({"group", "group", "Several nodes treated as one: the group's transform applies to all of them, and its part, material and colour are inherited by the ones that do not name their own.", {children}});
    }
    return ops;
}

}  // namespace

const std::vector<ModelOpInfo>& model_ops() {
    static const std::vector<ModelOpInfo> ops = build_ops();
    return ops;
}

const std::vector<ModelFieldInfo>& model_common_fields() {
    static const std::vector<ModelFieldInfo> fields = [] {
        std::vector<ModelFieldInfo> f;
        ModelFieldInfo op = field("op", "string", "What the node is: one of the operations of the catalog (`model.info {}` lists them).");
        op.required = true;
        f.push_back(op);
        f.push_back(field("id", "string", "A name for this node that stays the same when the tree changes: model.edit finds nodes by it. Letters, digits, `_`, `-` and `.`, at most 64 characters, unique in the document."));
        f.push_back(field("note", "string", "A comment for the next person (or AI) reading the document; it has no effect."));
        f.push_back(boolean("enabled", "false leaves the node (and everything below it) out without deleting it.", true));
        f.push_back(field("part", "string", "The part of the model this node and the nodes below it belong to (\"door\", \"left_wheel\"). Parts become submeshes of the baked .glb, named in the primitive's extras, so tools and scripts can find them. Left out: the part of the group above, else none."));
        f.push_back(field("material", "string", "A key of the document's `materials`. Left out: the material of the group above, else the default (white). Nodes with the same part and material share a submesh."));
        f.push_back(field("color", "color", "Vertex colour, [r, g, b] or [r, g, b, a] in 0..1, or \"#rrggbb\" / \"#rrggbbaa\". Multiplies the material's colour when drawn. Left out: the colour of the group above, else none."));
        f.push_back(field("position", "vec3", "Where the node's origin goes, [x, y, z] in metres, relative to the group above.", Json::array({0, 0, 0})));
        f.push_back(field("rotation", "vec3", "Rotation in degrees, [pitch (X), yaw (Y), roll (Z)], applied roll first, then pitch, then yaw.", Json::array({0, 0, 0})));
        f.push_back(field("scale", "size3", "Scale: one number, or [x, y, z]. A negative entry mirrors the node (the triangles are turned so they still face out). Never 0.", Json::array({1, 1, 1})));
        return f;
    }();
    return fields;
}

const std::vector<ModelFieldInfo>& model_align_fields() {
    static const std::vector<ModelFieldInfo> fields = [] {
        ModelFieldInfo align = field("align", "choice", "Where the primitive sits against its origin, along Y, before `position` moves it: \"center\" (its bounding box is centred; text keeps its baseline at 0), \"bottom\" (it stands on y = 0) or \"top\" (it hangs from y = 0).", Json("center"));
        align.choices = {"center", "bottom", "top"};
        return std::vector<ModelFieldInfo>{align};
    }();
    return fields;
}

// ---- reading -----------------------------------------------------------------------------------------------------------------

namespace {

const ModelOpInfo* find_op(std::string_view op) {
    for (const ModelOpInfo& o : model_ops())
        if (o.op == op) return &o;
    return nullptr;
}

std::vector<std::string> op_names() {
    std::vector<std::string> names;
    for (const ModelOpInfo& o : model_ops()) names.push_back(o.op);
    return names;
}

std::string quoted_list(const std::vector<std::string>& names) {
    std::string s;
    for (std::size_t i = 0; i < names.size(); ++i) s += (i ? ", \"" : "\"") + names[i] + "\"";
    return s;
}

std::string num_text(double v) {
    if (v == std::floor(v) && std::fabs(v) < 1e9) return std::format("{}", static_cast<long long>(v));
    return std::format("{:g}", v);
}

std::string range_text(const ModelFieldInfo& f) {
    if (f.min && f.max) return "from " + num_text(*f.min) + " to " + num_text(*f.max);
    if (f.min) return "at least " + num_text(*f.min);
    if (f.max) return "at most " + num_text(*f.max);
    return "";
}

struct Reader {
    std::vector<ModelIssue> issues;
    std::vector<std::string> materialNames;
    std::map<std::string, std::string> ids;  // node id -> pointer
    std::size_t nodeCount = 0;

    void err(std::string pointer, std::string message, std::string hint) { issues.push_back({std::move(pointer), std::move(message), std::move(hint)}); }
};

bool is_integral(const Json& v) { return v.is_number_integer() || (v.is_number_float() && std::isfinite(v.get<double>()) && v.get<double>() == std::floor(v.get<double>())); }

std::optional<Vec4> parse_color(const Json& v) {
    if (v.is_string()) {
        const std::string s = v.get<std::string>();
        if ((s.size() != 7 && s.size() != 9) || s[0] != '#') return std::nullopt;
        float c[4] = {0, 0, 0, 1};
        for (std::size_t i = 0; i < (s.size() - 1) / 2; ++i) {
            int value = 0;
            for (std::size_t k = 0; k < 2; ++k) {
                const char ch = s[1 + i * 2 + k];
                int d;
                if (ch >= '0' && ch <= '9') d = ch - '0';
                else if (ch >= 'a' && ch <= 'f') d = 10 + ch - 'a';
                else if (ch >= 'A' && ch <= 'F') d = 10 + ch - 'A';
                else return std::nullopt;
                value = value * 16 + d;
            }
            c[i] = float(value) / 255.0f;
        }
        return Vec4{c[0], c[1], c[2], c[3]};
    }
    if (!v.is_array() || (v.size() != 3 && v.size() != 4)) return std::nullopt;
    float c[4] = {0, 0, 0, 1};
    for (std::size_t i = 0; i < v.size(); ++i) {
        if (!v[i].is_number()) return std::nullopt;
        const double d = v[i].get<double>();
        if (!std::isfinite(d) || d < 0 || d > 1) return std::nullopt;
        c[i] = float(d);
    }
    return Vec4{c[0], c[1], c[2], c[3]};
}

// Checks one number against the field's range; false (and an issue) when it is not a number or out of range.
bool check_number(Reader& r, const ModelFieldInfo& f, const Json& v, const std::string& pointer, const std::string& what, bool wholeNumber) {
    if (!v.is_number() || !std::isfinite(v.get<double>())) {
        r.err(pointer, what + " must be " + (wholeNumber ? "a whole number" : "a number") + ", got " + describe_json_value(v), f.doc);
        return false;
    }
    if (wholeNumber && !is_integral(v)) {
        r.err(pointer, what + " must be a whole number, got " + describe_json_value(v), f.doc);
        return false;
    }
    const double d = v.get<double>();
    if ((f.min && d < *f.min) || (f.max && d > *f.max)) {
        r.err(pointer, what + " must be " + range_text(f) + ", got " + num_text(d), f.doc);
        return false;
    }
    return true;
}

// Reads the value `v` of `f` into `out` (normalised). False when it had a problem (reported).
bool read_field(Reader& r, const ModelFieldInfo& f, const Json& v, const std::string& pointer, Json& out) {
    const std::string& t = f.type;
    if (t == "number" || t == "integer") {
        if (!check_number(r, f, v, pointer, f.key, t == "integer")) return false;
        out = t == "integer" ? Json(static_cast<long long>(std::llround(v.get<double>()))) : Json(v.get<double>());
        return true;
    }
    if (t == "boolean") {
        if (!v.is_boolean()) {
            r.err(pointer, f.key + " must be true or false, got " + describe_json_value(v), "Write true or false. " + f.doc);
            return false;
        }
        out = v;
        return true;
    }
    if (t == "string" || t == "choice") {
        if (!v.is_string()) {
            r.err(pointer, f.key + " must be " + (f.choices.empty() ? "text" : "one of " + quoted_list(f.choices)) + ", got " + describe_json_value(v), f.doc);
            return false;
        }
        const std::string s = v.get<std::string>();
        if (t == "choice" && std::find(f.choices.begin(), f.choices.end(), s) == f.choices.end()) {
            r.err(pointer, f.key + " must be one of " + quoted_list(f.choices) + ", got \"" + s + "\"", did_you_mean(s, f.choices) + " " + f.doc);
            return false;
        }
        out = v;
        return true;
    }
    if (t == "vec3" || t == "size3" || t == "count3" || t == "count2") {
        const bool counts = t == "count3" || t == "count2";
        const std::size_t n = t == "count2" ? 2 : 3;
        const bool scalarOk = t != "vec3";
        Json parts = Json::array();
        if (scalarOk && v.is_number()) {
            if (!check_number(r, f, v, pointer, f.key, counts)) return false;
            for (std::size_t i = 0; i < n; ++i) parts.push_back(counts ? Json(static_cast<long long>(std::llround(v.get<double>()))) : Json(v.get<double>()));
            out = parts;
            return true;
        }
        if (!v.is_array() || v.size() != n) {
            const std::string shape = n == 2 ? "[x, z]" : "[x, y, z]";
            r.err(pointer, f.key + " must be " + (scalarOk ? "a number or " : "") + "a list " + shape + ", got " + describe_json_value(v), f.doc);
            return false;
        }
        bool ok = true;
        for (std::size_t i = 0; i < n; ++i) {
            const std::string at = pointer + "/" + std::to_string(i);
            if (!check_number(r, f, v[i], at, f.key + "[" + std::to_string(i) + "]", counts)) ok = false;
            else parts.push_back(counts ? Json(static_cast<long long>(std::llround(v[i].get<double>()))) : Json(v[i].get<double>()));
        }
        if (ok) out = parts;
        return ok;
    }
    if (t == "color") {
        if (!parse_color(v)) {
            r.err(pointer, f.key + " must be [r, g, b] or [r, g, b, a] with numbers from 0 to 1, or \"#rrggbb\", got " + describe_json_value(v), "Example: [0.8, 0.2, 0.1] or \"#cc3319\".");
            return false;
        }
        out = v;
        return true;
    }
    r.err(pointer, "internal: unknown field type " + t, "");
    return false;
}

Vec3 to_vec3(const Json& a) { return {a[0].get<float>(), a[1].get<float>(), a[2].get<float>()}; }

std::vector<std::string> allowed_keys(const ModelOpInfo& op) {
    std::vector<std::string> keys;
    for (const ModelFieldInfo& f : model_common_fields()) keys.push_back(f.key);
    if (op.kind == "primitive") keys.push_back("align");
    for (const ModelFieldInfo& f : op.fields) keys.push_back(f.key);
    return keys;
}

// Rules that involve several fields of one operation.
void check_op(Reader& r, const ModelNode& n, const std::string& at) {
    const Json& p = n.params;
    auto num = [&](const char* k) { return p[k].get<double>(); };
    if (n.op == "capsule" && num("height") < 2 * num("radius") - 1e-9)
        r.err(at + "/height", std::format("capsule height {} is less than twice its radius ({}): the two hemispheres do not fit", num("height"), 2 * num("radius")),
              "`height` is tip to tip. Raise it to at least " + num_text(2 * num("radius")) + ", or lower `radius`; for a ball use a sphere.");
    if (n.op == "torus" && num("tube") > num("radius"))
        r.err(at + "/tube", std::format("torus tube {} is larger than its ring radius {}: the tube would cross itself", num("tube"), num("radius")),
              "Make `tube` at most `radius` (a ring radius of 0.5 and a tube of 0.15 is a doughnut).");
    if (n.op == "pipe" && num("innerRadius") >= num("radius"))
        r.err(at + "/innerRadius", std::format("pipe innerRadius {} is not smaller than its radius {}", num("innerRadius"), num("radius")),
              "The hole must be narrower than the outside: lower `innerRadius` or raise `radius`.");
    if (n.op == "arch") {
        if (num("openingWidth") >= num("width"))
            r.err(at + "/openingWidth", std::format("arch openingWidth {} is not smaller than the wall's width {}", num("openingWidth"), num("width")),
                  "The doorway must leave wall on both sides: lower `openingWidth` or raise `width`.");
        if (num("openingHeight") >= num("height"))
            r.err(at + "/openingHeight", std::format("arch openingHeight {} is not smaller than the wall's height {}", num("openingHeight"), num("height")),
                  "The doorway must leave wall above the arch: lower `openingHeight` or raise `height`.");
        if (num("openingHeight") < num("openingWidth") / 2)
            r.err(at + "/openingHeight", std::format("arch openingHeight {} is less than half the opening's width ({}): the half circle does not fit", num("openingHeight"), num("openingWidth") / 2),
                  "Raise `openingHeight` to at least " + num_text(num("openingWidth") / 2) + " or narrow the opening.");
    }
    if (n.op == "cylinder" && p.contains("radiusTop") && num("radius") == 0 && num("radiusTop") == 0)
        r.err(at + "/radius", "a cylinder with both radii 0 has no volume", "Give `radius` or `radiusTop` a size above 0.");
    if (n.op == "text" && p["text"].get<std::string>().empty())
        r.err(at + "/text", "text is empty", "Write the text to build, e.g. \"EXIT\".");
    if (n.op == "text" && p["text"].get<std::string>().size() > 200)
        r.err(at + "/text", "text is longer than 200 characters", "Split it into several text nodes.");
}

bool valid_id(const std::string& id) {
    if (id.empty() || id.size() > 64) return false;
    for (char c : id)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-' || c == '.')) return false;
    return true;
}

ModelNode read_node(Reader& r, const Json& j, const std::string& at, int depth) {
    ModelNode n;
    n.pointer = at;
    if (++r.nodeCount > kModelDocMaxNodes) {
        if (r.nodeCount == kModelDocMaxNodes + 1)
            r.err(at, std::format("the document has more than {} nodes", kModelDocMaxNodes), "Split the model into several documents, or use fewer, bigger primitives.");
        return n;
    }
    if (!j.is_object()) {
        r.err(at, "a node must be an object, got " + describe_json_value(j), "Write {\"op\": \"box\", \"size\": [1, 1, 1]}.");
        return n;
    }
    auto opIt = j.find("op");
    if (opIt == j.end()) {
        r.err(at, "a node needs \"op\"", "Name the operation: " + quoted_list(op_names()) + ".");
        return n;
    }
    if (!opIt->is_string()) {
        r.err(at + "/op", "op must be text, got " + describe_json_value(*opIt), "Name the operation: " + quoted_list(op_names()) + ".");
        return n;
    }
    n.op = opIt->get<std::string>();
    const ModelOpInfo* op = find_op(n.op);
    if (!op) {
        r.err(at + "/op", "unknown operation \"" + n.op + "\"", did_you_mean(n.op, op_names())); 
        return n;
    }
    const std::vector<std::string> keys = allowed_keys(*op);
    for (auto it = j.begin(); it != j.end(); ++it) {
        if (std::find(keys.begin(), keys.end(), it.key()) != keys.end()) continue;
        r.err(at + "/" + it.key(), "\"" + it.key() + "\" is not a field of " + n.op + " nodes", did_you_mean(it.key(), keys));
    }

    // the fields every node has
    if (auto it = j.find("id"); it != j.end()) {
        if (!it->is_string() || !valid_id(it->get<std::string>()))
            r.err(at + "/id", "id must be 1 to 64 letters, digits, '_', '-' or '.', got " + describe_json_value(*it), "Example: \"door_frame\".");
        else {
            n.id = it->get<std::string>();
            auto [pos, fresh] = r.ids.emplace(n.id, at);
            if (!fresh) r.err(at + "/id", "id \"" + n.id + "\" is already used by " + pos->second, "Ids are unique in a document: rename one, or leave the id out.");
        }
    }
    if (auto it = j.find("note"); it != j.end()) {
        if (!it->is_string()) r.err(at + "/note", "note must be text, got " + describe_json_value(*it), "Write a short comment, or remove it.");
        else n.note = it->get<std::string>();
    }
    if (auto it = j.find("enabled"); it != j.end()) {
        if (!it->is_boolean()) r.err(at + "/enabled", "enabled must be true or false, got " + describe_json_value(*it), "Write true or false.");
        else n.enabled = it->get<bool>();
    }
    for (const char* key : {"part", "material"}) {
        auto it = j.find(key);
        if (it == j.end()) continue;
        const std::string ptr = at + "/" + key;
        if (!it->is_string() || it->get<std::string>().empty() || it->get<std::string>().size() > 64) {
            r.err(ptr, std::string(key) + " must be a name of 1 to 64 characters, got " + describe_json_value(*it), std::string("Example: \"") + (std::string(key) == "part" ? "door" : "wood") + "\".");
            continue;
        }
        const std::string s = it->get<std::string>();
        if (std::string(key) == "part") n.part = s;
        else {
            if (std::find(r.materialNames.begin(), r.materialNames.end(), s) == r.materialNames.end())
                r.err(ptr, "material \"" + s + "\" is not in the document's `materials`",
                      (r.materialNames.empty() ? std::string("The document has no materials yet: add {\"materials\": {\"" + s + "\": {\"color\": [0.6, 0.4, 0.2, 1]}}}.")
                                               : did_you_mean(s, r.materialNames)));
            n.material = s;
        }
    }
    if (auto it = j.find("color"); it != j.end()) {
        Json dummy;
        if (read_field(r, *std::find_if(model_common_fields().begin(), model_common_fields().end(), [](const ModelFieldInfo& f) { return f.key == "color"; }), *it, at + "/color", dummy))
            n.color = parse_color(*it);
    }
    for (const ModelFieldInfo& f : model_common_fields()) {
        if (f.key != "position" && f.key != "rotation" && f.key != "scale") continue;
        auto it = j.find(f.key);
        if (it == j.end()) continue;
        Json out;
        if (!read_field(r, f, *it, at + "/" + f.key, out)) continue;
        if (f.key == "scale") {
            bool zero = false;
            for (std::size_t i = 0; i < 3; ++i)
                if (std::fabs(out[i].get<double>()) < 1e-4) zero = true;
            if (zero) {
                r.err(at + "/scale", "scale " + out.dump() + " has an entry of (almost) 0, which flattens the node to nothing", "Use a small non-zero value, or `enabled: false` to leave the node out.");
                continue;
            }
        }
        (f.key == "position" ? n.position : f.key == "rotation" ? n.rotation : n.scale) = to_vec3(out);
    }
    if (op->kind == "primitive") {
        if (auto it = j.find("align"); it != j.end()) {
            Json out;
            if (read_field(r, model_align_fields()[0], *it, at + "/align", out)) n.align = out.get<std::string>();
        }
    }

    // the fields of the operation
    for (const ModelFieldInfo& f : op->fields) {
        auto it = j.find(f.key);
        if (f.type == "nodes") {
            if (it == j.end()) continue;
            if (!it->is_array()) {
                r.err(at + "/" + f.key, "children must be a list of nodes, got " + describe_json_value(*it), "Write \"children\": [{\"op\": \"box\"}].");
                continue;
            }
            if (depth >= kModelDocMaxDepth) {
                r.err(at + "/children", std::format("groups are nested more than {} levels deep", kModelDocMaxDepth), "Flatten the tree: a group inside a group inside... rarely needs to be that deep.");
                continue;
            }
            for (std::size_t i = 0; i < it->size(); ++i) n.children.push_back(read_node(r, (*it)[i], at + "/children/" + std::to_string(i), depth + 1));
            continue;
        }
        if (it == j.end()) {
            if (f.required) r.err(at, n.op + " nodes need \"" + f.key + "\"", f.doc);
            else if (f.def) n.params[f.key] = *f.def;
            continue;
        }
        Json out;
        if (read_field(r, f, *it, at + "/" + f.key, out)) n.params[f.key] = out;
        else if (f.def) n.params[f.key] = *f.def;  // keep going with something, to list the other problems
    }
    // check_op reads fields with defaults; skip when a field it needs failed
    bool complete = true;
    for (const ModelFieldInfo& f : op->fields)
        if (f.type != "nodes" && (f.def || f.required) && !n.params.contains(f.key)) complete = false;
    if (complete) check_op(r, n, at);
    return n;
}

}  // namespace

Result<ModelDoc> parse_model_doc(const Json& json, std::string_view file, std::vector<ModelIssue>* issuesOut) {
    Reader r;
    ModelDoc doc;
    auto finish = [&]() -> Result<ModelDoc> {
        if (issuesOut) *issuesOut = r.issues;
        if (r.issues.empty()) return doc;
        const ModelIssue& first = r.issues.front();
        std::string where = std::string(file);
        if (!first.pointer.empty()) where += (where.empty() ? "" : " ") + first.pointer;
        std::string message = (where.empty() ? "" : where + ": ") + first.message;
        if (r.issues.size() > 1) message += std::format(" (and {} more problem{})", r.issues.size() - 1, r.issues.size() == 2 ? "" : "s");
        return make_error(message, first.hint.empty() ? "docs/MODELING.md describes the format and schemas/model.schema.json lists every field." : first.hint);
    };
    if (!json.is_object()) {
        r.err("", "a model document must be a JSON object, got " + describe_json_value(json), "Start from `model.create`, or write {\"format\": \"factoria.model/1\", \"nodes\": [{\"op\": \"box\"}]}.");
        return finish();
    }
    static const std::vector<std::string> topKeys = {"$schema", "format", "doc", "output", "materials", "nodes"};
    for (auto it = json.begin(); it != json.end(); ++it)
        if (std::find(topKeys.begin(), topKeys.end(), it.key()) == topKeys.end())
            r.err("/" + it.key(), "\"" + it.key() + "\" is not a field of a model document", did_you_mean(it.key(), topKeys));
    if (auto it = json.find("format"); it == json.end())
        r.err("/format", "the document has no \"format\"", std::string("Add \"format\": \"") + kModelDocFormat + "\".");
    else if (!it->is_string() || it->get<std::string>() != kModelDocFormat)
        r.err("/format", "format must be \"" + std::string(kModelDocFormat) + "\", got " + describe_json_value(*it), "This reader only knows format 1.");
    if (auto it = json.find("doc"); it != json.end()) {
        if (!it->is_string()) r.err("/doc", "doc must be text, got " + describe_json_value(*it), "Say in a sentence what the model is and where the game uses it.");
        else doc.doc = it->get<std::string>();
    }
    if (auto it = json.find("output"); it != json.end()) {
        if (!it->is_object()) r.err("/output", "output must be an object like {\"path\": \"assets/models/door.glb\"}, got " + describe_json_value(*it), "Leave it out to bake next to the document.");
        else {
            for (auto o = it->begin(); o != it->end(); ++o)
                if (o.key() != "path") r.err("/output/" + o.key(), "\"" + o.key() + "\" is not a field of output", did_you_mean(o.key(), std::vector<std::string>{"path"}));
            if (auto p = it->find("path"); p != it->end()) {
                if (!p->is_string() || !ends_with(to_lower(p->get<std::string>()), ".glb")) r.err("/output/path", "output.path must be a project path ending in .glb, got " + describe_json_value(*p), "Example: \"assets/models/door.glb\".");
                else doc.outputPath = p->get<std::string>();
            }
        }
    }
    if (auto it = json.find("materials"); it != json.end()) {
        if (!it->is_object()) r.err("/materials", "materials must be an object of named materials, got " + describe_json_value(*it), "Example: {\"wood\": {\"color\": [0.6, 0.4, 0.2, 1], \"roughness\": 0.8}}.");
        else
            for (auto m = it->begin(); m != it->end(); ++m) {
                const std::string at = "/materials/" + m.key();
                if (m.key().empty() || m.key().size() > 64) {
                    r.err(at, "a material name must be 1 to 64 characters", "Example: \"wood\".");
                    continue;
                }
                if (!m->is_object()) {
                    r.err(at, "a material must be an object like {\"color\": [r, g, b, a]}, got " + describe_json_value(*m), "Fields: color, texture, metallic, roughness, emissive, doubleSided, blend.");
                    continue;
                }
                if (m->contains("name")) {
                    r.err(at + "/name", "a material is named by its key (\"" + m.key() + "\"), not by a `name` field", "Remove `name`.");
                    continue;
                }
                auto mat = mesh_material_from_json(*m, "material '" + m.key() + "'");
                if (!mat.ok()) {
                    r.err(at, mat.error().message, mat.error().hint);
                    continue;
                }
                for (const char* k : {"metallic", "roughness"})
                    if (m->contains(k) && (*m)[k].is_number() && ((*m)[k].get<double>() < 0 || (*m)[k].get<double>() > 1))
                        r.err(at + "/" + k, std::string(k) + " must be from 0 to 1, got " + describe_json_value((*m)[k]), "0 is none, 1 is full.");
                mat->name = m.key();
                r.materialNames.push_back(m.key());
                doc.materials.emplace_back(m.key(), std::move(*mat));
            }
    }
    if (auto it = json.find("nodes"); it == json.end())
        r.err("/nodes", "the document has no \"nodes\"", "Add the list of operations, e.g. \"nodes\": [{\"op\": \"box\", \"size\": [1, 2, 1]}].");
    else if (!it->is_array())
        r.err("/nodes", "nodes must be a list, got " + describe_json_value(*it), "Write \"nodes\": [{\"op\": \"box\"}].");
    else
        for (std::size_t i = 0; i < it->size(); ++i) doc.nodes.push_back(read_node(r, (*it)[i], "/nodes/" + std::to_string(i), 1));
    return finish();
}

Result<ModelDoc> load_model_doc(std::string_view path, std::vector<ModelIssue>* issues) {
    auto text = fs::read_text(path);
    if (!text)
        return make_error(std::string(path) + ": cannot read the model document: " + text.error().message,
                          text.error().hint.empty() ? "Model documents are *.model.json files; model.create writes a starting point." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_model_doc(*json, path, issues);
}

// ---- finding nodes -----------------------------------------------------------------------------------------------------------

namespace {

void collect_ids(const Json& list, const std::string& base, std::vector<std::pair<std::string, std::string>>& out) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& n = list[i];
        if (!n.is_object()) continue;
        const std::string at = base + "/" + std::to_string(i);
        if (n.contains("id") && n["id"].is_string()) out.emplace_back(n["id"].get<std::string>(), at);
        if (n.contains("children")) collect_ids(n["children"], at + "/children", out);
    }
}

}  // namespace

std::vector<std::pair<std::string, std::string>> model_node_ids(const Json& documentJson) {
    std::vector<std::pair<std::string, std::string>> out;
    if (documentJson.is_object() && documentJson.contains("nodes")) collect_ids(documentJson["nodes"], "/nodes", out);
    return out;
}

Json* find_model_node(Json& doc, std::string_view ref, std::string* pointer, std::string* why) {
    auto fail = [&](std::string message) -> Json* {
        if (why) *why = std::move(message);
        return nullptr;
    };
    const auto ids = model_node_ids(doc);
    std::vector<std::string> names;
    for (const auto& [id, at] : ids) names.push_back(id);
    const std::string known = names.empty() ? "The document has no node ids yet (model.edit's `add` gives every new node one)." : "Ids in the document: " + quoted_list(names) + ".";
    if (ref.empty()) return fail("Empty node reference. " + known);
    std::string at;
    if (ref[0] == '/') {
        at = std::string(ref);
    } else {
        for (const auto& [id, p] : ids)
            if (id == ref) at = p;
        if (at.empty()) return fail("No node has the id \"" + std::string(ref) + "\". " + did_you_mean(ref, names));
    }
    // walk the pointer by hand: only /nodes/<i> and /children/<i> are nodes
    const std::vector<std::string> parts = split(at, '/');
    if (parts.size() < 2 || parts[0] != "nodes" || parts.size() % 2 != 0) return fail("'" + at + "' is not a node pointer. Node pointers look like /nodes/0 or /nodes/1/children/2. " + known);
    Json* cur = &doc;
    for (std::size_t i = 0; i < parts.size(); ++i) {
        if (i % 2 == 1) {
            const std::string& idx = parts[i];
            if (idx.empty() || !std::all_of(idx.begin(), idx.end(), [](char c) { return c >= '0' && c <= '9'; }) || idx.size() > 6)
                return fail("'" + at + "': '" + idx + "' is not a list position. " + known);
            const std::size_t k = std::stoul(idx);
            if (!cur->is_array() || k >= cur->size()) return fail("'" + at + "' is outside the document (position " + idx + " of " + std::to_string(cur->is_array() ? cur->size() : 0) + "). " + known);
            cur = &(*cur)[k];
        } else {
            if (parts[i] != (i == 0 ? "nodes" : "children") || !cur->is_object() || !cur->contains(parts[i])) return fail("'" + at + "' does not lead to a node. " + known);
            cur = &(*cur)[parts[i]];
        }
    }
    if (!cur->is_object()) return fail("'" + at + "' is not a node. " + known);
    if (pointer) *pointer = at;
    return cur;
}

// ---- schema ------------------------------------------------------------------------------------------------------------------

namespace {

Json number_schema(const ModelFieldInfo& f, bool whole) {
    Json s = Json::object({{"type", whole ? "integer" : "number"}});
    if (f.min) s["minimum"] = whole ? Json(static_cast<long long>(*f.min)) : Json(*f.min);
    if (f.max) s["maximum"] = whole ? Json(static_cast<long long>(*f.max)) : Json(*f.max);
    return s;
}

Json field_schema(const ModelFieldInfo& f) {
    Json s;
    const std::string& t = f.type;
    if (t == "number") s = number_schema(f, false);
    else if (t == "integer") s = number_schema(f, true);
    else if (t == "boolean") s = Json::object({{"type", "boolean"}});
    else if (t == "string") s = Json::object({{"type", "string"}});
    else if (t == "choice") s = Json::object({{"type", "string"}, {"enum", f.choices}});
    else if (t == "vec3" || t == "size3" || t == "count3" || t == "count2") {
        const bool counts = t == "count3" || t == "count2";
        const std::size_t n = t == "count2" ? 2 : 3;
        Json array = Json::object({{"type", "array"}, {"items", number_schema(f, counts)}, {"minItems", n}, {"maxItems", n}});
        if (t == "vec3") s = array;
        else s = Json::object({{"anyOf", Json::array({number_schema(f, counts), array})}});
    } else if (t == "color") {
        Json array = Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})}, {"minItems", 3}, {"maxItems", 4}});
        s = Json::object({{"anyOf", Json::array({array, Json::object({{"type", "string"}, {"pattern", "^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"}})})}});
    } else if (t == "nodes") {
        s = Json::object({{"type", "array"}, {"items", Json::object({{"$ref", "#/$defs/node"}})}});
    }
    s["description"] = f.doc;
    if (f.def) s["default"] = *f.def;
    return s;
}

}  // namespace

Json model_doc_schema() {
    Json defs = Json::object();
    Json alternatives = Json::array();
    for (const ModelOpInfo& op : model_ops()) {
        Json props = Json::object();
        Json required = Json::array({"op"});
        props["op"] = Json::object({{"const", op.op}, {"description", "Always \"" + op.op + "\" for this node."}});
        for (const ModelFieldInfo& f : model_common_fields()) {
            if (f.key == "op") continue;
            props[f.key] = field_schema(f);
        }
        if (op.kind == "primitive")
            for (const ModelFieldInfo& f : model_align_fields()) props[f.key] = field_schema(f);
        for (const ModelFieldInfo& f : op.fields) {
            props[f.key] = field_schema(f);
            if (f.required) required.push_back(f.key);
        }
        defs[op.op] = Json::object({{"type", "object"}, {"description", op.doc}, {"required", required}, {"additionalProperties", false}, {"properties", props}});
        alternatives.push_back(Json::object({{"$ref", "#/$defs/" + op.op}}));
    }
    defs["node"] = Json::object({{"description", "One operation of the tree: a primitive or a group. `op` says which."}, {"oneOf", alternatives}});
    Json material = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "A material, named by its key in `materials`. Written into the .glb as a glTF material."},
         {"properties",
          Json::object({{"color", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 3}, {"maxItems", 4}, {"description", "Base colour [r, g, b, a], 0..1. Default white."}})},
                        {"texture", Json::object({{"type", "string"}, {"description", "A project image used as the base colour texture, e.g. \"assets/textures/wood.png\". The model's uvs are per primitive (docs/MODELING.md)."}})},
                        {"metallic", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "0..1. Default 0."}})},
                        {"roughness", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "0..1. Default 0.6."}})},
                        {"emissive", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 3}, {"maxItems", 4}, {"description", "Light the surface gives off [r, g, b], 0..1. Default none."}})},
                        {"doubleSided", Json::object({{"type", "boolean"}, {"description", "Draw back faces too (flat leaves, cloth). Default false."}})},
                        {"blend", Json::object({{"type", "boolean"}, {"description", "Alpha-blended (glass); the alpha of `color` and of vertex colours shows. Default false."}})}})}});
    return Json::object(
        {{"$schema", "https://json-schema.org/draft/2020-12/schema"},
         {"$id", "https://factoria.dev/schemas/model.schema.json"},
         {"title", "FactorIA model document (*.model.json)"},
         {"description", "A 3D model as a tree of operations (primitives, groups, transforms) with named parts, materials and vertex colours. `model.bake` evaluates it and writes the .glb next to it; the same bytes on every platform. Errors name the file and the JSON pointer; docs/MODELING.md explains the format and `model.info {}` lists the operations."},
         {"type", "object"},
         {"required", Json::array({"format", "nodes"})},
         {"additionalProperties", false},
         {"properties",
          Json::object({{"$schema", Json::object({{"type", "string"}, {"description", "Optional schema reference for editors."}})},
                        {"format", Json::object({{"const", kModelDocFormat}, {"description", std::string("File format identifier. Always \"") + kModelDocFormat + "\"."}})},
                        {"doc", Json::object({{"type", "string"}, {"description", "What the model is and where the game uses it."}})},
                        {"output", Json::object({{"type", "object"}, {"additionalProperties", false}, {"description", "Where `model.bake` writes the .glb."},
                                                 {"properties", Json::object({{"path", Json::object({{"type", "string"}, {"pattern", "\\.[gG][lL][bB]$"}, {"description", "Project-relative file under assets/ ending in .glb. Left out: next to the document, with .glb instead of .model.json."}})}})}})},
                        {"materials", Json::object({{"type", "object"}, {"description", "Named materials the nodes refer to with `material`."}, {"additionalProperties", material}})},
                        {"nodes", Json::object({{"type", "array"}, {"description", "The tree: operations evaluated in order and merged into one mesh."}, {"items", Json::object({{"$ref", "#/$defs/node"}})}})}})},
         {"$defs", defs}});
}

}  // namespace fa
