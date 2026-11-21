{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _266 = tex.sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _89 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = precise::atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = fast::min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _309, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _401 = _309.lit.y > 0.5;\n    if (_401)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _309.normal_uv.xy) + _309.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _425 = fa_tex_fix(param, param_1);\n        float3 _429 = (_425 * 2.0) - float3(1.0);\n        float _436 = cos(params.y);\n        float _438 = sin(params.y);\n        n = fast::normalize(float3((float2(_436, _438) * _429.x) + ((float2(-_438, _436) * ((mode > 5.5) ? (-1.0) : 1.0)) * _429.y), fast::max(_429.z, 0.0500000007450580596923828125)));\n    }\n    bool _472 = !_401;\n    bool _478;\n    if (_472)\n    {\n        _478 = _309.lit.z > 0.5;\n    }\n    else\n    {\n        _478 = _472;\n    }\n    float3 _481;\n    if (_478)\n    {\n        _481 = _309.flat_ambient.xyz;\n    }\n    else\n    {\n        _481 = _309.ambient.xyz;\n    }\n    float3 total = _481;\n    bool _498;\n    if (_478)\n    {\n        _498 = _309.lit.z < 1.5;\n    }\n    else\n    {\n        _498 = _478;\n    }\n    if (_498)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _309.light_map.xy), level(0.0)).xyz * _309.light_map.z);\n    }\n    float3 l;\n    float _616;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _538;\n        if (!_478)\n        {\n            _538 = float(i) >= _309.lit.x;\n        }\n        else\n        {\n            _538 = _478;\n        }\n        if (_538)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_309.light_pos[i].w < 0.0)\n        {\n            l = _309.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _564 = _309.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_564) / fast::max(_309.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _309.light_color[i].w);\n            float3 _584 = float3(_564, _309.light_pos[i].z);\n            l = _584 / float3(fast::max(length(_584), 9.9999997473787516355514526367188e-05));\n            if (_309.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _309.light_shadow_v[i].x;\n                float2 param_3 = -_564;\n                float param_4 = _309.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_401)\n        {\n            _616 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _616 = 1.0;\n        }\n        total += (_309.light_color[i].xyz * (att * _616));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _644 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _648 = uv * _644;\n    float _654 = _644.x;\n    float _656 = _644.y;\n    float _658 = fast::clamp(shape_rs.x, 0.0, fast::min(_654, _656));\n    float2 _669 = (abs(_648) - _644) + float2(_658);\n    float d = (length(fast::max(_669, float2(0.0))) + fast::min(fast::max(_669.x, _669.y), 0.0)) - _658;\n    float ax = params.y;\n    bool _690 = params.y > 15.0;\n    if (_690)\n    {\n        ax -= 20.0;\n    }\n    float _701;\n    if (ax <= (-1.5))\n    {\n        _701 = (-2.0) - ax;\n    }\n    else\n    {\n        _701 = 0.0;\n    }\n    if (_701 > 0.0)\n    {\n        float _715 = _701 * 0.5;\n        d = abs(d + _715) - _715;\n    }\n    float _723 = fwidth(d);\n    float _724 = fast::max(_723, 9.9999997473787516355514526367188e-05);\n    float _734 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _724)), 0.0, 1.0);\n    float _739;\n    if (shape_rs.y > _724)\n    {\n        _739 = (_734 * _734) * (3.0 - (2.0 * _734));\n    }\n    else\n    {\n        _739 = _734;\n    }\n    float4 c = color;\n    bool _761 = (_701 <= 0.0) && (ax > (-0.5));\n    if (_761)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _776 = cos(ax);\n            float _778 = sin(ax);\n            g = ((dot(_648, float2(_776, _778)) / fast::max((abs(_776) * _654) + (abs(_778) * _656), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_690)\n        {\n            float4 _821 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _821;\n            float3 param = _821.xyz;\n            float param_1 = xform.y;\n            float3 _828 = fa_tex_fix(param, param_1);\n            float4 _1525 = c;\n            _1525.x = _828.x;\n            _1525.y = _828.y;\n            _1525.z = _828.z;\n            c = _1525;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _840 = scene_rgb(param_2, xform);\n            float4 _865 = mix(float4(color.xyz * color.w, color.w), float4(_840 * color2.w, color2.w), float4(g));\n            float _867 = _865.w;\n            float3 _870;\n            if (_867 > 9.9999997473787516355514526367188e-06)\n            {\n                _870 = _865.xyz / float3(_867);\n            }\n            else\n            {\n                _870 = color.xyz;\n            }\n            c = float4(_870, _867);\n        }\n    }\n    float4 _1534 = c;\n    _1534.w = _1534.w * _739;\n    c = _1534;\n    if (_761 || (shape_rs.y > 0.0))\n    {\n        float _911 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _920 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _920 + float3(_911 * 0.0039215688593685626983642578125);\n            float3 _926 = fa_srgb_to_linear(param_4);\n            float4 _1537 = c;\n            _1537.x = _926.x;\n            _1537.y = _926.y;\n            _1537.z = _926.z;\n            c = _1537;\n        }\n        else\n        {\n            float4 _936 = c;\n            float3 _939 = _936.xyz + float3(_911 * 0.0039215688593685626983642578125);\n            float4 _1544 = _936;\n            _1544.x = _939.x;\n            _1544.y = _939.y;\n            _1544.z = _939.z;\n            c = _1544;\n        }\n        float4 _1549 = c;\n        _1549.w = fast::clamp(_1549.w + ((_911 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1549.w)), 0.0, 1.0);\n        c = _1549;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _309)\n{\n    float2 _316 = gl_FragCoord.xy * _309.fa_target.xy;\n    float _320 = _316.y;\n    return float2(_316.x, mix(_320, 1.0 - _320, _309.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _309, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _362 = base_mode < 0.5;\n    bool _373;\n    if (!_362)\n    {\n        _373 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _373 = _362;\n    }\n    float _374;\n    if (_373)\n    {\n        _374 = shape_half.x;\n    }\n    else\n    {\n        _374 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _309), _309.fa_time.x, base_mode, float4(0.0), _374 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _309 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _966 = in.params.x > 31.5;\n    if (_966)\n    {\n        mode -= 32.0;\n    }\n    float _974 = mode;\n    bool _976 = _974 > 15.5;\n    if (_976)\n    {\n        mode -= 16.0;\n    }\n    float _984 = mode;\n    bool _986 = _984 > 7.5;\n    if (_986)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_976)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_976)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1050 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1050;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1050.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1085 = length(in.uv);\n                    float _1088 = fwidth(_1085);\n                    float _1089 = fast::max(_1088, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1085) / _1089) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1085) / _1089) + 0.5, 0.0, 1.0) * fast::clamp(((_1085 - in.params.y) / _1089) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1129 = fast::clamp(1.0 - _1085, 0.0, 1.0);\n                            cov = (_1129 * _1129) * (3.0 - (2.0 * _1129));\n                        }\n                    }\n                    float3 _1138;\n                    if (_976)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1138 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1138 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1138, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1478 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _309, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1478 };\n    fragment0(param_11, param_12);\n    _1478 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_966)\n    {\n        float4 _1176 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1181 = scene_rgb(param_13, in.xform);\n        float3 _1185 = mix(_1176.xyz, _1181, float3(in.color2.w));\n        out.frag_color.x = _1185.x;\n        out.frag_color.y = _1185.y;\n        out.frag_color.z = _1185.z;\n    }\n    if (_986)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1209 = _309.fog_col.w > 0.0;\n    bool _1217;\n    if (!_1209)\n    {\n        _1217 = _309.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1217 = _1209;\n    }\n    if (_1217)\n    {\n        float3 _1231 = float3(in.world_xy, in.world_z) - _309.fog_eye.xyz;\n        float _1238 = dot(_1231, _309.fog_c.xyz);\n        bool _1242 = _309.fog_c.w > 0.5;\n        float _1243;\n        if (_1242)\n        {\n            _1243 = _1238;\n        }\n        else\n        {\n            _1243 = length(_1231);\n        }\n        float _1255 = _1243 - _309.fog_b.x;\n        if (_1255 > 0.0)\n        {\n            float _1264 = _309.fog_col.w * _1255;\n            float tau = _1264 * _1264;\n            if (_309.fog_b.y > 0.0)\n            {\n                float _1280;\n                if (_1242)\n                {\n                    _1280 = in.world_xy.y - (_309.fog_c.y * _1238);\n                }\n                else\n                {\n                    _1280 = _309.fog_eye.y;\n                }\n                float _1301 = mix(_1280, in.world_xy.y, fast::clamp(_309.fog_b.x / _1243, 0.0, 1.0));\n                float _1305 = in.world_xy.y - _1301;\n                float _1310 = _1301 - _309.fog_b.z;\n                float _1315 = in.world_xy.y - _309.fog_b.z;\n                bool _1318 = _1310 <= 0.0;\n                bool _1319 = !_1318;\n                bool _1325;\n                if (_1319)\n                {\n                    _1325 = _309.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1325 = _1318;\n                }\n                float _1326;\n                if (_1325)\n                {\n                    _1326 = _309.fog_b.y;\n                }\n                else\n                {\n                    _1326 = _309.fog_b.y * exp(-fast::min(_309.fog_b.w * _1310, 80.0));\n                }\n                bool _1353;\n                if (_1319)\n                {\n                    _1353 = _309.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1353 = _1318;\n                }\n                float _1354;\n                if (_1353)\n                {\n                    _1354 = _309.fog_b.y * _1310;\n                }\n                else\n                {\n                    _1354 = (_309.fog_b.y * (1.0 - exp(-fast::min(_309.fog_b.w * _1310, 80.0)))) / _309.fog_b.w;\n                }\n                bool _1379 = _1315 <= 0.0;\n                bool _1386;\n                if (!_1379)\n                {\n                    _1386 = _309.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1386 = _1379;\n                }\n                float _1387;\n                if (_1386)\n                {\n                    _1387 = _309.fog_b.y * _1315;\n                }\n                else\n                {\n                    _1387 = (_309.fog_b.y * (1.0 - exp(-fast::min(_309.fog_b.w * _1315, 80.0)))) / _309.fog_b.w;\n                }\n                float _1414;\n                if (abs(_1305) < 0.001000000047497451305389404296875)\n                {\n                    _1414 = _1326;\n                }\n                else\n                {\n                    _1414 = (_1387 - _1354) / _1305;\n                }\n                tau += (_1255 * fast::max(_1414, 0.0));\n            }\n            float4 _1437 = out.frag_color;\n            float3 _1445 = mix(_1437.xyz, _309.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1445.x;\n            out.frag_color.y = _1445.y;\n            out.frag_color.z = _1445.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_309",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _232 = tex.sample(smp, in.uv);\n    float3 param = _232.xyz;\n    float param_1 = in.xform.y;\n    float3 _243 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_243, _232.w) * in.color;\n    float param_2 = 0.0;\n    float4 _298 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _298 };\n    fragment0(param_3, param_4);\n    _298 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1008,
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
