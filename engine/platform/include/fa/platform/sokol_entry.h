// Mobile (and custom) entry points.
//
// On iOS and Android sokol_app owns the process entry point and calls the
// game's `sokol_main(argc, argv)`. player/ defines it like this:
//
//     #include "fa/platform/sokol_entry.h"
//     extern "C" sapp_desc sokol_main(int argc, char* argv[]) {   // C linkage: sokol calls it from C
//         static fa::AppDesc desc = make_app_desc();   // fills callbacks, input, ...
//         return fa::to_sapp_desc(desc);
//     }
//
// On desktop the same function is used internally by fa::run_app().
#pragma once

#include "fa/platform/app.h"
#include <cstdint>

#include "fa/platform/sokol_logging.h"
#include "sokol_app.h"

namespace fa {

// Builds a sapp_desc whose callbacks drive `desc` (init/frame/event/cleanup,
// input translation, dt clamping). The AppDesc is COPIED into platform-owned
// storage, so the argument may be a temporary. Only one app can run per process.
sapp_desc to_sapp_desc(const AppDesc& desc);

// Points `out.images` at the usable images of `images` (AppDesc::icon): at most SAPP_MAX_ICONIMAGES, skipping one whose pixel
// buffer is not width * height * 4 bytes. The pixels are not copied, so `images` must outlive `out`. Returns how many were
// set. to_sapp_desc uses it on Windows and Linux, the platforms where sokol_app shows a window icon.
int fill_sapp_icon(sapp_icon_desc& out, const std::vector<AppIconImage>& images);

}  // namespace fa
