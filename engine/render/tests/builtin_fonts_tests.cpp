// The built-in fonts selectable by name (fa/render/builtin_fonts.h): serif, hand, blackletter, display, and the real bold
// and italic faces of Text.bold and [b] / [i].
#include "test_util.h"

#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

#include "fa/core/strings.h"
#include "fa/render/builtin_fonts.h"
#include "fa/render/fonts.h"
#include "font_internal.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::test;
namespace fr = fa::render;

namespace {

// The developer tools set this source from the files embedded in them; the render tests read the repository's.
void install_source() {
    {
        set_builtin_font_source([](std::string_view file) -> std::optional<std::string> {
            std::ifstream in(std::filesystem::path(FA_REPO_ROOT) / "engine/render/assets/fonts/extra" / std::string(file), std::ios::binary);
            if (!in) return std::nullopt;
            std::ostringstream ss;
            ss << in.rdbuf();
            return ss.str();
        });
    }
}

const char* const kSpanishGerman = "Áéíóú ÁÉÍÓÚ ñ Ñ ü Ü ¿¡ äöü ÄÖÜ ß «» “” ‘’ — … ç";

}  // namespace

TEST_CASE("builtin fonts: every name resolves, has the Spanish and German letters and draws ink") {
    install_source();
    REQUIRE(builtin_fonts().size() == 6);
    for (const BuiltinFont& font : builtin_fonts()) {
        CAPTURE(font.name);
        auto face = fr::load_font_face(font.name);
        REQUIRE_MESSAGE(face->ok, face->error);
        for (const std::string& file : font.files) {
            CAPTURE(file);
            CHECK(file.size() > 4);
        }
        // coverage of the font alone, without DejaVu Sans behind it: the faces
        for (char32_t cp : fr::decode_text(kSpanishGerman)) {
            if (cp == U' ' || font.name == "builtin:pixel") continue;
            CAPTURE(std::uint32_t(cp));
            if (font.name == "builtin" || font.name == "builtin:serif" || font.name == "builtin:hand" || font.name == "builtin:display")
                CHECK(face->has_glyph(cp));
        }
        auto bitmap = rasterize_text("Ñandú ¿Qué? Straße", font.name, 32);
        REQUIRE(bitmap.ok());
        CHECK(bitmap->width > 40);
        CHECK(bitmap->height > 10);
    }
    // the blackletter has the accents of Spanish and German too; the check of the characters it lacks is the coverage API's
    auto cov = FontCoverage::load({"builtin:blackletter"});
    REQUIRE(cov.ok());
    CHECK(cov->missing("Ñandú ¿Qué? Straße Äpfel").empty());
}

TEST_CASE("builtin fonts: the faces of a family exist as the catalog says") {
    install_source();
    for (const BuiltinFont& font : builtin_fonts()) {
        if (font.embedded) continue;
        CAPTURE(font.name);
        CHECK(builtin_variant_file(font, false, false) == font.files[0]);
        CHECK(builtin_variant_file(font, true, false).empty() == !font.hasBold);
        CHECK(builtin_variant_file(font, false, true).empty() == !font.hasItalic);
        CHECK(builtin_variant_file(font, true, true).empty() == !font.hasBoldItalic);
        for (const char* variant : {"#bold", "#italic", "#bolditalic"}) {
            auto face = fr::load_font_face(font.name + variant);
            const bool exists = std::string(variant) == "#bold" ? font.hasBold : std::string(variant) == "#italic" ? font.hasItalic : font.hasBoldItalic;
            CAPTURE(variant);
            CHECK(face->ok == exists);
        }
    }
}

TEST_CASE("builtin fonts: an unknown builtin: name is an error that lists every built-in font and suggests the closest") {
    install_source();
    auto face = fr::load_font_face("builtin:serf");
    CHECK_FALSE(face->ok);
    CHECK(face->error.find("builtin:serf") != std::string::npos);
    for (const BuiltinFont& font : builtin_fonts()) {
        CAPTURE(font.name);
        CHECK(face->hint.find(font.name == "builtin" ? "\"\"" : font.name) != std::string::npos);
    }
    CHECK(face->hint.find("Did you mean 'builtin:serif'?") != std::string::npos);
    auto missing = FontCoverage::load({"builtin:handwriting"});
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().hint.find("builtin:blackletter") != std::string::npos);
}

