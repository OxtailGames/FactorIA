// The "Play on Phone" window's logic (phone_model.h): the status line, the checklist, the address the QR code shows and a start that
// fails on the helper thread. GPU-free; no server is started (a missing project is refused before any socket opens).
#include <chrono>
#include <string>
#include <thread>

#include "doctest.h"
#include "phone_model.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("phone window: the status line and the QR address") {
    ServeWebStatus st;
    CHECK(phone_state_line(st) == "Not running.");
    st.running = true;
    st.state = "exporting";
    CHECK(phone_state_line(st).find("Exporting") != std::string::npos);
    st.version = 2;
    CHECK(phone_state_line(st).find("Rebuilding") != std::string::npos);
    st.state = "failed";
    st.error = "boom";
    CHECK(phone_state_line(st).find("boom") != std::string::npos);
    st.state = "ready";
    CHECK_FALSE(phone_state_line(st).empty());

    // No LAN address: no QR (a code of 127.0.0.1 would open the phone's own localhost).
    st.localUrl = "http://127.0.0.1:1234/tok/";
    CHECK(phone_qr_url(st, 0).empty());
    st.lanUrls = {"http://192.168.1.5:1234/tok/", "http://10.0.0.7:1234/tok/"};
    CHECK(phone_qr_url(st, 0) == st.lanUrls[0]);
    CHECK(phone_qr_url(st, 1) == st.lanUrls[1]);
    CHECK(phone_qr_url(st, 9) == st.lanUrls[1]);  // out of range: the last address
}

TEST_CASE("phone window: the checklist names the usual causes") {
    std::string all;
    for (const auto& l : phone_help_lines()) all += l + "\n";
    for (const char* word : {"same Wi-Fi", "Windows", "macOS", "firewall", "guest Wi-Fi", "VPN"})
        CHECK_MESSAGE(all.find(word) != std::string::npos, word);
}

TEST_CASE("phone window: a start that fails reports why, once, and the session is free again") {
    PhoneSession session;
    ServeWebOptions o;
    o.projectDir = "/definitely/not/a/factoria/project";
    REQUIRE(session.start(o));
    session.wait();
    std::optional<PhoneSession::Done> done;
    for (int i = 0; i < 600 && !(done = session.take_result()); ++i)
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    REQUIRE(done.has_value());
    CHECK(done->wasStart);
    CHECK_FALSE(done->ok);
    CHECK_FALSE(done->error.empty());
    CHECK_FALSE(session.busy());
    CHECK_FALSE(session.take_result().has_value());
}
