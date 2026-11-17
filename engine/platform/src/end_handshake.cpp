// EndHandshake: see end_handshake.h.
#include "end_handshake.h"

#include <exception>

#include "fa/core/log.h"

namespace fa {

EndHandshake::Outcome EndHandshake::request(std::chrono::milliseconds budget, const std::function<bool()>& wake) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (state_ == State::Done) return Outcome::Served;
    }
    // Outside the lock: the wake-up may block briefly (a pipe write, a looper wake), and serve() needs the lock.
    if (!wake || !wake()) return Outcome::NotDelivered;
    std::unique_lock<std::mutex> lock(mutex_);
    return done_.wait_for(lock, budget, [this] { return state_ == State::Done; }) ? Outcome::Served : Outcome::TimedOut;
}

bool EndHandshake::serve(const std::function<void()>& work) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (state_ != State::Idle) return false;
        state_ = State::Running;
    }
    try {
        if (work) work();
    } catch (const std::exception& e) {
        FA_ERROR("platform", "the app's end stopped early: {}", e.what());
    } catch (...) {
        FA_ERROR("platform", "the app's end stopped early: an unknown exception");
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        state_ = State::Done;
    }
    done_.notify_all();
    return true;
}

bool EndHandshake::served() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_ == State::Done;
}

}  // namespace fa
