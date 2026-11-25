// Who makes the window's swapchain (fa/platform/app.h, M77-P9e1): the platform's own (sokol_app's; the D3D11 presenter
// on Windows) or a D3D12 or Vulkan device that claims the native window. The rule is pure, so every platform checks it.
#include <doctest.h>

#include <string>

#include "fa/platform/app.h"

using namespace fa;

namespace {
WindowPresenterStep step(WindowPresenter now, WindowPresenterEvent event, bool inUse = false,
                         const std::string& busy = "") {
    return window_presenter_step(now, event, inUse, busy);
}
}  // namespace

TEST_CASE("window presenter: names") {
    CHECK(std::string(window_presenter_name(WindowPresenter::Unclaimed)) == "none");
    CHECK(std::string(window_presenter_name(WindowPresenter::Platform)) == "platform");
    CHECK(std::string(window_presenter_name(WindowPresenter::Device)) == "device");
}

TEST_CASE("window presenter: the platform's swapchain is marked on the first ask") {
    const WindowPresenterStep first = step(WindowPresenter::Unclaimed, WindowPresenterEvent::PlatformAsked);
    CHECK(first.error.empty());
    CHECK_FALSE(first.releasePlatform);
    CHECK(first.next == WindowPresenter::Platform);
    const WindowPresenterStep again = step(WindowPresenter::Platform, WindowPresenterEvent::PlatformAsked, true);
    CHECK(again.error.empty());
    CHECK(again.next == WindowPresenter::Platform);
}

TEST_CASE("window presenter: a device claims an unused window and the platform's swapchain goes first") {
    const WindowPresenterStep fromNone = step(WindowPresenter::Unclaimed, WindowPresenterEvent::DeviceClaim);
    CHECK(fromNone.error.empty());
    CHECK_FALSE(fromNone.releasePlatform);  // nothing made yet: nothing to release
    CHECK(fromNone.next == WindowPresenter::Device);
    const WindowPresenterStep fromPlatform = step(WindowPresenter::Platform, WindowPresenterEvent::DeviceClaim, false);
    CHECK(fromPlatform.error.empty());
    CHECK(fromPlatform.releasePlatform);  // one flip-model swapchain per HWND
    CHECK(fromPlatform.next == WindowPresenter::Device);
}

TEST_CASE("window presenter: refused claims change nothing and say why") {
    // A graphics context draws with the platform's swapchain.
    const WindowPresenterStep inUse = step(WindowPresenter::Platform, WindowPresenterEvent::DeviceClaim, true);
    CHECK(inUse.next == WindowPresenter::Platform);
    CHECK_FALSE(inUse.releasePlatform);
    CHECK(inUse.error.find("close_context") != std::string::npos);
    // The window has a graphics API of its own (an OpenGL window): the busy reason is the error.
    const std::string busy = "sokol_app made an OpenGL context on this window";
    const WindowPresenterStep gl = step(WindowPresenter::Unclaimed, WindowPresenterEvent::DeviceClaim, false, busy);
    CHECK(gl.next == WindowPresenter::Unclaimed);
    CHECK(gl.error == busy);
    // A device has it already.
    const WindowPresenterStep twice = step(WindowPresenter::Device, WindowPresenterEvent::DeviceClaim);
    CHECK(twice.next == WindowPresenter::Device);
    CHECK(twice.error.find("another GPU device") != std::string::npos);
    // The platform's swapchain is not made while a device has the window.
    const WindowPresenterStep asked = step(WindowPresenter::Device, WindowPresenterEvent::PlatformAsked);
    CHECK(asked.next == WindowPresenter::Device);
    CHECK(asked.error.find("app_release_native_window") != std::string::npos);
}

TEST_CASE("window presenter: the fallback path, claim, release, then the platform's swapchain again") {
    WindowPresenter now = WindowPresenter::Unclaimed;
    WindowPresenterStep s = step(now, WindowPresenterEvent::DeviceClaim);
    REQUIRE(s.error.empty());
    now = s.next;
    // The device failed to start: it destroyed its swapchain and lets the window go.
    s = step(now, WindowPresenterEvent::DeviceRelease);
    CHECK(s.error.empty());
    now = s.next;
    CHECK(now == WindowPresenter::Unclaimed);
    // The build's sokol backend asks for the window's device: the platform makes its swapchain anew.
    s = step(now, WindowPresenterEvent::PlatformAsked);
    CHECK(s.next == WindowPresenter::Platform);
    // A release without a device changes nothing.
    CHECK(step(WindowPresenter::Platform, WindowPresenterEvent::DeviceRelease).next == WindowPresenter::Platform);
    CHECK(step(WindowPresenter::Unclaimed, WindowPresenterEvent::DeviceRelease).next == WindowPresenter::Unclaimed);
}

TEST_CASE("window presenter: without a window nothing is handed, claimed or presented") {
    // Tests run without run_app(): no window.
    const NativeWindow handles = app_native_window();
    CHECK(handles.window == nullptr);
    CHECK(handles.display == nullptr);
    CHECK_FALSE(handles.busy.empty());
    const Result<NativeWindow> claim = app_claim_native_window("vulkan");
    REQUIRE_FALSE(claim.ok());
    CHECK(claim.error().message.find("vulkan") != std::string::npos);
    CHECK(claim.error().message.find("hint") != std::string::npos);
    CHECK(app_window_presenter() == WindowPresenter::Unclaimed);
    CHECK(app_window_device_backend().empty());
    app_release_native_window();  // nothing claimed: nothing changes
    CHECK(app_window_presenter() == WindowPresenter::Unclaimed);
    CHECK_FALSE(app_read_window_back_buffer(4, 4, nullptr));
}
