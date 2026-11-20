{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "glsl430",
  "params": [],
  "textures": [],
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
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1997[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _489 = fa_mesh_fs_params[19].x < 0.0;\n    bool _496;\n    if (!_489)\n    {\n        _496 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _496 = _489;\n    }\n    bool _504;\n    if (!_496)\n    {\n        _504 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _504 = _496;\n    }\n    bool _511;\n    if (!_504)\n    {\n        _511 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _511 = _504;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    if (_518)\n    {\n        return ivec2(0);\n    }\n    vec4 _528 = vec4(world_pos, 1.0);\n    float _535 = dot(fa_mesh_fs_params[16], _528);\n    if (!(_535 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _557 = vec2(dot(fa_mesh_fs_params[14], _528), dot(fa_mesh_fs_params[15], _528)) / vec2(_535);\n    int _561 = int(fa_mesh_fs_params[18].x);\n    int _565 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _565) + clamp(int(floor(((_557.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _565 - 1)) * _561)) + clamp(int(floor(((_557.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _561 - 1);\n    vec4 _636 = fa_light_texel(param);\n    return ivec2(int(_636.x), int(_636.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2814 = fa_cluster_lookup(param);\n    fa_cl_slot = _2814.x;\n    fa_cl_local = _2814.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2958 = fa_linear_to_srgb(param);\n        c = _2958;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2966 = fa_srgb_to_linear(param_1);\n            c = _2966;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _256;\n    if (i.front_facing)\n    {\n        _256 = i.world_normal;\n    }\n    else\n    {\n        _256 = -i.world_normal;\n    }\n    vec3 _280 = normalize(i.world_tangent.xyz - (_256 * dot(_256, i.world_tangent.xyz)));\n    vec3 _308 = normalize(((_280 * m.x) + ((cross(_256, _280) * i.world_tangent.w) * m.y)) + (_256 * m.z));\n    vec3 _311;\n    if (i.front_facing)\n    {\n        _311 = _308;\n    }\n    else\n    {\n        _311 = -_308;\n    }\n    return _311;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2997 = fa_tex_fix(param_2, param_3);\n    vec4 _4200 = base_t;\n    _4200.x = _2997.x;\n    _4200.y = _2997.y;\n    _4200.z = _2997.z;\n    base_t = _4200;\n    vec4 _3011 = (_4200 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4102 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3043 = fa_tex_fix(param_6, param_7);\n        vec3 _3046 = (_3043 * 2.0) - vec3(1.0);\n        vec2 _3051 = _3046.xy * fa_mesh_fs_params[6].x;\n        vec3 _4208 = _3046;\n        _4208.x = _3051.x;\n        _4208.y = _3051.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4208;\n        _4102 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3080 = fa_tex_fix(param_12, param_13);\n    vec4 _4211 = mrt;\n    _4211.x = _3080.x;\n    _4211.y = _3080.y;\n    _4211.z = _3080.z;\n    mrt = _4211;\n    vec4 _3108 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3108.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3120 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3150 = fa_tex_fix(param_20, param_21);\n    float _4107 = fa_mesh_fs_params[20].x;\n    float _4108 = fa_mesh_fs_params[20].y;\n    float _4111 = fa_mesh_fs_params[20].z;\n    float _4110 = fa_mesh_fs_params[21].w;\n    float _4113 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4107 *= _3120.y;\n            _4108 *= _3120.z;\n            _4110 *= _3108.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4111 *= mrt.x;\n            _4113 *= mrt.w;\n        }\n    }\n    return Surface(_3011.xyz, _3011.w, _4102, clamp(fa_mesh_fs_params[5].x * _3080.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3080.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3120.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3150), _4107, _4108, fa_mesh_fs_params[21].xyz, _4110, _4111, fa_mesh_fs_params[20].w, _4113, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1922 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1930 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1933 = int(_1922);\n    int _1936 = int(_1930);\n    float _1946 = _1930 - float(_1936);\n    int _2002 = (_1933 * 9) + _1936;\n    int _2022 = ((_1933 + 1) * 9) + _1936;\n    return mix(mix(_1997[_2002], _1997[_2002 + 1], _1946), mix(_1997[_2022], _1997[_2022 + 1], _1946), _1922 - float(_1933));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4038 = false;\n    float _4039 = 1.0;\n    float _4040 = 1.0;\n    float _4041 = 1.0;\n    float _4042 = 0.0;\n    float _4043 = 0.0;\n    float _4044 = 0.0;\n    float _4045 = 0.0;\n    float _4047 = 1.0;\n    bool _4048 = false;\n    vec3 _4049 = vec3(0.0);\n    float _4050 = 1.0;\n    float _4051 = 1.0;\n    float _4052 = 1.0;\n    float _4053 = 0.0;\n    float _4054 = 0.0;\n    vec3 _4055 = vec3(1.0, 0.0, 0.0);\n    vec3 _4056 = vec3(0.0, 0.0, 1.0);\n    float _4057 = 1.0;\n    float _4058 = 1.0;\n    float _2075 = clamp(s.specular, 0.0, 1.0);\n    float _2079 = clamp(s.ior, 1.0, 3.0);\n    bool _2084 = (_2075 != 1.0) || (_2079 != 1.5);\n    bool _2094;\n    if (!_2084)\n    {\n        _2094 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2094 = _2084;\n    }\n    if (_2094)\n    {\n        float _2102 = (_2079 - 1.0) / (_2079 + 1.0);\n        f0 = mix(min(vec3(_2102 * _2102) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2075, s.albedo, vec3(metallic));\n        _4039 = mix(_2075, 1.0, metallic);\n        _4038 = true;\n    }\n    float _2130 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2130 > 0.0)\n    {\n        float _2138 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4042 = _2130;\n        _4043 = _2138;\n        float _2145 = _2138 * _2138;\n        _4044 = _2145;\n        _4045 = _2145 * _2145;\n        float _2157 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4047 = _2157;\n        _4040 = 1.0 - (_2130 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2157, 0.0, 1.0), 5.0))));\n        _4038 = true;\n    }\n    vec3 _2177 = max(s.sheen_color, vec3(0.0));\n    float _2186 = max(_2177.x, max(_2177.y, _2177.z));\n    if (_2186 > 0.0)\n    {\n        float _2194 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4048 = true;\n        _4049 = _2177;\n        _4050 = _2194;\n        _4051 = _2194 * _2194;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2194;\n        float _2211 = fa_sheen_albedo(param, param_1);\n        _4053 = _2211;\n        _4052 = 1.0 - min(_2186 * _2211, 1.0);\n        _4038 = true;\n    }\n    _4041 = _4040 * _4052;\n    float _2230 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2230 != 0.0)\n    {\n        vec3 _2245 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2245;\n        if (dot(_2245, _2245) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2259 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2259.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2259.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2259.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2263 = t;\n        vec3 _2264 = normalize(_2263);\n        t = _2264;\n        vec3 _2289 = normalize((_2264 * cos(s.anisotropy_rotation)) + ((cross(n, _2264) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4055 = _2289;\n        _4056 = cross(n, _2289);\n        float _2299 = roughness * roughness;\n        float _2305 = mix(_2299, 1.0, _2230 * _2230);\n        bool _2307 = _2230 > 0.0;\n        _4057 = _2307 ? _2305 : _2299;\n        _4058 = _2307 ? _2299 : _2305;\n        _4054 = _2230;\n        _4038 = true;\n    }\n    return FaLayers(_4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, i.world_normal, _4047, _4048, _4049, _4050, _4051, _4052, _4053, _4054, _4055, _4056, _4057, _4058);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _356 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _362 = fa_light_texel(param_1);\n    float _365 = _362.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _372 = _365 < 0.5;\n    vec3 l;\n    if (_372)\n    {\n        l = normalize(_356.xyz);\n    }\n    else\n    {\n        vec3 _384 = _356.xyz - world_pos;\n        float _386 = length(_384);\n        dist = _386;\n        l = _384 / vec3(max(_386, 9.9999997473787516355514526367188e-05));\n        float _401 = _386 / max(_356.w, 0.001000000047497451305389404296875);\n        float _407 = clamp(1.0 - (_401 * _401), 0.0, 1.0);\n        atten = _407 * _407;\n        if (_365 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _421 = fa_light_texel(param_2);\n            float _431 = _421.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _438 = fa_light_texel(param_3);\n            float _439 = _438.x;\n            float cos_inner = _439;\n            if (_439 > 1.5)\n            {\n                cos_inner = mix(_431, 1.0, 0.25);\n            }\n            atten *= smoothstep(_431, cos_inner, dot(-l, normalize(_421.xyz)));\n        }\n    }\n    int _470;\n    if (_372)\n    {\n        _470 = 0;\n    }\n    else\n    {\n        _470 = (_365 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _362.xyz * atten, atten, 1.0, dist, _470);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _710;\n    if (i == 0)\n    {\n        _710 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _726;\n        if (i == 1)\n        {\n            _726 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _734;\n            if (i == 2)\n            {\n                _734 = fa_shadows[24].z;\n            }\n            else\n            {\n                _734 = fa_shadows[24].w;\n            }\n            _726 = _734;\n        }\n        _710 = _726;\n    }\n    return _710;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _767 = fa_shadow_depth(param, param_1);\n    float _771;\n    if (conv.x < 0.5)\n    {\n        _771 = _767;\n    }\n    else\n    {\n        _771 = (conv.y * conv.z) / (conv.z - (_767 * (conv.z - conv.y)));\n    }\n    return _771;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _698 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_698), sin(_698)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _817 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _831 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _817;\n            vec2 _850 = fa_shadow_vogel(param_3, param_4, param_5) * _831;\n            vec2 param_6 = uv + (_850 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _862 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_862 < (zr - (length(_850) * plane)))\n            {\n                sum += _862;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _906 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _906; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _906;\n        float param_11 = _817;\n        vec2 _925 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_925 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_925) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_906);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _967 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _972 = clamp(dot(n, l), 0.0, 1.0);\n    float _978 = sqrt(1.0 - (_972 * _972));\n    float _986 = min(_978 / max(_972, 0.20000000298023223876953125), 4.0);\n    float _991;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _991 = fa_shadows[26].y;\n    }\n    else\n    {\n        _991 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1016 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_991 * _978)), 1.0);\n    float _1023 = _1016.x;\n    bool _1026 = _1023 < fa_shadows[ci * 1 + 16].x;\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _1023 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1044;\n    if (!_1035)\n    {\n        _1044 = _1016.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1044 = _1035;\n    }\n    bool _1053;\n    if (!_1044)\n    {\n        _1053 = _1016.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1053 = _1044;\n    }\n    bool _1060;\n    if (!_1053)\n    {\n        _1060 = _1016.z > 1.0;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        return -1.0;\n    }\n    float _1069;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1069 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1069 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1016.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1016.z - ((_1069 * (1.0 + (0.5 * _986))) / _967);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _967;\n    float param_5 = _967 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_986, 3.0)) * 0.5) / _967;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1463 = int(fa_shadows[25].x + 0.5);\n    if (_1463 < 1)\n    {\n        return 1.0;\n    }\n    float _1479 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1463 - 1;\n    if (_1479 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1491 = _1463 > 1;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1479 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 1;\n    }\n    bool _1502 = _1463 > 2;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1479 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 2;\n    }\n    bool _1513 = _1463 > 3;\n    bool _1520;\n    if (_1513)\n    {\n        _1520 = _1479 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    if (_1520)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1463)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1546 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1546;\n        if (_1546 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1571;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1571 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1571 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1590 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1571, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1601 = clamp((_1479 - (fa_shadow_split_at(param_7) - _1590)) / _1590, 0.0, 1.0);\n        if (_1601 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1463)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1622 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1622;\n                if (_1622 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1601);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1128 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1136;\n    if (!_1128)\n    {\n        _1136 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1136 = _1128;\n    }\n    if (_1136)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1149 = fa_light_texel(param);\n    float _1150 = _1149.x;\n    if (_1150 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1159 = int(_1150 + 0.5);\n    int param_1 = _1159;\n    vec4 _1163 = fa_light_texel(param_1);\n    int param_2 = _1159 + 1;\n    vec4 _1168 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1171 = _1163.y;\n    if (_1171 > 0.0)\n    {\n        float _1188 = 1.0 - smoothstep(0.75 * _1171, _1171, length(world - fa_shadows[27].xyz));\n        fade = _1188;\n        if (_1188 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1163.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1207 = world - fa_light_texel(param_3).xyz;\n        vec3 _1210 = abs(_1207);\n        float _1212 = _1210.x;\n        float _1214 = _1210.y;\n        bool _1215 = _1212 >= _1214;\n        bool _1223;\n        if (_1215)\n        {\n            _1223 = _1212 >= _1210.z;\n        }\n        else\n        {\n            _1223 = _1215;\n        }\n        int _1224;\n        if (_1223)\n        {\n            _1224 = (_1207.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1237;\n            if (_1214 >= _1210.z)\n            {\n                _1237 = (_1207.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1237 = (_1207.z > 0.0) ? 4 : 5;\n            }\n            _1224 = _1237;\n        }\n        face = _1224;\n    }\n    int _1256 = (_1159 + 2) + (face * 6);\n    int param_4 = _1256;\n    int param_5 = _1256 + 1;\n    int param_6 = _1256 + 3;\n    vec4 _1270 = fa_light_texel(param_6);\n    int param_7 = _1256 + 4;\n    vec4 _1275 = fa_light_texel(param_7);\n    int param_8 = _1256 + 5;\n    vec4 _1280 = fa_light_texel(param_8);\n    float _1292 = _1280.x * max(dot(_1270, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1297 = clamp(dot(n, l), 0.0, 1.0);\n    float _1303 = sqrt(1.0 - (_1297 * _1297));\n    float _1309 = min(_1303 / max(_1297, 0.20000000298023223876953125), 4.0);\n    float _1312 = _1168.y;\n    float _1314;\n    if (_1312 > 0.0)\n    {\n        _1314 = _1312;\n    }\n    else\n    {\n        _1314 = 1.5 * _1292;\n    }\n    vec4 _1334 = vec4(world + (n * (_1314 * _1303)), 1.0);\n    float _1338 = dot(_1270, _1334);\n    float _1341 = _1280.y;\n    if (_1338 < _1341)\n    {\n        return 1.0;\n    }\n    vec2 _1356 = vec2(dot(fa_light_texel(param_4), _1334), dot(fa_light_texel(param_5), _1334)) / vec2(_1338);\n    float _1358 = _1356.x;\n    bool _1361 = _1358 < _1275.x;\n    bool _1370;\n    if (!_1361)\n    {\n        _1370 = _1358 > _1275.z;\n    }\n    else\n    {\n        _1370 = _1361;\n    }\n    bool _1379;\n    if (!_1370)\n    {\n        _1379 = _1356.y < _1275.y;\n    }\n    else\n    {\n        _1379 = _1370;\n    }\n    bool _1388;\n    if (!_1379)\n    {\n        _1388 = _1356.y > _1275.w;\n    }\n    else\n    {\n        _1388 = _1379;\n    }\n    if (_1388)\n    {\n        return 1.0;\n    }\n    float _1394 = _1168.x;\n    float _1396;\n    if (_1394 > 0.0)\n    {\n        _1396 = _1394;\n    }\n    else\n    {\n        _1396 = 1.5 * _1292;\n    }\n    vec2 param_9 = _1356;\n    vec4 param_10 = _1275;\n    float param_11 = _1338 - (_1396 * (1.0 + (0.5 * _1309)));\n    float param_12 = _1292;\n    float param_13 = 1.0;\n    float param_14 = _1280.z * 0.25;\n    float param_15 = (_1292 * min(_1309, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1341, _1280.z);\n    int param_17 = int(_1163.z + 0.5);\n    float param_18 = _1163.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2842 = fa_light_sample(param, param_1);\n    vec3 _4087 = _2842.direction;\n    vec3 _4082 = _2842.color;\n    float _4089 = _2842.attenuation;\n    float _4084 = _2842.shadow;\n    int _4092 = _2842.type;\n    if ((_4092 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _4087;\n        float _2856 = fa_shadow_factor(param_2, param_3);\n        _4084 = _2856;\n        _4082 *= _2856;\n    }\n    else\n    {\n        bool _2867 = _4092 != 0;\n        bool _2873;\n        if (_2867)\n        {\n            _2873 = _4089 > 0.0;\n        }\n        else\n        {\n            _2873 = _2867;\n        }\n        if (_2873)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _4087;\n            float _2885 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _4084 = _2885;\n            _4082 *= _2885;\n        }\n    }\n    return LightSample(_4087, _4082, _4089, _4084, _2842._distance, _4092);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2457 = tdh / at;\n    float _2461 = bdh / ab;\n    float _2473 = ((_2457 * _2457) + (_2461 * _2461)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2473) * _2473);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2554 = 1.0 / alpha;\n    return ((2.0 + _2554) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2554)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2587 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2666 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2666) * _2666);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2587);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2587));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2739 = max(dot(L.nc, l), 0.0);\n        float _2745 = max(dot(L.nc, h), 0.0);\n        float _2754 = ((_2745 * _2745) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2754) * _2754)) * (0.5 / max(mix((2.0 * _2739) * L.coat_ndv, _2739 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2739)) * _2739);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1854 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1857 = _1854.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1857 * _1857, exp2((-9.27999973297119140625) * ndv)) * _1857) + _1854.y)) + _1854.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1759 = rough * rough;\n    float _1789 = 0.60000002384185791015625 * _1759;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1759)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1789, 0.0500000007450580596923828125 + _1789, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1759 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2340;\n        if (L.aniso >= 0.0)\n        {\n            _2340 = L.b;\n        }\n        else\n        {\n            _2340 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2340, v), _2340), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2373 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2373.x) + (vec3(L.f90) * _2373.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2428 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2428.x) + _2428.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1896 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1896.x) + vec3(_1896.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1646 = int(fa_shadows[25].x + 0.5);\n    float _1656 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1661 = _1646 > 0;\n    bool _1670;\n    if (_1661)\n    {\n        int param = _1646 - 1;\n        _1670 = _1656 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1670 = _1661;\n    }\n    if (_1670)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1677 = _1646 > 1;\n        bool _1684;\n        if (_1677)\n        {\n            _1684 = _1656 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1684 = _1677;\n        }\n        if (_1684)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1690 = _1646 > 2;\n        bool _1697;\n        if (_1690)\n        {\n            _1697 = _1656 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1697 = _1690;\n        }\n        if (_1697)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1703 = _1646 > 3;\n        bool _1710;\n        if (_1703)\n        {\n            _1710 = _1656 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1710 = _1703;\n        }\n        if (_1710)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3817 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3817 = -_3817;\n    }\n    vec3 _3271 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3817, fa_world_tangent, fa_uv, fa_vertex_color, _3271, gl_FrontFacing);\n    Surface _3279 = fa_standard_surface(param_1);\n    vec3 _3848 = _3279.albedo;\n    float _3849 = _3279.alpha;\n    vec3 _3850 = _3279.normal;\n    float _3851 = _3279.metallic;\n    float _3852 = _3279.roughness;\n    float _3853 = _3279.occlusion;\n    vec3 _3854 = _3279.emission;\n    float _3855 = _3279.clearcoat;\n    float _3856 = _3279.clearcoat_roughness;\n    vec3 _3857 = _3279.sheen_color;\n    float _3858 = _3279.sheen_roughness;\n    float _3859 = _3279.anisotropy;\n    float _3860 = _3279.anisotropy_rotation;\n    float _3861 = _3279.specular;\n    float _3862 = _3279.ior;\n    vec3 _3863 = _3279.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3817, fa_world_tangent, fa_uv, fa_vertex_color, _3271, gl_FrontFacing);\n    Surface param_3 = _3279;\n    surface(param_2, param_3);\n    _3848 = param_3.albedo;\n    _3849 = param_3.alpha;\n    _3850 = param_3.normal;\n    _3851 = param_3.metallic;\n    _3852 = param_3.roughness;\n    _3853 = param_3.occlusion;\n    _3854 = param_3.emission;\n    _3855 = param_3.clearcoat;\n    _3856 = param_3.clearcoat_roughness;\n    _3857 = param_3.sheen_color;\n    _3858 = param_3.sheen_roughness;\n    _3859 = param_3.anisotropy;\n    _3860 = param_3.anisotropy_rotation;\n    _3861 = param_3.specular;\n    _3862 = param_3.ior;\n    _3863 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3848;\n    }\n    else\n    {\n        vec3 _3301 = normalize(_3850);\n        float _3308 = clamp(_3851, 0.0, 1.0);\n        float _3312 = clamp(_3852, 0.0500000007450580596923828125, 1.0);\n        float _3316 = _3312 * _3312;\n        float _3320 = _3316 * _3316;\n        float _3325 = max(dot(_3301, _3271), 9.9999997473787516355514526367188e-05);\n        vec3 _3331 = _3848 * (1.0 - _3308);\n        vec3 _3338 = mix(vec3(0.039999999105930328369140625), _3848, vec3(_3308));\n        vec3 f0 = _3338;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3817, fa_world_tangent, fa_uv, fa_vertex_color, _3271, gl_FrontFacing);\n        Surface param_5 = Surface(_3848, _3849, _3850, _3851, _3852, _3853, _3854, _3855, _3856, _3857, _3858, _3859, _3860, _3861, _3862, _3863);\n        vec3 param_6 = _3301;\n        vec3 param_7 = _3271;\n        float param_8 = _3308;\n        float param_9 = _3312;\n        vec3 param_10 = _3338;\n        FaLayers _3354 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _3301;\n        vec3 lit = (fa_ambient_light(param_11) * _3331) * _3853;\n        if (_3354.on)\n        {\n            lit *= _3354.base_scale;\n        }\n        int _3376 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3376; ln++)\n        {\n            int param_12 = ln;\n            int _3389 = fa_cl_light(param_12);\n            int param_13 = _3389;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _3817;\n            LightSample _3398 = fa_light_shadowed(param_13, param_14, param_15);\n            vec3 _4022 = _3398.direction;\n            float _3406 = max(dot(_3301, _4022), 0.0);\n            float _3412 = _3398.attenuation * _3398.shadow;\n            vec3 _3417 = normalize(_4022 + _3271);\n            float _3422 = max(dot(_3301, _3417), 0.0);\n            float _3427 = max(dot(_3271, _3417), 0.0);\n            if (_3354.on)\n            {\n                FaLayers param_16 = _3354;\n                vec3 param_17 = _3331;\n                vec3 param_18 = f0;\n                vec3 param_19 = _3301;\n                vec3 param_20 = _3271;\n                vec3 param_21 = _4022;\n                vec3 param_22 = _3417;\n                float param_23 = _3406;\n                float param_24 = _3325;\n                float param_25 = _3422;\n                float param_26 = _3427;\n                float param_27 = _3316;\n                float param_28 = _3320;\n                int param_29 = _3389;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _3412));\n            }\n            else\n            {\n                float _3475 = ((_3422 * _3422) * (_3320 - 1.0)) + 1.0;\n                int param_30 = _3389;\n                lit += (((_3331 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3427, 5.0))) * (((_3320 / ((3.1415927410125732421875 * _3475) * _3475)) * (0.5 / max(mix((2.0 * _3406) * _3325, _3406 + _3325, _3316), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3406))) * fa_light_rgb(param_30)) * (_3406 * _3412));\n            }\n        }\n        if (_3354.on)\n        {\n            FaLayers param_31 = _3354;\n            vec3 param_32 = _3301;\n            vec3 param_33 = _3271;\n            vec3 param_34 = f0;\n            float param_35 = _3312;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3853);\n        }\n        else\n        {\n            vec3 param_36 = _3301;\n            vec3 param_37 = _3271;\n            vec3 param_38 = f0;\n            float param_39 = _3312;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3853);\n        }\n        result = lit;\n    }\n    vec3 _3568 = result;\n    vec3 _3569 = _3568 + _3854;\n    result = _3569;\n    vec3 param_40 = _3569;\n    vec3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3578 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3585;\n    if (!_3578)\n    {\n        _3585 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3585 = _3578;\n    }\n    if (_3585)\n    {\n        vec3 _3594 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3600 = dot(_3594, fa_mesh_fs_params[9].xyz);\n        bool _3604 = fa_mesh_fs_params[9].w > 0.5;\n        float _3605;\n        if (_3604)\n        {\n            _3605 = _3600;\n        }\n        else\n        {\n            _3605 = length(_3594);\n        }\n        float _3617 = _3605 - fa_mesh_fs_params[8].x;\n        if (_3617 > 0.0)\n        {\n            float _3626 = fa_mesh_fs_params[7].w * _3617;\n            float tau = _3626 * _3626;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3642;\n                if (_3604)\n                {\n                    _3642 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3600);\n                }\n                else\n                {\n                    _3642 = fa_mesh_fs_params[0].y;\n                }\n                float _3663 = mix(_3642, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3605, 0.0, 1.0));\n                float _3667 = fa_world_pos.y - _3663;\n                float _3672 = _3663 - fa_mesh_fs_params[8].z;\n                float _3677 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3680 = _3672 <= 0.0;\n                bool _3681 = !_3680;\n                bool _3687;\n                if (_3681)\n                {\n                    _3687 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3687 = _3680;\n                }\n                float _3688;\n                if (_3687)\n                {\n                    _3688 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3688 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3672, 80.0));\n                }\n                bool _3715;\n                if (_3681)\n                {\n                    _3715 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3715 = _3680;\n                }\n                float _3716;\n                if (_3715)\n                {\n                    _3716 = fa_mesh_fs_params[8].y * _3672;\n                }\n                else\n                {\n                    _3716 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3672, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3741 = _3677 <= 0.0;\n                bool _3748;\n                if (!_3741)\n                {\n                    _3748 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3748 = _3741;\n                }\n                float _3749;\n                if (_3748)\n                {\n                    _3749 = fa_mesh_fs_params[8].y * _3677;\n                }\n                else\n                {\n                    _3749 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3677, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3776;\n                if (abs(_3667) < 0.001000000047497451305389404296875)\n                {\n                    _3776 = _3688;\n                }\n                else\n                {\n                    _3776 = (_3749 - _3716) / _3667;\n                }\n                tau += (_3617 * max(_3776, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3849);\n}\n\n",
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
            "inst_name": "_168",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_238",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_484",
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
            "inst_name": "_720",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1997[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _489 = fa_mesh_fs_params[19].x < 0.0;\n    bool _496;\n    if (!_489)\n    {\n        _496 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _496 = _489;\n    }\n    bool _504;\n    if (!_496)\n    {\n        _504 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _504 = _496;\n    }\n    bool _511;\n    if (!_504)\n    {\n        _511 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _511 = _504;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    if (_518)\n    {\n        return ivec2(0);\n    }\n    vec4 _528 = vec4(world_pos, 1.0);\n    float _535 = dot(fa_mesh_fs_params[16], _528);\n    if (!(_535 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _557 = vec2(dot(fa_mesh_fs_params[14], _528), dot(fa_mesh_fs_params[15], _528)) / vec2(_535);\n    int _561 = int(fa_mesh_fs_params[18].x);\n    int _565 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _565) + clamp(int(floor(((_557.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _565 - 1)) * _561)) + clamp(int(floor(((_557.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _561 - 1);\n    vec4 _636 = fa_light_texel(param);\n    return ivec2(int(_636.x), int(_636.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2814 = fa_cluster_lookup(param);\n    fa_cl_slot = _2814.x;\n    fa_cl_local = _2814.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2958 = fa_linear_to_srgb(param);\n        c = _2958;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2966 = fa_srgb_to_linear(param_1);\n            c = _2966;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _256;\n    if (i.front_facing)\n    {\n        _256 = i.world_normal;\n    }\n    else\n    {\n        _256 = -i.world_normal;\n    }\n    vec3 _280 = normalize(i.world_tangent.xyz - (_256 * dot(_256, i.world_tangent.xyz)));\n    vec3 _308 = normalize(((_280 * m.x) + ((cross(_256, _280) * i.world_tangent.w) * m.y)) + (_256 * m.z));\n    vec3 _311;\n    if (i.front_facing)\n    {\n        _311 = _308;\n    }\n    else\n    {\n        _311 = -_308;\n    }\n    return _311;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2997 = fa_tex_fix(param_2, param_3);\n    vec4 _4200 = base_t;\n    _4200.x = _2997.x;\n    _4200.y = _2997.y;\n    _4200.z = _2997.z;\n    base_t = _4200;\n    vec4 _3011 = (_4200 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4102 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3043 = fa_tex_fix(param_6, param_7);\n        vec3 _3046 = (_3043 * 2.0) - vec3(1.0);\n        vec2 _3051 = _3046.xy * fa_mesh_fs_params[6].x;\n        vec3 _4208 = _3046;\n        _4208.x = _3051.x;\n        _4208.y = _3051.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4208;\n        _4102 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3080 = fa_tex_fix(param_12, param_13);\n    vec4 _4211 = mrt;\n    _4211.x = _3080.x;\n    _4211.y = _3080.y;\n    _4211.z = _3080.z;\n    mrt = _4211;\n    vec4 _3108 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3108.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3120 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3150 = fa_tex_fix(param_20, param_21);\n    float _4107 = fa_mesh_fs_params[20].x;\n    float _4108 = fa_mesh_fs_params[20].y;\n    float _4111 = fa_mesh_fs_params[20].z;\n    float _4110 = fa_mesh_fs_params[21].w;\n    float _4113 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4107 *= _3120.y;\n            _4108 *= _3120.z;\n            _4110 *= _3108.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4111 *= mrt.x;\n            _4113 *= mrt.w;\n        }\n    }\n    return Surface(_3011.xyz, _3011.w, _4102, clamp(fa_mesh_fs_params[5].x * _3080.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3080.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3120.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3150), _4107, _4108, fa_mesh_fs_params[21].xyz, _4110, _4111, fa_mesh_fs_params[20].w, _4113, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1922 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1930 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1933 = int(_1922);\n    int _1936 = int(_1930);\n    float _1946 = _1930 - float(_1936);\n    int _2002 = (_1933 * 9) + _1936;\n    int _2022 = ((_1933 + 1) * 9) + _1936;\n    return mix(mix(_1997[_2002], _1997[_2002 + 1], _1946), mix(_1997[_2022], _1997[_2022 + 1], _1946), _1922 - float(_1933));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4038 = false;\n    float _4039 = 1.0;\n    float _4040 = 1.0;\n    float _4041 = 1.0;\n    float _4042 = 0.0;\n    float _4043 = 0.0;\n    float _4044 = 0.0;\n    float _4045 = 0.0;\n    float _4047 = 1.0;\n    bool _4048 = false;\n    vec3 _4049 = vec3(0.0);\n    float _4050 = 1.0;\n    float _4051 = 1.0;\n    float _4052 = 1.0;\n    float _4053 = 0.0;\n    float _4054 = 0.0;\n    vec3 _4055 = vec3(1.0, 0.0, 0.0);\n    vec3 _4056 = vec3(0.0, 0.0, 1.0);\n    float _4057 = 1.0;\n    float _4058 = 1.0;\n    float _2075 = clamp(s.specular, 0.0, 1.0);\n    float _2079 = clamp(s.ior, 1.0, 3.0);\n    bool _2084 = (_2075 != 1.0) || (_2079 != 1.5);\n    bool _2094;\n    if (!_2084)\n    {\n        _2094 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2094 = _2084;\n    }\n    if (_2094)\n    {\n        float _2102 = (_2079 - 1.0) / (_2079 + 1.0);\n        f0 = mix(min(vec3(_2102 * _2102) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2075, s.albedo, vec3(metallic));\n        _4039 = mix(_2075, 1.0, metallic);\n        _4038 = true;\n    }\n    float _2130 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2130 > 0.0)\n    {\n        float _2138 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4042 = _2130;\n        _4043 = _2138;\n        float _2145 = _2138 * _2138;\n        _4044 = _2145;\n        _4045 = _2145 * _2145;\n        float _2157 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4047 = _2157;\n        _4040 = 1.0 - (_2130 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2157, 0.0, 1.0), 5.0))));\n        _4038 = true;\n    }\n    vec3 _2177 = max(s.sheen_color, vec3(0.0));\n    float _2186 = max(_2177.x, max(_2177.y, _2177.z));\n    if (_2186 > 0.0)\n    {\n        float _2194 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4048 = true;\n        _4049 = _2177;\n        _4050 = _2194;\n        _4051 = _2194 * _2194;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2194;\n        float _2211 = fa_sheen_albedo(param, param_1);\n        _4053 = _2211;\n        _4052 = 1.0 - min(_2186 * _2211, 1.0);\n        _4038 = true;\n    }\n    _4041 = _4040 * _4052;\n    float _2230 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2230 != 0.0)\n    {\n        vec3 _2245 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2245;\n        if (dot(_2245, _2245) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2259 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2259.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2259.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2259.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2263 = t;\n        vec3 _2264 = normalize(_2263);\n        t = _2264;\n        vec3 _2289 = normalize((_2264 * cos(s.anisotropy_rotation)) + ((cross(n, _2264) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4055 = _2289;\n        _4056 = cross(n, _2289);\n        float _2299 = roughness * roughness;\n        float _2305 = mix(_2299, 1.0, _2230 * _2230);\n        bool _2307 = _2230 > 0.0;\n        _4057 = _2307 ? _2305 : _2299;\n        _4058 = _2307 ? _2299 : _2305;\n        _4054 = _2230;\n        _4038 = true;\n    }\n    return FaLayers(_4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, i.world_normal, _4047, _4048, _4049, _4050, _4051, _4052, _4053, _4054, _4055, _4056, _4057, _4058);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _356 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _362 = fa_light_texel(param_1);\n    float _365 = _362.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _372 = _365 < 0.5;\n    vec3 l;\n    if (_372)\n    {\n        l = normalize(_356.xyz);\n    }\n    else\n    {\n        vec3 _384 = _356.xyz - world_pos;\n        float _386 = length(_384);\n        dist = _386;\n        l = _384 / vec3(max(_386, 9.9999997473787516355514526367188e-05));\n        float _401 = _386 / max(_356.w, 0.001000000047497451305389404296875);\n        float _407 = clamp(1.0 - (_401 * _401), 0.0, 1.0);\n        atten = _407 * _407;\n        if (_365 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _421 = fa_light_texel(param_2);\n            float _431 = _421.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _438 = fa_light_texel(param_3);\n            float _439 = _438.x;\n            float cos_inner = _439;\n            if (_439 > 1.5)\n            {\n                cos_inner = mix(_431, 1.0, 0.25);\n            }\n            atten *= smoothstep(_431, cos_inner, dot(-l, normalize(_421.xyz)));\n        }\n    }\n    int _470;\n    if (_372)\n    {\n        _470 = 0;\n    }\n    else\n    {\n        _470 = (_365 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _362.xyz * atten, atten, 1.0, dist, _470);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _710;\n    if (i == 0)\n    {\n        _710 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _726;\n        if (i == 1)\n        {\n            _726 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _734;\n            if (i == 2)\n            {\n                _734 = fa_shadows[24].z;\n            }\n            else\n            {\n                _734 = fa_shadows[24].w;\n            }\n            _726 = _734;\n        }\n        _710 = _726;\n    }\n    return _710;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _767 = fa_shadow_depth(param, param_1);\n    float _771;\n    if (conv.x < 0.5)\n    {\n        _771 = _767;\n    }\n    else\n    {\n        _771 = (conv.y * conv.z) / (conv.z - (_767 * (conv.z - conv.y)));\n    }\n    return _771;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _698 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_698), sin(_698)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _817 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _831 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _817;\n            vec2 _850 = fa_shadow_vogel(param_3, param_4, param_5) * _831;\n            vec2 param_6 = uv + (_850 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _862 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_862 < (zr - (length(_850) * plane)))\n            {\n                sum += _862;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _906 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _906; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _906;\n        float param_11 = _817;\n        vec2 _925 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_925 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_925) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_906);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _967 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _972 = clamp(dot(n, l), 0.0, 1.0);\n    float _978 = sqrt(1.0 - (_972 * _972));\n    float _986 = min(_978 / max(_972, 0.20000000298023223876953125), 4.0);\n    float _991;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _991 = fa_shadows[26].y;\n    }\n    else\n    {\n        _991 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1016 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_991 * _978)), 1.0);\n    float _1023 = _1016.x;\n    bool _1026 = _1023 < fa_shadows[ci * 1 + 16].x;\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _1023 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1044;\n    if (!_1035)\n    {\n        _1044 = _1016.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1044 = _1035;\n    }\n    bool _1053;\n    if (!_1044)\n    {\n        _1053 = _1016.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1053 = _1044;\n    }\n    bool _1060;\n    if (!_1053)\n    {\n        _1060 = _1016.z > 1.0;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        return -1.0;\n    }\n    float _1069;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1069 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1069 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1016.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1016.z - ((_1069 * (1.0 + (0.5 * _986))) / _967);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _967;\n    float param_5 = _967 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_986, 3.0)) * 0.5) / _967;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1463 = int(fa_shadows[25].x + 0.5);\n    if (_1463 < 1)\n    {\n        return 1.0;\n    }\n    float _1479 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1463 - 1;\n    if (_1479 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1491 = _1463 > 1;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1479 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 1;\n    }\n    bool _1502 = _1463 > 2;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1479 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 2;\n    }\n    bool _1513 = _1463 > 3;\n    bool _1520;\n    if (_1513)\n    {\n        _1520 = _1479 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    if (_1520)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1463)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1546 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1546;\n        if (_1546 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1571;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1571 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1571 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1590 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1571, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1601 = clamp((_1479 - (fa_shadow_split_at(param_7) - _1590)) / _1590, 0.0, 1.0);\n        if (_1601 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1463)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1622 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1622;\n                if (_1622 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1601);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1128 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1136;\n    if (!_1128)\n    {\n        _1136 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1136 = _1128;\n    }\n    if (_1136)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1149 = fa_light_texel(param);\n    float _1150 = _1149.x;\n    if (_1150 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1159 = int(_1150 + 0.5);\n    int param_1 = _1159;\n    vec4 _1163 = fa_light_texel(param_1);\n    int param_2 = _1159 + 1;\n    vec4 _1168 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1171 = _1163.y;\n    if (_1171 > 0.0)\n    {\n        float _1188 = 1.0 - smoothstep(0.75 * _1171, _1171, length(world - fa_shadows[27].xyz));\n        fade = _1188;\n        if (_1188 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1163.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1207 = world - fa_light_texel(param_3).xyz;\n        vec3 _1210 = abs(_1207);\n        float _1212 = _1210.x;\n        float _1214 = _1210.y;\n        bool _1215 = _1212 >= _1214;\n        bool _1223;\n        if (_1215)\n        {\n            _1223 = _1212 >= _1210.z;\n        }\n        else\n        {\n            _1223 = _1215;\n        }\n        int _1224;\n        if (_1223)\n        {\n            _1224 = (_1207.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1237;\n            if (_1214 >= _1210.z)\n            {\n                _1237 = (_1207.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1237 = (_1207.z > 0.0) ? 4 : 5;\n            }\n            _1224 = _1237;\n        }\n        face = _1224;\n    }\n    int _1256 = (_1159 + 2) + (face * 6);\n    int param_4 = _1256;\n    int param_5 = _1256 + 1;\n    int param_6 = _1256 + 3;\n    vec4 _1270 = fa_light_texel(param_6);\n    int param_7 = _1256 + 4;\n    vec4 _1275 = fa_light_texel(param_7);\n    int param_8 = _1256 + 5;\n    vec4 _1280 = fa_light_texel(param_8);\n    float _1292 = _1280.x * max(dot(_1270, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1297 = clamp(dot(n, l), 0.0, 1.0);\n    float _1303 = sqrt(1.0 - (_1297 * _1297));\n    float _1309 = min(_1303 / max(_1297, 0.20000000298023223876953125), 4.0);\n    float _1312 = _1168.y;\n    float _1314;\n    if (_1312 > 0.0)\n    {\n        _1314 = _1312;\n    }\n    else\n    {\n        _1314 = 1.5 * _1292;\n    }\n    vec4 _1334 = vec4(world + (n * (_1314 * _1303)), 1.0);\n    float _1338 = dot(_1270, _1334);\n    float _1341 = _1280.y;\n    if (_1338 < _1341)\n    {\n        return 1.0;\n    }\n    vec2 _1356 = vec2(dot(fa_light_texel(param_4), _1334), dot(fa_light_texel(param_5), _1334)) / vec2(_1338);\n    float _1358 = _1356.x;\n    bool _1361 = _1358 < _1275.x;\n    bool _1370;\n    if (!_1361)\n    {\n        _1370 = _1358 > _1275.z;\n    }\n    else\n    {\n        _1370 = _1361;\n    }\n    bool _1379;\n    if (!_1370)\n    {\n        _1379 = _1356.y < _1275.y;\n    }\n    else\n    {\n        _1379 = _1370;\n    }\n    bool _1388;\n    if (!_1379)\n    {\n        _1388 = _1356.y > _1275.w;\n    }\n    else\n    {\n        _1388 = _1379;\n    }\n    if (_1388)\n    {\n        return 1.0;\n    }\n    float _1394 = _1168.x;\n    float _1396;\n    if (_1394 > 0.0)\n    {\n        _1396 = _1394;\n    }\n    else\n    {\n        _1396 = 1.5 * _1292;\n    }\n    vec2 param_9 = _1356;\n    vec4 param_10 = _1275;\n    float param_11 = _1338 - (_1396 * (1.0 + (0.5 * _1309)));\n    float param_12 = _1292;\n    float param_13 = 1.0;\n    float param_14 = _1280.z * 0.25;\n    float param_15 = (_1292 * min(_1309, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1341, _1280.z);\n    int param_17 = int(_1163.z + 0.5);\n    float param_18 = _1163.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2842 = fa_light_sample(param, param_1);\n    vec3 _4087 = _2842.direction;\n    vec3 _4082 = _2842.color;\n    float _4089 = _2842.attenuation;\n    float _4084 = _2842.shadow;\n    int _4092 = _2842.type;\n    if ((_4092 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _4087;\n        float _2856 = fa_shadow_factor(param_2, param_3);\n        _4084 = _2856;\n        _4082 *= _2856;\n    }\n    else\n    {\n        bool _2867 = _4092 != 0;\n        bool _2873;\n        if (_2867)\n        {\n            _2873 = _4089 > 0.0;\n        }\n        else\n        {\n            _2873 = _2867;\n        }\n        if (_2873)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _4087;\n            float _2885 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _4084 = _2885;\n            _4082 *= _2885;\n        }\n    }\n    return LightSample(_4087, _4082, _4089, _4084, _2842._distance, _4092);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2457 = tdh / at;\n    float _2461 = bdh / ab;\n    float _2473 = ((_2457 * _2457) + (_2461 * _2461)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2473) * _2473);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2554 = 1.0 / alpha;\n    return ((2.0 + _2554) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2554)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2587 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2666 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2666) * _2666);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2587);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2587));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2739 = max(dot(L.nc, l), 0.0);\n        float _2745 = max(dot(L.nc, h), 0.0);\n        float _2754 = ((_2745 * _2745) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2754) * _2754)) * (0.5 / max(mix((2.0 * _2739) * L.coat_ndv, _2739 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2739)) * _2739);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1854 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1857 = _1854.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1857 * _1857, exp2((-9.27999973297119140625) * ndv)) * _1857) + _1854.y)) + _1854.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1759 = rough * rough;\n    float _1789 = 0.60000002384185791015625 * _1759;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1759)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1789, 0.0500000007450580596923828125 + _1789, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1759 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2340;\n        if (L.aniso >= 0.0)\n        {\n            _2340 = L.b;\n        }\n        else\n        {\n            _2340 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2340, v), _2340), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2373 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2373.x) + (vec3(L.f90) * _2373.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2428 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2428.x) + _2428.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1896 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1896.x) + vec3(_1896.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1646 = int(fa_shadows[25].x + 0.5);\n    float _1656 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1661 = _1646 > 0;\n    bool _1670;\n    if (_1661)\n    {\n        int param = _1646 - 1;\n        _1670 = _1656 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1670 = _1661;\n    }\n    if (_1670)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1677 = _1646 > 1;\n        bool _1684;\n        if (_1677)\n        {\n            _1684 = _1656 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1684 = _1677;\n        }\n        if (_1684)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1690 = _1646 > 2;\n        bool _1697;\n        if (_1690)\n        {\n            _1697 = _1656 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1697 = _1690;\n        }\n        if (_1697)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1703 = _1646 > 3;\n        bool _1710;\n        if (_1703)\n        {\n            _1710 = _1656 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1710 = _1703;\n        }\n        if (_1710)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3817 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3817 = -_3817;\n    }\n    vec3 _3271 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3817, fa_world_tangent, fa_uv, fa_vertex_color, _3271, gl_FrontFacing);\n    Surface _3279 = fa_standard_surface(param_1);\n    vec3 _3848 = _3279.albedo;\n    float _3849 = _3279.alpha;\n    vec3 _3850 = _3279.normal;\n    float _3851 = _3279.metallic;\n    float _3852 = _3279.roughness;\n    float _3853 = _3279.occlusion;\n    vec3 _3854 = _3279.emission;\n    float _3855 = _3279.clearcoat;\n    float _3856 = _3279.clearcoat_roughness;\n    vec3 _3857 = _3279.sheen_color;\n    float _3858 = _3279.sheen_roughness;\n    float _3859 = _3279.anisotropy;\n    float _3860 = _3279.anisotropy_rotation;\n    float _3861 = _3279.specular;\n    float _3862 = _3279.ior;\n    vec3 _3863 = _3279.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3817, fa_world_tangent, fa_uv, fa_vertex_color, _3271, gl_FrontFacing);\n    Surface param_3 = _3279;\n    surface(param_2, param_3);\n    _3848 = param_3.albedo;\n    _3849 = param_3.alpha;\n    _3850 = param_3.normal;\n    _3851 = param_3.metallic;\n    _3852 = param_3.roughness;\n    _3853 = param_3.occlusion;\n    _3854 = param_3.emission;\n    _3855 = param_3.clearcoat;\n    _3856 = param_3.clearcoat_roughness;\n    _3857 = param_3.sheen_color;\n    _3858 = param_3.sheen_roughness;\n    _3859 = param_3.anisotropy;\n    _3860 = param_3.anisotropy_rotation;\n    _3861 = param_3.specular;\n    _3862 = param_3.ior;\n    _3863 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3848;\n    }\n    else\n    {\n        vec3 _3301 = normalize(_3850);\n        float _3308 = clamp(_3851, 0.0, 1.0);\n        float _3312 = clamp(_3852, 0.0500000007450580596923828125, 1.0);\n        float _3316 = _3312 * _3312;\n        float _3320 = _3316 * _3316;\n        float _3325 = max(dot(_3301, _3271), 9.9999997473787516355514526367188e-05);\n        vec3 _3331 = _3848 * (1.0 - _3308);\n        vec3 _3338 = mix(vec3(0.039999999105930328369140625), _3848, vec3(_3308));\n        vec3 f0 = _3338;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3817, fa_world_tangent, fa_uv, fa_vertex_color, _3271, gl_FrontFacing);\n        Surface param_5 = Surface(_3848, _3849, _3850, _3851, _3852, _3853, _3854, _3855, _3856, _3857, _3858, _3859, _3860, _3861, _3862, _3863);\n        vec3 param_6 = _3301;\n        vec3 param_7 = _3271;\n        float param_8 = _3308;\n        float param_9 = _3312;\n        vec3 param_10 = _3338;\n        FaLayers _3354 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _3301;\n        vec3 lit = (fa_ambient_light(param_11) * _3331) * _3853;\n        if (_3354.on)\n        {\n            lit *= _3354.base_scale;\n        }\n        int _3376 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3376; ln++)\n        {\n            int param_12 = ln;\n            int _3389 = fa_cl_light(param_12);\n            int param_13 = _3389;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _3817;\n            LightSample _3398 = fa_light_shadowed(param_13, param_14, param_15);\n            vec3 _4022 = _3398.direction;\n            float _3406 = max(dot(_3301, _4022), 0.0);\n            float _3412 = _3398.attenuation * _3398.shadow;\n            vec3 _3417 = normalize(_4022 + _3271);\n            float _3422 = max(dot(_3301, _3417), 0.0);\n            float _3427 = max(dot(_3271, _3417), 0.0);\n            if (_3354.on)\n            {\n                FaLayers param_16 = _3354;\n                vec3 param_17 = _3331;\n                vec3 param_18 = f0;\n                vec3 param_19 = _3301;\n                vec3 param_20 = _3271;\n                vec3 param_21 = _4022;\n                vec3 param_22 = _3417;\n                float param_23 = _3406;\n                float param_24 = _3325;\n                float param_25 = _3422;\n                float param_26 = _3427;\n                float param_27 = _3316;\n                float param_28 = _3320;\n                int param_29 = _3389;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _3412));\n            }\n            else\n            {\n                float _3475 = ((_3422 * _3422) * (_3320 - 1.0)) + 1.0;\n                int param_30 = _3389;\n                lit += (((_3331 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3427, 5.0))) * (((_3320 / ((3.1415927410125732421875 * _3475) * _3475)) * (0.5 / max(mix((2.0 * _3406) * _3325, _3406 + _3325, _3316), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3406))) * fa_light_rgb(param_30)) * (_3406 * _3412));\n            }\n        }\n        if (_3354.on)\n        {\n            FaLayers param_31 = _3354;\n            vec3 param_32 = _3301;\n            vec3 param_33 = _3271;\n            vec3 param_34 = f0;\n            float param_35 = _3312;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3853);\n        }\n        else\n        {\n            vec3 param_36 = _3301;\n            vec3 param_37 = _3271;\n            vec3 param_38 = f0;\n            float param_39 = _3312;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3853);\n        }\n        result = lit;\n    }\n    vec3 _3568 = result;\n    vec3 _3569 = _3568 + _3854;\n    result = _3569;\n    vec3 param_40 = _3569;\n    vec3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3578 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3585;\n    if (!_3578)\n    {\n        _3585 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3585 = _3578;\n    }\n    if (_3585)\n    {\n        vec3 _3594 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3600 = dot(_3594, fa_mesh_fs_params[9].xyz);\n        bool _3604 = fa_mesh_fs_params[9].w > 0.5;\n        float _3605;\n        if (_3604)\n        {\n            _3605 = _3600;\n        }\n        else\n        {\n            _3605 = length(_3594);\n        }\n        float _3617 = _3605 - fa_mesh_fs_params[8].x;\n        if (_3617 > 0.0)\n        {\n            float _3626 = fa_mesh_fs_params[7].w * _3617;\n            float tau = _3626 * _3626;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3642;\n                if (_3604)\n                {\n                    _3642 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3600);\n                }\n                else\n                {\n                    _3642 = fa_mesh_fs_params[0].y;\n                }\n                float _3663 = mix(_3642, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3605, 0.0, 1.0));\n                float _3667 = fa_world_pos.y - _3663;\n                float _3672 = _3663 - fa_mesh_fs_params[8].z;\n                float _3677 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3680 = _3672 <= 0.0;\n                bool _3681 = !_3680;\n                bool _3687;\n                if (_3681)\n                {\n                    _3687 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3687 = _3680;\n                }\n                float _3688;\n                if (_3687)\n                {\n                    _3688 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3688 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3672, 80.0));\n                }\n                bool _3715;\n                if (_3681)\n                {\n                    _3715 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3715 = _3680;\n                }\n                float _3716;\n                if (_3715)\n                {\n                    _3716 = fa_mesh_fs_params[8].y * _3672;\n                }\n                else\n                {\n                    _3716 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3672, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3741 = _3677 <= 0.0;\n                bool _3748;\n                if (!_3741)\n                {\n                    _3748 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3748 = _3741;\n                }\n                float _3749;\n                if (_3748)\n                {\n                    _3749 = fa_mesh_fs_params[8].y * _3677;\n                }\n                else\n                {\n                    _3749 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3677, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3776;\n                if (abs(_3667) < 0.001000000047497451305389404296875)\n                {\n                    _3776 = _3688;\n                }\n                else\n                {\n                    _3776 = (_3749 - _3716) / _3667;\n                }\n                tau += (_3617 * max(_3776, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3849);\n}\n\n",
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
            "inst_name": "_173",
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
            "inst_name": "_217",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_350",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_484",
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
            "inst_name": "_720",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _203 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _210 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_203 * _210).z;\n    fa_pre_r0 = vec3(_203[0].x, _203[1].x, _203[2].x);\n    fa_pre_r1 = vec3(_203[0].y, _203[1].y, _203[2].y);\n    fa_pre_r2 = vec3(_203[0].z, _203[1].z, _203[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _210;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _748 = base_t;\n    _748.x = _242.x;\n    _748.y = _242.y;\n    _748.z = _242.z;\n    base_t = _748;\n    vec4 _257 = (_748 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _711 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _756 = _294;\n        _756.x = _299.x;\n        _756.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _756;\n        _711 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _759 = mrt;\n    _759.x = _328.x;\n    _759.y = _328.y;\n    _759.z = _328.z;\n    mrt = _759;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _716 = fa_mesh_fs_params[20].x;\n    float _717 = fa_mesh_fs_params[20].y;\n    float _720 = fa_mesh_fs_params[20].z;\n    float _719 = fa_mesh_fs_params[21].w;\n    float _722 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _716 *= _370.y;\n            _717 *= _370.z;\n            _719 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _720 *= mrt.x;\n            _722 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _711, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _716, _717, fa_mesh_fs_params[21].xyz, _719, _720, fa_mesh_fs_params[20].w, _722, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _622 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _622 = -_622;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _622, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _622, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_168",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_272",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _315 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _322 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_315 * _322).z;\n    fa_pre_r0 = vec3(_315[0].x, _315[1].x, _315[2].x);\n    fa_pre_r1 = vec3(_315[0].y, _315[1].y, _315[2].y);\n    fa_pre_r2 = vec3(_315[0].z, _315[1].z, _315[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _322;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _748 = base_t;\n    _748.x = _242.x;\n    _748.y = _242.y;\n    _748.z = _242.z;\n    base_t = _748;\n    vec4 _257 = (_748 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _711 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _756 = _294;\n        _756.x = _299.x;\n        _756.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _756;\n        _711 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _759 = mrt;\n    _759.x = _328.x;\n    _759.y = _328.y;\n    _759.z = _328.z;\n    mrt = _759;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _716 = fa_mesh_fs_params[20].x;\n    float _717 = fa_mesh_fs_params[20].y;\n    float _720 = fa_mesh_fs_params[20].z;\n    float _719 = fa_mesh_fs_params[21].w;\n    float _722 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _716 *= _370.y;\n            _717 *= _370.z;\n            _719 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _720 *= mrt.x;\n            _722 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _711, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _716, _717, fa_mesh_fs_params[21].xyz, _719, _720, fa_mesh_fs_params[20].w, _722, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _622 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _622 = -_622;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _622, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _622, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_173",
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
            "inst_name": "_217",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_384",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_159",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_176",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          }
        ],
        "views": [
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
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_199 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_199 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_199 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_164",
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
            "inst_name": "_208",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_288",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          }
        ],
        "views": [
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
          }
        ]
      }
    }
  }
}
