{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _513 = fa_linear_to_srgb(param);\n        c = _513;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _521 = fa_srgb_to_linear(param_1);\n            c = _521;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _532 = tex.sample(smp, p);\n    float3 param = _532.xyz;\n    float param_1 = xform.y;\n    float3 _542 = fa_tex_fix(param, param_1);\n    return float4(_542, _532.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _118 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_118.x * 255.0) + 0.5) * 256.0) + floor((_118.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _221 = floor(tt);\n    float _231 = _221 - (1024.0 * floor(_221 * 0.0009765625));\n    float _234 = _231 + 1.0;\n    float i1 = _234;\n    if (_234 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _231;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _221);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _271 = length(d);\n    float result = 1.0;\n    if (_271 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _282 = precise::atan2(d.y, d.x);\n        float a = _282;\n        float _285;\n        if (_282 < 0.0)\n        {\n            _285 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _285 = a;\n        }\n        a = _285;\n        float _295 = _285 * 162.9746551513671875;\n        float _304 = fast::min((size * 10.0) / _271, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _332 = floor(_295 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _304));\n            float param = v;\n            float param_1 = _332 - (1024.0 * floor(_332 * 0.0009765625));\n            float _346 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_346 < _271)\n            {\n                sum += _346;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _378 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _271)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _396 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _402 = 1.0 - (0.800000011920928955078125 * abs(_396));\n                float param_2 = v;\n                float param_3 = _295 + (_396 * _378);\n                float param_4 = _271;\n                float param_5 = radius;\n                acc += (_402 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _402;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _142 = length(d);\n    if (_142 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _156 = precise::atan2(d.y, d.x);\n    float a = _156;\n    float _159;\n    if (_156 < 0.0)\n    {\n        _159 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _159 = a;\n    }\n    a = _159;\n    float _171 = _159 * 162.9746551513671875;\n    float _176 = fast::min(floor(_171), 1023.0);\n    float _183 = _176 + 1.0;\n    float i1 = _183;\n    if (_183 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _176;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _142) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _142) + 0.5, 0.0, 1.0), _171 - _176);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _579, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _689 = _579.lit.y > 0.5;\n    if (_689)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _579.normal_uv.xy) + _579.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _713 = fa_tex_fix(param, param_1);\n        float3 _717 = (_713 * 2.0) - float3(1.0);\n        float _724 = cos(params.y);\n        float _726 = sin(params.y);\n        n = fast::normalize(float3((float2(_724, _726) * _717.x) + ((float2(-_726, _724) * ((mode > 5.5) ? (-1.0) : 1.0)) * _717.y), fast::max(_717.z, 0.0500000007450580596923828125)));\n    }\n    bool _760 = !_689;\n    bool _766;\n    if (_760)\n    {\n        _766 = _579.lit.z > 0.5;\n    }\n    else\n    {\n        _766 = _760;\n    }\n    float3 _769;\n    if (_766)\n    {\n        _769 = _579.flat_ambient.xyz;\n    }\n    else\n    {\n        _769 = _579.ambient.xyz;\n    }\n    float3 total = _769;\n    bool _786;\n    if (_766)\n    {\n        _786 = _579.lit.z < 1.5;\n    }\n    else\n    {\n        _786 = _766;\n    }\n    if (_786)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _579.light_map.xy), level(0.0)).xyz * _579.light_map.z);\n    }\n    float3 l;\n    float _906;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _824;\n        if (!_766)\n        {\n            _824 = float(i) >= _579.lit.x;\n        }\n        else\n        {\n            _824 = _766;\n        }\n        if (_824)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_579.light_pos[i].w < 0.0)\n        {\n            l = _579.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _850 = _579.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_850) / fast::max(_579.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _579.light_color[i].w);\n            float3 _870 = float3(_850, _579.light_pos[i].z);\n            l = _870 / float3(fast::max(length(_870), 9.9999997473787516355514526367188e-05));\n            if (_579.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _579.light_shadow_v[i].x;\n                float param_3 = _579.light_shadow_v[i].y;\n                float2 param_4 = -_850;\n                float param_5 = _579.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n        }\n        if (_689)\n        {\n            _906 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _906 = 1.0;\n        }\n        total += (_579.light_color[i].xyz * (att * _906));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _559 = fa_srgb_to_linear(param);\n        c = _559;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _934 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _938 = uv * _934;\n    float _944 = _934.x;\n    float _946 = _934.y;\n    float _948 = fast::clamp(shape_rs.x, 0.0, fast::min(_944, _946));\n    float2 _959 = (abs(_938) - _934) + float2(_948);\n    float d = (length(fast::max(_959, float2(0.0))) + fast::min(fast::max(_959.x, _959.y), 0.0)) - _948;\n    float ax = params.y;\n    bool _980 = params.y > 15.0;\n    if (_980)\n    {\n        ax -= 20.0;\n    }\n    float _991;\n    if (ax <= (-1.5))\n    {\n        _991 = (-2.0) - ax;\n    }\n    else\n    {\n        _991 = 0.0;\n    }\n    if (_991 > 0.0)\n    {\n        float _1005 = _991 * 0.5;\n        d = abs(d + _1005) - _1005;\n    }\n    float _1013 = fwidth(d);\n    float _1014 = fast::max(_1013, 9.9999997473787516355514526367188e-05);\n    float _1024 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1014)), 0.0, 1.0);\n    float _1029;\n    if (shape_rs.y > _1014)\n    {\n        _1029 = (_1024 * _1024) * (3.0 - (2.0 * _1024));\n    }\n    else\n    {\n        _1029 = _1024;\n    }\n    float4 c = color;\n    bool _1051 = (_991 <= 0.0) && (ax > (-0.5));\n    if (_1051)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1066 = cos(ax);\n            float _1068 = sin(ax);\n            g = ((dot(_938, float2(_1066, _1068)) / fast::max((abs(_1066) * _944) + (abs(_1068) * _946), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_980)\n        {\n            float4 _1111 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1111;\n            float3 param = _1111.xyz;\n            float param_1 = xform.y;\n            float3 _1118 = fa_tex_fix(param, param_1);\n            float4 _1814 = c;\n            _1814.x = _1118.x;\n            _1814.y = _1118.y;\n            _1814.z = _1118.z;\n            c = _1814;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1130 = scene_rgb(param_2, xform);\n            float4 _1155 = mix(float4(color.xyz * color.w, color.w), float4(_1130 * color2.w, color2.w), float4(g));\n            float _1157 = _1155.w;\n            float3 _1160;\n            if (_1157 > 9.9999997473787516355514526367188e-06)\n            {\n                _1160 = _1155.xyz / float3(_1157);\n            }\n            else\n            {\n                _1160 = color.xyz;\n            }\n            c = float4(_1160, _1157);\n        }\n    }\n    float4 _1823 = c;\n    _1823.w = _1823.w * _1029;\n    c = _1823;\n    if (_1051 || (shape_rs.y > 0.0))\n    {\n        float _1201 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1210 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1210 + float3(_1201 * 0.0039215688593685626983642578125);\n            float3 _1216 = fa_srgb_to_linear(param_4);\n            float4 _1826 = c;\n            _1826.x = _1216.x;\n            _1826.y = _1216.y;\n            _1826.z = _1216.z;\n            c = _1826;\n        }\n        else\n        {\n            float4 _1226 = c;\n            float3 _1229 = _1226.xyz + float3(_1201 * 0.0039215688593685626983642578125);\n            float4 _1833 = _1226;\n            _1833.x = _1229.x;\n            _1833.y = _1229.y;\n            _1833.z = _1229.z;\n            c = _1833;\n        }\n        float4 _1838 = c;\n        _1838.w = fast::clamp(_1838.w + ((_1201 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1838.w)), 0.0, 1.0);\n        c = _1838;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _579)\n{\n    float2 _585 = gl_FragCoord.xy * _579.fa_target.xy;\n    float _589 = _585.y;\n    return float2(_585.x, mix(_589, 1.0 - _589, _579.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _579, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _628 = base_mode < 0.5;\n    bool _639;\n    if (!_628)\n    {\n        _639 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _639 = _628;\n    }\n    float _640;\n    if (_639)\n    {\n        _640 = shape_half.x;\n    }\n    else\n    {\n        _640 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _579), _579.fa_time.x, base_mode, float4(0.0), _640 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _565 = scene_rgb(param, xform);\n    return _565;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _665)\n{\n    float3 param = tint.xyz;\n    float3 _668 = fa_scene_rgb(param, xform) * _665.boost;\n    s.color.x = _668.x;\n    s.color.y = _668.y;\n    s.color.z = _668.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _579 [[buffer(1)]], constant fa_material& _665 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1256 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1256)\n    {\n        mode -= 32.0;\n    }\n    float _1264 = mode;\n    bool _1266 = _1264 > 15.5;\n    if (_1266)\n    {\n        mode -= 16.0;\n    }\n    float _1274 = mode;\n    bool _1276 = _1274 > 7.5;\n    if (_1276)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1266)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _579, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1266)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _579, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1340 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1340;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _579, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1340.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1375 = length(in.uv);\n                    float _1378 = fwidth(_1375);\n                    float _1379 = fast::max(_1378, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1375) / _1379) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1375) / _1379) + 0.5, 0.0, 1.0) * fast::clamp(((_1375 - in.params.y) / _1379) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1419 = fast::clamp(1.0 - _1375, 0.0, 1.0);\n                            cov = (_1419 * _1419) * (3.0 - (2.0 * _1419));\n                        }\n                    }\n                    float3 _1428;\n                    if (_1266)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1428 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _579, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1428 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1428, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1767 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _579, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1767 };\n    fragment0(param_11, param_12, in.xform, tint, _665);\n    _1767 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1256)\n    {\n        float4 _1466 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1471 = scene_rgb(param_13, in.xform);\n        float3 _1475 = mix(_1466.xyz, _1471, float3(in.color2.w));\n        out.frag_color.x = _1475.x;\n        out.frag_color.y = _1475.y;\n        out.frag_color.z = _1475.z;\n    }\n    if (_1276)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1499 = _579.fog_col.w > 0.0;\n    bool _1507;\n    if (!_1499)\n    {\n        _1507 = _579.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1507 = _1499;\n    }\n    if (_1507)\n    {\n        float3 _1521 = float3(in.world_xy, in.world_z) - _579.fog_eye.xyz;\n        float _1528 = dot(_1521, _579.fog_c.xyz);\n        bool _1532 = _579.fog_c.w > 0.5;\n        float _1533;\n        if (_1532)\n        {\n            _1533 = _1528;\n        }\n        else\n        {\n            _1533 = length(_1521);\n        }\n        float _1545 = _1533 - _579.fog_b.x;\n        if (_1545 > 0.0)\n        {\n            float _1554 = _579.fog_col.w * _1545;\n            float tau = _1554 * _1554;\n            if (_579.fog_b.y > 0.0)\n            {\n                float _1570;\n                if (_1532)\n                {\n                    _1570 = in.world_xy.y - (_579.fog_c.y * _1528);\n                }\n                else\n                {\n                    _1570 = _579.fog_eye.y;\n                }\n                float _1591 = mix(_1570, in.world_xy.y, fast::clamp(_579.fog_b.x / _1533, 0.0, 1.0));\n                float _1595 = in.world_xy.y - _1591;\n                float _1600 = _1591 - _579.fog_b.z;\n                float _1605 = in.world_xy.y - _579.fog_b.z;\n                bool _1608 = _1600 <= 0.0;\n                bool _1609 = !_1608;\n                bool _1615;\n                if (_1609)\n                {\n                    _1615 = _579.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1615 = _1608;\n                }\n                float _1616;\n                if (_1615)\n                {\n                    _1616 = _579.fog_b.y;\n                }\n                else\n                {\n                    _1616 = _579.fog_b.y * exp(-fast::min(_579.fog_b.w * _1600, 80.0));\n                }\n                bool _1643;\n                if (_1609)\n                {\n                    _1643 = _579.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1643 = _1608;\n                }\n                float _1644;\n                if (_1643)\n                {\n                    _1644 = _579.fog_b.y * _1600;\n                }\n                else\n                {\n                    _1644 = (_579.fog_b.y * (1.0 - exp(-fast::min(_579.fog_b.w * _1600, 80.0)))) / _579.fog_b.w;\n                }\n                bool _1669 = _1605 <= 0.0;\n                bool _1676;\n                if (!_1669)\n                {\n                    _1676 = _579.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1676 = _1669;\n                }\n                float _1677;\n                if (_1676)\n                {\n                    _1677 = _579.fog_b.y * _1605;\n                }\n                else\n                {\n                    _1677 = (_579.fog_b.y * (1.0 - exp(-fast::min(_579.fog_b.w * _1605, 80.0)))) / _579.fog_b.w;\n                }\n                float _1704;\n                if (abs(_1595) < 0.001000000047497451305389404296875)\n                {\n                    _1704 = _1616;\n                }\n                else\n                {\n                    _1704 = (_1677 - _1644) / _1595;\n                }\n                tau += (_1545 * fast::max(_1704, 0.0));\n            }\n            float4 _1727 = out.frag_color;\n            float3 _1735 = mix(_1727.xyz, _579.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1735.x;\n            out.frag_color.y = _1735.y;\n            out.frag_color.z = _1735.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_579",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_665",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _160)\n{\n    float2 _167 = gl_FragCoord.xy * _160.fa_target.xy;\n    float _172 = _167.y;\n    return float2(_167.x, mix(_172, 1.0 - _172, _160.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _160, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _215 = base_mode < 0.5;\n    bool _226;\n    if (!_215)\n    {\n        _226 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _226 = _215;\n    }\n    float _227;\n    if (_226)\n    {\n        _227 = shape_half.x;\n    }\n    else\n    {\n        _227 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _160), _160.fa_time.x, base_mode, float4(0.0), _227 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param, xform);\n    return _145;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _252)\n{\n    float3 param = tint.xyz;\n    float3 _255 = fa_scene_rgb(param, xform) * _252.boost;\n    s.color.x = _255.x;\n    s.color.y = _255.y;\n    s.color.z = _255.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _160 [[buffer(1)]], constant fa_material& _252 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _282 = tex.sample(smp, in.uv);\n    float3 param = _282.xyz;\n    float param_1 = in.xform.y;\n    float3 _291 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_291, _282.w) * in.color;\n    float param_2 = 0.0;\n    float4 _345 = out.frag_color;\n    float shift;\n    float4 tint;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _160, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _345 };\n    fragment0(param_3, param_4, in.xform, tint, _252);\n    _345 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_160",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_252",
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
