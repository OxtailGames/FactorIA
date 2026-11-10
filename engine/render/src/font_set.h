// The fonts of a game and the layout of a text, without a GPU: which font face every character of a Text comes from (its own
// font, the project's fallback fonts, the built-in DejaVu Sans last, bold and italic faces), HarfBuzz shaping, bidirectional
// text, line breaking, rich text and the metrics of the lines. THE one implementation of "how big is this text": `Fonts`
// (fonts.cpp) places glyph quads in the GPU atlas on top of a TextPrep, and `TextMeasurer` (text_measure.cpp) measures with it
// when there is no renderer, so a run with --no-graphics lays out like a window.
#pragma once

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <string_view>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/text_fit.h"
#include "font_internal.h"
#include "text_shaper.h"

namespace fa::render {

struct FontMetrics {
    float ascent = 0, descent = 0, lineGap = 0;  // pixels at the requested size (descent negative)
    float lineHeight() const { return ascent - descent + lineGap; }
};

// How much wider the engine makes a letter it emboldens (a font with no bold face), in raster pixels: a stem about 4 % of the
// size thicker, never less than 0.7 px so the pixel font and small sizes still show it.
float synthetic_bold_extra(int px);

// The raster size of a text drawn at `fontSize` local units per em where one unit is `pixelsPerUnit` pixels: 4..400 px.
int text_raster_px(float fontSize, float pixelsPerUnit);

// A text shaped and measured, with what placing its glyphs needs.
struct TextPrep {
    FontFace* primary = nullptr;  // the Text's own font (or the built-in one); null: nothing could be laid out
    int px = 0;                   // raster pixels per em
    float unitsPerPx = 1.0f;      // local units per raster pixel
    FontMetrics fm;               // of the primary font at px
    float lineH = 0;              // pixels between two baselines
    float maxW = 0;               // wrap width in raster pixels (0 = never)
    bool rich = false;            // Text.markup or Text.bold
    std::u32string text;          // the code points laid out (markup tags removed)
    std::vector<MarkupAttr> attrs;      // one per code point of `text` (rich text)
    std::vector<int> iconDef;           // by markup icon index: index in `iconDefs`, or -1 (not defined: a blank box)
    std::vector<int> colorSlot;         // by attr.color: 0 = the Text's colour, else palette index + 1
    std::vector<RichIcon> iconDefs;     // the icons the project defines that the text uses
    std::vector<Color> palette;         // the colours the text uses, resolved
    ShapedText shaped;
    Vec2 size{0, 0};              // the widest line and all the lines, in local units: what measuring sees
};

class FontSet {
public:
    // Called once for a font file that cannot be loaded (font key, what is wrong, what to do).
    using FailureNote = std::function<void(const std::string& font, const std::string& error, const std::string& hint)>;
    explicit FontSet(FailureNote note = {});

    // font: "" / "builtin" / "builtin:pixel" / project path to a .ttf. Never null: a font that cannot be loaded is the built-in
    // one (the failure is reported once). The built-in one is the only face that can be !ok (not in this build): then null checks.
    FontFace* face(const std::string& font);
    // The face of that file even when it failed to load (ok == false).
    FontFace* load(const std::string& font);
    bool has_face(const std::string& font) const;
    // Background loading: a face loaded off the main thread (load_font_face) joins the cache, unless that font is there already.
    void adopt(std::unique_ptr<FontFace> face, std::vector<std::string> files);
    void clear();
    Json report() const;

    // The fonts every Text falls back to after its own font; the built-in DejaVu Sans stays last. Drops what was measured.
    void set_fallback_fonts(std::vector<std::string> fonts);
    const std::vector<std::string>& fallback_fonts() const { return fallbackKeys_; }
    // The project's "text" section: colours, icons and bold faces. Drops what was measured.
    void set_rich_style(const RichTextStyle& style);
    const RichTextStyle& rich_style() const { return style_; }

    // Shapes `t.text` in `t.font` (then the fallback fonts) at `fontSize` local units per em, wrapping at t.maxWidth local units,
    // for glyphs rasterized at fontSize * pixelsPerUnit pixels. t.fontSize is NOT read. Reports (once) markup mistakes and
    // characters no font has. `prep.primary` is null when not even the built-in font could be loaded.
    TextPrep prepare(const Text& t, float fontSize, float pixelsPerUnit);
    // prepare(...).size, remembered: the same text at the same size is shaped once.
    // nullopt when nothing could be laid out (not even the built-in font loads).
    std::optional<Vec2> measure(const Text& t, float fontSize, float pixelsPerUnit);

    // Increments every time the fonts, fallback chain or style change: caches of layouts built on top compare it.
    unsigned generation() const { return generation_; }

private:
    FontFace* variant_face(FontFace* regular, bool bold, bool italic, bool& boldDrawn);
    void warn_missing_glyphs(FontFace* f, const std::string& text, const std::vector<char32_t>& missing);
    void warn_markup(const std::string& source);

    FailureNote note_;
    std::unordered_map<std::string, std::unique_ptr<FontFace>> faces_;
    std::vector<std::string> fallbackKeys_;
    RichTextStyle style_;  // boldFonts / italicFonts keyed by FontFace::key (face_key: "builtin" for "")
    std::unordered_set<std::string> warnedRich_;     // markup problems already reported (capped)
    std::unordered_set<std::string> warnedMissing_;  // fonts already warned about a missing glyph
    // Sizes of the texts measured lately. ponytail: dropped whole at 4096 entries.
    std::unordered_map<std::string, Vec2> sizes_;
    int nextId_ = 1;
    unsigned generation_ = 0;
};

// The cache key of a font: "builtin" for "", a built-in name as it is, a font file by its normalized path, so
// "./fonts/a.ttf", "fonts//a.ttf" and the path a background load adopted it with are one face.
std::string font_face_key(const std::string& font);

// Renderer::measure_text and TextMeasurer::measure_text are these two, with the renderer's or the measurer's FontSet and scales
// (text_measure.cpp): the very layout of Text drawing at entity scale 1. Screen-space text is measured at the interface scale it
// is drawn at (rasterized `uiScale` times as large, the result in UI units).
Vec2 measure_plain_text(FontSet& fonts, std::string_view text, float fontSize, std::string_view font, float maxWidth, RenderSpace space,
                        TextStyle style, float textScale, float uiScale);
// With the Text's maxTextScale cap and autoShrink applied at `textScale` (text_fit.h).
Vec2 measure_text_component(FontSet& fonts, const Text& text, float textScale, float uiScale);

}  // namespace fa::render
