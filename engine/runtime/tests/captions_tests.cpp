// Captions through the whole engine: the caption list (lifetime with a sound, seconds, maxLines, a language change), the
// ui.caption command and the Captions component that receives the lines.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Captions Test",
  "id": "com.example.captions",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "localization": { "defaultLanguage": "en", "languages": ["en", "es"] }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "subtitles", "components": { "Captions": { "maxLines": 2 } } }
  ]
})";

const char* kSceneWithout = R"({
  "format": "factoria.scene/1",
  "entities": [ { "id": "cam", "components": { "Camera": {} } } ]
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const char* scene = kScene) {
        dir = fs::make_temp_dir("fa_captions_test_" + name);
        write("factoria.json", kProject);
        write("scenes/main.scene.json", scene);
        write("locales/en.json", R"({ "$name": "English", "intro": "Welcome" })");
        write("locales/es.json", R"({ "$name": "Español", "intro": "Bienvenido" })");
        // 0.5 s of silence, 16-bit mono PCM at 44.1 kHz
        const std::uint32_t n = 22050;
        std::string b;
        auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
        auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
        b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
        b += "data"; u32(n * 2);
        b.append(std::size_t(n) * 2, '\0');
        write("assets/sfx/line.wav", b);
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        return c;
    }
};

Json eval(Engine& e, const std::string& code) {
    auto r = e.commands().call("script.eval", Json::object({{"code", code}}));
    INFO(code << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

// The lines the Captions entity draws now.
Json drawn(Engine& e) {
    Json out = Json::array();
    e.world().each<Captions>([&](Entity, Captions& c) { out = c.lines; });
    return out;
}

}  // namespace

TEST_CASE("captions: a sound's caption lives as long as the sound plays") {
    TempProject p("sound");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e, "audio.play('assets/sfx/line.wav', { caption: 'Hello there', speaker: 'Mara' })");
    e.step(1);
    REQUIRE(e.captions().size() == 1);
    CHECK(e.captions().lines()[0].source == "audio:assets/sfx/line.wav");
    REQUIRE(drawn(e).size() == 1);
    CHECK(drawn(e)[0]["text"] == "Hello there");
    CHECK(drawn(e)[0]["speaker"] == "Mara");
    e.step(15);  // 0.25 s of a 0.5 s sound
    CHECK(e.captions().size() == 1);
    e.step(30);  // past its end
    CHECK(e.captions().size() == 0);
    CHECK(drawn(e).empty());
    e.shutdown();
}

TEST_CASE("captions: audio.stop and stopAll end the caption at once; a looping sound needs captionSeconds") {
    TempProject p("stop");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e, "globalThis.v = audio.play('assets/sfx/line.wav', { caption: 'one' })");
    e.step(1);
    CHECK(e.captions().size() == 1);
    eval(e, "audio.stop(globalThis.v)");
    CHECK(e.captions().size() == 0);
    eval(e, "audio.play('assets/sfx/line.wav', { caption: 'two' }); ui.caption('free line', 5)");
    eval(e, "audio.stopAll()");
    REQUIRE(e.captions().size() == 1);  // only the line that was not tied to a sound stays
    CHECK(e.captions().lines()[0].text == "free line");
    auto r = e.commands().call("script.eval", Json::object({{"code", "audio.play('assets/sfx/line.wav', { loop: true, caption: 'x' })"}}));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("captionSeconds") != std::string::npos);
    eval(e, "audio.play('assets/sfx/line.wav', { loop: true, caption: 'bed', captionSeconds: 0.25 })");
    CHECK(e.captions().size() == 2);
    e.step(30);  // 0.5 s: the looping sound still plays, its caption is gone
    REQUIRE(e.captions().size() == 1);
    CHECK(e.captions().lines()[0].text == "free line");
    e.shutdown();
}

TEST_CASE("captions: ui.caption runs for its seconds of the engine clock, and ui.clear_captions removes them") {
    TempProject p("seconds");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto r = e.commands().call("ui.caption", Json::parse(R"({"text":"Watch out!","seconds":0.5,"speaker":"Mara"})"));
    REQUIRE(r.ok);
    e.step(20);
    CHECK(e.captions().size() == 1);
    e.step(20);  // 0.67 s in
    CHECK(e.captions().size() == 0);
    REQUIRE(e.commands().call("ui.caption", Json::parse(R"({"text":"again","seconds":10})")).ok);
    e.step(2);
    CHECK(e.captions().size() == 1);
    REQUIRE(e.commands().call("ui.clear_captions", Json::object()).ok);
    CHECK(e.captions().size() == 0);
    r = e.commands().call("ui.caption", Json::parse(R"({"seconds":1})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}

TEST_CASE("captions: the component draws the newest maxLines, the list keeps all of them") {
    TempProject p("maxlines");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e, "ui.caption('one', 5); ui.caption('two', 5); ui.caption('three', 5)");
    e.step(1);
    CHECK(e.captions().size() == 3);
    const Json lines = drawn(e);
    REQUIRE(lines.size() == 2);
    CHECK(lines[0]["text"] == "two");
    CHECK(lines[1]["text"] == "three");
    e.shutdown();
}

TEST_CASE("captions: a caption key follows the language while it shows") {
    TempProject p("language");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e, "audio.play('assets/sfx/line.wav', { captionKey: 'intro', speaker: 'Mara' })");
    eval(e, "ui.caption('', 5, { key: 'intro' })");
    e.step(1);
    REQUIRE(e.captions().size() == 2);
    CHECK(e.captions().lines()[0].text == "Welcome");
    CHECK(e.captions().lines()[0].key == "intro");
    eval(e, "i18n.setLanguage('es')");
    CHECK(e.captions().lines()[0].text == "Bienvenido");
    CHECK(e.captions().lines()[1].text == "Bienvenido");
    e.step(1);
    REQUIRE(drawn(e).size() == 2);
    CHECK(drawn(e)[0]["text"] == "Bienvenido");
    e.shutdown();
}

TEST_CASE("captions: without a Captions entity captions are tracked but nothing receives them") {
    TempProject p("none", kSceneWithout);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e, "ui.caption('quiet', 5)");
    e.step(2);
    CHECK(e.captions().size() == 1);
    CHECK(drawn(e).empty());
    e.shutdown();
}
