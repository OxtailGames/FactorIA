// iOS helpers for the player: locate the game folder inside the app bundle and the Documents directory.
// UNTESTED locally (needs Xcode); built by the CI "ios" job.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <string>

std::string fa_player_ios_game_dir() {
    @autoreleasepool {
        NSString* res = [[NSBundle mainBundle] resourcePath];
        return std::string([res UTF8String]) + "/game";
    }
}

std::string fa_player_ios_documents_dir() {
    @autoreleasepool {
        NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* d = dirs.count > 0 ? dirs[0] : NSTemporaryDirectory();
        return std::string([d UTF8String]);
    }
}

// Turns the app's window scene to "portrait" or "landscape" (the check run of `player.run_ios_sim`: `simctl` has no rotate
// command). The scene exists a moment after the start, so the request waits for it; the Info.plist must allow the
// orientation (export.ios / display.orientation), else iOS refuses and the error is logged.
void fa_player_ios_request_orientation(const std::string& orientation) {
    @autoreleasepool {
        const bool landscape = orientation == "landscape";
        if (!landscape && orientation != "portrait") {
            NSLog(@"player: FA_ORIENTATION '%s' is not 'portrait' or 'landscape'; ignored", orientation.c_str());
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) continue;
                UIWindowScene* windowScene = (UIWindowScene*)scene;
                if (@available(iOS 16.0, *)) {
                    UIInterfaceOrientationMask mask = landscape ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskPortrait;
                    UIWindowSceneGeometryPreferencesIOS* prefs = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:mask];
                    [windowScene requestGeometryUpdateWithPreferences:prefs errorHandler:^(NSError* error) {
                        NSLog(@"player: cannot turn the screen to %@: %@", landscape ? @"landscape" : @"portrait", error.localizedDescription);
                    }];
                    NSLog(@"player: screen orientation requested: %@", landscape ? @"landscape" : @"portrait");
                } else {
                    NSLog(@"player: turning the screen needs iOS 16 or newer");
                }
                break;
            }
        });
    }
}
