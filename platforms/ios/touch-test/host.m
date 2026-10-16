// The UI test's target app. It only has to exist: the test drives the FactorIA player by bundle id instead.
#import <UIKit/UIKit.h>

@interface FaTouchHostDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation FaTouchHostDelegate
@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([FaTouchHostDelegate class]));
    }
}
