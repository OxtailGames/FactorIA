{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "2079829332065ce3783c961c08db454e84df9f84c8284a005fa67df5d2d143e6",
  "slang": "glsl430",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(binding = 0) uniform sampler2D fa_vs_mask_fa_vs_mask_smp;\n\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (textureLod(fa_vs_mask_fa_vs_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125), 0.0).x * 40.0);\n}\n\nvoid main()\n{\n    vec3 _171 = position;\n    vec2 _172 = texcoord0;\n    vec4 _173 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _108 = fa_srgb_to_linear(param);\n        vec4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex(_171, _172, _173);\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _407 = quad_fs_params[0].y > 0.5;\n    if (_407)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _431 = fa_tex_fix(param, param_1);\n        vec3 _435 = (_431 * 2.0) - vec3(1.0);\n        float _442 = cos(params.y);\n        float _444 = sin(params.y);\n        n = normalize(vec3((vec2(_442, _444) * _435.x) + ((vec2(-_444, _442) * ((mode > 5.5) ? (-1.0) : 1.0)) * _435.y), max(_435.z, 0.0500000007450580596923828125)));\n    }\n    bool _477 = !_407;\n    bool _483;\n    if (_477)\n    {\n        _483 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _483 = _477;\n    }\n    vec3 _486;\n    if (_483)\n    {\n        _486 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _486 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _486;\n    bool _503;\n    if (_483)\n    {\n        _503 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _503 = _483;\n    }\n    if (_503)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _621;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _543;\n        if (!_483)\n        {\n            _543 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _543 = _483;\n        }\n        if (_543)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _569 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_569) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _589 = vec3(_569, quad_fs_params[i * 1 + 5].z);\n            l = _589 / vec3(max(length(_589), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_569;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_407)\n        {\n            _621 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _621 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _621));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _649 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _653 = uv * _649;\n    float _659 = _649.x;\n    float _661 = _649.y;\n    float _663 = clamp(shape_rs.x, 0.0, min(_659, _661));\n    vec2 _674 = (abs(_653) - _649) + vec2(_663);\n    float d = (length(max(_674, vec2(0.0))) + min(max(_674.x, _674.y), 0.0)) - _663;\n    float ax = params.y;\n    bool _695 = params.y > 15.0;\n    if (_695)\n    {\n        ax -= 20.0;\n    }\n    float _706;\n    if (ax <= (-1.5))\n    {\n        _706 = (-2.0) - ax;\n    }\n    else\n    {\n        _706 = 0.0;\n    }\n    if (_706 > 0.0)\n    {\n        float _720 = _706 * 0.5;\n        d = abs(d + _720) - _720;\n    }\n    float _728 = fwidth(d);\n    float _729 = max(_728, 9.9999997473787516355514526367188e-05);\n    float _739 = clamp(0.5 - (d / max(shape_rs.y, _729)), 0.0, 1.0);\n    float _744;\n    if (shape_rs.y > _729)\n    {\n        _744 = (_739 * _739) * (3.0 - (2.0 * _739));\n    }\n    else\n    {\n        _744 = _739;\n    }\n    vec4 c = color;\n    bool _766 = (_706 <= 0.0) && (ax > (-0.5));\n    if (_766)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _781 = cos(ax);\n            float _783 = sin(ax);\n            g = ((dot(_653, vec2(_781, _783)) / max((abs(_781) * _659) + (abs(_783) * _661), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_695)\n        {\n            vec4 _826 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _826;\n            vec3 param = _826.xyz;\n            float param_1 = xform.y;\n            vec3 _833 = fa_tex_fix(param, param_1);\n            vec4 _1529 = c;\n            _1529.x = _833.x;\n            _1529.y = _833.y;\n            _1529.z = _833.z;\n            c = _1529;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _845 = scene_rgb(param_2);\n            vec4 _870 = mix(vec4(color.xyz * color.w, color.w), vec4(_845 * color2.w, color2.w), vec4(g));\n            float _872 = _870.w;\n            vec3 _875;\n            if (_872 > 9.9999997473787516355514526367188e-06)\n            {\n                _875 = _870.xyz / vec3(_872);\n            }\n            else\n            {\n                _875 = color.xyz;\n            }\n            c = vec4(_875, _872);\n        }\n    }\n    vec4 _1538 = c;\n    _1538.w = _1538.w * _744;\n    c = _1538;\n    if (_766 || (shape_rs.y > 0.0))\n    {\n        float _916 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _925 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _925 + vec3(_916 * 0.0039215688593685626983642578125);\n            vec3 _931 = fa_srgb_to_linear(param_4);\n            vec4 _1541 = c;\n            _1541.x = _931.x;\n            _1541.y = _931.y;\n            _1541.z = _931.z;\n            c = _1541;\n        }\n        else\n        {\n            vec4 _941 = c;\n            vec3 _944 = _941.xyz + vec3(_916 * 0.0039215688593685626983642578125);\n            vec4 _1548 = _941;\n            _1548.x = _944.x;\n            _1548.y = _944.y;\n            _1548.z = _944.z;\n            c = _1548;\n        }\n        vec4 _1553 = c;\n        _1553.w = clamp(_1553.w + ((_916 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1553.w)), 0.0, 1.0);\n        c = _1553;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _315 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _319 = _315.y;\n    return vec2(_315.x, mix(_319, 1.0 - _319, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _361 = base_mode < 0.5;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _373);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _393 = texture(mask_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _393.x;\n    s.color.y = _393.y;\n    s.color.z = _393.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _971 = params.x > 31.5;\n    if (_971)\n    {\n        mode -= 32.0;\n    }\n    float _979 = mode;\n    bool _981 = _979 > 15.5;\n    if (_981)\n    {\n        mode -= 16.0;\n    }\n    float _989 = mode;\n    bool _991 = _989 > 7.5;\n    if (_991)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_981)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_981)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1055 = tex_color(param_5) * color;\n                vec4 param_6 = _1055;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1055.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1090 = length(uv);\n                    float _1093 = fwidth(_1090);\n                    float _1094 = max(_1093, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1090) / _1094) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1090) / _1094) + 0.5, 0.0, 1.0) * clamp(((_1090 - params.y) / _1094) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1134 = clamp(1.0 - _1090, 0.0, 1.0);\n                            cov = (_1134 * _1134) * (3.0 - (2.0 * _1134));\n                        }\n                    }\n                    vec3 _1143;\n                    if (_981)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1143 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1143 = color.xyz;\n                    }\n                    frag_color = vec4(_1143, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1482 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1482);\n    fragment(param_11, param_12);\n    _1482 = param_12.color;\n    frag_color = param_12.color;\n    if (_971)\n    {\n        vec4 _1181 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1186 = scene_rgb(param_13);\n        vec3 _1190 = mix(_1181.xyz, _1186, vec3(color2.w));\n        frag_color.x = _1190.x;\n        frag_color.y = _1190.y;\n        frag_color.z = _1190.z;\n    }\n    if (_991)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1214 = quad_fs_params[53].w > 0.0;\n    bool _1222;\n    if (!_1214)\n    {\n        _1222 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1222 = _1214;\n    }\n    if (_1222)\n    {\n        vec3 _1236 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1243 = dot(_1236, quad_fs_params[55].xyz);\n        bool _1247 = quad_fs_params[55].w > 0.5;\n        float _1248;\n        if (_1247)\n        {\n            _1248 = _1243;\n        }\n        else\n        {\n            _1248 = length(_1236);\n        }\n        float _1260 = _1248 - quad_fs_params[54].x;\n        if (_1260 > 0.0)\n        {\n            float _1269 = quad_fs_params[53].w * _1260;\n            float tau = _1269 * _1269;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1285;\n                if (_1247)\n                {\n                    _1285 = world_xy.y - (quad_fs_params[55].y * _1243);\n                }\n                else\n                {\n                    _1285 = quad_fs_params[56].y;\n                }\n                float _1306 = mix(_1285, world_xy.y, clamp(quad_fs_params[54].x / _1248, 0.0, 1.0));\n                float _1310 = world_xy.y - _1306;\n                float _1315 = _1306 - quad_fs_params[54].z;\n                float _1320 = world_xy.y - quad_fs_params[54].z;\n                bool _1323 = _1315 <= 0.0;\n                bool _1324 = !_1323;\n                bool _1330;\n                if (_1324)\n                {\n                    _1330 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1330 = _1323;\n                }\n                float _1331;\n                if (_1330)\n                {\n                    _1331 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1331 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1315, 80.0));\n                }\n                bool _1358;\n                if (_1324)\n                {\n                    _1358 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1358 = _1323;\n                }\n                float _1359;\n                if (_1358)\n                {\n                    _1359 = quad_fs_params[54].y * _1315;\n                }\n                else\n                {\n                    _1359 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1315, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1384 = _1320 <= 0.0;\n                bool _1391;\n                if (!_1384)\n                {\n                    _1391 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1391 = _1384;\n                }\n                float _1392;\n                if (_1391)\n                {\n                    _1392 = quad_fs_params[54].y * _1320;\n                }\n                else\n                {\n                    _1392 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1320, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1419;\n                if (abs(_1310) < 0.001000000047497451305389404296875)\n                {\n                    _1419 = _1331;\n                }\n                else\n                {\n                    _1419 = (_1392 - _1359) / _1310;\n                }\n                tau += (_1260 * max(_1419, 0.0));\n            }\n            vec4 _1442 = frag_color;\n            vec3 _1450 = mix(_1442.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1450.x;\n            frag_color.y = _1450.y;\n            frag_color.z = _1450.z;\n        }\n    }\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_308",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _222 = texture(mask_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _222.x;\n    s.color.y = _222.y;\n    s.color.z = _222.z;\n}\n\nvoid main()\n{\n    vec4 _237 = texture(tex_smp, uv);\n    vec3 param = _237.xyz;\n    float param_1 = xform.y;\n    vec3 _248 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_248, _237.w) * color;\n    float param_2 = 0.0;\n    vec4 _302 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_302);\n    fragment(param_3, param_4);\n    _302 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
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
