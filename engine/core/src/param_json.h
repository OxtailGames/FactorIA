// Private to fa_core: the small helpers noise.cpp and erosion.cpp share to read a parameter struct from a JSON object with
// teaching errors (JSON pointer, what is wrong, how to fix it, "did you mean" for a misspelled key or word).
#pragma once

#include <cmath>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/core/types.h"

namespace fa::detail {

inline std::string pj_at(std::string_view pointer, std::string_view key) {
    return std::string(pointer) + "/" + std::string(key);
}

// The text of a number for an error message (an integer as an integer, a float with up to 6 digits).
inline std::string pj_num(double v) {
    if (std::isfinite(v) && std::fabs(v) < 1e15 && v == std::floor(v)) return std::format("{}", std::int64_t(v));
    return std::format("{:.6g}", v);
}

// `value` must be an object whose keys are all in `known`.
inline Result<void> pj_check_object(const Json& value, std::string_view pointer, const std::vector<std::string>& known,
                                    std::string_view what) {
    if (!value.is_object())
        return make_error(
            std::format("{}: {} must be a JSON object, got {}", pointer.empty() ? "/" : pointer, what,
                        value.type_name()),
            std::format("Write {} as an object such as {{\"{}\": ...}}.", what, known.empty() ? "" : known[0]));
    for (auto it = value.begin(); it != value.end(); ++it) {
        const std::string& k = it.key();
        bool found = false;
        for (const std::string& n : known) found = found || n == k;
        if (!found)
            return make_error(std::format("{}: unknown field '{}' in {}", pj_at(pointer, k), k, what),
                              fa::did_you_mean(k, known));
    }
    return {};
}

// An optional finite number: leaves `out` alone when the key is missing.
inline Result<void> pj_float(const Json& o, std::string_view pointer, const char* key, float& out) {
    auto it = o.find(key);
    if (it == o.end()) return {};
    if (!it->is_number())
        return make_error(std::format("{}: must be a number, got {}", pj_at(pointer, key), it->type_name()),
                          std::format("Write a plain number, for example \"{}\": 1.5.", key));
    const double v = it->get<double>();
    if (!std::isfinite(v) || std::fabs(v) > 3.0e38)
        return make_error(
            std::format("{}: must be a finite number that fits a float, got {}", pj_at(pointer, key), pj_num(v)),
            "Use a normal number such as 0.5 or 100.");
    out = float(v);
    return {};
}

// An optional integer in [lo, hi] (a float with no fraction, 4.0, is accepted). The range is checked before narrowing.
inline Result<void> pj_int(const Json& o, std::string_view pointer, const char* key, std::int64_t lo, std::int64_t hi,
                           std::int64_t& out) {
    auto it = o.find(key);
    if (it == o.end()) return {};
    if (!it->is_number())
        return make_error(std::format("{}: must be an integer, got {}", pj_at(pointer, key), it->type_name()),
                          std::format("Write a whole number from {} to {}.", lo, hi));
    const double d = it->get<double>();
    if (!std::isfinite(d) || d != std::floor(d))
        return make_error(std::format("{}: must be a whole number, got {}", pj_at(pointer, key), pj_num(d)),
                          std::format("Write a whole number from {} to {}.", lo, hi));
    if (d < double(lo) || d > double(hi))
        return make_error(std::format("{}: {} is out of range {} to {}", pj_at(pointer, key), pj_num(d), lo, hi),
                          std::format("Use a value from {} to {}.", lo, hi));
    out = std::int64_t(d);
    return {};
}

// An optional unsigned 64-bit integer (a seed): a non-negative whole JSON number.
inline Result<void> pj_u64(const Json& o, std::string_view pointer, const char* key, std::uint64_t& out) {
    auto it = o.find(key);
    if (it == o.end()) return {};
    if (it->is_number_unsigned()) {
        out = it->get<std::uint64_t>();
        return {};
    }
    if (it->is_number_integer() || it->is_number_float()) {
        const double d = it->get<double>();
        if (std::isfinite(d) && d >= 0 && d == std::floor(d) && d < 18446744073709551616.0) {
            out = std::uint64_t(d);
            return {};
        }
        return make_error(
            std::format("{}: must be a whole number of 0 or more, got {}", pj_at(pointer, key), pj_num(d)),
            "Use a non-negative integer such as 1234 (a script number is exact up to 9007199254740992).");
    }
    return make_error(std::format("{}: must be a whole number, got {}", pj_at(pointer, key), it->type_name()),
                      "Write the seed as a non-negative integer such as 1234.");
}

// An optional word from `names`: sets `index`.
inline Result<void> pj_enum(const Json& o, std::string_view pointer, const char* key,
                            const std::vector<std::string>& names, int& index) {
    auto it = o.find(key);
    if (it == o.end()) return {};
    if (!it->is_string())
        return make_error(std::format("{}: must be a string, got {}", pj_at(pointer, key), it->type_name()),
                          "Write a string. " + fa::did_you_mean("", names));
    const std::string s = it->get<std::string>();
    for (std::size_t i = 0; i < names.size(); ++i) {
        if (names[i] == s) {
            index = int(i);
            return {};
        }
    }
    return make_error(std::format("{}: unknown value '{}'", pj_at(pointer, key), s), fa::did_you_mean(s, names));
}

// "{pointer}/{key}: {what}" for a value that is out of its range.
inline Error pj_range_error(std::string_view pointer, const char* key, std::string_view problem,
                            std::string_view hint) {
    return make_error(std::format("{}: {}", pj_at(pointer, key), problem), std::string(hint));
}

}  // namespace fa::detail
