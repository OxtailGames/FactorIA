{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _641 = texture(tex_smp, p);\n    vec3 param = _641.xyz;\n    float param_1 = xform.y;\n    vec3 _651 = fa_tex_fix(param, param_1);\n    return vec4(_651, _641.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _131 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = atan(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = atan(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _155) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _494 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    vec2 c = vec2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    vec2 _526 = c;\n    vec2 _531 = clamp(_526, vec2(0.001953125), vec2(0.998046875));\n    c = _531;\n    return vec3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _789 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _789.xy, 0.0);\n    return cookie_value(param_3) * _789.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _811 = quad_fs_params[0].y > 0.5;\n    if (_811)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _835 = fa_tex_fix(param, param_1);\n        vec3 _839 = (_835 * 2.0) - vec3(1.0);\n        float _846 = cos(params.y);\n        float _848 = sin(params.y);\n        n = normalize(vec3((vec2(_846, _848) * _839.x) + ((vec2(-_848, _846) * ((mode > 5.5) ? (-1.0) : 1.0)) * _839.y), max(_839.z, 0.0500000007450580596923828125)));\n    }\n    bool _882 = !_811;\n    bool _888;\n    if (_882)\n    {\n        _888 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _888 = _882;\n    }\n    vec3 _891;\n    if (_888)\n    {\n        _891 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _891 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _891;\n    bool _908;\n    if (_888)\n    {\n        _908 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _908 = _888;\n    }\n    if (_908)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1035;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _945;\n        if (!_888)\n        {\n            _945 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _945 = _888;\n        }\n        if (_945)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _971 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_971) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _991 = vec3(_971, quad_fs_params[i * 1 + 5].z);\n            l = _991 / vec3(max(length(_991), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_971;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_971;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_811)\n        {\n            _1035 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1035 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1035));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1285 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1289 = uv * _1285;\n    float _1295 = _1285.x;\n    float _1297 = _1285.y;\n    float _1299 = clamp(shape_rs.x, 0.0, min(_1295, _1297));\n    vec2 _1310 = (abs(_1289) - _1285) + vec2(_1299);\n    float d = (length(max(_1310, vec2(0.0))) + min(max(_1310.x, _1310.y), 0.0)) - _1299;\n    float ax = params.y;\n    bool _1331 = params.y > 15.0;\n    if (_1331)\n    {\n        ax -= 20.0;\n    }\n    float _1342;\n    if (ax <= (-1.5))\n    {\n        _1342 = (-2.0) - ax;\n    }\n    else\n    {\n        _1342 = 0.0;\n    }\n    if (_1342 > 0.0)\n    {\n        float _1356 = _1342 * 0.5;\n        d = abs(d + _1356) - _1356;\n    }\n    float _1364 = fwidth(d);\n    float _1365 = max(_1364, 9.9999997473787516355514526367188e-05);\n    float _1375 = clamp(0.5 - (d / max(shape_rs.y, _1365)), 0.0, 1.0);\n    float _1380;\n    if (shape_rs.y > _1365)\n    {\n        _1380 = (_1375 * _1375) * (3.0 - (2.0 * _1375));\n    }\n    else\n    {\n        _1380 = _1375;\n    }\n    vec4 c = color;\n    bool _1402 = (_1342 <= 0.0) && (ax > (-0.5));\n    if (_1402)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1417 = cos(ax);\n            float _1419 = sin(ax);\n            g = ((dot(_1289, vec2(_1417, _1419)) / max((abs(_1417) * _1295) + (abs(_1419) * _1297), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1331)\n        {\n            vec4 _1462 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1462;\n            vec3 param = _1462.xyz;\n            float param_1 = xform.y;\n            vec3 _1469 = fa_tex_fix(param, param_1);\n            vec4 _2257 = c;\n            _2257.x = _1469.x;\n            _2257.y = _1469.y;\n            _2257.z = _1469.z;\n            c = _2257;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1481 = scene_rgb(param_2);\n            vec4 _1506 = mix(vec4(color.xyz * color.w, color.w), vec4(_1481 * color2.w, color2.w), vec4(g));\n            float _1508 = _1506.w;\n            vec3 _1511;\n            if (_1508 > 9.9999997473787516355514526367188e-06)\n            {\n                _1511 = _1506.xyz / vec3(_1508);\n            }\n            else\n            {\n                _1511 = color.xyz;\n            }\n            c = vec4(_1511, _1508);\n        }\n    }\n    vec4 _2266 = c;\n    _2266.w = _2266.w * _1380;\n    c = _2266;\n    if (_1402 || (shape_rs.y > 0.0))\n    {\n        float _1552 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1561 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1561 + vec3(_1552 * 0.0039215688593685626983642578125);\n            vec3 _1567 = fa_srgb_to_linear(param_4);\n            vec4 _2269 = c;\n            _2269.x = _1567.x;\n            _2269.y = _1567.y;\n            _2269.z = _1567.z;\n            c = _2269;\n        }\n        else\n        {\n            vec4 _1577 = c;\n            vec3 _1580 = _1577.xyz + vec3(_1552 * 0.0039215688593685626983642578125);\n            vec4 _2276 = _1577;\n            _2276.x = _1580.x;\n            _2276.y = _1580.y;\n            _2276.z = _1580.z;\n            c = _2276;\n        }\n        vec4 _2281 = c;\n        _2281.w = clamp(_2281.w + ((_1552 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2281.w)), 0.0, 1.0);\n        c = _2281;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1072 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1074 = texture(tex_smp, uv - _1072);\n    float _1075 = _1074.w;\n    vec4 _1085 = texture(tex_smp, uv + _1072);\n    float _1086 = _1085.w;\n    vec2 _1094 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1096 = texture(tex_smp, uv - _1094);\n    float _1097 = _1096.w;\n    vec4 _1107 = texture(tex_smp, uv + _1094);\n    float _1108 = _1107.w;\n    float _1123 = _1075 - _1086;\n    float _1126 = _1108 - _1097;\n    float _1136 = cos(params.y);\n    float _1138 = sin(params.y);\n    vec2 _1164 = ((vec2(_1136, _1138) * _1123) + ((vec2(-_1138, _1136) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1126)) / vec2(max(length(vec2(_1123, _1126)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1210 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1213 = length(_1210);\n            att = pow(clamp(1.0 - (_1213 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1210 / vec2(max(_1213, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1210;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1210;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1164, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1075, _1086), min(_1097, _1108))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _690 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _694 = _690.y;\n    return vec2(_690.x, mix(_694, 1.0 - _694, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _732 = base_mode < 0.5;\n    bool _743;\n    if (!_732)\n    {\n        _743 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _743 = _732;\n    }\n    float _744;\n    if (_743)\n    {\n        _744 = shape_half.x;\n    }\n    else\n    {\n        _744 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _744);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1607 = params.x > 31.5;\n    if (_1607)\n    {\n        mode -= 32.0;\n    }\n    float _1615 = mode;\n    bool _1617 = _1615 > 15.5;\n    if (_1617)\n    {\n        mode -= 16.0;\n    }\n    float _1625 = mode;\n    bool _1627 = _1625 > 7.5;\n    if (_1627)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1617)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1617)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1689 = tex_color(param_5);\n                vec4 _1691 = _1689 * color;\n                vec4 param_6 = _1691;\n                float param_7 = mode;\n                float _1698 = _1691.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1698);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1698;\n                    float param_9 = mode;\n                    vec4 _1714 = frag_color;\n                    vec3 _1716 = _1714.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1716.x;\n                    frag_color.y = _1716.y;\n                    frag_color.z = _1716.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1746 = length(uv);\n                    float _1749 = fwidth(_1746);\n                    float _1750 = max(_1749, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1746) / _1750) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1746) / _1750) + 0.5, 0.0, 1.0) * clamp(((_1746 - params.y) / _1750) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1790 = clamp(1.0 - _1746, 0.0, 1.0);\n                            cov = (_1790 * _1790) * (3.0 - (2.0 * _1790));\n                        }\n                    }\n                    vec3 _1799;\n                    if (_1617)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1799 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1799 = color.xyz;\n                    }\n                    frag_color = vec4(_1799, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1854 = fa_tex_fix(param_12, param_13);\n            e *= _1854;\n        }\n        vec4 _1858 = frag_color;\n        vec3 _1860 = _1858.xyz + e;\n        frag_color.x = _1860.x;\n        frag_color.y = _1860.y;\n        frag_color.z = _1860.z;\n    }\n    float param_14 = mode;\n    vec4 _2187 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2187);\n    fragment(param_15, param_16);\n    _2187 = param_16.color;\n    frag_color = param_16.color;\n    if (_1607)\n    {\n        vec4 _1886 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1891 = scene_rgb(param_17);\n        vec3 _1895 = mix(_1886.xyz, _1891, vec3(color2.w));\n        frag_color.x = _1895.x;\n        frag_color.y = _1895.y;\n        frag_color.z = _1895.z;\n    }\n    if (_1627)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1919 = quad_fs_params[53].w > 0.0;\n    bool _1927;\n    if (!_1919)\n    {\n        _1927 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1927 = _1919;\n    }\n    if (_1927)\n    {\n        vec3 _1941 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1948 = dot(_1941, quad_fs_params[55].xyz);\n        bool _1952 = quad_fs_params[55].w > 0.5;\n        float _1953;\n        if (_1952)\n        {\n            _1953 = _1948;\n        }\n        else\n        {\n            _1953 = length(_1941);\n        }\n        float _1965 = _1953 - quad_fs_params[54].x;\n        if (_1965 > 0.0)\n        {\n            float _1974 = quad_fs_params[53].w * _1965;\n            float tau = _1974 * _1974;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1990;\n                if (_1952)\n                {\n                    _1990 = world_xy.y - (quad_fs_params[55].y * _1948);\n                }\n                else\n                {\n                    _1990 = quad_fs_params[56].y;\n                }\n                float _2011 = mix(_1990, world_xy.y, clamp(quad_fs_params[54].x / _1953, 0.0, 1.0));\n                float _2015 = world_xy.y - _2011;\n                float _2020 = _2011 - quad_fs_params[54].z;\n                float _2025 = world_xy.y - quad_fs_params[54].z;\n                bool _2028 = _2020 <= 0.0;\n                bool _2029 = !_2028;\n                bool _2035;\n                if (_2029)\n                {\n                    _2035 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2035 = _2028;\n                }\n                float _2036;\n                if (_2035)\n                {\n                    _2036 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2036 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2020, 80.0));\n                }\n                bool _2063;\n                if (_2029)\n                {\n                    _2063 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2063 = _2028;\n                }\n                float _2064;\n                if (_2063)\n                {\n                    _2064 = quad_fs_params[54].y * _2020;\n                }\n                else\n                {\n                    _2064 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2020, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2089 = _2025 <= 0.0;\n                bool _2096;\n                if (!_2089)\n                {\n                    _2096 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2096 = _2089;\n                }\n                float _2097;\n                if (_2096)\n                {\n                    _2097 = quad_fs_params[54].y * _2025;\n                }\n                else\n                {\n                    _2097 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2025, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2124;\n                if (abs(_2015) < 0.001000000047497451305389404296875)\n                {\n                    _2124 = _2036;\n                }\n                else\n                {\n                    _2124 = (_2097 - _2064) / _2015;\n                }\n                tau += (_1965 * max(_2124, 0.0));\n            }\n            vec4 _2147 = frag_color;\n            vec3 _2155 = mix(_2147.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2155.x;\n            frag_color.y = _2155.y;\n            frag_color.z = _2155.z;\n        }\n    }\n}\n\n",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    vec4 _235 = texture(tex_smp, uv);\n    vec3 param = _235.xyz;\n    float param_1 = xform.y;\n    vec3 _246 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_246, _235.w) * color;\n    float param_2 = 0.0;\n    vec4 _300 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_300);\n    fragment(param_3, param_4);\n    _300 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
