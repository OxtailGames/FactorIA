{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "metal_macos",
  "params": [
    "cut",
    "cutY"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _266 = tex.sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _89 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = precise::atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = fast::min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _309, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _412 = _309.lit.y > 0.5;\n    if (_412)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _309.normal_uv.xy) + _309.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _436 = fa_tex_fix(param, param_1);\n        float3 _440 = (_436 * 2.0) - float3(1.0);\n        float _447 = cos(params.y);\n        float _449 = sin(params.y);\n        n = fast::normalize(float3((float2(_447, _449) * _440.x) + ((float2(-_449, _447) * ((mode > 5.5) ? (-1.0) : 1.0)) * _440.y), fast::max(_440.z, 0.0500000007450580596923828125)));\n    }\n    bool _483 = !_412;\n    bool _489;\n    if (_483)\n    {\n        _489 = _309.lit.z > 0.5;\n    }\n    else\n    {\n        _489 = _483;\n    }\n    float3 _492;\n    if (_489)\n    {\n        _492 = _309.flat_ambient.xyz;\n    }\n    else\n    {\n        _492 = _309.ambient.xyz;\n    }\n    float3 total = _492;\n    bool _509;\n    if (_489)\n    {\n        _509 = _309.lit.z < 1.5;\n    }\n    else\n    {\n        _509 = _489;\n    }\n    if (_509)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _309.light_map.xy), level(0.0)).xyz * _309.light_map.z);\n    }\n    float3 l;\n    float _627;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _549;\n        if (!_489)\n        {\n            _549 = float(i) >= _309.lit.x;\n        }\n        else\n        {\n            _549 = _489;\n        }\n        if (_549)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_309.light_pos[i].w < 0.0)\n        {\n            l = _309.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _575 = _309.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_575) / fast::max(_309.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _309.light_color[i].w);\n            float3 _595 = float3(_575, _309.light_pos[i].z);\n            l = _595 / float3(fast::max(length(_595), 9.9999997473787516355514526367188e-05));\n            if (_309.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _309.light_shadow_v[i].x;\n                float2 param_3 = -_575;\n                float param_4 = _309.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_412)\n        {\n            _627 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _627 = 1.0;\n        }\n        total += (_309.light_color[i].xyz * (att * _627));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _655 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _659 = uv * _655;\n    float _665 = _655.x;\n    float _667 = _655.y;\n    float _669 = fast::clamp(shape_rs.x, 0.0, fast::min(_665, _667));\n    float2 _680 = (abs(_659) - _655) + float2(_669);\n    float d = (length(fast::max(_680, float2(0.0))) + fast::min(fast::max(_680.x, _680.y), 0.0)) - _669;\n    float ax = params.y;\n    bool _701 = params.y > 15.0;\n    if (_701)\n    {\n        ax -= 20.0;\n    }\n    float _712;\n    if (ax <= (-1.5))\n    {\n        _712 = (-2.0) - ax;\n    }\n    else\n    {\n        _712 = 0.0;\n    }\n    if (_712 > 0.0)\n    {\n        float _726 = _712 * 0.5;\n        d = abs(d + _726) - _726;\n    }\n    float _734 = fwidth(d);\n    float _735 = fast::max(_734, 9.9999997473787516355514526367188e-05);\n    float _745 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _735)), 0.0, 1.0);\n    float _750;\n    if (shape_rs.y > _735)\n    {\n        _750 = (_745 * _745) * (3.0 - (2.0 * _745));\n    }\n    else\n    {\n        _750 = _745;\n    }\n    float4 c = color;\n    bool _772 = (_712 <= 0.0) && (ax > (-0.5));\n    if (_772)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _787 = cos(ax);\n            float _789 = sin(ax);\n            g = ((dot(_659, float2(_787, _789)) / fast::max((abs(_787) * _665) + (abs(_789) * _667), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_701)\n        {\n            float4 _832 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _832;\n            float3 param = _832.xyz;\n            float param_1 = xform.y;\n            float3 _839 = fa_tex_fix(param, param_1);\n            float4 _1536 = c;\n            _1536.x = _839.x;\n            _1536.y = _839.y;\n            _1536.z = _839.z;\n            c = _1536;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _851 = scene_rgb(param_2, xform);\n            float4 _876 = mix(float4(color.xyz * color.w, color.w), float4(_851 * color2.w, color2.w), float4(g));\n            float _878 = _876.w;\n            float3 _881;\n            if (_878 > 9.9999997473787516355514526367188e-06)\n            {\n                _881 = _876.xyz / float3(_878);\n            }\n            else\n            {\n                _881 = color.xyz;\n            }\n            c = float4(_881, _878);\n        }\n    }\n    float4 _1545 = c;\n    _1545.w = _1545.w * _750;\n    c = _1545;\n    if (_772 || (shape_rs.y > 0.0))\n    {\n        float _922 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _931 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _931 + float3(_922 * 0.0039215688593685626983642578125);\n            float3 _937 = fa_srgb_to_linear(param_4);\n            float4 _1548 = c;\n            _1548.x = _937.x;\n            _1548.y = _937.y;\n            _1548.z = _937.z;\n            c = _1548;\n        }\n        else\n        {\n            float4 _947 = c;\n            float3 _950 = _947.xyz + float3(_922 * 0.0039215688593685626983642578125);\n            float4 _1555 = _947;\n            _1555.x = _950.x;\n            _1555.y = _950.y;\n            _1555.z = _950.z;\n            c = _1555;\n        }\n        float4 _1560 = c;\n        _1560.w = fast::clamp(_1560.w + ((_922 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1560.w)), 0.0, 1.0);\n        c = _1560;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _309)\n{\n    float2 _316 = gl_FragCoord.xy * _309.fa_target.xy;\n    float _320 = _316.y;\n    return float2(_316.x, mix(_320, 1.0 - _320, _309.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _309, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _362 = base_mode < 0.5;\n    bool _373;\n    if (!_362)\n    {\n        _373 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _373 = _362;\n    }\n    float _374;\n    if (_373)\n    {\n        _374 = shape_half.x;\n    }\n    else\n    {\n        _374 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _309), _309.fa_time.x, base_mode, float4(0.0), _374 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _390)\n{\n    bool _393 = i.screen_uv.x < _390.cut;\n    bool _402;\n    if (!_393)\n    {\n        _402 = i.screen_uv.y < _390.cutY;\n    }\n    else\n    {\n        _402 = _393;\n    }\n    if (_402)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _309 [[buffer(1)]], constant fa_material& _390 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _977 = in.params.x > 31.5;\n    if (_977)\n    {\n        mode -= 32.0;\n    }\n    float _985 = mode;\n    bool _987 = _985 > 15.5;\n    if (_987)\n    {\n        mode -= 16.0;\n    }\n    float _995 = mode;\n    bool _997 = _995 > 7.5;\n    if (_997)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_987)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_987)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1061 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1061;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1061.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1096 = length(in.uv);\n                    float _1099 = fwidth(_1096);\n                    float _1100 = fast::max(_1099, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1096) / _1100) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1096) / _1100) + 0.5, 0.0, 1.0) * fast::clamp(((_1096 - in.params.y) / _1100) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1140 = fast::clamp(1.0 - _1096, 0.0, 1.0);\n                            cov = (_1140 * _1140) * (3.0 - (2.0 * _1140));\n                        }\n                    }\n                    float3 _1149;\n                    if (_987)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1149 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _309, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1149 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1149, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1489 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _309, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1489 };\n    fragment0(param_11, param_12, _390);\n    _1489 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_977)\n    {\n        float4 _1187 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1192 = scene_rgb(param_13, in.xform);\n        float3 _1196 = mix(_1187.xyz, _1192, float3(in.color2.w));\n        out.frag_color.x = _1196.x;\n        out.frag_color.y = _1196.y;\n        out.frag_color.z = _1196.z;\n    }\n    if (_997)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1220 = _309.fog_col.w > 0.0;\n    bool _1228;\n    if (!_1220)\n    {\n        _1228 = _309.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1228 = _1220;\n    }\n    if (_1228)\n    {\n        float3 _1242 = float3(in.world_xy, in.world_z) - _309.fog_eye.xyz;\n        float _1249 = dot(_1242, _309.fog_c.xyz);\n        bool _1253 = _309.fog_c.w > 0.5;\n        float _1254;\n        if (_1253)\n        {\n            _1254 = _1249;\n        }\n        else\n        {\n            _1254 = length(_1242);\n        }\n        float _1266 = _1254 - _309.fog_b.x;\n        if (_1266 > 0.0)\n        {\n            float _1275 = _309.fog_col.w * _1266;\n            float tau = _1275 * _1275;\n            if (_309.fog_b.y > 0.0)\n            {\n                float _1291;\n                if (_1253)\n                {\n                    _1291 = in.world_xy.y - (_309.fog_c.y * _1249);\n                }\n                else\n                {\n                    _1291 = _309.fog_eye.y;\n                }\n                float _1312 = mix(_1291, in.world_xy.y, fast::clamp(_309.fog_b.x / _1254, 0.0, 1.0));\n                float _1316 = in.world_xy.y - _1312;\n                float _1321 = _1312 - _309.fog_b.z;\n                float _1326 = in.world_xy.y - _309.fog_b.z;\n                bool _1329 = _1321 <= 0.0;\n                bool _1330 = !_1329;\n                bool _1336;\n                if (_1330)\n                {\n                    _1336 = _309.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1336 = _1329;\n                }\n                float _1337;\n                if (_1336)\n                {\n                    _1337 = _309.fog_b.y;\n                }\n                else\n                {\n                    _1337 = _309.fog_b.y * exp(-fast::min(_309.fog_b.w * _1321, 80.0));\n                }\n                bool _1364;\n                if (_1330)\n                {\n                    _1364 = _309.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1364 = _1329;\n                }\n                float _1365;\n                if (_1364)\n                {\n                    _1365 = _309.fog_b.y * _1321;\n                }\n                else\n                {\n                    _1365 = (_309.fog_b.y * (1.0 - exp(-fast::min(_309.fog_b.w * _1321, 80.0)))) / _309.fog_b.w;\n                }\n                bool _1390 = _1326 <= 0.0;\n                bool _1397;\n                if (!_1390)\n                {\n                    _1397 = _309.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1397 = _1390;\n                }\n                float _1398;\n                if (_1397)\n                {\n                    _1398 = _309.fog_b.y * _1326;\n                }\n                else\n                {\n                    _1398 = (_309.fog_b.y * (1.0 - exp(-fast::min(_309.fog_b.w * _1326, 80.0)))) / _309.fog_b.w;\n                }\n                float _1425;\n                if (abs(_1316) < 0.001000000047497451305389404296875)\n                {\n                    _1425 = _1337;\n                }\n                else\n                {\n                    _1425 = (_1398 - _1365) / _1316;\n                }\n                tau += (_1266 * fast::max(_1425, 0.0));\n            }\n            float4 _1448 = out.frag_color;\n            float3 _1456 = mix(_1448.xyz, _309.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1456.x;\n            out.frag_color.y = _1456.y;\n            out.frag_color.z = _1456.z;\n        }\n    }\n    return out;\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_390",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _215)\n{\n    bool _218 = i.screen_uv.x < _215.cut;\n    bool _227;\n    if (!_218)\n    {\n        _227 = i.screen_uv.y < _215.cutY;\n    }\n    else\n    {\n        _227 = _218;\n    }\n    if (_227)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], constant fa_material& _215 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _243 = tex.sample(smp, in.uv);\n    float3 param = _243.xyz;\n    float param_1 = in.xform.y;\n    float3 _254 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_254, _243.w) * in.color;\n    float param_2 = 0.0;\n    float4 _309 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _309 };\n    fragment0(param_3, param_4, _215);\n    _309 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_215",
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
