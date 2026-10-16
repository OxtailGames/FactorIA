// Taps the middle of the screen of the app named by FA_TOUCH_BUNDLE_ID (passed to xcodebuild as
// TEST_RUNNER_FA_TOUCH_BUNDLE_ID), which must already run in the simulator. activate brings a running app to the front
// without starting it again, so the process and its captured console stay the same.
#import <XCTest/XCTest.h>

@interface FaTouchTests : XCTestCase
@end

@implementation FaTouchTests

- (void)testTapMiddleOfScreen {
    NSString* bundleId = NSProcessInfo.processInfo.environment[@"FA_TOUCH_BUNDLE_ID"];
    XCTAssertNotNil(bundleId, @"set TEST_RUNNER_FA_TOUCH_BUNDLE_ID=<bundle id of the running app> for xcodebuild");
    if (bundleId == nil) return;
    XCUIApplication* app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleId];
    XCTAssertNotEqual(app.state, XCUIApplicationStateNotRunning, @"%@ is not running: launch it first", bundleId);
    [app activate];
    XCTAssertTrue([app waitForState:XCUIApplicationStateRunningForeground timeout:30],
                  @"%@ did not come to the foreground", bundleId);
    [[app coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)] tap];
}

@end
