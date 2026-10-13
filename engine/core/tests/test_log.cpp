#include <doctest.h>

#include <thread>

#include "fa/core/log.h"

using namespace fa;

TEST_CASE("log: ring buffer, sinks, counters") {
    set_log_format(LogFormat::None);
    set_log_level(LogLevel::Debug);
    clear_recent_logs();
    set_log_frame(7);
    int sinkHits = 0;
    int id = add_log_sink([&](const LogEntry& e) { if (e.category == "t") ++sinkHits; });
    FA_INFO("t", "hello {}", 42);
    FA_ERROR("t", "bad");
    FA_TRACE("t", "hidden");  // below the level
    remove_log_sink(id);
    FA_WARN("t", "after sink removed");
    CHECK(sinkHits == 2);
    CHECK(error_count() == 1);

    auto logs = recent_logs();
    REQUIRE(logs.size() == 3);
    CHECK(logs[0].message == "hello 42");
    CHECK(logs[0].frame == 7);
    CHECK(logs[0].seq < logs[1].seq);
    CHECK(logs[1].level == LogLevel::Error);
    CHECK(recent_logs(10, LogLevel::Warn).size() == 2);
    CHECK(recent_logs(10, LogLevel::Trace, logs[1].seq).size() == 1);
    CHECK(recent_logs(1)[0].message == "after sink removed");

    clear_recent_logs();
    CHECK(error_count() == 0);
    CHECK(recent_logs().empty());
    set_log_level(LogLevel::Info);
    set_log_format(LogFormat::Text);
}

TEST_CASE("log: level names and ring capacity") {
    LogLevel l;
    CHECK(parse_log_level("WARN", l));
    CHECK(l == LogLevel::Warn);
    CHECK(!parse_log_level("loud", l));
    CHECK(std::string(log_level_name(LogLevel::Error)) == "error");

    set_log_format(LogFormat::None);
    clear_recent_logs();
    for (int i = 0; i < 5000; ++i) FA_INFO("cap", "{}", i);
    auto all = recent_logs(10000);
    CHECK(all.size() == 4096);
    CHECK(all.back().message == "4999");
    set_log_format(LogFormat::Text);
    clear_recent_logs();
}

TEST_CASE("log: thread safety") {
    set_log_format(LogFormat::None);
    clear_recent_logs();
    std::vector<std::thread> threads;
    for (int t = 0; t < 4; ++t)
        threads.emplace_back([] { for (int i = 0; i < 200; ++i) FA_INFO("mt", "line {}", i); });
    for (auto& t : threads) t.join();
    CHECK(recent_logs(10000).size() == 800);
    set_log_format(LogFormat::Text);
    clear_recent_logs();
}
