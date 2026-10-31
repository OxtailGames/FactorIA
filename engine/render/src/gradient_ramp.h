// Gradient ramps: the colours of a Shape2D gradient with stops or an easing, baked into one row of a shared texture
// (kRampWidth texels wide). The quad shader (mode 7) looks the row up at the eased position, so a gradient with 8 stops costs
// the same as a two-colour one and shapes with the same ramp still share a batch.
#pragma once

#include <array>
#include <cstdint>
#include <unordered_map>
#include <vector>

#include "fa/scene/components.h"
#include "render_internal.h"

namespace fa::render {

constexpr int kRampWidth = 256;  // texels along a ramp
constexpr int kRampRows = 256;   // distinct ramps held at once

// What a ramp is baked from: up to kMaxGradientStops stops sorted by position, and the curve applied to the position.
struct GradientSpec {
    GradientEase ease = GradientEase::Linear;
    int count = 0;
    std::array<float, kMaxGradientStops> t{};
    std::array<Color, kMaxGradientStops> color{};
    std::uint64_t hash() const;
    bool operator==(const GradientSpec& o) const;
};

// The ramp a filled gradient shape needs, with `tint` (Tint component) multiplied into every colour. False when the shape's
// gradient is the plain color -> color2 one (no stops, linear easing): the shader blends those two itself. A malformed entry of
// gradientStops is skipped (`warning` receives what was wrong, once per call); with no valid stop left the two colours are used.
bool gradient_spec(const Shape2D& s, const Color& tint, GradientSpec& out, std::string* warning = nullptr);

// The straight-alpha RGBA8 texel `i` (0..kRampWidth-1) of the ramp of `spec`: colours blend premultiplied between stops (so
// fading to a transparent colour does not grey), stay at the first/last stop outside them.
void bake_ramp_row(const GradientSpec& spec, std::uint8_t* rgba /* kRampWidth * 4 */);

class GradientRamps {
public:
    GradientRamps() = default;
    ~GradientRamps();
    GradientRamps(const GradientRamps&) = delete;
    GradientRamps& operator=(const GradientRamps&) = delete;

    // Starts a frame: a row used since this call is never evicted while the frame is gathered.
    void begin_frame() { ++tick_; }
    // The row of `spec`, baked on first use; -1 when all kRampRows rows are in use by this frame's shapes.
    int acquire(const GradientSpec& spec);
    // The v texture coordinate of the middle of row `row`.
    static float row_v(int row) { return (float(row) + 0.5f) / float(kRampRows); }
    // The u texture coordinate that reads the texel centre of position g in 0..1 (clamped), so g = 0 and 1 give the end colours.
    static float u_of(float g) { return (0.5f + std::clamp(g, 0.0f, 1.0f) * float(kRampWidth - 1)) / float(kRampWidth); }
    // The texture the ramp shapes draw with. It has no GPU image until the first acquire() and sync().
    TextureAsset* texture() { return &tex_; }
    // Uploads the rows baked since the last call (the image is made again). Call after the gather, before drawing.
    void sync();
    void destroy();
    int rows_in_use() const { return int(byHash_.size()); }
    std::size_t bytes() const { return tex_.image.id ? std::size_t(kRampWidth) * kRampRows * 4 : 0; }

private:
    struct Row {
        GradientSpec spec;
        std::uint64_t used = 0;
        bool live = false;
    };
    TextureAsset tex_;
    std::vector<std::uint8_t> pixels_;  // kRampRows rows of kRampWidth RGBA8 texels
    std::array<Row, kRampRows> rows_{};
    std::unordered_map<std::uint64_t, std::vector<int>> byHash_;  // spec hash -> rows holding it
    std::uint64_t tick_ = 1;
    bool dirty_ = false;
};

}  // namespace fa::render
