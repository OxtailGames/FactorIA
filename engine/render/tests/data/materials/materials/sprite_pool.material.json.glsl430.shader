{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "glsl430",
  "params": [
    "reflection",
    "refraction",
    "size",
    "strength",
    "tint",
    "waveAmplitude",
    "waveLength",
    "waveSpeed"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[8];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _269 = texture(tex_smp, p);\n    vec3 param = _269.xyz;\n    float param_1 = xform.y;\n    vec3 _279 = fa_tex_fix(param, param_1);\n    return vec4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _92 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = atan(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _497 = quad_fs_params[0].y > 0.5;\n    if (_497)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _521 = fa_tex_fix(param, param_1);\n        vec3 _525 = (_521 * 2.0) - vec3(1.0);\n        float _532 = cos(params.y);\n        float _534 = sin(params.y);\n        n = normalize(vec3((vec2(_532, _534) * _525.x) + ((vec2(-_534, _532) * ((mode > 5.5) ? (-1.0) : 1.0)) * _525.y), max(_525.z, 0.0500000007450580596923828125)));\n    }\n    bool _568 = !_497;\n    bool _574;\n    if (_568)\n    {\n        _574 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _574 = _568;\n    }\n    vec3 _577;\n    if (_574)\n    {\n        _577 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _577 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _577;\n    bool _594;\n    if (_574)\n    {\n        _594 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _594 = _574;\n    }\n    if (_594)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _710;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _632;\n        if (!_574)\n        {\n            _632 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _632 = _574;\n        }\n        if (_632)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _658 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_658) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _678 = vec3(_658, quad_fs_params[i * 1 + 5].z);\n            l = _678 / vec3(max(length(_678), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_658;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_497)\n        {\n            _710 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _710 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _710));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _738 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _742 = uv * _738;\n    float _748 = _738.x;\n    float _750 = _738.y;\n    float _752 = clamp(shape_rs.x, 0.0, min(_748, _750));\n    vec2 _763 = (abs(_742) - _738) + vec2(_752);\n    float d = (length(max(_763, vec2(0.0))) + min(max(_763.x, _763.y), 0.0)) - _752;\n    float ax = params.y;\n    bool _784 = params.y > 15.0;\n    if (_784)\n    {\n        ax -= 20.0;\n    }\n    float _795;\n    if (ax <= (-1.5))\n    {\n        _795 = (-2.0) - ax;\n    }\n    else\n    {\n        _795 = 0.0;\n    }\n    if (_795 > 0.0)\n    {\n        float _809 = _795 * 0.5;\n        d = abs(d + _809) - _809;\n    }\n    float _817 = fwidth(d);\n    float _818 = max(_817, 9.9999997473787516355514526367188e-05);\n    float _828 = clamp(0.5 - (d / max(shape_rs.y, _818)), 0.0, 1.0);\n    float _833;\n    if (shape_rs.y > _818)\n    {\n        _833 = (_828 * _828) * (3.0 - (2.0 * _828));\n    }\n    else\n    {\n        _833 = _828;\n    }\n    vec4 c = color;\n    bool _855 = (_795 <= 0.0) && (ax > (-0.5));\n    if (_855)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _870 = cos(ax);\n            float _872 = sin(ax);\n            g = ((dot(_742, vec2(_870, _872)) / max((abs(_870) * _748) + (abs(_872) * _750), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_784)\n        {\n            vec4 _915 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _915;\n            vec3 param = _915.xyz;\n            float param_1 = xform.y;\n            vec3 _922 = fa_tex_fix(param, param_1);\n            vec4 _1620 = c;\n            _1620.x = _922.x;\n            _1620.y = _922.y;\n            _1620.z = _922.z;\n            c = _1620;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _934 = scene_rgb(param_2);\n            vec4 _959 = mix(vec4(color.xyz * color.w, color.w), vec4(_934 * color2.w, color2.w), vec4(g));\n            float _961 = _959.w;\n            vec3 _964;\n            if (_961 > 9.9999997473787516355514526367188e-06)\n            {\n                _964 = _959.xyz / vec3(_961);\n            }\n            else\n            {\n                _964 = color.xyz;\n            }\n            c = vec4(_964, _961);\n        }\n    }\n    vec4 _1629 = c;\n    _1629.w = _1629.w * _833;\n    c = _1629;\n    if (_855 || (shape_rs.y > 0.0))\n    {\n        float _1005 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1014 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1014 + vec3(_1005 * 0.0039215688593685626983642578125);\n            vec3 _1020 = fa_srgb_to_linear(param_4);\n            vec4 _1632 = c;\n            _1632.x = _1020.x;\n            _1632.y = _1020.y;\n            _1632.z = _1020.z;\n            c = _1632;\n        }\n        else\n        {\n            vec4 _1030 = c;\n            vec3 _1033 = _1030.xyz + vec3(_1005 * 0.0039215688593685626983642578125);\n            vec4 _1639 = _1030;\n            _1639.x = _1033.x;\n            _1639.y = _1033.y;\n            _1639.z = _1033.z;\n            c = _1639;\n        }\n        vec4 _1644 = c;\n        _1644.w = clamp(_1644.w + ((_1005 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1644.w)), 0.0, 1.0);\n        c = _1644;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _360 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _364 = _360.y;\n    return vec2(_360.x, mix(_364, 1.0 - _364, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _403 = base_mode < 0.5;\n    bool _414;\n    if (!_403)\n    {\n        _414 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _414 = _403;\n    }\n    float _415;\n    if (_414)\n    {\n        _415 = shape_half.x;\n    }\n    else\n    {\n        _415 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _415);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[59].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _328 = (uv_1 * quad_fs_params[59].xy) + quad_fs_params[59].zw;\n    float _330 = _328.y;\n    _328.y = mix(_330, 1.0 - _330, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_328, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + (vec2(fa_material[1].x + fa_material[3].x, 0.0) * quad_fs_params[58].xy);\n    s.color = vec4(mix(fa_scene_color(param).xyz, fa_material[4].xyz, vec3(fa_material[4].w)), 1.0);\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1060 = params.x > 31.5;\n    if (_1060)\n    {\n        mode -= 32.0;\n    }\n    float _1068 = mode;\n    bool _1070 = _1068 > 15.5;\n    if (_1070)\n    {\n        mode -= 16.0;\n    }\n    float _1078 = mode;\n    bool _1080 = _1078 > 7.5;\n    if (_1080)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1070)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1070)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1144 = tex_color(param_5) * color;\n                vec4 param_6 = _1144;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1144.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1179 = length(uv);\n                    float _1182 = fwidth(_1179);\n                    float _1183 = max(_1182, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1179) / _1183) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1179) / _1183) + 0.5, 0.0, 1.0) * clamp(((_1179 - params.y) / _1183) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1223 = clamp(1.0 - _1179, 0.0, 1.0);\n                            cov = (_1223 * _1223) * (3.0 - (2.0 * _1223));\n                        }\n                    }\n                    vec3 _1232;\n                    if (_1070)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1232 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1232 = color.xyz;\n                    }\n                    frag_color = vec4(_1232, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1569 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1569);\n    fragment(param_11, param_12);\n    _1569 = param_12.color;\n    frag_color = param_12.color;\n    if (_1060)\n    {\n        vec4 _1270 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1275 = scene_rgb(param_13);\n        vec3 _1279 = mix(_1270.xyz, _1275, vec3(color2.w));\n        frag_color.x = _1279.x;\n        frag_color.y = _1279.y;\n        frag_color.z = _1279.z;\n    }\n    if (_1080)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1302 = quad_fs_params[53].w > 0.0;\n    bool _1310;\n    if (!_1302)\n    {\n        _1310 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1310 = _1302;\n    }\n    if (_1310)\n    {\n        vec3 _1323 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1330 = dot(_1323, quad_fs_params[55].xyz);\n        bool _1334 = quad_fs_params[55].w > 0.5;\n        float _1335;\n        if (_1334)\n        {\n            _1335 = _1330;\n        }\n        else\n        {\n            _1335 = length(_1323);\n        }\n        float _1347 = _1335 - quad_fs_params[54].x;\n        if (_1347 > 0.0)\n        {\n            float _1356 = quad_fs_params[53].w * _1347;\n            float tau = _1356 * _1356;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1372;\n                if (_1334)\n                {\n                    _1372 = world_xy.y - (quad_fs_params[55].y * _1330);\n                }\n                else\n                {\n                    _1372 = quad_fs_params[56].y;\n                }\n                float _1393 = mix(_1372, world_xy.y, clamp(quad_fs_params[54].x / _1335, 0.0, 1.0));\n                float _1397 = world_xy.y - _1393;\n                float _1402 = _1393 - quad_fs_params[54].z;\n                float _1407 = world_xy.y - quad_fs_params[54].z;\n                bool _1410 = _1402 <= 0.0;\n                bool _1411 = !_1410;\n                bool _1417;\n                if (_1411)\n                {\n                    _1417 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1417 = _1410;\n                }\n                float _1418;\n                if (_1417)\n                {\n                    _1418 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1418 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1402, 80.0));\n                }\n                bool _1445;\n                if (_1411)\n                {\n                    _1445 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1445 = _1410;\n                }\n                float _1446;\n                if (_1445)\n                {\n                    _1446 = quad_fs_params[54].y * _1402;\n                }\n                else\n                {\n                    _1446 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1402, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1471 = _1407 <= 0.0;\n                bool _1478;\n                if (!_1471)\n                {\n                    _1478 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1478 = _1471;\n                }\n                float _1479;\n                if (_1478)\n                {\n                    _1479 = quad_fs_params[54].y * _1407;\n                }\n                else\n                {\n                    _1479 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1407, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1506;\n                if (abs(_1397) < 0.001000000047497451305389404296875)\n                {\n                    _1506 = _1418;\n                }\n                else\n                {\n                    _1506 = (_1479 - _1446) / _1397;\n                }\n                tau += (_1347 * max(_1506, 0.0));\n            }\n            vec4 _1529 = frag_color;\n            vec3 _1537 = mix(_1529.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1537.x;\n            frag_color.y = _1537.y;\n            frag_color.z = _1537.z;\n        }\n    }\n}\n\n",
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
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_307",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
                "offset": 0,
                "glsl_name": "quad_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_430",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 8,
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
              "name": "fa_scene_tex",
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
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[63];\nuniform vec4 fa_material[8];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D fa_scene_tex_light_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _189 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _193 = _189.y;\n    return vec2(_189.x, mix(_193, 1.0 - _193, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _233 = base_mode < 0.5;\n    bool _244;\n    if (!_233)\n    {\n        _244 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _244 = _233;\n    }\n    float _245;\n    if (_244)\n    {\n        _245 = shape_half.x;\n    }\n    else\n    {\n        _245 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _245);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_scene_color(vec2 uv_1)\n{\n    if (quad_fs_params[59].x <= 0.0)\n    {\n        return vec4(0.0);\n    }\n    vec2 _150 = (uv_1 * quad_fs_params[59].xy) + quad_fs_params[59].zw;\n    float _153 = _150.y;\n    _150.y = mix(_153, 1.0 - _153, quad_fs_params[58].z);\n    return textureLod(fa_scene_tex_light_smp, clamp(_150, vec2(0.0), vec2(1.0)), 0.0);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec2 param = i.screen_uv + (vec2(fa_material[1].x + fa_material[3].x, 0.0) * quad_fs_params[58].xy);\n    s.color = vec4(mix(fa_scene_color(param).xyz, fa_material[4].xyz, vec3(fa_material[4].w)), 1.0);\n}\n\nvoid main()\n{\n    vec4 _329 = texture(tex_smp, uv);\n    vec3 param = _329.xyz;\n    float param_1 = xform.y;\n    vec3 _340 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_340, _329.w) * color;\n    float param_2 = 0.0;\n    vec4 _393 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_393);\n    fragment(param_3, param_4);\n    _393 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_128",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
                "offset": 0,
                "glsl_name": "quad_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_261",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 8,
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
              "slot": 12,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
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
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1,
            "glsl_name": "fa_scene_tex_light_smp"
          }
        ]
      }
    }
  }
}
