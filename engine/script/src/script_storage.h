// The files behind `storage.*`: one JSON file per key in <user dir>/storage/, and the writer that setAsync uses.
// Private to the script module.
#pragma once

#include <condition_variable>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/crypto.h"
#include "fa/core/json.h"

namespace fa::storage_files {

// <user dir>/storage
std::filesystem::path dir();
// The file name of a key: lowercase letters, digits, '_' and '-' are kept, every other byte is written as %XX (so two keys
// never share a file, even on a case-insensitive disk), then ".json". A very long key keeps its first characters and ends
// in a hash of the whole key; a name Windows reserves (con, nul, com1...) has its first letter escaped.
std::string file_name(const std::string& key);

// What the encryption key of a value is made of: the project's secret (factoria.json "storage"."encryptionSecret", empty
// when the project has none) and the game id that salts it.
struct KeyMaterial {
    std::string secret;
    std::string gameId;
};
// The key that seals the value of storage key `key`: HKDF-SHA256 over the secret, salted with the game id, with
// "factoria.storage.v1:" + key as the context, so a file copied under another key (or into another game) does not open.
// An Error that teaches when the project has no secret (or one that is too short to be a random value).
Result<crypto::Key> derive_key(const KeyMaterial& material, const std::string& key);

// What a key's file holds. Plain:      {"key": "slot1", "value": <the value>}
//                       Compressed: {"key": "slot1", "z": "zlib", "n": <size of the value's JSON text>, "data": "<base64>"}
//                       Encrypted:  {"key": "slot1", "enc": "chacha20poly1305", "z"?: "zlib", "n"?: ..., "data": "<base64 of a
//                                    crypto.h sealed blob of the value's JSON text (zlib-compressed when "z")>"}
// `sealKey` non-null seals the value (a fresh random salt and nonce each time); the blob's associated data is "zlib" or
// "json", so the unauthenticated "z" flag cannot be flipped without the file failing to open. An Error only when the
// operating system's random source fails.
Result<std::string> encode(const std::string& key, const std::string& valueText, bool compress,
                           const crypto::Key* sealKey = nullptr);
struct Decoded {
    std::string key;
    Json value;
    bool compressed = false;
    bool encrypted = false;
};
// Reads a key file's text. On failure `problem` says what is wrong. An encrypted file needs `material` (null = a reader that
// cannot decrypt, like a listing of damaged files that does not care); a file that fails authentication is "damaged".
bool decode(const std::string& text, Decoded& out, std::string& problem, const KeyMaterial* material = nullptr);

// One write that setAsync asked for.
struct Job {
    int id = 0;
    std::string key;
    std::string valueText;  // the value as compact JSON, made on the main thread
    bool compress = false;
    bool encrypt = false;
    crypto::Key sealKey{};  // when `encrypt`: derived on the main thread (derive_key); zeroed once the job has run
    bool persist = false;   // false: nothing goes to disk (memory storage); the job only measures its size
    std::filesystem::path file;
    // result
    bool ok = true;
    std::string error;
    std::size_t bytes = 0;  // size of the key's file
};

// Runs jobs one after another, in the order they were submitted. With a worker thread (desktop and mobile, persistent
// storage) they run beside the game; without one (the web has no threads, and memory storage has nothing to wait for)
// they run in pump(), which the engine calls between frames.
class Writer {
public:
    Writer() = default;
    ~Writer();
    Writer(const Writer&) = delete;
    Writer& operator=(const Writer&) = delete;

    void submit(Job job, bool threaded);
    // Runs the jobs that wait and no worker owns (no-op when the worker has them).
    void pump();
    // Returns once every submitted job has run.
    void drain();
    // Jobs that finished since the last call, in submit order.
    std::vector<Job> take_done();
    bool idle();

private:
    void run(Job& job);
    void worker_main();

    std::mutex mutex_;
    std::condition_variable wake_, idleCv_;
    std::deque<Job> queue_;
    std::vector<Job> done_;
    std::thread worker_;
    bool stop_ = false;
    bool busy_ = false;
    bool workerMode_ = false;
};

}  // namespace fa::storage_files
