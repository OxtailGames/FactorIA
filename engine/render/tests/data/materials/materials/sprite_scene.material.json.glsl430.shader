{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "glsl430",
  "params": [
    "amount",
    "dx",
    "dy"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[3];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _269 = texture(tex_smp, p);\n    vec3 param = _269.xyz;\n    float param_1 = xform.y;\n    vec3 _279 = fa_tex_fix(param, param_1);\n    return vec4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _92 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = atan(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _464 = quad_fs_params[0].y > 0.5;\n    if (_464)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _488 = fa_tex_fix(param, param_1);\n        vec3 _492 = (_488 * 2.0) - vec3(1.0);\n        float _499 = cos(params.y);\n        float _501 = sin(params.y);\n        n = normalize(vec3((vec2(_499, _501) * _492.x) + ((vec2(-_501, _499) * ((mode > 5.5) ? (-1.0) : 1.0)) * _492.y), max(_492.z, 0.0500000007450580596923828125)));\n    }\n    bool _535 = !_464;\n    bool _541;\n    if (_535)\n    {\n        _541 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _541 = _535;\n    }\n    vec3 _544;\n    if (_541)\n    {\n        _544 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _544 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _544;\n    bool _561;\n    if (_541)\n    {\n        _561 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _561 = _541;\n    }\n    if (_561)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _678;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _600;\n        if (!_541)\n        {\n            _600 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _600 = _541;\n        }\n        if (_600)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _626 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_626) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _646 = vec3(_626, quad_fs_params[i * 1 + 5].z);\n            l = _646 / vec3(max(length(_646), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_626;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_464)\n        {\n            _678 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _678 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _678));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _706 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _710 = uv * _706;\n    float _716 = _706.x;\n    float _718 = _706.y;\n    float _720 = clamp(shape_rs.x, 0.0, min(_716, _718));\n    vec2 _731 = (abs(_710) - _706) + vec2(_720);\n    float d = (length(max(_731, vec2(0.0))) + min(max(_731.x, _731.y), 0.0)) - _720;\n    float ax = params.y;\n    bool _752 = params.y > 15.0;\n    if (_752)\n    {\n        ax -= 20.0;\n    }\n    float _763;\n    if (ax <= (-1.5))\n    {\n        _763 = (-2.0) - ax;\n    }\n    else\n    {\n        _763 = 0.0;\n    }\n    if (_763 > 0.0)\n    {\n        float _777 = _763 * 0.5;\n        d = abs(d + _777) - _777;\n    }\n    float _785 = fwidth(d);\n    float _786 = max(_785, 9.9999997473787516355514526367188e-05);\n    float _796 = clamp(0.5 - (d / max(shape_rs.y, _786)), 0.0, 1.0);\n    float _801;\n    if (shape_rs.y > _786)\n    {\n        _801 = (_796 * _796) * (3.0 - (2.0 * _796));\n    }\n    else\n    {\n        _801 = _796;\n    }\n    vec4 c = color;\n    bool _823 = (_763 <= 0.0) && (ax > (-0.5));\n    if (_823)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _838 = cos(ax);\n            float _840 = sin(ax);\n            g = ((dot(_710, vec2(_838, _840)) / max((abs(_838) * _716) + (abs(_840) * _718), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_752)\n        {\n            vec4 _883 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _883;\n            vec3 param = _883.xyz;\n            float param_1 = xform.y;\n            vec3 _890 = fa_tex_fix(param, param_1);\n            vec4 _1589 = c;\n            _1589.x = _890.x;\n            _1589.y = _890.y;\n            _1589.z = _890.z;\n            c = _1589;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _902 = scene_rgb(param_2);\n            vec4 _927 = mix(vec4(color.xyz * color.w, color.w), vec4(_902 * color2.w, color2.w), vec4(g));\n            float _929 = _927.w;\n            vec3 _932;\n            if (_929 > 9.9999997473787516355514526367188e-06)\n            {\n                _932 = _927.xyz / vec3(_929);\n            }\n            else\n            {\n                _932 = color.xyz;\n            }\n            c = vec4(_932, _929);\n        }\n    }\n    vec4 _1598 = c;\n    _1598.w = _1598.w * _801;\n    c = _1598;\n    if (_823 || (shape_rs.y > 0.0))\n    {\n        float _973 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _982 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _982 + vec3(_973 * 0.0039215688593685626983642578125);\n            vec3 _988 = fa_srgb_to_linear(param_4);\n            vec4 _1601 = c;\n            _1601.x = _988.x;\n            _1601.y = _988.y;\n            _1601.z = _988.z;\n            c = _1601;\n        }\n        else\n        {\n            vec4 _998 = c;\n            vec3 _1001 = _998.xyz + vec3(_973 * 0.0039215688593685626983642578125);\n            vec4 _1608 = _998;\n            _1608.x = _1001.x;\n            _1608.y = _1001.y;\n            _1608.z = _1001.z;\n            c = _1608;\n        }\n        vec4 _1613 = c;\n        _1613.w = clamp(_1613.w + ((_973 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1613.w)), 0.0, 1.0);\n        c = _1613;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _360 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _364 = _360.y;\n    return vec2(_360.x, mix(_364, 1.0 - _364, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _403 = base_mode < 0.5;\n    bool _414;\n    if (!_403)\n    {\n        _414 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _414 = _403;\n    }\n    float _415;\n    if (_414)\n    {\n        _415 = shape_half.x;\n    }\n    else\n    {\n        _415 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _415);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[59].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _328 = (uv_1 * quad_fs_params[59].xy) + quad_fs_params[59].zw;\n    float _330 = _328.y;\n    _328.y = mix(_330, 1.0 - _330, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_328, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + vec2(fa_material[1].x, fa_material[2].x);\n    s.color = vec4(mix(s.color.xyz, fa_scene_color(param).xyz, vec3(fa_material[0].x)), s.color.w);\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1028 = params.x > 31.5;\n    if (_1028)\n    {\n        mode -= 32.0;\n    }\n    float _1036 = mode;\n    bool _1038 = _1036 > 15.5;\n    if (_1038)\n    {\n        mode -= 16.0;\n    }\n    float _1046 = mode;\n    bool _1048 = _1046 > 7.5;\n    if (_1048)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1038)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1038)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1112 = tex_color(param_5) * color;\n                vec4 param_6 = _1112;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1112.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1147 = length(uv);\n                    float _1150 = fwidth(_1147);\n                    float _1151 = max(_1150, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1147) / _1151) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1147) / _1151) + 0.5, 0.0, 1.0) * clamp(((_1147 - params.y) / _1151) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1191 = clamp(1.0 - _1147, 0.0, 1.0);\n                            cov = (_1191 * _1191) * (3.0 - (2.0 * _1191));\n                        }\n                    }\n                    vec3 _1200;\n                    if (_1038)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1200 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1200 = color.xyz;\n                    }\n                    frag_color = vec4(_1200, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1538 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1538);\n    fragment(param_11, param_12);\n    _1538 = param_12.color;\n    frag_color = param_12.color;\n    if (_1028)\n    {\n        vec4 _1238 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1243 = scene_rgb(param_13);\n        vec3 _1247 = mix(_1238.xyz, _1243, vec3(color2.w));\n        frag_color.x = _1247.x;\n        frag_color.y = _1247.y;\n        frag_color.z = _1247.z;\n    }\n    if (_1048)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1270 = quad_fs_params[53].w > 0.0;\n    bool _1278;\n    if (!_1270)\n    {\n        _1278 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1278 = _1270;\n    }\n    if (_1278)\n    {\n        vec3 _1292 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1299 = dot(_1292, quad_fs_params[55].xyz);\n        bool _1303 = quad_fs_params[55].w > 0.5;\n        float _1304;\n        if (_1303)\n        {\n            _1304 = _1299;\n        }\n        else\n        {\n            _1304 = length(_1292);\n        }\n        float _1316 = _1304 - quad_fs_params[54].x;\n        if (_1316 > 0.0)\n        {\n            float _1325 = quad_fs_params[53].w * _1316;\n            float tau = _1325 * _1325;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1341;\n                if (_1303)\n                {\n                    _1341 = world_xy.y - (quad_fs_params[55].y * _1299);\n                }\n                else\n                {\n                    _1341 = quad_fs_params[56].y;\n                }\n                float _1362 = mix(_1341, world_xy.y, clamp(quad_fs_params[54].x / _1304, 0.0, 1.0));\n                float _1366 = world_xy.y - _1362;\n                float _1371 = _1362 - quad_fs_params[54].z;\n                float _1376 = world_xy.y - quad_fs_params[54].z;\n                bool _1379 = _1371 <= 0.0;\n                bool _1380 = !_1379;\n                bool _1386;\n                if (_1380)\n                {\n                    _1386 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1386 = _1379;\n                }\n                float _1387;\n                if (_1386)\n                {\n                    _1387 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1387 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1371, 80.0));\n                }\n                bool _1414;\n                if (_1380)\n                {\n                    _1414 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1414 = _1379;\n                }\n                float _1415;\n                if (_1414)\n                {\n                    _1415 = quad_fs_params[54].y * _1371;\n                }\n                else\n                {\n                    _1415 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1371, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1440 = _1376 <= 0.0;\n                bool _1447;\n                if (!_1440)\n                {\n                    _1447 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1447 = _1440;\n                }\n                float _1448;\n                if (_1447)\n                {\n                    _1448 = quad_fs_params[54].y * _1376;\n                }\n                else\n                {\n                    _1448 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1376, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1475;\n                if (abs(_1366) < 0.001000000047497451305389404296875)\n                {\n                    _1475 = _1387;\n                }\n                else\n                {\n                    _1475 = (_1448 - _1415) / _1366;\n                }\n                tau += (_1316 * max(_1475, 0.0));\n            }\n            vec4 _1498 = frag_color;\n            vec3 _1506 = mix(_1498.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1506.x;\n            frag_color.y = _1506.y;\n            frag_color.z = _1506.z;\n        }\n    }\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
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
            "inst_name": "_307",
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
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_432",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 3,
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
          },
          {
            "texture": {
              "slot": 12,
              "stage": "fragment",
              "name": "fa_scene_tex",
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
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[3];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _189 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _193 = _189.y;\n    return vec2(_189.x, mix(_193, 1.0 - _193, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _233 = base_mode < 0.5;\n    bool _244;\n    if (!_233)\n    {\n        _244 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _244 = _233;\n    }\n    float _245;\n    if (_244)\n    {\n        _245 = shape_half.x;\n    }\n    else\n    {\n        _245 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _245);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[59].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _150 = (uv_1 * quad_fs_params[59].xy) + quad_fs_params[59].zw;\n    float _153 = _150.y;\n    _150.y = mix(_153, 1.0 - _153, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_150, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + vec2(fa_material[1].x, fa_material[2].x);\n    s.color = vec4(mix(s.color.xyz, fa_scene_color(param).xyz, vec3(fa_material[0].x)), s.color.w);\n}\n\nvoid main()\n{\n    vec4 _296 = texture(tex_smp, uv);\n    vec3 param = _296.xyz;\n    float param_1 = xform.y;\n    vec3 _307 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_307, _296.w) * color;\n    float param_2 = 0.0;\n    vec4 _360 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_360);\n    fragment(param_3, param_4);\n    _360 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
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
            "inst_name": "_128",
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
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_263",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 3,
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
              "slot": 12,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering"
          },
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    }
  }
}
