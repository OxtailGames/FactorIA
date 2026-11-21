{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _269 = texture(tex_smp, p);\n    vec3 param = _269.xyz;\n    float param_1 = xform.y;\n    vec3 _279 = fa_tex_fix(param, param_1);\n    return vec4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _92 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = atan(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _418 = quad_fs_params[0].y > 0.5;\n    if (_418)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _442 = fa_tex_fix(param, param_1);\n        vec3 _446 = (_442 * 2.0) - vec3(1.0);\n        float _453 = cos(params.y);\n        float _455 = sin(params.y);\n        n = normalize(vec3((vec2(_453, _455) * _446.x) + ((vec2(-_455, _453) * ((mode > 5.5) ? (-1.0) : 1.0)) * _446.y), max(_446.z, 0.0500000007450580596923828125)));\n    }\n    bool _489 = !_418;\n    bool _495;\n    if (_489)\n    {\n        _495 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _495 = _489;\n    }\n    vec3 _498;\n    if (_495)\n    {\n        _498 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _498 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _498;\n    bool _515;\n    if (_495)\n    {\n        _515 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _515 = _495;\n    }\n    if (_515)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _633;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _555;\n        if (!_495)\n        {\n            _555 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _555 = _495;\n        }\n        if (_555)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _581 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_581) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _601 = vec3(_581, quad_fs_params[i * 1 + 5].z);\n            l = _601 / vec3(max(length(_601), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_581;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_418)\n        {\n            _633 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _633 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _633));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _661 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _665 = uv * _661;\n    float _671 = _661.x;\n    float _673 = _661.y;\n    float _675 = clamp(shape_rs.x, 0.0, min(_671, _673));\n    vec2 _686 = (abs(_665) - _661) + vec2(_675);\n    float d = (length(max(_686, vec2(0.0))) + min(max(_686.x, _686.y), 0.0)) - _675;\n    float ax = params.y;\n    bool _707 = params.y > 15.0;\n    if (_707)\n    {\n        ax -= 20.0;\n    }\n    float _718;\n    if (ax <= (-1.5))\n    {\n        _718 = (-2.0) - ax;\n    }\n    else\n    {\n        _718 = 0.0;\n    }\n    if (_718 > 0.0)\n    {\n        float _732 = _718 * 0.5;\n        d = abs(d + _732) - _732;\n    }\n    float _740 = fwidth(d);\n    float _741 = max(_740, 9.9999997473787516355514526367188e-05);\n    float _751 = clamp(0.5 - (d / max(shape_rs.y, _741)), 0.0, 1.0);\n    float _756;\n    if (shape_rs.y > _741)\n    {\n        _756 = (_751 * _751) * (3.0 - (2.0 * _751));\n    }\n    else\n    {\n        _756 = _751;\n    }\n    vec4 c = color;\n    bool _778 = (_718 <= 0.0) && (ax > (-0.5));\n    if (_778)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _793 = cos(ax);\n            float _795 = sin(ax);\n            g = ((dot(_665, vec2(_793, _795)) / max((abs(_793) * _671) + (abs(_795) * _673), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_707)\n        {\n            vec4 _838 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _838;\n            vec3 param = _838.xyz;\n            float param_1 = xform.y;\n            vec3 _845 = fa_tex_fix(param, param_1);\n            vec4 _1542 = c;\n            _1542.x = _845.x;\n            _1542.y = _845.y;\n            _1542.z = _845.z;\n            c = _1542;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _857 = scene_rgb(param_2);\n            vec4 _882 = mix(vec4(color.xyz * color.w, color.w), vec4(_857 * color2.w, color2.w), vec4(g));\n            float _884 = _882.w;\n            vec3 _887;\n            if (_884 > 9.9999997473787516355514526367188e-06)\n            {\n                _887 = _882.xyz / vec3(_884);\n            }\n            else\n            {\n                _887 = color.xyz;\n            }\n            c = vec4(_887, _884);\n        }\n    }\n    vec4 _1551 = c;\n    _1551.w = _1551.w * _756;\n    c = _1551;\n    if (_778 || (shape_rs.y > 0.0))\n    {\n        float _928 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _937 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _937 + vec3(_928 * 0.0039215688593685626983642578125);\n            vec3 _943 = fa_srgb_to_linear(param_4);\n            vec4 _1554 = c;\n            _1554.x = _943.x;\n            _1554.y = _943.y;\n            _1554.z = _943.z;\n            c = _1554;\n        }\n        else\n        {\n            vec4 _953 = c;\n            vec3 _956 = _953.xyz + vec3(_928 * 0.0039215688593685626983642578125);\n            vec4 _1561 = _953;\n            _1561.x = _956.x;\n            _1561.y = _956.y;\n            _1561.z = _956.z;\n            c = _1561;\n        }\n        vec4 _1566 = c;\n        _1566.w = clamp(_1566.w + ((_928 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1566.w)), 0.0, 1.0);\n        c = _1566;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _324 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _328 = _324.y;\n    return vec2(_324.x, mix(_328, 1.0 - _328, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _370 = base_mode < 0.5;\n    bool _381;\n    if (!_370)\n    {\n        _381 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _381 = _370;\n    }\n    float _382;\n    if (_381)\n    {\n        _382 = shape_half.x;\n    }\n    else\n    {\n        _382 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _382);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _302 = scene_rgb(param);\n    return _302;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _403 = s.color;\n    vec3 _405 = _403.xyz * fa_scene_rgb(param);\n    s.color.x = _405.x;\n    s.color.y = _405.y;\n    s.color.z = _405.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _983 = params.x > 31.5;\n    if (_983)\n    {\n        mode -= 32.0;\n    }\n    float _991 = mode;\n    bool _993 = _991 > 15.5;\n    if (_993)\n    {\n        mode -= 16.0;\n    }\n    float _1001 = mode;\n    bool _1003 = _1001 > 7.5;\n    if (_1003)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_993)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_993)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1067 = tex_color(param_5) * color;\n                vec4 param_6 = _1067;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1067.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1102 = length(uv);\n                    float _1105 = fwidth(_1102);\n                    float _1106 = max(_1105, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1102) / _1106) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1102) / _1106) + 0.5, 0.0, 1.0) * clamp(((_1102 - params.y) / _1106) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1146 = clamp(1.0 - _1102, 0.0, 1.0);\n                            cov = (_1146 * _1146) * (3.0 - (2.0 * _1146));\n                        }\n                    }\n                    vec3 _1155;\n                    if (_993)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1155 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1155 = color.xyz;\n                    }\n                    frag_color = vec4(_1155, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1495 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1495);\n    fragment(param_11, param_12);\n    _1495 = param_12.color;\n    frag_color = param_12.color;\n    if (_983)\n    {\n        vec4 _1193 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1198 = scene_rgb(param_13);\n        vec3 _1202 = mix(_1193.xyz, _1198, vec3(color2.w));\n        frag_color.x = _1202.x;\n        frag_color.y = _1202.y;\n        frag_color.z = _1202.z;\n    }\n    if (_1003)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1226 = quad_fs_params[53].w > 0.0;\n    bool _1234;\n    if (!_1226)\n    {\n        _1234 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1234 = _1226;\n    }\n    if (_1234)\n    {\n        vec3 _1248 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1255 = dot(_1248, quad_fs_params[55].xyz);\n        bool _1259 = quad_fs_params[55].w > 0.5;\n        float _1260;\n        if (_1259)\n        {\n            _1260 = _1255;\n        }\n        else\n        {\n            _1260 = length(_1248);\n        }\n        float _1272 = _1260 - quad_fs_params[54].x;\n        if (_1272 > 0.0)\n        {\n            float _1281 = quad_fs_params[53].w * _1272;\n            float tau = _1281 * _1281;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1297;\n                if (_1259)\n                {\n                    _1297 = world_xy.y - (quad_fs_params[55].y * _1255);\n                }\n                else\n                {\n                    _1297 = quad_fs_params[56].y;\n                }\n                float _1318 = mix(_1297, world_xy.y, clamp(quad_fs_params[54].x / _1260, 0.0, 1.0));\n                float _1322 = world_xy.y - _1318;\n                float _1327 = _1318 - quad_fs_params[54].z;\n                float _1332 = world_xy.y - quad_fs_params[54].z;\n                bool _1335 = _1327 <= 0.0;\n                bool _1336 = !_1335;\n                bool _1342;\n                if (_1336)\n                {\n                    _1342 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1342 = _1335;\n                }\n                float _1343;\n                if (_1342)\n                {\n                    _1343 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1343 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1327, 80.0));\n                }\n                bool _1370;\n                if (_1336)\n                {\n                    _1370 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1370 = _1335;\n                }\n                float _1371;\n                if (_1370)\n                {\n                    _1371 = quad_fs_params[54].y * _1327;\n                }\n                else\n                {\n                    _1371 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1327, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1396 = _1332 <= 0.0;\n                bool _1403;\n                if (!_1396)\n                {\n                    _1403 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1403 = _1396;\n                }\n                float _1404;\n                if (_1403)\n                {\n                    _1404 = quad_fs_params[54].y * _1332;\n                }\n                else\n                {\n                    _1404 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1332, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1431;\n                if (abs(_1322) < 0.001000000047497451305389404296875)\n                {\n                    _1431 = _1343;\n                }\n                else\n                {\n                    _1431 = (_1404 - _1371) / _1322;\n                }\n                tau += (_1272 * max(_1431, 0.0));\n            }\n            vec4 _1454 = frag_color;\n            vec3 _1462 = mix(_1454.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1462.x;\n            frag_color.y = _1462.y;\n            frag_color.z = _1462.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_317",
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
            "inst_name": "_396",
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
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _162 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _167 = _162.y;\n    return vec2(_162.x, mix(_167, 1.0 - _167, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _223);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _244 = s.color;\n    vec3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid main()\n{\n    vec4 _265 = texture(tex_smp, uv);\n    vec3 param = _265.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_274, _265.w) * color;\n    float param_2 = 0.0;\n    vec4 _329 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_329);\n    fragment(param_3, param_4);\n    _329 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_155",
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
            "inst_name": "_237",
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
