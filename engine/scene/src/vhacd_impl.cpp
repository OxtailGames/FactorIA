// The implementation of V-HACD (external/vhacd, one header). Only the synchronous CreateVHACD() is used (model_game_ready.cpp), which
// runs in the calling thread; the header still includes <thread> and <mutex> for its asynchronous mode, which the engine never starts.
#define ENABLE_VHACD_IMPLEMENTATION 1
// MSVC: no warnings from the vendored implementation compiled here (its flow-analysis warnings, such as C4701
// and C4702, are reported in this file under /WX; external/ is not edited).
#if defined(_MSC_VER)
#pragma warning(push, 0)
#endif
#include "vhacd_deterministic.h"  // VHACD.h made deterministic across standard libraries (engine/scene/CMakeLists.txt)
#if defined(_MSC_VER)
#pragma warning(pop)
#endif
