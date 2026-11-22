{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _68 = v.world_pos;\n    vec2 _76 = fa_vs_points.data[gl_InstanceID].pos.xy + (_68.xy * fa_vs_points.data[gl_InstanceID].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _178 = position;\n    vec2 _179 = texcoord0;\n    vec4 _180 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _117 = fa_srgb_to_linear(param);\n        vec4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex(_178, _179, _180);\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[101];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _644 = texture(tex_smp, p);\n    vec3 param = _644.xyz;\n    float param_1 = xform.y;\n    vec3 _654 = fa_tex_fix(param, param_1);\n    return vec4(_654, _644.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _824 = (world_xy * quad_fs_params[99].xy) + quad_fs_params[99].zw;\n    vec4 _831 = textureLod(fx_gi_tex_light_smp, _824, 0.0);\n    float _835 = _824.x;\n    bool _836 = _835 >= 0.0;\n    bool _842;\n    if (_836)\n    {\n        _842 = _824.y >= 0.0;\n    }\n    else\n    {\n        _842 = _836;\n    }\n    bool _848;\n    if (_842)\n    {\n        _848 = _835 <= 1.0;\n    }\n    else\n    {\n        _848 = _842;\n    }\n    bool _854;\n    if (_848)\n    {\n        _854 = _824.y <= 1.0;\n    }\n    else\n    {\n        _854 = _848;\n    }\n    bool _862;\n    if (_854)\n    {\n        _862 = _831.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _862 = _854;\n    }\n    vec3 _863;\n    if (_862)\n    {\n        _863 = (_831.xyz / vec3(_831.w)) * quad_fs_params[100].x;\n    }\n    else\n    {\n        _863 = vec3(0.0);\n    }\n    return _863;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _134 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = atan(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = atan(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _497 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    vec2 c = vec2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    vec2 _529 = c;\n    vec2 _534 = clamp(_529, vec2(0.001953125), vec2(0.998046875));\n    c = _534;\n    return vec3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _798 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _798.xy, 0.0);\n    return cookie_value(param_3) * _798.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _885 = quad_fs_params[0].y > 0.5;\n    if (_885)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _909 = fa_tex_fix(param, param_1);\n        vec3 _913 = (_909 * 2.0) - vec3(1.0);\n        float _920 = cos(params.y);\n        float _922 = sin(params.y);\n        n = normalize(vec3((vec2(_920, _922) * _913.x) + ((vec2(-_922, _920) * ((mode > 5.5) ? (-1.0) : 1.0)) * _913.y), max(_913.z, 0.0500000007450580596923828125)));\n    }\n    bool _956 = !_885;\n    bool _962;\n    if (_956)\n    {\n        _962 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _962 = _956;\n    }\n    vec3 _965;\n    if (_962)\n    {\n        _965 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _965 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _965;\n    if (quad_fs_params[100].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _990;\n    if (_962)\n    {\n        _990 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _990 = _962;\n    }\n    if (_990)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1117;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1027;\n        if (!_962)\n        {\n            _1027 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1027 = _962;\n        }\n        if (_1027)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1053 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1053) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1073 = vec3(_1053, quad_fs_params[i * 1 + 5].z);\n            l = _1073 / vec3(max(length(_1073), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1053;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1053;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_885)\n        {\n            _1117 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1117 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1117));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1367 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1371 = uv * _1367;\n    float _1377 = _1367.x;\n    float _1379 = _1367.y;\n    float _1381 = clamp(shape_rs.x, 0.0, min(_1377, _1379));\n    vec2 _1392 = (abs(_1371) - _1367) + vec2(_1381);\n    float d = (length(max(_1392, vec2(0.0))) + min(max(_1392.x, _1392.y), 0.0)) - _1381;\n    float ax = params.y;\n    bool _1413 = params.y > 15.0;\n    if (_1413)\n    {\n        ax -= 20.0;\n    }\n    float _1424;\n    if (ax <= (-1.5))\n    {\n        _1424 = (-2.0) - ax;\n    }\n    else\n    {\n        _1424 = 0.0;\n    }\n    if (_1424 > 0.0)\n    {\n        float _1438 = _1424 * 0.5;\n        d = abs(d + _1438) - _1438;\n    }\n    float _1446 = fwidth(d);\n    float _1447 = max(_1446, 9.9999997473787516355514526367188e-05);\n    float _1457 = clamp(0.5 - (d / max(shape_rs.y, _1447)), 0.0, 1.0);\n    float _1462;\n    if (shape_rs.y > _1447)\n    {\n        _1462 = (_1457 * _1457) * (3.0 - (2.0 * _1457));\n    }\n    else\n    {\n        _1462 = _1457;\n    }\n    vec4 c = color;\n    bool _1484 = (_1424 <= 0.0) && (ax > (-0.5));\n    if (_1484)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1499 = cos(ax);\n            float _1501 = sin(ax);\n            g = ((dot(_1371, vec2(_1499, _1501)) / max((abs(_1499) * _1377) + (abs(_1501) * _1379), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1413)\n        {\n            vec4 _1544 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1544;\n            vec3 param = _1544.xyz;\n            float param_1 = xform.y;\n            vec3 _1551 = fa_tex_fix(param, param_1);\n            vec4 _2346 = c;\n            _2346.x = _1551.x;\n            _2346.y = _1551.y;\n            _2346.z = _1551.z;\n            c = _2346;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1563 = scene_rgb(param_2);\n            vec4 _1588 = mix(vec4(color.xyz * color.w, color.w), vec4(_1563 * color2.w, color2.w), vec4(g));\n            float _1590 = _1588.w;\n            vec3 _1593;\n            if (_1590 > 9.9999997473787516355514526367188e-06)\n            {\n                _1593 = _1588.xyz / vec3(_1590);\n            }\n            else\n            {\n                _1593 = color.xyz;\n            }\n            c = vec4(_1593, _1590);\n        }\n    }\n    vec4 _2355 = c;\n    _2355.w = _2355.w * _1462;\n    c = _2355;\n    if (_1484 || (shape_rs.y > 0.0))\n    {\n        float _1634 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1643 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1643 + vec3(_1634 * 0.0039215688593685626983642578125);\n            vec3 _1649 = fa_srgb_to_linear(param_4);\n            vec4 _2358 = c;\n            _2358.x = _1649.x;\n            _2358.y = _1649.y;\n            _2358.z = _1649.z;\n            c = _2358;\n        }\n        else\n        {\n            vec4 _1659 = c;\n            vec3 _1662 = _1659.xyz + vec3(_1634 * 0.0039215688593685626983642578125);\n            vec4 _2365 = _1659;\n            _2365.x = _1662.x;\n            _2365.y = _1662.y;\n            _2365.z = _1662.z;\n            c = _2365;\n        }\n        vec4 _2370 = c;\n        _2370.w = clamp(_2370.w + ((_1634 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2370.w)), 0.0, 1.0);\n        c = _2370;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1154 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1156 = texture(tex_smp, uv - _1154);\n    float _1157 = _1156.w;\n    vec4 _1167 = texture(tex_smp, uv + _1154);\n    float _1168 = _1167.w;\n    vec2 _1176 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1178 = texture(tex_smp, uv - _1176);\n    float _1179 = _1178.w;\n    vec4 _1189 = texture(tex_smp, uv + _1176);\n    float _1190 = _1189.w;\n    float _1205 = _1157 - _1168;\n    float _1208 = _1190 - _1179;\n    float _1218 = cos(params.y);\n    float _1220 = sin(params.y);\n    vec2 _1246 = ((vec2(_1218, _1220) * _1205) + ((vec2(-_1220, _1218) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1208)) / vec2(max(length(vec2(_1205, _1208)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1292 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1295 = length(_1292);\n            att = pow(clamp(1.0 - (_1295 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1292 / vec2(max(_1295, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1292;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1292;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1246, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1157, _1168), min(_1179, _1190))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _694 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _698 = _694.y;\n    return vec2(_694.x, mix(_698, 1.0 - _698, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _736 = base_mode < 0.5;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _748);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1689 = params.x > 31.5;\n    if (_1689)\n    {\n        mode -= 32.0;\n    }\n    float _1697 = mode;\n    bool _1699 = _1697 > 15.5;\n    if (_1699)\n    {\n        mode -= 16.0;\n    }\n    float _1707 = mode;\n    bool _1709 = _1707 > 7.5;\n    if (_1709)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1699)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1699)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1771 = tex_color(param_5);\n                vec4 _1773 = _1771 * color;\n                vec4 param_6 = _1773;\n                float param_7 = mode;\n                float _1780 = _1773.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1780);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1780;\n                    float param_9 = mode;\n                    vec4 _1796 = frag_color;\n                    vec3 _1798 = _1796.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1798.x;\n                    frag_color.y = _1798.y;\n                    frag_color.z = _1798.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1828 = length(uv);\n                    float _1831 = fwidth(_1828);\n                    float _1832 = max(_1831, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1828) / _1832) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1828) / _1832) + 0.5, 0.0, 1.0) * clamp(((_1828 - params.y) / _1832) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1872 = clamp(1.0 - _1828, 0.0, 1.0);\n                            cov = (_1872 * _1872) * (3.0 - (2.0 * _1872));\n                        }\n                    }\n                    vec3 _1881;\n                    if (_1699)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1881 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1881 = color.xyz;\n                    }\n                    frag_color = vec4(_1881, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1936 = fa_tex_fix(param_12, param_13);\n            e *= _1936;\n        }\n        vec4 _1940 = frag_color;\n        vec3 _1942 = _1940.xyz + e;\n        frag_color.x = _1942.x;\n        frag_color.y = _1942.y;\n        frag_color.z = _1942.z;\n    }\n    float param_14 = mode;\n    vec4 _2270 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2270);\n    fragment(param_15, param_16);\n    _2270 = param_16.color;\n    frag_color = param_16.color;\n    if (_1689)\n    {\n        vec4 _1968 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1973 = scene_rgb(param_17);\n        vec3 _1977 = mix(_1968.xyz, _1973, vec3(color2.w));\n        frag_color.x = _1977.x;\n        frag_color.y = _1977.y;\n        frag_color.z = _1977.z;\n    }\n    if (_1709)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2001 = quad_fs_params[53].w > 0.0;\n    bool _2009;\n    if (!_2001)\n    {\n        _2009 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2009 = _2001;\n    }\n    if (_2009)\n    {\n        vec3 _2023 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2030 = dot(_2023, quad_fs_params[55].xyz);\n        bool _2034 = quad_fs_params[55].w > 0.5;\n        float _2035;\n        if (_2034)\n        {\n            _2035 = _2030;\n        }\n        else\n        {\n            _2035 = length(_2023);\n        }\n        float _2047 = _2035 - quad_fs_params[54].x;\n        if (_2047 > 0.0)\n        {\n            float _2056 = quad_fs_params[53].w * _2047;\n            float tau = _2056 * _2056;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2072;\n                if (_2034)\n                {\n                    _2072 = world_xy.y - (quad_fs_params[55].y * _2030);\n                }\n                else\n                {\n                    _2072 = quad_fs_params[56].y;\n                }\n                float _2093 = mix(_2072, world_xy.y, clamp(quad_fs_params[54].x / _2035, 0.0, 1.0));\n                float _2097 = world_xy.y - _2093;\n                float _2102 = _2093 - quad_fs_params[54].z;\n                float _2107 = world_xy.y - quad_fs_params[54].z;\n                bool _2110 = _2102 <= 0.0;\n                bool _2111 = !_2110;\n                bool _2117;\n                if (_2111)\n                {\n                    _2117 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2117 = _2110;\n                }\n                float _2118;\n                if (_2117)\n                {\n                    _2118 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2118 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2102, 80.0));\n                }\n                bool _2145;\n                if (_2111)\n                {\n                    _2145 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2145 = _2110;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = quad_fs_params[54].y * _2102;\n                }\n                else\n                {\n                    _2146 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2102, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2171 = _2107 <= 0.0;\n                bool _2178;\n                if (!_2171)\n                {\n                    _2178 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2178 = _2171;\n                }\n                float _2179;\n                if (_2178)\n                {\n                    _2179 = quad_fs_params[54].y * _2107;\n                }\n                else\n                {\n                    _2179 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2107, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2206;\n                if (abs(_2097) < 0.001000000047497451305389404296875)\n                {\n                    _2206 = _2118;\n                }\n                else\n                {\n                    _2206 = (_2179 - _2146) / _2097;\n                }\n                tau += (_2047 * max(_2206, 0.0));\n            }\n            vec4 _2229 = frag_color;\n            vec3 _2237 = mix(_2229.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2237.x;\n            frag_color.y = _2237.y;\n            frag_color.z = _2237.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_105",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _68 = v.world_pos;\n    vec2 _76 = fa_vs_points.data[gl_InstanceID].pos.xy + (_68.xy * fa_vs_points.data[gl_InstanceID].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _178 = position;\n    vec2 _179 = texcoord0;\n    vec4 _180 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _117 = fa_srgb_to_linear(param);\n        vec4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex(_178, _179, _180);\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[101];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _138 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _144 = _138.y;\n    return vec2(_138.x, mix(_144, 1.0 - _144, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _200);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    vec4 _242 = texture(tex_smp, uv);\n    vec3 param = _242.xyz;\n    float param_1 = xform.y;\n    vec3 _253 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_253, _242.w) * color;\n    float param_2 = 0.0;\n    vec4 _308 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_308);\n    fragment(param_3, param_4);\n    _308 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_105",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
