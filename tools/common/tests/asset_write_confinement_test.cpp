// The asset commands (assets.*, audio.*, sfx.*, music.*, model.*, rig.*, skin3d.*, anim3d.*, vfx.*) write only where the project allows
// (M92.1b2a / M92.2): a file they make goes through the project write check, so a caller without WriteAnywhere (an MCP client, an
// agent) cannot leave the project, no caller can write into .git or .factoria/, and a command that is declared read-only or
// {read,state} but keeps a picture at a caller's path asks for writeProject first. One representative of each family; the checks
// that need a graphics device are not here.
#include <doctest.h>

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

#include "asset_test_helpers.h"
#include "audio_test_wav.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/tooling/audio_analysis.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

std::string code_of(const CommandResult& r) { return r.error.is_object() ? r.error.value("code", std::string()) : std::string(); }
std::string message_of(const CommandResult& r) { return r.error.is_object() ? r.error.value("message", std::string()) : std::string(); }

bool make_dir_link(const stdfs::path& link, const stdfs::path& target) {
    std::error_code ec;
    stdfs::create_directory_symlink(target, link, ec);
    return !ec;
}

const char* kDoor = R"({"format": "factoria.audio/1", "doc": "test door", "source": "assets/raw/door.wav", "steps": [
    {"type": "trim", "start": 0.2, "end": 0.8}, {"type": "normalize", "target": -6}]})";
const char* kCrate = R"({"format":"factoria.model/1","nodes":[
    {"op":"rounded_box","size":[1,1,1],"radius":0.05,"position":[0,0.5,0],"part":"body"}]})";
const char* kSvg = R"(<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="#c03030"/></svg>)";

// A project with the inputs the commands below read, and a `.git` folder so a write into it can be seen.
struct Fixture : AssetsProject {
    TempDir elsewhere;
    Fixture() {
        register_audio_commands(registry, dir);  // assets.spectrogram and assets.check_mix
        std::filesystem::create_directories(file(".git/hooks"));
        write_all(file("assets/raw/door.wav"), sine_wav(1.0, -20.0));
        write_all(file("assets/audio/door.audio.json"), kDoor);
        write_all(file("assets/models/crate.model.json"), kCrate);
        write_all(file("assets/tone.wav"), sine_wav(0.5, -12.0));
        write_png(file("assets/walk.png"), make_image(40, 20, {200, 40, 40, 255}));
        write_png(file("assets/a.png"), make_image(16, 16, {20, 90, 200, 255}));
    }
    std::string outside_file() const { return (elsewhere.path / "out.png").generic_string(); }
    bool git_untouched() const { return std::filesystem::is_empty(file(".git/hooks")) && !exists(".git/out.png"); }
};

// A command with the argument that names where its output goes; `with(path)` is its arguments for that path.
struct Writer {
    const char* command;
    const char* argument;
    Json (*args)(const std::string& path);
};

const std::vector<Writer>& caller_path_writers() {
    static const std::vector<Writer> list = {
        {"model.preview", "out", [](const std::string& p) { return Json{{"path", "assets/models/crate.model.json"}, {"out", p}}; }},
        {"audio.render", "pictureOut", [](const std::string& p) { return Json{{"path", "assets/audio/door.audio.json"}, {"pictureOut", p}}; }},
        {"assets.spectrogram", "out", [](const std::string& p) { return Json{{"path", "assets/tone.wav"}, {"out", p}}; }},
        {"assets.contact_sheet", "path", [](const std::string& p) { return Json{{"paths", Json::array({"assets/a.png"})}, {"path", p}}; }},
        {"music.info", "pictureOut", [](const std::string& p) { return Json{{"path", "assets/music/t.song.json"}, {"pictureOut", p}}; }},
    };
    return list;
}

