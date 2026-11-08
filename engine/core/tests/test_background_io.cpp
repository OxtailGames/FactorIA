// The background IO queue (fa/core/background_io.h): the same results with the pool stopped, inline, 0, 1 and 8 workers,
// cancel, two queues kept apart, and the IO thread that ends with its last queue. No sleeps: waits are on state.
#include <doctest.h>

#include <atomic>
#include <condition_variable>
#include <filesystem>
#include <fstream>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/background_io.h"
#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/core/load_trace.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct PoolScope {
    explicit PoolScope(const jobs::Settings& s) { REQUIRE(jobs::start(s).ok()); }
    ~PoolScope() { jobs::stop(); }
    PoolScope(const PoolScope&) = delete;
    PoolScope& operator=(const PoolScope&) = delete;
};

// An item that "reads" `n` and decodes it into n * n (no file: the queue does not care what a read is).
IoQueue::Ticket submit_square(IoQueue& q, int n) {
    return q.submit([n]() -> Result<IoFile> { return IoFile{"item" + std::to_string(n), {}}; },
                    [n](IoFile& f) -> IoResult {
                        IoResult r;
                        r.ok = f.path == "item" + std::to_string(n);
                        r.value = std::make_shared<int>(n * n);
                        r.bytes = std::uint64_t(n);
                        return r;
                    });
}

std::vector<int> squares(IoQueue& q, int count) {
    std::vector<IoQueue::Ticket> tickets;
    for (int i = 0; i < count; ++i) tickets.push_back(submit_square(q, i));
    std::vector<int> out;
    for (IoQueue::Ticket t : tickets) {
        IoResult r = q.take(t);
        out.push_back(r.ok && r.value ? *std::static_pointer_cast<int>(r.value) : -1);
    }
    return out;
}

// A gate the test opens: an item's read waits on it, so the test knows the IO thread is inside that read.
struct Gate {
    std::mutex mu;
    std::condition_variable cv;
    bool entered = false, open = false;
    void enter_and_wait() {
        std::unique_lock<std::mutex> lock(mu);
        entered = true;
        cv.notify_all();
        cv.wait(lock, [&] { return open; });
    }
    void wait_entered() {
        std::unique_lock<std::mutex> lock(mu);
        cv.wait(lock, [&] { return entered; });
    }
    void release() {
        std::lock_guard<std::mutex> lock(mu);
        open = true;
        cv.notify_all();
    }
};

}  // namespace

TEST_CASE("background io: the same results with the pool stopped, inline, 0, 1 and 8 workers") {
    std::vector<int> expected;
    for (int i = 0; i < 40; ++i) expected.push_back(i * i);
    {
        IoQueue q(nullptr, LoadTrace::kNoOwner);  // the pool is stopped
        CHECK_FALSE(q.threaded());
        CHECK(squares(q, 40) == expected);
    }
    for (const jobs::Settings& s : {jobs::Settings::inline_jobs(), jobs::Settings::threads(0), jobs::Settings::threads(1),
                                    jobs::Settings::threads(8)}) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        jobs::Owner owner("io test");
        {
            IoQueue q(&owner, LoadTrace::kNoOwner);
            CHECK(q.threaded() == (jobs::worker_count() > 0));
            CHECK(squares(q, 40) == expected);
            CHECK(q.queued() == 0);
        }
        REQUIRE(owner.wait().ok());
        CHECK_FALSE(IoQueue::io_thread_running());  // the last queue is gone: so is the thread
    }
}

TEST_CASE("background io: a queue that is not threaded is never ready and does the work in take()") {
    IoQueue q(nullptr, LoadTrace::kNoOwner);
    const IoQueue::Ticket t = submit_square(q, 7);
    CHECK_FALSE(q.ready(t));
    CHECK(q.queued() == 1);
    IoResult r = q.take(t);
    REQUIRE(r.ok);
    CHECK(*std::static_pointer_cast<int>(r.value) == 49);
    CHECK(r.bytes == 7);
    CHECK(q.ready(t));  // unknown now: taken
    CHECK_FALSE(q.take(t).ok);
    CHECK_FALSE(IoQueue::io_thread_running());
}

TEST_CASE("background io: errors of the read and the decode come back with their hint") {
    IoQueue q(nullptr, LoadTrace::kNoOwner);
    const IoQueue::Ticket a = q.submit([]() -> Result<IoFile> { return make_error("no such file 'x.png'", "Check the path."); },
                                       [](IoFile&) { return IoResult{true}; });
    const IoQueue::Ticket b = q.submit([]() -> Result<IoFile> { return IoFile{"y.png", {}}; },
                                       [](IoFile&) -> IoResult {
                                           IoResult r;
                                           r.error = "not a PNG";
                                           r.hint = "Export it again.";
                                           return r;
                                       });
    IoResult ra = q.take(a);
    CHECK_FALSE(ra.ok);
    CHECK(ra.error == "no such file 'x.png'");
    CHECK(ra.hint == "Check the path.");
    IoResult rb = q.take(b);
    CHECK_FALSE(rb.ok);
    CHECK(rb.hint == "Export it again.");
}

