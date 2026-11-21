{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _147 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _147;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _507 = fa_linear_to_srgb(param);\n        c = _507;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _515 = fa_srgb_to_linear(param_1);\n            c = _515;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _526 = texture(tex_smp, p);\n    vec3 param = _526.xyz;\n    float param_1 = xform.y;\n    vec3 _536 = fa_tex_fix(param, param_1);\n    return vec4(_536, _526.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _112 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_112.x * 255.0) + 0.5) * 256.0) + floor((_112.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _215 = floor(tt);\n    float _225 = _215 - (1024.0 * floor(_215 * 0.0009765625));\n    float _228 = _225 + 1.0;\n    float i1 = _228;\n    if (_228 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _225;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _215);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _265 = length(d);\n    float result = 1.0;\n    if (_265 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _276 = atan(d.y, d.x);\n        float a = _276;\n        float _279;\n        if (_276 < 0.0)\n        {\n            _279 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _279 = a;\n        }\n        a = _279;\n        float _289 = _279 * 162.9746551513671875;\n        float _298 = min((size * 10.0) / _265, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _326 = floor(_289 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _298));\n            float param = v;\n            float param_1 = _326 - (1024.0 * floor(_326 * 0.0009765625));\n            float _340 = shadow_texel(param, param_1) * radius;\n            if (_340 < _265)\n            {\n                sum += _340;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _372 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _265)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _390 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _396 = 1.0 - (0.800000011920928955078125 * abs(_390));\n                float param_2 = v;\n                float param_3 = _289 + (_390 * _372);\n                float param_4 = _265;\n                float param_5 = radius;\n                acc += (_396 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _396;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _136 = length(d);\n    if (_136 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _150 = atan(d.y, d.x);\n    float a = _150;\n    float _153;\n    if (_150 < 0.0)\n    {\n        _153 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _153 = a;\n    }\n    a = _153;\n    float _165 = _153 * 162.9746551513671875;\n    float _170 = min(floor(_165), 1023.0);\n    float _177 = _170 + 1.0;\n    float i1 = _177;\n    if (_177 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _170;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _136) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _136) + 0.5, 0.0, 1.0), _165 - _170);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _670 = quad_fs_params[0].y > 0.5;\n    if (_670)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _694 = fa_tex_fix(param, param_1);\n        vec3 _698 = (_694 * 2.0) - vec3(1.0);\n        float _705 = cos(params.y);\n        float _707 = sin(params.y);\n        n = normalize(vec3((vec2(_705, _707) * _698.x) + ((vec2(-_707, _705) * ((mode > 5.5) ? (-1.0) : 1.0)) * _698.y), max(_698.z, 0.0500000007450580596923828125)));\n    }\n    bool _741 = !_670;\n    bool _747;\n    if (_741)\n    {\n        _747 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _747 = _741;\n    }\n    vec3 _750;\n    if (_747)\n    {\n        _750 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _750 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _750;\n    bool _767;\n    if (_747)\n    {\n        _767 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _767 = _747;\n    }\n    if (_767)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _887;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _805;\n        if (!_747)\n        {\n            _805 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _805 = _747;\n        }\n        if (_805)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _831 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_831) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _851 = vec3(_831, quad_fs_params[i * 1 + 5].z);\n            l = _851 / vec3(max(length(_851), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_831;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_670)\n        {\n            _887 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _887 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _887));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _553 = fa_srgb_to_linear(param);\n        c = _553;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _915 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _919 = uv * _915;\n    float _925 = _915.x;\n    float _927 = _915.y;\n    float _929 = clamp(shape_rs.x, 0.0, min(_925, _927));\n    vec2 _940 = (abs(_919) - _915) + vec2(_929);\n    float d = (length(max(_940, vec2(0.0))) + min(max(_940.x, _940.y), 0.0)) - _929;\n    float ax = params.y;\n    bool _961 = params.y > 15.0;\n    if (_961)\n    {\n        ax -= 20.0;\n    }\n    float _972;\n    if (ax <= (-1.5))\n    {\n        _972 = (-2.0) - ax;\n    }\n    else\n    {\n        _972 = 0.0;\n    }\n    if (_972 > 0.0)\n    {\n        float _986 = _972 * 0.5;\n        d = abs(d + _986) - _986;\n    }\n    float _994 = fwidth(d);\n    float _995 = max(_994, 9.9999997473787516355514526367188e-05);\n    float _1005 = clamp(0.5 - (d / max(shape_rs.y, _995)), 0.0, 1.0);\n    float _1010;\n    if (shape_rs.y > _995)\n    {\n        _1010 = (_1005 * _1005) * (3.0 - (2.0 * _1005));\n    }\n    else\n    {\n        _1010 = _1005;\n    }\n    vec4 c = color;\n    bool _1032 = (_972 <= 0.0) && (ax > (-0.5));\n    if (_1032)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1047 = cos(ax);\n            float _1049 = sin(ax);\n            g = ((dot(_919, vec2(_1047, _1049)) / max((abs(_1047) * _925) + (abs(_1049) * _927), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_961)\n        {\n            vec4 _1092 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1092;\n            vec3 param = _1092.xyz;\n            float param_1 = xform.y;\n            vec3 _1099 = fa_tex_fix(param, param_1);\n            vec4 _1795 = c;\n            _1795.x = _1099.x;\n            _1795.y = _1099.y;\n            _1795.z = _1099.z;\n            c = _1795;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1111 = scene_rgb(param_2);\n            vec4 _1136 = mix(vec4(color.xyz * color.w, color.w), vec4(_1111 * color2.w, color2.w), vec4(g));\n            float _1138 = _1136.w;\n            vec3 _1141;\n            if (_1138 > 9.9999997473787516355514526367188e-06)\n            {\n                _1141 = _1136.xyz / vec3(_1138);\n            }\n            else\n            {\n                _1141 = color.xyz;\n            }\n            c = vec4(_1141, _1138);\n        }\n    }\n    vec4 _1804 = c;\n    _1804.w = _1804.w * _1010;\n    c = _1804;\n    if (_1032 || (shape_rs.y > 0.0))\n    {\n        float _1182 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1191 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1191 + vec3(_1182 * 0.0039215688593685626983642578125);\n            vec3 _1197 = fa_srgb_to_linear(param_4);\n            vec4 _1807 = c;\n            _1807.x = _1197.x;\n            _1807.y = _1197.y;\n            _1807.z = _1197.z;\n            c = _1807;\n        }\n        else\n        {\n            vec4 _1207 = c;\n            vec3 _1210 = _1207.xyz + vec3(_1182 * 0.0039215688593685626983642578125);\n            vec4 _1814 = _1207;\n            _1814.x = _1210.x;\n            _1814.y = _1210.y;\n            _1814.z = _1210.z;\n            c = _1814;\n        }\n        vec4 _1819 = c;\n        _1819.w = clamp(_1819.w + ((_1182 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1819.w)), 0.0, 1.0);\n        c = _1819;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _579 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _583 = _579.y;\n    return vec2(_579.x, mix(_583, 1.0 - _583, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _622 = base_mode < 0.5;\n    bool _633;\n    if (!_622)\n    {\n        _633 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _633 = _622;\n    }\n    float _634;\n    if (_633)\n    {\n        _634 = shape_half.x;\n    }\n    else\n    {\n        _634 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _634);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _559 = scene_rgb(param);\n    return _559;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _655 = s.color;\n    vec3 _657 = _655.xyz * fa_scene_rgb(param);\n    s.color.x = _657.x;\n    s.color.y = _657.y;\n    s.color.z = _657.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1237 = params.x > 31.5;\n    if (_1237)\n    {\n        mode -= 32.0;\n    }\n    float _1245 = mode;\n    bool _1247 = _1245 > 15.5;\n    if (_1247)\n    {\n        mode -= 16.0;\n    }\n    float _1255 = mode;\n    bool _1257 = _1255 > 7.5;\n    if (_1257)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1247)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1247)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1321 = tex_color(param_5) * color;\n                vec4 param_6 = _1321;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1321.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1356 = length(uv);\n                    float _1359 = fwidth(_1356);\n                    float _1360 = max(_1359, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1356) / _1360) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1356) / _1360) + 0.5, 0.0, 1.0) * clamp(((_1356 - params.y) / _1360) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1400 = clamp(1.0 - _1356, 0.0, 1.0);\n                            cov = (_1400 * _1400) * (3.0 - (2.0 * _1400));\n                        }\n                    }\n                    vec3 _1409;\n                    if (_1247)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1409 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1409 = color.xyz;\n                    }\n                    frag_color = vec4(_1409, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1748 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1748);\n    fragment(param_11, param_12);\n    _1748 = param_12.color;\n    frag_color = param_12.color;\n    if (_1237)\n    {\n        vec4 _1447 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1452 = scene_rgb(param_13);\n        vec3 _1456 = mix(_1447.xyz, _1452, vec3(color2.w));\n        frag_color.x = _1456.x;\n        frag_color.y = _1456.y;\n        frag_color.z = _1456.z;\n    }\n    if (_1257)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1480 = quad_fs_params[53].w > 0.0;\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    if (_1488)\n    {\n        vec3 _1502 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1509 = dot(_1502, quad_fs_params[55].xyz);\n        bool _1513 = quad_fs_params[55].w > 0.5;\n        float _1514;\n        if (_1513)\n        {\n            _1514 = _1509;\n        }\n        else\n        {\n            _1514 = length(_1502);\n        }\n        float _1526 = _1514 - quad_fs_params[54].x;\n        if (_1526 > 0.0)\n        {\n            float _1535 = quad_fs_params[53].w * _1526;\n            float tau = _1535 * _1535;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1551;\n                if (_1513)\n                {\n                    _1551 = world_xy.y - (quad_fs_params[55].y * _1509);\n                }\n                else\n                {\n                    _1551 = quad_fs_params[56].y;\n                }\n                float _1572 = mix(_1551, world_xy.y, clamp(quad_fs_params[54].x / _1514, 0.0, 1.0));\n                float _1576 = world_xy.y - _1572;\n                float _1581 = _1572 - quad_fs_params[54].z;\n                float _1586 = world_xy.y - quad_fs_params[54].z;\n                bool _1589 = _1581 <= 0.0;\n                bool _1590 = !_1589;\n                bool _1596;\n                if (_1590)\n                {\n                    _1596 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1596 = _1589;\n                }\n                float _1597;\n                if (_1596)\n                {\n                    _1597 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1597 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1581, 80.0));\n                }\n                bool _1624;\n                if (_1590)\n                {\n                    _1624 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1624 = _1589;\n                }\n                float _1625;\n                if (_1624)\n                {\n                    _1625 = quad_fs_params[54].y * _1581;\n                }\n                else\n                {\n                    _1625 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1581, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1650 = _1586 <= 0.0;\n                bool _1657;\n                if (!_1650)\n                {\n                    _1657 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1657 = _1650;\n                }\n                float _1658;\n                if (_1657)\n                {\n                    _1658 = quad_fs_params[54].y * _1586;\n                }\n                else\n                {\n                    _1658 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1586, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1685;\n                if (abs(_1576) < 0.001000000047497451305389404296875)\n                {\n                    _1685 = _1597;\n                }\n                else\n                {\n                    _1685 = (_1658 - _1625) / _1576;\n                }\n                tau += (_1526 * max(_1685, 0.0));\n            }\n            vec4 _1708 = frag_color;\n            vec3 _1716 = mix(_1708.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1716.x;\n            frag_color.y = _1716.y;\n            frag_color.z = _1716.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_573",
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
            "inst_name": "_648",
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
