{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _631 = fa_linear_to_srgb(param);\n        c = _631;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _639 = fa_srgb_to_linear(param_1);\n            c = _639;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _650 = texture(tex_smp, p);\n    vec3 param = _650.xyz;\n    float param_1 = xform.y;\n    vec3 _660 = fa_tex_fix(param, param_1);\n    return vec4(_660, _650.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _140 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_140.x * 255.0) + 0.5) * 256.0) + floor((_140.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _243 = floor(tt);\n    float _253 = _243 - (1024.0 * floor(_243 * 0.0009765625));\n    float _256 = _253 + 1.0;\n    float i1 = _256;\n    if (_256 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _253;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _243);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _293 = length(d);\n    float result = 1.0;\n    if (_293 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _304 = atan(d.y, d.x);\n        float a = _304;\n        float _307;\n        if (_304 < 0.0)\n        {\n            _307 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _307 = a;\n        }\n        a = _307;\n        float _317 = _307 * 162.9746551513671875;\n        float _326 = min((size * 10.0) / _293, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _352 = floor(_317 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _326));\n            float param = v;\n            float param_1 = _352 - (1024.0 * floor(_352 * 0.0009765625));\n            float _366 = shadow_texel(param, param_1) * radius;\n            if (_366 < _293)\n            {\n                sum += _366;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _398 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _293)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _416 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _422 = 1.0 - (0.800000011920928955078125 * abs(_416));\n                float param_2 = v;\n                float param_3 = _317 + (_416 * _398);\n                float param_4 = _293;\n                float param_5 = radius;\n                acc += (_422 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _422;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _164 = length(d);\n    if (_164 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _178 = atan(d.y, d.x);\n    float a = _178;\n    float _181;\n    if (_178 < 0.0)\n    {\n        _181 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _181 = a;\n    }\n    a = _181;\n    float _193 = _181 * 162.9746551513671875;\n    float _198 = min(floor(_193), 1023.0);\n    float _205 = _198 + 1.0;\n    float i1 = _205;\n    if (_205 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _198;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _164) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _164) + 0.5, 0.0, 1.0), _193 - _198);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _503 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _507 = _503.x + 0.5;\n    vec2 c = vec2(_507, 0.5 - _503.y);\n    bool _515 = _507 >= 0.0;\n    bool _521;\n    if (_515)\n    {\n        _521 = c.x <= 1.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y >= 0.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    bool _533;\n    if (_527)\n    {\n        _533 = c.y <= 1.0;\n    }\n    else\n    {\n        _533 = _527;\n    }\n    vec2 _535 = c;\n    vec2 _540 = clamp(_535, vec2(0.001953125), vec2(0.998046875));\n    c = _540;\n    return vec3(cell.x + (_540.x * cell.w), cell.y + (_540.y * cell.z), float(_533));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _823 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _823.xy, 0.0);\n    return cookie_value(param_3) * _823.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _845 = quad_fs_params[0].y > 0.5;\n    if (_845)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _869 = fa_tex_fix(param, param_1);\n        vec3 _873 = (_869 * 2.0) - vec3(1.0);\n        float _880 = cos(params.y);\n        float _882 = sin(params.y);\n        n = normalize(vec3((vec2(_880, _882) * _873.x) + ((vec2(-_882, _880) * ((mode > 5.5) ? (-1.0) : 1.0)) * _873.y), max(_873.z, 0.0500000007450580596923828125)));\n    }\n    bool _916 = !_845;\n    bool _922;\n    if (_916)\n    {\n        _922 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _922 = _916;\n    }\n    vec3 _925;\n    if (_922)\n    {\n        _925 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _925 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _925;\n    bool _942;\n    if (_922)\n    {\n        _942 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _942 = _922;\n    }\n    if (_942)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1069;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _979;\n        if (!_922)\n        {\n            _979 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _979 = _922;\n        }\n        if (_979)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1005 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1005) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1025 = vec3(_1005, quad_fs_params[i * 1 + 5].z);\n            l = _1025 / vec3(max(length(_1025), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1005;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1005;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_845)\n        {\n            _1069 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1069 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1069));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _676 = fa_srgb_to_linear(param);\n        c = _676;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1319 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1323 = uv * _1319;\n    float _1329 = _1319.x;\n    float _1331 = _1319.y;\n    float _1333 = clamp(shape_rs.x, 0.0, min(_1329, _1331));\n    vec2 _1344 = (abs(_1323) - _1319) + vec2(_1333);\n    float d = (length(max(_1344, vec2(0.0))) + min(max(_1344.x, _1344.y), 0.0)) - _1333;\n    float ax = params.y;\n    bool _1365 = params.y > 15.0;\n    if (_1365)\n    {\n        ax -= 20.0;\n    }\n    float _1376;\n    if (ax <= (-1.5))\n    {\n        _1376 = (-2.0) - ax;\n    }\n    else\n    {\n        _1376 = 0.0;\n    }\n    if (_1376 > 0.0)\n    {\n        float _1390 = _1376 * 0.5;\n        d = abs(d + _1390) - _1390;\n    }\n    float _1398 = fwidth(d);\n    float _1399 = max(_1398, 9.9999997473787516355514526367188e-05);\n    float _1409 = clamp(0.5 - (d / max(shape_rs.y, _1399)), 0.0, 1.0);\n    float _1414;\n    if (shape_rs.y > _1399)\n    {\n        _1414 = (_1409 * _1409) * (3.0 - (2.0 * _1409));\n    }\n    else\n    {\n        _1414 = _1409;\n    }\n    vec4 c = color;\n    bool _1436 = (_1376 <= 0.0) && (ax > (-0.5));\n    if (_1436)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1451 = cos(ax);\n            float _1453 = sin(ax);\n            g = ((dot(_1323, vec2(_1451, _1453)) / max((abs(_1451) * _1329) + (abs(_1453) * _1331), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1365)\n        {\n            vec4 _1496 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1496;\n            vec3 param = _1496.xyz;\n            float param_1 = xform.y;\n            vec3 _1503 = fa_tex_fix(param, param_1);\n            vec4 _2292 = c;\n            _2292.x = _1503.x;\n            _2292.y = _1503.y;\n            _2292.z = _1503.z;\n            c = _2292;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1515 = scene_rgb(param_2);\n            vec4 _1540 = mix(vec4(color.xyz * color.w, color.w), vec4(_1515 * color2.w, color2.w), vec4(g));\n            float _1542 = _1540.w;\n            vec3 _1545;\n            if (_1542 > 9.9999997473787516355514526367188e-06)\n            {\n                _1545 = _1540.xyz / vec3(_1542);\n            }\n            else\n            {\n                _1545 = color.xyz;\n            }\n            c = vec4(_1545, _1542);\n        }\n    }\n    vec4 _2301 = c;\n    _2301.w = _2301.w * _1414;\n    c = _2301;\n    if (_1436 || (shape_rs.y > 0.0))\n    {\n        float _1586 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1595 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1595 + vec3(_1586 * 0.0039215688593685626983642578125);\n            vec3 _1601 = fa_srgb_to_linear(param_4);\n            vec4 _2304 = c;\n            _2304.x = _1601.x;\n            _2304.y = _1601.y;\n            _2304.z = _1601.z;\n            c = _2304;\n        }\n        else\n        {\n            vec4 _1611 = c;\n            vec3 _1614 = _1611.xyz + vec3(_1586 * 0.0039215688593685626983642578125);\n            vec4 _2311 = _1611;\n            _2311.x = _1614.x;\n            _2311.y = _1614.y;\n            _2311.z = _1614.z;\n            c = _2311;\n        }\n        vec4 _2316 = c;\n        _2316.w = clamp(_2316.w + ((_1586 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2316.w)), 0.0, 1.0);\n        c = _2316;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1106 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1108 = texture(tex_smp, uv - _1106);\n    float _1109 = _1108.w;\n    vec4 _1119 = texture(tex_smp, uv + _1106);\n    float _1120 = _1119.w;\n    vec2 _1128 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1130 = texture(tex_smp, uv - _1128);\n    float _1131 = _1130.w;\n    vec4 _1141 = texture(tex_smp, uv + _1128);\n    float _1142 = _1141.w;\n    float _1157 = _1109 - _1120;\n    float _1160 = _1142 - _1131;\n    float _1170 = cos(params.y);\n    float _1172 = sin(params.y);\n    vec2 _1198 = ((vec2(_1170, _1172) * _1157) + ((vec2(-_1172, _1170) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1160)) / vec2(max(length(vec2(_1157, _1160)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1244 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1247 = length(_1244);\n            att = pow(clamp(1.0 - (_1247 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1244 / vec2(max(_1247, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1244;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1244;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1198, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1109, _1120), min(_1131, _1142))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _705 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _709 = _705.y;\n    return vec2(_705.x, mix(_709, 1.0 - _709, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _747 = base_mode < 0.5;\n    bool _758;\n    if (!_747)\n    {\n        _758 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _758 = _747;\n    }\n    float _759;\n    if (_758)\n    {\n        _759 = shape_half.x;\n    }\n    else\n    {\n        _759 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _759);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _682 = scene_rgb(param);\n    return _682;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _787 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _787.x;\n    s.color.y = _787.y;\n    s.color.z = _787.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1641 = params.x > 31.5;\n    if (_1641)\n    {\n        mode -= 32.0;\n    }\n    float _1649 = mode;\n    bool _1651 = _1649 > 15.5;\n    if (_1651)\n    {\n        mode -= 16.0;\n    }\n    float _1659 = mode;\n    bool _1661 = _1659 > 7.5;\n    if (_1661)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1651)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1651)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1723 = tex_color(param_5);\n                vec4 _1725 = _1723 * color;\n                vec4 param_6 = _1725;\n                float param_7 = mode;\n                float _1732 = _1725.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1732);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1732;\n                    float param_9 = mode;\n                    vec4 _1748 = frag_color;\n                    vec3 _1750 = _1748.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1750.x;\n                    frag_color.y = _1750.y;\n                    frag_color.z = _1750.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1780 = length(uv);\n                    float _1783 = fwidth(_1780);\n                    float _1784 = max(_1783, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1780) / _1784) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1780) / _1784) + 0.5, 0.0, 1.0) * clamp(((_1780 - params.y) / _1784) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1824 = clamp(1.0 - _1780, 0.0, 1.0);\n                            cov = (_1824 * _1824) * (3.0 - (2.0 * _1824));\n                        }\n                    }\n                    vec3 _1833;\n                    if (_1651)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1833 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1833 = color.xyz;\n                    }\n                    frag_color = vec4(_1833, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1888 = fa_tex_fix(param_12, param_13);\n            e *= _1888;\n        }\n        vec4 _1892 = frag_color;\n        vec3 _1894 = _1892.xyz + e;\n        frag_color.x = _1894.x;\n        frag_color.y = _1894.y;\n        frag_color.z = _1894.z;\n    }\n    float param_14 = mode;\n    vec4 _2222 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2222);\n    fragment(param_15, param_16);\n    _2222 = param_16.color;\n    frag_color = param_16.color;\n    if (_1641)\n    {\n        vec4 _1920 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1925 = scene_rgb(param_17);\n        vec3 _1929 = mix(_1920.xyz, _1925, vec3(color2.w));\n        frag_color.x = _1929.x;\n        frag_color.y = _1929.y;\n        frag_color.z = _1929.z;\n    }\n    if (_1661)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1953 = quad_fs_params[53].w > 0.0;\n    bool _1961;\n    if (!_1953)\n    {\n        _1961 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1961 = _1953;\n    }\n    if (_1961)\n    {\n        vec3 _1975 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1982 = dot(_1975, quad_fs_params[55].xyz);\n        bool _1986 = quad_fs_params[55].w > 0.5;\n        float _1987;\n        if (_1986)\n        {\n            _1987 = _1982;\n        }\n        else\n        {\n            _1987 = length(_1975);\n        }\n        float _1999 = _1987 - quad_fs_params[54].x;\n        if (_1999 > 0.0)\n        {\n            float _2008 = quad_fs_params[53].w * _1999;\n            float tau = _2008 * _2008;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2024;\n                if (_1986)\n                {\n                    _2024 = world_xy.y - (quad_fs_params[55].y * _1982);\n                }\n                else\n                {\n                    _2024 = quad_fs_params[56].y;\n                }\n                float _2045 = mix(_2024, world_xy.y, clamp(quad_fs_params[54].x / _1987, 0.0, 1.0));\n                float _2049 = world_xy.y - _2045;\n                float _2054 = _2045 - quad_fs_params[54].z;\n                float _2059 = world_xy.y - quad_fs_params[54].z;\n                bool _2062 = _2054 <= 0.0;\n                bool _2063 = !_2062;\n                bool _2069;\n                if (_2063)\n                {\n                    _2069 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2069 = _2062;\n                }\n                float _2070;\n                if (_2069)\n                {\n                    _2070 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2070 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2054, 80.0));\n                }\n                bool _2097;\n                if (_2063)\n                {\n                    _2097 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2097 = _2062;\n                }\n                float _2098;\n                if (_2097)\n                {\n                    _2098 = quad_fs_params[54].y * _2054;\n                }\n                else\n                {\n                    _2098 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2054, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2123 = _2059 <= 0.0;\n                bool _2130;\n                if (!_2123)\n                {\n                    _2130 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2130 = _2123;\n                }\n                float _2131;\n                if (_2130)\n                {\n                    _2131 = quad_fs_params[54].y * _2059;\n                }\n                else\n                {\n                    _2131 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2059, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2158;\n                if (abs(_2049) < 0.001000000047497451305389404296875)\n                {\n                    _2158 = _2070;\n                }\n                else\n                {\n                    _2158 = (_2131 - _2098) / _2049;\n                }\n                tau += (_1999 * max(_2158, 0.0));\n            }\n            vec4 _2181 = frag_color;\n            vec3 _2189 = mix(_2181.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2189.x;\n            frag_color.y = _2189.y;\n            frag_color.z = _2189.z;\n        }\n    }\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
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
            "inst_name": "_699",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_784",
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[99];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _171 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _176 = _171.y;\n    return vec2(_171.x, mix(_176, 1.0 - _176, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _219 = base_mode < 0.5;\n    bool _230;\n    if (!_219)\n    {\n        _230 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _230 = _219;\n    }\n    float _231;\n    if (_230)\n    {\n        _231 = shape_half.x;\n    }\n    else\n    {\n        _231 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _231);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _259 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _259.x;\n    s.color.y = _259.y;\n    s.color.z = _259.z;\n}\n\nvoid main()\n{\n    vec4 _286 = texture(tex_smp, uv);\n    vec3 param = _286.xyz;\n    float param_1 = xform.y;\n    vec3 _295 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_295, _286.w) * color;\n    float param_2 = 0.0;\n    vec4 _350 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_350);\n    fragment(param_3, param_4);\n    _350 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
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
            "inst_name": "_164",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_256",
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
