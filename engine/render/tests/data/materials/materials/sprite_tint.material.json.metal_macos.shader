{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "e7ae2aae15992ecb78a26a34b353f3d952e8e65744815e598b5d319af1a2ba44",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _269 = tex.sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _92 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = precise::atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = fast::min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _316, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _417 = _316.lit.y > 0.5;\n    if (_417)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _316.normal_uv.xy) + _316.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _441 = fa_tex_fix(param, param_1);\n        float3 _445 = (_441 * 2.0) - float3(1.0);\n        float _452 = cos(params.y);\n        float _454 = sin(params.y);\n        n = fast::normalize(float3((float2(_452, _454) * _445.x) + ((float2(-_454, _452) * ((mode > 5.5) ? (-1.0) : 1.0)) * _445.y), fast::max(_445.z, 0.0500000007450580596923828125)));\n    }\n    bool _488 = !_417;\n    bool _494;\n    if (_488)\n    {\n        _494 = _316.lit.z > 0.5;\n    }\n    else\n    {\n        _494 = _488;\n    }\n    float3 _497;\n    if (_494)\n    {\n        _497 = _316.flat_ambient.xyz;\n    }\n    else\n    {\n        _497 = _316.ambient.xyz;\n    }\n    float3 total = _497;\n    bool _514;\n    if (_494)\n    {\n        _514 = _316.lit.z < 1.5;\n    }\n    else\n    {\n        _514 = _494;\n    }\n    if (_514)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _316.light_map.xy), level(0.0)).xyz * _316.light_map.z);\n    }\n    float3 l;\n    float _632;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _554;\n        if (!_494)\n        {\n            _554 = float(i) >= _316.lit.x;\n        }\n        else\n        {\n            _554 = _494;\n        }\n        if (_554)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_316.light_pos[i].w < 0.0)\n        {\n            l = _316.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _580 = _316.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_580) / fast::max(_316.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _316.light_color[i].w);\n            float3 _600 = float3(_580, _316.light_pos[i].z);\n            l = _600 / float3(fast::max(length(_600), 9.9999997473787516355514526367188e-05));\n            if (_316.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _316.light_shadow_v[i].x;\n                float2 param_3 = -_580;\n                float param_4 = _316.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_417)\n        {\n            _632 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _632 = 1.0;\n        }\n        total += (_316.light_color[i].xyz * (att * _632));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _660 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _664 = uv * _660;\n    float _670 = _660.x;\n    float _672 = _660.y;\n    float _674 = fast::clamp(shape_rs.x, 0.0, fast::min(_670, _672));\n    float2 _685 = (abs(_664) - _660) + float2(_674);\n    float d = (length(fast::max(_685, float2(0.0))) + fast::min(fast::max(_685.x, _685.y), 0.0)) - _674;\n    float ax = params.y;\n    bool _706 = params.y > 15.0;\n    if (_706)\n    {\n        ax -= 20.0;\n    }\n    float _717;\n    if (ax <= (-1.5))\n    {\n        _717 = (-2.0) - ax;\n    }\n    else\n    {\n        _717 = 0.0;\n    }\n    if (_717 > 0.0)\n    {\n        float _731 = _717 * 0.5;\n        d = abs(d + _731) - _731;\n    }\n    float _739 = fwidth(d);\n    float _740 = fast::max(_739, 9.9999997473787516355514526367188e-05);\n    float _750 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _740)), 0.0, 1.0);\n    float _755;\n    if (shape_rs.y > _740)\n    {\n        _755 = (_750 * _750) * (3.0 - (2.0 * _750));\n    }\n    else\n    {\n        _755 = _750;\n    }\n    float4 c = color;\n    bool _777 = (_717 <= 0.0) && (ax > (-0.5));\n    if (_777)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _792 = cos(ax);\n            float _794 = sin(ax);\n            g = ((dot(_664, float2(_792, _794)) / fast::max((abs(_792) * _670) + (abs(_794) * _672), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_706)\n        {\n            float4 _837 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _837;\n            float3 param = _837.xyz;\n            float param_1 = xform.y;\n            float3 _844 = fa_tex_fix(param, param_1);\n            float4 _1540 = c;\n            _1540.x = _844.x;\n            _1540.y = _844.y;\n            _1540.z = _844.z;\n            c = _1540;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _856 = scene_rgb(param_2, xform);\n            float4 _881 = mix(float4(color.xyz * color.w, color.w), float4(_856 * color2.w, color2.w), float4(g));\n            float _883 = _881.w;\n            float3 _886;\n            if (_883 > 9.9999997473787516355514526367188e-06)\n            {\n                _886 = _881.xyz / float3(_883);\n            }\n            else\n            {\n                _886 = color.xyz;\n            }\n            c = float4(_886, _883);\n        }\n    }\n    float4 _1549 = c;\n    _1549.w = _1549.w * _755;\n    c = _1549;\n    if (_777 || (shape_rs.y > 0.0))\n    {\n        float _927 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _936 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _936 + float3(_927 * 0.0039215688593685626983642578125);\n            float3 _942 = fa_srgb_to_linear(param_4);\n            float4 _1552 = c;\n            _1552.x = _942.x;\n            _1552.y = _942.y;\n            _1552.z = _942.z;\n            c = _1552;\n        }\n        else\n        {\n            float4 _952 = c;\n            float3 _955 = _952.xyz + float3(_927 * 0.0039215688593685626983642578125);\n            float4 _1559 = _952;\n            _1559.x = _955.x;\n            _1559.y = _955.y;\n            _1559.z = _955.z;\n            c = _1559;\n        }\n        float4 _1564 = c;\n        _1564.w = fast::clamp(_1564.w + ((_927 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1564.w)), 0.0, 1.0);\n        c = _1564;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _316)\n{\n    float2 _323 = gl_FragCoord.xy * _316.fa_target.xy;\n    float _327 = _323.y;\n    return float2(_323.x, mix(_327, 1.0 - _327, _316.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _316, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _369 = base_mode < 0.5;\n    bool _380;\n    if (!_369)\n    {\n        _380 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _380 = _369;\n    }\n    float _381;\n    if (_380)\n    {\n        _381 = shape_half.x;\n    }\n    else\n    {\n        _381 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _316), _316.fa_time.x, base_mode, float4(0.0), _381 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _302 = scene_rgb(param, xform);\n    return _302;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _395)\n{\n    float3 param = _395.tint.xyz;\n    float4 _402 = s.color;\n    float3 _404 = _402.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _404.x;\n    s.color.y = _404.y;\n    s.color.z = _404.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _316 [[buffer(1)]], constant fa_material& _395 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _982 = in.params.x > 31.5;\n    if (_982)\n    {\n        mode -= 32.0;\n    }\n    float _990 = mode;\n    bool _992 = _990 > 15.5;\n    if (_992)\n    {\n        mode -= 16.0;\n    }\n    float _1000 = mode;\n    bool _1002 = _1000 > 7.5;\n    if (_1002)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_992)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _316, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_992)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _316, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1066 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1066;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _316, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1066.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1101 = length(in.uv);\n                    float _1104 = fwidth(_1101);\n                    float _1105 = fast::max(_1104, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1101) / _1105) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1101) / _1105) + 0.5, 0.0, 1.0) * fast::clamp(((_1101 - in.params.y) / _1105) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1145 = fast::clamp(1.0 - _1101, 0.0, 1.0);\n                            cov = (_1145 * _1145) * (3.0 - (2.0 * _1145));\n                        }\n                    }\n                    float3 _1154;\n                    if (_992)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1154 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _316, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1154 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1154, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1493 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _316, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1493 };\n    fragment0(param_11, param_12, in.xform, _395);\n    _1493 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_982)\n    {\n        float4 _1192 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1197 = scene_rgb(param_13, in.xform);\n        float3 _1201 = mix(_1192.xyz, _1197, float3(in.color2.w));\n        out.frag_color.x = _1201.x;\n        out.frag_color.y = _1201.y;\n        out.frag_color.z = _1201.z;\n    }\n    if (_1002)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1225 = _316.fog_col.w > 0.0;\n    bool _1233;\n    if (!_1225)\n    {\n        _1233 = _316.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1233 = _1225;\n    }\n    if (_1233)\n    {\n        float3 _1247 = float3(in.world_xy, in.world_z) - _316.fog_eye.xyz;\n        float _1254 = dot(_1247, _316.fog_c.xyz);\n        bool _1258 = _316.fog_c.w > 0.5;\n        float _1259;\n        if (_1258)\n        {\n            _1259 = _1254;\n        }\n        else\n        {\n            _1259 = length(_1247);\n        }\n        float _1271 = _1259 - _316.fog_b.x;\n        if (_1271 > 0.0)\n        {\n            float _1280 = _316.fog_col.w * _1271;\n            float tau = _1280 * _1280;\n            if (_316.fog_b.y > 0.0)\n            {\n                float _1296;\n                if (_1258)\n                {\n                    _1296 = in.world_xy.y - (_316.fog_c.y * _1254);\n                }\n                else\n                {\n                    _1296 = _316.fog_eye.y;\n                }\n                float _1317 = mix(_1296, in.world_xy.y, fast::clamp(_316.fog_b.x / _1259, 0.0, 1.0));\n                float _1321 = in.world_xy.y - _1317;\n                float _1326 = _1317 - _316.fog_b.z;\n                float _1331 = in.world_xy.y - _316.fog_b.z;\n                bool _1334 = _1326 <= 0.0;\n                bool _1335 = !_1334;\n                bool _1341;\n                if (_1335)\n                {\n                    _1341 = _316.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1341 = _1334;\n                }\n                float _1342;\n                if (_1341)\n                {\n                    _1342 = _316.fog_b.y;\n                }\n                else\n                {\n                    _1342 = _316.fog_b.y * exp(-fast::min(_316.fog_b.w * _1326, 80.0));\n                }\n                bool _1369;\n                if (_1335)\n                {\n                    _1369 = _316.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1369 = _1334;\n                }\n                float _1370;\n                if (_1369)\n                {\n                    _1370 = _316.fog_b.y * _1326;\n                }\n                else\n                {\n                    _1370 = (_316.fog_b.y * (1.0 - exp(-fast::min(_316.fog_b.w * _1326, 80.0)))) / _316.fog_b.w;\n                }\n                bool _1395 = _1331 <= 0.0;\n                bool _1402;\n                if (!_1395)\n                {\n                    _1402 = _316.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1402 = _1395;\n                }\n                float _1403;\n                if (_1402)\n                {\n                    _1403 = _316.fog_b.y * _1331;\n                }\n                else\n                {\n                    _1403 = (_316.fog_b.y * (1.0 - exp(-fast::min(_316.fog_b.w * _1331, 80.0)))) / _316.fog_b.w;\n                }\n                float _1430;\n                if (abs(_1321) < 0.001000000047497451305389404296875)\n                {\n                    _1430 = _1342;\n                }\n                else\n                {\n                    _1430 = (_1403 - _1370) / _1321;\n                }\n                tau += (_1271 * fast::max(_1430, 0.0));\n            }\n            float4 _1453 = out.frag_color;\n            float3 _1461 = mix(_1453.xyz, _316.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1461.x;\n            out.frag_color.y = _1461.y;\n            out.frag_color.z = _1461.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_316",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_395",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _153)\n{\n    float2 _160 = gl_FragCoord.xy * _153.fa_target.xy;\n    float _165 = _160.y;\n    return float2(_160.x, mix(_165, 1.0 - _165, _153.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _153, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _209 = base_mode < 0.5;\n    bool _220;\n    if (!_209)\n    {\n        _220 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _220 = _209;\n    }\n    float _221;\n    if (_220)\n    {\n        _221 = shape_half.x;\n    }\n    else\n    {\n        _221 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _153), _153.fa_time.x, base_mode, float4(0.0), _221 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param, xform);\n    return _138;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _235)\n{\n    float3 param = _235.tint.xyz;\n    float4 _242 = s.color;\n    float3 _244 = _242.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _244.x;\n    s.color.y = _244.y;\n    s.color.z = _244.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _153 [[buffer(1)]], constant fa_material& _235 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _263 = tex.sample(smp, in.uv);\n    float3 param = _263.xyz;\n    float param_1 = in.xform.y;\n    float3 _272 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_272, _263.w) * in.color;\n    float param_2 = 0.0;\n    float4 _326 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _153, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _326 };\n    fragment0(param_3, param_4, in.xform, _235);\n    _326 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_153",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_235",
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
