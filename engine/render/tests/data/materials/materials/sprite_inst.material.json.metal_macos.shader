{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _264 = fa_srgb_to_linear(param_1);\n            c = _264;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _275 = tex.sample(smp, p);\n    float3 param = _275.xyz;\n    float param_1 = xform.y;\n    float3 _285 = fa_tex_fix(param, param_1);\n    return float4(_285, _275.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _98 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_98.x * 255.0) + 0.5) * 256.0) + floor((_98.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _122 = length(d);\n    if (_122 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _136 = precise::atan2(d.y, d.x);\n    float a = _136;\n    float _139;\n    if (_136 < 0.0)\n    {\n        _139 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _139 = a;\n    }\n    a = _139;\n    float _151 = _139 * 162.9746551513671875;\n    float _156 = fast::min(floor(_151), 1023.0);\n    float _163 = _156 + 1.0;\n    float i1 = _163;\n    if (_163 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _156;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _122) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _122) + 0.5, 0.0, 1.0), _151 - _156);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _322, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _436 = _322.lit.y > 0.5;\n    if (_436)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _322.normal_uv.xy) + _322.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _460 = fa_tex_fix(param, param_1);\n        float3 _464 = (_460 * 2.0) - float3(1.0);\n        float _471 = cos(params.y);\n        float _473 = sin(params.y);\n        n = fast::normalize(float3((float2(_471, _473) * _464.x) + ((float2(-_473, _471) * ((mode > 5.5) ? (-1.0) : 1.0)) * _464.y), fast::max(_464.z, 0.0500000007450580596923828125)));\n    }\n    bool _507 = !_436;\n    bool _513;\n    if (_507)\n    {\n        _513 = _322.lit.z > 0.5;\n    }\n    else\n    {\n        _513 = _507;\n    }\n    float3 _516;\n    if (_513)\n    {\n        _516 = _322.flat_ambient.xyz;\n    }\n    else\n    {\n        _516 = _322.ambient.xyz;\n    }\n    float3 total = _516;\n    bool _533;\n    if (_513)\n    {\n        _533 = _322.lit.z < 1.5;\n    }\n    else\n    {\n        _533 = _513;\n    }\n    if (_533)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _322.light_map.xy), level(0.0)).xyz * _322.light_map.z);\n    }\n    float3 l;\n    float _651;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _573;\n        if (!_513)\n        {\n            _573 = float(i) >= _322.lit.x;\n        }\n        else\n        {\n            _573 = _513;\n        }\n        if (_573)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_322.light_pos[i].w < 0.0)\n        {\n            l = _322.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _599 = _322.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_599) / fast::max(_322.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _322.light_color[i].w);\n            float3 _619 = float3(_599, _322.light_pos[i].z);\n            l = _619 / float3(fast::max(length(_619), 9.9999997473787516355514526367188e-05));\n            if (_322.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _322.light_shadow_v[i].x;\n                float2 param_3 = -_599;\n                float param_4 = _322.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_436)\n        {\n            _651 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _651 = 1.0;\n        }\n        total += (_322.light_color[i].xyz * (att * _651));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _302 = fa_srgb_to_linear(param);\n        c = _302;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _679 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _683 = uv * _679;\n    float _689 = _679.x;\n    float _691 = _679.y;\n    float _693 = fast::clamp(shape_rs.x, 0.0, fast::min(_689, _691));\n    float2 _704 = (abs(_683) - _679) + float2(_693);\n    float d = (length(fast::max(_704, float2(0.0))) + fast::min(fast::max(_704.x, _704.y), 0.0)) - _693;\n    float ax = params.y;\n    bool _725 = params.y > 15.0;\n    if (_725)\n    {\n        ax -= 20.0;\n    }\n    float _736;\n    if (ax <= (-1.5))\n    {\n        _736 = (-2.0) - ax;\n    }\n    else\n    {\n        _736 = 0.0;\n    }\n    if (_736 > 0.0)\n    {\n        float _750 = _736 * 0.5;\n        d = abs(d + _750) - _750;\n    }\n    float _758 = fwidth(d);\n    float _759 = fast::max(_758, 9.9999997473787516355514526367188e-05);\n    float _769 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _759)), 0.0, 1.0);\n    float _774;\n    if (shape_rs.y > _759)\n    {\n        _774 = (_769 * _769) * (3.0 - (2.0 * _769));\n    }\n    else\n    {\n        _774 = _769;\n    }\n    float4 c = color;\n    bool _796 = (_736 <= 0.0) && (ax > (-0.5));\n    if (_796)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _811 = cos(ax);\n            float _813 = sin(ax);\n            g = ((dot(_683, float2(_811, _813)) / fast::max((abs(_811) * _689) + (abs(_813) * _691), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_725)\n        {\n            float4 _856 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _856;\n            float3 param = _856.xyz;\n            float param_1 = xform.y;\n            float3 _863 = fa_tex_fix(param, param_1);\n            float4 _1559 = c;\n            _1559.x = _863.x;\n            _1559.y = _863.y;\n            _1559.z = _863.z;\n            c = _1559;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _875 = scene_rgb(param_2, xform);\n            float4 _900 = mix(float4(color.xyz * color.w, color.w), float4(_875 * color2.w, color2.w), float4(g));\n            float _902 = _900.w;\n            float3 _905;\n            if (_902 > 9.9999997473787516355514526367188e-06)\n            {\n                _905 = _900.xyz / float3(_902);\n            }\n            else\n            {\n                _905 = color.xyz;\n            }\n            c = float4(_905, _902);\n        }\n    }\n    float4 _1568 = c;\n    _1568.w = _1568.w * _774;\n    c = _1568;\n    if (_796 || (shape_rs.y > 0.0))\n    {\n        float _946 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _955 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _955 + float3(_946 * 0.0039215688593685626983642578125);\n            float3 _961 = fa_srgb_to_linear(param_4);\n            float4 _1571 = c;\n            _1571.x = _961.x;\n            _1571.y = _961.y;\n            _1571.z = _961.z;\n            c = _1571;\n        }\n        else\n        {\n            float4 _971 = c;\n            float3 _974 = _971.xyz + float3(_946 * 0.0039215688593685626983642578125);\n            float4 _1578 = _971;\n            _1578.x = _974.x;\n            _1578.y = _974.y;\n            _1578.z = _974.z;\n            c = _1578;\n        }\n        float4 _1583 = c;\n        _1583.w = fast::clamp(_1583.w + ((_946 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1583.w)), 0.0, 1.0);\n        c = _1583;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _322)\n{\n    float2 _329 = gl_FragCoord.xy * _322.fa_target.xy;\n    float _333 = _329.y;\n    return float2(_329.x, mix(_333, 1.0 - _333, _322.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _322, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _375 = base_mode < 0.5;\n    bool _386;\n    if (!_375)\n    {\n        _386 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _386 = _375;\n    }\n    float _387;\n    if (_386)\n    {\n        _387 = shape_half.x;\n    }\n    else\n    {\n        _387 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _322), _322.fa_time.x, base_mode, float4(0.0), _387 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _308 = scene_rgb(param, xform);\n    return _308;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _412)\n{\n    float3 param = tint.xyz;\n    float3 _415 = fa_scene_rgb(param, xform) * _412.boost;\n    s.color.x = _415.x;\n    s.color.y = _415.y;\n    s.color.z = _415.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _322 [[buffer(1)]], constant fa_material& _412 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1001 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1001)\n    {\n        mode -= 32.0;\n    }\n    float _1009 = mode;\n    bool _1011 = _1009 > 15.5;\n    if (_1011)\n    {\n        mode -= 16.0;\n    }\n    float _1019 = mode;\n    bool _1021 = _1019 > 7.5;\n    if (_1021)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1011)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _322, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1011)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _322, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1085 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1085;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _322, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1085.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1120 = length(in.uv);\n                    float _1123 = fwidth(_1120);\n                    float _1124 = fast::max(_1123, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1120) / _1124) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1120) / _1124) + 0.5, 0.0, 1.0) * fast::clamp(((_1120 - in.params.y) / _1124) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1164 = fast::clamp(1.0 - _1120, 0.0, 1.0);\n                            cov = (_1164 * _1164) * (3.0 - (2.0 * _1164));\n                        }\n                    }\n                    float3 _1173;\n                    if (_1011)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1173 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _322, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1173 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1173, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1512 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _322, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1512 };\n    fragment0(param_11, param_12, in.xform, tint, _412);\n    _1512 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1001)\n    {\n        float4 _1211 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1216 = scene_rgb(param_13, in.xform);\n        float3 _1220 = mix(_1211.xyz, _1216, float3(in.color2.w));\n        out.frag_color.x = _1220.x;\n        out.frag_color.y = _1220.y;\n        out.frag_color.z = _1220.z;\n    }\n    if (_1021)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1244 = _322.fog_col.w > 0.0;\n    bool _1252;\n    if (!_1244)\n    {\n        _1252 = _322.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1252 = _1244;\n    }\n    if (_1252)\n    {\n        float3 _1266 = float3(in.world_xy, in.world_z) - _322.fog_eye.xyz;\n        float _1273 = dot(_1266, _322.fog_c.xyz);\n        bool _1277 = _322.fog_c.w > 0.5;\n        float _1278;\n        if (_1277)\n        {\n            _1278 = _1273;\n        }\n        else\n        {\n            _1278 = length(_1266);\n        }\n        float _1290 = _1278 - _322.fog_b.x;\n        if (_1290 > 0.0)\n        {\n            float _1299 = _322.fog_col.w * _1290;\n            float tau = _1299 * _1299;\n            if (_322.fog_b.y > 0.0)\n            {\n                float _1315;\n                if (_1277)\n                {\n                    _1315 = in.world_xy.y - (_322.fog_c.y * _1273);\n                }\n                else\n                {\n                    _1315 = _322.fog_eye.y;\n                }\n                float _1336 = mix(_1315, in.world_xy.y, fast::clamp(_322.fog_b.x / _1278, 0.0, 1.0));\n                float _1340 = in.world_xy.y - _1336;\n                float _1345 = _1336 - _322.fog_b.z;\n                float _1350 = in.world_xy.y - _322.fog_b.z;\n                bool _1353 = _1345 <= 0.0;\n                bool _1354 = !_1353;\n                bool _1360;\n                if (_1354)\n                {\n                    _1360 = _322.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1360 = _1353;\n                }\n                float _1361;\n                if (_1360)\n                {\n                    _1361 = _322.fog_b.y;\n                }\n                else\n                {\n                    _1361 = _322.fog_b.y * exp(-fast::min(_322.fog_b.w * _1345, 80.0));\n                }\n                bool _1388;\n                if (_1354)\n                {\n                    _1388 = _322.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1388 = _1353;\n                }\n                float _1389;\n                if (_1388)\n                {\n                    _1389 = _322.fog_b.y * _1345;\n                }\n                else\n                {\n                    _1389 = (_322.fog_b.y * (1.0 - exp(-fast::min(_322.fog_b.w * _1345, 80.0)))) / _322.fog_b.w;\n                }\n                bool _1414 = _1350 <= 0.0;\n                bool _1421;\n                if (!_1414)\n                {\n                    _1421 = _322.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1421 = _1414;\n                }\n                float _1422;\n                if (_1421)\n                {\n                    _1422 = _322.fog_b.y * _1350;\n                }\n                else\n                {\n                    _1422 = (_322.fog_b.y * (1.0 - exp(-fast::min(_322.fog_b.w * _1350, 80.0)))) / _322.fog_b.w;\n                }\n                float _1449;\n                if (abs(_1340) < 0.001000000047497451305389404296875)\n                {\n                    _1449 = _1361;\n                }\n                else\n                {\n                    _1449 = (_1422 - _1389) / _1340;\n                }\n                tau += (_1290 * fast::max(_1449, 0.0));\n            }\n            float4 _1472 = out.frag_color;\n            float3 _1480 = mix(_1472.xyz, _322.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1480.x;\n            out.frag_color.y = _1480.y;\n            out.frag_color.z = _1480.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_322",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_412",
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
