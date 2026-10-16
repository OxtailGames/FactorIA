// Drawing of the game UI widgets (Panel, Button, Toggle, Slider, TextField, ScrollList): 9-slice, state tints, labels,
// focus ring, clipping. Interaction (focus, hover, values) is fa_ui's; here the runtime flags are set by hand.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>

using namespace fa;
using namespace fa::test;

namespace {

// 24x24 texture whose four 8x8 corners are different patterns, edges have a dark 2 px rim and the centre is flat: any
// scaling of a corner changes its pixels.
Image nine_slice_texture() {
    Image img;
    img.width = img.height = 24;
    img.rgba.resize(24 * 24 * 4);
    const Color corner[4] = {Color::hex(0xe04040), Color::hex(0x40e040), Color::hex(0x4040e0), Color::hex(0xe0e040)};
    for (int y = 0; y < 24; ++y)
        for (int x = 0; x < 24; ++x) {
            const int cx = x / 8, cy = y / 8;
            Color c;
            if (cx != 1 && cy != 1) {  // a corner: its colour with a 2 px checker so every pixel row differs from its neighbour
                c = corner[(cy / 2) * 2 + cx / 2];
                if (((x % 8) / 2 + (y % 8) / 2) % 2 == 1) c = Color{c.r * 0.5f, c.g * 0.5f, c.b * 0.5f, 1};
            } else if (cx == 1 && cy == 1) {
                c = Color::hex(0xd8d8b0);
            } else {  // an edge: dark rim on the outside, flat inside
                const int rim = cy == 0 ? y : cy == 2 ? 23 - y : cx == 0 ? x : 23 - x;
                c = rim < 2 ? Color::hex(0x202020) : Color::hex(0x808080);
            }
            img.set_pixel(x, y, c);
        }
    return img;
}

bool near(const Color& a, const Color& b, float tol = 0.02f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

// A widget component on a new entity at screen position (x, y) (top-left corner, design pixels).
template <class T>
T& widget(World& w, const char* name, float x, float y, float width, float height) {
    Entity e = make(w, name, {x, y, 0});
    T& c = w.add<T>(e);
    c.size = {width, height};
    c.pivot = {0, 1};
    return c;
}

}  // namespace

TEST_CASE("9-slice: a Panel keeps its corners unscaled at any size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image tex = nine_slice_texture();
    REQUIRE(save_png(tex, "assets/nine_slice.png").ok());
    World w;
    w.add<Camera>(make(w, "cam"));
    struct Spot { float x, y, width, height; };
    const Spot spots[3] = {{10, 10, 40, 40}, {60, 10, 100, 60}, {10, 80, 200, 90}};  // small, wide, large
    for (int i = 0; i < 3; ++i) {
        Panel& p = widget<Panel>(w, ("panel" + std::to_string(i)).c_str(), spots[i].x, spots[i].y, spots[i].width, spots[i].height);
        p.texture = "assets/nine_slice.png";
        p.slice = {8, 8, 8, 8};
        p.color = Color{1, 1, 1, 1};
    }
    Image img = g.render(w);
    for (const Spot& s : spots) {
        for (int j = 0; j < 8; ++j) {
            for (int i = 0; i < 8; ++i) {
                const int x0 = int(s.x), y0 = int(s.y), x1 = int(s.x + s.width) - 8, y1 = int(s.y + s.height) - 8;
                INFO("panel " << x0 << "," << y0 << " pixel " << i << "," << j);
                CHECK(near(img.pixel(x0 + i, y0 + j), tex.pixel(i, j)));
                CHECK(near(img.pixel(x1 + i, y0 + j), tex.pixel(16 + i, j)));
                CHECK(near(img.pixel(x0 + i, y1 + j), tex.pixel(i, 16 + j)));
                CHECK(near(img.pixel(x1 + i, y1 + j), tex.pixel(16 + i, 16 + j)));
            }
        }
    }
    // the centre and the edges are stretched: flat colours between the corners
    CHECK(near(img.pixel(110, 40), tex.pixel(12, 12)));  // centre of the wide panel
    CHECK(near(img.pixel(110, 10), tex.pixel(12, 0)));   // its top rim (the edge is stretched along x only)
    CHECK(near(img.pixel(110, 14), tex.pixel(12, 4)));   // inside the top edge
    expect_golden(img, "2d_nine_slice");
}

TEST_CASE("widgets: backgrounds, labels, state tints, focus ring and ScrollList clipping") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam"));
    auto label = [](auto& c, float size = 14) { c.fontSize = size; };

    Button& play = widget<Button>(w, "play", 10, 10, 100, 30);
    play.text = "Play";
    label(play);
    Button& options = widget<Button>(w, "options", 120, 10, 100, 30);
    options.text = "Options";
    options.focused = true;
    label(options);
    Button& quit = widget<Button>(w, "quit", 230, 10, 80, 30);
    quit.text = "Quit";
    quit.hovered = true;
    label(quit);

