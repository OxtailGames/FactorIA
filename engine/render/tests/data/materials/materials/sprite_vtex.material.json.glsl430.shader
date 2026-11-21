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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(binding = 0) uniform sampler2D fa_vs_mask_fa_vs_mask_smp;\n\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (textureLod(fa_vs_mask_fa_vs_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125), 0.0).x * 40.0);\n}\n\nvoid main()\n{\n    vec3 _171 = position;\n    vec2 _172 = texcoord0;\n    vec4 _173 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _108 = fa_srgb_to_linear(param);\n        vec4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex(_171, _172, _173);\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D mask_mask_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _523 = texture(tex_smp, p);\n    vec3 param = _523.xyz;\n    float param_1 = xform.y;\n    vec3 _533 = fa_tex_fix(param, param_1);\n    return vec4(_533, _523.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _109 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_109.x * 255.0) + 0.5) * 256.0) + floor((_109.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0 * floor(_212 * 0.0009765625));\n    float _225 = _222 + 1.0;\n    float i1 = _225;\n    if (_225 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _212);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _262 = length(d);\n    float result = 1.0;\n    if (_262 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _273 = atan(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0)\n        {\n            _276 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875;\n        float _295 = min((size * 10.0) / _262, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0 * floor(_323 * 0.0009765625));\n            float _337 = shadow_texel(param, param_1) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _369 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _262)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _393 = 1.0 - (0.800000011920928955078125 * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _147 = atan(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0)\n    {\n        _150 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875;\n    float _167 = min(floor(_162), 1023.0);\n    float _174 = _167 + 1.0;\n    float i1 = _174;\n    if (_174 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _133) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _133) + 0.5, 0.0, 1.0), _162 - _167);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _660 = quad_fs_params[0].y > 0.5;\n    if (_660)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _684 = fa_tex_fix(param, param_1);\n        vec3 _688 = (_684 * 2.0) - vec3(1.0);\n        float _695 = cos(params.y);\n        float _697 = sin(params.y);\n        n = normalize(vec3((vec2(_695, _697) * _688.x) + ((vec2(-_697, _695) * ((mode > 5.5) ? (-1.0) : 1.0)) * _688.y), max(_688.z, 0.0500000007450580596923828125)));\n    }\n    bool _730 = !_660;\n    bool _736;\n    if (_730)\n    {\n        _736 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _736 = _730;\n    }\n    vec3 _739;\n    if (_736)\n    {\n        _739 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _739 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _739;\n    bool _756;\n    if (_736)\n    {\n        _756 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _756 = _736;\n    }\n    if (_756)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _876;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _794;\n        if (!_736)\n        {\n            _794 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _794 = _736;\n        }\n        if (_794)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _820 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_820) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _840 = vec3(_820, quad_fs_params[i * 1 + 5].z);\n            l = _840 / vec3(max(length(_840), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_820;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_660)\n        {\n            _876 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _876 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _876));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _904 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _908 = uv * _904;\n    float _914 = _904.x;\n    float _916 = _904.y;\n    float _918 = clamp(shape_rs.x, 0.0, min(_914, _916));\n    vec2 _929 = (abs(_908) - _904) + vec2(_918);\n    float d = (length(max(_929, vec2(0.0))) + min(max(_929.x, _929.y), 0.0)) - _918;\n    float ax = params.y;\n    bool _950 = params.y > 15.0;\n    if (_950)\n    {\n        ax -= 20.0;\n    }\n    float _961;\n    if (ax <= (-1.5))\n    {\n        _961 = (-2.0) - ax;\n    }\n    else\n    {\n        _961 = 0.0;\n    }\n    if (_961 > 0.0)\n    {\n        float _975 = _961 * 0.5;\n        d = abs(d + _975) - _975;\n    }\n    float _983 = fwidth(d);\n    float _984 = max(_983, 9.9999997473787516355514526367188e-05);\n    float _994 = clamp(0.5 - (d / max(shape_rs.y, _984)), 0.0, 1.0);\n    float _999;\n    if (shape_rs.y > _984)\n    {\n        _999 = (_994 * _994) * (3.0 - (2.0 * _994));\n    }\n    else\n    {\n        _999 = _994;\n    }\n    vec4 c = color;\n    bool _1021 = (_961 <= 0.0) && (ax > (-0.5));\n    if (_1021)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1036 = cos(ax);\n            float _1038 = sin(ax);\n            g = ((dot(_908, vec2(_1036, _1038)) / max((abs(_1036) * _914) + (abs(_1038) * _916), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_950)\n        {\n            vec4 _1081 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1081;\n            vec3 param = _1081.xyz;\n            float param_1 = xform.y;\n            vec3 _1088 = fa_tex_fix(param, param_1);\n            vec4 _1784 = c;\n            _1784.x = _1088.x;\n            _1784.y = _1088.y;\n            _1784.z = _1088.z;\n            c = _1784;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1100 = scene_rgb(param_2);\n            vec4 _1125 = mix(vec4(color.xyz * color.w, color.w), vec4(_1100 * color2.w, color2.w), vec4(g));\n            float _1127 = _1125.w;\n            vec3 _1130;\n            if (_1127 > 9.9999997473787516355514526367188e-06)\n            {\n                _1130 = _1125.xyz / vec3(_1127);\n            }\n            else\n            {\n                _1130 = color.xyz;\n            }\n            c = vec4(_1130, _1127);\n        }\n    }\n    vec4 _1793 = c;\n    _1793.w = _1793.w * _999;\n    c = _1793;\n    if (_1021 || (shape_rs.y > 0.0))\n    {\n        float _1171 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1180 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1180 + vec3(_1171 * 0.0039215688593685626983642578125);\n            vec3 _1186 = fa_srgb_to_linear(param_4);\n            vec4 _1796 = c;\n            _1796.x = _1186.x;\n            _1796.y = _1186.y;\n            _1796.z = _1186.z;\n            c = _1796;\n        }\n        else\n        {\n            vec4 _1196 = c;\n            vec3 _1199 = _1196.xyz + vec3(_1171 * 0.0039215688593685626983642578125);\n            vec4 _1803 = _1196;\n            _1803.x = _1199.x;\n            _1803.y = _1199.y;\n            _1803.z = _1199.z;\n            c = _1803;\n        }\n        vec4 _1808 = c;\n        _1808.w = clamp(_1808.w + ((_1171 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1808.w)), 0.0, 1.0);\n        c = _1808;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _571 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _575 = _571.y;\n    return vec2(_571.x, mix(_575, 1.0 - _575, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _614 = base_mode < 0.5;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _626);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _646 = texture(mask_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _646.x;\n    s.color.y = _646.y;\n    s.color.z = _646.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1226 = params.x > 31.5;\n    if (_1226)\n    {\n        mode -= 32.0;\n    }\n    float _1234 = mode;\n    bool _1236 = _1234 > 15.5;\n    if (_1236)\n    {\n        mode -= 16.0;\n    }\n    float _1244 = mode;\n    bool _1246 = _1244 > 7.5;\n    if (_1246)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1236)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1236)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1310 = tex_color(param_5) * color;\n                vec4 param_6 = _1310;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1310.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1345 = length(uv);\n                    float _1348 = fwidth(_1345);\n                    float _1349 = max(_1348, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1345) / _1349) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1345) / _1349) + 0.5, 0.0, 1.0) * clamp(((_1345 - params.y) / _1349) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1389 = clamp(1.0 - _1345, 0.0, 1.0);\n                            cov = (_1389 * _1389) * (3.0 - (2.0 * _1389));\n                        }\n                    }\n                    vec3 _1398;\n                    if (_1236)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1398 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1398 = color.xyz;\n                    }\n                    frag_color = vec4(_1398, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1737 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1737);\n    fragment(param_11, param_12);\n    _1737 = param_12.color;\n    frag_color = param_12.color;\n    if (_1226)\n    {\n        vec4 _1436 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1441 = scene_rgb(param_13);\n        vec3 _1445 = mix(_1436.xyz, _1441, vec3(color2.w));\n        frag_color.x = _1445.x;\n        frag_color.y = _1445.y;\n        frag_color.z = _1445.z;\n    }\n    if (_1246)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1469 = quad_fs_params[53].w > 0.0;\n    bool _1477;\n    if (!_1469)\n    {\n        _1477 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1477 = _1469;\n    }\n    if (_1477)\n    {\n        vec3 _1491 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1498 = dot(_1491, quad_fs_params[55].xyz);\n        bool _1502 = quad_fs_params[55].w > 0.5;\n        float _1503;\n        if (_1502)\n        {\n            _1503 = _1498;\n        }\n        else\n        {\n            _1503 = length(_1491);\n        }\n        float _1515 = _1503 - quad_fs_params[54].x;\n        if (_1515 > 0.0)\n        {\n            float _1524 = quad_fs_params[53].w * _1515;\n            float tau = _1524 * _1524;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1540;\n                if (_1502)\n                {\n                    _1540 = world_xy.y - (quad_fs_params[55].y * _1498);\n                }\n                else\n                {\n                    _1540 = quad_fs_params[56].y;\n                }\n                float _1561 = mix(_1540, world_xy.y, clamp(quad_fs_params[54].x / _1503, 0.0, 1.0));\n                float _1565 = world_xy.y - _1561;\n                float _1570 = _1561 - quad_fs_params[54].z;\n                float _1575 = world_xy.y - quad_fs_params[54].z;\n                bool _1578 = _1570 <= 0.0;\n                bool _1579 = !_1578;\n                bool _1585;\n                if (_1579)\n                {\n                    _1585 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1585 = _1578;\n                }\n                float _1586;\n                if (_1585)\n                {\n                    _1586 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1586 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1570, 80.0));\n                }\n                bool _1613;\n                if (_1579)\n                {\n                    _1613 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1613 = _1578;\n                }\n                float _1614;\n                if (_1613)\n                {\n                    _1614 = quad_fs_params[54].y * _1570;\n                }\n                else\n                {\n                    _1614 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1570, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1639 = _1575 <= 0.0;\n                bool _1646;\n                if (!_1639)\n                {\n                    _1646 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1646 = _1639;\n                }\n                float _1647;\n                if (_1646)\n                {\n                    _1647 = quad_fs_params[54].y * _1575;\n                }\n                else\n                {\n                    _1647 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1575, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1674;\n                if (abs(_1565) < 0.001000000047497451305389404296875)\n                {\n                    _1674 = _1586;\n                }\n                else\n                {\n                    _1674 = (_1647 - _1614) / _1565;\n                }\n                tau += (_1515 * max(_1674, 0.0));\n            }\n            vec4 _1697 = frag_color;\n            vec3 _1705 = mix(_1697.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1705.x;\n            frag_color.y = _1705.y;\n            frag_color.z = _1705.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_96",
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
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering"
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7,
            "glsl_name": "fa_vs_mask_fa_vs_mask_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "tex_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0,
            "glsl_name": "normal_tex_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1,
            "glsl_name": "light_tex_light_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2,
            "glsl_name": "shadow_tex_shadow_smp"
          },
          {
            "slot": 5,
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(binding = 0) uniform sampler2D fa_vs_mask_fa_vs_mask_smp;\n\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (textureLod(fa_vs_mask_fa_vs_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125), 0.0).x * 40.0);\n}\n\nvoid main()\n{\n    vec3 _171 = position;\n    vec2 _172 = texcoord0;\n    vec4 _173 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _108 = fa_srgb_to_linear(param);\n        vec4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex(_171, _172, _173);\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec4 _222 = texture(mask_mask_smp, vec2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _222.x;\n    s.color.y = _222.y;\n    s.color.z = _222.z;\n}\n\nvoid main()\n{\n    vec4 _237 = texture(tex_smp, uv);\n    vec3 param = _237.xyz;\n    float param_1 = xform.y;\n    vec3 _248 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_248, _237.w) * color;\n    float param_2 = 0.0;\n    vec4 _302 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_302);\n    fragment(param_3, param_4);\n    _302 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_96",
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
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering"
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7,
            "glsl_name": "fa_vs_mask_fa_vs_mask_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "tex_smp"
          },
          {
            "slot": 2,
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
