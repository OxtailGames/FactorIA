// assets.* commands with the fake provider: images, sprite sheets, sounds, models, the style of assets.json, provenance and the
// store disclosure. (The real providers through recorded answers: test_asset_providers.cpp.)
#include <cgltf.h>

#include "asset_test.h"
#include "fa/core/asset_manifest.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

TEST_CASE("assets.generate_image with the fake provider writes the PNG and its provenance") {
    Game game(fake_config());
    auto r = game.call("assets.generate_image",
                       {{"prompt", "a red potion bottle"}, {"path", "assets/items/potion.png"}, {"width", 48}, {"height", 32}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());

    // the file: a PNG of the size that was asked for
    const Image img = decode_png(game.file("assets/items/potion.png"));
    CHECK(img.width == 48);
    CHECK(img.height == 32);
    CHECK(r.result["width"] == 48);
    CHECK(r.result["height"] == 32);
    CHECK(r.result["bytes"] == game.file("assets/items/potion.png").size());
    CHECK(r.result["$image"]["mimeType"] == "image/png");
    CHECK(std::filesystem::path(r.result["$image"]["path"].get<std::string>()) == std::filesystem::absolute(game.dir.path / "assets/items/potion.png"));

    // the record in assets.json
    const Json prov = game.provenance("assets/items/potion.png");
    CHECK(prov["origin"] == "generated");
    CHECK(prov["ai"] == true);
    CHECK(prov["kind"] == "image");
    CHECK(prov["provider"] == "fake");
    CHECK(prov["prompt"] == "a red potion bottle");
    CHECK(prov["author"] == "factoria");
    CHECK(prov["date"] == assets::today());
    CHECK_FALSE(prov["license"].get<std::string>().empty());
    CHECK(r.result["provenance"] == prov);
    CHECK(game.manifest()["format"] == "factoria.assets/1");
}

TEST_CASE("assets.generate_image: transparent background, determinism and overwrite") {
    Game game(fake_config());
    game.ok("assets.generate_image", {{"prompt", "a gem"}, {"path", "assets/gem.png"}, {"width", 32}, {"height", 32}, {"transparent", true}});
    const std::string first = game.file("assets/gem.png");
    const Image gem = decode_png(first);
    CHECK(gem.rgba[3] == 0);  // the corner of a transparent image
    bool someOpaque = false;
    for (std::size_t i = 3; i < gem.rgba.size(); i += 4) someOpaque = someOpaque || gem.rgba[i] == 255;
    CHECK(someOpaque);

    // a second call on the same path is refused, the file stays
    auto again = game.call("assets.generate_image", {{"prompt", "a gem"}, {"path", "assets/gem.png"}, {"width", 32}, {"height", 32}, {"transparent", true}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    CHECK(again.error["hint"].get<std::string>().find("overwrite") != std::string::npos);
    CHECK(game.file("assets/gem.png") == first);

    // the same request gives the same picture, another prompt another one
    game.ok("assets.generate_image", {{"prompt", "a gem"}, {"path", "assets/gem.png"}, {"width", 32}, {"height", 32}, {"transparent", true}, {"overwrite", true}});
    CHECK(game.file("assets/gem.png") == first);
    game.ok("assets.generate_image", {{"prompt", "a ruby"}, {"path", "assets/gem.png"}, {"width", 32}, {"height", 32}, {"transparent", true}, {"overwrite", true}});
    CHECK(game.file("assets/gem.png") != first);
    CHECK(game.provenance("assets/gem.png")["prompt"] == "a ruby");
}

TEST_CASE("assets.generate_image: wrong paths and missing configuration teach") {
    Game game(fake_config());
    auto outside = game.call("assets.generate_image", {{"prompt", "x"}, {"path", "scenes/x.png"}});
    REQUIRE_FALSE(outside.ok);
    CHECK(outside.error["code"] == "invalid_path");
    CHECK(outside.error["hint"].get<std::string>().find("assets/") != std::string::npos);
    CHECK_FALSE(game.exists("scenes/x.png"));

    auto escaping = game.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/../../x.png"}});
    REQUIRE_FALSE(escaping.ok);
    CHECK(escaping.error["code"] == "invalid_path");

    auto jpg = game.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/a.jpg"}});
    REQUIRE_FALSE(jpg.ok);
    CHECK(jpg.error["code"] == "wrong_extension");
    CHECK(jpg.error["hint"] == "Use 'assets/a.png'.");

    auto blank = game.call("assets.generate_image", {{"prompt", "  "}, {"path", "assets/a.png"}});
    REQUIRE_FALSE(blank.ok);
    CHECK(blank.error["code"] == "invalid_argument");

    auto tiny = game.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/a.png"}, {"width", 2}});
    CHECK_FALSE(tiny.ok);  // the schema: at least 8 pixels

    CHECK_FALSE(game.exists("assets.json"));  // nothing was recorded

    // no "assets" in ai.json: no default provider, the error shows what to add
    Game unconfigured(default_config());
    auto none = unconfigured.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/a.png"}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["code"] == "no_provider");
    CHECK(none.error["message"] == "No provider is configured for image generation");
    const std::string hint = none.error["hint"];
    CHECK(hint.find("\"assets\": {\"image\":") != std::string::npos);
    CHECK(hint.find("\"fake\"") != std::string::npos);
    // ... or pass the provider
    auto viaArg = unconfigured.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/a.png"}, {"provider", "fake"}});
    CHECK(viaArg.ok);

    auto typo = unconfigured.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/b.png"}, {"provider", "fak"}});
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["message"].get<std::string>().find("Unknown asset provider 'fak'") != std::string::npos);
    CHECK(typo.error["hint"].get<std::string>().find("fake") != std::string::npos);

    auto wrongKind = unconfigured.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/b.png"}, {"provider", "meshy"}});
    REQUIRE_FALSE(wrongKind.ok);
    CHECK(wrongKind.error["message"].get<std::string>().find("cannot generate image") != std::string::npos);
}

TEST_CASE("assets.generate_image: no project folder") {
    AiCommandOptions opt;
    opt.loadConfig = [] { return Result<AiConfig>(fake_config()); };
    opt.projectDir = [] { return std::string(); };
    CommandRegistry registry;
    register_ai_commands(registry, opt);
    auto r = registry.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/a.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "no_project");
}

TEST_CASE("the style of assets.json: prompt, references and palette lock") {
    Game game(fake_config());
    game.put("assets/ref.png", png_bytes(8, 8, 200, 30, 30));
    game.put("assets.json", R"({"format":"factoria.assets/1","style":{"prompt":"16-bit pixel art, black outline",
        "palette":["#101010","#f0f0f0","#c03030"],"references":["assets/ref.png"]}})");

    game.ok("assets.generate_image", {{"prompt", "a potion"}, {"path", "assets/potion.png"}, {"width", 32}, {"height", 32}});
    const Json prov = game.provenance("assets/potion.png");
    CHECK(prov["prompt"] == "a potion\n\nStyle: 16-bit pixel art, black outline");
    CHECK(prov["references"] == Json::array({"assets/ref.png"}));
    CHECK(prov["notes"].get<std::string>().find("3 colours of the style palette") != std::string::npos);
    const auto locked = colours_of(decode_png(game.file("assets/potion.png")));
    CHECK(locked.size() <= 3);
    for (std::uint32_t c : locked) CHECK((c == 0x101010 || c == 0xf0f0f0 || c == 0xc03030));
    CHECK(game.manifest()["style"]["prompt"] == "16-bit pixel art, black outline");  // the style is left as it was

    // style:false skips all of it
    game.ok("assets.generate_image", {{"prompt", "a potion"}, {"path", "assets/free.png"}, {"width", 32}, {"height", 32}, {"style", false}});
    const Json free = game.provenance("assets/free.png");
    CHECK(free["prompt"] == "a potion");
    CHECK_FALSE(free.contains("references"));
    CHECK(colours_of(decode_png(game.file("assets/free.png"))).size() > 3);

    // references of the call and of the style are both sent, once each
    game.ok("assets.generate_image", {{"prompt", "a potion"}, {"path", "assets/two.png"}, {"width", 16}, {"height", 16},
                                      {"references", Json::array({"assets/ref.png", "assets/potion.png"})}});
    CHECK(game.provenance("assets/two.png")["references"] == Json::array({"assets/ref.png", "assets/potion.png"}));

    auto missing = game.call("assets.generate_image", {{"prompt", "x"}, {"path", "assets/m.png"}, {"references", Json::array({"assets/nope.png"})}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "not_found");
    CHECK_FALSE(game.exists("assets/m.png"));
}

