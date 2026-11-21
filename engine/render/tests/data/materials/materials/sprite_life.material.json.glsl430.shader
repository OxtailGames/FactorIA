{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#version 430\n\nuniform vec4 vs_params[6];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid main()\n{\n    vec4 _144 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _82 = fa_srgb_to_linear(param);\n        vec4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(position, 1.0);\n    uv = texcoord0;\n    color = _144;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _523 = texture(tex_smp, p);\n    vec3 param = _523.xyz;\n    float param_1 = xform.y;\n    vec3 _533 = fa_tex_fix(param, param_1);\n    return vec4(_533, _523.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _109 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_109.x * 255.0) + 0.5) * 256.0) + floor((_109.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0 * floor(_212 * 0.0009765625));\n    float _225 = _222 + 1.0;\n    float i1 = _225;\n    if (_225 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _212);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _262 = length(d);\n    float result = 1.0;\n    if (_262 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _273 = atan(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0)\n        {\n            _276 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875;\n        float _295 = min((size * 10.0) / _262, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0 * floor(_323 * 0.0009765625));\n            float _337 = shadow_texel(param, param_1) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _369 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _262)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _393 = 1.0 - (0.800000011920928955078125 * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _147 = atan(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0)\n    {\n        _150 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875;\n    float _167 = min(floor(_162), 1023.0);\n    float _174 = _167 + 1.0;\n    float i1 = _174;\n    if (_174 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _133) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _133) + 0.5, 0.0, 1.0), _162 - _167);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _653 = quad_fs_params[0].y > 0.5;\n    if (_653)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _677 = fa_tex_fix(param, param_1);\n        vec3 _681 = (_677 * 2.0) - vec3(1.0);\n        float _688 = cos(params.y);\n        float _690 = sin(params.y);\n        n = normalize(vec3((vec2(_688, _690) * _681.x) + ((vec2(-_690, _688) * ((mode > 5.5) ? (-1.0) : 1.0)) * _681.y), max(_681.z, 0.0500000007450580596923828125)));\n    }\n    bool _724 = !_653;\n    bool _730;\n    if (_724)\n    {\n        _730 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _730 = _724;\n    }\n    vec3 _733;\n    if (_730)\n    {\n        _733 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _733 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _733;\n    bool _750;\n    if (_730)\n    {\n        _750 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _750 = _730;\n    }\n    if (_750)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _870;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _788;\n        if (!_730)\n        {\n            _788 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _788 = _730;\n        }\n        if (_788)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _814 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_814) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _834 = vec3(_814, quad_fs_params[i * 1 + 5].z);\n            l = _834 / vec3(max(length(_834), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_814;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_653)\n        {\n            _870 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _870 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _870));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _898 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _902 = uv * _898;\n    float _908 = _898.x;\n    float _910 = _898.y;\n    float _912 = clamp(shape_rs.x, 0.0, min(_908, _910));\n    vec2 _923 = (abs(_902) - _898) + vec2(_912);\n    float d = (length(max(_923, vec2(0.0))) + min(max(_923.x, _923.y), 0.0)) - _912;\n    float ax = params.y;\n    bool _944 = params.y > 15.0;\n    if (_944)\n    {\n        ax -= 20.0;\n    }\n    float _955;\n    if (ax <= (-1.5))\n    {\n        _955 = (-2.0) - ax;\n    }\n    else\n    {\n        _955 = 0.0;\n    }\n    if (_955 > 0.0)\n    {\n        float _969 = _955 * 0.5;\n        d = abs(d + _969) - _969;\n    }\n    float _977 = fwidth(d);\n    float _978 = max(_977, 9.9999997473787516355514526367188e-05);\n    float _988 = clamp(0.5 - (d / max(shape_rs.y, _978)), 0.0, 1.0);\n    float _993;\n    if (shape_rs.y > _978)\n    {\n        _993 = (_988 * _988) * (3.0 - (2.0 * _988));\n    }\n    else\n    {\n        _993 = _988;\n    }\n    vec4 c = color;\n    bool _1015 = (_955 <= 0.0) && (ax > (-0.5));\n    if (_1015)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1030 = cos(ax);\n            float _1032 = sin(ax);\n            g = ((dot(_902, vec2(_1030, _1032)) / max((abs(_1030) * _908) + (abs(_1032) * _910), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_944)\n        {\n            vec4 _1075 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1075;\n            vec3 param = _1075.xyz;\n            float param_1 = xform.y;\n            vec3 _1082 = fa_tex_fix(param, param_1);\n            vec4 _1778 = c;\n            _1778.x = _1082.x;\n            _1778.y = _1082.y;\n            _1778.z = _1082.z;\n            c = _1778;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1094 = scene_rgb(param_2);\n            vec4 _1119 = mix(vec4(color.xyz * color.w, color.w), vec4(_1094 * color2.w, color2.w), vec4(g));\n            float _1121 = _1119.w;\n            vec3 _1124;\n            if (_1121 > 9.9999997473787516355514526367188e-06)\n            {\n                _1124 = _1119.xyz / vec3(_1121);\n            }\n            else\n            {\n                _1124 = color.xyz;\n            }\n            c = vec4(_1124, _1121);\n        }\n    }\n    vec4 _1787 = c;\n    _1787.w = _1787.w * _993;\n    c = _1787;\n    if (_1015 || (shape_rs.y > 0.0))\n    {\n        float _1165 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1174 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1174 + vec3(_1165 * 0.0039215688593685626983642578125);\n            vec3 _1180 = fa_srgb_to_linear(param_4);\n            vec4 _1790 = c;\n            _1790.x = _1180.x;\n            _1790.y = _1180.y;\n            _1790.z = _1180.z;\n            c = _1790;\n        }\n        else\n        {\n            vec4 _1190 = c;\n            vec3 _1193 = _1190.xyz + vec3(_1165 * 0.0039215688593685626983642578125);\n            vec4 _1797 = _1190;\n            _1797.x = _1193.x;\n            _1797.y = _1193.y;\n            _1797.z = _1193.z;\n            c = _1797;\n        }\n        vec4 _1802 = c;\n        _1802.w = clamp(_1802.w + ((_1165 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1802.w)), 0.0, 1.0);\n        c = _1802;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _571 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _575 = _571.y;\n    return vec2(_571.x, mix(_575, 1.0 - _575, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _614 = base_mode < 0.5;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _626);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1220 = params.x > 31.5;\n    if (_1220)\n    {\n        mode -= 32.0;\n    }\n    float _1228 = mode;\n    bool _1230 = _1228 > 15.5;\n    if (_1230)\n    {\n        mode -= 16.0;\n    }\n    float _1238 = mode;\n    bool _1240 = _1238 > 7.5;\n    if (_1240)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1230)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1230)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1304 = tex_color(param_5) * color;\n                vec4 param_6 = _1304;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1304.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1339 = length(uv);\n                    float _1342 = fwidth(_1339);\n                    float _1343 = max(_1342, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1339) / _1343) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1339) / _1343) + 0.5, 0.0, 1.0) * clamp(((_1339 - params.y) / _1343) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1383 = clamp(1.0 - _1339, 0.0, 1.0);\n                            cov = (_1383 * _1383) * (3.0 - (2.0 * _1383));\n                        }\n                    }\n                    vec3 _1392;\n                    if (_1230)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1392 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1392 = color.xyz;\n                    }\n                    frag_color = vec4(_1392, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1731 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1731);\n    fragment(param_11, param_12);\n    _1731 = param_12.color;\n    frag_color = param_12.color;\n    if (_1220)\n    {\n        vec4 _1430 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1435 = scene_rgb(param_13);\n        vec3 _1439 = mix(_1430.xyz, _1435, vec3(color2.w));\n        frag_color.x = _1439.x;\n        frag_color.y = _1439.y;\n        frag_color.z = _1439.z;\n    }\n    if (_1240)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1463 = quad_fs_params[53].w > 0.0;\n    bool _1471;\n    if (!_1463)\n    {\n        _1471 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1471 = _1463;\n    }\n    if (_1471)\n    {\n        vec3 _1485 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1492 = dot(_1485, quad_fs_params[55].xyz);\n        bool _1496 = quad_fs_params[55].w > 0.5;\n        float _1497;\n        if (_1496)\n        {\n            _1497 = _1492;\n        }\n        else\n        {\n            _1497 = length(_1485);\n        }\n        float _1509 = _1497 - quad_fs_params[54].x;\n        if (_1509 > 0.0)\n        {\n            float _1518 = quad_fs_params[53].w * _1509;\n            float tau = _1518 * _1518;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1534;\n                if (_1496)\n                {\n                    _1534 = world_xy.y - (quad_fs_params[55].y * _1492);\n                }\n                else\n                {\n                    _1534 = quad_fs_params[56].y;\n                }\n                float _1555 = mix(_1534, world_xy.y, clamp(quad_fs_params[54].x / _1497, 0.0, 1.0));\n                float _1559 = world_xy.y - _1555;\n                float _1564 = _1555 - quad_fs_params[54].z;\n                float _1569 = world_xy.y - quad_fs_params[54].z;\n                bool _1572 = _1564 <= 0.0;\n                bool _1573 = !_1572;\n                bool _1579;\n                if (_1573)\n                {\n                    _1579 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1579 = _1572;\n                }\n                float _1580;\n                if (_1579)\n                {\n                    _1580 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1580 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1564, 80.0));\n                }\n                bool _1607;\n                if (_1573)\n                {\n                    _1607 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1607 = _1572;\n                }\n                float _1608;\n                if (_1607)\n                {\n                    _1608 = quad_fs_params[54].y * _1564;\n                }\n                else\n                {\n                    _1608 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1564, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1633 = _1569 <= 0.0;\n                bool _1640;\n                if (!_1633)\n                {\n                    _1640 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1640 = _1633;\n                }\n                float _1641;\n                if (_1640)\n                {\n                    _1641 = quad_fs_params[54].y * _1569;\n                }\n                else\n                {\n                    _1641 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1569, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1668;\n                if (abs(_1559) < 0.001000000047497451305389404296875)\n                {\n                    _1668 = _1580;\n                }\n                else\n                {\n                    _1668 = (_1641 - _1608) / _1559;\n                }\n                tau += (_1509 * max(_1668, 0.0));\n            }\n            vec4 _1691 = frag_color;\n            vec3 _1699 = mix(_1691.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1699.x;\n            frag_color.y = _1699.y;\n            frag_color.z = _1699.z;\n        }\n    }\n}\n\n",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid main()\n{\n    vec4 _230 = texture(tex_smp, uv);\n    vec3 param = _230.xyz;\n    float param_1 = xform.y;\n    vec3 _241 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_241, _230.w) * color;\n    float param_2 = 0.0;\n    vec4 _295 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_295);\n    fragment(param_3, param_4);\n    _295 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
