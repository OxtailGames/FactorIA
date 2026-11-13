// Audio files whose headers lie (M93.2b): a header may claim any channel count and any length, and a decoder must not size its
// buffers from either. These are the cases the fuzz target `audio` found or guards.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <vector>

#include "audio_test_helpers.h"
#include "fa/audio/analysis.h"
#include "fa/audio/convert.h"
#include "fa/audio/soundfont.h"
#include "tiny_sf2.h"

using namespace fa;
using namespace audio_test;

namespace {

void set32(std::vector<std::uint8_t>& b, std::size_t at, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) b[at + std::size_t(i)] = std::uint8_t(v >> (8 * i));
}

}  // namespace

TEST_CASE("decode_audio: a WAV that claims more channels than the engine reads is an error that says so") {
    std::vector<float> tone;
    add_sine(tone, 0.1, 440.0, 0.3, 8000);
    std::vector<std::uint8_t> wav = wav_bytes(tone, 1, 8000);
    // fmt chunk: channels at byte 22, then the byte rate (28) and the block align (32) of a 64-channel file.
    wav[22] = std::uint8_t(64);
    wav[23] = std::uint8_t(0);
    set32(wav, 28, 8000u * 64u * 2u);
    wav[32] = std::uint8_t(64 * 2);
    wav[33] = std::uint8_t(0);
    const auto clip = decode_audio(wav, ".wav");
    REQUIRE_FALSE(clip.ok());
    CHECK(clip.error().message.find("channels") != std::string::npos);
    CHECK_FALSE(measure_loudness(wav, ".wav").ok());

    // A file with a few more channels than stereo is fine: the clip plays its first two.
    std::vector<float> six(tone.size() * 6, 0.1f);
    const auto surround = decode_audio(wav_bytes(six, 6, 8000), ".wav");
    REQUIRE(surround.ok());
    CHECK(surround->channels == 2);
}

TEST_CASE("decode_audio: a WAV whose header promises hours of audio is read for what the file holds") {
    std::vector<float> tone;
    add_sine(tone, 0.1, 440.0, 0.3, 8000);
    std::vector<std::uint8_t> wav = wav_bytes(tone, 1, 8000);
    set32(wav, 40, 0xFFFFFFF0u);  // the data chunk's size
    set32(wav, 4, 0xFFFFFFF0u);   // and the RIFF size
    const auto clip = decode_audio(wav, ".wav");
    if (clip.ok()) {  // read what is there (the reserve is capped, not the data)
        CHECK(clip->frames() > 0);
        CHECK(clip->frames() <= tone.size());
    }
    CHECK(decode_audio(wav, ".wav", 0.05).ok() == clip.ok());
}

namespace {
std::vector<std::uint8_t> read_ogg() {  // a short tone through the engine's own Vorbis encoder
    std::vector<float> tone;
    add_sine(tone, 0.3, 440.0, 0.3, 22050);
    auto ogg = encode_vorbis(wav_bytes(tone, 1, 22050));
    REQUIRE_MESSAGE(ogg.ok(), (ogg.ok() ? "" : ogg.error().to_string()));
    return *ogg;
}

// Where the comment header ("\x03vorbis") starts.
std::size_t comment_header(const std::vector<std::uint8_t>& ogg) {
    static const char tag[] = "\x03vorbis";
    const auto at = std::search(ogg.begin(), ogg.end(), tag, tag + 7);
    REQUIRE(at != ogg.end());
    return std::size_t(at - ogg.begin());
}
}  // namespace

TEST_CASE("decode_audio: an OGG whose comment lengths lie is refused before stb_vorbis allocates from them") {
    const std::vector<std::uint8_t> good = read_ogg();
    REQUIRE(decode_audio(good, ".ogg").ok());
    const std::size_t head = comment_header(good);

    std::vector<std::uint8_t> vendor = good;  // a vendor string of 4 billion bytes (stb_vorbis reads -1: a write before its buffer)
    set32(vendor, head + 7, 0xFFFFFFFFu);
    CHECK_FALSE(decode_audio(vendor, ".ogg").ok());

    std::vector<std::uint8_t> hugeVendor = good;  // 2 GB: stb_vorbis would loop over it byte by byte
    set32(hugeVendor, head + 7, 0x7FFFFFF0u);
    CHECK_FALSE(decode_audio(hugeVendor, ".ogg").ok());

    std::vector<std::uint8_t> comments = good;  // the comment count follows the vendor string
    const std::size_t vendorLen = good[head + 7] | good[head + 8] << 8 | good[head + 9] << 16 | good[head + 10] << 24;
    set32(comments, head + 11 + vendorLen, 0x7FFFFFFFu);
    CHECK_FALSE(decode_audio(comments, ".ogg").ok());

    const std::vector<std::uint8_t> cut(good.begin(), good.begin() + std::ptrdiff_t(head + 9));  // ends inside the vendor length
    CHECK_FALSE(decode_audio(cut, ".ogg").ok());
}

