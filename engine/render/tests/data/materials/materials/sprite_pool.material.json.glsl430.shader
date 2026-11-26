{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "glsl430",
  "params": [
    "reflection",
    "refraction",
    "size",
    "strength",
    "tint",
    "waveAmplitude",
    "waveLength",
    "waveSpeed"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[8];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\nlayout(binding = 7) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _647 = texture(tex_smp, p);\n    vec3 param = _647.xyz;\n    float param_1 = xform.y;\n    vec3 _657 = fa_tex_fix(param, param_1);\n    return vec4(_657, _647.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _909 = (world_xy * quad_fs_params[99].xy) + quad_fs_params[99].zw;\n    vec4 _916 = textureLod(fx_gi_tex_light_smp, _909, 0.0);\n    float _920 = _909.x;\n    bool _921 = _920 >= 0.0;\n    bool _927;\n    if (_921)\n    {\n        _927 = _909.y >= 0.0;\n    }\n    else\n    {\n        _927 = _921;\n    }\n    bool _933;\n    if (_927)\n    {\n        _933 = _920 <= 1.0;\n    }\n    else\n    {\n        _933 = _927;\n    }\n    bool _939;\n    if (_933)\n    {\n        _939 = _909.y <= 1.0;\n    }\n    else\n    {\n        _939 = _933;\n    }\n    bool _947;\n    if (_939)\n    {\n        _947 = _916.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _947 = _939;\n    }\n    vec3 _948;\n    if (_947)\n    {\n        _948 = (_916.xyz / vec3(_916.w)) * quad_fs_params[100].x;\n    }\n    else\n    {\n        _948 = vec3(0.0);\n    }\n    return _948;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _137 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = atan(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = atan(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _500 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    vec2 c = vec2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    vec2 _532 = c;\n    vec2 _537 = clamp(_532, vec2(0.001953125), vec2(0.998046875));\n    c = _537;\n    return vec3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _884 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _884.xy, 0.0);\n    return cookie_value(param_3) * _884.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _970 = quad_fs_params[0].y > 0.5;\n    if (_970)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _994 = fa_tex_fix(param, param_1);\n        vec3 _998 = (_994 * 2.0) - vec3(1.0);\n        float _1005 = cos(params.y);\n        float _1007 = sin(params.y);\n        n = normalize(vec3((vec2(_1005, _1007) * _998.x) + ((vec2(-_1007, _1005) * ((mode > 5.5) ? (-1.0) : 1.0)) * _998.y), max(_998.z, 0.0500000007450580596923828125)));\n    }\n    bool _1041 = !_970;\n    bool _1047;\n    if (_1041)\n    {\n        _1047 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _1047 = _1041;\n    }\n    vec3 _1050;\n    if (_1047)\n    {\n        _1050 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _1050 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _1050;\n    if (quad_fs_params[100].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _1075;\n    if (_1047)\n    {\n        _1075 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _1075 = _1047;\n    }\n    if (_1075)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1202;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1112;\n        if (!_1047)\n        {\n            _1112 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1112 = _1047;\n        }\n        if (_1112)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1138 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1138) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1158 = vec3(_1138, quad_fs_params[i * 1 + 5].z);\n            l = _1158 / vec3(max(length(_1158), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1138;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1138;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_970)\n        {\n            _1202 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1202 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1202));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1452 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1456 = uv * _1452;\n    float _1462 = _1452.x;\n    float _1464 = _1452.y;\n    float _1466 = clamp(shape_rs.x, 0.0, min(_1462, _1464));\n    vec2 _1477 = (abs(_1456) - _1452) + vec2(_1466);\n    float d = (length(max(_1477, vec2(0.0))) + min(max(_1477.x, _1477.y), 0.0)) - _1466;\n    float ax = params.y;\n    bool _1498 = params.y > 15.0;\n    if (_1498)\n    {\n        ax -= 20.0;\n    }\n    float _1509;\n    if (ax <= (-1.5))\n    {\n        _1509 = (-2.0) - ax;\n    }\n    else\n    {\n        _1509 = 0.0;\n    }\n    if (_1509 > 0.0)\n    {\n        float _1523 = _1509 * 0.5;\n        d = abs(d + _1523) - _1523;\n    }\n    float _1531 = fwidth(d);\n    float _1532 = max(_1531, 9.9999997473787516355514526367188e-05);\n    float _1542 = clamp(0.5 - (d / max(shape_rs.y, _1532)), 0.0, 1.0);\n    float _1547;\n    if (shape_rs.y > _1532)\n    {\n        _1547 = (_1542 * _1542) * (3.0 - (2.0 * _1542));\n    }\n    else\n    {\n        _1547 = _1542;\n    }\n    vec4 c = color;\n    bool _1569 = (_1509 <= 0.0) && (ax > (-0.5));\n    if (_1569)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1584 = cos(ax);\n            float _1586 = sin(ax);\n            g = ((dot(_1456, vec2(_1584, _1586)) / max((abs(_1584) * _1462) + (abs(_1586) * _1464), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1498)\n        {\n            vec4 _1629 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1629;\n            vec3 param = _1629.xyz;\n            float param_1 = xform.y;\n            vec3 _1636 = fa_tex_fix(param, param_1);\n            vec4 _2431 = c;\n            _2431.x = _1636.x;\n            _2431.y = _1636.y;\n            _2431.z = _1636.z;\n            c = _2431;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1648 = scene_rgb(param_2);\n            vec4 _1673 = mix(vec4(color.xyz * color.w, color.w), vec4(_1648 * color2.w, color2.w), vec4(g));\n            float _1675 = _1673.w;\n            vec3 _1678;\n            if (_1675 > 9.9999997473787516355514526367188e-06)\n            {\n                _1678 = _1673.xyz / vec3(_1675);\n            }\n            else\n            {\n                _1678 = color.xyz;\n            }\n            c = vec4(_1678, _1675);\n        }\n    }\n    vec4 _2440 = c;\n    _2440.w = _2440.w * _1547;\n    c = _2440;\n    if (_1569 || (shape_rs.y > 0.0))\n    {\n        float _1719 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1728 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1728 + vec3(_1719 * 0.0039215688593685626983642578125);\n            vec3 _1734 = fa_srgb_to_linear(param_4);\n            vec4 _2443 = c;\n            _2443.x = _1734.x;\n            _2443.y = _1734.y;\n            _2443.z = _1734.z;\n            c = _2443;\n        }\n        else\n        {\n            vec4 _1744 = c;\n            vec3 _1747 = _1744.xyz + vec3(_1719 * 0.0039215688593685626983642578125);\n            vec4 _2450 = _1744;\n            _2450.x = _1747.x;\n            _2450.y = _1747.y;\n            _2450.z = _1747.z;\n            c = _2450;\n        }\n        vec4 _2455 = c;\n        _2455.w = clamp(_2455.w + ((_1719 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2455.w)), 0.0, 1.0);\n        c = _2455;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1239 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1241 = texture(tex_smp, uv - _1239);\n    float _1242 = _1241.w;\n    vec4 _1252 = texture(tex_smp, uv + _1239);\n    float _1253 = _1252.w;\n    vec2 _1261 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1263 = texture(tex_smp, uv - _1261);\n    float _1264 = _1263.w;\n    vec4 _1274 = texture(tex_smp, uv + _1261);\n    float _1275 = _1274.w;\n    float _1290 = _1242 - _1253;\n    float _1293 = _1275 - _1264;\n    float _1303 = cos(params.y);\n    float _1305 = sin(params.y);\n    vec2 _1331 = ((vec2(_1303, _1305) * _1290) + ((vec2(-_1305, _1303) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1293)) / vec2(max(length(vec2(_1290, _1293)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1377 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1380 = length(_1377);\n            att = pow(clamp(1.0 - (_1380 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1377 / vec2(max(_1380, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1377;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1377;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1331, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1242, _1253), min(_1264, _1275))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _737 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _741 = _737.y;\n    return vec2(_737.x, mix(_741, 1.0 - _741, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _777 = base_mode < 0.5;\n    bool _788;\n    if (!_777)\n    {\n        _788 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _788 = _777;\n    }\n    float _789;\n    if (_788)\n    {\n        _789 = shape_half.x;\n    }\n    else\n    {\n        _789 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _789);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[95].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _706 = (uv_1 * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    float _708 = _706.y;\n    _706.y = mix(_708, 1.0 - _708, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_706, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + (vec2(fa_material[1].x + fa_material[3].x, 0.0) * quad_fs_params[58].xy);\n    s.color = vec4(mix(fa_scene_color(param).xyz, fa_material[4].xyz, vec3(fa_material[4].w)), 1.0);\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1774 = params.x > 31.5;\n    if (_1774)\n    {\n        mode -= 32.0;\n    }\n    float _1782 = mode;\n    bool _1784 = _1782 > 15.5;\n    if (_1784)\n    {\n        mode -= 16.0;\n    }\n    float _1792 = mode;\n    bool _1794 = _1792 > 7.5;\n    if (_1794)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1784)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1784)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1856 = tex_color(param_5);\n                vec4 _1858 = _1856 * color;\n                vec4 param_6 = _1858;\n                float param_7 = mode;\n                float _1865 = _1858.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1865);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1865;\n                    float param_9 = mode;\n                    vec4 _1881 = frag_color;\n                    vec3 _1883 = _1881.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1883.x;\n                    frag_color.y = _1883.y;\n                    frag_color.z = _1883.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1913 = length(uv);\n                    float _1916 = fwidth(_1913);\n                    float _1917 = max(_1916, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1913) / _1917) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1913) / _1917) + 0.5, 0.0, 1.0) * clamp(((_1913 - params.y) / _1917) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1957 = clamp(1.0 - _1913, 0.0, 1.0);\n                            cov = (_1957 * _1957) * (3.0 - (2.0 * _1957));\n                        }\n                    }\n                    vec3 _1966;\n                    if (_1784)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1966 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1966 = color.xyz;\n                    }\n                    frag_color = vec4(_1966, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _2020 = fa_tex_fix(param_12, param_13);\n            e *= _2020;\n        }\n        vec4 _2024 = frag_color;\n        vec3 _2026 = _2024.xyz + e;\n        frag_color.x = _2026.x;\n        frag_color.y = _2026.y;\n        frag_color.z = _2026.z;\n    }\n    float param_14 = mode;\n    vec4 _2351 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2351);\n    fragment(param_15, param_16);\n    _2351 = param_16.color;\n    frag_color = param_16.color;\n    if (_1774)\n    {\n        vec4 _2052 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _2057 = scene_rgb(param_17);\n        vec3 _2061 = mix(_2052.xyz, _2057, vec3(color2.w));\n        frag_color.x = _2061.x;\n        frag_color.y = _2061.y;\n        frag_color.z = _2061.z;\n    }\n    if (_1794)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2084 = quad_fs_params[53].w > 0.0;\n    bool _2092;\n    if (!_2084)\n    {\n        _2092 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2092 = _2084;\n    }\n    if (_2092)\n    {\n        vec3 _2105 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2112 = dot(_2105, quad_fs_params[55].xyz);\n        bool _2116 = quad_fs_params[55].w > 0.5;\n        float _2117;\n        if (_2116)\n        {\n            _2117 = _2112;\n        }\n        else\n        {\n            _2117 = length(_2105);\n        }\n        float _2129 = _2117 - quad_fs_params[54].x;\n        if (_2129 > 0.0)\n        {\n            float _2138 = quad_fs_params[53].w * _2129;\n            float tau = _2138 * _2138;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2154;\n                if (_2116)\n                {\n                    _2154 = world_xy.y - (quad_fs_params[55].y * _2112);\n                }\n                else\n                {\n                    _2154 = quad_fs_params[56].y;\n                }\n                float _2175 = mix(_2154, world_xy.y, clamp(quad_fs_params[54].x / _2117, 0.0, 1.0));\n                float _2179 = world_xy.y - _2175;\n                float _2184 = _2175 - quad_fs_params[54].z;\n                float _2189 = world_xy.y - quad_fs_params[54].z;\n                bool _2192 = _2184 <= 0.0;\n                bool _2193 = !_2192;\n                bool _2199;\n                if (_2193)\n                {\n                    _2199 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2199 = _2192;\n                }\n                float _2200;\n                if (_2199)\n                {\n                    _2200 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2200 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2184, 80.0));\n                }\n                bool _2227;\n                if (_2193)\n                {\n                    _2227 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2227 = _2192;\n                }\n                float _2228;\n                if (_2227)\n                {\n                    _2228 = quad_fs_params[54].y * _2184;\n                }\n                else\n                {\n                    _2228 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2184, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2253 = _2189 <= 0.0;\n                bool _2260;\n                if (!_2253)\n                {\n                    _2260 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2260 = _2253;\n                }\n                float _2261;\n                if (_2260)\n                {\n                    _2261 = quad_fs_params[54].y * _2189;\n                }\n                else\n                {\n                    _2261 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2189, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2288;\n                if (abs(_2179) < 0.001000000047497451305389404296875)\n                {\n                    _2288 = _2200;\n                }\n                else\n                {\n                    _2288 = (_2261 - _2228) / _2179;\n                }\n                tau += (_2129 * max(_2288, 0.0));\n            }\n            vec4 _2311 = frag_color;\n            vec3 _2319 = mix(_2311.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2319.x;\n            frag_color.y = _2319.y;\n            frag_color.z = _2319.z;\n        }\n    }\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_686",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 101,
                "offset": 0,
                "glsl_name": "quad_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_804",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 8,
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
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fx_gi_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 15,
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
            "name": "fx_gi_tex_light_smp",
            "view_name": "fx_gi_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1,
            "glsl_name": "fx_gi_tex_light_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1,
            "glsl_name": "light_tex_light_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2,
            "glsl_name": "shadow_tex_shadow_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1,
            "glsl_name": "fx_cookie_tex_light_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0,
            "glsl_name": "fx_emissive_tex_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 15,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[8];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _191 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _195 = _191.y;\n    return vec2(_191.x, mix(_195, 1.0 - _195, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _235 = base_mode < 0.5;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _247);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[95].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _152 = (uv_1 * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    float _155 = _152.y;\n    _152.y = mix(_155, 1.0 - _155, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_152, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + (vec2(fa_material[1].x + fa_material[3].x, 0.0) * quad_fs_params[58].xy);\n    s.color = vec4(mix(fa_scene_color(param).xyz, fa_material[4].xyz, vec3(fa_material[4].w)), 1.0);\n}\n\nvoid main()\n{\n    vec4 _330 = texture(tex_smp, uv);\n    vec3 param = _330.xyz;\n    float param_1 = xform.y;\n    vec3 _341 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_341, _330.w) * color;\n    float param_2 = 0.0;\n    vec4 _394 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_394);\n    fragment(param_3, param_4);\n    _394 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_130",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 101,
                "offset": 0,
                "glsl_name": "quad_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_263",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 8,
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
              "slot": 15,
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
            "view_slot": 15,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    }
  }
}