TEST_CASE("builtin fonts: without the file a player says where it looked, and a project font path is not confused with them") {
    set_builtin_font_source({});
    auto face = fr::load_font_face("builtin:display");
    CHECK_FALSE(face->ok);
    CHECK(face->error.find("builtin-fonts/IMFeENrm28P.ttf") != std::string::npos);
    CHECK(face->hint.find("export") != std::string::npos);
    CHECK(fr::load_font_face("builtin:pixel")->ok);  // inside the player: needs no file
    install_source();
}

TEST_CASE("builtin fonts: builtin_fonts_named_in finds whole names only") {
    const auto names = [](std::string_view text) {
        std::vector<std::string> out;
        for (const BuiltinFont* f : builtin_fonts_named_in(text)) out.push_back(f->name);
        return out;
    };
    CHECK(names(R"({"font": "builtin:serif"} "builtin:hand")") == std::vector<std::string>{"builtin:serif", "builtin:hand"});
    CHECK(names("builtin:serif-bold builtin:handwriting builtin:serif2").empty());
    CHECK(names("builtin:pixel and the default font").empty());  // inside the player: nothing to copy
    CHECK(names("font:'builtin:display'") == std::vector<std::string>{"builtin:display"});
}

TEST_CASE("builtin fonts: bold and italic draw the real faces of the family") {
    install_source();
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const TextStyle markup{true, false}, bold{false, true};
    const auto width = [&](const std::string& text, const std::string& font, TextStyle style = {}) {
        return g.renderer.measure_text(text, 24, font, 0, RenderSpace::World, style).x;
    };
    const float regular = width("Hamburgefonstiv", "builtin:serif");
    const float boldW = width("Hamburgefonstiv", "builtin:serif", bold);
    const float italicW = width("[i]Hamburgefonstiv[/i]", "builtin:serif", markup);
    const float bothW = width("[b][i]Hamburgefonstiv[/i][/b]", "builtin:serif", markup);
    CHECK(width("[b]Hamburgefonstiv[/b]", "builtin:serif", markup) == doctest::Approx(boldW).epsilon(0.001));
    // the real faces have their own advances: not the regular ones plus the engine's thickening
    auto bold_face = fr::load_font_face("builtin:serif#bold");
    auto regular_face = fr::load_font_face("builtin:serif");
    REQUIRE(bold_face->ok);
    REQUIRE(regular_face->ok);
    CHECK(boldW != doctest::Approx(regular).epsilon(0.001));
    CHECK(italicW != doctest::Approx(regular).epsilon(0.001));
    CHECK(bothW != doctest::Approx(boldW).epsilon(0.001));
    CHECK(bothW != doctest::Approx(italicW).epsilon(0.001));
    // a family without the face stays as it is: no italic in the blackletter, DejaVu Sans or the pixel font
    for (const char* font : {"builtin:blackletter", "", "builtin:pixel"})
        CHECK(width("[i]Hamburgefonstiv[/i]", font, markup) == doctest::Approx(width("Hamburgefonstiv", font)).epsilon(0.001));
    // handwriting has a bold face but no italic one
    CHECK(width("[i]Hamburgefonstiv[/i]", "builtin:hand", markup) == doctest::Approx(width("Hamburgefonstiv", "builtin:hand")).epsilon(0.001));
    CHECK(width("Hamburgefonstiv", "builtin:hand", bold) != doctest::Approx(width("Hamburgefonstiv", "builtin:hand")).epsilon(0.001));
    CHECK(width("[i]Hamburgefonstiv[/i]", "builtin:display", markup) != doctest::Approx(width("Hamburgefonstiv", "builtin:display")).epsilon(0.001));
}

TEST_CASE("builtin fonts: the text.fonts italic entry of a project font draws [i], and a text.fonts entry wins over the family's face") {
    install_source();
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const TextStyle markup{true, false};
    RichTextStyle s;
    s.italicFonts["builtin:blackletter"] = "builtin:pixel";  // any other face will do for the test
    s.boldFonts["builtin:serif"] = "builtin:pixel";
    g.renderer.set_rich_text_style(s);
    const auto width = [&](const std::string& text, const std::string& font) {
        return g.renderer.measure_text(text, 24, font, 0, RenderSpace::World, markup).x;
    };
    const float pixel = g.renderer.measure_text("abcdef", 24, "builtin:pixel").x;
    CHECK(width("[i]abcdef[/i]", "builtin:blackletter") == doctest::Approx(pixel).epsilon(0.001));
    CHECK(width("[b]abcdef[/b]", "builtin:serif") == doctest::Approx(pixel).epsilon(0.001));
    g.renderer.set_rich_text_style({});
}
