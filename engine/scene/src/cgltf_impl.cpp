// cgltf implementation lives here.
#define CGLTF_IMPLEMENTATION
// MSVC: no warnings from the vendored implementation compiled here (its flow-analysis warnings, such as C4701
// and C4702, are reported in this file under /WX; external/ is not edited).
#if defined(_MSC_VER)
#pragma warning(push, 0)
#endif
#include <cgltf.h>
#if defined(_MSC_VER)
#pragma warning(pop)
#endif
