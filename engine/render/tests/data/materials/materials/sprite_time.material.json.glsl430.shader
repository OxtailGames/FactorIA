{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "be09d710d10cdccec43655f10e6af3b043d5ce26db7fbf1ce164733ea9edbe00",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _819 = (world_xy * quad_fs_params[99].xy) + quad_fs_params[99].zw;\n    vec4 _826 = textureLod(fx_gi_tex_light_smp, _819, 0.0);\n    float _830 = _819.x;\n    bool _831 = _830 >= 0.0;\n    bool _837;\n    if (_831)\n    {\n        _837 = _819.y >= 0.0;\n    }\n    else\n    {\n        _837 = _831;\n    }\n    bool _843;\n    if (_837)\n    {\n        _843 = _830 <= 1.0;\n    }\n    else\n    {\n        _843 = _837;\n    }\n    bool _849;\n    if (_843)\n    {\n        _849 = _819.y <= 1.0;\n    }\n    else\n    {\n        _849 = _843;\n    }\n    bool _857;\n    if (_849)\n    {\n        _857 = _826.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _857 = _849;\n    }\n    vec3 _858;\n    if (_857)\n    {\n        _858 = (_826.xyz / vec3(_826.w)) * quad_fs_params[100].x;\n    }\n    else\n    {\n        _858 = vec3(0.0);\n    }\n    return _858;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _793 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _793.xy, 0.0);\n    return cookie_value(param_3) * _793.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _880 = quad_fs_params[0].y > 0.5;\n    if (_880)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _904 = fa_tex_fix(param, param_1);\n        vec3 _908 = (_904 * 2.0) - vec3(1.0);\n        float _915 = cos(params.y);\n        float _917 = sin(params.y);\n        n = normalize(vec3((vec2(_915, _917) * _908.x) + ((vec2(-_917, _915) * ((mode > 5.5) ? (-1.0) : 1.0)) * _908.y), max(_908.z, 0.0500000007450580596923828125)));\n    }\n    bool _951 = !_880;\n    bool _957;\n    if (_951)\n    {\n        _957 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _957 = _951;\n    }\n    vec3 _960;\n    if (_957)\n    {\n        _960 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _960 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _960;\n    if (quad_fs_params[100].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _985;\n    if (_957)\n    {\n        _985 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _985 = _957;\n    }\n    if (_985)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1112;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1022;\n        if (!_957)\n        {\n            _1022 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1022 = _957;\n        }\n        if (_1022)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1048 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1048) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1068 = vec3(_1048, quad_fs_params[i * 1 + 5].z);\n            l = _1068 / vec3(max(length(_1068), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1048;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1048;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_880)\n        {\n            _1112 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1112 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1112));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1362 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1366 = uv * _1362;\n    float _1372 = _1362.x;\n    float _1374 = _1362.y;\n    float _1376 = clamp(shape_rs.x, 0.0, min(_1372, _1374));\n    vec2 _1387 = (abs(_1366) - _1362) + vec2(_1376);\n    float d = (length(max(_1387, vec2(0.0))) + min(max(_1387.x, _1387.y), 0.0)) - _1376;\n    float ax = params.y;\n    bool _1408 = params.y > 15.0;\n    if (_1408)\n    {\n        ax -= 20.0;\n    }\n    float _1419;\n    if (ax <= (-1.5))\n    {\n        _1419 = (-2.0) - ax;\n    }\n    else\n    {\n        _1419 = 0.0;\n    }\n    if (_1419 > 0.0)\n    {\n        float _1433 = _1419 * 0.5;\n        d = abs(d + _1433) - _1433;\n    }\n    float _1441 = fwidth(d);\n    float _1442 = max(_1441, 9.9999997473787516355514526367188e-05);\n    float _1452 = clamp(0.5 - (d / max(shape_rs.y, _1442)), 0.0, 1.0);\n    float _1457;\n    if (shape_rs.y > _1442)\n    {\n        _1457 = (_1452 * _1452) * (3.0 - (2.0 * _1452));\n    }\n    else\n    {\n        _1457 = _1452;\n    }\n    vec4 c = color;\n    bool _1479 = (_1419 <= 0.0) && (ax > (-0.5));\n    if (_1479)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1494 = cos(ax);\n            float _1496 = sin(ax);\n            g = ((dot(_1366, vec2(_1494, _1496)) / max((abs(_1494) * _1372) + (abs(_1496) * _1374), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1408)\n        {\n            vec4 _1539 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1539;\n            vec3 param = _1539.xyz;\n            float param_1 = xform.y;\n            vec3 _1546 = fa_tex_fix(param, param_1);\n            vec4 _2341 = c;\n            _2341.x = _1546.x;\n            _2341.y = _1546.y;\n            _2341.z = _1546.z;\n            c = _2341;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1558 = scene_rgb(param_2);\n            vec4 _1583 = mix(vec4(color.xyz * color.w, color.w), vec4(_1558 * color2.w, color2.w), vec4(g));\n            float _1585 = _1583.w;\n            vec3 _1588;\n            if (_1585 > 9.9999997473787516355514526367188e-06)\n            {\n                _1588 = _1583.xyz / vec3(_1585);\n            }\n            else\n            {\n                _1588 = color.xyz;\n            }\n            c = vec4(_1588, _1585);\n        }\n    }\n    vec4 _2350 = c;\n    _2350.w = _2350.w * _1457;\n    c = _2350;\n    if (_1479 || (shape_rs.y > 0.0))\n    {\n        float _1629 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1638 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1638 + vec3(_1629 * 0.0039215688593685626983642578125);\n            vec3 _1644 = fa_srgb_to_linear(param_4);\n            vec4 _2353 = c;\n            _2353.x = _1644.x;\n            _2353.y = _1644.y;\n            _2353.z = _1644.z;\n            c = _2353;\n        }\n        else\n        {\n            vec4 _1654 = c;\n            vec3 _1657 = _1654.xyz + vec3(_1629 * 0.0039215688593685626983642578125);\n            vec4 _2360 = _1654;\n            _2360.x = _1657.x;\n            _2360.y = _1657.y;\n            _2360.z = _1657.z;\n            c = _2360;\n        }\n        vec4 _2365 = c;\n        _2365.w = clamp(_2365.w + ((_1629 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2365.w)), 0.0, 1.0);\n        c = _2365;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1149 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1151 = texture(tex_smp, uv - _1149);\n    float _1152 = _1151.w;\n    vec4 _1162 = texture(tex_smp, uv + _1149);\n    float _1163 = _1162.w;\n    vec2 _1171 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1173 = texture(tex_smp, uv - _1171);\n    float _1174 = _1173.w;\n    vec4 _1184 = texture(tex_smp, uv + _1171);\n    float _1185 = _1184.w;\n    float _1200 = _1152 - _1163;\n    float _1203 = _1185 - _1174;\n    float _1213 = cos(params.y);\n    float _1215 = sin(params.y);\n    vec2 _1241 = ((vec2(_1213, _1215) * _1200) + ((vec2(-_1215, _1213) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1203)) / vec2(max(length(vec2(_1200, _1203)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1287 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1290 = length(_1287);\n            att = pow(clamp(1.0 - (_1290 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1287 / vec2(max(_1290, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1287;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1287;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1241, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1152, _1163), min(_1174, _1185))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _694 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _698 = _694.y;\n    return vec2(_694.x, mix(_698, 1.0 - _698, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _736 = base_mode < 0.5;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _748);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1684 = params.x > 31.5;\n    if (_1684)\n    {\n        mode -= 32.0;\n    }\n    float _1692 = mode;\n    bool _1694 = _1692 > 15.5;\n    if (_1694)\n    {\n        mode -= 16.0;\n    }\n    float _1702 = mode;\n    bool _1704 = _1702 > 7.5;\n    if (_1704)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1694)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1694)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1766 = tex_color(param_5);\n                vec4 _1768 = _1766 * color;\n                vec4 param_6 = _1768;\n                float param_7 = mode;\n                float _1775 = _1768.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1775);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1775;\n                    float param_9 = mode;\n                    vec4 _1791 = frag_color;\n                    vec3 _1793 = _1791.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1793.x;\n                    frag_color.y = _1793.y;\n                    frag_color.z = _1793.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1823 = length(uv);\n                    float _1826 = fwidth(_1823);\n                    float _1827 = max(_1826, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1823) / _1827) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1823) / _1827) + 0.5, 0.0, 1.0) * clamp(((_1823 - params.y) / _1827) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1867 = clamp(1.0 - _1823, 0.0, 1.0);\n                            cov = (_1867 * _1867) * (3.0 - (2.0 * _1867));\n                        }\n                    }\n                    vec3 _1876;\n                    if (_1694)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1876 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1876 = color.xyz;\n                    }\n                    frag_color = vec4(_1876, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1931 = fa_tex_fix(param_12, param_13);\n            e *= _1931;\n        }\n        vec4 _1935 = frag_color;\n        vec3 _1937 = _1935.xyz + e;\n        frag_color.x = _1937.x;\n        frag_color.y = _1937.y;\n        frag_color.z = _1937.z;\n    }\n    float param_14 = mode;\n    vec4 _2265 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2265);\n    fragment(param_15, param_16);\n    _2265 = param_16.color;\n    frag_color = param_16.color;\n    if (_1684)\n    {\n        vec4 _1963 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1968 = scene_rgb(param_17);\n        vec3 _1972 = mix(_1963.xyz, _1968, vec3(color2.w));\n        frag_color.x = _1972.x;\n        frag_color.y = _1972.y;\n        frag_color.z = _1972.z;\n    }\n    if (_1704)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1996 = quad_fs_params[53].w > 0.0;\n    bool _2004;\n    if (!_1996)\n    {\n        _2004 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2004 = _1996;\n    }\n    if (_2004)\n    {\n        vec3 _2018 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2025 = dot(_2018, quad_fs_params[55].xyz);\n        bool _2029 = quad_fs_params[55].w > 0.5;\n        float _2030;\n        if (_2029)\n        {\n            _2030 = _2025;\n        }\n        else\n        {\n            _2030 = length(_2018);\n        }\n        float _2042 = _2030 - quad_fs_params[54].x;\n        if (_2042 > 0.0)\n        {\n            float _2051 = quad_fs_params[53].w * _2042;\n            float tau = _2051 * _2051;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2067;\n                if (_2029)\n                {\n                    _2067 = world_xy.y - (quad_fs_params[55].y * _2025);\n                }\n                else\n                {\n                    _2067 = quad_fs_params[56].y;\n                }\n                float _2088 = mix(_2067, world_xy.y, clamp(quad_fs_params[54].x / _2030, 0.0, 1.0));\n                float _2092 = world_xy.y - _2088;\n                float _2097 = _2088 - quad_fs_params[54].z;\n                float _2102 = world_xy.y - quad_fs_params[54].z;\n                bool _2105 = _2097 <= 0.0;\n                bool _2106 = !_2105;\n                bool _2112;\n                if (_2106)\n                {\n                    _2112 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2112 = _2105;\n                }\n                float _2113;\n                if (_2112)\n                {\n                    _2113 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2113 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2097, 80.0));\n                }\n                bool _2140;\n                if (_2106)\n                {\n                    _2140 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2140 = _2105;\n                }\n                float _2141;\n                if (_2140)\n                {\n                    _2141 = quad_fs_params[54].y * _2097;\n                }\n                else\n                {\n                    _2141 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2097, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2166 = _2102 <= 0.0;\n                bool _2173;\n                if (!_2166)\n                {\n                    _2173 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2173 = _2166;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = quad_fs_params[54].y * _2102;\n                }\n                else\n                {\n                    _2174 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2102, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2201;\n                if (abs(_2092) < 0.001000000047497451305389404296875)\n                {\n                    _2201 = _2113;\n                }\n                else\n                {\n                    _2201 = (_2174 - _2141) / _2092;\n                }\n                tau += (_2042 * max(_2201, 0.0));\n            }\n            vec4 _2224 = frag_color;\n            vec3 _2232 = mix(_2224.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2232.x;\n            frag_color.y = _2232.y;\n            frag_color.z = _2232.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_688",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 101,
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _138 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _144 = _138.y;\n    return vec2(_138.x, mix(_144, 1.0 - _144, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _200);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    vec4 _237 = texture(tex_smp, uv);\n    vec3 param = _237.xyz;\n    float param_1 = xform.y;\n    vec3 _248 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_248, _237.w) * color;\n    float param_2 = 0.0;\n    vec4 _303 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_303);\n    fragment(param_3, param_4);\n    _303 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 101,
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
