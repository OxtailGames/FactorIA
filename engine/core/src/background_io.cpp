#include "fa/core/background_io.h"

#include <algorithm>
#include <condition_variable>
#include <deque>
#include <exception>
#include <map>
#include <mutex>
#include <new>
#include <thread>

#include "fa/core/jobs.h"

namespace fa {
namespace {

enum class ItemState { Queued, Reading, Decoding, Done };

struct Item {
    IoQueue::Ticket id = 0;
    IoRead read;
    IoDecode decode;
    std::uint64_t tag = 0;
    LoadTrace::Owner traceOwner = LoadTrace::kNoOwner;
    jobs::Owner* jobsOwner = nullptr;
    ItemState state = ItemState::Queued;
    bool cancelled = false;
    IoFile file;
    std::vector<std::string> files;
    IoResult result;
    jobs::Handle handle;
};
using ItemPtr = std::shared_ptr<Item>;

// Every queue's shared state lives under one mutex: the IO thread moves between them, and the lock is held only to pick
// or settle an item, never during a read or a decode.
struct Shared {
    std::mutex mu;
    std::condition_variable work;  // the IO thread waits here for items
    std::condition_variable done;  // takers wait here for an item the IO thread is reading
    std::vector<IoQueue::State*> queues;
    std::size_t next = 0;  // round robin between the queues
    std::thread thread;
    bool running = false;
    std::uint64_t generation = 0;  // a thread runs while it is the generation it was started for
};

Shared& shared() {
    static Shared* s = new Shared();  // never destroyed: the IO thread may outlive static destruction order
    return *s;
}

}  // namespace

struct IoQueue::State {
    jobs::Owner* jobs = nullptr;
    LoadTrace::Owner traceOwner = LoadTrace::kNoOwner;
    std::deque<ItemPtr> pending;     // not started yet, in submit order
    std::map<Ticket, ItemPtr> items;  // every item not taken or cancelled
    int reading = 0;                  // items the IO thread is reading now
    Ticket nextTicket = 1;
};

namespace {

void settle(Item& item, IoResult result) {
    result.files.insert(result.files.begin(), item.files.begin(), item.files.end());
    // Each file once, in the order it was first read or used.
    std::vector<std::string> unique;
    for (std::string& f : result.files)
        if (std::find(unique.begin(), unique.end(), f) == unique.end()) unique.push_back(std::move(f));
    result.files = std::move(unique);
    item.result = std::move(result);
    item.file = IoFile{};
}

IoResult failure(std::string message, std::string hint = {}) {
    IoResult r;
    r.error = std::move(message);
    r.hint = std::move(hint);
    return r;
}

// The read of `item` on this thread; false when it failed (the result is then set).
bool run_read(Item& item) {
    const LoadTrace::ReadingFor reading(item.traceOwner, item.tag);
    const LoadTrace::FileCollector collect(&item.files);
    try {
        Result<IoFile> f = item.read ? item.read() : Result<IoFile>(IoFile{});
        if (!f) {
            settle(item, failure(f.error().message, f.error().hint));
            return false;
        }
        item.file = std::move(f.value());
        return true;
    } catch (const std::bad_alloc&) {
        settle(item, failure("out of memory while reading '" + item.file.path + "'", "Load fewer or smaller files at once."));
    } catch (const std::exception& e) {
        settle(item, failure(std::string("the read failed: ") + e.what()));
    }
    return false;
}

void run_decode(Item& item) {
    const LoadTrace::ReadingFor reading(item.traceOwner, item.tag);
    const LoadTrace::FileCollector collect(&item.files);
    IoResult r;
    try {
        const std::uint64_t readBytes = item.file.view.size();
        r = item.decode ? item.decode(item.file) : IoResult{true};
        r.bytes = std::max(r.bytes, readBytes);
    } catch (const std::bad_alloc&) {
        r = failure("out of memory while decoding '" + item.file.path + "'", "Load fewer or smaller files at once.");
    } catch (const std::exception& e) {
        r = failure("decoding '" + item.file.path + "' failed: " + e.what());
    }
    settle(item, std::move(r));
}

// The decode of an item the IO thread has read: a job of the queue's owner (it runs at once when the pool does not).
void start_decode(const ItemPtr& item) {
    const jobs::OwnerScope scope(item->jobsOwner);
    jobs::Handle h = jobs::submit("io.decode", [item] {
        bool skip = false;
        {
            std::lock_guard<std::mutex> lock(shared().mu);
            skip = item->cancelled;
        }
        if (skip) settle(*item, IoResult{false, true});
        else run_decode(*item);
        std::lock_guard<std::mutex> lock(shared().mu);
        item->state = ItemState::Done;
        shared().done.notify_all();
    });
    std::lock_guard<std::mutex> lock(shared().mu);
    if (item->state != ItemState::Done) {
        item->state = ItemState::Decoding;
        item->handle = h;
    }
}

void io_thread_main(std::uint64_t generation) {
    Shared& s = shared();
    std::unique_lock<std::mutex> lock(s.mu);
    while (s.generation == generation) {
        ItemPtr item;
        IoQueue::State* from = nullptr;
        for (std::size_t i = 0; i < s.queues.size() && !item; ++i) {
            IoQueue::State* q = s.queues[(s.next + i) % s.queues.size()];
            if (q->pending.empty()) continue;
            item = q->pending.front();
            q->pending.pop_front();
            from = q;
            s.next = (s.next + i + 1) % s.queues.size();
        }
        if (!item) {
            s.work.wait(lock);
            continue;
        }
        item->state = ItemState::Reading;
        from->reading++;
        lock.unlock();
        const bool read = run_read(*item);
        lock.lock();
        const bool decode = read && !item->cancelled;
        if (!decode) {
            if (read) settle(*item, IoResult{false, true});
            item->state = ItemState::Done;
        }
        lock.unlock();
        // The decode is queued before this queue lets go (reading--): cancel_all() returns only after it, so the engine's
        // wait on its jobs owner sees the job.
        if (decode) start_decode(item);
        lock.lock();
        from->reading--;
        s.done.notify_all();
    }
}

}  // namespace

IoQueue::IoQueue(jobs::Owner* jobsOwner, LoadTrace::Owner traceOwner) : state_(std::make_shared<State>()) {
    state_->jobs = jobsOwner;
    state_->traceOwner = traceOwner;
#ifndef __EMSCRIPTEN__
    threaded_ = jobs::running() && !jobs::inline_mode() && jobs::worker_count() > 0;
#endif
    if (!threaded_) return;
    std::lock_guard<std::mutex> lock(shared().mu);
    shared().queues.push_back(state_.get());
}

IoQueue::~IoQueue() {
    cancel_all();
    if (!threaded_) return;
    Shared& s = shared();
    std::thread joinMe;
    {
        std::lock_guard<std::mutex> lock(s.mu);
        s.queues.erase(std::remove(s.queues.begin(), s.queues.end(), state_.get()), s.queues.end());
        s.next = 0;
        if (s.queues.empty() && s.running) {  // the last queue: the thread ends (a later queue starts a new one)
            ++s.generation;
            s.running = false;
            joinMe = std::move(s.thread);
            s.work.notify_all();
        }
    }
    if (joinMe.joinable()) joinMe.join();
}

IoQueue::Ticket IoQueue::submit(IoRead read, IoDecode decode, std::uint64_t traceTag) {
    auto item = std::make_shared<Item>();
    item->read = std::move(read);
    item->decode = std::move(decode);
    item->tag = traceTag;
    item->traceOwner = state_->traceOwner;
    item->jobsOwner = state_->jobs;
    Shared& s = shared();
    std::lock_guard<std::mutex> lock(s.mu);
    item->id = state_->nextTicket++;
    state_->items[item->id] = item;
    if (!threaded_) return item->id;  // done by take()
    state_->pending.push_back(item);
    if (!s.running) {
        s.running = true;
        s.thread = std::thread(io_thread_main, s.generation);
    }
    s.work.notify_one();
    return item->id;
}

bool IoQueue::ready(Ticket t) const {
    std::lock_guard<std::mutex> lock(shared().mu);
    auto it = state_->items.find(t);
    return it == state_->items.end() || it->second->state == ItemState::Done;
}

std::size_t IoQueue::queued() const {
    std::lock_guard<std::mutex> lock(shared().mu);
    return state_->items.size();
}

IoResult IoQueue::take(Ticket t) {
    Shared& s = shared();
    std::unique_lock<std::mutex> lock(s.mu);
    auto it = state_->items.find(t);
    if (it == state_->items.end()) return failure("no background read with this ticket (taken or cancelled already)");
    ItemPtr item = it->second;
    for (;;) {
        if (item->state == ItemState::Done) break;
        if (item->state == ItemState::Queued) {  // not started: do it here, now
            auto p = std::find(state_->pending.begin(), state_->pending.end(), item);
            if (p != state_->pending.end()) state_->pending.erase(p);
            item->state = ItemState::Reading;
            lock.unlock();
            if (run_read(*item)) run_decode(*item);
            lock.lock();
            item->state = ItemState::Done;
            break;
        }
        if (item->state == ItemState::Decoding && item->handle.valid()) {
            jobs::Handle h = item->handle;
            lock.unlock();
            (void)jobs::wait(h);  // runs the decode here when no worker has picked it up yet
            lock.lock();
            continue;
        }
        s.done.wait(lock);  // the IO thread is reading it (or queuing its decode)
    }
    state_->items.erase(item->id);
    return std::move(item->result);
}

void IoQueue::cancel(Ticket t) {
    std::lock_guard<std::mutex> lock(shared().mu);
    auto it = state_->items.find(t);
    if (it == state_->items.end()) return;
    ItemPtr item = it->second;
    item->cancelled = true;
    auto p = std::find(state_->pending.begin(), state_->pending.end(), item);
    if (p != state_->pending.end()) state_->pending.erase(p);
    state_->items.erase(it);
}

void IoQueue::cancel_all() {
    Shared& s = shared();
    std::unique_lock<std::mutex> lock(s.mu);
    for (auto& [id, item] : state_->items) item->cancelled = true;
    state_->items.clear();
    state_->pending.clear();
    s.done.wait(lock, [&] { return state_->reading == 0; });
}

bool IoQueue::io_thread_running() {
    std::lock_guard<std::mutex> lock(shared().mu);
    return shared().running;
}

}  // namespace fa
