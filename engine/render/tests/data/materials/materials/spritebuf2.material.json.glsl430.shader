{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "extra",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    },
    {
      "name": "points",
      "binding": 1,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _86 = v.world_pos;\n    vec2 _93 = fa_vs_points.data[gl_InstanceID].pos.xy + ((_86.xy * fa_vs_points.data[gl_InstanceID].pos.w) * ((fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0)) ? 0.0 : 1.0));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _192 = position;\n    vec2 _193 = texcoord0;\n    vec4 _194 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _132 = fa_srgb_to_linear(param);\n        vec4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex param_1 = QuadVertex(_192, _193, _194);\n    vertex(param_1);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _408 = quad_fs_params[0].y > 0.5;\n    if (_408)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _432 = fa_tex_fix(param, param_1);\n        vec3 _436 = (_432 * 2.0) - vec3(1.0);\n        float _443 = cos(params.y);\n        float _445 = sin(params.y);\n        n = normalize(vec3((vec2(_443, _445) * _436.x) + ((vec2(-_445, _443) * ((mode > 5.5) ? (-1.0) : 1.0)) * _436.y), max(_436.z, 0.0500000007450580596923828125)));\n    }\n    bool _479 = !_408;\n    bool _485;\n    if (_479)\n    {\n        _485 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _485 = _479;\n    }\n    vec3 _488;\n    if (_485)\n    {\n        _488 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _488 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _488;\n    bool _505;\n    if (_485)\n    {\n        _505 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _505 = _485;\n    }\n    if (_505)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _623;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _545;\n        if (!_485)\n        {\n            _545 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _545 = _485;\n        }\n        if (_545)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _571 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_571) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _591 = vec3(_571, quad_fs_params[i * 1 + 5].z);\n            l = _591 / vec3(max(length(_591), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_571;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_408)\n        {\n            _623 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _623 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _623));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _651 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _655 = uv * _651;\n    float _661 = _651.x;\n    float _663 = _651.y;\n    float _665 = clamp(shape_rs.x, 0.0, min(_661, _663));\n    vec2 _676 = (abs(_655) - _651) + vec2(_665);\n    float d = (length(max(_676, vec2(0.0))) + min(max(_676.x, _676.y), 0.0)) - _665;\n    float ax = params.y;\n    bool _697 = params.y > 15.0;\n    if (_697)\n    {\n        ax -= 20.0;\n    }\n    float _708;\n    if (ax <= (-1.5))\n    {\n        _708 = (-2.0) - ax;\n    }\n    else\n    {\n        _708 = 0.0;\n    }\n    if (_708 > 0.0)\n    {\n        float _722 = _708 * 0.5;\n        d = abs(d + _722) - _722;\n    }\n    float _730 = fwidth(d);\n    float _731 = max(_730, 9.9999997473787516355514526367188e-05);\n    float _741 = clamp(0.5 - (d / max(shape_rs.y, _731)), 0.0, 1.0);\n    float _746;\n    if (shape_rs.y > _731)\n    {\n        _746 = (_741 * _741) * (3.0 - (2.0 * _741));\n    }\n    else\n    {\n        _746 = _741;\n    }\n    vec4 c = color;\n    bool _768 = (_708 <= 0.0) && (ax > (-0.5));\n    if (_768)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _783 = cos(ax);\n            float _785 = sin(ax);\n            g = ((dot(_655, vec2(_783, _785)) / max((abs(_783) * _661) + (abs(_785) * _663), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_697)\n        {\n            vec4 _828 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _828;\n            vec3 param = _828.xyz;\n            float param_1 = xform.y;\n            vec3 _835 = fa_tex_fix(param, param_1);\n            vec4 _1536 = c;\n            _1536.x = _835.x;\n            _1536.y = _835.y;\n            _1536.z = _835.z;\n            c = _1536;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _847 = scene_rgb(param_2);\n            vec4 _872 = mix(vec4(color.xyz * color.w, color.w), vec4(_847 * color2.w, color2.w), vec4(g));\n            float _874 = _872.w;\n            vec3 _877;\n            if (_874 > 9.9999997473787516355514526367188e-06)\n            {\n                _877 = _872.xyz / vec3(_874);\n            }\n            else\n            {\n                _877 = color.xyz;\n            }\n            c = vec4(_877, _874);\n        }\n    }\n    vec4 _1545 = c;\n    _1545.w = _1545.w * _746;\n    c = _1545;\n    if (_768 || (shape_rs.y > 0.0))\n    {\n        float _918 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _927 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _927 + vec3(_918 * 0.0039215688593685626983642578125);\n            vec3 _933 = fa_srgb_to_linear(param_4);\n            vec4 _1548 = c;\n            _1548.x = _933.x;\n            _1548.y = _933.y;\n            _1548.z = _933.z;\n            c = _1548;\n        }\n        else\n        {\n            vec4 _943 = c;\n            vec3 _946 = _943.xyz + vec3(_918 * 0.0039215688593685626983642578125);\n            vec4 _1555 = _943;\n            _1555.x = _946.x;\n            _1555.y = _946.y;\n            _1555.z = _946.z;\n            c = _1555;\n        }\n        vec4 _1560 = c;\n        _1560.w = clamp(_1560.w + ((_918 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1560.w)), 0.0, 1.0);\n        c = _1560;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _315 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _319 = _315.y;\n    return vec2(_315.x, mix(_319, 1.0 - _319, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _361 = base_mode < 0.5;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _373);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _973 = params.x > 31.5;\n    if (_973)\n    {\n        mode -= 32.0;\n    }\n    float _981 = mode;\n    bool _983 = _981 > 15.5;\n    if (_983)\n    {\n        mode -= 16.0;\n    }\n    float _991 = mode;\n    bool _993 = _991 > 7.5;\n    if (_993)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_983)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_983)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1057 = tex_color(param_5) * color;\n                vec4 param_6 = _1057;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1057.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1092 = length(uv);\n                    float _1095 = fwidth(_1092);\n                    float _1096 = max(_1095, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1092) / _1096) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1092) / _1096) + 0.5, 0.0, 1.0) * clamp(((_1092 - params.y) / _1096) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1136 = clamp(1.0 - _1092, 0.0, 1.0);\n                            cov = (_1136 * _1136) * (3.0 - (2.0 * _1136));\n                        }\n                    }\n                    vec3 _1145;\n                    if (_983)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1145 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1145 = color.xyz;\n                    }\n                    frag_color = vec4(_1145, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1489 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1489);\n    fragment(param_11, param_12);\n    _1489 = param_12.color;\n    frag_color = param_12.color;\n    if (_973)\n    {\n        vec4 _1183 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1188 = scene_rgb(param_13);\n        vec3 _1192 = mix(_1183.xyz, _1188, vec3(color2.w));\n        frag_color.x = _1192.x;\n        frag_color.y = _1192.y;\n        frag_color.z = _1192.z;\n    }\n    if (_993)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1216 = quad_fs_params[53].w > 0.0;\n    bool _1224;\n    if (!_1216)\n    {\n        _1224 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1224 = _1216;\n    }\n    if (_1224)\n    {\n        vec3 _1238 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1245 = dot(_1238, quad_fs_params[55].xyz);\n        bool _1249 = quad_fs_params[55].w > 0.5;\n        float _1250;\n        if (_1249)\n        {\n            _1250 = _1245;\n        }\n        else\n        {\n            _1250 = length(_1238);\n        }\n        float _1262 = _1250 - quad_fs_params[54].x;\n        if (_1262 > 0.0)\n        {\n            float _1271 = quad_fs_params[53].w * _1262;\n            float tau = _1271 * _1271;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1287;\n                if (_1249)\n                {\n                    _1287 = world_xy.y - (quad_fs_params[55].y * _1245);\n                }\n                else\n                {\n                    _1287 = quad_fs_params[56].y;\n                }\n                float _1308 = mix(_1287, world_xy.y, clamp(quad_fs_params[54].x / _1250, 0.0, 1.0));\n                float _1312 = world_xy.y - _1308;\n                float _1317 = _1308 - quad_fs_params[54].z;\n                float _1322 = world_xy.y - quad_fs_params[54].z;\n                bool _1325 = _1317 <= 0.0;\n                bool _1326 = !_1325;\n                bool _1332;\n                if (_1326)\n                {\n                    _1332 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1332 = _1325;\n                }\n                float _1333;\n                if (_1332)\n                {\n                    _1333 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1333 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1317, 80.0));\n                }\n                bool _1360;\n                if (_1326)\n                {\n                    _1360 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1360 = _1325;\n                }\n                float _1361;\n                if (_1360)\n                {\n                    _1361 = quad_fs_params[54].y * _1317;\n                }\n                else\n                {\n                    _1361 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1317, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1386 = _1322 <= 0.0;\n                bool _1393;\n                if (!_1386)\n                {\n                    _1393 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1393 = _1386;\n                }\n                float _1394;\n                if (_1393)\n                {\n                    _1394 = quad_fs_params[54].y * _1322;\n                }\n                else\n                {\n                    _1394 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1322, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1421;\n                if (abs(_1312) < 0.001000000047497451305389404296875)\n                {\n                    _1421 = _1333;\n                }\n                else\n                {\n                    _1421 = (_1394 - _1361) / _1312;\n                }\n                tau += (_1262 * max(_1421, 0.0));\n            }\n            vec4 _1444 = frag_color;\n            vec3 _1452 = mix(_1444.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1452.x;\n            frag_color.y = _1452.y;\n            frag_color.z = _1452.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_122",
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
            "inst_name": "_308",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _86 = v.world_pos;\n    vec2 _93 = fa_vs_points.data[gl_InstanceID].pos.xy + ((_86.xy * fa_vs_points.data[gl_InstanceID].pos.w) * ((fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0)) ? 0.0 : 1.0));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _192 = position;\n    vec2 _193 = texcoord0;\n    vec4 _194 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _132 = fa_srgb_to_linear(param);\n        vec4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex param_1 = QuadVertex(_192, _193, _194);\n    vertex(param_1);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[59];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _134 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _140 = _134.y;\n    return vec2(_134.x, mix(_140, 1.0 - _140, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _196);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    vec4 _238 = texture(tex_smp, uv);\n    vec3 param = _238.xyz;\n    float param_1 = xform.y;\n    vec3 _249 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_249, _238.w) * color;\n    float param_2 = 0.0;\n    vec4 _308 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_308);\n    fragment(param_3, param_4);\n    _308 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_122",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
