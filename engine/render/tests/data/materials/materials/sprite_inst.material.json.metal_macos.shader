{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "be09d710d10cdccec43655f10e6af3b043d5ce26db7fbf1ce164733ea9edbe00",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _634 = fa_linear_to_srgb(param);\n        c = _634;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _642 = fa_srgb_to_linear(param_1);\n            c = _642;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _653 = tex.sample(smp, p);\n    float3 param = _653.xyz;\n    float param_1 = xform.y;\n    float3 _663 = fa_tex_fix(param, param_1);\n    return float4(_663, _653.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _702, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _852 = (world_xy * _702.gi_xf.xy) + _702.gi_xf.zw;\n    float4 _859 = fx_gi_tex.sample(light_smp, _852, level(0.0));\n    float _863 = _852.x;\n    bool _864 = _863 >= 0.0;\n    bool _870;\n    if (_864)\n    {\n        _870 = _852.y >= 0.0;\n    }\n    else\n    {\n        _870 = _864;\n    }\n    bool _876;\n    if (_870)\n    {\n        _876 = _863 <= 1.0;\n    }\n    else\n    {\n        _876 = _870;\n    }\n    bool _882;\n    if (_876)\n    {\n        _882 = _852.y <= 1.0;\n    }\n    else\n    {\n        _882 = _876;\n    }\n    bool _890;\n    if (_882)\n    {\n        _890 = _859.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _890 = _882;\n    }\n    float3 _891;\n    if (_890)\n    {\n        _891 = (_859.xyz / float3(_859.w)) * _702.gi_p.x;\n    }\n    else\n    {\n        _891 = float3(0.0);\n    }\n    return _891;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _143 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_143.x * 255.0) + 0.5) * 256.0) + floor((_143.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _246 = floor(tt);\n    float _256 = _246 - (1024.0 * floor(_246 * 0.0009765625));\n    float _259 = _256 + 1.0;\n    float i1 = _259;\n    if (_259 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _256;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _246);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _296 = length(d);\n    float result = 1.0;\n    if (_296 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _307 = precise::atan2(d.y, d.x);\n        float a = _307;\n        float _310;\n        if (_307 < 0.0)\n        {\n            _310 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _310 = a;\n        }\n        a = _310;\n        float _320 = _310 * 162.9746551513671875;\n        float _329 = fast::min((size * 10.0) / _296, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _355 = floor(_320 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _329));\n            float param = v;\n            float param_1 = _355 - (1024.0 * floor(_355 * 0.0009765625));\n            float _369 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_369 < _296)\n            {\n                sum += _369;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _401 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _296)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _419 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _425 = 1.0 - (0.800000011920928955078125 * abs(_419));\n                float param_2 = v;\n                float param_3 = _320 + (_419 * _401);\n                float param_4 = _296;\n                float param_5 = radius;\n                acc += (_425 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _425;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _167 = length(d);\n    if (_167 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _181 = precise::atan2(d.y, d.x);\n    float a = _181;\n    float _184;\n    if (_181 < 0.0)\n    {\n        _184 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _184 = a;\n    }\n    a = _184;\n    float _196 = _184 * 162.9746551513671875;\n    float _201 = fast::min(floor(_196), 1023.0);\n    float _208 = _201 + 1.0;\n    float i1 = _208;\n    if (_208 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _201;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _167) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _167) + 0.5, 0.0, 1.0), _196 - _201);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _506 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _510 = _506.x + 0.5;\n    float2 c = float2(_510, 0.5 - _506.y);\n    bool _518 = _510 >= 0.0;\n    bool _524;\n    if (_518)\n    {\n        _524 = c.x <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y >= 0.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    bool _536;\n    if (_530)\n    {\n        _536 = c.y <= 1.0;\n    }\n    else\n    {\n        _536 = _530;\n    }\n    float2 _538 = c;\n    float2 _543 = fast::clamp(_538, float2(0.001953125), float2(0.998046875));\n    c = _543;\n    return float3(cell.x + (_543.x * cell.w), cell.y + (_543.y * cell.z), float(_536));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _702, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_702.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _702.light_cookie[i];\n    float4 param_1 = _702.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _826 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _826.xy, level(0.0));\n    return cookie_value(param_3) * _826.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _702, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _913 = _702.lit.y > 0.5;\n    if (_913)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _702.normal_uv.xy) + _702.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _937 = fa_tex_fix(param, param_1);\n        float3 _941 = (_937 * 2.0) - float3(1.0);\n        float _948 = cos(params.y);\n        float _950 = sin(params.y);\n        n = fast::normalize(float3((float2(_948, _950) * _941.x) + ((float2(-_950, _948) * ((mode > 5.5) ? (-1.0) : 1.0)) * _941.y), fast::max(_941.z, 0.0500000007450580596923828125)));\n    }\n    bool _984 = !_913;\n    bool _990;\n    if (_984)\n    {\n        _990 = _702.lit.z > 0.5;\n    }\n    else\n    {\n        _990 = _984;\n    }\n    float3 _993;\n    if (_990)\n    {\n        _993 = _702.flat_ambient.xyz;\n    }\n    else\n    {\n        _993 = _702.ambient.xyz;\n    }\n    float3 total = _993;\n    if (_702.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_702, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _1018;\n    if (_990)\n    {\n        _1018 = _702.lit.z < 1.5;\n    }\n    else\n    {\n        _1018 = _990;\n    }\n    if (_1018)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _702.light_map.xy), level(0.0)).xyz * _702.light_map.z);\n    }\n    float3 l;\n    float _1145;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1055;\n        if (!_990)\n        {\n            _1055 = float(i) >= _702.lit.x;\n        }\n        else\n        {\n            _1055 = _990;\n        }\n        if (_1055)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_702.light_pos[i].w < 0.0)\n        {\n            l = _702.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1081 = _702.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1081) / fast::max(_702.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _702.light_color[i].w);\n            float3 _1101 = float3(_1081, _702.light_pos[i].z);\n            l = _1101 / float3(fast::max(length(_1101), 9.9999997473787516355514526367188e-05));\n            if (_702.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _702.light_shadow_v[i].x;\n                float param_3 = _702.light_shadow_v[i].y;\n                float2 param_4 = -_1081;\n                float param_5 = _702.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1081;\n            att *= cookie_att(param_6, param_7, _702, fx_cookie_tex, light_smp);\n        }\n        if (_913)\n        {\n            _1145 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1145 = 1.0;\n        }\n        total += (_702.light_color[i].xyz * (att * _1145));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _679 = fa_srgb_to_linear(param);\n        c = _679;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1395 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1399 = uv * _1395;\n    float _1405 = _1395.x;\n    float _1407 = _1395.y;\n    float _1409 = fast::clamp(shape_rs.x, 0.0, fast::min(_1405, _1407));\n    float2 _1420 = (abs(_1399) - _1395) + float2(_1409);\n    float d = (length(fast::max(_1420, float2(0.0))) + fast::min(fast::max(_1420.x, _1420.y), 0.0)) - _1409;\n    float ax = params.y;\n    bool _1441 = params.y > 15.0;\n    if (_1441)\n    {\n        ax -= 20.0;\n    }\n    float _1452;\n    if (ax <= (-1.5))\n    {\n        _1452 = (-2.0) - ax;\n    }\n    else\n    {\n        _1452 = 0.0;\n    }\n    if (_1452 > 0.0)\n    {\n        float _1466 = _1452 * 0.5;\n        d = abs(d + _1466) - _1466;\n    }\n    float _1474 = fwidth(d);\n    float _1475 = fast::max(_1474, 9.9999997473787516355514526367188e-05);\n    float _1485 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1475)), 0.0, 1.0);\n    float _1490;\n    if (shape_rs.y > _1475)\n    {\n        _1490 = (_1485 * _1485) * (3.0 - (2.0 * _1485));\n    }\n    else\n    {\n        _1490 = _1485;\n    }\n    float4 c = color;\n    bool _1512 = (_1452 <= 0.0) && (ax > (-0.5));\n    if (_1512)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1527 = cos(ax);\n            float _1529 = sin(ax);\n            g = ((dot(_1399, float2(_1527, _1529)) / fast::max((abs(_1527) * _1405) + (abs(_1529) * _1407), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1441)\n        {\n            float4 _1572 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1572;\n            float3 param = _1572.xyz;\n            float param_1 = xform.y;\n            float3 _1579 = fa_tex_fix(param, param_1);\n            float4 _2374 = c;\n            _2374.x = _1579.x;\n            _2374.y = _1579.y;\n            _2374.z = _1579.z;\n            c = _2374;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1591 = scene_rgb(param_2, xform);\n            float4 _1616 = mix(float4(color.xyz * color.w, color.w), float4(_1591 * color2.w, color2.w), float4(g));\n            float _1618 = _1616.w;\n            float3 _1621;\n            if (_1618 > 9.9999997473787516355514526367188e-06)\n            {\n                _1621 = _1616.xyz / float3(_1618);\n            }\n            else\n            {\n                _1621 = color.xyz;\n            }\n            c = float4(_1621, _1618);\n        }\n    }\n    float4 _2383 = c;\n    _2383.w = _2383.w * _1490;\n    c = _2383;\n    if (_1512 || (shape_rs.y > 0.0))\n    {\n        float _1662 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1671 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1671 + float3(_1662 * 0.0039215688593685626983642578125);\n            float3 _1677 = fa_srgb_to_linear(param_4);\n            float4 _2386 = c;\n            _2386.x = _1677.x;\n            _2386.y = _1677.y;\n            _2386.z = _1677.z;\n            c = _2386;\n        }\n        else\n        {\n            float4 _1687 = c;\n            float3 _1690 = _1687.xyz + float3(_1662 * 0.0039215688593685626983642578125);\n            float4 _2393 = _1687;\n            _2393.x = _1690.x;\n            _2393.y = _1690.y;\n            _2393.z = _1690.z;\n            c = _2393;\n        }\n        float4 _2398 = c;\n        _2398.w = fast::clamp(_2398.w + ((_1662 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2398.w)), 0.0, 1.0);\n        c = _2398;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _702, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1182 = float2(_702.fx_rim_uv.x, 0.0);\n    float4 _1184 = tex.sample(smp, (uv - _1182));\n    float _1185 = _1184.w;\n    float4 _1195 = tex.sample(smp, (uv + _1182));\n    float _1196 = _1195.w;\n    float2 _1204 = float2(0.0, _702.fx_rim_uv.y);\n    float4 _1206 = tex.sample(smp, (uv - _1204));\n    float _1207 = _1206.w;\n    float4 _1217 = tex.sample(smp, (uv + _1204));\n    float _1218 = _1217.w;\n    float _1233 = _1185 - _1196;\n    float _1236 = _1218 - _1207;\n    float _1246 = cos(params.y);\n    float _1248 = sin(params.y);\n    float2 _1274 = ((float2(_1246, _1248) * _1233) + ((float2(-_1248, _1246) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1236)) / float2(fast::max(length(float2(_1233, _1236)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _702.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_702.light_pos[i].w < 0.0)\n        {\n            to_l = _702.light_pos[i].xy / float2(fast::max(length(_702.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1320 = _702.light_pos[i].xy - world_xy;\n            float _1323 = length(_1320);\n            att = powr(fast::clamp(1.0 - (_1323 / fast::max(_702.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _702.light_color[i].w);\n            to_l = _1320 / float2(fast::max(_1323, 9.9999997473787516355514526367188e-05));\n            if (_702.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _702.light_shadow_v[i].x;\n                float param_1 = _702.light_shadow_v[i].y;\n                float2 param_2 = -_1320;\n                float param_3 = _702.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1320;\n            att *= cookie_att(param_4, param_5, _702, fx_cookie_tex, light_smp);\n        }\n        sum += (_702.light_color[i].xyz * (att * fast::max(dot(_1274, to_l), 0.0)));\n    }\n    return (sum * _702.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1185, _1196), fast::min(_1207, _1218))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _702)\n{\n    float2 _708 = gl_FragCoord.xy * _702.fa_target.xy;\n    float _712 = _708.y;\n    return float2(_708.x, mix(_712, 1.0 - _712, _702.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _702, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _750 = base_mode < 0.5;\n    bool _761;\n    if (!_750)\n    {\n        _761 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _761 = _750;\n    }\n    float _762;\n    if (_761)\n    {\n        _762 = shape_half.x;\n    }\n    else\n    {\n        _762 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _702), _702.fa_time.x, base_mode, float4(0.0), _762 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _685 = scene_rgb(param, xform);\n    return _685;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _787)\n{\n    float3 param = tint.xyz;\n    float3 _790 = fa_scene_rgb(param, xform) * _787.boost;\n    s.color.x = _790.x;\n    s.color.y = _790.y;\n    s.color.z = _790.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _702 [[buffer(1)]], constant fa_material& _787 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1717 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1717)\n    {\n        mode -= 32.0;\n    }\n    float _1725 = mode;\n    bool _1727 = _1725 > 15.5;\n    if (_1727)\n    {\n        mode -= 16.0;\n    }\n    float _1735 = mode;\n    bool _1737 = _1735 > 7.5;\n    if (_1737)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1727)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _702, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1727)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _702, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1799 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1801 = _1799 * in.color;\n                float4 param_6 = _1801;\n                float param_7 = mode;\n                float _1808 = _1801.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _702, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1808);\n                if (_702.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1808;\n                    float param_9 = mode;\n                    float4 _1824 = out.frag_color;\n                    float3 _1826 = _1824.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _702, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1826.x;\n                    out.frag_color.y = _1826.y;\n                    out.frag_color.z = _1826.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1856 = length(in.uv);\n                    float _1859 = fwidth(_1856);\n                    float _1860 = fast::max(_1859, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1856) / _1860) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1856) / _1860) + 0.5, 0.0, 1.0) * fast::clamp(((_1856 - in.params.y) / _1860) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1900 = fast::clamp(1.0 - _1856, 0.0, 1.0);\n                            cov = (_1900 * _1900) * (3.0 - (2.0 * _1900));\n                        }\n                    }\n                    float3 _1909;\n                    if (_1727)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1909 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _702, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1909 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1909, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_702.fx_emit.w > 0.5)\n    {\n        float3 e = _702.fx_emit.xyz;\n        if (_702.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _702.fx_emit_uv.xy) + _702.fx_emit_uv.zw)).xyz;\n            float param_13 = _702.fx_emit.w - 2.0;\n            float3 _1964 = fa_tex_fix(param_12, param_13);\n            e *= _1964;\n        }\n        float4 _1968 = out.frag_color;\n        float3 _1970 = _1968.xyz + e;\n        out.frag_color.x = _1970.x;\n        out.frag_color.y = _1970.y;\n        out.frag_color.z = _1970.z;\n    }\n    float param_14 = mode;\n    float4 _2298 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _702, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2298 };\n    fragment0(param_15, param_16, in.xform, tint, _787);\n    _2298 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1717)\n    {\n        float4 _1996 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _2001 = scene_rgb(param_17, in.xform);\n        float3 _2005 = mix(_1996.xyz, _2001, float3(in.color2.w));\n        out.frag_color.x = _2005.x;\n        out.frag_color.y = _2005.y;\n        out.frag_color.z = _2005.z;\n    }\n    if (_1737)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2029 = _702.fog_col.w > 0.0;\n    bool _2037;\n    if (!_2029)\n    {\n        _2037 = _702.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2037 = _2029;\n    }\n    if (_2037)\n    {\n        float3 _2051 = float3(in.world_xy, in.world_z) - _702.fog_eye.xyz;\n        float _2058 = dot(_2051, _702.fog_c.xyz);\n        bool _2062 = _702.fog_c.w > 0.5;\n        float _2063;\n        if (_2062)\n        {\n            _2063 = _2058;\n        }\n        else\n        {\n            _2063 = length(_2051);\n        }\n        float _2075 = _2063 - _702.fog_b.x;\n        if (_2075 > 0.0)\n        {\n            float _2084 = _702.fog_col.w * _2075;\n            float tau = _2084 * _2084;\n            if (_702.fog_b.y > 0.0)\n            {\n                float _2100;\n                if (_2062)\n                {\n                    _2100 = in.world_xy.y - (_702.fog_c.y * _2058);\n                }\n                else\n                {\n                    _2100 = _702.fog_eye.y;\n                }\n                float _2121 = mix(_2100, in.world_xy.y, fast::clamp(_702.fog_b.x / _2063, 0.0, 1.0));\n                float _2125 = in.world_xy.y - _2121;\n                float _2130 = _2121 - _702.fog_b.z;\n                float _2135 = in.world_xy.y - _702.fog_b.z;\n                bool _2138 = _2130 <= 0.0;\n                bool _2139 = !_2138;\n                bool _2145;\n                if (_2139)\n                {\n                    _2145 = _702.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2145 = _2138;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = _702.fog_b.y;\n                }\n                else\n                {\n                    _2146 = _702.fog_b.y * exp(-fast::min(_702.fog_b.w * _2130, 80.0));\n                }\n                bool _2173;\n                if (_2139)\n                {\n                    _2173 = _702.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2173 = _2138;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = _702.fog_b.y * _2130;\n                }\n                else\n                {\n                    _2174 = (_702.fog_b.y * (1.0 - exp(-fast::min(_702.fog_b.w * _2130, 80.0)))) / _702.fog_b.w;\n                }\n                bool _2199 = _2135 <= 0.0;\n                bool _2206;\n                if (!_2199)\n                {\n                    _2206 = _702.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2206 = _2199;\n                }\n                float _2207;\n                if (_2206)\n                {\n                    _2207 = _702.fog_b.y * _2135;\n                }\n                else\n                {\n                    _2207 = (_702.fog_b.y * (1.0 - exp(-fast::min(_702.fog_b.w * _2135, 80.0)))) / _702.fog_b.w;\n                }\n                float _2234;\n                if (abs(_2125) < 0.001000000047497451305389404296875)\n                {\n                    _2234 = _2146;\n                }\n                else\n                {\n                    _2234 = (_2207 - _2174) / _2125;\n                }\n                tau += (_2075 * fast::max(_2234, 0.0));\n            }\n            float4 _2257 = out.frag_color;\n            float3 _2265 = mix(_2257.xyz, _702.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2265.x;\n            out.frag_color.y = _2265.y;\n            out.frag_color.z = _2265.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_702",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_787",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _164)\n{\n    float2 _171 = gl_FragCoord.xy * _164.fa_target.xy;\n    float _176 = _171.y;\n    return float2(_171.x, mix(_176, 1.0 - _176, _164.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _164, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _219 = base_mode < 0.5;\n    bool _230;\n    if (!_219)\n    {\n        _230 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _230 = _219;\n    }\n    float _231;\n    if (_230)\n    {\n        _231 = shape_half.x;\n    }\n    else\n    {\n        _231 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _164), _164.fa_time.x, base_mode, float4(0.0), _231 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param, xform);\n    return _145;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _256)\n{\n    float3 param = tint.xyz;\n    float3 _259 = fa_scene_rgb(param, xform) * _256.boost;\n    s.color.x = _259.x;\n    s.color.y = _259.y;\n    s.color.z = _259.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _164 [[buffer(1)]], constant fa_material& _256 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _286 = tex.sample(smp, in.uv);\n    float3 param = _286.xyz;\n    float param_1 = in.xform.y;\n    float3 _295 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_295, _286.w) * in.color;\n    float param_2 = 0.0;\n    float4 _350 = out.frag_color;\n    float shift;\n    float4 tint;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _164, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _350 };\n    fragment0(param_3, param_4, in.xform, tint, _256);\n    _350 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_164",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_256",
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
