#include <doctest.h>

#include <filesystem>
#include <set>
#include <string>

#include "fa/tooling/api_export.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/project_fs.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
struct FsFixture {
    testing::TempDir tmp;
    testing::TempDir outside;
    CommandRegistry reg;
    FsFixture() {
        testing::write_all(tmp.path / "scripts/a.js", "const speed = 300;\nconst jump = 600;\nexport default 1;\n");
        testing::write_all(tmp.path / "dup.txt", "x = 1\nx = 1\n");
        testing::write_all(tmp.path / ".factoria/log.txt", "secret needle");
        testing::write_all(tmp.path / "bin.dat", std::string("needle\0bin", 10));
        testing::write_all(outside.path / "secret.txt", "top secret");
        std::error_code ec;
        stdfs::create_symlink(outside.path, tmp.path / "link", ec);
        register_fs_commands(reg, tmp.str());
    }
};
}  // namespace

TEST_CASE("fs: sandbox rejects escapes with helpful errors") {
    FsFixture f;
    for (const char* bad : {"../x", "scripts/../../x", "/etc/passwd", "C:/Windows/x", "~/x", "a\\..\\..\\x"}) {
        CAPTURE(bad);
        auto r = f.reg.call("fs.read", {{"path", bad}});
        CHECK_FALSE(r.ok);
        auto w = f.reg.call("fs.write", {{"path", bad}, {"content", "x"}});
        CHECK_FALSE(w.ok);
    }
    auto r = f.reg.call("fs.read", {{"path", "../x"}});
    CHECK(r.error["hint"].get<std::string>().size() > 5);
    // Symlink leaving the project
    if (stdfs::is_symlink(f.tmp.path / "link")) {
        CHECK_FALSE(f.reg.call("fs.read", {{"path", "link/secret.txt"}}).ok);
        CHECK_FALSE(f.reg.call("fs.write", {{"path", "link/new.txt"}, {"content", "x"}}).ok);
        CHECK_FALSE(stdfs::exists(f.outside.path / "new.txt"));
    }
    CHECK_FALSE(f.reg.call("fs.delete", {{"path", "."}}).ok);
    CHECK(resolve_project_path(f.tmp.str(), "scripts/a.js").ok());
}

TEST_CASE("fs.write: base64 encoding writes binary files") {
    FsFixture f;
    // 1x1 PNG
    const std::string b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";
    auto w = f.reg.call("fs.write", {{"path", "sprites/dot.png"}, {"content", b64}, {"encoding", "base64"}});
    REQUIRE(w.ok);
    std::string bytes = testing::read_all(f.tmp.path / "sprites/dot.png");
    CHECK(w.result["bytes"] == bytes.size());
    REQUIRE(bytes.size() > 24);
    CHECK(bytes.substr(1, 3) == "PNG");
    auto be32 = [&](size_t o) { return (unsigned char)bytes[o] << 24 | (unsigned char)bytes[o + 1] << 16 | (unsigned char)bytes[o + 2] << 8 | (unsigned char)bytes[o + 3]; };
    CHECK(be32(16) == 1);  // IHDR width
    CHECK(be32(20) == 1);  // IHDR height

    auto bad = f.reg.call("fs.write", {{"path", "sprites/bad.png"}, {"content", "iVBO!Rw0K"}, {"encoding", "base64"}});
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("character 4") != std::string::npos);
    CHECK(bad.error["hint"].get<std::string>().size() > 5);
    CHECK_FALSE(stdfs::exists(f.tmp.path / "sprites/bad.png"));
    CHECK_FALSE(f.reg.call("fs.write", {{"path", "x.bin"}, {"content", "AA"}, {"encoding", "hex"}}).ok);
}

