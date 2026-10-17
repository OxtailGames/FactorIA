// Scripts as QuickJS bytecode (fa/script/bytecode.h): what a `--release` export puts in the game pack.
#include <doctest.h>

#include "test_host.h"
#include "fa/script/bytecode.h"

using namespace fa;
using namespace fa::test;

namespace {

// Compiles `source` the way the export does and stores the result in the test project under `path`.
std::string compiled(TestHost& h, const std::string& path, const std::string& source) {
    auto bytes = compile_script_bytecode(source, path);
    REQUIRE_MESSAGE(bytes.ok(), (bytes.ok() ? "" : bytes.error().to_string()));
    std::string text(bytes->begin(), bytes->end());
    h.file(path, text);
    return text;
}

Json scene_with_script(const std::string& path) {
    return Json::object({{"format", "factoria.scene/1"},
                         {"entities", Json::array({Json::object({{"id", "p"},
                                                                  {"components", Json::object({{"Script", Json::object({{"path", path}})}})}})})}});
}

bool any_error_has(const TestHost& h, const std::string& needle) {
    for (const auto& e : h.scripts.errors())
        if (e.message.find(needle) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("bytecode: a compiled script has the signature, the version tag and no source text") {
    TestHost h("bc_format");
    const std::string text = compiled(h, "scripts/a.js", "// UNIQUE_COMMENT_IN_SOURCE\nexport const answer = 42;\n");
    CHECK(is_script_bytecode(text));
    CHECK_FALSE(is_script_bytecode("export const answer = 42;\n"));
    CHECK_FALSE(is_script_bytecode(""));
    CHECK(text.find(script_bytecode_tag()) != std::string::npos);
    CHECK(text.find("UNIQUE_COMMENT_IN_SOURCE") == std::string::npos);  // the source is not shipped
    CHECK(script_bytecode_tag().find("QuickJS") != std::string::npos);
    auto payload = script_bytecode_payload(text, "scripts/a.js");
    REQUIRE(payload.ok());
    CHECK_FALSE(payload->empty());
}

TEST_CASE("bytecode: a syntax error is reported with file, line and column at compile time") {
    auto r = compile_script_bytecode("export const ok = 1;\n\nconst = ;\n", "scripts/broken.js");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.rfind("scripts/broken.js:3:", 0) == 0);
    CHECK(r.error().message.find("SyntaxError") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
}

TEST_CASE("bytecode: behaviours, imports between modules, JSON data and tools run from compiled scripts") {
    TestHost h("bc_run");
    compiled(h, "lib/util.js", "// UNIQUE_COMMENT_LIB\nexport const twice = (n) => n * 2;\n");
    h.file("scripts/data.json", "{\"base\": 21}");
    compiled(h, "scripts/a.js",
             "import { Behaviour } from 'factoria';\nimport { twice } from '../lib/util.js';\nimport data from './data.json';\n"
             "export default class A extends Behaviour {\n  speed = 3;\n  onStart() { globalThis.V = twice(data.base) + this.speed; }\n}\n");
    compiled(h, "tools/hello.js",
             "export default { name: 'hello', summary: 's', input: {type:'object', properties:{n:{type:'integer', default: 2}}}, "
             "run({n}) { return { twice: n * 2 }; } };\n");
    h.file("scenes/main.scene.json", scene_with_script("scripts/a.js").dump());
    REQUIRE(h.start());
    CHECK(h.scripts.check_syntax("scripts/a.js").ok());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(2);
    CHECK(h.scripts.errors().empty());
    CHECK(h.scripts.eval("globalThis.V")->get<int>() == 45);
    auto tool = h.cmds.call("project.hello", Json::object());
    REQUIRE(tool.ok);
    CHECK(tool.result["twice"] == 4);

    // Plain source and compiled scripts can be mixed: the loader looks at each file.
    h.file("scripts/plain.js", "import { Behaviour } from 'factoria';\nexport default class P extends Behaviour { onStart() { globalThis.W = 7; } }\n");
    h.file("scenes/mixed.scene.json", scene_with_script("scripts/plain.js").dump());
    REQUIRE(h.load_scene_now("scenes/mixed.scene.json").empty());
    h.step_frames(1);
    CHECK(h.scripts.eval("globalThis.W")->get<int>() == 7);
    CHECK(h.scripts.errors().empty());
}

TEST_CASE("bytecode: an error inside a compiled module still names the file and the line") {
    TestHost h("bc_errors");
    compiled(h, "scripts/e.js",
             "import { Behaviour } from 'factoria';\n// a comment line\nexport default class E extends Behaviour {\n"
             "  onUpdate() { this.nothing.x = 1; }\n}\n");
    h.file("scenes/main.scene.json", scene_with_script("scripts/e.js").dump());
    REQUIRE(h.start());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(2);
    int typeErrors = 0;
    for (const auto& e : h.scripts.errors())
        if (e.message.find("TypeError") != std::string::npos) {
            ++typeErrors;
            CHECK(e.file == "scripts/e.js");
            CHECK(e.line == 4);  // the line of the source, though the source is not shipped
            CHECK(e.entityId == "p");
        }
    CHECK(typeErrors == 1);  // recorded once, like for a plain script

    // Also an error thrown while the module loads (top level code), and through an import.
    compiled(h, "scripts/lib.js", "export const x = 1;\nthrow new Error('boom at load');\n");
    compiled(h, "scripts/user.js", "import { Behaviour } from 'factoria';\nimport { x } from './lib.js';\nexport default class U extends Behaviour {}\n");
    h.file("scenes/user.scene.json", scene_with_script("scripts/user.js").dump());
    h.scripts.clear_errors();
    h.load_scene_now("scenes/user.scene.json");
    bool named = false;
    for (const auto& e : h.scripts.errors())
        if (e.message.find("boom at load") != std::string::npos) {
            named = true;
            CHECK(e.file == "scripts/lib.js");
            CHECK(e.line == 2);
        }
    CHECK(named);
}

TEST_CASE("bytecode: a script from another version, or a damaged one, fails with an error that says what to do") {
    TestHost h("bc_version");
    const std::string good = compiled(h, "scripts/a.js", "export const answer = 42;\n");

    // The tag names the versions that compiled the script; another FactorIA or QuickJS is refused before QuickJS sees the bytes.
    const std::string tag = script_bytecode_tag();
    std::string other = good;
    other.replace(10 + tag.find("FactorIA") + 7, 1, "B");  // "FactorIB ..."
    auto mismatch = script_bytecode_payload(other, "scripts/a.js");
    REQUIRE_FALSE(mismatch.ok());
    CHECK(mismatch.error().message.find("'scripts/a.js' was compiled by FactorIB") != std::string::npos);
    CHECK(mismatch.error().message.find("but this game runs " + tag) != std::string::npos);
    CHECK(mismatch.error().hint.find("Export the game again with this FactorIA version") != std::string::npos);
    CHECK(mismatch.error().hint.find("export.scriptBytecode: false") != std::string::npos);

    std::string newerFormat = good;
    newerFormat[7] = 9;
    auto format = script_bytecode_payload(newerFormat, "scripts/a.js");
    REQUIRE_FALSE(format.ok());
    CHECK(format.error().message.find("format 9") != std::string::npos);
    CHECK(format.error().hint.find("Export the game again") != std::string::npos);

    auto cut = script_bytecode_payload(good.substr(0, 11), "scripts/a.js");
    REQUIRE_FALSE(cut.ok());
    CHECK(cut.error().message.find("cut short") != std::string::npos);

    auto plain = script_bytecode_payload("export const a = 1;", "scripts/a.js");
    REQUIRE_FALSE(plain.ok());
    CHECK(plain.error().message.find("not a compiled script") != std::string::npos);

    // The game itself: the error is a script error that names the file and carries the hint, and nothing crashes.
    h.file("scripts/mismatch.js", other);
    h.file("scenes/main.scene.json", scene_with_script("scripts/mismatch.js").dump());
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(1);
    REQUIRE_FALSE(h.scripts.errors().empty());
    CHECK(any_error_has(h, "was compiled by FactorIB"));
    CHECK(any_error_has(h, "Export the game again with this FactorIA version"));
    CHECK(any_error_has(h, "scripts/mismatch.js"));
    auto syntax = h.scripts.check_syntax("scripts/mismatch.js");  // what validate and the editor ask about a script
    REQUIRE_FALSE(syntax.ok());
    CHECK(syntax.error().message.find("was compiled by FactorIB") != std::string::npos);

    // Right tag, damaged bytecode: QuickJS refuses it (its own version and checksum checks), the error still says what to do.
    std::string damaged = good.substr(0, good.size() - 6);
    h.file("scripts/damaged.js", damaged);
    h.file("scenes/damaged.scene.json", scene_with_script("scripts/damaged.js").dump());
    h.scripts.clear_errors();
    h.load_scene_now("scenes/damaged.scene.json");
    h.step_frames(1);
    REQUIRE_FALSE(h.scripts.errors().empty());
    CHECK(any_error_has(h, "scripts/damaged.js"));
    CHECK(any_error_has(h, "Export the game again"));
}
