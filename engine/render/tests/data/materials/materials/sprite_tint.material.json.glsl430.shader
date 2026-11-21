{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _647 = texture(tex_smp, p);\n    vec3 param = _647.xyz;\n    float param_1 = xform.y;\n    vec3 _657 = fa_tex_fix(param, param_1);\n    return vec4(_657, _647.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _832 = (world_xy * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    vec4 _839 = textureLod(fx_gi_tex_light_smp, _832, 0.0);\n    float _843 = _832.x;\n    bool _844 = _843 >= 0.0;\n    bool _850;\n    if (_844)\n    {\n        _850 = _832.y >= 0.0;\n    }\n    else\n    {\n        _850 = _844;\n    }\n    bool _856;\n    if (_850)\n    {\n        _856 = _843 <= 1.0;\n    }\n    else\n    {\n        _856 = _850;\n    }\n    bool _862;\n    if (_856)\n    {\n        _862 = _832.y <= 1.0;\n    }\n    else\n    {\n        _862 = _856;\n    }\n    bool _870;\n    if (_862)\n    {\n        _870 = _839.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _870 = _862;\n    }\n    vec3 _871;\n    if (_870)\n    {\n        _871 = (_839.xyz / vec3(_839.w)) * quad_fs_params[96].x;\n    }\n    else\n    {\n        _871 = vec3(0.0);\n    }\n    return _871;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _137 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = atan(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = atan(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _500 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    vec2 c = vec2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    vec2 _532 = c;\n    vec2 _537 = clamp(_532, vec2(0.001953125), vec2(0.998046875));\n    c = _537;\n    return vec3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _806 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _806.xy, 0.0);\n    return cookie_value(param_3) * _806.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _893 = quad_fs_params[0].y > 0.5;\n    if (_893)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _917 = fa_tex_fix(param, param_1);\n        vec3 _921 = (_917 * 2.0) - vec3(1.0);\n        float _928 = cos(params.y);\n        float _930 = sin(params.y);\n        n = normalize(vec3((vec2(_928, _930) * _921.x) + ((vec2(-_930, _928) * ((mode > 5.5) ? (-1.0) : 1.0)) * _921.y), max(_921.z, 0.0500000007450580596923828125)));\n    }\n    bool _964 = !_893;\n    bool _970;\n    if (_964)\n    {\n        _970 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _970 = _964;\n    }\n    vec3 _973;\n    if (_970)\n    {\n        _973 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _973 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _973;\n    if (quad_fs_params[96].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _998;\n    if (_970)\n    {\n        _998 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _998 = _970;\n    }\n    if (_998)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1125;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1035;\n        if (!_970)\n        {\n            _1035 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1035 = _970;\n        }\n        if (_1035)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1061 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1061) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1081 = vec3(_1061, quad_fs_params[i * 1 + 5].z);\n            l = _1081 / vec3(max(length(_1081), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1061;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1061;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_893)\n        {\n            _1125 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1125 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1125));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1375 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1379 = uv * _1375;\n    float _1385 = _1375.x;\n    float _1387 = _1375.y;\n    float _1389 = clamp(shape_rs.x, 0.0, min(_1385, _1387));\n    vec2 _1400 = (abs(_1379) - _1375) + vec2(_1389);\n    float d = (length(max(_1400, vec2(0.0))) + min(max(_1400.x, _1400.y), 0.0)) - _1389;\n    float ax = params.y;\n    bool _1421 = params.y > 15.0;\n    if (_1421)\n    {\n        ax -= 20.0;\n    }\n    float _1432;\n    if (ax <= (-1.5))\n    {\n        _1432 = (-2.0) - ax;\n    }\n    else\n    {\n        _1432 = 0.0;\n    }\n    if (_1432 > 0.0)\n    {\n        float _1446 = _1432 * 0.5;\n        d = abs(d + _1446) - _1446;\n    }\n    float _1454 = fwidth(d);\n    float _1455 = max(_1454, 9.9999997473787516355514526367188e-05);\n    float _1465 = clamp(0.5 - (d / max(shape_rs.y, _1455)), 0.0, 1.0);\n    float _1470;\n    if (shape_rs.y > _1455)\n    {\n        _1470 = (_1465 * _1465) * (3.0 - (2.0 * _1465));\n    }\n    else\n    {\n        _1470 = _1465;\n    }\n    vec4 c = color;\n    bool _1492 = (_1432 <= 0.0) && (ax > (-0.5));\n    if (_1492)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1507 = cos(ax);\n            float _1509 = sin(ax);\n            g = ((dot(_1379, vec2(_1507, _1509)) / max((abs(_1507) * _1385) + (abs(_1509) * _1387), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1421)\n        {\n            vec4 _1552 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1552;\n            vec3 param = _1552.xyz;\n            float param_1 = xform.y;\n            vec3 _1559 = fa_tex_fix(param, param_1);\n            vec4 _2353 = c;\n            _2353.x = _1559.x;\n            _2353.y = _1559.y;\n            _2353.z = _1559.z;\n            c = _2353;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1571 = scene_rgb(param_2);\n            vec4 _1596 = mix(vec4(color.xyz * color.w, color.w), vec4(_1571 * color2.w, color2.w), vec4(g));\n            float _1598 = _1596.w;\n            vec3 _1601;\n            if (_1598 > 9.9999997473787516355514526367188e-06)\n            {\n                _1601 = _1596.xyz / vec3(_1598);\n            }\n            else\n            {\n                _1601 = color.xyz;\n            }\n            c = vec4(_1601, _1598);\n        }\n    }\n    vec4 _2362 = c;\n    _2362.w = _2362.w * _1470;\n    c = _2362;\n    if (_1492 || (shape_rs.y > 0.0))\n    {\n        float _1642 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1651 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1651 + vec3(_1642 * 0.0039215688593685626983642578125);\n            vec3 _1657 = fa_srgb_to_linear(param_4);\n            vec4 _2365 = c;\n            _2365.x = _1657.x;\n            _2365.y = _1657.y;\n            _2365.z = _1657.z;\n            c = _2365;\n        }\n        else\n        {\n            vec4 _1667 = c;\n            vec3 _1670 = _1667.xyz + vec3(_1642 * 0.0039215688593685626983642578125);\n            vec4 _2372 = _1667;\n            _2372.x = _1670.x;\n            _2372.y = _1670.y;\n            _2372.z = _1670.z;\n            c = _2372;\n        }\n        vec4 _2377 = c;\n        _2377.w = clamp(_2377.w + ((_1642 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2377.w)), 0.0, 1.0);\n        c = _2377;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1162 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1164 = texture(tex_smp, uv - _1162);\n    float _1165 = _1164.w;\n    vec4 _1175 = texture(tex_smp, uv + _1162);\n    float _1176 = _1175.w;\n    vec2 _1184 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1186 = texture(tex_smp, uv - _1184);\n    float _1187 = _1186.w;\n    vec4 _1197 = texture(tex_smp, uv + _1184);\n    float _1198 = _1197.w;\n    float _1213 = _1165 - _1176;\n    float _1216 = _1198 - _1187;\n    float _1226 = cos(params.y);\n    float _1228 = sin(params.y);\n    vec2 _1254 = ((vec2(_1226, _1228) * _1213) + ((vec2(-_1228, _1226) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1216)) / vec2(max(length(vec2(_1213, _1216)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1300 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1303 = length(_1300);\n            att = pow(clamp(1.0 - (_1303 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1300 / vec2(max(_1303, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1300;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1300;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1254, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1165, _1176), min(_1187, _1198))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _701 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _705 = _701.y;\n    return vec2(_701.x, mix(_705, 1.0 - _705, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _743 = base_mode < 0.5;\n    bool _754;\n    if (!_743)\n    {\n        _754 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _754 = _743;\n    }\n    float _755;\n    if (_754)\n    {\n        _755 = shape_half.x;\n    }\n    else\n    {\n        _755 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _755);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _679 = scene_rgb(param);\n    return _679;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _776 = s.color;\n    vec3 _778 = _776.xyz * fa_scene_rgb(param);\n    s.color.x = _778.x;\n    s.color.y = _778.y;\n    s.color.z = _778.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1697 = params.x > 31.5;\n    if (_1697)\n    {\n        mode -= 32.0;\n    }\n    float _1705 = mode;\n    bool _1707 = _1705 > 15.5;\n    if (_1707)\n    {\n        mode -= 16.0;\n    }\n    float _1715 = mode;\n    bool _1717 = _1715 > 7.5;\n    if (_1717)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1707)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1707)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1779 = tex_color(param_5);\n                vec4 _1781 = _1779 * color;\n                vec4 param_6 = _1781;\n                float param_7 = mode;\n                float _1788 = _1781.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1788);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1788;\n                    float param_9 = mode;\n                    vec4 _1804 = frag_color;\n                    vec3 _1806 = _1804.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1806.x;\n                    frag_color.y = _1806.y;\n                    frag_color.z = _1806.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1836 = length(uv);\n                    float _1839 = fwidth(_1836);\n                    float _1840 = max(_1839, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1836) / _1840) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1836) / _1840) + 0.5, 0.0, 1.0) * clamp(((_1836 - params.y) / _1840) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1880 = clamp(1.0 - _1836, 0.0, 1.0);\n                            cov = (_1880 * _1880) * (3.0 - (2.0 * _1880));\n                        }\n                    }\n                    vec3 _1889;\n                    if (_1707)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1889 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1889 = color.xyz;\n                    }\n                    frag_color = vec4(_1889, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1944 = fa_tex_fix(param_12, param_13);\n            e *= _1944;\n        }\n        vec4 _1948 = frag_color;\n        vec3 _1950 = _1948.xyz + e;\n        frag_color.x = _1950.x;\n        frag_color.y = _1950.y;\n        frag_color.z = _1950.z;\n    }\n    float param_14 = mode;\n    vec4 _2277 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2277);\n    fragment(param_15, param_16);\n    _2277 = param_16.color;\n    frag_color = param_16.color;\n    if (_1697)\n    {\n        vec4 _1976 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1981 = scene_rgb(param_17);\n        vec3 _1985 = mix(_1976.xyz, _1981, vec3(color2.w));\n        frag_color.x = _1985.x;\n        frag_color.y = _1985.y;\n        frag_color.z = _1985.z;\n    }\n    if (_1717)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2009 = quad_fs_params[53].w > 0.0;\n    bool _2017;\n    if (!_2009)\n    {\n        _2017 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2017 = _2009;\n    }\n    if (_2017)\n    {\n        vec3 _2031 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2038 = dot(_2031, quad_fs_params[55].xyz);\n        bool _2042 = quad_fs_params[55].w > 0.5;\n        float _2043;\n        if (_2042)\n        {\n            _2043 = _2038;\n        }\n        else\n        {\n            _2043 = length(_2031);\n        }\n        float _2055 = _2043 - quad_fs_params[54].x;\n        if (_2055 > 0.0)\n        {\n            float _2064 = quad_fs_params[53].w * _2055;\n            float tau = _2064 * _2064;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2080;\n                if (_2042)\n                {\n                    _2080 = world_xy.y - (quad_fs_params[55].y * _2038);\n                }\n                else\n                {\n                    _2080 = quad_fs_params[56].y;\n                }\n                float _2101 = mix(_2080, world_xy.y, clamp(quad_fs_params[54].x / _2043, 0.0, 1.0));\n                float _2105 = world_xy.y - _2101;\n                float _2110 = _2101 - quad_fs_params[54].z;\n                float _2115 = world_xy.y - quad_fs_params[54].z;\n                bool _2118 = _2110 <= 0.0;\n                bool _2119 = !_2118;\n                bool _2125;\n                if (_2119)\n                {\n                    _2125 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2125 = _2118;\n                }\n                float _2126;\n                if (_2125)\n                {\n                    _2126 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2126 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2110, 80.0));\n                }\n                bool _2153;\n                if (_2119)\n                {\n                    _2153 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2153 = _2118;\n                }\n                float _2154;\n                if (_2153)\n                {\n                    _2154 = quad_fs_params[54].y * _2110;\n                }\n                else\n                {\n                    _2154 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2110, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2179 = _2115 <= 0.0;\n                bool _2186;\n                if (!_2179)\n                {\n                    _2186 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2186 = _2179;\n                }\n                float _2187;\n                if (_2186)\n                {\n                    _2187 = quad_fs_params[54].y * _2115;\n                }\n                else\n                {\n                    _2187 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2115, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2214;\n                if (abs(_2105) < 0.001000000047497451305389404296875)\n                {\n                    _2214 = _2126;\n                }\n                else\n                {\n                    _2214 = (_2187 - _2154) / _2105;\n                }\n                tau += (_2055 * max(_2214, 0.0));\n            }\n            vec4 _2237 = frag_color;\n            vec3 _2245 = mix(_2237.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2245.x;\n            frag_color.y = _2245.y;\n            frag_color.z = _2245.z;\n        }\n    }\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_695",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 97,
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
            "inst_name": "_769",
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
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _162 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _167 = _162.y;\n    return vec2(_162.x, mix(_167, 1.0 - _167, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _223);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _244 = s.color;\n    vec3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid main()\n{\n    vec4 _265 = texture(tex_smp, uv);\n    vec3 param = _265.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_274, _265.w) * color;\n    float param_2 = 0.0;\n    vec4 _328 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_328);\n    fragment(param_3, param_4);\n    _328 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_155",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 97,
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