TEST_CASE("fs: list read write edit delete") {
    FsFixture f;
    auto list = f.reg.call("fs.list", {{"recursive", true}});
    REQUIRE(list.ok);
    bool sawA = false, sawHidden = false;
    for (auto& e : list.result["entries"]) {
        sawA = sawA || e["path"] == "scripts/a.js";
        sawHidden = sawHidden || e["path"].get<std::string>().find(".factoria") == 0;
    }
    CHECK(sawA);
    CHECK_FALSE(sawHidden);

    auto read = f.reg.call("fs.read", {{"path", "scripts/a.js"}, {"startLine", 2}, {"endLine", 2}});
    REQUIRE(read.ok);
    CHECK(read.result["content"] == "const jump = 600;\n");
    CHECK(read.result["totalLines"] == 3);
    CHECK(f.reg.call("fs.read", {{"path", "bin.dat"}}).error["code"] == "binary_file");
    CHECK(f.reg.call("fs.read", {{"path", "missing.js"}}).error["code"] == "not_found");

    auto w = f.reg.call("fs.write", {{"path", "scenes/new.scene.json"}, {"content", "{bad"}});
    REQUIRE(w.ok);
    CHECK(w.result.contains("warning"));
    CHECK(stdfs::exists(f.tmp.path / "scenes/new.scene.json"));
    CHECK_FALSE(f.reg.call("fs.write", {{"path", "scenes/new.scene.json"}, {"content", "{}"}, {"overwrite", false}}).ok);
    CHECK_FALSE(f.reg.call("fs.write", {{"path", ".factoria/x"}, {"content", "x"}}).ok);

    // edit: unique, ambiguous, missing
    CHECK(f.reg.call("fs.edit", {{"path", "scripts/a.js"}, {"find", "speed = 300"}, {"replace", "speed = 360"}}).ok);
    CHECK(testing::read_all(f.tmp.path / "scripts/a.js").find("speed = 360") != std::string::npos);
    auto amb = f.reg.call("fs.edit", {{"path", "dup.txt"}, {"find", "x = 1"}, {"replace", "x = 2"}});
    REQUIRE_FALSE(amb.ok);
    CHECK(amb.error["code"] == "ambiguous");
    CHECK(amb.error["message"].get<std::string>().find("lines 1, 2") != std::string::npos);
    CHECK(testing::read_all(f.tmp.path / "dup.txt") == "x = 1\nx = 1\n");
    CHECK(f.reg.call("fs.edit", {{"path", "dup.txt"}, {"find", "x = 1"}, {"replace", "x = 2"}, {"replaceAll", true}}).result["replacements"] == 2);
    CHECK(f.reg.call("fs.edit", {{"path", "dup.txt"}, {"find", "nope"}, {"replace", "y"}}).error["code"] == "no_match");

    CHECK_FALSE(f.reg.call("fs.delete", {{"path", "scripts"}}).ok);  // needs recursive
    CHECK(f.reg.call("fs.delete", {{"path", "scripts"}, {"recursive", true}}).ok);
    CHECK_FALSE(stdfs::exists(f.tmp.path / "scripts"));
}

TEST_CASE("fs: search skips binary and .factoria, supports regex") {
    FsFixture f;
    auto r = f.reg.call("fs.search", {{"query", "needle"}});
    REQUIRE(r.ok);
    CHECK(r.result["count"] == 0);  // only in binary + .factoria
    auto s = f.reg.call("fs.search", {{"query", "CONST \\w+ = \\d+"}, {"regex", true}});
    REQUIRE(s.ok);
    CHECK(s.result["count"] == 2);
    CHECK(s.result["matches"][0]["path"] == "scripts/a.js");
    CHECK(s.result["matches"][0]["line"] == 1);
    CHECK(f.reg.call("fs.search", {{"query", "CONST"}, {"caseSensitive", true}}).result["count"] == 0);
    CHECK_FALSE(f.reg.call("fs.search", {{"query", "(["}, {"regex", true}}).ok);
    CHECK(f.reg.call("fs.search", {{"query", "speed"}, {"glob", "**/*.js"}}).result["count"] == 1);
    CHECK(f.reg.call("fs.search", {{"query", "speed"}, {"glob", "*.txt"}}).result["count"] == 0);
}

