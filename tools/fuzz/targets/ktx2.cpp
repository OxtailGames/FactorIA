// KTX2 files (Basis Universal UASTC / ETC1S): ktx2_size reads the header, decode_ktx2 transcodes the first level to RGBA8 on
// the CPU. A damaged file is an error; a header that claims a huge texture must not allocate it.
#include <cstddef>
#include <cstdint>

#include "fa/core/image.h"
#include "fa/render/ktx2.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    (void)fa::ktx2_size(data, size);
    const auto image = fa::decode_ktx2(data, size);
    if (image && image.value().rgba.size() != std::size_t(image.value().width) * std::size_t(image.value().height) * 4)
        fa::fuzz::fail("decode_ktx2: the pixel buffer is not width x height x 4");
    return 0;
}
