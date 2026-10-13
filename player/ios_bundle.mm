// iOS helpers for the player: locate the game folder inside the app bundle and the Documents directory.
// UNTESTED locally (needs Xcode); built by the CI "ios" job.
#import <Foundation/Foundation.h>

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
