{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _684, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_684.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _684.light_cookie[i];\n    float4 param_1 = _684.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _797 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _797.xy, level(0.0));\n    return cookie_value(param_3) * _797.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _684, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _819 = _684.lit.y > 0.5;\n    if (_819)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _684.normal_uv.xy) + _684.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _843 = fa_tex_fix(param, param_1);\n        float3 _847 = (_843 * 2.0) - float3(1.0);\n        float _854 = cos(params.y);\n        float _856 = sin(params.y);\n        n = fast::normalize(float3((float2(_854, _856) * _847.x) + ((float2(-_856, _854) * ((mode > 5.5) ? (-1.0) : 1.0)) * _847.y), fast::max(_847.z, 0.0500000007450580596923828125)));\n    }\n    bool _890 = !_819;\n    bool _896;\n    if (_890)\n    {\n        _896 = _684.lit.z > 0.5;\n    }\n    else\n    {\n        _896 = _890;\n    }\n    float3 _899;\n    if (_896)\n    {\n        _899 = _684.flat_ambient.xyz;\n    }\n    else\n    {\n        _899 = _684.ambient.xyz;\n    }\n    float3 total = _899;\n    bool _916;\n    if (_896)\n    {\n        _916 = _684.lit.z < 1.5;\n    }\n    else\n    {\n        _916 = _896;\n    }\n    if (_916)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _684.light_map.xy), level(0.0)).xyz * _684.light_map.z);\n    }\n    float3 l;\n    float _1043;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _953;\n        if (!_896)\n        {\n            _953 = float(i) >= _684.lit.x;\n        }\n        else\n        {\n            _953 = _896;\n        }\n        if (_953)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_684.light_pos[i].w < 0.0)\n        {\n            l = _684.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _979 = _684.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_979) / fast::max(_684.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _684.light_color[i].w);\n            float3 _999 = float3(_979, _684.light_pos[i].z);\n            l = _999 / float3(fast::max(length(_999), 9.9999997473787516355514526367188e-05));\n            if (_684.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _684.light_shadow_v[i].x;\n                float param_3 = _684.light_shadow_v[i].y;\n                float2 param_4 = -_979;\n                float param_5 = _684.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_979;\n            att *= cookie_att(param_6, param_7, _684, fx_cookie_tex, light_smp);\n        }\n        if (_819)\n        {\n            _1043 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1043 = 1.0;\n        }\n        total += (_684.light_color[i].xyz * (att * _1043));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1293 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1297 = uv * _1293;\n    float _1303 = _1293.x;\n    float _1305 = _1293.y;\n    float _1307 = fast::clamp(shape_rs.x, 0.0, fast::min(_1303, _1305));\n    float2 _1318 = (abs(_1297) - _1293) + float2(_1307);\n    float d = (length(fast::max(_1318, float2(0.0))) + fast::min(fast::max(_1318.x, _1318.y), 0.0)) - _1307;\n    float ax = params.y;\n    bool _1339 = params.y > 15.0;\n    if (_1339)\n    {\n        ax -= 20.0;\n    }\n    float _1350;\n    if (ax <= (-1.5))\n    {\n        _1350 = (-2.0) - ax;\n    }\n    else\n    {\n        _1350 = 0.0;\n    }\n    if (_1350 > 0.0)\n    {\n        float _1364 = _1350 * 0.5;\n        d = abs(d + _1364) - _1364;\n    }\n    float _1372 = fwidth(d);\n    float _1373 = fast::max(_1372, 9.9999997473787516355514526367188e-05);\n    float _1383 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1373)), 0.0, 1.0);\n    float _1388;\n    if (shape_rs.y > _1373)\n    {\n        _1388 = (_1383 * _1383) * (3.0 - (2.0 * _1383));\n    }\n    else\n    {\n        _1388 = _1383;\n    }\n    float4 c = color;\n    bool _1410 = (_1350 <= 0.0) && (ax > (-0.5));\n    if (_1410)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1425 = cos(ax);\n            float _1427 = sin(ax);\n            g = ((dot(_1297, float2(_1425, _1427)) / fast::max((abs(_1425) * _1303) + (abs(_1427) * _1305), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1339)\n        {\n            float4 _1470 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1470;\n            float3 param = _1470.xyz;\n            float param_1 = xform.y;\n            float3 _1477 = fa_tex_fix(param, param_1);\n            float4 _2265 = c;\n            _2265.x = _1477.x;\n            _2265.y = _1477.y;\n            _2265.z = _1477.z;\n            c = _2265;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1489 = scene_rgb(param_2, xform);\n            float4 _1514 = mix(float4(color.xyz * color.w, color.w), float4(_1489 * color2.w, color2.w), float4(g));\n            float _1516 = _1514.w;\n            float3 _1519;\n            if (_1516 > 9.9999997473787516355514526367188e-06)\n            {\n                _1519 = _1514.xyz / float3(_1516);\n            }\n            else\n            {\n                _1519 = color.xyz;\n            }\n            c = float4(_1519, _1516);\n        }\n    }\n    float4 _2274 = c;\n    _2274.w = _2274.w * _1388;\n    c = _2274;\n    if (_1410 || (shape_rs.y > 0.0))\n    {\n        float _1560 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1569 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1569 + float3(_1560 * 0.0039215688593685626983642578125);\n            float3 _1575 = fa_srgb_to_linear(param_4);\n            float4 _2277 = c;\n            _2277.x = _1575.x;\n            _2277.y = _1575.y;\n            _2277.z = _1575.z;\n            c = _2277;\n        }\n        else\n        {\n            float4 _1585 = c;\n            float3 _1588 = _1585.xyz + float3(_1560 * 0.0039215688593685626983642578125);\n            float4 _2284 = _1585;\n            _2284.x = _1588.x;\n            _2284.y = _1588.y;\n            _2284.z = _1588.z;\n            c = _2284;\n        }\n        float4 _2289 = c;\n        _2289.w = fast::clamp(_2289.w + ((_1560 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2289.w)), 0.0, 1.0);\n        c = _2289;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _684, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1080 = float2(_684.fx_rim_uv.x, 0.0);\n    float4 _1082 = tex.sample(smp, (uv - _1080));\n    float _1083 = _1082.w;\n    float4 _1093 = tex.sample(smp, (uv + _1080));\n    float _1094 = _1093.w;\n    float2 _1102 = float2(0.0, _684.fx_rim_uv.y);\n    float4 _1104 = tex.sample(smp, (uv - _1102));\n    float _1105 = _1104.w;\n    float4 _1115 = tex.sample(smp, (uv + _1102));\n    float _1116 = _1115.w;\n    float _1131 = _1083 - _1094;\n    float _1134 = _1116 - _1105;\n    float _1144 = cos(params.y);\n    float _1146 = sin(params.y);\n    float2 _1172 = ((float2(_1144, _1146) * _1131) + ((float2(-_1146, _1144) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1134)) / float2(fast::max(length(float2(_1131, _1134)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _684.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_684.light_pos[i].w < 0.0)\n        {\n            to_l = _684.light_pos[i].xy / float2(fast::max(length(_684.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1218 = _684.light_pos[i].xy - world_xy;\n            float _1221 = length(_1218);\n            att = powr(fast::clamp(1.0 - (_1221 / fast::max(_684.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _684.light_color[i].w);\n            to_l = _1218 / float2(fast::max(_1221, 9.9999997473787516355514526367188e-05));\n            if (_684.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _684.light_shadow_v[i].x;\n                float param_1 = _684.light_shadow_v[i].y;\n                float2 param_2 = -_1218;\n                float param_3 = _684.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1218;\n            att *= cookie_att(param_4, param_5, _684, fx_cookie_tex, light_smp);\n        }\n        sum += (_684.light_color[i].xyz * (att * fast::max(dot(_1172, to_l), 0.0)));\n    }\n    return (sum * _684.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1083, _1094), fast::min(_1105, _1116))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _684)\n{\n    float2 _690 = gl_FragCoord.xy * _684.fa_target.xy;\n    float _694 = _690.y;\n    return float2(_690.x, mix(_694, 1.0 - _694, _684.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _684, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _732 = base_mode < 0.5;\n    bool _743;\n    if (!_732)\n    {\n        _743 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _743 = _732;\n    }\n    float _744;\n    if (_743)\n    {\n        _744 = shape_half.x;\n    }\n    else\n    {\n        _744 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _684), _684.fa_time.x, base_mode, float4(0.0), _744 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _760)\n{\n    bool _763 = i.screen_uv.x < _760.cut;\n    bool _772;\n    if (!_763)\n    {\n        _772 = i.screen_uv.y < _760.cutY;\n    }\n    else\n    {\n        _772 = _763;\n    }\n    if (_772)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _684 [[buffer(1)]], constant fa_material& _760 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1615 = in.params.x > 31.5;\n    if (_1615)\n    {\n        mode -= 32.0;\n    }\n    float _1623 = mode;\n    bool _1625 = _1623 > 15.5;\n    if (_1625)\n    {\n        mode -= 16.0;\n    }\n    float _1633 = mode;\n    bool _1635 = _1633 > 7.5;\n    if (_1635)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1625)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1625)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1697 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1699 = _1697 * in.color;\n                float4 param_6 = _1699;\n                float param_7 = mode;\n                float _1706 = _1699.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1706);\n                if (_684.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1706;\n                    float param_9 = mode;\n                    float4 _1722 = out.frag_color;\n                    float3 _1724 = _1722.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1724.x;\n                    out.frag_color.y = _1724.y;\n                    out.frag_color.z = _1724.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1754 = length(in.uv);\n                    float _1757 = fwidth(_1754);\n                    float _1758 = fast::max(_1757, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1754) / _1758) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1754) / _1758) + 0.5, 0.0, 1.0) * fast::clamp(((_1754 - in.params.y) / _1758) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1798 = fast::clamp(1.0 - _1754, 0.0, 1.0);\n                            cov = (_1798 * _1798) * (3.0 - (2.0 * _1798));\n                        }\n                    }\n                    float3 _1807;\n                    if (_1625)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1807 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1807 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1807, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_684.fx_emit.w > 0.5)\n    {\n        float3 e = _684.fx_emit.xyz;\n        if (_684.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _684.fx_emit_uv.xy) + _684.fx_emit_uv.zw)).xyz;\n            float param_13 = _684.fx_emit.w - 2.0;\n            float3 _1862 = fa_tex_fix(param_12, param_13);\n            e *= _1862;\n        }\n        float4 _1866 = out.frag_color;\n        float3 _1868 = _1866.xyz + e;\n        out.frag_color.x = _1868.x;\n        out.frag_color.y = _1868.y;\n        out.frag_color.z = _1868.z;\n    }\n    float param_14 = mode;\n    float4 _2195 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _684, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2195 };\n    fragment0(param_15, param_16, _760);\n    _2195 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1615)\n    {\n        float4 _1894 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1899 = scene_rgb(param_17, in.xform);\n        float3 _1903 = mix(_1894.xyz, _1899, float3(in.color2.w));\n        out.frag_color.x = _1903.x;\n        out.frag_color.y = _1903.y;\n        out.frag_color.z = _1903.z;\n    }\n    if (_1635)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1927 = _684.fog_col.w > 0.0;\n    bool _1935;\n    if (!_1927)\n    {\n        _1935 = _684.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1935 = _1927;\n    }\n    if (_1935)\n    {\n        float3 _1949 = float3(in.world_xy, in.world_z) - _684.fog_eye.xyz;\n        float _1956 = dot(_1949, _684.fog_c.xyz);\n        bool _1960 = _684.fog_c.w > 0.5;\n        float _1961;\n        if (_1960)\n        {\n            _1961 = _1956;\n        }\n        else\n        {\n            _1961 = length(_1949);\n        }\n        float _1973 = _1961 - _684.fog_b.x;\n        if (_1973 > 0.0)\n        {\n            float _1982 = _684.fog_col.w * _1973;\n            float tau = _1982 * _1982;\n            if (_684.fog_b.y > 0.0)\n            {\n                float _1998;\n                if (_1960)\n                {\n                    _1998 = in.world_xy.y - (_684.fog_c.y * _1956);\n                }\n                else\n                {\n                    _1998 = _684.fog_eye.y;\n                }\n                float _2019 = mix(_1998, in.world_xy.y, fast::clamp(_684.fog_b.x / _1961, 0.0, 1.0));\n                float _2023 = in.world_xy.y - _2019;\n                float _2028 = _2019 - _684.fog_b.z;\n                float _2033 = in.world_xy.y - _684.fog_b.z;\n                bool _2036 = _2028 <= 0.0;\n                bool _2037 = !_2036;\n                bool _2043;\n                if (_2037)\n                {\n                    _2043 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2043 = _2036;\n                }\n                float _2044;\n                if (_2043)\n                {\n                    _2044 = _684.fog_b.y;\n                }\n                else\n                {\n                    _2044 = _684.fog_b.y * exp(-fast::min(_684.fog_b.w * _2028, 80.0));\n                }\n                bool _2071;\n                if (_2037)\n                {\n                    _2071 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2071 = _2036;\n                }\n                float _2072;\n                if (_2071)\n                {\n                    _2072 = _684.fog_b.y * _2028;\n                }\n                else\n                {\n                    _2072 = (_684.fog_b.y * (1.0 - exp(-fast::min(_684.fog_b.w * _2028, 80.0)))) / _684.fog_b.w;\n                }\n                bool _2097 = _2033 <= 0.0;\n                bool _2104;\n                if (!_2097)\n                {\n                    _2104 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2104 = _2097;\n                }\n                float _2105;\n                if (_2104)\n                {\n                    _2105 = _684.fog_b.y * _2033;\n                }\n                else\n                {\n                    _2105 = (_684.fog_b.y * (1.0 - exp(-fast::min(_684.fog_b.w * _2033, 80.0)))) / _684.fog_b.w;\n                }\n                float _2132;\n                if (abs(_2023) < 0.001000000047497451305389404296875)\n                {\n                    _2132 = _2044;\n                }\n                else\n                {\n                    _2132 = (_2105 - _2072) / _2023;\n                }\n                tau += (_1973 * fast::max(_2132, 0.0));\n            }\n            float4 _2155 = out.frag_color;\n            float3 _2163 = mix(_2155.xyz, _684.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2163.x;\n            out.frag_color.y = _2163.y;\n            out.frag_color.z = _2163.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_684",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_760",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _215)\n{\n    bool _218 = i.screen_uv.x < _215.cut;\n    bool _227;\n    if (!_218)\n    {\n        _227 = i.screen_uv.y < _215.cutY;\n    }\n    else\n    {\n        _227 = _218;\n    }\n    if (_227)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], constant fa_material& _215 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _243 = tex.sample(smp, in.uv);\n    float3 param = _243.xyz;\n    float param_1 = in.xform.y;\n    float3 _254 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_254, _243.w) * in.color;\n    float param_2 = 0.0;\n    float4 _308 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _308 };\n    fragment0(param_3, param_4, _215);\n    _308 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_129",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_215",
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