TEST_CASE("the palette can be an image; a palette of more than 256 colours is refused before anything is paid for") {
    Game game(fake_config());
    Image swatches;
    swatches.width = 3;
    swatches.height = 1;
    swatches.rgba = {255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255};
    const auto swatchPng = encode_png(swatches);
    game.put("assets/palette.png", std::string(swatchPng.begin(), swatchPng.end()));
    game.put("assets.json", R"({"format":"factoria.assets/1","style":{"palette":"assets/palette.png"}})");
    game.ok("assets.generate_image", {{"prompt", "a flag"}, {"path", "assets/flag.png"}, {"width", 24}, {"height", 24}});
    for (std::uint32_t c : colours_of(decode_png(game.file("assets/flag.png")))) CHECK((c == 0xff0000 || c == 0x00ff00 || c == 0x0000ff));

    Image many;
    many.width = 20;
    many.height = 20;
    for (int i = 0; i < 400; ++i) many.rgba.insert(many.rgba.end(), {std::uint8_t(i % 256), std::uint8_t(i / 256), 7, 255});
    const auto manyPng = encode_png(many);
    game.put("assets/photo.png", std::string(manyPng.begin(), manyPng.end()));
    game.put("assets.json", R"({"format":"factoria.assets/1","style":{"palette":"assets/photo.png"}})");
    auto r = game.call("assets.generate_image", {{"prompt", "a flag"}, {"path", "assets/flag2.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_style");
    CHECK(r.error["message"].get<std::string>().find("256") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("style:false") != std::string::npos);
    CHECK_FALSE(game.exists("assets/flag2.png"));
    CHECK(game.call("assets.generate_image", {{"prompt", "a flag"}, {"path", "assets/flag2.png"}, {"style", false}}).ok);
}

TEST_CASE("assets.generate_sprite_sheet: a grid of different frames, the layout in assets.json, how to play it") {
    Game game(fake_config());
    const Json r = game.ok("assets.generate_sprite_sheet", {{"prompt", "a slime bouncing"}, {"path", "assets/slime.png"}, {"frames", 5},
                                                             {"columns", 3}, {"frameWidth", 32}, {"frameHeight", 24}, {"fps", 10}});
    const Image sheet = decode_png(game.file("assets/slime.png"));
    CHECK(sheet.width == 96);  // 3 columns of 32
    CHECK(sheet.height == 48);  // 2 rows of 24
    CHECK(sheet.rgba[3] == 0);  // sprites are transparent by default

    auto frame_differs = [&](int a, int b) {
        for (int y = 0; y < 24; ++y) {
            for (int x = 0; x < 32; ++x) {
                const Color p = sheet.pixel((a % 3) * 32 + x, (a / 3) * 24 + y), q = sheet.pixel((b % 3) * 32 + x, (b / 3) * 24 + y);
                if (p.r != q.r || p.g != q.g || p.b != q.b || p.a != q.a) return true;
            }
        }
        return false;
    };
    CHECK(frame_differs(0, 1));
    CHECK(frame_differs(1, 2));
    CHECK(frame_differs(3, 4));

    const Json entry = game.manifest()["assets"]["assets/slime.png"];
    CHECK(entry["provenance"]["origin"] == "generated");
    CHECK(entry["provenance"]["prompt"].get<std::string>().find("5 animation frames in a grid of 3 columns by 2 rows") != std::string::npos);
    const Json expectedSheet = Json::parse(R"({"columns":3,"rows":2,"frameWidth":32,"frameHeight":24,"frames":5,
        "clips":[{"name":"default","firstFrame":0,"lastFrame":4,"fps":10}]})");
    CHECK(entry["sheet"] == expectedSheet);
    CHECK(r["setup"]["Sprite"]["texture"] == "assets/slime.png");
    CHECK(r["setup"]["SpriteAnimator"] == Json::parse(R"({"columns":3,"rows":2,"firstFrame":0,"lastFrame":4,"fps":10})"));
    CHECK(r["next"].get<std::string>().find("SpriteAnimator") != std::string::npos);

    // the default grid is the square root of the frames, rounded up
    game.ok("assets.generate_sprite_sheet", {{"prompt", "a coin"}, {"path", "assets/coin.png"}, {"frames", 5}, {"frameWidth", 16}, {"frameHeight", 16}});
    CHECK(game.manifest()["assets"]["assets/coin.png"]["sheet"]["columns"] == 3);
    CHECK(game.manifest()["assets"]["assets/coin.png"]["sheet"]["rows"] == 2);

    // a plain image over a sheet drops the layout
    game.ok("assets.generate_image", {{"prompt", "a coin"}, {"path", "assets/coin.png"}, {"overwrite", true}});
    CHECK_FALSE(game.manifest()["assets"]["assets/coin.png"].contains("sheet"));

    auto huge = game.call("assets.generate_sprite_sheet", {{"prompt", "x"}, {"path", "assets/huge.png"}, {"frames", 4}, {"columns", 4},
                                                            {"frameWidth", 2048}, {"frameHeight", 64}});
    REQUIRE_FALSE(huge.ok);
    CHECK(huge.error["code"] == "too_large");
    auto columns = game.call("assets.generate_sprite_sheet", {{"prompt", "x"}, {"path", "assets/c.png"}, {"frames", 2}, {"columns", 3},
                                                               {"frameWidth", 16}, {"frameHeight", 16}});
    REQUIRE_FALSE(columns.ok);
    CHECK(columns.error["code"] == "invalid_argument");
}

TEST_CASE("assets.generate_sound, music and voice with the fake provider: WAV files with their kind in the provenance") {
    Game game(fake_config());
    auto wav_samples = [&](const std::string& rel) {
        const std::string wav = game.file(rel);
        REQUIRE(wav.size() > 44);
        CHECK(wav.substr(0, 4) == "RIFF");
        CHECK(wav.substr(8, 4) == "WAVE");
        return (wav.size() - 44) / 2;  // mono, 16-bit
    };
    const Json sound = game.ok("assets.generate_sound", {{"prompt", "coin pickup"}, {"path", "assets/sfx/coin.wav"}, {"seconds", 1}});
    const auto soundSamples = wav_samples("assets/sfx/coin.wav");
    game.ok("assets.generate_music", {{"prompt", "calm forest"}, {"path", "assets/music/forest.wav"}, {"seconds", 4}});
    const auto musicSamples = wav_samples("assets/music/forest.wav");
    CHECK(musicSamples == soundSamples * 4);
    const Json voice = game.ok("assets.generate_voice", {{"text", "Welcome, traveller."}, {"path", "assets/voice/welcome.wav"}, {"voice", "narrator"}});
    wav_samples("assets/voice/welcome.wav");

    CHECK(sound["kind"] == "sound");
    CHECK(sound["next"].get<std::string>().find("AudioSource") != std::string::npos);
    CHECK(game.provenance("assets/sfx/coin.wav")["kind"] == "sound");
    CHECK(game.provenance("assets/music/forest.wav")["kind"] == "music");
    const Json voiceProvenance = game.provenance("assets/voice/welcome.wav");
    CHECK(voiceProvenance["kind"] == "voice");
    CHECK(voiceProvenance["prompt"] == "Welcome, traveller.");  // the spoken text
    CHECK(voiceProvenance["notes"] == "Voice: narrator.");
    CHECK(voice["provenance"] == voiceProvenance);

    // the extension has to be the one the provider makes, and that is said before anything is generated
    auto mp3 = game.call("assets.generate_sound", {{"prompt", "coin"}, {"path", "assets/sfx/coin2.mp3"}});
    REQUIRE_FALSE(mp3.ok);
    CHECK(mp3.error["code"] == "wrong_extension");
    CHECK(mp3.error["message"].get<std::string>().find(".wav") != std::string::npos);
    CHECK(mp3.error["hint"] == "Use 'assets/sfx/coin2.wav'.");
    CHECK_FALSE(game.exists("assets/sfx/coin2.mp3"));
    CHECK(game.call("assets.generate_sound", {{"prompt", "coin"}, {"path", "assets/sfx/coin.wav"}}).error["code"] == "exists");
    CHECK_FALSE(game.call("assets.generate_voice", {{"text", ""}, {"path", "assets/voice/none.wav"}}).ok);
}

TEST_CASE("assets.generate_model with the fake provider writes a glTF cube that cgltf parses") {
    Game game(fake_config());
    game.ok("assets.generate_model", {{"prompt", "a wooden crate"}, {"path", "assets/models/crate.gltf"}});
    CHECK(game.provenance("assets/models/crate.gltf")["kind"] == "model3d");

    const std::string gltf = game.file("assets/models/crate.gltf");
    cgltf_options options{};
    cgltf_data* data = nullptr;
    REQUIRE(cgltf_parse(&options, gltf.data(), gltf.size(), &data) == cgltf_result_success);
    CHECK(cgltf_load_buffers(&options, data, nullptr) == cgltf_result_success);  // the buffer is embedded
    CHECK(cgltf_validate(data) == cgltf_result_success);
    REQUIRE(data->meshes_count == 1);
    REQUIRE(data->meshes[0].primitives_count == 1);
    const cgltf_primitive& prim = data->meshes[0].primitives[0];
    CHECK(prim.indices->count == 36);  // 12 triangles
    bool hasPositions = false;
    for (cgltf_size i = 0; i < prim.attributes_count; ++i) {
        if (prim.attributes[i].type == cgltf_attribute_type_position) {
            hasPositions = true;
            CHECK(prim.attributes[i].data->count == 24);
        }
    }
    CHECK(hasPositions);
    cgltf_free(data);

    auto glb = game.call("assets.generate_model", {{"prompt", "a crate"}, {"path", "assets/models/crate2.glb"}});
    REQUIRE_FALSE(glb.ok);
    CHECK(glb.error["code"] == "wrong_extension");
    CHECK(glb.error["hint"] == "Use 'assets/models/crate2.gltf'.");
}

TEST_CASE("assets.provenance and assets.set_provenance") {
    Game game(fake_config());
    game.ok("assets.generate_image", {{"prompt", "a gem"}, {"path", "assets/gem.png"}, {"width", 16}, {"height", 16}});
    game.put("assets/hero.png", png_bytes(8, 8, 1, 2, 3));
    game.put("assets/sfx/step.wav", "RIFF----WAVEfmt ");
    game.put("assets/readme.txt", "not an art, sound or model file");

    const Json all = game.ok("assets.provenance", Json::object());
    CHECK(all["assets"].size() == 1);
    CHECK(all["assets"][0]["path"] == "assets/gem.png");
    CHECK(all["assets"][0]["fileExists"] == true);
    CHECK(all["aiCount"] == 1);
    CHECK(all["withoutProvenance"] == Json::array({"assets/hero.png", "assets/sfx/step.wav"}));

    const Json one = game.ok("assets.provenance", {{"path", "assets/gem.png"}});
    CHECK(one["exists"] == true);
    CHECK(one["provenance"]["provider"] == "fake");
    const Json none = game.ok("assets.provenance", {{"path", "assets/hero.png"}});
    CHECK(none["exists"] == true);
    CHECK(none["provenance"].is_null());

    // hand-made, bought and "made with AI elsewhere" files
    const Json set = game.ok("assets.set_provenance", {{"path", "assets/hero.png"}, {"origin", "original"}, {"author", "Ana"}});
    CHECK(set["provenance"]["ai"] == false);
    CHECK(set["provenance"]["date"] == assets::today());
    game.ok("assets.set_provenance", {{"path", "assets/sfx/step.wav"}, {"origin", "imported"}, {"ai", true}, {"kind", "sound"}, {"provider", "Suno"},
                                      {"license", "Pro plan"}, {"source", "https://example.com/step"}, {"date", "2026-01-31"}, {"seed", 7}});
    const Json step = game.provenance("assets/sfx/step.wav");
    CHECK(step["ai"] == true);
    CHECK(step["date"] == "2026-01-31");
    CHECK(step["seed"] == 7);
    CHECK(step["source"] == "https://example.com/step");
    CHECK(game.ok("assets.provenance", Json::object())["withoutProvenance"].empty());

    // set_provenance replaces the record
    game.ok("assets.set_provenance", {{"path", "assets/sfx/step.wav"}, {"origin", "original"}});
    CHECK(game.provenance("assets/sfx/step.wav") == Json::parse(R"({"origin":"original","ai":false,"date":")" + assets::today() + R"("})"));

    auto missing = game.call("assets.set_provenance", {{"path", "assets/nope.png"}, {"origin", "original"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "not_found");
    auto contradiction = game.call("assets.set_provenance", {{"path", "assets/hero.png"}, {"origin", "generated"}, {"ai", false}});
    REQUIRE_FALSE(contradiction.ok);
    CHECK(contradiction.error["code"] == "invalid_argument");
    CHECK_FALSE(game.call("assets.set_provenance", {{"path", "assets/hero.png"}, {"origin", "found online"}}).ok);  // not one of the origins
    CHECK_FALSE(game.call("assets.set_provenance", {{"path", "assets/hero.png"}, {"origin", "original"}, {"date", "yesterday"}}).ok);
}

TEST_CASE("assets.disclosure answers the store survey from the provenance records") {
    Game game(fake_config());
    game.ok("assets.generate_image", {{"prompt", "a gem"}, {"path", "assets/gem.png"}, {"width", 16}, {"height", 16}});
    game.ok("assets.generate_image", {{"prompt", "a ruby"}, {"path", "assets/ruby.png"}, {"width", 16}, {"height", 16}});
    game.ok("assets.generate_sound", {{"prompt", "coin"}, {"path", "assets/sfx/coin.wav"}});
    game.ok("assets.generate_music", {{"prompt", "forest"}, {"path", "assets/music/forest.wav"}});
    game.ok("assets.generate_voice", {{"text", "Hello"}, {"path", "assets/voice/hello.wav"}});
    game.ok("assets.generate_model", {{"prompt", "crate"}, {"path", "assets/crate.gltf"}});
    game.put("assets/hero.png", png_bytes(8, 8, 1, 2, 3));
    game.ok("assets.set_provenance", {{"path", "assets/hero.png"}, {"origin", "original"}});
    game.put("assets/bought.png", png_bytes(8, 8, 3, 2, 1));
    game.ok("assets.set_provenance", {{"path", "assets/bought.png"}, {"origin", "imported"}, {"ai", false}});
    game.put("assets/unknown.png", png_bytes(8, 8, 9, 9, 9));

    const Json d = game.ok("assets.disclosure", Json::object());
    CHECK(d["hasAiContent"] == true);
    CHECK(d["withoutProvenance"] == Json::array({"assets/unknown.png"}));
    const std::string md = d["markdown"];
    CHECK(md.find("6 assets were made with AI tools.") != std::string::npos);
    CHECK(md.find("| Art and images | 2 | fake |") != std::string::npos);
    CHECK(md.find("| Sound effects | 1 | fake |") != std::string::npos);
    CHECK(md.find("| Music | 1 | fake |") != std::string::npos);
    CHECK(md.find("| Voice | 1 | fake |") != std::string::npos);
    CHECK(md.find("| 3D models | 1 | fake |") != std::string::npos);
    CHECK(md.find("`assets/gem.png`") != std::string::npos);
    CHECK(md.find("`assets/hero.png`") == std::string::npos);  // made by hand: not in the list of AI assets
    CHECK(md.find("## Live-generated content") != std::string::npos);
    CHECK(md.find("None. The FactorIA engine generates no content at run time") != std::string::npos);
    CHECK(md.find("## Assets without provenance") != std::string::npos);
    CHECK(md.find("- `assets/unknown.png`") != std::string::npos);

    // no AI at all
    Game plain(fake_config());
    plain.put("assets/hero.png", png_bytes(8, 8, 1, 2, 3));
    plain.ok("assets.set_provenance", {{"path", "assets/hero.png"}, {"origin", "original"}});
    const Json p = plain.ok("assets.disclosure", Json::object());
    CHECK(p["hasAiContent"] == false);
    CHECK(p["markdown"].get<std::string>().find("None of the assets is recorded as made with AI.") != std::string::npos);
}

TEST_CASE("assets.set_provenance keeps the order of a hand-ordered assets.json and changes one entry") {
    Game game(fake_config());
    game.put("assets/z.png", png_bytes(2, 2, 1, 2, 3));
    game.put("assets/a.png", png_bytes(2, 2, 1, 2, 3));
    game.put("assets/m.png", png_bytes(2, 2, 1, 2, 3));
    game.put("assets.json",
             R"({"format":"factoria.assets/1","assets":{"assets/z.png":{"import":{"compression":"none"}},"assets/a.png":{"import":{"atlas":"ui"}},"assets/m.png":{"import":{"atlas":"hud"}}}})");
    game.ok("assets.set_provenance", {{"path", "assets/a.png"}, {"origin", "original"}});
    const Json m = game.manifest();
    std::vector<std::string> keys;
    for (auto it = m["assets"].begin(); it != m["assets"].end(); ++it) keys.push_back(it.key());
    CHECK(keys == std::vector<std::string>{"assets/z.png", "assets/a.png", "assets/m.png"});
    CHECK(m["assets"]["assets/a.png"]["provenance"]["origin"] == "original");
    CHECK(m["assets"]["assets/a.png"]["import"]["atlas"] == "ui");
    CHECK(m["assets"]["assets/z.png"] == Json::parse(R"({"import":{"compression":"none"}})"));
    CHECK(m["assets"]["assets/m.png"] == Json::parse(R"({"import":{"atlas":"hud"}})"));

    // a new entry goes to the end of a hand-ordered file
    game.put("assets/b.png", png_bytes(2, 2, 1, 2, 3));
    game.ok("assets.set_provenance", {{"path", "assets/b.png"}, {"origin", "original"}});
    CHECK(game.manifest()["assets"].begin().key() == "assets/z.png");
    CHECK((--game.manifest()["assets"].end()).key() == "assets/b.png");
}

TEST_CASE("assets.generate_voice without a provider: the error names the keys, silent:true writes a silent clip of the line's length") {
    Game game(config_from(R"({})"));
    auto none = game.call("assets.generate_voice", {{"text", "Welcome, traveller."}, {"path", "assets/voice/welcome.wav"}});
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["code"] == "no_provider");
    const std::string hint = none.error["hint"].get<std::string>();
    CHECK(hint.find("ELEVENLABS_API_KEY") != std::string::npos);
    CHECK(hint.find("OPENAI_API_KEY") != std::string::npos);
    CHECK(hint.find("silent") != std::string::npos);

    const std::string text = "Welcome to the lodge, traveller. Mind the stairs.";
    Json made = game.ok("assets.generate_voice", {{"text", text}, {"path", "assets/voice/welcome.wav"}, {"silent", true}});
    CHECK(made["silent"] == true);
    const std::string wav = game.file("assets/voice/welcome.wav");
    REQUIRE(wav.size() > 44);
    CHECK(wav.substr(0, 4) == "RIFF");
    for (std::size_t i = 44; i < wav.size(); ++i) REQUIRE(wav[i] == 0);
    const double seconds = static_cast<double>(wav.size() - 44) / 2 / 22050;
    CHECK(seconds == doctest::Approx(0.06 * static_cast<double>(text.size())).epsilon(0.01));
    CHECK(made["seconds"].get<double>() == doctest::Approx(seconds).epsilon(0.001));
    const Json prov = game.provenance("assets/voice/welcome.wav");
    CHECK(prov["ai"] == false);  // nothing was generated: it does not count in the AI disclosure
    CHECK(prov["kind"] == "voice");
    CHECK(prov["prompt"] == text);

    // `seconds` sets the length; a silent clip is a WAV; an existing file is kept
    game.ok("assets.generate_voice", {{"text", "Hi"}, {"path", "assets/voice/hi.wav"}, {"silent", true}, {"seconds", 2.5}});
    CHECK(game.file("assets/voice/hi.wav").size() == 44 + 2 * 55125);
    CHECK_FALSE(game.call("assets.generate_voice", {{"text", "Hi"}, {"path", "assets/voice/hi.mp3"}, {"silent", true}}).ok);
    CHECK(game.call("assets.generate_voice", {{"text", "Hi"}, {"path", "assets/voice/hi.wav"}, {"silent", true}}).error["code"] == "exists");
}
