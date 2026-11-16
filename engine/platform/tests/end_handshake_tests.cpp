// EndHandshake: Android's main thread asks the engine's thread to run the game's end and waits for it, bounded.
#include <doctest.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <stdexcept>
#include <thread>

#include "../src/end_handshake.h"

using namespace fa;
using namespace std::chrono_literals;

namespace {
// The engine's thread: sleeps until woken, then serves (what the looper callback of activity_end_android.cpp does).
struct EngineThread {
    EndHandshake& handshake;
    std::function<void()> work;
    std::mutex m;
    std::condition_variable cv;
    bool woken = false;
    std::thread thread;
    EngineThread(EndHandshake& h, std::function<void()> w) : handshake(h), work(std::move(w)) {
        thread = std::thread([this] {
            std::unique_lock<std::mutex> lock(m);
            cv.wait(lock, [this] { return woken; });
            lock.unlock();
            handshake.serve(work);
        });
    }
    bool wake() {
        {
            std::lock_guard<std::mutex> lock(m);
            woken = true;
        }
        cv.notify_all();
        return true;
    }
    ~EngineThread() {
        wake();
        thread.join();
    }
};
}  // namespace

TEST_CASE("end handshake: the engine's thread runs the work once and the request returns when it is done") {
    EndHandshake h;
    std::atomic<int> runs{0};
    std::atomic<bool> ranOnEngineThread{false};
    const std::thread::id caller = std::this_thread::get_id();
    EngineThread engine(h, [&] {
        ++runs;
        ranOnEngineThread = std::this_thread::get_id() != caller;
    });
    // A budget far above what the work takes: it only bounds a broken run.
    CHECK(h.request(10s, [&] { return engine.wake(); }) == EndHandshake::Outcome::Served);
    CHECK(runs == 1);
    CHECK(ranOnEngineThread);
    CHECK(h.served());
    // Asked again (a second destroy, Back after game.quit()): answered at once, without a wake-up and without a second run.
    int wakes = 0;
    CHECK(h.request(10s, [&] { return ++wakes > 0; }) == EndHandshake::Outcome::Served);
    CHECK(wakes == 0);
    CHECK_FALSE(h.serve([&] { ++runs; }));
    CHECK(runs == 1);
}

TEST_CASE("end handshake: an engine thread that does not answer holds the caller for the budget only") {
    EndHandshake h;
    const auto t0 = std::chrono::steady_clock::now();
    CHECK(h.request(30ms, [] { return true; }) == EndHandshake::Outcome::TimedOut);  // woken, never served
    CHECK(std::chrono::steady_clock::now() - t0 >= 30ms);
    CHECK_FALSE(h.served());
    // The work still runs once when the engine's thread gets to it later.
    int runs = 0;
    CHECK(h.serve([&] { ++runs; }));
    CHECK(runs == 1);
    CHECK(h.served());
}

TEST_CASE("end handshake: a work that outlasts the budget times out, and finishes afterwards") {
    EndHandshake h;
    std::mutex gate;
    std::unique_lock<std::mutex> hold(gate);  // the work waits on this until the request has timed out
    std::atomic<bool> finished{false};
    EngineThread engine(h, [&] {
        std::lock_guard<std::mutex> wait(gate);
        finished = true;
    });
    CHECK(h.request(30ms, [&] { return engine.wake(); }) == EndHandshake::Outcome::TimedOut);
    CHECK_FALSE(h.served());
    hold.unlock();
    CHECK(h.request(10s, [] { return true; }) == EndHandshake::Outcome::Served);  // waits for the same run
    CHECK(finished);
}

TEST_CASE("end handshake: a wake-up that fails returns at once and asks nothing") {
    EndHandshake h;
    CHECK(h.request(10s, [] { return false; }) == EndHandshake::Outcome::NotDelivered);
    CHECK(h.request(10s, nullptr) == EndHandshake::Outcome::NotDelivered);
    CHECK_FALSE(h.served());
}

TEST_CASE("end handshake: an exception in the work is swallowed and the waiters are answered") {
    EndHandshake h;
    CHECK(h.serve([] { throw std::runtime_error("boom"); }));
    CHECK(h.served());
    CHECK(h.request(10s, [] { return true; }) == EndHandshake::Outcome::Served);
}
