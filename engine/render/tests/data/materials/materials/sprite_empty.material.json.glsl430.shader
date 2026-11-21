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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _806 = (world_xy * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    vec4 _813 = textureLod(fx_gi_tex_light_smp, _806, 0.0);\n    float _817 = _806.x;\n    bool _818 = _817 >= 0.0;\n    bool _824;\n    if (_818)\n    {\n        _824 = _806.y >= 0.0;\n    }\n    else\n    {\n        _824 = _818;\n    }\n    bool _830;\n    if (_824)\n    {\n        _830 = _817 <= 1.0;\n    }\n    else\n    {\n        _830 = _824;\n    }\n    bool _836;\n    if (_830)\n    {\n        _836 = _806.y <= 1.0;\n    }\n    else\n    {\n        _836 = _830;\n    }\n    bool _844;\n    if (_836)\n    {\n        _844 = _813.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _844 = _836;\n    }\n    vec3 _845;\n    if (_844)\n    {\n        _845 = (_813.xyz / vec3(_813.w)) * quad_fs_params[96].x;\n    }\n    else\n    {\n        _845 = vec3(0.0);\n    }\n    return _845;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _780 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _780.xy, 0.0);\n    return cookie_value(param_3) * _780.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _867 = quad_fs_params[0].y > 0.5;\n    if (_867)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _891 = fa_tex_fix(param, param_1);\n        vec3 _895 = (_891 * 2.0) - vec3(1.0);\n        float _902 = cos(params.y);\n        float _904 = sin(params.y);\n        n = normalize(vec3((vec2(_902, _904) * _895.x) + ((vec2(-_904, _902) * ((mode > 5.5) ? (-1.0) : 1.0)) * _895.y), max(_895.z, 0.0500000007450580596923828125)));\n    }\n    bool _938 = !_867;\n    bool _944;\n    if (_938)\n    {\n        _944 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _944 = _938;\n    }\n    vec3 _947;\n    if (_944)\n    {\n        _947 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _947 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _947;\n    if (quad_fs_params[96].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _972;\n    if (_944)\n    {\n        _972 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _972 = _944;\n    }\n    if (_972)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1099;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1009;\n        if (!_944)\n        {\n            _1009 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1009 = _944;\n        }\n        if (_1009)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1035 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1035) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1055 = vec3(_1035, quad_fs_params[i * 1 + 5].z);\n            l = _1055 / vec3(max(length(_1055), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1035;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1035;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_867)\n        {\n            _1099 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1099 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1099));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1349 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1353 = uv * _1349;\n    float _1359 = _1349.x;\n    float _1361 = _1349.y;\n    float _1363 = clamp(shape_rs.x, 0.0, min(_1359, _1361));\n    vec2 _1374 = (abs(_1353) - _1349) + vec2(_1363);\n    float d = (length(max(_1374, vec2(0.0))) + min(max(_1374.x, _1374.y), 0.0)) - _1363;\n    float ax = params.y;\n    bool _1395 = params.y > 15.0;\n    if (_1395)\n    {\n        ax -= 20.0;\n    }\n    float _1406;\n    if (ax <= (-1.5))\n    {\n        _1406 = (-2.0) - ax;\n    }\n    else\n    {\n        _1406 = 0.0;\n    }\n    if (_1406 > 0.0)\n    {\n        float _1420 = _1406 * 0.5;\n        d = abs(d + _1420) - _1420;\n    }\n    float _1428 = fwidth(d);\n    float _1429 = max(_1428, 9.9999997473787516355514526367188e-05);\n    float _1439 = clamp(0.5 - (d / max(shape_rs.y, _1429)), 0.0, 1.0);\n    float _1444;\n    if (shape_rs.y > _1429)\n    {\n        _1444 = (_1439 * _1439) * (3.0 - (2.0 * _1439));\n    }\n    else\n    {\n        _1444 = _1439;\n    }\n    vec4 c = color;\n    bool _1466 = (_1406 <= 0.0) && (ax > (-0.5));\n    if (_1466)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1481 = cos(ax);\n            float _1483 = sin(ax);\n            g = ((dot(_1353, vec2(_1481, _1483)) / max((abs(_1481) * _1359) + (abs(_1483) * _1361), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1395)\n        {\n            vec4 _1526 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1526;\n            vec3 param = _1526.xyz;\n            float param_1 = xform.y;\n            vec3 _1533 = fa_tex_fix(param, param_1);\n            vec4 _2327 = c;\n            _2327.x = _1533.x;\n            _2327.y = _1533.y;\n            _2327.z = _1533.z;\n            c = _2327;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1545 = scene_rgb(param_2);\n            vec4 _1570 = mix(vec4(color.xyz * color.w, color.w), vec4(_1545 * color2.w, color2.w), vec4(g));\n            float _1572 = _1570.w;\n            vec3 _1575;\n            if (_1572 > 9.9999997473787516355514526367188e-06)\n            {\n                _1575 = _1570.xyz / vec3(_1572);\n            }\n            else\n            {\n                _1575 = color.xyz;\n            }\n            c = vec4(_1575, _1572);\n        }\n    }\n    vec4 _2336 = c;\n    _2336.w = _2336.w * _1444;\n    c = _2336;\n    if (_1466 || (shape_rs.y > 0.0))\n    {\n        float _1616 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1625 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1625 + vec3(_1616 * 0.0039215688593685626983642578125);\n            vec3 _1631 = fa_srgb_to_linear(param_4);\n            vec4 _2339 = c;\n            _2339.x = _1631.x;\n            _2339.y = _1631.y;\n            _2339.z = _1631.z;\n            c = _2339;\n        }\n        else\n        {\n            vec4 _1641 = c;\n            vec3 _1644 = _1641.xyz + vec3(_1616 * 0.0039215688593685626983642578125);\n            vec4 _2346 = _1641;\n            _2346.x = _1644.x;\n            _2346.y = _1644.y;\n            _2346.z = _1644.z;\n            c = _2346;\n        }\n        vec4 _2351 = c;\n        _2351.w = clamp(_2351.w + ((_1616 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2351.w)), 0.0, 1.0);\n        c = _2351;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1136 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1138 = texture(tex_smp, uv - _1136);\n    float _1139 = _1138.w;\n    vec4 _1149 = texture(tex_smp, uv + _1136);\n    float _1150 = _1149.w;\n    vec2 _1158 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1160 = texture(tex_smp, uv - _1158);\n    float _1161 = _1160.w;\n    vec4 _1171 = texture(tex_smp, uv + _1158);\n    float _1172 = _1171.w;\n    float _1187 = _1139 - _1150;\n    float _1190 = _1172 - _1161;\n    float _1200 = cos(params.y);\n    float _1202 = sin(params.y);\n    vec2 _1228 = ((vec2(_1200, _1202) * _1187) + ((vec2(-_1202, _1200) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1190)) / vec2(max(length(vec2(_1187, _1190)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1274 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1277 = length(_1274);\n            att = pow(clamp(1.0 - (_1277 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1274 / vec2(max(_1277, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1274;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1274;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1228, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1139, _1150), min(_1161, _1172))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _693 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _697 = _693.y;\n    return vec2(_693.x, mix(_697, 1.0 - _697, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _735 = base_mode < 0.5;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _747);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1671 = params.x > 31.5;\n    if (_1671)\n    {\n        mode -= 32.0;\n    }\n    float _1679 = mode;\n    bool _1681 = _1679 > 15.5;\n    if (_1681)\n    {\n        mode -= 16.0;\n    }\n    float _1689 = mode;\n    bool _1691 = _1689 > 7.5;\n    if (_1691)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1681)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1681)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1753 = tex_color(param_5);\n                vec4 _1755 = _1753 * color;\n                vec4 param_6 = _1755;\n                float param_7 = mode;\n                float _1762 = _1755.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1762);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1762;\n                    float param_9 = mode;\n                    vec4 _1778 = frag_color;\n                    vec3 _1780 = _1778.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1780.x;\n                    frag_color.y = _1780.y;\n                    frag_color.z = _1780.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1810 = length(uv);\n                    float _1813 = fwidth(_1810);\n                    float _1814 = max(_1813, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1810) / _1814) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1810) / _1814) + 0.5, 0.0, 1.0) * clamp(((_1810 - params.y) / _1814) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1854 = clamp(1.0 - _1810, 0.0, 1.0);\n                            cov = (_1854 * _1854) * (3.0 - (2.0 * _1854));\n                        }\n                    }\n                    vec3 _1863;\n                    if (_1681)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1863 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1863 = color.xyz;\n                    }\n                    frag_color = vec4(_1863, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1918 = fa_tex_fix(param_12, param_13);\n            e *= _1918;\n        }\n        vec4 _1922 = frag_color;\n        vec3 _1924 = _1922.xyz + e;\n        frag_color.x = _1924.x;\n        frag_color.y = _1924.y;\n        frag_color.z = _1924.z;\n    }\n    float param_14 = mode;\n    vec4 _2251 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2251);\n    fragment(param_15, param_16);\n    _2251 = param_16.color;\n    frag_color = param_16.color;\n    if (_1671)\n    {\n        vec4 _1950 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1955 = scene_rgb(param_17);\n        vec3 _1959 = mix(_1950.xyz, _1955, vec3(color2.w));\n        frag_color.x = _1959.x;\n        frag_color.y = _1959.y;\n        frag_color.z = _1959.z;\n    }\n    if (_1691)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1983 = quad_fs_params[53].w > 0.0;\n    bool _1991;\n    if (!_1983)\n    {\n        _1991 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1991 = _1983;\n    }\n    if (_1991)\n    {\n        vec3 _2005 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2012 = dot(_2005, quad_fs_params[55].xyz);\n        bool _2016 = quad_fs_params[55].w > 0.5;\n        float _2017;\n        if (_2016)\n        {\n            _2017 = _2012;\n        }\n        else\n        {\n            _2017 = length(_2005);\n        }\n        float _2029 = _2017 - quad_fs_params[54].x;\n        if (_2029 > 0.0)\n        {\n            float _2038 = quad_fs_params[53].w * _2029;\n            float tau = _2038 * _2038;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2054;\n                if (_2016)\n                {\n                    _2054 = world_xy.y - (quad_fs_params[55].y * _2012);\n                }\n                else\n                {\n                    _2054 = quad_fs_params[56].y;\n                }\n                float _2075 = mix(_2054, world_xy.y, clamp(quad_fs_params[54].x / _2017, 0.0, 1.0));\n                float _2079 = world_xy.y - _2075;\n                float _2084 = _2075 - quad_fs_params[54].z;\n                float _2089 = world_xy.y - quad_fs_params[54].z;\n                bool _2092 = _2084 <= 0.0;\n                bool _2093 = !_2092;\n                bool _2099;\n                if (_2093)\n                {\n                    _2099 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2099 = _2092;\n                }\n                float _2100;\n                if (_2099)\n                {\n                    _2100 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2100 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2084, 80.0));\n                }\n                bool _2127;\n                if (_2093)\n                {\n                    _2127 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2127 = _2092;\n                }\n                float _2128;\n                if (_2127)\n                {\n                    _2128 = quad_fs_params[54].y * _2084;\n                }\n                else\n                {\n                    _2128 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2084, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2153 = _2089 <= 0.0;\n                bool _2160;\n                if (!_2153)\n                {\n                    _2160 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2160 = _2153;\n                }\n                float _2161;\n                if (_2160)\n                {\n                    _2161 = quad_fs_params[54].y * _2089;\n                }\n                else\n                {\n                    _2161 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2089, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2188;\n                if (abs(_2079) < 0.001000000047497451305389404296875)\n                {\n                    _2188 = _2100;\n                }\n                else\n                {\n                    _2188 = (_2161 - _2128) / _2079;\n                }\n                tau += (_2029 * max(_2188, 0.0));\n            }\n            vec4 _2211 = frag_color;\n            vec3 _2219 = mix(_2211.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2219.x;\n            frag_color.y = _2219.y;\n            frag_color.z = _2219.z;\n        }\n    }\n}\n\n",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid main()\n{\n    vec4 _223 = texture(tex_smp, uv);\n    vec3 param = _223.xyz;\n    float param_1 = xform.y;\n    vec3 _234 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_234, _223.w) * color;\n    float param_2 = 0.0;\n    vec4 _288 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_288);\n    fragment(param_3, param_4);\n    _288 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
