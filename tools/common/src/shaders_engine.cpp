// The ShaderCompiler the engine uses for custom materials in development (docs/design/CUSTOM_SHADERS.md, "Where and when
// it runs"): the renderer asks for a twin, this compiles it with compile_material().
#include "fa/tooling/shaders.h"

namespace fa {

ShaderCompiler make_engine_shader_compiler(const std::string& projectDir, const SetupContext& context) {
    return [projectDir, context](const std::string& materialPath, const std::string& slang) -> Result<Json> {
        ShaderCompileOptions options;
        options.setup = context;
        options.dialects = {slang};
        auto r = compile_material(projectDir, materialPath, options);
        if (!r) return r.error();
        if (!r->ok || !r->twins.count(slang)) {
            std::string message;
            for (const ShaderIssue& e : r->errors) message += (message.empty() ? "" : "\n") + e.to_string();
            if (message.empty()) message = "Material '" + materialPath + "' did not compile for " + slang + ".";
            return Error{message, r->errors.empty() ? std::string() : r->errors[0].hint};
        }
        return r->twins.at(slang);
    };
}

}  // namespace fa
