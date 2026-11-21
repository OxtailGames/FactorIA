{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "glsl430",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(binding = 0) uniform sampler2D fa_vs_mask_fa_vs_mask_smp;\n\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (textureLod(fa_vs_mask_fa_vs_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125), 0.0).x * 40.0);\n}\n\nvoid main()\n{\n    vec3 _171 = position;\n    vec2 _172 = texcoord0;\n    vec4 _173 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _108 = fa_srgb_to_linear(param);\n        vec4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex(_171, _172, _173);\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _386 = texture(tex_smp, p);\n    vec3 param = _386.xyz;\n    float param_1 = xform.y;\n    vec3 _396 = fa_tex_fix(param, param_1);\n    return vec4(_396, _386.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _111 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_111.x * 255.0) + 0.5) * 256.0) + floor((_111.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _149 = atan(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0)\n    {\n        _152 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875;\n    float _169 = min(floor(_164), 1023.0);\n    float _176 = _169 + 1.0;\n    float i1 = _176;\n    if (_176 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _135) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _135) + 0.5, 0.0, 1.0), _164 - _169);\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _239 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5;\n    vec2 c = vec2(_243, 0.5 - _239.y);\n    bool _251 = _243 >= 0.0;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    vec2 _271 = c;\n    vec2 _276 = clamp(_271, vec2(0.001953125), vec2(0.998046875));\n    c = _276;\n    return vec3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _541 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _541.xy, 0.0);\n    return cookie_value(param_3) * _541.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _563 = quad_fs_params[0].y > 0.5;\n    if (_563)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _587 = fa_tex_fix(param, param_1);\n        vec3 _591 = (_587 * 2.0) - vec3(1.0);\n        float _598 = cos(params.y);\n        float _600 = sin(params.y);\n        n = normalize(vec3((vec2(_598, _600) * _591.x) + ((vec2(-_600, _598) * ((mode > 5.5) ? (-1.0) : 1.0)) * _591.y), max(_591.z, 0.0500000007450580596923828125)));\n    }\n    bool _633 = !_563;\n    bool _639;\n    if (_633)\n    {\n        _639 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _639 = _633;\n    }\n    vec3 _642;\n    if (_639)\n    {\n        _642 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _642 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _642;\n    bool _659;\n    if (_639)\n    {\n        _659 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _659 = _639;\n    }\n    if (_659)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _783;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _697;\n        if (!_639)\n        {\n            _697 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _697 = _639;\n        }\n        if (_697)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _723 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_723) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _743 = vec3(_723, quad_fs_params[i * 1 + 5].z);\n            l = _743 / vec3(max(length(_743), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_723;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            vec2 param_6 = -_723;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_563)\n        {\n            _783 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _783 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _783));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1029 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1033 = uv * _1029;\n    float _1039 = _1029.x;\n    float _1041 = _1029.y;\n    float _1043 = clamp(shape_rs.x, 0.0, min(_1039, _1041));\n    vec2 _1054 = (abs(_1033) - _1029) + vec2(_1043);\n    float d = (length(max(_1054, vec2(0.0))) + min(max(_1054.x, _1054.y), 0.0)) - _1043;\n    float ax = params.y;\n    bool _1075 = params.y > 15.0;\n    if (_1075)\n    {\n        ax -= 20.0;\n    }\n    float _1086;\n    if (ax <= (-1.5))\n    {\n        _1086 = (-2.0) - ax;\n    }\n    else\n    {\n        _1086 = 0.0;\n    }\n    if (_1086 > 0.0)\n    {\n        float _1100 = _1086 * 0.5;\n        d = abs(d + _1100) - _1100;\n    }\n    float _1108 = fwidth(d);\n    float _1109 = max(_1108, 9.9999997473787516355514526367188e-05);\n    float _1119 = clamp(0.5 - (d / max(shape_rs.y, _1109)), 0.0, 1.0);\n    float _1124;\n    if (shape_rs.y > _1109)\n    {\n        _1124 = (_1119 * _1119) * (3.0 - (2.0 * _1119));\n    }\n    else\n    {\n        _1124 = _1119;\n    }\n    vec4 c = color;\n    bool _1146 = (_1086 <= 0.0) && (ax > (-0.5));\n    if (_1146)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1161 = cos(ax);\n            float _1163 = sin(ax);\n            g = ((dot(_1033, vec2(_1161, _1163)) / max((abs(_1161) * _1039) + (abs(_1163) * _1041), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1075)\n        {\n            vec4 _1206 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1206;\n            vec3 param = _1206.xyz;\n            float param_1 = xform.y;\n            vec3 _1213 = fa_tex_fix(param, param_1);\n            vec4 _2001 = c;\n            _2001.x = _1213.x;\n            _2001.y = _1213.y;\n            _2001.z = _1213.z;\n            c = _2001;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1225 = scene_rgb(param_2);\n            vec4 _1250 = mix(vec4(color.xyz * color.w, color.w), vec4(_1225 * color2.w, color2.w), vec4(g));\n            float _1252 = _1250.w;\n            vec3 _1255;\n            if (_1252 > 9.9999997473787516355514526367188e-06)\n            {\n                _1255 = _1250.xyz / vec3(_1252);\n            }\n            else\n            {\n                _1255 = color.xyz;\n            }\n            c = vec4(_1255, _1252);\n        }\n    }\n    vec4 _2010 = c;\n    _2010.w = _2010.w * _1124;\n    c = _2010;\n    if (_1146 || (shape_rs.y > 0.0))\n    {\n        float _1296 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1305 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1305 + vec3(_1296 * 0.0039215688593685626983642578125);\n            vec3 _1311 = fa_srgb_to_linear(param_4);\n            vec4 _2013 = c;\n            _2013.x = _1311.x;\n            _2013.y = _1311.y;\n            _2013.z = _1311.z;\n            c = _2013;\n        }\n        else\n        {\n            vec4 _1321 = c;\n            vec3 _1324 = _1321.xyz + vec3(_1296 * 0.0039215688593685626983642578125);\n            vec4 _2020 = _1321;\n            _2020.x = _1324.x;\n            _2020.y = _1324.y;\n            _2020.z = _1324.z;\n            c = _2020;\n        }\n        vec4 _2025 = c;\n        _2025.w = clamp(_2025.w + ((_1296 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2025.w)), 0.0, 1.0);\n        c = _2025;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _820 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _822 = texture(tex_smp, uv - _820);\n    float _823 = _822.w;\n    vec4 _833 = texture(tex_smp, uv + _820);\n    float _834 = _833.w;\n    vec2 _842 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _844 = texture(tex_smp, uv - _842);\n    float _845 = _844.w;\n    vec4 _855 = texture(tex_smp, uv + _842);\n    float _856 = _855.w;\n    float _871 = _823 - _834;\n    float _874 = _856 - _845;\n    float _884 = cos(params.y);\n    float _886 = sin(params.y);\n    vec2 _912 = ((vec2(_884, _886) * _871) + ((vec2(-_886, _884) * ((mode > 5.5) ? (-1.0) : 1.0)) * _874)) / vec2(max(length(vec2(_871, _874)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _958 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _961 = length(_958);\n            att = pow(clamp(1.0 - (_961 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _958 / vec2(max(_961, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                vec2 param_1 = -_958;\n                float param_2 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            vec2 param_4 = -_958;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_912, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_823, _834), min(_845, _856))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _435 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _439 = _435.y;\n    return vec2(_435.x, mix(_439, 1.0 - _439, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _480 = base_mode < 0.5;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _492);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _512 = texture(mask_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _512.x;\n    s.color.y = _512.y;\n    s.color.z = _512.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1351 = params.x > 31.5;\n    if (_1351)\n    {\n        mode -= 32.0;\n    }\n    float _1359 = mode;\n    bool _1361 = _1359 > 15.5;\n    if (_1361)\n    {\n        mode -= 16.0;\n    }\n    float _1369 = mode;\n    bool _1371 = _1369 > 7.5;\n    if (_1371)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1361)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1361)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1433 = tex_color(param_5);\n                vec4 _1435 = _1433 * color;\n                vec4 param_6 = _1435;\n                float param_7 = mode;\n                float _1442 = _1435.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1442);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1442;\n                    float param_9 = mode;\n                    vec4 _1458 = frag_color;\n                    vec3 _1460 = _1458.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1460.x;\n                    frag_color.y = _1460.y;\n                    frag_color.z = _1460.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1490 = length(uv);\n                    float _1493 = fwidth(_1490);\n                    float _1494 = max(_1493, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1490) / _1494) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1490) / _1494) + 0.5, 0.0, 1.0) * clamp(((_1490 - params.y) / _1494) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1534 = clamp(1.0 - _1490, 0.0, 1.0);\n                            cov = (_1534 * _1534) * (3.0 - (2.0 * _1534));\n                        }\n                    }\n                    vec3 _1543;\n                    if (_1361)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1543 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1543 = color.xyz;\n                    }\n                    frag_color = vec4(_1543, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1598 = fa_tex_fix(param_12, param_13);\n            e *= _1598;\n        }\n        vec4 _1602 = frag_color;\n        vec3 _1604 = _1602.xyz + e;\n        frag_color.x = _1604.x;\n        frag_color.y = _1604.y;\n        frag_color.z = _1604.z;\n    }\n    float param_14 = mode;\n    vec4 _1931 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_1931);\n    fragment(param_15, param_16);\n    _1931 = param_16.color;\n    frag_color = param_16.color;\n    if (_1351)\n    {\n        vec4 _1630 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1635 = scene_rgb(param_17);\n        vec3 _1639 = mix(_1630.xyz, _1635, vec3(color2.w));\n        frag_color.x = _1639.x;\n        frag_color.y = _1639.y;\n        frag_color.z = _1639.z;\n    }\n    if (_1371)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1663 = quad_fs_params[53].w > 0.0;\n    bool _1671;\n    if (!_1663)\n    {\n        _1671 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1671 = _1663;\n    }\n    if (_1671)\n    {\n        vec3 _1685 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1692 = dot(_1685, quad_fs_params[55].xyz);\n        bool _1696 = quad_fs_params[55].w > 0.5;\n        float _1697;\n        if (_1696)\n        {\n            _1697 = _1692;\n        }\n        else\n        {\n            _1697 = length(_1685);\n        }\n        float _1709 = _1697 - quad_fs_params[54].x;\n        if (_1709 > 0.0)\n        {\n            float _1718 = quad_fs_params[53].w * _1709;\n            float tau = _1718 * _1718;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1734;\n                if (_1696)\n                {\n                    _1734 = world_xy.y - (quad_fs_params[55].y * _1692);\n                }\n                else\n                {\n                    _1734 = quad_fs_params[56].y;\n                }\n                float _1755 = mix(_1734, world_xy.y, clamp(quad_fs_params[54].x / _1697, 0.0, 1.0));\n                float _1759 = world_xy.y - _1755;\n                float _1764 = _1755 - quad_fs_params[54].z;\n                float _1769 = world_xy.y - quad_fs_params[54].z;\n                bool _1772 = _1764 <= 0.0;\n                bool _1773 = !_1772;\n                bool _1779;\n                if (_1773)\n                {\n                    _1779 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1779 = _1772;\n                }\n                float _1780;\n                if (_1779)\n                {\n                    _1780 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1780 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1764, 80.0));\n                }\n                bool _1807;\n                if (_1773)\n                {\n                    _1807 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1807 = _1772;\n                }\n                float _1808;\n                if (_1807)\n                {\n                    _1808 = quad_fs_params[54].y * _1764;\n                }\n                else\n                {\n                    _1808 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1764, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1833 = _1769 <= 0.0;\n                bool _1840;\n                if (!_1833)\n                {\n                    _1840 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1840 = _1833;\n                }\n                float _1841;\n                if (_1840)\n                {\n                    _1841 = quad_fs_params[54].y * _1769;\n                }\n                else\n                {\n                    _1841 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1769, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1868;\n                if (abs(_1759) < 0.001000000047497451305389404296875)\n                {\n                    _1868 = _1780;\n                }\n                else\n                {\n                    _1868 = (_1841 - _1808) / _1759;\n                }\n                tau += (_1709 * max(_1868, 0.0));\n            }\n            vec4 _1891 = frag_color;\n            vec3 _1899 = mix(_1891.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1899.x;\n            frag_color.y = _1899.y;\n            frag_color.z = _1899.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_96",
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
            "inst_name": "_429",
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
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
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering"
          },
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7,
            "glsl_name": "fa_vs_mask_fa_vs_mask_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "tex_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0,
            "glsl_name": "normal_tex_smp"
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
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(binding = 0) uniform sampler2D fa_vs_mask_fa_vs_mask_smp;\n\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (textureLod(fa_vs_mask_fa_vs_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125), 0.0).x * 40.0);\n}\n\nvoid main()\n{\n    vec3 _171 = position;\n    vec2 _172 = texcoord0;\n    vec4 _173 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _108 = fa_srgb_to_linear(param);\n        vec4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex(_171, _172, _173);\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _224 = texture(mask_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _224.x;\n    s.color.y = _224.y;\n    s.color.z = _224.z;\n}\n\nvoid main()\n{\n    vec4 _239 = texture(tex_smp, uv);\n    vec3 param = _239.xyz;\n    float param_1 = xform.y;\n    vec3 _250 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_250, _239.w) * color;\n    float param_2 = 0.0;\n    vec4 _304 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_304);\n    fragment(param_3, param_4);\n    _304 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_96",
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
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering"
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7,
            "glsl_name": "fa_vs_mask_fa_vs_mask_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "tex_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    }
  }
}
