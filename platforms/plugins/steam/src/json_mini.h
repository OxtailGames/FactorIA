// A small JSON value, parser and writer: the plugin reads the arguments of a request (JSON text) and answers with JSON
// text, and has no dependency to get them from. Numbers are doubles (ids are strings; scores fit in 32 bits).
#pragma once

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <type_traits>
#include <utility>
#include <vector>

namespace steam_plugin {

class Json {
public:
    enum class Type { Null, Bool, Number, String, Array, Object };

    Json() = default;
    Json(std::nullptr_t) {}
    Json(bool b) : type_(Type::Bool), bool_(b) {}
    template <class T, class = typename std::enable_if<std::is_integral<T>::value && !std::is_same<T, bool>::value>::type>
    Json(T n) : type_(Type::Number), number_(static_cast<double>(n)) {}
    Json(double n) : type_(Type::Number), number_(n) {}
    Json(const char* s) : type_(Type::String), string_(s ? s : "") {}
    Json(std::string s) : type_(Type::String), string_(std::move(s)) {}

    static Json array() {
        Json j;
        j.type_ = Type::Array;
        return j;
    }
    static Json object() {
        Json j;
        j.type_ = Type::Object;
        return j;
    }

    Type type() const { return type_; }
    bool is_null() const { return type_ == Type::Null; }
    bool is_string() const { return type_ == Type::String; }
    bool is_number() const { return type_ == Type::Number; }
    bool is_object() const { return type_ == Type::Object; }
    bool is_array() const { return type_ == Type::Array; }

    const std::string& str() const { return string_; }
    double num() const { return number_; }
    bool boolean() const { return bool_; }
    const std::vector<Json>& items() const { return items_; }

    // Object member, or null when this is not an object or has no such key.
    const Json* find(const std::string& key) const {
        for (const auto& m : members_)
            if (m.first == key) return &m.second;
        return nullptr;
    }
    std::string string_or(const std::string& key, const std::string& fallback = std::string()) const {
        const Json* v = find(key);
        return v && v->is_string() ? v->string_ : fallback;
    }
    double number_or(const std::string& key, double fallback) const {
        const Json* v = find(key);
        return v && v->is_number() ? v->number_ : fallback;
    }

    Json& set(const std::string& key, Json value) {
        type_ = Type::Object;
        for (auto& m : members_)
            if (m.first == key) {
                m.second = std::move(value);
                return *this;
            }
        members_.emplace_back(key, std::move(value));
        return *this;
    }
    Json& push(Json value) {
        type_ = Type::Array;
        items_.push_back(std::move(value));
        return *this;
    }
    const std::vector<std::pair<std::string, Json>>& members() const { return members_; }

    std::string dump() const {
        std::string out;
        write(out);
        return out;
    }

    // Parses `text`; false with a message that names the position when it is not JSON.
    static bool parse(const std::string& text, Json& out, std::string& error) {
        Parser p{text, 0, 0, error};
        p.skip();
        if (!p.value(out)) return false;
        p.skip();
        if (p.pos != text.size()) return p.fail("unexpected text after the value");
        return true;
    }

private:
    Type type_ = Type::Null;
    bool bool_ = false;
    double number_ = 0;
    std::string string_;
    std::vector<Json> items_;
    std::vector<std::pair<std::string, Json>> members_;

    // Appends `s` as a JSON string. Bytes that are not valid UTF-8 become U+FFFD: Steam hands over names the engine's JSON
    // parser would refuse.
    static void write_string(std::string& out, const std::string& s) {
        out += '"';
        for (std::size_t i = 0; i < s.size();) {
            const unsigned char c = static_cast<unsigned char>(s[i]);
            if (c == '"' || c == '\\') {
                out += '\\';
                out += static_cast<char>(c);
                ++i;
            } else if (c < 0x20) {
                char buf[8];
                std::snprintf(buf, sizeof buf, "\\u%04x", c);
                out += buf;
                ++i;
            } else if (c < 0x80) {
                out += static_cast<char>(c);
                ++i;
            } else {
                const std::size_t n = utf8_length(s, i);
                if (n == 0) {
                    out += "\xEF\xBF\xBD";
                    ++i;
                } else {
                    out.append(s, i, n);
                    i += n;
                }
            }
        }
        out += '"';
    }

