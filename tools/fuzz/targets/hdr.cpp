// fa::decode_hdr (Radiance RGBE) on any bytes: a header that claims a huge picture is an error, not an allocation, a
// decoded picture holds exactly width x height x 3 finite non-negative floats, and what encode_hdr writes of it
// decodes again to the same size.
#include <cmath>
#include <cstddef>
#include <cstdint>

#include "fa/core/image_float.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    auto image = fa::decode_hdr(data, size);
    if (!image) return 0;
    const fa::ImageF& img = image.value();
    if (img.channels != 3 || img.width < 1 || img.height < 1 ||
        img.data.size() != std::size_t(img.width) * std::size_t(img.height) * 3)
        fa::fuzz::fail("decode_hdr: the pixel buffer is not width x height x 3");
    for (float v : img.data)
        if (!(v >= 0.0f) || !std::isfinite(v)) fa::fuzz::fail("decode_hdr: a pixel is negative or not finite");
    // The round trip of a big picture takes long for one input: only the small ones.
    if (img.data.size() <= (std::size_t(1) << 16)) {
        const auto bytes = fa::encode_hdr(img);
        auto again = fa::decode_hdr(bytes.data(), bytes.size());
        if (!again) fa::fuzz::fail("encode_hdr wrote a file that decode_hdr refuses");
        if (again.value().width != img.width || again.value().height != img.height)
            fa::fuzz::fail("encode_hdr changed the size");
        (void)img.half_size();
    }
    return 0;
}
