{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
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
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\nlayout(binding = 1) uniform sampler2D normal_tex_smp;\nlayout(binding = 2) uniform sampler2D light_tex_light_smp;\nlayout(binding = 3) uniform sampler2D shadow_tex_shadow_smp;\nlayout(binding = 4) uniform sampler2D fx_cookie_tex_light_smp;\nlayout(binding = 5) uniform sampler2D fx_emissive_tex_smp;\n\nlayout(location = 7) in vec3 xform;\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 2) in vec2 params;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 4) in vec4 color2;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nvec4 tex_color(vec2 p)\n{\n    vec4 _386 = texture(tex_smp, p);\n    vec3 param = _386.xyz;\n    float param_1 = xform.y;\n    vec3 _396 = fa_tex_fix(param, param_1);\n    return vec4(_396, _386.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    vec4 _111 = textureLod(shadow_tex_shadow_smp, vec2((i + 0.5) * 0.0009765625, v), 0.0);\n    return ((floor((_111.x * 255.0) + 0.5) * 256.0) + floor((_111.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nfloat light_shadow(float v, vec2 d, float radius)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _149 = atan(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0)\n    {\n        _152 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875;\n    float _169 = min(floor(_164), 1023.0);\n    float _176 = _169 + 1.0;\n    float i1 = _176;\n    if (_176 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(clamp(((shadow_texel(param, param_1) * radius) - _135) + 0.5, 0.0, 1.0), clamp(((shadow_texel(param_2, param_3) * radius) - _135) + 0.5, 0.0, 1.0), _164 - _169);\n}\n\nvec3 cookie_coord(vec4 cell, vec4 xf, vec2 off)\n{\n    vec2 _239 = vec2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5;\n    vec2 c = vec2(_243, 0.5 - _239.y);\n    bool _251 = _243 >= 0.0;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    vec2 _271 = c;\n    vec2 _276 = clamp(_271, vec2(0.001953125), vec2(0.998046875));\n    c = _276;\n    return vec3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nfloat cookie_value(vec4 t)\n{\n    return dot(t.xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nfloat cookie_att(int i, vec2 d)\n{\n    if (quad_fs_params[i * 1 + 63].w == 0.0)\n    {\n        return 1.0;\n    }\n    vec4 param = quad_fs_params[i * 1 + 63];\n    vec4 param_1 = quad_fs_params[i * 1 + 79];\n    vec2 param_2 = d;\n    vec3 _542 = cookie_coord(param, param_1, param_2);\n    vec4 param_3 = textureLod(fx_cookie_tex_light_smp, _542.xy, 0.0);\n    return cookie_value(param_3) * _542.z;\n}\n\nvec3 lit_color(vec4 base, float mode)\n{\n    vec3 n = vec3(0.0, 0.0, 1.0);\n    bool _564 = quad_fs_params[0].y > 0.5;\n    if (_564)\n    {\n        vec3 param = texture(normal_tex_smp, (uv * quad_fs_params[2].xy) + quad_fs_params[2].zw).xyz;\n        float param_1 = xform.z;\n        vec3 _588 = fa_tex_fix(param, param_1);\n        vec3 _592 = (_588 * 2.0) - vec3(1.0);\n        float _599 = cos(params.y);\n        float _601 = sin(params.y);\n        n = normalize(vec3((vec2(_599, _601) * _592.x) + ((vec2(-_601, _599) * ((mode > 5.5) ? (-1.0) : 1.0)) * _592.y), max(_592.z, 0.0500000007450580596923828125)));\n    }\n    bool _635 = !_564;\n    bool _641;\n    if (_635)\n    {\n        _641 = quad_fs_params[0].z > 0.5;\n    }\n    else\n    {\n        _641 = _635;\n    }\n    vec3 _644;\n    if (_641)\n    {\n        _644 = quad_fs_params[3].xyz;\n    }\n    else\n    {\n        _644 = quad_fs_params[1].xyz;\n    }\n    vec3 total = _644;\n    bool _661;\n    if (_641)\n    {\n        _661 = quad_fs_params[0].z < 1.5;\n    }\n    else\n    {\n        _661 = _641;\n    }\n    if (_661)\n    {\n        total += (textureLod(light_tex_light_smp, gl_FragCoord.xy * quad_fs_params[4].xy, 0.0).xyz * quad_fs_params[4].z);\n    }\n    vec3 l;\n    float _785;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _699;\n        if (!_641)\n        {\n            _699 = float(i) >= quad_fs_params[0].x;\n        }\n        else\n        {\n            _699 = _641;\n        }\n        if (_699)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            l = quad_fs_params[i * 1 + 5].xyz;\n        }\n        else\n        {\n            vec2 _725 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            att = pow(clamp(1.0 - (length(_725) / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            vec3 _745 = vec3(_725, quad_fs_params[i * 1 + 5].z);\n            l = _745 / vec3(max(length(_745), 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param_2 = quad_fs_params[i * 1 + 37].x;\n                vec2 param_3 = -_725;\n                float param_4 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            vec2 param_6 = -_725;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_564)\n        {\n            _785 = max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _785 = 1.0;\n        }\n        total += (quad_fs_params[i * 1 + 21].xyz * (att * _785));\n    }\n    return base.xyz * total;\n}\n\nvec3 scene_rgb(inout vec3 c)\n{\n    if (xform.x > 0.5)\n    {\n        vec3 param = c;\n        vec3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nvec4 shape_color()\n{\n    vec2 _1031 = max(shape_half, vec2(9.9999997473787516355514526367188e-05));\n    vec2 _1035 = uv * _1031;\n    float _1041 = _1031.x;\n    float _1043 = _1031.y;\n    float _1045 = clamp(shape_rs.x, 0.0, min(_1041, _1043));\n    vec2 _1056 = (abs(_1035) - _1031) + vec2(_1045);\n    float d = (length(max(_1056, vec2(0.0))) + min(max(_1056.x, _1056.y), 0.0)) - _1045;\n    float ax = params.y;\n    bool _1077 = params.y > 15.0;\n    if (_1077)\n    {\n        ax -= 20.0;\n    }\n    float _1088;\n    if (ax <= (-1.5))\n    {\n        _1088 = (-2.0) - ax;\n    }\n    else\n    {\n        _1088 = 0.0;\n    }\n    if (_1088 > 0.0)\n    {\n        float _1102 = _1088 * 0.5;\n        d = abs(d + _1102) - _1102;\n    }\n    float _1110 = fwidth(d);\n    float _1111 = max(_1110, 9.9999997473787516355514526367188e-05);\n    float _1121 = clamp(0.5 - (d / max(shape_rs.y, _1111)), 0.0, 1.0);\n    float _1126;\n    if (shape_rs.y > _1111)\n    {\n        _1126 = (_1121 * _1121) * (3.0 - (2.0 * _1121));\n    }\n    else\n    {\n        _1126 = _1121;\n    }\n    vec4 c = color;\n    bool _1148 = (_1088 <= 0.0) && (ax > (-0.5));\n    if (_1148)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1163 = cos(ax);\n            float _1165 = sin(ax);\n            g = ((dot(_1035, vec2(_1163, _1165)) / max((abs(_1163) * _1041) + (abs(_1165) * _1043), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = clamp(g, 0.0, 1.0);\n        if (_1077)\n        {\n            vec4 _1208 = textureLod(tex_smp, vec2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), 0.0);\n            c = _1208;\n            vec3 param = _1208.xyz;\n            float param_1 = xform.y;\n            vec3 _1215 = fa_tex_fix(param, param_1);\n            vec4 _2003 = c;\n            _2003.x = _1215.x;\n            _2003.y = _1215.y;\n            _2003.z = _1215.z;\n            c = _2003;\n        }\n        else\n        {\n            vec3 param_2 = color2.xyz;\n            vec3 _1227 = scene_rgb(param_2);\n            vec4 _1252 = mix(vec4(color.xyz * color.w, color.w), vec4(_1227 * color2.w, color2.w), vec4(g));\n            float _1254 = _1252.w;\n            vec3 _1257;\n            if (_1254 > 9.9999997473787516355514526367188e-06)\n            {\n                _1257 = _1252.xyz / vec3(_1254);\n            }\n            else\n            {\n                _1257 = color.xyz;\n            }\n            c = vec4(_1257, _1254);\n        }\n    }\n    vec4 _2012 = c;\n    _2012.w = _2012.w * _1126;\n    c = _2012;\n    if (_1148 || (shape_rs.y > 0.0))\n    {\n        float _1298 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            vec3 param_3 = c.xyz;\n            vec3 _1307 = fa_linear_to_srgb(param_3);\n            vec3 param_4 = _1307 + vec3(_1298 * 0.0039215688593685626983642578125);\n            vec3 _1313 = fa_srgb_to_linear(param_4);\n            vec4 _2015 = c;\n            _2015.x = _1313.x;\n            _2015.y = _1313.y;\n            _2015.z = _1313.z;\n            c = _2015;\n        }\n        else\n        {\n            vec4 _1323 = c;\n            vec3 _1326 = _1323.xyz + vec3(_1298 * 0.0039215688593685626983642578125);\n            vec4 _2022 = _1323;\n            _2022.x = _1326.x;\n            _2022.y = _1326.y;\n            _2022.z = _1326.z;\n            c = _2022;\n        }\n        vec4 _2027 = c;\n        _2027.w = clamp(_2027.w + ((_1298 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2027.w)), 0.0, 1.0);\n        c = _2027;\n    }\n    return c;\n}\n\nvec3 rim_color(float a0, float mode)\n{\n    vec2 _822 = vec2(quad_fs_params[62].x, 0.0);\n    vec4 _824 = texture(tex_smp, uv - _822);\n    float _825 = _824.w;\n    vec4 _835 = texture(tex_smp, uv + _822);\n    float _836 = _835.w;\n    vec2 _844 = vec2(0.0, quad_fs_params[62].y);\n    vec4 _846 = texture(tex_smp, uv - _844);\n    float _847 = _846.w;\n    vec4 _857 = texture(tex_smp, uv + _844);\n    float _858 = _857.w;\n    float _873 = _825 - _836;\n    float _876 = _858 - _847;\n    float _886 = cos(params.y);\n    float _888 = sin(params.y);\n    vec2 _914 = ((vec2(_886, _888) * _873) + ((vec2(-_888, _886) * ((mode > 5.5) ? (-1.0) : 1.0)) * _876)) / vec2(max(length(vec2(_873, _876)), 9.9999997473787516355514526367188e-05));\n    vec3 sum = vec3(0.0);\n    vec2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= quad_fs_params[0].x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (quad_fs_params[i * 1 + 5].w < 0.0)\n        {\n            to_l = quad_fs_params[i * 1 + 5].xy / vec2(max(length(quad_fs_params[i * 1 + 5].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            vec2 _960 = quad_fs_params[i * 1 + 5].xy - world_xy;\n            float _963 = length(_960);\n            att = pow(clamp(1.0 - (_963 / max(quad_fs_params[i * 1 + 5].w, 0.001000000047497451305389404296875)), 0.0, 1.0), quad_fs_params[i * 1 + 21].w);\n            to_l = _960 / vec2(max(_963, 9.9999997473787516355514526367188e-05));\n            if (quad_fs_params[i * 1 + 37].x >= 0.0)\n            {\n                float param = quad_fs_params[i * 1 + 37].x;\n                vec2 param_1 = -_960;\n                float param_2 = quad_fs_params[i * 1 + 5].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            vec2 param_4 = -_960;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (quad_fs_params[i * 1 + 21].xyz * (att * max(dot(_914, to_l), 0.0)));\n    }\n    return (sum * quad_fs_params[61].xyz) * (a0 * (1.0 - min(min(_825, _836), min(_847, _858))));\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _435 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _439 = _435.y;\n    return vec2(_435.x, mix(_439, 1.0 - _439, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _480 = base_mode < 0.5;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _492);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    float mode = params.x;\n    bool _1353 = params.x > 31.5;\n    if (_1353)\n    {\n        mode -= 32.0;\n    }\n    float _1361 = mode;\n    bool _1363 = _1361 > 15.5;\n    if (_1363)\n    {\n        mode -= 16.0;\n    }\n    float _1371 = mode;\n    bool _1373 = _1371 > 7.5;\n    if (_1373)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        vec2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1363)\n        {\n            vec4 param_1 = frag_color;\n            float param_2 = 5.0;\n            frag_color = vec4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            frag_color = shape_color();\n            if (_1363)\n            {\n                vec4 param_3 = frag_color;\n                float param_4 = 5.0;\n                frag_color = vec4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                vec2 param_5 = uv;\n                vec4 _1435 = tex_color(param_5);\n                vec4 _1437 = _1435 * color;\n                vec4 param_6 = _1437;\n                float param_7 = mode;\n                float _1444 = _1437.w;\n                frag_color = vec4(lit_color(param_6, param_7), _1444);\n                if (quad_fs_params[61].w > 0.5)\n                {\n                    float param_8 = _1444;\n                    float param_9 = mode;\n                    vec4 _1460 = frag_color;\n                    vec3 _1462 = _1460.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1462.x;\n                    frag_color.y = _1462.y;\n                    frag_color.z = _1462.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    frag_color = vec4(color.xyz, color.w * texture(tex_smp, uv).x);\n                }\n                else\n                {\n                    float _1492 = length(uv);\n                    float _1495 = fwidth(_1492);\n                    float _1496 = max(_1495, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = clamp(((1.0 - _1492) / _1496) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = clamp(((1.0 - _1492) / _1496) + 0.5, 0.0, 1.0) * clamp(((_1492 - params.y) / _1496) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1536 = clamp(1.0 - _1492, 0.0, 1.0);\n                            cov = (_1536 * _1536) * (3.0 - (2.0 * _1536));\n                        }\n                    }\n                    vec3 _1545;\n                    if (_1363)\n                    {\n                        vec4 param_10 = color;\n                        float param_11 = 5.0;\n                        _1545 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1545 = color.xyz;\n                    }\n                    frag_color = vec4(_1545, color.w * cov);\n                }\n            }\n        }\n    }\n    if (quad_fs_params[59].w > 0.5)\n    {\n        vec3 e = quad_fs_params[59].xyz;\n        if (quad_fs_params[59].w > 1.5)\n        {\n            vec3 param_12 = texture(fx_emissive_tex_smp, (uv * quad_fs_params[60].xy) + quad_fs_params[60].zw).xyz;\n            float param_13 = quad_fs_params[59].w - 2.0;\n            vec3 _1600 = fa_tex_fix(param_12, param_13);\n            e *= _1600;\n        }\n        vec4 _1604 = frag_color;\n        vec3 _1606 = _1604.xyz + e;\n        frag_color.x = _1606.x;\n        frag_color.y = _1606.y;\n        frag_color.z = _1606.z;\n    }\n    float param_14 = mode;\n    vec4 _1933 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface param_16 = QuadSurface(_1933);\n    fragment(param_15, param_16);\n    _1933 = param_16.color;\n    frag_color = param_16.color;\n    if (_1353)\n    {\n        vec4 _1632 = frag_color;\n        vec3 param_17 = color2.xyz;\n        vec3 _1637 = scene_rgb(param_17);\n        vec3 _1641 = mix(_1632.xyz, _1637, vec3(color2.w));\n        frag_color.x = _1641.x;\n        frag_color.y = _1641.y;\n        frag_color.z = _1641.z;\n    }\n    if (_1373)\n    {\n        frag_color = vec4(mix(vec3(1.0), frag_color.xyz, vec3(frag_color.w)), 1.0);\n    }\n    bool _1665 = quad_fs_params[53].w > 0.0;\n    bool _1673;\n    if (!_1665)\n    {\n        _1673 = quad_fs_params[54].y > 0.0;\n    }\n    else\n    {\n        _1673 = _1665;\n    }\n    if (_1673)\n    {\n        vec3 _1687 = vec3(world_xy, world_z) - quad_fs_params[56].xyz;\n        float _1694 = dot(_1687, quad_fs_params[55].xyz);\n        bool _1698 = quad_fs_params[55].w > 0.5;\n        float _1699;\n        if (_1698)\n        {\n            _1699 = _1694;\n        }\n        else\n        {\n            _1699 = length(_1687);\n        }\n        float _1711 = _1699 - quad_fs_params[54].x;\n        if (_1711 > 0.0)\n        {\n            float _1720 = quad_fs_params[53].w * _1711;\n            float tau = _1720 * _1720;\n            if (quad_fs_params[54].y > 0.0)\n            {\n                float _1736;\n                if (_1698)\n                {\n                    _1736 = world_xy.y - (quad_fs_params[55].y * _1694);\n                }\n                else\n                {\n                    _1736 = quad_fs_params[56].y;\n                }\n                float _1757 = mix(_1736, world_xy.y, clamp(quad_fs_params[54].x / _1699, 0.0, 1.0));\n                float _1761 = world_xy.y - _1757;\n                float _1766 = _1757 - quad_fs_params[54].z;\n                float _1771 = world_xy.y - quad_fs_params[54].z;\n                bool _1774 = _1766 <= 0.0;\n                bool _1775 = !_1774;\n                bool _1781;\n                if (_1775)\n                {\n                    _1781 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1781 = _1774;\n                }\n                float _1782;\n                if (_1781)\n                {\n                    _1782 = quad_fs_params[54].y;\n                }\n                else\n                {\n                    _1782 = quad_fs_params[54].y * exp(-min(quad_fs_params[54].w * _1766, 80.0));\n                }\n                bool _1809;\n                if (_1775)\n                {\n                    _1809 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1809 = _1774;\n                }\n                float _1810;\n                if (_1809)\n                {\n                    _1810 = quad_fs_params[54].y * _1766;\n                }\n                else\n                {\n                    _1810 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1766, 80.0)))) / quad_fs_params[54].w;\n                }\n                bool _1835 = _1771 <= 0.0;\n                bool _1842;\n                if (!_1835)\n                {\n                    _1842 = quad_fs_params[54].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1842 = _1835;\n                }\n                float _1843;\n                if (_1842)\n                {\n                    _1843 = quad_fs_params[54].y * _1771;\n                }\n                else\n                {\n                    _1843 = (quad_fs_params[54].y * (1.0 - exp(-min(quad_fs_params[54].w * _1771, 80.0)))) / quad_fs_params[54].w;\n                }\n                float _1870;\n                if (abs(_1761) < 0.001000000047497451305389404296875)\n                {\n                    _1870 = _1782;\n                }\n                else\n                {\n                    _1870 = (_1843 - _1810) / _1761;\n                }\n                tau += (_1711 * max(_1870, 0.0));\n            }\n            vec4 _1893 = frag_color;\n            vec3 _1901 = mix(_1893.xyz, quad_fs_params[53].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            frag_color.x = _1901.x;\n            frag_color.y = _1901.y;\n            frag_color.z = _1901.z;\n        }\n    }\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_429",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
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
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1,
            "glsl_name": "fx_cookie_tex_light_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0,
            "glsl_name": "fx_emissive_tex_smp"
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#version 430\n\nstruct QuadVertex\n{\n    vec3 world_pos;\n    vec2 uv;\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 vs_params[6];\nlayout(location = 9) flat out int fa_inst_index_v;\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec2 texcoord0;\nlayout(location = 2) in vec4 color0;\nlayout(location = 0) out vec2 uv;\nlayout(location = 1) out vec4 color;\nlayout(location = 7) out vec3 xform;\nlayout(location = 2) out vec2 params;\nlayout(location = 3) in vec2 params0;\nlayout(location = 3) out vec2 world_xy;\nlayout(location = 8) out float world_z;\nlayout(location = 4) out vec4 color2;\nlayout(location = 4) in vec4 color2_0;\nlayout(location = 5) out vec2 shape_half;\nlayout(location = 5) in vec2 shape_half0;\nlayout(location = 6) out vec2 shape_rs;\nlayout(location = 6) in vec2 shape_rs0;\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    vec3 _68 = v.world_pos;\n    vec2 _76 = fa_vs_points.data[gl_InstanceID].pos.xy + (_68.xy * fa_vs_points.data[gl_InstanceID].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid main()\n{\n    fa_inst_index_v = gl_InstanceID;\n    vec3 _178 = position;\n    vec2 _179 = texcoord0;\n    vec4 _180 = color0;\n    if (vs_params[4].x > 0.5)\n    {\n        vec3 param = color0.xyz;\n        vec3 _117 = fa_srgb_to_linear(param);\n        vec4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex(_178, _179, _180);\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mat4(vs_params[0], vs_params[1], vs_params[2], vs_params[3]) * vec4(param_1.world_pos, 1.0);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = vs_params[4].xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\n",
      "fs": "#version 430\n\nstruct QuadInput\n{\n    vec2 uv;\n    vec4 color;\n    vec2 world_pos;\n    vec2 screen_uv;\n    float time;\n    float mode;\n    vec4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    vec4 color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 quad_fs_params[95];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D tex_smp;\n\nlayout(location = 0) in vec2 uv;\nlayout(location = 1) in vec4 color;\nlayout(location = 3) in vec2 world_xy;\nlayout(location = 5) in vec2 shape_half;\nlayout(location = 9) flat in int fa_inst_index_v;\nlayout(location = 0) out vec4 frag_color;\nlayout(location = 7) in vec3 xform;\nlayout(location = 2) in vec2 params;\nlayout(location = 4) in vec4 color2;\nlayout(location = 6) in vec2 shape_rs;\nlayout(location = 8) in float world_z;\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nvec2 fa_screen_uv()\n{\n    vec2 _136 = gl_FragCoord.xy * quad_fs_params[58].xy;\n    float _142 = _136.y;\n    return vec2(_136.x, mix(_142, 1.0 - _142, quad_fs_params[58].z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput(uv, color, world_xy, fa_screen_uv(), quad_fs_params[57].x, base_mode, vec4(0.0), _198);\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nvoid main()\n{\n    vec4 _240 = texture(tex_smp, uv);\n    vec3 param = _240.xyz;\n    float param_1 = xform.y;\n    vec3 _251 = fa_tex_fix(param, param_1);\n    frag_color = vec4(_251, _240.w) * color;\n    float param_2 = 0.0;\n    vec4 _305 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface param_4 = QuadSurface(_305);\n    fragment(param_3, param_4);\n    _305 = param_4.color;\n    frag_color = param_4.color;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 95,
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
