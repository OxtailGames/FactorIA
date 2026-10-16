// platform.add_backend {"backend": "apple"}: the App Store and Game Center backend (docs/PLATFORM.md, "Apple").
#include "platform_setup.h"

namespace fa::platform_setup {

Backend apple_backend() {
    Backend b;
    b.name = "apple";
    b.summary = "the StoreKit and Game Center plugin (not available yet).";
    b.properties = Json::object();
    b.run = [](Context&) {
        throw CommandError("unavailable", "the Apple backend cannot be set up by this version of factoria yet",
                           "docs/PLATFORM.md lists the backends this version has.");
    };
    return b;
}

}  // namespace fa::platform_setup
