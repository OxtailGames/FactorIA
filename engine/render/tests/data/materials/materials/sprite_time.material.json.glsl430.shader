{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _404 = quad_fs_params[0].y > 0.5;\n    if (_404)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _428 = fa_tex_fix(param, param_1);\n        vec3 _432 = (_428 * 2.0) - vec3(1.0);\n        float _439 = cos(params.y);\n        float _441 = sin(params.y);\n        n = normalize(vec3((vec2(_439, _441) * _432.x) + ((vec2(-_441, _439) * ((mode > 5.5) ? (-1.0) : 1.0)) * _432.y), max(_432.z, 0.0500000007450580596923828125)));\n    }\n    bool _475 = !_404;\n    bool _481;\n    if (_475)\n    {\n        _481 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _481 = _475;\n    }\n    vec3 _484;\n    if (_481)\n    {\n        _484 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _484 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _484;\n    bool _501;\n    if (_481)\n    {\n        _501 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _501 = _481;\n    }\n    if (_501)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _619;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _541;\n        if (!_481)\n        {\n            _541 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _541 = _481;\n        }\n        if (_541)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _567 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_567) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _587 = vec3(_567, quad_fs_params[i * 1 + 5].z);\n            l = _587 / vec3(max(length(_587), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_567;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_404)\n        {\n            _619 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _619 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _619));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _647 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _651 = uv * _647;\n    float _657 = _647.x;\n    float _659 = _647.y;\n    float _661 = clamp(shape_rs.x, 0.0, min(_657, _659));\n    vec2 _672 = (abs(_651) - _647) + vec2(_661);\n    float d = (length(max(_672, vec2(0.0))) + min(max(_672.x, _672.y), 0.0)) - _661;\n    float ax = params.y;\n    bool _693 = params.y > 15.0;\n    if (_693)\n    {\n        ax -= 20.0;\n    }\n    float _704;\n    if (ax <= (-1.5))\n    {\n        _704 = (-2.0) - ax;\n    }\n    else\n    {\n        _704 = 0.0;\n    }\n    if (_704 > 0.0)\n    {\n        float _718 = _704 * 0.5;\n        d = abs(d + _718) - _718;\n    }\n    float _726 = fwidth(d);\n    float _727 = max(_726, 9.9999997473787516355514526367188e-05);\n    float _737 = clamp(0.5 - (d / max(shape_rs.y, _727)), 0.0, 1.0);\n    float _742;\n    if (shape_rs.y > _727)\n    {\n        _742 = (_737 * _737) * (3.0 - (2.0 * _737));\n    }\n    else\n    {\n        _742 = _737;\n    }\n    vec4 c = color;\n    bool _764 = (_704 <= 0.0) && (ax > (-0.5));\n    if (_764)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _779 = cos(ax);\n            float _781 = sin(ax);\n            g = ((dot(_651, vec2(_779, _781)) / max((abs(_779) * _657) + (abs(_781) * _659), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_693)\n        {\n            vec4 _824 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _824;\n            vec3 param = _824.xyz;\n            float param_1 = xform.y;\n            vec3 _831 = fa_tex_fix(param, param_1);\n            vec4 _1528 = c;\n            _1528.x = _831.x;\n            _1528.y = _831.y;\n            _1528.z = _831.z;\n            c = _1528;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _843 = scene_rgb(param_2);\n            vec4 _868 = mix(vec4(color.xyz * color.w, color.w), vec4(_843 * color2.w, color2.w), vec4(g));\n            float _870 = _868.w;\n            vec3 _873;\n            if (_870 > 9.9999997473787516355514526367188e-06)\n            {\n                _873 = _868.xyz / vec3(_870);\n            }\n            else\n            {\n                _873 = color.xyz;\n            }\n            c = vec4(_873, _870);\n        }\n    }\n    vec4 _1537 = c;\n    _1537.w = _1537.w * _742;\n    c = _1537;\n    if (_764 || (shape_rs.y > 0.0))\n    {\n        float _914 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _923 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _923 + vec3(_914 * 0.0039215688593685626983642578125);\n            vec3 _929 = fa_srgb_to_linear(param_4);\n            vec4 _1540 = c;\n            _1540.x = _929.x;\n            _1540.y = _929.y;\n            _1540.z = _929.z;\n            c = _1540;\n        }\n        else\n        {\n            vec4 _939 = c;\n            vec3 _942 = _939.xyz + vec3(_914 * 0.0039215688593685626983642578125);\n            vec4 _1547 = _939;\n            _1547.x = _942.x;\n            _1547.y = _942.y;\n            _1547.z = _942.z;\n            c = _1547;\n        }\n        vec4 _1552 = c;\n        _1552.w = clamp(_1552.w + ((_914 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1552.w)), 0.0, 1.0);\n        c = _1552;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _316 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _320 = _316.y;\n    return vec2(_316.x, mix(_320, 1.0 - _320, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _362 = base_mode < 0.5;\n    bool _373;\n    if (!_362)\n    {\n        _373 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _373 = _362;\n    }\n    float _374;\n    if (_373)\n    {\n        _374 = shape_half.x;\n    }\n    else\n    {\n        _374 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _374);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _969 = params.x > 31.5;\n    if (_969)\n    {\n        mode -= 32.0;\n    }\n    float _977 = mode;\n    bool _979 = _977 > 15.5;\n    if (_979)\n    {\n        mode -= 16.0;\n    }\n    float _987 = mode;\n    bool _989 = _987 > 7.5;\n    if (_989)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_979)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_979)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1053 = tex_color(param_5) * color;\n                vec4 param_6 = _1053;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1053.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1088 = length(uv);\n                    float _1091 = fwidth(_1088);\n                    float _1092 = max(_1091, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1088) / _1092) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1088) / _1092) + 0.5, 0.0, 1.0) * clamp(((_1088 - params.y) / _1092) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1132 = clamp(1.0 - _1088, 0.0, 1.0);\n                            cov = (_1132 * _1132) * (3.0 - (2.0 * _1132));\n                        }\n                    }\n                    vec3 _1141;\n                    if (_979)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1141 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1141 = color.xyz;\n                    }\n                    frag_color = vec4(_1141, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1481 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1481);\n    fragment(param_11, param_12);\n    _1481 = param_12.color;\n    frag_color = param_12.color;\n    if (_969)\n    {\n        vec4 _1179 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1184 = scene_rgb(param_13);\n        vec3 _1188 = mix(_1179.xyz, _1184, vec3(color2.w));\n        frag_color.x = _1188.x;\n        frag_color.y = _1188.y;\n        frag_color.z = _1188.z;\n    }\n    if (_989)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1212 = quad_fs_params[53].w > 0.0;\n    bool _1220;\n    if (!_1212)\n    {\n        _1220 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1220 = _1212;\n    }\n    if (_1220)\n    {\n        vec3 _1234 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1241 = dot(_1234, quad_fs_params[55].xyz);\n        bool _1245 = quad_fs_params[55].w > 0.5;\n        float _1246;\n        if (_1245)\n        {\n            _1246 = _1241;\n        }\n        else\n        {\n            _1246 = length(_1234);\n        }\n        float _1258 = _1246 - quad_fs_params[54].x;\n        if (_1258 > 0.0)\n        {\n            float _1267 = quad_fs_params[53].w * _1258;\n            float tau = _1267 * _1267;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1283;\n                if (_1245)\n                {\n                    _1283 = world_xy.y - (quad_fs_params[55].y * _1241);\n                }\n                else\n                {\n                    _1283 = quad_fs_params[56].y;\n                }\n                float _1304 = mix(_1283, world_xy.y, clamp(quad_fs_params[54].x / _1246, 0.0, 1.0));\n                float _1308 = world_xy.y - _1304;\n                float _1313 = _1304 - quad_fs_params[54].z;\n                float _1318 = world_xy.y - quad_fs_params[54].z;\n                bool _1321 = _1313 <= 0.0;\n                bool _1322 = !_1321;\n                bool _1328;\n                if (_1322)\n                {\n                    _1328 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1328 = _1321;\n                }\n                float _1329;\n                if (_1328)\n                {\n                    _1329 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1329 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1313, 80.0));\n                }\n                bool _1356;\n                if (_1322)\n                {\n                    _1356 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1356 = _1321;\n                }\n                float _1357;\n                if (_1356)\n                {\n                    _1357 = quad_fs_params[54].y * _1313;\n                }\n                else\n                {\n                    _1357 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1313, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1382 = _1318 <= 0.0;\n                bool _1389;\n                if (!_1382)\n                {\n                    _1389 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1389 = _1382;\n                }\n                float _1390;\n                if (_1389)\n                {\n                    _1390 = quad_fs_params[54].y * _1318;\n                }\n                else\n                {\n                    _1390 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1318, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1417;\n                if (abs(_1308) < 0.001000000047497451305389404296875)\n                {\n                    _1417 = _1329;\n                }\n                else\n                {\n                    _1417 = (_1390 - _1357) / _1308;\n                }\n                tau += (_1258 * max(_1417, 0.0));\n            }\n            vec4 _1440 = frag_color;\n            vec3 _1448 = mix(_1440.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1448.x;\n            frag_color.y = _1448.y;\n            frag_color.z = _1448.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_309",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
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
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    vec4 _235 = texture(tex_smp, uv);\n    vec3 param = _235.xyz;\n    float param_1 = xform.y;\n    vec3 _246 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_246, _235.w) * color;\n    float param_2 = 0.0;\n    vec4 _301 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_301);\n    fragment(param_3, param_4);\n    _301 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
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
