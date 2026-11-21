{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D fx_gi_tex_light_smp;\nlayout(binding = 3) uniform sampler2D light_tex_light_smp;\nlayout(binding = 4) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 5) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 6) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _634 = fa_linear_to_srgb(param);\n        c = _634;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _642 = fa_srgb_to_linear(param_1);\n            c = _642;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _653 = texture(tex_smp, p);\n    vec3 param = _653.xyz;\n    float param_1 = xform.y;\n    vec3 _663 = fa_tex_fix(param, param_1);\n    return vec4(_663, _653.w);\n}\n\nvec3 gi_irradiance()\n{\n    vec2 _851 = (world_xy * quad_fs_params[95].xy) + quad_fs_params[95].zw;\n    vec4 _858 = textureLod(fx_gi_tex_light_smp, _851, 0.0);\n    float _862 = _851.x;\n    bool _863 = _862 >= 0.0;\n    bool _869;\n    if (_863)\n    {\n        _869 = _851.y >= 0.0;\n    }\n    else\n    {\n        _869 = _863;\n    }\n    bool _875;\n    if (_869)\n    {\n        _875 = _862 <= 1.0;\n    }\n    else\n    {\n        _875 = _869;\n    }\n    bool _881;\n    if (_875)\n    {\n        _881 = _851.y <= 1.0;\n    }\n    else\n    {\n        _881 = _875;\n    }\n    bool _889;\n    if (_881)\n    {\n        _889 = _858.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _889 = _881;\n    }\n    vec3 _890;\n    if (_889)\n    {\n        _890 = (_858.xyz / vec3(_858.w)) * quad_fs_params[96].x;\n    }\n    else\n    {\n        _890 = vec3(0.0);\n    }\n    return _890;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _143 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_143.x * 255.0) + 0.5) * 256.0) + floor((_143.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _246 = floor(tt);\n    float _256 = _246 - (1024.0 * floor(_246 * 0.0009765625));\n    float _259 = _256 + 1.0;\n    float i1 = _259;\n    if (_259 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _256;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _246);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _296 = length(d);\n    float result = 1.0;\n    if (_296 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _307 = atan(d.y, d.x);\n        float a = _307;\n        float _310;\n        if (_307 < 0.0)\n        {\n            _310 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _310 = a;\n        }\n        a = _310;\n        float _320 = _310 * 162.9746551513671875;\n        float _329 = min((size * 10.0) / _296, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _355 = floor(_320 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _329));\n            float param = v;\n            float param_1 = _355 - (1024.0 * floor(_355 * 0.0009765625));\n            float _369 = shadow_texel(param, param_1) * radius;\n            if (_369 < _296)\n            {\n                sum += _369;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _401 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _296)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _419 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _425 = 1.0 - (0.800000011920928955078125 * abs(_419));\n                float param_2 = v;\n                float param_3 = _320 + (_419 * _401);\n                float param_4 = _296;\n                float param_5 = radius;\n                acc += (_425 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _425;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _167 = length(d);\n    if (_167 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _181 = atan(d.y, d.x);\n    float a = _181;\n    float _184;\n    if (_181 < 0.0)\n    {\n        _184 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _184 = a;\n    }\n    a = _184;\n    float _196 = _184 * 162.9746551513671875;\n    float _201 = min(floor(_196), 1023.0);\n    float _208 = _201 + 1.0;\n    float i1 = _208;\n    if (_208 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _201;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _167) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _167) + 0.5, 0.0, 1.0), _196 - _201);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _506 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _510 = _506.x + 0.5;\n    vec2 c = vec2(_510, 0.5 - _506.y);\n    bool _518 = _510 >= 0.0;\n    bool _524;\n    if (_518)\n    {\n        _524 = c.x <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y >= 0.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    bool _536;\n    if (_530)\n    {\n        _536 = c.y <= 1.0;\n    }\n    else\n    {\n        _536 = _530;\n    }\n    vec2 _538 = c;\n    vec2 _543 = clamp(_538, vec2(0.001953125), vec2(0.998046875));\n    c = _543;\n    return vec3(cell.x + (_543.x * cell.w), cell.y + (_543.y * cell.z), float(_536));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _825 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _825.xy, 0.0);\n    return cookie_value(param_3) * _825.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _912 = quad_fs_params[0].y > 0.5;\n    if (_912)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _936 = fa_tex_fix(param, param_1);\n        vec3 _940 = (_936 * 2.0) - vec3(1.0);\n        float _947 = cos(params.y);\n        float _949 = sin(params.y);\n        n = normalize(vec3((vec2(_947, _949) * _940.x) + ((vec2(-_949, _947) * ((mode > 5.5) ? (-1.0) : 1.0)) * _940.y), max(_940.z, 0.0500000007450580596923828125)));\n    }\n    bool _983 = !_912;\n    bool _989;\n    if (_983)\n    {\n        _989 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _989 = _983;\n    }\n    vec3 _992;\n    if (_989)\n    {\n        _992 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _992 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _992;\n    if (quad_fs_params[96].x > 0.0)\n    {\n        total += gi_irradiance();\n    }\n    bool _1017;\n    if (_989)\n    {\n        _1017 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _1017 = _989;\n    }\n    if (_1017)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _1144;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1054;\n        if (!_989)\n        {\n            _1054 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _1054 = _989;\n        }\n        if (_1054)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _1080 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_1080) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _1100 = vec3(_1080, quad_fs_params[i * 1 + 5].z);\n            l = _1100 / vec3(max(length(_1100), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_1080;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            vec2 param_7 = -_1080;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_912)\n        {\n            _1144 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1144 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _1144));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _679 = fa_srgb_to_linear(param);\n        c = _679;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1394 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1398 = uv * _1394;\n    float _1404 = _1394.x;\n    float _1406 = _1394.y;\n    float _1408 = clamp(shape_rs.x, 0.0, min(_1404, _1406));\n    vec2 _1419 = (abs(_1398) - _1394) + vec2(_1408);\n    float d = (length(max(_1419, vec2(0.0))) + min(max(_1419.x, _1419.y), 0.0)) - _1408;\n    float ax = params.y;\n    bool _1440 = params.y > 15.0;\n    if (_1440)\n    {\n        ax -= 20.0;\n    }\n    float _1451;\n    if (ax <= (-1.5))\n    {\n        _1451 = (-2.0) - ax;\n    }\n    else\n    {\n        _1451 = 0.0;\n    }\n    if (_1451 > 0.0)\n    {\n        float _1465 = _1451 * 0.5;\n        d = abs(d + _1465) - _1465;\n    }\n    float _1473 = fwidth(d);\n    float _1474 = max(_1473, 9.9999997473787516355514526367188e-05);\n    float _1484 = clamp(0.5 - (d / max(shape_rs.y, _1474)), 0.0, 1.0);\n    float _1489;\n    if (shape_rs.y > _1474)\n    {\n        _1489 = (_1484 * _1484) * (3.0 - (2.0 * _1484));\n    }\n    else\n    {\n        _1489 = _1484;\n    }\n    vec4 c = color;\n    bool _1511 = (_1451 <= 0.0) && (ax > (-0.5));\n    if (_1511)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1526 = cos(ax);\n            float _1528 = sin(ax);\n            g = ((dot(_1398, vec2(_1526, _1528)) / max((abs(_1526) * _1404) + (abs(_1528) * _1406), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1440)\n        {\n            vec4 _1571 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1571;\n            vec3 param = _1571.xyz;\n            float param_1 = xform.y;\n            vec3 _1578 = fa_tex_fix(param, param_1);\n            vec4 _2372 = c;\n            _2372.x = _1578.x;\n            _2372.y = _1578.y;\n            _2372.z = _1578.z;\n            c = _2372;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1590 = scene_rgb(param_2);\n            vec4 _1615 = mix(vec4(color.xyz * color.w, color.w), vec4(_1590 * color2.w, color2.w), vec4(g));\n            float _1617 = _1615.w;\n            vec3 _1620;\n            if (_1617 > 9.9999997473787516355514526367188e-06)\n            {\n                _1620 = _1615.xyz / vec3(_1617);\n            }\n            else\n            {\n                _1620 = color.xyz;\n            }\n            c = vec4(_1620, _1617);\n        }\n    }\n    vec4 _2381 = c;\n    _2381.w = _2381.w * _1489;\n    c = _2381;\n    if (_1511 || (shape_rs.y > 0.0))\n    {\n        float _1661 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1670 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1670 + vec3(_1661 * 0.0039215688593685626983642578125);\n            vec3 _1676 = fa_srgb_to_linear(param_4);\n            vec4 _2384 = c;\n            _2384.x = _1676.x;\n            _2384.y = _1676.y;\n            _2384.z = _1676.z;\n            c = _2384;\n        }\n        else\n        {\n            vec4 _1686 = c;\n            vec3 _1689 = _1686.xyz + vec3(_1661 * 0.0039215688593685626983642578125);\n            vec4 _2391 = _1686;\n            _2391.x = _1689.x;\n            _2391.y = _1689.y;\n            _2391.z = _1689.z;\n            c = _2391;\n        }\n        vec4 _2396 = c;\n        _2396.w = clamp(_2396.w + ((_1661 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2396.w)), 0.0, 1.0);\n        c = _2396;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _1181 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _1183 = texture(tex_smp, uv - _1181);\n    float _1184 = _1183.w;\n    vec4 _1194 = texture(tex_smp, uv + _1181);\n    float _1195 = _1194.w;\n    vec2 _1203 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _1205 = texture(tex_smp, uv - _1203);\n    float _1206 = _1205.w;\n    vec4 _1216 = texture(tex_smp, uv + _1203);\n    float _1217 = _1216.w;\n    float _1232 = _1184 - _1195;\n    float _1235 = _1217 - _1206;\n    float _1245 = cos(params.y);\n    float _1247 = sin(params.y);\n    vec2 _1273 = ((vec2(_1245, _1247) * _1232) + ((vec2(-_1247, _1245) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1235)) / vec2(max(length(vec2(_1232, _1235)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _1319 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _1322 = length(_1319);\n            att = pow(clamp(1.0 - (_1322 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _1319 / vec2(max(_1322, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                float param_1 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_2 = -_1319;\n                float param_3 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            vec2 param_5 = -_1319;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_1273, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_1184, _1195), min(_1206, _1217))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _707 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _711 = _707.y;\n    return vec2(_707.x, mix(_711, 1.0 - _711, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _749 = base_mode < 0.5;\n    bool _760;\n    if (!_749)\n    {\n        _760 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _760 = _749;\n    }\n    float _761;\n    if (_760)\n    {\n        _761 = shape_half.x;\n    }\n    else\n    {\n        _761 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _761);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _685 = scene_rgb(param);\n    return _685;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _789 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _789.x;\n    s.color.y = _789.y;\n    s.color.z = _789.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1716 = params.x > 31.5;\n    if (_1716)\n    {\n        mode -= 32.0;\n    }\n    float _1724 = mode;\n    bool _1726 = _1724 > 15.5;\n    if (_1726)\n    {\n        mode -= 16.0;\n    }\n    float _1734 = mode;\n    bool _1736 = _1734 > 7.5;\n    if (_1736)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1726)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1726)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1798 = tex_color(param_5);\n                vec4 _1800 = _1798 * color;\n                vec4 param_6 = _1800;\n                float param_7 = mode;\n                float _1807 = _1800.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1807);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1807;\n                    float param_9 = mode;\n                    vec4 _1823 = frag_color;\n                    vec3 _1825 = _1823.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1825.x;\n                    frag_color.y = _1825.y;\n                    frag_color.z = _1825.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1855 = length(uv);\n                    float _1858 = fwidth(_1855);\n                    float _1859 = max(_1858, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1855) / _1859) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1855) / _1859) + 0.5, 0.0, 1.0) * clamp(((_1855 - params.y) / _1859) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1899 = clamp(1.0 - _1855, 0.0, 1.0);\n                            cov = (_1899 * _1899) * (3.0 - (2.0 * _1899));\n                        }\n                    }\n                    vec3 _1908;\n                    if (_1726)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1908 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1908 = color.xyz;\n                    }\n                    frag_color = vec4(_1908, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1963 = fa_tex_fix(param_12, param_13);\n            e *= _1963;\n        }\n        vec4 _1967 = frag_color;\n        vec3 _1969 = _1967.xyz + e;\n        frag_color.x = _1969.x;\n        frag_color.y = _1969.y;\n        frag_color.z = _1969.z;\n    }\n    float param_14 = mode;\n    vec4 _2296 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_2296);\n    fragment(param_15, param_16);\n    _2296 = param_16.color;\n    frag_color = param_16.color;\n    if (_1716)\n    {\n        vec4 _1995 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _2000 = scene_rgb(param_17);\n        vec3 _2004 = mix(_1995.xyz, _2000, vec3(color2.w));\n        frag_color.x = _2004.x;\n        frag_color.y = _2004.y;\n        frag_color.z = _2004.z;\n    }\n    if (_1736)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _2028 = quad_fs_params[53].w > 0.0;\n    bool _2036;\n    if (!_2028)\n    {\n        _2036 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _2036 = _2028;\n    }\n    if (_2036)\n    {\n        vec3 _2050 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _2057 = dot(_2050, quad_fs_params[55].xyz);\n        bool _2061 = quad_fs_params[55].w > 0.5;\n        float _2062;\n        if (_2061)\n        {\n            _2062 = _2057;\n        }\n        else\n        {\n            _2062 = length(_2050);\n        }\n        float _2074 = _2062 - quad_fs_params[54].x;\n        if (_2074 > 0.0)\n        {\n            float _2083 = quad_fs_params[53].w * _2074;\n            float tau = _2083 * _2083;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _2099;\n                if (_2061)\n                {\n                    _2099 = world_xy.y - (quad_fs_params[55].y * _2057);\n                }\n                else\n                {\n                    _2099 = quad_fs_params[56].y;\n                }\n                float _2120 = mix(_2099, world_xy.y, clamp(quad_fs_params[54].x / _2062, 0.0, 1.0));\n                float _2124 = world_xy.y - _2120;\n                float _2129 = _2120 - quad_fs_params[54].z;\n                float _2134 = world_xy.y - quad_fs_params[54].z;\n                bool _2137 = _2129 <= 0.0;\n                bool _2138 = !_2137;\n                bool _2144;\n                if (_2138)\n                {\n                    _2144 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2144 = _2137;\n                }\n                float _2145;\n                if (_2144)\n                {\n                    _2145 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _2145 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _2129, 80.0));\n                }\n                bool _2172;\n                if (_2138)\n                {\n                    _2172 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2172 = _2137;\n                }\n                float _2173;\n                if (_2172)\n                {\n                    _2173 = quad_fs_params[54].y * _2129;\n                }\n                else\n                {\n                    _2173 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2129, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _2198 = _2134 <= 0.0;\n                bool _2205;\n                if (!_2198)\n                {\n                    _2205 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2205 = _2198;\n                }\n                float _2206;\n                if (_2205)\n                {\n                    _2206 = quad_fs_params[54].y * _2134;\n                }\n                else\n                {\n                    _2206 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _2134, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _2233;\n                if (abs(_2124) < 0.001000000047497451305389404296875)\n                {\n                    _2233 = _2145;\n                }\n                else\n                {\n                    _2233 = (_2206 - _2173) / _2124;\n                }\n                tau += (_2074 * max(_2233, 0.0));\n            }\n            vec4 _2256 = frag_color;\n            vec3 _2264 = mix(_2256.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _2264.x;\n            frag_color.y = _2264.y;\n            frag_color.z = _2264.z;\n        }\n    }\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_701",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 97,
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
            "inst_name": "_786",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[97];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _169 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _174 = _169.y;\n    return vec2(_169.x, mix(_174, 1.0 - _174, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _229);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _257 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nvoid main()\n{\n    vec4 _284 = texture(tex_smp, uv);\n    vec3 param = _284.xyz;\n    float param_1 = xform.y;\n    vec3 _293 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_293, _284.w) * color;\n    float param_2 = 0.0;\n    vec4 _347 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_347);\n    fragment(param_3, param_4);\n    _347 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 97,
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
            "inst_name": "_254",
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
