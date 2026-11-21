{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _150 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _150;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _684, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_684.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _684.light_cookie[i];\n    float4 param_1 = _684.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _792 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _792.xy, level(0.0));\n    return cookie_value(param_3) * _792.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _684, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _814 = _684.lit.y > 0.5;\n    if (_814)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _684.normal_uv.xy) + _684.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _838 = fa_tex_fix(param, param_1);\n        float3 _842 = (_838 * 2.0) - float3(1.0);\n        float _849 = cos(params.y);\n        float _851 = sin(params.y);\n        n = fast::normalize(float3((float2(_849, _851) * _842.x) + ((float2(-_851, _849) * ((mode > 5.5) ? (-1.0) : 1.0)) * _842.y), fast::max(_842.z, 0.0500000007450580596923828125)));\n    }\n    bool _884 = !_814;\n    bool _890;\n    if (_884)\n    {\n        _890 = _684.lit.z > 0.5;\n    }\n    else\n    {\n        _890 = _884;\n    }\n    float3 _893;\n    if (_890)\n    {\n        _893 = _684.flat_ambient.xyz;\n    }\n    else\n    {\n        _893 = _684.ambient.xyz;\n    }\n    float3 total = _893;\n    bool _910;\n    if (_890)\n    {\n        _910 = _684.lit.z < 1.5;\n    }\n    else\n    {\n        _910 = _890;\n    }\n    if (_910)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _684.light_map.xy), level(0.0)).xyz * _684.light_map.z);\n    }\n    float3 l;\n    float _1037;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _947;\n        if (!_890)\n        {\n            _947 = float(i) >= _684.lit.x;\n        }\n        else\n        {\n            _947 = _890;\n        }\n        if (_947)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_684.light_pos[i].w < 0.0)\n        {\n            l = _684.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _973 = _684.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_973) / fast::max(_684.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _684.light_color[i].w);\n            float3 _993 = float3(_973, _684.light_pos[i].z);\n            l = _993 / float3(fast::max(length(_993), 9.9999997473787516355514526367188e-05));\n            if (_684.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _684.light_shadow_v[i].x;\n                float param_3 = _684.light_shadow_v[i].y;\n                float2 param_4 = -_973;\n                float param_5 = _684.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_973;\n            att *= cookie_att(param_6, param_7, _684, fx_cookie_tex, light_smp);\n        }\n        if (_814)\n        {\n            _1037 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1037 = 1.0;\n        }\n        total += (_684.light_color[i].xyz * (att * _1037));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1287 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1291 = uv * _1287;\n    float _1297 = _1287.x;\n    float _1299 = _1287.y;\n    float _1301 = fast::clamp(shape_rs.x, 0.0, fast::min(_1297, _1299));\n    float2 _1312 = (abs(_1291) - _1287) + float2(_1301);\n    float d = (length(fast::max(_1312, float2(0.0))) + fast::min(fast::max(_1312.x, _1312.y), 0.0)) - _1301;\n    float ax = params.y;\n    bool _1333 = params.y > 15.0;\n    if (_1333)\n    {\n        ax -= 20.0;\n    }\n    float _1344;\n    if (ax <= (-1.5))\n    {\n        _1344 = (-2.0) - ax;\n    }\n    else\n    {\n        _1344 = 0.0;\n    }\n    if (_1344 > 0.0)\n    {\n        float _1358 = _1344 * 0.5;\n        d = abs(d + _1358) - _1358;\n    }\n    float _1366 = fwidth(d);\n    float _1367 = fast::max(_1366, 9.9999997473787516355514526367188e-05);\n    float _1377 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1367)), 0.0, 1.0);\n    float _1382;\n    if (shape_rs.y > _1367)\n    {\n        _1382 = (_1377 * _1377) * (3.0 - (2.0 * _1377));\n    }\n    else\n    {\n        _1382 = _1377;\n    }\n    float4 c = color;\n    bool _1404 = (_1344 <= 0.0) && (ax > (-0.5));\n    if (_1404)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1419 = cos(ax);\n            float _1421 = sin(ax);\n            g = ((dot(_1291, float2(_1419, _1421)) / fast::max((abs(_1419) * _1297) + (abs(_1421) * _1299), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1333)\n        {\n            float4 _1464 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1464;\n            float3 param = _1464.xyz;\n            float param_1 = xform.y;\n            float3 _1471 = fa_tex_fix(param, param_1);\n            float4 _2259 = c;\n            _2259.x = _1471.x;\n            _2259.y = _1471.y;\n            _2259.z = _1471.z;\n            c = _2259;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1483 = scene_rgb(param_2, xform);\n            float4 _1508 = mix(float4(color.xyz * color.w, color.w), float4(_1483 * color2.w, color2.w), float4(g));\n            float _1510 = _1508.w;\n            float3 _1513;\n            if (_1510 > 9.9999997473787516355514526367188e-06)\n            {\n                _1513 = _1508.xyz / float3(_1510);\n            }\n            else\n            {\n                _1513 = color.xyz;\n            }\n            c = float4(_1513, _1510);\n        }\n    }\n    float4 _2268 = c;\n    _2268.w = _2268.w * _1382;\n    c = _2268;\n    if (_1404 || (shape_rs.y > 0.0))\n    {\n        float _1554 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1563 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1563 + float3(_1554 * 0.0039215688593685626983642578125);\n            float3 _1569 = fa_srgb_to_linear(param_4);\n            float4 _2271 = c;\n            _2271.x = _1569.x;\n            _2271.y = _1569.y;\n            _2271.z = _1569.z;\n            c = _2271;\n        }\n        else\n        {\n            float4 _1579 = c;\n            float3 _1582 = _1579.xyz + float3(_1554 * 0.0039215688593685626983642578125);\n            float4 _2278 = _1579;\n            _2278.x = _1582.x;\n            _2278.y = _1582.y;\n            _2278.z = _1582.z;\n            c = _2278;\n        }\n        float4 _2283 = c;\n        _2283.w = fast::clamp(_2283.w + ((_1554 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2283.w)), 0.0, 1.0);\n        c = _2283;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _684, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1074 = float2(_684.fx_rim_uv.x, 0.0);\n    float4 _1076 = tex.sample(smp, (uv - _1074));\n    float _1077 = _1076.w;\n    float4 _1087 = tex.sample(smp, (uv + _1074));\n    float _1088 = _1087.w;\n    float2 _1096 = float2(0.0, _684.fx_rim_uv.y);\n    float4 _1098 = tex.sample(smp, (uv - _1096));\n    float _1099 = _1098.w;\n    float4 _1109 = tex.sample(smp, (uv + _1096));\n    float _1110 = _1109.w;\n    float _1125 = _1077 - _1088;\n    float _1128 = _1110 - _1099;\n    float _1138 = cos(params.y);\n    float _1140 = sin(params.y);\n    float2 _1166 = ((float2(_1138, _1140) * _1125) + ((float2(-_1140, _1138) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1128)) / float2(fast::max(length(float2(_1125, _1128)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _684.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_684.light_pos[i].w < 0.0)\n        {\n            to_l = _684.light_pos[i].xy / float2(fast::max(length(_684.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1212 = _684.light_pos[i].xy - world_xy;\n            float _1215 = length(_1212);\n            att = powr(fast::clamp(1.0 - (_1215 / fast::max(_684.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _684.light_color[i].w);\n            to_l = _1212 / float2(fast::max(_1215, 9.9999997473787516355514526367188e-05));\n            if (_684.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _684.light_shadow_v[i].x;\n                float param_1 = _684.light_shadow_v[i].y;\n                float2 param_2 = -_1212;\n                float param_3 = _684.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1212;\n            att *= cookie_att(param_4, param_5, _684, fx_cookie_tex, light_smp);\n        }\n        sum += (_684.light_color[i].xyz * (att * fast::max(dot(_1166, to_l), 0.0)));\n    }\n    return (sum * _684.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1077, _1088), fast::min(_1099, _1110))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _684)\n{\n    float2 _690 = gl_FragCoord.xy * _684.fa_target.xy;\n    float _694 = _690.y;\n    return float2(_690.x, mix(_694, 1.0 - _694, _684.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _684, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _732 = base_mode < 0.5;\n    bool _743;\n    if (!_732)\n    {\n        _743 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _743 = _732;\n    }\n    float _744;\n    if (_743)\n    {\n        _744 = shape_half.x;\n    }\n    else\n    {\n        _744 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _684), _684.fa_time.x, base_mode, float4(0.0), _744 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _763 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _763.x;\n    s.color.y = _763.y;\n    s.color.z = _763.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _684 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], texture2d<float> fx_emissive_tex [[texture(5)]], texture2d<float> fx_cookie_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1609 = in.params.x > 31.5;\n    if (_1609)\n    {\n        mode -= 32.0;\n    }\n    float _1617 = mode;\n    bool _1619 = _1617 > 15.5;\n    if (_1619)\n    {\n        mode -= 16.0;\n    }\n    float _1627 = mode;\n    bool _1629 = _1627 > 7.5;\n    if (_1629)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1619)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1619)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1691 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1693 = _1691 * in.color;\n                float4 param_6 = _1693;\n                float param_7 = mode;\n                float _1700 = _1693.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1700);\n                if (_684.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1700;\n                    float param_9 = mode;\n                    float4 _1716 = out.frag_color;\n                    float3 _1718 = _1716.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1718.x;\n                    out.frag_color.y = _1718.y;\n                    out.frag_color.z = _1718.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1748 = length(in.uv);\n                    float _1751 = fwidth(_1748);\n                    float _1752 = fast::max(_1751, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1748) / _1752) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1748) / _1752) + 0.5, 0.0, 1.0) * fast::clamp(((_1748 - in.params.y) / _1752) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1792 = fast::clamp(1.0 - _1748, 0.0, 1.0);\n                            cov = (_1792 * _1792) * (3.0 - (2.0 * _1792));\n                        }\n                    }\n                    float3 _1801;\n                    if (_1619)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1801 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _684, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1801 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1801, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_684.fx_emit.w > 0.5)\n    {\n        float3 e = _684.fx_emit.xyz;\n        if (_684.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _684.fx_emit_uv.xy) + _684.fx_emit_uv.zw)).xyz;\n            float param_13 = _684.fx_emit.w - 2.0;\n            float3 _1856 = fa_tex_fix(param_12, param_13);\n            e *= _1856;\n        }\n        float4 _1860 = out.frag_color;\n        float3 _1862 = _1860.xyz + e;\n        out.frag_color.x = _1862.x;\n        out.frag_color.y = _1862.y;\n        out.frag_color.z = _1862.z;\n    }\n    float param_14 = mode;\n    float4 _2189 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _684, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2189 };\n    fragment0(param_15, param_16, mask, mask_smp);\n    _2189 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1609)\n    {\n        float4 _1888 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1893 = scene_rgb(param_17, in.xform);\n        float3 _1897 = mix(_1888.xyz, _1893, float3(in.color2.w));\n        out.frag_color.x = _1897.x;\n        out.frag_color.y = _1897.y;\n        out.frag_color.z = _1897.z;\n    }\n    if (_1629)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1921 = _684.fog_col.w > 0.0;\n    bool _1929;\n    if (!_1921)\n    {\n        _1929 = _684.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1929 = _1921;\n    }\n    if (_1929)\n    {\n        float3 _1943 = float3(in.world_xy, in.world_z) - _684.fog_eye.xyz;\n        float _1950 = dot(_1943, _684.fog_c.xyz);\n        bool _1954 = _684.fog_c.w > 0.5;\n        float _1955;\n        if (_1954)\n        {\n            _1955 = _1950;\n        }\n        else\n        {\n            _1955 = length(_1943);\n        }\n        float _1967 = _1955 - _684.fog_b.x;\n        if (_1967 > 0.0)\n        {\n            float _1976 = _684.fog_col.w * _1967;\n            float tau = _1976 * _1976;\n            if (_684.fog_b.y > 0.0)\n            {\n                float _1992;\n                if (_1954)\n                {\n                    _1992 = in.world_xy.y - (_684.fog_c.y * _1950);\n                }\n                else\n                {\n                    _1992 = _684.fog_eye.y;\n                }\n                float _2013 = mix(_1992, in.world_xy.y, fast::clamp(_684.fog_b.x / _1955, 0.0, 1.0));\n                float _2017 = in.world_xy.y - _2013;\n                float _2022 = _2013 - _684.fog_b.z;\n                float _2027 = in.world_xy.y - _684.fog_b.z;\n                bool _2030 = _2022 <= 0.0;\n                bool _2031 = !_2030;\n                bool _2037;\n                if (_2031)\n                {\n                    _2037 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2037 = _2030;\n                }\n                float _2038;\n                if (_2037)\n                {\n                    _2038 = _684.fog_b.y;\n                }\n                else\n                {\n                    _2038 = _684.fog_b.y * exp(-fast::min(_684.fog_b.w * _2022, 80.0));\n                }\n                bool _2065;\n                if (_2031)\n                {\n                    _2065 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2065 = _2030;\n                }\n                float _2066;\n                if (_2065)\n                {\n                    _2066 = _684.fog_b.y * _2022;\n                }\n                else\n                {\n                    _2066 = (_684.fog_b.y * (1.0 - exp(-fast::min(_684.fog_b.w * _2022, 80.0)))) / _684.fog_b.w;\n                }\n                bool _2091 = _2027 <= 0.0;\n                bool _2098;\n                if (!_2091)\n                {\n                    _2098 = _684.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2098 = _2091;\n                }\n                float _2099;\n                if (_2098)\n                {\n                    _2099 = _684.fog_b.y * _2027;\n                }\n                else\n                {\n                    _2099 = (_684.fog_b.y * (1.0 - exp(-fast::min(_684.fog_b.w * _2027, 80.0)))) / _684.fog_b.w;\n                }\n                float _2126;\n                if (abs(_2017) < 0.001000000047497451305389404296875)\n                {\n                    _2126 = _2038;\n                }\n                else\n                {\n                    _2126 = (_2099 - _2066) / _2017;\n                }\n                tau += (_1967 * fast::max(_2126, 0.0));\n            }\n            float4 _2149 = out.frag_color;\n            float3 _2157 = mix(_2149.xyz, _684.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2157.x;\n            out.frag_color.y = _2157.y;\n            out.frag_color.z = _2157.z;\n        }\n    }\n    return out;\n}\n\n",
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
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
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
              "msl_texture_n": 6
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
          },
          {
            "slot": 6,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _150 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _150;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _223 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _223.x;\n    s.color.y = _223.y;\n    s.color.z = _223.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _238 = tex.sample(smp, in.uv);\n    float3 param = _238.xyz;\n    float param_1 = in.xform.y;\n    float3 _249 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_249, _238.w) * in.color;\n    float param_2 = 0.0;\n    float4 _303 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _303 };\n    fragment0(param_3, param_4, mask, mask_smp);\n    _303 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
          }
        ],
        "samplers": [
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
