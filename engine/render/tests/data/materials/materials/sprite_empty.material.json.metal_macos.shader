{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _266 = tex.sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _89 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = precise::atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = fast::min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _308, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _391 = _308.lit.y > 0.5;\n    if (_391)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _308.normal_uv.xy) + _308.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _415 = fa_tex_fix(param, param_1);\n        float3 _419 = (_415 * 2.0) - float3(1.0);\n        float _426 = cos(params.y);\n        float _428 = sin(params.y);\n        n = fast::normalize(float3((float2(_426, _428) * _419.x) + ((float2(-_428, _426) * ((mode > 5.5) ? (-1.0) : 1.0)) * _419.y), fast::max(_419.z, 0.0500000007450580596923828125)));\n    }\n    bool _462 = !_391;\n    bool _468;\n    if (_462)\n    {\n        _468 = _308.lit.z > 0.5;\n    }\n    else\n    {\n        _468 = _462;\n    }\n    float3 _471;\n    if (_468)\n    {\n        _471 = _308.flat_ambient.xyz;\n    }\n    else\n    {\n        _471 = _308.ambient.xyz;\n    }\n    float3 total = _471;\n    bool _488;\n    if (_468)\n    {\n        _488 = _308.lit.z < 1.5;\n    }\n    else\n    {\n        _488 = _468;\n    }\n    if (_488)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _308.light_map.xy), level(0.0)).xyz * _308.light_map.z);\n    }\n    float3 l;\n    float _606;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _528;\n        if (!_468)\n        {\n            _528 = float(i) >= _308.lit.x;\n        }\n        else\n        {\n            _528 = _468;\n        }\n        if (_528)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_308.light_pos[i].w < 0.0)\n        {\n            l = _308.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _554 = _308.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_554) / fast::max(_308.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _308.light_color[i].w);\n            float3 _574 = float3(_554, _308.light_pos[i].z);\n            l = _574 / float3(fast::max(length(_574), 9.9999997473787516355514526367188e-05));\n            if (_308.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _308.light_shadow_v[i].x;\n                float2 param_3 = -_554;\n                float param_4 = _308.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_391)\n        {\n            _606 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _606 = 1.0;\n        }\n        total += (_308.light_color[i].xyz * (att * _606));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _634 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _638 = uv * _634;\n    float _644 = _634.x;\n    float _646 = _634.y;\n    float _648 = fast::clamp(shape_rs.x, 0.0, fast::min(_644, _646));\n    float2 _659 = (abs(_638) - _634) + float2(_648);\n    float d = (length(fast::max(_659, float2(0.0))) + fast::min(fast::max(_659.x, _659.y), 0.0)) - _648;\n    float ax = params.y;\n    bool _680 = params.y > 15.0;\n    if (_680)\n    {\n        ax -= 20.0;\n    }\n    float _691;\n    if (ax <= (-1.5))\n    {\n        _691 = (-2.0) - ax;\n    }\n    else\n    {\n        _691 = 0.0;\n    }\n    if (_691 > 0.0)\n    {\n        float _705 = _691 * 0.5;\n        d = abs(d + _705) - _705;\n    }\n    float _713 = fwidth(d);\n    float _714 = fast::max(_713, 9.9999997473787516355514526367188e-05);\n    float _724 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _714)), 0.0, 1.0);\n    float _729;\n    if (shape_rs.y > _714)\n    {\n        _729 = (_724 * _724) * (3.0 - (2.0 * _724));\n    }\n    else\n    {\n        _729 = _724;\n    }\n    float4 c = color;\n    bool _751 = (_691 <= 0.0) && (ax > (-0.5));\n    if (_751)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _766 = cos(ax);\n            float _768 = sin(ax);\n            g = ((dot(_638, float2(_766, _768)) / fast::max((abs(_766) * _644) + (abs(_768) * _646), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_680)\n        {\n            float4 _811 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _811;\n            float3 param = _811.xyz;\n            float param_1 = xform.y;\n            float3 _818 = fa_tex_fix(param, param_1);\n            float4 _1514 = c;\n            _1514.x = _818.x;\n            _1514.y = _818.y;\n            _1514.z = _818.z;\n            c = _1514;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _830 = scene_rgb(param_2, xform);\n            float4 _855 = mix(float4(color.xyz * color.w, color.w), float4(_830 * color2.w, color2.w), float4(g));\n            float _857 = _855.w;\n            float3 _860;\n            if (_857 > 9.9999997473787516355514526367188e-06)\n            {\n                _860 = _855.xyz / float3(_857);\n            }\n            else\n            {\n                _860 = color.xyz;\n            }\n            c = float4(_860, _857);\n        }\n    }\n    float4 _1523 = c;\n    _1523.w = _1523.w * _729;\n    c = _1523;\n    if (_751 || (shape_rs.y > 0.0))\n    {\n        float _901 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _910 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _910 + float3(_901 * 0.0039215688593685626983642578125);\n            float3 _916 = fa_srgb_to_linear(param_4);\n            float4 _1526 = c;\n            _1526.x = _916.x;\n            _1526.y = _916.y;\n            _1526.z = _916.z;\n            c = _1526;\n        }\n        else\n        {\n            float4 _926 = c;\n            float3 _929 = _926.xyz + float3(_901 * 0.0039215688593685626983642578125);\n            float4 _1533 = _926;\n            _1533.x = _929.x;\n            _1533.y = _929.y;\n            _1533.z = _929.z;\n            c = _1533;\n        }\n        float4 _1538 = c;\n        _1538.w = fast::clamp(_1538.w + ((_901 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1538.w)), 0.0, 1.0);\n        c = _1538;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _308)\n{\n    float2 _315 = gl_FragCoord.xy * _308.fa_target.xy;\n    float _319 = _315.y;\n    return float2(_315.x, mix(_319, 1.0 - _319, _308.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _308, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _361 = base_mode < 0.5;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _308), _308.fa_time.x, base_mode, float4(0.0), _373 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _308 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _956 = in.params.x > 31.5;\n    if (_956)\n    {\n        mode -= 32.0;\n    }\n    float _964 = mode;\n    bool _966 = _964 > 15.5;\n    if (_966)\n    {\n        mode -= 16.0;\n    }\n    float _974 = mode;\n    bool _976 = _974 > 7.5;\n    if (_976)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_966)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_966)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1040 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1040;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1040.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1075 = length(in.uv);\n                    float _1078 = fwidth(_1075);\n                    float _1079 = fast::max(_1078, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1075) / _1079) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1075) / _1079) + 0.5, 0.0, 1.0) * fast::clamp(((_1075 - in.params.y) / _1079) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1119 = fast::clamp(1.0 - _1075, 0.0, 1.0);\n                            cov = (_1119 * _1119) * (3.0 - (2.0 * _1119));\n                        }\n                    }\n                    float3 _1128;\n                    if (_966)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1128 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _308, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1128 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1128, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1467 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _308, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1467 };\n    fragment0(param_11, param_12);\n    _1467 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_956)\n    {\n        float4 _1166 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1171 = scene_rgb(param_13, in.xform);\n        float3 _1175 = mix(_1166.xyz, _1171, float3(in.color2.w));\n        out.frag_color.x = _1175.x;\n        out.frag_color.y = _1175.y;\n        out.frag_color.z = _1175.z;\n    }\n    if (_976)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1199 = _308.fog_col.w > 0.0;\n    bool _1207;\n    if (!_1199)\n    {\n        _1207 = _308.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1207 = _1199;\n    }\n    if (_1207)\n    {\n        float3 _1221 = float3(in.world_xy, in.world_z) - _308.fog_eye.xyz;\n        float _1228 = dot(_1221, _308.fog_c.xyz);\n        bool _1232 = _308.fog_c.w > 0.5;\n        float _1233;\n        if (_1232)\n        {\n            _1233 = _1228;\n        }\n        else\n        {\n            _1233 = length(_1221);\n        }\n        float _1245 = _1233 - _308.fog_b.x;\n        if (_1245 > 0.0)\n        {\n            float _1254 = _308.fog_col.w * _1245;\n            float tau = _1254 * _1254;\n            if (_308.fog_b.y > 0.0)\n            {\n                float _1270;\n                if (_1232)\n                {\n                    _1270 = in.world_xy.y - (_308.fog_c.y * _1228);\n                }\n                else\n                {\n                    _1270 = _308.fog_eye.y;\n                }\n                float _1291 = mix(_1270, in.world_xy.y, fast::clamp(_308.fog_b.x / _1233, 0.0, 1.0));\n                float _1295 = in.world_xy.y - _1291;\n                float _1300 = _1291 - _308.fog_b.z;\n                float _1305 = in.world_xy.y - _308.fog_b.z;\n                bool _1308 = _1300 <= 0.0;\n                bool _1309 = !_1308;\n                bool _1315;\n                if (_1309)\n                {\n                    _1315 = _308.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1315 = _1308;\n                }\n                float _1316;\n                if (_1315)\n                {\n                    _1316 = _308.fog_b.y;\n                }\n                else\n                {\n                    _1316 = _308.fog_b.y * exp(-fast::min(_308.fog_b.w * _1300, 80.0));\n                }\n                bool _1343;\n                if (_1309)\n                {\n                    _1343 = _308.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1343 = _1308;\n                }\n                float _1344;\n                if (_1343)\n                {\n                    _1344 = _308.fog_b.y * _1300;\n                }\n                else\n                {\n                    _1344 = (_308.fog_b.y * (1.0 - exp(-fast::min(_308.fog_b.w * _1300, 80.0)))) / _308.fog_b.w;\n                }\n                bool _1369 = _1305 <= 0.0;\n                bool _1376;\n                if (!_1369)\n                {\n                    _1376 = _308.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1376 = _1369;\n                }\n                float _1377;\n                if (_1376)\n                {\n                    _1377 = _308.fog_b.y * _1305;\n                }\n                else\n                {\n                    _1377 = (_308.fog_b.y * (1.0 - exp(-fast::min(_308.fog_b.w * _1305, 80.0)))) / _308.fog_b.w;\n                }\n                float _1404;\n                if (abs(_1295) < 0.001000000047497451305389404296875)\n                {\n                    _1404 = _1316;\n                }\n                else\n                {\n                    _1404 = (_1377 - _1344) / _1295;\n                }\n                tau += (_1245 * fast::max(_1404, 0.0));\n            }\n            float4 _1427 = out.frag_color;\n            float3 _1435 = mix(_1427.xyz, _308.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1435.x;\n            out.frag_color.y = _1435.y;\n            out.frag_color.z = _1435.z;\n        }\n    }\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _127)\n{\n    float2 _134 = gl_FragCoord.xy * _127.fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, mix(_140, 1.0 - _140, _127.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _127, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _127), _127.fa_time.x, base_mode, float4(0.0), _196 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _127 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _221 = tex.sample(smp, in.uv);\n    float3 param = _221.xyz;\n    float param_1 = in.xform.y;\n    float3 _232 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_232, _221.w) * in.color;\n    float param_2 = 0.0;\n    float4 _286 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _127, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _286 };\n    fragment0(param_3, param_4);\n    _286 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
