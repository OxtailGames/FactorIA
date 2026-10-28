#include <atomic>
#include <chrono>
#include <mutex>
#include <thread>

#include "fa/ai/progress_file.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

TEST_CASE("progress file: the tail delivers what is appended after it started, in order") {
    TempDir dir;
    append_progress_line(dir.str(), "left over from an earlier run");
    std::mutex mu;
    std::vector<std::string> got;
    {
        ProgressTail tail(dir.str(), [&](const std::string& l) {
            std::lock_guard<std::mutex> lock(mu);
            got.push_back(l);
        }, 20);
        append_progress_line(dir.str(), "worker: starting");
        append_progress_line(dir.str(), "worker > running Bash\n(two lines)");
        for (int i = 0; i < 100; ++i) {
            {
                std::lock_guard<std::mutex> lock(mu);
                if (got.size() >= 2) break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
        }
        append_progress_line(dir.str(), "worker: finished");  // delivered by the destructor's last look
    }
    REQUIRE(got.size() == 3);
    CHECK(got[0] == "worker: starting");
    CHECK(got[1] == "worker > running Bash (two lines)");
    CHECK(got[2] == "worker: finished");
}
