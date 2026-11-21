{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _376 = fa_linear_to_srgb(param);\n        c = _376;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _384 = fa_srgb_to_linear(param_1);\n            c = _384;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _395 = texture(tex_smp, p);\n    vec3 param = _395.xyz;\n    float param_1 = xform.y;\n    vec3 _405 = fa_tex_fix(param, param_1);\n    return vec4(_405, _395.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _120 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_120.x * 255.0) + 0.5) * 256.0) + floor((_120.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _144 = length(d);\n    if (_144 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _158 = atan(d.y, d.x);\n    float a = _158;\n    float _161;\n    if (_158 < 0.0)\n    {\n        _161 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _161 = a;\n    }\n    a = _161;\n    float _173 = _161 * 162.9746551513671875;\n    float _178 = min(floor(_173), 1023.0);\n    float _185 = _178 + 1.0;\n    float i1 = _185;\n    if (_185 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _178;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _144) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _144) + 0.5, 0.0, 1.0), _173 - _178);\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _248 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _252 = _248.x + 0.5;\n    vec2 c = vec2(_252, 0.5 - _248.y);\n    bool _260 = _252 >= 0.0;\n    bool _266;\n    if (_260)\n    {\n        _266 = c.x <= 1.0;\n    }\n    else\n    {\n        _266 = _260;\n    }\n    bool _272;\n    if (_266)\n    {\n        _272 = c.y >= 0.0;\n    }\n    else\n    {\n        _272 = _266;\n    }\n    bool _278;\n    if (_272)\n    {\n        _278 = c.y <= 1.0;\n    }\n    else\n    {\n        _278 = _272;\n    }\n    vec2 _280 = c;\n    vec2 _285 = clamp(_280, vec2(0.001953125), vec2(0.998046875));\n    c = _285;\n    return vec3(cell.x + (_285.x * cell.w), cell.y + (_285.y * cell.z), float(_278));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _570 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _570.xy, 0.0);\n    return cookie_value(param_3) * _570.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _592 = quad_fs_params[0].y > 0.5;\n    if (_592)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _616 = fa_tex_fix(param, param_1);\n        vec3 _620 = (_616 * 2.0) - vec3(1.0);\n        float _627 = cos(params.y);\n        float _629 = sin(params.y);\n        n = normalize(vec3((vec2(_627, _629) * _620.x) + ((vec2(-_629, _627) * ((mode > 5.5) ? (-1.0) : 1.0)) * _620.y), max(_620.z, 0.0500000007450580596923828125)));\n    }\n    bool _663 = !_592;\n    bool _669;\n    if (_663)\n    {\n        _669 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _669 = _663;\n    }\n    vec3 _672;\n    if (_669)\n    {\n        _672 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _672 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _672;\n    bool _689;\n    if (_669)\n    {\n        _689 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _689 = _669;\n    }\n    if (_689)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _813;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _727;\n        if (!_669)\n        {\n            _727 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _727 = _669;\n        }\n        if (_727)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _753 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_753) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _773 = vec3(_753, quad_fs_params[i * 1 + 5].z);\n            l = _773 / vec3(max(length(_773), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_753;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            vec2 param_6 = -_753;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_592)\n        {\n            _813 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _813 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _813));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _421 = fa_srgb_to_linear(param);\n        c = _421;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1059 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1063 = uv * _1059;\n    float _1069 = _1059.x;\n    float _1071 = _1059.y;\n    float _1073 = clamp(shape_rs.x, 0.0, min(_1069, _1071));\n    vec2 _1084 = (abs(_1063) - _1059) + vec2(_1073);\n    float d = (length(max(_1084, vec2(0.0))) + min(max(_1084.x, _1084.y), 0.0)) - _1073;\n    float ax = params.y;\n    bool _1105 = params.y > 15.0;\n    if (_1105)\n    {\n        ax -= 20.0;\n    }\n    float _1116;\n    if (ax <= (-1.5))\n    {\n        _1116 = (-2.0) - ax;\n    }\n    else\n    {\n        _1116 = 0.0;\n    }\n    if (_1116 > 0.0)\n    {\n        float _1130 = _1116 * 0.5;\n        d = abs(d + _1130) - _1130;\n    }\n    float _1138 = fwidth(d);\n    float _1139 = max(_1138, 9.9999997473787516355514526367188e-05);\n    float _1149 = clamp(0.5 - (d / max(shape_rs.y, _1139)), 0.0, 1.0);\n    float _1154;\n    if (shape_rs.y > _1139)\n    {\n        _1154 = (_1149 * _1149) * (3.0 - (2.0 * _1149));\n    }\n    else\n    {\n        _1154 = _1149;\n    }\n    vec4 c = color;\n    bool _1176 = (_1116 <= 0.0) && (ax > (-0.5));\n    if (_1176)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1191 = cos(ax);\n            float _1193 = sin(ax);\n            g = ((dot(_1063, vec2(_1191, _1193)) / max((abs(_1191) * _1069) + (abs(_1193) * _1071), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1105)\n        {\n            vec4 _1236 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1236;\n            vec3 param = _1236.xyz;\n            float param_1 = xform.y;\n            vec3 _1243 = fa_tex_fix(param, param_1);\n            vec4 _2031 = c;\n            _2031.x = _1243.x;\n            _2031.y = _1243.y;\n            _2031.z = _1243.z;\n            c = _2031;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1255 = scene_rgb(param_2);\n            vec4 _1280 = mix(vec4(color.xyz * color.w, color.w), vec4(_1255 * color2.w, color2.w), vec4(g));\n            float _1282 = _1280.w;\n            vec3 _1285;\n            if (_1282 > 9.9999997473787516355514526367188e-06)\n            {\n                _1285 = _1280.xyz / vec3(_1282);\n            }\n            else\n            {\n                _1285 = color.xyz;\n            }\n            c = vec4(_1285, _1282);\n        }\n    }\n    vec4 _2040 = c;\n    _2040.w = _2040.w * _1154;\n    c = _2040;\n    if (_1176 || (shape_rs.y > 0.0))\n    {\n        float _1326 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1335 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1335 + vec3(_1326 * 0.0039215688593685626983642578125);\n            vec3 _1341 = fa_srgb_to_linear(param_4);\n            vec4 _2043 = c;\n            _2043.x = _1341.x;\n            _2043.y = _1341.y;\n            _2043.z = _1341.z;\n            c = _2043;\n        }\n        else\n        {\n            vec4 _1351 = c;\n            vec3 _1354 = _1351.xyz + vec3(_1326 * 0.0039215688593685626983642578125);\n            vec4 _2050 = _1351;\n            _2050.x = _1354.x;\n            _2050.y = _1354.y;\n            _2050.z = _1354.z;\n            c = _2050;\n        }\n        vec4 _2055 = c;\n        _2055.w = clamp(_2055.w + ((_1326 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2055.w)), 0.0, 1.0);\n        c = _2055;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _850 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _852 = texture(tex_smp, uv - _850);\n    float _853 = _852.w;\n    vec4 _863 = texture(tex_smp, uv + _850);\n    float _864 = _863.w;\n    vec2 _872 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _874 = texture(tex_smp, uv - _872);\n    float _875 = _874.w;\n    vec4 _885 = texture(tex_smp, uv + _872);\n    float _886 = _885.w;\n    float _901 = _853 - _864;\n    float _904 = _886 - _875;\n    float _914 = cos(params.y);\n    float _916 = sin(params.y);\n    vec2 _942 = ((vec2(_914, _916) * _901) + ((vec2(-_916, _914) * ((mode > 5.5) ? (-1.0) : 1.0)) * _904)) / vec2(max(length(vec2(_901, _904)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _988 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _991 = length(_988);\n            att = pow(clamp(1.0 - (_991 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _988 / vec2(max(_991, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                vec2 param_1 = -_988;\n                float param_2 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            vec2 param_4 = -_988;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_942, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_853, _864), min(_875, _886))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _449 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _453 = _449.y;\n    return vec2(_449.x, mix(_453, 1.0 - _453, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _494 = base_mode < 0.5;\n    bool _505;\n    if (!_494)\n    {\n        _505 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _505 = _494;\n    }\n    float _506;\n    if (_505)\n    {\n        _506 = shape_half.x;\n    }\n    else\n    {\n        _506 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _506);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _427 = scene_rgb(param);\n    return _427;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _534 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _534.x;\n    s.color.y = _534.y;\n    s.color.z = _534.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1381 = params.x > 31.5;\n    if (_1381)\n    {\n        mode -= 32.0;\n    }\n    float _1389 = mode;\n    bool _1391 = _1389 > 15.5;\n    if (_1391)\n    {\n        mode -= 16.0;\n    }\n    float _1399 = mode;\n    bool _1401 = _1399 > 7.5;\n    if (_1401)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1391)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1391)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1463 = tex_color(param_5);\n                vec4 _1465 = _1463 * color;\n                vec4 param_6 = _1465;\n                float param_7 = mode;\n                float _1472 = _1465.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1472);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1472;\n                    float param_9 = mode;\n                    vec4 _1488 = frag_color;\n                    vec3 _1490 = _1488.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1490.x;\n                    frag_color.y = _1490.y;\n                    frag_color.z = _1490.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1520 = length(uv);\n                    float _1523 = fwidth(_1520);\n                    float _1524 = max(_1523, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1520) / _1524) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1520) / _1524) + 0.5, 0.0, 1.0) * clamp(((_1520 - params.y) / _1524) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1564 = clamp(1.0 - _1520, 0.0, 1.0);\n                            cov = (_1564 * _1564) * (3.0 - (2.0 * _1564));\n                        }\n                    }\n                    vec3 _1573;\n                    if (_1391)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1573 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1573 = color.xyz;\n                    }\n                    frag_color = vec4(_1573, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1628 = fa_tex_fix(param_12, param_13);\n            e *= _1628;\n        }\n        vec4 _1632 = frag_color;\n        vec3 _1634 = _1632.xyz + e;\n        frag_color.x = _1634.x;\n        frag_color.y = _1634.y;\n        frag_color.z = _1634.z;\n    }\n    float param_14 = mode;\n    vec4 _1961 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_1961);\n    fragment(param_15, param_16);\n    _1961 = param_16.color;\n    frag_color = param_16.color;\n    if (_1381)\n    {\n        vec4 _1660 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1665 = scene_rgb(param_17);\n        vec3 _1669 = mix(_1660.xyz, _1665, vec3(color2.w));\n        frag_color.x = _1669.x;\n        frag_color.y = _1669.y;\n        frag_color.z = _1669.z;\n    }\n    if (_1401)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1693 = quad_fs_params[53].w > 0.0;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        vec3 _1715 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1722 = dot(_1715, quad_fs_params[55].xyz);\n        bool _1726 = quad_fs_params[55].w > 0.5;\n        float _1727;\n        if (_1726)\n        {\n            _1727 = _1722;\n        }\n        else\n        {\n            _1727 = length(_1715);\n        }\n        float _1739 = _1727 - quad_fs_params[54].x;\n        if (_1739 > 0.0)\n        {\n            float _1748 = quad_fs_params[53].w * _1739;\n            float tau = _1748 * _1748;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1764;\n                if (_1726)\n                {\n                    _1764 = world_xy.y - (quad_fs_params[55].y * _1722);\n                }\n                else\n                {\n                    _1764 = quad_fs_params[56].y;\n                }\n                float _1785 = mix(_1764, world_xy.y, clamp(quad_fs_params[54].x / _1727, 0.0, 1.0));\n                float _1789 = world_xy.y - _1785;\n                float _1794 = _1785 - quad_fs_params[54].z;\n                float _1799 = world_xy.y - quad_fs_params[54].z;\n                bool _1802 = _1794 <= 0.0;\n                bool _1803 = !_1802;\n                bool _1809;\n                if (_1803)\n                {\n                    _1809 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1809 = _1802;\n                }\n                float _1810;\n                if (_1809)\n                {\n                    _1810 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1810 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1794, 80.0));\n                }\n                bool _1837;\n                if (_1803)\n                {\n                    _1837 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1837 = _1802;\n                }\n                float _1838;\n                if (_1837)\n                {\n                    _1838 = quad_fs_params[54].y * _1794;\n                }\n                else\n                {\n                    _1838 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1794, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1863 = _1799 <= 0.0;\n                bool _1870;\n                if (!_1863)\n                {\n                    _1870 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1870 = _1863;\n                }\n                float _1871;\n                if (_1870)\n                {\n                    _1871 = quad_fs_params[54].y * _1799;\n                }\n                else\n                {\n                    _1871 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1799, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1898;\n                if (abs(_1789) < 0.001000000047497451305389404296875)\n                {\n                    _1898 = _1810;\n                }\n                else\n                {\n                    _1898 = (_1871 - _1838) / _1789;\n                }\n                tau += (_1739 * max(_1898, 0.0));\n            }\n            vec4 _1921 = frag_color;\n            vec3 _1929 = mix(_1921.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1929.x;\n            frag_color.y = _1929.y;\n            frag_color.z = _1929.z;\n        }\n    }\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_443",
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
            "inst_name": "_531",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _169 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _174 = _169.y;\n    return vec2(_169.x, mix(_174, 1.0 - _174, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _229);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _257 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nvoid main()\n{\n    vec4 _284 = texture(tex_smp, uv);\n    vec3 param = _284.xyz;\n    float param_1 = xform.y;\n    vec3 _293 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_293, _284.w) * color;\n    float param_2 = 0.0;\n    vec4 _347 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_347);\n    fragment(param_3, param_4);\n    _347 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
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
