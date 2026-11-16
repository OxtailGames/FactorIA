// Authenticated encryption for files the player should not edit by hand (save slots): SHA-256 digests, HMAC-SHA256,
// HKDF-SHA256 (RFC 5869), ChaCha20-Poly1305 (RFC 8439), a constant-time compare, secure zeroing, random bytes from the
// operating system, and a sealed-blob file format built on them. Our own code, no library behind it.
//
// WHAT IT PROTECTS: a sealed file cannot be read as text and cannot be changed (one flipped bit, a truncated or
// swapped file) without `open_blob` / `aead_open` failing, so a player cannot edit gold or an unlocked level with a text
// editor or a hex editor, and a half-written or damaged file is reported instead of loaded as garbage.
//
// WHAT IT DOES NOT PROTECT: the key. A key that ships inside the game (in the binary, a script or a pack) can be
// extracted by anyone who wants to, and then the file can be read and forged again. This is tamper-evidence and
// protection against casual reading, not DRM and not a defence against a determined cheater; real secrecy needs a key
// that never leaves the player's device or a server that holds it. It does not hide the size of the data (the blob
// is 50 bytes larger than the data), and it does not stop a player from restoring an older sealed file (a rollback):
// put a counter or a timestamp inside the data and check it if that matters.
//
// Randomness is NOT the simulation's `world.rng()`: nonces and salts come from the operating system's CSPRNG
// (arc4random_buf on Apple, getrandom on Linux, /dev/urandom on Android, BCryptGenRandom on Windows, getentropy, which is
// crypto.getRandomValues, on the web). That is fine, because sealing is I/O and never takes part in the simulation.
//
// Errors are `fa::Result` values that say what is wrong and what to do; a failed open never returns partial plaintext.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa::crypto {

using ByteView = std::span<const std::uint8_t>;
using Bytes = std::vector<std::uint8_t>;

inline constexpr std::size_t kDigestSize = 32;  // SHA-256 and HMAC-SHA256 output
inline constexpr std::size_t kKeySize = 32;     // ChaCha20-Poly1305 key
inline constexpr std::size_t kNonceSize = 12;   // ChaCha20-Poly1305 nonce (never reuse one with the same key)
inline constexpr std::size_t kTagSize = 16;     // Poly1305 tag appended to the ciphertext

using Digest = std::array<std::uint8_t, kDigestSize>;
using Key = std::array<std::uint8_t, kKeySize>;
using Nonce = std::array<std::uint8_t, kNonceSize>;

// A std::string or string_view of bytes as ByteView (no copy).
inline ByteView as_bytes(std::string_view s) {
    return ByteView(reinterpret_cast<const std::uint8_t*>(s.data()), s.size());
}

// ---- Hashes and key derivation --------------------------------------------------------------------------------------

// SHA-256 of `data` (the same function as fa::Sha256 in hash.h, as raw bytes).
Digest sha256(ByteView data);

// HMAC-SHA256 (RFC 2104 / RFC 4231). Any key length. Compare two MACs with `constant_time_equal`, never with `==`.
Digest hmac_sha256(ByteView key, ByteView data);

// HKDF-SHA256 (RFC 5869): `length` bytes derived from the input key material `ikm`, an optional `salt` (empty = 32
// zero bytes) and a context string `info`. `length` is at most 255 * 32 = 8160; more is an Error.
Result<Bytes> hkdf_sha256(ByteView ikm, ByteView salt, ByteView info, std::size_t length);

// A 32-byte key from a secret string (the "key" a game picks) and a context that names what it is for ("save-slots"):
// HKDF-SHA256 with a fixed salt. The same secret and context always give the same key, and a different context gives an
// unrelated key. It does NOT stretch the secret: it is for a long random secret, not a short password a player types
// (a password would need a slow function, which this module does not have).
Key key_from_secret(std::string_view secret, std::string_view context);

// ---- ChaCha20-Poly1305 (RFC 8439) -----------------------------------------------------------------------------------

