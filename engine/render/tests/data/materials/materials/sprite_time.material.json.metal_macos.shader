{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _685, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_685.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _685.light_cookie[i];\n    float4 param_1 = _685.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _790 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _790.xy, level(0.0));\n    return cookie_value(param_3) * _790.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _812 = _685.lit.y > 0.5;\n    if (_812)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _685.normal_uv.xy) + _685.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _836 = fa_tex_fix(param, param_1);\n        float3 _840 = (_836 * 2.0) - float3(1.0);\n        float _847 = cos(params.y);\n        float _849 = sin(params.y);\n        n = fast::normalize(float3((float2(_847, _849) * _840.x) + ((float2(-_849, _847) * ((mode > 5.5) ? (-1.0) : 1.0)) * _840.y), fast::max(_840.z, 0.0500000007450580596923828125)));\n    }\n    bool _883 = !_812;\n    bool _889;\n    if (_883)\n    {\n        _889 = _685.lit.z > 0.5;\n    }\n    else\n    {\n        _889 = _883;\n    }\n    float3 _892;\n    if (_889)\n    {\n        _892 = _685.flat_ambient.xyz;\n    }\n    else\n    {\n        _892 = _685.ambient.xyz;\n    }\n    float3 total = _892;\n    bool _909;\n    if (_889)\n    {\n        _909 = _685.lit.z < 1.5;\n    }\n    else\n    {\n        _909 = _889;\n    }\n    if (_909)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _685.light_map.xy), level(0.0)).xyz * _685.light_map.z);\n    }\n    float3 l;\n    float _1036;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _946;\n        if (!_889)\n        {\n            _946 = float(i) >= _685.lit.x;\n        }\n        else\n        {\n            _946 = _889;\n        }\n        if (_946)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            l = _685.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _972 = _685.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_972) / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            float3 _992 = float3(_972, _685.light_pos[i].z);\n            l = _992 / float3(fast::max(length(_992), 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _685.light_shadow_v[i].x;\n                float param_3 = _685.light_shadow_v[i].y;\n                float2 param_4 = -_972;\n                float param_5 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_972;\n            att *= cookie_att(param_6, param_7, _685, fx_cookie_tex, light_smp);\n        }\n        if (_812)\n        {\n            _1036 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1036 = 1.0;\n        }\n        total += (_685.light_color[i].xyz * (att * _1036));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1286 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1290 = uv * _1286;\n    float _1296 = _1286.x;\n    float _1298 = _1286.y;\n    float _1300 = fast::clamp(shape_rs.x, 0.0, fast::min(_1296, _1298));\n    float2 _1311 = (abs(_1290) - _1286) + float2(_1300);\n    float d = (length(fast::max(_1311, float2(0.0))) + fast::min(fast::max(_1311.x, _1311.y), 0.0)) - _1300;\n    float ax = params.y;\n    bool _1332 = params.y > 15.0;\n    if (_1332)\n    {\n        ax -= 20.0;\n    }\n    float _1343;\n    if (ax <= (-1.5))\n    {\n        _1343 = (-2.0) - ax;\n    }\n    else\n    {\n        _1343 = 0.0;\n    }\n    if (_1343 > 0.0)\n    {\n        float _1357 = _1343 * 0.5;\n        d = abs(d + _1357) - _1357;\n    }\n    float _1365 = fwidth(d);\n    float _1366 = fast::max(_1365, 9.9999997473787516355514526367188e-05);\n    float _1376 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1366)), 0.0, 1.0);\n    float _1381;\n    if (shape_rs.y > _1366)\n    {\n        _1381 = (_1376 * _1376) * (3.0 - (2.0 * _1376));\n    }\n    else\n    {\n        _1381 = _1376;\n    }\n    float4 c = color;\n    bool _1403 = (_1343 <= 0.0) && (ax > (-0.5));\n    if (_1403)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1418 = cos(ax);\n            float _1420 = sin(ax);\n            g = ((dot(_1290, float2(_1418, _1420)) / fast::max((abs(_1418) * _1296) + (abs(_1420) * _1298), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1332)\n        {\n            float4 _1463 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1463;\n            float3 param = _1463.xyz;\n            float param_1 = xform.y;\n            float3 _1470 = fa_tex_fix(param, param_1);\n            float4 _2259 = c;\n            _2259.x = _1470.x;\n            _2259.y = _1470.y;\n            _2259.z = _1470.z;\n            c = _2259;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1482 = scene_rgb(param_2, xform);\n            float4 _1507 = mix(float4(color.xyz * color.w, color.w), float4(_1482 * color2.w, color2.w), float4(g));\n            float _1509 = _1507.w;\n            float3 _1512;\n            if (_1509 > 9.9999997473787516355514526367188e-06)\n            {\n                _1512 = _1507.xyz / float3(_1509);\n            }\n            else\n            {\n                _1512 = color.xyz;\n            }\n            c = float4(_1512, _1509);\n        }\n    }\n    float4 _2268 = c;\n    _2268.w = _2268.w * _1381;\n    c = _2268;\n    if (_1403 || (shape_rs.y > 0.0))\n    {\n        float _1553 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1562 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1562 + float3(_1553 * 0.0039215688593685626983642578125);\n            float3 _1568 = fa_srgb_to_linear(param_4);\n            float4 _2271 = c;\n            _2271.x = _1568.x;\n            _2271.y = _1568.y;\n            _2271.z = _1568.z;\n            c = _2271;\n        }\n        else\n        {\n            float4 _1578 = c;\n            float3 _1581 = _1578.xyz + float3(_1553 * 0.0039215688593685626983642578125);\n            float4 _2278 = _1578;\n            _2278.x = _1581.x;\n            _2278.y = _1581.y;\n            _2278.z = _1581.z;\n            c = _2278;\n        }\n        float4 _2283 = c;\n        _2283.w = fast::clamp(_2283.w + ((_1553 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2283.w)), 0.0, 1.0);\n        c = _2283;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1073 = float2(_685.fx_rim_uv.x, 0.0);\n    float4 _1075 = tex.sample(smp, (uv - _1073));\n    float _1076 = _1075.w;\n    float4 _1086 = tex.sample(smp, (uv + _1073));\n    float _1087 = _1086.w;\n    float2 _1095 = float2(0.0, _685.fx_rim_uv.y);\n    float4 _1097 = tex.sample(smp, (uv - _1095));\n    float _1098 = _1097.w;\n    float4 _1108 = tex.sample(smp, (uv + _1095));\n    float _1109 = _1108.w;\n    float _1124 = _1076 - _1087;\n    float _1127 = _1109 - _1098;\n    float _1137 = cos(params.y);\n    float _1139 = sin(params.y);\n    float2 _1165 = ((float2(_1137, _1139) * _1124) + ((float2(-_1139, _1137) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1127)) / float2(fast::max(length(float2(_1124, _1127)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _685.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            to_l = _685.light_pos[i].xy / float2(fast::max(length(_685.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1211 = _685.light_pos[i].xy - world_xy;\n            float _1214 = length(_1211);\n            att = powr(fast::clamp(1.0 - (_1214 / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            to_l = _1211 / float2(fast::max(_1214, 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _685.light_shadow_v[i].x;\n                float param_1 = _685.light_shadow_v[i].y;\n                float2 param_2 = -_1211;\n                float param_3 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1211;\n            att *= cookie_att(param_4, param_5, _685, fx_cookie_tex, light_smp);\n        }\n        sum += (_685.light_color[i].xyz * (att * fast::max(dot(_1165, to_l), 0.0)));\n    }\n    return (sum * _685.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1076, _1087), fast::min(_1098, _1109))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _685)\n{\n    float2 _691 = gl_FragCoord.xy * _685.fa_target.xy;\n    float _695 = _691.y;\n    return float2(_691.x, mix(_695, 1.0 - _695, _685.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _733 = base_mode < 0.5;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _685), _685.fa_time.x, base_mode, float4(0.0), _745 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _685 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1608 = in.params.x > 31.5;\n    if (_1608)\n    {\n        mode -= 32.0;\n    }\n    float _1616 = mode;\n    bool _1618 = _1616 > 15.5;\n    if (_1618)\n    {\n        mode -= 16.0;\n    }\n    float _1626 = mode;\n    bool _1628 = _1626 > 7.5;\n    if (_1628)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1618)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1618)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1690 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1692 = _1690 * in.color;\n                float4 param_6 = _1692;\n                float param_7 = mode;\n                float _1699 = _1692.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1699);\n                if (_685.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1699;\n                    float param_9 = mode;\n                    float4 _1715 = out.frag_color;\n                    float3 _1717 = _1715.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1717.x;\n                    out.frag_color.y = _1717.y;\n                    out.frag_color.z = _1717.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1747 = length(in.uv);\n                    float _1750 = fwidth(_1747);\n                    float _1751 = fast::max(_1750, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1747) / _1751) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1747) / _1751) + 0.5, 0.0, 1.0) * fast::clamp(((_1747 - in.params.y) / _1751) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1791 = fast::clamp(1.0 - _1747, 0.0, 1.0);\n                            cov = (_1791 * _1791) * (3.0 - (2.0 * _1791));\n                        }\n                    }\n                    float3 _1800;\n                    if (_1618)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1800 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1800 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1800, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_685.fx_emit.w > 0.5)\n    {\n        float3 e = _685.fx_emit.xyz;\n        if (_685.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _685.fx_emit_uv.xy) + _685.fx_emit_uv.zw)).xyz;\n            float param_13 = _685.fx_emit.w - 2.0;\n            float3 _1855 = fa_tex_fix(param_12, param_13);\n            e *= _1855;\n        }\n        float4 _1859 = out.frag_color;\n        float3 _1861 = _1859.xyz + e;\n        out.frag_color.x = _1861.x;\n        out.frag_color.y = _1861.y;\n        out.frag_color.z = _1861.z;\n    }\n    float param_14 = mode;\n    float4 _2189 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _685, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2189 };\n    fragment0(param_15, param_16);\n    _2189 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1608)\n    {\n        float4 _1887 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1892 = scene_rgb(param_17, in.xform);\n        float3 _1896 = mix(_1887.xyz, _1892, float3(in.color2.w));\n        out.frag_color.x = _1896.x;\n        out.frag_color.y = _1896.y;\n        out.frag_color.z = _1896.z;\n    }\n    if (_1628)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1920 = _685.fog_col.w > 0.0;\n    bool _1928;\n    if (!_1920)\n    {\n        _1928 = _685.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1928 = _1920;\n    }\n    if (_1928)\n    {\n        float3 _1942 = float3(in.world_xy, in.world_z) - _685.fog_eye.xyz;\n        float _1949 = dot(_1942, _685.fog_c.xyz);\n        bool _1953 = _685.fog_c.w > 0.5;\n        float _1954;\n        if (_1953)\n        {\n            _1954 = _1949;\n        }\n        else\n        {\n            _1954 = length(_1942);\n        }\n        float _1966 = _1954 - _685.fog_b.x;\n        if (_1966 > 0.0)\n        {\n            float _1975 = _685.fog_col.w * _1966;\n            float tau = _1975 * _1975;\n            if (_685.fog_b.y > 0.0)\n            {\n                float _1991;\n                if (_1953)\n                {\n                    _1991 = in.world_xy.y - (_685.fog_c.y * _1949);\n                }\n                else\n                {\n                    _1991 = _685.fog_eye.y;\n                }\n                float _2012 = mix(_1991, in.world_xy.y, fast::clamp(_685.fog_b.x / _1954, 0.0, 1.0));\n                float _2016 = in.world_xy.y - _2012;\n                float _2021 = _2012 - _685.fog_b.z;\n                float _2026 = in.world_xy.y - _685.fog_b.z;\n                bool _2029 = _2021 <= 0.0;\n                bool _2030 = !_2029;\n                bool _2036;\n                if (_2030)\n                {\n                    _2036 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2036 = _2029;\n                }\n                float _2037;\n                if (_2036)\n                {\n                    _2037 = _685.fog_b.y;\n                }\n                else\n                {\n                    _2037 = _685.fog_b.y * exp(-fast::min(_685.fog_b.w * _2021, 80.0));\n                }\n                bool _2064;\n                if (_2030)\n                {\n                    _2064 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2064 = _2029;\n                }\n                float _2065;\n                if (_2064)\n                {\n                    _2065 = _685.fog_b.y * _2021;\n                }\n                else\n                {\n                    _2065 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2021, 80.0)))) / _685.fog_b.w;\n                }\n                bool _2090 = _2026 <= 0.0;\n                bool _2097;\n                if (!_2090)\n                {\n                    _2097 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2097 = _2090;\n                }\n                float _2098;\n                if (_2097)\n                {\n                    _2098 = _685.fog_b.y * _2026;\n                }\n                else\n                {\n                    _2098 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2026, 80.0)))) / _685.fog_b.w;\n                }\n                float _2125;\n                if (abs(_2016) < 0.001000000047497451305389404296875)\n                {\n                    _2125 = _2037;\n                }\n                else\n                {\n                    _2125 = (_2098 - _2065) / _2016;\n                }\n                tau += (_1966 * fast::max(_2125, 0.0));\n            }\n            float4 _2148 = out.frag_color;\n            float3 _2156 = mix(_2148.xyz, _685.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2156.x;\n            out.frag_color.y = _2156.y;\n            out.frag_color.z = _2156.z;\n        }\n    }\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _237 = tex.sample(smp, in.uv);\n    float3 param = _237.xyz;\n    float param_1 = in.xform.y;\n    float3 _248 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_248, _237.w) * in.color;\n    float param_2 = 0.0;\n    float4 _303 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _303 };\n    fragment0(param_3, param_4);\n    _303 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
