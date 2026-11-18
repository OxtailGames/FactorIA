{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "dac082249371b076675e61040e0115b7624fdfe0d386fccb444476b7af3a109f",
  "slang": "glsl430",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 2) in vec2 params;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _264 = texture(tex_smp, p);\n    vec3 param = _264.xyz;\n    float param_1 = xform.y;\n    vec3 _274 = fa_tex_fix(param, param_1);\n    return vec4(_274, _264.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _87 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_87.x * 255.0) + 0.5) * 256.0) + floor((_87.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _125 = atan(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0)\n    {\n        _128 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875;\n    float _145 = min(floor(_140), 1023.0);\n    float _152 = _145 + 1.0;\n    float i1 = _152;\n    if (_152 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _111) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _111) + 0.5, 0.0, 1.0), _140 - _145);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _381 = quad_fs_params[0].y > 0.5;\n    if (_381)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _405 = fa_tex_fix(param, param_1);\n        vec3 _409 = (_405 * 2.0) - vec3(1.0);\n        float _416 = cos(params.y);\n        float _418 = sin(params.y);\n        n = normalize(vec3((vec2(_416, _418) * _409.x) + ((vec2(-_418, _416) * ((mode > 5.5) ? (-1.0) : 1.0)) * _409.y), max(_409.z, 0.0500000007450580596923828125)));\n    }\n    bool _451 = !_381;\n    bool _457;\n    if (_451)\n    {\n        _457 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _457 = _451;\n    }\n    vec3 _460;\n    if (_457)\n    {\n        _460 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _460 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _460;\n    bool _477;\n    if (_457)\n    {\n        _477 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _477 = _457;\n    }\n    if (_477)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _596;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _517;\n        if (!_457)\n        {\n            _517 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _517 = _457;\n        }\n        if (_517)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _543 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_543) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _563 = vec3(_543, quad_fs_params[i * 1 + 5].z);\n            l = _563 / vec3(max(length(_563), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_543;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_381)\n        {\n            _596 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _596 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _596));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _625 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _629 = uv * _625;\n    float _635 = _625.x;\n    float _637 = _625.y;\n    float _639 = clamp(shape_rs.x, 0.0, min(_635, _637));\n    vec2 _650 = (abs(_629) - _625) + vec2(_639);\n    float d = (length(max(_650, vec2(0.0))) + min(max(_650.x, _650.y), 0.0)) - _639;\n    float ax = params.y;\n    bool _671 = params.y > 15.0;\n    if (_671)\n    {\n        ax -= 20.0;\n    }\n    float _682;\n    if (ax <= (-1.5))\n    {\n        _682 = (-2.0) - ax;\n    }\n    else\n    {\n        _682 = 0.0;\n    }\n    if (_682 > 0.0)\n    {\n        float _696 = _682 * 0.5;\n        d = abs(d + _696) - _696;\n    }\n    float _704 = fwidth(d);\n    float _705 = max(_704, 9.9999997473787516355514526367188e-05);\n    float _715 = clamp(0.5 - (d / max(shape_rs.y, _705)), 0.0, 1.0);\n    float _720;\n    if (shape_rs.y > _705)\n    {\n        _720 = (_715 * _715) * (3.0 - (2.0 * _715));\n    }\n    else\n    {\n        _720 = _715;\n    }\n    vec4 c = color;\n    bool _742 = (_682 <= 0.0) && (ax > (-0.5));\n    if (_742)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _757 = cos(ax);\n            float _759 = sin(ax);\n            g = ((dot(_629, vec2(_757, _759)) / max((abs(_757) * _635) + (abs(_759) * _637), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_671)\n        {\n            vec4 _802 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _802;\n            vec3 param = _802.xyz;\n            float param_1 = xform.y;\n            vec3 _809 = fa_tex_fix(param, param_1);\n            vec4 _1501 = c;\n            _1501.x = _809.x;\n            _1501.y = _809.y;\n            _1501.z = _809.z;\n            c = _1501;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _821 = scene_rgb(param_2);\n            vec4 _846 = mix(vec4(color.xyz * color.w, color.w), vec4(_821 * color2.w, color2.w), vec4(g));\n            float _848 = _846.w;\n            vec3 _851;\n            if (_848 > 9.9999997473787516355514526367188e-06)\n            {\n                _851 = _846.xyz / vec3(_848);\n            }\n            else\n            {\n                _851 = color.xyz;\n            }\n            c = vec4(_851, _848);\n        }\n    }\n    vec4 _1510 = c;\n    _1510.w = _1510.w * _720;\n    c = _1510;\n    if (_742 || (shape_rs.y > 0.0))\n    {\n        float _892 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _901 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _901 + vec3(_892 * 0.0039215688593685626983642578125);\n            vec3 _907 = fa_srgb_to_linear(param_4);\n            vec4 _1513 = c;\n            _1513.x = _907.x;\n            _1513.y = _907.y;\n            _1513.z = _907.z;\n            c = _1513;\n        }\n        else\n        {\n            vec4 _917 = c;\n            vec3 _920 = _917.xyz + vec3(_892 * 0.0039215688593685626983642578125);\n            vec4 _1520 = _917;\n            _1520.x = _920.x;\n            _1520.y = _920.y;\n            _1520.z = _920.z;\n            c = _1520;\n        }\n        vec4 _1525 = c;\n        _1525.w = clamp(_1525.w + ((_892 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1525.w)), 0.0, 1.0);\n        c = _1525;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _313 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _317 = _313.y;\n    return vec2(_313.x, mix(_317, 1.0 - _317, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _367 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _367.x;\n    s.color.y = _367.y;\n    s.color.z = _367.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _947 = params.x > 31.5;\n    if (_947)\n    {\n        mode -= 32.0;\n    }\n    float _955 = mode;\n    bool _957 = _955 > 15.5;\n    if (_957)\n    {\n        mode -= 16.0;\n    }\n    float _965 = mode;\n    bool _967 = _965 > 7.5;\n    if (_967)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_957)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_957)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1031 = tex_color(param_5) * color;\n                vec4 param_6 = _1031;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1031.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1067 = length(uv);\n                    float _1070 = fwidth(_1067);\n                    float _1071 = max(_1070, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1067) / _1071) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1067) / _1071) + 0.5, 0.0, 1.0) * clamp(((_1067 - params.y) / _1071) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1112 = clamp(1.0 - _1067, 0.0, 1.0);\n                            cov = (_1112 * _1112) * (3.0 - (2.0 * _1112));\n                        }\n                    }\n                    vec3 _1121;\n                    if (_957)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1121 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1121 = color.xyz;\n                    }\n                    frag_color = vec4(_1121, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(frag_color);\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_947)\n    {\n        vec4 _1158 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1163 = scene_rgb(param_13);\n        vec3 _1167 = mix(_1158.xyz, _1163, vec3(color2.w));\n        frag_color.x = _1167.x;\n        frag_color.y = _1167.y;\n        frag_color.z = _1167.z;\n    }\n    if (_967)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1191 = quad_fs_params[53].w > 0.0;\n    bool _1199;\n    if (!_1191)\n    {\n        _1199 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1199 = _1191;\n    }\n    if (_1199)\n    {\n        vec3 _1213 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1220 = dot(_1213, quad_fs_params[55].xyz);\n        bool _1224 = quad_fs_params[55].w > 0.5;\n        float _1225;\n        if (_1224)\n        {\n            _1225 = _1220;\n        }\n        else\n        {\n            _1225 = length(_1213);\n        }\n        float _1237 = _1225 - quad_fs_params[54].x;\n        if (_1237 > 0.0)\n        {\n            float _1246 = quad_fs_params[53].w * _1237;\n            float tau = _1246 * _1246;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1262;\n                if (_1224)\n                {\n                    _1262 = world_xy.y - (quad_fs_params[55].y * _1220);\n                }\n                else\n                {\n                    _1262 = quad_fs_params[56].y;\n                }\n                float _1283 = mix(_1262, world_xy.y, clamp(quad_fs_params[54].x / _1225, 0.0, 1.0));\n                float _1287 = world_xy.y - _1283;\n                float _1292 = _1283 - quad_fs_params[54].z;\n                float _1297 = world_xy.y - quad_fs_params[54].z;\n                bool _1300 = _1292 <= 0.0;\n                bool _1301 = !_1300;\n                bool _1307;\n                if (_1301)\n                {\n                    _1307 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1307 = _1300;\n                }\n                float _1308;\n                if (_1307)\n                {\n                    _1308 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1308 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1292, 80.0));\n                }\n                bool _1335;\n                if (_1301)\n                {\n                    _1335 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1335 = _1300;\n                }\n                float _1336;\n                if (_1335)\n                {\n                    _1336 = quad_fs_params[54].y * _1292;\n                }\n                else\n                {\n                    _1336 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1292, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1361 = _1297 <= 0.0;\n                bool _1368;\n                if (!_1361)\n                {\n                    _1368 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1368 = _1361;\n                }\n                float _1369;\n                if (_1368)\n                {\n                    _1369 = quad_fs_params[54].y * _1297;\n                }\n                else\n                {\n                    _1369 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1297, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1396;\n                if (abs(_1287) < 0.001000000047497451305389404296875)\n                {\n                    _1396 = _1308;\n                }\n                else\n                {\n                    _1396 = (_1369 - _1336) / _1287;\n                }\n                tau += (_1237 * max(_1396, 0.0));\n            }\n            vec4 _1419 = frag_color;\n            vec3 _1427 = mix(_1419.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1427.x;\n            frag_color.y = _1427.y;\n            frag_color.z = _1427.z;\n        }\n    }\n}\n\n",
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
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _132 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _138 = _132.y;\n    return vec2(_132.x, mix(_138, 1.0 - _138, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0));\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _195 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _195.x;\n    s.color.y = _195.y;\n    s.color.z = _195.z;\n}\n\nvoid main()\n{\n    vec4 _210 = texture(tex_smp, uv);\n    vec3 param = _210.xyz;\n    float param_1 = xform.y;\n    vec3 _222 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_222, _210.w) * color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(frag_color);\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\n",
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
          }
        ],
        "samplers": [
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
