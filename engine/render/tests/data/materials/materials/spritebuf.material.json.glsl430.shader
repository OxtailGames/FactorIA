{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "points",
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
    }
  ],
  "programs": {
    "quad": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _68 = v.world_pos;\n    vec2 _76 = fa_vs_points.data[gl_InstanceID].pos.xy + (_68.xy * fa_vs_points.data[gl_InstanceID].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _178 = position;\n    vec2 _179 = texcoord0;\n    vec4 _180 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _117 = fa_srgb_to_linear(param);\n        vec4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex(_178, _179, _180);\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[63];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _266 = texture(tex_smp, p);\n    vec3 param = _266.xyz;\n    float param_1 = xform.y;\n    vec3 _276 = fa_tex_fix(param, param_1);\n    return vec4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _89 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_89.x * 255.0) + 0.5) * 256.0) + floor((_89.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _127 = atan(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0)\n    {\n        _130 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875;\n    float _147 = min(floor(_142), 1023.0);\n    float _154 = _147 + 1.0;\n    float i1 = _154;\n    if (_154 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5, 0.0, 1.0), _142 - _147);\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _409 = quad_fs_params[0].y > 0.5;\n    if (_409)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _433 = fa_tex_fix(param, param_1);\n        vec3 _437 = (_433 * 2.0) - vec3(1.0);\n        float _444 = cos(params.y);\n        float _446 = sin(params.y);\n        n = normalize(vec3((vec2(_444, _446) * _437.x) + ((vec2(-_446, _444) * ((mode > 5.5) ? (-1.0) : 1.0)) * _437.y), max(_437.z, 0.0500000007450580596923828125)));\n    }\n    bool _480 = !_409;\n    bool _486;\n    if (_480)\n    {\n        _486 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _486 = _480;\n    }\n    vec3 _489;\n    if (_486)\n    {\n        _489 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _489 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _489;\n    bool _506;\n    if (_486)\n    {\n        _506 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _506 = _486;\n    }\n    if (_506)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _624;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _546;\n        if (!_486)\n        {\n            _546 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _546 = _486;\n        }\n        if (_546)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _572 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_572) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _592 = vec3(_572, quad_fs_params[i * 1 + 5].z);\n            l = _592 / vec3(max(length(_592), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_572;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_409)\n        {\n            _624 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _624 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _624));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _652 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _656 = uv * _652;\n    float _662 = _652.x;\n    float _664 = _652.y;\n    float _666 = clamp(shape_rs.x, 0.0, min(_662, _664));\n    vec2 _677 = (abs(_656) - _652) + vec2(_666);\n    float d = (length(max(_677, vec2(0.0))) + min(max(_677.x, _677.y), 0.0)) - _666;\n    float ax = params.y;\n    bool _698 = params.y > 15.0;\n    if (_698)\n    {\n        ax -= 20.0;\n    }\n    float _709;\n    if (ax <= (-1.5))\n    {\n        _709 = (-2.0) - ax;\n    }\n    else\n    {\n        _709 = 0.0;\n    }\n    if (_709 > 0.0)\n    {\n        float _723 = _709 * 0.5;\n        d = abs(d + _723) - _723;\n    }\n    float _731 = fwidth(d);\n    float _732 = max(_731, 9.9999997473787516355514526367188e-05);\n    float _742 = clamp(0.5 - (d / max(shape_rs.y, _732)), 0.0, 1.0);\n    float _747;\n    if (shape_rs.y > _732)\n    {\n        _747 = (_742 * _742) * (3.0 - (2.0 * _742));\n    }\n    else\n    {\n        _747 = _742;\n    }\n    vec4 c = color;\n    bool _769 = (_709 <= 0.0) && (ax > (-0.5));\n    if (_769)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _784 = cos(ax);\n            float _786 = sin(ax);\n            g = ((dot(_656, vec2(_784, _786)) / max((abs(_784) * _662) + (abs(_786) * _664), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_698)\n        {\n            vec4 _829 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _829;\n            vec3 param = _829.xyz;\n            float param_1 = xform.y;\n            vec3 _836 = fa_tex_fix(param, param_1);\n            vec4 _1533 = c;\n            _1533.x = _836.x;\n            _1533.y = _836.y;\n            _1533.z = _836.z;\n            c = _1533;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _848 = scene_rgb(param_2);\n            vec4 _873 = mix(vec4(color.xyz * color.w, color.w), vec4(_848 * color2.w, color2.w), vec4(g));\n            float _875 = _873.w;\n            vec3 _878;\n            if (_875 > 9.9999997473787516355514526367188e-06)\n            {\n                _878 = _873.xyz / vec3(_875);\n            }\n            else\n            {\n                _878 = color.xyz;\n            }\n            c = vec4(_878, _875);\n        }\n    }\n    vec4 _1542 = c;\n    _1542.w = _1542.w * _747;\n    c = _1542;\n    if (_769 || (shape_rs.y > 0.0))\n    {\n        float _919 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _928 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _928 + vec3(_919 * 0.0039215688593685626983642578125);\n            vec3 _934 = fa_srgb_to_linear(param_4);\n            vec4 _1545 = c;\n            _1545.x = _934.x;\n            _1545.y = _934.y;\n            _1545.z = _934.z;\n            c = _1545;\n        }\n        else\n        {\n            vec4 _944 = c;\n            vec3 _947 = _944.xyz + vec3(_919 * 0.0039215688593685626983642578125);\n            vec4 _1552 = _944;\n            _1552.x = _947.x;\n            _1552.y = _947.y;\n            _1552.z = _947.z;\n            c = _1552;\n        }\n        vec4 _1557 = c;\n        _1557.w = clamp(_1557.w + ((_919 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1557.w)), 0.0, 1.0);\n        c = _1557;\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _316 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _320 = _316.y;\n    return vec2(_316.x, mix(_320, 1.0 - _320, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _362 = base_mode < 0.5;\n    bool _373;\n    if (!_362)\n    {\n        _373 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _373 = _362;\n    }\n    float _374;\n    if (_373)\n    {\n        _374 = shape_half.x;\n    }\n    else\n    {\n        _374 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _374);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _974 = params.x > 31.5;\n    if (_974)\n    {\n        mode -= 32.0;\n    }\n    float _982 = mode;\n    bool _984 = _982 > 15.5;\n    if (_984)\n    {\n        mode -= 16.0;\n    }\n    float _992 = mode;\n    bool _994 = _992 > 7.5;\n    if (_994)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_984)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_984)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1058 = tex_color(param_5) * color;\n                vec4 param_6 = _1058;\n                float param_7 = mode;\n                frag_color = vec4(lit_color(param_6, param_7), _1058.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1093 = length(uv);\n                    float _1096 = fwidth(_1093);\n                    float _1097 = max(_1096, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1093) / _1097) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1093) / _1097) + 0.5, 0.0, 1.0) * clamp(((_1093 - params.y) / _1097) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1137 = clamp(1.0 - _1093, 0.0, 1.0);\n                            cov = (_1137 * _1137) * (3.0 - (2.0 * _1137));\n                        }\n                    }\n                    vec3 _1146;\n                    if (_984)\n                    {\n                        vec4 param_8 = color;\n                        float param_9 = 5.0;\n                        _1146 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1146 = color.xyz;\n                    }\n                    frag_color = vec4(_1146, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    vec4 _1486 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface param_12 = QuadSurface(_1486);\n    fragment(param_11, param_12);\n    _1486 = param_12.color;\n    frag_color = param_12.color;\n    if (_974)\n    {\n        vec4 _1184 = frag_color;\n        vec3 param_13 = color2.xyz;\n        vec3 _1189 = scene_rgb(param_13);\n        vec3 _1193 = mix(_1184.xyz, _1189, vec3(color2.w));\n        frag_color.x = _1193.x;\n        frag_color.y = _1193.y;\n        frag_color.z = _1193.z;\n    }\n    if (_994)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1217 = quad_fs_params[53].w > 0.0;\n    bool _1225;\n    if (!_1217)\n    {\n        _1225 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1225 = _1217;\n    }\n    if (_1225)\n    {\n        vec3 _1239 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1246 = dot(_1239, quad_fs_params[55].xyz);\n        bool _1250 = quad_fs_params[55].w > 0.5;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - quad_fs_params[54].x;\n        if (_1263 > 0.0)\n        {\n            float _1272 = quad_fs_params[53].w * _1263;\n            float tau = _1272 * _1272;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_xy.y - (quad_fs_params[55].y * _1246);\n                }\n                else\n                {\n                    _1288 = quad_fs_params[56].y;\n                }\n                float _1309 = mix(_1288, world_xy.y, clamp(quad_fs_params[54].x / _1251, 0.0, 1.0));\n                float _1313 = world_xy.y - _1309;\n                float _1318 = _1309 - quad_fs_params[54].z;\n                float _1323 = world_xy.y - quad_fs_params[54].z;\n                bool _1326 = _1318 <= 0.0;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1334 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1318, 80.0));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = quad_fs_params[54].y * _1318;\n                }\n                else\n                {\n                    _1362 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1318, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1387 = _1323 <= 0.0;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = quad_fs_params[54].y * _1323;\n                }\n                else\n                {\n                    _1395 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1323, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * max(_1422, 0.0));\n            }\n            vec4 _1445 = frag_color;\n            vec3 _1453 = mix(_1445.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1453.x;\n            frag_color.y = _1453.y;\n            frag_color.z = _1453.z;\n        }\n    }\n}\n\n",
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
            "inst_name": "_105",
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
            "inst_name": "_309",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _68 = v.world_pos;\n    vec2 _76 = fa_vs_points.data[gl_InstanceID].pos.xy + (_68.xy * fa_vs_points.data[gl_InstanceID].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _178 = position;\n    vec2 _179 = texcoord0;\n    vec4 _180 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _117 = fa_srgb_to_linear(param);\n        vec4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex(_178, _179, _180);\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[63];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    vec4 _240 = texture(tex_smp, uv);\n    vec3 param = _240.xyz;\n    float param_1 = xform.y;\n    vec3 _251 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_251, _240.w) * color;\n    float param_2 = 0.0;\n    vec4 _306 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_306);\n    fragment(param_3, param_4);\n    _306 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "inst_name": "_105",
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
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 63,
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
