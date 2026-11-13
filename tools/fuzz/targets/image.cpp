// fa::decode_image and fa::image_size on any bytes (PNG, JPG, TGA, BMP, GIF, PSD, HDR, PIC, PNM through stb_image): the
// header size and the decoded size must agree, and a header that claims a huge picture is an error, not an allocation.
#include <cstddef>
#include <cstdint>

#include "fa/core/image.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    const auto header = fa::image_size(data, size);
    auto image = fa::decode_image(data, size);
    if (image) {
        if (image.value().rgba.size() != std::size_t(image.value().width) * std::size_t(image.value().height) * 4)
            fa::fuzz::fail("decode_image: the pixel buffer is not width x height x 4");
        if (header && (header.value().width != image.value().width || header.value().height != image.value().height))
            fa::fuzz::fail("image_size and decode_image disagree on the size");
        (void)fa::mip_chain(std::move(image.value()));
    }
    return 0;
}
