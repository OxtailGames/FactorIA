// Background file loading: an IO thread that reads files and hands their bytes to decode jobs (docs/ARCHITECTURE.md,
// "Background loading"; docs/PERFORMANCE.md, "Background loading").
//
// Each Engine owns one IoQueue (its jobs owner and its load-trace owner go with it). The IO THREAD is shared by the
// process: one thread serves the queues of every engine in turn (round robin, one file at a time), so two engines that
// load at once both move on and never see each other's files. It exists only while a threaded queue lives and has had
// work: a game that never loads in the background starts no thread.
//
// An item is a READ (on the IO thread: through fa::fs, so a game.pak, an APK or a warm file answer it like any read)
// followed by a DECODE (a job of the queue's jobs owner: PNG/KTX2 to pixels, glTF to vertices, a sound to samples, JSON
// to a tree). Its result waits until the owner takes it on the main thread (take()), which also uploads it to the GPU
// or adopts it into a cache: that part is never done here.
//
// Threaded or not: a queue made while the job pool runs with at least one worker thread (fa/core/jobs.h) is THREADED:
// reads and decodes run while the main thread does other things, and ready() tells whether take() would wait. Without
// workers (0 workers, inline mode, a stopped pool, the web) there is no IO thread: take() does the read and the decode
// itself, on the calling thread. Either way take() returns the same result, so what a game computes does not depend
// on it; only how long frames take does. take() of an item the IO thread has not started yet does it on the calling
// thread at once (no waiting behind other files), so it never deadlocks, also with 0 workers.
//
// The load trace (fa/core/load_trace.h): the read and the decode run in a ReadingFor(traceOwner, traceTag) scope, so
// they are the owner's reads, read AHEAD for the background load `traceTag`; the project files an item read or used are
// in its result (IoResult::files, collected only while a trace exists) for the user to report with
// LoadTrace::file_used() when it first uses the asset.
//
// Cancelling: cancel() drops an item (a decode already running finishes and is thrown away); cancel_all() drops every
// item and returns once the IO thread has let go of this queue's files, so the engine can then wait for its jobs owner
// and shut down (the decode jobs still running belong to that owner). Thread-safe, except that take(), cancel() and
// cancel_all() of one queue are meant for its owner's thread.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/load_trace.h"
#include "fa/core/types.h"

namespace fa {

namespace jobs {
class Owner;
}

// The file an item read: `path` is the file that was read (a compressed twin, e.g. "a.png.ktx2", when the reader chose it).
struct IoFile {
    std::string path;
    fs::FileView view;
};

struct IoResult {
    bool ok = false;
    bool cancelled = false;
    std::string error, hint;         // ok == false: why, and how to fix it
    std::shared_ptr<void> value;     // what the decode made (its type is the submitter's)
    std::uint64_t bytes = 0;         // bytes read (the decode may set more: the files it read itself)
    std::vector<std::string> files;  // project files the item read or used, in order (only while a load trace exists)
};

// Runs on the IO thread (or the thread that takes the item): reads the item's file.
using IoRead = std::function<Result<IoFile>()>;
// Runs as a job (or on the thread that takes the item): turns the file into the item's value. It may read more files
// through fa::fs (a glTF's buffers). It must not touch anything only the main thread may (the GPU, an engine's caches).
using IoDecode = std::function<IoResult(IoFile& file)>;

class IoQueue {
public:
    using Ticket = std::uint64_t;

    // `jobs`: the owner of the decode jobs (null: none, the jobs are nobody's). `traceOwner`: whose reads they are.
    IoQueue(jobs::Owner* jobs, LoadTrace::Owner traceOwner);
    ~IoQueue();  // cancel_all()
    IoQueue(const IoQueue&) = delete;
    IoQueue& operator=(const IoQueue&) = delete;

    // Queues an item; the IO thread starts on it in submit order (per queue). `traceTag`: the background load it is for
    // (0: none). A decode that returns ok == false keeps its error; `read` failing gives its error and hint.
    Ticket submit(IoRead read, IoDecode decode, std::uint64_t traceTag = 0);
    // The read and decode of `t` are done (always false for a queue that is not threaded until it is taken; true for an
    // unknown ticket).
    bool ready(Ticket t) const;
    // The result of `t`, doing the work now when it has not started, else waiting for it. Forgets the ticket. An unknown
    // ticket gives ok == false.
    IoResult take(Ticket t);
    void cancel(Ticket t);
    void cancel_all();

    bool threaded() const { return threaded_; }
    std::size_t queued() const;  // items submitted and not taken or cancelled yet

    // The IO thread exists now (tests: a game that never loads in the background starts none).
    static bool io_thread_running();

    struct State;

private:
    std::shared_ptr<State> state_;
    bool threaded_ = false;
};

}  // namespace fa
