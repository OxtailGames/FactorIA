// The building blocks of ChaCha20-Poly1305 (crypto.cpp), exposed so the tests can check them against the RFC 8439 vectors
// one by one. Not part of the public API: use aead_seal / seal_blob.
#pragma once

#include "fa/core/crypto.h"

namespace fa::crypto::detail {

// ChaCha20 block function (RFC 8439, 2.3): the 64-byte key stream block for `counter`.
void chacha20_block(const Key& key, std::uint32_t counter, const Nonce& nonce, std::uint8_t out[64]);

// ChaCha20 encryption (RFC 8439, 2.4): `out` = `in` XOR key stream starting at block `counter`; out.size() == in.size().
void chacha20_xor(const Key& key, std::uint32_t counter, const Nonce& nonce, ByteView in, std::uint8_t* out);

// Poly1305 (RFC 8439, 2.5): the 16-byte tag of `msg` under a 32-byte one-time key.
void poly1305_tag(const std::uint8_t key[32], ByteView msg, std::uint8_t tag[16]);

}  // namespace fa::crypto::detail
