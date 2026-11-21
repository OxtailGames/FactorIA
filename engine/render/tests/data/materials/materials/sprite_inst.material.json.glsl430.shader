{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _264 = fa_srgb_to_linear(param_1);\n            c = _264;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _275 = texture(tex_smp, p);\n    vec3 param = _275.xyz;\n    float param_1 = xform.y;\n    vec3 _285 = fa_tex_fix(param, param_1);\n    return vec4(_285, _275.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _98 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_98.x * 255.0) + 0.5) * 256.0) + floor((_98.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _122 = length(d);\n    if (_122 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _136 = atan(d.y, d.x);\n    float a = _136;\n    float _139;\n    if (_136 < 0.0)\n    {\n        _139 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _139 = a;\n    }\n    a = _139;\n    float _151 = _139 * 162.9746551513671875;\n    float _156 = min(floor(_151), 1023.0);\n    float _163 = _156 + 1.0;\n    float i1 = _163;\n    if (_163 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _156;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _122) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _122) + 0.5, 0.0, 1.0), _151 - _156);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _437 = quad_fs_params[0].y > 0.5;\n    if (_437)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _461 = fa_tex_fix(param, param_1);\n        vec3 _465 = (_461 * 2.0) - vec3(1.0);\n        float _472 = cos(params.y);\n        float _474 = sin(params.y);\n        n = normalize(vec3((vec2(_472, _474) * _465.x) + ((vec2(-_474, _472) * ((mode > 5.5) ? (-1.0) : 1.0)) * _465.y), max(_465.z, 0.0500000007450580596923828125)));\n    }\n    bool _508 = !_437;\n    bool _514;\n    if (_508)\n    {\n        _514 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _514 = _508;\n    }\n    vec3 _517;\n    if (_514)\n    {\n        _517 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _517 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _517;\n    bool _534;\n    if (_514)\n    {\n        _534 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _534 = _514;\n    }\n    if (_534)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _652;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _574;\n        if (!_514)\n        {\n            _574 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _574 = _514;\n        }\n        if (_574)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _600 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_600) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _620 = vec3(_600, quad_fs_params[i * 1 + 5].z);\n            l = _620 / vec3(max(length(_620), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_600;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_437)\n        {\n            _652 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _652 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _652));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _302 = fa_srgb_to_linear(param);\n        c = _302;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _680 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _684 = uv * _680;\n    float _690 = _680.x;\n    float _692 = _680.y;\n    float _694 = clamp(shape_rs.x, 0.0, min(_690, _692));\n    vec2 _705 = (abs(_684) - _680) + vec2(_694);\n    float d = (length(max(_705, vec2(0.0))) + min(max(_705.x, _705.y), 0.0)) - _694;\n    float ax = params.y;\n    bool _726 = params.y > 15.0;\n    if (_726)\n    {\n        ax -= 20.0;\n    }\n    float _737;\n    if (ax <= (-1.5))\n    {\n        _737 = (-2.0) - ax;\n    }\n    else\n    {\n        _737 = 0.0;\n    }\n    if (_737 > 0.0)\n    {\n        float _751 = _737 * 0.5;\n        d = abs(d + _751) - _751;\n    }\n    float _759 = fwidth(d);\n    float _760 = max(_759, 9.9999997473787516355514526367188e-05);\n    float _770 = clamp(0.5 - (d / max(shape_rs.y, _760)), 0.0, 1.0);\n    float _775;\n    if (shape_rs.y > _760)\n    {\n        _775 = (_770 * _770) * (3.0 - (2.0 * _770));\n    }\n    else\n    {\n        _775 = _770;\n    }\n    vec4 c = color;\n    bool _797 = (_737 <= 0.0) && (ax > (-0.5));\n    if (_797)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _812 = cos(ax);\n            float _814 = sin(ax);\n            g = ((dot(_684, vec2(_812, _814)) / max((abs(_812) * _690) + (abs(_814) * _692), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_726)\n        {\n            vec4 _857 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _857;\n            vec3 param = _857.xyz;\n            float param_1 = xform.y;\n            vec3 _864 = fa_tex_fix(param, param_1);\n            vec4 _1561 = c;\n            _1561.x = _864.x;\n            _1561.y = _864.y;\n            _1561.z = _864.z;\n            c = _1561;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _876 = scene_rgb(param_2);\n            vec4 _901 = mix(vec4(color.xyz * color.w, color.w), vec4(_876 * color2.w, color2.w), vec4(g));\n            float _903 = _901.w;\n            vec3 _906;\n            if (_903 > 9.9999997473787516355514526367188e-06)\n            {\n                _906 = _901.xyz / vec3(_903);\n            }\n            else\n            {\n                _906 = color.xyz;\n            }\n            c = vec4(_906, _903);\n        }\n    }\n    vec4 _1570 = c;\n    _1570.w = _1570.w * _775;\n    c = _1570;\n    if (_797 || (shape_rs.y > 0.0))\n    {\n        float _947 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _956 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _956 + vec3(_947 * 0.0039215688593685626983642578125);\n            vec3 _962 = fa_srgb_to_linear(param_4);\n            vec4 _1573 = c;\n            _1573.x = _962.x;\n            _1573.y = _962.y;\n            _1573.z = _962.z;\n            c = _1573;\n        }\n        else\n        {\n            vec4 _972 = c;\n            vec3 _975 = _972.xyz + vec3(_947 * 0.0039215688593685626983642578125);\n            vec4 _1580 = _972;\n            _1580.x = _975.x;\n            _1580.y = _975.y;\n            _1580.z = _975.z;\n            c = _1580;\n        }\n        vec4 _1585 = c;\n        _1585.w = clamp(_1585.w + ((_947 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1585.w)), 0.0, 1.0);\n        c = _1585;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _330 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _334 = _330.y;\n    return vec2(_330.x, mix(_334, 1.0 - _334, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _376 = base_mode < 0.5;\n    bool _387;\n    if (!_376)\n    {\n        _387 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _387 = _376;\n    }\n    float _388;\n    if (_387)\n    {\n        _388 = shape_half.x;\n    }\n    else\n    {\n        _388 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _388);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _308 = scene_rgb(param);\n    return _308;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _416 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _416.x;\n    s.color.y = _416.y;\n    s.color.z = _416.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1002 = params.x > 31.5;\n    if (_1002)\n    {\n        mode -= 32.0;\n    }\n    float _1010 = mode;\n    bool _1012 = _1010 > 15.5;\n    if (_1012)\n    {\n        mode -= 16.0;\n    }\n    float _1020 = mode;\n    bool _1022 = _1020 > 7.5;\n    if (_1022)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1012)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1012)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1086 = tex_color(param_5) * color;\n                vec4 param_6 = _1086;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1086.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1121 = length(uv);\n                    float _1124 = fwidth(_1121);\n                    float _1125 = max(_1124, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1121) / _1125) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1121) / _1125) + 0.5, 0.0, 1.0) * clamp(((_1121 - params.y) / _1125) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1165 = clamp(1.0 - _1121, 0.0, 1.0);\n                            cov = (_1165 * _1165) * (3.0 - (2.0 * _1165));\n                        }\n                    }\n                    vec3 _1174;\n                    if (_1012)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1174 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1174 = color.xyz;\n                    }\n                    frag_color = vec4(_1174, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1514 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1514);\n    fragment(param_11, param_12);\n    _1514 = param_12.color;\n    frag_color = param_12.color;\n    if (_1002)\n    {\n        vec4 _1212 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1217 = scene_rgb(param_13);\n        vec3 _1221 = mix(_1212.xyz, _1217, vec3(color2.w));\n        frag_color.x = _1221.x;\n        frag_color.y = _1221.y;\n        frag_color.z = _1221.z;\n    }\n    if (_1022)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1245 = quad_fs_params[53].w > 0.0;\n    bool _1253;\n    if (!_1245)\n    {\n        _1253 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1253 = _1245;\n    }\n    if (_1253)\n    {\n        vec3 _1267 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1274 = dot(_1267, quad_fs_params[55].xyz);\n        bool _1278 = quad_fs_params[55].w > 0.5;\n        float _1279;\n        if (_1278)\n        {\n            _1279 = _1274;\n        }\n        else\n        {\n            _1279 = length(_1267);\n        }\n        float _1291 = _1279 - quad_fs_params[54].x;\n        if (_1291 > 0.0)\n        {\n            float _1300 = quad_fs_params[53].w * _1291;\n            float tau = _1300 * _1300;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1316;\n                if (_1278)\n                {\n                    _1316 = world_xy.y - (quad_fs_params[55].y * _1274);\n                }\n                else\n                {\n                    _1316 = quad_fs_params[56].y;\n                }\n                float _1337 = mix(_1316, world_xy.y, clamp(quad_fs_params[54].x / _1279, 0.0, 1.0));\n                float _1341 = world_xy.y - _1337;\n                float _1346 = _1337 - quad_fs_params[54].z;\n                float _1351 = world_xy.y - quad_fs_params[54].z;\n                bool _1354 = _1346 <= 0.0;\n                bool _1355 = !_1354;\n                bool _1361;\n                if (_1355)\n                {\n                    _1361 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1354;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1362 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1346, 80.0));\n                }\n                bool _1389;\n                if (_1355)\n                {\n                    _1389 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1389 = _1354;\n                }\n                float _1390;\n                if (_1389)\n                {\n                    _1390 = quad_fs_params[54].y * _1346;\n                }\n                else\n                {\n                    _1390 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1346, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1415 = _1351 <= 0.0;\n                bool _1422;\n                if (!_1415)\n                {\n                    _1422 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1422 = _1415;\n                }\n                float _1423;\n                if (_1422)\n                {\n                    _1423 = quad_fs_params[54].y * _1351;\n                }\n                else\n                {\n                    _1423 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1351, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1450;\n                if (abs(_1341) < 0.001000000047497451305389404296875)\n                {\n                    _1450 = _1362;\n                }\n                else\n                {\n                    _1450 = (_1423 - _1390) / _1341;\n                }\n                tau += (_1291 * max(_1450, 0.0));\n            }\n            vec4 _1473 = frag_color;\n            vec3 _1481 = mix(_1473.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1481.x;\n            frag_color.y = _1481.y;\n            frag_color.z = _1481.z;\n        }\n    }\n}\n\n",
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
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_323",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
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
            "inst_name": "_413",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _169 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _174 = _169.y;\n    return vec2(_169.x, mix(_174, 1.0 - _174, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _229);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _257 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nvoid main()\n{\n    vec4 _284 = texture(tex_smp, uv);\n    vec3 param = _284.xyz;\n    float param_1 = xform.y;\n    vec3 _293 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_293, _284.w) * color;\n    float param_2 = 0.0;\n    vec4 _348 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_348);\n    fragment(param_3, param_4);\n    _348 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
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
            "inst_name": "_254",
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
