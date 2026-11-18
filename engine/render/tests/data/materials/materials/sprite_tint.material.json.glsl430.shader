{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "dac082249371b076675e61040e0115b7624fdfe0d386fccb444476b7af3a109f",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 2) in vec2 params;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _248 = fa_linear_to_srgb(param);\n        c = _248;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _256 = fa_srgb_to_linear(param_1);\n            c = _256;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _267 = texture(tex_smp, p);\n    vec3 param = _267.xyz;\n    float param_1 = xform.y;\n    vec3 _277 = fa_tex_fix(param, param_1);\n    return vec4(_277, _267.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _90 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_90.x * 255.0) + 0.5) * 256.0) + floor((_90.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _114 = length(d);\n    if (_114 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _128 = atan(d.y, d.x);\n    float a = _128;\n    float _131;\n    if (_128 < 0.0)\n    {\n        _131 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _131 = a;\n    }\n    a = _131;\n    float _143 = _131 * 162.9746551513671875;\n    float _148 = min(floor(_143), 1023.0);\n    float _155 = _148 + 1.0;\n    float i1 = _155;\n    if (_155 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _148;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _114) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _114) + 0.5, 0.0, 1.0), _143 - _148);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _392 = quad_fs_params[0].y > 0.5;\n    if (_392)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _416 = fa_tex_fix(param, param_1);\n        vec3 _420 = (_416 * 2.0) - vec3(1.0);\n        float _427 = cos(params.y);\n        float _429 = sin(params.y);\n        n = normalize(vec3((vec2(_427, _429) * _420.x) + ((vec2(-_429, _427) * ((mode > 5.5) ? (-1.0) : 1.0)) * _420.y), max(_420.z, 0.0500000007450580596923828125)));\n    }\n    bool _463 = !_392;\n    bool _469;\n    if (_463)\n    {\n        _469 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _469 = _463;\n    }\n    vec3 _472;\n    if (_469)\n    {\n        _472 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _472 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _472;\n    bool _489;\n    if (_469)\n    {\n        _489 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _489 = _469;\n    }\n    if (_489)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _608;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _529;\n        if (!_469)\n        {\n            _529 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _529 = _469;\n        }\n        if (_529)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _555 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_555) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _575 = vec3(_555, quad_fs_params[i * 1 + 5].z);\n            l = _575 / vec3(max(length(_575), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_555;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_392)\n        {\n            _608 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _608 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _608));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _294 = fa_srgb_to_linear(param);\n        c = _294;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _637 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _641 = uv * _637;\n    float _647 = _637.x;\n    float _649 = _637.y;\n    float _651 = clamp(shape_rs.x, 0.0, min(_647, _649));\n    vec2 _662 = (abs(_641) - _637) + vec2(_651);\n    float d = (length(max(_662, vec2(0.0))) + min(max(_662.x, _662.y), 0.0)) - _651;\n    float ax = params.y;\n    bool _683 = params.y > 15.0;\n    if (_683)\n    {\n        ax -= 20.0;\n    }\n    float _694;\n    if (ax <= (-1.5))\n    {\n        _694 = (-2.0) - ax;\n    }\n    else\n    {\n        _694 = 0.0;\n    }\n    if (_694 > 0.0)\n    {\n        float _708 = _694 * 0.5;\n        d = abs(d + _708) - _708;\n    }\n    float _716 = fwidth(d);\n    float _717 = max(_716, 9.9999997473787516355514526367188e-05);\n    float _727 = clamp(0.5 - (d / max(shape_rs.y, _717)), 0.0, 1.0);\n    float _732;\n    if (shape_rs.y > _717)\n    {\n        _732 = (_727 * _727) * (3.0 - (2.0 * _727));\n    }\n    else\n    {\n        _732 = _727;\n    }\n    vec4 c = color;\n    bool _754 = (_694 <= 0.0) && (ax > (-0.5));\n    if (_754)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _769 = cos(ax);\n            float _771 = sin(ax);\n            g = ((dot(_641, vec2(_769, _771)) / max((abs(_769) * _647) + (abs(_771) * _649), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_683)\n        {\n            vec4 _814 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _814;\n            vec3 param = _814.xyz;\n            float param_1 = xform.y;\n            vec3 _821 = fa_tex_fix(param, param_1);\n            vec4 _1513 = c;\n            _1513.x = _821.x;\n            _1513.y = _821.y;\n            _1513.z = _821.z;\n            c = _1513;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _833 = scene_rgb(param_2);\n            vec4 _858 = mix(vec4(color.xyz * color.w, color.w), vec4(_833 * color2.w, color2.w), vec4(g));\n            float _860 = _858.w;\n            vec3 _863;\n            if (_860 > 9.9999997473787516355514526367188e-06)\n            {\n                _863 = _858.xyz / vec3(_860);\n            }\n            else\n            {\n                _863 = color.xyz;\n            }\n            c = vec4(_863, _860);\n        }\n    }\n    vec4 _1522 = c;\n    _1522.w = _1522.w * _732;\n    c = _1522;\n    if (_754 || (shape_rs.y > 0.0))\n    {\n        float _904 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _913 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _913 + vec3(_904 * 0.0039215688593685626983642578125);\n            vec3 _919 = fa_srgb_to_linear(param_4);\n            vec4 _1525 = c;\n            _1525.x = _919.x;\n            _1525.y = _919.y;\n            _1525.z = _919.z;\n            c = _1525;\n        }\n        else\n        {\n            vec4 _929 = c;\n            vec3 _932 = _929.xyz + vec3(_904 * 0.0039215688593685626983642578125);\n            vec4 _1532 = _929;\n            _1532.x = _932.x;\n            _1532.y = _932.y;\n            _1532.z = _932.z;\n            c = _1532;\n        }\n        vec4 _1537 = c;\n        _1537.w = clamp(_1537.w + ((_904 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1537.w)), 0.0, 1.0);\n        c = _1537;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _321 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _325 = _321.y;\n    return vec2(_321.x, mix(_325, 1.0 - _325, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _300 = scene_rgb(param);\n    return _300;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _377 = s.color;\n    vec3 _379 = _377.xyz * fa_scene_rgb(param);\n    s.color.x = _379.x;\n    s.color.y = _379.y;\n    s.color.z = _379.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _959 = params.x > 31.5;\n    if (_959)\n    {\n        mode -= 32.0;\n    }\n    float _967 = mode;\n    bool _969 = _967 > 15.5;\n    if (_969)\n    {\n        mode -= 16.0;\n    }\n    float _977 = mode;\n    bool _979 = _977 > 7.5;\n    if (_979)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_969)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_969)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1043 = tex_color(param_5) * color;\n                vec4 param_6 = _1043;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1043.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1079 = length(uv);\n                    float _1082 = fwidth(_1079);\n                    float _1083 = max(_1082, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1079) / _1083) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1079) / _1083) + 0.5, 0.0, 1.0) * clamp(((_1079 - params.y) / _1083) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1124 = clamp(1.0 - _1079, 0.0, 1.0);\n                            cov = (_1124 * _1124) * (3.0 - (2.0 * _1124));\n                        }\n                    }\n                    vec3 _1133;\n                    if (_969)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1133 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1133 = color.xyz;\n                    }\n                    frag_color = vec4(_1133, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(frag_color);\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_959)\n    {\n        vec4 _1170 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1175 = scene_rgb(param_13);\n        vec3 _1179 = mix(_1170.xyz, _1175, vec3(color2.w));\n        frag_color.x = _1179.x;\n        frag_color.y = _1179.y;\n        frag_color.z = _1179.z;\n    }\n    if (_979)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1203 = quad_fs_params[53].w > 0.0;\n    bool _1211;\n    if (!_1203)\n    {\n        _1211 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1211 = _1203;\n    }\n    if (_1211)\n    {\n        vec3 _1225 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1232 = dot(_1225, quad_fs_params[55].xyz);\n        bool _1236 = quad_fs_params[55].w > 0.5;\n        float _1237;\n        if (_1236)\n        {\n            _1237 = _1232;\n        }\n        else\n        {\n            _1237 = length(_1225);\n        }\n        float _1249 = _1237 - quad_fs_params[54].x;\n        if (_1249 > 0.0)\n        {\n            float _1258 = quad_fs_params[53].w * _1249;\n            float tau = _1258 * _1258;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1274;\n                if (_1236)\n                {\n                    _1274 = world_xy.y - (quad_fs_params[55].y * _1232);\n                }\n                else\n                {\n                    _1274 = quad_fs_params[56].y;\n                }\n                float _1295 = mix(_1274, world_xy.y, clamp(quad_fs_params[54].x / _1237, 0.0, 1.0));\n                float _1299 = world_xy.y - _1295;\n                float _1304 = _1295 - quad_fs_params[54].z;\n                float _1309 = world_xy.y - quad_fs_params[54].z;\n                bool _1312 = _1304 <= 0.0;\n                bool _1313 = !_1312;\n                bool _1319;\n                if (_1313)\n                {\n                    _1319 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1319 = _1312;\n                }\n                float _1320;\n                if (_1319)\n                {\n                    _1320 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1320 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1304, 80.0));\n                }\n                bool _1347;\n                if (_1313)\n                {\n                    _1347 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1347 = _1312;\n                }\n                float _1348;\n                if (_1347)\n                {\n                    _1348 = quad_fs_params[54].y * _1304;\n                }\n                else\n                {\n                    _1348 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1304, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1373 = _1309 <= 0.0;\n                bool _1380;\n                if (!_1373)\n                {\n                    _1380 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1380 = _1373;\n                }\n                float _1381;\n                if (_1380)\n                {\n                    _1381 = quad_fs_params[54].y * _1309;\n                }\n                else\n                {\n                    _1381 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1309, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1408;\n                if (abs(_1299) < 0.001000000047497451305389404296875)\n                {\n                    _1408 = _1320;\n                }\n                else\n                {\n                    _1408 = (_1381 - _1348) / _1299;\n                }\n                tau += (_1249 * max(_1408, 0.0));\n            }\n            vec4 _1431 = frag_color;\n            vec3 _1439 = mix(_1431.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1439.x;\n            frag_color.y = _1439.y;\n            frag_color.z = _1439.z;\n        }\n    }\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_314",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
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
            "inst_name": "_370",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _105 = fa_linear_to_srgb(param);\n        c = _105;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _114 = fa_srgb_to_linear(param_1);\n            c = _114;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _158 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _163 = _158.y;\n    return vec2(_158.x, mix(_163, 1.0 - _163, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _130 = fa_srgb_to_linear(param);\n        c = _130;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _136 = scene_rgb(param);\n    return _136;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _217 = s.color;\n    vec3 _219 = _217.xyz * fa_scene_rgb(param);\n    s.color.x = _219.x;\n    s.color.y = _219.y;\n    s.color.z = _219.z;\n}\n\nvoid main()\n{\n    vec4 _238 = texture(tex_smp, uv);\n    vec3 param = _238.xyz;\n    float param_1 = xform.y;\n    vec3 _247 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_247, _238.w) * color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(frag_color);\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_151",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 59,
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
            "inst_name": "_210",
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