// The writers that make a project file at `path`; `path` is judged before anything is made.
const std::vector<Writer>& project_writers() {
    static const std::vector<Writer> list = {
        {"audio.create", "path", [](const std::string& p) { return Json{{"path", p}, {"source", "assets/raw/door.wav"}}; }},
        {"anim3d.create", "path", [](const std::string& p) { return Json{{"path", p}}; }},
        {"model.create", "path", [](const std::string& p) { return Json{{"path", p}, {"nodes", Json::array({{{"op", "box"}, {"size", {1, 1, 1}}}})}}; }},
        {"rig.create", "path", [](const std::string& p) { return Json{{"path", p}, {"model", "assets/models/crate.model.json"}, {"template", "humanoid"}}; }},
        {"assets.generate_texture", "path", [](const std::string& p) { return Json{{"path", p}, {"preset", "paper"}, {"width", 16}, {"height", 16}}; }},
        {"vfx.create", "path", [](const std::string& p) { return Json{{"path", p}}; }},
        {"assets.slice_sheet", "out", [](const std::string& p) { return Json{{"path", "assets/walk.png"}, {"columns", 4}, {"rows", 2}, {"out", p}}; }},
        {"assets.synth_sound", "path", [](const std::string& p) { return Json{{"path", p}, {"preset", "bark"}}; }},
        {"assets.rasterize_svg", "path", [](const std::string& p) { return Json{{"path", p}, {"svg", kSvg}}; }},
        {"music.create", "path", [](const std::string& p) { return Json{{"path", p}, {"picture", false}, {"arpeggio", false}}; }},
    };
    return list;
}

}  // namespace

TEST_CASE("a picture kept at a caller's path: MCP stays inside the project, .git is closed to everyone, the user may name any folder") {
    Fixture p;
    for (const Writer& w : caller_path_writers()) {
        CAPTURE(w.command);
        // The command-line user (the default caller): .git is closed, an absolute path is theirs.
        {
            CommandResult r = p.call(w.command, w.args(".git/out.png"));
            REQUIRE_FALSE(r.ok);
            CHECK_MESSAGE(code_of(r) == "managed_path_denied", r.error.dump());
        }
        CommandCapabilityScope mcp(capability_sets::mcp());
        const std::pair<std::string, std::string> bad[] = {{"../out.png", "path_outside_root"},
                                                          {p.outside_file(), "absolute_path_denied"},
                                                          {".git/out.png", "managed_path_denied"},
                                                          {".factoria/state/out.png", "managed_path_denied"}};
        for (const auto& entry : bad) {
            const std::string& path = entry.first;
            const std::string& code = entry.second;
            CAPTURE(path);
            CommandResult r = p.call(w.command, w.args(path));
            REQUIRE_FALSE(r.ok);
            CHECK_MESSAGE(code_of(r) == code, r.error.dump());
            CHECK_FALSE(r.error.value("hint", std::string()).empty());
        }
    }
    CHECK_FALSE(stdfs::exists(p.elsewhere.path / "out.png"));
    CHECK_FALSE(stdfs::exists(p.dir + "/../out.png"));
    CHECK(p.git_untouched());
}

