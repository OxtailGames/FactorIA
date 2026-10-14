// JSON -> CastShape for the physics.shape_cast command and physics.shapeCast in scripts (one parser, one set of
// messages).
#include <cmath>
#include <string>
#include <vector>

#include "fa/core/strings.h"
#include "fa/physics/physics.h"

namespace fa {

namespace {

std::string example(bool is3d) {
    return is3d ? R"({"shape":"sphere","radius":0.5} or {"shape":"box","size":[1,2,1]})"
                : R"({"shape":"circle","radius":8} or {"shape":"box","size":[16,24]})";
}
Error fail(const std::string& message, bool is3d, const std::string& extra = {}) {
    return make_error(message, (extra.empty() ? "" : extra + " ") + "Example: " + example(is3d) + ".");
}

// A positive, finite number.
bool positive(const Json& v, float& out) {
    if (!v.is_number()) return false;
    double d = v.get<double>();
    if (!std::isfinite(d) || d <= 0.0) return false;
    out = static_cast<float>(d);
    return true;
}

// [a, b(, c)] or {x, y(, z)}: exactly `n` positive numbers.
bool positive_list(const Json& v, std::size_t n, float* out) {
    if (v.is_array()) {
        if (v.size() != n) return false;
        for (std::size_t i = 0; i < n; ++i)
            if (!positive(v[i], out[i])) return false;
        return true;
    }
    if (!v.is_object()) return false;
    static const char* const keys[] = {"x", "y", "z"};
    if (v.size() != n) return false;
    for (std::size_t i = 0; i < n; ++i) {
        auto it = v.find(keys[i]);
        if (it == v.end() || !positive(*it, out[i])) return false;
    }
    return true;
}

}  // namespace

Result<CastShape> cast_shape_from_json(const Json& j, bool is3d) {
    const char* dim = is3d ? "3D" : "2D";
    const char* unit = is3d ? "meters" : "pixels";
    if (!j.is_object())
        return fail("A cast shape must be an object with a \"shape\" name, but got " + j.dump() + ".", is3d);
    auto sh = j.find("shape");
    if (sh == j.end())
        return fail(std::string("The cast shape has no \"shape\" name; a ") + dim + " cast takes " +
                        (is3d ? "\"sphere\" or \"box\"" : "\"circle\" or \"box\"") + ".",
                    is3d);
    if (!sh->is_string())
        return fail("The cast shape's \"shape\" must be a string, but got " + sh->dump() + ".", is3d);
    const std::string name = sh->get<std::string>();
    const std::string lower = to_lower(name);

    CastShape out;
    if (lower == "box") {
        out.kind = CastShape::Kind::Box;
    } else if (lower == (is3d ? "sphere" : "circle")) {
        out.kind = CastShape::Kind::Circle;
    } else if (lower == (is3d ? "circle" : "sphere")) {
        const std::string what = std::string("\"") + name + "\" is a " + (is3d ? "2D" : "3D") + " shape, but this is a " +
                                 dim + " cast (" + (is3d ? "from/to have a z" : "from/to are 2D") + ").";
        return fail(what, is3d,
                    is3d ? "A 3D cast uses \"sphere\" (radius) or \"box\" (size [x, y, z]); \"circle\" is the 2D name."
                         : "A 2D cast uses \"circle\" (radius) or \"box\" (size [width, height]); pass 3D from/to "
                           "(with z) to cast a \"sphere\".");
    } else {
        const std::vector<std::string> names =
            is3d ? std::vector<std::string>{"sphere", "box"} : std::vector<std::string>{"circle", "box"};
        return fail("Unknown " + std::string(dim) + " cast shape \"" + name + "\". " + did_you_mean(name, names), is3d);
    }

    const bool circle = out.kind == CastShape::Kind::Circle;
    const char* shapeName = circle ? (is3d ? "sphere" : "circle") : "box";
    for (auto it = j.begin(); it != j.end(); ++it) {
        const std::string& key = it.key();
        if (key == "shape" || key == (circle ? "radius" : "size")) continue;
        if (key == "radius" || key == "size") {  // the other shape's size key
            const std::string used = circle ? "\"size\"" : "\"radius\"", wanted = circle ? "\"radius\"" : "\"size\"";
            const std::string form = circle ? "a positive number" : is3d ? "[x, y, z]" : "[width, height]";
            return fail(std::string("A ") + shapeName + " is sized by " + wanted + ", not " + used + ".", is3d,
                        "Give " + wanted + " as " + form + " in " + unit + ".");
        }
        const std::vector<std::string> keys = {"shape", circle ? "radius" : "size"};
        return fail("Unknown key \"" + key + "\" in the " + shapeName + " cast shape. " + did_you_mean(key, keys), is3d);
    }

    if (circle) {
        auto r = j.find("radius");
        if (r == j.end() || !positive(*r, out.radius))
            return fail(std::string("A ") + shapeName + " cast needs \"radius\", a positive number in " + unit +
                            (r == j.end() ? "." : ", but got " + r->dump() + "."),
                        is3d);
    } else {
        auto s = j.find("size");
        float v[3] = {1, 1, 1};
        const std::size_t n = is3d ? 3 : 2;
        if (s == j.end() || !positive_list(*s, n, v)) {
            const std::string form = is3d ? "[x, y, z]" : "[width, height]";
            const bool wrongCount = s != j.end() && s->is_array() && s->size() == (is3d ? 2u : 3u);
            return fail(std::string("A ") + dim + " box cast needs \"size\", " + form + " as positive numbers in " + unit +
                            (s == j.end() ? "." : ", but got " + s->dump() + "."),
                        is3d,
                        !wrongCount ? ""
                        : is3d      ? "A 3D box needs all three dimensions."
                                    : "A 2D box has no depth; use [width, height].");
        }
        out.size = {v[0], v[1], is3d ? v[2] : 1.0f};
    }
    return out;
}

}  // namespace fa