TEST_CASE("fs: .factoria is managed by the tools, .factoria/tmp is the scratch folder (write, edit, list, search, delete)") {
    FsFixture f;
    // Managed files (screenshots, saves...) cannot be written, edited or deleted, and the error names the allowed place.
    for (const char* managed : {".factoria/log.txt", ".factoria/save/slot1.json", ".factoria/screenshots/frame_1.png", ".git/config"}) {
        CAPTURE(managed);
        auto w = f.reg.call("fs.write", {{"path", managed}, {"content", "x"}});
        REQUIRE_FALSE(w.ok);
        CHECK(w.error["hint"].get<std::string>().find(".factoria/tmp/") != std::string::npos);
        CHECK(w.error["message"].get<std::string>().find(managed) != std::string::npos);
        CHECK_FALSE(f.reg.call("fs.edit", {{"path", managed}, {"find", "needle"}, {"replace", "y"}}).ok);
        auto d = f.reg.call("fs.delete", {{"path", managed}});
        REQUIRE_FALSE(d.ok);
        CHECK(d.error["hint"].get<std::string>().find(".factoria/tmp/") != std::string::npos);
    }
    CHECK(testing::read_all(f.tmp.path / ".factoria/log.txt") == "secret needle");  // untouched
    CHECK_FALSE(f.reg.call("fs.delete", {{"path", ".factoria"}, {"recursive", true}}).ok);
    CHECK(stdfs::exists(f.tmp.path / ".factoria/log.txt"));
    CHECK_FALSE(f.reg.call("fs.delete", {{"path", ".factoria/save"}, {"recursive", true}}).ok);

    // The scratch folder may be created, rewritten, listed, searched and deleted with the same commands.
    auto w = f.reg.call("fs.write", {{"path", ".factoria/tmp/gen/base.scene.json"}, {"content", "{\"scratch\": \"needle\"}"}});
    REQUIRE_MESSAGE(w.ok, w.error.dump());
    CHECK(stdfs::exists(f.tmp.path / ".factoria/tmp/gen/base.scene.json"));
    CHECK(f.reg.call("fs.edit", {{"path", ".factoria/tmp/gen/base.scene.json"}, {"find", "scratch"}, {"replace", "tmp"}}).ok);
    CHECK(testing::read_all(f.tmp.path / ".factoria/tmp/gen/base.scene.json").find("\"tmp\"") != std::string::npos);
    auto list = f.reg.call("fs.list", {{"path", ".factoria/tmp"}, {"recursive", true}});
    REQUIRE(list.ok);
    CHECK(list.result["count"] == 2);  // gen/ and gen/base.scene.json
    CHECK(list.result["entries"][1]["path"] == ".factoria/tmp/gen/base.scene.json");
    auto root = f.reg.call("fs.list", {{"recursive", true}});  // the project listing still hides .factoria
    for (auto& e : root.result["entries"]) CHECK(e["path"].get<std::string>().find(".factoria") == std::string::npos);
    CHECK(f.reg.call("fs.search", {{"query", "needle"}, {"path", ".factoria/tmp"}}).result["count"] == 1);
    CHECK(f.reg.call("fs.search", {{"query", "needle"}}).result["count"] == 0);  // not found from the root: hidden there
    CHECK(f.reg.call("fs.delete", {{"path", ".factoria/tmp/gen/base.scene.json"}}).ok);
    CHECK_FALSE(stdfs::exists(f.tmp.path / ".factoria/tmp/gen/base.scene.json"));
    CHECK(f.reg.call("fs.delete", {{"path", ".factoria/tmp"}, {"recursive", true}}).ok);
    CHECK_FALSE(stdfs::exists(f.tmp.path / ".factoria/tmp"));
    CHECK(stdfs::exists(f.tmp.path / ".factoria/log.txt"));  // the rest of .factoria is still there

    // The descriptions say so, because they are what AIs read.
    for (const char* name : {"fs.write", "fs.edit", "fs.delete"}) {
        const CommandInfo* info = f.reg.info(name);
        REQUIRE(info != nullptr);
        CHECK_MESSAGE(info->description.find(".factoria/tmp") != std::string::npos, name);
    }
}

