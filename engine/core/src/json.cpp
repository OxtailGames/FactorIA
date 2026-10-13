#include "fa/core/json.h"

#include <array>
#include <cmath>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {
namespace {

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

// 1-based line / column of a 0-based byte offset.
std::pair<int, int> line_col(std::string_view text, std::size_t offset) {
    offset = std::min(offset, text.size());
    int line = 1, col = 1;
    for (std::size_t i = 0; i < offset; ++i) {
        if (text[i] == '\n') { ++line; col = 1; }
        else ++col;
    }
    return {line, col};
}

// Guess what went wrong from the characters around the failing byte.
std::string parse_hint(std::string_view text, std::size_t offset, const std::string& what) {
    auto at = [&](std::size_t i) { return i < text.size() ? text[i] : '\0'; };
    char c = at(offset);
    std::size_t prev = offset;
    while (prev > 0 && std::isspace(static_cast<unsigned char>(at(prev - 1)))) --prev;
    char before = prev > 0 ? at(prev - 1) : '\0';
    if ((c == '}' || c == ']') && before == ',') return "Remove the trailing comma before '" + std::string(1, c) + "' (JSON does not allow it).";
    if (c == '\'') return "JSON strings use double quotes (\"), not single quotes.";
    if (c == '/') return "JSON does not allow comments; remove them (put notes in a \"_comment\" or \"description\" key).";
    if (what.find("end of input") != std::string::npos || offset >= text.size())
        return "The file ends too early: close every '{' / '[' and every string.";
    if (std::isalpha(static_cast<unsigned char>(c)) && (before == '{' || before == ','))
        return "Object keys must be quoted: \"key\": value.";
    if (before == '"' || before == '}' || before == ']' || std::isdigit(static_cast<unsigned char>(before)))
        return "A comma is probably missing between the previous value and this one.";
    return "Check brackets, commas and quotes near this position (a JSON linter such as `python -m json.tool` helps).";
}

bool is_number(const Json& j) { return j.is_number(); }

// Reads [a, b, ...] or {"x":..} with `keys` into out[0..n).
bool read_components(const Json& j, float* out, int n, const char* const* keys, int minArray, const char* form,
                     std::string* err) {
    auto fail = [&](const std::string& why) {
        if (err) *err = std::string("expected ") + form + ", got " + describe_json_value(j) + (why.empty() ? "" : " (" + why + ")");
        return false;
    };
    if (j.is_array()) {
        if (int(j.size()) < minArray || int(j.size()) > n) return fail("array has " + std::to_string(j.size()) + " numbers");
        for (std::size_t i = 0; i < j.size(); ++i) {
            if (!is_number(j[i])) return fail("element " + std::to_string(i) + " is not a number");
            out[i] = j[i].get<float>();
        }
        return true;
    }
    if (j.is_object()) {
        for (auto it = j.begin(); it != j.end(); ++it) {
            int idx = -1;
            for (int k = 0; k < n; ++k)
                if (it.key() == keys[k]) idx = k;
            if (idx < 0) return fail("unknown key '" + it.key() + "'");
            if (!is_number(it.value())) return fail("key '" + it.key() + "' is not a number");
            out[idx] = it.value().get<float>();
        }
        return true;
    }
    return fail("");
}

struct NamedColor { std::string_view name; Color color; };
const std::array<NamedColor, 15> kColors = {{
    {"white", {1, 1, 1, 1}},
    {"black", {0, 0, 0, 1}},
    {"red", {1, 0, 0, 1}},
    {"green", {0, 1, 0, 1}},
    {"blue", {0, 0, 1, 1}},
    {"yellow", {1, 1, 0, 1}},
    {"cyan", {0, 1, 1, 1}},
    {"magenta", {1, 0, 1, 1}},
    {"gray", {0.5f, 0.5f, 0.5f, 1}},
    {"grey", {0.5f, 0.5f, 0.5f, 1}},
    {"orange", {1, 0.6471f, 0, 1}},
    {"purple", {0.5f, 0, 0.5f, 1}},
    {"pink", {1, 0.7529f, 0.7961f, 1}},
    {"brown", {0.6471f, 0.1647f, 0.1647f, 1}},
    {"transparent", {0, 0, 0, 0}},
}};

int hex_digit(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

}  // namespace

std::string describe_json_value(const Json& j) {
    std::string kind;
    switch (j.type()) {
        case Json::value_t::null: return "null";
        case Json::value_t::boolean: return j.get<bool>() ? "true" : "false";
        case Json::value_t::string: kind = "string "; break;
        case Json::value_t::number_integer:
        case Json::value_t::number_unsigned:
        case Json::value_t::number_float: kind = "number "; break;
        case Json::value_t::array: kind = "array "; break;
        case Json::value_t::object: kind = "object "; break;
        default: break;
    }
    std::string text = j.dump(-1, ' ', false, Json::error_handler_t::replace);
    if (text.size() > 60) text = text.substr(0, 57) + "...";
    return kind + text;
}

Result<Json> parse_json(std::string_view text, std::string_view sourceName) {
    try {
        return Json::parse(text.begin(), text.end());
    } catch (const Json::parse_error& e) {
        std::size_t byte = e.byte > 0 ? std::size_t(e.byte) - 1 : 0;
        auto [line, col] = line_col(text, byte);
        // nlohmann prefixes messages with "[json.exception.parse_error.101] parse error at line 1, column 5: ".
        std::string what = e.what();
        std::size_t colon = what.find(": ");
        if (colon != std::string::npos && what.find("parse error") != std::string::npos) what = what.substr(colon + 2);
        std::string msg = std::string(sourceName) + ":" + std::to_string(line) + ":" + std::to_string(col) +
                          ": invalid JSON: " + what;
        return make_error(std::move(msg), parse_hint(text, byte, what));
    }
}

Result<Json> load_json_file(std::string_view path) {
    auto text = fs::read_text(path);
    if (!text) return text.error();
    return parse_json(text.value(), path);
}

std::string dump_json(const Json& j) {
    return j.dump(2, ' ', false, Json::error_handler_t::replace) + "\n";
}

Result<void> save_json_file(std::string_view path, const Json& j) {
    return fs::write_text(path, dump_json(j));
}

bool json_to(const Json& j, bool& out, std::string* err) {
    if (j.is_boolean()) { out = j.get<bool>(); return true; }
    if (err) *err = "expected true or false, got " + describe_json_value(j);
    return false;
}

bool json_to(const Json& j, int& out, std::string* err) {
    if (j.is_number_integer() || j.is_number_unsigned()) { out = j.get<int>(); return true; }
    if (j.is_number_float()) {
        double d = j.get<double>();
        if (d == std::floor(d) && std::fabs(d) < 2147483648.0) { out = int(d); return true; }
        if (err) *err = "expected an integer, got " + describe_json_value(j) + " (use a whole number)";
        return false;
    }
    if (err) *err = "expected an integer, got " + describe_json_value(j);
    return false;
}

bool json_to(const Json& j, float& out, std::string* err) {
    if (j.is_number()) { out = j.get<float>(); return true; }
    if (err) *err = "expected a number, got " + describe_json_value(j);
    return false;
}

bool json_to(const Json& j, std::string& out, std::string* err) {
    if (j.is_string()) { out = j.get<std::string>(); return true; }
    if (err) *err = "expected a string, got " + describe_json_value(j);
    return false;
}

bool json_to(const Json& j, Vec2& out, std::string* err) {
    static const char* const keys[] = {"x", "y"};
    float v[2] = {0, 0};
    if (!read_components(j, v, 2, keys, 2, "[x, y] or {\"x\":..,\"y\":..}", err)) return false;
    out = {v[0], v[1]};
    return true;
}

bool json_to(const Json& j, Vec3& out, std::string* err) {
    static const char* const keys[] = {"x", "y", "z"};
    float v[3] = {0, 0, 0};
    if (!read_components(j, v, 3, keys, 2, "[x, y, z] or {\"x\":..,\"y\":..,\"z\":..}", err)) return false;
    out = {v[0], v[1], v[2]};
    return true;
}

bool json_to(const Json& j, Vec4& out, std::string* err) {
    static const char* const keys[] = {"x", "y", "z", "w"};
    float v[4] = {0, 0, 0, 0};
    if (!read_components(j, v, 4, keys, 4, "[x, y, z, w] or {\"x\":..,\"y\":..,\"z\":..,\"w\":..}", err)) return false;
    out = {v[0], v[1], v[2], v[3]};
    return true;
}

bool json_to(const Json& j, Color& out, std::string* err) {
    static const char* const keys[] = {"r", "g", "b", "a"};
    constexpr const char* form = "[r, g, b(, a)] (0..1), \"#rrggbb\", \"#rrggbbaa\" or a color name like \"red\"";
    if (j.is_string()) {
        if (parse_color(j.get<std::string>(), out)) return true;
        if (err) {
            std::vector<std::string> names;
            for (auto n : color_names()) names.emplace_back(n);
            *err = "expected " + std::string(form) + ", got " + describe_json_value(j) + ". " +
                   did_you_mean(j.get<std::string>(), names, 20);
        }
        return false;
    }
    float v[4] = {0, 0, 0, 1};
    if (j.is_array()) {
        if (j.size() < 3 || j.size() > 4) {
            if (err) *err = std::string("expected ") + form + ", got " + describe_json_value(j);
            return false;
        }
        if (!read_components(j, v, 4, keys, 3, form, err)) return false;
        bool bytes = false;
        for (std::size_t i = 0; i < j.size(); ++i) bytes |= v[i] > 1.0f;
        if (bytes) for (std::size_t i = 0; i < j.size(); ++i) v[i] /= 255.0f;  // 0..255 form
    } else if (!read_components(j, v, 4, keys, 3, form, err)) {
        return false;
    }
    out = {v[0], v[1], v[2], v[3]};
    return true;
}

bool json_to(const Json& j, Rect& out, std::string* err) {
    static const char* const keys[] = {"x", "y", "w", "h"};
    float v[4] = {0, 0, 0, 0};
    if (!read_components(j, v, 4, keys, 4, "[x, y, w, h] or {\"x\":..,\"y\":..,\"w\":..,\"h\":..}", err)) return false;
    out = {v[0], v[1], v[2], v[3]};
    return true;
}

Json to_json(float v) { return round4(double(v)); }
Json to_json(Vec2 v) { return Json::array({round4(v.x), round4(v.y)}); }
Json to_json(Vec3 v) { return Json::array({round4(v.x), round4(v.y), round4(v.z)}); }
Json to_json(Vec4 v) { return Json::array({round4(v.x), round4(v.y), round4(v.z), round4(v.w)}); }
Json to_json(Color c) { return Json::array({round4(c.r), round4(c.g), round4(c.b), round4(c.a)}); }
Json to_json(const Rect& r) { return Json::array({round4(r.x), round4(r.y), round4(r.w), round4(r.h)}); }

bool parse_color(std::string_view text, Color& out) {
    text = trim(text);
    if (text.empty()) return false;
    if (text[0] == '#') {
        std::string_view h = text.substr(1);
        int d[8];
        if (h.size() != 3 && h.size() != 4 && h.size() != 6 && h.size() != 8) return false;
        for (std::size_t i = 0; i < h.size(); ++i) {
            d[i] = hex_digit(h[i]);
            if (d[i] < 0) return false;
        }
        float c[4] = {0, 0, 0, 1};
        if (h.size() <= 4) {
            for (std::size_t i = 0; i < h.size(); ++i) c[i] = float(d[i] * 17) / 255.0f;
        } else {
            for (std::size_t i = 0; i < h.size() / 2; ++i) c[i] = float(d[i * 2] * 16 + d[i * 2 + 1]) / 255.0f;
        }
        out = {c[0], c[1], c[2], c[3]};
        return true;
    }
    for (const NamedColor& n : kColors) {
        if (iequals(text, n.name)) { out = n.color; return true; }
    }
    return false;
}

std::span<const std::string_view> color_names() {
    static const std::array<std::string_view, 15> names = [] {
        std::array<std::string_view, 15> a;
        for (std::size_t i = 0; i < kColors.size(); ++i) a[i] = kColors[i].name;
        return a;
    }();
    return names;
}

const Json* json_at(const Json& root, std::string_view pointer) {
    if (pointer.empty()) return &root;
    try {
        Json::json_pointer ptr{std::string(pointer)};
        if (!root.contains(ptr)) return nullptr;
        return &root.at(ptr);
    } catch (const Json::exception&) {
        return nullptr;
    }
}

void json_merge(Json& target, const Json& patch) {
    if (patch.is_object() && target.is_object()) {
        for (auto it = patch.begin(); it != patch.end(); ++it) {
            if (target.contains(it.key())) json_merge(target[it.key()], it.value());
            else target[it.key()] = it.value();
        }
    } else {
        target = patch;
    }
}

}  // namespace fa
