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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _392 = quad_fs_params[0].y > 0.5;\n    if (_392)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _416 = fa_tex_fix(param, param_1);\n        vec3 _420 = (_416 * 2.0) - vec3(1.0);\n        float _427 = cos(params.y);\n        float _429 = sin(params.y);\n        n = normalize(vec3((vec2(_427, _429) * _420.x) + ((vec2(-_429, _427) * ((mode > 5.5) ? (-1.0) : 1.0)) * _420.y), max(_420.z, 0.0500000007450580596923828125)));\n    }\n    bool _463 = !_392;\n    bool _469;\n    if (_463)\n    {\n        _469 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _469 = _463;\n    }\n    vec3 _472;\n    if (_469)\n    {\n        _472 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _472 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _472;\n    bool _489;\n    if (_469)\n    {\n        _489 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _489 = _469;\n    }\n    if (_489)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _607;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _529;\n        if (!_469)\n        {\n            _529 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _529 = _469;\n        }\n        if (_529)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _555 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_555) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _575 = vec3(_555, quad_fs_params[i * 1 + 5].z);\n            l = _575 / vec3(max(length(_575), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_555;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_392)\n        {\n            _607 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _607 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _607));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _635 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _639 = uv * _635;\n    float _645 = _635.x;\n    float _647 = _635.y;\n    float _649 = clamp(shape_rs.x, 0.0, min(_645, _647));\n    vec2 _660 = (abs(_639) - _635) + vec2(_649);\n    float d = (length(max(_660, vec2(0.0))) + min(max(_660.x, _660.y), 0.0)) - _649;\n    float ax = params.y;\n    bool _681 = params.y > 15.0;\n    if (_681)\n    {\n        ax -= 20.0;\n    }\n    float _692;\n    if (ax <= (-1.5))\n    {\n        _692 = (-2.0) - ax;\n    }\n    else\n    {\n        _692 = 0.0;\n    }\n    if (_692 > 0.0)\n    {\n        float _706 = _692 * 0.5;\n        d = abs(d + _706) - _706;\n    }\n    float _714 = fwidth(d);\n    float _715 = max(_714, 9.9999997473787516355514526367188e-05);\n    float _725 = clamp(0.5 - (d / max(shape_rs.y, _715)), 0.0, 1.0);\n    float _730;\n    if (shape_rs.y > _715)\n    {\n        _730 = (_725 * _725) * (3.0 - (2.0 * _725));\n    }\n    else\n    {\n        _730 = _725;\n    }\n    vec4 c = color;\n    bool _752 = (_692 <= 0.0) && (ax > (-0.5));\n    if (_752)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _767 = cos(ax);\n            float _769 = sin(ax);\n            g = ((dot(_639, vec2(_767, _769)) / max((abs(_767) * _645) + (abs(_769) * _647), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_681)\n        {\n            vec4 _812 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _812;\n            vec3 param = _812.xyz;\n            float param_1 = xform.y;\n            vec3 _819 = fa_tex_fix(param, param_1);\n            vec4 _1516 = c;\n            _1516.x = _819.x;\n            _1516.y = _819.y;\n            _1516.z = _819.z;\n            c = _1516;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _831 = scene_rgb(param_2);\n            vec4 _856 = mix(vec4(color.xyz * color.w, color.w), vec4(_831 * color2.w, color2.w), vec4(g));\n            float _858 = _856.w;\n            vec3 _861;\n            if (_858 > 9.9999997473787516355514526367188e-06)\n            {\n                _861 = _856.xyz / vec3(_858);\n            }\n            else\n            {\n                _861 = color.xyz;\n            }\n            c = vec4(_861, _858);\n        }\n    }\n    vec4 _1525 = c;\n    _1525.w = _1525.w * _730;\n    c = _1525;\n    if (_752 || (shape_rs.y > 0.0))\n    {\n        float _902 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _911 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _911 + vec3(_902 * 0.0039215688593685626983642578125);\n            vec3 _917 = fa_srgb_to_linear(param_4);\n            vec4 _1528 = c;\n            _1528.x = _917.x;\n            _1528.y = _917.y;\n            _1528.z = _917.z;\n            c = _1528;\n        }\n        else\n        {\n            vec4 _927 = c;\n            vec3 _930 = _927.xyz + vec3(_902 * 0.0039215688593685626983642578125);\n            vec4 _1535 = _927;\n            _1535.x = _930.x;\n            _1535.y = _930.y;\n            _1535.z = _930.z;\n            c = _1535;\n        }\n        vec4 _1540 = c;\n        _1540.w = clamp(_1540.w + ((_902 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1540.w)), 0.0, 1.0);\n        c = _1540;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _316 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _320 = _316.y;\n    return vec2(_316.x, mix(_320, 1.0 - _320, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _362 = base_mode < 0.5;\n    bool _373;\n    if (!_362)\n    {\n        _373 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _373 = _362;\n    }\n    float _374;\n    if (_373)\n    {\n        _374 = shape_half.x;\n    }\n    else\n    {\n        _374 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _374);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _957 = params.x > 31.5;\n    if (_957)\n    {\n        mode -= 32.0;\n    }\n    float _965 = mode;\n    bool _967 = _965 > 15.5;\n    if (_967)\n    {\n        mode -= 16.0;\n    }\n    float _975 = mode;\n    bool _977 = _975 > 7.5;\n    if (_977)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_967)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_967)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1041 = tex_color(param_5) * color;\n                vec4 param_6 = _1041;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1041.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1076 = length(uv);\n                    float _1079 = fwidth(_1076);\n                    float _1080 = max(_1079, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1076) / _1080) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1076) / _1080) + 0.5, 0.0, 1.0) * clamp(((_1076 - params.y) / _1080) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1120 = clamp(1.0 - _1076, 0.0, 1.0);\n                            cov = (_1120 * _1120) * (3.0 - (2.0 * _1120));\n                        }\n                    }\n                    vec3 _1129;\n                    if (_967)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1129 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1129 = color.xyz;\n                    }\n                    frag_color = vec4(_1129, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1469 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1469);\n    fragment(param_11, param_12);\n    _1469 = param_12.color;\n    frag_color = param_12.color;\n    if (_957)\n    {\n        vec4 _1167 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1172 = scene_rgb(param_13);\n        vec3 _1176 = mix(_1167.xyz, _1172, vec3(color2.w));\n        frag_color.x = _1176.x;\n        frag_color.y = _1176.y;\n        frag_color.z = _1176.z;\n    }\n    if (_977)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1200 = quad_fs_params[53].w > 0.0;\n    bool _1208;\n    if (!_1200)\n    {\n        _1208 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1208 = _1200;\n    }\n    if (_1208)\n    {\n        vec3 _1222 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1229 = dot(_1222, quad_fs_params[55].xyz);\n        bool _1233 = quad_fs_params[55].w > 0.5;\n        float _1234;\n        if (_1233)\n        {\n            _1234 = _1229;\n        }\n        else\n        {\n            _1234 = length(_1222);\n        }\n        float _1246 = _1234 - quad_fs_params[54].x;\n        if (_1246 > 0.0)\n        {\n            float _1255 = quad_fs_params[53].w * _1246;\n            float tau = _1255 * _1255;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1271;\n                if (_1233)\n                {\n                    _1271 = world_xy.y - (quad_fs_params[55].y * _1229);\n                }\n                else\n                {\n                    _1271 = quad_fs_params[56].y;\n                }\n                float _1292 = mix(_1271, world_xy.y, clamp(quad_fs_params[54].x / _1234, 0.0, 1.0));\n                float _1296 = world_xy.y - _1292;\n                float _1301 = _1292 - quad_fs_params[54].z;\n                float _1306 = world_xy.y - quad_fs_params[54].z;\n                bool _1309 = _1301 <= 0.0;\n                bool _1310 = !_1309;\n                bool _1316;\n                if (_1310)\n                {\n                    _1316 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1316 = _1309;\n                }\n                float _1317;\n                if (_1316)\n                {\n                    _1317 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1317 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1301, 80.0));\n                }\n                bool _1344;\n                if (_1310)\n                {\n                    _1344 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1344 = _1309;\n                }\n                float _1345;\n                if (_1344)\n                {\n                    _1345 = quad_fs_params[54].y * _1301;\n                }\n                else\n                {\n                    _1345 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1301, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1370 = _1306 <= 0.0;\n                bool _1377;\n                if (!_1370)\n                {\n                    _1377 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1377 = _1370;\n                }\n                float _1378;\n                if (_1377)\n                {\n                    _1378 = quad_fs_params[54].y * _1306;\n                }\n                else\n                {\n                    _1378 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1306, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1405;\n                if (abs(_1296) < 0.001000000047497451305389404296875)\n                {\n                    _1405 = _1317;\n                }\n                else\n                {\n                    _1405 = (_1378 - _1345) / _1296;\n                }\n                tau += (_1246 * max(_1405, 0.0));\n            }\n            vec4 _1428 = frag_color;\n            vec3 _1436 = mix(_1428.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1436.x;\n            frag_color.y = _1436.y;\n            frag_color.z = _1436.z;\n        }\n    }\n}\n\n",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid main()\n{\n    vec4 _223 = texture(tex_smp, uv);\n    vec3 param = _223.xyz;\n    float param_1 = xform.y;\n    vec3 _234 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_234, _223.w) * color;\n    float param_2 = 0.0;\n    vec4 _289 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_289);\n    fragment(param_3, param_4);\n    _289 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
