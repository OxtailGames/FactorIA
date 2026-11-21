{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "extra",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    },
    {
      "name": "points",
      "binding": 1,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    float3 _86 = v.world_pos;\n    float2 _93 = fa_vs_points.data[int(gl_InstanceIndex)].pos.xy + ((_86.xy * fa_vs_points.data[int(gl_InstanceIndex)].pos.w) * ((((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0)) ? 0.0 : 1.0));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _122 [[buffer(0)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    out.fa_inst_index_v = int(gl_InstanceIndex);\n    float3 _192 = in.position;\n    float2 _193 = in.texcoord0;\n    float4 _194 = in.color0;\n    if (_122.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _132 = fa_srgb_to_linear(param);\n        float4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex param_1 = QuadVertex{ _192, _193, _194 };\n    vertex0(param_1, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    out.gl_Position = _122.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _122.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _687, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _823 = (world_xy * _687.gi_xf.xy) + _687.gi_xf.zw;\n    float4 _830 = fx_gi_tex.sample(light_smp, _823, level(0.0));\n    float _834 = _823.x;\n    bool _835 = _834 >= 0.0;\n    bool _841;\n    if (_835)\n    {\n        _841 = _823.y >= 0.0;\n    }\n    else\n    {\n        _841 = _835;\n    }\n    bool _847;\n    if (_841)\n    {\n        _847 = _834 <= 1.0;\n    }\n    else\n    {\n        _847 = _841;\n    }\n    bool _853;\n    if (_847)\n    {\n        _853 = _823.y <= 1.0;\n    }\n    else\n    {\n        _853 = _847;\n    }\n    bool _861;\n    if (_853)\n    {\n        _861 = _830.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _861 = _853;\n    }\n    float3 _862;\n    if (_861)\n    {\n        _862 = (_830.xyz / float3(_830.w)) * _687.gi_p.x;\n    }\n    else\n    {\n        _862 = float3(0.0);\n    }\n    return _862;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _687, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_687.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _687.light_cookie[i];\n    float4 param_1 = _687.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _797 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _797.xy, level(0.0));\n    return cookie_value(param_3) * _797.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _687, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _884 = _687.lit.y > 0.5;\n    if (_884)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _687.normal_uv.xy) + _687.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _908 = fa_tex_fix(param, param_1);\n        float3 _912 = (_908 * 2.0) - float3(1.0);\n        float _919 = cos(params.y);\n        float _921 = sin(params.y);\n        n = fast::normalize(float3((float2(_919, _921) * _912.x) + ((float2(-_921, _919) * ((mode > 5.5) ? (-1.0) : 1.0)) * _912.y), fast::max(_912.z, 0.0500000007450580596923828125)));\n    }\n    bool _955 = !_884;\n    bool _961;\n    if (_955)\n    {\n        _961 = _687.lit.z > 0.5;\n    }\n    else\n    {\n        _961 = _955;\n    }\n    float3 _964;\n    if (_961)\n    {\n        _964 = _687.flat_ambient.xyz;\n    }\n    else\n    {\n        _964 = _687.ambient.xyz;\n    }\n    float3 total = _964;\n    if (_687.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_687, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _989;\n    if (_961)\n    {\n        _989 = _687.lit.z < 1.5;\n    }\n    else\n    {\n        _989 = _961;\n    }\n    if (_989)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _687.light_map.xy), level(0.0)).xyz * _687.light_map.z);\n    }\n    float3 l;\n    float _1116;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1026;\n        if (!_961)\n        {\n            _1026 = float(i) >= _687.lit.x;\n        }\n        else\n        {\n            _1026 = _961;\n        }\n        if (_1026)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_687.light_pos[i].w < 0.0)\n        {\n            l = _687.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1052 = _687.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1052) / fast::max(_687.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _687.light_color[i].w);\n            float3 _1072 = float3(_1052, _687.light_pos[i].z);\n            l = _1072 / float3(fast::max(length(_1072), 9.9999997473787516355514526367188e-05));\n            if (_687.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _687.light_shadow_v[i].x;\n                float param_3 = _687.light_shadow_v[i].y;\n                float2 param_4 = -_1052;\n                float param_5 = _687.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1052;\n            att *= cookie_att(param_6, param_7, _687, fx_cookie_tex, light_smp);\n        }\n        if (_884)\n        {\n            _1116 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1116 = 1.0;\n        }\n        total += (_687.light_color[i].xyz * (att * _1116));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1366 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1370 = uv * _1366;\n    float _1376 = _1366.x;\n    float _1378 = _1366.y;\n    float _1380 = fast::clamp(shape_rs.x, 0.0, fast::min(_1376, _1378));\n    float2 _1391 = (abs(_1370) - _1366) + float2(_1380);\n    float d = (length(fast::max(_1391, float2(0.0))) + fast::min(fast::max(_1391.x, _1391.y), 0.0)) - _1380;\n    float ax = params.y;\n    bool _1412 = params.y > 15.0;\n    if (_1412)\n    {\n        ax -= 20.0;\n    }\n    float _1423;\n    if (ax <= (-1.5))\n    {\n        _1423 = (-2.0) - ax;\n    }\n    else\n    {\n        _1423 = 0.0;\n    }\n    if (_1423 > 0.0)\n    {\n        float _1437 = _1423 * 0.5;\n        d = abs(d + _1437) - _1437;\n    }\n    float _1445 = fwidth(d);\n    float _1446 = fast::max(_1445, 9.9999997473787516355514526367188e-05);\n    float _1456 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1446)), 0.0, 1.0);\n    float _1461;\n    if (shape_rs.y > _1446)\n    {\n        _1461 = (_1456 * _1456) * (3.0 - (2.0 * _1456));\n    }\n    else\n    {\n        _1461 = _1456;\n    }\n    float4 c = color;\n    bool _1483 = (_1423 <= 0.0) && (ax > (-0.5));\n    if (_1483)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1498 = cos(ax);\n            float _1500 = sin(ax);\n            g = ((dot(_1370, float2(_1498, _1500)) / fast::max((abs(_1498) * _1376) + (abs(_1500) * _1378), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1412)\n        {\n            float4 _1543 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1543;\n            float3 param = _1543.xyz;\n            float param_1 = xform.y;\n            float3 _1550 = fa_tex_fix(param, param_1);\n            float4 _2349 = c;\n            _2349.x = _1550.x;\n            _2349.y = _1550.y;\n            _2349.z = _1550.z;\n            c = _2349;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1562 = scene_rgb(param_2, xform);\n            float4 _1587 = mix(float4(color.xyz * color.w, color.w), float4(_1562 * color2.w, color2.w), float4(g));\n            float _1589 = _1587.w;\n            float3 _1592;\n            if (_1589 > 9.9999997473787516355514526367188e-06)\n            {\n                _1592 = _1587.xyz / float3(_1589);\n            }\n            else\n            {\n                _1592 = color.xyz;\n            }\n            c = float4(_1592, _1589);\n        }\n    }\n    float4 _2358 = c;\n    _2358.w = _2358.w * _1461;\n    c = _2358;\n    if (_1483 || (shape_rs.y > 0.0))\n    {\n        float _1633 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1642 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1642 + float3(_1633 * 0.0039215688593685626983642578125);\n            float3 _1648 = fa_srgb_to_linear(param_4);\n            float4 _2361 = c;\n            _2361.x = _1648.x;\n            _2361.y = _1648.y;\n            _2361.z = _1648.z;\n            c = _2361;\n        }\n        else\n        {\n            float4 _1658 = c;\n            float3 _1661 = _1658.xyz + float3(_1633 * 0.0039215688593685626983642578125);\n            float4 _2368 = _1658;\n            _2368.x = _1661.x;\n            _2368.y = _1661.y;\n            _2368.z = _1661.z;\n            c = _2368;\n        }\n        float4 _2373 = c;\n        _2373.w = fast::clamp(_2373.w + ((_1633 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2373.w)), 0.0, 1.0);\n        c = _2373;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _687, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1153 = float2(_687.fx_rim_uv.x, 0.0);\n    float4 _1155 = tex.sample(smp, (uv - _1153));\n    float _1156 = _1155.w;\n    float4 _1166 = tex.sample(smp, (uv + _1153));\n    float _1167 = _1166.w;\n    float2 _1175 = float2(0.0, _687.fx_rim_uv.y);\n    float4 _1177 = tex.sample(smp, (uv - _1175));\n    float _1178 = _1177.w;\n    float4 _1188 = tex.sample(smp, (uv + _1175));\n    float _1189 = _1188.w;\n    float _1204 = _1156 - _1167;\n    float _1207 = _1189 - _1178;\n    float _1217 = cos(params.y);\n    float _1219 = sin(params.y);\n    float2 _1245 = ((float2(_1217, _1219) * _1204) + ((float2(-_1219, _1217) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1207)) / float2(fast::max(length(float2(_1204, _1207)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _687.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_687.light_pos[i].w < 0.0)\n        {\n            to_l = _687.light_pos[i].xy / float2(fast::max(length(_687.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1291 = _687.light_pos[i].xy - world_xy;\n            float _1294 = length(_1291);\n            att = powr(fast::clamp(1.0 - (_1294 / fast::max(_687.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _687.light_color[i].w);\n            to_l = _1291 / float2(fast::max(_1294, 9.9999997473787516355514526367188e-05));\n            if (_687.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _687.light_shadow_v[i].x;\n                float param_1 = _687.light_shadow_v[i].y;\n                float2 param_2 = -_1291;\n                float param_3 = _687.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1291;\n            att *= cookie_att(param_4, param_5, _687, fx_cookie_tex, light_smp);\n        }\n        sum += (_687.light_color[i].xyz * (att * fast::max(dot(_1245, to_l), 0.0)));\n    }\n    return (sum * _687.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1156, _1167), fast::min(_1178, _1189))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _687)\n{\n    float2 _693 = gl_FragCoord.xy * _687.fa_target.xy;\n    float _697 = _693.y;\n    return float2(_693.x, mix(_697, 1.0 - _697, _687.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _687, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _735 = base_mode < 0.5;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _687), _687.fa_time.x, base_mode, float4(0.0), _747 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _687 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1688 = in.params.x > 31.5;\n    if (_1688)\n    {\n        mode -= 32.0;\n    }\n    float _1696 = mode;\n    bool _1698 = _1696 > 15.5;\n    if (_1698)\n    {\n        mode -= 16.0;\n    }\n    float _1706 = mode;\n    bool _1708 = _1706 > 7.5;\n    if (_1708)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1698)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1698)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1770 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1772 = _1770 * in.color;\n                float4 param_6 = _1772;\n                float param_7 = mode;\n                float _1779 = _1772.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1779);\n                if (_687.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1779;\n                    float param_9 = mode;\n                    float4 _1795 = out.frag_color;\n                    float3 _1797 = _1795.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1797.x;\n                    out.frag_color.y = _1797.y;\n                    out.frag_color.z = _1797.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1827 = length(in.uv);\n                    float _1830 = fwidth(_1827);\n                    float _1831 = fast::max(_1830, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1827) / _1831) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1827) / _1831) + 0.5, 0.0, 1.0) * fast::clamp(((_1827 - in.params.y) / _1831) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1871 = fast::clamp(1.0 - _1827, 0.0, 1.0);\n                            cov = (_1871 * _1871) * (3.0 - (2.0 * _1871));\n                        }\n                    }\n                    float3 _1880;\n                    if (_1698)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1880 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1880 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1880, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_687.fx_emit.w > 0.5)\n    {\n        float3 e = _687.fx_emit.xyz;\n        if (_687.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _687.fx_emit_uv.xy) + _687.fx_emit_uv.zw)).xyz;\n            float param_13 = _687.fx_emit.w - 2.0;\n            float3 _1935 = fa_tex_fix(param_12, param_13);\n            e *= _1935;\n        }\n        float4 _1939 = out.frag_color;\n        float3 _1941 = _1939.xyz + e;\n        out.frag_color.x = _1941.x;\n        out.frag_color.y = _1941.y;\n        out.frag_color.z = _1941.z;\n    }\n    float param_14 = mode;\n    float4 _2273 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _687, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2273 };\n    fragment0(param_15, param_16, points, in.fa_inst_index_v);\n    _2273 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1688)\n    {\n        float4 _1967 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1972 = scene_rgb(param_17, in.xform);\n        float3 _1976 = mix(_1967.xyz, _1972, float3(in.color2.w));\n        out.frag_color.x = _1976.x;\n        out.frag_color.y = _1976.y;\n        out.frag_color.z = _1976.z;\n    }\n    if (_1708)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2000 = _687.fog_col.w > 0.0;\n    bool _2008;\n    if (!_2000)\n    {\n        _2008 = _687.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2008 = _2000;\n    }\n    if (_2008)\n    {\n        float3 _2022 = float3(in.world_xy, in.world_z) - _687.fog_eye.xyz;\n        float _2029 = dot(_2022, _687.fog_c.xyz);\n        bool _2033 = _687.fog_c.w > 0.5;\n        float _2034;\n        if (_2033)\n        {\n            _2034 = _2029;\n        }\n        else\n        {\n            _2034 = length(_2022);\n        }\n        float _2046 = _2034 - _687.fog_b.x;\n        if (_2046 > 0.0)\n        {\n            float _2055 = _687.fog_col.w * _2046;\n            float tau = _2055 * _2055;\n            if (_687.fog_b.y > 0.0)\n            {\n                float _2071;\n                if (_2033)\n                {\n                    _2071 = in.world_xy.y - (_687.fog_c.y * _2029);\n                }\n                else\n                {\n                    _2071 = _687.fog_eye.y;\n                }\n                float _2092 = mix(_2071, in.world_xy.y, fast::clamp(_687.fog_b.x / _2034, 0.0, 1.0));\n                float _2096 = in.world_xy.y - _2092;\n                float _2101 = _2092 - _687.fog_b.z;\n                float _2106 = in.world_xy.y - _687.fog_b.z;\n                bool _2109 = _2101 <= 0.0;\n                bool _2110 = !_2109;\n                bool _2116;\n                if (_2110)\n                {\n                    _2116 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2116 = _2109;\n                }\n                float _2117;\n                if (_2116)\n                {\n                    _2117 = _687.fog_b.y;\n                }\n                else\n                {\n                    _2117 = _687.fog_b.y * exp(-fast::min(_687.fog_b.w * _2101, 80.0));\n                }\n                bool _2144;\n                if (_2110)\n                {\n                    _2144 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2144 = _2109;\n                }\n                float _2145;\n                if (_2144)\n                {\n                    _2145 = _687.fog_b.y * _2101;\n                }\n                else\n                {\n                    _2145 = (_687.fog_b.y * (1.0 - exp(-fast::min(_687.fog_b.w * _2101, 80.0)))) / _687.fog_b.w;\n                }\n                bool _2170 = _2106 <= 0.0;\n                bool _2177;\n                if (!_2170)\n                {\n                    _2177 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2177 = _2170;\n                }\n                float _2178;\n                if (_2177)\n                {\n                    _2178 = _687.fog_b.y * _2106;\n                }\n                else\n                {\n                    _2178 = (_687.fog_b.y * (1.0 - exp(-fast::min(_687.fog_b.w * _2106, 80.0)))) / _687.fog_b.w;\n                }\n                float _2205;\n                if (abs(_2096) < 0.001000000047497451305389404296875)\n                {\n                    _2205 = _2117;\n                }\n                else\n                {\n                    _2205 = (_2178 - _2145) / _2096;\n                }\n                tau += (_2046 * fast::max(_2205, 0.0));\n            }\n            float4 _2228 = out.frag_color;\n            float3 _2236 = mix(_2228.xyz, _687.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2236.x;\n            out.frag_color.y = _2236.y;\n            out.frag_color.z = _2236.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_122",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_687",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    float3 _86 = v.world_pos;\n    float2 _93 = fa_vs_points.data[int(gl_InstanceIndex)].pos.xy + ((_86.xy * fa_vs_points.data[int(gl_InstanceIndex)].pos.w) * ((((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0)) ? 0.0 : 1.0));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _122 [[buffer(0)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    out.fa_inst_index_v = int(gl_InstanceIndex);\n    float3 _192 = in.position;\n    float2 _193 = in.texcoord0;\n    float4 _194 = in.color0;\n    if (_122.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _132 = fa_srgb_to_linear(param);\n        float4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex param_1 = QuadVertex{ _192, _193, _194 };\n    vertex0(param_1, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    out.gl_Position = _122.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _122.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _240 = tex.sample(smp, in.uv);\n    float3 param = _240.xyz;\n    float param_1 = in.xform.y;\n    float3 _251 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_251, _240.w) * in.color;\n    float param_2 = 0.0;\n    float4 _310 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _310 };\n    fragment0(param_3, param_4, points, in.fa_inst_index_v);\n    _310 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_122",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1552,
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
