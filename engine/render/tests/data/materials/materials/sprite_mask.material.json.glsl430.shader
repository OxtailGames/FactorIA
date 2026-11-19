{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "2079829332065ce3783c961c08db454e84df9f84c8284a005fa67df5d2d143e6",
  "slang": "glsl430",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _406 = quad_fs_params[0].y > 0.5;\n    if (_406)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _430 = fa_tex_fix(param, param_1);\n        vec3 _434 = (_430 * 2.0) - vec3(1.0);\n        float _441 = cos(params.y);\n        float _443 = sin(params.y);\n        n = normalize(vec3((vec2(_441, _443) * _434.x) + ((vec2(-_443, _441) * ((mode > 5.5) ? (-1.0) : 1.0)) * _434.y), max(_434.z, 0.0500000007450580596923828125)));\n    }\n    bool _476 = !_406;\n    bool _482;\n    if (_476)\n    {\n        _482 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _482 = _476;\n    }\n    vec3 _485;\n    if (_482)\n    {\n        _485 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _485 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _485;\n    bool _502;\n    if (_482)\n    {\n        _502 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _502 = _482;\n    }\n    if (_502)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _620;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _542;\n        if (!_482)\n        {\n            _542 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _542 = _482;\n        }\n        if (_542)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _568 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_568) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _588 = vec3(_568, quad_fs_params[i * 1 + 5].z);\n            l = _588 / vec3(max(length(_588), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_568;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_406)\n        {\n            _620 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _620 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _620));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _648 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _652 = uv * _648;\n    float _658 = _648.x;\n    float _660 = _648.y;\n    float _662 = clamp(shape_rs.x, 0.0, min(_658, _660));\n    vec2 _673 = (abs(_652) - _648) + vec2(_662);\n    float d = (length(max(_673, vec2(0.0))) + min(max(_673.x, _673.y), 0.0)) - _662;\n    float ax = params.y;\n    bool _694 = params.y > 15.0;\n    if (_694)\n    {\n        ax -= 20.0;\n    }\n    float _705;\n    if (ax <= (-1.5))\n    {\n        _705 = (-2.0) - ax;\n    }\n    else\n    {\n        _705 = 0.0;\n    }\n    if (_705 > 0.0)\n    {\n        float _719 = _705 * 0.5;\n        d = abs(d + _719) - _719;\n    }\n    float _727 = fwidth(d);\n    float _728 = max(_727, 9.9999997473787516355514526367188e-05);\n    float _738 = clamp(0.5 - (d / max(shape_rs.y, _728)), 0.0, 1.0);\n    float _743;\n    if (shape_rs.y > _728)\n    {\n        _743 = (_738 * _738) * (3.0 - (2.0 * _738));\n    }\n    else\n    {\n        _743 = _738;\n    }\n    vec4 c = color;\n    bool _765 = (_705 <= 0.0) && (ax > (-0.5));\n    if (_765)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _780 = cos(ax);\n            float _782 = sin(ax);\n            g = ((dot(_652, vec2(_780, _782)) / max((abs(_780) * _658) + (abs(_782) * _660), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_694)\n        {\n            vec4 _825 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _825;\n            vec3 param = _825.xyz;\n            float param_1 = xform.y;\n            vec3 _832 = fa_tex_fix(param, param_1);\n            vec4 _1528 = c;\n            _1528.x = _832.x;\n            _1528.y = _832.y;\n            _1528.z = _832.z;\n            c = _1528;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _844 = scene_rgb(param_2);\n            vec4 _869 = mix(vec4(color.xyz * color.w, color.w), vec4(_844 * color2.w, color2.w), vec4(g));\n            float _871 = _869.w;\n            vec3 _874;\n            if (_871 > 9.9999997473787516355514526367188e-06)\n            {\n                _874 = _869.xyz / vec3(_871);\n            }\n            else\n            {\n                _874 = color.xyz;\n            }\n            c = vec4(_874, _871);\n        }\n    }\n    vec4 _1537 = c;\n    _1537.w = _1537.w * _743;\n    c = _1537;\n    if (_765 || (shape_rs.y > 0.0))\n    {\n        float _915 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _924 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _924 + vec3(_915 * 0.0039215688593685626983642578125);\n            vec3 _930 = fa_srgb_to_linear(param_4);\n            vec4 _1540 = c;\n            _1540.x = _930.x;\n            _1540.y = _930.y;\n            _1540.z = _930.z;\n            c = _1540;\n        }\n        else\n        {\n            vec4 _940 = c;\n            vec3 _943 = _940.xyz + vec3(_915 * 0.0039215688593685626983642578125);\n            vec4 _1547 = _940;\n            _1547.x = _943.x;\n            _1547.y = _943.y;\n            _1547.z = _943.z;\n            c = _1547;\n        }\n        vec4 _1552 = c;\n        _1552.w = clamp(_1552.w + ((_915 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1552.w)), 0.0, 1.0);\n        c = _1552;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _315 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _319 = _315.y;\n    return vec2(_315.x, mix(_319, 1.0 - _319, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _361 = base_mode < 0.5;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _373);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _392 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _392.x;\n    s.color.y = _392.y;\n    s.color.z = _392.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _970 = params.x > 31.5;\n    if (_970)\n    {\n        mode -= 32.0;\n    }\n    float _978 = mode;\n    bool _980 = _978 > 15.5;\n    if (_980)\n    {\n        mode -= 16.0;\n    }\n    float _988 = mode;\n    bool _990 = _988 > 7.5;\n    if (_990)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_980)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_980)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1054 = tex_color(param_5) * color;\n                vec4 param_6 = _1054;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1054.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1089 = length(uv);\n                    float _1092 = fwidth(_1089);\n                    float _1093 = max(_1092, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1089) / _1093) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1089) / _1093) + 0.5, 0.0, 1.0) * clamp(((_1089 - params.y) / _1093) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1133 = clamp(1.0 - _1089, 0.0, 1.0);\n                            cov = (_1133 * _1133) * (3.0 - (2.0 * _1133));\n                        }\n                    }\n                    vec3 _1142;\n                    if (_980)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1142 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1142 = color.xyz;\n                    }\n                    frag_color = vec4(_1142, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1481 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1481);\n    fragment(param_11, param_12);\n    _1481 = param_12.color;\n    frag_color = param_12.color;\n    if (_970)\n    {\n        vec4 _1180 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1185 = scene_rgb(param_13);\n        vec3 _1189 = mix(_1180.xyz, _1185, vec3(color2.w));\n        frag_color.x = _1189.x;\n        frag_color.y = _1189.y;\n        frag_color.z = _1189.z;\n    }\n    if (_990)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1213 = quad_fs_params[53].w > 0.0;\n    bool _1221;\n    if (!_1213)\n    {\n        _1221 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1221 = _1213;\n    }\n    if (_1221)\n    {\n        vec3 _1235 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1242 = dot(_1235, quad_fs_params[55].xyz);\n        bool _1246 = quad_fs_params[55].w > 0.5;\n        float _1247;\n        if (_1246)\n        {\n            _1247 = _1242;\n        }\n        else\n        {\n            _1247 = length(_1235);\n        }\n        float _1259 = _1247 - quad_fs_params[54].x;\n        if (_1259 > 0.0)\n        {\n            float _1268 = quad_fs_params[53].w * _1259;\n            float tau = _1268 * _1268;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1284;\n                if (_1246)\n                {\n                    _1284 = world_xy.y - (quad_fs_params[55].y * _1242);\n                }\n                else\n                {\n                    _1284 = quad_fs_params[56].y;\n                }\n                float _1305 = mix(_1284, world_xy.y, clamp(quad_fs_params[54].x / _1247, 0.0, 1.0));\n                float _1309 = world_xy.y - _1305;\n                float _1314 = _1305 - quad_fs_params[54].z;\n                float _1319 = world_xy.y - quad_fs_params[54].z;\n                bool _1322 = _1314 <= 0.0;\n                bool _1323 = !_1322;\n                bool _1329;\n                if (_1323)\n                {\n                    _1329 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1329 = _1322;\n                }\n                float _1330;\n                if (_1329)\n                {\n                    _1330 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1330 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1314, 80.0));\n                }\n                bool _1357;\n                if (_1323)\n                {\n                    _1357 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1357 = _1322;\n                }\n                float _1358;\n                if (_1357)\n                {\n                    _1358 = quad_fs_params[54].y * _1314;\n                }\n                else\n                {\n                    _1358 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1314, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1383 = _1319 <= 0.0;\n                bool _1390;\n                if (!_1383)\n                {\n                    _1390 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1390 = _1383;\n                }\n                float _1391;\n                if (_1390)\n                {\n                    _1391 = quad_fs_params[54].y * _1319;\n                }\n                else\n                {\n                    _1391 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1319, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1418;\n                if (abs(_1309) < 0.001000000047497451305389404296875)\n                {\n                    _1418 = _1330;\n                }\n                else\n                {\n                    _1418 = (_1391 - _1358) / _1309;\n                }\n                tau += (_1259 * max(_1418, 0.0));\n            }\n            vec4 _1441 = frag_color;\n            vec3 _1449 = mix(_1441.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1449.x;\n            frag_color.y = _1449.y;\n            frag_color.z = _1449.z;\n        }\n    }\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_308",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
                "offset": 0,
                "glsl_name": "quad_fs_params"
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _221 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _221.x;\n    s.color.y = _221.y;\n    s.color.z = _221.z;\n}\n\nvoid main()\n{\n    vec4 _236 = texture(tex_smp, uv);\n    vec3 param = _236.xyz;\n    float param_1 = xform.y;\n    vec3 _247 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_247, _236.w) * color;\n    float param_2 = 0.0;\n    vec4 _301 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_301);\n    fragment(param_3, param_4);\n    _301 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
                "offset": 0,
                "glsl_name": "quad_fs_params"
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    }
  }
}
