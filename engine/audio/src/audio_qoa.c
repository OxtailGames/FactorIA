/* qoa implementation (single C translation unit): decoding of .qoa clips and the encoder behind encode_qoa(). */
#define QOA_IMPLEMENTATION
#define QOA_NO_STDIO
/* MSVC C4701 at qoa.h:469 is a false positive: the first of the 16 scale factors always beats the initial best rank and
 * sets best_lms. Silenced for the vendored code only: external/ is not edited. */
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4701)
#endif
#include "qoa.h"
#if defined(_MSC_VER)
#pragma warning(pop)
#endif
