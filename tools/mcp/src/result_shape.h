// How a tool result is cut down to the size cap and summed up in one line (server.cpp). Private to fa_mcp.
#pragma once

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa::mcp_detail {

// Bytes of `j` serialized compactly (dump(-1) with invalid UTF-8 replaced), counted without building the text.
std::size_t json_size(const Json& j);

// The longest prefix of `s` of at most `maxBytes` bytes that does not end inside a UTF-8 sequence.
std::string_view utf8_prefix(std::string_view s, std::size_t maxBytes);

// One part of a result that was cut: the first `kept` of `of` items (array), keys (object) or bytes (string).
struct ResultCut {
    std::string pointer;  // JSON pointer, "" for the whole result
    std::string unit;     // "items", "keys", "bytes"
    std::size_t kept = 0;
    std::size_t of = 0;
};

struct ShapedResult {
    Json value;                   // the result, or its cut-down copy (always valid JSON)
    std::vector<ResultCut> cuts;  // empty when nothing was cut
    std::size_t originalBytes = 0;
    bool replaced = false;        // nothing of the result fitted: `value` is only the note
};

// Room kept free under the cap for the truncation note (it lists at most kMaxListedCuts cuts).
inline constexpr std::size_t kNoteReserve = 2048;
inline constexpr std::size_t kMaxListedCuts = 6;
// The smallest cap McpServer accepts: room for the note and some of the result.
inline constexpr std::size_t kMinResultCap = 4 * kNoteReserve;

// Cuts `value` down until it fits `cap` - kNoteReserve bytes of compact JSON: the part that weighs most is cut first (the
// tail of an array or an object, the end of a long string). The work is bounded by a fixed number of passes, whatever the
// result; a result that still does not fit is replaced by null (`replaced`).
ShapedResult shape_result(Json value, std::size_t cap);

// The truncation note: what was cut, and how to get the rest. `pagingArgs` are the paging arguments the command takes
// (offset, limit, startLine...), `narrowingArgs` the arguments that ask for less (filter, path...).
std::string truncation_note(const ShapedResult& shaped, std::size_t cap, const std::vector<std::string>& pagingArgs,
                            const std::vector<std::string>& narrowingArgs);

// The arguments of `inputSchema` (a command's) that page through a result, and those that narrow it, in the schema's
// order: a known name (offset, limit, cursor, startLine, filter, path...), or for paging a camelCase name whose first or
// last word is offset, limit, cursor or page (pageToken, nextCursor, entityLimit) declared as an integer or a string (not
// homepage, a `uvOffset` vector or a `rateLimit` number). An argument counts once, as paging first.
std::vector<std::string> paging_arguments(const Json& inputSchema);
std::vector<std::string> narrowing_arguments(const Json& inputSchema);

}  // namespace fa::mcp_detail
