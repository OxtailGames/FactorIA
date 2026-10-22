// The text patcher behind JsonPatchOp (fa/tooling/json_patch.h): scans the members of an object without building a tree of
// the whole file, so only the bytes of the changed values move.
#include "fa/tooling/json_patch.h"

#include <filesystem>

#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

struct Member {
    std::string key;
    std::size_t keyStart = 0;    // offset of the opening quote of the key
    std::size_t valueStart = 0;  // first character of the value
    std::size_t valueEnd = 0;    // one past its last character
};

struct ObjectScan {
    std::size_t open = 0;   // offset of '{'
    std::size_t close = 0;  // offset of '}'
    std::vector<Member> members;
};

bool is_ws(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

std::size_t skip_ws(const std::string& t, std::size_t i) {
    while (i < t.size() && is_ws(t[i])) ++i;
    return i;
}

// One past the closing quote of the string starting at `i` (t[i] == '"'); npos when it never closes.
std::size_t skip_string(const std::string& t, std::size_t i) {
    for (++i; i < t.size(); ++i) {
        if (t[i] == '\\') ++i;
        else if (t[i] == '"') return i + 1;
    }
    return std::string::npos;
}

// One past the end of the JSON value starting at `i`; npos on malformed text.
std::size_t skip_value(const std::string& t, std::size_t i) {
    if (i >= t.size()) return std::string::npos;
    if (t[i] == '"') return skip_string(t, i);
    if (t[i] == '{' || t[i] == '[') {
        int depth = 0;
        for (; i < t.size(); ++i) {
            const char c = t[i];
            if (c == '"') {
                i = skip_string(t, i);
                if (i == std::string::npos) return i;
                --i;
            } else if (c == '{' || c == '[') {
                ++depth;
            } else if (c == '}' || c == ']') {
                if (--depth == 0) return i + 1;
            }
        }
        return std::string::npos;
    }
    while (i < t.size() && t[i] != ',' && t[i] != '}' && t[i] != ']' && !is_ws(t[i])) ++i;
    return i;
}

// The members of the object whose '{' is at `start`.
bool scan_object(const std::string& t, std::size_t start, ObjectScan& out) {
    if (start >= t.size() || t[start] != '{') return false;
    std::size_t i = start;
    out.open = i++;
    for (;;) {
        i = skip_ws(t, i);
        if (i >= t.size()) return false;
        if (t[i] == '}') {
            out.close = i;
            return true;
        }
        if (t[i] != '"') return false;
        Member m;
        m.keyStart = i;
        const std::size_t keyEnd = skip_string(t, i);
        if (keyEnd == std::string::npos) return false;
        auto key = parse_json(std::string_view(t).substr(i, keyEnd - i));
        m.key = key.ok() && key->is_string() ? key->get<std::string>() : t.substr(i + 1, keyEnd - i - 2);
        i = skip_ws(t, keyEnd);
        if (i >= t.size() || t[i] != ':') return false;
        i = skip_ws(t, i + 1);
        m.valueStart = i;
        m.valueEnd = skip_value(t, i);
        if (m.valueEnd == std::string::npos) return false;
        out.members.push_back(std::move(m));
        i = skip_ws(t, out.members.back().valueEnd);
        if (i < t.size() && t[i] == ',') ++i;
    }
}

// The root object (after a BOM and white space).
bool scan_root(const std::string& t, ObjectScan& out, std::size_t& start) {
    std::size_t i = skip_ws(t, 0);
    if (t.compare(i, 3, "\xEF\xBB\xBF") == 0) i = skip_ws(t, i + 3);
    start = i;
    return scan_object(t, i, out);
}

const Member* find_member(const ObjectScan& obj, const std::string& key) {
    for (auto it = obj.members.rbegin(); it != obj.members.rend(); ++it)
        if (it->key == key) return &*it;
    return nullptr;
}

// Layout facts of the file, so that new text looks like the old.
struct Style {
    std::string indent = "  ";  // one level (the leading whitespace of the first member of the root)
    std::string newline = "\n";
    bool inlineArrays = false;  // the file keeps arrays of scalars on one line: ["a", "b"]
};

bool has_inline_array(const std::string& t) {
    for (std::size_t i = 0; i < t.size(); ++i) {
        if (t[i] == '"') {
            i = skip_string(t, i);
            if (i == std::string::npos) return false;
            --i;
        } else if (t[i] == '[') {
            std::size_t j = i + 1;
            while (j < t.size() && (t[j] == ' ' || t[j] == '\t')) ++j;
            if (j < t.size() && t[j] != '\n' && t[j] != '\r' && t[j] != ']') return true;
        }
    }
    return false;
}

Style detect_style(const std::string& t, const ObjectScan& root) {
    Style s;
    if (t.find("\r\n") != std::string::npos) s.newline = "\r\n";
    s.inlineArrays = has_inline_array(t);
    if (!root.members.empty()) {
        const std::size_t k = root.members.front().keyStart;
        std::size_t b = k;
        while (b > 0 && (t[b - 1] == ' ' || t[b - 1] == '\t')) --b;
        if (b == 0 || t[b - 1] == '\n') {
            if (k > b) s.indent = t.substr(b, k - b);
        }
    }
    return s;
}

std::string repeat(const std::string& unit, std::size_t n) {
    std::string out;
    for (std::size_t i = 0; i < n; ++i) out += unit;
    return out;
}

// The text of `value` as a member of an object at nesting `depth` (0 = the root): the engine's layout (2-space levels,
// scalar arrays on one line when the file does that), in the file's own indent unit and line endings.
std::string render_value(const Json& value, const Style& style, std::size_t depth) {
    JsonFormat compact;
    std::string text = style.inlineArrays ? dump_json(value, compact) : dump_json(value);
    while (!text.empty() && text.back() == '\n') text.pop_back();
    std::string out;
    std::size_t lineStart = 0;
    bool first = true;
    while (lineStart <= text.size()) {
        std::size_t eol = text.find('\n', lineStart);
        if (eol == std::string::npos) eol = text.size();
        std::string line = text.substr(lineStart, eol - lineStart);
        if (!first) {
            std::size_t spaces = 0;
            while (spaces < line.size() && line[spaces] == ' ') ++spaces;
            out += style.newline + repeat(style.indent, depth + 1 + spaces / 2) + line.substr(spaces);
        } else {
            out += line;
        }
        first = false;
        lineStart = eol + 1;
    }
    return out;
}

std::string quoted(const std::string& key) { return Json(key).dump(-1, ' ', false, Json::error_handler_t::replace); }

// Replaces the value of `key` in `obj`, or appends the member after the last one.
std::string set_member(const std::string& t, const ObjectScan& obj, const Style& style, std::size_t depth, const std::string& key,
                       const std::string& valueText) {
    std::string out = t;
    if (const Member* m = find_member(obj, key)) {
        out.replace(m->valueStart, m->valueEnd - m->valueStart, valueText);
        return out;
    }
    const std::string member = quoted(key) + ": " + valueText;
    if (obj.members.empty()) {
        out.replace(obj.open + 1, obj.close - obj.open - 1,
                    style.newline + repeat(style.indent, depth + 1) + member + style.newline + repeat(style.indent, depth));
        return out;
    }
    const Member& last = obj.members.back();
    // The whitespace that separated the previous member from the last one is reused (newline + indent, or a space).
    std::size_t b = last.keyStart;
    while (b > 0 && is_ws(t[b - 1])) --b;
    std::string sep = t.substr(b, last.keyStart - b);
    if (const auto nl = sep.find('\n'); nl != std::string::npos) sep.erase(0, nl > 0 && sep[nl - 1] == '\r' ? nl - 1 : nl);  // not the old line's trailing blanks
    out.insert(last.valueEnd, "," + (sep.empty() ? std::string(" ") : sep) + member);
    return out;
}

std::string remove_member(const std::string& t, const ObjectScan& obj, const std::string& key) {
    const Member* m = find_member(obj, key);
    if (!m) return t;
    const std::size_t i = std::size_t(m - obj.members.data());
    const std::size_t n = obj.members.size();
    std::string out = t;
    if (n == 1) {
        const std::string between = t.substr(obj.open + 1, obj.close - obj.open - 1);
        out.replace(obj.open + 1, obj.close - obj.open - 1, between.find('\n') != std::string::npos ? "\n" : "");
    } else if (i + 1 < n) {
        out.erase(m->keyStart, obj.members[i + 1].keyStart - m->keyStart);
    } else {
        out.erase(obj.members[i - 1].valueEnd, m->valueEnd - obj.members[i - 1].valueEnd);
    }
    return out;
}

// `value` wrapped in objects for path[from..]: {"a": {"b": value}}.
Json nest(const std::vector<std::string>& path, std::size_t from, const Json& value) {
    Json out = value;
    for (std::size_t i = path.size(); i-- > from;) out = Json::object({{path[i], out}});
    return out;
}

struct Failure {
    std::string message, hint;
};

// Applies one op inside the object whose '{' is at `start` (nesting `depth`), for path[index..].
std::optional<Failure> apply_at(std::string& t, std::size_t start, std::size_t depth, const Style& style, const JsonPatchOp& op,
                                std::size_t index) {
    ObjectScan obj;
    if (!scan_object(t, start, obj)) return Failure{"cannot locate the keys to patch", "Fix the JSON syntax of the file."};
    const std::string& key = op.path[index];
    const bool last = index + 1 == op.path.size();
    const Member* m = find_member(obj, key);
    if (last) {
        if (!op.value) t = remove_member(t, obj, key);
        else t = set_member(t, obj, style, depth, key, render_value(*op.value, style, depth));
        return std::nullopt;
    }
    if (m && t[m->valueStart] == '{') return apply_at(t, m->valueStart, depth + 1, style, op, index + 1);
    if (m && op.value) {
        std::string at;
        for (std::size_t i = 0; i <= index; ++i) at += "/" + op.path[i];
        return Failure{at + " is not an object, so " + "/" + op.path.back() + " cannot be put inside it",
                       "Change that value to an object (or remove it) by hand first."};
    }
    if (!m && op.value) t = set_member(t, obj, style, depth, key, render_value(nest(op.path, index + 1, *op.value), style, depth));
    return std::nullopt;  // removing something that is not there
}

}  // namespace

