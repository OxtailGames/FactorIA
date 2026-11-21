{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "metal_macos",
  "params": [
    "cut",
    "cutY"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _685, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_685.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _685.light_cookie[i];\n    float4 param_1 = _685.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _798 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _798.xy, level(0.0));\n    return cookie_value(param_3) * _798.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _820 = _685.lit.y > 0.5;\n    if (_820)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _685.normal_uv.xy) + _685.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _844 = fa_tex_fix(param, param_1);\n        float3 _848 = (_844 * 2.0) - float3(1.0);\n        float _855 = cos(params.y);\n        float _857 = sin(params.y);\n        n = fast::normalize(float3((float2(_855, _857) * _848.x) + ((float2(-_857, _855) * ((mode > 5.5) ? (-1.0) : 1.0)) * _848.y), fast::max(_848.z, 0.0500000007450580596923828125)));\n    }\n    bool _891 = !_820;\n    bool _897;\n    if (_891)\n    {\n        _897 = _685.lit.z > 0.5;\n    }\n    else\n    {\n        _897 = _891;\n    }\n    float3 _900;\n    if (_897)\n    {\n        _900 = _685.flat_ambient.xyz;\n    }\n    else\n    {\n        _900 = _685.ambient.xyz;\n    }\n    float3 total = _900;\n    bool _917;\n    if (_897)\n    {\n        _917 = _685.lit.z < 1.5;\n    }\n    else\n    {\n        _917 = _897;\n    }\n    if (_917)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _685.light_map.xy), level(0.0)).xyz * _685.light_map.z);\n    }\n    float3 l;\n    float _1044;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _954;\n        if (!_897)\n        {\n            _954 = float(i) >= _685.lit.x;\n        }\n        else\n        {\n            _954 = _897;\n        }\n        if (_954)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            l = _685.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _980 = _685.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_980) / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            float3 _1000 = float3(_980, _685.light_pos[i].z);\n            l = _1000 / float3(fast::max(length(_1000), 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _685.light_shadow_v[i].x;\n                float param_3 = _685.light_shadow_v[i].y;\n                float2 param_4 = -_980;\n                float param_5 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_980;\n            att *= cookie_att(param_6, param_7, _685, fx_cookie_tex, light_smp);\n        }\n        if (_820)\n        {\n            _1044 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1044 = 1.0;\n        }\n        total += (_685.light_color[i].xyz * (att * _1044));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1294 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1298 = uv * _1294;\n    float _1304 = _1294.x;\n    float _1306 = _1294.y;\n    float _1308 = fast::clamp(shape_rs.x, 0.0, fast::min(_1304, _1306));\n    float2 _1319 = (abs(_1298) - _1294) + float2(_1308);\n    float d = (length(fast::max(_1319, float2(0.0))) + fast::min(fast::max(_1319.x, _1319.y), 0.0)) - _1308;\n    float ax = params.y;\n    bool _1340 = params.y > 15.0;\n    if (_1340)\n    {\n        ax -= 20.0;\n    }\n    float _1351;\n    if (ax <= (-1.5))\n    {\n        _1351 = (-2.0) - ax;\n    }\n    else\n    {\n        _1351 = 0.0;\n    }\n    if (_1351 > 0.0)\n    {\n        float _1365 = _1351 * 0.5;\n        d = abs(d + _1365) - _1365;\n    }\n    float _1373 = fwidth(d);\n    float _1374 = fast::max(_1373, 9.9999997473787516355514526367188e-05);\n    float _1384 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1374)), 0.0, 1.0);\n    float _1389;\n    if (shape_rs.y > _1374)\n    {\n        _1389 = (_1384 * _1384) * (3.0 - (2.0 * _1384));\n    }\n    else\n    {\n        _1389 = _1384;\n    }\n    float4 c = color;\n    bool _1411 = (_1351 <= 0.0) && (ax > (-0.5));\n    if (_1411)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1426 = cos(ax);\n            float _1428 = sin(ax);\n            g = ((dot(_1298, float2(_1426, _1428)) / fast::max((abs(_1426) * _1304) + (abs(_1428) * _1306), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1340)\n        {\n            float4 _1471 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1471;\n            float3 param = _1471.xyz;\n            float param_1 = xform.y;\n            float3 _1478 = fa_tex_fix(param, param_1);\n            float4 _2267 = c;\n            _2267.x = _1478.x;\n            _2267.y = _1478.y;\n            _2267.z = _1478.z;\n            c = _2267;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1490 = scene_rgb(param_2, xform);\n            float4 _1515 = mix(float4(color.xyz * color.w, color.w), float4(_1490 * color2.w, color2.w), float4(g));\n            float _1517 = _1515.w;\n            float3 _1520;\n            if (_1517 > 9.9999997473787516355514526367188e-06)\n            {\n                _1520 = _1515.xyz / float3(_1517);\n            }\n            else\n            {\n                _1520 = color.xyz;\n            }\n            c = float4(_1520, _1517);\n        }\n    }\n    float4 _2276 = c;\n    _2276.w = _2276.w * _1389;\n    c = _2276;\n    if (_1411 || (shape_rs.y > 0.0))\n    {\n        float _1561 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1570 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1570 + float3(_1561 * 0.0039215688593685626983642578125);\n            float3 _1576 = fa_srgb_to_linear(param_4);\n            float4 _2279 = c;\n            _2279.x = _1576.x;\n            _2279.y = _1576.y;\n            _2279.z = _1576.z;\n            c = _2279;\n        }\n        else\n        {\n            float4 _1586 = c;\n            float3 _1589 = _1586.xyz + float3(_1561 * 0.0039215688593685626983642578125);\n            float4 _2286 = _1586;\n            _2286.x = _1589.x;\n            _2286.y = _1589.y;\n            _2286.z = _1589.z;\n            c = _2286;\n        }\n        float4 _2291 = c;\n        _2291.w = fast::clamp(_2291.w + ((_1561 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2291.w)), 0.0, 1.0);\n        c = _2291;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1081 = float2(_685.fx_rim_uv.x, 0.0);\n    float4 _1083 = tex.sample(smp, (uv - _1081));\n    float _1084 = _1083.w;\n    float4 _1094 = tex.sample(smp, (uv + _1081));\n    float _1095 = _1094.w;\n    float2 _1103 = float2(0.0, _685.fx_rim_uv.y);\n    float4 _1105 = tex.sample(smp, (uv - _1103));\n    float _1106 = _1105.w;\n    float4 _1116 = tex.sample(smp, (uv + _1103));\n    float _1117 = _1116.w;\n    float _1132 = _1084 - _1095;\n    float _1135 = _1117 - _1106;\n    float _1145 = cos(params.y);\n    float _1147 = sin(params.y);\n    float2 _1173 = ((float2(_1145, _1147) * _1132) + ((float2(-_1147, _1145) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1135)) / float2(fast::max(length(float2(_1132, _1135)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _685.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            to_l = _685.light_pos[i].xy / float2(fast::max(length(_685.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1219 = _685.light_pos[i].xy - world_xy;\n            float _1222 = length(_1219);\n            att = powr(fast::clamp(1.0 - (_1222 / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            to_l = _1219 / float2(fast::max(_1222, 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _685.light_shadow_v[i].x;\n                float param_1 = _685.light_shadow_v[i].y;\n                float2 param_2 = -_1219;\n                float param_3 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1219;\n            att *= cookie_att(param_4, param_5, _685, fx_cookie_tex, light_smp);\n        }\n        sum += (_685.light_color[i].xyz * (att * fast::max(dot(_1173, to_l), 0.0)));\n    }\n    return (sum * _685.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1084, _1095), fast::min(_1106, _1117))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _685)\n{\n    float2 _691 = gl_FragCoord.xy * _685.fa_target.xy;\n    float _695 = _691.y;\n    return float2(_691.x, mix(_695, 1.0 - _695, _685.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _733 = base_mode < 0.5;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _685), _685.fa_time.x, base_mode, float4(0.0), _745 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _761)\n{\n    bool _764 = i.screen_uv.x < _761.cut;\n    bool _773;\n    if (!_764)\n    {\n        _773 = i.screen_uv.y < _761.cutY;\n    }\n    else\n    {\n        _773 = _764;\n    }\n    if (_773)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _685 [[buffer(1)]], constant fa_material& _761 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1616 = in.params.x > 31.5;\n    if (_1616)\n    {\n        mode -= 32.0;\n    }\n    float _1624 = mode;\n    bool _1626 = _1624 > 15.5;\n    if (_1626)\n    {\n        mode -= 16.0;\n    }\n    float _1634 = mode;\n    bool _1636 = _1634 > 7.5;\n    if (_1636)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1626)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1626)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1698 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1700 = _1698 * in.color;\n                float4 param_6 = _1700;\n                float param_7 = mode;\n                float _1707 = _1700.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1707);\n                if (_685.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1707;\n                    float param_9 = mode;\n                    float4 _1723 = out.frag_color;\n                    float3 _1725 = _1723.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1725.x;\n                    out.frag_color.y = _1725.y;\n                    out.frag_color.z = _1725.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1755 = length(in.uv);\n                    float _1758 = fwidth(_1755);\n                    float _1759 = fast::max(_1758, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1755) / _1759) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1755) / _1759) + 0.5, 0.0, 1.0) * fast::clamp(((_1755 - in.params.y) / _1759) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1799 = fast::clamp(1.0 - _1755, 0.0, 1.0);\n                            cov = (_1799 * _1799) * (3.0 - (2.0 * _1799));\n                        }\n                    }\n                    float3 _1808;\n                    if (_1626)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1808 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1808 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1808, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_685.fx_emit.w > 0.5)\n    {\n        float3 e = _685.fx_emit.xyz;\n        if (_685.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _685.fx_emit_uv.xy) + _685.fx_emit_uv.zw)).xyz;\n            float param_13 = _685.fx_emit.w - 2.0;\n            float3 _1863 = fa_tex_fix(param_12, param_13);\n            e *= _1863;\n        }\n        float4 _1867 = out.frag_color;\n        float3 _1869 = _1867.xyz + e;\n        out.frag_color.x = _1869.x;\n        out.frag_color.y = _1869.y;\n        out.frag_color.z = _1869.z;\n    }\n    float param_14 = mode;\n    float4 _2197 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _685, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2197 };\n    fragment0(param_15, param_16, _761);\n    _2197 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1616)\n    {\n        float4 _1895 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1900 = scene_rgb(param_17, in.xform);\n        float3 _1904 = mix(_1895.xyz, _1900, float3(in.color2.w));\n        out.frag_color.x = _1904.x;\n        out.frag_color.y = _1904.y;\n        out.frag_color.z = _1904.z;\n    }\n    if (_1636)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1928 = _685.fog_col.w > 0.0;\n    bool _1936;\n    if (!_1928)\n    {\n        _1936 = _685.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1936 = _1928;\n    }\n    if (_1936)\n    {\n        float3 _1950 = float3(in.world_xy, in.world_z) - _685.fog_eye.xyz;\n        float _1957 = dot(_1950, _685.fog_c.xyz);\n        bool _1961 = _685.fog_c.w > 0.5;\n        float _1962;\n        if (_1961)\n        {\n            _1962 = _1957;\n        }\n        else\n        {\n            _1962 = length(_1950);\n        }\n        float _1974 = _1962 - _685.fog_b.x;\n        if (_1974 > 0.0)\n        {\n            float _1983 = _685.fog_col.w * _1974;\n            float tau = _1983 * _1983;\n            if (_685.fog_b.y > 0.0)\n            {\n                float _1999;\n                if (_1961)\n                {\n                    _1999 = in.world_xy.y - (_685.fog_c.y * _1957);\n                }\n                else\n                {\n                    _1999 = _685.fog_eye.y;\n                }\n                float _2020 = mix(_1999, in.world_xy.y, fast::clamp(_685.fog_b.x / _1962, 0.0, 1.0));\n                float _2024 = in.world_xy.y - _2020;\n                float _2029 = _2020 - _685.fog_b.z;\n                float _2034 = in.world_xy.y - _685.fog_b.z;\n                bool _2037 = _2029 <= 0.0;\n                bool _2038 = !_2037;\n                bool _2044;\n                if (_2038)\n                {\n                    _2044 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2044 = _2037;\n                }\n                float _2045;\n                if (_2044)\n                {\n                    _2045 = _685.fog_b.y;\n                }\n                else\n                {\n                    _2045 = _685.fog_b.y * exp(-fast::min(_685.fog_b.w * _2029, 80.0));\n                }\n                bool _2072;\n                if (_2038)\n                {\n                    _2072 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2072 = _2037;\n                }\n                float _2073;\n                if (_2072)\n                {\n                    _2073 = _685.fog_b.y * _2029;\n                }\n                else\n                {\n                    _2073 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2029, 80.0)))) / _685.fog_b.w;\n                }\n                bool _2098 = _2034 <= 0.0;\n                bool _2105;\n                if (!_2098)\n                {\n                    _2105 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2105 = _2098;\n                }\n                float _2106;\n                if (_2105)\n                {\n                    _2106 = _685.fog_b.y * _2034;\n                }\n                else\n                {\n                    _2106 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2034, 80.0)))) / _685.fog_b.w;\n                }\n                float _2133;\n                if (abs(_2024) < 0.001000000047497451305389404296875)\n                {\n                    _2133 = _2045;\n                }\n                else\n                {\n                    _2133 = (_2106 - _2073) / _2024;\n                }\n                tau += (_1974 * fast::max(_2133, 0.0));\n            }\n            float4 _2156 = out.frag_color;\n            float3 _2164 = mix(_2156.xyz, _685.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2164.x;\n            out.frag_color.y = _2164.y;\n            out.frag_color.z = _2164.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_68",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_685",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_761",
            "msl_buffer_n": 5
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
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
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
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _217)\n{\n    bool _220 = i.screen_uv.x < _217.cut;\n    bool _229;\n    if (!_220)\n    {\n        _229 = i.screen_uv.y < _217.cutY;\n    }\n    else\n    {\n        _229 = _220;\n    }\n    if (_229)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], constant fa_material& _217 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _245 = tex.sample(smp, in.uv);\n    float3 param = _245.xyz;\n    float param_1 = in.xform.y;\n    float3 _256 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_256, _245.w) * in.color;\n    float param_2 = 0.0;\n    float4 _311 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _311 };\n    fragment0(param_3, param_4, _217);\n    _311 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_68",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_131",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_217",
            "msl_buffer_n": 5
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
          }
        ],
        "samplers": [
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
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
