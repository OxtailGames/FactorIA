{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c7bc8cc90909f1ebab7aa9dd758cdced3d658fca63fc282b6949a210c4a3347",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "extra",
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
    },
    {
      "name": "points",
      "binding": 1,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3653[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1494 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1501;\n    if (!_1494)\n    {\n        _1501 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1501 = _1494;\n    }\n    bool _1509;\n    if (!_1501)\n    {\n        _1509 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1509 = _1501;\n    }\n    bool _1516;\n    if (!_1509)\n    {\n        _1516 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1516 = _1509;\n    }\n    bool _1523;\n    if (!_1516)\n    {\n        _1523 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1523 = _1516;\n    }\n    if (_1523)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1533 = vec4(world_pos, 1.0);\n    float _1539 = dot(fa_mesh_fs_params[16], _1533);\n    if (!(_1539 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1561 = vec2(dot(fa_mesh_fs_params[14], _1533), dot(fa_mesh_fs_params[15], _1533)) / vec2(_1539);\n    int _1565 = int(fa_mesh_fs_params[18].x);\n    int _1569 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1569) + clamp(int(floor(((_1561.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1569 - 1)) * _1565)) + clamp(int(floor(((_1561.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1565 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1645 = fa_cluster_texel(param);\n    return ivec2(int(_1645.x), int(_1645.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4723 = fa_cluster_lookup(param);\n    fa_cl_slot = _4723.x;\n    fa_cl_local = _4723.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5867 = fa_linear_to_srgb(param);\n        c = _5867;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5875 = fa_srgb_to_linear(param_1);\n            c = _5875;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _439;\n    if (i.front_facing)\n    {\n        _439 = i.world_normal;\n    }\n    else\n    {\n        _439 = -i.world_normal;\n    }\n    vec3 _463 = normalize(i.world_tangent.xyz - (_439 * dot(_439, i.world_tangent.xyz)));\n    vec3 _490 = normalize(((_463 * m.x) + ((cross(_439, _463) * i.world_tangent.w) * m.y)) + (_439 * m.z));\n    vec3 _493;\n    if (i.front_facing)\n    {\n        _493 = _490;\n    }\n    else\n    {\n        _493 = -_490;\n    }\n    return _493;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5906 = fa_tex_fix(param_2, param_3);\n    vec4 _7339 = base_t;\n    _7339.x = _5906.x;\n    _7339.y = _5906.y;\n    _7339.z = _5906.z;\n    base_t = _7339;\n    vec4 _5920 = (_7339 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7164 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5952 = fa_tex_fix(param_6, param_7);\n        vec3 _5955 = (_5952 * 2.0) - vec3(1.0);\n        vec2 _5960 = _5955.xy * fa_mesh_fs_params[6].x;\n        vec3 _7347 = _5955;\n        _7347.x = _5960.x;\n        _7347.y = _5960.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7347;\n        _7164 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5988 = fa_tex_fix(param_12, param_13);\n    vec4 _7350 = mrt;\n    _7350.x = _5988.x;\n    _7350.y = _5988.y;\n    _7350.z = _5988.z;\n    mrt = _7350;\n    vec4 _6016 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6016.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6027 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6057 = fa_tex_fix(param_20, param_21);\n    float _7169 = fa_mesh_fs_params[20].x;\n    float _7170 = fa_mesh_fs_params[20].y;\n    float _7173 = fa_mesh_fs_params[20].z;\n    float _7172 = fa_mesh_fs_params[21].w;\n    float _7175 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7169 *= _6027.y;\n            _7170 *= _6027.z;\n            _7172 *= _6016.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7173 *= mrt.x;\n            _7175 *= mrt.w;\n        }\n    }\n    return Surface(_5920.xyz, _5920.w, _7164, clamp(fa_mesh_fs_params[5].x * _5988.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5988.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6027.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6057), _7169, _7170, fa_mesh_fs_params[21].xyz, _7172, _7173, fa_mesh_fs_params[20].w, _7175, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1725 = rect.zw - rect.xy;\n    vec2 _1729 = _1725 * atlas;\n    vec2 _1733 = ddx * _1729;\n    vec2 _1737 = ddy * _1729;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1725), clamp(0.5 * log2(max(max(dot(_1733, _1733), dot(_1737, _1737)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1770 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1777;\n    if (!_1770)\n    {\n        _1777 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1777 = _1770;\n    }\n    if (_1777)\n    {\n        return;\n    }\n    vec3 _1783 = dFdx(world_pos);\n    vec3 _1786 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1790 = fa_cluster_texel(param);\n    int _1794 = int(_1790.w);\n    if (_1794 < 1)\n    {\n        return;\n    }\n    int _1804 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1804;\n    vec4 _1808 = fa_light_texel(param_1);\n    vec2 _1811 = _1808.yz;\n    int _1815 = int(_1808.w);\n    int param_2 = _1804 + 1;\n    vec4 _1820 = fa_light_texel(param_2);\n    float _1821 = _1820.x;\n    int _1827 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1831 = int(_1790.z);\n    vec3 _2096;\n    for (int k = 0; k < _1794; k++)\n    {\n        int _1844 = _1831 + k;\n        int param_3 = _1815 + (_1844 >> 2);\n        int _1861 = (_1804 + 2) + (int(fa_light_texel(param_3)[_1844 & 3]) * 7);\n        int param_4 = _1861 + 6;\n        vec4 _1866 = fa_light_texel(param_4);\n        if (((int(_1866.w + 0.5) >> _1827) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1861;\n        vec4 _1881 = fa_light_texel(param_5);\n        int param_6 = _1861 + 1;\n        vec4 _1886 = fa_light_texel(param_6);\n        int param_7 = _1861 + 2;\n        vec4 _1891 = fa_light_texel(param_7);\n        vec3 _1894 = _1881.xyz;\n        float _1899 = dot(_1894, world_pos) + _1881.w;\n        vec3 _1901 = _1886.xyz;\n        float _1906 = dot(_1901, world_pos) + _1886.w;\n        vec3 _1908 = _1891.xyz;\n        float _1913 = dot(_1908, world_pos) + _1891.w;\n        bool _1918 = abs(_1899) > 0.5;\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1906) > 0.5;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        bool _1934;\n        if (!_1926)\n        {\n            _1934 = abs(_1913) > 0.5;\n        }\n        else\n        {\n            _1934 = _1926;\n        }\n        if (_1934)\n        {\n            continue;\n        }\n        float _1949 = clamp(dot(geo_normal, normalize(_1908)) * _1866.z, 0.0, 1.0);\n        if (_1949 <= 0.0)\n        {\n            continue;\n        }\n        float _1969 = (clamp((0.5 - abs(_1913)) * 10.0, 0.0, 1.0) * _1949) * _1866.x;\n        vec2 _1977 = vec2(_1899 + 0.5, 0.5 - _1906);\n        vec2 _1987 = vec2(dot(_1894, _1783), dot(_1901, _1783));\n        vec2 _1997 = vec2(dot(_1894, _1786), dot(_1901, _1786));\n        int param_8 = _1861 + 5;\n        vec4 _2002 = fa_light_texel(param_8);\n        int param_9 = _1861 + 3;\n        vec4 _2007 = fa_light_texel(param_9);\n        int param_10 = _1861 + 4;\n        vec4 _2012 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2002.xyz;\n        bool _2022 = _2007.z > _2007.x;\n        if (_2022)\n        {\n            vec4 param_11 = _2007;\n            vec2 param_12 = _1977;\n            vec2 param_13 = _1811;\n            vec2 param_14 = _1987;\n            vec2 param_15 = _1997;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1821 > 0.5) && (_1821 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2048 = fa_dc_to_linear(param_16);\n                vec4 _7244 = tx;\n                _7244.x = _2048.x;\n                _7244.y = _2048.y;\n                _7244.z = _2048.z;\n                tx = _7244;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1969 * tex_a) * _2002.w, 0.0, 1.0)));\n        if (_2012.z > _2012.x)\n        {\n            vec4 param_17 = _2012;\n            vec2 param_18 = _1977;\n            vec2 param_19 = _1811;\n            vec2 param_20 = _1987;\n            vec2 param_21 = _1997;\n            vec4 _2092 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1821 > 1.5)\n            {\n                vec3 param_22 = _2092.xyz;\n                vec3 _2102 = fa_dc_to_srgb(param_22);\n                _2096 = _2102;\n            }\n            else\n            {\n                _2096 = _2092.xyz;\n            }\n            vec3 _2111 = (_2096 * 2.0) - vec3(1.0);\n            vec2 _2116 = _2111.xy * _1866.y;\n            vec3 _2138 = (normalize(_1894) * _2116.x) + (normalize(_1901) * _2116.y);\n            vec3 _2141 = normalize(normal);\n            normal = normalize(mix(_2141, normalize((_2141 * max(_2111.z, 0.0500000007450580596923828125)) + (_2138 - (_2141 * dot(_2141, _2138)))), vec3(clamp(_1969 * (_2022 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3579 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3586 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3589 = int(_3579);\n    int _3592 = int(_3586);\n    float _3602 = _3586 - float(_3592);\n    int _3657 = (_3589 * 9) + _3592;\n    int _3677 = ((_3589 + 1) * 9) + _3592;\n    return mix(mix(_3653[_3657], _3653[_3657 + 1], _3602), mix(_3653[_3677], _3653[_3677 + 1], _3602), _3579 - float(_3589));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7087 = false;\n    float _7088 = 1.0;\n    float _7089 = 1.0;\n    float _7090 = 1.0;\n    float _7091 = 0.0;\n    float _7092 = 0.0;\n    float _7093 = 0.0;\n    float _7094 = 0.0;\n    float _7096 = 1.0;\n    bool _7097 = false;\n    vec3 _7098 = vec3(0.0);\n    float _7099 = 1.0;\n    float _7100 = 1.0;\n    float _7101 = 1.0;\n    float _7102 = 0.0;\n    float _7103 = 0.0;\n    vec3 _7104 = vec3(1.0, 0.0, 0.0);\n    vec3 _7105 = vec3(0.0, 0.0, 1.0);\n    float _7106 = 1.0;\n    float _7107 = 1.0;\n    float _3728 = clamp(s.specular, 0.0, 1.0);\n    float _3732 = clamp(s.ior, 1.0, 3.0);\n    bool _3737 = (_3728 != 1.0) || (_3732 != 1.5);\n    bool _3746;\n    if (!_3737)\n    {\n        _3746 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3746 = _3737;\n    }\n    if (_3746)\n    {\n        float _3754 = (_3732 - 1.0) / (_3732 + 1.0);\n        f0 = mix(min(vec3(_3754 * _3754) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3728, s.albedo, vec3(metallic));\n        _7088 = mix(_3728, 1.0, metallic);\n        _7087 = true;\n    }\n    float _3781 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3781 > 0.0)\n    {\n        float _3789 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7091 = _3781;\n        _7092 = _3789;\n        float _3796 = _3789 * _3789;\n        _7093 = _3796;\n        _7094 = _3796 * _3796;\n        float _3808 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7096 = _3808;\n        _7089 = 1.0 - (_3781 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3808, 0.0, 1.0), 5.0))));\n        _7087 = true;\n    }\n    vec3 _3827 = max(s.sheen_color, vec3(0.0));\n    float _3836 = max(_3827.x, max(_3827.y, _3827.z));\n    if (_3836 > 0.0)\n    {\n        float _3844 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7097 = true;\n        _7098 = _3827;\n        _7099 = _3844;\n        _7100 = _3844 * _3844;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3844;\n        float _3861 = fa_sheen_albedo(param, param_1);\n        _7102 = _3861;\n        _7101 = 1.0 - min(_3836 * _3861, 1.0);\n        _7087 = true;\n    }\n    _7090 = _7089 * _7101;\n    float _3880 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3880 != 0.0)\n    {\n        vec3 _3895 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3895;\n        if (dot(_3895, _3895) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3907 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3907.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3907.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3907.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3911 = t;\n        vec3 _3912 = normalize(_3911);\n        t = _3912;\n        vec3 _3937 = normalize((_3912 * cos(s.anisotropy_rotation)) + ((cross(n, _3912) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7104 = _3937;\n        _7105 = cross(n, _3937);\n        float _3947 = roughness * roughness;\n        float _3953 = mix(_3947, 1.0, _3880 * _3880);\n        bool _3955 = _3880 > 0.0;\n        _7106 = _3955 ? _3953 : _3947;\n        _7107 = _3955 ? _3947 : _3953;\n        _7103 = _3880;\n        _7087 = true;\n    }\n    return FaLayers(_7087, _7088, _7089, _7090, _7091, _7092, _7093, _7094, i.world_normal, _7096, _7097, _7098, _7099, _7100, _7101, _7102, _7103, _7104, _7105, _7106, _7107);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3336 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3336;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _743 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _756 = (c - (ru * hx)) - p;\n        vec3 _762 = ru * (2.0 * hx);\n        float _768 = max(dot(_762, _762), 9.9999999392252902907785028219223e-09);\n        float _772 = dot(_756, _762);\n        float t = clamp((-_772) / _768, 0.0, 1.0);\n        if (_743)\n        {\n            float _787 = dot(r, _762);\n            float _793 = _768 - (_787 * _787);\n            if (abs(_793) > (9.9999997473787516355514526367188e-06 * _768))\n            {\n                t = clamp(((dot(r, _756) * _787) - _772) / _793, 0.0, 1.0);\n            }\n        }\n        return (p + _756) + (_762 * t);\n    }\n    vec3 q = p;\n    float _825 = dot(r, axis);\n    bool _833;\n    if (_743)\n    {\n        _833 = abs(_825) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _833 = _743;\n    }\n    if (_833)\n    {\n        float _843 = dot(c - p, axis) / _825;\n        if (_843 > 0.0)\n        {\n            q = p + (r * _843);\n        }\n    }\n    vec3 _856 = q - c;\n    vec2 xy = vec2(dot(_856, ru), dot(_856, uu));\n    if (shape > 0.5)\n    {\n        float _871 = length(xy);\n        if (_871 > hx)\n        {\n            xy *= (hx / _871);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _505 = abs(d);\n    float _507 = _505.x;\n    float _509 = _505.y;\n    bool _510 = _507 >= _509;\n    bool _518;\n    if (_510)\n    {\n        _518 = _507 >= _505.z;\n    }\n    else\n    {\n        _518 = _510;\n    }\n    int _519;\n    if (_518)\n    {\n        _519 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _534;\n        if (_509 >= _505.z)\n        {\n            _534 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _534 = (d.z > 0.0) ? 4 : 5;\n        }\n        _519 = _534;\n    }\n    return _519;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _663 = dot(d, right);\n    float _667 = dot(d, up);\n    float _678;\n    if (((_663 * _663) + (_667 * _667)) > 1.0000000133514319600180897396058e-10)\n    {\n        _678 = atan(_667, _663) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _678 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_678 - floor(_678)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _909 = fa_light_base(param);\n    bool _913 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _909;\n    vec4 _917 = fa_light_texel(param_1);\n    int param_2 = _909 + 1;\n    vec4 _922 = fa_light_texel(param_2);\n    float _925 = _922.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _937 = _913 && (_925 > 2.5);\n    fa_light_is_area = _937;\n    bool _939 = _925 < 0.5;\n    vec3 l;\n    if (_939)\n    {\n        l = normalize(_917.xyz);\n        if (_913)\n        {\n            int param_3 = _909 + 6;\n            vec4 _953 = fa_light_texel(param_3);\n            if (_953.z > 0.5)\n            {\n                int param_4 = _909 + 4;\n                vec4 _963 = fa_light_texel(param_4);\n                int param_5 = _909 + 5;\n                vec4 _968 = fa_light_texel(param_5);\n                vec2 param_6 = _953.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _963.xyz) * _963.w, (-dot(world_pos, _968.xyz)) * _968.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _998 = _917.xyz;\n        vec3 _1000 = _998 - world_pos;\n        vec3 to_light = _1000;\n        float _1003 = length(_1000);\n        float reach = _1003;\n        bool front = true;\n        if (_937)\n        {\n            int param_8 = _909 + 7;\n            reach = max(_1003 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _909 + 4;\n            vec4 _1027 = fa_light_texel(param_9);\n            int param_10 = _909 + 5;\n            vec4 _1032 = fa_light_texel(param_10);\n            int param_11 = _909 + 6;\n            vec4 _1037 = fa_light_texel(param_11);\n            float _1038 = _1037.w;\n            int param_12 = _909 + 2;\n            vec3 _1045 = normalize(fa_light_texel(param_12).xyz);\n            bool _1047 = _1038 > 1.5;\n            bool _1055;\n            if (!_1047)\n            {\n                _1055 = dot(_1045, to_light) < 0.0;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            front = _1055;\n            vec3 r = vec3(0.0);\n            vec3 _1064 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1068 = dot(n, n) > 0.5;\n            bool _1076;\n            if (_1068)\n            {\n                _1076 = dot(_1064, _1064) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1076 = _1068;\n            }\n            if (_1076)\n            {\n                r = reflect(-normalize(_1064), normalize(n));\n            }\n            vec3 param_13 = _998;\n            vec3 param_14 = _1045;\n            vec3 param_15 = _1027.xyz;\n            vec3 param_16 = _1032.xyz;\n            float param_17 = _1027.w;\n            float param_18 = _1032.w;\n            float param_19 = _1038;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1112 = length(to_light);\n        dist = _1112;\n        l = to_light / vec3(max(_1112, 9.9999997473787516355514526367188e-05));\n        float _1126 = reach / max(_917.w, 0.001000000047497451305389404296875);\n        float _1132 = clamp(1.0 - (_1126 * _1126), 0.0, 1.0);\n        float _1134;\n        if (front)\n        {\n            _1134 = _1132 * _1132;\n        }\n        else\n        {\n            _1134 = 0.0;\n        }\n        atten = _1134;\n        bool _1145 = _925 < 2.5;\n        if ((_925 > 1.5) && _1145)\n        {\n            int param_22 = _909 + 2;\n            vec4 _1153 = fa_light_texel(param_22);\n            float _1163 = _1153.w;\n            int param_23 = _909 + 3;\n            vec4 _1168 = fa_light_texel(param_23);\n            float _1169 = _1168.x;\n            float cos_inner = _1169;\n            if (_1169 > 1.5)\n            {\n                cos_inner = mix(_1163, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1163, cos_inner, dot(-l, normalize(_1153.xyz)));\n        }\n        if (_913 && (_925 < 1.5))\n        {\n            int param_24 = _909 + 6;\n            vec4 _1193 = fa_light_texel(param_24);\n            if (_1193.z > 0.5)\n            {\n                vec3 _1201 = -to_light;\n                int param_25 = _909 + 4;\n                int param_26 = _909 + 5;\n                vec3 _1215 = fa_light_texel(param_25).xyz;\n                vec3 _1219 = fa_light_texel(param_26).xyz;\n                vec3 _1228 = vec3(dot(_1201, _1215), dot(_1201, _1219), dot(_1201, cross(_1215, _1219)));\n                vec3 param_27 = _1228;\n                int _1232 = fa_cube_face(param_27);\n                int param_28 = _1232;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1259 = vec2(dot(_1228, cross(param_29, param_30)), dot(_1228, param_30)) / vec2(max(dot(_1228, param_29), 9.9999997473787516355514526367188e-05));\n                int _1263 = _1232 / 3;\n                vec2 param_31 = _1193.xy + (vec2(float(_1232 - (_1263 * 3)), float(_1263)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1259.x), 0.5 - (0.5 * _1259.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _909 + 7;\n            vec4 _1293 = fa_light_texel(param_33);\n            if (_1293.z > 0.5)\n            {\n                int param_34 = _909 + 2;\n                int param_35 = _909 + 4;\n                int param_36 = _909 + 5;\n                vec2 param_37 = _1293.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_913 && _1145)\n            {\n                int param_42 = _909 + 6;\n                vec4 _1340 = fa_light_texel(param_42);\n                int param_43 = _909 + 7;\n                vec4 _1345 = fa_light_texel(param_43);\n                bool _1348 = _1340.z > 0.5;\n                bool _1355;\n                if (!_1348)\n                {\n                    _1355 = _1345.z > 0.5;\n                }\n                else\n                {\n                    _1355 = _1348;\n                }\n                if (_1355)\n                {\n                    int param_44 = _909 + 2;\n                    vec4 _1362 = fa_light_texel(param_44);\n                    vec3 _1366 = normalize(_1362.xyz);\n                    int param_45 = _909 + 4;\n                    vec4 _1371 = fa_light_texel(param_45);\n                    int param_46 = _909 + 5;\n                    vec4 _1376 = fa_light_texel(param_46);\n                    if (_1348)\n                    {\n                        vec3 _1384 = -to_light;\n                        float _1391 = _1362.w;\n                        float _1407 = 0.5 / max(dot(_1384, _1366) * (sqrt(max(1.0 - (_1391 * _1391), 0.0)) / max(_1391, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1340.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1384, _1371.xyz) * _1407), 0.5 - (dot(_1384, _1376.xyz) * _1407));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1345.z > 0.5)\n                    {\n                        vec2 param_49 = _1345.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1366;\n                        vec3 param_52 = _1371.xyz;\n                        vec3 param_53 = _1376.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7075 = _922.xyz * atten;\n    if (_913)\n    {\n        _7075 *= fa_light_tint;\n    }\n    int _1476;\n    if (_939)\n    {\n        _1476 = 0;\n    }\n    else\n    {\n        _1476 = ((_925 > 1.5) && (_925 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7075, atten, 1.0, dist, _1476);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2213;\n    if (i == 0)\n    {\n        _2213 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2229;\n        if (i == 1)\n        {\n            _2229 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2237;\n            if (i == 2)\n            {\n                _2237 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2237 = fa_shadows[24].w;\n            }\n            _2229 = _2237;\n        }\n        _2213 = _2229;\n    }\n    return _2213;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2270 = fa_shadow_depth(param, param_1);\n    float _2274;\n    if (conv.x < 0.5)\n    {\n        _2274 = _2270;\n    }\n    else\n    {\n        _2274 = (conv.y * conv.z) / (conv.z - (_2270 * (conv.z - conv.y)));\n    }\n    return _2274;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2201 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2201), sin(_2201)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2320 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2329;\n        if (k < 0.0)\n        {\n            _2329 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2329 = k;\n        }\n        float _2349 = clamp((_2329 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2320;\n            vec2 _2368 = fa_shadow_vogel(param_3, param_4, param_5) * _2349;\n            vec2 param_6 = uv + (_2368 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2380 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2380 < (zr - (length(_2368) * plane)))\n            {\n                sum += _2380;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2406 = sum / cnt;\n        float _2416;\n        if (k < 0.0)\n        {\n            _2416 = (-k) / max(_2406, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2416 = k;\n        }\n        radius = clamp(((max(zr - _2406, 0.0) * unit) * _2416) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2438 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2438; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2438;\n        float param_11 = _2320;\n        vec2 _2457 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2457 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2457) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2438);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2499 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2504 = clamp(dot(n, l), 0.0, 1.0);\n    float _2510 = sqrt(1.0 - (_2504 * _2504));\n    float _2517 = min(_2510 / max(_2504, 0.20000000298023223876953125), 4.0);\n    float _2522;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2522 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2522 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2547 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2522 * _2510)), 1.0);\n    float _2554 = _2547.x;\n    bool _2557 = _2554 < fa_shadows[ci * 1 + 16].x;\n    bool _2566;\n    if (!_2557)\n    {\n        _2566 = _2554 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2566 = _2557;\n    }\n    bool _2575;\n    if (!_2566)\n    {\n        _2575 = _2547.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2575 = _2566;\n    }\n    bool _2584;\n    if (!_2575)\n    {\n        _2584 = _2547.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2584 = _2575;\n    }\n    bool _2591;\n    if (!_2584)\n    {\n        _2591 = _2547.z > 1.0;\n    }\n    else\n    {\n        _2591 = _2584;\n    }\n    if (_2591)\n    {\n        return -1.0;\n    }\n    float _2599;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2599 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2599 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2547.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2547.z - ((_2599 * (1.0 + (0.5 * _2517))) / _2499);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2499;\n    float param_5 = _2499 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2517, 3.0)) * 0.5) / _2499;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2977 = int(fa_shadows[25].x + 0.5);\n    if (_2977 < 1)\n    {\n        return 1.0;\n    }\n    float _2992 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2977 - 1;\n    if (_2992 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3004 = _2977 > 1;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2992 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 1;\n    }\n    bool _3015 = _2977 > 2;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2992 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 2;\n    }\n    bool _3026 = _2977 > 3;\n    bool _3033;\n    if (_3026)\n    {\n        _3033 = _2992 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2977)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3059 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3059;\n        if (_3059 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3084;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3084 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3084 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3103 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3084, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3114 = clamp((_2992 - (fa_shadow_split_at(param_7) - _3103)) / _3103, 0.0, 1.0);\n        if (_3114 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2977)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3135 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3135;\n                if (_3135 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3114);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2657 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2664;\n    if (!_2657)\n    {\n        _2664 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2664 = _2657;\n    }\n    if (_2664)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2677 = fa_light_texel(param);\n    float _2678 = _2677.x;\n    if (_2678 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2687 = int(_2678 + 0.5);\n    int param_1 = _2687;\n    vec4 _2691 = fa_light_texel(param_1);\n    int param_2 = _2687 + 1;\n    vec4 _2696 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2699 = _2691.y;\n    if (_2699 > 0.0)\n    {\n        float _2716 = 1.0 - smoothstep(0.75 * _2699, _2699, length(world - fa_shadows[27].xyz));\n        fade = _2716;\n        if (_2716 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2691.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2740 = (_2687 + 2) + (face * 6);\n    int param_4 = _2740;\n    int param_5 = _2740 + 1;\n    int param_6 = _2740 + 3;\n    vec4 _2754 = fa_light_texel(param_6);\n    int param_7 = _2740 + 4;\n    vec4 _2759 = fa_light_texel(param_7);\n    int param_8 = _2740 + 5;\n    vec4 _2764 = fa_light_texel(param_8);\n    float _2776 = _2764.x * max(dot(_2754, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2781 = clamp(dot(n, l), 0.0, 1.0);\n    float _2804 = clamp(dot(n, _2754.xyz), -1.0, 1.0);\n    float _2823 = min(sqrt(1.0 - (_2804 * _2804)) / max(abs(dot(n, world - lpos)) / max(dot(_2754, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2826 = _2696.y;\n    float _2828;\n    if (_2826 > 0.0)\n    {\n        _2828 = _2826;\n    }\n    else\n    {\n        _2828 = 1.5 * _2776;\n    }\n    vec4 _2848 = vec4(world + (n * (_2828 * sqrt(1.0 - (_2781 * _2781)))), 1.0);\n    float _2852 = dot(_2754, _2848);\n    float _2855 = _2764.y;\n    if (_2852 < _2855)\n    {\n        return 1.0;\n    }\n    vec2 _2870 = vec2(dot(fa_light_texel(param_4), _2848), dot(fa_light_texel(param_5), _2848)) / vec2(_2852);\n    float _2872 = _2870.x;\n    bool _2875 = _2872 < _2759.x;\n    bool _2884;\n    if (!_2875)\n    {\n        _2884 = _2872 > _2759.z;\n    }\n    else\n    {\n        _2884 = _2875;\n    }\n    bool _2893;\n    if (!_2884)\n    {\n        _2893 = _2870.y < _2759.y;\n    }\n    else\n    {\n        _2893 = _2884;\n    }\n    bool _2902;\n    if (!_2893)\n    {\n        _2902 = _2870.y > _2759.w;\n    }\n    else\n    {\n        _2902 = _2893;\n    }\n    if (_2902)\n    {\n        return 1.0;\n    }\n    float _2908 = _2696.x;\n    float _2910;\n    if (_2908 > 0.0)\n    {\n        _2910 = _2908;\n    }\n    else\n    {\n        _2910 = 1.5 * _2776;\n    }\n    vec2 param_9 = _2870;\n    vec4 param_10 = _2759;\n    float param_11 = _2852 - (_2910 * (1.0 + (0.5 * _2823)));\n    float param_12 = _2776;\n    float param_13 = 1.0;\n    float param_14 = _2764.z * 0.25;\n    float param_15 = (_2776 * min(_2823, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2855, _2764.z);\n    int param_17 = int(_2691.z + 0.5);\n    float param_18 = _2691.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4465 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4472;\n    if (!_4465)\n    {\n        _4472 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4472 = _4465;\n    }\n    if (_4472)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4485 = fa_light_texel(param);\n    float _4486 = _4485.y;\n    float len = _4486;\n    if (_4486 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4498 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4508 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4498);\n    if (_4508 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4514 = len;\n    float _4517 = min(_4514, 0.89999997615814208984375 * dist);\n    len = _4517;\n    float _4522 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4498);\n    float _4527 = _4522 + (0.5 * _4517);\n    vec3 _4533 = world + (gn * _4522);\n    float _4535 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4599;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4550 = (float(k) + _4535) * 0.083333335816860198974609375;\n        vec3 _4558 = _4533 + (l * (_4550 * len));\n        vec4 _4564 = vec4(_4558, 1.0);\n        float _4570 = dot(fa_mesh_fs_params[28], _4564);\n        if (_4570 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4590 = vec2(dot(fa_mesh_fs_params[26], _4564), dot(fa_mesh_fs_params[27], _4564)) / vec2(_4570);\n        float _4594 = _4590.x * 0.5;\n        float _4595 = _4594 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4599 = (_4590.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4599 = 0.5 - (_4590.y * 0.5);\n        }\n        bool _4615 = _4595 < 0.0;\n        bool _4622;\n        if (!_4615)\n        {\n            _4622 = _4595 >= 1.0;\n        }\n        else\n        {\n            _4622 = _4615;\n        }\n        bool _4629;\n        if (!_4622)\n        {\n            _4629 = _4599 < 0.0;\n        }\n        else\n        {\n            _4629 = _4622;\n        }\n        bool _4636;\n        if (!_4629)\n        {\n            _4636 = _4599 >= 1.0;\n        }\n        else\n        {\n            _4636 = _4629;\n        }\n        if (_4636)\n        {\n            break;\n        }\n        vec4 _4655 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4595, _4599) * fa_mesh_fs_params[24].zw), 0);\n        if (_4655.w < 0.5)\n        {\n            continue;\n        }\n        float _4674 = (dot(fa_mesh_fs_params[29].xyz, _4558) + fa_mesh_fs_params[29].w) - _4655.x;\n        if ((_4674 > _4522) && (_4674 < _4527))\n        {\n            occ = max(occ, (1.0 - (_4550 * _4550)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4595, 0.5 - _4594), min(_4599, 1.0 - _4599))));\n        }\n    }\n    return 1.0 - (occ * _4508);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4750 = fa_lm.z > 0.5;\n    bool _4756;\n    if (_4750)\n    {\n        int param = li;\n        _4756 = fa_light_baked(param);\n    }\n    else\n    {\n        _4756 = _4750;\n    }\n    if (_4756)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4780 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7144 = _4780.color;\n    float _7146 = _4780.shadow;\n    bool _4783 = _4780.type == 0;\n    if (_4783 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4780.direction;\n        float _4794 = fa_shadow_factor(param_5, param_6);\n        _7146 = _4794;\n        _7144 *= _4794;\n    }\n    else\n    {\n        bool _4805 = _4780.type != 0;\n        bool _4811;\n        if (_4805)\n        {\n            _4811 = _4780.attenuation > 0.0;\n        }\n        else\n        {\n            _4811 = _4805;\n        }\n        if (_4811)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4780.direction;\n            float _4830 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7146 = _4830;\n            _7144 *= _4830;\n        }\n    }\n    bool _4840 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4846;\n    if (_4840)\n    {\n        _4846 = _4780.attenuation > 0.0;\n    }\n    else\n    {\n        _4846 = _4840;\n    }\n    if (_4846)\n    {\n        float _4853;\n        if (_4783)\n        {\n            _4853 = 1000000000.0;\n        }\n        else\n        {\n            _4853 = _4780._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4780.direction;\n        float param_18 = _4853;\n        float _4871 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7146 *= _4871;\n        _7144 *= _4871;\n    }\n    return LightSample(_4780.direction, _7144, _4780.attenuation, _7146, _4780._distance, _4780.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4914 = v - (n * dot(v, n));\n    vec3 t = _4914;\n    float _4918 = dot(_4914, _4914);\n    float l2 = _4918;\n    if (_4918 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4928;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4928 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4928 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4928;\n        l2 = dot(_4928, _4928);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4963 = dot(a, a);\n    float _4967 = dot(b, b);\n    if ((_4963 < 1.0000000195414813782625560981111e-24) || (_4967 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4981 = a * inversesqrt(_4963);\n    vec3 _4986 = b * inversesqrt(_4967);\n    float _4990 = dot(_4981, _4986);\n    float _4993 = abs(_4990);\n    float g = (((((((((((0.0416471660137176513671875 * _4993) - 0.1924748718738555908203125) * _4993) + 0.4179156124591827392578125) * _4993) - 0.616057217121124267578125) * _4993) + 0.777722418308258056640625) * _4993) - 0.999542415142059326171875) * _4993) + 1.570791721343994140625;\n    if (_4990 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4990 * _4990), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4981, _4986) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5050 = a.z > 0.0;\n    bool _5054 = b.z > 0.0;\n    if (_5050 && _5054)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5050 != _5054)\n        {\n            vec3 _5089 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5089.z = 0.0;\n            if (_5050)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5089;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5089;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5089;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5089;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5138 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5164 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5190 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5216 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5138;\n    vec3 param_1 = _5164;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5164;\n    vec3 param_7 = _5190;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5190;\n    vec3 param_13 = _5216;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5216;\n    vec3 param_19 = _5138;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5366 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5390 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5406 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5366;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5390;\n    vec4 param_9 = m;\n    vec3 param_10 = _5366;\n    vec3 param_11 = _5390;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5406;\n    vec4 param_14 = m;\n    vec3 param_15 = _5366;\n    vec3 param_16 = _5406;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5464 = fa_light_base(param);\n    int param_1 = _5464;\n    int param_2 = _5464 + 1;\n    int param_3 = _5464 + 2;\n    int param_4 = _5464 + 4;\n    vec4 _5486 = fa_light_texel(param_4);\n    int param_5 = _5464 + 5;\n    vec4 _5491 = fa_light_texel(param_5);\n    int param_6 = _5464 + 6;\n    vec4 _5496 = fa_light_texel(param_6);\n    float _5497 = _5496.w;\n    vec3 _5502 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5504 = _5497 < 1.5;\n    bool _5511;\n    if (_5504)\n    {\n        _5511 = dot(normalize(fa_light_texel(param_3).xyz), _5502) >= 0.0;\n    }\n    else\n    {\n        _5511 = _5504;\n    }\n    if (_5511)\n    {\n        return vec3(0.0);\n    }\n    bool _5520 = (_5497 > 0.5) && _5504;\n    float _5524 = _5520 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5527 = _5486.xyz;\n    float _5529 = _5486.w;\n    vec3 _5535 = _5491.xyz;\n    float _5537 = _5491.w;\n    vec3 up = _5535 * (_5537 * _5524);\n    float _5543;\n    if (_5520)\n    {\n        _5543 = (3.1415927410125732421875 * _5529) * _5529;\n    }\n    else\n    {\n        _5543 = (4.0 * _5529) * _5537;\n    }\n    if (_5497 > 1.5)\n    {\n        vec3 _5569 = cross(_5527, -_5502);\n        vec3 perp = _5569;\n        float _5573 = dot(_5569, _5569);\n        vec3 _5576;\n        if (_5573 > 1.0000000133514319600180897396058e-10)\n        {\n            _5576 = perp * inversesqrt(_5573);\n        }\n        else\n        {\n            _5576 = _5535;\n        }\n        perp = _5576;\n        up = _5576 * _5537;\n    }\n    float _5597 = max(_5543, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5607 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5607;\n    vec3 param_10 = n;\n    vec3 param_11 = _5502;\n    vec3 _5615 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5607;\n    vec3 param_13 = n;\n    vec3 param_14 = _5527 * (_5529 * _5524);\n    vec3 _5623 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5607;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5631 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5497;\n    vec3 param_20 = _5615;\n    vec3 param_21 = _5623;\n    vec3 param_22 = _5631;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5650 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5650;\n    vec2 param_26 = _5650 + vec2(64.0, 0.0);\n    vec4 _5660 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5497;\n    vec3 param_29 = _5615;\n    vec3 param_30 = _5623;\n    vec3 param_31 = _5631;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5660.x) + ((vec3(f90) - f0) * _5660.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5502, _5502)) + _5597) / _5597) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4202 = 1.0 / alpha;\n    return ((2.0 + _4202) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4202)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4237 = max(dot(L.nc, l), 0.0);\n    float _4243 = max(dot(L.nc, h), 0.0);\n    float _4252 = ((_4243 * _4243) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4252) * _4252)) * (0.5 / max(mix((2.0 * _4237) * L.coat_ndv, _4237 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4237)) * _4237;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5728;\n    if (L.sheen_on)\n    {\n        _5728 = L.sheen_scale;\n    }\n    else\n    {\n        _5728 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5728);\n    vec3 _5741 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5752 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5761 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5741), 0.0);\n        float param_13 = _5761;\n        float param_14 = ndv;\n        result += ((L.sheen * _5752) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5761)) * _5761) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5741;\n        float param_18 = max(dot(v, _5741), 0.0);\n        result += (_5752 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4105 = tdh / at;\n    float _4109 = bdh / ab;\n    float _4121 = ((_4105 * _4105) + (_4109 * _4109)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4121) * _4121);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4301 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4380 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4380) * _4380);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4301);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4301));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3511 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3514 = _3511.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3514 * _3514, exp2((-9.27999973297119140625) * ndv)) * _3514) + _3511.y)) + _3511.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3365 = rough * rough;\n    float _3395 = 0.60000002384185791015625 * _3365;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3365)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3395, 0.0500000007450580596923828125 + _3395, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3365 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3988;\n        if (L.aniso >= 0.0)\n        {\n            _3988 = L.b;\n        }\n        else\n        {\n            _3988 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3988, v), _3988), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4021 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4021.x) + (vec3(L.f90) * _4021.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4076 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4076.x) + _4076.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3553 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3553.x) + vec3(_3553.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3159 = int(fa_shadows[25].x + 0.5);\n    float _3169 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3174 = _3159 > 0;\n    bool _3183;\n    if (_3174)\n    {\n        int param = _3159 - 1;\n        _3183 = _3169 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3183 = _3174;\n    }\n    if (_3183)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3189 = _3159 > 1;\n        bool _3196;\n        if (_3189)\n        {\n            _3196 = _3169 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3196 = _3189;\n        }\n        if (_3196)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3202 = _3159 > 2;\n        bool _3209;\n        if (_3202)\n        {\n            _3209 = _3169 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3209 = _3202;\n        }\n        if (_3209)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3215 = _3159 > 3;\n        bool _3222;\n        if (_3215)\n        {\n            _3222 = _3169 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3222 = _3215;\n        }\n        if (_3222)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6844 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6844 = -_6844;\n    }\n    vec3 _6197 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6844, fa_world_tangent, fa_uv, fa_vertex_color, _6197, gl_FrontFacing);\n    Surface _6205 = fa_standard_surface(param_1);\n    vec3 _6875 = _6205.albedo;\n    float _6876 = _6205.alpha;\n    vec3 _6877 = _6205.normal;\n    float _6878 = _6205.metallic;\n    float _6879 = _6205.roughness;\n    float _6880 = _6205.occlusion;\n    vec3 _6881 = _6205.emission;\n    float _6882 = _6205.clearcoat;\n    float _6883 = _6205.clearcoat_roughness;\n    vec3 _6884 = _6205.sheen_color;\n    float _6885 = _6205.sheen_roughness;\n    float _6886 = _6205.anisotropy;\n    float _6887 = _6205.anisotropy_rotation;\n    float _6888 = _6205.specular;\n    float _6889 = _6205.ior;\n    vec3 _6890 = _6205.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6844, fa_world_tangent, fa_uv, fa_vertex_color, _6197, gl_FrontFacing);\n    Surface param_3 = _6205;\n    surface(param_2, param_3);\n    _6875 = param_3.albedo;\n    _6876 = param_3.alpha;\n    _6877 = param_3.normal;\n    _6878 = param_3.metallic;\n    _6879 = param_3.roughness;\n    _6880 = param_3.occlusion;\n    _6881 = param_3.emission;\n    _6882 = param_3.clearcoat;\n    _6883 = param_3.clearcoat_roughness;\n    _6884 = param_3.sheen_color;\n    _6885 = param_3.sheen_roughness;\n    _6886 = param_3.anisotropy;\n    _6887 = param_3.anisotropy_rotation;\n    _6888 = param_3.specular;\n    _6889 = param_3.ior;\n    _6890 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6844;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6875 = param_6;\n    _6877 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6875;\n    }\n    else\n    {\n        vec3 _6244 = normalize(_6877);\n        float _6251 = clamp(_6878, 0.0, 1.0);\n        float _6255 = clamp(_6879, 0.0500000007450580596923828125, 1.0);\n        float _6259 = _6255 * _6255;\n        float _6263 = _6259 * _6259;\n        float _6268 = max(dot(_6244, _6197), 9.9999997473787516355514526367188e-05);\n        vec3 _6274 = _6875 * (1.0 - _6251);\n        vec3 _6281 = mix(vec3(0.039999999105930328369140625), _6875, vec3(_6251));\n        vec3 f0 = _6281;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6844, fa_world_tangent, fa_uv, fa_vertex_color, _6197, gl_FrontFacing);\n        Surface param_9 = Surface(_6875, _6876, _6877, _6878, _6879, _6880, _6881, _6882, _6883, _6884, _6885, _6886, _6887, _6888, _6889, _6890);\n        vec3 param_10 = _6244;\n        vec3 param_11 = _6197;\n        float param_12 = _6251;\n        float param_13 = _6255;\n        vec3 param_14 = _6281;\n        FaLayers _6297 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6244;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6274) * _6880;\n        if (_6297.on)\n        {\n            lit *= _6297.base_scale;\n        }\n        int _6319 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6319; ln++)\n        {\n            int param_16 = ln;\n            int _6332 = fa_cl_light(param_16);\n            bool _6335 = fa_lm.z > 0.5;\n            bool _6341;\n            if (_6335)\n            {\n                int param_17 = _6332;\n                _6341 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6341 = _6335;\n            }\n            if (_6341)\n            {\n                continue;\n            }\n            int param_18 = _6332;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6844;\n            LightSample _6353 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6361 = max(dot(_6244, _6353.direction), 0.0);\n            float _6367 = _6353.attenuation * _6353.shadow;\n            vec3 _6372 = normalize(_6353.direction + _6197);\n            float _6377 = max(dot(_6244, _6372), 0.0);\n            float _6382 = max(dot(_6197, _6372), 0.0);\n            bool _6389;\n            if (fa_light_is_area)\n            {\n                _6389 = !_6297.on;\n            }\n            else\n            {\n                _6389 = fa_light_is_area;\n            }\n            if (_6389)\n            {\n                int param_21 = _6332;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6244;\n                vec3 param_24 = _6197;\n                vec3 param_25 = _6274;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6255;\n                float param_29 = _6268;\n                float param_30 = _6367;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6297;\n                    int param_32 = _6332;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6244;\n                    vec3 param_35 = _6197;\n                    vec3 param_36 = _6353.direction;\n                    vec3 param_37 = _6274;\n                    vec3 param_38 = f0;\n                    float param_39 = _6255;\n                    float param_40 = _6268;\n                    float param_41 = _6367;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6297.on)\n                    {\n                        FaLayers param_42 = _6297;\n                        vec3 param_43 = _6274;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6244;\n                        vec3 param_46 = _6197;\n                        vec3 param_47 = _6353.direction;\n                        vec3 param_48 = _6372;\n                        float param_49 = _6361;\n                        float param_50 = _6268;\n                        float param_51 = _6377;\n                        float param_52 = _6382;\n                        float param_53 = _6259;\n                        float param_54 = _6263;\n                        int param_55 = _6332;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6367));\n                    }\n                    else\n                    {\n                        float _6495 = ((_6377 * _6377) * (_6263 - 1.0)) + 1.0;\n                        int param_56 = _6332;\n                        lit += (((_6274 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6382, 5.0))) * (((_6263 / ((3.1415927410125732421875 * _6495) * _6495)) * (0.5 / max(mix((2.0 * _6361) * _6268, _6361 + _6268, _6259), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6361))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6361 * _6367));\n                    }\n                }\n            }\n        }\n        if (_6297.on)\n        {\n            FaLayers param_57 = _6297;\n            vec3 param_58 = _6244;\n            vec3 param_59 = _6197;\n            vec3 param_60 = f0;\n            float param_61 = _6255;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6880);\n        }\n        else\n        {\n            vec3 param_62 = _6244;\n            vec3 param_63 = _6197;\n            vec3 param_64 = f0;\n            float param_65 = _6255;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6880);\n        }\n        result = lit;\n    }\n    vec3 _6590 = result;\n    vec3 _6591 = _6590 + _6881;\n    result = _6591;\n    vec3 param_66 = _6591;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6600 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6607;\n    if (!_6600)\n    {\n        _6607 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6607 = _6600;\n    }\n    if (_6607)\n    {\n        vec3 _6616 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6622 = dot(_6616, fa_mesh_fs_params[9].xyz);\n        bool _6626 = fa_mesh_fs_params[9].w > 0.5;\n        float _6627;\n        if (_6626)\n        {\n            _6627 = _6622;\n        }\n        else\n        {\n            _6627 = length(_6616);\n        }\n        float _6639 = _6627 - fa_mesh_fs_params[8].x;\n        if (_6639 > 0.0)\n        {\n            float _6648 = fa_mesh_fs_params[7].w * _6639;\n            float tau = _6648 * _6648;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6664;\n                if (_6626)\n                {\n                    _6664 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6622);\n                }\n                else\n                {\n                    _6664 = fa_mesh_fs_params[0].y;\n                }\n                float _6685 = mix(_6664, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6627, 0.0, 1.0));\n                float _6689 = fa_world_pos.y - _6685;\n                float _6694 = _6685 - fa_mesh_fs_params[8].z;\n                float _6699 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6702 = _6694 <= 0.0;\n                bool _6703 = !_6702;\n                bool _6709;\n                if (_6703)\n                {\n                    _6709 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6709 = _6702;\n                }\n                float _6710;\n                if (_6709)\n                {\n                    _6710 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6710 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6694, 80.0));\n                }\n                bool _6737;\n                if (_6703)\n                {\n                    _6737 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6737 = _6702;\n                }\n                float _6738;\n                if (_6737)\n                {\n                    _6738 = fa_mesh_fs_params[8].y * _6694;\n                }\n                else\n                {\n                    _6738 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6694, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6763 = _6699 <= 0.0;\n                bool _6770;\n                if (!_6763)\n                {\n                    _6770 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6770 = _6763;\n                }\n                float _6771;\n                if (_6770)\n                {\n                    _6771 = fa_mesh_fs_params[8].y * _6699;\n                }\n                else\n                {\n                    _6771 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6699, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6798;\n                if (abs(_6689) < 0.001000000047497451305389404296875)\n                {\n                    _6798 = _6710;\n                }\n                else\n                {\n                    _6798 = (_6771 - _6738) / _6689;\n                }\n                tau += (_6639 * max(_6798, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6876);\n}\n\n",
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
            "inst_name": "_182",
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
            "inst_name": "_252",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_556",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2223",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3653[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1494 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1501;\n    if (!_1494)\n    {\n        _1501 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1501 = _1494;\n    }\n    bool _1509;\n    if (!_1501)\n    {\n        _1509 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1509 = _1501;\n    }\n    bool _1516;\n    if (!_1509)\n    {\n        _1516 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1516 = _1509;\n    }\n    bool _1523;\n    if (!_1516)\n    {\n        _1523 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1523 = _1516;\n    }\n    if (_1523)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1533 = vec4(world_pos, 1.0);\n    float _1539 = dot(fa_mesh_fs_params[16], _1533);\n    if (!(_1539 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1561 = vec2(dot(fa_mesh_fs_params[14], _1533), dot(fa_mesh_fs_params[15], _1533)) / vec2(_1539);\n    int _1565 = int(fa_mesh_fs_params[18].x);\n    int _1569 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1569) + clamp(int(floor(((_1561.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1569 - 1)) * _1565)) + clamp(int(floor(((_1561.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1565 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1645 = fa_cluster_texel(param);\n    return ivec2(int(_1645.x), int(_1645.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4723 = fa_cluster_lookup(param);\n    fa_cl_slot = _4723.x;\n    fa_cl_local = _4723.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5867 = fa_linear_to_srgb(param);\n        c = _5867;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5875 = fa_srgb_to_linear(param_1);\n            c = _5875;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _439;\n    if (i.front_facing)\n    {\n        _439 = i.world_normal;\n    }\n    else\n    {\n        _439 = -i.world_normal;\n    }\n    vec3 _463 = normalize(i.world_tangent.xyz - (_439 * dot(_439, i.world_tangent.xyz)));\n    vec3 _490 = normalize(((_463 * m.x) + ((cross(_439, _463) * i.world_tangent.w) * m.y)) + (_439 * m.z));\n    vec3 _493;\n    if (i.front_facing)\n    {\n        _493 = _490;\n    }\n    else\n    {\n        _493 = -_490;\n    }\n    return _493;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5906 = fa_tex_fix(param_2, param_3);\n    vec4 _7339 = base_t;\n    _7339.x = _5906.x;\n    _7339.y = _5906.y;\n    _7339.z = _5906.z;\n    base_t = _7339;\n    vec4 _5920 = (_7339 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7164 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5952 = fa_tex_fix(param_6, param_7);\n        vec3 _5955 = (_5952 * 2.0) - vec3(1.0);\n        vec2 _5960 = _5955.xy * fa_mesh_fs_params[6].x;\n        vec3 _7347 = _5955;\n        _7347.x = _5960.x;\n        _7347.y = _5960.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7347;\n        _7164 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5988 = fa_tex_fix(param_12, param_13);\n    vec4 _7350 = mrt;\n    _7350.x = _5988.x;\n    _7350.y = _5988.y;\n    _7350.z = _5988.z;\n    mrt = _7350;\n    vec4 _6016 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6016.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6027 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6057 = fa_tex_fix(param_20, param_21);\n    float _7169 = fa_mesh_fs_params[20].x;\n    float _7170 = fa_mesh_fs_params[20].y;\n    float _7173 = fa_mesh_fs_params[20].z;\n    float _7172 = fa_mesh_fs_params[21].w;\n    float _7175 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7169 *= _6027.y;\n            _7170 *= _6027.z;\n            _7172 *= _6016.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7173 *= mrt.x;\n            _7175 *= mrt.w;\n        }\n    }\n    return Surface(_5920.xyz, _5920.w, _7164, clamp(fa_mesh_fs_params[5].x * _5988.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5988.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6027.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6057), _7169, _7170, fa_mesh_fs_params[21].xyz, _7172, _7173, fa_mesh_fs_params[20].w, _7175, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1725 = rect.zw - rect.xy;\n    vec2 _1729 = _1725 * atlas;\n    vec2 _1733 = ddx * _1729;\n    vec2 _1737 = ddy * _1729;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1725), clamp(0.5 * log2(max(max(dot(_1733, _1733), dot(_1737, _1737)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1770 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1777;\n    if (!_1770)\n    {\n        _1777 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1777 = _1770;\n    }\n    if (_1777)\n    {\n        return;\n    }\n    vec3 _1783 = dFdx(world_pos);\n    vec3 _1786 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1790 = fa_cluster_texel(param);\n    int _1794 = int(_1790.w);\n    if (_1794 < 1)\n    {\n        return;\n    }\n    int _1804 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1804;\n    vec4 _1808 = fa_light_texel(param_1);\n    vec2 _1811 = _1808.yz;\n    int _1815 = int(_1808.w);\n    int param_2 = _1804 + 1;\n    vec4 _1820 = fa_light_texel(param_2);\n    float _1821 = _1820.x;\n    int _1827 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1831 = int(_1790.z);\n    vec3 _2096;\n    for (int k = 0; k < _1794; k++)\n    {\n        int _1844 = _1831 + k;\n        int param_3 = _1815 + (_1844 >> 2);\n        int _1861 = (_1804 + 2) + (int(fa_light_texel(param_3)[_1844 & 3]) * 7);\n        int param_4 = _1861 + 6;\n        vec4 _1866 = fa_light_texel(param_4);\n        if (((int(_1866.w + 0.5) >> _1827) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1861;\n        vec4 _1881 = fa_light_texel(param_5);\n        int param_6 = _1861 + 1;\n        vec4 _1886 = fa_light_texel(param_6);\n        int param_7 = _1861 + 2;\n        vec4 _1891 = fa_light_texel(param_7);\n        vec3 _1894 = _1881.xyz;\n        float _1899 = dot(_1894, world_pos) + _1881.w;\n        vec3 _1901 = _1886.xyz;\n        float _1906 = dot(_1901, world_pos) + _1886.w;\n        vec3 _1908 = _1891.xyz;\n        float _1913 = dot(_1908, world_pos) + _1891.w;\n        bool _1918 = abs(_1899) > 0.5;\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1906) > 0.5;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        bool _1934;\n        if (!_1926)\n        {\n            _1934 = abs(_1913) > 0.5;\n        }\n        else\n        {\n            _1934 = _1926;\n        }\n        if (_1934)\n        {\n            continue;\n        }\n        float _1949 = clamp(dot(geo_normal, normalize(_1908)) * _1866.z, 0.0, 1.0);\n        if (_1949 <= 0.0)\n        {\n            continue;\n        }\n        float _1969 = (clamp((0.5 - abs(_1913)) * 10.0, 0.0, 1.0) * _1949) * _1866.x;\n        vec2 _1977 = vec2(_1899 + 0.5, 0.5 - _1906);\n        vec2 _1987 = vec2(dot(_1894, _1783), dot(_1901, _1783));\n        vec2 _1997 = vec2(dot(_1894, _1786), dot(_1901, _1786));\n        int param_8 = _1861 + 5;\n        vec4 _2002 = fa_light_texel(param_8);\n        int param_9 = _1861 + 3;\n        vec4 _2007 = fa_light_texel(param_9);\n        int param_10 = _1861 + 4;\n        vec4 _2012 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2002.xyz;\n        bool _2022 = _2007.z > _2007.x;\n        if (_2022)\n        {\n            vec4 param_11 = _2007;\n            vec2 param_12 = _1977;\n            vec2 param_13 = _1811;\n            vec2 param_14 = _1987;\n            vec2 param_15 = _1997;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1821 > 0.5) && (_1821 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2048 = fa_dc_to_linear(param_16);\n                vec4 _7244 = tx;\n                _7244.x = _2048.x;\n                _7244.y = _2048.y;\n                _7244.z = _2048.z;\n                tx = _7244;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1969 * tex_a) * _2002.w, 0.0, 1.0)));\n        if (_2012.z > _2012.x)\n        {\n            vec4 param_17 = _2012;\n            vec2 param_18 = _1977;\n            vec2 param_19 = _1811;\n            vec2 param_20 = _1987;\n            vec2 param_21 = _1997;\n            vec4 _2092 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1821 > 1.5)\n            {\n                vec3 param_22 = _2092.xyz;\n                vec3 _2102 = fa_dc_to_srgb(param_22);\n                _2096 = _2102;\n            }\n            else\n            {\n                _2096 = _2092.xyz;\n            }\n            vec3 _2111 = (_2096 * 2.0) - vec3(1.0);\n            vec2 _2116 = _2111.xy * _1866.y;\n            vec3 _2138 = (normalize(_1894) * _2116.x) + (normalize(_1901) * _2116.y);\n            vec3 _2141 = normalize(normal);\n            normal = normalize(mix(_2141, normalize((_2141 * max(_2111.z, 0.0500000007450580596923828125)) + (_2138 - (_2141 * dot(_2141, _2138)))), vec3(clamp(_1969 * (_2022 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3579 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3586 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3589 = int(_3579);\n    int _3592 = int(_3586);\n    float _3602 = _3586 - float(_3592);\n    int _3657 = (_3589 * 9) + _3592;\n    int _3677 = ((_3589 + 1) * 9) + _3592;\n    return mix(mix(_3653[_3657], _3653[_3657 + 1], _3602), mix(_3653[_3677], _3653[_3677 + 1], _3602), _3579 - float(_3589));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7087 = false;\n    float _7088 = 1.0;\n    float _7089 = 1.0;\n    float _7090 = 1.0;\n    float _7091 = 0.0;\n    float _7092 = 0.0;\n    float _7093 = 0.0;\n    float _7094 = 0.0;\n    float _7096 = 1.0;\n    bool _7097 = false;\n    vec3 _7098 = vec3(0.0);\n    float _7099 = 1.0;\n    float _7100 = 1.0;\n    float _7101 = 1.0;\n    float _7102 = 0.0;\n    float _7103 = 0.0;\n    vec3 _7104 = vec3(1.0, 0.0, 0.0);\n    vec3 _7105 = vec3(0.0, 0.0, 1.0);\n    float _7106 = 1.0;\n    float _7107 = 1.0;\n    float _3728 = clamp(s.specular, 0.0, 1.0);\n    float _3732 = clamp(s.ior, 1.0, 3.0);\n    bool _3737 = (_3728 != 1.0) || (_3732 != 1.5);\n    bool _3746;\n    if (!_3737)\n    {\n        _3746 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3746 = _3737;\n    }\n    if (_3746)\n    {\n        float _3754 = (_3732 - 1.0) / (_3732 + 1.0);\n        f0 = mix(min(vec3(_3754 * _3754) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3728, s.albedo, vec3(metallic));\n        _7088 = mix(_3728, 1.0, metallic);\n        _7087 = true;\n    }\n    float _3781 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3781 > 0.0)\n    {\n        float _3789 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7091 = _3781;\n        _7092 = _3789;\n        float _3796 = _3789 * _3789;\n        _7093 = _3796;\n        _7094 = _3796 * _3796;\n        float _3808 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7096 = _3808;\n        _7089 = 1.0 - (_3781 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3808, 0.0, 1.0), 5.0))));\n        _7087 = true;\n    }\n    vec3 _3827 = max(s.sheen_color, vec3(0.0));\n    float _3836 = max(_3827.x, max(_3827.y, _3827.z));\n    if (_3836 > 0.0)\n    {\n        float _3844 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7097 = true;\n        _7098 = _3827;\n        _7099 = _3844;\n        _7100 = _3844 * _3844;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3844;\n        float _3861 = fa_sheen_albedo(param, param_1);\n        _7102 = _3861;\n        _7101 = 1.0 - min(_3836 * _3861, 1.0);\n        _7087 = true;\n    }\n    _7090 = _7089 * _7101;\n    float _3880 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3880 != 0.0)\n    {\n        vec3 _3895 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3895;\n        if (dot(_3895, _3895) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3907 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3907.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3907.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3907.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3911 = t;\n        vec3 _3912 = normalize(_3911);\n        t = _3912;\n        vec3 _3937 = normalize((_3912 * cos(s.anisotropy_rotation)) + ((cross(n, _3912) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7104 = _3937;\n        _7105 = cross(n, _3937);\n        float _3947 = roughness * roughness;\n        float _3953 = mix(_3947, 1.0, _3880 * _3880);\n        bool _3955 = _3880 > 0.0;\n        _7106 = _3955 ? _3953 : _3947;\n        _7107 = _3955 ? _3947 : _3953;\n        _7103 = _3880;\n        _7087 = true;\n    }\n    return FaLayers(_7087, _7088, _7089, _7090, _7091, _7092, _7093, _7094, i.world_normal, _7096, _7097, _7098, _7099, _7100, _7101, _7102, _7103, _7104, _7105, _7106, _7107);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3336 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3336;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _743 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _756 = (c - (ru * hx)) - p;\n        vec3 _762 = ru * (2.0 * hx);\n        float _768 = max(dot(_762, _762), 9.9999999392252902907785028219223e-09);\n        float _772 = dot(_756, _762);\n        float t = clamp((-_772) / _768, 0.0, 1.0);\n        if (_743)\n        {\n            float _787 = dot(r, _762);\n            float _793 = _768 - (_787 * _787);\n            if (abs(_793) > (9.9999997473787516355514526367188e-06 * _768))\n            {\n                t = clamp(((dot(r, _756) * _787) - _772) / _793, 0.0, 1.0);\n            }\n        }\n        return (p + _756) + (_762 * t);\n    }\n    vec3 q = p;\n    float _825 = dot(r, axis);\n    bool _833;\n    if (_743)\n    {\n        _833 = abs(_825) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _833 = _743;\n    }\n    if (_833)\n    {\n        float _843 = dot(c - p, axis) / _825;\n        if (_843 > 0.0)\n        {\n            q = p + (r * _843);\n        }\n    }\n    vec3 _856 = q - c;\n    vec2 xy = vec2(dot(_856, ru), dot(_856, uu));\n    if (shape > 0.5)\n    {\n        float _871 = length(xy);\n        if (_871 > hx)\n        {\n            xy *= (hx / _871);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _505 = abs(d);\n    float _507 = _505.x;\n    float _509 = _505.y;\n    bool _510 = _507 >= _509;\n    bool _518;\n    if (_510)\n    {\n        _518 = _507 >= _505.z;\n    }\n    else\n    {\n        _518 = _510;\n    }\n    int _519;\n    if (_518)\n    {\n        _519 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _534;\n        if (_509 >= _505.z)\n        {\n            _534 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _534 = (d.z > 0.0) ? 4 : 5;\n        }\n        _519 = _534;\n    }\n    return _519;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _663 = dot(d, right);\n    float _667 = dot(d, up);\n    float _678;\n    if (((_663 * _663) + (_667 * _667)) > 1.0000000133514319600180897396058e-10)\n    {\n        _678 = atan(_667, _663) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _678 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_678 - floor(_678)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _909 = fa_light_base(param);\n    bool _913 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _909;\n    vec4 _917 = fa_light_texel(param_1);\n    int param_2 = _909 + 1;\n    vec4 _922 = fa_light_texel(param_2);\n    float _925 = _922.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _937 = _913 && (_925 > 2.5);\n    fa_light_is_area = _937;\n    bool _939 = _925 < 0.5;\n    vec3 l;\n    if (_939)\n    {\n        l = normalize(_917.xyz);\n        if (_913)\n        {\n            int param_3 = _909 + 6;\n            vec4 _953 = fa_light_texel(param_3);\n            if (_953.z > 0.5)\n            {\n                int param_4 = _909 + 4;\n                vec4 _963 = fa_light_texel(param_4);\n                int param_5 = _909 + 5;\n                vec4 _968 = fa_light_texel(param_5);\n                vec2 param_6 = _953.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _963.xyz) * _963.w, (-dot(world_pos, _968.xyz)) * _968.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _998 = _917.xyz;\n        vec3 _1000 = _998 - world_pos;\n        vec3 to_light = _1000;\n        float _1003 = length(_1000);\n        float reach = _1003;\n        bool front = true;\n        if (_937)\n        {\n            int param_8 = _909 + 7;\n            reach = max(_1003 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _909 + 4;\n            vec4 _1027 = fa_light_texel(param_9);\n            int param_10 = _909 + 5;\n            vec4 _1032 = fa_light_texel(param_10);\n            int param_11 = _909 + 6;\n            vec4 _1037 = fa_light_texel(param_11);\n            float _1038 = _1037.w;\n            int param_12 = _909 + 2;\n            vec3 _1045 = normalize(fa_light_texel(param_12).xyz);\n            bool _1047 = _1038 > 1.5;\n            bool _1055;\n            if (!_1047)\n            {\n                _1055 = dot(_1045, to_light) < 0.0;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            front = _1055;\n            vec3 r = vec3(0.0);\n            vec3 _1064 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1068 = dot(n, n) > 0.5;\n            bool _1076;\n            if (_1068)\n            {\n                _1076 = dot(_1064, _1064) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1076 = _1068;\n            }\n            if (_1076)\n            {\n                r = reflect(-normalize(_1064), normalize(n));\n            }\n            vec3 param_13 = _998;\n            vec3 param_14 = _1045;\n            vec3 param_15 = _1027.xyz;\n            vec3 param_16 = _1032.xyz;\n            float param_17 = _1027.w;\n            float param_18 = _1032.w;\n            float param_19 = _1038;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1112 = length(to_light);\n        dist = _1112;\n        l = to_light / vec3(max(_1112, 9.9999997473787516355514526367188e-05));\n        float _1126 = reach / max(_917.w, 0.001000000047497451305389404296875);\n        float _1132 = clamp(1.0 - (_1126 * _1126), 0.0, 1.0);\n        float _1134;\n        if (front)\n        {\n            _1134 = _1132 * _1132;\n        }\n        else\n        {\n            _1134 = 0.0;\n        }\n        atten = _1134;\n        bool _1145 = _925 < 2.5;\n        if ((_925 > 1.5) && _1145)\n        {\n            int param_22 = _909 + 2;\n            vec4 _1153 = fa_light_texel(param_22);\n            float _1163 = _1153.w;\n            int param_23 = _909 + 3;\n            vec4 _1168 = fa_light_texel(param_23);\n            float _1169 = _1168.x;\n            float cos_inner = _1169;\n            if (_1169 > 1.5)\n            {\n                cos_inner = mix(_1163, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1163, cos_inner, dot(-l, normalize(_1153.xyz)));\n        }\n        if (_913 && (_925 < 1.5))\n        {\n            int param_24 = _909 + 6;\n            vec4 _1193 = fa_light_texel(param_24);\n            if (_1193.z > 0.5)\n            {\n                vec3 _1201 = -to_light;\n                int param_25 = _909 + 4;\n                int param_26 = _909 + 5;\n                vec3 _1215 = fa_light_texel(param_25).xyz;\n                vec3 _1219 = fa_light_texel(param_26).xyz;\n                vec3 _1228 = vec3(dot(_1201, _1215), dot(_1201, _1219), dot(_1201, cross(_1215, _1219)));\n                vec3 param_27 = _1228;\n                int _1232 = fa_cube_face(param_27);\n                int param_28 = _1232;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1259 = vec2(dot(_1228, cross(param_29, param_30)), dot(_1228, param_30)) / vec2(max(dot(_1228, param_29), 9.9999997473787516355514526367188e-05));\n                int _1263 = _1232 / 3;\n                vec2 param_31 = _1193.xy + (vec2(float(_1232 - (_1263 * 3)), float(_1263)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1259.x), 0.5 - (0.5 * _1259.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _909 + 7;\n            vec4 _1293 = fa_light_texel(param_33);\n            if (_1293.z > 0.5)\n            {\n                int param_34 = _909 + 2;\n                int param_35 = _909 + 4;\n                int param_36 = _909 + 5;\n                vec2 param_37 = _1293.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_913 && _1145)\n            {\n                int param_42 = _909 + 6;\n                vec4 _1340 = fa_light_texel(param_42);\n                int param_43 = _909 + 7;\n                vec4 _1345 = fa_light_texel(param_43);\n                bool _1348 = _1340.z > 0.5;\n                bool _1355;\n                if (!_1348)\n                {\n                    _1355 = _1345.z > 0.5;\n                }\n                else\n                {\n                    _1355 = _1348;\n                }\n                if (_1355)\n                {\n                    int param_44 = _909 + 2;\n                    vec4 _1362 = fa_light_texel(param_44);\n                    vec3 _1366 = normalize(_1362.xyz);\n                    int param_45 = _909 + 4;\n                    vec4 _1371 = fa_light_texel(param_45);\n                    int param_46 = _909 + 5;\n                    vec4 _1376 = fa_light_texel(param_46);\n                    if (_1348)\n                    {\n                        vec3 _1384 = -to_light;\n                        float _1391 = _1362.w;\n                        float _1407 = 0.5 / max(dot(_1384, _1366) * (sqrt(max(1.0 - (_1391 * _1391), 0.0)) / max(_1391, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1340.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1384, _1371.xyz) * _1407), 0.5 - (dot(_1384, _1376.xyz) * _1407));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1345.z > 0.5)\n                    {\n                        vec2 param_49 = _1345.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1366;\n                        vec3 param_52 = _1371.xyz;\n                        vec3 param_53 = _1376.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7075 = _922.xyz * atten;\n    if (_913)\n    {\n        _7075 *= fa_light_tint;\n    }\n    int _1476;\n    if (_939)\n    {\n        _1476 = 0;\n    }\n    else\n    {\n        _1476 = ((_925 > 1.5) && (_925 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7075, atten, 1.0, dist, _1476);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2213;\n    if (i == 0)\n    {\n        _2213 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2229;\n        if (i == 1)\n        {\n            _2229 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2237;\n            if (i == 2)\n            {\n                _2237 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2237 = fa_shadows[24].w;\n            }\n            _2229 = _2237;\n        }\n        _2213 = _2229;\n    }\n    return _2213;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2270 = fa_shadow_depth(param, param_1);\n    float _2274;\n    if (conv.x < 0.5)\n    {\n        _2274 = _2270;\n    }\n    else\n    {\n        _2274 = (conv.y * conv.z) / (conv.z - (_2270 * (conv.z - conv.y)));\n    }\n    return _2274;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2201 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2201), sin(_2201)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2320 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2329;\n        if (k < 0.0)\n        {\n            _2329 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2329 = k;\n        }\n        float _2349 = clamp((_2329 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2320;\n            vec2 _2368 = fa_shadow_vogel(param_3, param_4, param_5) * _2349;\n            vec2 param_6 = uv + (_2368 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2380 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2380 < (zr - (length(_2368) * plane)))\n            {\n                sum += _2380;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2406 = sum / cnt;\n        float _2416;\n        if (k < 0.0)\n        {\n            _2416 = (-k) / max(_2406, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2416 = k;\n        }\n        radius = clamp(((max(zr - _2406, 0.0) * unit) * _2416) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2438 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2438; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2438;\n        float param_11 = _2320;\n        vec2 _2457 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2457 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2457) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2438);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2499 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2504 = clamp(dot(n, l), 0.0, 1.0);\n    float _2510 = sqrt(1.0 - (_2504 * _2504));\n    float _2517 = min(_2510 / max(_2504, 0.20000000298023223876953125), 4.0);\n    float _2522;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2522 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2522 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2547 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2522 * _2510)), 1.0);\n    float _2554 = _2547.x;\n    bool _2557 = _2554 < fa_shadows[ci * 1 + 16].x;\n    bool _2566;\n    if (!_2557)\n    {\n        _2566 = _2554 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2566 = _2557;\n    }\n    bool _2575;\n    if (!_2566)\n    {\n        _2575 = _2547.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2575 = _2566;\n    }\n    bool _2584;\n    if (!_2575)\n    {\n        _2584 = _2547.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2584 = _2575;\n    }\n    bool _2591;\n    if (!_2584)\n    {\n        _2591 = _2547.z > 1.0;\n    }\n    else\n    {\n        _2591 = _2584;\n    }\n    if (_2591)\n    {\n        return -1.0;\n    }\n    float _2599;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2599 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2599 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2547.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2547.z - ((_2599 * (1.0 + (0.5 * _2517))) / _2499);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2499;\n    float param_5 = _2499 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2517, 3.0)) * 0.5) / _2499;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2977 = int(fa_shadows[25].x + 0.5);\n    if (_2977 < 1)\n    {\n        return 1.0;\n    }\n    float _2992 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2977 - 1;\n    if (_2992 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3004 = _2977 > 1;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2992 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 1;\n    }\n    bool _3015 = _2977 > 2;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2992 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 2;\n    }\n    bool _3026 = _2977 > 3;\n    bool _3033;\n    if (_3026)\n    {\n        _3033 = _2992 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2977)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3059 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3059;\n        if (_3059 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3084;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3084 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3084 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3103 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3084, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3114 = clamp((_2992 - (fa_shadow_split_at(param_7) - _3103)) / _3103, 0.0, 1.0);\n        if (_3114 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2977)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3135 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3135;\n                if (_3135 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3114);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2657 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2664;\n    if (!_2657)\n    {\n        _2664 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2664 = _2657;\n    }\n    if (_2664)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2677 = fa_light_texel(param);\n    float _2678 = _2677.x;\n    if (_2678 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2687 = int(_2678 + 0.5);\n    int param_1 = _2687;\n    vec4 _2691 = fa_light_texel(param_1);\n    int param_2 = _2687 + 1;\n    vec4 _2696 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2699 = _2691.y;\n    if (_2699 > 0.0)\n    {\n        float _2716 = 1.0 - smoothstep(0.75 * _2699, _2699, length(world - fa_shadows[27].xyz));\n        fade = _2716;\n        if (_2716 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2691.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2740 = (_2687 + 2) + (face * 6);\n    int param_4 = _2740;\n    int param_5 = _2740 + 1;\n    int param_6 = _2740 + 3;\n    vec4 _2754 = fa_light_texel(param_6);\n    int param_7 = _2740 + 4;\n    vec4 _2759 = fa_light_texel(param_7);\n    int param_8 = _2740 + 5;\n    vec4 _2764 = fa_light_texel(param_8);\n    float _2776 = _2764.x * max(dot(_2754, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2781 = clamp(dot(n, l), 0.0, 1.0);\n    float _2804 = clamp(dot(n, _2754.xyz), -1.0, 1.0);\n    float _2823 = min(sqrt(1.0 - (_2804 * _2804)) / max(abs(dot(n, world - lpos)) / max(dot(_2754, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2826 = _2696.y;\n    float _2828;\n    if (_2826 > 0.0)\n    {\n        _2828 = _2826;\n    }\n    else\n    {\n        _2828 = 1.5 * _2776;\n    }\n    vec4 _2848 = vec4(world + (n * (_2828 * sqrt(1.0 - (_2781 * _2781)))), 1.0);\n    float _2852 = dot(_2754, _2848);\n    float _2855 = _2764.y;\n    if (_2852 < _2855)\n    {\n        return 1.0;\n    }\n    vec2 _2870 = vec2(dot(fa_light_texel(param_4), _2848), dot(fa_light_texel(param_5), _2848)) / vec2(_2852);\n    float _2872 = _2870.x;\n    bool _2875 = _2872 < _2759.x;\n    bool _2884;\n    if (!_2875)\n    {\n        _2884 = _2872 > _2759.z;\n    }\n    else\n    {\n        _2884 = _2875;\n    }\n    bool _2893;\n    if (!_2884)\n    {\n        _2893 = _2870.y < _2759.y;\n    }\n    else\n    {\n        _2893 = _2884;\n    }\n    bool _2902;\n    if (!_2893)\n    {\n        _2902 = _2870.y > _2759.w;\n    }\n    else\n    {\n        _2902 = _2893;\n    }\n    if (_2902)\n    {\n        return 1.0;\n    }\n    float _2908 = _2696.x;\n    float _2910;\n    if (_2908 > 0.0)\n    {\n        _2910 = _2908;\n    }\n    else\n    {\n        _2910 = 1.5 * _2776;\n    }\n    vec2 param_9 = _2870;\n    vec4 param_10 = _2759;\n    float param_11 = _2852 - (_2910 * (1.0 + (0.5 * _2823)));\n    float param_12 = _2776;\n    float param_13 = 1.0;\n    float param_14 = _2764.z * 0.25;\n    float param_15 = (_2776 * min(_2823, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2855, _2764.z);\n    int param_17 = int(_2691.z + 0.5);\n    float param_18 = _2691.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4465 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4472;\n    if (!_4465)\n    {\n        _4472 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4472 = _4465;\n    }\n    if (_4472)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4485 = fa_light_texel(param);\n    float _4486 = _4485.y;\n    float len = _4486;\n    if (_4486 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4498 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4508 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4498);\n    if (_4508 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4514 = len;\n    float _4517 = min(_4514, 0.89999997615814208984375 * dist);\n    len = _4517;\n    float _4522 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4498);\n    float _4527 = _4522 + (0.5 * _4517);\n    vec3 _4533 = world + (gn * _4522);\n    float _4535 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4599;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4550 = (float(k) + _4535) * 0.083333335816860198974609375;\n        vec3 _4558 = _4533 + (l * (_4550 * len));\n        vec4 _4564 = vec4(_4558, 1.0);\n        float _4570 = dot(fa_mesh_fs_params[28], _4564);\n        if (_4570 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4590 = vec2(dot(fa_mesh_fs_params[26], _4564), dot(fa_mesh_fs_params[27], _4564)) / vec2(_4570);\n        float _4594 = _4590.x * 0.5;\n        float _4595 = _4594 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4599 = (_4590.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4599 = 0.5 - (_4590.y * 0.5);\n        }\n        bool _4615 = _4595 < 0.0;\n        bool _4622;\n        if (!_4615)\n        {\n            _4622 = _4595 >= 1.0;\n        }\n        else\n        {\n            _4622 = _4615;\n        }\n        bool _4629;\n        if (!_4622)\n        {\n            _4629 = _4599 < 0.0;\n        }\n        else\n        {\n            _4629 = _4622;\n        }\n        bool _4636;\n        if (!_4629)\n        {\n            _4636 = _4599 >= 1.0;\n        }\n        else\n        {\n            _4636 = _4629;\n        }\n        if (_4636)\n        {\n            break;\n        }\n        vec4 _4655 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4595, _4599) * fa_mesh_fs_params[24].zw), 0);\n        if (_4655.w < 0.5)\n        {\n            continue;\n        }\n        float _4674 = (dot(fa_mesh_fs_params[29].xyz, _4558) + fa_mesh_fs_params[29].w) - _4655.x;\n        if ((_4674 > _4522) && (_4674 < _4527))\n        {\n            occ = max(occ, (1.0 - (_4550 * _4550)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4595, 0.5 - _4594), min(_4599, 1.0 - _4599))));\n        }\n    }\n    return 1.0 - (occ * _4508);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4750 = fa_lm.z > 0.5;\n    bool _4756;\n    if (_4750)\n    {\n        int param = li;\n        _4756 = fa_light_baked(param);\n    }\n    else\n    {\n        _4756 = _4750;\n    }\n    if (_4756)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4780 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7144 = _4780.color;\n    float _7146 = _4780.shadow;\n    bool _4783 = _4780.type == 0;\n    if (_4783 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4780.direction;\n        float _4794 = fa_shadow_factor(param_5, param_6);\n        _7146 = _4794;\n        _7144 *= _4794;\n    }\n    else\n    {\n        bool _4805 = _4780.type != 0;\n        bool _4811;\n        if (_4805)\n        {\n            _4811 = _4780.attenuation > 0.0;\n        }\n        else\n        {\n            _4811 = _4805;\n        }\n        if (_4811)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4780.direction;\n            float _4830 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7146 = _4830;\n            _7144 *= _4830;\n        }\n    }\n    bool _4840 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4846;\n    if (_4840)\n    {\n        _4846 = _4780.attenuation > 0.0;\n    }\n    else\n    {\n        _4846 = _4840;\n    }\n    if (_4846)\n    {\n        float _4853;\n        if (_4783)\n        {\n            _4853 = 1000000000.0;\n        }\n        else\n        {\n            _4853 = _4780._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4780.direction;\n        float param_18 = _4853;\n        float _4871 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7146 *= _4871;\n        _7144 *= _4871;\n    }\n    return LightSample(_4780.direction, _7144, _4780.attenuation, _7146, _4780._distance, _4780.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4914 = v - (n * dot(v, n));\n    vec3 t = _4914;\n    float _4918 = dot(_4914, _4914);\n    float l2 = _4918;\n    if (_4918 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4928;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4928 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4928 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4928;\n        l2 = dot(_4928, _4928);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4963 = dot(a, a);\n    float _4967 = dot(b, b);\n    if ((_4963 < 1.0000000195414813782625560981111e-24) || (_4967 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4981 = a * inversesqrt(_4963);\n    vec3 _4986 = b * inversesqrt(_4967);\n    float _4990 = dot(_4981, _4986);\n    float _4993 = abs(_4990);\n    float g = (((((((((((0.0416471660137176513671875 * _4993) - 0.1924748718738555908203125) * _4993) + 0.4179156124591827392578125) * _4993) - 0.616057217121124267578125) * _4993) + 0.777722418308258056640625) * _4993) - 0.999542415142059326171875) * _4993) + 1.570791721343994140625;\n    if (_4990 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4990 * _4990), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4981, _4986) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5050 = a.z > 0.0;\n    bool _5054 = b.z > 0.0;\n    if (_5050 && _5054)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5050 != _5054)\n        {\n            vec3 _5089 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5089.z = 0.0;\n            if (_5050)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5089;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5089;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5089;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5089;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5138 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5164 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5190 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5216 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5138;\n    vec3 param_1 = _5164;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5164;\n    vec3 param_7 = _5190;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5190;\n    vec3 param_13 = _5216;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5216;\n    vec3 param_19 = _5138;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5366 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5390 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5406 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5366;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5390;\n    vec4 param_9 = m;\n    vec3 param_10 = _5366;\n    vec3 param_11 = _5390;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5406;\n    vec4 param_14 = m;\n    vec3 param_15 = _5366;\n    vec3 param_16 = _5406;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5464 = fa_light_base(param);\n    int param_1 = _5464;\n    int param_2 = _5464 + 1;\n    int param_3 = _5464 + 2;\n    int param_4 = _5464 + 4;\n    vec4 _5486 = fa_light_texel(param_4);\n    int param_5 = _5464 + 5;\n    vec4 _5491 = fa_light_texel(param_5);\n    int param_6 = _5464 + 6;\n    vec4 _5496 = fa_light_texel(param_6);\n    float _5497 = _5496.w;\n    vec3 _5502 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5504 = _5497 < 1.5;\n    bool _5511;\n    if (_5504)\n    {\n        _5511 = dot(normalize(fa_light_texel(param_3).xyz), _5502) >= 0.0;\n    }\n    else\n    {\n        _5511 = _5504;\n    }\n    if (_5511)\n    {\n        return vec3(0.0);\n    }\n    bool _5520 = (_5497 > 0.5) && _5504;\n    float _5524 = _5520 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5527 = _5486.xyz;\n    float _5529 = _5486.w;\n    vec3 _5535 = _5491.xyz;\n    float _5537 = _5491.w;\n    vec3 up = _5535 * (_5537 * _5524);\n    float _5543;\n    if (_5520)\n    {\n        _5543 = (3.1415927410125732421875 * _5529) * _5529;\n    }\n    else\n    {\n        _5543 = (4.0 * _5529) * _5537;\n    }\n    if (_5497 > 1.5)\n    {\n        vec3 _5569 = cross(_5527, -_5502);\n        vec3 perp = _5569;\n        float _5573 = dot(_5569, _5569);\n        vec3 _5576;\n        if (_5573 > 1.0000000133514319600180897396058e-10)\n        {\n            _5576 = perp * inversesqrt(_5573);\n        }\n        else\n        {\n            _5576 = _5535;\n        }\n        perp = _5576;\n        up = _5576 * _5537;\n    }\n    float _5597 = max(_5543, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5607 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5607;\n    vec3 param_10 = n;\n    vec3 param_11 = _5502;\n    vec3 _5615 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5607;\n    vec3 param_13 = n;\n    vec3 param_14 = _5527 * (_5529 * _5524);\n    vec3 _5623 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5607;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5631 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5497;\n    vec3 param_20 = _5615;\n    vec3 param_21 = _5623;\n    vec3 param_22 = _5631;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5650 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5650;\n    vec2 param_26 = _5650 + vec2(64.0, 0.0);\n    vec4 _5660 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5497;\n    vec3 param_29 = _5615;\n    vec3 param_30 = _5623;\n    vec3 param_31 = _5631;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5660.x) + ((vec3(f90) - f0) * _5660.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5502, _5502)) + _5597) / _5597) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4202 = 1.0 / alpha;\n    return ((2.0 + _4202) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4202)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4237 = max(dot(L.nc, l), 0.0);\n    float _4243 = max(dot(L.nc, h), 0.0);\n    float _4252 = ((_4243 * _4243) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4252) * _4252)) * (0.5 / max(mix((2.0 * _4237) * L.coat_ndv, _4237 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4237)) * _4237;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5728;\n    if (L.sheen_on)\n    {\n        _5728 = L.sheen_scale;\n    }\n    else\n    {\n        _5728 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5728);\n    vec3 _5741 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5752 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5761 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5741), 0.0);\n        float param_13 = _5761;\n        float param_14 = ndv;\n        result += ((L.sheen * _5752) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5761)) * _5761) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5741;\n        float param_18 = max(dot(v, _5741), 0.0);\n        result += (_5752 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4105 = tdh / at;\n    float _4109 = bdh / ab;\n    float _4121 = ((_4105 * _4105) + (_4109 * _4109)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4121) * _4121);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4301 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4380 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4380) * _4380);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4301);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4301));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3511 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3514 = _3511.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3514 * _3514, exp2((-9.27999973297119140625) * ndv)) * _3514) + _3511.y)) + _3511.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3365 = rough * rough;\n    float _3395 = 0.60000002384185791015625 * _3365;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3365)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3395, 0.0500000007450580596923828125 + _3395, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3365 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3988;\n        if (L.aniso >= 0.0)\n        {\n            _3988 = L.b;\n        }\n        else\n        {\n            _3988 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3988, v), _3988), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4021 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4021.x) + (vec3(L.f90) * _4021.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4076 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4076.x) + _4076.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3553 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3553.x) + vec3(_3553.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3159 = int(fa_shadows[25].x + 0.5);\n    float _3169 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3174 = _3159 > 0;\n    bool _3183;\n    if (_3174)\n    {\n        int param = _3159 - 1;\n        _3183 = _3169 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3183 = _3174;\n    }\n    if (_3183)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3189 = _3159 > 1;\n        bool _3196;\n        if (_3189)\n        {\n            _3196 = _3169 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3196 = _3189;\n        }\n        if (_3196)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3202 = _3159 > 2;\n        bool _3209;\n        if (_3202)\n        {\n            _3209 = _3169 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3209 = _3202;\n        }\n        if (_3209)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3215 = _3159 > 3;\n        bool _3222;\n        if (_3215)\n        {\n            _3222 = _3169 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3222 = _3215;\n        }\n        if (_3222)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6844 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6844 = -_6844;\n    }\n    vec3 _6197 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6844, fa_world_tangent, fa_uv, fa_vertex_color, _6197, gl_FrontFacing);\n    Surface _6205 = fa_standard_surface(param_1);\n    vec3 _6875 = _6205.albedo;\n    float _6876 = _6205.alpha;\n    vec3 _6877 = _6205.normal;\n    float _6878 = _6205.metallic;\n    float _6879 = _6205.roughness;\n    float _6880 = _6205.occlusion;\n    vec3 _6881 = _6205.emission;\n    float _6882 = _6205.clearcoat;\n    float _6883 = _6205.clearcoat_roughness;\n    vec3 _6884 = _6205.sheen_color;\n    float _6885 = _6205.sheen_roughness;\n    float _6886 = _6205.anisotropy;\n    float _6887 = _6205.anisotropy_rotation;\n    float _6888 = _6205.specular;\n    float _6889 = _6205.ior;\n    vec3 _6890 = _6205.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6844, fa_world_tangent, fa_uv, fa_vertex_color, _6197, gl_FrontFacing);\n    Surface param_3 = _6205;\n    surface(param_2, param_3);\n    _6875 = param_3.albedo;\n    _6876 = param_3.alpha;\n    _6877 = param_3.normal;\n    _6878 = param_3.metallic;\n    _6879 = param_3.roughness;\n    _6880 = param_3.occlusion;\n    _6881 = param_3.emission;\n    _6882 = param_3.clearcoat;\n    _6883 = param_3.clearcoat_roughness;\n    _6884 = param_3.sheen_color;\n    _6885 = param_3.sheen_roughness;\n    _6886 = param_3.anisotropy;\n    _6887 = param_3.anisotropy_rotation;\n    _6888 = param_3.specular;\n    _6889 = param_3.ior;\n    _6890 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6844;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6875 = param_6;\n    _6877 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6875;\n    }\n    else\n    {\n        vec3 _6244 = normalize(_6877);\n        float _6251 = clamp(_6878, 0.0, 1.0);\n        float _6255 = clamp(_6879, 0.0500000007450580596923828125, 1.0);\n        float _6259 = _6255 * _6255;\n        float _6263 = _6259 * _6259;\n        float _6268 = max(dot(_6244, _6197), 9.9999997473787516355514526367188e-05);\n        vec3 _6274 = _6875 * (1.0 - _6251);\n        vec3 _6281 = mix(vec3(0.039999999105930328369140625), _6875, vec3(_6251));\n        vec3 f0 = _6281;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6844, fa_world_tangent, fa_uv, fa_vertex_color, _6197, gl_FrontFacing);\n        Surface param_9 = Surface(_6875, _6876, _6877, _6878, _6879, _6880, _6881, _6882, _6883, _6884, _6885, _6886, _6887, _6888, _6889, _6890);\n        vec3 param_10 = _6244;\n        vec3 param_11 = _6197;\n        float param_12 = _6251;\n        float param_13 = _6255;\n        vec3 param_14 = _6281;\n        FaLayers _6297 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6244;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6274) * _6880;\n        if (_6297.on)\n        {\n            lit *= _6297.base_scale;\n        }\n        int _6319 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6319; ln++)\n        {\n            int param_16 = ln;\n            int _6332 = fa_cl_light(param_16);\n            bool _6335 = fa_lm.z > 0.5;\n            bool _6341;\n            if (_6335)\n            {\n                int param_17 = _6332;\n                _6341 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6341 = _6335;\n            }\n            if (_6341)\n            {\n                continue;\n            }\n            int param_18 = _6332;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6844;\n            LightSample _6353 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6361 = max(dot(_6244, _6353.direction), 0.0);\n            float _6367 = _6353.attenuation * _6353.shadow;\n            vec3 _6372 = normalize(_6353.direction + _6197);\n            float _6377 = max(dot(_6244, _6372), 0.0);\n            float _6382 = max(dot(_6197, _6372), 0.0);\n            bool _6389;\n            if (fa_light_is_area)\n            {\n                _6389 = !_6297.on;\n            }\n            else\n            {\n                _6389 = fa_light_is_area;\n            }\n            if (_6389)\n            {\n                int param_21 = _6332;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6244;\n                vec3 param_24 = _6197;\n                vec3 param_25 = _6274;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6255;\n                float param_29 = _6268;\n                float param_30 = _6367;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6297;\n                    int param_32 = _6332;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6244;\n                    vec3 param_35 = _6197;\n                    vec3 param_36 = _6353.direction;\n                    vec3 param_37 = _6274;\n                    vec3 param_38 = f0;\n                    float param_39 = _6255;\n                    float param_40 = _6268;\n                    float param_41 = _6367;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6297.on)\n                    {\n                        FaLayers param_42 = _6297;\n                        vec3 param_43 = _6274;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6244;\n                        vec3 param_46 = _6197;\n                        vec3 param_47 = _6353.direction;\n                        vec3 param_48 = _6372;\n                        float param_49 = _6361;\n                        float param_50 = _6268;\n                        float param_51 = _6377;\n                        float param_52 = _6382;\n                        float param_53 = _6259;\n                        float param_54 = _6263;\n                        int param_55 = _6332;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6367));\n                    }\n                    else\n                    {\n                        float _6495 = ((_6377 * _6377) * (_6263 - 1.0)) + 1.0;\n                        int param_56 = _6332;\n                        lit += (((_6274 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6382, 5.0))) * (((_6263 / ((3.1415927410125732421875 * _6495) * _6495)) * (0.5 / max(mix((2.0 * _6361) * _6268, _6361 + _6268, _6259), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6361))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6361 * _6367));\n                    }\n                }\n            }\n        }\n        if (_6297.on)\n        {\n            FaLayers param_57 = _6297;\n            vec3 param_58 = _6244;\n            vec3 param_59 = _6197;\n            vec3 param_60 = f0;\n            float param_61 = _6255;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6880);\n        }\n        else\n        {\n            vec3 param_62 = _6244;\n            vec3 param_63 = _6197;\n            vec3 param_64 = f0;\n            float param_65 = _6255;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6880);\n        }\n        result = lit;\n    }\n    vec3 _6590 = result;\n    vec3 _6591 = _6590 + _6881;\n    result = _6591;\n    vec3 param_66 = _6591;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6600 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6607;\n    if (!_6600)\n    {\n        _6607 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6607 = _6600;\n    }\n    if (_6607)\n    {\n        vec3 _6616 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6622 = dot(_6616, fa_mesh_fs_params[9].xyz);\n        bool _6626 = fa_mesh_fs_params[9].w > 0.5;\n        float _6627;\n        if (_6626)\n        {\n            _6627 = _6622;\n        }\n        else\n        {\n            _6627 = length(_6616);\n        }\n        float _6639 = _6627 - fa_mesh_fs_params[8].x;\n        if (_6639 > 0.0)\n        {\n            float _6648 = fa_mesh_fs_params[7].w * _6639;\n            float tau = _6648 * _6648;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6664;\n                if (_6626)\n                {\n                    _6664 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6622);\n                }\n                else\n                {\n                    _6664 = fa_mesh_fs_params[0].y;\n                }\n                float _6685 = mix(_6664, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6627, 0.0, 1.0));\n                float _6689 = fa_world_pos.y - _6685;\n                float _6694 = _6685 - fa_mesh_fs_params[8].z;\n                float _6699 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6702 = _6694 <= 0.0;\n                bool _6703 = !_6702;\n                bool _6709;\n                if (_6703)\n                {\n                    _6709 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6709 = _6702;\n                }\n                float _6710;\n                if (_6709)\n                {\n                    _6710 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6710 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6694, 80.0));\n                }\n                bool _6737;\n                if (_6703)\n                {\n                    _6737 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6737 = _6702;\n                }\n                float _6738;\n                if (_6737)\n                {\n                    _6738 = fa_mesh_fs_params[8].y * _6694;\n                }\n                else\n                {\n                    _6738 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6694, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6763 = _6699 <= 0.0;\n                bool _6770;\n                if (!_6763)\n                {\n                    _6770 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6770 = _6763;\n                }\n                float _6771;\n                if (_6770)\n                {\n                    _6771 = fa_mesh_fs_params[8].y * _6699;\n                }\n                else\n                {\n                    _6771 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6699, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6798;\n                if (abs(_6689) < 0.001000000047497451305389404296875)\n                {\n                    _6798 = _6710;\n                }\n                else\n                {\n                    _6798 = (_6771 - _6738) / _6689;\n                }\n                tau += (_6639 * max(_6798, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6876);\n}\n\n",
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
            "inst_name": "_187",
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
            "inst_name": "_231",
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
            "inst_name": "_364",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_556",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2223",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _217 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _224 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_217 * _224).z;\n    fa_pre_r0 = vec3(_217[0].x, _217[1].x, _217[2].x);\n    fa_pre_r1 = vec3(_217[0].y, _217[1].y, _217[2].y);\n    fa_pre_r2 = vec3(_217[0].z, _217[1].z, _217[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _224;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _755 = base_t;\n    _755.x = _242.x;\n    _755.y = _242.y;\n    _755.z = _242.z;\n    base_t = _755;\n    vec4 _257 = (_755 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _718 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _763 = _294;\n        _763.x = _299.x;\n        _763.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _763;\n        _718 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _766 = mrt;\n    _766.x = _328.x;\n    _766.y = _328.y;\n    _766.z = _328.z;\n    mrt = _766;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _723 = fa_mesh_fs_params[20].x;\n    float _724 = fa_mesh_fs_params[20].y;\n    float _727 = fa_mesh_fs_params[20].z;\n    float _726 = fa_mesh_fs_params[21].w;\n    float _729 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _723 *= _370.y;\n            _724 *= _370.z;\n            _726 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _727 *= mrt.x;\n            _729 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _718, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _723, _724, fa_mesh_fs_params[21].xyz, _726, _727, fa_mesh_fs_params[20].w, _729, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _629 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _629 = -_629;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_182",
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
            "inst_name": "_286",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _329 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _336 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_329 * _336).z;\n    fa_pre_r0 = vec3(_329[0].x, _329[1].x, _329[2].x);\n    fa_pre_r1 = vec3(_329[0].y, _329[1].y, _329[2].y);\n    fa_pre_r2 = vec3(_329[0].z, _329[1].z, _329[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _336;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _755 = base_t;\n    _755.x = _242.x;\n    _755.y = _242.y;\n    _755.z = _242.z;\n    base_t = _755;\n    vec4 _257 = (_755 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _718 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _763 = _294;\n        _763.x = _299.x;\n        _763.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _763;\n        _718 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _766 = mrt;\n    _766.x = _328.x;\n    _766.y = _328.y;\n    _766.z = _328.z;\n    mrt = _766;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _723 = fa_mesh_fs_params[20].x;\n    float _724 = fa_mesh_fs_params[20].y;\n    float _727 = fa_mesh_fs_params[20].z;\n    float _726 = fa_mesh_fs_params[21].w;\n    float _729 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _723 *= _370.y;\n            _724 *= _370.z;\n            _726 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _727 *= mrt.x;\n            _729 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _718, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _723, _724, fa_mesh_fs_params[21].xyz, _726, _727, fa_mesh_fs_params[20].w, _729, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _629 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _629 = -_629;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_187",
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
            "inst_name": "_231",
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
            "inst_name": "_398",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _115 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _115) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_115 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _53 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _68;\n    if (!_53)\n    {\n        _68 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _68 = _53;\n    }\n    if (_68)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_190",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _213 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_213 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_213 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_213 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _120 = cross(model[1].xyz, model[2].xyz);\n    float _124 = (dot(model[0].xyz, _120) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_120 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _124, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _124), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _58 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _73;\n    if (!_58)\n    {\n        _73 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _73 = _58;\n    }\n    if (_73)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "inst_name": "_178",
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
            "inst_name": "_222",
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
            "inst_name": "_302",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          }
        ]
      }
    }
  }
}
