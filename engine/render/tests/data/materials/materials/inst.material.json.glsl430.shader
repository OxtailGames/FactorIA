{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2003[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _495 = fa_mesh_fs_params[19].x < 0.0;\n    bool _502;\n    if (!_495)\n    {\n        _502 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _502 = _495;\n    }\n    bool _510;\n    if (!_502)\n    {\n        _510 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _510 = _502;\n    }\n    bool _517;\n    if (!_510)\n    {\n        _517 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _517 = _510;\n    }\n    bool _524;\n    if (!_517)\n    {\n        _524 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _524 = _517;\n    }\n    if (_524)\n    {\n        return ivec2(0);\n    }\n    vec4 _534 = vec4(world_pos, 1.0);\n    float _541 = dot(fa_mesh_fs_params[16], _534);\n    if (!(_541 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _563 = vec2(dot(fa_mesh_fs_params[14], _534), dot(fa_mesh_fs_params[15], _534)) / vec2(_541);\n    int _567 = int(fa_mesh_fs_params[18].x);\n    int _571 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _571) + clamp(int(floor(((_563.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _571 - 1)) * _567)) + clamp(int(floor(((_563.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _567 - 1);\n    vec4 _642 = fa_light_texel(param);\n    return ivec2(int(_642.x), int(_642.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2820 = fa_cluster_lookup(param);\n    fa_cl_slot = _2820.x;\n    fa_cl_local = _2820.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2980 = fa_linear_to_srgb(param);\n        c = _2980;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2988 = fa_srgb_to_linear(param_1);\n            c = _2988;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _262;\n    if (i.front_facing)\n    {\n        _262 = i.world_normal;\n    }\n    else\n    {\n        _262 = -i.world_normal;\n    }\n    vec3 _286 = normalize(i.world_tangent.xyz - (_262 * dot(_262, i.world_tangent.xyz)));\n    vec3 _314 = normalize(((_286 * m.x) + ((cross(_262, _286) * i.world_tangent.w) * m.y)) + (_262 * m.z));\n    vec3 _317;\n    if (i.front_facing)\n    {\n        _317 = _314;\n    }\n    else\n    {\n        _317 = -_314;\n    }\n    return _317;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3019 = fa_tex_fix(param_2, param_3);\n    vec4 _4222 = base_t;\n    _4222.x = _3019.x;\n    _4222.y = _3019.y;\n    _4222.z = _3019.z;\n    base_t = _4222;\n    vec4 _3033 = (_4222 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4124 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3065 = fa_tex_fix(param_6, param_7);\n        vec3 _3068 = (_3065 * 2.0) - vec3(1.0);\n        vec2 _3073 = _3068.xy * fa_mesh_fs_params[6].x;\n        vec3 _4230 = _3068;\n        _4230.x = _3073.x;\n        _4230.y = _3073.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4230;\n        _4124 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3102 = fa_tex_fix(param_12, param_13);\n    vec4 _4233 = mrt;\n    _4233.x = _3102.x;\n    _4233.y = _3102.y;\n    _4233.z = _3102.z;\n    mrt = _4233;\n    vec4 _3130 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3130.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3142 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3172 = fa_tex_fix(param_20, param_21);\n    float _4129 = fa_mesh_fs_params[20].x;\n    float _4130 = fa_mesh_fs_params[20].y;\n    float _4133 = fa_mesh_fs_params[20].z;\n    float _4132 = fa_mesh_fs_params[21].w;\n    float _4135 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4129 *= _3142.y;\n            _4130 *= _3142.z;\n            _4132 *= _3130.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4133 *= mrt.x;\n            _4135 *= mrt.w;\n        }\n    }\n    return Surface(_3033.xyz, _3033.w, _4124, clamp(fa_mesh_fs_params[5].x * _3102.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3102.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3142.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3172), _4129, _4130, fa_mesh_fs_params[21].xyz, _4132, _4133, fa_mesh_fs_params[20].w, _4135, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1928 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1936 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1939 = int(_1928);\n    int _1942 = int(_1936);\n    float _1952 = _1936 - float(_1942);\n    int _2008 = (_1939 * 9) + _1942;\n    int _2028 = ((_1939 + 1) * 9) + _1942;\n    return mix(mix(_2003[_2008], _2003[_2008 + 1], _1952), mix(_2003[_2028], _2003[_2028 + 1], _1952), _1928 - float(_1939));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4060 = false;\n    float _4061 = 1.0;\n    float _4062 = 1.0;\n    float _4063 = 1.0;\n    float _4064 = 0.0;\n    float _4065 = 0.0;\n    float _4066 = 0.0;\n    float _4067 = 0.0;\n    float _4069 = 1.0;\n    bool _4070 = false;\n    vec3 _4071 = vec3(0.0);\n    float _4072 = 1.0;\n    float _4073 = 1.0;\n    float _4074 = 1.0;\n    float _4075 = 0.0;\n    float _4076 = 0.0;\n    vec3 _4077 = vec3(1.0, 0.0, 0.0);\n    vec3 _4078 = vec3(0.0, 0.0, 1.0);\n    float _4079 = 1.0;\n    float _4080 = 1.0;\n    float _2081 = clamp(s.specular, 0.0, 1.0);\n    float _2085 = clamp(s.ior, 1.0, 3.0);\n    bool _2090 = (_2081 != 1.0) || (_2085 != 1.5);\n    bool _2100;\n    if (!_2090)\n    {\n        _2100 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2100 = _2090;\n    }\n    if (_2100)\n    {\n        float _2108 = (_2085 - 1.0) / (_2085 + 1.0);\n        f0 = mix(min(vec3(_2108 * _2108) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2081, s.albedo, vec3(metallic));\n        _4061 = mix(_2081, 1.0, metallic);\n        _4060 = true;\n    }\n    float _2136 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2136 > 0.0)\n    {\n        float _2144 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4064 = _2136;\n        _4065 = _2144;\n        float _2151 = _2144 * _2144;\n        _4066 = _2151;\n        _4067 = _2151 * _2151;\n        float _2163 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4069 = _2163;\n        _4062 = 1.0 - (_2136 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2163, 0.0, 1.0), 5.0))));\n        _4060 = true;\n    }\n    vec3 _2183 = max(s.sheen_color, vec3(0.0));\n    float _2192 = max(_2183.x, max(_2183.y, _2183.z));\n    if (_2192 > 0.0)\n    {\n        float _2200 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4070 = true;\n        _4071 = _2183;\n        _4072 = _2200;\n        _4073 = _2200 * _2200;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2200;\n        float _2217 = fa_sheen_albedo(param, param_1);\n        _4075 = _2217;\n        _4074 = 1.0 - min(_2192 * _2217, 1.0);\n        _4060 = true;\n    }\n    _4063 = _4062 * _4074;\n    float _2236 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2236 != 0.0)\n    {\n        vec3 _2251 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2251;\n        if (dot(_2251, _2251) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2265 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2265.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2265.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2265.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2269 = t;\n        vec3 _2270 = normalize(_2269);\n        t = _2270;\n        vec3 _2295 = normalize((_2270 * cos(s.anisotropy_rotation)) + ((cross(n, _2270) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4077 = _2295;\n        _4078 = cross(n, _2295);\n        float _2305 = roughness * roughness;\n        float _2311 = mix(_2305, 1.0, _2236 * _2236);\n        bool _2313 = _2236 > 0.0;\n        _4079 = _2313 ? _2311 : _2305;\n        _4080 = _2313 ? _2305 : _2311;\n        _4076 = _2236;\n        _4060 = true;\n    }\n    return FaLayers(_4060, _4061, _4062, _4063, _4064, _4065, _4066, _4067, i.world_normal, _4069, _4070, _4071, _4072, _4073, _4074, _4075, _4076, _4077, _4078, _4079, _4080);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _362 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _368 = fa_light_texel(param_1);\n    float _371 = _368.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _378 = _371 < 0.5;\n    vec3 l;\n    if (_378)\n    {\n        l = normalize(_362.xyz);\n    }\n    else\n    {\n        vec3 _390 = _362.xyz - world_pos;\n        float _392 = length(_390);\n        dist = _392;\n        l = _390 / vec3(max(_392, 9.9999997473787516355514526367188e-05));\n        float _407 = _392 / max(_362.w, 0.001000000047497451305389404296875);\n        float _413 = clamp(1.0 - (_407 * _407), 0.0, 1.0);\n        atten = _413 * _413;\n        if (_371 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _427 = fa_light_texel(param_2);\n            float _437 = _427.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _444 = fa_light_texel(param_3);\n            float _445 = _444.x;\n            float cos_inner = _445;\n            if (_445 > 1.5)\n            {\n                cos_inner = mix(_437, 1.0, 0.25);\n            }\n            atten *= smoothstep(_437, cos_inner, dot(-l, normalize(_427.xyz)));\n        }\n    }\n    int _476;\n    if (_378)\n    {\n        _476 = 0;\n    }\n    else\n    {\n        _476 = (_371 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _368.xyz * atten, atten, 1.0, dist, _476);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _716;\n    if (i == 0)\n    {\n        _716 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _732;\n        if (i == 1)\n        {\n            _732 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _740;\n            if (i == 2)\n            {\n                _740 = fa_shadows[24].z;\n            }\n            else\n            {\n                _740 = fa_shadows[24].w;\n            }\n            _732 = _740;\n        }\n        _716 = _732;\n    }\n    return _716;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _773 = fa_shadow_depth(param, param_1);\n    float _777;\n    if (conv.x < 0.5)\n    {\n        _777 = _773;\n    }\n    else\n    {\n        _777 = (conv.y * conv.z) / (conv.z - (_773 * (conv.z - conv.y)));\n    }\n    return _777;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _704 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_704), sin(_704)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _823 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _837 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _823;\n            vec2 _856 = fa_shadow_vogel(param_3, param_4, param_5) * _837;\n            vec2 param_6 = uv + (_856 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _868 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_868 < (zr - (length(_856) * plane)))\n            {\n                sum += _868;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _912 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _912; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _912;\n        float param_11 = _823;\n        vec2 _931 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_931 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_931) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_912);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _973 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _978 = clamp(dot(n, l), 0.0, 1.0);\n    float _984 = sqrt(1.0 - (_978 * _978));\n    float _992 = min(_984 / max(_978, 0.20000000298023223876953125), 4.0);\n    float _997;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _997 = fa_shadows[26].y;\n    }\n    else\n    {\n        _997 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1022 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_997 * _984)), 1.0);\n    float _1029 = _1022.x;\n    bool _1032 = _1029 < fa_shadows[ci * 1 + 16].x;\n    bool _1041;\n    if (!_1032)\n    {\n        _1041 = _1029 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1041 = _1032;\n    }\n    bool _1050;\n    if (!_1041)\n    {\n        _1050 = _1022.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1050 = _1041;\n    }\n    bool _1059;\n    if (!_1050)\n    {\n        _1059 = _1022.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1059 = _1050;\n    }\n    bool _1066;\n    if (!_1059)\n    {\n        _1066 = _1022.z > 1.0;\n    }\n    else\n    {\n        _1066 = _1059;\n    }\n    if (_1066)\n    {\n        return -1.0;\n    }\n    float _1075;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1075 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1075 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1022.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1022.z - ((_1075 * (1.0 + (0.5 * _992))) / _973);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _973;\n    float param_5 = _973 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_992, 3.0)) * 0.5) / _973;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1469 = int(fa_shadows[25].x + 0.5);\n    if (_1469 < 1)\n    {\n        return 1.0;\n    }\n    float _1485 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1469 - 1;\n    if (_1485 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1497 = _1469 > 1;\n    bool _1504;\n    if (_1497)\n    {\n        _1504 = _1485 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1504 = _1497;\n    }\n    if (_1504)\n    {\n        ci = 1;\n    }\n    bool _1508 = _1469 > 2;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1485 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 2;\n    }\n    bool _1519 = _1469 > 3;\n    bool _1526;\n    if (_1519)\n    {\n        _1526 = _1485 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    if (_1526)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1469)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1552 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1552;\n        if (_1552 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1577;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1577 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1577 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1596 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1577, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1607 = clamp((_1485 - (fa_shadow_split_at(param_7) - _1596)) / _1596, 0.0, 1.0);\n        if (_1607 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1469)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1628 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1628;\n                if (_1628 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1607);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1134 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1142;\n    if (!_1134)\n    {\n        _1142 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1142 = _1134;\n    }\n    if (_1142)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1155 = fa_light_texel(param);\n    float _1156 = _1155.x;\n    if (_1156 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1165 = int(_1156 + 0.5);\n    int param_1 = _1165;\n    vec4 _1169 = fa_light_texel(param_1);\n    int param_2 = _1165 + 1;\n    vec4 _1174 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1177 = _1169.y;\n    if (_1177 > 0.0)\n    {\n        float _1194 = 1.0 - smoothstep(0.75 * _1177, _1177, length(world - fa_shadows[27].xyz));\n        fade = _1194;\n        if (_1194 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1169.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1213 = world - fa_light_texel(param_3).xyz;\n        vec3 _1216 = abs(_1213);\n        float _1218 = _1216.x;\n        float _1220 = _1216.y;\n        bool _1221 = _1218 >= _1220;\n        bool _1229;\n        if (_1221)\n        {\n            _1229 = _1218 >= _1216.z;\n        }\n        else\n        {\n            _1229 = _1221;\n        }\n        int _1230;\n        if (_1229)\n        {\n            _1230 = (_1213.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1243;\n            if (_1220 >= _1216.z)\n            {\n                _1243 = (_1213.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1243 = (_1213.z > 0.0) ? 4 : 5;\n            }\n            _1230 = _1243;\n        }\n        face = _1230;\n    }\n    int _1262 = (_1165 + 2) + (face * 6);\n    int param_4 = _1262;\n    int param_5 = _1262 + 1;\n    int param_6 = _1262 + 3;\n    vec4 _1276 = fa_light_texel(param_6);\n    int param_7 = _1262 + 4;\n    vec4 _1281 = fa_light_texel(param_7);\n    int param_8 = _1262 + 5;\n    vec4 _1286 = fa_light_texel(param_8);\n    float _1298 = _1286.x * max(dot(_1276, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1303 = clamp(dot(n, l), 0.0, 1.0);\n    float _1309 = sqrt(1.0 - (_1303 * _1303));\n    float _1315 = min(_1309 / max(_1303, 0.20000000298023223876953125), 4.0);\n    float _1318 = _1174.y;\n    float _1320;\n    if (_1318 > 0.0)\n    {\n        _1320 = _1318;\n    }\n    else\n    {\n        _1320 = 1.5 * _1298;\n    }\n    vec4 _1340 = vec4(world + (n * (_1320 * _1309)), 1.0);\n    float _1344 = dot(_1276, _1340);\n    float _1347 = _1286.y;\n    if (_1344 < _1347)\n    {\n        return 1.0;\n    }\n    vec2 _1362 = vec2(dot(fa_light_texel(param_4), _1340), dot(fa_light_texel(param_5), _1340)) / vec2(_1344);\n    float _1364 = _1362.x;\n    bool _1367 = _1364 < _1281.x;\n    bool _1376;\n    if (!_1367)\n    {\n        _1376 = _1364 > _1281.z;\n    }\n    else\n    {\n        _1376 = _1367;\n    }\n    bool _1385;\n    if (!_1376)\n    {\n        _1385 = _1362.y < _1281.y;\n    }\n    else\n    {\n        _1385 = _1376;\n    }\n    bool _1394;\n    if (!_1385)\n    {\n        _1394 = _1362.y > _1281.w;\n    }\n    else\n    {\n        _1394 = _1385;\n    }\n    if (_1394)\n    {\n        return 1.0;\n    }\n    float _1400 = _1174.x;\n    float _1402;\n    if (_1400 > 0.0)\n    {\n        _1402 = _1400;\n    }\n    else\n    {\n        _1402 = 1.5 * _1298;\n    }\n    vec2 param_9 = _1362;\n    vec4 param_10 = _1281;\n    float param_11 = _1344 - (_1402 * (1.0 + (0.5 * _1315)));\n    float param_12 = _1298;\n    float param_13 = 1.0;\n    float param_14 = _1286.z * 0.25;\n    float param_15 = (_1298 * min(_1315, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1347, _1286.z);\n    int param_17 = int(_1169.z + 0.5);\n    float param_18 = _1169.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2848 = fa_light_sample(param, param_1);\n    vec3 _4109 = _2848.direction;\n    vec3 _4104 = _2848.color;\n    float _4111 = _2848.attenuation;\n    float _4106 = _2848.shadow;\n    int _4114 = _2848.type;\n    if ((_4114 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _4109;\n        float _2862 = fa_shadow_factor(param_2, param_3);\n        _4106 = _2862;\n        _4104 *= _2862;\n    }\n    else\n    {\n        bool _2873 = _4114 != 0;\n        bool _2879;\n        if (_2873)\n        {\n            _2879 = _4111 > 0.0;\n        }\n        else\n        {\n            _2879 = _2873;\n        }\n        if (_2879)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _4109;\n            float _2891 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _4106 = _2891;\n            _4104 *= _2891;\n        }\n    }\n    return LightSample(_4109, _4104, _4111, _4106, _2848._distance, _4114);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2463 = tdh / at;\n    float _2467 = bdh / ab;\n    float _2479 = ((_2463 * _2463) + (_2467 * _2467)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2479) * _2479);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2560 = 1.0 / alpha;\n    return ((2.0 + _2560) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2560)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2593 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2672 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2672) * _2672);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2593);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2593));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2745 = max(dot(L.nc, l), 0.0);\n        float _2751 = max(dot(L.nc, h), 0.0);\n        float _2760 = ((_2751 * _2751) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2760) * _2760)) * (0.5 / max(mix((2.0 * _2745) * L.coat_ndv, _2745 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2745)) * _2745);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1860 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1863 = _1860.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1863 * _1863, exp2((-9.27999973297119140625) * ndv)) * _1863) + _1860.y)) + _1860.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1765 = rough * rough;\n    float _1795 = 0.60000002384185791015625 * _1765;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1765)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1795, 0.0500000007450580596923828125 + _1795, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1765 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2346;\n        if (L.aniso >= 0.0)\n        {\n            _2346 = L.b;\n        }\n        else\n        {\n            _2346 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2346, v), _2346), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2379 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2379.x) + (vec3(L.f90) * _2379.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2434 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2434.x) + _2434.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1902 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1902.x) + vec3(_1902.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1652 = int(fa_shadows[25].x + 0.5);\n    float _1662 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1667 = _1652 > 0;\n    bool _1676;\n    if (_1667)\n    {\n        int param = _1652 - 1;\n        _1676 = _1662 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1676 = _1667;\n    }\n    if (_1676)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1683 = _1652 > 1;\n        bool _1690;\n        if (_1683)\n        {\n            _1690 = _1662 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1690 = _1683;\n        }\n        if (_1690)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1696 = _1652 > 2;\n        bool _1703;\n        if (_1696)\n        {\n            _1703 = _1662 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1703 = _1696;\n        }\n        if (_1703)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1709 = _1652 > 3;\n        bool _1716;\n        if (_1709)\n        {\n            _1716 = _1662 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1716 = _1709;\n        }\n        if (_1716)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3839 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3839 = -_3839;\n    }\n    vec3 _3293 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3839, fa_world_tangent, fa_uv, fa_vertex_color, _3293, gl_FrontFacing);\n    Surface _3301 = fa_standard_surface(param_1);\n    vec3 _3870 = _3301.albedo;\n    float _3871 = _3301.alpha;\n    vec3 _3872 = _3301.normal;\n    float _3873 = _3301.metallic;\n    float _3874 = _3301.roughness;\n    float _3875 = _3301.occlusion;\n    vec3 _3876 = _3301.emission;\n    float _3877 = _3301.clearcoat;\n    float _3878 = _3301.clearcoat_roughness;\n    vec3 _3879 = _3301.sheen_color;\n    float _3880 = _3301.sheen_roughness;\n    float _3881 = _3301.anisotropy;\n    float _3882 = _3301.anisotropy_rotation;\n    float _3883 = _3301.specular;\n    float _3884 = _3301.ior;\n    vec3 _3885 = _3301.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3839, fa_world_tangent, fa_uv, fa_vertex_color, _3293, gl_FrontFacing);\n    Surface param_3 = _3301;\n    surface(param_2, param_3);\n    _3870 = param_3.albedo;\n    _3871 = param_3.alpha;\n    _3872 = param_3.normal;\n    _3873 = param_3.metallic;\n    _3874 = param_3.roughness;\n    _3875 = param_3.occlusion;\n    _3876 = param_3.emission;\n    _3877 = param_3.clearcoat;\n    _3878 = param_3.clearcoat_roughness;\n    _3879 = param_3.sheen_color;\n    _3880 = param_3.sheen_roughness;\n    _3881 = param_3.anisotropy;\n    _3882 = param_3.anisotropy_rotation;\n    _3883 = param_3.specular;\n    _3884 = param_3.ior;\n    _3885 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3870;\n    }\n    else\n    {\n        vec3 _3323 = normalize(_3872);\n        float _3330 = clamp(_3873, 0.0, 1.0);\n        float _3334 = clamp(_3874, 0.0500000007450580596923828125, 1.0);\n        float _3338 = _3334 * _3334;\n        float _3342 = _3338 * _3338;\n        float _3347 = max(dot(_3323, _3293), 9.9999997473787516355514526367188e-05);\n        vec3 _3353 = _3870 * (1.0 - _3330);\n        vec3 _3360 = mix(vec3(0.039999999105930328369140625), _3870, vec3(_3330));\n        vec3 f0 = _3360;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3839, fa_world_tangent, fa_uv, fa_vertex_color, _3293, gl_FrontFacing);\n        Surface param_5 = Surface(_3870, _3871, _3872, _3873, _3874, _3875, _3876, _3877, _3878, _3879, _3880, _3881, _3882, _3883, _3884, _3885);\n        vec3 param_6 = _3323;\n        vec3 param_7 = _3293;\n        float param_8 = _3330;\n        float param_9 = _3334;\n        vec3 param_10 = _3360;\n        FaLayers _3376 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _3323;\n        vec3 lit = (fa_ambient_light(param_11) * _3353) * _3875;\n        if (_3376.on)\n        {\n            lit *= _3376.base_scale;\n        }\n        int _3398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3398; ln++)\n        {\n            int param_12 = ln;\n            int _3411 = fa_cl_light(param_12);\n            int param_13 = _3411;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _3839;\n            LightSample _3420 = fa_light_shadowed(param_13, param_14, param_15);\n            vec3 _4044 = _3420.direction;\n            float _3428 = max(dot(_3323, _4044), 0.0);\n            float _3434 = _3420.attenuation * _3420.shadow;\n            vec3 _3439 = normalize(_4044 + _3293);\n            float _3444 = max(dot(_3323, _3439), 0.0);\n            float _3449 = max(dot(_3293, _3439), 0.0);\n            if (_3376.on)\n            {\n                FaLayers param_16 = _3376;\n                vec3 param_17 = _3353;\n                vec3 param_18 = f0;\n                vec3 param_19 = _3323;\n                vec3 param_20 = _3293;\n                vec3 param_21 = _4044;\n                vec3 param_22 = _3439;\n                float param_23 = _3428;\n                float param_24 = _3347;\n                float param_25 = _3444;\n                float param_26 = _3449;\n                float param_27 = _3338;\n                float param_28 = _3342;\n                int param_29 = _3411;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _3434));\n            }\n            else\n            {\n                float _3497 = ((_3444 * _3444) * (_3342 - 1.0)) + 1.0;\n                int param_30 = _3411;\n                lit += (((_3353 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3449, 5.0))) * (((_3342 / ((3.1415927410125732421875 * _3497) * _3497)) * (0.5 / max(mix((2.0 * _3428) * _3347, _3428 + _3347, _3338), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3428))) * fa_light_rgb(param_30)) * (_3428 * _3434));\n            }\n        }\n        if (_3376.on)\n        {\n            FaLayers param_31 = _3376;\n            vec3 param_32 = _3323;\n            vec3 param_33 = _3293;\n            vec3 param_34 = f0;\n            float param_35 = _3334;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3875);\n        }\n        else\n        {\n            vec3 param_36 = _3323;\n            vec3 param_37 = _3293;\n            vec3 param_38 = f0;\n            float param_39 = _3334;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3875);\n        }\n        result = lit;\n    }\n    vec3 _3590 = result;\n    vec3 _3591 = _3590 + _3876;\n    result = _3591;\n    vec3 param_40 = _3591;\n    vec3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3600 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3607;\n    if (!_3600)\n    {\n        _3607 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3607 = _3600;\n    }\n    if (_3607)\n    {\n        vec3 _3616 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3622 = dot(_3616, fa_mesh_fs_params[9].xyz);\n        bool _3626 = fa_mesh_fs_params[9].w > 0.5;\n        float _3627;\n        if (_3626)\n        {\n            _3627 = _3622;\n        }\n        else\n        {\n            _3627 = length(_3616);\n        }\n        float _3639 = _3627 - fa_mesh_fs_params[8].x;\n        if (_3639 > 0.0)\n        {\n            float _3648 = fa_mesh_fs_params[7].w * _3639;\n            float tau = _3648 * _3648;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3664;\n                if (_3626)\n                {\n                    _3664 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3622);\n                }\n                else\n                {\n                    _3664 = fa_mesh_fs_params[0].y;\n                }\n                float _3685 = mix(_3664, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3627, 0.0, 1.0));\n                float _3689 = fa_world_pos.y - _3685;\n                float _3694 = _3685 - fa_mesh_fs_params[8].z;\n                float _3699 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3702 = _3694 <= 0.0;\n                bool _3703 = !_3702;\n                bool _3709;\n                if (_3703)\n                {\n                    _3709 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3709 = _3702;\n                }\n                float _3710;\n                if (_3709)\n                {\n                    _3710 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3710 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3694, 80.0));\n                }\n                bool _3737;\n                if (_3703)\n                {\n                    _3737 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3737 = _3702;\n                }\n                float _3738;\n                if (_3737)\n                {\n                    _3738 = fa_mesh_fs_params[8].y * _3694;\n                }\n                else\n                {\n                    _3738 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3694, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3763 = _3699 <= 0.0;\n                bool _3770;\n                if (!_3763)\n                {\n                    _3770 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3770 = _3763;\n                }\n                float _3771;\n                if (_3770)\n                {\n                    _3771 = fa_mesh_fs_params[8].y * _3699;\n                }\n                else\n                {\n                    _3771 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3699, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3798;\n                if (abs(_3689) < 0.001000000047497451305389404296875)\n                {\n                    _3798 = _3710;\n                }\n                else\n                {\n                    _3798 = (_3771 - _3738) / _3689;\n                }\n                tau += (_3639 * max(_3798, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3871);\n}\n\n",
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
            "inst_name": "_490",
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
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_726",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2916",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2003[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _495 = fa_mesh_fs_params[19].x < 0.0;\n    bool _502;\n    if (!_495)\n    {\n        _502 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _502 = _495;\n    }\n    bool _510;\n    if (!_502)\n    {\n        _510 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _510 = _502;\n    }\n    bool _517;\n    if (!_510)\n    {\n        _517 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _517 = _510;\n    }\n    bool _524;\n    if (!_517)\n    {\n        _524 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _524 = _517;\n    }\n    if (_524)\n    {\n        return ivec2(0);\n    }\n    vec4 _534 = vec4(world_pos, 1.0);\n    float _541 = dot(fa_mesh_fs_params[16], _534);\n    if (!(_541 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _563 = vec2(dot(fa_mesh_fs_params[14], _534), dot(fa_mesh_fs_params[15], _534)) / vec2(_541);\n    int _567 = int(fa_mesh_fs_params[18].x);\n    int _571 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _571) + clamp(int(floor(((_563.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _571 - 1)) * _567)) + clamp(int(floor(((_563.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _567 - 1);\n    vec4 _642 = fa_light_texel(param);\n    return ivec2(int(_642.x), int(_642.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2820 = fa_cluster_lookup(param);\n    fa_cl_slot = _2820.x;\n    fa_cl_local = _2820.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2980 = fa_linear_to_srgb(param);\n        c = _2980;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2988 = fa_srgb_to_linear(param_1);\n            c = _2988;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _262;\n    if (i.front_facing)\n    {\n        _262 = i.world_normal;\n    }\n    else\n    {\n        _262 = -i.world_normal;\n    }\n    vec3 _286 = normalize(i.world_tangent.xyz - (_262 * dot(_262, i.world_tangent.xyz)));\n    vec3 _314 = normalize(((_286 * m.x) + ((cross(_262, _286) * i.world_tangent.w) * m.y)) + (_262 * m.z));\n    vec3 _317;\n    if (i.front_facing)\n    {\n        _317 = _314;\n    }\n    else\n    {\n        _317 = -_314;\n    }\n    return _317;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3019 = fa_tex_fix(param_2, param_3);\n    vec4 _4222 = base_t;\n    _4222.x = _3019.x;\n    _4222.y = _3019.y;\n    _4222.z = _3019.z;\n    base_t = _4222;\n    vec4 _3033 = (_4222 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4124 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3065 = fa_tex_fix(param_6, param_7);\n        vec3 _3068 = (_3065 * 2.0) - vec3(1.0);\n        vec2 _3073 = _3068.xy * fa_mesh_fs_params[6].x;\n        vec3 _4230 = _3068;\n        _4230.x = _3073.x;\n        _4230.y = _3073.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4230;\n        _4124 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3102 = fa_tex_fix(param_12, param_13);\n    vec4 _4233 = mrt;\n    _4233.x = _3102.x;\n    _4233.y = _3102.y;\n    _4233.z = _3102.z;\n    mrt = _4233;\n    vec4 _3130 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3130.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3142 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3172 = fa_tex_fix(param_20, param_21);\n    float _4129 = fa_mesh_fs_params[20].x;\n    float _4130 = fa_mesh_fs_params[20].y;\n    float _4133 = fa_mesh_fs_params[20].z;\n    float _4132 = fa_mesh_fs_params[21].w;\n    float _4135 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4129 *= _3142.y;\n            _4130 *= _3142.z;\n            _4132 *= _3130.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4133 *= mrt.x;\n            _4135 *= mrt.w;\n        }\n    }\n    return Surface(_3033.xyz, _3033.w, _4124, clamp(fa_mesh_fs_params[5].x * _3102.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3102.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3142.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3172), _4129, _4130, fa_mesh_fs_params[21].xyz, _4132, _4133, fa_mesh_fs_params[20].w, _4135, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1928 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1936 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1939 = int(_1928);\n    int _1942 = int(_1936);\n    float _1952 = _1936 - float(_1942);\n    int _2008 = (_1939 * 9) + _1942;\n    int _2028 = ((_1939 + 1) * 9) + _1942;\n    return mix(mix(_2003[_2008], _2003[_2008 + 1], _1952), mix(_2003[_2028], _2003[_2028 + 1], _1952), _1928 - float(_1939));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4060 = false;\n    float _4061 = 1.0;\n    float _4062 = 1.0;\n    float _4063 = 1.0;\n    float _4064 = 0.0;\n    float _4065 = 0.0;\n    float _4066 = 0.0;\n    float _4067 = 0.0;\n    float _4069 = 1.0;\n    bool _4070 = false;\n    vec3 _4071 = vec3(0.0);\n    float _4072 = 1.0;\n    float _4073 = 1.0;\n    float _4074 = 1.0;\n    float _4075 = 0.0;\n    float _4076 = 0.0;\n    vec3 _4077 = vec3(1.0, 0.0, 0.0);\n    vec3 _4078 = vec3(0.0, 0.0, 1.0);\n    float _4079 = 1.0;\n    float _4080 = 1.0;\n    float _2081 = clamp(s.specular, 0.0, 1.0);\n    float _2085 = clamp(s.ior, 1.0, 3.0);\n    bool _2090 = (_2081 != 1.0) || (_2085 != 1.5);\n    bool _2100;\n    if (!_2090)\n    {\n        _2100 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2100 = _2090;\n    }\n    if (_2100)\n    {\n        float _2108 = (_2085 - 1.0) / (_2085 + 1.0);\n        f0 = mix(min(vec3(_2108 * _2108) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2081, s.albedo, vec3(metallic));\n        _4061 = mix(_2081, 1.0, metallic);\n        _4060 = true;\n    }\n    float _2136 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2136 > 0.0)\n    {\n        float _2144 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4064 = _2136;\n        _4065 = _2144;\n        float _2151 = _2144 * _2144;\n        _4066 = _2151;\n        _4067 = _2151 * _2151;\n        float _2163 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4069 = _2163;\n        _4062 = 1.0 - (_2136 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2163, 0.0, 1.0), 5.0))));\n        _4060 = true;\n    }\n    vec3 _2183 = max(s.sheen_color, vec3(0.0));\n    float _2192 = max(_2183.x, max(_2183.y, _2183.z));\n    if (_2192 > 0.0)\n    {\n        float _2200 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4070 = true;\n        _4071 = _2183;\n        _4072 = _2200;\n        _4073 = _2200 * _2200;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2200;\n        float _2217 = fa_sheen_albedo(param, param_1);\n        _4075 = _2217;\n        _4074 = 1.0 - min(_2192 * _2217, 1.0);\n        _4060 = true;\n    }\n    _4063 = _4062 * _4074;\n    float _2236 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2236 != 0.0)\n    {\n        vec3 _2251 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2251;\n        if (dot(_2251, _2251) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2265 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2265.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2265.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2265.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2269 = t;\n        vec3 _2270 = normalize(_2269);\n        t = _2270;\n        vec3 _2295 = normalize((_2270 * cos(s.anisotropy_rotation)) + ((cross(n, _2270) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4077 = _2295;\n        _4078 = cross(n, _2295);\n        float _2305 = roughness * roughness;\n        float _2311 = mix(_2305, 1.0, _2236 * _2236);\n        bool _2313 = _2236 > 0.0;\n        _4079 = _2313 ? _2311 : _2305;\n        _4080 = _2313 ? _2305 : _2311;\n        _4076 = _2236;\n        _4060 = true;\n    }\n    return FaLayers(_4060, _4061, _4062, _4063, _4064, _4065, _4066, _4067, i.world_normal, _4069, _4070, _4071, _4072, _4073, _4074, _4075, _4076, _4077, _4078, _4079, _4080);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _362 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _368 = fa_light_texel(param_1);\n    float _371 = _368.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _378 = _371 < 0.5;\n    vec3 l;\n    if (_378)\n    {\n        l = normalize(_362.xyz);\n    }\n    else\n    {\n        vec3 _390 = _362.xyz - world_pos;\n        float _392 = length(_390);\n        dist = _392;\n        l = _390 / vec3(max(_392, 9.9999997473787516355514526367188e-05));\n        float _407 = _392 / max(_362.w, 0.001000000047497451305389404296875);\n        float _413 = clamp(1.0 - (_407 * _407), 0.0, 1.0);\n        atten = _413 * _413;\n        if (_371 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _427 = fa_light_texel(param_2);\n            float _437 = _427.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _444 = fa_light_texel(param_3);\n            float _445 = _444.x;\n            float cos_inner = _445;\n            if (_445 > 1.5)\n            {\n                cos_inner = mix(_437, 1.0, 0.25);\n            }\n            atten *= smoothstep(_437, cos_inner, dot(-l, normalize(_427.xyz)));\n        }\n    }\n    int _476;\n    if (_378)\n    {\n        _476 = 0;\n    }\n    else\n    {\n        _476 = (_371 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _368.xyz * atten, atten, 1.0, dist, _476);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _716;\n    if (i == 0)\n    {\n        _716 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _732;\n        if (i == 1)\n        {\n            _732 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _740;\n            if (i == 2)\n            {\n                _740 = fa_shadows[24].z;\n            }\n            else\n            {\n                _740 = fa_shadows[24].w;\n            }\n            _732 = _740;\n        }\n        _716 = _732;\n    }\n    return _716;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _773 = fa_shadow_depth(param, param_1);\n    float _777;\n    if (conv.x < 0.5)\n    {\n        _777 = _773;\n    }\n    else\n    {\n        _777 = (conv.y * conv.z) / (conv.z - (_773 * (conv.z - conv.y)));\n    }\n    return _777;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _704 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_704), sin(_704)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _823 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _837 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _823;\n            vec2 _856 = fa_shadow_vogel(param_3, param_4, param_5) * _837;\n            vec2 param_6 = uv + (_856 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _868 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_868 < (zr - (length(_856) * plane)))\n            {\n                sum += _868;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _912 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _912; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _912;\n        float param_11 = _823;\n        vec2 _931 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_931 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_931) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_912);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _973 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _978 = clamp(dot(n, l), 0.0, 1.0);\n    float _984 = sqrt(1.0 - (_978 * _978));\n    float _992 = min(_984 / max(_978, 0.20000000298023223876953125), 4.0);\n    float _997;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _997 = fa_shadows[26].y;\n    }\n    else\n    {\n        _997 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1022 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_997 * _984)), 1.0);\n    float _1029 = _1022.x;\n    bool _1032 = _1029 < fa_shadows[ci * 1 + 16].x;\n    bool _1041;\n    if (!_1032)\n    {\n        _1041 = _1029 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1041 = _1032;\n    }\n    bool _1050;\n    if (!_1041)\n    {\n        _1050 = _1022.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1050 = _1041;\n    }\n    bool _1059;\n    if (!_1050)\n    {\n        _1059 = _1022.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1059 = _1050;\n    }\n    bool _1066;\n    if (!_1059)\n    {\n        _1066 = _1022.z > 1.0;\n    }\n    else\n    {\n        _1066 = _1059;\n    }\n    if (_1066)\n    {\n        return -1.0;\n    }\n    float _1075;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1075 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1075 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1022.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1022.z - ((_1075 * (1.0 + (0.5 * _992))) / _973);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _973;\n    float param_5 = _973 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_992, 3.0)) * 0.5) / _973;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1469 = int(fa_shadows[25].x + 0.5);\n    if (_1469 < 1)\n    {\n        return 1.0;\n    }\n    float _1485 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1469 - 1;\n    if (_1485 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1497 = _1469 > 1;\n    bool _1504;\n    if (_1497)\n    {\n        _1504 = _1485 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1504 = _1497;\n    }\n    if (_1504)\n    {\n        ci = 1;\n    }\n    bool _1508 = _1469 > 2;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1485 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 2;\n    }\n    bool _1519 = _1469 > 3;\n    bool _1526;\n    if (_1519)\n    {\n        _1526 = _1485 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    if (_1526)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1469)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1552 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1552;\n        if (_1552 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1577;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1577 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1577 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1596 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1577, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1607 = clamp((_1485 - (fa_shadow_split_at(param_7) - _1596)) / _1596, 0.0, 1.0);\n        if (_1607 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1469)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1628 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1628;\n                if (_1628 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1607);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1134 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1142;\n    if (!_1134)\n    {\n        _1142 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1142 = _1134;\n    }\n    if (_1142)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1155 = fa_light_texel(param);\n    float _1156 = _1155.x;\n    if (_1156 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1165 = int(_1156 + 0.5);\n    int param_1 = _1165;\n    vec4 _1169 = fa_light_texel(param_1);\n    int param_2 = _1165 + 1;\n    vec4 _1174 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1177 = _1169.y;\n    if (_1177 > 0.0)\n    {\n        float _1194 = 1.0 - smoothstep(0.75 * _1177, _1177, length(world - fa_shadows[27].xyz));\n        fade = _1194;\n        if (_1194 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1169.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1213 = world - fa_light_texel(param_3).xyz;\n        vec3 _1216 = abs(_1213);\n        float _1218 = _1216.x;\n        float _1220 = _1216.y;\n        bool _1221 = _1218 >= _1220;\n        bool _1229;\n        if (_1221)\n        {\n            _1229 = _1218 >= _1216.z;\n        }\n        else\n        {\n            _1229 = _1221;\n        }\n        int _1230;\n        if (_1229)\n        {\n            _1230 = (_1213.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1243;\n            if (_1220 >= _1216.z)\n            {\n                _1243 = (_1213.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1243 = (_1213.z > 0.0) ? 4 : 5;\n            }\n            _1230 = _1243;\n        }\n        face = _1230;\n    }\n    int _1262 = (_1165 + 2) + (face * 6);\n    int param_4 = _1262;\n    int param_5 = _1262 + 1;\n    int param_6 = _1262 + 3;\n    vec4 _1276 = fa_light_texel(param_6);\n    int param_7 = _1262 + 4;\n    vec4 _1281 = fa_light_texel(param_7);\n    int param_8 = _1262 + 5;\n    vec4 _1286 = fa_light_texel(param_8);\n    float _1298 = _1286.x * max(dot(_1276, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1303 = clamp(dot(n, l), 0.0, 1.0);\n    float _1309 = sqrt(1.0 - (_1303 * _1303));\n    float _1315 = min(_1309 / max(_1303, 0.20000000298023223876953125), 4.0);\n    float _1318 = _1174.y;\n    float _1320;\n    if (_1318 > 0.0)\n    {\n        _1320 = _1318;\n    }\n    else\n    {\n        _1320 = 1.5 * _1298;\n    }\n    vec4 _1340 = vec4(world + (n * (_1320 * _1309)), 1.0);\n    float _1344 = dot(_1276, _1340);\n    float _1347 = _1286.y;\n    if (_1344 < _1347)\n    {\n        return 1.0;\n    }\n    vec2 _1362 = vec2(dot(fa_light_texel(param_4), _1340), dot(fa_light_texel(param_5), _1340)) / vec2(_1344);\n    float _1364 = _1362.x;\n    bool _1367 = _1364 < _1281.x;\n    bool _1376;\n    if (!_1367)\n    {\n        _1376 = _1364 > _1281.z;\n    }\n    else\n    {\n        _1376 = _1367;\n    }\n    bool _1385;\n    if (!_1376)\n    {\n        _1385 = _1362.y < _1281.y;\n    }\n    else\n    {\n        _1385 = _1376;\n    }\n    bool _1394;\n    if (!_1385)\n    {\n        _1394 = _1362.y > _1281.w;\n    }\n    else\n    {\n        _1394 = _1385;\n    }\n    if (_1394)\n    {\n        return 1.0;\n    }\n    float _1400 = _1174.x;\n    float _1402;\n    if (_1400 > 0.0)\n    {\n        _1402 = _1400;\n    }\n    else\n    {\n        _1402 = 1.5 * _1298;\n    }\n    vec2 param_9 = _1362;\n    vec4 param_10 = _1281;\n    float param_11 = _1344 - (_1402 * (1.0 + (0.5 * _1315)));\n    float param_12 = _1298;\n    float param_13 = 1.0;\n    float param_14 = _1286.z * 0.25;\n    float param_15 = (_1298 * min(_1315, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1347, _1286.z);\n    int param_17 = int(_1169.z + 0.5);\n    float param_18 = _1169.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2848 = fa_light_sample(param, param_1);\n    vec3 _4109 = _2848.direction;\n    vec3 _4104 = _2848.color;\n    float _4111 = _2848.attenuation;\n    float _4106 = _2848.shadow;\n    int _4114 = _2848.type;\n    if ((_4114 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _4109;\n        float _2862 = fa_shadow_factor(param_2, param_3);\n        _4106 = _2862;\n        _4104 *= _2862;\n    }\n    else\n    {\n        bool _2873 = _4114 != 0;\n        bool _2879;\n        if (_2873)\n        {\n            _2879 = _4111 > 0.0;\n        }\n        else\n        {\n            _2879 = _2873;\n        }\n        if (_2879)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _4109;\n            float _2891 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _4106 = _2891;\n            _4104 *= _2891;\n        }\n    }\n    return LightSample(_4109, _4104, _4111, _4106, _2848._distance, _4114);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2463 = tdh / at;\n    float _2467 = bdh / ab;\n    float _2479 = ((_2463 * _2463) + (_2467 * _2467)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2479) * _2479);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2560 = 1.0 / alpha;\n    return ((2.0 + _2560) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2560)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2593 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2672 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2672) * _2672);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2593);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2593));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2745 = max(dot(L.nc, l), 0.0);\n        float _2751 = max(dot(L.nc, h), 0.0);\n        float _2760 = ((_2751 * _2751) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2760) * _2760)) * (0.5 / max(mix((2.0 * _2745) * L.coat_ndv, _2745 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2745)) * _2745);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1860 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1863 = _1860.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1863 * _1863, exp2((-9.27999973297119140625) * ndv)) * _1863) + _1860.y)) + _1860.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1765 = rough * rough;\n    float _1795 = 0.60000002384185791015625 * _1765;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1765)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1795, 0.0500000007450580596923828125 + _1795, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1765 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2346;\n        if (L.aniso >= 0.0)\n        {\n            _2346 = L.b;\n        }\n        else\n        {\n            _2346 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2346, v), _2346), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2379 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2379.x) + (vec3(L.f90) * _2379.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2434 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2434.x) + _2434.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1902 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1902.x) + vec3(_1902.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1652 = int(fa_shadows[25].x + 0.5);\n    float _1662 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1667 = _1652 > 0;\n    bool _1676;\n    if (_1667)\n    {\n        int param = _1652 - 1;\n        _1676 = _1662 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1676 = _1667;\n    }\n    if (_1676)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1683 = _1652 > 1;\n        bool _1690;\n        if (_1683)\n        {\n            _1690 = _1662 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1690 = _1683;\n        }\n        if (_1690)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1696 = _1652 > 2;\n        bool _1703;\n        if (_1696)\n        {\n            _1703 = _1662 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1703 = _1696;\n        }\n        if (_1703)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1709 = _1652 > 3;\n        bool _1716;\n        if (_1709)\n        {\n            _1716 = _1662 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1716 = _1709;\n        }\n        if (_1716)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3839 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3839 = -_3839;\n    }\n    vec3 _3293 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3839, fa_world_tangent, fa_uv, fa_vertex_color, _3293, gl_FrontFacing);\n    Surface _3301 = fa_standard_surface(param_1);\n    vec3 _3870 = _3301.albedo;\n    float _3871 = _3301.alpha;\n    vec3 _3872 = _3301.normal;\n    float _3873 = _3301.metallic;\n    float _3874 = _3301.roughness;\n    float _3875 = _3301.occlusion;\n    vec3 _3876 = _3301.emission;\n    float _3877 = _3301.clearcoat;\n    float _3878 = _3301.clearcoat_roughness;\n    vec3 _3879 = _3301.sheen_color;\n    float _3880 = _3301.sheen_roughness;\n    float _3881 = _3301.anisotropy;\n    float _3882 = _3301.anisotropy_rotation;\n    float _3883 = _3301.specular;\n    float _3884 = _3301.ior;\n    vec3 _3885 = _3301.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3839, fa_world_tangent, fa_uv, fa_vertex_color, _3293, gl_FrontFacing);\n    Surface param_3 = _3301;\n    surface(param_2, param_3);\n    _3870 = param_3.albedo;\n    _3871 = param_3.alpha;\n    _3872 = param_3.normal;\n    _3873 = param_3.metallic;\n    _3874 = param_3.roughness;\n    _3875 = param_3.occlusion;\n    _3876 = param_3.emission;\n    _3877 = param_3.clearcoat;\n    _3878 = param_3.clearcoat_roughness;\n    _3879 = param_3.sheen_color;\n    _3880 = param_3.sheen_roughness;\n    _3881 = param_3.anisotropy;\n    _3882 = param_3.anisotropy_rotation;\n    _3883 = param_3.specular;\n    _3884 = param_3.ior;\n    _3885 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3870;\n    }\n    else\n    {\n        vec3 _3323 = normalize(_3872);\n        float _3330 = clamp(_3873, 0.0, 1.0);\n        float _3334 = clamp(_3874, 0.0500000007450580596923828125, 1.0);\n        float _3338 = _3334 * _3334;\n        float _3342 = _3338 * _3338;\n        float _3347 = max(dot(_3323, _3293), 9.9999997473787516355514526367188e-05);\n        vec3 _3353 = _3870 * (1.0 - _3330);\n        vec3 _3360 = mix(vec3(0.039999999105930328369140625), _3870, vec3(_3330));\n        vec3 f0 = _3360;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3839, fa_world_tangent, fa_uv, fa_vertex_color, _3293, gl_FrontFacing);\n        Surface param_5 = Surface(_3870, _3871, _3872, _3873, _3874, _3875, _3876, _3877, _3878, _3879, _3880, _3881, _3882, _3883, _3884, _3885);\n        vec3 param_6 = _3323;\n        vec3 param_7 = _3293;\n        float param_8 = _3330;\n        float param_9 = _3334;\n        vec3 param_10 = _3360;\n        FaLayers _3376 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _3323;\n        vec3 lit = (fa_ambient_light(param_11) * _3353) * _3875;\n        if (_3376.on)\n        {\n            lit *= _3376.base_scale;\n        }\n        int _3398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3398; ln++)\n        {\n            int param_12 = ln;\n            int _3411 = fa_cl_light(param_12);\n            int param_13 = _3411;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _3839;\n            LightSample _3420 = fa_light_shadowed(param_13, param_14, param_15);\n            vec3 _4044 = _3420.direction;\n            float _3428 = max(dot(_3323, _4044), 0.0);\n            float _3434 = _3420.attenuation * _3420.shadow;\n            vec3 _3439 = normalize(_4044 + _3293);\n            float _3444 = max(dot(_3323, _3439), 0.0);\n            float _3449 = max(dot(_3293, _3439), 0.0);\n            if (_3376.on)\n            {\n                FaLayers param_16 = _3376;\n                vec3 param_17 = _3353;\n                vec3 param_18 = f0;\n                vec3 param_19 = _3323;\n                vec3 param_20 = _3293;\n                vec3 param_21 = _4044;\n                vec3 param_22 = _3439;\n                float param_23 = _3428;\n                float param_24 = _3347;\n                float param_25 = _3444;\n                float param_26 = _3449;\n                float param_27 = _3338;\n                float param_28 = _3342;\n                int param_29 = _3411;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _3434));\n            }\n            else\n            {\n                float _3497 = ((_3444 * _3444) * (_3342 - 1.0)) + 1.0;\n                int param_30 = _3411;\n                lit += (((_3353 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3449, 5.0))) * (((_3342 / ((3.1415927410125732421875 * _3497) * _3497)) * (0.5 / max(mix((2.0 * _3428) * _3347, _3428 + _3347, _3338), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3428))) * fa_light_rgb(param_30)) * (_3428 * _3434));\n            }\n        }\n        if (_3376.on)\n        {\n            FaLayers param_31 = _3376;\n            vec3 param_32 = _3323;\n            vec3 param_33 = _3293;\n            vec3 param_34 = f0;\n            float param_35 = _3334;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3875);\n        }\n        else\n        {\n            vec3 param_36 = _3323;\n            vec3 param_37 = _3293;\n            vec3 param_38 = f0;\n            float param_39 = _3334;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3875);\n        }\n        result = lit;\n    }\n    vec3 _3590 = result;\n    vec3 _3591 = _3590 + _3876;\n    result = _3591;\n    vec3 param_40 = _3591;\n    vec3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3600 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3607;\n    if (!_3600)\n    {\n        _3607 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3607 = _3600;\n    }\n    if (_3607)\n    {\n        vec3 _3616 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3622 = dot(_3616, fa_mesh_fs_params[9].xyz);\n        bool _3626 = fa_mesh_fs_params[9].w > 0.5;\n        float _3627;\n        if (_3626)\n        {\n            _3627 = _3622;\n        }\n        else\n        {\n            _3627 = length(_3616);\n        }\n        float _3639 = _3627 - fa_mesh_fs_params[8].x;\n        if (_3639 > 0.0)\n        {\n            float _3648 = fa_mesh_fs_params[7].w * _3639;\n            float tau = _3648 * _3648;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3664;\n                if (_3626)\n                {\n                    _3664 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3622);\n                }\n                else\n                {\n                    _3664 = fa_mesh_fs_params[0].y;\n                }\n                float _3685 = mix(_3664, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3627, 0.0, 1.0));\n                float _3689 = fa_world_pos.y - _3685;\n                float _3694 = _3685 - fa_mesh_fs_params[8].z;\n                float _3699 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3702 = _3694 <= 0.0;\n                bool _3703 = !_3702;\n                bool _3709;\n                if (_3703)\n                {\n                    _3709 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3709 = _3702;\n                }\n                float _3710;\n                if (_3709)\n                {\n                    _3710 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3710 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3694, 80.0));\n                }\n                bool _3737;\n                if (_3703)\n                {\n                    _3737 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3737 = _3702;\n                }\n                float _3738;\n                if (_3737)\n                {\n                    _3738 = fa_mesh_fs_params[8].y * _3694;\n                }\n                else\n                {\n                    _3738 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3694, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3763 = _3699 <= 0.0;\n                bool _3770;\n                if (!_3763)\n                {\n                    _3770 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3770 = _3763;\n                }\n                float _3771;\n                if (_3770)\n                {\n                    _3771 = fa_mesh_fs_params[8].y * _3699;\n                }\n                else\n                {\n                    _3771 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3699, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3798;\n                if (abs(_3689) < 0.001000000047497451305389404296875)\n                {\n                    _3798 = _3710;\n                }\n                else\n                {\n                    _3798 = (_3771 - _3738) / _3689;\n                }\n                tau += (_3639 * max(_3798, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3871);\n}\n\n",
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
            "inst_name": "_490",
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
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_726",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2916",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    vec4 _280 = (_770 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _733 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = fa_mesh_fs_params[20].x;\n    float _739 = fa_mesh_fs_params[20].y;\n    float _742 = fa_mesh_fs_params[20].z;\n    float _741 = fa_mesh_fs_params[21].w;\n    float _744 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _733, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _738, _739, fa_mesh_fs_params[21].xyz, _741, _742, fa_mesh_fs_params[20].w, _744, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    vec4 _280 = (_770 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _733 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = fa_mesh_fs_params[20].x;\n    float _739 = fa_mesh_fs_params[20].y;\n    float _742 = fa_mesh_fs_params[20].z;\n    float _741 = fa_mesh_fs_params[21].w;\n    float _744 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _733, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _738, _739, fa_mesh_fs_params[21].xyz, _741, _742, fa_mesh_fs_params[20].w, _744, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
