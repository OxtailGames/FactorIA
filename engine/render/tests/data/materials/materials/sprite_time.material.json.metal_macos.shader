{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _684, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_684.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _684.light_cookie[i];\n    float4 param_1 = _684.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _789 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _789.xy, level(0.0));\n    return cookie_value(param_3) * _789.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _684, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _811 = _684.lit.y > 0.5;\n    if (_811)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _684.normal_uv.xy) + _684.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _835 = fa_tex_fix(param, param_1);\n        float3 _839 = (_835 * 2.0) - float3(1.0);\n        float _846 = cos(params.y);\n        float _848 = sin(params.y);\n        n = fast::normalize(float3((float2(_846, _848) * _839.x) + ((float2(-_848, _846) * ((mode > 5.5) ? (-1.0) : 1.0)) * _839.y), fast::max(_839.z, 0.0500000007450580596923828125)));\n    }\n    bool _882 = !_811;\n    bool _888;\n    if (_882)\n    {\n        _888 = _684.lit.z > 0.5;\n    }\n    else\n    {\n        _888 = _882;\n    }\n    float3 _891;\n    if (_888)\n    {\n        _891 = _684.flat_ambient.xyz;\n    }\n    else\n    {\n        _891 = _684.ambient.xyz;\n    }\n    float3 total = _891;\n    bool _908;\n    if (_888)\n    {\n        _908 = _684.lit.z < 1.5;\n    }\n    else\n    {\n        _908 = _888;\n    }\n    if (_908)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _684.light_map.xy), level(0.0)).xyz * _684.light_map.z);\n    }\n    float3 l;\n    float _1035;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _945;\n        if (!_888)\n        {\n            _945 = float(i) >= _684.lit.x;\n        }\n        else\n        {\n            _945 = _888;\n        }\n        if (_945)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_684.light_pos[i].w < 0.0)\n        {\n            l = _684.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _971 = _684.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_971) / fast::max(_684.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _684.light_color[i].w);\n            float3 _991 = float3(_971, _684.light_pos[i].z);\n            l = _991 / float3(fast::max(length(_991), 9.9999997473787516355514526367188e-05));\n            if (_684.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _684.light_shadow_v[i].x;\n                float param_3 = _684.light_shadow_v[i].y;\n                float2 param_4 = -_971;\n                float param_5 = _684.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_971;\n            att *= cookie_att(param_6, param_7, _684, fx_cookie_tex, light_smp);\n        }\n        if (_811)\n        {\n            _1035 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1035 = 1.0;\n        }\n        total += (_684.light_color[i].xyz * (att * _1035));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1285 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1289 = uv * _1285;\n    float _1295 = _1285.x;\n    float _1297 = _1285.y;\n    float _1299 = fast::clamp(shape_rs.x, 0.0, fast::min(_1295, _1297));\n    float2 _1310 = (abs(_1289) - _1285) + float2(_1299);\n    float d = (length(fast::max(_1310, float2(0.0))) + fast::min(fast::max(_1310.x, _1310.y), 0.0)) - _1299;\n    float ax = params.y;\n    bool _1331 = params.y > 15.0;\n    if (_1331)\n    {\n        ax -= 20.0;\n    }\n    float _1342;\n    if (ax <= (-1.5))\n    {\n        _1342 = (-2.0) - ax;\n    }\n    else\n    {\n        _1342 = 0.0;\n    }\n    if (_1342 > 0.0)\n    {\n        float _1356 = _1342 * 0.5;\n        d = abs(d + _1356) - _1356;\n    }\n    float _1364 = fwidth(d);\n    float _1365 = fast::max(_1364, 9.9999997473787516355514526367188e-05);\n    float _1375 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1365)), 0.0, 1.0);\n    float _1380;\n    if (shape_rs.y > _1365)\n    {\n        _1380 = (_1375 * _1375) * (3.0 - (2.0 * _1375));\n    }\n    else\n    {\n        _1380 = _1375;\n    }\n    float4 c = color;\n    bool _1402 = (_1342 <= 0.0) && (ax > (-0.5));\n    if (_1402)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1417 = cos(ax);\n            float _1419 = sin(ax);\n            g = ((dot(_1289, float2(_1417, _1419)) / fast::max((abs(_1417) * _1295) + (abs(_1419) * _1297), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1331)\n        {\n            float4 _1462 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1462;\n            float3 param = _1462.xyz;\n            float param_1 = xform.y;\n            float3 _1469 = fa_tex_fix(param, param_1);\n            float4 _2257 = c;\n            _2257.x = _1469.x;\n            _2257.y = _1469.y;\n            _2257.z = _1469.z;\n            c = _2257;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1481 = scene_rgb(param_2, xform);\n            float4 _1506 = mix(float4(color.xyz * color.w, color.w), float4(_1481 * color2.w, color2.w), float4(g));\n            float _1508 = _1506.w;\n            float3 _1511;\n            if (_1508 > 9.9999997473787516355514526367188e-06)\n            {\n                _1511 = _1506.xyz / float3(_1508);\n            }\n            else\n            {\n                _1511 = color.xyz;\n            }\n            c = float4(_1511, _1508);\n        }\n    }\n    float4 _2266 = c;\n    _2266.w = _2266.w * _1380;\n    c = _2266;\n    if (_1402 || (shape_rs.y > 0.0))\n    {\n        float _1552 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1561 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1561 + float3(_1552 * 0.0039215688593685626983642578125);\n            float3 _1567 = fa_srgb_to_linear(param_4);\n            float4 _2269 = c;\n            _2269.x = _1567.x;\n            _2269.y = _1567.y;\n            _2269.z = _1567.z;\n            c = _2269;\n        }\n        else\n        {\n            float4 _1577 = c;\n            float3 _1580 = _1577.xyz + float3(_1552 * 0.0039215688593685626983642578125);\n            float4 _2276 = _1577;\n            _2276.x = _1580.x;\n            _2276.y = _1580.y;\n            _2276.z = _1580.z;\n            c = _2276;\n        }\n        float4 _2281 = c;\n        _2281.w = fast::clamp(_2281.w + ((_1552 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2281.w)), 0.0, 1.0);\n        c = _2281;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _684, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1072 = float2(_684.fx_rim_uv.x, 0.0);\n    float4 _1074 = tex.sample(smp, (uv - _1072));\n    float _1075 = _1074.w;\n    float4 _1085 = tex.sample(smp, (uv + _1072));\n    float _1086 = _1085.w;\n    float2 _1094 = float2(0.0, _684.fx_rim_uv.y);\n    float4 _1096 = tex.sample(smp, (uv - _1094));\n    float _1097 = _1096.w;\n    float4 _1107 = tex.sample(smp, (uv + _1094));\n    float _1108 = _1107.w;\n    float _1123 = _1075 - _1086;\n    float _1126 = _1108 - _1097;\n    float _1136 = cos(params.y);\n    float _1138 = sin(params.y);\n    float2 _1164 = ((float2(_1136, _1138) * _1123) + ((float2(-_1138, _1136) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1126)) / float2(fast::max(length(float2(_1123, _1126)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _684.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_684.light_pos[i].w < 0.0)\n        {\n            to_l = _684.light_pos[i].xy / float2(fast::max(length(_684.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1210 = _684.light_pos[i].xy - world_xy;\n            float _1213 = length(_1210);\n            att = powr(fast::clamp(1.0 - (_1213 / fast::max(_684.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _684.light_color[i].w);\n            to_l = _1210 / float2(fast::max(_1213, 9.9999997473787516355514526367188e-05));\n            if (_684.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _684.light_shadow_v[i].x;\n                float param_1 = _684.light_shadow_v[i].y;\n                float2 param_2 = -_1210;\n                float param_3 = _684.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1210;\n            att *= cookie_att(param_4, param_5, _684, fx_cookie_tex, light_smp);\n        }\n        sum += (_684.light_color[i].xyz * (att * fast::max(dot(_1164, to_l), 0.0)));\n    }\n    return (sum * _684.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1075, _1086), fast::min(_1097, _1108))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _684)\n{\n    float2 _690 = gl_FragCoord.xy * _684.fa_target.xy;\n    float _694 = _690.y;\n    return float2(_690.x, mix(_694, 1.0 - _694, _684.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _684, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _732 = base_mode < 0.5;\n    bool _743;\n    if (!_732)\n    {\n        _743 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _743 = _732;\n    }\n    float _744;\n    if (_743)\n    {\n        _744 = shape_half.x;\n    }\n    else\n    {\n        _744 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _684), _684.fa_time.x, base_mode, float4(0.0), _744 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _684 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1607 = in.params.x > 31.5;\n    if (_1607)\n    {\n        mode -= 32.0;\n    }\n    float _1615 = mode;\n    bool _1617 = _1615 > 15.5;\n    if (_1617)\n    {\n        mode -= 16.0;\n    }\n    float _1625 = mode;\n    bool _1627 = _1625 > 7.5;\n    if (_1627)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1617)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1617)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1689 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1691 = _1689 * in.color;\n                float4 param_6 = _1691;\n                float param_7 = mode;\n                float _1698 = _1691.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1698);\n                if (_684.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1698;\n                    float param_9 = mode;\n                    float4 _1714 = out.frag_color;\n                    float3 _1716 = _1714.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1716.x;\n                    out.frag_color.y = _1716.y;\n                    out.frag_color.z = _1716.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1746 = length(in.uv);\n                    float _1749 = fwidth(_1746);\n                    float _1750 = fast::max(_1749, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1746) / _1750) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1746) / _1750) + 0.5, 0.0, 1.0) * fast::clamp(((_1746 - in.params.y) / _1750) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1790 = fast::clamp(1.0 - _1746, 0.0, 1.0);\n                            cov = (_1790 * _1790) * (3.0 - (2.0 * _1790));\n                        }\n                    }\n                    float3 _1799;\n                    if (_1617)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1799 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1799 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1799, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_684.fx_emit.w > 0.5)\n    {\n        float3 e = _684.fx_emit.xyz;\n        if (_684.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _684.fx_emit_uv.xy) + _684.fx_emit_uv.zw)).xyz;\n            float param_13 = _684.fx_emit.w - 2.0;\n            float3 _1854 = fa_tex_fix(param_12, param_13);\n            e *= _1854;\n        }\n        float4 _1858 = out.frag_color;\n        float3 _1860 = _1858.xyz + e;\n        out.frag_color.x = _1860.x;\n        out.frag_color.y = _1860.y;\n        out.frag_color.z = _1860.z;\n    }\n    float param_14 = mode;\n    float4 _2187 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _684, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2187 };\n    fragment0(param_15, param_16);\n    _2187 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1607)\n    {\n        float4 _1886 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1891 = scene_rgb(param_17, in.xform);\n        float3 _1895 = mix(_1886.xyz, _1891, float3(in.color2.w));\n        out.frag_color.x = _1895.x;\n        out.frag_color.y = _1895.y;\n        out.frag_color.z = _1895.z;\n    }\n    if (_1627)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1919 = _684.fog_col.w > 0.0;\n    bool _1927;\n    if (!_1919)\n    {\n        _1927 = _684.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1927 = _1919;\n    }\n    if (_1927)\n    {\n        float3 _1941 = float3(in.world_xy, in.world_z) - _684.fog_eye.xyz;\n        float _1948 = dot(_1941, _684.fog_c.xyz);\n        bool _1952 = _684.fog_c.w > 0.5;\n        float _1953;\n        if (_1952)\n        {\n            _1953 = _1948;\n        }\n        else\n        {\n            _1953 = length(_1941);\n        }\n        float _1965 = _1953 - _684.fog_b.x;\n        if (_1965 > 0.0)\n        {\n            float _1974 = _684.fog_col.w * _1965;\n            float tau = _1974 * _1974;\n            if (_684.fog_b.y > 0.0)\n            {\n                float _1990;\n                if (_1952)\n                {\n                    _1990 = in.world_xy.y - (_684.fog_c.y * _1948);\n                }\n                else\n                {\n                    _1990 = _684.fog_eye.y;\n                }\n                float _2011 = mix(_1990, in.world_xy.y, fast::clamp(_684.fog_b.x / _1953, 0.0, 1.0));\n                float _2015 = in.world_xy.y - _2011;\n                float _2020 = _2011 - _684.fog_b.z;\n                float _2025 = in.world_xy.y - _684.fog_b.z;\n                bool _2028 = _2020 <= 0.0;\n                bool _2029 = !_2028;\n                bool _2035;\n                if (_2029)\n                {\n                    _2035 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2035 = _2028;\n                }\n                float _2036;\n                if (_2035)\n                {\n                    _2036 = _684.fog_b.y;\n                }\n                else\n                {\n                    _2036 = _684.fog_b.y * exp(-fast::min(_684.fog_b.w * _2020, 80.0));\n                }\n                bool _2063;\n                if (_2029)\n                {\n                    _2063 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2063 = _2028;\n                }\n                float _2064;\n                if (_2063)\n                {\n                    _2064 = _684.fog_b.y * _2020;\n                }\n                else\n                {\n                    _2064 = (_684.fog_b.y * (1.0 - exp(-fast::min(_684.fog_b.w * _2020, 80.0)))) / _684.fog_b.w;\n                }\n                bool _2089 = _2025 <= 0.0;\n                bool _2096;\n                if (!_2089)\n                {\n                    _2096 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2096 = _2089;\n                }\n                float _2097;\n                if (_2096)\n                {\n                    _2097 = _684.fog_b.y * _2025;\n                }\n                else\n                {\n                    _2097 = (_684.fog_b.y * (1.0 - exp(-fast::min(_684.fog_b.w * _2025, 80.0)))) / _684.fog_b.w;\n                }\n                float _2124;\n                if (abs(_2015) < 0.001000000047497451305389404296875)\n                {\n                    _2124 = _2036;\n                }\n                else\n                {\n                    _2124 = (_2097 - _2064) / _2015;\n                }\n                tau += (_1965 * fast::max(_2124, 0.0));\n            }\n            float4 _2147 = out.frag_color;\n            float3 _2155 = mix(_2147.xyz, _684.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2155.x;\n            out.frag_color.y = _2155.y;\n            out.frag_color.z = _2155.z;\n        }\n    }\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _235 = tex.sample(smp, in.uv);\n    float3 param = _235.xyz;\n    float param_1 = in.xform.y;\n    float3 _246 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_246, _235.w) * in.color;\n    float param_2 = 0.0;\n    float4 _300 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _300 };\n    fragment0(param_3, param_4);\n    _300 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
