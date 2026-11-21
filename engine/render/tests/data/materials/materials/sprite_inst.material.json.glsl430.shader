{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _513 = fa_linear_to_srgb(param);\n        c = _513;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _521 = fa_srgb_to_linear(param_1);\n            c = _521;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _532 = texture(tex_smp, p);\n    vec3 param = _532.xyz;\n    float param_1 = xform.y;\n    vec3 _542 = fa_tex_fix(param, param_1);\n    return vec4(_542, _532.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _118 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_118.x * 255.0) + 0.5) * 256.0) + floor((_118.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _221 = floor(tt);\n    float _231 = _221 - (1024.0 * floor(_221 * 0.0009765625));\n    float _234 = _231 + 1.0;\n    float i1 = _234;\n    if (_234 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _231;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5, 0.0, 1.0), tt - _221);\n}\n\nfloat light_shadow_soft(float v, float size, vec2 d, float radius)\n{\n    float _271 = length(d);\n    float result = 1.0;\n    if (_271 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _282 = atan(d.y, d.x);\n        float a = _282;\n        float _285;\n        if (_282 < 0.0)\n        {\n            _285 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _285 = a;\n        }\n        a = _285;\n        float _295 = _285 * 162.9746551513671875;\n        float _304 = min((size * 10.0) / _271, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _332 = floor(_295 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _304));\n            float param = v;\n            float param_1 = _332 - (1024.0 * floor(_332 * 0.0009765625));\n            float _346 = shadow_texel(param, param_1) * radius;\n            if (_346 < _271)\n            {\n                sum += _346;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _378 = min(size * ((1.0 / max(sum / n, 1.0)) - (1.0 / _271)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _396 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _402 = 1.0 - (0.800000011920928955078125 * abs(_396));\n                float param_2 = v;\n                float param_3 = _295 + (_396 * _378);\n                float param_4 = _271;\n                float param_5 = radius;\n                acc += (_402 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _402;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _142 = length(d);\n    if (_142 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _156 = atan(d.y, d.x);\n    float a = _156;\n    float _159;\n    if (_156 < 0.0)\n    {\n        _159 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _159 = a;\n    }\n    a = _159;\n    float _171 = _159 * 162.9746551513671875;\n    float _176 = min(floor(_171), 1023.0);\n    float _183 = _176 + 1.0;\n    float i1 = _183;\n    if (_183 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _176;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _142) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _142) + 0.5, 0.0, 1.0), _171 - _176);\n}\n\nfloat light_shadow_sized(float v, float size, vec2 d, float radius)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        vec2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        vec2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _689 = quad_fs_params[0].y > 0.5;\n    if (_689)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _713 = fa_tex_fix(param, param_1);\n        vec3 _717 = (_713 * 2.0) - vec3(1.0);\n        float _724 = cos(params.y);\n        float _726 = sin(params.y);\n        n = normalize(vec3((vec2(_724, _726) * _717.x) + ((vec2(-_726, _724) * ((mode > 5.5) ? (-1.0) : 1.0)) * _717.y), max(_717.z, 0.0500000007450580596923828125)));\n    }\n    bool _760 = !_689;\n    bool _766;\n    if (_760)\n    {\n        _766 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _766 = _760;\n    }\n    vec3 _769;\n    if (_766)\n    {\n        _769 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _769 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _769;\n    bool _786;\n    if (_766)\n    {\n        _786 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _786 = _766;\n    }\n    if (_786)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _906;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _824;\n        if (!_766)\n        {\n            _824 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _824 = _766;\n        }\n        if (_824)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _850 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_850) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _870 = vec3(_850, quad_fs_params[i * 1 + 5].z);\n            l = _870 / vec3(max(length(_870), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                float param_3 = quad_fs_params[i * 1 + 37].y;\n                vec2 param_4 = -_850;\n                float param_5 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_689)\n        {\n            _906 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _906 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _906));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _559 = fa_srgb_to_linear(param);\n        c = _559;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _934 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _938 = uv * _934;\n    float _944 = _934.x;\n    float _946 = _934.y;\n    float _948 = clamp(shape_rs.x, 0.0, min(_944, _946));\n    vec2 _959 = (abs(_938) - _934) + vec2(_948);\n    float d = (length(max(_959, vec2(0.0))) + min(max(_959.x, _959.y), 0.0)) - _948;\n    float ax = params.y;\n    bool _980 = params.y > 15.0;\n    if (_980)\n    {\n        ax -= 20.0;\n    }\n    float _991;\n    if (ax <= (-1.5))\n    {\n        _991 = (-2.0) - ax;\n    }\n    else\n    {\n        _991 = 0.0;\n    }\n    if (_991 > 0.0)\n    {\n        float _1005 = _991 * 0.5;\n        d = abs(d + _1005) - _1005;\n    }\n    float _1013 = fwidth(d);\n    float _1014 = max(_1013, 9.9999997473787516355514526367188e-05);\n    float _1024 = clamp(0.5 - (d / max(shape_rs.y, _1014)), 0.0, 1.0);\n    float _1029;\n    if (shape_rs.y > _1014)\n    {\n        _1029 = (_1024 * _1024) * (3.0 - (2.0 * _1024));\n    }\n    else\n    {\n        _1029 = _1024;\n    }\n    vec4 c = color;\n    bool _1051 = (_991 <= 0.0) && (ax > (-0.5));\n    if (_1051)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1066 = cos(ax);\n            float _1068 = sin(ax);\n            g = ((dot(_938, vec2(_1066, _1068)) / max((abs(_1066) * _944) + (abs(_1068) * _946), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_980)\n        {\n            vec4 _1111 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1111;\n            vec3 param = _1111.xyz;\n            float param_1 = xform.y;\n            vec3 _1118 = fa_tex_fix(param, param_1);\n            vec4 _1814 = c;\n            _1814.x = _1118.x;\n            _1814.y = _1118.y;\n            _1814.z = _1118.z;\n            c = _1814;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1130 = scene_rgb(param_2);\n            vec4 _1155 = mix(vec4(color.xyz * color.w, color.w), vec4(_1130 * color2.w, color2.w), vec4(g));\n            float _1157 = _1155.w;\n            vec3 _1160;\n            if (_1157 > 9.9999997473787516355514526367188e-06)\n            {\n                _1160 = _1155.xyz / vec3(_1157);\n            }\n            else\n            {\n                _1160 = color.xyz;\n            }\n            c = vec4(_1160, _1157);\n        }\n    }\n    vec4 _1823 = c;\n    _1823.w = _1823.w * _1029;\n    c = _1823;\n    if (_1051 || (shape_rs.y > 0.0))\n    {\n        float _1201 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1210 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1210 + vec3(_1201 * 0.0039215688593685626983642578125);\n            vec3 _1216 = fa_srgb_to_linear(param_4);\n            vec4 _1826 = c;\n            _1826.x = _1216.x;\n            _1826.y = _1216.y;\n            _1826.z = _1216.z;\n            c = _1826;\n        }\n        else\n        {\n            vec4 _1226 = c;\n            vec3 _1229 = _1226.xyz + vec3(_1201 * 0.0039215688593685626983642578125);\n            vec4 _1833 = _1226;\n            _1833.x = _1229.x;\n            _1833.y = _1229.y;\n            _1833.z = _1229.z;\n            c = _1833;\n        }\n        vec4 _1838 = c;\n        _1838.w = clamp(_1838.w + ((_1201 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1838.w)), 0.0, 1.0);\n        c = _1838;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _585 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _589 = _585.y;\n    return vec2(_585.x, mix(_589, 1.0 - _589, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _628 = base_mode < 0.5;\n    bool _639;\n    if (!_628)\n    {\n        _639 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _639 = _628;\n    }\n    float _640;\n    if (_639)\n    {\n        _640 = shape_half.x;\n    }\n    else\n    {\n        _640 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _640);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _565 = scene_rgb(param);\n    return _565;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _668 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _668.x;\n    s.color.y = _668.y;\n    s.color.z = _668.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1256 = params.x > 31.5;\n    if (_1256)\n    {\n        mode -= 32.0;\n    }\n    float _1264 = mode;\n    bool _1266 = _1264 > 15.5;\n    if (_1266)\n    {\n        mode -= 16.0;\n    }\n    float _1274 = mode;\n    bool _1276 = _1274 > 7.5;\n    if (_1276)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1266)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1266)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1340 = tex_color(param_5) * color;\n                vec4 param_6 = _1340;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1340.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1375 = length(uv);\n                    float _1378 = fwidth(_1375);\n                    float _1379 = max(_1378, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1375) / _1379) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1375) / _1379) + 0.5, 0.0, 1.0) * clamp(((_1375 - params.y) / _1379) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1419 = clamp(1.0 - _1375, 0.0, 1.0);\n                            cov = (_1419 * _1419) * (3.0 - (2.0 * _1419));\n                        }\n                    }\n                    vec3 _1428;\n                    if (_1266)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1428 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1428 = color.xyz;\n                    }\n                    frag_color = vec4(_1428, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1767 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1767);\n    fragment(param_11, param_12);\n    _1767 = param_12.color;\n    frag_color = param_12.color;\n    if (_1256)\n    {\n        vec4 _1466 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1471 = scene_rgb(param_13);\n        vec3 _1475 = mix(_1466.xyz, _1471, vec3(color2.w));\n        frag_color.x = _1475.x;\n        frag_color.y = _1475.y;\n        frag_color.z = _1475.z;\n    }\n    if (_1276)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1499 = quad_fs_params[53].w > 0.0;\n    bool _1507;\n    if (!_1499)\n    {\n        _1507 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1507 = _1499;\n    }\n    if (_1507)\n    {\n        vec3 _1521 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1528 = dot(_1521, quad_fs_params[55].xyz);\n        bool _1532 = quad_fs_params[55].w > 0.5;\n        float _1533;\n        if (_1532)\n        {\n            _1533 = _1528;\n        }\n        else\n        {\n            _1533 = length(_1521);\n        }\n        float _1545 = _1533 - quad_fs_params[54].x;\n        if (_1545 > 0.0)\n        {\n            float _1554 = quad_fs_params[53].w * _1545;\n            float tau = _1554 * _1554;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1570;\n                if (_1532)\n                {\n                    _1570 = world_xy.y - (quad_fs_params[55].y * _1528);\n                }\n                else\n                {\n                    _1570 = quad_fs_params[56].y;\n                }\n                float _1591 = mix(_1570, world_xy.y, clamp(quad_fs_params[54].x / _1533, 0.0, 1.0));\n                float _1595 = world_xy.y - _1591;\n                float _1600 = _1591 - quad_fs_params[54].z;\n                float _1605 = world_xy.y - quad_fs_params[54].z;\n                bool _1608 = _1600 <= 0.0;\n                bool _1609 = !_1608;\n                bool _1615;\n                if (_1609)\n                {\n                    _1615 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1615 = _1608;\n                }\n                float _1616;\n                if (_1615)\n                {\n                    _1616 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1616 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1600, 80.0));\n                }\n                bool _1643;\n                if (_1609)\n                {\n                    _1643 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1643 = _1608;\n                }\n                float _1644;\n                if (_1643)\n                {\n                    _1644 = quad_fs_params[54].y * _1600;\n                }\n                else\n                {\n                    _1644 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1600, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1669 = _1605 <= 0.0;\n                bool _1676;\n                if (!_1669)\n                {\n                    _1676 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1676 = _1669;\n                }\n                float _1677;\n                if (_1676)\n                {\n                    _1677 = quad_fs_params[54].y * _1605;\n                }\n                else\n                {\n                    _1677 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1605, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1704;\n                if (abs(_1595) < 0.001000000047497451305389404296875)\n                {\n                    _1704 = _1616;\n                }\n                else\n                {\n                    _1704 = (_1677 - _1644) / _1595;\n                }\n                tau += (_1545 * max(_1704, 0.0));\n            }\n            vec4 _1727 = frag_color;\n            vec3 _1735 = mix(_1727.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1735.x;\n            frag_color.y = _1735.y;\n            frag_color.z = _1735.z;\n        }\n    }\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
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
            "inst_name": "_579",
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
            "inst_name": "_665",
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nuniform vec4 vs_params[6];\nlayout(location = 7) in vec4 fa_inst_d0;\nlayout(location = 8) in vec4 fa_inst_d1;\nlayout(location = 9) flat out vec4 fa_inst_v0;\nlayout(location = 10) flat out vec4 fa_inst_v1;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\nfloat shift;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid main()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    vec3 _184 = position;\n    vec2 _185 = texcoord0;\n    vec4 _186 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param_3 = color0.xyz;\n        vec3 _119 = fa_srgb_to_linear(param_3);\n        vec4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex(_184, _185, _186);\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_4.world_pos, 1.0);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nuniform vec4 quad_fs_params[59];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in vec4 fa_inst_v0;\nlayout(location = 10) flat in vec4 fa_inst_v1;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\nfloat shift;\nvec4 tint;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _167 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _172 = _167.y;\n    return vec2(_167.x, mix(_172, 1.0 - _172, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _215 = base_mode < 0.5;\n    bool _226;\n    if (!_215)\n    {\n        _226 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _226 = _215;\n    }\n    float _227;\n    if (_226)\n    {\n        _227 = shape_half.x;\n    }\n    else\n    {\n        _227 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _227);\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    vec3 param = c;\n    vec3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    vec3 param = tint.xyz;\n    vec3 _255 = fa_scene_rgb(param) * fa_material[0].x;\n    s.color.x = _255.x;\n    s.color.y = _255.y;\n    s.color.z = _255.z;\n}\n\nvoid main()\n{\n    vec4 _282 = texture(tex_smp, uv);\n    vec3 param = _282.xyz;\n    float param_1 = xform.y;\n    vec3 _291 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_291, _282.w) * color;\n    float param_2 = 0.0;\n    vec4 _345 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_345);\n    fragment(param_3, param_4);\n    _345 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
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
            "inst_name": "_160",
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
            "inst_name": "_252",
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
