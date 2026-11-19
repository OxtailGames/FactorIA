{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
  "slang": "glsl430",
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _264 = fa_srgb_to_linear(param_1);\n            c = _264;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _275 = texture(tex_smp, p);\n    vec3 param = _275.xyz;\n    float param_1 = xform.y;\n    vec3 _285 = fa_tex_fix(param, param_1);\n    return vec4(_285, _275.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _98 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_98.x * 255.0) + 0.5) * 256.0) + floor((_98.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _122 = length(d);\n    if (_122 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _136 = atan(d.y, d.x);\n    float a = _136;\n    float _139;\n    if (_136 < 0.0)\n    {\n        _139 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _139 = a;\n    }\n    a = _139;\n    float _151 = _139 * 162.9746551513671875;\n    float _156 = min(floor(_151), 1023.0);\n    float _163 = _156 + 1.0;\n    float i1 = _163;\n    if (_163 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _156;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _122) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _122) + 0.5, 0.0, 1.0), _151 - _156);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _436 = quad_fs_params[0].y > 0.5;\n    if (_436)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _460 = fa_tex_fix(param, param_1);\n        vec3 _464 = (_460 * 2.0) - vec3(1.0);\n        float _471 = cos(params.y);\n        float _473 = sin(params.y);\n        n = normalize(vec3((vec2(_471, _473) * _464.x) + ((vec2(-_473, _471) * ((mode > 5.5) ? (-1.0) : 1.0)) * _464.y), max(_464.z, 0.0500000007450580596923828125)));\n    }\n    bool _507 = !_436;\n    bool _513;\n    if (_507)\n    {\n        _513 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _513 = _507;\n    }\n    vec3 _516;\n    if (_513)\n    {\n        _516 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _516 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _516;\n    bool _533;\n    if (_513)\n    {\n        _533 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _533 = _513;\n    }\n    if (_533)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _651;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _573;\n        if (!_513)\n        {\n            _573 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _573 = _513;\n        }\n        if (_573)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _599 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_599) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _619 = vec3(_599, quad_fs_params[i * 1 + 5].z);\n            l = _619 / vec3(max(length(_619), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_599;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_436)\n        {\n            _651 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _651 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _651));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _302 = fa_srgb_to_linear(param);\n        c = _302;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _679 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _683 = uv * _679;\n    float _689 = _679.x;\n    float _691 = _679.y;\n    float _693 = clamp(shape_rs.x, 0.0, min(_689, _691));\n    vec2 _704 = (abs(_683) - _679) + vec2(_693);\n    float d = (length(max(_704, vec2(0.0))) + min(max(_704.x, _704.y), 0.0)) - _693;\n    float ax = params.y;\n    bool _725 = params.y > 15.0;\n    if (_725)\n    {\n        ax -= 20.0;\n    }\n    float _736;\n    if (ax <= (-1.5))\n    {\n        _736 = (-2.0) - ax;\n    }\n    else\n    {\n        _736 = 0.0;\n    }\n    if (_736 > 0.0)\n    {\n        float _750 = _736 * 0.5;\n        d = abs(d + _750) - _750;\n    }\n    float _758 = fwidth(d);\n    float _759 = max(_758, 9.9999997473787516355514526367188e-05);\n    float _769 = clamp(0.5 - (d / max(shape_rs.y, _759)), 0.0, 1.0);\n    float _774;\n    if (shape_rs.y > _759)\n    {\n        _774 = (_769 * _769) * (3.0 - (2.0 * _769));\n    }\n    else\n    {\n        _774 = _769;\n    }\n    vec4 c = color;\n    bool _796 = (_736 <= 0.0) && (ax > (-0.5));\n    if (_796)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _811 = cos(ax);\n            float _813 = sin(ax);\n            g = ((dot(_683, vec2(_811, _813)) / max((abs(_811) * _689) + (abs(_813) * _691), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_725)\n        {\n            vec4 _856 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _856;\n            vec3 param = _856.xyz;\n            float param_1 = xform.y;\n            vec3 _863 = fa_tex_fix(param, param_1);\n            vec4 _1559 = c;\n            _1559.x = _863.x;\n            _1559.y = _863.y;\n            _1559.z = _863.z;\n            c = _1559;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _875 = scene_rgb(param_2);\n            vec4 _900 = mix(vec4(color.xyz * color.w, color.w), vec4(_875 * color2.w, color2.w), vec4(g));\n            float _902 = _900.w;\n            vec3 _905;\n            if (_902 > 9.9999997473787516355514526367188e-06)\n            {\n                _905 = _900.xyz / vec3(_902);\n            }\n            else\n            {\n                _905 = color.xyz;\n            }\n            c = vec4(_905, _902);\n        }\n    }\n    vec4 _1568 = c;\n    _1568.w = _1568.w * _774;\n    c = _1568;\n    if (_796 || (shape_rs.y > 0.0))\n    {\n        float _946 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _955 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _955 + vec3(_946 * 0.0039215688593685626983642578125);\n            vec3 _961 = fa_srgb_to_linear(param_4);\n            vec4 _1571 = c;\n            _1571.x = _961.x;\n            _1571.y = _961.y;\n            _1571.z = _961.z;\n            c = _1571;\n        }\n        else\n        {\n            vec4 _971 = c;\n            vec3 _974 = _971.xyz + vec3(_946 * 0.0039215688593685626983642578125);\n            vec4 _1578 = _971;\n            _1578.x = _974.x;\n            _1578.y = _974.y;\n            _1578.z = _974.z;\n            c = _1578;\n        }\n        vec4 _1583 = c;\n        _1583.w = clamp(_1583.w + ((_946 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1583.w)), 0.0, 1.0);\n        c = _1583;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _329 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _333 = _329.y;\n    return vec2(_329.x, mix(_333, 1.0 - _333, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _375 = base_mode < 0.5;\n    bool _386;\n    if (!_375)\n    {\n        _386 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _386 = _375;\n    }\n    float _387;\n    if (_386)\n    {\n        _387 = shape_half.x;\n    }\n    else\n    {\n        _387 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _387);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _308 = scene_rgb(param);\n    return _308;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _415 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _415.x;\n    s.color.y = _415.y;\n    s.color.z = _415.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1001 = params.x > 31.5;\n    if (_1001)\n    {\n        mode -= 32.0;\n    }\n    float _1009 = mode;\n    bool _1011 = _1009 > 15.5;\n    if (_1011)\n    {\n        mode -= 16.0;\n    }\n    float _1019 = mode;\n    bool _1021 = _1019 > 7.5;\n    if (_1021)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1011)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1011)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1085 = tex_color(param_5) * color;\n                vec4 param_6 = _1085;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1085.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1120 = length(uv);\n                    float _1123 = fwidth(_1120);\n                    float _1124 = max(_1123, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1120) / _1124) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1120) / _1124) + 0.5, 0.0, 1.0) * clamp(((_1120 - params.y) / _1124) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1164 = clamp(1.0 - _1120, 0.0, 1.0);\n                            cov = (_1164 * _1164) * (3.0 - (2.0 * _1164));\n                        }\n                    }\n                    vec3 _1173;\n                    if (_1011)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1173 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1173 = color.xyz;\n                    }\n                    frag_color = vec4(_1173, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1512 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1512);\n    fragment(param_11, param_12);\n    _1512 = param_12.color;\n    frag_color = param_12.color;\n    if (_1001)\n    {\n        vec4 _1211 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1216 = scene_rgb(param_13);\n        vec3 _1220 = mix(_1211.xyz, _1216, vec3(color2.w));\n        frag_color.x = _1220.x;\n        frag_color.y = _1220.y;\n        frag_color.z = _1220.z;\n    }\n    if (_1021)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1244 = quad_fs_params[53].w > 0.0;\n    bool _1252;\n    if (!_1244)\n    {\n        _1252 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1252 = _1244;\n    }\n    if (_1252)\n    {\n        vec3 _1266 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1273 = dot(_1266, quad_fs_params[55].xyz);\n        bool _1277 = quad_fs_params[55].w > 0.5;\n        float _1278;\n        if (_1277)\n        {\n            _1278 = _1273;\n        }\n        else\n        {\n            _1278 = length(_1266);\n        }\n        float _1290 = _1278 - quad_fs_params[54].x;\n        if (_1290 > 0.0)\n        {\n            float _1299 = quad_fs_params[53].w * _1290;\n            float tau = _1299 * _1299;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1315;\n                if (_1277)\n                {\n                    _1315 = world_xy.y - (quad_fs_params[55].y * _1273);\n                }\n                else\n                {\n                    _1315 = quad_fs_params[56].y;\n                }\n                float _1336 = mix(_1315, world_xy.y, clamp(quad_fs_params[54].x / _1278, 0.0, 1.0));\n                float _1340 = world_xy.y - _1336;\n                float _1345 = _1336 - quad_fs_params[54].z;\n                float _1350 = world_xy.y - quad_fs_params[54].z;\n                bool _1353 = _1345 <= 0.0;\n                bool _1354 = !_1353;\n                bool _1360;\n                if (_1354)\n                {\n                    _1360 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1360 = _1353;\n                }\n                float _1361;\n                if (_1360)\n                {\n                    _1361 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1361 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1345, 80.0));\n                }\n                bool _1388;\n                if (_1354)\n                {\n                    _1388 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1388 = _1353;\n                }\n                float _1389;\n                if (_1388)\n                {\n                    _1389 = quad_fs_params[54].y * _1345;\n                }\n                else\n                {\n                    _1389 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1345, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1414 = _1350 <= 0.0;\n                bool _1421;\n                if (!_1414)\n                {\n                    _1421 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1421 = _1414;\n                }\n                float _1422;\n                if (_1421)\n                {\n                    _1422 = quad_fs_params[54].y * _1350;\n                }\n                else\n                {\n                    _1422 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1350, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1449;\n                if (abs(_1340) < 0.001000000047497451305389404296875)\n                {\n                    _1449 = _1361;\n                }\n                else\n                {\n                    _1449 = (_1422 - _1389) / _1340;\n                }\n                tau += (_1290 * max(_1449, 0.0));\n            }\n            vec4 _1472 = frag_color;\n            vec3 _1480 = mix(_1472.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1480.x;\n            frag_color.y = _1480.y;\n            frag_color.z = _1480.z;\n        }\n    }\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "position"
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "texcoord0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "color0"
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "params0"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "color2_0"
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "shape_half0"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "shape_rs0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 6,
                "offset": 0,
                "glsl_name": "vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_322",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
                "offset": 0,
                "glsl_name": "quad_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_412",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "shadow_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 0,
            "glsl_name": "tex_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0,
            "glsl_name": "normal_tex_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1,
            "glsl_name": "light_tex_light_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2,
            "glsl_name": "shadow_tex_shadow_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _167 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _172 = _167.y;\n    return vec2(_167.x, mix(_172, 1.0 - _172, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _215 = base_mode < 0.5;\n    bool _226;\n    if (!_215)\n    {\n        _226 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _226 = _215;\n    }\n    float _227;\n    if (_226)\n    {\n        _227 = shape_half.x;\n    }\n    else\n    {\n        _227 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _227);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _255 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _255.x;\n    s.color.y = _255.y;\n    s.color.z = _255.z;\n}\n\nvoid main()\n{\n    vec4 _282 = texture(tex_smp, uv);\n    vec3 param = _282.xyz;\n    float param_1 = xform.y;\n    vec3 _291 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_291, _282.w) * color;\n    float param_2 = 0.0;\n    vec4 _345 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_345);\n    fragment(param_3, param_4);\n    _345 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "position"
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "texcoord0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "color0"
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "params0"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "color2_0"
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "shape_half0"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "shape_rs0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 6,
                "offset": 0,
                "glsl_name": "vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_160",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
                "offset": 0,
                "glsl_name": "quad_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_252",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
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
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 0,
            "glsl_name": "tex_smp"
          }
        ]
      }
    }
  }
}
