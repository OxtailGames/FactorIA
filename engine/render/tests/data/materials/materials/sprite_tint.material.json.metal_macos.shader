{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _647 = tex.sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _696, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _833 = (world_xy * _696.gi_xf.xy) + _696.gi_xf.zw;\n    float4 _840 = fx_gi_tex.sample(light_smp, _833, level(0.0));\n    float _844 = _833.x;\n    bool _845 = _844 >= 0.0;\n    bool _851;\n    if (_845)\n    {\n        _851 = _833.y >= 0.0;\n    }\n    else\n    {\n        _851 = _845;\n    }\n    bool _857;\n    if (_851)\n    {\n        _857 = _844 <= 1.0;\n    }\n    else\n    {\n        _857 = _851;\n    }\n    bool _863;\n    if (_857)\n    {\n        _863 = _833.y <= 1.0;\n    }\n    else\n    {\n        _863 = _857;\n    }\n    bool _871;\n    if (_863)\n    {\n        _871 = _840.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    float3 _872;\n    if (_871)\n    {\n        _872 = (_840.xyz / float3(_840.w)) * _696.gi_p.x;\n    }\n    else\n    {\n        _872 = float3(0.0);\n    }\n    return _872;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _137 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = precise::atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = fast::min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = precise::atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = fast::min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    float2 c = float2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = fast::clamp(_532, float2(0.001953125), float2(0.998046875));\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _696, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_696.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _696.light_cookie[i];\n    float4 param_1 = _696.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _807 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _807.xy, level(0.0));\n    return cookie_value(param_3) * _807.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _696, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _894 = _696.lit.y > 0.5;\n    if (_894)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _696.normal_uv.xy) + _696.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _918 = fa_tex_fix(param, param_1);\n        float3 _922 = (_918 * 2.0) - float3(1.0);\n        float _929 = cos(params.y);\n        float _931 = sin(params.y);\n        n = fast::normalize(float3((float2(_929, _931) * _922.x) + ((float2(-_931, _929) * ((mode > 5.5) ? (-1.0) : 1.0)) * _922.y), fast::max(_922.z, 0.0500000007450580596923828125)));\n    }\n    bool _965 = !_894;\n    bool _971;\n    if (_965)\n    {\n        _971 = _696.lit.z > 0.5;\n    }\n    else\n    {\n        _971 = _965;\n    }\n    float3 _974;\n    if (_971)\n    {\n        _974 = _696.flat_ambient.xyz;\n    }\n    else\n    {\n        _974 = _696.ambient.xyz;\n    }\n    float3 total = _974;\n    if (_696.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_696, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _999;\n    if (_971)\n    {\n        _999 = _696.lit.z < 1.5;\n    }\n    else\n    {\n        _999 = _971;\n    }\n    if (_999)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _696.light_map.xy), level(0.0)).xyz * _696.light_map.z);\n    }\n    float3 l;\n    float _1126;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1036;\n        if (!_971)\n        {\n            _1036 = float(i) >= _696.lit.x;\n        }\n        else\n        {\n            _1036 = _971;\n        }\n        if (_1036)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_696.light_pos[i].w < 0.0)\n        {\n            l = _696.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1062 = _696.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1062) / fast::max(_696.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _696.light_color[i].w);\n            float3 _1082 = float3(_1062, _696.light_pos[i].z);\n            l = _1082 / float3(fast::max(length(_1082), 9.9999997473787516355514526367188e-05));\n            if (_696.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _696.light_shadow_v[i].x;\n                float param_3 = _696.light_shadow_v[i].y;\n                float2 param_4 = -_1062;\n                float param_5 = _696.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1062;\n            att *= cookie_att(param_6, param_7, _696, fx_cookie_tex, light_smp);\n        }\n        if (_894)\n        {\n            _1126 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1126 = 1.0;\n        }\n        total += (_696.light_color[i].xyz * (att * _1126));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1376 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1380 = uv * _1376;\n    float _1386 = _1376.x;\n    float _1388 = _1376.y;\n    float _1390 = fast::clamp(shape_rs.x, 0.0, fast::min(_1386, _1388));\n    float2 _1401 = (abs(_1380) - _1376) + float2(_1390);\n    float d = (length(fast::max(_1401, float2(0.0))) + fast::min(fast::max(_1401.x, _1401.y), 0.0)) - _1390;\n    float ax = params.y;\n    bool _1422 = params.y > 15.0;\n    if (_1422)\n    {\n        ax -= 20.0;\n    }\n    float _1433;\n    if (ax <= (-1.5))\n    {\n        _1433 = (-2.0) - ax;\n    }\n    else\n    {\n        _1433 = 0.0;\n    }\n    if (_1433 > 0.0)\n    {\n        float _1447 = _1433 * 0.5;\n        d = abs(d + _1447) - _1447;\n    }\n    float _1455 = fwidth(d);\n    float _1456 = fast::max(_1455, 9.9999997473787516355514526367188e-05);\n    float _1466 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1456)), 0.0, 1.0);\n    float _1471;\n    if (shape_rs.y > _1456)\n    {\n        _1471 = (_1466 * _1466) * (3.0 - (2.0 * _1466));\n    }\n    else\n    {\n        _1471 = _1466;\n    }\n    float4 c = color;\n    bool _1493 = (_1433 <= 0.0) && (ax > (-0.5));\n    if (_1493)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1508 = cos(ax);\n            float _1510 = sin(ax);\n            g = ((dot(_1380, float2(_1508, _1510)) / fast::max((abs(_1508) * _1386) + (abs(_1510) * _1388), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1422)\n        {\n            float4 _1553 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1553;\n            float3 param = _1553.xyz;\n            float param_1 = xform.y;\n            float3 _1560 = fa_tex_fix(param, param_1);\n            float4 _2355 = c;\n            _2355.x = _1560.x;\n            _2355.y = _1560.y;\n            _2355.z = _1560.z;\n            c = _2355;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1572 = scene_rgb(param_2, xform);\n            float4 _1597 = mix(float4(color.xyz * color.w, color.w), float4(_1572 * color2.w, color2.w), float4(g));\n            float _1599 = _1597.w;\n            float3 _1602;\n            if (_1599 > 9.9999997473787516355514526367188e-06)\n            {\n                _1602 = _1597.xyz / float3(_1599);\n            }\n            else\n            {\n                _1602 = color.xyz;\n            }\n            c = float4(_1602, _1599);\n        }\n    }\n    float4 _2364 = c;\n    _2364.w = _2364.w * _1471;\n    c = _2364;\n    if (_1493 || (shape_rs.y > 0.0))\n    {\n        float _1643 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1652 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1652 + float3(_1643 * 0.0039215688593685626983642578125);\n            float3 _1658 = fa_srgb_to_linear(param_4);\n            float4 _2367 = c;\n            _2367.x = _1658.x;\n            _2367.y = _1658.y;\n            _2367.z = _1658.z;\n            c = _2367;\n        }\n        else\n        {\n            float4 _1668 = c;\n            float3 _1671 = _1668.xyz + float3(_1643 * 0.0039215688593685626983642578125);\n            float4 _2374 = _1668;\n            _2374.x = _1671.x;\n            _2374.y = _1671.y;\n            _2374.z = _1671.z;\n            c = _2374;\n        }\n        float4 _2379 = c;\n        _2379.w = fast::clamp(_2379.w + ((_1643 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2379.w)), 0.0, 1.0);\n        c = _2379;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _696, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1163 = float2(_696.fx_rim_uv.x, 0.0);\n    float4 _1165 = tex.sample(smp, (uv - _1163));\n    float _1166 = _1165.w;\n    float4 _1176 = tex.sample(smp, (uv + _1163));\n    float _1177 = _1176.w;\n    float2 _1185 = float2(0.0, _696.fx_rim_uv.y);\n    float4 _1187 = tex.sample(smp, (uv - _1185));\n    float _1188 = _1187.w;\n    float4 _1198 = tex.sample(smp, (uv + _1185));\n    float _1199 = _1198.w;\n    float _1214 = _1166 - _1177;\n    float _1217 = _1199 - _1188;\n    float _1227 = cos(params.y);\n    float _1229 = sin(params.y);\n    float2 _1255 = ((float2(_1227, _1229) * _1214) + ((float2(-_1229, _1227) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1217)) / float2(fast::max(length(float2(_1214, _1217)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _696.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_696.light_pos[i].w < 0.0)\n        {\n            to_l = _696.light_pos[i].xy / float2(fast::max(length(_696.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1301 = _696.light_pos[i].xy - world_xy;\n            float _1304 = length(_1301);\n            att = powr(fast::clamp(1.0 - (_1304 / fast::max(_696.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _696.light_color[i].w);\n            to_l = _1301 / float2(fast::max(_1304, 9.9999997473787516355514526367188e-05));\n            if (_696.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _696.light_shadow_v[i].x;\n                float param_1 = _696.light_shadow_v[i].y;\n                float2 param_2 = -_1301;\n                float param_3 = _696.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1301;\n            att *= cookie_att(param_4, param_5, _696, fx_cookie_tex, light_smp);\n        }\n        sum += (_696.light_color[i].xyz * (att * fast::max(dot(_1255, to_l), 0.0)));\n    }\n    return (sum * _696.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1166, _1177), fast::min(_1188, _1199))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _696)\n{\n    float2 _702 = gl_FragCoord.xy * _696.fa_target.xy;\n    float _706 = _702.y;\n    return float2(_702.x, mix(_706, 1.0 - _706, _696.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _696, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _744 = base_mode < 0.5;\n    bool _755;\n    if (!_744)\n    {\n        _755 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _755 = _744;\n    }\n    float _756;\n    if (_755)\n    {\n        _756 = shape_half.x;\n    }\n    else\n    {\n        _756 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _696), _696.fa_time.x, base_mode, float4(0.0), _756 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _679 = scene_rgb(param, xform);\n    return _679;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _770)\n{\n    float3 param = _770.tint.xyz;\n    float4 _777 = s.color;\n    float3 _779 = _777.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _779.x;\n    s.color.y = _779.y;\n    s.color.z = _779.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _696 [[buffer(1)]], constant fa_material& _770 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1698 = in.params.x > 31.5;\n    if (_1698)\n    {\n        mode -= 32.0;\n    }\n    float _1706 = mode;\n    bool _1708 = _1706 > 15.5;\n    if (_1708)\n    {\n        mode -= 16.0;\n    }\n    float _1716 = mode;\n    bool _1718 = _1716 > 7.5;\n    if (_1718)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1708)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _696, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1708)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _696, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1780 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1782 = _1780 * in.color;\n                float4 param_6 = _1782;\n                float param_7 = mode;\n                float _1789 = _1782.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _696, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1789);\n                if (_696.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1789;\n                    float param_9 = mode;\n                    float4 _1805 = out.frag_color;\n                    float3 _1807 = _1805.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _696, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1807.x;\n                    out.frag_color.y = _1807.y;\n                    out.frag_color.z = _1807.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1837 = length(in.uv);\n                    float _1840 = fwidth(_1837);\n                    float _1841 = fast::max(_1840, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1837) / _1841) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1837) / _1841) + 0.5, 0.0, 1.0) * fast::clamp(((_1837 - in.params.y) / _1841) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1881 = fast::clamp(1.0 - _1837, 0.0, 1.0);\n                            cov = (_1881 * _1881) * (3.0 - (2.0 * _1881));\n                        }\n                    }\n                    float3 _1890;\n                    if (_1708)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1890 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _696, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1890 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1890, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_696.fx_emit.w > 0.5)\n    {\n        float3 e = _696.fx_emit.xyz;\n        if (_696.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _696.fx_emit_uv.xy) + _696.fx_emit_uv.zw)).xyz;\n            float param_13 = _696.fx_emit.w - 2.0;\n            float3 _1945 = fa_tex_fix(param_12, param_13);\n            e *= _1945;\n        }\n        float4 _1949 = out.frag_color;\n        float3 _1951 = _1949.xyz + e;\n        out.frag_color.x = _1951.x;\n        out.frag_color.y = _1951.y;\n        out.frag_color.z = _1951.z;\n    }\n    float param_14 = mode;\n    float4 _2279 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _696, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2279 };\n    fragment0(param_15, param_16, in.xform, _770);\n    _2279 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1698)\n    {\n        float4 _1977 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1982 = scene_rgb(param_17, in.xform);\n        float3 _1986 = mix(_1977.xyz, _1982, float3(in.color2.w));\n        out.frag_color.x = _1986.x;\n        out.frag_color.y = _1986.y;\n        out.frag_color.z = _1986.z;\n    }\n    if (_1718)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2010 = _696.fog_col.w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = _696.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        float3 _2032 = float3(in.world_xy, in.world_z) - _696.fog_eye.xyz;\n        float _2039 = dot(_2032, _696.fog_c.xyz);\n        bool _2043 = _696.fog_c.w > 0.5;\n        float _2044;\n        if (_2043)\n        {\n            _2044 = _2039;\n        }\n        else\n        {\n            _2044 = length(_2032);\n        }\n        float _2056 = _2044 - _696.fog_b.x;\n        if (_2056 > 0.0)\n        {\n            float _2065 = _696.fog_col.w * _2056;\n            float tau = _2065 * _2065;\n            if (_696.fog_b.y > 0.0)\n            {\n                float _2081;\n                if (_2043)\n                {\n                    _2081 = in.world_xy.y - (_696.fog_c.y * _2039);\n                }\n                else\n                {\n                    _2081 = _696.fog_eye.y;\n                }\n                float _2102 = mix(_2081, in.world_xy.y, fast::clamp(_696.fog_b.x / _2044, 0.0, 1.0));\n                float _2106 = in.world_xy.y - _2102;\n                float _2111 = _2102 - _696.fog_b.z;\n                float _2116 = in.world_xy.y - _696.fog_b.z;\n                bool _2119 = _2111 <= 0.0;\n                bool _2120 = !_2119;\n                bool _2126;\n                if (_2120)\n                {\n                    _2126 = _696.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2126 = _2119;\n                }\n                float _2127;\n                if (_2126)\n                {\n                    _2127 = _696.fog_b.y;\n                }\n                else\n                {\n                    _2127 = _696.fog_b.y * exp(-fast::min(_696.fog_b.w * _2111, 80.0));\n                }\n                bool _2154;\n                if (_2120)\n                {\n                    _2154 = _696.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2154 = _2119;\n                }\n                float _2155;\n                if (_2154)\n                {\n                    _2155 = _696.fog_b.y * _2111;\n                }\n                else\n                {\n                    _2155 = (_696.fog_b.y * (1.0 - exp(-fast::min(_696.fog_b.w * _2111, 80.0)))) / _696.fog_b.w;\n                }\n                bool _2180 = _2116 <= 0.0;\n                bool _2187;\n                if (!_2180)\n                {\n                    _2187 = _696.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2187 = _2180;\n                }\n                float _2188;\n                if (_2187)\n                {\n                    _2188 = _696.fog_b.y * _2116;\n                }\n                else\n                {\n                    _2188 = (_696.fog_b.y * (1.0 - exp(-fast::min(_696.fog_b.w * _2116, 80.0)))) / _696.fog_b.w;\n                }\n                float _2215;\n                if (abs(_2106) < 0.001000000047497451305389404296875)\n                {\n                    _2215 = _2127;\n                }\n                else\n                {\n                    _2215 = (_2188 - _2155) / _2106;\n                }\n                tau += (_2056 * fast::max(_2215, 0.0));\n            }\n            float4 _2238 = out.frag_color;\n            float3 _2246 = mix(_2238.xyz, _696.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2246.x;\n            out.frag_color.y = _2246.y;\n            out.frag_color.z = _2246.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_696",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_770",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _157)\n{\n    float2 _164 = gl_FragCoord.xy * _157.fa_target.xy;\n    float _169 = _164.y;\n    return float2(_164.x, mix(_169, 1.0 - _169, _157.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _157, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _213 = base_mode < 0.5;\n    bool _224;\n    if (!_213)\n    {\n        _224 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _224 = _213;\n    }\n    float _225;\n    if (_224)\n    {\n        _225 = shape_half.x;\n    }\n    else\n    {\n        _225 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _157), _157.fa_time.x, base_mode, float4(0.0), _225 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param, xform);\n    return _138;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _239)\n{\n    float3 param = _239.tint.xyz;\n    float4 _246 = s.color;\n    float3 _248 = _246.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _248.x;\n    s.color.y = _248.y;\n    s.color.z = _248.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _157 [[buffer(1)]], constant fa_material& _239 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _267 = tex.sample(smp, in.uv);\n    float3 param = _267.xyz;\n    float param_1 = in.xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_276, _267.w) * in.color;\n    float param_2 = 0.0;\n    float4 _331 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _157, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _331 };\n    fragment0(param_3, param_4, in.xform, _239);\n    _331 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_157",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_239",
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
