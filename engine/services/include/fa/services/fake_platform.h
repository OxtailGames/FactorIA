// The fake platform backend: a deterministic, in-memory store for headless runs, `factoria test` and development
// (docs/PLATFORM.md, "The fake backend"). It offers all eight services, keeps everything in memory (nothing reaches a
// real store, nothing is written to disk) and never reads the clock: the same requests always give the same answers.
//
// Test hooks: respond() scripts the next answers of a method (a cancelled purchase, a network error), emit() sends an
// event as the store would, set_signed_in() / set_delay_frames() change how it behaves, state() shows everything it
// holds and every request it got, reset() starts over. The `platform.*` commands and `game.platform` in tests are
// these functions.
#pragma once

#include <deque>
#include <functional>
#include <map>
#include <string>
#include <vector>

#include "fa/services/platform.h"

namespace fa {

class FakeBackend final : public PlatformBackend {
public:
    FakeBackend();

    std::string name() const override { return none_ ? "none" : "fake"; }
    std::vector<std::string> services() const override { return none_ ? std::vector<std::string>{} : platform_services_all(); }
    void attach(const PlatformSink& sink) override { sink_ = sink; }
    void request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) override;
    void frame() override;

    // Queues `times` scripted answers for `method` (first in, first out, one per request). `answer` is
    //   {"error": code, "message"?, "hint"?}   reject with that error (code: one of platform_error_codes())
    //   {"result": value}                      resolve with exactly that value
    //   any other object                       shallow-merged into the default result: {"status": "cancelled"}
    // A scripted answer changes the fake's state only when it is a success the default would also apply: a cancelled
    // purchase owns nothing.
    Result<void> respond(const std::string& method, const Json& answer, int times = 1);
    // Sends an event to the game as the store would. A "purchase" with status "purchased" also records an unfinished
    // transaction (missing transactionId / receipt are made up).
    Result<void> emit(const std::string& event, const Json& data);
    // Takes a purchase back, as a refund does: the product leaves restore() (and its unfinished transaction is dropped), and
    // the game gets the "purchase" event a real backend sends: {status: "revoked", productId, transactionId, receipt}. A
    // product the player does not own (and no unfinished transaction of it) is an error naming the owned ones.
    Result<void> revoke(const std::string& productId);
    // Fresh state: signed in, no delay, nothing scripted, nothing unlocked or bought, an empty request log; transactions
    // and integrity tokens are numbered from 1 again.
    void reset();
    // Not signed in: every method but player.signIn answers "notSignedIn". Sends a `player` event when it changes.
    void set_signed_in(bool signedIn);
    bool signed_in() const { return signedIn_; }
    // Behave as the "none" backend (no service, every call rejects `unavailable`, signIn answers signed out) until reset().
    // Call PlatformServices::refresh_backend() afterwards so `has` follows.
    void set_none(bool none) { none_ = none; }
    // Answers are held for this many engine frames (0 = answered inside request, so a promise resolves at once).
    void set_delay_frames(int frames);
    int delay_frames() const { return delay_; }

    // {player, signedIn, delayFrames, frame, achievements: {id: {unlocked, progress}}, stats: {id: value},
    //  leaderboards: {id: best}, cloud: {key: text}, owned: [productId], unfinished: [{transactionId, productId, receipt}],
    //  presence: {text, data}, scripted: {method: queued}, held: n, calls: [{seq, frame, method, args, answered, ok?,
    //  result? | error?, scripted?}], callsDropped}. `frame` counts frames since the fake was made or reset.
    Json state() const;

private:
    struct Outcome {
        bool ok = true;
        Json result;
        PlatformError error;
        std::function<void(const Json& finalResult)> commit;  // applies the state change, given the answer that is sent
    };
    struct Scripted {
        Json answer;
        int times = 1;
    };
    struct Held {
        std::uint64_t id, seq, due;
        std::string method;
        Json args;
    };
    struct Achievement {
        bool unlocked = false;
        double progress = 0.0;
    };
    struct Transaction {
        std::string transactionId, productId, receipt;
    };

    void answer(std::uint64_t id, std::uint64_t seq, const std::string& method, const Json& args);
    Outcome compute(const std::string& method, const Json& args);
    Json* log_entry(std::uint64_t seq);

    PlatformSink sink_;
    bool signedIn_ = true;
    bool none_ = false;
    int delay_ = 0;
    std::uint64_t frames_ = 0, seq_ = 0, nextTx_ = 1, nextIntegrity_ = 1, callsDropped_ = 0;
    std::map<std::string, std::deque<Scripted>> scripted_;
    std::vector<Held> held_;
    std::map<std::string, Achievement> achievements_;
    std::map<std::string, double> stats_;
    std::map<std::string, long long> bests_;
    std::map<std::string, std::string> cloud_;
    std::map<std::string, Transaction> owned_;  // by product id: non-consumables and subscriptions
    std::vector<Transaction> unfinished_;
    Json presence_;
    std::deque<Json> log_;
};

}  // namespace fa
