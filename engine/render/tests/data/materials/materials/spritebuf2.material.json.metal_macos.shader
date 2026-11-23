{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _688, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _824 = (world_xy * _688.gi_xf.xy) + _688.gi_xf.zw;\n    float4 _831 = fx_gi_tex.sample(light_smp, _824, level(0.0));\n    float _835 = _824.x;\n    bool _836 = _835 >= 0.0;\n    bool _842;\n    if (_836)\n    {\n        _842 = _824.y >= 0.0;\n    }\n    else\n    {\n        _842 = _836;\n    }\n    bool _848;\n    if (_842)\n    {\n        _848 = _835 <= 1.0;\n    }\n    else\n    {\n        _848 = _842;\n    }\n    bool _854;\n    if (_848)\n    {\n        _854 = _824.y <= 1.0;\n    }\n    else\n    {\n        _854 = _848;\n    }\n    bool _862;\n    if (_854)\n    {\n        _862 = _831.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _862 = _854;\n    }\n    float3 _863;\n    if (_862)\n    {\n        _863 = (_831.xyz / float3(_831.w)) * _688.gi_p.x;\n    }\n    else\n    {\n        _863 = float3(0.0);\n    }\n    return _863;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _688, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_688.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _688.light_cookie[i];\n    float4 param_1 = _688.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _798 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _798.xy, level(0.0));\n    return cookie_value(param_3) * _798.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _688, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _885 = _688.lit.y > 0.5;\n    if (_885)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _688.normal_uv.xy) + _688.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _909 = fa_tex_fix(param, param_1);\n        float3 _913 = (_909 * 2.0) - float3(1.0);\n        float _920 = cos(params.y);\n        float _922 = sin(params.y);\n        n = fast::normalize(float3((float2(_920, _922) * _913.x) + ((float2(-_922, _920) * ((mode > 5.5) ? (-1.0) : 1.0)) * _913.y), fast::max(_913.z, 0.0500000007450580596923828125)));\n    }\n    bool _956 = !_885;\n    bool _962;\n    if (_956)\n    {\n        _962 = _688.lit.z > 0.5;\n    }\n    else\n    {\n        _962 = _956;\n    }\n    float3 _965;\n    if (_962)\n    {\n        _965 = _688.flat_ambient.xyz;\n    }\n    else\n    {\n        _965 = _688.ambient.xyz;\n    }\n    float3 total = _965;\n    if (_688.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_688, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _990;\n    if (_962)\n    {\n        _990 = _688.lit.z < 1.5;\n    }\n    else\n    {\n        _990 = _962;\n    }\n    if (_990)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _688.light_map.xy), level(0.0)).xyz * _688.light_map.z);\n    }\n    float3 l;\n    float _1117;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1027;\n        if (!_962)\n        {\n            _1027 = float(i) >= _688.lit.x;\n        }\n        else\n        {\n            _1027 = _962;\n        }\n        if (_1027)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_688.light_pos[i].w < 0.0)\n        {\n            l = _688.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1053 = _688.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1053) / fast::max(_688.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _688.light_color[i].w);\n            float3 _1073 = float3(_1053, _688.light_pos[i].z);\n            l = _1073 / float3(fast::max(length(_1073), 9.9999997473787516355514526367188e-05));\n            if (_688.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _688.light_shadow_v[i].x;\n                float param_3 = _688.light_shadow_v[i].y;\n                float2 param_4 = -_1053;\n                float param_5 = _688.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1053;\n            att *= cookie_att(param_6, param_7, _688, fx_cookie_tex, light_smp);\n        }\n        if (_885)\n        {\n            _1117 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1117 = 1.0;\n        }\n        total += (_688.light_color[i].xyz * (att * _1117));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1367 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1371 = uv * _1367;\n    float _1377 = _1367.x;\n    float _1379 = _1367.y;\n    float _1381 = fast::clamp(shape_rs.x, 0.0, fast::min(_1377, _1379));\n    float2 _1392 = (abs(_1371) - _1367) + float2(_1381);\n    float d = (length(fast::max(_1392, float2(0.0))) + fast::min(fast::max(_1392.x, _1392.y), 0.0)) - _1381;\n    float ax = params.y;\n    bool _1413 = params.y > 15.0;\n    if (_1413)\n    {\n        ax -= 20.0;\n    }\n    float _1424;\n    if (ax <= (-1.5))\n    {\n        _1424 = (-2.0) - ax;\n    }\n    else\n    {\n        _1424 = 0.0;\n    }\n    if (_1424 > 0.0)\n    {\n        float _1438 = _1424 * 0.5;\n        d = abs(d + _1438) - _1438;\n    }\n    float _1446 = fwidth(d);\n    float _1447 = fast::max(_1446, 9.9999997473787516355514526367188e-05);\n    float _1457 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1447)), 0.0, 1.0);\n    float _1462;\n    if (shape_rs.y > _1447)\n    {\n        _1462 = (_1457 * _1457) * (3.0 - (2.0 * _1457));\n    }\n    else\n    {\n        _1462 = _1457;\n    }\n    float4 c = color;\n    bool _1484 = (_1424 <= 0.0) && (ax > (-0.5));\n    if (_1484)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1499 = cos(ax);\n            float _1501 = sin(ax);\n            g = ((dot(_1371, float2(_1499, _1501)) / fast::max((abs(_1499) * _1377) + (abs(_1501) * _1379), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1413)\n        {\n            float4 _1544 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1544;\n            float3 param = _1544.xyz;\n            float param_1 = xform.y;\n            float3 _1551 = fa_tex_fix(param, param_1);\n            float4 _2351 = c;\n            _2351.x = _1551.x;\n            _2351.y = _1551.y;\n            _2351.z = _1551.z;\n            c = _2351;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1563 = scene_rgb(param_2, xform);\n            float4 _1588 = mix(float4(color.xyz * color.w, color.w), float4(_1563 * color2.w, color2.w), float4(g));\n            float _1590 = _1588.w;\n            float3 _1593;\n            if (_1590 > 9.9999997473787516355514526367188e-06)\n            {\n                _1593 = _1588.xyz / float3(_1590);\n            }\n            else\n            {\n                _1593 = color.xyz;\n            }\n            c = float4(_1593, _1590);\n        }\n    }\n    float4 _2360 = c;\n    _2360.w = _2360.w * _1462;\n    c = _2360;\n    if (_1484 || (shape_rs.y > 0.0))\n    {\n        float _1634 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1643 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1643 + float3(_1634 * 0.0039215688593685626983642578125);\n            float3 _1649 = fa_srgb_to_linear(param_4);\n            float4 _2363 = c;\n            _2363.x = _1649.x;\n            _2363.y = _1649.y;\n            _2363.z = _1649.z;\n            c = _2363;\n        }\n        else\n        {\n            float4 _1659 = c;\n            float3 _1662 = _1659.xyz + float3(_1634 * 0.0039215688593685626983642578125);\n            float4 _2370 = _1659;\n            _2370.x = _1662.x;\n            _2370.y = _1662.y;\n            _2370.z = _1662.z;\n            c = _2370;\n        }\n        float4 _2375 = c;\n        _2375.w = fast::clamp(_2375.w + ((_1634 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2375.w)), 0.0, 1.0);\n        c = _2375;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _688, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1154 = float2(_688.fx_rim_uv.x, 0.0);\n    float4 _1156 = tex.sample(smp, (uv - _1154));\n    float _1157 = _1156.w;\n    float4 _1167 = tex.sample(smp, (uv + _1154));\n    float _1168 = _1167.w;\n    float2 _1176 = float2(0.0, _688.fx_rim_uv.y);\n    float4 _1178 = tex.sample(smp, (uv - _1176));\n    float _1179 = _1178.w;\n    float4 _1189 = tex.sample(smp, (uv + _1176));\n    float _1190 = _1189.w;\n    float _1205 = _1157 - _1168;\n    float _1208 = _1190 - _1179;\n    float _1218 = cos(params.y);\n    float _1220 = sin(params.y);\n    float2 _1246 = ((float2(_1218, _1220) * _1205) + ((float2(-_1220, _1218) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1208)) / float2(fast::max(length(float2(_1205, _1208)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _688.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_688.light_pos[i].w < 0.0)\n        {\n            to_l = _688.light_pos[i].xy / float2(fast::max(length(_688.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1292 = _688.light_pos[i].xy - world_xy;\n            float _1295 = length(_1292);\n            att = powr(fast::clamp(1.0 - (_1295 / fast::max(_688.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _688.light_color[i].w);\n            to_l = _1292 / float2(fast::max(_1295, 9.9999997473787516355514526367188e-05));\n            if (_688.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _688.light_shadow_v[i].x;\n                float param_1 = _688.light_shadow_v[i].y;\n                float2 param_2 = -_1292;\n                float param_3 = _688.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1292;\n            att *= cookie_att(param_4, param_5, _688, fx_cookie_tex, light_smp);\n        }\n        sum += (_688.light_color[i].xyz * (att * fast::max(dot(_1246, to_l), 0.0)));\n    }\n    return (sum * _688.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1157, _1168), fast::min(_1179, _1190))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _688)\n{\n    float2 _694 = gl_FragCoord.xy * _688.fa_target.xy;\n    float _698 = _694.y;\n    return float2(_694.x, mix(_698, 1.0 - _698, _688.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _688, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _736 = base_mode < 0.5;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _688), _688.fa_time.x, base_mode, float4(0.0), _748 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _688 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1689 = in.params.x > 31.5;\n    if (_1689)\n    {\n        mode -= 32.0;\n    }\n    float _1697 = mode;\n    bool _1699 = _1697 > 15.5;\n    if (_1699)\n    {\n        mode -= 16.0;\n    }\n    float _1707 = mode;\n    bool _1709 = _1707 > 7.5;\n    if (_1709)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1699)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1699)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1771 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1773 = _1771 * in.color;\n                float4 param_6 = _1773;\n                float param_7 = mode;\n                float _1780 = _1773.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1780);\n                if (_688.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1780;\n                    float param_9 = mode;\n                    float4 _1796 = out.frag_color;\n                    float3 _1798 = _1796.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1798.x;\n                    out.frag_color.y = _1798.y;\n                    out.frag_color.z = _1798.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1828 = length(in.uv);\n                    float _1831 = fwidth(_1828);\n                    float _1832 = fast::max(_1831, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1828) / _1832) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1828) / _1832) + 0.5, 0.0, 1.0) * fast::clamp(((_1828 - in.params.y) / _1832) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1872 = fast::clamp(1.0 - _1828, 0.0, 1.0);\n                            cov = (_1872 * _1872) * (3.0 - (2.0 * _1872));\n                        }\n                    }\n                    float3 _1881;\n                    if (_1699)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1881 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1881 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1881, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_688.fx_emit.w > 0.5)\n    {\n        float3 e = _688.fx_emit.xyz;\n        if (_688.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _688.fx_emit_uv.xy) + _688.fx_emit_uv.zw)).xyz;\n            float param_13 = _688.fx_emit.w - 2.0;\n            float3 _1936 = fa_tex_fix(param_12, param_13);\n            e *= _1936;\n        }\n        float4 _1940 = out.frag_color;\n        float3 _1942 = _1940.xyz + e;\n        out.frag_color.x = _1942.x;\n        out.frag_color.y = _1942.y;\n        out.frag_color.z = _1942.z;\n    }\n    float param_14 = mode;\n    float4 _2275 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _688, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2275 };\n    fragment0(param_15, param_16, points, in.fa_inst_index_v);\n    _2275 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1689)\n    {\n        float4 _1968 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1973 = scene_rgb(param_17, in.xform);\n        float3 _1977 = mix(_1968.xyz, _1973, float3(in.color2.w));\n        out.frag_color.x = _1977.x;\n        out.frag_color.y = _1977.y;\n        out.frag_color.z = _1977.z;\n    }\n    if (_1709)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2001 = _688.fog_col.w > 0.0;\n    bool _2009;\n    if (!_2001)\n    {\n        _2009 = _688.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2009 = _2001;\n    }\n    if (_2009)\n    {\n        float3 _2023 = float3(in.world_xy, in.world_z) - _688.fog_eye.xyz;\n        float _2030 = dot(_2023, _688.fog_c.xyz);\n        bool _2034 = _688.fog_c.w > 0.5;\n        float _2035;\n        if (_2034)\n        {\n            _2035 = _2030;\n        }\n        else\n        {\n            _2035 = length(_2023);\n        }\n        float _2047 = _2035 - _688.fog_b.x;\n        if (_2047 > 0.0)\n        {\n            float _2056 = _688.fog_col.w * _2047;\n            float tau = _2056 * _2056;\n            if (_688.fog_b.y > 0.0)\n            {\n                float _2072;\n                if (_2034)\n                {\n                    _2072 = in.world_xy.y - (_688.fog_c.y * _2030);\n                }\n                else\n                {\n                    _2072 = _688.fog_eye.y;\n                }\n                float _2093 = mix(_2072, in.world_xy.y, fast::clamp(_688.fog_b.x / _2035, 0.0, 1.0));\n                float _2097 = in.world_xy.y - _2093;\n                float _2102 = _2093 - _688.fog_b.z;\n                float _2107 = in.world_xy.y - _688.fog_b.z;\n                bool _2110 = _2102 <= 0.0;\n                bool _2111 = !_2110;\n                bool _2117;\n                if (_2111)\n                {\n                    _2117 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2117 = _2110;\n                }\n                float _2118;\n                if (_2117)\n                {\n                    _2118 = _688.fog_b.y;\n                }\n                else\n                {\n                    _2118 = _688.fog_b.y * exp(-fast::min(_688.fog_b.w * _2102, 80.0));\n                }\n                bool _2145;\n                if (_2111)\n                {\n                    _2145 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2145 = _2110;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = _688.fog_b.y * _2102;\n                }\n                else\n                {\n                    _2146 = (_688.fog_b.y * (1.0 - exp(-fast::min(_688.fog_b.w * _2102, 80.0)))) / _688.fog_b.w;\n                }\n                bool _2171 = _2107 <= 0.0;\n                bool _2178;\n                if (!_2171)\n                {\n                    _2178 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2178 = _2171;\n                }\n                float _2179;\n                if (_2178)\n                {\n                    _2179 = _688.fog_b.y * _2107;\n                }\n                else\n                {\n                    _2179 = (_688.fog_b.y * (1.0 - exp(-fast::min(_688.fog_b.w * _2107, 80.0)))) / _688.fog_b.w;\n                }\n                float _2206;\n                if (abs(_2097) < 0.001000000047497451305389404296875)\n                {\n                    _2206 = _2118;\n                }\n                else\n                {\n                    _2206 = (_2179 - _2146) / _2097;\n                }\n                tau += (_2047 * fast::max(_2206, 0.0));\n            }\n            float4 _2229 = out.frag_color;\n            float3 _2237 = mix(_2229.xyz, _688.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2237.x;\n            out.frag_color.y = _2237.y;\n            out.frag_color.z = _2237.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_688",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _242 = tex.sample(smp, in.uv);\n    float3 param = _242.xyz;\n    float param_1 = in.xform.y;\n    float3 _253 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_253, _242.w) * in.color;\n    float param_2 = 0.0;\n    float4 _313 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _313 };\n    fragment0(param_3, param_4, points, in.fa_inst_index_v);\n    _313 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1616,
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
