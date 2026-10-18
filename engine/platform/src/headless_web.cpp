// Window-less GPU context on the web: there is none. A page always has its canvas (sokol_app), and headless runs (tests,
// screenshots, replays) are tools of the developer's machine. The engine links this class everywhere; here it only says no.
#include <cstring>

#include "fa/platform/app.h"

namespace fa {

struct HeadlessGpu::Impl {};

HeadlessGpu::HeadlessGpu() = default;
HeadlessGpu::~HeadlessGpu() = default;

bool HeadlessGpu::init(std::string* error) {
    if (error)
        *error = "headless rendering is not available in the web player: a browser page always draws to its canvas. "
                 "Run headless commands (screenshots, tests, replays) with the desktop `factoria` tool.";
    return false;
}

void HeadlessGpu::shutdown() {}
bool HeadlessGpu::valid() const { return impl_ != nullptr; }  // never
GfxEnvironment HeadlessGpu::environment() const { return {}; }
const char* HeadlessGpu::description() const { return "not available on the web"; }
void HeadlessGpu::end_frame() {}

}  // namespace fa
