#include "assets_shots.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>

#include "fa/core/process.h"
#include "fa/core/screenshot_files.h"
#include "fa/render/fonts.h"
#include "fa/tooling/self_update.h"
#include "util.h"

namespace fa::assets_detail {

Image resize_area(const Image& src, int w, int h) {
    Image out;
    out.width = std::max(1, w);
    out.height = std::max(1, h);
    out.rgba.assign(std::size_t(out.width) * out.height * 4, 0);
    if (src.width <= 0 || src.height <= 0) return out;
    const double sx = double(src.width) / out.width, sy = double(src.height) / out.height;
    for (int y = 0; y < out.height; ++y) {
        const double y0 = y * sy, y1 = (y + 1) * sy;
        for (int x = 0; x < out.width; ++x) {
            const double x0 = x * sx, x1 = (x + 1) * sx;
            std::uint8_t* d = &out.rgba[(std::size_t(y) * out.width + x) * 4];
            if (x1 - x0 <= 1.0 && y1 - y0 <= 1.0) {  // growing (or 1:1): the pixel under the centre
                const int px = std::clamp(int((x0 + x1) / 2), 0, src.width - 1), py = std::clamp(int((y0 + y1) / 2), 0, src.height - 1);
                std::copy_n(&src.rgba[(std::size_t(py) * src.width + px) * 4], 4, d);
                continue;
            }
            double r = 0, g = 0, b = 0, a = 0, wsum = 0;
            for (int j = int(std::floor(y0)); j < std::min(src.height, int(std::ceil(y1))); ++j) {
                const double wy = std::min(y1, j + 1.0) - std::max(y0, double(j));
                for (int i = int(std::floor(x0)); i < std::min(src.width, int(std::ceil(x1))); ++i) {
                    const double wgt = wy * (std::min(x1, i + 1.0) - std::max(x0, double(i)));
                    const std::uint8_t* p = &src.rgba[(std::size_t(j) * src.width + i) * 4];
                    const double al = p[3] / 255.0;
                    r += wgt * al * p[0];
                    g += wgt * al * p[1];
                    b += wgt * al * p[2];
                    a += wgt * al;
                    wsum += wgt;
                }
            }
            if (wsum <= 0 || a <= 0) continue;
            d[0] = std::uint8_t(std::lround(std::clamp(r / a, 0.0, 255.0)));
            d[1] = std::uint8_t(std::lround(std::clamp(g / a, 0.0, 255.0)));
            d[2] = std::uint8_t(std::lround(std::clamp(b / a, 0.0, 255.0)));
            d[3] = std::uint8_t(std::lround(std::clamp(a / wsum * 255.0, 0.0, 255.0)));
        }
    }
    return out;
}

Image to_greyscale(const Image& src) {
    Image out = src;
    for (std::size_t i = 0; i + 3 < out.rgba.size(); i += 4) {
        const double l = 0.2126 * out.rgba[i] + 0.7152 * out.rgba[i + 1] + 0.0722 * out.rgba[i + 2];
        out.rgba[i] = out.rgba[i + 1] = out.rgba[i + 2] = std::uint8_t(std::lround(std::clamp(l, 0.0, 255.0)));
    }
    return out;
}

void fill_rect_rgb(Image& dst, int x, int y, int w, int h, Rgb8 c) {
    for (int j = std::max(0, y); j < std::min(dst.height, y + h); ++j)
        for (int i = std::max(0, x); i < std::min(dst.width, x + w); ++i) {
            std::uint8_t* p = &dst.rgba[(std::size_t(j) * dst.width + i) * 4];
            p[0] = c.r;
            p[1] = c.g;
            p[2] = c.b;
            p[3] = 255;
        }
}

void draw_over(Image& dst, const Image& src, int x, int y) {
    for (int j = 0; j < src.height; ++j) {
        const int dy = y + j;
        if (dy < 0 || dy >= dst.height) continue;
        for (int i = 0; i < src.width; ++i) {
            const int dx = x + i;
            if (dx < 0 || dx >= dst.width) continue;
            const std::uint8_t* s = &src.rgba[(std::size_t(j) * src.width + i) * 4];
            if (s[3] == 0) continue;
            std::uint8_t* d = &dst.rgba[(std::size_t(dy) * dst.width + dx) * 4];
            const double a = s[3] / 255.0;
            for (int k = 0; k < 3; ++k) d[k] = std::uint8_t(std::lround(d[k] + (s[k] - d[k]) * a));
            d[3] = 255;
        }
    }
}

int draw_text(Image& dst, int x, int y, const std::string& text, float px, Rgb8 c) {
    auto bmp = rasterize_text(text, "", px);
    if (!bmp.ok() || bmp->width <= 0) return 0;
    for (int j = 0; j < bmp->height; ++j) {
        const int dy = y + j;
        if (dy < 0 || dy >= dst.height) continue;
        for (int i = 0; i < bmp->width; ++i) {
            const int dx = x + i;
            const int cov = bmp->coverage[std::size_t(j) * bmp->width + i];
            if (dx < 0 || dx >= dst.width || cov == 0) continue;
            std::uint8_t* d = &dst.rgba[(std::size_t(dy) * dst.width + dx) * 4];
            const double a = cov / 255.0;
            d[0] = std::uint8_t(std::lround(d[0] + (c.r - d[0]) * a));
            d[1] = std::uint8_t(std::lround(d[1] + (c.g - d[1]) * a));
            d[2] = std::uint8_t(std::lround(d[2] + (c.b - d[2]) * a));
            d[3] = 255;
        }
    }
    return bmp->width;
}

int text_width(const std::string& text, float px) {
    auto bmp = rasterize_text(text, "", px);
    return bmp.ok() ? bmp->width : 0;
}

std::string hex_colour(const Color& c) {
    auto byte = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255)); };
    return std::format("#{:02x}{:02x}{:02x}", byte(c.r), byte(c.g), byte(c.b));
}

