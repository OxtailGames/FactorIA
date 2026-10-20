// String helpers used across modules.
#pragma once

#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace fa {

std::string to_lower(std::string_view s);
bool iequals(std::string_view a, std::string_view b);
bool starts_with(std::string_view s, std::string_view prefix);
bool ends_with(std::string_view s, std::string_view suffix);
std::string_view trim(std::string_view s);
std::vector<std::string> split(std::string_view s, char sep, bool skipEmpty = true);
std::string join(std::span<const std::string> parts, std::string_view sep);
std::string replace_all(std::string s, std::string_view from, std::string_view to);
// Glob over forward-slash paths: `*` and `?` stay inside a folder name, `**` crosses folders ("**/" also matches none).
bool glob_match(std::string_view pattern, std::string_view path);

std::size_t edit_distance(std::string_view a, std::string_view b);  // case-insensitive Levenshtein
// Closest candidate within a reasonable distance, or "" if none is close.
// Used for "did you mean ..." hints everywhere.
std::string closest_match(std::string_view input, std::span<const std::string> candidates);
// "Unknown X 'foo'. Did you mean 'bar'? Valid: a, b, c" style message tail.
std::string did_you_mean(std::string_view input, std::span<const std::string> candidates, std::size_t listMax = 12);

std::string base64_encode(const void* data, std::size_t size);
std::vector<unsigned char> base64_decode(std::string_view text);

}  // namespace fa
