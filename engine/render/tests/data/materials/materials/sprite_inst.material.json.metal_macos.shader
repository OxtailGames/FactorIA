{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _631 = fa_linear_to_srgb(param);\n        c = _631;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _639 = fa_srgb_to_linear(param_1);\n            c = _639;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _650 = tex.sample(smp, p);\n    float3 param = _650.xyz;\n    float param_1 = xform.y;\n    float3 _660 = fa_tex_fix(param, param_1);\n    return float4(_660, _650.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _140 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_140.x * 255.0) + 0.5) * 256.0) + floor((_140.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _243 = floor(tt);\n    float _253 = _243 - (1024.0 * floor(_243 * 0.0009765625));\n    float _256 = _253 + 1.0;\n    float i1 = _256;\n    if (_256 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _253;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _243);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _293 = length(d);\n    float result = 1.0;\n    if (_293 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _304 = precise::atan2(d.y, d.x);\n        float a = _304;\n        float _307;\n        if (_304 < 0.0)\n        {\n            _307 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _307 = a;\n        }\n        a = _307;\n        float _317 = _307 * 162.9746551513671875;\n        float _326 = fast::min((size * 10.0) / _293, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _352 = floor(_317 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _326));\n            float param = v;\n            float param_1 = _352 - (1024.0 * floor(_352 * 0.0009765625));\n            float _366 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_366 < _293)\n            {\n                sum += _366;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _398 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _293)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _416 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _422 = 1.0 - (0.800000011920928955078125 * abs(_416));\n                float param_2 = v;\n                float param_3 = _317 + (_416 * _398);\n                float param_4 = _293;\n                float param_5 = radius;\n                acc += (_422 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _422;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _164 = length(d);\n    if (_164 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _178 = precise::atan2(d.y, d.x);\n    float a = _178;\n    float _181;\n    if (_178 < 0.0)\n    {\n        _181 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _181 = a;\n    }\n    a = _181;\n    float _193 = _181 * 162.9746551513671875;\n    float _198 = fast::min(floor(_193), 1023.0);\n    float _205 = _198 + 1.0;\n    float i1 = _205;\n    if (_205 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _198;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _164) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _164) + 0.5, 0.0, 1.0), _193 - _198);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _503 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _507 = _503.x + 0.5;\n    float2 c = float2(_507, 0.5 - _503.y);\n    bool _515 = _507 >= 0.0;\n    bool _521;\n    if (_515)\n    {\n        _521 = c.x <= 1.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y >= 0.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    bool _533;\n    if (_527)\n    {\n        _533 = c.y <= 1.0;\n    }\n    else\n    {\n        _533 = _527;\n    }\n    float2 _535 = c;\n    float2 _540 = fast::clamp(_535, float2(0.001953125), float2(0.998046875));\n    c = _540;\n    return float3(cell.x + (_540.x * cell.w), cell.y + (_540.y * cell.z), float(_533));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _698, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_698.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _698.light_cookie[i];\n    float4 param_1 = _698.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _822 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _822.xy, level(0.0));\n    return cookie_value(param_3) * _822.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _698, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _844 = _698.lit.y > 0.5;\n    if (_844)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _698.normal_uv.xy) + _698.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _868 = fa_tex_fix(param, param_1);\n        float3 _872 = (_868 * 2.0) - float3(1.0);\n        float _879 = cos(params.y);\n        float _881 = sin(params.y);\n        n = fast::normalize(float3((float2(_879, _881) * _872.x) + ((float2(-_881, _879) * ((mode > 5.5) ? (-1.0) : 1.0)) * _872.y), fast::max(_872.z, 0.0500000007450580596923828125)));\n    }\n    bool _915 = !_844;\n    bool _921;\n    if (_915)\n    {\n        _921 = _698.lit.z > 0.5;\n    }\n    else\n    {\n        _921 = _915;\n    }\n    float3 _924;\n    if (_921)\n    {\n        _924 = _698.flat_ambient.xyz;\n    }\n    else\n    {\n        _924 = _698.ambient.xyz;\n    }\n    float3 total = _924;\n    bool _941;\n    if (_921)\n    {\n        _941 = _698.lit.z < 1.5;\n    }\n    else\n    {\n        _941 = _921;\n    }\n    if (_941)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _698.light_map.xy), level(0.0)).xyz * _698.light_map.z);\n    }\n    float3 l;\n    float _1068;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _978;\n        if (!_921)\n        {\n            _978 = float(i) >= _698.lit.x;\n        }\n        else\n        {\n            _978 = _921;\n        }\n        if (_978)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_698.light_pos[i].w < 0.0)\n        {\n            l = _698.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1004 = _698.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1004) / fast::max(_698.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _698.light_color[i].w);\n            float3 _1024 = float3(_1004, _698.light_pos[i].z);\n            l = _1024 / float3(fast::max(length(_1024), 9.9999997473787516355514526367188e-05));\n            if (_698.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _698.light_shadow_v[i].x;\n                float param_3 = _698.light_shadow_v[i].y;\n                float2 param_4 = -_1004;\n                float param_5 = _698.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1004;\n            att *= cookie_att(param_6, param_7, _698, fx_cookie_tex, light_smp);\n        }\n        if (_844)\n        {\n            _1068 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1068 = 1.0;\n        }\n        total += (_698.light_color[i].xyz * (att * _1068));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _676 = fa_srgb_to_linear(param);\n        c = _676;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1318 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1322 = uv * _1318;\n    float _1328 = _1318.x;\n    float _1330 = _1318.y;\n    float _1332 = fast::clamp(shape_rs.x, 0.0, fast::min(_1328, _1330));\n    float2 _1343 = (abs(_1322) - _1318) + float2(_1332);\n    float d = (length(fast::max(_1343, float2(0.0))) + fast::min(fast::max(_1343.x, _1343.y), 0.0)) - _1332;\n    float ax = params.y;\n    bool _1364 = params.y > 15.0;\n    if (_1364)\n    {\n        ax -= 20.0;\n    }\n    float _1375;\n    if (ax <= (-1.5))\n    {\n        _1375 = (-2.0) - ax;\n    }\n    else\n    {\n        _1375 = 0.0;\n    }\n    if (_1375 > 0.0)\n    {\n        float _1389 = _1375 * 0.5;\n        d = abs(d + _1389) - _1389;\n    }\n    float _1397 = fwidth(d);\n    float _1398 = fast::max(_1397, 9.9999997473787516355514526367188e-05);\n    float _1408 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1398)), 0.0, 1.0);\n    float _1413;\n    if (shape_rs.y > _1398)\n    {\n        _1413 = (_1408 * _1408) * (3.0 - (2.0 * _1408));\n    }\n    else\n    {\n        _1413 = _1408;\n    }\n    float4 c = color;\n    bool _1435 = (_1375 <= 0.0) && (ax > (-0.5));\n    if (_1435)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1450 = cos(ax);\n            float _1452 = sin(ax);\n            g = ((dot(_1322, float2(_1450, _1452)) / fast::max((abs(_1450) * _1328) + (abs(_1452) * _1330), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1364)\n        {\n            float4 _1495 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1495;\n            float3 param = _1495.xyz;\n            float param_1 = xform.y;\n            float3 _1502 = fa_tex_fix(param, param_1);\n            float4 _2290 = c;\n            _2290.x = _1502.x;\n            _2290.y = _1502.y;\n            _2290.z = _1502.z;\n            c = _2290;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1514 = scene_rgb(param_2, xform);\n            float4 _1539 = mix(float4(color.xyz * color.w, color.w), float4(_1514 * color2.w, color2.w), float4(g));\n            float _1541 = _1539.w;\n            float3 _1544;\n            if (_1541 > 9.9999997473787516355514526367188e-06)\n            {\n                _1544 = _1539.xyz / float3(_1541);\n            }\n            else\n            {\n                _1544 = color.xyz;\n            }\n            c = float4(_1544, _1541);\n        }\n    }\n    float4 _2299 = c;\n    _2299.w = _2299.w * _1413;\n    c = _2299;\n    if (_1435 || (shape_rs.y > 0.0))\n    {\n        float _1585 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1594 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1594 + float3(_1585 * 0.0039215688593685626983642578125);\n            float3 _1600 = fa_srgb_to_linear(param_4);\n            float4 _2302 = c;\n            _2302.x = _1600.x;\n            _2302.y = _1600.y;\n            _2302.z = _1600.z;\n            c = _2302;\n        }\n        else\n        {\n            float4 _1610 = c;\n            float3 _1613 = _1610.xyz + float3(_1585 * 0.0039215688593685626983642578125);\n            float4 _2309 = _1610;\n            _2309.x = _1613.x;\n            _2309.y = _1613.y;\n            _2309.z = _1613.z;\n            c = _2309;\n        }\n        float4 _2314 = c;\n        _2314.w = fast::clamp(_2314.w + ((_1585 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2314.w)), 0.0, 1.0);\n        c = _2314;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _698, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1105 = float2(_698.fx_rim_uv.x, 0.0);\n    float4 _1107 = tex.sample(smp, (uv - _1105));\n    float _1108 = _1107.w;\n    float4 _1118 = tex.sample(smp, (uv + _1105));\n    float _1119 = _1118.w;\n    float2 _1127 = float2(0.0, _698.fx_rim_uv.y);\n    float4 _1129 = tex.sample(smp, (uv - _1127));\n    float _1130 = _1129.w;\n    float4 _1140 = tex.sample(smp, (uv + _1127));\n    float _1141 = _1140.w;\n    float _1156 = _1108 - _1119;\n    float _1159 = _1141 - _1130;\n    float _1169 = cos(params.y);\n    float _1171 = sin(params.y);\n    float2 _1197 = ((float2(_1169, _1171) * _1156) + ((float2(-_1171, _1169) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1159)) / float2(fast::max(length(float2(_1156, _1159)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _698.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_698.light_pos[i].w < 0.0)\n        {\n            to_l = _698.light_pos[i].xy / float2(fast::max(length(_698.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1243 = _698.light_pos[i].xy - world_xy;\n            float _1246 = length(_1243);\n            att = powr(fast::clamp(1.0 - (_1246 / fast::max(_698.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _698.light_color[i].w);\n            to_l = _1243 / float2(fast::max(_1246, 9.9999997473787516355514526367188e-05));\n            if (_698.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _698.light_shadow_v[i].x;\n                float param_1 = _698.light_shadow_v[i].y;\n                float2 param_2 = -_1243;\n                float param_3 = _698.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1243;\n            att *= cookie_att(param_4, param_5, _698, fx_cookie_tex, light_smp);\n        }\n        sum += (_698.light_color[i].xyz * (att * fast::max(dot(_1197, to_l), 0.0)));\n    }\n    return (sum * _698.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1108, _1119), fast::min(_1130, _1141))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _698)\n{\n    float2 _704 = gl_FragCoord.xy * _698.fa_target.xy;\n    float _708 = _704.y;\n    return float2(_704.x, mix(_708, 1.0 - _708, _698.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _698, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _746 = base_mode < 0.5;\n    bool _757;\n    if (!_746)\n    {\n        _757 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _757 = _746;\n    }\n    float _758;\n    if (_757)\n    {\n        _758 = shape_half.x;\n    }\n    else\n    {\n        _758 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _698), _698.fa_time.x, base_mode, float4(0.0), _758 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _682 = scene_rgb(param, xform);\n    return _682;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _783)\n{\n    float3 param = tint.xyz;\n    float3 _786 = fa_scene_rgb(param, xform) * _783.boost;\n    s.color.x = _786.x;\n    s.color.y = _786.y;\n    s.color.z = _786.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _698 [[buffer(1)]], constant fa_material& _783 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1640 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1640)\n    {\n        mode -= 32.0;\n    }\n    float _1648 = mode;\n    bool _1650 = _1648 > 15.5;\n    if (_1650)\n    {\n        mode -= 16.0;\n    }\n    float _1658 = mode;\n    bool _1660 = _1658 > 7.5;\n    if (_1660)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1650)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _698, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1650)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _698, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1722 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1724 = _1722 * in.color;\n                float4 param_6 = _1724;\n                float param_7 = mode;\n                float _1731 = _1724.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _698, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1731);\n                if (_698.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1731;\n                    float param_9 = mode;\n                    float4 _1747 = out.frag_color;\n                    float3 _1749 = _1747.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _698, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1749.x;\n                    out.frag_color.y = _1749.y;\n                    out.frag_color.z = _1749.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1779 = length(in.uv);\n                    float _1782 = fwidth(_1779);\n                    float _1783 = fast::max(_1782, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1779) / _1783) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1779) / _1783) + 0.5, 0.0, 1.0) * fast::clamp(((_1779 - in.params.y) / _1783) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1823 = fast::clamp(1.0 - _1779, 0.0, 1.0);\n                            cov = (_1823 * _1823) * (3.0 - (2.0 * _1823));\n                        }\n                    }\n                    float3 _1832;\n                    if (_1650)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1832 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _698, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1832 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1832, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_698.fx_emit.w > 0.5)\n    {\n        float3 e = _698.fx_emit.xyz;\n        if (_698.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _698.fx_emit_uv.xy) + _698.fx_emit_uv.zw)).xyz;\n            float param_13 = _698.fx_emit.w - 2.0;\n            float3 _1887 = fa_tex_fix(param_12, param_13);\n            e *= _1887;\n        }\n        float4 _1891 = out.frag_color;\n        float3 _1893 = _1891.xyz + e;\n        out.frag_color.x = _1893.x;\n        out.frag_color.y = _1893.y;\n        out.frag_color.z = _1893.z;\n    }\n    float param_14 = mode;\n    float4 _2220 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _698, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2220 };\n    fragment0(param_15, param_16, in.xform, tint, _783);\n    _2220 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1640)\n    {\n        float4 _1919 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1924 = scene_rgb(param_17, in.xform);\n        float3 _1928 = mix(_1919.xyz, _1924, float3(in.color2.w));\n        out.frag_color.x = _1928.x;\n        out.frag_color.y = _1928.y;\n        out.frag_color.z = _1928.z;\n    }\n    if (_1660)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1952 = _698.fog_col.w > 0.0;\n    bool _1960;\n    if (!_1952)\n    {\n        _1960 = _698.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1960 = _1952;\n    }\n    if (_1960)\n    {\n        float3 _1974 = float3(in.world_xy, in.world_z) - _698.fog_eye.xyz;\n        float _1981 = dot(_1974, _698.fog_c.xyz);\n        bool _1985 = _698.fog_c.w > 0.5;\n        float _1986;\n        if (_1985)\n        {\n            _1986 = _1981;\n        }\n        else\n        {\n            _1986 = length(_1974);\n        }\n        float _1998 = _1986 - _698.fog_b.x;\n        if (_1998 > 0.0)\n        {\n            float _2007 = _698.fog_col.w * _1998;\n            float tau = _2007 * _2007;\n            if (_698.fog_b.y > 0.0)\n            {\n                float _2023;\n                if (_1985)\n                {\n                    _2023 = in.world_xy.y - (_698.fog_c.y * _1981);\n                }\n                else\n                {\n                    _2023 = _698.fog_eye.y;\n                }\n                float _2044 = mix(_2023, in.world_xy.y, fast::clamp(_698.fog_b.x / _1986, 0.0, 1.0));\n                float _2048 = in.world_xy.y - _2044;\n                float _2053 = _2044 - _698.fog_b.z;\n                float _2058 = in.world_xy.y - _698.fog_b.z;\n                bool _2061 = _2053 <= 0.0;\n                bool _2062 = !_2061;\n                bool _2068;\n                if (_2062)\n                {\n                    _2068 = _698.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2068 = _2061;\n                }\n                float _2069;\n                if (_2068)\n                {\n                    _2069 = _698.fog_b.y;\n                }\n                else\n                {\n                    _2069 = _698.fog_b.y * exp(-fast::min(_698.fog_b.w * _2053, 80.0));\n                }\n                bool _2096;\n                if (_2062)\n                {\n                    _2096 = _698.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2096 = _2061;\n                }\n                float _2097;\n                if (_2096)\n                {\n                    _2097 = _698.fog_b.y * _2053;\n                }\n                else\n                {\n                    _2097 = (_698.fog_b.y * (1.0 - exp(-fast::min(_698.fog_b.w * _2053, 80.0)))) / _698.fog_b.w;\n                }\n                bool _2122 = _2058 <= 0.0;\n                bool _2129;\n                if (!_2122)\n                {\n                    _2129 = _698.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2129 = _2122;\n                }\n                float _2130;\n                if (_2129)\n                {\n                    _2130 = _698.fog_b.y * _2058;\n                }\n                else\n                {\n                    _2130 = (_698.fog_b.y * (1.0 - exp(-fast::min(_698.fog_b.w * _2058, 80.0)))) / _698.fog_b.w;\n                }\n                float _2157;\n                if (abs(_2048) < 0.001000000047497451305389404296875)\n                {\n                    _2157 = _2069;\n                }\n                else\n                {\n                    _2157 = (_2130 - _2097) / _2048;\n                }\n                tau += (_1998 * fast::max(_2157, 0.0));\n            }\n            float4 _2180 = out.frag_color;\n            float3 _2188 = mix(_2180.xyz, _698.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2188.x;\n            out.frag_color.y = _2188.y;\n            out.frag_color.z = _2188.z;\n        }\n    }\n    return out;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_698",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_783",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _162)\n{\n    float2 _169 = gl_FragCoord.xy * _162.fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, mix(_174, 1.0 - _174, _162.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _162, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _162), _162.fa_time.x, base_mode, float4(0.0), _229 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param, xform);\n    return _145;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _254)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param, xform) * _254.boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _162 [[buffer(1)]], constant fa_material& _254 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _284 = tex.sample(smp, in.uv);\n    float3 param = _284.xyz;\n    float param_1 = in.xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_293, _284.w) * in.color;\n    float param_2 = 0.0;\n    float4 _347 = out.frag_color;\n    float shift;\n    float4 tint;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _162, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _347 };\n    fragment0(param_3, param_4, in.xform, tint, _254);\n    _347 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_254",
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
