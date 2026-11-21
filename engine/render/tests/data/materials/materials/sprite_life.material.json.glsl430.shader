{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _641 = texture(tex_smp, p);\n    vec3 param = _641.xyz;\n    float param_1 = xform.y;\n    vec3 _651 = fa_tex_fix(param, param_1);\n    return vec4(_651, _641.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _131 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = atan(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = atan(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _155) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _494 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    vec2 c = vec2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    vec2 _526 = c;\n    vec2 _531 = clamp(_526, vec2(0.001953125), vec2(0.998046875));\n    c = _531;\n    return vec3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _787 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _787.xy, 0.0);\n    return cookie_value(param_3) * _787.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _809 = quad_fs_params[0].y > 0.5;\n    if (_809)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _833 = fa_tex_fix(param, param_1);\n        vec3 _837 = (_833 * 2.0) - vec3(1.0);\n        float _844 = cos(params.y);\n        float _846 = sin(params.y);\n        n = normalize(vec3((vec2(_844, _846) * _837.x) + ((vec2(-_846, _844) * ((mode > 5.5) ? (-1.0) : 1.0)) * _837.y), max(_837.z, 0.0500000007450580596923828125)));\n    }\n    bool _880 = !_809;\n    bool _886;\n    if (_880)\n    {\n        _886 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _886 = _880;\n    }\n    vec3 _889;\n    if (_886)\n    {\n        _889 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _889 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _889;\n    bool _906;\n    if (_886)\n    {\n        _906 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _906 = _886;\n    }\n    if (_906)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1033;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _943;\n        if (!_886)\n        {\n            _943 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _943 = _886;\n        }\n        if (_943)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _969 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_969) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _989 = vec3(_969, quad_fs_params[i * 1 + 5].z);\n            l = _989 / vec3(max(length(_989), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_969;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_969;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_809)\n        {\n            _1033 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1033 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1033));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1283 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1287 = uv * _1283;\n    float _1293 = _1283.x;\n    float _1295 = _1283.y;\n    float _1297 = clamp(shape_rs.x, 0.0, min(_1293, _1295));\n    vec2 _1308 = (abs(_1287) - _1283) + vec2(_1297);\n    float d = (length(max(_1308, vec2(0.0))) + min(max(_1308.x, _1308.y), 0.0)) - _1297;\n    float ax = params.y;\n    bool _1329 = params.y > 15.0;\n    if (_1329)\n    {\n        ax -= 20.0;\n    }\n    float _1340;\n    if (ax <= (-1.5))\n    {\n        _1340 = (-2.0) - ax;\n    }\n    else\n    {\n        _1340 = 0.0;\n    }\n    if (_1340 > 0.0)\n    {\n        float _1354 = _1340 * 0.5;\n        d = abs(d + _1354) - _1354;\n    }\n    float _1362 = fwidth(d);\n    float _1363 = max(_1362, 9.9999997473787516355514526367188e-05);\n    float _1373 = clamp(0.5 - (d / max(shape_rs.y, _1363)), 0.0, 1.0);\n    float _1378;\n    if (shape_rs.y > _1363)\n    {\n        _1378 = (_1373 * _1373) * (3.0 - (2.0 * _1373));\n    }\n    else\n    {\n        _1378 = _1373;\n    }\n    vec4 c = color;\n    bool _1400 = (_1340 <= 0.0) && (ax > (-0.5));\n    if (_1400)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1415 = cos(ax);\n            float _1417 = sin(ax);\n            g = ((dot(_1287, vec2(_1415, _1417)) / max((abs(_1415) * _1293) + (abs(_1417) * _1295), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1329)\n        {\n            vec4 _1460 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1460;\n            vec3 param = _1460.xyz;\n            float param_1 = xform.y;\n            vec3 _1467 = fa_tex_fix(param, param_1);\n            vec4 _2256 = c;\n            _2256.x = _1467.x;\n            _2256.y = _1467.y;\n            _2256.z = _1467.z;\n            c = _2256;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1479 = scene_rgb(param_2);\n            vec4 _1504 = mix(vec4(color.xyz * color.w, color.w), vec4(_1479 * color2.w, color2.w), vec4(g));\n            float _1506 = _1504.w;\n            vec3 _1509;\n            if (_1506 > 9.9999997473787516355514526367188e-06)\n            {\n                _1509 = _1504.xyz / vec3(_1506);\n            }\n            else\n            {\n                _1509 = color.xyz;\n            }\n            c = vec4(_1509, _1506);\n        }\n    }\n    vec4 _2265 = c;\n    _2265.w = _2265.w * _1378;\n    c = _2265;\n    if (_1400 || (shape_rs.y > 0.0))\n    {\n        float _1550 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1559 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1559 + vec3(_1550 * 0.0039215688593685626983642578125);\n            vec3 _1565 = fa_srgb_to_linear(param_4);\n            vec4 _2268 = c;\n            _2268.x = _1565.x;\n            _2268.y = _1565.y;\n            _2268.z = _1565.z;\n            c = _2268;\n        }\n        else\n        {\n            vec4 _1575 = c;\n            vec3 _1578 = _1575.xyz + vec3(_1550 * 0.0039215688593685626983642578125);\n            vec4 _2275 = _1575;\n            _2275.x = _1578.x;\n            _2275.y = _1578.y;\n            _2275.z = _1578.z;\n            c = _2275;\n        }\n        vec4 _2280 = c;\n        _2280.w = clamp(_2280.w + ((_1550 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2280.w)), 0.0, 1.0);\n        c = _2280;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1070 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1072 = texture(tex_smp, uv - _1070);\n    float _1073 = _1072.w;\n    vec4 _1083 = texture(tex_smp, uv + _1070);\n    float _1084 = _1083.w;\n    vec2 _1092 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1094 = texture(tex_smp, uv - _1092);\n    float _1095 = _1094.w;\n    vec4 _1105 = texture(tex_smp, uv + _1092);\n    float _1106 = _1105.w;\n    float _1121 = _1073 - _1084;\n    float _1124 = _1106 - _1095;\n    float _1134 = cos(params.y);\n    float _1136 = sin(params.y);\n    vec2 _1162 = ((vec2(_1134, _1136) * _1121) + ((vec2(-_1136, _1134) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1124)) / vec2(max(length(vec2(_1121, _1124)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1208 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1211 = length(_1208);\n            att = pow(clamp(1.0 - (_1211 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1208 / vec2(max(_1211, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1208;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1208;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1162, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1073, _1084), min(_1095, _1106))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _691 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _695 = _691.y;\n    return vec2(_691.x, mix(_695, 1.0 - _695, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _733 = base_mode < 0.5;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _745);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1605 = params.x > 31.5;\n    if (_1605)\n    {\n        mode -= 32.0;\n    }\n    float _1613 = mode;\n    bool _1615 = _1613 > 15.5;\n    if (_1615)\n    {\n        mode -= 16.0;\n    }\n    float _1623 = mode;\n    bool _1625 = _1623 > 7.5;\n    if (_1625)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1615)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1615)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1687 = tex_color(param_5);\n                vec4 _1689 = _1687 * color;\n                vec4 param_6 = _1689;\n                float param_7 = mode;\n                float _1696 = _1689.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1696);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1696;\n                    float param_9 = mode;\n                    vec4 _1712 = frag_color;\n                    vec3 _1714 = _1712.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1714.x;\n                    frag_color.y = _1714.y;\n                    frag_color.z = _1714.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1744 = length(uv);\n                    float _1747 = fwidth(_1744);\n                    float _1748 = max(_1747, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1744) / _1748) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1744) / _1748) + 0.5, 0.0, 1.0) * clamp(((_1744 - params.y) / _1748) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1788 = clamp(1.0 - _1744, 0.0, 1.0);\n                            cov = (_1788 * _1788) * (3.0 - (2.0 * _1788));\n                        }\n                    }\n                    vec3 _1797;\n                    if (_1615)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1797 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1797 = color.xyz;\n                    }\n                    frag_color = vec4(_1797, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1852 = fa_tex_fix(param_12, param_13);\n            e *= _1852;\n        }\n        vec4 _1856 = frag_color;\n        vec3 _1858 = _1856.xyz + e;\n        frag_color.x = _1858.x;\n        frag_color.y = _1858.y;\n        frag_color.z = _1858.z;\n    }\n    float param_14 = mode;\n    vec4 _2186 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2186);\n    fragment(param_15, param_16);\n    _2186 = param_16.color;\n    frag_color = param_16.color;\n    if (_1605)\n    {\n        vec4 _1884 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1889 = scene_rgb(param_17);\n        vec3 _1893 = mix(_1884.xyz, _1889, vec3(color2.w));\n        frag_color.x = _1893.x;\n        frag_color.y = _1893.y;\n        frag_color.z = _1893.z;\n    }\n    if (_1625)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1917 = quad_fs_params[53].w > 0.0;\n    bool _1925;\n    if (!_1917)\n    {\n        _1925 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1925 = _1917;\n    }\n    if (_1925)\n    {\n        vec3 _1939 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1946 = dot(_1939, quad_fs_params[55].xyz);\n        bool _1950 = quad_fs_params[55].w > 0.5;\n        float _1951;\n        if (_1950)\n        {\n            _1951 = _1946;\n        }\n        else\n        {\n            _1951 = length(_1939);\n        }\n        float _1963 = _1951 - quad_fs_params[54].x;\n        if (_1963 > 0.0)\n        {\n            float _1972 = quad_fs_params[53].w * _1963;\n            float tau = _1972 * _1972;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1988;\n                if (_1950)\n                {\n                    _1988 = world_xy.y - (quad_fs_params[55].y * _1946);\n                }\n                else\n                {\n                    _1988 = quad_fs_params[56].y;\n                }\n                float _2009 = mix(_1988, world_xy.y, clamp(quad_fs_params[54].x / _1951, 0.0, 1.0));\n                float _2013 = world_xy.y - _2009;\n                float _2018 = _2009 - quad_fs_params[54].z;\n                float _2023 = world_xy.y - quad_fs_params[54].z;\n                bool _2026 = _2018 <= 0.0;\n                bool _2027 = !_2026;\n                bool _2033;\n                if (_2027)\n                {\n                    _2033 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2033 = _2026;\n                }\n                float _2034;\n                if (_2033)\n                {\n                    _2034 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2034 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2018, 80.0));\n                }\n                bool _2061;\n                if (_2027)\n                {\n                    _2061 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2061 = _2026;\n                }\n                float _2062;\n                if (_2061)\n                {\n                    _2062 = quad_fs_params[54].y * _2018;\n                }\n                else\n                {\n                    _2062 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2018, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2087 = _2023 <= 0.0;\n                bool _2094;\n                if (!_2087)\n                {\n                    _2094 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2094 = _2087;\n                }\n                float _2095;\n                if (_2094)\n                {\n                    _2095 = quad_fs_params[54].y * _2023;\n                }\n                else\n                {\n                    _2095 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2023, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2122;\n                if (abs(_2013) < 0.001000000047497451305389404296875)\n                {\n                    _2122 = _2034;\n                }\n                else\n                {\n                    _2122 = (_2095 - _2062) / _2013;\n                }\n                tau += (_1963 * max(_2122, 0.0));\n            }\n            vec4 _2145 = frag_color;\n            vec3 _2153 = mix(_2145.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2153.x;\n            frag_color.y = _2153.y;\n            frag_color.z = _2153.z;\n        }\n    }\n}\n\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_685",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 99,
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
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _138 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _144 = _138.y;\n    return vec2(_138.x, mix(_144, 1.0 - _144, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _200);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    vec4 _234 = texture(tex_smp, uv);\n    vec3 param = _234.xyz;\n    float param_1 = xform.y;\n    vec3 _245 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_245, _234.w) * color;\n    float param_2 = 0.0;\n    vec4 _300 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_300);\n    fragment(param_3, param_4);\n    _300 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 99,
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