TEST_CASE("a picture kept at a caller's path: the command-line user can still write an absolute path") {
    Fixture p;
    const std::string out = p.outside_file();
    CommandResult r = p.call("assets.spectrogram", Json{{"path", "assets/tone.wav"}, {"out", out}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(stdfs::exists(p.elsewhere.path / "out.png"));

    stdfs::remove(p.elsewhere.path / "out.png");
    r = p.call("model.preview", Json{{"path", "assets/models/crate.model.json"}, {"out", out}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(stdfs::exists(p.elsewhere.path / "out.png"));

    // Inside the project the same call works for an MCP client too.
    CommandCapabilityScope mcp(capability_sets::mcp());
    r = p.call("model.preview", Json{{"path", "assets/models/crate.model.json"}, {"out", "assets/crate.png"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(p.exists("assets/crate.png"));
}

TEST_CASE("the previews that keep a picture only at a caller's path are not read-only; {read,state} may look but not keep") {
    Fixture p;
    for (const char* name : {"model.preview", "audio.render", "assets.spectrogram", "assets.contact_sheet", "assets.preview_sheet",
                             "assets.preview_in_scene", "music.info", "anim3d.preview", "skin3d.preview", "assets.check_art"}) {
        CAPTURE(name);
        const CommandInfo* info = p.registry.info(name);
        REQUIRE(info != nullptr);
        CHECK(info->capabilitiesDeclared);
        CHECK_FALSE(info->readOnly);
        CHECK(info->capabilities == capability_sets::changes_state());
    }
    for (const char* name : {"model.info", "audio.info", "rig.info", "skin3d.info", "anim3d.info", "model.check"}) {
        CAPTURE(name);
        const CommandInfo* info = p.registry.info(name);
        REQUIRE(info != nullptr);
        CHECK(info->readOnly);
        CHECK(info->capabilities == capability_sets::reads());
    }

    CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
    // Without a path they work: the picture is the engine's own temporary screenshot.
    CommandResult look = p.call("model.preview", Json{{"path", "assets/models/crate.model.json"}});
    CHECK_MESSAGE(look.ok, look.error.dump());
    look = p.call("assets.contact_sheet", Json{{"paths", Json::array({"assets/a.png"})}});
    CHECK_MESSAGE(look.ok, look.error.dump());
    // With one they need writeProject.
    for (const Writer& w : caller_path_writers()) {
        CAPTURE(w.command);
        CommandResult r = p.call(w.command, w.args("assets/kept.png"));
        REQUIRE_FALSE(r.ok);
        CHECK_MESSAGE(code_of(r) == "capability_denied", r.error.dump());
    }
    CHECK_FALSE(p.exists("assets/kept.png"));
}

TEST_CASE("the commands that make project files: MCP stays inside the project and no caller reaches .git, before anything is made") {
    Fixture p;
    for (const Writer& w : project_writers()) {
        CAPTURE(w.command);
        {
            CommandResult r = p.call(w.command, w.args(".git/out.png"));
            REQUIRE_FALSE(r.ok);
        }
        CommandCapabilityScope mcp(capability_sets::mcp());
        for (const std::string& path : {std::string("../out.png"), p.outside_file(), std::string(".git/out.png"), std::string(".factoria/state/out.png")}) {
            CAPTURE(path);
            CommandResult r = p.call(w.command, w.args(path));
            REQUIRE_FALSE(r.ok);
            CHECK_FALSE(message_of(r).empty());
        }
    }
    CHECK_FALSE(stdfs::exists(p.elsewhere.path / "out.png"));
    CHECK_FALSE(stdfs::exists(p.dir + "/../out.png"));
    CHECK(p.git_untouched());
}

// A link in assets/ that leads into .git: the check is on the real path, so the plain-looking name is refused too.
TEST_CASE("the commands that make project files refuse a link into .git") {
    Fixture p;
    if (!make_dir_link(p.file("assets/meta"), p.file(".git/hooks"))) {
        MESSAGE("this system does not let the test make a folder link: skipped");
        return;
    }
    const std::vector<std::pair<Writer, std::string>> through = {
        {project_writers()[0], "assets/meta/d.audio.json"},      {project_writers()[1], "assets/meta/a.anim.json"},
        {project_writers()[2], "assets/meta/c.model.json"},      {project_writers()[3], "assets/meta/h.rig.json"},
        {project_writers()[4], "assets/meta/t.png"},             {project_writers()[5], "assets/meta/h.vfx.json"},
        {project_writers()[6], "assets/meta/s.png"},             {project_writers()[7], "assets/meta/b.wav"},
        {project_writers()[8], "assets/meta/c.png"},             {project_writers()[9], "assets/meta/t.song.json"},
    };
    for (const bool mcp : {false, true}) {
        std::optional<CommandCapabilityScope> scope;
        if (mcp) scope.emplace(capability_sets::mcp());
        for (const auto& entry : through) {
            const Writer& w = entry.first;
            const std::string& path = entry.second;
            CAPTURE(w.command);
            CAPTURE(path);
            CAPTURE(mcp);
            CommandResult r = p.call(w.command, w.args(path));
            REQUIRE_FALSE(r.ok);
            const bool managed = message_of(r).find("managed_path_denied") != std::string::npos;
            const bool coded = code_of(r) == "managed_path_denied";
            CHECK_MESSAGE((managed || coded), r.error.dump());
        }
    }
    for (const Writer& w : caller_path_writers()) {
        CAPTURE(w.command);
        CommandResult r = p.call(w.command, w.args("assets/meta/out.png"));
        REQUIRE_FALSE(r.ok);
        CHECK_MESSAGE(code_of(r) == "managed_path_denied", r.error.dump());
    }
    CHECK(p.git_untouched());
}

TEST_CASE("the commands that make project files need writeProject: {read,state} is refused before the arguments are looked at") {
    Fixture p;
    CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
    for (const Writer& w : project_writers()) {
        CAPTURE(w.command);
        CommandResult r = p.call(w.command, w.args("assets/ok.png"));
        REQUIRE_FALSE(r.ok);
        CHECK_MESSAGE(code_of(r) == "capability_denied", r.error.dump());
    }
    for (const char* name : {"audio.bake", "audio.edit", "model.bake", "model.edit", "model.texture", "model.uv", "rig.fit", "rig.bake", "skin3d.auto",
                             "anim3d.set_keys", "anim3d.generate", "vfx.edit", "music.edit", "music.render", "music.import_midi", "music.export_midi",
                             "sfx.render", "sfx.preset", "assets.pack_atlas", "assets.draw_icon", "assets.draw_capsules", "assets.import",
                             "assets.bake_sheet", "assets.regenerate", "assets.analyze_audio", "assets.subset_font", "assets.generate_loop",
                             "assets.convert_audio", "assets.animate_svg", "model.import_clean"}) {
        CAPTURE(name);
        const CommandInfo* info = p.registry.info(name);
        REQUIRE(info != nullptr);
        CHECK(info->capabilitiesDeclared);
        CHECK(info->capabilities.has_all(CapabilitySet{Capability::WriteProject}));
        CHECK_FALSE(info->readOnly);
        CommandResult r = p.call(name, Json::object());
        REQUIRE_FALSE(r.ok);
        CHECK_MESSAGE(code_of(r) == "capability_denied", name << ": " << r.error.dump());
    }
}

TEST_CASE("every path argument the asset commands mark is read or write") {
    Fixture p;
    int marked = 0;
    for (const CommandInfo* info : p.registry.list()) {
        if (!info->inputSchema.is_object() || !info->inputSchema.contains("properties")) continue;
        for (auto it = info->inputSchema["properties"].begin(); it != info->inputSchema["properties"].end(); ++it) {
            if (!it.value().is_object() || !it.value().contains("x-fa-path")) continue;
            ++marked;
            CAPTURE(info->name);
            CAPTURE(it.key());
            const std::string kind = it.value()["x-fa-path"].get<std::string>();
            const bool kindOk = kind == "read" || kind == "write";
            CHECK(kindOk);
        }
    }
    CHECK(marked > 40);
    for (const Writer& w : caller_path_writers()) {
        CAPTURE(w.command);
        const CommandInfo* info = p.registry.info(w.command);
        REQUIRE(info != nullptr);
        REQUIRE(info->inputSchema["properties"].contains(w.argument));
        CHECK(info->inputSchema["properties"][w.argument].value("x-fa-path", std::string()) == "write");
    }
    for (const Writer& w : project_writers()) {
        CAPTURE(w.command);
        const CommandInfo* info = p.registry.info(w.command);
        REQUIRE(info != nullptr);
        REQUIRE(info->inputSchema["properties"].contains(w.argument));
        CHECK(info->inputSchema["properties"][w.argument].value("x-fa-path", std::string()) == "write");
    }
}
