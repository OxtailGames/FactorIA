// A reader for exactly the YAML sokol-shdc writes with --format bare_yaml (its reflection file): block mappings (`key: value`,
// `key:` + a deeper block) and block sequences (a `-` on its own line, or `- key: value`), scalars on one line. There is no
// YAML library in the engine and none is needed for anything else.
#include <charconv>
#include <string>
#include <vector>

#include "fa/tooling/shaders.h"

namespace fa {

namespace {

struct Line {
    int indent = 0;
    std::string text;  // without the indentation
    int number = 0;    // 1-based line of the file
};

Json scalar(std::string_view s) {
    if (s.size() >= 2 && ((s.front() == '"' && s.back() == '"') || (s.front() == '\'' && s.back() == '\''))) {
        std::string out;
        for (std::size_t i = 1; i + 1 < s.size(); ++i) {
            if (s[0] == '"' && s[i] == '\\' && i + 2 < s.size()) {
                ++i;
                out += s[i] == 'n' ? '\n' : s[i] == 't' ? '\t' : s[i];
            } else
                out += s[i];
        }
        return out;
    }
    if (s == "true") return true;
    if (s == "false") return false;
    if (s == "null" || s == "~") return nullptr;
    long long iv = 0;
    auto r = std::from_chars(s.data(), s.data() + s.size(), iv);
    if (r.ec == std::errc() && r.ptr == s.data() + s.size()) return iv;
    if (!s.empty() && (std::isdigit(static_cast<unsigned char>(s[0])) || ((s[0] == '-' || s[0] == '.') && s.size() > 1))) {
        char* end = nullptr;
        const std::string tmp(s);
        double d = std::strtod(tmp.c_str(), &end);
        if (end == tmp.c_str() + tmp.size()) return d;
    }
    return std::string(s);
}

struct Parser {
    std::vector<Line> lines;
    std::size_t pos = 0;
    std::string error;

    bool fail(const Line& l, const std::string& why) {
        if (error.empty()) error = "line " + std::to_string(l.number) + ": " + why + " (\"" + l.text + "\")";
        return false;
    }

    // A block of lines that all start at `indent`.
    bool block(int indent, Json& out) {
        if (pos >= lines.size()) { out = Json::array(); return true; }
        const Line& first = lines[pos];
        if (first.text == "-") return sequence(indent, out);
        return mapping(indent, out);
    }

    bool sequence(int indent, Json& out) {
        out = Json::array();
        while (pos < lines.size() && lines[pos].indent == indent && lines[pos].text == "-") {
            ++pos;
            if (pos < lines.size() && lines[pos].indent > indent) {
                Json item;
                if (!block(lines[pos].indent, item)) return false;
                out.push_back(std::move(item));
            } else {
                out.push_back(nullptr);
            }
        }
        if (pos < lines.size() && lines[pos].indent > indent) return fail(lines[pos], "unexpected indentation");
        return true;
    }

    bool mapping(int indent, Json& out) {
        out = Json::object();
        while (pos < lines.size() && lines[pos].indent == indent && lines[pos].text != "-") {
            const Line& l = lines[pos];
            std::size_t colon = l.text.find(": ");
            std::string key, value;
            if (colon != std::string::npos) {
                key = l.text.substr(0, colon);
                value = l.text.substr(colon + 2);
                while (!value.empty() && value.front() == ' ') value.erase(value.begin());
            } else if (!l.text.empty() && l.text.back() == ':') {
                key = l.text.substr(0, l.text.size() - 1);
            } else {
                return fail(l, "expected `key: value` or `key:`");
            }
            if (key.size() >= 2 && key.front() == '"' && key.back() == '"') key = key.substr(1, key.size() - 2);
            ++pos;
            if (!value.empty()) {
                out[key] = scalar(value);
            } else if (pos < lines.size() && (lines[pos].indent > indent || (lines[pos].indent == indent && lines[pos].text == "-"))) {
                Json child;
                if (!block(lines[pos].indent, child)) return false;
                out[key] = std::move(child);
            } else {
                out[key] = Json::array();
            }
        }
        if (pos < lines.size() && lines[pos].indent > indent) return fail(lines[pos], "unexpected indentation");
        return true;
    }
};

}  // namespace

Result<Json> parse_shdc_yaml(std::string_view text) {
    Parser p;
    int number = 0;
    std::size_t start = 0;
    while (start <= text.size()) {
        std::size_t nl = text.find('\n', start);
        std::string raw(text.substr(start, nl == std::string_view::npos ? std::string_view::npos : nl - start));
        start = nl == std::string_view::npos ? text.size() + 1 : nl + 1;
        ++number;
        while (!raw.empty() && (raw.back() == '\r' || raw.back() == ' ')) raw.pop_back();
        if (raw.empty() || raw[0] == '#') continue;
        int indent = 0;
        while (indent < int(raw.size()) && raw[indent] == ' ') ++indent;
        std::string content = raw.substr(indent);
        if (content == "---") continue;
        // "- key: value" is a `-` followed by a mapping line two columns in.
        if (content.size() > 2 && content[0] == '-' && content[1] == ' ') {
            p.lines.push_back({indent, "-", number});
            std::string rest = content.substr(2);
            int extra = 2;
            while (!rest.empty() && rest.front() == ' ') { rest.erase(rest.begin()); ++extra; }
            p.lines.push_back({indent + extra, rest, number});
        } else {
            p.lines.push_back({indent, content, number});
        }
    }
    if (p.lines.empty()) return make_error("sokol-shdc wrote an empty reflection file", "Run sokol-shdc by hand on the generated top file to see what it prints.");
    Json root;
    if (!p.block(p.lines.front().indent, root) || !p.error.empty() || p.pos < p.lines.size()) {
        if (p.error.empty() && p.pos < p.lines.size()) p.error = "line " + std::to_string(p.lines[p.pos].number) + ": unexpected content";
        return make_error("cannot read the reflection YAML of sokol-shdc: " + p.error,
                          "The reader understands the YAML of the pinned sokol-shdc (fa/tooling/setup.h, kSetupSokolShdcCommit); another version may write something else. "
                          "Use `factoria setup shaders` to install the pinned one.");
    }
    return root;
}

}  // namespace fa
