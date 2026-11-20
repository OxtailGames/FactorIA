{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1571[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _446 = fa_mesh_fs_params[19].x < 0.0;\n    bool _453;\n    if (!_446)\n    {\n        _453 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    bool _461;\n    if (!_453)\n    {\n        _461 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _461 = _453;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    if (_475)\n    {\n        return ivec2(0);\n    }\n    vec4 _485 = vec4(world_pos, 1.0);\n    float _492 = dot(fa_mesh_fs_params[16], _485);\n    if (!(_492 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _514 = vec2(dot(fa_mesh_fs_params[14], _485), dot(fa_mesh_fs_params[15], _485)) / vec2(_492);\n    int _518 = int(fa_mesh_fs_params[18].x);\n    int _522 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _522) + clamp(int(floor(((_514.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _522 - 1)) * _518)) + clamp(int(floor(((_514.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _518 - 1);\n    vec4 _593 = fa_light_texel(param);\n    return ivec2(int(_593.x), int(_593.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2111 = fa_cluster_lookup(param);\n    fa_cl_slot = _2111.x;\n    fa_cl_local = _2111.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2247 = fa_linear_to_srgb(param);\n        c = _2247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2255 = fa_srgb_to_linear(param_1);\n            c = _2255;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _205;\n    if (i.front_facing)\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    vec3 _229 = normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    vec3 _257 = normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    vec3 _260;\n    if (i.front_facing)\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2286 = fa_tex_fix(param_2, param_3);\n    vec4 _3305 = base_t;\n    _3305.x = _2286.x;\n    _3305.y = _2286.y;\n    _3305.z = _2286.z;\n    base_t = _3305;\n    vec4 _2300 = (_3305 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3239 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2332 = fa_tex_fix(param_6, param_7);\n        vec3 _2336 = (_2332 * 2.0) - vec3(1.0);\n        vec2 _2341 = _2336.xy * fa_mesh_fs_params[6].x;\n        vec3 _3313 = _2336;\n        _3313.x = _2341.x;\n        _3313.y = _2341.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3313;\n        _3239 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2370 = fa_tex_fix(param_12, param_13);\n    vec4 _3316 = mrt;\n    _3316.x = _2370.x;\n    _3316.y = _2370.y;\n    _3316.z = _2370.z;\n    mrt = _3316;\n    vec4 _2398 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2398.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2410 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2440 = fa_tex_fix(param_20, param_21);\n    float _3244 = fa_mesh_fs_params[20].x;\n    float _3245 = fa_mesh_fs_params[20].y;\n    float _3248 = fa_mesh_fs_params[20].z;\n    float _3247 = fa_mesh_fs_params[21].w;\n    float _3250 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3244 *= _2410.y;\n            _3245 *= _2410.z;\n            _3247 *= _2398.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3248 *= mrt.x;\n            _3250 *= mrt.w;\n        }\n    }\n    return Surface(_2300.xyz, _2300.w, _3239, clamp(fa_mesh_fs_params[5].x * _2370.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2370.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2410.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2440), _3244, _3245, fa_mesh_fs_params[21].xyz, _3247, _3248, fa_mesh_fs_params[20].w, _3250, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1496 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1504 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1507 = int(_1496);\n    int _1510 = int(_1504);\n    float _1520 = _1504 - float(_1510);\n    int _1576 = (_1507 * 9) + _1510;\n    int _1596 = ((_1507 + 1) * 9) + _1510;\n    return mix(mix(_1571[_1576], _1571[_1576 + 1], _1520), mix(_1571[_1596], _1571[_1596 + 1], _1520), _1496 - float(_1507));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3098 = false;\n    float _3099 = 1.0;\n    float _3100 = 1.0;\n    float _3101 = 1.0;\n    float _3102 = 0.0;\n    float _3103 = 0.0;\n    float _3104 = 0.0;\n    float _3105 = 0.0;\n    float _3107 = 1.0;\n    bool _3108 = false;\n    vec3 _3109 = vec3(0.0);\n    float _3110 = 1.0;\n    float _3111 = 1.0;\n    float _3112 = 1.0;\n    float _3113 = 0.0;\n    float _3114 = 0.0;\n    vec3 _3115 = vec3(1.0, 0.0, 0.0);\n    vec3 _3116 = vec3(0.0, 0.0, 1.0);\n    float _3117 = 1.0;\n    float _3118 = 1.0;\n    float _1651 = clamp(s.specular, 0.0, 1.0);\n    float _1655 = clamp(s.ior, 1.0, 3.0);\n    bool _1660 = (_1651 != 1.0) || (_1655 != 1.5);\n    bool _1670;\n    if (!_1660)\n    {\n        _1670 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1670 = _1660;\n    }\n    if (_1670)\n    {\n        float _1678 = (_1655 - 1.0) / (_1655 + 1.0);\n        f0 = mix(min(vec3(_1678 * _1678) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1651, s.albedo, vec3(metallic));\n        _3099 = mix(_1651, 1.0, metallic);\n        _3098 = true;\n    }\n    float _1706 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1706 > 0.0)\n    {\n        float _1714 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3102 = _1706;\n        _3103 = _1714;\n        float _1721 = _1714 * _1714;\n        _3104 = _1721;\n        _3105 = _1721 * _1721;\n        float _1733 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3107 = _1733;\n        _3100 = 1.0 - (_1706 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1733, 0.0, 1.0), 5.0))));\n        _3098 = true;\n    }\n    vec3 _1753 = max(s.sheen_color, vec3(0.0));\n    float _1762 = max(_1753.x, max(_1753.y, _1753.z));\n    if (_1762 > 0.0)\n    {\n        float _1770 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3108 = true;\n        _3109 = _1753;\n        _3110 = _1770;\n        _3111 = _1770 * _1770;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1770;\n        float _1787 = fa_sheen_albedo(param, param_1);\n        _3113 = _1787;\n        _3112 = 1.0 - min(_1762 * _1787, 1.0);\n        _3098 = true;\n    }\n    _3101 = _3100 * _3112;\n    float _1806 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1806 != 0.0)\n    {\n        vec3 _1821 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1821;\n        if (dot(_1821, _1821) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1835 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1835.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1835.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1835.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1839 = t;\n        vec3 _1840 = normalize(_1839);\n        t = _1840;\n        vec3 _1865 = normalize((_1840 * cos(s.anisotropy_rotation)) + ((cross(n, _1840) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3115 = _1865;\n        _3116 = cross(n, _1865);\n        float _1875 = roughness * roughness;\n        float _1881 = mix(_1875, 1.0, _1806 * _1806);\n        bool _1883 = _1806 > 0.0;\n        _3117 = _1883 ? _1881 : _1875;\n        _3118 = _1883 ? _1875 : _1881;\n        _3114 = _1806;\n        _3098 = true;\n    }\n    return FaLayers(_3098, _3099, _3100, _3101, _3102, _3103, _3104, _3105, i.world_normal, _3107, _3108, _3109, _3110, _3111, _3112, _3113, _3114, _3115, _3116, _3117, _3118);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1428 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1431 = _1428.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1431 * _1431, exp2((-9.27999973297119140625) * ndv)) * _1431) + _1428.y)) + _1428.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1333 = rough * rough;\n    float _1363 = 0.60000002384185791015625 * _1333;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1333)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1363, 0.0500000007450580596923828125 + _1363, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1333 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1916;\n        if (L.aniso >= 0.0)\n        {\n            _1916 = L.b;\n        }\n        else\n        {\n            _1916 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1916, v), _1916), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1949 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1949.x) + (vec3(L.f90) * _1949.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2004 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2004.x) + _2004.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1470 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1470.x) + vec3(_1470.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2033 = clamp(s.metallic, 0.0, 1.0);\n    float _2037 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2044 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2033));\n    vec3 f0 = _2044;\n    vec3 _2048 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2048;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2033;\n    float param_5 = _2037;\n    vec3 param_6 = _2044;\n    FaLayers _2065 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2065.on)\n    {\n        FaLayers param_7 = _2065;\n        vec3 param_8 = _2048;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2037;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2048;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2037;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _316 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _322 = fa_light_texel(param_1);\n    float _325 = _322.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _325 < 0.5;\n    vec3 l;\n    if (_331)\n    {\n        l = normalize(_316.xyz);\n    }\n    else\n    {\n        vec3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / vec3(max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / max(_316.w, 0.001000000047497451305389404296875);\n        float _366 = clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_325 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _396 = fa_light_texel(param_3);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _427;\n    if (_331)\n    {\n        _427 = 0;\n    }\n    else\n    {\n        _427 = (_325 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _322.xyz * atten, atten, 1.0, dist, _427);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _667;\n    if (i == 0)\n    {\n        _667 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _683;\n        if (i == 1)\n        {\n            _683 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _691;\n            if (i == 2)\n            {\n                _691 = fa_shadows[24].z;\n            }\n            else\n            {\n                _691 = fa_shadows[24].w;\n            }\n            _683 = _691;\n        }\n        _667 = _683;\n    }\n    return _667;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _655 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_655), sin(_655)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _729 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _734 = clamp(dot(n, l), 0.0, 1.0);\n    float _740 = sqrt(1.0 - (_734 * _734));\n    float _748 = min(_740 / max(_734, 0.20000000298023223876953125), 4.0);\n    float _753;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _753 = fa_shadows[26].y;\n    }\n    else\n    {\n        _753 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _778 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_753 * _740)), 1.0);\n    float _785 = _778.x;\n    bool _788 = _785 < fa_shadows[ci * 1 + 16].x;\n    bool _797;\n    if (!_788)\n    {\n        _797 = _785 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _797 = _788;\n    }\n    bool _806;\n    if (!_797)\n    {\n        _806 = _778.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _806 = _797;\n    }\n    bool _815;\n    if (!_806)\n    {\n        _815 = _778.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _822;\n    if (!_815)\n    {\n        _822 = _778.z > 1.0;\n    }\n    else\n    {\n        _822 = _815;\n    }\n    if (_822)\n    {\n        return -1.0;\n    }\n    float _831;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _831 = fa_shadows[26].x;\n    }\n    else\n    {\n        _831 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _850 = _778.z - ((_831 * (1.0 + (0.5 * _748))) / _729);\n    float _859 = ((fa_shadows[ci * 1 + 20].x * min(_748, 3.0)) * 0.5) / _729;\n    int _868 = int(fa_shadows[25].z + 0.5);\n    if (_868 == 1)\n    {\n        vec2 param = _778.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _879 = fa_shadow_depth(param, param_1);\n        return float(_850 <= _879);\n    }\n    float _886 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _889 = _868 == 2;\n    if (_889)\n    {\n        float _903 = clamp(((fa_shadows[25].w * _729) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _886;\n            vec2 _922 = fa_shadow_vogel(param_2, param_3, param_4) * _903;\n            vec2 param_5 = _778.xy + (_922 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _933 = fa_shadow_depth(param_5, param_6);\n            if (_933 < (_850 - (length(_922) * _859)))\n            {\n                sum += _933;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_850 - (sum / cnt), 0.0) * _729) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _977 = _889 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _977; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _977;\n        float param_9 = _886;\n        vec2 _996 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _778.xy + (_996 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1007 = fa_shadow_depth(param_10, param_11);\n        lit += float((_850 - (length(_996) * _859)) <= _1007);\n    }\n    return lit / float(_977);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1037 = int(fa_shadows[25].x + 0.5);\n    if (_1037 < 1)\n    {\n        return 1.0;\n    }\n    float _1053 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1037 - 1;\n    if (_1053 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1065 = _1037 > 1;\n    bool _1072;\n    if (_1065)\n    {\n        _1072 = _1053 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1072 = _1065;\n    }\n    if (_1072)\n    {\n        ci = 1;\n    }\n    bool _1076 = _1037 > 2;\n    bool _1083;\n    if (_1076)\n    {\n        _1083 = _1053 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1083 = _1076;\n    }\n    if (_1083)\n    {\n        ci = 2;\n    }\n    bool _1087 = _1037 > 3;\n    bool _1094;\n    if (_1087)\n    {\n        _1094 = _1053 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1094 = _1087;\n    }\n    if (_1094)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1037)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1120 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1120;\n        if (_1120 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1145;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1145 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1145 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1164 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1145, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1175 = clamp((_1053 - (fa_shadow_split_at(param_7) - _1164)) / _1164, 0.0, 1.0);\n        if (_1175 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1037)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1196 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1196;\n                if (_1196 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1175);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2138 = fa_lm.z > 0.5;\n    bool _2144;\n    if (_2138)\n    {\n        int param = li;\n        _2144 = fa_light_baked(param);\n    }\n    else\n    {\n        _2144 = _2138;\n    }\n    if (_2144)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2166 = fa_light_sample(param_2, param_3);\n    vec3 _3224 = _2166.direction;\n    vec3 _3219 = _2166.color;\n    float _3221 = _2166.shadow;\n    int _3229 = _2166.type;\n    if ((_3229 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3224;\n        float _2180 = fa_shadow_factor(param_4, param_5);\n        _3221 = _2180;\n        _3219 *= _2180;\n    }\n    return LightSample(_3224, _3219, _2166.attenuation, _3221, _2166._distance, _3229);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1220 = int(fa_shadows[25].x + 0.5);\n    float _1230 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1235 = _1220 > 0;\n    bool _1244;\n    if (_1235)\n    {\n        int param = _1220 - 1;\n        _1244 = _1230 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1244 = _1235;\n    }\n    if (_1244)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1251 = _1220 > 1;\n        bool _1258;\n        if (_1251)\n        {\n            _1258 = _1230 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1258 = _1251;\n        }\n        if (_1258)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1264 = _1220 > 2;\n        bool _1271;\n        if (_1264)\n        {\n            _1271 = _1230 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1271 = _1264;\n        }\n        if (_1271)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1277 = _1220 > 3;\n        bool _1284;\n        if (_1277)\n        {\n            _1284 = _1230 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1284 = _1277;\n        }\n        if (_1284)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2928 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2928 = -_2928;\n    }\n    vec3 _2580 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n    Surface _2588 = fa_standard_surface(param_1);\n    vec3 _2967 = _2588.albedo;\n    float _2968 = _2588.alpha;\n    vec3 _2969 = _2588.normal;\n    float _2970 = _2588.metallic;\n    float _2971 = _2588.roughness;\n    float _2972 = _2588.occlusion;\n    vec3 _2973 = _2588.emission;\n    float _2974 = _2588.clearcoat;\n    float _2975 = _2588.clearcoat_roughness;\n    vec3 _2976 = _2588.sheen_color;\n    float _2977 = _2588.sheen_roughness;\n    float _2978 = _2588.anisotropy;\n    float _2979 = _2588.anisotropy_rotation;\n    float _2980 = _2588.specular;\n    float _2981 = _2588.ior;\n    vec3 _2982 = _2588.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n    Surface param_3 = _2588;\n    surface(param_2, param_3);\n    _2967 = param_3.albedo;\n    _2968 = param_3.alpha;\n    _2969 = param_3.normal;\n    _2970 = param_3.metallic;\n    _2971 = param_3.roughness;\n    _2972 = param_3.occlusion;\n    _2973 = param_3.emission;\n    _2974 = param_3.clearcoat;\n    _2975 = param_3.clearcoat_roughness;\n    _2976 = param_3.sheen_color;\n    _2977 = param_3.sheen_roughness;\n    _2978 = param_3.anisotropy;\n    _2979 = param_3.anisotropy_rotation;\n    _2980 = param_3.specular;\n    _2981 = param_3.ior;\n    _2982 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2967;\n    }\n    else\n    {\n        vec3 _2609 = _2969;\n        vec3 _2610 = normalize(_2609);\n        _2969 = _2610;\n        vec3 param_4 = _2610;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n        Surface param_6 = Surface(_2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982);\n        vec3 param_7 = fa_indirect_diffuse(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2629 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2629; ln++)\n        {\n            int param_8 = ln;\n            int _2642 = fa_cl_light(param_8);\n            bool _2645 = fa_lm.z > 0.5;\n            bool _2651;\n            if (_2645)\n            {\n                int param_9 = _2642;\n                _2651 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _2651 = _2645;\n            }\n            if (_2651)\n            {\n                continue;\n            }\n            int param_10 = _2642;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2928;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n            Surface param_14 = Surface(_2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _2678 = result;\n    vec3 _2679 = _2678 + _2973;\n    result = _2679;\n    vec3 param_16 = _2679;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2688 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2695;\n    if (!_2688)\n    {\n        _2695 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2695 = _2688;\n    }\n    if (_2695)\n    {\n        vec3 _2704 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2710 = dot(_2704, fa_mesh_fs_params[9].xyz);\n        bool _2714 = fa_mesh_fs_params[9].w > 0.5;\n        float _2715;\n        if (_2714)\n        {\n            _2715 = _2710;\n        }\n        else\n        {\n            _2715 = length(_2704);\n        }\n        float _2727 = _2715 - fa_mesh_fs_params[8].x;\n        if (_2727 > 0.0)\n        {\n            float _2736 = fa_mesh_fs_params[7].w * _2727;\n            float tau = _2736 * _2736;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2752;\n                if (_2714)\n                {\n                    _2752 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2710);\n                }\n                else\n                {\n                    _2752 = fa_mesh_fs_params[0].y;\n                }\n                float _2773 = mix(_2752, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2715, 0.0, 1.0));\n                float _2777 = fa_world_pos.y - _2773;\n                float _2782 = _2773 - fa_mesh_fs_params[8].z;\n                float _2787 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2790 = _2782 <= 0.0;\n                bool _2791 = !_2790;\n                bool _2797;\n                if (_2791)\n                {\n                    _2797 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2797 = _2790;\n                }\n                float _2798;\n                if (_2797)\n                {\n                    _2798 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2798 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2782, 80.0));\n                }\n                bool _2825;\n                if (_2791)\n                {\n                    _2825 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2825 = _2790;\n                }\n                float _2826;\n                if (_2825)\n                {\n                    _2826 = fa_mesh_fs_params[8].y * _2782;\n                }\n                else\n                {\n                    _2826 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2782, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2851 = _2787 <= 0.0;\n                bool _2858;\n                if (!_2851)\n                {\n                    _2858 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2858 = _2851;\n                }\n                float _2859;\n                if (_2858)\n                {\n                    _2859 = fa_mesh_fs_params[8].y * _2787;\n                }\n                else\n                {\n                    _2859 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2787, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2886;\n                if (abs(_2777) < 0.001000000047497451305389404296875)\n                {\n                    _2886 = _2798;\n                }\n                else\n                {\n                    _2886 = (_2859 - _2826) / _2777;\n                }\n                tau += (_2727 * max(_2886, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2968);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_441",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_677",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1571[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _446 = fa_mesh_fs_params[19].x < 0.0;\n    bool _453;\n    if (!_446)\n    {\n        _453 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    bool _461;\n    if (!_453)\n    {\n        _461 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _461 = _453;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    if (_475)\n    {\n        return ivec2(0);\n    }\n    vec4 _485 = vec4(world_pos, 1.0);\n    float _492 = dot(fa_mesh_fs_params[16], _485);\n    if (!(_492 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _514 = vec2(dot(fa_mesh_fs_params[14], _485), dot(fa_mesh_fs_params[15], _485)) / vec2(_492);\n    int _518 = int(fa_mesh_fs_params[18].x);\n    int _522 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _522) + clamp(int(floor(((_514.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _522 - 1)) * _518)) + clamp(int(floor(((_514.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _518 - 1);\n    vec4 _593 = fa_light_texel(param);\n    return ivec2(int(_593.x), int(_593.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2111 = fa_cluster_lookup(param);\n    fa_cl_slot = _2111.x;\n    fa_cl_local = _2111.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2247 = fa_linear_to_srgb(param);\n        c = _2247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2255 = fa_srgb_to_linear(param_1);\n            c = _2255;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _205;\n    if (i.front_facing)\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    vec3 _229 = normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    vec3 _257 = normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    vec3 _260;\n    if (i.front_facing)\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2286 = fa_tex_fix(param_2, param_3);\n    vec4 _3305 = base_t;\n    _3305.x = _2286.x;\n    _3305.y = _2286.y;\n    _3305.z = _2286.z;\n    base_t = _3305;\n    vec4 _2300 = (_3305 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3239 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2332 = fa_tex_fix(param_6, param_7);\n        vec3 _2336 = (_2332 * 2.0) - vec3(1.0);\n        vec2 _2341 = _2336.xy * fa_mesh_fs_params[6].x;\n        vec3 _3313 = _2336;\n        _3313.x = _2341.x;\n        _3313.y = _2341.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3313;\n        _3239 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2370 = fa_tex_fix(param_12, param_13);\n    vec4 _3316 = mrt;\n    _3316.x = _2370.x;\n    _3316.y = _2370.y;\n    _3316.z = _2370.z;\n    mrt = _3316;\n    vec4 _2398 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2398.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2410 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2440 = fa_tex_fix(param_20, param_21);\n    float _3244 = fa_mesh_fs_params[20].x;\n    float _3245 = fa_mesh_fs_params[20].y;\n    float _3248 = fa_mesh_fs_params[20].z;\n    float _3247 = fa_mesh_fs_params[21].w;\n    float _3250 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3244 *= _2410.y;\n            _3245 *= _2410.z;\n            _3247 *= _2398.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3248 *= mrt.x;\n            _3250 *= mrt.w;\n        }\n    }\n    return Surface(_2300.xyz, _2300.w, _3239, clamp(fa_mesh_fs_params[5].x * _2370.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2370.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2410.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2440), _3244, _3245, fa_mesh_fs_params[21].xyz, _3247, _3248, fa_mesh_fs_params[20].w, _3250, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1496 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1504 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1507 = int(_1496);\n    int _1510 = int(_1504);\n    float _1520 = _1504 - float(_1510);\n    int _1576 = (_1507 * 9) + _1510;\n    int _1596 = ((_1507 + 1) * 9) + _1510;\n    return mix(mix(_1571[_1576], _1571[_1576 + 1], _1520), mix(_1571[_1596], _1571[_1596 + 1], _1520), _1496 - float(_1507));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3098 = false;\n    float _3099 = 1.0;\n    float _3100 = 1.0;\n    float _3101 = 1.0;\n    float _3102 = 0.0;\n    float _3103 = 0.0;\n    float _3104 = 0.0;\n    float _3105 = 0.0;\n    float _3107 = 1.0;\n    bool _3108 = false;\n    vec3 _3109 = vec3(0.0);\n    float _3110 = 1.0;\n    float _3111 = 1.0;\n    float _3112 = 1.0;\n    float _3113 = 0.0;\n    float _3114 = 0.0;\n    vec3 _3115 = vec3(1.0, 0.0, 0.0);\n    vec3 _3116 = vec3(0.0, 0.0, 1.0);\n    float _3117 = 1.0;\n    float _3118 = 1.0;\n    float _1651 = clamp(s.specular, 0.0, 1.0);\n    float _1655 = clamp(s.ior, 1.0, 3.0);\n    bool _1660 = (_1651 != 1.0) || (_1655 != 1.5);\n    bool _1670;\n    if (!_1660)\n    {\n        _1670 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1670 = _1660;\n    }\n    if (_1670)\n    {\n        float _1678 = (_1655 - 1.0) / (_1655 + 1.0);\n        f0 = mix(min(vec3(_1678 * _1678) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1651, s.albedo, vec3(metallic));\n        _3099 = mix(_1651, 1.0, metallic);\n        _3098 = true;\n    }\n    float _1706 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1706 > 0.0)\n    {\n        float _1714 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3102 = _1706;\n        _3103 = _1714;\n        float _1721 = _1714 * _1714;\n        _3104 = _1721;\n        _3105 = _1721 * _1721;\n        float _1733 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3107 = _1733;\n        _3100 = 1.0 - (_1706 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1733, 0.0, 1.0), 5.0))));\n        _3098 = true;\n    }\n    vec3 _1753 = max(s.sheen_color, vec3(0.0));\n    float _1762 = max(_1753.x, max(_1753.y, _1753.z));\n    if (_1762 > 0.0)\n    {\n        float _1770 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3108 = true;\n        _3109 = _1753;\n        _3110 = _1770;\n        _3111 = _1770 * _1770;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1770;\n        float _1787 = fa_sheen_albedo(param, param_1);\n        _3113 = _1787;\n        _3112 = 1.0 - min(_1762 * _1787, 1.0);\n        _3098 = true;\n    }\n    _3101 = _3100 * _3112;\n    float _1806 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1806 != 0.0)\n    {\n        vec3 _1821 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1821;\n        if (dot(_1821, _1821) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1835 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1835.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1835.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1835.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1839 = t;\n        vec3 _1840 = normalize(_1839);\n        t = _1840;\n        vec3 _1865 = normalize((_1840 * cos(s.anisotropy_rotation)) + ((cross(n, _1840) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3115 = _1865;\n        _3116 = cross(n, _1865);\n        float _1875 = roughness * roughness;\n        float _1881 = mix(_1875, 1.0, _1806 * _1806);\n        bool _1883 = _1806 > 0.0;\n        _3117 = _1883 ? _1881 : _1875;\n        _3118 = _1883 ? _1875 : _1881;\n        _3114 = _1806;\n        _3098 = true;\n    }\n    return FaLayers(_3098, _3099, _3100, _3101, _3102, _3103, _3104, _3105, i.world_normal, _3107, _3108, _3109, _3110, _3111, _3112, _3113, _3114, _3115, _3116, _3117, _3118);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1428 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1431 = _1428.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1431 * _1431, exp2((-9.27999973297119140625) * ndv)) * _1431) + _1428.y)) + _1428.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1333 = rough * rough;\n    float _1363 = 0.60000002384185791015625 * _1333;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1333)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1363, 0.0500000007450580596923828125 + _1363, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1333 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1916;\n        if (L.aniso >= 0.0)\n        {\n            _1916 = L.b;\n        }\n        else\n        {\n            _1916 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1916, v), _1916), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1949 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1949.x) + (vec3(L.f90) * _1949.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2004 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2004.x) + _2004.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1470 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1470.x) + vec3(_1470.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2033 = clamp(s.metallic, 0.0, 1.0);\n    float _2037 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2044 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2033));\n    vec3 f0 = _2044;\n    vec3 _2048 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2048;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2033;\n    float param_5 = _2037;\n    vec3 param_6 = _2044;\n    FaLayers _2065 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2065.on)\n    {\n        FaLayers param_7 = _2065;\n        vec3 param_8 = _2048;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2037;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2048;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2037;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _316 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _322 = fa_light_texel(param_1);\n    float _325 = _322.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _325 < 0.5;\n    vec3 l;\n    if (_331)\n    {\n        l = normalize(_316.xyz);\n    }\n    else\n    {\n        vec3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / vec3(max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / max(_316.w, 0.001000000047497451305389404296875);\n        float _366 = clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_325 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _396 = fa_light_texel(param_3);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _427;\n    if (_331)\n    {\n        _427 = 0;\n    }\n    else\n    {\n        _427 = (_325 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _322.xyz * atten, atten, 1.0, dist, _427);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _667;\n    if (i == 0)\n    {\n        _667 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _683;\n        if (i == 1)\n        {\n            _683 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _691;\n            if (i == 2)\n            {\n                _691 = fa_shadows[24].z;\n            }\n            else\n            {\n                _691 = fa_shadows[24].w;\n            }\n            _683 = _691;\n        }\n        _667 = _683;\n    }\n    return _667;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _655 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_655), sin(_655)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _729 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _734 = clamp(dot(n, l), 0.0, 1.0);\n    float _740 = sqrt(1.0 - (_734 * _734));\n    float _748 = min(_740 / max(_734, 0.20000000298023223876953125), 4.0);\n    float _753;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _753 = fa_shadows[26].y;\n    }\n    else\n    {\n        _753 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _778 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_753 * _740)), 1.0);\n    float _785 = _778.x;\n    bool _788 = _785 < fa_shadows[ci * 1 + 16].x;\n    bool _797;\n    if (!_788)\n    {\n        _797 = _785 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _797 = _788;\n    }\n    bool _806;\n    if (!_797)\n    {\n        _806 = _778.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _806 = _797;\n    }\n    bool _815;\n    if (!_806)\n    {\n        _815 = _778.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _822;\n    if (!_815)\n    {\n        _822 = _778.z > 1.0;\n    }\n    else\n    {\n        _822 = _815;\n    }\n    if (_822)\n    {\n        return -1.0;\n    }\n    float _831;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _831 = fa_shadows[26].x;\n    }\n    else\n    {\n        _831 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _850 = _778.z - ((_831 * (1.0 + (0.5 * _748))) / _729);\n    float _859 = ((fa_shadows[ci * 1 + 20].x * min(_748, 3.0)) * 0.5) / _729;\n    int _868 = int(fa_shadows[25].z + 0.5);\n    if (_868 == 1)\n    {\n        vec2 param = _778.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _879 = fa_shadow_depth(param, param_1);\n        return float(_850 <= _879);\n    }\n    float _886 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _889 = _868 == 2;\n    if (_889)\n    {\n        float _903 = clamp(((fa_shadows[25].w * _729) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _886;\n            vec2 _922 = fa_shadow_vogel(param_2, param_3, param_4) * _903;\n            vec2 param_5 = _778.xy + (_922 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _933 = fa_shadow_depth(param_5, param_6);\n            if (_933 < (_850 - (length(_922) * _859)))\n            {\n                sum += _933;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_850 - (sum / cnt), 0.0) * _729) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _977 = _889 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _977; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _977;\n        float param_9 = _886;\n        vec2 _996 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _778.xy + (_996 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1007 = fa_shadow_depth(param_10, param_11);\n        lit += float((_850 - (length(_996) * _859)) <= _1007);\n    }\n    return lit / float(_977);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1037 = int(fa_shadows[25].x + 0.5);\n    if (_1037 < 1)\n    {\n        return 1.0;\n    }\n    float _1053 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1037 - 1;\n    if (_1053 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1065 = _1037 > 1;\n    bool _1072;\n    if (_1065)\n    {\n        _1072 = _1053 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1072 = _1065;\n    }\n    if (_1072)\n    {\n        ci = 1;\n    }\n    bool _1076 = _1037 > 2;\n    bool _1083;\n    if (_1076)\n    {\n        _1083 = _1053 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1083 = _1076;\n    }\n    if (_1083)\n    {\n        ci = 2;\n    }\n    bool _1087 = _1037 > 3;\n    bool _1094;\n    if (_1087)\n    {\n        _1094 = _1053 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1094 = _1087;\n    }\n    if (_1094)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1037)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1120 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1120;\n        if (_1120 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1145;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1145 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1145 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1164 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1145, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1175 = clamp((_1053 - (fa_shadow_split_at(param_7) - _1164)) / _1164, 0.0, 1.0);\n        if (_1175 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1037)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1196 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1196;\n                if (_1196 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1175);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2138 = fa_lm.z > 0.5;\n    bool _2144;\n    if (_2138)\n    {\n        int param = li;\n        _2144 = fa_light_baked(param);\n    }\n    else\n    {\n        _2144 = _2138;\n    }\n    if (_2144)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2166 = fa_light_sample(param_2, param_3);\n    vec3 _3224 = _2166.direction;\n    vec3 _3219 = _2166.color;\n    float _3221 = _2166.shadow;\n    int _3229 = _2166.type;\n    if ((_3229 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3224;\n        float _2180 = fa_shadow_factor(param_4, param_5);\n        _3221 = _2180;\n        _3219 *= _2180;\n    }\n    return LightSample(_3224, _3219, _2166.attenuation, _3221, _2166._distance, _3229);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1220 = int(fa_shadows[25].x + 0.5);\n    float _1230 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1235 = _1220 > 0;\n    bool _1244;\n    if (_1235)\n    {\n        int param = _1220 - 1;\n        _1244 = _1230 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1244 = _1235;\n    }\n    if (_1244)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1251 = _1220 > 1;\n        bool _1258;\n        if (_1251)\n        {\n            _1258 = _1230 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1258 = _1251;\n        }\n        if (_1258)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1264 = _1220 > 2;\n        bool _1271;\n        if (_1264)\n        {\n            _1271 = _1230 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1271 = _1264;\n        }\n        if (_1271)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1277 = _1220 > 3;\n        bool _1284;\n        if (_1277)\n        {\n            _1284 = _1230 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1284 = _1277;\n        }\n        if (_1284)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2928 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2928 = -_2928;\n    }\n    vec3 _2580 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n    Surface _2588 = fa_standard_surface(param_1);\n    vec3 _2967 = _2588.albedo;\n    float _2968 = _2588.alpha;\n    vec3 _2969 = _2588.normal;\n    float _2970 = _2588.metallic;\n    float _2971 = _2588.roughness;\n    float _2972 = _2588.occlusion;\n    vec3 _2973 = _2588.emission;\n    float _2974 = _2588.clearcoat;\n    float _2975 = _2588.clearcoat_roughness;\n    vec3 _2976 = _2588.sheen_color;\n    float _2977 = _2588.sheen_roughness;\n    float _2978 = _2588.anisotropy;\n    float _2979 = _2588.anisotropy_rotation;\n    float _2980 = _2588.specular;\n    float _2981 = _2588.ior;\n    vec3 _2982 = _2588.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n    Surface param_3 = _2588;\n    surface(param_2, param_3);\n    _2967 = param_3.albedo;\n    _2968 = param_3.alpha;\n    _2969 = param_3.normal;\n    _2970 = param_3.metallic;\n    _2971 = param_3.roughness;\n    _2972 = param_3.occlusion;\n    _2973 = param_3.emission;\n    _2974 = param_3.clearcoat;\n    _2975 = param_3.clearcoat_roughness;\n    _2976 = param_3.sheen_color;\n    _2977 = param_3.sheen_roughness;\n    _2978 = param_3.anisotropy;\n    _2979 = param_3.anisotropy_rotation;\n    _2980 = param_3.specular;\n    _2981 = param_3.ior;\n    _2982 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2967;\n    }\n    else\n    {\n        vec3 _2609 = _2969;\n        vec3 _2610 = normalize(_2609);\n        _2969 = _2610;\n        vec3 param_4 = _2610;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n        Surface param_6 = Surface(_2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982);\n        vec3 param_7 = fa_indirect_diffuse(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2629 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2629; ln++)\n        {\n            int param_8 = ln;\n            int _2642 = fa_cl_light(param_8);\n            bool _2645 = fa_lm.z > 0.5;\n            bool _2651;\n            if (_2645)\n            {\n                int param_9 = _2642;\n                _2651 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _2651 = _2645;\n            }\n            if (_2651)\n            {\n                continue;\n            }\n            int param_10 = _2642;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2928;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2928, fa_world_tangent, fa_uv, fa_vertex_color, _2580, gl_FrontFacing);\n            Surface param_14 = Surface(_2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _2678 = result;\n    vec3 _2679 = _2678 + _2973;\n    result = _2679;\n    vec3 param_16 = _2679;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2688 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2695;\n    if (!_2688)\n    {\n        _2695 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2695 = _2688;\n    }\n    if (_2695)\n    {\n        vec3 _2704 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2710 = dot(_2704, fa_mesh_fs_params[9].xyz);\n        bool _2714 = fa_mesh_fs_params[9].w > 0.5;\n        float _2715;\n        if (_2714)\n        {\n            _2715 = _2710;\n        }\n        else\n        {\n            _2715 = length(_2704);\n        }\n        float _2727 = _2715 - fa_mesh_fs_params[8].x;\n        if (_2727 > 0.0)\n        {\n            float _2736 = fa_mesh_fs_params[7].w * _2727;\n            float tau = _2736 * _2736;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2752;\n                if (_2714)\n                {\n                    _2752 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2710);\n                }\n                else\n                {\n                    _2752 = fa_mesh_fs_params[0].y;\n                }\n                float _2773 = mix(_2752, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2715, 0.0, 1.0));\n                float _2777 = fa_world_pos.y - _2773;\n                float _2782 = _2773 - fa_mesh_fs_params[8].z;\n                float _2787 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2790 = _2782 <= 0.0;\n                bool _2791 = !_2790;\n                bool _2797;\n                if (_2791)\n                {\n                    _2797 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2797 = _2790;\n                }\n                float _2798;\n                if (_2797)\n                {\n                    _2798 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2798 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2782, 80.0));\n                }\n                bool _2825;\n                if (_2791)\n                {\n                    _2825 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2825 = _2790;\n                }\n                float _2826;\n                if (_2825)\n                {\n                    _2826 = fa_mesh_fs_params[8].y * _2782;\n                }\n                else\n                {\n                    _2826 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2782, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2851 = _2787 <= 0.0;\n                bool _2858;\n                if (!_2851)\n                {\n                    _2858 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2858 = _2851;\n                }\n                float _2859;\n                if (_2858)\n                {\n                    _2859 = fa_mesh_fs_params[8].y * _2787;\n                }\n                else\n                {\n                    _2859 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2787, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2886;\n                if (abs(_2777) < 0.001000000047497451305389404296875)\n                {\n                    _2886 = _2798;\n                }\n                else\n                {\n                    _2886 = (_2859 - _2826) / _2777;\n                }\n                tau += (_2727 * max(_2886, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2968);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_441",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_677",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
