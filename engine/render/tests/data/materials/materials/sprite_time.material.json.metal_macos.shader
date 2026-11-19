{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "e7ae2aae15992ecb78a26a34b353f3d952e8e65744815e598b5d319af1a2ba44",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _266 = tex.sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _89 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = precise::atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = fast::min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _308, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _403 = _308.lit.y > 0.5;\n    if (_403)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _308.normal_uv.xy) + _308.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _427 = fa_tex_fix(param, param_1);\n        float3 _431 = (_427 * 2.0) - float3(1.0);\n        float _438 = cos(params.y);\n        float _440 = sin(params.y);\n        n = fast::normalize(float3((float2(_438, _440) * _431.x) + ((float2(-_440, _438) * ((mode > 5.5) ? (-1.0) : 1.0)) * _431.y), fast::max(_431.z, 0.0500000007450580596923828125)));\n    }\n    bool _474 = !_403;\n    bool _480;\n    if (_474)\n    {\n        _480 = _308.lit.z > 0.5;\n    }\n    else\n    {\n        _480 = _474;\n    }\n    float3 _483;\n    if (_480)\n    {\n        _483 = _308.flat_ambient.xyz;\n    }\n    else\n    {\n        _483 = _308.ambient.xyz;\n    }\n    float3 total = _483;\n    bool _500;\n    if (_480)\n    {\n        _500 = _308.lit.z < 1.5;\n    }\n    else\n    {\n        _500 = _480;\n    }\n    if (_500)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _308.light_map.xy), level(0.0)).xyz * _308.light_map.z);\n    }\n    float3 l;\n    float _618;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _540;\n        if (!_480)\n        {\n            _540 = float(i) >= _308.lit.x;\n        }\n        else\n        {\n            _540 = _480;\n        }\n        if (_540)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_308.light_pos[i].w < 0.0)\n        {\n            l = _308.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _566 = _308.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_566) / fast::max(_308.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _308.light_color[i].w);\n            float3 _586 = float3(_566, _308.light_pos[i].z);\n            l = _586 / float3(fast::max(length(_586), 9.9999997473787516355514526367188e-05));\n            if (_308.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _308.light_shadow_v[i].x;\n                float2 param_3 = -_566;\n                float param_4 = _308.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_403)\n        {\n            _618 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _618 = 1.0;\n        }\n        total += (_308.light_color[i].xyz * (att * _618));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _646 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _650 = uv * _646;\n    float _656 = _646.x;\n    float _658 = _646.y;\n    float _660 = fast::clamp(shape_rs.x, 0.0, fast::min(_656, _658));\n    float2 _671 = (abs(_650) - _646) + float2(_660);\n    float d = (length(fast::max(_671, float2(0.0))) + fast::min(fast::max(_671.x, _671.y), 0.0)) - _660;\n    float ax = params.y;\n    bool _692 = params.y > 15.0;\n    if (_692)\n    {\n        ax -= 20.0;\n    }\n    float _703;\n    if (ax <= (-1.5))\n    {\n        _703 = (-2.0) - ax;\n    }\n    else\n    {\n        _703 = 0.0;\n    }\n    if (_703 > 0.0)\n    {\n        float _717 = _703 * 0.5;\n        d = abs(d + _717) - _717;\n    }\n    float _725 = fwidth(d);\n    float _726 = fast::max(_725, 9.9999997473787516355514526367188e-05);\n    float _736 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _726)), 0.0, 1.0);\n    float _741;\n    if (shape_rs.y > _726)\n    {\n        _741 = (_736 * _736) * (3.0 - (2.0 * _736));\n    }\n    else\n    {\n        _741 = _736;\n    }\n    float4 c = color;\n    bool _763 = (_703 <= 0.0) && (ax > (-0.5));\n    if (_763)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _778 = cos(ax);\n            float _780 = sin(ax);\n            g = ((dot(_650, float2(_778, _780)) / fast::max((abs(_778) * _656) + (abs(_780) * _658), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_692)\n        {\n            float4 _823 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _823;\n            float3 param = _823.xyz;\n            float param_1 = xform.y;\n            float3 _830 = fa_tex_fix(param, param_1);\n            float4 _1526 = c;\n            _1526.x = _830.x;\n            _1526.y = _830.y;\n            _1526.z = _830.z;\n            c = _1526;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _842 = scene_rgb(param_2, xform);\n            float4 _867 = mix(float4(color.xyz * color.w, color.w), float4(_842 * color2.w, color2.w), float4(g));\n            float _869 = _867.w;\n            float3 _872;\n            if (_869 > 9.9999997473787516355514526367188e-06)\n            {\n                _872 = _867.xyz / float3(_869);\n            }\n            else\n            {\n                _872 = color.xyz;\n            }\n            c = float4(_872, _869);\n        }\n    }\n    float4 _1535 = c;\n    _1535.w = _1535.w * _741;\n    c = _1535;\n    if (_763 || (shape_rs.y > 0.0))\n    {\n        float _913 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _922 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _922 + float3(_913 * 0.0039215688593685626983642578125);\n            float3 _928 = fa_srgb_to_linear(param_4);\n            float4 _1538 = c;\n            _1538.x = _928.x;\n            _1538.y = _928.y;\n            _1538.z = _928.z;\n            c = _1538;\n        }\n        else\n        {\n            float4 _938 = c;\n            float3 _941 = _938.xyz + float3(_913 * 0.0039215688593685626983642578125);\n            float4 _1545 = _938;\n            _1545.x = _941.x;\n            _1545.y = _941.y;\n            _1545.z = _941.z;\n            c = _1545;\n        }\n        float4 _1550 = c;\n        _1550.w = fast::clamp(_1550.w + ((_913 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1550.w)), 0.0, 1.0);\n        c = _1550;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _308)\n{\n    float2 _315 = gl_FragCoord.xy * _308.fa_target.xy;\n    float _319 = _315.y;\n    return float2(_315.x, mix(_319, 1.0 - _319, _308.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _308, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _361 = base_mode < 0.5;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _308), _308.fa_time.x, base_mode, float4(0.0), _373 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _308 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _968 = in.params.x > 31.5;\n    if (_968)\n    {\n        mode -= 32.0;\n    }\n    float _976 = mode;\n    bool _978 = _976 > 15.5;\n    if (_978)\n    {\n        mode -= 16.0;\n    }\n    float _986 = mode;\n    bool _988 = _986 > 7.5;\n    if (_988)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_978)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_978)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1052 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1052;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1052.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1087 = length(in.uv);\n                    float _1090 = fwidth(_1087);\n                    float _1091 = fast::max(_1090, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1087) / _1091) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1087) / _1091) + 0.5, 0.0, 1.0) * fast::clamp(((_1087 - in.params.y) / _1091) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1131 = fast::clamp(1.0 - _1087, 0.0, 1.0);\n                            cov = (_1131 * _1131) * (3.0 - (2.0 * _1131));\n                        }\n                    }\n                    float3 _1140;\n                    if (_978)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1140 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1140 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1140, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1479 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _308, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1479 };\n    fragment0(param_11, param_12);\n    _1479 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_968)\n    {\n        float4 _1178 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1183 = scene_rgb(param_13, in.xform);\n        float3 _1187 = mix(_1178.xyz, _1183, float3(in.color2.w));\n        out.frag_color.x = _1187.x;\n        out.frag_color.y = _1187.y;\n        out.frag_color.z = _1187.z;\n    }\n    if (_988)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1211 = _308.fog_col.w > 0.0;\n    bool _1219;\n    if (!_1211)\n    {\n        _1219 = _308.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1219 = _1211;\n    }\n    if (_1219)\n    {\n        float3 _1233 = float3(in.world_xy, in.world_z) - _308.fog_eye.xyz;\n        float _1240 = dot(_1233, _308.fog_c.xyz);\n        bool _1244 = _308.fog_c.w > 0.5;\n        float _1245;\n        if (_1244)\n        {\n            _1245 = _1240;\n        }\n        else\n        {\n            _1245 = length(_1233);\n        }\n        float _1257 = _1245 - _308.fog_b.x;\n        if (_1257 > 0.0)\n        {\n            float _1266 = _308.fog_col.w * _1257;\n            float tau = _1266 * _1266;\n            if (_308.fog_b.y > 0.0)\n            {\n                float _1282;\n                if (_1244)\n                {\n                    _1282 = in.world_xy.y - (_308.fog_c.y * _1240);\n                }\n                else\n                {\n                    _1282 = _308.fog_eye.y;\n                }\n                float _1303 = mix(_1282, in.world_xy.y, fast::clamp(_308.fog_b.x / _1245, 0.0, 1.0));\n                float _1307 = in.world_xy.y - _1303;\n                float _1312 = _1303 - _308.fog_b.z;\n                float _1317 = in.world_xy.y - _308.fog_b.z;\n                bool _1320 = _1312 <= 0.0;\n                bool _1321 = !_1320;\n                bool _1327;\n                if (_1321)\n                {\n                    _1327 = _308.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1327 = _1320;\n                }\n                float _1328;\n                if (_1327)\n                {\n                    _1328 = _308.fog_b.y;\n                }\n                else\n                {\n                    _1328 = _308.fog_b.y * exp(-fast::min(_308.fog_b.w * _1312, 80.0));\n                }\n                bool _1355;\n                if (_1321)\n                {\n                    _1355 = _308.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1355 = _1320;\n                }\n                float _1356;\n                if (_1355)\n                {\n                    _1356 = _308.fog_b.y * _1312;\n                }\n                else\n                {\n                    _1356 = (_308.fog_b.y * (1.0 - exp(-fast::min(_308.fog_b.w * _1312, 80.0)))) / _308.fog_b.w;\n                }\n                bool _1381 = _1317 <= 0.0;\n                bool _1388;\n                if (!_1381)\n                {\n                    _1388 = _308.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1388 = _1381;\n                }\n                float _1389;\n                if (_1388)\n                {\n                    _1389 = _308.fog_b.y * _1317;\n                }\n                else\n                {\n                    _1389 = (_308.fog_b.y * (1.0 - exp(-fast::min(_308.fog_b.w * _1317, 80.0)))) / _308.fog_b.w;\n                }\n                float _1416;\n                if (abs(_1307) < 0.001000000047497451305389404296875)\n                {\n                    _1416 = _1328;\n                }\n                else\n                {\n                    _1416 = (_1389 - _1356) / _1307;\n                }\n                tau += (_1257 * fast::max(_1416, 0.0));\n            }\n            float4 _1439 = out.frag_color;\n            float3 _1447 = mix(_1439.xyz, _308.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1447.x;\n            out.frag_color.y = _1447.y;\n            out.frag_color.z = _1447.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_308",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _127)\n{\n    float2 _134 = gl_FragCoord.xy * _127.fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, mix(_140, 1.0 - _140, _127.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _127, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _127), _127.fa_time.x, base_mode, float4(0.0), _196 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _127 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _233 = tex.sample(smp, in.uv);\n    float3 param = _233.xyz;\n    float param_1 = in.xform.y;\n    float3 _244 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_244, _233.w) * in.color;\n    float param_2 = 0.0;\n    float4 _298 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _127, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _298 };\n    fragment0(param_3, param_4);\n    _298 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_127",
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
