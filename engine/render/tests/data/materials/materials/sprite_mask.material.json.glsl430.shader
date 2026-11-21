{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "glsl430",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _641 = texture(tex_smp, p);\n    vec3 param = _641.xyz;\n    float param_1 = xform.y;\n    vec3 _651 = fa_tex_fix(param, param_1);\n    return vec4(_651, _641.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _131 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = atan(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = atan(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _155) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _494 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    vec2 c = vec2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    vec2 _526 = c;\n    vec2 _531 = clamp(_526, vec2(0.001953125), vec2(0.998046875));\n    c = _531;\n    return vec3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _792 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _792.xy, 0.0);\n    return cookie_value(param_3) * _792.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _814 = quad_fs_params[0].y > 0.5;\n    if (_814)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _838 = fa_tex_fix(param, param_1);\n        vec3 _842 = (_838 * 2.0) - vec3(1.0);\n        float _849 = cos(params.y);\n        float _851 = sin(params.y);\n        n = normalize(vec3((vec2(_849, _851) * _842.x) + ((vec2(-_851, _849) * ((mode > 5.5) ? (-1.0) : 1.0)) * _842.y), max(_842.z, 0.0500000007450580596923828125)));\n    }\n    bool _884 = !_814;\n    bool _890;\n    if (_884)\n    {\n        _890 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _890 = _884;\n    }\n    vec3 _893;\n    if (_890)\n    {\n        _893 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _893 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _893;\n    bool _910;\n    if (_890)\n    {\n        _910 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _910 = _890;\n    }\n    if (_910)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1037;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _947;\n        if (!_890)\n        {\n            _947 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _947 = _890;\n        }\n        if (_947)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _973 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_973) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _993 = vec3(_973, quad_fs_params[i * 1 + 5].z);\n            l = _993 / vec3(max(length(_993), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_973;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_973;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_814)\n        {\n            _1037 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1037 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1037));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1287 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1291 = uv * _1287;\n    float _1297 = _1287.x;\n    float _1299 = _1287.y;\n    float _1301 = clamp(shape_rs.x, 0.0, min(_1297, _1299));\n    vec2 _1312 = (abs(_1291) - _1287) + vec2(_1301);\n    float d = (length(max(_1312, vec2(0.0))) + min(max(_1312.x, _1312.y), 0.0)) - _1301;\n    float ax = params.y;\n    bool _1333 = params.y > 15.0;\n    if (_1333)\n    {\n        ax -= 20.0;\n    }\n    float _1344;\n    if (ax <= (-1.5))\n    {\n        _1344 = (-2.0) - ax;\n    }\n    else\n    {\n        _1344 = 0.0;\n    }\n    if (_1344 > 0.0)\n    {\n        float _1358 = _1344 * 0.5;\n        d = abs(d + _1358) - _1358;\n    }\n    float _1366 = fwidth(d);\n    float _1367 = max(_1366, 9.9999997473787516355514526367188e-05);\n    float _1377 = clamp(0.5 - (d / max(shape_rs.y, _1367)), 0.0, 1.0);\n    float _1382;\n    if (shape_rs.y > _1367)\n    {\n        _1382 = (_1377 * _1377) * (3.0 - (2.0 * _1377));\n    }\n    else\n    {\n        _1382 = _1377;\n    }\n    vec4 c = color;\n    bool _1404 = (_1344 <= 0.0) && (ax > (-0.5));\n    if (_1404)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1419 = cos(ax);\n            float _1421 = sin(ax);\n            g = ((dot(_1291, vec2(_1419, _1421)) / max((abs(_1419) * _1297) + (abs(_1421) * _1299), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1333)\n        {\n            vec4 _1464 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1464;\n            vec3 param = _1464.xyz;\n            float param_1 = xform.y;\n            vec3 _1471 = fa_tex_fix(param, param_1);\n            vec4 _2259 = c;\n            _2259.x = _1471.x;\n            _2259.y = _1471.y;\n            _2259.z = _1471.z;\n            c = _2259;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1483 = scene_rgb(param_2);\n            vec4 _1508 = mix(vec4(color.xyz * color.w, color.w), vec4(_1483 * color2.w, color2.w), vec4(g));\n            float _1510 = _1508.w;\n            vec3 _1513;\n            if (_1510 > 9.9999997473787516355514526367188e-06)\n            {\n                _1513 = _1508.xyz / vec3(_1510);\n            }\n            else\n            {\n                _1513 = color.xyz;\n            }\n            c = vec4(_1513, _1510);\n        }\n    }\n    vec4 _2268 = c;\n    _2268.w = _2268.w * _1382;\n    c = _2268;\n    if (_1404 || (shape_rs.y > 0.0))\n    {\n        float _1554 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1563 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1563 + vec3(_1554 * 0.0039215688593685626983642578125);\n            vec3 _1569 = fa_srgb_to_linear(param_4);\n            vec4 _2271 = c;\n            _2271.x = _1569.x;\n            _2271.y = _1569.y;\n            _2271.z = _1569.z;\n            c = _2271;\n        }\n        else\n        {\n            vec4 _1579 = c;\n            vec3 _1582 = _1579.xyz + vec3(_1554 * 0.0039215688593685626983642578125);\n            vec4 _2278 = _1579;\n            _2278.x = _1582.x;\n            _2278.y = _1582.y;\n            _2278.z = _1582.z;\n            c = _2278;\n        }\n        vec4 _2283 = c;\n        _2283.w = clamp(_2283.w + ((_1554 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2283.w)), 0.0, 1.0);\n        c = _2283;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1074 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1076 = texture(tex_smp, uv - _1074);\n    float _1077 = _1076.w;\n    vec4 _1087 = texture(tex_smp, uv + _1074);\n    float _1088 = _1087.w;\n    vec2 _1096 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1098 = texture(tex_smp, uv - _1096);\n    float _1099 = _1098.w;\n    vec4 _1109 = texture(tex_smp, uv + _1096);\n    float _1110 = _1109.w;\n    float _1125 = _1077 - _1088;\n    float _1128 = _1110 - _1099;\n    float _1138 = cos(params.y);\n    float _1140 = sin(params.y);\n    vec2 _1166 = ((vec2(_1138, _1140) * _1125) + ((vec2(-_1140, _1138) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1128)) / vec2(max(length(vec2(_1125, _1128)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1212 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1215 = length(_1212);\n            att = pow(clamp(1.0 - (_1215 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1212 / vec2(max(_1215, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1212;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1212;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1166, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1077, _1088), min(_1099, _1110))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _690 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _694 = _690.y;\n    return vec2(_690.x, mix(_694, 1.0 - _694, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _732 = base_mode < 0.5;\n    bool _743;\n    if (!_732)\n    {\n        _743 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _743 = _732;\n    }\n    float _744;\n    if (_743)\n    {\n        _744 = shape_half.x;\n    }\n    else\n    {\n        _744 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _744);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _763 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _763.x;\n    s.color.y = _763.y;\n    s.color.z = _763.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1609 = params.x > 31.5;\n    if (_1609)\n    {\n        mode -= 32.0;\n    }\n    float _1617 = mode;\n    bool _1619 = _1617 > 15.5;\n    if (_1619)\n    {\n        mode -= 16.0;\n    }\n    float _1627 = mode;\n    bool _1629 = _1627 > 7.5;\n    if (_1629)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1619)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1619)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1691 = tex_color(param_5);\n                vec4 _1693 = _1691 * color;\n                vec4 param_6 = _1693;\n                float param_7 = mode;\n                float _1700 = _1693.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1700);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1700;\n                    float param_9 = mode;\n                    vec4 _1716 = frag_color;\n                    vec3 _1718 = _1716.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1718.x;\n                    frag_color.y = _1718.y;\n                    frag_color.z = _1718.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1748 = length(uv);\n                    float _1751 = fwidth(_1748);\n                    float _1752 = max(_1751, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1748) / _1752) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1748) / _1752) + 0.5, 0.0, 1.0) * clamp(((_1748 - params.y) / _1752) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1792 = clamp(1.0 - _1748, 0.0, 1.0);\n                            cov = (_1792 * _1792) * (3.0 - (2.0 * _1792));\n                        }\n                    }\n                    vec3 _1801;\n                    if (_1619)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1801 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1801 = color.xyz;\n                    }\n                    frag_color = vec4(_1801, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1856 = fa_tex_fix(param_12, param_13);\n            e *= _1856;\n        }\n        vec4 _1860 = frag_color;\n        vec3 _1862 = _1860.xyz + e;\n        frag_color.x = _1862.x;\n        frag_color.y = _1862.y;\n        frag_color.z = _1862.z;\n    }\n    float param_14 = mode;\n    vec4 _2189 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2189);\n    fragment(param_15, param_16);\n    _2189 = param_16.color;\n    frag_color = param_16.color;\n    if (_1609)\n    {\n        vec4 _1888 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1893 = scene_rgb(param_17);\n        vec3 _1897 = mix(_1888.xyz, _1893, vec3(color2.w));\n        frag_color.x = _1897.x;\n        frag_color.y = _1897.y;\n        frag_color.z = _1897.z;\n    }\n    if (_1629)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1921 = quad_fs_params[53].w > 0.0;\n    bool _1929;\n    if (!_1921)\n    {\n        _1929 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1929 = _1921;\n    }\n    if (_1929)\n    {\n        vec3 _1943 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1950 = dot(_1943, quad_fs_params[55].xyz);\n        bool _1954 = quad_fs_params[55].w > 0.5;\n        float _1955;\n        if (_1954)\n        {\n            _1955 = _1950;\n        }\n        else\n        {\n            _1955 = length(_1943);\n        }\n        float _1967 = _1955 - quad_fs_params[54].x;\n        if (_1967 > 0.0)\n        {\n            float _1976 = quad_fs_params[53].w * _1967;\n            float tau = _1976 * _1976;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1992;\n                if (_1954)\n                {\n                    _1992 = world_xy.y - (quad_fs_params[55].y * _1950);\n                }\n                else\n                {\n                    _1992 = quad_fs_params[56].y;\n                }\n                float _2013 = mix(_1992, world_xy.y, clamp(quad_fs_params[54].x / _1955, 0.0, 1.0));\n                float _2017 = world_xy.y - _2013;\n                float _2022 = _2013 - quad_fs_params[54].z;\n                float _2027 = world_xy.y - quad_fs_params[54].z;\n                bool _2030 = _2022 <= 0.0;\n                bool _2031 = !_2030;\n                bool _2037;\n                if (_2031)\n                {\n                    _2037 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2037 = _2030;\n                }\n                float _2038;\n                if (_2037)\n                {\n                    _2038 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2038 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2022, 80.0));\n                }\n                bool _2065;\n                if (_2031)\n                {\n                    _2065 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2065 = _2030;\n                }\n                float _2066;\n                if (_2065)\n                {\n                    _2066 = quad_fs_params[54].y * _2022;\n                }\n                else\n                {\n                    _2066 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2022, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2091 = _2027 <= 0.0;\n                bool _2098;\n                if (!_2091)\n                {\n                    _2098 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2098 = _2091;\n                }\n                float _2099;\n                if (_2098)\n                {\n                    _2099 = quad_fs_params[54].y * _2027;\n                }\n                else\n                {\n                    _2099 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2027, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2126;\n                if (abs(_2017) < 0.001000000047497451305389404296875)\n                {\n                    _2126 = _2038;\n                }\n                else\n                {\n                    _2126 = (_2099 - _2066) / _2017;\n                }\n                tau += (_1967 * max(_2126, 0.0));\n            }\n            vec4 _2149 = frag_color;\n            vec3 _2157 = mix(_2149.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2157.x;\n            frag_color.y = _2157.y;\n            frag_color.z = _2157.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_684",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _223 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _223.x;\n    s.color.y = _223.y;\n    s.color.z = _223.z;\n}\n\nvoid main()\n{\n    vec4 _238 = texture(tex_smp, uv);\n    vec3 param = _238.xyz;\n    float param_1 = xform.y;\n    vec3 _249 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_249, _238.w) * color;\n    float param_2 = 0.0;\n    vec4 _303 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_303);\n    fragment(param_3, param_4);\n    _303 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    }
  }
}
