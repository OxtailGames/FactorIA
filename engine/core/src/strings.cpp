#include "fa/core/strings.h"

#include <algorithm>
#include <cctype>

namespace fa {

static char lower_char(char c) { return char(std::tolower(static_cast<unsigned char>(c))); }

std::string to_lower(std::string_view s) {
    std::string r(s);
    for (char& c : r) c = lower_char(c);
    return r;
}

bool iequals(std::string_view a, std::string_view b) {
    if (a.size() != b.size()) return false;
    for (std::size_t i = 0; i < a.size(); ++i)
        if (lower_char(a[i]) != lower_char(b[i])) return false;
    return true;
}

bool starts_with(std::string_view s, std::string_view prefix) {
    return s.size() >= prefix.size() && s.substr(0, prefix.size()) == prefix;
}

bool ends_with(std::string_view s, std::string_view suffix) {
    return s.size() >= suffix.size() && s.substr(s.size() - suffix.size()) == suffix;
}

std::string_view trim(std::string_view s) {
    auto isSpace = [](char c) { return std::isspace(static_cast<unsigned char>(c)) != 0; };
    while (!s.empty() && isSpace(s.front())) s.remove_prefix(1);
    while (!s.empty() && isSpace(s.back())) s.remove_suffix(1);
    return s;
}

std::vector<std::string> split(std::string_view s, char sep, bool skipEmpty) {
    std::vector<std::string> out;
    std::size_t start = 0;
    while (start <= s.size()) {
        std::size_t end = s.find(sep, start);
        if (end == std::string_view::npos) end = s.size();
        if (!skipEmpty || end > start) out.emplace_back(s.substr(start, end - start));
        start = end + 1;
    }
    return out;
}

std::string join(std::span<const std::string> parts, std::string_view sep) {
    std::string r;
    for (std::size_t i = 0; i < parts.size(); ++i) {
        if (i) r += sep;
        r += parts[i];
    }
    return r;
}

std::string replace_all(std::string s, std::string_view from, std::string_view to) {
    if (from.empty()) return s;
    std::size_t pos = 0;
    while ((pos = s.find(from, pos)) != std::string::npos) {
        s.replace(pos, from.size(), to);
        pos += to.size();
    }
    return s;
}

std::size_t edit_distance(std::string_view a, std::string_view b) {
    std::vector<std::size_t> prev(b.size() + 1), cur(b.size() + 1);
    for (std::size_t j = 0; j <= b.size(); ++j) prev[j] = j;
    for (std::size_t i = 1; i <= a.size(); ++i) {
        cur[0] = i;
        for (std::size_t j = 1; j <= b.size(); ++j) {
            std::size_t cost = lower_char(a[i - 1]) == lower_char(b[j - 1]) ? 0 : 1;
            cur[j] = std::min({prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost});
        }
        std::swap(prev, cur);
    }
    return prev[b.size()];
}

std::string closest_match(std::string_view input, std::span<const std::string> candidates) {
    std::size_t limit = std::max<std::size_t>(2, input.size() / 3);
    std::size_t best = limit + 1;
    std::string result;
    for (const std::string& c : candidates) {
        std::size_t d = edit_distance(input, c);
        if (d < best) {
            best = d;
            result = c;
        }
    }
    return result;
}

std::string did_you_mean(std::string_view input, std::span<const std::string> candidates, std::size_t listMax) {
    std::string out;
    std::string best = closest_match(input, candidates);
    if (!best.empty()) out += "Did you mean '" + best + "'? ";
    if (!candidates.empty()) {
        out += "Valid: ";
        std::size_t n = std::min(candidates.size(), listMax);
        for (std::size_t i = 0; i < n; ++i) {
            if (i) out += ", ";
            out += candidates[i];
        }
        if (candidates.size() > n) out += ", ... (" + std::to_string(candidates.size() - n) + " more)";
        out += ".";
    }
    while (!out.empty() && out.back() == ' ') out.pop_back();
    return out;
}

static const char kB64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

std::string base64_encode(const void* data, std::size_t size) {
    const auto* p = static_cast<const unsigned char*>(data);
    std::string out;
    out.reserve((size + 2) / 3 * 4);
    for (std::size_t i = 0; i < size; i += 3) {
        unsigned v = unsigned(p[i]) << 16;
        if (i + 1 < size) v |= unsigned(p[i + 1]) << 8;
        if (i + 2 < size) v |= p[i + 2];
        out += kB64[(v >> 18) & 63];
        out += kB64[(v >> 12) & 63];
        out += i + 1 < size ? kB64[(v >> 6) & 63] : '=';
        out += i + 2 < size ? kB64[v & 63] : '=';
    }
    return out;
}

std::vector<unsigned char> base64_decode(std::string_view text) {
    std::vector<unsigned char> out;
    unsigned acc = 0;
    int bits = 0;
    for (char c : text) {
        int v;
        if (c >= 'A' && c <= 'Z') v = c - 'A';
        else if (c >= 'a' && c <= 'z') v = c - 'a' + 26;
        else if (c >= '0' && c <= '9') v = c - '0' + 52;
        else if (c == '+' || c == '-') v = 62;
        else if (c == '/' || c == '_') v = 63;
        else continue;  // '=' padding and whitespace
        acc = (acc << 6) | unsigned(v);
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            out.push_back(static_cast<unsigned char>((acc >> bits) & 0xff));
        }
    }
    return out;
}

}  // namespace fa
