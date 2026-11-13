// A QR code encoder (ISO/IEC 18004, model 2), byte mode only, written for the editor's "Play on phone" window: the LAN
// URL of the web build is drawn as a code the phone's camera reads. No library.
//
// qr_encode() picks the smallest version (1 to 40) that holds the bytes at the chosen error correction level and the
// mask (of the 8) with the lowest penalty score, as the standard says; the result is deterministic. Byte mode holds any
// bytes: the standard's default reading is ISO 8859-1, but every phone reads a UTF-8 or ASCII URL.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

enum class QrEcc : std::uint8_t {
    Low,
    Medium,
    Quartile,
    High
};  // about 7%, 15%, 25%, 30% of the codewords can be wrong

struct QrCode {
    int version = 0;  // 1..40
    int size = 0;     // modules per side: 17 + 4 * version
    int mask = 0;     // the mask pattern used, 0..7
    QrEcc ecc = QrEcc::Medium;
    std::vector<std::uint8_t> modules;  // size * size, row by row from the top left: 1 = dark. No quiet zone.

    bool dark(int x, int y) const {
        return x >= 0 && y >= 0 && x < size && y < size &&
               modules[static_cast<std::size_t>(y) * static_cast<std::size_t>(size) + static_cast<std::size_t>(x)] != 0;
    }
    // The rows as text ('#' dark, '.' light), for tests and logs.
    std::vector<std::string> rows() const;
};

// How many bytes version `version` (1..40) holds at `ecc` in byte mode; 0 for a version out of range.
int qr_capacity_bytes(int version, QrEcc ecc);

// Encodes `data` in byte mode. An error (with a hint) when it does not fit even in version 40 (2953 bytes at Low, 2331 at
// Medium, 1663 at Quartile, 1273 at High). `minVersion` forces a bigger symbol than needed (clamped to 1..40).
Result<QrCode> qr_encode(std::string_view data, QrEcc ecc = QrEcc::Medium, int minVersion = 1);

// The Reed-Solomon error correction codewords of one block of data codewords (GF(256), polynomial 0x11D): the building
// block of the encoder, exposed for the standard's worked examples.
std::vector<std::uint8_t> qr_reed_solomon(const std::vector<std::uint8_t>& data, int eccLength);

// The 15 format information bits (error correction level and mask, BCH-coded and XORed with 0x5412).
std::uint32_t qr_format_bits(QrEcc ecc, int mask);

}  // namespace fa
