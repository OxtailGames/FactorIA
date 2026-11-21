{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _803 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _803.xy, 0.0);\n    return cookie_value(param_3) * _803.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _825 = quad_fs_params[0].y > 0.5;\n    if (_825)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _849 = fa_tex_fix(param, param_1);\n        vec3 _853 = (_849 * 2.0) - vec3(1.0);\n        float _860 = cos(params.y);\n        float _862 = sin(params.y);\n        n = normalize(vec3((vec2(_860, _862) * _853.x) + ((vec2(-_862, _860) * ((mode > 5.5) ? (-1.0) : 1.0)) * _853.y), max(_853.z, 0.0500000007450580596923828125)));\n    }\n    bool _896 = !_825;\n    bool _902;\n    if (_896)\n    {\n        _902 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _902 = _896;\n    }\n    vec3 _905;\n    if (_902)\n    {\n        _905 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _905 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _905;\n    bool _922;\n    if (_902)\n    {\n        _922 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _922 = _902;\n    }\n    if (_922)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1049;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _959;\n        if (!_902)\n        {\n            _959 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _959 = _902;\n        }\n        if (_959)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _985 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_985) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1005 = vec3(_985, quad_fs_params[i * 1 + 5].z);\n            l = _1005 / vec3(max(length(_1005), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_985;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_985;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_825)\n        {\n            _1049 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1049 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1049));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1299 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1303 = uv * _1299;\n    float _1309 = _1299.x;\n    float _1311 = _1299.y;\n    float _1313 = clamp(shape_rs.x, 0.0, min(_1309, _1311));\n    vec2 _1324 = (abs(_1303) - _1299) + vec2(_1313);\n    float d = (length(max(_1324, vec2(0.0))) + min(max(_1324.x, _1324.y), 0.0)) - _1313;\n    float ax = params.y;\n    bool _1345 = params.y > 15.0;\n    if (_1345)\n    {\n        ax -= 20.0;\n    }\n    float _1356;\n    if (ax <= (-1.5))\n    {\n        _1356 = (-2.0) - ax;\n    }\n    else\n    {\n        _1356 = 0.0;\n    }\n    if (_1356 > 0.0)\n    {\n        float _1370 = _1356 * 0.5;\n        d = abs(d + _1370) - _1370;\n    }\n    float _1378 = fwidth(d);\n    float _1379 = max(_1378, 9.9999997473787516355514526367188e-05);\n    float _1389 = clamp(0.5 - (d / max(shape_rs.y, _1379)), 0.0, 1.0);\n    float _1394;\n    if (shape_rs.y > _1379)\n    {\n        _1394 = (_1389 * _1389) * (3.0 - (2.0 * _1389));\n    }\n    else\n    {\n        _1394 = _1389;\n    }\n    vec4 c = color;\n    bool _1416 = (_1356 <= 0.0) && (ax > (-0.5));\n    if (_1416)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1431 = cos(ax);\n            float _1433 = sin(ax);\n            g = ((dot(_1303, vec2(_1431, _1433)) / max((abs(_1431) * _1309) + (abs(_1433) * _1311), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1345)\n        {\n            vec4 _1476 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1476;\n            vec3 param = _1476.xyz;\n            float param_1 = xform.y;\n            vec3 _1483 = fa_tex_fix(param, param_1);\n            vec4 _2271 = c;\n            _2271.x = _1483.x;\n            _2271.y = _1483.y;\n            _2271.z = _1483.z;\n            c = _2271;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1495 = scene_rgb(param_2);\n            vec4 _1520 = mix(vec4(color.xyz * color.w, color.w), vec4(_1495 * color2.w, color2.w), vec4(g));\n            float _1522 = _1520.w;\n            vec3 _1525;\n            if (_1522 > 9.9999997473787516355514526367188e-06)\n            {\n                _1525 = _1520.xyz / vec3(_1522);\n            }\n            else\n            {\n                _1525 = color.xyz;\n            }\n            c = vec4(_1525, _1522);\n        }\n    }\n    vec4 _2280 = c;\n    _2280.w = _2280.w * _1394;\n    c = _2280;\n    if (_1416 || (shape_rs.y > 0.0))\n    {\n        float _1566 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1575 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1575 + vec3(_1566 * 0.0039215688593685626983642578125);\n            vec3 _1581 = fa_srgb_to_linear(param_4);\n            vec4 _2283 = c;\n            _2283.x = _1581.x;\n            _2283.y = _1581.y;\n            _2283.z = _1581.z;\n            c = _2283;\n        }\n        else\n        {\n            vec4 _1591 = c;\n            vec3 _1594 = _1591.xyz + vec3(_1566 * 0.0039215688593685626983642578125);\n            vec4 _2290 = _1591;\n            _2290.x = _1594.x;\n            _2290.y = _1594.y;\n            _2290.z = _1594.z;\n            c = _2290;\n        }\n        vec4 _2295 = c;\n        _2295.w = clamp(_2295.w + ((_1566 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2295.w)), 0.0, 1.0);\n        c = _2295;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1086 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1088 = texture(tex_smp, uv - _1086);\n    float _1089 = _1088.w;\n    vec4 _1099 = texture(tex_smp, uv + _1086);\n    float _1100 = _1099.w;\n    vec2 _1108 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1110 = texture(tex_smp, uv - _1108);\n    float _1111 = _1110.w;\n    vec4 _1121 = texture(tex_smp, uv + _1108);\n    float _1122 = _1121.w;\n    float _1137 = _1089 - _1100;\n    float _1140 = _1122 - _1111;\n    float _1150 = cos(params.y);\n    float _1152 = sin(params.y);\n    vec2 _1178 = ((vec2(_1150, _1152) * _1137) + ((vec2(-_1152, _1150) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1140)) / vec2(max(length(vec2(_1137, _1140)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1224 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1227 = length(_1224);\n            att = pow(clamp(1.0 - (_1227 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1224 / vec2(max(_1227, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1224;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1224;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1178, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1089, _1100), min(_1111, _1122))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _698 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _702 = _698.y;\n    return vec2(_698.x, mix(_702, 1.0 - _702, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _740 = base_mode < 0.5;\n    bool _751;\n    if (!_740)\n    {\n        _751 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _751 = _740;\n    }\n    float _752;\n    if (_751)\n    {\n        _752 = shape_half.x;\n    }\n    else\n    {\n        _752 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _752);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _676 = scene_rgb(param);\n    return _676;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _773 = s.color;\n    vec3 _775 = _773.xyz * fa_scene_rgb(param);\n    s.color.x = _775.x;\n    s.color.y = _775.y;\n    s.color.z = _775.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1621 = params.x > 31.5;\n    if (_1621)\n    {\n        mode -= 32.0;\n    }\n    float _1629 = mode;\n    bool _1631 = _1629 > 15.5;\n    if (_1631)\n    {\n        mode -= 16.0;\n    }\n    float _1639 = mode;\n    bool _1641 = _1639 > 7.5;\n    if (_1641)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1631)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1631)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1703 = tex_color(param_5);\n                vec4 _1705 = _1703 * color;\n                vec4 param_6 = _1705;\n                float param_7 = mode;\n                float _1712 = _1705.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1712);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1712;\n                    float param_9 = mode;\n                    vec4 _1728 = frag_color;\n                    vec3 _1730 = _1728.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1730.x;\n                    frag_color.y = _1730.y;\n                    frag_color.z = _1730.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1760 = length(uv);\n                    float _1763 = fwidth(_1760);\n                    float _1764 = max(_1763, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1760) / _1764) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1760) / _1764) + 0.5, 0.0, 1.0) * clamp(((_1760 - params.y) / _1764) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1804 = clamp(1.0 - _1760, 0.0, 1.0);\n                            cov = (_1804 * _1804) * (3.0 - (2.0 * _1804));\n                        }\n                    }\n                    vec3 _1813;\n                    if (_1631)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1813 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1813 = color.xyz;\n                    }\n                    frag_color = vec4(_1813, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1868 = fa_tex_fix(param_12, param_13);\n            e *= _1868;\n        }\n        vec4 _1872 = frag_color;\n        vec3 _1874 = _1872.xyz + e;\n        frag_color.x = _1874.x;\n        frag_color.y = _1874.y;\n        frag_color.z = _1874.z;\n    }\n    float param_14 = mode;\n    vec4 _2201 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2201);\n    fragment(param_15, param_16);\n    _2201 = param_16.color;\n    frag_color = param_16.color;\n    if (_1621)\n    {\n        vec4 _1900 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1905 = scene_rgb(param_17);\n        vec3 _1909 = mix(_1900.xyz, _1905, vec3(color2.w));\n        frag_color.x = _1909.x;\n        frag_color.y = _1909.y;\n        frag_color.z = _1909.z;\n    }\n    if (_1641)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1933 = quad_fs_params[53].w > 0.0;\n    bool _1941;\n    if (!_1933)\n    {\n        _1941 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1941 = _1933;\n    }\n    if (_1941)\n    {\n        vec3 _1955 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1962 = dot(_1955, quad_fs_params[55].xyz);\n        bool _1966 = quad_fs_params[55].w > 0.5;\n        float _1967;\n        if (_1966)\n        {\n            _1967 = _1962;\n        }\n        else\n        {\n            _1967 = length(_1955);\n        }\n        float _1979 = _1967 - quad_fs_params[54].x;\n        if (_1979 > 0.0)\n        {\n            float _1988 = quad_fs_params[53].w * _1979;\n            float tau = _1988 * _1988;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2004;\n                if (_1966)\n                {\n                    _2004 = world_xy.y - (quad_fs_params[55].y * _1962);\n                }\n                else\n                {\n                    _2004 = quad_fs_params[56].y;\n                }\n                float _2025 = mix(_2004, world_xy.y, clamp(quad_fs_params[54].x / _1967, 0.0, 1.0));\n                float _2029 = world_xy.y - _2025;\n                float _2034 = _2025 - quad_fs_params[54].z;\n                float _2039 = world_xy.y - quad_fs_params[54].z;\n                bool _2042 = _2034 <= 0.0;\n                bool _2043 = !_2042;\n                bool _2049;\n                if (_2043)\n                {\n                    _2049 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2049 = _2042;\n                }\n                float _2050;\n                if (_2049)\n                {\n                    _2050 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2050 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2034, 80.0));\n                }\n                bool _2077;\n                if (_2043)\n                {\n                    _2077 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2077 = _2042;\n                }\n                float _2078;\n                if (_2077)\n                {\n                    _2078 = quad_fs_params[54].y * _2034;\n                }\n                else\n                {\n                    _2078 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2034, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2103 = _2039 <= 0.0;\n                bool _2110;\n                if (!_2103)\n                {\n                    _2110 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2110 = _2103;\n                }\n                float _2111;\n                if (_2110)\n                {\n                    _2111 = quad_fs_params[54].y * _2039;\n                }\n                else\n                {\n                    _2111 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2039, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2138;\n                if (abs(_2029) < 0.001000000047497451305389404296875)\n                {\n                    _2138 = _2050;\n                }\n                else\n                {\n                    _2138 = (_2111 - _2078) / _2029;\n                }\n                tau += (_1979 * max(_2138, 0.0));\n            }\n            vec4 _2161 = frag_color;\n            vec3 _2169 = mix(_2161.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2169.x;\n            frag_color.y = _2169.y;\n            frag_color.z = _2169.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_692",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
            "inst_name": "_766",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _162 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _167 = _162.y;\n    return vec2(_162.x, mix(_167, 1.0 - _167, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _223);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _244 = s.color;\n    vec3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid main()\n{\n    vec4 _265 = texture(tex_smp, uv);\n    vec3 param = _265.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_274, _265.w) * color;\n    float param_2 = 0.0;\n    vec4 _328 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_328);\n    fragment(param_3, param_4);\n    _328 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_155",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
