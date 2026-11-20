{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "glsl430",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1985[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _863 = fa_mesh_fs_params[19].x < 0.0;\n    bool _870;\n    if (!_863)\n    {\n        _870 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _870 = _863;\n    }\n    bool _878;\n    if (!_870)\n    {\n        _878 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _878 = _870;\n    }\n    bool _885;\n    if (!_878)\n    {\n        _885 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _885 = _878;\n    }\n    bool _892;\n    if (!_885)\n    {\n        _892 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _892 = _885;\n    }\n    if (_892)\n    {\n        return ivec2(0);\n    }\n    vec4 _902 = vec4(world_pos, 1.0);\n    float _909 = dot(fa_mesh_fs_params[16], _902);\n    if (!(_909 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _931 = vec2(dot(fa_mesh_fs_params[14], _902), dot(fa_mesh_fs_params[15], _902)) / vec2(_909);\n    int _935 = int(fa_mesh_fs_params[18].x);\n    int _939 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _939) + clamp(int(floor(((_931.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _939 - 1)) * _935)) + clamp(int(floor(((_931.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _935 - 1);\n    vec4 _1010 = fa_light_texel(param);\n    return ivec2(int(_1010.x), int(_1010.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2802 = fa_cluster_lookup(param);\n    fa_cl_slot = _2802.x;\n    fa_cl_local = _2802.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3716 = fa_linear_to_srgb(param);\n        c = _3716;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3724 = fa_srgb_to_linear(param_1);\n            c = _3724;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _313;\n    if (i.front_facing)\n    {\n        _313 = i.world_normal;\n    }\n    else\n    {\n        _313 = -i.world_normal;\n    }\n    vec3 _337 = normalize(i.world_tangent.xyz - (_313 * dot(_313, i.world_tangent.xyz)));\n    vec3 _365 = normalize(((_337 * m.x) + ((cross(_313, _337) * i.world_tangent.w) * m.y)) + (_313 * m.z));\n    vec3 _368;\n    if (i.front_facing)\n    {\n        _368 = _365;\n    }\n    else\n    {\n        _368 = -_365;\n    }\n    return _368;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3755 = fa_tex_fix(param_2, param_3);\n    vec4 _4996 = base_t;\n    _4996.x = _3755.x;\n    _4996.y = _3755.y;\n    _4996.z = _3755.z;\n    base_t = _4996;\n    vec4 _3769 = (_4996 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4906 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3801 = fa_tex_fix(param_6, param_7);\n        vec3 _3804 = (_3801 * 2.0) - vec3(1.0);\n        vec2 _3809 = _3804.xy * fa_mesh_fs_params[6].x;\n        vec3 _5004 = _3804;\n        _5004.x = _3809.x;\n        _5004.y = _3809.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5004;\n        _4906 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3837 = fa_tex_fix(param_12, param_13);\n    vec4 _5007 = mrt;\n    _5007.x = _3837.x;\n    _5007.y = _3837.y;\n    _5007.z = _3837.z;\n    mrt = _5007;\n    vec4 _3865 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3865.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3877 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3907 = fa_tex_fix(param_20, param_21);\n    float _4911 = fa_mesh_fs_params[20].x;\n    float _4912 = fa_mesh_fs_params[20].y;\n    float _4915 = fa_mesh_fs_params[20].z;\n    float _4914 = fa_mesh_fs_params[21].w;\n    float _4917 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4911 *= _3877.y;\n            _4912 *= _3877.z;\n            _4914 *= _3865.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4915 *= mrt.x;\n            _4917 *= mrt.w;\n        }\n    }\n    return Surface(_3769.xyz, _3769.w, _4906, clamp(fa_mesh_fs_params[5].x * _3837.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3837.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3877.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3907), _4911, _4912, fa_mesh_fs_params[21].xyz, _4914, _4915, fa_mesh_fs_params[20].w, _4917, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1910 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1918 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1921 = int(_1910);\n    int _1924 = int(_1918);\n    float _1934 = _1918 - float(_1924);\n    int _1990 = (_1921 * 9) + _1924;\n    int _2010 = ((_1921 + 1) * 9) + _1924;\n    return mix(mix(_1985[_1990], _1985[_1990 + 1], _1934), mix(_1985[_2010], _1985[_2010 + 1], _1934), _1910 - float(_1921));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4842 = false;\n    float _4843 = 1.0;\n    float _4844 = 1.0;\n    float _4845 = 1.0;\n    float _4846 = 0.0;\n    float _4847 = 0.0;\n    float _4848 = 0.0;\n    float _4849 = 0.0;\n    float _4851 = 1.0;\n    bool _4852 = false;\n    vec3 _4853 = vec3(0.0);\n    float _4854 = 1.0;\n    float _4855 = 1.0;\n    float _4856 = 1.0;\n    float _4857 = 0.0;\n    float _4858 = 0.0;\n    vec3 _4859 = vec3(1.0, 0.0, 0.0);\n    vec3 _4860 = vec3(0.0, 0.0, 1.0);\n    float _4861 = 1.0;\n    float _4862 = 1.0;\n    float _2064 = clamp(s.specular, 0.0, 1.0);\n    float _2068 = clamp(s.ior, 1.0, 3.0);\n    bool _2073 = (_2064 != 1.0) || (_2068 != 1.5);\n    bool _2082;\n    if (!_2073)\n    {\n        _2082 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2082 = _2073;\n    }\n    if (_2082)\n    {\n        float _2090 = (_2068 - 1.0) / (_2068 + 1.0);\n        f0 = mix(min(vec3(_2090 * _2090) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2064, s.albedo, vec3(metallic));\n        _4843 = mix(_2064, 1.0, metallic);\n        _4842 = true;\n    }\n    float _2118 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2118 > 0.0)\n    {\n        float _2126 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4846 = _2118;\n        _4847 = _2126;\n        float _2133 = _2126 * _2126;\n        _4848 = _2133;\n        _4849 = _2133 * _2133;\n        float _2145 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4851 = _2145;\n        _4844 = 1.0 - (_2118 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2145, 0.0, 1.0), 5.0))));\n        _4842 = true;\n    }\n    vec3 _2165 = max(s.sheen_color, vec3(0.0));\n    float _2174 = max(_2165.x, max(_2165.y, _2165.z));\n    if (_2174 > 0.0)\n    {\n        float _2182 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4852 = true;\n        _4853 = _2165;\n        _4854 = _2182;\n        _4855 = _2182 * _2182;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2182;\n        float _2199 = fa_sheen_albedo(param, param_1);\n        _4857 = _2199;\n        _4856 = 1.0 - min(_2174 * _2199, 1.0);\n        _4842 = true;\n    }\n    _4845 = _4844 * _4856;\n    float _2218 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2218 != 0.0)\n    {\n        vec3 _2233 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2233;\n        if (dot(_2233, _2233) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2247 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2247.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2247.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2247.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2251 = t;\n        vec3 _2252 = normalize(_2251);\n        t = _2252;\n        vec3 _2277 = normalize((_2252 * cos(s.anisotropy_rotation)) + ((cross(n, _2252) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4859 = _2277;\n        _4860 = cross(n, _2277);\n        float _2287 = roughness * roughness;\n        float _2293 = mix(_2287, 1.0, _2218 * _2218);\n        bool _2295 = _2218 > 0.0;\n        _4861 = _2295 ? _2293 : _2287;\n        _4862 = _2295 ? _2287 : _2293;\n        _4858 = _2218;\n        _4842 = true;\n    }\n    return FaLayers(_4842, _4843, _4844, _4845, _4846, _4847, _4848, _4849, i.world_normal, _4851, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860, _4861, _4862);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _471 = dot(d, right);\n    float _475 = dot(d, up);\n    float _486;\n    if (((_471 * _471) + (_475 * _475)) > 1.0000000133514319600180897396058e-10)\n    {\n        _486 = atan(_475, _471) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _486 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_486 - floor(_486)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _519 = fa_light_base(param);\n    bool _523 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _519;\n    vec4 _527 = fa_light_texel(param_1);\n    int param_2 = _519 + 1;\n    vec4 _532 = fa_light_texel(param_2);\n    float _535 = _532.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _547 = _523 && (_535 > 2.5);\n    fa_light_is_area = _547;\n    bool _550 = _535 < 0.5;\n    vec3 l;\n    if (_550)\n    {\n        l = normalize(_527.xyz);\n        if (_523)\n        {\n            int param_3 = _519 + 6;\n            vec4 _564 = fa_light_texel(param_3);\n            if (_564.z > 0.5)\n            {\n                int param_4 = _519 + 4;\n                vec4 _574 = fa_light_texel(param_4);\n                int param_5 = _519 + 5;\n                vec4 _580 = fa_light_texel(param_5);\n                vec2 param_6 = _564.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _574.xyz) * _574.w, (-dot(world_pos, _580.xyz)) * _580.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _612 = _527.xyz - world_pos;\n        float _614 = length(_612);\n        dist = _614;\n        l = _612 / vec3(max(_614, 9.9999997473787516355514526367188e-05));\n        float reach = _614;\n        if (_547)\n        {\n            int param_8 = _519 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _646 = reach / max(_527.w, 0.001000000047497451305389404296875);\n        float _652 = clamp(1.0 - (_646 * _646), 0.0, 1.0);\n        atten = _652 * _652;\n        bool _660 = _535 < 2.5;\n        if ((_535 > 1.5) && _660)\n        {\n            int param_9 = _519 + 2;\n            vec4 _668 = fa_light_texel(param_9);\n            float _678 = _668.w;\n            int param_10 = _519 + 3;\n            vec4 _684 = fa_light_texel(param_10);\n            float _685 = _684.x;\n            float cos_inner = _685;\n            if (_685 > 1.5)\n            {\n                cos_inner = mix(_678, 1.0, 0.25);\n            }\n            atten *= smoothstep(_678, cos_inner, dot(-l, normalize(_668.xyz)));\n        }\n        if (_523 && _660)\n        {\n            int param_11 = _519 + 6;\n            vec4 _709 = fa_light_texel(param_11);\n            int param_12 = _519 + 7;\n            vec4 _714 = fa_light_texel(param_12);\n            bool _717 = _709.z > 0.5;\n            bool _724;\n            if (!_717)\n            {\n                _724 = _714.z > 0.5;\n            }\n            else\n            {\n                _724 = _717;\n            }\n            if (_724)\n            {\n                int param_13 = _519 + 2;\n                vec4 _731 = fa_light_texel(param_13);\n                vec3 _735 = normalize(_731.xyz);\n                int param_14 = _519 + 4;\n                vec4 _740 = fa_light_texel(param_14);\n                int param_15 = _519 + 5;\n                vec4 _745 = fa_light_texel(param_15);\n                if (_717)\n                {\n                    vec3 _753 = -_612;\n                    float _760 = _731.w;\n                    float _776 = 0.5 / max(dot(_753, _735) * (sqrt(max(1.0 - (_760 * _760), 0.0)) / max(_760, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _709.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_753, _740.xyz) * _776), 0.5 - (dot(_753, _745.xyz) * _776));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_714.z > 0.5)\n                {\n                    vec2 param_18 = _714.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _735;\n                    vec3 param_21 = _740.xyz;\n                    vec3 param_22 = _745.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _4830 = _532.xyz * atten;\n    if (_523)\n    {\n        _4830 *= fa_light_tint;\n    }\n    int _845;\n    if (_550)\n    {\n        _845 = 0;\n    }\n    else\n    {\n        _845 = ((_535 > 1.5) && (_535 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4830, atten, 1.0, dist, _845);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1084;\n    if (i == 0)\n    {\n        _1084 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1100;\n        if (i == 1)\n        {\n            _1100 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1108;\n            if (i == 2)\n            {\n                _1108 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1108 = fa_shadows[24].w;\n            }\n            _1100 = _1108;\n        }\n        _1084 = _1100;\n    }\n    return _1084;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1072 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1072), sin(_1072)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1146 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1151 = clamp(dot(n, l), 0.0, 1.0);\n    float _1157 = sqrt(1.0 - (_1151 * _1151));\n    float _1165 = min(_1157 / max(_1151, 0.20000000298023223876953125), 4.0);\n    float _1170;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1170 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1170 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1195 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1170 * _1157)), 1.0);\n    float _1202 = _1195.x;\n    bool _1205 = _1202 < fa_shadows[ci * 1 + 16].x;\n    bool _1214;\n    if (!_1205)\n    {\n        _1214 = _1202 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1214 = _1205;\n    }\n    bool _1223;\n    if (!_1214)\n    {\n        _1223 = _1195.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1223 = _1214;\n    }\n    bool _1232;\n    if (!_1223)\n    {\n        _1232 = _1195.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1232 = _1223;\n    }\n    bool _1239;\n    if (!_1232)\n    {\n        _1239 = _1195.z > 1.0;\n    }\n    else\n    {\n        _1239 = _1232;\n    }\n    if (_1239)\n    {\n        return -1.0;\n    }\n    float _1247;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1247 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1247 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1266 = _1195.z - ((_1247 * (1.0 + (0.5 * _1165))) / _1146);\n    float _1275 = ((fa_shadows[ci * 1 + 20].x * min(_1165, 3.0)) * 0.5) / _1146;\n    int _1284 = int(fa_shadows[25].z + 0.5);\n    if (_1284 == 1)\n    {\n        vec2 param = _1195.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1295 = fa_shadow_depth(param, param_1);\n        return float(_1266 <= _1295);\n    }\n    float _1302 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1305 = _1284 == 2;\n    if (_1305)\n    {\n        float _1319 = clamp(((fa_shadows[25].w * _1146) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1302;\n            vec2 _1338 = fa_shadow_vogel(param_2, param_3, param_4) * _1319;\n            vec2 param_5 = _1195.xy + (_1338 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1349 = fa_shadow_depth(param_5, param_6);\n            if (_1349 < (_1266 - (length(_1338) * _1275)))\n            {\n                sum += _1349;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1266 - (sum / cnt), 0.0) * _1146) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1393 = _1305 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1393;\n        float param_9 = _1302;\n        vec2 _1412 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1195.xy + (_1412 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1423 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1266 - (length(_1412) * _1275)) <= _1423);\n    }\n    return lit / float(_1393);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1453 = int(fa_shadows[25].x + 0.5);\n    if (_1453 < 1)\n    {\n        return 1.0;\n    }\n    float _1468 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1453 - 1;\n    if (_1468 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1480 = _1453 > 1;\n    bool _1487;\n    if (_1480)\n    {\n        _1487 = _1468 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1487 = _1480;\n    }\n    if (_1487)\n    {\n        ci = 1;\n    }\n    bool _1491 = _1453 > 2;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1468 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 2;\n    }\n    bool _1502 = _1453 > 3;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1468 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1453)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1535 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1535;\n        if (_1535 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1560;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1560 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1560 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1579 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1560, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1590 = clamp((_1468 - (fa_shadow_split_at(param_7) - _1579)) / _1579, 0.0, 1.0);\n        if (_1590 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1453)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1611 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1611;\n                if (_1611 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1590);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2830 = fa_light_sample(param, param_1);\n    vec3 _4886 = _2830.color;\n    float _4888 = _2830.shadow;\n    if ((_2830.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2830.direction;\n        float _2844 = fa_shadow_factor(param_2, param_3);\n        _4888 = _2844;\n        _4886 *= _2844;\n    }\n    return LightSample(_2830.direction, _4886, _2830.attenuation, _4888, _2830._distance, _2830.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _2884 = v - (n * dot(v, n));\n    vec3 t = _2884;\n    float _2888 = dot(_2884, _2884);\n    float l2 = _2888;\n    if (_2888 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _2898;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2898 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2898 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _2898;\n        l2 = dot(_2898, _2898);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _2933 = dot(a, a);\n    float _2937 = dot(b, b);\n    if ((_2933 < 1.0000000195414813782625560981111e-24) || (_2937 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _2951 = a * inversesqrt(_2933);\n    vec3 _2956 = b * inversesqrt(_2937);\n    float _2960 = dot(_2951, _2956);\n    float _2963 = abs(_2960);\n    float g = (((((((((((0.0416471660137176513671875 * _2963) - 0.1924748718738555908203125) * _2963) + 0.4179156124591827392578125) * _2963) - 0.616057217121124267578125) * _2963) + 0.777722418308258056640625) * _2963) - 0.999542415142059326171875) * _2963) + 1.570791721343994140625;\n    if (_2960 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_2960 * _2960), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2951, _2956) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _3020 = a.z > 0.0;\n    bool _3024 = b.z > 0.0;\n    if (_3020 && _3024)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3020 != _3024)\n        {\n            vec3 _3059 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3059.z = 0.0;\n            if (_3020)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _3059;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3059;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _3059;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3059;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _3108 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _3134 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _3160 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _3186 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _3108;\n    vec3 param_1 = _3134;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _3134;\n    vec3 param_7 = _3160;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _3160;\n    vec3 param_13 = _3186;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _3186;\n    vec3 param_19 = _3108;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _3336 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3360 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3376 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _3336;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _3360;\n    vec4 param_9 = m;\n    vec3 param_10 = _3336;\n    vec3 param_11 = _3360;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _3376;\n    vec4 param_14 = m;\n    vec3 param_15 = _3336;\n    vec3 param_16 = _3376;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _3434 = fa_light_base(param);\n    int param_1 = _3434;\n    int param_2 = _3434 + 1;\n    int param_3 = _3434 + 2;\n    int param_4 = _3434 + 4;\n    vec4 _3456 = fa_light_texel(param_4);\n    int param_5 = _3434 + 5;\n    vec4 _3461 = fa_light_texel(param_5);\n    int param_6 = _3434 + 6;\n    vec4 _3466 = fa_light_texel(param_6);\n    float _3467 = _3466.w;\n    vec3 _3472 = fa_light_texel(param_1).xyz - world_pos;\n    bool _3474 = _3467 < 1.5;\n    bool _3481;\n    if (_3474)\n    {\n        _3481 = dot(normalize(fa_light_texel(param_3).xyz), _3472) >= 0.0;\n    }\n    else\n    {\n        _3481 = _3474;\n    }\n    if (_3481)\n    {\n        return vec3(0.0);\n    }\n    bool _3490 = (_3467 > 0.5) && _3474;\n    float _3494 = _3490 ? 1.0539000034332275390625 : 1.0;\n    vec3 _3497 = _3456.xyz;\n    float _3499 = _3456.w;\n    vec3 _3505 = _3461.xyz;\n    float _3507 = _3461.w;\n    vec3 up = _3505 * (_3507 * _3494);\n    float _3513;\n    if (_3490)\n    {\n        _3513 = (3.1415927410125732421875 * _3499) * _3499;\n    }\n    else\n    {\n        _3513 = (4.0 * _3499) * _3507;\n    }\n    if (_3467 > 1.5)\n    {\n        vec3 _3539 = cross(_3497, -_3472);\n        vec3 perp = _3539;\n        float _3543 = dot(_3539, _3539);\n        vec3 _3546;\n        if (_3543 > 1.0000000133514319600180897396058e-10)\n        {\n            _3546 = perp * inversesqrt(_3543);\n        }\n        else\n        {\n            _3546 = _3505;\n        }\n        perp = _3546;\n        up = _3546 * _3507;\n    }\n    float _3567 = max(_3513, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _3577 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _3577;\n    vec3 param_10 = n;\n    vec3 param_11 = _3472;\n    vec3 _3585 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _3577;\n    vec3 param_13 = n;\n    vec3 param_14 = _3497 * (_3499 * _3494);\n    vec3 _3593 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _3577;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _3601 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3467;\n    vec3 param_20 = _3585;\n    vec3 param_21 = _3593;\n    vec3 param_22 = _3601;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _3620 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _3620;\n    vec2 param_26 = _3620 + vec2(64.0, 0.0);\n    vec4 _3630 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _3467;\n    vec3 param_29 = _3585;\n    vec3 param_30 = _3593;\n    vec3 param_31 = _3601;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3630.x) + ((vec3(1.0) - f0) * _3630.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_3472, _3472)) + _3567) / _3567) * window);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2445 = tdh / at;\n    float _2449 = bdh / ab;\n    float _2461 = ((_2445 * _2445) + (_2449 * _2449)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2461) * _2461);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2542 = 1.0 / alpha;\n    return ((2.0 + _2542) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2542)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2575 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2654 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2654) * _2654);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2575);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2575));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2727 = max(dot(L.nc, l), 0.0);\n        float _2733 = max(dot(L.nc, h), 0.0);\n        float _2742 = ((_2733 * _2733) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2742) * _2742)) * (0.5 / max(mix((2.0 * _2727) * L.coat_ndv, _2727 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2727)) * _2727);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1842 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1845 = _1842.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1845 * _1845, exp2((-9.27999973297119140625) * ndv)) * _1845) + _1842.y)) + _1842.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1747 = rough * rough;\n    float _1777 = 0.60000002384185791015625 * _1747;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1747)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1777, 0.0500000007450580596923828125 + _1777, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1747 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2328;\n        if (L.aniso >= 0.0)\n        {\n            _2328 = L.b;\n        }\n        else\n        {\n            _2328 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2328, v), _2328), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2361 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2361.x) + (vec3(L.f90) * _2361.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2416 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2416.x) + _2416.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1884 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1884.x) + vec3(_1884.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1635 = int(fa_shadows[25].x + 0.5);\n    float _1645 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1650 = _1635 > 0;\n    bool _1659;\n    if (_1650)\n    {\n        int param = _1635 - 1;\n        _1659 = _1645 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1659 = _1650;\n    }\n    if (_1659)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1666 = _1635 > 1;\n        bool _1673;\n        if (_1666)\n        {\n            _1673 = _1645 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1673 = _1666;\n        }\n        if (_1673)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1679 = _1635 > 2;\n        bool _1686;\n        if (_1679)\n        {\n            _1686 = _1645 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1686 = _1679;\n        }\n        if (_1686)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1692 = _1635 > 3;\n        bool _1699;\n        if (_1692)\n        {\n            _1699 = _1645 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1699 = _1692;\n        }\n        if (_1699)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4621 = -_4621;\n    }\n    vec3 _4028 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface _4036 = fa_standard_surface(param_1);\n    vec3 _4652 = _4036.albedo;\n    float _4653 = _4036.alpha;\n    vec3 _4654 = _4036.normal;\n    float _4655 = _4036.metallic;\n    float _4656 = _4036.roughness;\n    float _4657 = _4036.occlusion;\n    vec3 _4658 = _4036.emission;\n    float _4659 = _4036.clearcoat;\n    float _4660 = _4036.clearcoat_roughness;\n    vec3 _4661 = _4036.sheen_color;\n    float _4662 = _4036.sheen_roughness;\n    float _4663 = _4036.anisotropy;\n    float _4664 = _4036.anisotropy_rotation;\n    float _4665 = _4036.specular;\n    float _4666 = _4036.ior;\n    vec3 _4667 = _4036.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface param_3 = _4036;\n    surface(param_2, param_3);\n    _4652 = param_3.albedo;\n    _4653 = param_3.alpha;\n    _4654 = param_3.normal;\n    _4655 = param_3.metallic;\n    _4656 = param_3.roughness;\n    _4657 = param_3.occlusion;\n    _4658 = param_3.emission;\n    _4659 = param_3.clearcoat;\n    _4660 = param_3.clearcoat_roughness;\n    _4661 = param_3.sheen_color;\n    _4662 = param_3.sheen_roughness;\n    _4663 = param_3.anisotropy;\n    _4664 = param_3.anisotropy_rotation;\n    _4665 = param_3.specular;\n    _4666 = param_3.ior;\n    _4667 = param_3.specular_color;\n    if (param_3.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4652;\n    }\n    else\n    {\n        vec3 _4069 = normalize(_4654);\n        float _4076 = clamp(_4655, 0.0, 1.0);\n        float _4080 = clamp(_4656, 0.0500000007450580596923828125, 1.0);\n        float _4084 = _4080 * _4080;\n        float _4088 = _4084 * _4084;\n        float _4093 = max(dot(_4069, _4028), 9.9999997473787516355514526367188e-05);\n        vec3 _4099 = _4652 * (1.0 - _4076);\n        vec3 _4106 = mix(vec3(0.039999999105930328369140625), _4652, vec3(_4076));\n        vec3 f0 = _4106;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n        Surface param_5 = Surface(_4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661, _4662, _4663, _4664, _4665, _4666, _4667);\n        vec3 param_6 = _4069;\n        vec3 param_7 = _4028;\n        float param_8 = _4076;\n        float param_9 = _4080;\n        vec3 param_10 = _4106;\n        FaLayers _4122 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _4069;\n        vec3 lit = (fa_ambient_light(param_11) * _4099) * _4657;\n        if (_4122.on)\n        {\n            lit *= _4122.base_scale;\n        }\n        int _4144 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4144; ln++)\n        {\n            int param_12 = ln;\n            int _4157 = fa_cl_light(param_12);\n            int param_13 = _4157;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _4621;\n            LightSample _4166 = fa_light_shadowed(param_13, param_14, param_15);\n            float _4174 = max(dot(_4069, _4166.direction), 0.0);\n            float _4180 = _4166.attenuation * _4166.shadow;\n            vec3 _4185 = normalize(_4166.direction + _4028);\n            float _4190 = max(dot(_4069, _4185), 0.0);\n            float _4195 = max(dot(_4028, _4185), 0.0);\n            bool _4202;\n            if (fa_light_is_area)\n            {\n                _4202 = !_4122.on;\n            }\n            else\n            {\n                _4202 = fa_light_is_area;\n            }\n            if (_4202)\n            {\n                int param_16 = _4157;\n                vec3 param_17 = fa_world_pos;\n                vec3 param_18 = _4069;\n                vec3 param_19 = _4028;\n                vec3 param_20 = _4099;\n                vec3 param_21 = f0;\n                float param_22 = _4080;\n                float param_23 = _4093;\n                float param_24 = _4180;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);\n            }\n            else\n            {\n                if (_4122.on)\n                {\n                    FaLayers param_25 = _4122;\n                    vec3 param_26 = _4099;\n                    vec3 param_27 = f0;\n                    vec3 param_28 = _4069;\n                    vec3 param_29 = _4028;\n                    vec3 param_30 = _4166.direction;\n                    vec3 param_31 = _4185;\n                    float param_32 = _4174;\n                    float param_33 = _4093;\n                    float param_34 = _4190;\n                    float param_35 = _4195;\n                    float param_36 = _4084;\n                    float param_37 = _4088;\n                    int param_38 = _4157;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38) * fa_light_tint) * _4180));\n                }\n                else\n                {\n                    float _4277 = ((_4190 * _4190) * (_4088 - 1.0)) + 1.0;\n                    int param_39 = _4157;\n                    lit += (((_4099 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4195, 5.0))) * (((_4088 / ((3.1415927410125732421875 * _4277) * _4277)) * (0.5 / max(mix((2.0 * _4174) * _4093, _4174 + _4093, _4084), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4174))) * (fa_light_rgb(param_39) * fa_light_tint)) * (_4174 * _4180));\n                }\n            }\n        }\n        if (_4122.on)\n        {\n            FaLayers param_40 = _4122;\n            vec3 param_41 = _4069;\n            vec3 param_42 = _4028;\n            vec3 param_43 = f0;\n            float param_44 = _4080;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44) * _4657);\n        }\n        else\n        {\n            vec3 param_45 = _4069;\n            vec3 param_46 = _4028;\n            vec3 param_47 = f0;\n            float param_48 = _4080;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48) * _4657);\n        }\n        result = lit;\n    }\n    vec3 _4372 = result;\n    vec3 _4373 = _4372 + _4658;\n    result = _4373;\n    vec3 param_49 = _4373;\n    vec3 param_50 = fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50);\n    bool _4382 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4389;\n    if (!_4382)\n    {\n        _4389 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4389 = _4382;\n    }\n    if (_4389)\n    {\n        vec3 _4398 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4404 = dot(_4398, fa_mesh_fs_params[9].xyz);\n        bool _4408 = fa_mesh_fs_params[9].w > 0.5;\n        float _4409;\n        if (_4408)\n        {\n            _4409 = _4404;\n        }\n        else\n        {\n            _4409 = length(_4398);\n        }\n        float _4421 = _4409 - fa_mesh_fs_params[8].x;\n        if (_4421 > 0.0)\n        {\n            float _4430 = fa_mesh_fs_params[7].w * _4421;\n            float tau = _4430 * _4430;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4446;\n                if (_4408)\n                {\n                    _4446 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4404);\n                }\n                else\n                {\n                    _4446 = fa_mesh_fs_params[0].y;\n                }\n                float _4467 = mix(_4446, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4409, 0.0, 1.0));\n                float _4471 = fa_world_pos.y - _4467;\n                float _4476 = _4467 - fa_mesh_fs_params[8].z;\n                float _4481 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4484 = _4476 <= 0.0;\n                bool _4485 = !_4484;\n                bool _4491;\n                if (_4485)\n                {\n                    _4491 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4491 = _4484;\n                }\n                float _4492;\n                if (_4491)\n                {\n                    _4492 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4492 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4476, 80.0));\n                }\n                bool _4519;\n                if (_4485)\n                {\n                    _4519 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4519 = _4484;\n                }\n                float _4520;\n                if (_4519)\n                {\n                    _4520 = fa_mesh_fs_params[8].y * _4476;\n                }\n                else\n                {\n                    _4520 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4476, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4545 = _4481 <= 0.0;\n                bool _4552;\n                if (!_4545)\n                {\n                    _4552 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4552 = _4545;\n                }\n                float _4553;\n                if (_4552)\n                {\n                    _4553 = fa_mesh_fs_params[8].y * _4481;\n                }\n                else\n                {\n                    _4553 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4481, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4580;\n                if (abs(_4471) < 0.001000000047497451305389404296875)\n                {\n                    _4580 = _4492;\n                }\n                else\n                {\n                    _4580 = (_4553 - _4520) / _4471;\n                }\n                tau += (_4421 * max(_4580, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4653);\n}\n\n",
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
            "inst_name": "_381",
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
            "inst_name": "_1094",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4047",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1985[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _863 = fa_mesh_fs_params[19].x < 0.0;\n    bool _870;\n    if (!_863)\n    {\n        _870 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _870 = _863;\n    }\n    bool _878;\n    if (!_870)\n    {\n        _878 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _878 = _870;\n    }\n    bool _885;\n    if (!_878)\n    {\n        _885 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _885 = _878;\n    }\n    bool _892;\n    if (!_885)\n    {\n        _892 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _892 = _885;\n    }\n    if (_892)\n    {\n        return ivec2(0);\n    }\n    vec4 _902 = vec4(world_pos, 1.0);\n    float _909 = dot(fa_mesh_fs_params[16], _902);\n    if (!(_909 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _931 = vec2(dot(fa_mesh_fs_params[14], _902), dot(fa_mesh_fs_params[15], _902)) / vec2(_909);\n    int _935 = int(fa_mesh_fs_params[18].x);\n    int _939 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _939) + clamp(int(floor(((_931.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _939 - 1)) * _935)) + clamp(int(floor(((_931.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _935 - 1);\n    vec4 _1010 = fa_light_texel(param);\n    return ivec2(int(_1010.x), int(_1010.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2802 = fa_cluster_lookup(param);\n    fa_cl_slot = _2802.x;\n    fa_cl_local = _2802.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3716 = fa_linear_to_srgb(param);\n        c = _3716;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3724 = fa_srgb_to_linear(param_1);\n            c = _3724;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _313;\n    if (i.front_facing)\n    {\n        _313 = i.world_normal;\n    }\n    else\n    {\n        _313 = -i.world_normal;\n    }\n    vec3 _337 = normalize(i.world_tangent.xyz - (_313 * dot(_313, i.world_tangent.xyz)));\n    vec3 _365 = normalize(((_337 * m.x) + ((cross(_313, _337) * i.world_tangent.w) * m.y)) + (_313 * m.z));\n    vec3 _368;\n    if (i.front_facing)\n    {\n        _368 = _365;\n    }\n    else\n    {\n        _368 = -_365;\n    }\n    return _368;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3755 = fa_tex_fix(param_2, param_3);\n    vec4 _4996 = base_t;\n    _4996.x = _3755.x;\n    _4996.y = _3755.y;\n    _4996.z = _3755.z;\n    base_t = _4996;\n    vec4 _3769 = (_4996 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4906 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3801 = fa_tex_fix(param_6, param_7);\n        vec3 _3804 = (_3801 * 2.0) - vec3(1.0);\n        vec2 _3809 = _3804.xy * fa_mesh_fs_params[6].x;\n        vec3 _5004 = _3804;\n        _5004.x = _3809.x;\n        _5004.y = _3809.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5004;\n        _4906 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3837 = fa_tex_fix(param_12, param_13);\n    vec4 _5007 = mrt;\n    _5007.x = _3837.x;\n    _5007.y = _3837.y;\n    _5007.z = _3837.z;\n    mrt = _5007;\n    vec4 _3865 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3865.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3877 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3907 = fa_tex_fix(param_20, param_21);\n    float _4911 = fa_mesh_fs_params[20].x;\n    float _4912 = fa_mesh_fs_params[20].y;\n    float _4915 = fa_mesh_fs_params[20].z;\n    float _4914 = fa_mesh_fs_params[21].w;\n    float _4917 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4911 *= _3877.y;\n            _4912 *= _3877.z;\n            _4914 *= _3865.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4915 *= mrt.x;\n            _4917 *= mrt.w;\n        }\n    }\n    return Surface(_3769.xyz, _3769.w, _4906, clamp(fa_mesh_fs_params[5].x * _3837.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3837.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3877.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3907), _4911, _4912, fa_mesh_fs_params[21].xyz, _4914, _4915, fa_mesh_fs_params[20].w, _4917, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1910 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1918 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1921 = int(_1910);\n    int _1924 = int(_1918);\n    float _1934 = _1918 - float(_1924);\n    int _1990 = (_1921 * 9) + _1924;\n    int _2010 = ((_1921 + 1) * 9) + _1924;\n    return mix(mix(_1985[_1990], _1985[_1990 + 1], _1934), mix(_1985[_2010], _1985[_2010 + 1], _1934), _1910 - float(_1921));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4842 = false;\n    float _4843 = 1.0;\n    float _4844 = 1.0;\n    float _4845 = 1.0;\n    float _4846 = 0.0;\n    float _4847 = 0.0;\n    float _4848 = 0.0;\n    float _4849 = 0.0;\n    float _4851 = 1.0;\n    bool _4852 = false;\n    vec3 _4853 = vec3(0.0);\n    float _4854 = 1.0;\n    float _4855 = 1.0;\n    float _4856 = 1.0;\n    float _4857 = 0.0;\n    float _4858 = 0.0;\n    vec3 _4859 = vec3(1.0, 0.0, 0.0);\n    vec3 _4860 = vec3(0.0, 0.0, 1.0);\n    float _4861 = 1.0;\n    float _4862 = 1.0;\n    float _2064 = clamp(s.specular, 0.0, 1.0);\n    float _2068 = clamp(s.ior, 1.0, 3.0);\n    bool _2073 = (_2064 != 1.0) || (_2068 != 1.5);\n    bool _2082;\n    if (!_2073)\n    {\n        _2082 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2082 = _2073;\n    }\n    if (_2082)\n    {\n        float _2090 = (_2068 - 1.0) / (_2068 + 1.0);\n        f0 = mix(min(vec3(_2090 * _2090) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2064, s.albedo, vec3(metallic));\n        _4843 = mix(_2064, 1.0, metallic);\n        _4842 = true;\n    }\n    float _2118 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2118 > 0.0)\n    {\n        float _2126 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4846 = _2118;\n        _4847 = _2126;\n        float _2133 = _2126 * _2126;\n        _4848 = _2133;\n        _4849 = _2133 * _2133;\n        float _2145 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4851 = _2145;\n        _4844 = 1.0 - (_2118 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2145, 0.0, 1.0), 5.0))));\n        _4842 = true;\n    }\n    vec3 _2165 = max(s.sheen_color, vec3(0.0));\n    float _2174 = max(_2165.x, max(_2165.y, _2165.z));\n    if (_2174 > 0.0)\n    {\n        float _2182 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4852 = true;\n        _4853 = _2165;\n        _4854 = _2182;\n        _4855 = _2182 * _2182;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2182;\n        float _2199 = fa_sheen_albedo(param, param_1);\n        _4857 = _2199;\n        _4856 = 1.0 - min(_2174 * _2199, 1.0);\n        _4842 = true;\n    }\n    _4845 = _4844 * _4856;\n    float _2218 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2218 != 0.0)\n    {\n        vec3 _2233 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2233;\n        if (dot(_2233, _2233) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2247 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2247.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2247.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2247.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2251 = t;\n        vec3 _2252 = normalize(_2251);\n        t = _2252;\n        vec3 _2277 = normalize((_2252 * cos(s.anisotropy_rotation)) + ((cross(n, _2252) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4859 = _2277;\n        _4860 = cross(n, _2277);\n        float _2287 = roughness * roughness;\n        float _2293 = mix(_2287, 1.0, _2218 * _2218);\n        bool _2295 = _2218 > 0.0;\n        _4861 = _2295 ? _2293 : _2287;\n        _4862 = _2295 ? _2287 : _2293;\n        _4858 = _2218;\n        _4842 = true;\n    }\n    return FaLayers(_4842, _4843, _4844, _4845, _4846, _4847, _4848, _4849, i.world_normal, _4851, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860, _4861, _4862);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _471 = dot(d, right);\n    float _475 = dot(d, up);\n    float _486;\n    if (((_471 * _471) + (_475 * _475)) > 1.0000000133514319600180897396058e-10)\n    {\n        _486 = atan(_475, _471) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _486 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_486 - floor(_486)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _519 = fa_light_base(param);\n    bool _523 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _519;\n    vec4 _527 = fa_light_texel(param_1);\n    int param_2 = _519 + 1;\n    vec4 _532 = fa_light_texel(param_2);\n    float _535 = _532.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _547 = _523 && (_535 > 2.5);\n    fa_light_is_area = _547;\n    bool _550 = _535 < 0.5;\n    vec3 l;\n    if (_550)\n    {\n        l = normalize(_527.xyz);\n        if (_523)\n        {\n            int param_3 = _519 + 6;\n            vec4 _564 = fa_light_texel(param_3);\n            if (_564.z > 0.5)\n            {\n                int param_4 = _519 + 4;\n                vec4 _574 = fa_light_texel(param_4);\n                int param_5 = _519 + 5;\n                vec4 _580 = fa_light_texel(param_5);\n                vec2 param_6 = _564.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _574.xyz) * _574.w, (-dot(world_pos, _580.xyz)) * _580.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _612 = _527.xyz - world_pos;\n        float _614 = length(_612);\n        dist = _614;\n        l = _612 / vec3(max(_614, 9.9999997473787516355514526367188e-05));\n        float reach = _614;\n        if (_547)\n        {\n            int param_8 = _519 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _646 = reach / max(_527.w, 0.001000000047497451305389404296875);\n        float _652 = clamp(1.0 - (_646 * _646), 0.0, 1.0);\n        atten = _652 * _652;\n        bool _660 = _535 < 2.5;\n        if ((_535 > 1.5) && _660)\n        {\n            int param_9 = _519 + 2;\n            vec4 _668 = fa_light_texel(param_9);\n            float _678 = _668.w;\n            int param_10 = _519 + 3;\n            vec4 _684 = fa_light_texel(param_10);\n            float _685 = _684.x;\n            float cos_inner = _685;\n            if (_685 > 1.5)\n            {\n                cos_inner = mix(_678, 1.0, 0.25);\n            }\n            atten *= smoothstep(_678, cos_inner, dot(-l, normalize(_668.xyz)));\n        }\n        if (_523 && _660)\n        {\n            int param_11 = _519 + 6;\n            vec4 _709 = fa_light_texel(param_11);\n            int param_12 = _519 + 7;\n            vec4 _714 = fa_light_texel(param_12);\n            bool _717 = _709.z > 0.5;\n            bool _724;\n            if (!_717)\n            {\n                _724 = _714.z > 0.5;\n            }\n            else\n            {\n                _724 = _717;\n            }\n            if (_724)\n            {\n                int param_13 = _519 + 2;\n                vec4 _731 = fa_light_texel(param_13);\n                vec3 _735 = normalize(_731.xyz);\n                int param_14 = _519 + 4;\n                vec4 _740 = fa_light_texel(param_14);\n                int param_15 = _519 + 5;\n                vec4 _745 = fa_light_texel(param_15);\n                if (_717)\n                {\n                    vec3 _753 = -_612;\n                    float _760 = _731.w;\n                    float _776 = 0.5 / max(dot(_753, _735) * (sqrt(max(1.0 - (_760 * _760), 0.0)) / max(_760, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _709.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_753, _740.xyz) * _776), 0.5 - (dot(_753, _745.xyz) * _776));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_714.z > 0.5)\n                {\n                    vec2 param_18 = _714.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _735;\n                    vec3 param_21 = _740.xyz;\n                    vec3 param_22 = _745.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _4830 = _532.xyz * atten;\n    if (_523)\n    {\n        _4830 *= fa_light_tint;\n    }\n    int _845;\n    if (_550)\n    {\n        _845 = 0;\n    }\n    else\n    {\n        _845 = ((_535 > 1.5) && (_535 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4830, atten, 1.0, dist, _845);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1084;\n    if (i == 0)\n    {\n        _1084 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1100;\n        if (i == 1)\n        {\n            _1100 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1108;\n            if (i == 2)\n            {\n                _1108 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1108 = fa_shadows[24].w;\n            }\n            _1100 = _1108;\n        }\n        _1084 = _1100;\n    }\n    return _1084;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1072 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1072), sin(_1072)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1146 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1151 = clamp(dot(n, l), 0.0, 1.0);\n    float _1157 = sqrt(1.0 - (_1151 * _1151));\n    float _1165 = min(_1157 / max(_1151, 0.20000000298023223876953125), 4.0);\n    float _1170;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1170 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1170 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1195 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1170 * _1157)), 1.0);\n    float _1202 = _1195.x;\n    bool _1205 = _1202 < fa_shadows[ci * 1 + 16].x;\n    bool _1214;\n    if (!_1205)\n    {\n        _1214 = _1202 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1214 = _1205;\n    }\n    bool _1223;\n    if (!_1214)\n    {\n        _1223 = _1195.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1223 = _1214;\n    }\n    bool _1232;\n    if (!_1223)\n    {\n        _1232 = _1195.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1232 = _1223;\n    }\n    bool _1239;\n    if (!_1232)\n    {\n        _1239 = _1195.z > 1.0;\n    }\n    else\n    {\n        _1239 = _1232;\n    }\n    if (_1239)\n    {\n        return -1.0;\n    }\n    float _1247;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1247 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1247 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1266 = _1195.z - ((_1247 * (1.0 + (0.5 * _1165))) / _1146);\n    float _1275 = ((fa_shadows[ci * 1 + 20].x * min(_1165, 3.0)) * 0.5) / _1146;\n    int _1284 = int(fa_shadows[25].z + 0.5);\n    if (_1284 == 1)\n    {\n        vec2 param = _1195.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1295 = fa_shadow_depth(param, param_1);\n        return float(_1266 <= _1295);\n    }\n    float _1302 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1305 = _1284 == 2;\n    if (_1305)\n    {\n        float _1319 = clamp(((fa_shadows[25].w * _1146) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1302;\n            vec2 _1338 = fa_shadow_vogel(param_2, param_3, param_4) * _1319;\n            vec2 param_5 = _1195.xy + (_1338 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1349 = fa_shadow_depth(param_5, param_6);\n            if (_1349 < (_1266 - (length(_1338) * _1275)))\n            {\n                sum += _1349;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1266 - (sum / cnt), 0.0) * _1146) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1393 = _1305 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1393;\n        float param_9 = _1302;\n        vec2 _1412 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1195.xy + (_1412 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1423 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1266 - (length(_1412) * _1275)) <= _1423);\n    }\n    return lit / float(_1393);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1453 = int(fa_shadows[25].x + 0.5);\n    if (_1453 < 1)\n    {\n        return 1.0;\n    }\n    float _1468 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1453 - 1;\n    if (_1468 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1480 = _1453 > 1;\n    bool _1487;\n    if (_1480)\n    {\n        _1487 = _1468 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1487 = _1480;\n    }\n    if (_1487)\n    {\n        ci = 1;\n    }\n    bool _1491 = _1453 > 2;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1468 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 2;\n    }\n    bool _1502 = _1453 > 3;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1468 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1453)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1535 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1535;\n        if (_1535 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1560;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1560 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1560 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1579 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1560, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1590 = clamp((_1468 - (fa_shadow_split_at(param_7) - _1579)) / _1579, 0.0, 1.0);\n        if (_1590 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1453)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1611 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1611;\n                if (_1611 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1590);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2830 = fa_light_sample(param, param_1);\n    vec3 _4886 = _2830.color;\n    float _4888 = _2830.shadow;\n    if ((_2830.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2830.direction;\n        float _2844 = fa_shadow_factor(param_2, param_3);\n        _4888 = _2844;\n        _4886 *= _2844;\n    }\n    return LightSample(_2830.direction, _4886, _2830.attenuation, _4888, _2830._distance, _2830.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _2884 = v - (n * dot(v, n));\n    vec3 t = _2884;\n    float _2888 = dot(_2884, _2884);\n    float l2 = _2888;\n    if (_2888 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _2898;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2898 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2898 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _2898;\n        l2 = dot(_2898, _2898);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _2933 = dot(a, a);\n    float _2937 = dot(b, b);\n    if ((_2933 < 1.0000000195414813782625560981111e-24) || (_2937 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _2951 = a * inversesqrt(_2933);\n    vec3 _2956 = b * inversesqrt(_2937);\n    float _2960 = dot(_2951, _2956);\n    float _2963 = abs(_2960);\n    float g = (((((((((((0.0416471660137176513671875 * _2963) - 0.1924748718738555908203125) * _2963) + 0.4179156124591827392578125) * _2963) - 0.616057217121124267578125) * _2963) + 0.777722418308258056640625) * _2963) - 0.999542415142059326171875) * _2963) + 1.570791721343994140625;\n    if (_2960 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_2960 * _2960), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2951, _2956) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _3020 = a.z > 0.0;\n    bool _3024 = b.z > 0.0;\n    if (_3020 && _3024)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3020 != _3024)\n        {\n            vec3 _3059 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3059.z = 0.0;\n            if (_3020)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _3059;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3059;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _3059;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3059;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _3108 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _3134 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _3160 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _3186 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _3108;\n    vec3 param_1 = _3134;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _3134;\n    vec3 param_7 = _3160;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _3160;\n    vec3 param_13 = _3186;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _3186;\n    vec3 param_19 = _3108;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _3336 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3360 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3376 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _3336;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _3360;\n    vec4 param_9 = m;\n    vec3 param_10 = _3336;\n    vec3 param_11 = _3360;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _3376;\n    vec4 param_14 = m;\n    vec3 param_15 = _3336;\n    vec3 param_16 = _3376;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _3434 = fa_light_base(param);\n    int param_1 = _3434;\n    int param_2 = _3434 + 1;\n    int param_3 = _3434 + 2;\n    int param_4 = _3434 + 4;\n    vec4 _3456 = fa_light_texel(param_4);\n    int param_5 = _3434 + 5;\n    vec4 _3461 = fa_light_texel(param_5);\n    int param_6 = _3434 + 6;\n    vec4 _3466 = fa_light_texel(param_6);\n    float _3467 = _3466.w;\n    vec3 _3472 = fa_light_texel(param_1).xyz - world_pos;\n    bool _3474 = _3467 < 1.5;\n    bool _3481;\n    if (_3474)\n    {\n        _3481 = dot(normalize(fa_light_texel(param_3).xyz), _3472) >= 0.0;\n    }\n    else\n    {\n        _3481 = _3474;\n    }\n    if (_3481)\n    {\n        return vec3(0.0);\n    }\n    bool _3490 = (_3467 > 0.5) && _3474;\n    float _3494 = _3490 ? 1.0539000034332275390625 : 1.0;\n    vec3 _3497 = _3456.xyz;\n    float _3499 = _3456.w;\n    vec3 _3505 = _3461.xyz;\n    float _3507 = _3461.w;\n    vec3 up = _3505 * (_3507 * _3494);\n    float _3513;\n    if (_3490)\n    {\n        _3513 = (3.1415927410125732421875 * _3499) * _3499;\n    }\n    else\n    {\n        _3513 = (4.0 * _3499) * _3507;\n    }\n    if (_3467 > 1.5)\n    {\n        vec3 _3539 = cross(_3497, -_3472);\n        vec3 perp = _3539;\n        float _3543 = dot(_3539, _3539);\n        vec3 _3546;\n        if (_3543 > 1.0000000133514319600180897396058e-10)\n        {\n            _3546 = perp * inversesqrt(_3543);\n        }\n        else\n        {\n            _3546 = _3505;\n        }\n        perp = _3546;\n        up = _3546 * _3507;\n    }\n    float _3567 = max(_3513, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _3577 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _3577;\n    vec3 param_10 = n;\n    vec3 param_11 = _3472;\n    vec3 _3585 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _3577;\n    vec3 param_13 = n;\n    vec3 param_14 = _3497 * (_3499 * _3494);\n    vec3 _3593 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _3577;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _3601 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3467;\n    vec3 param_20 = _3585;\n    vec3 param_21 = _3593;\n    vec3 param_22 = _3601;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _3620 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _3620;\n    vec2 param_26 = _3620 + vec2(64.0, 0.0);\n    vec4 _3630 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _3467;\n    vec3 param_29 = _3585;\n    vec3 param_30 = _3593;\n    vec3 param_31 = _3601;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3630.x) + ((vec3(1.0) - f0) * _3630.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_3472, _3472)) + _3567) / _3567) * window);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2445 = tdh / at;\n    float _2449 = bdh / ab;\n    float _2461 = ((_2445 * _2445) + (_2449 * _2449)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2461) * _2461);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2542 = 1.0 / alpha;\n    return ((2.0 + _2542) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2542)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2575 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2654 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2654) * _2654);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2575);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2575));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2727 = max(dot(L.nc, l), 0.0);\n        float _2733 = max(dot(L.nc, h), 0.0);\n        float _2742 = ((_2733 * _2733) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2742) * _2742)) * (0.5 / max(mix((2.0 * _2727) * L.coat_ndv, _2727 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2727)) * _2727);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1842 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1845 = _1842.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1845 * _1845, exp2((-9.27999973297119140625) * ndv)) * _1845) + _1842.y)) + _1842.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1747 = rough * rough;\n    float _1777 = 0.60000002384185791015625 * _1747;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1747)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1777, 0.0500000007450580596923828125 + _1777, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1747 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2328;\n        if (L.aniso >= 0.0)\n        {\n            _2328 = L.b;\n        }\n        else\n        {\n            _2328 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2328, v), _2328), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2361 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2361.x) + (vec3(L.f90) * _2361.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2416 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2416.x) + _2416.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1884 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1884.x) + vec3(_1884.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1635 = int(fa_shadows[25].x + 0.5);\n    float _1645 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1650 = _1635 > 0;\n    bool _1659;\n    if (_1650)\n    {\n        int param = _1635 - 1;\n        _1659 = _1645 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1659 = _1650;\n    }\n    if (_1659)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1666 = _1635 > 1;\n        bool _1673;\n        if (_1666)\n        {\n            _1673 = _1645 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1673 = _1666;\n        }\n        if (_1673)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1679 = _1635 > 2;\n        bool _1686;\n        if (_1679)\n        {\n            _1686 = _1645 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1686 = _1679;\n        }\n        if (_1686)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1692 = _1635 > 3;\n        bool _1699;\n        if (_1692)\n        {\n            _1699 = _1645 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1699 = _1692;\n        }\n        if (_1699)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4621 = -_4621;\n    }\n    vec3 _4028 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface _4036 = fa_standard_surface(param_1);\n    vec3 _4652 = _4036.albedo;\n    float _4653 = _4036.alpha;\n    vec3 _4654 = _4036.normal;\n    float _4655 = _4036.metallic;\n    float _4656 = _4036.roughness;\n    float _4657 = _4036.occlusion;\n    vec3 _4658 = _4036.emission;\n    float _4659 = _4036.clearcoat;\n    float _4660 = _4036.clearcoat_roughness;\n    vec3 _4661 = _4036.sheen_color;\n    float _4662 = _4036.sheen_roughness;\n    float _4663 = _4036.anisotropy;\n    float _4664 = _4036.anisotropy_rotation;\n    float _4665 = _4036.specular;\n    float _4666 = _4036.ior;\n    vec3 _4667 = _4036.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n    Surface param_3 = _4036;\n    surface(param_2, param_3);\n    _4652 = param_3.albedo;\n    _4653 = param_3.alpha;\n    _4654 = param_3.normal;\n    _4655 = param_3.metallic;\n    _4656 = param_3.roughness;\n    _4657 = param_3.occlusion;\n    _4658 = param_3.emission;\n    _4659 = param_3.clearcoat;\n    _4660 = param_3.clearcoat_roughness;\n    _4661 = param_3.sheen_color;\n    _4662 = param_3.sheen_roughness;\n    _4663 = param_3.anisotropy;\n    _4664 = param_3.anisotropy_rotation;\n    _4665 = param_3.specular;\n    _4666 = param_3.ior;\n    _4667 = param_3.specular_color;\n    if (param_3.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4652;\n    }\n    else\n    {\n        vec3 _4069 = normalize(_4654);\n        float _4076 = clamp(_4655, 0.0, 1.0);\n        float _4080 = clamp(_4656, 0.0500000007450580596923828125, 1.0);\n        float _4084 = _4080 * _4080;\n        float _4088 = _4084 * _4084;\n        float _4093 = max(dot(_4069, _4028), 9.9999997473787516355514526367188e-05);\n        vec3 _4099 = _4652 * (1.0 - _4076);\n        vec3 _4106 = mix(vec3(0.039999999105930328369140625), _4652, vec3(_4076));\n        vec3 f0 = _4106;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing);\n        Surface param_5 = Surface(_4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661, _4662, _4663, _4664, _4665, _4666, _4667);\n        vec3 param_6 = _4069;\n        vec3 param_7 = _4028;\n        float param_8 = _4076;\n        float param_9 = _4080;\n        vec3 param_10 = _4106;\n        FaLayers _4122 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _4069;\n        vec3 lit = (fa_ambient_light(param_11) * _4099) * _4657;\n        if (_4122.on)\n        {\n            lit *= _4122.base_scale;\n        }\n        int _4144 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4144; ln++)\n        {\n            int param_12 = ln;\n            int _4157 = fa_cl_light(param_12);\n            int param_13 = _4157;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _4621;\n            LightSample _4166 = fa_light_shadowed(param_13, param_14, param_15);\n            float _4174 = max(dot(_4069, _4166.direction), 0.0);\n            float _4180 = _4166.attenuation * _4166.shadow;\n            vec3 _4185 = normalize(_4166.direction + _4028);\n            float _4190 = max(dot(_4069, _4185), 0.0);\n            float _4195 = max(dot(_4028, _4185), 0.0);\n            bool _4202;\n            if (fa_light_is_area)\n            {\n                _4202 = !_4122.on;\n            }\n            else\n            {\n                _4202 = fa_light_is_area;\n            }\n            if (_4202)\n            {\n                int param_16 = _4157;\n                vec3 param_17 = fa_world_pos;\n                vec3 param_18 = _4069;\n                vec3 param_19 = _4028;\n                vec3 param_20 = _4099;\n                vec3 param_21 = f0;\n                float param_22 = _4080;\n                float param_23 = _4093;\n                float param_24 = _4180;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);\n            }\n            else\n            {\n                if (_4122.on)\n                {\n                    FaLayers param_25 = _4122;\n                    vec3 param_26 = _4099;\n                    vec3 param_27 = f0;\n                    vec3 param_28 = _4069;\n                    vec3 param_29 = _4028;\n                    vec3 param_30 = _4166.direction;\n                    vec3 param_31 = _4185;\n                    float param_32 = _4174;\n                    float param_33 = _4093;\n                    float param_34 = _4190;\n                    float param_35 = _4195;\n                    float param_36 = _4084;\n                    float param_37 = _4088;\n                    int param_38 = _4157;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38) * fa_light_tint) * _4180));\n                }\n                else\n                {\n                    float _4277 = ((_4190 * _4190) * (_4088 - 1.0)) + 1.0;\n                    int param_39 = _4157;\n                    lit += (((_4099 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4195, 5.0))) * (((_4088 / ((3.1415927410125732421875 * _4277) * _4277)) * (0.5 / max(mix((2.0 * _4174) * _4093, _4174 + _4093, _4084), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4174))) * (fa_light_rgb(param_39) * fa_light_tint)) * (_4174 * _4180));\n                }\n            }\n        }\n        if (_4122.on)\n        {\n            FaLayers param_40 = _4122;\n            vec3 param_41 = _4069;\n            vec3 param_42 = _4028;\n            vec3 param_43 = f0;\n            float param_44 = _4080;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44) * _4657);\n        }\n        else\n        {\n            vec3 param_45 = _4069;\n            vec3 param_46 = _4028;\n            vec3 param_47 = f0;\n            float param_48 = _4080;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48) * _4657);\n        }\n        result = lit;\n    }\n    vec3 _4372 = result;\n    vec3 _4373 = _4372 + _4658;\n    result = _4373;\n    vec3 param_49 = _4373;\n    vec3 param_50 = fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50);\n    bool _4382 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4389;\n    if (!_4382)\n    {\n        _4389 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4389 = _4382;\n    }\n    if (_4389)\n    {\n        vec3 _4398 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4404 = dot(_4398, fa_mesh_fs_params[9].xyz);\n        bool _4408 = fa_mesh_fs_params[9].w > 0.5;\n        float _4409;\n        if (_4408)\n        {\n            _4409 = _4404;\n        }\n        else\n        {\n            _4409 = length(_4398);\n        }\n        float _4421 = _4409 - fa_mesh_fs_params[8].x;\n        if (_4421 > 0.0)\n        {\n            float _4430 = fa_mesh_fs_params[7].w * _4421;\n            float tau = _4430 * _4430;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4446;\n                if (_4408)\n                {\n                    _4446 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4404);\n                }\n                else\n                {\n                    _4446 = fa_mesh_fs_params[0].y;\n                }\n                float _4467 = mix(_4446, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4409, 0.0, 1.0));\n                float _4471 = fa_world_pos.y - _4467;\n                float _4476 = _4467 - fa_mesh_fs_params[8].z;\n                float _4481 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4484 = _4476 <= 0.0;\n                bool _4485 = !_4484;\n                bool _4491;\n                if (_4485)\n                {\n                    _4491 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4491 = _4484;\n                }\n                float _4492;\n                if (_4491)\n                {\n                    _4492 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4492 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4476, 80.0));\n                }\n                bool _4519;\n                if (_4485)\n                {\n                    _4519 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4519 = _4484;\n                }\n                float _4520;\n                if (_4519)\n                {\n                    _4520 = fa_mesh_fs_params[8].y * _4476;\n                }\n                else\n                {\n                    _4520 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4476, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4545 = _4481 <= 0.0;\n                bool _4552;\n                if (!_4545)\n                {\n                    _4552 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4552 = _4545;\n                }\n                float _4553;\n                if (_4552)\n                {\n                    _4553 = fa_mesh_fs_params[8].y * _4481;\n                }\n                else\n                {\n                    _4553 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4481, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4580;\n                if (abs(_4471) < 0.001000000047497451305389404296875)\n                {\n                    _4580 = _4492;\n                }\n                else\n                {\n                    _4580 = (_4553 - _4520) / _4471;\n                }\n                tau += (_4421 * max(_4580, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4653);\n}\n\n",
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
            "inst_name": "_381",
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
            "inst_name": "_1094",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4047",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _745 = base_t;\n    _745.x = _225.x;\n    _745.y = _225.y;\n    _745.z = _225.z;\n    base_t = _745;\n    vec4 _241 = (_745 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _708 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _753 = _279;\n        _753.x = _284.x;\n        _753.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _756 = mrt;\n    _756.x = _313.x;\n    _756.y = _313.y;\n    _756.z = _313.z;\n    mrt = _756;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _713 = fa_mesh_fs_params[20].x;\n    float _714 = fa_mesh_fs_params[20].y;\n    float _717 = fa_mesh_fs_params[20].z;\n    float _716 = fa_mesh_fs_params[21].w;\n    float _719 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _713 *= _355.y;\n            _714 *= _355.z;\n            _716 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _708, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _713, _714, fa_mesh_fs_params[21].xyz, _716, _717, fa_mesh_fs_params[20].w, _719, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface _524 = fa_standard_surface(param);\n    vec3 _643 = _524.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _643 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 _545 = normalize(_643);\n    vec3 _560 = normalize(vec3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    vec2 e = _560.xy / vec2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _745 = base_t;\n    _745.x = _225.x;\n    _745.y = _225.y;\n    _745.z = _225.z;\n    base_t = _745;\n    vec4 _241 = (_745 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _708 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _753 = _279;\n        _753.x = _284.x;\n        _753.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _756 = mrt;\n    _756.x = _313.x;\n    _756.y = _313.y;\n    _756.z = _313.z;\n    mrt = _756;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _713 = fa_mesh_fs_params[20].x;\n    float _714 = fa_mesh_fs_params[20].y;\n    float _717 = fa_mesh_fs_params[20].z;\n    float _716 = fa_mesh_fs_params[21].w;\n    float _719 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _713 *= _355.y;\n            _714 *= _355.z;\n            _716 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _708, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _713, _714, fa_mesh_fs_params[21].xyz, _716, _717, fa_mesh_fs_params[20].w, _719, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface _524 = fa_standard_surface(param);\n    vec3 _643 = _524.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _643 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 _545 = normalize(_643);\n    vec3 _560 = normalize(vec3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    vec2 e = _560.xy / vec2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _233 = _190.world_pos;\n    fa_world_pos = _233;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_233, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _679 = base_t;\n    _679.x = _225.x;\n    _679.y = _225.y;\n    _679.z = _225.z;\n    base_t = _679;\n    vec4 _241 = (_679 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _648 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _687 = _279;\n        _687.x = _284.x;\n        _687.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _687;\n        _648 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _690 = mrt;\n    _690.x = _313.x;\n    _690.y = _313.y;\n    _690.z = _313.z;\n    mrt = _690;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _653 = fa_mesh_fs_params[20].x;\n    float _654 = fa_mesh_fs_params[20].y;\n    float _657 = fa_mesh_fs_params[20].z;\n    float _656 = fa_mesh_fs_params[21].w;\n    float _659 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _653 *= _355.y;\n            _654 *= _355.z;\n            _656 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _657 *= mrt.x;\n            _659 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _648, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _653, _654, fa_mesh_fs_params[21].xyz, _656, _657, fa_mesh_fs_params[20].w, _659, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _559 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _559 = -_559;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_165 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_165 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_165 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vec3 _354 = _311.world_pos;\n    fa_world_pos = _354;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_354, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _679 = base_t;\n    _679.x = _225.x;\n    _679.y = _225.y;\n    _679.z = _225.z;\n    base_t = _679;\n    vec4 _241 = (_679 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _648 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _687 = _279;\n        _687.x = _284.x;\n        _687.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _687;\n        _648 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _690 = mrt;\n    _690.x = _313.x;\n    _690.y = _313.y;\n    _690.z = _313.z;\n    mrt = _690;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _653 = fa_mesh_fs_params[20].x;\n    float _654 = fa_mesh_fs_params[20].y;\n    float _657 = fa_mesh_fs_params[20].z;\n    float _656 = fa_mesh_fs_params[21].w;\n    float _659 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _653 *= _355.y;\n            _654 *= _355.z;\n            _656 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _657 *= mrt.x;\n            _659 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _648, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _653, _654, fa_mesh_fs_params[21].xyz, _656, _657, fa_mesh_fs_params[20].w, _659, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _559 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _559 = -_559;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
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
            "inst_name": "_174",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
