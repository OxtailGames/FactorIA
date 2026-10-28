// macOS: the editor's name in the Dock (app_icon.h, set_dock_name).
//
// A process that is not an app bundle is named after its executable: the Dock would call the editor "factoria".
// LaunchServices keeps that display name and has no public API to change it, so its private
// _LSSetApplicationInformationItem is looked up at run time: if a macOS release drops it the name stays the
// executable's and nothing else changes. Editor only: the game player (Mac App Store builds) never references it, and
// a game runs from its own bundle anyway.
#include "app_icon.h"

#import <AppKit/AppKit.h>
#include <dlfcn.h>

namespace fa::editor {

bool set_dock_name(const char* name) {
    if (NSBundle.mainBundle.bundleIdentifier != nil) return false;  // a bundle: its Info.plist names it
    using GetAsn = CFTypeRef (*)();
    using SetItem = OSStatus (*)(int session, CFTypeRef asn, CFStringRef key, CFStringRef value, CFDictionaryRef* out);
    void* ls = dlopen("/System/Library/Frameworks/CoreServices.framework/CoreServices", RTLD_LAZY | RTLD_NOLOAD);
    if (!ls) return false;
    auto get_asn = reinterpret_cast<GetAsn>(dlsym(ls, "_LSGetCurrentApplicationASN"));
    auto set_item = reinterpret_cast<SetItem>(dlsym(ls, "_LSSetApplicationInformationItem"));
    auto key = static_cast<const CFStringRef*>(dlsym(ls, "_kLSDisplayNameKey"));
    bool done = false;
    if (get_asn && set_item && key) {
        CFTypeRef asn = get_asn();
        NSString* value = [NSString stringWithUTF8String:name];
        constexpr int kDefaultSession = -2;  // kLSDefaultSessionID
        done = asn && set_item(kDefaultSession, asn, *key, (__bridge CFStringRef)value, nullptr) == noErr;
    }
    dlclose(ls);
    return done;
}

}  // namespace fa::editor
