{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _634 = fa_linear_to_srgb(param);\n        c = _634;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _642 = fa_srgb_to_linear(param_1);\n            c = _642;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _653 = tex.sample(smp, p);\n    float3 param = _653.xyz;\n    float param_1 = xform.y;\n    float3 _663 = fa_tex_fix(param, param_1);\n    return float4(_663, _653.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _701, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _851 = (world_xy * _701.gi_xf.xy) + _701.gi_xf.zw;\n    float4 _858 = fx_gi_tex.sample(light_smp, _851, level(0.0));\n    float _862 = _851.x;\n    bool _863 = _862 >= 0.0;\n    bool _869;\n    if (_863)\n    {\n        _869 = _851.y >= 0.0;\n    }\n    else\n    {\n        _869 = _863;\n    }\n    bool _875;\n    if (_869)\n    {\n        _875 = _862 <= 1.0;\n    }\n    else\n    {\n        _875 = _869;\n    }\n    bool _881;\n    if (_875)\n    {\n        _881 = _851.y <= 1.0;\n    }\n    else\n    {\n        _881 = _875;\n    }\n    bool _889;\n    if (_881)\n    {\n        _889 = _858.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _889 = _881;\n    }\n    float3 _890;\n    if (_889)\n    {\n        _890 = (_858.xyz / float3(_858.w)) * _701.gi_p.x;\n    }\n    else\n    {\n        _890 = float3(0.0);\n    }\n    return _890;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _143 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_143.x * 255.0) + 0.5) * 256.0) + floor((_143.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _246 = floor(tt);\n    float _256 = _246 - (1024.0 * floor(_246 * 0.0009765625));\n    float _259 = _256 + 1.0;\n    float i1 = _259;\n    if (_259 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _256;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _246);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _296 = length(d);\n    float result = 1.0;\n    if (_296 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _307 = precise::atan2(d.y, d.x);\n        float a = _307;\n        float _310;\n        if (_307 < 0.0)\n        {\n            _310 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _310 = a;\n        }\n        a = _310;\n        float _320 = _310 * 162.9746551513671875;\n        float _329 = fast::min((size * 10.0) / _296, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _355 = floor(_320 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _329));\n            float param = v;\n            float param_1 = _355 - (1024.0 * floor(_355 * 0.0009765625));\n            float _369 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_369 < _296)\n            {\n                sum += _369;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _401 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _296)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _419 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _425 = 1.0 - (0.800000011920928955078125 * abs(_419));\n                float param_2 = v;\n                float param_3 = _320 + (_419 * _401);\n                float param_4 = _296;\n                float param_5 = radius;\n                acc += (_425 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _425;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _167 = length(d);\n    if (_167 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _181 = precise::atan2(d.y, d.x);\n    float a = _181;\n    float _184;\n    if (_181 < 0.0)\n    {\n        _184 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _184 = a;\n    }\n    a = _184;\n    float _196 = _184 * 162.9746551513671875;\n    float _201 = fast::min(floor(_196), 1023.0);\n    float _208 = _201 + 1.0;\n    float i1 = _208;\n    if (_208 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _201;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _167) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _167) + 0.5, 0.0, 1.0), _196 - _201);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _506 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _510 = _506.x + 0.5;\n    float2 c = float2(_510, 0.5 - _506.y);\n    bool _518 = _510 >= 0.0;\n    bool _524;\n    if (_518)\n    {\n        _524 = c.x <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y >= 0.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    bool _536;\n    if (_530)\n    {\n        _536 = c.y <= 1.0;\n    }\n    else\n    {\n        _536 = _530;\n    }\n    float2 _538 = c;\n    float2 _543 = fast::clamp(_538, float2(0.001953125), float2(0.998046875));\n    c = _543;\n    return float3(cell.x + (_543.x * cell.w), cell.y + (_543.y * cell.z), float(_536));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _701, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_701.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _701.light_cookie[i];\n    float4 param_1 = _701.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _825 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _825.xy, level(0.0));\n    return cookie_value(param_3) * _825.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _701, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _912 = _701.lit.y > 0.5;\n    if (_912)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _701.normal_uv.xy) + _701.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _936 = fa_tex_fix(param, param_1);\n        float3 _940 = (_936 * 2.0) - float3(1.0);\n        float _947 = cos(params.y);\n        float _949 = sin(params.y);\n        n = fast::normalize(float3((float2(_947, _949) * _940.x) + ((float2(-_949, _947) * ((mode > 5.5) ? (-1.0) : 1.0)) * _940.y), fast::max(_940.z, 0.0500000007450580596923828125)));\n    }\n    bool _983 = !_912;\n    bool _989;\n    if (_983)\n    {\n        _989 = _701.lit.z > 0.5;\n    }\n    else\n    {\n        _989 = _983;\n    }\n    float3 _992;\n    if (_989)\n    {\n        _992 = _701.flat_ambient.xyz;\n    }\n    else\n    {\n        _992 = _701.ambient.xyz;\n    }\n    float3 total = _992;\n    if (_701.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_701, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _1017;\n    if (_989)\n    {\n        _1017 = _701.lit.z < 1.5;\n    }\n    else\n    {\n        _1017 = _989;\n    }\n    if (_1017)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _701.light_map.xy), level(0.0)).xyz * _701.light_map.z);\n    }\n    float3 l;\n    float _1144;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1054;\n        if (!_989)\n        {\n            _1054 = float(i) >= _701.lit.x;\n        }\n        else\n        {\n            _1054 = _989;\n        }\n        if (_1054)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_701.light_pos[i].w < 0.0)\n        {\n            l = _701.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1080 = _701.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1080) / fast::max(_701.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _701.light_color[i].w);\n            float3 _1100 = float3(_1080, _701.light_pos[i].z);\n            l = _1100 / float3(fast::max(length(_1100), 9.9999997473787516355514526367188e-05));\n            if (_701.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _701.light_shadow_v[i].x;\n                float param_3 = _701.light_shadow_v[i].y;\n                float2 param_4 = -_1080;\n                float param_5 = _701.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1080;\n            att *= cookie_att(param_6, param_7, _701, fx_cookie_tex, light_smp);\n        }\n        if (_912)\n        {\n            _1144 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1144 = 1.0;\n        }\n        total += (_701.light_color[i].xyz * (att * _1144));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _679 = fa_srgb_to_linear(param);\n        c = _679;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1394 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1398 = uv * _1394;\n    float _1404 = _1394.x;\n    float _1406 = _1394.y;\n    float _1408 = fast::clamp(shape_rs.x, 0.0, fast::min(_1404, _1406));\n    float2 _1419 = (abs(_1398) - _1394) + float2(_1408);\n    float d = (length(fast::max(_1419, float2(0.0))) + fast::min(fast::max(_1419.x, _1419.y), 0.0)) - _1408;\n    float ax = params.y;\n    bool _1440 = params.y > 15.0;\n    if (_1440)\n    {\n        ax -= 20.0;\n    }\n    float _1451;\n    if (ax <= (-1.5))\n    {\n        _1451 = (-2.0) - ax;\n    }\n    else\n    {\n        _1451 = 0.0;\n    }\n    if (_1451 > 0.0)\n    {\n        float _1465 = _1451 * 0.5;\n        d = abs(d + _1465) - _1465;\n    }\n    float _1473 = fwidth(d);\n    float _1474 = fast::max(_1473, 9.9999997473787516355514526367188e-05);\n    float _1484 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1474)), 0.0, 1.0);\n    float _1489;\n    if (shape_rs.y > _1474)\n    {\n        _1489 = (_1484 * _1484) * (3.0 - (2.0 * _1484));\n    }\n    else\n    {\n        _1489 = _1484;\n    }\n    float4 c = color;\n    bool _1511 = (_1451 <= 0.0) && (ax > (-0.5));\n    if (_1511)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1526 = cos(ax);\n            float _1528 = sin(ax);\n            g = ((dot(_1398, float2(_1526, _1528)) / fast::max((abs(_1526) * _1404) + (abs(_1528) * _1406), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1440)\n        {\n            float4 _1571 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1571;\n            float3 param = _1571.xyz;\n            float param_1 = xform.y;\n            float3 _1578 = fa_tex_fix(param, param_1);\n            float4 _2372 = c;\n            _2372.x = _1578.x;\n            _2372.y = _1578.y;\n            _2372.z = _1578.z;\n            c = _2372;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1590 = scene_rgb(param_2, xform);\n            float4 _1615 = mix(float4(color.xyz * color.w, color.w), float4(_1590 * color2.w, color2.w), float4(g));\n            float _1617 = _1615.w;\n            float3 _1620;\n            if (_1617 > 9.9999997473787516355514526367188e-06)\n            {\n                _1620 = _1615.xyz / float3(_1617);\n            }\n            else\n            {\n                _1620 = color.xyz;\n            }\n            c = float4(_1620, _1617);\n        }\n    }\n    float4 _2381 = c;\n    _2381.w = _2381.w * _1489;\n    c = _2381;\n    if (_1511 || (shape_rs.y > 0.0))\n    {\n        float _1661 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1670 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1670 + float3(_1661 * 0.0039215688593685626983642578125);\n            float3 _1676 = fa_srgb_to_linear(param_4);\n            float4 _2384 = c;\n            _2384.x = _1676.x;\n            _2384.y = _1676.y;\n            _2384.z = _1676.z;\n            c = _2384;\n        }\n        else\n        {\n            float4 _1686 = c;\n            float3 _1689 = _1686.xyz + float3(_1661 * 0.0039215688593685626983642578125);\n            float4 _2391 = _1686;\n            _2391.x = _1689.x;\n            _2391.y = _1689.y;\n            _2391.z = _1689.z;\n            c = _2391;\n        }\n        float4 _2396 = c;\n        _2396.w = fast::clamp(_2396.w + ((_1661 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2396.w)), 0.0, 1.0);\n        c = _2396;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _701, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1181 = float2(_701.fx_rim_uv.x, 0.0);\n    float4 _1183 = tex.sample(smp, (uv - _1181));\n    float _1184 = _1183.w;\n    float4 _1194 = tex.sample(smp, (uv + _1181));\n    float _1195 = _1194.w;\n    float2 _1203 = float2(0.0, _701.fx_rim_uv.y);\n    float4 _1205 = tex.sample(smp, (uv - _1203));\n    float _1206 = _1205.w;\n    float4 _1216 = tex.sample(smp, (uv + _1203));\n    float _1217 = _1216.w;\n    float _1232 = _1184 - _1195;\n    float _1235 = _1217 - _1206;\n    float _1245 = cos(params.y);\n    float _1247 = sin(params.y);\n    float2 _1273 = ((float2(_1245, _1247) * _1232) + ((float2(-_1247, _1245) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1235)) / float2(fast::max(length(float2(_1232, _1235)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _701.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_701.light_pos[i].w < 0.0)\n        {\n            to_l = _701.light_pos[i].xy / float2(fast::max(length(_701.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1319 = _701.light_pos[i].xy - world_xy;\n            float _1322 = length(_1319);\n            att = powr(fast::clamp(1.0 - (_1322 / fast::max(_701.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _701.light_color[i].w);\n            to_l = _1319 / float2(fast::max(_1322, 9.9999997473787516355514526367188e-05));\n            if (_701.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _701.light_shadow_v[i].x;\n                float param_1 = _701.light_shadow_v[i].y;\n                float2 param_2 = -_1319;\n                float param_3 = _701.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1319;\n            att *= cookie_att(param_4, param_5, _701, fx_cookie_tex, light_smp);\n        }\n        sum += (_701.light_color[i].xyz * (att * fast::max(dot(_1273, to_l), 0.0)));\n    }\n    return (sum * _701.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1184, _1195), fast::min(_1206, _1217))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _701)\n{\n    float2 _707 = gl_FragCoord.xy * _701.fa_target.xy;\n    float _711 = _707.y;\n    return float2(_707.x, mix(_711, 1.0 - _711, _701.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _701, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _749 = base_mode < 0.5;\n    bool _760;\n    if (!_749)\n    {\n        _760 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _760 = _749;\n    }\n    float _761;\n    if (_760)\n    {\n        _761 = shape_half.x;\n    }\n    else\n    {\n        _761 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _701), _701.fa_time.x, base_mode, float4(0.0), _761 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _685 = scene_rgb(param, xform);\n    return _685;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _786)\n{\n    float3 param = tint.xyz;\n    float3 _789 = fa_scene_rgb(param, xform) * _786.boost;\n    s.color.x = _789.x;\n    s.color.y = _789.y;\n    s.color.z = _789.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _701 [[buffer(1)]], constant fa_material& _786 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1716 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1716)\n    {\n        mode -= 32.0;\n    }\n    float _1724 = mode;\n    bool _1726 = _1724 > 15.5;\n    if (_1726)\n    {\n        mode -= 16.0;\n    }\n    float _1734 = mode;\n    bool _1736 = _1734 > 7.5;\n    if (_1736)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1726)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _701, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1726)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _701, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1798 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1800 = _1798 * in.color;\n                float4 param_6 = _1800;\n                float param_7 = mode;\n                float _1807 = _1800.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _701, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1807);\n                if (_701.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1807;\n                    float param_9 = mode;\n                    float4 _1823 = out.frag_color;\n                    float3 _1825 = _1823.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _701, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1825.x;\n                    out.frag_color.y = _1825.y;\n                    out.frag_color.z = _1825.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1855 = length(in.uv);\n                    float _1858 = fwidth(_1855);\n                    float _1859 = fast::max(_1858, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1855) / _1859) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1855) / _1859) + 0.5, 0.0, 1.0) * fast::clamp(((_1855 - in.params.y) / _1859) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1899 = fast::clamp(1.0 - _1855, 0.0, 1.0);\n                            cov = (_1899 * _1899) * (3.0 - (2.0 * _1899));\n                        }\n                    }\n                    float3 _1908;\n                    if (_1726)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1908 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _701, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1908 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1908, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_701.fx_emit.w > 0.5)\n    {\n        float3 e = _701.fx_emit.xyz;\n        if (_701.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _701.fx_emit_uv.xy) + _701.fx_emit_uv.zw)).xyz;\n            float param_13 = _701.fx_emit.w - 2.0;\n            float3 _1963 = fa_tex_fix(param_12, param_13);\n            e *= _1963;\n        }\n        float4 _1967 = out.frag_color;\n        float3 _1969 = _1967.xyz + e;\n        out.frag_color.x = _1969.x;\n        out.frag_color.y = _1969.y;\n        out.frag_color.z = _1969.z;\n    }\n    float param_14 = mode;\n    float4 _2296 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _701, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2296 };\n    fragment0(param_15, param_16, in.xform, tint, _786);\n    _2296 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1716)\n    {\n        float4 _1995 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _2000 = scene_rgb(param_17, in.xform);\n        float3 _2004 = mix(_1995.xyz, _2000, float3(in.color2.w));\n        out.frag_color.x = _2004.x;\n        out.frag_color.y = _2004.y;\n        out.frag_color.z = _2004.z;\n    }\n    if (_1736)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2028 = _701.fog_col.w > 0.0;\n    bool _2036;\n    if (!_2028)\n    {\n        _2036 = _701.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2036 = _2028;\n    }\n    if (_2036)\n    {\n        float3 _2050 = float3(in.world_xy, in.world_z) - _701.fog_eye.xyz;\n        float _2057 = dot(_2050, _701.fog_c.xyz);\n        bool _2061 = _701.fog_c.w > 0.5;\n        float _2062;\n        if (_2061)\n        {\n            _2062 = _2057;\n        }\n        else\n        {\n            _2062 = length(_2050);\n        }\n        float _2074 = _2062 - _701.fog_b.x;\n        if (_2074 > 0.0)\n        {\n            float _2083 = _701.fog_col.w * _2074;\n            float tau = _2083 * _2083;\n            if (_701.fog_b.y > 0.0)\n            {\n                float _2099;\n                if (_2061)\n                {\n                    _2099 = in.world_xy.y - (_701.fog_c.y * _2057);\n                }\n                else\n                {\n                    _2099 = _701.fog_eye.y;\n                }\n                float _2120 = mix(_2099, in.world_xy.y, fast::clamp(_701.fog_b.x / _2062, 0.0, 1.0));\n                float _2124 = in.world_xy.y - _2120;\n                float _2129 = _2120 - _701.fog_b.z;\n                float _2134 = in.world_xy.y - _701.fog_b.z;\n                bool _2137 = _2129 <= 0.0;\n                bool _2138 = !_2137;\n                bool _2144;\n                if (_2138)\n                {\n                    _2144 = _701.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2144 = _2137;\n                }\n                float _2145;\n                if (_2144)\n                {\n                    _2145 = _701.fog_b.y;\n                }\n                else\n                {\n                    _2145 = _701.fog_b.y * exp(-fast::min(_701.fog_b.w * _2129, 80.0));\n                }\n                bool _2172;\n                if (_2138)\n                {\n                    _2172 = _701.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2172 = _2137;\n                }\n                float _2173;\n                if (_2172)\n                {\n                    _2173 = _701.fog_b.y * _2129;\n                }\n                else\n                {\n                    _2173 = (_701.fog_b.y * (1.0 - exp(-fast::min(_701.fog_b.w * _2129, 80.0)))) / _701.fog_b.w;\n                }\n                bool _2198 = _2134 <= 0.0;\n                bool _2205;\n                if (!_2198)\n                {\n                    _2205 = _701.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2205 = _2198;\n                }\n                float _2206;\n                if (_2205)\n                {\n                    _2206 = _701.fog_b.y * _2134;\n                }\n                else\n                {\n                    _2206 = (_701.fog_b.y * (1.0 - exp(-fast::min(_701.fog_b.w * _2134, 80.0)))) / _701.fog_b.w;\n                }\n                float _2233;\n                if (abs(_2124) < 0.001000000047497451305389404296875)\n                {\n                    _2233 = _2145;\n                }\n                else\n                {\n                    _2233 = (_2206 - _2173) / _2124;\n                }\n                tau += (_2074 * fast::max(_2233, 0.0));\n            }\n            float4 _2256 = out.frag_color;\n            float3 _2264 = mix(_2256.xyz, _701.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2264.x;\n            out.frag_color.y = _2264.y;\n            out.frag_color.z = _2264.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_701",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_786",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _162)\n{\n    float2 _169 = gl_FragCoord.xy * _162.fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, mix(_174, 1.0 - _174, _162.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _162, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _162), _162.fa_time.x, base_mode, float4(0.0), _229 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param, xform);\n    return _145;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _254)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param, xform) * _254.boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _162 [[buffer(1)]], constant fa_material& _254 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _284 = tex.sample(smp, in.uv);\n    float3 param = _284.xyz;\n    float param_1 = in.xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_293, _284.w) * in.color;\n    float param_2 = 0.0;\n    float4 _347 = out.frag_color;\n    float shift;\n    float4 tint;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _162, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _347 };\n    fragment0(param_3, param_4, in.xform, tint, _254);\n    _347 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1552,
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
