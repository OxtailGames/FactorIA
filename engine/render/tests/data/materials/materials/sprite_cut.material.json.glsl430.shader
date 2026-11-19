{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _411 = quad_fs_params[0].y > 0.5;\n    if (_411)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _435 = fa_tex_fix(param, param_1);\n        vec3 _439 = (_435 * 2.0) - vec3(1.0);\n        float _446 = cos(params.y);\n        float _448 = sin(params.y);\n        n = normalize(vec3((vec2(_446, _448) * _439.x) + ((vec2(-_448, _446) * ((mode > 5.5) ? (-1.0) : 1.0)) * _439.y), max(_439.z, 0.0500000007450580596923828125)));\n    }\n    bool _482 = !_411;\n    bool _488;\n    if (_482)\n    {\n        _488 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _488 = _482;\n    }\n    vec3 _491;\n    if (_488)\n    {\n        _491 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _491 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _491;\n    bool _508;\n    if (_488)\n    {\n        _508 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _508 = _488;\n    }\n    if (_508)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _626;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _548;\n        if (!_488)\n        {\n            _548 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _548 = _488;\n        }\n        if (_548)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _574 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_574) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _594 = vec3(_574, quad_fs_params[i * 1 + 5].z);\n            l = _594 / vec3(max(length(_594), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_574;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_411)\n        {\n            _626 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _626 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _626));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _654 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _658 = uv * _654;\n    float _664 = _654.x;\n    float _666 = _654.y;\n    float _668 = clamp(shape_rs.x, 0.0, min(_664, _666));\n    vec2 _679 = (abs(_658) - _654) + vec2(_668);\n    float d = (length(max(_679, vec2(0.0))) + min(max(_679.x, _679.y), 0.0)) - _668;\n    float ax = params.y;\n    bool _700 = params.y > 15.0;\n    if (_700)\n    {\n        ax -= 20.0;\n    }\n    float _711;\n    if (ax <= (-1.5))\n    {\n        _711 = (-2.0) - ax;\n    }\n    else\n    {\n        _711 = 0.0;\n    }\n    if (_711 > 0.0)\n    {\n        float _725 = _711 * 0.5;\n        d = abs(d + _725) - _725;\n    }\n    float _733 = fwidth(d);\n    float _734 = max(_733, 9.9999997473787516355514526367188e-05);\n    float _744 = clamp(0.5 - (d / max(shape_rs.y, _734)), 0.0, 1.0);\n    float _749;\n    if (shape_rs.y > _734)\n    {\n        _749 = (_744 * _744) * (3.0 - (2.0 * _744));\n    }\n    else\n    {\n        _749 = _744;\n    }\n    vec4 c = color;\n    bool _771 = (_711 <= 0.0) && (ax > (-0.5));\n    if (_771)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _786 = cos(ax);\n            float _788 = sin(ax);\n            g = ((dot(_658, vec2(_786, _788)) / max((abs(_786) * _664) + (abs(_788) * _666), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_700)\n        {\n            vec4 _831 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _831;\n            vec3 param = _831.xyz;\n            float param_1 = xform.y;\n            vec3 _838 = fa_tex_fix(param, param_1);\n            vec4 _1534 = c;\n            _1534.x = _838.x;\n            _1534.y = _838.y;\n            _1534.z = _838.z;\n            c = _1534;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _850 = scene_rgb(param_2);\n            vec4 _875 = mix(vec4(color.xyz * color.w, color.w), vec4(_850 * color2.w, color2.w), vec4(g));\n            float _877 = _875.w;\n            vec3 _880;\n            if (_877 > 9.9999997473787516355514526367188e-06)\n            {\n                _880 = _875.xyz / vec3(_877);\n            }\n            else\n            {\n                _880 = color.xyz;\n            }\n            c = vec4(_880, _877);\n        }\n    }\n    vec4 _1543 = c;\n    _1543.w = _1543.w * _749;\n    c = _1543;\n    if (_771 || (shape_rs.y > 0.0))\n    {\n        float _921 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _930 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _930 + vec3(_921 * 0.0039215688593685626983642578125);\n            vec3 _936 = fa_srgb_to_linear(param_4);\n            vec4 _1546 = c;\n            _1546.x = _936.x;\n            _1546.y = _936.y;\n            _1546.z = _936.z;\n            c = _1546;\n        }\n        else\n        {\n            vec4 _946 = c;\n            vec3 _949 = _946.xyz + vec3(_921 * 0.0039215688593685626983642578125);\n            vec4 _1553 = _946;\n            _1553.x = _949.x;\n            _1553.y = _949.y;\n            _1553.z = _949.z;\n            c = _1553;\n        }\n        vec4 _1558 = c;\n        _1558.w = clamp(_1558.w + ((_921 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1558.w)), 0.0, 1.0);\n        c = _1558;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _315 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _319 = _315.y;\n    return vec2(_315.x, mix(_319, 1.0 - _319, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _361 = base_mode < 0.5;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _373);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _392 = i.screen_uv.x < fa_material[0].x;\n    bool _401;\n    if (!_392)\n    {\n        _401 = i.screen_uv.y < fa_material[1].x;\n    }\n    else\n    {\n        _401 = _392;\n    }\n    if (_401)\n    {\n        discard;\n    }\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _976 = params.x > 31.5;\n    if (_976)\n    {\n        mode -= 32.0;\n    }\n    float _984 = mode;\n    bool _986 = _984 > 15.5;\n    if (_986)\n    {\n        mode -= 16.0;\n    }\n    float _994 = mode;\n    bool _996 = _994 > 7.5;\n    if (_996)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_986)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_986)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1060 = tex_color(param_5) * color;\n                vec4 param_6 = _1060;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1060.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1095 = length(uv);\n                    float _1098 = fwidth(_1095);\n                    float _1099 = max(_1098, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1095) / _1099) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1095) / _1099) + 0.5, 0.0, 1.0) * clamp(((_1095 - params.y) / _1099) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1139 = clamp(1.0 - _1095, 0.0, 1.0);\n                            cov = (_1139 * _1139) * (3.0 - (2.0 * _1139));\n                        }\n                    }\n                    vec3 _1148;\n                    if (_986)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1148 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1148 = color.xyz;\n                    }\n                    frag_color = vec4(_1148, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1487 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1487);\n    fragment(param_11, param_12);\n    _1487 = param_12.color;\n    frag_color = param_12.color;\n    if (_976)\n    {\n        vec4 _1186 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1191 = scene_rgb(param_13);\n        vec3 _1195 = mix(_1186.xyz, _1191, vec3(color2.w));\n        frag_color.x = _1195.x;\n        frag_color.y = _1195.y;\n        frag_color.z = _1195.z;\n    }\n    if (_996)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1219 = quad_fs_params[53].w > 0.0;\n    bool _1227;\n    if (!_1219)\n    {\n        _1227 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1227 = _1219;\n    }\n    if (_1227)\n    {\n        vec3 _1241 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1248 = dot(_1241, quad_fs_params[55].xyz);\n        bool _1252 = quad_fs_params[55].w > 0.5;\n        float _1253;\n        if (_1252)\n        {\n            _1253 = _1248;\n        }\n        else\n        {\n            _1253 = length(_1241);\n        }\n        float _1265 = _1253 - quad_fs_params[54].x;\n        if (_1265 > 0.0)\n        {\n            float _1274 = quad_fs_params[53].w * _1265;\n            float tau = _1274 * _1274;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1290;\n                if (_1252)\n                {\n                    _1290 = world_xy.y - (quad_fs_params[55].y * _1248);\n                }\n                else\n                {\n                    _1290 = quad_fs_params[56].y;\n                }\n                float _1311 = mix(_1290, world_xy.y, clamp(quad_fs_params[54].x / _1253, 0.0, 1.0));\n                float _1315 = world_xy.y - _1311;\n                float _1320 = _1311 - quad_fs_params[54].z;\n                float _1325 = world_xy.y - quad_fs_params[54].z;\n                bool _1328 = _1320 <= 0.0;\n                bool _1329 = !_1328;\n                bool _1335;\n                if (_1329)\n                {\n                    _1335 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1335 = _1328;\n                }\n                float _1336;\n                if (_1335)\n                {\n                    _1336 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1336 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1320, 80.0));\n                }\n                bool _1363;\n                if (_1329)\n                {\n                    _1363 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1363 = _1328;\n                }\n                float _1364;\n                if (_1363)\n                {\n                    _1364 = quad_fs_params[54].y * _1320;\n                }\n                else\n                {\n                    _1364 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1320, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1389 = _1325 <= 0.0;\n                bool _1396;\n                if (!_1389)\n                {\n                    _1396 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1396 = _1389;\n                }\n                float _1397;\n                if (_1396)\n                {\n                    _1397 = quad_fs_params[54].y * _1325;\n                }\n                else\n                {\n                    _1397 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1325, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1424;\n                if (abs(_1315) < 0.001000000047497451305389404296875)\n                {\n                    _1424 = _1336;\n                }\n                else\n                {\n                    _1424 = (_1397 - _1364) / _1315;\n                }\n                tau += (_1265 * max(_1424, 0.0));\n            }\n            vec4 _1447 = frag_color;\n            vec3 _1455 = mix(_1447.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1455.x;\n            frag_color.y = _1455.y;\n            frag_color.z = _1455.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_308",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_389",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _216 = i.screen_uv.x < fa_material[0].x;\n    bool _225;\n    if (!_216)\n    {\n        _225 = i.screen_uv.y < fa_material[1].x;\n    }\n    else\n    {\n        _225 = _216;\n    }\n    if (_225)\n    {\n        discard;\n    }\n}\n\nvoid main()\n{\n    vec4 _241 = texture(tex_smp, uv);\n    vec3 param = _241.xyz;\n    float param_1 = xform.y;\n    vec3 _252 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_252, _241.w) * color;\n    float param_2 = 0.0;\n    vec4 _306 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_306);\n    fragment(param_3, param_4);\n    _306 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_127",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_213",
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
