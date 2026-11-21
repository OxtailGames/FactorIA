{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "be09d710d10cdccec43655f10e6af3b043d5ce26db7fbf1ce164733ea9edbe00",
  "slang": "metal_macos",
  "params": [
    "amount",
    "dx",
    "dy"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float amount;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float dx;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float dy;\n    float fa_pad6;\n    float fa_pad7;\n    float fa_pad8;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _647 = tex.sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _686, sampler light_smp, thread float2& world_xy, texture2d<float> fx_gi_tex)\n{\n    float2 _878 = (world_xy * _686.gi_xf.xy) + _686.gi_xf.zw;\n    float4 _885 = fx_gi_tex.sample(light_smp, _878, level(0.0));\n    float _889 = _878.x;\n    bool _890 = _889 >= 0.0;\n    bool _896;\n    if (_890)\n    {\n        _896 = _878.y >= 0.0;\n    }\n    else\n    {\n        _896 = _890;\n    }\n    bool _902;\n    if (_896)\n    {\n        _902 = _889 <= 1.0;\n    }\n    else\n    {\n        _902 = _896;\n    }\n    bool _908;\n    if (_902)\n    {\n        _908 = _878.y <= 1.0;\n    }\n    else\n    {\n        _908 = _902;\n    }\n    bool _916;\n    if (_908)\n    {\n        _916 = _885.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _916 = _908;\n    }\n    float3 _917;\n    if (_916)\n    {\n        _917 = (_885.xyz / float3(_885.w)) * _686.gi_p.x;\n    }\n    else\n    {\n        _917 = float3(0.0);\n    }\n    return _917;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _137 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = precise::atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = fast::min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = precise::atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = fast::min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    float2 c = float2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = fast::clamp(_532, float2(0.001953125), float2(0.998046875));\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _686, sampler light_smp, texture2d<float> fx_cookie_tex)\n{\n    if (_686.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _686.light_cookie[i];\n    float4 param_1 = _686.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _853 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _853.xy, level(0.0));\n    return cookie_value(param_3) * _853.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, constant quad_fs_params& _686, sampler light_smp, thread float4& gl_FragCoord, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _939 = _686.lit.y > 0.5;\n    if (_939)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _686.normal_uv.xy) + _686.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _963 = fa_tex_fix(param, param_1);\n        float3 _967 = (_963 * 2.0) - float3(1.0);\n        float _974 = cos(params.y);\n        float _976 = sin(params.y);\n        n = fast::normalize(float3((float2(_974, _976) * _967.x) + ((float2(-_976, _974) * ((mode > 5.5) ? (-1.0) : 1.0)) * _967.y), fast::max(_967.z, 0.0500000007450580596923828125)));\n    }\n    bool _1010 = !_939;\n    bool _1016;\n    if (_1010)\n    {\n        _1016 = _686.lit.z > 0.5;\n    }\n    else\n    {\n        _1016 = _1010;\n    }\n    float3 _1019;\n    if (_1016)\n    {\n        _1019 = _686.flat_ambient.xyz;\n    }\n    else\n    {\n        _1019 = _686.ambient.xyz;\n    }\n    float3 total = _1019;\n    if (_686.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_686, light_smp, world_xy, fx_gi_tex);\n    }\n    bool _1044;\n    if (_1016)\n    {\n        _1044 = _686.lit.z < 1.5;\n    }\n    else\n    {\n        _1044 = _1016;\n    }\n    if (_1044)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _686.light_map.xy), level(0.0)).xyz * _686.light_map.z);\n    }\n    float3 l;\n    float _1171;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1081;\n        if (!_1016)\n        {\n            _1081 = float(i) >= _686.lit.x;\n        }\n        else\n        {\n            _1081 = _1016;\n        }\n        if (_1081)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_686.light_pos[i].w < 0.0)\n        {\n            l = _686.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1107 = _686.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1107) / fast::max(_686.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _686.light_color[i].w);\n            float3 _1127 = float3(_1107, _686.light_pos[i].z);\n            l = _1127 / float3(fast::max(length(_1127), 9.9999997473787516355514526367188e-05));\n            if (_686.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _686.light_shadow_v[i].x;\n                float param_3 = _686.light_shadow_v[i].y;\n                float2 param_4 = -_1107;\n                float param_5 = _686.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1107;\n            att *= cookie_att(param_6, param_7, _686, light_smp, fx_cookie_tex);\n        }\n        if (_939)\n        {\n            _1171 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1171 = 1.0;\n        }\n        total += (_686.light_color[i].xyz * (att * _1171));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1421 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1425 = uv * _1421;\n    float _1431 = _1421.x;\n    float _1433 = _1421.y;\n    float _1435 = fast::clamp(shape_rs.x, 0.0, fast::min(_1431, _1433));\n    float2 _1446 = (abs(_1425) - _1421) + float2(_1435);\n    float d = (length(fast::max(_1446, float2(0.0))) + fast::min(fast::max(_1446.x, _1446.y), 0.0)) - _1435;\n    float ax = params.y;\n    bool _1467 = params.y > 15.0;\n    if (_1467)\n    {\n        ax -= 20.0;\n    }\n    float _1478;\n    if (ax <= (-1.5))\n    {\n        _1478 = (-2.0) - ax;\n    }\n    else\n    {\n        _1478 = 0.0;\n    }\n    if (_1478 > 0.0)\n    {\n        float _1492 = _1478 * 0.5;\n        d = abs(d + _1492) - _1492;\n    }\n    float _1500 = fwidth(d);\n    float _1501 = fast::max(_1500, 9.9999997473787516355514526367188e-05);\n    float _1511 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1501)), 0.0, 1.0);\n    float _1516;\n    if (shape_rs.y > _1501)\n    {\n        _1516 = (_1511 * _1511) * (3.0 - (2.0 * _1511));\n    }\n    else\n    {\n        _1516 = _1511;\n    }\n    float4 c = color;\n    bool _1538 = (_1478 <= 0.0) && (ax > (-0.5));\n    if (_1538)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1553 = cos(ax);\n            float _1555 = sin(ax);\n            g = ((dot(_1425, float2(_1553, _1555)) / fast::max((abs(_1553) * _1431) + (abs(_1555) * _1433), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1467)\n        {\n            float4 _1598 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1598;\n            float3 param = _1598.xyz;\n            float param_1 = xform.y;\n            float3 _1605 = fa_tex_fix(param, param_1);\n            float4 _2402 = c;\n            _2402.x = _1605.x;\n            _2402.y = _1605.y;\n            _2402.z = _1605.z;\n            c = _2402;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1617 = scene_rgb(param_2, xform);\n            float4 _1642 = mix(float4(color.xyz * color.w, color.w), float4(_1617 * color2.w, color2.w), float4(g));\n            float _1644 = _1642.w;\n            float3 _1647;\n            if (_1644 > 9.9999997473787516355514526367188e-06)\n            {\n                _1647 = _1642.xyz / float3(_1644);\n            }\n            else\n            {\n                _1647 = color.xyz;\n            }\n            c = float4(_1647, _1644);\n        }\n    }\n    float4 _2411 = c;\n    _2411.w = _2411.w * _1516;\n    c = _2411;\n    if (_1538 || (shape_rs.y > 0.0))\n    {\n        float _1688 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1697 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1697 + float3(_1688 * 0.0039215688593685626983642578125);\n            float3 _1703 = fa_srgb_to_linear(param_4);\n            float4 _2414 = c;\n            _2414.x = _1703.x;\n            _2414.y = _1703.y;\n            _2414.z = _1703.z;\n            c = _2414;\n        }\n        else\n        {\n            float4 _1713 = c;\n            float3 _1716 = _1713.xyz + float3(_1688 * 0.0039215688593685626983642578125);\n            float4 _2421 = _1713;\n            _2421.x = _1716.x;\n            _2421.y = _1716.y;\n            _2421.z = _1716.z;\n            c = _2421;\n        }\n        float4 _2426 = c;\n        _2426.w = fast::clamp(_2426.w + ((_1688 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2426.w)), 0.0, 1.0);\n        c = _2426;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _686, sampler light_smp, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, thread float2& params)\n{\n    float2 _1208 = float2(_686.fx_rim_uv.x, 0.0);\n    float4 _1210 = tex.sample(smp, (uv - _1208));\n    float _1211 = _1210.w;\n    float4 _1221 = tex.sample(smp, (uv + _1208));\n    float _1222 = _1221.w;\n    float2 _1230 = float2(0.0, _686.fx_rim_uv.y);\n    float4 _1232 = tex.sample(smp, (uv - _1230));\n    float _1233 = _1232.w;\n    float4 _1243 = tex.sample(smp, (uv + _1230));\n    float _1244 = _1243.w;\n    float _1259 = _1211 - _1222;\n    float _1262 = _1244 - _1233;\n    float _1272 = cos(params.y);\n    float _1274 = sin(params.y);\n    float2 _1300 = ((float2(_1272, _1274) * _1259) + ((float2(-_1274, _1272) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1262)) / float2(fast::max(length(float2(_1259, _1262)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _686.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_686.light_pos[i].w < 0.0)\n        {\n            to_l = _686.light_pos[i].xy / float2(fast::max(length(_686.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1346 = _686.light_pos[i].xy - world_xy;\n            float _1349 = length(_1346);\n            att = powr(fast::clamp(1.0 - (_1349 / fast::max(_686.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _686.light_color[i].w);\n            to_l = _1346 / float2(fast::max(_1349, 9.9999997473787516355514526367188e-05));\n            if (_686.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _686.light_shadow_v[i].x;\n                float param_1 = _686.light_shadow_v[i].y;\n                float2 param_2 = -_1346;\n                float param_3 = _686.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1346;\n            att *= cookie_att(param_4, param_5, _686, light_smp, fx_cookie_tex);\n        }\n        sum += (_686.light_color[i].xyz * (att * fast::max(dot(_1300, to_l), 0.0)));\n    }\n    return (sum * _686.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1211, _1222), fast::min(_1233, _1244))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _686, thread float4& gl_FragCoord)\n{\n    float2 _737 = gl_FragCoord.xy * _686.fa_target.xy;\n    float _741 = _737.y;\n    return float2(_737.x, mix(_741, 1.0 - _741, _686.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _686, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _777 = base_mode < 0.5;\n    bool _788;\n    if (!_777)\n    {\n        _788 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _788 = _777;\n    }\n    float _789;\n    if (_788)\n    {\n        _789 = shape_half.x;\n    }\n    else\n    {\n        _789 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_686, gl_FragCoord), _686.fa_time.x, base_mode, float4(0.0), _789 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _686, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_686.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _706 = (uv * _686.fa_scene.xy) + _686.fa_scene.zw;\n    float _708 = _706.y;\n    _706.y = mix(_708, 1.0 - _708, _686.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_706, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _686, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _806)\n{\n    float2 param = i.screen_uv + float2(_806.dx, _806.dy);\n    s.color = float4(mix(s.color.xyz, fa_scene_color(param, _686, fa_scene_tex, light_smp).xyz, float3(_806.amount)), s.color.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _686 [[buffer(1)]], constant fa_material& _806 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], texture2d<float> fa_scene_tex [[texture(7)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1743 = in.params.x > 31.5;\n    if (_1743)\n    {\n        mode -= 32.0;\n    }\n    float _1751 = mode;\n    bool _1753 = _1751 > 15.5;\n    if (_1753)\n    {\n        mode -= 16.0;\n    }\n    float _1761 = mode;\n    bool _1763 = _1761 > 7.5;\n    if (_1763)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1753)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1753)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1825 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1827 = _1825 * in.color;\n                float4 param_6 = _1827;\n                float param_7 = mode;\n                float _1834 = _1827.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex), _1834);\n                if (_686.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1834;\n                    float param_9 = mode;\n                    float4 _1850 = out.frag_color;\n                    float3 _1852 = _1850.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _686, light_smp, in.uv, in.world_xy, fx_cookie_tex, in.params);\n                    out.frag_color.x = _1852.x;\n                    out.frag_color.y = _1852.y;\n                    out.frag_color.z = _1852.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1882 = length(in.uv);\n                    float _1885 = fwidth(_1882);\n                    float _1886 = fast::max(_1885, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1882) / _1886) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1882) / _1886) + 0.5, 0.0, 1.0) * fast::clamp(((_1882 - in.params.y) / _1886) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1926 = fast::clamp(1.0 - _1882, 0.0, 1.0);\n                            cov = (_1926 * _1926) * (3.0 - (2.0 * _1926));\n                        }\n                    }\n                    float3 _1935;\n                    if (_1753)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1935 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1935 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1935, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_686.fx_emit.w > 0.5)\n    {\n        float3 e = _686.fx_emit.xyz;\n        if (_686.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _686.fx_emit_uv.xy) + _686.fx_emit_uv.zw)).xyz;\n            float param_13 = _686.fx_emit.w - 2.0;\n            float3 _1990 = fa_tex_fix(param_12, param_13);\n            e *= _1990;\n        }\n        float4 _1994 = out.frag_color;\n        float3 _1996 = _1994.xyz + e;\n        out.frag_color.x = _1996.x;\n        out.frag_color.y = _1996.y;\n        out.frag_color.z = _1996.z;\n    }\n    float param_14 = mode;\n    float4 _2322 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, _686, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2322 };\n    fragment0(param_15, param_16, _686, fa_scene_tex, light_smp, _806);\n    _2322 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1743)\n    {\n        float4 _2022 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _2027 = scene_rgb(param_17, in.xform);\n        float3 _2031 = mix(_2022.xyz, _2027, float3(in.color2.w));\n        out.frag_color.x = _2031.x;\n        out.frag_color.y = _2031.y;\n        out.frag_color.z = _2031.z;\n    }\n    if (_1763)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2054 = _686.fog_col.w > 0.0;\n    bool _2062;\n    if (!_2054)\n    {\n        _2062 = _686.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2062 = _2054;\n    }\n    if (_2062)\n    {\n        float3 _2076 = float3(in.world_xy, in.world_z) - _686.fog_eye.xyz;\n        float _2083 = dot(_2076, _686.fog_c.xyz);\n        bool _2087 = _686.fog_c.w > 0.5;\n        float _2088;\n        if (_2087)\n        {\n            _2088 = _2083;\n        }\n        else\n        {\n            _2088 = length(_2076);\n        }\n        float _2100 = _2088 - _686.fog_b.x;\n        if (_2100 > 0.0)\n        {\n            float _2109 = _686.fog_col.w * _2100;\n            float tau = _2109 * _2109;\n            if (_686.fog_b.y > 0.0)\n            {\n                float _2125;\n                if (_2087)\n                {\n                    _2125 = in.world_xy.y - (_686.fog_c.y * _2083);\n                }\n                else\n                {\n                    _2125 = _686.fog_eye.y;\n                }\n                float _2146 = mix(_2125, in.world_xy.y, fast::clamp(_686.fog_b.x / _2088, 0.0, 1.0));\n                float _2150 = in.world_xy.y - _2146;\n                float _2155 = _2146 - _686.fog_b.z;\n                float _2160 = in.world_xy.y - _686.fog_b.z;\n                bool _2163 = _2155 <= 0.0;\n                bool _2164 = !_2163;\n                bool _2170;\n                if (_2164)\n                {\n                    _2170 = _686.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2170 = _2163;\n                }\n                float _2171;\n                if (_2170)\n                {\n                    _2171 = _686.fog_b.y;\n                }\n                else\n                {\n                    _2171 = _686.fog_b.y * exp(-fast::min(_686.fog_b.w * _2155, 80.0));\n                }\n                bool _2198;\n                if (_2164)\n                {\n                    _2198 = _686.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2198 = _2163;\n                }\n                float _2199;\n                if (_2198)\n                {\n                    _2199 = _686.fog_b.y * _2155;\n                }\n                else\n                {\n                    _2199 = (_686.fog_b.y * (1.0 - exp(-fast::min(_686.fog_b.w * _2155, 80.0)))) / _686.fog_b.w;\n                }\n                bool _2224 = _2160 <= 0.0;\n                bool _2231;\n                if (!_2224)\n                {\n                    _2231 = _686.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2231 = _2224;\n                }\n                float _2232;\n                if (_2231)\n                {\n                    _2232 = _686.fog_b.y * _2160;\n                }\n                else\n                {\n                    _2232 = (_686.fog_b.y * (1.0 - exp(-fast::min(_686.fog_b.w * _2160, 80.0)))) / _686.fog_b.w;\n                }\n                float _2259;\n                if (abs(_2150) < 0.001000000047497451305389404296875)\n                {\n                    _2259 = _2171;\n                }\n                else\n                {\n                    _2259 = (_2232 - _2199) / _2150;\n                }\n                tau += (_2100 * fast::max(_2259, 0.0));\n            }\n            float4 _2282 = out.frag_color;\n            float3 _2290 = mix(_2282.xyz, _686.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2290.x;\n            out.frag_color.y = _2290.y;\n            out.frag_color.z = _2290.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_686",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_806",
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
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 7
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
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 15,
            "sampler_slot": 1
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float amount;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float dx;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float dy;\n    float fa_pad6;\n    float fa_pad7;\n    float fa_pad8;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _130, thread float4& gl_FragCoord)\n{\n    float2 _191 = gl_FragCoord.xy * _130.fa_target.xy;\n    float _195 = _191.y;\n    return float2(_191.x, mix(_195, 1.0 - _195, _130.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _130, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _235 = base_mode < 0.5;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_130, gl_FragCoord), _130.fa_time.x, base_mode, float4(0.0), _247 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _130, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_130.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _152 = (uv * _130.fa_scene.xy) + _130.fa_scene.zw;\n    float _155 = _152.y;\n    _152.y = mix(_155, 1.0 - _155, _130.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_152, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _130, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _265)\n{\n    float2 param = i.screen_uv + float2(_265.dx, _265.dy);\n    s.color = float4(mix(s.color.xyz, fa_scene_color(param, _130, fa_scene_tex, light_smp).xyz, float3(_265.amount)), s.color.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _130 [[buffer(1)]], constant fa_material& _265 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> fa_scene_tex [[texture(1)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _298 = tex.sample(smp, in.uv);\n    float3 param = _298.xyz;\n    float param_1 = in.xform.y;\n    float3 _309 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_309, _298.w) * in.color;\n    float param_2 = 0.0;\n    float4 _362 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, _130, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _362 };\n    fragment0(param_3, param_4, _130, fa_scene_tex, light_smp, _265);\n    _362 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_130",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_265",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 1
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
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 15,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