TEST_CASE("background io: cancel drops an item; cancel_all waits for the read in progress") {
    if (!jobs::threads_supported()) return;
    PoolScope pool(jobs::Settings::threads(2));
    jobs::Owner owner("io cancel");
    {
        IoQueue q(&owner, LoadTrace::kNoOwner);
        REQUIRE(q.threaded());
        auto gate = std::make_shared<Gate>();
        std::atomic<int> decoded{0};
        const IoQueue::Ticket blocked = q.submit(
            [gate]() -> Result<IoFile> {
                gate->enter_and_wait();
                return IoFile{"slow", {}};
            },
            [&decoded](IoFile&) {
                decoded++;
                return IoResult{true};
            });
        const IoQueue::Ticket later = submit_square(q, 3);
        gate->wait_entered();  // the IO thread is in the first read
        CHECK_FALSE(q.ready(blocked));
        q.cancel(later);  // never started: gone at once
        CHECK(q.queued() == 1);
        q.cancel(blocked);  // the read goes on and its result is thrown away
        gate->release();
        q.cancel_all();
        CHECK(q.queued() == 0);
        REQUIRE(owner.wait().ok());
        CHECK(decoded.load() == 0);  // a cancelled item is not decoded
    }
    REQUIRE(owner.wait().ok());
}

TEST_CASE("background io: two queues of two owners keep their items apart") {
    for (const jobs::Settings& s : {jobs::Settings::threads(0), jobs::Settings::threads(3)}) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        jobs::Owner ownerA("io a"), ownerB("io b");
        {
            IoQueue a(&ownerA, LoadTrace::new_owner());
            IoQueue b(&ownerB, LoadTrace::new_owner());
            std::vector<IoQueue::Ticket> ta, tb;
            for (int i = 0; i < 20; ++i) {
                ta.push_back(submit_square(a, i));
                tb.push_back(submit_square(b, 100 + i));
            }
            CHECK(a.queued() == 20);
            CHECK(b.queued() == 20);
            for (int i = 0; i < 20; ++i) {
                IoResult rb = b.take(tb[std::size_t(i)]);
                IoResult ra = a.take(ta[std::size_t(i)]);
                REQUIRE(ra.ok);
                REQUIRE(rb.ok);
                CHECK(*std::static_pointer_cast<int>(ra.value) == i * i);
                CHECK(*std::static_pointer_cast<int>(rb.value) == (100 + i) * (100 + i));
            }
            b.cancel_all();  // one queue's cancel leaves the other alone
            const IoQueue::Ticket t = submit_square(a, 5);
            CHECK(*std::static_pointer_cast<int>(a.take(t).value) == 25);
        }
        REQUIRE(ownerA.wait().ok());
        REQUIRE(ownerB.wait().ok());
    }
}

TEST_CASE("background io: reads ahead go to the load trace's totals, and the files an item read come with its result") {
    const stdfs::path dir = fs::make_temp_dir("fa_background_io");
    stdfs::create_directories(dir / "assets");
    std::ofstream(dir / "assets" / "a.txt", std::ios::binary) << "hello";
    const stdfs::path oldRoot = fs::project_root();
    fs::set_project_root(dir);
    for (const jobs::Settings& s : {jobs::Settings::threads(0), jobs::Settings::threads(2)}) {
        CAPTURE(s.describe());
        PoolScope pool(s);
        jobs::Owner owner("io trace");
        const LoadTrace::Owner reader = LoadTrace::new_owner();
        LoadTrace trace(reader);
        {
            const LoadTrace::ReadingFor reading(reader);
            trace.scene_started("scenes/main.scene.json");
        }
        {
            IoQueue q(&owner, reader);
            const IoQueue::Ticket t = q.submit(
                [] {
                    if (auto w = fs::warm("assets/a.txt"); !w) return Result<IoFile>(w.error());
                    auto v = fs::read_view("assets/a.txt");
                    if (!v) return Result<IoFile>(v.error());
                    return Result<IoFile>(IoFile{"assets/a.txt", std::move(v.value())});
                },
                [](IoFile& f) {
                    IoResult r;
                    r.ok = f.view.size() == 5;
                    return r;
                },
                /*traceTag=*/42);
            IoResult r = q.take(t);
            REQUIRE(r.ok);
            CHECK(r.bytes == 5);
            REQUIRE(r.files.size() == 1);
            CHECK(r.files[0] == "assets/a.txt");
        }
        REQUIRE(owner.wait().ok());
        // Read ahead: counted, but not in the first-use order until something uses it.
        CHECK(trace.report()["reads"]["count"].get<int>() >= 1);
        bool listed = false;
        for (const SceneFiles& sf : trace.order())
            for (const std::string& f : sf.files) listed = listed || f == "assets/a.txt";
        CHECK_FALSE(listed);
        {
            const LoadTrace::ReadingFor reading(reader);
            LoadTrace::file_used("assets/a.txt");
        }
        listed = false;
        for (const SceneFiles& sf : trace.order())
            for (const std::string& f : sf.files) listed = listed || f == "assets/a.txt";
        CHECK(listed);
        fs::unwarm_all();
    }
    fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}
