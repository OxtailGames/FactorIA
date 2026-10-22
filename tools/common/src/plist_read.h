// A small reader for XML property lists (Info.plist, .entitlements, the plist inside a .provisionprofile). Private to fa_tooling.
#pragma once

#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::tooling_detail {

// The root <dict> (or <array>) of an XML plist as JSON: <string>/<date> -> string, <integer> -> integer, <real> -> number,
// <true/>/<false/> -> boolean, <data> -> the base64 text. Anything before the first <plist> (a CMS envelope around a profile)
// is skipped, so `text` may be the raw bytes of a .provisionprofile as well.
Result<Json> parse_xml_plist(std::string_view text);

}  // namespace fa::tooling_detail
