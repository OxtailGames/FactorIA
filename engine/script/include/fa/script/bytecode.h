// Scripts as QuickJS bytecode: what a `--release` desktop export can ship in the game pack instead of the plain .js files
// (docs/EXPORTING.md, "Release build"). The module loader of ScriptSystem accepts such a file wherever it accepts a .js:
// the file keeps its name ("scripts/player.js"), only its content differs, and `import` between modules works as ever.
//
// A compiled script is
//
//   "FAQJSBC" + u8 format version (1)   8 bytes
//   u16 length (little-endian) + tag    who wrote it: "FactorIA <version>; QuickJS <version>"
//   the bytecode of the module          JS_WriteObject, LINE NUMBERS KEPT (so an error still says "scripts/player.js:12:7"),
//                                       the source text left out
//
// Bytecode is only valid for the QuickJS it was written by. The tag names the FactorIA and QuickJS versions, and QuickJS
// checks its own bytecode version and a checksum on top: a script from another version fails to load with an error that says
// to export the game again, never with a crash.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// True when `data` starts like a compiled script (it may still be damaged or from another version: see the loader's errors).
bool is_script_bytecode(std::string_view data);

// "FactorIA 0.1.4; QuickJS 0.17.0": the tag this build writes into every compiled script and requires when it loads one.
std::string script_bytecode_tag();

// Compiles `source` as an ES module with the QuickJS the player embeds. `moduleName` is the module's project-relative path
// ("scripts/player.js"); it is what stack traces and errors name. A syntax error is returned as
// "scripts/player.js:3:5: SyntaxError: ..." with a hint.
Result<std::vector<std::uint8_t>> compile_script_bytecode(std::string_view source, std::string_view moduleName);

// The QuickJS bytecode inside a compiled script, after checking that this build wrote it. `file` only names the script in
// the error: "scripts/player.js was compiled by FactorIA 0.1.3 (...) but this is FactorIA 0.1.4 (...)" with the hint to
// export the game again with this FactorIA version.
Result<std::string_view> script_bytecode_payload(std::string_view data, std::string_view file);

}  // namespace fa
