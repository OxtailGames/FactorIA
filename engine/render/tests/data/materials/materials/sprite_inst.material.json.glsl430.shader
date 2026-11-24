{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _634 = fa_linear_to_srgb(param);\n        c = _634;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _642 = fa_srgb_to_linear(param_1);\n            c = _642;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _653 = texture(tex_smp, p);\n    vec3 param = _653.xyz;\n    float param_1 = xform.y;\n    vec3 _663 = fa_tex_fix(param, param_1);\n    return vec4(_663, _653.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _852 = (world_xy * quad_fs_params[99].xy) + quad_fs_params[99].zw;\n    vec4 _859 = textureLod(fx_gi_tex_light_smp, _852, 0.0);\n    float _863 = _852.x;\n    bool _864 = _863 >= 0.0;\n    bool _870;\n    if (_864)\n    {\n        _870 = _852.y >= 0.0;\n    }\n    else\n    {\n        _870 = _864;\n    }\n    bool _876;\n    if (_870)\n    {\n        _876 = _863 <= 1.0;\n    }\n    else\n    {\n        _876 = _870;\n    }\n    bool _882;\n    if (_876)\n    {\n        _882 = _852.y <= 1.0;\n    }\n    else\n    {\n        _882 = _876;\n    }\n    bool _890;\n    if (_882)\n    {\n        _890 = _859.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _890 = _882;\n    }\n    vec3 _891;\n    if (_890)\n    {\n        _891 = (_859.xyz / vec3(_859.w)) * quad_fs_params[100].x;\n    }\n    else\n    {\n        _891 = vec3(0.0);\n    }\n    return _891;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _143 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_143.x * 255.0) + 0.5) * 256.0) + floor((_143.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _246 = floor(tt);\n    float _256 = _246 - (1024.0 * floor(_246 * 0.0009765625));\n    float _259 = _256 + 1.0;\n    float i1 = _259;\n    if (_259 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _256;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _246);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _296 = length(d);\n    float result = 1.0;\n    if (_296 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _307 = atan(d.y, d.x);\n        float a = _307;\n        float _310;\n        if (_307 < 0.0)\n        {\n            _310 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _310 = a;\n        }\n        a = _310;\n        float _320 = _310 * 162.9746551513671875;\n        float _329 = min((size * 10.0) / _296, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _355 = floor(_320 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _329));\n            float param = v;\n            float param_1 = _355 - (1024.0 * floor(_355 * 0.0009765625));\n            float _369 = shadow_texel(param, param_1) * radius;\n            if (_369 < _296)\n            {\n                sum += _369;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _401 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _296)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _419 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _425 = 1.0 - (0.800000011920928955078125 * abs(_419));\n                float param_2 = v;\n                float param_3 = _320 + (_419 * _401);\n                float param_4 = _296;\n                float param_5 = radius;\n                acc += (_425 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _425;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _167 = length(d);\n    if (_167 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _181 = atan(d.y, d.x);\n    float a = _181;\n    float _184;\n    if (_181 < 0.0)\n    {\n        _184 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _184 = a;\n    }\n    a = _184;\n    float _196 = _184 * 162.9746551513671875;\n    float _201 = min(floor(_196), 1023.0);\n    float _208 = _201 + 1.0;\n    float i1 = _208;\n    if (_208 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _201;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _167) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _167) + 0.5, 0.0, 1.0), _196 - _201);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _506 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _510 = _506.x + 0.5;\n    vec2 c = vec2(_510, 0.5 - _506.y);\n    bool _518 = _510 >= 0.0;\n    bool _524;\n    if (_518)\n    {\n        _524 = c.x <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y >= 0.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    bool _536;\n    if (_530)\n    {\n        _536 = c.y <= 1.0;\n    }\n    else\n    {\n        _536 = _530;\n    }\n    vec2 _538 = c;\n    vec2 _543 = clamp(_538, vec2(0.001953125), vec2(0.998046875));\n    c = _543;\n    return vec3(cell.x + (_543.x * cell.w), cell.y + (_543.y * cell.z), float(_536));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _826 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _826.xy, 0.0);\n    return cookie_value(param_3) * _826.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _913 = quad_fs_params[0].y > 0.5;\n    if (_913)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _937 = fa_tex_fix(param, param_1);\n        vec3 _941 = (_937 * 2.0) - vec3(1.0);\n        float _948 = cos(params.y);\n        float _950 = sin(params.y);\n        n = normalize(vec3((vec2(_948, _950) * _941.x) + ((vec2(-_950, _948) * ((mode > 5.5) ? (-1.0) : 1.0)) * _941.y), max(_941.z, 0.0500000007450580596923828125)));\n    }\n    bool _984 = !_913;\n    bool _990;\n    if (_984)\n    {\n        _990 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _990 = _984;\n    }\n    vec3 _993;\n    if (_990)\n    {\n        _993 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _993 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _993;\n    if (quad_fs_params[100].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _1018;\n    if (_990)\n    {\n        _1018 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _1018 = _990;\n    }\n    if (_1018)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1145;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1055;\n        if (!_990)\n        {\n            _1055 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1055 = _990;\n        }\n        if (_1055)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1081 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1081) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1101 = vec3(_1081, quad_fs_params[i * 1 + 5].z);\n            l = _1101 / vec3(max(length(_1101), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1081;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1081;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_913)\n        {\n            _1145 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1145 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1145));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _679 = fa_srgb_to_linear(param);\n        c = _679;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1395 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1399 = uv * _1395;\n    float _1405 = _1395.x;\n    float _1407 = _1395.y;\n    float _1409 = clamp(shape_rs.x, 0.0, min(_1405, _1407));\n    vec2 _1420 = (abs(_1399) - _1395) + vec2(_1409);\n    float d = (length(max(_1420, vec2(0.0))) + min(max(_1420.x, _1420.y), 0.0)) - _1409;\n    float ax = params.y;\n    bool _1441 = params.y > 15.0;\n    if (_1441)\n    {\n        ax -= 20.0;\n    }\n    float _1452;\n    if (ax <= (-1.5))\n    {\n        _1452 = (-2.0) - ax;\n    }\n    else\n    {\n        _1452 = 0.0;\n    }\n    if (_1452 > 0.0)\n    {\n        float _1466 = _1452 * 0.5;\n        d = abs(d + _1466) - _1466;\n    }\n    float _1474 = fwidth(d);\n    float _1475 = max(_1474, 9.9999997473787516355514526367188e-05);\n    float _1485 = clamp(0.5 - (d / max(shape_rs.y, _1475)), 0.0, 1.0);\n    float _1490;\n    if (shape_rs.y > _1475)\n    {\n        _1490 = (_1485 * _1485) * (3.0 - (2.0 * _1485));\n    }\n    else\n    {\n        _1490 = _1485;\n    }\n    vec4 c = color;\n    bool _1512 = (_1452 <= 0.0) && (ax > (-0.5));\n    if (_1512)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1527 = cos(ax);\n            float _1529 = sin(ax);\n            g = ((dot(_1399, vec2(_1527, _1529)) / max((abs(_1527) * _1405) + (abs(_1529) * _1407), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1441)\n        {\n            vec4 _1572 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1572;\n            vec3 param = _1572.xyz;\n            float param_1 = xform.y;\n            vec3 _1579 = fa_tex_fix(param, param_1);\n            vec4 _2374 = c;\n            _2374.x = _1579.x;\n            _2374.y = _1579.y;\n            _2374.z = _1579.z;\n            c = _2374;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1591 = scene_rgb(param_2);\n            vec4 _1616 = mix(vec4(color.xyz * color.w, color.w), vec4(_1591 * color2.w, color2.w), vec4(g));\n            float _1618 = _1616.w;\n            vec3 _1621;\n            if (_1618 > 9.9999997473787516355514526367188e-06)\n            {\n                _1621 = _1616.xyz / vec3(_1618);\n            }\n            else\n            {\n                _1621 = color.xyz;\n            }\n            c = vec4(_1621, _1618);\n        }\n    }\n    vec4 _2383 = c;\n    _2383.w = _2383.w * _1490;\n    c = _2383;\n    if (_1512 || (shape_rs.y > 0.0))\n    {\n        float _1662 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1671 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1671 + vec3(_1662 * 0.0039215688593685626983642578125);\n            vec3 _1677 = fa_srgb_to_linear(param_4);\n            vec4 _2386 = c;\n            _2386.x = _1677.x;\n            _2386.y = _1677.y;\n            _2386.z = _1677.z;\n            c = _2386;\n        }\n        else\n        {\n            vec4 _1687 = c;\n            vec3 _1690 = _1687.xyz + vec3(_1662 * 0.0039215688593685626983642578125);\n            vec4 _2393 = _1687;\n            _2393.x = _1690.x;\n            _2393.y = _1690.y;\n            _2393.z = _1690.z;\n            c = _2393;\n        }\n        vec4 _2398 = c;\n        _2398.w = clamp(_2398.w + ((_1662 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2398.w)), 0.0, 1.0);\n        c = _2398;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1182 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1184 = texture(tex_smp, uv - _1182);\n    float _1185 = _1184.w;\n    vec4 _1195 = texture(tex_smp, uv + _1182);\n    float _1196 = _1195.w;\n    vec2 _1204 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1206 = texture(tex_smp, uv - _1204);\n    float _1207 = _1206.w;\n    vec4 _1217 = texture(tex_smp, uv + _1204);\n    float _1218 = _1217.w;\n    float _1233 = _1185 - _1196;\n    float _1236 = _1218 - _1207;\n    float _1246 = cos(params.y);\n    float _1248 = sin(params.y);\n    vec2 _1274 = ((vec2(_1246, _1248) * _1233) + ((vec2(-_1248, _1246) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1236)) / vec2(max(length(vec2(_1233, _1236)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1320 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1323 = length(_1320);\n            att = pow(clamp(1.0 - (_1323 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1320 / vec2(max(_1323, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1320;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1320;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1274, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1185, _1196), min(_1207, _1218))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _708 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _712 = _708.y;\n    return vec2(_708.x, mix(_712, 1.0 - _712, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _750 = base_mode < 0.5;\n    bool _761;\n    if (!_750)\n    {\n        _761 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _761 = _750;\n    }\n    float _762;\n    if (_761)\n    {\n        _762 = shape_half.x;\n    }\n    else\n    {\n        _762 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _762);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _685 = scene_rgb(param);\n    return _685;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _790 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _790.x;\n    s.color.y = _790.y;\n    s.color.z = _790.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1717 = params.x > 31.5;\n    if (_1717)\n    {\n        mode -= 32.0;\n    }\n    float _1725 = mode;\n    bool _1727 = _1725 > 15.5;\n    if (_1727)\n    {\n        mode -= 16.0;\n    }\n    float _1735 = mode;\n    bool _1737 = _1735 > 7.5;\n    if (_1737)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1727)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1727)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1799 = tex_color(param_5);\n                vec4 _1801 = _1799 * color;\n                vec4 param_6 = _1801;\n                float param_7 = mode;\n                float _1808 = _1801.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1808);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1808;\n                    float param_9 = mode;\n                    vec4 _1824 = frag_color;\n                    vec3 _1826 = _1824.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1826.x;\n                    frag_color.y = _1826.y;\n                    frag_color.z = _1826.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1856 = length(uv);\n                    float _1859 = fwidth(_1856);\n                    float _1860 = max(_1859, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1856) / _1860) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1856) / _1860) + 0.5, 0.0, 1.0) * clamp(((_1856 - params.y) / _1860) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1900 = clamp(1.0 - _1856, 0.0, 1.0);\n                            cov = (_1900 * _1900) * (3.0 - (2.0 * _1900));\n                        }\n                    }\n                    vec3 _1909;\n                    if (_1727)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1909 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1909 = color.xyz;\n                    }\n                    frag_color = vec4(_1909, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1964 = fa_tex_fix(param_12, param_13);\n            e *= _1964;\n        }\n        vec4 _1968 = frag_color;\n        vec3 _1970 = _1968.xyz + e;\n        frag_color.x = _1970.x;\n        frag_color.y = _1970.y;\n        frag_color.z = _1970.z;\n    }\n    float param_14 = mode;\n    vec4 _2298 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2298);\n    fragment(param_15, param_16);\n    _2298 = param_16.color;\n    frag_color = param_16.color;\n    if (_1717)\n    {\n        vec4 _1996 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _2001 = scene_rgb(param_17);\n        vec3 _2005 = mix(_1996.xyz, _2001, vec3(color2.w));\n        frag_color.x = _2005.x;\n        frag_color.y = _2005.y;\n        frag_color.z = _2005.z;\n    }\n    if (_1737)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2029 = quad_fs_params[53].w > 0.0;\n    bool _2037;\n    if (!_2029)\n    {\n        _2037 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2037 = _2029;\n    }\n    if (_2037)\n    {\n        vec3 _2051 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2058 = dot(_2051, quad_fs_params[55].xyz);\n        bool _2062 = quad_fs_params[55].w > 0.5;\n        float _2063;\n        if (_2062)\n        {\n            _2063 = _2058;\n        }\n        else\n        {\n            _2063 = length(_2051);\n        }\n        float _2075 = _2063 - quad_fs_params[54].x;\n        if (_2075 > 0.0)\n        {\n            float _2084 = quad_fs_params[53].w * _2075;\n            float tau = _2084 * _2084;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2100;\n                if (_2062)\n                {\n                    _2100 = world_xy.y - (quad_fs_params[55].y * _2058);\n                }\n                else\n                {\n                    _2100 = quad_fs_params[56].y;\n                }\n                float _2121 = mix(_2100, world_xy.y, clamp(quad_fs_params[54].x / _2063, 0.0, 1.0));\n                float _2125 = world_xy.y - _2121;\n                float _2130 = _2121 - quad_fs_params[54].z;\n                float _2135 = world_xy.y - quad_fs_params[54].z;\n                bool _2138 = _2130 <= 0.0;\n                bool _2139 = !_2138;\n                bool _2145;\n                if (_2139)\n                {\n                    _2145 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2145 = _2138;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2146 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2130, 80.0));\n                }\n                bool _2173;\n                if (_2139)\n                {\n                    _2173 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2173 = _2138;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = quad_fs_params[54].y * _2130;\n                }\n                else\n                {\n                    _2174 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2130, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2199 = _2135 <= 0.0;\n                bool _2206;\n                if (!_2199)\n                {\n                    _2206 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2206 = _2199;\n                }\n                float _2207;\n                if (_2206)\n                {\n                    _2207 = quad_fs_params[54].y * _2135;\n                }\n                else\n                {\n                    _2207 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2135, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2234;\n                if (abs(_2125) < 0.001000000047497451305389404296875)\n                {\n                    _2234 = _2146;\n                }\n                else\n                {\n                    _2234 = (_2207 - _2174) / _2125;\n                }\n                tau += (_2075 * max(_2234, 0.0));\n            }\n            vec4 _2257 = frag_color;\n            vec3 _2265 = mix(_2257.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2265.x;\n            frag_color.y = _2265.y;\n            frag_color.z = _2265.z;\n        }\n    }\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_702",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_787",
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[101];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _171 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _176 = _171.y;\n    return vec2(_171.x, mix(_176, 1.0 - _176, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _219 = base_mode < 0.5;\n    bool _230;\n    if (!_219)\n    {\n        _230 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _230 = _219;\n    }\n    float _231;\n    if (_230)\n    {\n        _231 = shape_half.x;\n    }\n    else\n    {\n        _231 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _231);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _259 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _259.x;\n    s.color.y = _259.y;\n    s.color.z = _259.z;\n}\n\nvoid main()\n{\n    vec4 _286 = texture(tex_smp, uv);\n    vec3 param = _286.xyz;\n    float param_1 = xform.y;\n    vec3 _295 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_295, _286.w) * color;\n    float param_2 = 0.0;\n    vec4 _350 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_350);\n    fragment(param_3, param_4);\n    _350 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_164",
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
