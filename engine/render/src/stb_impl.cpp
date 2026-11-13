// stb_truetype implementation lives here (stb_image / stb_image_write live in
// fa_core's image.cpp; do not define their implementations again).
#define STB_TRUETYPE_IMPLEMENTATION
// MSVC: no warnings from the vendored implementation compiled here (its flow-analysis warnings, such as C4701
// and C4702, are reported in this file under /WX; external/ is not edited).
#if defined(_MSC_VER)
#pragma warning(push, 0)
#endif
#include <stb_truetype.h>
#if defined(_MSC_VER)
#pragma warning(pop)
#endif
