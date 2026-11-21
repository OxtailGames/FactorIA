{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _647 = tex.sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _695, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _832 = (world_xy * _695.gi_xf.xy) + _695.gi_xf.zw;\n    float4 _839 = fx_gi_tex.sample(light_smp, _832, level(0.0));\n    float _843 = _832.x;\n    bool _844 = _843 >= 0.0;\n    bool _850;\n    if (_844)\n    {\n        _850 = _832.y >= 0.0;\n    }\n    else\n    {\n        _850 = _844;\n    }\n    bool _856;\n    if (_850)\n    {\n        _856 = _843 <= 1.0;\n    }\n    else\n    {\n        _856 = _850;\n    }\n    bool _862;\n    if (_856)\n    {\n        _862 = _832.y <= 1.0;\n    }\n    else\n    {\n        _862 = _856;\n    }\n    bool _870;\n    if (_862)\n    {\n        _870 = _839.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _870 = _862;\n    }\n    float3 _871;\n    if (_870)\n    {\n        _871 = (_839.xyz / float3(_839.w)) * _695.gi_p.x;\n    }\n    else\n    {\n        _871 = float3(0.0);\n    }\n    return _871;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _137 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = precise::atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = fast::min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = precise::atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = fast::min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    float2 c = float2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = fast::clamp(_532, float2(0.001953125), float2(0.998046875));\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _695, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_695.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _695.light_cookie[i];\n    float4 param_1 = _695.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _806 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _806.xy, level(0.0));\n    return cookie_value(param_3) * _806.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _695, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _893 = _695.lit.y > 0.5;\n    if (_893)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _695.normal_uv.xy) + _695.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _917 = fa_tex_fix(param, param_1);\n        float3 _921 = (_917 * 2.0) - float3(1.0);\n        float _928 = cos(params.y);\n        float _930 = sin(params.y);\n        n = fast::normalize(float3((float2(_928, _930) * _921.x) + ((float2(-_930, _928) * ((mode > 5.5) ? (-1.0) : 1.0)) * _921.y), fast::max(_921.z, 0.0500000007450580596923828125)));\n    }\n    bool _964 = !_893;\n    bool _970;\n    if (_964)\n    {\n        _970 = _695.lit.z > 0.5;\n    }\n    else\n    {\n        _970 = _964;\n    }\n    float3 _973;\n    if (_970)\n    {\n        _973 = _695.flat_ambient.xyz;\n    }\n    else\n    {\n        _973 = _695.ambient.xyz;\n    }\n    float3 total = _973;\n    if (_695.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_695, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _998;\n    if (_970)\n    {\n        _998 = _695.lit.z < 1.5;\n    }\n    else\n    {\n        _998 = _970;\n    }\n    if (_998)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _695.light_map.xy), level(0.0)).xyz * _695.light_map.z);\n    }\n    float3 l;\n    float _1125;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1035;\n        if (!_970)\n        {\n            _1035 = float(i) >= _695.lit.x;\n        }\n        else\n        {\n            _1035 = _970;\n        }\n        if (_1035)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_695.light_pos[i].w < 0.0)\n        {\n            l = _695.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1061 = _695.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1061) / fast::max(_695.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _695.light_color[i].w);\n            float3 _1081 = float3(_1061, _695.light_pos[i].z);\n            l = _1081 / float3(fast::max(length(_1081), 9.9999997473787516355514526367188e-05));\n            if (_695.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _695.light_shadow_v[i].x;\n                float param_3 = _695.light_shadow_v[i].y;\n                float2 param_4 = -_1061;\n                float param_5 = _695.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1061;\n            att *= cookie_att(param_6, param_7, _695, fx_cookie_tex, light_smp);\n        }\n        if (_893)\n        {\n            _1125 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1125 = 1.0;\n        }\n        total += (_695.light_color[i].xyz * (att * _1125));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1375 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1379 = uv * _1375;\n    float _1385 = _1375.x;\n    float _1387 = _1375.y;\n    float _1389 = fast::clamp(shape_rs.x, 0.0, fast::min(_1385, _1387));\n    float2 _1400 = (abs(_1379) - _1375) + float2(_1389);\n    float d = (length(fast::max(_1400, float2(0.0))) + fast::min(fast::max(_1400.x, _1400.y), 0.0)) - _1389;\n    float ax = params.y;\n    bool _1421 = params.y > 15.0;\n    if (_1421)\n    {\n        ax -= 20.0;\n    }\n    float _1432;\n    if (ax <= (-1.5))\n    {\n        _1432 = (-2.0) - ax;\n    }\n    else\n    {\n        _1432 = 0.0;\n    }\n    if (_1432 > 0.0)\n    {\n        float _1446 = _1432 * 0.5;\n        d = abs(d + _1446) - _1446;\n    }\n    float _1454 = fwidth(d);\n    float _1455 = fast::max(_1454, 9.9999997473787516355514526367188e-05);\n    float _1465 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1455)), 0.0, 1.0);\n    float _1470;\n    if (shape_rs.y > _1455)\n    {\n        _1470 = (_1465 * _1465) * (3.0 - (2.0 * _1465));\n    }\n    else\n    {\n        _1470 = _1465;\n    }\n    float4 c = color;\n    bool _1492 = (_1432 <= 0.0) && (ax > (-0.5));\n    if (_1492)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1507 = cos(ax);\n            float _1509 = sin(ax);\n            g = ((dot(_1379, float2(_1507, _1509)) / fast::max((abs(_1507) * _1385) + (abs(_1509) * _1387), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1421)\n        {\n            float4 _1552 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1552;\n            float3 param = _1552.xyz;\n            float param_1 = xform.y;\n            float3 _1559 = fa_tex_fix(param, param_1);\n            float4 _2353 = c;\n            _2353.x = _1559.x;\n            _2353.y = _1559.y;\n            _2353.z = _1559.z;\n            c = _2353;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1571 = scene_rgb(param_2, xform);\n            float4 _1596 = mix(float4(color.xyz * color.w, color.w), float4(_1571 * color2.w, color2.w), float4(g));\n            float _1598 = _1596.w;\n            float3 _1601;\n            if (_1598 > 9.9999997473787516355514526367188e-06)\n            {\n                _1601 = _1596.xyz / float3(_1598);\n            }\n            else\n            {\n                _1601 = color.xyz;\n            }\n            c = float4(_1601, _1598);\n        }\n    }\n    float4 _2362 = c;\n    _2362.w = _2362.w * _1470;\n    c = _2362;\n    if (_1492 || (shape_rs.y > 0.0))\n    {\n        float _1642 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1651 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1651 + float3(_1642 * 0.0039215688593685626983642578125);\n            float3 _1657 = fa_srgb_to_linear(param_4);\n            float4 _2365 = c;\n            _2365.x = _1657.x;\n            _2365.y = _1657.y;\n            _2365.z = _1657.z;\n            c = _2365;\n        }\n        else\n        {\n            float4 _1667 = c;\n            float3 _1670 = _1667.xyz + float3(_1642 * 0.0039215688593685626983642578125);\n            float4 _2372 = _1667;\n            _2372.x = _1670.x;\n            _2372.y = _1670.y;\n            _2372.z = _1670.z;\n            c = _2372;\n        }\n        float4 _2377 = c;\n        _2377.w = fast::clamp(_2377.w + ((_1642 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2377.w)), 0.0, 1.0);\n        c = _2377;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _695, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1162 = float2(_695.fx_rim_uv.x, 0.0);\n    float4 _1164 = tex.sample(smp, (uv - _1162));\n    float _1165 = _1164.w;\n    float4 _1175 = tex.sample(smp, (uv + _1162));\n    float _1176 = _1175.w;\n    float2 _1184 = float2(0.0, _695.fx_rim_uv.y);\n    float4 _1186 = tex.sample(smp, (uv - _1184));\n    float _1187 = _1186.w;\n    float4 _1197 = tex.sample(smp, (uv + _1184));\n    float _1198 = _1197.w;\n    float _1213 = _1165 - _1176;\n    float _1216 = _1198 - _1187;\n    float _1226 = cos(params.y);\n    float _1228 = sin(params.y);\n    float2 _1254 = ((float2(_1226, _1228) * _1213) + ((float2(-_1228, _1226) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1216)) / float2(fast::max(length(float2(_1213, _1216)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _695.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_695.light_pos[i].w < 0.0)\n        {\n            to_l = _695.light_pos[i].xy / float2(fast::max(length(_695.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1300 = _695.light_pos[i].xy - world_xy;\n            float _1303 = length(_1300);\n            att = powr(fast::clamp(1.0 - (_1303 / fast::max(_695.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _695.light_color[i].w);\n            to_l = _1300 / float2(fast::max(_1303, 9.9999997473787516355514526367188e-05));\n            if (_695.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _695.light_shadow_v[i].x;\n                float param_1 = _695.light_shadow_v[i].y;\n                float2 param_2 = -_1300;\n                float param_3 = _695.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1300;\n            att *= cookie_att(param_4, param_5, _695, fx_cookie_tex, light_smp);\n        }\n        sum += (_695.light_color[i].xyz * (att * fast::max(dot(_1254, to_l), 0.0)));\n    }\n    return (sum * _695.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1165, _1176), fast::min(_1187, _1198))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _695)\n{\n    float2 _701 = gl_FragCoord.xy * _695.fa_target.xy;\n    float _705 = _701.y;\n    return float2(_701.x, mix(_705, 1.0 - _705, _695.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _695, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _743 = base_mode < 0.5;\n    bool _754;\n    if (!_743)\n    {\n        _754 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _754 = _743;\n    }\n    float _755;\n    if (_754)\n    {\n        _755 = shape_half.x;\n    }\n    else\n    {\n        _755 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _695), _695.fa_time.x, base_mode, float4(0.0), _755 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _679 = scene_rgb(param, xform);\n    return _679;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _769)\n{\n    float3 param = _769.tint.xyz;\n    float4 _776 = s.color;\n    float3 _778 = _776.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _778.x;\n    s.color.y = _778.y;\n    s.color.z = _778.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _695 [[buffer(1)]], constant fa_material& _769 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1697 = in.params.x > 31.5;\n    if (_1697)\n    {\n        mode -= 32.0;\n    }\n    float _1705 = mode;\n    bool _1707 = _1705 > 15.5;\n    if (_1707)\n    {\n        mode -= 16.0;\n    }\n    float _1715 = mode;\n    bool _1717 = _1715 > 7.5;\n    if (_1717)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1707)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _695, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1707)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _695, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1779 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1781 = _1779 * in.color;\n                float4 param_6 = _1781;\n                float param_7 = mode;\n                float _1788 = _1781.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _695, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1788);\n                if (_695.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1788;\n                    float param_9 = mode;\n                    float4 _1804 = out.frag_color;\n                    float3 _1806 = _1804.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _695, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1806.x;\n                    out.frag_color.y = _1806.y;\n                    out.frag_color.z = _1806.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1836 = length(in.uv);\n                    float _1839 = fwidth(_1836);\n                    float _1840 = fast::max(_1839, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1836) / _1840) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1836) / _1840) + 0.5, 0.0, 1.0) * fast::clamp(((_1836 - in.params.y) / _1840) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1880 = fast::clamp(1.0 - _1836, 0.0, 1.0);\n                            cov = (_1880 * _1880) * (3.0 - (2.0 * _1880));\n                        }\n                    }\n                    float3 _1889;\n                    if (_1707)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1889 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _695, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1889 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1889, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_695.fx_emit.w > 0.5)\n    {\n        float3 e = _695.fx_emit.xyz;\n        if (_695.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _695.fx_emit_uv.xy) + _695.fx_emit_uv.zw)).xyz;\n            float param_13 = _695.fx_emit.w - 2.0;\n            float3 _1944 = fa_tex_fix(param_12, param_13);\n            e *= _1944;\n        }\n        float4 _1948 = out.frag_color;\n        float3 _1950 = _1948.xyz + e;\n        out.frag_color.x = _1950.x;\n        out.frag_color.y = _1950.y;\n        out.frag_color.z = _1950.z;\n    }\n    float param_14 = mode;\n    float4 _2277 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _695, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2277 };\n    fragment0(param_15, param_16, in.xform, _769);\n    _2277 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1697)\n    {\n        float4 _1976 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1981 = scene_rgb(param_17, in.xform);\n        float3 _1985 = mix(_1976.xyz, _1981, float3(in.color2.w));\n        out.frag_color.x = _1985.x;\n        out.frag_color.y = _1985.y;\n        out.frag_color.z = _1985.z;\n    }\n    if (_1717)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2009 = _695.fog_col.w > 0.0;\n    bool _2017;\n    if (!_2009)\n    {\n        _2017 = _695.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2017 = _2009;\n    }\n    if (_2017)\n    {\n        float3 _2031 = float3(in.world_xy, in.world_z) - _695.fog_eye.xyz;\n        float _2038 = dot(_2031, _695.fog_c.xyz);\n        bool _2042 = _695.fog_c.w > 0.5;\n        float _2043;\n        if (_2042)\n        {\n            _2043 = _2038;\n        }\n        else\n        {\n            _2043 = length(_2031);\n        }\n        float _2055 = _2043 - _695.fog_b.x;\n        if (_2055 > 0.0)\n        {\n            float _2064 = _695.fog_col.w * _2055;\n            float tau = _2064 * _2064;\n            if (_695.fog_b.y > 0.0)\n            {\n                float _2080;\n                if (_2042)\n                {\n                    _2080 = in.world_xy.y - (_695.fog_c.y * _2038);\n                }\n                else\n                {\n                    _2080 = _695.fog_eye.y;\n                }\n                float _2101 = mix(_2080, in.world_xy.y, fast::clamp(_695.fog_b.x / _2043, 0.0, 1.0));\n                float _2105 = in.world_xy.y - _2101;\n                float _2110 = _2101 - _695.fog_b.z;\n                float _2115 = in.world_xy.y - _695.fog_b.z;\n                bool _2118 = _2110 <= 0.0;\n                bool _2119 = !_2118;\n                bool _2125;\n                if (_2119)\n                {\n                    _2125 = _695.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2125 = _2118;\n                }\n                float _2126;\n                if (_2125)\n                {\n                    _2126 = _695.fog_b.y;\n                }\n                else\n                {\n                    _2126 = _695.fog_b.y * exp(-fast::min(_695.fog_b.w * _2110, 80.0));\n                }\n                bool _2153;\n                if (_2119)\n                {\n                    _2153 = _695.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2153 = _2118;\n                }\n                float _2154;\n                if (_2153)\n                {\n                    _2154 = _695.fog_b.y * _2110;\n                }\n                else\n                {\n                    _2154 = (_695.fog_b.y * (1.0 - exp(-fast::min(_695.fog_b.w * _2110, 80.0)))) / _695.fog_b.w;\n                }\n                bool _2179 = _2115 <= 0.0;\n                bool _2186;\n                if (!_2179)\n                {\n                    _2186 = _695.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2186 = _2179;\n                }\n                float _2187;\n                if (_2186)\n                {\n                    _2187 = _695.fog_b.y * _2115;\n                }\n                else\n                {\n                    _2187 = (_695.fog_b.y * (1.0 - exp(-fast::min(_695.fog_b.w * _2115, 80.0)))) / _695.fog_b.w;\n                }\n                float _2214;\n                if (abs(_2105) < 0.001000000047497451305389404296875)\n                {\n                    _2214 = _2126;\n                }\n                else\n                {\n                    _2214 = (_2187 - _2154) / _2105;\n                }\n                tau += (_2055 * fast::max(_2214, 0.0));\n            }\n            float4 _2237 = out.frag_color;\n            float3 _2245 = mix(_2237.xyz, _695.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2245.x;\n            out.frag_color.y = _2245.y;\n            out.frag_color.z = _2245.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_695",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_769",
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
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fx_gi_tex",
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
            "name": "fx_gi_tex_light_smp",
            "view_name": "fx_gi_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1
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
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 6,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _155)\n{\n    float2 _162 = gl_FragCoord.xy * _155.fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, mix(_167, 1.0 - _167, _155.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _155, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _155), _155.fa_time.x, base_mode, float4(0.0), _223 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param, xform);\n    return _138;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _237)\n{\n    float3 param = _237.tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _155 [[buffer(1)]], constant fa_material& _237 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _265 = tex.sample(smp, in.uv);\n    float3 param = _265.xyz;\n    float param_1 = in.xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_274, _265.w) * in.color;\n    float param_2 = 0.0;\n    float4 _328 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _155, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _328 };\n    fragment0(param_3, param_4, in.xform, _237);\n    _328 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_155",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_237",
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
