// macOS and iOS. UNTESTED: only compiled by CI.
#import <Foundation/Foundation.h>
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#include "fa/platform/accessibility.h"

namespace fa {

AccessibilitySettings read_system_accessibility() {
    AccessibilitySettings s;
#if TARGET_OS_IPHONE
    s.reduceMotion = UIAccessibilityIsReduceMotionEnabled();
    s.highContrast = UIAccessibilityDarkerSystemColorsEnabled();
    s.screenReader = UIAccessibilityIsVoiceOverRunning();
    // Dynamic Type: how big a 16 pt body font becomes at the player's size.
    const CGFloat scaled = [[UIFontMetrics defaultMetrics] scaledValueForValue:16.0];
    if (scaled > 0) s.textScale = static_cast<float>(scaled / 16.0);
#else
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    s.reduceMotion = workspace.accessibilityDisplayShouldReduceMotion;
    s.highContrast = workspace.accessibilityDisplayShouldIncreaseContrast;
    s.screenReader = [workspace isVoiceOverEnabled];
#endif
    return s;
}

}  // namespace fa
