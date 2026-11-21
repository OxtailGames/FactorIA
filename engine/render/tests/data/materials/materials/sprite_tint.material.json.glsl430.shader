{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _269 = texture(tex_smp, p);\n    vec3 param = _269.xyz;\n    float param_1 = xform.y;\n    vec3 _279 = fa_tex_fix(param, param_1);\n    return vec4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _92 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = atan(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _417 = quad_fs_params[0].y > 0.5;\n    if (_417)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _441 = fa_tex_fix(param, param_1);\n        vec3 _445 = (_441 * 2.0) - vec3(1.0);\n        float _452 = cos(params.y);\n        float _454 = sin(params.y);\n        n = normalize(vec3((vec2(_452, _454) * _445.x) + ((vec2(-_454, _452) * ((mode > 5.5) ? (-1.0) : 1.0)) * _445.y), max(_445.z, 0.0500000007450580596923828125)));\n    }\n    bool _488 = !_417;\n    bool _494;\n    if (_488)\n    {\n        _494 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _494 = _488;\n    }\n    vec3 _497;\n    if (_494)\n    {\n        _497 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _497 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _497;\n    bool _514;\n    if (_494)\n    {\n        _514 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _514 = _494;\n    }\n    if (_514)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _632;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _554;\n        if (!_494)\n        {\n            _554 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _554 = _494;\n        }\n        if (_554)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _580 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_580) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _600 = vec3(_580, quad_fs_params[i * 1 + 5].z);\n            l = _600 / vec3(max(length(_600), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_580;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_417)\n        {\n            _632 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _632 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _632));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _660 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _664 = uv * _660;\n    float _670 = _660.x;\n    float _672 = _660.y;\n    float _674 = clamp(shape_rs.x, 0.0, min(_670, _672));\n    vec2 _685 = (abs(_664) - _660) + vec2(_674);\n    float d = (length(max(_685, vec2(0.0))) + min(max(_685.x, _685.y), 0.0)) - _674;\n    float ax = params.y;\n    bool _706 = params.y > 15.0;\n    if (_706)\n    {\n        ax -= 20.0;\n    }\n    float _717;\n    if (ax <= (-1.5))\n    {\n        _717 = (-2.0) - ax;\n    }\n    else\n    {\n        _717 = 0.0;\n    }\n    if (_717 > 0.0)\n    {\n        float _731 = _717 * 0.5;\n        d = abs(d + _731) - _731;\n    }\n    float _739 = fwidth(d);\n    float _740 = max(_739, 9.9999997473787516355514526367188e-05);\n    float _750 = clamp(0.5 - (d / max(shape_rs.y, _740)), 0.0, 1.0);\n    float _755;\n    if (shape_rs.y > _740)\n    {\n        _755 = (_750 * _750) * (3.0 - (2.0 * _750));\n    }\n    else\n    {\n        _755 = _750;\n    }\n    vec4 c = color;\n    bool _777 = (_717 <= 0.0) && (ax > (-0.5));\n    if (_777)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _792 = cos(ax);\n            float _794 = sin(ax);\n            g = ((dot(_664, vec2(_792, _794)) / max((abs(_792) * _670) + (abs(_794) * _672), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_706)\n        {\n            vec4 _837 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _837;\n            vec3 param = _837.xyz;\n            float param_1 = xform.y;\n            vec3 _844 = fa_tex_fix(param, param_1);\n            vec4 _1540 = c;\n            _1540.x = _844.x;\n            _1540.y = _844.y;\n            _1540.z = _844.z;\n            c = _1540;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _856 = scene_rgb(param_2);\n            vec4 _881 = mix(vec4(color.xyz * color.w, color.w), vec4(_856 * color2.w, color2.w), vec4(g));\n            float _883 = _881.w;\n            vec3 _886;\n            if (_883 > 9.9999997473787516355514526367188e-06)\n            {\n                _886 = _881.xyz / vec3(_883);\n            }\n            else\n            {\n                _886 = color.xyz;\n            }\n            c = vec4(_886, _883);\n        }\n    }\n    vec4 _1549 = c;\n    _1549.w = _1549.w * _755;\n    c = _1549;\n    if (_777 || (shape_rs.y > 0.0))\n    {\n        float _927 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _936 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _936 + vec3(_927 * 0.0039215688593685626983642578125);\n            vec3 _942 = fa_srgb_to_linear(param_4);\n            vec4 _1552 = c;\n            _1552.x = _942.x;\n            _1552.y = _942.y;\n            _1552.z = _942.z;\n            c = _1552;\n        }\n        else\n        {\n            vec4 _952 = c;\n            vec3 _955 = _952.xyz + vec3(_927 * 0.0039215688593685626983642578125);\n            vec4 _1559 = _952;\n            _1559.x = _955.x;\n            _1559.y = _955.y;\n            _1559.z = _955.z;\n            c = _1559;\n        }\n        vec4 _1564 = c;\n        _1564.w = clamp(_1564.w + ((_927 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1564.w)), 0.0, 1.0);\n        c = _1564;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _323 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _327 = _323.y;\n    return vec2(_323.x, mix(_327, 1.0 - _327, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _369 = base_mode < 0.5;\n    bool _380;\n    if (!_369)\n    {\n        _380 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _380 = _369;\n    }\n    float _381;\n    if (_380)\n    {\n        _381 = shape_half.x;\n    }\n    else\n    {\n        _381 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _381);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _302 = scene_rgb(param);\n    return _302;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _402 = s.color;\n    vec3 _404 = _402.xyz * fa_scene_rgb(param);\n    s.color.x = _404.x;\n    s.color.y = _404.y;\n    s.color.z = _404.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _982 = params.x > 31.5;\n    if (_982)\n    {\n        mode -= 32.0;\n    }\n    float _990 = mode;\n    bool _992 = _990 > 15.5;\n    if (_992)\n    {\n        mode -= 16.0;\n    }\n    float _1000 = mode;\n    bool _1002 = _1000 > 7.5;\n    if (_1002)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_992)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_992)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1066 = tex_color(param_5) * color;\n                vec4 param_6 = _1066;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1066.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1101 = length(uv);\n                    float _1104 = fwidth(_1101);\n                    float _1105 = max(_1104, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1101) / _1105) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1101) / _1105) + 0.5, 0.0, 1.0) * clamp(((_1101 - params.y) / _1105) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1145 = clamp(1.0 - _1101, 0.0, 1.0);\n                            cov = (_1145 * _1145) * (3.0 - (2.0 * _1145));\n                        }\n                    }\n                    vec3 _1154;\n                    if (_992)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1154 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1154 = color.xyz;\n                    }\n                    frag_color = vec4(_1154, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1493 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1493);\n    fragment(param_11, param_12);\n    _1493 = param_12.color;\n    frag_color = param_12.color;\n    if (_982)\n    {\n        vec4 _1192 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1197 = scene_rgb(param_13);\n        vec3 _1201 = mix(_1192.xyz, _1197, vec3(color2.w));\n        frag_color.x = _1201.x;\n        frag_color.y = _1201.y;\n        frag_color.z = _1201.z;\n    }\n    if (_1002)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1225 = quad_fs_params[53].w > 0.0;\n    bool _1233;\n    if (!_1225)\n    {\n        _1233 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1233 = _1225;\n    }\n    if (_1233)\n    {\n        vec3 _1247 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1254 = dot(_1247, quad_fs_params[55].xyz);\n        bool _1258 = quad_fs_params[55].w > 0.5;\n        float _1259;\n        if (_1258)\n        {\n            _1259 = _1254;\n        }\n        else\n        {\n            _1259 = length(_1247);\n        }\n        float _1271 = _1259 - quad_fs_params[54].x;\n        if (_1271 > 0.0)\n        {\n            float _1280 = quad_fs_params[53].w * _1271;\n            float tau = _1280 * _1280;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1296;\n                if (_1258)\n                {\n                    _1296 = world_xy.y - (quad_fs_params[55].y * _1254);\n                }\n                else\n                {\n                    _1296 = quad_fs_params[56].y;\n                }\n                float _1317 = mix(_1296, world_xy.y, clamp(quad_fs_params[54].x / _1259, 0.0, 1.0));\n                float _1321 = world_xy.y - _1317;\n                float _1326 = _1317 - quad_fs_params[54].z;\n                float _1331 = world_xy.y - quad_fs_params[54].z;\n                bool _1334 = _1326 <= 0.0;\n                bool _1335 = !_1334;\n                bool _1341;\n                if (_1335)\n                {\n                    _1341 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1341 = _1334;\n                }\n                float _1342;\n                if (_1341)\n                {\n                    _1342 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1342 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1326, 80.0));\n                }\n                bool _1369;\n                if (_1335)\n                {\n                    _1369 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1369 = _1334;\n                }\n                float _1370;\n                if (_1369)\n                {\n                    _1370 = quad_fs_params[54].y * _1326;\n                }\n                else\n                {\n                    _1370 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1326, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1395 = _1331 <= 0.0;\n                bool _1402;\n                if (!_1395)\n                {\n                    _1402 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1402 = _1395;\n                }\n                float _1403;\n                if (_1402)\n                {\n                    _1403 = quad_fs_params[54].y * _1331;\n                }\n                else\n                {\n                    _1403 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1331, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1430;\n                if (abs(_1321) < 0.001000000047497451305389404296875)\n                {\n                    _1430 = _1342;\n                }\n                else\n                {\n                    _1430 = (_1403 - _1370) / _1321;\n                }\n                tau += (_1271 * max(_1430, 0.0));\n            }\n            vec4 _1453 = frag_color;\n            vec3 _1461 = mix(_1453.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1461.x;\n            frag_color.y = _1461.y;\n            frag_color.z = _1461.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_316",
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
            "inst_name": "_395",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _160 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _165 = _160.y;\n    return vec2(_160.x, mix(_165, 1.0 - _165, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _209 = base_mode < 0.5;\n    bool _220;\n    if (!_209)\n    {\n        _220 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _220 = _209;\n    }\n    float _221;\n    if (_220)\n    {\n        _221 = shape_half.x;\n    }\n    else\n    {\n        _221 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _221);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _242 = s.color;\n    vec3 _244 = _242.xyz * fa_scene_rgb(param);\n    s.color.x = _244.x;\n    s.color.y = _244.y;\n    s.color.z = _244.z;\n}\n\nvoid main()\n{\n    vec4 _263 = texture(tex_smp, uv);\n    vec3 param = _263.xyz;\n    float param_1 = xform.y;\n    vec3 _272 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_272, _263.w) * color;\n    float param_2 = 0.0;\n    vec4 _326 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_326);\n    fragment(param_3, param_4);\n    _326 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_153",
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
            "inst_name": "_235",
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
