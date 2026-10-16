// The AI-generated content disclosure: fa/tooling/ai_disclosure.h.
#include <doctest.h>

#include "fa/tooling/ai_disclosure.h"

using namespace fa;

namespace {

const char* kManifest = R"({
  "format": "factoria.assets/1",
  "assets": {
    "assets/hero.png": {"provenance": {"origin": "generated", "ai": true, "kind": "image", "provider": "openai", "model": "gpt-image-1",
                                       "license": "OpenAI terms", "date": "2026-10-01"}},
    "assets/tiles.png": {"provenance": {"origin": "generated", "ai": true, "provider": "openai", "model": "gpt-image-1", "date": "2026-10-02"}},
    "assets/sfx/door.mp3": {"provenance": {"origin": "generated", "ai": true, "kind": "sound", "provider": "elevenlabs", "date": "2026-10-03"}},
    "assets/music/theme.mp3": {"provenance": {"origin": "generated", "ai": true, "kind": "music", "provider": "elevenlabs", "date": "2026-10-03"}},
    "assets/voice/hi.mp3": {"provenance": {"origin": "generated", "ai": true, "kind": "voice", "provider": "elevenlabs", "date": "2026-10-04"}},
    "assets/crate.glb": {"provenance": {"origin": "generated", "ai": true, "provider": "meshy", "date": "2026-10-05"}},
    "assets/step.wav": {"provenance": {"origin": "generated", "ai": true, "provider": "suno", "date": "2026-10-05"}},
    "assets/bought.png": {"provenance": {"origin": "imported", "ai": false, "date": "2026-10-06"}},
    "assets/gone.png": {"provenance": {"origin": "generated", "ai": true, "provider": "openai", "date": "2026-10-06"}},
    "assets/levels.png": {"import": {"compression": "none"}}
  }
})";

const std::vector<std::string> kFiles = {"assets/hero.png", "assets/tiles.png", "assets/sfx/door.mp3", "assets/music/theme.mp3",
                                         "assets/voice/hi.mp3", "assets/crate.glb", "assets/step.wav", "assets/bought.png",
                                         "assets/levels.png", "assets/orphan.ogg", "assets/notes.txt", "scripts/main.js", "assets.json"};

}  // namespace

TEST_CASE("has_ai_content: any record with ai true") {
    CHECK(has_ai_content(Json::parse(kManifest)));
    CHECK_FALSE(has_ai_content(Json::parse(R"({"format":"factoria.assets/1"})")));
    CHECK_FALSE(has_ai_content(Json::parse(R"({"assets":{"assets/a.png":{"provenance":{"origin":"original","ai":false,"date":"2026-10-01"}}}})")));
    CHECK_FALSE(has_ai_content(Json::parse(R"({"assets":{"assets/a.png":{"provenance":{"origin":"original","date":"2026-10-01"}}}})")));
    CHECK_FALSE(has_ai_content(Json()));
}

TEST_CASE("ai_content_disclosure: categories with counts, providers and models") {
    const std::string md = ai_content_disclosure(Json::parse(kManifest), kFiles);
    CHECK(md.find("7 assets were made with AI tools.") != std::string::npos);  // gone.png is not in the project
    CHECK(md.find("| Art and images | 2 | openai (gpt-image-1) |") != std::string::npos);
    CHECK(md.find("| Sound effects | 1 | elevenlabs |") != std::string::npos);
    CHECK(md.find("| Music | 1 | elevenlabs |") != std::string::npos);
    CHECK(md.find("| Voice | 1 | elevenlabs |") != std::string::npos);
    CHECK(md.find("| 3D models | 1 | meshy |") != std::string::npos);
    CHECK(md.find("| Audio (sound effect, music or voice not recorded) | 1 | suno |") != std::string::npos);  // no kind, a .wav
    CHECK(md.find("- `assets/hero.png`: Art and images, openai (gpt-image-1), 2026-10-01") != std::string::npos);
    CHECK(md.find("assets/bought.png") == std::string::npos);  // made without AI
    CHECK(md.find("assets/gone.png") == std::string::npos);
    CHECK(md.find("- openai: OpenAI terms (1 asset)") != std::string::npos);
    CHECK(md.find("## Live-generated content") != std::string::npos);
    CHECK(md.find("None. The FactorIA engine generates no content at run time") != std::string::npos);
}

TEST_CASE("ai_content_disclosure: the files without a provenance record are listed") {
    const std::string md = ai_content_disclosure(Json::parse(kManifest), kFiles);
    const std::size_t at = md.find("## Assets without provenance");
    REQUIRE(at != std::string::npos);
    const std::string tail = md.substr(at);
    CHECK(tail.find("- `assets/levels.png`") != std::string::npos);  // has an entry, but only import settings
    CHECK(tail.find("- `assets/orphan.ogg`") != std::string::npos);
    CHECK(tail.find("notes.txt") == std::string::npos);  // not an art, sound or model file
    CHECK(tail.find("main.js") == std::string::npos);
    CHECK(assets_without_provenance(Json::parse(kManifest), kFiles) == std::vector<std::string>{"assets/levels.png", "assets/orphan.ogg"});

    const std::string clean = ai_content_disclosure(Json::parse(R"({"assets":{"assets/a.png":{"provenance":{"origin":"original","date":"2026-10-01"}}}})"),
                                                    {"assets/a.png"});
    CHECK(clean.find("None of the assets is recorded as made with AI.") != std::string::npos);
    CHECK(clean.find("Every art, sound and model file under assets/ has a provenance record.") != std::string::npos);
    CHECK(clean.find("## Terms recorded") == std::string::npos);
}
