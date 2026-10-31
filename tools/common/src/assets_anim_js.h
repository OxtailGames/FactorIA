// The sandboxed JavaScript of assets.animate_svg: a project module (`art/coin_spin.anim.js`) whose default export draws one
// frame of an animation as SVG text. See assets_anim_js.cpp.
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "assets_internal.h"

namespace fa::assets_detail {

struct AnimFrame {
    std::string clip;     // "" without clips
    int frame = 0;        // index inside the clip (the whole animation without clips)
    int frames = 1;       // frames of the clip
    int sheetFrame = 0;   // index in the sheet
    double fps = 12;
    double t = 0;         // frame / fps
    double progress = 0;  // 0..1 through the clip
    int width = 0, height = 0;  // the cell, in pixels
    Json params = Json::object();
    std::uint32_t seed = 0;      // seeds `rng` and Math.random for this frame
    std::uint32_t baseSeed = 0;  // the `seed` argument of the command: `seed` of the frame argument, and what rngFor(key) uses
};

class AnimModule {
public:
    struct Limits {
        double seconds = 2.0;                  // per call (loading the module, and each frame)
        std::size_t memoryBytes = std::size_t(128) * 1024 * 1024;
        std::size_t stackBytes = std::size_t(256) * 1024;
    };

    // Loads and runs `moduleRel` (project-relative .js) and finds its `frame` function. Throws CommandError (teaching: the
    // file, line and column of a mistake in the module, or what is missing).
    static std::unique_ptr<AnimModule> load(const std::string& projectDir, const std::string& moduleRel, const Limits& limits);
    ~AnimModule();
    AnimModule(const AnimModule&) = delete;
    AnimModule& operator=(const AnimModule&) = delete;

    // Draws one frame: the SVG text the module's function returns. Throws CommandError, naming the module, line and frame.
    std::string draw(const AnimFrame& frame);

    // Every project file the module loaded (itself first, then what it imported), project-relative.
    const std::vector<std::string>& files() const;
    // What the module wrote with console.log / warn / error ("log: ..."), at most a few hundred lines.
    const std::vector<std::string>& logs() const;

private:
    struct Impl;
    explicit AnimModule(std::unique_ptr<Impl> impl);
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::assets_detail
