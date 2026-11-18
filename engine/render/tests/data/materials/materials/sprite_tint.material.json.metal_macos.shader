{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _248 = fa_linear_to_srgb(param);\n        c = _248;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _256 = fa_srgb_to_linear(param_1);\n            c = _256;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _267 = tex.sample(smp, p);\n    float3 param = _267.xyz;\n    float param_1 = xform.y;\n    float3 _277 = fa_tex_fix(param, param_1);\n    return float4(_277, _267.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _90 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_90.x * 255.0) + 0.5) * 256.0) + floor((_90.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _114 = length(d);\n    if (_114 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _128 = precise::atan2(d.y, d.x);\n    float a = _128;\n    float _131;\n    if (_128 < 0.0)\n    {\n        _131 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _131 = a;\n    }\n    a = _131;\n    float _143 = _131 * 162.9746551513671875;\n    float _148 = fast::min(floor(_143), 1023.0);\n    float _155 = _148 + 1.0;\n    float i1 = _155;\n    if (_155 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _148;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _114) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _114) + 0.5, 0.0, 1.0), _143 - _148);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _314, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _392 = _314.lit.y > 0.5;\n    if (_392)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _314.normal_uv.xy) + _314.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _416 = fa_tex_fix(param, param_1);\n        float3 _420 = (_416 * 2.0) - float3(1.0);\n        float _427 = cos(params.y);\n        float _429 = sin(params.y);\n        n = fast::normalize(float3((float2(_427, _429) * _420.x) + ((float2(-_429, _427) * ((mode > 5.5) ? (-1.0) : 1.0)) * _420.y), fast::max(_420.z, 0.0500000007450580596923828125)));\n    }\n    bool _463 = !_392;\n    bool _469;\n    if (_463)\n    {\n        _469 = _314.lit.z > 0.5;\n    }\n    else\n    {\n        _469 = _463;\n    }\n    float3 _472;\n    if (_469)\n    {\n        _472 = _314.flat_ambient.xyz;\n    }\n    else\n    {\n        _472 = _314.ambient.xyz;\n    }\n    float3 total = _472;\n    bool _489;\n    if (_469)\n    {\n        _489 = _314.lit.z < 1.5;\n    }\n    else\n    {\n        _489 = _469;\n    }\n    if (_489)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _314.light_map.xy), level(0.0)).xyz * _314.light_map.z);\n    }\n    float3 l;\n    float _608;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _529;\n        if (!_469)\n        {\n            _529 = float(i) >= _314.lit.x;\n        }\n        else\n        {\n            _529 = _469;\n        }\n        if (_529)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_314.light_pos[i].w < 0.0)\n        {\n            l = _314.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _555 = _314.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_555) / fast::max(_314.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _314.light_color[i].w);\n            float3 _575 = float3(_555, _314.light_pos[i].z);\n            l = _575 / float3(fast::max(length(_575), 9.9999997473787516355514526367188e-05));\n            if (_314.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _314.light_shadow_v[i].x;\n                float2 param_3 = -_555;\n                float param_4 = _314.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_392)\n        {\n            _608 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _608 = 1.0;\n        }\n        total += (_314.light_color[i].xyz * (att * _608));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _294 = fa_srgb_to_linear(param);\n        c = _294;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& params, thread float2& shape_half, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _637 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _641 = uv * _637;\n    float _647 = _637.x;\n    float _649 = _637.y;\n    float _651 = fast::clamp(shape_rs.x, 0.0, fast::min(_647, _649));\n    float2 _662 = (abs(_641) - _637) + float2(_651);\n    float d = (length(fast::max(_662, float2(0.0))) + fast::min(fast::max(_662.x, _662.y), 0.0)) - _651;\n    float ax = params.y;\n    bool _683 = params.y > 15.0;\n    if (_683)\n    {\n        ax -= 20.0;\n    }\n    float _694;\n    if (ax <= (-1.5))\n    {\n        _694 = (-2.0) - ax;\n    }\n    else\n    {\n        _694 = 0.0;\n    }\n    if (_694 > 0.0)\n    {\n        float _708 = _694 * 0.5;\n        d = abs(d + _708) - _708;\n    }\n    float _716 = fwidth(d);\n    float _717 = fast::max(_716, 9.9999997473787516355514526367188e-05);\n    float _727 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _717)), 0.0, 1.0);\n    float _732;\n    if (shape_rs.y > _717)\n    {\n        _732 = (_727 * _727) * (3.0 - (2.0 * _727));\n    }\n    else\n    {\n        _732 = _727;\n    }\n    float4 c = color;\n    bool _754 = (_694 <= 0.0) && (ax > (-0.5));\n    if (_754)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _769 = cos(ax);\n            float _771 = sin(ax);\n            g = ((dot(_641, float2(_769, _771)) / fast::max((abs(_769) * _647) + (abs(_771) * _649), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_683)\n        {\n            float4 _814 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _814;\n            float3 param = _814.xyz;\n            float param_1 = xform.y;\n            float3 _821 = fa_tex_fix(param, param_1);\n            float4 _1513 = c;\n            _1513.x = _821.x;\n            _1513.y = _821.y;\n            _1513.z = _821.z;\n            c = _1513;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _833 = scene_rgb(param_2, xform);\n            float4 _858 = mix(float4(color.xyz * color.w, color.w), float4(_833 * color2.w, color2.w), float4(g));\n            float _860 = _858.w;\n            float3 _863;\n            if (_860 > 9.9999997473787516355514526367188e-06)\n            {\n                _863 = _858.xyz / float3(_860);\n            }\n            else\n            {\n                _863 = color.xyz;\n            }\n            c = float4(_863, _860);\n        }\n    }\n    float4 _1522 = c;\n    _1522.w = _1522.w * _732;\n    c = _1522;\n    if (_754 || (shape_rs.y > 0.0))\n    {\n        float _904 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _913 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _913 + float3(_904 * 0.0039215688593685626983642578125);\n            float3 _919 = fa_srgb_to_linear(param_4);\n            float4 _1525 = c;\n            _1525.x = _919.x;\n            _1525.y = _919.y;\n            _1525.z = _919.z;\n            c = _1525;\n        }\n        else\n        {\n            float4 _929 = c;\n            float3 _932 = _929.xyz + float3(_904 * 0.0039215688593685626983642578125);\n            float4 _1532 = _929;\n            _1532.x = _932.x;\n            _1532.y = _932.y;\n            _1532.z = _932.z;\n            c = _1532;\n        }\n        float4 _1537 = c;\n        _1537.w = fast::clamp(_1537.w + ((_904 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1537.w)), 0.0, 1.0);\n        c = _1537;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _314)\n{\n    float2 _321 = gl_FragCoord.xy * _314.fa_target.xy;\n    float _325 = _321.y;\n    return float2(_321.x, mix(_325, 1.0 - _325, _314.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _314, thread float2& uv, thread float4& color, thread float2& world_xy)\n{\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _314), _314.fa_time.x, base_mode, float4(0.0) };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _300 = scene_rgb(param, xform);\n    return _300;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _370)\n{\n    float3 param = _370.tint.xyz;\n    float4 _377 = s.color;\n    float3 _379 = _377.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _379.x;\n    s.color.y = _379.y;\n    s.color.z = _379.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _314 [[buffer(1)]], constant fa_material& _370 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _959 = in.params.x > 31.5;\n    if (_959)\n    {\n        mode -= 32.0;\n    }\n    float _967 = mode;\n    bool _969 = _967 > 15.5;\n    if (_969)\n    {\n        mode -= 16.0;\n    }\n    float _977 = mode;\n    bool _979 = _977 > 7.5;\n    if (_979)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_969)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _314, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.params, in.shape_half, in.shape_rs, in.color2);\n            if (_969)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _314, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1043 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1043;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _314, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1043.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1079 = length(in.uv);\n                    float _1082 = fwidth(_1079);\n                    float _1083 = fast::max(_1082, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1079) / _1083) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1079) / _1083) + 0.5, 0.0, 1.0) * fast::clamp(((_1079 - in.params.y) / _1083) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1124 = fast::clamp(1.0 - _1079, 0.0, 1.0);\n                            cov = (_1124 * _1124) * (3.0 - (2.0 * _1124));\n                        }\n                    }\n                    float3 _1133;\n                    if (_969)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1133 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _314, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1133 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1133, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _314, in.uv, in.color, in.world_xy);\n    QuadSurface param_12 = QuadSurface{ out.frag_color };\n    fragment0(param_11, param_12, in.xform, _370);\n    out.frag_color = param_12.color;\n    if (_959)\n    {\n        float4 _1170 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1175 = scene_rgb(param_13, in.xform);\n        float3 _1179 = mix(_1170.xyz, _1175, float3(in.color2.w));\n        out.frag_color.x = _1179.x;\n        out.frag_color.y = _1179.y;\n        out.frag_color.z = _1179.z;\n    }\n    if (_979)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1203 = _314.fog_col.w > 0.0;\n    bool _1211;\n    if (!_1203)\n    {\n        _1211 = _314.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1211 = _1203;\n    }\n    if (_1211)\n    {\n        float3 _1225 = float3(in.world_xy, in.world_z) - _314.fog_eye.xyz;\n        float _1232 = dot(_1225, _314.fog_c.xyz);\n        bool _1236 = _314.fog_c.w > 0.5;\n        float _1237;\n        if (_1236)\n        {\n            _1237 = _1232;\n        }\n        else\n        {\n            _1237 = length(_1225);\n        }\n        float _1249 = _1237 - _314.fog_b.x;\n        if (_1249 > 0.0)\n        {\n            float _1258 = _314.fog_col.w * _1249;\n            float tau = _1258 * _1258;\n            if (_314.fog_b.y > 0.0)\n            {\n                float _1274;\n                if (_1236)\n                {\n                    _1274 = in.world_xy.y - (_314.fog_c.y * _1232);\n                }\n                else\n                {\n                    _1274 = _314.fog_eye.y;\n                }\n                float _1295 = mix(_1274, in.world_xy.y, fast::clamp(_314.fog_b.x / _1237, 0.0, 1.0));\n                float _1299 = in.world_xy.y - _1295;\n                float _1304 = _1295 - _314.fog_b.z;\n                float _1309 = in.world_xy.y - _314.fog_b.z;\n                bool _1312 = _1304 <= 0.0;\n                bool _1313 = !_1312;\n                bool _1319;\n                if (_1313)\n                {\n                    _1319 = _314.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1319 = _1312;\n                }\n                float _1320;\n                if (_1319)\n                {\n                    _1320 = _314.fog_b.y;\n                }\n                else\n                {\n                    _1320 = _314.fog_b.y * exp(-fast::min(_314.fog_b.w * _1304, 80.0));\n                }\n                bool _1347;\n                if (_1313)\n                {\n                    _1347 = _314.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1347 = _1312;\n                }\n                float _1348;\n                if (_1347)\n                {\n                    _1348 = _314.fog_b.y * _1304;\n                }\n                else\n                {\n                    _1348 = (_314.fog_b.y * (1.0 - exp(-fast::min(_314.fog_b.w * _1304, 80.0)))) / _314.fog_b.w;\n                }\n                bool _1373 = _1309 <= 0.0;\n                bool _1380;\n                if (!_1373)\n                {\n                    _1380 = _314.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1380 = _1373;\n                }\n                float _1381;\n                if (_1380)\n                {\n                    _1381 = _314.fog_b.y * _1309;\n                }\n                else\n                {\n                    _1381 = (_314.fog_b.y * (1.0 - exp(-fast::min(_314.fog_b.w * _1309, 80.0)))) / _314.fog_b.w;\n                }\n                float _1408;\n                if (abs(_1299) < 0.001000000047497451305389404296875)\n                {\n                    _1408 = _1320;\n                }\n                else\n                {\n                    _1408 = (_1381 - _1348) / _1299;\n                }\n                tau += (_1249 * fast::max(_1408, 0.0));\n            }\n            float4 _1431 = out.frag_color;\n            float3 _1439 = mix(_1431.xyz, _314.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1439.x;\n            out.frag_color.y = _1439.y;\n            out.frag_color.z = _1439.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_314",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_370",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _105 = fa_linear_to_srgb(param);\n        c = _105;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _114 = fa_srgb_to_linear(param_1);\n            c = _114;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _151)\n{\n    float2 _158 = gl_FragCoord.xy * _151.fa_target.xy;\n    float _163 = _158.y;\n    return float2(_158.x, mix(_163, 1.0 - _163, _151.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _151, thread float2& uv, thread float4& color, thread float2& world_xy)\n{\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _151), _151.fa_time.x, base_mode, float4(0.0) };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _130 = fa_srgb_to_linear(param);\n        c = _130;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _136 = scene_rgb(param, xform);\n    return _136;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _210)\n{\n    float3 param = _210.tint.xyz;\n    float4 _217 = s.color;\n    float3 _219 = _217.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _219.x;\n    s.color.y = _219.y;\n    s.color.z = _219.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _151 [[buffer(1)]], constant fa_material& _210 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _238 = tex.sample(smp, in.uv);\n    float3 param = _238.xyz;\n    float param_1 = in.xform.y;\n    float3 _247 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_247, _238.w) * in.color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _151, in.uv, in.color, in.world_xy);\n    QuadSurface param_4 = QuadSurface{ out.frag_color };\n    fragment0(param_3, param_4, in.xform, _210);\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_151",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_210",
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
