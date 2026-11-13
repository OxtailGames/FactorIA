// TrueType / OpenType fonts through stb_truetype: the font is loaded from memory and some text is drawn with it, in two sizes.
// stb_truetype follows every offset of the file without a length, so the engine checks the tables first (font_check.cpp); a
// damaged font is an error, never a read outside the buffer.
#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/render/fonts.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    const std::vector<std::uint8_t> bytes(data, data + size);
    (void)fa::rasterize_text("AB Hello, \xC3\xA9\xED\x95\x9C", bytes, 24.0f);
    (void)fa::rasterize_text("Ag", bytes, 7.0f);
    return 0;
}