    Toggle& music = widget<Toggle>(w, "music", 10, 50, 150, 28);
    music.label = "Music";
    music.value = true;
    label(music);
    Toggle& full = widget<Toggle>(w, "full", 170, 50, 140, 28);
    full.label = "Window";
    label(full);

    Slider& volume = widget<Slider>(w, "volume", 10, 90, 200, 30);
    volume.label = "Vol";
    volume.value = 0.6f;
    label(volume);
    TextField& name = widget<TextField>(w, "name", 220, 90, 90, 30);
    name.text = "abc";
    name.caret = true;
    label(name);

    ScrollList& list = widget<ScrollList>(w, "list", 10, 128, 150, 40);
    list.padding = {0, 0, 0, 0};
    Entity listE = w.find("list");
    for (int i = 0; i < 3; ++i) {  // 24 px items at y 128, 152, 176: the second is cut at the list's bottom, the third is gone
        Button& item = widget<Button>(w, ("item" + std::to_string(i)).c_str(), 10, 128.0f + 24.0f * float(i), 150, 24);
        item.text = "Item " + std::to_string(i);
        item.color = Color{0.8f, 0.2f, 0.2f, 1};
        label(item);
        w.set_parent(w.find(("item" + std::to_string(i)).c_str()), listE, true);
    }
    Entity stripe = make(w, "stripe", {10, 160, 0});  // anything screen-space under a ScrollList is clipped, not just widgets
    {
        Shape2D& s = w.add<Shape2D>(stripe);
        s.space = RenderSpace::Screen;
        s.pivot = {0, 1};
        s.size = {60, 30};
        s.color = Color::hex(0x40e040);
        s.layer = 300;
    }
    w.set_parent(stripe, listE, true);
    TextField& hint = widget<TextField>(w, "hint", 170, 128, 140, 30);
    hint.placeholder = "Name";
    label(hint);
    Button& off = widget<Button>(w, "off", 170, 164, 60, 14);
    off.text = "Off";
    off.interactable = false;
    label(off, 10);

    Image img = g.render(w);
    const Color clear = Color{0.08f, 0.08f, 0.12f, 1};
    auto brightest = [&](int x0, int y0, int x1, int y1) {  // the brightest channel in a pixel box: text is white on dark
        float m = 0;
        for (int y = y0; y < y1; ++y)
            for (int x = x0; x < x1; ++x) m = std::max({m, img.pixel(x, y).r, img.pixel(x, y).g, img.pixel(x, y).b});
        return m;
    };
    // backgrounds: the default style is a translucent dark blue; the hovered one is lighter, the disabled one fainter
    const Color normal = img.pixel(14, 36), hovered = img.pixel(234, 36), disabled = img.pixel(173, 176);
    CHECK(normal.b > clear.b + 0.04f);
    CHECK(hovered.b > normal.b + 0.03f);
    CHECK(near(disabled, clear, 0.08f));
    // labels
    CHECK(brightest(30, 15, 90, 35) > 0.8f);   // "Play"
    CHECK(brightest(140, 15, 200, 35) > 0.8f); // "Options"
    CHECK(brightest(60, 55, 150, 75) > 0.8f);  // "Music"
    CHECK(brightest(240, 95, 300, 115) > 0.8f); // "abc" and its caret
    // the focus ring is 3 px of accent colour just inside the focused widget only
    const Color accent = options.accentColor;
    CHECK(near(img.pixel(170, 11), accent, 0.03f));
    CHECK(near(img.pixel(121, 25), accent, 0.03f));
    CHECK_FALSE(near(img.pixel(60, 11), accent, 0.1f));
    // toggle: the check is filled only when on; slider: the fill ends at the knob
    CHECK(near(img.pixel(25, 64), music.accentColor, 0.03f));
    CHECK_FALSE(near(img.pixel(185, 64), full.accentColor, 0.1f));
    // ScrollList: the item that crosses the bottom edge is cut there and the one after it is not drawn
    const Color itemRed = img.pixel(100, 150);
    CHECK(itemRed.r > 0.6f);
    CHECK(img.pixel(100, 165).r > 0.6f);       // second item, inside the list (y < 168)
    CHECK(near(img.pixel(100, 172), clear, 0.05f));  // second item below the list: clipped
    CHECK(near(img.pixel(100, 178), clear, 0.05f));  // third item: entirely outside
    CHECK(near(img.pixel(40, 165), Color::hex(0x40e040), 0.03f));  // a Shape2D under the list is cut at the same edge
    CHECK(near(img.pixel(40, 172), clear, 0.05f));
    expect_golden(img, "2d_widgets");
}
