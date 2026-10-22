#include "plist_read.h"

#include <cctype>
#include <cstdlib>

namespace fa::tooling_detail {

namespace {

struct Cursor {
    std::string_view s;
    std::size_t i = 0;
    std::string problem;

    void skip_space() {
        while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
    }
    // Skips whitespace, comments, <?...?> and <!...> declarations.
    void skip_misc() {
        for (;;) {
            skip_space();
            if (s.compare(i, 4, "<!--") == 0) {
                const std::size_t e = s.find("-->", i);
                i = e == std::string_view::npos ? s.size() : e + 3;
            } else if (s.compare(i, 2, "<?") == 0) {
                const std::size_t e = s.find("?>", i);
                i = e == std::string_view::npos ? s.size() : e + 2;
            } else if (s.compare(i, 2, "<!") == 0) {
                const std::size_t e = s.find('>', i);
                i = e == std::string_view::npos ? s.size() : e + 1;
            } else {
                return;
            }
        }
    }
    // "<name>" or "<name/>" at i: its name and whether it is self-closing; i moves past it.
    bool open_tag(std::string& name, bool& selfClosing) {
        skip_misc();
        if (i >= s.size() || s[i] != '<' || s.compare(i, 2, "</") == 0) return false;
        const std::size_t e = s.find('>', i);
        if (e == std::string_view::npos) return false;
        std::string inner(s.substr(i + 1, e - i - 1));
        selfClosing = !inner.empty() && inner.back() == '/';
        if (selfClosing) inner.pop_back();
        const std::size_t sp = inner.find_first_of(" \t\r\n");
        name = sp == std::string::npos ? inner : inner.substr(0, sp);
        i = e + 1;
        return true;
    }
};

std::string decode(std::string_view t) {
    std::string out;
    for (std::size_t i = 0; i < t.size(); ++i) {
        if (t[i] == '&') {
            const std::size_t e = t.find(';', i);
            if (e != std::string_view::npos) {
                const std::string_view ent = t.substr(i + 1, e - i - 1);
                const char* rep = ent == "amp" ? "&" : ent == "lt" ? "<" : ent == "gt" ? ">" : ent == "quot" ? "\"" : ent == "apos" ? "'" : nullptr;
                if (rep) {
                    out += rep;
                    i = e;
                    continue;
                }
            }
        }
        out += t[i];
    }
    return out;
}

// The text up to </name>.
bool read_text(Cursor& c, const std::string& name, std::string& text) {
    const std::string close = "</" + name + ">";
    const std::size_t e = c.s.find(close, c.i);
    if (e == std::string_view::npos) {
        c.problem = "<" + name + "> is never closed";
        return false;
    }
    text = decode(c.s.substr(c.i, e - c.i));
    c.i = e + close.size();
    return true;
}

bool expect_close(Cursor& c, const char* name) {
    c.skip_misc();
    const std::string close = std::string("</") + name + ">";
    if (c.s.compare(c.i, close.size(), close) != 0) {
        c.problem = "expected " + close;
        return false;
    }
    c.i += close.size();
    return true;
}

bool parse_value(Cursor& c, const std::string& name, bool selfClosing, Json& out, int depth) {
    if (depth > 32) {
        c.problem = "nested too deep";
        return false;
    }
    if (name == "true" || name == "false") {
        out = name == "true";
        if (!selfClosing) {
            std::string ignored;
            if (!read_text(c, name, ignored)) return false;
        }
        return true;
    }
    if (name == "dict") {
        out = Json::object();
        if (selfClosing) return true;
        for (;;) {
            c.skip_misc();
            if (c.s.compare(c.i, 7, "</dict>") == 0) {
                c.i += 7;
                return true;
            }
            std::string kn;
            bool sc = false;
            if (!c.open_tag(kn, sc) || kn != "key" || sc) {
                c.problem = "expected <key> inside <dict>";
                return false;
            }
            std::string key;
            if (!read_text(c, "key", key)) return false;
            std::string vn;
            if (!c.open_tag(vn, sc)) {
                c.problem = "the key '" + key + "' has no value";
                return false;
            }
            Json v;
            if (!parse_value(c, vn, sc, v, depth + 1)) return false;
            out[key] = std::move(v);
        }
    }
    if (name == "array") {
        out = Json::array();
        if (selfClosing) return true;
        for (;;) {
            c.skip_misc();
            if (c.s.compare(c.i, 8, "</array>") == 0) {
                c.i += 8;
                return true;
            }
            std::string vn;
            bool sc = false;
            if (!c.open_tag(vn, sc)) {
                c.problem = "expected a value or </array>";
                return false;
            }
            Json v;
            if (!parse_value(c, vn, sc, v, depth + 1)) return false;
            out.push_back(std::move(v));
        }
    }
    std::string text;
    if (!selfClosing && !read_text(c, name, text)) return false;
    if (name == "integer") out = std::strtoll(text.c_str(), nullptr, 10);
    else if (name == "real") out = std::strtod(text.c_str(), nullptr);
    else out = text;  // string, date, data
    return true;
}

}  // namespace

Result<Json> parse_xml_plist(std::string_view text) {
    const std::size_t start = text.find("<plist");
    if (start == std::string_view::npos)
        return Error{"no <plist> found", "Pass an XML property list (a binary plist: convert it with `plutil -convert xml1 -o - <file>`)."};
    Cursor c{text, start, {}};
    std::string name;
    bool sc = false;
    if (!c.open_tag(name, sc) || name != "plist" || sc) return Error{"bad <plist> tag", "The file is not a property list."};
    if (!c.open_tag(name, sc)) return Error{"the <plist> is empty", "A property list holds a <dict> or an <array>."};
    Json root;
    const char* hint = "The file is damaged or not an XML property list.";
    if (!parse_value(c, name, sc, root, 0)) return Error{"cannot read the property list: " + c.problem, hint};
    if (!expect_close(c, "plist")) return Error{"cannot read the property list: " + c.problem, hint};
    return root;
}

}  // namespace fa::tooling_detail
