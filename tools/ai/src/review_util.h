// Private helpers shared by the one-shot vision reviews (assets.review, vfx.review): the reply's JSON, files, pictures for the model.
#pragma once

#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "fa/ai/text_model.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"

namespace fa::ai::review {

inline constexpr std::uintmax_t kBigPicture = 1u << 20;  // a picture over 1 MB is shrunk before it is sent
inline constexpr int kLongSide = 1024;

// The reply's JSON object: the first '{' to the last '}' (a model may wrap it in prose or a fence).
inline std::string json_object_in(const std::string& text) {
    const std::size_t a = text.find('{'), b = text.rfind('}');
    if (a == std::string::npos || b == std::string::npos || b < a) return {};
    return text.substr(a, b - a + 1);
}

inline std::filesystem::path resolve(const std::string& projectDir, const std::string& path) {
    const std::filesystem::path p(path);
    return p.is_absolute() ? p : std::filesystem::path(projectDir) / p;
}

// A picture as the model gets it: the file itself, shrunk (PNG) when it is large.
inline Result<ImageData> picture_for_model(const std::filesystem::path& file, bool* shrunk) {
    auto data = load_image_data(file.string());
    if (!data.ok()) return data.error();
    std::error_code ec;
    if (std::filesystem::file_size(file, ec) <= kBigPicture) return data;
    const std::vector<unsigned char> bytes = fa::base64_decode(data->base64);
    auto img = decode_image(bytes.data(), bytes.size());
    if (!img.ok() || std::max(img->width, img->height) <= kLongSide) return data;
    const double k = double(kLongSide) / double(std::max(img->width, img->height));
    const Image small = resize_image(*img, std::max(1, int(img->width * k)), std::max(1, int(img->height * k)));
    const std::vector<std::uint8_t> png = encode_png(small);
    if (shrunk) *shrunk = true;
    return ImageData{"image/png", fa::base64_encode(png.data(), png.size())};
}

inline std::string read_text(const std::filesystem::path& p) {
    std::ifstream f(p, std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

}  // namespace fa::ai::review