stdfs::path write_temporary_picture(const std::string& projectDir, const Image& picture, const char* tag) {
    static std::atomic<int> counter{0};
    const stdfs::path dir = project_file(projectDir, kScreenshotDir);
    std::error_code ec;
    stdfs::path file;
    for (;;) {
        file = dir / std::format("frame_{}_{}.png", ++counter, tag);
        if (!stdfs::exists(file, ec)) break;
    }
    const std::vector<std::uint8_t> png = encode_png(picture);
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);
    return file;
}

Json image_member(const stdfs::path& file, bool temporary) {
    Json j = Json::object({{"path", file.string()}, {"mimeType", "image/png"}});
    if (temporary) j["temporary"] = true;
    return j;
}

Json call_in_child(const std::string& projectDir, const char* command, const Json& args) {
    stdfs::path exe = executable_path();
    if (!exe.empty() && exe.stem() != "factoria") {  // the editor or a game: the command line tool sits next to it
        stdfs::path sibling = exe.parent_path() / ("factoria" + exe.extension().string());
        std::error_code ec;
        exe = stdfs::exists(sibling, ec) ? sibling : stdfs::path();
    }
    if (exe.empty())
        fail("gpu_busy", std::string("This process already uses the graphics card (the editor, a window or a session with graphics), and ") + command + " needs a second device; the factoria executable could not be located to run it in a child process.",
             std::string("Run it from a terminal: factoria call ") + command + " '{...}'.");
    ProcessOptions po;
    po.argv = {exe.string(), "call", "--project", projectDir, "--no-graphics", "--json", command, args.dump()};
    po.workingDir = projectDir;
    po.timeoutSeconds = 900;
    auto run = run_process(po);
    if (!run.ok()) fail("failed", std::string("Cannot start ") + exe.string() + " to run " + command + " in a child process: " + run.error().message, run.error().hint);
    auto out = parse_json(run->stdoutText, std::string("<") + command + " in a child process>");
    if (!out.ok()) {
        const std::string tail = run->stderrText.size() > 600 ? run->stderrText.substr(run->stderrText.size() - 600) : run->stderrText;
        fail("failed", std::format("The child process that runs {} (exit code {}) printed no result. Its error output ended with: {}", command, run->exitCode, tail),
             std::string("Run the command from a terminal to see it: factoria call ") + command + " '{...}'.");
    }
    if (out->is_object() && out->contains("ok") && (*out)["ok"] == false) {
        const Json err = out->value("error", Json::object());
        throw CommandError(err.value("code", std::string("failed")), err.value("message", std::string("The child process failed.")), err.value("hint", std::string()));
    }
    return *out;
}

void no_gpu_error(const char* command, const std::string& message, const char* alternative) {
    fail("no_gpu", std::string(command) + " draws with the GPU for this, and this computer has no graphics device the engine can use. " + message,
         std::string("Run it on a machine with a GPU (Metal, Direct3D 11, OpenGL; a Linux CI needs Mesa's EGL, llvmpipe). ") + alternative);
}

}  // namespace fa::assets_detail
