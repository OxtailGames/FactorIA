{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, texture2d<float> fa_vs_mask, sampler fa_vs_mask_smp)\n{\n    v.world_pos.x += (fa_vs_mask.sample(fa_vs_mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125), level(0.0)).x * 40.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _96 [[buffer(0)]], texture2d<float> fa_vs_mask [[texture(0)]], sampler fa_vs_mask_smp [[sampler(7)]])\n{\n    main0_out out = {};\n    float3 _171 = in.position;\n    float2 _172 = in.texcoord0;\n    float4 _173 = in.color0;\n    if (_96.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex{ _171, _172, _173 };\n    vertex0(param_1, fa_vs_mask, fa_vs_mask_smp);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    out.gl_Position = _96.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _96.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _523 = tex.sample(smp, p);\n    float3 param = _523.xyz;\n    float param_1 = xform.y;\n    float3 _533 = fa_tex_fix(param, param_1);\n    return float4(_533, _523.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _109 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_109.x * 255.0) + 0.5) * 256.0) + floor((_109.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0 * floor(_212 * 0.0009765625));\n    float _225 = _222 + 1.0;\n    float i1 = _225;\n    if (_225 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _212);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _262 = length(d);\n    float result = 1.0;\n    if (_262 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _273 = precise::atan2(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0)\n        {\n            _276 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875;\n        float _295 = fast::min((size * 10.0) / _262, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0 * floor(_323 * 0.0009765625));\n            float _337 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _369 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _262)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _393 = 1.0 - (0.800000011920928955078125 * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _147 = precise::atan2(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0)\n    {\n        _150 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875;\n    float _167 = fast::min(floor(_162), 1023.0);\n    float _174 = _167 + 1.0;\n    float i1 = _174;\n    if (_174 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _133) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _133) + 0.5, 0.0, 1.0), _162 - _167);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _565, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _660 = _565.lit.y > 0.5;\n    if (_660)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _565.normal_uv.xy) + _565.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _684 = fa_tex_fix(param, param_1);\n        float3 _688 = (_684 * 2.0) - float3(1.0);\n        float _695 = cos(params.y);\n        float _697 = sin(params.y);\n        n = fast::normalize(float3((float2(_695, _697) * _688.x) + ((float2(-_697, _695) * ((mode > 5.5) ? (-1.0) : 1.0)) * _688.y), fast::max(_688.z, 0.0500000007450580596923828125)));\n    }\n    bool _730 = !_660;\n    bool _736;\n    if (_730)\n    {\n        _736 = _565.lit.z > 0.5;\n    }\n    else\n    {\n        _736 = _730;\n    }\n    float3 _739;\n    if (_736)\n    {\n        _739 = _565.flat_ambient.xyz;\n    }\n    else\n    {\n        _739 = _565.ambient.xyz;\n    }\n    float3 total = _739;\n    bool _756;\n    if (_736)\n    {\n        _756 = _565.lit.z < 1.5;\n    }\n    else\n    {\n        _756 = _736;\n    }\n    if (_756)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _565.light_map.xy), level(0.0)).xyz * _565.light_map.z);\n    }\n    float3 l;\n    float _876;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _794;\n        if (!_736)\n        {\n            _794 = float(i) >= _565.lit.x;\n        }\n        else\n        {\n            _794 = _736;\n        }\n        if (_794)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_565.light_pos[i].w < 0.0)\n        {\n            l = _565.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _820 = _565.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_820) / fast::max(_565.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _565.light_color[i].w);\n            float3 _840 = float3(_820, _565.light_pos[i].z);\n            l = _840 / float3(fast::max(length(_840), 9.9999997473787516355514526367188e-05));\n            if (_565.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _565.light_shadow_v[i].x;\n                float param_3 = _565.light_shadow_v[i].y;\n                float2 param_4 = -_820;\n                float param_5 = _565.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n        }\n        if (_660)\n        {\n            _876 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _876 = 1.0;\n        }\n        total += (_565.light_color[i].xyz * (att * _876));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _904 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _908 = uv * _904;\n    float _914 = _904.x;\n    float _916 = _904.y;\n    float _918 = fast::clamp(shape_rs.x, 0.0, fast::min(_914, _916));\n    float2 _929 = (abs(_908) - _904) + float2(_918);\n    float d = (length(fast::max(_929, float2(0.0))) + fast::min(fast::max(_929.x, _929.y), 0.0)) - _918;\n    float ax = params.y;\n    bool _950 = params.y > 15.0;\n    if (_950)\n    {\n        ax -= 20.0;\n    }\n    float _961;\n    if (ax <= (-1.5))\n    {\n        _961 = (-2.0) - ax;\n    }\n    else\n    {\n        _961 = 0.0;\n    }\n    if (_961 > 0.0)\n    {\n        float _975 = _961 * 0.5;\n        d = abs(d + _975) - _975;\n    }\n    float _983 = fwidth(d);\n    float _984 = fast::max(_983, 9.9999997473787516355514526367188e-05);\n    float _994 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _984)), 0.0, 1.0);\n    float _999;\n    if (shape_rs.y > _984)\n    {\n        _999 = (_994 * _994) * (3.0 - (2.0 * _994));\n    }\n    else\n    {\n        _999 = _994;\n    }\n    float4 c = color;\n    bool _1021 = (_961 <= 0.0) && (ax > (-0.5));\n    if (_1021)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1036 = cos(ax);\n            float _1038 = sin(ax);\n            g = ((dot(_908, float2(_1036, _1038)) / fast::max((abs(_1036) * _914) + (abs(_1038) * _916), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_950)\n        {\n            float4 _1081 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1081;\n            float3 param = _1081.xyz;\n            float param_1 = xform.y;\n            float3 _1088 = fa_tex_fix(param, param_1);\n            float4 _1784 = c;\n            _1784.x = _1088.x;\n            _1784.y = _1088.y;\n            _1784.z = _1088.z;\n            c = _1784;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1100 = scene_rgb(param_2, xform);\n            float4 _1125 = mix(float4(color.xyz * color.w, color.w), float4(_1100 * color2.w, color2.w), float4(g));\n            float _1127 = _1125.w;\n            float3 _1130;\n            if (_1127 > 9.9999997473787516355514526367188e-06)\n            {\n                _1130 = _1125.xyz / float3(_1127);\n            }\n            else\n            {\n                _1130 = color.xyz;\n            }\n            c = float4(_1130, _1127);\n        }\n    }\n    float4 _1793 = c;\n    _1793.w = _1793.w * _999;\n    c = _1793;\n    if (_1021 || (shape_rs.y > 0.0))\n    {\n        float _1171 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1180 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1180 + float3(_1171 * 0.0039215688593685626983642578125);\n            float3 _1186 = fa_srgb_to_linear(param_4);\n            float4 _1796 = c;\n            _1796.x = _1186.x;\n            _1796.y = _1186.y;\n            _1796.z = _1186.z;\n            c = _1796;\n        }\n        else\n        {\n            float4 _1196 = c;\n            float3 _1199 = _1196.xyz + float3(_1171 * 0.0039215688593685626983642578125);\n            float4 _1803 = _1196;\n            _1803.x = _1199.x;\n            _1803.y = _1199.y;\n            _1803.z = _1199.z;\n            c = _1803;\n        }\n        float4 _1808 = c;\n        _1808.w = fast::clamp(_1808.w + ((_1171 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1808.w)), 0.0, 1.0);\n        c = _1808;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _565)\n{\n    float2 _571 = gl_FragCoord.xy * _565.fa_target.xy;\n    float _575 = _571.y;\n    return float2(_571.x, mix(_575, 1.0 - _575, _565.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _565, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _614 = base_mode < 0.5;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _565), _565.fa_time.x, base_mode, float4(0.0), _626 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _646 = mask.sample(mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _646.x;\n    s.color.y = _646.y;\n    s.color.z = _646.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _565 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1226 = in.params.x > 31.5;\n    if (_1226)\n    {\n        mode -= 32.0;\n    }\n    float _1234 = mode;\n    bool _1236 = _1234 > 15.5;\n    if (_1236)\n    {\n        mode -= 16.0;\n    }\n    float _1244 = mode;\n    bool _1246 = _1244 > 7.5;\n    if (_1246)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1236)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1236)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1310 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1310;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1310.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1345 = length(in.uv);\n                    float _1348 = fwidth(_1345);\n                    float _1349 = fast::max(_1348, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1345) / _1349) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1345) / _1349) + 0.5, 0.0, 1.0) * fast::clamp(((_1345 - in.params.y) / _1349) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1389 = fast::clamp(1.0 - _1345, 0.0, 1.0);\n                            cov = (_1389 * _1389) * (3.0 - (2.0 * _1389));\n                        }\n                    }\n                    float3 _1398;\n                    if (_1236)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1398 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1398 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1398, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1737 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _565, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1737 };\n    fragment0(param_11, param_12, mask, mask_smp);\n    _1737 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1226)\n    {\n        float4 _1436 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1441 = scene_rgb(param_13, in.xform);\n        float3 _1445 = mix(_1436.xyz, _1441, float3(in.color2.w));\n        out.frag_color.x = _1445.x;\n        out.frag_color.y = _1445.y;\n        out.frag_color.z = _1445.z;\n    }\n    if (_1246)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1469 = _565.fog_col.w > 0.0;\n    bool _1477;\n    if (!_1469)\n    {\n        _1477 = _565.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1477 = _1469;\n    }\n    if (_1477)\n    {\n        float3 _1491 = float3(in.world_xy, in.world_z) - _565.fog_eye.xyz;\n        float _1498 = dot(_1491, _565.fog_c.xyz);\n        bool _1502 = _565.fog_c.w > 0.5;\n        float _1503;\n        if (_1502)\n        {\n            _1503 = _1498;\n        }\n        else\n        {\n            _1503 = length(_1491);\n        }\n        float _1515 = _1503 - _565.fog_b.x;\n        if (_1515 > 0.0)\n        {\n            float _1524 = _565.fog_col.w * _1515;\n            float tau = _1524 * _1524;\n            if (_565.fog_b.y > 0.0)\n            {\n                float _1540;\n                if (_1502)\n                {\n                    _1540 = in.world_xy.y - (_565.fog_c.y * _1498);\n                }\n                else\n                {\n                    _1540 = _565.fog_eye.y;\n                }\n                float _1561 = mix(_1540, in.world_xy.y, fast::clamp(_565.fog_b.x / _1503, 0.0, 1.0));\n                float _1565 = in.world_xy.y - _1561;\n                float _1570 = _1561 - _565.fog_b.z;\n                float _1575 = in.world_xy.y - _565.fog_b.z;\n                bool _1578 = _1570 <= 0.0;\n                bool _1579 = !_1578;\n                bool _1585;\n                if (_1579)\n                {\n                    _1585 = _565.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1585 = _1578;\n                }\n                float _1586;\n                if (_1585)\n                {\n                    _1586 = _565.fog_b.y;\n                }\n                else\n                {\n                    _1586 = _565.fog_b.y * exp(-fast::min(_565.fog_b.w * _1570, 80.0));\n                }\n                bool _1613;\n                if (_1579)\n                {\n                    _1613 = _565.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1613 = _1578;\n                }\n                float _1614;\n                if (_1613)\n                {\n                    _1614 = _565.fog_b.y * _1570;\n                }\n                else\n                {\n                    _1614 = (_565.fog_b.y * (1.0 - exp(-fast::min(_565.fog_b.w * _1570, 80.0)))) / _565.fog_b.w;\n                }\n                bool _1639 = _1575 <= 0.0;\n                bool _1646;\n                if (!_1639)\n                {\n                    _1646 = _565.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1646 = _1639;\n                }\n                float _1647;\n                if (_1646)\n                {\n                    _1647 = _565.fog_b.y * _1575;\n                }\n                else\n                {\n                    _1647 = (_565.fog_b.y * (1.0 - exp(-fast::min(_565.fog_b.w * _1575, 80.0)))) / _565.fog_b.w;\n                }\n                float _1674;\n                if (abs(_1565) < 0.001000000047497451305389404296875)\n                {\n                    _1674 = _1586;\n                }\n                else\n                {\n                    _1674 = (_1647 - _1614) / _1565;\n                }\n                tau += (_1515 * fast::max(_1674, 0.0));\n            }\n            float4 _1697 = out.frag_color;\n            float3 _1705 = mix(_1697.xyz, _565.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1705.x;\n            out.frag_color.y = _1705.y;\n            out.frag_color.z = _1705.z;\n        }\n    }\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_96",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_565",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 7
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "shadow_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, texture2d<float> fa_vs_mask, sampler fa_vs_mask_smp)\n{\n    v.world_pos.x += (fa_vs_mask.sample(fa_vs_mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125), level(0.0)).x * 40.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _96 [[buffer(0)]], texture2d<float> fa_vs_mask [[texture(0)]], sampler fa_vs_mask_smp [[sampler(7)]])\n{\n    main0_out out = {};\n    float3 _171 = in.position;\n    float2 _172 = in.texcoord0;\n    float4 _173 = in.color0;\n    if (_96.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex{ _171, _172, _173 };\n    vertex0(param_1, fa_vs_mask, fa_vs_mask_smp);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    out.gl_Position = _96.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _96.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _127)\n{\n    float2 _134 = gl_FragCoord.xy * _127.fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, mix(_140, 1.0 - _140, _127.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _127, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _127), _127.fa_time.x, base_mode, float4(0.0), _196 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _222 = mask.sample(mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _222.x;\n    s.color.y = _222.y;\n    s.color.z = _222.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _127 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _237 = tex.sample(smp, in.uv);\n    float3 param = _237.xyz;\n    float param_1 = in.xform.y;\n    float3 _248 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_248, _237.w) * in.color;\n    float param_2 = 0.0;\n    float4 _302 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _127, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _302 };\n    fragment0(param_3, param_4, mask, mask_smp);\n    _302 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_96",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 7
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 3
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    }
  }
}
