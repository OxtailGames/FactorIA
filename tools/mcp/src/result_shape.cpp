#include "result_shape.h"

#include <algorithm>
#include <array>
#include <exception>
#include <initializer_list>
#include <string_view>

namespace fa::mcp_detail {

namespace {

constexpr std::size_t kMinStringBytes = 256;  // a string is never cut below this
constexpr int kMaxPasses = 24;                // each pass cuts at least one part; deep results stop here

std::size_t key_size(const std::string& key) {
    return Json(key).dump(-1, ' ', false, Json::error_handler_t::replace).size();
}

std::string pointer_token(const std::string& key) {
    std::string out;
    for (char c : key) {
        if (c == '~')
            out += "~0";
        else if (c == '/')
            out += "~1";
        else
            out += c;
    }
    return out;
}

void record(std::vector<ResultCut>& cuts, const std::string& pointer, const char* unit, std::size_t kept,
            std::size_t of) {
    for (ResultCut& c : cuts)
        if (c.pointer == pointer) {  // cut again: `of` stays the size the result had
            c.kept = kept;
            return;
        }
    cuts.push_back(ResultCut{pointer, unit, kept, of});
}

// Frees about `excess` bytes inside `node` (at `pointer`): first inside its heaviest child when that child alone weighs more
// than the excess, then by dropping its tail. Returns the bytes freed.
std::size_t shrink(Json& node, const std::string& pointer, std::size_t excess, std::vector<ResultCut>& cuts,
                   int depth) {
    if (excess == 0) return 0;
    if (node.is_string()) {
        const std::string& s = node.get_ref<const std::string&>();
        if (s.size() <= kMinStringBytes) return 0;
        const std::size_t before = json_size(node);
        const std::size_t want = s.size() > excess + kMinStringBytes ? s.size() - excess : kMinStringBytes;
        const std::size_t of = s.size();
        std::string cut(utf8_prefix(s, want));
        const std::size_t kept = cut.size();
        node = std::move(cut);
        record(cuts, pointer, "bytes", kept, of);
        const std::size_t after = json_size(node);
        return before > after ? before - after : 0;
    }
    if (!node.is_array() && !node.is_object()) return 0;
    const std::size_t n = node.size();
    if (n == 0) return 0;
    std::size_t freed = 0;
    // The heaviest child, when it alone could give the excess (and there is depth left): cut inside it.
    if (depth < 64) {
        std::size_t best = 0, bestSize = 0;
        std::size_t i = 0;
        for (auto it = node.begin(); it != node.end(); ++it, ++i) {
            const std::size_t sz = json_size(*it);
            if (sz > bestSize) {
                bestSize = sz;
                best = i;
            }
        }
        if (bestSize > excess || n == 1) {
            auto it = node.begin();
            std::advance(it, static_cast<std::ptrdiff_t>(best));
            const std::string childPointer =
                pointer + "/" + (node.is_array() ? std::to_string(best) : pointer_token(it.key()));
            freed += shrink(*it, childPointer, excess, cuts, depth + 1);
            if (freed >= excess) return freed;
        }
    }
    if (n <= 1) return freed;
    // Drop the tail (the last items or keys) until enough is freed; the first one always stays.
    std::size_t keep = n, dropped = 0;
    std::vector<std::size_t> sizes;
    sizes.reserve(n);
    for (auto it = node.begin(); it != node.end(); ++it)
        sizes.push_back(json_size(*it) + 1 +
                        (node.is_object() ? key_size(it.key()) + 1 : 0));  // + comma (+ key and colon)
    while (keep > 1 && freed + dropped < excess) dropped += sizes[--keep];
    const std::size_t of = n;
    if (node.is_array()) {
        node.erase(node.begin() + static_cast<std::ptrdiff_t>(keep), node.end());
    } else {
        Json kept = Json::object();
        std::size_t i = 0;
        for (auto it = node.begin(); it != node.end() && i < keep; ++it, ++i) kept[it.key()] = std::move(it.value());
        node = std::move(kept);
    }
    // A container cut more than once keeps the size it had first (record()).
    record(cuts, pointer, node.is_array() ? "items" : "keys", keep, of);
    return freed + dropped;
}

}  // namespace

std::size_t json_size(const Json& j) {
    switch (j.type()) {
        case Json::value_t::object: {
            std::size_t n = 2;
            bool first = true;
            for (auto it = j.begin(); it != j.end(); ++it) {
                n += (first ? 0 : 1) + key_size(it.key()) + 1 + json_size(it.value());
                first = false;
            }
            return n;
        }
        case Json::value_t::array: {
            std::size_t n = 2;
            bool first = true;
            for (const Json& v : j) {
                n += (first ? 0 : 1) + json_size(v);
                first = false;
            }
            return n;
        }
        default: return j.dump(-1, ' ', false, Json::error_handler_t::replace).size();
    }
}

std::string_view utf8_prefix(std::string_view s, std::size_t maxBytes) {
    if (s.size() <= maxBytes) return s;
    std::size_t end = maxBytes;
    // Back off continuation bytes (10xxxxxx) to the start of the sequence that does not fit whole, then drop it.
    std::size_t lead = end;
    while (lead > 0 && (static_cast<unsigned char>(s[lead]) & 0xC0) == 0x80) --lead;
    if (lead < end || (static_cast<unsigned char>(s[end]) & 0xC0) == 0x80) end = lead;
    // `end` is now at a byte that starts a sequence (or ASCII): everything before it is whole.
    return s.substr(0, end);
}

ShapedResult shape_result(Json value, std::size_t cap) {
    ShapedResult out;
    const std::size_t budget = cap > kNoteReserve ? cap - kNoteReserve : 0;
    out.originalBytes = json_size(value);
    std::size_t size = out.originalBytes;
    for (int pass = 0; pass < kMaxPasses && size > budget; ++pass) {
        const std::size_t freed = shrink(value, "", size - budget, out.cuts, 0);
        size = json_size(value);
        if (freed == 0) break;  // nothing left to cut (a result of numbers and short strings only, deep)
    }
    if (size > budget) {
        out.value = nullptr;
        out.replaced = true;
        out.cuts.clear();
    } else {
        // A part cut in one pass and dropped whole in a later one is not in the result any more: not worth a mention.
        out.cuts.erase(std::remove_if(out.cuts.begin(), out.cuts.end(),
                                      [&](const ResultCut& c) {
                                          if (c.pointer.empty()) return false;
                                          try {
                                              return !value.contains(Json::json_pointer(c.pointer));
                                          } catch (const std::exception&) {
                                              return true;
                                          }
                                      }),
                       out.cuts.end());
        out.value = std::move(value);
    }
    return out;
}

std::string truncation_note(const ShapedResult& shaped, std::size_t cap, const std::vector<std::string>& pagingArgs,
                            const std::vector<std::string>& narrowingArgs) {
    const auto kib = [](std::size_t bytes) { return std::to_string((bytes + 1023) / 1024) + " KiB"; };
    std::string note = "[truncated] This result is " + kib(shaped.originalBytes) + " of JSON, over the " + kib(cap) +
                       " a tool result may carry, so ";
    if (shaped.replaced) {
        note += "none of it is shown.";
    } else {
        note += "it was cut: ";
        for (std::size_t i = 0; i < shaped.cuts.size() && i < kMaxListedCuts; ++i) {
            const ResultCut& c = shaped.cuts[i];
            constexpr std::size_t kShownPointer = 160;  // a deep pointer is shortened: the note must fit its reserve
            const std::string pointer = c.pointer.size() <= kShownPointer
                                            ? c.pointer
                                            : std::string(utf8_prefix(c.pointer, kShownPointer)) + "...";
            note += (i ? "; " : "") + (c.pointer.empty() ? std::string("the result") : "`" + pointer + "`") +
                    " keeps the first " + std::to_string(c.kept) + " of " + std::to_string(c.of) + " " + c.unit;
        }
        if (shaped.cuts.size() > kMaxListedCuts)
            note += "; and " + std::to_string(shaped.cuts.size() - kMaxListedCuts) + " more parts";
        note += ".";
    }
    const auto list = [](const std::vector<std::string>& names) {
        std::string s;
        for (std::size_t i = 0; i < names.size(); ++i)
            s += (i == 0 ? "" : i + 1 == names.size() ? " and " : ", ") + ("`" + names[i] + "`");
        return s;
    };
    if (!pagingArgs.empty()) {
        note += " Get the rest with this command's paging argument" + std::string(pagingArgs.size() > 1 ? "s " : " ") +
                list(pagingArgs) + ": call it again asking for the next part.";
    } else if (!narrowingArgs.empty()) {
        note += " This command does not page: ask for less with " + list(narrowingArgs) + ".";
    } else {
        note += " This command does not page: ask for a smaller part (one entity, one file, one scene) or use a "
                "command that "
                "lists less.";
    }
    return note;
}

namespace {

// Names of arguments that page through a result, and of arguments that narrow it. Matched exactly (camelCase JSON keys);
// paging_name() also takes the command's own camelCase names.
constexpr std::array<const char*, 16> kPagingNames = {
    "offset",   "limit",    "cursor",     "page",     "pageSize",   "perPage", "startLine", "endLine",
    "maxLines", "maxBytes", "maxResults", "maxItems", "maxEntries", "skip",    "start",     "max"};
constexpr std::array<const char*, 16> kNarrowingNames = {
    "filter", "query",   "path",    "prefix", "glob",  "pattern",  "tag",    "category",
    "kind",   "heading", "section", "fields", "depth", "maxDepth", "entity", "name"};

template <std::size_t N>
bool named(const std::string& key, const std::array<const char*, N>& names) {
    return std::find_if(names.begin(), names.end(), [&](const char* n) { return key == n; }) != names.end();
}

// Whether the schema of a property declares one of `types` ("type": a string, or an array of them). `untyped`: the
// answer when it declares none.
bool typed_as(const Json& prop, std::initializer_list<const char*> types, bool untyped) {
    const auto t = prop.is_object() ? prop.find("type") : prop.end();
    if (!prop.is_object() || t == prop.end()) return untyped;
    auto one = [&](const Json& v) {
        return v.is_string() &&
               std::any_of(types.begin(), types.end(), [&](const char* n) { return v.get<std::string>() == n; });
    };
    if (t->is_array()) return std::any_of(t->begin(), t->end(), one);
    return one(*t);
}

// `part` (lower case) as the first or the last word of a camelCase `key`: pageToken, cursorId, nextCursor, entityLimit.
// Never inside a word (homepage) and never the whole key (named() covers those).
bool camel_word(const std::string& key, std::string_view part) {
    const std::size_t n = part.size();
    if (key.size() <= n) return false;
    const auto upper = [](char c) { return c >= 'A' && c <= 'Z'; };
    if (key.compare(0, n, part) == 0 && upper(key[n])) return true;
    const std::size_t at = key.size() - n;
    return upper(key[at]) && key[at] == static_cast<char>(part[0] - 'a' + 'A') &&
           key.compare(at + 1, n - 1, part.substr(1)) == 0;
}

// An argument that pages through a result: one of kPagingNames (a count or a position: an integer, a number or a string,
// or undeclared), or a camelCase name made with offset, limit, cursor or page whose schema says integer or string (so
// a `uvOffset` vector or a `rateLimit` number is not one).
bool paging_name(const std::string& key, const Json& prop) {
    if (named(key, kPagingNames)) return typed_as(prop, {"integer", "number", "string"}, true);
    for (std::string_view part : {"offset", "limit", "cursor", "page"})
        if (camel_word(key, part)) return typed_as(prop, {"integer", "string"}, false);
    return false;
}

// The properties of `inputSchema` for which `pick(name, schema)` is true, in the schema's own order.
template <typename Pick>
std::vector<std::string> properties_where(const Json& inputSchema, Pick pick) {
    std::vector<std::string> out;
    if (!inputSchema.is_object() || !inputSchema.contains("properties") || !inputSchema["properties"].is_object())
        return out;
    const Json& props = inputSchema["properties"];
    for (auto it = props.begin(); it != props.end(); ++it)
        if (pick(it.key(), it.value())) out.push_back(it.key());
    return out;
}

}  // namespace

std::vector<std::string> paging_arguments(const Json& inputSchema) {
    return properties_where(inputSchema, paging_name);
}
std::vector<std::string> narrowing_arguments(const Json& inputSchema) {
    return properties_where(inputSchema, [](const std::string& key, const Json& prop) {
        return !paging_name(key, prop) && named(key, kNarrowingNames);
    });
}

}  // namespace fa::mcp_detail
