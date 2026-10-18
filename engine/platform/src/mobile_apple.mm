// iOS: the safe area, vibration and the on-screen keyboard. macOS has none of them (mobile.cpp). UNTESTED: written without
// an iPhone or a Mac at hand; only compiled by CI.
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

#include "mobile_impl.h"
#include "sokol_app.h"
#include "sokol_window.h"

namespace fa {

// UIView.safeAreaInsets of sokol_app's view, in framebuffer pixels (sokol_impl_apple.m).
EdgeInsets mobile_safe_insets() {
    float left = 0, top = 0, right = 0, bottom = 0;
    if (!fa_sapp_safe_insets(&left, &top, &right, &bottom)) return {};
    return {left, top, right, bottom};
}

// iOS does not let an app choose how long the motor runs. A short request is a haptic tap whose strength follows the length
// (UIImpactFeedbackGenerator); a long one is the system vibration, which lasts about half a second. iPads have no motor and
// do nothing.
void mobile_vibrate(float seconds) {
    if (seconds > 0.3f) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        return;
    }
    const UIImpactFeedbackStyle style = seconds <= 0.05f   ? UIImpactFeedbackStyleLight
                                        : seconds <= 0.15f ? UIImpactFeedbackStyleMedium
                                                           : UIImpactFeedbackStyleHeavy;
    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [generator prepare];
    [generator impactOccurred];
}

// sokol_app shows the keyboard with a hidden UITextField and delivers what is typed as CHAR events (one UTF-16 unit each:
// emoji, which are surrogate pairs, are dropped by sokol_app) and Enter / Backspace as key events.
void mobile_show_keyboard(bool show) { sapp_show_keyboard(show); }

void mobile_poll(Input&) {}
bool mobile_native_event(const void*) { return false; }

}  // namespace fa

#endif
