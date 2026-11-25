// Who makes the window's swapchain (fa/platform/app.h, M77-P9e1): the pure state machine app.cpp acts on.
#include "fa/platform/app.h"

namespace fa {

const char* window_presenter_name(WindowPresenter presenter) {
    switch (presenter) {
        case WindowPresenter::None: return "none";
        case WindowPresenter::Platform: return "platform";
        case WindowPresenter::Device: return "device";
    }
    return "none";
}

WindowPresenterStep window_presenter_step(WindowPresenter now, WindowPresenterEvent event, bool platformInUse,
                                          const std::string& busy) {
    WindowPresenterStep step;
    step.next = now;
    switch (event) {
        case WindowPresenterEvent::PlatformAsked:
            if (now == WindowPresenter::Device) {
                step.error =
                    "a GPU device (D3D12 or Vulkan) has the window's swapchain, so the platform makes none (hint: shut "
                    "that renderer down and call app_release_native_window() first)";
                return step;
            }
            step.makePlatform = now == WindowPresenter::None;
            step.next = WindowPresenter::Platform;
            return step;
        case WindowPresenterEvent::DeviceClaim:
            if (!busy.empty()) {
                step.error = busy;
                return step;
            }
            if (now == WindowPresenter::Device) {
                step.error = "another GPU device has the window's swapchain already (hint: one renderer draws into the "
                             "window; release it with app_release_native_window() once its swapchain is gone)";
                return step;
            }
            if (now == WindowPresenter::Platform && platformInUse) {
                step.error = "the window already presents through the platform's swapchain and a graphics context "
                             "draws with it (hint: close it with Renderer::close_context() before a D3D12 or Vulkan "
                             "renderer starts, or leave the backend on auto)";
                return step;
            }
            step.releasePlatform = now == WindowPresenter::Platform;
            step.next = WindowPresenter::Device;
            return step;
        case WindowPresenterEvent::DeviceRelease:
            if (now == WindowPresenter::Device) step.next = WindowPresenter::None;
            return step;
    }
    return step;
}

}  // namespace fa
