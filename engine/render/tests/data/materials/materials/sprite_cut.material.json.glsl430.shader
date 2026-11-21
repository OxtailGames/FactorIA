{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "glsl430",
  "params": [
    "cut",
    "cutY"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _641 = texture(tex_smp, p);\n    vec3 param = _641.xyz;\n    float param_1 = xform.y;\n    vec3 _651 = fa_tex_fix(param, param_1);\n    return vec4(_651, _641.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _131 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = atan(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = atan(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _155) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _494 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    vec2 c = vec2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    vec2 _526 = c;\n    vec2 _531 = clamp(_526, vec2(0.001953125), vec2(0.998046875));\n    c = _531;\n    return vec3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _798 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _798.xy, 0.0);\n    return cookie_value(param_3) * _798.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _820 = quad_fs_params[0].y > 0.5;\n    if (_820)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _844 = fa_tex_fix(param, param_1);\n        vec3 _848 = (_844 * 2.0) - vec3(1.0);\n        float _855 = cos(params.y);\n        float _857 = sin(params.y);\n        n = normalize(vec3((vec2(_855, _857) * _848.x) + ((vec2(-_857, _855) * ((mode > 5.5) ? (-1.0) : 1.0)) * _848.y), max(_848.z, 0.0500000007450580596923828125)));\n    }\n    bool _891 = !_820;\n    bool _897;\n    if (_891)\n    {\n        _897 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _897 = _891;\n    }\n    vec3 _900;\n    if (_897)\n    {\n        _900 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _900 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _900;\n    bool _917;\n    if (_897)\n    {\n        _917 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _917 = _897;\n    }\n    if (_917)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1044;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _954;\n        if (!_897)\n        {\n            _954 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _954 = _897;\n        }\n        if (_954)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _980 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_980) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1000 = vec3(_980, quad_fs_params[i * 1 + 5].z);\n            l = _1000 / vec3(max(length(_1000), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_980;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_980;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_820)\n        {\n            _1044 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1044 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1044));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1294 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1298 = uv * _1294;\n    float _1304 = _1294.x;\n    float _1306 = _1294.y;\n    float _1308 = clamp(shape_rs.x, 0.0, min(_1304, _1306));\n    vec2 _1319 = (abs(_1298) - _1294) + vec2(_1308);\n    float d = (length(max(_1319, vec2(0.0))) + min(max(_1319.x, _1319.y), 0.0)) - _1308;\n    float ax = params.y;\n    bool _1340 = params.y > 15.0;\n    if (_1340)\n    {\n        ax -= 20.0;\n    }\n    float _1351;\n    if (ax <= (-1.5))\n    {\n        _1351 = (-2.0) - ax;\n    }\n    else\n    {\n        _1351 = 0.0;\n    }\n    if (_1351 > 0.0)\n    {\n        float _1365 = _1351 * 0.5;\n        d = abs(d + _1365) - _1365;\n    }\n    float _1373 = fwidth(d);\n    float _1374 = max(_1373, 9.9999997473787516355514526367188e-05);\n    float _1384 = clamp(0.5 - (d / max(shape_rs.y, _1374)), 0.0, 1.0);\n    float _1389;\n    if (shape_rs.y > _1374)\n    {\n        _1389 = (_1384 * _1384) * (3.0 - (2.0 * _1384));\n    }\n    else\n    {\n        _1389 = _1384;\n    }\n    vec4 c = color;\n    bool _1411 = (_1351 <= 0.0) && (ax > (-0.5));\n    if (_1411)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1426 = cos(ax);\n            float _1428 = sin(ax);\n            g = ((dot(_1298, vec2(_1426, _1428)) / max((abs(_1426) * _1304) + (abs(_1428) * _1306), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1340)\n        {\n            vec4 _1471 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1471;\n            vec3 param = _1471.xyz;\n            float param_1 = xform.y;\n            vec3 _1478 = fa_tex_fix(param, param_1);\n            vec4 _2267 = c;\n            _2267.x = _1478.x;\n            _2267.y = _1478.y;\n            _2267.z = _1478.z;\n            c = _2267;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1490 = scene_rgb(param_2);\n            vec4 _1515 = mix(vec4(color.xyz * color.w, color.w), vec4(_1490 * color2.w, color2.w), vec4(g));\n            float _1517 = _1515.w;\n            vec3 _1520;\n            if (_1517 > 9.9999997473787516355514526367188e-06)\n            {\n                _1520 = _1515.xyz / vec3(_1517);\n            }\n            else\n            {\n                _1520 = color.xyz;\n            }\n            c = vec4(_1520, _1517);\n        }\n    }\n    vec4 _2276 = c;\n    _2276.w = _2276.w * _1389;\n    c = _2276;\n    if (_1411 || (shape_rs.y > 0.0))\n    {\n        float _1561 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1570 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1570 + vec3(_1561 * 0.0039215688593685626983642578125);\n            vec3 _1576 = fa_srgb_to_linear(param_4);\n            vec4 _2279 = c;\n            _2279.x = _1576.x;\n            _2279.y = _1576.y;\n            _2279.z = _1576.z;\n            c = _2279;\n        }\n        else\n        {\n            vec4 _1586 = c;\n            vec3 _1589 = _1586.xyz + vec3(_1561 * 0.0039215688593685626983642578125);\n            vec4 _2286 = _1586;\n            _2286.x = _1589.x;\n            _2286.y = _1589.y;\n            _2286.z = _1589.z;\n            c = _2286;\n        }\n        vec4 _2291 = c;\n        _2291.w = clamp(_2291.w + ((_1561 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2291.w)), 0.0, 1.0);\n        c = _2291;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1081 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1083 = texture(tex_smp, uv - _1081);\n    float _1084 = _1083.w;\n    vec4 _1094 = texture(tex_smp, uv + _1081);\n    float _1095 = _1094.w;\n    vec2 _1103 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1105 = texture(tex_smp, uv - _1103);\n    float _1106 = _1105.w;\n    vec4 _1116 = texture(tex_smp, uv + _1103);\n    float _1117 = _1116.w;\n    float _1132 = _1084 - _1095;\n    float _1135 = _1117 - _1106;\n    float _1145 = cos(params.y);\n    float _1147 = sin(params.y);\n    vec2 _1173 = ((vec2(_1145, _1147) * _1132) + ((vec2(-_1147, _1145) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1135)) / vec2(max(length(vec2(_1132, _1135)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1219 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1222 = length(_1219);\n            att = pow(clamp(1.0 - (_1222 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1219 / vec2(max(_1222, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1219;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1219;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1173, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1084, _1095), min(_1106, _1117))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _691 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _695 = _691.y;\n    return vec2(_691.x, mix(_695, 1.0 - _695, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _733 = base_mode < 0.5;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _745);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _764 = i.screen_uv.x < fa_material[0].x;\n    bool _773;\n    if (!_764)\n    {\n        _773 = i.screen_uv.y < fa_material[1].x;\n    }\n    else\n    {\n        _773 = _764;\n    }\n    if (_773)\n    {\n        discard;\n    }\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1616 = params.x > 31.5;\n    if (_1616)\n    {\n        mode -= 32.0;\n    }\n    float _1624 = mode;\n    bool _1626 = _1624 > 15.5;\n    if (_1626)\n    {\n        mode -= 16.0;\n    }\n    float _1634 = mode;\n    bool _1636 = _1634 > 7.5;\n    if (_1636)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1626)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1626)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1698 = tex_color(param_5);\n                vec4 _1700 = _1698 * color;\n                vec4 param_6 = _1700;\n                float param_7 = mode;\n                float _1707 = _1700.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1707);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1707;\n                    float param_9 = mode;\n                    vec4 _1723 = frag_color;\n                    vec3 _1725 = _1723.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1725.x;\n                    frag_color.y = _1725.y;\n                    frag_color.z = _1725.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1755 = length(uv);\n                    float _1758 = fwidth(_1755);\n                    float _1759 = max(_1758, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1755) / _1759) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1755) / _1759) + 0.5, 0.0, 1.0) * clamp(((_1755 - params.y) / _1759) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1799 = clamp(1.0 - _1755, 0.0, 1.0);\n                            cov = (_1799 * _1799) * (3.0 - (2.0 * _1799));\n                        }\n                    }\n                    vec3 _1808;\n                    if (_1626)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1808 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1808 = color.xyz;\n                    }\n                    frag_color = vec4(_1808, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1863 = fa_tex_fix(param_12, param_13);\n            e *= _1863;\n        }\n        vec4 _1867 = frag_color;\n        vec3 _1869 = _1867.xyz + e;\n        frag_color.x = _1869.x;\n        frag_color.y = _1869.y;\n        frag_color.z = _1869.z;\n    }\n    float param_14 = mode;\n    vec4 _2197 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2197);\n    fragment(param_15, param_16);\n    _2197 = param_16.color;\n    frag_color = param_16.color;\n    if (_1616)\n    {\n        vec4 _1895 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1900 = scene_rgb(param_17);\n        vec3 _1904 = mix(_1895.xyz, _1900, vec3(color2.w));\n        frag_color.x = _1904.x;\n        frag_color.y = _1904.y;\n        frag_color.z = _1904.z;\n    }\n    if (_1636)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1928 = quad_fs_params[53].w > 0.0;\n    bool _1936;\n    if (!_1928)\n    {\n        _1936 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1936 = _1928;\n    }\n    if (_1936)\n    {\n        vec3 _1950 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1957 = dot(_1950, quad_fs_params[55].xyz);\n        bool _1961 = quad_fs_params[55].w > 0.5;\n        float _1962;\n        if (_1961)\n        {\n            _1962 = _1957;\n        }\n        else\n        {\n            _1962 = length(_1950);\n        }\n        float _1974 = _1962 - quad_fs_params[54].x;\n        if (_1974 > 0.0)\n        {\n            float _1983 = quad_fs_params[53].w * _1974;\n            float tau = _1983 * _1983;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1999;\n                if (_1961)\n                {\n                    _1999 = world_xy.y - (quad_fs_params[55].y * _1957);\n                }\n                else\n                {\n                    _1999 = quad_fs_params[56].y;\n                }\n                float _2020 = mix(_1999, world_xy.y, clamp(quad_fs_params[54].x / _1962, 0.0, 1.0));\n                float _2024 = world_xy.y - _2020;\n                float _2029 = _2020 - quad_fs_params[54].z;\n                float _2034 = world_xy.y - quad_fs_params[54].z;\n                bool _2037 = _2029 <= 0.0;\n                bool _2038 = !_2037;\n                bool _2044;\n                if (_2038)\n                {\n                    _2044 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2044 = _2037;\n                }\n                float _2045;\n                if (_2044)\n                {\n                    _2045 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2045 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2029, 80.0));\n                }\n                bool _2072;\n                if (_2038)\n                {\n                    _2072 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2072 = _2037;\n                }\n                float _2073;\n                if (_2072)\n                {\n                    _2073 = quad_fs_params[54].y * _2029;\n                }\n                else\n                {\n                    _2073 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2029, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2098 = _2034 <= 0.0;\n                bool _2105;\n                if (!_2098)\n                {\n                    _2105 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2105 = _2098;\n                }\n                float _2106;\n                if (_2105)\n                {\n                    _2106 = quad_fs_params[54].y * _2034;\n                }\n                else\n                {\n                    _2106 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2034, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2133;\n                if (abs(_2024) < 0.001000000047497451305389404296875)\n                {\n                    _2133 = _2045;\n                }\n                else\n                {\n                    _2133 = (_2106 - _2073) / _2024;\n                }\n                tau += (_1974 * max(_2133, 0.0));\n            }\n            vec4 _2156 = frag_color;\n            vec3 _2164 = mix(_2156.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2164.x;\n            frag_color.y = _2164.y;\n            frag_color.z = _2164.z;\n        }\n    }\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_761",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _138 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _144 = _138.y;\n    return vec2(_138.x, mix(_144, 1.0 - _144, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _200);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _220 = i.screen_uv.x < fa_material[0].x;\n    bool _229;\n    if (!_220)\n    {\n        _229 = i.screen_uv.y < fa_material[1].x;\n    }\n    else\n    {\n        _229 = _220;\n    }\n    if (_229)\n    {\n        discard;\n    }\n}\n\nvoid main()\n{\n    vec4 _245 = texture(tex_smp, uv);\n    vec3 param = _245.xyz;\n    float param_1 = xform.y;\n    vec3 _256 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_256, _245.w) * color;\n    float param_2 = 0.0;\n    vec4 _311 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_311);\n    fragment(param_3, param_4);\n    _311 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_217",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
