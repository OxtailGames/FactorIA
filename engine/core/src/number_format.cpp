#include "fa/core/number_format.h"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cctype>
#include <cstring>
#include <initializer_list>
#include <iterator>

namespace fa {

namespace {

struct NumberStyle {
    const char* decimal = ".";
    const char* group = ",";
    int minGrouping = 1;                // digits of the integer part from which groups start: 1 = "1,234", 2 = "12.345" only
    const char* digits = nullptr;       // ten UTF-8 digits (nullptr: ASCII)
};

constexpr const char* kNbsp = "\xC2\xA0";          // U+00A0
constexpr const char* kNarrowNbsp = "\xE2\x80\xAF";  // U+202F
constexpr const char* kArabicDigits = "\xD9\xA0|\xD9\xA1|\xD9\xA2|\xD9\xA3|\xD9\xA4|\xD9\xA5|\xD9\xA6|\xD9\xA7|\xD9\xA8|\xD9\xA9";
constexpr const char* kPersianDigits = "\xDB\xB0|\xDB\xB1|\xDB\xB2|\xDB\xB3|\xDB\xB4|\xDB\xB5|\xDB\xB6|\xDB\xB7|\xDB\xB8|\xDB\xB9";

constexpr const char* kLanguages[] = {"ar", "bg", "cs", "da", "de", "el", "en", "es", "fa", "fi", "fr", "he", "id", "it",
                                      "ja", "ko", "nb", "nl", "no", "pl", "pt", "ru", "sk", "sv", "tr", "uk", "zh"};

void split_tag(std::string_view tag, std::string& language, std::string& region) {
    language.clear();
    region.clear();
    std::size_t start = 0;
    bool first = true;
    while (start <= tag.size()) {
        std::size_t end = tag.find_first_of("-_", start);
        if (end == std::string_view::npos) end = tag.size();
        const std::string_view part = tag.substr(start, end - start);
        if (first) {
            for (char c : part) language += static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
            first = false;
        } else if (part.size() == 2 || (part.size() == 3 && std::isdigit(static_cast<unsigned char>(part[0])))) {
            for (char c : part) region += static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
        }
        start = end + 1;
    }
}

bool one_of(const std::string& s, std::initializer_list<const char*> list) {
    return std::any_of(list.begin(), list.end(), [&](const char* x) { return s == x; });
}

NumberStyle style_for(std::string_view tag) {
    std::string lang, region;
    split_tag(tag, lang, region);
    NumberStyle s;  // English
    if (lang == "es") {
        // Spain writes 1234,5 and 12.345,5; Latin America (except a few countries) and the US write like English.
        if (one_of(region, {"MX", "US", "PR", "GT", "HN", "NI", "SV", "PA", "DO", "PE", "419"})) return s;
        s.decimal = ",";
        s.group = ".";
        s.minGrouping = 2;
    } else if (lang == "pt") {
        s.decimal = ",";
        if (region == "PT") {
            s.group = kNbsp;
            s.minGrouping = 2;
        } else {
            s.group = ".";
        }
    } else if (lang == "de") {
        if (region == "CH" || region == "LI") {
            s.decimal = ".";
            s.group = "\xE2\x80\x99";  // U+2019
        } else {
            s.decimal = ",";
            s.group = ".";
        }
    } else if (lang == "fr") {
        s.decimal = ",";
        s.group = kNarrowNbsp;
    } else if (lang == "it") {
        s.decimal = ",";
        s.group = ".";
        s.minGrouping = 2;
        if (region == "CH") {
            s.decimal = ".";
            s.group = "\xE2\x80\x99";
            s.minGrouping = 1;
        }
    } else if (one_of(lang, {"nl", "tr", "id", "da", "el"})) {
        s.decimal = ",";
        s.group = ".";
    } else if (one_of(lang, {"ru", "uk", "cs", "sk", "bg", "sv", "nb", "no", "fi", "pl"})) {
        s.decimal = ",";
        s.group = kNbsp;
        if (lang == "pl" || lang == "bg") s.minGrouping = 2;
    } else if (lang == "ar") {
        s.decimal = "\xD9\xAB";  // U+066B
        s.group = "\xD9\xAC";    // U+066C
        s.digits = kArabicDigits;
    } else if (lang == "fa") {
        s.decimal = "\xD9\xAB";
        s.group = "\xD9\xAC";
        s.digits = kPersianDigits;
    }
    return s;  // en, ja, zh, ko, he and every language the table does not know: "1,234.5"
}

void append_digit(std::string& out, const NumberStyle& s, char digit) {
    if (!s.digits) {
        out += digit;
        return;
    }
    const char* p = s.digits;
    for (int i = 0; i < digit - '0'; ++i) p = std::strchr(p, '|') + 1;
    const char* end = std::strchr(p, '|');
    out.append(p, end ? static_cast<std::size_t>(end - p) : std::strlen(p));
}

// "-1234.50" (ASCII) -> the text of `style`.
std::string localize_ascii(const std::string& ascii, const NumberStyle& s) {
    std::string out;
    std::size_t i = 0;
    if (i < ascii.size() && ascii[i] == '-') out += ascii[i++];
    const std::size_t dot = ascii.find('.', i);
    const std::size_t intEnd = dot == std::string::npos ? ascii.size() : dot;
    const std::size_t count = intEnd - i;
    const bool grouped = count >= static_cast<std::size_t>(3 + s.minGrouping);
    for (std::size_t k = 0; k < count; ++k) {
        if (grouped && k > 0 && (count - k) % 3 == 0) out += s.group;
        append_digit(out, s, ascii[i + k]);
    }
    if (dot != std::string::npos) {
        out += s.decimal;
        for (std::size_t k = dot + 1; k < ascii.size(); ++k) append_digit(out, s, ascii[k]);
    }
    return out;
}

// Fixed notation, `decimals` digits (negative: the shortest text that reads back as the same value, at most 9 decimals).
std::string ascii_number(double value, int decimals) {
    char buf[400];
    std::to_chars_result r;
    if (decimals < 0) {
        r = std::to_chars(buf, buf + sizeof(buf), value, std::chars_format::fixed);
        std::string s(buf, r.ptr);
        const std::size_t dot = s.find('.');
        if (dot != std::string::npos && s.size() - dot - 1 > 9) {  // 0.1 + 0.2: 17 digits of noise
            r = std::to_chars(buf, buf + sizeof(buf), value, std::chars_format::fixed, 9);
            s.assign(buf, r.ptr);
            while (!s.empty() && s.back() == '0') s.pop_back();
            if (!s.empty() && s.back() == '.') s.pop_back();
        }
        return s;
    }
    decimals = std::min(decimals, 9);
    // A tie rounds away from zero, like JavaScript's toFixed (0.25 -> "0.3"), not to even like printf.
    double scale = 1;
    for (int i = 0; i < decimals; ++i) scale *= 10;
    if (std::fabs(value) * scale < 1e15) value = std::round(value * scale) / scale;
    r = std::to_chars(buf, buf + sizeof(buf), value, std::chars_format::fixed, decimals);
    return std::string(buf, r.ptr);
}

void strip_negative_zero(std::string& s) {
    if (s.empty() || s[0] != '-') return;
    if (std::all_of(s.begin() + 1, s.end(), [](char c) { return c == '0' || c == '.'; })) s.erase(0, 1);
}

}  // namespace

std::string format_number(double value, int decimals, std::string_view language) {
    if (std::isnan(value)) return "nan";
    if (std::isinf(value)) return value < 0 ? "-inf" : "inf";
    std::string ascii = ascii_number(value, decimals);
    strip_negative_zero(ascii);
    return localize_ascii(ascii, style_for(language));
}

std::string format_duration(double seconds, int decimals, std::string_view language) {
    if (std::isnan(seconds) || std::isinf(seconds)) return format_number(seconds, 0, language);
    decimals = std::clamp(decimals, 0, 3);
    const NumberStyle s = style_for(language);
    double scale = 1;
    for (int i = 0; i < decimals; ++i) scale *= 10;
    const bool negative = seconds < 0;
    // Whole units of the last decimal, so a carry (59.96 -> 60.0) moves into the minutes.
    const double units = std::round(std::fabs(seconds) * scale);
    if (units >= 9e15) return format_number(seconds, decimals, language);
    const long long total = static_cast<long long>(units);
    const long long perSecond = static_cast<long long>(scale);
    const long long whole = total / perSecond;
    const long long frac = total % perSecond;
    const long long h = whole / 3600, m = (whole / 60) % 60, sec = whole % 60;
    const auto two = [](long long v) { return std::string(v < 10 ? "0" : "") + std::to_string(v); };
    std::string ascii = h > 0 ? std::to_string(h) + ":" + two(m) + ":" + two(sec) : std::to_string(m) + ":" + two(sec);
    if (decimals > 0) {
        std::string f = std::to_string(frac);
        ascii += "." + std::string(static_cast<std::size_t>(decimals) - f.size(), '0') + f;
    }
    // Digits and the decimal separator of the language; ':' stays. No grouping: minutes never reach 1000 here.
    std::string out = negative && total > 0 ? "-" : "";
    for (char c : ascii) {
        if (c >= '0' && c <= '9') append_digit(out, s, c);
        else if (c == '.') out += s.decimal;
        else out += c;
    }
    return out;
}

const char* const* number_format_languages(std::size_t* count) {
    if (count) *count = std::size(kLanguages);
    return kLanguages;
}

}  // namespace fa
