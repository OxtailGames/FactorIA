// AppWindowControl: what `window.*` in scripts does to the game window (engine_impl.h).
#include <algorithm>
#include <thread>

#include "engine_impl.h"
#include "fa/platform/app.h"

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace fa {

namespace {

const char* platform_label() {
#if defined(_WIN32)
    return "Windows";
#elif defined(__ANDROID__)
    return "Android";
#elif defined(__APPLE__)
    return app_is_mobile() ? "iOS" : "macOS";
#else
    return "Linux";
#endif
}

constexpr const char* kAlwaysFullscreen = "phones and tablets always run full screen";

// Sleeps about `d`. A plain sleep overshoots by a whole timer tick (15 ms on Windows by default), which would turn a
// 144 fps cap into 64 fps, so Windows uses a high-resolution waitable timer (Windows 10 1803 and later).
void sleep_for(std::chrono::nanoseconds d) {
#if defined(_WIN32)
    static HANDLE timer = CreateWaitableTimerExW(nullptr, nullptr, 0x00000002 /* CREATE_WAITABLE_TIMER_HIGH_RESOLUTION */,
                                                 TIMER_ALL_ACCESS);
    if (timer) {
        LARGE_INTEGER due;
        due.QuadPart = -(d.count() / 100);  // 100 ns units, negative = relative
        if (SetWaitableTimer(timer, &due, 0, nullptr, nullptr, FALSE)) {
            WaitForSingleObject(timer, INFINITE);
            return;
        }
    }
#endif
    std::this_thread::sleep_for(d);
}

}  // namespace

bool AppWindowControl::fullscreen() const { return app_is_fullscreen(); }

void AppWindowControl::size(int& width, int& height) const { app_window_size(width, height); }

void AppWindowControl::display_size(int& width, int& height) const {
    if (!app_display_size(width, height)) app_window_size(width, height);
}

bool AppWindowControl::vsync() const { return app_vsync(); }

std::string AppWindowControl::set_fullscreen(bool on) {
    if (app_is_mobile())
        return on ? std::string()
                  : std::string(kAlwaysFullscreen) + ", so there is no windowed mode to go back to. Hide the full screen option "
                                                     "when window.fullscreen is already true on a phone or tablet.";
    app_set_fullscreen(on);
    return {};
}

std::string AppWindowControl::set_size(int width, int height) {
    if (app_is_mobile())
        return std::string(kAlwaysFullscreen) + ", so there is no window to resize. Offer window.setSize() only on desktop.";
    if (app_is_fullscreen())
        return "the window is full screen. Call window.setFullscreen(false) first, then window.setSize(" + std::to_string(width) +
               ", " + std::to_string(height) + "); or leave full screen as it is and let the game letterbox.";
    if (!app_set_window_size(width, height)) return std::string("this platform (") + platform_label() + ") cannot resize the window.";
    return {};
}

std::string AppWindowControl::set_vsync(bool on) {
    if (!app_set_vsync(on))
        return std::string("vsync cannot be changed while the game runs on ") + platform_label() +
               (app_is_mobile() ? " (the display sets the frame rate)." : " with this graphics driver.") +
               " Set display.vsync in factoria.json instead, and check window.vsync for the value in effect.";
    return {};
}

std::string AppWindowControl::set_frame_cap(int fps) {
    if (app_is_mobile())
        return std::string("the frame rate of phones and tablets follows the display, so a frame cap is not available on ") +
               platform_label() + ". Offer window.frameCap only on desktop.";
    cap_ = std::max(fps, 0);
    return {};
}

void AppWindowControl::throttle() {
    using clock = std::chrono::steady_clock;
    if (cap_ > 0) {
        const auto target = last_ + std::chrono::duration_cast<clock::duration>(std::chrono::duration<double>(1.0 / cap_));
        // Sleep most of the wait, then yield for the rest: the sleep alone is not precise enough.
        for (auto now = clock::now(); now < target; now = clock::now()) {
            const auto left = target - now;
            if (left > std::chrono::milliseconds(2)) sleep_for(left - std::chrono::milliseconds(1));
            else std::this_thread::yield();
        }
    }
    last_ = clock::now();
}

}  // namespace fa
