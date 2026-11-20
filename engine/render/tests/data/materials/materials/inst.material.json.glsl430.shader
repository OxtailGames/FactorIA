{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2064[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _522 = fa_mesh_fs_params[19].x < 0.0;\n    bool _529;\n    if (!_522)\n    {\n        _529 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _529 = _522;\n    }\n    bool _537;\n    if (!_529)\n    {\n        _537 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _537 = _529;\n    }\n    bool _544;\n    if (!_537)\n    {\n        _544 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _544 = _537;\n    }\n    bool _551;\n    if (!_544)\n    {\n        _551 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _551 = _544;\n    }\n    if (_551)\n    {\n        return ivec2(0);\n    }\n    vec4 _561 = vec4(world_pos, 1.0);\n    float _568 = dot(fa_mesh_fs_params[16], _561);\n    if (!(_568 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _590 = vec2(dot(fa_mesh_fs_params[14], _561), dot(fa_mesh_fs_params[15], _561)) / vec2(_568);\n    int _594 = int(fa_mesh_fs_params[18].x);\n    int _598 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _598) + clamp(int(floor(((_590.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _598 - 1)) * _594)) + clamp(int(floor(((_590.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _594 - 1);\n    vec4 _669 = fa_light_texel(param);\n    return ivec2(int(_669.x), int(_669.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2881 = fa_cluster_lookup(param);\n    fa_cl_slot = _2881.x;\n    fa_cl_local = _2881.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3068 = fa_linear_to_srgb(param);\n        c = _3068;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3076 = fa_srgb_to_linear(param_1);\n            c = _3076;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _272;\n    if (i.front_facing)\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    vec3 _296 = normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    vec3 _324 = normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    vec3 _327;\n    if (i.front_facing)\n    {\n        _327 = _324;\n    }\n    else\n    {\n        _327 = -_324;\n    }\n    return _327;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3107 = fa_tex_fix(param_2, param_3);\n    vec4 _4354 = base_t;\n    _4354.x = _3107.x;\n    _4354.y = _3107.y;\n    _4354.z = _3107.z;\n    base_t = _4354;\n    vec4 _3121 = (_4354 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4256 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3153 = fa_tex_fix(param_6, param_7);\n        vec3 _3156 = (_3153 * 2.0) - vec3(1.0);\n        vec2 _3161 = _3156.xy * fa_mesh_fs_params[6].x;\n        vec3 _4362 = _3156;\n        _4362.x = _3161.x;\n        _4362.y = _3161.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4362;\n        _4256 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3190 = fa_tex_fix(param_12, param_13);\n    vec4 _4365 = mrt;\n    _4365.x = _3190.x;\n    _4365.y = _3190.y;\n    _4365.z = _3190.z;\n    mrt = _4365;\n    vec4 _3218 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3230 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3260 = fa_tex_fix(param_20, param_21);\n    float _4261 = fa_mesh_fs_params[20].x;\n    float _4262 = fa_mesh_fs_params[20].y;\n    float _4265 = fa_mesh_fs_params[20].z;\n    float _4264 = fa_mesh_fs_params[21].w;\n    float _4267 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4261 *= _3230.y;\n            _4262 *= _3230.z;\n            _4264 *= _3218.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4265 *= mrt.x;\n            _4267 *= mrt.w;\n        }\n    }\n    return Surface(_3121.xyz, _3121.w, _4256, clamp(fa_mesh_fs_params[5].x * _3190.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3190.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3230.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3260), _4261, _4262, fa_mesh_fs_params[21].xyz, _4264, _4265, fa_mesh_fs_params[20].w, _4267, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1989 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1997 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2000 = int(_1989);\n    int _2003 = int(_1997);\n    float _2013 = _1997 - float(_2003);\n    int _2069 = (_2000 * 9) + _2003;\n    int _2089 = ((_2000 + 1) * 9) + _2003;\n    return mix(mix(_2064[_2069], _2064[_2069 + 1], _2013), mix(_2064[_2089], _2064[_2089 + 1], _2013), _1989 - float(_2000));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4179 = false;\n    float _4180 = 1.0;\n    float _4181 = 1.0;\n    float _4182 = 1.0;\n    float _4183 = 0.0;\n    float _4184 = 0.0;\n    float _4185 = 0.0;\n    float _4186 = 0.0;\n    float _4188 = 1.0;\n    bool _4189 = false;\n    vec3 _4190 = vec3(0.0);\n    float _4191 = 1.0;\n    float _4192 = 1.0;\n    float _4193 = 1.0;\n    float _4194 = 0.0;\n    float _4195 = 0.0;\n    vec3 _4196 = vec3(1.0, 0.0, 0.0);\n    vec3 _4197 = vec3(0.0, 0.0, 1.0);\n    float _4198 = 1.0;\n    float _4199 = 1.0;\n    float _2142 = clamp(s.specular, 0.0, 1.0);\n    float _2146 = clamp(s.ior, 1.0, 3.0);\n    bool _2151 = (_2142 != 1.0) || (_2146 != 1.5);\n    bool _2161;\n    if (!_2151)\n    {\n        _2161 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2161 = _2151;\n    }\n    if (_2161)\n    {\n        float _2169 = (_2146 - 1.0) / (_2146 + 1.0);\n        f0 = mix(min(vec3(_2169 * _2169) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2142, s.albedo, vec3(metallic));\n        _4180 = mix(_2142, 1.0, metallic);\n        _4179 = true;\n    }\n    float _2197 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2197 > 0.0)\n    {\n        float _2205 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4183 = _2197;\n        _4184 = _2205;\n        float _2212 = _2205 * _2205;\n        _4185 = _2212;\n        _4186 = _2212 * _2212;\n        float _2224 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4188 = _2224;\n        _4181 = 1.0 - (_2197 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2224, 0.0, 1.0), 5.0))));\n        _4179 = true;\n    }\n    vec3 _2244 = max(s.sheen_color, vec3(0.0));\n    float _2253 = max(_2244.x, max(_2244.y, _2244.z));\n    if (_2253 > 0.0)\n    {\n        float _2261 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4189 = true;\n        _4190 = _2244;\n        _4191 = _2261;\n        _4192 = _2261 * _2261;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2261;\n        float _2278 = fa_sheen_albedo(param, param_1);\n        _4194 = _2278;\n        _4193 = 1.0 - min(_2253 * _2278, 1.0);\n        _4179 = true;\n    }\n    _4182 = _4181 * _4193;\n    float _2297 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2297 != 0.0)\n    {\n        vec3 _2312 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2312;\n        if (dot(_2312, _2312) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2326 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2326.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2326.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2326.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2330 = t;\n        vec3 _2331 = normalize(_2330);\n        t = _2331;\n        vec3 _2356 = normalize((_2331 * cos(s.anisotropy_rotation)) + ((cross(n, _2331) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4196 = _2356;\n        _4197 = cross(n, _2356);\n        float _2366 = roughness * roughness;\n        float _2372 = mix(_2366, 1.0, _2297 * _2297);\n        bool _2374 = _2297 > 0.0;\n        _4198 = _2374 ? _2372 : _2366;\n        _4199 = _2374 ? _2366 : _2372;\n        _4195 = _2297;\n        _4179 = true;\n    }\n    return FaLayers(_4179, _4180, _4181, _4182, _4183, _4184, _4185, _4186, i.world_normal, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _391 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _397 = fa_light_texel(param_1);\n    float _400 = _397.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _406 = _400 < 0.5;\n    vec3 l;\n    if (_406)\n    {\n        l = normalize(_391.xyz);\n    }\n    else\n    {\n        vec3 _418 = _391.xyz - world_pos;\n        float _420 = length(_418);\n        dist = _420;\n        l = _418 / vec3(max(_420, 9.9999997473787516355514526367188e-05));\n        float _435 = _420 / max(_391.w, 0.001000000047497451305389404296875);\n        float _441 = clamp(1.0 - (_435 * _435), 0.0, 1.0);\n        atten = _441 * _441;\n        if (_400 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _455 = fa_light_texel(param_2);\n            float _465 = _455.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _471 = fa_light_texel(param_3);\n            float _472 = _471.x;\n            float cos_inner = _472;\n            if (_472 > 1.5)\n            {\n                cos_inner = mix(_465, 1.0, 0.25);\n            }\n            atten *= smoothstep(_465, cos_inner, dot(-l, normalize(_455.xyz)));\n        }\n    }\n    int _503;\n    if (_406)\n    {\n        _503 = 0;\n    }\n    else\n    {\n        _503 = (_400 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _397.xyz * atten, atten, 1.0, dist, _503);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _743;\n    if (i == 0)\n    {\n        _743 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _759;\n        if (i == 1)\n        {\n            _759 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _767;\n            if (i == 2)\n            {\n                _767 = fa_shadows[24].z;\n            }\n            else\n            {\n                _767 = fa_shadows[24].w;\n            }\n            _759 = _767;\n        }\n        _743 = _759;\n    }\n    return _743;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _800 = fa_shadow_depth(param, param_1);\n    float _804;\n    if (conv.x < 0.5)\n    {\n        _804 = _800;\n    }\n    else\n    {\n        _804 = (conv.y * conv.z) / (conv.z - (_800 * (conv.z - conv.y)));\n    }\n    return _804;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _731 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_731), sin(_731)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _850 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _864 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _850;\n            vec2 _883 = fa_shadow_vogel(param_3, param_4, param_5) * _864;\n            vec2 param_6 = uv + (_883 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _895 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_895 < (zr - (length(_883) * plane)))\n            {\n                sum += _895;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _939 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _939; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _939;\n        float param_11 = _850;\n        vec2 _958 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_958 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_958) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_939);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1000 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1005 = clamp(dot(n, l), 0.0, 1.0);\n    float _1011 = sqrt(1.0 - (_1005 * _1005));\n    float _1019 = min(_1011 / max(_1005, 0.20000000298023223876953125), 4.0);\n    float _1024;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1024 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1024 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1049 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1024 * _1011)), 1.0);\n    float _1056 = _1049.x;\n    bool _1059 = _1056 < fa_shadows[ci * 1 + 16].x;\n    bool _1068;\n    if (!_1059)\n    {\n        _1068 = _1056 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1068 = _1059;\n    }\n    bool _1077;\n    if (!_1068)\n    {\n        _1077 = _1049.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1077 = _1068;\n    }\n    bool _1086;\n    if (!_1077)\n    {\n        _1086 = _1049.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1086 = _1077;\n    }\n    bool _1093;\n    if (!_1086)\n    {\n        _1093 = _1049.z > 1.0;\n    }\n    else\n    {\n        _1093 = _1086;\n    }\n    if (_1093)\n    {\n        return -1.0;\n    }\n    float _1102;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1102 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1102 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1049.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1049.z - ((_1102 * (1.0 + (0.5 * _1019))) / _1000);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1000;\n    float param_5 = _1000 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1019, 3.0)) * 0.5) / _1000;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1530 = int(fa_shadows[25].x + 0.5);\n    if (_1530 < 1)\n    {\n        return 1.0;\n    }\n    float _1546 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1530 - 1;\n    if (_1546 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1558 = _1530 > 1;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1546 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 1;\n    }\n    bool _1569 = _1530 > 2;\n    bool _1576;\n    if (_1569)\n    {\n        _1576 = _1546 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1576 = _1569;\n    }\n    if (_1576)\n    {\n        ci = 2;\n    }\n    bool _1580 = _1530 > 3;\n    bool _1587;\n    if (_1580)\n    {\n        _1587 = _1546 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1587 = _1580;\n    }\n    if (_1587)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1530)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1613 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1613;\n        if (_1613 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1638;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1638 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1638 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1657 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1638, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1668 = clamp((_1546 - (fa_shadow_split_at(param_7) - _1657)) / _1657, 0.0, 1.0);\n        if (_1668 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1530)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1689 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1689;\n                if (_1689 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1668);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1161 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1169;\n    if (!_1161)\n    {\n        _1169 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1169 = _1161;\n    }\n    if (_1169)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1182 = fa_light_texel(param);\n    float _1183 = _1182.x;\n    if (_1183 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1192 = int(_1183 + 0.5);\n    int param_1 = _1192;\n    vec4 _1196 = fa_light_texel(param_1);\n    int param_2 = _1192 + 1;\n    vec4 _1201 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1204 = _1196.y;\n    if (_1204 > 0.0)\n    {\n        float _1221 = 1.0 - smoothstep(0.75 * _1204, _1204, length(world - fa_shadows[27].xyz));\n        fade = _1221;\n        if (_1221 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1196.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1240 = world - fa_light_texel(param_3).xyz;\n        vec3 _1243 = abs(_1240);\n        float _1245 = _1243.x;\n        float _1247 = _1243.y;\n        bool _1248 = _1245 >= _1247;\n        bool _1256;\n        if (_1248)\n        {\n            _1256 = _1245 >= _1243.z;\n        }\n        else\n        {\n            _1256 = _1248;\n        }\n        int _1257;\n        if (_1256)\n        {\n            _1257 = (_1240.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1270;\n            if (_1247 >= _1243.z)\n            {\n                _1270 = (_1240.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1270 = (_1240.z > 0.0) ? 4 : 5;\n            }\n            _1257 = _1270;\n        }\n        face = _1257;\n    }\n    int _1289 = (_1192 + 2) + (face * 6);\n    int param_4 = _1289;\n    int param_5 = _1289 + 1;\n    int param_6 = _1289 + 3;\n    vec4 _1303 = fa_light_texel(param_6);\n    int param_7 = _1289 + 4;\n    vec4 _1308 = fa_light_texel(param_7);\n    int param_8 = _1289 + 5;\n    vec4 _1313 = fa_light_texel(param_8);\n    float _1325 = _1313.x * max(dot(_1303, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1330 = clamp(dot(n, l), 0.0, 1.0);\n    float _1353 = clamp(dot(n, _1303.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1376 = min(sqrt(1.0 - (_1353 * _1353)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1303, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1379 = _1201.y;\n    float _1381;\n    if (_1379 > 0.0)\n    {\n        _1381 = _1379;\n    }\n    else\n    {\n        _1381 = 1.5 * _1325;\n    }\n    vec4 _1401 = vec4(world + (n * (_1381 * sqrt(1.0 - (_1330 * _1330)))), 1.0);\n    float _1405 = dot(_1303, _1401);\n    float _1408 = _1313.y;\n    if (_1405 < _1408)\n    {\n        return 1.0;\n    }\n    vec2 _1423 = vec2(dot(fa_light_texel(param_4), _1401), dot(fa_light_texel(param_5), _1401)) / vec2(_1405);\n    float _1425 = _1423.x;\n    bool _1428 = _1425 < _1308.x;\n    bool _1437;\n    if (!_1428)\n    {\n        _1437 = _1425 > _1308.z;\n    }\n    else\n    {\n        _1437 = _1428;\n    }\n    bool _1446;\n    if (!_1437)\n    {\n        _1446 = _1423.y < _1308.y;\n    }\n    else\n    {\n        _1446 = _1437;\n    }\n    bool _1455;\n    if (!_1446)\n    {\n        _1455 = _1423.y > _1308.w;\n    }\n    else\n    {\n        _1455 = _1446;\n    }\n    if (_1455)\n    {\n        return 1.0;\n    }\n    float _1461 = _1201.x;\n    float _1463;\n    if (_1461 > 0.0)\n    {\n        _1463 = _1461;\n    }\n    else\n    {\n        _1463 = 1.5 * _1325;\n    }\n    vec2 param_10 = _1423;\n    vec4 param_11 = _1308;\n    float param_12 = _1405 - (_1463 * (1.0 + (0.5 * _1376)));\n    float param_13 = _1325;\n    float param_14 = 1.0;\n    float param_15 = _1313.z * 0.25;\n    float param_16 = (_1325 * min(_1376, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1408, _1313.z);\n    int param_18 = int(_1196.z + 0.5);\n    float param_19 = _1196.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2908 = fa_lm.z > 0.5;\n    bool _2914;\n    if (_2908)\n    {\n        int param = li;\n        _2914 = fa_light_baked(param);\n    }\n    else\n    {\n        _2914 = _2908;\n    }\n    if (_2914)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2936 = fa_light_sample(param_2, param_3);\n    vec3 _4241 = _2936.direction;\n    vec3 _4236 = _2936.color;\n    float _4243 = _2936.attenuation;\n    float _4238 = _2936.shadow;\n    int _4246 = _2936.type;\n    if ((_4246 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4241;\n        float _2950 = fa_shadow_factor(param_4, param_5);\n        _4238 = _2950;\n        _4236 *= _2950;\n    }\n    else\n    {\n        bool _2961 = _4246 != 0;\n        bool _2967;\n        if (_2961)\n        {\n            _2967 = _4243 > 0.0;\n        }\n        else\n        {\n            _2967 = _2961;\n        }\n        if (_2967)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4241;\n            float _2979 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4238 = _2979;\n            _4236 *= _2979;\n        }\n    }\n    return LightSample(_4241, _4236, _4243, _4238, _2936._distance, _4246);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2524 = tdh / at;\n    float _2528 = bdh / ab;\n    float _2540 = ((_2524 * _2524) + (_2528 * _2528)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2540) * _2540);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2621 = 1.0 / alpha;\n    return ((2.0 + _2621) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2621)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2654 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2733 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2733) * _2733);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2654);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2654));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2806 = max(dot(L.nc, l), 0.0);\n        float _2812 = max(dot(L.nc, h), 0.0);\n        float _2821 = ((_2812 * _2812) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2821) * _2821)) * (0.5 / max(mix((2.0 * _2806) * L.coat_ndv, _2806 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2806)) * _2806);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1921 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1924 = _1921.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1924 * _1924, exp2((-9.27999973297119140625) * ndv)) * _1924) + _1921.y)) + _1921.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1826 = rough * rough;\n    float _1856 = 0.60000002384185791015625 * _1826;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1826)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1856, 0.0500000007450580596923828125 + _1856, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1826 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2407;\n        if (L.aniso >= 0.0)\n        {\n            _2407 = L.b;\n        }\n        else\n        {\n            _2407 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2407, v), _2407), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2440 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2440.x) + (vec3(L.f90) * _2440.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2495 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2495.x) + _2495.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1963 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1963.x) + vec3(_1963.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1713 = int(fa_shadows[25].x + 0.5);\n    float _1723 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1728 = _1713 > 0;\n    bool _1737;\n    if (_1728)\n    {\n        int param = _1713 - 1;\n        _1737 = _1723 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1737 = _1728;\n    }\n    if (_1737)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1744 = _1713 > 1;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1723 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1757 = _1713 > 2;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1723 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1770 = _1713 > 3;\n        bool _1777;\n        if (_1770)\n        {\n            _1777 = _1723 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1777 = _1770;\n        }\n        if (_1777)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3958 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3958 = -_3958;\n    }\n    vec3 _3400 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3958, fa_world_tangent, fa_uv, fa_vertex_color, _3400, gl_FrontFacing);\n    Surface _3408 = fa_standard_surface(param_1);\n    vec3 _3989 = _3408.albedo;\n    float _3990 = _3408.alpha;\n    vec3 _3991 = _3408.normal;\n    float _3992 = _3408.metallic;\n    float _3993 = _3408.roughness;\n    float _3994 = _3408.occlusion;\n    vec3 _3995 = _3408.emission;\n    float _3996 = _3408.clearcoat;\n    float _3997 = _3408.clearcoat_roughness;\n    vec3 _3998 = _3408.sheen_color;\n    float _3999 = _3408.sheen_roughness;\n    float _4000 = _3408.anisotropy;\n    float _4001 = _3408.anisotropy_rotation;\n    float _4002 = _3408.specular;\n    float _4003 = _3408.ior;\n    vec3 _4004 = _3408.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3958, fa_world_tangent, fa_uv, fa_vertex_color, _3400, gl_FrontFacing);\n    Surface param_3 = _3408;\n    surface(param_2, param_3);\n    _3989 = param_3.albedo;\n    _3990 = param_3.alpha;\n    _3991 = param_3.normal;\n    _3992 = param_3.metallic;\n    _3993 = param_3.roughness;\n    _3994 = param_3.occlusion;\n    _3995 = param_3.emission;\n    _3996 = param_3.clearcoat;\n    _3997 = param_3.clearcoat_roughness;\n    _3998 = param_3.sheen_color;\n    _3999 = param_3.sheen_roughness;\n    _4000 = param_3.anisotropy;\n    _4001 = param_3.anisotropy_rotation;\n    _4002 = param_3.specular;\n    _4003 = param_3.ior;\n    _4004 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3989;\n    }\n    else\n    {\n        vec3 _3430 = normalize(_3991);\n        float _3437 = clamp(_3992, 0.0, 1.0);\n        float _3441 = clamp(_3993, 0.0500000007450580596923828125, 1.0);\n        float _3445 = _3441 * _3441;\n        float _3449 = _3445 * _3445;\n        float _3454 = max(dot(_3430, _3400), 9.9999997473787516355514526367188e-05);\n        vec3 _3460 = _3989 * (1.0 - _3437);\n        vec3 _3467 = mix(vec3(0.039999999105930328369140625), _3989, vec3(_3437));\n        vec3 f0 = _3467;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3958, fa_world_tangent, fa_uv, fa_vertex_color, _3400, gl_FrontFacing);\n        Surface param_5 = Surface(_3989, _3990, _3991, _3992, _3993, _3994, _3995, _3996, _3997, _3998, _3999, _4000, _4001, _4002, _4003, _4004);\n        vec3 param_6 = _3430;\n        vec3 param_7 = _3400;\n        float param_8 = _3437;\n        float param_9 = _3441;\n        vec3 param_10 = _3467;\n        FaLayers _3483 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _3430;\n        vec3 lit = (fa_indirect_diffuse(param_11) * _3460) * _3994;\n        if (_3483.on)\n        {\n            lit *= _3483.base_scale;\n        }\n        int _3505 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3505; ln++)\n        {\n            int param_12 = ln;\n            int _3518 = fa_cl_light(param_12);\n            bool _3521 = fa_lm.z > 0.5;\n            bool _3527;\n            if (_3521)\n            {\n                int param_13 = _3518;\n                _3527 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3527 = _3521;\n            }\n            if (_3527)\n            {\n                continue;\n            }\n            int param_14 = _3518;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3958;\n            LightSample _3539 = fa_light_shadowed(param_14, param_15, param_16);\n            vec3 _4163 = _3539.direction;\n            float _3547 = max(dot(_3430, _4163), 0.0);\n            float _3553 = _3539.attenuation * _3539.shadow;\n            vec3 _3558 = normalize(_4163 + _3400);\n            float _3563 = max(dot(_3430, _3558), 0.0);\n            float _3568 = max(dot(_3400, _3558), 0.0);\n            if (_3483.on)\n            {\n                FaLayers param_17 = _3483;\n                vec3 param_18 = _3460;\n                vec3 param_19 = f0;\n                vec3 param_20 = _3430;\n                vec3 param_21 = _3400;\n                vec3 param_22 = _4163;\n                vec3 param_23 = _3558;\n                float param_24 = _3547;\n                float param_25 = _3454;\n                float param_26 = _3563;\n                float param_27 = _3568;\n                float param_28 = _3445;\n                float param_29 = _3449;\n                int param_30 = _3518;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3553));\n            }\n            else\n            {\n                float _3616 = ((_3563 * _3563) * (_3449 - 1.0)) + 1.0;\n                int param_31 = _3518;\n                lit += (((_3460 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3568, 5.0))) * (((_3449 / ((3.1415927410125732421875 * _3616) * _3616)) * (0.5 / max(mix((2.0 * _3547) * _3454, _3547 + _3454, _3445), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3547))) * fa_light_rgb(param_31)) * (_3547 * _3553));\n            }\n        }\n        if (_3483.on)\n        {\n            FaLayers param_32 = _3483;\n            vec3 param_33 = _3430;\n            vec3 param_34 = _3400;\n            vec3 param_35 = f0;\n            float param_36 = _3441;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3994);\n        }\n        else\n        {\n            vec3 param_37 = _3430;\n            vec3 param_38 = _3400;\n            vec3 param_39 = f0;\n            float param_40 = _3441;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3994);\n        }\n        result = lit;\n    }\n    vec3 _3709 = result;\n    vec3 _3710 = _3709 + _3995;\n    result = _3710;\n    vec3 param_41 = _3710;\n    vec3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3719 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3726;\n    if (!_3719)\n    {\n        _3726 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3726 = _3719;\n    }\n    if (_3726)\n    {\n        vec3 _3735 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3741 = dot(_3735, fa_mesh_fs_params[9].xyz);\n        bool _3745 = fa_mesh_fs_params[9].w > 0.5;\n        float _3746;\n        if (_3745)\n        {\n            _3746 = _3741;\n        }\n        else\n        {\n            _3746 = length(_3735);\n        }\n        float _3758 = _3746 - fa_mesh_fs_params[8].x;\n        if (_3758 > 0.0)\n        {\n            float _3767 = fa_mesh_fs_params[7].w * _3758;\n            float tau = _3767 * _3767;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3783;\n                if (_3745)\n                {\n                    _3783 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3741);\n                }\n                else\n                {\n                    _3783 = fa_mesh_fs_params[0].y;\n                }\n                float _3804 = mix(_3783, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3746, 0.0, 1.0));\n                float _3808 = fa_world_pos.y - _3804;\n                float _3813 = _3804 - fa_mesh_fs_params[8].z;\n                float _3818 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3821 = _3813 <= 0.0;\n                bool _3822 = !_3821;\n                bool _3828;\n                if (_3822)\n                {\n                    _3828 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3828 = _3821;\n                }\n                float _3829;\n                if (_3828)\n                {\n                    _3829 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3829 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3813, 80.0));\n                }\n                bool _3856;\n                if (_3822)\n                {\n                    _3856 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3856 = _3821;\n                }\n                float _3857;\n                if (_3856)\n                {\n                    _3857 = fa_mesh_fs_params[8].y * _3813;\n                }\n                else\n                {\n                    _3857 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3813, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3882 = _3818 <= 0.0;\n                bool _3889;\n                if (!_3882)\n                {\n                    _3889 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3889 = _3882;\n                }\n                float _3890;\n                if (_3889)\n                {\n                    _3890 = fa_mesh_fs_params[8].y * _3818;\n                }\n                else\n                {\n                    _3890 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3818, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3917;\n                if (abs(_3808) < 0.001000000047497451305389404296875)\n                {\n                    _3917 = _3829;\n                }\n                else\n                {\n                    _3917 = (_3890 - _3857) / _3808;\n                }\n                tau += (_3758 * max(_3917, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3990);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "inst_name": "_517",
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
            "inst_name": "_753",
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
            "inst_name": "_3004",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2064[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _522 = fa_mesh_fs_params[19].x < 0.0;\n    bool _529;\n    if (!_522)\n    {\n        _529 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _529 = _522;\n    }\n    bool _537;\n    if (!_529)\n    {\n        _537 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _537 = _529;\n    }\n    bool _544;\n    if (!_537)\n    {\n        _544 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _544 = _537;\n    }\n    bool _551;\n    if (!_544)\n    {\n        _551 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _551 = _544;\n    }\n    if (_551)\n    {\n        return ivec2(0);\n    }\n    vec4 _561 = vec4(world_pos, 1.0);\n    float _568 = dot(fa_mesh_fs_params[16], _561);\n    if (!(_568 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _590 = vec2(dot(fa_mesh_fs_params[14], _561), dot(fa_mesh_fs_params[15], _561)) / vec2(_568);\n    int _594 = int(fa_mesh_fs_params[18].x);\n    int _598 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _598) + clamp(int(floor(((_590.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _598 - 1)) * _594)) + clamp(int(floor(((_590.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _594 - 1);\n    vec4 _669 = fa_light_texel(param);\n    return ivec2(int(_669.x), int(_669.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2881 = fa_cluster_lookup(param);\n    fa_cl_slot = _2881.x;\n    fa_cl_local = _2881.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3068 = fa_linear_to_srgb(param);\n        c = _3068;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3076 = fa_srgb_to_linear(param_1);\n            c = _3076;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _272;\n    if (i.front_facing)\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    vec3 _296 = normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    vec3 _324 = normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    vec3 _327;\n    if (i.front_facing)\n    {\n        _327 = _324;\n    }\n    else\n    {\n        _327 = -_324;\n    }\n    return _327;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3107 = fa_tex_fix(param_2, param_3);\n    vec4 _4354 = base_t;\n    _4354.x = _3107.x;\n    _4354.y = _3107.y;\n    _4354.z = _3107.z;\n    base_t = _4354;\n    vec4 _3121 = (_4354 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4256 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3153 = fa_tex_fix(param_6, param_7);\n        vec3 _3156 = (_3153 * 2.0) - vec3(1.0);\n        vec2 _3161 = _3156.xy * fa_mesh_fs_params[6].x;\n        vec3 _4362 = _3156;\n        _4362.x = _3161.x;\n        _4362.y = _3161.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4362;\n        _4256 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3190 = fa_tex_fix(param_12, param_13);\n    vec4 _4365 = mrt;\n    _4365.x = _3190.x;\n    _4365.y = _3190.y;\n    _4365.z = _3190.z;\n    mrt = _4365;\n    vec4 _3218 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3230 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3260 = fa_tex_fix(param_20, param_21);\n    float _4261 = fa_mesh_fs_params[20].x;\n    float _4262 = fa_mesh_fs_params[20].y;\n    float _4265 = fa_mesh_fs_params[20].z;\n    float _4264 = fa_mesh_fs_params[21].w;\n    float _4267 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4261 *= _3230.y;\n            _4262 *= _3230.z;\n            _4264 *= _3218.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4265 *= mrt.x;\n            _4267 *= mrt.w;\n        }\n    }\n    return Surface(_3121.xyz, _3121.w, _4256, clamp(fa_mesh_fs_params[5].x * _3190.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3190.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3230.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3260), _4261, _4262, fa_mesh_fs_params[21].xyz, _4264, _4265, fa_mesh_fs_params[20].w, _4267, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1989 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1997 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2000 = int(_1989);\n    int _2003 = int(_1997);\n    float _2013 = _1997 - float(_2003);\n    int _2069 = (_2000 * 9) + _2003;\n    int _2089 = ((_2000 + 1) * 9) + _2003;\n    return mix(mix(_2064[_2069], _2064[_2069 + 1], _2013), mix(_2064[_2089], _2064[_2089 + 1], _2013), _1989 - float(_2000));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4179 = false;\n    float _4180 = 1.0;\n    float _4181 = 1.0;\n    float _4182 = 1.0;\n    float _4183 = 0.0;\n    float _4184 = 0.0;\n    float _4185 = 0.0;\n    float _4186 = 0.0;\n    float _4188 = 1.0;\n    bool _4189 = false;\n    vec3 _4190 = vec3(0.0);\n    float _4191 = 1.0;\n    float _4192 = 1.0;\n    float _4193 = 1.0;\n    float _4194 = 0.0;\n    float _4195 = 0.0;\n    vec3 _4196 = vec3(1.0, 0.0, 0.0);\n    vec3 _4197 = vec3(0.0, 0.0, 1.0);\n    float _4198 = 1.0;\n    float _4199 = 1.0;\n    float _2142 = clamp(s.specular, 0.0, 1.0);\n    float _2146 = clamp(s.ior, 1.0, 3.0);\n    bool _2151 = (_2142 != 1.0) || (_2146 != 1.5);\n    bool _2161;\n    if (!_2151)\n    {\n        _2161 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2161 = _2151;\n    }\n    if (_2161)\n    {\n        float _2169 = (_2146 - 1.0) / (_2146 + 1.0);\n        f0 = mix(min(vec3(_2169 * _2169) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2142, s.albedo, vec3(metallic));\n        _4180 = mix(_2142, 1.0, metallic);\n        _4179 = true;\n    }\n    float _2197 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2197 > 0.0)\n    {\n        float _2205 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4183 = _2197;\n        _4184 = _2205;\n        float _2212 = _2205 * _2205;\n        _4185 = _2212;\n        _4186 = _2212 * _2212;\n        float _2224 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4188 = _2224;\n        _4181 = 1.0 - (_2197 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2224, 0.0, 1.0), 5.0))));\n        _4179 = true;\n    }\n    vec3 _2244 = max(s.sheen_color, vec3(0.0));\n    float _2253 = max(_2244.x, max(_2244.y, _2244.z));\n    if (_2253 > 0.0)\n    {\n        float _2261 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4189 = true;\n        _4190 = _2244;\n        _4191 = _2261;\n        _4192 = _2261 * _2261;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2261;\n        float _2278 = fa_sheen_albedo(param, param_1);\n        _4194 = _2278;\n        _4193 = 1.0 - min(_2253 * _2278, 1.0);\n        _4179 = true;\n    }\n    _4182 = _4181 * _4193;\n    float _2297 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2297 != 0.0)\n    {\n        vec3 _2312 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2312;\n        if (dot(_2312, _2312) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2326 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2326.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2326.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2326.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2330 = t;\n        vec3 _2331 = normalize(_2330);\n        t = _2331;\n        vec3 _2356 = normalize((_2331 * cos(s.anisotropy_rotation)) + ((cross(n, _2331) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4196 = _2356;\n        _4197 = cross(n, _2356);\n        float _2366 = roughness * roughness;\n        float _2372 = mix(_2366, 1.0, _2297 * _2297);\n        bool _2374 = _2297 > 0.0;\n        _4198 = _2374 ? _2372 : _2366;\n        _4199 = _2374 ? _2366 : _2372;\n        _4195 = _2297;\n        _4179 = true;\n    }\n    return FaLayers(_4179, _4180, _4181, _4182, _4183, _4184, _4185, _4186, i.world_normal, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _391 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _397 = fa_light_texel(param_1);\n    float _400 = _397.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _406 = _400 < 0.5;\n    vec3 l;\n    if (_406)\n    {\n        l = normalize(_391.xyz);\n    }\n    else\n    {\n        vec3 _418 = _391.xyz - world_pos;\n        float _420 = length(_418);\n        dist = _420;\n        l = _418 / vec3(max(_420, 9.9999997473787516355514526367188e-05));\n        float _435 = _420 / max(_391.w, 0.001000000047497451305389404296875);\n        float _441 = clamp(1.0 - (_435 * _435), 0.0, 1.0);\n        atten = _441 * _441;\n        if (_400 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _455 = fa_light_texel(param_2);\n            float _465 = _455.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _471 = fa_light_texel(param_3);\n            float _472 = _471.x;\n            float cos_inner = _472;\n            if (_472 > 1.5)\n            {\n                cos_inner = mix(_465, 1.0, 0.25);\n            }\n            atten *= smoothstep(_465, cos_inner, dot(-l, normalize(_455.xyz)));\n        }\n    }\n    int _503;\n    if (_406)\n    {\n        _503 = 0;\n    }\n    else\n    {\n        _503 = (_400 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _397.xyz * atten, atten, 1.0, dist, _503);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _743;\n    if (i == 0)\n    {\n        _743 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _759;\n        if (i == 1)\n        {\n            _759 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _767;\n            if (i == 2)\n            {\n                _767 = fa_shadows[24].z;\n            }\n            else\n            {\n                _767 = fa_shadows[24].w;\n            }\n            _759 = _767;\n        }\n        _743 = _759;\n    }\n    return _743;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _800 = fa_shadow_depth(param, param_1);\n    float _804;\n    if (conv.x < 0.5)\n    {\n        _804 = _800;\n    }\n    else\n    {\n        _804 = (conv.y * conv.z) / (conv.z - (_800 * (conv.z - conv.y)));\n    }\n    return _804;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _731 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_731), sin(_731)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _850 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _864 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _850;\n            vec2 _883 = fa_shadow_vogel(param_3, param_4, param_5) * _864;\n            vec2 param_6 = uv + (_883 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _895 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_895 < (zr - (length(_883) * plane)))\n            {\n                sum += _895;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _939 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _939; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _939;\n        float param_11 = _850;\n        vec2 _958 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_958 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_958) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_939);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1000 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1005 = clamp(dot(n, l), 0.0, 1.0);\n    float _1011 = sqrt(1.0 - (_1005 * _1005));\n    float _1019 = min(_1011 / max(_1005, 0.20000000298023223876953125), 4.0);\n    float _1024;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1024 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1024 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1049 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1024 * _1011)), 1.0);\n    float _1056 = _1049.x;\n    bool _1059 = _1056 < fa_shadows[ci * 1 + 16].x;\n    bool _1068;\n    if (!_1059)\n    {\n        _1068 = _1056 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1068 = _1059;\n    }\n    bool _1077;\n    if (!_1068)\n    {\n        _1077 = _1049.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1077 = _1068;\n    }\n    bool _1086;\n    if (!_1077)\n    {\n        _1086 = _1049.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1086 = _1077;\n    }\n    bool _1093;\n    if (!_1086)\n    {\n        _1093 = _1049.z > 1.0;\n    }\n    else\n    {\n        _1093 = _1086;\n    }\n    if (_1093)\n    {\n        return -1.0;\n    }\n    float _1102;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1102 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1102 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1049.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1049.z - ((_1102 * (1.0 + (0.5 * _1019))) / _1000);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1000;\n    float param_5 = _1000 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1019, 3.0)) * 0.5) / _1000;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1530 = int(fa_shadows[25].x + 0.5);\n    if (_1530 < 1)\n    {\n        return 1.0;\n    }\n    float _1546 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1530 - 1;\n    if (_1546 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1558 = _1530 > 1;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1546 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 1;\n    }\n    bool _1569 = _1530 > 2;\n    bool _1576;\n    if (_1569)\n    {\n        _1576 = _1546 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1576 = _1569;\n    }\n    if (_1576)\n    {\n        ci = 2;\n    }\n    bool _1580 = _1530 > 3;\n    bool _1587;\n    if (_1580)\n    {\n        _1587 = _1546 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1587 = _1580;\n    }\n    if (_1587)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1530)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1613 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1613;\n        if (_1613 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1638;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1638 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1638 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1657 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1638, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1668 = clamp((_1546 - (fa_shadow_split_at(param_7) - _1657)) / _1657, 0.0, 1.0);\n        if (_1668 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1530)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1689 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1689;\n                if (_1689 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1668);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1161 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1169;\n    if (!_1161)\n    {\n        _1169 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1169 = _1161;\n    }\n    if (_1169)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1182 = fa_light_texel(param);\n    float _1183 = _1182.x;\n    if (_1183 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1192 = int(_1183 + 0.5);\n    int param_1 = _1192;\n    vec4 _1196 = fa_light_texel(param_1);\n    int param_2 = _1192 + 1;\n    vec4 _1201 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1204 = _1196.y;\n    if (_1204 > 0.0)\n    {\n        float _1221 = 1.0 - smoothstep(0.75 * _1204, _1204, length(world - fa_shadows[27].xyz));\n        fade = _1221;\n        if (_1221 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1196.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1240 = world - fa_light_texel(param_3).xyz;\n        vec3 _1243 = abs(_1240);\n        float _1245 = _1243.x;\n        float _1247 = _1243.y;\n        bool _1248 = _1245 >= _1247;\n        bool _1256;\n        if (_1248)\n        {\n            _1256 = _1245 >= _1243.z;\n        }\n        else\n        {\n            _1256 = _1248;\n        }\n        int _1257;\n        if (_1256)\n        {\n            _1257 = (_1240.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1270;\n            if (_1247 >= _1243.z)\n            {\n                _1270 = (_1240.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1270 = (_1240.z > 0.0) ? 4 : 5;\n            }\n            _1257 = _1270;\n        }\n        face = _1257;\n    }\n    int _1289 = (_1192 + 2) + (face * 6);\n    int param_4 = _1289;\n    int param_5 = _1289 + 1;\n    int param_6 = _1289 + 3;\n    vec4 _1303 = fa_light_texel(param_6);\n    int param_7 = _1289 + 4;\n    vec4 _1308 = fa_light_texel(param_7);\n    int param_8 = _1289 + 5;\n    vec4 _1313 = fa_light_texel(param_8);\n    float _1325 = _1313.x * max(dot(_1303, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1330 = clamp(dot(n, l), 0.0, 1.0);\n    float _1353 = clamp(dot(n, _1303.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1376 = min(sqrt(1.0 - (_1353 * _1353)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1303, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1379 = _1201.y;\n    float _1381;\n    if (_1379 > 0.0)\n    {\n        _1381 = _1379;\n    }\n    else\n    {\n        _1381 = 1.5 * _1325;\n    }\n    vec4 _1401 = vec4(world + (n * (_1381 * sqrt(1.0 - (_1330 * _1330)))), 1.0);\n    float _1405 = dot(_1303, _1401);\n    float _1408 = _1313.y;\n    if (_1405 < _1408)\n    {\n        return 1.0;\n    }\n    vec2 _1423 = vec2(dot(fa_light_texel(param_4), _1401), dot(fa_light_texel(param_5), _1401)) / vec2(_1405);\n    float _1425 = _1423.x;\n    bool _1428 = _1425 < _1308.x;\n    bool _1437;\n    if (!_1428)\n    {\n        _1437 = _1425 > _1308.z;\n    }\n    else\n    {\n        _1437 = _1428;\n    }\n    bool _1446;\n    if (!_1437)\n    {\n        _1446 = _1423.y < _1308.y;\n    }\n    else\n    {\n        _1446 = _1437;\n    }\n    bool _1455;\n    if (!_1446)\n    {\n        _1455 = _1423.y > _1308.w;\n    }\n    else\n    {\n        _1455 = _1446;\n    }\n    if (_1455)\n    {\n        return 1.0;\n    }\n    float _1461 = _1201.x;\n    float _1463;\n    if (_1461 > 0.0)\n    {\n        _1463 = _1461;\n    }\n    else\n    {\n        _1463 = 1.5 * _1325;\n    }\n    vec2 param_10 = _1423;\n    vec4 param_11 = _1308;\n    float param_12 = _1405 - (_1463 * (1.0 + (0.5 * _1376)));\n    float param_13 = _1325;\n    float param_14 = 1.0;\n    float param_15 = _1313.z * 0.25;\n    float param_16 = (_1325 * min(_1376, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1408, _1313.z);\n    int param_18 = int(_1196.z + 0.5);\n    float param_19 = _1196.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2908 = fa_lm.z > 0.5;\n    bool _2914;\n    if (_2908)\n    {\n        int param = li;\n        _2914 = fa_light_baked(param);\n    }\n    else\n    {\n        _2914 = _2908;\n    }\n    if (_2914)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2936 = fa_light_sample(param_2, param_3);\n    vec3 _4241 = _2936.direction;\n    vec3 _4236 = _2936.color;\n    float _4243 = _2936.attenuation;\n    float _4238 = _2936.shadow;\n    int _4246 = _2936.type;\n    if ((_4246 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4241;\n        float _2950 = fa_shadow_factor(param_4, param_5);\n        _4238 = _2950;\n        _4236 *= _2950;\n    }\n    else\n    {\n        bool _2961 = _4246 != 0;\n        bool _2967;\n        if (_2961)\n        {\n            _2967 = _4243 > 0.0;\n        }\n        else\n        {\n            _2967 = _2961;\n        }\n        if (_2967)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4241;\n            float _2979 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4238 = _2979;\n            _4236 *= _2979;\n        }\n    }\n    return LightSample(_4241, _4236, _4243, _4238, _2936._distance, _4246);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2524 = tdh / at;\n    float _2528 = bdh / ab;\n    float _2540 = ((_2524 * _2524) + (_2528 * _2528)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2540) * _2540);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2621 = 1.0 / alpha;\n    return ((2.0 + _2621) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2621)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2654 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2733 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2733) * _2733);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2654);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2654));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2806 = max(dot(L.nc, l), 0.0);\n        float _2812 = max(dot(L.nc, h), 0.0);\n        float _2821 = ((_2812 * _2812) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2821) * _2821)) * (0.5 / max(mix((2.0 * _2806) * L.coat_ndv, _2806 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2806)) * _2806);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1921 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1924 = _1921.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1924 * _1924, exp2((-9.27999973297119140625) * ndv)) * _1924) + _1921.y)) + _1921.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1826 = rough * rough;\n    float _1856 = 0.60000002384185791015625 * _1826;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1826)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1856, 0.0500000007450580596923828125 + _1856, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1826 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2407;\n        if (L.aniso >= 0.0)\n        {\n            _2407 = L.b;\n        }\n        else\n        {\n            _2407 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2407, v), _2407), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2440 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2440.x) + (vec3(L.f90) * _2440.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2495 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2495.x) + _2495.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1963 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1963.x) + vec3(_1963.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1713 = int(fa_shadows[25].x + 0.5);\n    float _1723 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1728 = _1713 > 0;\n    bool _1737;\n    if (_1728)\n    {\n        int param = _1713 - 1;\n        _1737 = _1723 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1737 = _1728;\n    }\n    if (_1737)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1744 = _1713 > 1;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1723 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1757 = _1713 > 2;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1723 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1770 = _1713 > 3;\n        bool _1777;\n        if (_1770)\n        {\n            _1777 = _1723 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1777 = _1770;\n        }\n        if (_1777)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3958 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3958 = -_3958;\n    }\n    vec3 _3400 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3958, fa_world_tangent, fa_uv, fa_vertex_color, _3400, gl_FrontFacing);\n    Surface _3408 = fa_standard_surface(param_1);\n    vec3 _3989 = _3408.albedo;\n    float _3990 = _3408.alpha;\n    vec3 _3991 = _3408.normal;\n    float _3992 = _3408.metallic;\n    float _3993 = _3408.roughness;\n    float _3994 = _3408.occlusion;\n    vec3 _3995 = _3408.emission;\n    float _3996 = _3408.clearcoat;\n    float _3997 = _3408.clearcoat_roughness;\n    vec3 _3998 = _3408.sheen_color;\n    float _3999 = _3408.sheen_roughness;\n    float _4000 = _3408.anisotropy;\n    float _4001 = _3408.anisotropy_rotation;\n    float _4002 = _3408.specular;\n    float _4003 = _3408.ior;\n    vec3 _4004 = _3408.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3958, fa_world_tangent, fa_uv, fa_vertex_color, _3400, gl_FrontFacing);\n    Surface param_3 = _3408;\n    surface(param_2, param_3);\n    _3989 = param_3.albedo;\n    _3990 = param_3.alpha;\n    _3991 = param_3.normal;\n    _3992 = param_3.metallic;\n    _3993 = param_3.roughness;\n    _3994 = param_3.occlusion;\n    _3995 = param_3.emission;\n    _3996 = param_3.clearcoat;\n    _3997 = param_3.clearcoat_roughness;\n    _3998 = param_3.sheen_color;\n    _3999 = param_3.sheen_roughness;\n    _4000 = param_3.anisotropy;\n    _4001 = param_3.anisotropy_rotation;\n    _4002 = param_3.specular;\n    _4003 = param_3.ior;\n    _4004 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3989;\n    }\n    else\n    {\n        vec3 _3430 = normalize(_3991);\n        float _3437 = clamp(_3992, 0.0, 1.0);\n        float _3441 = clamp(_3993, 0.0500000007450580596923828125, 1.0);\n        float _3445 = _3441 * _3441;\n        float _3449 = _3445 * _3445;\n        float _3454 = max(dot(_3430, _3400), 9.9999997473787516355514526367188e-05);\n        vec3 _3460 = _3989 * (1.0 - _3437);\n        vec3 _3467 = mix(vec3(0.039999999105930328369140625), _3989, vec3(_3437));\n        vec3 f0 = _3467;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3958, fa_world_tangent, fa_uv, fa_vertex_color, _3400, gl_FrontFacing);\n        Surface param_5 = Surface(_3989, _3990, _3991, _3992, _3993, _3994, _3995, _3996, _3997, _3998, _3999, _4000, _4001, _4002, _4003, _4004);\n        vec3 param_6 = _3430;\n        vec3 param_7 = _3400;\n        float param_8 = _3437;\n        float param_9 = _3441;\n        vec3 param_10 = _3467;\n        FaLayers _3483 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _3430;\n        vec3 lit = (fa_indirect_diffuse(param_11) * _3460) * _3994;\n        if (_3483.on)\n        {\n            lit *= _3483.base_scale;\n        }\n        int _3505 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3505; ln++)\n        {\n            int param_12 = ln;\n            int _3518 = fa_cl_light(param_12);\n            bool _3521 = fa_lm.z > 0.5;\n            bool _3527;\n            if (_3521)\n            {\n                int param_13 = _3518;\n                _3527 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3527 = _3521;\n            }\n            if (_3527)\n            {\n                continue;\n            }\n            int param_14 = _3518;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3958;\n            LightSample _3539 = fa_light_shadowed(param_14, param_15, param_16);\n            vec3 _4163 = _3539.direction;\n            float _3547 = max(dot(_3430, _4163), 0.0);\n            float _3553 = _3539.attenuation * _3539.shadow;\n            vec3 _3558 = normalize(_4163 + _3400);\n            float _3563 = max(dot(_3430, _3558), 0.0);\n            float _3568 = max(dot(_3400, _3558), 0.0);\n            if (_3483.on)\n            {\n                FaLayers param_17 = _3483;\n                vec3 param_18 = _3460;\n                vec3 param_19 = f0;\n                vec3 param_20 = _3430;\n                vec3 param_21 = _3400;\n                vec3 param_22 = _4163;\n                vec3 param_23 = _3558;\n                float param_24 = _3547;\n                float param_25 = _3454;\n                float param_26 = _3563;\n                float param_27 = _3568;\n                float param_28 = _3445;\n                float param_29 = _3449;\n                int param_30 = _3518;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3553));\n            }\n            else\n            {\n                float _3616 = ((_3563 * _3563) * (_3449 - 1.0)) + 1.0;\n                int param_31 = _3518;\n                lit += (((_3460 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3568, 5.0))) * (((_3449 / ((3.1415927410125732421875 * _3616) * _3616)) * (0.5 / max(mix((2.0 * _3547) * _3454, _3547 + _3454, _3445), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3547))) * fa_light_rgb(param_31)) * (_3547 * _3553));\n            }\n        }\n        if (_3483.on)\n        {\n            FaLayers param_32 = _3483;\n            vec3 param_33 = _3430;\n            vec3 param_34 = _3400;\n            vec3 param_35 = f0;\n            float param_36 = _3441;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3994);\n        }\n        else\n        {\n            vec3 param_37 = _3430;\n            vec3 param_38 = _3400;\n            vec3 param_39 = f0;\n            float param_40 = _3441;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3994);\n        }\n        result = lit;\n    }\n    vec3 _3709 = result;\n    vec3 _3710 = _3709 + _3995;\n    result = _3710;\n    vec3 param_41 = _3710;\n    vec3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3719 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3726;\n    if (!_3719)\n    {\n        _3726 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3726 = _3719;\n    }\n    if (_3726)\n    {\n        vec3 _3735 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3741 = dot(_3735, fa_mesh_fs_params[9].xyz);\n        bool _3745 = fa_mesh_fs_params[9].w > 0.5;\n        float _3746;\n        if (_3745)\n        {\n            _3746 = _3741;\n        }\n        else\n        {\n            _3746 = length(_3735);\n        }\n        float _3758 = _3746 - fa_mesh_fs_params[8].x;\n        if (_3758 > 0.0)\n        {\n            float _3767 = fa_mesh_fs_params[7].w * _3758;\n            float tau = _3767 * _3767;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3783;\n                if (_3745)\n                {\n                    _3783 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3741);\n                }\n                else\n                {\n                    _3783 = fa_mesh_fs_params[0].y;\n                }\n                float _3804 = mix(_3783, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3746, 0.0, 1.0));\n                float _3808 = fa_world_pos.y - _3804;\n                float _3813 = _3804 - fa_mesh_fs_params[8].z;\n                float _3818 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3821 = _3813 <= 0.0;\n                bool _3822 = !_3821;\n                bool _3828;\n                if (_3822)\n                {\n                    _3828 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3828 = _3821;\n                }\n                float _3829;\n                if (_3828)\n                {\n                    _3829 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3829 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3813, 80.0));\n                }\n                bool _3856;\n                if (_3822)\n                {\n                    _3856 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3856 = _3821;\n                }\n                float _3857;\n                if (_3856)\n                {\n                    _3857 = fa_mesh_fs_params[8].y * _3813;\n                }\n                else\n                {\n                    _3857 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3813, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3882 = _3818 <= 0.0;\n                bool _3889;\n                if (!_3882)\n                {\n                    _3889 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3889 = _3882;\n                }\n                float _3890;\n                if (_3889)\n                {\n                    _3890 = fa_mesh_fs_params[8].y * _3818;\n                }\n                else\n                {\n                    _3890 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3818, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3917;\n                if (abs(_3808) < 0.001000000047497451305389404296875)\n                {\n                    _3917 = _3829;\n                }\n                else\n                {\n                    _3917 = (_3890 - _3857) / _3808;\n                }\n                tau += (_3758 * max(_3917, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3990);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "inst_name": "_517",
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
            "inst_name": "_753",
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
            "inst_name": "_3004",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
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