TEST_CASE("docs: list, read and search the bundled documentation") {
    auto docs = list_docs();
    REQUIRE_FALSE(docs.empty());
    bool arch = false, script = false;
    for (auto& d : docs) {
        arch = arch || d.name == "architecture";
        script = script || d.name == "scripting";
        CHECK(d.path.rfind("docs/", 0) == 0);
    }
    CHECK(arch);
    CHECK(script);

    auto r = read_doc("scripting");
    REQUIRE(r.ok());
    CHECK(r->find("Behaviour") != std::string::npos);
    CHECK(read_doc("docs/SCRIPTING.md").ok());
    CHECK(read_doc("SCRIPTING.md").ok());
    auto bad = read_doc("scriptng");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("scripting") != std::string::npos);

    auto hits = search_docs("fixed step deterministic headless");
    REQUIRE_FALSE(hits.empty());
    CHECK_FALSE(hits[0].snippet.empty());
    CHECK(hits[0].line > 0);
    auto hits2 = search_docs("onTriggerEnter");
    REQUIRE_FALSE(hits2.empty());
    // Ranking depends on doc content; only require the reference doc to be among the hits.
    bool scriptingHit = false;
    for (const auto& h : hits2) scriptingHit = scriptingHit || h.doc == "scripting";
    CHECK(scriptingHit);
    CHECK(search_docs("zzzqqqxxx").empty());
    CHECK(search_docs("").empty());
}

TEST_CASE("docs: search puts each doc's best section first, so the top is not one guide") {
    const auto hits = search_docs("onTriggerEnter", 100);
    std::set<std::string> docs;
    for (const auto& h : hits) docs.insert(h.doc);
    REQUIRE(docs.size() >= 3);
    std::set<std::string> top;
    for (size_t i = 0; i < docs.size(); ++i) CHECK(top.insert(hits[i].doc).second);  // the first N hits: N distinct docs
    for (size_t i = 1; i < docs.size(); ++i) CHECK(hits[i - 1].score >= hits[i].score);
}

TEST_CASE("docs: commands") {
    CommandRegistry reg;
    register_docs_commands(reg);
    register_api_export_commands(reg);
    auto list = reg.call("docs.list");
    REQUIRE(list.ok);
    CHECK(list.result["docs"].size() >= 2);
    auto read = reg.call("docs.read", {{"name", "architecture"}, {"maxLines", 5}});
    REQUIRE(read.ok);
    CHECK(read.result["truncated"] == true);
    CHECK(read.result["endLine"] == 5);
    CHECK_FALSE(reg.call("docs.read", {{"name", "nope-nope"}}).ok);
    auto search = reg.call("docs.search", {{"query", "ENGINE_FEEDBACK"}});
    REQUIRE(search.ok);
    CHECK(search.result["count"] >= 1);
    auto cmds = reg.call("docs.commands");
    REQUIRE(cmds.ok);
    CHECK(cmds.result["markdown"].get<std::string>().find("docs.search") != std::string::npos);
}

TEST_CASE("api export: markdown for components and commands") {
    std::string comps = export_components_markdown();
    CHECK(comps.find("# Components reference") != std::string::npos);
    CHECK(comps.find("Sprite") != std::string::npos);
    CommandRegistry reg;
    register_docs_commands(reg);
    std::string md = export_commands_markdown(reg);
    CHECK(md.find("### `docs.read`") != std::string::npos);
    CHECK(md.find("| `name` |") != std::string::npos);
    CHECK(export_commands_json(reg).size() == 3);
}

