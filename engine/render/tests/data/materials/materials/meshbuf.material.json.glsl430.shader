{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2739[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _552 = fa_mesh_fs_params[19].x < 0.0;\n    bool _559;\n    if (!_552)\n    {\n        _559 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _559 = _552;\n    }\n    bool _567;\n    if (!_559)\n    {\n        _567 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _567 = _559;\n    }\n    bool _574;\n    if (!_567)\n    {\n        _574 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _574 = _567;\n    }\n    bool _581;\n    if (!_574)\n    {\n        _581 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _581 = _574;\n    }\n    if (_581)\n    {\n        return vec4(0.0);\n    }\n    vec4 _591 = vec4(world_pos, 1.0);\n    float _598 = dot(fa_mesh_fs_params[16], _591);\n    if (!(_598 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _620 = vec2(dot(fa_mesh_fs_params[14], _591), dot(fa_mesh_fs_params[15], _591)) / vec2(_598);\n    int _624 = int(fa_mesh_fs_params[18].x);\n    int _628 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _628) + clamp(int(floor(((_620.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _628 - 1)) * _624)) + clamp(int(floor(((_620.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _624 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _704 = fa_cluster_texel(param);\n    return ivec2(int(_704.x), int(_704.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3552 = fa_cluster_lookup(param);\n    fa_cl_slot = _3552.x;\n    fa_cl_local = _3552.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3712 = fa_linear_to_srgb(param);\n        c = _3712;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3720 = fa_srgb_to_linear(param_1);\n            c = _3720;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _303;\n    if (i.front_facing)\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    vec3 _327 = normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    vec3 _354 = normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    vec3 _357;\n    if (i.front_facing)\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3751 = fa_tex_fix(param_2, param_3);\n    vec4 _5050 = base_t;\n    _5050.x = _3751.x;\n    _5050.y = _3751.y;\n    _5050.z = _3751.z;\n    base_t = _5050;\n    vec4 _3765 = (_5050 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4917 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3797 = fa_tex_fix(param_6, param_7);\n        vec3 _3800 = (_3797 * 2.0) - vec3(1.0);\n        vec2 _3805 = _3800.xy * fa_mesh_fs_params[6].x;\n        vec3 _5058 = _3800;\n        _5058.x = _3805.x;\n        _5058.y = _3805.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5058;\n        _4917 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3834 = fa_tex_fix(param_12, param_13);\n    vec4 _5061 = mrt;\n    _5061.x = _3834.x;\n    _5061.y = _3834.y;\n    _5061.z = _3834.z;\n    mrt = _5061;\n    vec4 _3862 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3862.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3874 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3904 = fa_tex_fix(param_20, param_21);\n    float _4922 = fa_mesh_fs_params[20].x;\n    float _4923 = fa_mesh_fs_params[20].y;\n    float _4926 = fa_mesh_fs_params[20].z;\n    float _4925 = fa_mesh_fs_params[21].w;\n    float _4928 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4922 *= _3874.y;\n            _4923 *= _3874.z;\n            _4925 *= _3862.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4926 *= mrt.x;\n            _4928 *= mrt.w;\n        }\n    }\n    return Surface(_3765.xyz, _3765.w, _4917, clamp(fa_mesh_fs_params[5].x * _3834.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3834.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3874.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3904), _4922, _4923, fa_mesh_fs_params[21].xyz, _4925, _4926, fa_mesh_fs_params[20].w, _4928, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _785 = rect.zw - rect.xy;\n    vec2 _789 = _785 * atlas;\n    vec2 _793 = ddx * _789;\n    vec2 _797 = ddy * _789;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _785), clamp(0.5 * log2(max(max(dot(_793, _793), dot(_797, _797)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _832 = fa_mesh_fs_params[10].y < 0.5;\n    bool _839;\n    if (!_832)\n    {\n        _839 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _839 = _832;\n    }\n    if (_839)\n    {\n        return;\n    }\n    vec3 _845 = dFdx(world_pos);\n    vec3 _848 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _852 = fa_cluster_texel(param);\n    int _856 = int(_852.w);\n    if (_856 < 1)\n    {\n        return;\n    }\n    int _866 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _866;\n    vec4 _870 = fa_light_texel(param_1);\n    vec2 _873 = _870.yz;\n    int _877 = int(_870.w);\n    int param_2 = _866 + 1;\n    vec4 _882 = fa_light_texel(param_2);\n    float _883 = _882.x;\n    int _889 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _893 = int(_852.z);\n    vec3 _1159;\n    for (int k = 0; k < _856; k++)\n    {\n        int _906 = _893 + k;\n        int param_3 = _877 + (_906 >> 2);\n        int _924 = (_866 + 2) + (int(fa_light_texel(param_3)[_906 & 3]) * 7);\n        int param_4 = _924 + 6;\n        vec4 _929 = fa_light_texel(param_4);\n        if (((int(_929.w + 0.5) >> _889) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _924;\n        vec4 _944 = fa_light_texel(param_5);\n        int param_6 = _924 + 1;\n        vec4 _949 = fa_light_texel(param_6);\n        int param_7 = _924 + 2;\n        vec4 _954 = fa_light_texel(param_7);\n        vec3 _957 = _944.xyz;\n        float _962 = dot(_957, world_pos) + _944.w;\n        vec3 _964 = _949.xyz;\n        float _969 = dot(_964, world_pos) + _949.w;\n        vec3 _971 = _954.xyz;\n        float _976 = dot(_971, world_pos) + _954.w;\n        bool _981 = abs(_962) > 0.5;\n        bool _989;\n        if (!_981)\n        {\n            _989 = abs(_969) > 0.5;\n        }\n        else\n        {\n            _989 = _981;\n        }\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_976) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        if (_997)\n        {\n            continue;\n        }\n        float _1012 = clamp(dot(geo_normal, normalize(_971)) * _929.z, 0.0, 1.0);\n        if (_1012 <= 0.0)\n        {\n            continue;\n        }\n        float _1032 = (clamp((0.5 - abs(_976)) * 10.0, 0.0, 1.0) * _1012) * _929.x;\n        vec2 _1040 = vec2(_962 + 0.5, 0.5 - _969);\n        vec2 _1050 = vec2(dot(_957, _845), dot(_964, _845));\n        vec2 _1060 = vec2(dot(_957, _848), dot(_964, _848));\n        int param_8 = _924 + 5;\n        vec4 _1065 = fa_light_texel(param_8);\n        int param_9 = _924 + 3;\n        vec4 _1070 = fa_light_texel(param_9);\n        int param_10 = _924 + 4;\n        vec4 _1075 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1065.xyz;\n        bool _1085 = _1070.z > _1070.x;\n        if (_1085)\n        {\n            vec4 param_11 = _1070;\n            vec2 param_12 = _1040;\n            vec2 param_13 = _873;\n            vec2 param_14 = _1050;\n            vec2 param_15 = _1060;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_883 > 0.5) && (_883 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1111 = fa_dc_to_linear(param_16);\n                vec4 _4973 = tx;\n                _4973.x = _1111.x;\n                _4973.y = _1111.y;\n                _4973.z = _1111.z;\n                tx = _4973;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1032 * tex_a) * _1065.w, 0.0, 1.0)));\n        if (_1075.z > _1075.x)\n        {\n            vec4 param_17 = _1075;\n            vec2 param_18 = _1040;\n            vec2 param_19 = _873;\n            vec2 param_20 = _1050;\n            vec2 param_21 = _1060;\n            vec4 _1155 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_883 > 1.5)\n            {\n                vec3 param_22 = _1155.xyz;\n                vec3 _1165 = fa_dc_to_srgb(param_22);\n                _1159 = _1165;\n            }\n            else\n            {\n                _1159 = _1155.xyz;\n            }\n            vec3 _1175 = (_1159 * 2.0) - vec3(1.0);\n            vec2 _1180 = _1175.xy * _929.y;\n            vec3 _1202 = (normalize(_957) * _1180.x) + (normalize(_964) * _1180.y);\n            vec3 _1205 = normalize(normal);\n            normal = normalize(mix(_1205, normalize((_1205 * max(_1175.z, 0.0500000007450580596923828125)) + (_1202 - (_1205 * dot(_1205, _1202)))), vec3(clamp(_1032 * (_1085 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2665 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2672 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2675 = int(_2665);\n    int _2678 = int(_2672);\n    float _2688 = _2672 - float(_2678);\n    int _2743 = (_2675 * 9) + _2678;\n    int _2763 = ((_2675 + 1) * 9) + _2678;\n    return mix(mix(_2739[_2743], _2739[_2743 + 1], _2688), mix(_2739[_2763], _2739[_2763 + 1], _2688), _2665 - float(_2675));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4840 = false;\n    float _4841 = 1.0;\n    float _4842 = 1.0;\n    float _4843 = 1.0;\n    float _4844 = 0.0;\n    float _4845 = 0.0;\n    float _4846 = 0.0;\n    float _4847 = 0.0;\n    float _4849 = 1.0;\n    bool _4850 = false;\n    vec3 _4851 = vec3(0.0);\n    float _4852 = 1.0;\n    float _4853 = 1.0;\n    float _4854 = 1.0;\n    float _4855 = 0.0;\n    float _4856 = 0.0;\n    vec3 _4857 = vec3(1.0, 0.0, 0.0);\n    vec3 _4858 = vec3(0.0, 0.0, 1.0);\n    float _4859 = 1.0;\n    float _4860 = 1.0;\n    float _2816 = clamp(s.specular, 0.0, 1.0);\n    float _2820 = clamp(s.ior, 1.0, 3.0);\n    bool _2825 = (_2816 != 1.0) || (_2820 != 1.5);\n    bool _2835;\n    if (!_2825)\n    {\n        _2835 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2835 = _2825;\n    }\n    if (_2835)\n    {\n        float _2843 = (_2820 - 1.0) / (_2820 + 1.0);\n        f0 = mix(min(vec3(_2843 * _2843) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2816, s.albedo, vec3(metallic));\n        _4841 = mix(_2816, 1.0, metallic);\n        _4840 = true;\n    }\n    float _2871 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2871 > 0.0)\n    {\n        float _2879 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4844 = _2871;\n        _4845 = _2879;\n        float _2886 = _2879 * _2879;\n        _4846 = _2886;\n        _4847 = _2886 * _2886;\n        float _2898 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4849 = _2898;\n        _4842 = 1.0 - (_2871 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2898, 0.0, 1.0), 5.0))));\n        _4840 = true;\n    }\n    vec3 _2917 = max(s.sheen_color, vec3(0.0));\n    float _2926 = max(_2917.x, max(_2917.y, _2917.z));\n    if (_2926 > 0.0)\n    {\n        float _2934 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4850 = true;\n        _4851 = _2917;\n        _4852 = _2934;\n        _4853 = _2934 * _2934;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2934;\n        float _2951 = fa_sheen_albedo(param, param_1);\n        _4855 = _2951;\n        _4854 = 1.0 - min(_2926 * _2951, 1.0);\n        _4840 = true;\n    }\n    _4843 = _4842 * _4854;\n    float _2970 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2970 != 0.0)\n    {\n        vec3 _2985 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2985;\n        if (dot(_2985, _2985) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2998 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2998.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2998.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2998.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3002 = t;\n        vec3 _3003 = normalize(_3002);\n        t = _3003;\n        vec3 _3028 = normalize((_3003 * cos(s.anisotropy_rotation)) + ((cross(n, _3003) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4857 = _3028;\n        _4858 = cross(n, _3028);\n        float _3038 = roughness * roughness;\n        float _3044 = mix(_3038, 1.0, _2970 * _2970);\n        bool _3046 = _2970 > 0.0;\n        _4859 = _3046 ? _3044 : _3038;\n        _4860 = _3046 ? _3038 : _3044;\n        _4856 = _2970;\n        _4840 = true;\n    }\n    return FaLayers(_4840, _4841, _4842, _4843, _4844, _4845, _4846, _4847, i.world_normal, _4849, _4850, _4851, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2422 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2422;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _421 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _427 = fa_light_texel(param_1);\n    float _430 = _427.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _436 = _430 < 0.5;\n    vec3 l;\n    if (_436)\n    {\n        l = normalize(_421.xyz);\n    }\n    else\n    {\n        vec3 _448 = _421.xyz - world_pos;\n        float _450 = length(_448);\n        dist = _450;\n        l = _448 / vec3(max(_450, 9.9999997473787516355514526367188e-05));\n        float _465 = _450 / max(_421.w, 0.001000000047497451305389404296875);\n        float _471 = clamp(1.0 - (_465 * _465), 0.0, 1.0);\n        atten = _471 * _471;\n        if (_430 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _485 = fa_light_texel(param_2);\n            float _495 = _485.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _501 = fa_light_texel(param_3);\n            float _502 = _501.x;\n            float cos_inner = _502;\n            if (_502 > 1.5)\n            {\n                cos_inner = mix(_495, 1.0, 0.25);\n            }\n            atten *= smoothstep(_495, cos_inner, dot(-l, normalize(_485.xyz)));\n        }\n    }\n    int _533;\n    if (_436)\n    {\n        _533 = 0;\n    }\n    else\n    {\n        _533 = (_430 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _427.xyz * atten, atten, 1.0, dist, _533);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1277;\n    if (i == 0)\n    {\n        _1277 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1293;\n        if (i == 1)\n        {\n            _1293 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1301;\n            if (i == 2)\n            {\n                _1301 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1301 = fa_shadows[24].w;\n            }\n            _1293 = _1301;\n        }\n        _1277 = _1293;\n    }\n    return _1277;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1334 = fa_shadow_depth(param, param_1);\n    float _1338;\n    if (conv.x < 0.5)\n    {\n        _1338 = _1334;\n    }\n    else\n    {\n        _1338 = (conv.y * conv.z) / (conv.z - (_1334 * (conv.z - conv.y)));\n    }\n    return _1338;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1265 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1265), sin(_1265)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1384 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1398 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1384;\n            vec2 _1417 = fa_shadow_vogel(param_3, param_4, param_5) * _1398;\n            vec2 param_6 = uv + (_1417 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1429 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1429 < (zr - (length(_1417) * plane)))\n            {\n                sum += _1429;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1473;\n        float param_11 = _1384;\n        vec2 _1492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1492 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1473);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1534 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1539 = clamp(dot(n, l), 0.0, 1.0);\n    float _1545 = sqrt(1.0 - (_1539 * _1539));\n    float _1552 = min(_1545 / max(_1539, 0.20000000298023223876953125), 4.0);\n    float _1557;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1557 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1557 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1582 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1557 * _1545)), 1.0);\n    float _1589 = _1582.x;\n    bool _1592 = _1589 < fa_shadows[ci * 1 + 16].x;\n    bool _1601;\n    if (!_1592)\n    {\n        _1601 = _1589 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1601 = _1592;\n    }\n    bool _1610;\n    if (!_1601)\n    {\n        _1610 = _1582.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1610 = _1601;\n    }\n    bool _1619;\n    if (!_1610)\n    {\n        _1619 = _1582.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1619 = _1610;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _1582.z > 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return -1.0;\n    }\n    float _1635;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1635 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1635 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1582.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1582.z - ((_1635 * (1.0 + (0.5 * _1552))) / _1534);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1534;\n    float param_5 = _1534 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1552, 3.0)) * 0.5) / _1534;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2062 = int(fa_shadows[25].x + 0.5);\n    if (_2062 < 1)\n    {\n        return 1.0;\n    }\n    float _2077 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2062 - 1;\n    if (_2077 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2089 = _2062 > 1;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2077 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 1;\n    }\n    bool _2100 = _2062 > 2;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2077 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 2;\n    }\n    bool _2111 = _2062 > 3;\n    bool _2118;\n    if (_2111)\n    {\n        _2118 = _2077 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2118 = _2111;\n    }\n    if (_2118)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2062)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2144 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2144;\n        if (_2144 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2169 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2169 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2188 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2169, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2199 = clamp((_2077 - (fa_shadow_split_at(param_7) - _2188)) / _2188, 0.0, 1.0);\n        if (_2199 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2062)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2220 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2220;\n                if (_2220 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2199);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1693 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1714 = fa_light_texel(param);\n    float _1715 = _1714.x;\n    if (_1715 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1724 = int(_1715 + 0.5);\n    int param_1 = _1724;\n    vec4 _1728 = fa_light_texel(param_1);\n    int param_2 = _1724 + 1;\n    vec4 _1733 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1736 = _1728.y;\n    if (_1736 > 0.0)\n    {\n        float _1753 = 1.0 - smoothstep(0.75 * _1736, _1736, length(world - fa_shadows[27].xyz));\n        fade = _1753;\n        if (_1753 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1728.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1772 = world - fa_light_texel(param_3).xyz;\n        vec3 _1775 = abs(_1772);\n        float _1777 = _1775.x;\n        float _1779 = _1775.y;\n        bool _1780 = _1777 >= _1779;\n        bool _1788;\n        if (_1780)\n        {\n            _1788 = _1777 >= _1775.z;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        int _1789;\n        if (_1788)\n        {\n            _1789 = (_1772.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1802;\n            if (_1779 >= _1775.z)\n            {\n                _1802 = (_1772.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1802 = (_1772.z > 0.0) ? 4 : 5;\n            }\n            _1789 = _1802;\n        }\n        face = _1789;\n    }\n    int _1821 = (_1724 + 2) + (face * 6);\n    int param_4 = _1821;\n    int param_5 = _1821 + 1;\n    int param_6 = _1821 + 3;\n    vec4 _1835 = fa_light_texel(param_6);\n    int param_7 = _1821 + 4;\n    vec4 _1840 = fa_light_texel(param_7);\n    int param_8 = _1821 + 5;\n    vec4 _1845 = fa_light_texel(param_8);\n    float _1857 = _1845.x * max(dot(_1835, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1862 = clamp(dot(n, l), 0.0, 1.0);\n    float _1885 = clamp(dot(n, _1835.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1908 = min(sqrt(1.0 - (_1885 * _1885)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1835, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1911 = _1733.y;\n    float _1913;\n    if (_1911 > 0.0)\n    {\n        _1913 = _1911;\n    }\n    else\n    {\n        _1913 = 1.5 * _1857;\n    }\n    vec4 _1933 = vec4(world + (n * (_1913 * sqrt(1.0 - (_1862 * _1862)))), 1.0);\n    float _1937 = dot(_1835, _1933);\n    float _1940 = _1845.y;\n    if (_1937 < _1940)\n    {\n        return 1.0;\n    }\n    vec2 _1955 = vec2(dot(fa_light_texel(param_4), _1933), dot(fa_light_texel(param_5), _1933)) / vec2(_1937);\n    float _1957 = _1955.x;\n    bool _1960 = _1957 < _1840.x;\n    bool _1969;\n    if (!_1960)\n    {\n        _1969 = _1957 > _1840.z;\n    }\n    else\n    {\n        _1969 = _1960;\n    }\n    bool _1978;\n    if (!_1969)\n    {\n        _1978 = _1955.y < _1840.y;\n    }\n    else\n    {\n        _1978 = _1969;\n    }\n    bool _1987;\n    if (!_1978)\n    {\n        _1987 = _1955.y > _1840.w;\n    }\n    else\n    {\n        _1987 = _1978;\n    }\n    if (_1987)\n    {\n        return 1.0;\n    }\n    float _1993 = _1733.x;\n    float _1995;\n    if (_1993 > 0.0)\n    {\n        _1995 = _1993;\n    }\n    else\n    {\n        _1995 = 1.5 * _1857;\n    }\n    vec2 param_10 = _1955;\n    vec4 param_11 = _1840;\n    float param_12 = _1937 - (_1995 * (1.0 + (0.5 * _1908)));\n    float param_13 = _1857;\n    float param_14 = 1.0;\n    float param_15 = _1845.z * 0.25;\n    float param_16 = (_1857 * min(_1908, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1940, _1845.z);\n    int param_18 = int(_1728.z + 0.5);\n    float param_19 = _1728.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3579 = fa_lm.z > 0.5;\n    bool _3585;\n    if (_3579)\n    {\n        int param = li;\n        _3585 = fa_light_baked(param);\n    }\n    else\n    {\n        _3585 = _3579;\n    }\n    if (_3585)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3607 = fa_light_sample(param_2, param_3);\n    vec3 _4902 = _3607.direction;\n    vec3 _4897 = _3607.color;\n    float _4904 = _3607.attenuation;\n    float _4899 = _3607.shadow;\n    int _4907 = _3607.type;\n    if ((_4907 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4902;\n        float _3621 = fa_shadow_factor(param_4, param_5);\n        _4899 = _3621;\n        _4897 *= _3621;\n    }\n    else\n    {\n        bool _3632 = _4907 != 0;\n        bool _3638;\n        if (_3632)\n        {\n            _3638 = _4904 > 0.0;\n        }\n        else\n        {\n            _3638 = _3632;\n        }\n        if (_3638)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4902;\n            float _3650 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4899 = _3650;\n            _4897 *= _3650;\n        }\n    }\n    return LightSample(_4902, _4897, _4904, _4899, _3607._distance, _4907);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3196 = tdh / at;\n    float _3200 = bdh / ab;\n    float _3212 = ((_3196 * _3196) + (_3200 * _3200)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3212) * _3212);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3293 = 1.0 / alpha;\n    return ((2.0 + _3293) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3293)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3325 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3404 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3404) * _3404);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3325);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3325));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3477 = max(dot(L.nc, l), 0.0);\n        float _3483 = max(dot(L.nc, h), 0.0);\n        float _3492 = ((_3483 * _3483) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3492) * _3492)) * (0.5 / max(mix((2.0 * _3477) * L.coat_ndv, _3477 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3477)) * _3477);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2597 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2600 = _2597.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2600 * _2600, exp2((-9.27999973297119140625) * ndv)) * _2600) + _2597.y)) + _2597.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2451 = rough * rough;\n    float _2481 = 0.60000002384185791015625 * _2451;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2451)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2481, 0.0500000007450580596923828125 + _2481, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2451 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3079;\n        if (L.aniso >= 0.0)\n        {\n            _3079 = L.b;\n        }\n        else\n        {\n            _3079 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3079, v), _3079), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3112 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3112.x) + (vec3(L.f90) * _3112.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3167 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3167.x) + _3167.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2639 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2639.x) + vec3(_2639.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2244 = int(fa_shadows[25].x + 0.5);\n    float _2254 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2259 = _2244 > 0;\n    bool _2268;\n    if (_2259)\n    {\n        int param = _2244 - 1;\n        _2268 = _2254 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2268 = _2259;\n    }\n    if (_2268)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2275 = _2244 > 1;\n        bool _2282;\n        if (_2275)\n        {\n            _2282 = _2254 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2282 = _2275;\n        }\n        if (_2282)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2288 = _2244 > 2;\n        bool _2295;\n        if (_2288)\n        {\n            _2295 = _2254 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2295 = _2288;\n        }\n        if (_2295)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2301 = _2244 > 3;\n        bool _2308;\n        if (_2301)\n        {\n            _2308 = _2254 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2308 = _2301;\n        }\n        if (_2308)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4619 = -_4619;\n    }\n    vec3 _4044 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4619, fa_world_tangent, fa_uv, fa_vertex_color, _4044, gl_FrontFacing);\n    Surface _4052 = fa_standard_surface(param_1);\n    vec3 _4650 = _4052.albedo;\n    float _4651 = _4052.alpha;\n    vec3 _4652 = _4052.normal;\n    float _4653 = _4052.metallic;\n    float _4654 = _4052.roughness;\n    float _4655 = _4052.occlusion;\n    vec3 _4656 = _4052.emission;\n    float _4657 = _4052.clearcoat;\n    float _4658 = _4052.clearcoat_roughness;\n    vec3 _4659 = _4052.sheen_color;\n    float _4660 = _4052.sheen_roughness;\n    float _4661 = _4052.anisotropy;\n    float _4662 = _4052.anisotropy_rotation;\n    float _4663 = _4052.specular;\n    float _4664 = _4052.ior;\n    vec3 _4665 = _4052.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4619, fa_world_tangent, fa_uv, fa_vertex_color, _4044, gl_FrontFacing);\n    Surface param_3 = _4052;\n    surface(param_2, param_3);\n    _4650 = param_3.albedo;\n    _4651 = param_3.alpha;\n    _4652 = param_3.normal;\n    _4653 = param_3.metallic;\n    _4654 = param_3.roughness;\n    _4655 = param_3.occlusion;\n    _4656 = param_3.emission;\n    _4657 = param_3.clearcoat;\n    _4658 = param_3.clearcoat_roughness;\n    _4659 = param_3.sheen_color;\n    _4660 = param_3.sheen_roughness;\n    _4661 = param_3.anisotropy;\n    _4662 = param_3.anisotropy_rotation;\n    _4663 = param_3.specular;\n    _4664 = param_3.ior;\n    _4665 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4619;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4650 = param_6;\n    _4652 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4650;\n    }\n    else\n    {\n        vec3 _4091 = normalize(_4652);\n        float _4098 = clamp(_4653, 0.0, 1.0);\n        float _4102 = clamp(_4654, 0.0500000007450580596923828125, 1.0);\n        float _4106 = _4102 * _4102;\n        float _4110 = _4106 * _4106;\n        float _4115 = max(dot(_4091, _4044), 9.9999997473787516355514526367188e-05);\n        vec3 _4121 = _4650 * (1.0 - _4098);\n        vec3 _4128 = mix(vec3(0.039999999105930328369140625), _4650, vec3(_4098));\n        vec3 f0 = _4128;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4619, fa_world_tangent, fa_uv, fa_vertex_color, _4044, gl_FrontFacing);\n        Surface param_9 = Surface(_4650, _4651, _4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661, _4662, _4663, _4664, _4665);\n        vec3 param_10 = _4091;\n        vec3 param_11 = _4044;\n        float param_12 = _4098;\n        float param_13 = _4102;\n        vec3 param_14 = _4128;\n        FaLayers _4144 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4091;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4121) * _4655;\n        if (_4144.on)\n        {\n            lit *= _4144.base_scale;\n        }\n        int _4166 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4166; ln++)\n        {\n            int param_16 = ln;\n            int _4179 = fa_cl_light(param_16);\n            bool _4182 = fa_lm.z > 0.5;\n            bool _4188;\n            if (_4182)\n            {\n                int param_17 = _4179;\n                _4188 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4188 = _4182;\n            }\n            if (_4188)\n            {\n                continue;\n            }\n            int param_18 = _4179;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4619;\n            LightSample _4200 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _4824 = _4200.direction;\n            float _4208 = max(dot(_4091, _4824), 0.0);\n            float _4214 = _4200.attenuation * _4200.shadow;\n            vec3 _4219 = normalize(_4824 + _4044);\n            float _4224 = max(dot(_4091, _4219), 0.0);\n            float _4229 = max(dot(_4044, _4219), 0.0);\n            if (_4144.on)\n            {\n                FaLayers param_21 = _4144;\n                vec3 param_22 = _4121;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4091;\n                vec3 param_25 = _4044;\n                vec3 param_26 = _4824;\n                vec3 param_27 = _4219;\n                float param_28 = _4208;\n                float param_29 = _4115;\n                float param_30 = _4224;\n                float param_31 = _4229;\n                float param_32 = _4106;\n                float param_33 = _4110;\n                int param_34 = _4179;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4214));\n            }\n            else\n            {\n                float _4277 = ((_4224 * _4224) * (_4110 - 1.0)) + 1.0;\n                int param_35 = _4179;\n                lit += (((_4121 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4229, 5.0))) * (((_4110 / ((3.1415927410125732421875 * _4277) * _4277)) * (0.5 / max(mix((2.0 * _4208) * _4115, _4208 + _4115, _4106), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4208))) * fa_light_rgb(param_35)) * (_4208 * _4214));\n            }\n        }\n        if (_4144.on)\n        {\n            FaLayers param_36 = _4144;\n            vec3 param_37 = _4091;\n            vec3 param_38 = _4044;\n            vec3 param_39 = f0;\n            float param_40 = _4102;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4655);\n        }\n        else\n        {\n            vec3 param_41 = _4091;\n            vec3 param_42 = _4044;\n            vec3 param_43 = f0;\n            float param_44 = _4102;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4655);\n        }\n        result = lit;\n    }\n    vec3 _4370 = result;\n    vec3 _4371 = _4370 + _4656;\n    result = _4371;\n    vec3 param_45 = _4371;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4380 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4387;\n    if (!_4380)\n    {\n        _4387 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4387 = _4380;\n    }\n    if (_4387)\n    {\n        vec3 _4396 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4402 = dot(_4396, fa_mesh_fs_params[9].xyz);\n        bool _4406 = fa_mesh_fs_params[9].w > 0.5;\n        float _4407;\n        if (_4406)\n        {\n            _4407 = _4402;\n        }\n        else\n        {\n            _4407 = length(_4396);\n        }\n        float _4419 = _4407 - fa_mesh_fs_params[8].x;\n        if (_4419 > 0.0)\n        {\n            float _4428 = fa_mesh_fs_params[7].w * _4419;\n            float tau = _4428 * _4428;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4444;\n                if (_4406)\n                {\n                    _4444 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4402);\n                }\n                else\n                {\n                    _4444 = fa_mesh_fs_params[0].y;\n                }\n                float _4465 = mix(_4444, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4407, 0.0, 1.0));\n                float _4469 = fa_world_pos.y - _4465;\n                float _4474 = _4465 - fa_mesh_fs_params[8].z;\n                float _4479 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4482 = _4474 <= 0.0;\n                bool _4483 = !_4482;\n                bool _4489;\n                if (_4483)\n                {\n                    _4489 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4489 = _4482;\n                }\n                float _4490;\n                if (_4489)\n                {\n                    _4490 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4490 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4474, 80.0));\n                }\n                bool _4517;\n                if (_4483)\n                {\n                    _4517 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4517 = _4482;\n                }\n                float _4518;\n                if (_4517)\n                {\n                    _4518 = fa_mesh_fs_params[8].y * _4474;\n                }\n                else\n                {\n                    _4518 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4474, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4543 = _4479 <= 0.0;\n                bool _4550;\n                if (!_4543)\n                {\n                    _4550 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4550 = _4543;\n                }\n                float _4551;\n                if (_4550)\n                {\n                    _4551 = fa_mesh_fs_params[8].y * _4479;\n                }\n                else\n                {\n                    _4551 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4479, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4578;\n                if (abs(_4469) < 0.001000000047497451305389404296875)\n                {\n                    _4578 = _4490;\n                }\n                else\n                {\n                    _4578 = (_4551 - _4518) / _4469;\n                }\n                tau += (_4419 * max(_4578, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4651);\n}\n\n",
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
            "inst_name": "_168",
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
            "inst_name": "_547",
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
            "inst_name": "_1287",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2739[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _552 = fa_mesh_fs_params[19].x < 0.0;\n    bool _559;\n    if (!_552)\n    {\n        _559 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _559 = _552;\n    }\n    bool _567;\n    if (!_559)\n    {\n        _567 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _567 = _559;\n    }\n    bool _574;\n    if (!_567)\n    {\n        _574 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _574 = _567;\n    }\n    bool _581;\n    if (!_574)\n    {\n        _581 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _581 = _574;\n    }\n    if (_581)\n    {\n        return vec4(0.0);\n    }\n    vec4 _591 = vec4(world_pos, 1.0);\n    float _598 = dot(fa_mesh_fs_params[16], _591);\n    if (!(_598 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _620 = vec2(dot(fa_mesh_fs_params[14], _591), dot(fa_mesh_fs_params[15], _591)) / vec2(_598);\n    int _624 = int(fa_mesh_fs_params[18].x);\n    int _628 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _628) + clamp(int(floor(((_620.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _628 - 1)) * _624)) + clamp(int(floor(((_620.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _624 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _704 = fa_cluster_texel(param);\n    return ivec2(int(_704.x), int(_704.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3552 = fa_cluster_lookup(param);\n    fa_cl_slot = _3552.x;\n    fa_cl_local = _3552.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3712 = fa_linear_to_srgb(param);\n        c = _3712;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3720 = fa_srgb_to_linear(param_1);\n            c = _3720;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _303;\n    if (i.front_facing)\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    vec3 _327 = normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    vec3 _354 = normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    vec3 _357;\n    if (i.front_facing)\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3751 = fa_tex_fix(param_2, param_3);\n    vec4 _5050 = base_t;\n    _5050.x = _3751.x;\n    _5050.y = _3751.y;\n    _5050.z = _3751.z;\n    base_t = _5050;\n    vec4 _3765 = (_5050 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4917 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3797 = fa_tex_fix(param_6, param_7);\n        vec3 _3800 = (_3797 * 2.0) - vec3(1.0);\n        vec2 _3805 = _3800.xy * fa_mesh_fs_params[6].x;\n        vec3 _5058 = _3800;\n        _5058.x = _3805.x;\n        _5058.y = _3805.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5058;\n        _4917 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3834 = fa_tex_fix(param_12, param_13);\n    vec4 _5061 = mrt;\n    _5061.x = _3834.x;\n    _5061.y = _3834.y;\n    _5061.z = _3834.z;\n    mrt = _5061;\n    vec4 _3862 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3862.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3874 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3904 = fa_tex_fix(param_20, param_21);\n    float _4922 = fa_mesh_fs_params[20].x;\n    float _4923 = fa_mesh_fs_params[20].y;\n    float _4926 = fa_mesh_fs_params[20].z;\n    float _4925 = fa_mesh_fs_params[21].w;\n    float _4928 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4922 *= _3874.y;\n            _4923 *= _3874.z;\n            _4925 *= _3862.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4926 *= mrt.x;\n            _4928 *= mrt.w;\n        }\n    }\n    return Surface(_3765.xyz, _3765.w, _4917, clamp(fa_mesh_fs_params[5].x * _3834.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3834.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3874.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3904), _4922, _4923, fa_mesh_fs_params[21].xyz, _4925, _4926, fa_mesh_fs_params[20].w, _4928, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _785 = rect.zw - rect.xy;\n    vec2 _789 = _785 * atlas;\n    vec2 _793 = ddx * _789;\n    vec2 _797 = ddy * _789;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _785), clamp(0.5 * log2(max(max(dot(_793, _793), dot(_797, _797)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _832 = fa_mesh_fs_params[10].y < 0.5;\n    bool _839;\n    if (!_832)\n    {\n        _839 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _839 = _832;\n    }\n    if (_839)\n    {\n        return;\n    }\n    vec3 _845 = dFdx(world_pos);\n    vec3 _848 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _852 = fa_cluster_texel(param);\n    int _856 = int(_852.w);\n    if (_856 < 1)\n    {\n        return;\n    }\n    int _866 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _866;\n    vec4 _870 = fa_light_texel(param_1);\n    vec2 _873 = _870.yz;\n    int _877 = int(_870.w);\n    int param_2 = _866 + 1;\n    vec4 _882 = fa_light_texel(param_2);\n    float _883 = _882.x;\n    int _889 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _893 = int(_852.z);\n    vec3 _1159;\n    for (int k = 0; k < _856; k++)\n    {\n        int _906 = _893 + k;\n        int param_3 = _877 + (_906 >> 2);\n        int _924 = (_866 + 2) + (int(fa_light_texel(param_3)[_906 & 3]) * 7);\n        int param_4 = _924 + 6;\n        vec4 _929 = fa_light_texel(param_4);\n        if (((int(_929.w + 0.5) >> _889) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _924;\n        vec4 _944 = fa_light_texel(param_5);\n        int param_6 = _924 + 1;\n        vec4 _949 = fa_light_texel(param_6);\n        int param_7 = _924 + 2;\n        vec4 _954 = fa_light_texel(param_7);\n        vec3 _957 = _944.xyz;\n        float _962 = dot(_957, world_pos) + _944.w;\n        vec3 _964 = _949.xyz;\n        float _969 = dot(_964, world_pos) + _949.w;\n        vec3 _971 = _954.xyz;\n        float _976 = dot(_971, world_pos) + _954.w;\n        bool _981 = abs(_962) > 0.5;\n        bool _989;\n        if (!_981)\n        {\n            _989 = abs(_969) > 0.5;\n        }\n        else\n        {\n            _989 = _981;\n        }\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_976) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        if (_997)\n        {\n            continue;\n        }\n        float _1012 = clamp(dot(geo_normal, normalize(_971)) * _929.z, 0.0, 1.0);\n        if (_1012 <= 0.0)\n        {\n            continue;\n        }\n        float _1032 = (clamp((0.5 - abs(_976)) * 10.0, 0.0, 1.0) * _1012) * _929.x;\n        vec2 _1040 = vec2(_962 + 0.5, 0.5 - _969);\n        vec2 _1050 = vec2(dot(_957, _845), dot(_964, _845));\n        vec2 _1060 = vec2(dot(_957, _848), dot(_964, _848));\n        int param_8 = _924 + 5;\n        vec4 _1065 = fa_light_texel(param_8);\n        int param_9 = _924 + 3;\n        vec4 _1070 = fa_light_texel(param_9);\n        int param_10 = _924 + 4;\n        vec4 _1075 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1065.xyz;\n        bool _1085 = _1070.z > _1070.x;\n        if (_1085)\n        {\n            vec4 param_11 = _1070;\n            vec2 param_12 = _1040;\n            vec2 param_13 = _873;\n            vec2 param_14 = _1050;\n            vec2 param_15 = _1060;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_883 > 0.5) && (_883 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1111 = fa_dc_to_linear(param_16);\n                vec4 _4973 = tx;\n                _4973.x = _1111.x;\n                _4973.y = _1111.y;\n                _4973.z = _1111.z;\n                tx = _4973;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1032 * tex_a) * _1065.w, 0.0, 1.0)));\n        if (_1075.z > _1075.x)\n        {\n            vec4 param_17 = _1075;\n            vec2 param_18 = _1040;\n            vec2 param_19 = _873;\n            vec2 param_20 = _1050;\n            vec2 param_21 = _1060;\n            vec4 _1155 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_883 > 1.5)\n            {\n                vec3 param_22 = _1155.xyz;\n                vec3 _1165 = fa_dc_to_srgb(param_22);\n                _1159 = _1165;\n            }\n            else\n            {\n                _1159 = _1155.xyz;\n            }\n            vec3 _1175 = (_1159 * 2.0) - vec3(1.0);\n            vec2 _1180 = _1175.xy * _929.y;\n            vec3 _1202 = (normalize(_957) * _1180.x) + (normalize(_964) * _1180.y);\n            vec3 _1205 = normalize(normal);\n            normal = normalize(mix(_1205, normalize((_1205 * max(_1175.z, 0.0500000007450580596923828125)) + (_1202 - (_1205 * dot(_1205, _1202)))), vec3(clamp(_1032 * (_1085 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2665 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2672 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2675 = int(_2665);\n    int _2678 = int(_2672);\n    float _2688 = _2672 - float(_2678);\n    int _2743 = (_2675 * 9) + _2678;\n    int _2763 = ((_2675 + 1) * 9) + _2678;\n    return mix(mix(_2739[_2743], _2739[_2743 + 1], _2688), mix(_2739[_2763], _2739[_2763 + 1], _2688), _2665 - float(_2675));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4840 = false;\n    float _4841 = 1.0;\n    float _4842 = 1.0;\n    float _4843 = 1.0;\n    float _4844 = 0.0;\n    float _4845 = 0.0;\n    float _4846 = 0.0;\n    float _4847 = 0.0;\n    float _4849 = 1.0;\n    bool _4850 = false;\n    vec3 _4851 = vec3(0.0);\n    float _4852 = 1.0;\n    float _4853 = 1.0;\n    float _4854 = 1.0;\n    float _4855 = 0.0;\n    float _4856 = 0.0;\n    vec3 _4857 = vec3(1.0, 0.0, 0.0);\n    vec3 _4858 = vec3(0.0, 0.0, 1.0);\n    float _4859 = 1.0;\n    float _4860 = 1.0;\n    float _2816 = clamp(s.specular, 0.0, 1.0);\n    float _2820 = clamp(s.ior, 1.0, 3.0);\n    bool _2825 = (_2816 != 1.0) || (_2820 != 1.5);\n    bool _2835;\n    if (!_2825)\n    {\n        _2835 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2835 = _2825;\n    }\n    if (_2835)\n    {\n        float _2843 = (_2820 - 1.0) / (_2820 + 1.0);\n        f0 = mix(min(vec3(_2843 * _2843) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2816, s.albedo, vec3(metallic));\n        _4841 = mix(_2816, 1.0, metallic);\n        _4840 = true;\n    }\n    float _2871 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2871 > 0.0)\n    {\n        float _2879 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4844 = _2871;\n        _4845 = _2879;\n        float _2886 = _2879 * _2879;\n        _4846 = _2886;\n        _4847 = _2886 * _2886;\n        float _2898 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4849 = _2898;\n        _4842 = 1.0 - (_2871 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2898, 0.0, 1.0), 5.0))));\n        _4840 = true;\n    }\n    vec3 _2917 = max(s.sheen_color, vec3(0.0));\n    float _2926 = max(_2917.x, max(_2917.y, _2917.z));\n    if (_2926 > 0.0)\n    {\n        float _2934 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4850 = true;\n        _4851 = _2917;\n        _4852 = _2934;\n        _4853 = _2934 * _2934;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2934;\n        float _2951 = fa_sheen_albedo(param, param_1);\n        _4855 = _2951;\n        _4854 = 1.0 - min(_2926 * _2951, 1.0);\n        _4840 = true;\n    }\n    _4843 = _4842 * _4854;\n    float _2970 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2970 != 0.0)\n    {\n        vec3 _2985 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2985;\n        if (dot(_2985, _2985) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2998 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2998.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2998.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2998.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3002 = t;\n        vec3 _3003 = normalize(_3002);\n        t = _3003;\n        vec3 _3028 = normalize((_3003 * cos(s.anisotropy_rotation)) + ((cross(n, _3003) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4857 = _3028;\n        _4858 = cross(n, _3028);\n        float _3038 = roughness * roughness;\n        float _3044 = mix(_3038, 1.0, _2970 * _2970);\n        bool _3046 = _2970 > 0.0;\n        _4859 = _3046 ? _3044 : _3038;\n        _4860 = _3046 ? _3038 : _3044;\n        _4856 = _2970;\n        _4840 = true;\n    }\n    return FaLayers(_4840, _4841, _4842, _4843, _4844, _4845, _4846, _4847, i.world_normal, _4849, _4850, _4851, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2422 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2422;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _421 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _427 = fa_light_texel(param_1);\n    float _430 = _427.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _436 = _430 < 0.5;\n    vec3 l;\n    if (_436)\n    {\n        l = normalize(_421.xyz);\n    }\n    else\n    {\n        vec3 _448 = _421.xyz - world_pos;\n        float _450 = length(_448);\n        dist = _450;\n        l = _448 / vec3(max(_450, 9.9999997473787516355514526367188e-05));\n        float _465 = _450 / max(_421.w, 0.001000000047497451305389404296875);\n        float _471 = clamp(1.0 - (_465 * _465), 0.0, 1.0);\n        atten = _471 * _471;\n        if (_430 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _485 = fa_light_texel(param_2);\n            float _495 = _485.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _501 = fa_light_texel(param_3);\n            float _502 = _501.x;\n            float cos_inner = _502;\n            if (_502 > 1.5)\n            {\n                cos_inner = mix(_495, 1.0, 0.25);\n            }\n            atten *= smoothstep(_495, cos_inner, dot(-l, normalize(_485.xyz)));\n        }\n    }\n    int _533;\n    if (_436)\n    {\n        _533 = 0;\n    }\n    else\n    {\n        _533 = (_430 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _427.xyz * atten, atten, 1.0, dist, _533);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1277;\n    if (i == 0)\n    {\n        _1277 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1293;\n        if (i == 1)\n        {\n            _1293 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1301;\n            if (i == 2)\n            {\n                _1301 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1301 = fa_shadows[24].w;\n            }\n            _1293 = _1301;\n        }\n        _1277 = _1293;\n    }\n    return _1277;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1334 = fa_shadow_depth(param, param_1);\n    float _1338;\n    if (conv.x < 0.5)\n    {\n        _1338 = _1334;\n    }\n    else\n    {\n        _1338 = (conv.y * conv.z) / (conv.z - (_1334 * (conv.z - conv.y)));\n    }\n    return _1338;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1265 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1265), sin(_1265)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1384 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1398 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1384;\n            vec2 _1417 = fa_shadow_vogel(param_3, param_4, param_5) * _1398;\n            vec2 param_6 = uv + (_1417 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1429 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1429 < (zr - (length(_1417) * plane)))\n            {\n                sum += _1429;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1473;\n        float param_11 = _1384;\n        vec2 _1492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1492 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1473);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1534 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1539 = clamp(dot(n, l), 0.0, 1.0);\n    float _1545 = sqrt(1.0 - (_1539 * _1539));\n    float _1552 = min(_1545 / max(_1539, 0.20000000298023223876953125), 4.0);\n    float _1557;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1557 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1557 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1582 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1557 * _1545)), 1.0);\n    float _1589 = _1582.x;\n    bool _1592 = _1589 < fa_shadows[ci * 1 + 16].x;\n    bool _1601;\n    if (!_1592)\n    {\n        _1601 = _1589 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1601 = _1592;\n    }\n    bool _1610;\n    if (!_1601)\n    {\n        _1610 = _1582.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1610 = _1601;\n    }\n    bool _1619;\n    if (!_1610)\n    {\n        _1619 = _1582.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1619 = _1610;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _1582.z > 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return -1.0;\n    }\n    float _1635;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1635 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1635 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1582.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1582.z - ((_1635 * (1.0 + (0.5 * _1552))) / _1534);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1534;\n    float param_5 = _1534 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1552, 3.0)) * 0.5) / _1534;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2062 = int(fa_shadows[25].x + 0.5);\n    if (_2062 < 1)\n    {\n        return 1.0;\n    }\n    float _2077 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2062 - 1;\n    if (_2077 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2089 = _2062 > 1;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2077 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 1;\n    }\n    bool _2100 = _2062 > 2;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2077 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 2;\n    }\n    bool _2111 = _2062 > 3;\n    bool _2118;\n    if (_2111)\n    {\n        _2118 = _2077 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2118 = _2111;\n    }\n    if (_2118)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2062)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2144 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2144;\n        if (_2144 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2169 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2169 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2188 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2169, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2199 = clamp((_2077 - (fa_shadow_split_at(param_7) - _2188)) / _2188, 0.0, 1.0);\n        if (_2199 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2062)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2220 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2220;\n                if (_2220 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2199);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1693 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1714 = fa_light_texel(param);\n    float _1715 = _1714.x;\n    if (_1715 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1724 = int(_1715 + 0.5);\n    int param_1 = _1724;\n    vec4 _1728 = fa_light_texel(param_1);\n    int param_2 = _1724 + 1;\n    vec4 _1733 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1736 = _1728.y;\n    if (_1736 > 0.0)\n    {\n        float _1753 = 1.0 - smoothstep(0.75 * _1736, _1736, length(world - fa_shadows[27].xyz));\n        fade = _1753;\n        if (_1753 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1728.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1772 = world - fa_light_texel(param_3).xyz;\n        vec3 _1775 = abs(_1772);\n        float _1777 = _1775.x;\n        float _1779 = _1775.y;\n        bool _1780 = _1777 >= _1779;\n        bool _1788;\n        if (_1780)\n        {\n            _1788 = _1777 >= _1775.z;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        int _1789;\n        if (_1788)\n        {\n            _1789 = (_1772.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1802;\n            if (_1779 >= _1775.z)\n            {\n                _1802 = (_1772.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1802 = (_1772.z > 0.0) ? 4 : 5;\n            }\n            _1789 = _1802;\n        }\n        face = _1789;\n    }\n    int _1821 = (_1724 + 2) + (face * 6);\n    int param_4 = _1821;\n    int param_5 = _1821 + 1;\n    int param_6 = _1821 + 3;\n    vec4 _1835 = fa_light_texel(param_6);\n    int param_7 = _1821 + 4;\n    vec4 _1840 = fa_light_texel(param_7);\n    int param_8 = _1821 + 5;\n    vec4 _1845 = fa_light_texel(param_8);\n    float _1857 = _1845.x * max(dot(_1835, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1862 = clamp(dot(n, l), 0.0, 1.0);\n    float _1885 = clamp(dot(n, _1835.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1908 = min(sqrt(1.0 - (_1885 * _1885)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1835, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1911 = _1733.y;\n    float _1913;\n    if (_1911 > 0.0)\n    {\n        _1913 = _1911;\n    }\n    else\n    {\n        _1913 = 1.5 * _1857;\n    }\n    vec4 _1933 = vec4(world + (n * (_1913 * sqrt(1.0 - (_1862 * _1862)))), 1.0);\n    float _1937 = dot(_1835, _1933);\n    float _1940 = _1845.y;\n    if (_1937 < _1940)\n    {\n        return 1.0;\n    }\n    vec2 _1955 = vec2(dot(fa_light_texel(param_4), _1933), dot(fa_light_texel(param_5), _1933)) / vec2(_1937);\n    float _1957 = _1955.x;\n    bool _1960 = _1957 < _1840.x;\n    bool _1969;\n    if (!_1960)\n    {\n        _1969 = _1957 > _1840.z;\n    }\n    else\n    {\n        _1969 = _1960;\n    }\n    bool _1978;\n    if (!_1969)\n    {\n        _1978 = _1955.y < _1840.y;\n    }\n    else\n    {\n        _1978 = _1969;\n    }\n    bool _1987;\n    if (!_1978)\n    {\n        _1987 = _1955.y > _1840.w;\n    }\n    else\n    {\n        _1987 = _1978;\n    }\n    if (_1987)\n    {\n        return 1.0;\n    }\n    float _1993 = _1733.x;\n    float _1995;\n    if (_1993 > 0.0)\n    {\n        _1995 = _1993;\n    }\n    else\n    {\n        _1995 = 1.5 * _1857;\n    }\n    vec2 param_10 = _1955;\n    vec4 param_11 = _1840;\n    float param_12 = _1937 - (_1995 * (1.0 + (0.5 * _1908)));\n    float param_13 = _1857;\n    float param_14 = 1.0;\n    float param_15 = _1845.z * 0.25;\n    float param_16 = (_1857 * min(_1908, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1940, _1845.z);\n    int param_18 = int(_1728.z + 0.5);\n    float param_19 = _1728.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3579 = fa_lm.z > 0.5;\n    bool _3585;\n    if (_3579)\n    {\n        int param = li;\n        _3585 = fa_light_baked(param);\n    }\n    else\n    {\n        _3585 = _3579;\n    }\n    if (_3585)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3607 = fa_light_sample(param_2, param_3);\n    vec3 _4902 = _3607.direction;\n    vec3 _4897 = _3607.color;\n    float _4904 = _3607.attenuation;\n    float _4899 = _3607.shadow;\n    int _4907 = _3607.type;\n    if ((_4907 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4902;\n        float _3621 = fa_shadow_factor(param_4, param_5);\n        _4899 = _3621;\n        _4897 *= _3621;\n    }\n    else\n    {\n        bool _3632 = _4907 != 0;\n        bool _3638;\n        if (_3632)\n        {\n            _3638 = _4904 > 0.0;\n        }\n        else\n        {\n            _3638 = _3632;\n        }\n        if (_3638)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4902;\n            float _3650 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4899 = _3650;\n            _4897 *= _3650;\n        }\n    }\n    return LightSample(_4902, _4897, _4904, _4899, _3607._distance, _4907);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3196 = tdh / at;\n    float _3200 = bdh / ab;\n    float _3212 = ((_3196 * _3196) + (_3200 * _3200)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3212) * _3212);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3293 = 1.0 / alpha;\n    return ((2.0 + _3293) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3293)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3325 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3404 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3404) * _3404);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3325);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3325));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3477 = max(dot(L.nc, l), 0.0);\n        float _3483 = max(dot(L.nc, h), 0.0);\n        float _3492 = ((_3483 * _3483) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3492) * _3492)) * (0.5 / max(mix((2.0 * _3477) * L.coat_ndv, _3477 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3477)) * _3477);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2597 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2600 = _2597.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2600 * _2600, exp2((-9.27999973297119140625) * ndv)) * _2600) + _2597.y)) + _2597.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2451 = rough * rough;\n    float _2481 = 0.60000002384185791015625 * _2451;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2451)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2481, 0.0500000007450580596923828125 + _2481, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2451 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3079;\n        if (L.aniso >= 0.0)\n        {\n            _3079 = L.b;\n        }\n        else\n        {\n            _3079 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3079, v), _3079), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3112 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3112.x) + (vec3(L.f90) * _3112.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3167 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3167.x) + _3167.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2639 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2639.x) + vec3(_2639.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2244 = int(fa_shadows[25].x + 0.5);\n    float _2254 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2259 = _2244 > 0;\n    bool _2268;\n    if (_2259)\n    {\n        int param = _2244 - 1;\n        _2268 = _2254 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2268 = _2259;\n    }\n    if (_2268)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2275 = _2244 > 1;\n        bool _2282;\n        if (_2275)\n        {\n            _2282 = _2254 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2282 = _2275;\n        }\n        if (_2282)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2288 = _2244 > 2;\n        bool _2295;\n        if (_2288)\n        {\n            _2295 = _2254 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2295 = _2288;\n        }\n        if (_2295)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2301 = _2244 > 3;\n        bool _2308;\n        if (_2301)\n        {\n            _2308 = _2254 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2308 = _2301;\n        }\n        if (_2308)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4619 = -_4619;\n    }\n    vec3 _4044 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4619, fa_world_tangent, fa_uv, fa_vertex_color, _4044, gl_FrontFacing);\n    Surface _4052 = fa_standard_surface(param_1);\n    vec3 _4650 = _4052.albedo;\n    float _4651 = _4052.alpha;\n    vec3 _4652 = _4052.normal;\n    float _4653 = _4052.metallic;\n    float _4654 = _4052.roughness;\n    float _4655 = _4052.occlusion;\n    vec3 _4656 = _4052.emission;\n    float _4657 = _4052.clearcoat;\n    float _4658 = _4052.clearcoat_roughness;\n    vec3 _4659 = _4052.sheen_color;\n    float _4660 = _4052.sheen_roughness;\n    float _4661 = _4052.anisotropy;\n    float _4662 = _4052.anisotropy_rotation;\n    float _4663 = _4052.specular;\n    float _4664 = _4052.ior;\n    vec3 _4665 = _4052.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4619, fa_world_tangent, fa_uv, fa_vertex_color, _4044, gl_FrontFacing);\n    Surface param_3 = _4052;\n    surface(param_2, param_3);\n    _4650 = param_3.albedo;\n    _4651 = param_3.alpha;\n    _4652 = param_3.normal;\n    _4653 = param_3.metallic;\n    _4654 = param_3.roughness;\n    _4655 = param_3.occlusion;\n    _4656 = param_3.emission;\n    _4657 = param_3.clearcoat;\n    _4658 = param_3.clearcoat_roughness;\n    _4659 = param_3.sheen_color;\n    _4660 = param_3.sheen_roughness;\n    _4661 = param_3.anisotropy;\n    _4662 = param_3.anisotropy_rotation;\n    _4663 = param_3.specular;\n    _4664 = param_3.ior;\n    _4665 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4619;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4650 = param_6;\n    _4652 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4650;\n    }\n    else\n    {\n        vec3 _4091 = normalize(_4652);\n        float _4098 = clamp(_4653, 0.0, 1.0);\n        float _4102 = clamp(_4654, 0.0500000007450580596923828125, 1.0);\n        float _4106 = _4102 * _4102;\n        float _4110 = _4106 * _4106;\n        float _4115 = max(dot(_4091, _4044), 9.9999997473787516355514526367188e-05);\n        vec3 _4121 = _4650 * (1.0 - _4098);\n        vec3 _4128 = mix(vec3(0.039999999105930328369140625), _4650, vec3(_4098));\n        vec3 f0 = _4128;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4619, fa_world_tangent, fa_uv, fa_vertex_color, _4044, gl_FrontFacing);\n        Surface param_9 = Surface(_4650, _4651, _4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661, _4662, _4663, _4664, _4665);\n        vec3 param_10 = _4091;\n        vec3 param_11 = _4044;\n        float param_12 = _4098;\n        float param_13 = _4102;\n        vec3 param_14 = _4128;\n        FaLayers _4144 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4091;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4121) * _4655;\n        if (_4144.on)\n        {\n            lit *= _4144.base_scale;\n        }\n        int _4166 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4166; ln++)\n        {\n            int param_16 = ln;\n            int _4179 = fa_cl_light(param_16);\n            bool _4182 = fa_lm.z > 0.5;\n            bool _4188;\n            if (_4182)\n            {\n                int param_17 = _4179;\n                _4188 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4188 = _4182;\n            }\n            if (_4188)\n            {\n                continue;\n            }\n            int param_18 = _4179;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4619;\n            LightSample _4200 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _4824 = _4200.direction;\n            float _4208 = max(dot(_4091, _4824), 0.0);\n            float _4214 = _4200.attenuation * _4200.shadow;\n            vec3 _4219 = normalize(_4824 + _4044);\n            float _4224 = max(dot(_4091, _4219), 0.0);\n            float _4229 = max(dot(_4044, _4219), 0.0);\n            if (_4144.on)\n            {\n                FaLayers param_21 = _4144;\n                vec3 param_22 = _4121;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4091;\n                vec3 param_25 = _4044;\n                vec3 param_26 = _4824;\n                vec3 param_27 = _4219;\n                float param_28 = _4208;\n                float param_29 = _4115;\n                float param_30 = _4224;\n                float param_31 = _4229;\n                float param_32 = _4106;\n                float param_33 = _4110;\n                int param_34 = _4179;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4214));\n            }\n            else\n            {\n                float _4277 = ((_4224 * _4224) * (_4110 - 1.0)) + 1.0;\n                int param_35 = _4179;\n                lit += (((_4121 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4229, 5.0))) * (((_4110 / ((3.1415927410125732421875 * _4277) * _4277)) * (0.5 / max(mix((2.0 * _4208) * _4115, _4208 + _4115, _4106), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4208))) * fa_light_rgb(param_35)) * (_4208 * _4214));\n            }\n        }\n        if (_4144.on)\n        {\n            FaLayers param_36 = _4144;\n            vec3 param_37 = _4091;\n            vec3 param_38 = _4044;\n            vec3 param_39 = f0;\n            float param_40 = _4102;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4655);\n        }\n        else\n        {\n            vec3 param_41 = _4091;\n            vec3 param_42 = _4044;\n            vec3 param_43 = f0;\n            float param_44 = _4102;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4655);\n        }\n        result = lit;\n    }\n    vec3 _4370 = result;\n    vec3 _4371 = _4370 + _4656;\n    result = _4371;\n    vec3 param_45 = _4371;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4380 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4387;\n    if (!_4380)\n    {\n        _4387 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4387 = _4380;\n    }\n    if (_4387)\n    {\n        vec3 _4396 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4402 = dot(_4396, fa_mesh_fs_params[9].xyz);\n        bool _4406 = fa_mesh_fs_params[9].w > 0.5;\n        float _4407;\n        if (_4406)\n        {\n            _4407 = _4402;\n        }\n        else\n        {\n            _4407 = length(_4396);\n        }\n        float _4419 = _4407 - fa_mesh_fs_params[8].x;\n        if (_4419 > 0.0)\n        {\n            float _4428 = fa_mesh_fs_params[7].w * _4419;\n            float tau = _4428 * _4428;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4444;\n                if (_4406)\n                {\n                    _4444 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4402);\n                }\n                else\n                {\n                    _4444 = fa_mesh_fs_params[0].y;\n                }\n                float _4465 = mix(_4444, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4407, 0.0, 1.0));\n                float _4469 = fa_world_pos.y - _4465;\n                float _4474 = _4465 - fa_mesh_fs_params[8].z;\n                float _4479 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4482 = _4474 <= 0.0;\n                bool _4483 = !_4482;\n                bool _4489;\n                if (_4483)\n                {\n                    _4489 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4489 = _4482;\n                }\n                float _4490;\n                if (_4489)\n                {\n                    _4490 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4490 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4474, 80.0));\n                }\n                bool _4517;\n                if (_4483)\n                {\n                    _4517 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4517 = _4482;\n                }\n                float _4518;\n                if (_4517)\n                {\n                    _4518 = fa_mesh_fs_params[8].y * _4474;\n                }\n                else\n                {\n                    _4518 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4474, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4543 = _4479 <= 0.0;\n                bool _4550;\n                if (!_4543)\n                {\n                    _4550 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4550 = _4543;\n                }\n                float _4551;\n                if (_4550)\n                {\n                    _4551 = fa_mesh_fs_params[8].y * _4479;\n                }\n                else\n                {\n                    _4551 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4479, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4578;\n                if (abs(_4469) < 0.001000000047497451305389404296875)\n                {\n                    _4578 = _4490;\n                }\n                else\n                {\n                    _4578 = (_4551 - _4518) / _4469;\n                }\n                tau += (_4419 * max(_4578, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4651);\n}\n\n",
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
            "inst_name": "_173",
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
            "inst_name": "_547",
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
            "inst_name": "_1287",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _203 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _210 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_203 * _210).z;\n    fa_pre_r0 = vec3(_203[0].x, _203[1].x, _203[2].x);\n    fa_pre_r1 = vec3(_203[0].y, _203[1].y, _203[2].y);\n    fa_pre_r2 = vec3(_203[0].z, _203[1].z, _203[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _210;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_168",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _315 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _322 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_315 * _322).z;\n    fa_pre_r0 = vec3(_315[0].x, _315[1].x, _315[2].x);\n    fa_pre_r1 = vec3(_315[0].y, _315[1].y, _315[2].y);\n    fa_pre_r2 = vec3(_315[0].z, _315[1].z, _315[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _322;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_173",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_159",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_199 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_199 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_199 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_164",
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
