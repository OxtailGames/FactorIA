{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "dac082249371b076675e61040e0115b7624fdfe0d386fccb444476b7af3a109f",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 2) in vec2 params;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _264 = texture(tex_smp, p);\n    vec3 param = _264.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    return vec4(_274, _264.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _87 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_87.x * 255.0) + 0.5) * 256.0) + floor((_87.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _125 = atan(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0)\n    {\n        _128 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875;\n    float _145 = min(floor(_140), 1023.0);\n    float _152 = _145 + 1.0;\n    float i1 = _152;\n    if (_152 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _111) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _111) + 0.5, 0.0, 1.0), _140 - _145);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _366 = quad_fs_params[0].y > 0.5;\n    if (_366)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _390 = fa_tex_fix(param, param_1);\n        vec3 _394 = (_390 * 2.0) - vec3(1.0);\n        float _401 = cos(params.y);\n        float _403 = sin(params.y);\n        n = normalize(vec3((vec2(_401, _403) * _394.x) + ((vec2(-_403, _401) * ((mode > 5.5) ? (-1.0) : 1.0)) * _394.y), max(_394.z, 0.0500000007450580596923828125)));\n    }\n    bool _437 = !_366;\n    bool _443;\n    if (_437)\n    {\n        _443 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _443 = _437;\n    }\n    vec3 _446;\n    if (_443)\n    {\n        _446 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _446 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _446;\n    bool _463;\n    if (_443)\n    {\n        _463 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _463 = _443;\n    }\n    if (_463)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _582;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _503;\n        if (!_443)\n        {\n            _503 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _503 = _443;\n        }\n        if (_503)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _529 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_529) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _549 = vec3(_529, quad_fs_params[i * 1 + 5].z);\n            l = _549 / vec3(max(length(_549), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_529;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_366)\n        {\n            _582 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _582 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _582));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _611 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _615 = uv * _611;\n    float _621 = _611.x;\n    float _623 = _611.y;\n    float _625 = clamp(shape_rs.x, 0.0, min(_621, _623));\n    vec2 _636 = (abs(_615) - _611) + vec2(_625);\n    float d = (length(max(_636, vec2(0.0))) + min(max(_636.x, _636.y), 0.0)) - _625;\n    float ax = params.y;\n    bool _657 = params.y > 15.0;\n    if (_657)\n    {\n        ax -= 20.0;\n    }\n    float _668;\n    if (ax <= (-1.5))\n    {\n        _668 = (-2.0) - ax;\n    }\n    else\n    {\n        _668 = 0.0;\n    }\n    if (_668 > 0.0)\n    {\n        float _682 = _668 * 0.5;\n        d = abs(d + _682) - _682;\n    }\n    float _690 = fwidth(d);\n    float _691 = max(_690, 9.9999997473787516355514526367188e-05);\n    float _701 = clamp(0.5 - (d / max(shape_rs.y, _691)), 0.0, 1.0);\n    float _706;\n    if (shape_rs.y > _691)\n    {\n        _706 = (_701 * _701) * (3.0 - (2.0 * _701));\n    }\n    else\n    {\n        _706 = _701;\n    }\n    vec4 c = color;\n    bool _728 = (_668 <= 0.0) && (ax > (-0.5));\n    if (_728)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _743 = cos(ax);\n            float _745 = sin(ax);\n            g = ((dot(_615, vec2(_743, _745)) / max((abs(_743) * _621) + (abs(_745) * _623), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_657)\n        {\n            vec4 _788 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _788;\n            vec3 param = _788.xyz;\n            float param_1 = xform.y;\n            vec3 _795 = fa_tex_fix(param, param_1);\n            vec4 _1487 = c;\n            _1487.x = _795.x;\n            _1487.y = _795.y;\n            _1487.z = _795.z;\n            c = _1487;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _807 = scene_rgb(param_2);\n            vec4 _832 = mix(vec4(color.xyz * color.w, color.w), vec4(_807 * color2.w, color2.w), vec4(g));\n            float _834 = _832.w;\n            vec3 _837;\n            if (_834 > 9.9999997473787516355514526367188e-06)\n            {\n                _837 = _832.xyz / vec3(_834);\n            }\n            else\n            {\n                _837 = color.xyz;\n            }\n            c = vec4(_837, _834);\n        }\n    }\n    vec4 _1496 = c;\n    _1496.w = _1496.w * _706;\n    c = _1496;\n    if (_728 || (shape_rs.y > 0.0))\n    {\n        float _878 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _887 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _887 + vec3(_878 * 0.0039215688593685626983642578125);\n            vec3 _893 = fa_srgb_to_linear(param_4);\n            vec4 _1499 = c;\n            _1499.x = _893.x;\n            _1499.y = _893.y;\n            _1499.z = _893.z;\n            c = _1499;\n        }\n        else\n        {\n            vec4 _903 = c;\n            vec3 _906 = _903.xyz + vec3(_878 * 0.0039215688593685626983642578125);\n            vec4 _1506 = _903;\n            _1506.x = _906.x;\n            _1506.y = _906.y;\n            _1506.z = _906.z;\n            c = _1506;\n        }\n        vec4 _1511 = c;\n        _1511.w = clamp(_1511.w + ((_878 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1511.w)), 0.0, 1.0);\n        c = _1511;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _313 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _317 = _313.y;\n    return vec2(_313.x, mix(_317, 1.0 - _317, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _933 = params.x > 31.5;\n    if (_933)\n    {\n        mode -= 32.0;\n    }\n    float _941 = mode;\n    bool _943 = _941 > 15.5;\n    if (_943)\n    {\n        mode -= 16.0;\n    }\n    float _951 = mode;\n    bool _953 = _951 > 7.5;\n    if (_953)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_943)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_943)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1017 = tex_color(param_5) * color;\n                vec4 param_6 = _1017;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1017.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1053 = length(uv);\n                    float _1056 = fwidth(_1053);\n                    float _1057 = max(_1056, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1053) / _1057) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1053) / _1057) + 0.5, 0.0, 1.0) * clamp(((_1053 - params.y) / _1057) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1098 = clamp(1.0 - _1053, 0.0, 1.0);\n                            cov = (_1098 * _1098) * (3.0 - (2.0 * _1098));\n                        }\n                    }\n                    vec3 _1107;\n                    if (_943)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1107 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1107 = color.xyz;\n                    }\n                    frag_color = vec4(_1107, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(frag_color);\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_933)\n    {\n        vec4 _1144 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1149 = scene_rgb(param_13);\n        vec3 _1153 = mix(_1144.xyz, _1149, vec3(color2.w));\n        frag_color.x = _1153.x;\n        frag_color.y = _1153.y;\n        frag_color.z = _1153.z;\n    }\n    if (_953)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1177 = quad_fs_params[53].w > 0.0;\n    bool _1185;\n    if (!_1177)\n    {\n        _1185 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1185 = _1177;\n    }\n    if (_1185)\n    {\n        vec3 _1199 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1206 = dot(_1199, quad_fs_params[55].xyz);\n        bool _1210 = quad_fs_params[55].w > 0.5;\n        float _1211;\n        if (_1210)\n        {\n            _1211 = _1206;\n        }\n        else\n        {\n            _1211 = length(_1199);\n        }\n        float _1223 = _1211 - quad_fs_params[54].x;\n        if (_1223 > 0.0)\n        {\n            float _1232 = quad_fs_params[53].w * _1223;\n            float tau = _1232 * _1232;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1248;\n                if (_1210)\n                {\n                    _1248 = world_xy.y - (quad_fs_params[55].y * _1206);\n                }\n                else\n                {\n                    _1248 = quad_fs_params[56].y;\n                }\n                float _1269 = mix(_1248, world_xy.y, clamp(quad_fs_params[54].x / _1211, 0.0, 1.0));\n                float _1273 = world_xy.y - _1269;\n                float _1278 = _1269 - quad_fs_params[54].z;\n                float _1283 = world_xy.y - quad_fs_params[54].z;\n                bool _1286 = _1278 <= 0.0;\n                bool _1287 = !_1286;\n                bool _1293;\n                if (_1287)\n                {\n                    _1293 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1293 = _1286;\n                }\n                float _1294;\n                if (_1293)\n                {\n                    _1294 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1294 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1278, 80.0));\n                }\n                bool _1321;\n                if (_1287)\n                {\n                    _1321 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1321 = _1286;\n                }\n                float _1322;\n                if (_1321)\n                {\n                    _1322 = quad_fs_params[54].y * _1278;\n                }\n                else\n                {\n                    _1322 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1278, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1347 = _1283 <= 0.0;\n                bool _1354;\n                if (!_1347)\n                {\n                    _1354 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1354 = _1347;\n                }\n                float _1355;\n                if (_1354)\n                {\n                    _1355 = quad_fs_params[54].y * _1283;\n                }\n                else\n                {\n                    _1355 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1283, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1382;\n                if (abs(_1273) < 0.001000000047497451305389404296875)\n                {\n                    _1382 = _1294;\n                }\n                else\n                {\n                    _1382 = (_1355 - _1322) / _1273;\n                }\n                tau += (_1223 * max(_1382, 0.0));\n            }\n            vec4 _1405 = frag_color;\n            vec3 _1413 = mix(_1405.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1413.x;\n            frag_color.y = _1413.y;\n            frag_color.z = _1413.z;\n        }\n    }\n}\n\n",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _132 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _138 = _132.y;\n    return vec2(_132.x, mix(_138, 1.0 - _138, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid main()\n{\n    vec4 _195 = texture(tex_smp, uv);\n    vec3 param = _195.xyz;\n    float param_1 = xform.y;\n    vec3 _207 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_207, _195.w) * color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(frag_color);\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\n",
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
