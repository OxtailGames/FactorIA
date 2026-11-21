{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "be09d710d10cdccec43655f10e6af3b043d5ce26db7fbf1ce164733ea9edbe00",
  "slang": "glsl430",
  "params": [
    "cut",
    "cutY"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _827 = (world_xy * quad_fs_params[99].xy) + quad_fs_params[99].zw;\n    vec4 _834 = textureLod(fx_gi_tex_light_smp, _827, 0.0);\n    float _838 = _827.x;\n    bool _839 = _838 >= 0.0;\n    bool _845;\n    if (_839)\n    {\n        _845 = _827.y >= 0.0;\n    }\n    else\n    {\n        _845 = _839;\n    }\n    bool _851;\n    if (_845)\n    {\n        _851 = _838 <= 1.0;\n    }\n    else\n    {\n        _851 = _845;\n    }\n    bool _857;\n    if (_851)\n    {\n        _857 = _827.y <= 1.0;\n    }\n    else\n    {\n        _857 = _851;\n    }\n    bool _865;\n    if (_857)\n    {\n        _865 = _834.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _865 = _857;\n    }\n    vec3 _866;\n    if (_865)\n    {\n        _866 = (_834.xyz / vec3(_834.w)) * quad_fs_params[100].x;\n    }\n    else\n    {\n        _866 = vec3(0.0);\n    }\n    return _866;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _801 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _801.xy, 0.0);\n    return cookie_value(param_3) * _801.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _888 = quad_fs_params[0].y > 0.5;\n    if (_888)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _912 = fa_tex_fix(param, param_1);\n        vec3 _916 = (_912 * 2.0) - vec3(1.0);\n        float _923 = cos(params.y);\n        float _925 = sin(params.y);\n        n = normalize(vec3((vec2(_923, _925) * _916.x) + ((vec2(-_925, _923) * ((mode > 5.5) ? (-1.0) : 1.0)) * _916.y), max(_916.z, 0.0500000007450580596923828125)));\n    }\n    bool _959 = !_888;\n    bool _965;\n    if (_959)\n    {\n        _965 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _965 = _959;\n    }\n    vec3 _968;\n    if (_965)\n    {\n        _968 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _968 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _968;\n    if (quad_fs_params[100].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _993;\n    if (_965)\n    {\n        _993 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _993 = _965;\n    }\n    if (_993)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1120;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1030;\n        if (!_965)\n        {\n            _1030 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1030 = _965;\n        }\n        if (_1030)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1056 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1056) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1076 = vec3(_1056, quad_fs_params[i * 1 + 5].z);\n            l = _1076 / vec3(max(length(_1076), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1056;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1056;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_888)\n        {\n            _1120 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1120 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1120));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1370 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1374 = uv * _1370;\n    float _1380 = _1370.x;\n    float _1382 = _1370.y;\n    float _1384 = clamp(shape_rs.x, 0.0, min(_1380, _1382));\n    vec2 _1395 = (abs(_1374) - _1370) + vec2(_1384);\n    float d = (length(max(_1395, vec2(0.0))) + min(max(_1395.x, _1395.y), 0.0)) - _1384;\n    float ax = params.y;\n    bool _1416 = params.y > 15.0;\n    if (_1416)\n    {\n        ax -= 20.0;\n    }\n    float _1427;\n    if (ax <= (-1.5))\n    {\n        _1427 = (-2.0) - ax;\n    }\n    else\n    {\n        _1427 = 0.0;\n    }\n    if (_1427 > 0.0)\n    {\n        float _1441 = _1427 * 0.5;\n        d = abs(d + _1441) - _1441;\n    }\n    float _1449 = fwidth(d);\n    float _1450 = max(_1449, 9.9999997473787516355514526367188e-05);\n    float _1460 = clamp(0.5 - (d / max(shape_rs.y, _1450)), 0.0, 1.0);\n    float _1465;\n    if (shape_rs.y > _1450)\n    {\n        _1465 = (_1460 * _1460) * (3.0 - (2.0 * _1460));\n    }\n    else\n    {\n        _1465 = _1460;\n    }\n    vec4 c = color;\n    bool _1487 = (_1427 <= 0.0) && (ax > (-0.5));\n    if (_1487)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1502 = cos(ax);\n            float _1504 = sin(ax);\n            g = ((dot(_1374, vec2(_1502, _1504)) / max((abs(_1502) * _1380) + (abs(_1504) * _1382), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1416)\n        {\n            vec4 _1547 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1547;\n            vec3 param = _1547.xyz;\n            float param_1 = xform.y;\n            vec3 _1554 = fa_tex_fix(param, param_1);\n            vec4 _2349 = c;\n            _2349.x = _1554.x;\n            _2349.y = _1554.y;\n            _2349.z = _1554.z;\n            c = _2349;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1566 = scene_rgb(param_2);\n            vec4 _1591 = mix(vec4(color.xyz * color.w, color.w), vec4(_1566 * color2.w, color2.w), vec4(g));\n            float _1593 = _1591.w;\n            vec3 _1596;\n            if (_1593 > 9.9999997473787516355514526367188e-06)\n            {\n                _1596 = _1591.xyz / vec3(_1593);\n            }\n            else\n            {\n                _1596 = color.xyz;\n            }\n            c = vec4(_1596, _1593);\n        }\n    }\n    vec4 _2358 = c;\n    _2358.w = _2358.w * _1465;\n    c = _2358;\n    if (_1487 || (shape_rs.y > 0.0))\n    {\n        float _1637 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1646 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1646 + vec3(_1637 * 0.0039215688593685626983642578125);\n            vec3 _1652 = fa_srgb_to_linear(param_4);\n            vec4 _2361 = c;\n            _2361.x = _1652.x;\n            _2361.y = _1652.y;\n            _2361.z = _1652.z;\n            c = _2361;\n        }\n        else\n        {\n            vec4 _1662 = c;\n            vec3 _1665 = _1662.xyz + vec3(_1637 * 0.0039215688593685626983642578125);\n            vec4 _2368 = _1662;\n            _2368.x = _1665.x;\n            _2368.y = _1665.y;\n            _2368.z = _1665.z;\n            c = _2368;\n        }\n        vec4 _2373 = c;\n        _2373.w = clamp(_2373.w + ((_1637 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2373.w)), 0.0, 1.0);\n        c = _2373;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1157 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1159 = texture(tex_smp, uv - _1157);\n    float _1160 = _1159.w;\n    vec4 _1170 = texture(tex_smp, uv + _1157);\n    float _1171 = _1170.w;\n    vec2 _1179 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1181 = texture(tex_smp, uv - _1179);\n    float _1182 = _1181.w;\n    vec4 _1192 = texture(tex_smp, uv + _1179);\n    float _1193 = _1192.w;\n    float _1208 = _1160 - _1171;\n    float _1211 = _1193 - _1182;\n    float _1221 = cos(params.y);\n    float _1223 = sin(params.y);\n    vec2 _1249 = ((vec2(_1221, _1223) * _1208) + ((vec2(-_1223, _1221) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1211)) / vec2(max(length(vec2(_1208, _1211)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1295 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1298 = length(_1295);\n            att = pow(clamp(1.0 - (_1298 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1295 / vec2(max(_1298, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1295;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1295;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1249, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1160, _1171), min(_1182, _1193))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _694 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _698 = _694.y;\n    return vec2(_694.x, mix(_698, 1.0 - _698, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _736 = base_mode < 0.5;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _748);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _767 = i.screen_uv.x < fa_material[0].x;\n    bool _776;\n    if (!_767)\n    {\n        _776 = i.screen_uv.y < fa_material[1].x;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    if (_776)\n    {\n        discard;\n    }\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1692 = params.x > 31.5;\n    if (_1692)\n    {\n        mode -= 32.0;\n    }\n    float _1700 = mode;\n    bool _1702 = _1700 > 15.5;\n    if (_1702)\n    {\n        mode -= 16.0;\n    }\n    float _1710 = mode;\n    bool _1712 = _1710 > 7.5;\n    if (_1712)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1702)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1702)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1774 = tex_color(param_5);\n                vec4 _1776 = _1774 * color;\n                vec4 param_6 = _1776;\n                float param_7 = mode;\n                float _1783 = _1776.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1783);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1783;\n                    float param_9 = mode;\n                    vec4 _1799 = frag_color;\n                    vec3 _1801 = _1799.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1801.x;\n                    frag_color.y = _1801.y;\n                    frag_color.z = _1801.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1831 = length(uv);\n                    float _1834 = fwidth(_1831);\n                    float _1835 = max(_1834, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1831) / _1835) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1831) / _1835) + 0.5, 0.0, 1.0) * clamp(((_1831 - params.y) / _1835) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1875 = clamp(1.0 - _1831, 0.0, 1.0);\n                            cov = (_1875 * _1875) * (3.0 - (2.0 * _1875));\n                        }\n                    }\n                    vec3 _1884;\n                    if (_1702)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1884 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1884 = color.xyz;\n                    }\n                    frag_color = vec4(_1884, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1939 = fa_tex_fix(param_12, param_13);\n            e *= _1939;\n        }\n        vec4 _1943 = frag_color;\n        vec3 _1945 = _1943.xyz + e;\n        frag_color.x = _1945.x;\n        frag_color.y = _1945.y;\n        frag_color.z = _1945.z;\n    }\n    float param_14 = mode;\n    vec4 _2273 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2273);\n    fragment(param_15, param_16);\n    _2273 = param_16.color;\n    frag_color = param_16.color;\n    if (_1692)\n    {\n        vec4 _1971 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1976 = scene_rgb(param_17);\n        vec3 _1980 = mix(_1971.xyz, _1976, vec3(color2.w));\n        frag_color.x = _1980.x;\n        frag_color.y = _1980.y;\n        frag_color.z = _1980.z;\n    }\n    if (_1712)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2004 = quad_fs_params[53].w > 0.0;\n    bool _2012;\n    if (!_2004)\n    {\n        _2012 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2012 = _2004;\n    }\n    if (_2012)\n    {\n        vec3 _2026 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2033 = dot(_2026, quad_fs_params[55].xyz);\n        bool _2037 = quad_fs_params[55].w > 0.5;\n        float _2038;\n        if (_2037)\n        {\n            _2038 = _2033;\n        }\n        else\n        {\n            _2038 = length(_2026);\n        }\n        float _2050 = _2038 - quad_fs_params[54].x;\n        if (_2050 > 0.0)\n        {\n            float _2059 = quad_fs_params[53].w * _2050;\n            float tau = _2059 * _2059;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2075;\n                if (_2037)\n                {\n                    _2075 = world_xy.y - (quad_fs_params[55].y * _2033);\n                }\n                else\n                {\n                    _2075 = quad_fs_params[56].y;\n                }\n                float _2096 = mix(_2075, world_xy.y, clamp(quad_fs_params[54].x / _2038, 0.0, 1.0));\n                float _2100 = world_xy.y - _2096;\n                float _2105 = _2096 - quad_fs_params[54].z;\n                float _2110 = world_xy.y - quad_fs_params[54].z;\n                bool _2113 = _2105 <= 0.0;\n                bool _2114 = !_2113;\n                bool _2120;\n                if (_2114)\n                {\n                    _2120 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2120 = _2113;\n                }\n                float _2121;\n                if (_2120)\n                {\n                    _2121 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2121 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2105, 80.0));\n                }\n                bool _2148;\n                if (_2114)\n                {\n                    _2148 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2148 = _2113;\n                }\n                float _2149;\n                if (_2148)\n                {\n                    _2149 = quad_fs_params[54].y * _2105;\n                }\n                else\n                {\n                    _2149 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2105, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2174 = _2110 <= 0.0;\n                bool _2181;\n                if (!_2174)\n                {\n                    _2181 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2181 = _2174;\n                }\n                float _2182;\n                if (_2181)\n                {\n                    _2182 = quad_fs_params[54].y * _2110;\n                }\n                else\n                {\n                    _2182 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2110, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2209;\n                if (abs(_2100) < 0.001000000047497451305389404296875)\n                {\n                    _2209 = _2121;\n                }\n                else\n                {\n                    _2209 = (_2182 - _2149) / _2100;\n                }\n                tau += (_2050 * max(_2209, 0.0));\n            }\n            vec4 _2232 = frag_color;\n            vec3 _2240 = mix(_2232.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2240.x;\n            frag_color.y = _2240.y;\n            frag_color.z = _2240.z;\n        }\n    }\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_764",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _138 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _144 = _138.y;\n    return vec2(_138.x, mix(_144, 1.0 - _144, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _200);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _220 = i.screen_uv.x < fa_material[0].x;\n    bool _229;\n    if (!_220)\n    {\n        _229 = i.screen_uv.y < fa_material[1].x;\n    }\n    else\n    {\n        _229 = _220;\n    }\n    if (_229)\n    {\n        discard;\n    }\n}\n\nvoid main()\n{\n    vec4 _245 = texture(tex_smp, uv);\n    vec3 param = _245.xyz;\n    float param_1 = xform.y;\n    vec3 _256 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_256, _245.w) * color;\n    float param_2 = 0.0;\n    vec4 _311 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_311);\n    fragment(param_3, param_4);\n    _311 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_217",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
