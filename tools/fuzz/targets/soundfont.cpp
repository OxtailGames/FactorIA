// SoundFont (.sf2) files through TinySoundFont: Soundfont::from_memory, then one short note of the first preset is rendered.
// A damaged file is an error; a file whose sample tables point outside it must not be read past its end.
#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/audio/soundfont.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    const std::vector<std::uint8_t> bytes(data, data + size);
    const auto font = fa::Soundfont::from_memory(bytes, "fuzz.sf2");
    if (!font || font.value().presets().empty()) return 0;
    std::vector<double> left, right;
    const fa::SoundfontNote note{0, 2000, 60, 0.8f};
    (void)font.value().render(0, 22050, {note}, 4000, left, right);
    return 0;
}
