{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _370 = fa_linear_to_srgb(param);\n        c = _370;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _378 = fa_srgb_to_linear(param_1);\n            c = _378;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _389 = texture(tex_smp, p);\n    vec3 param = _389.xyz;\n    float param_1 = xform.y;\n    vec3 _399 = fa_tex_fix(param, param_1);\n    return vec4(_399, _389.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _114 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_114.x * 255.0) + 0.5) * 256.0) + floor((_114.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _138 = length(d);\n    if (_138 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _152 = atan(d.y, d.x);\n    float a = _152;\n    float _155;\n    if (_152 < 0.0)\n    {\n        _155 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _155 = a;\n    }\n    a = _155;\n    float _167 = _155 * 162.9746551513671875;\n    float _172 = min(floor(_167), 1023.0);\n    float _179 = _172 + 1.0;\n    float i1 = _179;\n    if (_179 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _172;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _138) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _138) + 0.5, 0.0, 1.0), _167 - _172);\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _242 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _246 = _242.x + 0.5;\n    vec2 c = vec2(_246, 0.5 - _242.y);\n    bool _254 = _246 >= 0.0;\n    bool _260;\n    if (_254)\n    {\n        _260 = c.x <= 1.0;\n    }\n    else\n    {\n        _260 = _254;\n    }\n    bool _266;\n    if (_260)\n    {\n        _266 = c.y >= 0.0;\n    }\n    else\n    {\n        _266 = _260;\n    }\n    bool _272;\n    if (_266)\n    {\n        _272 = c.y <= 1.0;\n    }\n    else\n    {\n        _272 = _266;\n    }\n    vec2 _274 = c;\n    vec2 _279 = clamp(_274, vec2(0.001953125), vec2(0.998046875));\n    c = _279;\n    return vec3(cell.x + (_279.x * cell.w), cell.y + (_279.y * cell.z), float(_272));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _551 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _551.xy, 0.0);\n    return cookie_value(param_3) * _551.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _573 = quad_fs_params[0].y > 0.5;\n    if (_573)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _597 = fa_tex_fix(param, param_1);\n        vec3 _601 = (_597 * 2.0) - vec3(1.0);\n        float _608 = cos(params.y);\n        float _610 = sin(params.y);\n        n = normalize(vec3((vec2(_608, _610) * _601.x) + ((vec2(-_610, _608) * ((mode > 5.5) ? (-1.0) : 1.0)) * _601.y), max(_601.z, 0.0500000007450580596923828125)));\n    }\n    bool _644 = !_573;\n    bool _650;\n    if (_644)\n    {\n        _650 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _650 = _644;\n    }\n    vec3 _653;\n    if (_650)\n    {\n        _653 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _653 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _653;\n    bool _670;\n    if (_650)\n    {\n        _670 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _670 = _650;\n    }\n    if (_670)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _794;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _708;\n        if (!_650)\n        {\n            _708 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _708 = _650;\n        }\n        if (_708)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _734 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_734) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _754 = vec3(_734, quad_fs_params[i * 1 + 5].z);\n            l = _754 / vec3(max(length(_754), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_734;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            vec2 param_6 = -_734;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_573)\n        {\n            _794 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _794 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _794));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _415 = fa_srgb_to_linear(param);\n        c = _415;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1040 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1044 = uv * _1040;\n    float _1050 = _1040.x;\n    float _1052 = _1040.y;\n    float _1054 = clamp(shape_rs.x, 0.0, min(_1050, _1052));\n    vec2 _1065 = (abs(_1044) - _1040) + vec2(_1054);\n    float d = (length(max(_1065, vec2(0.0))) + min(max(_1065.x, _1065.y), 0.0)) - _1054;\n    float ax = params.y;\n    bool _1086 = params.y > 15.0;\n    if (_1086)\n    {\n        ax -= 20.0;\n    }\n    float _1097;\n    if (ax <= (-1.5))\n    {\n        _1097 = (-2.0) - ax;\n    }\n    else\n    {\n        _1097 = 0.0;\n    }\n    if (_1097 > 0.0)\n    {\n        float _1111 = _1097 * 0.5;\n        d = abs(d + _1111) - _1111;\n    }\n    float _1119 = fwidth(d);\n    float _1120 = max(_1119, 9.9999997473787516355514526367188e-05);\n    float _1130 = clamp(0.5 - (d / max(shape_rs.y, _1120)), 0.0, 1.0);\n    float _1135;\n    if (shape_rs.y > _1120)\n    {\n        _1135 = (_1130 * _1130) * (3.0 - (2.0 * _1130));\n    }\n    else\n    {\n        _1135 = _1130;\n    }\n    vec4 c = color;\n    bool _1157 = (_1097 <= 0.0) && (ax > (-0.5));\n    if (_1157)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1172 = cos(ax);\n            float _1174 = sin(ax);\n            g = ((dot(_1044, vec2(_1172, _1174)) / max((abs(_1172) * _1050) + (abs(_1174) * _1052), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1086)\n        {\n            vec4 _1217 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1217;\n            vec3 param = _1217.xyz;\n            float param_1 = xform.y;\n            vec3 _1224 = fa_tex_fix(param, param_1);\n            vec4 _2012 = c;\n            _2012.x = _1224.x;\n            _2012.y = _1224.y;\n            _2012.z = _1224.z;\n            c = _2012;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1236 = scene_rgb(param_2);\n            vec4 _1261 = mix(vec4(color.xyz * color.w, color.w), vec4(_1236 * color2.w, color2.w), vec4(g));\n            float _1263 = _1261.w;\n            vec3 _1266;\n            if (_1263 > 9.9999997473787516355514526367188e-06)\n            {\n                _1266 = _1261.xyz / vec3(_1263);\n            }\n            else\n            {\n                _1266 = color.xyz;\n            }\n            c = vec4(_1266, _1263);\n        }\n    }\n    vec4 _2021 = c;\n    _2021.w = _2021.w * _1135;\n    c = _2021;\n    if (_1157 || (shape_rs.y > 0.0))\n    {\n        float _1307 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1316 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1316 + vec3(_1307 * 0.0039215688593685626983642578125);\n            vec3 _1322 = fa_srgb_to_linear(param_4);\n            vec4 _2024 = c;\n            _2024.x = _1322.x;\n            _2024.y = _1322.y;\n            _2024.z = _1322.z;\n            c = _2024;\n        }\n        else\n        {\n            vec4 _1332 = c;\n            vec3 _1335 = _1332.xyz + vec3(_1307 * 0.0039215688593685626983642578125);\n            vec4 _2031 = _1332;\n            _2031.x = _1335.x;\n            _2031.y = _1335.y;\n            _2031.z = _1335.z;\n            c = _2031;\n        }\n        vec4 _2036 = c;\n        _2036.w = clamp(_2036.w + ((_1307 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2036.w)), 0.0, 1.0);\n        c = _2036;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _831 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _833 = texture(tex_smp, uv - _831);\n    float _834 = _833.w;\n    vec4 _844 = texture(tex_smp, uv + _831);\n    float _845 = _844.w;\n    vec2 _853 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _855 = texture(tex_smp, uv - _853);\n    float _856 = _855.w;\n    vec4 _866 = texture(tex_smp, uv + _853);\n    float _867 = _866.w;\n    float _882 = _834 - _845;\n    float _885 = _867 - _856;\n    float _895 = cos(params.y);\n    float _897 = sin(params.y);\n    vec2 _923 = ((vec2(_895, _897) * _882) + ((vec2(-_897, _895) * ((mode > 5.5) ? (-1.0) : 1.0)) * _885)) / vec2(max(length(vec2(_882, _885)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _969 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _972 = length(_969);\n            att = pow(clamp(1.0 - (_972 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _969 / vec2(max(_972, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                vec2 param_1 = -_969;\n                float param_2 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            vec2 param_4 = -_969;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_923, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_834, _845), min(_856, _867))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _443 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _447 = _443.y;\n    return vec2(_443.x, mix(_447, 1.0 - _447, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _488 = base_mode < 0.5;\n    bool _499;\n    if (!_488)\n    {\n        _499 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _499 = _488;\n    }\n    float _500;\n    if (_499)\n    {\n        _500 = shape_half.x;\n    }\n    else\n    {\n        _500 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _500);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _421 = scene_rgb(param);\n    return _421;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _521 = s.color;\n    vec3 _523 = _521.xyz * fa_scene_rgb(param);\n    s.color.x = _523.x;\n    s.color.y = _523.y;\n    s.color.z = _523.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1362 = params.x > 31.5;\n    if (_1362)\n    {\n        mode -= 32.0;\n    }\n    float _1370 = mode;\n    bool _1372 = _1370 > 15.5;\n    if (_1372)\n    {\n        mode -= 16.0;\n    }\n    float _1380 = mode;\n    bool _1382 = _1380 > 7.5;\n    if (_1382)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1372)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1372)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1444 = tex_color(param_5);\n                vec4 _1446 = _1444 * color;\n                vec4 param_6 = _1446;\n                float param_7 = mode;\n                float _1453 = _1446.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1453);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1453;\n                    float param_9 = mode;\n                    vec4 _1469 = frag_color;\n                    vec3 _1471 = _1469.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1471.x;\n                    frag_color.y = _1471.y;\n                    frag_color.z = _1471.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1501 = length(uv);\n                    float _1504 = fwidth(_1501);\n                    float _1505 = max(_1504, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1501) / _1505) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1501) / _1505) + 0.5, 0.0, 1.0) * clamp(((_1501 - params.y) / _1505) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1545 = clamp(1.0 - _1501, 0.0, 1.0);\n                            cov = (_1545 * _1545) * (3.0 - (2.0 * _1545));\n                        }\n                    }\n                    vec3 _1554;\n                    if (_1372)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1554 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1554 = color.xyz;\n                    }\n                    frag_color = vec4(_1554, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1609 = fa_tex_fix(param_12, param_13);\n            e *= _1609;\n        }\n        vec4 _1613 = frag_color;\n        vec3 _1615 = _1613.xyz + e;\n        frag_color.x = _1615.x;\n        frag_color.y = _1615.y;\n        frag_color.z = _1615.z;\n    }\n    float param_14 = mode;\n    vec4 _1942 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_1942);\n    fragment(param_15, param_16);\n    _1942 = param_16.color;\n    frag_color = param_16.color;\n    if (_1362)\n    {\n        vec4 _1641 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1646 = scene_rgb(param_17);\n        vec3 _1650 = mix(_1641.xyz, _1646, vec3(color2.w));\n        frag_color.x = _1650.x;\n        frag_color.y = _1650.y;\n        frag_color.z = _1650.z;\n    }\n    if (_1382)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1674 = quad_fs_params[53].w > 0.0;\n    bool _1682;\n    if (!_1674)\n    {\n        _1682 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1682 = _1674;\n    }\n    if (_1682)\n    {\n        vec3 _1696 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1703 = dot(_1696, quad_fs_params[55].xyz);\n        bool _1707 = quad_fs_params[55].w > 0.5;\n        float _1708;\n        if (_1707)\n        {\n            _1708 = _1703;\n        }\n        else\n        {\n            _1708 = length(_1696);\n        }\n        float _1720 = _1708 - quad_fs_params[54].x;\n        if (_1720 > 0.0)\n        {\n            float _1729 = quad_fs_params[53].w * _1720;\n            float tau = _1729 * _1729;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1745;\n                if (_1707)\n                {\n                    _1745 = world_xy.y - (quad_fs_params[55].y * _1703);\n                }\n                else\n                {\n                    _1745 = quad_fs_params[56].y;\n                }\n                float _1766 = mix(_1745, world_xy.y, clamp(quad_fs_params[54].x / _1708, 0.0, 1.0));\n                float _1770 = world_xy.y - _1766;\n                float _1775 = _1766 - quad_fs_params[54].z;\n                float _1780 = world_xy.y - quad_fs_params[54].z;\n                bool _1783 = _1775 <= 0.0;\n                bool _1784 = !_1783;\n                bool _1790;\n                if (_1784)\n                {\n                    _1790 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1790 = _1783;\n                }\n                float _1791;\n                if (_1790)\n                {\n                    _1791 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1791 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1775, 80.0));\n                }\n                bool _1818;\n                if (_1784)\n                {\n                    _1818 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1818 = _1783;\n                }\n                float _1819;\n                if (_1818)\n                {\n                    _1819 = quad_fs_params[54].y * _1775;\n                }\n                else\n                {\n                    _1819 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1775, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1844 = _1780 <= 0.0;\n                bool _1851;\n                if (!_1844)\n                {\n                    _1851 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1851 = _1844;\n                }\n                float _1852;\n                if (_1851)\n                {\n                    _1852 = quad_fs_params[54].y * _1780;\n                }\n                else\n                {\n                    _1852 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1780, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1879;\n                if (abs(_1770) < 0.001000000047497451305389404296875)\n                {\n                    _1879 = _1791;\n                }\n                else\n                {\n                    _1879 = (_1852 - _1819) / _1770;\n                }\n                tau += (_1720 * max(_1879, 0.0));\n            }\n            vec4 _1902 = frag_color;\n            vec3 _1910 = mix(_1902.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1910.x;\n            frag_color.y = _1910.y;\n            frag_color.z = _1910.z;\n        }\n    }\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_437",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
            "inst_name": "_514",
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
          },
          {
            "texture": {
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
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
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1,
            "glsl_name": "fx_cookie_tex_light_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0,
            "glsl_name": "fx_emissive_tex_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _162 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _167 = _162.y;\n    return vec2(_162.x, mix(_167, 1.0 - _167, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _223);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _244 = s.color;\n    vec3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid main()\n{\n    vec4 _265 = texture(tex_smp, uv);\n    vec3 param = _265.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_274, _265.w) * color;\n    float param_2 = 0.0;\n    vec4 _328 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_328);\n    fragment(param_3, param_4);\n    _328 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_155",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
