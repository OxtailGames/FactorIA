{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1288 = fa_linear_to_srgb(param);\n        c = _1288;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1296 = fa_srgb_to_linear(param_1);\n            c = _1296;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _131;\n    if (i.front_facing)\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    vec3 _155 = normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    vec3 _183 = normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    vec3 _186;\n    if (i.front_facing)\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1327 = fa_tex_fix(param_2, param_3);\n    vec4 _2113 = base_t;\n    _2113.x = _1327.x;\n    _2113.y = _1327.y;\n    _2113.z = _1327.z;\n    base_t = _2113;\n    vec4 _1341 = (_2113 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2081 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1373 = fa_tex_fix(param_6, param_7);\n        vec3 _1377 = (_1373 * 2.0) - vec3(1.0);\n        vec2 _1382 = _1377.xy * fa_mesh_fs_params[6].x;\n        vec3 _2121 = _1377;\n        _2121.x = _1382.x;\n        _2121.y = _1382.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2121;\n        _2081 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1411 = fa_tex_fix(param_12, param_13);\n    vec4 _2124 = mrt;\n    _2124.x = _1411.x;\n    _2124.y = _1411.y;\n    _2124.z = _1411.z;\n    mrt = _2124;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1450 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1477 = fa_tex_fix(param_20, param_21);\n    return Surface(_1341.xyz, _1341.w, _2081, clamp(fa_mesh_fs_params[5].x * _1411.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1411.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1450.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1477));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _214 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_214)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _232 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / vec3(max(_234, 9.9999997473787516355514526367188e-05));\n        float _250 = _234 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _256 = clamp(1.0 - (_250 * _250), 0.0, 1.0);\n        atten = _256 * _256;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _307);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = fa_shadows[24].z;\n            }\n            else\n            {\n                _383 = fa_shadows[24].w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _427 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _432 = clamp(dot(n, l), 0.0, 1.0);\n    float _438 = sqrt(1.0 - (_432 * _432));\n    float _446 = min(_438 / max(_432, 0.20000000298023223876953125), 4.0);\n    float _451;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _451 = fa_shadows[26].y;\n    }\n    else\n    {\n        _451 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _476 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_451 * _438)), 1.0);\n    float _483 = _476.x;\n    bool _486 = _483 < fa_shadows[ci * 1 + 16].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0;\n    }\n    float _529;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _529 = fa_shadows[26].x;\n    }\n    else\n    {\n        _529 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0 + (0.5 * _446))) / _427);\n    float _557 = ((fa_shadows[ci * 1 + 20].x * min(_446, 3.0)) * 0.5) / _427;\n    int _566 = int(fa_shadows[25].z + 0.5);\n    if (_566 == 1)\n    {\n        vec2 param = _476.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _577 = fa_shadow_depth(param, param_1);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = clamp(((fa_shadows[25].w * _427) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            vec2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            vec2 param_5 = _476.xy + (_621 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _632 = fa_shadow_depth(param_5, param_6);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_548 - (sum / cnt), 0.0) * _427) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        vec2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _476.xy + (_695 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _706 = fa_shadow_depth(param_10, param_11);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _739 = int(fa_shadows[25].x + 0.5);\n    if (_739 < 1)\n    {\n        return 1.0;\n    }\n    float _755 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > fa_shadows[24].x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > fa_shadows[24].y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > fa_shadows[24].z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _822;\n        if (_822 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _847 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _866 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _847, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _877 = clamp((_755 - (fa_shadow_split_at(param_7) - _866)) / _866, 0.0, 1.0);\n        if (_877 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _898;\n                if (_898 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1);\n    vec3 _2066 = _1194.direction;\n    vec3 _2061 = _1194.color;\n    float _2068 = _1194.attenuation;\n    float _2063 = _1194.shadow;\n    int _2071 = _1194.type;\n    if ((_2071 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2066;\n        float _1208 = fa_shadow_factor(param_2, param_3);\n        _2063 = _1208;\n        _2061 = fa_lights[li * 1 + 32].xyz * (_2068 * _1208);\n    }\n    return LightSample(_2066, _2061, _2068, _2063, _1194._distance, _2071);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1130 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1133 = _1130.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1133 * _1133, exp2((-9.27999973297119140625) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625 * _1035;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1035)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1065, 0.0500000007450580596923828125 + _1065, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1035 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1172 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1172.x) + vec3(_1172.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _922 = int(fa_shadows[25].x + 0.5);\n    float _932 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > fa_shadows[24].x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > fa_shadows[24].y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > fa_shadows[24].z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _1986 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1986 = -_1986;\n    }\n    vec3 _1520 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing);\n    Surface _1525 = fa_standard_surface(param);\n    vec3 _2009 = _1525.albedo;\n    float _2010 = _1525.alpha;\n    vec3 _2011 = _1525.normal;\n    float _2012 = _1525.metallic;\n    float _2013 = _1525.roughness;\n    float _2014 = _1525.occlusion;\n    vec3 _2015 = _1525.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing);\n    Surface param_2 = _1525;\n    surface(param_1, param_2);\n    _2009 = param_2.albedo;\n    _2010 = param_2.alpha;\n    _2011 = param_2.normal;\n    _2012 = param_2.metallic;\n    _2013 = param_2.roughness;\n    _2014 = param_2.occlusion;\n    _2015 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2009;\n    }\n    else\n    {\n        vec3 _1547 = normalize(_2011);\n        float _1554 = clamp(_2012, 0.0, 1.0);\n        float _1558 = clamp(_2013, 0.0500000007450580596923828125, 1.0);\n        float _1562 = _1558 * _1558;\n        float _1566 = _1562 * _1562;\n        float _1571 = max(dot(_1547, _1520), 9.9999997473787516355514526367188e-05);\n        vec3 _1577 = _2009 * (1.0 - _1554);\n        vec3 _1585 = mix(vec3(0.039999999105930328369140625), _2009, vec3(_1554));\n        vec3 param_3 = _1547;\n        vec3 lit = (fa_ambient_light(param_3) * _1577) * _2014;\n        int _1599 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1599)\n            {\n                break;\n            }\n            int param_4 = li;\n            vec3 param_5 = fa_world_pos;\n            vec3 param_6 = _1986;\n            LightSample _1623 = fa_light_shadowed(param_4, param_5, param_6);\n            vec3 _2044 = _1623.direction;\n            float _1631 = max(dot(_1547, _2044), 0.0);\n            vec3 _1642 = normalize(_2044 + _1520);\n            float _1647 = max(dot(_1547, _1642), 0.0);\n            float _1660 = ((_1647 * _1647) * (_1566 - 1.0)) + 1.0;\n            lit += (((_1577 + (((_1585 + ((vec3(1.0) - _1585) * pow(1.0 - max(dot(_1520, _1642), 0.0), 5.0))) * (((_1566 / ((3.1415927410125732421875 * _1660) * _1660)) * (0.5 / max(mix((2.0 * _1631) * _1571, _1631 + _1571, _1562), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1631))) * fa_lights[li * 1 + 32].xyz) * (_1631 * (_1623.attenuation * _1623.shadow)));\n        }\n        vec3 param_7 = _1547;\n        vec3 param_8 = _1520;\n        vec3 param_9 = _1585;\n        float param_10 = _1558;\n        vec3 _1730 = lit;\n        vec3 _1731 = _1730 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _2014);\n        lit = _1731;\n        result = _1731;\n    }\n    vec3 _1735 = result;\n    vec3 _1736 = _1735 + _2015;\n    result = _1736;\n    vec3 param_11 = _1736;\n    vec3 param_12 = fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12);\n    bool _1745 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1753;\n    if (!_1745)\n    {\n        _1753 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1753 = _1745;\n    }\n    if (_1753)\n    {\n        vec3 _1762 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1769 = dot(_1762, fa_mesh_fs_params[9].xyz);\n        bool _1773 = fa_mesh_fs_params[9].w > 0.5;\n        float _1774;\n        if (_1773)\n        {\n            _1774 = _1769;\n        }\n        else\n        {\n            _1774 = length(_1762);\n        }\n        float _1786 = _1774 - fa_mesh_fs_params[8].x;\n        if (_1786 > 0.0)\n        {\n            float _1795 = fa_mesh_fs_params[7].w * _1786;\n            float tau = _1795 * _1795;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1811;\n                if (_1773)\n                {\n                    _1811 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1769);\n                }\n                else\n                {\n                    _1811 = fa_mesh_fs_params[0].y;\n                }\n                float _1832 = mix(_1811, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1774, 0.0, 1.0));\n                float _1836 = fa_world_pos.y - _1832;\n                float _1841 = _1832 - fa_mesh_fs_params[8].z;\n                float _1846 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1849 = _1841 <= 0.0;\n                bool _1850 = !_1849;\n                bool _1856;\n                if (_1850)\n                {\n                    _1856 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1856 = _1849;\n                }\n                float _1857;\n                if (_1856)\n                {\n                    _1857 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1857 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1841, 80.0));\n                }\n                bool _1884;\n                if (_1850)\n                {\n                    _1884 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1884 = _1849;\n                }\n                float _1885;\n                if (_1884)\n                {\n                    _1885 = fa_mesh_fs_params[8].y * _1841;\n                }\n                else\n                {\n                    _1885 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1841, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1910 = _1846 <= 0.0;\n                bool _1917;\n                if (!_1910)\n                {\n                    _1917 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1917 = _1910;\n                }\n                float _1918;\n                if (_1917)\n                {\n                    _1918 = fa_mesh_fs_params[8].y * _1846;\n                }\n                else\n                {\n                    _1918 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1846, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1945;\n                if (abs(_1836) < 0.001000000047497451305389404296875)\n                {\n                    _1945 = _1857;\n                }\n                else\n                {\n                    _1945 = (_1918 - _1885) / _1836;\n                }\n                tau += (_1786 * max(_1945, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2010);\n}\n\n",
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
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_203",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_369",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_728",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_386, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1288 = fa_linear_to_srgb(param);\n        c = _1288;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1296 = fa_srgb_to_linear(param_1);\n            c = _1296;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _131;\n    if (i.front_facing)\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    vec3 _155 = normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    vec3 _183 = normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    vec3 _186;\n    if (i.front_facing)\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1327 = fa_tex_fix(param_2, param_3);\n    vec4 _2113 = base_t;\n    _2113.x = _1327.x;\n    _2113.y = _1327.y;\n    _2113.z = _1327.z;\n    base_t = _2113;\n    vec4 _1341 = (_2113 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2081 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1373 = fa_tex_fix(param_6, param_7);\n        vec3 _1377 = (_1373 * 2.0) - vec3(1.0);\n        vec2 _1382 = _1377.xy * fa_mesh_fs_params[6].x;\n        vec3 _2121 = _1377;\n        _2121.x = _1382.x;\n        _2121.y = _1382.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2121;\n        _2081 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1411 = fa_tex_fix(param_12, param_13);\n    vec4 _2124 = mrt;\n    _2124.x = _1411.x;\n    _2124.y = _1411.y;\n    _2124.z = _1411.z;\n    mrt = _2124;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1450 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1477 = fa_tex_fix(param_20, param_21);\n    return Surface(_1341.xyz, _1341.w, _2081, clamp(fa_mesh_fs_params[5].x * _1411.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1411.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1450.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1477));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _214 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_214)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _232 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / vec3(max(_234, 9.9999997473787516355514526367188e-05));\n        float _250 = _234 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _256 = clamp(1.0 - (_250 * _250), 0.0, 1.0);\n        atten = _256 * _256;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _307);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = fa_shadows[24].z;\n            }\n            else\n            {\n                _383 = fa_shadows[24].w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _427 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _432 = clamp(dot(n, l), 0.0, 1.0);\n    float _438 = sqrt(1.0 - (_432 * _432));\n    float _446 = min(_438 / max(_432, 0.20000000298023223876953125), 4.0);\n    float _451;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _451 = fa_shadows[26].y;\n    }\n    else\n    {\n        _451 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _476 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_451 * _438)), 1.0);\n    float _483 = _476.x;\n    bool _486 = _483 < fa_shadows[ci * 1 + 16].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0;\n    }\n    float _529;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _529 = fa_shadows[26].x;\n    }\n    else\n    {\n        _529 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0 + (0.5 * _446))) / _427);\n    float _557 = ((fa_shadows[ci * 1 + 20].x * min(_446, 3.0)) * 0.5) / _427;\n    int _566 = int(fa_shadows[25].z + 0.5);\n    if (_566 == 1)\n    {\n        vec2 param = _476.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _577 = fa_shadow_depth(param, param_1);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = clamp(((fa_shadows[25].w * _427) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            vec2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            vec2 param_5 = _476.xy + (_621 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _632 = fa_shadow_depth(param_5, param_6);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_548 - (sum / cnt), 0.0) * _427) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        vec2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _476.xy + (_695 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _706 = fa_shadow_depth(param_10, param_11);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _739 = int(fa_shadows[25].x + 0.5);\n    if (_739 < 1)\n    {\n        return 1.0;\n    }\n    float _755 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > fa_shadows[24].x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > fa_shadows[24].y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > fa_shadows[24].z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _822;\n        if (_822 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _847 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _866 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _847, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _877 = clamp((_755 - (fa_shadow_split_at(param_7) - _866)) / _866, 0.0, 1.0);\n        if (_877 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _898;\n                if (_898 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1);\n    vec3 _2066 = _1194.direction;\n    vec3 _2061 = _1194.color;\n    float _2068 = _1194.attenuation;\n    float _2063 = _1194.shadow;\n    int _2071 = _1194.type;\n    if ((_2071 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2066;\n        float _1208 = fa_shadow_factor(param_2, param_3);\n        _2063 = _1208;\n        _2061 = fa_lights[li * 1 + 32].xyz * (_2068 * _1208);\n    }\n    return LightSample(_2066, _2061, _2068, _2063, _1194._distance, _2071);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1130 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1133 = _1130.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1133 * _1133, exp2((-9.27999973297119140625) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625 * _1035;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1035)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1065, 0.0500000007450580596923828125 + _1065, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1035 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1172 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1172.x) + vec3(_1172.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _922 = int(fa_shadows[25].x + 0.5);\n    float _932 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > fa_shadows[24].x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > fa_shadows[24].y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > fa_shadows[24].z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _1986 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1986 = -_1986;\n    }\n    vec3 _1520 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing);\n    Surface _1525 = fa_standard_surface(param);\n    vec3 _2009 = _1525.albedo;\n    float _2010 = _1525.alpha;\n    vec3 _2011 = _1525.normal;\n    float _2012 = _1525.metallic;\n    float _2013 = _1525.roughness;\n    float _2014 = _1525.occlusion;\n    vec3 _2015 = _1525.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing);\n    Surface param_2 = _1525;\n    surface(param_1, param_2);\n    _2009 = param_2.albedo;\n    _2010 = param_2.alpha;\n    _2011 = param_2.normal;\n    _2012 = param_2.metallic;\n    _2013 = param_2.roughness;\n    _2014 = param_2.occlusion;\n    _2015 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2009;\n    }\n    else\n    {\n        vec3 _1547 = normalize(_2011);\n        float _1554 = clamp(_2012, 0.0, 1.0);\n        float _1558 = clamp(_2013, 0.0500000007450580596923828125, 1.0);\n        float _1562 = _1558 * _1558;\n        float _1566 = _1562 * _1562;\n        float _1571 = max(dot(_1547, _1520), 9.9999997473787516355514526367188e-05);\n        vec3 _1577 = _2009 * (1.0 - _1554);\n        vec3 _1585 = mix(vec3(0.039999999105930328369140625), _2009, vec3(_1554));\n        vec3 param_3 = _1547;\n        vec3 lit = (fa_ambient_light(param_3) * _1577) * _2014;\n        int _1599 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1599)\n            {\n                break;\n            }\n            int param_4 = li;\n            vec3 param_5 = fa_world_pos;\n            vec3 param_6 = _1986;\n            LightSample _1623 = fa_light_shadowed(param_4, param_5, param_6);\n            vec3 _2044 = _1623.direction;\n            float _1631 = max(dot(_1547, _2044), 0.0);\n            vec3 _1642 = normalize(_2044 + _1520);\n            float _1647 = max(dot(_1547, _1642), 0.0);\n            float _1660 = ((_1647 * _1647) * (_1566 - 1.0)) + 1.0;\n            lit += (((_1577 + (((_1585 + ((vec3(1.0) - _1585) * pow(1.0 - max(dot(_1520, _1642), 0.0), 5.0))) * (((_1566 / ((3.1415927410125732421875 * _1660) * _1660)) * (0.5 / max(mix((2.0 * _1631) * _1571, _1631 + _1571, _1562), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1631))) * fa_lights[li * 1 + 32].xyz) * (_1631 * (_1623.attenuation * _1623.shadow)));\n        }\n        vec3 param_7 = _1547;\n        vec3 param_8 = _1520;\n        vec3 param_9 = _1585;\n        float param_10 = _1558;\n        vec3 _1730 = lit;\n        vec3 _1731 = _1730 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _2014);\n        lit = _1731;\n        result = _1731;\n    }\n    vec3 _1735 = result;\n    vec3 _1736 = _1735 + _2015;\n    result = _1736;\n    vec3 param_11 = _1736;\n    vec3 param_12 = fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12);\n    bool _1745 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1753;\n    if (!_1745)\n    {\n        _1753 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1753 = _1745;\n    }\n    if (_1753)\n    {\n        vec3 _1762 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1769 = dot(_1762, fa_mesh_fs_params[9].xyz);\n        bool _1773 = fa_mesh_fs_params[9].w > 0.5;\n        float _1774;\n        if (_1773)\n        {\n            _1774 = _1769;\n        }\n        else\n        {\n            _1774 = length(_1762);\n        }\n        float _1786 = _1774 - fa_mesh_fs_params[8].x;\n        if (_1786 > 0.0)\n        {\n            float _1795 = fa_mesh_fs_params[7].w * _1786;\n            float tau = _1795 * _1795;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1811;\n                if (_1773)\n                {\n                    _1811 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1769);\n                }\n                else\n                {\n                    _1811 = fa_mesh_fs_params[0].y;\n                }\n                float _1832 = mix(_1811, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1774, 0.0, 1.0));\n                float _1836 = fa_world_pos.y - _1832;\n                float _1841 = _1832 - fa_mesh_fs_params[8].z;\n                float _1846 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1849 = _1841 <= 0.0;\n                bool _1850 = !_1849;\n                bool _1856;\n                if (_1850)\n                {\n                    _1856 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1856 = _1849;\n                }\n                float _1857;\n                if (_1856)\n                {\n                    _1857 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1857 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1841, 80.0));\n                }\n                bool _1884;\n                if (_1850)\n                {\n                    _1884 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1884 = _1849;\n                }\n                float _1885;\n                if (_1884)\n                {\n                    _1885 = fa_mesh_fs_params[8].y * _1841;\n                }\n                else\n                {\n                    _1885 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1841, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1910 = _1846 <= 0.0;\n                bool _1917;\n                if (!_1910)\n                {\n                    _1917 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1917 = _1910;\n                }\n                float _1918;\n                if (_1917)\n                {\n                    _1918 = fa_mesh_fs_params[8].y * _1846;\n                }\n                else\n                {\n                    _1918 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1846, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1945;\n                if (abs(_1836) < 0.001000000047497451305389404296875)\n                {\n                    _1945 = _1857;\n                }\n                else\n                {\n                    _1945 = (_1918 - _1885) / _1836;\n                }\n                tau += (_1786 * max(_1945, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2010);\n}\n\n",
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
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_203",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_369",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_728",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _243 = fa_tex_fix(param_2, param_3);\n    vec4 _604 = base_t;\n    _604.x = _243.x;\n    _604.y = _243.y;\n    _604.z = _243.z;\n    base_t = _604;\n    vec4 _259 = (_604 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _585 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _293 = fa_tex_fix(param_6, param_7);\n        vec3 _297 = (_293 * 2.0) - vec3(1.0);\n        vec2 _302 = _297.xy * fa_mesh_fs_params[6].x;\n        vec3 _612 = _297;\n        _612.x = _302.x;\n        _612.y = _302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _612;\n        _585 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _331 = fa_tex_fix(param_12, param_13);\n    vec4 _615 = mrt;\n    _615.x = _331.x;\n    _615.y = _331.y;\n    _615.z = _331.z;\n    mrt = _615;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _399 = fa_tex_fix(param_20, param_21);\n    return Surface(_259.xyz, _259.w, _585, clamp(fa_mesh_fs_params[5].x * _331.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _331.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_372.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _399));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _532 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _532 = -_532;\n    }\n    vec3 _445 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _460 = normalize(param_2.normal);\n    vec3 _475 = normalize(vec3(dot(fa_pre_r0, _460), dot(fa_pre_r1, _460), dot(fa_pre_r2, _460)));\n    float _487 = _475.z;\n    vec2 e = _475.xy / vec2((abs(_475.x) + abs(_475.y)) + abs(_487));\n    if (_487 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_125",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
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
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _243 = fa_tex_fix(param_2, param_3);\n    vec4 _604 = base_t;\n    _604.x = _243.x;\n    _604.y = _243.y;\n    _604.z = _243.z;\n    base_t = _604;\n    vec4 _259 = (_604 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _585 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _293 = fa_tex_fix(param_6, param_7);\n        vec3 _297 = (_293 * 2.0) - vec3(1.0);\n        vec2 _302 = _297.xy * fa_mesh_fs_params[6].x;\n        vec3 _612 = _297;\n        _612.x = _302.x;\n        _612.y = _302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _612;\n        _585 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _331 = fa_tex_fix(param_12, param_13);\n    vec4 _615 = mrt;\n    _615.x = _331.x;\n    _615.y = _331.y;\n    _615.z = _331.z;\n    mrt = _615;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _399 = fa_tex_fix(param_20, param_21);\n    return Surface(_259.xyz, _259.w, _585, clamp(fa_mesh_fs_params[5].x * _331.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _331.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_372.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _399));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _532 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _532 = -_532;\n    }\n    vec3 _445 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _460 = normalize(param_2.normal);\n    vec3 _475 = normalize(vec3(dot(fa_pre_r0, _460), dot(fa_pre_r1, _460), dot(fa_pre_r2, _460)));\n    float _487 = _475.z;\n    vec2 e = _475.xy / vec2((abs(_475.x) + abs(_475.y)) + abs(_487));\n    if (_487 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_125",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
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
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}
