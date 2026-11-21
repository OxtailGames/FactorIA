{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nuniform vec4 fa_material[8];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\nlayout(binding = 6) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _881 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _881.xy, 0.0);\n    return cookie_value(param_3) * _881.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _902 = quad_fs_params[0].y > 0.5;\n    if (_902)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _926 = fa_tex_fix(param, param_1);\n        vec3 _930 = (_926 * 2.0) - vec3(1.0);\n        float _937 = cos(params.y);\n        float _939 = sin(params.y);\n        n = normalize(vec3((vec2(_937, _939) * _930.x) + ((vec2(-_939, _937) * ((mode > 5.5) ? (-1.0) : 1.0)) * _930.y), max(_930.z, 0.0500000007450580596923828125)));\n    }\n    bool _973 = !_902;\n    bool _979;\n    if (_973)\n    {\n        _979 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _979 = _973;\n    }\n    vec3 _982;\n    if (_979)\n    {\n        _982 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _982 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _982;\n    bool _999;\n    if (_979)\n    {\n        _999 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _999 = _979;\n    }\n    if (_999)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1126;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1036;\n        if (!_979)\n        {\n            _1036 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1036 = _979;\n        }\n        if (_1036)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1062 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1062) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1082 = vec3(_1062, quad_fs_params[i * 1 + 5].z);\n            l = _1082 / vec3(max(length(_1082), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1062;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1062;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_902)\n        {\n            _1126 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1126 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1126));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1376 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1380 = uv * _1376;\n    float _1386 = _1376.x;\n    float _1388 = _1376.y;\n    float _1390 = clamp(shape_rs.x, 0.0, min(_1386, _1388));\n    vec2 _1401 = (abs(_1380) - _1376) + vec2(_1390);\n    float d = (length(max(_1401, vec2(0.0))) + min(max(_1401.x, _1401.y), 0.0)) - _1390;\n    float ax = params.y;\n    bool _1422 = params.y > 15.0;\n    if (_1422)\n    {\n        ax -= 20.0;\n    }\n    float _1433;\n    if (ax <= (-1.5))\n    {\n        _1433 = (-2.0) - ax;\n    }\n    else\n    {\n        _1433 = 0.0;\n    }\n    if (_1433 > 0.0)\n    {\n        float _1447 = _1433 * 0.5;\n        d = abs(d + _1447) - _1447;\n    }\n    float _1455 = fwidth(d);\n    float _1456 = max(_1455, 9.9999997473787516355514526367188e-05);\n    float _1466 = clamp(0.5 - (d / max(shape_rs.y, _1456)), 0.0, 1.0);\n    float _1471;\n    if (shape_rs.y > _1456)\n    {\n        _1471 = (_1466 * _1466) * (3.0 - (2.0 * _1466));\n    }\n    else\n    {\n        _1471 = _1466;\n    }\n    vec4 c = color;\n    bool _1493 = (_1433 <= 0.0) && (ax > (-0.5));\n    if (_1493)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1508 = cos(ax);\n            float _1510 = sin(ax);\n            g = ((dot(_1380, vec2(_1508, _1510)) / max((abs(_1508) * _1386) + (abs(_1510) * _1388), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1422)\n        {\n            vec4 _1553 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1553;\n            vec3 param = _1553.xyz;\n            float param_1 = xform.y;\n            vec3 _1560 = fa_tex_fix(param, param_1);\n            vec4 _2349 = c;\n            _2349.x = _1560.x;\n            _2349.y = _1560.y;\n            _2349.z = _1560.z;\n            c = _2349;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1572 = scene_rgb(param_2);\n            vec4 _1597 = mix(vec4(color.xyz * color.w, color.w), vec4(_1572 * color2.w, color2.w), vec4(g));\n            float _1599 = _1597.w;\n            vec3 _1602;\n            if (_1599 > 9.9999997473787516355514526367188e-06)\n            {\n                _1602 = _1597.xyz / vec3(_1599);\n            }\n            else\n            {\n                _1602 = color.xyz;\n            }\n            c = vec4(_1602, _1599);\n        }\n    }\n    vec4 _2358 = c;\n    _2358.w = _2358.w * _1471;\n    c = _2358;\n    if (_1493 || (shape_rs.y > 0.0))\n    {\n        float _1643 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1652 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1652 + vec3(_1643 * 0.0039215688593685626983642578125);\n            vec3 _1658 = fa_srgb_to_linear(param_4);\n            vec4 _2361 = c;\n            _2361.x = _1658.x;\n            _2361.y = _1658.y;\n            _2361.z = _1658.z;\n            c = _2361;\n        }\n        else\n        {\n            vec4 _1668 = c;\n            vec3 _1671 = _1668.xyz + vec3(_1643 * 0.0039215688593685626983642578125);\n            vec4 _2368 = _1668;\n            _2368.x = _1671.x;\n            _2368.y = _1671.y;\n            _2368.z = _1671.z;\n            c = _2368;\n        }\n        vec4 _2373 = c;\n        _2373.w = clamp(_2373.w + ((_1643 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2373.w)), 0.0, 1.0);\n        c = _2373;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1163 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1165 = texture(tex_smp, uv - _1163);\n    float _1166 = _1165.w;\n    vec4 _1176 = texture(tex_smp, uv + _1163);\n    float _1177 = _1176.w;\n    vec2 _1185 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1187 = texture(tex_smp, uv - _1185);\n    float _1188 = _1187.w;\n    vec4 _1198 = texture(tex_smp, uv + _1185);\n    float _1199 = _1198.w;\n    float _1214 = _1166 - _1177;\n    float _1217 = _1199 - _1188;\n    float _1227 = cos(params.y);\n    float _1229 = sin(params.y);\n    vec2 _1255 = ((vec2(_1227, _1229) * _1214) + ((vec2(-_1229, _1227) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1217)) / vec2(max(length(vec2(_1214, _1217)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1301 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1304 = length(_1301);\n            att = pow(clamp(1.0 - (_1304 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1301 / vec2(max(_1304, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1301;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1301;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1255, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1166, _1177), min(_1188, _1199))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _734 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _738 = _734.y;\n    return vec2(_734.x, mix(_738, 1.0 - _738, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _774 = base_mode < 0.5;\n    bool _785;\n    if (!_774)\n    {\n        _785 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _785 = _774;\n    }\n    float _786;\n    if (_785)\n    {\n        _786 = shape_half.x;\n    }\n    else\n    {\n        _786 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _786);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[95].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _703 = (uv_1 * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    float _705 = _703.y;\n    _703.y = mix(_705, 1.0 - _705, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_703, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + (vec2(fa_material[1].x + fa_material[3].x, 0.0) * quad_fs_params[58].xy);\n    s.color = vec4(mix(fa_scene_color(param).xyz, fa_material[4].xyz, vec3(fa_material[4].w)), 1.0);\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1698 = params.x > 31.5;\n    if (_1698)\n    {\n        mode -= 32.0;\n    }\n    float _1706 = mode;\n    bool _1708 = _1706 > 15.5;\n    if (_1708)\n    {\n        mode -= 16.0;\n    }\n    float _1716 = mode;\n    bool _1718 = _1716 > 7.5;\n    if (_1718)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1708)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1708)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1780 = tex_color(param_5);\n                vec4 _1782 = _1780 * color;\n                vec4 param_6 = _1782;\n                float param_7 = mode;\n                float _1789 = _1782.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1789);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1789;\n                    float param_9 = mode;\n                    vec4 _1805 = frag_color;\n                    vec3 _1807 = _1805.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1807.x;\n                    frag_color.y = _1807.y;\n                    frag_color.z = _1807.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1837 = length(uv);\n                    float _1840 = fwidth(_1837);\n                    float _1841 = max(_1840, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1837) / _1841) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1837) / _1841) + 0.5, 0.0, 1.0) * clamp(((_1837 - params.y) / _1841) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1881 = clamp(1.0 - _1837, 0.0, 1.0);\n                            cov = (_1881 * _1881) * (3.0 - (2.0 * _1881));\n                        }\n                    }\n                    vec3 _1890;\n                    if (_1708)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1890 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1890 = color.xyz;\n                    }\n                    frag_color = vec4(_1890, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1944 = fa_tex_fix(param_12, param_13);\n            e *= _1944;\n        }\n        vec4 _1948 = frag_color;\n        vec3 _1950 = _1948.xyz + e;\n        frag_color.x = _1950.x;\n        frag_color.y = _1950.y;\n        frag_color.z = _1950.z;\n    }\n    float param_14 = mode;\n    vec4 _2275 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2275);\n    fragment(param_15, param_16);\n    _2275 = param_16.color;\n    frag_color = param_16.color;\n    if (_1698)\n    {\n        vec4 _1976 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1981 = scene_rgb(param_17);\n        vec3 _1985 = mix(_1976.xyz, _1981, vec3(color2.w));\n        frag_color.x = _1985.x;\n        frag_color.y = _1985.y;\n        frag_color.z = _1985.z;\n    }\n    if (_1718)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2008 = quad_fs_params[53].w > 0.0;\n    bool _2016;\n    if (!_2008)\n    {\n        _2016 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2016 = _2008;\n    }\n    if (_2016)\n    {\n        vec3 _2029 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2036 = dot(_2029, quad_fs_params[55].xyz);\n        bool _2040 = quad_fs_params[55].w > 0.5;\n        float _2041;\n        if (_2040)\n        {\n            _2041 = _2036;\n        }\n        else\n        {\n            _2041 = length(_2029);\n        }\n        float _2053 = _2041 - quad_fs_params[54].x;\n        if (_2053 > 0.0)\n        {\n            float _2062 = quad_fs_params[53].w * _2053;\n            float tau = _2062 * _2062;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2078;\n                if (_2040)\n                {\n                    _2078 = world_xy.y - (quad_fs_params[55].y * _2036);\n                }\n                else\n                {\n                    _2078 = quad_fs_params[56].y;\n                }\n                float _2099 = mix(_2078, world_xy.y, clamp(quad_fs_params[54].x / _2041, 0.0, 1.0));\n                float _2103 = world_xy.y - _2099;\n                float _2108 = _2099 - quad_fs_params[54].z;\n                float _2113 = world_xy.y - quad_fs_params[54].z;\n                bool _2116 = _2108 <= 0.0;\n                bool _2117 = !_2116;\n                bool _2123;\n                if (_2117)\n                {\n                    _2123 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2123 = _2116;\n                }\n                float _2124;\n                if (_2123)\n                {\n                    _2124 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2124 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2108, 80.0));\n                }\n                bool _2151;\n                if (_2117)\n                {\n                    _2151 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2151 = _2116;\n                }\n                float _2152;\n                if (_2151)\n                {\n                    _2152 = quad_fs_params[54].y * _2108;\n                }\n                else\n                {\n                    _2152 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2108, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2177 = _2113 <= 0.0;\n                bool _2184;\n                if (!_2177)\n                {\n                    _2184 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2184 = _2177;\n                }\n                float _2185;\n                if (_2184)\n                {\n                    _2185 = quad_fs_params[54].y * _2113;\n                }\n                else\n                {\n                    _2185 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2113, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2212;\n                if (abs(_2103) < 0.001000000047497451305389404296875)\n                {\n                    _2212 = _2124;\n                }\n                else\n                {\n                    _2212 = (_2185 - _2152) / _2103;\n                }\n                tau += (_2053 * max(_2212, 0.0));\n            }\n            vec4 _2235 = frag_color;\n            vec3 _2243 = mix(_2235.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2243.x;\n            frag_color.y = _2243.y;\n            frag_color.z = _2243.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_683",
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
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_801",
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
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nuniform vec4 fa_material[8];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _191 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _195 = _191.y;\n    return vec2(_191.x, mix(_195, 1.0 - _195, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _235 = base_mode < 0.5;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _247);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[95].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _152 = (uv_1 * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    float _155 = _152.y;\n    _152.y = mix(_155, 1.0 - _155, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_152, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + (vec2(fa_material[1].x + fa_material[3].x, 0.0) * quad_fs_params[58].xy);\n    s.color = vec4(mix(fa_scene_color(param).xyz, fa_material[4].xyz, vec3(fa_material[4].w)), 1.0);\n}\n\nvoid main()\n{\n    vec4 _330 = texture(tex_smp, uv);\n    vec3 param = _330.xyz;\n    float param_1 = xform.y;\n    vec3 _341 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_341, _330.w) * color;\n    float param_2 = 0.0;\n    vec4 _394 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_394);\n    fragment(param_3, param_4);\n    _394 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_130",
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
              "slot": 14,
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
            "view_slot": 14,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    }
  }
}
