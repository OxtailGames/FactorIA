{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "glsl430",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _150 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _150;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _523 = texture(tex_smp, p);\n    vec3 param = _523.xyz;\n    float param_1 = xform.y;\n    vec3 _533 = fa_tex_fix(param, param_1);\n    return vec4(_533, _523.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _109 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_109.x * 255.0) + 0.5) * 256.0) + floor((_109.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0 * floor(_212 * 0.0009765625));\n    float _225 = _222 + 1.0;\n    float i1 = _225;\n    if (_225 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _212);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _262 = length(d);\n    float result = 1.0;\n    if (_262 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _273 = atan(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0)\n        {\n            _276 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875;\n        float _295 = min((size * 10.0) / _262, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0 * floor(_323 * 0.0009765625));\n            float _337 = shadow_texel(param, param_1) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _369 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _262)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _393 = 1.0 - (0.800000011920928955078125 * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _147 = atan(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0)\n    {\n        _150 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875;\n    float _167 = min(floor(_162), 1023.0);\n    float _174 = _167 + 1.0;\n    float i1 = _174;\n    if (_174 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _133) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _133) + 0.5, 0.0, 1.0), _162 - _167);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _659 = quad_fs_params[0].y > 0.5;\n    if (_659)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _683 = fa_tex_fix(param, param_1);\n        vec3 _687 = (_683 * 2.0) - vec3(1.0);\n        float _694 = cos(params.y);\n        float _696 = sin(params.y);\n        n = normalize(vec3((vec2(_694, _696) * _687.x) + ((vec2(-_696, _694) * ((mode > 5.5) ? (-1.0) : 1.0)) * _687.y), max(_687.z, 0.0500000007450580596923828125)));\n    }\n    bool _729 = !_659;\n    bool _735;\n    if (_729)\n    {\n        _735 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _735 = _729;\n    }\n    vec3 _738;\n    if (_735)\n    {\n        _738 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _738 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _738;\n    bool _755;\n    if (_735)\n    {\n        _755 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _755 = _735;\n    }\n    if (_755)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _875;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _793;\n        if (!_735)\n        {\n            _793 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _793 = _735;\n        }\n        if (_793)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _819 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_819) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _839 = vec3(_819, quad_fs_params[i * 1 + 5].z);\n            l = _839 / vec3(max(length(_839), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_819;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_659)\n        {\n            _875 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _875 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _875));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _903 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _907 = uv * _903;\n    float _913 = _903.x;\n    float _915 = _903.y;\n    float _917 = clamp(shape_rs.x, 0.0, min(_913, _915));\n    vec2 _928 = (abs(_907) - _903) + vec2(_917);\n    float d = (length(max(_928, vec2(0.0))) + min(max(_928.x, _928.y), 0.0)) - _917;\n    float ax = params.y;\n    bool _949 = params.y > 15.0;\n    if (_949)\n    {\n        ax -= 20.0;\n    }\n    float _960;\n    if (ax <= (-1.5))\n    {\n        _960 = (-2.0) - ax;\n    }\n    else\n    {\n        _960 = 0.0;\n    }\n    if (_960 > 0.0)\n    {\n        float _974 = _960 * 0.5;\n        d = abs(d + _974) - _974;\n    }\n    float _982 = fwidth(d);\n    float _983 = max(_982, 9.9999997473787516355514526367188e-05);\n    float _993 = clamp(0.5 - (d / max(shape_rs.y, _983)), 0.0, 1.0);\n    float _998;\n    if (shape_rs.y > _983)\n    {\n        _998 = (_993 * _993) * (3.0 - (2.0 * _993));\n    }\n    else\n    {\n        _998 = _993;\n    }\n    vec4 c = color;\n    bool _1020 = (_960 <= 0.0) && (ax > (-0.5));\n    if (_1020)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1035 = cos(ax);\n            float _1037 = sin(ax);\n            g = ((dot(_907, vec2(_1035, _1037)) / max((abs(_1035) * _913) + (abs(_1037) * _915), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_949)\n        {\n            vec4 _1080 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1080;\n            vec3 param = _1080.xyz;\n            float param_1 = xform.y;\n            vec3 _1087 = fa_tex_fix(param, param_1);\n            vec4 _1783 = c;\n            _1783.x = _1087.x;\n            _1783.y = _1087.y;\n            _1783.z = _1087.z;\n            c = _1783;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1099 = scene_rgb(param_2);\n            vec4 _1124 = mix(vec4(color.xyz * color.w, color.w), vec4(_1099 * color2.w, color2.w), vec4(g));\n            float _1126 = _1124.w;\n            vec3 _1129;\n            if (_1126 > 9.9999997473787516355514526367188e-06)\n            {\n                _1129 = _1124.xyz / vec3(_1126);\n            }\n            else\n            {\n                _1129 = color.xyz;\n            }\n            c = vec4(_1129, _1126);\n        }\n    }\n    vec4 _1792 = c;\n    _1792.w = _1792.w * _998;\n    c = _1792;\n    if (_1020 || (shape_rs.y > 0.0))\n    {\n        float _1170 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1179 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1179 + vec3(_1170 * 0.0039215688593685626983642578125);\n            vec3 _1185 = fa_srgb_to_linear(param_4);\n            vec4 _1795 = c;\n            _1795.x = _1185.x;\n            _1795.y = _1185.y;\n            _1795.z = _1185.z;\n            c = _1795;\n        }\n        else\n        {\n            vec4 _1195 = c;\n            vec3 _1198 = _1195.xyz + vec3(_1170 * 0.0039215688593685626983642578125);\n            vec4 _1802 = _1195;\n            _1802.x = _1198.x;\n            _1802.y = _1198.y;\n            _1802.z = _1198.z;\n            c = _1802;\n        }\n        vec4 _1807 = c;\n        _1807.w = clamp(_1807.w + ((_1170 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1807.w)), 0.0, 1.0);\n        c = _1807;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _571 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _575 = _571.y;\n    return vec2(_571.x, mix(_575, 1.0 - _575, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _614 = base_mode < 0.5;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _626);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _645 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _645.x;\n    s.color.y = _645.y;\n    s.color.z = _645.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1225 = params.x > 31.5;\n    if (_1225)\n    {\n        mode -= 32.0;\n    }\n    float _1233 = mode;\n    bool _1235 = _1233 > 15.5;\n    if (_1235)\n    {\n        mode -= 16.0;\n    }\n    float _1243 = mode;\n    bool _1245 = _1243 > 7.5;\n    if (_1245)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1235)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1235)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1309 = tex_color(param_5) * color;\n                vec4 param_6 = _1309;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1309.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1344 = length(uv);\n                    float _1347 = fwidth(_1344);\n                    float _1348 = max(_1347, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1344) / _1348) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1344) / _1348) + 0.5, 0.0, 1.0) * clamp(((_1344 - params.y) / _1348) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1388 = clamp(1.0 - _1344, 0.0, 1.0);\n                            cov = (_1388 * _1388) * (3.0 - (2.0 * _1388));\n                        }\n                    }\n                    vec3 _1397;\n                    if (_1235)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1397 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1397 = color.xyz;\n                    }\n                    frag_color = vec4(_1397, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1736 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1736);\n    fragment(param_11, param_12);\n    _1736 = param_12.color;\n    frag_color = param_12.color;\n    if (_1225)\n    {\n        vec4 _1435 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1440 = scene_rgb(param_13);\n        vec3 _1444 = mix(_1435.xyz, _1440, vec3(color2.w));\n        frag_color.x = _1444.x;\n        frag_color.y = _1444.y;\n        frag_color.z = _1444.z;\n    }\n    if (_1245)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1468 = quad_fs_params[53].w > 0.0;\n    bool _1476;\n    if (!_1468)\n    {\n        _1476 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1476 = _1468;\n    }\n    if (_1476)\n    {\n        vec3 _1490 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1497 = dot(_1490, quad_fs_params[55].xyz);\n        bool _1501 = quad_fs_params[55].w > 0.5;\n        float _1502;\n        if (_1501)\n        {\n            _1502 = _1497;\n        }\n        else\n        {\n            _1502 = length(_1490);\n        }\n        float _1514 = _1502 - quad_fs_params[54].x;\n        if (_1514 > 0.0)\n        {\n            float _1523 = quad_fs_params[53].w * _1514;\n            float tau = _1523 * _1523;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1539;\n                if (_1501)\n                {\n                    _1539 = world_xy.y - (quad_fs_params[55].y * _1497);\n                }\n                else\n                {\n                    _1539 = quad_fs_params[56].y;\n                }\n                float _1560 = mix(_1539, world_xy.y, clamp(quad_fs_params[54].x / _1502, 0.0, 1.0));\n                float _1564 = world_xy.y - _1560;\n                float _1569 = _1560 - quad_fs_params[54].z;\n                float _1574 = world_xy.y - quad_fs_params[54].z;\n                bool _1577 = _1569 <= 0.0;\n                bool _1578 = !_1577;\n                bool _1584;\n                if (_1578)\n                {\n                    _1584 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1584 = _1577;\n                }\n                float _1585;\n                if (_1584)\n                {\n                    _1585 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1585 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1569, 80.0));\n                }\n                bool _1612;\n                if (_1578)\n                {\n                    _1612 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1612 = _1577;\n                }\n                float _1613;\n                if (_1612)\n                {\n                    _1613 = quad_fs_params[54].y * _1569;\n                }\n                else\n                {\n                    _1613 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1569, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1638 = _1574 <= 0.0;\n                bool _1645;\n                if (!_1638)\n                {\n                    _1645 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1645 = _1638;\n                }\n                float _1646;\n                if (_1645)\n                {\n                    _1646 = quad_fs_params[54].y * _1574;\n                }\n                else\n                {\n                    _1646 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1574, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1673;\n                if (abs(_1564) < 0.001000000047497451305389404296875)\n                {\n                    _1673 = _1585;\n                }\n                else\n                {\n                    _1673 = (_1646 - _1613) / _1564;\n                }\n                tau += (_1514 * max(_1673, 0.0));\n            }\n            vec4 _1696 = frag_color;\n            vec3 _1704 = mix(_1696.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1704.x;\n            frag_color.y = _1704.y;\n            frag_color.z = _1704.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_565",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _221 = texture(mask_mask_smp, vec2(0.0500000007450580596923828125));\n    s.color.x = _221.x;\n    s.color.y = _221.y;\n    s.color.z = _221.z;\n}\n\nvoid main()\n{\n    vec4 _236 = texture(tex_smp, uv);\n    vec3 param = _236.xyz;\n    float param_1 = xform.y;\n    vec3 _247 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_247, _236.w) * color;\n    float param_2 = 0.0;\n    vec4 _301 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_301);\n    fragment(param_3, param_4);\n    _301 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
