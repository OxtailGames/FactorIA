// Frames, tags and cels of an image document: which cel a layer shows in a frame, and how the frames and tags lay out in the sprite
// sheet the bake writes (docs/IMAGES.md, "Frames and tags").
#include <algorithm>
#include <cmath>
#include <format>
#include <numeric>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "image_doc_internal.h"

namespace fa {

int image_frame_count(const ImageDocument& doc) { return std::max(1, int(doc.frames.size())); }

const char* image_tag_direction_name(ImageTagDirection direction) {
    switch (direction) {
        case ImageTagDirection::Forward: return "forward";
        case ImageTagDirection::Reverse: return "reverse";
        case ImageTagDirection::PingPong: return "pingpong";
    }
    return "forward";
}
std::vector<std::string> image_tag_direction_names() { return {"forward", "reverse", "pingpong"}; }

ImageCelView image_layer_cel(const ImageLayer& layer, int frame) {
    ImageCelView v;
    auto own = [&]() {
        v.empty = layer.kind == ImageLayerKind::Pixels && layer.source.empty();
        v.source = &layer.source;
        v.rows = &layer.rows;
        v.x = layer.x;
        v.y = layer.y;
        v.opacity = 1.0f;
        v.origin = 0;
    };
    if ((layer.kind != ImageLayerKind::Pixels && layer.kind != ImageLayerKind::Indexed) || layer.cels.empty() ||
        frame <= 0) {
        own();
        return v;
    }
    const ImageCel* cur = nullptr;
    for (const ImageCel& c : layer.cels) {
        if (c.frame > frame) break;
        cur = &c;
    }
    if (!cur) {
        own();
        return v;
    }
    if (cur->link >= 0 && cur->link < cur->frame) return image_layer_cel(layer, cur->link);
    v.empty = cur->empty;
    v.source = &cur->source;
    v.rows = &cur->rows;
    v.x = cur->x.value_or(layer.x);
    v.y = cur->y.value_or(layer.y);
    v.opacity = cur->opacity;
    v.origin = cur->frame;
    return v;
}

namespace {

constexpr int kMaxClipCells = 512;  // the cells one tag may spell out
constexpr int kMaxSheetSide = 16384;

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

// One pass over a tag in its direction. A looping ping-pong leaves out the turn-around frames at both ends (the loop supplies them).
std::vector<int> tag_pass(const ImageTag& tag) {
    std::vector<int> seq;
    if (tag.direction == ImageTagDirection::Reverse) {
        for (int f = tag.to; f >= tag.from; --f) seq.push_back(f);
        return seq;
    }
    for (int f = tag.from; f <= tag.to; ++f) seq.push_back(f);
    if (tag.direction == ImageTagDirection::PingPong)
        for (int f = tag.to - 1; f > tag.from; --f) seq.push_back(f);
    return seq;
}

}  // namespace

Result<ImageSheetPlan> plan_image_sheet(const ImageDocument& doc) {
    ImageSheetPlan plan;
    const int n = image_frame_count(doc);
    auto duration = [&](int f) { return doc.frames.empty() ? 100 : doc.frames[std::size_t(f)].duration; };
    for (int f = 0; f < n; ++f) plan.cellFrame.push_back(f);

    std::vector<assets_detail::SheetClip> clips;
    for (const ImageTag& tag : doc.tags) {
        if (tag.from < 0 || tag.to >= n || tag.from > tag.to)
            continue;  // the parser rejects these; a document built in memory may not
        bool uniform = true;
        for (int f = tag.from; f <= tag.to; ++f) uniform = uniform && duration(f) == duration(tag.from);
        assets_detail::SheetClip clip;
        clip.name = tag.name;
        clip.loop = tag.repeat == 0;
        // A run that plays the frames in order needs no extra cells: a forward tag, a single frame, or a looping ping-pong of two frames
        // (its turn-around frames are the ends, which the loop supplies).
        const bool inOrder =
            tag.direction == ImageTagDirection::Forward || tag.from == tag.to ||
            (tag.direction == ImageTagDirection::PingPong && tag.repeat == 0 && tag.to - tag.from <= 1);
        if (inOrder && tag.repeat <= 1 && uniform) {
            clip.firstFrame = tag.from;
            clip.lastFrame = tag.to;
            clip.fps = round3(1000.0 / duration(tag.from));
            clips.push_back(clip);
            continue;
        }
        // The play order, spelled out in extra cells.
        std::vector<int> pass = tag_pass(tag), seq;
        const int repeats = std::max(1, tag.repeat);
        for (int r = 0; r < repeats; ++r) seq.insert(seq.end(), pass.begin(), pass.end());
        if (tag.repeat > 0 && tag.direction == ImageTagDirection::PingPong && tag.to > tag.from)
            seq.push_back(tag.from);  // comes to rest
        int g = 0;
        for (int f : seq) g = std::gcd(g, duration(f));
        long long cells = 0;
        for (int f : seq) cells += duration(f) / g;
        std::vector<int> sequence;
        double cellMs = g;
        if (cells <= kMaxClipCells) {
            for (int f : seq)
                for (int k = 0; k < duration(f) / g; ++k) sequence.push_back(f);
        } else {
            long long total = 0;
            for (int f : seq) total += duration(f);
            cellMs = double(total) / double(seq.size());
            sequence = seq;
            plan.warnings.push_back(std::format("Tag '{}': its frames last {} ms in {} steps, too many cells for one "
                                                "clip, so every frame plays for the average of {} ms.",
                                                tag.name, total, seq.size(), round3(cellMs)));
        }
        clip.firstFrame = int(plan.cellFrame.size());
        for (int f : sequence) plan.cellFrame.push_back(f);
        clip.lastFrame = int(plan.cellFrame.size()) - 1;
        clip.fps = round3(1000.0 / cellMs);
        clips.push_back(clip);
    }

    plan.cells = int(plan.cellFrame.size());
    plan.columns =
        doc.sheetColumns > 0 ? std::min(doc.sheetColumns, plan.cells) : int(std::ceil(std::sqrt(double(plan.cells))));
    plan.rows = (plan.cells + plan.columns - 1) / plan.columns;
    if (std::size_t(plan.columns) * std::size_t(doc.width) > std::size_t(kMaxSheetSide) ||
        std::size_t(plan.rows) * std::size_t(doc.height) > std::size_t(kMaxSheetSide))
        return make_error(
            std::format("The sprite sheet would be {}x{} px ({} cells of {}x{} in {} columns), more than the {} px a "
                        "texture can have.",
                        plan.columns * doc.width, plan.rows * doc.height, plan.cells, doc.width, doc.height,
                        plan.columns, kMaxSheetSide),
            "Set `sheet.columns` so the sheet is closer to square, use fewer frames, or make the canvas smaller.");
    for (const assets_detail::SheetClip& c : clips)
        plan.clips.push_back({c.name, c.firstFrame, c.lastFrame, c.fps, c.loop});
    plan.sheet = assets_detail::sheet_entry(plan.columns, plan.rows, doc.width, doc.height, plan.cells, clips);
    return plan;
}

}  // namespace fa
