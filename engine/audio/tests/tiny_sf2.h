// A tiny SoundFont 2 built in code (no binary from anywhere), for the tests of the SoundFont instruments in fa_audio and in the tools.
#pragma once

#include <cmath>
#include <cstdint>
#include <numbers>
#include <string>
#include <vector>

namespace fa::testing {
namespace tiny_sf2_detail {

struct Bytes {
    std::vector<std::uint8_t> b;
    void u8(int v) { b.push_back(std::uint8_t(v)); }
    void u16(int v) {
        u8(v & 255);
        u8((v >> 8) & 255);
    }
    void u32(std::uint32_t v) {
        u16(int(v & 0xffff));
        u16(int(v >> 16));
    }
    void tag(const char* s) {
        for (int i = 0; i < 4; ++i) u8(s[i]);
    }
    void name(const std::string& s) {  // a 20-byte zero-padded name
        for (int i = 0; i < 20; ++i) u8(i < int(s.size()) ? s[std::size_t(i)] : 0);
    }
    void add(const Bytes& o) { b.insert(b.end(), o.b.begin(), o.b.end()); }
};

inline Bytes chunk(const char* id, const Bytes& body) {
    Bytes c;
    c.tag(id);
    c.u32(std::uint32_t(body.b.size()));
    c.add(body);
    if (body.b.size() % 2) c.u8(0);
    return c;
}
inline Bytes list(const char* type, const Bytes& body) {
    Bytes inner;
    inner.tag(type);
    inner.add(body);
    return chunk("LIST", inner);
}

}  // namespace tiny_sf2_detail

// A one-sample SoundFont: a looped 441 Hz sine at root key 69, a melodic preset "Test Sine" (bank 0, program 0), a second melodic preset
// "Test Sine Two" (bank 0, program 5) and a drum preset "Test Kit" (bank 128, program 0).
inline std::vector<std::uint8_t> tiny_sf2() {
    using namespace tiny_sf2_detail;
    Bytes info;
    {
        Bytes ifil;
        ifil.u16(2);
        ifil.u16(1);
        info.add(chunk("ifil", ifil));
        Bytes isng;
        for (char ch : std::string("EMU8000")) isng.u8(ch);
        isng.u8(0);
        info.add(chunk("isng", isng));
        Bytes inam;
        for (char ch : std::string("tiny")) inam.u8(ch);
        inam.u8(0);
        info.add(chunk("INAM", inam));
    }
    constexpr int kCycles = 44, kPeriod = 100, kLen = kCycles * kPeriod;
    Bytes smpl;
    for (int i = 0; i < kLen; ++i)
        smpl.u16(int(std::lround(12000.0 * std::sin(2.0 * std::numbers::pi * double(i) / kPeriod))) & 0xffff);
    for (int i = 0; i < 46; ++i) smpl.u16(0);  // the 46 zero samples a SoundFont keeps after every sample
    Bytes sdta;
    sdta.add(chunk("smpl", smpl));

    Bytes phdr;
    auto preset = [&](const std::string& n, int program, int bank, int bag) {
        phdr.name(n);
        phdr.u16(program);
        phdr.u16(bank);
        phdr.u16(bag);
        phdr.u32(0);
        phdr.u32(0);
        phdr.u32(0);
    };
    preset("Test Sine", 0, 0, 0);
    preset("Test Sine Two", 5, 0, 1);
    preset("Test Kit", 0, 128, 2);
    preset("EOP", 0, 0, 3);
    Bytes pbag;
    for (int i = 0; i < 4; ++i) {
        pbag.u16(i);
        pbag.u16(0);
    }
    Bytes pmod;
    for (int i = 0; i < 10; ++i) pmod.u8(0);
    Bytes pgen;
    for (int i = 0; i < 3; ++i) {
        pgen.u16(41);
        pgen.u16(0);
    }  // instrument 0
    pgen.u16(0);
    pgen.u16(0);
    Bytes inst;
    inst.name("Sine");
    inst.u16(0);
    inst.name("EOI");
    inst.u16(1);
    Bytes ibag;
    ibag.u16(0);
    ibag.u16(0);
    ibag.u16(2);
    ibag.u16(0);
    Bytes imod;
    for (int i = 0; i < 10; ++i) imod.u8(0);
    Bytes igen;
    igen.u16(54);
    igen.u16(1);  // sampleModes: loop
    igen.u16(53);
    igen.u16(0);  // sampleID 0 (last)
    igen.u16(0);
    igen.u16(0);
    Bytes shdr;
    shdr.name("Sine");
    shdr.u32(0);
    shdr.u32(kLen);
    shdr.u32(0);
    shdr.u32(kLen);
    shdr.u32(44100);
    shdr.u8(69);
    shdr.u8(0);
    shdr.u16(0);
    shdr.u16(1);
    shdr.name("EOS");
    for (int i = 0; i < 26; ++i) shdr.u8(0);
    Bytes pdta;
    pdta.add(chunk("phdr", phdr));
    pdta.add(chunk("pbag", pbag));
    pdta.add(chunk("pmod", pmod));
    pdta.add(chunk("pgen", pgen));
    pdta.add(chunk("inst", inst));
    pdta.add(chunk("ibag", ibag));
    pdta.add(chunk("imod", imod));
    pdta.add(chunk("igen", igen));
    pdta.add(chunk("shdr", shdr));

    Bytes body;
    body.tag("sfbk");
    body.add(list("INFO", info));
    body.add(list("sdta", sdta));
    body.add(list("pdta", pdta));
    Bytes file;
    file.tag("RIFF");
    file.u32(std::uint32_t(body.b.size()));
    file.add(body);
    return file.b;
}

}  // namespace fa::testing
