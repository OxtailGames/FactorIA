// What the vector.* command files share (vector_commands.cpp: the operations on shapes; vector_edit_commands.cpp: the commands the
// Vector panel needs): the argument readers, the schema pieces and `run`, which reads the SVG from a file, text or an image document's
// svg layer, runs a command body on it and writes the result back with a preview.
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "vector_ops.h"
#include "vector_svg.h"

namespace fa::vec::cmd {

struct Ctx {
    const char* cmd;
    std::string projectDir;
    const Json& a;
    SvgDoc& doc;
    std::vector<std::string>& warnings;
};
using Body = std::function<Json(Ctx&)>;

// ---- arguments (they throw CommandError with the pointer, what is wrong and how to fix it) ----------------------------------
double num_arg(const Json& a, const char* cmd, const char* key, double lo, double hi, double def, const char* hint = "");
int int_arg(const Json& a, const char* cmd, const char* key, int lo, int hi, int def);
std::string enum_arg(const Json& a, const char* cmd, const char* key, const std::vector<std::string>& names, const std::string& def, bool required = false);
std::string str_arg(const Json& a, const char* cmd, const char* key, const std::string& def, const char* hint = "");
bool point_arg(const Json& a, const char* cmd, const char* key, P& out, const char* meaning);
bool valid_id(const std::string& id);
// `key`: one id or selector, or a list of them (duplicates dropped, the order kept).
std::vector<XNode*> pick(Ctx& c, const char* key, bool required);
std::vector<XNode*> pick_or_all(Ctx& c);
XNode* single_element(Ctx& c, const char* key);
Settings settings_of(Ctx& c, double divisor);

// ---- placement ----------------------------------------------------------------------------------------------------------------
Placement placement_of(Ctx& c, bool lineArt, const Settings& s);
struct Frame {
    P centre;
    double unit;  // 40% of the drawing's shorter side, in the parent's units
};
Frame frame_of(Ctx& c, const Placement& at);

// ---- schema pieces -------------------------------------------------------------------------------------------------------------
Json str_prop(const char* desc);
Json num_prop(const char* desc);
Json bool_prop(const char* desc, bool def);
Json refs_prop(const char* desc);
Json enum_prop(const std::vector<std::string>& names, const char* desc);
Json common_props();    // source / svg / document + layer, out, overwrite, dryRun, preview, previewSize, bake
Json geometry_props();  // tolerance, curves, cornerAngle
Json merge_props(Json a, const Json& b);
Json placement_props();  // id, parent, before, transform, fill, stroke, strokeWidth, opacity, attributes

// The command: checks the arguments against `props`, reads the SVG, runs `body`, writes the result where the arguments say and adds the
// preview `$image` (unless `preview` is false).
Json run(const std::string& projectDir, const Json& a, const char* cmd, const Json& props, bool readOnly, const Body& body);

}  // namespace fa::vec::cmd
