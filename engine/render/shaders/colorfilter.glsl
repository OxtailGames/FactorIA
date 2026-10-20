// FactorIA colour filter (Camera.colorFilter): the last post-process pass. One full-screen triangle reads the finished
// game target and writes the filtered picture into a second image of the same size (a pass cannot read what it
// writes); that image is what present(), the editor viewport and screenshots show.
//
// The game target holds sRGB-encoded values, so every filter works in linear light: decode, filter, encode.
//   mode 1  greyscale     Rec. 709 luminance
//   mode 2  highContrast  gamma-space contrast stretch around mid grey (x1.8), clipped
//   mode 3-5 protanopia, deuteranopia, tritanopia: a daltonize correction (Fidaner et al.) for a viewer who lacks
//           that cone. The loss is estimated with the Machado, Oliveira and Fernandes 2009 matrix of severity 1.0
//           (the same numbers as simulate_color_vision() in fa/core/image.h): err = original - simulated. The error
//           is then shifted into the channels the viewer still sees (protanopia, deuteranopia: err.r*0.7 + err.g go
//           to green, err.r*0.7 + err.b to blue; tritanopia: err.b*0.7 + err.r to red, err.b*0.7 + err.g to green),
//           so colours that collapsed together differ in brightness or in the remaining hue axis.
@module colorfilter

@vs vs
layout(binding=0) uniform colorfilter_vs_params {
    vec4 flip;      // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
};
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, flip.x));
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform colorfilter_params {
    vec4 p;         // x = mode (1 greyscale, 2 highContrast, 3 protanopia, 4 deuteranopia, 5 tritanopia)
};
in vec2 uv;
out vec4 frag_color;

vec3 to_linear(vec3 c) {
    return mix(pow(max((c + 0.055) / 1.055, vec3(0.0)), vec3(2.4)), c / 12.92, vec3(lessThanEqual(c, vec3(0.04045))));
}
vec3 to_srgb(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    return mix(1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, c * 12.92, vec3(lessThanEqual(c, vec3(0.0031308))));
}

void main() {
    vec3 c = textureLod(sampler2D(tex, smp), uv, 0.0).rgb;
    int mode = int(p.x + 0.5);
    vec3 o = c;
    if (mode == 1) {
        float y = dot(to_linear(c), vec3(0.2126, 0.7152, 0.0722));
        o = to_srgb(vec3(y));
    } else if (mode == 2) {
        o = clamp((c - 0.5) * 1.8 + 0.5, 0.0, 1.0);
    } else if (mode >= 3) {
        vec3 l = to_linear(c);
        // Machado 2009, severity 1.0, linear RGB. GLSL matrices are column-major: each vec3 is a COLUMN, so the
        // columns below are the table's columns (what pure red, green and blue become).
        mat3 m;
        if (mode == 3) {
            m = mat3(vec3(0.152286, 0.114503, -0.003882), vec3(1.052583, 0.786281, -0.048116), vec3(-0.204868, 0.099216, 1.051998));
        } else if (mode == 4) {
            m = mat3(vec3(0.367322, 0.280085, -0.011820), vec3(0.860646, 0.672501, 0.042940), vec3(-0.227968, 0.047413, 0.968881));
        } else {
            m = mat3(vec3(1.255528, -0.078411, 0.004733), vec3(-0.076749, 0.930809, 0.691367), vec3(-0.178779, 0.147602, 0.303900));
        }
        vec3 err = l - m * l;
        vec3 add = mode == 5 ? vec3(err.r + 0.7 * err.b, err.g + 0.7 * err.b, 0.0)
                             : vec3(0.0, 0.7 * err.r + err.g, 0.7 * err.r + err.b);
        o = to_srgb(l + add);
    }
    frag_color = vec4(o, 1.0);
}
@end

@program colorfilter vs fs