    // The length of the valid UTF-8 sequence that starts at s[i], or 0.
    static std::size_t utf8_length(const std::string& s, std::size_t i) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        std::size_t n = c >= 0xC2 && c <= 0xDF ? 2 : (c >= 0xE0 && c <= 0xEF ? 3 : (c >= 0xF0 && c <= 0xF4 ? 4 : 0));
        if (n == 0 || i + n > s.size()) return 0;
        for (std::size_t k = 1; k < n; ++k)
            if ((static_cast<unsigned char>(s[i + k]) & 0xC0) != 0x80) return 0;
        const unsigned char c1 = static_cast<unsigned char>(s[i + 1]);
        if ((c == 0xE0 && c1 < 0xA0) || (c == 0xED && c1 > 0x9F) || (c == 0xF0 && c1 < 0x90) || (c == 0xF4 && c1 > 0x8F)) return 0;
        return n;
    }

    void write(std::string& out) const {
        switch (type_) {
            case Type::Null: out += "null"; break;
            case Type::Bool: out += bool_ ? "true" : "false"; break;
            case Type::Number: {
                char buf[40];
                if (!std::isfinite(number_)) std::snprintf(buf, sizeof buf, "null");
                else if (number_ == std::floor(number_) && std::fabs(number_) < 9e15) std::snprintf(buf, sizeof buf, "%.0f", number_);
                else std::snprintf(buf, sizeof buf, "%.9g", number_);
                out += buf;
                break;
            }
            case Type::String: write_string(out, string_); break;
            case Type::Array:
                out += '[';
                for (std::size_t i = 0; i < items_.size(); ++i) {
                    if (i) out += ',';
                    items_[i].write(out);
                }
                out += ']';
                break;
            case Type::Object:
                out += '{';
                for (std::size_t i = 0; i < members_.size(); ++i) {
                    if (i) out += ',';
                    write_string(out, members_[i].first);
                    out += ':';
                    members_[i].second.write(out);
                }
                out += '}';
                break;
        }
    }

    struct Parser {
        const std::string& s;
        std::size_t pos;
        int depth;
        std::string& error;

