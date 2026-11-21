{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _386 = texture(tex_smp, p);\n    vec3 param = _386.xyz;\n    float param_1 = xform.y;\n    vec3 _396 = fa_tex_fix(param, param_1);\n    return vec4(_396, _386.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _111 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_111.x * 255.0) + 0.5) * 256.0) + floor((_111.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _149 = atan(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0)\n    {\n        _152 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875;\n    float _169 = min(floor(_164), 1023.0);\n    float _176 = _169 + 1.0;\n    float i1 = _176;\n    if (_176 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _135) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _135) + 0.5, 0.0, 1.0), _164 - _169);\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _239 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5;\n    vec2 c = vec2(_243, 0.5 - _239.y);\n    bool _251 = _243 >= 0.0;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    vec2 _271 = c;\n    vec2 _276 = clamp(_271, vec2(0.001953125), vec2(0.998046875));\n    c = _276;\n    return vec3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _534 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _534.xy, 0.0);\n    return cookie_value(param_3) * _534.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _556 = quad_fs_params[0].y > 0.5;\n    if (_556)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _580 = fa_tex_fix(param, param_1);\n        vec3 _584 = (_580 * 2.0) - vec3(1.0);\n        float _591 = cos(params.y);\n        float _593 = sin(params.y);\n        n = normalize(vec3((vec2(_591, _593) * _584.x) + ((vec2(-_593, _591) * ((mode > 5.5) ? (-1.0) : 1.0)) * _584.y), max(_584.z, 0.0500000007450580596923828125)));\n    }\n    bool _627 = !_556;\n    bool _633;\n    if (_627)\n    {\n        _633 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _633 = _627;\n    }\n    vec3 _636;\n    if (_633)\n    {\n        _636 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _636 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _636;\n    bool _653;\n    if (_633)\n    {\n        _653 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _653 = _633;\n    }\n    if (_653)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _777;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _691;\n        if (!_633)\n        {\n            _691 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _691 = _633;\n        }\n        if (_691)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _717 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_717) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _737 = vec3(_717, quad_fs_params[i * 1 + 5].z);\n            l = _737 / vec3(max(length(_737), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_717;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            vec2 param_6 = -_717;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_556)\n        {\n            _777 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _777 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _777));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1023 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1027 = uv * _1023;\n    float _1033 = _1023.x;\n    float _1035 = _1023.y;\n    float _1037 = clamp(shape_rs.x, 0.0, min(_1033, _1035));\n    vec2 _1048 = (abs(_1027) - _1023) + vec2(_1037);\n    float d = (length(max(_1048, vec2(0.0))) + min(max(_1048.x, _1048.y), 0.0)) - _1037;\n    float ax = params.y;\n    bool _1069 = params.y > 15.0;\n    if (_1069)\n    {\n        ax -= 20.0;\n    }\n    float _1080;\n    if (ax <= (-1.5))\n    {\n        _1080 = (-2.0) - ax;\n    }\n    else\n    {\n        _1080 = 0.0;\n    }\n    if (_1080 > 0.0)\n    {\n        float _1094 = _1080 * 0.5;\n        d = abs(d + _1094) - _1094;\n    }\n    float _1102 = fwidth(d);\n    float _1103 = max(_1102, 9.9999997473787516355514526367188e-05);\n    float _1113 = clamp(0.5 - (d / max(shape_rs.y, _1103)), 0.0, 1.0);\n    float _1118;\n    if (shape_rs.y > _1103)\n    {\n        _1118 = (_1113 * _1113) * (3.0 - (2.0 * _1113));\n    }\n    else\n    {\n        _1118 = _1113;\n    }\n    vec4 c = color;\n    bool _1140 = (_1080 <= 0.0) && (ax > (-0.5));\n    if (_1140)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1155 = cos(ax);\n            float _1157 = sin(ax);\n            g = ((dot(_1027, vec2(_1155, _1157)) / max((abs(_1155) * _1033) + (abs(_1157) * _1035), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1069)\n        {\n            vec4 _1200 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1200;\n            vec3 param = _1200.xyz;\n            float param_1 = xform.y;\n            vec3 _1207 = fa_tex_fix(param, param_1);\n            vec4 _1995 = c;\n            _1995.x = _1207.x;\n            _1995.y = _1207.y;\n            _1995.z = _1207.z;\n            c = _1995;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1219 = scene_rgb(param_2);\n            vec4 _1244 = mix(vec4(color.xyz * color.w, color.w), vec4(_1219 * color2.w, color2.w), vec4(g));\n            float _1246 = _1244.w;\n            vec3 _1249;\n            if (_1246 > 9.9999997473787516355514526367188e-06)\n            {\n                _1249 = _1244.xyz / vec3(_1246);\n            }\n            else\n            {\n                _1249 = color.xyz;\n            }\n            c = vec4(_1249, _1246);\n        }\n    }\n    vec4 _2004 = c;\n    _2004.w = _2004.w * _1118;\n    c = _2004;\n    if (_1140 || (shape_rs.y > 0.0))\n    {\n        float _1290 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1299 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1299 + vec3(_1290 * 0.0039215688593685626983642578125);\n            vec3 _1305 = fa_srgb_to_linear(param_4);\n            vec4 _2007 = c;\n            _2007.x = _1305.x;\n            _2007.y = _1305.y;\n            _2007.z = _1305.z;\n            c = _2007;\n        }\n        else\n        {\n            vec4 _1315 = c;\n            vec3 _1318 = _1315.xyz + vec3(_1290 * 0.0039215688593685626983642578125);\n            vec4 _2014 = _1315;\n            _2014.x = _1318.x;\n            _2014.y = _1318.y;\n            _2014.z = _1318.z;\n            c = _2014;\n        }\n        vec4 _2019 = c;\n        _2019.w = clamp(_2019.w + ((_1290 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2019.w)), 0.0, 1.0);\n        c = _2019;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _814 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _816 = texture(tex_smp, uv - _814);\n    float _817 = _816.w;\n    vec4 _827 = texture(tex_smp, uv + _814);\n    float _828 = _827.w;\n    vec2 _836 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _838 = texture(tex_smp, uv - _836);\n    float _839 = _838.w;\n    vec4 _849 = texture(tex_smp, uv + _836);\n    float _850 = _849.w;\n    float _865 = _817 - _828;\n    float _868 = _850 - _839;\n    float _878 = cos(params.y);\n    float _880 = sin(params.y);\n    vec2 _906 = ((vec2(_878, _880) * _865) + ((vec2(-_880, _878) * ((mode > 5.5) ? (-1.0) : 1.0)) * _868)) / vec2(max(length(vec2(_865, _868)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _952 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _955 = length(_952);\n            att = pow(clamp(1.0 - (_955 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _952 / vec2(max(_955, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                vec2 param_1 = -_952;\n                float param_2 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            vec2 param_4 = -_952;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_906, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_817, _828), min(_839, _850))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _435 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _439 = _435.y;\n    return vec2(_435.x, mix(_439, 1.0 - _439, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _480 = base_mode < 0.5;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _492);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1345 = params.x > 31.5;\n    if (_1345)\n    {\n        mode -= 32.0;\n    }\n    float _1353 = mode;\n    bool _1355 = _1353 > 15.5;\n    if (_1355)\n    {\n        mode -= 16.0;\n    }\n    float _1363 = mode;\n    bool _1365 = _1363 > 7.5;\n    if (_1365)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1355)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1355)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1427 = tex_color(param_5);\n                vec4 _1429 = _1427 * color;\n                vec4 param_6 = _1429;\n                float param_7 = mode;\n                float _1436 = _1429.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1436);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1436;\n                    float param_9 = mode;\n                    vec4 _1452 = frag_color;\n                    vec3 _1454 = _1452.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1454.x;\n                    frag_color.y = _1454.y;\n                    frag_color.z = _1454.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1484 = length(uv);\n                    float _1487 = fwidth(_1484);\n                    float _1488 = max(_1487, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1484) / _1488) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1484) / _1488) + 0.5, 0.0, 1.0) * clamp(((_1484 - params.y) / _1488) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1528 = clamp(1.0 - _1484, 0.0, 1.0);\n                            cov = (_1528 * _1528) * (3.0 - (2.0 * _1528));\n                        }\n                    }\n                    vec3 _1537;\n                    if (_1355)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1537 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1537 = color.xyz;\n                    }\n                    frag_color = vec4(_1537, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1592 = fa_tex_fix(param_12, param_13);\n            e *= _1592;\n        }\n        vec4 _1596 = frag_color;\n        vec3 _1598 = _1596.xyz + e;\n        frag_color.x = _1598.x;\n        frag_color.y = _1598.y;\n        frag_color.z = _1598.z;\n    }\n    float param_14 = mode;\n    vec4 _1925 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_1925);\n    fragment(param_15, param_16);\n    _1925 = param_16.color;\n    frag_color = param_16.color;\n    if (_1345)\n    {\n        vec4 _1624 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1629 = scene_rgb(param_17);\n        vec3 _1633 = mix(_1624.xyz, _1629, vec3(color2.w));\n        frag_color.x = _1633.x;\n        frag_color.y = _1633.y;\n        frag_color.z = _1633.z;\n    }\n    if (_1365)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1657 = quad_fs_params[53].w > 0.0;\n    bool _1665;\n    if (!_1657)\n    {\n        _1665 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1665 = _1657;\n    }\n    if (_1665)\n    {\n        vec3 _1679 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1686 = dot(_1679, quad_fs_params[55].xyz);\n        bool _1690 = quad_fs_params[55].w > 0.5;\n        float _1691;\n        if (_1690)\n        {\n            _1691 = _1686;\n        }\n        else\n        {\n            _1691 = length(_1679);\n        }\n        float _1703 = _1691 - quad_fs_params[54].x;\n        if (_1703 > 0.0)\n        {\n            float _1712 = quad_fs_params[53].w * _1703;\n            float tau = _1712 * _1712;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1728;\n                if (_1690)\n                {\n                    _1728 = world_xy.y - (quad_fs_params[55].y * _1686);\n                }\n                else\n                {\n                    _1728 = quad_fs_params[56].y;\n                }\n                float _1749 = mix(_1728, world_xy.y, clamp(quad_fs_params[54].x / _1691, 0.0, 1.0));\n                float _1753 = world_xy.y - _1749;\n                float _1758 = _1749 - quad_fs_params[54].z;\n                float _1763 = world_xy.y - quad_fs_params[54].z;\n                bool _1766 = _1758 <= 0.0;\n                bool _1767 = !_1766;\n                bool _1773;\n                if (_1767)\n                {\n                    _1773 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1773 = _1766;\n                }\n                float _1774;\n                if (_1773)\n                {\n                    _1774 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1774 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1758, 80.0));\n                }\n                bool _1801;\n                if (_1767)\n                {\n                    _1801 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1801 = _1766;\n                }\n                float _1802;\n                if (_1801)\n                {\n                    _1802 = quad_fs_params[54].y * _1758;\n                }\n                else\n                {\n                    _1802 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1758, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1827 = _1763 <= 0.0;\n                bool _1834;\n                if (!_1827)\n                {\n                    _1834 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1834 = _1827;\n                }\n                float _1835;\n                if (_1834)\n                {\n                    _1835 = quad_fs_params[54].y * _1763;\n                }\n                else\n                {\n                    _1835 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1763, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1862;\n                if (abs(_1753) < 0.001000000047497451305389404296875)\n                {\n                    _1862 = _1774;\n                }\n                else\n                {\n                    _1862 = (_1835 - _1802) / _1753;\n                }\n                tau += (_1703 * max(_1862, 0.0));\n            }\n            vec4 _1885 = frag_color;\n            vec3 _1893 = mix(_1885.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1893.x;\n            frag_color.y = _1893.y;\n            frag_color.z = _1893.z;\n        }\n    }\n}\n\n",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    vec4 _232 = texture(tex_smp, uv);\n    vec3 param = _232.xyz;\n    float param_1 = xform.y;\n    vec3 _243 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_243, _232.w) * color;\n    float param_2 = 0.0;\n    vec4 _297 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_297);\n    fragment(param_3, param_4);\n    _297 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
