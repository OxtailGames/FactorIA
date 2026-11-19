{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 2) in vec2 params;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _264 = texture(tex_smp, p);\n    vec3 param = _264.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    return vec4(_274, _264.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _87 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_87.x * 255.0) + 0.5) * 256.0) + floor((_87.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _125 = atan(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0)\n    {\n        _128 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875;\n    float _145 = min(floor(_140), 1023.0);\n    float _152 = _145 + 1.0;\n    float i1 = _152;\n    if (_152 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _111) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _111) + 0.5, 0.0, 1.0), _140 - _145);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _378 = quad_fs_params[0].y > 0.5;\n    if (_378)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _402 = fa_tex_fix(param, param_1);\n        vec3 _406 = (_402 * 2.0) - vec3(1.0);\n        float _413 = cos(params.y);\n        float _415 = sin(params.y);\n        n = normalize(vec3((vec2(_413, _415) * _406.x) + ((vec2(-_415, _413) * ((mode > 5.5) ? (-1.0) : 1.0)) * _406.y), max(_406.z, 0.0500000007450580596923828125)));\n    }\n    bool _449 = !_378;\n    bool _455;\n    if (_449)\n    {\n        _455 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _455 = _449;\n    }\n    vec3 _458;\n    if (_455)\n    {\n        _458 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _458 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _458;\n    bool _475;\n    if (_455)\n    {\n        _475 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _475 = _455;\n    }\n    if (_475)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _594;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _515;\n        if (!_455)\n        {\n            _515 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _515 = _455;\n        }\n        if (_515)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _541 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_541) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _561 = vec3(_541, quad_fs_params[i * 1 + 5].z);\n            l = _561 / vec3(max(length(_561), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_541;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_378)\n        {\n            _594 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _594 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _594));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _623 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _627 = uv * _623;\n    float _633 = _623.x;\n    float _635 = _623.y;\n    float _637 = clamp(shape_rs.x, 0.0, min(_633, _635));\n    vec2 _648 = (abs(_627) - _623) + vec2(_637);\n    float d = (length(max(_648, vec2(0.0))) + min(max(_648.x, _648.y), 0.0)) - _637;\n    float ax = params.y;\n    bool _669 = params.y > 15.0;\n    if (_669)\n    {\n        ax -= 20.0;\n    }\n    float _680;\n    if (ax <= (-1.5))\n    {\n        _680 = (-2.0) - ax;\n    }\n    else\n    {\n        _680 = 0.0;\n    }\n    if (_680 > 0.0)\n    {\n        float _694 = _680 * 0.5;\n        d = abs(d + _694) - _694;\n    }\n    float _702 = fwidth(d);\n    float _703 = max(_702, 9.9999997473787516355514526367188e-05);\n    float _713 = clamp(0.5 - (d / max(shape_rs.y, _703)), 0.0, 1.0);\n    float _718;\n    if (shape_rs.y > _703)\n    {\n        _718 = (_713 * _713) * (3.0 - (2.0 * _713));\n    }\n    else\n    {\n        _718 = _713;\n    }\n    vec4 c = color;\n    bool _740 = (_680 <= 0.0) && (ax > (-0.5));\n    if (_740)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _755 = cos(ax);\n            float _757 = sin(ax);\n            g = ((dot(_627, vec2(_755, _757)) / max((abs(_755) * _633) + (abs(_757) * _635), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_669)\n        {\n            vec4 _800 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _800;\n            vec3 param = _800.xyz;\n            float param_1 = xform.y;\n            vec3 _807 = fa_tex_fix(param, param_1);\n            vec4 _1499 = c;\n            _1499.x = _807.x;\n            _1499.y = _807.y;\n            _1499.z = _807.z;\n            c = _1499;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _819 = scene_rgb(param_2);\n            vec4 _844 = mix(vec4(color.xyz * color.w, color.w), vec4(_819 * color2.w, color2.w), vec4(g));\n            float _846 = _844.w;\n            vec3 _849;\n            if (_846 > 9.9999997473787516355514526367188e-06)\n            {\n                _849 = _844.xyz / vec3(_846);\n            }\n            else\n            {\n                _849 = color.xyz;\n            }\n            c = vec4(_849, _846);\n        }\n    }\n    vec4 _1508 = c;\n    _1508.w = _1508.w * _718;\n    c = _1508;\n    if (_740 || (shape_rs.y > 0.0))\n    {\n        float _890 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _899 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _899 + vec3(_890 * 0.0039215688593685626983642578125);\n            vec3 _905 = fa_srgb_to_linear(param_4);\n            vec4 _1511 = c;\n            _1511.x = _905.x;\n            _1511.y = _905.y;\n            _1511.z = _905.z;\n            c = _1511;\n        }\n        else\n        {\n            vec4 _915 = c;\n            vec3 _918 = _915.xyz + vec3(_890 * 0.0039215688593685626983642578125);\n            vec4 _1518 = _915;\n            _1518.x = _918.x;\n            _1518.y = _918.y;\n            _1518.z = _918.z;\n            c = _1518;\n        }\n        vec4 _1523 = c;\n        _1523.w = clamp(_1523.w + ((_890 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1523.w)), 0.0, 1.0);\n        c = _1523;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _313 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _317 = _313.y;\n    return vec2(_313.x, mix(_317, 1.0 - _317, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _945 = params.x > 31.5;\n    if (_945)\n    {\n        mode -= 32.0;\n    }\n    float _953 = mode;\n    bool _955 = _953 > 15.5;\n    if (_955)\n    {\n        mode -= 16.0;\n    }\n    float _963 = mode;\n    bool _965 = _963 > 7.5;\n    if (_965)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_955)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_955)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1029 = tex_color(param_5) * color;\n                vec4 param_6 = _1029;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1029.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1065 = length(uv);\n                    float _1068 = fwidth(_1065);\n                    float _1069 = max(_1068, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1065) / _1069) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1065) / _1069) + 0.5, 0.0, 1.0) * clamp(((_1065 - params.y) / _1069) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1110 = clamp(1.0 - _1065, 0.0, 1.0);\n                            cov = (_1110 * _1110) * (3.0 - (2.0 * _1110));\n                        }\n                    }\n                    vec3 _1119;\n                    if (_955)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1119 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1119 = color.xyz;\n                    }\n                    frag_color = vec4(_1119, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(frag_color);\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_945)\n    {\n        vec4 _1156 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1161 = scene_rgb(param_13);\n        vec3 _1165 = mix(_1156.xyz, _1161, vec3(color2.w));\n        frag_color.x = _1165.x;\n        frag_color.y = _1165.y;\n        frag_color.z = _1165.z;\n    }\n    if (_965)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1189 = quad_fs_params[53].w > 0.0;\n    bool _1197;\n    if (!_1189)\n    {\n        _1197 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1197 = _1189;\n    }\n    if (_1197)\n    {\n        vec3 _1211 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1218 = dot(_1211, quad_fs_params[55].xyz);\n        bool _1222 = quad_fs_params[55].w > 0.5;\n        float _1223;\n        if (_1222)\n        {\n            _1223 = _1218;\n        }\n        else\n        {\n            _1223 = length(_1211);\n        }\n        float _1235 = _1223 - quad_fs_params[54].x;\n        if (_1235 > 0.0)\n        {\n            float _1244 = quad_fs_params[53].w * _1235;\n            float tau = _1244 * _1244;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1260;\n                if (_1222)\n                {\n                    _1260 = world_xy.y - (quad_fs_params[55].y * _1218);\n                }\n                else\n                {\n                    _1260 = quad_fs_params[56].y;\n                }\n                float _1281 = mix(_1260, world_xy.y, clamp(quad_fs_params[54].x / _1223, 0.0, 1.0));\n                float _1285 = world_xy.y - _1281;\n                float _1290 = _1281 - quad_fs_params[54].z;\n                float _1295 = world_xy.y - quad_fs_params[54].z;\n                bool _1298 = _1290 <= 0.0;\n                bool _1299 = !_1298;\n                bool _1305;\n                if (_1299)\n                {\n                    _1305 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1305 = _1298;\n                }\n                float _1306;\n                if (_1305)\n                {\n                    _1306 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1306 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1290, 80.0));\n                }\n                bool _1333;\n                if (_1299)\n                {\n                    _1333 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1298;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = quad_fs_params[54].y * _1290;\n                }\n                else\n                {\n                    _1334 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1290, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1359 = _1295 <= 0.0;\n                bool _1366;\n                if (!_1359)\n                {\n                    _1366 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1366 = _1359;\n                }\n                float _1367;\n                if (_1366)\n                {\n                    _1367 = quad_fs_params[54].y * _1295;\n                }\n                else\n                {\n                    _1367 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1295, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1394;\n                if (abs(_1285) < 0.001000000047497451305389404296875)\n                {\n                    _1394 = _1306;\n                }\n                else\n                {\n                    _1394 = (_1367 - _1334) / _1285;\n                }\n                tau += (_1235 * max(_1394, 0.0));\n            }\n            vec4 _1417 = frag_color;\n            vec3 _1425 = mix(_1417.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1425.x;\n            frag_color.y = _1425.y;\n            frag_color.z = _1425.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_306",
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
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _132 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _138 = _132.y;\n    return vec2(_132.x, mix(_138, 1.0 - _138, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nvoid main()\n{\n    vec4 _207 = texture(tex_smp, uv);\n    vec3 param = _207.xyz;\n    float param_1 = xform.y;\n    vec3 _219 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_219, _207.w) * color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(frag_color);\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_125",
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
