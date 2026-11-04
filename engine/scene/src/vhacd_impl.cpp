// The implementation of V-HACD (external/vhacd, one header). Only the synchronous CreateVHACD() is used (model_game_ready.cpp), which
// runs in the calling thread; the header still includes <thread> and <mutex> for its asynchronous mode, which the engine never starts.
#define ENABLE_VHACD_IMPLEMENTATION 1
#include "VHACD.h"
