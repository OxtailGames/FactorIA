// platform.add_backend {"backend": "steam"}: the Steamworks backend (docs/PLATFORM.md, "Steam").
#include "platform_setup.h"

namespace fa::platform_setup {

Backend steam_backend() {
    Backend b;
    b.name = "steam";
    b.summary = "the Steamworks plugin (not available yet).";
    b.properties = Json::object();
    b.run = [](Context&) {
        throw CommandError("unavailable", "the Steamworks backend cannot be set up by this version of factoria yet",
                           "docs/PLATFORM.md lists the backends this version has.");
    };
    return b;
}

}  // namespace fa::platform_setup
