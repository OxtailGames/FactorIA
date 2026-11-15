// The spellings of a path that a command which writes a caller's file must confine to the project (CommandCaller::Mcp or an
// agent): shared by the writers of the runtime (command_capabilities_tests.cpp) and of fa_authoring
// (tools/authoring/tests/authoring_capabilities_tests.cpp), so both walk the same list.
#pragma once

#include <string>
#include <vector>

namespace fa_test {

struct PathVariant {
    std::string path;
    const char* code;  // the error code the path rules give; nullptr: they do not refuse it (the command may still fail)
};

// `name` is the file name the command wants (for example "x.scene.json"), `outsideAbs` an absolute path of a folder that
// is not the project, `linkedMeta` whether the project has a "meta" link to ".factoria" (a link into a managed folder).
inline std::vector<PathVariant> confinement_variants(const std::string& name, const std::string& outsideAbs,
                                                     bool linkedMeta) {
    std::vector<PathVariant> v = {
        {"../" + name, "path_outside_root"},
        {outsideAbs + "/" + name, "absolute_path_denied"},
        {"/tmp/" + name, "absolute_path_denied"},
        {".git/" + name, "managed_path_denied"},
        {".factoria/" + name, "managed_path_denied"},
        // The Windows spellings are refused on every system (a project moves between them).
        {"scenes\\..\\..\\" + name, "path_outside_root"},
        {"..\\" + name, "path_outside_root"},
        {"C:" + name, "absolute_path_denied"},
        {"C:/" + name, "absolute_path_denied"},
        {"C:\\" + name, "absolute_path_denied"},
        {"\\\\server\\share\\" + name, "absolute_path_denied"},
        {".GIT/" + name, "managed_path_denied"},
        {".Factoria/" + name, "managed_path_denied"},
        {".git./" + name, "managed_path_denied"},
        {"a/../.git/" + name, "managed_path_denied"},
        // A name Windows cannot create is refused for a new file ("con" + name is a normal name).
        {"out/nul.x/" + name, "invalid_path"},
        // A plain project path is not refused by the path rules.
        {"out/" + name, nullptr},
        {"out/con" + name, nullptr},
    };
    if (linkedMeta) v.push_back({"meta/" + name, "managed_path_denied"});
    return v;
}

}  // namespace fa_test
