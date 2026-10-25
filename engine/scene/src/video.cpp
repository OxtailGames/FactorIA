#include "fa/scene/video.h"

#include <algorithm>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/video.h"

namespace fa {

namespace {

void open_video(World& w, Entity e, Video& v) {
    VideoRuntime& rt = v.rt;
    // A script may have called play() or seek() in the frames before the file was open: the first open keeps that.
    const bool first = !rt.tried;
    const bool scriptPlay = first && v.playing;
    const float scriptTime = first ? v.time : 0.0f;
    rt.decoder.reset();
    rt.tried = true;
    rt.openedPath = v.path;
    rt.lastTime = 0;
    v.time = 0;
    v.duration = 0;
    v.ended = false;
    v.playing = false;
    if (v.path.empty()) return;
    auto fail = [&](const std::string& why) {
        FA_WARN("video", "entity '{}' Video: {}", w.id_of(e), why);
    };
    auto bytes = fs::read_bytes(v.path);
    if (!bytes) {
        const std::string hint = bytes.error().hint.empty() ? "" : " (hint: " + bytes.error().hint + ")";
        return fail(bytes.error().message + hint);
    }
    auto decoder = VideoDecoder::open(std::make_shared<const std::vector<std::uint8_t>>(std::move(bytes.value())), v.path);
    if (!decoder) return fail(decoder.error().to_string());
    rt.decoder = std::move(decoder.value());
    v.duration = float(rt.decoder->info().duration);
    v.playing = v.autoplay || scriptPlay;
    v.time = scriptTime;  // a value other than 0 is a seek, made by update_videos right after
}

}  // namespace

void update_videos(World& w, float dt) {
    w.each<Video>([&](Entity e, Video& v) {
        if (!w.active_in_hierarchy(e)) return;
        VideoRuntime& rt = v.rt;
        if (!rt.tried || rt.openedPath != v.path) open_video(w, e, v);
        if (!rt.decoder) return;
        VideoDecoder& d = *rt.decoder;
        d.set_loop(v.loop);

        if (double(v.time) != rt.lastTime) {  // a script assigned `time`: seek
            d.seek(double(std::max(0.0f, v.time)));
            v.ended = d.ended();
            if (d.ended()) v.playing = false;
        }
        if (v.playing && d.ended()) {  // play() after the end starts over
            d.seek(0);
            v.ended = false;
        }
        if (v.playing && !d.ended() && dt > 0) {
            d.advance(double(dt));
            if (d.ended()) {
                v.playing = false;
                v.ended = true;
                Json data = Json::object({{"id", w.id_of(e)}, {"path", v.path}});
                w.events().game.push_back(GameEvent{"video.ended", std::move(data), e});
            }
        }
        v.time = float(d.time());
        v.duration = float(d.info().duration);
        rt.lastTime = double(v.time);
        });
}

}  // namespace fa