        bool fail(const std::string& why) {
            error = why + " (at character " + std::to_string(pos) + ")";
            return false;
        }
        void skip() {
            while (pos < s.size() && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == '\n' || s[pos] == '\r')) ++pos;
        }
        bool literal(const char* word, Json value, Json& out) {
            const std::size_t n = std::char_traits<char>::length(word);
            if (s.compare(pos, n, word) != 0) return fail("expected a JSON value");
            pos += n;
            out = std::move(value);
            return true;
        }
        bool value(Json& out) {
            if (pos >= s.size()) return fail("unexpected end of the text");
            if (++depth > 64) return fail("nested too deeply");
            const bool ok = value_inner(out);
            --depth;
            return ok;
        }
        bool value_inner(Json& out) {
            switch (s[pos]) {
                case '{': return object(out);
                case '[': return array(out);
                case '"': {
                    std::string str;
                    if (!string(str)) return false;
                    out = Json(std::move(str));
                    return true;
                }
                case 't': return literal("true", Json(true), out);
                case 'f': return literal("false", Json(false), out);
                case 'n': return literal("null", Json(), out);
                default: return number(out);
            }
        }
        bool number(Json& out) {
            const char* begin = s.c_str() + pos;
            char* end = nullptr;
            const double d = std::strtod(begin, &end);
            if (end == begin) return fail("expected a JSON value");
            pos += static_cast<std::size_t>(end - begin);
            out = Json(d);
            return true;
        }
        bool hex4(unsigned& code) {
            if (pos + 4 > s.size()) return fail("a \\u escape needs four hex digits");
            code = 0;
            for (int i = 0; i < 4; ++i) {
                const char c = s[pos++];
                code <<= 4;
                if (c >= '0' && c <= '9') code |= static_cast<unsigned>(c - '0');
                else if (c >= 'a' && c <= 'f') code |= static_cast<unsigned>(c - 'a' + 10);
                else if (c >= 'A' && c <= 'F') code |= static_cast<unsigned>(c - 'A' + 10);
                else return fail("a \\u escape needs four hex digits");
            }
            return true;
        }
        static void utf8(std::string& out, unsigned cp) {
            if (cp < 0x80) {
                out += static_cast<char>(cp);
            } else if (cp < 0x800) {
                out += static_cast<char>(0xC0 | (cp >> 6));
                out += static_cast<char>(0x80 | (cp & 0x3F));
            } else if (cp < 0x10000) {
                out += static_cast<char>(0xE0 | (cp >> 12));
                out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
                out += static_cast<char>(0x80 | (cp & 0x3F));
            } else {
                out += static_cast<char>(0xF0 | (cp >> 18));
                out += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
                out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
                out += static_cast<char>(0x80 | (cp & 0x3F));
            }
        }
        bool string(std::string& out) {
            ++pos;  // the opening quote
            while (pos < s.size()) {
                const char c = s[pos++];
                if (c == '"') return true;
                if (c != '\\') {
                    out += c;
                    continue;
                }
                if (pos >= s.size()) break;
                const char e = s[pos++];
                switch (e) {
                    case '"': out += '"'; break;
                    case '\\': out += '\\'; break;
                    case '/': out += '/'; break;
                    case 'b': out += '\b'; break;
                    case 'f': out += '\f'; break;
                    case 'n': out += '\n'; break;
                    case 'r': out += '\r'; break;
                    case 't': out += '\t'; break;
                    case 'u': {
                        unsigned cp = 0;
                        if (!hex4(cp)) return false;
                        if (cp >= 0xD800 && cp < 0xDC00 && s.compare(pos, 2, "\\u") == 0) {  // a surrogate pair
                            pos += 2;
                            unsigned low = 0;
                            if (!hex4(low)) return false;
                            cp = 0x10000 + ((cp - 0xD800) << 10) + (low - 0xDC00);
                        }
                        utf8(out, cp);
                        break;
                    }
                    default: return fail("unknown escape in a string");
                }
            }
            return fail("a string is not closed");
        }
        bool array(Json& out) {
            ++pos;
            out = Json::array();
            skip();
            if (pos < s.size() && s[pos] == ']') return ++pos, true;
            for (;;) {
                skip();
                Json item;
                if (!value(item)) return false;
                out.push(std::move(item));
                skip();
                if (pos < s.size() && s[pos] == ',') {
                    ++pos;
                    continue;
                }
                if (pos < s.size() && s[pos] == ']') return ++pos, true;
                return fail("expected ',' or ']' in an array");
            }
        }
        bool object(Json& out) {
            ++pos;
            out = Json::object();
            skip();
            if (pos < s.size() && s[pos] == '}') return ++pos, true;
            for (;;) {
                skip();
                if (pos >= s.size() || s[pos] != '"') return fail("expected a string key in an object");
                std::string key;
                if (!string(key)) return false;
                skip();
                if (pos >= s.size() || s[pos] != ':') return fail("expected ':' after a key");
                ++pos;
                skip();
                Json v;
                if (!value(v)) return false;
                out.set(key, std::move(v));
                skip();
                if (pos < s.size() && s[pos] == ',') {
                    ++pos;
                    continue;
                }
                if (pos < s.size() && s[pos] == '}') return ++pos, true;
                return fail("expected ',' or '}' in an object");
            }
        }
    };
};

}  // namespace steam_plugin