// The largest plaintext of one message: RFC 8439 allows 2^38 - 64 bytes.
inline constexpr std::uint64_t kMaxMessageSize = (std::uint64_t(1) << 38) - 64;

// Encrypts and authenticates: returns the ciphertext (same length as `plaintext`) followed by the 16-byte tag. `aad` is
// authenticated but not encrypted (a slot name, a version: whatever must match when the data is opened); it may be empty.
// NEVER seal two messages with the same key and nonce: the key stream repeats and both messages leak. Use `seal_blob`,
// which picks a fresh random nonce each time, unless you manage nonces yourself. An Error only for a message larger
// than kMaxMessageSize.
Result<Bytes> aead_seal(const Key& key, const Nonce& nonce, ByteView aad, ByteView plaintext);

// Checks the tag, then decrypts. `sealed` is what `aead_seal` returned (ciphertext + tag). On any mismatch (wrong key,
// wrong nonce, wrong `aad`, one changed byte, truncation) returns an Error ("the data was changed or the key is
// wrong") and no plaintext at all: nothing is decrypted before the tag is verified.
Result<Bytes> aead_open(const Key& key, const Nonce& nonce, ByteView aad, ByteView sealed);

// ---- Small helpers --------------------------------------------------------------------------------------------------

// True when both have the same length and the same bytes. The time depends on the length only, not on where the first
// difference is, so a MAC or tag check does not leak how many bytes were right.
bool constant_time_equal(ByteView a, ByteView b);

// Overwrites `size` bytes with zeros in a way the optimizer may not remove (a plain memset of a buffer that is never read
// again is deleted). Use it on keys and key material on the stack or in a vector before they go out of scope.
void secure_zero(void* data, std::size_t size);
template <class T, std::size_t N>
void secure_zero(std::array<T, N>& a) {
    secure_zero(a.data(), N * sizeof(T));
}

// Fills `out` with random bytes from the operating system's CSPRNG. An Error only when the system refuses (it names the
// call and the system's message); never falls back to a weaker source.
Result<void> random_bytes(std::span<std::uint8_t> out);

// ---- Sealed blobs: the file format ----------------------------------------------------------------------------------
//
//   offset  size  field
//        0     4  magic "FASB"
//        4     1  format version (1)
//        5     1  reserved, 0
//        6    16  salt (random per blob; the blob's encryption key is HKDF(key, salt))
//       22    12  nonce (random per blob)
//       34     n  ciphertext (the data, encrypted)
//     34+n    16  Poly1305 tag over the header, the caller's `aad` and the ciphertext
//
// A fresh random salt and nonce are drawn for every seal, so sealing the same data twice gives two unrelated files and a
// key can seal any number of files. The header is authenticated: changing any byte of the blob makes `open_blob` fail.

inline constexpr std::size_t kBlobOverhead = 34 + kTagSize;  // bytes a sealed blob is larger than its data
inline constexpr std::uint8_t kBlobVersion = 1;

// Encrypts and authenticates `data` into a sealed blob. `aad` (optional) is bound to the blob without being stored: the
// same bytes must be given to `open_blob` (a game can pass the slot number so a file copied into another slot is
// refused). Errors: the system random source failed, or `data` is too large.
Result<std::string> seal_blob(const Key& key, ByteView aad, ByteView data);
inline Result<std::string> seal_blob(const Key& key, ByteView aad, std::string_view data) {
    return seal_blob(key, aad, as_bytes(data));
}

// Verifies and decrypts a blob made by `seal_blob`. Errors say which problem it is: not a sealed blob (wrong magic: a
// plain file), a format version this engine does not know (a file from a newer version), too short (truncated), or the
// data was changed or the key or `aad` is wrong. On any error no data is returned.
Result<std::string> open_blob(const Key& key, ByteView aad, std::string_view blob);

// True when `blob` starts with the sealed-blob magic: lets a loader tell a sealed file from a plain one (a game that
// turns encryption on later still reads the plain saves of its players). It does not check anything else.
bool is_sealed_blob(std::string_view blob);

}  // namespace fa::crypto
