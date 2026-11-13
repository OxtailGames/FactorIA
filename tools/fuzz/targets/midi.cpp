// Standard MIDI Files: parse_midi on any bytes, then the file is written back and read again (the writer's output must be a
// file the reader accepts).
#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/audio/midi.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    const std::vector<std::uint8_t> bytes(data, data + size);
    const auto midi = fa::parse_midi(bytes, "fuzz.mid");
    if (!midi) return 0;
    const auto written = fa::write_midi(midi.value());
    if (written && !fa::parse_midi(written.value(), "fuzz-written.mid")) fa::fuzz::fail("write_midi wrote a file that parse_midi refuses");
    return 0;
}
