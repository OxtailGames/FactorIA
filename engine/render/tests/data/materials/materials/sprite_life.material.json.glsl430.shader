{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _815 = (world_xy * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    vec4 _822 = textureLod(fx_gi_tex_light_smp, _815, 0.0);\n    float _826 = _815.x;\n    bool _827 = _826 >= 0.0;\n    bool _833;\n    if (_827)\n    {\n        _833 = _815.y >= 0.0;\n    }\n    else\n    {\n        _833 = _827;\n    }\n    bool _839;\n    if (_833)\n    {\n        _839 = _826 <= 1.0;\n    }\n    else\n    {\n        _839 = _833;\n    }\n    bool _845;\n    if (_839)\n    {\n        _845 = _815.y <= 1.0;\n    }\n    else\n    {\n        _845 = _839;\n    }\n    bool _853;\n    if (_845)\n    {\n        _853 = _822.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _853 = _845;\n    }\n    vec3 _854;\n    if (_853)\n    {\n        _854 = (_822.xyz / vec3(_822.w)) * quad_fs_params[96].x;\n    }\n    else\n    {\n        _854 = vec3(0.0);\n    }\n    return _854;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _789 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _789.xy, 0.0);\n    return cookie_value(param_3) * _789.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _876 = quad_fs_params[0].y > 0.5;\n    if (_876)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _900 = fa_tex_fix(param, param_1);\n        vec3 _904 = (_900 * 2.0) - vec3(1.0);\n        float _911 = cos(params.y);\n        float _913 = sin(params.y);\n        n = normalize(vec3((vec2(_911, _913) * _904.x) + ((vec2(-_913, _911) * ((mode > 5.5) ? (-1.0) : 1.0)) * _904.y), max(_904.z, 0.0500000007450580596923828125)));\n    }\n    bool _947 = !_876;\n    bool _953;\n    if (_947)\n    {\n        _953 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _953 = _947;\n    }\n    vec3 _956;\n    if (_953)\n    {\n        _956 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _956 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _956;\n    if (quad_fs_params[96].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _981;\n    if (_953)\n    {\n        _981 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _981 = _953;\n    }\n    if (_981)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1108;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1018;\n        if (!_953)\n        {\n            _1018 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1018 = _953;\n        }\n        if (_1018)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1044 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1044) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1064 = vec3(_1044, quad_fs_params[i * 1 + 5].z);\n            l = _1064 / vec3(max(length(_1064), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1044;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1044;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_876)\n        {\n            _1108 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1108 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1108));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1358 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1362 = uv * _1358;\n    float _1368 = _1358.x;\n    float _1370 = _1358.y;\n    float _1372 = clamp(shape_rs.x, 0.0, min(_1368, _1370));\n    vec2 _1383 = (abs(_1362) - _1358) + vec2(_1372);\n    float d = (length(max(_1383, vec2(0.0))) + min(max(_1383.x, _1383.y), 0.0)) - _1372;\n    float ax = params.y;\n    bool _1404 = params.y > 15.0;\n    if (_1404)\n    {\n        ax -= 20.0;\n    }\n    float _1415;\n    if (ax <= (-1.5))\n    {\n        _1415 = (-2.0) - ax;\n    }\n    else\n    {\n        _1415 = 0.0;\n    }\n    if (_1415 > 0.0)\n    {\n        float _1429 = _1415 * 0.5;\n        d = abs(d + _1429) - _1429;\n    }\n    float _1437 = fwidth(d);\n    float _1438 = max(_1437, 9.9999997473787516355514526367188e-05);\n    float _1448 = clamp(0.5 - (d / max(shape_rs.y, _1438)), 0.0, 1.0);\n    float _1453;\n    if (shape_rs.y > _1438)\n    {\n        _1453 = (_1448 * _1448) * (3.0 - (2.0 * _1448));\n    }\n    else\n    {\n        _1453 = _1448;\n    }\n    vec4 c = color;\n    bool _1475 = (_1415 <= 0.0) && (ax > (-0.5));\n    if (_1475)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1490 = cos(ax);\n            float _1492 = sin(ax);\n            g = ((dot(_1362, vec2(_1490, _1492)) / max((abs(_1490) * _1368) + (abs(_1492) * _1370), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1404)\n        {\n            vec4 _1535 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1535;\n            vec3 param = _1535.xyz;\n            float param_1 = xform.y;\n            vec3 _1542 = fa_tex_fix(param, param_1);\n            vec4 _2336 = c;\n            _2336.x = _1542.x;\n            _2336.y = _1542.y;\n            _2336.z = _1542.z;\n            c = _2336;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1554 = scene_rgb(param_2);\n            vec4 _1579 = mix(vec4(color.xyz * color.w, color.w), vec4(_1554 * color2.w, color2.w), vec4(g));\n            float _1581 = _1579.w;\n            vec3 _1584;\n            if (_1581 > 9.9999997473787516355514526367188e-06)\n            {\n                _1584 = _1579.xyz / vec3(_1581);\n            }\n            else\n            {\n                _1584 = color.xyz;\n            }\n            c = vec4(_1584, _1581);\n        }\n    }\n    vec4 _2345 = c;\n    _2345.w = _2345.w * _1453;\n    c = _2345;\n    if (_1475 || (shape_rs.y > 0.0))\n    {\n        float _1625 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1634 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1634 + vec3(_1625 * 0.0039215688593685626983642578125);\n            vec3 _1640 = fa_srgb_to_linear(param_4);\n            vec4 _2348 = c;\n            _2348.x = _1640.x;\n            _2348.y = _1640.y;\n            _2348.z = _1640.z;\n            c = _2348;\n        }\n        else\n        {\n            vec4 _1650 = c;\n            vec3 _1653 = _1650.xyz + vec3(_1625 * 0.0039215688593685626983642578125);\n            vec4 _2355 = _1650;\n            _2355.x = _1653.x;\n            _2355.y = _1653.y;\n            _2355.z = _1653.z;\n            c = _2355;\n        }\n        vec4 _2360 = c;\n        _2360.w = clamp(_2360.w + ((_1625 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2360.w)), 0.0, 1.0);\n        c = _2360;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1145 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1147 = texture(tex_smp, uv - _1145);\n    float _1148 = _1147.w;\n    vec4 _1158 = texture(tex_smp, uv + _1145);\n    float _1159 = _1158.w;\n    vec2 _1167 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1169 = texture(tex_smp, uv - _1167);\n    float _1170 = _1169.w;\n    vec4 _1180 = texture(tex_smp, uv + _1167);\n    float _1181 = _1180.w;\n    float _1196 = _1148 - _1159;\n    float _1199 = _1181 - _1170;\n    float _1209 = cos(params.y);\n    float _1211 = sin(params.y);\n    vec2 _1237 = ((vec2(_1209, _1211) * _1196) + ((vec2(-_1211, _1209) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1199)) / vec2(max(length(vec2(_1196, _1199)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1283 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1286 = length(_1283);\n            att = pow(clamp(1.0 - (_1286 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1283 / vec2(max(_1286, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1283;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1283;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1237, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1148, _1159), min(_1170, _1181))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _693 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _697 = _693.y;\n    return vec2(_693.x, mix(_697, 1.0 - _697, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _735 = base_mode < 0.5;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _747);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1680 = params.x > 31.5;\n    if (_1680)\n    {\n        mode -= 32.0;\n    }\n    float _1688 = mode;\n    bool _1690 = _1688 > 15.5;\n    if (_1690)\n    {\n        mode -= 16.0;\n    }\n    float _1698 = mode;\n    bool _1700 = _1698 > 7.5;\n    if (_1700)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1690)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1690)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1762 = tex_color(param_5);\n                vec4 _1764 = _1762 * color;\n                vec4 param_6 = _1764;\n                float param_7 = mode;\n                float _1771 = _1764.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1771);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1771;\n                    float param_9 = mode;\n                    vec4 _1787 = frag_color;\n                    vec3 _1789 = _1787.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1789.x;\n                    frag_color.y = _1789.y;\n                    frag_color.z = _1789.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1819 = length(uv);\n                    float _1822 = fwidth(_1819);\n                    float _1823 = max(_1822, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1819) / _1823) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1819) / _1823) + 0.5, 0.0, 1.0) * clamp(((_1819 - params.y) / _1823) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1863 = clamp(1.0 - _1819, 0.0, 1.0);\n                            cov = (_1863 * _1863) * (3.0 - (2.0 * _1863));\n                        }\n                    }\n                    vec3 _1872;\n                    if (_1690)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1872 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1872 = color.xyz;\n                    }\n                    frag_color = vec4(_1872, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1927 = fa_tex_fix(param_12, param_13);\n            e *= _1927;\n        }\n        vec4 _1931 = frag_color;\n        vec3 _1933 = _1931.xyz + e;\n        frag_color.x = _1933.x;\n        frag_color.y = _1933.y;\n        frag_color.z = _1933.z;\n    }\n    float param_14 = mode;\n    vec4 _2260 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2260);\n    fragment(param_15, param_16);\n    _2260 = param_16.color;\n    frag_color = param_16.color;\n    if (_1680)\n    {\n        vec4 _1959 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1964 = scene_rgb(param_17);\n        vec3 _1968 = mix(_1959.xyz, _1964, vec3(color2.w));\n        frag_color.x = _1968.x;\n        frag_color.y = _1968.y;\n        frag_color.z = _1968.z;\n    }\n    if (_1700)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1992 = quad_fs_params[53].w > 0.0;\n    bool _2000;\n    if (!_1992)\n    {\n        _2000 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2000 = _1992;\n    }\n    if (_2000)\n    {\n        vec3 _2014 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2021 = dot(_2014, quad_fs_params[55].xyz);\n        bool _2025 = quad_fs_params[55].w > 0.5;\n        float _2026;\n        if (_2025)\n        {\n            _2026 = _2021;\n        }\n        else\n        {\n            _2026 = length(_2014);\n        }\n        float _2038 = _2026 - quad_fs_params[54].x;\n        if (_2038 > 0.0)\n        {\n            float _2047 = quad_fs_params[53].w * _2038;\n            float tau = _2047 * _2047;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2063;\n                if (_2025)\n                {\n                    _2063 = world_xy.y - (quad_fs_params[55].y * _2021);\n                }\n                else\n                {\n                    _2063 = quad_fs_params[56].y;\n                }\n                float _2084 = mix(_2063, world_xy.y, clamp(quad_fs_params[54].x / _2026, 0.0, 1.0));\n                float _2088 = world_xy.y - _2084;\n                float _2093 = _2084 - quad_fs_params[54].z;\n                float _2098 = world_xy.y - quad_fs_params[54].z;\n                bool _2101 = _2093 <= 0.0;\n                bool _2102 = !_2101;\n                bool _2108;\n                if (_2102)\n                {\n                    _2108 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2108 = _2101;\n                }\n                float _2109;\n                if (_2108)\n                {\n                    _2109 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2109 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2093, 80.0));\n                }\n                bool _2136;\n                if (_2102)\n                {\n                    _2136 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2136 = _2101;\n                }\n                float _2137;\n                if (_2136)\n                {\n                    _2137 = quad_fs_params[54].y * _2093;\n                }\n                else\n                {\n                    _2137 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2093, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2162 = _2098 <= 0.0;\n                bool _2169;\n                if (!_2162)\n                {\n                    _2169 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2169 = _2162;\n                }\n                float _2170;\n                if (_2169)\n                {\n                    _2170 = quad_fs_params[54].y * _2098;\n                }\n                else\n                {\n                    _2170 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2098, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2197;\n                if (abs(_2088) < 0.001000000047497451305389404296875)\n                {\n                    _2197 = _2109;\n                }\n                else\n                {\n                    _2197 = (_2170 - _2137) / _2088;\n                }\n                tau += (_2038 * max(_2197, 0.0));\n            }\n            vec4 _2220 = frag_color;\n            vec3 _2228 = mix(_2220.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2228.x;\n            frag_color.y = _2228.y;\n            frag_color.z = _2228.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_687",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 97,
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    vec4 _232 = texture(tex_smp, uv);\n    vec3 param = _232.xyz;\n    float param_1 = xform.y;\n    vec3 _243 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_243, _232.w) * color;\n    float param_2 = 0.0;\n    vec4 _297 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_297);\n    fragment(param_3, param_4);\n    _297 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 97,
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