Result<std::string> patch_json_text(const std::string& text, const std::vector<JsonPatchOp>& ops, const std::string& file) {
    auto parsed = parse_json(text, file);
    if (!parsed.ok()) return make_error(parsed.error().message, "Fix the JSON syntax of " + file + " first; nothing is patched over a broken file.");
    if (!parsed->is_object())
        return make_error(file + ": expected a JSON object, got " + describe_json_value(*parsed), "The file must start with { and end with }.");
    ObjectScan root;
    std::size_t rootStart = 0;
    if (!scan_root(text, root, rootStart))
        return make_error(file + ": cannot locate the top-level keys to patch.", "Fix the JSON syntax of " + file + ".");
    const Style style = detect_style(text, root);

    std::string out = text;
    for (const JsonPatchOp& op : ops) {
        if (op.path.empty()) return make_error("a JSON patch needs a key path", "This is an engine bug; report it.");
        std::size_t start = 0;
        ObjectScan current;
        if (!scan_root(out, current, start)) return make_error(file + ": internal error while patching the file", "Report this as an engine bug.");
        if (auto fail = apply_at(out, start, 0, style, op, 0)) return make_error(file + ": " + fail->message, fail->hint);
    }

    // Never produce a file that would not parse.
    auto check = parse_json(out, file);
    if (!check.ok() || !check->is_object())
        return make_error(file + ": internal error: the patched file would not be valid JSON; nothing was written.",
                          "Report this as an engine bug with the keys you changed.");
    return out;
}

Result<std::string> patch_json_file(const std::string& path, const std::vector<JsonPatchOp>& ops) {
    const auto text = tooling_detail::read_file(stdfs::path(path));
    if (!text) return make_error("Cannot read " + path + ".", "Check that the file exists and is readable.");
    auto patched = patch_json_text(*text, ops, path);
    if (!patched.ok()) return patched.error();
    if (*patched != *text) {
        std::string err;
        if (!tooling_detail::write_file(stdfs::path(path), *patched, &err))
            return make_error("Cannot write " + path + ": " + err, "Check that the folder is writable.");
    }
    return std::move(patched.value());
}

}  // namespace fa
