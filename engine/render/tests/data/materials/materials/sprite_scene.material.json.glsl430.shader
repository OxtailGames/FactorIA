{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "glsl430",
  "params": [
    "amount",
    "dx",
    "dy"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[3];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\nlayout(binding = 7) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _647 = texture(tex_smp, p);\n    vec3 param = _647.xyz;\n    float param_1 = xform.y;\n    vec3 _657 = fa_tex_fix(param, param_1);\n    return vec4(_657, _647.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _878 = (world_xy * quad_fs_params[99].xy) + quad_fs_params[99].zw;\n    vec4 _885 = textureLod(fx_gi_tex_light_smp, _878, 0.0);\n    float _889 = _878.x;\n    bool _890 = _889 >= 0.0;\n    bool _896;\n    if (_890)\n    {\n        _896 = _878.y >= 0.0;\n    }\n    else\n    {\n        _896 = _890;\n    }\n    bool _902;\n    if (_896)\n    {\n        _902 = _889 <= 1.0;\n    }\n    else\n    {\n        _902 = _896;\n    }\n    bool _908;\n    if (_902)\n    {\n        _908 = _878.y <= 1.0;\n    }\n    else\n    {\n        _908 = _902;\n    }\n    bool _916;\n    if (_908)\n    {\n        _916 = _885.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _916 = _908;\n    }\n    vec3 _917;\n    if (_916)\n    {\n        _917 = (_885.xyz / vec3(_885.w)) * quad_fs_params[100].x;\n    }\n    else\n    {\n        _917 = vec3(0.0);\n    }\n    return _917;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _137 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = atan(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = atan(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _500 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    vec2 c = vec2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    vec2 _532 = c;\n    vec2 _537 = clamp(_532, vec2(0.001953125), vec2(0.998046875));\n    c = _537;\n    return vec3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _853 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _853.xy, 0.0);\n    return cookie_value(param_3) * _853.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _939 = quad_fs_params[0].y > 0.5;\n    if (_939)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _963 = fa_tex_fix(param, param_1);\n        vec3 _967 = (_963 * 2.0) - vec3(1.0);\n        float _974 = cos(params.y);\n        float _976 = sin(params.y);\n        n = normalize(vec3((vec2(_974, _976) * _967.x) + ((vec2(-_976, _974) * ((mode > 5.5) ? (-1.0) : 1.0)) * _967.y), max(_967.z, 0.0500000007450580596923828125)));\n    }\n    bool _1010 = !_939;\n    bool _1016;\n    if (_1010)\n    {\n        _1016 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _1016 = _1010;\n    }\n    vec3 _1019;\n    if (_1016)\n    {\n        _1019 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _1019 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _1019;\n    if (quad_fs_params[100].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _1044;\n    if (_1016)\n    {\n        _1044 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _1044 = _1016;\n    }\n    if (_1044)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1171;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1081;\n        if (!_1016)\n        {\n            _1081 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1081 = _1016;\n        }\n        if (_1081)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1107 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1107) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1127 = vec3(_1107, quad_fs_params[i * 1 + 5].z);\n            l = _1127 / vec3(max(length(_1127), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1107;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1107;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_939)\n        {\n            _1171 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1171 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1171));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1421 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1425 = uv * _1421;\n    float _1431 = _1421.x;\n    float _1433 = _1421.y;\n    float _1435 = clamp(shape_rs.x, 0.0, min(_1431, _1433));\n    vec2 _1446 = (abs(_1425) - _1421) + vec2(_1435);\n    float d = (length(max(_1446, vec2(0.0))) + min(max(_1446.x, _1446.y), 0.0)) - _1435;\n    float ax = params.y;\n    bool _1467 = params.y > 15.0;\n    if (_1467)\n    {\n        ax -= 20.0;\n    }\n    float _1478;\n    if (ax <= (-1.5))\n    {\n        _1478 = (-2.0) - ax;\n    }\n    else\n    {\n        _1478 = 0.0;\n    }\n    if (_1478 > 0.0)\n    {\n        float _1492 = _1478 * 0.5;\n        d = abs(d + _1492) - _1492;\n    }\n    float _1500 = fwidth(d);\n    float _1501 = max(_1500, 9.9999997473787516355514526367188e-05);\n    float _1511 = clamp(0.5 - (d / max(shape_rs.y, _1501)), 0.0, 1.0);\n    float _1516;\n    if (shape_rs.y > _1501)\n    {\n        _1516 = (_1511 * _1511) * (3.0 - (2.0 * _1511));\n    }\n    else\n    {\n        _1516 = _1511;\n    }\n    vec4 c = color;\n    bool _1538 = (_1478 <= 0.0) && (ax > (-0.5));\n    if (_1538)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1553 = cos(ax);\n            float _1555 = sin(ax);\n            g = ((dot(_1425, vec2(_1553, _1555)) / max((abs(_1553) * _1431) + (abs(_1555) * _1433), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1467)\n        {\n            vec4 _1598 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1598;\n            vec3 param = _1598.xyz;\n            float param_1 = xform.y;\n            vec3 _1605 = fa_tex_fix(param, param_1);\n            vec4 _2402 = c;\n            _2402.x = _1605.x;\n            _2402.y = _1605.y;\n            _2402.z = _1605.z;\n            c = _2402;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1617 = scene_rgb(param_2);\n            vec4 _1642 = mix(vec4(color.xyz * color.w, color.w), vec4(_1617 * color2.w, color2.w), vec4(g));\n            float _1644 = _1642.w;\n            vec3 _1647;\n            if (_1644 > 9.9999997473787516355514526367188e-06)\n            {\n                _1647 = _1642.xyz / vec3(_1644);\n            }\n            else\n            {\n                _1647 = color.xyz;\n            }\n            c = vec4(_1647, _1644);\n        }\n    }\n    vec4 _2411 = c;\n    _2411.w = _2411.w * _1516;\n    c = _2411;\n    if (_1538 || (shape_rs.y > 0.0))\n    {\n        float _1688 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1697 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1697 + vec3(_1688 * 0.0039215688593685626983642578125);\n            vec3 _1703 = fa_srgb_to_linear(param_4);\n            vec4 _2414 = c;\n            _2414.x = _1703.x;\n            _2414.y = _1703.y;\n            _2414.z = _1703.z;\n            c = _2414;\n        }\n        else\n        {\n            vec4 _1713 = c;\n            vec3 _1716 = _1713.xyz + vec3(_1688 * 0.0039215688593685626983642578125);\n            vec4 _2421 = _1713;\n            _2421.x = _1716.x;\n            _2421.y = _1716.y;\n            _2421.z = _1716.z;\n            c = _2421;\n        }\n        vec4 _2426 = c;\n        _2426.w = clamp(_2426.w + ((_1688 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2426.w)), 0.0, 1.0);\n        c = _2426;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1208 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1210 = texture(tex_smp, uv - _1208);\n    float _1211 = _1210.w;\n    vec4 _1221 = texture(tex_smp, uv + _1208);\n    float _1222 = _1221.w;\n    vec2 _1230 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1232 = texture(tex_smp, uv - _1230);\n    float _1233 = _1232.w;\n    vec4 _1243 = texture(tex_smp, uv + _1230);\n    float _1244 = _1243.w;\n    float _1259 = _1211 - _1222;\n    float _1262 = _1244 - _1233;\n    float _1272 = cos(params.y);\n    float _1274 = sin(params.y);\n    vec2 _1300 = ((vec2(_1272, _1274) * _1259) + ((vec2(-_1274, _1272) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1262)) / vec2(max(length(vec2(_1259, _1262)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1346 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1349 = length(_1346);\n            att = pow(clamp(1.0 - (_1349 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1346 / vec2(max(_1349, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1346;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1346;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1300, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1211, _1222), min(_1233, _1244))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _737 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _741 = _737.y;\n    return vec2(_737.x, mix(_741, 1.0 - _741, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _777 = base_mode < 0.5;\n    bool _788;\n    if (!_777)\n    {\n        _788 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _788 = _777;\n    }\n    float _789;\n    if (_788)\n    {\n        _789 = shape_half.x;\n    }\n    else\n    {\n        _789 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _789);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[95].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _706 = (uv_1 * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    float _708 = _706.y;\n    _706.y = mix(_708, 1.0 - _708, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_706, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + vec2(fa_material[1].x, fa_material[2].x);\n    s.color = vec4(mix(s.color.xyz, fa_scene_color(param).xyz, vec3(fa_material[0].x)), s.color.w);\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1743 = params.x > 31.5;\n    if (_1743)\n    {\n        mode -= 32.0;\n    }\n    float _1751 = mode;\n    bool _1753 = _1751 > 15.5;\n    if (_1753)\n    {\n        mode -= 16.0;\n    }\n    float _1761 = mode;\n    bool _1763 = _1761 > 7.5;\n    if (_1763)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1753)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1753)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1825 = tex_color(param_5);\n                vec4 _1827 = _1825 * color;\n                vec4 param_6 = _1827;\n                float param_7 = mode;\n                float _1834 = _1827.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1834);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1834;\n                    float param_9 = mode;\n                    vec4 _1850 = frag_color;\n                    vec3 _1852 = _1850.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1852.x;\n                    frag_color.y = _1852.y;\n                    frag_color.z = _1852.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1882 = length(uv);\n                    float _1885 = fwidth(_1882);\n                    float _1886 = max(_1885, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1882) / _1886) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1882) / _1886) + 0.5, 0.0, 1.0) * clamp(((_1882 - params.y) / _1886) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1926 = clamp(1.0 - _1882, 0.0, 1.0);\n                            cov = (_1926 * _1926) * (3.0 - (2.0 * _1926));\n                        }\n                    }\n                    vec3 _1935;\n                    if (_1753)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1935 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1935 = color.xyz;\n                    }\n                    frag_color = vec4(_1935, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1990 = fa_tex_fix(param_12, param_13);\n            e *= _1990;\n        }\n        vec4 _1994 = frag_color;\n        vec3 _1996 = _1994.xyz + e;\n        frag_color.x = _1996.x;\n        frag_color.y = _1996.y;\n        frag_color.z = _1996.z;\n    }\n    float param_14 = mode;\n    vec4 _2322 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2322);\n    fragment(param_15, param_16);\n    _2322 = param_16.color;\n    frag_color = param_16.color;\n    if (_1743)\n    {\n        vec4 _2022 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _2027 = scene_rgb(param_17);\n        vec3 _2031 = mix(_2022.xyz, _2027, vec3(color2.w));\n        frag_color.x = _2031.x;\n        frag_color.y = _2031.y;\n        frag_color.z = _2031.z;\n    }\n    if (_1763)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2054 = quad_fs_params[53].w > 0.0;\n    bool _2062;\n    if (!_2054)\n    {\n        _2062 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2062 = _2054;\n    }\n    if (_2062)\n    {\n        vec3 _2076 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2083 = dot(_2076, quad_fs_params[55].xyz);\n        bool _2087 = quad_fs_params[55].w > 0.5;\n        float _2088;\n        if (_2087)\n        {\n            _2088 = _2083;\n        }\n        else\n        {\n            _2088 = length(_2076);\n        }\n        float _2100 = _2088 - quad_fs_params[54].x;\n        if (_2100 > 0.0)\n        {\n            float _2109 = quad_fs_params[53].w * _2100;\n            float tau = _2109 * _2109;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2125;\n                if (_2087)\n                {\n                    _2125 = world_xy.y - (quad_fs_params[55].y * _2083);\n                }\n                else\n                {\n                    _2125 = quad_fs_params[56].y;\n                }\n                float _2146 = mix(_2125, world_xy.y, clamp(quad_fs_params[54].x / _2088, 0.0, 1.0));\n                float _2150 = world_xy.y - _2146;\n                float _2155 = _2146 - quad_fs_params[54].z;\n                float _2160 = world_xy.y - quad_fs_params[54].z;\n                bool _2163 = _2155 <= 0.0;\n                bool _2164 = !_2163;\n                bool _2170;\n                if (_2164)\n                {\n                    _2170 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2170 = _2163;\n                }\n                float _2171;\n                if (_2170)\n                {\n                    _2171 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2171 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2155, 80.0));\n                }\n                bool _2198;\n                if (_2164)\n                {\n                    _2198 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2198 = _2163;\n                }\n                float _2199;\n                if (_2198)\n                {\n                    _2199 = quad_fs_params[54].y * _2155;\n                }\n                else\n                {\n                    _2199 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2155, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2224 = _2160 <= 0.0;\n                bool _2231;\n                if (!_2224)\n                {\n                    _2231 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2231 = _2224;\n                }\n                float _2232;\n                if (_2231)\n                {\n                    _2232 = quad_fs_params[54].y * _2160;\n                }\n                else\n                {\n                    _2232 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2160, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2259;\n                if (abs(_2150) < 0.001000000047497451305389404296875)\n                {\n                    _2259 = _2171;\n                }\n                else\n                {\n                    _2259 = (_2232 - _2199) / _2150;\n                }\n                tau += (_2100 * max(_2259, 0.0));\n            }\n            vec4 _2282 = frag_color;\n            vec3 _2290 = mix(_2282.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2290.x;\n            frag_color.y = _2290.y;\n            frag_color.z = _2290.z;\n        }\n    }\n}\n\n",
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
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_806",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 3,
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[3];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _191 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _195 = _191.y;\n    return vec2(_191.x, mix(_195, 1.0 - _195, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _235 = base_mode < 0.5;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _247);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[95].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _152 = (uv_1 * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    float _155 = _152.y;\n    _152.y = mix(_155, 1.0 - _155, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_152, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + vec2(fa_material[1].x, fa_material[2].x);\n    s.color = vec4(mix(s.color.xyz, fa_scene_color(param).xyz, vec3(fa_material[0].x)), s.color.w);\n}\n\nvoid main()\n{\n    vec4 _298 = texture(tex_smp, uv);\n    vec3 param = _298.xyz;\n    float param_1 = xform.y;\n    vec3 _309 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_309, _298.w) * color;\n    float param_2 = 0.0;\n    vec4 _362 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_362);\n    fragment(param_3, param_4);\n    _362 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_265",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 3,
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
