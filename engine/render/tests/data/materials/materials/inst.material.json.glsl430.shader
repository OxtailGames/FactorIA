{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
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
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1991[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _869 = fa_mesh_fs_params[19].x < 0.0;\n    bool _876;\n    if (!_869)\n    {\n        _876 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _876 = _869;\n    }\n    bool _884;\n    if (!_876)\n    {\n        _884 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _884 = _876;\n    }\n    bool _891;\n    if (!_884)\n    {\n        _891 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _891 = _884;\n    }\n    bool _898;\n    if (!_891)\n    {\n        _898 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _898 = _891;\n    }\n    if (_898)\n    {\n        return ivec2(0);\n    }\n    vec4 _908 = vec4(world_pos, 1.0);\n    float _915 = dot(fa_mesh_fs_params[16], _908);\n    if (!(_915 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _937 = vec2(dot(fa_mesh_fs_params[14], _908), dot(fa_mesh_fs_params[15], _908)) / vec2(_915);\n    int _941 = int(fa_mesh_fs_params[18].x);\n    int _945 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _945) + clamp(int(floor(((_937.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _945 - 1)) * _941)) + clamp(int(floor(((_937.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _941 - 1);\n    vec4 _1016 = fa_light_texel(param);\n    return ivec2(int(_1016.x), int(_1016.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2808 = fa_cluster_lookup(param);\n    fa_cl_slot = _2808.x;\n    fa_cl_local = _2808.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3753 = fa_linear_to_srgb(param);\n        c = _3753;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3761 = fa_srgb_to_linear(param_1);\n            c = _3761;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _319;\n    if (i.front_facing)\n    {\n        _319 = i.world_normal;\n    }\n    else\n    {\n        _319 = -i.world_normal;\n    }\n    vec3 _343 = normalize(i.world_tangent.xyz - (_319 * dot(_319, i.world_tangent.xyz)));\n    vec3 _371 = normalize(((_343 * m.x) + ((cross(_319, _343) * i.world_tangent.w) * m.y)) + (_319 * m.z));\n    vec3 _374;\n    if (i.front_facing)\n    {\n        _374 = _371;\n    }\n    else\n    {\n        _374 = -_371;\n    }\n    return _374;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3792 = fa_tex_fix(param_2, param_3);\n    vec4 _5022 = base_t;\n    _5022.x = _3792.x;\n    _5022.y = _3792.y;\n    _5022.z = _3792.z;\n    base_t = _5022;\n    vec4 _3806 = (_5022 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4932 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3838 = fa_tex_fix(param_6, param_7);\n        vec3 _3841 = (_3838 * 2.0) - vec3(1.0);\n        vec2 _3846 = _3841.xy * fa_mesh_fs_params[6].x;\n        vec3 _5030 = _3841;\n        _5030.x = _3846.x;\n        _5030.y = _3846.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5030;\n        _4932 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3874 = fa_tex_fix(param_12, param_13);\n    vec4 _5033 = mrt;\n    _5033.x = _3874.x;\n    _5033.y = _3874.y;\n    _5033.z = _3874.z;\n    mrt = _5033;\n    vec4 _3902 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3902.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3914 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3944 = fa_tex_fix(param_20, param_21);\n    float _4937 = fa_mesh_fs_params[20].x;\n    float _4938 = fa_mesh_fs_params[20].y;\n    float _4941 = fa_mesh_fs_params[20].z;\n    float _4940 = fa_mesh_fs_params[21].w;\n    float _4943 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4937 *= _3914.y;\n            _4938 *= _3914.z;\n            _4940 *= _3902.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4941 *= mrt.x;\n            _4943 *= mrt.w;\n        }\n    }\n    return Surface(_3806.xyz, _3806.w, _4932, clamp(fa_mesh_fs_params[5].x * _3874.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3874.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3914.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3944), _4937, _4938, fa_mesh_fs_params[21].xyz, _4940, _4941, fa_mesh_fs_params[20].w, _4943, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1916 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1924 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1927 = int(_1916);\n    int _1930 = int(_1924);\n    float _1940 = _1924 - float(_1930);\n    int _1996 = (_1927 * 9) + _1930;\n    int _2016 = ((_1927 + 1) * 9) + _1930;\n    return mix(mix(_1991[_1996], _1991[_1996 + 1], _1940), mix(_1991[_2016], _1991[_2016 + 1], _1940), _1916 - float(_1927));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4868 = false;\n    float _4869 = 1.0;\n    float _4870 = 1.0;\n    float _4871 = 1.0;\n    float _4872 = 0.0;\n    float _4873 = 0.0;\n    float _4874 = 0.0;\n    float _4875 = 0.0;\n    float _4877 = 1.0;\n    bool _4878 = false;\n    vec3 _4879 = vec3(0.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _4882 = 1.0;\n    float _4883 = 0.0;\n    float _4884 = 0.0;\n    vec3 _4885 = vec3(1.0, 0.0, 0.0);\n    vec3 _4886 = vec3(0.0, 0.0, 1.0);\n    float _4887 = 1.0;\n    float _4888 = 1.0;\n    float _2070 = clamp(s.specular, 0.0, 1.0);\n    float _2074 = clamp(s.ior, 1.0, 3.0);\n    bool _2079 = (_2070 != 1.0) || (_2074 != 1.5);\n    bool _2088;\n    if (!_2079)\n    {\n        _2088 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2088 = _2079;\n    }\n    if (_2088)\n    {\n        float _2096 = (_2074 - 1.0) / (_2074 + 1.0);\n        f0 = mix(min(vec3(_2096 * _2096) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2070, s.albedo, vec3(metallic));\n        _4869 = mix(_2070, 1.0, metallic);\n        _4868 = true;\n    }\n    float _2124 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2124 > 0.0)\n    {\n        float _2132 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4872 = _2124;\n        _4873 = _2132;\n        float _2139 = _2132 * _2132;\n        _4874 = _2139;\n        _4875 = _2139 * _2139;\n        float _2151 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4877 = _2151;\n        _4870 = 1.0 - (_2124 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2151, 0.0, 1.0), 5.0))));\n        _4868 = true;\n    }\n    vec3 _2171 = max(s.sheen_color, vec3(0.0));\n    float _2180 = max(_2171.x, max(_2171.y, _2171.z));\n    if (_2180 > 0.0)\n    {\n        float _2188 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4878 = true;\n        _4879 = _2171;\n        _4880 = _2188;\n        _4881 = _2188 * _2188;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2188;\n        float _2205 = fa_sheen_albedo(param, param_1);\n        _4883 = _2205;\n        _4882 = 1.0 - min(_2180 * _2205, 1.0);\n        _4868 = true;\n    }\n    _4871 = _4870 * _4882;\n    float _2224 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2224 != 0.0)\n    {\n        vec3 _2239 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2239;\n        if (dot(_2239, _2239) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2253 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2253.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2253.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2253.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2257 = t;\n        vec3 _2258 = normalize(_2257);\n        t = _2258;\n        vec3 _2283 = normalize((_2258 * cos(s.anisotropy_rotation)) + ((cross(n, _2258) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4885 = _2283;\n        _4886 = cross(n, _2283);\n        float _2293 = roughness * roughness;\n        float _2299 = mix(_2293, 1.0, _2224 * _2224);\n        bool _2301 = _2224 > 0.0;\n        _4887 = _2301 ? _2299 : _2293;\n        _4888 = _2301 ? _2293 : _2299;\n        _4884 = _2224;\n        _4868 = true;\n    }\n    return FaLayers(_4868, _4869, _4870, _4871, _4872, _4873, _4874, _4875, i.world_normal, _4877, _4878, _4879, _4880, _4881, _4882, _4883, _4884, _4885, _4886, _4887, _4888);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _477 = dot(d, right);\n    float _481 = dot(d, up);\n    float _492;\n    if (((_477 * _477) + (_481 * _481)) > 1.0000000133514319600180897396058e-10)\n    {\n        _492 = atan(_481, _477) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_492 - floor(_492)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _525 = fa_light_base(param);\n    bool _529 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _525;\n    vec4 _533 = fa_light_texel(param_1);\n    int param_2 = _525 + 1;\n    vec4 _538 = fa_light_texel(param_2);\n    float _541 = _538.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _553 = _529 && (_541 > 2.5);\n    fa_light_is_area = _553;\n    bool _556 = _541 < 0.5;\n    vec3 l;\n    if (_556)\n    {\n        l = normalize(_533.xyz);\n        if (_529)\n        {\n            int param_3 = _525 + 6;\n            vec4 _570 = fa_light_texel(param_3);\n            if (_570.z > 0.5)\n            {\n                int param_4 = _525 + 4;\n                vec4 _580 = fa_light_texel(param_4);\n                int param_5 = _525 + 5;\n                vec4 _586 = fa_light_texel(param_5);\n                vec2 param_6 = _570.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _580.xyz) * _580.w, (-dot(world_pos, _586.xyz)) * _586.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _618 = _533.xyz - world_pos;\n        float _620 = length(_618);\n        dist = _620;\n        l = _618 / vec3(max(_620, 9.9999997473787516355514526367188e-05));\n        float reach = _620;\n        if (_553)\n        {\n            int param_8 = _525 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _652 = reach / max(_533.w, 0.001000000047497451305389404296875);\n        float _658 = clamp(1.0 - (_652 * _652), 0.0, 1.0);\n        atten = _658 * _658;\n        bool _666 = _541 < 2.5;\n        if ((_541 > 1.5) && _666)\n        {\n            int param_9 = _525 + 2;\n            vec4 _674 = fa_light_texel(param_9);\n            float _684 = _674.w;\n            int param_10 = _525 + 3;\n            vec4 _690 = fa_light_texel(param_10);\n            float _691 = _690.x;\n            float cos_inner = _691;\n            if (_691 > 1.5)\n            {\n                cos_inner = mix(_684, 1.0, 0.25);\n            }\n            atten *= smoothstep(_684, cos_inner, dot(-l, normalize(_674.xyz)));\n        }\n        if (_529 && _666)\n        {\n            int param_11 = _525 + 6;\n            vec4 _715 = fa_light_texel(param_11);\n            int param_12 = _525 + 7;\n            vec4 _720 = fa_light_texel(param_12);\n            bool _723 = _715.z > 0.5;\n            bool _730;\n            if (!_723)\n            {\n                _730 = _720.z > 0.5;\n            }\n            else\n            {\n                _730 = _723;\n            }\n            if (_730)\n            {\n                int param_13 = _525 + 2;\n                vec4 _737 = fa_light_texel(param_13);\n                vec3 _741 = normalize(_737.xyz);\n                int param_14 = _525 + 4;\n                vec4 _746 = fa_light_texel(param_14);\n                int param_15 = _525 + 5;\n                vec4 _751 = fa_light_texel(param_15);\n                if (_723)\n                {\n                    vec3 _759 = -_618;\n                    float _766 = _737.w;\n                    float _782 = 0.5 / max(dot(_759, _741) * (sqrt(max(1.0 - (_766 * _766), 0.0)) / max(_766, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _715.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_759, _746.xyz) * _782), 0.5 - (dot(_759, _751.xyz) * _782));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_720.z > 0.5)\n                {\n                    vec2 param_18 = _720.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _741;\n                    vec3 param_21 = _746.xyz;\n                    vec3 param_22 = _751.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _4856 = _538.xyz * atten;\n    if (_529)\n    {\n        _4856 *= fa_light_tint;\n    }\n    int _851;\n    if (_556)\n    {\n        _851 = 0;\n    }\n    else\n    {\n        _851 = ((_541 > 1.5) && (_541 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4856, atten, 1.0, dist, _851);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1090;\n    if (i == 0)\n    {\n        _1090 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1106;\n        if (i == 1)\n        {\n            _1106 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1114;\n            if (i == 2)\n            {\n                _1114 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1114 = fa_shadows[24].w;\n            }\n            _1106 = _1114;\n        }\n        _1090 = _1106;\n    }\n    return _1090;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1078 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1078), sin(_1078)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1152 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1157 = clamp(dot(n, l), 0.0, 1.0);\n    float _1163 = sqrt(1.0 - (_1157 * _1157));\n    float _1171 = min(_1163 / max(_1157, 0.20000000298023223876953125), 4.0);\n    float _1176;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1176 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1176 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1201 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1176 * _1163)), 1.0);\n    float _1208 = _1201.x;\n    bool _1211 = _1208 < fa_shadows[ci * 1 + 16].x;\n    bool _1220;\n    if (!_1211)\n    {\n        _1220 = _1208 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1220 = _1211;\n    }\n    bool _1229;\n    if (!_1220)\n    {\n        _1229 = _1201.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1229 = _1220;\n    }\n    bool _1238;\n    if (!_1229)\n    {\n        _1238 = _1201.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1238 = _1229;\n    }\n    bool _1245;\n    if (!_1238)\n    {\n        _1245 = _1201.z > 1.0;\n    }\n    else\n    {\n        _1245 = _1238;\n    }\n    if (_1245)\n    {\n        return -1.0;\n    }\n    float _1253;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1253 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1253 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1272 = _1201.z - ((_1253 * (1.0 + (0.5 * _1171))) / _1152);\n    float _1281 = ((fa_shadows[ci * 1 + 20].x * min(_1171, 3.0)) * 0.5) / _1152;\n    int _1290 = int(fa_shadows[25].z + 0.5);\n    if (_1290 == 1)\n    {\n        vec2 param = _1201.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1301 = fa_shadow_depth(param, param_1);\n        return float(_1272 <= _1301);\n    }\n    float _1308 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1311 = _1290 == 2;\n    if (_1311)\n    {\n        float _1325 = clamp(((fa_shadows[25].w * _1152) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1308;\n            vec2 _1344 = fa_shadow_vogel(param_2, param_3, param_4) * _1325;\n            vec2 param_5 = _1201.xy + (_1344 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1355 = fa_shadow_depth(param_5, param_6);\n            if (_1355 < (_1272 - (length(_1344) * _1281)))\n            {\n                sum += _1355;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1272 - (sum / cnt), 0.0) * _1152) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1399 = _1311 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1399; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1399;\n        float param_9 = _1308;\n        vec2 _1418 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1201.xy + (_1418 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1429 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1272 - (length(_1418) * _1281)) <= _1429);\n    }\n    return lit / float(_1399);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1459 = int(fa_shadows[25].x + 0.5);\n    if (_1459 < 1)\n    {\n        return 1.0;\n    }\n    float _1474 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1459 - 1;\n    if (_1474 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1486 = _1459 > 1;\n    bool _1493;\n    if (_1486)\n    {\n        _1493 = _1474 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    if (_1493)\n    {\n        ci = 1;\n    }\n    bool _1497 = _1459 > 2;\n    bool _1504;\n    if (_1497)\n    {\n        _1504 = _1474 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1504 = _1497;\n    }\n    if (_1504)\n    {\n        ci = 2;\n    }\n    bool _1508 = _1459 > 3;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1474 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1459)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1541 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1541;\n        if (_1541 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1566;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1566 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1566 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1585 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1566, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1596 = clamp((_1474 - (fa_shadow_split_at(param_7) - _1585)) / _1585, 0.0, 1.0);\n        if (_1596 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1459)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1617 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1617;\n                if (_1617 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1596);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2836 = fa_light_sample(param, param_1);\n    vec3 _4912 = _2836.color;\n    float _4914 = _2836.shadow;\n    if ((_2836.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2836.direction;\n        float _2850 = fa_shadow_factor(param_2, param_3);\n        _4914 = _2850;\n        _4912 *= _2850;\n    }\n    return LightSample(_2836.direction, _4912, _2836.attenuation, _4914, _2836._distance, _2836.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _2890 = v - (n * dot(v, n));\n    vec3 t = _2890;\n    float _2894 = dot(_2890, _2890);\n    float l2 = _2894;\n    if (_2894 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _2904;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2904 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2904 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _2904;\n        l2 = dot(_2904, _2904);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _2939 = dot(a, a);\n    float _2943 = dot(b, b);\n    if ((_2939 < 1.0000000195414813782625560981111e-24) || (_2943 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _2957 = a * inversesqrt(_2939);\n    vec3 _2962 = b * inversesqrt(_2943);\n    float _2966 = dot(_2957, _2962);\n    float _2969 = abs(_2966);\n    float g = (((((((((((0.0416471660137176513671875 * _2969) - 0.1924748718738555908203125) * _2969) + 0.4179156124591827392578125) * _2969) - 0.616057217121124267578125) * _2969) + 0.777722418308258056640625) * _2969) - 0.999542415142059326171875) * _2969) + 1.570791721343994140625;\n    if (_2966 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_2966 * _2966), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2957, _2962) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _3026 = a.z > 0.0;\n    bool _3030 = b.z > 0.0;\n    if (_3026 && _3030)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3026 != _3030)\n        {\n            vec3 _3065 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3065.z = 0.0;\n            if (_3026)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _3065;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3065;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _3065;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3065;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _3114 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _3140 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _3166 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _3192 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _3114;\n    vec3 param_1 = _3140;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _3140;\n    vec3 param_7 = _3166;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _3166;\n    vec3 param_13 = _3192;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _3192;\n    vec3 param_19 = _3114;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _3342 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3366 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3382 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _3342;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _3366;\n    vec4 param_9 = m;\n    vec3 param_10 = _3342;\n    vec3 param_11 = _3366;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _3382;\n    vec4 param_14 = m;\n    vec3 param_15 = _3342;\n    vec3 param_16 = _3382;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _3440 = fa_light_base(param);\n    int param_1 = _3440;\n    int param_2 = _3440 + 1;\n    int param_3 = _3440 + 2;\n    int param_4 = _3440 + 4;\n    vec4 _3462 = fa_light_texel(param_4);\n    int param_5 = _3440 + 5;\n    vec4 _3467 = fa_light_texel(param_5);\n    int param_6 = _3440 + 6;\n    vec4 _3472 = fa_light_texel(param_6);\n    float _3473 = _3472.w;\n    vec3 _3478 = fa_light_texel(param_1).xyz - world_pos;\n    bool _3480 = _3473 < 1.5;\n    bool _3487;\n    if (_3480)\n    {\n        _3487 = dot(normalize(fa_light_texel(param_3).xyz), _3478) >= 0.0;\n    }\n    else\n    {\n        _3487 = _3480;\n    }\n    if (_3487)\n    {\n        return vec3(0.0);\n    }\n    bool _3496 = (_3473 > 0.5) && _3480;\n    float _3500 = _3496 ? 1.0539000034332275390625 : 1.0;\n    vec3 _3503 = _3462.xyz;\n    float _3505 = _3462.w;\n    vec3 _3511 = _3467.xyz;\n    float _3513 = _3467.w;\n    vec3 up = _3511 * (_3513 * _3500);\n    float _3519;\n    if (_3496)\n    {\n        _3519 = (3.1415927410125732421875 * _3505) * _3505;\n    }\n    else\n    {\n        _3519 = (4.0 * _3505) * _3513;\n    }\n    if (_3473 > 1.5)\n    {\n        vec3 _3545 = cross(_3503, -_3478);\n        vec3 perp = _3545;\n        float _3549 = dot(_3545, _3545);\n        vec3 _3552;\n        if (_3549 > 1.0000000133514319600180897396058e-10)\n        {\n            _3552 = perp * inversesqrt(_3549);\n        }\n        else\n        {\n            _3552 = _3511;\n        }\n        perp = _3552;\n        up = _3552 * _3513;\n    }\n    float _3573 = max(_3519, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _3583 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _3583;\n    vec3 param_10 = n;\n    vec3 param_11 = _3478;\n    vec3 _3591 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _3583;\n    vec3 param_13 = n;\n    vec3 param_14 = _3503 * (_3505 * _3500);\n    vec3 _3599 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _3583;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _3607 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3473;\n    vec3 param_20 = _3591;\n    vec3 param_21 = _3599;\n    vec3 param_22 = _3607;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _3626 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _3626;\n    vec2 param_26 = _3626 + vec2(64.0, 0.0);\n    vec4 _3636 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _3473;\n    vec3 param_29 = _3591;\n    vec3 param_30 = _3599;\n    vec3 param_31 = _3607;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3636.x) + ((vec3(1.0) - f0) * _3636.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_3478, _3478)) + _3573) / _3573) * window);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2451 = tdh / at;\n    float _2455 = bdh / ab;\n    float _2467 = ((_2451 * _2451) + (_2455 * _2455)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2467) * _2467);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2548 = 1.0 / alpha;\n    return ((2.0 + _2548) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2548)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2581 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2660 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2660) * _2660);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2581);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2581));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2733 = max(dot(L.nc, l), 0.0);\n        float _2739 = max(dot(L.nc, h), 0.0);\n        float _2748 = ((_2739 * _2739) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2748) * _2748)) * (0.5 / max(mix((2.0 * _2733) * L.coat_ndv, _2733 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2733)) * _2733);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1848 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1851 = _1848.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1851 * _1851, exp2((-9.27999973297119140625) * ndv)) * _1851) + _1848.y)) + _1848.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1753 = rough * rough;\n    float _1783 = 0.60000002384185791015625 * _1753;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1753)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1783, 0.0500000007450580596923828125 + _1783, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1753 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2334;\n        if (L.aniso >= 0.0)\n        {\n            _2334 = L.b;\n        }\n        else\n        {\n            _2334 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2334, v), _2334), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2367 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2367.x) + (vec3(L.f90) * _2367.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2422 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2422.x) + _2422.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1890 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1890.x) + vec3(_1890.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1641 = int(fa_shadows[25].x + 0.5);\n    float _1651 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1656 = _1641 > 0;\n    bool _1665;\n    if (_1656)\n    {\n        int param = _1641 - 1;\n        _1665 = _1651 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1665 = _1656;\n    }\n    if (_1665)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1672 = _1641 > 1;\n        bool _1679;\n        if (_1672)\n        {\n            _1679 = _1651 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1679 = _1672;\n        }\n        if (_1679)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1685 = _1641 > 2;\n        bool _1692;\n        if (_1685)\n        {\n            _1692 = _1651 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1692 = _1685;\n        }\n        if (_1692)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1698 = _1641 > 3;\n        bool _1705;\n        if (_1698)\n        {\n            _1705 = _1651 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1705 = _1698;\n        }\n        if (_1705)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4647 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4647 = -_4647;\n    }\n    vec3 _4065 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4647, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface _4073 = fa_standard_surface(param_1);\n    vec3 _4678 = _4073.albedo;\n    float _4679 = _4073.alpha;\n    vec3 _4680 = _4073.normal;\n    float _4681 = _4073.metallic;\n    float _4682 = _4073.roughness;\n    float _4683 = _4073.occlusion;\n    vec3 _4684 = _4073.emission;\n    float _4685 = _4073.clearcoat;\n    float _4686 = _4073.clearcoat_roughness;\n    vec3 _4687 = _4073.sheen_color;\n    float _4688 = _4073.sheen_roughness;\n    float _4689 = _4073.anisotropy;\n    float _4690 = _4073.anisotropy_rotation;\n    float _4691 = _4073.specular;\n    float _4692 = _4073.ior;\n    vec3 _4693 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4647, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface param_3 = _4073;\n    surface(param_2, param_3);\n    _4678 = param_3.albedo;\n    _4679 = param_3.alpha;\n    _4680 = param_3.normal;\n    _4681 = param_3.metallic;\n    _4682 = param_3.roughness;\n    _4683 = param_3.occlusion;\n    _4684 = param_3.emission;\n    _4685 = param_3.clearcoat;\n    _4686 = param_3.clearcoat_roughness;\n    _4687 = param_3.sheen_color;\n    _4688 = param_3.sheen_roughness;\n    _4689 = param_3.anisotropy;\n    _4690 = param_3.anisotropy_rotation;\n    _4691 = param_3.specular;\n    _4692 = param_3.ior;\n    _4693 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4678;\n    }\n    else\n    {\n        vec3 _4095 = normalize(_4680);\n        float _4102 = clamp(_4681, 0.0, 1.0);\n        float _4106 = clamp(_4682, 0.0500000007450580596923828125, 1.0);\n        float _4110 = _4106 * _4106;\n        float _4114 = _4110 * _4110;\n        float _4119 = max(dot(_4095, _4065), 9.9999997473787516355514526367188e-05);\n        vec3 _4125 = _4678 * (1.0 - _4102);\n        vec3 _4132 = mix(vec3(0.039999999105930328369140625), _4678, vec3(_4102));\n        vec3 f0 = _4132;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _4647, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n        Surface param_5 = Surface(_4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693);\n        vec3 param_6 = _4095;\n        vec3 param_7 = _4065;\n        float param_8 = _4102;\n        float param_9 = _4106;\n        vec3 param_10 = _4132;\n        FaLayers _4148 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _4095;\n        vec3 lit = (fa_ambient_light(param_11) * _4125) * _4683;\n        if (_4148.on)\n        {\n            lit *= _4148.base_scale;\n        }\n        int _4170 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4170; ln++)\n        {\n            int param_12 = ln;\n            int _4183 = fa_cl_light(param_12);\n            int param_13 = _4183;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _4647;\n            LightSample _4192 = fa_light_shadowed(param_13, param_14, param_15);\n            float _4200 = max(dot(_4095, _4192.direction), 0.0);\n            float _4206 = _4192.attenuation * _4192.shadow;\n            vec3 _4211 = normalize(_4192.direction + _4065);\n            float _4216 = max(dot(_4095, _4211), 0.0);\n            float _4221 = max(dot(_4065, _4211), 0.0);\n            bool _4228;\n            if (fa_light_is_area)\n            {\n                _4228 = !_4148.on;\n            }\n            else\n            {\n                _4228 = fa_light_is_area;\n            }\n            if (_4228)\n            {\n                int param_16 = _4183;\n                vec3 param_17 = fa_world_pos;\n                vec3 param_18 = _4095;\n                vec3 param_19 = _4065;\n                vec3 param_20 = _4125;\n                vec3 param_21 = f0;\n                float param_22 = _4106;\n                float param_23 = _4119;\n                float param_24 = _4206;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);\n            }\n            else\n            {\n                if (_4148.on)\n                {\n                    FaLayers param_25 = _4148;\n                    vec3 param_26 = _4125;\n                    vec3 param_27 = f0;\n                    vec3 param_28 = _4095;\n                    vec3 param_29 = _4065;\n                    vec3 param_30 = _4192.direction;\n                    vec3 param_31 = _4211;\n                    float param_32 = _4200;\n                    float param_33 = _4119;\n                    float param_34 = _4216;\n                    float param_35 = _4221;\n                    float param_36 = _4110;\n                    float param_37 = _4114;\n                    int param_38 = _4183;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38) * fa_light_tint) * _4206));\n                }\n                else\n                {\n                    float _4303 = ((_4216 * _4216) * (_4114 - 1.0)) + 1.0;\n                    int param_39 = _4183;\n                    lit += (((_4125 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4221, 5.0))) * (((_4114 / ((3.1415927410125732421875 * _4303) * _4303)) * (0.5 / max(mix((2.0 * _4200) * _4119, _4200 + _4119, _4110), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4200))) * (fa_light_rgb(param_39) * fa_light_tint)) * (_4200 * _4206));\n                }\n            }\n        }\n        if (_4148.on)\n        {\n            FaLayers param_40 = _4148;\n            vec3 param_41 = _4095;\n            vec3 param_42 = _4065;\n            vec3 param_43 = f0;\n            float param_44 = _4106;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44) * _4683);\n        }\n        else\n        {\n            vec3 param_45 = _4095;\n            vec3 param_46 = _4065;\n            vec3 param_47 = f0;\n            float param_48 = _4106;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48) * _4683);\n        }\n        result = lit;\n    }\n    vec3 _4398 = result;\n    vec3 _4399 = _4398 + _4684;\n    result = _4399;\n    vec3 param_49 = _4399;\n    vec3 param_50 = fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50);\n    bool _4408 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4415;\n    if (!_4408)\n    {\n        _4415 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4415 = _4408;\n    }\n    if (_4415)\n    {\n        vec3 _4424 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4430 = dot(_4424, fa_mesh_fs_params[9].xyz);\n        bool _4434 = fa_mesh_fs_params[9].w > 0.5;\n        float _4435;\n        if (_4434)\n        {\n            _4435 = _4430;\n        }\n        else\n        {\n            _4435 = length(_4424);\n        }\n        float _4447 = _4435 - fa_mesh_fs_params[8].x;\n        if (_4447 > 0.0)\n        {\n            float _4456 = fa_mesh_fs_params[7].w * _4447;\n            float tau = _4456 * _4456;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4472;\n                if (_4434)\n                {\n                    _4472 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4430);\n                }\n                else\n                {\n                    _4472 = fa_mesh_fs_params[0].y;\n                }\n                float _4493 = mix(_4472, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4435, 0.0, 1.0));\n                float _4497 = fa_world_pos.y - _4493;\n                float _4502 = _4493 - fa_mesh_fs_params[8].z;\n                float _4507 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4510 = _4502 <= 0.0;\n                bool _4511 = !_4510;\n                bool _4517;\n                if (_4511)\n                {\n                    _4517 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4517 = _4510;\n                }\n                float _4518;\n                if (_4517)\n                {\n                    _4518 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4518 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4502, 80.0));\n                }\n                bool _4545;\n                if (_4511)\n                {\n                    _4545 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4545 = _4510;\n                }\n                float _4546;\n                if (_4545)\n                {\n                    _4546 = fa_mesh_fs_params[8].y * _4502;\n                }\n                else\n                {\n                    _4546 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4502, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4571 = _4507 <= 0.0;\n                bool _4578;\n                if (!_4571)\n                {\n                    _4578 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4578 = _4571;\n                }\n                float _4579;\n                if (_4578)\n                {\n                    _4579 = fa_mesh_fs_params[8].y * _4507;\n                }\n                else\n                {\n                    _4579 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4507, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4606;\n                if (abs(_4497) < 0.001000000047497451305389404296875)\n                {\n                    _4606 = _4518;\n                }\n                else\n                {\n                    _4606 = (_4579 - _4546) / _4497;\n                }\n                tau += (_4447 * max(_4606, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4679);\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "inst_name": "_387",
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
            "inst_name": "_1100",
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
            "inst_name": "_3689",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1991[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _869 = fa_mesh_fs_params[19].x < 0.0;\n    bool _876;\n    if (!_869)\n    {\n        _876 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _876 = _869;\n    }\n    bool _884;\n    if (!_876)\n    {\n        _884 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _884 = _876;\n    }\n    bool _891;\n    if (!_884)\n    {\n        _891 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _891 = _884;\n    }\n    bool _898;\n    if (!_891)\n    {\n        _898 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _898 = _891;\n    }\n    if (_898)\n    {\n        return ivec2(0);\n    }\n    vec4 _908 = vec4(world_pos, 1.0);\n    float _915 = dot(fa_mesh_fs_params[16], _908);\n    if (!(_915 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _937 = vec2(dot(fa_mesh_fs_params[14], _908), dot(fa_mesh_fs_params[15], _908)) / vec2(_915);\n    int _941 = int(fa_mesh_fs_params[18].x);\n    int _945 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _945) + clamp(int(floor(((_937.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _945 - 1)) * _941)) + clamp(int(floor(((_937.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _941 - 1);\n    vec4 _1016 = fa_light_texel(param);\n    return ivec2(int(_1016.x), int(_1016.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2808 = fa_cluster_lookup(param);\n    fa_cl_slot = _2808.x;\n    fa_cl_local = _2808.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3753 = fa_linear_to_srgb(param);\n        c = _3753;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3761 = fa_srgb_to_linear(param_1);\n            c = _3761;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _319;\n    if (i.front_facing)\n    {\n        _319 = i.world_normal;\n    }\n    else\n    {\n        _319 = -i.world_normal;\n    }\n    vec3 _343 = normalize(i.world_tangent.xyz - (_319 * dot(_319, i.world_tangent.xyz)));\n    vec3 _371 = normalize(((_343 * m.x) + ((cross(_319, _343) * i.world_tangent.w) * m.y)) + (_319 * m.z));\n    vec3 _374;\n    if (i.front_facing)\n    {\n        _374 = _371;\n    }\n    else\n    {\n        _374 = -_371;\n    }\n    return _374;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3792 = fa_tex_fix(param_2, param_3);\n    vec4 _5022 = base_t;\n    _5022.x = _3792.x;\n    _5022.y = _3792.y;\n    _5022.z = _3792.z;\n    base_t = _5022;\n    vec4 _3806 = (_5022 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4932 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3838 = fa_tex_fix(param_6, param_7);\n        vec3 _3841 = (_3838 * 2.0) - vec3(1.0);\n        vec2 _3846 = _3841.xy * fa_mesh_fs_params[6].x;\n        vec3 _5030 = _3841;\n        _5030.x = _3846.x;\n        _5030.y = _3846.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5030;\n        _4932 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3874 = fa_tex_fix(param_12, param_13);\n    vec4 _5033 = mrt;\n    _5033.x = _3874.x;\n    _5033.y = _3874.y;\n    _5033.z = _3874.z;\n    mrt = _5033;\n    vec4 _3902 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3902.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3914 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3944 = fa_tex_fix(param_20, param_21);\n    float _4937 = fa_mesh_fs_params[20].x;\n    float _4938 = fa_mesh_fs_params[20].y;\n    float _4941 = fa_mesh_fs_params[20].z;\n    float _4940 = fa_mesh_fs_params[21].w;\n    float _4943 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4937 *= _3914.y;\n            _4938 *= _3914.z;\n            _4940 *= _3902.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4941 *= mrt.x;\n            _4943 *= mrt.w;\n        }\n    }\n    return Surface(_3806.xyz, _3806.w, _4932, clamp(fa_mesh_fs_params[5].x * _3874.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3874.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3914.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3944), _4937, _4938, fa_mesh_fs_params[21].xyz, _4940, _4941, fa_mesh_fs_params[20].w, _4943, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1916 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1924 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1927 = int(_1916);\n    int _1930 = int(_1924);\n    float _1940 = _1924 - float(_1930);\n    int _1996 = (_1927 * 9) + _1930;\n    int _2016 = ((_1927 + 1) * 9) + _1930;\n    return mix(mix(_1991[_1996], _1991[_1996 + 1], _1940), mix(_1991[_2016], _1991[_2016 + 1], _1940), _1916 - float(_1927));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4868 = false;\n    float _4869 = 1.0;\n    float _4870 = 1.0;\n    float _4871 = 1.0;\n    float _4872 = 0.0;\n    float _4873 = 0.0;\n    float _4874 = 0.0;\n    float _4875 = 0.0;\n    float _4877 = 1.0;\n    bool _4878 = false;\n    vec3 _4879 = vec3(0.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _4882 = 1.0;\n    float _4883 = 0.0;\n    float _4884 = 0.0;\n    vec3 _4885 = vec3(1.0, 0.0, 0.0);\n    vec3 _4886 = vec3(0.0, 0.0, 1.0);\n    float _4887 = 1.0;\n    float _4888 = 1.0;\n    float _2070 = clamp(s.specular, 0.0, 1.0);\n    float _2074 = clamp(s.ior, 1.0, 3.0);\n    bool _2079 = (_2070 != 1.0) || (_2074 != 1.5);\n    bool _2088;\n    if (!_2079)\n    {\n        _2088 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2088 = _2079;\n    }\n    if (_2088)\n    {\n        float _2096 = (_2074 - 1.0) / (_2074 + 1.0);\n        f0 = mix(min(vec3(_2096 * _2096) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2070, s.albedo, vec3(metallic));\n        _4869 = mix(_2070, 1.0, metallic);\n        _4868 = true;\n    }\n    float _2124 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2124 > 0.0)\n    {\n        float _2132 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4872 = _2124;\n        _4873 = _2132;\n        float _2139 = _2132 * _2132;\n        _4874 = _2139;\n        _4875 = _2139 * _2139;\n        float _2151 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4877 = _2151;\n        _4870 = 1.0 - (_2124 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2151, 0.0, 1.0), 5.0))));\n        _4868 = true;\n    }\n    vec3 _2171 = max(s.sheen_color, vec3(0.0));\n    float _2180 = max(_2171.x, max(_2171.y, _2171.z));\n    if (_2180 > 0.0)\n    {\n        float _2188 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4878 = true;\n        _4879 = _2171;\n        _4880 = _2188;\n        _4881 = _2188 * _2188;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2188;\n        float _2205 = fa_sheen_albedo(param, param_1);\n        _4883 = _2205;\n        _4882 = 1.0 - min(_2180 * _2205, 1.0);\n        _4868 = true;\n    }\n    _4871 = _4870 * _4882;\n    float _2224 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2224 != 0.0)\n    {\n        vec3 _2239 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2239;\n        if (dot(_2239, _2239) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2253 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2253.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2253.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2253.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2257 = t;\n        vec3 _2258 = normalize(_2257);\n        t = _2258;\n        vec3 _2283 = normalize((_2258 * cos(s.anisotropy_rotation)) + ((cross(n, _2258) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4885 = _2283;\n        _4886 = cross(n, _2283);\n        float _2293 = roughness * roughness;\n        float _2299 = mix(_2293, 1.0, _2224 * _2224);\n        bool _2301 = _2224 > 0.0;\n        _4887 = _2301 ? _2299 : _2293;\n        _4888 = _2301 ? _2293 : _2299;\n        _4884 = _2224;\n        _4868 = true;\n    }\n    return FaLayers(_4868, _4869, _4870, _4871, _4872, _4873, _4874, _4875, i.world_normal, _4877, _4878, _4879, _4880, _4881, _4882, _4883, _4884, _4885, _4886, _4887, _4888);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _477 = dot(d, right);\n    float _481 = dot(d, up);\n    float _492;\n    if (((_477 * _477) + (_481 * _481)) > 1.0000000133514319600180897396058e-10)\n    {\n        _492 = atan(_481, _477) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_492 - floor(_492)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _525 = fa_light_base(param);\n    bool _529 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _525;\n    vec4 _533 = fa_light_texel(param_1);\n    int param_2 = _525 + 1;\n    vec4 _538 = fa_light_texel(param_2);\n    float _541 = _538.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _553 = _529 && (_541 > 2.5);\n    fa_light_is_area = _553;\n    bool _556 = _541 < 0.5;\n    vec3 l;\n    if (_556)\n    {\n        l = normalize(_533.xyz);\n        if (_529)\n        {\n            int param_3 = _525 + 6;\n            vec4 _570 = fa_light_texel(param_3);\n            if (_570.z > 0.5)\n            {\n                int param_4 = _525 + 4;\n                vec4 _580 = fa_light_texel(param_4);\n                int param_5 = _525 + 5;\n                vec4 _586 = fa_light_texel(param_5);\n                vec2 param_6 = _570.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _580.xyz) * _580.w, (-dot(world_pos, _586.xyz)) * _586.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _618 = _533.xyz - world_pos;\n        float _620 = length(_618);\n        dist = _620;\n        l = _618 / vec3(max(_620, 9.9999997473787516355514526367188e-05));\n        float reach = _620;\n        if (_553)\n        {\n            int param_8 = _525 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _652 = reach / max(_533.w, 0.001000000047497451305389404296875);\n        float _658 = clamp(1.0 - (_652 * _652), 0.0, 1.0);\n        atten = _658 * _658;\n        bool _666 = _541 < 2.5;\n        if ((_541 > 1.5) && _666)\n        {\n            int param_9 = _525 + 2;\n            vec4 _674 = fa_light_texel(param_9);\n            float _684 = _674.w;\n            int param_10 = _525 + 3;\n            vec4 _690 = fa_light_texel(param_10);\n            float _691 = _690.x;\n            float cos_inner = _691;\n            if (_691 > 1.5)\n            {\n                cos_inner = mix(_684, 1.0, 0.25);\n            }\n            atten *= smoothstep(_684, cos_inner, dot(-l, normalize(_674.xyz)));\n        }\n        if (_529 && _666)\n        {\n            int param_11 = _525 + 6;\n            vec4 _715 = fa_light_texel(param_11);\n            int param_12 = _525 + 7;\n            vec4 _720 = fa_light_texel(param_12);\n            bool _723 = _715.z > 0.5;\n            bool _730;\n            if (!_723)\n            {\n                _730 = _720.z > 0.5;\n            }\n            else\n            {\n                _730 = _723;\n            }\n            if (_730)\n            {\n                int param_13 = _525 + 2;\n                vec4 _737 = fa_light_texel(param_13);\n                vec3 _741 = normalize(_737.xyz);\n                int param_14 = _525 + 4;\n                vec4 _746 = fa_light_texel(param_14);\n                int param_15 = _525 + 5;\n                vec4 _751 = fa_light_texel(param_15);\n                if (_723)\n                {\n                    vec3 _759 = -_618;\n                    float _766 = _737.w;\n                    float _782 = 0.5 / max(dot(_759, _741) * (sqrt(max(1.0 - (_766 * _766), 0.0)) / max(_766, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _715.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_759, _746.xyz) * _782), 0.5 - (dot(_759, _751.xyz) * _782));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_720.z > 0.5)\n                {\n                    vec2 param_18 = _720.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _741;\n                    vec3 param_21 = _746.xyz;\n                    vec3 param_22 = _751.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _4856 = _538.xyz * atten;\n    if (_529)\n    {\n        _4856 *= fa_light_tint;\n    }\n    int _851;\n    if (_556)\n    {\n        _851 = 0;\n    }\n    else\n    {\n        _851 = ((_541 > 1.5) && (_541 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4856, atten, 1.0, dist, _851);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1090;\n    if (i == 0)\n    {\n        _1090 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1106;\n        if (i == 1)\n        {\n            _1106 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1114;\n            if (i == 2)\n            {\n                _1114 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1114 = fa_shadows[24].w;\n            }\n            _1106 = _1114;\n        }\n        _1090 = _1106;\n    }\n    return _1090;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1078 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1078), sin(_1078)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1152 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1157 = clamp(dot(n, l), 0.0, 1.0);\n    float _1163 = sqrt(1.0 - (_1157 * _1157));\n    float _1171 = min(_1163 / max(_1157, 0.20000000298023223876953125), 4.0);\n    float _1176;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1176 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1176 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1201 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1176 * _1163)), 1.0);\n    float _1208 = _1201.x;\n    bool _1211 = _1208 < fa_shadows[ci * 1 + 16].x;\n    bool _1220;\n    if (!_1211)\n    {\n        _1220 = _1208 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1220 = _1211;\n    }\n    bool _1229;\n    if (!_1220)\n    {\n        _1229 = _1201.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1229 = _1220;\n    }\n    bool _1238;\n    if (!_1229)\n    {\n        _1238 = _1201.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1238 = _1229;\n    }\n    bool _1245;\n    if (!_1238)\n    {\n        _1245 = _1201.z > 1.0;\n    }\n    else\n    {\n        _1245 = _1238;\n    }\n    if (_1245)\n    {\n        return -1.0;\n    }\n    float _1253;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1253 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1253 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1272 = _1201.z - ((_1253 * (1.0 + (0.5 * _1171))) / _1152);\n    float _1281 = ((fa_shadows[ci * 1 + 20].x * min(_1171, 3.0)) * 0.5) / _1152;\n    int _1290 = int(fa_shadows[25].z + 0.5);\n    if (_1290 == 1)\n    {\n        vec2 param = _1201.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1301 = fa_shadow_depth(param, param_1);\n        return float(_1272 <= _1301);\n    }\n    float _1308 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1311 = _1290 == 2;\n    if (_1311)\n    {\n        float _1325 = clamp(((fa_shadows[25].w * _1152) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1308;\n            vec2 _1344 = fa_shadow_vogel(param_2, param_3, param_4) * _1325;\n            vec2 param_5 = _1201.xy + (_1344 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1355 = fa_shadow_depth(param_5, param_6);\n            if (_1355 < (_1272 - (length(_1344) * _1281)))\n            {\n                sum += _1355;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1272 - (sum / cnt), 0.0) * _1152) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1399 = _1311 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1399; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1399;\n        float param_9 = _1308;\n        vec2 _1418 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1201.xy + (_1418 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1429 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1272 - (length(_1418) * _1281)) <= _1429);\n    }\n    return lit / float(_1399);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1459 = int(fa_shadows[25].x + 0.5);\n    if (_1459 < 1)\n    {\n        return 1.0;\n    }\n    float _1474 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1459 - 1;\n    if (_1474 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1486 = _1459 > 1;\n    bool _1493;\n    if (_1486)\n    {\n        _1493 = _1474 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    if (_1493)\n    {\n        ci = 1;\n    }\n    bool _1497 = _1459 > 2;\n    bool _1504;\n    if (_1497)\n    {\n        _1504 = _1474 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1504 = _1497;\n    }\n    if (_1504)\n    {\n        ci = 2;\n    }\n    bool _1508 = _1459 > 3;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1474 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1459)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1541 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1541;\n        if (_1541 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1566;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1566 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1566 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1585 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1566, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1596 = clamp((_1474 - (fa_shadow_split_at(param_7) - _1585)) / _1585, 0.0, 1.0);\n        if (_1596 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1459)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1617 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1617;\n                if (_1617 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1596);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2836 = fa_light_sample(param, param_1);\n    vec3 _4912 = _2836.color;\n    float _4914 = _2836.shadow;\n    if ((_2836.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2836.direction;\n        float _2850 = fa_shadow_factor(param_2, param_3);\n        _4914 = _2850;\n        _4912 *= _2850;\n    }\n    return LightSample(_2836.direction, _4912, _2836.attenuation, _4914, _2836._distance, _2836.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _2890 = v - (n * dot(v, n));\n    vec3 t = _2890;\n    float _2894 = dot(_2890, _2890);\n    float l2 = _2894;\n    if (_2894 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _2904;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2904 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2904 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _2904;\n        l2 = dot(_2904, _2904);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _2939 = dot(a, a);\n    float _2943 = dot(b, b);\n    if ((_2939 < 1.0000000195414813782625560981111e-24) || (_2943 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _2957 = a * inversesqrt(_2939);\n    vec3 _2962 = b * inversesqrt(_2943);\n    float _2966 = dot(_2957, _2962);\n    float _2969 = abs(_2966);\n    float g = (((((((((((0.0416471660137176513671875 * _2969) - 0.1924748718738555908203125) * _2969) + 0.4179156124591827392578125) * _2969) - 0.616057217121124267578125) * _2969) + 0.777722418308258056640625) * _2969) - 0.999542415142059326171875) * _2969) + 1.570791721343994140625;\n    if (_2966 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_2966 * _2966), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2957, _2962) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _3026 = a.z > 0.0;\n    bool _3030 = b.z > 0.0;\n    if (_3026 && _3030)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3026 != _3030)\n        {\n            vec3 _3065 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3065.z = 0.0;\n            if (_3026)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _3065;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3065;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _3065;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3065;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _3114 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _3140 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _3166 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _3192 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _3114;\n    vec3 param_1 = _3140;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _3140;\n    vec3 param_7 = _3166;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _3166;\n    vec3 param_13 = _3192;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _3192;\n    vec3 param_19 = _3114;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _3342 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3366 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _3382 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _3342;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _3366;\n    vec4 param_9 = m;\n    vec3 param_10 = _3342;\n    vec3 param_11 = _3366;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _3382;\n    vec4 param_14 = m;\n    vec3 param_15 = _3342;\n    vec3 param_16 = _3382;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _3440 = fa_light_base(param);\n    int param_1 = _3440;\n    int param_2 = _3440 + 1;\n    int param_3 = _3440 + 2;\n    int param_4 = _3440 + 4;\n    vec4 _3462 = fa_light_texel(param_4);\n    int param_5 = _3440 + 5;\n    vec4 _3467 = fa_light_texel(param_5);\n    int param_6 = _3440 + 6;\n    vec4 _3472 = fa_light_texel(param_6);\n    float _3473 = _3472.w;\n    vec3 _3478 = fa_light_texel(param_1).xyz - world_pos;\n    bool _3480 = _3473 < 1.5;\n    bool _3487;\n    if (_3480)\n    {\n        _3487 = dot(normalize(fa_light_texel(param_3).xyz), _3478) >= 0.0;\n    }\n    else\n    {\n        _3487 = _3480;\n    }\n    if (_3487)\n    {\n        return vec3(0.0);\n    }\n    bool _3496 = (_3473 > 0.5) && _3480;\n    float _3500 = _3496 ? 1.0539000034332275390625 : 1.0;\n    vec3 _3503 = _3462.xyz;\n    float _3505 = _3462.w;\n    vec3 _3511 = _3467.xyz;\n    float _3513 = _3467.w;\n    vec3 up = _3511 * (_3513 * _3500);\n    float _3519;\n    if (_3496)\n    {\n        _3519 = (3.1415927410125732421875 * _3505) * _3505;\n    }\n    else\n    {\n        _3519 = (4.0 * _3505) * _3513;\n    }\n    if (_3473 > 1.5)\n    {\n        vec3 _3545 = cross(_3503, -_3478);\n        vec3 perp = _3545;\n        float _3549 = dot(_3545, _3545);\n        vec3 _3552;\n        if (_3549 > 1.0000000133514319600180897396058e-10)\n        {\n            _3552 = perp * inversesqrt(_3549);\n        }\n        else\n        {\n            _3552 = _3511;\n        }\n        perp = _3552;\n        up = _3552 * _3513;\n    }\n    float _3573 = max(_3519, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _3583 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _3583;\n    vec3 param_10 = n;\n    vec3 param_11 = _3478;\n    vec3 _3591 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _3583;\n    vec3 param_13 = n;\n    vec3 param_14 = _3503 * (_3505 * _3500);\n    vec3 _3599 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _3583;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _3607 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3473;\n    vec3 param_20 = _3591;\n    vec3 param_21 = _3599;\n    vec3 param_22 = _3607;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _3626 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _3626;\n    vec2 param_26 = _3626 + vec2(64.0, 0.0);\n    vec4 _3636 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _3473;\n    vec3 param_29 = _3591;\n    vec3 param_30 = _3599;\n    vec3 param_31 = _3607;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3636.x) + ((vec3(1.0) - f0) * _3636.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_3478, _3478)) + _3573) / _3573) * window);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2451 = tdh / at;\n    float _2455 = bdh / ab;\n    float _2467 = ((_2451 * _2451) + (_2455 * _2455)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2467) * _2467);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2548 = 1.0 / alpha;\n    return ((2.0 + _2548) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2548)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2581 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2660 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2660) * _2660);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2581);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2581));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2733 = max(dot(L.nc, l), 0.0);\n        float _2739 = max(dot(L.nc, h), 0.0);\n        float _2748 = ((_2739 * _2739) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2748) * _2748)) * (0.5 / max(mix((2.0 * _2733) * L.coat_ndv, _2733 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2733)) * _2733);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1848 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1851 = _1848.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1851 * _1851, exp2((-9.27999973297119140625) * ndv)) * _1851) + _1848.y)) + _1848.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1753 = rough * rough;\n    float _1783 = 0.60000002384185791015625 * _1753;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1753)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1783, 0.0500000007450580596923828125 + _1783, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1753 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2334;\n        if (L.aniso >= 0.0)\n        {\n            _2334 = L.b;\n        }\n        else\n        {\n            _2334 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2334, v), _2334), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2367 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2367.x) + (vec3(L.f90) * _2367.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2422 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2422.x) + _2422.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1890 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1890.x) + vec3(_1890.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1641 = int(fa_shadows[25].x + 0.5);\n    float _1651 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1656 = _1641 > 0;\n    bool _1665;\n    if (_1656)\n    {\n        int param = _1641 - 1;\n        _1665 = _1651 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1665 = _1656;\n    }\n    if (_1665)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1672 = _1641 > 1;\n        bool _1679;\n        if (_1672)\n        {\n            _1679 = _1651 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1679 = _1672;\n        }\n        if (_1679)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1685 = _1641 > 2;\n        bool _1692;\n        if (_1685)\n        {\n            _1692 = _1651 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1692 = _1685;\n        }\n        if (_1692)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1698 = _1641 > 3;\n        bool _1705;\n        if (_1698)\n        {\n            _1705 = _1651 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1705 = _1698;\n        }\n        if (_1705)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4647 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4647 = -_4647;\n    }\n    vec3 _4065 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4647, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface _4073 = fa_standard_surface(param_1);\n    vec3 _4678 = _4073.albedo;\n    float _4679 = _4073.alpha;\n    vec3 _4680 = _4073.normal;\n    float _4681 = _4073.metallic;\n    float _4682 = _4073.roughness;\n    float _4683 = _4073.occlusion;\n    vec3 _4684 = _4073.emission;\n    float _4685 = _4073.clearcoat;\n    float _4686 = _4073.clearcoat_roughness;\n    vec3 _4687 = _4073.sheen_color;\n    float _4688 = _4073.sheen_roughness;\n    float _4689 = _4073.anisotropy;\n    float _4690 = _4073.anisotropy_rotation;\n    float _4691 = _4073.specular;\n    float _4692 = _4073.ior;\n    vec3 _4693 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4647, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface param_3 = _4073;\n    surface(param_2, param_3);\n    _4678 = param_3.albedo;\n    _4679 = param_3.alpha;\n    _4680 = param_3.normal;\n    _4681 = param_3.metallic;\n    _4682 = param_3.roughness;\n    _4683 = param_3.occlusion;\n    _4684 = param_3.emission;\n    _4685 = param_3.clearcoat;\n    _4686 = param_3.clearcoat_roughness;\n    _4687 = param_3.sheen_color;\n    _4688 = param_3.sheen_roughness;\n    _4689 = param_3.anisotropy;\n    _4690 = param_3.anisotropy_rotation;\n    _4691 = param_3.specular;\n    _4692 = param_3.ior;\n    _4693 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4678;\n    }\n    else\n    {\n        vec3 _4095 = normalize(_4680);\n        float _4102 = clamp(_4681, 0.0, 1.0);\n        float _4106 = clamp(_4682, 0.0500000007450580596923828125, 1.0);\n        float _4110 = _4106 * _4106;\n        float _4114 = _4110 * _4110;\n        float _4119 = max(dot(_4095, _4065), 9.9999997473787516355514526367188e-05);\n        vec3 _4125 = _4678 * (1.0 - _4102);\n        vec3 _4132 = mix(vec3(0.039999999105930328369140625), _4678, vec3(_4102));\n        vec3 f0 = _4132;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _4647, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n        Surface param_5 = Surface(_4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693);\n        vec3 param_6 = _4095;\n        vec3 param_7 = _4065;\n        float param_8 = _4102;\n        float param_9 = _4106;\n        vec3 param_10 = _4132;\n        FaLayers _4148 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _4095;\n        vec3 lit = (fa_ambient_light(param_11) * _4125) * _4683;\n        if (_4148.on)\n        {\n            lit *= _4148.base_scale;\n        }\n        int _4170 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4170; ln++)\n        {\n            int param_12 = ln;\n            int _4183 = fa_cl_light(param_12);\n            int param_13 = _4183;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _4647;\n            LightSample _4192 = fa_light_shadowed(param_13, param_14, param_15);\n            float _4200 = max(dot(_4095, _4192.direction), 0.0);\n            float _4206 = _4192.attenuation * _4192.shadow;\n            vec3 _4211 = normalize(_4192.direction + _4065);\n            float _4216 = max(dot(_4095, _4211), 0.0);\n            float _4221 = max(dot(_4065, _4211), 0.0);\n            bool _4228;\n            if (fa_light_is_area)\n            {\n                _4228 = !_4148.on;\n            }\n            else\n            {\n                _4228 = fa_light_is_area;\n            }\n            if (_4228)\n            {\n                int param_16 = _4183;\n                vec3 param_17 = fa_world_pos;\n                vec3 param_18 = _4095;\n                vec3 param_19 = _4065;\n                vec3 param_20 = _4125;\n                vec3 param_21 = f0;\n                float param_22 = _4106;\n                float param_23 = _4119;\n                float param_24 = _4206;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);\n            }\n            else\n            {\n                if (_4148.on)\n                {\n                    FaLayers param_25 = _4148;\n                    vec3 param_26 = _4125;\n                    vec3 param_27 = f0;\n                    vec3 param_28 = _4095;\n                    vec3 param_29 = _4065;\n                    vec3 param_30 = _4192.direction;\n                    vec3 param_31 = _4211;\n                    float param_32 = _4200;\n                    float param_33 = _4119;\n                    float param_34 = _4216;\n                    float param_35 = _4221;\n                    float param_36 = _4110;\n                    float param_37 = _4114;\n                    int param_38 = _4183;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38) * fa_light_tint) * _4206));\n                }\n                else\n                {\n                    float _4303 = ((_4216 * _4216) * (_4114 - 1.0)) + 1.0;\n                    int param_39 = _4183;\n                    lit += (((_4125 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4221, 5.0))) * (((_4114 / ((3.1415927410125732421875 * _4303) * _4303)) * (0.5 / max(mix((2.0 * _4200) * _4119, _4200 + _4119, _4110), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4200))) * (fa_light_rgb(param_39) * fa_light_tint)) * (_4200 * _4206));\n                }\n            }\n        }\n        if (_4148.on)\n        {\n            FaLayers param_40 = _4148;\n            vec3 param_41 = _4095;\n            vec3 param_42 = _4065;\n            vec3 param_43 = f0;\n            float param_44 = _4106;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44) * _4683);\n        }\n        else\n        {\n            vec3 param_45 = _4095;\n            vec3 param_46 = _4065;\n            vec3 param_47 = f0;\n            float param_48 = _4106;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48) * _4683);\n        }\n        result = lit;\n    }\n    vec3 _4398 = result;\n    vec3 _4399 = _4398 + _4684;\n    result = _4399;\n    vec3 param_49 = _4399;\n    vec3 param_50 = fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50);\n    bool _4408 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4415;\n    if (!_4408)\n    {\n        _4415 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4415 = _4408;\n    }\n    if (_4415)\n    {\n        vec3 _4424 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4430 = dot(_4424, fa_mesh_fs_params[9].xyz);\n        bool _4434 = fa_mesh_fs_params[9].w > 0.5;\n        float _4435;\n        if (_4434)\n        {\n            _4435 = _4430;\n        }\n        else\n        {\n            _4435 = length(_4424);\n        }\n        float _4447 = _4435 - fa_mesh_fs_params[8].x;\n        if (_4447 > 0.0)\n        {\n            float _4456 = fa_mesh_fs_params[7].w * _4447;\n            float tau = _4456 * _4456;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4472;\n                if (_4434)\n                {\n                    _4472 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4430);\n                }\n                else\n                {\n                    _4472 = fa_mesh_fs_params[0].y;\n                }\n                float _4493 = mix(_4472, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4435, 0.0, 1.0));\n                float _4497 = fa_world_pos.y - _4493;\n                float _4502 = _4493 - fa_mesh_fs_params[8].z;\n                float _4507 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4510 = _4502 <= 0.0;\n                bool _4511 = !_4510;\n                bool _4517;\n                if (_4511)\n                {\n                    _4517 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4517 = _4510;\n                }\n                float _4518;\n                if (_4517)\n                {\n                    _4518 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4518 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4502, 80.0));\n                }\n                bool _4545;\n                if (_4511)\n                {\n                    _4545 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4545 = _4510;\n                }\n                float _4546;\n                if (_4545)\n                {\n                    _4546 = fa_mesh_fs_params[8].y * _4502;\n                }\n                else\n                {\n                    _4546 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4502, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4571 = _4507 <= 0.0;\n                bool _4578;\n                if (!_4571)\n                {\n                    _4578 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4578 = _4571;\n                }\n                float _4579;\n                if (_4578)\n                {\n                    _4579 = fa_mesh_fs_params[8].y * _4507;\n                }\n                else\n                {\n                    _4579 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4507, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4606;\n                if (abs(_4497) < 0.001000000047497451305389404296875)\n                {\n                    _4606 = _4518;\n                }\n                else\n                {\n                    _4606 = (_4579 - _4546) / _4497;\n                }\n                tau += (_4447 * max(_4606, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4679);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "inst_name": "_205",
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
            "inst_name": "_387",
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
            "inst_name": "_1100",
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
            "inst_name": "_3689",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    vec4 _280 = (_771 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _734 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = fa_mesh_fs_params[20].x;\n    float _740 = fa_mesh_fs_params[20].y;\n    float _743 = fa_mesh_fs_params[20].z;\n    float _742 = fa_mesh_fs_params[21].w;\n    float _745 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _734, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _739, _740, fa_mesh_fs_params[21].xyz, _742, _743, fa_mesh_fs_params[20].w, _745, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    vec4 _280 = (_771 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _734 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = fa_mesh_fs_params[20].x;\n    float _740 = fa_mesh_fs_params[20].y;\n    float _743 = fa_mesh_fs_params[20].z;\n    float _742 = fa_mesh_fs_params[21].w;\n    float _745 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _734, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _739, _740, fa_mesh_fs_params[21].xyz, _742, _743, fa_mesh_fs_params[20].w, _745, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "inst_name": "_205",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
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
            "inst_name": "_196",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}