TEST_CASE("docs.read: the default result fits an MCP tool result, a cut read ends with contents and the call that continues") {
    CommandRegistry reg;
    register_docs_commands(reg);
    register_api_export_commands(reg);
    for (const char* doc : {"ai-guide", "components", "licenses"}) {
        CAPTURE(doc);
        auto r = reg.call("docs.read", {{"name", doc}});
        REQUIRE(r.ok);
        CHECK(r.result.dump().size() < 70000);  // far under 25k tokens
        REQUIRE(r.result["truncated"] == true);
        CHECK(r.result["content"].get<std::string>().size() <= 40000);
        const std::string contents = r.result["contents"].get<std::string>();
        if (std::string(doc) != "licenses") CHECK(contents.find("(line ") != std::string::npos);  // that page has no headings
        CHECK(contents.size() <= 8000);
        CHECK(r.result["next"].get<std::string>().find("docs.read") != std::string::npos);
        // Continuing with nextStartLine leaves no gap and no overlap.
        auto more = reg.call("docs.read", {{"name", doc}, {"startLine", r.result["nextStartLine"]}});
        REQUIRE(more.ok);
        CHECK(more.result["startLine"] == r.result["endLine"].get<long>() + 1);
    }
    // maxBytes is respected (down to one line at least).
    auto small = reg.call("docs.read", {{"name", "ai-guide"}, {"maxBytes", 2000}});
    REQUIRE(small.ok);
    CHECK(small.result["content"].get<std::string>().size() <= 2000);
    // A small page is returned whole, with no contents.
    auto whole = reg.call("docs.read", {{"name", "ai-guide"}, {"startLine", 10}, {"maxLines", 3}});
    REQUIRE(whole.ok);
    CHECK(whole.result["endLine"] == 12);
}

TEST_CASE("docs.read: a section is read by heading, exact title first, several matches are listed") {
    CommandRegistry reg;
    register_docs_commands(reg);
    auto r = reg.call("docs.read", {{"name", "ai-guide"}, {"heading", "9.1 platformer character"}});
    REQUIRE(r.ok);
    const std::string content = r.result["content"].get<std::string>();
    CHECK(content.rfind("### 9.1 Platformer character", 0) == 0);
    CHECK(content.find("9.2 Top-down movement") == std::string::npos);  // stops at the next heading of its level
    CHECK(r.result["truncated"] == false);
    auto partial = reg.call("docs.read", {{"name", "ai-guide"}, {"heading", "Top-down movement"}});
    REQUIRE(partial.ok);
    CHECK(partial.result["heading"] == "9.2 Top-down movement");
    auto many = reg.call("docs.read", {{"name", "ai-guide"}, {"heading", "9."}});
    REQUIRE_FALSE(many.ok);
    CHECK(many.error["message"].get<std::string>().find("matches") != std::string::npos);
    auto none = reg.call("docs.read", {{"name", "ai-guide"}, {"heading", "Platformr character"}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["message"].get<std::string>().find("Did you mean") != std::string::npos);
}

TEST_CASE("docs.components and docs.commands: the default lists names, name gives one in full, filter narrows, full is everything") {
    CommandRegistry reg;
    register_docs_commands(reg);
    register_api_export_commands(reg);
    auto list = reg.call("docs.components");
    REQUIRE(list.ok);
    const std::string md = list.result["markdown"].get<std::string>();
    CHECK(md.size() < 40000);
    CHECK(md.find("- `Sprite`: ") != std::string::npos);
    CHECK(md.find("docs.components {\"name\":") != std::string::npos);
    auto one = reg.call("docs.components", {{"name", "sprite"}});
    REQUIRE(one.ok);
    CHECK(one.result["markdown"].get<std::string>().find("| Field | Type | Default | Description |") != std::string::npos);
    auto bad = reg.call("docs.components", {{"name", "Spritee"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("Did you mean 'Sprite'") != std::string::npos);
    auto filtered = reg.call("docs.components", {{"filter", "sprite"}});
    REQUIRE(filtered.ok);
    CHECK(filtered.result["markdown"].get<std::string>().size() < md.size());
    auto full = reg.call("docs.components", {{"full", true}});
    REQUIRE(full.ok);
    CHECK(full.result["markdown"].get<std::string>().size() > 100000);
    auto json = reg.call("docs.components", {{"format", "json"}});
    REQUIRE(json.ok);
    CHECK(json.result.dump().size() < 40000);

    auto cmds = reg.call("docs.commands");
    REQUIRE(cmds.ok);
    CHECK(cmds.result["markdown"].get<std::string>().size() < 40000);
    auto cmd = reg.call("docs.commands", {{"name", "docs.read"}});
    REQUIRE(cmd.ok);
    CHECK(cmd.result["markdown"].get<std::string>().find("| `maxBytes` |") != std::string::npos);
    CHECK_FALSE(reg.call("docs.commands", {{"name", "docs.reed"}}).ok);
}
