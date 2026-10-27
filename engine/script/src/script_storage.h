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

#include "fa/core/json.h"

namespace fa::storage_files {

// <user dir>/storage
std::filesystem::path dir();
// The file name of a key: lowercase letters, digits, '_' and '-' are kept, every other byte is written as %XX (so two keys
// never share a file, even on a case-insensitive disk), then ".json". A very long key keeps its first characters and ends
// in a hash of the whole key; a name Windows reserves (con, nul, com1...) has its first letter escaped.
std::string file_name(const std::string& key);

// What a key's file holds. Plain:      {"key": "slot1", "value": <the value>}
//                       Compressed: {"key": "slot1", "z": "zlib", "n": <size of the value's JSON text>, "data": "<base64>"}
std::string encode(const std::string& key, const std::string& valueText, bool compress);
struct Decoded {
    std::string key;
    Json value;
    bool compressed = false;
};
// Reads a key file's text. On failure `problem` says what is wrong.
bool decode(const std::string& text, Decoded& out, std::string& problem);

// One write that setAsync asked for.
struct Job {
    int id = 0;
    std::string key;
    std::string valueText;  // the value as compact JSON, made on the main thread
    bool compress = false;
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
