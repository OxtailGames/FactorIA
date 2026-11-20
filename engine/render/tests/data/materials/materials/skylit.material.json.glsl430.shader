{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1877[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _755 = fa_mesh_fs_params[19].x < 0.0;\n    bool _762;\n    if (!_755)\n    {\n        _762 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _762 = _755;\n    }\n    bool _770;\n    if (!_762)\n    {\n        _770 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _770 = _762;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    bool _784;\n    if (!_777)\n    {\n        _784 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return ivec2(0);\n    }\n    vec4 _794 = vec4(world_pos, 1.0);\n    float _801 = dot(fa_mesh_fs_params[16], _794);\n    if (!(_801 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _823 = vec2(dot(fa_mesh_fs_params[14], _794), dot(fa_mesh_fs_params[15], _794)) / vec2(_801);\n    int _827 = int(fa_mesh_fs_params[18].x);\n    int _831 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _831) + clamp(int(floor(((_823.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _831 - 1)) * _827)) + clamp(int(floor(((_823.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _827 - 1);\n    vec4 _902 = fa_light_texel(param);\n    return ivec2(int(_902.x), int(_902.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2415 = fa_cluster_lookup(param);\n    fa_cl_slot = _2415.x;\n    fa_cl_local = _2415.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2524 = fa_linear_to_srgb(param);\n        c = _2524;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2532 = fa_srgb_to_linear(param_1);\n            c = _2532;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _215;\n    if (i.front_facing)\n    {\n        _215 = i.world_normal;\n    }\n    else\n    {\n        _215 = -i.world_normal;\n    }\n    vec3 _239 = normalize(i.world_tangent.xyz - (_215 * dot(_215, i.world_tangent.xyz)));\n    vec3 _267 = normalize(((_239 * m.x) + ((cross(_215, _239) * i.world_tangent.w) * m.y)) + (_215 * m.z));\n    vec3 _270;\n    if (i.front_facing)\n    {\n        _270 = _267;\n    }\n    else\n    {\n        _270 = -_267;\n    }\n    return _270;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2563 = fa_tex_fix(param_2, param_3);\n    vec4 _3547 = base_t;\n    _3547.x = _2563.x;\n    _3547.y = _2563.y;\n    _3547.z = _2563.z;\n    base_t = _3547;\n    vec4 _2577 = (_3547 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3471 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2609 = fa_tex_fix(param_6, param_7);\n        vec3 _2613 = (_2609 * 2.0) - vec3(1.0);\n        vec2 _2618 = _2613.xy * fa_mesh_fs_params[6].x;\n        vec3 _3555 = _2613;\n        _3555.x = _2618.x;\n        _3555.y = _2618.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3555;\n        _3471 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2646 = fa_tex_fix(param_12, param_13);\n    vec4 _3558 = mrt;\n    _3558.x = _2646.x;\n    _3558.y = _2646.y;\n    _3558.z = _2646.z;\n    mrt = _3558;\n    vec4 _2674 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2674.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2686 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2716 = fa_tex_fix(param_20, param_21);\n    float _3476 = fa_mesh_fs_params[20].x;\n    float _3477 = fa_mesh_fs_params[20].y;\n    float _3480 = fa_mesh_fs_params[20].z;\n    float _3479 = fa_mesh_fs_params[21].w;\n    float _3482 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3476 *= _2686.y;\n            _3477 *= _2686.z;\n            _3479 *= _2674.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3480 *= mrt.x;\n            _3482 *= mrt.w;\n        }\n    }\n    return Surface(_2577.xyz, _2577.w, _3471, clamp(fa_mesh_fs_params[5].x * _2646.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2646.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2686.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2716), _3476, _3477, fa_mesh_fs_params[21].xyz, _3479, _3480, fa_mesh_fs_params[20].w, _3482, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1802 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1810 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1813 = int(_1802);\n    int _1816 = int(_1810);\n    float _1826 = _1810 - float(_1816);\n    int _1882 = (_1813 * 9) + _1816;\n    int _1902 = ((_1813 + 1) * 9) + _1816;\n    return mix(mix(_1877[_1882], _1877[_1882 + 1], _1826), mix(_1877[_1902], _1877[_1902 + 1], _1826), _1802 - float(_1813));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3343 = false;\n    float _3344 = 1.0;\n    float _3345 = 1.0;\n    float _3346 = 1.0;\n    float _3347 = 0.0;\n    float _3348 = 0.0;\n    float _3349 = 0.0;\n    float _3350 = 0.0;\n    float _3352 = 1.0;\n    bool _3353 = false;\n    vec3 _3354 = vec3(0.0);\n    float _3355 = 1.0;\n    float _3356 = 1.0;\n    float _3357 = 1.0;\n    float _3358 = 0.0;\n    float _3359 = 0.0;\n    vec3 _3360 = vec3(1.0, 0.0, 0.0);\n    vec3 _3361 = vec3(0.0, 0.0, 1.0);\n    float _3362 = 1.0;\n    float _3363 = 1.0;\n    float _1956 = clamp(s.specular, 0.0, 1.0);\n    float _1960 = clamp(s.ior, 1.0, 3.0);\n    bool _1965 = (_1956 != 1.0) || (_1960 != 1.5);\n    bool _1974;\n    if (!_1965)\n    {\n        _1974 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1974 = _1965;\n    }\n    if (_1974)\n    {\n        float _1982 = (_1960 - 1.0) / (_1960 + 1.0);\n        f0 = mix(min(vec3(_1982 * _1982) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1956, s.albedo, vec3(metallic));\n        _3344 = mix(_1956, 1.0, metallic);\n        _3343 = true;\n    }\n    float _2010 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2010 > 0.0)\n    {\n        float _2018 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3347 = _2010;\n        _3348 = _2018;\n        float _2025 = _2018 * _2018;\n        _3349 = _2025;\n        _3350 = _2025 * _2025;\n        float _2037 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3352 = _2037;\n        _3345 = 1.0 - (_2010 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2037, 0.0, 1.0), 5.0))));\n        _3343 = true;\n    }\n    vec3 _2057 = max(s.sheen_color, vec3(0.0));\n    float _2066 = max(_2057.x, max(_2057.y, _2057.z));\n    if (_2066 > 0.0)\n    {\n        float _2074 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3353 = true;\n        _3354 = _2057;\n        _3355 = _2074;\n        _3356 = _2074 * _2074;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2074;\n        float _2091 = fa_sheen_albedo(param, param_1);\n        _3358 = _2091;\n        _3357 = 1.0 - min(_2066 * _2091, 1.0);\n        _3343 = true;\n    }\n    _3346 = _3345 * _3357;\n    float _2110 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2110 != 0.0)\n    {\n        vec3 _2125 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2125;\n        if (dot(_2125, _2125) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2139 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2139.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2139.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2139.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2143 = t;\n        vec3 _2144 = normalize(_2143);\n        t = _2144;\n        vec3 _2169 = normalize((_2144 * cos(s.anisotropy_rotation)) + ((cross(n, _2144) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3360 = _2169;\n        _3361 = cross(n, _2169);\n        float _2179 = roughness * roughness;\n        float _2185 = mix(_2179, 1.0, _2110 * _2110);\n        bool _2187 = _2110 > 0.0;\n        _3362 = _2187 ? _2185 : _2179;\n        _3363 = _2187 ? _2179 : _2185;\n        _3359 = _2110;\n        _3343 = true;\n    }\n    return FaLayers(_3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, i.world_normal, _3352, _3353, _3354, _3355, _3356, _3357, _3358, _3359, _3360, _3361, _3362, _3363);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1734 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1737 = _1734.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1737 * _1737, exp2((-9.27999973297119140625) * ndv)) * _1737) + _1734.y)) + _1734.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1639 = rough * rough;\n    float _1669 = 0.60000002384185791015625 * _1639;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1639)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1669, 0.0500000007450580596923828125 + _1669, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1639 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2220;\n        if (L.aniso >= 0.0)\n        {\n            _2220 = L.b;\n        }\n        else\n        {\n            _2220 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2220, v), _2220), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2253 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2253.x) + (vec3(L.f90) * _2253.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2308 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2308.x) + _2308.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1776 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1776.x) + vec3(_1776.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2337 = clamp(s.metallic, 0.0, 1.0);\n    float _2341 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2348 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2337));\n    vec3 f0 = _2348;\n    vec3 _2352 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2352;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2337;\n    float param_5 = _2341;\n    vec3 param_6 = _2348;\n    FaLayers _2369 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2369.on)\n    {\n        FaLayers param_7 = _2369;\n        vec3 param_8 = _2352;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2341;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2352;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2341;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _364 = dot(d, right);\n    float _368 = dot(d, up);\n    float _379;\n    if (((_364 * _364) + (_368 * _368)) > 1.0000000133514319600180897396058e-10)\n    {\n        _379 = atan(_368, _364) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _379 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_379 - floor(_379)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _412 = fa_light_base(param);\n    bool _416 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _412;\n    vec4 _420 = fa_light_texel(param_1);\n    int param_2 = _412 + 1;\n    vec4 _425 = fa_light_texel(param_2);\n    float _428 = _425.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _440 = _416 && (_428 > 2.5);\n    fa_light_is_area = _440;\n    bool _443 = _428 < 0.5;\n    vec3 l;\n    if (_443)\n    {\n        l = normalize(_420.xyz);\n        if (_416)\n        {\n            int param_3 = _412 + 6;\n            vec4 _457 = fa_light_texel(param_3);\n            if (_457.z > 0.5)\n            {\n                int param_4 = _412 + 4;\n                vec4 _467 = fa_light_texel(param_4);\n                int param_5 = _412 + 5;\n                vec4 _473 = fa_light_texel(param_5);\n                vec2 param_6 = _457.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _467.xyz) * _467.w, (-dot(world_pos, _473.xyz)) * _473.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _505 = _420.xyz - world_pos;\n        float _507 = length(_505);\n        dist = _507;\n        l = _505 / vec3(max(_507, 9.9999997473787516355514526367188e-05));\n        float reach = _507;\n        if (_440)\n        {\n            int param_8 = _412 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _539 = reach / max(_420.w, 0.001000000047497451305389404296875);\n        float _545 = clamp(1.0 - (_539 * _539), 0.0, 1.0);\n        atten = _545 * _545;\n        bool _553 = _428 < 2.5;\n        if ((_428 > 1.5) && _553)\n        {\n            int param_9 = _412 + 2;\n            vec4 _561 = fa_light_texel(param_9);\n            float _571 = _561.w;\n            int param_10 = _412 + 3;\n            vec4 _577 = fa_light_texel(param_10);\n            float _578 = _577.x;\n            float cos_inner = _578;\n            if (_578 > 1.5)\n            {\n                cos_inner = mix(_571, 1.0, 0.25);\n            }\n            atten *= smoothstep(_571, cos_inner, dot(-l, normalize(_561.xyz)));\n        }\n        if (_416 && _553)\n        {\n            int param_11 = _412 + 6;\n            vec4 _602 = fa_light_texel(param_11);\n            int param_12 = _412 + 7;\n            vec4 _607 = fa_light_texel(param_12);\n            bool _610 = _602.z > 0.5;\n            bool _617;\n            if (!_610)\n            {\n                _617 = _607.z > 0.5;\n            }\n            else\n            {\n                _617 = _610;\n            }\n            if (_617)\n            {\n                int param_13 = _412 + 2;\n                vec4 _624 = fa_light_texel(param_13);\n                vec3 _628 = normalize(_624.xyz);\n                int param_14 = _412 + 4;\n                vec4 _633 = fa_light_texel(param_14);\n                int param_15 = _412 + 5;\n                vec4 _638 = fa_light_texel(param_15);\n                if (_610)\n                {\n                    vec3 _646 = -_505;\n                    float _653 = _624.w;\n                    float _669 = 0.5 / max(dot(_646, _628) * (sqrt(max(1.0 - (_653 * _653), 0.0)) / max(_653, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _602.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_646, _633.xyz) * _669), 0.5 - (dot(_646, _638.xyz) * _669));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_607.z > 0.5)\n                {\n                    vec2 param_18 = _607.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _628;\n                    vec3 param_21 = _633.xyz;\n                    vec3 param_22 = _638.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _3331 = _425.xyz * atten;\n    if (_416)\n    {\n        _3331 *= fa_light_tint;\n    }\n    int _737;\n    if (_443)\n    {\n        _737 = 0;\n    }\n    else\n    {\n        _737 = ((_428 > 1.5) && (_428 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _3331, atten, 1.0, dist, _737);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _976;\n    if (i == 0)\n    {\n        _976 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _992;\n        if (i == 1)\n        {\n            _992 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1000;\n            if (i == 2)\n            {\n                _1000 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1000 = fa_shadows[24].w;\n            }\n            _992 = _1000;\n        }\n        _976 = _992;\n    }\n    return _976;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _964 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_964), sin(_964)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1038 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1043 = clamp(dot(n, l), 0.0, 1.0);\n    float _1049 = sqrt(1.0 - (_1043 * _1043));\n    float _1057 = min(_1049 / max(_1043, 0.20000000298023223876953125), 4.0);\n    float _1062;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1062 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1062 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1087 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1062 * _1049)), 1.0);\n    float _1094 = _1087.x;\n    bool _1097 = _1094 < fa_shadows[ci * 1 + 16].x;\n    bool _1106;\n    if (!_1097)\n    {\n        _1106 = _1094 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1106 = _1097;\n    }\n    bool _1115;\n    if (!_1106)\n    {\n        _1115 = _1087.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1115 = _1106;\n    }\n    bool _1124;\n    if (!_1115)\n    {\n        _1124 = _1087.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1124 = _1115;\n    }\n    bool _1131;\n    if (!_1124)\n    {\n        _1131 = _1087.z > 1.0;\n    }\n    else\n    {\n        _1131 = _1124;\n    }\n    if (_1131)\n    {\n        return -1.0;\n    }\n    float _1139;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1139 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1139 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1158 = _1087.z - ((_1139 * (1.0 + (0.5 * _1057))) / _1038);\n    float _1167 = ((fa_shadows[ci * 1 + 20].x * min(_1057, 3.0)) * 0.5) / _1038;\n    int _1176 = int(fa_shadows[25].z + 0.5);\n    if (_1176 == 1)\n    {\n        vec2 param = _1087.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1187 = fa_shadow_depth(param, param_1);\n        return float(_1158 <= _1187);\n    }\n    float _1194 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1197 = _1176 == 2;\n    if (_1197)\n    {\n        float _1211 = clamp(((fa_shadows[25].w * _1038) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1194;\n            vec2 _1230 = fa_shadow_vogel(param_2, param_3, param_4) * _1211;\n            vec2 param_5 = _1087.xy + (_1230 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1241 = fa_shadow_depth(param_5, param_6);\n            if (_1241 < (_1158 - (length(_1230) * _1167)))\n            {\n                sum += _1241;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1158 - (sum / cnt), 0.0) * _1038) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1285 = _1197 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1285; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1285;\n        float param_9 = _1194;\n        vec2 _1304 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1087.xy + (_1304 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1315 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1158 - (length(_1304) * _1167)) <= _1315);\n    }\n    return lit / float(_1285);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1345 = int(fa_shadows[25].x + 0.5);\n    if (_1345 < 1)\n    {\n        return 1.0;\n    }\n    float _1360 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1345 - 1;\n    if (_1360 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1372 = _1345 > 1;\n    bool _1379;\n    if (_1372)\n    {\n        _1379 = _1360 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    if (_1379)\n    {\n        ci = 1;\n    }\n    bool _1383 = _1345 > 2;\n    bool _1390;\n    if (_1383)\n    {\n        _1390 = _1360 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        ci = 2;\n    }\n    bool _1394 = _1345 > 3;\n    bool _1401;\n    if (_1394)\n    {\n        _1401 = _1360 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1401 = _1394;\n    }\n    if (_1401)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1345)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1427 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1427;\n        if (_1427 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1452;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1452 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1452 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1471 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1452, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1482 = clamp((_1360 - (fa_shadow_split_at(param_7) - _1471)) / _1471, 0.0, 1.0);\n        if (_1482 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1345)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1503 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1503;\n                if (_1503 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1482);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2443 = fa_light_sample(param, param_1);\n    vec3 _3451 = _2443.color;\n    float _3453 = _2443.shadow;\n    if ((_2443.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2443.direction;\n        float _2457 = fa_shadow_factor(param_2, param_3);\n        _3453 = _2457;\n        _3451 *= _2457;\n    }\n    return LightSample(_2443.direction, _3451, _2443.attenuation, _3453, _2443._distance, _2443.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1527 = int(fa_shadows[25].x + 0.5);\n    float _1537 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1542 = _1527 > 0;\n    bool _1551;\n    if (_1542)\n    {\n        int param = _1527 - 1;\n        _1551 = _1537 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1551 = _1542;\n    }\n    if (_1551)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1558 = _1527 > 1;\n        bool _1565;\n        if (_1558)\n        {\n            _1565 = _1537 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1565 = _1558;\n        }\n        if (_1565)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1571 = _1527 > 2;\n        bool _1578;\n        if (_1571)\n        {\n            _1578 = _1537 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1578 = _1571;\n        }\n        if (_1578)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1584 = _1527 > 3;\n        bool _1591;\n        if (_1584)\n        {\n            _1591 = _1537 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1591 = _1584;\n        }\n        if (_1591)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3173 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3173 = -_3173;\n    }\n    vec3 _2837 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n    Surface _2845 = fa_standard_surface(param_1);\n    vec3 _3212 = _2845.albedo;\n    float _3213 = _2845.alpha;\n    vec3 _3214 = _2845.normal;\n    float _3215 = _2845.metallic;\n    float _3216 = _2845.roughness;\n    float _3217 = _2845.occlusion;\n    vec3 _3218 = _2845.emission;\n    float _3219 = _2845.clearcoat;\n    float _3220 = _2845.clearcoat_roughness;\n    vec3 _3221 = _2845.sheen_color;\n    float _3222 = _2845.sheen_roughness;\n    float _3223 = _2845.anisotropy;\n    float _3224 = _2845.anisotropy_rotation;\n    float _3225 = _2845.specular;\n    float _3226 = _2845.ior;\n    vec3 _3227 = _2845.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n    Surface param_3 = _2845;\n    surface(param_2, param_3);\n    _3212 = param_3.albedo;\n    _3213 = param_3.alpha;\n    _3214 = param_3.normal;\n    _3215 = param_3.metallic;\n    _3216 = param_3.roughness;\n    _3217 = param_3.occlusion;\n    _3218 = param_3.emission;\n    _3219 = param_3.clearcoat;\n    _3220 = param_3.clearcoat_roughness;\n    _3221 = param_3.sheen_color;\n    _3222 = param_3.sheen_roughness;\n    _3223 = param_3.anisotropy;\n    _3224 = param_3.anisotropy_rotation;\n    _3225 = param_3.specular;\n    _3226 = param_3.ior;\n    _3227 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3212;\n    }\n    else\n    {\n        vec3 _2866 = _3214;\n        vec3 _2867 = normalize(_2866);\n        _3214 = _2867;\n        vec3 param_4 = _2867;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n        Surface param_6 = Surface(_3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227);\n        vec3 param_7 = fa_ambient_light(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2886 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2886; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            vec3 param_10 = fa_world_pos;\n            vec3 param_11 = _3173;\n            LightSample _2908 = fa_light_shadowed(param_9, param_10, param_11);\n            SurfaceInput param_12 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n            Surface param_13 = Surface(_3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227);\n            LightSample param_14 = _2908;\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    vec3 _2923 = result;\n    vec3 _2924 = _2923 + _3218;\n    result = _2924;\n    vec3 param_15 = _2924;\n    vec3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2933 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2940;\n    if (!_2933)\n    {\n        _2940 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2940 = _2933;\n    }\n    if (_2940)\n    {\n        vec3 _2949 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2955 = dot(_2949, fa_mesh_fs_params[9].xyz);\n        bool _2959 = fa_mesh_fs_params[9].w > 0.5;\n        float _2960;\n        if (_2959)\n        {\n            _2960 = _2955;\n        }\n        else\n        {\n            _2960 = length(_2949);\n        }\n        float _2972 = _2960 - fa_mesh_fs_params[8].x;\n        if (_2972 > 0.0)\n        {\n            float _2981 = fa_mesh_fs_params[7].w * _2972;\n            float tau = _2981 * _2981;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2997;\n                if (_2959)\n                {\n                    _2997 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2955);\n                }\n                else\n                {\n                    _2997 = fa_mesh_fs_params[0].y;\n                }\n                float _3018 = mix(_2997, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2960, 0.0, 1.0));\n                float _3022 = fa_world_pos.y - _3018;\n                float _3027 = _3018 - fa_mesh_fs_params[8].z;\n                float _3032 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3035 = _3027 <= 0.0;\n                bool _3036 = !_3035;\n                bool _3042;\n                if (_3036)\n                {\n                    _3042 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3042 = _3035;\n                }\n                float _3043;\n                if (_3042)\n                {\n                    _3043 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3043 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3027, 80.0));\n                }\n                bool _3070;\n                if (_3036)\n                {\n                    _3070 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3070 = _3035;\n                }\n                float _3071;\n                if (_3070)\n                {\n                    _3071 = fa_mesh_fs_params[8].y * _3027;\n                }\n                else\n                {\n                    _3071 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3027, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3096 = _3032 <= 0.0;\n                bool _3103;\n                if (!_3096)\n                {\n                    _3103 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3103 = _3096;\n                }\n                float _3104;\n                if (_3103)\n                {\n                    _3104 = fa_mesh_fs_params[8].y * _3032;\n                }\n                else\n                {\n                    _3104 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3032, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3131;\n                if (abs(_3022) < 0.001000000047497451305389404296875)\n                {\n                    _3131 = _3043;\n                }\n                else\n                {\n                    _3131 = (_3104 - _3071) / _3022;\n                }\n                tau += (_2972 * max(_3131, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3213);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_283",
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
            "inst_name": "_986",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_386, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1877[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _755 = fa_mesh_fs_params[19].x < 0.0;\n    bool _762;\n    if (!_755)\n    {\n        _762 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _762 = _755;\n    }\n    bool _770;\n    if (!_762)\n    {\n        _770 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _770 = _762;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    bool _784;\n    if (!_777)\n    {\n        _784 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return ivec2(0);\n    }\n    vec4 _794 = vec4(world_pos, 1.0);\n    float _801 = dot(fa_mesh_fs_params[16], _794);\n    if (!(_801 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _823 = vec2(dot(fa_mesh_fs_params[14], _794), dot(fa_mesh_fs_params[15], _794)) / vec2(_801);\n    int _827 = int(fa_mesh_fs_params[18].x);\n    int _831 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _831) + clamp(int(floor(((_823.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _831 - 1)) * _827)) + clamp(int(floor(((_823.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _827 - 1);\n    vec4 _902 = fa_light_texel(param);\n    return ivec2(int(_902.x), int(_902.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2415 = fa_cluster_lookup(param);\n    fa_cl_slot = _2415.x;\n    fa_cl_local = _2415.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2524 = fa_linear_to_srgb(param);\n        c = _2524;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2532 = fa_srgb_to_linear(param_1);\n            c = _2532;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _215;\n    if (i.front_facing)\n    {\n        _215 = i.world_normal;\n    }\n    else\n    {\n        _215 = -i.world_normal;\n    }\n    vec3 _239 = normalize(i.world_tangent.xyz - (_215 * dot(_215, i.world_tangent.xyz)));\n    vec3 _267 = normalize(((_239 * m.x) + ((cross(_215, _239) * i.world_tangent.w) * m.y)) + (_215 * m.z));\n    vec3 _270;\n    if (i.front_facing)\n    {\n        _270 = _267;\n    }\n    else\n    {\n        _270 = -_267;\n    }\n    return _270;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2563 = fa_tex_fix(param_2, param_3);\n    vec4 _3547 = base_t;\n    _3547.x = _2563.x;\n    _3547.y = _2563.y;\n    _3547.z = _2563.z;\n    base_t = _3547;\n    vec4 _2577 = (_3547 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3471 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2609 = fa_tex_fix(param_6, param_7);\n        vec3 _2613 = (_2609 * 2.0) - vec3(1.0);\n        vec2 _2618 = _2613.xy * fa_mesh_fs_params[6].x;\n        vec3 _3555 = _2613;\n        _3555.x = _2618.x;\n        _3555.y = _2618.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3555;\n        _3471 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2646 = fa_tex_fix(param_12, param_13);\n    vec4 _3558 = mrt;\n    _3558.x = _2646.x;\n    _3558.y = _2646.y;\n    _3558.z = _2646.z;\n    mrt = _3558;\n    vec4 _2674 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2674.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2686 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2716 = fa_tex_fix(param_20, param_21);\n    float _3476 = fa_mesh_fs_params[20].x;\n    float _3477 = fa_mesh_fs_params[20].y;\n    float _3480 = fa_mesh_fs_params[20].z;\n    float _3479 = fa_mesh_fs_params[21].w;\n    float _3482 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3476 *= _2686.y;\n            _3477 *= _2686.z;\n            _3479 *= _2674.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3480 *= mrt.x;\n            _3482 *= mrt.w;\n        }\n    }\n    return Surface(_2577.xyz, _2577.w, _3471, clamp(fa_mesh_fs_params[5].x * _2646.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2646.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2686.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2716), _3476, _3477, fa_mesh_fs_params[21].xyz, _3479, _3480, fa_mesh_fs_params[20].w, _3482, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1802 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1810 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1813 = int(_1802);\n    int _1816 = int(_1810);\n    float _1826 = _1810 - float(_1816);\n    int _1882 = (_1813 * 9) + _1816;\n    int _1902 = ((_1813 + 1) * 9) + _1816;\n    return mix(mix(_1877[_1882], _1877[_1882 + 1], _1826), mix(_1877[_1902], _1877[_1902 + 1], _1826), _1802 - float(_1813));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3343 = false;\n    float _3344 = 1.0;\n    float _3345 = 1.0;\n    float _3346 = 1.0;\n    float _3347 = 0.0;\n    float _3348 = 0.0;\n    float _3349 = 0.0;\n    float _3350 = 0.0;\n    float _3352 = 1.0;\n    bool _3353 = false;\n    vec3 _3354 = vec3(0.0);\n    float _3355 = 1.0;\n    float _3356 = 1.0;\n    float _3357 = 1.0;\n    float _3358 = 0.0;\n    float _3359 = 0.0;\n    vec3 _3360 = vec3(1.0, 0.0, 0.0);\n    vec3 _3361 = vec3(0.0, 0.0, 1.0);\n    float _3362 = 1.0;\n    float _3363 = 1.0;\n    float _1956 = clamp(s.specular, 0.0, 1.0);\n    float _1960 = clamp(s.ior, 1.0, 3.0);\n    bool _1965 = (_1956 != 1.0) || (_1960 != 1.5);\n    bool _1974;\n    if (!_1965)\n    {\n        _1974 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1974 = _1965;\n    }\n    if (_1974)\n    {\n        float _1982 = (_1960 - 1.0) / (_1960 + 1.0);\n        f0 = mix(min(vec3(_1982 * _1982) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1956, s.albedo, vec3(metallic));\n        _3344 = mix(_1956, 1.0, metallic);\n        _3343 = true;\n    }\n    float _2010 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2010 > 0.0)\n    {\n        float _2018 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3347 = _2010;\n        _3348 = _2018;\n        float _2025 = _2018 * _2018;\n        _3349 = _2025;\n        _3350 = _2025 * _2025;\n        float _2037 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3352 = _2037;\n        _3345 = 1.0 - (_2010 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2037, 0.0, 1.0), 5.0))));\n        _3343 = true;\n    }\n    vec3 _2057 = max(s.sheen_color, vec3(0.0));\n    float _2066 = max(_2057.x, max(_2057.y, _2057.z));\n    if (_2066 > 0.0)\n    {\n        float _2074 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3353 = true;\n        _3354 = _2057;\n        _3355 = _2074;\n        _3356 = _2074 * _2074;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2074;\n        float _2091 = fa_sheen_albedo(param, param_1);\n        _3358 = _2091;\n        _3357 = 1.0 - min(_2066 * _2091, 1.0);\n        _3343 = true;\n    }\n    _3346 = _3345 * _3357;\n    float _2110 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2110 != 0.0)\n    {\n        vec3 _2125 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2125;\n        if (dot(_2125, _2125) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2139 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2139.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2139.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2139.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2143 = t;\n        vec3 _2144 = normalize(_2143);\n        t = _2144;\n        vec3 _2169 = normalize((_2144 * cos(s.anisotropy_rotation)) + ((cross(n, _2144) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3360 = _2169;\n        _3361 = cross(n, _2169);\n        float _2179 = roughness * roughness;\n        float _2185 = mix(_2179, 1.0, _2110 * _2110);\n        bool _2187 = _2110 > 0.0;\n        _3362 = _2187 ? _2185 : _2179;\n        _3363 = _2187 ? _2179 : _2185;\n        _3359 = _2110;\n        _3343 = true;\n    }\n    return FaLayers(_3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, i.world_normal, _3352, _3353, _3354, _3355, _3356, _3357, _3358, _3359, _3360, _3361, _3362, _3363);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1734 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1737 = _1734.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1737 * _1737, exp2((-9.27999973297119140625) * ndv)) * _1737) + _1734.y)) + _1734.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1639 = rough * rough;\n    float _1669 = 0.60000002384185791015625 * _1639;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1639)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1669, 0.0500000007450580596923828125 + _1669, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1639 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2220;\n        if (L.aniso >= 0.0)\n        {\n            _2220 = L.b;\n        }\n        else\n        {\n            _2220 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2220, v), _2220), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2253 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2253.x) + (vec3(L.f90) * _2253.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2308 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2308.x) + _2308.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1776 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1776.x) + vec3(_1776.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2337 = clamp(s.metallic, 0.0, 1.0);\n    float _2341 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2348 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2337));\n    vec3 f0 = _2348;\n    vec3 _2352 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2352;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2337;\n    float param_5 = _2341;\n    vec3 param_6 = _2348;\n    FaLayers _2369 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2369.on)\n    {\n        FaLayers param_7 = _2369;\n        vec3 param_8 = _2352;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2341;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2352;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2341;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _364 = dot(d, right);\n    float _368 = dot(d, up);\n    float _379;\n    if (((_364 * _364) + (_368 * _368)) > 1.0000000133514319600180897396058e-10)\n    {\n        _379 = atan(_368, _364) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _379 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_379 - floor(_379)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _412 = fa_light_base(param);\n    bool _416 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _412;\n    vec4 _420 = fa_light_texel(param_1);\n    int param_2 = _412 + 1;\n    vec4 _425 = fa_light_texel(param_2);\n    float _428 = _425.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _440 = _416 && (_428 > 2.5);\n    fa_light_is_area = _440;\n    bool _443 = _428 < 0.5;\n    vec3 l;\n    if (_443)\n    {\n        l = normalize(_420.xyz);\n        if (_416)\n        {\n            int param_3 = _412 + 6;\n            vec4 _457 = fa_light_texel(param_3);\n            if (_457.z > 0.5)\n            {\n                int param_4 = _412 + 4;\n                vec4 _467 = fa_light_texel(param_4);\n                int param_5 = _412 + 5;\n                vec4 _473 = fa_light_texel(param_5);\n                vec2 param_6 = _457.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _467.xyz) * _467.w, (-dot(world_pos, _473.xyz)) * _473.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _505 = _420.xyz - world_pos;\n        float _507 = length(_505);\n        dist = _507;\n        l = _505 / vec3(max(_507, 9.9999997473787516355514526367188e-05));\n        float reach = _507;\n        if (_440)\n        {\n            int param_8 = _412 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _539 = reach / max(_420.w, 0.001000000047497451305389404296875);\n        float _545 = clamp(1.0 - (_539 * _539), 0.0, 1.0);\n        atten = _545 * _545;\n        bool _553 = _428 < 2.5;\n        if ((_428 > 1.5) && _553)\n        {\n            int param_9 = _412 + 2;\n            vec4 _561 = fa_light_texel(param_9);\n            float _571 = _561.w;\n            int param_10 = _412 + 3;\n            vec4 _577 = fa_light_texel(param_10);\n            float _578 = _577.x;\n            float cos_inner = _578;\n            if (_578 > 1.5)\n            {\n                cos_inner = mix(_571, 1.0, 0.25);\n            }\n            atten *= smoothstep(_571, cos_inner, dot(-l, normalize(_561.xyz)));\n        }\n        if (_416 && _553)\n        {\n            int param_11 = _412 + 6;\n            vec4 _602 = fa_light_texel(param_11);\n            int param_12 = _412 + 7;\n            vec4 _607 = fa_light_texel(param_12);\n            bool _610 = _602.z > 0.5;\n            bool _617;\n            if (!_610)\n            {\n                _617 = _607.z > 0.5;\n            }\n            else\n            {\n                _617 = _610;\n            }\n            if (_617)\n            {\n                int param_13 = _412 + 2;\n                vec4 _624 = fa_light_texel(param_13);\n                vec3 _628 = normalize(_624.xyz);\n                int param_14 = _412 + 4;\n                vec4 _633 = fa_light_texel(param_14);\n                int param_15 = _412 + 5;\n                vec4 _638 = fa_light_texel(param_15);\n                if (_610)\n                {\n                    vec3 _646 = -_505;\n                    float _653 = _624.w;\n                    float _669 = 0.5 / max(dot(_646, _628) * (sqrt(max(1.0 - (_653 * _653), 0.0)) / max(_653, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _602.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_646, _633.xyz) * _669), 0.5 - (dot(_646, _638.xyz) * _669));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_607.z > 0.5)\n                {\n                    vec2 param_18 = _607.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _628;\n                    vec3 param_21 = _633.xyz;\n                    vec3 param_22 = _638.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _3331 = _425.xyz * atten;\n    if (_416)\n    {\n        _3331 *= fa_light_tint;\n    }\n    int _737;\n    if (_443)\n    {\n        _737 = 0;\n    }\n    else\n    {\n        _737 = ((_428 > 1.5) && (_428 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _3331, atten, 1.0, dist, _737);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _976;\n    if (i == 0)\n    {\n        _976 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _992;\n        if (i == 1)\n        {\n            _992 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1000;\n            if (i == 2)\n            {\n                _1000 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1000 = fa_shadows[24].w;\n            }\n            _992 = _1000;\n        }\n        _976 = _992;\n    }\n    return _976;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _964 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_964), sin(_964)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1038 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1043 = clamp(dot(n, l), 0.0, 1.0);\n    float _1049 = sqrt(1.0 - (_1043 * _1043));\n    float _1057 = min(_1049 / max(_1043, 0.20000000298023223876953125), 4.0);\n    float _1062;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1062 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1062 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1087 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1062 * _1049)), 1.0);\n    float _1094 = _1087.x;\n    bool _1097 = _1094 < fa_shadows[ci * 1 + 16].x;\n    bool _1106;\n    if (!_1097)\n    {\n        _1106 = _1094 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1106 = _1097;\n    }\n    bool _1115;\n    if (!_1106)\n    {\n        _1115 = _1087.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1115 = _1106;\n    }\n    bool _1124;\n    if (!_1115)\n    {\n        _1124 = _1087.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1124 = _1115;\n    }\n    bool _1131;\n    if (!_1124)\n    {\n        _1131 = _1087.z > 1.0;\n    }\n    else\n    {\n        _1131 = _1124;\n    }\n    if (_1131)\n    {\n        return -1.0;\n    }\n    float _1139;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1139 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1139 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1158 = _1087.z - ((_1139 * (1.0 + (0.5 * _1057))) / _1038);\n    float _1167 = ((fa_shadows[ci * 1 + 20].x * min(_1057, 3.0)) * 0.5) / _1038;\n    int _1176 = int(fa_shadows[25].z + 0.5);\n    if (_1176 == 1)\n    {\n        vec2 param = _1087.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1187 = fa_shadow_depth(param, param_1);\n        return float(_1158 <= _1187);\n    }\n    float _1194 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1197 = _1176 == 2;\n    if (_1197)\n    {\n        float _1211 = clamp(((fa_shadows[25].w * _1038) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1194;\n            vec2 _1230 = fa_shadow_vogel(param_2, param_3, param_4) * _1211;\n            vec2 param_5 = _1087.xy + (_1230 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1241 = fa_shadow_depth(param_5, param_6);\n            if (_1241 < (_1158 - (length(_1230) * _1167)))\n            {\n                sum += _1241;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1158 - (sum / cnt), 0.0) * _1038) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1285 = _1197 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1285; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1285;\n        float param_9 = _1194;\n        vec2 _1304 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1087.xy + (_1304 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1315 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1158 - (length(_1304) * _1167)) <= _1315);\n    }\n    return lit / float(_1285);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1345 = int(fa_shadows[25].x + 0.5);\n    if (_1345 < 1)\n    {\n        return 1.0;\n    }\n    float _1360 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1345 - 1;\n    if (_1360 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1372 = _1345 > 1;\n    bool _1379;\n    if (_1372)\n    {\n        _1379 = _1360 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    if (_1379)\n    {\n        ci = 1;\n    }\n    bool _1383 = _1345 > 2;\n    bool _1390;\n    if (_1383)\n    {\n        _1390 = _1360 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        ci = 2;\n    }\n    bool _1394 = _1345 > 3;\n    bool _1401;\n    if (_1394)\n    {\n        _1401 = _1360 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1401 = _1394;\n    }\n    if (_1401)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1345)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1427 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1427;\n        if (_1427 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1452;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1452 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1452 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1471 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1452, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1482 = clamp((_1360 - (fa_shadow_split_at(param_7) - _1471)) / _1471, 0.0, 1.0);\n        if (_1482 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1345)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1503 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1503;\n                if (_1503 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1482);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2443 = fa_light_sample(param, param_1);\n    vec3 _3451 = _2443.color;\n    float _3453 = _2443.shadow;\n    if ((_2443.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2443.direction;\n        float _2457 = fa_shadow_factor(param_2, param_3);\n        _3453 = _2457;\n        _3451 *= _2457;\n    }\n    return LightSample(_2443.direction, _3451, _2443.attenuation, _3453, _2443._distance, _2443.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1527 = int(fa_shadows[25].x + 0.5);\n    float _1537 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1542 = _1527 > 0;\n    bool _1551;\n    if (_1542)\n    {\n        int param = _1527 - 1;\n        _1551 = _1537 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1551 = _1542;\n    }\n    if (_1551)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1558 = _1527 > 1;\n        bool _1565;\n        if (_1558)\n        {\n            _1565 = _1537 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1565 = _1558;\n        }\n        if (_1565)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1571 = _1527 > 2;\n        bool _1578;\n        if (_1571)\n        {\n            _1578 = _1537 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1578 = _1571;\n        }\n        if (_1578)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1584 = _1527 > 3;\n        bool _1591;\n        if (_1584)\n        {\n            _1591 = _1537 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1591 = _1584;\n        }\n        if (_1591)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3173 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3173 = -_3173;\n    }\n    vec3 _2837 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n    Surface _2845 = fa_standard_surface(param_1);\n    vec3 _3212 = _2845.albedo;\n    float _3213 = _2845.alpha;\n    vec3 _3214 = _2845.normal;\n    float _3215 = _2845.metallic;\n    float _3216 = _2845.roughness;\n    float _3217 = _2845.occlusion;\n    vec3 _3218 = _2845.emission;\n    float _3219 = _2845.clearcoat;\n    float _3220 = _2845.clearcoat_roughness;\n    vec3 _3221 = _2845.sheen_color;\n    float _3222 = _2845.sheen_roughness;\n    float _3223 = _2845.anisotropy;\n    float _3224 = _2845.anisotropy_rotation;\n    float _3225 = _2845.specular;\n    float _3226 = _2845.ior;\n    vec3 _3227 = _2845.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n    Surface param_3 = _2845;\n    surface(param_2, param_3);\n    _3212 = param_3.albedo;\n    _3213 = param_3.alpha;\n    _3214 = param_3.normal;\n    _3215 = param_3.metallic;\n    _3216 = param_3.roughness;\n    _3217 = param_3.occlusion;\n    _3218 = param_3.emission;\n    _3219 = param_3.clearcoat;\n    _3220 = param_3.clearcoat_roughness;\n    _3221 = param_3.sheen_color;\n    _3222 = param_3.sheen_roughness;\n    _3223 = param_3.anisotropy;\n    _3224 = param_3.anisotropy_rotation;\n    _3225 = param_3.specular;\n    _3226 = param_3.ior;\n    _3227 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3212;\n    }\n    else\n    {\n        vec3 _2866 = _3214;\n        vec3 _2867 = normalize(_2866);\n        _3214 = _2867;\n        vec3 param_4 = _2867;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n        Surface param_6 = Surface(_3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227);\n        vec3 param_7 = fa_ambient_light(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2886 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2886; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            vec3 param_10 = fa_world_pos;\n            vec3 param_11 = _3173;\n            LightSample _2908 = fa_light_shadowed(param_9, param_10, param_11);\n            SurfaceInput param_12 = SurfaceInput(fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing);\n            Surface param_13 = Surface(_3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227);\n            LightSample param_14 = _2908;\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    vec3 _2923 = result;\n    vec3 _2924 = _2923 + _3218;\n    result = _2924;\n    vec3 param_15 = _2924;\n    vec3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2933 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2940;\n    if (!_2933)\n    {\n        _2940 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2940 = _2933;\n    }\n    if (_2940)\n    {\n        vec3 _2949 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2955 = dot(_2949, fa_mesh_fs_params[9].xyz);\n        bool _2959 = fa_mesh_fs_params[9].w > 0.5;\n        float _2960;\n        if (_2959)\n        {\n            _2960 = _2955;\n        }\n        else\n        {\n            _2960 = length(_2949);\n        }\n        float _2972 = _2960 - fa_mesh_fs_params[8].x;\n        if (_2972 > 0.0)\n        {\n            float _2981 = fa_mesh_fs_params[7].w * _2972;\n            float tau = _2981 * _2981;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2997;\n                if (_2959)\n                {\n                    _2997 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2955);\n                }\n                else\n                {\n                    _2997 = fa_mesh_fs_params[0].y;\n                }\n                float _3018 = mix(_2997, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2960, 0.0, 1.0));\n                float _3022 = fa_world_pos.y - _3018;\n                float _3027 = _3018 - fa_mesh_fs_params[8].z;\n                float _3032 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3035 = _3027 <= 0.0;\n                bool _3036 = !_3035;\n                bool _3042;\n                if (_3036)\n                {\n                    _3042 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3042 = _3035;\n                }\n                float _3043;\n                if (_3042)\n                {\n                    _3043 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3043 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3027, 80.0));\n                }\n                bool _3070;\n                if (_3036)\n                {\n                    _3070 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3070 = _3035;\n                }\n                float _3071;\n                if (_3070)\n                {\n                    _3071 = fa_mesh_fs_params[8].y * _3027;\n                }\n                else\n                {\n                    _3071 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3027, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3096 = _3032 <= 0.0;\n                bool _3103;\n                if (!_3096)\n                {\n                    _3103 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3103 = _3096;\n                }\n                float _3104;\n                if (_3103)\n                {\n                    _3104 = fa_mesh_fs_params[8].y * _3032;\n                }\n                else\n                {\n                    _3104 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3032, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3131;\n                if (abs(_3022) < 0.001000000047497451305389404296875)\n                {\n                    _3131 = _3043;\n                }\n                else\n                {\n                    _3131 = (_3104 - _3071) / _3022;\n                }\n                tau += (_2972 * max(_3131, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3213);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_283",
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
            "inst_name": "_986",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