TEST_CASE("decode_audio: an OGG with more than 16 MB of comments says it is a size limit, not damage") {
    const std::vector<std::uint8_t> good = read_ogg();
    // The identification page of the real file, then 300 pages that all continue the comment packet (255 lacing values of 255
    // bytes, so the packet never ends): about 19 MB, as a file with a huge cover picture in its tags has.
    const char capture[] = "OggS";
    const auto second = std::search(good.begin() + 4, good.end(), capture, capture + 4);
    REQUIRE(second != good.end());
    std::vector<std::uint8_t> big(good.begin(), second);
    for (int page = 0; page < 300; ++page) {
        std::vector<std::uint8_t> p(27 + 255 + 255 * 255, 0x41);
        std::copy(capture, capture + 4, p.begin());
        std::fill(p.begin() + 4, p.begin() + 26, std::uint8_t(0));
        p[26] = 255;
        std::fill(p.begin() + 27, p.begin() + 27 + 255, std::uint8_t(255));
        big.insert(big.end(), p.begin(), p.end());
    }
    const auto clip = decode_audio(big, ".ogg");
    REQUIRE_FALSE(clip.ok());
    CHECK(clip.error().message.find("16 MB") != std::string::npos);
    CHECK(clip.error().message.find("not a valid") == std::string::npos);
    // Damage keeps its own message.
    const std::vector<std::uint8_t> cut(good.begin(), good.begin() + std::ptrdiff_t(comment_header(good) + 9));
    const auto damaged = decode_audio(cut, ".ogg");
    REQUIRE_FALSE(damaged.ok());
    CHECK(damaged.error().message.find("not a valid") != std::string::npos);
}

TEST_CASE("decode_audio: damaged OGG, MP3 and QOA are errors, empty input too") {
    const std::vector<std::uint8_t> junk(64, 0x55);
    for (const char* ext : {".wav", ".ogg", ".mp3", ".qoa"}) CHECK_FALSE(decode_audio(junk, ext).ok());
    CHECK_FALSE(decode_audio(std::vector<std::uint8_t>{}, ".wav").ok());
    CHECK_FALSE(decode_audio(junk, ".flac").ok());
}

namespace {
// Where table `id` ("phdr", "igen"...) has its records in a SoundFont, and how many records of `size` bytes it holds.
struct Table {
    std::size_t at = 0, count = 0;
};
Table sf2_table(const std::vector<std::uint8_t>& sf2, const char* id, std::size_t size) {
    const auto it = std::search(sf2.begin(), sf2.end(), id, id + 4);
    REQUIRE(it != sf2.end());
    const std::size_t at = std::size_t(it - sf2.begin());
    return {at + 8, (std::size_t(sf2[at + 4]) | std::size_t(sf2[at + 5]) << 8) / size};
}
void put16(std::vector<std::uint8_t>& b, std::size_t at, unsigned v) {
    b[at] = std::uint8_t(v & 255);
    b[at + 1] = std::uint8_t(v >> 8);
}
}  // namespace

TEST_CASE("Soundfont::from_memory: indices that point outside the SoundFont's tables are refused, not followed") {
    const std::vector<std::uint8_t> good = fa::testing::tiny_sf2();
    REQUIRE(Soundfont::from_memory(good, "good.sf2").ok());
    const Table phdr = sf2_table(good, "phdr", 38), pbag = sf2_table(good, "pbag", 4), pgen = sf2_table(good, "pgen", 4),
                inst = sf2_table(good, "inst", 22), igen = sf2_table(good, "igen", 4);

    auto refused = [&](const std::vector<std::uint8_t>& sf2, const char* name) {
        CAPTURE(name);
        const auto font = Soundfont::from_memory(sf2, name);
        REQUIRE_FALSE(font.ok());
        CHECK(font.error().message.find("damaged") != std::string::npos);
        CHECK_FALSE(font.error().hint.empty());
    };

    std::vector<std::uint8_t> bad = good;  // the terminal preset header's zone index points at zones that are not there
    put16(bad, phdr.at + (phdr.count - 1) * 38 + 24, 9999);
    refused(bad, "zones.sf2");

    bad = good;  // the first preset zone's generator index is beyond the generator list
    put16(bad, pbag.at, 0xFFFF);
    refused(bad, "gens.sf2");

    bad = good;  // a preset zone uses the instrument number that is the terminal record
    for (std::size_t g = 0; g < pgen.count; ++g)
        if (good[pgen.at + g * 4] == 41) put16(bad, pgen.at + g * 4 + 2, unsigned(inst.count - 1));
    refused(bad, "terminal.sf2");

    bad = good;  // an instrument zone names a sample header that is not there
    for (std::size_t g = 0; g < igen.count; ++g)
        if (good[igen.at + g * 4] == 53) put16(bad, igen.at + g * 4 + 2, 9999);
    refused(bad, "sample.sf2");

    // Every cut of a good file is an error or a font, never a read outside the file.
    for (std::size_t cut = 0; cut < good.size(); cut += 37)
        (void)Soundfont::from_memory(std::vector<std::uint8_t>(good.begin(), good.begin() + std::ptrdiff_t(cut)), "cut.sf2");
}
