// fa::parse_json on any bytes: the parser every scene, prefab, project file and MCP message goes through. What parses is
// written back (both layouts) and read again, which must work and keep the size of an array or an object.
#include <cstddef>
#include <cstdint>
#include <string>

#include "fa/core/json.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    auto parsed = fa::parse_json(fa::fuzz::as_text(data, size), "fuzz.json");
    if (!parsed) return 0;
    const fa::Json& value = parsed.value();
    const std::string pretty = fa::dump_json(value);
    const std::string compact = fa::dump_json(value, fa::JsonFormat{});
    for (const std::string* text : {&pretty, &compact}) {
        auto again = fa::parse_json(*text, "fuzz-again.json");
        if (!again) fa::fuzz::fail("what dump_json wrote does not parse");
        // Scalars are not compared: 1e999 is infinity and is written as null. A container keeps its type and its size.
        if ((value.is_object() || value.is_array()) &&
            (again.value().type() != value.type() || again.value().size() != value.size()))
            fa::fuzz::fail("a dump and a parse changed the size of the top-level value");
    }
    (void)fa::json_at(value, "/a/0/b");
    return 0;
}
